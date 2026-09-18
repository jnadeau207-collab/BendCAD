import { createHash, randomUUID } from "node:crypto";
import { spawn } from "node:child_process";
import { readFileSync } from "node:fs";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

import {
  kernelProtocolVersion,
  kernelRequestDeadlineMs,
  kernelRequestSchema,
  booleanCombineOperationSchema,
  chamferOperationSchema,
  createBoxOperationSchema,
  createConeOperationSchema,
  createCylinderOperationSchema,
  createProfileOperationSchema,
  createSphereOperationSchema,
  createTorusOperationSchema,
  createWedgeOperationSchema,
  crc32Hex,
  aembSectionIds,
  describeKernelError,
  extrudeOperationSchema,
  filletOperationSchema,
  holeOperationSchema,
  loftOperationSchema,
  offsetOperationSchema,
  operationSchema,
  parseAembPacket,
  revolveOperationSchema,
  sweepOperationSchema,
  transformOperationSchema,
  type BodyTransform,
  type BooleanCombineOperation,
  type ChamferOperation,
  type CreateBoxOperation,
  type CreateCylinderOperation,
  type CreateConeOperation,
  type CreateProfileOperation,
  type CreateSphereOperation,
  type CreateTorusOperation,
  type CreateWedgeOperation,
  type ExtrudeOperation,
  type FilletOperation,
  type HoleOperation,
  type KernelResponse,
  type LoftOperation,
  type OffsetOperation,
  type Operation,
  type RevolveOperation,
  type SweepOperation,
  type TransformOperation,
} from "@aeth/geometry-contracts";
import { afterEach, expect, it } from "vitest";

import { nativeDescribe } from "./native-gate.js";

import {
  KernelRequestQueue,
  KernelSupervisor,
  type BinaryMeshFrame,
} from "../src/index.js";

/** Asserts a kernel response is ok, surfacing the kernel error on failure. */
function expectKernelOk(response: KernelResponse): void {
  expect(
    response.ok,
    response.ok ? "" : `kernel error: ${JSON.stringify(response.error)}`,
  ).toBe(true);
}

const executable = process.env.AETH_KERNEL_HOST_PATH;
const describeNative = nativeDescribe();
const supervisors: KernelSupervisor[] = [];
const occtManifestSha256 = createHash("sha256")
  .update(
    readFileSync(
      new URL(
        "../../../native/third_party/occt.manifest.json",
        import.meta.url,
      ),
    ),
  )
  .digest("hex");
interface GeometryFixture {
  readonly operation: unknown;
  readonly expected: Readonly<{
    volumeMm3: number;
    surfaceAreaMm2: number;
    centerOfMassMm: [number, number, number];
    boundingBoxMm: [number, number, number, number, number, number];
    solidCount: number;
    shellCount: number;
    faceCount: number;
    edgeCount: number;
    vertexCount: number;
    triangleCount?: number;
  }>;
}

/**
 * A consumed-reference document fixture: an ordered operation list (profile
 * then extrude) whose expected probes describe the single extruded body.
 */
interface GeometryDocumentFixture {
  readonly operations: readonly unknown[];
  readonly expected: GeometryFixture["expected"];
}

function loadGeometryFixture(fileName: string): GeometryFixture {
  return JSON.parse(
    readFileSync(
      new URL(`../../../fixtures/geometry/${fileName}`, import.meta.url),
      "utf8",
    ),
  ) as GeometryFixture;
}

function loadDocumentFixture(fileName: string): GeometryDocumentFixture {
  return JSON.parse(
    readFileSync(
      new URL(`../../../fixtures/geometry/${fileName}`, import.meta.url),
      "utf8",
    ),
  ) as GeometryDocumentFixture;
}

const goldenFixture = loadGeometryFixture("box-100x60x30.json");
const cylinderFixture = loadGeometryFixture("cylinder-r25-h80.json");
const sphereFixture = loadGeometryFixture("sphere-r30.json");
const profileExtrudeFixtures = [
  "profile-rect-80x50-extrude-30.json",
  "profile-circle-r20-extrude-h60.json",
  "profile-rounded-rect-80x50-r10-extrude-20.json",
].map((fileName) => [fileName, loadDocumentFixture(fileName)] as const);
const booleanFixtures = [
  "boolean-union-box-cylinder.json",
  "boolean-cut-box-cylinder.json",
  "boolean-intersect.json",
].map((fileName) => [fileName, loadDocumentFixture(fileName)] as const);
const cutBracketFixture = loadDocumentFixture("boolean-cut-box-cylinder.json");
const holeFixtures = [
  "hole-blind-plate-r8-d10.json",
  "hole-through-all-plate-r8.json",
].map((fileName) => [fileName, loadDocumentFixture(fileName)] as const);

function nativeEnvironment(): Record<string, string> {
  const environment: Record<string, string> = {};
  for (const name of [
    "CASROOT",
    "CSF_OCCTResourcePath",
    "LD_LIBRARY_PATH",
    "DYLD_LIBRARY_PATH",
    "PATH",
  ]) {
    const value = process.env[name];
    if (value) environment[name] = value;
  }
  return environment;
}

function hardKill(pid: number): void {
  if (process.platform === "win32") process.kill(pid);
  else process.kill(pid, "SIGKILL");
}

