/**
 * Wire-schema coverage for the AQL `query` request/result pair (integration
 * tranche N4). The native selector evaluator consumes the parsed AST (never a
 * string) and returns resolved entities with per-stage cardinalities; these
 * tests pin the envelope the kernel client sends and receives — a valid AST
 * round-trips, a malformed one is rejected, and the `query` request shares the
 * document-size envelope with the other operation-carrying methods.
 */
import { describe, expect, it } from "vitest";

import {
  kernelProtocolVersion,
  kernelRequestSchema,
  kernelResultSchema,
  selectorQuerySchema,
} from "../src/index.js";

const requestId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d01";
const documentId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d02";
const opId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d11";
const bodyId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d21";

/** edges(op(<opId>)).convex().parallel(+z) — a representative fillet-edge ref. */
function ast(): unknown {
  return {
    kind: "edges",
    scope: [{ source: "op", opId }],
    filters: [
      { name: "convex", args: [] },
      {
        name: "parallel",
        args: [
          { arg: "direction", value: { form: "axis", sign: 1, axis: "z" } },
        ],
      },
    ],
  };
}

function box(index: number): unknown {
  const pad = (n: number) => n.toString(16).padStart(12, "0");
  return {
    id: `018f0f5d-0000-7000-8000-${pad(index)}`,
    type: "create_box",
    schemaVersion: 1,
    name: "Box",
    outputBodyId: `018f0f5d-0000-7000-8000-${pad(500_000 + index)}`,
    parameters: {
      width: 100,
      depth: 60,
      height: 30,
      placement: {
        origin: [0, 0, 0],
        zDirection: [0, 0, 1],
        xDirection: [1, 0, 0],
      },
    },
    metadata: {
      createdAt: "2026-07-13T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  };
}

describe("selectorQuerySchema", () => {
  it("accepts a nested query AST", () => {
    // adjacentTo carries a full nested query — exercises the lazy recursion.
    const nested = {
      kind: "faces",
      scope: [{ source: "body", opId }],
      filters: [
        {
          name: "adjacentTo",
          args: [
            {
              arg: "query",
              value: {
                kind: "faces",
                scope: [{ source: "op", opId }],
                filters: [
                  { name: "role", args: [{ arg: "ident", value: "top" }] },
                ],
              },
            },
          ],
        },
      ],
    };
    expect(selectorQuerySchema.safeParse(nested).success).toBe(true);
  });

  it("rejects an unknown head kind", () => {
    const result = selectorQuerySchema.safeParse({
      kind: "solids",
      scope: [{ source: "all" }],
      filters: [],
    });
    expect(result.success).toBe(false);
  });

  it("rejects an empty scope", () => {
    const result = selectorQuerySchema.safeParse({
      kind: "faces",
      scope: [],
      filters: [],
    });
    expect(result.success).toBe(false);
  });
});

describe("query request", () => {
  it("accepts a well-formed query request", () => {
    const result = kernelRequestSchema.safeParse({
      protocolVersion: kernelProtocolVersion,
      requestId,
      documentId,
      revision: 3,
      method: "query",
      atOperationId: opId,
      operations: [box(0)],
      ast: ast(),
    });
    expect(result.success).toBe(true);
  });

  it("rejects a query request whose ast is malformed", () => {
    const result = kernelRequestSchema.safeParse({
      protocolVersion: kernelProtocolVersion,
      requestId,
      documentId,
      revision: 3,
      method: "query",
      atOperationId: opId,
      operations: [box(0)],
      ast: { kind: "edges" }, // missing scope
    });
    expect(result.success).toBe(false);
  });

  it("requires atOperationId to be a uuid", () => {
    const result = kernelRequestSchema.safeParse({
      protocolVersion: kernelProtocolVersion,
      requestId,
      documentId,
      revision: 3,
      method: "query",
      atOperationId: "not-a-uuid",
      operations: [box(0)],
      ast: ast(),
    });
    expect(result.success).toBe(false);
  });
});

describe("query result", () => {
  it("accepts a resolved entity set with diagnostics and stage cardinalities", () => {
    const result = kernelResultSchema.safeParse({
      type: "query",
      entities: [
        {
          token: `t:${opId}/side-edge/0`,
          kind: "edge",
          bodyId,
          centroid: [10, 0, 15],
          length: 30,
          curve: "line",
          axis: { origin: [10, 0, 0], dir: [0, 0, 1] },
        },
        {
          token: `t:${opId}/wall/0`,
          kind: "face",
          bodyId,
          centroid: [0, 0, 15],
          area: 120,
          surface: "cylinder",
          radius: 4,
          axis: { origin: [0, 0, 0], dir: [0, 0, 1] },
        },
      ],
      diagnostics: [
        {
          code: "D_MIXED_CONVEXITY",
          message: "edge has mixed convexity along its length",
          token: `t:${opId}/side-edge/0`,
        },
      ],
      stageCardinalities: [12, 4, 2],
    });
    expect(result.success).toBe(true);
  });

  it("rejects a resolved entity with a malformed token", () => {
    const result = kernelResultSchema.safeParse({
      type: "query",
      entities: [
        { token: "side-edge-0", kind: "edge", bodyId, centroid: [0, 0, 0] },
      ],
      diagnostics: [],
      stageCardinalities: [1],
    });
    expect(result.success).toBe(false);
  });

  it("rejects a diagnostic with an unknown code", () => {
    const result = kernelResultSchema.safeParse({
      type: "query",
      entities: [],
      diagnostics: [{ code: "D_MADE_UP", message: "nope" }],
      stageCardinalities: [0],
    });
    expect(result.success).toBe(false);
  });
});
