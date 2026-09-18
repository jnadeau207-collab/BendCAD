#pragma once

#include <atomic>

#include <nlohmann/json.hpp>

namespace aeth {

class BodyPool;
class NamingRegistry;

/**
 * Native executors for the staged datum operations (catalog wave 1;
 * docs/design/2026-07-19-native-catalog-wave1.md §2; plan 01-geometry-core/02
 * §2.3/§2.5/§3). Datum operations produce NO body and no profile: each mints
 * exactly one synthetic entity in the naming registry — `t:<opId>/plane/0`
 * (kind 'f', role `plane`) for datum_plane, `t:<opId>/axis/0` (kind 'e', role
 * `axis`) for datum_axis — and nothing about it survives the request
 * (ADR-003 epoch-local identity).
 *
 * Both executors REQUIRE the naming registry: every mode carries at least one
 * topology ref, resolution runs through the N5 ResolveRef path over the
 * registry, and the minted entity lives in it. `registry == nullptr` (the
 * plain `evaluate_document` path, replay-cache included) refuses with an
 * attributed UNSUPPORTED_OPERATION — the fillet-v2 registry-guard precedent —
 * so the wave-1 staging contract stays fail-closed on the real wire until the
 * query-capable replay state threads a registry there.
 *
 * Failure taxonomy (plan 02 §3 tables): resolution failures surface as
 * SelectorFailure (E_SEL_EMPTY / E_SEL_AMBIGUOUS); reference-class violations
 * (non-planar base, off-plane axis, coincident points, non-rotational face)
 * throw OperationFailure INVALID_REQUEST with
 * `details.datumCode = "E_DATUM_INVALID_REFERENCE"` plus the plan's per-mode
 * fields — fine codes ride in `details`, never as new wire codes.
 */
void EvaluateDatumPlane(const nlohmann::json& operation, BodyPool& pool, NamingRegistry* registry,
                        const std::atomic_bool& cancelled);

void EvaluateDatumAxis(const nlohmann::json& operation, BodyPool& pool, NamingRegistry* registry,
                       const std::atomic_bool& cancelled);

} // namespace aeth
