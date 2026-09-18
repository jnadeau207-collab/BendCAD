import { describe, expect, it } from "vitest";

import { operationRefSchema } from "../src/index.js";

const durable = {
  query: 'faces(op("aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa")).role(top)',
  arity: "one" as const,
  anchors: [
    {
      token: "t:aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa/top/0",
      kind: "face" as const,
      centroid: [0, 0, 0] as const,
      surface: "plane" as const,
      normal: [0, 0, 1] as const,
      axis: {
        origin: [0, 0, 0] as const,
        dir: [0, 0, 1] as const,
      },
      radius: 4,
      adjHash: "0123456789abcdef",
    },
  ],
  onEmpty: "error" as const,
};

describe("durable topology boundary", () => {
  it("accepts query, lineage, analytic, and incidence evidence", () => {
    expect(operationRefSchema.parse(durable)).toEqual(durable);
  });

  it.each([
    ["entityIndex", 7],
    ["faceIndex", 7],
    ["edgeIndex", 7],
    ["presentationBodyId", "bbbbbbbb-2222-4b22-8b22-bbbbbbbbbbbb"],
    ["processEpoch", 3],
    ["evaluationEpoch", 9],
  ])("rejects epoch-local %s from a persisted anchor", (field, value) => {
    expect(() =>
      operationRefSchema.parse({
        ...durable,
        anchors: [{ ...durable.anchors[0], [field]: value }],
      }),
    ).toThrow();
  });

  it("rejects presentation identity from the persisted ref envelope", () => {
    expect(() =>
      operationRefSchema.parse({
        ...durable,
        occurrenceId: "cccccccc-3333-4c33-8c33-cccccccccccc",
        presentationBodyId: "dddddddd-4444-4d44-8d44-dddddddddddd",
      }),
    ).toThrow();
  });
});
