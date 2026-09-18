import { randomUUID } from "node:crypto";

import {
  kernelProtocolVersion,
  type KernelRequest,
  type KernelResponse,
} from "@aeth/geometry-contracts";

import { KernelRequestTimeoutError } from "./native-kernel-client.js";
import type { KernelSupervisor } from "./supervisor.js";

/** Base class for every failure the queue itself produces. */
export class KernelQueueError extends Error {
  public constructor(message: string, options?: ErrorOptions) {
    super(message, options);
    this.name = "KernelQueueError";
  }
}

/** The bounded queue is at capacity; the request was never accepted. */
export class KernelQueueFullError extends KernelQueueError {
  public readonly maxQueueDepth: number;

  public constructor(message: string, maxQueueDepth: number) {
    super(message);
    this.name = "KernelQueueFullError";
    this.maxQueueDepth = maxQueueDepth;
  }
}

/**
 * The deadline (measured from submission) expired while the request was
 * still queued. The request produced no host traffic. Contrast with
 * `KernelRequestTimeoutError`, which means the deadline expired after
 * dispatch while the request was in flight on the host.
 */
export class KernelQueueTimeoutError extends KernelQueueError {
  public constructor(message: string) {
    super(message);
    this.name = "KernelQueueTimeoutError";
  }
}

/** A queued request was cancelled before dispatch; no host traffic occurred. */
export class KernelQueueCancelledError extends KernelQueueError {
  public constructor(message: string) {
    super(message);
    this.name = "KernelQueueCancelledError";
  }
}

/**
 * The supervisor epoch changed between submission and dispatch. Geometry
 * tokens are epoch-local (ADR-003), so a request formed against epoch N must
 * never be silently re-dispatched against epoch N+1. Callers rebuild the
 * request against the current epoch and resubmit.
 */
export class KernelEpochInvalidatedError extends KernelQueueError {
  public readonly submittedEpoch: number;
  public readonly currentEpoch: number;

  public constructor(
    message: string,
    submittedEpoch: number,
    currentEpoch: number,
  ) {
    super(message);
    this.name = "KernelEpochInvalidatedError";
    this.submittedEpoch = submittedEpoch;
    this.currentEpoch = currentEpoch;
  }
}

/** The queue (or its supervisor) shut down; nothing will be dispatched. */
export class KernelQueueClosedError extends KernelQueueError {
  public constructor(message: string, options?: ErrorOptions) {
    super(message, options);
    this.name = "KernelQueueClosedError";
  }
}

export interface KernelRequestQueueOptions {
  /**
   * Default per-request deadline in milliseconds, measured from submission
   * (not dispatch). Defaults to 30 000 ms.
   */
  readonly defaultDeadlineMs?: number;
  /**
   * Maximum number of queued (not yet dispatched) requests. The in-flight
   * request does not count toward this bound. Defaults to 64.
   */
  readonly maxQueueDepth?: number;
  /** Transport budget for best-effort protocol cancel frames. Default 5 000. */
  readonly cancelTimeoutMs?: number;
}

export interface KernelQueueSubmitOptions {
  /** Deadline for this request, from submission. Overrides the default. */
  readonly deadlineMs?: number;
  /**
   * Cancels the request. Aborting while queued removes the request without
   * any host traffic and rejects with `KernelQueueCancelledError`. Aborting
   * while in flight sends the protocol `cancel` method with
   * `targetRequestId`; the returned promise then settles with whatever the
   * host answers — normally an `ok: false` response with error code
   * `CANCELLED`, or the real result if the host finished first.
   */
  readonly signal?: AbortSignal;
}

interface QueueEntry {
  readonly request: KernelRequest;
  readonly submittedEpoch: number;
  readonly deadlineAt: number;
  readonly signal: AbortSignal | undefined;
  phase: "queued" | "in-flight";
  settled: boolean;
  timer: NodeJS.Timeout | undefined;
  abortListener: (() => void) | undefined;
  resolve: (response: KernelResponse) => void;
  reject: (error: Error) => void;
}

