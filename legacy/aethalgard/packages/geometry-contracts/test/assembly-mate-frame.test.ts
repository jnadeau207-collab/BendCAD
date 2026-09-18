/**
 * Wire contract for ASM-005 mate-frame resolution (plan 07 §5): the durable
 * `MateFrame` a definition's exact f64 B-rep resolves an `AssemblyEndpoint`
 * selector to, and the live `resolve_mate_frames` request/result pair backed by
 * `native/kernel-host/src/mate_frame.*`.
 */
import { describe, expect, it } from "vitest";

import {
  endpointResolutionOutcomeSchema,
  endpointResolutionStatusSchema,
  mateFrameEndpointRequestSchema,
  mateFrameGeometrySchema,
  mateFrameSchema,
  resolveMateFramesRequestSchema,
  resolveMateFramesResultSchema,
  type EndpointResolutionStatus,
  type MateFrameGeometry,
} from "../src/index.js";

function uuidAt(index: number): string {
  return `018f0f5d-0000-7000-8000-${index.toString(16).padStart(12, "0")}`;
}

const unitX = [1, 0, 0];
const unitY = [0, 1, 0];

function evidence(overrides: Record<string, unknown>): unknown {
  return {
    kind: "face",
    geometryClass: "plane",
    measure: 100,
    centroid: [0, 0, 0],
    axis: [0, 0, 1],
    radius: null,
    ...overrides,
  };
}

const pointEvidence = evidence({
  kind: "vertex",
  geometryClass: "point",
  measure: 0,
  axis: null,
});
const axisEvidence = evidence({
  kind: "edge",
  geometryClass: "circle",
  measure: 31.4159265,
  axis: [0, 0, 1],
  radius: 5,
});
const planeEvidence = evidence({});
const cylinderEvidence = evidence({
  geometryClass: "cylinder",
  measure: 150,
  centroid: [0, 0, 5],
  radius: 5,
});
const coneEvidence = evidence({
  geometryClass: "cone",
  measure: 200,
  centroid: [0, 0, 5],
  radius: 5,
});
const sphereEvidence = evidence({
  geometryClass: "sphere",
  measure: 300,
  axis: null,
});

function frame(overrides: Record<string, unknown>): unknown {
  return {
    origin: [0, 0, 0],
    primary: unitX,
    secondary: unitY,
    orientationClass: "directed",
    ...overrides,
  };
}

const wellFormedFrames: Record<MateFrameGeometry, unknown> = {
  point: frame({
    geometry: "point",
    orientationClass: "isotropic",
    sourceEvidence: pointEvidence,
  }),
  axis: frame({
    geometry: "axis",
    orientationClass: "undirected-axis",
    radius: 5,
    sourceEvidence: axisEvidence,
  }),
  plane: frame({ geometry: "plane", sourceEvidence: planeEvidence }),
  cylinder: frame({
    geometry: "cylinder",
    orientationClass: "undirected-axis",
    radius: 5,
    sourceEvidence: cylinderEvidence,
  }),
  cone: frame({
    geometry: "cone",
    orientationClass: "undirected-axis",
    radius: 5,
    halfAngleRad: 0.3,
    sourceEvidence: coneEvidence,
  }),
  sphere: frame({
    geometry: "sphere",
    orientationClass: "isotropic",
    radius: 5,
    sourceEvidence: sphereEvidence,
  }),
};

describe("mateFrameSchema well-formed geometry classes", () => {
  it.each(mateFrameGeometrySchema.options)(
    "accepts a well-formed %s frame",
    (geometry) => {
      expect(
        mateFrameSchema.safeParse(wellFormedFrames[geometry]).success,
      ).toBe(true);
    },
  );

  it("carries radius on axis/cylinder/cone/sphere and omits it on point/plane", () => {
    for (const geometry of ["axis", "cylinder", "cone", "sphere"] as const) {
      expect(mateFrameSchema.parse(wellFormedFrames[geometry])).toMatchObject({
        radius: 5,
      });
    }
    for (const geometry of ["point", "plane"] as const) {
      const parsed = mateFrameSchema.parse(wellFormedFrames[geometry]) as {
        radius?: number;
      };
      expect(parsed.radius).toBeUndefined();
    }
  });

  it("carries halfAngleRad only on cone", () => {
    const cone = mateFrameSchema.parse(wellFormedFrames.cone) as {
      halfAngleRad?: number;
    };
    expect(cone.halfAngleRad).toBe(0.3);
    for (const geometry of [
      "point",
      "axis",
      "plane",
      "cylinder",
      "sphere",
    ] as const) {
      const parsed = mateFrameSchema.parse(wellFormedFrames[geometry]) as {
        halfAngleRad?: number;
      };
      expect(parsed.halfAngleRad).toBeUndefined();
    }
  });

  it("rejects orientation values outside the native vocabulary", () => {
    expect(
      mateFrameSchema.safeParse(
        frame({
          geometry: "plane",
          orientationClass: "display-only",
          sourceEvidence: planeEvidence,
        }),
      ).success,
    ).toBe(false);
  });
});

