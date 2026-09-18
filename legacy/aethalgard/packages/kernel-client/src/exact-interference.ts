import {
  exactInterferenceRequestSchema,
  exactInterferenceSuccessResponseSchema,
  kernelProtocolVersion,
  type ExactInterferenceRequest,
  type ExactInterferenceSuccessResponse,
  type KernelRequest,
  type KernelResponse,
} from "@aeth/geometry-contracts";

import type { KernelQueueSubmitOptions } from "./request-queue.js";

/** Queue seam used by exact interference and scripted qualification tests. */
export interface ExactInterferenceQueue {
  submit(
    request: KernelRequest,
    options?: KernelQueueSubmitOptions,
  ): Promise<KernelResponse>;
}

/**
 * Builds the canonical exact-interference request envelope. Pair ordering and
 * endpoint identity are enforced by the shared geometry-contract schema.
 */
export function createExactInterferenceRequest(
  input: Omit<ExactInterferenceRequest, "protocolVersion" | "method">,
): ExactInterferenceRequest {
  return exactInterferenceRequestSchema.parse({
    protocolVersion: kernelProtocolVersion,
    method: "interference_exact",
    ...input,
  });
}

/**
 * Routes exact interference through the bounded, epoch-aware queue and
 * validates the dedicated success envelope before returning it to product
 * code. Native geometry remains the authority for the report and evidence.
 */
export async function submitExactInterference(
  queue: ExactInterferenceQueue,
  request: ExactInterferenceRequest,
  options: KernelQueueSubmitOptions = {},
): Promise<ExactInterferenceSuccessResponse> {
  const validatedRequest = exactInterferenceRequestSchema.parse(request);
  const response = await queue.submit(validatedRequest, options);
  return exactInterferenceSuccessResponseSchema.parse(response);
}
