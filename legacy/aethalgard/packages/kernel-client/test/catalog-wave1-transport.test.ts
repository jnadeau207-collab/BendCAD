import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";

import {
  describeKernelError,
  kernelProtocolVersion,
  kernelRequestSchema,
  kernelResponseSchema,
  wireOperationSchema,
  type Operation,
} from "@aeth/geometry-contracts";
import { afterEach, describe, expect, it } from "vitest";

import { IsolatedKernelSession } from "../src/index.js";
import { opFacesNormalZ, opQuery, worldQuery } from "./wire-refs.js";

/**
 * Catalog wave-1 transport contract
 * (docs/design/2026-07-19-catalog-ts-contracts.md §5): the six staged
 * operation types (datum_plane, datum_axis, shell, mirror, pattern_linear,
 * pattern_circular) ride `evaluate_document` through the REAL length-prefixed
 * transport against the scripted fake host — schema-valid, envelope-valid,
 * and answered. Their kernel-side refusal (attributed UNSUPPORTED_OPERATION
 * until native execution lands) is pinned against the real host in
 * `catalog-wave1.native.integration.test.ts`; here the CLIENT half of that
 * fail-closed contract is pinned: the closed error enum carries the code and
 * the registry marks it non-retryable with an actionable hint.
 */

const fixture = fileURLToPath(
  new URL("./fixtures/scripted-kernel.mjs", import.meta.url),
);

const sessions: IsolatedKernelSession[] = [];

afterEach(() => {
  for (const session of sessions.splice(0)) session.close();
});

function startSession(): IsolatedKernelSession {
  const session = IsolatedKernelSession.start({
    executable: process.execPath,
    arguments: [fixture],
    environment: {},
    signal: new AbortController().signal,
  });
  sessions.push(session);
  return session;
}

const metadata = {
  createdAt: "2026-07-19T09:00:00.000Z",
  createdBy: { kind: "user" },
} as const;

/** One literal (already materialized) operation of every wave-1 type. */
function catalogWave1Operations(): readonly Operation[] {
  const boxOperationId = randomUUID();
  const seedOperationId = randomUUID();
  const shared = { schemaVersion: 1, metadata } as const;
  // Validated against the WIRE schema (N6 slice C): the doc→kernel ref lowering
  // rewrites each persisted `{query}` slot to the wire `{ast}` these staged ops
  // ride, and the request schema now refuses a raw `{query}` fail-closed.
  return wireOperationSchema.array().parse([
    {
      ...shared,
      id: boxOperationId,
      type: "create_box",
      name: "Catalog wave 1 target",
      outputBodyId: randomUUID(),
      parameters: { width: 60, depth: 40, height: 20, placement: {} },
    },
    {
      ...shared,
      id: seedOperationId,
      type: "create_cylinder",
      name: "Catalog wave 1 seed",
      outputBodyId: randomUUID(),
      parameters: { radius: 3, height: 25, placement: {} },
    },
    {
      ...shared,
      id: randomUUID(),
      type: "datum_plane",
      name: "Lid plane",
      parameters: {
        mode: "offset",
        offset: 5,
        base: {
          ast: opQuery("faces", boxOperationId, [{ name: "planar", args: [] }]),
        },
      },
    },
    {
      ...shared,
      id: randomUUID(),
      type: "datum_axis",
      name: "Post axis",
      parameters: {
        mode: "cylinderAxis",
        face: { ast: opQuery("faces", seedOperationId) },
      },
    },
    {
      ...shared,
      id: randomUUID(),
      type: "shell",
      name: "Hollow the box",
      outputBodyId: randomUUID(),
      parameters: {
        targetOperationId: boxOperationId,
        thickness: 1.6,
        openFaces: {
          ast: opFacesNormalZ(boxOperationId),
          arity: "any",
          onEmpty: "empty-ok",
        },
      },
    },
    {
      ...shared,
      id: randomUUID(),
      type: "mirror",
      name: "Mirror the seed",
      outputBodyId: randomUUID(),
      parameters: {
        sourceOperationId: seedOperationId,
        plane: { ast: worldQuery("faces", "yz") },
        merge: false,
      },
    },
    {
      ...shared,
      id: randomUUID(),
      type: "pattern_linear",
      name: "Row of seeds",
      outputBodyId: randomUUID(),
      parameters: {
        seedOperationId,
        count: 4,
        spacing: 12,
        direction: [1, 0, 0],
      },
    },
    {
      ...shared,
      id: randomUUID(),
      type: "pattern_circular",
      name: "Bolt circle",
      outputBodyId: randomUUID(),
      parameters: {
        seedOperationId,
        axis: { ast: worldQuery("edges", "z") },
        count: 6,
        op: "subtract",
        targetOperationId: boxOperationId,
      },
    },
  ]);
}

describe("catalog wave 1 rides the kernel transport", () => {
  it("carries every staged operation type through evaluate_document", async () => {
    const session = startSession();
    const operations = catalogWave1Operations();
    // Envelope proof: the staged types satisfy the SAME request schema every
    // evaluate_document goes through — no special-casing at the boundary.
    const request = kernelRequestSchema.parse({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      documentId: randomUUID(),
      revision: 7,
      method: "evaluate_document",
      operations: [...operations],
    });
    const response = await session.client.request(request);
    expect(response.ok, response.ok ? "" : JSON.stringify(response.error)).toBe(
      true,
    );
    if (!response.ok) return;
    expect(response.result.type).toBe("evaluation");
    if (response.result.type !== "evaluation") return;
    expect(response.result.revision).toBe(7);
  });
});

describe("catalog wave 1 fail-closed refusal, client half", () => {
  it("parses an attributed UNSUPPORTED_OPERATION refusal for a staged op", () => {
    // The exact envelope the real kernel emits pre-native (geometry.cpp's
    // dispatch `else` → "unsupported operation: <type>" → UNSUPPORTED_
    // OPERATION with the op id attributed) parses through the CLOSED
    // response schema — the code is a first-class enum member, not a string
    // that leaks through.
    const operationId = randomUUID();
    const response = kernelResponseSchema.parse({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      ok: false,
      error: {
        code: "UNSUPPORTED_OPERATION",
        message: "unsupported operation: shell",
        operationId,
      },
    });
    expect(response.ok).toBe(false);
    if (response.ok) return;
    expect(response.error.code).toBe("UNSUPPORTED_OPERATION");
    expect(response.error.operationId).toBe(operationId);
  });

  it("registers the refusal as non-retryable with an actionable hint", () => {
    const descriptor = describeKernelError("UNSUPPORTED_OPERATION");
    expect(descriptor.retryable).toBe(false);
    expect(descriptor.severity).toBe("error");
    expect(descriptor.agentHint.length).toBeGreaterThan(0);
  });
});
