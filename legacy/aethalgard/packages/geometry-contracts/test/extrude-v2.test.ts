import { describe, expect, it } from "vitest";

import {
  operationSchema,
  wireOperationSchema,
  type OperationRef,
  type OperationRefWire,
} from "../src/index.js";

const PROFILE = "00000000-0000-4000-8000-0000000000a1";
const SOURCE = "00000000-0000-4000-8000-0000000000a2";
const TARGET = "00000000-0000-4000-8000-0000000000a3";
const EXTRUDE = "00000000-0000-4000-8000-0000000000b1";
const BODY = "00000000-0000-4000-8000-0000000000b2";

const metadata = {
  createdAt: "2026-08-08T14:00:00.000Z",
  createdBy: { kind: "user" as const },
};

function extrude(parameters: Record<string, unknown>) {
  return {
    id: EXTRUDE,
    type: "extrude" as const,
    schemaVersion: 2 as const,
    name: "Extrude 1",
    outputBodyId: BODY,
    parameters,
    metadata,
  };
}

const persistedFaceRef: OperationRef = {
  query: `faces(op(${SOURCE}))`,
  arity: "one",
  anchors: [],
  onEmpty: "error",
};

const wireFaceRef: OperationRefWire = {
  ast: {
    kind: "faces",
    scope: [{ source: "op", opId: SOURCE }],
    filters: [],
  },
  arity: "one",
  anchors: [],
  onEmpty: "error",
};

describe("Extrude v2 kernel-wire contract", () => {
  it("accepts a profile-based v2 operation on the kernel wire", () => {
    const operation = extrude({
      profileOperationId: PROFILE,
      start: { mode: "offset", offsetMm: 5 },
      extent: {
        mode: "twoSided",
        distanceForwardMm: 5,
        distanceBackwardMm: 15,
      },
      direction: "reverse",
      boolean: { mode: "join", targetOperationId: TARGET },
    });

    expect(operationSchema.safeParse(operation).success).toBe(true);
    expect(wireOperationSchema.safeParse(operation).success).toBe(true);
  });

  it("requires wire AST refs for face-profile and to-face operations", () => {
    const wireOperation = extrude({
      faceProfile: wireFaceRef,
      toFace: {
        ...wireFaceRef,
        ast: { ...wireFaceRef.ast, scope: [{ source: "op", opId: TARGET }] },
      },
      start: { mode: "profilePlane" },
      extent: { mode: "toFace" },
      direction: "normal",
      boolean: { mode: "newBody" },
    });
    const persistedOperation = extrude({
      faceProfile: persistedFaceRef,
      toFace: { ...persistedFaceRef, query: `faces(op(${TARGET}))` },
      start: { mode: "profilePlane" },
      extent: { mode: "toFace" },
      direction: "normal",
      boolean: { mode: "newBody" },
    });

    expect(wireOperationSchema.safeParse(wireOperation).success).toBe(true);
    expect(operationSchema.safeParse(wireOperation).success).toBe(false);
    expect(operationSchema.safeParse(persistedOperation).success).toBe(true);
    expect(wireOperationSchema.safeParse(persistedOperation).success).toBe(
      false,
    );
  });

  describe("start: object", () => {
    const startObjectRef: OperationRef = {
      ...persistedFaceRef,
      query: `faces(op(${TARGET}))`,
    };

    it("accepts start object with a durable reference, with and without an extra offset", () => {
      const base = {
        profileOperationId: PROFILE,
        extent: { mode: "distance", distanceMm: 10 },
        direction: "normal",
        boolean: { mode: "newBody" },
      };

      expect(
        operationSchema.safeParse(
          extrude({
            ...base,
            start: { mode: "object" },
            startObject: startObjectRef,
          }),
        ).success,
      ).toBe(true);

      expect(
        operationSchema.safeParse(
          extrude({
            ...base,
            start: { mode: "object", offsetMm: 5 },
            startObject: startObjectRef,
          }),
        ).success,
      ).toBe(true);
    });

    it("refuses start object without a reference, and a reference without start object", () => {
      const base = {
        profileOperationId: PROFILE,
        extent: { mode: "distance", distanceMm: 10 },
        direction: "normal",
        boolean: { mode: "newBody" },
      };

      // object mode with no ref would otherwise have to guess a plane.
      expect(
        operationSchema.safeParse(
          extrude({ ...base, start: { mode: "object" } }),
        ).success,
      ).toBe(false);

      // A ref that no mode consumes is a silent no-op; reject it outright so
      // authored intent cannot be quietly dropped.
      expect(
        operationSchema.safeParse(
          extrude({
            ...base,
            start: { mode: "profilePlane" },
            startObject: startObjectRef,
          }),
        ).success,
      ).toBe(false);
    });

    it("keeps the persisted and wire ref forms distinct for start object", () => {
      const base = {
        profileOperationId: PROFILE,
        start: { mode: "object" },
        extent: { mode: "distance", distanceMm: 10 },
        direction: "normal",
        boolean: { mode: "newBody" },
      };
      const wireOp = extrude({
        ...base,
        startObject: {
          ...wireFaceRef,
          ast: { ...wireFaceRef.ast, scope: [{ source: "op", opId: TARGET }] },
        },
      });
      const persistedOp = extrude({ ...base, startObject: startObjectRef });

      expect(wireOperationSchema.safeParse(wireOp).success).toBe(true);
      expect(operationSchema.safeParse(wireOp).success).toBe(false);
      expect(operationSchema.safeParse(persistedOp).success).toBe(true);
      expect(wireOperationSchema.safeParse(persistedOp).success).toBe(false);
    });
  });
});
