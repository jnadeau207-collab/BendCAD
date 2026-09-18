#pragma once

#include <atomic>

#include <nlohmann/json.hpp>

#include "geometry.hpp"

namespace aeth {

class BodyPool;
class NamingRegistry;

/**
 * Native executor for the staged `shell` operation (catalog wave 1;
 * docs/design/2026-07-19-native-catalog-wave1.md §3; plan 01-geometry-core/04
 * `shell`). Shell CONSUMES its target body (the fillet/offset taxonomy) and
 * produces one hollowed body.
 *
 * CLOSED HOLLOW (absent or empty-resolved `openFaces`) executes fully:
 * recorded divergence from the plan's MakeThickSolidByJoin mapping — on the
 * pinned OCCT, ByJoin with an EMPTY ClosingFaces list returns the plain
 * offset solid, silently NOT a hollow (BRepOffset_MakeOffset::MakeThickSolid,
 * the `!myFaces.IsEmpty()` guard) — so the hollow is built by decomposition
 * into two verified primitives: the offset stage synthesizes the cavity
 * (`inward`: offset(target, -t)) or the grown skin (`outward`:
 * offset(target, +t)), and a nested BRepAlgoAPI_Cut produces the two-shell
 * solid. The synthesized solid is a SYNTHETIC operand exactly like the hole's
 * cylinder, so element naming and the registry harvest ride the verified
 * boolean history surface (OperationClass::Shell: synthetic face survivors
 * re-mint as `wall`, the target's faces identity-survive).
 *
 * `openFaces` (design note §3.3): resolution + every resolve-time validation
 * land NOW through the strict fillet-v2 slot path (persisted-form guard,
 * E_SEL_* refusals, face kind, on-target-body, not-all-faces-removed —
 * `details.shellCode` carries `E_SHELL_FAILED` / `E_SHELL_ALL_FACES_REMOVED`),
 * but the ByJoin EXECUTION stage is deferred fail-closed: a non-empty
 * resolved set refuses with an attributed UNSUPPORTED_OPERATION naming the
 * unverified thick-solid history surface. Without a registry the slot refuses
 * like every ref slot does.
 *
 * Geometry failures of the closed-hollow pipeline probe `thickness` with the
 * Wave 2.4 bounded-feasibility search (full offset+cut pipeline per candidate)
 * and throw GEOMETRY_FAILED. When a bound is found the details are EXACTLY the
 * strict offset/fillet-shaped `feasibilityProbe` triple with NO `shellCode`
 * (the `.strict()` thickness variant forbids it; the fine
 * `E_SHELL_THICKNESS_TOO_LARGE` intent is implied by `parameter: "thickness"`).
 * Only when no bound is found do the details carry
 * `{shellCode: "E_SHELL_FAILED", probeSkipped: true}`.
 */
EvaluatedBody EvaluateShell(const nlohmann::json& operation, BodyPool& pool,
                            ElementNameBook* elementNames, NamingRegistry* registry,
                            const std::atomic_bool& cancelled);

} // namespace aeth
