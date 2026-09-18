import { z } from "zod";

import { fitCompensationSchema } from "./fit-compensation.js";
import { operationRefSchema, operationRefWireSchema } from "./refs.js";
import { sketchParametersSchemaWith } from "./sketch.js";

export const millimetersSchema = z
  .number()
  .finite()
  .positive()
  .max(1_000_000)
  .describe("A finite positive length in millimeters");

export const operationIdSchema = z.string().uuid().brand<"OperationId">();

export const bodyIdSchema = z.string().uuid().brand<"BodyId">();

/**
 * Identity of a planar profile produced by a profile operation. Profiles are
 * not bodies: they never appear in the evaluation response's `bodies` array,
 * produce no mesh packet, and exist in the kernel only for the evaluation
 * epoch that consumed them.
 */
export const profileIdSchema = z.string().uuid().brand<"ProfileId">();

export const point3Schema = z
  .tuple([z.number().finite(), z.number().finite(), z.number().finite()])
  .refine(
    (value) => value.every((component) => Math.abs(component) <= 10_000_000),
    {
      message: "Point components must be within the supported modeling extent",
    },
  );

/**
 * The outer bound on any body-local rebasing anchor and on a body's world
 * extent, in millimetres. A world coordinate is capped at 10_000_000 mm
 * (`point3Schema` above); a body's world-AABB centre (the AEMB2
 * `worldOriginMm` anchor) and its space diagonal both stay inside this looser
 * 1e8 mm envelope. MUST stay bit-identical to `kMaxModelExtentMm` in
 * `native/kernel-host/src/tessellate.cpp`: the kernel throws
 * "model extent exceeds export limit" past it, and `parseAembPacket` rejects a
 * `worldOriginMm` component beyond it — the two constants are one contract.
 */
export const maxModelExtentMm = 1e8;

export const direction3Schema = point3Schema.refine(
  ([x, y, zValue]) => Math.hypot(x, y, zValue) >= 1e-9,
  { message: "Direction must be non-zero" },
);

export const placementSchema = z
  .object({
    origin: point3Schema.default([0, 0, 0]),
    zDirection: direction3Schema.default([0, 0, 1]),
    xDirection: direction3Schema.default([1, 0, 0]),
  })
  .strict()
  .default({ origin: [0, 0, 0], zDirection: [0, 0, 1], xDirection: [1, 0, 0] });

export const operationMetadataSchema = z
  .object({
    createdAt: z.iso.datetime({ offset: true }),
    createdBy: z.discriminatedUnion("kind", [
      z.object({ kind: z.literal("user") }),
      z.object({
        kind: z.literal("agent"),
        runId: z.string().uuid(),
        toolCallId: z.string().min(1).max(256),
      }),
      z.object({
        kind: z.literal("import"),
        sourceName: z.string().min(1).max(512),
      }),
    ]),
    suppressed: z.boolean().optional(),
  })
  .strict();

export const createBoxOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("create_box"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        width: millimetersSchema,
        depth: millimetersSchema,
        height: millimetersSchema,
        placement: placementSchema,
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

export const createCylinderOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("create_cylinder"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        radius: millimetersSchema,
        height: millimetersSchema,
        placement: placementSchema,
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

export const createSphereOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("create_sphere"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        radius: millimetersSchema,
        placement: placementSchema,
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * A right-angular wedge: a box of `width`(x) × `depth`(y) × `height`(z) whose
 * top face (at height) is narrowed in x to `topWidth`, so one face slopes.
 * `topWidth` in [0, width]: 0 gives a triangular-prism knife edge, `width`
 * gives a plain box. The base's near corner sits at the placement origin.
 */
export const createWedgeOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("create_wedge"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        width: millimetersSchema,
        depth: millimetersSchema,
        height: millimetersSchema,
        topWidth: z.number().finite().min(0).max(1_000_000),
        placement: placementSchema,
      })
      .strict()
      .superRefine((parameters, context) => {
        if (parameters.topWidth > parameters.width) {
          context.addIssue({
            code: "custom",
            message: "topWidth must not exceed width",
            path: ["topWidth"],
          });
        }
      }),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * A cone or truncated cone (frustum): `radiusBottom` at the placement origin,
 * `radiusTop` at height `height` along the placement z direction. A zero
 * `radiusTop` produces a pointed cone; a positive one produces a frustum.
 * Base-center convention like the cylinder — the origin is the center of the
 * bottom circle.
 */
export const createConeOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("create_cone"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        radiusBottom: millimetersSchema,
        radiusTop: z.number().finite().min(0).max(1_000_000),
        height: millimetersSchema,
        placement: placementSchema,
      })
      .strict()
      .superRefine((parameters, context) => {
        const tolerance = 1e-9 * Math.max(1, Math.abs(parameters.radiusBottom));
        if (
          Math.abs(parameters.radiusTop - parameters.radiusBottom) <= tolerance
        ) {
          context.addIssue({
            code: "custom",
            message:
              "The top and bottom are the same size — use a cylinder for that. [E_PRIM_CONE_EQUAL_RADII]",
            path: ["radiusTop"],
            params: { primitiveCode: "E_PRIM_CONE_EQUAL_RADII" },
          });
        }
      }),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * A ring torus: a circle of radius `minorRadius` swept around an axis at
 * distance `majorRadius`, centered on the placement origin with the ring axis
 * along the placement z direction. `minorRadius` must be strictly less than
 * `majorRadius` (a ring torus that does not self-intersect through the axis).
 */
export const createTorusOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("create_torus"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        majorRadius: millimetersSchema,
        minorRadius: millimetersSchema,
        placement: placementSchema,
      })
      .strict()
      .superRefine((parameters, context) => {
        if (parameters.minorRadius >= parameters.majorRadius) {
          context.addIssue({
            code: "custom",
            message: "minorRadius must be strictly less than majorRadius",
            path: ["minorRadius"],
          });
        }
      }),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * Planar profile shapes, discriminated by `kind`. All profiles are centered
 * on the placement origin and live in the placement's XY plane: `width`
 * spans the placement x direction, `depth` spans the placement y direction,
 * and the profile normal is the placement z direction.
 */
export const rectangleProfileShapeSchema = z
  .object({
    kind: z.literal("rectangle"),
    width: millimetersSchema,
    depth: millimetersSchema,
  })
  .strict();

export const circleProfileShapeSchema = z
  .object({
    kind: z.literal("circle"),
    radius: millimetersSchema,
  })
  .strict();

/**
 * A rectangle whose four corners are replaced by quarter-circle arcs. The
 * corner radius is strictly below min(width, depth) / 2: at exactly half the
 * short side the straight segments degenerate to zero length (a slot/stadium,
 * which is a distinct future profile kind), and beyond it the contour
 * self-intersects.
 */
export const roundedRectangleProfileShapeSchema = z
  .object({
    kind: z.literal("roundedRectangle"),
    width: millimetersSchema,
    depth: millimetersSchema,
    cornerRadius: millimetersSchema,
  })
  .strict()
  .superRefine((shape, context) => {
    if (shape.cornerRadius >= Math.min(shape.width, shape.depth) / 2) {
      context.addIssue({
        code: "custom",
        message:
          "cornerRadius must be strictly less than min(width, depth) / 2",
        path: ["cornerRadius"],
      });
    }
  });

/**
 * A stadium/slot: a straight run capped by a semicircle of radius `width`/2 at
 * each short end, `length` spanning the placement x direction and `width` the
 * y direction. `length` must strictly exceed `width`; at length === width the
 * straight run vanishes and the shape degenerates to a circle.
 */
export const slotProfileShapeSchema = z
  .object({
    kind: z.literal("slot"),
    length: millimetersSchema,
    width: millimetersSchema,
  })
  .strict()
  .superRefine((shape, context) => {
    if (shape.length <= shape.width) {
      context.addIssue({
        code: "custom",
        message: "slot length must be strictly greater than its width",
        path: ["length"],
      });
    }
  });

/**
 * A regular convex polygon with `sides` vertices spaced evenly on a circle of
 * radius `circumradius`, the first vertex on the placement +x axis and the
 * polygon centered on the placement origin in its XY plane.
 */
export const polygonProfileShapeSchema = z
  .object({
    kind: z.literal("polygon"),
    sides: z.number().int().min(3).max(64),
    circumradius: millimetersSchema,
  })
  .strict();

/**
 * An ellipse with semi-axis `radiusX` along the placement x direction and
 * `radiusY` along y, centered on the placement origin. Equal radii give a
 * circle.
 */
export const ellipseProfileShapeSchema = z
  .object({
    kind: z.literal("ellipse"),
    radiusX: millimetersSchema,
    radiusY: millimetersSchema,
  })
  .strict();

export const profileShapeSchema = z.discriminatedUnion("kind", [
  rectangleProfileShapeSchema,
  circleProfileShapeSchema,
  roundedRectangleProfileShapeSchema,
  slotProfileShapeSchema,
  polygonProfileShapeSchema,
  ellipseProfileShapeSchema,
]);

/**
 * A planar profile on a placement plane. Produces no body: the operation's
 * output is the branded `outputProfileId`, consumed by feature-creation
 * operations (extrude first) that reference this operation by its id. A
 * profile no operation consumes is valid and simply evaluates to nothing.
 */
export const createProfileOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("create_profile"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputProfileId: profileIdSchema,
    parameters: z
      .object({
        shape: profileShapeSchema,
        placement: placementSchema,
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * Extrudes an earlier planar profile operation into a solid body.
 *
 * `profileOperationId` is an OPERATION-level reference (ADR-003): it names
 * the profile operation's document id, never epoch-local topology. The
 * document-model dependency registry declares it, so deleting a consumed
 * profile is refused at the transaction seam, and the kernel fails an
 * unresolvable reference with REFERENCE_MISSING carrying this operation's id.
 * v1 extrudes along the profile plane's normal only.
 */
export const extrudeOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("extrude"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        profileOperationId: operationIdSchema,
        distance: millimetersSchema,
        direction: z.literal("normal"),
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * Revolves an earlier planar profile operation around an axis into a solid body.
 *
 * `profileOperationId` is an OPERATION-level reference (ADR-003), exactly like
 * `extrude`: it names the profile operation's document id, never epoch-local
 * topology, and the document dependency registry declares it so deleting a
 * consumed profile is refused at the transaction seam. Like extrude and unlike
 * a boolean, revolve does NOT consume the profile — several features may
 * reference one profile within an evaluation.
 *
 * The revolution axis is the world-space line through `axisOrigin` along
 * `axisDirection`; `angleDegrees` sweeps the profile from 0 to that angle about
 * the axis, a full 360 producing a closed solid of revolution. A valid revolve
 * needs the axis to lie clear of the profile interior: an axis that crosses the
 * profile yields a self-intersecting body, which the kernel refuses with
 * GEOMETRY_FAILED rather than emitting invalid geometry. v1 revolves a single
 * closed profile only; multi-contour and thin-wall revolves are future work.
 */
export const revolveOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("revolve"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        profileOperationId: operationIdSchema,
        /** Literal legacy axis, retained for existing documents. */
        axisOrigin: point3Schema.optional(),
        axisDirection: direction3Schema.optional(),
        /** Associative axis derived from the consumed profile's current frame. */
        profileAxis: z.enum(["left", "right", "bottom", "top"]).optional(),
        angleDegrees: z.number().finite().gt(0).max(360),
      })
      .superRefine((parameters, context) => {
        const hasOrigin = parameters.axisOrigin !== undefined;
        const hasDirection = parameters.axisDirection !== undefined;
        const hasLiteralAxis = hasOrigin && hasDirection;
        const hasProfileAxis = parameters.profileAxis !== undefined;
        if (hasLiteralAxis === hasProfileAxis) {
          context.addIssue({
            code: "custom",
            message:
              "A revolve needs exactly one literal axis or profile-relative axis.",
            path: ["axisOrigin"],
          });
        }
        if (hasOrigin !== hasDirection) {
          context.addIssue({
            code: "custom",
            message: "axisOrigin and axisDirection must be supplied together.",
            path: ["axisOrigin"],
          });
        }
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * Lofts a solid body through two or more earlier planar profile operations,
 * blending each cross-section into the next in the given order.
 *
 * `profileOperationIds` are OPERATION-level references (ADR-003), each naming a
 * profile operation's document id — never epoch-local topology — in the order
 * the sections are threaded. Order is significant: sections blend from the
 * first to the last. Like extrude and revolve, loft READS its profiles (it does
 * not consume them); the document dependency registry declares every reference
 * so deleting any consumed profile is refused at the transaction seam. The
 * profiles must be positioned at distinct planes (typically parallel, at
 * different placement origins) for a valid solid; coincident or self-
 * intersecting section arrangements are refused with GEOMETRY_FAILED rather
 * than emitting invalid geometry.
 *
 * `ruled` selects straight (ruled) blending between adjacent sections; the
 * default is a smooth blend. v1 lofts single closed profiles only (no guide
 * curves, no multi-contour sections).
 */
export const loftOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("loft"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        profileOperationIds: z.array(operationIdSchema).min(2).max(64),
        ruled: z.boolean().default(false),
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * Sweeps an earlier planar profile along a polyline path (spine) into a solid.
 *
 * `profileOperationId` is an OPERATION-level reference (ADR-003) like extrude's:
 * the profile is READ (not consumed) as the swept cross-section. `path` is the
 * spine as an ordered list of >=2 world-space points joined by straight
 * segments; the profile is kept perpendicular to the spine as it sweeps, so the
 * section should sit at the spine's first point. A straight two-point path
 * produces a prism of the section along the path (a directional extrude); a
 * multi-point path bends the sweep, mitering at the corners. A path too tightly
 * curved for the section self-intersects and is refused with GEOMETRY_FAILED
 * rather than emitting invalid geometry. v1 is a straight-segment polyline;
 * arc/spline spines and reusable path entities are future work.
 *
 * A face sketch has no safe renderer-side world frame. For that case the
 * associative `profilePath` form carries a profile-normal spine and its length;
 * the native evaluator derives the actual world points from the current sketch
 * frame on every replay. Literal `path` remains the wire format for authored
 * world-space spines and agent submissions.
 */
export const sweepOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("sweep"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        profileOperationId: operationIdSchema,
        path: z.array(point3Schema).min(2).max(256).optional(),
        profilePath: z
          .object({
            kind: z.literal("normal"),
            lengthMm: millimetersSchema,
          })
          .strict()
          .optional(),
      })
      .superRefine((parameters, context) => {
        const hasLiteralPath = parameters.path !== undefined;
        const hasProfilePath = parameters.profilePath !== undefined;
        if (hasLiteralPath === hasProfilePath) {
          context.addIssue({
            code: "custom",
            message:
              "A sweep needs exactly one literal path or profile-relative path.",
            path: ["path"],
          });
        }
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

export const booleanKindSchema = z.enum(["union", "cut", "intersect"]);

/**
 * Combines two earlier solid bodies into one: `union` merges target and tool,
 * `cut` subtracts the tool from the target, `intersect` keeps only their
 * overlap.
 *
 * `targetOperationId` and `toolOperationId` are OPERATION-level references
 * (ADR-003): each names the document id of a BODY-PRODUCING operation
 * evaluated EARLIER in the document — never epoch-local topology and never a
 * profile. The boolean CONSUMES both referenced bodies. This is the body
 * management contract: the consumed bodies leave the evaluation result (no
 * bodies entry, no probes, no mesh packet) and only the boolean's
 * `outputBodyId` body appears in their place, at the boolean's position in
 * document order. Consumed is consumed — a later operation that references an
 * already-consumed operation id fails with REFERENCE_MISSING carrying the
 * consuming operation's id; there is no DAG reuse of a consumed body. The
 * dependency registry declares both references, so deleting a consumed
 * operation is refused at the transaction seam while the boolean exists.
 * Target and tool must be distinct: a body cannot be combined with itself.
 */
export const booleanCombineOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("boolean_combine"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        kind: booleanKindSchema,
        targetOperationId: operationIdSchema,
        toolOperationId: operationIdSchema,
      })
      .strict()
      .superRefine((parameters, context) => {
        if (parameters.targetOperationId === parameters.toolOperationId) {
          context.addIssue({
            code: "custom",
            message:
              "targetOperationId and toolOperationId must reference distinct operations",
            path: ["toolOperationId"],
          });
        }
      }),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * The bore size for a hole feature, given as either a radius or a diameter in
 * millimeters. Exactly one form is accepted per instance (discriminated by
 * `kind`); the kernel resolves either to the tool cylinder's radius.
 */
export const holeSizeSchema = z.discriminatedUnion("kind", [
  z.object({ kind: z.literal("radius"), radius: millimetersSchema }).strict(),
  z
    .object({ kind: z.literal("diameter"), diameter: millimetersSchema })
    .strict(),
]);

/**
 * A hole's placement: `origin` is the center point where the hole begins
 * (the entry point on the target body) and `zDirection` is the drilling
 * axis — defaulting straight down (-Z), the common case of a hole cut from a
 * body's top face, unlike the general `placementSchema` default of +Z used
 * by shape-creating primitives. `xDirection` participates only to keep the
 * same orthonormal-frame contract every placement carries; a cylindrical
 * tool has no dependence on it.
 */
export const holePlacementSchema = z
  .object({
    origin: point3Schema.default([0, 0, 0]),
    zDirection: direction3Schema.default([0, 0, -1]),
    xDirection: direction3Schema.default([1, 0, 0]),
  })
  .strict()
  .default({
    origin: [0, 0, 0],
    zDirection: [0, 0, -1],
    xDirection: [1, 0, 0],
  });

/**
 * A parametric, positional cylindrical hole cut into an earlier solid body
 * (Tranche B item 4, first pass — POSITIONAL only). Unlike `boolean_combine`,
 * the tool is not itself an earlier operation: the kernel synthesizes a
 * cylinder from `size` / `depth` / `placement` and cuts it from the target.
 * v1 intentionally excludes face-placed holes (NG-2 topology selectors do not
 * exist yet); `placement.origin` is a raw world coordinate the caller
 * supplies, never a reference to a target face.
 *
 * `targetOperationId` is an OPERATION-level reference (ADR-003), exactly like
 * `boolean_combine.parameters.targetOperationId`: it names an earlier
 * BODY-PRODUCING operation, and the hole CONSUMES it — the target leaves the
 * evaluation result entirely (no bodies entry, no probes, no mesh packet) and
 * only the hole's `outputBodyId` body appears in its place, at the hole's
 * position in document order. The same REFERENCE_MISSING taxonomy as
 * boolean_combine's target applies: missing, non-body, forward, and
 * already-consumed references are all the same failure, attributed to this
 * operation's id.
 *
 * Depth contract: exactly one of `depth` (a blind hole, cut to that exact
 * distance along the drilling axis from `placement.origin`) or `throughAll`
 * (the kernel computes a depth from the target's own extent, guaranteed to
 * fully pierce it) applies — never both, never neither.
 */
export const holeOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("hole"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        targetOperationId: operationIdSchema,
        placement: holePlacementSchema,
        size: holeSizeSchema,
        depth: millimetersSchema.optional(),
        throughAll: z.boolean().default(false),
      })
      .strict()
      .superRefine((parameters, context) => {
        if (parameters.throughAll && parameters.depth !== undefined) {
          context.addIssue({
            code: "custom",
            message: "depth must be omitted when throughAll is set",
            path: ["depth"],
          });
        }
        if (!parameters.throughAll && parameters.depth === undefined) {
          context.addIssue({
            code: "custom",
            message: "depth is required unless throughAll is set",
            path: ["depth"],
          });
        }
      }),
    metadata: operationMetadataSchema,
  })
  .strict();

/* --- fastener-after-snap (MASTER_PLAN §9) — STAGED (no native executor yet) --- */

/**
 * The metric fastener sizes a `bolt` supports — the sizes the ISO 4762
 * head/counterbore table covers (`@aeth/parts-library` §3). The kernel resolves
 * the actual clearance-hole / head dimensions from these semantic sizes via the
 * hardware tables at execution time; the operation stores the size, never the
 * raw millimeters, so a fit-table correction re-parametrizes every bolt.
 */
export const boltSizeSchema = z.enum([
  "M2",
  "M2.5",
  "M3",
  "M4",
  "M5",
  "M6",
  "M8",
]);

/** ISO 273 clearance-hole fit class (`@aeth/parts-library` §1). */
export const boltFitSchema = z.enum(["close", "medium", "free"]);

/** The head seat cut into the near face so the screw head sits flush/below. */
export const boltHeadSchema = z.enum(["none", "counterbore", "countersink"]);

/**
 * A **bolt**: a fastener-grade clearance hole (optionally with a counterbore or
 * countersink head seat) cut into an earlier solid body — the fastener-after-snap
 * "bolt" choice (MASTER_PLAN §9). It consumes `targetOperationId` exactly like
 * `hole` (positional, world-coordinate `placement`; NG-2 face selectors do not
 * exist yet), and the target leaves the evaluation result, replaced by this
 * operation's `outputBodyId`.
 *
 * The clearance diameter and head geometry are NOT stored as raw millimeters:
 * they derive from `size`/`fit`/`head` through the `@aeth/parts-library` tables
 * (ISO 273 clearance + §6.3 print compensation; ISO 4762 counterbore/countersink)
 * at execution time. STAGED: no native executor yet, so `evaluate_document`
 * refuses it with an attributed `UNSUPPORTED_OPERATION`, and it is kept off the
 * agent wire until the executor lands (the catalog-wave1 precedent).
 */
export const boltOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("bolt"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        targetOperationId: operationIdSchema,
        placement: holePlacementSchema,
        size: boltSizeSchema,
        fit: boltFitSchema.default("medium"),
        head: boltHeadSchema.default("none"),
        depth: millimetersSchema.optional(),
        throughAll: z.boolean().default(false),
        /**
         * The printed-fit allowance this bolt was authored with (CAP-021).
         *
         * OPTIONAL WITH NO DEFAULT, deliberately: a bolt authored before this
         * field carries no record, and its absence changes no canonical bytes —
         * so `.aeth` documents round-trip unchanged and the pinned
         * cross-language op-hash golden vector is untouched. Because it lives in
         * `parameters` it is inside the RFC 8785 JSON the op-hash already
         * covers, so a different allowance is a different hash and the native
         * replay cache re-keys itself with no hasher, `excludedKeys` or C++
         * mirror change. See docs/design/2026-07-28-fit-compensation-seam.md
         * for why the allowance is STORED rather than read live from the active
         * printer profile at evaluation time.
         */
        compensation: fitCompensationSchema.optional(),
      })
      .strict()
      .superRefine((parameters, context) => {
        if (parameters.throughAll && parameters.depth !== undefined) {
          context.addIssue({
            code: "custom",
            message: "depth must be omitted when throughAll is set",
            path: ["depth"],
          });
        }
        if (!parameters.throughAll && parameters.depth === undefined) {
          context.addIssue({
            code: "custom",
            message: "depth is required unless throughAll is set",
            path: ["depth"],
          });
        }
      }),
    metadata: operationMetadataSchema,
  })
  .strict();

