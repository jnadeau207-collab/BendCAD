import { z } from "zod";

import {
  endpointResolutionOutcomeSchema,
  mateFrameEndpointRequestSchema,
} from "./assembly-mate-frame.js";
import {
  kernelErrorSchema,
  kernelProtocolVersion,
  kernelRequestSchema,
  kernelResponseSchema,
  type KernelRequest,
  type KernelResponse,
} from "./kernel-protocol.js";
import {
  maxDocumentOperationsBytes,
  operationsSerializedByteLength,
  wireOperationSchema,
} from "./operations.js";

/**
 * Live kernel transport for ASM-005 exact endpoint resolution.
 *
 * This is deliberately composed beside the historical kernel protocol module
 * rather than duplicating its ordinary request/result variants. The combined
 * transport schemas below are the process-boundary authority used by the
 * kernel client: every pre-existing method remains governed by
 * `kernelRequestSchema`/`kernelResponseSchema`, while `resolve_mate_frames`
 * adds one definition-scoped request and one exact result.
 */
export const resolveMateFramesKernelRequestSchema = z
  .object({
    protocolVersion: z.literal(kernelProtocolVersion),
    requestId: z.string().uuid(),
    method: z.literal("resolve_mate_frames"),
    definitionId: z.string().uuid(),
    revisionHash: z.string().min(1).max(128),
    operations: z.array(wireOperationSchema).max(100_000),
    endpoints: z.array(mateFrameEndpointRequestSchema).min(1).max(4096),
  })
  .strict()
  .superRefine((request, context) => {
    const bytes = operationsSerializedByteLength(request.operations);
    if (bytes > maxDocumentOperationsBytes) {
      context.addIssue({
        code: "custom",
        message: `Definition operations serialize to ${bytes} bytes, exceeding the ${maxDocumentOperationsBytes}-byte document-size envelope`,
        path: ["operations"],
      });
    }
    const endpointIds = new Set<string>();
    for (const [index, endpoint] of request.endpoints.entries()) {
      if (endpointIds.has(endpoint.requestId)) {
        context.addIssue({
          code: "custom",
          message: `Duplicate endpoint request id ${endpoint.requestId}`,
          path: ["endpoints", index, "requestId"],
        });
      }
      endpointIds.add(endpoint.requestId);
    }
  });
export type ResolveMateFramesKernelRequest = z.infer<
  typeof resolveMateFramesKernelRequestSchema
>;

export const resolveMateFramesKernelResultSchema = z
  .object({
    type: z.literal("mate_frame_resolution"),
    definitionId: z.string().uuid(),
    revisionHash: z.string().min(1).max(128),
    outcomes: z.array(endpointResolutionOutcomeSchema).min(1).max(4096),
  })
  .strict()
  .superRefine((result, context) => {
    const outcomeIds = new Set<string>();
    for (const [index, outcome] of result.outcomes.entries()) {
      if (outcomeIds.has(outcome.requestId)) {
        context.addIssue({
          code: "custom",
          message: `Duplicate endpoint outcome id ${outcome.requestId}`,
          path: ["outcomes", index, "requestId"],
        });
      }
      outcomeIds.add(outcome.requestId);
    }
  });
export type ResolveMateFramesKernelResult = z.infer<
  typeof resolveMateFramesKernelResultSchema
>;

export const resolveMateFramesKernelResponseSchema = z.discriminatedUnion(
  "ok",
  [
    z
      .object({
        protocolVersion: z.literal(kernelProtocolVersion),
        requestId: z.string().uuid(),
        ok: z.literal(true),
        result: resolveMateFramesKernelResultSchema,
      })
      .strict(),
    z
      .object({
        protocolVersion: z.literal(kernelProtocolVersion),
        requestId: z.string().uuid(),
        ok: z.literal(false),
        error: kernelErrorSchema,
      })
      .strict(),
  ],
);
export type ResolveMateFramesKernelResponse = z.infer<
  typeof resolveMateFramesKernelResponseSchema
>;

/** One process protocol, including the exact assembly endpoint method. */
export const kernelTransportRequestSchema: z.ZodType<
  KernelRequest | ResolveMateFramesKernelRequest
> = z.union([kernelRequestSchema, resolveMateFramesKernelRequestSchema]);
export type KernelTransportRequest =
  KernelRequest | ResolveMateFramesKernelRequest;

/** One process response protocol, including exact mate-frame outcomes. */
export const kernelTransportResponseSchema: z.ZodType<
  KernelResponse | ResolveMateFramesKernelResponse
> = z.union([kernelResponseSchema, resolveMateFramesKernelResponseSchema]);
export type KernelTransportResponse =
  KernelResponse | ResolveMateFramesKernelResponse;
