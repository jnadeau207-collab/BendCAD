import { randomUUID } from "node:crypto";

import {
  kernelProtocolVersion,
  type KernelRequest,
  type KernelResponse,
} from "@aeth/geometry-contracts";
import { describe, expect, it, vi } from "vitest";

import {
  DefinitionEvaluationCache,
  DefinitionEvaluationError,
  KernelQueueTimeoutError,
  type DefinitionEvaluationRequestInit,
  type KernelQueueSubmitOptions,
  type KernelRequestQueue,
} from "../src/index.js";

interface PendingSubmit {
  readonly request: KernelRequest;
  readonly resolve: (response: KernelResponse) => void;
  readonly reject: (error: unknown) => void;
}

type KernelErrorPayload = Extract<KernelResponse, { ok: false }>["error"];

function createFakeQueue() {
  const pending: PendingSubmit[] = [];
  const submit = vi.fn(
    (request: KernelRequest, _options?: KernelQueueSubmitOptions) =>
      new Promise<KernelResponse>((resolve, reject) => {
        pending.push({ request, resolve, reject });
      }),
  );
  return { submit, pending };
}

function fakeCache() {
  const { submit, pending } = createFakeQueue();
  // Only `submit` is ever called by DefinitionEvaluationCache; the cast
  // avoids depending on KernelRequestQueue's private supervisor wiring.
  const queue = { submit } as unknown as KernelRequestQueue;
  return { cache: new DefinitionEvaluationCache(queue), submit, pending };
}

function requestInit(
  definitionId: string,
  revisionHash: string,
): DefinitionEvaluationRequestInit {
  return { definitionId, revisionHash, operations: [] };
}

function okResponse(
  requestId: string,
  definitionId: string,
  revisionHash: string,
  epoch = 1,
): KernelResponse {
  return {
    protocolVersion: kernelProtocolVersion,
    requestId,
    ok: true,
    result: {
      type: "definition_evaluation",
      definitionId,
      revisionHash,
      epoch,
      bodies: [],
    },
  };
}

function errorResponse(
  requestId: string,
  code: KernelErrorPayload["code"],
  message: string,
): KernelResponse {
  return {
    protocolVersion: kernelProtocolVersion,
    requestId,
    ok: false,
    error: { code, message },
  };
}

function takePending(
  pending: readonly PendingSubmit[],
  index: number,
): PendingSubmit {
  const entry = pending[index];
  if (!entry) throw new Error(`missing pending submit at index ${index}`);
  return entry;
}

function byDefinition(
  entries: readonly { definitionId: string; revisionHash: string }[],
) {
  return [...entries].sort((a, b) =>
    a.definitionId.localeCompare(b.definitionId),
  );
}

