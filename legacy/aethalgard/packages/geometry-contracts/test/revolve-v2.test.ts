import { describe, expect, it } from "vitest";

import {
  operationSchema,
  wireOperationSchema,
  type OperationRef,
  type OperationRefWire,
} from "../src/index.js";

const PROFILE = "00000000-0000-4000-8000-000000000101";
const SOURCE = "00000000-0000-4000-8000-000000000102";
const TARGET = "00000000-0000-4000-8000-000000000103";
const REVOLVE = "00000000-0000-4000-8000-000000000104";
const BODY = "00000000-0000-4000-8000-000000000105";
const metadata = {
  createdAt: "2026-08-08T20:00:00.000Z",
  createdBy: { kind: "user" as const },
};

const edgeRef: OperationRef = {
  query: `edges(op(${SOURCE}))`,
  arity: "one",
  anchors: [],
  onEmpty: "error",
};
const faceRef: OperationRef = {
  query: `faces(op(${SOURCE}))`,
  arity: "one",
  anchors: [],
  onEmpty: "error",
};
const wireEdgeRef: OperationRefWire = {
  ast: {
    kind: "edges",
    scope: [{ source: "op", opId: SOURCE }],
    filters: [],
  },
  arity: "one",
  anchors: [],
  onEmpty: "error",
};

function revolve(parameters: Record<string, unknown>) {
  return {
    id: REVOLVE,
    type: "revolve" as const,
    schemaVersion: 2 as const,
    name: "Spin 1",
    outputBodyId: BODY,
    parameters,
    metadata,
  };
}

function baseParameters() {
  return {
    profileOperationId: PROFILE,
    axisSource: { kind: "edge" },
    axisEdge: edgeRef,
    extent: { mode: "oneSide", angleDegrees: 75 },
    direction: "forward",
    boolean: { mode: "newBody" },
  };
}

describe("Revolve v2 contract (issue #139)", () => {
  it("accepts every professional angular extent", () => {
    for (const extent of [
      { mode: "oneSide", angleDegrees: 75 },
      { mode: "symmetric", angleDegrees: 120 },
      {
        mode: "twoSided",
        forwardAngleDegrees: 30,
        backwardAngleDegrees: 210,
      },
      { mode: "full" },
    ]) {
      expect(
        operationSchema.safeParse(revolve({ ...baseParameters(), extent }))
          .success,
      ).toBe(true);
    }
  });

  it("keeps direction independent and accepts unequal thin walls", () => {
    expect(
      operationSchema.safeParse(
        revolve({
          ...baseParameters(),
          direction: "reverse",
          thin: { sideOneMm: 2, sideTwoMm: 5 },
          boolean: { mode: "cut", targetOperationId: TARGET },
        }),
      ).success,
    ).toBe(true);
  });

  it("accepts an exact rotational face axis and planar face profile", () => {
    expect(
      operationSchema.safeParse(
        revolve({
          faceProfile: faceRef,
          axisSource: { kind: "rotationalFace" },
          axisFace: { ...faceRef, query: `faces(op(${TARGET}))` },
          projectAxisToProfilePlane: true,
          extent: { mode: "full" },
          direction: "forward",
          boolean: { mode: "newBody" },
        }),
      ).success,
    ).toBe(true);
  });

  it("requires exactly one profile source and the matching axis slot", () => {
    expect(
      operationSchema.safeParse(
        revolve({ ...baseParameters(), faceProfile: faceRef }),
      ).success,
    ).toBe(false);
    expect(
      operationSchema.safeParse(
        revolve({ ...baseParameters(), axisEdge: undefined }),
      ).success,
    ).toBe(false);
    expect(
      operationSchema.safeParse(
        revolve({
          ...baseParameters(),
          axisSource: { kind: "rotationalFace" },
          axisEdge: undefined,
          axisFace: undefined,
        }),
      ).success,
    ).toBe(false);
  });

  it("refuses zero/360 partial angles, a two-sided full alias, and zero thin walls", () => {
    for (const extent of [
      { mode: "oneSide", angleDegrees: 0 },
      { mode: "oneSide", angleDegrees: 360 },
      {
        mode: "twoSided",
        forwardAngleDegrees: 180,
        backwardAngleDegrees: 180,
      },
    ]) {
      expect(
        operationSchema.safeParse(revolve({ ...baseParameters(), extent }))
          .success,
      ).toBe(false);
    }
    expect(
      operationSchema.safeParse(
        revolve({
          ...baseParameters(),
          thin: { sideOneMm: 0, sideTwoMm: 0 },
        }),
      ).success,
    ).toBe(false);
  });

  it("keeps persisted query refs and kernel wire AST refs distinct", () => {
    const persisted = revolve(baseParameters());
    const wire = revolve({ ...baseParameters(), axisEdge: wireEdgeRef });
    expect(operationSchema.safeParse(persisted).success).toBe(true);
    expect(wireOperationSchema.safeParse(persisted).success).toBe(false);
    expect(operationSchema.safeParse(wire).success).toBe(false);
    expect(wireOperationSchema.safeParse(wire).success).toBe(true);
  });

  it("keeps v1 readable while new v2 fields remain strict", () => {
    const v1 = {
      id: REVOLVE,
      type: "revolve",
      schemaVersion: 1,
      name: "Legacy Revolve",
      outputBodyId: BODY,
      parameters: {
        profileOperationId: PROFILE,
        axisOrigin: [0, 0, 0],
        axisDirection: [0, 1, 0],
        angleDegrees: 180,
      },
      metadata,
    };
    expect(operationSchema.safeParse(v1).success).toBe(true);
    expect(
      operationSchema.safeParse(
        revolve({ ...baseParameters(), accidentalFallbackAxis: [0, 1, 0] }),
      ).success,
    ).toBe(false);
  });
});
