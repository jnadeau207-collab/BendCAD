import { z } from "zod";

export const entityKindSchema = z.enum(["face", "edge", "vertex"]);
export type EntityKind = z.infer<typeof entityKindSchema>;

export const geometryClassSchema = z.enum([
  "plane",
  "cylinder",
  "cone",
  "sphere",
  "torus",
  "bezier-surface",
  "bspline-surface",
  "line",
  "circle",
  "ellipse",
  "bezier-curve",
  "bspline-curve",
  "point",
  "other",
]);
export type GeometryClass = z.infer<typeof geometryClassSchema>;

const finiteNumber = z.number().finite();

const geometryClassesByKind: Readonly<
  Record<EntityKind, ReadonlySet<GeometryClass>>
> = {
  face: new Set([
    "plane",
    "cylinder",
    "cone",
    "sphere",
    "torus",
    "bezier-surface",
    "bspline-surface",
    "other",
  ]),
  edge: new Set([
    "line",
    "circle",
    "ellipse",
    "bezier-curve",
    "bspline-curve",
    "other",
  ]),
  vertex: new Set(["point"]),
};

const adjacentKindsByKind: Readonly<
  Record<EntityKind, ReadonlySet<EntityKind>>
> = {
  face: new Set(["edge"]),
  edge: new Set(["face", "vertex"]),
  vertex: new Set(["edge"]),
};

const axisCompatibleClasses: ReadonlySet<GeometryClass> = new Set([
  "plane",
  "cylinder",
  "cone",
  "line",
  "circle",
  "ellipse",
]);

const undirectedAxisClasses: ReadonlySet<GeometryClass> = new Set([
  "cylinder",
  "cone",
  "line",
  "circle",
  "ellipse",
]);

const radiusCompatibleClasses: ReadonlySet<GeometryClass> = new Set([
  "cylinder",
  "cone",
  "circle",
]);

const topologySelectionEvidenceFields = {
  kind: entityKindSchema,
  geometryClass: geometryClassSchema,
  /** Face area in mm², edge length in mm, or zero for a vertex. */
  measure: finiteNumber.nonnegative(),
  centroid: z.tuple([finiteNumber, finiteNumber, finiteNumber]),
  axis: z.tuple([finiteNumber, finiteNumber, finiteNumber]).nullable(),
  radius: finiteNumber.nonnegative().nullable(),
} as const;

function validateTopologyEvidence(
  entity: {
    readonly kind: EntityKind;
    readonly geometryClass: GeometryClass;
    readonly axis: readonly [number, number, number] | null;
    readonly radius: number | null;
  },
  context: z.RefinementCtx,
): void {
  if (!geometryClassesByKind[entity.kind].has(entity.geometryClass)) {
    context.addIssue({
      code: "custom",
      message: `Geometry class ${entity.geometryClass} is incompatible with topology kind ${entity.kind}`,
      path: ["geometryClass"],
    });
  }
  if (
    entity.axis !== null &&
    !axisCompatibleClasses.has(entity.geometryClass)
  ) {
    context.addIssue({
      code: "custom",
      message: `Geometry class ${entity.geometryClass} cannot carry axis evidence`,
      path: ["axis"],
    });
  }
  if (entity.axis !== null) {
    const magnitude = Math.hypot(...entity.axis);
    if (Math.abs(magnitude - 1) > 1e-6) {
      context.addIssue({
        code: "custom",
        message: "Topology axis evidence must be a unit vector",
        path: ["axis"],
      });
    }
    if (undirectedAxisClasses.has(entity.geometryClass)) {
      const leading = entity.axis.find(
        (component) => Math.abs(component) > 1e-9,
      );
      if (leading === undefined || leading < 0) {
        context.addIssue({
          code: "custom",
          message:
            "Undirected topology axis evidence must use the canonical positive sign",
          path: ["axis"],
        });
      }
    }
  }
  if (
    entity.radius !== null &&
    !radiusCompatibleClasses.has(entity.geometryClass)
  ) {
    context.addIssue({
      code: "custom",
      message: `Geometry class ${entity.geometryClass} cannot carry radius evidence`,
      path: ["radius"],
    });
  }
}

/**
 * Bounded identity evidence for one displayed AEMB row. The native host derives
 * this from the same dense OCCT maps used by tessellation, so selection
 * recording does not need to ship an unbounded whole-body topology snapshot.
 */
export const topologySelectionEvidenceSchema = z
  .object(topologySelectionEvidenceFields)
  .strict()
  .superRefine(validateTopologyEvidence);
export type TopologySelectionEvidence = z.infer<
  typeof topologySelectionEvidenceSchema
>;

