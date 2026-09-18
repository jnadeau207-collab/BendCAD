/**
 * Content hash of a CAD operation — the shared contract that lets the C++ kernel
 * and this TypeScript layer agree byte-for-byte on what an operation "is", so the
 * replay cache (docs/design/2026-07-17-replay-cache.md) can be content-addressed
 * without the two sides ever disagreeing on a cache hit. Spec + rationale:
 * docs/design/2026-07-17-op-hash-contract.md. Mirrored by
 * native/kernel-host/src/operation_hash.hpp and pinned bit-for-bit by
 * fixtures/golden/operation-hash-v1.json.
 */

import type { SelectorQuery } from "./selector-ast.js";
import { printSelector } from "./selector-print.js";
import { sha256, bytesToHex, concatBytes } from "./sha256.js";

/** Version tag mixed into the cache-line root — a format bump invalidates every line. */
export const operationHashVersion = "aeth-op-hash-v1";

const utf8 = new TextEncoder();

/**
 * Keys whose value never reaches the kernel's geometry/naming output, stripped
 * wherever they appear before hashing (docs/design/2026-07-17-op-hash-contract.md):
 * `name`/`metadata` are display/provenance (metadata carries a wall-clock
 * `createdAt` and per-session `runId`, so including them would defeat the cache
 * across saves); `anchors` are selector hints already declared "excluded from
 * document hashing" in refs.ts.
 *
 * `snapHints` joins them by plan-02's own instruction: it declares them dropped
 * before canonicalization "exactly as ref `anchors` are", so editing a snap
 * hint must recompute NOTHING. Listing it HERE rather than special-casing the
 * sketch operation is what makes that rule law — a rule no hasher applies is
 * documentation, which is precisely what this capability's review caught.
 */
const excludedKeys: ReadonlySet<string> = new Set([
  "name",
  "metadata",
  "anchors",
  "snapHints",
]);

/**
 * RFC 8785 §3.2.2.3 number serialization: ECMAScript `Number.prototype.toString`
 * — the shortest round-trip decimal. `String(x)` IS that algorithm in V8, and
 * `String(-0) === "0"` already matches RFC 8785. Non-finite values are rejected
 * (fail closed) rather than emitted as `null` the way `JSON.stringify` would.
 */
export function jcsNumber(value: number): string {
  if (!Number.isFinite(value)) {
    throw new Error(
      `operation hash cannot serialize a non-finite number: ${String(value)}`,
    );
  }
  return String(value);
}

// UTF-16 code-unit order (RFC 8785 §3.2.3). JS `<`/`>` on strings compares by
// code unit, which is exactly the required order.
function compareCodeUnits(left: string, right: string): number {
  return left < right ? -1 : left > right ? 1 : 0;
}

/**
 * RFC 8785 (JSON Canonicalization Scheme) serialization of a JSON value: sorted
 * object keys, no whitespace, ECMAScript string escaping (via `JSON.stringify`
 * of the string, which is RFC 8785-compatible §3.2.2.2), and {@link jcsNumber}
 * numbers. `undefined` object members are omitted (absent optionals never
 * appear). Throws on a value type JSON cannot represent.
 */
export function canonicalJson(value: unknown): string {
  if (value === null) {
    return "null";
  }
  switch (typeof value) {
    case "boolean":
      return value ? "true" : "false";
    case "number":
      return jcsNumber(value);
    case "string":
      return JSON.stringify(value);
    case "object": {
      if (Array.isArray(value)) {
        return `[${value.map((element) => canonicalJson(element)).join(",")}]`;
      }
      const record = value as Record<string, unknown>;
      const keys = Object.keys(record)
        .filter((key) => record[key] !== undefined)
        .sort(compareCodeUnits);
      const members = keys.map(
        (key) => `${JSON.stringify(key)}:${canonicalJson(record[key])}`,
      );
      return `{${members.join(",")}}`;
    }
    default:
      throw new Error(
        `operation hash cannot serialize a value of type ${typeof value}`,
      );
  }
}

/**
 * A ref slot is any object carrying the resolution policy (`arity` + `onEmpty`)
 * plus a selector — either the persisted `query` string or the wire `ast`
 * (refs.ts `operationRefSchema` / `operationRefWireSchema`). Detection is by
 * shape and is IDENTICAL to the C++ `IsRefSlot` twin, so both languages project
 * the same slots (docs/design/2026-07-23-phase4-native-geometry.md §5).
 */
