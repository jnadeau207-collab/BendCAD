import { z } from "zod";

import {
  aembFormatSchema,
  boundingBoxMmSchema,
  meshDescriptorSchema,
} from "./mesh-payload.js";
import {
  draftAngleToleranceDegSchema,
  maxDocumentOperationsBytes,
  operationsSerializedByteLength,
  pullDirectionSchema,
  wireOperationSchema,
} from "./operations.js";
import { referenceEntityKindSchema, topologyTokenSchema } from "./refs.js";
import {
  sketchConstraintIdSchema,
  sketchConstraintSchema,
  sketchEntityIdSchema,
  sketchEntitySchema,
  sketchSolutionSchema,
} from "./sketch.js";
import { selectorQuerySchema } from "./selector-ast.js";
import {
  entityKindSchema,
  topologySelectionEvidenceSchema,
  topologySnapshotSchema,
} from "./topology.js";

export const kernelProtocolVersion = 3 as const;

const requestBase = {
  protocolVersion: z.literal(kernelProtocolVersion),
  requestId: z.string().uuid(),
} as const;

const documentEvaluationFields = {
  documentId: z.string().uuid(),
  revision: z.number().int().nonnegative(),
  // Operations are validated against the WIRE schema (N6 slice C): every request
  // that carries the operations array (evaluate_document / export_step /
  // export_mesh / query) receives them AFTER the doc→kernel ref lowering
  // (`lowerOperationsForKernel`, @aeth/document-model) has rewritten each ref
  // slot's persisted `{query}` to the wire `{ast}`. Validating with
  // `wireOperationSchema` means a lowered `{ast}` op passes while a persisted
  // `{query}` op that reached the wire UNLOWERED is refused at the process
  // boundary — the fail-closed transport guarantee (plan 05 §4.2: only the parsed
  // AST crosses the kernel-host boundary). Slot-free ops (a box, a hole) are
  // byte-identical under both schemas.
  operations: z.array(wireOperationSchema).max(100_000),
} as const;

/**
 * Per-op wall-clock timeout the kernel host enforces (Wave 2.1 slice 3b; plan 06
 * §7). These MIRROR the native `OpTimeoutForMethod` literals — a drift makes the
 * queue and kernel budgets disagree, so `kernel-protocol.test.ts` pins the
 * request-deadline reconciliation and the native op-timeout path uses the same
 * numbers.
 */
export const kernelExportOperationTimeoutMs = 120_000 as const;
export const kernelDefaultOperationTimeoutMs = 30_000 as const;
/** Supervisor escalation window beyond a per-op deadline (plan 06 §7/§10). */
export const kernelTimeoutEscalationMarginMs = 15_000 as const;

/** The per-op wall-clock cap the kernel applies to `method`. */
export function kernelOperationTimeoutMs(method: string): number {
  return method === "export_step" || method === "export_mesh"
    ? kernelExportOperationTimeoutMs
    : kernelDefaultOperationTimeoutMs;
}

/**
 * The per-REQUEST deadline a `KernelRequestQueue` submission must allow for
 * `method` so the kernel's cooperative per-op TIMEOUT returns a clean, attributed
 * error BEFORE the queue's blunt submission deadline fires its cancel/restart
 * escalation (finding 2). Strictly greater than the per-op cap PLUS the
 * escalation margin, with equal headroom on top. The default 30 000 ms queue
 * deadline is shorter than the 30 000 ms eval cap (and far shorter than the
 * 120 000 ms export cap), so exports could never surface the attributed TIMEOUT
 * until callers use this budget.
 */
export function kernelRequestDeadlineMs(method: string): number {
  return (
    kernelOperationTimeoutMs(method) +
    kernelTimeoutEscalationMarginMs +
    kernelTimeoutEscalationMarginMs
  );
}

const positiveMillimetres = z.number().finite().positive();

/**
 * First reference-mutation fixture: a box split by a vertical plane whose
 * normal is a horizontal axis at a parameterized offset. Additive protocol
 * surface; the response separates entrant-visible snapshots from the
 * history-derived oracle.
 *
 * Scope: the open (0, 1) offsetFraction domain deliberately makes a split
 * plane that contains existing box topology (a vertex, edge, or face)
 * impossible for this fixture — that is a fixture limitation, not an oracle
 * guarantee, and a dedicated fixture is required before strata that can
 * produce plane-through-existing-topology.
 */
export const planarSplitFixtureSchema = z
  .object({
    kind: z.literal("planar-split"),
    box: z
      .object({
        width: positiveMillimetres,
        depth: positiveMillimetres,
        height: positiveMillimetres,
      })
      .strict(),
    plane: z
      .object({
        axis: z.enum(["x", "y"]),
        offsetFraction: z.number().gt(0).lt(1),
      })
      .strict(),
    baseOperationId: z.string().uuid(),
    splitOperationId: z.string().uuid(),
  })
  .strict();
export type PlanarSplitFixture = z.infer<typeof planarSplitFixtureSchema>;

/**
 * The fillet fixture never allows the radius to reach the geometric maximum
 * for the two faces adjacent to the filleted edge (min(width, depth), where
 * the trimmed neighbour degenerates to zero extent and the fillet surface
 * becomes tangent to the opposite boundary). Mirroring the split fixture's
 * open (0, 1) offset domain, the radius is capped at this fraction of
 * min(width, depth), so degenerate-tangency and face-consuming fillets are a
 * fixture-domain exclusion, not a proven oracle robustness.
 */
export const filletRadiusMaximumFraction = 0.8 as const;

/**
 * Second reference-mutation fixture: a box with one vertical edge replaced by
 * a constant-radius fillet. Additive protocol surface; the response separates
 * entrant-visible snapshots from the history-derived oracle.
 *
 * Coordinate contract (millimetres): the box occupies
 * [0, width] x [0, depth] x [0, height], exactly as the kernel host builds it.
 * The filleted edge is the single vertical edge (parallel to Z, spanning
 * z in [0, height]) at x = 0 for `edge.xSide` "min" or x = width for "max",
 * and y = 0 for `edge.ySide` "min" or y = depth for "max". The kernel selects
 * that edge by its two vertex coordinates and fails the request unless exactly
 * one box edge matches.
 *
 * Scope: `filletRadiusMaximumFraction` keeps the radius strictly below the
 * geometric maximum min(width, depth) with a safety margin; radius values at
 * or beyond the cap (degenerate tangency, a fillet consuming an adjacent face
 * or the whole box corner) are structurally impossible for this fixture. That
 * is a fixture-domain limitation, not an oracle guarantee, and a dedicated
 * fixture is required before strata that can produce fillet-consumes-topology
 * results.
 */
export const filletFixtureSchema = z
  .object({
    kind: z.literal("fillet"),
    box: z
      .object({
        width: positiveMillimetres,
        depth: positiveMillimetres,
        height: positiveMillimetres,
      })
      .strict(),
    fillet: z
      .object({
        radius: positiveMillimetres,
        edge: z
          .object({
            xSide: z.enum(["min", "max"]),
            ySide: z.enum(["min", "max"]),
          })
          .strict(),
      })
      .strict(),
    baseOperationId: z.string().uuid(),
    filletOperationId: z.string().uuid(),
  })
  .strict()
  .superRefine((value, context) => {
    const maximumRadius =
      filletRadiusMaximumFraction * Math.min(value.box.width, value.box.depth);
    if (value.fillet.radius > maximumRadius) {
      context.addIssue({
        code: "custom",
        message:
          "fillet radius must stay at or below " +
          `${filletRadiusMaximumFraction} x min(width, depth)`,
      });
    }
  });
export type FilletFixture = z.infer<typeof filletFixtureSchema>;

/**
 * Shared clearance rule for the boss-based construction-correspondence
 * fixtures below: every cylindrical feature must clear the box top-face
 * boundary and every other feature footprint by at least this fraction of its
 * own radius. Mirroring the split fixture's open (0, 1) offset domain and the
 * fillet radius cap, this makes tangent, overlapping, or boundary-crossing
 * feature footprints structurally impossible for these fixtures — a
 * fixture-domain exclusion, not an oracle robustness guarantee.
 */
export const bossClearanceMinimumFraction = 0.25 as const;

/**
 * Third reference-mutation fixture: a box with a linear array of cylindrical
 * bosses fused onto its top face in ONE General-Fuse evaluation, re-evaluated
 * with the instance count changed by exactly one. Additive protocol surface;
 * the response separates entrant-visible snapshots from the oracle.
 *
 * Coordinate contract (millimetres): the box occupies
 * [0, width] x [0, depth] x [0, height]. Instance i (0-based) is a vertical
 * cylinder of the given radius/height whose base disc sits on the top face at
 * (firstCenterX + i * pitch, centerY, height).
 *
 * ORACLE CLASS — construction correspondence, NOT single-run algorithm
 * history: the before and after states are two INDEPENDENT evaluations (a
 * parameter change forces full re-evaluation), so no algorithm history can
 * relate them. Each evaluation instead records, through its own fuse history
 * composed with the deterministic construction (instance i's tool shape),
 * which result entities belong to the base and which to each instance;
 * correspondence across evaluations is then by construction identity
 * (base <-> base, instance i <-> instance i for i < min(N, N')), refined
 * where a construction parent alone is ambiguous by topological incidence
 * with already-corresponded entities. Never geometric similarity. Per
 * ADR-005 this is a semantic oracle class that requires human adversarial
 * review; corpora built on it must stay `qualificationEligible: false` until
 * that review clears.
 */
export const linearPatternFixtureSchema = z
  .object({
    kind: z.literal("linear-pattern"),
    box: z
      .object({
        width: positiveMillimetres,
        depth: positiveMillimetres,
        height: positiveMillimetres,
      })
      .strict(),
    boss: z
      .object({
        radius: positiveMillimetres,
        height: positiveMillimetres,
      })
      .strict(),
    layout: z
      .object({
        firstCenterX: positiveMillimetres,
        centerY: positiveMillimetres,
        pitch: positiveMillimetres,
      })
      .strict(),
    instanceCount: z
      .object({
        before: z.number().int().min(2).max(6),
        after: z.number().int().min(1).max(7),
      })
      .strict(),
    baseOperationId: z.string().uuid(),
    arrayOperationId: z.string().uuid(),
  })
  .strict()
  .superRefine((value, context) => {
    if (
      Math.abs(value.instanceCount.before - value.instanceCount.after) !== 1
    ) {
      context.addIssue({
        code: "custom",
        message: "instance count must change by exactly one",
      });
    }
    const radius = value.boss.radius;
    const clearance = bossClearanceMinimumFraction * radius;
    if (value.layout.pitch < 2 * radius + clearance) {
      context.addIssue({
        code: "custom",
        message: "adjacent instances must clear each other by the minimum",
      });
    }
    const maxCount = Math.max(
      value.instanceCount.before,
      value.instanceCount.after,
    );
    const lastCenterX =
      value.layout.firstCenterX + (maxCount - 1) * value.layout.pitch;
    if (
      value.layout.firstCenterX - radius < clearance ||
      value.box.width - (lastCenterX + radius) < clearance ||
      value.layout.centerY - radius < clearance ||
      value.box.depth - (value.layout.centerY + radius) < clearance
    ) {
      context.addIssue({
        code: "custom",
        message:
          "every instance footprint must clear the top-face boundary by the minimum",
      });
    }
  });
