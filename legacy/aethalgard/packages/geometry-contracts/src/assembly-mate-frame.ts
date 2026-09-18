import { z } from "zod";

import { assemblyEndpointGeometrySchema } from "./assembly-endpoint.js";
import { resolvedEntitySchema } from "./kernel-protocol.js";
import { selectorQuerySchema } from "./selector-ast.js";
import { topologySelectionEvidenceSchema } from "./topology.js";

/** Canonical exact geometry classes emitted by the OCCT endpoint extractor. */
export const mateFrameGeometrySchema = z.enum([
  "point",
  "axis",
  "plane",
  "cylinder",
  "cone",
  "sphere",
]);
export type MateFrameGeometry = z.infer<typeof mateFrameGeometrySchema>;

/**
 * Orientation semantics are part of mate compatibility, not display metadata.
 * They therefore use a closed vocabulary shared with the native extractor.
 */
export const mateFrameOrientationClassSchema = z.enum([
  "directed",
  "undirected-axis",
  "isotropic",
]);
export type MateFrameOrientationClass = z.infer<
  typeof mateFrameOrientationClassSchema
>;

const radiusCompatibleMateGeometry: ReadonlySet<MateFrameGeometry> = new Set([
  "cylinder",
  "cone",
  "axis",
  "sphere",
]);

function validateMateFrame(
  frame: {
    readonly primary: readonly [number, number, number];
    readonly secondary: readonly [number, number, number];
    readonly geometry: MateFrameGeometry;
    readonly radius?: number | undefined;
    readonly halfAngleRad?: number | undefined;
  },
  context: z.RefinementCtx,
): void {
  const primaryMagnitude = Math.hypot(...frame.primary);
  if (Math.abs(primaryMagnitude - 1) > 1e-6) {
    context.addIssue({
      code: "custom",
      message: "MateFrame primary must be a unit vector",
      path: ["primary"],
    });
  }
  const secondaryMagnitude = Math.hypot(...frame.secondary);
  if (Math.abs(secondaryMagnitude - 1) > 1e-6) {
    context.addIssue({
      code: "custom",
      message: "MateFrame secondary must be a unit vector",
      path: ["secondary"],
    });
  }
  const dot =
    frame.primary[0] * frame.secondary[0] +
    frame.primary[1] * frame.secondary[1] +
    frame.primary[2] * frame.secondary[2];
  if (Math.abs(dot) >= 1e-6) {
    context.addIssue({
      code: "custom",
      message: "MateFrame primary and secondary must be mutually perpendicular",
      path: ["secondary"],
    });
  }
  if (
    frame.radius !== undefined &&
    !radiusCompatibleMateGeometry.has(frame.geometry)
  ) {
    context.addIssue({
      code: "custom",
      message: `MateFrame geometry ${frame.geometry} cannot carry radius evidence`,
      path: ["radius"],
    });
  }
  if (frame.halfAngleRad !== undefined && frame.geometry !== "cone") {
    context.addIssue({
      code: "custom",
      message: "MateFrame halfAngleRad is only legal for cone geometry",
      path: ["halfAngleRad"],
    });
  }
}

export const mateFrameSchema = z
  .object({
    origin: z.tuple([
      z.number().finite(),
      z.number().finite(),
      z.number().finite(),
    ]),
    primary: z.tuple([
      z.number().finite(),
      z.number().finite(),
      z.number().finite(),
    ]),
    secondary: z.tuple([
      z.number().finite(),
      z.number().finite(),
      z.number().finite(),
    ]),
    geometry: mateFrameGeometrySchema,
    radius: z.number().finite().nonnegative().optional(),
    halfAngleRad: z.number().finite().nonnegative().optional(),
    orientationClass: mateFrameOrientationClassSchema,
    sourceEvidence: topologySelectionEvidenceSchema,
  })
  .strict()
  .superRefine(validateMateFrame);
export type MateFrame = z.infer<typeof mateFrameSchema>;

export const mateFrameEndpointRequestSchema = z
  .object({
    requestId: z.string().min(1).max(128),
    ast: selectorQuerySchema,
    expectedGeometry: assemblyEndpointGeometrySchema,
  })
  .strict();
export type MateFrameEndpointRequest = z.infer<
  typeof mateFrameEndpointRequestSchema
>;

/**
 * Geometry-only batch payload used by native unit seams. The live process
 * method is the definition-scoped contract in kernel-assembly-protocol.ts.
 */
export const resolveMateFramesRequestSchema = z
  .object({
    operations: z.array(z.unknown()).max(100_000),
    endpoints: z.array(mateFrameEndpointRequestSchema).min(1).max(4096),
  })
  .strict();
export type ResolveMateFramesRequest = z.infer<
  typeof resolveMateFramesRequestSchema
>;

export const endpointResolutionStatusSchema = z.enum([
  "resolved",
  "missing",
  "ambiguous",
  "invalidated",
]);
export type EndpointResolutionStatus = z.infer<
  typeof endpointResolutionStatusSchema
>;

export const endpointResolutionOutcomeSchema = z.discriminatedUnion("status", [
  z
    .object({
      requestId: z.string().min(1).max(128),
      status: z.literal("resolved"),
      frame: mateFrameSchema,
    })
    .strict(),
  z
    .object({
      requestId: z.string().min(1).max(128),
      status: z.literal("missing"),
      message: z.string().min(1),
    })
    .strict(),
  z
    .object({
      requestId: z.string().min(1).max(128),
      status: z.literal("ambiguous"),
      candidates: z.array(resolvedEntitySchema).max(5),
      message: z.string().min(1),
    })
    .strict(),
  z
    .object({
      requestId: z.string().min(1).max(128),
      status: z.literal("invalidated"),
      message: z.string().min(1),
    })
    .strict(),
]);
export type EndpointResolutionOutcome = z.infer<
  typeof endpointResolutionOutcomeSchema
>;

export const resolveMateFramesResultSchema = z
  .object({
    outcomes: z.array(endpointResolutionOutcomeSchema).max(4096),
  })
  .strict();
export type ResolveMateFramesResult = z.infer<
  typeof resolveMateFramesResultSchema
>;