/** The filament class a `clasp`'s snap-fit strain rules key on (§8). */
export const claspMaterialSchema = z.enum([
  "PLA",
  "PETG",
  "ABS",
  "TPU",
  "unknown",
]);

/** Whether a clasp is meant to re-open (releasable) or hold for good (permanent). */
export const claspRetentionSchema = z.enum(["releasable", "permanent"]);

/**
 * A **clasp**: a cantilever snap-fit hook feature added to an earlier solid body
 * — the fastener-after-snap "clasp" choice (MASTER_PLAN §9). It consumes
 * `targetOperationId` and mounts at a positional `placement`; the beam is sized
 * by the caller (root thickness / length / width) and its allowable deflection +
 * retention geometry derive from the `@aeth/parts-library` §8 strain rules for
 * `material` at execution time.
 *
 * v1 models the hook as a single-output feature on the host (one `outputBodyId`),
 * within the one-op/one-body birth contract; the matching catch on the mating
 * body is a follow-up gated on the multi-output-birth decision (ADR-013). It has
 * no native executor: like `bolt`, it LOWERS to a primitive subgraph (a beam box
 * + hook wedge unioned onto the host) at the evaluation boundary
 * (`@aeth/document-model` `lowerFastenerOperations`), so the kernel executes only
 * the primitives it already knows. A raw `clasp` reaching the kernel fails closed.
 */
