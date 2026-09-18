import { createHash, randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";

import {
  aembSectionIds,
  createCylinderOperationSchema,
  createSphereOperationSchema,
  kernelProtocolVersion,
  kernelRequestSchema,
  manufacturingExportTessellationQuality,
  parseAembPacket,
} from "@aeth/geometry-contracts";
import { afterEach, expect, it } from "vitest";

import { nativeDescribe } from "./native-gate.js";

import { KernelSupervisor, type BinaryMeshFrame } from "../src/index.js";

/**
 * Proves the MANUFACTURING EXPORT tessellation (finding-10) actually delivers a
 * bounded chord error at large body scales — not merely that it passes 0.02 mm
 * as a parameter. A large curved body is placed one kilometre from the world
 * origin, exported through the real kernel's `export_mesh` method, and the
 * returned AEMB2 packet is decoded back to WORLD coordinates. The chord error
 * (sagitta) at every tessellated edge midpoint is measured against the analytic
 * surface and must stay at manufacturing fidelity — within 2x the 0.02 mm
 * export deflection target (OCCT realizes ~0.03 mm on a sphere).
 *
 * The kilometre offset is the crux of the test: float32 has ~0.12 mm ULP at
 * 1e6 mm, several times the export tolerance. The measured chord error stays at
 * ~0.02-0.03 mm ONLY because AEMB2 stores body-LOCAL coordinates rebased against
 * an f64 world origin (finding-9); an encoder that wrote world coordinates as
 * float32 would smear the surface by ~0.12 mm and fail this test. So the two
 * integrity fixes are proven together, end to end, against real OCCT.
 *
 * Native-gated exactly like the sibling boundary suite: it runs only when
 * AETH_KERNEL_HOST_PATH points at a built host (native:test sets it).
 */
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

/**
 * Absolute export tolerances the kernel's TessellateShapeForExport pins —
 * read from the single-source tessellation-quality table so this native
 * integration test and the C++ mesher provably agree on the same numbers.
 */
const exportDeflectionMm =
  manufacturingExportTessellationQuality.linearDeflectionMm;
const exportLodTier = manufacturingExportTessellationQuality.lodTier;
/**
 * One kilometre from origin: large enough that float32 ULP (~0.12 mm) dwarfs
 * the export tolerance, so a non-rebased encoder cannot pass, yet far inside
 * the 1e8 mm model-extent envelope so the kernel accepts the body.
 */
const worldOffsetMm = 1_000_000;
/** A half-metre-scale body: at this radius the 0.02 mm LINEAR deflection binds
 * (its 1.45° chord step is finer than the 10° angular floor), so the measured
 * sagitta should sit right at ~0.02 mm rather than being angle-limited. */
const bodyRadiusMm = 250;
/**
 * Upper bound on the measured sagitta. OCCT's BRepMesh treats the linear
 * deflection as an approximate target and realizes up to ~1.5x it on doubly
 * curved surfaces (a sphere here measures ~0.03 mm, deterministically), so the
 * meaningful ceiling is 2x the 0.02 mm target. This is still an order of
 * magnitude under display-grade LOD and, crucially, far below the ~0.12 mm
 * float32 ULP at 1e6 mm — so a non-rebased encoder (finding-9 regression) fails
 * this bound while the real, rebased export clears it.
 */
const chordErrorCeilingMm = 0.04;

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

async function startSupervisor(): Promise<KernelSupervisor> {
  if (!executable) throw new Error("AETH_KERNEL_HOST_PATH is not configured");
  const supervisor = new KernelSupervisor({
    executable,
    requestTimeoutMs: 120_000,
    environment: nativeEnvironment(),
  });
  supervisors.push(supervisor);
  const build = await supervisor.start();
  expect(build.occtManifestSha256).toBe(occtManifestSha256);
  return supervisor;
}

function nextMesh(supervisor: KernelSupervisor): Promise<BinaryMeshFrame> {
  return new Promise((resolve) => supervisor.client.once("mesh", resolve));
}

/** A single body's mesh reconstructed to WORLD millimetres from an AEMB2 packet. */
interface WorldMesh {
  readonly positions: Float64Array;
  readonly triangles: Uint32Array;
  readonly faceOwners: Uint32Array;
  readonly vertexCount: number;
  readonly triangleCount: number;
}

/**
 * Decodes an AEMB2 packet to world coordinates: the packet stores body-local
 * float32 positions, so world = worldOriginMm (f64) + local (f32). This is the
 * exact reconstruction the viewport performs, exercised here to measure the
 * geometry the kernel actually produced.
 */
function toWorldMesh(packet: ArrayBuffer): WorldMesh {
  const aemb = parseAembPacket(packet);
  const positionSection = aemb.sections.get(aembSectionIds.positions);
  const triangleSection = aemb.sections.get(aembSectionIds.triangles);
  const faceSection = aemb.sections.get(aembSectionIds.faceIds);
  if (!positionSection || !triangleSection || !faceSection) {
    throw new Error("AEMB packet is missing a required section");
  }
  const local = new Float32Array(
    aemb.buffer,
    positionSection.byteOffset,
    aemb.vertexCount * 3,
  );
  const [originX, originY, originZ] = aemb.worldOriginMm;
  const positions = new Float64Array(aemb.vertexCount * 3);
  for (let vertex = 0; vertex < aemb.vertexCount; vertex += 1) {
    positions[vertex * 3] = originX + (local[vertex * 3] ?? 0);
    positions[vertex * 3 + 1] = originY + (local[vertex * 3 + 1] ?? 0);
    positions[vertex * 3 + 2] = originZ + (local[vertex * 3 + 2] ?? 0);
  }
  const triangles = new Uint32Array(
    aemb.buffer,
    triangleSection.byteOffset,
    aemb.triangleCount * 3,
  );
  const faceOwners = new Uint32Array(
    aemb.buffer,
    faceSection.byteOffset,
    aemb.triangleCount,
  );
  return {
    positions,
    triangles,
    faceOwners,
    vertexCount: aemb.vertexCount,
    triangleCount: aemb.triangleCount,
  };
}

/** Every ordered [a, b] edge of triangle t (indices into `positions`). */
function triangleEdges(mesh: WorldMesh, triangle: number): [number, number][] {
  const a = mesh.triangles[triangle * 3] ?? 0;
  const b = mesh.triangles[triangle * 3 + 1] ?? 0;
  const c = mesh.triangles[triangle * 3 + 2] ?? 0;
  return [
    [a, b],
    [b, c],
    [c, a],
  ];
}

interface ChordErrorMeasurement {
  readonly maxErrorMm: number;
  readonly edgesMeasured: number;
}

/**
 * Maximum chord error over the edges the caller admits, where `surfaceDistance`
 * returns the signed distance from the analytic surface (0 on the surface) for
 * a world point. The chord error at an edge is how far its MIDPOINT sinks below
 * the true surface — the sagitta the tessellation is allowed to introduce.
 */
function measureChordError(
  mesh: WorldMesh,
  admitTriangle: (triangle: number) => boolean,
  surfaceDistance: (x: number, y: number, z: number) => number,
): ChordErrorMeasurement {
  let maxErrorMm = 0;
  let edgesMeasured = 0;
  for (let triangle = 0; triangle < mesh.triangleCount; triangle += 1) {
    if (!admitTriangle(triangle)) continue;
    for (const [a, b] of triangleEdges(mesh, triangle)) {
      const midX =
        ((mesh.positions[a * 3] ?? 0) + (mesh.positions[b * 3] ?? 0)) / 2;
      const midY =
        ((mesh.positions[a * 3 + 1] ?? 0) + (mesh.positions[b * 3 + 1] ?? 0)) /
        2;
      const midZ =
        ((mesh.positions[a * 3 + 2] ?? 0) + (mesh.positions[b * 3 + 2] ?? 0)) /
        2;
      const error = Math.abs(surfaceDistance(midX, midY, midZ));
      if (error > maxErrorMm) maxErrorMm = error;
      edgesMeasured += 1;
    }
  }
  return { maxErrorMm, edgesMeasured };
}

/**
 * Face-owner ids whose triangles span a large Z extent. On an axis-aligned
 * cylinder this isolates the single curved lateral face from the two flat caps
 * without any radial heuristic: the caps are planar at constant Z (near-zero
 * extent), while the lateral face reaches from the bottom rim to the top rim.
 * Radial isolation is unsound because a cap triangle can carry a diameter edge
 * whose endpoints both sit at r = R yet whose midpoint is the axis (r = 0).
 */
function largeZExtentFaceOwners(
  mesh: WorldMesh,
  minExtentMm: number,
): Set<number> {
  const zMin = new Map<number, number>();
  const zMax = new Map<number, number>();
  for (let triangle = 0; triangle < mesh.triangleCount; triangle += 1) {
    const owner = mesh.faceOwners[triangle] ?? 0;
    for (let corner = 0; corner < 3; corner += 1) {
      const vertex = mesh.triangles[triangle * 3 + corner] ?? 0;
      const z = mesh.positions[vertex * 3 + 2] ?? 0;
      zMin.set(owner, Math.min(zMin.get(owner) ?? Infinity, z));
      zMax.set(owner, Math.max(zMax.get(owner) ?? -Infinity, z));
    }
  }
  const owners = new Set<number>();
  for (const [owner, hi] of zMax) {
    if (hi - (zMin.get(owner) ?? hi) > minExtentMm) owners.add(owner);
  }
  return owners;
}

afterEach(() => {
  for (const supervisor of supervisors.splice(0)) supervisor.stop();
});

describeNative("export tessellation chord error at large body scales", () => {
  // Kilometre-offset tessellation legitimately runs right at vitest's 5 s
  // default under parallel suite load; explicit headroom, matching the
  // repo's precedent for known-heavy tests.
  it(
    "keeps a cylinder's lateral chord error at manufacturing fidelity one kilometre from origin",
    { timeout: 30_000 },
    async () => {
      const supervisor = await startSupervisor();
      const centerX = worldOffsetMm;
      const centerY = worldOffsetMm;
      const cylinder = createCylinderOperationSchema.parse({
        id: randomUUID(),
        type: "create_cylinder",
        schemaVersion: 1,
        name: "Chord-error cylinder",
        outputBodyId: randomUUID(),
        parameters: {
          radius: bodyRadiusMm,
          height: 400,
          placement: {
            origin: [centerX, centerY, 0],
            zDirection: [0, 0, 1],
            xDirection: [1, 0, 0],
          },
        },
        metadata: {
          createdAt: "2026-07-15T00:00:00.000Z",
          createdBy: { kind: "user" },
        },
      });

      const meshPromise = nextMesh(supervisor);
      const response = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 1,
          method: "export_mesh",
          operations: [cylinder],
        }),
      );
      expect(
        response.ok,
        response.ok ? "" : `kernel error: ${JSON.stringify(response.error)}`,
      ).toBe(true);
      if (!response.ok || response.result.type !== "export_mesh") return;
      const body = response.result.bodies[0];
      expect(body).toBeDefined();
      if (!body) return;
      // The descriptor proves this came from the export tessellation, not the
      // size-relative viewport LOD.
      expect(body.mesh.lodTier).toBe(exportLodTier);
      expect(body.mesh.deflectionMm).toBeCloseTo(exportDeflectionMm, 6);

      const frame = await meshPromise;
      expect(frame.streamSequence).toBe(body.mesh.streamSequence);
      const mesh = toWorldMesh(frame.packet);

      // Isolate the single curved lateral face by Z extent: the cylinder's two
      // caps are planar (constant Z), only the wall spans the full 400 mm height.
      const lateralOwners = largeZExtentFaceOwners(mesh, 200);
      expect(lateralOwners.size).toBe(1);
      const isLateral = (triangle: number): boolean =>
        lateralOwners.has(mesh.faceOwners[triangle] ?? 0);
      const lateralTriangles = Array.from(
        { length: mesh.triangleCount },
        (_unused, triangle) => triangle,
      ).filter(isLateral).length;
      // A 0.02 mm tessellation of an R=250 cylinder is hundreds of lateral
      // triangles; a mere handful would mean the isolation picked up a cap.
      expect(lateralTriangles).toBeGreaterThan(100);

      const { maxErrorMm, edgesMeasured } = measureChordError(
        mesh,
        isLateral,
        (x, y) => Math.hypot(x - centerX, y - centerY) - bodyRadiusMm,
      );
      expect(edgesMeasured).toBeGreaterThan(0);
      // The heart of the test: real, measured surface deviation stays at the
      // export tolerance even a kilometre out — only rebasing makes this hold.
      expect(maxErrorMm).toBeLessThanOrEqual(chordErrorCeilingMm);
      // And the mesh is genuinely faceted at export scale (not degenerate): the
      // worst chord is a real fraction of the tolerance, not numerical zero.
      expect(maxErrorMm).toBeGreaterThan(0.001);
    },
  );

  it(
    "keeps a sphere's chord error at manufacturing fidelity one kilometre from origin",
    { timeout: 30_000 },
    async () => {
      const supervisor = await startSupervisor();
      const center: [number, number, number] = [
        worldOffsetMm,
        worldOffsetMm,
        worldOffsetMm,
      ];
      const sphere = createSphereOperationSchema.parse({
        id: randomUUID(),
        type: "create_sphere",
        schemaVersion: 1,
        name: "Chord-error sphere",
        outputBodyId: randomUUID(),
        parameters: {
          radius: bodyRadiusMm,
          placement: {
            origin: center,
            zDirection: [0, 0, 1],
            xDirection: [1, 0, 0],
          },
        },
        metadata: {
          createdAt: "2026-07-15T00:00:00.000Z",
          createdBy: { kind: "user" },
        },
      });

      const meshPromise = nextMesh(supervisor);
      const response = await supervisor.client.request(
        kernelRequestSchema.parse({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          documentId: randomUUID(),
          revision: 1,
          method: "export_mesh",
          operations: [sphere],
        }),
      );
      expect(
        response.ok,
        response.ok ? "" : `kernel error: ${JSON.stringify(response.error)}`,
      ).toBe(true);
      if (!response.ok || response.result.type !== "export_mesh") return;
      const body = response.result.bodies[0];
      expect(body).toBeDefined();
      if (!body) return;
      expect(body.mesh.lodTier).toBe(exportLodTier);
      expect(body.mesh.deflectionMm).toBeCloseTo(exportDeflectionMm, 6);

      const frame = await meshPromise;
      expect(frame.streamSequence).toBe(body.mesh.streamSequence);
      const mesh = toWorldMesh(frame.packet);

      // A sphere is a single curved face: every triangle is admitted and the
      // surface distance is the 3-D radial error from the sphere centre.
      const { maxErrorMm, edgesMeasured } = measureChordError(
        mesh,
        () => true,
        (x, y, z) =>
          Math.hypot(x - center[0], y - center[1], z - center[2]) -
          bodyRadiusMm,
      );
      expect(edgesMeasured).toBeGreaterThan(300);
      expect(maxErrorMm).toBeLessThanOrEqual(chordErrorCeilingMm);
      expect(maxErrorMm).toBeGreaterThan(0.001);
    },
  );
});
