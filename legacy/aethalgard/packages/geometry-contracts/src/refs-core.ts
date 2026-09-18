import { z } from "zod";

import { selectorQuerySchema } from "./selector-ast.js";

/**
 * Operation reference slots (plan 01 §7.1/§7.3, plan 05): the persisted form
 * of a topology reference. A ref is an AQL query string plus resolution
 * policy plus optional recorded anchors. Anchors are HINTS — written by the
 * UI at click time, refreshed opportunistically, excluded from document
 * hashing, and never authoritative (plan 05 §9.3: they disambiguate only
 * through the two-channel lattice; a lone anchor match can never silently
 * rebind a reference).
 *
 * These schemas are envelope-shape only. Parsing the query, kind-matching it
 * against the slot, and rootedness live in @aeth/document-model (which owns
 * the AQL parser); resolution lives in the kernel host. No operation schema
 * consumes a ref slot until the executor actually resolves it — a schema
 * that accepted a ref the kernel ignored would silently produce wrong
 * geometry, which is the one unrepresentable outcome.
 *
 * Token format tracks the shipped id formats (see the N1 note in
 * @aeth/document-model selector/ast.ts): `t:<opId>/<role>/<ordinal>` where
 * opId is a UUID (the production format) or legacy `op_<base32>`.
 */

const uuidPattern =
  "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}";

/**
 * `t:<opId>[:<outputIndex>]/<role>/<ordinal>` (ADR-013 decision 2, ruled in
 * `docs/design/2026-07-28-multi-output-birth-residuals.md`).
 *
 * A birth operation may produce SEVERAL bodies (a multi-solid STEP import), and
 * element enumeration is per-(op, output body). The index therefore has to live
 * INSIDE the token: if it sat beside the token in the ref envelope, face 3 of
 * solid A and face 3 of solid B of the same import would mint the identical
 * string, and the one property a token exists to have — naming exactly one
 * entity — would stop being true.
 *
 * The index is OPTIONAL and absent means 0, so every token persisted before
 * schema 3 parses and resolves unchanged. That back-compatibility is not a
 * courtesy; it is what lets a schema-2 document round-trip byte-identically.
 */
export const topologyTokenPattern = new RegExp(
  `^t:(?:op_[0-9a-z]{1,26}|${uuidPattern})(?::[0-9]+)?/[a-z][a-z0-9-]*/[0-9]+$`,
);

export const topologyTokenSchema = z
  .string()
  .max(256)
  .regex(topologyTokenPattern, {
    message: "Topology token must be t:<opId>[:<outputIndex>]/<role>/<ordinal>",
  });

/** The parsed parts of a topology token. */
export interface ParsedTopologyToken {
  readonly operationId: string;
  /** Which born body of that operation; 0 for single-output ops and legacy tokens. */
  readonly outputIndex: number;
  readonly role: string;
  readonly ordinal: number;
}

/**
 * Splits a topology token, or returns undefined when it is not one.
 *
 * The op id may itself contain no colon (a UUID has none, and the legacy
 * `op_<base32>` form is lowercase alphanumeric), so the LAST colon before the
 * first slash is unambiguously the output-index separator when present.
 */
export function parseTopologyToken(
  token: string,
): ParsedTopologyToken | undefined {
  if (!topologyTokenPattern.test(token)) return undefined;
  const firstSlash = token.indexOf("/");
  const head = token.slice(2, firstSlash);
  const rest = token.slice(firstSlash + 1);
  const separator = head.lastIndexOf(":");
  const operationId = separator === -1 ? head : head.slice(0, separator);
  const outputIndex =
    separator === -1 ? 0 : Number.parseInt(head.slice(separator + 1), 10);
  const [role = "", ordinalText = ""] = rest.split("/");
  return {
    operationId,
    outputIndex,
    role,
    ordinal: Number.parseInt(ordinalText, 10),
  };
}

/**
 * Builds a topology token. `outputIndex` 0 emits the LEGACY form (no index) so
 * a single-output operation mints exactly the bytes it always did — which is
 * what keeps existing documents, their op-hashes, and their replay-cache keys
 * unchanged by this contract growing.
 */
export function formatTopologyToken(parts: {
  readonly operationId: string;
  readonly outputIndex?: number;
  readonly role: string;
  readonly ordinal: number;
}): string {
  const index = parts.outputIndex ?? 0;
  const scope =
    index === 0 ? parts.operationId : `${parts.operationId}:${String(index)}`;
  return `t:${scope}/${parts.role}/${String(parts.ordinal)}`;
}

