import { z } from "zod";

import {
  kernelExportOperationTimeoutMs,
  kernelOperationTimeoutMs as coreKernelOperationTimeoutMs,
  kernelProtocolVersion,
  kernelRequestSchema as coreKernelRequestSchema,
  kernelResponseSchema as coreKernelResponseSchema,
  kernelResultSchema as coreKernelResultSchema,
  kernelTimeoutEscalationMarginMs,
  resolvedEntitySchema as coreResolvedEntitySchema,
  selDiagnosticSchema,
} from "./kernel-protocol-core.js";
import { wireOperationSchema } from "./operations.js";

export * from "./kernel-protocol-core.js";

const finiteNumber = z.number().finite();
const vector3Schema = z.tuple([finiteNumber, finiteNumber, finiteNumber]);
const rotationMatrixSchema = z.tuple([
  finiteNumber,
  finiteNumber,
  finiteNumber,
  finiteNumber,
  finiteNumber,
  finiteNumber,
  finiteNumber,
  finiteNumber,
  finiteNumber,
]);

const collisionWorldPoseSchema = z
  .object({
    position: vector3Schema,
    rotation: rotationMatrixSchema,
  })
  .strict();

const collisionInstanceSchema = z
  .object({
    instanceId: z.string().uuid(),
    definitionId: z.string().uuid(),
    revisionHash: z.string().min(1).max(128),
    definitionBodyId: z.string().uuid(),
    worldPose: collisionWorldPoseSchema,
  })
  .strict();

const collisionPairSchema = z.tuple([
  z.number().int().nonnegative(),
  z.number().int().nonnegative(),
]);

const collisionPairSelectionSchema = z.discriminatedUnion("mode", [
  z.object({ mode: z.literal("all") }).strict(),
  z
    .object({
      mode: z.literal("selected"),
      pairs: z.array(collisionPairSchema).min(1).max(1_000_000),
    })
    .strict(),
]);

const collisionRequestSchema = z
  .object({
    protocolVersion: z.literal(kernelProtocolVersion),
    requestId: z.string().uuid(),
    method: z.enum(["check_interference", "check_clearance"]),
    instances: z.array(collisionInstanceSchema).min(2).max(1_000_000),
    pairs: collisionPairSelectionSchema,
    exclusions: z.array(collisionPairSchema).max(1_000_000).optional(),
    budget: z
      .object({
        timeoutMs: z
          .number()
          .int()
          .positive()
          .max(kernelExportOperationTimeoutMs),
      })
      .strict()
      .optional(),
  })
  .strict()
  .superRefine((request, context) => {
    if (request.pairs.mode === "selected" && request.exclusions !== undefined) {
      context.addIssue({
        code: "custom",
        message: "exclusions are only valid when pairs.mode is all",
        path: ["exclusions"],
      });
    }

    const validatePairs = (
      pairs: readonly (readonly [number, number])[],
      path: "pairs" | "exclusions",
    ): void => {
      for (let index = 0; index < pairs.length; index += 1) {
        const pair = pairs[index];
        if (!pair) continue;
        const [a, b] = pair;
        if (a === b) {
          context.addIssue({
            code: "custom",
            message: "collision pairs must name two distinct instances",
            path:
              path === "pairs"
                ? ["pairs", "pairs", index]
                : ["exclusions", index],
          });
        }
        if (a >= request.instances.length || b >= request.instances.length) {
          context.addIssue({
            code: "custom",
            message: "collision pair index is outside the instances array",
            path:
              path === "pairs"
                ? ["pairs", "pairs", index]
                : ["exclusions", index],
          });
        }
      }
    };

    if (request.pairs.mode === "selected") {
      validatePairs(request.pairs.pairs, "pairs");
    }
    if (request.exclusions !== undefined) {
      validatePairs(request.exclusions, "exclusions");
    }
  });

export const exactInterferenceEndpointSchema = z
  .object({
    bodyId: z.string().uuid(),
    occurrencePath: z.array(z.string().uuid()).min(1).max(256),
    definitionId: z.string().uuid(),
    definitionRevisionHash: z.string().min(1).max(128),
  })
  .strict();

export const exactInterferencePairSchema = z
  .object({
    a: exactInterferenceEndpointSchema,
    b: exactInterferenceEndpointSchema,
  })
  .strict()
  .superRefine((pair, context) => {
    const endpointKey = (
      endpoint: z.infer<typeof exactInterferenceEndpointSchema>,
    ): string =>
      [
        endpoint.bodyId,
        endpoint.occurrencePath.join("/"),
        endpoint.definitionId,
        endpoint.definitionRevisionHash,
      ].join("\u0000");
    const aKey = endpointKey(pair.a);
    const bKey = endpointKey(pair.b);
    if (aKey === bKey) {
      context.addIssue({
        code: "custom",
        message:
          "exact interference pairs cannot compare an endpoint with itself",
        path: ["b"],
      });
    } else if (aKey > bKey) {
      context.addIssue({
        code: "custom",
        message: "exact interference pair endpoints must be in canonical order",
        path: ["b"],
      });
    }
  });

