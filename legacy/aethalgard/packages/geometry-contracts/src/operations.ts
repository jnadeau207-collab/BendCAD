import { z } from "zod";

import { operationRefSchema, operationRefWireSchema } from "./refs.js";
import { sketchEntityIdSchema } from "./sketch.js";
import * as legacy from "./operations-legacy.js";

export * from "./operations-legacy.js";
export const holeOperationV1Schema = legacy.holeOperationSchema;
export const holeMetricNominalSchema = z.enum([
  "M2",
  "M2.5",
  "M3",
  "M4",
  "M5",
  "M6",
  "M8",
  "M10",
]);
export const holeClearanceFitSchema = z.enum(["close", "medium", "free"]);
const signedHoleOffsetSchema = z
  .number()
  .finite()
  .min(-1_000_000)
  .max(1_000_000);
const holeFacePointSchema = z
  .object({ uMm: signedHoleOffsetSchema, vMm: signedHoleOffsetSchema })
  .strict();

export const holeFormV2Schema = z.union([
  z
    .object({ kind: z.literal("simple"), diameterMm: legacy.millimetersSchema })
    .strict(),
  z
    .object({
      kind: z.literal("counterbore"),
      diameterMm: legacy.millimetersSchema,
      counterboreDiameterMm: legacy.millimetersSchema,
      counterboreDepthMm: legacy.millimetersSchema,
    })
    .strict()
    .superRefine((form, context) => {
      if (form.counterboreDiameterMm <= form.diameterMm)
        context.addIssue({
          code: "custom",
          message: "counterboreDiameterMm must exceed the main hole diameter",
          path: ["counterboreDiameterMm"],
        });
    }),
  z
    .object({
      kind: z.literal("countersink"),
      diameterMm: legacy.millimetersSchema,
      countersinkDiameterMm: legacy.millimetersSchema,
      includedAngleDegrees: z.number().finite().gt(0).lt(180).default(90),
    })
    .strict()
    .superRefine((form, context) => {
      if (form.countersinkDiameterMm <= form.diameterMm)
        context.addIssue({
          code: "custom",
          message: "countersinkDiameterMm must exceed the main hole diameter",
          path: ["countersinkDiameterMm"],
        });
    }),
  z
    .object({
      kind: z.literal("clearance"),
      nominal: holeMetricNominalSchema,
      fit: holeClearanceFitSchema.default("medium"),
    })
    .strict(),
  z
    .object({
      kind: z.literal("tapped"),
      designation: z.string().trim().min(3).max(64),
      threadClass: z.string().trim().min(1).max(32).default("6H"),
      handedness: z.enum(["right", "left"]).default("right"),
      threadMode: z.literal("cosmetic").default("cosmetic"),
    })
    .strict(),
]);
export const holeDrillPointV2Schema = z.union([
  z.object({ kind: z.literal("flat") }).strict(),
  z
    .object({
      kind: z.literal("angled"),
      includedAngleDegrees: z.number().finite().gt(0).lt(180).default(118),
    })
    .strict(),
]);