export type LinearPatternFixture = z.infer<typeof linearPatternFixtureSchema>;

/**
 * Fourth reference-mutation fixture: a box with a cylindrical boss fused onto
 * its top face and a vertical through-hole cut clear of the boss, re-evaluated
 * WITHOUT the boss operation (the document suppresses that feature). Additive
 * protocol surface; the response separates entrant-visible snapshots from the
 * oracle.
 *
 * Coordinate contract (millimetres): the box occupies
 * [0, width] x [0, depth] x [0, height]. The boss is a vertical cylinder whose
 * base disc sits on the top face at (boss.center.x, boss.center.y, height).
 * The hole is cut by a vertical cylinder centred at
 * (hole.center.x, hole.center.y) spanning strictly beyond [0, height], so it
 * pierces the top and bottom faces. Boss and hole footprints are disjoint by
 * the shared clearance rule.
 *
 * ORACLE CLASS — the same construction-correspondence oracle as the
 * linear-pattern fixture (two independent evaluations, per-evaluation
 * histories composed across the fuse and cut via BRepTools_History::Merge,
 * correspondence by construction identity plus incidence refinement). The
 * same ADR-005 human-review requirement applies; corpora stay
 * `qualificationEligible: false`.
 */
export const bossSuppressionFixtureSchema = z
  .object({
    kind: z.literal("boss-suppression"),
    box: z
      .object({
        width: positiveMillimetres,
        depth: positiveMillimetres,
        height: positiveMillimetres,
      })
      .strict(),
    boss: z
      .object({
        radius: positiveMillimetres,
        height: positiveMillimetres,
        center: z
          .object({ x: positiveMillimetres, y: positiveMillimetres })
          .strict(),
      })
      .strict(),
    hole: z
      .object({
        radius: positiveMillimetres,
        center: z
          .object({ x: positiveMillimetres, y: positiveMillimetres })
          .strict(),
      })
      .strict(),
    baseOperationId: z.string().uuid(),
    bossOperationId: z.string().uuid(),
    holeOperationId: z.string().uuid(),
  })
  .strict()
  .superRefine((value, context) => {
    const inTopFace = (
      center: Readonly<{ x: number; y: number }>,
      radius: number,
    ): boolean => {
      const clearance = bossClearanceMinimumFraction * radius;
      return (
        center.x - radius >= clearance &&
        value.box.width - (center.x + radius) >= clearance &&
        center.y - radius >= clearance &&
        value.box.depth - (center.y + radius) >= clearance
      );
    };
    if (!inTopFace(value.boss.center, value.boss.radius)) {
      context.addIssue({
        code: "custom",
        message: "boss footprint must clear the top-face boundary",
      });
    }
    if (!inTopFace(value.hole.center, value.hole.radius)) {
      context.addIssue({
        code: "custom",
        message: "hole footprint must clear the top-face boundary",
      });
    }
    const distance = Math.hypot(
      value.boss.center.x - value.hole.center.x,
      value.boss.center.y - value.hole.center.y,
    );
    const clearance =
      bossClearanceMinimumFraction *
      Math.max(value.boss.radius, value.hole.radius);
    if (distance < value.boss.radius + value.hole.radius + clearance) {
      context.addIssue({
        code: "custom",
        message:
          "boss and hole footprints must clear each other by the minimum",
      });
    }
  });
export type BossSuppressionFixture = z.infer<
  typeof bossSuppressionFixtureSchema
>;

/**
 * Shared clearance rule for the merge fixture below: the tool box's
 * cross-section (perpendicular to the piercing axis) must clear the target
 * box's boundary on that cross-section by this fraction of the tool's own
 * depth/height, and the tool's extent along the piercing axis must both start
 * and end at least this fraction of the tool's own width clear of the
 * target's boundary on that axis. Mirroring the split fixture's open (0, 1)
 * offset domain, the fillet radius cap, and the boss clearance fraction, this
 * makes every argument face plane coincide with another (glued faces)
 * structurally impossible, makes tangency (a near-zero embedding or
 * protrusion depth) structurally impossible, and — because the pierced
 * cross-section never reaches the target's own face boundary — makes the
 * piercing hole always a single interior loop rather than an edge-touching
 * notch whose classification would be ambiguous, and guarantees every
 * trimmed argument face remains one connected remainder (never splits into
 * several same-kind pieces). A fixture-domain exclusion, not an oracle
 * robustness guarantee.
 */
export const mergeClearanceMinimumFraction = 0.2 as const;

/**
 * Fifth reference-mutation fixture: a "target" box and a "tool" box fused in
 * ONE BRepAlgoAPI_Fuse run. Unlike the linear-pattern box+cylinder fuse, BOTH
 * arguments are real bodies with their own before-state topology and
 * provenance (mirroring how a document-level boolean_combine merges two
 * independent bodies): the before snapshot is a compound of both solids.
 * Additive protocol surface; the response separates entrant-visible
 * snapshots from the history-derived oracle.
 *
 * ORACLE CLASS — SINGLE-RUN ALGORITHM HISTORY, the SAME class as
 * "planar-split": BRepAlgoAPI_Fuse with SetToFillHistory(true) produces one
 * General-Fuse History() covering both argument solids, which is fed to the
 * identical, unmodified history-derived oracle (IsRemoved/Modified/Generated)
 * — no construction-correspondence re-evaluation, no ADR-005 human-review
 * requirement.
 *
 * Coordinate contract (millimetres): the target box occupies
 * [0, target.width] x [0, target.depth] x [0, target.height], exactly as
 * every other fixture's box. The tool box occupies
 * [tool.placement.originX, tool.placement.originX + tool.width] x
 * [tool.placement.originY, tool.placement.originY + tool.depth] x
 * [tool.placement.originZ, tool.placement.originZ + tool.height] — the tool
 * pierces the target's max-X face, embedded inside the target along X for
 * part of its width and protruding beyond it for the rest, while its Y and Z
 * cross-section stays strictly interior to the target's Y/Z extent.
 *
 * Scope: `mergeClearanceMinimumFraction` keeps the tool's cross-section clear
 * of the target's Y/Z boundary and keeps the tool's embedding/protrusion
 * depth along X clear of the target's X boundary, both with a safety margin;
 * see the constant's own documentation for the pathologies this rules out.
 * That is a fixture-domain limitation, not an oracle guarantee, and a
 * dedicated fixture is required before strata that can produce
 * coincident-face or edge-touching merges.
 */
export const mergeFixtureSchema = z
  .object({
    kind: z.literal("merge"),
    target: z
      .object({
        width: positiveMillimetres,
        depth: positiveMillimetres,
        height: positiveMillimetres,
      })
      .strict(),
    tool: z
      .object({
        width: positiveMillimetres,
        depth: positiveMillimetres,
        height: positiveMillimetres,
        placement: z
          .object({
            originX: positiveMillimetres,
            originY: positiveMillimetres,
            originZ: positiveMillimetres,
          })
          .strict(),
      })
      .strict(),
    targetOperationId: z.string().uuid(),
    toolOperationId: z.string().uuid(),
    mergeOperationId: z.string().uuid(),
    /**
     * Additive fuse-argument-order knob; "target-first" when absent. The
     * fused solid is identical either way — the knob changes only which
     * argument list each solid enters the Boolean through, and the before
     * snapshot, provenance, and oracle contracts are unchanged. It exists so
     * the element-name channel's section names can be PROVEN commutative
     * (invariant under an argument-order flip) against the real kernel
     * instead of by construction-time assertion.
     */
    argumentOrder: z.enum(["target-first", "tool-first"]).optional(),
  })
  .strict()
  .superRefine((value, context) => {
    const { target, tool } = value;
    const { originX, originY, originZ } = tool.placement;

    const crossClearanceY = mergeClearanceMinimumFraction * tool.depth;
    if (
      originY < crossClearanceY ||
      target.depth - (originY + tool.depth) < crossClearanceY
    ) {
      context.addIssue({
        code: "custom",
        message: "merge tool footprint must clear the target depth boundary",
      });
    }
    const crossClearanceZ = mergeClearanceMinimumFraction * tool.height;
    if (
      originZ < crossClearanceZ ||
      target.height - (originZ + tool.height) < crossClearanceZ
    ) {
      context.addIssue({
        code: "custom",
        message: "merge tool footprint must clear the target height boundary",
      });
    }
    const pierceClearance = mergeClearanceMinimumFraction * tool.width;
    if (originX < pierceClearance || target.width - originX < pierceClearance) {
      context.addIssue({
        code: "custom",
        message:
          "merge tool must be embedded clear of the target width boundary",
      });
    }
    if (originX + tool.width - target.width < pierceClearance) {
      context.addIssue({
        code: "custom",
        message:
          "merge tool must protrude clear beyond the target width boundary",
      });
    }
  });
export type MergeFixture = z.infer<typeof mergeFixtureSchema>;

/**
 * The STEP-interchange fixtures' rectangular through-opening must clear the
 * slab boundary — and, in the import-cut fixture, the corner notch — by this
 * fraction of the opening's own width/depth on the respective axis. Keeping
 * every cut plane strictly separated from every pre-existing plane makes
 * coplanar-face gluing, tangency, and edge-touching loops structurally
 * impossible: a fixture-domain exclusion, not an oracle robustness
 * guarantee. Mirrored by `kOpeningClearanceMinimumFraction` in
 * native/kernel-host/src/mutation.cpp.
 */
export const openingClearanceMinimumFraction = 0.25 as const;

/**
 * The import-cut fixture's corner notch spans at most this fraction of the
 * slab's width/depth, bounding it away from the far corners. Mirrored by
 * `kNotchMaximumFraction` in native/kernel-host/src/mutation.cpp.
 */
export const notchMaximumFraction = 0.4 as const;

const slabSchema = z
  .object({
    width: positiveMillimetres,
    depth: positiveMillimetres,
    height: positiveMillimetres,
  })
  .strict();

const openingSchema = z
  .object({
    originX: positiveMillimetres,
    originY: positiveMillimetres,
    width: positiveMillimetres,
    depth: positiveMillimetres,
  })
  .strict();

function validateSlabOpening(
  value: {
    slab: { width: number; depth: number };
    opening: { originX: number; originY: number; width: number; depth: number };
  },
  context: z.RefinementCtx,
): void {
  const clearanceX = openingClearanceMinimumFraction * value.opening.width;
  if (
    value.opening.originX < clearanceX ||
    value.slab.width - (value.opening.originX + value.opening.width) <
      clearanceX
  ) {
    context.addIssue({
      code: "custom",
      message: "opening must clear the slab width boundary by the minimum",
    });
  }
  const clearanceY = openingClearanceMinimumFraction * value.opening.depth;
  if (
    value.opening.originY < clearanceY ||
    value.slab.depth - (value.opening.originY + value.opening.depth) <
      clearanceY
  ) {
    context.addIssue({
      code: "custom",
      message: "opening must clear the slab depth boundary by the minimum",
    });
  }
}

