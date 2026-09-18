import { randomUUID } from "node:crypto";

import {
  kernelProtocolVersion,
  kernelRequestSchema,
  planarSplitFixtureSchema,
  type MutationCaseResult,
  type PlanarSplitFixture,
} from "@aeth/geometry-contracts";

import type { NativeKernelClient } from "./native-kernel-client.js";

export class MutationCaseError extends Error {
  public constructor(message: string) {
    super(message);
    this.name = "MutationCaseError";
  }
}

export interface MutationCaseRequestOptions {
  /** Deterministic request identity for reproducible corpora. */
  readonly requestId?: string;
}

/**
 * Requests one real reference-mutation case from a live kernel host. The
 * returned payload keeps the entrant-visible snapshots and the history-derived
 * oracle in separate fields; callers that build tournament corpora must never
 * hand the `oracle` field to an entrant.
 */
export async function requestMutationCase(
  client: NativeKernelClient,
  fixture: PlanarSplitFixture,
  options: MutationCaseRequestOptions = {},
): Promise<MutationCaseResult> {
  const response = await client.request(
    kernelRequestSchema.parse({
      protocolVersion: kernelProtocolVersion,
      requestId: options.requestId ?? randomUUID(),
      method: "mutation_case",
      fixture: planarSplitFixtureSchema.parse(fixture),
    }),
  );
  if (!response.ok) {
    throw new MutationCaseError(
      `Kernel mutation case failed (${response.error.code}): ${response.error.message}`,
    );
  }
  if (response.result.type !== "mutation_case") {
    throw new MutationCaseError(
      `Kernel returned an unexpected result type: ${response.result.type}`,
    );
  }
  return response.result;
}
