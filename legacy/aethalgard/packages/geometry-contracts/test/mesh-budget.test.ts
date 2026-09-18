import { describe, expect, it } from "vitest";

import {
  admitToEvaluationBudget,
  createEvaluationBudgetTotals,
  evaluationBudget,
  MeshBudgetError,
  type EvaluationBudgetTotals,
  type MeshBudgetDescriptor,
} from "../src/index.js";

function descriptor(
  overrides: Partial<MeshBudgetDescriptor> = {},
): MeshBudgetDescriptor {
  return {
    packetByteLength: 0,
    vertexCount: 0,
    triangleCount: 0,
    faceCount: 0,
    edgeCount: 0,
    edgeVertexCount: 0,
    brepVertexCount: 0,
    ...overrides,
  };
}

describe("admitToEvaluationBudget (finding-8)", () => {
  it("accepts a body well under budget and advances the accumulator", () => {
    const totals = createEvaluationBudgetTotals();
    admitToEvaluationBudget(
      totals,
      descriptor({
        packetByteLength: 4096,
        vertexCount: 100,
        triangleCount: 200,
        faceCount: 6,
        edgeCount: 12,
        edgeVertexCount: 24,
        brepVertexCount: 8,
      }),
    );
    expect(totals).toEqual({
      packetBytes: 4096,
      vertices: 100,
      triangles: 200,
      faces: 6,
      edges: 12,
      edgeVertices: 24,
      brepVertices: 8,
      bodyCount: 1,
      gpuBytes: 100 * 28 + 200 * 12,
    });
  });

  it("accumulates across multiple bodies", () => {
    const totals = createEvaluationBudgetTotals();
    const body = descriptor({
      packetByteLength: 1000,
      vertexCount: 10,
      triangleCount: 20,
    });
    admitToEvaluationBudget(totals, body);
    admitToEvaluationBudget(totals, body);
    expect(totals.bodyCount).toBe(2);
    expect(totals.packetBytes).toBe(2000);
    expect(totals.vertices).toBe(20);
    expect(totals.triangles).toBe(40);
    expect(totals.gpuBytes).toBe(2 * (10 * 28 + 20 * 12));
  });

  const ceilingCases: readonly {
    name: string;
    field: string;
    seed?: (totals: EvaluationBudgetTotals) => void;
    over: Partial<MeshBudgetDescriptor>;
  }[] = [
    {
      name: "packet bytes",
      field: "totalPacketBytes",
      over: { packetByteLength: evaluationBudget.totalPacketBytes + 1 },
    },
    {
      name: "triangles",
      field: "totalTriangles",
      over: { triangleCount: evaluationBudget.totalTriangles + 1 },
    },
    {
      name: "vertices",
      field: "totalVertices",
      over: { vertexCount: evaluationBudget.totalVertices + 1 },
    },
    {
      name: "faces",
      field: "totalFaces",
      over: { faceCount: evaluationBudget.totalFaces + 1 },
    },
    {
      name: "edges",
      field: "totalEdges",
      over: { edgeCount: evaluationBudget.totalEdges + 1 },
    },
    {
      name: "edge vertices",
      field: "totalEdgeVertices",
      over: { edgeVertexCount: evaluationBudget.totalEdgeVertices + 1 },
    },
    {
      name: "brep vertices",
      field: "totalBrepVertices",
      over: { brepVertexCount: evaluationBudget.totalBrepVertices + 1 },
    },
    {
      name: "body count",
      field: "bodyCount",
      seed: (totals) => {
        totals.bodyCount = evaluationBudget.bodyCount;
      },
      over: {},
    },
    {
      // The GPU-footprint estimate is far looser than the vertex/triangle
      // count ceilings, so it can only bind once the accumulator is already
      // loaded near it — a defence-in-depth ceiling exercised directly.
      name: "gpu bytes",
      field: "gpuBytes",
      seed: (totals) => {
        totals.gpuBytes = evaluationBudget.gpuBytes;
      },
      over: { vertexCount: 1 },
    },
  ];

  it.each(ceilingCases)(
    "rejects the $name ceiling with MeshBudgetError and leaves totals untouched",
    ({ field, seed, over }) => {
      const totals = createEvaluationBudgetTotals();
      seed?.(totals);
      const before = { ...totals };
      let thrown: unknown;
      try {
        admitToEvaluationBudget(totals, descriptor(over));
      } catch (error) {
        thrown = error;
      }
      expect(thrown).toBeInstanceOf(MeshBudgetError);
      expect((thrown as MeshBudgetError).field).toBe(field);
      expect(totals).toEqual(before);
    },
  );
});
