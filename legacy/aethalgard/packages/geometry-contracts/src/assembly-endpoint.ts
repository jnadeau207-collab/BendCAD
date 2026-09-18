import { z } from "zod";

import { operationRefSchema } from "./refs.js";

/**
 * ASM-001 (`docs/plan/07-assemblies/00-assembly-system.md` §2.2/§3) is the
 * eventual canonical owner of these two ids as part of
 * `ComponentDefinition`/`ComponentOccurrence`. ASM-001 has not landed in this
 * tree as of ASM-005's own admission-time grounding. These brands exist here
 * so ASM-005 is independently buildable and testable; because TS brand
 * identity is structural on the literal brand string, a later
 * `ComponentOccurrenceId` exported by ASM-001 under the identical brand
 * string (`"ComponentOccurrenceId"`) unifies with this one with zero code
 * change. If ASM-001 already exports these when this capability is actually
 * implemented, DELETE these two lines and import from ASM-001's file instead
 * — do not maintain two independent schemas.
 */
export const componentDefinitionIdSchema = z
  .string()
  .uuid()
  .brand<"ComponentDefinitionId">();

export const componentOccurrenceIdSchema = z
  .string()
  .uuid()
  .brand<"ComponentOccurrenceId">();

export type ComponentDefinitionId = z.infer<typeof componentDefinitionIdSchema>;

export type ComponentOccurrenceId = z.infer<typeof componentOccurrenceIdSchema>;

/**
 * Spec §3's `AssemblyEndpoint.expectedGeometry` union — the geometry kind an
 * assembly endpoint author declared before resolution, checked against what
 * the selector actually resolves to (`assemblyEndpointGeometryRules` below).
 */
export const assemblyEndpointGeometrySchema = z.enum([
  "point",
  "line",
  "axis",
  "plane",
  "circle",
  "cylinder",
  "cone",
  "sphere",
  "coordinate_frame",
]);

export type AssemblyEndpointGeometry = z.infer<
  typeof assemblyEndpointGeometrySchema
>;

/**
 * Spec §3's `AssemblyEndpoint` interface: `{ occurrenceId, selector,
 * expectedGeometry }`. A mate endpoint is authored from a recorded durable
 * selector, never raw pick data (spec §5) — the selector is an
 * `OperationRef` rooted in the referenced definition's operation provenance,
 * and its arity must resolve to exactly one entity: an endpoint that could
 * match zero or several entities is not a place a mate can attach.
 */
export const assemblyEndpointSchema = z
  .object({
    occurrenceId: componentOccurrenceIdSchema,
    selector: operationRefSchema,
    expectedGeometry: assemblyEndpointGeometrySchema,
  })
  .strict()
  .refine((endpoint) => endpoint.selector.arity === "one", {
    message:
      'An assembly endpoint selector must resolve to exactly one entity (arity "one")',
    path: ["selector", "arity"],
  });

export type AssemblyEndpoint = z.infer<typeof assemblyEndpointSchema>;

/**
 * The static geometry-kind mapping table: the single TS-side source of truth
 * for which AQL head-kind and which OCCT analytic geometry class(es) an
 * endpoint's declared `expectedGeometry` requires at resolution time.
 * `selectorKind` undefined means no static kind constraint on the selector;
 * `analyticClasses` undefined means unconstrained/never-resolvable. Both are
 * undefined only for `coordinate_frame` (see the ruling below).
 */
export interface AssemblyEndpointGeometryRule {
  readonly selectorKind: "faces" | "edges" | "vertices" | undefined;
  readonly analyticClasses: readonly string[] | undefined;
}

/**
 * RULING (this is a delivering-session decision): `"axis"` and `"line"` share
 * an identical analytic requirement (a straight edge/datum axis,
 * `CurveClass === "line"`) — the two words exist for AUTHORING clarity only
 * (did the person pick a datum axis or a plain straight edge), never a
 * geometric distinction. `"coordinate_frame"` is accepted structurally (the
 * schema must parse it, since spec §3 pins it as a legal value every
 * downstream agent may rely on) but NO kernel operation in this tree can
 * currently produce a resolvable coordinate-frame entity (no
 * `datum_frame`/`datum_coordinate_system` operation exists — confirmed by
 * reading `native/kernel-host/src/datum_feature.hpp`, which only offers
 * `EvaluateDatumPlane`/`EvaluateDatumAxis`). Every `coordinate_frame`
 * endpoint therefore resolves to kernel status `invalidated` unconditionally
 * in this capability; a future capability that adds a real datum-frame
 * operation must revisit this rule, not silently reinterpret it.
 */
export const assemblyEndpointGeometryRules: Readonly<
  Record<AssemblyEndpointGeometry, AssemblyEndpointGeometryRule>
> = {
  point: { selectorKind: "vertices", analyticClasses: ["point"] },
  line: { selectorKind: "edges", analyticClasses: ["line"] },
  axis: { selectorKind: "edges", analyticClasses: ["line"] },
  circle: { selectorKind: "edges", analyticClasses: ["circle"] },
  plane: { selectorKind: "faces", analyticClasses: ["plane"] },
  cylinder: { selectorKind: "faces", analyticClasses: ["cylinder"] },
  cone: { selectorKind: "faces", analyticClasses: ["cone"] },
  sphere: { selectorKind: "faces", analyticClasses: ["sphere"] },
  coordinate_frame: { selectorKind: undefined, analyticClasses: undefined },
};
