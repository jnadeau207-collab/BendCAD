#include "bounded_feasibility.hpp"

#include <cmath>
#include <cstddef>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {

int failures = 0;

void Check(const bool condition, const char* message) {
  if (!condition) {
    std::cerr << "FAIL: " << message << '\n';
    ++failures;
  }
}

} // namespace

int main() {
  {
    std::size_t calls = 0;
    const auto result = aeth::ProbeMaxFeasible(10.0, [&calls](const double candidate) {
      ++calls;
      return candidate <= 7.0;
    });
    Check(result.has_value(), "monotone search returns a tested bound");
    Check(result && result->maxFeasible <= 7.0, "bound never exceeds the feasible limit");
    Check(result && result->maxFeasible > 6.98, "bound is refined near the feasible limit");
    Check(result && result->attempts == calls, "attempt count matches predicate calls");
    Check(calls <= 16, "search never exceeds its fixed attempt budget");
  }

  {
    std::size_t calls = 0;
    const auto result = aeth::ProbeMaxFeasible(256.0, [&calls](const double) {
      ++calls;
      return false;
    });
    Check(!result.has_value(), "no invented bound when no candidate succeeds");
    Check(calls == 8, "unsuccessful bracketing has a fixed work ceiling");
  }

  {
    std::size_t calls = 0;
    const auto result = aeth::ProbeMaxFeasible(256.0, [&calls](const double candidate) {
      ++calls;
      return candidate <= 1.0;
    });
    Check(result.has_value(), "last bracket candidate may establish a bound");
    Check(result && result->maxFeasible <= 1.0, "late bound remains an actual success");
    Check(calls == 16, "successful search also obeys the absolute attempt ceiling");
  }

  {
    std::size_t calls = 0;
    const auto predicate = [&calls](const double) {
      ++calls;
      return true;
    };
    Check(!aeth::ProbeMaxFeasible(0.0, predicate).has_value(), "zero is rejected without work");
    Check(!aeth::ProbeMaxFeasible(-1.0, predicate).has_value(),
          "negative magnitude is rejected without work");
    Check(!aeth::ProbeMaxFeasible(std::numeric_limits<double>::infinity(), predicate).has_value(),
          "non-finite magnitude is rejected without work");
    Check(calls == 0, "invalid inputs never invoke the predicate");
  }

  {
    struct Stop final : std::runtime_error {
      Stop() : std::runtime_error("stop") {}
    };
    std::size_t calls = 0;
    bool propagated = false;
    try {
      (void)aeth::ProbeMaxFeasible(10.0, [&calls](const double) -> bool {
        ++calls;
        if (calls == 3)
          throw Stop();
        return false;
      });
    } catch (const Stop&) {
      propagated = true;
    }
    Check(propagated, "predicate exceptions propagate immediately");
    Check(calls == 3, "search stops immediately when the predicate throws");
  }

  if (failures != 0)
    return 1;
  std::cout << "bounded feasibility: all checks passed\n";
  return 0;
}
