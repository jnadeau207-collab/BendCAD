import { spawn, type ChildProcess } from "node:child_process";
import { EventEmitter } from "node:events";

import { constructChildEnv } from "@aeth/child-process-env";
import {
  kernelTransportResponseSchema,
  parseAembPacket,
  type KernelRequest,
  type KernelResponse,
  type KernelTransportRequest,
  type KernelTransportResponse,
  type ResolveMateFramesKernelRequest,
  type ResolveMateFramesKernelResponse,
} from "@aeth/geometry-contracts";
import { ControlFrameDecoder, encodeControlFrame } from "@aeth/ipc";

import {
  BinaryMeshFrameDecoder,
  type BinaryMeshFrame,
} from "./binary-frame.js";

interface PendingRequest {
  readonly resolve: (response: KernelTransportResponse) => void;
  readonly reject: (error: Error) => void;
  readonly timeout: NodeJS.Timeout;
}

export interface NativeKernelClientOptions {
  readonly executable: string;
  readonly arguments?: readonly string[];
  readonly environment?: Readonly<Record<string, string>>;
  readonly requestTimeoutMs?: number;
}

/** Per-request overrides for {@link NativeKernelClient.request}. */
export interface KernelRequestOptions {
  /**
   * Transport budget for this request, measured from dispatch to response.
   * Overrides the client-wide `requestTimeoutMs` for this request only.
   */
  readonly timeoutMs?: number;
}

export class KernelConnectionError extends Error {
  public constructor(message: string, options?: ErrorOptions) {
    super(message, options);
    this.name = "KernelConnectionError";
  }
}

/**
 * An in-flight request exceeded its transport budget. Distinct from
 * `KernelQueueTimeoutError`, which fires before a request ever reaches the
 * host; this error means the host received the request and did not answer
 * within the deadline.
 */
export class KernelRequestTimeoutError extends KernelConnectionError {
  public constructor(message: string, options?: ErrorOptions) {
    super(message, options);
    this.name = "KernelRequestTimeoutError";
  }
}

export class NativeKernelClient extends EventEmitter {
  readonly #options: NativeKernelClientOptions;
  readonly #pending = new Map<string, PendingRequest>();
  #process: ChildProcess | undefined;
  #fatalError: KernelConnectionError | undefined;

  public constructor(options: NativeKernelClientOptions) {
    super();
    this.#options = options;
  }

  public get pid(): number | undefined {
    return this.#process?.pid;
  }