/**
 * One "step-reimport" mutation case: an all-planar slab
 * ([0, width] x [0, depth] x [0, height]) pierced by one rectangular
 * through-opening along Z is built, serialized to a private temporary STEP
 * file ONCE, and read back TWICE through the production reader. Before and
 * after snapshot the two independently transferred shapes; the construction
 * that produced the bytes never reaches the case, so both sides carry only
 * `sourceOperationId`'s provenance — exactly what a real import looks like.
 *
 * ORACLE CLASS — serialization-identity correspondence, NOT single-run
 * algorithm history: no history spans a serialization boundary, and an
 * import has no construction program of its own. The declared premise is
 * that a deterministic reader constructs the identical shape from identical
 * bytes, so equal per-kind enumeration indices denote the same entity; the
 * kernel VERIFIES that premise per case (counts, geometry class, measure,
 * centroid within serialization tolerance) and fails the request on any
 * disagreement instead of guessing. Emits only stable-single truths. Like
 * the construction-correspondence class this is a declared-truth oracle
 * requiring ADR-005 human adversarial review; corpora built on it must stay
 * `qualificationEligible: false` until that review clears.
 *
 * The all-planar geometry is deliberate: planes round-trip STEP without
 * periodic-surface seam ambiguity, so serialization itself can never
 * manufacture or destroy topology (the congruence is still asserted, never
 * assumed).
 */
export const stepReimportFixtureSchema = z
  .object({
    kind: z.literal("step-reimport"),
    slab: slabSchema,
    opening: openingSchema,
    sourceOperationId: z.string().uuid(),
  })
  .strict()
  .superRefine(validateSlabOpening);
export type StepReimportFixture = z.infer<typeof stepReimportFixtureSchema>;

/**
 * One "step-import-cut" mutation case: the same pierced slab is serialized
 * and read back ONCE, then a full-height corner notch
 * ([width - notch.width, width] x [0, notch.depth] x Z) is cut from the
 * IMPORTED shape by one real Boolean with history recording. The oracle is
 * therefore the ordinary single-run algorithm-history class (exempt from the
 * declared-truth review) — the import only changes what the base solid is:
 * its entities genuinely carry no construction history when the cut runs.
 * The notch consumes the corner's vertical edge outright (a "gone" truth on
 * an imported entity), re-trims the four faces meeting that corner, and
 * leaves the opening's entities identity survivors.
 *
 * Scope: `openingClearanceMinimumFraction` keeps the opening interior to the
 * slab and clear of the notch on BOTH axes, and `notchMaximumFraction`
 * bounds the notch away from the far corners, so every cut plane stays
 * strictly separated from every pre-existing plane. Fixture-domain
 * exclusions, not oracle robustness guarantees.
 */
export const stepImportCutFixtureSchema = z
  .object({
    kind: z.literal("step-import-cut"),
    slab: slabSchema,
    opening: openingSchema,
    notch: z
      .object({
        width: positiveMillimetres,
        depth: positiveMillimetres,
      })
      .strict(),
    sourceOperationId: z.string().uuid(),
    cutOperationId: z.string().uuid(),
  })
  .strict()
  .superRefine((value, context) => {
    validateSlabOpening(value, context);
    if (
      value.notch.width > notchMaximumFraction * value.slab.width ||
      value.notch.depth > notchMaximumFraction * value.slab.depth
    ) {
      context.addIssue({
        code: "custom",
        message: "notch must span at most the fixture fraction of the slab",
      });
    }
    const clearanceX = openingClearanceMinimumFraction * value.opening.width;
    if (
      value.slab.width - value.notch.width <
      value.opening.originX + value.opening.width + clearanceX
    ) {
      context.addIssue({
        code: "custom",
        message: "notch must clear the opening along the width axis",
      });
    }
    const clearanceY = openingClearanceMinimumFraction * value.opening.depth;
    if (value.opening.originY < value.notch.depth + clearanceY) {
      context.addIssue({
        code: "custom",
        message: "notch must clear the opening along the depth axis",
      });
    }
  });
export type StepImportCutFixture = z.infer<typeof stepImportCutFixtureSchema>;

export const mutationFixtureSchema = z.discriminatedUnion("kind", [
  planarSplitFixtureSchema,
  filletFixtureSchema,
  linearPatternFixtureSchema,
  bossSuppressionFixtureSchema,
  mergeFixtureSchema,
  stepReimportFixtureSchema,
  stepImportCutFixtureSchema,
]);
export type MutationFixture = z.infer<typeof mutationFixtureSchema>;

export const mutationFixtureKindSchema = z.enum([
  "planar-split",
  "fillet",
  "linear-pattern",
  "boss-suppression",
  "merge",
  "step-reimport",
  "step-import-cut",
]);
export type MutationFixtureKind = z.infer<typeof mutationFixtureKindSchema>;

export const mutationFateSchema = z.enum([
  "stable-single",
  "stable-set",
  "gone",
]);
export type MutationFate = z.infer<typeof mutationFateSchema>;

/**
 * One after entity the algorithm history records as Generated (not Modified)
 * from a BEFORE entity. Generated relations are cross-kind — a before-edge
 * can generate an after-vertex, a before-face an after-edge, and a
 * fillet-class algorithm can remove a before-edge yet generate an after-face
 * from it — so each image carries its own kind.
 */
export const mutationGeneratedImageSchema = z
  .object({
    token: z.string().min(1).max(256),
    kind: entityKindSchema,
  })
  .strict();
export type MutationGeneratedImage = z.infer<
  typeof mutationGeneratedImageSchema
>;

/**
 * Kernel-truth lineage for one BEFORE entity, computed exclusively from the
 * mutation algorithm's recorded history (IsRemoved/Modified/Generated).
 * Never derived from geometric similarity. `fate` and `afterTokens` come
 * from IsRemoved/Modified plus result membership; `generated` additively
 * carries the Generated() images and never influences the fate.
 */
export const mutationOracleEntrySchema = z
  .object({
    beforeToken: z.string().min(1).max(256),
    fate: mutationFateSchema,
    afterTokens: z.array(z.string().min(1).max(256)).max(100_000),
    /**
     * Additive Generated() lineage. Disjoint from `afterTokens` (the OCCT
     * history contract keeps G(S) and M(S) disjoint) and legal on every
     * fate including "gone" — removal forbids modified descendants, not
     * generated images. Omitted when the history records none.
     */
    generated: z.array(mutationGeneratedImageSchema).max(100_000).optional(),
  })
  .strict()
  .superRefine((value, context) => {
    if (new Set(value.afterTokens).size !== value.afterTokens.length) {
      context.addIssue({
        code: "custom",
        message: "oracle after tokens must be unique",
      });
    }
    const generated = value.generated ?? [];
    const generatedTokens = new Set(generated.map((image) => image.token));
    if (generatedTokens.size !== generated.length) {
      context.addIssue({
        code: "custom",
        message: "oracle generated tokens must be unique",
      });
    }
    if (value.afterTokens.some((token) => generatedTokens.has(token))) {
      context.addIssue({
        code: "custom",
        message:
          "a generated image cannot also be a modified/surviving descendant",
      });
    }
    if (value.fate === "gone" && value.afterTokens.length !== 0) {
      context.addIssue({
        code: "custom",
        message: "a removed entity cannot have modified descendants",
      });
    }
    if (value.fate === "stable-single" && value.afterTokens.length !== 1) {
      context.addIssue({
        code: "custom",
        message: "stable-single requires exactly one descendant",
      });
    }
    if (value.fate === "stable-set" && value.afterTokens.length < 2) {
      context.addIssue({
        code: "custom",
        message: "stable-set requires at least two descendants",
      });
    }
  });
export type MutationOracleEntry = z.infer<typeof mutationOracleEntrySchema>;

/**
 * One lineage-derived element name (NG-2 Phase A), correlated to a topology
 * snapshot entity by its epoch-local token. The token stays positional and
 * epoch-local per ADR-003; the name is the parallel channel that IS a
 * deterministic function of construction lineage — the substrate the
 * history-map tournament entrant resolves over. The grammar is defined in
 * native/kernel-host/src/element_names.hpp; its emitted alphabet is hex
 * digits, the markers n/M/G/S/L/Q/f/e/v, and ':', '.', '/', which
 * structurally cannot spell any banned oracle vocabulary.
 */
export const elementNameEntrySchema = z
  .object({
    token: z.string().min(1).max(256),
    name: z.string().min(1).max(512),
  })
  .strict();
export type ElementNameEntry = z.infer<typeof elementNameEntrySchema>;

/**
 * One sub-shape reference of the additive `ocaf_case` method (NG-2 entrant
 * #2). `index` is the 0-based `TopExp::MapShapes` position within `kind` of
 * the fixture's BEFORE shape for a request target, or of the AFTER shape for
 * a solved entity — the same enumeration that mints the mutation-case
 * snapshot tokens, so a resolver can translate `te:` tokens to and from this
 * form without any geometric inference.
 */
export const ocafCaseEntitySchema = z
  .object({
    kind: entityKindSchema,
    index: z.number().int().nonnegative().max(1_000_000),
  })
  .strict();
export type OcafCaseEntity = z.infer<typeof ocafCaseEntitySchema>;

/**
 * One `ocaf_case` outcome. `status` maps 1:1 to what the OCAF TNaming
 * machinery actually reported for that target's selector — never invented:
 *
 * - "solved": `TNaming_Selector::Solve` succeeded with a single shape of the
 *   target kind present in the AFTER result; `solved` carries exactly one
 *   entry.
 * - "ambiguous": `Solve` produced a `TopAbs_COMPOUND` whose members are all
 *   of the target kind and all present in the AFTER result (the documented
 *   FILTERBYNEIGHBOURGS failure shape, OCCT tracker #23119); `solved`
 *   carries the member set, possibly empty when no member was extractable.
 * - "missing": the naming recipe evaluated to no current value
 *   (`Solve() == false`, a null/empty NamedShape, or a null `Get()`).
 * - "failed": selection or solving failed closed — an out-of-range target,
 *   `Select() == false`, a wrong-kind solved shape, or a solved shape absent
 *   from the AFTER result. `solved` is absent.
 */
export const ocafCaseOutcomeSchema = z
  .object({
    target: ocafCaseEntitySchema,
    status: z.enum(["solved", "ambiguous", "missing", "failed"]),
    solved: z.array(ocafCaseEntitySchema).max(100_000).optional(),
  })
  .strict()
  .superRefine((value, context) => {
    if (
      value.status === "solved" &&
      (value.solved === undefined || value.solved.length !== 1)
    ) {
      context.addIssue({
        code: "custom",
        message:
          "a solved ocaf outcome carries exactly one solved entity — a selector names one entity",
      });
    }
    if (value.status === "ambiguous" && value.solved === undefined) {
      context.addIssue({
        code: "custom",
        message:
          "an ambiguous ocaf outcome carries its candidate set (possibly empty)",
      });
    }
    if (
      (value.status === "missing" || value.status === "failed") &&
      value.solved !== undefined
    ) {
      context.addIssue({
        code: "custom",
        message: "a missing/failed ocaf outcome carries no solved entities",
      });
    }
  });
