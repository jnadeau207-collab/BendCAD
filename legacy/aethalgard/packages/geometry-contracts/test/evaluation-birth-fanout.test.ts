/**
 * The evaluation `bodies` array as ONE ENTRY PER BORN BODY (CAP-024 /
 * ADR-013 decision 3) — the packet's single sanctioned §4 seam change.
 *
 * The array used to mean "one entry per body-producing operation", and its
 * `superRefine` leaned on that: an `operationId` could not repeat. A multi-solid
 * import produces several bodies from one operation, so the contract has to
 * admit repeats — and the moment it does, two NEW ways to be wrong appear that
 * nothing else would catch:
 *
 * - duplicate output indices for one operation, which would mis-key the replay
 *   cache and repoint every reference scoped to that index;
 * - a GAPPED index set, which is a body the kernel dropped while still
 *   reporting success.
 *
 * Both fail on the wire rather than downstream, because downstream they are
 * indistinguishable from a document that legitimately has fewer bodies.
 */
import { describe, expect, it } from "vitest";

import { kernelResultSchema } from "../src/kernel-protocol.js";

const OP = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d11";
const OTHER_OP = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d12";
const BODY = (n: number): string =>
  `018f0f5d-7b3a-7cc1-9d22-7a0a96d30d${String(n).padStart(2, "0")}`;

function probes(): unknown {
  return {
    valid: true,
    volumeMm3: 1,
    surfaceAreaMm2: 6,
    centerOfMassMm: [0, 0, 0],
    boundingBoxMm: [0, 0, 0, 1, 1, 1],
    solidCount: 1,
    shellCount: 1,
    faceCount: 6,
    edgeCount: 12,
    vertexCount: 8,
  };
}

function mesh(streamSequence: number): unknown {
  return {
    format: "AEMB2",
    streamSequence,
    packetByteLength: 128,
    vertexCount: 8,
    triangleCount: 12,
    faceCount: 6,
    edgeCount: 12,
    edgeVertexCount: 24,
    brepVertexCount: 8,
    lodTier: 0,
    deflectionMm: 0.01,
    angularDeflectionRad: 0.5,
    checksumCrc32: "0a1b2c3d",
    epoch: 1,
    boundingBoxMm: [0, 0, 0, 1, 1, 1],
    worldOriginMm: [0, 0, 0],
    boundingBoxLocalMm: [0, 0, 0, 1, 1, 1],
  };
}

function body(
  bodyId: string,
  operationId: string,
  streamSequence: number,
  outputIndex?: number,
): Record<string, unknown> {
  return {
    bodyId,
    operationId,
    probes: probes(),
    mesh: mesh(streamSequence),
    ...(outputIndex === undefined ? {} : { outputIndex }),
  };
}

function parse(bodies: readonly unknown[]): {
  success: boolean;
  message: string;
} {
  const result = kernelResultSchema.safeParse({
    type: "evaluation",
    revision: 1,
    epoch: 1,
    bodies,
  });
  return {
    success: result.success,
    message: result.success ? "" : JSON.stringify(result.error.issues),
  };
}

describe("single-output evaluation is unchanged", () => {
  it("accepts one entry per operation with no index at all", () => {
    // The byte-identity clause: an existing kernel that has never heard of
    // outputIndex keeps producing a valid response.
    expect(
      parse([body(BODY(1), OP, 1), body(BODY(2), OTHER_OP, 2)]).success,
    ).toBe(true);
  });

  it("accepts an explicit index 0", () => {
    expect(parse([body(BODY(1), OP, 1, 0)]).success).toBe(true);
  });
});

describe("a birth operation may fan out", () => {
  it("accepts several bodies sharing one operationId with a complete index set", () => {
    expect(
      parse([
        body(BODY(1), OP, 1, 0),
        body(BODY(2), OP, 2, 1),
        body(BODY(3), OP, 3, 2),
      ]).success,
    ).toBe(true);
  });

  it("accepts the fan-out alongside ordinary single-output operations", () => {
    expect(
      parse([
        body(BODY(1), OP, 1, 0),
        body(BODY(2), OP, 2, 1),
        body(BODY(3), OTHER_OP, 3),
      ]).success,
    ).toBe(true);
  });

  it("does not require the entries to arrive in index order", () => {
    expect(
      parse([body(BODY(1), OP, 1, 1), body(BODY(2), OP, 2, 0)]).success,
    ).toBe(true);
  });
});

describe("the two new ways to be wrong fail on the wire", () => {
  it("refuses duplicate output indices for one operation", () => {
    // Two bodies claiming to be body 1 of the same import: every reference
    // scoped to index 1 becomes ambiguous, and the replay cache mis-keys.
    const parsed = parse([
      body(BODY(1), OP, 1, 0),
      body(BODY(2), OP, 2, 1),
      body(BODY(3), OP, 3, 1),
    ]);
    expect(parsed.success).toBe(false);
    expect(parsed.message).toContain("complete 0..N-1 set");
  });

  it("refuses a GAPPED index set", () => {
    // Index 1 missing is a body the kernel dropped while reporting success —
    // downstream that is indistinguishable from a two-solid import.
    const parsed = parse([body(BODY(1), OP, 1, 0), body(BODY(2), OP, 2, 2)]);
    expect(parsed.success).toBe(false);
    expect(parsed.message).toContain("complete 0..N-1 set");
  });

  it("refuses a set that does not start at 0", () => {
    const parsed = parse([body(BODY(1), OP, 1, 1), body(BODY(2), OP, 2, 2)]);
    expect(parsed.success).toBe(false);
  });

  it("refuses a repeated operationId where the indices were omitted", () => {
    // Both default to 0, so this is the duplicate-index case and must fail —
    // a host that fanned out without stamping indices is silently claiming two
    // bodies are the same one.
    const parsed = parse([body(BODY(1), OP, 1), body(BODY(2), OP, 2)]);
    expect(parsed.success).toBe(false);
  });

  it("still refuses a duplicate bodyId", () => {
    // The invariant fan-out does NOT relax: two entries sharing a body id
    // collapse in the viewport regardless of which operation bore them.
    const parsed = parse([body(BODY(1), OP, 1, 0), body(BODY(1), OP, 2, 1)]);
    expect(parsed.success).toBe(false);
    expect(parsed.message).toContain("Duplicate body id");
  });

  it("refuses a negative index", () => {
    expect(parse([body(BODY(1), OP, 1, -1)]).success).toBe(false);
  });
});
