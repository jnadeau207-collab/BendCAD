#pragma once

#include <cmath>
#include <cstddef>
#include <optional>
#include <utility>

namespace aeth {

/**
 * Conservative result from a bounded feasibility search.
 *
 * maxFeasible is always a candidate for which the caller's predicate returned
 * true. It is a tested lower bound, not a claim that OCCT feasibility is
 * perfectly monotone near a geometric degeneracy.
 */
struct FeasibilityProbeResult final {
  double maxFeasible{};
  std::size_t attempts{};
};

/**
 * Searches below a value already known to fail.
 *
 * The predicate owns the expensive operation-specific work and may throw
 * (notably Cancelled); exceptions deliberately escape so cancellation/timeout
 * outrank diagnostics. At most kBracketAttempts + kRefinementAttempts predicate
 * calls are made.
 */
template <typename IsFeasible>
std::optional<FeasibilityProbeResult> ProbeMaxFeasible(const double failedMagnitude,
                                                       IsFeasible&& isFeasible) {
  constexpr std::size_t kBracketAttempts = 8;
  constexpr std::size_t kRefinementAttempts = 8;

  if (!std::isfinite(failedMagnitude) || !(failedMagnitude > 0.0))
    return std::nullopt;

  double failing = failedMagnitude;
  double candidate = failedMagnitude * 0.5;
  std::size_t attempts = 0;
  std::optional<double> successful;

  // Geometrically shrink until a feasible candidate brackets the known
  // failure. A fixed count bounds OCCT work even for adversarial input.
  for (std::size_t attempt = 0; attempt < kBracketAttempts; ++attempt) {
    if (!(candidate > 0.0) || !(candidate < failing))
      break;
    ++attempts;
    if (std::forward<IsFeasible>(isFeasible)(candidate)) {
      successful = candidate;
      break;
    }
    failing = candidate;
    candidate *= 0.5;
  }

  if (!successful.has_value())
    return std::nullopt;

  // Refine between the greatest tested success and the nearest tested failure.
  // The predicate may be imperfectly monotone near tolerance; retaining only
  // actual successes keeps the returned value conservative.
  for (std::size_t attempt = 0; attempt < kRefinementAttempts; ++attempt) {
    const double midpoint = *successful + (failing - *successful) * 0.5;
    if (!(midpoint > *successful) || !(midpoint < failing))
      break;
    ++attempts;
    if (std::forward<IsFeasible>(isFeasible)(midpoint))
      successful = midpoint;
    else
      failing = midpoint;
  }

  return FeasibilityProbeResult{*successful, attempts};
}

} // namespace aeth
