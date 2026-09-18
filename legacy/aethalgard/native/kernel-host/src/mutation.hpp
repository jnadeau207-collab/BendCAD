#pragma once

#include <atomic>
#include <cstdint>
#include <string>
#include <vector>

#include <BRepTools_History.hxx>
#include <NCollection_List.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shape.hxx>
#include <nlohmann/json.hpp>

class BRepAlgoAPI_BooleanOperation;

namespace aeth {

// ---------------------------------------------------------------------------
// Shared fixture surface (NG-2). The five parsed fixture records, their JSON
// parsers, and the deterministic construction helpers below are shared
// between the mutation-case oracle (BuildMutationCase) and the OCAF TNaming
// entrant (BuildOcafCase, ocaf_naming.cpp): both must rebuild bit-identical
// fixture programs from the same wire payload, so the construction lives in
// exactly one place. Every helper builds from parametric inputs only and is
// deterministic for a given fixture and OCCT build.
// ---------------------------------------------------------------------------

struct PlanarSplitFixture final {
  double width{};
  double depth{};
  double height{};
  char axis{};
  double offsetFraction{};
  std::string baseOperationId;
  std::string splitOperationId;
};

struct FilletFixture final {
  double width{};
  double depth{};
  double height{};
  double radius{};
  bool edgeAtXMax{};
  bool edgeAtYMax{};
  std::string baseOperationId;
  std::string filletOperationId;
};

struct LinearPatternFixture final {
  double width{};
  double depth{};
  double height{};
  double bossRadius{};
  double bossHeight{};
  double firstCenterX{};
  double centerY{};
  double pitch{};
  int countBefore{};
  int countAfter{};
  std::string baseOperationId;
  std::string arrayOperationId;
};

struct BossSuppressionFixture final {
  double width{};
  double depth{};
  double height{};
  double bossRadius{};
  double bossHeight{};
  double bossCenterX{};
  double bossCenterY{};
  double holeRadius{};
  double holeCenterX{};
  double holeCenterY{};
  std::string baseOperationId;
  std::string bossOperationId;
  std::string holeOperationId;
};

struct MergeFixture final {
  double targetWidth{};
  double targetDepth{};
  double targetHeight{};
  double toolWidth{};
  double toolDepth{};
  double toolHeight{};
  double originX{};
  double originY{};
  double originZ{};
  std::string targetOperationId;
  std::string toolOperationId;
  std::string mergeOperationId;
  /// Additive fuse-argument-order knob ("target-first" when absent). The
  /// fused solid is identical either way; the knob exists so the element-name
  /// channel's section-edge commutativity (names invariant under a Boolean
  /// argument-order flip) is provable against the real kernel.
  bool toolFirst{};
};

/// Shared geometry of the two STEP-interchange fixtures: an all-planar slab
/// ([0, width] x [0, depth] x [0, height]) pierced by one rectangular
/// through-opening along Z ([openingOriginX, +openingWidth] x
/// [openingOriginY, +openingDepth]). All-planar by design: planes round-trip
/// STEP without periodic-surface seam ambiguity, so serialization itself can
/// never manufacture or destroy topology (the fixtures still assert the
/// round-trip congruence rather than assume it). The construction that
/// produces the STEP bytes is discarded — the imported body enters the case
/// with no history, which is the property this stratum exists to test.
struct StepReimportFixture final {
  double width{};
  double depth{};
  double height{};
  double openingOriginX{};
  double openingOriginY{};
  double openingWidth{};
  double openingDepth{};
  /// The document operation that binds the external file (every entity of an
  /// imported body carries this single provenance — an import has no
  /// per-feature history).
  std::string sourceOperationId;
};

struct StepImportCutFixture final {
  double width{};
  double depth{};
  double height{};
  double openingOriginX{};
  double openingOriginY{};
  double openingWidth{};
  double openingDepth{};
  /// Full-height corner notch cut AFTER import at the (x = width, y = 0)
  /// corner: material [width - notchWidth, width] x [0, notchDepth] x Z is
  /// removed, so the notch consumes that corner's vertical edge outright
  /// (a "gone" truth) while re-trimming its adjacent faces.
  double notchWidth{};
  double notchDepth{};
  std::string sourceOperationId;
  std::string cutOperationId;
};

/// Fixture parsers: validate the `fixture` member of a kernel request against
/// the same domain rules the TypeScript schemas enforce and fail with
/// std::invalid_argument on violation.
PlanarSplitFixture ParsePlanarSplitFixture(const nlohmann::json& request);
FilletFixture ParseFilletFixture(const nlohmann::json& request);
LinearPatternFixture ParseLinearPatternFixture(const nlohmann::json& request);
BossSuppressionFixture ParseBossSuppressionFixture(const nlohmann::json& request);
MergeFixture ParseMergeFixture(const nlohmann::json& request);
StepReimportFixture ParseStepReimportFixture(const nlohmann::json& request);
StepImportCutFixture ParseStepImportCutFixture(const nlohmann::json& request);

/// The mutation-fixture box occupies [0, width] x [0, depth] x [0, height];
/// every fixture coordinate contract is stated against this placement.
TopoDS_Shape BuildBaseBox(double width, double depth, double height,
                          const std::atomic_bool& cancelled);

/// Places a box with one corner at (originX, originY, originZ) instead of the
/// origin -- the merge fixture's "tool" box.
TopoDS_Shape BuildBoxAt(double originX, double originY, double originZ, double width, double depth,
                        double height, const std::atomic_bool& cancelled);

/// Bounded vertical split plane face fully crossing the fixture box.
TopoDS_Face BuildSplitTool(const PlanarSplitFixture& fixture);

/// Deterministic fillet-edge selection: the single vertical box edge named by
/// the fixture's xSide/ySide. Fails unless exactly one box edge matches.
TopoDS_Edge SelectFilletEdge(const TopoDS_Shape& solid, const FilletFixture& fixture);

/// Vertical cylinder primitive used by the boss fixtures.
TopoDS_Shape BuildVerticalCylinder(double centerX, double centerY, double baseZ, double radius,
                                   double height, const std::atomic_bool& cancelled);

/// Runs one General-Fuse-based boolean with history recording and merges the
/// recorded history into the composed `history`. `stepHistoryOut` receives the
/// operation's OWN un-composed history handle (reference-counted, safely
/// outliving the non-copyable algorithm object).
TopoDS_Shape RunBooleanIntoHistory(BRepAlgoAPI_BooleanOperation& operation,
                                   const TopoDS_Shape& object,
                                   const NCollection_List<TopoDS_Shape>& tools,
                                   BRepTools_History& history, const char* label,
                                   const std::atomic_bool& cancelled,
                                   occ::handle<BRepTools_History>& stepHistoryOut);

/// One BRepAlgoAPI_Splitter evaluation of `baseSolid` by `splitTool` with
/// history recording; `historyOut` receives the splitter's History() handle.
TopoDS_Shape RunPlanarSplitIntoHistory(const TopoDS_Shape& baseSolid, const TopoDS_Face& splitTool,
                                       const std::atomic_bool& cancelled,
                                       occ::handle<BRepTools_History>& historyOut);

/// One BRepFilletAPI_MakeFillet evaluation of the fixture's edge on
/// `baseSolid`. BRepFilletAPI_MakeFillet exposes no History() handle; the
/// returned history is materialized through BRepTools_History's template
/// constructor over the algorithm's IsDeleted/Modified/Generated surface,
/// with the IsDeleted correction documented on LocalOperationHistorySource
/// in local_operation_history.hpp (the pinned MakeFillet::IsDeleted is only
/// truthful for faces).
TopoDS_Shape RunFilletIntoHistory(const TopoDS_Shape& baseSolid, const FilletFixture& fixture,
                                  const std::atomic_bool& cancelled,
                                  occ::handle<BRepTools_History>& historyOut);

/// Builds one reference-mutation tournament case: a base solid, a real OCCT
/// mutation, entrant-visible before/after topology snapshots, and an oracle
/// mapping derived exclusively from recorded algorithm history plus, for the
/// two re-evaluation fixtures, the deterministic construction program. The
/// oracle never infers identity from geometric similarity.
///
/// Two distinct oracle classes are implemented:
///
/// 1. SINGLE-RUN ALGORITHM HISTORY ("planar-split", "fillet", "merge"):
///    before and after are one algorithm run apart, and the oracle consults
///    exactly three history relations: IsRemoved() and Modified() decide each
///    BEFORE entity's fate (gone / stable-single / stable-set), and
///    Generated() populates the additive per-entry "generated" list of
///    cross-kind after images (a before-edge can generate an after-vertex or
///    an after-face, a before-face an after-edge).
///
/// 2. CONSTRUCTION CORRESPONDENCE ("linear-pattern", "boss-suppression"):
///    before and after are two INDEPENDENT full evaluations (a parameter
///    change or feature suppression forces re-evaluation), so no algorithm
///    history relates them. Each evaluation records, through its own
///    algorithm history composed across operations with
///    BRepTools_History::Merge, which result entities descend from which
///    deterministic construction argument (the base box, instance i's tool
///    cylinder, the hole tool). Correspondence across evaluations is then by
///    construction identity: equal owners and equal TopExp sub-shape indices
///    of the identical construction program denote the same constructed
///    entity. Where a construction parent alone leaves several candidates
///    (e.g. the two seam-end vertices generated from one tool seam edge),
///    the correspondence is refined by topological incidence with
///    already-corresponded higher-kind entities — exact set membership,
///    never geometric similarity. Entities whose owning feature is absent
///    from the other evaluation are "gone"; entities of a newly added
///    feature have no BEFORE parent and appear in no entry. This class emits
///    only "gone" and "stable-single" fates and no "generated" lineage
///    (cross-evaluation correspondence has no analogue of within-run
///    generation). Per ADR-005 this is a semantic oracle class requiring
///    human adversarial review before any qualification use.
///
/// 3. SERIALIZATION-IDENTITY CORRESPONDENCE ("step-reimport"): before and
///    after are two independent STEP reads of the SAME file bytes. No
///    algorithm history spans a serialization boundary, and the imported
///    body has no construction program of its own — the oracle's declared
///    premise is that a deterministic reader constructs the identical shape
///    from identical bytes, so equal per-kind TopExp::MapShapes indices
///    denote the same entity. The fixture VERIFIES that premise per case
///    (per-kind counts equal; per-index geometry class, centroid, and
///    measure agree within serialization tolerance) and fails the request
///    loudly on any disagreement — the oracle never guesses. Emits only
///    "stable-single" fates. Like class 2 this is a declared-truth oracle
///    requiring ADR-005 human review before qualification use.
///
/// Supported fixture kinds:
/// - "planar-split": a box divided by a vertical plane
///   (BRepAlgoAPI_Splitter, one General-Fuse History() covering every
///   argument sub-shape).
/// - "fillet": a box with one vertical edge replaced by a constant-radius
///   fillet (BRepFilletAPI_MakeFillet). The history is materialized through
///   BRepTools_History's template constructor over the algorithm's
///   IsDeleted/Modified/Generated surface, with one correction: the pinned
///   MakeFillet::IsDeleted is only truthful for faces (its result map holds
///   faces only), so edge/vertex removal is decided by BRepTools_History's
///   own definition — absent from the result and no Modified images — via
///   exact TShape set membership, never geometric similarity.
/// - "linear-pattern": a box with N cylindrical bosses fused onto its top
///   face in ONE BRepAlgoAPI_Fuse run (one General-Fuse history covering the
///   box and every instance tool), re-evaluated with N changed by exactly
///   one.
/// - "boss-suppression": a box with a fused boss and a vertical through-hole
///   cut clear of the boss, re-evaluated without the boss operation. Each
///   evaluation composes its fuse and cut histories with
///   BRepTools_History::Merge before deriving construction ownership.
/// - "merge": two independently dimensioned boxes (a "target" and a "tool")
///   fused in ONE BRepAlgoAPI_Fuse run. Unlike "linear-pattern"'s box+cylinder
///   fuse, BOTH arguments are real bodies with their own before-state
///   topology and provenance (mirroring how a document-level boolean_combine
///   merges two independent bodies), so the before snapshot is a compound of
///   both solids. The one General-Fuse History() this produces is the SAME
///   history class BRepAlgoAPI_Splitter produces for "planar-split", so it is
///   fed to the identical, unmodified OracleEntries() — this fixture adds no
///   new oracle logic, only a new before/after construction.
/// - "step-reimport": the all-planar pierced slab is written to a temporary
///   STEP file ONCE and read back TWICE; before and after snapshot the two
///   independently transferred shapes (oracle class 3). The construction that
///   generated the bytes never reaches the case — both sides carry only the
///   binding operation's provenance, exactly what a real import looks like.
/// - "step-import-cut": the same slab is written and read ONCE, then a
///   full-height corner notch is cut from the IMPORTED shape by one real
///   BRepAlgoAPI_Cut with history (oracle class 1 — the exempt algorithm-
///   history class; the import only changes what the base solid is). The
///   notch consumes the corner's vertical edge (a "gone" truth on an
///   imported entity), re-trims the four faces meeting that corner, and
///   leaves the opening's entities identity survivors.
///
/// Fixture scope: the planar-split fixture constrains offsetFraction to the
/// open interval (0, 1), which makes a split plane that contains existing
/// box topology (a vertex, edge, or face) structurally impossible. The
/// fillet fixture caps the radius at 0.8 x min(width, depth), strictly below
/// the geometric maximum, which makes degenerate tangency and
/// fillet-consumes-adjacent-topology structurally impossible. The two boss
/// fixtures require every feature footprint to clear the top-face boundary
/// and every other footprint by at least 0.25 x its radius, which makes
/// tangent, overlapping, or boundary-crossing features — and therefore any
/// argument sub-shape splitting into several same-kind pieces — structurally
/// impossible. The merge fixture requires the tool box's cross-section
/// (perpendicular to the piercing axis) to clear the target box's boundary on
/// that cross-section by 0.2 x the tool's own depth/height, and requires the
/// tool's extent along the piercing axis to both start and end at least
/// 0.2 x the tool's own width clear of the target's boundary on that axis —
/// which makes every argument face plane coincide with another (glued faces)
/// structurally impossible, makes tangency (a near-zero embedding or
/// protrusion depth) structurally impossible, and — because the pierced
/// cross-section never reaches the target's own face boundary — makes the
/// piercing hole always a single interior loop rather than an edge-touching
/// notch whose classification would be ambiguous, and guarantees every
/// trimmed argument face remains one connected remainder (never splits into
/// several same-kind pieces). All are fixture-domain limitations, not oracle
/// robustness guarantees; dedicated fixtures are required before strata that
/// can produce those interactions.
nlohmann::json BuildMutationCase(const nlohmann::json& request, std::uint32_t evaluationEpoch,
                                 const std::atomic_bool& cancelled);

} // namespace aeth
