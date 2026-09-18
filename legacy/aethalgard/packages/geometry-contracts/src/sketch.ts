/**
 * The `sketch` operation's wire schema — plan-02's entity model plus the
 * constraint system ADR-016 requires (CAP-035, split piece 1).
 *
 * NOTHING USER-VISIBLE SHIPS WITH THIS FILE. It is the foundation the vendored
 * solver, the entity UI and the drag-solve loop are each built on as their own
 * capabilities; landing it alone is what lets those be reviewed and reverted
 * independently.
 *
 * A DELIBERATE DEPARTURE FROM PLAN-02, recorded rather than slipped in. Plan
 * 02's `sketch` section says in its own words: "Users never see a constraint
 * solver — the UI's snapping engine gives the feel of constraints, and the
 * agent emits explicit coordinates". ADR-016 (ACCEPTED) reverses exactly that:
 * it adopts a real 2D variational solver, so a sketch has to persist the
 * constraint SYSTEM, not only the coordinates its snapping happened to produce.
 * The entity model below is plan-02's, verbatim and complete; the `constraints`
 * and `solution` fields are ADR-016's addition on top of it. Plan 02's
 * "no constraint solver in v1" ruling is therefore superseded for this
 * operation, which is a spec correction owed back to plan 02 — see the packet.
 *
 * `snapHints` survive because plan 02 makes them normative AND normatively
 * INERT: they record what the UI inferred at draw time so re-opening a sketch
 * can re-derive live snapping. They are never solved, never load-bearing, and
 * (plan 02 §10.1's exclusion list) are dropped before subgraph hashing — so
 * editing a hint recomputes nothing. That exclusion is a property the op-hash
 * projection must honour, and it is asserted in this module's tests rather than
 * left as prose.
 */
import { z } from "zod";

import { operationRefSchema } from "./refs.js";

/**
 * A sketch entity id: `ent_` + a Crockford-base-32 ULID, unique per DOCUMENT
 * (plan 02 §4). Minted by the creating client, never by the kernel — the
 * kernel resolves entities, it does not name them.
 */
export const sketchEntityIdSchema = z
  .string()
  .regex(
    /^ent_[0-9A-HJKMNP-TV-Z]{26}$/,
    "a sketch entity id is `ent_` followed by a 26-character ULID",
  )
  .describe("Document-unique sketch entity id");

/** A sketch constraint id, minted the same way and unique per document. */
export const sketchConstraintIdSchema = z
  .string()
  .regex(
    /^cst_[0-9A-HJKMNP-TV-Z]{26}$/,
    "a sketch constraint id is `cst_` followed by a 26-character ULID",
  )
  .describe("Document-unique sketch constraint id");

/**
 * Plan 02's coordinate envelope: every evaluated sketch coordinate satisfies
 * |c| ≤ 1e7, else `E_SKETCH_ENTITY_RANGE`. Stated once so no entity restates
 * it and they cannot drift apart.
 */
const SKETCH_COORD_LIMIT = 1e7;
/** Plan 02's degeneracy floor: below this a distance is "no size" at all. */
const SKETCH_MIN_SIZE = 1e-6;

function requiredAt<T>(
  values: readonly T[],
  index: number,
  context: string,
): T {
  const value = values[index];
  if (value === undefined) throw new Error(`${context} is out of range.`);
  return value;
}

const sketchCoordinate = z
  .number()
  .finite()
  .min(-SKETCH_COORD_LIMIT)
  .max(SKETCH_COORD_LIMIT);

/** A sketch-plane `(u, v)` point in millimetres. */
export const point2Schema = z.tuple([sketchCoordinate, sketchCoordinate]);

/** A positive sketch dimension: ≥ 1e-6 (else degenerate) and ≤ 1e7. */
const sketchSize = z
  .number()
  .finite()
  .min(SKETCH_MIN_SIZE)
  .max(SKETCH_COORD_LIMIT);

/** Degrees, CCW from +u. Any finite value; normalized where a kind says so. */
const sketchAngle = z.number().finite();

/**
 * A dimensional expression is persisted beside its evaluated value.  The
 * document-model materializer resolves it against the document parameter
 * table before the kernel wire is built; keeping the source here means a
 * sketch dimension remains associative when a named parameter changes.
 */
const sketchDimensionExpression = z.string().trim().min(1).max(512);

/**
 * One snap the UI inferred at draw time (plan 02, "snapHints").
 *
 * INFORMATIONAL ONLY. `targets` entries are entity ids or AQL query strings and
 * are validated only against this shape — a dangling or unparseable target is
 * ignored silently, because a hint that has gone stale must never fail a
 * document that is otherwise valid.
 */
export const sketchSnapHintSchema = z
  .object({
    kind: z.enum([
      "coincident",
      "midpoint",
      "perpendicular",
      "tangent",
      "horizontal",
      "vertical",
      "concentric",
      "on-curve",
    ]),
    targets: z.array(z.string()).max(8),
  })
  .strict();

/** Fields every entity kind carries (plan 02, "Entity record — common fields"). */
const sketchEntityBase = {
  eid: sketchEntityIdSchema,
  /**
   * Construction geometry is lowered and selectable but EXCLUDED from the
   * region arrangement — a centreline is a real entity a revolve axis can
   * reference, and it must not also become a region boundary.
   */
  construction: z.boolean().default(false),
  snapHints: z.array(sketchSnapHintSchema).max(16).optional(),
};

/* --- The eleven entity kinds (plan 02, verbatim) ------------------------- */

export const sketchPointSchema = z
  .object({ ...sketchEntityBase, kind: z.literal("point"), at: point2Schema })
  .strict();

export const sketchLineSchema = z
  .object({
    ...sketchEntityBase,
    kind: z.literal("line"),
    p1: point2Schema,
    p2: point2Schema,
  })
  .strict();

export const sketchPolylineSchema = z
  .object({
    ...sketchEntityBase,
    kind: z.literal("polyline"),
    points: z.array(point2Schema).min(2).max(512),
    closed: z.boolean().default(false),
  })
  .strict();

export const sketchRectangleSchema = z
  .object({
    ...sketchEntityBase,
    kind: z.literal("rectangle"),
    mode: z.enum(["center", "corner"]),
    position: point2Schema,
    width: sketchSize,
    height: sketchSize,
    rotation: sketchAngle.default(0),
  })
  .strict();

export const sketchCircleSchema = z
  .object({
    ...sketchEntityBase,
    kind: z.literal("circle"),
    center: point2Schema,
    radius: sketchSize,
  })
  .strict();

export const sketchArcCenterSchema = z
  .object({
    ...sketchEntityBase,
    kind: z.literal("arc-center"),
    center: point2Schema,
    radius: sketchSize,
    startAngle: sketchAngle,
    endAngle: sketchAngle,
    ccw: z.boolean().default(true),
  })
  .strict();

export const sketchArcThreePointSchema = z
  .object({
    ...sketchEntityBase,
    kind: z.literal("arc-three-point"),
    p1: point2Schema,
    p2: point2Schema,
    p3: point2Schema,
  })
  .strict();

export const sketchEllipseSchema = z
  .object({
    ...sketchEntityBase,
    kind: z.literal("ellipse"),
    center: point2Schema,
    // `radiusX < radiusY` is LEGAL — lowering swaps the major axis. Refusing it
    // here would reject a sketch the kernel builds correctly.
    radiusX: sketchSize,
    radiusY: sketchSize,
    rotation: sketchAngle.default(0),
  })
  .strict();

export const sketchPolygonSchema = z
  .object({
    ...sketchEntityBase,
    kind: z.literal("polygon"),
    center: point2Schema,
    sides: z.number().int().min(3).max(64),
    circumradius: sketchSize,
    rotation: sketchAngle.default(0),
  })
  .strict();

