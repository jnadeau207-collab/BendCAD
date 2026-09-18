import { randomUUID } from "node:crypto";
import { once } from "node:events";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import {
  kernelProtocolVersion,
  type BuildManifest,
} from "@aeth/geometry-contracts";
import { afterEach, describe, expect, it } from "vitest";

import { KernelSupervisor } from "../src/index.js";

const fixture = fileURLToPath(
  new URL("./fixtures/scripted-kernel.mjs", import.meta.url),
);

const supervisors: KernelSupervisor[] = [];
const cleanups: (() => void)[] = [];

function makeSupervisor(
  environment: Record<string, string> = {},
): KernelSupervisor {
  const supervisor = new KernelSupervisor({
    executable: process.execPath,
    arguments: [fixture],
    // This suite tests supervisor state/event coherence, not transport
    // deadlines. Keep the fixture handshake tolerant of a fully saturated
    // Turbo run; timeout behavior has dedicated deterministic coverage.
    requestTimeoutMs: 10_000,
    environment,
  });
  supervisors.push(supervisor);
  return supervisor;
}

/** A spawn-counter file the fixture increments once per spawn. */
function spawnCounter(): { path: string; read: () => number } {
  const directory = mkdtempSync(join(tmpdir(), "aeth-scripted-supervisor-"));
  const path = join(directory, "spawns.count");
  cleanups.push(() => rmSync(directory, { recursive: true, force: true }));
  return {
    path,
    read: () => {
      try {
        return Number.parseInt(readFileSync(path, "utf8"), 10) || 0;
      } catch {
        return 0;
      }
    },
  };
}

afterEach(() => {
  for (const supervisor of supervisors.splice(0)) supervisor.stop();
  for (const cleanup of cleanups.splice(0)) cleanup();
});

describe("KernelSupervisor start coherence", () => {
  it("reaches ready with a state and event that agree", async () => {
    const supervisor = makeSupervisor();
    const readyEvents: BuildManifest[] = [];
    supervisor.on("ready", (build: BuildManifest) => readyEvents.push(build));

    const build = await supervisor.start();

    expect(supervisor.state).toBe("ready");
    expect(supervisor.epoch).toBe(1);
    expect(readyEvents).toHaveLength(1);
    // The event carried exactly the build the handshake returned: state and
    // event are coherent.
    expect(readyEvents[0]).toEqual(build);
    expect(supervisor.client).toBeDefined();
  });

  it(
    "lands on a coherent dead state when a crash-recovery handshake fails",
    { timeout: 30_000 },
    async () => {
      const counter = spawnCounter();
      const supervisor = makeSupervisor({
        AETH_SCRIPTED_KERNEL_BEHAVIOR: "restart-then-unhealthy",
        AETH_SCRIPTED_KERNEL_SPAWN_COUNTER: counter.path,
      });

      let recovered = 0;
      supervisor.on("recovered", () => (recovered += 1));

      // Spawn #1 answers the initial handshake.
      await supervisor.start();
      expect(supervisor.state).toBe("ready");
      expect(counter.read()).toBe(1);

      // Trigger a post-ready crash: spawn #1 exits on the cancel, the
      // supervisor enters recovery, spawn #2 answers health with ok:false so
      // the restart handshake fails. Pre-fix, #discardHandshakeClient left
      // #state as "starting" while the exit handler emitted "dead" — the state
      // and the event disagreed. The fix must land on "dead".
      const dead = once(supervisor, "dead");
      void supervisor.client
        .request({
          protocolVersion: kernelProtocolVersion,
          requestId: randomUUID(),
          method: "cancel",
          targetRequestId: randomUUID(),
        })
        .catch(() => undefined);

      const [error] = await dead;
      expect(error).toBeInstanceOf(Error);
      expect(supervisor.state).toBe("dead");
      // Epoch never advanced past the one successful handshake.
      expect(supervisor.epoch).toBe(1);
      // Exactly two spawns: the original and the one failed replacement. The
      // failed restart must not churn into further spawns.
      expect(counter.read()).toBe(2);
      expect(recovered).toBe(0);
      // A dead supervisor exposes no client.
      expect(() => supervisor.client).toThrow();
    },
  );
});
