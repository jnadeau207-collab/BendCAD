/**
 * The wire schema crossing the native process boundary between
 * `packages/assembly-client` and `native/assembly-host` (ASM-002, plan 07
 * §6.4/§14.2). Mirrors `kernel-protocol.ts`'s shape exactly: a
 * `protocolVersion` literal + `requestId` UUID request base, a
 * `z.discriminatedUnion("ok", […])` response envelope, and a per-method
 * result union discriminated on `type`. Nothing here is a document schema —
 * persisted assembly tables live in `@aeth/document-model` (ASM-001); this
 * file is transport only, exactly like `kernel-protocol.ts` is transport
 * only for the kernel.
 */
import { z } from "zod";

import { point3Schema } from "./operations.js";

export const assemblyProtocolVersion = 1 as const;

const requestBase = {
  protocolVersion: z.literal(assemblyProtocolVersion),
  requestId: z.string().uuid(),
} as const;

/**
 * Row-major 3x3 rotation matrix, expected orthonormal (not enforced here —
 * the native adapter is the source of truth for whether a returned matrix is
 * valid; enforcing det≈1/orthonormality in zod would be expensive on a hot
 * path and duplicate what OndselSolver's own numerics already guarantee).
 */
export const rotationMatrix3Schema = z.tuple([
  z.number().finite(),
  z.number().finite(),
  z.number().finite(),
  z.number().finite(),
  z.number().finite(),
  z.number().finite(),
  z.number().finite(),
  z.number().finite(),
  z.number().finite(),
]);

/**
 * The canonical cross-boundary rigid placement: a 3-vector position plus a
 * 3x3 rotation matrix, chosen to mirror the real OndselSolver API this
 * adapter marshals to/from (`MbD::ASMTSpatialItem::position3D` /
 * `::rotationMatrix`, read back via `getPosition3D(i)`/`getRotationMatrix(i)`
 * — vendored header `ASMTSpatialItem.h`).
 *
 * NOT YET DEFINED ANYWHERE ELSE IN THE REPO as of this writing. Plan 07 §3/
 * §4.2 uses `RigidPose` in `ComponentOccurrence.initialPose` and
 * `ViewportOccurrence.worldPose` but never defines its shape — this is that
 * definition, provisional but load-bearing.
 *
 * IMPORTANT — cross-package ownership note: `ComponentOccurrence.initialPose`
 * (ASM-001, `packages/document-model/src/assembly-*.ts`) needs this SAME
 * type. `@aeth/geometry-contracts` sits below `@aeth/document-model` in the
 * dependency graph (document-model already imports selector/topology/
 * operations types FROM geometry-contracts, never the reverse), so ASM-001
 * is expected to import `RigidPose` FROM HERE rather than define its own. If
 * ASM-001 lands first per the DAG and needs `RigidPose` before this file
 * exists, that is a re-grounding item for ASM-001's own admission — it must
 * not fork a second pose type. If, by the time ASM-002 is actually
 * implemented, ASM-001 already shipped a `RigidPose` elsewhere, DELETE this
 * local definition and import that one instead; never carry two.
 */
export const rigidPoseSchema = z
  .object({
    position: point3Schema,
    rotation: rotationMatrix3Schema,
  })
  .strict();
export type RigidPose = z.infer<typeof rigidPoseSchema>;

/** Placeholder until ASM-001 lands its own document-model identity brands. */
export const assemblyOccurrenceIdSchema = z.string().uuid();
/** Placeholder until ASM-001 lands its own document-model identity brands. */
export const assemblyRelationshipIdSchema = z.string().uuid();

/**
 * Plan 07 §6.2, quoted verbatim: "A joint is a semantic motion primitive
 * compiled into solver constraints: fixed: 0 DOF; revolute: 1 rotational
 * DOF; prismatic: 1 translational DOF; cylindrical: 1 translation + 1
 * rotation on a shared axis; planar: 2 in-plane translations + 1
 * normal-axis rotation; ball: 3 rotational DOF; pin-slot: translation along
 * slot + optional pin rotation; screw: coupled rotation/translation by
 * pitch; rigid group: several occurrences solved as one rigid island."
 *
 * ASM-002's exit criterion is scoped to exactly three of these — fixed,
 * revolute, prismatic. Adding cylindrical/planar/ball/pin-slot/screw/
 * rigid-group is ASM-008's schema change, never invented ahead of it here
 * (the standing law "the verb invents no analytic ceiling" — this enum is
 * not pre-widened for a joint kind no solver adapter yet compiles).
 */
