#pragma once

#include <atomic>
#include <vector>

#include <nlohmann/json.hpp>

#include "geometry.hpp"

namespace aeth {

class BodyPool;
class NamingRegistry;

/**
 * Native executor for the staged `edge_flange` operation (sheet-metal wave).
 * Grows a NEW flat panel plus a radiused bend from a picked FREE edge of an
 * existing sheet-metal body. edge_flange CONSUMES its target (the fillet/
 * shell/chamfer taxonomy) and produces one modified body.
 *
 * OCCT has no sheet-metal/bend primitive at any version (confirmed by grep
 * across the vendored source tree — the same starting point shell_feature.hpp
 * documents for `shell`), so the bend is built from hand-composed, verified
 * primitives exactly as shell's closed hollow is:
 *
 * 1. The picked edge is resolved via the strict fillet-v2 ref-slot path
 *    (`ResolveRefSlotStrict` + `SingleResolvedEntity`, arity ONE), then
 *    sanity-checked with `ComputeDihedralRange`/`ClassifyDihedral` (the SAME
 *    call `geometry_measures.cpp` uses for dihedral classification
 *    elsewhere) to confirm it is a coherent boundary edge of a genuinely
 *    planar face — refusing `E_EDGE_FLANGE_NOT_PLANAR_BOUNDARY` otherwise.
 * 2. The flat (angle-zero) continuation panel and a SHARP-cornered wedge
 *    infill are built as ONE prism (`BRepPrimAPI_MakePrism`, the same
 *    primitive `extrude`/`base_flange` use) from a hand-derived pentagon
 *    cross-section, then fused to the target (`BRepAlgoAPI_Fuse`) — a clean
 *    coincident-face fuse, since the infill's near face is exactly the
 *    target's own perimeter wall face at the picked edge.
 * 3. The resulting SHARP corner has exactly two new crease edges at
 *    analytically-known 3D positions (the original picked edge, and that
 *    edge translated by the sheet thickness along the base face's inward
 *    normal) — rounding BOTH with `BRepFilletAPI_MakeFillet` (inner crease at
 *    `bendRadiusMm`, outer crease at `bendRadiusMm + thicknessMm`, the
 *    documented inside/outside bend-radius relationship) produces the
 *    genuine, tangent, uniform-thickness cylindrical bend band — OCCT's own
 *    fillet algorithm does the tangent-arc construction, rather than a
 *    hand-built `Geom_CylindricalSurface` trim, exactly the kind of "verify
 *    empirically, reuse a proven primitive" divergence shell_feature.hpp's
 *    own comment records for `MakeThickSolidByJoin`.
 * 4. Bend relief (`reliefType != "none"`) removes a small notch at each end
 *    of the bend line via `BRepAlgoAPI_Cut`, skipped at an end whose adjacent
 *    perpendicular wall is already the thin (~thicknessMm) original
 *    perimeter wall (nothing to tear) rather than a taller pre-existing
 *    flange panel (which WOULD interfere without relief).
 *
 * Every stage is validated with `BRepCheck_Analyzer` before proceeding; any
 * stage that fails refuses with `GEOMETRY_FAILED` and a `details.bendCode` of
 * `E_EDGE_FLANGE_NOT_PLANAR_BOUNDARY`, `E_EDGE_FLANGE_SELF_INTERSECTS`, or
 * `E_EDGE_FLANGE_RELIEF_FAILED` — never a degenerate or silently-wrong body.
 */
EvaluatedBody EvaluateEdgeFlange(const nlohmann::json& operation, BodyPool& pool,
                                 ElementNameBook* elementNames, NamingRegistry* registry,
                                 const std::atomic_bool& cancelled);

/**
 * Native executor for the staged `unfold` operation (sheet-metal wave).
 * CONSUMES the folded (bent) target body and births TWO bodies from ONE
 * operation — the SAME multi-output-birth mechanism `import_step` uses for a
 * multi-solid file (ADR-013): the returned vector always has exactly two
 * entries sharing `operation`'s id, `[0]` the folded pass-through (an
 * identity copy of the target, `outputIndex` 0, matching `outputBodyId` —
 * "pass-through" so downstream features may keep building on the 3D form)
 * and `[1]` the flat pattern (`outputIndex` 1, matching `outputBodyIds[1]`).
 * `ExecuteOperation` in geometry.cpp is the only caller and owns the
 * pool-production ORDER (see its own comment) — this function's return order
 * is always birth-index order, [folded, flat].
 *
 * Algorithm: classify every face of the target via `SurfaceClass`. Planar
 * faces are candidate flat panels. `edge_flange` always builds a bend as a
 * matched CONCENTRIC PAIR of cylindrical faces (inner at the stated
 * `bendRadiusMm`, outer at `bendRadiusMm + thicknessMm` — see
 * `EvaluateEdgeFlange`), so a bend is recognized here as exactly that: two
 * cylindrical faces sharing one axis line, whose radii differ by the
 * (derived, never assumed) thickness. A face-adjacency BFS with the
 * recognized bend faces removed decomposes the body into PANEL connected
 * components (each component naturally carries its own top/bottom/perimeter
 * faces together, sidestepping any separate top-vs-bottom pairing problem).
 * Two panel components are bend-adjacent iff a recognized bend's faces touch
 * both.
 *
 * The seed panel is the component containing the largest-area planar face
 * (a documented deterministic fallback: tracing back to literally the
 * `base_flange` operation would need the full document's operation list,
 * which no per-operation executor in this codebase receives — each one sees
 * only its own operation JSON plus the pool/registry). BFS from the seed
 * flattens each newly-reached component with a rigid transform composed from
 * its parent's (rotate by the bend's own NEGATIVE measured sweep angle about
 * the bend's own axis, then translate so the bend's allowance —
 * `BA = angleRad * (insideRadiusMm + kFactor * thicknessMm)` — separates the
 * two components' tangent lines exactly). A revisited component reached by a
 * second, independent bend refuses `E_UNFOLD_NOT_DEVELOPABLE`; zero
 * recognized bends refuses `E_UNFOLD_NO_BENDS`.
 *
 * `kFactorOverride`, when present, replaces every bend's kFactor uniformly.
 * When absent, this executor uses the documented default kFactor (0.44) for
 * every bend: a genuine per-bend "the kFactor edge_flange was actually
 * called with" is not retrievable here — this executor, like every other
 * operation executor in this codebase, sees only the target body's raw
 * topology plus the registry's lineage NAMES, never a prior operation's own
 * `parameters` JSON, and no cross-operation numeric side-channel exists to
 * carry it. This is a stated, deliberate scope limitation (documented rather
 * than silently guessed), not an oversight; `kFactorOverride` is the
 * escape hatch the wire contract already provides for exactly this gap.
 */
std::vector<EvaluatedBody> EvaluateUnfoldBodies(const nlohmann::json& operation, BodyPool& pool,
                                                ElementNameBook* elementNames,
                                                NamingRegistry* registry,
                                                const std::atomic_bool& cancelled);

} // namespace aeth
