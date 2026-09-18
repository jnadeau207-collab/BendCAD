#pragma once

#include <atomic>
#include <cstddef>
#include <string>
#include <vector>

#include <nlohmann/json.hpp>

#include "geometry.hpp"
#include "selector_evaluator.hpp"

namespace aeth {

class NamingRegistry;

/// Resolution outcome for one operation ref slot at execution time (plan 05 §8
/// failure table). Every outcome short of `Resolved` is a TYPED refusal: the
/// executor turns it into an attributed kernel error and NEVER acts on a guess.
/// This is the product-side descendant of the NG-2 tournament's cardinal
/// no-silent-misreference gate.
enum class RefStatus {
  /// arity satisfied — `entities` is the exact, ordered set to act on.
  Resolved,
  /// E_SEL_EMPTY: the query (or arity floor) matched nothing. `stageCardinalities`
  /// attributes the first zeroing filter (§8.1).
  Empty,
  /// E_SEL_AMBIGUOUS: a `one` slot resolved to several candidates the two-channel
  /// lattice could not separate (§9.3). `candidates` carries the scored top-k.
  Ambiguous,
};

/// The result of resolving one ref slot against a replay state.
struct RefResolution final {
  RefStatus status = RefStatus::Empty;
  /// Resolved: the exact entity set the executor must act on (canonical order).
  std::vector<QueryEntity> entities;
  /// Ambiguous: the scored top-k candidate set for the §8/§9.3 repair payload.
  std::vector<QueryEntity> candidates;
  /// Empty: |S0|, |S1|, …, |Sn| so the caller attributes the first zeroing
  /// filter and builds the E_SEL_EMPTY payload (§8.1).
  std::vector<std::size_t> stageCardinalities;
  /// Diagnostics carried through from evaluation, plus D_ANCHOR_DRIFT when an
  /// ambiguous slot was recovered by the two-channel lattice (§9.3).
  std::vector<QueryDiagnostic> diagnostics;
  /// Human-readable one-line summary for the thrown error message.
  std::string message;
};

/// Resolves one operation ref slot at execution time against a replay state.
///
/// `refSlot` is the kernel-wire ref shape `{ast, arity, anchors, onEmpty}`
/// (@aeth/geometry-contracts `operationRefWireSchema`): the doc-model-parsed
/// AQL AST (never the string, plan 05 §4.2), the expected cardinality
/// (plan 01 §7.3), the recorded anchor fingerprints (hints only), and the
/// empty-set policy.
///
/// `bodies` are the visible bodies at the CONSUMING op's timeline position —
/// the executor peeks them from the body pool BEFORE the op consumes its
/// target, so the query's `op(...)`/`body(...)` sources resolve against exactly
/// the state the op sees. `registry` is the naming registry harvested through
/// the prior operation.
///
/// Pipeline: run the N4 evaluator (`EvaluateQuery`) to get the descriptive set,
/// then apply arity. A `one` slot that resolves to k>1 candidates enters the
/// §9.3 two-channel anchor lattice — the history channel (normalized-lineage-
/// name congruence over the registry) and the signature channel (the anchor
/// score) — and a candidate is accepted SILENTLY only when both channels
/// independently commit to the SAME single candidate. Any channel conflict, a
/// grammar-required twin the channels cannot separate, or a missing anchor
/// demotes to `Ambiguous`. Mirrors the qualified tournament resolver
/// `tools/reference-tournament/src/resolvers/hybrid.ts` (`combineVerdicts`).
///
/// `onEmpty` policy (plan 01 §7.1): `error` (default) surfaces `Empty`;
/// `empty-ok` turns an empty match into a `Resolved` empty set. `skip-op` is
/// rejected as unsupported for a fillet-class op (it cannot skip and still
/// produce its output body); a later tranche wires the degrade path.
RefResolution ResolveRef(const nlohmann::json& refSlot, const std::vector<EvaluatedBody>& bodies,
                         const NamingRegistry& registry, const std::atomic_bool& cancelled);

} // namespace aeth