export const assemblyJointKindSchema = z.enum([
  "fixed",
  "revolute",
  "prismatic",
]);
export type AssemblyJointKind = z.infer<typeof assemblyJointKindSchema>;

export const assemblySolveOccurrenceSchema = z
  .object({
    occurrenceId: assemblyOccurrenceIdSchema,
    initialPose: rigidPoseSchema,
    /** true => the native adapter sets `ASMTPart::isFixed = true`. */
    grounded: z.boolean(),
  })
  .strict();
export type AssemblySolveOccurrence = z.infer<
  typeof assemblySolveOccurrenceSchema
>;

/**
 * A named reference frame on ONE occurrence, in that occurrence's own local
 * frame — mirrors `MbD::ASMTMarker` (a local position3D+rotationMatrix owned
 * by an `ASMTPart`). ASM-002 places markers directly by fixture authors
 * (there is no face/edge resolution yet — that is ASM-005's
 * `resolve_mate_frames`); once ASM-005 lands, its resolved `MateFrame` data
 * populates these instead.
 */
export const assemblySolveMarkerSchema = z
  .object({
    markerId: z.string().min(1).max(200),
    occurrenceId: assemblyOccurrenceIdSchema,
    localPose: rigidPoseSchema,
  })
  .strict();
export type AssemblySolveMarker = z.infer<typeof assemblySolveMarkerSchema>;

/** `markerI`/`markerJ` each name an `assemblySolveMarkerSchema.markerId`. */
export const assemblySolveJointSchema = z
  .object({
    jointId: assemblyRelationshipIdSchema,
    kind: assemblyJointKindSchema,
    markerI: z.string().min(1).max(200),
    markerJ: z.string().min(1).max(200),
  })
  .strict();
export type AssemblySolveJoint = z.infer<typeof assemblySolveJointSchema>;

export const assemblySolveFixtureSchema = z
  .object({
    occurrences: z.array(assemblySolveOccurrenceSchema).min(1).max(10_000),
    markers: z.array(assemblySolveMarkerSchema).max(20_000),
    joints: z.array(assemblySolveJointSchema).max(10_000),
  })
  .strict();
export type AssemblySolveFixture = z.infer<typeof assemblySolveFixtureSchema>;

/**
 * Outcome vocabulary. Mirrors the EXACT discipline of `native/kernel-host`'s
 * ADR-016 sketch-solver seam (`sketch_solver.hpp`'s `SketchSolverStatus`/
 * `SketchSolverResult`), whose own doc comment states: "The diagnosis
 * vocabulary below is OURS. PlaneGCS reports integers and tag sets; every
 * word a person could read is authored on this side." Apply the identical
 * discipline to OndselSolver's diagnostics — never surface a raw
 * OndselSolver/MbD tag, constraint index, or C++ type name.
 */
export const assemblySolveStatusSchema = z.enum([
  /** Fully constrained, zero residual, zero free DOF. */
  "solved",
  /** Consistent but free DOF remain — NOT a failure. */
  "under_constrained",
  /** Consistent, over-specified; redundant joints named — NOT a failure. */
  "redundant",
  /** The named joints cannot all be satisfied at once. */
  "conflicting",
  /** Numerics exhausted the iteration budget. */
  "did_not_converge",
  /** Malformed input (dangling marker/joint ref) — reported before any numeric work. */
  "invalid",
]);
export type AssemblySolveStatus = z.infer<typeof assemblySolveStatusSchema>;

export const assemblyOccurrencePoseResultSchema = z
  .object({
    occurrenceId: assemblyOccurrenceIdSchema,
    pose: rigidPoseSchema,
    freeTranslationalDof: z.number().int().min(0).max(3),
    freeRotationalDof: z.number().int().min(0).max(3),
  })
  .strict();
export type AssemblyOccurrencePoseResult = z.infer<
  typeof assemblyOccurrencePoseResultSchema
>;

export const assemblySolveResultSchema = z
  .object({
    status: assemblySolveStatusSchema,
    poses: z.array(assemblyOccurrencePoseResultSchema),
    totalFreeDof: z.number().int().min(0),
    /**
     * Plan 07 §6.4: "minimal or bounded conflicting relationship set" — OUR
     * joint ids, never solver constraint indices.
     */
    conflictingJointIds: z.array(assemblyRelationshipIdSchema),
    redundantJointIds: z.array(assemblyRelationshipIdSchema),
    /** A sentence in OUR words, safe to show a person. */
    message: z.string().max(2000),
    iterationCount: z.number().int().min(0),
    elapsedMs: z.number().min(0),
  })
  .strict();