function isRefSlot(record: Record<string, unknown>): boolean {
  return (
    "arity" in record &&
    "onEmpty" in record &&
    ("ast" in record || "query" in record)
  );
}

// Deep copy stripping every excluded key, so name/metadata (top-level) and
// anchors (nested in a ref slot) never reach the canonicalization. A ref slot is
// additionally PROJECTED over its printed canonical selector (N6 A′): the slot
// is rewritten to `{ query: printSelector(ast), arity, onEmpty }` so the
// persisted `query` (printed doc-side by `printSelector(parseSelector(query))`)
// and the wire `ast` (printed here) canonicalize to identical bytes across the
// query→ast transport. This layer owns no AQL parser, so a slot that reaches the
// hash carrying only `query` (a pre-N6 persisted shape) fails closed rather than
// hash a raw query string that would silently mismatch the kernel.
function stripExcluded(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map((element) => stripExcluded(element));
  }
  if (value !== null && typeof value === "object") {
    const record = value as Record<string, unknown>;
    if (isRefSlot(record)) {
      if (!("ast" in record) || record.ast === undefined) {
        throw new Error(
          "canonicalOperationBytes: ref slot reached the hash without a wire ast",
        );
      }
      return {
        query: printSelector(record.ast as SelectorQuery),
        arity: stripExcluded(record.arity),
        onEmpty: record.onEmpty,
      };
    }
    const out: Record<string, unknown> = {};
    for (const [key, member] of Object.entries(record)) {
      if (excludedKeys.has(key)) {
        continue;
      }
      out[key] = stripExcluded(member);
    }
    return out;
  }
  return value;
}

/**
 * The canonical bytes of an operation's hashable projection — its `type`,
 * `schemaVersion`, identity (`id`, `outputBodyId`/`outputProfileId`), and
 * `parameters` (anchors stripped), as RFC 8785 JCS UTF-8. Excludes `name` and
 * `metadata`. This is the per-operation contribution to the cumulative cache key.
 */
export function canonicalOperationBytes(operation: unknown): Uint8Array {
  if (
    operation === null ||
    typeof operation !== "object" ||
    Array.isArray(operation)
  ) {
    throw new Error("canonicalOperationBytes requires an operation object");
  }
  return utf8.encode(canonicalJson(stripExcluded(operation)));
}

/**
 * The cache line root H(-1): binds the whole line to one document and one kernel
 * geometry version. `kernelGeomVersion` (e.g. "occt-8.0.0+aeth.3") folds in here
 * so an OCCT/semantics bump invalidates every prefix in the line.
 */
function cacheLineRoot(
  documentId: string,
  kernelGeomVersion: string,
): Uint8Array {
  return sha256(
    utf8.encode(
      canonicalJson({ v: operationHashVersion, documentId, kernelGeomVersion }),
    ),
  );
}

/**
 * The cumulative prefix hash H(k) over operations[0..k]:
 *   H(-1) = SHA-256(JCS({ v, documentId, kernelGeomVersion }))
 *   H(i)  = SHA-256(H(i-1) [32 bytes] ‖ canonicalOperationBytes(op[i]))
 * Returned as lowercase hex — the L1 replay-cache key for "state after this
 * prefix". Content-addressed: any op change cascades into every later H, so
 * stale entries simply never match.
 */
export function cumulativeOperationHash(
  documentId: string,
  kernelGeomVersion: string,
  operations: readonly unknown[],
): string {
  let hash = cacheLineRoot(documentId, kernelGeomVersion);
  for (const operation of operations) {
    hash = sha256(concatBytes(hash, canonicalOperationBytes(operation)));
  }
  return bytesToHex(hash);
}

/**
 * Every cumulative prefix hash: `[H(-1), H(0), …, H(n-1)]` (length n+1). The
 * replay cache snapshots state at each op, so it needs the hash at every prefix
 * boundary, not just the final one.
 */
export function cumulativeOperationHashes(
  documentId: string,
  kernelGeomVersion: string,
  operations: readonly unknown[],
): string[] {
  let hash = cacheLineRoot(documentId, kernelGeomVersion);
  const hashes = [bytesToHex(hash)];
  for (const operation of operations) {
    hash = sha256(concatBytes(hash, canonicalOperationBytes(operation)));
    hashes.push(bytesToHex(hash));
  }
  return hashes;
}
