// Oracle driver: exercises the ORIGINAL legacy mesh-budget.ts via its own
// runtime (bun). Prints the pilot line protocol; Bend lanes must match stdout.
import {
  admitToEvaluationBudget,
  createEvaluationBudgetTotals,
  evaluationBudget,
  perPacketCountCaps,
  maxPacketBytes,
  MeshBudgetError,
  type EvaluationBudgetTotals,
  type MeshBudgetDescriptor,
} from "../../legacy/aethalgard/packages/geometry-contracts/src/mesh-budget.ts";

const d = (o: Partial<MeshBudgetDescriptor> = {}): MeshBudgetDescriptor => ({
  packetByteLength: 0,
  vertexCount: 0,
  triangleCount: 0,
  faceCount: 0,
  edgeCount: 0,
  edgeVertexCount: 0,
  brepVertexCount: 0,
  ...o,
});

const showTotals = (t: EvaluationBudgetTotals): string =>
  `packetBytes=${t.packetBytes} triangles=${t.triangles} vertices=${t.vertices} faces=${t.faces} edges=${t.edges} edgeVertices=${t.edgeVertices} brepVertices=${t.brepVertices} bodyCount=${t.bodyCount} gpuBytes=${t.gpuBytes}`;

let fails = 0;
const check = (cond: boolean): void => {
  if (!cond) fails += 1;
};

console.log(`const maxPacketBytes=${maxPacketBytes}`);
console.log(
  `const perPacket triangleCount=${perPacketCountCaps.triangleCount} vertexCount=${perPacketCountCaps.vertexCount} faceCount=${perPacketCountCaps.faceCount} edgeCount=${perPacketCountCaps.edgeCount} edgeVertexCount=${perPacketCountCaps.edgeVertexCount} brepVertexCount=${perPacketCountCaps.brepVertexCount}`,
);
console.log(
  `const eval totalPacketBytes=${evaluationBudget.totalPacketBytes} totalTriangles=${evaluationBudget.totalTriangles} totalVertices=${evaluationBudget.totalVertices} totalFaces=${evaluationBudget.totalFaces} totalEdges=${evaluationBudget.totalEdges} totalEdgeVertices=${evaluationBudget.totalEdgeVertices} totalBrepVertices=${evaluationBudget.totalBrepVertices} bodyCount=${evaluationBudget.bodyCount} gpuBytes=${evaluationBudget.gpuBytes}`,
);

// V1: single accept (mirrors mesh-budget.test.ts "accepts a body well under budget")
{
  const t = createEvaluationBudgetTotals();
  admitToEvaluationBudget(
    t,
    d({ packetByteLength: 4096, vertexCount: 100, triangleCount: 200, faceCount: 6, edgeCount: 12, edgeVertexCount: 24, brepVertexCount: 8 }),
  );
  console.log(`accept-single ${showTotals(t)}`);
  check(t.packetBytes === 4096 && t.triangles === 200 && t.vertices === 100 && t.faces === 6 && t.edges === 12 && t.edgeVertices === 24 && t.brepVertices === 8 && t.bodyCount === 1 && t.gpuBytes === 100 * 28 + 200 * 12);
}

// V2: double accumulation (mirrors "accumulates across multiple bodies")
{
  const t = createEvaluationBudgetTotals();
  const body = d({ packetByteLength: 1000, vertexCount: 10, triangleCount: 20 });
  admitToEvaluationBudget(t, body);
  admitToEvaluationBudget(t, body);
  console.log(`accept-double ${showTotals(t)}`);
  check(t.bodyCount === 2 && t.packetBytes === 2000 && t.vertices === 20 && t.triangles === 40 && t.gpuBytes === 2 * (10 * 28 + 20 * 12));
}

// V3..V11: the 9 ceiling rejections in TS ceilingCases order, atomicity checked
const cases: { over: Partial<MeshBudgetDescriptor>; field: string; seed?: (t: EvaluationBudgetTotals) => void }[] = [
  { over: { packetByteLength: evaluationBudget.totalPacketBytes + 1 }, field: "totalPacketBytes" },
  { over: { triangleCount: evaluationBudget.totalTriangles + 1 }, field: "totalTriangles" },
  { over: { vertexCount: evaluationBudget.totalVertices + 1 }, field: "totalVertices" },
  { over: { faceCount: evaluationBudget.totalFaces + 1 }, field: "totalFaces" },
  { over: { edgeCount: evaluationBudget.totalEdges + 1 }, field: "totalEdges" },
  { over: { edgeVertexCount: evaluationBudget.totalEdgeVertices + 1 }, field: "totalEdgeVertices" },
  { over: { brepVertexCount: evaluationBudget.totalBrepVertices + 1 }, field: "totalBrepVertices" },
  { over: {}, field: "bodyCount", seed: (t) => { t.bodyCount = evaluationBudget.bodyCount; } },
  { over: { vertexCount: 1 }, field: "gpuBytes", seed: (t) => { t.gpuBytes = evaluationBudget.gpuBytes; } },
];
let atomicOk = true;
for (const c of cases) {
  const t = createEvaluationBudgetTotals();
  c.seed?.(t);
  const before = { ...t };
  let thrown: unknown;
  try {
    admitToEvaluationBudget(t, d(c.over));
  } catch (e) {
    thrown = e;
  }
  const field = thrown instanceof MeshBudgetError ? thrown.field : "UNEXPECTED-ACCEPT";
  console.log(`reject ${field}`);
  check(thrown instanceof MeshBudgetError && field === c.field);
  if (JSON.stringify(t) !== JSON.stringify(before)) atomicOk = false;
}

// V12: exact-boundary accept (next == ceiling passes; only next > ceiling rejects)
{
  const t = createEvaluationBudgetTotals();
  admitToEvaluationBudget(t, d({ triangleCount: evaluationBudget.totalTriangles }));
  console.log(`accept-boundary triangles=${t.triangles} bodyCount=${t.bodyCount}`);
  check(t.triangles === evaluationBudget.totalTriangles && t.bodyCount === 1);
}

console.log(`atomicity ${atomicOk ? "ok" : "VIOLATED"}`);
check(atomicOk);
console.log(`selfcheck fails=${fails}`);
if (fails !== 0) process.exit(1);
