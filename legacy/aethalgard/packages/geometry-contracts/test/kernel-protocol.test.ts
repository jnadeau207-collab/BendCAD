/**
 * Evaluation-response identity integrity: the kernel result schema must reject
 * a response whose bodies reuse a bodyId or an operationId. Downstream
 * consumers key bodies by id (viewport display map, app metadata, selection),
 * so a duplicate silently aliases two distinct bodies into one — the protocol
 * boundary is the place to catch a broken host.
 */
import { describe, expect, it } from "vitest";

import {
  kernelErrorSchema,
  kernelExportOperationTimeoutMs,
  kernelOperationTimeoutMs,
  kernelProtocolVersion,
  kernelRequestDeadlineMs,
  kernelRequestSchema,
  kernelResponseSchema,
  kernelResultSchema,
  kernelTimeoutEscalationMarginMs,
  maxDocumentOperationsBytes,
  operationsSerializedByteLength,
} from "../src/index.js";

function probes(): unknown {
  return {
    valid: true,
    volumeMm3: 1,
    surfaceAreaMm2: 6,
    centerOfMassMm: [0, 0, 0],
    boundingBoxMm: [0, 0, 0, 1, 1, 1],
    solidCount: 1,
    shellCount: 1,
    faceCount: 6,
    edgeCount: 12,
    vertexCount: 8,
  };
}

function mesh(streamSequence: number): unknown {
  return {
    format: "AEMB2",
    streamSequence,
    packetByteLength: 128,
    vertexCount: 8,
    triangleCount: 12,
    faceCount: 6,
    edgeCount: 12,
    edgeVertexCount: 24,
    brepVertexCount: 8,
    lodTier: 0,
    deflectionMm: 0.01,
    angularDeflectionRad: 0.5,
    checksumCrc32: "0a1b2c3d",
    epoch: 1,
    boundingBoxMm: [0, 0, 0, 1, 1, 1],
    worldOriginMm: [0, 0, 0],
    boundingBoxLocalMm: [0, 0, 0, 1, 1, 1],
  };
}

function body(
  bodyId: string,
  operationId: string,
  streamSequence: number,
): unknown {
  return { bodyId, operationId, probes: probes(), mesh: mesh(streamSequence) };
}

function evaluation(bodies: unknown[]): unknown {
  return { type: "evaluation", revision: 1, epoch: 1, bodies };
}

const idA = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d01";
const idB = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d02";
const opA = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d11";
const opB = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d12";

describe("kernelResultSchema evaluation identity", () => {
  it("accepts distinct body and operation ids", () => {
    const result = kernelResultSchema.safeParse(
      evaluation([body(idA, opA, 1), body(idB, opB, 2)]),
    );
    expect(result.success).toBe(true);
  });

  it("rejects a duplicate bodyId across bodies", () => {
    const result = kernelResultSchema.safeParse(
      evaluation([body(idA, opA, 1), body(idA, opB, 2)]),
    );
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(
        result.error.issues.some((issue) =>
          /duplicate body id/i.test(issue.message),
        ),
      ).toBe(true);
    }
  });

  it("rejects a repeated operationId that is not a declared birth fan-out", () => {
    // CAP-024 / ADR-013 decision 3 relaxed this array from "one entry per
    // body-producing OPERATION" to "one entry per BORN BODY", so an
    // operationId may now repeat — but ONLY as a complete 0..N-1 index set.
    // Two entries that both default to index 0 are still two bodies claiming to
    // be the same one, so this stays a refusal; what changed is the reason.
    const result = kernelResultSchema.safeParse(
      evaluation([body(idA, opA, 1), body(idB, opA, 2)]),
    );
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(
        result.error.issues.some((issue) =>
          /complete 0\.\.N-1 set/i.test(issue.message),
        ),
      ).toBe(true);
    }
  });

  it("accepts a repeated operationId WITH a complete output-index set", () => {
    // The seam change itself: a multi-solid import legitimately returns several
    // bodies from one operation. Full coverage of the new rule lives in
    // `evaluation-birth-fanout.test.ts`; this is the consumer-side proof that
    // the relaxation actually landed here.
    const fanned = [
      { ...(body(idA, opA, 1) as Record<string, unknown>), outputIndex: 0 },
      { ...(body(idB, opA, 2) as Record<string, unknown>), outputIndex: 1 },
    ];
    expect(kernelResultSchema.safeParse(evaluation(fanned)).success).toBe(true);
  });
});

describe("evaluate_document LOD request contract (Wave 2.2)", () => {
  const request = {
    protocolVersion: kernelProtocolVersion,
    requestId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d21",
    documentId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d22",
    revision: 1,
    method: "evaluate_document",
    operations: [],
  } as const;

  it("preserves the current tier-0-compatible request when lodTier is omitted", () => {
    const result = kernelRequestSchema.safeParse(request);
    expect(result.success).toBe(true);
    if (!result.success) return;
    expect(result.data).not.toHaveProperty("lodTier");
  });

  it.each([0, 1, 2])("accepts viewport LOD tier %i", (lodTier) => {
    expect(kernelRequestSchema.safeParse({ ...request, lodTier }).success).toBe(
      true,
    );
  });

  it.each([3, -1, -10, 2.5])(
    "rejects unsupported or non-integer LOD tier %s",
    (lodTier) => {
      expect(
        kernelRequestSchema.safeParse({ ...request, lodTier }).success,
      ).toBe(false);
    },
  );

  it("accepts a bounded topology selection request", () => {
    expect(
      kernelRequestSchema.safeParse({
        ...request,
        topologySelection: {
          bodyId: idA,
          kind: "edge",
          entityIndex: 11,
        },
      }).success,
    ).toBe(true);
  });

  it("rejects whole-snapshot and bounded topology modes together", () => {
    const result = kernelRequestSchema.safeParse({
      ...request,
      includeTopology: true,
      topologySelection: {
        bodyId: idA,
        kind: "face",
        entityIndex: 0,
      },
    });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.message).toMatch(/mutually exclusive/);
    }
  });

  it.each([-1, 1_000_000, 1.5])(
    "rejects invalid topology selection entity index %s",
    (entityIndex) => {
      expect(
        kernelRequestSchema.safeParse({
          ...request,
          topologySelection: {
            bodyId: idA,
            kind: "vertex",
            entityIndex,
          },
        }).success,
      ).toBe(false);
    },
  );

  it("leaves export_mesh strict and without a lodTier request field", () => {
    expect(
      kernelRequestSchema.safeParse({
        ...request,
        method: "export_mesh",
        lodTier: 2,
      }).success,
    ).toBe(false);
  });
});

describe("kernel/queue timeout budget reconciliation (finding 2)", () => {
  // The per-REQUEST queue deadline must be strictly longer than the per-OP kernel
  // cap plus the escalation margin, or the queue kills (and starts a restart)
  // before the kernel's cooperative TIMEOUT can return an attributed error.
  for (const method of [
    "evaluate_document",
    "export_step",
    "export_mesh",
    "query",
  ]) {
    it(`gives ${method} a request deadline past its op cap + escalation`, () => {
      expect(kernelRequestDeadlineMs(method)).toBeGreaterThan(
        kernelOperationTimeoutMs(method) + kernelTimeoutEscalationMarginMs,
      );
    });
  }

  it("caps exports at 120 s and everything else at 30 s (mirrors native)", () => {
    expect(kernelOperationTimeoutMs("export_step")).toBe(120_000);
    expect(kernelOperationTimeoutMs("export_mesh")).toBe(120_000);
    expect(kernelOperationTimeoutMs("evaluate_document")).toBe(30_000);
  });

  it("keeps every deadline above the default 30 s queue deadline it replaces", () => {
    expect(kernelRequestDeadlineMs("evaluate_document")).toBeGreaterThan(
      30_000,
    );
    expect(kernelRequestDeadlineMs("export_step")).toBeGreaterThan(30_000);
  });
});

