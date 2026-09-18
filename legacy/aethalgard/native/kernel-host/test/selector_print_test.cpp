// Native cross-language pin for the AQL canonical selector printer (Phase 4 N6
// slice A). Reads the ONE committed golden (fixtures/golden/selector-print-v1.json)
// that the TypeScript @aeth/document-model drift meta-test also reproduces, and
// asserts C++ aeth::PrintSelector(ast) equals the golden `canonical` string for
// every case — the byte-for-byte pin that keeps PrintSelector ≡ printSelector so
// the op-hash ref projection is invariant across the query→ast transport. Links
// only selector_print + operation_hash (EcmaNumberToString) + nlohmann — no OCCT.
#include <cstdio>
#include <exception>
#include <fstream>
#include <sstream>
#include <string>

#include <nlohmann/json.hpp>

#include "selector_print.hpp"

#ifndef AETH_SELECTOR_PRINT_GOLDEN_PATH
#error                                                                                             \
    "AETH_SELECTOR_PRINT_GOLDEN_PATH must be defined by the build (absolute path to the golden fixture)"
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

nlohmann::json LoadGolden() {
  std::ifstream stream(AETH_SELECTOR_PRINT_GOLDEN_PATH, std::ios::binary);
  if (!stream) {
    throw std::runtime_error("could not open golden fixture at " AETH_SELECTOR_PRINT_GOLDEN_PATH);
  }
  std::ostringstream buffer;
  buffer << stream.rdbuf();
  return nlohmann::json::parse(buffer.str());
}

} // namespace

int main() {
  try {
    const nlohmann::json golden = LoadGolden();
    std::printf("PrintSelector cross-language vectors:\n");
    for (const nlohmann::json& testCase : golden.at("cases")) {
      const std::string canonical = testCase.at("canonical").get<std::string>();
      const std::string description = testCase.at("description").get<std::string>();
      const std::string actual = aeth::PrintSelector(testCase.at("ast"));
      checkEqualString(actual, canonical, description + " -> " + canonical);
    }
  } catch (const std::exception& error) {
    std::printf("FATAL: %s\n", error.what());
    return 2;
  }

  if (g_failures != 0) {
    std::printf("\n%d selector-print vector(s) FAILED\n", g_failures);
    return 1;
  }
  std::printf("\nall selector-print vectors passed\n");
  return 0;
}