export type AssemblySolveResult = z.infer<typeof assemblySolveResultSchema>;

export const assemblyRequestSchema = z.discriminatedUnion("method", [
  z.object({ ...requestBase, method: z.literal("health") }).strict(),
  z
    .object({
      ...requestBase,
      method: z.literal("solve"),
      fixture: assemblySolveFixtureSchema,
    })
    .strict(),
  z
    .object({
      ...requestBase,
      method: z.literal("cancel"),
      targetRequestId: z.string().uuid(),
    })
    .strict(),
]);
export type AssemblyRequest = z.infer<typeof assemblyRequestSchema>;

/**
 * Deliberately does NOT include a `CONFLICTING`/`REDUNDANT` code: those are
 * valid SOLVE outcomes reported via `assemblySolveStatusSchema.status`, not
 * protocol errors (mirrors the sketch-solver precedent where `Conflicting`/
 * `Redundant` are result statuses, never thrown errors). `CRASHED` is the
 * host process dying mid-request.
 */
export const assemblyErrorSchema = z
  .object({
    code: z.enum([
      "INVALID_REQUEST",
      "CANCELLED",
      "TIMEOUT",
      "BUSY",
      "IO_ERROR",
      "CRASHED",
    ]),
    message: z.string().min(1),
    details: z.record(z.string(), z.unknown()).optional(),
  })
  .strict();
export type AssemblyError = z.infer<typeof assemblyErrorSchema>;

/** Minimal build-manifest mirror of `kernel-protocol.ts`'s `buildManifestSchema`. */
export const assemblyBuildManifestSchema = z
  .object({
    gitSha: z.string().min(1),
    builtAt: z.string().min(1),
  })
  .strict();
export type AssemblyBuildManifest = z.infer<typeof assemblyBuildManifestSchema>;

export const assemblyResultSchema = z.discriminatedUnion("type", [
  z
    .object({ type: z.literal("health"), build: assemblyBuildManifestSchema })
    .strict(),
  z
    .object({
      type: z.literal("solve"),
      ...assemblySolveResultSchema.shape,
    })
    .strict(),
  /**
   * This exact shape is REQUIRED: `packages/assembly-client`'s request-queue
   * "idleness barrier" (ported from `packages/kernel-client/src/
   * request-queue.ts`'s `#confirmHostIdle`) checks
   * `response.result.type === "cancellation" && response.result.
   * targetRequestId === targetRequestId` to prove the native worker actually
   * stopped before dispatching the next request. Get this field name/shape
   * wrong and cancellation silently stops being safe.
   */
  z
    .object({
      type: z.literal("cancellation"),
      targetRequestId: z.string().uuid(),
    })
    .strict(),
]);
export type AssemblyResult = z.infer<typeof assemblyResultSchema>;

export const assemblyResponseSchema = z.discriminatedUnion("ok", [
  z
    .object({
      protocolVersion: z.literal(assemblyProtocolVersion),
      requestId: z.string().uuid(),
      ok: z.literal(true),
      result: assemblyResultSchema,
    })
    .strict(),
  z
    .object({
      protocolVersion: z.literal(assemblyProtocolVersion),
      requestId: z.string().uuid(),
      ok: z.literal(false),
      error: assemblyErrorSchema,
    })
    .strict(),
]);
export type AssemblyResponse = z.infer<typeof assemblyResponseSchema>;

export const assemblySolveRequestDeadlineMs = 30_000 as const;
export const assemblyDefaultRequestDeadlineMs = 5_000 as const;

/**
 * The per-request deadline `packages/assembly-client`'s request queue must
 * allow for `method`. ASM-002's fixture scope (fixed/revolute/prismatic, no
 * islands, no couplings) solves cheaply, so one generous budget per method is
 * enough for now. Later rows — ASM-009's live drag-solve and ASM-013's motion
 * studies — will need a budget that scales with fixture size (occurrence/
 * marker/joint counts) rather than this flat per-method constant; this
 * function is the seam that later gets that parameter, not a promise that
 * the budget stays flat forever.
 */
export function assemblyRequestDeadlineMs(method: string): number {
  return method === "solve"
    ? assemblySolveRequestDeadlineMs
    : assemblyDefaultRequestDeadlineMs;
}
