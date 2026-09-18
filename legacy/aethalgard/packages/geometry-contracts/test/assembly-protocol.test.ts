/**
 * Wire-protocol contract for `packages/assembly-client` <-> `native/assembly-host`
 * (ASM-002, plan 07 §6.4/§14.2). Mirrors `kernel-protocol.test.ts`'s structure:
 * a minimal valid request parses, the joint-kind enum stays exactly the
 * ASM-002 scope (fixed/revolute/prismatic) ahead of ASM-008's wider joint
 * vocabulary, `rigidPoseSchema` inherits `point3Schema`'s own extent
 * refinement rather than duplicating the bound, the solve-result/response
 * envelope round-trips every status and keeps its UUID arrays honest, and the
 * `protocolVersion` literal is actually load-bearing rather than decorative.
 */
import { describe, expect, it } from "vitest";

import {
  assemblyJointKindSchema,
  assemblyProtocolVersion,
  assemblyRequestSchema,
  assemblyResponseSchema,
  assemblySolveResultSchema,
  assemblySolveStatusSchema,
  point3Schema,
  rigidPoseSchema,
} from "../src/index.js";

function uuidAt(index: number): string {
  return `018f0f5d-0000-7000-8000-${index.toString(16).padStart(12, "0")}`;
}

const idGrounded = uuidAt(1);
const idFree = uuidAt(2);
const jointId = uuidAt(11);
const requestId = uuidAt(21);

const identityRotation = [1, 0, 0, 0, 1, 0, 0, 0, 1] as const;

function identityPose(
  position: readonly [number, number, number] = [0, 0, 0],
): unknown {
  return { position, rotation: identityRotation };
}

function validSolveRequest(overrides: Record<string, unknown> = {}): unknown {
  return {
    protocolVersion: assemblyProtocolVersion,
    requestId,
    method: "solve",
    fixture: {
      occurrences: [
        {
          occurrenceId: idGrounded,
          initialPose: identityPose(),
          grounded: true,
        },
        {
          occurrenceId: idFree,
          initialPose: identityPose([10, 0, 0]),
          grounded: false,
        },
      ],
      markers: [
        {
          markerId: "m-grounded",
          occurrenceId: idGrounded,
          localPose: identityPose(),
        },
        {
          markerId: "m-free",
          occurrenceId: idFree,
          localPose: identityPose(),
        },
      ],
      joints: [
        {
          jointId,
          kind: "fixed",
          markerI: "m-grounded",
          markerJ: "m-free",
        },
      ],
    },
    ...overrides,
  };
}

describe("assemblyRequestSchema minimal solve fixture", () => {
  it("parses one grounded occurrence, one free occurrence, one marker each, and one fixed joint", () => {
    const result = assemblyRequestSchema.safeParse(validSolveRequest());
    expect(result.success).toBe(true);
  });
});

describe("assemblyJointKindSchema (ASM-002 scope, ahead of ASM-008)", () => {
  it.each(["fixed", "revolute", "prismatic"])("accepts %s", (kind) => {
    expect(assemblyJointKindSchema.safeParse(kind).success).toBe(true);
  });

  it.each([
    "cylindrical",
    "planar",
    "ball",
    "pin-slot",
    "screw",
    "rigid-group",
    "FIXED",
    "",
  ])("rejects %s — not yet widened for ASM-008", (kind) => {
    expect(assemblyJointKindSchema.safeParse(kind).success).toBe(false);
  });
});

describe("rigidPoseSchema", () => {
  it("rejects a rotation tuple carrying a non-finite number", () => {
    const result = rigidPoseSchema.safeParse({
      position: [0, 0, 0],
      rotation: [1, 0, 0, 0, Number.NaN, 0, 0, 0, 1],
    });
    expect(result.success).toBe(false);
  });

  it("inherits point3Schema's own ±10,000,000 mm extent instead of a locally duplicated bound", () => {
    // point3Schema is the single source of this refinement; asserting
    // rigidPoseSchema's verdict against point3Schema's OWN verdict (rather than
    // hardcoding the bound a second time here) proves the position field is
    // composed from that schema, not reimplemented alongside it.
    const atExtent: [number, number, number] = [10_000_000, 0, 0];
    const pastExtent: [number, number, number] = [10_000_001, 0, 0];

    expect(point3Schema.safeParse(atExtent).success).toBe(true);
    expect(
      rigidPoseSchema.safeParse({
        position: atExtent,
        rotation: identityRotation,
      }).success,
    ).toBe(point3Schema.safeParse(atExtent).success);

    expect(point3Schema.safeParse(pastExtent).success).toBe(false);
    expect(
      rigidPoseSchema.safeParse({
        position: pastExtent,
        rotation: identityRotation,
      }).success,
    ).toBe(point3Schema.safeParse(pastExtent).success);
  });
});

