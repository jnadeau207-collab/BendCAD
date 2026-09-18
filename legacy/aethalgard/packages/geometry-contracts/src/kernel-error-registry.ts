import type { z } from "zod";

import type { kernelErrorSchema } from "./kernel-protocol.js";

/**
 * Structured metadata for every error the kernel can raise (doc 06 §11). The
 * kernel host emits one of a closed set of wire `code`s (kernelErrorSchema), and
 * kernel responses are validated against that enum at the process boundary, so
 * an unregistered code can never cross. This registry is the SINGLE source of
 * that structured meaning: keyed on the wire enum, it cannot drift from what the
 * host emits, and the `Record<KernelErrorCode, …>` type makes a missing entry a
 * compile error. `severity`/`retryable`/`agentHint` are derived TS-side from the
 * received wire code — the host never has to duplicate (and so never desyncs)
 * this table.
 *
 * `retryable` distinguishes a transient condition worth resubmitting (busy,
 * cancelled, a transient I/O fault) from a design defect the agent must repair
 * by editing its proposal (a bad selector, an infeasible radius). `agentHint`
 * is the machine-readable repair suggestion Gate 4 depends on.
 */

export type KernelErrorCode = z.infer<typeof kernelErrorSchema>["code"];
export type KernelErrorSeverity = "error" | "warning";

export interface KernelErrorDescriptor {
  readonly severity: KernelErrorSeverity;
  readonly retryable: boolean;
  readonly agentHint: string;
}

export const kernelErrorRegistry: Record<
  KernelErrorCode,
  KernelErrorDescriptor
> = {
  INVALID_REQUEST: {
    severity: "error",
    retryable: false,
    agentHint:
      "The request was malformed; correct the operation's structure before resubmitting.",
  },
  REFERENCE_MISSING: {
    severity: "error",
    retryable: false,
    agentHint:
      "The selector matched no entity; broaden the query or confirm the referenced operation still produces it.",
  },
  REFERENCE_AMBIGUOUS: {
    severity: "error",
    retryable: false,
    agentHint:
      "The selector matched several entities; add an anchor or a narrowing filter so it resolves to exactly one.",
  },
  GEOMETRY_FAILED: {
    severity: "error",
    retryable: false,
    agentHint:
      "The kernel could not build this operation with these parameters; adjust them (for example a smaller fillet radius or offset distance).",
  },
  CANCELLED: {
    severity: "warning",
    retryable: true,
    agentHint: "The request was cancelled; resubmit it to try again.",
  },
  TIMEOUT: {
    severity: "error",
    retryable: true,
    agentHint:
      "This operation exceeded its time budget and was stopped; simplify or split it (fewer features, coarser detail) before resubmitting.",
  },
  BUSY: {
    severity: "warning",
    retryable: true,
    agentHint: "The kernel was busy; retry after a short backoff.",
  },
  IO_ERROR: {
    severity: "error",
    retryable: true,
    agentHint:
      "A transient I/O fault occurred while talking to the kernel; retrying may succeed.",
  },
  UNSUPPORTED_OPERATION: {
    severity: "error",
    retryable: false,
    agentHint:
      "This operation or parameter is not supported by the current kernel; use a supported alternative.",
  },
  INTERNAL_ERROR: {
    severity: "error",
    retryable: false,
    agentHint:
      "The kernel hit an internal fault; this is not repairable by editing the operation and should be surfaced, not retried.",
  },
};

/** The structured descriptor for a kernel wire error code. */
export function describeKernelError(
  code: KernelErrorCode,
): KernelErrorDescriptor {
  return kernelErrorRegistry[code];
}