function createBox(
  width = 100,
  depth = 60,
  height = 30,
  origin: [number, number, number] = [0, 0, 0],
): CreateBoxOperation {
  return {
    id: randomUUID() as CreateBoxOperation["id"],
    type: "create_box",
    schemaVersion: 1,
    name: "Native integration box",
    outputBodyId: randomUUID() as CreateBoxOperation["outputBodyId"],
    parameters: {
      width,
      depth,
      height,
      placement: {
        origin,
        zDirection: [0, 0, 1],
        xDirection: [1, 0, 0],
      },
    },
    metadata: {
      createdAt: "2026-07-12T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  };
}

function createCylinder(
  radius: number,
  height: number,
): CreateCylinderOperation {
  return createCylinderOperationSchema.parse({
    id: randomUUID(),
    type: "create_cylinder",
    schemaVersion: 1,
    name: "Native integration cylinder",
    outputBodyId: randomUUID(),
    parameters: {
      radius,
      height,
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
  });
}

function createSphere(radius: number): CreateSphereOperation {
  return createSphereOperationSchema.parse({
    id: randomUUID(),
    type: "create_sphere",
    schemaVersion: 1,
    name: "Native integration sphere",
    outputBodyId: randomUUID(),
    parameters: {
      radius,
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
  });
}

function createProfile(
  shape: CreateProfileOperation["parameters"]["shape"],
): CreateProfileOperation {
  return createProfileOperationSchema.parse({
    id: randomUUID(),
    type: "create_profile",
    schemaVersion: 1,
    name: "Native integration profile",
    outputProfileId: randomUUID(),
    parameters: {
      shape,
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
  });
}

function createCylinderAt(
  radius: number,
  height: number,
  origin: [number, number, number],
): CreateCylinderOperation {
  return createCylinderOperationSchema.parse({
    id: randomUUID(),
    type: "create_cylinder",
    schemaVersion: 1,
    name: "Native integration cylinder",
    outputBodyId: randomUUID(),
    parameters: {
      radius,
      height,
      placement: { origin, zDirection: [0, 0, 1], xDirection: [1, 0, 0] },
    },
    metadata: {
      createdAt: "2026-07-13T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });
}

function createBoolean(
  kind: BooleanCombineOperation["parameters"]["kind"],
  targetOperationId: string,
  toolOperationId: string,
): BooleanCombineOperation {
  return booleanCombineOperationSchema.parse({
    id: randomUUID(),
    type: "boolean_combine",
    schemaVersion: 1,
    name: "Native integration boolean",
    outputBodyId: randomUUID(),
    parameters: { kind, targetOperationId, toolOperationId },
    metadata: {
      createdAt: "2026-07-13T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });
}

function createHole(
  targetOperationId: string,
  radius: number,
  options: {
    readonly depth?: number;
    readonly throughAll?: boolean;
    readonly origin?: [number, number, number];
    /** Drilling axis; the tool cuts along +zDirection from the origin. */
    readonly zDirection?: [number, number, number];
    readonly xDirection?: [number, number, number];
  } = {},
): HoleOperation {
  const {
    depth,
    throughAll = false,
    origin = [0, 0, 0],
    zDirection = [0, 0, -1],
    xDirection = [1, 0, 0],
  } = options;
  return holeOperationSchema.parse({
    id: randomUUID(),
    type: "hole",
    schemaVersion: 1,
    name: "Native integration hole",
    outputBodyId: randomUUID(),
    parameters: {
      targetOperationId,
      placement: { origin, zDirection, xDirection },
      size: { kind: "radius", radius },
      ...(throughAll
        ? { throughAll: true }
        : { depth: depth ?? radius, throughAll: false }),
    },
    metadata: {
      createdAt: "2026-07-13T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });
}

function createExtrude(
  profileOperationId: string,
  distance: number,
): ExtrudeOperation {
  return extrudeOperationSchema.parse({
    id: randomUUID(),
    type: "extrude",
    schemaVersion: 1,
    name: "Native integration extrude",
    outputBodyId: randomUUID(),
    parameters: { profileOperationId, distance, direction: "normal" },
    metadata: {
      createdAt: "2026-07-13T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });
}

function createRevolve(
  profileOperationId: string,
  options: {
    readonly axisOrigin?: [number, number, number];
    readonly axisDirection?: [number, number, number];
    readonly profileAxis?: "left" | "right" | "bottom" | "top";
    readonly angleDegrees?: number;
  } = {},
): RevolveOperation {
  const {
    axisOrigin = [30, 0, 0],
    axisDirection = [0, 1, 0],
    profileAxis,
    angleDegrees = 360,
  } = options;
  const parameters =
    profileAxis === undefined
      ? { profileOperationId, axisOrigin, axisDirection, angleDegrees }
      : { profileOperationId, profileAxis, angleDegrees };
  return revolveOperationSchema.parse({
    id: randomUUID(),
    type: "revolve",
    schemaVersion: 1,
    name: "Native integration revolve",
    outputBodyId: randomUUID(),
    parameters,
    metadata: {
      createdAt: "2026-07-13T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });
}

function createProfileAt(
  shape: CreateProfileOperation["parameters"]["shape"],
  origin: [number, number, number],
): CreateProfileOperation {
  return createProfileOperationSchema.parse({
    id: randomUUID(),
    type: "create_profile",
    schemaVersion: 1,
    name: "Native integration loft section",
    outputProfileId: randomUUID(),
    parameters: {
      shape,
      placement: { origin, zDirection: [0, 0, 1], xDirection: [1, 0, 0] },
    },
    metadata: {
      createdAt: "2026-07-13T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });
}

function createLoft(
  profileOperationIds: readonly string[],
  ruled = false,
): LoftOperation {
  return loftOperationSchema.parse({
    id: randomUUID(),
    type: "loft",
    schemaVersion: 1,
    name: "Native integration loft",
    outputBodyId: randomUUID(),
    parameters: { profileOperationIds, ruled },
    metadata: {
      createdAt: "2026-07-13T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });
}

function createTransform(
  targetOperationId: string,
  transform: BodyTransform,
): TransformOperation {
  return transformOperationSchema.parse({
    id: randomUUID(),
    type: "transform",
    schemaVersion: 1,
    name: "Native integration transform",
    outputBodyId: randomUUID(),
    parameters: { targetOperationId, transform },
    metadata: {
      createdAt: "2026-07-13T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });
}

function createCone(
  radiusBottom: number,
  radiusTop: number,
  height: number,
): CreateConeOperation {
  return createConeOperationSchema.parse({
    id: randomUUID(),
    type: "create_cone",
    schemaVersion: 1,
    name: "Native integration cone",
    outputBodyId: randomUUID(),
    parameters: {
      radiusBottom,
      radiusTop,
      height,
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
  });
}

function createTorus(
  majorRadius: number,
  minorRadius: number,
): CreateTorusOperation {
  return createTorusOperationSchema.parse({
    id: randomUUID(),
    type: "create_torus",
    schemaVersion: 1,
    name: "Native integration torus",
    outputBodyId: randomUUID(),
    parameters: {
      majorRadius,
      minorRadius,
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
  });
}

function createWedge(
  width: number,
  depth: number,
  height: number,
  topWidth: number,
): CreateWedgeOperation {
  return createWedgeOperationSchema.parse({
    id: randomUUID(),
    type: "create_wedge",
    schemaVersion: 1,
    name: "Native integration wedge",
    outputBodyId: randomUUID(),
    parameters: {
      width,
      depth,
      height,
      topWidth,
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
  });
}

function createSweep(
  profileOperationId: string,
  path: readonly [number, number, number][],
): SweepOperation {
  return sweepOperationSchema.parse({
    id: randomUUID(),
    type: "sweep",
    schemaVersion: 1,
    name: "Native integration sweep",
    outputBodyId: randomUUID(),
    parameters: { profileOperationId, path },
    metadata: {
      createdAt: "2026-07-13T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });
}

function createOffset(
  targetOperationId: string,
  distance: number,
): OffsetOperation {
  return offsetOperationSchema.parse({
    id: randomUUID(),
    type: "offset",
    schemaVersion: 1,
    name: "Native integration offset",
    outputBodyId: randomUUID(),
    parameters: { targetOperationId, distance },
    metadata: {
      createdAt: "2026-07-13T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });
}

function createFillet(
  targetOperationId: string,
  radius: number,
): FilletOperation {
  return filletOperationSchema.parse({
    id: randomUUID(),
    type: "fillet",
    schemaVersion: 1,
    name: "Native integration fillet",
    outputBodyId: randomUUID(),
    parameters: { targetOperationId, radius },
    metadata: {
      createdAt: "2026-07-13T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });
}

function createChamfer(
  targetOperationId: string,
  distance: number,
): ChamferOperation {
  return chamferOperationSchema.parse({
    id: randomUUID(),
    type: "chamfer",
    schemaVersion: 1,
    name: "Native integration chamfer",
    outputBodyId: randomUUID(),
    parameters: { targetOperationId, distance },
    metadata: {
      createdAt: "2026-07-13T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });
}

async function startSupervisor(): Promise<KernelSupervisor> {
  if (!executable) throw new Error("AETH_KERNEL_HOST_PATH is not configured");
  const supervisor = new KernelSupervisor({
    executable,
    requestTimeoutMs: 120_000,
    environment: nativeEnvironment(),
  });
  supervisors.push(supervisor);
  const build = await supervisor.start();
  expect(build.occtCommit).toBe("4f95ecaa3b690e34988d42e2ca7fe882e7a8bc7d");
  expect(build.occtManifestSha256).toBe(occtManifestSha256);
  return supervisor;
}

function nextMesh(supervisor: KernelSupervisor): Promise<BinaryMeshFrame> {
  return new Promise((resolve) => supervisor.client.once("mesh", resolve));
}

function collectMeshes(
  supervisor: KernelSupervisor,
  count: number,
): Promise<BinaryMeshFrame[]> {
  return new Promise((resolve) => {
    const frames: BinaryMeshFrame[] = [];
    const onMesh = (frame: BinaryMeshFrame): void => {
      frames.push(frame);
      if (frames.length === count) {
        supervisor.client.off("mesh", onMesh);
        resolve(frames);
      }
    };
    supervisor.client.on("mesh", onMesh);
  });
}

afterEach(() => {
  for (const supervisor of supervisors.splice(0)) supervisor.stop();
});

describeNative("native OCCT boundary", () => {
  it("returns a bounded error instead of terminating when a topology response exceeds the control frame", async () => {
    const supervisor = await startSupervisor();
    const sampleOperation = createBox(1, 1, 1);
    const sample = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [sampleOperation],
        includeTopology: true,
      }),
    );
    expectKernelOk(sample);
    if (!sample.ok || sample.result.type !== "evaluation") return;
    const sampleBody = sample.result.bodies[0];
    if (sampleBody === undefined)
      throw new Error("sample topology body is missing");

    const controlFrameBytes = 4 * 1024 * 1024;
    const bodyBytes = Buffer.byteLength(JSON.stringify(sampleBody), "utf8");
    const bodyCount = Math.min(
      2_000,
      Math.ceil((controlFrameBytes + 64 * 1024) / bodyBytes),
    );
    const operations = Array.from({ length: bodyCount }, (_unused, index) =>
      createBox(1, 1, 1, [index * 2, 0, 0]),
    );
    const oversized = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 2,
        method: "evaluate_document",
        operations,
        includeTopology: true,
      }),
    );

    expect(oversized).toMatchObject({
      ok: false,
      error: {
        code: "INTERNAL_ERROR",
      },
    });
    if (!oversized.ok) {
      expect(oversized.error.message).toMatch(
        /control response exceeds the frame budget/,
      );
    }

    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expectKernelOk(health);
  }, 120_000);

  it("evaluates, tessellates, exports, and reimports a real box", async () => {
    const supervisor = await startSupervisor();
    const operation = createBoxOperationSchema.parse(goldenFixture.operation);
    const expected = goldenFixture.expected;
    const meshPromise = nextMesh(supervisor);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [operation],
      }),
    );
    expect(evaluation.ok).toBe(true);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const body = evaluation.result.bodies[0];
    expect(body?.probes.valid).toBe(true);
    expect(body?.probes.volumeMm3).toBeCloseTo(expected.volumeMm3, 6);
    expect(body?.probes.surfaceAreaMm2).toBeCloseTo(expected.surfaceAreaMm2, 6);
    body?.probes.centerOfMassMm.forEach((component, index) =>
      expect(component).toBeCloseTo(expected.centerOfMassMm[index] ?? 0, 9),
    );
    expect(body?.probes.boundingBoxMm).toEqual(expected.boundingBoxMm);
    expect(body?.probes.solidCount).toBe(expected.solidCount);
    expect(body?.probes.shellCount).toBe(expected.shellCount);
    expect(body?.probes.faceCount).toBe(expected.faceCount);
    expect(body?.probes.edgeCount).toBe(expected.edgeCount);
    expect(body?.probes.vertexCount).toBe(expected.vertexCount);

    const mesh = await meshPromise;
    expect(mesh.streamSequence).toBe(body?.mesh.streamSequence);
    const aemb = parseAembPacket(mesh.packet);
    expect(crc32Hex(mesh.packet)).toBe(body?.mesh.checksumCrc32);
    expect(aemb.faceCount).toBe(expected.faceCount);
    expect(aemb.triangleCount).toBe(expected.triangleCount);
    expect(aemb.edgeCount).toBe(expected.edgeCount);
    expect(aemb.brepVertexCount).toBe(expected.vertexCount);
    const faceSection = aemb.sections.get(aembSectionIds.faceIds);
    const normalSection = aemb.sections.get(aembSectionIds.normals);
    if (!faceSection || !normalSection)
      throw new Error("AEMB ownership sections are missing");
    const faceOwners = new Uint32Array(
      aemb.buffer,
      faceSection.byteOffset,
      aemb.triangleCount,
    );
    expect(new Set(faceOwners).size).toBe(expected.faceCount);
    const normals = new Float32Array(
      aemb.buffer,
      normalSection.byteOffset,
      aemb.vertexCount * 3,
    );
    for (let index = 0; index < normals.length; index += 3) {
      expect(
        Math.hypot(
          normals[index] ?? 0,
          normals[index + 1] ?? 0,
          normals[index + 2] ?? 0,
        ),
      ).toBeCloseTo(1, 5);
    }

    const directory = await mkdtemp(join(tmpdir(), "aeth kernel Æther Parts-"));
    try {
      const stepPath = join(directory, "fixture Ω.step");
      const exported = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 1,
          method: "export_step",
          operations: [operation],
          outputPath: stepPath,
        }),
      );
      expect(exported.ok && exported.result.type === "step_export").toBe(true);
      const inspected = await supervisor.client.request({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        method: "inspect_step",
        inputPath: stepPath,
      });
      expectKernelOk(inspected);
      if (inspected.ok && inspected.result.type === "step_inspection") {
        expect(inspected.result.probes.valid).toBe(true);
        expect(inspected.result.probes.volumeMm3).toBeCloseTo(
          expected.volumeMm3,
          4,
        );
      }
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  });

  it("ingests an exported STEP back into the document as an identical body (D-019)", async () => {
    const supervisor = await startSupervisor();
    const boxOp = createBoxOperationSchema.parse(goldenFixture.operation);
    const expected = goldenFixture.expected;

    const directory = await mkdtemp(join(tmpdir(), "aeth-step-import-"));
    try {
      // 1. Export the box to a real STEP file.
      const stepPath = join(directory, "bracket.step");
      const exported = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 1,
          method: "export_step",
          operations: [boxOp],
          outputPath: stepPath,
        }),
      );
      expectKernelOk(exported);

      // 2. Retain those exact bytes as an import_step operation, the same shape
      //    the desktop import flow builds (source verbatim + its SHA-256 anchor).
      const source = readFileSync(stepPath).toString("utf8");
      const sourceSha256 = createHash("sha256")
        .update(source, "utf8")
        .digest("hex");
      const importOp = operationSchema.parse({
        id: randomUUID(),
        type: "import_step",
        schemaVersion: 1,
        name: "Reimported box",
        outputBodyId: randomUUID(),
        parameters: { source, sourceSha256 },
        metadata: {
          createdAt: "2026-07-21T00:00:00.000Z",
          createdBy: { kind: "import", sourceName: "bracket.step" },
        },
      });

      // 3. Evaluate the import_step document → a REAL body appears, streamed and
      //    probed exactly like a synthesized primitive.
      const meshPromise = nextMesh(supervisor);
      const reimport = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 2,
          method: "evaluate_document",
          operations: [importOp],
        }),
      );
      expectKernelOk(reimport);
      if (!reimport.ok || reimport.result.type !== "evaluation") return;
      // Gate 6 / gate 9: the body, its identity, units, and measures all survive
      // the export -> re-import interchange round trip.
      expect(reimport.result.bodies).toHaveLength(1);
      const body = reimport.result.bodies[0];
      expect(body?.operationId).toBe(importOp.id);
      expect(body?.bodyId).toBe(importOp.outputBodyId);
      expect(body?.probes.valid).toBe(true);
      expect(body?.probes.solidCount).toBe(expected.solidCount);
      expect(body?.probes.volumeMm3).toBeCloseTo(expected.volumeMm3, 4);
      expect(body?.probes.surfaceAreaMm2).toBeCloseTo(
        expected.surfaceAreaMm2,
        4,
      );
      expect(body?.probes.faceCount).toBe(expected.faceCount);
      expect(body?.probes.edgeCount).toBe(expected.edgeCount);
      expect(body?.probes.vertexCount).toBe(expected.vertexCount);
      const mesh = await meshPromise;
      expect(mesh.streamSequence).toBe(body?.mesh.streamSequence);

      // 4. Integrity (gate 9): a source that does not match its recorded hash is
      //    refused, never silently rebuilt into different geometry.
      const tampered = operationSchema.parse({
        ...importOp,
        id: randomUUID(),
        outputBodyId: randomUUID(),
        parameters: {
          source,
          sourceSha256: sourceSha256.replace(/^./, (first) =>
            first === "a" ? "b" : "a",
          ),
        },
      });
      const rejected = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 3,
          method: "evaluate_document",
          operations: [tampered],
        }),
      );
      expect(rejected.ok).toBe(false);
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  });

  /**
   * CAP-011 — the composition that used to be impossible. Any document
   * carrying a selector ref slot evaluates under the naming registry, and both
   * imports refused a naming pass outright, so a person could have imports OR
   * selector-driven features in a document, never both. Measured at the base
   * tip: `import_step` + a fillet with an `edges` ref returned
   * UNSUPPORTED_OPERATION "import_step cannot record element names yet", and so
   * did a bare `query` over the import — recording was refused too.
   *
   * The proof is deliberately the CAP-006 number. That capability measured a
   * 4 mm fillet on ONE 64 mm edge of the NATIVE 90x64x36 box removing
   * (1 - pi/4) * 4^2 * 64 mm3. The same edge of the same box, this time read
   * back from STEP bytes, must lose the same material — a weaker assertion
   * (an operation appended, a body produced) would pass even if the selector
   * had resolved to the wrong edge.
   */
  it("records a selector on an imported body and fillets the recorded edge", async () => {
    const supervisor = await startSupervisor();
    const directory = await mkdtemp(join(tmpdir(), "aeth-import-naming-"));
    try {
      const stepPath = join(directory, "box.step");
      const box = createBox(90, 64, 36);
      const exported = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 1,
          method: "export_step",
          operations: [box],
          outputPath: stepPath,
        }),
      );
      expectKernelOk(exported);

      const source = readFileSync(stepPath).toString("utf8");
      const importOp = operationSchema.parse({
        id: randomUUID(),
        type: "import_step",
        schemaVersion: 1,
        name: "Imported bracket",
        outputBodyId: randomUUID(),
        parameters: {
          source,
          sourceSha256: createHash("sha256")
            .update(source, "utf8")
            .digest("hex"),
        },
        metadata: {
          createdAt: "2026-07-27T00:00:00.000Z",
          createdBy: { kind: "import", sourceName: "bracket.step" },
        },
      });

      // 1. RECORDING: the selection-recording path replays the document with a
      //    fresh registry and asks what is on the imported body. This is the
      //    request the desktop recorder makes at click time.
      const recorded = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 2,
          method: "query",
          operations: [importOp],
          atOperationId: importOp.id,
          ast: {
            kind: "edges",
            scope: [{ source: "body", opId: importOp.id }],
            filters: [],
          },
        }),
      );
      expectKernelOk(recorded);
      if (!recorded.ok || recorded.result.type !== "query") return;
      const edges = recorded.result.entities;
      expect(edges).toHaveLength(12);
      // Flat per-kind roles, because an import has no authored construction
      // frame: a `top`/`wall` role over read-back topology would be a guess.
      for (const edge of edges) {
        expect(edge.token).toMatch(
          new RegExp(`^t:${importOp.id}/imported-edge/\\d+$`),
        );
      }
      const target = edges.find((edge) => edge.length === 64);
      expect(target, "the imported box has a 64 mm edge").toBeDefined();
      if (target === undefined) return;

      // 2. AUTHORING: hand the RECORDED token to the fillet's ref slot verbatim
      //    (the CAP-006 rule — never re-mint a reference from pick data).
      const fillet = {
        id: randomUUID(),
        type: "fillet",
        schemaVersion: 2,
        name: "Round the imported edge",
        outputBodyId: randomUUID(),
        parameters: {
          targetOperationId: importOp.id,
          radius: 4,
          edges: {
            ast: {
              kind: "edges",
              scope: [{ source: "token", token: target.token }],
              filters: [],
            },
            arity: "one",
            anchors: [],
            onEmpty: "error",
          },
        },
        metadata: {
          createdAt: "2026-07-27T00:00:00.000Z",
          createdBy: { kind: "user" },
        },
      };
      const evaluated = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 3,
          method: "evaluate_document",
          operations: [importOp, fillet],
        }),
      );
      expectKernelOk(evaluated);
      if (!evaluated.ok || evaluated.result.type !== "evaluation") return;
      expect(evaluated.result.bodies).toHaveLength(1);
      const body = evaluated.result.bodies[0];
      expect(body?.probes.valid).toBe(true);
      expect(body?.probes.solidCount).toBe(1);
      // Exactly ONE edge was rounded: one new blend face, and the material lost
      // is the CAP-006 figure for a single 64 mm edge (219.75 mm3). Rounding
      // every edge instead would remove ~1432 and land 26 faces here.
      expect(body?.probes.faceCount).toBe(7);
      expect(207360 - (body?.probes.volumeMm3 ?? 0)).toBeCloseTo(219.75, 2);
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  });

  /**
   * CAP-034 — a face-scoped LOCAL OFFSET on an IMPORTED body. This is the
   * second half of the packet's exit criterion, and the freeze review reopened
   * the capability for it: the packaged gate proves a box face, but "then a
   * face on an IMPORTED body" was untested.
   *
   * The number is the assertion, and it separates further here than for any
   * sibling verb. `offsetOperationSchema` v2 reads an ABSENT `face` slot as v1
   * semantics — offset EVERY face — and v1 offset SUCCEEDS, so a dropped
   * reference would return a valid, plausible, WRONG body rather than an error.
   * Moving one 90x64 face of the imported box outward by 5 mm adds exactly
   * 90 x 64 x 5 = 28,800 mm3; the whole-body fallback would have added 133,040.
   */
  it("offsets a recorded FACE of an imported body", async () => {
    const supervisor = await startSupervisor();
    const directory = await mkdtemp(join(tmpdir(), "aeth-offset-import-"));
    try {
      const stepPath = join(directory, "box.step");
      const box = createBox(90, 64, 36);
      expectKernelOk(
        await supervisor.client.request(
          kernelRequestSchema.parse({
            protocolVersion: kernelProtocolVersion,
            requestId: randomUUID(),
            documentId: randomUUID(),
            revision: 1,
            method: "export_step",
            operations: [box],
            outputPath: stepPath,
          }),
        ),
      );

      const source = readFileSync(stepPath).toString("utf8");
      const importOp = operationSchema.parse({
        id: randomUUID(),
        type: "import_step",
        schemaVersion: 1,
        name: "Imported plate",
        outputBodyId: randomUUID(),
        parameters: {
          source,
          sourceSha256: createHash("sha256")
            .update(source, "utf8")
            .digest("hex"),
        },
        metadata: {
          createdAt: "2026-07-27T00:00:00.000Z",
          createdBy: { kind: "import", sourceName: "plate.step" },
        },
      });

      // 1. RECORDING — the recorder's own request, asking what FACES are on the
      //    imported body. Imports mint FLAT per-kind roles (CAP-011): there is
      //    no authored construction frame, so `imported-face` is the honest
      //    role and a `top`/`side` guess would be a lie about a file we did not
      //    build.
      const recorded = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 2,
          method: "query",
          operations: [importOp],
          atOperationId: importOp.id,
          ast: {
            kind: "faces",
            scope: [{ source: "body", opId: importOp.id }],
            filters: [],
          },
        }),
      );
      expectKernelOk(recorded);
      if (!recorded.ok || recorded.result.type !== "query") return;
      const faces = recorded.result.entities;
      expect(faces).toHaveLength(6);
      for (const face of faces) {
        expect(face.token).toMatch(
          new RegExp(`^t:${importOp.id}/imported-face/\\d+$`),
        );
      }
      // The 90 x 64 face — the one whose offset has an unambiguous expected
      // volume, and distinguishable from the 90x36 and 64x36 faces by area.
      const target = faces.find(
        (face) => Math.abs((face.area ?? 0) - 90 * 64) < 1e-6,
      );
      expect(target, "the imported box has a 90x64 face").toBeDefined();
      if (target === undefined) return;

      // 2. AUTHORING — hand the RECORDED token to the face slot verbatim.
      const offset = {
        id: randomUUID(),
        type: "offset",
        schemaVersion: 2,
        name: "Push the imported face",
        outputBodyId: randomUUID(),
        parameters: {
          targetOperationId: importOp.id,
          distance: 5,
          face: {
            ast: {
              kind: "faces",
              scope: [{ source: "token", token: target.token }],
              filters: [],
            },
            arity: "one",
            anchors: [],
            onEmpty: "error",
          },
        },
        metadata: {
          createdAt: "2026-07-27T00:00:00.000Z",
          createdBy: { kind: "user" },
        },
      };
      const evaluated = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 3,
          method: "evaluate_document",
          operations: [importOp, offset],
        }),
      );
      expectKernelOk(evaluated);
      if (!evaluated.ok || evaluated.result.type !== "evaluation") return;
      expect(evaluated.result.bodies).toHaveLength(1);
      const body = evaluated.result.bodies[0];
      expect(body?.probes.valid).toBe(true);
      expect(body?.probes.solidCount).toBe(1);
      // SIX faces still — re-trimmed, not split. The offset moved one face and
      // the neighbours followed; a split would leave more.
      expect(body?.probes.faceCount).toBe(6);
      // Exactly one face moved: 90 x 64 x 5 = 28,800 mm3 added, against the
      // 133,040 a dropped reference (v1 whole-body) would have added.
      expect((body?.probes.volumeMm3 ?? 0) - 207360).toBeCloseTo(28800, 2);
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  });

  /**
   * CAP-012 — an edge-scoped chamfer, in a document that also contains an
   * IMPORT. That combination is the whole point of the dependency on CAP-011:
   * before it, any document carrying a selector ref slot refused outright if an
   * import was present, so "chamfer the edge of a part I imported" was
   * unreachable in principle.
   *
   * The number is the assertion. `chamferOperationSchema` v2 reads an ABSENT
   * `edges` slot as v1 semantics — bevel EVERY edge — so a dropped reference
   * would still produce a plausible body. A symmetric chamfer of distance d on
   * one 90-degree edge of length L removes a right triangular prism:
   * (d^2 / 2) * L. For d = 4 on the imported box's 64 mm edge that is 512 mm3,
   * against ~6000 if all twelve edges had been bevelled.
   */
  it("chamfers a recorded edge of an imported body", async () => {
    const supervisor = await startSupervisor();
    const directory = await mkdtemp(join(tmpdir(), "aeth-chamfer-"));
    try {
      const stepPath = join(directory, "box.step");
      const box = createBox(90, 64, 36);
      expectKernelOk(
        await supervisor.client.request(
          kernelRequestSchema.parse({
            protocolVersion: kernelProtocolVersion,
            requestId: randomUUID(),
            documentId: randomUUID(),
            revision: 1,
            method: "export_step",
            operations: [box],
            outputPath: stepPath,
          }),
        ),
      );
      const source = readFileSync(stepPath).toString("utf8");
      const importOp = operationSchema.parse({
        id: randomUUID(),
        type: "import_step",
        schemaVersion: 1,
        name: "Imported plate",
        outputBodyId: randomUUID(),
        parameters: {
          source,
          sourceSha256: createHash("sha256")
            .update(source, "utf8")
            .digest("hex"),
        },
        metadata: {
          createdAt: "2026-07-27T00:00:00.000Z",
          createdBy: { kind: "import", sourceName: "plate.step" },
        },
      });

      // Record a selector on the import exactly as the desktop recorder does.
      const recorded = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 2,
          method: "query",
          operations: [importOp],
          atOperationId: importOp.id,
          ast: {
            kind: "edges",
            scope: [{ source: "body", opId: importOp.id }],
            filters: [],
          },
        }),
      );
      expectKernelOk(recorded);
      if (!recorded.ok || recorded.result.type !== "query") return;
      const target = recorded.result.entities.find(
        (entity) => entity.length === 64,
      );
      expect(target, "the imported box has a 64 mm edge").toBeDefined();
      if (target === undefined) return;

      const chamfer = {
        id: randomUUID(),
        type: "chamfer",
        schemaVersion: 2,
        name: "Bevel the imported edge",
        outputBodyId: randomUUID(),
        parameters: {
          targetOperationId: importOp.id,
          distance: 4,
          edges: {
            ast: {
              kind: "edges",
              scope: [{ source: "token", token: target.token }],
              filters: [],
            },
            arity: "one",
            anchors: [],
            onEmpty: "error",
          },
        },
        metadata: {
          createdAt: "2026-07-27T00:00:00.000Z",
          createdBy: { kind: "user" },
        },
      };
      const evaluated = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 3,
          method: "evaluate_document",
          operations: [importOp, chamfer],
        }),
      );
      expectKernelOk(evaluated);
      if (!evaluated.ok || evaluated.result.type !== "evaluation") return;
      const body = evaluated.result.bodies[0];
      expect(body?.probes.solidCount).toBe(1);
      // One bevelled edge: one new flat face on the imported box's six.
      expect(body?.probes.faceCount).toBe(7);
      expect(207360 - (body?.probes.volumeMm3 ?? 0)).toBeCloseTo(512, 3);
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  });

  /**
   * The typed-resolution law for the new slot: an `edges` query that matches
   * nothing REFUSES the operation rather than silently falling back to v1
   * all-edges semantics, which is the one outcome the schema makes
   * indistinguishable from success.
   */
  it("refuses a chamfer whose edge selector resolves to nothing", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(40, 30, 20);
    const chamfer = {
      id: randomUUID(),
      type: "chamfer",
      schemaVersion: 2,
      name: "Bevel nothing",
      outputBodyId: randomUUID(),
      parameters: {
        targetOperationId: box.id,
        distance: 2,
        edges: {
          ast: {
            kind: "edges",
            scope: [
              {
                source: "token",
                token: `t:${randomUUID()}/top-edge/0`,
              },
            ],
            filters: [],
          },
          arity: "one",
          anchors: [],
          onEmpty: "error",
        },
      },
      metadata: {
        createdAt: "2026-07-27T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    };
    const evaluated = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, chamfer],
      }),
    );
    expect(evaluated.ok).toBe(false);
    if (evaluated.ok) return;
    expect(evaluated.error.code).toBe("REFERENCE_MISSING");
  });

  it("retessellates a cached B-rep at a new viewport LOD without replaying geometry", async () => {
    if (!executable) throw new Error("AETH_KERNEL_HOST_PATH is not configured");
    const supervisor = new KernelSupervisor({
      executable,
      requestTimeoutMs: 120_000,
      environment: { ...nativeEnvironment(), AETH_REPLAY_CACHE: "1" },
    });
    supervisors.push(supervisor);
    await supervisor.start();

    const operation = createBoxOperationSchema.parse(goldenFixture.operation);
    const documentId = randomUUID();
    const evaluateAt = async (lodTier: 0 | 1 | 2) => {
      const meshPromise = nextMesh(supervisor);
      const response = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId,
          revision: 1,
          method: "evaluate_document",
          operations: [operation],
          lodTier,
        }),
      );
      expectKernelOk(response);
      if (!response.ok || response.result.type !== "evaluation") {
        throw new Error("expected an evaluation response");
      }
      const frame = await meshPromise;
      return {
        descriptor: response.result.bodies[0]?.mesh,
        packet: parseAembPacket(frame.packet),
      };
    };

    const coarse = await evaluateAt(0);
    const fine = await evaluateAt(2);
    expect(coarse.descriptor?.lodTier).toBe(0);
    expect(coarse.packet.lodTier).toBe(0);
    expect(fine.descriptor?.lodTier).toBe(2);
    expect(fine.packet.lodTier).toBe(2);
    expect(fine.packet.deflectionMm).toBeLessThan(coarse.packet.deflectionMm);

    const stats = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "stats",
    });
    expectKernelOk(stats);
    if (!stats.ok || stats.result.type !== "stats") return;
    expect(stats.result.cache.misses).toBe(1);
    expect(stats.result.cache.hits).toBe(1);
    expect(stats.result.cache.snapshotsStored).toBe(1);
  });

  it("answers stats with the replay cache's governor state and build identity", async () => {
    const supervisor = await startSupervisor();
    const stats = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "stats",
    });
    expectKernelOk(stats);
    if (!stats.ok || stats.result.type !== "stats") return;
    const { cache } = stats.result;
    // Default byte budget is 512 MB (plan 06 §9 cacheRamMb). Reuse is off unless
    // AETH_REPLAY_CACHE is set, so a freshly started host reports an inert,
    // empty governor — the wire contract and server wiring are what this pins.
    expect(cache.budgetBytes).toBe(512 * 1024 * 1024);
    expect(cache.entries).toBe(0);
    expect(cache.bytes).toBe(0);
    expect(cache.hits).toBe(0);
    expect(cache.misses).toBe(0);
    expect(cache.evictions).toBe(0);
    expect(cache.snapshotsStored).toBe(0);
    expect(stats.result.uptimeMs).toBeGreaterThanOrEqual(0);
    expect(stats.result.occtCommit).toBe(
      "4f95ecaa3b690e34988d42e2ca7fe882e7a8bc7d",
    );
    expect(stats.result.kernelGeomVersion.length).toBeGreaterThan(0);
  });

  it("returns an attributed TIMEOUT for an operation that exceeds its per-op budget", async () => {
    // A 1 ms per-op cap (AETH_OP_TIMEOUT_MS) is far smaller than any real OCCT
    // boolean, so the watchdog trips and the op's cooperative cancellation check
    // unwinds it into a clean, attributed TIMEOUT (slice 3b) rather than a blunt
    // transport kill. The transport budget stays generous so the kernel's own
    // per-op timeout — not the client deadline — is what fires.
    if (!executable) throw new Error("AETH_KERNEL_HOST_PATH is not configured");
    const supervisor = new KernelSupervisor({
      executable,
      requestTimeoutMs: 120_000,
      environment: { ...nativeEnvironment(), AETH_OP_TIMEOUT_MS: "1" },
    });
    supervisors.push(supervisor);
    await supervisor.start();

    // A box + an all-12-edge fillet: the fillet is a real blend that takes well
    // over 1 ms, so its post-Build cancellation check observes the tripped flag
    // and unwinds — deterministic against a 1 ms cap, unlike a sub-millisecond
    // primitive.
    const box = createBox(60, 60, 60, [0, 0, 0]);
    const fillet = createFillet(box.id, 8);
    const response = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, fillet],
      }),
    );
    expect(response.ok).toBe(false);
    if (response.ok) return;
    expect(response.error.code).toBe("TIMEOUT");
    // Attributed to a document operation, with the budget echoed for the agent.
    expect(response.error.operationId).toBeDefined();
    expect(response.error.details?.timeoutMs).toBe(1);
    expect(describeKernelError(response.error.code).retryable).toBe(true);

    // Containment, not process death (plan 06 §7): the host survives an op
    // timeout, so a follow-up request succeeds on the SAME process.
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("surfaces a per-op TIMEOUT through KernelRequestQueue with the reconciled deadline (finding 2)", async () => {
    // The production composition: submit through the queue, not the bare client.
    // The reconciled per-request deadline (kernelRequestDeadlineMs) is far longer
    // than the tiny per-op cap, so the kernel's cooperative TIMEOUT returns a
    // clean, attributed error THROUGH the queue rather than the queue firing its
    // own submission-deadline kill/restart first. With the pre-fix default 30 s
    // queue deadline vs the 30 s eval / 120 s export op caps, this never surfaced.
    if (!executable) throw new Error("AETH_KERNEL_HOST_PATH is not configured");
    const supervisor = new KernelSupervisor({
      executable,
      requestTimeoutMs: 120_000,
      environment: { ...nativeEnvironment(), AETH_OP_TIMEOUT_MS: "1" },
    });
    supervisors.push(supervisor);
    await supervisor.start();
    const queue = new KernelRequestQueue(supervisor);
    try {
      const box = createBox(60, 60, 60, [0, 0, 0]);
      const fillet = createFillet(box.id, 8);
      const request = kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, fillet],
      });
      const response = await queue.submit(request, {
        deadlineMs: kernelRequestDeadlineMs(request.method),
      });
      expect(response.ok).toBe(false);
      if (response.ok) return;
      // A clean, attributed kernel TIMEOUT — NOT a KernelQueueTimeoutError /
      // KernelRequestTimeoutError, which would have thrown out of submit().
      expect(response.error.code).toBe("TIMEOUT");
      expect(response.error.operationId).toBeDefined();
      expect(response.error.details?.timeoutMs).toBe(1);
    } finally {
      queue.close();
    }
  });

  it("evaluates a multi-body box, cylinder, and sphere document against analytic probes", async () => {
    const supervisor = await startSupervisor();
    const operations: Operation[] = [
      createBoxOperationSchema.parse(goldenFixture.operation),
      createCylinderOperationSchema.parse(cylinderFixture.operation),
      createSphereOperationSchema.parse(sphereFixture.operation),
    ];
    const expectedByBodyId = new Map<string, GeometryFixture["expected"]>(
      [goldenFixture, cylinderFixture, sphereFixture].map((fixture, index) => {
        const operation = operations[index];
        if (!operation) throw new Error("fixture/operation misalignment");
        return [operation.outputBodyId, fixture.expected];
      }),
    );
    const meshesPromise = collectMeshes(supervisor, operations.length);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations,
      }),
    );
    expect(evaluation.ok).toBe(true);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    expect(evaluation.result.bodies).toHaveLength(operations.length);

    const meshes = await meshesPromise;
    const framesBySequence = new Map(
      meshes.map((frame) => [frame.streamSequence, frame]),
    );
    expect(framesBySequence.size).toBe(operations.length);
    const descriptorSequences = new Set(
      evaluation.result.bodies.map((body) => body.mesh.streamSequence),
    );
    expect(descriptorSequences.size).toBe(operations.length);

    for (const body of evaluation.result.bodies) {
      const expected = expectedByBodyId.get(body.bodyId);
      if (!expected) throw new Error(`unexpected body ${body.bodyId}`);
      expect(body.probes.valid).toBe(true);
      expect(body.probes.volumeMm3).toBeCloseTo(expected.volumeMm3, 6);
      expect(body.probes.surfaceAreaMm2).toBeCloseTo(
        expected.surfaceAreaMm2,
        6,
      );
      body.probes.centerOfMassMm.forEach((component, index) =>
        expect(component).toBeCloseTo(expected.centerOfMassMm[index] ?? 0, 9),
      );
      // Curved primitives get near-exact optimal bounds from analytic
      // surfaces; assert per-component closeness instead of bitwise equality.
      body.probes.boundingBoxMm.forEach((component, index) =>
        expect(component).toBeCloseTo(expected.boundingBoxMm[index] ?? 0, 9),
      );
      expect(body.probes.solidCount).toBe(expected.solidCount);
      expect(body.probes.shellCount).toBe(expected.shellCount);
      expect(body.probes.faceCount).toBe(expected.faceCount);
      expect(body.probes.edgeCount).toBe(expected.edgeCount);
      expect(body.probes.vertexCount).toBe(expected.vertexCount);

      const frame = framesBySequence.get(body.mesh.streamSequence);
      if (!frame)
        throw new Error(`missing mesh frame ${body.mesh.streamSequence}`);
      expect(crc32Hex(frame.packet)).toBe(body.mesh.checksumCrc32);
      const aemb = parseAembPacket(frame.packet);
      expect(aemb.triangleCount).toBe(body.mesh.triangleCount);
      expect(aemb.triangleCount).toBeGreaterThan(0);
      expect(aemb.faceCount).toBe(expected.faceCount);
      expect(aemb.edgeCount).toBe(expected.edgeCount);
      expect(aemb.brepVertexCount).toBe(expected.vertexCount);
      const faceSection = aemb.sections.get(aembSectionIds.faceIds);
      if (!faceSection)
        throw new Error("AEMB face-ownership section is missing");
      const faceOwners = new Uint32Array(
        aemb.buffer,
        faceSection.byteOffset,
        aemb.triangleCount,
      );
      // Every B-rep face must own at least one triangle, so the distinct
      // tessellation owners equal the semantic probe faceCount.
      expect(new Set(faceOwners).size).toBe(expected.faceCount);
    }
  });

  it("round-trips the multi-body primitive document through STEP", async () => {
    const supervisor = await startSupervisor();
    const operations: Operation[] = [
      createBoxOperationSchema.parse(goldenFixture.operation),
      createCylinderOperationSchema.parse(cylinderFixture.operation),
      createSphereOperationSchema.parse(sphereFixture.operation),
    ];
    const totalVolume = [goldenFixture, cylinderFixture, sphereFixture].reduce(
      (sum, fixture) => sum + fixture.expected.volumeMm3,
      0,
    );
    const directory = await mkdtemp(join(tmpdir(), "aeth kernel primitives-"));
    try {
      const stepPath = join(directory, "primitives Ω.step");
      const exported = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 1,
          method: "export_step",
          operations,
          outputPath: stepPath,
        }),
      );
      expectKernelOk(exported);
      if (!exported.ok || exported.result.type !== "step_export") return;
      expect(exported.result.bodyCount).toBe(operations.length);
      expect(exported.result.byteLength).toBeGreaterThan(0);
      const inspected = await supervisor.client.request({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        method: "inspect_step",
        inputPath: stepPath,
      });
      expectKernelOk(inspected);
      if (!inspected.ok || inspected.result.type !== "step_inspection") return;
      expect(inspected.result.probes.valid).toBe(true);
      expect(inspected.result.probes.solidCount).toBe(operations.length);
      expect(inspected.result.probes.volumeMm3).toBeCloseTo(totalVolume, 3);
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  });

  it.each(profileExtrudeFixtures)(
    "evaluates the consumed-reference document %s against analytic probes",
    async (_fileName, fixture) => {
      const supervisor = await startSupervisor();
      const operations = fixture.operations.map((operation) =>
        operationSchema.parse(operation),
      );
      const extrude = operations.find(
        (operation) => operation.type === "extrude",
      );
      if (!extrude) throw new Error("fixture is missing its extrude operation");
      const expected = fixture.expected;
      const meshPromise = nextMesh(supervisor);
      const evaluation = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 1,
          method: "evaluate_document",
          operations,
        }),
      );
      expect(evaluation.ok).toBe(true);
      if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
      // Evaluation contract: the profile operation produces no body, so a
      // two-operation profile+extrude document evaluates to exactly one body
      // owned by the extrude operation.
      expect(evaluation.result.bodies).toHaveLength(1);
      const body = evaluation.result.bodies[0];
      if (!body) throw new Error("extruded body is missing");
      expect(body.operationId).toBe(extrude.id);
      expect(body.bodyId).toBe(extrude.outputBodyId);
      expect(body.probes.valid).toBe(true);
      expect(body.probes.volumeMm3).toBeCloseTo(expected.volumeMm3, 6);
      expect(body.probes.surfaceAreaMm2).toBeCloseTo(
        expected.surfaceAreaMm2,
        6,
      );
      body.probes.centerOfMassMm.forEach((component, index) =>
        expect(component).toBeCloseTo(expected.centerOfMassMm[index] ?? 0, 9),
      );
      body.probes.boundingBoxMm.forEach((component, index) =>
        expect(component).toBeCloseTo(expected.boundingBoxMm[index] ?? 0, 9),
      );
      expect(body.probes.solidCount).toBe(expected.solidCount);
      expect(body.probes.shellCount).toBe(expected.shellCount);
      expect(body.probes.faceCount).toBe(expected.faceCount);
      expect(body.probes.edgeCount).toBe(expected.edgeCount);
      expect(body.probes.vertexCount).toBe(expected.vertexCount);

      const mesh = await meshPromise;
      expect(mesh.streamSequence).toBe(body.mesh.streamSequence);
      expect(crc32Hex(mesh.packet)).toBe(body.mesh.checksumCrc32);
      const aemb = parseAembPacket(mesh.packet);
      expect(aemb.triangleCount).toBe(body.mesh.triangleCount);
      expect(aemb.triangleCount).toBeGreaterThan(0);
      expect(aemb.faceCount).toBe(expected.faceCount);
      expect(aemb.edgeCount).toBe(expected.edgeCount);
      expect(aemb.brepVertexCount).toBe(expected.vertexCount);
      const faceSection = aemb.sections.get(aembSectionIds.faceIds);
      if (!faceSection)
        throw new Error("AEMB face-ownership section is missing");
      const faceOwners = new Uint32Array(
        aemb.buffer,
        faceSection.byteOffset,
        aemb.triangleCount,
      );
      expect(new Set(faceOwners).size).toBe(expected.faceCount);
    },
  );

  it("keeps profiles out of the bodies array and evaluates multi-op documents in document order", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(100, 60, 30);
    const profile = createProfile({ kind: "rectangle", width: 80, depth: 50 });
    const extrude = createExtrude(profile.id, 30);
    const operations: Operation[] = [box, profile, extrude];
    const meshesPromise = collectMeshes(supervisor, 2);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations,
      }),
    );
    expect(evaluation.ok).toBe(true);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    // Three operations, two bodies: the profile is consumed by the extrude
    // and never surfaces as a body. Bodies preserve document order among the
    // body-producing operations.
    expect(evaluation.result.bodies.map((body) => body.operationId)).toEqual([
      box.id,
      extrude.id,
    ]);
    const [boxBody, extrudeBody] = evaluation.result.bodies;
    expect(boxBody?.probes.volumeMm3).toBeCloseTo(180_000, 6);
    expect(extrudeBody?.probes.volumeMm3).toBeCloseTo(120_000, 6);
    const meshes = await meshesPromise;
    expect(new Set(meshes.map((frame) => frame.streamSequence)).size).toBe(2);
  });

  it("treats a dangling profile as a valid document that produces no bodies", async () => {
    const supervisor = await startSupervisor();
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [createProfile({ kind: "circle", radius: 20 })],
      }),
    );
    expect(evaluation.ok).toBe(true);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    expect(evaluation.result.bodies).toHaveLength(0);
  });

  it("fails REFERENCE_MISSING with the consuming operation id when the profile does not exist", async () => {
    const supervisor = await startSupervisor();
    const extrude = createExtrude(randomUUID(), 30);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [extrude],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("REFERENCE_MISSING");
    expect(evaluation.error.operationId).toBe(extrude.id);
    expect(evaluation.error.message).toContain(
      extrude.parameters.profileOperationId,
    );
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("fails REFERENCE_MISSING for wrong-type and forward profile references", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(10, 10, 10);
    const wrongType = createExtrude(box.id, 5);
    const wrongTypeEvaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, wrongType],
      }),
    );
    expect(wrongTypeEvaluation.ok).toBe(false);
    if (!wrongTypeEvaluation.ok) {
      expect(wrongTypeEvaluation.error.code).toBe("REFERENCE_MISSING");
      expect(wrongTypeEvaluation.error.operationId).toBe(wrongType.id);
    }

    const profile = createProfile({ kind: "rectangle", width: 20, depth: 20 });
    const forward = createExtrude(profile.id, 5);
    const forwardEvaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 2,
        method: "evaluate_document",
        operations: [forward, profile],
      }),
    );
    expect(forwardEvaluation.ok).toBe(false);
    if (!forwardEvaluation.ok) {
      expect(forwardEvaluation.error.code).toBe("REFERENCE_MISSING");
      expect(forwardEvaluation.error.operationId).toBe(forward.id);
    }
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("extrudes at the millimetre distance maximum and the corner-radius validity boundary", async () => {
    const supervisor = await startSupervisor();
    const maxDistance = 1_000_000;
    const tallProfile = createProfile({
      kind: "rectangle",
      width: 80,
      depth: 50,
    });
    const boundaryRadius = 24.999;
    const boundaryProfile = createProfile({
      kind: "roundedRectangle",
      width: 80,
      depth: 50,
      cornerRadius: boundaryRadius,
    });
    const tallExtrude = createExtrude(tallProfile.id, maxDistance);
    const boundaryExtrude = createExtrude(boundaryProfile.id, 10);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [
          tallProfile,
          boundaryProfile,
          tallExtrude,
          boundaryExtrude,
        ],
      }),
    );
    expect(evaluation.ok).toBe(true);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    expect(evaluation.result.bodies).toHaveLength(2);
    const [tallBody, boundaryBody] = evaluation.result.bodies;
    if (!tallBody || !boundaryBody)
      throw new Error("boundary evaluation is missing bodies");
    expect(tallBody.probes.valid).toBe(true);
    const tallVolume = 80 * 50 * maxDistance;
    expect(
      Math.abs(tallBody.probes.volumeMm3 - tallVolume) / tallVolume,
    ).toBeLessThan(1e-9);
    expect(boundaryBody.probes.valid).toBe(true);
    const boundaryVolume = (80 * 50 - (4 - Math.PI) * boundaryRadius ** 2) * 10;
    expect(
      Math.abs(boundaryBody.probes.volumeMm3 - boundaryVolume) / boundaryVolume,
    ).toBeLessThan(1e-9);
    // The 0.002 mm straight remnants stay above modeling tolerance, so the
    // boundary solid keeps the full rounded-rectangle topology.
    expect(boundaryBody.probes.faceCount).toBe(10);
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("revolves a profile a full turn into a solid of the analytic (Pappus) volume", async () => {
    const supervisor = await startSupervisor();
    const profile = createProfile({ kind: "rectangle", width: 20, depth: 10 });
    // Axis parallel to Y at x=30, clear of the profile (x in [-10, 10]).
    const revolve = createRevolve(profile.id, {
      axisOrigin: [30, 0, 0],
      axisDirection: [0, 1, 0],
      angleDegrees: 360,
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [profile, revolve],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    // The profile is consumed as input and never surfaces as a body; only the
    // revolve's solid remains, owned by the revolve operation.
    expect(evaluation.result.bodies.map((body) => body.operationId)).toEqual([
      revolve.id,
    ]);
    const [body] = evaluation.result.bodies;
    expect(body?.bodyId).toBe(revolve.outputBodyId);
    expect(body?.probes.solidCount).toBe(1);
    // Pappus's theorem: V = 2π·R_c·A, with centroid radius R_c = 30 (axis at
    // x=30, profile centroid at x=0) and area A = 20·10 = 200 mm².
    const expectedVolume = 2 * Math.PI * 30 * 200;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.999);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.001);
  });

  it("revolves a profile through a partial angle into a proportional wedge", async () => {
    const supervisor = await startSupervisor();
    const profile = createProfile({ kind: "rectangle", width: 20, depth: 10 });
    const revolve = createRevolve(profile.id, {
      axisOrigin: [30, 0, 0],
      axisDirection: [0, 1, 0],
      angleDegrees: 90,
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [profile, revolve],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // A 90° sweep travels a quarter of the full arc: V = (π/2)·R_c·A.
    const expectedVolume = (Math.PI / 2) * 30 * 200;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.999);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.001);
  });

  it("resolves a profile-relative revolve axis from the evaluated profile frame", async () => {
    const supervisor = await startSupervisor();
    const profile = createProfileAt(
      { kind: "rectangle", width: 20, depth: 10 },
      [5, 0, 7],
    );
    const revolve = createRevolve(profile.id, {
      profileAxis: "left",
      angleDegrees: 360,
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [profile, revolve],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // The semantic left axis is tangent to the rectangle at local x=-10;
    // translating the profile frame must not change the analytic volume.
    const expectedVolume = 2 * Math.PI * 10 * 200;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.999);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.001);
  });

  it("fails REFERENCE_MISSING with the revolve's id when its profile does not exist", async () => {
    const supervisor = await startSupervisor();
    const revolve = createRevolve(randomUUID());
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [revolve],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("REFERENCE_MISSING");
    expect(evaluation.error.operationId).toBe(revolve.id);
    expect(evaluation.error.message).toContain(
      revolve.parameters.profileOperationId,
    );
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("fails closed rather than emit an invalid body when the axis crosses the profile", async () => {
    const supervisor = await startSupervisor();
    const profile = createProfile({ kind: "rectangle", width: 20, depth: 10 });
    // Axis through the profile centre: x in [-10, 10] straddles x=0, so a full
    // revolve would sweep material through itself. The kernel must refuse it,
    // never emit a silently invalid solid.
    const revolve = createRevolve(profile.id, {
      axisOrigin: [0, 0, 0],
      axisDirection: [0, 1, 0],
      angleDegrees: 360,
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [profile, revolve],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(["GEOMETRY_FAILED", "INTERNAL_ERROR"]).toContain(
      evaluation.error.code,
    );
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("evaluates a wedge to its analytic trapezoidal volume", async () => {
    const supervisor = await startSupervisor();
    const wedge = createWedge(40, 20, 15, 10);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [wedge],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // Volume = depth * height * (width + topWidth) / 2 = 20 * 15 * 50 / 2.
    const expectedVolume = (20 * 15 * (40 + 10)) / 2;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.999);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.001);
  });

  it("evaluates a ring torus to its analytic volume", async () => {
    const supervisor = await startSupervisor();
    const torus = createTorus(20, 4);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [torus],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // Ring torus volume = 2 * pi^2 * R * r^2 = 2 * pi^2 * 20 * 16.
    const expectedVolume = 2 * Math.PI ** 2 * 20 * 16;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.999);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.001);
  });

  it("evaluates a pointed cone to its analytic volume", async () => {
    const supervisor = await startSupervisor();
    const cone = createCone(10, 0, 30);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [cone],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // Cone volume = (pi*h/3)(r1^2 + r1*r2 + r2^2) = (pi*30/3)*100 = 1000*pi.
    const expectedVolume = ((Math.PI * 30) / 3) * 100;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.999);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.001);
  });

  it("evaluates a truncated cone (frustum) to its analytic volume", async () => {
    const supervisor = await startSupervisor();
    const cone = createCone(10, 5, 20);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [cone],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // (pi*20/3)(100 + 50 + 25) = (20*pi/3)*175.
    const expectedVolume = ((Math.PI * 20) / 3) * (100 + 50 + 25);
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.999);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.001);
  });

  it("translates a body: volume is preserved and the centroid shifts", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(20, 20, 20);
    const moved = createTransform(box.id, {
      kind: "translate",
      offset: [50, 0, 0],
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, moved],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    // The box is consumed; only the transformed body surfaces, owned by it.
    expect(evaluation.result.bodies.map((body) => body.operationId)).toEqual([
      moved.id,
    ]);
    const [body] = evaluation.result.bodies;
    expect(body?.probes.volumeMm3).toBeCloseTo(8000, 3);
    // Base-centered box: centroid was (0,0,10); after +50 in x it is (50,0,10).
    expect(body?.probes.centerOfMassMm[0]).toBeCloseTo(50, 3);
    expect(body?.probes.centerOfMassMm[2]).toBeCloseTo(10, 3);
  });

  it("rotates a body about an axis: volume is preserved", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(40, 10, 10);
    const rotated = createTransform(box.id, {
      kind: "rotate",
      axisOrigin: [0, 0, 0],
      axisDirection: [0, 0, 1],
      angleDegrees: 90,
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, rotated],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.volumeMm3).toBeCloseTo(4000, 3);
  });

  it("scales a body: volume grows by the cube of the factor", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(10, 10, 10);
    const scaled = createTransform(box.id, { kind: "scale", factor: 2 });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, scaled],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    // Uniform 2x scale about the origin: 1000 -> 1000 * 2^3 = 8000.
    expect(body?.probes.volumeMm3).toBeCloseTo(8000, 3);
  });

  it("mirrors a body across a plane: volume preserved, centroid reflected, still valid", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(20, 20, 20);
    const mirrored = createTransform(box.id, {
      kind: "mirror",
      planeOrigin: [30, 0, 0],
      planeNormal: [1, 0, 0],
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, mirrored],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    // A valid solid (not inside-out) with preserved volume; the centroid
    // reflects across the plane x=30: x 0 -> 60.
    expect(body?.probes.solidCount).toBe(1);
    expect(body?.probes.volumeMm3).toBeCloseTo(8000, 3);
    expect(body?.probes.centerOfMassMm[0]).toBeCloseTo(60, 3);
    expect(body?.probes.centerOfMassMm[2]).toBeCloseTo(10, 3);
  });

  it("fails REFERENCE_MISSING with the transform's id when its target is missing", async () => {
    const supervisor = await startSupervisor();
    const transform = createTransform(randomUUID(), {
      kind: "translate",
      offset: [1, 0, 0],
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [transform],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("REFERENCE_MISSING");
    expect(evaluation.error.operationId).toBe(transform.id);
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("extrudes a slot profile to its analytic stadium volume", async () => {
    const supervisor = await startSupervisor();
    const profile = createProfile({ kind: "slot", length: 40, width: 10 });
    const extrude = createExtrude(profile.id, 20);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [profile, extrude],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // Stadium area = width*(length-width) + pi*(width/2)^2 = 10*30 + 25*pi.
    const area = 10 * 30 + Math.PI * 25;
    const expectedVolume = area * 20;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.999);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.001);
  });

  it("extrudes a regular hexagon profile to its analytic volume", async () => {
    const supervisor = await startSupervisor();
    const profile = createProfile({
      kind: "polygon",
      sides: 6,
      circumradius: 10,
    });
    const extrude = createExtrude(profile.id, 20);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [profile, extrude],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // Regular-polygon area = (1/2) * n * r^2 * sin(2*pi/n).
    const area = 0.5 * 6 * 100 * Math.sin((2 * Math.PI) / 6);
    const expectedVolume = area * 20;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.999);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.001);
  });

  it("extrudes an ellipse profile to its analytic volume", async () => {
    const supervisor = await startSupervisor();
    const profile = createProfile({ kind: "ellipse", radiusX: 15, radiusY: 8 });
    const extrude = createExtrude(profile.id, 20);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [profile, extrude],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // Ellipse area = pi*rx*ry; volume = pi*15*8*20.
    const expectedVolume = Math.PI * 15 * 8 * 20;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.999);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.001);
  });

  it("fillets every edge of a box into a valid solid with slightly reduced volume", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(20, 20, 20);
    const fillet = createFillet(box.id, 2);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, fillet],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    expect(evaluation.result.bodies.map((body) => body.operationId)).toEqual([
      fillet.id,
    ]);
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // Rounding convex edges removes a little material: below 8000, above ~7000.
    expect(body?.probes.volumeMm3).toBeLessThan(8000);
    expect(body?.probes.volumeMm3).toBeGreaterThan(7000);
  });

  it("chamfers every edge of a box into a valid solid with slightly reduced volume", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(20, 20, 20);
    const chamfer = createChamfer(box.id, 2);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, chamfer],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    expect(body?.probes.volumeMm3).toBeLessThan(8000);
    expect(body?.probes.volumeMm3).toBeGreaterThan(7000);
  });

  it("fails closed when a fillet radius is too large for the body", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(20, 20, 20);
    // r15 exceeds the 10 mm half-extent: opposite-edge fillets would overlap.
    const fillet = createFillet(box.id, 15);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, fillet],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(["GEOMETRY_FAILED", "INTERNAL_ERROR"]).toContain(
      evaluation.error.code,
    );
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("fails REFERENCE_MISSING with the fillet's id when its target is missing", async () => {
    const supervisor = await startSupervisor();
    const fillet = createFillet(randomUUID(), 2);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [fillet],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("REFERENCE_MISSING");
    expect(evaluation.error.operationId).toBe(fillet.id);
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("offsets a sphere outward into a larger sphere of the analytic volume", async () => {
    const supervisor = await startSupervisor();
    const sphere = createSphere(10);
    const offset = createOffset(sphere.id, 5);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [sphere, offset],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    // The sphere is consumed; only the offset body surfaces.
    expect(evaluation.result.bodies.map((body) => body.operationId)).toEqual([
      offset.id,
    ]);
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // Offsetting a sphere r10 by +5 is a sphere r15: (4/3)*pi*15^3.
    const expectedVolume = (4 / 3) * Math.PI * 15 ** 3;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.99);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.01);
  });

  it("offsets a box outward into a larger valid solid", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(20, 20, 20);
    const offset = createOffset(box.id, 2);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, offset],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // Grows past the original 8000; stays under the sharp-corner bound 24^3.
    expect(body?.probes.volumeMm3).toBeGreaterThan(8000);
    expect(body?.probes.volumeMm3).toBeLessThan(24 ** 3);
  });

  it("fails closed when an inset offset collapses the body", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(20, 20, 20);
    // Inset 15 mm on a body only 10 mm thick from center: it collapses.
    const offset = createOffset(box.id, -15);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, offset],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(["GEOMETRY_FAILED", "INTERNAL_ERROR"]).toContain(
      evaluation.error.code,
    );
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("fails REFERENCE_MISSING with the offset's id when its target is missing", async () => {
    const supervisor = await startSupervisor();
    const offset = createOffset(randomUUID(), 2);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [offset],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("REFERENCE_MISSING");
    expect(evaluation.error.operationId).toBe(offset.id);
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("sweeps a profile along a straight path into a prism of the analytic volume", async () => {
    const supervisor = await startSupervisor();
    const profile = createProfile({ kind: "rectangle", width: 20, depth: 10 });
    const sweep = createSweep(profile.id, [
      [0, 0, 0],
      [0, 0, 50],
    ]);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [profile, sweep],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    expect(evaluation.result.bodies.map((body) => body.operationId)).toEqual([
      sweep.id,
    ]);
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // A 20x10 section (area 200) swept 50 along +Z is a prism: volume 10000.
    const expectedVolume = 200 * 50;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.999);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.001);
  });

  it("resolves a profile-normal sweep path from the evaluated profile frame", async () => {
    const supervisor = await startSupervisor();
    const profile = createProfile({ kind: "rectangle", width: 20, depth: 10 });
    const sweep = sweepOperationSchema.parse({
      id: randomUUID(),
      type: "sweep",
      schemaVersion: 1,
      name: "Native profile-normal sweep",
      outputBodyId: randomUUID(),
      parameters: {
        profileOperationId: profile.id,
        profilePath: { kind: "normal", lengthMm: 50 },
      },
      metadata: {
        createdAt: "2026-07-13T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [profile, sweep],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    expect(body?.probes.volumeMm3).toBeGreaterThan(20 * 10 * 50 * 0.999);
    expect(body?.probes.volumeMm3).toBeLessThan(20 * 10 * 50 * 1.001);
  });

  it("sweeps a profile along a bent path into a single valid solid", async () => {
    const supervisor = await startSupervisor();
    const profile = createProfile({ kind: "rectangle", width: 20, depth: 10 });
    // Up 40 along Z, then across 30 along X: an L-shaped swept bar.
    const sweep = createSweep(profile.id, [
      [0, 0, 0],
      [0, 0, 40],
      [30, 0, 40],
    ]);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [profile, sweep],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // Roughly area * total path length (70) with corner effects; bound it
    // generously to confirm it swept the whole path into a plausible solid.
    expect(body?.probes.volumeMm3).toBeGreaterThan(200 * 50);
    expect(body?.probes.volumeMm3).toBeLessThan(200 * 90);
  });

  it("fails REFERENCE_MISSING with the sweep's id when its profile does not exist", async () => {
    const supervisor = await startSupervisor();
    const sweep = createSweep(randomUUID(), [
      [0, 0, 0],
      [0, 0, 50],
    ]);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [sweep],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("REFERENCE_MISSING");
    expect(evaluation.error.operationId).toBe(sweep.id);
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("fails closed on a degenerate sweep path with a zero-length segment", async () => {
    const supervisor = await startSupervisor();
    const profile = createProfile({ kind: "rectangle", width: 20, depth: 10 });
    const sweep = createSweep(profile.id, [
      [0, 0, 0],
      [0, 0, 0],
    ]);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [profile, sweep],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(["INVALID_REQUEST", "GEOMETRY_FAILED", "INTERNAL_ERROR"]).toContain(
      evaluation.error.code,
    );
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("fails INVALID_REQUEST when a sweep section is offset from the spine's first point", async () => {
    const supervisor = await startSupervisor();
    // Profile plane sits at the origin; the spine starts at (10, 0, 0). The
    // documented contract requires the section to sit at the spine's first
    // point — this is enforced, not silently transported, so the mismatch is
    // refused rather than producing a surprising-but-valid solid.
    const profile = createProfile({ kind: "rectangle", width: 20, depth: 10 });
    const sweep = createSweep(profile.id, [
      [10, 0, 0],
      [10, 0, 50],
    ]);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [profile, sweep],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("INVALID_REQUEST");
    expect(evaluation.error.message).toContain("spine's first point");
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("lofts a solid through two identical sections as a straight prism", async () => {
    const supervisor = await startSupervisor();
    const bottom = createProfileAt(
      { kind: "rectangle", width: 20, depth: 10 },
      [0, 0, 0],
    );
    const top = createProfileAt(
      { kind: "rectangle", width: 20, depth: 10 },
      [0, 0, 40],
    );
    const loft = createLoft([bottom.id, top.id]);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [bottom, top, loft],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    // Both profiles are inputs; only the loft body surfaces, owned by the loft.
    expect(evaluation.result.bodies.map((body) => body.operationId)).toEqual([
      loft.id,
    ]);
    const [body] = evaluation.result.bodies;
    expect(body?.bodyId).toBe(loft.outputBodyId);
    expect(body?.probes.solidCount).toBe(1);
    // Identical 20x10 sections 40 apart is a straight prism: 20*10*40.
    const expectedVolume = 20 * 10 * 40;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.999);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.001);
  });

  it("lofts a ruled taper whose volume matches the analytic frustum", async () => {
    const supervisor = await startSupervisor();
    const bottom = createProfileAt(
      { kind: "rectangle", width: 20, depth: 10 },
      [0, 0, 0],
    );
    const top = createProfileAt(
      { kind: "rectangle", width: 10, depth: 5 },
      [0, 0, 30],
    );
    const loft = createLoft([bottom.id, top.id], /*ruled=*/ true);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [bottom, top, loft],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // Linearly-ruled rectangle sections: area(t) = (20-10t)(10-5t), so by
    // Simpson (exact for the quadratic) V = (h/6)(A0 + 4*Amid + A1) with
    // A0=200, Amid=15*7.5=112.5, A1=50, h=30 -> 3500.
    const expectedVolume = 3500;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume * 0.995);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume * 1.005);
  });

  it("fails REFERENCE_MISSING with the loft's id when a section profile is missing", async () => {
    const supervisor = await startSupervisor();
    const bottom = createProfileAt(
      { kind: "rectangle", width: 20, depth: 10 },
      [0, 0, 0],
    );
    const loft = createLoft([bottom.id, randomUUID()]);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [bottom, loft],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("REFERENCE_MISSING");
    expect(evaluation.error.operationId).toBe(loft.id);
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("shares one profile across a loft and an extrude without corrupting either", async () => {
    // A profile read by two features in one evaluation: the loft must own a
    // copy of its section wire, or its through-sections build would corrupt the
    // shared profile and break the extrude that also reads it.
    const supervisor = await startSupervisor();
    const bottom = createProfileAt(
      { kind: "rectangle", width: 20, depth: 10 },
      [0, 0, 0],
    );
    const top = createProfileAt(
      { kind: "rectangle", width: 20, depth: 10 },
      [0, 0, 40],
    );
    const loft = createLoft([bottom.id, top.id]);
    const extrude = createExtrude(bottom.id, 5);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [bottom, top, loft, extrude],
      }),
    );
    expectKernelOk(evaluation);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    expect(evaluation.result.bodies.map((body) => body.operationId)).toEqual([
      loft.id,
      extrude.id,
    ]);
    const [loftBody, extrudeBody] = evaluation.result.bodies;
    expect(loftBody?.probes.volumeMm3).toBeGreaterThan(20 * 10 * 40 * 0.999);
    expect(loftBody?.probes.volumeMm3).toBeLessThan(20 * 10 * 40 * 1.001);
    expect(extrudeBody?.probes.volumeMm3).toBeCloseTo(20 * 10 * 5, 6);
  });

  it("round-trips a primitive + profile + extrude document through STEP", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(100, 60, 30);
    const profile = createProfile({ kind: "circle", radius: 20 });
    const extrude = createExtrude(profile.id, 60);
    const operations: Operation[] = [box, profile, extrude];
    const totalVolume = 180_000 + Math.PI * 20 ** 2 * 60;
    const directory = await mkdtemp(join(tmpdir(), "aeth kernel profiles-"));
    try {
      const stepPath = join(directory, "profile extrude Ω.step");
      const exported = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 1,
          method: "export_step",
          operations,
          outputPath: stepPath,
        }),
      );
      expectKernelOk(exported);
      if (!exported.ok || exported.result.type !== "step_export") return;
      // Only body-producing operations export: the consumed profile is not a
      // STEP solid.
      expect(exported.result.bodyCount).toBe(2);
      expect(exported.result.byteLength).toBeGreaterThan(0);
      const inspected = await supervisor.client.request({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        method: "inspect_step",
        inputPath: stepPath,
      });
      expectKernelOk(inspected);
      if (!inspected.ok || inspected.result.type !== "step_inspection") return;
      expect(inspected.result.probes.valid).toBe(true);
      expect(inspected.result.probes.solidCount).toBe(2);
      expect(inspected.result.probes.volumeMm3).toBeCloseTo(totalVolume, 3);
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  });

  it.each(booleanFixtures)(
    "evaluates the body-consuming boolean document %s against analytic probes",
    async (_fileName, fixture) => {
      const supervisor = await startSupervisor();
      const operations = fixture.operations.map((operation) =>
        operationSchema.parse(operation),
      );
      const boolean = operations.find(
        (operation) => operation.type === "boolean_combine",
      );
      if (!boolean) throw new Error("fixture is missing its boolean operation");
      const expected = fixture.expected;
      const frames: BinaryMeshFrame[] = [];
      const onMesh = (frame: BinaryMeshFrame): void => {
        frames.push(frame);
      };
      supervisor.client.on("mesh", onMesh);
      const evaluation = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 1,
          method: "evaluate_document",
          operations,
        }),
      );
      expect(evaluation.ok).toBe(true);
      if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
      // Body management: the boolean consumed the target and the tool, so a
      // three-operation document evaluates to exactly one body owned by the
      // boolean operation.
      expect(evaluation.result.bodies).toHaveLength(1);
      const body = evaluation.result.bodies[0];
      if (!body) throw new Error("boolean body is missing");
      expect(body.operationId).toBe(boolean.id);
      expect(body.bodyId).toBe(boolean.outputBodyId);
      expect(body.probes.valid).toBe(true);
      expect(body.probes.volumeMm3).toBeCloseTo(expected.volumeMm3, 6);
      expect(body.probes.surfaceAreaMm2).toBeCloseTo(
        expected.surfaceAreaMm2,
        6,
      );
      body.probes.centerOfMassMm.forEach((component, index) =>
        expect(component).toBeCloseTo(expected.centerOfMassMm[index] ?? 0, 9),
      );
      body.probes.boundingBoxMm.forEach((component, index) =>
        expect(component).toBeCloseTo(expected.boundingBoxMm[index] ?? 0, 9),
      );
      expect(body.probes.solidCount).toBe(expected.solidCount);
      expect(body.probes.shellCount).toBe(expected.shellCount);
      expect(body.probes.faceCount).toBe(expected.faceCount);
      expect(body.probes.edgeCount).toBe(expected.edgeCount);
      expect(body.probes.vertexCount).toBe(expected.vertexCount);

      // A health round-trip after the evaluation acts as a barrier: every
      // mesh frame the request produced has been flushed by now. The
      // consumed bodies must have produced NO mesh packets.
      const health = await supervisor.client.request({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        method: "health",
      });
      expect(health.ok).toBe(true);
      supervisor.client.off("mesh", onMesh);
      expect(frames).toHaveLength(1);
      const mesh = frames[0];
      if (!mesh) throw new Error("boolean mesh frame is missing");
      expect(mesh.streamSequence).toBe(body.mesh.streamSequence);
      expect(crc32Hex(mesh.packet)).toBe(body.mesh.checksumCrc32);
      const aemb = parseAembPacket(mesh.packet);
      expect(aemb.triangleCount).toBe(body.mesh.triangleCount);
      expect(aemb.triangleCount).toBeGreaterThan(0);
      expect(aemb.faceCount).toBe(expected.faceCount);
      expect(aemb.edgeCount).toBe(expected.edgeCount);
      expect(aemb.brepVertexCount).toBe(expected.vertexCount);
      const faceSection = aemb.sections.get(aembSectionIds.faceIds);
      if (!faceSection)
        throw new Error("AEMB face-ownership section is missing");
      const faceOwners = new Uint32Array(
        aemb.buffer,
        faceSection.byteOffset,
        aemb.triangleCount,
      );
      expect(new Set(faceOwners).size).toBe(expected.faceCount);
    },
  );

  it.each(holeFixtures)(
    "evaluates the target-consuming hole document %s against analytic probes, with a real cylindrical bore face",
    async (_fileName, fixture) => {
      const supervisor = await startSupervisor();
      const operations = fixture.operations.map((operation) =>
        operationSchema.parse(operation),
      );
      const hole = operations.find((operation) => operation.type === "hole");
      if (!hole) throw new Error("fixture is missing its hole operation");
      const expected = fixture.expected;
      const meshPromise = nextMesh(supervisor);
      const evaluation = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 1,
          method: "evaluate_document",
          operations,
          includeTopology: true,
        }),
      );
      expect(evaluation.ok).toBe(true);
      if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
      // Body management: the hole consumed its target box, so a two-operation
      // document (plate, hole) evaluates to exactly one body owned by the
      // hole operation — the same contract as boolean_combine's target.
      expect(evaluation.result.bodies).toHaveLength(1);
      const body = evaluation.result.bodies[0];
      if (!body) throw new Error("hole body is missing");
      expect(body.operationId).toBe(hole.id);
      expect(body.bodyId).toBe(hole.outputBodyId);
      expect(body.probes.valid).toBe(true);
      // Volume reduced by ~the hole volume: the fixture's expected volume is
      // the analytic plate-minus-bore derivation documented in its own
      // notes, so matching it here proves the cut actually removed material
      // rather than being a silent no-op or removing the wrong amount.
      expect(body.probes.volumeMm3).toBeCloseTo(expected.volumeMm3, 6);
      expect(body.probes.surfaceAreaMm2).toBeCloseTo(
        expected.surfaceAreaMm2,
        6,
      );
      body.probes.centerOfMassMm.forEach((component, index) =>
        expect(component).toBeCloseTo(expected.centerOfMassMm[index] ?? 0, 9),
      );
      body.probes.boundingBoxMm.forEach((component, index) =>
        expect(component).toBeCloseTo(expected.boundingBoxMm[index] ?? 0, 9),
      );
      expect(body.probes.solidCount).toBe(expected.solidCount);
      expect(body.probes.shellCount).toBe(expected.shellCount);
      expect(body.probes.faceCount).toBe(expected.faceCount);
      expect(body.probes.edgeCount).toBe(expected.edgeCount);
      expect(body.probes.vertexCount).toBe(expected.vertexCount);

      // A cylindrical interior face must exist: the hole's bore wall, proving
      // the cut actually bored a round hole rather than, say, producing a
      // differently-shaped notch or leaving the body untouched. This is the
      // real per-fixture OCCT topology, not a re-derivation from parameters.
      const topology = body.topology;
      if (!topology)
        throw new Error("hole body is missing its topology snapshot");
      const cylindricalFaces = topology.entities.filter(
        (entity) =>
          entity.kind === "face" && entity.geometryClass === "cylinder",
      );
      expect(cylindricalFaces.length).toBeGreaterThan(0);

      const mesh = await meshPromise;
      expect(mesh.streamSequence).toBe(body.mesh.streamSequence);
      expect(crc32Hex(mesh.packet)).toBe(body.mesh.checksumCrc32);
      const aemb = parseAembPacket(mesh.packet);
      expect(aemb.triangleCount).toBe(body.mesh.triangleCount);
      expect(aemb.triangleCount).toBeGreaterThan(0);
      expect(aemb.faceCount).toBe(expected.faceCount);
      expect(aemb.edgeCount).toBe(expected.edgeCount);
      expect(aemb.brepVertexCount).toBe(expected.vertexCount);
      const faceSection = aemb.sections.get(aembSectionIds.faceIds);
      if (!faceSection)
        throw new Error("AEMB face-ownership section is missing");
      const faceOwners = new Uint32Array(
        aemb.buffer,
        faceSection.byteOffset,
        aemb.triangleCount,
      );
      expect(new Set(faceOwners).size).toBe(expected.faceCount);
    },
  );

  it("excludes the consumed target from a hole's response while a bystander keeps document order", async () => {
    const supervisor = await startSupervisor();
    const target = createBox(40, 40, 20);
    const bystander = createSphere(10);
    // Blind hole from the top face, well clear of the box's sides.
    const hole = createHole(target.id, 5, { depth: 8, origin: [0, 0, 20] });
    const operations: Operation[] = [target, bystander, hole];
    const meshesPromise = collectMeshes(supervisor, 2);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations,
      }),
    );
    expect(evaluation.ok).toBe(true);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    expect(evaluation.result.bodies.map((body) => body.operationId)).toEqual([
      bystander.id,
      hole.id,
    ]);
    const [sphereBody, holeBody] = evaluation.result.bodies;
    expect(sphereBody?.probes.volumeMm3).toBeCloseTo(
      (4 / 3) * Math.PI * 10 ** 3,
      6,
    );
    expect(holeBody?.probes.volumeMm3).toBeCloseTo(
      40 * 40 * 20 - Math.PI * 5 ** 2 * 8,
      6,
    );
    const meshes = await meshesPromise;
    expect(new Set(meshes.map((frame) => frame.streamSequence))).toEqual(
      new Set(evaluation.result.bodies.map((body) => body.mesh.streamSequence)),
    );
  });

  it("fails REFERENCE_MISSING when a hole references a missing target", async () => {
    const supervisor = await startSupervisor();
    const hole = createHole(randomUUID(), 5, { depth: 5 });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [hole],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("REFERENCE_MISSING");
    expect(evaluation.error.operationId).toBe(hole.id);
    expect(evaluation.error.message).toContain(
      hole.parameters.targetOperationId,
    );
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("fails REFERENCE_MISSING when a hole references an already-consumed body", async () => {
    const supervisor = await startSupervisor();
    const first = createBox(40, 40, 20);
    const second = createBox(20, 20, 20, [0, 0, 20]);
    const union = createBoolean("union", first.id, second.id);
    // Consumed is consumed: `first` was eaten by the union, so a later hole
    // may not reference it even though the operation still exists in the
    // document.
    const reuse = createHole(first.id, 5, { depth: 5 });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [first, second, union, reuse],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("REFERENCE_MISSING");
    expect(evaluation.error.operationId).toBe(reuse.id);
    expect(evaluation.error.message).toContain(first.id);
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("fails GEOMETRY_FAILED when a hole would remove its entire target", async () => {
    const supervisor = await startSupervisor();
    const target = createBox(10, 10, 10);
    // A wildly oversized, fully-through tool drilled from the top face
    // swallows the whole 10x10x10 box.
    const hole = createHole(target.id, 50, {
      throughAll: true,
      origin: [0, 0, 10],
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, hole],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("GEOMETRY_FAILED");
    expect(evaluation.error.message).toContain("hole cut");
    expect(evaluation.error.message).toContain("entire target");
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("rejects a blind hole whose origin is off the target body's surface", async () => {
    const supervisor = await startSupervisor();
    // Box spans x,y in [-20, 20]; an origin at x=100 is nowhere near the
    // surface. The entry-point contract requires the origin to BE the entry
    // point on the body, so this is rejected as an invalid request.
    const target = createBox(40, 40, 20);
    const hole = createHole(target.id, 5, { depth: 8, origin: [100, 0, 20] });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, hole],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("INVALID_REQUEST");
    expect(evaluation.error.message).toContain(
      "must lie on the target body's surface",
    );
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("rejects a through-all hole whose origin misses the target body", async () => {
    const supervisor = await startSupervisor();
    // Through-all still requires a valid entry point: an origin off the body
    // (x=100) has no surface to drill from, regardless of derived depth.
    const target = createBox(40, 40, 20);
    const hole = createHole(target.id, 5, {
      throughAll: true,
      origin: [100, 0, 20],
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, hole],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("INVALID_REQUEST");
    expect(evaluation.error.message).toContain(
      "must lie on the target body's surface",
    );
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("cuts a blind hole from a valid surface entry point", async () => {
    const supervisor = await startSupervisor();
    // Origin dead-centre on the top face (z=20), drilling straight down: the
    // canonical valid entry point. It must succeed and remove exactly the tool
    // volume.
    const target = createBox(40, 40, 20);
    const hole = createHole(target.id, 5, { depth: 8, origin: [0, 0, 20] });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, hole],
      }),
    );
    expect(evaluation.ok).toBe(true);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.volumeMm3).toBeCloseTo(
      40 * 40 * 20 - Math.PI * 5 ** 2 * 8,
      6,
    );
  });

  it("rejects a hole whose origin floats above the surface even though the tool reaches the body", async () => {
    const supervisor = await startSupervisor();
    // Origin 5 mm above the top face (z=25). The overshot tool still reaches
    // down into the box, so a mere intersection test would pass — but the
    // origin is not the entry point, so the entry-point contract rejects it.
    const target = createBox(40, 40, 20);
    const hole = createHole(target.id, 5, { depth: 10, origin: [0, 0, 25] });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, hole],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("INVALID_REQUEST");
    expect(evaluation.error.message).toContain(
      "must lie on the target body's surface",
    );
  });

  it("rejects a hole whose origin sits inside the target solid", async () => {
    const supervisor = await startSupervisor();
    // Origin at z=10 is in the interior of the z in [0, 20] box, not on any
    // face — an entry point cannot be inside the material.
    const target = createBox(40, 40, 20);
    const hole = createHole(target.id, 5, { depth: 5, origin: [0, 0, 10] });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, hole],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("INVALID_REQUEST");
    expect(evaluation.error.message).toContain(
      "must lie on the target body's surface",
    );
  });

  it("rejects a surface origin whose drilling direction points out of the body", async () => {
    const supervisor = await startSupervisor();
    // Origin on the top face but drilling UP (+z), away from the material:
    // ahead is empty space, behind is solid — the inverse of a valid hole.
    const target = createBox(40, 40, 20);
    const hole = createHole(target.id, 5, {
      depth: 8,
      origin: [0, 0, 20],
      zDirection: [0, 0, 1],
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, hole],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("INVALID_REQUEST");
    expect(evaluation.error.message).toContain("must point into the target");
  });

  it("cuts an oblique hole entering the surface at an angle", async () => {
    const supervisor = await startSupervisor();
    // Origin on the top face, drilling down but tilted in x: still enters the
    // material (ahead is solid, behind is empty), so an angled entry is valid.
    const target = createBox(40, 40, 20);
    const hole = createHole(target.id, 4, {
      depth: 8,
      origin: [0, 0, 20],
      zDirection: [0.3, 0, -1],
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, hole],
      }),
    );
    expect(evaluation.ok).toBe(true);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // Some material was removed relative to the intact 40x40x20 box.
    expect(body?.probes.volumeMm3).toBeLessThan(40 * 40 * 20);
    expect(body?.probes.valid).toBe(true);
  });

  it("cuts a through-hole at million-millimetre body scale (local, not bbox-scaled, tolerance)", async () => {
    const supervisor = await startSupervisor();
    // A 1e6 mm cube — the top of the supported dimension range. Its bounding-box
    // diagonal is ~1.7e6 mm, so the former bbox-scaled ON band (~1.7 mm) and
    // probe step (~170 mm) both broke here. Origin dead-centre on the top face
    // (z = 1e6), drilling straight down through the body: the local
    // classification accepts this valid entry at any scale.
    const target = createBox(1_000_000, 1_000_000, 1_000_000);
    const hole = createHole(target.id, 5000, {
      throughAll: true,
      origin: [0, 0, 1_000_000],
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, hole],
      }),
    );
    expect(evaluation.ok).toBe(true);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    expect(body?.probes.valid).toBe(true);
    // Material removed, but the body was not severed into pieces.
    expect(body?.probes.volumeMm3).toBeGreaterThan(0);
    expect(body?.probes.volumeMm3).toBeLessThan(1_000_000 ** 3);
  }, 60_000);

  it("rejects an origin a millimetre above a million-millimetre body's surface", async () => {
    const supervisor = await startSupervisor();
    // The origin sits 1 mm above the top face of a 1e6 mm cube. Under the old
    // bbox-scaled ON band (~1.7 mm at this scale) a point this far off the
    // surface was wrongly accepted as lying on it; the absolute local tolerance
    // (OCCT confusion, ~1e-7 mm) rejects it.
    const target = createBox(1_000_000, 1_000_000, 1_000_000);
    const hole = createHole(target.id, 5000, {
      depth: 10_000,
      origin: [0, 0, 1_000_001],
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, hole],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("INVALID_REQUEST");
    expect(evaluation.error.message).toContain(
      "must lie on the target body's surface",
    );
  }, 60_000);

  it("cuts a through-hole in a million-millimetre-wide thin plate (probe local to the wall)", async () => {
    const supervisor = await startSupervisor();
    // A 1e6 x 1e6 x 5 mm plate: extreme aspect ratio. Its bounding-box diagonal
    // is ~1.4e6 mm, so the old bbox-scaled inward probe (~140 mm) stepped clean
    // through the 5 mm wall and mis-read a valid entry as outside. The local
    // probe is half the wall thickness (2.5 mm), so it stays inside the plate.
    const target = createBox(1_000_000, 1_000_000, 5);
    const hole = createHole(target.id, 1000, {
      throughAll: true,
      origin: [0, 0, 5],
    });
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, hole],
      }),
    );
    expect(evaluation.ok).toBe(true);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [body] = evaluation.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    expect(body?.probes.valid).toBe(true);
    expect(body?.probes.volumeMm3).toBeGreaterThan(0);
    expect(body?.probes.volumeMm3).toBeLessThan(1_000_000 * 1_000_000 * 5);
  }, 60_000);

  it("fails GEOMETRY_FAILED when a boolean cut's tool does not overlap the target", async () => {
    const supervisor = await startSupervisor();
    // Two disjoint boxes: the cut removes nothing and OCCT would return the
    // unchanged target as one valid solid. Consistent with the fail-closed
    // boolean family (disjoint union / non-overlapping intersect both fail), a
    // cut that removes no material is rejected rather than silently a no-op.
    const target = createBox(20, 20, 20);
    const tool = createBox(20, 20, 20, [500, 0, 0]);
    const cut = createBoolean("cut", target.id, tool.id);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, tool, cut],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("GEOMETRY_FAILED");
    expect(evaluation.error.message).toContain("boolean cut");
    expect(evaluation.error.message).toContain("removed no material");
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("excludes consumed bodies from the response while untouched bodies keep their order", async () => {
    const supervisor = await startSupervisor();
    const target = createBox(80, 60, 40);
    const tool = createCylinderAt(15, 60, [0, 0, 20]);
    const bystander = createSphere(10);
    const union = createBoolean("union", target.id, tool.id);
    // Document order: target, tool, bystander, boolean. The consumed target
    // and tool vanish; the survivors keep document order: sphere (op 3)
    // before the boolean's output (op 4).
    const operations: Operation[] = [target, tool, bystander, union];
    const meshesPromise = collectMeshes(supervisor, 2);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations,
      }),
    );
    expect(evaluation.ok).toBe(true);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    expect(evaluation.result.bodies.map((body) => body.operationId)).toEqual([
      bystander.id,
      union.id,
    ]);
    const [sphereBody, unionBody] = evaluation.result.bodies;
    expect(sphereBody?.probes.volumeMm3).toBeCloseTo(
      (4 / 3) * Math.PI * 10 ** 3,
      6,
    );
    expect(unionBody?.probes.volumeMm3).toBeCloseTo(
      80 * 60 * 40 + Math.PI * 15 ** 2 * 40,
      6,
    );
    // Mesh emission follows the visible bodies exactly: one stream sequence
    // per unconsumed body, each matching its descriptor.
    const meshes = await meshesPromise;
    expect(new Set(meshes.map((frame) => frame.streamSequence))).toEqual(
      new Set(evaluation.result.bodies.map((body) => body.mesh.streamSequence)),
    );
  });

  it("chains booleans: a union consumed by a cut in one document", async () => {
    const supervisor = await startSupervisor();
    const block = createBox(80, 60, 40);
    const boss = createCylinderAt(15, 60, [0, 0, 20]);
    const union = createBoolean("union", block.id, boss.id);
    // The drill overshoots the block on both sides and stays clear of the
    // boss (axis distance sqrt(25^2 + 15^2) > 15 + 8).
    const drill = createCylinderAt(8, 50, [25, 15, -5]);
    const cut = createBoolean("cut", union.id, drill.id);
    const operations: Operation[] = [block, boss, union, drill, cut];
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations,
      }),
    );
    expect(evaluation.ok).toBe(true);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    // Five operations, one visible body: the cut owns it; the union's
    // intermediate body was itself consumed.
    expect(evaluation.result.bodies).toHaveLength(1);
    const body = evaluation.result.bodies[0];
    if (!body) throw new Error("chained boolean body is missing");
    expect(body.operationId).toBe(cut.id);
    expect(body.bodyId).toBe(cut.outputBodyId);
    expect(body.probes.valid).toBe(true);
    const unionVolume = 80 * 60 * 40 + Math.PI * 15 ** 2 * 40;
    const drillBore = Math.PI * 8 ** 2 * 40;
    expect(body.probes.volumeMm3).toBeCloseTo(unionVolume - drillBore, 6);
    expect(body.probes.solidCount).toBe(1);
  });

  it("round-trips the cut bracket through STEP with only the surviving body", async () => {
    const supervisor = await startSupervisor();
    const operations = cutBracketFixture.operations.map((operation) =>
      operationSchema.parse(operation),
    );
    const directory = await mkdtemp(join(tmpdir(), "aeth kernel booleans-"));
    try {
      const stepPath = join(directory, "cut bracket Ω.step");
      const exported = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 1,
          method: "export_step",
          operations,
          outputPath: stepPath,
        }),
      );
      expectKernelOk(exported);
      if (!exported.ok || exported.result.type !== "step_export") return;
      // Consumed bodies never export: three operations, one STEP solid.
      expect(exported.result.bodyCount).toBe(1);
      expect(exported.result.byteLength).toBeGreaterThan(0);
      const inspected = await supervisor.client.request({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        method: "inspect_step",
        inputPath: stepPath,
      });
      expectKernelOk(inspected);
      if (!inspected.ok || inspected.result.type !== "step_inspection") return;
      expect(inspected.result.probes.valid).toBe(true);
      expect(inspected.result.probes.solidCount).toBe(1);
      expect(inspected.result.probes.volumeMm3).toBeCloseTo(
        cutBracketFixture.expected.volumeMm3,
        3,
      );
      expect(inspected.result.probes.faceCount).toBe(
        cutBracketFixture.expected.faceCount,
      );
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  });

  it("fails GEOMETRY_FAILED when a cut consumes its entire target", async () => {
    const supervisor = await startSupervisor();
    const target = createBox(20, 20, 20);
    const tool = createBox(100, 100, 100, [0, 0, -40]);
    const cut = createBoolean("cut", target.id, tool.id);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, tool, cut],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("GEOMETRY_FAILED");
    expect(evaluation.error.message).toContain("boolean cut");
    expect(evaluation.error.message).toContain("entire target");
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("fails GEOMETRY_FAILED when intersecting disjoint bodies", async () => {
    const supervisor = await startSupervisor();
    const target = createBox(20, 20, 20);
    const tool = createBox(20, 20, 20, [500, 0, 0]);
    const intersect = createBoolean("intersect", target.id, tool.id);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, tool, intersect],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("GEOMETRY_FAILED");
    expect(evaluation.error.message).toContain("boolean intersect");
    expect(evaluation.error.message).toContain("do not overlap");
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("fails GEOMETRY_FAILED when a union would produce disjoint solids", async () => {
    const supervisor = await startSupervisor();
    const target = createBox(20, 20, 20);
    const tool = createBox(20, 20, 20, [500, 0, 0]);
    const union = createBoolean("union", target.id, tool.id);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [target, tool, union],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("GEOMETRY_FAILED");
    expect(evaluation.error.message).toContain("boolean union");
    expect(evaluation.error.message).toContain("disjoint solids");
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("fails REFERENCE_MISSING when a boolean references an already-consumed body", async () => {
    const supervisor = await startSupervisor();
    // Two overlapping boxes centered on the same origin: the union is a
    // single connected cross-shaped solid.
    const first = createBox(100, 60, 30);
    const second = createBox(60, 100, 30);
    const union = createBoolean("union", first.id, second.id);
    const drill = createCylinderAt(5, 50, [0, 0, -10]);
    // Consumed is consumed: `first` was eaten by the union, so a later
    // boolean may not reference it — even though the operation still exists
    // in the document. There is no DAG reuse of a consumed body.
    const reuse = createBoolean("cut", first.id, drill.id);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [first, second, union, drill, reuse],
      }),
    );
    expect(evaluation.ok).toBe(false);
    if (evaluation.ok) return;
    expect(evaluation.error.code).toBe("REFERENCE_MISSING");
    expect(evaluation.error.operationId).toBe(reuse.id);
    expect(evaluation.error.message).toContain(first.id);
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("fails REFERENCE_MISSING for missing, non-body, and forward boolean references", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(20, 20, 20);

    // Missing: the tool id names no operation at all.
    const missingTool = createBoolean("union", box.id, randomUUID());
    const missingEvaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, missingTool],
      }),
    );
    expect(missingEvaluation.ok).toBe(false);
    if (!missingEvaluation.ok) {
      expect(missingEvaluation.error.code).toBe("REFERENCE_MISSING");
      expect(missingEvaluation.error.operationId).toBe(missingTool.id);
      expect(missingEvaluation.error.message).toContain(
        missingTool.parameters.toolOperationId,
      );
    }

    // Non-body: a profile is not a consumable body.
    const profile = createProfile({ kind: "rectangle", width: 20, depth: 20 });
    const profileTool = createBoolean("cut", box.id, profile.id);
    const nonBodyEvaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 2,
        method: "evaluate_document",
        operations: [box, profile, profileTool],
      }),
    );
    expect(nonBodyEvaluation.ok).toBe(false);
    if (!nonBodyEvaluation.ok) {
      expect(nonBodyEvaluation.error.code).toBe("REFERENCE_MISSING");
      expect(nonBodyEvaluation.error.operationId).toBe(profileTool.id);
    }

    // Forward: the tool body evaluates after the boolean.
    const laterBox = createBox(10, 10, 10);
    const forward = createBoolean("intersect", box.id, laterBox.id);
    const forwardEvaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 3,
        method: "evaluate_document",
        operations: [box, forward, laterBox],
      }),
    );
    expect(forwardEvaluation.ok).toBe(false);
    if (!forwardEvaluation.ok) {
      expect(forwardEvaluation.error.code).toBe("REFERENCE_MISSING");
      expect(forwardEvaluation.error.operationId).toBe(forward.id);
    }
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("evaluates radii at the millimetre schema boundary without degrading", async () => {
    const supervisor = await startSupervisor();
    const maxRadius = 1_000_000;
    const operations: Operation[] = [
      createCylinder(maxRadius, maxRadius),
      createSphere(maxRadius),
    ];
    const meshesPromise = collectMeshes(supervisor, operations.length);
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations,
      }),
    );
    expect(evaluation.ok).toBe(true);
    if (!evaluation.ok || evaluation.result.type !== "evaluation") return;
    const [cylinderBody, sphereBody] = evaluation.result.bodies;
    if (!cylinderBody || !sphereBody)
      throw new Error("boundary evaluation is missing bodies");
    expect(cylinderBody.probes.valid).toBe(true);
    expect(sphereBody.probes.valid).toBe(true);
    const cylinderVolume = Math.PI * maxRadius ** 2 * maxRadius;
    const sphereVolume = (4 / 3) * Math.PI * maxRadius ** 3;
    expect(
      Math.abs(cylinderBody.probes.volumeMm3 - cylinderVolume) / cylinderVolume,
    ).toBeLessThan(1e-9);
    expect(
      Math.abs(sphereBody.probes.volumeMm3 - sphereVolume) / sphereVolume,
    ).toBeLessThan(1e-9);
    const meshes = await meshesPromise;
    expect(new Set(meshes.map((frame) => frame.streamSequence)).size).toBe(
      operations.length,
    );
  });

  it("handles sub-micron radii with valid geometry or a structured failure", async () => {
    const supervisor = await startSupervisor();
    const subMicron = 1e-4;
    const evaluation = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [
          createCylinder(subMicron, subMicron),
          createSphere(subMicron),
        ],
      }),
    );
    if (evaluation.ok) {
      expect(evaluation.result.type).toBe("evaluation");
      if (evaluation.result.type === "evaluation") {
        expect(evaluation.result.bodies).toHaveLength(2);
        for (const body of evaluation.result.bodies) {
          expect(body.probes.valid).toBe(true);
          expect(body.probes.volumeMm3).toBeGreaterThan(0);
        }
      }
    } else {
      expect(["GEOMETRY_FAILED", "INVALID_REQUEST"]).toContain(
        evaluation.error.code,
      );
    }
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("cancels between operations without killing the host", async () => {
    const supervisor = await startSupervisor();
    const targetRequestId = randomUUID();
    const operations = Array.from({ length: 2_000 }, () =>
      createBox(10, 10, 10),
    );
    const evaluation = supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: targetRequestId,
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations,
      }),
    );
    await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "cancel",
      targetRequestId,
    });
    const cancelled = await evaluation;
    expect(cancelled.ok).toBe(false);
    if (!cancelled.ok) expect(cancelled.error.code).toBe("CANCELLED");
    const health = await supervisor.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(health.ok).toBe(true);
  });

  it("restarts after a hard process death and evaluates again", async () => {
    const supervisor = await startSupervisor();
    const originalEpoch = supervisor.epoch;
    const pid = supervisor.client.pid;
    if (!pid) throw new Error("Kernel host has no process id");
    const recovered = new Promise((resolve, reject) => {
      const timeout = setTimeout(
        () => reject(new Error("kernel recovery timed out")),
        10_000,
      );
      supervisor.once("recovered", (build) => {
        clearTimeout(timeout);
        resolve(build);
      });
    });
    hardKill(pid);
    await recovered;
    expect(supervisor.client.pid).not.toBe(pid);
    expect(supervisor.epoch).toBeGreaterThan(originalEpoch);
    const meshPromise = nextMesh(supervisor);
    const response = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 2,
        method: "evaluate_document",
        operations: [createBox(20, 20, 20)],
      }),
    );
    expect(response.ok).toBe(true);
    await meshPromise;
  });

  it("fails closed on garbage request bytes and starts a clean host", async () => {
    if (!executable) throw new Error("AETH_KERNEL_HOST_PATH is not configured");
    const child = spawn(executable, [], {
      env: process.env,
      stdio: ["pipe", "pipe", "pipe", "pipe"],
    });
    const exited = new Promise<number | null>((resolve) =>
      child.once("exit", (code) => resolve(code)),
    );
    child.stdin.write(Buffer.from([0xff, 0xff, 0xff, 0xff]));
    child.stdin.end();
    expect(await exited).not.toBe(0);

    const supervisor = await startSupervisor();
    expect(supervisor.state).toBe("ready");
  });
});

