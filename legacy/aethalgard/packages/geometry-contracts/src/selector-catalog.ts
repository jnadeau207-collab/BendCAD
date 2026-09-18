import type { SelectorKind } from "./selector-ast.js";

/**
 * The normative v1 filter catalog (plan 05 §3.2): which entity kinds each
 * filter applies to and what arguments it takes. This table is the single
 * static-checking authority shared by the parser, the printer's
 * default-omission rule, ref validation, and the op-hash ref projection; the
 * native evaluator implements the semantics.
 *
 * Home: `@aeth/geometry-contracts` (beside the AST types it references), so the
 * op-hash — which projects each ref slot over `printSelector` (N6 A′) — can
 * reach it without inverting the package layering (`@aeth/document-model`
 * depends on this package, not the reverse). document-model re-exports it, so
 * its parser / ref-validation consumers are unchanged.
 */

export type ParamType =
  | "number"
  | "ident"
  | "axis"
  | "direction"
  | "point" // 2 or 3 components
  | "point2" // exactly 2 components
  | "query";

/** Constraint on a nested query argument's head kind. */
export type NestedQueryKind =
  | "any" // adjacentTo: neighborhood crosses kinds
  | "same" // union/not: kinds must match the outer query
  | "faces" // boundaryOf/interiorTo: loop/shared edges OF faces
  | "faces-or-edges"; // on: boundary of faces (or edges, for vertices)

export interface ParamSpec {
  readonly type: ParamType;
  readonly optional?: boolean;
  /**
   * Canonical-printing default (plan 05 §3.4): an optional numeric argument
   * exactly equal to its default is omitted from the canonical string, and
   * the parser fills it back in — so defaulted and explicit forms produce
   * the identical AST.
   */
  readonly defaultValue?: number;
  readonly integer?: boolean;
  readonly minimum?: number;
  readonly nestedKind?: NestedQueryKind;
}

export interface FilterSpec {
  readonly kinds: readonly SelectorKind[];
  readonly params: readonly ParamSpec[];
}

const F = "faces" as const;
const E = "edges" as const;
const V = "vertices" as const;
const B = "bodies" as const;
const R = "regions" as const;

const noArgs: readonly ParamSpec[] = [];

export const filterCatalog: ReadonlyMap<string, FilterSpec> = new Map<
  string,
  FilterSpec
>([
  // Creation / role
  ["created", { kinds: [F, E, V, B], params: noArgs }],
  ["modified", { kinds: [F, E, V, B], params: noArgs }],
  ["role", { kinds: [F, E, V], params: [{ type: "ident" }] }],
  // Geometric class
  ["planar", { kinds: [F], params: noArgs }],
  ["cylindrical", { kinds: [F], params: noArgs }],
  ["conical", { kinds: [F], params: noArgs }],
  ["spherical", { kinds: [F], params: noArgs }],
  ["toroidal", { kinds: [F], params: noArgs }],
  ["freeform", { kinds: [F], params: noArgs }],
  ["line", { kinds: [E], params: noArgs }],
  ["circle", { kinds: [E], params: noArgs }],
  ["ellipse", { kinds: [E], params: noArgs }],
  ["bspline", { kinds: [E], params: noArgs }],
  // Directional (default angular tolerance 1.0°)
  [
    "normal",
    {
      kinds: [F],
      params: [
        { type: "direction" },
        { type: "number", optional: true, defaultValue: 1 },
      ],
    },
  ],
  [
    "parallel",
    {
      kinds: [F, E],
      params: [
        { type: "direction" },
        { type: "number", optional: true, defaultValue: 1 },
      ],
    },
  ],
  [
    "perpendicular",
    {
      kinds: [F, E],
      params: [
        { type: "direction" },
        { type: "number", optional: true, defaultValue: 1 },
      ],
    },
  ],
  // axisAligned is grammar sugar: the parser desugars it to `parallel` on
  // the named world axis (plan 05 §3.4), so it never appears in a canonical
  // AST. Its catalog entry exists so the pre-desugar kind check still runs.
  [
    "axisAligned",
    {
      kinds: [F, E],
      params: [
        { type: "axis" },
        { type: "number", optional: true, defaultValue: 1 },
      ],
    },
  ],
  // Positional
  ["min", { kinds: [F, E, V, B, R], params: [{ type: "axis" }] }],
  ["max", { kinds: [F, E, V, B, R], params: [{ type: "axis" }] }],
  [
    "at",
    {
      kinds: [F, E, V, R],
      params: [
        { type: "point" },
        { type: "number", optional: true, defaultValue: 0.5 },
      ],
    },
  ],
  [
    "within",
    { kinds: [F, E, V, B], params: [{ type: "point" }, { type: "point" }] },
  ],
  ["containing", { kinds: [R], params: [{ type: "point2" }] }],
  [
    "onGround",
    {
      kinds: [F],
      params: [{ type: "number", optional: true, defaultValue: 1e-3 }],
    },
  ],
  // Size / measure
  [
    "largest",
    {
      kinds: [F, E, B, R],
      params: [
        {
          type: "number",
          optional: true,
          defaultValue: 1,
          integer: true,
          minimum: 1,
        },
      ],
    },
  ],
  [
    "smallest",
    {
      kinds: [F, E, B, R],
      params: [
        {
          type: "number",
          optional: true,
          defaultValue: 1,
          integer: true,
          minimum: 1,
        },
      ],
    },
  ],
  ["area", { kinds: [F, R], params: [{ type: "number" }, { type: "number" }] }],
  ["length", { kinds: [E], params: [{ type: "number" }, { type: "number" }] }],
  [
    "radius",
    {
      kinds: [F, E],
      params: [
        { type: "number" },
        { type: "number", optional: true, defaultValue: 1e-3 },
      ],
    },
  ],
  [
    "radiusBetween",
    { kinds: [F, E], params: [{ type: "number" }, { type: "number" }] },
  ],
  // Topological
  ["convex", { kinds: [E], params: noArgs }],
  ["concave", { kinds: [E], params: noArgs }],
  [
    "smooth",
    {
      kinds: [E],
      params: [{ type: "number", optional: true, defaultValue: 1 }],
    },
  ],
  [
    "adjacentTo",
    { kinds: [F, E, V], params: [{ type: "query", nestedKind: "any" }] },
  ],
  [
    "on",
    {
      kinds: [E, V],
      params: [{ type: "query", nestedKind: "faces-or-edges" }],
    },
  ],
  [
    "boundaryOf",
    { kinds: [E], params: [{ type: "query", nestedKind: "faces" }] },
  ],
  [
    "interiorTo",
    { kinds: [E], params: [{ type: "query", nestedKind: "faces" }] },
  ],
  // Set / order
  [
    "union",
    {
      kinds: [F, E, V, B, R],
      params: [{ type: "query", nestedKind: "same" }],
    },
  ],
  [
    "not",
    {
      kinds: [F, E, V, B, R],
      params: [{ type: "query", nestedKind: "same" }],
    },
  ],
  [
    "nth",
    {
      kinds: [F, E, V, B, R],
      params: [{ type: "number", integer: true, minimum: 0 }],
    },
  ],
  [
    "first",
    {
      kinds: [F, E, V, B, R],
      params: [{ type: "number", integer: true, minimum: 1 }],
    },
  ],
]);