function holeOperationV2SchemaWith(ref: typeof operationRefSchema) {
  return z
    .object({
      id: legacy.operationIdSchema,
      type: z.literal("hole"),
      schemaVersion: z.literal(2),
      name: z.string().trim().min(1).max(120),
      outputBodyId: legacy.bodyIdSchema,
      parameters: z
        .object({
          targetOperationId: legacy.operationIdSchema,
          entryFace: ref,
          placementMode: z.enum([
            "face-points",
            "face-offsets",
            "sketch-points",
            "reference-points",
            "concentric-face",
            "concentric-axis",
          ]),
          facePoints: z.array(holeFacePointSchema).min(1).max(512).optional(),
          offsetAxis: ref.optional(),
          offsetAlongMm: signedHoleOffsetSchema.optional(),
          offsetPerpendicularMm: signedHoleOffsetSchema.optional(),
          sketchOperationId: legacy.operationIdSchema.optional(),
          sketchPointEntityIds: z
            .array(sketchEntityIdSchema)
            .min(1)
            .max(512)
            .optional(),
          pointRefs: ref.optional(),
          axisFace: ref.optional(),
          axisEdge: ref.optional(),
          direction: z.enum(["into", "reverse"]).default("into"),
          startOffsetMm: signedHoleOffsetSchema.default(0),
          form: holeFormV2Schema,
          extentMode: z.enum(["through-all", "blind", "to-face"]),
          depthMm: legacy.millimetersSchema.optional(),
          extentFace: ref.optional(),
          extentOffsetMm: signedHoleOffsetSchema.default(0),
          drillPoint: holeDrillPointV2Schema.default({ kind: "flat" }),
        })
        .strict()
        .superRefine((parameters, context) => {
          const require = (
            present: boolean,
            name: string,
            required: boolean,
          ): void => {
            if (present === required) return;
            context.addIssue({
              code: "custom",
              message: required
                ? `${name} is required for ${parameters.placementMode}`
                : `${name} is not valid for ${parameters.placementMode}`,
              path: [name],
            });
          };
          require(parameters.facePoints !==
            undefined, "facePoints", parameters.placementMode ===
            "face-points");
          require(parameters.offsetAxis !==
            undefined, "offsetAxis", parameters.placementMode ===
            "face-offsets");
          require(parameters.offsetAlongMm !==
            undefined, "offsetAlongMm", parameters.placementMode ===
            "face-offsets");
          require(parameters.offsetPerpendicularMm !==
            undefined, "offsetPerpendicularMm", parameters.placementMode ===
            "face-offsets");
          require(parameters.sketchOperationId !==
            undefined, "sketchOperationId", parameters.placementMode ===
            "sketch-points");
          require(parameters.sketchPointEntityIds !==
            undefined, "sketchPointEntityIds", parameters.placementMode ===
            "sketch-points");
          require(parameters.pointRefs !==
            undefined, "pointRefs", parameters.placementMode ===
            "reference-points");
          require(parameters.axisFace !==
            undefined, "axisFace", parameters.placementMode ===
            "concentric-face");
          require(parameters.axisEdge !==
            undefined, "axisEdge", parameters.placementMode ===
            "concentric-axis");
          if (parameters.extentMode === "blind") {
            if (parameters.depthMm === undefined)
              context.addIssue({
                code: "custom",
                message: "depthMm is required for a blind hole",
                path: ["depthMm"],
              });
            if (parameters.extentFace !== undefined)
              context.addIssue({
                code: "custom",
                message: "extentFace is only valid for a to-face hole",
                path: ["extentFace"],
              });
          } else if (parameters.extentMode === "to-face") {
            if (parameters.extentFace === undefined)
              context.addIssue({
                code: "custom",
                message: "extentFace is required for a to-face hole",
                path: ["extentFace"],
              });
            if (parameters.depthMm !== undefined)
              context.addIssue({
                code: "custom",
                message: "depthMm is not valid for a to-face hole",
                path: ["depthMm"],
              });
          } else {
            if (parameters.depthMm !== undefined)
              context.addIssue({
                code: "custom",
                message: "depthMm is not valid for a through-all hole",
                path: ["depthMm"],
              });
            if (parameters.extentFace !== undefined)
              context.addIssue({
                code: "custom",
                message: "extentFace is only valid for a to-face hole",
                path: ["extentFace"],
              });
            if (parameters.drillPoint.kind !== "flat")
              context.addIssue({
                code: "custom",
                message:
                  "drill-point geometry is only meaningful on a terminating hole",
                path: ["drillPoint"],
              });
            if (Math.abs(parameters.startOffsetMm) > 1e-12)
              context.addIssue({
                code: "custom",
                message:
                  "through-all holes start at the entry surface; use Blind or To Face for an offset start",
                path: ["startOffsetMm"],
              });
          }
        }),
      metadata: legacy.operationMetadataSchema,
    })
    .strict();
}
export const holeOperationV2Schema =
  holeOperationV2SchemaWith(operationRefSchema);
export const holeOperationSchema = z.union([
  holeOperationV1Schema,
  holeOperationV2Schema,
]);

// ── Extrude parity — professional v2 (issue #138) ────────────────────────────
const signedMillimetersSchema = z
  .number()
  .finite()
  .min(-1_000_000)
  .max(1_000_000)
  .refine((v) => Math.abs(v) > 1e-9, { message: "Offset must be non-zero" });
const taperAngleSchema = z.number().finite().min(-89).max(89);