export const claspOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("clasp"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        targetOperationId: operationIdSchema,
        placement: holePlacementSchema,
        material: claspMaterialSchema,
        beamThicknessMm: millimetersSchema,
        beamLengthMm: millimetersSchema,
        beamWidthMm: millimetersSchema,
        retention: claspRetentionSchema.default("releasable"),
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * A rigid or uniform-scale transformation applied to a body, discriminated by
 * `kind`: `translate` by an offset vector, `rotate` by an angle (degrees) about
 * a world-space axis line, `scale` uniformly about the world origin, or `mirror`
 * across the plane through `planeOrigin` with normal `planeNormal` (a chirality
 * flip — the left-hand version of a part).
 */
export const bodyTransformSchema = z.discriminatedUnion("kind", [
  z.object({ kind: z.literal("translate"), offset: point3Schema }).strict(),
  z
    .object({
      kind: z.literal("rotate"),
      axisOrigin: point3Schema,
      axisDirection: direction3Schema,
      angleDegrees: z.number().finite(),
    })
    .strict(),
  z
    .object({
      kind: z.literal("scale"),
      factor: z.number().finite().gt(0).max(10_000),
    })
    .strict(),
  z
    .object({
      kind: z.literal("mirror"),
      planeOrigin: point3Schema,
      planeNormal: direction3Schema,
    })
    .strict(),
]);

/**
 * Transforms an earlier solid body — translate, rotate, or uniformly scale it.
 *
 * `targetOperationId` is an OPERATION-level reference (ADR-003) to an earlier
 * BODY-PRODUCING operation, and the transform CONSUMES it exactly like
 * boolean_combine and hole consume their targets: the original body leaves the
 * evaluation result and only the transformed `outputBodyId` body appears in its
 * place, at the transform's position in document order. This is move/rotate/
 * scale semantics, not copy — a pattern that keeps the original is future work.
 * The same REFERENCE_MISSING taxonomy applies (missing, non-body, forward, or
 * already-consumed references are all the same failure, attributed here).
 */
export const transformOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("transform"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        targetOperationId: operationIdSchema,
        transform: bodyTransformSchema,
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * Offsets an earlier solid body's whole surface by `distance` — a positive
 * distance grows the body outward, a negative one insets it. Convex edges are
 * rounded (arc join). Like boolean_combine and hole, offset CONSUMES its target
 * (the grown/inset body replaces it at document order) and shares the same
 * REFERENCE_MISSING taxonomy. An inset larger than the body's own thickness
 * collapses it; that is refused with GEOMETRY_FAILED rather than emitting
 * degenerate geometry.
 *
 * v1 is the WHOLE-BODY offset. ADR-014 supersedes it as the operation's future
 * without removing it: `offset` now means LOCAL FACE OFFSET (v2, below), and an
 * absent `face` slot keeps evaluating v1 bit-for-bit — the absent-slot-is-v1
 * invariant `fillet` and `chamfer` established.
 */
export const offsetOperationV1Schema = z
  .object({
    id: operationIdSchema,
    type: z.literal("offset"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        targetOperationId: operationIdSchema,
        distance: z
          .number()
          .finite()
          .refine(
            (value) => Math.abs(value) >= 1e-6 && Math.abs(value) <= 1_000_000,
            {
              message:
                "offset distance must be non-zero and within the modeling extent",
            },
          ),
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * v2 — LOCAL FACE OFFSET (ADR-014, plan-04 `### offset`). The optional `face`
 * slot names the ONE face whose underlying surface moves; its neighbours are
 * re-trimmed against the moved surface, keeping their own surfaces. Absent
 * `face` ⇒ v1 whole-body semantics, bit-for-bit.
 */
function offsetOperationV2SchemaWith(faceRef: RefSlotSchema) {
  return z
    .object({
      id: operationIdSchema,
      type: z.literal("offset"),
      schemaVersion: z.literal(2),
      name: z.string().trim().min(1).max(120),
      outputBodyId: bodyIdSchema,
      parameters: z
        .object({
          targetOperationId: operationIdSchema,
          distance: z
            .number()
            .finite()
            .refine(
              (value) =>
                Math.abs(value) >= 1e-6 && Math.abs(value) <= 1_000_000,
              {
                message:
                  "offset distance must be non-zero and within the modeling extent",
              },
            ),
          /**
           * The face to move, as the persisted AQL query whose parsed AST the
           * kernel resolves. Arity `one`: a local face offset moves exactly one
           * face, and an empty or ambiguous match REFUSES rather than guessing.
           */
          face: faceRef.optional(),
        })
        .strict(),
      metadata: operationMetadataSchema,
    })
    .strict();
}

export const offsetOperationV2Schema =
  offsetOperationV2SchemaWith(operationRefSchema);

export const offsetOperationSchema = z.discriminatedUnion("schemaVersion", [
  offsetOperationV1Schema,
  offsetOperationV2Schema,
]);

/**
 * Rounds edges of an earlier solid body with a constant-radius fillet.
 *
 * The fillet operation is versioned by `schemaVersion`, a nested discriminated
 * union that the outer `operationSchema` routes to once it has matched
 * `type: "fillet"`:
 *
 * - **schemaVersion 1** rounds EVERY edge of the target by `radius`. This is
 *   byte-identical to the original single-version fillet schema, so every
 *   persisted v1 fillet loads unchanged (migration-neutral).
 * - **schemaVersion 2** adds an optional `edges` topology-reference slot (an
 *   AQL query string plus recorded anchors, plan 01 §7.1 / ADR-006). When
 *   `edges` is present the fillet rounds only the resolved edge set; when it is
 *   ABSENT v2 behaves exactly like v1 (all edges), so a v1 fillet upgrades to
 *   v2 by version bump alone with no parameter change.
 *
 * The persisted `edges.query` is an AQL STRING; the kernel never sees that
 * string (plan 05 §4.2). Document-model parses, kind-checks (must resolve to
 * `edge` head kind, not faces), and rootedness-checks the query at op
 * acceptance, then ships the parsed AST across the kernel-host boundary as
 * `operationRefWireSchema` (refs.ts). Edge-scoped resolution is the executor's
 * job (tranche N5).
 *
 * Like boolean_combine and hole, fillet CONSUMES its target (the rounded body
 * replaces it) and shares the REFERENCE_MISSING taxonomy. A radius too large
 * for an edge's neighborhood (adjacent faces too small, or opposite fillets
 * overlapping) is refused with GEOMETRY_FAILED rather than emitting an invalid
 * body.
 */
export const filletOperationV1Schema = z
  .object({
    id: operationIdSchema,
    type: z.literal("fillet"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        targetOperationId: operationIdSchema,
        radius: millimetersSchema,
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * A ref-slot schema — either the persisted {@link operationRefSchema} (`{query}`,
 * on-disk) or the kernel-wire {@link operationRefWireSchema} (`{ast}`, transport)
 * presented under the same compile-time type. Every operation type that carries
 * topology-reference slots is built by a `…SchemaWith(ref)` factory taking this,
 * so its persisted and wire schemas share ONE definition and can never drift in
 * their non-ref parameters (the same single-source-of-truth invariant
 * `presentOperationRefSlots` enforces for the slot set). `operationSchema` passes
 * the persisted ref; {@link wireOperationSchema} passes the wire ref.
 */
type RefSlotSchema = typeof operationRefSchema;

function filletOperationV2SchemaWith(edgesRef: RefSlotSchema) {
  return z
    .object({
      id: operationIdSchema,
      type: z.literal("fillet"),
      schemaVersion: z.literal(2),
      name: z.string().trim().min(1).max(120),
      outputBodyId: bodyIdSchema,
      parameters: z
        .object({
          targetOperationId: operationIdSchema,
          radius: millimetersSchema,
          /**
           * Optional edge selector. Absent ⇒ all edges (v1 behavior). Present ⇒
           * the persisted AQL query + anchors whose parsed AST the kernel
           * resolves to the edge set this fillet rounds. Validated at op
           * acceptance (parse + `edge`-kind + rootedness) by @aeth/document-model.
           */
          edges: edgesRef.optional(),
        })
        .strict(),
      metadata: operationMetadataSchema,
    })
    .strict();
}

export const filletOperationV2Schema =
  filletOperationV2SchemaWith(operationRefSchema);

export const filletOperationSchema = z.discriminatedUnion("schemaVersion", [
  filletOperationV1Schema,
  filletOperationV2Schema,
]);

/**
 * Bevels edges of an earlier solid body with a constant-distance chamfer. v1
 * bevels EVERY edge by `distance` — edge-scoped chamfering awaits NG-2 topology
 * selectors. CONSUMES its target like fillet, same REFERENCE_MISSING taxonomy.
 * A distance too large for an edge's neighborhood is refused with
 * GEOMETRY_FAILED rather than emitting an invalid body.
 */
export const chamferOperationV1Schema = z
  .object({
    id: operationIdSchema,
    type: z.literal("chamfer"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        targetOperationId: operationIdSchema,
        distance: millimetersSchema,
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

function chamferOperationV2SchemaWith(edgesRef: RefSlotSchema) {
  return z
    .object({
      id: operationIdSchema,
      type: z.literal("chamfer"),
      schemaVersion: z.literal(2),
      name: z.string().trim().min(1).max(120),
      outputBodyId: bodyIdSchema,
      parameters: z
        .object({
          targetOperationId: operationIdSchema,
          distance: millimetersSchema,
          /**
           * Optional edge selector, the fillet-v2 twin. Absent ⇒ every edge (v1
           * behavior, bit-for-bit). Present ⇒ the persisted AQL query whose
           * parsed AST the kernel resolves to the edge set this chamfer bevels.
           * Validated at op acceptance (parse + `edge`-kind + rootedness) by
           * @aeth/document-model.
           */
          edges: edgesRef.optional(),
        })
        .strict(),
      metadata: operationMetadataSchema,
    })
    .strict();
}

export const chamferOperationV2Schema =
  chamferOperationV2SchemaWith(operationRefSchema);

export const chamferOperationSchema = z.discriminatedUnion("schemaVersion", [
  chamferOperationV1Schema,
  chamferOperationV2Schema,
]);

/* --- catalog-ts-contracts: datum / shell / pattern / mirror (wave 1) -------
 *
 * TS contracts landed AHEAD of native execution (the fillet-v2 staging
 * pattern; docs/design/2026-07-19-catalog-ts-contracts.md). Adding these
 * types to the union makes them "known", so Gate 9 no longer shields them:
 * until the native catalog wave lands, the kernel dispatch refuses each with
 * an ATTRIBUTED `UNSUPPORTED_OPERATION` (geometry.cpp's fail-closed final
 * `else`), pinned by kernel-client's catalog-wave1 native suite. Plan specs
 * (semantically normative): 02 §3 `datum-plane`/`datum-axis`, doc 04 `shell`/
 * `mirror`/`pattern-linear`/`pattern-circular`, adapted to the shipped flat
 * envelope (recorded divergence, audit §4.B).
 */

/**
 * A signed datum-plane offset in millimeters. Unlike {@link millimetersSchema}
 * (strictly positive), an offset may be negative (below the base plane) or
 * zero (coincident with it); magnitude is capped at the 02 §3 `datum-plane`
 * bound (`E_PRIM_DIM_TOO_LARGE` past 1e7), matching the `point3Schema` extent.
 */
const signedDatumOffsetSchema = z
  .number()
  .finite()
  .min(-10_000_000)
  .max(10_000_000)
  .describe("A finite signed offset in millimeters within the modeling extent");

/**
 * A datum-plane rotation in degrees. The plan requires only "finite"; the
 * schema binds it to one full turn either way (a rotation past ±360° is the
 * same plane as its principal angle, so nothing expressible is lost) — a
 * doc-model bound recorded in the wave-1 design note.
 */
const datumRotationDegreesSchema = z.number().finite().min(-360).max(360);

/**
 * A pattern instance count along one direction: an evaluated integer within
 * the instance budget. The plan sets no upper bound; the schema binds the
 * n-ary boolean budget the way the byte envelope binds document size
 * (design-note §2.5, recorded).
 */
export const maxPatternInstances = 1024;

const patternCountSchema = z.number().int().min(1).max(maxPatternInstances);

/**
 * A signed pattern step in millimeters: non-zero (a zero step stacks every
 * instance in place) and within the modeling magnitude envelope, the same
 * bounds the whole-body `offset` distance uses.
 */
const patternSpacingSchema = z
  .number()
  .finite()
  .refine((value) => Math.abs(value) >= 1e-6 && Math.abs(value) <= 1_000_000, {
    message: "pattern spacing must be non-zero and within the modeling extent",
  });

/** sin(1°) — the doc 04 degenerate-axes threshold, precomputed. */
const sinOneDegree = Math.sin(Math.PI / 180);

/**
 * Whether two pattern directions are within 1° of COLINEAR (parallel or
 * anti-parallel). Sign-insensitive on purpose: an anti-parallel second
 * direction collapses the grid onto one line exactly like a parallel one
 * (fail-closed strengthening of doc 04 rule 2, recorded in the design note).
 */
function directionsNearlyColinear(
  a: readonly [number, number, number],
  b: readonly [number, number, number],
): boolean {
  const [ax, ay, az] = a;
  const [bx, by, bz] = b;
  const cross: readonly [number, number, number] = [
    ay * bz - az * by,
    az * bx - ax * bz,
    ax * by - ay * bx,
  ];
  const sine =
    Math.hypot(...cross) / (Math.hypot(ax, ay, az) * Math.hypot(bx, by, bz));
  return sine < sinOneDegree;
}

/**
 * A construction plane for sketching, mirroring, and angled datums where no
 * suitable face exists (02 §3 `datum-plane`). Produces NO body and carries no
 * output id: its sole product is the synthetic infinite-plane entity
 * `t:<opId>/plane/0` minted from this operation's own id (02 §2.3) — like
 * `create_profile`, it never appears in the evaluation response's bodies.
 *
 * `parameters` is a `mode` discriminated union, so params and ref slots not
 * applicable to the chosen mode are structurally absent (the plan's
 * `E_DOC_MISSING_REF_SLOT`/`E_DOC_UNKNOWN_REF_SLOT` acceptance rules, made
 * unrepresentable):
 *
 * - `offset`: the plane parallel to `base`, `offset` mm along its normal.
 * - `angled`: `base` rotated by `angle` degrees about `axis` (right-hand rule
 *   about the canonicalized axis direction, 02 §2.5); the axis must lie on the
 *   base plane (resolve-time `E_DATUM_INVALID_REFERENCE`).
 * - `midplane`: halfway between parallel planar faces `a` and `b`.
 *
 * Ref slots are persisted `operationRefSchema` envelopes; `base`/`a`/`b`
 * expect `faces(...)` queries (planar faces, datum planes, and world planes
 * all resolve under the `faces` head — `faces(world(xy))`, 05 §4.1), `axis`
 * expects `edges(...)` (linear edges, datum axes, world axes). Kind and
 * rootedness are checked at op acceptance by @aeth/document-model; planarity
 * and axis-on-plane are the executor's resolve-time checks (native wave).
 */
function datumPlaneOperationSchemaWith(ref: RefSlotSchema) {
  return z
    .object({
      id: operationIdSchema,
      type: z.literal("datum_plane"),
      schemaVersion: z.literal(1),
      name: z.string().trim().min(1).max(120),
      parameters: z.discriminatedUnion("mode", [
        z
          .object({
            mode: z.literal("offset"),
            offset: signedDatumOffsetSchema,
            base: ref,
          })
          .strict(),
        z
          .object({
            mode: z.literal("angled"),
            angle: datumRotationDegreesSchema,
            base: ref,
            axis: ref,
          })
          .strict(),
        z
          .object({
            mode: z.literal("midplane"),
            a: ref,
            b: ref,
          })
          .strict(),
      ]),
      metadata: operationMetadataSchema,
    })
    .strict();
}

export const datumPlaneOperationSchema =
  datumPlaneOperationSchemaWith(operationRefSchema);

/**
 * A construction axis for revolves, circular patterns, and angled datum
 * planes (02 §3 `datum-axis`). Like `datum_plane` it produces NO body and no
 * output id; it mints the synthetic infinite-line entity `t:<opId>/axis/0`.
 *
 * - `twoPoints`: through vertices `a` → `b` (user intent fixes the sense — no
 *   02 §2.5 canonicalization flip); coincident points are the executor's
 *   resolve-time `E_DATUM_INVALID_REFERENCE`.
 * - `faceNormal`: the planar `face`'s outward normal through `position`
 *   projected onto the face plane (any distance is legal — the axis is
 *   infinite).
 * - `cylinderAxis`: the rotation axis of a cylindrical/conical/toroidal
 *   `face`, direction canonicalized (02 §2.5).
 *
 * `a`/`b` expect `vertices(...)` queries; `face` expects `faces(...)`.
 */
function datumAxisOperationSchemaWith(ref: RefSlotSchema) {
  return z
    .object({
      id: operationIdSchema,
      type: z.literal("datum_axis"),
      schemaVersion: z.literal(1),
      name: z.string().trim().min(1).max(120),
      parameters: z.discriminatedUnion("mode", [
        z
          .object({
            mode: z.literal("twoPoints"),
            a: ref,
            b: ref,
          })
          .strict(),
        z
          .object({
            mode: z.literal("faceNormal"),
            position: point3Schema,
            face: ref,
          })
          .strict(),
        z
          .object({
            mode: z.literal("cylinderAxis"),
            face: ref,
          })
          .strict(),
      ]),
      metadata: operationMetadataSchema,
    })
    .strict();
}

export const datumAxisOperationSchema =
  datumAxisOperationSchemaWith(operationRefSchema);

/**
 * Hollows an earlier solid body to a uniform wall thickness, optionally
 * removing faces to create openings (doc 04 `shell`).
 *
 * `targetOperationId` is an OPERATION-level reference (ADR-003) to an earlier
 * BODY-PRODUCING operation; shell CONSUMES it exactly like fillet/chamfer
 * (the hollowed body replaces it at document order) and shares the
 * REFERENCE_MISSING taxonomy. `direction` chooses which side the wall grows:
 * `inward` keeps the outer size (walls grow into the original volume),
 * `outward` grows the body (the original surface becomes the cavity).
 *
 * `openFaces` is an optional persisted topology ref (`faces(...)` query, doc
 * 04 slot arity `any` / onEmpty `empty-ok` — the authored envelope carries
 * the per-ref policy): the resolved faces are removed to create openings.
 * ABSENT `openFaces` is the closed hollow shell with an internal void — legal
 * and printable; drainage concerns belong to preflight, never the kernel.
 * "Open faces lie on the target body", "not all faces removed", and body
 * kind checks are the executor's resolve-time validation (native wave).
 */
function shellOperationSchemaWith(openFacesRef: RefSlotSchema) {
  return z
    .object({
      id: operationIdSchema,
      type: z.literal("shell"),
      schemaVersion: z.literal(1),
      name: z.string().trim().min(1).max(120),
      outputBodyId: bodyIdSchema,
      parameters: z
        .object({
          targetOperationId: operationIdSchema,
          thickness: millimetersSchema,
          direction: z.enum(["inward", "outward"]).default("inward"),
          openFaces: openFacesRef.optional(),
        })
        .strict(),
      metadata: operationMetadataSchema,
    })
    .strict();
}

export const shellOperationSchema =
  shellOperationSchemaWith(operationRefSchema);

/**
 * Mirrors an earlier solid body across a plane, either as a new independent
 * body or fused with its source — the "model half a symmetric part, then
 * mirror-merge" workflow (doc 04 `mirror`).
 *
 * `sourceOperationId` is an OPERATION-level reference (ADR-003) to an earlier
 * BODY-PRODUCING operation. Consumption depends on `merge`:
 *
 * - `merge: false` (default) creates a NEW body from the mirrored copy while
 *   the source stays live — a READ, like extrude's profile reference, and the
 *   first body reference in the catalog that does not consume its body.
 * - `merge: true` fuses the mirrored copy into the source (internal n-ary
 *   fuse, doc 04) and CONSUMES it exactly like `transform`.
 *
 * Either way the source is a hard dependency: deleting it is refused while
 * the mirror exists. `plane` is a persisted topology ref under the `faces`
 * head — a planar face, a `datum_plane`, or a world plane
 * (`faces(world(yz))`, one of the slots that accepts world datums, 05 §4.1);
 * planarity is the executor's resolve-time `E_MIRROR_PLANE_INVALID`.
 *
 * Distinct from the `transform` operation's `mirror` transform kind, which
 * takes a raw plane by coordinates and always consumes: this op takes the
 * plane by reference and supports merge.
 */
function mirrorOperationSchemaWith(planeRef: RefSlotSchema) {
  return z
    .object({
      id: operationIdSchema,
      type: z.literal("mirror"),
      schemaVersion: z.literal(1),
      name: z.string().trim().min(1).max(120),
      outputBodyId: bodyIdSchema,
      parameters: z
        .object({
          sourceOperationId: operationIdSchema,
          plane: planeRef,
          merge: z.boolean().default(false),
        })
        .strict(),
      metadata: operationMetadataSchema,
    })
    .strict();
}

export const mirrorOperationSchema =
  mirrorOperationSchemaWith(operationRefSchema);

/**
 * How pattern instances combine into the single result body (doc 04, locked
 * v1 model: a pattern always yields exactly ONE body):
 *
 * - `fuseInstances` (default): one new body containing all instances
 *   (including the copy at the seed's original position); no target.
 * - `union` / `subtract`: all instances fused into / cut from
 *   `targetOperationId` in a single n-ary boolean; target required.
 */
export const patternCombineSchema = z.enum([
  "fuseInstances",
  "union",
  "subtract",
]);

/**
 * Shared `superRefine` for the pattern target rules (doc 04 validation rules
 * `E_PATTERN_TARGET_REQUIRED` / `E_PATTERN_TARGET_FORBIDDEN` and the static
 * half of `E_BOOL_SELF_TOOL`).
 */
function addPatternTargetIssues(
  parameters: {
    readonly seedOperationId: string;
    readonly targetOperationId?: string | undefined;
    readonly op: z.infer<typeof patternCombineSchema>;
  },
  context: z.RefinementCtx,
): void {
  if (parameters.op === "fuseInstances") {
    if (parameters.targetOperationId !== undefined) {
      context.addIssue({
        code: "custom",
        message: "targetOperationId is forbidden when op is fuseInstances",
        path: ["targetOperationId"],
      });
    }
    return;
  }
  if (parameters.targetOperationId === undefined) {
    context.addIssue({
      code: "custom",
      message: `targetOperationId is required when op is ${parameters.op}`,
      path: ["targetOperationId"],
    });
    return;
  }
  if (parameters.targetOperationId === parameters.seedOperationId) {
    context.addIssue({
      code: "custom",
      message:
        "targetOperationId must reference a different operation than seedOperationId",
      path: ["targetOperationId"],
    });
  }
}

/**
 * Repeats a seed body on a 1D or 2D grid (doc 04 `pattern-linear`). Instance
 * `(i, j)` is translated by `i·spacing·direction + j·spacing2·direction2`,
 * instance 0 being the unmoved copy; all instances combine in ONE n-ary
 * boolean per `op` (never a chain, and deliberately no `simplify` — doc 04's
 * per-instance ordinal model forbids unification).
 *
 * `seedOperationId` references the earlier BODY-PRODUCING seed operation;
 * the seed is consumed unless `consumeSeed: false` (the instancing escape
 * hatch — the still-live seed then coincides with instance 0 under
 * `fuseInstances`, intentionally). `targetOperationId` is required exactly
 * when `op` is `union`/`subtract` and must name a different operation than
 * the seed. `direction`/`direction2` are raw direction vectors — the schema
 * does not normalize (the kernel does); a second direction within 1° of
 * colinear with the first is refused (`E_PATTERN_DEGENERATE_AXES`,
 * sign-insensitive). The `count2 > 1` grid requires `spacing2` + `direction2`
 * and a 1D pattern forbids them, and `count·count2` is capped by
 * {@link maxPatternInstances} (doc-model instance budget, design-note §2.5).
 */
export const patternLinearOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("pattern_linear"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        seedOperationId: operationIdSchema,
        count: patternCountSchema,
        spacing: patternSpacingSchema,
        direction: direction3Schema,
        count2: patternCountSchema.default(1),
        spacing2: patternSpacingSchema.optional(),
        direction2: direction3Schema.optional(),
        op: patternCombineSchema.default("fuseInstances"),
        targetOperationId: operationIdSchema.optional(),
        consumeSeed: z.boolean().default(true),
      })
      .strict()
      .superRefine((parameters, context) => {
        addPatternTargetIssues(parameters, context);
        if (parameters.count * parameters.count2 > maxPatternInstances) {
          context.addIssue({
            code: "custom",
            message: `count * count2 must not exceed ${String(maxPatternInstances)} instances`,
            path: ["count2"],
          });
        }
        if (parameters.count2 > 1) {
          for (const key of ["spacing2", "direction2"] as const) {
            if (parameters[key] === undefined) {
              context.addIssue({
                code: "custom",
                message: `${key} is required when count2 is greater than 1`,
                path: [key],
              });
            }
          }
        } else {
          for (const key of ["spacing2", "direction2"] as const) {
            if (parameters[key] !== undefined) {
              context.addIssue({
                code: "custom",
                message: `${key} must be omitted for a one-directional pattern`,
                path: [key],
              });
            }
          }
        }
        if (
          parameters.direction2 !== undefined &&
          directionsNearlyColinear(parameters.direction, parameters.direction2)
        ) {
          context.addIssue({
            code: "custom",
            message:
              "direction2 must be at least 1 degree away from direction (and from its opposite)",
            path: ["direction2"],
          });
        }
      }),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * Repeats a seed body around an axis (doc 04 `pattern-circular`): the same
 * locked single-result-body model, `op`/`consumeSeed`/target semantics, and
 * single n-ary boolean as `pattern_linear`; only the placement differs.
 *
 * `axis` is a persisted topology ref under the `edges` head — a linear edge,
 * a `datum_axis`, or a world axis (`edges(world(z))`); linearity is the
 * executor's resolve-time `E_PATTERN_AXIS_INVALID`. `count` includes the
 * original position and must be at least 2. `totalAngle` is the pattern's
 * angular span in (0, 360]; the full-circle vs open-arc fencepost rule
 * (θ_k = k·total/count vs k·total/(count−1)) is the executor's, normatively
 * fixed in doc 04. `rotateInstances: false` is the translate-only orbit
 * (instances keep the seed's orientation).
 */
function patternCircularOperationSchemaWith(axisRef: RefSlotSchema) {
  return z
    .object({
      id: operationIdSchema,
      type: z.literal("pattern_circular"),
      schemaVersion: z.literal(1),
      name: z.string().trim().min(1).max(120),
      outputBodyId: bodyIdSchema,
      parameters: z
        .object({
          seedOperationId: operationIdSchema,
          axis: axisRef,
          count: z.number().int().min(2).max(maxPatternInstances),
          totalAngle: z.number().finite().gt(0).max(360).default(360),
          rotateInstances: z.boolean().default(true),
          op: patternCombineSchema.default("fuseInstances"),
          targetOperationId: operationIdSchema.optional(),
          consumeSeed: z.boolean().default(true),
        })
        .strict()
        .superRefine(addPatternTargetIssues),
      metadata: operationMetadataSchema,
    })
    .strict();
}

export const patternCircularOperationSchema =
  patternCircularOperationSchemaWith(operationRefSchema);

/* --- end catalog-ts-contracts wave 1 -------------------------------------- */

/**
 * The maximum length, in UTF-8 characters, of a STEP `import_step` operation's
 * inline `source` (MASTER_PLAN §1.4 Tranche E; defect D-019). An `import_step`
 * is a body-birth operation whose geometry is NOT synthesized from a handful of
 * numeric parameters but read back from a preserved ISO-10303-21 exchange
 * structure; per §2.1 the original imported source is retained, and the only
 * place a replayable operation can retain it is inside the operation itself, so
 * the whole Part-21 text rides in `parameters.source` (content-addressed by the
 * op-hash contract, exactly like every other parameter).
 *
 * This bound is DISTINCT from — and much smaller than — the 64 MiB
 * `maxStepImportBytes` cap the desktop main process applies while STRUCTURALLY
 * validating a hostile file (defect D-012, non-materializing entity counting):
 * that cap bounds the transient heap of a read/parse pass, whereas THIS bound
 * governs what can actually be INGESTED as a persisted operation. An ingested
 * `import_step` must ride inside the single {@link maxDocumentOperationsBytes}
 * document-size envelope every boundary enforces (mutation acceptance, kernel
 * transport, journal, `.aeth` container), so the source is bounded well below
 * that 3 MiB envelope with headroom for the rest of the operation and array.
 * A structurally-valid STEP file between this bound and the 64 MiB validation
 * cap is refused HONESTLY at ingestion (it does not fit the document envelope),
 * never silently truncated.
 */
export const maxImportStepSourceChars = 2 * 1024 * 1024;

/**
 * Ingests a preserved STEP (ISO-10303-21) B-rep as a solid body — the read
 * half of the manufacturing interchange (MASTER_PLAN §1.4 Tranche E; gates 6
 * "Export integrity" + 9 "File integrity"; defect D-019). Unlike the primitive
 * births, whose geometry is synthesized from numeric parameters, `import_step`
 * is a body-birth whose geometry is read back from the exact bytes it carries:
 *
 * - `source` is the original imported Part-21 exchange structure, retained
 *   verbatim per §2.1. It is the operation's entire geometric definition, so
 *   the op-hash contract content-addresses it like any other parameter and
 *   deterministic replay reduces to the kernel's proven property that identical
 *   STEP bytes read back to identical topology (the step-reimport oracle,
 *   kernel-protocol.ts / mutation.cpp). The kernel builds the body from these
 *   bytes; a document that carries an `import_step` never depends on the
 *   original file still existing on disk.
 * - `sourceSha256` is the lowercase-hex SHA-256 of `source`'s UTF-8 bytes: a
 *   content-integrity anchor (§2.4 content-addressed reference) the native
 *   executor RE-VERIFIES against the bytes it is about to build from, so a
 *   source corrupted in transport is refused rather than silently yielding
 *   different geometry. The schema pins its FORMAT here; the byte-exact match
 *   is enforced where the bytes become geometry (the kernel), the one place it
 *   can be checked against the real input.
 *
 * `import_step` REFERENCES and CONSUMES nothing — it is a root like the
 * primitive creations, so it declares no operation dependencies and carries no
 * topology-reference slots. Provenance (the originating filename) rides in
 * `metadata.createdBy` as the existing `{ kind: "import", sourceName }` arm,
 * which the op-hash contract excludes so two imports of identical bytes from
 * differently-named files share a cache line.
 */
/**
 * The ordered set of bodies a BIRTH operation declares (ADR-013 decision 1).
 *
 * WHY THE SCALAR STAYS. A multi-solid import is the only operation kind that
 * produces more than one body, and it still has a FIRST body. Keeping
 * `outputBodyId` as that first body — and requiring `outputBodyIds[0]` to equal
 * it — means every consumer written before fan-out existed keeps resolving to
 * body 0 unchanged, and every persisted token without an `:<outputIndex>`
 * keeps meaning what it always meant.
 *
 * The field is OPTIONAL with no default, so a single-solid import omits it
 * entirely and serializes to the exact bytes it always did: the RFC 8785
 * canonical form is unchanged, so its op-hash and its replay-cache key are
 * unchanged. Fan-out costs existing documents nothing — measured, not assumed.
 *
 * The ORDER is the canonical geometric order ruled in
 * `docs/design/2026-07-28-multi-output-birth-residuals.md` (volume desc, then
 * centre of mass, then bbox diagonal) — a property of the shapes rather than of
 * OCCT's reader, so identical file bytes give an identical order forever.
 */
const outputBodyIdsSchema = z.array(bodyIdSchema).min(1).max(1024);

export const importStepOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("import_step"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    /** Present only when the import produced more than one solid. */
    outputBodyIds: outputBodyIdsSchema.optional(),
    parameters: z
      .object({
        source: z.string().min(1).max(maxImportStepSourceChars),
        sourceSha256: z.string().regex(/^[0-9a-f]{64}$/),
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

// The two invariants that bind `outputBodyIds` to `outputBodyId` — the first
// entry IS the scalar, and no id repeats within one set — are enforced in
// `@aeth/document-model`'s document identity pass rather than here.
//
// Not a preference: attaching a `superRefine` turns this into a ZodEffects, and
// the agent toolset builds its model-facing tool inputs by `.omit()`-ing fields
// off these operation schemas — so a refinement here silently costs the agent
// every import tool. The document pass is also where document-wide body-id
// uniqueness already lives, so both rules land in one place instead of two.

/**
 * The maximum length, in UTF-8 characters, of a mesh `import_mesh` operation's
 * inline `source` (MASTER_PLAN §1.4 Tranche E; defect D-023). Like
 * {@link maxImportStepSourceChars} it holds the retained geometry INSIDE the
 * operation so an import replays with no dependence on the original file, and it
 * is bounded well below the {@link maxDocumentOperationsBytes} envelope with
 * headroom for the rest of the operation and array. A checked mesh whose base64
 * payload exceeds this bound validates as geometry but is refused HONESTLY at
 * ingestion (`too_large_to_ingest`, mirroring STEP), never silently truncated.
 * Base64 inflates the binary aeth-mesh-v1 payload ~4/3, so this caps the stored
 * surface at roughly 1.5 MiB of checked mesh.
 */
export const maxImportMeshSourceChars = 2 * 1024 * 1024;

/**
 * Ingests a preserved mesh (STL/OBJ/3MF, ingested through the
 * `@aeth/interchange` pipeline) as a solid body — the mesh half of the
 * manufacturing interchange (MASTER_PLAN §1.4 Tranche E; gates 6 "Export
 * integrity" + 9 "File integrity"; defect D-023). Like `import_step` it is a
 * body-birth whose geometry is read back from the exact bytes it carries, but
 * where STEP retains Part-21 text, a mesh retains its CHECKED surface:
 *
 * - `source` is the base64-encoded `aeth-mesh-v1` payload the interchange
 *   ingestion pipeline produced (the guaranteed-manifold, welded, degenerate-
 *   dropped, outward-oriented triangle surface — plan 01 §6.3). The original
 *   STL/OBJ/3MF bytes are NOT retained: the meaning-preserving repair pipeline
 *   is the ingestion, and the checked buffers "are what gets stored" (§6.3.1
 *   step 11). Retaining raw mesh bytes would demand re-running that TS-only
 *   repair inside the kernel, which the native host does not link; the checked
 *   surface is instead rebuilt deterministically into the same solid. The
 *   op-hash contract content-addresses it exactly like `import_step.source`.
 * - `sourceSha256` is the lowercase-hex SHA-256 of `source`'s UTF-8 bytes — the
 *   same content-integrity anchor `import_step` carries; the native executor
 *   re-verifies it against the retained bytes before it decodes and sews them,
 *   so a source corrupted in transport is refused rather than silently yielding
 *   different geometry.
 *
 * `import_mesh` yields exactly ONE body (plan 01 §6 / 08 §6.1: multiple mesh
 * objects combine into one mesh body; a multi-lump surface becomes one body that
 * is a compound of solids). It REFERENCES and CONSUMES nothing — a root like the
 * primitive creations and `import_step` — so it declares no operation
 * dependencies and carries no topology-reference slots. Provenance (the
 * originating filename) rides in `metadata.createdBy` as the `import` arm, which
 * the op-hash contract excludes so two imports of identical checked bytes from
 * differently-named files share a cache line.
 */
export const importMeshOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("import_mesh"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        source: z.string().min(1).max(maxImportMeshSourceChars),
        sourceSha256: z.string().regex(/^[0-9a-f]{64}$/),
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/* --- sheet-metal wave 1: base_flange / edge_flange / unfold ---------------
 *
 * TS contracts land alongside — but independently of — the native kernel
 * dispatch for these three types (a second, concurrent workstream against the
 * same field names). Whichever side lands first, `evaluate_document` cannot
 * silently do the wrong thing: adding these types to the union below makes
 * them "known" (Gate 9 no longer shields them), so until the native side is
 * measured working a raw instance reaching the kernel is refused with an
 * ATTRIBUTED `UNSUPPORTED_OPERATION` (geometry.cpp's fail-closed final
 * `else`) — the same catalog-wave1/fillet-v2 staging pattern. All three ship
 * v1 only: brand new types, so every ref slot is present from the start and
 * there is no earlier unversioned shape to stay migration-neutral with.
 */

/**
 * Creates the FIRST solid body of a sheet-metal part from a planar profile:
 * a flat base flange of uniform sheet `thicknessMm`. Structurally the
 * sheet-metal analogue of `extrude` — `profileOperationId` is an
 * OPERATION-level reference (ADR-003) to an earlier profile operation, READ
 * (not consumed) exactly like extrude's, revolve's, loft's, and sweep's:
 * several features may reference one profile within an evaluation, and the
 * document dependency registry declares the reference so deleting a
 * consumed profile is refused at the transaction seam.
 *
 * `direction` chooses which side of the profile plane the material grows
 * into. Unlike extrude v1 (`direction` pinned to the literal `"normal"`),
 * base_flange also accepts `"reverse"`: a flat sheet has no inherent "only
 * one side makes sense" constraint the way a first extrude's convention
 * does, so both are offered from v1.
 */
export const baseFlangeOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("base_flange"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        profileOperationId: operationIdSchema,
        thicknessMm: millimetersSchema,
        direction: z.enum(["normal", "reverse"]).default("normal"),
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * Folds a new flange out from one specific straight edge of an earlier
 * sheet-metal body — the second sheet-metal feature, chained onto
 * `base_flange`'s output or an earlier `edge_flange`'s.
 *
 * `targetOperationId` is an OPERATION-level reference (ADR-003) to an
 * earlier BODY-PRODUCING operation. edge_flange CONSUMES it exactly like
 * fillet/chamfer/shell: the target leaves the evaluation result (no bodies
 * entry, no probes, no mesh packet) and only this operation's
 * `outputBodyId` body appears in its place, at edge_flange's position in
 * document order. The same REFERENCE_MISSING taxonomy applies (missing,
 * non-body, forward, or already-consumed references are all the same
 * failure, attributed to this operation's id).
 *
 * `edge` is a REQUIRED persisted topology ref under the `edges` head — unlike
 * fillet-v1's implicit "every edge" or shell's OPTIONAL `openFaces`, a flange
 * always folds along one specific, caller-chosen edge, so there is no
 * sensible "absent means every edge" default here. The persisted `edge.query`
 * is an AQL string the kernel never sees (plan 05 §4.2): document-model
 * parses, kind-checks (must resolve to `edge` head kind), and rootedness-
 * checks it at op acceptance, then ships the parsed AST across the
 * kernel-host boundary as `operationRefWireSchema` — the same
 * `…SchemaWith(ref)` factory pattern `shellOperationSchemaWith` established.
 * `@aeth/document-model`'s ref-slot registry (`operation-ref-slots.ts`)
 * additionally registers `edge` so the query's named operation becomes a hard
 * dependency (deleting it is refused while this edge_flange exists).
 *
 * `flangeLengthMm` is the new wall's flat length, measured from the bend.
 * `bendAngleDeg` is exclusive of 0 (a zero-degree bend folds nothing — not a
 * bend at all) and inclusive up to 180 (a full hem: the flange folds back
 * flush against the wall it came from — a real, if extreme, sheet-metal
 * feature). `bendRadiusMm` is the inside bend radius; `thicknessMm` restates
 * the sheet thickness (reconciling it against the body's already-established
 * thickness is the native executor's concern, not this schema's).
 *
 * `kFactor` in [0, 1] is the neutral-axis position used for bend-allowance
 * flattening (0 = neutral axis at the inside face, 1 = at the outside face).
 * THE 0.44 DEFAULT IS A STATED GENERAL-PURPOSE STARTING POINT, NOT A
 * UNIVERSAL PHYSICAL CONSTANT: real shops maintain their own per-material,
 * per-gauge bend tables, and a `kFactor` lookup keyed by material + gauge is
 * explicitly OUT OF SCOPE for this v1 — a real, recorded backlog item, not a
 * silently missing feature. This per-operation override is the full extent
 * of "bend table" support for now.
 *
 * `reliefType` chooses the corner-relief cut at the bend's ends (`none` when
 * the flange spans a whole straight edge with no free ends to relieve,
 * `rectangular` otherwise). Real sheet-metal tools also offer an `obround`
 * (stadium-shaped) relief cut and a `tear` relief; both are REAL, recorded
 * gaps rather than silently missing — see `edge-flange-creation.ts`'s own
 * doc comment — deferred to a v1.1 rather than shipped as a schema value the
 * native kernel cannot yet cut (this v1 only accepts values the kernel has
 * verified geometry for). `reliefDepthMm` is left a TRUE OPTIONAL with NO
 * schema default on purpose: when absent, the native kernel
 * derives a sensible depth (bend radius + thickness) at execution time,
 * matching how this codebase generally prefers the kernel compute a real
 * default over the schema fabricating one (e.g. dimension offsets are not
 * schema-defaulted either).
 */
function edgeFlangeOperationSchemaWith(edgeRef: RefSlotSchema) {
  return z
    .object({
      id: operationIdSchema,
      type: z.literal("edge_flange"),
      schemaVersion: z.literal(1),
      name: z.string().trim().min(1).max(120),
      outputBodyId: bodyIdSchema,
      parameters: z
        .object({
          targetOperationId: operationIdSchema,
          edge: edgeRef,
          flangeLengthMm: millimetersSchema,
          bendAngleDeg: z.number().finite().gt(0).max(180),
          bendRadiusMm: millimetersSchema,
          thicknessMm: millimetersSchema,
          /** See the schema doc comment: a stated default, not a physical constant. */
          kFactor: z.number().finite().gte(0).lte(1).default(0.44),
          reliefType: z.enum(["none", "rectangular"]).default("rectangular"),
          reliefDepthMm: millimetersSchema.optional(),
        })
        .strict(),
      metadata: operationMetadataSchema,
    })
    .strict();
}

export const edgeFlangeOperationSchema =
  edgeFlangeOperationSchemaWith(operationRefSchema);

/**
 * The ordered pair of bodies `unfold` births, reusing the multi-output-birth
 * mechanism ADR-013 built for `import_step`'s multi-solid case rather than
 * inventing a parallel one: index 0 is the folded body — the SAME id as
 * `outputBodyId` (the existing `outputBodyIds[0] === outputBodyId` invariant
 * every legacy scalar-only consumer already resolves to) — and index 1 is the
 * newly computed flat-pattern body.
 *
 * UNLIKE `import_step`'s `outputBodyIds` (optional, present only for a
 * multi-solid import — a genuinely variable count from 1 to 1024 driven by
 * the imported file's own content), `unfold` ALWAYS produces exactly this
 * pair: every unfold births a folded body AND a flat body, never a variable
 * count driven by authored input. The field is therefore REQUIRED here (no
 * `.optional()`) and shaped as an exact 2-tuple rather than reusing
 * import_step's variable-length array schema — a deliberate, narrower fit for
 * a birth count that is fixed by the operation's own semantics. See the
 * report note on this file's author's deviation from the originally sketched
 * `outputBodyIds` shape for the reasoning in full.
 */
const unfoldOutputBodyIdsSchema = z.tuple([bodyIdSchema, bodyIdSchema]);

/**
 * Computes the flat pattern of an earlier sheet-metal body: unbends every
 * flange to its planar shape — the sheet-metal "flatten for the cut file"
 * step.
 *
 * `targetOperationId` is an OPERATION-level reference (ADR-003) to an earlier
 * BODY-PRODUCING operation. unfold CONSUMES it exactly like
 * fillet/chamfer/shell/hole/offset/transform: the target leaves the
 * evaluation result and only unfold's own bodies appear in its place, at
 * unfold's position in document order — the folded body (`outputBodyId`,
 * shape-identical to the consumed target; unfold changes no geometry, it only
 * computes an additional flat representation) and the new flat-pattern body
 * (`outputBodyIds[1]`). A later feature that wants to keep building on the 3D
 * form references unfold's OWN id as its `targetOperationId`, exactly as any
 * feature chain already works (the same convention a fillet after a shell
 * points at the shell, not at the shell's own target). The same
 * REFERENCE_MISSING taxonomy applies to `targetOperationId` as every other
 * consuming operation's target.
 *
 * `kFactorOverride`, when given, supersedes the bend-allowance `kFactor`
 * recorded on each `edge_flange`/`base_flange` this body was built from, for
 * THIS unfold's flattening math only — the upstream operations keep their own
 * stated `kFactor` unchanged. Absent, the native executor uses each feature's
 * own recorded value.
 *
 * NO ref slots: `targetOperationId` is an operation-id reference exactly like
 * `mirror.parameters.sourceOperationId` or `transform.parameters
 * .targetOperationId`, not an AQL-selector topology pick, so
 * `@aeth/document-model`'s ref-slot registry declares an empty slot list for
 * this type (mirroring `extrude`'s own empty entry).
 *
 * The two invariants binding `outputBodyIds` to `outputBodyId` — index 0 IS
 * the scalar, and no id repeats within the set — are enforced in
 * `@aeth/document-model`'s document identity pass (`addOperationIdentityIssues`
 * in document-schema.ts) rather than with a `.refine()` here, exactly as they
 * are for `import_step`. Not a preference: attaching a `superRefine` would
 * turn this schema into a ZodEffects, and the agent toolset builds its
 * model-facing tool input by `.omit()`-ing envelope fields off the production
 * operation schema — a refinement here would silently break `.omit()` for
 * this tool (see `import_step`'s own precedent comment on
 * `importStepOperationSchema`, immediately above `outputBodyIdsSchema`,
 * which explains this in full).
 */
export const unfoldOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("unfold"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    outputBodyIds: unfoldOutputBodyIdsSchema,
    parameters: z
      .object({
        targetOperationId: operationIdSchema,
        kFactorOverride: z.number().finite().gte(0).lte(1).optional(),
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/* --- end sheet-metal wave 1 ------------------------------------------------ */

/* --- surfacing wave 1: boundary_surface / surface_offset / stitch / thicken
 *
 * A CAD "surface" body is an OPEN shape (an unclosed shell or a single face),
 * as opposed to a CLOSED solid — real tools (Fusion 360's Surface workspace,
 * SolidWorks Surfaces) let you build these mid-model and thicken/stitch them
 * back into solids later. NO NEW SCHEMA FIELD MARKS A BODY "surface" VS
 * "solid": that distinction is DERIVED at evaluation time from the kernel's
 * existing `ShapeProbes.solidCount`/`shellCount`/`faceCount` wire fields
 * (kernel-protocol-core.ts) — already generic and shape-agnostic — so every
 * operation below simply produces A body, whose openness the evaluation
 * response reveals structurally. Nothing here is authored state.
 *
 * TS contracts land alongside — but from a workstream independent of — the
 * native kernel dispatch for these four types (the sheet-metal wave's own
 * precedent, repeated). Adding these types to the union below makes them
 * "known" (Gate 9 no longer shields them), so until the native side is
 * measured working a raw instance reaching the kernel is refused with an
 * ATTRIBUTED `UNSUPPORTED_OPERATION` (geometry.cpp's fail-closed final
 * `else`) — the same catalog-wave1/fillet-v2/sheet-metal staging pattern.
 * All four ship v1 only: brand new types, so there is no earlier unversioned
 * shape to stay migration-neutral with. None of the four carries a topology
 * ref slot (see `boundary_surface`'s own doc comment for why one was
 * deliberately NOT added even though it was the natural first candidate).
 */

/**
 * Fills an earlier body's ENTIRE open boundary into a new OPEN surface — the
 * "Fill"/"Patch" surfacing verb (Fusion 360 Patch, SolidWorks Fill Surface).
 * Structurally the surfacing analogue of `mirror`/`datum_plane`:
 * `targetOperationId` is an OPERATION-level reference (ADR-003) to the
 * earlier BODY-PRODUCING operation whose boundary is filled, READ (not
 * consumed) exactly like `mirror.parameters.sourceOperationId` or
 * `datum_plane`'s face/axis slots — the source body stays live and untouched;
 * boundary_surface only reads its topology to build a brand new body. The
 * dependency registry still declares the reference as a hard dependency
 * (deleting the source is refused while this operation exists) even though
 * nothing is consumed — the same non-consuming-but-still-a-hard-dependency
 * shape `mirror`'s unmerged read and every `datum_*` reference already
 * document.
 *
 * NO EDGE SELECTOR: `targetOperationId` is the ONLY parameter. Unlike
 * `edge_flange`'s required `edge` ref, boundary_surface does not name WHICH
 * edges to fill — it fills the target's WHOLE free/open boundary (every edge
 * incident to exactly one face, walked into a loop), found by the native
 * executor directly from the target's own topology. This is a deliberate
 * scope decision, verified against both sides of this catalog's own
 * contract, not a placeholder:
 *
 * 1. The v1 selector grammar's filter catalog (`selector-catalog.ts`
 *    `filterCatalog`, the single static-checking authority the parser, ref
 *    validation, and the op-hash projection all share) has no predicate for
 *    "edges bordering exactly one face". `convex`/`concave` classify an
 *    edge's dihedral angle, `boundaryOf`/`interiorTo` test membership
 *    relative to a GIVEN faces query, `adjacentTo` tests neighborhood — none
 *    of them can express "free" in the absolute, no-reference-needed sense a
 *    boundary fill needs. There is nothing a `boundaryEdges` ref slot could
 *    ask the v1 grammar for that the target's own topology doesn't already
 *    answer unambiguously.
 * 2. A ref slot is only ever added once the executor actually resolves it:
 *    "a schema that accepted a ref the kernel ignored would silently produce
 *    wrong geometry, which is the one unrepresentable outcome" (refs-core.ts,
 *    stated for every ref slot in this catalog, not invented for this one).
 *    With no selector able to express the distinction in (1), the native v1
 *    executor computes the free boundary itself rather than resolving an
 *    authored selection — so the field simply does not exist here rather
 *    than existing unread.
 *
 * Practical consequence: v1 succeeds exactly when the target's WHOLE edge set
 * already forms one simple closed free boundary (the common real case — an
 * unclosed `stitch`/earlier `boundary_surface`/imported open shell) and
 * refuses (native `E_BOUNDARY_SURFACE_NOT_CLOSED`) when the target has no
 * open boundary, more than one disjoint boundary loop, or a non-manifold
 * junction among its free edges. Hand-picking WHICH boundary to fill when a
 * target has several — "cap one hole in an otherwise-closed solid" — needs
 * real free-edge selection the v1 grammar cannot express yet: a recorded
 * v1.1 gap (a selector-grammar gap, specifically), not a silently missing
 * capability.
 *
 * The produced body is OPEN by construction — a single filled face, not a
 * solid. As stated in the section note above, nothing in this schema records
 * that; a later `thicken` or `stitch` reads this operation's `outputBodyId`
 * exactly like any other body-producing operation's.
 *
 * V1 SCOPE (recorded, not silently missing): the fill matches G0 (positional)
 * continuity only — it only guarantees the new surface meets the boundary
 * loop position-for-position, and does NOT match tangent (G1) or curvature
 * (G2) continuity against the faces the loop borders. Real tools (Fusion 360
 * Patch, SolidWorks Fill Surface) expose a per-edge "Connected (G0) / Tangent
 * (G1) / Curvature (G2)" choice; that per-edge continuity selection is a
 * real, recorded v1.1 gap alongside targeted free-edge selection above.
 */
export const boundarySurfaceOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("boundary_surface"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        /** Whose body's free boundary is filled — read-only, NOT consumed. */
        targetOperationId: operationIdSchema,
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * Offsets an existing OPEN surface body along its own normal by a signed
 * distance in millimeters — the surfacing analogue of the solid-only
 * `offset`/shell family, but for a body with no interior volume to grow into
 * or out of: a positive `distanceMm` pushes the whole surface one way along
 * its normal, negative the other.
 *
 * DELIBERATELY DISTINCT FROM `offset` (CAP-034's "Push", the v2 LOCAL FACE
 * OFFSET documented on `offsetOperationV2SchemaWith` above): that operation
 * moves ONE FACE of a SOLID body, re-trimming its neighbours against the
 * moved surface. `surface_offset` moves the WHOLE body along its own normal —
 * there are no neighbouring faces on the target to re-trim. Same underlying
 * idea (a signed distance along a normal), a different target class
 * entirely, hence the distinct operation type rather than a third `offset`
 * schemaVersion.
 *
 * `targetOperationId` is an OPERATION-level reference (ADR-003) to an earlier
 * BODY-PRODUCING operation. surface_offset CONSUMES it exactly like
 * fillet/chamfer/shell/offset: the target leaves the evaluation result (no
 * bodies entry, no probes, no mesh packet) and only this operation's
 * `outputBodyId` body appears in its place, at surface_offset's position in
 * document order. The same REFERENCE_MISSING taxonomy applies (missing,
 * non-body, forward, or already-consumed references are all the same
 * failure, attributed to this operation's id).
 *
 * Whether the target is actually an OPEN surface — as opposed to a closed
 * solid, which this operation is not meant for — is the native executor's
 * resolve-time check, never the schema's: body openness is DERIVED from
 * `ShapeProbes.solidCount`/`shellCount`/`faceCount` at evaluation time, not
 * an authored field this or any operation carries (see the section note
 * above).
 *
 * `distanceMm` REJECTS EXACTLY ZERO: a zero-distance offset moves nothing, so
 * it is refused as not being an edit at all — the same treatment the
 * existing face-scoped `offset` verb gives a zero distance at its own
 * authoring boundary (`offset-creation.ts`'s `parseOffsetDistance`: "Zero is
 * refused because it is not an edit — the kernel refuses it too"), and the
 * same "non-zero ... within the modeling extent" framing
 * `offsetOperationV1Schema.parameters.distance` already states for its own
 * signed whole-body distance.
 */
export const surfaceOffsetOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("surface_offset"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        /** The surface body being offset — CONSUMED. */
        targetOperationId: operationIdSchema,
        distanceMm: z
          .number()
          .finite()
          .min(-1_000_000)
          .max(1_000_000)
          .refine((value) => value !== 0, {
            message:
              "surface_offset distanceMm must be non-zero and within the modeling extent — a zero-distance offset is not an edit",
          }),
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * Sews exactly two earlier bodies (each surface or solid) together into one,
 * within `toleranceMm` — the surfacing "Stitch"/"Sew" verb (Fusion 360
 * Stitch, SolidWorks Knit Surface). Structurally the surfacing twin of
 * `boolean_combine`: the same two-operand consuming shape, minus a `kind`
 * discriminant (a stitch has only one behaviour — sew, not union/cut/
 * intersect) and plus a tolerance in its place.
 *
 * `firstOperationId` and `secondOperationId` are OPERATION-level references
 * (ADR-003), each naming the document id of a BODY-PRODUCING operation
 * evaluated EARLIER in the document — exactly like `boolean_combine`'s
 * `targetOperationId`/`toolOperationId`. stitch CONSUMES both: the consumed
 * bodies leave the evaluation result (no bodies entry, no probes, no mesh
 * packet) and only `outputBodyId` appears in their place, at stitch's
 * position in document order. The same REFERENCE_MISSING taxonomy applies to
 * each (missing, non-body, forward, or already-consumed references are all
 * the same failure, attributed to this operation's id), and the same
 * distinctness rule `boolean_combine` enforces on its target/tool applies
 * here: the two operands must name different operations.
 *
 * WHETHER THE RESULT IS OPEN OR CLOSED IS A RUNTIME OUTCOME, NEVER AN
 * AUTHORED CHOICE: if the two sewn bodies happen to close up into a
 * watertight shell, the kernel produces a SOLID; if a gap wider than
 * `toleranceMm` remains, it stays an OPEN surface. Nothing in this schema
 * distinguishes the two cases — like every other body-producing operation in
 * this section, openness is DERIVED from
 * `ShapeProbes.solidCount`/`shellCount`/`faceCount` at evaluation time, never
 * stored here.
 *
 * `toleranceMm` is the maximum gap between the two bodies' boundaries that
 * still sews shut; it DEFAULTS to 0.01 mm — a tight, print/CNC-realistic
 * starting point rather than a physical constant, the same "stated default,
 * not a universal constant" framing `edge_flange`'s `kFactor` default
 * documents for its own general-purpose number.
 *
 * V1 SCOPE (recorded, not silently missing): v1 stitches exactly TWO bodies
 * at a time, mirroring `boolean_combine`'s own two-body precedent. Stitching
 * many surfaces in one command — the multi-select "Stitch" real tools
 * typically offer — needs repeated application of this operation in v1: a
 * real, recorded v1.1 convenience gap, not a missing capability.
 *
 * No ref-slot registration: like `boolean_combine`, stitch references whole
 * bodies by operation id, not a topology selector, so
 * `@aeth/document-model`'s ref-slot registry declares an empty slot list for
 * this type.
 */
export const stitchOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("stitch"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        firstOperationId: operationIdSchema,
        secondOperationId: operationIdSchema,
        toleranceMm: millimetersSchema.default(0.01),
      })
      .strict()
      .superRefine((parameters, context) => {
        if (parameters.firstOperationId === parameters.secondOperationId) {
          context.addIssue({
            code: "custom",
            message:
              "firstOperationId and secondOperationId must reference distinct operations",
            path: ["secondOperationId"],
          });
        }
      }),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * Extrudes an existing OPEN surface body along its own normal by
 * `thicknessMm`, producing a SOLID — the surfacing "Thicken" verb (Fusion 360
 * Thicken, SolidWorks Thicken). The solid-producing counterpart to
 * `surface_offset`: where surface_offset moves a surface and leaves it a
 * surface, thicken gives a surface real wall thickness and turns it into a
 * closed solid (subject to the same runtime-derived openness rule every
 * other operation in this section follows — see the section note above).
 *
 * `targetOperationId` is an OPERATION-level reference (ADR-003) to an earlier
 * BODY-PRODUCING operation. thicken CONSUMES it exactly like
 * fillet/chamfer/shell/surface_offset: the target leaves the evaluation
 * result and only this operation's `outputBodyId` body appears in its place,
 * at thicken's position in document order. The same REFERENCE_MISSING
 * taxonomy applies (missing, non-body, forward, or already-consumed
 * references are all the same failure, attributed to this operation's id).
 *
 * `direction` chooses which side of the surface the material grows into:
 * `normal` (default) grows along the surface's own outward normal, `reverse`
 * grows against it, and `symmetric` grows the solid on BOTH sides of the
 * surface — a real, common option in both Fusion 360 and SolidWorks Thicken,
 * offered from v1 exactly like `base_flange` offers `normal`/`reverse` from
 * its own v1 (a surface, like a flat sheet, has no inherent "only one side
 * makes sense" constraint). Exactly how the thickness splits between the two
 * sides under `symmetric` is the native executor's concern, not this
 * schema's.
 *
 * Whether the target is actually an OPEN surface, and whether the thickened
 * result is a valid closed solid, are the native executor's resolve-time
 * checks (a self-intersecting thicken over a too-curved surface is refused
 * with GEOMETRY_FAILED rather than emitting invalid geometry) — never the
 * schema's: body openness is DERIVED from
 * `ShapeProbes.solidCount`/`shellCount`/`faceCount` at evaluation time, not
 * an authored field.
 *
 * No ref slots: `targetOperationId` is an operation-id reference exactly like
 * `unfold.parameters.targetOperationId` or `shell.parameters.targetOperationId`,
 * not an AQL-selector topology pick.
 */
export const thickenOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("thicken"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        targetOperationId: operationIdSchema,
        thicknessMm: millimetersSchema,
        direction: z.enum(["normal", "reverse", "symmetric"]).default("normal"),
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/* --- end surfacing wave 1 --------------------------------------------------- */

/* --- electrical wave 1: wire_route -----------------------------------------
 *
 * TS contracts land alongside — but independently of — the native kernel
 * dispatch for this type (the sheet-metal/surfacing waves' own precedent,
 * repeated). Adding it to the union below makes it "known" (Gate 9 no longer
 * shields it), so until the native side is measured working a raw instance
 * reaching the kernel is refused with an ATTRIBUTED `UNSUPPORTED_OPERATION`
 * (geometry.cpp's fail-closed final `else`) — the same catalog-wave1/
 * fillet-v2/sheet-metal/surfacing staging pattern. Ships v1 only: a brand
 * new type, so every ref slot is present from the start and there is no
 * earlier unversioned shape to stay migration-neutral with.
 */

/**
 * Routes a single physical wire or cable, point to point, through an ordered
 * polyline of waypoints — the Electrical/routing domain's one v1 primitive.
 *
 * REAL WIRE-HARNESS CAD (SolidWorks Routing) distinguishes three tiers: a
 * WIRE (a single conductor), a CABLE (a jacketed multi-conductor part), and
 * a HARNESS (the assembled, branched network of many routed wires/cables).
 * `wire_route` builds only the single point-to-point PRIMITIVE a harness
 * would later be assembled from — branching, multi-endpoint harnesses are a
 * real, recorded v1.1 gap (see the V1 SCOPE note below), not a silent
 * omission.
 *
 * A routed wire becomes ORDINARY SOLID GEOMETRY in real tools: a thin
 * pipe/tube swept along its path, exactly like `sweep`'s own profile-along-
 * path result. That is why this operation carries NO new body-kind or
 * lifecycle category — it is just another body-producing operation, with
 * `outputBodyId` and everything else exactly as normal, sitting in the same
 * operation union as `extrude`/`sweep`/every other body-producing type.
 *
 * `startVertex` and `endVertex` are REQUIRED persisted topology refs under
 * the `vertices` head — the wire's two terminal points. Unlike shell's
 * OPTIONAL `openFaces`, a routed wire always runs between two specific,
 * caller-chosen points: there is no sensible "absent means some default
 * endpoint" here, the same discipline `edge_flange`'s required `edge` slot
 * documents for its own single ref ("a wire route with no start has nothing
 * to build" is the electrical twin of "a flange with no edge has nothing to
 * fold along"). Each persisted `…Vertex.query` is an AQL string the kernel
 * never sees (plan 05 §4.2): document-model parses, kind-checks (must
 * resolve to `vertex` head kind — `datum_axis`'s `a`/`b` twoPoints slots are
 * the existing precedent that `vertex` is already a fully supported
 * ref-slot kind), and rootedness-checks each at op acceptance, then ships
 * the parsed ASTs across the kernel-host boundary as
 * `operationRefWireSchema` — the same `…SchemaWith(ref)` factory pattern
 * `edgeFlangeOperationSchemaWith` established, adapted here for TWO slots
 * instead of one. `@aeth/document-model`'s ref-slot registry
 * (`operation-ref-slots.ts`) registers both `startVertex` and `endVertex`,
 * so the two operations they resolve against each become a hard dependency
 * (deleting either is refused while this wire_route exists) — see the
 * dependency-rule doc comment in `@aeth/document-model`'s `dependencies.ts`
 * for why NEITHER referenced body is consumed.
 *
 * `waypoints` is an ordered list of intermediate world-space points the
 * routed spline passes through BETWEEN `startVertex` and `endVertex` — the
 * same array-of-free-points idiom `sweep`'s own `path` field established,
 * reusing `point3Schema` directly rather than inventing a parallel point
 * type. Unlike `sweep.parameters.path` (REQUIRED, minimum 2 points, because
 * a sweep's spine has no other source of position), `wire_route`'s two
 * REQUIRED endpoints already come from `startVertex`/`endVertex`, so
 * `waypoints` may legally be EMPTY — a direct, unbent point-to-point run is
 * a completely ordinary wire route, not an edge case. Capped at 64,
 * matching this catalog's general carefulness about unbounded authored
 * arrays (e.g. `loft`'s `profileOperationIds`, `reliefType`-adjacent bounds
 * elsewhere in this file).
 *
 * `diameterMm` is the wire/cable's physical outer diameter: what turns the
 * routed result into a real, measurable, clearance-checkable solid rather
 * than a bare construction curve — the same "this number is what makes the
 * body real" role `thicknessMm` plays for `base_flange`/`thicken`.
 *
 * `minimumBendRadiusMm` (MBR) is the real industry term for a wire or
 * cable's physical bend-radius limit — how tightly it may be curved before
 * the conductor or jacket is damaged. THIS IS A NATIVE-KERNEL GEOMETRIC
 * CHECK, NOT A SCHEMA-LEVEL ONE: the executor samples the ROUTED PATH'S
 * ACTUAL BUILT CURVATURE along its length and REFUSES — it does NOT
 * silently clamp the geometry or reroute around the violation — wherever
 * the required radius is tighter than this value. The schema's only job is
 * carrying the number through; the "bend rules" this domain's exit
 * criterion names are enforced entirely native-side, against the spline's
 * measured curvature, never against a manually-placed constraint the way a
 * dimension constrains a sketch.
 *
 * `wireType` records the real SAE J1128 two-tier physical distinction
 * (`"wire"`: a single primary conductor; `"cable"`: a jacketed multi-
 * conductor part) but is COSMETIC/DESCRIPTIVE ONLY in v1 — recorded
 * honestly rather than implied: it does not yet drive different kernel
 * behavior (jacket geometry, conductor count/bundling, a different default
 * MBR table per type). Defaults to `"wire"`, the simpler and more common
 * case.
 *
 * `netName` is a PLAIN LABEL for the logical signal/net this physical wire
 * realizes (SolidWorks' "Net" concept) — an optional free-form string, NOT a
 * validated graph connecting multiple wire_route operations to shared
 * connector pins. A real electrical net (many wires sharing a named signal,
 * validated against a connector/pin library) is out of scope for v1; this
 * field is honest labeling only, recorded here rather than silently implied
 * to be load-bearing.
 *
 * V1 SCOPE (recorded, not silently missing), checked against real
 * SolidWorks Routing documentation:
 *
 * 1. SINGLE-DOCUMENT-GRAPH ONLY. `startVertex`/`endVertex` reference
 *    vertices on bodies produced by OTHER OPERATIONS IN THE SAME DOCUMENT —
 *    exactly like every other ref-based operation (fillet, edge_flange, …),
 *    NOT cross-occurrence references into a different assembly component.
 *    Real wire-harness routing crosses assembly occurrences (a wire from a
 *    connector on Part A to a connector on Part B); that needs the assembly
 *    layer's own endpoint-resolution mechanism (`AssemblyEndpoint` in
 *    `packages/document-model/src/assembly/model.ts`), which this v1 does
 *    not integrate with. A real, recorded v1.1/v2 gap, not a silent
 *    limitation.
 * 2. NO BRANCHING HARNESSES. v1 is strictly point-to-point, one wire per
 *    operation — the same "start narrow, defer the harder multi-entity
 *    case" discipline `sweep`'s own point-to-point v1 already set precedent
 *    for.
 * 3. NO AUTOMATIC CLEARANCE-VS-REST-OF-ASSEMBLY CHECK. The wire's real solid
 *    geometry (from `diameterMm`) exists for a FUTURE clearance check to
 *    use; `minimumBendRadiusMm` above is the full extent of v1 "bend rule"
 *    enforcement.
 * 4. `wireType`/`netName` ARE LABELS, NOT YET LOAD-BEARING — see their own
 *    field notes above.
 */
/** The real SAE J1128 two-tier physical distinction `wire_route.wireType` records — see that field's own doc note on {@link wireRouteOperationSchemaWith} for why it is cosmetic/descriptive only in v1. Named and exported (unlike, say, `base_flange`'s inline `direction` enum) because the desktop authoring surface and any future net/harness tooling need the same literal union by name, not just inline in one operation's parameters. */
export const wireTypeSchema = z.enum(["wire", "cable"]);

function wireRouteOperationSchemaWith(vertexRef: RefSlotSchema) {
  return z
    .object({
      id: operationIdSchema,
      type: z.literal("wire_route"),
      schemaVersion: z.literal(1),
      name: z.string().trim().min(1).max(120),
      outputBodyId: bodyIdSchema,
      parameters: z
        .object({
          startVertex: vertexRef,
          endVertex: vertexRef,
          waypoints: z.array(point3Schema).max(64).default([]),
          diameterMm: millimetersSchema,
          minimumBendRadiusMm: millimetersSchema,
          wireType: wireTypeSchema.default("wire"),
          netName: z.string().trim().min(1).max(120).optional(),
        })
        .strict(),
      metadata: operationMetadataSchema,
    })
    .strict();
}

export const wireRouteOperationSchema =
  wireRouteOperationSchemaWith(operationRefSchema);

/* --- end electrical wave 1 -------------------------------------------------- */

/* --- mold/tooling wave 1: mold_parting_line / mold_shutoff_surface /
 * mold_parting_surface / mold_tooling_split ---------------------------------
 *
 * TS contracts land alongside — but independently of — the native kernel
 * dispatch for these four types (the sheet-metal/surfacing/electrical waves'
 * own precedent, repeated). Adding them to the union below makes them
 * "known" (Gate 9 no longer shields them), so until the native side is
 * measured working a raw instance reaching the kernel is refused with an
 * ATTRIBUTED `UNSUPPORTED_OPERATION` (geometry.cpp's fail-closed final
 * `else`) — the same catalog-wave1/fillet-v2/sheet-metal/surfacing/
 * electrical staging pattern. All four ship v1 only: brand new types, so
 * every ref slot is present from the start and there is no earlier
 * unversioned shape to stay migration-neutral with.
 *
 * Real-world reference: SolidWorks Mold Tools (Draft Analysis -> Parting
 * Line -> Shut-Off Surfaces -> Parting Surface -> Tooling Split — pull
 * direction, draft angle, positive/negative/no-draft/straddle faces) plus
 * Fusion 360's leaner generic-tool composition (Draft, Split, Patch/Offset
 * Surface). Fusion has NO dedicated mold workspace — confirming that draft
 * analysis belongs as an inspect-only kernel query rather than a tree
 * feature is authentic to how real tools already treat it, not a shortcut
 * this catalog is taking; see `mold_draft_analysis` in
 * `kernel-protocol-core.ts`, a sibling top-level RPC method to
 * `simulate`/`hlr_project` rather than a member of this file's operation
 * union — it never appears in `operationSchema`/`wireOperationSchema` and
 * bypasses `ExecuteOperation`/`naming_registry` entirely, exactly like those
 * two siblings.
 *
 * NONE of the four operations below carries a topology ref slot: every
 * `*OperationId` parameter here is an OPERATION-level reference (ADR-003) —
 * the same `mirror.parameters.sourceOperationId` /
 * `boundary_surface.parameters.targetOperationId` shape this catalog already
 * uses for "read (or consume) a whole earlier operation's body by id," never
 * an AQL-selector topology pick — so `@aeth/document-model`'s ref-slot
 * registry (`operation-ref-slots.ts`) declares an empty slot list for all
 * four, exactly as it does for `boundary_surface`/`unfold`/`stitch`/`thicken`.
 * Every one of those references is a non-consuming HARD dependency (READ,
 * never consumed) — see `@aeth/document-model`'s `dependencies.ts` for the
 * per-type rule and why: a mold tool references the part it is being built
 * around, it does not remove that part from the document. A person who
 * generates tooling for their design still has their design afterward.
 */

/**
 * A literal unit-vector-shaped OBJECT `{x, y, z}` — the mold/tooling wave's
 * pull direction. Deliberately NOT this file's established TUPLE shape
 * (`point3Schema`/`direction3Schema`, `[x, y, z]`, used everywhere else here:
 * `axisDirection`, `transform`'s `offset`, `sweep`'s `path`, `wire_route`'s
 * `waypoints`, …): a pull direction is picked from a clicked face's normal
 * and then edited COMPONENT BY COMPONENT in the mold-tooling panel's own
 * Stepper triplet, and the parallel `mold_draft_analysis` kernel query
 * request (`kernel-protocol-core.ts`) carries the exact same shape for its
 * own live preview — a named-key object is what both that per-component
 * editing surface and that parallel request want; a positional tuple would
 * make "which index is up" one more thing a reader has to remember. This
 * shape was independently converged on by both the schema and the desktop-UI
 * side of this catalog wave, not a unilateral choice.
 *
 * Only NON-ZERO is enforced here (mirroring `direction3Schema`'s own
 * "Direction must be non-zero" refinement) — never an exact-unit-length
 * check, since a UI-computed normalization is never bit-exact 1.0 anyway;
 * the native `ClassifyDraftFaces` classifier normalizes at classification
 * time. "Normalized at author time" is a stated authoring intent, not a
 * schema-enforced invariant.
 */
export const pullDirectionSchema = z
  .object({
    x: z.number().finite(),
    y: z.number().finite(),
    z: z.number().finite(),
  })
  .strict()
  .refine((value) => Math.hypot(value.x, value.y, value.z) >= 1e-9, {
    message: "pullDirection must be a non-zero vector",
  });

/**
 * The draft-angle tolerance, in degrees, within which a face's angle to the
 * pull direction is classified "no draft" (SolidWorks' own yellow
 * no-draft-face case) rather than positive or negative draft. Shared,
 * byte-for-byte, by `mold_parting_line.parameters.draftAngleToleranceDeg`
 * and the `mold_draft_analysis` kernel query request
 * (`kernel-protocol-core.ts`) — one schema behind both doors onto the same
 * native `ClassifyDraftFaces` classifier (see the section note above), so
 * the two can never disagree about what "the same tolerance" means.
 *
 * Bounded to [0, 30]: 0 admits no tolerance band at all (a legal, if
 * unforgiving, choice — every face not EXACTLY parallel to the pull
 * direction is decisively positive or negative), and 30 degrees is already a
 * generous outer bound for what a real mold shop would ever still call
 * "no draft." DEFAULTS to 0.5 — A STATED GENERAL-PURPOSE STARTING POINT, NOT
 * A UNIVERSAL MOLDMAKING CONSTANT, the same "stated default, not a physical
 * constant" framing `edge_flange.parameters.kFactor` and
 * `stitch.parameters.toleranceMm` already use for their own numbers.
 */
export const draftAngleToleranceDegSchema = z
  .number()
  .finite()
  .gte(0)
  .lte(30)
  .default(0.5);

/**
 * Finds a part's parting line — the closed loop where a mold's core and
 * cavity halves meet — along an authored pull direction, and births it as a
 * new WIRE body (an open curve network; NOT a solid, NOT a face — the same
 * "body kind is derived from `ShapeProbes`, never a stored field" rule
 * every surfacing operation in this file already follows).
 *
 * `targetOperationId` is an OPERATION-level reference (ADR-003) to the
 * earlier BODY-PRODUCING operation the parting line is found on, READ (not
 * consumed) exactly like `boundary_surface.parameters.targetOperationId` —
 * the source solid stays live and untouched; `mold_parting_line` only reads
 * its topology. `pullDirection` is the mold-open direction (see
 * {@link pullDirectionSchema}); `draftAngleToleranceDeg` (see
 * {@link draftAngleToleranceDegSchema}) is the no-draft tolerance band.
 *
 * EXECUTOR (native, landing from an independent, concurrent workstream):
 * calls the shared `ClassifyDraftFaces(body, pullDirection, tolerance)`
 * function — the SAME function the `mold_draft_analysis` kernel query calls,
 * one source of truth behind two doors (see the section note above) — then
 * walks edges via the (new, shared) `IncidentFacesOf` helper, finds every
 * edge whose two incident faces carry OPPOSITE sign classification
 * (positive/negative), and assembles the found edges into a loop via a new
 * connected-component grouping helper. Refuses (fails closed, never fakes a
 * parting line) with:
 *
 * - `E_PARTING_LINE_NO_DRAFT_VARIATION` — every face classified the same
 *   sign; there is nothing to find (a degenerate pull direction, e.g.
 *   perpendicular to the wrong axis).
 * - `E_PARTING_LINE_STRADDLE_FACE` — a face's sampled normals span both
 *   signs (SolidWorks' own "blue face" case) and the loop cannot be closed
 *   through edges alone; the message names the offending face's stable
 *   naming token, the same `agentHint`-bearing discipline every other
 *   kernel refusal in this codebase already follows, so an agent can act on
 *   it. This is the SAME real limitation SolidWorks itself documents to the
 *   user ("the software cannot automatically find parting lines through
 *   [straddle faces]," directing them to a manual Split Faces step) — v1
 *   here refuses a parting line through a straddle face for the identical
 *   reason, not as a shortcut.
 * - `E_PARTING_LINE_MULTIPLE_LOOPS` — more than one closed loop was found
 *   and v1 has no disambiguation rule for which one is intended; the message
 *   reports the count. v1 handles the single-outer-loop case, the
 *   overwhelmingly common real one; multi-loop is a documented, honest
 *   v1.1 gap, never a silent wrong answer.
 *
 * HLR (hidden-line removal) is NOT reused for this: `hlr_project` produces
 * flattened 2D paper-space polylines in a view's own projector frame, never
 * 3D edges on the model — not reusable for a 3D parting-line result.
 */
export const moldPartingLineOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("mold_parting_line"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        targetOperationId: operationIdSchema,
        pullDirection: pullDirectionSchema,
        draftAngleToleranceDeg: draftAngleToleranceDegSchema,
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * Caps every through-hole a part has relative to a pull direction with a new
 * filled surface (Fusion/SolidWorks "Shut-Off Surface") — the optional step
 * between parting line and parting surface, needed only when the part
 * actually has through-holes along the pull direction.
 *
 * `targetOperationId` is the SAME source solid `mold_parting_line` targeted
 * (an OPERATION-level reference, read not consumed). `partingLineOperationId`
 * references that earlier `mold_parting_line` operation so the executor can
 * EXCLUDE its outer loop from the free-edge set it caps — only "hole" loops
 * get capped, never the parting line's own boundary. Both references are
 * non-consuming hard dependencies, exactly like `boundary_surface`'s own
 * non-consuming read of its target.
 *
 * EXECUTOR (native, landing from an independent, concurrent workstream):
 * `FreeEdgesOf(body)`, grouped into loops by a new connected-component
 * helper shared with `mold_parting_line`, EXCLUDING the loop matching the
 * referenced parting line's own edge set (a loop is the parting line iff its
 * edges are exactly that operation's output wire's own edges — every other
 * free loop on the source body is a hole to cap). Each remaining loop is
 * filled independently via `BRepOffsetAPI_MakeFilling`
 * (`boundary_surface`'s own proven per-edge `Add(edge, GeomAbs_C0)` pattern —
 * position continuity only, no `Add(TopoDS_Wire)` overload on this OCCT
 * build), then every filled cap is combined by Sew (not Fuse — the caps are
 * disjoint) into one surface body. Refuses with `E_SHUTOFF_NO_HOLES` when
 * there are no non-parting-line free loops at all — told plainly, never a
 * silently empty output body (the same "named, not zeroed" ethos the BOM
 * panel's own mass-unknown handling already documents elsewhere in this
 * codebase).
 *
 * V1 SCOPE (recorded, not silently missing): v1 caps EVERY non-parting-line
 * free loop automatically — there is no per-loop opt-out picker. This
 * mirrors `boundary_surface`'s own no-selector precedent (see its schema
 * doc comment) rather than being an oversight; per-loop selection is a fair,
 * documented v1.1 gap.
 */
export const moldShutoffSurfaceOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("mold_shutoff_surface"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        targetOperationId: operationIdSchema,
        partingLineOperationId: operationIdSchema,
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * Extrudes the parting line (and, if present, the shut-off surface) into a
 * new surface body ready to split a tooling block with — the boundary
 * `mold_tooling_split`'s own boolean split cuts against.
 *
 * `partingLineOperationId` is an OPERATION-level reference (ADR-003) to the
 * earlier `mold_parting_line` operation, READ not consumed — this operation
 * also reads that operation's OWN `pullDirection` transitively rather than
 * re-specifying it, one source of truth for which way the mold opens.
 * `shutoffSurfaceOperationId` is an OPTIONAL operation-level reference,
 * likewise read not consumed: knit in when present, omitted when the part
 * has no through-holes along the pull direction (see
 * `mold_shutoff_surface`'s own doc comment). `extensionDistanceMm` is an
 * EXPLICIT LITERAL the caller states outright — the UI suggests a starting
 * value from the source body's bbox diagonal but never auto-sizes silently;
 * this catalog's doctrine is no hidden magic numbers, the same reasoning
 * `boundary_surface`/`stitch`/every other numeric default in this file
 * already states for itself.
 *
 * EXECUTOR (native, landing from an independent, concurrent workstream):
 * `BRepPrimAPI_MakePrism` on the parting line's WIRE, along the pull
 * direction read (transitively) from the referenced `mold_parting_line`
 * operation, by `extensionDistanceMm` in BOTH directions — so the resulting
 * surface fully spans a tooling block built with any reasonable margin —
 * producing a shell; when a shut-off surface is referenced, that shell is
 * knit into it (Sew, the same idiom `mold_shutoff_surface` itself uses to
 * combine its own caps) into one shell. `BRepPrimAPI_MakePrism` is used
 * throughout this codebase, but always face-to-solid, never wire-to-shell —
 * standard OCCT behavior, but genuinely novel for this codebase, so the
 * native workstream verifies it empirically before relying on it (the same
 * discipline `MakeThickSolid`'s ByJoin/BySimple split and `MakeFilling`'s
 * missing wire overload were both discovered and documented by).
 *
 * Refuses with `E_PARTING_SURFACE_SELF_INTERSECTS` when the swept wire is
 * non-planar enough that the extrusion self-intersects (a real possibility
 * for a non-planar parting line) — fail closed, matching
 * `boundary_surface`'s own `E_BOUNDARY_SURFACE_SELF_INTERSECTS` precedent
 * exactly.
 */
export const moldPartingSurfaceOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("mold_parting_surface"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    parameters: z
      .object({
        partingLineOperationId: operationIdSchema,
        shutoffSurfaceOperationId: operationIdSchema.optional(),
        extensionDistanceMm: millimetersSchema,
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/**
 * A non-negative length in millimeters — like {@link millimetersSchema} but
 * WITHOUT its `.positive()` floor. `mold_tooling_split`'s three per-axis
 * block margins legitimately allow exactly zero (an insert, or a part that
 * is already boxy on one axis, needs no extra clearance there) — unlike
 * every OTHER `*Mm` field in this catalog that reuses
 * {@link millimetersSchema} because a zero-length extrusion, thickness, or
 * flange would not be an edit at all.
 */
const nonNegativeMillimetersSchema = z.number().finite().gte(0).max(1_000_000);

/**
 * The ordered set of bodies `mold_tooling_split` births: core, then cavity,
 * then zero or more insert bodies (see the operation's own doc comment for
 * the role-assignment rule). Index 0 (`outputBodyIds[0]`) is always "core"
 * and equals the scalar `outputBodyId`, exactly like every other
 * multi-output-birth type in this file.
 *
 * A THIRD, DELIBERATE PATTERN for `outputBodyIds`, distinct from BOTH
 * precedents this catalog already established, because neither fits this
 * operation's actual cardinality rule:
 *
 * - UNLIKE `import_step`'s {@link outputBodyIdsSchema} (OPTIONAL — entirely
 *   absent for the overwhelmingly common single-solid import, present only
 *   when the imported file happens to contain more than one solid, and
 *   `min(1)` when it is): a tooling split ALWAYS produces at least two
 *   bodies. There is no legal "just one" outcome the way a single-solid
 *   import has one — core and cavity are the two mold halves a split
 *   ALWAYS yields, so this field is REQUIRED (no `.optional()`), and its
 *   floor is 2, not 1.
 * - UNLIKE `unfold`'s {@link unfoldOutputBodyIdsSchema} (a FIXED 2-tuple:
 *   every unfold births exactly a folded body and a flat body, never more,
 *   never fewer — cardinality is constant, only ORDER is semantic): a
 *   tooling split's COUNT is variable. `extraSplitSurfaceOperationIds`
 *   (this operation's own parameter, below) adds one insert body per extra
 *   split surface the author references, so the very same operation type
 *   legitimately produces 2, 3, or more bodies depending on what was
 *   authored — a fixed tuple cannot represent that; only an array with a
 *   floor can.
 *
 * So this type needs BOTH `import_step`'s variable cardinality AND
 * `unfold`'s unconditional presence AT ONCE: ordering is semantic and
 * asymmetric like `unfold`'s pair (index 0 is core, index 1 is cavity, the
 * rest are inserts in author-controlled order — never geometry-sorted, see
 * the operation's own doc comment), while cardinality is variable like
 * `import_step`'s set (driven by how many extra split surfaces were
 * authored). That is exactly why neither existing schema fits verbatim and
 * this third shape earns its place rather than forcing the operation into
 * one of the other two.
 *
 * Capped at 64: `extraSplitSurfaceOperationIds` is itself capped at 16, so
 * 2 + 16 = 18 is the realistic ceiling; 64 leaves the same headroom this
 * catalog gives every other authored-array bound (e.g.
 * `wire_route.parameters.waypoints`).
 *
 * As with `import_step`/`unfold`, the two invariants binding this set to the
 * scalar `outputBodyId` — index 0 IS the scalar, and no id repeats within
 * the set — are enforced in `@aeth/document-model`'s document identity pass
 * (`addOperationIdentityIssues` in document-schema.ts), which is ALREADY
 * FULLY GENERIC over any `outputBodyIds`-bearing operation via structural
 * duck-typing (confirmed by direct reading, and by a real end-to-end test
 * exercising this exact variable-length-always-present shape) — not a
 * `.refine()` here. Not a preference: attaching a `superRefine` would turn
 * this schema into a ZodEffects, and the agent toolset builds its
 * model-facing tool input by `.omit()`-ing envelope fields off the
 * production operation schema — a refinement here would silently break
 * `.omit()` for this tool, exactly as `import_step`'s and `unfold`'s own
 * doc comments on their `outputBodyIds` schemas already explain in full.
 */
const moldToolingSplitOutputBodyIdsSchema = z
  .array(bodyIdSchema)
  .min(2)
  .max(64);

/**
 * Splits a tooling block around a part into its core and cavity mold halves
 * (plus optional inserts) — the terminal step of the mold-tooling chain,
 * producing real SOLID bodies for the first time in this wave (parting line
 * is a wire, shut-off and parting surfaces are open surfaces).
 *
 * `targetOperationId` is an OPERATION-level reference (ADR-003) to the part
 * solid being tooled, READ not consumed — a person who generates tooling
 * for their part still has their part afterward. `partingSurfaceOperationId`
 * references the splitting surface (read, not consumed).
 * `shutoffSurfaceOperationId` is OPTIONAL and, when present, is needed AGAIN
 * here to build the capped cut-tool solid (see the executor note below)
 * EVEN THOUGH `mold_parting_surface` may already reference the same
 * operation — this is deliberately EXPLICIT, not inherited transitively,
 * because the two operations use the shut-off surface for two different
 * purposes (one knits it into a splitting shell, the other sews it into a
 * cut-tool solid) and a transitive lookup would silently couple them.
 * `block` gives the three non-negative per-axis margins (see
 * {@link nonNegativeMillimetersSchema}) the tooling block is expanded by
 * beyond the source body's bounding box. `extraSplitSurfaceOperationIds` is
 * an OPTIONAL, capped list of additional operation-level references — each
 * an independent splitting tool authored earlier via ORDINARY surfacing
 * operations (`boundary_surface`/`surface_offset`/etc., NOT a new
 * mold-specific tool — reuse, not reinvention) — for insert splits beyond
 * the basic core/cavity pair.
 *
 * EXECUTOR (native, landing from an independent, concurrent workstream):
 *
 * 1. Build the capped cut-tool solid: Sew(part faces [+ shut-off faces if
 *    referenced]) -> solid. With no shut-off reference and no through-holes
 *    present, the part solid is used directly. Sewing the shut-off faces in
 *    (rather than cutting with the raw, unsewn part) is what makes the two
 *    mold halves touch/pinch at a through-hole instead of leaving the hole
 *    tunneling through both halves — the entire reason shut-off surfaces
 *    exist. Reuses whatever Sewing/MakeSolid idiom the `stitch` operation's
 *    own executor already established, rather than re-deriving it.
 * 2. Build the block: `BRepPrimAPI_MakeBox` sized to the source body's bbox
 *    expanded by the three margins, reusing the existing box-primitive
 *    creation path (`create_box`'s own executor).
 * 3. `Cut(block, cappedSolid)` -> the moldable block.
 * 4. `BRepAlgoAPI_Splitter(cut result, tools=[partingSurface, ...extraSplit
 *    surfaces])` -> a compound of N solids. `BRepAlgoAPI_Splitter` exists
 *    today only as test/naming-oracle infrastructure with a PLANAR tool
 *    face; this operation's parting surface is a curved/knit SHELL, so the
 *    native workstream empirically spikes a non-planar shell tool before
 *    building the full feature on top of that assumption, the same
 *    discipline `MakeThickSolid`/`MakeFilling` were both proven by first.
 * 5. Explode the compound and assign role by centroid position relative to
 *    the parting surface along the pull direction (read transitively from
 *    `mold_parting_line` via `mold_parting_surface`): pull-direction-positive
 *    centroid is "cavity" (the mold half the pull direction points OUT of),
 *    negative is "core" — DELIBERATELY DEFINED here rather than asserted as
 *    a universal moldmaking convention, the same honesty every other
 *    definitional call in this catalog already states plainly. Any
 *    additional solids from `extraSplitSurfaceOperationIds` are "insert"
 *    role, ordered by that array's OWN author-controlled order — never
 *    geometry-sorted, since insert identity is intent, not geometric
 *    happenstance, the same reasoning `unfold`'s own fixed role order
 *    already follows.
 *
 * Refuses with `E_TOOLING_SPLIT_WRONG_SOLID_COUNT` when the splitter does
 * not yield EXACTLY `2 + extraSplitSurfaceOperationIds.length` solids — fail
 * closed, no silent best-guess mapping, mirroring `import_step`'s own
 * hard-fail-on-mismatch precedent (`EvaluateImportStepBodies`). This count
 * check is KERNEL-ONLY — never schema or `@aeth/document-model` — because
 * the true solid count is only knowable once the kernel actually runs the
 * splitter, exactly mirroring `import_step`'s own precedent of leaving this
 * class of check out of the TS layer entirely.
 */
export const moldToolingSplitOperationSchema = z
  .object({
    id: operationIdSchema,
    type: z.literal("mold_tooling_split"),
    schemaVersion: z.literal(1),
    name: z.string().trim().min(1).max(120),
    outputBodyId: bodyIdSchema,
    outputBodyIds: moldToolingSplitOutputBodyIdsSchema,
    parameters: z
      .object({
        targetOperationId: operationIdSchema,
        partingSurfaceOperationId: operationIdSchema,
        shutoffSurfaceOperationId: operationIdSchema.optional(),
        block: z
          .object({
            marginXMm: nonNegativeMillimetersSchema,
            marginYMm: nonNegativeMillimetersSchema,
            marginZMm: nonNegativeMillimetersSchema,
          })
          .strict(),
        extraSplitSurfaceOperationIds: z
          .array(operationIdSchema)
          .max(16)
          .optional(),
      })
      .strict(),
    metadata: operationMetadataSchema,
  })
  .strict();

/* --- end mold/tooling wave 1 ------------------------------------------------ */

/**
 * The `sketch` operation (CAP-035): plan-02's entity graph, the ADR-016
 * constraint system over it, and the solver's accepted solution.
 *
 * Produces NO body — a profile provider (plan 01 §2). The parameters live in
 * `sketch.ts`; only the envelope is here, so the union below can include the
 * kind without that module importing back from this one. **A schema outside
 * this union is not an operation kind** — a document carrying one would not
 * parse — which is why the envelope belongs where the union is.
 */
function sketchOperationSchemaWith(ref: typeof operationRefSchema) {
  return z
    .object({
      id: operationIdSchema,
      type: z.literal("sketch"),
      schemaVersion: z.literal(1),
      name: z.string().trim().min(1).max(120),
      parameters: sketchParametersSchemaWith(ref),
      metadata: operationMetadataSchema,
    })
    .strict();
}

export const sketchOperationSchema =
  sketchOperationSchemaWith(operationRefSchema);

export type SketchOperation = z.infer<typeof sketchOperationSchema>;

export const operationSchema = z.discriminatedUnion("type", [
  sketchOperationSchema,
  createBoxOperationSchema,
  createCylinderOperationSchema,
  createSphereOperationSchema,
  createConeOperationSchema,
  createTorusOperationSchema,
  createWedgeOperationSchema,
  createProfileOperationSchema,
  extrudeOperationSchema,
  revolveOperationSchema,
  loftOperationSchema,
  sweepOperationSchema,
  booleanCombineOperationSchema,
  holeOperationSchema,
  boltOperationSchema,
  claspOperationSchema,
  transformOperationSchema,
  offsetOperationSchema,
  filletOperationSchema,
  chamferOperationSchema,
  datumPlaneOperationSchema,
  datumAxisOperationSchema,
  shellOperationSchema,
  mirrorOperationSchema,
  patternLinearOperationSchema,
  patternCircularOperationSchema,
  importStepOperationSchema,
  importMeshOperationSchema,
  baseFlangeOperationSchema,
  edgeFlangeOperationSchema,
  unfoldOperationSchema,
  boundarySurfaceOperationSchema,
  surfaceOffsetOperationSchema,
  stitchOperationSchema,
  thickenOperationSchema,
  wireRouteOperationSchema,
  moldPartingLineOperationSchema,
  moldShutoffSurfaceOperationSchema,
  moldPartingSurfaceOperationSchema,
  moldToolingSplitOperationSchema,
]);

/**
 * The kernel-wire ref-slot schema: at RUNTIME it is {@link operationRefWireSchema}
 * (`{ast}`), so a lowered wire ref validates and a raw persisted `{query}` ref is
 * rejected fail-closed; at COMPILE time it presents as the persisted
 * {@link operationRefSchema}. The cast keeps {@link wireOperationSchema} inferring
 * to {@link Operation} — the whole doc→kernel lowering pipeline already types its
 * `{ast}`-shaped output as `Operation` (see `lowerOneOperationRefs`'s
 * `as Operation` in @aeth/document-model), so a genuine parallel wire type would
 * only force that same lie one level up while rippling `KernelRequest` across
 * every transport signature. The two ref schemas are byte-for-byte the same
 * envelope apart from `query`↔`ast` (refs.ts), so nothing but the validated
 * ref-slot shape differs.
 */
const wireOperationRefSchema =
  operationRefWireSchema as unknown as typeof operationRefSchema;

const filletOperationV2WireSchema = filletOperationV2SchemaWith(
  wireOperationRefSchema,
);

const filletOperationWireSchema = z.discriminatedUnion("schemaVersion", [
  filletOperationV1Schema,
  filletOperationV2WireSchema,
]);

const chamferOperationV2WireSchema = chamferOperationV2SchemaWith(
  wireOperationRefSchema,
);

const chamferOperationWireSchema = z.discriminatedUnion("schemaVersion", [
  chamferOperationV1Schema,
  chamferOperationV2WireSchema,
]);

const offsetOperationV2WireSchema = offsetOperationV2SchemaWith(
  wireOperationRefSchema,
);

const offsetOperationWireSchema = z.discriminatedUnion("schemaVersion", [
  offsetOperationV1Schema,
  offsetOperationV2WireSchema,
]);

/**
 * The kernel-WIRE operation schema (N6 slice C). Byte-identical to
 * {@link operationSchema} except every operation type that carries a
 * topology-reference slot validates that slot against the wire `{ast}` form
 * instead of the persisted `{query}` form — the shape the doc→kernel ref
 * lowering (`lowerOperationsForKernel`, @aeth/document-model) actually ships.
 * The slot-free op types are REUSED by reference from `operationSchema`'s
 * members; only the ref-bearing types (fillet v2, chamfer v2, offset v2,
 * datum_plane, datum_axis, shell, mirror, pattern_circular, edge_flange,
 * wire_route, and `sketch` — whose `plane` slot is its only ref) are
 * re-derived from their shared `…SchemaWith` factory with
 * {@link wireOperationRefSchema}, so persisted and wire can never disagree
 * on anything but the ref-slot form.
 *
 * The kernel request validates its `operations` against THIS (kernel-protocol.ts),
 * so a persisted `{query}` op that reaches the wire unlowered is refused at the
 * process boundary rather than silently accepted — the fail-closed transport
 * guarantee (plan 05 §4.2: only the parsed AST crosses the kernel boundary).
 */
export const wireOperationSchema = z.discriminatedUnion("type", [
  sketchOperationSchemaWith(wireOperationRefSchema),
  createBoxOperationSchema,
  createCylinderOperationSchema,
  createSphereOperationSchema,
  createConeOperationSchema,
  createTorusOperationSchema,
  createWedgeOperationSchema,
  createProfileOperationSchema,
  extrudeOperationSchema,
  revolveOperationSchema,
  loftOperationSchema,
  sweepOperationSchema,
  booleanCombineOperationSchema,
  holeOperationSchema,
  boltOperationSchema,
  claspOperationSchema,
  transformOperationSchema,
  offsetOperationWireSchema,
  filletOperationWireSchema,
  chamferOperationWireSchema,
  datumPlaneOperationSchemaWith(wireOperationRefSchema),
  datumAxisOperationSchemaWith(wireOperationRefSchema),
  shellOperationSchemaWith(wireOperationRefSchema),
  mirrorOperationSchemaWith(wireOperationRefSchema),
  patternLinearOperationSchema,
  patternCircularOperationSchemaWith(wireOperationRefSchema),
  importStepOperationSchema,
  importMeshOperationSchema,
  baseFlangeOperationSchema,
  edgeFlangeOperationSchemaWith(wireOperationRefSchema),
  unfoldOperationSchema,
  boundarySurfaceOperationSchema,
  surfaceOffsetOperationSchema,
  stitchOperationSchema,
  thickenOperationSchema,
  wireRouteOperationSchemaWith(wireOperationRefSchema),
  moldPartingLineOperationSchema,
  moldShutoffSurfaceOperationSchema,
  moldPartingSurfaceOperationSchema,
  moldToolingSplitOperationSchema,
]);

/**
 * The single supported document-size envelope: the maximum serialized (UTF-8
 * JSON) byte length of a document's `operations` array.
 *
 * This ONE budget is enforced on the SAME measured quantity at every boundary a
 * document crosses — mutation acceptance (`documentStateSchema` in
 * `@aeth/document-model`), kernel transport (`evaluate_document` /
 * `export_step` requests below), the append-only journal
 * (`defaultMaxJournalRecordBytes` in `@aeth/project-file`), and `.aeth`
 * container read AND write (`aethZipLimits`) — so a document one boundary
 * accepts, every other boundary also accepts. Before this envelope existed,
 * those boundaries advertised mutually contradictory maxima (a 100 000-op count
 * cap, a 4 MiB control frame, a 16 MiB journal record, a 256 MiB writer vs a
 * 128 MiB reader), so a schema-valid document could be un-evaluatable,
 * un-journalable, or written yet un-reopenable.
 *
 * Sized to ride inside the 4 MiB kernel control frame
 * (`@aeth/ipc` `defaultMaxControlFrameBytes`) with over a megabyte of headroom
 * for the request envelope and an `export_step` output path; the
 * `document-size envelope fits the kernel control frame` test in
 * `@aeth/kernel-client` pins that relationship so the constants can never drift
 * apart. The 100 000-operation COUNT cap remains a secondary structural bound;
 * at any realistic per-operation size the byte envelope binds first.
 */
export const maxDocumentOperationsBytes = 3 * 1024 * 1024;

const operationsByteEncoder = new TextEncoder();

/** Serialized (UTF-8 JSON) byte length of an operations array. */
export function operationsSerializedByteLength(
  operations: readonly unknown[],
): number {
  return operationsByteEncoder.encode(JSON.stringify(operations)).byteLength;
}

/** Whether an operations array fits the {@link maxDocumentOperationsBytes} envelope. */
export function operationsWithinEnvelope(
  operations: readonly unknown[],
): boolean {
  return (
    operationsSerializedByteLength(operations) <= maxDocumentOperationsBytes
  );
}

export type Millimeters = z.infer<typeof millimetersSchema>;
export type OperationId = z.infer<typeof operationIdSchema>;
export type BodyId = z.infer<typeof bodyIdSchema>;
export type ProfileId = z.infer<typeof profileIdSchema>;
export type CreateBoxOperation = z.infer<typeof createBoxOperationSchema>;
export type CreateCylinderOperation = z.infer<
  typeof createCylinderOperationSchema
>;
export type CreateSphereOperation = z.infer<typeof createSphereOperationSchema>;
export type CreateConeOperation = z.infer<typeof createConeOperationSchema>;
export type CreateTorusOperation = z.infer<typeof createTorusOperationSchema>;
export type CreateWedgeOperation = z.infer<typeof createWedgeOperationSchema>;
export type ProfileShape = z.infer<typeof profileShapeSchema>;
export type CreateProfileOperation = z.infer<
  typeof createProfileOperationSchema
>;
export type ExtrudeOperation = z.infer<typeof extrudeOperationSchema>;
export type RevolveOperation = z.infer<typeof revolveOperationSchema>;
export type LoftOperation = z.infer<typeof loftOperationSchema>;
export type SweepOperation = z.infer<typeof sweepOperationSchema>;
export type BodyTransform = z.infer<typeof bodyTransformSchema>;
export type TransformOperation = z.infer<typeof transformOperationSchema>;
export type OffsetOperationV1 = z.infer<typeof offsetOperationV1Schema>;
export type OffsetOperationV2 = z.infer<typeof offsetOperationV2Schema>;
export type OffsetOperation = z.infer<typeof offsetOperationSchema>;
export type FilletOperationV1 = z.infer<typeof filletOperationV1Schema>;
export type FilletOperationV2 = z.infer<typeof filletOperationV2Schema>;
export type FilletOperation = z.infer<typeof filletOperationSchema>;
export type ChamferOperationV1 = z.infer<typeof chamferOperationV1Schema>;
export type ChamferOperationV2 = z.infer<typeof chamferOperationV2Schema>;
export type ChamferOperation = z.infer<typeof chamferOperationSchema>;
export type BooleanKind = z.infer<typeof booleanKindSchema>;
export type BooleanCombineOperation = z.infer<
  typeof booleanCombineOperationSchema
>;
export type HoleSize = z.infer<typeof holeSizeSchema>;
export type HolePlacement = z.infer<typeof holePlacementSchema>;
export type HoleOperation = z.infer<typeof holeOperationSchema>;
/* --- fastener-after-snap (staged) types --- */
export type BoltSize = z.infer<typeof boltSizeSchema>;
export type BoltFit = z.infer<typeof boltFitSchema>;
export type BoltHead = z.infer<typeof boltHeadSchema>;
export type BoltOperation = z.infer<typeof boltOperationSchema>;
export type ClaspMaterial = z.infer<typeof claspMaterialSchema>;
export type ClaspRetention = z.infer<typeof claspRetentionSchema>;
export type ClaspOperation = z.infer<typeof claspOperationSchema>;
/* --- catalog-ts-contracts wave 1 types --- */
export type DatumPlaneOperation = z.infer<typeof datumPlaneOperationSchema>;
export type DatumAxisOperation = z.infer<typeof datumAxisOperationSchema>;
export type ShellOperation = z.infer<typeof shellOperationSchema>;
export type MirrorOperation = z.infer<typeof mirrorOperationSchema>;
export type PatternCombine = z.infer<typeof patternCombineSchema>;
export type PatternLinearOperation = z.infer<
  typeof patternLinearOperationSchema
>;
export type PatternCircularOperation = z.infer<
  typeof patternCircularOperationSchema
>;
export type ImportStepOperation = z.infer<typeof importStepOperationSchema>;
export type ImportMeshOperation = z.infer<typeof importMeshOperationSchema>;
/* --- sheet-metal wave 1 types --- */
export type BaseFlangeOperation = z.infer<typeof baseFlangeOperationSchema>;
export type EdgeFlangeOperation = z.infer<typeof edgeFlangeOperationSchema>;
export type UnfoldOperation = z.infer<typeof unfoldOperationSchema>;
/* --- surfacing wave 1 types --- */
export type BoundarySurfaceOperation = z.infer<
  typeof boundarySurfaceOperationSchema
>;
export type SurfaceOffsetOperation = z.infer<
  typeof surfaceOffsetOperationSchema
>;
export type StitchOperation = z.infer<typeof stitchOperationSchema>;
export type ThickenOperation = z.infer<typeof thickenOperationSchema>;
/* --- electrical wave 1 types --- */
export type WireType = z.infer<typeof wireTypeSchema>;
export type WireRouteOperation = z.infer<typeof wireRouteOperationSchema>;
/* --- mold/tooling wave 1 types --- */
export type PullDirection = z.infer<typeof pullDirectionSchema>;
export type MoldPartingLineOperation = z.infer<
  typeof moldPartingLineOperationSchema
>;
export type MoldShutoffSurfaceOperation = z.infer<
  typeof moldShutoffSurfaceOperationSchema
>;
export type MoldPartingSurfaceOperation = z.infer<
  typeof moldPartingSurfaceOperationSchema
>;
export type MoldToolingSplitOperation = z.infer<
  typeof moldToolingSplitOperationSchema
>;
export type Operation = z.infer<typeof operationSchema>;

/**
 * Exhaustive record of every KNOWN operation type. A `Record<Operation["type"],
 * true>` is the single source of truth for the type set: adding a member to the
 * operation union without listing it here fails to compile (missing key), and a
 * stray key that is not a real operation type fails too. {@link knownOperationTypes}
 * derives the runtime set from it so the two can never drift.
 */
const knownOperationTypeRecord: Record<Operation["type"], true> = {
  create_box: true,
  create_cylinder: true,
  create_sphere: true,
  create_cone: true,
  create_torus: true,
  create_wedge: true,
  create_profile: true,
  extrude: true,
  revolve: true,
  loft: true,
  sweep: true,
  boolean_combine: true,
  hole: true,
  bolt: true,
  clasp: true,
  transform: true,
  offset: true,
  fillet: true,
  chamfer: true,
  /* --- catalog-ts-contracts wave 1 --- */
  datum_plane: true,
  datum_axis: true,
  shell: true,
  mirror: true,
  pattern_linear: true,
  pattern_circular: true,
  import_step: true,
  import_mesh: true,
  sketch: true,
  /* --- sheet-metal wave 1 --- */
  base_flange: true,
  edge_flange: true,
  unfold: true,
  /* --- surfacing wave 1 --- */
  boundary_surface: true,
  surface_offset: true,
  stitch: true,
  thicken: true,
  /* --- electrical wave 1 --- */
  wire_route: true,
  /* --- mold/tooling wave 1 --- */
  mold_parting_line: true,
  mold_shutoff_surface: true,
  mold_parting_surface: true,
  mold_tooling_split: true,
};

/** The set of operation `type` discriminants this build understands. */
export const knownOperationTypes: ReadonlySet<string> = new Set(
  Object.keys(knownOperationTypeRecord),
);

/**
 * Operation types whose TS contracts are LANDED but which are NOT yet ready to
 * offer to the agent's model-facing wire toolset, because they cannot execute
 * end-to-end over `evaluate_document` today. The precise kernel boundary is
 * per-type (pinned by kernel-client's catalog-wave1 native suite):
 *
 * - `shell` executes real geometry over the wire in BOTH scopes. The claim that
 *   `openFaces` still refuses expired with CAP-013, which landed the ByJoin
 *   execution and its history fixtures.
 * - `datum_plane` / `datum_axis` execute over the wire and their minted
 *   synthetic entities are now RESOLVABLE (CAP-014). The claim that
 *   `evaluate_document` does not thread the registry expired at N6 slice C part
 *   3, and the follow-on claim that the minted entity could not be referenced
 *   expired with CAP-014: a datum plane resolves under a `faces` head, a datum
 *   axis under `edges`, and a mirror consumes one. They stay in this set for
 *   the ordinary reason — agent-wire enablement is a separate deliberate act,
 *   and the user path is the UI verb, which needs no wire flip.
 * - `mirror` / `pattern_linear` / `pattern_circular` LEFT this set on
 *   2026-07-26 (founder-directed, `gov/agent-wire-unstaging`). A bullet here
 *   used to claim they refuse over the wire; that was pre-N6 — since N6 slice C
 *   the kernel auto-engages the naming registry for any selector-carrying
 *   document, and their wire execution is pinned by kernel-client's catalog
 *   wave 2 case plus the CAP-007/CAP-008 packaged gates. Their enablement is
 *   what forced the ref-slot anchors compaction and the re-measured budget pins
 *   (`@aeth/agent-contracts` wire-toolset test, design note §3).
 *
 * `bolt` and `clasp` are NOT in this set: they are enabled by a different
 * mechanism than a native executor. Each carries semantic hardware the kernel has
 * no tables for, so both authoring paths LOWER it to a concrete primitive
 * subgraph the kernel already executes, immediately before `evaluate_document`
 * (`@aeth/document-model` `lowerFastenerOperations`, applied by both the desktop
 * feed and the agent's `KernelDocumentPort`) — a bolt to hole/cone-cut geometry,
 * a clasp to a beam-box + hook-wedge union. The kernel therefore never sees a raw
 * bolt or clasp — one that reached it would hit the dispatch-`else` refusal, the
 * same fail-closed guard as any unexecutable op — so enabling them was safe once
 * both feeds lowered them. The clasp is v1 single-body (the ADR-013-gated mating
 * catch is a follow-up, not a staging gate).
 *
 * Documents carrying any of them are editable (they are known types — Gate 9
 * unknown-op degradation does not apply). Removing a type from this set is the
 * deliberate enablement act: it auto-enrolls the tool in the wire surface,
 * whose budget pins then force the ref-slot compaction decision recorded in
 * docs/design/2026-07-19-toolset-compaction.md.
 *
 * This is ONLY the catalog-wave enablement ledger, and it is SIDECAR-surface
 * policy: it exists to hold that surface's measured token pins, so a surface
 * with no such budget (`@aeth/agent-contracts` `frontierToolNames`, the MCP
 * surface a 200k-context frontier agent sees) deliberately does NOT apply it.
 * The complete set of types kept off the SIDECAR wire surface is
 * {@link modelExcludedOperationTypes}, which also carries the permanently
 * {@link nonAuthorableOperationTypes} (`import_step`, `import_mesh`) — those
 * are off EVERY surface, for a reason that has nothing to do with budget.
 *
 * 2026-08-04 (sheet-metal wave 1): `base_flange`, `edge_flange`, and `unfold`
 * JOIN the set from day one. Their TS contracts land in the same change as —
 * but from a workstream independent of — the native kernel dispatch for
 * these three types, so regardless of which side lands first, a model call
 * fails closed with `UNSUPPORTED_OPERATION` until BOTH sides are measured
 * working together and someone makes the deliberate call to un-stage them.
 * Brand new native geometry gets the exact same fail-closed-for-agents-
 * until-proven treatment `shell` got when it was new — nothing less because
 * the geometry is new, nothing more because a second team is racing to land
 * the kernel side.
 *
 * 2026-08-04 (surfacing wave 1): `boundary_surface`, `surface_offset`,
 * `stitch`, and `thicken` JOIN the set from day one, for the identical
 * reason and on the identical schedule as sheet-metal wave 1 immediately
 * above — a second, concurrent workstream lands the native kernel dispatch
 * for these four types against the same field names, and until BOTH sides
 * are measured working together a model call fails closed with
 * `UNSUPPORTED_OPERATION` rather than either side guessing the other is
 * ready.
 *
 * 2026-08-04 (electrical wave 1): `wire_route` JOINS the set from day one,
 * for the identical reason as both waves immediately above — a concurrent,
 * independent workstream lands the native kernel dispatch for this one
 * type against the same field names, and until BOTH sides are measured
 * working together a model call fails closed with `UNSUPPORTED_OPERATION`
 * rather than either side guessing the other is ready.
 *
 * 2026-08-05 (mold/tooling wave 1): `mold_parting_line`,
 * `mold_shutoff_surface`, `mold_parting_surface`, and `mold_tooling_split`
 * JOIN the set from day one, for the identical reason as every wave
 * above — a concurrent, independent workstream lands the native kernel
 * dispatch for these four types against the same field names, and until
 * BOTH sides are measured working together a model call fails closed with
 * `UNSUPPORTED_OPERATION` rather than either side guessing the other is
 * ready. (`mold_draft_analysis` is NOT a member of this set: it is not an
 * operation at all — a read-only top-level kernel RPC method, a sibling to
 * `simulate`/`hlr_project`, that never appears in this file's operation
 * union in the first place. See its schema in `kernel-protocol-core.ts`.)
 */
export const stagedOperationTypes: ReadonlySet<Operation["type"]> = new Set([
  "datum_plane",
  "datum_axis",
  "shell",
  // 2026-07-27 (CAP-034), and this member is here for a DIFFERENT reason than
  // the others. `offset` executes for real — planar targets, both directions,
  // fixture-pinned history. It is staged purely for wire BUDGET: its v2 `face`
  // ref slot costs 148 tokens on the model-facing surface, which puts
  // `propose_transaction` at 2417 against a 2269 pin that was set at the
  // measured minimum by the agent-wire un-staging repair. Moving that pin
  // would shrink the assemblable-document budget (80 -> 47 operations at the
  // default window), so the manager ruled: stage the type instead.
  //
  // Consequences, stated so nobody mistakes this for "not built": the verb
  // ships to users by hand and IS reachable; no shipped model consumes the
  // wire until CAP-022/023, so the agent cost today is zero; and un-staging is
  // a one-line set edit plus a pin re-measure. The real fix is dynamic
  // per-run tool-sets (recorded, and now the forcing function three capabilities
  // deep) — at which point this entry should go.
  "offset",
  // 2026-07-27 (CAP-035 piece 1). The strongest reason in this set: `sketch`
  // has NO kernel executor at all. Its schema landed as a §4 seam so the
  // vendored solver, the entity UI and the drag-solve loop could each be built
  // and reviewed separately, and split piece 2 lands the executor.
  //
  // Until then a `sketch` reaching `evaluate_document` would hit a dispatch arm
  // that does not exist. Staging it is the FAIL-CLOSED pin — the same shape
  // CAP-012 used for `offset` before its executor existed: a typed refusal at
  // the wire boundary rather than an unhandled type deep in the kernel.
  // Remove this entry in the piece that lands the executor, not before.
  "sketch",
  // 2026-08-04: sheet-metal wave 1. See the doc comment above this set for
  // why all three join together, from day one, regardless of which side —
  // this TS contract or the concurrent native kernel dispatch — lands first.
  "base_flange",
  "edge_flange",
  "unfold",
  // 2026-08-04: surfacing wave 1. Same day, same reasoning, same schedule —
  // see the doc comment above this set.
  "boundary_surface",
  "surface_offset",
  "stitch",
  "thicken",
  // 2026-08-04: electrical wave 1. Same day, same reasoning, same schedule —
  // see the doc comment above this set.
  "wire_route",
  // 2026-08-05: mold/tooling wave 1. Same reasoning, same day-one schedule —
  // see the doc comment above this set.
  "mold_parting_line",
  "mold_shutoff_surface",
  "mold_parting_surface",
  "mold_tooling_split",
] as const);

/**
 * Operation types NO model may author on ANY surface, ever — the permanent,
 * non-budget half of {@link modelExcludedOperationTypes}.
 *
 * `import_step` and `import_mesh` EXECUTE end-to-end (their native executors
 * read the retained STEP / checked mesh into a real body), so this is NOT a
 * staging or budget exclusion and it never expires: the geometry is a
 * PRESERVED FILE the model cannot synthesize, and no agent — a 4B sidecar or a
 * 200k-context frontier model — types megabytes of Part-21 text or a base64
 * mesh payload into a tool call. Both are authored exclusively by the desktop
 * import flow (manufacturing-import.ts).
 *
 * Kept SEPARATE from {@link stagedOperationTypes} because the two exclusions
 * have nothing in common but their current effect. Staging is a per-surface
 * budget/enablement decision that a surface with room may decline to apply
 * (`@aeth/agent-contracts` `frontierToolNames` does exactly that); this set is
 * a property of the operations themselves, so EVERY model-facing surface
 * subtracts it. A new surface that filters only by staging is a bug; one that
 * filters only by this set is a deliberate choice about budget.
 */
export const nonAuthorableOperationTypes: ReadonlySet<Operation["type"]> =
  new Set<Operation["type"]>(["import_step", "import_mesh"]);

/**
 * Operation types the agent's SIDECAR wire toolset OMITS — the set the local
 * small model's wire surface filters by (`@aeth/agent-contracts`
 * `wireToolNames` and the `propose_transaction` operation union). A tool that
 * model can never usefully call is context noise and repair-loop bait, so it
 * stays out of the emitted surface while remaining a fully known, editable
 * operation. Two DISJOINT reasons put a type here, and they are now carried by
 * two separate sets so nothing conflates them:
 *
 * 1. **Catalog-wave staging** — every {@link stagedOperationTypes} member. Read
 *    the rationale there: it is a per-surface budget and enablement ledger, not
 *    a statement that the operation is unauthorable.
 * 2. **Never authorable** — every {@link nonAuthorableOperationTypes} member
 *    (`import_step`, `import_mesh`), a PERMANENT exclusion on every surface.
 *
 * This union is the SIDECAR surface's filter specifically. The MCP/frontier
 * surface (`@aeth/agent-contracts` `frontierToolNames` /
 * `buildFrontierAuthoringToolset`) subtracts only reason 2, because reason 1
 * exists solely to hold the sidecar's measured token pins and a 200k-context
 * agent has no such constraint. Do not reach for this set from a surface that
 * is not budget-constrained.
 *
 * The registry entry (`operationToolRegistry`) and description stay
 * compile-required for every excluded type, so the toolset code, attribution,
 * and validation still cover them; only their emission to the model is dropped.
 */
export const modelExcludedOperationTypes: ReadonlySet<Operation["type"]> =
  new Set<Operation["type"]>([
    ...stagedOperationTypes,
    ...nonAuthorableOperationTypes,
  ]);

/**
 * A persisted operation whose `type` this build does NOT understand — an
 * operation authored by a NEWER build (Gate 9, MASTER_PLAN §5: "unknown ops
 * degrade visibly, never discard the graph"). Its raw payload is preserved
 * byte-for-byte (`looseObject` keeps every field) so a save round-trips it back
 * to the newer build intact. Only genuinely unknown types qualify: a `type` in
 * {@link knownOperationTypes} must satisfy its typed schema, so a MALFORMED known
 * operation still fails rather than degrading to "unknown" (corruption is not
 * forward-compatibility). An `id` is still required — the document's identity
 * namespaces (op id / body id / profile id uniqueness) span unknown ops too.
 *
 * Unknown operations enter a document ONLY through a load boundary
 * (`documentStateSchema` parse on `.aeth` read / journal replay); the running
 * editor never mints one (live mutations parse with the closed `operationSchema`),
 * and a document that contains one opens read-only.
 */
export const unknownOperationSchema = z
  .looseObject({
    id: operationIdSchema,
    type: z.string().min(1).max(128),
  })
  .refine((operation) => !knownOperationTypes.has(operation.type), {
    message:
      "A known operation type must satisfy its typed schema; only genuinely unknown types are preserved as unknown operations",
    path: ["type"],
  });

export type UnknownOperation = z.infer<typeof unknownOperationSchema>;

/**
 * The element type of a PERSISTED document's `operations` array: a fully typed
 * known {@link Operation}, or an {@link UnknownOperation} carried forward from a
 * newer build. `operationSchema` is tried first (a known type must be valid);
 * only a genuinely unknown type falls through to the preserving branch.
 */
export const persistedOperationSchema = z.union([
  operationSchema,
  unknownOperationSchema,
]);

export type PersistedOperation = z.infer<typeof persistedOperationSchema>;

/** Whether a persisted operation is one this build does not understand. */
export function isUnknownOperation(
  operation: PersistedOperation,
): operation is UnknownOperation {
  return !knownOperationTypes.has(operation.type);
}

/**
 * Whether a persisted operation is a fully typed {@link Operation} this build
 * understands. The type-guard complement of {@link isUnknownOperation}: use it
 * to narrow a persisted `operations` array to the known ops before an execution
 * boundary (kernel evaluation, tessellation) that cannot process an unknown op.
 * The unknown ops are still carried in the document (Gate 9 — never discarded)
 * and surfaced as a visible read-only/degraded state elsewhere.
 */
export function isKnownOperation(
  operation: PersistedOperation,
): operation is Operation {
  return knownOperationTypes.has(operation.type);
}