export const sketchSlotSchema = z
  .object({
    ...sketchEntityBase,
    kind: z.literal("slot"),
    p1: point2Schema,
    p2: point2Schema,
    width: sketchSize,
  })
  .strict();

export const sketchSplineSchema = z
  .object({
    ...sketchEntityBase,
    kind: z.literal("spline"),
    points: z.array(point2Schema).min(3).max(512),
    closed: z.boolean().default(false),
  })
  .strict();

export const sketchEntitySchema = z.discriminatedUnion("kind", [
  sketchPointSchema,
  sketchLineSchema,
  sketchPolylineSchema,
  sketchRectangleSchema,
  sketchCircleSchema,
  sketchArcCenterSchema,
  sketchArcThreePointSchema,
  sketchEllipseSchema,
  sketchPolygonSchema,
  sketchSlotSchema,
  sketchSplineSchema,
]);

export type SketchEntity = z.infer<typeof sketchEntitySchema>;

/* --- Constraints (ADR-016's addition, not plan-02's) --------------------- */

/**
 * One endpoint or centre a constraint can bind to.
 *
 * A constraint names an ENTITY plus which of its points, never a coordinate —
 * the whole purpose of a solver is that coordinates move. `point` is the entity
 * itself for the `point` kind; `center` names a circle or arc centre.
 */
export const sketchAnchorSchema = z
  .object({
    eid: sketchEntityIdSchema,
    at: z.enum(["start", "end", "center", "point", "mid"]),
  })
  .strict();

const constraintBase = { cid: sketchConstraintIdSchema };

/** Two anchors occupy the same location. */
export const coincidentConstraintSchema = z
  .object({
    ...constraintBase,
    kind: z.literal("coincident"),
    a: sketchAnchorSchema,
    b: sketchAnchorSchema,
  })
  .strict();

/** A line-like entity runs along +u (horizontal) or +v (vertical). */
export const axisAlignedConstraintSchema = z
  .object({
    ...constraintBase,
    kind: z.enum(["horizontal", "vertical"]),
    eid: sketchEntityIdSchema,
  })
  .strict();

/**
 * Two lines held at a fixed relative direction: running the same way
 * (parallel), or meeting at a right angle (perpendicular).
 *
 * These name ENTITIES, not anchors, and that is the whole design of the record.
 * A direction belongs to a line as a whole, so "which endpoint is the parallel
 * on" is a question with no answer; `a` and `b` are entity ids because binding
 * a direction to a point would invent a distinction the geometry does not have.
 *
 * Unlike horizontal/vertical, these are RELATIVE: they say how two lines stand
 * to each other and fix neither one in the sketch. A pair of parallel lines is
 * still free to rotate together, which is what makes them composable with a
 * separate angular dimension rather than a competitor to one.
 */
export const lineRelationConstraintSchema = z
  .object({
    ...constraintBase,
    kind: z.enum(["parallel", "perpendicular"]),
    a: sketchEntityIdSchema,
    b: sketchEntityIdSchema,
  })
  .strict();

/**
 * A dimensioned distance between two anchors.
 *
 * `value` is a length, so it takes the same positive envelope every other
 * sketch dimension does — a zero-distance dimension is a coincidence
 * constraint, and expressing it as a distance would be a different statement
 * about the same intent.
 */
export const distanceConstraintSchema = z
  .object({
    ...constraintBase,
    kind: z.literal("distance"),
    a: sketchAnchorSchema,
    b: sketchAnchorSchema,
    value: sketchSize,
    expression: sketchDimensionExpression.optional(),
    /** Reference dimensions report a measurement but do not drive geometry. */
    driving: z.boolean().optional(),
  })
  .strict();

/** A dimensioned radius on a circle or arc. */
export const radiusConstraintSchema = z
  .object({
    ...constraintBase,
    kind: z.literal("radius"),
    eid: sketchEntityIdSchema,
    value: sketchSize,
    expression: sketchDimensionExpression.optional(),
    driving: z.boolean().optional(),
  })
  .strict();

/** A midpoint of one line lies on another selected line. */
export const midpointConstraintSchema = z
  .object({
    ...constraintBase,
    kind: z.literal("midpoint"),
    a: sketchEntityIdSchema,
    b: sketchEntityIdSchema,
  })
  .strict();

/** Two line-like entities occupy the same infinite line. */
export const collinearConstraintSchema = z
  .object({
    ...constraintBase,
    kind: z.literal("collinear"),
    a: sketchEntityIdSchema,
    b: sketchEntityIdSchema,
  })
  .strict();

/** A horizontal/vertical distance or line length dimension. */
export const orientedDistanceConstraintSchema = z
  .object({
    ...constraintBase,
    kind: z.enum(["horizontal-distance", "vertical-distance", "length"]),
    a: sketchAnchorSchema,
    b: sketchAnchorSchema,
    value: sketchSize,
    expression: sketchDimensionExpression.optional(),
    driving: z.boolean().optional(),
  })
  .strict();

/** Diameter of a circle or circular arc. */
export const diameterConstraintSchema = z
  .object({
    ...constraintBase,
    kind: z.literal("diameter"),
    eid: sketchEntityIdSchema,
    value: sketchSize,
    expression: sketchDimensionExpression.optional(),
    driving: z.boolean().optional(),
  })
  .strict();

/** Durable fix/ground intent. Unfix is represented by removing this record. */
export const fixedConstraintSchema = z
  .object({
    ...constraintBase,
    kind: z.enum(["fix", "ground"]),
    eid: sketchEntityIdSchema,
  })
  .strict();

/** Two curves or lines share a common tangent at their contact. */
export const curveRelationConstraintSchema = z
  .object({
    ...constraintBase,
    kind: z.enum(["tangent", "equal", "concentric"]),
    a: sketchEntityIdSchema,
    b: sketchEntityIdSchema,
  })
  .strict();

/** Two anchors are mirrored about a selected construction line. */
export const symmetryConstraintSchema = z
  .object({
    ...constraintBase,
    kind: z.literal("symmetry"),
    a: sketchAnchorSchema,
    b: sketchAnchorSchema,
    axis: sketchEntityIdSchema,
  })
  .strict();

/** A driving angle between two line-like entities, in degrees. */
export const angleConstraintSchema = z
  .object({
    ...constraintBase,
    kind: z.enum(["angle", "angular"]),
    a: sketchEntityIdSchema,
    b: sketchEntityIdSchema,
    value: z.number().finite().min(-360).max(360),
    expression: sketchDimensionExpression.optional(),
    driving: z.boolean().optional(),
  })
  .strict();

export const sketchConstraintSchema = z.discriminatedUnion("kind", [
  coincidentConstraintSchema,
  axisAlignedConstraintSchema.extend({ kind: z.literal("horizontal") }),
  axisAlignedConstraintSchema.extend({ kind: z.literal("vertical") }),
  lineRelationConstraintSchema.extend({ kind: z.literal("parallel") }),
  lineRelationConstraintSchema.extend({ kind: z.literal("perpendicular") }),
  distanceConstraintSchema,
  radiusConstraintSchema,
  midpointConstraintSchema,
  collinearConstraintSchema,
  orientedDistanceConstraintSchema,
  diameterConstraintSchema,
  fixedConstraintSchema,
  curveRelationConstraintSchema.extend({ kind: z.literal("tangent") }),
  curveRelationConstraintSchema.extend({ kind: z.literal("equal") }),
  curveRelationConstraintSchema.extend({ kind: z.literal("concentric") }),
  symmetryConstraintSchema,
  angleConstraintSchema.extend({ kind: z.literal("angle") }),
  angleConstraintSchema.extend({ kind: z.literal("angular") }),
]);

export type SketchConstraint = z.infer<typeof sketchConstraintSchema>;

