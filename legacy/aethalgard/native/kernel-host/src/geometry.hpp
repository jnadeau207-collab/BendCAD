#pragma once

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include <TopoDS_Shape.hxx>
#include <nlohmann/json.hpp>

#include "cancel.hpp"
#include "element_names.hpp"
#include "operation_timeout.hpp"

namespace aeth {

/**
 * An operation-level reference (extrude -> profile operation id,
 * boolean_combine -> target/tool body-producing operation ids, per ADR-003)
 * that does not resolve to an evaluated, still-consumable producer earlier in
 * the document. For booleans this includes referencing a body another boolean
 * already consumed: consumed is consumed. `operationId` is the CONSUMING
 * operation's id — the operation that failed — so the document layer can
 * attribute the failure; the unresolved reference id is carried in the
 * message.
 */
class ReferenceMissing final : public std::runtime_error {
public:
  ReferenceMissing(std::string operationId, const std::string& message)
      : std::runtime_error(message), operationId_(std::move(operationId)) {}

  const std::string& OperationId() const { return operationId_; }

private:
  std::string operationId_;
};

/**
 * A per-operation geometry or request failure that carries the failing
 * operation's id so the document layer can attribute it (and the agent port can
 * feed a repairable error back into the run instead of crashing). Mirrors
 * ReferenceMissing's shape but additionally carries the mapped error `code`
 * (GEOMETRY_FAILED, UNSUPPORTED_OPERATION, or INVALID_REQUEST) so the server's
 * catch chain can reproduce the exact taxonomy the unattributed catches would
 * have produced — only now with an operationId attached. Optional `details`
 * carries operation-specific machine-readable repair data (Wave 2.4 feasibility
 * bounds) without creating another exception taxonomy.
 */
class OperationFailure final : public std::runtime_error {
public:
  OperationFailure(std::string operationId, std::string code, const std::string& message,
                   nlohmann::json details = nlohmann::json())
      : std::runtime_error(message), operationId_(std::move(operationId)), code_(std::move(code)),
        details_(std::move(details)) {}

  const std::string& OperationId() const { return operationId_; }
  const std::string& Code() const { return code_; }
  const nlohmann::json& Details() const { return details_; }

private:
  std::string operationId_;
  std::string code_;
  nlohmann::json details_;
};

/**
 * A topology-reference resolution failure at execution time (plan 05 §8): an
 * op's `refs` slot resolved to nothing (`E_SEL_EMPTY`) or to several candidates
 * the two-channel lattice could not separate (`E_SEL_AMBIGUOUS`). Carries the
 * consuming operation's id, the coarse wire `code` the transport already knows
 * (`REFERENCE_MISSING` for empty, `REFERENCE_AMBIGUOUS` for ambiguous), the
 * fine `selectorCode` (the plan-05 taxonomy), and a structured `details`
 * payload — the §8.1 per-stage cardinalities / zeroing filter for empty, or the
 * scored candidate list for ambiguous — so the agent repair loop gets data, not
 * a string (plan 05 §10). The cardinal rule made representable: a ref that
 * cannot be PROVEN is a typed refusal, never a silently mis-cut edge.
 */
class SelectorFailure final : public std::runtime_error {
public:
  SelectorFailure(std::string operationId, std::string code, std::string selectorCode,
                  const std::string& message, nlohmann::json details)
      : std::runtime_error(message), operationId_(std::move(operationId)), code_(std::move(code)),
        selectorCode_(std::move(selectorCode)), details_(std::move(details)) {}

