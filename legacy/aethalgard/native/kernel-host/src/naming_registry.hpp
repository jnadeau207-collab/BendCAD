#pragma once

#include <atomic>
#include <cstddef>
#include <map>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include <NCollection_DataMap.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS_Shape.hxx>
#include <gp_Dir.hxx>
#include <gp_Pnt.hxx>

#include "element_names.hpp"

class BRepTools_History;

namespace aeth {

/// One registry entry per minted topology token (plan 05 §6.2, as amended by
/// ADR-006). Records are append-only within an evaluation epoch: a record's
/// `shape` moves forward when its entity survives a downstream operation as
/// the single Modified image (the §6.3 step-12 alias), and `live` flips false
/// exactly once when the entity leaves the current replay state. Nothing here
/// survives the request that built it (ADR-003 epoch-local identity).
struct NamingRecord final {
  /// `t:<opId>/<role>/<ordinal>` — the epoch-local presentation handle.
  std::string token;
  /// The entity's TopoDS shape at the CURRENT replay state (alias-updated).
  TopoDS_Shape shape;
  /// Operation that minted this token (== the token's opId field).
  std::string minter;
  /// Role within the minting operation's role table (lowercase kebab).
  std::string role;
  /// Entity kind: 'f' face, 'e' edge, 'v' vertex.
  char kind{};
  /// The `n1:` lineage name at mint time — the identity spine (ADR-006).
  std::string lineageName;
  /// NormalizeElementName(lineageName): the cross-replay correspondence key.
  std::string normalizedLineageName;
  /// Tokens of the input-side entities this one descends from, sorted and
  /// deduplicated. Losing provenance of §6.3 assign-conflicts is recorded
  /// here too, so adjacency/created() queries stay truthful.
  std::vector<std::string> ancestors;
  /// False once superseded/deleted downstream. Never removed in-session.
  bool live{};
  /// GRAMMAR-REQUIRED TWIN: another record minted in the same (op, role)
  /// bucket shares this record's kind and normalized lineage name. The
  /// ordinal below is a geometric-tie-break PRESENTATION order only; any
  /// resolution that must distinguish flagged records is ambiguous, never
  /// positional (plan 05 §6.4 as amended — the symmetry theorem).
  bool nameCollision{};
  /// D_ORDER_TIE (§6.4): the geometric canonical key ALSO tied, so the
  /// ordinal fell back to TopExp::MapShapes traversal order — surfaced so
  /// tests can hunt the one non-deterministic corner instead of hiding it.
  bool orderTie{};
};

/// Epoch-local kernel naming registry (plan 05 §6.2–§6.4 as amended by
/// ADR-006; integration tranche N3). Composes the existing ElementNameBook —
/// the registry OWNS the book that geometry.cpp's tranche-N0 naming passes
/// record into, so there is exactly one history-retention path and one naming
/// pass per operation. After each operation the harvest (§6.3) turns the
/// book's lineage names plus the SAME retained OCCT history into records:
///
/// - ordinals within a role bucket follow the NORMALIZED LINEAGE NAME order
///   (deterministic, geometry-independent — the ADR-006 amendment), with the
///   §6.4 geometric canonical key demoted to a tie-break that only twins with
///   grammar-identical names ever reach;
/// - a 1:1 Modified image keeps its old token as an alias (§6.3 step 12): the
///   surviving shape answers to every token on its alias chain (capped at 8,
///   oldest dropped); a SPLIT (one source, several same-kind images) never
///   aliases — the source token dies and each half minths a new record, so a
///   stale token can never silently follow one twin;
/// - entities the harvest cannot attribute fail the request loudly (a fresh
///   quantized-geometry root minted at the harvested operation means the
///   naming pass itself could not attribute the entity), as does an
///   operation type without a role table — never a guess, never a skip.
///
/// Role tables cover every body birth the host currently executes: the six
/// primitives, the extrude/revolve/loft/sweep feature family, and the two
/// imports (flat per-kind roles — see HarvestImportedBody). Births are
/// classified from their authored construction frame (never world axes or
/// traversal position), then minted through the same lineage-first ordering
/// as mutating operations. Boolean `modified`/`tool-face`/`tool-edge`/`seam`,
/// hole/shell `wall`, fillet `fillet`, and transform `modified` retain their
/// operation-history tables. Truly untabled operations still fail closed.
///
/// Determinism is a wire contract: every iteration below is TopExp::MapShapes
/// index order or sorted std::map keys, never unordered containers. Two
/// independent evaluations of one program produce record-for-record identical
/// registries (the tranche N3 verify criterion).
///
/// The registry is the substrate the tranche-N4 selector evaluator queries at
/// a timeline position: evaluate the document prefix with a fresh registry,
/// then resolve tokens/names through the lookups below.
class NamingRegistry final {
public:
  /// Which minimal role table governs a harvested operation. Shell (catalog
  /// wave 1) mirrors Hole's minimal table: its synthesized offset solid is a
  /// synthetic operand whose surviving faces re-mint as `wall` (the cavity
  /// surface when inward, the new outer skin when outward — doc 04), while
  /// the target's untouched faces identity-survive.
  ///
  /// Catalog wave 2 (docs/design/2026-07-19-native-catalog-wave1.md line 285 —
  /// "a later wave", designed in the shell mold) adds two:
  ///
  /// - `Mirror` (the `merge: true` fuse only — the `merge: false` new body uses
  ///   `HarvestMirrorCopy` below): the mirrored copy is a SYNTHETIC operand of
  ///   the fuse (the hole/shell tool route), so its surviving/split faces re-mint
  ///   as doc-04 `mirrored` / `mirrored-edge` / `mirrored-vertex` while the
  ///   source's untouched faces identity-survive as `modified` and the join
  ///   curves are `seam` — the doc-04 mirror role table (ordinals lineage-first
  ///   per ADR-006, superseding doc-04's source-index rule exactly as shell's §3.2
  ///   superseded its per-role ordinal).
  /// - `Pattern` (pattern_linear / pattern_circular): every instance is a
  ///   SYNTHETIC operand of the single n-ary boolean, so instance images re-mint
  ///   as doc-04 `instance-face` / `instance-edge` / `instance-vertex`; the
  ///   optional real `target` (union / subtract) identity-survives as `modified`;
  ///   instance-intersection curves are `seam`. Cross-replay identity rides the
  ///   compound-ordinal lineage name (`AddPrimitive` on the instance compound is
  ///   prefix-stable in instance order), the ADR-006-compatible expression of
  ///   doc-04's `m·P + k` computed ordinal.
  /// `Chamfer` (CAP-012) is the doc-04 chamfer table: bevel faces generated
  /// from one provenance input edge are `chamfer`, the corner patches where
  /// several chamfers meet are `chamfer-corner` (a multi-source Generated
  /// image — the §6.3 "section" family), and generated edges are
  /// `chamfer-edge`. It shares Fillet's honest limit: `BRepFilletAPI_MakeChamfer`
  /// exposes a FACE-ONLY Modified surface, so bevel boundary edges and vertices
  /// the history cannot attribute fall to the reserved `generated` role rather
  /// than being guessed into `chamfer-edge`.
  ///
  /// Sheet-metal domain (native-kernel sheet-metal wave):
  ///
  /// - `BaseFlange` is DECLARED for the domain's symmetry and for
  ///   `role(...)` queries to name against, but `base_flange` itself never
  ///   constructs it: the operation is a root BIRTH (a profile swept into a
  ///   thin solid, no target consumed) exactly like `extrude`, so its harvest
  ///   travels through `HarvestBirth`/`BirthClass::Extrude` — the SAME reason
  ///   `extrude`/`revolve`/`loft`/`sweep` are `BirthClass` members and not
  ///   `OperationClass` members. Every switch below still carries a real
  ///   `BaseFlange` case (never a `default:`) so a future direct use stays
  ///   type-checked.
  /// - `EdgeFlange` is DESIGNED for the hole/offset tool-operand mold — the
  ///   target's untouched faces identity-survive as `modified`; the
  ///   synthetic new-material solid's (flat panel + bend infill) surviving
  ///   flat faces re-mint as `panel`; faces the bend's paired fillets
  ///   generate re-mint as `bend` — but is likewise never constructed today.
  ///   MEASURED (sheet_metal_feature.cpp's own comment on its
  ///   `EvaluateEdgeFlange` naming block has the full account):
  ///   `BRepFilletAPI_MakeFillet`'s history is ALREADY documented as
  ///   face-only-reliable for a single, uncomposed fillet (Fillet's own
  ///   role-table comment above); composed through the upstream fuse this
  ///   file's bend construction needs first, the rebuilt history does not
  ///   carry enough for `ElementNameBook`'s lower-bound reconstruction to
  ///   attribute every edge/vertex, and unlike offset's ShapeUpgrade-
  ///   SameDomain simplification stage there is no cheaper history-
  ///   preserving alternative to a real fillet call here. `edge_flange`
  ///   mints its result the SAME AddDerivedPrimitive/HarvestCopiedBody way
  ///   as `Unfold` below instead. This role table is left fully designed and
  ///   type-checked (not reduced to a throwing stub) so a future fix to the
  ///   history-composition gap can wire `HarvestOperation` straight to it.
  /// - `Unfold` is DECLARED for the same reason as `BaseFlange` and is
  ///   likewise never constructed: neither of unfold's two born bodies has a
  ///   Modified/Generated boolean history to harvest through
  ///   `HarvestOperation`. The folded pass-through is an identity copy of the
  ///   target and the flat pattern is a from-scratch reconstruction (each
  ///   panel's own face rigidly repositioned, each bend replaced by a fresh
  ///   flat allowance strip) — both mint through `HarvestCopiedBody` (the
  ///   `import_step`/`import_mesh` "no authored construction frame" mold),
  ///   uniformly as `panel` faces, since the copied-body mint takes one role
  ///   per kind and a strip-vs-reused-panel distinction is not load-bearing
  ///   for `role(...)` queries the way panel-vs-bend is on the folded body.
  ///   See sheet_metal_feature.cpp for both harvests.
  ///
  /// Surfacing domain (native-kernel Surfacing wave; surfacing_feature.cpp
  /// investigates each of these four independently rather than assuming one
  /// outcome for all — see that file's own header comment for the full
  /// per-operation reasoning):
  ///
  /// - `SurfaceOffset` is DECLARED but never constructed: it runs the exact
  ///   same whole-shape `BRepOffsetAPI_MakeOffsetShape::PerformByJoin` call
  ///   `offset`'s own v1 whole-body path uses (geometry.cpp), and that path
  ///   is ALREADY documented there as naming-unverified — `surface_offset`
  ///   applies the identical fail-closed guard instead of re-opening a
  ///   question this codebase already closed once.
  /// - `Stitch` is DECLARED but never constructed: `BRepBuilderAPI_Sewing`
  ///   extends `Standard_Transient` directly, not `BRepBuilderAPI_MakeShape`
  ///   (confirmed by reading its header), so `LocalOperationHistorySource`
  ///   (built around the `BRepBuilderAPI_MakeShape` Modified/Generated/
  ///   IsDeleted surface every other local-operation harvest in this
  ///   codebase wraps) has nothing compatible to adapt — Sewing's own
  ///   `Modified()` returns a single shape, not the list `BRepTools_History`
  ///   expects.
  /// - `BoundarySurface` is DECLARED but never constructed: its
  ///   `targetOperationId` body is a READ-ONLY reference (never consumed,
  ///   the same non-consuming shape `mirror`'s `merge: false` and
  ///   `datum_plane`'s backing face already use), so the boundary edges it
  ///   fills between stay live on a body that is NOT this operation's
  ///   result — `HarvestOperation`'s whole model (assign Modified/Generated
  ///   images of CONSUMED operands into the one new result) does not fit an
  ///   operand that survives elsewhere. Its new face mints fresh via
  ///   `AddDerivedPrimitive` instead (its boundary edges/vertices are
  ///   literally the target's own, already named).
  /// - `Thicken` is DECLARED but never constructed, a finding reached only
  ///   after actually testing the optimistic case, not by assumption: it
  ///   uses `BRepOffsetAPI_MakeThickSolid`, the exact class `shell`'s own
  ///   open-container branch already harvests successfully — but `thicken`
  ///   needs `MakeThickSolidBySimple`, not shell's `MakeThickSolidByJoin`
  ///   (measured: `ByJoin` with an empty closing-faces list never builds a
  ///   genuine closing collar at all, see surfacing_feature.cpp's own
  ///   comment on `EvaluateThicken`), and `BySimple`'s own Modified()/
  ///   Generated() surface is measurably thinner: even a single, UNCOMPOSED
  ///   call on a bare planar rectangle — no fuse, no composition of any kind
  ///   — still throws inside `ElementNameBook::ApplyOperation` ("cannot
  ///   attribute a result entity ... bare quantized-geometry root"), the
  ///   SAME failure class `EdgeFlange`'s composed fuse->fillet chain hits
  ///   above, but here from the primitive's OWN limited history rather than
  ///   from composition depth. All three direction modes ("normal",
  ///   "reverse", "symmetric") mint fresh via `AddDerivedPrimitive` instead.
  ///
  /// Electrical domain (native-kernel electrical wave 1;
  /// electrical_routing_feature.cpp):
  ///
  /// - `WireRoute` is DECLARED but never constructed, for an even more
  ///   fundamental reason than any Surfacing-wave member above: `wire_route`
  ///   does not merely have a history too thin to attribute (Thicken) or a
  ///   read-only unconsumed operand (BoundarySurface) — it consumes NO
  ///   existing body's topology AT ALL. Its spine (a `GeomAPI_Interpolate`
  ///   B-spline) and its circular profile are both built fresh from resolved
  ///   point COORDINATES; even `startVertex`/`endVertex`, the operation's
  ///   only topology references, are read only for their `gp_Pnt` and are
  ///   never fed into the sweep as TopoDS operands. There is therefore no
  ///   `NamingRegistry::Input` for `HarvestOperation` to attribute
  ///   Modified/Generated images against — `inputs` would be empty by
  ///   construction, not merely thin — which was traced through to the SAME
  ///   observable failure `Thicken` hit (`ElementNameBook::ApplyOperation`'s
  ///   multi-pass naming has no history to key any result sub-shape off, so
  ///   every one falls to the bare quantized-geometry fallback, which
  ///   `HarvestOperation`'s own classification loop explicitly rejects via
  ///   `IsBareQuantizedRoot` below) and confirmed by an actual run — see
  ///   electrical_routing_feature.hpp's own doc comment on
  ///   `EvaluateWireRoute` for the full account, and
  ///   test/electrical_routing_test.cpp's
  ///   `WireRouteHarvestOperationEmptyInputInvestigation` for the direct
  ///   measurement itself. `wire_route` mints its result fresh via
  ///   `AddDerivedPrimitive` instead, joining the Surfacing wave's own
  ///   "declared but never constructed" set.
  ///
  /// Mold/tooling domain (native-kernel mold/tooling wave;
  /// mold_tooling_feature.cpp): `MoldPartingLine`, `MoldShutoffSurface`,
  /// `MoldPartingSurface`, `MoldToolingSplit` are ALL FOUR declared for the
  /// same `-Wswitch` exhaustiveness reason as every member above, and ALL
  /// FOUR are never constructed through `HarvestOperation` either —
  /// investigated per-operation (mold_tooling_feature.hpp's own header
  /// comment has the full per-operation account): `MoldPartingLine` and
  /// `MoldShutoffSurface` are architecturally identical to `BoundarySurface`
  /// (a read-only, unconsumed target); `MoldPartingSurface` sweeps a wire
  /// into entirely new material; `MoldToolingSplit` produces its solids via
  /// `BRepAlgoAPI_Splitter`, which DOES retain a real, usable `History()`
  /// (this wave's own ctest spike confirms it) but wiring that history
  /// through `ElementNameBook::ApplyOperation` for MULTIPLE disjoint output
  /// solids sharing ONE history object is real, uninvestigated surface area
  /// this v1 does not open (the Surfacing wave's own `Thicken` lesson: a
  /// working `History()` does not by itself guarantee `ElementNameBook` can
  /// attribute every result entity through it). All four mint fresh via
  /// `AddDerivedPrimitive` instead, joining the Surfacing/Electrical waves'
  /// own "declared but never constructed" set.
  enum class OperationClass {
    Boolean,
    Hole,
    Fillet,
    Transform,
    Shell,
    Mirror,
    Pattern,
    Chamfer,
    Offset,
    BaseFlange,
    EdgeFlange,
    Unfold,
    BoundarySurface,
    SurfaceOffset,
    Stitch,
    Thicken,
    WireRoute,
    MoldPartingLine,
    MoldShutoffSurface,
    MoldPartingSurface,
    MoldToolingSplit
  };

