import {
  kernelProtocolVersion,
  type ExactInterferenceRequest,
  type KernelResponse,
} from "@aeth/geometry-contracts";
import { describe, expect, it, vi } from "vitest";

import {
  createExactInterferenceRequest,
  submitExactInterference,
} from "../src/index.js";

const operationId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d11";
const bodyA = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d21";
const bodyB = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d22";
const occurrenceA = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d31";
const occurrenceB = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d32";
const definitionA = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d41";
const definitionB = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d42";
const requestId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d51";

function endpoint(
  bodyId: string,
  occurrencePath: string[],
  definitionId: string,
) {
  return {
    bodyId,
    occurrencePath,
    definitionId,
    definitionRevisionHash: `sha-${definitionId}`,
  };
}

function request(): ExactInterferenceRequest {
  return createExactInterferenceRequest({
    requestId,
    operations: [
      {
        id: operationId,
        type: "create_box",
        schemaVersion: 1,
        name: "Interference target",
        outputBodyId: bodyA,
        parameters: {
          width: 10,
          depth: 10,
          height: 10,
          placement: {},
        },
        metadata: {
          createdAt: "2026-08-01T00:00:00.000Z",
          createdBy: { kind: "user" },
        },
      },
    ],
    pairs: [
      {
        a: endpoint(bodyA, [occurrenceA], definitionA),
        b: endpoint(bodyB, [occurrenceB], definitionB),
      },
    ],
    toleranceMm: 0.001,
    inputRevisionDigest: "revision-1",
  });
}

describe("exact interference kernel-client seam", () => {
  it("builds the canonical protocol envelope", () => {
    const built = request();

    expect(built.protocolVersion).toBe(kernelProtocolVersion);
    expect(built.method).toBe("interference_exact");
    expect(built.pairs).toHaveLength(1);
  });

  it("rejects self-pairs and reversed endpoint order before submission", () => {
    expect(() =>
      createExactInterferenceRequest({
        ...request(),
        pairs: [
          {
            a: endpoint(bodyA, [occurrenceA], definitionA),
            b: endpoint(bodyA, [occurrenceA], definitionA),
          },
        ],
      }),
    ).toThrow(/cannot compare an endpoint with itself/);

    const original = request();
    expect(() =>
      createExactInterferenceRequest({
        ...original,
        pairs: [
          {
            a: original.pairs[0].b,
            b: original.pairs[0].a,
          },
        ],
      }),
    ).toThrow(/canonical order/);
  });

  it("routes through the bounded queue and validates the exact result", async () => {
    const response: KernelResponse = {
      protocolVersion: kernelProtocolVersion,
      requestId,
      ok: true,
      result: {
        type: "interference_exact_result",
        report: { status: "clear", pairCount: 1 },
        evidence: { kernel: "occt", toleranceMm: 0.001 },
      },
    };
    const submit = vi.fn(async () => response);
    const result = await submitExactInterference({ submit }, request(), {
      deadlineMs: 12_000,
    });

    expect(submit).toHaveBeenCalledWith(request(), { deadlineMs: 12_000 });
    expect(result.result.type).toBe("interference_exact_result");
    expect(result.result.evidence).toMatchObject({ kernel: "occt" });
  });
});