  const std::string& OperationId() const { return operationId_; }
  const std::string& Code() const { return code_; }
  const std::string& SelectorCode() const { return selectorCode_; }
  const nlohmann::json& Details() const { return details_; }

private:
  std::string operationId_;
  std::string code_;
  std::string selectorCode_;
  nlohmann::json details_;
};

struct ShapeProbes final {
  bool valid{};
  double volume{};
  double surfaceArea{};
  double centerOfMass[3]{};
  double bounds[6]{};
  int solidCount{};
  int shellCount{};
  int faceCount{};
  int edgeCount{};
  int vertexCount{};
};

struct EvaluatedBody final {
  std::string bodyId;
  std::string operationId;
  /// Which born body of `operationId` this is (ADR-013). 0 for every
  /// single-output operation, so the wire field stays absent and the response
  /// is byte-identical to what it always was. Only a declared birth operation
  /// — a multi-solid import — ever produces a value above 0, and then its
  /// bodies carry a complete 0..N-1 set.
  int outputIndex{0};
  TopoDS_Shape shape;
  ShapeProbes probes;
};

class NamingRegistry;

/**
 * Evaluates a document's operations strictly in document order and returns
 * the bodies of the body-producing operations that remain UNCONSUMED at the
 * end of the request, in document order. A boolean_combine consumes its
 * target and tool bodies: consumed bodies never appear in the returned
 * vector, so they receive no probes entry, no mesh packet, and no STEP
 * export. Only this returned set may be surfaced by any caller.
 *
 * When `elementNames` is non-null (tranche N0: `includeElementNames` on
 * `evaluate_document`), every operation additionally records its
 * construction lineage into the book: body-birth operations (primitives and
 * profile sweeps) root every result sub-shape at the producing operation's
 * id, and mutating operations (booleans, hole, transform, fillet, chamfer)
 * retain their real per-op OCCT history and run the element_names.cpp
 * multi-pass naming, so every face/edge/vertex of every returned body has a
 * lineage name (total coverage — a projection miss is a defect, never a
 * skip). Operations whose history surface is unverified against the pinned
 * OCCT (offset) fail the request instead of minting names from an untrusted
 * lineage. Null keeps evaluation byte-identical to the pre-flag behavior,
 * including the booleans' history-free fast path.
 *
 * When `namingRegistry` is non-null (tranche N3), the same lineage passes
 * record into the registry's OWN book — pass either a bare book or a
 * registry, never both — and every operation is additionally harvested into
 * per-epoch naming records (plan 05 §6.2–§6.4 as amended by ADR-006) using
 * the SAME retained per-op history: one recording path, one history
 * retention. Every currently executable body birth (box/cylinder/sphere/
 * cone/torus/wedge and extrude/revolve/loft/sweep) has an explicit semantic
 * role table; rotated construction frames and feature cap planes are passed
 * to the harvest, so roles are never inferred from world axes or supplied by
 * a generic fallback. Mutating operation types without a verified history/
 * role table still fail with UNSUPPORTED_OPERATION. The registry is
 * epoch-local kernel state: nothing about it survives the request that built
 * it.
 */
std::vector<EvaluatedBody> EvaluateOperations(const nlohmann::json& operations,
                                              const std::atomic_bool& cancelled,
                                              ElementNameBook* elementNames = nullptr,
                                              NamingRegistry* namingRegistry = nullptr,
                                              OperationDeadline* deadline = nullptr);

/**
 * The replay engine (Wave 2.1): evaluates `evaluate_document` operations with a
 * content-addressed L1 cache. It holds an in-process LRU of evaluation-state
 * snapshots (body pool + profiles + name book) keyed by the cumulative
 * operation hash (`operation_hash.hpp`), so a re-evaluation restores the state
 * at the longest UNCHANGED operation prefix and re-executes only the changed
 * tail — the highest-leverage kernel fix (audit §4.E).
 *
 * Reuse is flag-gated and fail-closed: with `reuseEnabled == false` the cache is
 * never touched and the result is byte-identical to `EvaluateOperations` (the
 * default the server ships until the differential corpus proves warm == cold).
 * With it on, a warm evaluation MUST produce output byte-identical to a cold one
 * — same bodies, probes, and element names — which the differential test pins.
 * Only the bare-book (`includeElementNames`) path is cached; the registry-backed
 * `query` path is not.
 */
class DocumentEvaluator final {
public:
  /// Default L1 cache byte budget (plan 06 §9 `cacheRamMb`, default 512 MB).
  /// The governor evicts least-recently-used snapshots until the live total is
  /// within budget (Wave 2.1 slice 3a); it replaces the earlier fixed 512-ENTRY
  /// cap. A caller (a test, or a future supervisor budget handshake) may set a
  /// smaller budget through the constructor.
  static constexpr std::size_t kDefaultCacheBudgetBytes = 512ull * 1024ull * 1024ull;

  explicit DocumentEvaluator(std::size_t cacheBudgetBytes = kDefaultCacheBudgetBytes);
  ~DocumentEvaluator();
  DocumentEvaluator(const DocumentEvaluator&) = delete;
  DocumentEvaluator& operator=(const DocumentEvaluator&) = delete;

  /// Observability snapshot for the `stats` control method (plan 06 §7). All
  /// counters are cumulative over the evaluator's lifetime except `entries` /
  /// `bytes` / `budgetBytes`, which are the live governor state. `hits` /
  /// `misses` are per-EVALUATION prefix outcomes: a reuse evaluation that
  /// restored any cached prefix is a hit, a cold (startIndex == 0) one a miss.
  struct CacheStats final {
    std::size_t entries{};
    std::size_t bytes{};
    std::size_t budgetBytes{};
    std::uint64_t hits{};
    std::uint64_t misses{};
    std::uint64_t evictions{};
    std::uint64_t snapshotsStored{};
  };

