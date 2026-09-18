#pragma once

#include <atomic>
#include <stdexcept>
#include <string>
#include <vector>

#include <nlohmann/json.hpp>

#include "geometry.hpp"
#include "ref_resolution.hpp"
#include "selector_evaluator.hpp"

namespace aeth {

/**
 * Strict ref-slot resolution shared by the catalog wave-1 executors
 * (datum_plane / datum_axis / shell — docs/design/2026-07-19-native-catalog-wave1.md
 * §2.1). It reproduces EXACTLY the discipline the landed fillet-v2 executor
 * applies to its `edges` slot, factored so datum and shell cannot drift from
 * it (fillet's landed inline copy in geometry.cpp is deliberately unchanged):
 *
 * 1. Pre-N6 transport guard (F1): a slot still in PERSISTED form
 *    ({query: "<string>"}, no `ast` key) is refused with an attributed
 *    std::invalid_argument — the ExecuteOperation catch chain wraps it into
 *    OperationFailure(operationId, "INVALID_REQUEST", ...). The raw query
 *    string never crosses the process boundary (plan 05 §4.2).
 * 2. ResolveRef against the CONSUMING op's replay state (the peeked pool),
 *    with the slot's own arity/anchors/onEmpty policy.
 * 3. Empty  → SelectorFailure REFERENCE_MISSING / E_SEL_EMPTY carrying the
 *    §8.1 stage cardinalities; Ambiguous → SelectorFailure
 *    REFERENCE_AMBIGUOUS / E_SEL_AMBIGUOUS carrying the scored candidates.
 *    Either way the op REFUSES rather than acting on a guess — the cardinal
 *    no-silent-misreference rule (plan 05 §8).
 *
 * `opLabel` and `slotName` only shape the human-readable message; behavior is
 * identical for every caller.
 */
inline RefResolution ResolveRefSlotStrict(const std::string& operationId,
                                          const std::string& opLabel, const char* slotName,
                                          const nlohmann::json& slot,
                                          const std::vector<EvaluatedBody>& bodies,
                                          const NamingRegistry& registry,
                                          const std::atomic_bool& cancelled) {
  if (!slot.is_object() || !slot.contains("ast")) {
    throw std::invalid_argument(opLabel + " " + slotName +
                                " reference reached the kernel unparsed (persisted query form); "
                                "the transport must ship the wire AST (operationRefWireSchema)");
  }
  RefResolution resolution = ResolveRef(slot, bodies, registry, cancelled);
  if (resolution.status == RefStatus::Empty) {
    throw SelectorFailure(
        operationId, "REFERENCE_MISSING", "E_SEL_EMPTY",
        opLabel + " " + slotName + ": " + resolution.message,
        {{"selectorCode", "E_SEL_EMPTY"}, {"stageCardinalities", resolution.stageCardinalities}});
  }
  if (resolution.status == RefStatus::Ambiguous) {
    nlohmann::json candidates = nlohmann::json::array();
    for (const QueryEntity& candidate : resolution.candidates)
      candidates.push_back(ResolvedEntityToJson(candidate));
    throw SelectorFailure(operationId, "REFERENCE_AMBIGUOUS", "E_SEL_AMBIGUOUS",
                          opLabel + " " + slotName + ": " + resolution.message,
                          {{"selectorCode", "E_SEL_AMBIGUOUS"}, {"candidates", candidates}});
  }
  return resolution;
}

/**
 * A resolved slot that must name EXACTLY ONE entity of `expectedKind` ('f' /
 * 'e' / 'v'). The slot's own arity already enforces `one` on the wire default,
 * but the kernel is a trust boundary: an adversarial frame could ship a wider
 * arity, so the executor's per-slot cardinality and kind are re-checked here
 * (the fillet-v2 kind-check precedent) instead of trusting the envelope.
 */
inline const QueryEntity& SingleResolvedEntity(const std::string& opLabel, const char* slotName,
                                               const char expectedKind,
                                               const RefResolution& resolution) {
  if (resolution.entities.size() != 1) {
    throw std::invalid_argument(opLabel + " " + slotName + " reference resolved to " +
                                std::to_string(resolution.entities.size()) +
                                " entities; the slot requires exactly one");
  }
  const QueryEntity& entity = resolution.entities.front();
  if (entity.kind != expectedKind) {
    const auto kindName = [](const char kind) {
      return kind == 'f' ? "face" : kind == 'e' ? "edge" : "vertex";
    };
    throw std::invalid_argument(opLabel + " " + slotName + " reference resolved a non-" +
                                kindName(expectedKind) + " entity; the slot is " +
                                kindName(expectedKind) + "-kinded");
  }
  return entity;
}

} // namespace aeth
