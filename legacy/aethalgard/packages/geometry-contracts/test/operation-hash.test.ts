import { readFileSync } from "node:fs";

import { describe, expect, it } from "vitest";

import {
  bytesToHex,
  canonicalJson,
  canonicalOperationBytes,
  cumulativeOperationHash,
  cumulativeOperationHashes,
  jcsNumber,
  sha256,
} from "../src/index.js";

interface Golden {
  operationHashVersion: string;
  numberVectors: { value: number; expected: string }[];
  operationVectors: {
    description: string;
    operation: Record<string, unknown>;
    // Present for ref-bearing cases: the same op with every ref slot lowered
    // from persisted `{query}` to wire `{ast}` (N6 A′). The hasher rejects a raw
    // `{query}` slot (fail-closed), so ref cases MUST be hashed via the wire form.
    operationWire?: Record<string, unknown>;
    canonicalJson: string;
    canonicalSha256: string;
  }[];
  cumulativeVectors: {
    description: string;
    documentId: string;
    kernelGeomVersion: string;
    operations: Record<string, unknown>[];
    // Present when the chain contains a ref-bearing op: the wire-lowered chain.
    operationsWire?: Record<string, unknown>[];
    prefixHashes: string[];
  }[];
}

// The one committed cross-language pin (repo root, beside fixtures/geometry/).
// The native aeth-canonical-hash-test reproduces every value here; mutual
// agreement with this file is what proves TS and C++ cannot drift.
const golden = JSON.parse(
  readFileSync(
    new URL("../../../fixtures/golden/operation-hash-v1.json", import.meta.url),
    "utf8",
  ),
) as Golden;

const decode = (bytes: Uint8Array): string => new TextDecoder().decode(bytes);

describe("operation hash — golden cross-language pin", () => {
  it("formats every number vector as ECMAScript Number.toString", () => {
    for (const vector of golden.numberVectors) {
      expect(jcsNumber(vector.value)).toBe(vector.expected);
    }
  });

  it("canonicalizes every operation vector to the pinned JCS bytes", () => {
    for (const vector of golden.operationVectors) {
      // Ref cases are hashed via the wire form (`{ast}`); the persisted `{query}`
      // form fails closed here (no parser at this layer).
      const bytes = canonicalOperationBytes(
        vector.operationWire ?? vector.operation,
      );
      expect(decode(bytes)).toBe(vector.canonicalJson);
      expect(bytesToHex(sha256(bytes))).toBe(vector.canonicalSha256);
    }
  });

  it("reproduces every cumulative prefix-hash chain", () => {
    for (const vector of golden.cumulativeVectors) {
      expect(
        cumulativeOperationHashes(
          vector.documentId,
          vector.kernelGeomVersion,
          vector.operationsWire ?? vector.operations,
        ),
      ).toEqual(vector.prefixHashes);
    }
  });
});