describe("kernel TIMEOUT attribution (Wave 2.1 slice 3b, finding 3)", () => {
  const timedOutOpId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d31";

  it("accepts a fully attributed TIMEOUT", () => {
    const result = kernelErrorSchema.safeParse({
      code: "TIMEOUT",
      message: "operation exceeded its per-operation time budget",
      operationId: timedOutOpId,
      details: { timeoutMs: 30000 },
    });
    expect(result.success).toBe(true);
  });

  it("rejects a TIMEOUT missing the operationId", () => {
    const result = kernelErrorSchema.safeParse({
      code: "TIMEOUT",
      message: "x",
      details: { timeoutMs: 30000 },
    });
    expect(result.success).toBe(false);
  });

  it("rejects a TIMEOUT missing details.timeoutMs", () => {
    const result = kernelErrorSchema.safeParse({
      code: "TIMEOUT",
      message: "x",
      operationId: timedOutOpId,
    });
    expect(result.success).toBe(false);
  });

  it("rejects a bare TIMEOUT with neither attribute (the pre-fix hole)", () => {
    const result = kernelErrorSchema.safeParse({
      code: "TIMEOUT",
      message: "x",
    });
    expect(result.success).toBe(false);
  });

  it("still accepts a bare non-TIMEOUT error (attribution stays optional elsewhere)", () => {
    const result = kernelErrorSchema.safeParse({
      code: "CANCELLED",
      message: "kernel request was cancelled",
    });
    expect(result.success).toBe(true);
  });
});

describe("kernel stats method (Wave 2.1 slice 3a)", () => {
  const requestId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d21";

  function statsResult(overrides: Record<string, unknown> = {}): unknown {
    return {
      type: "stats",
      cache: {
        entries: 3,
        bytes: 4096,
        budgetBytes: 512 * 1024 * 1024,
        hits: 5,
        misses: 2,
        evictions: 1,
        snapshotsStored: 9,
      },
      uptimeMs: 1234,
      occtTag: "V8_0_0_p1",
      occtCommit: "4f95ecaa3b690e34988d42e2ca7fe882e7a8bc7d",
      kernelGeomVersion: "V8_0_0_p1+0.1.0",
      ...overrides,
    };
  }

  it("accepts a well-formed stats request with no payload", () => {
    const result = kernelRequestSchema.safeParse({
      protocolVersion: kernelProtocolVersion,
      requestId,
      method: "stats",
    });
    expect(result.success).toBe(true);
  });

  it("rejects a stats request carrying an unexpected field (strict)", () => {
    const result = kernelRequestSchema.safeParse({
      protocolVersion: kernelProtocolVersion,
      requestId,
      method: "stats",
      operations: [],
    });
    expect(result.success).toBe(false);
  });

  it("accepts a well-formed stats result", () => {
    expect(kernelResultSchema.safeParse(statsResult()).success).toBe(true);
  });

  it("rejects a stats result missing a cache counter (strict cache)", () => {
    const incomplete = statsResult() as { cache: Record<string, unknown> };
    delete incomplete.cache.evictions;
    expect(kernelResultSchema.safeParse(incomplete).success).toBe(false);
  });

  it("rejects a stats result with an extra top-level key (strict)", () => {
    expect(
      kernelResultSchema.safeParse(statsResult({ memory: { rssMb: 100 } }))
        .success,
    ).toBe(false);
  });
});

describe("kernelResultSchema export_mesh (finding-10)", () => {
  function exportBody(
    bodyId: string,
    operationId: string,
    streamSequence: number,
  ): unknown {
    // Export descriptors carry the absolute 0.02 mm tolerance and LOD tier 3,
    // and NO probes/topology — only the operation identity and the packet.
    return {
      bodyId,
      operationId,
      mesh: {
        ...(mesh(streamSequence) as Record<string, unknown>),
        lodTier: 3,
        deflectionMm: 0.02,
        angularDeflectionRad: 0.17453292519943295,
      },
    };
  }

  function exportResult(bodies: unknown[]): unknown {
    return { type: "export_mesh", revision: 1, epoch: 1, bodies };
  }

  it("accepts an export_mesh result with tier-3 probe-free bodies", () => {
    const result = kernelResultSchema.safeParse(
      exportResult([exportBody(idA, opA, 1), exportBody(idB, opB, 2)]),
    );
    expect(result.success).toBe(true);
  });

  it("rejects an export_mesh body that smuggles probes (strict object)", () => {
    const result = kernelResultSchema.safeParse(
      exportResult([
        { ...(exportBody(idA, opA, 1) as object), probes: probes() },
      ]),
    );
    expect(result.success).toBe(false);
  });
});

describe("kernel request document-size envelope", () => {
  function uuidAt(index: number): string {
    return `018f0f5d-0000-7000-8000-${index.toString(16).padStart(12, "0")}`;
  }

  function box(index: number): unknown {
    return {
      id: uuidAt(index),
      type: "create_box",
      schemaVersion: 1,
      name: "Box",
      outputBodyId: uuidAt(500_000 + index),
      parameters: {
        width: 100,
        depth: 60,
        height: 30,
        placement: {
          origin: [0, 0, 0],
          zDirection: [0, 0, 1],
          xDirection: [1, 0, 0],
        },
      },
      metadata: {
        createdAt: "2026-07-13T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    };
  }

  function boxesJustUnder(targetBytes: number): unknown[] {
    const perBox = operationsSerializedByteLength([box(0)]);
    const count = Math.max(1, Math.floor(targetBytes / perBox));
    let operations = Array.from({ length: count }, (_unused, index) =>
      box(index),
    );
    while (
      operations.length > 1 &&
      operationsSerializedByteLength(operations) >= targetBytes
    ) {
      operations = operations.slice(0, -1);
    }
    return operations;
  }

  function boxesJustOver(targetBytes: number): unknown[] {
    const operations = boxesJustUnder(targetBytes);
    while (operationsSerializedByteLength(operations) <= targetBytes) {
      operations.push(box(operations.length));
    }
    return operations;
  }

  function evaluateRequest(operations: unknown[]): unknown {
    return {
      protocolVersion: kernelProtocolVersion,
      requestId: uuidAt(900_001),
      documentId: uuidAt(900_002),
      revision: 1,
      method: "evaluate_document",
      operations,
    };
  }

  it("rejects an evaluate_document request whose operations exceed the envelope", () => {
    const result = kernelRequestSchema.safeParse(
      evaluateRequest(boxesJustOver(maxDocumentOperationsBytes)),
    );
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.message).toMatch(/document-size envelope/);
    }
  });

  it("rejects an export_step request whose operations exceed the envelope", () => {
    const result = kernelRequestSchema.safeParse({
      protocolVersion: kernelProtocolVersion,
      requestId: uuidAt(900_003),
      documentId: uuidAt(900_004),
      revision: 1,
      method: "export_step",
      outputPath: "C:/out/part.step",
      operations: boxesJustOver(maxDocumentOperationsBytes),
    });
    expect(result.success).toBe(false);
  });

  function exportMeshRequest(operations: unknown[]): unknown {
    return {
      protocolVersion: kernelProtocolVersion,
      requestId: uuidAt(900_005),
      documentId: uuidAt(900_006),
      revision: 1,
      method: "export_mesh",
      operations,
    };
  }

  it("accepts an export_mesh request within the envelope (finding-10)", () => {
    const result = kernelRequestSchema.safeParse(
      exportMeshRequest(boxesJustUnder(maxDocumentOperationsBytes)),
    );
    expect(result.success).toBe(true);
  });

  it("rejects an export_mesh request whose operations exceed the envelope", () => {
    const result = kernelRequestSchema.safeParse(
      exportMeshRequest(boxesJustOver(maxDocumentOperationsBytes)),
    );
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.message).toMatch(/document-size envelope/);
    }
  });

  it("accepts operations within the envelope", () => {
    const result = kernelRequestSchema.safeParse(
      evaluateRequest(boxesJustUnder(maxDocumentOperationsBytes)),
    );
    expect(result.success).toBe(true);
  });
});

