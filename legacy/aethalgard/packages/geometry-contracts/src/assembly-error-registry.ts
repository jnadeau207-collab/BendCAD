import type { z } from "zod";

import type { assemblyErrorSchema } from "./assembly-protocol.js";

/**
 * Structured metadata for every error the assembly host can raise (plan
 * docs/plan/07-assemblies/00-assembly-system.md §6.4, §13; ASM-002). The
 * assembly host emits one of a closed set of wire `code`s
 * (assemblyErrorSchema), and assembly responses are validated against that
 * enum at the process boundary, so an unregistered code can never cross.
 * This registry is the SINGLE source of that structured meaning: keyed on
 * the wire enum, it cannot drift from what the host emits, and the
 * `Record<AssemblyErrorCode, …>` type makes a missing entry a compile
 * error. `severity`/`retryable`/`agentHint` are derived TS-side from the
 * received wire code — the host never has to duplicate (and so never
 * desyncs) this table.
 *
 * `retryable` distinguishes a transient condition worth resubmitting (busy,
 * cancelled, a transient I/O fault, a crashed worker the supervisor is
 * restarting) from a design defect the agent must repair by editing its
 * fixture (a dangling reference, an unknown joint kind). `agentHint` is the
 * machine-readable repair suggestion Gate 4 depends on.
 */

export type AssemblyErrorCode = z.infer<typeof assemblyErrorSchema>["code"];
export type AssemblyErrorSeverity = "error" | "warning";

export interface AssemblyErrorDescriptor {
  readonly severity: AssemblyErrorSeverity;
  readonly retryable: boolean;
  readonly agentHint: string;
}

export const assemblyErrorRegistry: Record<
  AssemblyErrorCode,
  AssemblyErrorDescriptor
> = {
  INVALID_REQUEST: {
    severity: "error",
    retryable: false,
    agentHint:
      "The fixture was malformed — a dangling marker/occurrence reference or an unknown joint kind; correct the fixture's structure before resubmitting.",
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
      "This solve exceeded its time budget and was stopped; simplify the fixture (fewer joints or occurrences) before resubmitting.",
  },
  BUSY: {
    severity: "warning",
    retryable: true,
    agentHint: "The assembly host was busy; retry after a short backoff.",
  },
  IO_ERROR: {
    severity: "error",
    retryable: true,
    agentHint:
      "A transient I/O fault occurred while talking to the assembly host; retrying may succeed.",
  },
  CRASHED: {
    severity: "error",
    retryable: true,
    agentHint:
      "The assembly host process died and the supervisor is restarting it; resubmit once it has recovered.",
  },
};

/** The structured descriptor for an assembly wire error code. */
export function describeAssemblyError(
  code: AssemblyErrorCode,
): AssemblyErrorDescriptor {
  return assemblyErrorRegistry[code];
}
