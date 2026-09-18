import { describe, expect, it } from "vitest";

import { sweepOperationV2Schema } from "../src/index.js";

const PROFILE = "00000000-0000-4000-8000-000000000001";
const PATH_A = "00000000-0000-4000-8000-000000000002";
const PATH_B = "00000000-0000-4000-8000-000000000003";
const GUIDE = "00000000-0000-4000-8000-000000000004";
const END = "00000000-0000-4000-8000-000000000005";
const TARGET = "00000000-0000-4000-8000-000000000006";

function ref(kind: "edges" | "faces", operationId: string) {
  return {
    query: `${kind}(op(${operationId}))`,
    arity: "one" as const,
    anchors: [],
    onEmpty: "error" as const,
  };
}

function validSweep() {
  return {
    id: "00000000-0000-4000-8000-000000000010",
    type: "sweep" as const,
    schemaVersion: 2 as const,
    name: "Associative sweep",
    outputBodyId: "00000000-0000-4000-8000-000000000011",
    parameters: {
      profileOperationId: PROFILE,
      sketchRegionIds: ["region:closed-loop"],
      path: [ref("edges", PATH_A), ref("edges", PATH_B)],
      guideRail: ref("edges", GUIDE),
      orientation: "natural" as const,
      extent: { mode: "toReference" as const, end: ref("faces", END) },
      pathDirection: "reverse" as const,
      startRotationDegrees: 17,
      taperAngleDeg: 3,
      twistAngleDegrees: 31,
      boolean: { mode: "cut" as const, targetOperationId: TARGET },
    },
    metadata: {
      createdAt: "2026-08-09T00:00:00.000Z",
      createdBy: { kind: "user" as const },
    },
  };
}

describe("Sweep v2 associative contract (issue #140)", () => {
  it("preserves ordered references and every professional control", () => {
    const parsed = sweepOperationV2Schema.parse(validSweep());

    expect(parsed.parameters.path.map((pathRef) => pathRef.query)).toEqual([
      `edges(op(${PATH_A}))`,
      `edges(op(${PATH_B}))`,
    ]);
    expect(parsed.parameters.guideRail?.query).toBe(`edges(op(${GUIDE}))`);
    expect(parsed.parameters.orientation).toBe("natural");
    expect(parsed.parameters.extent).toEqual({
      mode: "toReference",
      end: ref("faces", END),
    });
    expect(parsed.parameters.pathDirection).toBe("reverse");
    expect(parsed.parameters.startRotationDegrees).toBe(17);
    expect(parsed.parameters.taperAngleDeg).toBe(3);
    expect(parsed.parameters.twistAngleDegrees).toBe(31);
    expect(parsed.parameters.boolean).toEqual({
      mode: "cut",
      targetOperationId: TARGET,
    });
  });

  it("accepts fixed orientation when no competing guide is authored", () => {
    const value = validSweep();
    const parsed = sweepOperationV2Schema.parse({
      ...value,
      parameters: {
        ...value.parameters,
        guideRail: undefined,
        orientation: "fixed",
      },
    });
    expect(parsed.parameters.orientation).toBe("fixed");
    expect(parsed.parameters.guideRail).toBeUndefined();
  });

  it("requires exactly one profile source", () => {
    expect(() =>
      sweepOperationV2Schema.parse({
        ...validSweep(),
        parameters: {
          ...validSweep().parameters,
          faceProfile: ref("faces", PROFILE),
        },
      }),
    ).toThrow(/Exactly one/);
  });

  it("requires at least one durable path edge", () => {
    expect(() =>
      sweepOperationV2Schema.parse({
        ...validSweep(),
        parameters: { ...validSweep().parameters, path: [] },
      }),
    ).toThrow();
  });
});
