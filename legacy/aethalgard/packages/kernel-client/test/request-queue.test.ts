import { randomUUID } from "node:crypto";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import {
  kernelProtocolVersion,
  kernelRequestSchema,
  type KernelRequest,
  type KernelResponse,
} from "@aeth/geometry-contracts";
import { ControlFrameError } from "@aeth/ipc";
import { afterEach, describe, expect, it } from "vitest";

import {
  BinaryFrameError,
  KernelConnectionError,
  KernelEpochInvalidatedError,
  KernelQueueCancelledError,
  KernelQueueClosedError,
  KernelQueueError,
  KernelQueueFullError,
  KernelQueueTimeoutError,
  KernelRequestQueue,
  KernelRequestTimeoutError,
  KernelSupervisor,
} from "../src/index.js";

const fixture = fileURLToPath(
  new URL("./fixtures/scripted-kernel.mjs", import.meta.url),
);

interface Harness {
  readonly supervisor: KernelSupervisor;
  readonly queue: KernelRequestQueue;
  readonly logPath: string;
}

const cleanups: (() => void)[] = [];

interface LoggedRequest {
  readonly pid: number;
  readonly method: string;
  readonly requestId: string;
  readonly targetRequestId?: string;
}

function readLog(logPath: string): LoggedRequest[] {
  let raw: string;
  try {
    raw = readFileSync(logPath, "utf8");
  } catch {
    return [];
  }
  return raw
    .split("\n")
    .filter((line) => line.length > 0)
    .map((line) => JSON.parse(line) as LoggedRequest);
}

async function startHarness(
  behavior: string,
  queueOptions: ConstructorParameters<typeof KernelRequestQueue>[1] = {},
): Promise<Harness> {
  const directory = mkdtempSync(join(tmpdir(), "aeth-scripted-kernel-"));
  const logPath = join(directory, "requests.ndjson");
  const supervisor = new KernelSupervisor({
    executable: process.execPath,
    arguments: [fixture],
    requestTimeoutMs: 5_000,
    environment: {
      AETH_SCRIPTED_KERNEL_BEHAVIOR: behavior,
      AETH_SCRIPTED_KERNEL_REQUEST_LOG: logPath,
    },
  });
  const queue = new KernelRequestQueue(supervisor, queueOptions);
  cleanups.push(() => {
    queue.close();
    supervisor.stop();
    rmSync(directory, { recursive: true, force: true });
  });
  await supervisor.start();
  return { supervisor, queue, logPath };
}

function evaluateRequest(name: string, revision: number): KernelRequest {
  return kernelRequestSchema.parse({
    protocolVersion: kernelProtocolVersion,
    requestId: randomUUID(),
    documentId: randomUUID(),
    revision,
    method: "evaluate_document",
    operations: [
      {
        id: randomUUID(),
        type: "create_box",
        schemaVersion: 1,
        name,
        outputBodyId: randomUUID(),
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
          createdAt: "2026-07-13T00:00:00.000Z",
          createdBy: { kind: "user" },
        },
      },
    ],
  });
}

function healthRequest(): KernelRequest {
  return {
    protocolVersion: kernelProtocolVersion,
    requestId: randomUUID(),
    method: "health",
  };
}

type Captured<T> =
  | { readonly status: "resolved"; readonly value: T }
  | { readonly status: "rejected"; readonly error: unknown };

/** Attaches handlers immediately so early rejections never go unhandled. */
function capture<T>(promise: Promise<T>): Promise<Captured<T>> {
  return promise.then(
    (value) => ({ status: "resolved" as const, value }),
    (error: unknown) => ({ status: "rejected" as const, error }),
  );
}

function rejectionOf<T>(captured: Captured<T>): unknown {
  expect(captured.status).toBe("rejected");
  return captured.status === "rejected" ? captured.error : undefined;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function until(
  condition: () => boolean,
  timeoutMs = 4_000,
): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (!condition()) {
    if (Date.now() > deadline) throw new Error("until() condition timed out");
    await sleep(2);
  }
}

function onceRecovered(supervisor: KernelSupervisor): Promise<void> {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(
      () => reject(new Error("supervisor recovery timed out")),
      8_000,
    );
    supervisor.once("recovered", () => {
      clearTimeout(timeout);
      resolve();
    });
  });
}