export type OcafCaseOutcome = z.infer<typeof ocafCaseOutcomeSchema>;

/**
 * Simulation study kinds (the strengths / heat-maps pillar): static linear
 * elasticity and steady-state heat conduction, both solved by the kernel
 * host's voxel hexahedral FEM — genuinely computed physics, never a shaded
 * guess.
 */
export const simulationStudyKindSchema = z.enum([
  "static-stress",
  "steady-heat",
]);
export type SimulationStudyKind = z.infer<typeof simulationStudyKindSchema>;

/**
 * Isotropic material card. The host runs a consistent N/mm/MPa unit system:
 * Young's modulus converts GPa -> MPa natively, conductivity W/(m*K) ->
 * W/(mm*K), so displacements come back in mm and stresses in MPa with forces
 * in N. `yieldStrengthMPa` is carried for factor-of-safety display; the
 * linear solve never reads it. Poisson's ratio at exactly 0.5 is
 * incompressible (no isotropic stiffness matrix exists), hence the open
 * bound.
 */
export const simulationMaterialSchema = z
  .object({
    youngsModulusGPa: z.number().finite().positive(),
    poissonsRatio: z.number().gt(-1).lt(0.5),
    yieldStrengthMPa: z.number().finite().positive(),
    thermalConductivityWPerMK: z.number().finite().positive(),
  })
  .strict();
export type SimulationMaterial = z.infer<typeof simulationMaterialSchema>;

/**
 * One boundary constraint: `ast` is the SAME selector wire form the `query`
 * member's `ast` field carries, resolved by the host through the same
 * evaluator against the same replay state. "fixed" clamps all three
 * displacement DOF (static-stress); "temperature" prescribes `valueC`
 * (steady-heat). The refinement makes valueC present exactly when the kind
 * needs it, so a meaningless number can never ride along silently.
 */
export const simulationConstraintSchema = z
  .object({
    id: z.string().min(1).max(128),
    ast: selectorQuerySchema,
    kind: z.enum(["fixed", "temperature"]),
    valueC: z.number().finite().optional(),
  })
  .strict()
  .superRefine((constraint, context) => {
    if (
      (constraint.kind === "temperature") !==
      (constraint.valueC !== undefined)
    ) {
      context.addIssue({
        code: "custom",
        message:
          'valueC must be present exactly when the constraint kind is "temperature"',
        path: ["valueC"],
      });
    }
  });
export type SimulationConstraint = z.infer<typeof simulationConstraintSchema>;

/**
 * One boundary load. "force" carries the TOTAL `vectorN` in newtons (the
 * host splits it equally over the matched skin nodes); "heat-flux" carries
 * `wattsPerM2` flowing INTO the body over the matched skin patch. The
 * refinements make each payload present exactly when its kind needs it, and
 * refuse an all-zero force — a load of nothing is a modelling error, not a
 * no-op.
 */
export const simulationLoadSchema = z
  .object({
    id: z.string().min(1).max(128),
    ast: selectorQuerySchema,
    kind: z.enum(["force", "heat-flux"]),
    vectorN: z
      .tuple([z.number().finite(), z.number().finite(), z.number().finite()])
      .optional(),
    wattsPerM2: z.number().finite().optional(),
  })
  .strict()
  .superRefine((load, context) => {
    if ((load.kind === "force") !== (load.vectorN !== undefined)) {
      context.addIssue({
        code: "custom",
        message:
          'vectorN must be present exactly when the load kind is "force"',
        path: ["vectorN"],
      });
    }
    if (
      load.vectorN !== undefined &&
      load.vectorN.every((component) => component === 0)
    ) {
      context.addIssue({
        code: "custom",
        message: "a force load must not be the zero vector",
        path: ["vectorN"],
      });
    }
    if ((load.kind === "heat-flux") !== (load.wattsPerM2 !== undefined)) {
      context.addIssue({
        code: "custom",
        message:
          'wattsPerM2 must be present exactly when the load kind is "heat-flux"',
        path: ["wattsPerM2"],
      });
    }
  });
export type SimulationLoad = z.infer<typeof simulationLoadSchema>;

/**
 * One study: what to solve, at which voxel edge length, on which material,
 * under which boundary conditions. The kind-coherence refinement keeps a
 * study physically well-typed at the process boundary: a static-stress study
 * carries only "fixed" constraints and "force" loads, a steady-heat study
 * only "temperature" constraints and "heat-flux" loads — a thermal clamp on
 * a stress study is a category error, refused here rather than guessed at
 * natively.
 */
export const simulationStudySchema = z
  .object({
    kind: simulationStudyKindSchema,
    resolutionMm: z.number().finite().positive(),
    material: simulationMaterialSchema,
    constraints: z.array(simulationConstraintSchema).min(1).max(1000),
    loads: z.array(simulationLoadSchema).max(1000),
  })
  .strict()
  .superRefine((study, context) => {
    const constraintKind =
      study.kind === "static-stress" ? "fixed" : "temperature";
    const loadKind = study.kind === "static-stress" ? "force" : "heat-flux";
    for (const [index, constraint] of study.constraints.entries()) {
      if (constraint.kind !== constraintKind) {
        context.addIssue({
          code: "custom",
          message: `a ${study.kind} study accepts only "${constraintKind}" constraints`,
          path: ["constraints", index, "kind"],
        });
      }
    }
    for (const [index, load] of study.loads.entries()) {
      if (load.kind !== loadKind) {
        context.addIssue({
          code: "custom",
          message: `a ${study.kind} study accepts only "${loadKind}" loads`,
          path: ["loads", index, "kind"],
        });
      }
    }
  });
export type SimulationStudy = z.infer<typeof simulationStudySchema>;

/** The recovered scalar field's name, 1:1 with the study kind. */
export const simulationScalarNameSchema = z.enum([
  "vonMisesMPa",
  "temperatureC",
]);
export type SimulationScalarName = z.infer<typeof simulationScalarNameSchema>;

/**
 * The voxel skin the host renders heat maps on: deduplicated vertices,
 * outward-wound triangles, one recovered scalar per vertex. Array caps come
 * from the host's 150000-element voxel cap (SIM_RESOLUTION refuses above
 * it): even fully disconnected voxels bound the skin at 1.2M vertices / 1.8M
 * triangles.
 */
export const simulationMeshSchema = z
  .object({
    /** Flattened x,y,z in millimetres — length a multiple of 3. */
    positions: z.array(z.number().finite()).max(4_000_000),
    /** Flattened vertex-index triples — length a multiple of 3. */
    triangles: z.array(z.number().int().nonnegative()).max(6_000_000),
    /** One scalar per vertex (positions.length / 3 entries). */
    scalars: z.array(z.number().finite()).max(1_400_000),
  })
  .strict()
  .superRefine((mesh, context) => {
    if (mesh.positions.length % 3 !== 0) {
      context.addIssue({
        code: "custom",
        message: "positions must be flattened x,y,z triples",
        path: ["positions"],
      });
    }
    if (mesh.triangles.length % 3 !== 0) {
      context.addIssue({
        code: "custom",
        message: "triangles must be flattened vertex-index triples",
        path: ["triangles"],
      });
    }
    if (mesh.scalars.length * 3 !== mesh.positions.length) {
      context.addIssue({
        code: "custom",
        message: "scalars must carry exactly one value per vertex",
        path: ["scalars"],
      });
    }
    const vertexCount = Math.floor(mesh.positions.length / 3);
    if (mesh.triangles.some((index) => index >= vertexCount)) {
      context.addIssue({
        code: "custom",
        message: "every triangle index must name an emitted vertex",
        path: ["triangles"],
      });
    }
  });
export type SimulationMesh = z.infer<typeof simulationMeshSchema>;

