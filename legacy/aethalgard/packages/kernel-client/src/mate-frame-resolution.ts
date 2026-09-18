import {
  resolveMateFramesKernelResponseSchema,
  type KernelRequest,
  type KernelResponse,
  type ResolveMateFramesKernelRequest,
  type ResolveMateFramesKernelResponse,
} from "@aeth/geometry-contracts";

import type { KernelQueueSubmitOptions } from "./request-queue.js";

/** Public queue seam needed by exact-frame coordination and scripted tests. */
export interface MateFrameResolutionQueue {
  submit(
    request: KernelRequest,
    options?: KernelQueueSubmitOptions,
  ): Promise<KernelResponse>;
}

/**
 * Submits ASM-005 exact endpoint work through the same bounded, epoch-aware
 * queue as every other kernel operation.
 *
 * `KernelRequestQueue` predates the additive assembly method and its public
 * generic still names the historical `KernelRequest` union. The queue's
 * runtime behavior is method-agnostic and the native client now parses the
 * combined transport. Keep the single narrow cast here, validate the returned
 * specialized response again, and never let product code call the raw client
 * for endpoint resolution.
 */
export async function submitMateFrameResolution(
  queue: MateFrameResolutionQueue,
  request: ResolveMateFramesKernelRequest,
  options: KernelQueueSubmitOptions = {},
): Promise<ResolveMateFramesKernelResponse> {
  const response = await queue.submit(
    request as unknown as KernelRequest,
    options,
  );
  return resolveMateFramesKernelResponseSchema.parse(response);
}
