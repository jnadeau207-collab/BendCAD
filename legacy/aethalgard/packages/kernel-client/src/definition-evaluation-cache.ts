import { randomUUID } from "node:crypto";

import {
  kernelProtocolVersion,
  kernelRequestSchema,
  type wireOperationSchema,
  type ElementNameEntry,
  type MeshDescriptor,
  type ShapeProbes,
  type TopologySnapshot,
} from "@aeth/geometry-contracts";

import { KernelQueueError } from "./request-queue.js";
import type {
  KernelQueueSubmitOptions,
  KernelRequestQueue,
} from "./request-queue.js";

// operations.ts exports the schema but not a named element type for it; derive
// one instead of adding an export to a file this capability does not own.
type WireOperation = ReturnType<typeof wireOperationSchema.parse>;

export class DefinitionEvaluationError extends Error {
  public constructor(message: string) {
    super(message);
    this.name = "DefinitionEvaluationError";
  }
}

export interface DefinitionEvaluationRequestInit {
  readonly definitionId: string;
  readonly revisionHash: string;
  readonly operations: readonly WireOperation[];
  readonly lodTier?: number;
  readonly includeTopology?: boolean;
  readonly includeElementNames?: boolean;
}

export interface DefinitionEvaluationBody {
  readonly definitionBodyId: string;
  readonly operationId: string;
  readonly outputIndex: number;
  readonly probes: ShapeProbes;
  readonly mesh: MeshDescriptor;
  readonly collisionShapeCacheKey: string;
  readonly topology?: TopologySnapshot;
  readonly elementNames?: readonly ElementNameEntry[];
}

export interface DefinitionEvaluationResult {
  readonly definitionId: string;
  readonly revisionHash: string;
  readonly epoch: number;
  readonly bodies: readonly DefinitionEvaluationBody[];
}

interface InFlightEntry {
  readonly sequence: number;
  readonly promise: Promise<DefinitionEvaluationResult>;
}

/**
 * Enforces assembly doc §4.1 ("the kernel evaluates each unique definition
 * once per revision hash") on the client side. `native/kernel-host` deliberately
 * answers every `evaluate_definition` request it receives with no memo of its
 * own; this cache is the only place N occurrences of one definition collapse
 * into one `KernelRequestQueue.submit` call. It never talks to the host
 * directly outside the queue.
 */
export class DefinitionEvaluationCache {
  readonly #queue: KernelRequestQueue;
  readonly #inFlight = new Map<string, InFlightEntry>();
  readonly #resolved = new Map<string, DefinitionEvaluationResult>();
  readonly #sequences = new Map<string, number>();

  public constructor(queue: KernelRequestQueue) {
    this.#queue = queue;
  }

  public get cachedKeys(): readonly {
    definitionId: string;
    revisionHash: string;
  }[] {
    return [...this.#resolved.values()].map((result) => ({
      definitionId: result.definitionId,
      revisionHash: result.revisionHash,
    }));
  }

  public evaluate(
    init: DefinitionEvaluationRequestInit,
    options?: Pick<KernelQueueSubmitOptions, "deadlineMs" | "signal">,
  ): Promise<DefinitionEvaluationResult> {
    const key = `${init.definitionId}:${init.revisionHash}`;
    const inFlight = this.#inFlight.get(key);
    if (inFlight) return inFlight.promise;

    const resolved = this.#resolved.get(init.definitionId);
    if (resolved && resolved.revisionHash === init.revisionHash) {
      return Promise.resolve(resolved);
    }

    const sequence = this.#nextSequence(init.definitionId);
    const tracked: Promise<DefinitionEvaluationResult> = this.#dispatch(
      init,
      sequence,
      options,
    ).finally(() => {
      this.#inFlight.delete(key);
    });
    this.#inFlight.set(key, { sequence, promise: tracked });
    return tracked;
  }

  /**
   * Drops the cache for one definition and fences its sequence so any
   * in-flight request for the revision it just dropped can no longer win the
   * race in `#commitIfLatest`. Does not touch `KernelRequestQueue` — the queue
   * owns cancellation via `AbortSignal`.
   */
  public invalidate(definitionId: string): void {
    this.#resolved.delete(definitionId);
    this.#nextSequence(definitionId);
  }

  public clear(): void {
    for (const definitionId of this.#sequences.keys()) {
      this.#nextSequence(definitionId);
    }
    this.#resolved.clear();
  }

  async #dispatch(
    init: DefinitionEvaluationRequestInit,
    sequence: number,
    options:
      Pick<KernelQueueSubmitOptions, "deadlineMs" | "signal"> | undefined,
  ): Promise<DefinitionEvaluationResult> {
    const request = kernelRequestSchema.parse({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "evaluate_definition",
      definitionId: init.definitionId,
      revisionHash: init.revisionHash,
      operations: init.operations,
      ...(init.lodTier !== undefined ? { lodTier: init.lodTier } : {}),
      ...(init.includeTopology !== undefined
        ? { includeTopology: init.includeTopology }
        : {}),
      ...(init.includeElementNames !== undefined
        ? { includeElementNames: init.includeElementNames }
        : {}),
    });

    let response;
    try {
      response = await this.#queue.submit(request, options);
    } catch (error) {
      // Queue errors (full/timeout/cancelled/epoch-invalidated/closed) carry
      // information callers distinguish on (e.g. a cancelled drag vs a real
      // geometry failure); pass them through unchanged instead of masking
      // them behind DefinitionEvaluationError.
      if (error instanceof KernelQueueError) throw error;
      throw new DefinitionEvaluationError(
        error instanceof Error ? error.message : String(error),
      );
    }

    if (!response.ok) {
      throw new DefinitionEvaluationError(
        `Kernel definition evaluation failed (${response.error.code}): ${response.error.message}`,
      );
    }
    if (response.result.type !== "definition_evaluation") {
      throw new DefinitionEvaluationError(
        `Kernel returned an unexpected result type: ${response.result.type}`,
      );
    }

    const result: DefinitionEvaluationResult = {
      definitionId: response.result.definitionId,
      revisionHash: response.result.revisionHash,
      epoch: response.result.epoch,
      bodies: response.result.bodies.map((body): DefinitionEvaluationBody => ({
        definitionBodyId: body.definitionBodyId,
        operationId: body.operationId,
        outputIndex: body.outputIndex ?? 0,
        probes: body.probes,
        mesh: body.mesh,
        collisionShapeCacheKey: body.collisionShapeCacheKey,
        ...(body.topology !== undefined ? { topology: body.topology } : {}),
        ...(body.elementNames !== undefined
          ? { elementNames: body.elementNames }
          : {}),
      })),
    };

    this.#commitIfLatest(init.definitionId, sequence, result);
    return result;
  }

  #nextSequence(definitionId: string): number {
    const next = (this.#sequences.get(definitionId) ?? 0) + 1;
    this.#sequences.set(definitionId, next);
    return next;
  }

  /**
   * A settlement only wins the resolved cache if no newer request (a cold
   * dispatch, `invalidate`, or `clear`) has been issued for this definition
   * since it was stamped. Sequence numbers only increase, so a stale
   * evaluation that answers after a newer one — or after an invalidation —
   * is silently dropped rather than clobbering the current result.
   */
  #commitIfLatest(
    definitionId: string,
    sequence: number,
    result: DefinitionEvaluationResult,
  ): void {
    if (sequence < (this.#sequences.get(definitionId) ?? 0)) return;
    this.#resolved.set(definitionId, result);
  }
}