  /// One harvested input body: the EXACT shape the algorithm consumed plus
  /// its operand class (tool operands take the tool-* / wall roles).
  struct Input final {
    TopoDS_Shape shape;
    bool tool{};
    /// A SYNTHETIC operand has no document identity (the hole's cylinder is
    /// synthesized from parameters, never a body): its scaffolding `tool`
    /// records exist only to give descendants real ancestor tokens, so a
    /// synthetic sub-shape that survives or is modified into the result is
    /// RE-MINTED under the operation's role and its scaffolding record dies —
    /// an internal `tool` role must never leak onto a live result entity.
    bool synthetic{};
  };

  /// Explicit semantic table for a body-producing operation with no retained
  /// OCCT history. The start/end boundaries are authored construction planes,
  /// not inferred extrema: that keeps a rotated primitive, a 180-degree
  /// partial revolve (coincident infinite cap planes), and a bent sweep from
  /// silently changing roles when geometry moves. `faceExpected=false` keeps
  /// a real boundary for edge/vertex classification while stating that the
  /// solid has no cap face there (a pointed cone or knife-edge wedge).
  enum class BirthClass { Cylinder, Sphere, Cone, Torus, Wedge, Extrude, Revolve, Loft, Sweep };

  struct BirthBoundary final {
    gp_Pnt anchor;
    gp_Dir normal;
    bool faceExpected{true};
  };

