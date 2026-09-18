/**
 * Product-derived mesh resource budgets — the single source of the ceilings a
 * mesh delivery must clear. Two tiers:
 *
 *   • Per-packet caps bound ONE body's packet. `maxPacketBytes` is the wire
 *     byte cap the binary framer enforces before it allocates a packet buffer
 *     (connection-fatal on overrun — see `binary-frame.ts`); `perPacketCountCaps`
 *     bound the header counts `parseAembPacket` reads, rejected there as a
 *     `MeshPayloadError` before any section work.
 *
 *   • The evaluation budget bounds a WHOLE evaluation — the sum across every
 *     retained body plus a body-count ceiling and a GPU-footprint estimate.
 *     Crossing it is a resource-policy rejection ({@link MeshBudgetError}), NOT
 *     protocol corruption: the connection stays healthy and the caller surfaces
 *     the evaluation as failed rather than poisoning the kernel.
 *
 * The numbers are deliberate product ceilings, not arithmetic identities; keep
 * them here so every enforcement point reads the same constant.
 */

/** Per-packet wire byte cap: 48 MiB. Enforced by the binary framer. */
export const maxPacketBytes = 50_331_648;

/**
 * Per-packet header-count ceilings. Enforced inside `parseAembPacket` (as a
 * {@link import("./mesh-payload.js").MeshPayloadError}) before it trusts any
 * count to size a section.
 */
export const perPacketCountCaps = Object.freeze({
  triangleCount: 500_000,
  vertexCount: 300_000,
  faceCount: 50_000,
  edgeCount: 100_000,
  edgeVertexCount: 2_000_000,
  brepVertexCount: 300_000,
});

/**
 * Evaluation-wide ceilings. `totalPacketBytes` is 256 MiB; `gpuBytes` is
 * 480 MiB of estimated device memory (Σ vertexCount·28 + triangleCount·12 —
 * 28 bytes/vertex for interleaved position+normal+id attributes, 12 bytes per
 * triangle of index).
 */
export const evaluationBudget = Object.freeze({
  totalPacketBytes: 268_435_456,
  totalTriangles: 1_000_000,
  totalVertices: 600_000,
  totalFaces: 200_000,
  totalEdges: 400_000,
  totalEdgeVertices: 8_000_000,
  totalBrepVertices: 600_000,
  bodyCount: 1_000,
  gpuBytes: 503_316_480,
});

/** Estimated device-memory bytes a single body occupies once uploaded. */
const gpuBytesFor = (vertexCount: number, triangleCount: number): number =>
  vertexCount * 28 + triangleCount * 12;

/**
 * A resource-policy rejection: an evaluation's meshes would exceed a product
 * ceiling. Distinct from `MeshPayloadError`/`MeshReconciliationError` — those
 * mean the binary and control channels disagree and the connection must be
 * poisoned. A budget overrun means the connection is fine; the evaluation is
 * simply too large to retain.
 */
export class MeshBudgetError extends Error {
  public constructor(
    message: string,
    public readonly field: string,
  ) {
    super(message);
    this.name = "MeshBudgetError";
  }
}

/** The count/byte fields {@link admitToEvaluationBudget} reads off a descriptor. */
export interface MeshBudgetDescriptor {
  readonly packetByteLength: number;
  readonly vertexCount: number;
  readonly triangleCount: number;
  readonly faceCount: number;
  readonly edgeCount: number;
  readonly edgeVertexCount: number;
  readonly brepVertexCount: number;
}

/** The running accumulator {@link admitToEvaluationBudget} advances per body. */
export interface EvaluationBudgetTotals {
  packetBytes: number;
  triangles: number;
  vertices: number;
  faces: number;
  edges: number;
  edgeVertices: number;
  brepVertices: number;
  bodyCount: number;
  gpuBytes: number;
}

/** A zeroed accumulator for one evaluation's admission run. */
export function createEvaluationBudgetTotals(): EvaluationBudgetTotals {
  return {
    packetBytes: 0,
    triangles: 0,
    vertices: 0,
    faces: 0,
    edges: 0,
    edgeVertices: 0,
    brepVertices: 0,
    bodyCount: 0,
    gpuBytes: 0,
  };
}

/**
 * Admits one more body's descriptor into a running evaluation budget. Computes
 * every prospective total first and throws {@link MeshBudgetError} the instant
 * any ceiling would be crossed; `totals` is mutated ONLY when the body clears
 * every ceiling, so a rejected admission leaves the accumulator untouched and
 * the caller can attribute the failure to the exact body that overran.
 */
export function admitToEvaluationBudget(
  totals: EvaluationBudgetTotals,
  descriptor: MeshBudgetDescriptor,
): void {
  const nextBodyCount = totals.bodyCount + 1;
  const nextPacketBytes = totals.packetBytes + descriptor.packetByteLength;
  const nextTriangles = totals.triangles + descriptor.triangleCount;
  const nextVertices = totals.vertices + descriptor.vertexCount;
  const nextFaces = totals.faces + descriptor.faceCount;
  const nextEdges = totals.edges + descriptor.edgeCount;
  const nextEdgeVertices = totals.edgeVertices + descriptor.edgeVertexCount;
  const nextBrepVertices = totals.brepVertices + descriptor.brepVertexCount;
  const nextGpuBytes =
    totals.gpuBytes +
    gpuBytesFor(descriptor.vertexCount, descriptor.triangleCount);

  const ceilings: readonly (readonly [string, number, number])[] = [
    ["bodyCount", nextBodyCount, evaluationBudget.bodyCount],
    ["totalPacketBytes", nextPacketBytes, evaluationBudget.totalPacketBytes],
    ["totalTriangles", nextTriangles, evaluationBudget.totalTriangles],
    ["totalVertices", nextVertices, evaluationBudget.totalVertices],
    ["totalFaces", nextFaces, evaluationBudget.totalFaces],
    ["totalEdges", nextEdges, evaluationBudget.totalEdges],
    ["totalEdgeVertices", nextEdgeVertices, evaluationBudget.totalEdgeVertices],
    ["totalBrepVertices", nextBrepVertices, evaluationBudget.totalBrepVertices],
    ["gpuBytes", nextGpuBytes, evaluationBudget.gpuBytes],
  ];
  for (const [field, next, ceiling] of ceilings) {
    if (next > ceiling) {
      throw new MeshBudgetError(
        `Evaluation ${field} ${next} exceeds the ${ceiling} budget`,
        field,
      );
    }
  }

  totals.bodyCount = nextBodyCount;
  totals.packetBytes = nextPacketBytes;
  totals.triangles = nextTriangles;
  totals.vertices = nextVertices;
  totals.faces = nextFaces;
  totals.edges = nextEdges;
  totals.edgeVertices = nextEdgeVertices;
  totals.brepVertices = nextBrepVertices;
  totals.gpuBytes = nextGpuBytes;
}