describe("definition evaluation cache", () => {
  it("collapses two concurrent identical evaluate() calls into one submit call and resolves both with the same result", async () => {
    const { cache, submit, pending } = fakeCache();
    const definitionId = randomUUID();
    const init = requestInit(definitionId, "rev-1");

    const first = cache.evaluate(init);
    const second = cache.evaluate(init);
    expect(submit).toHaveBeenCalledTimes(1);

    const call = takePending(pending, 0);
    call.resolve(okResponse(call.request.requestId, definitionId, "rev-1"));

    const [firstResult, secondResult] = await Promise.all([first, second]);
    expect(firstResult).toBe(secondResult);
    expect(firstResult).toEqual({
      definitionId,
      revisionHash: "rev-1",
      epoch: 1,
      bodies: [],
    });
  });

  it("serves a third evaluate() call for an already-resolved key from cache, with zero additional submit calls", async () => {
    const { cache, submit, pending } = fakeCache();
    const definitionId = randomUUID();

    const first = cache.evaluate(requestInit(definitionId, "rev-1"));
    const call = takePending(pending, 0);
    call.resolve(okResponse(call.request.requestId, definitionId, "rev-1"));
    const resolved = await first;

    const third = await cache.evaluate(requestInit(definitionId, "rev-1"));
    expect(submit).toHaveBeenCalledTimes(1);
    expect(third).toBe(resolved);
  });

  it("issues a fresh submit for a different revisionHash on the same definitionId and returns the new revision", async () => {
    const { cache, submit, pending } = fakeCache();
    const definitionId = randomUUID();

    const first = cache.evaluate(requestInit(definitionId, "rev-1"));
    const firstCall = takePending(pending, 0);
    firstCall.resolve(
      okResponse(firstCall.request.requestId, definitionId, "rev-1"),
    );
    await first;

    const second = cache.evaluate(requestInit(definitionId, "rev-2"));
    expect(submit).toHaveBeenCalledTimes(2);
    const secondCall = takePending(pending, 1);
    secondCall.resolve(
      okResponse(secondCall.request.requestId, definitionId, "rev-2"),
    );

    const result = await second;
    expect(result.revisionHash).toBe("rev-2");
  });

  it("does not let an earlier-issued request's late settlement clobber a later-issued one's resolved entry", async () => {
    const { cache, pending } = fakeCache();
    const definitionId = randomUUID();

    const requestA = cache.evaluate(requestInit(definitionId, "rev-A"));
    const requestB = cache.evaluate(requestInit(definitionId, "rev-B"));
    const callA = takePending(pending, 0);
    const callB = takePending(pending, 1);

    callB.resolve(okResponse(callB.request.requestId, definitionId, "rev-B"));
    const resultB = await requestB;
    expect(resultB.revisionHash).toBe("rev-B");
    expect(cache.cachedKeys).toEqual([{ definitionId, revisionHash: "rev-B" }]);

    callA.resolve(okResponse(callA.request.requestId, definitionId, "rev-A"));
    const resultA = await requestA;
    // The caller who asked for revision A still gets revision A's own result
    // — only the SHARED resolved cache refuses the stale, out-of-order clobber.
    expect(resultA.revisionHash).toBe("rev-A");
    expect(cache.cachedKeys).toEqual([{ definitionId, revisionHash: "rev-B" }]);
  });

  it("does not cache a generic submit rejection, so the next call for the same key issues a fresh submit", async () => {
    const { cache, submit, pending } = fakeCache();
    const definitionId = randomUUID();

    const first = cache.evaluate(requestInit(definitionId, "rev-1"));
    const firstCall = takePending(pending, 0);
    firstCall.reject(new Error("kernel host crashed"));
    await expect(first).rejects.toBeInstanceOf(DefinitionEvaluationError);
    await expect(first).rejects.toThrow("kernel host crashed");

    const second = cache.evaluate(requestInit(definitionId, "rev-1"));
    expect(submit).toHaveBeenCalledTimes(2);
    const secondCall = takePending(pending, 1);
    secondCall.resolve(
      okResponse(secondCall.request.requestId, definitionId, "rev-1"),
    );
    await expect(second).resolves.toMatchObject({ revisionHash: "rev-1" });
    expect(cache.cachedKeys).toEqual([{ definitionId, revisionHash: "rev-1" }]);
  });

  it("does not cache a KernelQueueError rejection either, and passes it through unwrapped", async () => {
    const { cache, submit, pending } = fakeCache();
    const definitionId = randomUUID();

    const first = cache.evaluate(requestInit(definitionId, "rev-1"));
    const firstCall = takePending(pending, 0);
    firstCall.reject(
      new KernelQueueTimeoutError(
        "Kernel request exceeded its deadline while queued",
      ),
    );
    await expect(first).rejects.toBeInstanceOf(KernelQueueTimeoutError);
    await expect(first).rejects.not.toBeInstanceOf(DefinitionEvaluationError);

    const second = cache.evaluate(requestInit(definitionId, "rev-1"));
    expect(submit).toHaveBeenCalledTimes(2);
    const secondCall = takePending(pending, 1);
    secondCall.resolve(
      okResponse(secondCall.request.requestId, definitionId, "rev-1"),
    );
    await expect(second).resolves.toMatchObject({ revisionHash: "rev-1" });
  });

  it("rejects with DefinitionEvaluationError carrying the kernel error's code and message, mirroring MutationCaseError's format", async () => {
    const { cache, pending } = fakeCache();
    const definitionId = randomUUID();
    const code: KernelErrorPayload["code"] = "GEOMETRY_FAILED";
    const message = "definition body failed to rebuild";

    const settlement = cache.evaluate(requestInit(definitionId, "rev-1"));
    const call = takePending(pending, 0);
    call.resolve(errorResponse(call.request.requestId, code, message));

    await expect(settlement).rejects.toBeInstanceOf(DefinitionEvaluationError);
    await expect(settlement).rejects.toThrow(
      `Kernel definition evaluation failed (${code}): ${message}`,
    );
  });

  it("cachedKeys reflects exactly the resolved (definitionId, revisionHash) pairs, no more and no less", async () => {
    const { cache, pending } = fakeCache();
    expect(cache.cachedKeys).toEqual([]);

    const definitionA = randomUUID();
    const definitionB = randomUUID();
    const evalA = cache.evaluate(requestInit(definitionA, "rev-1"));
    const evalB = cache.evaluate(requestInit(definitionB, "rev-9"));
    const callA = takePending(pending, 0);
    const callB = takePending(pending, 1);
    callA.resolve(okResponse(callA.request.requestId, definitionA, "rev-1"));
    callB.resolve(okResponse(callB.request.requestId, definitionB, "rev-9"));
    await Promise.all([evalA, evalB]);

    expect(byDefinition(cache.cachedKeys)).toEqual(
      byDefinition([
        { definitionId: definitionA, revisionHash: "rev-1" },
        { definitionId: definitionB, revisionHash: "rev-9" },
      ]),
    );

    const evalANextRevision = cache.evaluate(requestInit(definitionA, "rev-2"));
    const callANext = takePending(pending, 2);
    callANext.resolve(
      okResponse(callANext.request.requestId, definitionA, "rev-2"),
    );
    await evalANextRevision;

    expect(cache.cachedKeys).toHaveLength(2);
    expect(byDefinition(cache.cachedKeys)).toEqual(
      byDefinition([
        { definitionId: definitionA, revisionHash: "rev-2" },
        { definitionId: definitionB, revisionHash: "rev-9" },
      ]),
    );
  });

  it("invalidate(definitionId) clears the resolved cache so the same key issues a fresh submit", async () => {
    const { cache, submit, pending } = fakeCache();
    const definitionId = randomUUID();

    const first = cache.evaluate(requestInit(definitionId, "rev-1"));
    const firstCall = takePending(pending, 0);
    firstCall.resolve(
      okResponse(firstCall.request.requestId, definitionId, "rev-1"),
    );
    await first;
    expect(cache.cachedKeys).toEqual([{ definitionId, revisionHash: "rev-1" }]);

    cache.invalidate(definitionId);
    expect(cache.cachedKeys).toEqual([]);

    const second = cache.evaluate(requestInit(definitionId, "rev-1"));
    expect(submit).toHaveBeenCalledTimes(2);
    const secondCall = takePending(pending, 1);
    secondCall.resolve(
      okResponse(secondCall.request.requestId, definitionId, "rev-1"),
    );
    await expect(second).resolves.toMatchObject({ revisionHash: "rev-1" });
  });

  it("clear() drops every resolved entry", async () => {
    const { cache, pending } = fakeCache();
    const definitionA = randomUUID();
    const definitionB = randomUUID();

    const evalA = cache.evaluate(requestInit(definitionA, "rev-1"));
    const evalB = cache.evaluate(requestInit(definitionB, "rev-1"));
    const callA = takePending(pending, 0);
    const callB = takePending(pending, 1);
    callA.resolve(okResponse(callA.request.requestId, definitionA, "rev-1"));
    callB.resolve(okResponse(callB.request.requestId, definitionB, "rev-1"));
    await Promise.all([evalA, evalB]);
    expect(cache.cachedKeys).toHaveLength(2);

    cache.clear();
    expect(cache.cachedKeys).toEqual([]);
  });
});
