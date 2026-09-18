import { randomUUID } from "node:crypto";
import { EventEmitter } from "node:events";

import {
  kernelProtocolVersion,
  type BuildManifest,
  type KernelResponse,
} from "@aeth/geometry-contracts";

import {
  KernelConnectionError,
  NativeKernelClient,
  type NativeKernelClientOptions,
} from "./native-kernel-client.js";

export type KernelSupervisorState =
  "stopped" | "starting" | "ready" | "restarting" | "dead";

/**
 * Supervises the native kernel host process.
 *
 * Events:
 * - `"ready"` (build) — a start or restart completed its health handshake;
 *   the epoch has advanced and the client accepts requests.
 * - `"client-fatal"` (error) — the active connection died. Per the foundation
 *   audit, a `ControlFrameError` (or binary-frame corruption) is fatal for
 *   the connection: resynchronization after a framing error is impossible, so
 *   every request pending on that connection is rejected and the host process
 *   is killed before this event fires.
 * - `"recovered"` (build) — an automatic restart after a crash succeeded.
 * - `"dead"` (error) — the crash-loop breaker gave up; no client is coming.
 * - `"stopped"` — `stop()` was called; deliberate shutdown.
 * - `"exit"`-driven restarts are internal; consumers observe the events above.
 */
export class KernelSupervisor extends EventEmitter {
  readonly #options: NativeKernelClientOptions;
  #client: NativeKernelClient | undefined;
  #state: KernelSupervisorState = "stopped";
  #crashes: number[] = [];
  #restart: Promise<BuildManifest> | undefined;
  #epoch = 0;

  public constructor(options: NativeKernelClientOptions) {
    super();
    this.#options = options;
  }

  public get state(): KernelSupervisorState {
    return this.#state;
  }

  public get client(): NativeKernelClient {
    if (!this.#client)
      throw new KernelConnectionError("Kernel supervisor is not ready");
    return this.#client;
  }

  /** Monotonic process epoch; any epoch-local geometry token is invalid after this changes. */
  public get epoch(): number {
    return this.#epoch;
  }

  public async start(): Promise<BuildManifest> {
    return this.#attemptStart(false);
  }

  /**
   * One spawn-and-handshake attempt. `isRestart` distinguishes a deliberate
   * `start()` (a failed handshake returns the supervisor to `"stopped"`) from
   * a crash-recovery restart (a failed handshake is terminal — `"dead"` — so
   * the state and the `"dead"` event the exit handler emits stay coherent).
   */
  async #attemptStart(isRestart: boolean): Promise<BuildManifest> {
    this.#state = "starting";
    const client = new NativeKernelClient(this.#options);
    this.#client = client;
    client.once("fatal", (error: Error) => {
      // A fatal connection (control-frame corruption, binary-frame
      // corruption, process death) invalidates every request pending on it.
      // Consumers such as KernelRequestQueue listen here to fail their
      // backlog with the fatal error instead of hanging or re-dispatching.
      if (this.#client === client) this.emit("client-fatal", error);
    });
    client.once("exit", () => {
      if (this.#client !== client || this.#state === "stopped") return;
      // A restart already in flight owns the terminal emit. A replacement
      // that dies before its handshake settles would otherwise attach a
      // second recovered/dead handler to the SAME restart promise and
      // double-fire; the in-flight restart handles this exit on its own path.
      if (this.#restart !== undefined) return;
      void this.restartAfterCrash()
        .then((build) => this.emit("recovered", build))
        .catch((error: unknown) => this.emit("dead", error));
    });
    client.start();
    let response: KernelResponse;
    try {
      response = await client.request({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        method: "health",
      });
    } catch (error) {
      this.#discardHandshakeClient(client, isRestart);
      throw error;
    }
    if (!response.ok || response.result.type !== "health") {
      this.#discardHandshakeClient(client, isRestart);
      throw new KernelConnectionError("Kernel health handshake failed");
    }
    this.#epoch += 1;
    this.#state = "ready";
    this.emit("ready", response.result.build);
    return response.result.build;
  }

  /**
   * A client that failed its handshake must not linger or trigger restarts,
   * and the supervisor must land on a terminal state coherent with what the
   * caller observes: a failed `start()` returns to `"stopped"`, a failed
   * crash-recovery restart is `"dead"` (matching the `"dead"` event). The
   * `"stopped"` guard preserves a concurrent `stop()` — it wins over both.
   */
  #discardHandshakeClient(
    client: NativeKernelClient,
    isRestart: boolean,
  ): void {
    if (this.#client === client) this.#client = undefined;
    client.stop();
    if (this.#state !== "stopped") {
      this.#state = isRestart ? "dead" : "stopped";
    }
  }

  public async restartAfterCrash(): Promise<BuildManifest> {
    if (this.#restart) return this.#restart;
    this.#restart = this.#performRestart();
    try {
      return await this.#restart;
    } finally {
      this.#restart = undefined;
    }
  }

  async #performRestart(): Promise<BuildManifest> {
    const now = Date.now();
    this.#crashes = this.#crashes.filter((time) => now - time < 60_000);
    this.#crashes.push(now);
    if (this.#crashes.length > 3) {
      this.#state = "dead";
      throw new KernelConnectionError(
        "Kernel exceeded three restart attempts within sixty seconds",
      );
    }
    this.#state = "restarting";
    this.#client?.stop();
    const delays = [0, 1_000, 5_000] as const;
    await new Promise((resolve) =>
      setTimeout(resolve, delays[this.#crashes.length - 1]),
    );
    return this.#attemptStart(true);
  }

  public stop(): void {
    const client = this.#client;
    this.#state = "stopped";
    // Deliberate shutdown owns the externally visible terminal condition.
    // Publish it before terminating the child so a fast process-exit/fatal
    // callback cannot race the queue into reporting a connection failure for
    // an intentional stop. Detach the client first as an additional guard:
    // the client's `fatal`/`exit` listeners both ignore a no-longer-current
    // client, while the captured instance below is still terminated exactly
    // once in this synchronous call.
    this.#client = undefined;
    try {
      this.emit("stopped");
    } finally {
      // EventEmitter listeners run synchronously and can throw. A consumer
      // failure must never strand the native child after this supervisor has
      // already transitioned to `stopped` and detached it.
      client?.stop();
    }
  }
}
