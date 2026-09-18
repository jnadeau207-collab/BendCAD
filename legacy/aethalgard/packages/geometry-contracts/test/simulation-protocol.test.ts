/**
 * Wire-schema coverage for the `simulate` request/result pair (voxel FEM —
 * the strengths / heat-maps pillar). These pin the envelope the kernel client
 * sends and receives: a fully-populated study round-trips for both kinds,
 * every physics-coherence refinement refuses its category error (a valueC on
 * a fixed constraint, a force without its vector, a thermal load on a stress
 * study), and the result mesh's structural invariants hold at the process
 * boundary.
 */
import { describe, expect, it } from "vitest";

import {
  kernelProtocolVersion,
  kernelRequestSchema,
  kernelResultSchema,
  simulationStudySchema,
} from "../src/index.js";

const requestId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d31d01";
const opId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d31d11";

function box(): unknown {
  return {
    id: opId,
    type: "create_box",
    schemaVersion: 1,
    name: "Bar",
    outputBodyId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d31d21",
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
      createdAt: "2026-08-04T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  };
}

/** faces(op(<opId>)).min(x) — the planar face a constraint clamps. */
function faceAst(filter: "min" | "max"): unknown {
  return {
    kind: "faces",
    scope: [{ source: "op", opId }],
    filters: [{ name: filter, args: [{ arg: "axis", value: "x" }] }],
  };
}

function staticStudy(): Record<string, unknown> {
  return {
    kind: "static-stress",
    resolutionMm: 5,
    material: {
      youngsModulusGPa: 200,
      poissonsRatio: 0.3,
      yieldStrengthMPa: 250,
      thermalConductivityWPerMK: 167,
    },
    constraints: [{ id: "fix-root", ast: faceAst("min"), kind: "fixed" }],
    loads: [
      {
        id: "end-load",
        ast: faceAst("max"),
        kind: "force",
        vectorN: [1000, 0, 0],
      },
    ],
  };
}

function heatStudy(): Record<string, unknown> {
  return {
    kind: "steady-heat",
    resolutionMm: 5,
    material: {
      youngsModulusGPa: 200,
      poissonsRatio: 0.3,
      yieldStrengthMPa: 250,
      thermalConductivityWPerMK: 167,
    },
    constraints: [
      { id: "hot-end", ast: faceAst("min"), kind: "temperature", valueC: 100 },
      { id: "cold-end", ast: faceAst("max"), kind: "temperature", valueC: 0 },
    ],
    loads: [
      {
        id: "sun",
        ast: faceAst("max"),
        kind: "heat-flux",
        wattsPerM2: 800,
      },
    ],
  };
}

function simulateRequest(study: unknown): unknown {
  return {
    protocolVersion: kernelProtocolVersion,
    requestId,
    method: "simulate",
    operations: [box()],
    study,
  };
}

describe("simulate request member", () => {
  it("round-trips a full static-stress request", () => {
    const request = simulateRequest(staticStudy());
    const parsed = kernelRequestSchema.safeParse(request);
    expect(parsed.success).toBe(true);
    if (!parsed.success || parsed.data.method !== "simulate") return;
    // No transforms anywhere on this member: the parsed value IS the wire
    // value, so the host and the mirror can never disagree on a field.
    expect(parsed.data).toEqual(request);
    expect(parsed.data.study.kind).toBe("static-stress");
  });

  it("round-trips a full steady-heat request", () => {
    const parsed = kernelRequestSchema.safeParse(simulateRequest(heatStudy()));
    expect(parsed.success).toBe(true);
    if (!parsed.success || parsed.data.method !== "simulate") return;
    expect(parsed.data.study.constraints).toHaveLength(2);
    expect(parsed.data.study.loads[0]).toMatchObject({ wattsPerM2: 800 });
  });

  it("refuses empty operations (a study needs geometry)", () => {
    const request = simulateRequest(staticStudy()) as Record<string, unknown>;
    request["operations"] = [];
    expect(kernelRequestSchema.safeParse(request).success).toBe(false);
  });

  it("refuses valueC on a fixed constraint (present iff temperature)", () => {
    const study = staticStudy();
    study["constraints"] = [
      { id: "fix-root", ast: faceAst("min"), kind: "fixed", valueC: 20 },
    ];
    expect(kernelRequestSchema.safeParse(simulateRequest(study)).success).toBe(
      false,
    );
  });

  it("refuses a temperature constraint without valueC", () => {
    const study = heatStudy();
    study["constraints"] = [
      { id: "hot-end", ast: faceAst("min"), kind: "temperature" },
    ];
    expect(kernelRequestSchema.safeParse(simulateRequest(study)).success).toBe(
      false,
    );
  });

  it("refuses a force load without vectorN", () => {
    const study = staticStudy();
    study["loads"] = [{ id: "end-load", ast: faceAst("max"), kind: "force" }];
    expect(kernelRequestSchema.safeParse(simulateRequest(study)).success).toBe(
      false,
    );
  });

  it("refuses an all-zero force vector", () => {
    const study = staticStudy();
    study["loads"] = [
      {
        id: "end-load",
        ast: faceAst("max"),
        kind: "force",
        vectorN: [0, 0, 0],
      },
    ];
    expect(kernelRequestSchema.safeParse(simulateRequest(study)).success).toBe(
      false,
    );
  });

  it("refuses a heat-flux load without wattsPerM2 (and force with it)", () => {
    const heat = heatStudy();
    heat["loads"] = [{ id: "sun", ast: faceAst("max"), kind: "heat-flux" }];
    expect(kernelRequestSchema.safeParse(simulateRequest(heat)).success).toBe(
      false,
    );
    const stress = staticStudy();
    stress["loads"] = [
      {
        id: "end-load",
        ast: faceAst("max"),
        kind: "force",
        vectorN: [1, 0, 0],
        wattsPerM2: 5,
      },
    ];
    expect(kernelRequestSchema.safeParse(simulateRequest(stress)).success).toBe(
      false,
    );
  });

  it("refuses a steady-heat study carrying a force load (kind coherence)", () => {
    const study = heatStudy();
    study["loads"] = [
      { id: "push", ast: faceAst("max"), kind: "force", vectorN: [1, 0, 0] },
    ];
    expect(kernelRequestSchema.safeParse(simulateRequest(study)).success).toBe(
      false,
    );
  });

  it("refuses a static-stress study carrying a temperature constraint", () => {
    const study = staticStudy();
    study["constraints"] = [
      { id: "hot", ast: faceAst("min"), kind: "temperature", valueC: 60 },
    ];
    expect(kernelRequestSchema.safeParse(simulateRequest(study)).success).toBe(
      false,
    );
  });

  it("refuses zero constraints and a non-positive resolution", () => {
    const noConstraints = staticStudy();
    noConstraints["constraints"] = [];
    expect(simulationStudySchema.safeParse(noConstraints).success).toBe(false);
    const flatResolution = staticStudy();
    flatResolution["resolutionMm"] = 0;
    expect(simulationStudySchema.safeParse(flatResolution).success).toBe(false);
  });

  it("refuses a Poisson ratio at the incompressible bound", () => {
    const study = staticStudy();
    (study["material"] as Record<string, unknown>)["poissonsRatio"] = 0.5;
    expect(simulationStudySchema.safeParse(study).success).toBe(false);
  });
});

describe("simulation_result member", () => {
  /** One voxel skin quad (4 vertices, 2 triangles) with plausible scalars. */
  function staticResult(): Record<string, unknown> {
    return {
      type: "simulation_result",
      kind: "static-stress",
      mesh: {
        positions: [0, 0, 0, 5, 0, 0, 5, 5, 0, 0, 5, 0],
        triangles: [0, 1, 2, 0, 2, 3],
        scalars: [9.8, 10.1, 10.0, 9.9],
      },
      scalar: { name: "vonMisesMPa", min: 9.8, max: 10.1 },
      displacementMaxMm: 0.005,
      summary: { elementCount: 80, nodeCount: 189, iterations: 42 },
    };
  }

  function heatResult(): Record<string, unknown> {
    const result = staticResult();
    result["kind"] = "steady-heat";
    result["scalar"] = { name: "temperatureC", min: 0, max: 100 };
    result["mesh"] = {
      positions: [0, 0, 0, 5, 0, 0, 5, 5, 0, 0, 5, 0],
      triangles: [0, 1, 2, 0, 2, 3],
      scalars: [100, 50, 25, 0],
    };
    delete result["displacementMaxMm"];
    return result;
  }

  it("round-trips a static-stress result", () => {
    const result = staticResult();
    const parsed = kernelResultSchema.safeParse(result);
    expect(parsed.success).toBe(true);
    if (!parsed.success) return;
    expect(parsed.data).toEqual(result);
  });

  it("round-trips a steady-heat result (no displacementMaxMm)", () => {
    expect(kernelResultSchema.safeParse(heatResult()).success).toBe(true);
  });

  it("refuses displacementMaxMm on a steady-heat result", () => {
    const result = heatResult();
    result["displacementMaxMm"] = 0.1;
    expect(kernelResultSchema.safeParse(result).success).toBe(false);
  });

  it("refuses a static-stress result missing displacementMaxMm", () => {
    const result = staticResult();
    delete result["displacementMaxMm"];
    expect(kernelResultSchema.safeParse(result).success).toBe(false);
  });

  it("refuses a scalar name that contradicts the study kind", () => {
    const result = staticResult();
    result["scalar"] = { name: "temperatureC", min: 0, max: 1 };
    expect(kernelResultSchema.safeParse(result).success).toBe(false);
  });

  it("refuses a mesh whose scalars do not cover its vertices", () => {
    const result = staticResult();
    (result["mesh"] as Record<string, unknown>)["scalars"] = [1, 2, 3];
    expect(kernelResultSchema.safeParse(result).success).toBe(false);
  });

  it("refuses ragged position/triangle arrays and out-of-range indices", () => {
    const raggedPositions = staticResult();
    (raggedPositions["mesh"] as Record<string, unknown>)["positions"] = [
      0, 0, 0, 1,
    ];
    expect(kernelResultSchema.safeParse(raggedPositions).success).toBe(false);
    const raggedTriangles = staticResult();
    (raggedTriangles["mesh"] as Record<string, unknown>)["triangles"] = [
      0, 1, 2, 0,
    ];
    expect(kernelResultSchema.safeParse(raggedTriangles).success).toBe(false);
    const wildIndex = staticResult();
    (wildIndex["mesh"] as Record<string, unknown>)["triangles"] = [0, 1, 9];
    expect(kernelResultSchema.safeParse(wildIndex).success).toBe(false);
  });
});
