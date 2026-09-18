/**
 * `fit-compensation` — the printed-fit allowance a feature was BUILT with.
 *
 * A printer profile carries a fit-coin offset, a material and a nozzle; the
 * parts library turns those into a diametral clearance (`namedFit()`). This is
 * the record of that resolution, stored ON the operation at authoring time.
 *
 * WHY STORED RATHER THAN THREADED (docs/design/2026-07-28-fit-compensation-seam.md):
 *
 * - **Determinism.** Geometry stays a pure function of the document. Threading a
 *   live profile into evaluation would mean the same `.aeth` cuts differently on
 *   different machines.
 * - **The replay cache.** Living in `parameters`, this record is already inside
 *   the RFC 8785 canonical JSON the op-hash covers — so a different compensation
 *   is a different hash and the native BodyPool re-keys itself. Nothing to
 *   invalidate by hand, and no way to serve a stale body. It needs no change to
 *   the hasher, its `excludedKeys`, or the C++ mirror.
 * - **What a document means.** A hole a person dimensioned and committed is part
 *   of the design. It must not silently re-cut because the file moved to another
 *   machine, which is the failure a manufacturing tool exists to prevent.
 *
 * The cost, stated rather than hidden: editing a profile does NOT update
 * features already committed. Re-fitting them is an explicit action and is not
 * part of this contract.
 *
 * It carries the TERMS, not just the number, so the app can always answer "why
 * is this hole this size?" with the arithmetic — `namedFit()`'s own contract of
 * reporting the rule rather than asserting certainty, carried into the document.
 * Deliberately shaped as the general record so the thread primitive and every
 * later clearance consumer store this rather than inventing a parallel one.
 */
import { z } from "zod";

/**
 * The named FDM fit presets, as stored.
 *
 * Duplicated from `@aeth/parts-library`'s `fitNames` rather than imported:
 * contracts is a leaf package (zod only), and a document schema may not depend
 * on the table package it describes. The two lists are pinned equal by a test in
 * a package that CAN see both, so a preset added on one side cannot silently
 * become unstorable on the other.
 */
export const fitCompensationNameSchema = z.enum([
  "press",
  "snug",
  "slide",
  "free",
  "rattle",
]);

/** The four terms `namedFit()` sums, kept so the number can be explained. */
export const fitCompensationTermsSchema = z
  .object({
    /** The table's diametral base for this fit at the reference nozzle. */
    base: z.number().finite(),
    /** The nozzle / die-swell adjustment away from that reference. */
    nozzleScale: z.number().finite(),
    /** The material's own offset. */
    material: z.number().finite(),
    /** The profile's fit-coin offset — the person's measured correction. */
    user: z.number().finite(),
  })
  .strict();

/**
 * The resolved allowance a feature was built with. `clearanceMm` is DIAMETRAL
 * and never negative (`namedFit` floors it at zero).
 */
export const fitCompensationSchema = z
  .object({
    fit: fitCompensationNameSchema,
    clearanceMm: z.number().finite().nonnegative(),
    terms: fitCompensationTermsSchema,
    /** The human sentence naming every term that produced the number. */
    rule: z.string().trim().min(1).max(400),
    /** The table this came from, so the value is traceable to its source. */
    source: z.string().trim().min(1).max(200),
  })
  .strict();

export type FitCompensationName = z.infer<typeof fitCompensationNameSchema>;
export type FitCompensationTerms = z.infer<typeof fitCompensationTermsSchema>;
export type FitCompensation = z.infer<typeof fitCompensationSchema>;

/**
 * The diametral allowance a compensation adds, or zero when a feature carries
 * none — every consumer reads the allowance through this so "no record" and
 * "no allowance" cannot drift apart.
 */
export function compensationClearanceMm(
  compensation: FitCompensation | undefined,
): number {
  return compensation?.clearanceMm ?? 0;
}
