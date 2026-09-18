#include "operation_hash.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <system_error>
#include <vector>

#include <nlohmann/json.hpp>

#include "selector_print.hpp" // PrintSelector — the ref-slot canonical projection
#include "sha256.hpp"

namespace aeth {
namespace {

// RFC 8785 §3.2.2.2 / ECMAScript JSON string escaping (matches JSON.stringify of
// a string): escape ", \, and U+0000–U+001F; emit everything else as literal
// UTF-8.
std::string JcsString(const std::string& value) {
  std::string out = "\"";
  for (const unsigned char character : value) {
    switch (character) {
    case '"':
      out += "\\\"";
      break;
    case '\\':
      out += "\\\\";
      break;
    case '\b':
      out += "\\b";
      break;
    case '\f':
      out += "\\f";
      break;
    case '\n':
      out += "\\n";
      break;
    case '\r':
      out += "\\r";
      break;
    case '\t':
      out += "\\t";
      break;
    default:
      if (character < 0x20) {
        std::array<char, 8> escape{};
        std::snprintf(escape.data(), escape.size(), "\\u%04x",
                      static_cast<unsigned int>(character));
        out += escape.data();
      } else {
        out.push_back(static_cast<char>(character));
      }
    }
  }
  out.push_back('"');
  return out;
}

// MUST stay identical to the TS `excludedKeys` set in
// packages/geometry-contracts/src/operation-hash.ts — the two sides agreeing
// byte-for-byte is this file's whole purpose, so a key added on one side and
// not the other silently splits the content-addressed cache in two.
// `snapHints` (CAP-035) joins them by plan-02's instruction that a sketch's
// snap hints are dropped before canonicalization exactly as ref `anchors` are.
const std::array<std::string, 4> kExcludedKeys = {"anchors", "metadata", "name", "snapHints"};

// A ref slot is any object carrying the resolution policy (`arity` + `onEmpty`)
// plus a selector — either the persisted `query` string or the wire `ast`
// (refs.ts `operationRefSchema` / `operationRefWireSchema`). Detection is by
// shape and mirrors the TS `isRefSlot` twin byte-for-byte, so both languages
// project the same slots (docs/design/2026-07-23-phase4-native-geometry.md §5).
bool IsRefSlot(const nlohmann::json& value) {
  return value.is_object() && value.contains("arity") && value.contains("onEmpty") &&
         (value.contains("ast") || value.contains("query"));
}

// Deep copy stripping every excluded key so name/metadata (top-level) and
// anchors (nested in a ref slot) never reach canonicalization. A ref slot is
// additionally PROJECTED over its printed canonical selector (N6 A′): rewritten
// to {query: PrintSelector(ast), arity, onEmpty} so the persisted `query`
// (printed doc-side by printSelector(parseSelector(query))) and the wire `ast`
// (printed here) canonicalize to identical bytes across the query→ast transport.
// The kernel owns no AQL parser, so a slot that reaches the hash carrying only
// `query` (a pre-N6 persisted shape) fails closed rather than hash a raw query
// string that would silently mismatch TS. Mirrors the TS `stripExcluded`.
nlohmann::json StripExcluded(const nlohmann::json& value) {
  if (value.is_array()) {
    nlohmann::json out = nlohmann::json::array();
    for (const nlohmann::json& element : value) {
      out.push_back(StripExcluded(element));
    }
    return out;
  }
  if (value.is_object()) {
    if (IsRefSlot(value)) {
      if (!value.contains("ast")) {
        throw std::runtime_error(
            "CanonicalOperationBytes: ref slot reached the hash without a wire ast");
      }
      nlohmann::json out = nlohmann::json::object();
      out["query"] = PrintSelector(value.at("ast"));
      out["arity"] = StripExcluded(value.at("arity"));
      out["onEmpty"] = value.at("onEmpty");
      return out;
    }
    nlohmann::json out = nlohmann::json::object();
    for (const auto& entry : value.items()) {
      if (std::find(kExcludedKeys.begin(), kExcludedKeys.end(), entry.key()) !=
          kExcludedKeys.end()) {
        continue;
      }
      out[entry.key()] = StripExcluded(entry.value());
    }
    return out;
  }
  return value;
}

std::string HexDigest(const std::array<std::uint8_t, 32>& digest) {
  static constexpr char kHexDigits[] = "0123456789abcdef";
  std::string hex;
  hex.reserve(64);
  for (const std::uint8_t byte : digest) {
    hex.push_back(kHexDigits[(byte >> 4) & 0xFu]);
    hex.push_back(kHexDigits[byte & 0xFu]);
  }
  return hex;
}

std::array<std::uint8_t, 32> Sha256OfString(const std::string& value) {
  return Sha256Bytes(reinterpret_cast<const unsigned char*>(value.data()), value.size());
}

std::array<std::uint8_t, 32> CacheLineRoot(const std::string& documentId,
                                           const std::string& kernelGeomVersion) {
  const nlohmann::json root = {
      {"v", kOperationHashVersion},
      {"documentId", documentId},
      {"kernelGeomVersion", kernelGeomVersion},
  };
  return Sha256OfString(CanonicalJson(root));
}

} // namespace

std::string EcmaNumberToString(double value) {
  if (!std::isfinite(value)) {
    throw std::runtime_error("operation hash cannot serialize a non-finite number");
  }
  // +0.0 and -0.0 both compare equal to 0.0; ECMAScript serializes both as "0".
  if (value == 0.0) {
    return "0";
  }
  std::string sign;
  double magnitude = value;
  if (magnitude < 0.0) {
    sign = "-";
    magnitude = -magnitude;
  }

  // Shortest round-trip significand + decimal exponent, in scientific form
  // "d[.ddd]e±XX". std::to_chars (no precision) produces the same correctly-
  // rounded shortest digits V8 does; the golden vectors pin that equivalence.
  std::array<char, 64> buffer{};
  const std::to_chars_result result = std::to_chars(buffer.data(), buffer.data() + buffer.size(),
                                                    magnitude, std::chars_format::scientific);
  if (result.ec != std::errc()) {
    throw std::runtime_error("operation hash number formatting overflowed its buffer");
  }
  const std::string scientific(buffer.data(), result.ptr);
  const std::size_t exponentPos = scientific.find('e');

  std::string digits;
  for (std::size_t index = 0; index < exponentPos; ++index) {
    if (scientific[index] != '.') {
      digits.push_back(scientific[index]);
    }
  }
  const int exponent = std::stoi(scientific.substr(exponentPos + 1));
  const int digitCount = static_cast<int>(digits.size());
  // n: the ECMAScript decimal-point position, value = digits × 10^(n - k).
  const int pointPosition = exponent + 1;

  std::string formatted;
  if (digitCount <= pointPosition && pointPosition <= 21) {
    formatted = digits + std::string(static_cast<std::size_t>(pointPosition - digitCount), '0');
  } else if (0 < pointPosition && pointPosition <= 21) {
    const auto split = static_cast<std::size_t>(pointPosition);
    formatted = digits.substr(0, split) + "." + digits.substr(split);
  } else if (-6 < pointPosition && pointPosition <= 0) {
    formatted = "0." + std::string(static_cast<std::size_t>(-pointPosition), '0') + digits;
  } else {
    const std::string mantissa =
        digitCount == 1 ? digits : digits.substr(0, 1) + "." + digits.substr(1);
    const int scientificExponent = pointPosition - 1;
    formatted = mantissa + "e" + (scientificExponent < 0 ? "-" : "+") +
                std::to_string(std::abs(scientificExponent));
  }
  return sign + formatted;
}

std::string CanonicalJson(const nlohmann::json& value) {
  switch (value.type()) {
  case nlohmann::json::value_t::null:
    return "null";
  case nlohmann::json::value_t::boolean:
    return value.get<bool>() ? "true" : "false";
  case nlohmann::json::value_t::string:
    return JcsString(value.get<std::string>());
  case nlohmann::json::value_t::number_integer:
  case nlohmann::json::value_t::number_unsigned:
  case nlohmann::json::value_t::number_float:
    // Every JSON number canonicalizes through double, exactly as V8 (whose only
    // number type is float64) does — so `3` and `3.0` produce identical bytes.
    return EcmaNumberToString(value.get<double>());
  case nlohmann::json::value_t::array: {
    std::string out = "[";
    bool first = true;
    for (const nlohmann::json& element : value) {
      if (!first) {
        out += ",";
      }
      first = false;
      out += CanonicalJson(element);
    }
    out += "]";
    return out;
  }
  case nlohmann::json::value_t::object: {
    std::vector<std::string> keys;
    keys.reserve(value.size());
    for (const auto& entry : value.items()) {
      keys.push_back(entry.key());
    }
    // Byte order equals RFC 8785 §3.2.3 UTF-16 code-unit order for the ASCII
    // keys this contract uses.
    std::sort(keys.begin(), keys.end());
    std::string out = "{";
    bool first = true;
    for (const std::string& key : keys) {
      if (!first) {
        out += ",";
      }
      first = false;
      out += JcsString(key) + ":" + CanonicalJson(value.at(key));
    }
    out += "}";
    return out;
  }
  default:
    throw std::runtime_error("operation hash cannot serialize this JSON value type");
  }
}

std::vector<std::uint8_t> CanonicalOperationBytes(const nlohmann::json& operation) {
  if (!operation.is_object()) {
    throw std::runtime_error("CanonicalOperationBytes requires an operation object");
  }
  const std::string json = CanonicalJson(StripExcluded(operation));
  return std::vector<std::uint8_t>(json.begin(), json.end());
}

std::vector<std::string> CumulativeOperationHashes(const std::string& documentId,
                                                   const std::string& kernelGeomVersion,
                                                   const nlohmann::json& operations) {
  if (!operations.is_array()) {
    throw std::runtime_error("CumulativeOperationHashes requires an operations array");
  }
  std::array<std::uint8_t, 32> hash = CacheLineRoot(documentId, kernelGeomVersion);
  std::vector<std::string> hashes;
  hashes.push_back(HexDigest(hash));
  for (const nlohmann::json& operation : operations) {
    const std::vector<std::uint8_t> bytes = CanonicalOperationBytes(operation);
    std::vector<std::uint8_t> combined;
    combined.reserve(hash.size() + bytes.size());
    combined.insert(combined.end(), hash.begin(), hash.end());
    combined.insert(combined.end(), bytes.begin(), bytes.end());
    hash = Sha256Bytes(combined.data(), combined.size());
    hashes.push_back(HexDigest(hash));
  }
  return hashes;
}

std::string CumulativeOperationHash(const std::string& documentId,
                                    const std::string& kernelGeomVersion,
                                    const nlohmann::json& operations) {
  return CumulativeOperationHashes(documentId, kernelGeomVersion, operations).back();
}

} // namespace aeth