  struct BirthSpec final {
    BirthClass operationClass;
    std::optional<BirthBoundary> start;
    std::optional<BirthBoundary> end;
  };

  /// The composed element-name book. geometry.cpp records the tranche-N0
  /// naming passes into EXACTLY this book when a registry is threaded, so
  /// harvest reads the same lineage names the wire projection would emit.
  ElementNameBook& Book() { return book_; }
  const ElementNameBook& Book() const { return book_; }

  /// Harvests a create_box birth (catalog 02 role table, face rows):
  /// `bottom` / `top` / `side` classified against the placement z direction,
  /// edges and vertices under the reserved `generated` role. Fails loudly if
  /// the shape is not a 6-face/12-edge/8-vertex planar box or a face defies
  /// the ±cos(1°) classification bands. Requires Book().AddPrimitive to have
  /// named the shape first.
  void HarvestBoxBirth(const std::string& operationId, const TopoDS_Shape& shape,
                       const gp_Dir& placementZ, const std::atomic_bool& cancelled);

  /// Harvests a non-box body birth through its explicit semantic role table.
  /// Primitive roles follow catalog 02 (`bottom`/`top`/`wall`/`seam` and
  /// boundary edge roles); profile features use `cap-start`/`cap-end`, `side`,
  /// `side-edge`, and `vertex`. Sphere pole closures are real OCCT topology and
  /// receive the explicit `pole-edge` role even though their geometric length
  /// is zero. Requires Book().AddPrimitive to have named the shape first.
  void HarvestBirth(const std::string& operationId, const TopoDS_Shape& shape,
                    const BirthSpec& spec, const std::atomic_bool& cancelled);

