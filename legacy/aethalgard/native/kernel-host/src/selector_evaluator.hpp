#pragma once

#include <atomic>
#include <string>
#include <vector>

#include <TopoDS_Shape.hxx>
#include <nlohmann/json.hpp>

#include "geometry.hpp"

namespace aeth {

class NamingRegistry;

/// One entity in a query pipeline set (plan 05 §2 `ResolvedEntity`, minus the
/// lazily-measured properties, which the serializer computes on demand). The
/// set S0..Sn the evaluator refines is a vector of these, deduplicated by
/// `IsSame` shape identity.
struct QueryEntity final {
  /// The live B-rep sub-shape. Identity within the current replay state.
  TopoDS_Shape shape;
  /// 'f' face, 'e' edge, 'v' vertex — always the query head kind.
  char kind{};
  /// The visible body this entity belongs to (its `EvaluatedBody.bodyId`).
  std::string bodyId;
  /// The presentation token (plan 05 §6.1): the newest live token answering
  /// for `shape`, chosen deterministically from the registry alias chain.
  std::string token;
  /// The chosen record's normalized lineage name — the §6.4 primary ordering
  /// key. Empty only for the `all()`/`body()` transient sources over an entity
  /// the registry somehow did not name (a coverage defect, surfaced as such).
  std::string normalizedName;
  /// FNV-1a hex of sorted live tokens on immediate incident B-rep entities.
  /// Derived after query evaluation from exact topology, never tessellation or
  /// dense entity rows. Empty only when no named incidence exists.
  std::string adjHash;
};

/// A non-fatal selector diagnostic (plan 05 §8.2). Rides along the query
/// result; the executor tranche promotes some of these to errors, but the
/// pure evaluator only reports.
struct QueryDiagnostic final {
  /// D_TOKEN_DEAD / D_ORDER_TIE / D_MIXED_CONVEXITY / D_ANCHOR_DRIFT.
  std::string code;
  std::string message;
  /// The offending token, when the diagnostic is entity-scoped ("" otherwise).
  std::string token;
};

/// The result of one query evaluation (plan 05 §4.1): the canonically-ordered
/// final set, the per-stage cardinalities that make E_SEL_EMPTY attributable
/// (§8.1), and any diagnostics.
struct QueryOutcome final {
  std::vector<QueryEntity> entities;
  /// |S0|, |S1|, ..., |Sn| — one entry per pipeline stage (kindHead expansion
  /// plus one per filter). The caller attributes an empty result to the first
  /// stage that zeroed the set.
  std::vector<std::size_t> stageCardinalities;
  std::vector<QueryDiagnostic> diagnostics;
};

/// Evaluates a serialized AQL AST (plan 05 §3 wire form — never the string)
/// against a replay state: the visible `bodies` and the `registry` that
/// EvaluateOperations populated for the SAME document prefix. Left-to-right
/// set refinement (§4.1): expand the scope to S0, apply each filter in order,
/// canonically order the survivors (§6.4). The raw query string never crosses
/// the process boundary; doc-model has already parsed, kind-checked, and
/// rooted the AST, so the evaluator implements only evaluation semantics.
///
/// This tranche (N4) implements the `op`/`body`/`token`/`all` sources over
/// faces/edges/vertices and the full v1 measured-filter catalog (§3.2). The
/// `sketch`/`tag`/`world` sources, the `bodies`/`regions` head kinds, and the
/// authored-durable-id channel are deferred (ADR-006 §5, tranche plan): a
/// query using them fails closed with a clear UNSUPPORTED_OPERATION rather
/// than a guess — the cardinal no-silent-misreference rule.
QueryOutcome EvaluateQuery(const nlohmann::json& ast, const std::vector<EvaluatedBody>& bodies,
                           const NamingRegistry& registry, const std::atomic_bool& cancelled);

/// Serializes one resolved entity to the `query` result's `ResolvedEntity`
/// JSON (plan 05 §2): token, kind, bodyId, centroid, and the lazily-measured
/// properties appropriate to its kind and geometry class. Exposed so the
/// server's Query handler and the evaluator's own tests share one projection.
nlohmann::json ResolvedEntityToJson(const QueryEntity& entity);

} // namespace aeth