// ---------------------------------------------------------------------------
// Element names through evaluate_document (integration tranche N0).
//
// The lineage-name channel the NG-2 tournament qualified inside mutation_case
// fixtures, now emitted for real document evaluations: one name per
// face/edge/vertex of every returned body, correlated by token with the
// body's topology snapshot. These tests pin the tranche plan's two verify
// criteria (independent-evaluation determinism, survivor congruence under a
// parameter edit) plus the offset fail-closed contract.
// ---------------------------------------------------------------------------

/** Fixed ids so lineage roots (`n1:<opId8>...`) are stable across requests. */
const namedBoxOperationId = "ee35835a-ad84-4768-9554-6385d3b4143a";
const namedHoleOperationId = "bd61ef50-50cd-479d-834f-6f26335fa9af";

function namedBoxHoleOperations(holeRadius: number): Operation[] {
  return [
    operationSchema.parse({
      id: namedBoxOperationId,
      type: "create_box",
      schemaVersion: 1,
      name: "Named plate",
      outputBodyId: "570b9e18-6286-46ec-8fc1-8ed563ee7f7a",
      parameters: {
        width: 80,
        depth: 50,
        height: 15,
        placement: {
          origin: [0, 0, 0],
          zDirection: [0, 0, 1],
          xDirection: [1, 0, 0],
        },
      },
      metadata: {
        createdAt: "2026-07-16T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    }),
    operationSchema.parse({
      id: namedHoleOperationId,
      type: "hole",
      schemaVersion: 1,
      name: "Named blind hole",
      outputBodyId: "e1f66fd5-1f87-4af3-b72d-8f6682902b05",
      parameters: {
        targetOperationId: namedBoxOperationId,
        placement: {
          origin: [15, 0, 15],
          zDirection: [0, 0, -1],
          xDirection: [1, 0, 0],
        },
        size: { kind: "radius", radius: holeRadius },
        depth: 10,
        throughAll: false,
      },
      metadata: {
        createdAt: "2026-07-16T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    }),
  ];
}

type EvaluationBody = Extract<
  Extract<KernelResponse, { ok: true }>["result"],
  { type: "evaluation" }
>["bodies"][number];

interface NamedEvaluation {
  readonly topology: NonNullable<EvaluationBody["topology"]>;
  readonly elementNames: NonNullable<EvaluationBody["elementNames"]>;
}

async function evaluateWithNames(
  operations: Operation[],
): Promise<NamedEvaluation> {
  const supervisor = await startSupervisor();
  const meshPromise = nextMesh(supervisor);
  const response = await supervisor.client.request(
    kernelRequestSchema.parse({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      documentId: randomUUID(),
      revision: 1,
      method: "evaluate_document",
      operations,
      includeTopology: true,
      includeElementNames: true,
    }),
  );
  await meshPromise;
  expectKernelOk(response);
  if (!response.ok || response.result.type !== "evaluation") {
    throw new Error("expected an evaluation result");
  }
  expect(response.result.bodies).toHaveLength(1);
  const body = response.result.bodies[0];
  if (!body?.topology || !body.elementNames) {
    throw new Error("expected topology and element names on the body");
  }
  return { topology: body.topology, elementNames: body.elementNames };
}

/**
 * First 8 hex characters of a UUID with dashes stripped — the name grammar's
 * operation prefix (element_names.hpp).
 */
function operationPrefix(operationId: string): string {
  return operationId.replaceAll("-", "").slice(0, 8);
}

describeNative("element names through evaluate_document (tranche N0)", () => {
  it("covers every snapshot entity and is byte-identical across independent evaluations", async () => {
    const first = await evaluateWithNames(namedBoxHoleOperations(8));
    const second = await evaluateWithNames(namedBoxHoleOperations(8));

    for (const evaluation of [first, second]) {
      // Total coverage, correlated by token: exactly one name per snapshot
      // entity — a resolver's "no match" honestly means missing, never "the
      // mapper skipped it".
      const snapshotTokens = evaluation.topology.entities
        .map((entity) => entity.token)
        .sort();
      const nameTokens = evaluation.elementNames
        .map((entry) => entry.token)
        .sort();
      expect(nameTokens).toEqual(snapshotTokens);
    }

    // Independent evaluations on independent kernel hosts produce
    // byte-identical name arrays (research 02 determinism contract). The
    // epoch-local tokens agree here too because both hosts are fresh, but
    // the durable claim under test is the NAME sequence.
    expect(first.elementNames.map((entry) => entry.name)).toEqual(
      second.elementNames.map((entry) => entry.name),
    );

    // The lineage channel is real, not a quantized fallback: the bore wall
    // (the only cylindrical face) roots at the HOLE operation, and box faces
    // root at the BOX operation.
    const nameByToken = new Map(
      first.elementNames.map((entry) => [entry.token, entry.name]),
    );
    const boreWall = first.topology.entities.find(
      (entity) => entity.kind === "face" && entity.geometryClass === "cylinder",
    );
    if (!boreWall) throw new Error("bore wall face is missing");
    expect(nameByToken.get(boreWall.token)).toMatch(
      new RegExp(`^n1:${operationPrefix(namedHoleOperationId)}\\.f\\.`),
    );
    const planarFaces = first.topology.entities.filter(
      (entity) => entity.kind === "face" && entity.geometryClass === "plane",
    );
    const boxRooted = planarFaces.filter((entity) =>
      nameByToken
        .get(entity.token)
        ?.startsWith(`n1:${operationPrefix(namedBoxOperationId)}.f.`),
    );
    // Six original box faces survive as faces (the top one re-trimmed); the
    // blind hole's floor is the only planar face NOT descending from the box.
    expect(boxRooted).toHaveLength(6);
  });

  it("preserves survivor congruence on untouched faces across a parameter edit", async () => {
    const before = await evaluateWithNames(namedBoxHoleOperations(8));
    const after = await evaluateWithNames(namedBoxHoleOperations(10));

    const faceNameAt = (
      evaluation: NamedEvaluation,
      centroid: [number, number, number],
    ): string => {
      const nameByToken = new Map(
        evaluation.elementNames.map((entry) => [entry.token, entry.name]),
      );
      const face = evaluation.topology.entities.find(
        (entity) =>
          entity.kind === "face" &&
          entity.geometryClass === "plane" &&
          Math.hypot(
            entity.centroid[0] - centroid[0],
            entity.centroid[1] - centroid[1],
            entity.centroid[2] - centroid[2],
          ) < 1e-6,
      );
      if (!face) {
        throw new Error(
          `expected a planar face at centroid ${JSON.stringify(centroid)}`,
        );
      }
      const name = nameByToken.get(face.token);
      if (!name) throw new Error("face has no element name");
      return name;
    };

    // The plate's bottom and four side faces are untouched by the hole edit:
    // identity survivors whose names carry no step for the hole at all, so
    // they must match byte-for-byte across the two evaluations.
    const untouchedCentroids: [number, number, number][] = [
      [0, 0, 0], // bottom
      [40, 0, 7.5],
      [-40, 0, 7.5],
      [0, 25, 7.5],
      [0, -25, 7.5],
    ];
    for (const centroid of untouchedCentroids) {
      const beforeName = faceNameAt(before, centroid);
      expect(faceNameAt(after, centroid)).toBe(beforeName);
      expect(beforeName).toMatch(
        new RegExp(`^n1:${operationPrefix(namedBoxOperationId)}\\.f\\.\\d+$`),
      );
    }

    // The top face IS touched (the hole re-trims it): its lineage gains
    // exactly one plain Modified step minted by the hole operation — the
    // step the survivor-matching normalization erases — and stays
    // byte-identical across the radius edit because the construction
    // identity is unchanged. Its centroid shifts with the radius (the
    // opening is off-center), so it is found as the one large box-rooted
    // planar face at z = 15 instead of by centroid.
    const topFaceName = (evaluation: NamedEvaluation): string => {
      const nameByToken = new Map(
        evaluation.elementNames.map((entry) => [entry.token, entry.name]),
      );
      const candidates = evaluation.topology.entities.filter(
        (entity) =>
          entity.kind === "face" &&
          entity.geometryClass === "plane" &&
          Math.abs(entity.centroid[2] - 15) < 1e-6 &&
          entity.measure > 1000 &&
          nameByToken
            .get(entity.token)
            ?.startsWith(`n1:${operationPrefix(namedBoxOperationId)}.f.`),
      );
      expect(candidates).toHaveLength(1);
      const top = candidates[0];
      if (!top) throw new Error("top face is missing");
      const name = nameByToken.get(top.token);
      if (!name) throw new Error("top face has no element name");
      return name;
    };
    const beforeTop = topFaceName(before);
    expect(topFaceName(after)).toBe(beforeTop);
    expect(beforeTop).toMatch(
      new RegExp(`/M\\.${operationPrefix(namedHoleOperationId)}$`),
    );
  });

  it("names transform survivors and fillet blends through their real histories", async () => {
    const boxOperationId = "1c56cd0a-88a2-4b6e-9d3e-27f4f4b2a901";
    const transformOperationId = "2d67de1b-99b3-4c7f-8e4f-38a5a5c3ba12";
    const filletOperationId = "3e78ef2c-aac4-4d80-9f50-49b6b6d4cb23";
    const baseBox = (targetName: string): Operation =>
      operationSchema.parse({
        id: boxOperationId,
        type: "create_box",
        schemaVersion: 1,
        name: targetName,
        outputBodyId: "681c0f29-7397-47fd-9002-9fe674ff8a8b",
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
          createdAt: "2026-07-16T00:00:00.000Z",
          createdBy: { kind: "user" },
        },
      });
    const metadata = {
      createdAt: "2026-07-16T00:00:00.000Z",
      createdBy: { kind: "user" },
    };

    // Transform: every entity is the single Modified image of its box
    // source, so every FACE name is exactly the box root plus one plain M
    // step — the step the survivor-matching normalization erases.
    const transformed = await evaluateWithNames([
      baseBox("Transform base"),
      operationSchema.parse({
        id: transformOperationId,
        type: "transform",
        schemaVersion: 1,
        name: "Moved base",
        outputBodyId: "792d1a3a-84a8-58fe-a113-afe785aa9b9c",
        parameters: {
          targetOperationId: boxOperationId,
          transform: { kind: "translate", offset: [5, 7, 9] },
        },
        metadata,
      }),
    ]);
    const transformFacePattern = new RegExp(
      `^n1:${operationPrefix(boxOperationId)}\\.f\\.\\d+/M\\.${operationPrefix(transformOperationId)}$`,
    );
    const transformNameByToken = new Map(
      transformed.elementNames.map((entry) => [entry.token, entry.name]),
    );
    const transformedFaces = transformed.topology.entities.filter(
      (entity) => entity.kind === "face",
    );
    expect(transformedFaces).toHaveLength(6);
    for (const face of transformedFaces) {
      expect(transformNameByToken.get(face.token)).toMatch(
        transformFacePattern,
      );
    }

    // Fillet (v1 all-edges): every surviving box face is re-trimmed (a
    // history-attributed image), every blend face descends from a box edge
    // or vertex — total coverage with NO face left to the quantized-geometry
    // fallback, proving the local-operation history actually flowed.
    const filleted = await evaluateWithNames([
      baseBox("Fillet base"),
      operationSchema.parse({
        id: filletOperationId,
        type: "fillet",
        schemaVersion: 1,
        name: "Rounded base",
        outputBodyId: "8a3e2b4b-95b9-69ff-b224-baf896bbac0d",
        parameters: { targetOperationId: boxOperationId, radius: 3 },
        metadata,
      }),
    ]);
    const filletNameByToken = new Map(
      filleted.elementNames.map((entry) => [entry.token, entry.name]),
    );
    const filletFaces = filleted.topology.entities.filter(
      (entity) => entity.kind === "face",
    );
    // 6 re-trimmed box faces + 12 edge blends + 8 corner patches.
    expect(filletFaces.length).toBeGreaterThan(6);
    let blendFaces = 0;
    for (const face of filletFaces) {
      const name = filletNameByToken.get(face.token);
      if (!name) throw new Error("fillet face has no element name");
      expect(name).not.toMatch(/^n1:Q\./);
      expect(name.startsWith(`n1:${operationPrefix(boxOperationId)}.`)).toBe(
        true,
      );
      if (name.includes(`/G.${operationPrefix(filletOperationId)}`)) {
        blendFaces += 1;
      }
    }
    expect(blendFaces).toBeGreaterThan(0);
  });

  it("fails closed when a document with an offset operation requests element names", async () => {
    const supervisor = await startSupervisor();
    const box = createBox(40, 40, 20);
    const offset: OffsetOperation = offsetOperationSchema.parse({
      id: randomUUID(),
      type: "offset",
      schemaVersion: 1,
      name: "Named offset",
      outputBodyId: randomUUID(),
      parameters: { targetOperationId: box.id, distance: 2 },
      metadata: {
        createdAt: "2026-07-16T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    });
    const response = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [box, offset],
        includeElementNames: true,
      }),
    );
    // Unverified history must never mint names: the request fails closed and
    // attributes the failure to the offset operation. The same document
    // WITHOUT the flag keeps evaluating exactly as before.
    expect(response.ok).toBe(false);
    if (response.ok) return;
    expect(response.error.code).toBe("UNSUPPORTED_OPERATION");
    expect(response.error.operationId).toBe(offset.id);

    const meshPromise = nextMesh(supervisor);
    const plain = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 2,
        method: "evaluate_document",
        operations: [box, offset],
      }),
    );
    await meshPromise;
    expectKernelOk(plain);
  });
});