export const exactInterferenceRequestSchema = z
  .object({
    protocolVersion: z.literal(kernelProtocolVersion),
    requestId: z.string().uuid(),
    method: z.literal("interference_exact"),
    operations: z.array(wireOperationSchema).min(1),
    pairs: z.array(exactInterferencePairSchema).min(1).max(1_000_000),
    toleranceMm: z.number().finite().nonnegative().optional(),
    inputRevisionDigest: z.string().min(1).max(128).optional(),
  })
  .strict();

export type ExactInterferenceEndpoint = z.infer<
  typeof exactInterferenceEndpointSchema
>;
export type ExactInterferencePair = z.infer<typeof exactInterferencePairSchema>;
export type ExactInterferenceRequest = z.infer<
  typeof exactInterferenceRequestSchema
>;

export type KernelRequest =
  | z.infer<typeof collisionRequestSchema>
  | z.infer<typeof exactInterferenceRequestSchema>
  | z.infer<typeof coreKernelRequestSchema>;

/**
 * Existing kernel requests plus collision and exact-interference queries.
 *
 * The annotation is required, not stylistic: the operation union underneath
 * (every operation schema, including extrude v2's modes) makes the inferred
 * ZodUnion type too long for TypeScript to serialize into the declaration
 * file (TS7056). Naming the output type keeps the emitted `.d.ts` bounded.
 * It narrows only the compile-time surface — `parse`/`safeParse` still take
 * `unknown` and every runtime check is unchanged.
 */
export const kernelRequestSchema: z.ZodType<KernelRequest> = z.union([
  collisionRequestSchema,
  exactInterferenceRequestSchema,
  coreKernelRequestSchema,
]);

/** Collision queries share the export-tier native wall-clock budget. */
export function kernelOperationTimeoutMs(method: string): number {
  return method === "check_interference" ||
    method === "check_clearance" ||
    method === "interference_exact"
    ? kernelExportOperationTimeoutMs
    : coreKernelOperationTimeoutMs(method);
}

/** Queue deadline reconciled against the enhanced per-operation timeout map. */
export function kernelRequestDeadlineMs(method: string): number {
  return (
    kernelOperationTimeoutMs(method) +
    kernelTimeoutEscalationMarginMs +
    kernelTimeoutEscalationMarginMs
  );
}

/**
 * Deterministic FNV-1a signature of the entity's sorted immediate incidence
 * neighborhood. Additive and optional: old hosts/responses remain valid, while
 * new topology recordings can retain the structural channel already declared
 * by referenceAnchorSchema.
 */
export const resolvedEntitySchema = coreResolvedEntitySchema
  .extend({
    adjHash: z
      .string()
      .max(64)
      .regex(/^[0-9a-f]+$/)
      .optional(),
  })
  .strict();

export type ResolvedEntity = z.infer<typeof resolvedEntitySchema>;

const adjacencyQueryResultSchema = z
  .object({
    type: z.literal("query"),
    entities: z.array(resolvedEntitySchema).max(1_000_000),
    diagnostics: z.array(selDiagnosticSchema).max(1_000),
    stageCardinalities: z.array(z.number().int().nonnegative()).max(17),
  })
  .strict();

const interferenceSeparatedSchema = z
  .object({
    pair: collisionPairSchema,
    status: z.literal("separated"),
  })
  .strict();

const interferenceIntersectingSchema = z
  .object({
    pair: collisionPairSchema,
    status: z.literal("intersecting"),
    overlapVolumeMm3: z.number().finite().nonnegative().optional(),
    contactAreaMm2: z.number().finite().nonnegative().optional(),
    containment: z.enum(["a-contains-b", "b-contains-a"]).optional(),
  })
  .strict()
  .superRefine((result, context) => {
    if (
      result.overlapVolumeMm3 === undefined &&
      result.contactAreaMm2 === undefined
    ) {
      context.addIssue({
        code: "custom",
        message:
          "an intersecting pair must carry overlapVolumeMm3 or contactAreaMm2",
      });
    }
  });

const interferenceFailedSchema = z
  .object({
    pair: collisionPairSchema,
    status: z.literal("failed"),
    message: z.string().min(1),
  })
  .strict();

const interferencePairResultSchema = z.union([
  interferenceSeparatedSchema,
  interferenceIntersectingSchema,
  interferenceFailedSchema,
]);

const clearanceNotSeparatedSchema = z
  .object({
    pair: collisionPairSchema,
    status: z.literal("not-separated"),
  })
  .strict();