export const extrudeStartSchema = z.discriminatedUnion("mode", [
  z.object({ mode: z.literal("profilePlane") }).strict(),
  z
    .object({ mode: z.literal("offset"), offsetMm: signedMillimetersSchema })
    .strict(),
  // Start from a durable planar face/plane instead of the profile's own
  // plane. The reference itself lives at `parameters.startObject`, not
  // inside this union — the same shape `toFace` uses for the extent — so it
  // is a top-level ref slot the dependency/repair machinery can see.
  // `offsetMm` is an optional additional offset from the resolved object.
  z
    .object({
      mode: z.literal("object"),
      offsetMm: signedMillimetersSchema.optional(),
    })
    .strict(),
]);
export const extrudeExtentSchema = z.discriminatedUnion("mode", [
  z
    .object({
      mode: z.literal("distance"),
      distanceMm: legacy.millimetersSchema,
    })
    .strict(),
  z
    .object({
      mode: z.literal("symmetric"),
      distanceMm: legacy.millimetersSchema,
    })
    .strict(),
  z
    .object({
      mode: z.literal("twoSided"),
      distanceForwardMm: legacy.millimetersSchema,
      distanceBackwardMm: legacy.millimetersSchema,
    })
    .strict(),
  z.object({ mode: z.literal("throughAll") }).strict(),
  z
    .object({
      mode: z.literal("toFace"),
      offsetMm: signedMillimetersSchema
        .optional()
        .default(0 as unknown as number),
    })
    .strict(),
]);
export const extrudeThinSchema = z
  .object({
    thicknessMm: legacy.millimetersSchema,
    position: z.enum(["oneSide", "midPlane", "twoSide"]).default("midPlane"),
  })
  .strict();
// Fusion additionally documents a "New Component" operation, gated there to
// Hybrid Design. It is absent here for a structural reason, not an oversight:
// `ComponentDefinitionSource` (document-model/src/assembly/model.ts) admits
// exactly three kinds — root, embedded snapshot, and external file — so a
// component definition is always a whole document, never a subset of
// operations authored inline. A modeling operation therefore has nothing to
// mint a definition from. Adding one is assembly-architecture work (multi-
// definition authoring inside a single document), not extrude work, and
// faking it by grouping bodies would produce a "component" that no BOM,
// occurrence, or joint could consume.
export const profileFeatureBooleanSchema = z.discriminatedUnion("mode", [
  z.object({ mode: z.literal("newBody") }).strict(),
  z
    .object({
      mode: z.literal("join"),
      targetOperationId: legacy.operationIdSchema,
    })
    .strict(),
  z
    .object({
      mode: z.literal("cut"),
      targetOperationId: legacy.operationIdSchema,
    })
    .strict(),
  z
    .object({
      mode: z.literal("intersect"),
      targetOperationId: legacy.operationIdSchema,
    })
    .strict(),
]);
export const extrudeBooleanSchema = profileFeatureBooleanSchema;
export const extrudeOperationV1Schema = legacy.extrudeOperationSchema;
function extrudeOperationV2SchemaWith(ref: typeof operationRefSchema) {
  return z
    .object({
      id: legacy.operationIdSchema,
      type: z.literal("extrude"),
      schemaVersion: z.literal(2),
      name: z.string().trim().min(1).max(120),
      outputBodyId: legacy.bodyIdSchema,
      parameters: z
        .object({
          profileOperationId: legacy.operationIdSchema.optional(),
          sketchRegionIds: z
            .array(z.string().min(1).max(256))
            .min(1)
            .max(64)
            .optional(),
          faceProfile: ref.optional(),
          toFace: ref.optional(),
          start: extrudeStartSchema.default({ mode: "profilePlane" }),
          startObject: ref.optional(),
          extent: extrudeExtentSchema,
          direction: z.enum(["normal", "reverse"]).default("normal"),
          taperAngleDeg: taperAngleSchema.default(0),
          thin: extrudeThinSchema.optional(),
          boolean: extrudeBooleanSchema.default({ mode: "newBody" }),
        })
        .strict()
        .superRefine((params, ctx) => {
          const hasProfile = params.profileOperationId !== undefined;
          const hasFace = params.faceProfile !== undefined;
          if (hasProfile === hasFace) {
            ctx.addIssue({
              code: "custom",
              message:
                "Exactly one of profileOperationId or faceProfile must be set",
              path: ["profileOperationId"],
            });
          }
          if (params.sketchRegionIds !== undefined && !hasProfile) {
            ctx.addIssue({
              code: "custom",
              message: "sketchRegionIds requires profileOperationId",
              path: ["sketchRegionIds"],
            });
          }
          if (params.extent.mode === "toFace" && params.toFace === undefined) {
            ctx.addIssue({
              code: "custom",
              message: "toFace is required when extent is toFace",
              path: ["toFace"],
            });
          }
          if (params.extent.mode !== "toFace" && params.toFace !== undefined) {
            ctx.addIssue({
              code: "custom",
              message: "toFace is only valid when extent is toFace",
              path: ["toFace"],
            });
          }
          if (
            params.start.mode === "object" &&
            params.startObject === undefined
          ) {
            ctx.addIssue({
              code: "custom",
              message: "startObject is required when start is object",
              path: ["startObject"],
            });
          }
          if (
            params.start.mode !== "object" &&
            params.startObject !== undefined
          ) {
            ctx.addIssue({
              code: "custom",
              message: "startObject is only valid when start is object",
              path: ["startObject"],
            });
          }
          if (
            params.boolean.mode !== "newBody" &&
            hasProfile &&
            params.boolean.targetOperationId === params.profileOperationId
          ) {
            ctx.addIssue({
              code: "custom",
              message:
                "boolean target must not be the same operation as the profile",
              path: ["boolean", "targetOperationId"],
            });
          }
        }),
      metadata: legacy.operationMetadataSchema,
    })
    .strict();
}
export const extrudeOperationV2Schema =
  extrudeOperationV2SchemaWith(operationRefSchema);
