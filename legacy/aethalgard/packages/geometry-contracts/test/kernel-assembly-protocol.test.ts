import { describe, expect, it } from "vitest";

import {
  kernelProtocolVersion,
  kernelTransportRequestSchema,
  kernelTransportResponseSchema,
  resolveMateFramesKernelRequestSchema,
  resolveMateFramesKernelResponseSchema,
} from "../src/index.js";

const topRequestId = "018f0f5d-0000-7000-8000-000000000001";
const definitionId = "018f0f5d-0000-7000-8000-000000000002";
const endpointRequestId = "fixed:left";

const ast = {
  kind: "faces",
  scope: [{ source: "all" }],
  filters: [],
} as const;

function request(overrides: Record<string, unknown> = {}): unknown {
  return {
    protocolVersion: kernelProtocolVersion,
    requestId: topRequestId,
    method: "resolve_mate_frames",
    definitionId,
    revisionHash: "sha256:definition-v1",
    operations: [],
    endpoints: [
      {
        requestId: endpointRequestId,
        ast,
        expectedGeometry: "plane",
      },
    ],
    ...overrides,
  };
}

function resolvedResponse(): unknown {
  return {
    protocolVersion: kernelProtocolVersion,
    requestId: topRequestId,
    ok: true,
    result: {
      type: "mate_frame_resolution",
      definitionId,
      revisionHash: "sha256:definition-v1",
      outcomes: [
        {
          requestId: endpointRequestId,
          status: "resolved",
          frame: {
            origin: [0, 0, 0],
            primary: [0, 0, 1],
            secondary: [1, 0, 0],
            geometry: "plane",
            orientationClass: "directed",
            sourceEvidence: {
              kind: "face",
              geometryClass: "plane",
              measure: 100,
              centroid: [0, 0, 0],
              axis: [0, 0, 1],
              radius: null,
            },
          },
        },
      ],
    },
  };
}

describe("live resolve_mate_frames kernel transport", () => {
  it("admits the exact definition-scoped request through the combined transport", () => {
    expect(
      resolveMateFramesKernelRequestSchema.safeParse(request()).success,
    ).toBe(true);
    expect(kernelTransportRequestSchema.safeParse(request()).success).toBe(
      true,
    );
  });

  it("admits an exact resolved outcome through the combined response transport", () => {
    expect(
      resolveMateFramesKernelResponseSchema.safeParse(resolvedResponse())
        .success,
    ).toBe(true);
    expect(
      kernelTransportResponseSchema.safeParse(resolvedResponse()).success,
    ).toBe(true);
  });

  it("rejects duplicate endpoint correlation ids", () => {
    const endpoint = {
      requestId: endpointRequestId,
      ast,
      expectedGeometry: "plane",
    };
    expect(
      resolveMateFramesKernelRequestSchema.safeParse(
        request({ endpoints: [endpoint, endpoint] }),
      ).success,
    ).toBe(false);
  });

  it("rejects a persisted selector string at the native boundary", () => {
    expect(
      resolveMateFramesKernelRequestSchema.safeParse(
        request({
          endpoints: [
            {
              requestId: endpointRequestId,
              query: "faces()",
              expectedGeometry: "plane",
            },
          ],
        }),
      ).success,
    ).toBe(false);
  });

  it("preserves ordinary kernel methods in the combined transport", () => {
    expect(
      kernelTransportRequestSchema.safeParse({
        protocolVersion: kernelProtocolVersion,
        requestId: topRequestId,
        method: "health",
      }).success,
    ).toBe(true);
  });
});