const defaultDeadlineMs = 30_000;
const defaultMaxQueueDepth = 64;
const defaultCancelTimeoutMs = 5_000;

/**
 * Deliberate FIFO request queue in front of `NativeKernelClient.request`.
 *
 * The kernel host is single-threaded per protocol, so the queue keeps at
 * most one work request in flight and dispatches strictly in submission
 * order. This replaces ad-hoc in-flight coalescing at call sites: independent
 * tools submit concurrently and each receives its own response.
 *
 * Contracts:
 * - **Deadlines** are measured from submission. Expiry while queued rejects
 *   with `KernelQueueTimeoutError` (no host traffic); after dispatch the
 *   remaining budget rides the transport and overruns reject with
 *   `KernelRequestTimeoutError`, followed by a best-effort protocol cancel so
 *   the single-threaded host is freed.
 * - **Cancellation** while queued removes the entry without host traffic;
 *   while in flight it sends the protocol `cancel` method and resolves per
 *   the host's `CANCELLED` error response.
 * - **Bounded depth** rejects overflow submissions with
 *   `KernelQueueFullError`.
 * - **Epoch awareness**: every entry carries the supervisor epoch at
 *   submission. When the supervisor restarts (epoch change), stale entries
 *   reject with `KernelEpochInvalidatedError` — never silently re-dispatched
 *   against a new epoch, because geometry tokens are epoch-local (ADR-003).
 * - **Fatal connections** (`ControlFrameError`, binary corruption, process
 *   death) reject the in-flight request and the whole backlog with the fatal
 *   error; after the supervisor recovers, the queue is empty and accepts new
 *   work against the new epoch.
 */
export class KernelRequestQueue {
  readonly #supervisor: KernelSupervisor;
  readonly #defaultDeadlineMs: number;
  readonly #maxQueueDepth: number;
  readonly #cancelTimeoutMs: number;
  readonly #queued: QueueEntry[] = [];
  #inFlight: QueueEntry | undefined;
  #pumping = false;
  #closed: KernelQueueClosedError | undefined;
  readonly #onClientFatal: (error: Error) => void;
  readonly #onReady: () => void;
  readonly #onDead: (error: unknown) => void;
  readonly #onStopped: () => void;

