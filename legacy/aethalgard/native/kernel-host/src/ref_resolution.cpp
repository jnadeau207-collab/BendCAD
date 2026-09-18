#include "ref_resolution.hpp"

#define ResolveRef ResolveRefCore
#include "ref_resolution-core.cpp"
#undef ResolveRef

namespace aeth {
namespace {

struct AnalyticAxisEvidence final {
  std::array<double, 3> origin;
  std::array<double, 3> dir;
};

std::optional<AnalyticAxisEvidence> ReadAnalyticAxis(const nlohmann::json& owner) {
  if (!owner.contains("axis") || !owner.at("axis").is_object())
    return std::nullopt;
  const nlohmann::json& axis = owner.at("axis");
  const auto origin = ReadVec3(axis, "origin");
  const auto dir = ReadVec3(axis, "dir");
  if (!origin.has_value() || !dir.has_value())
    return std::nullopt;
  return AnalyticAxisEvidence{*origin, *dir};
}

double RelativeDifference(double left, double right) {
  return std::abs(left - right) / std::max({std::abs(left), std::abs(right), 1.0e-12});
}

double AxisLineDistance(const AnalyticAxisEvidence& left, const AnalyticAxisEvidence& right) {
  const std::array<double, 3> delta = {
      right.origin[0] - left.origin[0],
      right.origin[1] - left.origin[1],
      right.origin[2] - left.origin[2],
  };
  const std::array<double, 3> cross = {
      delta[1] * left.dir[2] - delta[2] * left.dir[1],
      delta[2] * left.dir[0] - delta[0] * left.dir[2],
      delta[0] * left.dir[1] - delta[1] * left.dir[0],
  };
  return std::sqrt(Dot(cross, cross));
}

double EnrichedAnchorScore(const QueryEntity& candidate, const nlohmann::json& anchor) {
  const nlohmann::json projected = ResolvedEntityToJson(candidate);
  double score = AnchorScore(projected, anchor);

  if (anchor.contains("radius") && projected.contains("radius")) {
    const double recorded = anchor.at("radius").get<double>();
    const double current = projected.at("radius").get<double>();
    if (RelativeDifference(recorded, current) <= 1.0e-6)
      score += 25.0;
  }

  const auto recordedAxis = ReadAnalyticAxis(anchor);
  const auto currentAxis = ReadAnalyticAxis(projected);
  if (recordedAxis.has_value() && currentAxis.has_value()) {
    const double alignment =
        std::abs(std::clamp(Dot(recordedAxis->dir, currentAxis->dir), -1.0, 1.0));
    constexpr double kTwoDegreesRad = 2.0 * 3.14159265358979323846 / 180.0;
    if (alignment >= std::cos(kTwoDegreesRad)) {
      score += 20.0;
      if (AxisLineDistance(*recordedAxis, *currentAxis) <= 1.0e-5)
        score += 15.0;
    }
  }

  if (anchor.contains("adjHash") && projected.contains("adjHash") &&
      anchor.at("adjHash").get<std::string>() == projected.at("adjHash").get<std::string>()) {
    score += 20.0;
  }
  return score;
}

std::optional<std::size_t> UniqueHistoryCandidate(const std::vector<QueryEntity>& candidates,
                                                  const nlohmann::json& anchor,
                                                  const NamingRegistry& registry) {
  if (!anchor.contains("token"))
    return std::nullopt;
  const NamingRecord* recorded = registry.FindByToken(anchor.at("token").get<std::string>());
  if (recorded == nullptr)
    return std::nullopt;
  std::optional<std::size_t> match;
  for (std::size_t index = 0; index < candidates.size(); ++index) {
    if (candidates[index].normalizedName != recorded->normalizedLineageName)
      continue;
    if (match.has_value())
      return std::nullopt;
    match = index;
  }
  return match;
}

std::optional<std::size_t> UniqueEnrichedCandidate(const std::vector<QueryEntity>& candidates,
                                                   const nlohmann::json& anchor) {
  if (!anchor.contains("radius") && !anchor.contains("axis") && !anchor.contains("adjHash")) {
    return std::nullopt;
  }
  double best = -1.0;
  double runnerUp = -1.0;
  std::size_t bestIndex = 0;
  for (std::size_t index = 0; index < candidates.size(); ++index) {
    const double score = EnrichedAnchorScore(candidates[index], anchor);
    if (score > best) {
      runnerUp = best;
      best = score;
      bestIndex = index;
    } else if (score > runnerUp) {
      runnerUp = score;
    }
  }
  if (best >= 60.0 && best - runnerUp >= 20.0)
    return bestIndex;
  return std::nullopt;
}

} // namespace

RefResolution ResolveRef(const nlohmann::json& refSlot, const std::vector<EvaluatedBody>& bodies,
                         const NamingRegistry& registry, const std::atomic_bool& cancelled) {
  RefResolution resolution = ResolveRefCore(refSlot, bodies, registry, cancelled);
  if (resolution.status != RefStatus::Ambiguous || !refSlot.contains("anchors") ||
      !refSlot.at("anchors").is_array() || refSlot.at("anchors").empty()) {
    return resolution;
  }

  const nlohmann::json& anchor = refSlot.at("anchors").at(0);
  if (!anchor.contains("radius") && !anchor.contains("axis") && !anchor.contains("adjHash")) {
    return resolution;
  }

  const QueryOutcome outcome = EvaluateQuery(refSlot.at("ast"), bodies, registry, cancelled);
  if (outcome.entities.size() < 2)
    return resolution;

  const auto history = UniqueHistoryCandidate(outcome.entities, anchor, registry);
  const auto enriched = UniqueEnrichedCandidate(outcome.entities, anchor);
  if (!history.has_value() || !enriched.has_value() || history != enriched)
    return resolution;

  RefResolution recovered;
  recovered.status = RefStatus::Resolved;
  recovered.entities.push_back(outcome.entities[*history]);
  recovered.diagnostics = outcome.diagnostics;
  recovered.diagnostics.push_back(
      {"D_ANCHOR_DRIFT",
       "AQL remained ambiguous after topology evolution; lineage and analytic/"
       "incidence evidence independently proved the same entity",
       anchor.value("token", std::string{})});
  recovered.message =
      "reference recovered by independent lineage and enriched signature corroboration";
  return recovered;
}

} // namespace aeth