export const kernelRequestSchema = z
  .discriminatedUnion("method", [
    z.object({ ...requestBase, method: z.literal("health") }).strict(),
    // Fast control-plane query for the replay cache's governor state + counters
    // (plan 06 §7, Wave 2.1 slice 3a). Like health it carries no payload and is
    // answered inline (no worker), so it can be polled during an evaluation.
    z.object({ ...requestBase, method: z.literal("stats") }).strict(),
    z
      .object({
        ...requestBase,
        ...documentEvaluationFields,
        method: z.literal("evaluate_document"),
        /**
         * Viewport tessellation quality. Omission preserves the established
         * tier-0 evaluation path; tier 3 remains reserved for the separate
         * absolute-tolerance `export_mesh` path and is never accepted here.
         */
        lodTier: z.number().int().min(0).max(2).optional(),
        includeTopology: z.boolean().optional(),
        /**
         * Request bounded evidence for one dense AEMB topology row. Native
         * evaluation resolves the row through the same OCCT index maps used by
         * tessellation and returns evidence only on the named body.
         */
        topologySelection: z
          .object({
            bodyId: z.string().uuid(),
            kind: entityKindSchema,
            entityIndex: z.number().int().nonnegative().max(999_999),
          })
          .strict()
          .optional(),
        /**
         * Additive element-name channel (integration tranche N0): when true
         * every returned body carries `elementNames` — one lineage name per
         * face/edge/vertex, correlated by token with the body's topology
         * snapshot. Documents containing operations whose OCCT history
         * surface is unverified (offset) fail with UNSUPPORTED_OPERATION
         * instead of minting names from an untrusted lineage. Absent or
         * false leaves the response byte-identical to the pre-flag protocol.
         */
        includeElementNames: z.boolean().optional(),
      })
      .strict(),
    /**
     * Evaluate one definition's own operation list, versioned by an opaque
     * content hash the caller mints upstream (document-model) rather than by
     * `evaluate_document`'s monotonic documentId+revision pair — a definition
     * can be evaluated from many assembly documents that share no revision
     * counter, so it does NOT reuse `documentEvaluationFields`.
     *
     * Deliberately OMITTED: `topologySelection` (targeted single-entity
     * evidence for mate-frame endpoint resolution). That is ASM-005's concern
     * (native/kernel-host/src/: ref_resolution.hpp/.cpp, topology.hpp/.cpp,
     * mate_frame.hpp/.cpp; packages/document-model/src/selector/) — ASM-005
     * is expected to extend THIS request variant additively (a new optional
     * field), the same way `evaluate_document` itself grew
     * `topologySelection` after its initial ship. Not added speculatively
     * here.
     */
    z
      .object({
        ...requestBase,
        method: z.literal("evaluate_definition"),
        definitionId: z.string().uuid(),
        /**
         * Opaque content hash minted upstream (document-model, outside the
         * kernel wire) from a definition's revision-defining inputs. The
         * kernel treats it as an opaque cache-line label — it never
         * recomputes or validates it — and echoes it back on the result so a
         * caller can prove the response matches the request it made.
         * Assembly doc 07 §4.1: "The kernel evaluates each unique definition
         * once per revision hash."
         */
        revisionHash: z.string().min(1).max(128),
        /**
         * The definition's own operation list — a `{kind:"root"}`/
         * `{kind:"embedded"}` source's `operations` array (assembly doc §3),
         * validated against the SAME wire schema `evaluate_document` uses.
         */
        operations: z.array(wireOperationSchema).max(100_000),
        /** Same meaning/bounds as `evaluate_document`'s `lodTier`. */
        lodTier: z.number().int().min(0).max(2).optional(),
        /** Same meaning as `evaluate_document`'s `includeTopology` (full per-body topology, not a targeted selection). */
        includeTopology: z.boolean().optional(),
        /** Same meaning as `evaluate_document`'s `includeElementNames`. */
        includeElementNames: z.boolean().optional(),
      })
      .strict(),
    z
      .object({
        ...requestBase,
        ...documentEvaluationFields,
        method: z.literal("export_step"),
        outputPath: z.string().min(1).max(32_768),
      })
      .strict(),
    z
      .object({
        ...requestBase,
        ...documentEvaluationFields,
        method: z.literal("export_mesh"),
      })
      .strict(),
    z
      .object({
        ...requestBase,
        method: z.literal("inspect_step"),
        inputPath: z.string().min(1).max(32_768),
      })
      .strict(),
    /**
     * Solve a sketch's constraint system (CAP-037). NOT a document mutation:
     * a person applying a constraint has not committed anything yet, and the
     * authoring loop needs an answer before it can offer them one. The solver
     * itself lives behind the ADR-016 seam (`sketch_solver.hpp`); this is the
     * transport to it.
     *
     * `evaluate_document` deliberately does NOT carry this: that method exists
     * to produce bodies and a sketch produces none, so threading a solution
     * channel through it would make the response shape conditional on
     * operation kind. The two answer different questions and stay separate.
     */
    z
      .object({
        ...requestBase,
        method: z.literal("solve_sketch"),
        /** The entity graph, in the order the solution will mirror. */
        entities: z.array(sketchEntitySchema).max(2048),
        constraints: z.array(sketchConstraintSchema).max(2048),
        /**
         * Entities whose parameters are PINNED. Without at least one a
         * least-squares solve is free to translate the whole sketch — GOV-004
         * measured exactly that — so grounding is part of the request rather
         * than a solver default.
         */
        grounded: z.array(sketchEntityIdSchema).max(2048),
      })
      .strict(),
    /**
     * Project an operation program's bodies through hidden-line removal into
     * a drawing view's 2D line work. The program is evaluated exactly as
     * `evaluate_definition` evaluates it; `direction` is the eye's line of
     * sight and `up` becomes the paper's +Y (orthogonalized host-side, and a
     * pair that is parallel has no horizon and is refused). The geometry may
     * come from `operations`, from `instances`, or both — a request carrying
     * neither has nothing to draw and is refused by the request-level
     * superRefine below.
     */
    z
      .object({
        ...requestBase,
        method: z.literal("hlr_project"),
        operations: z.array(wireOperationSchema).max(100_000),
        direction: z.tuple([z.number(), z.number(), z.number()]),
        up: z.tuple([z.number(), z.number(), z.number()]),
        /**
         * Optional drafting section: before projection every body is cut by
         * the plane through `origin` with `normal`, REMOVING all material on
         * the side the normal points toward. The caller is responsible for a
         * `direction` that looks at the exposed cut (typically direction ===
         * normal); the result then carries `sectionOutlines`.
         */
        sectionPlane: z
          .object({
            origin: z.tuple([z.number(), z.number(), z.number()]),
            normal: z.tuple([z.number(), z.number(), z.number()]),
          })
          .strict()
          .optional(),
        /**
         * Posed assembly instances: when present the projected geometry is
         * the UNION of each instance's evaluated bodies transformed by its
         * pose — rotation quaternion x,y,z,w, then translation in
         * millimetres — and the top-level `operations` may be empty. Each
         * instance's `operations` is the same program shape the top-level
         * field carries. Absent leaves the request byte-identical to the
         * pre-instances protocol.
         */
        instances: z
          .array(
            z
              .object({
                operations: z.array(wireOperationSchema).max(100_000),
                pose: z
                  .object({
                    translationMm: z.tuple([
                      z.number(),
                      z.number(),
                      z.number(),
                    ]),
                    rotationXyzw: z.tuple([
                      z.number(),
                      z.number(),
                      z.number(),
                      z.number(),
                    ]),
                  })
                  .strict(),
              })
              .strict(),
          )
          .min(1)
          .optional(),
      })
      .strict(),
    /**
     * Run one physics study over an operation program (the strengths / heat
     * maps / structural load mapping pillar). The program is the SAME
     * operations array `evaluate_document` and `hlr_project` carry — at
     * least one operation, since a study needs geometry — evaluated with a
     * naming registry so every boundary-condition `ast` resolves through the
     * SAME selector evaluator the `query` method uses. The host voxelizes,
     * assembles, and solves natively; failures surface through the existing
     * error envelope with the fine code in `details.simulationCode`
     * (SIM_UNCONSTRAINED, SIM_RESOLUTION, SIM_DID_NOT_CONVERGE,
     * SIM_BC_UNRESOLVED) under the closed wire-code enum.
     */
    z
      .object({
        ...requestBase,
        method: z.literal("simulate"),
        operations: z.array(wireOperationSchema).min(1).max(100_000),
        study: simulationStudySchema,
      })
      .strict(),
    /**
     * Mold/tooling draft analysis (read-only) — a SIBLING to `simulate` and
     * `hlr_project` above, NOT an `operations`-array entry: it is never
     * validated against `operations.ts`'s `operationSchema`/
     * `wireOperationSchema` discriminated union, never dispatched through
     * `ExecuteOperation`, and never touches `naming_registry`'s
     * `OperationClass` enum — a top-level RPC method the same way `simulate`
     * and `hlr_project` are, dispatched directly in `server.cpp`'s
     * `HandleRequest`/`RunWork` rather than through the operation-execution
     * path. Real SolidWorks itself doesn't tree-feature Draft Analysis
     * either (a display mode, not a FeatureManager entry) and Fusion 360 has
     * no dedicated mold workspace at all — the same real-tool precedent
     * `simulate`'s own "read-only computation over an already-evaluated
     * body" shape already follows.
     *
     * Classifies every face of `bodyId` against `pullDirection` within
     * `draftAngleToleranceDeg`, calling the SAME shared native
     * `ClassifyDraftFaces` function `mold_parting_line`'s own executor calls
     * (`operations.ts`'s mold/tooling wave 1 section note) — one source of
     * truth, two doors, exactly the `inspect_document`/snapshot-resource
     * precedent restated for the kernel wire.
     *
     * `operations` is the SAME shape `simulate`'s own field is — REQUIRED,
     * at least one operation, since a classification needs geometry to
     * classify — evaluated to produce the body `bodyId` names.
     *
     * `bodyId` (a `z.string().uuid()`, deliberately NOT `targetOperationId`)
     * names the ALREADY-EVALUATED body directly, the same way
     * `evaluate_document`'s own `topologySelection.bodyId` names an
     * already-evaluated body for its own targeted-evidence request: unlike
     * an operation parameter (which always resolves an operation id through
     * the very evaluation the operation itself is part of), this request's
     * `operations` program is evaluated FIRST and `bodyId` then selects
     * which already-produced body to classify.
     */
    z
      .object({
        ...requestBase,
        method: z.literal("mold_draft_analysis"),
        operations: z.array(wireOperationSchema).min(1).max(100_000),
        bodyId: z.string().uuid(),
        pullDirection: pullDirectionSchema,
        draftAngleToleranceDeg: draftAngleToleranceDegSchema,
      })
      .strict(),
    z
      .object({
        ...requestBase,
        method: z.literal("mutation_case"),
        fixture: mutationFixtureSchema,
        /**
         * Additive element-name channel (NG-2 Phase A): when true the result
         * carries `beforeElementNames`/`afterElementNames`. Absent or false
         * leaves the response byte-identical to the pre-flag protocol.
         */
        includeElementNames: z.boolean().optional(),
      })
      .strict(),
    z
      .object({
        ...requestBase,
        /**
         * Additive OCAF TNaming resolution case (NG-2 entrant #2): the host
         * rebuilds the SAME fixture program as `mutation_case` while
         * recording real TNaming history into a TDF document, attaches one
         * `TNaming_Selector` per target on the BEFORE shape, applies the
         * fixture's mutation (or Case B replay), and reports what `Solve`
         * returned per target. Carries no oracle payload: outcomes are the
         * entrant's own answers, produced without ever seeing lineage.
         */
        method: z.literal("ocaf_case"),
        fixture: mutationFixtureSchema,
        targets: z.array(ocafCaseEntitySchema).min(1).max(10_000),
      })
      .strict(),
    z
      .object({
        ...requestBase,
        ...documentEvaluationFields,
        method: z.literal("query"),
        /**
         * Timeline position (plan 05 §2): evaluate the document strictly up
         * through this operation (inclusive) and ignore anything after it in
         * `operations`, then evaluate `ast` against that replay state's naming
         * registry + body table. The op must exist in `operations`; if it
         * doesn't the host fails the request with REFERENCE_MISSING naming it.
         */
        atOperationId: z.string().uuid(),
        /**
         * The already-parsed, doc-model-validated AQL AST (plan 05 §3, §4.2).
         * Doc-model performs static checks (parse, kind match, rootedness)
         * before ever building this request — the kernel evaluator trusts the
         * shape and only implements evaluation semantics, never re-parsing a
         * string. ADR-006 / plan 05 §4.2: the raw query string never crosses
         * the kernel-host process boundary, only this AST does.
         */
        ast: selectorQuerySchema,
      })
      .strict(),
    z
      .object({
        ...requestBase,
        method: z.literal("cancel"),
        targetRequestId: z.string().uuid(),
      })
      .strict(),
  ])
  .superRefine((request, context) => {
    // A projection with neither its own operations nor a posed instance has
    // no geometry to draw; refuse it at the process boundary the same way
    // the native host refuses an empty body list.
    if (
      request.method === "hlr_project" &&
      request.operations.length === 0 &&
      request.instances === undefined
    ) {
      context.addIssue({
        code: "custom",
        message:
          "an hlr_project request must carry a non-empty operations array or at least one posed instance",
        path: ["operations"],
      });
    }

    // Kernel-transport boundary of the single document-size envelope: every
    // request kind that carries the full operations array (evaluate_document,
    // export_step, export_mesh, query) sends it in ONE control frame, so the
    // serialized operations must fit the SAME envelope enforced at mutation
    // acceptance, the journal, and the `.aeth` container. Rejecting here —
    // cleanly, before transport — means an over-envelope document never reaches
    // (and is never silently truncated by) the 4 MiB control-frame limit.
    if (
      request.method !== "evaluate_document" &&
      request.method !== "evaluate_definition" &&
      request.method !== "export_step" &&
      request.method !== "export_mesh" &&
      request.method !== "query"
    ) {
      return;
    }
    const bytes = operationsSerializedByteLength(request.operations);
    if (bytes > maxDocumentOperationsBytes) {
      context.addIssue({
        code: "custom",
        message: `Document operations serialize to ${bytes} bytes, exceeding the ${maxDocumentOperationsBytes}-byte document-size envelope`,
        path: ["operations"],
      });
    }
    if (
      request.method === "evaluate_document" &&
      request.includeTopology === true &&
      request.topologySelection !== undefined
    ) {
      context.addIssue({
        code: "custom",
        message:
          "includeTopology and topologySelection are mutually exclusive evaluation modes",
        path: ["topologySelection"],
      });
    }
  });