  public constructor(
    supervisor: KernelSupervisor,
    options: KernelRequestQueueOptions = {},
  ) {
    const deadline = options.defaultDeadlineMs ?? defaultDeadlineMs;
    const depth = options.maxQueueDepth ?? defaultMaxQueueDepth;
    const cancelTimeout = options.cancelTimeoutMs ?? defaultCancelTimeoutMs;
    if (!Number.isFinite(deadline) || deadline <= 0) {
      throw new RangeError("defaultDeadlineMs must be a positive number");
    }
    if (!Number.isSafeInteger(depth) || depth <= 0) {
      throw new RangeError("maxQueueDepth must be a positive integer");
    }
    if (!Number.isFinite(cancelTimeout) || cancelTimeout <= 0) {
      throw new RangeError("cancelTimeoutMs must be a positive number");
    }
    this.#supervisor = supervisor;
    this.#defaultDeadlineMs = deadline;
    this.#maxQueueDepth = depth;
    this.#cancelTimeoutMs = cancelTimeout;
    this.#onClientFatal = (error: Error) => this.#flushAll(error);
    this.#onReady = () => {
      this.#sweepStaleEpochs();
      this.#pump();
    };
    this.#onDead = (error: unknown) => {
      this.#flushAll(
        error instanceof Error
          ? error
          : new KernelQueueClosedError("Kernel supervisor died"),
      );
    };
    this.#onStopped = () => {
      this.#flushAll(
        new KernelQueueClosedError("Kernel supervisor was stopped"),
      );
    };
    supervisor.on("client-fatal", this.#onClientFatal);
    supervisor.on("ready", this.#onReady);
    supervisor.on("dead", this.#onDead);
    supervisor.on("stopped", this.#onStopped);
  }

  /** Number of queued (not yet dispatched) requests. */
  public get depth(): number {
    return this.#queued.length;
  }

  /** Request id currently in flight toward the host, if any. */
  public get inFlightRequestId(): string | undefined {
    const entry = this.#inFlight;
    // A flushed entry is already settled for its caller even while the
    // transport promise is still winding down; report the caller's view.
    return entry && !entry.settled ? entry.request.requestId : undefined;
  }

  /**
   * Submits one request. Requests dispatch in FIFO order with at most one in
   * flight; the returned promise settles with the host response or one of
   * the typed queue errors documented on this class.
   */
  public submit(
    request: KernelRequest,
    options: KernelQueueSubmitOptions = {},
  ): Promise<KernelResponse> {
    if (this.#closed) return Promise.reject(this.#closed);
    const deadlineMs = options.deadlineMs ?? this.#defaultDeadlineMs;
    if (!Number.isFinite(deadlineMs) || deadlineMs <= 0) {
      return Promise.reject(
        new KernelQueueError("deadlineMs must be a positive number"),
      );
    }
    if (options.signal?.aborted) {
      return Promise.reject(
        new KernelQueueCancelledError(
          `Kernel request ${request.requestId} was cancelled before submission`,
        ),
      );
    }
    if (
      this.#inFlight?.request.requestId === request.requestId ||
      this.#queued.some(
        (entry) => entry.request.requestId === request.requestId,
      )
    ) {
      return Promise.reject(
        new KernelQueueError(`Duplicate request id ${request.requestId}`),
      );
    }
    if (this.#queued.length >= this.#maxQueueDepth) {
      return Promise.reject(
        new KernelQueueFullError(
          `Kernel request queue is full (${this.#maxQueueDepth} queued); rejecting ${request.requestId}`,
          this.#maxQueueDepth,
        ),
      );
    }
    return new Promise<KernelResponse>((resolve, reject) => {
      const entry: QueueEntry = {
        request,
        submittedEpoch: this.#supervisor.epoch,
        deadlineAt: Date.now() + deadlineMs,
        signal: options.signal,
        phase: "queued",
        settled: false,
        timer: undefined,
        abortListener: undefined,
        resolve,
        reject,
      };
      entry.timer = setTimeout(() => {
        if (entry.settled || entry.phase !== "queued") return;
        this.#remove(entry);
        this.#settleReject(
          entry,
          new KernelQueueTimeoutError(
            `Kernel request ${request.requestId} exceeded its ${deadlineMs}ms deadline while queued`,
          ),
        );
      }, deadlineMs);
      entry.timer.unref?.();
      if (options.signal) {
        const signal = options.signal;
        entry.abortListener = () => {
          if (entry.settled) return;
          if (entry.phase === "queued") {
            this.#remove(entry);
            this.#settleReject(
              entry,
              new KernelQueueCancelledError(
                `Kernel request ${request.requestId} was cancelled while queued`,
              ),
            );
            return;
          }
          // In flight: ask the host to cancel; the entry settles with the
          // host's CANCELLED error response (or its real result if the host
          // finished first).
          this.#sendCancel(request.requestId);
        };
        signal.addEventListener("abort", entry.abortListener, { once: true });
      }
      this.#queued.push(entry);
      this.#pump();
    });
  }

  /**
   * Rejects every queued request with `KernelQueueClosedError`, detaches
   * from the supervisor, and refuses further submissions. An in-flight
   * request is rejected as well; the host may still complete it internally.
   */
  public close(): void {
    if (this.#closed) return;
    this.#closed = new KernelQueueClosedError("Kernel request queue is closed");
    this.#flushAll(this.#closed);
    this.#supervisor.off("client-fatal", this.#onClientFatal);
    this.#supervisor.off("ready", this.#onReady);
    this.#supervisor.off("dead", this.#onDead);
    this.#supervisor.off("stopped", this.#onStopped);
  }

  #pump(): void {
    if (this.#pumping) return;
    this.#pumping = true;
    void this.#drain().finally(() => {
      this.#pumping = false;
      // Recheck for work that arrived during the final drain turn. A request
      // submitted from the completion continuation of the last in-flight
      // request runs BEFORE this callback (its microtask was scheduled first)
      // yet AFTER `#drain` observed an empty queue — a lost wakeup that would
      // otherwise strand it until an unrelated supervisor event. Re-pump only
      // when the host can actually dispatch: the "starting"/"restarting" gaps
      // are resumed by the supervisor's "ready" event, and re-pumping there
      // would spin.
      if (this.#canDispatchNow()) this.#pump();
    });
  }

  /**
   * Whether a fresh drain would make progress right now: work is queued, none
   * is in flight, the queue is open, and the supervisor is in a dispatchable
   * state. Mirrors the state gate inside {@link #drain} so the re-pump after a
   * lost wakeup never fires during an epoch gap (which the "ready" event owns)
   * or after a flush (which empties the queue).
   */
  #canDispatchNow(): boolean {
    if (this.#closed || this.#inFlight || this.#queued.length === 0)
      return false;
    const state = this.#supervisor.state;
    return (
      state !== "starting" &&
      state !== "restarting" &&
      state !== "stopped" &&
      state !== "dead"
    );
  }

  async #drain(): Promise<void> {
    while (!this.#inFlight && this.#queued.length > 0) {
      const state = this.#supervisor.state;
      if (state === "starting" || state === "restarting") {
        // The supervisor is between epochs; the "ready"/"dead" events resume
        // or flush the queue. Never dispatch against a half-started host.
        return;
      }
      if (state === "stopped" || state === "dead") {
        this.#flushAll(
          new KernelQueueClosedError(`Kernel supervisor is ${state}`),
        );
        return;
      }
      const entry = this.#queued.shift();
      if (!entry || entry.settled) continue;
      if (entry.submittedEpoch !== this.#supervisor.epoch) {
        this.#settleReject(
          entry,
          new KernelEpochInvalidatedError(
            `Kernel request ${entry.request.requestId} was submitted in epoch ${entry.submittedEpoch} but the supervisor is now in epoch ${this.#supervisor.epoch}`,
            entry.submittedEpoch,
            this.#supervisor.epoch,
          ),
        );
        continue;
      }
      const remaining = entry.deadlineAt - Date.now();
      if (remaining <= 0) {
        this.#settleReject(
          entry,
          new KernelQueueTimeoutError(
            `Kernel request ${entry.request.requestId} exceeded its deadline while queued`,
          ),
        );
        continue;
      }
      entry.phase = "in-flight";
      if (entry.timer) clearTimeout(entry.timer);
      entry.timer = undefined;
      this.#inFlight = entry;
      let hostWedged = false;
      try {
        const response = await this.#supervisor.client.request(entry.request, {
          timeoutMs: remaining,
        });
        this.#settleResolve(entry, response);
      } catch (error) {
        if (error instanceof KernelRequestTimeoutError) {
          // Idleness barrier: a timed-out request is STILL executing on the
          // single-threaded host. Publishing the next request now can race a
          // BUSY rejection, because a protocol cancel only asks the worker to
          // stop — it does not, by itself, mean the worker has stopped. Await a
          // cancel whose acknowledgment proves the host is idle (native
          // HandleCancel joins the worker before replying, and RunWork clears
          // `busy_` before publishing, so a reply means the host is free).
          // `#inFlight` stays set across this await, so no other dispatch slips
          // through. If idleness cannot be proven within the cancel budget the
          // worker is wedged; escalate to a supervisor restart rather than
          // dispatch blindly.
          hostWedged = !(await this.#confirmHostIdle(entry.request.requestId));
        }
        this.#settleReject(
          entry,
          error instanceof Error ? error : new Error(String(error)),
        );
      } finally {
        this.#inFlight = undefined;
      }
      if (hostWedged) {
        // Could not confirm the worker stopped. Force a fresh process; the
        // supervisor's "ready"/"dead" events then re-pump or flush the queue,
        // and stale-epoch entries reject so callers rebuild against the new
        // epoch. Stop draining into a host we cannot prove is idle.
        this.#forceSupervisorRestart();
        return;
      }
    }
  }

  /**
   * Sends a protocol cancel for a timed-out request and waits for its
   * acknowledgment, which — by the native idleness barrier — means the target
   * worker terminated and the host is idle. Returns whether idleness was
   * proven within the cancel budget.
   */
  async #confirmHostIdle(targetRequestId: string): Promise<boolean> {
    try {
      const response = await this.#supervisor.client.request(
        {
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          method: "cancel",
          targetRequestId,
        },
        { timeoutMs: this.#cancelTimeoutMs },
      );
      // Idleness is proven ONLY by a well-formed OK cancellation acknowledgment
      // that names THIS target. The native barrier sends such an ack only after
      // the target worker terminated and `busy_` cleared under the state mutex
      // (see HandleCancel joining the worker + RunWork's atomic completion).
      // Any other resolved shape — an `ok: false` error, a different result
      // type, or a mismatched targetRequestId — is NOT proof the host is idle,
      // so it must be treated as wedged: the caller then forces a fresh process
      // rather than dispatch into a host we cannot prove is free.
      return (
        response.ok &&
        response.result.type === "cancellation" &&
        response.result.targetRequestId === targetRequestId
      );
    } catch {
      return false;
    }
  }

  /**
   * Last resort when the host cannot be proven idle after a timeout: kill the
   * client so the supervisor's crash-recovery restarts the process against a
   * fresh epoch. The queue's "ready"/"dead"/"client-fatal" handlers resettle
   * the backlog; nothing is dispatched into the wedged process.
   */
  #forceSupervisorRestart(): void {
    try {
      this.#supervisor.client.stop();
    } catch {
      // No live client to stop — the supervisor is already recovering.
    }
  }

  #sendCancel(targetRequestId: string): void {
    try {
      void this.#supervisor.client
        .request(
          {
            protocolVersion: kernelProtocolVersion,
            requestId: randomUUID(),
            method: "cancel",
            targetRequestId,
          },
          { timeoutMs: this.#cancelTimeoutMs },
        )
        .catch(() => undefined);
    } catch {
      // No live client — nothing to cancel against.
    }
  }

  #sweepStaleEpochs(): void {
    const epoch = this.#supervisor.epoch;
    for (const entry of this.#queued.splice(0)) {
      if (entry.settled) continue;
      if (entry.submittedEpoch === epoch) {
        this.#queued.push(entry);
        continue;
      }
      this.#settleReject(
        entry,
        new KernelEpochInvalidatedError(
          `Kernel request ${entry.request.requestId} was submitted in epoch ${entry.submittedEpoch} but the supervisor recovered into epoch ${epoch}`,
          entry.submittedEpoch,
          epoch,
        ),
      );
    }
  }

  #flushAll(error: Error): void {
    const inFlight = this.#inFlight;
    if (inFlight && !inFlight.settled) this.#settleReject(inFlight, error);
    for (const entry of this.#queued.splice(0)) {
      if (!entry.settled) this.#settleReject(entry, error);
    }
  }

  #remove(entry: QueueEntry): void {
    const index = this.#queued.indexOf(entry);
    if (index !== -1) this.#queued.splice(index, 1);
  }

  #settleResolve(entry: QueueEntry, response: KernelResponse): void {
    if (entry.settled) return;
    entry.settled = true;
    this.#cleanup(entry);
    entry.resolve(response);
  }

  #settleReject(entry: QueueEntry, error: Error): void {
    if (entry.settled) return;
    entry.settled = true;
    this.#cleanup(entry);
    entry.reject(error);
  }

  #cleanup(entry: QueueEntry): void {
    if (entry.timer) clearTimeout(entry.timer);
    entry.timer = undefined;
    if (entry.signal && entry.abortListener) {
      entry.signal.removeEventListener("abort", entry.abortListener);
    }
    entry.abortListener = undefined;
  }
}