  /// Mints an IMPORTED body birth (CAP-011): `import_step` and `import_mesh`.
  ///
  /// An import is the one body birth with no authored construction frame, so it
  /// gets no semantic role table. Every face/edge/vertex of the read-back shape
  /// lands in one flat per-kind bucket — `imported-face` / `imported-edge` /
  /// `imported-vertex` — because classifying read-back topology as `top` or
  /// `wall` would be an inference about a file the kernel did not build, and a
  /// wrong-but-deterministic role is precisely the silent misreference the
  /// zero-silent-misreference law exists to exclude. The roles claim exactly
  /// what is known: this entity was born by this import.
  ///
  /// Identity still rests on the lineage name, not the role: `AddPrimitive`
  /// names sub-shapes in `TopExp::MapShapes` order, and identical retained
  /// bytes read back to identical topology (the step-reimport oracle in
  /// mutation.cpp, which already asserts two independent reads earn identical
  /// names), so the mint is replay-deterministic. Requires
  /// `Book().AddPrimitive` to have named `body` first; an entity the book
  /// cannot name fails the request loudly.
  void HarvestImportedBody(const std::string& operationId, int outputIndex,
                           const TopoDS_Shape& body, const std::atomic_bool& cancelled);

  /// Registers a synthesized (non-document) tool body — the hole's cylinder —
  /// under the consuming operation's id with the internal role `tool`, so the
  /// subsequent HarvestOperation can attribute images to real tokens. The
  /// records die in that harvest's liveness sweep unless a sub-shape
  /// survives into the result. Requires Book().AddPrimitive first.
  void HarvestSyntheticTool(const std::string& operationId, const TopoDS_Shape& tool,
                            const std::atomic_bool& cancelled);