describe("evaluate_document wire operation schema (N6 slice C)", () => {
  function uuidAt(index: number): string {
    return `018f0f5d-0000-7000-8000-${index.toString(16).padStart(12, "0")}`;
  }

  const boxId = uuidAt(1);
  const filletId = uuidAt(2);
  const extrudeId = uuidAt(3);

  function box(): unknown {
    return {
      id: boxId,
      type: "create_box",
      schemaVersion: 1,
      name: "Box",
      outputBodyId: uuidAt(101),
      parameters: {
        width: 60,
        depth: 40,
        height: 4,
        placement: {
          origin: [0, 0, 0],
          zDirection: [0, 0, 1],
          xDirection: [1, 0, 0],
        },
      },
      metadata: {
        createdAt: "2026-07-13T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    };
  }

  /** edges(op(<box>)).convex().parallel(+z) — the four vertical edges. */
  function edgesAst(): unknown {
    return {
      kind: "edges",
      scope: [{ source: "op", opId: boxId }],
      filters: [
        { name: "convex", args: [] },
        {
          name: "parallel",
          args: [
            { arg: "direction", value: { form: "axis", sign: 1, axis: "z" } },
          ],
        },
      ],
    };
  }

  function filletV2(edges: unknown): unknown {
    return {
      id: filletId,
      type: "fillet",
      schemaVersion: 2,
      name: "Round selected edges",
      outputBodyId: uuidAt(102),
      parameters: {
        targetOperationId: boxId,
        radius: 1.5,
        ...(edges === undefined ? {} : { edges }),
      },
      metadata: {
        createdAt: "2026-07-13T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    };
  }

  function extrudeV2(): unknown {
    return {
      id: extrudeId,
      type: "extrude",
      schemaVersion: 2,
      name: "Extrude selected face",
      outputBodyId: uuidAt(103),
      parameters: {
        faceProfile: {
          ast: {
            kind: "faces",
            scope: [{ source: "op", opId: boxId }],
            filters: [],
          },
          arity: "one",
          anchors: [],
          onEmpty: "error",
        },
        start: { mode: "profilePlane" },
        extent: { mode: "distance", distanceMm: 12 },
        direction: "normal",
        taperAngleDeg: 0,
        boolean: { mode: "newBody" },
      },
      metadata: {
        createdAt: "2026-08-08T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    };
  }

  function evaluateRequest(operations: unknown[]): unknown {
    return {
      protocolVersion: kernelProtocolVersion,
      requestId: uuidAt(900_001),
      documentId: uuidAt(900_002),
      revision: 1,
      method: "evaluate_document",
      operations,
    };
  }

  it("accepts a fillet v2 whose edges slot carries the lowered wire {ast}", () => {
    const result = kernelRequestSchema.safeParse(
      evaluateRequest([
        box(),
        filletV2({
          ast: edgesAst(),
          arity: "one-or-more",
          anchors: [],
          onEmpty: "error",
        }),
      ]),
    );
    expect(result.success).toBe(true);
  });

  it("accepts an Extrude v2 whose face-profile slot carries the lowered wire {ast}", () => {
    const result = kernelRequestSchema.safeParse(
      evaluateRequest([box(), extrudeV2()]),
    );
    expect(result.success).toBe(true);
  });

  it("rejects a fillet v2 whose edges slot still carries a persisted {query} (fail-closed)", () => {
    // A raw persisted query that reached the wire unlowered is a transport bug:
    // the request boundary must refuse it rather than pass it to a kernel that
    // cannot parse strings.
    const result = kernelRequestSchema.safeParse(
      evaluateRequest([
        box(),
        filletV2({
          query: `edges(op(${boxId})).convex().parallel(+z)`,
          arity: "one-or-more",
          anchors: [],
          onEmpty: "error",
        }),
      ]),
    );
    expect(result.success).toBe(false);
  });

  it("accepts a fillet v2 with no edges slot (all-edges v1 behavior) and a slot-free box", () => {
    expect(
      kernelRequestSchema.safeParse(
        evaluateRequest([box(), filletV2(undefined)]),
      ).success,
    ).toBe(true);
  });
});

describe("kernel geometry feasibility diagnostics (Wave 2.4)", () => {
  const operationId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d41";

  function geometryError(details: Record<string, unknown>): unknown {
    return {
      code: "GEOMETRY_FAILED",
      message: "fillet construction failed",
      operationId,
      details,
    };
  }

  it("accepts a conservative radius bound", () => {
    expect(
      kernelErrorSchema.safeParse(
        geometryError({
          requestedRadius: 20,
          maxFeasibleRadius: 4.98,
          feasibilityProbe: {
            parameter: "radius",
            requested: 20,
            maxFeasible: 4.98,
            bound: "tested-lower-bound",
            attempts: 12,
          },
        }),
      ).success,
    ).toBe(true);
  });

  it("accepts a directly substitutable signed offset bound", () => {
    expect(
      kernelErrorSchema.safeParse(
        geometryError({
          requestedDistance: -20,
          maxFeasibleDistance: -4.98,
          feasibilityProbe: {
            parameter: "distance",
            requested: -20,
            maxFeasible: -4.98,
            bound: "tested-lower-bound",
            attempts: 12,
          },
        }),
      ).success,
    ).toBe(true);
  });

  it("accepts a conservative shell thickness bound (catalog wave 1)", () => {
    expect(
      kernelErrorSchema.safeParse(
        geometryError({
          requestedThickness: 15,
          maxFeasibleThickness: 9.84,
          feasibilityProbe: {
            parameter: "thickness",
            requested: 15,
            maxFeasible: 9.84,
            bound: "tested-lower-bound",
            attempts: 10,
          },
        }),
      ).success,
    ).toBe(true);
  });

  it("rejects a thickness bound that does not reduce the failed request", () => {
    expect(
      kernelErrorSchema.safeParse(
        geometryError({
          requestedThickness: 15,
          maxFeasibleThickness: 15,
          feasibilityProbe: {
            parameter: "thickness",
            requested: 15,
            maxFeasible: 15,
            bound: "tested-lower-bound",
            attempts: 1,
          },
        }),
      ).success,
    ).toBe(false);
  });

  it("rejects a thickness alias that disagrees with the probe", () => {
    expect(
      kernelErrorSchema.safeParse(
        geometryError({
          requestedThickness: 15,
          maxFeasibleThickness: 8,
          feasibilityProbe: {
            parameter: "thickness",
            requested: 15,
            maxFeasible: 7,
            bound: "tested-lower-bound",
            attempts: 10,
          },
        }),
      ).success,
    ).toBe(false);
  });

  it("rejects a distance bound that reverses the requested direction", () => {
    expect(
      kernelErrorSchema.safeParse(
        geometryError({
          requestedDistance: -20,
          maxFeasibleDistance: 4.98,
          feasibilityProbe: {
            parameter: "distance",
            requested: -20,
            maxFeasible: 4.98,
            bound: "tested-lower-bound",
            attempts: 12,
          },
        }),
      ).success,
    ).toBe(false);
  });

  it("rejects an untested, non-positive, or over-budget bound", () => {
    for (const feasibilityProbe of [
      {
        parameter: "radius",
        requested: 20,
        maxFeasible: 0,
        bound: "tested-lower-bound",
        attempts: 12,
      },
      {
        parameter: "radius",
        requested: 20,
        maxFeasible: 4,
        bound: "analytic-maximum",
        attempts: 12,
      },
      {
        parameter: "radius",
        requested: 20,
        maxFeasible: 4,
        bound: "tested-lower-bound",
        attempts: 17,
      },
    ]) {
      expect(
        kernelErrorSchema.safeParse(
          geometryError({
            requestedRadius: 20,
            maxFeasibleRadius: feasibilityProbe.maxFeasible,
            feasibilityProbe,
          }),
        ).success,
      ).toBe(false);
    }
  });

  it("rejects a bound that does not reduce the failed magnitude", () => {
    for (const details of [
      {
        requestedRadius: 20,
        maxFeasibleRadius: 20,
        feasibilityProbe: {
          parameter: "radius",
          requested: 20,
          maxFeasible: 20,
          bound: "tested-lower-bound",
          attempts: 1,
        },
      },
      {
        requestedDistance: -20,
        maxFeasibleDistance: -25,
        feasibilityProbe: {
          parameter: "distance",
          requested: -20,
          maxFeasible: -25,
          bound: "tested-lower-bound",
          attempts: 1,
        },
      },
    ]) {
      expect(kernelErrorSchema.safeParse(geometryError(details)).success).toBe(
        false,
      );
    }
  });

  it("rejects aliases that disagree with the probe", () => {
    expect(
      kernelErrorSchema.safeParse(
        geometryError({
          requestedRadius: 20,
          maxFeasibleRadius: 6,
          feasibilityProbe: {
            parameter: "radius",
            requested: 20,
            maxFeasible: 5,
            bound: "tested-lower-bound",
            attempts: 12,
          },
        }),
      ).success,
    ).toBe(false);
  });

  it("preserves legacy GEOMETRY_FAILED errors without a probe", () => {
    expect(
      kernelErrorSchema.safeParse({
        code: "GEOMETRY_FAILED",
        message: "geometry failed",
        operationId,
      }).success,
    ).toBe(true);
  });
});

describe("solve_sketch wire method (CAP-037)", () => {
  const requestId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d60";
  const eid = (suffix: string) => `ent_${suffix.padEnd(26, "0")}`;
  const cid = (suffix: string) => `cst_${suffix.padEnd(26, "0")}`;

  const solveRequest = (overrides: Record<string, unknown> = {}) => ({
    protocolVersion: kernelProtocolVersion,
    requestId,
    method: "solve_sketch",
    entities: [
      {
        eid: eid("A"),
        kind: "line",
        p1: [0, 0],
        p2: [10, 0],
        construction: false,
      },
    ],
    constraints: [
      // A line-like entity is horizontal as a WHOLE: the wire names the entity,
      // not a pair of points. The kernel expands it to the line's endpoints.
      { cid: cid("A"), kind: "horizontal", eid: eid("A") },
    ],
    grounded: [],
    ...overrides,
  });

  it("accepts a constraint system with no document attached", () => {
    // The point of a separate method: solving is NOT a document mutation, so
    // the request carries no documentId, revision, or operations array.
    const parsed = kernelRequestSchema.safeParse(solveRequest());
    expect(parsed.success).toBe(true);
    if (parsed.success) {
      expect("documentId" in parsed.data).toBe(false);
      expect("operations" in parsed.data).toBe(false);
    }
  });

  it("is .strict() — a document field is refused, not ignored", () => {
    // Refusing this is what keeps the two methods from blurring: a caller that
    // means to evaluate a document must say so by choosing that method.
    expect(
      kernelRequestSchema.safeParse(
        solveRequest({ documentId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d61" }),
      ).success,
    ).toBe(false);
  });

  it("refuses an entity id that is not the `ent_` ULID form", () => {
    expect(
      kernelRequestSchema.safeParse(
        solveRequest({
          entities: [{ eid: "line-1", kind: "line", p1: [0, 0], p2: [10, 0] }],
        }),
      ).success,
    ).toBe(false);
  });

  it("carries the solved values and the DoF count on the way back", () => {
    const parsed = kernelResultSchema.safeParse({
      type: "sketch_solution",
      status: "converged",
      solution: {
        entities: [{ eid: eid("A"), values: [0, 0, 10, 0] }],
        degreesOfFreedom: 0,
      },
      conflicting: [],
      redundant: [],
      message: "This sketch is fully constrained.",
    });
    expect(parsed.success).toBe(true);
  });

  it("NAMES conflicting constraints rather than counting them", () => {
    const parsed = kernelResultSchema.safeParse({
      type: "sketch_solution",
      status: "conflicting",
      conflicting: [cid("A"), cid("B")],
      redundant: [],
      message: "These constraints cannot all be satisfied at once.",
    });
    expect(parsed.success).toBe(true);
    if (parsed.success && parsed.data.type === "sketch_solution") {
      // A solver tag integer reaching the wire would mean the kernel leaked
      // PlaneGCS's vocabulary instead of translating to ours.
      for (const name of parsed.data.conflicting) {
        expect(name.startsWith("cst_")).toBe(true);
      }
    }
  });

  it("omits the solution when the status has none to give", () => {
    const parsed = kernelResultSchema.safeParse({
      type: "sketch_solution",
      status: "invalid",
      conflicting: [],
      redundant: [],
      message: "Entity ent_x is missing coordinates.",
    });
    expect(parsed.success).toBe(true);
  });

  it("takes the DEFAULT per-op timeout, not the export budget", () => {
    // Solving is interactive: a person is waiting on it. The 120 s export cap
    // would be the wrong budget, and the native OpTimeoutForMethod twin
    // derives the same answer from the same default.
    expect(kernelOperationTimeoutMs("solve_sketch")).toBe(
      kernelOperationTimeoutMs("evaluate_document"),
    );
  });
});

describe("evaluate_definition request contract (ASM-003)", () => {
  const definitionId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30e01";
  const revisionHash = "rev-0000000000000000000000000001";
  const boxOperationId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30e02";
  const boxOutputBodyId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30e03";

  function boxOperation(): unknown {
    return {
      id: boxOperationId,
      type: "create_box",
      schemaVersion: 1,
      name: "Box",
      outputBodyId: boxOutputBodyId,
      parameters: {
        width: 40,
        depth: 30,
        height: 20,
        placement: {
          origin: [0, 0, 0],
          zDirection: [0, 0, 1],
          xDirection: [1, 0, 0],
        },
      },
      metadata: {
        createdAt: "2026-07-30T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    };
  }

  function evaluateDefinitionRequest(
    overrides: Record<string, unknown> = {},
  ): unknown {
    return {
      protocolVersion: kernelProtocolVersion,
      requestId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30e04",
      method: "evaluate_definition",
      definitionId,
      revisionHash,
      operations: [boxOperation()],
      ...overrides,
    };
  }

  it("parses a minimal valid evaluate_definition request", () => {
    expect(
      kernelRequestSchema.safeParse(evaluateDefinitionRequest()).success,
    ).toBe(true);
  });

  it("rejects a request missing definitionId", () => {
    const request = evaluateDefinitionRequest() as Record<string, unknown>;
    delete request.definitionId;
    expect(kernelRequestSchema.safeParse(request).success).toBe(false);
  });

  it("rejects a request missing revisionHash", () => {
    const request = evaluateDefinitionRequest() as Record<string, unknown>;
    delete request.revisionHash;
    expect(kernelRequestSchema.safeParse(request).success).toBe(false);
  });

  it("rejects a request with an empty-string revisionHash", () => {
    expect(
      kernelRequestSchema.safeParse(
        evaluateDefinitionRequest({ revisionHash: "" }),
      ).success,
    ).toBe(false);
  });
});

describe("evaluate_definition document-size envelope (ASM-003)", () => {
  // Mirrors the `boxesJustUnder`/`boxesJustOver`/`uuidAt` helper pattern from
  // the "kernel request document-size envelope" describe above (each describe
  // in this file keeps its own local copy rather than sharing one) — applied
  // to the new evaluate_definition method, so both sides of the request-level
  // superRefine's byte-envelope branch are proven for it, not just left to the
  // early-return.
  function uuidAt(index: number): string {
    return `018f0f5e-0000-7000-8000-${index.toString(16).padStart(12, "0")}`;
  }

  function box(index: number): unknown {
    return {
      id: uuidAt(index),
      type: "create_box",
      schemaVersion: 1,
      name: "Box",
      outputBodyId: uuidAt(500_000 + index),
      parameters: {
        width: 100,
        depth: 60,
        height: 30,
        placement: {
          origin: [0, 0, 0],
          zDirection: [0, 0, 1],
          xDirection: [1, 0, 0],
        },
      },
      metadata: {
        createdAt: "2026-07-13T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    };
  }

  function boxesJustUnder(targetBytes: number): unknown[] {
    const perBox = operationsSerializedByteLength([box(0)]);
    const count = Math.max(1, Math.floor(targetBytes / perBox));
    let operations = Array.from({ length: count }, (_unused, index) =>
      box(index),
    );
    while (
      operations.length > 1 &&
      operationsSerializedByteLength(operations) >= targetBytes
    ) {
      operations = operations.slice(0, -1);
    }
    return operations;
  }

  function boxesJustOver(targetBytes: number): unknown[] {
    const operations = boxesJustUnder(targetBytes);
    while (operationsSerializedByteLength(operations) <= targetBytes) {
      operations.push(box(operations.length));
    }
    return operations;
  }

  function evaluateDefinitionRequest(operations: unknown[]): unknown {
    return {
      protocolVersion: kernelProtocolVersion,
      requestId: uuidAt(900_001),
      method: "evaluate_definition",
      definitionId: uuidAt(900_002),
      revisionHash: "rev-envelope-0000000000000001",
      operations,
    };
  }

  it("accepts an evaluate_definition request within the envelope", () => {
    const result = kernelRequestSchema.safeParse(
      evaluateDefinitionRequest(boxesJustUnder(maxDocumentOperationsBytes)),
    );
    expect(result.success).toBe(true);
  });

  it("rejects an evaluate_definition request whose operations exceed the envelope", () => {
    const result = kernelRequestSchema.safeParse(
      evaluateDefinitionRequest(boxesJustOver(maxDocumentOperationsBytes)),
    );
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.message).toMatch(/document-size envelope/);
    }
  });
});

describe("definition_evaluation result contract (ASM-003)", () => {
  const definitionId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30e01";
  const revisionHash = "rev-0000000000000000000000000001";
  const bodyIdA = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30e10";
  const bodyIdB = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30e11";
  const opIdA = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30e20";
  const opIdB = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30e21";

  function definitionBody(
    definitionBodyId: string,
    operationId: string,
    streamSequence: number,
    overrides: Record<string, unknown> = {},
  ): unknown {
    return {
      definitionBodyId,
      operationId,
      probes: probes(),
      mesh: mesh(streamSequence),
      collisionShapeCacheKey: `${revisionHash}:${definitionBodyId}`,
      ...overrides,
    };
  }

  function definitionEvaluation(bodies: unknown[]): unknown {
    return {
      type: "definition_evaluation",
      definitionId,
      revisionHash,
      epoch: 1,
      bodies,
    };
  }

  it("round-trips a well-formed single-body result through kernelResultSchema and kernelResponseSchema", () => {
    const result = definitionEvaluation([definitionBody(bodyIdA, opIdA, 1)]);
    expect(kernelResultSchema.safeParse(result).success).toBe(true);

    const response = {
      protocolVersion: kernelProtocolVersion,
      requestId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30e30",
      ok: true,
      result,
    };
    expect(kernelResponseSchema.safeParse(response).success).toBe(true);
  });

  it("accepts distinct definitionBodyId and operationId across bodies", () => {
    const result = kernelResultSchema.safeParse(
      definitionEvaluation([
        definitionBody(bodyIdA, opIdA, 1),
        definitionBody(bodyIdB, opIdB, 2),
      ]),
    );
    expect(result.success).toBe(true);
  });

  it("rejects two bodies sharing the same definitionBodyId (generalized duplicate-id check)", () => {
    const result = kernelResultSchema.safeParse(
      definitionEvaluation([
        definitionBody(bodyIdA, opIdA, 1),
        definitionBody(bodyIdA, opIdB, 2),
      ]),
    );
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(
        result.error.issues.some((issue) => /duplicate/i.test(issue.message)),
      ).toBe(true);
    }
  });

  it("rejects an operationId output-index gap [0, 2] (ADR-013 contiguity, applied to definition_evaluation)", () => {
    const result = kernelResultSchema.safeParse(
      definitionEvaluation([
        definitionBody(bodyIdA, opIdA, 1, { outputIndex: 0 }),
        definitionBody(bodyIdB, opIdA, 2, { outputIndex: 2 }),
      ]),
    );
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(
        result.error.issues.some((issue) =>
          /complete 0\.\.N-1 set/i.test(issue.message),
        ),
      ).toBe(true);
    }
  });

  it("accepts an operationId output-index set [0, 1] for two bodies of the same operation", () => {
    expect(
      kernelResultSchema.safeParse(
        definitionEvaluation([
          definitionBody(bodyIdA, opIdA, 1, { outputIndex: 0 }),
          definitionBody(bodyIdB, opIdA, 2, { outputIndex: 1 }),
        ]),
      ).success,
    ).toBe(true);
  });

  it("rejects a body missing collisionShapeCacheKey", () => {
    const bodyMissingKey = definitionBody(bodyIdA, opIdA, 1) as Record<
      string,
      unknown
    >;
    delete bodyMissingKey.collisionShapeCacheKey;
    expect(
      kernelResultSchema.safeParse(definitionEvaluation([bodyMissingKey]))
        .success,
    ).toBe(false);
  });

  it("rejects a body with an empty-string collisionShapeCacheKey", () => {
    expect(
      kernelResultSchema.safeParse(
        definitionEvaluation([
          definitionBody(bodyIdA, opIdA, 1, { collisionShapeCacheKey: "" }),
        ]),
      ).success,
    ).toBe(false);
  });
});

describe("shared-branch regression guard: evaluate_document / evaluation unaffected (ASM-003/ASM-011)", () => {
  // Cheap proof that extending the request-level byte-envelope superRefine and
  // the result-level duplicate-id/output-index superRefine to cover the new
  // evaluate_definition/definition_evaluation and check_interference/
  // check_clearance branches never touched the pre-existing evaluate_document
  // / evaluation branch they now sit beside. Reuses fixtures already
  // exercised elsewhere in this file rather than inventing new ones.
  it("still parses the existing evaluate_document LOD request identically", () => {
    const request = {
      protocolVersion: kernelProtocolVersion,
      requestId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d21",
      documentId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d22",
      revision: 1,
      method: "evaluate_document",
      operations: [],
    } as const;
    expect(kernelRequestSchema.safeParse(request).success).toBe(true);
  });

  it("still accepts the existing distinct-ids evaluation result", () => {
    const result = kernelResultSchema.safeParse(
      evaluation([body(idA, opA, 1), body(idB, opB, 2)]),
    );
    expect(result.success).toBe(true);
  });
});

describe("check_interference / check_clearance request contract (ASM-011)", () => {
  // ASM-011's check_interference/check_clearance operate on already-resolved
  // OCCURRENCES, not a document operation graph, so an "instance" names a
  // (definitionId, revisionHash, definitionBodyId) triple from the ASM-003
  // definition-evaluation vocabulary plus a world placement. `worldPose`
  // deliberately mirrors `rigidPoseSchema` (assembly-protocol.ts) — the
  // already-established canonical cross-boundary rigid placement shape this
  // package documents as the one every new pose field should reuse — and the
  // plan's own `ViewportOccurrence.worldPose` field name (plan 07 §4.2).
  const instanceIdA = "018f0f5d-7b3a-7cc1-9d22-7a0a96d31a01";
  const instanceIdB = "018f0f5d-7b3a-7cc1-9d22-7a0a96d31a02";
  const definitionId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d31a03";
  const revisionHash = "rev-0000000000000000000000000002";
  const definitionBodyId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d31a04";

  function instance(instanceId: string): unknown {
    return {
      instanceId,
      definitionId,
      revisionHash,
      definitionBodyId,
      worldPose: {
        position: [0, 0, 0],
        rotation: [1, 0, 0, 0, 1, 0, 0, 0, 1],
      },
    };
  }

  function checkRequest(
    method: "check_interference" | "check_clearance",
    overrides: Record<string, unknown> = {},
  ): unknown {
    return {
      protocolVersion: kernelProtocolVersion,
      requestId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d31a10",
      method,
      instances: [instance(instanceIdA), instance(instanceIdB)],
      pairs: { mode: "all" },
      ...overrides,
    };
  }

  for (const method of ["check_interference", "check_clearance"] as const) {
    it(`parses a minimal valid 2-instance ${method} request`, () => {
      expect(kernelRequestSchema.safeParse(checkRequest(method)).success).toBe(
        true,
      );
    });

    it(`rejects a ${method} request carrying an unrecognized top-level key (.strict())`, () => {
      expect(
        kernelRequestSchema.safeParse(
          checkRequest(method, { unexpected: true }),
        ).success,
      ).toBe(false);
    });

    it(`rejects a ${method} instance carrying an unrecognized key (.strict())`, () => {
      const badInstance = {
        ...(instance(instanceIdA) as Record<string, unknown>),
        extra: true,
      };
      expect(
        kernelRequestSchema.safeParse(
          checkRequest(method, {
            instances: [badInstance, instance(instanceIdB)],
          }),
        ).success,
      ).toBe(false);
    });

    it(`rejects a ${method} pairs object carrying an unrecognized key (.strict())`, () => {
      expect(
        kernelRequestSchema.safeParse(
          checkRequest(method, { pairs: { mode: "all", extra: true } }),
        ).success,
      ).toBe(false);
    });

    it(`accepts a ${method} with valid in-bounds pairs.pairs`, () => {
      expect(
        kernelRequestSchema.safeParse(
          checkRequest(method, {
            pairs: { mode: "selected", pairs: [[0, 1]] },
          }),
        ).success,
      ).toBe(true);
    });

    it(`rejects a ${method} pairs.pairs entry >= instances.length`, () => {
      expect(
        kernelRequestSchema.safeParse(
          checkRequest(method, {
            pairs: { mode: "selected", pairs: [[0, 2]] },
          }),
        ).success,
      ).toBe(false);
    });

    it(`accepts a ${method} with valid in-bounds exclusions under "all" mode`, () => {
      expect(
        kernelRequestSchema.safeParse(
          checkRequest(method, {
            pairs: { mode: "all" },
            exclusions: [[0, 1]],
          }),
        ).success,
      ).toBe(true);
    });

    it(`rejects a ${method} exclusions entry >= instances.length`, () => {
      expect(
        kernelRequestSchema.safeParse(
          checkRequest(method, {
            pairs: { mode: "all" },
            exclusions: [[1, 2]],
          }),
        ).success,
      ).toBe(false);
    });

    it(`rejects a ${method} self-pair (a === b) in pairs.pairs`, () => {
      expect(
        kernelRequestSchema.safeParse(
          checkRequest(method, {
            pairs: { mode: "selected", pairs: [[0, 0]] },
          }),
        ).success,
      ).toBe(false);
    });

    it(`rejects a ${method} self-pair (a === b) in exclusions`, () => {
      expect(
        kernelRequestSchema.safeParse(
          checkRequest(method, {
            pairs: { mode: "all" },
            exclusions: [[1, 1]],
          }),
        ).success,
      ).toBe(false);
    });

    it(`rejects ${method} exclusions co-present with pairs.mode "selected"`, () => {
      expect(
        kernelRequestSchema.safeParse(
          checkRequest(method, {
            pairs: { mode: "selected", pairs: [[0, 1]] },
            exclusions: [[0, 1]],
          }),
        ).success,
      ).toBe(false);
    });

    it(`accepts a ${method} budget.timeoutMs exactly at the export-tier boundary`, () => {
      expect(
        kernelRequestSchema.safeParse(
          checkRequest(method, {
            budget: { timeoutMs: kernelExportOperationTimeoutMs },
          }),
        ).success,
      ).toBe(true);
    });

    it(`rejects a ${method} budget.timeoutMs above the export-tier boundary`, () => {
      expect(
        kernelRequestSchema.safeParse(
          checkRequest(method, {
            budget: { timeoutMs: kernelExportOperationTimeoutMs + 1 },
          }),
        ).success,
      ).toBe(false);
    });
  }

  it("pins check_interference/check_clearance to the export-tier op timeout", () => {
    expect(kernelOperationTimeoutMs("check_interference")).toBe(
      kernelExportOperationTimeoutMs,
    );
    expect(kernelOperationTimeoutMs("check_clearance")).toBe(
      kernelExportOperationTimeoutMs,
    );
  });
});

describe("exact native interference request contract", () => {
  it("admits a pair-complete OCCT request and export-tier deadline", () => {
    const bodyA = "018f0f5d-0000-7000-8000-000000000101";
    const bodyB = "018f0f5d-0000-7000-8000-000000000102";
    const operation = {
      id: "018f0f5d-0000-7000-8000-000000000001",
      type: "create_box",
      schemaVersion: 1,
      name: "Box",
      outputBodyId: bodyA,
      parameters: {
        width: 10,
        depth: 10,
        height: 10,
        placement: {
          origin: [0, 0, 0],
          zDirection: [0, 0, 1],
          xDirection: [1, 0, 0],
        },
      },
      metadata: {
        createdAt: "2026-08-01T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    };
    const endpoint = (bodyId: string, occurrenceId: string) => ({
      bodyId,
      occurrencePath: [occurrenceId],
      definitionId: bodyId,
      definitionRevisionHash: "revision-2026-08-01",
    });
    const request = {
      protocolVersion: kernelProtocolVersion,
      requestId: "018f0f5d-0000-7000-8000-000000000099",
      method: "interference_exact",
      operations: [operation, { ...operation, outputBodyId: bodyB }],
      pairs: [
        {
          a: endpoint(bodyA, "018f0f5d-0000-7000-8000-000000000201"),
          b: endpoint(bodyB, "018f0f5d-0000-7000-8000-000000000202"),
        },
      ],
      toleranceMm: 0.000001,
    };
    expect(kernelRequestSchema.safeParse(request).success).toBe(true);
    expect(kernelOperationTimeoutMs("interference_exact")).toBe(
      kernelExportOperationTimeoutMs,
    );
  });

  it("rejects self-pairs and reversed endpoint order", () => {
    const bodyA = "018f0f5d-0000-7000-8000-000000000101";
    const bodyB = "018f0f5d-0000-7000-8000-000000000102";
    const endpoint = (bodyId: string, occurrenceId: string) => ({
      bodyId,
      occurrencePath: [occurrenceId],
      definitionId: bodyId,
      definitionRevisionHash: "revision-2026-08-01",
    });
    const base = {
      protocolVersion: kernelProtocolVersion,
      requestId: "018f0f5d-0000-7000-8000-000000000099",
      method: "interference_exact" as const,
      operations: [
        {
          id: "018f0f5d-0000-7000-8000-000000000001",
          type: "create_box" as const,
          schemaVersion: 1,
          name: "Box",
          outputBodyId: bodyA,
          parameters: {
            width: 10,
            depth: 10,
            height: 10,
            placement: {
              origin: [0, 0, 0] as [number, number, number],
              zDirection: [0, 0, 1] as [number, number, number],
              xDirection: [1, 0, 0] as [number, number, number],
            },
          },
          metadata: {
            createdAt: "2026-08-01T00:00:00.000Z",
            createdBy: { kind: "user" as const },
          },
        },
      ],
      toleranceMm: 0.000001,
    };
    const a = endpoint(bodyA, "018f0f5d-0000-7000-8000-000000000201");
    const b = endpoint(bodyB, "018f0f5d-0000-7000-8000-000000000202");
    expect(
      kernelRequestSchema.safeParse({ ...base, pairs: [{ a, b: a }] }).success,
    ).toBe(false);
    expect(
      kernelRequestSchema.safeParse({ ...base, pairs: [{ a: b, b: a }] })
        .success,
    ).toBe(false);
  });
});

describe("interference_result / clearance_result completeness discipline (ASM-011)", () => {
  // "Timeouts return partial, explicitly incomplete pair sets; they never
  // report clear" (plan 07 §8.3) enforced at the protocol boundary rather
  // than left to convention: completeness !== "complete" REQUIRES a nonempty
  // incompletePairs, "complete" REFUSES one, and evaluatedPairCount must
  // always agree with what `results` actually carries.
  function interferenceResult(
    overrides: Record<string, unknown> = {},
  ): unknown {
    return {
      type: "interference_result",
      completeness: "complete",
      evaluatedPairCount: 1,
      results: [{ pair: [0, 1], status: "separated" }],
      ...overrides,
    };
  }

  function clearanceResult(overrides: Record<string, unknown> = {}): unknown {
    return {
      type: "clearance_result",
      completeness: "complete",
      evaluatedPairCount: 1,
      results: [
        {
          pair: [0, 1],
          status: "separated",
          clearanceMm: 3.2,
          witness: { pointA: [0, 0, 0], pointB: [3.2, 0, 0] },
        },
      ],
      ...overrides,
    };
  }

  type ResultBuilder = readonly [
    string,
    (overrides: Record<string, unknown>) => unknown,
  ];
  const resultBuilders: readonly ResultBuilder[] = [
    ["interference_result", interferenceResult],
    ["clearance_result", clearanceResult],
  ];

  for (const [label, resultOf] of resultBuilders) {
    it(`rejects a ${label} with completeness "partial" and no incompletePairs`, () => {
      expect(
        kernelResultSchema.safeParse(resultOf({ completeness: "partial" }))
          .success,
      ).toBe(false);
    });

    it(`rejects a ${label} with completeness "timeout" and an empty incompletePairs`, () => {
      expect(
        kernelResultSchema.safeParse(
          resultOf({ completeness: "timeout", incompletePairs: [] }),
        ).success,
      ).toBe(false);
    });

    it(`accepts a ${label} with completeness "partial" and a nonempty incompletePairs`, () => {
      expect(
        kernelResultSchema.safeParse(
          resultOf({ completeness: "partial", incompletePairs: [[0, 1]] }),
        ).success,
      ).toBe(true);
    });

    it(`rejects a ${label} with completeness "complete" carrying a nonempty incompletePairs`, () => {
      expect(
        kernelResultSchema.safeParse(
          resultOf({ completeness: "complete", incompletePairs: [[0, 1]] }),
        ).success,
      ).toBe(false);
    });

    it(`rejects a ${label} whose evaluatedPairCount disagrees with results.length`, () => {
      expect(
        kernelResultSchema.safeParse(resultOf({ evaluatedPairCount: 2 }))
          .success,
      ).toBe(false);
    });
  }
});

describe("interference pair-result validation (ASM-011)", () => {
  const pair = [0, 1];

  function result(pairResult: unknown): unknown {
    return {
      type: "interference_result",
      completeness: "complete",
      evaluatedPairCount: 1,
      results: [pairResult],
    };
  }

  it('rejects status "intersecting" with neither overlapVolumeMm3 nor contactAreaMm2', () => {
    expect(
      kernelResultSchema.safeParse(result({ pair, status: "intersecting" }))
        .success,
    ).toBe(false);
  });

  it('accepts status "intersecting" with overlapVolumeMm3', () => {
    expect(
      kernelResultSchema.safeParse(
        result({ pair, status: "intersecting", overlapVolumeMm3: 4.2 }),
      ).success,
    ).toBe(true);
  });

  it('accepts status "intersecting" with contactAreaMm2', () => {
    expect(
      kernelResultSchema.safeParse(
        result({ pair, status: "intersecting", contactAreaMm2: 4.2 }),
      ).success,
    ).toBe(true);
  });

  it('rejects status "failed" without a message', () => {
    expect(
      kernelResultSchema.safeParse(result({ pair, status: "failed" })).success,
    ).toBe(false);
  });

  it('accepts status "failed" with a message', () => {
    expect(
      kernelResultSchema.safeParse(
        result({ pair, status: "failed", message: "kernel timed out" }),
      ).success,
    ).toBe(true);
  });

  it('rejects status "separated" carrying overlapVolumeMm3', () => {
    expect(
      kernelResultSchema.safeParse(
        result({ pair, status: "separated", overlapVolumeMm3: 1 }),
      ).success,
    ).toBe(false);
  });

  it("rejects containment present with a non-intersecting status", () => {
    expect(
      kernelResultSchema.safeParse(
        result({ pair, status: "separated", containment: "a-contains-b" }),
      ).success,
    ).toBe(false);
  });

  it("accepts containment present alongside an intersecting status", () => {
    expect(
      kernelResultSchema.safeParse(
        result({
          pair,
          status: "intersecting",
          overlapVolumeMm3: 4.2,
          containment: "a-contains-b",
        }),
      ).success,
    ).toBe(true);
  });
});

describe("clearance pair-result validation (ASM-011)", () => {
  const pair = [0, 1];

  function result(pairResult: unknown): unknown {
    return {
      type: "clearance_result",
      completeness: "complete",
      evaluatedPairCount: 1,
      results: [pairResult],
    };
  }

  it('rejects status "not-separated" carrying a clearanceMm', () => {
    expect(
      kernelResultSchema.safeParse(
        result({ pair, status: "not-separated", clearanceMm: 0 }),
      ).success,
    ).toBe(false);
  });

  it('accepts status "not-separated" without a clearanceMm', () => {
    expect(
      kernelResultSchema.safeParse(result({ pair, status: "not-separated" }))
        .success,
    ).toBe(true);
  });

  it('rejects status "failed" carrying a clearanceMm', () => {
    expect(
      kernelResultSchema.safeParse(
        result({
          pair,
          status: "failed",
          message: "kernel timed out",
          clearanceMm: 1,
        }),
      ).success,
    ).toBe(false);
  });

  it('rejects status "separated" without clearanceMm and witness', () => {
    expect(
      kernelResultSchema.safeParse(result({ pair, status: "separated" }))
        .success,
    ).toBe(false);
  });

  it('accepts a fully-formed status "separated" result', () => {
    expect(
      kernelResultSchema.safeParse(
        result({
          pair,
          status: "separated",
          clearanceMm: 3.2,
          witness: { pointA: [0, 0, 0], pointB: [3.2, 0, 0] },
        }),
      ).success,
    ).toBe(true);
  });
});

describe("hlr_project section cuts and posed instances", () => {
  // Mirrors the local-fixture convention of this file: each describe keeps
  // its own uuidAt/box helpers rather than sharing one.
  function uuidAt(index: number): string {
    return `018f0f5f-0000-7000-8000-${index.toString(16).padStart(12, "0")}`;
  }

  function box(index: number): unknown {
    return {
      id: uuidAt(index),
      type: "create_box",
      schemaVersion: 1,
      name: "Box",
      outputBodyId: uuidAt(500_000 + index),
      parameters: {
        width: 100,
        depth: 60,
        height: 30,
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

  function instance(index: number, rotationXyzw: readonly number[]): unknown {
    return {
      operations: [box(index)],
      pose: {
        translationMm: [200 * index, 0, 0],
        rotationXyzw,
      },
    };
  }

  function hlrRequest(overrides: Record<string, unknown> = {}): unknown {
    return {
      protocolVersion: kernelProtocolVersion,
      requestId: uuidAt(900_001),
      method: "hlr_project",
      operations: [box(0)],
      direction: [0, 1, 0],
      up: [0, 0, 1],
      ...overrides,
    };
  }

  it("round-trips a request carrying a sectionPlane and posed instances", () => {
    const result = kernelRequestSchema.safeParse(
      hlrRequest({
        sectionPlane: { origin: [50, 30, 15], normal: [0, 1, 0] },
        instances: [
          instance(1, [0, 0, 0, 1]),
          // 90 degrees about Z: quaternion (0, 0, sin 45, cos 45).
          instance(2, [0, 0, Math.SQRT1_2, Math.SQRT1_2]),
        ],
      }),
    );
    expect(result.success).toBe(true);
    if (!result.success || result.data.method !== "hlr_project") return;
    expect(result.data.sectionPlane).toEqual({
      origin: [50, 30, 15],
      normal: [0, 1, 0],
    });
    expect(result.data.instances).toHaveLength(2);
  });

  it("still parses the pre-section request without the new fields", () => {
    const result = kernelRequestSchema.safeParse(hlrRequest());
    expect(result.success).toBe(true);
    if (!result.success) return;
    expect(result.data).not.toHaveProperty("sectionPlane");
    expect(result.data).not.toHaveProperty("instances");
  });

  it("rejects empty operations with no instances (nothing to draw)", () => {
    const result = kernelRequestSchema.safeParse(
      hlrRequest({ operations: [] }),
    );
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.message).toMatch(/posed instance/);
    }
  });

  it("accepts empty operations when instances carry the geometry", () => {
    expect(
      kernelRequestSchema.safeParse(
        hlrRequest({ operations: [], instances: [instance(1, [0, 0, 0, 1])] }),
      ).success,
    ).toBe(true);
  });

  it("rejects an empty instances array (min 1)", () => {
    expect(
      kernelRequestSchema.safeParse(hlrRequest({ instances: [] })).success,
    ).toBe(false);
  });

  it("rejects a sectionPlane carrying an unrecognized key (.strict())", () => {
    expect(
      kernelRequestSchema.safeParse(
        hlrRequest({
          sectionPlane: {
            origin: [50, 30, 15],
            normal: [0, 1, 0],
            offset: 1,
          },
        }),
      ).success,
    ).toBe(false);
  });

  it("rejects a pose missing rotationXyzw or with a 3-tuple rotation", () => {
    expect(
      kernelRequestSchema.safeParse(
        hlrRequest({
          instances: [
            { operations: [box(1)], pose: { translationMm: [0, 0, 0] } },
          ],
        }),
      ).success,
    ).toBe(false);
    expect(
      kernelRequestSchema.safeParse(
        hlrRequest({
          instances: [
            {
              operations: [box(1)],
              pose: { translationMm: [0, 0, 0], rotationXyzw: [0, 0, 1] },
            },
          ],
        }),
      ).success,
    ).toBe(false);
  });

  function hlrResult(overrides: Record<string, unknown> = {}): unknown {
    return {
      type: "hlr_projection",
      segments: [{ visible: true, points: [0, 0, 100, 0] }],
      bounds: { minX: 0, minY: 0, maxX: 100, maxY: 30 },
      bodyCount: 1,
      ...overrides,
    };
  }

  it("round-trips an hlr_projection result carrying sectionOutlines", () => {
    const result = hlrResult({
      // One triangle-sized loop and one empty-section companion case below;
      // the loop is flat x,y pairs with the first point not repeated.
      sectionOutlines: [{ points: [0, 0, 100, 0, 100, 30] }],
    });
    expect(kernelResultSchema.safeParse(result).success).toBe(true);
    const response = {
      protocolVersion: kernelProtocolVersion,
      requestId: uuidAt(900_002),
      ok: true,
      result,
    };
    expect(kernelResponseSchema.safeParse(response).success).toBe(true);
  });

  it("accepts an EMPTY sectionOutlines array (section missed every face)", () => {
    expect(
      kernelResultSchema.safeParse(hlrResult({ sectionOutlines: [] })).success,
    ).toBe(true);
  });

  it("still accepts the pre-section result without sectionOutlines", () => {
    expect(kernelResultSchema.safeParse(hlrResult()).success).toBe(true);
  });

  it("rejects a loop with fewer than three points (min 6 numbers)", () => {
    expect(
      kernelResultSchema.safeParse(
        hlrResult({ sectionOutlines: [{ points: [0, 0, 100, 0] }] }),
      ).success,
    ).toBe(false);
  });
});

describe("interference_result / clearance_result compose into kernelResultSchema (ASM-011)", () => {
  it("round-trips one fully-populated interference_result", () => {
    const result = {
      type: "interference_result",
      completeness: "complete",
      evaluatedPairCount: 2,
      results: [
        { pair: [0, 1], status: "separated" },
        {
          pair: [0, 2],
          status: "intersecting",
          overlapVolumeMm3: 5.1,
          contactAreaMm2: 12.4,
          containment: "a-contains-b",
        },
      ],
    };
    expect(kernelResultSchema.safeParse(result).success).toBe(true);
  });

  it("round-trips one fully-populated clearance_result", () => {
    const result = {
      type: "clearance_result",
      completeness: "partial",
      evaluatedPairCount: 1,
      incompletePairs: [[1, 2]],
      results: [
        {
          pair: [0, 1],
          status: "separated",
          clearanceMm: 2.0,
          witness: { pointA: [0, 0, 0], pointB: [2, 0, 0] },
        },
      ],
    };
    expect(kernelResultSchema.safeParse(result).success).toBe(true);
  });
});