export const referenceEntityKindSchema = z.enum([
  "face",
  "edge",
  "vertex",
  "body",
  "region",
]);

export type ReferenceEntityKind = z.infer<typeof referenceEntityKindSchema>;

/**
 * A recorded fingerprint of one entity a ref resolved to at record time
 * (plan 01 §7.1 `$defs/anchor`). Every field beyond the token is optional
 * measurement context for the signature channel's scoring (plan 05 §9.3).
 */
export const referenceAnchorSchema = z
  .object({
    token: topologyTokenSchema,
    kind: referenceEntityKindSchema.optional(),
    surface: z
      .enum(["plane", "cylinder", "cone", "sphere", "torus", "freeform"])
      .optional(),
    curve: z.enum(["line", "circle", "ellipse", "bspline", "other"]).optional(),
    centroid: z
      .tuple([z.number().finite(), z.number().finite(), z.number().finite()])
      .optional(),
    normal: z
      .tuple([z.number().finite(), z.number().finite(), z.number().finite()])
      .optional(),
    area: z.number().finite().nonnegative().optional(),
    length: z.number().finite().nonnegative().optional(),
    /** FNV-1a hex of sorted neighbor tokens at record time. */
    adjHash: z
      .string()
      .max(64)
      .regex(/^[0-9a-f]+$/)
      .optional(),
  })
  .strict();

export type ReferenceAnchor = z.infer<typeof referenceAnchorSchema>;

/**
 * Expected result cardinality, checked AFTER resolution (plan 01 §7.3):
 * `one` with 0 matches is E_SEL_EMPTY, with >1 is E_SEL_AMBIGUOUS (recovery
 * per plan 05 §8/§9); range form for slots like pattern seeds.
 */
export const referenceAritySchema = z.union([
  z.enum(["one", "one-or-more", "any"]),
  z
    .object({
      min: z.number().int().nonnegative(),
      max: z.number().int().positive().optional(),
    })
    .strict()
    .refine((range) => range.max === undefined || range.max >= range.min, {
      message: "arity.max must be >= arity.min",
    }),
]);

export type ReferenceArity = z.infer<typeof referenceAritySchema>;

/** One named ref slot's persisted value (plan 01 §7.1 `$defs/ref`). */
export const operationRefSchema = z
  .object({
    /**
     * AQL query string (grammar: plan 05 §3; parser in
     * @aeth/document-model). The 2048-char ceiling matches the parser's
     * E_SEL_TOO_LONG limit so an envelope-valid query can never be
     * rejected later on length alone.
     */
    query: z.string().min(1).max(2048),
    arity: referenceAritySchema.default("one"),
    /**
     * Bounded hint list: recorded fingerprints, never authoritative and
     * excluded from hashing. 64 anchors comfortably covers plan 05 §7's
     * multi-select fusion (union chains cap at 8 operands) while keeping
     * the envelope byte-bounded.
     */
    anchors: z.array(referenceAnchorSchema).max(64).default([]),
    onEmpty: z.enum(["error", "skip-op", "empty-ok"]).default("error"),
  })
  .strict();

export type OperationRef = z.infer<typeof operationRefSchema>;

/**
 * The KERNEL-WIRE form of a ref slot (plan 05 §4.2). Structurally identical to
 * {@link operationRefSchema} except the persisted AQL `query` STRING is
 * replaced by the parsed `ast` ({@link selectorQuerySchema}): the raw query
 * string never crosses the kernel-host process boundary. Document-model owns
 * parsing, kind-matching, and rootedness — it validates the persisted `query`
 * and, having produced the canonical AST, ships THIS shape to the kernel. The
 * `arity` / `anchors` / `onEmpty` resolution policy carries through unchanged
 * (anchors remain hints, never authoritative). The native selector evaluator
 * (tranche N4) consumes exactly this shape.
 *
 * This is not persisted and not hashed — it is a transport mirror of a
 * `operationRefSchema` value whose `query` has been parsed. Keeping it beside
 * the persisted schema means the two can never drift in their arity/anchor/
 * onEmpty contract.
 */
export const operationRefWireSchema = z
  .object({
    ast: selectorQuerySchema,
    arity: referenceAritySchema.default("one"),
    anchors: z.array(referenceAnchorSchema).max(64).default([]),
    onEmpty: z.enum(["error", "skip-op", "empty-ok"]).default("error"),
  })
  .strict();

export type OperationRefWire = z.infer<typeof operationRefWireSchema>;
