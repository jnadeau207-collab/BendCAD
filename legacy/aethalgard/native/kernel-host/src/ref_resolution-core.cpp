#include "ref_resolution.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

#include "cancel.hpp"
#include "naming_registry.hpp"
#include "selector_evaluator.hpp"

namespace aeth {
namespace {

// ---------------------------------------------------------------------------
// Arity (plan 01 §7.3 / @aeth/geometry-contracts referenceAritySchema)
// ---------------------------------------------------------------------------

struct Arity final {
  enum class Kind { One, OneOrMore, Any, Range } kind = Kind::One;
  std::size_t min = 1;
  std::optional<std::size_t> max;
};

Arity ParseArity(const nlohmann::json& refSlot) {
  // The wire default is "one" (operationRefWireSchema); a missing slot means a
  // single-entity reference.
  if (!refSlot.contains("arity"))
    return Arity{Arity::Kind::One, 1, std::optional<std::size_t>{1}};
  const nlohmann::json& arity = refSlot.at("arity");
  if (arity.is_string()) {
    const std::string form = arity.get<std::string>();
    if (form == "one")
      return Arity{Arity::Kind::One, 1, std::optional<std::size_t>{1}};
    if (form == "one-or-more")
      return Arity{Arity::Kind::OneOrMore, 1, std::nullopt};
    if (form == "any")
      return Arity{Arity::Kind::Any, 0, std::nullopt};
    throw std::invalid_argument("ref slot has an unknown arity form: " + form);
  }
  // Range form { min, max? }.
  Arity range;
  range.kind = Arity::Kind::Range;
  range.min = arity.at("min").get<std::size_t>();
  if (arity.contains("max"))
    range.max = arity.at("max").get<std::size_t>();
  return range;
}

// ---------------------------------------------------------------------------
// Signature channel (plan 05 §9.3 anchor score) — attribute/geometry matching.
// The score is computed JSON-vs-JSON so it shares EXACTLY the entity projection
// the query result and the recorded anchor both use (ResolvedEntityToJson /
// referenceAnchorSchema): a scoring divergence from what the UI recorded is
// then impossible by construction.
// ---------------------------------------------------------------------------

std::optional<std::array<double, 3>> ReadVec3(const nlohmann::json& owner, const char* key) {
  if (!owner.contains(key) || !owner.at(key).is_array() || owner.at(key).size() != 3)
    return std::nullopt;
  const nlohmann::json& value = owner.at(key);
  return std::array<double, 3>{value.at(0).get<double>(), value.at(1).get<double>(),
                               value.at(2).get<double>()};
}

double Norm(const std::array<double, 3>& a, const std::array<double, 3>& b) {
  const double dx = a[0] - b[0];
  const double dy = a[1] - b[1];
  const double dz = a[2] - b[2];
  return std::sqrt(dx * dx + dy * dy + dz * dz);
}

double Dot(const std::array<double, 3>& a, const std::array<double, 3>& b) {
  return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

/// The §9.3 score of one candidate against one anchor. `candidate` is a
/// ResolvedEntityToJson projection; `anchor` is a referenceAnchorSchema value.
double AnchorScore(const nlohmann::json& candidate, const nlohmann::json& anchor) {
  double score = 0.0;
  // Exact token survived — the strongest single signal, and normative: plan 05
  // §9.3's score table includes this +100 term. NOTE the deliberate correlation
  // with the history channel: the token is ALSO that channel's lookup key, so in
  // the token-survived case both channels lean on the one fact "this token is
  // live". That is safe — a live, unique token is dispositive on its own — and
  // in the case that actually matters, token DRIFT, this term contributes 0, so
  // the two channels are genuinely decorrelated exactly when decorrelation is
  // what protects against a silent misreference.
  if (anchor.contains("token") && candidate.contains("token") &&
      anchor.at("token").get<std::string>() == candidate.at("token").get<std::string>())
    score += 100.0;
  // Surface / curve geometry class matches (faces carry `surface`, edges `curve`).
  if (anchor.contains("surface") && candidate.contains("surface") &&
      anchor.at("surface").get<std::string>() == candidate.at("surface").get<std::string>())
    score += 20.0;
  if (anchor.contains("curve") && candidate.contains("curve") &&
      anchor.at("curve").get<std::string>() == candidate.at("curve").get<std::string>())
    score += 20.0;
  // Measure agreement within 25% (area for faces, length for edges).
  constexpr double kEps = 1.0e-9;
  if (anchor.contains("area") && candidate.contains("area")) {
    const double a = anchor.at("area").get<double>();
    const double c = candidate.at("area").get<double>();
    if (std::abs(c - a) / std::max(a, kEps) < 0.25)
      score += 15.0;
  }
  if (anchor.contains("length") && candidate.contains("length")) {
    const double a = anchor.at("length").get<double>();
    const double c = candidate.at("length").get<double>();
    if (std::abs(c - a) / std::max(a, kEps) < 0.25)
      score += 15.0;
  }
  // Outward-normal agreement within 15 degrees (planar faces).
  const std::optional<std::array<double, 3>> anchorNormal = ReadVec3(anchor, "normal");
  const std::optional<std::array<double, 3>> candidateNormal = ReadVec3(candidate, "normal");
  if (anchorNormal.has_value() && candidateNormal.has_value()) {
    const double cosAngle = std::clamp(Dot(*anchorNormal, *candidateNormal), -1.0, 1.0);
    if (cosAngle > std::cos(15.0 * 3.14159265358979323846 / 180.0))
      score += 15.0;
  }
  // Centroid proximity — a soft 5 mm falloff, always available on both sides.
  const std::optional<std::array<double, 3>> anchorCentroid = ReadVec3(anchor, "centroid");
  const std::optional<std::array<double, 3>> candidateCentroid = ReadVec3(candidate, "centroid");
  if (anchorCentroid.has_value() && candidateCentroid.has_value())
    score += 15.0 * std::exp(-Norm(*anchorCentroid, *candidateCentroid) / 5.0);
  // NOTE (deferred, tracked): the §9.3 adjHash term (+20 for a matching sorted-
  // neighbor-token FNV-1a) is not yet scored — ResolvedEntityToJson does not
  // emit adjHash, and the candidate-side neighbor set needs an adjacency pass
  // this tranche leaves to N6's pick plumbing. Its absence only makes the
  // score MORE conservative (a real match scores no lower than it should),
  // so no candidate is ever silently accepted that the full score would
  // reject — the safe direction.
  return score;
}

// ---------------------------------------------------------------------------
// Channel verdicts and the §6 lattice meet (mirrors hybrid.ts combineVerdicts,
// specialized to the two decorrelated heuristic channels §9.3 names).
// ---------------------------------------------------------------------------

struct ChannelVerdict final {
  enum class Kind { Proven, Ambiguous, Missing } kind = Kind::Missing;
  /// Index into the candidate vector when Proven; unused otherwise.
  std::size_t index = 0;
};

/// History channel (§9.3, §6.4): the candidate whose normalized lineage name
/// equals the anchored entity's is `proven`; a grammar-required twin the name
/// cannot separate (two candidates share it) is `ambiguous`; no match is
/// `missing`. Normalization already folds Modified-only extensions into
/// equality (the whole point of the congruence key), so equality IS the match.
ChannelVerdict HistoryChannel(const std::vector<QueryEntity>& candidates,
                              const nlohmann::json& anchor, const NamingRegistry& registry) {
  if (!anchor.contains("token"))
    return {ChannelVerdict::Kind::Missing, 0};
  const NamingRecord* anchorRecord = registry.FindByToken(anchor.at("token").get<std::string>());
  if (anchorRecord == nullptr)
    return {ChannelVerdict::Kind::Missing, 0};
  const std::string& anchorName = anchorRecord->normalizedLineageName;
  std::vector<std::size_t> matches;
  for (std::size_t index = 0; index < candidates.size(); ++index) {
    if (candidates[index].normalizedName == anchorName)
      matches.push_back(index);
  }
  if (matches.empty())
    return {ChannelVerdict::Kind::Missing, 0};
  if (matches.size() > 1)
    // Two live candidates share the anchor's normalized name: a grammar-
    // required twin collision the history channel cannot break (§6.4 symmetry
    // theorem — never positional). Fail closed to ambiguous.
    return {ChannelVerdict::Kind::Ambiguous, 0};
  return {ChannelVerdict::Kind::Proven, matches.front()};
}

/// Signature channel (§9.3 score): argmax over candidates; committed only when
/// the best clears 40 AND beats the runner-up by 15 (the tournament-tuned
/// separation that held zero misreferences on symmetric corpora). Otherwise
/// ambiguous — a near-tie is exactly the symmetry the channel must refuse.
ChannelVerdict SignatureChannel(const std::vector<QueryEntity>& candidates,
                                const nlohmann::json& anchor) {
  double best = -1.0;
  double runnerUp = -1.0;
  std::size_t bestIndex = 0;
  for (std::size_t index = 0; index < candidates.size(); ++index) {
    const double score = AnchorScore(ResolvedEntityToJson(candidates[index]), anchor);
    if (score > best) {
      runnerUp = best;
      best = score;
      bestIndex = index;
    } else if (score > runnerUp) {
      runnerUp = score;
    }
  }
  if (best >= 40.0 && best - runnerUp >= 15.0)
    return {ChannelVerdict::Kind::Proven, bestIndex};
  return {ChannelVerdict::Kind::Ambiguous, 0};
}

/// The §6 meet, safety-maximal reading (§9.3 "accepted silently only when both
/// channels independently commit to the same candidate"): accept iff BOTH
/// channels are Proven on the SAME index. Every other combination — different
/// indices (a FAULT, never a vote), a survivor-vs-gone (one Missing), or a lone
/// heuristic (one Ambiguous) — demotes to ambiguity. This is the
/// no-correlated-corroboration rule that held zero silent misreferences across
/// the 100k-pair qualification corpora.
std::optional<std::size_t> Corroborate(const ChannelVerdict& history,
                                       const ChannelVerdict& signature) {
  if (history.kind == ChannelVerdict::Kind::Proven &&
      signature.kind == ChannelVerdict::Kind::Proven && history.index == signature.index)
    return history.index;
  return std::nullopt;
}

// ---------------------------------------------------------------------------

/// The top-k candidate payload for an E_SEL_AMBIGUOUS result (§8/§9.3): the
/// candidates ordered by descending signature score against the anchor (so the
/// UI/agent sees the most plausible picks first), capped at five. With no
/// anchor the canonical evaluation order is kept.
std::vector<QueryEntity> TopCandidates(const std::vector<QueryEntity>& candidates,
                                       const nlohmann::json* anchor) {
  std::vector<QueryEntity> ranked = candidates;
  if (anchor != nullptr) {
    std::stable_sort(ranked.begin(), ranked.end(),
                     [anchor](const QueryEntity& a, const QueryEntity& b) {
                       return AnchorScore(ResolvedEntityToJson(a), *anchor) >
                              AnchorScore(ResolvedEntityToJson(b), *anchor);
                     });
  }
  constexpr std::size_t kMaxCandidates = 5;
  if (ranked.size() > kMaxCandidates)
    ranked.resize(kMaxCandidates);
  return ranked;
}

RefResolution Resolved(std::vector<QueryEntity> entities,
                       std::vector<QueryDiagnostic> diagnostics) {
  RefResolution result;
  result.status = RefStatus::Resolved;
  result.entities = std::move(entities);
  result.diagnostics = std::move(diagnostics);
  return result;
}

RefResolution EmptyResult(const QueryOutcome& outcome, const std::string& message) {
  RefResolution result;
  result.status = RefStatus::Empty;
  result.stageCardinalities = outcome.stageCardinalities;
  result.diagnostics = outcome.diagnostics;
  result.message = message;
  return result;
}

RefResolution AmbiguousResult(std::vector<QueryEntity> candidates,
                              std::vector<QueryDiagnostic> diagnostics,
                              const std::string& message) {
  RefResolution result;
  result.status = RefStatus::Ambiguous;
  result.candidates = std::move(candidates);
  result.diagnostics = std::move(diagnostics);
  result.message = message;
  return result;
}

/// Applies the onEmpty policy to a GENUINELY-empty match (count == 0) only — an
/// under-minimum but non-empty match is a typed refusal handled at the arity
/// site (F3), never here, so onEmpty can never discard partial matches. Default
/// `error` surfaces the empty; `empty-ok` accepts the empty set; `skip-op` is
/// unsupported for a fillet-class op (it cannot skip and still emit its output
/// body).
RefResolution ApplyEmptyPolicy(const nlohmann::json& refSlot, const QueryOutcome& outcome) {
  const std::string onEmpty =
      refSlot.contains("onEmpty") ? refSlot.at("onEmpty").get<std::string>() : "error";
  if (onEmpty == "empty-ok")
    return Resolved({}, outcome.diagnostics);
  if (onEmpty == "skip-op")
    throw std::invalid_argument(
        "unsupported operation: onEmpty=skip-op is not yet supported for a fillet-class "
        "reference (the op cannot skip and still produce its output body)");
  return EmptyResult(outcome, "reference resolved to no entities");
}

} // namespace

RefResolution ResolveRef(const nlohmann::json& refSlot, const std::vector<EvaluatedBody>& bodies,
                         const NamingRegistry& registry, const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
  const Arity arity = ParseArity(refSlot);

  // Descriptive resolution (N4): expand the scope, refine by the filter chain,
  // canonically order. The string never crosses the boundary — refSlot carries
  // the doc-model-parsed AST.
  const QueryOutcome outcome = EvaluateQuery(refSlot.at("ast"), bodies, registry, cancelled);
  const std::vector<QueryEntity>& resolved = outcome.entities;
  const std::size_t count = resolved.size();

  // Single anchor drives §9.3 disambiguation for a `one` slot; a `one` slot
  // records exactly one picked entity, so anchors[0] is THE anchor when present.
  const nlohmann::json* anchor = nullptr;
  if (refSlot.contains("anchors") && refSlot.at("anchors").is_array() &&
      !refSlot.at("anchors").empty())
    anchor = &refSlot.at("anchors").at(0);

  switch (arity.kind) {
  case Arity::Kind::Any:
    return Resolved(resolved, outcome.diagnostics);

  case Arity::Kind::OneOrMore:
    if (count == 0)
      return ApplyEmptyPolicy(refSlot, outcome);
    return Resolved(resolved, outcome.diagnostics);

  case Arity::Kind::Range: {
    // A genuinely-empty match runs the onEmpty policy; a NON-EMPTY under-minimum
    // match is a typed refusal regardless of onEmpty (F3). Routing under-minimum
    // through ApplyEmptyPolicy would let onEmpty:"empty-ok" silently discard the
    // partial matches — the very silent-misreference the slot's floor forbids.
    if (count == 0)
      return ApplyEmptyPolicy(refSlot, outcome);
    if (count < arity.min)
      return EmptyResult(outcome,
                         "reference resolved to fewer entities than the slot's arity minimum");
    if (arity.max.has_value() && count > *arity.max)
      return AmbiguousResult(TopCandidates(resolved, anchor), outcome.diagnostics,
                             "reference resolved to more entities than the slot's arity maximum");
    return Resolved(resolved, outcome.diagnostics);
  }

  case Arity::Kind::One:
  default: {
    if (count == 0)
      return ApplyEmptyPolicy(refSlot, outcome);
    if (count == 1)
      return Resolved(resolved, outcome.diagnostics);
    // k > 1 for a `one` slot: try the §9.3 two-channel anchor lattice. With no
    // anchor there is nothing to disambiguate against — fail closed.
    if (anchor == nullptr)
      return AmbiguousResult(TopCandidates(resolved, nullptr), outcome.diagnostics,
                             "reference resolved to several entities and carries no anchor to "
                             "disambiguate");
    const ChannelVerdict history = HistoryChannel(resolved, *anchor, registry);
    const ChannelVerdict signature = SignatureChannel(resolved, *anchor);
    const std::optional<std::size_t> accepted = Corroborate(history, signature);
    if (!accepted.has_value())
      return AmbiguousResult(TopCandidates(resolved, anchor), outcome.diagnostics,
                             "reference is ambiguous: the history and signature channels did not "
                             "independently agree on one entity");
    // Both channels committed to the same candidate — accept with the drift
    // diagnostic (§9.3 confidence: ambiguous-resolved). The doc-model refreshes
    // the anchor on a hash-neutral edit. The diagnostic is attached
    // UNCONDITIONALLY on every lattice-recovered acceptance, exactly as plan 05
    // §9.3 specifies — even when the exact token survived (a reviewer read the
    // name as over-claiming in that case, but the plan's contract, not the
    // apparent confidence, decides what rides on the acceptance).
    std::vector<QueryDiagnostic> diagnostics = outcome.diagnostics;
    diagnostics.push_back({"D_ANCHOR_DRIFT",
                           "reference recovered from ambiguity by two-channel anchor agreement",
                           resolved[*accepted].token});
    return Resolved({resolved[*accepted]}, std::move(diagnostics));
  }
  }
}

} // namespace aeth
