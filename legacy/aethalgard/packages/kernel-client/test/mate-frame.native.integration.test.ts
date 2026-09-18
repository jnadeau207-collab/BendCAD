import { createHash, randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";

import {
  createBoxOperationSchema,
  createSphereOperationSchema,
  kernelProtocolVersion,
  resolveMateFramesKernelRequestSchema,
  type ResolveMateFramesKernelResponse,
  type WireOperation,
} from "@aeth/geometry-contracts";
import { afterEach, expect, it } from "vitest";

import { KernelSupervisor } from "../src/index.js";
import { nativeDescribe } from "./native-gate.js";

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

const sphereFixture = JSON.parse(
  readFileSync(
    new URL("../../../fixtures/geometry/sphere-r30.json", import.meta.url),
    "utf8",
  ),
) as { readonly operation: unknown };
const boxFixture = JSON.parse(
  readFileSync(
    new URL("../../../fixtures/geometry/box-100x60x30.json", import.meta.url),
    "utf8",
  ),
) as { readonly operation: unknown };

const allFacesAst = {
  kind: "faces",
  scope: [{ source: "all" }],
  filters: [],
} as const;

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

function revisionHashOf(operations: readonly WireOperation[]): string {
  return createHash("sha256").update(JSON.stringify(operations)).digest("hex");
}

async function resolve(
  supervisor: KernelSupervisor,
  operations: readonly WireOperation[],
  expectedGeometry: "sphere" | "plane",
): Promise<ResolveMateFramesKernelResponse> {
  const request = resolveMateFramesKernelRequestSchema.parse({
    protocolVersion: kernelProtocolVersion,
    requestId: randomUUID(),
    method: "resolve_mate_frames",
    definitionId: randomUUID(),
    revisionHash: revisionHashOf(operations),
    operations,
    endpoints: [
      {
        requestId: "primary-endpoint",
        ast: allFacesAst,
        expectedGeometry,
      },
    ],
  });
  return supervisor.client.request(request, { timeoutMs: 120_000 });
}

afterEach(() => {
  for (const supervisor of supervisors.splice(0)) supervisor.stop();
});

describeNative("resolve_mate_frames over the real kernel host", () => {
  it("returns exact resolved, ambiguous, and invalidated endpoint outcomes", async () => {
    const supervisor = await startSupervisor();
    const sphere = createSphereOperationSchema.parse(sphereFixture.operation);
    const box = createBoxOperationSchema.parse(boxFixture.operation);

    const resolved = await resolve(supervisor, [sphere], "sphere");
    expect(resolved.ok).toBe(true);
    if (!resolved.ok) throw new Error(JSON.stringify(resolved.error));
    expect(resolved.result.type).toBe("mate_frame_resolution");
    expect(resolved.result.outcomes).toHaveLength(1);
    const [resolvedOutcome] = resolved.result.outcomes;
    expect(resolvedOutcome?.status).toBe("resolved");
    if (!resolvedOutcome || resolvedOutcome.status !== "resolved") {
      throw new Error(
        `unexpected resolved outcome: ${JSON.stringify(resolvedOutcome)}`,
      );
    }
    expect(resolvedOutcome.frame.geometry).toBe("sphere");
    expect(resolvedOutcome.frame.origin).toEqual([0, 0, 0]);
    expect(resolvedOutcome.frame.radius).toBeCloseTo(30, 10);
    expect(resolvedOutcome.frame.orientationClass).toBe("isotropic");

    const ambiguous = await resolve(supervisor, [box], "plane");
    expect(ambiguous.ok).toBe(true);
    if (!ambiguous.ok) throw new Error(JSON.stringify(ambiguous.error));
    const [ambiguousOutcome] = ambiguous.result.outcomes;
    expect(ambiguousOutcome?.status).toBe("ambiguous");
    if (!ambiguousOutcome || ambiguousOutcome.status !== "ambiguous") {
      throw new Error(
        `unexpected ambiguous outcome: ${JSON.stringify(ambiguousOutcome)}`,
      );
    }
    expect(ambiguousOutcome.candidates.length).toBeGreaterThan(1);
    expect(ambiguousOutcome.candidates.length).toBeLessThanOrEqual(5);

    const invalidated = await resolve(supervisor, [sphere], "plane");
    expect(invalidated.ok).toBe(true);
    if (!invalidated.ok) throw new Error(JSON.stringify(invalidated.error));
    const [invalidatedOutcome] = invalidated.result.outcomes;
    expect(invalidatedOutcome?.status).toBe("invalidated");
  });
});