/**
 * The solver's accepted answer for one entity, stored alongside the system.
 *
 * ADR-016's determinism decision is store-system-PLUS-solution: replay
 * re-solves and asserts the result reproduces this, and a divergence fails the
 * document CLOSED rather than silently drifting. That is only possible because
 * the accepted coordinates are persisted here — a document carrying only the
 * constraint system would have nothing to disagree with.
 */
export const sketchSolvedEntitySchema = z
  .object({
    eid: sketchEntityIdSchema,
    /**
     * The solved coordinates, in the entity's own field order. Deliberately a
     * flat number list rather than a per-kind shape: this is the solver's
     * output vector, and giving it structure would invite it to drift from the
     * entity schema it mirrors.
     */
    values: z.array(z.number().finite()).max(1024),
  })
  .strict();

export const sketchSolutionSchema = z
  .object({
    /** Every entity the solver moved, in entity order. */
    entities: z.array(sketchSolvedEntitySchema).max(2048),
    /**
     * Degrees of freedom the system left free. Zero means fully constrained —
     * the state a drag must refuse, naming the constraint that blocks it.
     */
    degreesOfFreedom: z.number().int().min(0),
  })
  .strict();

export type SketchSolution = z.infer<typeof sketchSolutionSchema>;

/**
 * Associative projected/include geometry. The source is deliberately a
 * topology reference rather than a snapshot of points: replay resolves it
 * against the current upstream result, so changing that result updates the
 * sketch or fails with a typed missing/ambiguous reference.
 */
export function sketchProjectedGeometrySchemaWith(
  ref: typeof operationRefSchema,
) {
  return z
    .object({
      eid: sketchEntityIdSchema,
      source: ref,
      mode: z.enum(["project", "include", "intersect"]).default("project"),
      construction: z.boolean().default(true),
    })
    .strict();
}

export const sketchProjectedGeometrySchema =
  sketchProjectedGeometrySchemaWith(operationRefSchema);

export type SketchProjectedGeometry = z.infer<
  typeof sketchProjectedGeometrySchema
>;

/** Number of values in the canonical solver vector for one entity. */
export function sketchEntityValueCount(entity: SketchEntity): number {
  switch (entity.kind) {
    case "point":
      return 2;
    case "line":
      return 4;
    case "circle":
      return 3;
    case "arc-center":
      return 5;
    case "polyline":
    case "spline":
      return entity.points.length * 2;
    case "rectangle":
      return 5;
    case "arc-three-point":
      return 6;
    case "ellipse":
      return 5;
    case "polygon":
      return 5;
    case "slot":
      return 5;
  }
}

/**
 * The `sketch` operation: an ordered entity list on a plane, the constraint
 * system over it, and the solver's accepted solution.
 *
 * Produces NO body — it is a profile provider (plan 01 §2). Consumers pull
 * closed regions through `regions(sketch(op_x))`; entities and their vertices
 * are selectable too, which is what lets a construction line serve as a
 * revolve axis.
 *
 * `entities: []` is LEGAL and so is `constraints: []`. Plan 02 says zero
 * entities and zero regions are valid — a sketch used only as a path or guide
 * is a real thing, and refusing an empty sketch would make the first moment of
 * every sketch an error state.
 *
 * The operation ENVELOPE is assembled in `operations.ts`, not here, so that the
 * discriminated union can include it without this module importing back from
 * the file that imports it. A schema outside the union is not an operation
 * kind — the review that found this said it plainly — so the envelope must live
 * where the union does.
 */
export function sketchParametersSchemaWith(ref: typeof operationRefSchema) {
  return z
    .object({
      /**
       * The sketch plane: a planar model face, a datum plane, or a world plane.
       * An OPERATION-level reference (ADR-003) — never epoch-local topology, so
       * the sketch survives a rebuild of the face it sits on.
       */
      plane: ref,
      entities: z.array(sketchEntitySchema).max(2048),
      projected: z
        .array(sketchProjectedGeometrySchemaWith(ref))
        .max(512)
        .default([]),
      constraints: z.array(sketchConstraintSchema).max(2048).default([]),
      /**
       * Entity ids whose parameters are PINNED for the solve.
       *
       * Part of the SYSTEM, not a hint. ADR-016's determinism contract is
       * store-system-plus-solution and re-solve on replay; a system solved with
       * an anchor and replayed without one is a DIFFERENT system, so replay
       * legitimately computes different coordinates and the document is refused.
       * CAP-037 hit exactly that on its first packaged commit.
       *
       * OPTIONAL with no default: an absent value must stay absent so documents
       * authored before this field, and the pinned op-hash golden vector, are
       * byte-identical to what they were.
       */
      grounded: z.array(sketchEntityIdSchema).max(2048).optional(),
      /**
       * Absent on a sketch that has never been solved (an empty one, or one
       * with no constraints). Present once the solver has accepted an answer,
       * and then it is what replay must reproduce.
       */
      solution: sketchSolutionSchema.optional(),
    })
    .strict()
    .superRefine((parameters, context) => {
      const ids = new Set<string>();
      for (const entity of parameters.entities) ids.add(entity.eid);
      for (const projection of parameters.projected) {
        if (ids.has(projection.eid)) {
          context.addIssue({
            code: z.ZodIssueCode.custom,
            message: `projected geometry id ${projection.eid} is already used by a sketch entity`,
            path: ["projected"],
          });
        }
        ids.add(projection.eid);
      }
    });
}

/**
 * The PERSISTED parameters (`plane` as `{query}`). The kernel-wire twin is
 * built from the same factory in operations.ts with the `{ast}` ref, so the two
 * can never drift in anything but the ref-slot form.
 */
export const sketchParametersSchema =
  sketchParametersSchemaWith(operationRefSchema);

export type SketchParameters = z.infer<typeof sketchParametersSchema>;

/**
 * The shape the validation helpers below read. Structural rather than the full
 * operation so they stay usable from either side of the envelope split.
 */
export interface SketchLike {
  readonly parameters: SketchParameters;
}

/**
 * The validation ladder's own codes (plan 02 §sketch "Validation").
 *
 * These are DOC-MODEL codes, raised before the kernel is ever asked — a
 * degenerate entity is a fact about the numbers, not a geometry failure, and
 * reporting it as `GEOMETRY_FAILED` would send a person looking for a modelling
 * problem that is really a typo.
 */
export const sketchValidationCodes = Object.freeze([
  "E_DOC_DUPLICATE_ID",
  "E_DOC_MISSING_REF_SLOT",
  "E_DOC_REF_KIND_MISMATCH",
  "E_DOC_UNROOTED_REF",
  "E_SKETCH_ZERO_ENTITY",
  "E_SKETCH_ENTITY_RANGE",
  "E_SKETCH_UNKNOWN_ANCHOR",
  "E_SKETCH_OVER_CONSTRAINED",
] as const);

export type SketchValidationCode = (typeof sketchValidationCodes)[number];

export interface SketchValidationIssue {
  readonly code: SketchValidationCode;
  /** The entity or constraint the issue is pinned to, when it has one. */
  readonly id?: string;
  readonly message: string;
}

function distance2(a: readonly [number, number], b: readonly [number, number]) {
  return Math.hypot(b[0] - a[0], b[1] - a[1]);
}

/**
 * The per-kind degeneracy rules the zod shapes cannot express: a shape can have
 * every field in range and still describe nothing — two identical endpoints, a
 * three-point arc whose points are collinear.
 *
 * Separate from the schema on purpose. `safeParse` answers "is this the right
 * shape"; this answers "does this describe a curve", and the two failures want
 * different words.
 */
