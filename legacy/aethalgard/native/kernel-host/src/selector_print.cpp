#include "selector_print.hpp"

#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

#include "operation_hash.hpp" // EcmaNumberToString — the shared ES number printer

namespace aeth {
namespace {

// Minimal double-quote escaping, matching print.ts `printString`: only `\` and
// `"` are escaped (NOT control characters — unlike JCS string escaping). The
// grammar admits no control characters in a string literal, so this is total.
std::string PrintString(const std::string& value) {
  std::string out = "\"";
  for (const char character : value) {
    if (character == '\\' || character == '"') {
      out.push_back('\\');
    }
    out.push_back(character);
  }
  out.push_back('"');
  return out;
}

std::string PrintNumber(const nlohmann::json& value) {
  return EcmaNumberToString(value.get<double>());
}

// One catalog parameter's printing-relevant facet: whether a trailing arg equal
// to `defaultValue` is omitted from the canonical string (plan 05 §3.4).
struct ParamDefault final {
  bool optional = false;
  bool hasDefault = false;
  double defaultValue = 0.0;
};

// The §3.2 catalog defaults (from @aeth/document-model `catalog.ts`), for the
// nine filters carrying an optional numeric argument. Only these can omit a
// trailing arg; every other filter prints all its arguments. This table is part
// of the printSelector≡PrintSelector contract and is pinned by the
// default-omission cases in `fixtures/golden/selector-print-v1.json`.
const std::unordered_map<std::string, std::vector<ParamDefault>>& FilterDefaults() {
  static const std::unordered_map<std::string, std::vector<ParamDefault>> table = {
      {"normal", {{}, {true, true, 1.0}}},
      {"parallel", {{}, {true, true, 1.0}}},
      {"perpendicular", {{}, {true, true, 1.0}}},
      {"at", {{}, {true, true, 0.5}}},
      {"onGround", {{true, true, 1e-3}}},
      {"largest", {{true, true, 1.0}}},
      {"smallest", {{true, true, 1.0}}},
      {"radius", {{}, {true, true, 1e-3}}},
      {"smooth", {{true, true, 1.0}}},
  };
  return table;
}

std::string PrintSelectorImpl(const nlohmann::json& query);

std::string PrintSource(const nlohmann::json& source) {
  const std::string tag = source.at("source").get<std::string>();
  if (tag == "op" || tag == "body" || tag == "sketch") {
    return tag + "(" + source.at("opId").get<std::string>() + ")";
  }
  if (tag == "tag") {
    return "tag(" + PrintString(source.at("tag").get<std::string>()) + ")";
  }
  if (tag == "token") {
    return "token(" + PrintString(source.at("token").get<std::string>()) + ")";
  }
  if (tag == "world") {
    return "world(" + source.at("world").get<std::string>() + ")";
  }
  if (tag == "all") {
    return "all";
  }
  throw std::invalid_argument("PrintSelector: unknown source '" + tag + "'");
}

std::string PrintArg(const nlohmann::json& arg) {
  const std::string tag = arg.at("arg").get<std::string>();
  if (tag == "number") {
    return PrintNumber(arg.at("value"));
  }
  if (tag == "string") {
    return PrintString(arg.at("value").get<std::string>());
  }
  if (tag == "ident" || tag == "axis") {
    return arg.at("value").get<std::string>();
  }
  if (tag == "direction") {
    const nlohmann::json& value = arg.at("value");
    if (value.at("form").get<std::string>() == "axis") {
      const std::string sign = value.at("sign").get<int>() == 1 ? "+" : "-";
      return sign + value.at("axis").get<std::string>();
    }
    std::string out = "[";
    bool first = true;
    for (const nlohmann::json& component : value.at("vector")) {
      if (!first) {
        out += ",";
      }
      first = false;
      out += PrintNumber(component);
    }
    out += "]";
    return out;
  }
  if (tag == "point") {
    std::string out = "[";
    bool first = true;
    for (const nlohmann::json& component : arg.at("value")) {
      if (!first) {
        out += ",";
      }
      first = false;
      out += PrintNumber(component);
    }
    out += "]";
    return out;
  }
  if (tag == "query") {
    return PrintSelectorImpl(arg.at("value"));
  }
  throw std::invalid_argument("PrintSelector: unknown arg '" + tag + "'");
}

std::string PrintFilter(const nlohmann::json& filter) {
  const std::string name = filter.at("name").get<std::string>();
  std::vector<nlohmann::json> args(filter.at("args").begin(), filter.at("args").end());

  // Omit trailing optional arguments that exactly equal their catalog default
  // (print.ts `printFilter`). Walk from the end; stop at the first arg that is
  // not an omittable default.
  const auto found = FilterDefaults().find(name);
  if (found != FilterDefaults().end()) {
    const std::vector<ParamDefault>& params = found->second;
    for (std::size_t index = args.size(); index-- > 0;) {
      if (index >= params.size()) {
        break;
      }
      const ParamDefault& param = params[index];
      const nlohmann::json& arg = args[index];
      if (param.optional && param.hasDefault && arg.at("arg").get<std::string>() == "number" &&
          arg.at("value").get<double>() == param.defaultValue) {
        args.pop_back();
        continue;
      }
      break;
    }
  }

  std::string out = name + "(";
  bool first = true;
  for (const nlohmann::json& arg : args) {
    if (!first) {
      out += ",";
    }
    first = false;
    out += PrintArg(arg);
  }
  out += ")";
  return out;
}

std::string PrintSelectorImpl(const nlohmann::json& query) {
  std::string scope;
  bool first = true;
  for (const nlohmann::json& source : query.at("scope")) {
    if (!first) {
      scope += ",";
    }
    first = false;
    scope += PrintSource(source);
  }
  std::string out = query.at("kind").get<std::string>() + "(" + scope + ")";
  for (const nlohmann::json& filter : query.at("filters")) {
    out += "." + PrintFilter(filter);
  }
  return out;
}

} // namespace

std::string PrintSelector(const nlohmann::json& ast) {
  if (!ast.is_object()) {
    throw std::invalid_argument("PrintSelector requires an AST object");
  }
  return PrintSelectorImpl(ast);
}

} // namespace aeth