const feasibilityProbeBase = {
  bound: z.literal("tested-lower-bound"),
  attempts: z.number().int().positive().max(16),
} as const;

/**
 * Optional repair payload on a Wave 2.4 GEOMETRY_FAILED error. The bound is a
 * candidate the kernel actually built and validated, not an analytic promise.
 */
export const geometryFeasibilityDetailsSchema = z.union([
  z
    .object({
      requestedRadius: z.number().finite().positive(),
      maxFeasibleRadius: z.number().finite().positive(),
      feasibilityProbe: z
        .object({
          parameter: z.literal("radius"),
          requested: z.number().finite().positive(),
          maxFeasible: z.number().finite().positive(),
          ...feasibilityProbeBase,
        })
        .strict(),
    })
    .strict()
    .superRefine((details, context) => {
      if (details.requestedRadius !== details.feasibilityProbe.requested) {
        context.addIssue({
          code: "custom",
          message: "requestedRadius must match feasibilityProbe.requested",
          path: ["requestedRadius"],
        });
      }
      if (!(details.maxFeasibleRadius < details.requestedRadius)) {
        context.addIssue({
          code: "custom",
          message: "maxFeasibleRadius must be below the failed requestedRadius",
          path: ["maxFeasibleRadius"],
        });
      }
      if (details.maxFeasibleRadius !== details.feasibilityProbe.maxFeasible) {
        context.addIssue({
          code: "custom",
          message: "maxFeasibleRadius must match feasibilityProbe.maxFeasible",
          path: ["maxFeasibleRadius"],
        });
      }
    }),
  z
    .object({
      requestedDistance: z
        .number()
        .finite()
        .refine((value) => value !== 0),
      maxFeasibleDistance: z
        .number()
        .finite()
        .refine((value) => value !== 0),
      feasibilityProbe: z
        .object({
          parameter: z.literal("distance"),
          requested: z
            .number()
            .finite()
            .refine((value) => value !== 0),
          maxFeasible: z
            .number()
            .finite()
            .refine((value) => value !== 0),
          ...feasibilityProbeBase,
        })
        .strict(),
    })
    .strict()
    .superRefine((details, context) => {
      if (details.requestedDistance !== details.feasibilityProbe.requested) {
        context.addIssue({
          code: "custom",
          message: "requestedDistance must match feasibilityProbe.requested",
          path: ["requestedDistance"],
        });
      }
      if (
        Math.sign(details.maxFeasibleDistance) !==
        Math.sign(details.requestedDistance)
      ) {
        context.addIssue({
          code: "custom",
          message: "maxFeasibleDistance must preserve the requested direction",
          path: ["maxFeasibleDistance"],
        });
      }
      if (
        !(
          Math.abs(details.maxFeasibleDistance) <
          Math.abs(details.requestedDistance)
        )
      ) {
        context.addIssue({
          code: "custom",
          message:
            "maxFeasibleDistance magnitude must be below the failed request",
          path: ["maxFeasibleDistance"],
        });
      }
      if (
        details.maxFeasibleDistance !== details.feasibilityProbe.maxFeasible
      ) {
        context.addIssue({
          code: "custom",
          message:
            "maxFeasibleDistance must match feasibilityProbe.maxFeasible",
          path: ["maxFeasibleDistance"],
        });
      }
    }),
  // Catalog wave 1 (docs/design/2026-07-19-native-catalog-wave1.md §3.4): the
  // shell executor probes its wall `thickness` exactly like fillet probes its
  // radius — the bound is a positive magnitude the kernel actually built and
  // validated (offset + nested cut + validity per candidate).
  z
    .object({
      requestedThickness: z.number().finite().positive(),
      maxFeasibleThickness: z.number().finite().positive(),
      feasibilityProbe: z
        .object({
          parameter: z.literal("thickness"),
          requested: z.number().finite().positive(),
          maxFeasible: z.number().finite().positive(),
          ...feasibilityProbeBase,
        })
        .strict(),
    })
    .strict()
    .superRefine((details, context) => {
      if (details.requestedThickness !== details.feasibilityProbe.requested) {
        context.addIssue({
          code: "custom",
          message: "requestedThickness must match feasibilityProbe.requested",
          path: ["requestedThickness"],
        });
      }
      if (!(details.maxFeasibleThickness < details.requestedThickness)) {
        context.addIssue({
          code: "custom",
          message:
            "maxFeasibleThickness must be below the failed requestedThickness",
          path: ["maxFeasibleThickness"],
        });
      }
      if (
        details.maxFeasibleThickness !== details.feasibilityProbe.maxFeasible
      ) {
        context.addIssue({
          code: "custom",
          message:
            "maxFeasibleThickness must match feasibilityProbe.maxFeasible",
          path: ["maxFeasibleThickness"],
        });
      }
    }),
]);
export type GeometryFeasibilityDetails = z.infer<
  typeof geometryFeasibilityDetailsSchema
>;

export const kernelErrorSchema = z
  .object({
    code: z.enum([
      "INVALID_REQUEST",
      "REFERENCE_MISSING",
      "REFERENCE_AMBIGUOUS",
      "GEOMETRY_FAILED",
      "CANCELLED",
      // Per-op wall-clock timeout (Wave 2.1 slice 3b; plan 06 §7's
      // E_KERNEL_TIMEOUT under the implemented bare-code taxonomy). Carries the
      // timed-out `operationId` and `details.timeoutMs`.
      "TIMEOUT",
      "BUSY",
      "IO_ERROR",
      "UNSUPPORTED_OPERATION",
      "INTERNAL_ERROR",
    ]),
    message: z.string().min(1),
    operationId: z.string().uuid().optional(),
    details: z.record(z.string(), z.unknown()).optional(),
  })
  .strict()
  .superRefine((error, context) => {
    // A per-op TIMEOUT MUST be attributed (Wave 2.1 slice 3b, finding 3): the
    // agent's Gate-4 repair depends on knowing WHICH op timed out and its budget,
    // so the contract requires the timed-out `operationId` (a UUID) and a numeric
    // `details.timeoutMs`. Enforcing it here means an unattributed TIMEOUT is
    // rejected at the process boundary rather than reaching a caller as a claim
    // the host never substantiated.
    if (error.code === "TIMEOUT") {
      if (error.operationId === undefined) {
        context.addIssue({
          code: "custom",
          message: "a TIMEOUT error must carry the timed-out operationId",
          path: ["operationId"],
        });
      }
      if (typeof error.details?.timeoutMs !== "number") {
        context.addIssue({
          code: "custom",
          message: "a TIMEOUT error must carry a numeric details.timeoutMs",
          path: ["details", "timeoutMs"],
        });
      }
    }

    // Feasibility diagnostics are optional, but when the host claims one it
    // must be complete and internally consistent. Other GEOMETRY_FAILED
    // details remain additive and are unaffected.
    if (
      error.code === "GEOMETRY_FAILED" &&
      error.details?.feasibilityProbe !== undefined
    ) {
      const parsed = geometryFeasibilityDetailsSchema.safeParse(error.details);
      if (!parsed.success) {
        context.addIssue({
          code: "custom",
          message: "malformed bounded-feasibility repair payload",
          path: ["details", "feasibilityProbe"],
        });
      }
    }
  });

export const buildManifestSchema = z
  .object({
    kernelProtocolVersion: z.literal(kernelProtocolVersion),
    kernelHostVersion: z.string().min(1),
    occtTag: z.literal("V8_0_0_p1"),
    occtCommit: z.literal("4f95ecaa3b690e34988d42e2ca7fe882e7a8bc7d"),
    occtManifestSha256: z.string().regex(/^[0-9a-f]{64}$/),
    compiler: z.string().min(1),
    buildType: z.string().min(1),
  })
  .strict();

export const shapeProbesSchema = z
  .object({
    valid: z.boolean(),
    volumeMm3: z.number().finite().nonnegative(),
    surfaceAreaMm2: z.number().finite().nonnegative(),
    centerOfMassMm: z.tuple([z.number(), z.number(), z.number()]),
    boundingBoxMm: boundingBoxMmSchema,
    solidCount: z.number().int().nonnegative(),
    shellCount: z.number().int().nonnegative(),
    faceCount: z.number().int().nonnegative(),
    edgeCount: z.number().int().nonnegative(),
    vertexCount: z.number().int().nonnegative(),
  })
  .strict();

/**
 * One resolved entity a `query` request's AST evaluated to (plan 05 §2
 * `ResolvedEntity`; §8.1's per-stage-cardinality attribution accompanies
 * this on the result, not here). Optional fields are populated per-kind —
 * `surface`/`normal` for faces, `curve`/`axis` for edges, etc. — mirroring
 * `referenceAnchorSchema`'s fingerprint fields in refs.ts for consistency
 * across the two "what is this entity" wire shapes.
 */
export const resolvedEntitySchema = z
  .object({
    token: topologyTokenSchema,
    kind: referenceEntityKindSchema,
    /**
     * Visible topology carries its owning body UUID.  Synthetic datum
     * entities are intentionally body-less, but they are still queryable
     * references (for example when opening a sketch on a datum plane), so the
     * wire uses the empty string for that explicit case.
     */
    bodyId: z.string().uuid().or(z.literal("")),
    centroid: z.tuple([
      z.number().finite(),
      z.number().finite(),
      z.number().finite(),
    ]),
    area: z.number().finite().nonnegative().optional(),
    length: z.number().finite().nonnegative().optional(),
    volume: z.number().finite().nonnegative().optional(),
    surface: z
      .enum(["plane", "cylinder", "cone", "sphere", "torus", "freeform"])
      .optional(),
    curve: z.enum(["line", "circle", "ellipse", "bspline", "other"]).optional(),
    /** Bounded samples for a selected edge's live sketch projection. */
    samplePoints: z
      .array(
        z.tuple([
          z.number().finite(),
          z.number().finite(),
          z.number().finite(),
        ]),
      )
      .max(128)
      .optional(),
    normal: z
      .tuple([z.number().finite(), z.number().finite(), z.number().finite()])
      .optional(),
    axis: z
      .object({
        origin: z.tuple([
          z.number().finite(),
          z.number().finite(),
          z.number().finite(),
        ]),
        dir: z.tuple([
          z.number().finite(),
          z.number().finite(),
          z.number().finite(),
        ]),
      })
      .strict()
      .optional(),
    radius: z.number().finite().nonnegative().optional(),
  })
  .strict();
export type ResolvedEntity = z.infer<typeof resolvedEntitySchema>;

/** One diagnostic a `query` evaluation attaches without failing the request. */
export const selDiagnosticSchema = z
  .object({
    code: z.enum([
      "D_TOKEN_DEAD",
      "D_ORDER_TIE",
      "D_MIXED_CONVEXITY",
      "D_ANCHOR_DRIFT",
    ]),
    message: z.string().min(1),
    token: topologyTokenSchema.optional(),
  })
  .strict();
export type SelDiagnostic = z.infer<typeof selDiagnosticSchema>;