export function sketchEntityDegeneracy(
  entity: SketchEntity,
): SketchValidationIssue | undefined {
  const zero = (message: string): SketchValidationIssue => ({
    code: "E_SKETCH_ZERO_ENTITY",
    id: entity.eid,
    message,
  });
  switch (entity.kind) {
    case "line":
      return distance2(entity.p1, entity.p2) >= SKETCH_MIN_SIZE
        ? undefined
        : zero("A line needs two different endpoints.");
    case "slot":
      return distance2(entity.p1, entity.p2) >= SKETCH_MIN_SIZE
        ? undefined
        : zero("A slot needs a centreline with length.");
    case "polyline":
    case "spline": {
      const points = entity.points;
      const pairs = entity.closed ? points.length : points.length - 1;
      for (let index = 0; index < pairs; index += 1) {
        const from = points[index];
        const to = points[(index + 1) % points.length];
        if (from === undefined || to === undefined) continue;
        if (distance2(from, to) < SKETCH_MIN_SIZE) {
          return zero(
            `Point ${String(index + 2)} repeats the point before it.`,
          );
        }
      }
      // Plan 02: a CLOSED polyline needs at least three points, because two
      // points plus the implicit closing segment is a line drawn twice.
      if (entity.kind === "polyline" && entity.closed && points.length < 3) {
        return zero("A closed polyline needs at least three points.");
      }
      return undefined;
    }
    case "arc-three-point": {
      const [p1, p2, p3] = [entity.p1, entity.p2, entity.p3];
      if (
        distance2(p1, p2) < SKETCH_MIN_SIZE ||
        distance2(p2, p3) < SKETCH_MIN_SIZE ||
        distance2(p1, p3) < SKETCH_MIN_SIZE
      ) {
        return zero("A three-point arc needs three distinct points.");
      }
      // Twice the triangle area; collinear points define no circle.
      const area2 = Math.abs(
        (p2[0] - p1[0]) * (p3[1] - p1[1]) - (p3[0] - p1[0]) * (p2[1] - p1[1]),
      );
      return area2 / 2 >= 1e-9
        ? undefined
        : zero("A three-point arc's points must not be in a straight line.");
    }
    default:
      // Every remaining kind's degeneracy is fully expressed by `sketchSize`
      // on its dimension fields, which the schema already enforces.
      return undefined;
  }
}

/**
 * Every anchor a constraint names must exist among the entities.
 *
 * A constraint pointing at a deleted entity is the sketch equivalent of the
 * dropped-reference class this project refuses everywhere else: the solver
 * would either ignore it or crash, and both are worse than saying so.
 */
export function sketchAnchorIssues(
  operation: SketchLike,
): SketchValidationIssue[] {
  const known = new Set(
    operation.parameters.entities.map((entity) => entity.eid),
  );
  const issues: SketchValidationIssue[] = [];
  const check = (cid: string, eid: string): void => {
    if (known.has(eid)) return;
    issues.push({
      code: "E_SKETCH_UNKNOWN_ANCHOR",
      id: cid,
      message: `This constraint refers to a shape that is no longer in the sketch.`,
    });
  };
  for (const constraint of operation.parameters.constraints) {
    switch (constraint.kind) {
      case "coincident":
      case "distance":
      case "horizontal-distance":
      case "vertical-distance":
      case "length":
        check(constraint.cid, constraint.a.eid);
        check(constraint.cid, constraint.b.eid);
        break;
      case "parallel":
      case "perpendicular":
      case "midpoint":
      case "collinear":
        // Entity ids, not anchors — a direction has no endpoint.
        check(constraint.cid, constraint.a);
        check(constraint.cid, constraint.b);
        break;
      case "tangent":
      case "equal":
      case "concentric":
      case "angle":
      case "angular":
        check(constraint.cid, constraint.a);
        check(constraint.cid, constraint.b);
        break;
      case "symmetry":
        check(constraint.cid, constraint.a.eid);
        check(constraint.cid, constraint.b.eid);
        check(constraint.cid, constraint.axis);
        break;
      default:
        check(constraint.cid, constraint.eid);
    }
  }
  for (const eid of operation.parameters.grounded ?? []) {
    if (known.has(eid)) continue;
    issues.push({
      code: "E_SKETCH_UNKNOWN_ANCHOR",
      id: eid,
      message: "This grounded shape is no longer in the sketch.",
    });
  }
  return issues;
}

/**
 * Entity ids duplicated within one sketch (plan 02 §4's id-integrity step).
 *
 * Document-wide uniqueness is the document model's to enforce; what this
 * module can see, and must, is a sketch that names the same entity twice.
 */
export function sketchDuplicateIdIssues(
  operation: SketchLike,
): SketchValidationIssue[] {
  const seen = new Set<string>();
  const issues: SketchValidationIssue[] = [];
  for (const entity of operation.parameters.entities) {
    if (seen.has(entity.eid)) {
      issues.push({
        code: "E_DOC_DUPLICATE_ID",
        id: entity.eid,
        message: "Two shapes in this sketch share an id.",
      });
    }
    seen.add(entity.eid);
  }
  for (const constraint of operation.parameters.constraints) {
    if (seen.has(constraint.cid)) {
      issues.push({
        code: "E_DOC_DUPLICATE_ID",
        id: constraint.cid,
        message: "A constraint shares an id with something else in the sketch.",
      });
    }
    seen.add(constraint.cid);
  }
  const grounded = new Set<string>();
  for (const eid of operation.parameters.grounded ?? []) {
    if (grounded.has(eid)) {
      issues.push({
        code: "E_DOC_DUPLICATE_ID",
        id: eid,
        message: "The same shape is grounded more than once.",
      });
    }
    grounded.add(eid);
  }
  return issues;
}

/** The whole doc-model ladder for one parsed sketch, in plan-02's order. */
export function validateSketch(operation: SketchLike): SketchValidationIssue[] {
  const issues: SketchValidationIssue[] = [
    ...sketchDuplicateIdIssues(operation),
  ];
  for (const entity of operation.parameters.entities) {
    const degenerate = sketchEntityDegeneracy(entity);
    if (degenerate !== undefined) issues.push(degenerate);
  }
  issues.push(...sketchAnchorIssues(operation));
  return issues;
}

/**
 * The operation's parameters with every `snapHints` member removed.
 *
 * Plan 02 §10.1's exclusion list, as code: hints are dropped before JCS
 * canonicalization exactly as ref `anchors` are, so editing a hint recomputes
 * NOTHING. Expressed here rather than in the hasher so the rule lives beside
 * the field it is about, and so a test can assert it without a hasher.
 */
export function sketchParametersForHashing(
  operation: SketchLike,
): SketchParameters {
  return {
    ...operation.parameters,
    entities: operation.parameters.entities.map((entity) => {
      // Rebuilt without the key rather than set to undefined: a present-but-
      // undefined `snapHints` still serializes differently under JCS, which is
      // exactly the difference this exclusion exists to erase.
      const rest: Record<string, unknown> = { ...entity };
      delete rest["snapHints"];
      return rest as unknown as SketchEntity;
    }),
  };
}

/* --- The closed region (CAP-038) ---------------------------------------- */

/**
 * One boundary curve of a closed sketch region, with its endpoints already
 * resolved from the solved values.
 *
 * A flat record rather than the entity itself: the kernel builds a wire from
 * these numbers, and handing it an entity would make it re-derive the solved
 * coordinates a second way.
 */
export type SketchRegionSegment =
  | {
      readonly kind: "line";
      readonly eid: string;
      readonly start: readonly [number, number];
      readonly end: readonly [number, number];
    }
  | {
      readonly kind: "arc";
      readonly eid: string;
      readonly start: readonly [number, number];
      readonly end: readonly [number, number];
      readonly center: readonly [number, number];
      readonly radius: number;
      readonly startAngle: number;
      readonly endAngle: number;
      readonly ccw: boolean;
    }
  | {
      readonly kind: "circle";
      readonly eid: string;
      readonly center: readonly [number, number];
      readonly radius: number;
    }
  | {
      readonly kind: "ellipse";
      readonly eid: string;
      readonly center: readonly [number, number];
      readonly radiusX: number;
      readonly radiusY: number;
      readonly rotation: number;
    }
  | {
      readonly kind: "spline";
      readonly eid: string;
      readonly points: readonly (readonly [number, number])[];
      readonly closed: boolean;
    };