describe("assemblySolveResultSchema", () => {
  function solveResult(
    status: (typeof assemblySolveStatusSchema.options)[number],
    overrides: Record<string, unknown> = {},
  ): unknown {
    return {
      status,
      poses: [
        {
          occurrenceId: idGrounded,
          pose: identityPose(),
          freeTranslationalDof: 0,
          freeRotationalDof: 0,
        },
        {
          occurrenceId: idFree,
          pose: identityPose([10, 0, 0]),
          freeTranslationalDof: status === "under_constrained" ? 3 : 0,
          freeRotationalDof: status === "under_constrained" ? 3 : 0,
        },
      ],
      totalFreeDof: status === "under_constrained" ? 6 : 0,
      conflictingJointIds: status === "conflicting" ? [jointId] : [],
      redundantJointIds: status === "redundant" ? [jointId] : [],
      message: `solve status: ${status}`,
      iterationCount: 3,
      elapsedMs: 1.5,
      ...overrides,
    };
  }

  it.each(assemblySolveStatusSchema.options)(
    "round-trips a %s solve result",
    (status) => {
      expect(
        assemblySolveResultSchema.safeParse(solveResult(status)).success,
      ).toBe(true);
    },
  );

  it("rejects a non-uuid entry in conflictingJointIds", () => {
    const result = assemblySolveResultSchema.safeParse(
      solveResult("conflicting", { conflictingJointIds: ["not-a-uuid"] }),
    );
    expect(result.success).toBe(false);
  });

  it("rejects a non-uuid entry in redundantJointIds", () => {
    const result = assemblySolveResultSchema.safeParse(
      solveResult("redundant", { redundantJointIds: ["not-a-uuid"] }),
    );
    expect(result.success).toBe(false);
  });
});

describe("assemblyResponseSchema ok discrimination", () => {
  function solvedResult(): unknown {
    return {
      type: "solve",
      status: "solved",
      poses: [
        {
          occurrenceId: idGrounded,
          pose: identityPose(),
          freeTranslationalDof: 0,
          freeRotationalDof: 0,
        },
      ],
      totalFreeDof: 0,
      conflictingJointIds: [],
      redundantJointIds: [],
      message: "fully constrained",
      iterationCount: 1,
      elapsedMs: 0.5,
    };
  }

  it("accepts an ok:true response carrying a solve result", () => {
    const response = {
      protocolVersion: assemblyProtocolVersion,
      requestId,
      ok: true,
      result: solvedResult(),
    };
    expect(assemblyResponseSchema.safeParse(response).success).toBe(true);
  });

  it("accepts an ok:false response carrying an error", () => {
    const response = {
      protocolVersion: assemblyProtocolVersion,
      requestId,
      ok: false,
      error: { code: "BUSY", message: "assembly host is busy" },
    };
    expect(assemblyResponseSchema.safeParse(response).success).toBe(true);
  });

  it("rejects an ok:true response carrying an error field instead of a result", () => {
    const response = {
      protocolVersion: assemblyProtocolVersion,
      requestId,
      ok: true,
      error: { code: "BUSY", message: "x" },
    };
    expect(assemblyResponseSchema.safeParse(response).success).toBe(false);
  });

  it("rejects an ok:false response carrying a result field instead of an error", () => {
    const response = {
      protocolVersion: assemblyProtocolVersion,
      requestId,
      ok: false,
      result: solvedResult(),
    };
    expect(assemblyResponseSchema.safeParse(response).success).toBe(false);
  });

  it("accepts a cancellation result whose targetRequestId is a uuid", () => {
    const response = {
      protocolVersion: assemblyProtocolVersion,
      requestId,
      ok: true,
      result: { type: "cancellation", targetRequestId: idGrounded },
    };
    expect(assemblyResponseSchema.safeParse(response).success).toBe(true);
  });

  it("rejects a cancellation result whose targetRequestId is not a uuid", () => {
    const response = {
      protocolVersion: assemblyProtocolVersion,
      requestId,
      ok: true,
      result: { type: "cancellation", targetRequestId: "not-a-uuid" },
    };
    expect(assemblyResponseSchema.safeParse(response).success).toBe(false);
  });
});

describe("assemblyProtocolVersion is load-bearing", () => {
  it("parses the minimal solve fixture at the current protocol version", () => {
    expect(assemblyRequestSchema.safeParse(validSolveRequest()).success).toBe(
      true,
    );
  });

  it("fails to parse the same request under a different protocolVersion literal", () => {
    const result = assemblyRequestSchema.safeParse(
      validSolveRequest({ protocolVersion: assemblyProtocolVersion + 1 }),
    );
    expect(result.success).toBe(false);
  });
});
