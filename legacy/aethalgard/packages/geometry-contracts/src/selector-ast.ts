import { z } from "zod";

/**
 * AQL selector AST — wire mirror (plan 05 §4.2, ADR-006).
 *
 * This file structurally mirrors `@aeth/document-model/src/selector/ast.ts`
 * (the `SelectorQuery`/`SelectorArg`/... shapes and the `SelectorKind`,
 * `WorldName`, `AxisName` unions) by convention, not by dependency: this
 * package never imports `@aeth/document-model`, since that would invert the
 * existing layering (document-model depends on geometry-contracts, not the
 * reverse). A `SelectorQuery` value produced by document-model's parser
 * passes validation here purely because both sides describe the same
 * JSON-serializable structural shape — TypeScript structural typing plus
 * JSON-serializability make the mirror work without an edge in the graph.
 *
 * This is the wire representation the kernel host's `query` request/result
 * pair (kernel-protocol.ts) consumes. The raw AQL query STRING never crosses
 * the kernel-host process boundary; only this parsed, doc-model-validated
 * AST does. Doc-model owns parsing, kind-matching, and rootedness checks
 * before ever building a `query` request — the kernel evaluator trusts the
 * shape and implements only evaluation semantics.
 *
 * Limits mirrored from document-model's ast.ts (enforced there at parse
 * time; the bounds below are this schema's own envelope, not a re-check of
 * document-model's enforcement): `maxQueryLength` = 2048, `maxNestingDepth`
 * = 4, `maxFiltersPerQuery` = 16.
 */

export const worldNameSchema = z.enum([
  "xy",
  "xz",
  "yz",
  "x",
  "y",
  "z",
  "origin",
]);
export type WorldName = z.infer<typeof worldNameSchema>;

export const axisNameSchema = z.enum(["x", "y", "z"]);
export type AxisName = z.infer<typeof axisNameSchema>;

export const selectorKindSchema = z.enum([
  "faces",
  "edges",
  "vertices",
  "bodies",
  "regions",
]);
export type SelectorKind = z.infer<typeof selectorKindSchema>;

export const selectorSourceSchema = z.discriminatedUnion("source", [
  z.object({ source: z.literal("op"), opId: z.string() }).strict(),
  z.object({ source: z.literal("body"), opId: z.string() }).strict(),
  z.object({ source: z.literal("sketch"), opId: z.string() }).strict(),
  z.object({ source: z.literal("tag"), tag: z.string() }).strict(),
  z.object({ source: z.literal("token"), token: z.string() }).strict(),
  z.object({ source: z.literal("world"), world: worldNameSchema }).strict(),
  z.object({ source: z.literal("all") }).strict(),
]);
export type SelectorSource = z.infer<typeof selectorSourceSchema>;

export const selectorDirectionSchema = z.discriminatedUnion("form", [
  z
    .object({
      form: z.literal("axis"),
      sign: z.union([z.literal(1), z.literal(-1)]),
      axis: axisNameSchema,
    })
    .strict(),
  z
    .object({
      form: z.literal("vector"),
      vector: z.tuple([
        z.number().finite(),
        z.number().finite(),
        z.number().finite(),
      ]),
    })
    .strict(),
]);
/**
 * Manual type (not `z.infer`) so the vector is `readonly` and matches the
 * document-model AST. Zod still validates at runtime; inferred tuple elements
 * would otherwise be mutable and break `parseSelector` → geometry-contracts
 * assignment at the selection-recording boundary.
 */
export type SelectorDirection =
  | { readonly form: "axis"; readonly sign: 1 | -1; readonly axis: AxisName }
  | {
      readonly form: "vector";
      readonly vector: readonly [number, number, number];
    };

/**
 * The three recursive shapes (`SelectorArg` -> `SelectorQuery` ->
 * `SelectorFilter` -> `SelectorArg`) are declared as plain TS types first so
 * `z.ZodType<T>` can annotate the `z.lazy(...)` schema that breaks the cycle
 * below — zod cannot infer a self-referential type from the schema alone.
 */
export type SelectorArg =
  | { readonly arg: "number"; readonly value: number }
  | { readonly arg: "string"; readonly value: string }
  | { readonly arg: "ident"; readonly value: string }
  | { readonly arg: "axis"; readonly value: AxisName }
  | { readonly arg: "direction"; readonly value: SelectorDirection }
  | { readonly arg: "point"; readonly value: readonly number[] }
  | { readonly arg: "query"; readonly value: SelectorQuery };

export interface SelectorFilter {
  readonly name: string;
  readonly args: readonly SelectorArg[];
}

export interface SelectorQuery {
  readonly kind: SelectorKind;
  readonly scope: readonly SelectorSource[];
  readonly filters: readonly SelectorFilter[];
}

/**
 * The only back-edge in the cycle: `arg: "query"` reaches forward to
 * `selectorQuerySchema`, which is declared later in this file. `z.lazy`
 * defers evaluation of the callback until parse time, by which point every
 * const below has been assigned — module-level statements all run before
 * any schema actually parses a value.
 */
export const selectorArgSchema: z.ZodType<SelectorArg> = z.lazy(() =>
  z.discriminatedUnion("arg", [
    z.object({ arg: z.literal("number"), value: z.number().finite() }).strict(),
    z.object({ arg: z.literal("string"), value: z.string() }).strict(),
    z.object({ arg: z.literal("ident"), value: z.string() }).strict(),
    z.object({ arg: z.literal("axis"), value: axisNameSchema }).strict(),
    z
      .object({ arg: z.literal("direction"), value: selectorDirectionSchema })
      .strict(),
    z
      .object({
        arg: z.literal("point"),
        value: z.array(z.number().finite()).min(2).max(3),
      })
      .strict(),
    z.object({ arg: z.literal("query"), value: selectorQuerySchema }).strict(),
  ]),
);

export const selectorFilterSchema: z.ZodType<SelectorFilter> = z
  .object({
    name: z.string().min(1),
    // No filter in the catalog takes more than 2-3 args; 8 is generous
    // headroom without leaving the envelope effectively unbounded.
    args: z.array(selectorArgSchema).max(8),
  })
  .strict();

export const selectorQuerySchema: z.ZodType<SelectorQuery> = z
  .object({
    kind: selectorKindSchema,
    scope: z.array(selectorSourceSchema).min(1),
    // Mirrors document-model's maxFiltersPerQuery (16).
    filters: z.array(selectorFilterSchema).max(16),
  })
  .strict();
