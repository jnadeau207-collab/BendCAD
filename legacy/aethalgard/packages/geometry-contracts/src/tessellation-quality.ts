/**
 * The single TS source of the tessellation-quality presets — named quality
 * levels mapped to their absolute deflection tolerances and the LOD tier
 * stamped into the AEMB packet.
 *
 * Today there is exactly one absolute preset: the MANUFACTURING-EXPORT
 * tessellation (finding-10) — a `0.02 mm` linear / `10°` angular chord
 * tolerance on every body regardless of size, reported as LOD tier 3 so its
 * packet and 3MF quality metadata are distinguishable from any viewport LOD
 * (tiers 0–2). These numbers were previously bare literals in the native host
 * (`native/kernel-host/src/tessellate.cpp`) and re-declared constants in the
 * desktop test fixtures; this module is the one TS place that owns them, so
 * every TS reader imports the same value.
 *
 * Viewport LOD (tiers 0–2) is deliberately absent: it is SIZE-RELATIVE
 * (diagonal-scaled in the native host, computed per body from its bounding
 * box), not a fixed-deflection preset, so it has no fixed number to record
 * here. Adding a future absolute level is appending a member to
 * {@link tessellationQualityLevels} and a row to {@link tessellationQualityTable}
 * — the exhaustive `Record` makes a level with no value a compile error. The
 * numbers are product/pipeline tuning, not arithmetic identities; keep them
 * here so every enforcement point reads the same constant.
 */

/** The deflection tolerances + provenance tier of one named quality level. */
export interface TessellationQuality {
  /** Absolute chord (linear) tolerance in millimeters; finite and positive. */
  readonly linearDeflectionMm: number;
  /** Absolute angular tolerance in radians; finite, positive, ≤ π. */
  readonly angularDeflectionRad: number;
  /** LOD tier stamped in the AEMB packet header (export = 3; viewport 0–2). */
  readonly lodTier: number;
}

/**
 * The named absolute-quality levels this table knows about, in declaration
 * order. Append-only: a new level is a new member here plus a row in
 * {@link tessellationQualityTable}.
 */
export const tessellationQualityLevels = ["manufacturing"] as const;

export type TessellationQualityLevel =
  (typeof tessellationQualityLevels)[number];

/**
 * The one table. Values are copied verbatim from the native host constants
 * (`kExportLinearDeflectionMm` / `kExportAngularDeflectionRad` /
 * `kExportLodTier`) and MUST stay numerically identical to them — a TS reader
 * and the C++ mesher have to agree on the export tessellation's identity.
 */
export const tessellationQualityTable: Readonly<
  Record<TessellationQualityLevel, TessellationQuality>
> = Object.freeze({
  /** finding-10 manufacturing export: 0.02 mm / 10° / LOD tier 3, absolute. */
  manufacturing: Object.freeze({
    linearDeflectionMm: 0.02,
    angularDeflectionRad: 0.17453292519943295, // 10 degrees
    lodTier: 3,
  }),
});

/**
 * Convenience alias for the manufacturing-export preset — the one absolute
 * quality that exists today. Identical reference to the table's row.
 */
export const manufacturingExportTessellationQuality: TessellationQuality =
  tessellationQualityTable.manufacturing;

/**
 * The quality preset for a named level. Throws for an unknown level (fail
 * closed, mirroring `checkSpec` in `@aeth/preflight`) — never happens for a
 * `TessellationQualityLevel`, but guards the lookup against a future desync.
 */
export function tessellationQuality(
  level: TessellationQualityLevel,
): TessellationQuality {
  const quality = tessellationQualityTable[level];
  if (!quality) {
    throw new Error(`Unknown tessellation quality level "${String(level)}"`);
  }
  return quality;
}
