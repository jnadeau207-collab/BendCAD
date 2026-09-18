#pragma once

#include <atomic>
#include <vector>

#include <TopoDS_Face.hxx>
#include <TopoDS_Shape.hxx>
#include <gp_Dir.hxx>
#include <nlohmann/json.hpp>

#include "geometry.hpp"

namespace aeth {

class BodyPool;
class NamingRegistry;

/**
 * Native executors for the Mold/tooling domain (`mold_parting_line`,
 * `mold_shutoff_surface`, `mold_parting_surface`, `mold_tooling_split`) plus
 * the shared analytic draft classifier `ClassifyDraftFaces` both this file's
 * own `mold_parting_line` executor AND the `mold_draft_analysis` top-level
 * RPC method (server.cpp) call — one source of truth for "what does draft
 * analysis say about this face", never two independently-drifting
 * implementations (the same "one projection, two doors" shape the
 * `inspect_document`/snapshot-resource MCP precedent already established).
 *
 * Real-world reference: SolidWorks Mold Tools (Draft Analysis -> Parting
 * Line -> Shut-Off Surfaces -> Parting Surface -> Tooling Split; pull
 * direction, draft angle, positive/negative/no-draft/straddle faces).
 * `mold_draft_analysis` is deliberately NOT a tree feature (see server.cpp's
 * own doc comment on the RPC method) — real SolidWorks doesn't tree-feature
 * Draft Analysis either (a display mode, not a FeatureManager entry) and
 * Fusion 360 has no dedicated mold workspace at all, confirming an
 * inspect-only query is authentic scope, not a shortcut.
 *
 * ALL FOUR operations below are read-only over every body they reference —
 * `targetOperationId` / `partingLineOperationId` / `shutoffSurfaceOperationId`
 * / `partingSurfaceOperationId` / `extraSplitSurfaceOperationIds` are every
 * one a non-consuming reference (the mirror `merge:false` / `datum_plane` /
 * `boundary_surface` taxonomy, resolved via `BodyPool::PeekVisibleBodies`,
 * never `BodyPool::Consume`) — deliberately, not incidentally: a mold
 * workflow chains FOUR steps off the SAME source part, and
 * `mold_tooling_split` alone needs simultaneous, live access to the part,
 * the parting surface, AND the shut-off surface, which a consuming design
 * could never support once any earlier step had eaten one of them.
 *
 * NAMING/REGISTRY: `NamingRegistry::OperationClass` gained four members
 * (`MoldPartingLine`, `MoldShutoffSurface`, `MoldPartingSurface`,
 * `MoldToolingSplit`) with exhaustive case coverage in every switch
 * naming_registry.cpp has over that enum — REQUIRED even though none of the
 * four ever constructs through `HarvestOperation` (the Surfacing wave's own
 * `BoundarySurface`/`Stitch`/`Thicken` precedent: a real case is required
 * everywhere so the switch stays exhaustive under `-Wswitch`). Investigated
 * per-operation, not assumed uniform, exactly like the Surfacing wave's own
 * per-op investigation (surfacing_feature.hpp's header comment):
 *
 * - `MoldPartingLine`'s output wire shares edge IDENTITY with its (unconsumed)
 *   target — its boundary is literally a subset of the target's own edges,
 *   never copied (see `EvaluateMoldPartingLine`'s own comment) — the exact
 *   `BoundarySurface` architecture: a read-only operand whose result is not
 *   itself the target, so `HarvestOperation`'s whole model (assign
 *   Modified/Generated images of a CONSUMED operand into the one new result)
 *   does not fit. Mints fresh via `AddDerivedPrimitive`, which — per its own
 *   doc comment — PRESERVES rather than overwrites any sub-shape that already
 *   carries a name (CAP-034's "swept/built from the target's own boundary"
 *   mold), so the wire's edges keep answering to their true target-lineage
 *   names/tokens and only the wire-as-a-body itself is new.
 * - `MoldShutoffSurface` is architecturally identical to `BoundarySurface`
 *   itself (per-edge `BRepOffsetAPI_MakeFilling`, target read not consumed) —
 *   mints fresh for the same reason.
 * - `MoldPartingSurface` sweeps the parting-line WIRE (a `BRepPrimAPI_MakePrism`
 *   on a bare wire — see this file's own header comment and the ctest spike
 *   that proved this shape is even buildable on this pinned OCCT) into a
 *   fresh shell; the swept side walls are new sub-shapes with no existing
 *   identity to inherit even under `AddDerivedPrimitive`'s "preserve if
 *   already named" rule — mints fresh.
 * - `MoldToolingSplit` produces its N solids via `BRepAlgoAPI_Splitter`, which
 *   DOES retain a real, usable `History()` (this file's own ctest spikes
 *   confirm it) — but wiring that history through
 *   `ElementNameBook::ApplyOperation`/`HarvestOperation` for MULTIPLE
 *   disjoint output solids sharing ONE history object, each needing its own
 *   per-body root-name scope, is real, uninvestigated surface area this v1
 *   does not open (the Surfacing wave's own repeated lesson: a class having a
 *   working `History()` does not by itself guarantee `ElementNameBook` can
 *   attribute every result entity through it — `Thicken`'s own measured
 *   divergence is the precedent for not assuming so without testing, and
 *   testing THAT composition is out of this wave's scope). `MoldToolingSplit`
 *   mints each of its N output bodies fresh via `AddDerivedPrimitive`
 *   instead, ONE call per body under the SAME operationId — the
 *   `import_step`/`EvaluateImportStepBodies` multi-solid-birth precedent
 *   (geometry.cpp's `produceRoot`, called once per solid, same operationId
 *   every time) rather than `unfold`'s own (which needed a registry-gated
 *   `HarvestCopiedBody` outputIndex scope because unfold's pass-through body
 *   mints nothing at all) — see `EvaluateMoldToolingSplit`'s own comment for
 *   why the import_step shape fits here and unfold's does not.
 */

/// Analytic per-face draft classification (positive/negative/no-draft/
/// straddle) relative to `pullDirection`, at `angleToleranceDeg` (0..30) of
/// tolerance around "vertical" (parallel to the pull direction — SolidWorks'
/// own "no draft" band).
enum class DraftClassification { Positive, Negative, NoDraft, Straddle };

struct DraftFaceResult final {
  TopoDS_Face face;
  DraftClassification classification;
};

/**
 * Classifies every face of `body` by sampling its ANALYTIC surface normal —
 * `GeomLProp_SLProps` via `geometry_measures.cpp`'s own `OutwardNormalAtPoint`
 * idiom, the exact same one `ComputeDihedralRange` already uses for edges —
 * NOT the faceted tessellation normals (`tessellate.cpp`'s `MeshData.normals`
 * back a SEPARATE, renderer-side-only live preview a sibling viewport-side
 * agent owns; they must never be confused for this authoritative computation
 * or the two could silently drift on a coarse mesh).
 *
 * For each face, several (u, v) samples are drawn from its parametric bounds
 * — `BRepTools::UVBounds`, filtered through `BRepClass_FaceClassifier` so a
 * non-rectangular trim never samples a point actually outside the face (a
 * grid corner landing off a circular or filleted trim is a real risk for a
 * naive UV-fraction sample, unlike `ComputeDihedralRange`'s 1-D edge-fraction
 * sampling, which has no such off-curve failure mode) — falling back to the
 * face's own area centroid (`BRepGProp::SurfaceProperties` projected onto the
 * surface via `GeomAPI_ProjectPointOnSurf`) on the rare sliver face where
 * every grid sample lands outside the trim.
 *
 * Per sample, `dot = pullDirection . outwardNormal`. `band = sin
 * (angleToleranceDeg)`: a face at EXACTLY `angleToleranceDeg` off vertical
 * (measured from the plane perpendicular to `pullDirection`) has |dot| ==
 * `band` (elementary trig: draft angle == 90 degrees - angle(normal, pull),
 * so cos(angle(normal,pull)) == cos(90 - draftAngle) == sin(draftAngle)).
 * Across a face's own samples, `hasPositive = max(dot) > band`, `hasNegative
 * = min(dot) < -band`; `hasPositive && hasNegative` classifies `Straddle`
 * (SolidWorks' "blue" case — the same min/max-range-then-fixed-threshold
 * shape `ClassifyFromRange`, geometry_measures.cpp, already uses for
 * dihedral mixed-sign detection), else `Positive`/`Negative`/`NoDraft` by
 * whichever bound fired (or neither).
 *
 * Face enumeration order is `TopExp::MapShapes(body, TopAbs_FACE, ...)` —
 * the SAME order every other wire topology projection in this codebase uses
 * (`DescribeTopology`, `ProjectElementNames`), so a caller correlating this
 * function's Nth result against a `topologySnapshot`/`elementNames`
 * projection of the SAME body/epoch gets the SAME face at the SAME index.
 *
 * Throws `std::invalid_argument` if `angleToleranceDeg` is outside [0, 30]
 * (the pinned schema's own authored range) or not finite.
 */
std::vector<DraftFaceResult>
ClassifyDraftFaces(const TopoDS_Shape& body, const gp_Dir& pullDirection, double angleToleranceDeg);

/**
 * `mold_parting_line`: finds the edge loop separating positive-draft faces
 * from negative-draft faces on `targetOperationId`'s (unconsumed) body along
 * `pullDirection`, and mints it as a new WIRE body (an open curve network —
 * NOT a solid, NOT a face; body-kind is derived from `ShapeProbes`, never a
 * stored field, the surfacing-wave rule applied unchanged here).
 *
 * ALGORITHM: calls the shared `ClassifyDraftFaces`, then walks every edge of
 * the target via `IncidentFacesOf` (topology_adjacency.hpp): an edge is a
 * PARTING-LINE CANDIDATE iff its two incident faces classify to opposite
 * SIGNS (one `Positive`, one `Negative` — a `NoDraft` or `Straddle` neighbour
 * never qualifies an edge on its own). The candidate edges are grouped into
 * loops via the shared `GroupEdgesIntoLoops` (topology_adjacency.hpp, new —
 * see its own doc comment); v1 accepts exactly ONE resulting loop.
 *
 * HLR IS A DEAD END for this (confirmed, not assumed):
 * `hlr_projection.cpp`'s pipeline returns FLATTENED 2D paper-space polylines
 * in the projector's own frame, never 3D edges on the model (its own header
 * comment: the view's scale is applied by the document layer, never there) —
 * unusable for locating a real 3D curve on the part. The face-classification
 * + edge-adjacency walk above is the only real option, and it happens to be
 * the SAME real limitation SolidWorks itself documents to its own users
 * (straddle faces shown in blue, "the software cannot automatically find
 * parting lines through them", requiring a manual Split Face) — this
 * executor refuses through a straddle face rather than fake a plausible-
 * looking curve through one, for the identical reason.
 *
 * Refusals (fail closed, `toolingCode` detail field — this domain's
 * `bendCode`/`surfaceCode`/`routeCode` equivalent):
 * - `E_PARTING_LINE_STRADDLE_FACE` (checked FIRST, before any edge walk: a
 *   straddle face poisons the sign-based walk fundamentally, wherever it
 *   sits on the body) — a face's own sampled normals span both signs.
 *   `details.faceToken` names the offending face's live registry token when
 *   a registry is threaded and the face already has one (an agent can act on
 *   it directly), omitted otherwise — never a guess at a name that cannot be
 *   proven live.
 * - `E_PARTING_LINE_NO_DRAFT_VARIATION` — zero candidate edges found (no
 *   edge anywhere has one `Positive` and one `Negative` incident face) —
 *   operationally identical to "every face is the same sign" for any body
 *   with a genuine parting line to find, and additionally, honestly, covers
 *   a body with signed faces that never happen to neighbour their opposite
 *   (e.g. separated only by `NoDraft` faces) without a separate code.
 * - `E_PARTING_LINE_MULTIPLE_LOOPS` — `GroupEdgesIntoLoops` either threw
 *   (the candidate edges do not resolve into simple closed loops at all) or
 *   returned other than exactly one loop; the message reports the loop count
 *   when known. v1 handles the single-outer-loop case, the overwhelmingly
 *   common one; multi-loop is a documented, honest v1.1 gap (mirrors
 *   `boundary_surface`'s identical single-loop v1 boundary), not a silent
 *   wrong answer.
 *
 * NAMING: see this file's header comment.
 */
EvaluatedBody EvaluateMoldPartingLine(const nlohmann::json& operation, BodyPool& pool,
                                      ElementNameBook* elementNames, NamingRegistry* registry,
                                      const std::atomic_bool& cancelled);

/**
 * `mold_shutoff_surface` (optional step — only needed when the part has
 * through-holes relative to the pull direction): caps every free-boundary
 * loop of `targetOperationId`'s body EXCEPT the one matching
 * `partingLineOperationId`'s own wire, into one new surface body (the knit
 * of every capped hole loop).
 *
 * ALGORITHM: `FreeEdgesOf(target)` (topology_adjacency.hpp), grouped into
 * loops via the shared `GroupEdgesIntoLoops`. A loop is the PARTING LINE
 * (excluded, never capped) iff its edge SET is exactly the parting-line
 * body's own edges, by `TopoDS_Shape::IsSame` identity — sound and exact
 * (no fuzzy geometric matching needed) because `mold_parting_line` never
 * copies the target's edges into its wire (see that executor's own
 * comment); every OTHER free loop is a hole to cap, filled via
 * `BRepOffsetAPI_MakeFilling`'s proven per-edge `Add(edge, GeomAbs_C0)`
 * pattern (`boundary_surface`'s own precedent, surfacing_feature.cpp) in
 * each loop's own walked order. The resulting cap faces are disjoint (one
 * per hole, never touching each other), so they are combined via
 * `BRepBuilderAPI_Sewing` — not `BRepAlgoAPI_Fuse` — the exact idiom
 * `stitch`'s own executor already uses to knit unrelated faces into one
 * body (surfacing_feature.cpp's `EvaluateStitch`), reused rather than
 * re-derived.
 *
 * v1 caps EVERY non-parting-line free loop automatically — no per-loop
 * opt-out picker (mirrors `boundary_surface`'s own no-selector v1 precedent:
 * no AQL predicate for "the free edges of a shape" exists to hand-pick a
 * subset with). A documented v1.1 gap, not an oversight.
 *
 * HONEST SCOPE LIMIT (discovered while implementing this executor, not in
 * the pinned spec's own algorithm sketch — surfaced here rather than
 * silently worked around): `target` is `mold_parting_line`'s OWN target —
 * an ordinary, fully closed/watertight `TopoDS_Solid`. An ORDINARY through-
 * hole in such a solid (a cylindrical wall face connecting a rim edge on
 * one outer face to a rim edge on another) is NOT a free edge — every one
 * of its edges, including both rims, is already shared by exactly two
 * faces (the standard manifold-solid definition; every operation this
 * codebase can produce a hole through — `hole`, `boolean_combine` cut —
 * already validates its result is a genuinely closed solid). So
 * `FreeEdgesOf(target)`, AS PINNED, only ever finds a hole loop to cap when
 * `target` ALREADY carries its own open boundary independent of any
 * ordinary hole — this v1 does not attempt the (real, and materially
 * harder) problem of deciding whether an ordinary closed hole's tunnel
 * crosses the parting surface's own span, which would need genuine new
 * topological analysis this wave did not investigate. `E_SHUTOFF_NO_HOLES`
 * is therefore the HONEST, correct outcome for the everyday case (an
 * ordinary closed part with an ordinary drilled hole) — this executor
 * fails closed rather than silently doing nothing, exactly the discipline
 * this catalog's own spikes apply to the two named empirical unknowns. See
 * mold_tooling_test.cpp's `ShutoffSurfaceNoHolesOnOrdinaryClosedPart` for a
 * test proving this refusal fires correctly (not merely a hand-wave), and
 * its other shut-off tests for the (real, working) case this executor DOES
 * serve: a target that already carries its own free boundary.
 *
 * Refusal: `E_SHUTOFF_NO_HOLES` (GEOMETRY_FAILED, `toolingCode` detail) — the
 * operation's ONE typed refusal code, covering every way capping the
 * target's holes can fail (mirrors `stitch`'s own single-code precedent,
 * `E_STITCH_NO_COMMON_BOUNDARY`): no free edges at all, free edges that do
 * not resolve into simple closed loops, every free loop being the parting
 * line itself (nothing left to cap), or a fill failing for one particular
 * hole loop. Told plainly through the message text at each call site, never
 * a silently empty result body (this codebase's "named, not zeroed" ethos,
 * the BOM panel's own mass-unknown handling cited as precedent).
 *
 * NAMING: see this file's header comment.
 */
EvaluatedBody EvaluateMoldShutoffSurface(const nlohmann::json& operation, BodyPool& pool,
                                         ElementNameBook* elementNames, NamingRegistry* registry,
                                         const std::atomic_bool& cancelled);

/**
 * `mold_parting_surface`: sweeps `partingLineOperationId`'s wire along ITS
 * OWN authored `pullDirection` (read back from that operation's own JSON —
 * one source of truth, never re-specified on this operation) by
 * `extensionDistanceMm` in BOTH directions, producing one new shell ready to
 * split a tooling block with; knits in `shutoffSurfaceOperationId`'s faces
 * too when referenced.
 *
 * WHY THIS EXECUTOR ALONE (with `mold_tooling_split`) TAKES `allOperations`:
 * every other executor in this codebase resolves a sibling operation only as
 * GEOMETRY (a body, or a ref-slot-resolved sub-shape) — never as a read of
 * that sibling's own AUTHORED PARAMETER VALUE. `pullDirection` is genuinely
 * only recorded on `mold_parting_line`'s own parameters (the pinned schema
 * deliberately does not re-specify it here — one source of truth, not a
 * drift-prone copy), so recovering it requires the operation's own JSON, not
 * just its evaluated body. `ExecuteOperation` (geometry.cpp) was extended
 * with one new `allOperations` parameter for exactly this — both of its call
 * sites already had the full array in scope under that exact name, so this
 * is a minimal, honest capability addition, not a smuggled side-channel (the
 * alternative — encoding a direction into the wire body's own geometry, or
 * inferring it from the wire's shape — would be exactly the "fake it"
 * shortcut this catalog's own doctrine forbids: not every wire has a
 * well-defined best-fit normal, and a non-planar parting line has none at
 * all).
 *
 * ALGORITHM: translates the parting-line wire by `-extensionDistanceMm`
 * along `pullDirection`, then `BRepPrimAPI_MakePrism`s it by
 * `2 * extensionDistanceMm` in ONE call — landing the swept shell's near and
 * far faces at `-extensionDistanceMm`/`+extensionDistanceMm` from the
 * original wire with NO internal seam to re-sew (a translate-then-single-
 * sweep, rather than two independent opposite-direction sweeps glued back
 * together, which would need a tolerance-based re-stitch of what should be
 * the exact same curve — avoidable, so avoided). `BRepPrimAPI_MakePrism` on
 * a bare `TopoDS_Wire` (never a face, unlike every existing call site in
 * this codebase — geometry.cpp's extrude/base_flange/local-face-offset,
 * sheet_metal_feature.cpp's `BuildRectPrismTool`) is genuinely novel
 * surface area for this codebase; see this file's own ctest spike, which
 * proves it produces a usable open shell on this pinned OCCT build BEFORE
 * this executor was written to depend on it. If `shutoffSurfaceOperationId`
 * is referenced, its faces are knit into the SAME shell via
 * `BRepBuilderAPI_Sewing` (`mold_shutoff_surface`'s own combine idiom,
 * reused).
 *
 * Refusal: `E_PARTING_SURFACE_SELF_INTERSECTS` (GEOMETRY_FAILED,
 * `toolingCode` detail) when the swept wire is non-planar enough that the
 * extrusion self-intersects (a real possibility for a non-planar parting
 * line) — checked both topologically (`BRepCheck_Analyzer`) and
 * geometrically (`BRepAlgoAPI_Check` with self-interference testing, the
 * `thicken` precedent for a primitive whose own construction does not
 * already guarantee non-self-overlap) — fail closed, matching
 * `boundary_surface`'s own `E_BOUNDARY_SURFACE_SELF_INTERSECTS` precedent
 * exactly.
 *
 * NAMING: see this file's header comment.
 */
EvaluatedBody EvaluateMoldPartingSurface(const nlohmann::json& operation,
                                         const nlohmann::json& allOperations, BodyPool& pool,
                                         ElementNameBook* elementNames, NamingRegistry* registry,
                                         const std::atomic_bool& cancelled);

/**
 * `mold_tooling_split`: cuts a tooling block (built around
 * `targetOperationId`'s bounding box, expanded by `block.marginXMm/YMm/ZMm`)
 * with the part and splits the remainder with the parting surface (plus any
 * `extraSplitSurfaceOperationIds` insert tools), producing 2..N solid
 * bodies: `outputBodyIds[0]` is always "core", `[1]` is always "cavity", any
 * further entries are "insert" role, ordered by
 * `extraSplitSurfaceOperationIds`'s own array order (author-controlled
 * intent, not geometry-sorted happenstance — the same reasoning `unfold`'s
 * own fixed folded/flat roles already rest on).
 *
 * `outputBodyIds` is a THIRD multi-output shape this catalog now has,
 * distinct from both existing ones: ALWAYS present with cardinality >= 2
 * (unlike `import_step`'s OPTIONAL-until-declared fan-out) AND
 * variable-length (unlike `unfold`'s fixed tuple-of-2) — ordering here is
 * semantic/asymmetric like `unfold`'s folded/flat pair, but cardinality is
 * variable like `import_step`'s declared solid count; neither existing
 * precedent fits verbatim, so this is genuinely its own third shape.
 *
 * ALGORITHM:
 * 1. Capped cut-tool solid: with a `shutoffSurfaceOperationId` reference,
 *    `BRepBuilderAPI_Sewing`s the part's own faces plus the shut-off's faces
 *    (the `mold_shutoff_surface`/`stitch` sew-and-rebuild-a-shell idiom,
 *    reused) into one closed shell, then `BRepBuilderAPI_MakeSolid`. Without
 *    a shut-off reference: the part solid is used directly WHEN it has no
 *    open boundary (`FreeEdgesOf` empty); a part with an open boundary and
 *    NO shut-off reference refuses (see below) rather than cutting with an
 *    unsewn part, which would tunnel any through-hole all the way through
 *    the block — real shut-offs exist precisely so the two mold halves
 *    PINCH at the hole instead. SAME HONEST SCOPE LIMIT as
 *    `mold_shutoff_surface` (see that executor's own doc comment): an
 *    ORDINARY closed hole through an otherwise-watertight part is not a
 *    free edge, so this safety check only fires for a target that already
 *    carries its own open boundary — it does not (today) detect "an
 *    ordinary closed hole whose tunnel needed a shut-off but never got
 *    one" the way its prose might suggest. Real, narrower than the prose
 *    implies, and stated here rather than silently left to look complete.
 * 2. Tooling block: `BRepPrimAPI_MakeBox` sized to the part's own bounding
 *    box (`ShapeProbes.bounds`, already computed) expanded by the three
 *    margins — the SAME primitive class geometry.cpp's own `create_box`
 *    path (`EvaluateBox`) uses; `EvaluateBox` itself is not reachable
 *    outside geometry.cpp's own anonymous namespace (checked before writing
 *    this file — no header declares it), so this executor calls
 *    `BRepPrimAPI_MakeBox` directly rather than reconstructing a synthetic
 *    `create_box` JSON operation to reuse the wrapper.
 * 3. `BRepAlgoAPI_Cut(block, cappedSolid)` -> the moldable block with the
 *    part's own cavity removed.
 * 4. `BRepAlgoAPI_Splitter(cutResult, tools=[partingSurface,
 *    ...extraSplitSurfaces])` -> a compound of solids. This file's own
 *    ctest spike proves `BRepAlgoAPI_Splitter` yields a correct 2-solid
 *    split from a genuinely NON-PLANAR shell tool on this pinned OCCT build
 *    (the existing `mutation.cpp` `RunPlanarSplitIntoHistory` fixture — real,
 *    proven, but test/naming-oracle-only infrastructure reached solely via
 *    `mutation_case`/`ocaf_case`, never a real feature — only ever exercises
 *    a PLANAR face tool) BEFORE this executor was written to depend on it.
 * 5. Explode the compound into its constituent solids and assign role by
 *    centroid position relative to the parting surface along
 *    `pullDirection` (read transitively: parting line -> parting surface ->
 *    this operation, via the SAME `allOperations` JSON lookup
 *    `mold_parting_surface` uses, chained one hop further) —
 *    pull-direction-POSITIVE centroid is "cavity" (the mold half the pull
 *    direction points OUT of — a DEFINITION this catalog states plainly
 *    rather than asserting as universal moldmaking convention, mirroring the
 *    honesty of every other definitional call in this catalog, e.g.
 *    `unfold`'s own kFactor default), negative is "core". Any solids beyond
 *    the core/cavity pair are "insert", assigned by
 *    `extraSplitSurfaceOperationIds` array order (author intent), not
 *    geometry.
 *
 * Refusal: `E_TOOLING_SPLIT_WRONG_SOLID_COUNT` (GEOMETRY_FAILED,
 * `toolingCode` detail) if the splitter does not yield EXACTLY
 * `2 + extraSplitSurfaceOperationIds.length` solids — fail closed, no
 * silent best-guess mapping, mirroring `import_step`'s own hard-fail-on-
 * mismatch precedent (geometry.cpp's `EvaluateImportStepBodies`, "a
 * declared-vs-produced mismatch is a hard failure, never a silent
 * truncation or a fabricated body"). This count check is KERNEL-ONLY — the
 * true solid count is only knowable once the splitter actually runs,
 * exactly mirroring `import_step`'s own precedent of leaving this class of
 * check out of the schema/document-model layer.
 * `E_TOOLING_SPLIT_CAP_TOOL_NOT_CLOSED` (GEOMETRY_FAILED, `toolingCode`
 * detail) when step 1 above cannot produce a valid closed solid cut tool —
 * either the sew does not close (a referenced shut-off that does not
 * actually meet the part's own boundary) or the part has an open boundary
 * with no shut-off referenced at all (see step 1's own account of why that
 * case fails rather than silently cutting with an open part). This second
 * code is NOT in the task brief's own pinned list verbatim — it is added
 * because folding "the cap tool never became a solid" into
 * `E_TOOLING_SPLIT_WRONG_SOLID_COUNT` would misdescribe a failure that has
 * nothing to do with the split's own output count (the splitter never even
 * runs), which this catalog's own doctrine (name the real failure, never
 * the nearest available label) argues against; it follows the SAME
 * `toolingCode` detail shape as every pinned code and is documented here,
 * in the commit, and in the final report exactly as prominently as the
 * pinned six.
 *
 * NAMING: see this file's header comment.
 */
std::vector<EvaluatedBody> EvaluateMoldToolingSplit(const nlohmann::json& operation,
                                                    const nlohmann::json& allOperations,
                                                    BodyPool& pool, ElementNameBook* elementNames,
                                                    NamingRegistry* registry,
                                                    const std::atomic_bool& cancelled);

} // namespace aeth