export const topologyEntitySchema = z
  .object({
    token: z.string().min(1).max(256),
    ...topologySelectionEvidenceFields,
    orientation: z.enum(["forward", "reversed", "internal", "external"]),
    adjacentTokens: z.array(z.string().min(1).max(256)).max(100_000),
    /** Epoch-local producing operation. This is provenance, not durable identity. */
    provenanceOperationId: z.string().min(1).max(256),
    /**
     * Unit axis characterizing the entity's direction. `null` for non-axial
     * geometry (sphere, torus, bezier/bspline, vertex, "other"). Two flavors,
     * both emitted by the kernel:
     *
     * - Planar FACES carry a DIRECTED outward normal: the plane normal
     *   negated when the face is REVERSED, so it points out of the material.
     *   A box's +Z and -Z faces therefore emit OPPOSITE axes and are
     *   correctly distinguished by AQL's axis gate.
     * - Cylinder/cone axes of revolution and all EDGE directions/axes carry
     *   an UNDIRECTED canonical axis: sign-flipped so the first component
     *   exceeding 1e-9 in absolute value is positive, which keeps TopoDS
     *   forward/reversed orientation from flipping the reported sign. Known
     *   residual: two entities on the same axis line (e.g. a box's opposite
     *   parallel edges) share this value, so the axis gate does not separate
     *   them — that needs centroid/measure scoring, not axis.
     *
     * Synthetic tournament fixtures may deliberately omit otherwise-available
     * axis evidence by using `null`, but a non-null axis is accepted only for a
     * geometry class the kernel can actually project direction evidence for.
     */
    axis: topologySelectionEvidenceFields.axis,
    /**
     * Cylindrical/conical face radius or circular edge radius, mirroring
     * `ResolvedEntity.radius` (kernel-protocol.ts) so the desktop selection
     * recorder can fold it into its identity fingerprint — two coaxial
     * analytic features with the same centroid/axis and coincidentally equal
     * lateral area (radius*height) are otherwise indistinguishable.
     *
     * Synthetic corpora may deliberately set analytic radius evidence to
     * `null`; any non-null radius is accepted only for cylinder, cone, or
     * circle classes and is rejected as contradictory evidence elsewhere.
     */
    radius: topologySelectionEvidenceFields.radius,
  })
  .strict()
  .superRefine(validateTopologyEvidence);
export type TopologyEntity = z.infer<typeof topologyEntitySchema>;

export const topologySnapshotSchema = z
  .object({
    snapshotId: z.string().min(1).max(256),
    evaluationEpoch: z.number().int().nonnegative(),
    entities: z.array(topologyEntitySchema).max(1_000_000),
  })
  .strict()
  .superRefine((snapshot, context) => {
    const tokenIndices = new Map<string, number>();
    const entitiesByToken = new Map<string, TopologyEntity>();
    const adjacencyByToken = new Map<string, ReadonlySet<string>>();
    for (const [index, entity] of snapshot.entities.entries()) {
      const prior = tokenIndices.get(entity.token);
      if (prior !== undefined) {
        context.addIssue({
          code: "custom",
          message: `Duplicate topology token ${entity.token}; first seen at entity ${prior}`,
          path: ["entities", index, "token"],
        });
      } else {
        tokenIndices.set(entity.token, index);
        entitiesByToken.set(entity.token, entity);
        adjacencyByToken.set(entity.token, new Set(entity.adjacentTokens));
      }
    }

    for (const [entityIndex, entity] of snapshot.entities.entries()) {
      const adjacent = new Set<string>();
      for (const [adjacentIndex, token] of entity.adjacentTokens.entries()) {
        const path = ["entities", entityIndex, "adjacentTokens", adjacentIndex];
        if (adjacent.has(token)) {
          context.addIssue({
            code: "custom",
            message: `Duplicate adjacent topology token ${token}`,
            path,
          });
        } else {
          adjacent.add(token);
        }
        if (token === entity.token) {
          context.addIssue({
            code: "custom",
            message: "A topology entity cannot be adjacent to itself",
            path,
          });
          continue;
        }
        const target = entitiesByToken.get(token);
        if (target === undefined) {
          context.addIssue({
            code: "custom",
            message: `Adjacent topology token ${token} is absent from the snapshot`,
            path,
          });
          continue;
        }
        if (!adjacentKindsByKind[entity.kind].has(target.kind)) {
          context.addIssue({
            code: "custom",
            message: `Topology kind ${entity.kind} cannot be adjacent to ${target.kind}`,
            path,
          });
        }
        if (!adjacencyByToken.get(token)?.has(entity.token)) {
          context.addIssue({
            code: "custom",
            message: `Topology adjacency ${entity.token} → ${token} is not reciprocal`,
            path,
          });
        }
      }
    }
  });
export type TopologySnapshot = z.infer<typeof topologySnapshotSchema>;