  /// Mints a fresh INDEPENDENT body whose result topology IS exactly the shape
  /// harvested — the operand was copied, not fused, so no OCCT history maps its
  /// entities. Three producers use it: the two catalog-wave-2 copies below
  /// (both leave their source/seed live and distinct), plus the imports, which
  /// pass an EMPTY correspondence map because they descend from file bytes
  /// rather than a document entity (see HarvestImportedBody above):
  ///
  /// - `mirror` with `merge: false` — the reflected copy, roles
  ///   `mirrored` / `mirrored-edge` / `mirrored-vertex`;
  /// - a single-instance `fuseInstances` pattern (the W_PATTERN_COUNT_ONE
  ///   degenerate: one transformed copy, no boolean), roles
  ///   `instance-face` / `instance-edge` / `instance-vertex`.
  ///
  /// `faceRole` / `edgeRole` / `vertexRole` name the three per-kind buckets;
  /// ordinals are lineage-first (ADR-006). `copyToSource` optionally maps each
  /// copy sub-shape (IsSame) to the source sub-shape it descends from (the
  /// BRepBuilderAPI_Transform 1:1 `Modified` image, reversed) so the mint records
  /// the source's newest token as an ancestor and provenance/adjacency queries
  /// stay truthful; an empty map mints without ancestors. Requires
  /// Book().AddPrimitive to have named `body` first and every mapped source
  /// sub-shape to already hold a record.
  void HarvestCopiedBody(
      const std::string& operationId, const TopoDS_Shape& body, const std::string& faceRole,
      const std::string& edgeRole, const std::string& vertexRole,
      const NCollection_DataMap<TopoDS_Shape, TopoDS_Shape, TopTools_ShapeMapHasher>& copyToSource,
      const std::atomic_bool& cancelled, int outputIndex = 0);

