import { randomUUID } from "node:crypto";
import { once } from "node:events";
import { fileURLToPath } from "node:url";

import { kernelProtocolVersion } from "@aeth/geometry-contracts";
import { afterEach, describe, expect, it } from "vitest";

import { IsolatedKernelSession } from "../src/index.js";

const fixture = fileURLToPath(
  new URL("./fixtures/scripted-kernel.mjs", import.meta.url),
);

const sessions: IsolatedKernelSession[] = [];

function startSession(
  signal: AbortSignal,
  environment: Record<string, string> = {},
): IsolatedKernelSession {
  const session = IsolatedKernelSession.start({
    executable: process.execPath,
    arguments: [fixture],
    environment,
    signal,
  });
  sessions.push(session);
  return session;
}

afterEach(() => {
  for (const session of sessions.splice(0)) session.close();
});

describe("IsolatedKernelSession", () => {
  it("force-terminates a hung subprocess when its signal aborts", async () => {
    const controller = new AbortController();
    // "timeout" accepts requests and never answers: exactly the hung host that
    // would leak if the session did not force-kill it on abort.
    const session = startSession(controller.signal, {
      AETH_SCRIPTED_KERNEL_BEHAVIOR: "timeout",
    });
    expect(session.pid).toBeGreaterThan(0);

    const exit = once(session.client, "exit");
    controller.abort(new Error("case exceeded its per-case budget"));
    // The exit event resolving is the proof the subprocess actually died
    // rather than lingering as a leak.
    const [payload] = (await exit) as [{ code: number | null }];
    expect(payload).toBeDefined();
  });

  it("starts a fresh, working session after a prior one was aborted", async () => {
    const firstController = new AbortController();
    const first = startSession(firstController.signal, {
      AETH_SCRIPTED_KERNEL_BEHAVIOR: "timeout",
    });
    const firstPid = first.pid;
    const firstExit = once(first.client, "exit");
    firstController.abort(new Error("first case aborted"));
    await firstExit;

    // A second session spawns its own independent subprocess and answers the
    // health handshake, proving the abort poisoned only its own session.
    const second = startSession(new AbortController().signal);
    const response = await second.client.request({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "health",
    });
    expect(response.ok).toBe(true);
    expect(second.pid).toBeGreaterThan(0);
    expect(second.pid).not.toBe(firstPid);
    second.close();
  });
});