/**
 * Replay-cache observability (plan 06 §7/§8, Wave 2.1 slice 3a). `entries` /
 * `bytes` / `budgetBytes` are the byte-bounded governor's live state; `hits` /
 * `misses` are per-EVALUATION prefix outcomes (a reuse eval that restored any
 * cached prefix is a hit, a cold one a miss); `evictions` / `snapshotsStored`
 * are lifetime totals. `bytes` is an estimate (§8.4) that intentionally
 * over-counts shape handles shared across snapshots, so it may exceed true RSS.
 */
export const kernelCacheStatsSchema = z
  .object({
    entries: z.number().int().nonnegative(),
    bytes: z.number().int().nonnegative(),
    budgetBytes: z.number().int().nonnegative(),
    hits: z.number().int().nonnegative(),
    misses: z.number().int().nonnegative(),
    evictions: z.number().int().nonnegative(),
    snapshotsStored: z.number().int().nonnegative(),
  })
  .strict();
export type KernelCacheStats = z.infer<typeof kernelCacheStatsSchema>;

export const kernelResultSchema = z
  .discriminatedUnion("type", [
    z
      .object({ type: z.literal("health"), build: buildManifestSchema })
      .strict(),
    // Replay-cache stats (Wave 2.1 slice 3a). The §7 `memory` (RSS) block is
    // intentionally absent until the §9 RSS sampler lands (slice 3b) — reporting
    // a fabricated RSS would be dishonest, so the subset ships honestly instead.
    z
      .object({
        type: z.literal("stats"),
        cache: kernelCacheStatsSchema,
        uptimeMs: z.number().int().nonnegative(),
        occtTag: z.string().min(1),
        occtCommit: z.string().min(1),
        kernelGeomVersion: z.string().min(1),
      })
      .strict(),
    z
      .object({
        type: z.literal("evaluation"),
        revision: z.number().int().nonnegative(),
        epoch: z.number().int().nonnegative(),
        /**
         * Evaluation contract: `bodies` contains one entry per BODY-PRODUCING
         * operation that is still UNCONSUMED at the end of the request, in
         * document order. Profile operations evaluate to epoch-local planar
         * faces held inside the kernel host for the duration of the request;
         * they contribute no bodies entry, no probes, and no mesh packet. A
         * dangling profile is therefore a valid document whose evaluation
         * succeeds with fewer bodies than operations (possibly zero). A
         * consuming operation whose reference does not name an earlier profile
         * operation in the same request fails the whole request with
         * REFERENCE_MISSING and the consuming operation's id.
         *
         * Body management (booleans): a `boolean_combine` CONSUMES the two
         * bodies its `targetOperationId` / `toolOperationId` reference. The
         * consumed bodies leave this array entirely — no probes, no mesh
         * packet, no stream sequence is emitted for them — and only the
         * boolean's output body appears, at the boolean's position in document
         * order. Consumed is consumed: a later operation referencing an
         * already-consumed operation id fails the request with
         * REFERENCE_MISSING carrying the later operation's id (no DAG reuse).
         * A boolean whose result contains no solid material (a cut that
         * consumes its entire target, an intersect of non-overlapping bodies)
         * or that would produce several disjoint solids fails the request with
         * GEOMETRY_FAILED naming the boolean kind — the kernel never fabricates
         * an "empty body" entry.
         */
        bodies: z.array(
          z
            .object({
              bodyId: z.string().uuid(),
              operationId: z.string().uuid(),
              /**
               * Which born body of `operationId` this is (ADR-013 decision 3).
               *
               * The array was "one entry per body-producing operation"; it is
               * now "one entry per BORN BODY". Only a declared birth operation
               * (a multi-solid import) may contribute several entries, and they
               * carry 0..N-1 in the canonical order the operation declared.
               * Absent means 0, so every single-output operation's entry is
               * byte-identical to what it always was.
               *
               * A FEATURE op that fragments is still GEOMETRY_FAILED — a fillet
               * must never silently split a part into two — and a birth op that
               * produces a different count than it declared is also
               * GEOMETRY_FAILED, never a silent truncation. Neither guard lives
               * here; this field is what lets the host tell the two apart.
               */
              outputIndex: z.number().int().nonnegative().optional(),
              probes: shapeProbesSchema,
              mesh: meshDescriptorSchema.extend({ format: aembFormatSchema }),
              topology: topologySnapshotSchema.optional(),
              topologySelection: topologySelectionEvidenceSchema.optional(),
              /**
               * Lineage-derived element names (integration tranche N0),
               * present only when the request set `includeElementNames`.
               * Total coverage: exactly one entry per face/edge/vertex of
               * this body, correlated by token through the same enumeration
               * that mints the topology snapshot's tokens — a resolver's
               * "no match" therefore honestly means missing, never "the
               * mapper skipped it".
               */
              elementNames: z
                .array(elementNameEntrySchema)
                .max(1_000_000)
                .optional(),
            })
            .strict(),
        ),
      })
      .strict(),
    z
      .object({
        type: z.literal("definition_evaluation"),
        definitionId: z.string().uuid(),
        revisionHash: z.string().min(1).max(128),
        epoch: z.number().int().nonnegative(),
        bodies: z.array(
          z
            .object({
              /**
               * The definition's OWN stable body identity — literally the
               * producing operation's `outputBodyId` (document-authored, per
               * operations.ts), renamed on this wire shape to make clear it
               * is a DEFINITION-scoped identity, not a document/occurrence
               * identity (assembly doc §4.2
               * `ViewportDefinitionBody.definitionBodyId`).
               */
              definitionBodyId: z.string().uuid(),
              operationId: z.string().uuid(),
              outputIndex: z.number().int().nonnegative().optional(),
              probes: shapeProbesSchema,
              mesh: meshDescriptorSchema.extend({ format: aembFormatSchema }),
              topology: topologySnapshotSchema.optional(),
              elementNames: z
                .array(elementNameEntrySchema)
                .max(1_000_000)
                .optional(),
              /**
               * Deterministic per-body cache-line label for a future
               * collision BVH/convex-proxy cache (ASM-010,
               * native/assembly-host). ALWAYS
               * `${revisionHash}:${definitionBodyId}` — computed once on the
               * native side (see native/kernel-host/src/geometry.hpp's
               * `CollisionShapeCacheKey`) so no later consumer re-derives it
               * differently. Assembly doc §4.1: "a collision-shape cache
               * key."
               */
              collisionShapeCacheKey: z.string().min(1),
            })
            .strict(),
        ),
      })
      .strict(),
    z
      .object({
        type: z.literal("step_export"),
        outputPath: z.string(),
        bodyCount: z.number().int().nonnegative(),
        byteLength: z.number().int().nonnegative(),
      })
      .strict(),
    z
      .object({
        type: z.literal("export_mesh"),
        revision: z.number().int().nonnegative(),
        epoch: z.number().int().nonnegative(),
        /**
         * One entry per unconsumed body-producing operation of the committed
         * revision, in document order — the SAME set `evaluation` returns, but
         * each mesh is tessellated at the ABSOLUTE export tolerance (finding-10)
         * rather than the size-relative viewport LOD. Export needs only the
         * operation identity and the packet, so a body carries neither probes
         * nor topology.
         */
        bodies: z.array(
          z
            .object({
              bodyId: z.string().uuid(),
              operationId: z.string().uuid(),
              /** Which born body of `operationId`; absent means 0 (ADR-013). */
              outputIndex: z.number().int().nonnegative().optional(),
              mesh: meshDescriptorSchema.extend({ format: aembFormatSchema }),
            })
            .strict(),
        ),
      })
      .strict(),
    z
      .object({ type: z.literal("step_inspection"), probes: shapeProbesSchema })
      .strict(),
    z
      .object({
        type: z.literal("mutation_case"),
        epoch: z.number().int().nonnegative(),
        fixtureKind: mutationFixtureKindSchema,
        /** Entrant-visible snapshots. Free of oracle lineage. */
        before: topologySnapshotSchema,
        after: topologySnapshotSchema,
        beforeProbes: shapeProbesSchema,
        afterProbes: shapeProbesSchema,
        /** Oracle-only payload. Must never be surfaced to a tournament entrant. */
        oracle: z
          .object({
            entries: z.array(mutationOracleEntrySchema).max(1_000_000),
          })
          .strict(),
        /**
         * Lineage-derived element names (NG-2 Phase A), present only when
         * the request set `includeElementNames`. Total coverage: exactly one
         * entry per entity of the corresponding snapshot, correlated by
         * token through the same enumeration that minted the tokens — a
         * resolver's "no match" therefore honestly means missing, never
         * "the mapper skipped it".
         */
        beforeElementNames: z
          .array(elementNameEntrySchema)
          .max(1_000_000)
          .optional(),
        afterElementNames: z
          .array(elementNameEntrySchema)
          .max(1_000_000)
          .optional(),
      })
      .strict(),
    z
      .object({
        type: z.literal("ocaf_case"),
        /** One outcome per request target, in request order. */
        outcomes: z.array(ocafCaseOutcomeSchema).max(10_000),
      })
      .strict(),
    z
      .object({
        type: z.literal("query"),
        /** Canonical order (plan 05 §6.4): the pipeline's final Sn. */
        entities: z.array(resolvedEntitySchema).max(1_000_000),
        diagnostics: z.array(selDiagnosticSchema).max(1_000),
        /**
         * |S0|, |S1|, ..., |Sn| — one entry per pipeline stage (the kindHead
         * expansion plus one per filter, plan 05 §4.1/§8.1). Lets a caller
         * that gets zero results attribute exactly which filter zeroed the
         * set and build an E_SEL_EMPTY repair payload; the kernel host itself
         * does not throw E_SEL_EMPTY (query is a pure evaluator — arity
         * enforcement and error-code emission belong to the ref-resolving
         * executor, a later tranche).
         */
        stageCardinalities: z.array(z.number().int().nonnegative()).max(17),
      })
      .strict(),
    /**
     * The solver's answer (CAP-037). `status` is the outcome vocabulary from
     * the ADR-016 seam, and the diagnosis names OUR constraint ids — the
     * kernel never returns PlaneGCS text or tag integers.
     */
    z
      .object({
        type: z.literal("sketch_solution"),
        status: z.enum([
          "converged",
          "conflicting",
          "redundant",
          "did-not-converge",
          "invalid",
        ]),
        /** Present on `converged` and `redundant`; absent otherwise. */
        solution: sketchSolutionSchema.optional(),
        /** Constraint ids, NAMED not counted, per `status`. */
        conflicting: z.array(sketchConstraintIdSchema).max(2048),
        redundant: z.array(sketchConstraintIdSchema).max(2048),
        /** A sentence in our words, safe to show a person. */
        message: z.string().max(2048),
      })
      .strict(),
    /**
     * A drawing view's line work: polylines in view coordinates (paper axes,
     * model millimetres — the view's scale is the document layer's business),
     * each VISIBLE (solid ink) or hidden (dashed). Coincident hidden ink is
     * kept: visible-over-hidden precedence is the renderer's call.
     */
    z
      .object({
        type: z.literal("hlr_projection"),
        segments: z
          .array(
            z
              .object({
                visible: z.boolean(),
                /** Flattened x0,y0,x1,y1,… — at least two points. */
                points: z.array(z.number()).min(4),
              })
              .strict(),
          )
          .max(100_000),
        bounds: z
          .object({
            minX: z.number(),
            minY: z.number(),
            maxX: z.number(),
            maxY: z.number(),
          })
          .strict(),
        bodyCount: z.number().int().nonnegative(),
        /**
         * CLOSED boundary loops of every cut face lying on the requested
         * section plane, in the same view coordinates as `segments`: each is
         * flattened x,y pairs with the first point NOT repeated at the end,
         * and a cut face's outer boundary and each of its holes are their
         * own loop. Present (possibly empty) exactly when the request
         * carried `sectionPlane`; absent otherwise.
         */
        sectionOutlines: z
          .array(
            z
              .object({
                /** Flattened x0,y0,… — at least three points. */
                points: z.array(z.number()).min(6),
              })
              .strict(),
          )
          .max(100_000)
          .optional(),
      })
      .strict(),
    /**
     * One solved study: the voxel-skin heat-map mesh, the recovered scalar
     * field's name and range over the EMITTED vertices, and the solve's own
     * honest accounting (element/node counts and the CG iterations actually
     * run). The refinement pins the physics coherence the mirror promises:
     * scalar.name is "vonMisesMPa" exactly for static-stress and
     * "temperatureC" for steady-heat, and displacementMaxMm (max nodal |u|
     * in mm) is present exactly for static-stress.
     */
    z
      .object({
        type: z.literal("simulation_result"),
        kind: simulationStudyKindSchema,
        mesh: simulationMeshSchema,
        scalar: z
          .object({
            name: simulationScalarNameSchema,
            min: z.number().finite(),
            max: z.number().finite(),
          })
          .strict(),
        displacementMaxMm: z.number().finite().nonnegative().optional(),
        summary: z
          .object({
            elementCount: z.number().int().nonnegative(),
            nodeCount: z.number().int().nonnegative(),
            iterations: z.number().int().nonnegative(),
          })
          .strict(),
      })
      .strict()
      .superRefine((result, context) => {
        const expectedName =
          result.kind === "static-stress" ? "vonMisesMPa" : "temperatureC";
        if (result.scalar.name !== expectedName) {
          context.addIssue({
            code: "custom",
            message: `a ${result.kind} result reports "${expectedName}"`,
            path: ["scalar", "name"],
          });
        }
        if (
          (result.kind === "static-stress") !==
          (result.displacementMaxMm !== undefined)
        ) {
          context.addIssue({
            code: "custom",
            message:
              "displacementMaxMm is present exactly for a static-stress result",
            path: ["displacementMaxMm"],
          });
        }
      }),
    /**
     * The answer to a `mold_draft_analysis` request. `type` is exactly
     * `"mold_draft_analysis"` — UNLIKE `simulate` -> `"simulation_result"`
     * or `hlr_project` -> `"hlr_projection"`, this response's type literal
     * matches its request `method` VERBATIM, not a distinct result-noun. A
     * naming trap the desktop-UI side of this catalog wave hit and fixed
     * once already (it first reached for `"mold_draft_analysis_result"` by
     * analogy with `simulation_result`) — recorded here, pinned by a test,
     * so it is not repeated.
     *
     * `faces` is an array of `{token, classification}` records — the SAME
     * array-of-records convention {@link elementNameEntrySchema} and
     * {@link topologySnapshotSchema}'s own `entities` already use for
     * per-entity kernel data, deliberately NOT a keyed map: every other
     * per-entity payload in this file is already an array (a map here would
     * be the one exception, not the pattern), and an array element carries
     * its own length bound and is duplicate-checked by the `superRefine`
     * below the same way `topologySnapshotSchema` duplicate-checks its own
     * `entities`. `token` is shaped like {@link elementNameEntrySchema}'s and
     * `topologyEntitySchema`'s own `token` (a bounded opaque string, NOT
     * {@link topologyTokenSchema}'s persisted `t:<opId>/<role>/<ordinal>`
     * ref-slot format) — the epoch-local token space a body's topology
     * snapshot and element names already use, so a caller that also
     * requested `includeTopology`/`includeElementNames` on the SAME body can
     * correlate a classified face back to its full topology entry or
     * lineage name by token equality.
     *
     * `counts` is the same tally `mold_parting_line`'s own executor keys off
     * to decide whether a pull direction has any draft variation at all
     * (`E_PARTING_LINE_NO_DRAFT_VARIATION` fires when every face lands in
     * one bucket) — reported here too so this read-only query answers the
     * identical question the authoring operation asks internally, without a
     * caller having to recount `faces` itself. The `superRefine` below
     * cross-checks both invariants: every `faces` token is unique (a
     * duplicate would mean the same face was classified twice, aliasing two
     * answers into one), and the four `counts` fields exactly equal the
     * tally of `faces`' own classifications, so `counts` can never silently
     * drift from what `faces` actually says.
     */
    z
      .object({
        type: z.literal("mold_draft_analysis"),
        bodyId: z.string().uuid(),
        faces: z
          .array(
            z
              .object({
                token: z.string().min(1).max(256),
                classification: z.enum([
                  "positive",
                  "negative",
                  "no-draft",
                  "straddle",
                ]),
              })
              .strict(),
          )
          .max(1_000_000),
        counts: z
          .object({
            positive: z.number().int().nonnegative(),
            negative: z.number().int().nonnegative(),
            noDraft: z.number().int().nonnegative(),
            straddle: z.number().int().nonnegative(),
          })
          .strict(),
      })
      .strict()
      .superRefine((result, context) => {
        const seenTokens = new Set<string>();
        const tally = { positive: 0, negative: 0, noDraft: 0, straddle: 0 };
        result.faces.forEach((face, index) => {
          if (seenTokens.has(face.token)) {
            context.addIssue({
              code: "custom",
              message: `Duplicate mold draft analysis face token ${face.token}`,
              path: ["faces", index, "token"],
            });
          } else {
            seenTokens.add(face.token);
          }
          if (face.classification === "positive") tally.positive += 1;
          else if (face.classification === "negative") tally.negative += 1;
          else if (face.classification === "no-draft") tally.noDraft += 1;
          else tally.straddle += 1;
        });
        if (tally.positive !== result.counts.positive) {
          context.addIssue({
            code: "custom",
            message: `counts.positive (${result.counts.positive}) does not match the tally of faces (${tally.positive})`,
            path: ["counts", "positive"],
          });
        }
        if (tally.negative !== result.counts.negative) {
          context.addIssue({
            code: "custom",
            message: `counts.negative (${result.counts.negative}) does not match the tally of faces (${tally.negative})`,
            path: ["counts", "negative"],
          });
        }
        if (tally.noDraft !== result.counts.noDraft) {
          context.addIssue({
            code: "custom",
            message: `counts.noDraft (${result.counts.noDraft}) does not match the tally of faces (${tally.noDraft})`,
            path: ["counts", "noDraft"],
          });
        }
        if (tally.straddle !== result.counts.straddle) {
          context.addIssue({
            code: "custom",
            message: `counts.straddle (${result.counts.straddle}) does not match the tally of faces (${tally.straddle})`,
            path: ["counts", "straddle"],
          });
        }
      }),
    z
      .object({
        type: z.literal("cancellation"),
        targetRequestId: z.string().uuid(),
      })
      .strict(),
  ])
  .superRefine((result, context) => {
    // Evaluation identity integrity: every returned body must carry a unique
    // bodyId (or, for a definition_evaluation, definitionBodyId) and a unique
    // operationId. Downstream consumers key bodies by id (the viewport's
    // displayed-body map, the app's metadata map, selection), so a duplicate
    // id would alias two distinct bodies into one — the renderer showing one
    // while metadata, export counts, and selection disagree. A host that
    // reports duplicates is broken; reject the response at the protocol
    // boundary rather than let the collision propagate. The SAME invariant
    // applies to both wire shapes, so both run through this one code path.
    if (result.type !== "evaluation" && result.type !== "definition_evaluation")
      return;
    const idOf = (
      body: { bodyId: string } | { definitionBodyId: string },
    ): string => ("bodyId" in body ? body.bodyId : body.definitionBodyId);
    const bodyIds = new Set<string>();
    // ADR-013 decision 3 relaxed this array from "one entry per body-producing
    // OPERATION" to "one entry per BORN BODY", so an operationId may now repeat
    // — but only as a declared birth fan-out, which means its entries must form
    // a complete contiguous 0..N-1 index set. A duplicate index would make two
    // bodies claim to be the same one (mis-keying the replay cache and making
    // every reference scoped to that index ambiguous); a GAP is a body the host
    // dropped while still reporting success, which downstream is
    // indistinguishable from a smaller import. Neither is recoverable later, so
    // both are refused at the protocol boundary.
    const indicesByOperation = new Map<string, number[]>();
    for (const [index, body] of result.bodies.entries()) {
      const id = idOf(body);
      const idKey = "bodyId" in body ? "bodyId" : "definitionBodyId";
      if (bodyIds.has(id)) {
        context.addIssue({
          code: "custom",
          message: `Duplicate body id ${id} in evaluation result`,
          path: ["bodies", index, idKey],
        });
      }
      bodyIds.add(id);
      const indices = indicesByOperation.get(body.operationId) ?? [];
      indices.push(body.outputIndex ?? 0);
      indicesByOperation.set(body.operationId, indices);
    }
    for (const [operationId, indices] of indicesByOperation) {
      if (indices.length === 1) continue;
      const sorted = [...indices].sort((a, b) => a - b);
      if (sorted.every((value, position) => value === position)) continue;
      context.addIssue({
        code: "custom",
        message:
          `Operation ${operationId} returned output indices ` +
          `[${sorted.join(", ")}] in evaluation result; a birth operation's ` +
          `entries must form a complete 0..N-1 set`,
        path: ["bodies"],
      });
    }
  });

export const kernelResponseSchema = z.discriminatedUnion("ok", [
  z
    .object({
      protocolVersion: z.literal(kernelProtocolVersion),
      requestId: z.string().uuid(),
      ok: z.literal(true),
      result: kernelResultSchema,
    })
    .strict(),
  z
    .object({
      protocolVersion: z.literal(kernelProtocolVersion),
      requestId: z.string().uuid(),
      ok: z.literal(false),
      error: kernelErrorSchema,
    })
    .strict(),
]);

export type KernelRequest = z.infer<typeof kernelRequestSchema>;
export type KernelResponse = z.infer<typeof kernelResponseSchema>;
export type KernelResult = z.infer<typeof kernelResultSchema>;
export type MutationCaseResult = Extract<
  KernelResult,
  { type: "mutation_case" }
>;
export type OcafCaseResult = Extract<KernelResult, { type: "ocaf_case" }>;
export type SimulationResult = Extract<
  KernelResult,
  { type: "simulation_result" }
>;
export type DefinitionEvaluationResult = Extract<
  KernelResult,
  { type: "definition_evaluation" }
>;
export type ShapeProbes = z.infer<typeof shapeProbesSchema>;
export type BuildManifest = z.infer<typeof buildManifestSchema>;