describe("mateFrameSchema rejects malformed frames", () => {
  it("rejects a primary vector that is not a unit vector", () => {
    expect(
      mateFrameSchema.safeParse(
        frame({
          geometry: "point",
          orientationClass: "isotropic",
          sourceEvidence: pointEvidence,
          primary: [2, 0, 0],
        }),
      ).success,
    ).toBe(false);
  });

  it("rejects primary/secondary that are not mutually perpendicular", () => {
    expect(
      mateFrameSchema.safeParse(
        frame({
          geometry: "point",
          orientationClass: "isotropic",
          sourceEvidence: pointEvidence,
          primary: unitX,
          secondary: unitX,
        }),
      ).success,
    ).toBe(false);
  });

  it("rejects a radius present with geometry plane", () => {
    expect(
      mateFrameSchema.safeParse(
        frame({ geometry: "plane", sourceEvidence: planeEvidence, radius: 5 }),
      ).success,
    ).toBe(false);
  });

  it("rejects halfAngleRad present with geometry cylinder", () => {
    expect(
      mateFrameSchema.safeParse(
        frame({
          geometry: "cylinder",
          orientationClass: "undirected-axis",
          radius: 5,
          halfAngleRad: 0.3,
          sourceEvidence: cylinderEvidence,
        }),
      ).success,
    ).toBe(false);
  });

  it.each(["point", "plane"] as const)(
    "rejects a radius present on %s geometry",
    (geometry) => {
      const sourceEvidence =
        geometry === "point" ? pointEvidence : planeEvidence;
      expect(
        mateFrameSchema.safeParse(
          frame({
            geometry,
            orientationClass: geometry === "point" ? "isotropic" : "directed",
            sourceEvidence,
            radius: 5,
          }),
        ).success,
      ).toBe(false);
    },
  );

  it.each(["point", "axis", "plane", "sphere"] as const)(
    "rejects halfAngleRad present on %s geometry",
    (geometry) => {
      const evidenceByGeometry = {
        point: pointEvidence,
        axis: axisEvidence,
        plane: planeEvidence,
        sphere: sphereEvidence,
      } as const;
      const orientationByGeometry = {
        point: "isotropic",
        axis: "undirected-axis",
        plane: "directed",
        sphere: "isotropic",
      } as const;
      const overrides: Record<string, unknown> = {
        geometry,
        orientationClass: orientationByGeometry[geometry],
        sourceEvidence: evidenceByGeometry[geometry],
        halfAngleRad: 0.3,
      };
      if (geometry === "axis" || geometry === "sphere") overrides.radius = 5;
      expect(mateFrameSchema.safeParse(frame(overrides)).success).toBe(false);
    },
  );
});

const endpointRequestId = "endpoint-1";
const validAst = {
  kind: "faces",
  scope: [{ source: "all" }],
  filters: [],
};

function endpointRequest(overrides: Record<string, unknown> = {}): unknown {
  return {
    requestId: endpointRequestId,
    ast: validAst,
    expectedGeometry: "plane",
    ...overrides,
  };
}

function candidateEntity(ordinal: number): unknown {
  return {
    token: `t:${uuidAt(1)}/faces/${ordinal}`,
    kind: "face",
    bodyId: uuidAt(2),
    centroid: [0, 0, 0],
  };
}

function outcomeFor(status: EndpointResolutionStatus): unknown {
  switch (status) {
    case "resolved":
      return {
        requestId: endpointRequestId,
        status,
        frame: wellFormedFrames.plane,
      };
    case "missing":
      return {
        requestId: endpointRequestId,
        status,
        message: "endpoint selector matched zero entities",
      };
    case "ambiguous":
      return {
        requestId: endpointRequestId,
        status,
        candidates: [candidateEntity(0), candidateEntity(1)],
        message: "endpoint selector matched 2 entities",
      };
    case "invalidated":
      return {
        requestId: endpointRequestId,
        status,
        message: "definition revision changed incompatibly",
      };
  }
}

describe("resolveMateFrames request/result contracts", () => {
  it("parses a minimal one-endpoint resolve request", () => {
    expect(
      resolveMateFramesRequestSchema.safeParse({
        operations: [],
        endpoints: [endpointRequest()],
      }).success,
    ).toBe(true);
  });

  it.each(endpointResolutionStatusSchema.options)(
    "round-trips a %s endpoint outcome standalone and inside a result",
    (status) => {
      const outcome = outcomeFor(status);
      expect(endpointResolutionOutcomeSchema.safeParse(outcome).success).toBe(
        true,
      );
      expect(
        resolveMateFramesResultSchema.safeParse({ outcomes: [outcome] })
          .success,
      ).toBe(true);
    },
  );

  it("rejects a resolved outcome missing its frame", () => {
    expect(
      endpointResolutionOutcomeSchema.safeParse({
        requestId: endpointRequestId,
        status: "resolved",
      }).success,
    ).toBe(false);
  });

  it("rejects an unknown status literal", () => {
    expect(
      endpointResolutionOutcomeSchema.safeParse({
        requestId: endpointRequestId,
        status: "suppressed",
        message: "not one of the four resolution outcomes",
      }).success,
    ).toBe(false);
  });

  it("rejects a result carrying a malformed outcome", () => {
    expect(
      resolveMateFramesResultSchema.safeParse({
        outcomes: [{ requestId: endpointRequestId, status: "resolved" }],
      }).success,
    ).toBe(false);
  });
});

describe("mateFrameEndpointRequestSchema ast validation", () => {
  it("accepts a well-formed selector ast", () => {
    expect(
      mateFrameEndpointRequestSchema.safeParse(endpointRequest()).success,
    ).toBe(true);
  });

  it("rejects an ast missing selectorQuerySchema's required scope field", () => {
    expect(
      mateFrameEndpointRequestSchema.safeParse(
        endpointRequest({ ast: { kind: "faces", filters: [] } }),
      ).success,
    ).toBe(false);
  });

  it("rejects an ast whose scope is not an array", () => {
    expect(
      mateFrameEndpointRequestSchema.safeParse(
        endpointRequest({ ast: { kind: "faces", scope: "all", filters: [] } }),
      ).success,
    ).toBe(false);
  });

  it("rejects an ast that is not an object at all", () => {
    expect(
      mateFrameEndpointRequestSchema.safeParse(
        endpointRequest({ ast: "faces()" }),
      ).success,
    ).toBe(false);
  });
});