  /// Registers a datum operation's single SYNTHETIC entity (plan 02 §2.3;
  /// catalog wave 1): role `plane` backs a face-kinded record
  /// `t:<opId>/plane/0`, role `axis` an edge-kinded `t:<opId>/axis/0`. The
  /// datum has no history object — the entity is minted directly: the backing
  /// shape is named in the composed book (AddPrimitive root) and one record
  /// is appended with a HAND-BUILT geometric key (quantized `anchor`
  /// centroid, measure 0) so the bounded backing proxy's finite extent never
  /// leaks into §6.4 ordering. The record is epoch-local like every other
  /// (ADR-003); its shape belongs to NO visible body — the selector
  /// evaluator's sources refuse such records fail-closed until the
  /// synthetic-entity resolution tranche lands.
  void RegisterDatumEntity(const std::string& operationId, const std::string& role,
                           const TopoDS_Shape& backing, const gp_Pnt& anchor,
                           const std::atomic_bool& cancelled);

  /// Mint selectable sketch edges in one semantic role. `semanticId` is the
  /// durable sketch eid/sub-eid (never an array index); it roots the lineage
  /// sort so adding unrelated geometry does not silently retarget an existing
  /// reference. `role` distinguishes construction axes from ordinary sketch
  /// path/boundary curves, while `lineageNamespace` keeps their element-name
  /// roots truthful. Multiple candidates remain explicitly ambiguous unless a
  /// recorded anchor/token disambiguates.
  void RegisterSketchEdges(const std::string& operationId, const std::string& role,
                           const std::string& lineageNamespace,
                           const std::vector<std::pair<std::string, TopoDS_Shape>>& edges,
                           const std::atomic_bool& cancelled);

