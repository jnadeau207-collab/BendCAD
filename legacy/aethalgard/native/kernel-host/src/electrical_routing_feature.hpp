#pragma once

#include <atomic>

#include <nlohmann/json.hpp>

#include "geometry.hpp"

namespace aeth {

class BodyPool;
class NamingRegistry;

/**
 * Native executor for the Electrical/routing domain's one v1 primitive,
 * `wire_route` (native-kernel electrical wave 1). A wire-harness route is a
 * physical wire or cable — real CAD (SolidWorks Routing, confirmed against
 * its own documentation) turns a routed wire into ORDINARY SOLID GEOMETRY: a
 * thin pipe/tube swept along a smooth path, exactly the family `sweep`'s own
 * profile-along-path result already belongs to. `wire_route` therefore
 * carries NO new body-kind or lifecycle category: it finishes through this
 * file's own `FinishSolidBody` (the geometry.cpp original reproduced here —
 * see this file's .cpp for why) and participates in `BodyPool`/tessellation/
 * STEP export exactly like any other solid.
 *
 * DISPATCH SHAPE: `wire_route` READS two existing vertices
 * (`startVertex`/`endVertex`, both REQUIRED, NEITHER consumed) rather than
 * birthing purely from its own parameters the way a primitive or a
 * profile-swept feature (extrude/revolve/loft/sweep) does, so it mirrors the
 * Surfacing wave's own dispatch shape (surfacing_feature.hpp/.cpp) instead:
 * `(operation, pool, elementNames, registry, cancelled)`, dispatched via
 * `pool.Produce(EvaluateWireRoute(...))` in geometry.cpp's `ExecuteOperation`
 * — never `produceRoot` (there is no birth-role table to classify against;
 * see the NAMING paragraph below for the full account of why this operation
 * does not fit `NamingRegistry::BirthClass` either).
 *
 * ALGORITHM:
 *
 * 1. `startVertex`/`endVertex` are REQUIRED vertex-kinded (`'v'`) ref slots —
 *    the exact `ResolveRefSlotStrict` + `SingleResolvedEntity` strict path
 *    `edge_flange`'s `edge` and `datum_axis`'s `a`/`b` twoPoints slots
 *    already use (arity ONE), resolved against the peeked pool. Each
 *    resolves to a `TopoDS_Vertex`; `BRep_Tool::Pnt` extracts its concrete
 *    point. `registry == nullptr` refuses fail-closed
 *    (`UNSUPPORTED_OPERATION`) — the same `edge_flange`/datum precedent,
 *    since ref-slot resolution has no path to a concrete point without a
 *    registry to query.
 * 2. The ordered point sequence is `[startPoint, waypoints..., endPoint]`
 *    (`waypoints` may legally be empty — a direct point-to-point run).
 *    Refuses `E_WIRE_ROUTE_DEGENERATE` if any two CONSECUTIVE points in that
 *    sequence are coincident within tolerance — which subsumes "fewer than 2
 *    distinct points result" (coincident `startVertex`/`endVertex` with no
 *    waypoints is exactly the two-point coincident-consecutive-pair case)
 *    without a separate cardinality check; see the .cpp for why this is not
 *    merely a convenient shortcut but the literally correct set of cases.
 * 3. `GeomAPI_Interpolate` fits one smooth, non-periodic, natural-C2
 *    `Geom_BSplineCurve` through the whole sequence — genuinely new OCCT
 *    surface area for this codebase (zero prior `Geom_BSplineCurve`/
 *    `GeomAPI_Interpolate`/`GeomLProp_CLProps` usage anywhere in
 *    kernel-host, confirmed by search before writing this file). See the
 *    .cpp for the header-verified constructor shape actually used, which
 *    diverges from the initially-assumed `TColgp_Array1OfPnt` shape (that
 *    typedef is deprecated in the pinned OCCT in favor of
 *    `NCollection_HArray1<gp_Pnt>` directly — verified by reading the
 *    vendored header, not assumed).
 * 4. `GeomLProp_CLProps` samples curvature across the curve's FULL parameter
 *    range at a resolution that scales with the curve's own knot structure
 *    (see the .cpp for the reasoned density — not an arbitrary constant) and
 *    refuses `E_WIRE_ROUTE_BEND_TOO_TIGHT` (tightest radius of curvature
 *    found, in `details`) if any sampled radius (1/curvature; a curvature-0
 *    straight segment is an EXPLICIT infinite-radius case, never a live
 *    division) is tighter than `minimumBendRadiusMm`. This runs BEFORE the
 *    sweep below so an over-tight route never pays for the more expensive
 *    solid construction it cannot pass anyway.
 * 5. `BRepOffsetAPI_MakePipeShell` sweeps a circular profile of radius
 *    `diameterMm / 2`, centered on the curve's start point and perpendicular
 *    to its start tangent BY CONSTRUCTION (`gp_Ax2(startPoint, startTangent)`
 *    picks that plane directly — no reliance on `WithCorrection` to rotate a
 *    misaligned section the way `EvaluateSweep`'s own literal-polyline path
 *    needs it), along the validated curve. Refuses
 *    `E_WIRE_ROUTE_SELF_INTERSECTS` if the sweep fails, does not produce a
 *    single solid, or fails `BRepCheck_Analyzer` — the same discipline every
 *    other feature in this codebase already applies to its own final solid.
 *
 * Every refusal above is an `OperationFailure` carrying a `routeCode` detail
 * field (this domain's equivalent of sheet-metal's `bendCode` / surfacing's
 * `surfaceCode`).
 *
 * NAMING: `NamingRegistry::OperationClass::WireRoute` is declared (so every
 * switch over that enum stays exhaustive under `-Wswitch`, the sheet-metal/
 * surfacing `BaseFlange`/`Unfold`/`Stitch` precedent) but — MEASURED, not
 * assumed, the Surfacing wave's own standard — never constructed through
 * `HarvestOperation`: unlike every operation that DOES construct through it,
 * `wire_route` consumes NO existing body's topology at all. Its spine and
 * profile are built fresh from resolved point COORDINATES, never from an
 * existing sub-shape — even `startVertex`/`endVertex` are read only for
 * their `gp_Pnt`, never fed into the sweep as TopoDS operands — so there is
 * no consumed `NamingRegistry::Input` for `HarvestOperation` to attribute
 * Modified/Generated images against (`inputs` would be empty by
 * construction, not merely small). Traced against `HarvestOperation`'s own
 * implementation (naming_registry.cpp) and confirmed by an actual run (see
 * test/electrical_routing_test.cpp's
 * `WireRouteHarvestOperationEmptyInputInvestigation`, which drives
 * `NamingRegistry::HarvestOperation` directly against a hand-built
 * wire_route-shaped pipe with zero consumed inputs and prints the real
 * observed exception): with zero real inputs,
 * `ElementNameBook::ApplyOperation`'s multi-pass naming has no history to
 * key any result sub-shape off, so every one falls to the bare
 * quantized-geometry fallback, which `HarvestOperation`'s own classification
 * loop explicitly rejects (`IsBareQuantizedRoot`) — the identical failure
 * class `Thicken`'s own comment records, but reached here for an even more
 * fundamental reason (no consumed operand at all, not merely a thin one).
 * `wire_route` mints its result fresh via `AddDerivedPrimitive` instead,
 * joining `BoundarySurface`/`Stitch`/`Thicken`/`SurfaceOffset` in the
 * Surfacing wave's own "declared but never constructed" set — its closest
 * architectural analogue is actually `BoundarySurface` (reads existing
 * bodies without consuming them, mints an independent result that shares no
 * sub-shape identity with what it read).
 */
EvaluatedBody EvaluateWireRoute(const nlohmann::json& operation, BodyPool& pool,
                                ElementNameBook* elementNames, NamingRegistry* registry,
                                const std::atomic_bool& cancelled);

} // namespace aeth