/** One closed boundary loop found by the sketch arrangement. */
export interface SketchRegionLoop {
  readonly segments: readonly SketchRegionSegment[];
  /** Positive for CCW material boundaries, negative for islands/holes. */
  readonly signedArea: number;
  /** Nesting depth: 0 is an outer material loop, odd depths are holes. */
  readonly depth: number;
  readonly isHole: boolean;
}

export type SketchRegionResult =
  | {
      readonly ok: true;
      /** Flattened compatibility view for existing profile consumers. */
      readonly segments: readonly SketchRegionSegment[];
      readonly loops: readonly SketchRegionLoop[];
    }
  | { readonly ok: false; readonly message: string };

/**
 * The solved parameter vector for one entity, or `undefined` when the solution
 * does not usably name it.
 *
 * The vector's order is the solver seam's canonical per-kind order
 * (`sketch_solver.hpp`): point x,y — line x1,y1,x2,y2 — circle cx,cy,r — arc
 * cx,cy,r,startAngle,endAngle. A vector of the wrong length is IGNORED rather
 * than partially applied: half a solution describes a shape that is neither
 * what was drawn nor what was solved.
 */
function solvedValues(
  entity: SketchEntity,
  solution: SketchSolution | undefined,
  expected: number,
): readonly number[] | undefined {
  const solved = solution?.entities.find((item) => item.eid === entity.eid);
  if (solved === undefined || solved.values.length !== expected) {
    return undefined;
  }
  return solved.values;
}

function arcEndpoint(
  center: readonly [number, number],
  radius: number,
  degrees: number,
): readonly [number, number] {
  const radians = (degrees * Math.PI) / 180;
  return [
    center[0] + radius * Math.cos(radians),
    center[1] + radius * Math.sin(radians),
  ];
}

/**
 * One boundary entity as a region segment, or `undefined` for a kind that
 * cannot bound a region in this tranche.
 */
function lineSegment(
  eid: string,
  start: readonly [number, number],
  end: readonly [number, number],
): SketchRegionSegment {
  return { kind: "line", eid, start, end };
}

function rotatePoint(
  point: readonly [number, number],
  origin: readonly [number, number],
  degrees: number,
): readonly [number, number] {
  const radians = (degrees * Math.PI) / 180;
  const c = Math.cos(radians);
  const s = Math.sin(radians);
  const u = point[0] - origin[0];
  const v = point[1] - origin[1];
  return [origin[0] + u * c - v * s, origin[1] + u * s + v * c];
}

