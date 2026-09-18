/**
 * ASM-003 — `evaluate_definition` end to end, over stdio, against the real
 * kernel host.
 *
 * packages/geometry-contracts/test/kernel-protocol.test.ts proves the wire
 * SHAPE (the request accepts/rejects, the response's strict fields). It
 * cannot prove the native dispatch honors the identity/determinism contract
 * assembly doc 07 §4.1 depends on: that `definitionBodyId` really is the
 * operation's own authored `outputBodyId` rather than a freshly minted one,
 * that `collisionShapeCacheKey` really is the documented
 * `${revisionHash}:${definitionBodyId}` composition, that two requests for the
 * same revision answer byte-identically, that an edited revision answers
 * differently, and — the load-bearing exit criterion this whole capability is
 * measured against — that `DefinitionEvaluationCache` collapses many
 * concurrent callers asking for the same `{definitionId, revisionHash}` into
 * exactly ONE native dispatch ("one evaluated definition displays 1000
 * uniquely placed occurrences while allocating one geometry resource").
 */
import { createHash, randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";

import {
  createBoxOperationSchema,
  kernelProtocolVersion,
  kernelRequestSchema,
  maxDocumentOperationsBytes,
  operationsSerializedByteLength,
  type CreateBoxOperation,
  type KernelRequest,
  type KernelResponse,
  type MeshDescriptor,
  type WireOperation,
} from "@aeth/geometry-contracts";
import { afterEach, expect, it } from "vitest";

import { DefinitionEvaluationCache } from "../src/definition-evaluation-cache.js";
import {
  KernelRequestQueue,
  KernelSupervisor,
  type KernelQueueSubmitOptions,
} from "../src/index.js";
import { nativeDescribe } from "./native-gate.js";

const executable = process.env.AETH_KERNEL_HOST_PATH;
const describeNative = nativeDescribe();
const supervisors: KernelSupervisor[] = [];
const queues: KernelRequestQueue[] = [];

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

/** A small `create_box` definition — deliberately tiny so req 6's 1000 concurrent evaluations stay cheap. */
const fixture = JSON.parse(
  readFileSync(
    new URL(
      "../../../fixtures/geometry/definition-evaluation-bolt.json",
      import.meta.url,
    ),
    "utf8",
  ),
) as { readonly operation: unknown };

function baseBoxOperation(): CreateBoxOperation {
  return createBoxOperationSchema.parse(fixture.operation);
}

function withWidth(
  operation: CreateBoxOperation,
  width: number,
): CreateBoxOperation {
  return createBoxOperationSchema.parse({
    ...operation,
    parameters: { ...operation.parameters, width },
  });
}

/**
 * The kernel treats `revisionHash` as an opaque cache-line label it never
 * recomputes (kernel-protocol.ts). Hashing the operations themselves mirrors
 * what a real upstream minter would do and gives this suite the property it
 * needs for free: identical operations hash identically (req 3), an edited
 * operation hashes differently (req 4).
 */
function revisionHashOf(operations: readonly WireOperation[]): string {
  return createHash("sha256").update(JSON.stringify(operations)).digest("hex");
}

/**
 * Wraps a REAL queue and counts `submit` calls without touching the queue's
 * private dispatch state — the spy this suite's most important assertion
 * (req 6) needs, since a `KernelRequestQueue` cannot be duck-typed (its
 * dispatch state is `#private`, so only a subclass can wrap its public API).
 */
class CountingKernelRequestQueue extends KernelRequestQueue {
  public submitCount = 0;

  public override submit(
    request: KernelRequest,
    options: KernelQueueSubmitOptions = {},
  ): Promise<KernelResponse> {
    this.submitCount += 1;
    return super.submit(request, options);
  }
}

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

function startQueue(supervisor: KernelSupervisor): KernelRequestQueue {
  const queue = new KernelRequestQueue(supervisor, {
    defaultDeadlineMs: 120_000,
  });
  queues.push(queue);
  return queue;
}

function evaluateDefinitionRequest(
  params: Readonly<{
    definitionId: string;
    revisionHash: string;
    operations: readonly WireOperation[];
  }>,
): KernelRequest {
  return kernelRequestSchema.parse({
    protocolVersion: kernelProtocolVersion,
    requestId: randomUUID(),
    method: "evaluate_definition",
    definitionId: params.definitionId,
    revisionHash: params.revisionHash,
    operations: params.operations,
  });
}

function evaluateDefinition(
  queue: KernelRequestQueue,
  params: Readonly<{
    definitionId: string;
    revisionHash: string;
    operations: readonly WireOperation[];
  }>,
): Promise<KernelResponse> {
  return queue.submit(evaluateDefinitionRequest(params));
}

/** Extracts the single body a definition evaluation must return, or fails loudly naming what came back instead. */
function onlyDefinitionBody(response: KernelResponse) {
  if (!response.ok) {
    throw new Error(
      `evaluate_definition failed (${response.error.code}): ${response.error.message}`,
    );
  }
  if (response.result.type !== "definition_evaluation") {
    throw new Error(`unexpected kernel result type: ${response.result.type}`);
  }
  const [body, ...rest] = response.result.bodies;
  if (!body || rest.length > 0) {
    throw new Error(
      `expected exactly one body, got ${response.result.bodies.length}`,
    );
  }
  return body;
}

/** Drops the two fields the protocol documents as per-request-monotonic, not part of the geometry answer. */
function meshWithoutPerRequestFields(
  mesh: MeshDescriptor,
): Omit<MeshDescriptor, "streamSequence" | "epoch"> {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars -- rest-sibling destructure is how the two fields are dropped
  const { streamSequence: _streamSequence, epoch: _epoch, ...rest } = mesh;
  return rest;
}

afterEach(() => {
  for (const queue of queues.splice(0)) queue.close();
  for (const supervisor of supervisors.splice(0)) supervisor.stop();
});

describeNative("evaluate_definition over the real kernel host", () => {
  it("returns exactly one body whose definitionBodyId is the operation's own outputBodyId", async () => {
    const supervisor = await startSupervisor();
    const queue = startQueue(supervisor);
    const operation = baseBoxOperation();
    const operations = [operation];

    const response = await evaluateDefinition(queue, {
      definitionId: randomUUID(),
      revisionHash: revisionHashOf(operations),
      operations,
    });

    expect(response.ok).toBe(true);
    if (!response.ok || response.result.type !== "definition_evaluation") {
      throw new Error(`unexpected response: ${JSON.stringify(response)}`);
    }
    expect(response.result.type).toBe("definition_evaluation");
    expect(response.result.bodies).toHaveLength(1);
    const body = onlyDefinitionBody(response);
    // The load-bearing fact the whole viewport-instancing design depends on:
    // the definition's body identity IS the document-authored outputBodyId,
    // never a host-minted uuid.
    expect(body.definitionBodyId).toBe(operation.outputBodyId);
  });

  it("computes collisionShapeCacheKey as exactly `${revisionHash}:${definitionBodyId}`", async () => {
    const supervisor = await startSupervisor();
    const queue = startQueue(supervisor);
    const operations = [baseBoxOperation()];
    const revisionHash = revisionHashOf(operations);

    const response = await evaluateDefinition(queue, {
      definitionId: randomUUID(),
      revisionHash,
      operations,
    });
    const body = onlyDefinitionBody(response);

    expect(body.collisionShapeCacheKey).toBe(
      `${revisionHash}:${body.definitionBodyId}`,
    );
  });

  it("answers two separate native requests for the same definition byte-identically", async () => {
    // Bypasses DefinitionEvaluationCache deliberately (submits straight
    // through the queue) — this is the NATIVE path's own determinism
    // guarantee, independent of any client-side memoization.
    const supervisor = await startSupervisor();
    const queue = startQueue(supervisor);
    const definitionId = randomUUID();
    const operations = [baseBoxOperation()];
    const revisionHash = revisionHashOf(operations);

    const first = onlyDefinitionBody(
      await evaluateDefinition(queue, {
        definitionId,
        revisionHash,
        operations,
      }),
    );
    const second = onlyDefinitionBody(
      await evaluateDefinition(queue, {
        definitionId,
        revisionHash,
        operations,
      }),
    );

    expect(second.definitionBodyId).toBe(first.definitionBodyId);
    expect(second.collisionShapeCacheKey).toBe(first.collisionShapeCacheKey);
    expect(second.probes).toEqual(first.probes);
    // streamSequence/epoch are per-request-monotonic by design (mesh-payload.ts);
    // everything else describing the geometry itself must match exactly.
    expect(meshWithoutPerRequestFields(second.mesh)).toEqual(
      meshWithoutPerRequestFields(first.mesh),
    );
  });

  it("answers a different mesh checksum and volume once the revision hash changes", async () => {
    const supervisor = await startSupervisor();
    const queue = startQueue(supervisor);
    const definitionId = randomUUID();
    const original = baseBoxOperation();
    const edited = withWidth(original, original.parameters.width * 2);

    const firstOperations = [original];
    const secondOperations = [edited];

    const first = onlyDefinitionBody(
      await evaluateDefinition(queue, {
        definitionId,
        revisionHash: revisionHashOf(firstOperations),
        operations: firstOperations,
      }),
    );
    const second = onlyDefinitionBody(
      await evaluateDefinition(queue, {
        definitionId,
        revisionHash: revisionHashOf(secondOperations),
        operations: secondOperations,
      }),
    );

    // Same definitionId, same body identity — only the edited geometry itself
    // answers differently. This is the native-layer half of "definition edits
    // update all occurrences": the occurrence side never re-fetches unless
    // the answer actually changed.
    expect(second.definitionBodyId).toBe(first.definitionBodyId);
    expect(second.mesh.checksumCrc32).not.toBe(first.mesh.checksumCrc32);
    expect(second.probes.volumeMm3).not.toBe(first.probes.volumeMm3);
  });

  it("refuses oversized operations via kernelRequestSchema.parse before any request reaches the native host", () => {
    const operation = baseBoxOperation();
    // The JSON array contributes its brackets once and separators between
    // elements, so dividing by the one-element array size underestimates the
    // repeated payload. Calculate the repeated envelope exactly, then verify
    // the resulting array with the production serializer.
    const operationBytes = operationsSerializedByteLength([operation]) - 2;
    const count =
      Math.floor((maxDocumentOperationsBytes - 1) / (operationBytes + 1)) + 1;
    const operations: WireOperation[] = Array.from(
      { length: count },
      () => operation,
    );
    expect(operationsSerializedByteLength(operations)).toBeGreaterThan(
      maxDocumentOperationsBytes,
    );

    const result = kernelRequestSchema.safeParse({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "evaluate_definition",
      definitionId: randomUUID(),
      revisionHash: "rev-oversized-0000000000000001",
      operations,
    });

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.message).toMatch(/document-size envelope/);
    }
  });

  it("collapses 1000 concurrent evaluate() calls for the same definition into exactly one native dispatch", async () => {
    const supervisor = await startSupervisor();
    const queue = new CountingKernelRequestQueue(supervisor, {
      defaultDeadlineMs: 120_000,
    });
    queues.push(queue);
    const cache = new DefinitionEvaluationCache(queue);

    const definitionId = randomUUID();
    const operations = [baseBoxOperation()];
    const revisionHash = revisionHashOf(operations);

    const concurrentCallers = 1000;
    const results = await Promise.all(
      Array.from({ length: concurrentCallers }, () =>
        cache.evaluate({ definitionId, revisionHash, operations }),
      ),
    );

    const [first, ...rest] = results;
    if (!first) throw new Error("expected at least one evaluation result");
    for (const result of rest) {
      // Reference equality: every caller must observe the SAME settled
      // result object, not merely a deep-equal copy of it.
      expect(result).toBe(first);
    }
    expect(queue.submitCount).toBe(1);
  }, 30_000);
});
