import { randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";

import {
  crc32Hex,
  createBoxOperationSchema,
  kernelProtocolVersion,
  kernelRequestSchema,
  parseAembPacket,
  type CreateBoxOperation,
  type KernelRequest,
} from "@aeth/geometry-contracts";
import { afterEach, expect, it } from "vitest";

import { nativeDescribe } from "./native-gate.js";

import {
  KernelRequestQueue,
  KernelRequestTimeoutError,
  KernelSupervisor,
  type BinaryMeshFrame,
} from "../src/index.js";

const executable = process.env.AETH_KERNEL_HOST_PATH;
const describeNative = nativeDescribe();
const supervisors: KernelSupervisor[] = [];
const queues: KernelRequestQueue[] = [];

const goldenFixture = JSON.parse(
  readFileSync(
    new URL("../../../fixtures/geometry/box-100x60x30.json", import.meta.url),
    "utf8",
  ),
) as {
  readonly operation: unknown;
  readonly expected: Readonly<{ volumeMm3: number }>;
};

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

function createBox(
  width: number,
  depth: number,
  height: number,
): CreateBoxOperation {
  return createBoxOperationSchema.parse({
    id: randomUUID(),
    type: "create_box",
    schemaVersion: 1,
    name: `Queue integration box ${width}x${depth}x${height}`,
    outputBodyId: randomUUID(),
    parameters: {
      width,
      depth,
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

function evaluateRequest(
  operation: CreateBoxOperation,
  revision: number,
): KernelRequest {
  return kernelRequestSchema.parse({
    protocolVersion: kernelProtocolVersion,
    requestId: randomUUID(),
    documentId: randomUUID(),
    revision,
    method: "evaluate_document",
    operations: [operation],
  });
}

/**
 * A deliberately heavy evaluation: `count` independent boxes, each tessellated
 * and streamed. Reliably outlasts a short transport deadline on any machine so
 * the timeout path fires while the OCCT worker is genuinely still in flight.
 */
function manyPrimitivesRequest(count: number, revision: number): KernelRequest {
  const operations = Array.from({ length: count }, (_unused, index) =>
    createBox(10 + (index % 7), 10 + (index % 5), 10 + (index % 3)),
  );
  return kernelRequestSchema.parse({
    protocolVersion: kernelProtocolVersion,
    requestId: randomUUID(),
    documentId: randomUUID(),
    revision,
    method: "evaluate_document",
    operations,
  });
}

async function settle<T>(
  promise: Promise<T>,
): Promise<
  { status: "resolved"; value: T } | { status: "rejected"; error: unknown }
> {
  try {
    return { status: "resolved", value: await promise };
  } catch (error) {
    return { status: "rejected", error };
  }
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
  for (const queue of queues.splice(0)) queue.close();
  for (const supervisor of supervisors.splice(0)) supervisor.stop();
});

describeNative("kernel request queue against the real host", () => {
  it("serializes three concurrent evaluate_document submissions with correlated meshes", async () => {
    if (!executable) throw new Error("AETH_KERNEL_HOST_PATH is not configured");
    const supervisor = new KernelSupervisor({
      executable,
      requestTimeoutMs: 120_000,
      environment: nativeEnvironment(),
    });
    supervisors.push(supervisor);
    await supervisor.start();
    const queue = new KernelRequestQueue(supervisor, {
      defaultDeadlineMs: 120_000,
    });
    queues.push(queue);

    const operations = [
      createBoxOperationSchema.parse(goldenFixture.operation),
      createBox(50, 40, 20),
      createBox(10, 10, 10),
    ];
    const expectedVolumes = [
      goldenFixture.expected.volumeMm3,
      50 * 40 * 20,
      10 * 10 * 10,
    ];
    const requests = operations.map((operation, index) =>
      evaluateRequest(operation, index + 1),
    );

    const meshesPromise = collectMeshes(supervisor, requests.length);
    const completionOrder: number[] = [];
    // Submit all three concurrently: independent tools sharing one host.
    const responses = await Promise.all(
      requests.map((request, index) =>
        queue.submit(request).then((response) => {
          completionOrder.push(index);
          return response;
        }),
      ),
    );

    // FIFO: the host answered in submission order.
    expect(completionOrder).toEqual([0, 1, 2]);
    expect(queue.depth).toBe(0);
    expect(queue.inFlightRequestId).toBeUndefined();

    const meshes = await meshesPromise;
    const framesBySequence = new Map(
      meshes.map((frame) => [frame.streamSequence, frame]),
    );
    expect(framesBySequence.size).toBe(requests.length);

    responses.forEach((response, index) => {
      const request = requests[index];
      const operation = operations[index];
      if (!request || !operation) throw new Error("fixture misalignment");
      expect(response.requestId).toBe(request.requestId);
      expect(response.ok).toBe(true);
      if (!response.ok || response.result.type !== "evaluation") {
        throw new Error("expected an evaluation result");
      }
      expect(response.result.revision).toBe(index + 1);
      expect(response.result.bodies).toHaveLength(1);
      const body = response.result.bodies[0];
      if (!body) throw new Error("evaluation returned no body");
      expect(body.bodyId).toBe(operation.outputBodyId);
      expect(body.probes.valid).toBe(true);
      expect(body.probes.volumeMm3).toBeCloseTo(
        expectedVolumes[index] ?? Number.NaN,
        6,
      );

      // Mesh events correlate per streamSequence and checksum.
      const frame = framesBySequence.get(body.mesh.streamSequence);
      if (!frame) {
        throw new Error(`missing mesh frame ${body.mesh.streamSequence}`);
      }
      expect(crc32Hex(frame.packet)).toBe(body.mesh.checksumCrc32);
      const aemb = parseAembPacket(frame.packet);
      expect(aemb.triangleCount).toBe(body.mesh.triangleCount);
      expect(aemb.triangleCount).toBeGreaterThan(0);
    });

    // Three distinct responses against three distinct meshes.
    const sequences = responses.map((response) => {
      if (!response.ok || response.result.type !== "evaluation") {
        throw new Error("expected an evaluation result");
      }
      return response.result.bodies[0]?.mesh.streamSequence;
    });
    expect(new Set(sequences).size).toBe(requests.length);
  });

  it("chains thousands of evaluations dispatched from each completion without a spurious BUSY", async () => {
    if (!executable) throw new Error("AETH_KERNEL_HOST_PATH is not configured");
    const supervisor = new KernelSupervisor({
      executable,
      requestTimeoutMs: 120_000,
      environment: nativeEnvironment(),
    });
    supervisors.push(supervisor);
    await supervisor.start();
    const queue = new KernelRequestQueue(supervisor, {
      defaultDeadlineMs: 120_000,
    });
    queues.push(queue);

    // Each request is submitted the instant its predecessor resolves (the
    // `await` returns in that completion continuation). Before the host
    // cleared `busy_` ahead of publishing its terminal response, this exact
    // pattern raced the flag and rejected legitimate sequential requests with
    // BUSY under scheduler pressure. Thousands of iterations make the old
    // race overwhelmingly likely to surface; the fixed ordering never does.
    const box = createBox(10, 10, 10);
    const iterations = 2_000;
    for (let index = 0; index < iterations; index += 1) {
      const response = await queue.submit(evaluateRequest(box, index + 1));
      if (!response.ok) {
        throw new Error(
          `sequential request ${index} failed: ${response.error.code} — ${response.error.message}`,
        );
      }
      if (response.result.type !== "evaluation") {
        throw new Error(`unexpected result type ${response.result.type}`);
      }
    }
    expect(queue.depth).toBe(0);
    expect(queue.inFlightRequestId).toBeUndefined();
  }, 120_000);

  it("never BUSYs a queued follow-up after an in-flight request times out (cancellation idleness barrier)", async () => {
    if (!executable) throw new Error("AETH_KERNEL_HOST_PATH is not configured");
    const supervisor = new KernelSupervisor({
      executable,
      requestTimeoutMs: 120_000,
      environment: nativeEnvironment(),
    });
    supervisors.push(supervisor);
    await supervisor.start();
    const queue = new KernelRequestQueue(supervisor, {
      defaultDeadlineMs: 120_000,
    });
    queues.push(queue);

    // Heavy evaluation with a short deadline: it dispatches, then the
    // transport deadline elapses while the OCCT worker is still tessellating.
    // A second request is already queued behind it. Before the idleness
    // barrier, releasing the host here could reject the follow-up with BUSY
    // because the cancelled worker had not actually stopped.
    const heavy = manyPrimitivesRequest(400, 1);
    const followUp = evaluateRequest(createBox(10, 10, 10), 2);
    const heavyPromise = settle(queue.submit(heavy, { deadlineMs: 40 }));
    const followUpPromise = settle(
      queue.submit(followUp, { deadlineMs: 120_000 }),
    );

    const heavyOutcome = await heavyPromise;
    // The heavy request timed out at the transport (worker still in flight),
    // not merely while queued.
    expect(heavyOutcome.status).toBe("rejected");
    if (heavyOutcome.status === "rejected") {
      expect(heavyOutcome.error).toBeInstanceOf(KernelRequestTimeoutError);
    }

    const followOutcome = await followUpPromise;
    // The follow-up must execute on the freed host and never see BUSY.
    expect(followOutcome.status).toBe("resolved");
    if (followOutcome.status === "resolved") {
      if (!followOutcome.value.ok) {
        throw new Error(
          `follow-up failed after a timeout: ${followOutcome.value.error.code} — ${followOutcome.value.error.message}`,
        );
      }
      expect(followOutcome.value.result.type).toBe("evaluation");
    }
    expect(queue.depth).toBe(0);
    expect(queue.inFlightRequestId).toBeUndefined();
  }, 120_000);
});