function circumcircle(
  p1: readonly [number, number],
  p2: readonly [number, number],
  p3: readonly [number, number],
):
  | {
      readonly center: readonly [number, number];
      readonly radius: number;
      readonly ccw: boolean;
    }
  | undefined {
  const twiceArea =
    2 * ((p1[0] - p2[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p2[1]));
  if (Math.abs(twiceArea) < 1e-12) return undefined;
  const p1Squared = p1[0] * p1[0] + p1[1] * p1[1];
  const p2Squared = p2[0] * p2[0] + p2[1] * p2[1];
  const p3Squared = p3[0] * p3[0] + p3[1] * p3[1];
  const center: readonly [number, number] = [
    (p1Squared * (p2[1] - p3[1]) +
      p2Squared * (p3[1] - p1[1]) +
      p3Squared * (p1[1] - p2[1])) /
      twiceArea,
    (p1Squared * (p3[0] - p2[0]) +
      p2Squared * (p1[0] - p3[0]) +
      p3Squared * (p2[0] - p1[0])) /
      twiceArea,
  ];
  return {
    center,
    radius: distance2(center, p1),
    ccw:
      (p2[0] - p1[0]) * (p3[1] - p2[1]) - (p2[1] - p1[1]) * (p3[0] - p2[0]) > 0,
  };
}

function threePointArcSegment(
  eid: string,
  p1: readonly [number, number],
  p2: readonly [number, number],
  p3: readonly [number, number],
): SketchRegionSegment | undefined {
  const circle = circumcircle(p1, p2, p3);
  if (circle === undefined) return undefined;
  return {
    kind: "arc",
    eid,
    start: p1,
    end: p3,
    center: circle.center,
    radius: circle.radius,
    startAngle:
      (Math.atan2(p1[1] - circle.center[1], p1[0] - circle.center[0]) * 180) /
      Math.PI,
    endAngle:
      (Math.atan2(p3[1] - circle.center[1], p3[0] - circle.center[0]) * 180) /
      Math.PI,
    ccw: circle.ccw,
  };
}

function slotSegments(
  eid: string,
  p1: readonly [number, number],
  p2: readonly [number, number],
  width: number,
): readonly SketchRegionSegment[] {
  const dx = p2[0] - p1[0];
  const dy = p2[1] - p1[1];
  const length = Math.hypot(dx, dy);
  if (length < SKETCH_MIN_SIZE) return [];
  const radius = width / 2;
  const nx = (-dy / length) * radius;
  const ny = (dx / length) * radius;
  const p1Bottom: readonly [number, number] = [p1[0] - nx, p1[1] - ny];
  const p2Bottom: readonly [number, number] = [p2[0] - nx, p2[1] - ny];
  const p2Top: readonly [number, number] = [p2[0] + nx, p2[1] + ny];
  const p1Top: readonly [number, number] = [p1[0] + nx, p1[1] + ny];
  const normalAngle = (Math.atan2(ny, nx) * 180) / Math.PI;
  return [
    lineSegment(`${eid}:lower`, p1Bottom, p2Bottom),
    {
      kind: "arc",
      eid: `${eid}:end-cap`,
      start: p2Bottom,
      end: p2Top,
      center: p2,
      radius,
      startAngle: normalAngle - 180,
      endAngle: normalAngle,
      ccw: true,
    },
    lineSegment(`${eid}:upper`, p2Top, p1Top),
    {
      kind: "arc",
      eid: `${eid}:start-cap`,
      start: p1Top,
      end: p1Bottom,
      center: p1,
      radius,
      startAngle: normalAngle,
      endAngle: normalAngle + 180,
      ccw: true,
    },
  ];
}

function polygonPoints(
  center: readonly [number, number],
  sides: number,
  radius: number,
  rotation: number,
): readonly (readonly [number, number])[] {
  return Array.from({ length: sides }, (_, index) => {
    const radians = (rotation * Math.PI) / 180 + (index * 2 * Math.PI) / sides;
    return [
      center[0] + radius * Math.cos(radians),
      center[1] + radius * Math.sin(radians),
    ];
  });
}

/** Expand a user-level entity into the exact boundary curves it contributes. */
function regionSegments(
  entity: SketchEntity,
  solution: SketchSolution | undefined,
): readonly SketchRegionSegment[] | undefined {
  switch (entity.kind) {
    case "point":
      return undefined;
    case "line": {
      const values = solvedValues(entity, solution, 4);
      return [
        lineSegment(
          entity.eid,
          values === undefined ? entity.p1 : [values[0] ?? 0, values[1] ?? 0],
          values === undefined ? entity.p2 : [values[2] ?? 0, values[3] ?? 0],
        ),
      ];
    }
    case "polyline": {
      const values = solvedValues(entity, solution, entity.points.length * 2);
      const points =
        values === undefined
          ? entity.points
          : entity.points.map(
              (_, index) =>
                [values[index * 2] ?? 0, values[index * 2 + 1] ?? 0] as const,
            );
      const result: SketchRegionSegment[] = [];
      for (let index = 0; index < points.length - 1; index += 1) {
        const start = points[index];
        const end = points[index + 1];
        if (start !== undefined && end !== undefined) {
          result.push(lineSegment(`${entity.eid}:${index}`, start, end));
        }
      }
      if (entity.closed && points.length > 1) {
        const start = points.at(-1);
        const end = points[0];
        if (start !== undefined && end !== undefined) {
          result.push(lineSegment(`${entity.eid}:close`, start, end));
        }
      }
      return result;
    }
    case "rectangle": {
      const values = solvedValues(entity, solution, 5);
      const position: readonly [number, number] =
        values === undefined
          ? entity.position
          : [values[0] ?? 0, values[1] ?? 0];
      const width = values === undefined ? entity.width : (values[2] ?? 0);
      const height = values === undefined ? entity.height : (values[3] ?? 0);
      const rotation =
        values === undefined ? entity.rotation : (values[4] ?? 0);
      const origin = entity.mode === "center" ? position : position;
      const local =
        entity.mode === "center"
          ? ([
              [-width / 2, -height / 2],
              [width / 2, -height / 2],
              [width / 2, height / 2],
              [-width / 2, height / 2],
            ] as const)
          : ([
              [0, 0],
              [width, 0],
              [width, height],
              [0, height],
            ] as const);
      const points = local.map((point) =>
        rotatePoint(
          [origin[0] + point[0], origin[1] + point[1]],
          origin,
          rotation,
        ),
      );
      return points.map((point, index) =>
        lineSegment(
          entity.eid + ":" + String(index),
          point,
          requiredAt(
            points,
            (index + 1) % points.length,
            "Sketch polygon point",
          ),
        ),
      );
    }
    case "circle": {
      const values = solvedValues(entity, solution, 3);
      return [
        {
          kind: "circle",
          eid: entity.eid,
          center:
            values === undefined
              ? entity.center
              : [values[0] ?? 0, values[1] ?? 0],
          radius: values === undefined ? entity.radius : (values[2] ?? 0),
        },
      ];
    }
    case "arc-center": {
      const values = solvedValues(entity, solution, 5);
      const center: readonly [number, number] =
        values === undefined ? entity.center : [values[0] ?? 0, values[1] ?? 0];
      const radius = values === undefined ? entity.radius : (values[2] ?? 0);
      const startAngle =
        values === undefined ? entity.startAngle : (values[3] ?? 0);
      const endAngle =
        values === undefined ? entity.endAngle : (values[4] ?? 0);
      return [
        {
          kind: "arc",
          eid: entity.eid,
          start: arcEndpoint(center, radius, startAngle),
          end: arcEndpoint(center, radius, endAngle),
          center,
          radius,
          startAngle,
          endAngle,
          ccw: entity.ccw,
        },
      ];
    }
    case "arc-three-point": {
      const values = solvedValues(entity, solution, 6);
      const p1: readonly [number, number] =
        values === undefined ? entity.p1 : [values[0] ?? 0, values[1] ?? 0];
      const p2: readonly [number, number] =
        values === undefined ? entity.p2 : [values[2] ?? 0, values[3] ?? 0];
      const p3: readonly [number, number] =
        values === undefined ? entity.p3 : [values[4] ?? 0, values[5] ?? 0];
      const segment = threePointArcSegment(entity.eid, p1, p2, p3);
      return segment === undefined ? undefined : [segment];
    }
    case "ellipse": {
      const values = solvedValues(entity, solution, 5);
      return [
        {
          kind: "ellipse",
          eid: entity.eid,
          center:
            values === undefined
              ? entity.center
              : [values[0] ?? 0, values[1] ?? 0],
          radiusX: values === undefined ? entity.radiusX : (values[2] ?? 0),
          radiusY: values === undefined ? entity.radiusY : (values[3] ?? 0),
          rotation: values === undefined ? entity.rotation : (values[4] ?? 0),
        },
      ];
    }
    case "polygon": {
      const values = solvedValues(entity, solution, 5);
      const center: readonly [number, number] =
        values === undefined ? entity.center : [values[0] ?? 0, values[1] ?? 0];
      const sides =
        values === undefined
          ? entity.sides
          : Math.round(values[2] ?? entity.sides);
      const radius =
        values === undefined ? entity.circumradius : (values[3] ?? 0);
      const rotation =
        values === undefined ? entity.rotation : (values[4] ?? 0);
      const points = polygonPoints(center, sides, radius, rotation);
      return points.map((point, index) =>
        lineSegment(
          entity.eid + ":" + String(index),
          point,
          requiredAt(
            points,
            (index + 1) % points.length,
            "Sketch polygon point",
          ),
        ),
      );
    }
    case "slot": {
      const values = solvedValues(entity, solution, 5);
      return slotSegments(
        entity.eid,
        values === undefined ? entity.p1 : [values[0] ?? 0, values[1] ?? 0],
        values === undefined ? entity.p2 : [values[2] ?? 0, values[3] ?? 0],
        values === undefined ? entity.width : (values[4] ?? 0),
      );
    }
    case "spline": {
      const values = solvedValues(entity, solution, entity.points.length * 2);
      const points =
        values === undefined
          ? entity.points
          : entity.points.map(
              (_, index) =>
                [values[index * 2] ?? 0, values[index * 2 + 1] ?? 0] as const,
            );
      return [
        { kind: "spline", eid: entity.eid, points, closed: entity.closed },
      ];
    }
  }
}

function segmentStart(segment: SketchRegionSegment): readonly [number, number] {
  if (segment.kind === "circle") {
    return [segment.center[0] + segment.radius, segment.center[1]];
  }
  if (segment.kind === "ellipse") {
    const c = Math.cos((segment.rotation * Math.PI) / 180);
    const s = Math.sin((segment.rotation * Math.PI) / 180);
    return [
      segment.center[0] + segment.radiusX * c,
      segment.center[1] + segment.radiusX * s,
    ];
  }
  if (segment.kind === "spline") return segment.points[0] ?? [0, 0];
  return segment.start;
}

function segmentEnd(segment: SketchRegionSegment): readonly [number, number] {
  if (segment.kind === "circle") {
    return [segment.center[0] + segment.radius, segment.center[1]];
  }
  if (segment.kind === "ellipse") return segmentStart(segment);
  if (segment.kind === "spline") {
    return segment.closed
      ? (segment.points[0] ?? [0, 0])
      : (segment.points.at(-1) ?? [0, 0]);
  }
  return segment.end;
}

function reverseSegment(segment: SketchRegionSegment): SketchRegionSegment {
  switch (segment.kind) {
    case "line":
      return { ...segment, start: segment.end, end: segment.start };
    case "arc":
      return {
        ...segment,
        start: segment.end,
        end: segment.start,
        startAngle: segment.endAngle,
        endAngle: segment.startAngle,
        ccw: !segment.ccw,
      };
    case "circle":
    case "ellipse":
      return segment;
    case "spline":
      return { ...segment, points: [...segment.points].reverse() };
  }
}

function nearlyEqualPoint(
  a: readonly [number, number],
  b: readonly [number, number],
): boolean {
  return distance2(a, b) < SKETCH_MIN_SIZE;
}

function normalizeAngleRadians(angle: number): number {
  const full = Math.PI * 2;
  const normalized = angle % full;
  return normalized < 0 ? normalized + full : normalized;
}

function sampleSegment(
  segment: SketchRegionSegment,
): readonly (readonly [number, number])[] {
  if (segment.kind === "line") return [segment.start, segment.end];
  if (segment.kind === "circle") {
    return Array.from({ length: 97 }, (_, index) => {
      const angle = (index * 2 * Math.PI) / 96;
      return [
        segment.center[0] + segment.radius * Math.cos(angle),
        segment.center[1] + segment.radius * Math.sin(angle),
      ];
    });
  }
  if (segment.kind === "ellipse") {
    const rotation = (segment.rotation * Math.PI) / 180;
    const c = Math.cos(rotation);
    const s = Math.sin(rotation);
    return Array.from({ length: 97 }, (_, index) => {
      const angle = (index * 2 * Math.PI) / 96;
      const u = segment.radiusX * Math.cos(angle);
      const v = segment.radiusY * Math.sin(angle);
      return [
        segment.center[0] + u * c - v * s,
        segment.center[1] + u * s + v * c,
      ];
    });
  }
  if (segment.kind === "spline") {
    if (segment.points.length < 2) return segment.points;
    const points = [...segment.points];
    if (segment.closed)
      points.push(requiredAt(points, 0, "Closed spline point"));
    return points;
  }
  const start = (segment.startAngle * Math.PI) / 180;
  const end = (segment.endAngle * Math.PI) / 180;
  const signedSweep = segment.ccw
    ? normalizeAngleRadians(end - start)
    : -normalizeAngleRadians(start - end);
  const steps = Math.max(8, Math.ceil(Math.abs(signedSweep) / (Math.PI / 24)));
  return Array.from({ length: steps + 1 }, (_, index) => {
    const angle = start + (signedSweep * index) / steps;
    return [
      segment.center[0] + segment.radius * Math.cos(angle),
      segment.center[1] + segment.radius * Math.sin(angle),
    ];
  });
}

function cross(
  a: readonly [number, number],
  b: readonly [number, number],
  c: readonly [number, number],
): number {
  return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
}

function onSegment(
  a: readonly [number, number],
  b: readonly [number, number],
  p: readonly [number, number],
): boolean {
  return (
    Math.abs(cross(a, b, p)) < SKETCH_MIN_SIZE &&
    p[0] >= Math.min(a[0], b[0]) - SKETCH_MIN_SIZE &&
    p[0] <= Math.max(a[0], b[0]) + SKETCH_MIN_SIZE &&
    p[1] >= Math.min(a[1], b[1]) - SKETCH_MIN_SIZE &&
    p[1] <= Math.max(a[1], b[1]) + SKETCH_MIN_SIZE
  );
}

function edgesCross(
  a1: readonly [number, number],
  a2: readonly [number, number],
  b1: readonly [number, number],
  b2: readonly [number, number],
): boolean {
  const c1 = cross(a1, a2, b1);
  const c2 = cross(a1, a2, b2);
  const c3 = cross(b1, b2, a1);
  const c4 = cross(b1, b2, a2);
  if (
    onSegment(a1, a2, b1) ||
    onSegment(a1, a2, b2) ||
    onSegment(b1, b2, a1) ||
    onSegment(b1, b2, a2)
  ) {
    return (
      !nearlyEqualPoint(a1, b1) &&
      !nearlyEqualPoint(a1, b2) &&
      !nearlyEqualPoint(a2, b1) &&
      !nearlyEqualPoint(a2, b2)
    );
  }
  return c1 > 0 !== c2 > 0 && c3 > 0 !== c4 > 0;
}

function loopSamples(
  segments: readonly SketchRegionSegment[],
): readonly (readonly [number, number])[] {
  const result: (readonly [number, number])[] = [];
  for (const segment of segments) {
    const samples = sampleSegment(segment);
    for (const point of samples) {
      if (
        result.length === 0 ||
        !nearlyEqualPoint(
          requiredAt(result, result.length - 1, "Loop sample"),
          point,
        )
      ) {
        result.push(point);
      }
    }
  }
  if (
    result.length > 1 &&
    nearlyEqualPoint(
      requiredAt(result, 0, "Loop sample"),
      requiredAt(result, result.length - 1, "Loop sample"),
    )
  ) {
    result.pop();
  }
  return result;
}

function signedPolygonArea(
  points: readonly (readonly [number, number])[],
): number {
  let area = 0;
  for (let index = 0; index < points.length; index += 1) {
    const current = requiredAt(points, index, "Polygon point");
    const next = requiredAt(
      points,
      (index + 1) % points.length,
      "Polygon point",
    );
    area += current[0] * next[1] - next[0] * current[1];
  }
  return area / 2;
}

function pointInPolygon(
  point: readonly [number, number],
  polygon: readonly (readonly [number, number])[],
): boolean {
  let inside = false;
  for (
    let index = 0, previous = polygon.length - 1;
    index < polygon.length;
    previous = index++
  ) {
    const current = requiredAt(polygon, index, "Polygon point");
    const prior = requiredAt(polygon, previous, "Polygon point");
    if (current[1] > point[1] !== prior[1] > point[1]) {
      const x =
        ((prior[0] - current[0]) * (point[1] - current[1])) /
          (prior[1] - current[1]) +
        current[0];
      if (point[0] < x) inside = !inside;
    }
  }
  return inside;
}

function orientLoop(
  loop: readonly SketchRegionSegment[],
  samples: readonly (readonly [number, number])[],
  hole: boolean,
): {
  readonly segments: readonly SketchRegionSegment[];
  readonly signedArea: number;
} {
  const area = signedPolygonArea(samples);
  const shouldBePositive = !hole;
  if (area >= 0 === shouldBePositive)
    return { segments: loop, signedArea: area };
  const reversed = [...loop].reverse().map(reverseSegment);
  return {
    segments: reversed,
    signedArea: -area,
  };
}

/**
 * The one closed region a sketch encloses, or the reason it encloses none.
 *
 * Boundary (non-construction) entities are arranged by solved endpoint
 * connectivity, independent of the order in which their records arrive. The
 * same degeneracy floor a zero-length entity is measured against is used for
 * joins, so a real gap is refused rather than stitched shut. Closed curves are
 * loops on their own, and disconnected loops plus nested islands are retained
 * with deterministic depth/orientation metadata.
 *
 * This is still deliberately narrower than a general planar boolean engine:
 * self-intersections and ambiguous branches are refused with an actionable
 * diagnostic. That keeps a gap or branch from being silently repaired, in line
 * with the tolerance boundary in ADR-015 §2.
 *
 * The coordinates are the SOLVED ones wherever the solution names the entity,
 * because the solved shape is the one a person is looking at and the one the
 * document's determinism contract pins.
 */
export function sketchClosedRegion(operation: SketchLike): SketchRegionResult {
  const boundary = operation.parameters.entities.filter(
    (entity) => !entity.construction,
  );
  if (boundary.length === 0) {
    return {
      ok: false,
      message:
        "This sketch has no boundary geometry — only construction guides.",
    };
  }

  const segments: SketchRegionSegment[] = [];
  for (const entity of boundary) {
    const expanded = regionSegments(entity, operation.parameters.solution);
    if (expanded === undefined || expanded.length === 0) {
      return {
        ok: false,
        message: `A ${entity.kind} cannot bound a region — use a closed curve or connected boundary geometry.`,
      };
    }
    segments.push(...expanded);
  }

  const pending = [...segments];
  const rawLoops: SketchRegionSegment[][] = [];
  while (pending.length > 0) {
    const first = pending.shift();
    if (first === undefined) break;
    const isClosedCurve =
      first.kind === "circle" ||
      first.kind === "ellipse" ||
      (first.kind === "spline" && first.closed);
    if (isClosedCurve) {
      rawLoops.push([first]);
      continue;
    }

    const loop: SketchRegionSegment[] = [first];
    const loopStart = segmentStart(first);
    let currentEnd = segmentEnd(first);
    while (!nearlyEqualPoint(currentEnd, loopStart)) {
      const matches = pending.flatMap((candidate, index) => {
        if (candidate.kind === "circle" || candidate.kind === "ellipse") {
          return [];
        }
        if (candidate.kind === "spline" && candidate.closed) return [];
        const atStart = nearlyEqualPoint(currentEnd, segmentStart(candidate));
        const atEnd = nearlyEqualPoint(currentEnd, segmentEnd(candidate));
        if (!atStart && !atEnd) return [];
        return [{ index, candidate, reverse: !atStart }];
      });
      if (matches.length === 0) {
        const last = requiredAt(loop, loop.length - 1, "Contour segment");
        const gap = distance2(currentEnd, loopStart);
        return {
          ok: false,
          message:
            `This contour is open: ${last.eid} ends ${gap.toFixed(3)} mm ` +
            `from where ${requiredAt(loop, 0, "Contour segment").eid} starts. Join them before using the region.`,
        };
      }
      if (matches.length > 1) {
        const ids = matches.map(({ candidate }) => candidate.eid).join(", ");
        return {
          ok: false,
          message:
            `This contour is ambiguous at ${currentEnd[0].toFixed(3)}, ` +
            `${currentEnd[1].toFixed(3)} mm: ${ids} meet at the same point. ` +
            "Separate the branches or add explicit profile boundaries.",
        };
      }
      const match = requiredAt(matches, 0, "Contour match");
      const next = requiredAt(
        pending.splice(match.index, 1),
        0,
        "Contour segment",
      );
      const oriented = match.reverse ? reverseSegment(next) : next;
      loop.push(oriented);
      currentEnd = segmentEnd(oriented);
      if (loop.length > segments.length) {
        return {
          ok: false,
          message:
            "The sketch boundary could not be arranged into a closed loop.",
        };
      }
    }
    rawLoops.push(loop);
  }

  const analyzed = rawLoops.map((loop) => {
    const samples = loopSamples(loop);
    const area = signedPolygonArea(samples);
    return { loop, samples, area, absoluteArea: Math.abs(area) };
  });
  for (const item of analyzed) {
    if (item.samples.length < 3 || item.absoluteArea < SKETCH_MIN_SIZE ** 2) {
      return {
        ok: false,
        message: `The boundary loop beginning at ${item.loop[0]?.eid ?? "unknown"} has zero area.`,
      };
    }
    for (let i = 0; i < item.samples.length; i += 1) {
      const a1 = requiredAt(item.samples, i, "Boundary sample");
      const a2 = requiredAt(
        item.samples,
        (i + 1) % item.samples.length,
        "Boundary sample",
      );
      for (let j = i + 1; j < item.samples.length; j += 1) {
        const adjacent =
          j === i + 1 || (i === 0 && j === item.samples.length - 1);
        if (adjacent) continue;
        const b1 = requiredAt(item.samples, j, "Boundary sample");
        const b2 = requiredAt(
          item.samples,
          (j + 1) % item.samples.length,
          "Boundary sample",
        );
        if (edgesCross(a1, a2, b1, b2)) {
          return {
            ok: false,
            message:
              `The boundary beginning at ${item.loop[0]?.eid ?? "unknown"} ` +
              "self-intersects; a solid region cannot be determined.",
          };
        }
      }
    }
  }

  const withDepth = analyzed.map((item, index) => {
    const probe = item.samples.reduce(
      (sum, point) => [sum[0] + point[0], sum[1] + point[1]] as const,
      [0, 0] as const,
    );
    const average: readonly [number, number] = [
      probe[0] / item.samples.length,
      probe[1] / item.samples.length,
    ];
    const depth = analyzed.filter(
      (other, otherIndex) =>
        otherIndex !== index &&
        other.absoluteArea > item.absoluteArea &&
        pointInPolygon(average, other.samples),
    ).length;
    return { ...item, depth };
  });
  const loops = withDepth.map((item) => {
    const oriented = orientLoop(item.loop, item.samples, item.depth % 2 === 1);
    return {
      segments: oriented.segments,
      signedArea: oriented.signedArea,
      depth: item.depth,
      isHole: item.depth % 2 === 1,
    } satisfies SketchRegionLoop;
  });
  return { ok: true, segments: loops.flatMap((loop) => loop.segments), loops };
}

/** Durable material-region ids, byte-identical to the native evaluator. */
export function sketchClosedRegionIds(
  operation: SketchLike,
): readonly string[] {
  const result = sketchClosedRegion(operation);
  if (!result.ok) return [];
  const ids: string[] = [];
  for (const [outerIndex, outer] of result.loops.entries()) {
    if (outer.depth % 2 !== 0) continue;
    const outerSamples = loopSamples(outer.segments);
    const contributing = [outer];
    for (const [holeIndex, hole] of result.loops.entries()) {
      if (holeIndex === outerIndex || hole.depth !== outer.depth + 1) continue;
      const samples = loopSamples(hole.segments);
      if (samples.length === 0 || outerSamples.length === 0) continue;
      const probe = samples.reduce(
        (sum, point) =>
          [
            sum[0] + point[0] / samples.length,
            sum[1] + point[1] / samples.length,
          ] as const,
        [0, 0] as const,
      );
      if (pointInPolygon(probe, outerSamples)) contributing.push(hole);
    }
    const eids = contributing
      .flatMap((loop) => loop.segments.map((segment) => segment.eid))
      .filter((eid) => eid.length > 0)
      .sort()
      .filter((eid, index, all) => index === 0 || eid !== all[index - 1]);
    ids.push(`region:${eids.join("+")}`);
  }
  return ids;
}

/** Half-extents of a region's bounding box in the sketch plane. */
export interface SketchRegionExtent {
  readonly halfU: number;
  readonly halfV: number;
  /** The bounding box centre, in sketch-plane millimetres. */
  readonly center: readonly [number, number];
}

/**
 * The region's bounding half-extent, measured from the same solved numbers the
 * region is built from.
 *
 * BOUNDING, and for an arc it bounds the whole circle rather than the swept
 * span. That is the safe direction for its one consumer — a revolve axis placed
 * at a tangent — exactly as `profileExtent`'s polygon circumradius is: an
 * under-estimate would put the axis through the region and earn a kernel
 * refusal the person did not cause.
 */
export function sketchRegionExtent(
  segments: readonly SketchRegionSegment[],
): SketchRegionExtent {
  let minU = Number.POSITIVE_INFINITY;
  let minV = Number.POSITIVE_INFINITY;
  let maxU = Number.NEGATIVE_INFINITY;
  let maxV = Number.NEGATIVE_INFINITY;
  const include = (u: number, v: number): void => {
    minU = Math.min(minU, u);
    minV = Math.min(minV, v);
    maxU = Math.max(maxU, u);
    maxV = Math.max(maxV, v);
  };
  for (const segment of segments) {
    if (segment.kind === "circle" || segment.kind === "arc") {
      include(
        segment.center[0] - segment.radius,
        segment.center[1] - segment.radius,
      );
      include(
        segment.center[0] + segment.radius,
        segment.center[1] + segment.radius,
      );
    } else if (segment.kind === "ellipse") {
      const rotation = (segment.rotation * Math.PI) / 180;
      const halfU = Math.hypot(
        segment.radiusX * Math.cos(rotation),
        segment.radiusY * Math.sin(rotation),
      );
      const halfV = Math.hypot(
        segment.radiusX * Math.sin(rotation),
        segment.radiusY * Math.cos(rotation),
      );
      include(segment.center[0] - halfU, segment.center[1] - halfV);
      include(segment.center[0] + halfU, segment.center[1] + halfV);
    } else if (segment.kind === "spline") {
      for (const point of segment.points) include(point[0], point[1]);
    } else {
      include(segment.start[0], segment.start[1]);
      include(segment.end[0], segment.end[1]);
    }
  }
  const center: readonly [number, number] = [
    (minU + maxU) / 2,
    (minV + maxV) / 2,
  ];
  return { halfU: (maxU - minU) / 2, halfV: (maxV - minV) / 2, center };
}