  public start(): void {
    if (this.#process)
      throw new KernelConnectionError("Kernel client is already started");
    this.#fatalError = undefined;
    const child = spawn(
      this.#options.executable,
      this.#options.arguments ?? [],
      {
        env: constructChildEnv(this.#options.environment ?? {}),
        stdio: ["pipe", "pipe", "pipe", "pipe"],
        windowsHide: true,
      },
    );
    this.#process = child;
    const controlDecoder = new ControlFrameDecoder();
    const binaryDecoder = new BinaryMeshFrameDecoder();

    child.stdout?.on("data", (chunk: Buffer) => {
      try {
        for (const raw of controlDecoder.push(chunk)) {
          const response = kernelTransportResponseSchema.parse(raw);
          const pending = this.#pending.get(response.requestId);
          if (!pending) continue;
          clearTimeout(pending.timeout);
          this.#pending.delete(response.requestId);
          pending.resolve(response);
        }
      } catch (error) {
        this.#failConnection("Kernel control stream is corrupt", error);
      }
    });
    const meshPipe = child.stdio[3];
    if (
      !meshPipe ||
      typeof meshPipe === "number" ||
      !("readable" in meshPipe)
    ) {
      this.#failConnection("Kernel binary mesh pipe was not created");
      return;
    }
    meshPipe.on("data", (chunk: Buffer) => {
      try {
        for (const frame of binaryDecoder.push(chunk)) {
          parseAembPacket(frame.packet);
          this.emit("mesh", frame);
        }
      } catch (error) {
        this.#failConnection("Kernel binary stream is corrupt", error);
      }
    });
    child.stderr?.on("data", (chunk: Buffer) =>
      this.emit("diagnostic", chunk.toString("utf8")),
    );
    child.once("error", (error) =>
      this.#failConnection("Kernel process failed", error),
    );
    child.once("exit", (code, signal) => {
      this.#process = undefined;
      this.#failConnection(
        `Kernel process exited (${code ?? signal ?? "unknown"})`,
      );
      this.emit("exit", { code, signal });
    });
  }

  /**
   * Sends one request to the host. Ordinary kernel requests retain their
   * historical response type; the ASM-005 exact-frame request receives its
   * dedicated response type. Product work still routes through the bounded
   * request queue once the assembly coordinator owns this call; the raw path
   * remains necessary for supervisor handshakes, cancel frames, and native
   * integration tests.
   */
  public request(
    request: KernelRequest,
    options?: KernelRequestOptions,
  ): Promise<KernelResponse>;
  public request(
    request: ResolveMateFramesKernelRequest,
    options?: KernelRequestOptions,
  ): Promise<ResolveMateFramesKernelResponse>;
  public request(
    request: KernelTransportRequest,
    options?: KernelRequestOptions,
  ): Promise<KernelTransportResponse> {
    if (this.#fatalError) return Promise.reject(this.#fatalError);
    const child = this.#process;
    const stdin = child?.stdin;
    if (!stdin) {
      return Promise.reject(
        new KernelConnectionError("Kernel client is not started"),
      );
    }
    if (this.#pending.has(request.requestId)) {
      return Promise.reject(
        new KernelConnectionError(`Duplicate request id ${request.requestId}`),
      );
    }
    const timeoutMs =
      options?.timeoutMs ?? this.#options.requestTimeoutMs ?? 30_000;
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.#pending.delete(request.requestId);
        reject(
          new KernelRequestTimeoutError(
            `Kernel request ${request.requestId} timed out after ${timeoutMs}ms`,
          ),
        );
      }, timeoutMs);
      this.#pending.set(request.requestId, { resolve, reject, timeout });
      try {
        stdin.write(encodeControlFrame(request));
      } catch (error) {
        // Encoding failures (for example an oversized control frame) never
        // reach the host, so they are per-request errors, not connection
        // corruption. Decode failures on the way back remain fatal.
        clearTimeout(timeout);
        this.#pending.delete(request.requestId);
        reject(
          error instanceof Error
            ? error
            : new KernelConnectionError(String(error)),
        );
      }
    });
  }

  public stop(): void {
    const child = this.#process;
    if (!child) return;
    if (process.platform === "win32") child.kill();
    else child.kill("SIGTERM");
  }

  /**
   * Poisons the connection with the SAME fatal semantics as an internally
   * detected framing corruption: every pending request is rejected, the host
   * process is killed, and `"fatal"` is emitted. Exposed so an external
   * detector — the document evaluator reconciling packets against their
   * descriptors — can treat a mesh/control desynchronization as the protocol
   * corruption it is, rather than swallowing it.
   */
  public reportProtocolViolation(message: string, cause?: unknown): void {
    this.#failConnection(message, cause);
  }

  #failConnection(message: string, cause?: unknown): void {
    if (this.#fatalError) return;
    const error = new KernelConnectionError(message, {
      cause: cause instanceof Error ? cause : undefined,
    });
    this.#fatalError = error;
    for (const pending of this.#pending.values()) {
      clearTimeout(pending.timeout);
      pending.reject(error);
    }
    this.#pending.clear();
    const child = this.#process;
    if (child) {
      if (process.platform === "win32") child.kill();
      else child.kill("SIGKILL");
    }
    this.emit("fatal", error);
  }
}

export type { BinaryMeshFrame };
