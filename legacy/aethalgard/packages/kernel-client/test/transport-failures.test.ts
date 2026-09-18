import { fileURLToPath } from "node:url";

import { kernelProtocolVersion } from "@aeth/geometry-contracts";
import { afterEach, describe, expect, it } from "vitest";

import { KernelConnectionError, NativeKernelClient } from "../src/index.js";

const fixture = fileURLToPath(
  new URL("./fixtures/scripted-kernel.mjs", import.meta.url),
);
const clients: NativeKernelClient[] = [];

function client(behavior: "garbage" | "timeout"): NativeKernelClient {
  const result = new NativeKernelClient({
    executable: process.execPath,
    arguments: [fixture],
    requestTimeoutMs: behavior === "timeout" ? 30 : 1_000,
    environment: { AETH_SCRIPTED_KERNEL_BEHAVIOR: behavior },
  });
  clients.push(result);
  result.start();
  return result;
}

afterEach(() => {
  for (const instance of clients.splice(0)) instance.stop();
});

describe("kernel transport failures", () => {
  it("makes a corrupt control stream connection-fatal", async () => {
    await expect(
      client("garbage").request({
        protocolVersion: kernelProtocolVersion,
        requestId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d50",
        method: "health",
      }),
    ).rejects.toThrow(/control stream is corrupt/);
  });

  it("rejects a request that exceeds its deadline", async () => {
    await expect(
      client("timeout").request({
        protocolVersion: kernelProtocolVersion,
        requestId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d51",
        method: "health",
      }),
    ).rejects.toBeInstanceOf(KernelConnectionError);
  });
});
