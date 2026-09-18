#pragma once

#include <atomic>

#include <nlohmann/json.hpp>

#include "geometry.hpp"

namespace aeth {

class BodyPool;
class NamingRegistry;

/**
 * Native executors for the Surfacing domain (`boundary_surface`,
 * `surface_offset`, `stitch`, `thicken`) — the sheet-metal wave's sibling for
 * OPEN shapes (an unclosed `TopoDS_Shell` or a single `TopoDS_Face`) rather
 * than closed `TopoDS_Solid`s. `EvaluatedBody.shape` was already a generic
 * `TopoDS_Shape` (geometry.hpp) and `BodyPool`/`tessellate.cpp`/
 * `hlr_projection.cpp`/STEP export were already shape-agnostic before this
 * wave — verified, not assumed (surfacing_test.cpp exercises real
 * tessellation and STEP export of an open shell produced by these
 * executors). `ProbeShape` (geometry.cpp) needed one real fix, documented at
 * its own definition: `BRepGProp::VolumeProperties` on an open shape returns
 * a numerically-defined but PHYSICALLY MEANINGLESS number (an artifact of the
 * divergence theorem applied to an incomplete boundary), so `volume` is now
 * forced to 0 and `centerOfMass` switches to the surface (area-weighted)
 * centroid whenever a shape has no solid sub-shape — `solidCount` was already
 * the correct, reliable open-vs-solid discriminator and needed no change.
 *
 * All four executors below mirror sheet_metal_feature.hpp/.cpp's own
 * discipline: typed `OperationFailure` refusals (a `surfaceCode` detail
 * field, this domain's equivalent of sheet-metal's `bendCode`) rather than a
 * leaked OCCT exception, and every numeric test in surfacing_test.cpp is
 * hand-derived independently of this file's own arithmetic.
 *
 * NAMING/REGISTRY: `NamingRegistry::OperationClass` gained four members
 * (`BoundarySurface`, `SurfaceOffset`, `Stitch`, `Thicken`) with exhaustive
 * case coverage in every switch naming_registry.cpp has over that enum (the
 * sheet-metal wave's own `BaseFlange`/`Unfold` precedent: a real case is
 * required everywhere even when an operation never actually constructs
 * through `HarvestOperation`, so the switch stays exhaustive under
 * `-Wswitch`). Investigated per-operation, not assumed uniform:
 *
 * - `SurfaceOffset` uses the EXACT SAME whole-shape `BRepOffsetAPI_
 *   MakeOffsetShape::PerformByJoin` call geometry.cpp's own `offset` v1
 *   whole-body path already uses — and that path is ALREADY documented
 *   there as naming-unverified ("BRepOffsetAPI_MakeOffsetShape's IsDeleted/
 *   Modified/Generated surface is unverified against the pinned OCCT").
 *   `EvaluateSurfaceOffset` applies the identical fail-closed guard
 *   (`elementNames != nullptr` refuses UNSUPPORTED_OPERATION) rather than
 *   silently re-opening a question this codebase already closed once.
 * - `Stitch` cannot compose through `HarvestOperation` at all:
 *   `BRepBuilderAPI_Sewing` extends `Standard_Transient` directly, NOT
 *   `BRepBuilderAPI_MakeShape` (confirmed by reading its header) — so
 *   `LocalOperationHistorySource` (which every other local-operation harvest
 *   in this codebase, fillet/chamfer/shell/thicken, wraps around a real
 *   `BRepBuilderAPI_MakeShape`) has no compatible surface to adapt. Its own
 *   `Modified()`/`IsModifiedSubShape()` return single shapes, not the
 *   `TopTools_ListOfShape` shape `BRepTools_History` expects. `EvaluateStitch`
 *   mints its result fresh (`AddDerivedPrimitive`) instead.
 * - `BoundarySurface` mints fresh for a different, architectural reason: its
 *   `targetOperationId` body is a READ-ONLY reference (never consumed, the
 *   same non-consuming shape `mirror`'s `merge: false` and `datum_plane`'s
 *   backing face already use), so the boundary edges it fills between stay
 *   live on a body that is NOT this operation's result — `HarvestOperation`'s
 *   whole model (assign Modified/Generated images of CONSUMED operands into
 *   the one new result) does not fit an operand that survives elsewhere.
 * - `Thicken` was the initial HYPOTHESIS for a real positive case —
 *   `BRepOffsetAPI_MakeThickSolid` is the EXACT class shell_feature.cpp's own
 *   open-container branch already harvests successfully via
 *   `LocalOperationHistorySource` — but testing it directly disproved that
 *   hypothesis (this file's own two "MEASURED DIVERGENCE" comments on
 *   `EvaluateThicken` have the full account): shell's own call
 *   (`MakeThickSolidByJoin` with an empty closing-faces list) never builds a
 *   genuine closing collar at all for `thicken`'s "no faces removed" case, so
 *   `thicken` needs `MakeThickSolidBySimple` instead — and `BySimple`'s own
 *   retained history is too thin for `ElementNameBook::ApplyOperation` to
 *   attribute even a single, UNCOMPOSED call on a bare planar rectangle (the
 *   same "cannot attribute a result entity" failure edge_flange's composed
 *   fuse->fillet chain hits, but here from the primitive's own limited
 *   history rather than composition depth). `EvaluateThicken` therefore
 *   mints fresh via `AddDerivedPrimitive` for ALL THREE direction modes
 *   ("normal", "reverse", "symmetric") uniformly — `Thicken` joins the other
 *   three Surfacing classes in the "declared but never constructed" set.
 */

/**
 * `boundary_surface`: fills a target body's ENTIRE open boundary (v1 — every
 * free edge, found by native OCCT topology traversal, not a hand-picked edge
 * selection: no selector predicate for "the free edges of a shape" exists in
 * this codebase's AQL filter vocabulary today, so hand-picking an arbitrary
 * edge loop across one or more bodies, Fusion 360 Patch's "Boundary Edges"
 * selection, is a real v1.1 gap — it would need today's single-entity durable
 * -reference recorder extended to multi-entity recording) into one new face.
 *
 * `targetOperationId` is a READ-ONLY reference — the target stays live and
 * unconsumed (mirror `merge:false` / `datum_plane`'s own non-consuming
 * shape), so further features may keep building on it while the new capping
 * face becomes an independent body.
 *
 * Algorithm: every edge of the target incident to exactly ONE face is a free
 * boundary edge (the standard manifold-boundary definition sheet_metal_
 * feature.cpp's own IncidentFacesOf/EndNeedsRelief already walk the same way
 * via TopExp::MapShapesAndAncestors). Those free edges are walked into ONE
 * ordered closed loop by shared vertices; any vertex touched by other than
 * two free edges, or a second disconnected loop, refuses
 * `E_BOUNDARY_SURFACE_NOT_CLOSED` (as does a target with NO free edges at
 * all — already fully closed, nothing to cap). The loop is filled via
 * `BRepOffsetAPI_MakeFilling`, added edge-by-edge (`Add(edge, GeomAbs_C0)`,
 * position/G0 continuity only, per the wire contract) in walked order — the
 * per-edge overload, not a wire overload: THIS PINNED OCCT VERSION HAS NO
 * `BRepOffsetAPI_MakeFilling::Add(TopoDS_Wire)` overload at all (confirmed by
 * reading the vendored header), so the "whichever proves more robust,
 * investigate both" choice the plan flagged resolves to "only one exists."
 * `BRepOffsetAPI_MakeFilling` handles arbitrary non-planar 3D loops (an
 * energy-minimizing deformed surface, not a planar-only fit) — surfacing_test.cpp
 * proves this with a genuinely non-planar hexagonal loop (3 mutually-adjacent
 * faces removed from a box, the classic "cut cube corner" space hexagon, not
 * coplanar by construction) as well as a planar rectangular one whose fill
 * area is checked to exactly equal width x height. A fill that OCCT cannot
 * complete for the given loop (degenerate/self-intersecting) refuses
 * `E_BOUNDARY_SURFACE_SELF_INTERSECTS`.
 */
EvaluatedBody EvaluateBoundarySurface(const nlohmann::json& operation, BodyPool& pool,
                                      ElementNameBook* elementNames, NamingRegistry* registry,
                                      const std::atomic_bool& cancelled);

/**
 * `surface_offset`: offsets an existing OPEN surface body along its normal by
 * `distanceMm` (signed, nonzero — zero is refused as a plain invalid-argument
 * rather than silently accepted as a no-op) via `BRepOffsetAPI_MakeOffsetShape
 * ::PerformByJoin`, the SAME whole-shape call `EvaluateOffset`'s v1 path
 * already uses in geometry.cpp — applied here to an OPEN shape instead of
 * requiring a closed solid. CONSUMES its target (the offset result replaces
 * it), the boolean_combine/hole/offset taxonomy.
 *
 * Refuses `E_SURFACE_OFFSET_NOT_SURFACE` (INVALID_REQUEST) up front if the
 * target's OWN stored probes report `solidCount >= 1` — this operation is
 * surfacing-specific, never a silent rename of the existing local-face-offset
 * (`offset` with a `face` ref) or `shell` operations, both of which stay
 * solid-only. Refuses `E_SURFACE_OFFSET_SELF_INTERSECTS` (GEOMETRY_FAILED) on
 * any OCCT construction failure or an invalid result.
 *
 * NAMING: fails closed exactly like `offset`'s own v1 whole-body path
 * (`elementNames != nullptr` refuses UNSUPPORTED_OPERATION) — see this file's
 * header comment for why that existing, already-documented guard applies
 * unchanged here.
 */
EvaluatedBody EvaluateSurfaceOffset(const nlohmann::json& operation, BodyPool& pool,
                                    ElementNameBook* elementNames, NamingRegistry* registry,
                                    const std::atomic_bool& cancelled);

/**
 * `stitch`: sews exactly two bodies (`firstOperationId`/`secondOperationId`,
 * BOTH consumed — the boolean_combine taxonomy) into one via
 * `BRepBuilderAPI_Sewing` at `toleranceMm`. After sewing, every face of the
 * sewn result is regathered into one fresh `TopoDS_Shell` (SewedShape()'s own
 * TopoDS typing is not trusted — this file measures the rebuilt shell's own
 * manifold closure directly instead: every edge must be incident to EXACTLY
 * two faces). Fully closed -> wrapped with `BRepBuilderAPI_MakeSolid` and
 * finished as a solid; otherwise finished as an open surface body.
 *
 * Refuses `E_STITCH_NO_COMMON_BOUNDARY` (GEOMETRY_FAILED) — the operation's
 * ONE typed refusal code, covering every way the sew can fail to produce a
 * single coherent piece — when `BRepBuilderAPI_Sewing::NbContigousEdges()`
 * reports zero (nothing actually merged: the two bodies share no geometry
 * within tolerance) or when any later construction stage fails.
 *
 * NAMING: mints fresh (`AddDerivedPrimitive`, no registry harvest) for both
 * outcomes — see this file's header comment for the measured reason
 * (`BRepBuilderAPI_Sewing`'s API shape does not fit `BRepTools_History`).
 */
EvaluatedBody EvaluateStitch(const nlohmann::json& operation, BodyPool& pool,
                             ElementNameBook* elementNames, NamingRegistry* registry,
                             const std::atomic_bool& cancelled);

/**
 * `thicken`: extrudes an OPEN surface into a solid along its own normal by
 * `thicknessMm` (positive) via `BRepOffsetAPI_MakeThickSolid::
 * MakeThickSolidBySimple`. CONSUMES its target (fillet/shell taxonomy).
 *
 * MEASURED DIVERGENCE FROM THE INITIAL PLAN (surfacing_test.cpp caught this
 * — the same "verify, don't assume" discipline sheet_metal_feature.cpp's own
 * comments record): the initial plan, matching shell_feature.cpp's own
 * open-container call shape, was `MakeThickSolidByJoin` with an EMPTY
 * closing-faces list. Tested directly, that does NOT build a genuine closing
 * collar at all — it silently returns just the plain offset image (still
 * open, never a solid), identically whether the input is a bare
 * `TopAbs_FACE` or a `TopAbs_SHELL` wrapping that same face.
 * shell_feature.cpp's own use of this class never exercises the
 * EMPTY-closing-faces case (its own `openFaces` is always non-empty when it
 * takes the open-container branch at all), so there was no existing
 * in-codebase proof either way before this test caught it.
 * `MakeThickSolidBySimple` is the primitive actually documented for this
 * shape ("Non-closed shell or face is expected as input", its own header
 * comment) and is verified (surfacing_test.cpp) to build the real collar
 * directly, for a bare face with no rewrap needed. Its own documented
 * tradeoff — "does not support faces removing" because "intersections are
 * not computed during offset creation" — is a real limitation for a
 * self-intersecting or sharply creased surface, but irrelevant for the
 * planar and singly-curved (cylindrical) surfaces this file's own tests
 * cover — but MEASURED (surfacing_test.cpp, a cylinder thickened inward past
 * its own radius) to be a real gap in practice, not just a documented
 * theoretical one: the resulting "solid" stays topologically closed even
 * though its walls physically overlap in space, so it passes both
 * `IsDone()` and the plain topological `BRepCheck_Analyzer(shape, false)`
 * check silently — neither one is a self-intersection test. `EvaluateThicken`
 * therefore runs `BRepAlgoAPI_Check` with self-interference testing enabled
 * as an explicit additional gate on the result, the general whole-shape
 * self-intersection detector this codebase's other offset-family primitives
 * (`PerformByJoin`, used by `surface_offset` — verified via that operation's
 * own equivalent cylinder test, which needed no such extra gate) get for
 * free from their own intersection-aware construction.
 *
 * `direction`: "normal" and "reverse" grow the full `thicknessMm` to one side
 * (a plain sign flip on the offset value, the shell inward/outward
 * precedent) via a SINGLE untouched call on the live target. "symmetric"
 * grows `thicknessMm / 2` to each side (the real option Fusion 360 and
 * SolidWorks Thicken both ship) — OCCT has no two-sided thicken primitive,
 * so this file builds it as a synthetic half-offset scaffold
 * (`BRepOffsetAPI_MakeOffsetShape` by `-thicknessMm/2`, a plain open-surface
 * offset, no history composed through it) followed by one MakeThickSolidBy-
 * Simple of the FULL thickness from there, landing the far wall at
 * `+thicknessMm/2` and the near wall at `-thicknessMm/2` — exactly centered
 * on the original surface.
 *
 * Refuses `E_THICKEN_NOT_SURFACE` (INVALID_REQUEST) if the target's stored
 * probes report `solidCount >= 1`. Refuses `E_THICKEN_SELF_INTERSECTS`
 * (GEOMETRY_FAILED) on any OCCT construction failure (either stage) or an
 * invalid/non-solid result.
 *
 * NAMING: MEASURED DIVERGENCE FROM THE INITIAL PLAN, again (surfacing_
 * test.cpp): the plan was for "normal"/"reverse" (a single untouched call
 * directly on the live target, structurally identical to shell's own
 * already-proven `LocalOperationHistorySource`-wrapped harvest) to construct
 * through `HarvestOperation`. Tested directly, `MakeThickSolidBySimple`'s own
 * Modified()/Generated() surface is too thin for `ElementNameBook::
 * ApplyOperation` to attribute even this simplest possible case (no
 * composition at all) — the SAME "cannot attribute a result entity" failure
 * edge_flange's composed fuse->fillet chain hits, but here from the
 * primitive's own limited history rather than composition depth. All THREE
 * direction modes therefore mint fresh instead (`AddDerivedPrimitive`,
 * uniformly) — see this file's header comment and naming_registry.hpp's own
 * `OperationClass::Thicken` doc comment for the full account.
 */
EvaluatedBody EvaluateThicken(const nlohmann::json& operation, BodyPool& pool,
                              ElementNameBook* elementNames, NamingRegistry* registry,
                              const std::atomic_bool& cancelled);

} // namespace aeth
