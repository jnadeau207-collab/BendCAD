// Native cross-language pin for the operation content-hash contract (Wave 2.1
// slice 1b-hash). Reads the ONE committed golden file
// (fixtures/golden/operation-hash-v1.json) that the TypeScript
// @aeth/geometry-contracts suite also reproduces, and asserts the C++
// implementation produces byte-identical results: the ECMAScript
// Number::toString float printer, the RFC 8785 JCS canonicalization (with
// name/metadata/anchors excluded), and the cumulative prefix-hash chain. Both
// suites agreeing with the same file is the byte-for-byte pin that keeps the two
// implementations from drifting. Links only operation_hash + nlohmann + the
// header-only sha256 — no OCCT, no kernel-host process.
#include <cstdio>
#include <exception>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include <nlohmann/json.hpp>

#include "operation_hash.hpp"
#include "sha256.hpp"

#ifndef AETH_OP_HASH_GOLDEN_PATH
#error "AETH_OP_HASH_GOLDEN_PATH must be defined by the build (absolute path to the golden fixture)"
#endif

namespace {

int g_failures = 0;

void checkEqualString(const std::string& actual, const std::string& expected,
                      const std::string& label) {
  if (actual == expected) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s\n         expected: %s\n         actual:   %s\n", label.c_str(),
                expected.c_str(), actual.c_str());
    g_failures += 1;
  }
}

std::string Sha256HexOfBytes(const std::vector<std::uint8_t>& bytes) {
  aeth::Sha256 hasher;
  hasher.Update(bytes.data(), bytes.size());
  return hasher.HexDigest();
}

std::string BytesToString(const std::vector<std::uint8_t>& bytes) {
  return std::string(bytes.begin(), bytes.end());
}

nlohmann::json LoadGolden() {
  std::ifstream stream(AETH_OP_HASH_GOLDEN_PATH, std::ios::binary);
  if (!stream) {
    throw std::runtime_error("could not open golden fixture at " AETH_OP_HASH_GOLDEN_PATH);
  }
  std::ostringstream buffer;
  buffer << stream.rdbuf();
  return nlohmann::json::parse(buffer.str());
}

void NumberVectors(const nlohmann::json& golden) {
  std::printf("ECMAScript Number::toString vectors:\n");
  for (const nlohmann::json& vector : golden.at("numberVectors")) {
    const double value = vector.at("value").get<double>();
    const std::string expected = vector.at("expected").get<std::string>();
    checkEqualString(aeth::EcmaNumberToString(value), expected, "format " + expected);
  }
}

void OperationVectors(const nlohmann::json& golden) {
  std::printf("canonical operation bytes vectors:\n");
  for (const nlohmann::json& vector : golden.at("operationVectors")) {
    const std::string description = vector.at("description").get<std::string>();
    // Ref-bearing cases carry an `operationWire` (the op with every ref slot
    // lowered to the wire `{ast}` form); the kernel only ever hashes the wire
    // form (a persisted `{query}` slot fails closed here). Non-ref cases hash
    // `operation` directly.
    const nlohmann::json& toHash =
        vector.contains("operationWire") ? vector.at("operationWire") : vector.at("operation");
    const std::vector<std::uint8_t> bytes = aeth::CanonicalOperationBytes(toHash);
    checkEqualString(BytesToString(bytes), vector.at("canonicalJson").get<std::string>(),
                     "canonicalJson: " + description);
    checkEqualString(Sha256HexOfBytes(bytes), vector.at("canonicalSha256").get<std::string>(),
                     "sha256: " + description);
  }
}

void CumulativeVectors(const nlohmann::json& golden) {
  std::printf("cumulative prefix-hash chains:\n");
  for (const nlohmann::json& vector : golden.at("cumulativeVectors")) {
    const std::string description = vector.at("description").get<std::string>();
    // A chain containing a ref-bearing op carries an `operationsWire` (the chain
    // with those ops lowered to the wire form) — the only form the kernel hashes.
    const nlohmann::json& operations =
        vector.contains("operationsWire") ? vector.at("operationsWire") : vector.at("operations");
    const std::vector<std::string> hashes = aeth::CumulativeOperationHashes(
        vector.at("documentId").get<std::string>(),
        vector.at("kernelGeomVersion").get<std::string>(), operations);
    const auto expected = vector.at("prefixHashes").get<std::vector<std::string>>();
    if (hashes.size() != expected.size()) {
      std::printf("  FAIL prefix-hash count: %s (expected %zu, got %zu)\n", description.c_str(),
                  expected.size(), hashes.size());
      g_failures += 1;
      continue;
    }
    for (std::size_t index = 0; index < hashes.size(); ++index) {
      checkEqualString(hashes[index], expected[index],
                       "H(" + std::to_string(static_cast<long long>(index) - 1) +
                           "): " + description);
    }
  }
}

} // namespace

int main() {
  try {
    const nlohmann::json golden = LoadGolden();
    NumberVectors(golden);
    OperationVectors(golden);
    CumulativeVectors(golden);
  } catch (const std::exception& error) {
    std::printf("FATAL: %s\n", error.what());
    return 1;
  }
  if (g_failures == 0) {
    std::printf("\nALL CANONICAL HASH TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d CANONICAL HASH CHECK(S) FAILED\n", g_failures);
  return 1;
}