export const extrudeOperationSchema = z.union([
  extrudeOperationV1Schema,
  extrudeOperationV2Schema,
]);

// ── Revolve superiority — durable professional v2 (issue #139) ──────────────
const revolvePartialAngleSchema = z.number().finite().gt(0).lt(360);
const revolveWallSchema = z.number().finite().min(0).max(1_000_000);

export const revolveAxisSourceSchema = z.discriminatedUnion("kind", [
  z.object({ kind: z.literal("edge") }).strict(),
  z.object({ kind: z.literal("rotationalFace") }).strict(),
]);

export const revolveExtentSchema = z.discriminatedUnion("mode", [
  z.object({ mode: z.literal("full") }).strict(),
  z
    .object({
      mode: z.literal("oneSide"),
      angleDegrees: revolvePartialAngleSchema,
    })
    .strict(),
  z
    .object({
      mode: z.literal("symmetric"),
      // Total included angle. The native evaluator applies half to each side.
      angleDegrees: revolvePartialAngleSchema,
    })
    .strict(),
  z
    .object({
      mode: z.literal("twoSided"),
      forwardAngleDegrees: revolvePartialAngleSchema,
      backwardAngleDegrees: revolvePartialAngleSchema,
    })
    .strict()
    .refine(
      (extent) =>
        extent.forwardAngleDegrees + extent.backwardAngleDegrees < 360,
      { message: "Two-sided angles must total less than 360 degrees" },
    ),
]);

export const revolveThinSchema = z
  .object({
    sideOneMm: revolveWallSchema,
    sideTwoMm: revolveWallSchema,
  })
  .strict()
  .refine((thin) => thin.sideOneMm > 0 || thin.sideTwoMm > 0, {
    message: "At least one thin wall side must be positive",
  });

export const revolveOperationV1Schema = legacy.revolveOperationSchema;
function revolveOperationV2SchemaWith(ref: typeof operationRefSchema) {
  return z
    .object({
      id: legacy.operationIdSchema,
      type: z.literal("revolve"),
      schemaVersion: z.literal(2),
      name: z.string().trim().min(1).max(120),
      outputBodyId: legacy.bodyIdSchema,
      parameters: z
        .object({
          profileOperationId: legacy.operationIdSchema.optional(),
          sketchRegionIds: z
            .array(z.string().min(1).max(256))
            .min(1)
            .max(64)
            .optional(),
          faceProfile: ref.optional(),
          axisSource: revolveAxisSourceSchema,
          axisEdge: ref.optional(),
          axisFace: ref.optional(),
          projectAxisToProfilePlane: z.boolean().default(false),
          extent: revolveExtentSchema,
          direction: z.enum(["forward", "reverse"]).default("forward"),
          thin: revolveThinSchema.optional(),
          boolean: profileFeatureBooleanSchema.default({ mode: "newBody" }),
        })
        .strict()
        .superRefine((params, ctx) => {
          const hasProfile = params.profileOperationId !== undefined;
          const hasFaceProfile = params.faceProfile !== undefined;
          if (hasProfile === hasFaceProfile) {
            ctx.addIssue({
              code: "custom",
              message:
                "Exactly one of profileOperationId or faceProfile must be set",
              path: ["profileOperationId"],
            });
          }
          if (params.sketchRegionIds !== undefined && !hasProfile) {
            ctx.addIssue({
              code: "custom",
              message: "sketchRegionIds requires profileOperationId",
              path: ["sketchRegionIds"],
            });
          }
          const wantsEdge = params.axisSource.kind === "edge";
          if (wantsEdge !== (params.axisEdge !== undefined)) {
            ctx.addIssue({
              code: "custom",
              message: wantsEdge
                ? "axisEdge is required for an edge axis"
                : "axisEdge is only valid for an edge axis",
              path: ["axisEdge"],
            });
          }
          const wantsFace = params.axisSource.kind === "rotationalFace";
          if (wantsFace !== (params.axisFace !== undefined)) {
            ctx.addIssue({
              code: "custom",
              message: wantsFace
                ? "axisFace is required for a rotational-face axis"
                : "axisFace is only valid for a rotational-face axis",
              path: ["axisFace"],
            });
          }
          if (
            params.boolean.mode !== "newBody" &&
            hasProfile &&
            params.boolean.targetOperationId === params.profileOperationId
          ) {
            ctx.addIssue({
              code: "custom",
              message:
                "boolean target must not be the same operation as the profile",
              path: ["boolean", "targetOperationId"],
            });
          }
        }),
      metadata: legacy.operationMetadataSchema,
    })
    .strict();
}

