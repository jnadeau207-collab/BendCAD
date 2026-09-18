import { NativeKernelClient } from "./native-kernel-client.js";

export interface IsolatedKernelSessionOptions {
  readonly executable: string;
  /**
   * Optional launcher arguments. Production callers point `executable` at the
   * compiled native host and need none; tests point it at a scripted `.mjs`
   * host and pass the script path here.
   */
  readonly arguments?: readonly string[];
  readonly environment?: Readonly<Record<string, string>>;
  /**
   * Binds this session's subprocess lifetime to a case. When the signal
   * aborts, the session force-terminates the host through the client's
   * protocol-violation path so a hung case cannot leak a process.
   */
  readonly signal: AbortSignal;
}

/**
 * A per-case, abort-scoped owner of a {@link NativeKernelClient}.
 *
 * The reference tournament hands each case an {@link AbortSignal} that fires
 * when the case exceeds its per-case timeout. A future native/OCAF entrant that
 * owns a kernel subprocess wraps it in an `IsolatedKernelSession`: on abort the
 * session calls {@link NativeKernelClient.reportProtocolViolation}, the same
 * SIGKILL/fatal path used for framing corruption, so the timed-out subprocess
 * is force-killed rather than abandoned as a leak. Normal completion tears the
 * subprocess down through {@link IsolatedKernelSession.close}. Each session owns
 * exactly one subprocess, so aborting or closing one never touches another.
 */
export class IsolatedKernelSession {
  readonly #client: NativeKernelClient;
  readonly #signal: AbortSignal;
  readonly #onAbort: () => void;
  #closed = false;

  private constructor(client: NativeKernelClient, signal: AbortSignal) {
    this.#client = client;
    this.#signal = signal;
    this.#onAbort = () => {
      // Idempotent by contract: reportProtocolViolation ignores repeat calls
      // once the connection is already poisoned.
      this.#client.reportProtocolViolation(
        "Kernel session aborted by its per-case signal",
        this.#signal.reason,
      );
    };
    this.#signal.addEventListener("abort", this.#onAbort, { once: true });
  }

  public static start(
    options: IsolatedKernelSessionOptions,
  ): IsolatedKernelSession {
    // Built conditionally so an omitted optional stays omitted: the workspace
    // compiles under exactOptionalPropertyTypes, where `arguments: undefined`
    // is not the same as an absent `arguments`.
    const client = new NativeKernelClient({
      executable: options.executable,
      ...(options.arguments !== undefined
        ? { arguments: options.arguments }
        : {}),
      ...(options.environment !== undefined
        ? { environment: options.environment }
        : {}),
    });
    client.start();
    const session = new IsolatedKernelSession(client, options.signal);
    // An already-aborted signal never dispatches to a freshly added listener,
    // so honor a pre-aborted signal explicitly and kill the subprocess we just
    // spawned rather than leaking it.
    if (options.signal.aborted) session.#onAbort();
    return session;
  }

  /** The wrapped client, for issuing requests within the session's lifetime. */
  public get client(): NativeKernelClient {
    return this.#client;
  }

  public get pid(): number | undefined {
    return this.#client.pid;
  }

  /** Normal teardown: detach the abort listener and stop the subprocess. */
  public close(): void {
    if (this.#closed) return;
    this.#closed = true;
    this.#signal.removeEventListener("abort", this.#onAbort);
    this.#client.stop();
  }
}
