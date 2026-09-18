#pragma once

#include <atomic>

#include <nlohmann/json.hpp>

namespace aeth {

/// Builds one OCAF `TNaming` resolution case (NG-2 entrant #2, research 02
/// §3/§10 Phase D2+D3): rebuilds the requested mutation fixture's BEFORE
/// construction while recording every operation's COMPLETE algorithm history
/// into a real `TDF_Data` document (`TNaming_Builder` per operation label —
/// never a flattened substitute, per ADR-005), attaches a `TNaming_Selector`
/// per requested target sub-shape, applies the fixture's AFTER construction
/// onto the same document, and reports what `Solve` actually returned.
///
/// Request: `{ method: "ocaf_case", fixture: <mutationFixtureSchema>,
/// targets: [{ kind, index }] }` where `index` is the 0-based
/// `TopExp::MapShapes` position within `kind` of the fixture's BEFORE shape —
/// the same enumeration that mints the mutation-case snapshot tokens.
///
/// Result: `{ type: "ocaf_case", outcomes: [{ target, status, solved? }] }`
/// with `status` mapped 1:1 from the TNaming machinery, never invented:
/// - "solved": `Solve` succeeded with a single shape of the target kind that
///   is a sub-shape of the AFTER result; `solved` carries exactly its
///   after-side `{kind, index}`.
/// - "ambiguous": `Solve` produced a `TopAbs_COMPOUND` whose members are all
///   of the target kind and all present in the AFTER result (the documented
///   FILTERBYNEIGHBOURGS failure shape, tracker #23119); `solved` carries the
///   member set (possibly empty when the compound had no members).
/// - "missing": `Select`-recipe evaluation reported no current value
///   (`Solve() == false`, a null/empty `NamedShape`, or a null `Get()`).
/// - "failed": anything else — selection failed, a target index is out of
///   range, the solved shape has the wrong kind, or a solved shape is not a
///   sub-shape of the AFTER result. Fail closed; a wrong answer is never
///   coerced toward a plausible one.
///
/// Case A fixtures (planar-split, fillet, merge) apply the mutating
/// operation onto the same document as new evolutions. Case B fixtures
/// (linear-pattern, boss-suppression: independent re-evaluations) replay the
/// AFTER program writing fresh `TNaming_NamedShape` states onto the SAME
/// per-operation labels (label identity = operation identity — the "we
/// control the op order ourselves" replay research 02 §3 blesses in place of
/// TFunction); a suppressed operation's labels are cleared and record no new
/// state.
nlohmann::json BuildOcafCase(const nlohmann::json& request, const std::atomic_bool& cancelled);

} // namespace aeth