const clearanceSeparatedSchema = z
  .object({
    pair: collisionPairSchema,
    status: z.literal("separated"),
    clearanceMm: z.number().finite().nonnegative(),
    witness: z
      .object({
        pointA: vector3Schema,
        pointB: vector3Schema,
      })
      .strict(),
  })
  .strict();

const clearanceFailedSchema = z
  .object({
    pair: collisionPairSchema,
    status: z.literal("failed"),
    message: z.string().min(1),
  })
  .strict();

const clearancePairResultSchema = z.union([
  clearanceNotSeparatedSchema,
  clearanceSeparatedSchema,
  clearanceFailedSchema,
]);

const resultCompletenessSchema = z.enum(["complete", "partial", "timeout"]);

const interferenceResultSchema = z
  .object({
    type: z.literal("interference_result"),
    completeness: resultCompletenessSchema,
    evaluatedPairCount: z.number().int().nonnegative(),
    incompletePairs: z.array(collisionPairSchema).max(1_000_000).optional(),
    results: z.array(interferencePairResultSchema).max(1_000_000),
  })
  .strict()
  .superRefine((result, context) => {
    if (result.evaluatedPairCount !== result.results.length) {
      context.addIssue({
        code: "custom",
        message: "evaluatedPairCount must equal results.length",
        path: ["evaluatedPairCount"],
      });
    }
    if (result.completeness === "complete") {
      if (result.incompletePairs !== undefined) {
        context.addIssue({
          code: "custom",
          message: "a complete result cannot carry incompletePairs",
          path: ["incompletePairs"],
        });
      }
    } else if (!result.incompletePairs || result.incompletePairs.length === 0) {
      context.addIssue({
        code: "custom",
        message: "a partial or timeout result must carry incompletePairs",
        path: ["incompletePairs"],
      });
    }
  });

const clearanceResultSchema = z
  .object({
    type: z.literal("clearance_result"),
    completeness: resultCompletenessSchema,
    evaluatedPairCount: z.number().int().nonnegative(),
    incompletePairs: z.array(collisionPairSchema).max(1_000_000).optional(),
    results: z.array(clearancePairResultSchema).max(1_000_000),
  })
  .strict()
  .superRefine((result, context) => {
    if (result.evaluatedPairCount !== result.results.length) {
      context.addIssue({
        code: "custom",
        message: "evaluatedPairCount must equal results.length",
        path: ["evaluatedPairCount"],
      });
    }
    if (result.completeness === "complete") {
      if (result.incompletePairs !== undefined) {
        context.addIssue({
          code: "custom",
          message: "a complete result cannot carry incompletePairs",
          path: ["incompletePairs"],
        });
      }
    } else if (!result.incompletePairs || result.incompletePairs.length === 0) {
      context.addIssue({
        code: "custom",
        message: "a partial or timeout result must carry incompletePairs",
        path: ["incompletePairs"],
      });
    }
  });

const collisionResultSchema = z.union([
  interferenceResultSchema,
  clearanceResultSchema,
]);

export const exactInterferenceResultSchema = z
  .object({
    type: z.literal("interference_exact_result"),
    report: z.record(z.string(), z.unknown()),
    evidence: z.record(z.string(), z.unknown()),
  })
  .strict();

export const exactInterferenceSuccessResponseSchema = z
  .object({
    protocolVersion: z.literal(kernelProtocolVersion),
    requestId: z.string().uuid(),
    ok: z.literal(true),
    result: exactInterferenceResultSchema,
  })
  .strict();

export type ExactInterferenceResult = z.infer<
  typeof exactInterferenceResultSchema
>;
export type ExactInterferenceSuccessResponse = z.infer<
  typeof exactInterferenceSuccessResponseSchema
>;

/**
 * The exact established result union plus the stronger query projection and
 * ASM-011 occurrence-level collision results.
 */
export const kernelResultSchema = z.union([
  exactInterferenceResultSchema,
  collisionResultSchema,
  adjacencyQueryResultSchema,
  coreKernelResultSchema,
]);

export type KernelResult = z.infer<typeof kernelResultSchema>;

const adjacencyQuerySuccessSchema = z
  .object({
    protocolVersion: z.literal(kernelProtocolVersion),
    requestId: z.string().uuid(),
    ok: z.literal(true),
    result: adjacencyQueryResultSchema,
  })
  .strict();

const collisionSuccessSchema = z
  .object({
    protocolVersion: z.literal(kernelProtocolVersion),
    requestId: z.string().uuid(),
    ok: z.literal(true),
    result: collisionResultSchema,
  })
  .strict();

export const kernelResponseSchema = z.union([
  exactInterferenceSuccessResponseSchema,
  collisionSuccessSchema,
  adjacencyQuerySuccessSchema,
  coreKernelResponseSchema,
]);

export type KernelResponse = z.infer<typeof kernelResponseSchema>;