afterEach(() => {
  for (const cleanup of cleanups.splice(0)) cleanup();
});

describe("kernel request queue", () => {
  it("dispatches FIFO with a single in-flight request and distinct responses", async () => {
    const { queue, logPath } = await startHarness("respond");
    const requests = [1, 2, 3].map((revision) =>
      evaluateRequest("sleep:50", revision),
    );
    const completionOrder: number[] = [];
    const settlements = requests.map((request, index) =>
      capture(
        queue.submit(request).then((response) => {
          completionOrder.push(index);
          return response;
        }),
      ),
    );
    const first = requests[0];
    if (!first) throw new Error("missing request fixture");
    expect(queue.inFlightRequestId).toBe(first.requestId);
    expect(queue.depth).toBe(2);
    const responses: KernelResponse[] = [];
    for (const settlement of settlements) {
      const outcome = await settlement;
      expect(outcome.status).toBe("resolved");
      if (outcome.status === "resolved") responses.push(outcome.value);
    }
    expect(completionOrder).toEqual([0, 1, 2]);
    responses.forEach((response, index) => {
      expect(response.requestId).toBe(requests[index]?.requestId);
      expect(response.ok).toBe(true);
      if (response.ok && response.result.type === "evaluation") {
        expect(response.result.revision).toBe(index + 1);
      }
    });
    expect(queue.depth).toBe(0);
    expect(queue.inFlightRequestId).toBeUndefined();
    const evaluates = readLog(logPath).filter(
      (entry) => entry.method === "evaluate_document",
    );
    expect(evaluates.map((entry) => entry.requestId)).toEqual(
      requests.map((request) => request.requestId),
    );
  });

  it("treats a corrupt control frame mid-queue as connection-fatal, then restarts clean", async () => {
    const { supervisor, queue, logPath } = await startHarness(
      "corrupt-control-after:1",
    );
    const fatalErrors: Error[] = [];
    supervisor.on("client-fatal", (error: Error) => fatalErrors.push(error));
    const recovered = onceRecovered(supervisor);
    const requests = [1, 2, 3].map((revision) =>
      evaluateRequest("sleep:0", revision),
    );
    const settlements = requests.map((request) =>
      capture(queue.submit(request)),
    );
    const [first, second, third] = await Promise.all(settlements);
    if (!first || !second || !third) throw new Error("missing settlements");

    // The response answered before the corruption was delivered intact.
    expect(first.status).toBe("resolved");
    if (first.status === "resolved") expect(first.value.ok).toBe(true);

    // The in-flight request fails with the fatal connection error, whose
    // cause is the framing error — fatal per the foundation audit contract.
    const secondError = rejectionOf(second);
    expect(secondError).toBeInstanceOf(KernelConnectionError);
    expect((secondError as Error).message).toMatch(/control stream is corrupt/);
    expect((secondError as Error).cause).toBeInstanceOf(ControlFrameError);

    // Queued requests behind it reject with the same fatal error and never
    // reach the host.
    expect(rejectionOf(third)).toBe(secondError);
    expect(fatalErrors[0]).toBe(secondError);

    await recovered;
    expect(queue.depth).toBe(0);
    expect(queue.inFlightRequestId).toBeUndefined();
    expect(supervisor.state).toBe("ready");
    expect(supervisor.epoch).toBe(2);

    const afterRestart = evaluateRequest("sleep:0", 4);
    const response = await queue.submit(afterRestart);
    expect(response.ok).toBe(true);

    const log = readLog(logPath);
    const thirdRequest = requests[2];
    if (!thirdRequest) throw new Error("missing request fixture");
    expect(
      log.some((entry) => entry.requestId === thirdRequest.requestId),
    ).toBe(false);
    expect(
      log.some((entry) => entry.requestId === afterRestart.requestId),
    ).toBe(true);
    expect(log.filter((entry) => entry.method === "health").length).toBe(2);
  }, 30_000);

  it("treats a garbage binary frame as connection-fatal for the whole queue", async () => {
    const { supervisor, queue } = await startHarness(
      "corrupt-binary-on-evaluate",
    );
    const recovered = onceRecovered(supervisor);
    const first = capture(queue.submit(evaluateRequest("sleep:0", 1)));
    const second = capture(queue.submit(evaluateRequest("sleep:0", 2)));
    const firstError = rejectionOf(await first);
    expect(firstError).toBeInstanceOf(KernelConnectionError);
    expect((firstError as Error).message).toMatch(/binary stream is corrupt/);
    expect((firstError as Error).cause).toBeInstanceOf(BinaryFrameError);
    expect(rejectionOf(await second)).toBe(firstError);
    await recovered;
    expect(queue.depth).toBe(0);
    const health = await queue.submit(healthRequest());
    expect(health.ok).toBe(true);
  });

  it("rejects submissions beyond the bounded queue depth without host traffic", async () => {
    const { queue, logPath } = await startHarness("respond", {
      maxQueueDepth: 1,
    });
    const first = capture(queue.submit(evaluateRequest("sleep:300", 1)));
    const second = capture(queue.submit(evaluateRequest("sleep:0", 2)));
    const overflow = evaluateRequest("sleep:0", 3);
    const third = capture(queue.submit(overflow));
    const thirdError = rejectionOf(await third);
    expect(thirdError).toBeInstanceOf(KernelQueueFullError);
    expect((thirdError as KernelQueueFullError).maxQueueDepth).toBe(1);
    expect((await first).status).toBe("resolved");
    expect((await second).status).toBe("resolved");
    expect(
      readLog(logPath).some((entry) => entry.requestId === overflow.requestId),
    ).toBe(false);
  }, 30_000);

  it("cancelling a queued request removes it without any host traffic", async () => {
    const { queue, logPath } = await startHarness("respond");
    const first = capture(queue.submit(evaluateRequest("sleep:300", 1)));
    const controller = new AbortController();
    const cancelled = evaluateRequest("sleep:0", 2);
    const second = capture(
      queue.submit(cancelled, { signal: controller.signal }),
    );
    controller.abort();
    expect(rejectionOf(await second)).toBeInstanceOf(KernelQueueCancelledError);
    expect((await first).status).toBe("resolved");
    const followUp = await queue.submit(evaluateRequest("sleep:0", 3));
    expect(followUp.ok).toBe(true);
    const log = readLog(logPath);
    expect(log.some((entry) => entry.requestId === cancelled.requestId)).toBe(
      false,
    );
    expect(log.some((entry) => entry.method === "cancel")).toBe(false);
  });

  it("cancelling an in-flight request sends protocol cancel and resolves per the host's CANCELLED error", async () => {
    const { queue, logPath } = await startHarness("respond");
    const controller = new AbortController();
    const request = evaluateRequest("sleep:5000", 1);
    const settlement = capture(
      queue.submit(request, { signal: controller.signal }),
    );
    await until(() => queue.inFlightRequestId === request.requestId);
    controller.abort();
    const outcome = await settlement;
    expect(outcome.status).toBe("resolved");
    if (outcome.status === "resolved") {
      expect(outcome.value.ok).toBe(false);
      if (!outcome.value.ok) {
        expect(outcome.value.error.code).toBe("CANCELLED");
      }
    }
    const cancelEntry = readLog(logPath).find(
      (entry) => entry.method === "cancel",
    );
    expect(cancelEntry?.targetRequestId).toBe(request.requestId);
  });

  it("expires a request whose deadline passes while it is still queued", async () => {
    const { queue, logPath } = await startHarness("respond");
    const first = capture(queue.submit(evaluateRequest("sleep:400", 1)));
    const expiring = evaluateRequest("sleep:0", 2);
    const second = capture(queue.submit(expiring, { deadlineMs: 50 }));
    const error = rejectionOf(await second);
    expect(error).toBeInstanceOf(KernelQueueTimeoutError);
    expect(error).not.toBeInstanceOf(KernelRequestTimeoutError);
    expect((await first).status).toBe("resolved");
    expect(
      readLog(logPath).some((entry) => entry.requestId === expiring.requestId),
    ).toBe(false);
  });

  it("distinguishes transport timeouts and frees the host with a protocol cancel", async () => {
    const { supervisor, queue, logPath } = await startHarness("respond");
    const stuck = evaluateRequest("sleep:5000", 1);
    const settlement = capture(queue.submit(stuck, { deadlineMs: 100 }));
    const error = rejectionOf(await settlement);
    expect(error).toBeInstanceOf(KernelRequestTimeoutError);
    expect(error).toBeInstanceOf(KernelConnectionError);
    expect(error).not.toBeInstanceOf(KernelQueueError);
    await until(() =>
      readLog(logPath).some(
        (entry) =>
          entry.method === "cancel" &&
          entry.targetRequestId === stuck.requestId,
      ),
    );
    const followUp = await queue.submit(evaluateRequest("sleep:0", 2));
    expect(followUp.ok).toBe(true);
    // A valid cancellation ack for the timed-out target PROVED the host idle, so
    // the queue dispatched the follow-up on the SAME process — no restart, epoch
    // unchanged. This is the positive contrast to the wedged-escalation case.
    expect(supervisor.epoch).toBe(1);
  });

  it("escalates to a fresh process when a timed-out request's cancel cannot prove idleness", async () => {
    // The idleness barrier only holds if the queue trusts a cancel ack ONLY
    // when it is a well-formed OK cancellation for the exact target. Here the
    // host answers the cancel with a valid-but-mismatched cancellation (naming
    // a different target), which is NOT proof this request's worker stopped.
    // The queue must therefore treat the host as wedged and force a restart
    // rather than dispatch into a process it cannot prove is idle.
    const { supervisor, queue, logPath } = await startHarness(
      "stuck-evaluate-bad-cancel:mismatch",
    );
    expect(supervisor.epoch).toBe(1);
    const recovered = onceRecovered(supervisor);
    const stuck = evaluateRequest("sleep:0", 1);
    const settlement = capture(queue.submit(stuck, { deadlineMs: 80 }));
    const error = rejectionOf(await settlement);
    expect(error).toBeInstanceOf(KernelRequestTimeoutError);
    // The queue tried to prove idleness with a cancel for the timed-out target.
    await until(() =>
      readLog(logPath).some(
        (entry) =>
          entry.method === "cancel" &&
          entry.targetRequestId === stuck.requestId,
      ),
    );
    // The mismatched ack was rejected as non-proof, so the queue killed the
    // client; the supervisor's crash recovery restarts into a fresh epoch.
    await recovered;
    expect(supervisor.epoch).toBe(2);
    // The queue is functional again on the new process (health round-trips).
    const health = await queue.submit(healthRequest());
    expect(health.ok).toBe(true);
  }, 30_000);

  it("escalates to a fresh process when a timed-out request's cancel returns an error", async () => {
    // Same escalation as the mismatch case, but the non-proof is an ok:false
    // error reply. The `response.ok` guard in #confirmHostIdle must reject it.
    const { supervisor, queue } = await startHarness(
      "stuck-evaluate-bad-cancel:error",
    );
    expect(supervisor.epoch).toBe(1);
    const recovered = onceRecovered(supervisor);
    const settlement = capture(
      queue.submit(evaluateRequest("sleep:0", 1), { deadlineMs: 80 }),
    );
    expect(rejectionOf(await settlement)).toBeInstanceOf(
      KernelRequestTimeoutError,
    );
    await recovered;
    expect(supervisor.epoch).toBe(2);
    const health = await queue.submit(healthRequest());
    expect(health.ok).toBe(true);
  });

  it("invalidates requests queued across a supervisor epoch change", async () => {
    const { supervisor, queue, logPath } = await startHarness(
      "corrupt-control-after:0",
    );
    const recovered = onceRecovered(supervisor);
    const doomed = capture(queue.submit(evaluateRequest("sleep:0", 1)));
    expect(rejectionOf(await doomed)).toBeInstanceOf(KernelConnectionError);
    await until(() => supervisor.state !== "ready");
    const stale = evaluateRequest("sleep:0", 2);
    const staleSettlement = capture(queue.submit(stale));
    await recovered;
    const error = rejectionOf(await staleSettlement);
    expect(error).toBeInstanceOf(KernelEpochInvalidatedError);
    expect((error as KernelEpochInvalidatedError).submittedEpoch).toBe(1);
    expect((error as KernelEpochInvalidatedError).currentEpoch).toBe(2);
    expect(
      readLog(logPath).some((entry) => entry.requestId === stale.requestId),
    ).toBe(false);
    const health = await queue.submit(healthRequest());
    expect(health.ok).toBe(true);
  });

  it("flushes queued and in-flight requests when the supervisor stops", async () => {
    const { supervisor, queue } = await startHarness("respond");
    const first = capture(queue.submit(evaluateRequest("sleep:5000", 1)));
    const second = capture(queue.submit(evaluateRequest("sleep:0", 2)));
    supervisor.stop();
    expect(rejectionOf(await first)).toBeInstanceOf(KernelQueueClosedError);
    expect(rejectionOf(await second)).toBeInstanceOf(KernelQueueClosedError);
    expect(queue.depth).toBe(0);
    expect(queue.inFlightRequestId).toBeUndefined();
  });

  it("treats an oversized control frame as a per-request error, not corruption", async () => {
    const { queue } = await startHarness("respond");
    const oversized = {
      ...healthRequest(),
      padding: "x".repeat(5 * 1024 * 1024),
    } as unknown as KernelRequest;
    const settlement = capture(queue.submit(oversized));
    const error = rejectionOf(await settlement);
    expect(error).toBeInstanceOf(ControlFrameError);
    const health = await queue.submit(healthRequest());
    expect(health.ok).toBe(true);
  });

  it("dispatches a follow-up submitted from the previous request's completion (no lost wakeup)", async () => {
    const { queue, logPath } = await startHarness("respond");
    const first = evaluateRequest("sleep:0", 1);
    const second = evaluateRequest("sleep:0", 2);
    // Submit `second` synchronously from `first`'s resolution — the exact
    // window where the drain has already observed an empty queue but has not
    // yet cleared its pumping flag. A short deadline turns a lost wakeup into a
    // fast, deterministic rejection instead of a hung test.
    const secondResponse = await new Promise<KernelResponse>(
      (resolve, reject) => {
        void queue.submit(first).then(() => {
          queue.submit(second, { deadlineMs: 1_000 }).then(resolve, reject);
        }, reject);
      },
    );
    expect(secondResponse.ok).toBe(true);
    expect(secondResponse.requestId).toBe(second.requestId);
    // No third request and no supervisor event pumped the queue — only the
    // re-pump after `first` completed could have dispatched `second`.
    const evaluates = readLog(logPath).filter(
      (entry) => entry.method === "evaluate_document",
    );
    expect(evaluates.map((entry) => entry.requestId)).toEqual([
      first.requestId,
      second.requestId,
    ]);
  });

  it("rejects duplicate request ids while the original is still queued", async () => {
    const { queue } = await startHarness("respond");
    const first = capture(queue.submit(evaluateRequest("sleep:200", 1)));
    const request = evaluateRequest("sleep:0", 2);
    const second = capture(queue.submit(request));
    const duplicate = capture(queue.submit(request));
    expect(rejectionOf(await duplicate)).toBeInstanceOf(KernelQueueError);
    expect((await first).status).toBe("resolved");
    expect((await second).status).toBe("resolved");
  });

  it("preserves a structured feasibility repair payload through client and queue", async () => {
    const { queue } = await startHarness("feasibility-error");
    const request = evaluateRequest("oversized-fillet", 1);
    if (request.method !== "evaluate_document")
      throw new Error("expected evaluate request fixture");
    const operation = request.operations[0];
    if (!operation) throw new Error("missing operation fixture");

    const response = await queue.submit(request);
    expect(response.ok).toBe(false);
    if (response.ok) return;
    expect(response.error.code).toBe("GEOMETRY_FAILED");
    expect(response.error.operationId).toBe(operation.id);
    expect(response.error.details).toEqual({
      requestedRadius: 20,
      maxFeasibleRadius: 4.98,
      feasibilityProbe: {
        parameter: "radius",
        requested: 20,
        maxFeasible: 4.98,
        bound: "tested-lower-bound",
        attempts: 12,
      },
    });
  });
});