  struct Result final {
    /// Unconsumed bodies in document order — the same set EvaluateOperations returns.
    std::vector<EvaluatedBody> bodies;
    /// The final element-name book, present iff `includeElementNames`. Keyed on
    /// `bodies`' live sub-shapes, ready for ProjectElementNames.
    std::optional<ElementNameBook> elementNames;
    /// Operations actually executed this call (the rest were restored from cache)
    /// — the reuse metric: a trailing-only edit re-executes just its suffix.
    std::size_t executedOperationCount{};
  };

  /**
   * Evaluates `operations` with prefix reuse. `documentId` + `kernelGeomVersion`
   * root the cache line (a different document or geometry version can never
   * collide). When `reuseEnabled`, restores the longest cached prefix, executes
   * the tail, and caches each new prefix state; otherwise evaluates cold and
   * leaves the cache untouched.
   */
  Result Evaluate(const nlohmann::json& operations, const std::string& documentId,
                  const std::string& kernelGeomVersion, bool includeElementNames, bool reuseEnabled,
                  const std::atomic_bool& cancelled, OperationDeadline* deadline = nullptr);

  /// Live governor state + lifetime counters (see CacheStats). Thread-safe: it
  /// takes the same lock the Put/Get path does, so a `stats` request handled on
  /// the reader thread may read consistently while a worker evaluates.
  CacheStats Stats() const;

private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};

ShapeProbes ProbeShape(const TopoDS_Shape& shape);
nlohmann::json ProbesToJson(const ShapeProbes& probes);

/**
 * The ASM-003 definition-evaluation wire contract's per-body collision-shape
 * cache key: `revisionHash + ":" + bodyId`. Deterministic and opaque — the
 * kernel never interprets it, it only guarantees the SAME (revisionHash,
 * bodyId) pair always produces the SAME string, so a future native/
 * assembly-host BVH/convex-proxy cache (ASM-010) can key off it without
 * recomputing anything the kernel already knows is unchanged. `bodyId` is
 * the definition body's stable identity (the producing operation's
 * document-authored `outputBodyId`), NOT a freshly-minted uuid.
 */
std::string CollisionShapeCacheKey(const std::string& revisionHash, const std::string& bodyId);

TopoDS_Shape CombineBodies(const std::vector<EvaluatedBody>& bodies);
std::uintmax_t ExportStep(const std::vector<EvaluatedBody>& bodies, const std::string& path,
                          const std::atomic_bool& cancelled);
nlohmann::json InspectStepXde(const std::string& path, const std::atomic_bool& cancelled);
std::uintmax_t ExportStepXde(const std::vector<EvaluatedBody>& bodies, const std::string& path,
                             const std::atomic_bool& cancelled);
nlohmann::json ExactInterference(const std::vector<EvaluatedBody>& bodies,
                                 const nlohmann::json& request, const std::string& kernelBuildId,
                                 const std::string& geometryBuildId,
                                 const std::atomic_bool& cancelled);
ShapeProbes InspectStep(const std::string& path, const std::atomic_bool& cancelled);

/**
 * Reads a STEP file and returns its transferred shape (the reader's OneShape
 * over all transferable roots). This is InspectStep's parsing stage without
 * the probe: the STEP-reimport mutation fixture needs the actual TopoDS_Shape
 * so it can snapshot topology and derive an oracle, while InspectStep's
 * callers only need probes. Throws on unreadable input, exactly like
 * InspectStep (which now delegates here).
 */
TopoDS_Shape ImportStepShape(const std::string& path, const std::atomic_bool& cancelled);

/**
 * Reads a STEP exchange structure held IN MEMORY (not on disk) and returns its
 * transferred shape — the read half of the `import_step` document operation
 * (defect D-019). It is the exact in-memory twin of {@link ImportStepShape}:
 * the operation retains its original Part-21 source verbatim (§2.1), so the
 * kernel builds the body straight from those bytes with no filesystem round
 * trip. Throws on unparseable input or a source with no transferable roots.
 */
TopoDS_Shape ImportStepShapeFromString(const std::string& source,
                                       const std::atomic_bool& cancelled);

/**
 * Rebuilds a solid body from a checked aeth-mesh-v1 surface held IN MEMORY — the
 * read half of the `import_mesh` document operation (defect D-023). `source` is
 * the base64-encoded aeth-mesh-v1 payload the operation retains (the guaranteed-
 * manifold, welded, outward-oriented surface the TS interchange pipeline
 * produced): this decodes the base64, validates the aeth-mesh-v1 layout
 * fail-closed, and sews its triangles into solid material — one solid, or a
 * compound of solids for a multi-lump mesh (still one body, §568). Throws on a
 * corrupt payload or a surface that will not form a valid solid; the kernel
 * rebuilds deterministically with no dependence on the original mesh file.
 */
TopoDS_Shape ImportMeshShapeFromString(const std::string& source,
                                       const std::atomic_bool& cancelled);

} // namespace aeth