describe("operation hash — canonicalization semantics", () => {
  const baseOp = {
    id: "aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa",
    type: "create_box",
    schemaVersion: 1,
    name: "Base Block",
    outputBodyId: "00000000-0000-4000-8000-00000000000b",
    parameters: {
      width: 80,
      depth: 50,
      height: 15,
      placement: {
        origin: [0, 0, 0],
        zDirection: [0, 0, 1],
        xDirection: [1, 0, 0],
      },
    },
    metadata: {
      createdAt: "2026-07-17T12:00:00Z",
      createdBy: { kind: "user" },
    },
  };

  it("excludes name and metadata (renames and re-authoring are hash-neutral)", () => {
    const renamed = { ...baseOp, name: "Totally Different Name" };
    const reauthored = {
      ...baseOp,
      metadata: {
        createdAt: "2027-01-01T00:00:00Z",
        createdBy: { kind: "user" },
      },
    };
    const canonical = decode(canonicalOperationBytes(baseOp));
    expect(canonical).not.toContain("Base Block");
    expect(canonical).not.toContain("createdAt");
    expect(decode(canonicalOperationBytes(renamed))).toBe(canonical);
    expect(decode(canonicalOperationBytes(reauthored))).toBe(canonical);
  });

  it("projects a wire ref slot over its canonical selector, excluding anchors and ast", () => {
    // N6 A′: the hasher consumes the WIRE ref form ({ast}) and rewrites the slot
    // to {query: printSelector(ast), arity, onEmpty}. anchors and the raw ast are
    // both dropped; arity/onEmpty carry through.
    const wire = {
      id: "eeeeeeee-5555-4e55-8e55-eeeeeeeeeeee",
      type: "fillet",
      schemaVersion: 2,
      name: "round",
      outputBodyId: "00000000-0000-4000-8000-00000000000e",
      parameters: {
        targetOperationId: "aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa",
        radius: 1.5,
        edges: {
          ast: {
            kind: "edges",
            scope: [{ source: "op", opId: "x" }],
            filters: [{ name: "convex", args: [] }],
          },
          arity: "any",
          anchors: [{ token: "t:1" }],
          onEmpty: "error",
        },
      },
      metadata: {
        createdAt: "2026-07-17T12:00:00Z",
        createdBy: { kind: "user" },
      },
    };
    const canonical = decode(canonicalOperationBytes(wire));
    expect(canonical).not.toContain("anchors");
    expect(canonical).not.toContain("t:1");
    expect(canonical).not.toContain("ast");
    expect(canonical).toContain('"query":"edges(op(x)).convex()"');
    expect(canonical).toContain('"arity":"any"');
  });

  it("fails closed on a ref slot that reaches the hash without a wire ast", () => {
    // The persisted {query} form has no ast; this layer owns no parser, so it
    // must throw rather than hash a raw query that would mismatch the kernel.
    const persisted = {
      id: "eeeeeeee-5555-4e55-8e55-eeeeeeeeeeee",
      type: "fillet",
      schemaVersion: 2,
      outputBodyId: "00000000-0000-4000-8000-00000000000e",
      parameters: {
        targetOperationId: "aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa",
        radius: 1.5,
        edges: {
          query: "edges(op(x)).convex()",
          arity: "any",
          anchors: [{ token: "t:1" }],
          onEmpty: "error",
        },
      },
    };
    expect(() => canonicalOperationBytes(persisted)).toThrow(/wire ast/);
  });

  it("is independent of source key insertion order", () => {
    const shuffled = {
      metadata: baseOp.metadata,
      parameters: {
        placement: {
          xDirection: [1, 0, 0],
          origin: [0, 0, 0],
          zDirection: [0, 0, 1],
        },
        height: 15,
        width: 80,
        depth: 50,
      },
      type: "create_box",
      outputBodyId: baseOp.outputBodyId,
      name: baseOp.name,
      schemaVersion: 1,
      id: baseOp.id,
    };
    expect(decode(canonicalOperationBytes(shuffled))).toBe(
      decode(canonicalOperationBytes(baseOp)),
    );
  });

  it('maps negative zero to "0" and rejects non-finite numbers', () => {
    expect(jcsNumber(-0)).toBe("0");
    expect(jcsNumber(0)).toBe("0");
    expect(() => jcsNumber(Number.NaN)).toThrow();
    expect(() => jcsNumber(Number.POSITIVE_INFINITY)).toThrow();
    expect(() => canonicalJson(Number.NEGATIVE_INFINITY)).toThrow();
  });

  it("roots each document/kernel-version in its own cache line", () => {
    const ops = [baseOp];
    const a = cumulativeOperationHash("doc-1", "occt-8.0.0+aeth.3", ops);
    const differentDoc = cumulativeOperationHash(
      "doc-2",
      "occt-8.0.0+aeth.3",
      ops,
    );
    const differentKernel = cumulativeOperationHash(
      "doc-1",
      "occt-8.0.0+aeth.4",
      ops,
    );
    expect(a).not.toBe(differentDoc);
    expect(a).not.toBe(differentKernel);
    // A trailing parameter edit changes the terminal hash (content-addressed).
    const edited = [
      { ...baseOp, parameters: { ...baseOp.parameters, width: 81 } },
    ];
    expect(
      cumulativeOperationHash("doc-1", "occt-8.0.0+aeth.3", edited),
    ).not.toBe(a);
  });
});