export const revolveOperationV2Schema =
  revolveOperationV2SchemaWith(operationRefSchema);
export const revolveOperationSchema = z.union([
  revolveOperationV1Schema,
  revolveOperationV2Schema,
]);

// ── Associative Sweep — durable professional v2 (issue #140) ───────────────
// A Sweep v2 path is an ordered list of durable selector refs. The old v1
// literal polyline remains readable, but new authored operations must carry
// geometry references so upstream edits can rebuild the feature instead of
// freezing renderer coordinates into the document.
function sweepExtentSchemaWith(ref: typeof operationRefSchema) {
  return z.discriminatedUnion("mode", [
    z.object({ mode: z.literal("full") }).strict(),
    z
      .object({
        mode: z.literal("distance"),
        distanceMm: legacy.millimetersSchema,
      })
      .strict(),
    z
      .object({
        mode: z.literal("toReference"),
        end: ref,
      })
      .strict(),
  ]);
}

const sweepProfileBooleanSchema = profileFeatureBooleanSchema;
const sweepTaperAngleSchema = z.number().finite().min(-89).max(89);
const sweepTwistAngleSchema = z
  .number()
  .finite()
  .min(-1_000_000)
  .max(1_000_000);
const sweepStartRotationSchema = z.number().finite().min(-360).max(360);

export const sweepOperationV1Schema = legacy.sweepOperationSchema;
function sweepOperationV2SchemaWith(ref: typeof operationRefSchema) {
  const pathRef = ref.extend({
    arity: z.literal("one").default("one"),
  });
  return z
    .object({
      id: legacy.operationIdSchema,
      type: z.literal("sweep"),
      schemaVersion: z.literal(2),
      name: z.string().trim().min(1).max(120),
      outputBodyId: legacy.bodyIdSchema,
      parameters: z
        .object({
          profileOperationId: legacy.operationIdSchema.optional(),
          sketchRegionIds: z
            .array(z.string().trim().min(1).max(256))
            .min(1)
            .max(64)
            .optional(),
          faceProfile: ref.optional(),
          path: z.array(pathRef).min(1).max(256),
          guideRail: ref.optional(),
          guideSurface: ref.optional(),
          orientation: z.enum(["natural", "fixed"]).default("natural"),
          extent: sweepExtentSchemaWith(ref).default({ mode: "full" }),
          pathDirection: z.enum(["forward", "reverse"]).default("forward"),
          startRotationDegrees: sweepStartRotationSchema.default(0),
          taperAngleDeg: sweepTaperAngleSchema.default(0),
          twistAngleDegrees: sweepTwistAngleSchema.default(0),
          boolean: sweepProfileBooleanSchema.default({ mode: "newBody" }),
        })
        .strict()
        .superRefine((params, context) => {
          const hasProfileOperation = params.profileOperationId !== undefined;
          const hasFaceProfile = params.faceProfile !== undefined;
          if (hasProfileOperation === hasFaceProfile) {
            context.addIssue({
              code: "custom",
              message:
                "Exactly one of profileOperationId or faceProfile must be set",
              path: ["profileOperationId"],
            });
          }
          if (params.sketchRegionIds !== undefined && !hasProfileOperation) {
            context.addIssue({
              code: "custom",
              message: "sketchRegionIds requires profileOperationId",
              path: ["sketchRegionIds"],
            });
          }
          if (
            params.boolean.mode !== "newBody" &&
            hasProfileOperation &&
            params.boolean.targetOperationId === params.profileOperationId
          ) {
            context.addIssue({
              code: "custom",
              message:
                "boolean target must not be the same operation as the profile",
              path: ["boolean", "targetOperationId"],
            });
          }
        }),
      metadata: legacy.operationMetadataSchema,
    })
    .strict();
}

