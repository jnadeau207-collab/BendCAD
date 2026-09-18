import { describe, expect, it } from "vitest";

import {
  filletOperationSchema,
  operationRefWireSchema,
  operationSchema,
} from "../src/index.js";

const filletId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d90";
const bodyId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d91";
const targetId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d92";

/** A schemaVersion-1 fillet exactly as documents persisted before v2 existed. */
const filletV1 = {
  id: filletId,
  type: "fillet",
  schemaVersion: 1,
  name: "Round all edges",
  outputBodyId: bodyId,
  parameters: {
    targetOperationId: targetId,
    radius: 4,
  },
  metadata: {
    createdAt: "2026-07-17T09:00:00.000Z",
    createdBy: { kind: "user" },
  },
} as const;

function v2With(parameters: Record<string, unknown>) {
  return {
    id: filletId,
    type: "fillet",
    schemaVersion: 2,
    name: "Round selected edges",
    outputBodyId: bodyId,
    parameters: {
      targetOperationId: targetId,
      radius: 4,
      ...parameters,
    },
    metadata: {
      createdAt: "2026-07-17T09:00:00.000Z",
      createdBy: { kind: "user" },
    },
  };
}

describe("fillet schemaVersion migration", () => {
  it("loads a v1 fillet byte-identically (migration-neutral)", () => {
    const direct = filletOperationSchema.safeParse(filletV1);
    expect(direct.success).toBe(true);
    if (direct.success) {
      expect(direct.data).toEqual(filletV1);
    }
    // The nested schemaVersion union still composes into the outer type union.
    const viaUnion = operationSchema.safeParse(filletV1);
    expect(viaUnion.success).toBe(true);
    if (viaUnion.success) {
      expect(viaUnion.data).toEqual(filletV1);
    }
  });

  it("rejects an edges slot on v1 (strict, edges is v2-only)", () => {
    const withEdges = {
      ...filletV1,
      parameters: {
        ...filletV1.parameters,
        edges: { query: "edges(op(op_a))" },
      },
    };
    expect(filletOperationSchema.safeParse(withEdges).success).toBe(false);
  });

  it("accepts a v2 fillet without edges (all-edges behavior)", () => {
    const parsed = filletOperationSchema.safeParse(v2With({}));
    expect(parsed.success).toBe(true);
    if (parsed.success && parsed.data.schemaVersion === 2) {
      expect(parsed.data.parameters.edges).toBeUndefined();
    }
  });

  it("round-trips a v2 fillet carrying an edges ref", () => {
    const parsed = operationSchema.safeParse(
      v2With({ edges: { query: "edges(op(op_a)).convex()" } }),
    );
    expect(parsed.success).toBe(true);
    if (
      parsed.success &&
      parsed.data.type === "fillet" &&
      parsed.data.schemaVersion === 2
    ) {
      const edges = parsed.data.parameters.edges;
      expect(edges?.query).toBe("edges(op(op_a)).convex()");
      // Ref envelope defaults are applied.
      expect(edges?.arity).toBe("one");
      expect(edges?.onEmpty).toBe("error");
      expect(edges?.anchors).toEqual([]);
    }
  });

  it("rejects a v2 fillet with a malformed edges ref", () => {
    // Empty query.
    expect(
      filletOperationSchema.safeParse(v2With({ edges: { query: "" } })).success,
    ).toBe(false);
    // Over-long query (parser E_SEL_TOO_LONG ceiling is 2048).
    expect(
      filletOperationSchema.safeParse(
        v2With({ edges: { query: "e".repeat(2049) } }),
      ).success,
    ).toBe(false);
    // Inverted arity range.
    expect(
      filletOperationSchema.safeParse(
        v2With({
          edges: { query: "edges(op(op_a))", arity: { min: 3, max: 2 } },
        }),
      ).success,
    ).toBe(false);
    // Unknown envelope key (strict).
    expect(
      filletOperationSchema.safeParse(
        v2With({ edges: { query: "edges(op(op_a))", ast: {} } }),
      ).success,
    ).toBe(false);
  });
});

describe("operationRefWireSchema (kernel-wire ref)", () => {
  const ast = {
    kind: "edges",
    scope: [{ source: "op", opId: "op_a" }],
    filters: [],
  } as const;

  it("carries the parsed AST plus resolution policy with defaults", () => {
    const parsed = operationRefWireSchema.safeParse({ ast });
    expect(parsed.success).toBe(true);
    if (parsed.success) {
      expect(parsed.data.ast).toEqual(ast);
      expect(parsed.data.arity).toBe("one");
      expect(parsed.data.onEmpty).toBe("error");
      expect(parsed.data.anchors).toEqual([]);
    }
  });

  it("carries arity, anchors, and onEmpty through unchanged", () => {
    const parsed = operationRefWireSchema.safeParse({
      ast,
      arity: "one-or-more",
      onEmpty: "empty-ok",
      anchors: [{ token: "t:op_a/side/0", kind: "edge" }],
    });
    expect(parsed.success).toBe(true);
    if (parsed.success) {
      expect(parsed.data.arity).toBe("one-or-more");
      expect(parsed.data.onEmpty).toBe("empty-ok");
      expect(parsed.data.anchors).toHaveLength(1);
    }
  });

  it("rejects the persisted query-string form (ast is required, strict)", () => {
    // The raw AQL string must never cross the kernel boundary.
    expect(
      operationRefWireSchema.safeParse({ query: "edges(op(op_a))" }).success,
    ).toBe(false);
    // A malformed AST is rejected structurally.
    expect(
      operationRefWireSchema.safeParse({ ast: { kind: "edges" } }).success,
    ).toBe(false);
  });
});