  /// The §6.3 harvest for one mutating operation, run AFTER the book's
  /// ApplyOperation with the SAME inputs, result, and retained history.
  /// Every input sub-shape must already hold a registry record (fail
  /// closed). Assign-conflicts tie-break target-over-tool then
  /// modified-over-generated, with every losing provenance recorded in the
  /// minted record's ancestors.
  void HarvestOperation(const std::string& operationId, OperationClass operationClass,
                        const std::vector<Input>& inputs, const TopoDS_Shape& result,
                        const BRepTools_History& history, const std::atomic_bool& cancelled);

  /// Append-order record access (mint order; deterministic across replays).
  std::size_t RecordCount() const { return records_.size(); }
  const NamingRecord& RecordAt(std::size_t index) const;

  /// Token lookup over ALL records (live and dead). Null when unknown.
  const NamingRecord* FindByToken(const std::string& token) const;

  /// The per-kind byNormalizedLineageName index (§6.2), filtered to LIVE
  /// records, in mint order. More than one entry is either an alias set
  /// (records sharing one shape — the same entity answering to several
  /// tokens) or a genuine twin collision (distinct shapes): consumers MUST
  /// deduplicate by shape identity before treating cardinality as ambiguity.
  std::vector<const NamingRecord*> LiveByNormalizedName(char kind,
                                                        const std::string& normalizedName) const;

  /// Every token currently answering for `shape` (the §6.3 step-12 alias
  /// chain), oldest first. Empty when the shape holds no live record.
  std::vector<std::string> TokensOf(const TopoDS_Shape& shape) const;

  /// Tranche 2.1 replay seam: an immutable value copy of the FULL registry
  /// state — the composed book plus every record and index — so a cache entry
  /// can restore the naming lineage as of an operation prefix and a tail replay
  /// mints byte-identical records. The OCCT-keyed indices (`shapeIndex` and the
  /// book's map) copy their TopoDS_Shape keys by handle, preserving the IsSame
  /// identity a restored BodyPool's sub-shapes resolve against. RestoreFrom is
  /// a full replacement; a snapshot is reusable across restores.
  struct Snapshot final {
    ElementNameBook::Snapshot book;
    std::vector<NamingRecord> records;
    std::map<std::string, std::size_t> byToken;
    std::map<std::pair<char, std::string>, std::vector<std::size_t>> byNormalizedName;
    NCollection_DataMap<TopoDS_Shape, std::vector<std::size_t>, TopTools_ShapeMapHasher> shapeIndex;
  };
  Snapshot TakeSnapshot() const;
  void RestoreFrom(const Snapshot& snapshot);

private:
  // Defined in naming_registry.cpp (as `final`); the forward declaration omits
  // the specifier — MSVC rejects `final` on a non-defining declaration (C3197).
  struct MintPlan;

  /// `outputIndex` scopes the minted TOKENS to one born body of a multi-output
  /// birth (ADR-013 decision 2): index 0 mints the legacy
  /// `t:<opId>/<role>/<ordinal>` and anything above it mints
  /// `t:<opId>:<index>/<role>/<ordinal>`. `minter` stays the raw operation id
  /// either way, so every lookup BY OPERATION is unchanged.
  void MintBuckets(const std::string& operationId,
                   std::map<std::string, std::vector<MintPlan>>& buckets,
                   const std::atomic_bool& cancelled, int outputIndex = 0);

  ElementNameBook book_;
  std::vector<NamingRecord> records_;
  std::map<std::string, std::size_t> byToken_;
  /// (kind, normalizedLineageName) -> record indices in mint order.
  std::map<std::pair<char, std::string>, std::vector<std::size_t>> byNormalizedName_;
  /// IsSame-keyed answering sets at the CURRENT replay state (§6.2 byTShape):
  /// every record index whose entity currently IS this shape, oldest first.
  NCollection_DataMap<TopoDS_Shape, std::vector<std::size_t>, TopTools_ShapeMapHasher> shapeIndex_;
};

} // namespace aeth
