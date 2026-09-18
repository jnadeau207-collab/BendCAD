/**
 * Wire-schema coverage for the `mold_draft_analysis` request/result pair —
 * the mold/tooling domain's one read-only top-level kernel RPC method, a
 * sibling to `simulate`/`hlr_project` (NOT an `operations`-array entry, never
 * touches `operations.ts`'s discriminated union). These pin the envelope the
 * kernel client sends and receives: a fully-populated request/result pair
 * round-trips, `bodyId` is required (not `targetOperationId`), the response
 * `type` literal is exactly `"mold_draft_analysis"` (regression-pinning the
 * naming trap the desktop-UI side of this catalog wave hit once already), and
 * the result's `superRefine` catches a duplicate face token and a
 * counts/tally mismatch.
 */
import { describe, expect, it } from "vitest";

import {
  kernelProtocolVersion,
  kernelRequestSchema,
  kernelResultSchema,
} from "../src/index.js";

const requestId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d32d01";
const opId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d32d11";
const bodyId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d32d21";

function box(): unknown {
  return {
    id: opId,
    type: "create_box",
    schemaVersion: 1,
    name: "Bar",
    outputBodyId: bodyId,
    parameters: {
      width: 100,
      depth: 10,
      height: 10,
      placement: {
        origin: [0, 0, 0],
        zDirection: [0, 0, 1],
        xDirection: [1, 0, 0],
      },
    },
    metadata: {
      createdAt: "2026-08-05T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  };
}

function draftAnalysisRequest(
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    protocolVersion: kernelProtocolVersion,
    requestId,
    method: "mold_draft_analysis",
    operations: [box()],
    bodyId,
    pullDirection: { x: 0, y: 0, z: 1 },
    draftAngleToleranceDeg: 0.5,
    ...overrides,
  };
}

describe("mold_draft_analysis request member", () => {
  it("round-trips a full request", () => {
    const request = draftAnalysisRequest();
    const parsed = kernelRequestSchema.safeParse(request);
    expect(parsed.success).toBe(true);
    if (!parsed.success || parsed.data.method !== "mold_draft_analysis") {
      return;
    }
    expect(parsed.data).toEqual(request);
    expect(parsed.data.bodyId).toBe(bodyId);
  });

  it("defaults draftAngleToleranceDeg to 0.5 when omitted", () => {
    const request = draftAnalysisRequest();
    delete (request as Record<string, unknown>)["draftAngleToleranceDeg"];
    const parsed = kernelRequestSchema.safeParse(request);
    expect(parsed.success).toBe(true);
    if (!parsed.success || parsed.data.method !== "mold_draft_analysis") {
      return;
    }
    expect(parsed.data.draftAngleToleranceDeg).toBe(0.5);
  });

  it("requires bodyId — a targetOperationId field is rejected as unknown", () => {
    const request = draftAnalysisRequest();
    delete (request as Record<string, unknown>)["bodyId"];
    expect(kernelRequestSchema.safeParse(request).success).toBe(false);

    const wrongField = draftAnalysisRequest();
    delete (wrongField as Record<string, unknown>)["bodyId"];
    (wrongField as Record<string, unknown>)["targetOperationId"] = opId;
    expect(kernelRequestSchema.safeParse(wrongField).success).toBe(false);
  });

  it("rejects a non-uuid bodyId", () => {
    expect(
      kernelRequestSchema.safeParse(
        draftAnalysisRequest({ bodyId: "not-a-uuid" }),
      ).success,
    ).toBe(false);
  });

  it("rejects empty operations — a classification needs geometry", () => {
    expect(
      kernelRequestSchema.safeParse(draftAnalysisRequest({ operations: [] }))
        .success,
    ).toBe(false);
  });

  it("rejects a tuple-shaped pullDirection (the object shape is required)", () => {
    expect(
      kernelRequestSchema.safeParse(
        draftAnalysisRequest({ pullDirection: [0, 0, 1] }),
      ).success,
    ).toBe(false);
  });

  it("rejects a zero-vector pullDirection", () => {
    expect(
      kernelRequestSchema.safeParse(
        draftAnalysisRequest({ pullDirection: { x: 0, y: 0, z: 0 } }),
      ).success,
    ).toBe(false);
  });

  it("rejects draftAngleToleranceDeg outside [0, 30]", () => {
    expect(
      kernelRequestSchema.safeParse(
        draftAnalysisRequest({ draftAngleToleranceDeg: -1 }),
      ).success,
    ).toBe(false);
    expect(
      kernelRequestSchema.safeParse(
        draftAnalysisRequest({ draftAngleToleranceDeg: 30.5 }),
      ).success,
    ).toBe(false);
  });

  it("rejects unknown fields", () => {
    expect(
      kernelRequestSchema.safeParse(
        draftAnalysisRequest({
          documentId: "018f0f5d-0000-7000-8000-0000000000ff",
        }),
      ).success,
    ).toBe(false);
  });
});

describe("mold_draft_analysis result member", () => {
  function result(
    overrides: Record<string, unknown> = {},
  ): Record<string, unknown> {
    return {
      type: "mold_draft_analysis",
      bodyId,
      faces: [
        { token: "face-0", classification: "positive" },
        { token: "face-1", classification: "negative" },
        { token: "face-2", classification: "no-draft" },
        { token: "face-3", classification: "straddle" },
      ],
      counts: { positive: 1, negative: 1, noDraft: 1, straddle: 1 },
      ...overrides,
    };
  }

  it("round-trips a full result", () => {
    const value = result();
    const parsed = kernelResultSchema.safeParse(value);
    expect(parsed.success).toBe(true);
    if (!parsed.success) return;
    expect(parsed.data).toEqual(value);
  });

  it("the type literal is exactly mold_draft_analysis, not mold_draft_analysis_result", () => {
    // Regression pin for the naming trap the desktop-UI side of this
    // catalog wave hit once already (it first reached for
    // "mold_draft_analysis_result" by analogy with simulate's own
    // "simulation_result").
    expect(
      kernelResultSchema.safeParse({
        ...result(),
        type: "mold_draft_analysis_result",
      }).success,
    ).toBe(false);
    const parsed = kernelResultSchema.safeParse(result());
    expect(parsed.success).toBe(true);
    if (parsed.success) expect(parsed.data.type).toBe("mold_draft_analysis");
  });

  it("accepts every classification value and an empty face list with all-zero counts", () => {
    expect(
      kernelResultSchema.safeParse(
        result({
          faces: [],
          counts: { positive: 0, negative: 0, noDraft: 0, straddle: 0 },
        }),
      ).success,
    ).toBe(true);
  });

  it("refuses a duplicate face token", () => {
    expect(
      kernelResultSchema.safeParse(
        result({
          faces: [
            { token: "face-0", classification: "positive" },
            { token: "face-0", classification: "negative" },
          ],
          counts: { positive: 1, negative: 1, noDraft: 0, straddle: 0 },
        }),
      ).success,
    ).toBe(false);
  });

  it("refuses counts that do not match the tally of faces", () => {
    expect(
      kernelResultSchema.safeParse(
        result({
          counts: { positive: 2, negative: 1, noDraft: 1, straddle: 1 },
        }),
      ).success,
    ).toBe(false);
    expect(
      kernelResultSchema.safeParse(
        result({
          counts: { positive: 1, negative: 0, noDraft: 1, straddle: 1 },
        }),
      ).success,
    ).toBe(false);
    expect(
      kernelResultSchema.safeParse(
        result({
          counts: { positive: 1, negative: 1, noDraft: 2, straddle: 1 },
        }),
      ).success,
    ).toBe(false);
    expect(
      kernelResultSchema.safeParse(
        result({
          counts: { positive: 1, negative: 1, noDraft: 1, straddle: 0 },
        }),
      ).success,
    ).toBe(false);
  });

  it("refuses an unknown classification value", () => {
    expect(
      kernelResultSchema.safeParse(
        result({
          faces: [{ token: "face-0", classification: "unknown" }],
          counts: { positive: 0, negative: 0, noDraft: 0, straddle: 0 },
        }),
      ).success,
    ).toBe(false);
  });

  it("refuses negative counts", () => {
    expect(
      kernelResultSchema.safeParse(
        result({
          counts: { positive: -1, negative: 1, noDraft: 1, straddle: 1 },
        }),
      ).success,
    ).toBe(false);
  });

  it("refuses a missing counts field", () => {
    const withoutCounts = result();
    delete withoutCounts["counts"];
    expect(kernelResultSchema.safeParse(withoutCounts).success).toBe(false);
  });

  it("refuses unknown fields", () => {
    expect(kernelResultSchema.safeParse(result({ extra: true })).success).toBe(
      false,
    );
  });
});