export const sweepOperationV2Schema =
  sweepOperationV2SchemaWith(operationRefSchema);
export const sweepOperationSchema = z.union([
  sweepOperationV1Schema,
  sweepOperationV2Schema,
]);
export const operationSchema = z.union([
  legacy.operationSchema,
  holeOperationV2Schema,
  extrudeOperationV2Schema,
  revolveOperationV2Schema,
  sweepOperationV2Schema,
]);
/**
 * Persisted operations must be built from the extended current-operation
 * union, not the legacy module's closed union.  Keeping this definition beside
 * `operationSchema` prevents a new schema version from being accepted by the
 * kernel wire contract while being silently rejected on document save.
 */
export const persistedOperationSchema = z.union([
  operationSchema,
  legacy.unknownOperationSchema,
]);
const holeOperationV2WireSchema = holeOperationV2SchemaWith(
  operationRefWireSchema as unknown as typeof operationRefSchema,
);
const extrudeOperationV2WireSchema = extrudeOperationV2SchemaWith(
  operationRefWireSchema as unknown as typeof operationRefSchema,
);
const revolveOperationV2WireSchema = revolveOperationV2SchemaWith(
  operationRefWireSchema as unknown as typeof operationRefSchema,
);
const sweepOperationV2WireSchema = sweepOperationV2SchemaWith(
  operationRefWireSchema as unknown as typeof operationRefSchema,
);
/**
 * A named alias for the wire union's output, so every embedding site (the
 * kernel request protocol spreads `operations: z.array(wireOperationSchema)`
 * into several discriminated-union variants) references this type instead of
 * re-inlining the full five-branch structural union. Without it, TS's
 * declaration-emit printer for `kernelRequestSchema` exceeds its
 * serialization limit (TS7056) once a fifth wire variant (Sweep v2) is added.
 */
type WireOperation =
  | z.infer<typeof legacy.wireOperationSchema>
  | z.infer<typeof holeOperationV2WireSchema>
  | z.infer<typeof extrudeOperationV2WireSchema>
  | z.infer<typeof revolveOperationV2WireSchema>
  | z.infer<typeof sweepOperationV2WireSchema>;
export const wireOperationSchema: z.ZodType<WireOperation> = z.union([
  legacy.wireOperationSchema,
  holeOperationV2WireSchema,
  extrudeOperationV2WireSchema,
  revolveOperationV2WireSchema,
  sweepOperationV2WireSchema,
]);
export type HoleOperationV1 = z.infer<typeof holeOperationV1Schema>;
export type HoleOperationV2 = z.infer<typeof holeOperationV2Schema>;
export type HoleOperation = z.infer<typeof holeOperationSchema>;
export type HoleFormV2 = z.infer<typeof holeFormV2Schema>;
export type HoleDrillPointV2 = z.infer<typeof holeDrillPointV2Schema>;
export type HoleMetricNominal = z.infer<typeof holeMetricNominalSchema>;
export type HoleClearanceFit = z.infer<typeof holeClearanceFitSchema>;
export type ExtrudeOperationV1 = z.infer<typeof extrudeOperationV1Schema>;
export type ExtrudeOperationV2 = z.infer<typeof extrudeOperationV2Schema>;
export type ExtrudeOperation = z.infer<typeof extrudeOperationSchema>;
export type RevolveOperationV1 = z.infer<typeof revolveOperationV1Schema>;
export type RevolveOperationV2 = z.infer<typeof revolveOperationV2Schema>;
export type RevolveOperation = z.infer<typeof revolveOperationSchema>;
export type SweepOperationV1 = z.infer<typeof sweepOperationV1Schema>;
export type SweepOperationV2 = z.infer<typeof sweepOperationV2Schema>;
export type SweepOperation = z.infer<typeof sweepOperationSchema>;
export type Operation = z.infer<typeof operationSchema>;
export type PersistedOperation = z.infer<typeof persistedOperationSchema>;
