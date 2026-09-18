import { describe, expect, it } from "vitest";

import {
  holeOperationSchema,
  holeOperationV2Schema,
  operationSchema,
  type OperationRef,
} from "../src/index.js";

const TARGET = "00000000-0000-4000-8000-0000000000a1";
const HOLE = "00000000-0000-4000-8000-0000000000b1";
const BODY = "00000000-0000-4000-8000-0000000000b2";

const faceRef: OperationRef = {
  query: `faces(op(${TARGET}))`,
  arity: "one",
  anchors: [],
  onEmpty: "error",
};

const metadata = {
  createdAt: "2026-08-08T01:00:00.000Z",
  createdBy: { kind: "user" as const },
};

function base(parameters: Record<string, unknown>) {
  return {
    id: HOLE,
    type: "hole" as const,
    schemaVersion: 2 as const,
    name: "Hole 1",
    outputBodyId: BODY,
    parameters: {
      targetOperationId: TARGET,
      entryFace: faceRef,
      placementMode: "face-points" as const,
      facePoints: [{ uMm: 12, vMm: -8 }],
      direction: "into" as const,
      startOffsetMm: 0,
      form: { kind: "simple" as const, diameterMm: 6 },
      extentMode: "through-all" as const,
      extentOffsetMm: 0,
      drillPoint: { kind: "flat" as const },
      ...parameters,
    },
    metadata,
  };
}

describe("Hole v2 contract", () => {
  it("extends the legacy operation catalog without invalidating v1", () => {
    const legacy = {
      id: HOLE,
      type: "hole" as const,
      schemaVersion: 1 as const,
      name: "Legacy hole",
      outputBodyId: BODY,
      parameters: {
        targetOperationId: TARGET,
        placement: {
          origin: [0, 0, 20],
          zDirection: [0, 0, -1],
          xDirection: [1, 0, 0],
        },
        size: { kind: "diameter" as const, diameter: 6 },
        throughAll: true,
      },
      metadata,
    };
    expect(holeOperationSchema.safeParse(legacy).success).toBe(true);
    expect(operationSchema.safeParse(legacy).success).toBe(true);
    expect(operationSchema.safeParse(base({})).success).toBe(true);
  });

  it("accepts all professional Hole forms", () => {
    const forms = [
      { kind: "simple", diameterMm: 6 },
      {
        kind: "counterbore",
        diameterMm: 6,
        counterboreDiameterMm: 10,
        counterboreDepthMm: 4,
      },
      {
        kind: "countersink",
        diameterMm: 6,
        countersinkDiameterMm: 12,
        includedAngleDegrees: 90,
      },
      { kind: "clearance", nominal: "M6", fit: "medium" },
      {
        kind: "tapped",
        designation: "M6x1",
        threadClass: "6H",
        handedness: "right",
        threadMode: "cosmetic",
      },
    ] as const;
    for (const form of forms) {
      expect(holeOperationV2Schema.safeParse(base({ form })).success).toBe(
        true,
      );
    }
  });

  it("accepts direct multi-point, sketch-point, reference, and concentric placement", () => {
    const variants = [
      base({
        facePoints: [
          { uMm: 1, vMm: 2 },
          { uMm: 8, vMm: 9 },
        ],
      }),
      base({
        placementMode: "sketch-points",
        facePoints: undefined,
        sketchOperationId: "00000000-0000-4000-8000-0000000000c1",
        sketchPointEntityIds: [
          "ent_00000000000000000000000001",
          "ent_00000000000000000000000002",
        ],
      }),
      base({
        placementMode: "reference-points",
        facePoints: undefined,
        pointRefs: {
          ...faceRef,
          query: `vertices(op(${TARGET}))`,
          arity: "one-or-more",
        },
      }),
      base({
        placementMode: "concentric-face",
        facePoints: undefined,
        axisFace: faceRef,
      }),
      base({
        placementMode: "concentric-axis",
        facePoints: undefined,
        axisEdge: { ...faceRef, query: `edges(op(${TARGET}))` },
      }),
    ];
    for (const variant of variants) {
      expect(holeOperationV2Schema.safeParse(variant).success).toBe(true);
    }
  });

  it("enforces blind / through-all / To-Face exclusivity", () => {
    expect(
      holeOperationV2Schema.safeParse(
        base({ extentMode: "blind", depthMm: 12 }),
      ).success,
    ).toBe(true);
    expect(
      holeOperationV2Schema.safeParse(
        base({ extentMode: "to-face", extentFace: faceRef }),
      ).success,
    ).toBe(true);
    expect(holeOperationV2Schema.safeParse(base({ depthMm: 12 })).success).toBe(
      false,
    );
    expect(
      holeOperationV2Schema.safeParse(
        base({ startOffsetMm: 2, extentMode: "through-all" }),
      ).success,
    ).toBe(false);
  });

  it("refuses malformed seats rather than producing overlapping nonsense", () => {
    expect(
      holeOperationV2Schema.safeParse(
        base({
          form: {
            kind: "counterbore",
            diameterMm: 8,
            counterboreDiameterMm: 6,
            counterboreDepthMm: 3,
          },
        }),
      ).success,
    ).toBe(false);
    expect(
      holeOperationV2Schema.safeParse(
        base({
          form: {
            kind: "countersink",
            diameterMm: 8,
            countersinkDiameterMm: 8,
            includedAngleDegrees: 90,
          },
        }),
      ).success,
    ).toBe(false);
  });
});
