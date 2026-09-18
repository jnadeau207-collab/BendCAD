import { describe, expect, it } from "vitest";

import {
  draftAngleToleranceDegSchema,
  knownOperationTypes,
  moldPartingLineOperationSchema,
  moldPartingSurfaceOperationSchema,
  moldShutoffSurfaceOperationSchema,
  moldToolingSplitOperationSchema,
  operationSchema,
  pullDirectionSchema,
  stagedOperationTypes,
  wireOperationSchema,
} from "../src/index.js";

/**
 * Mold/tooling wave 1 — schema contracts for `mold_parting_line` /
 * `mold_shutoff_surface` / `mold_parting_surface` / `mold_tooling_split`,
 * landed alongside (but from a workstream independent of) the native kernel
 * dispatch for these four types. Mirrors the sheet-metal-operations.test.ts /
 * surfacing-operations.test.ts pattern: every schema branch pinned here;
 * document-model acceptance/dependency behavior gets its own test file
 * (document-model/test/mold-tooling-operations.test.ts), the
 * `mold_draft_analysis` kernel query gets its own
 * (mold-draft-analysis-protocol.test.ts), and the fail-closed kernel
 * refusal is pinned in kernel-client's own suite.
 *
 * None of the four carries a topology ref slot — every `*OperationId`
 * parameter is an operation-id reference, mirroring `boundary_surface`'s own
 * precedent exactly (see that file's own header comment).
 */

const uuid = (n: number): string =>
  `018f0f5d-5555-7000-8000-${n.toString(16).padStart(12, "0")}`;

const metadata = {
  createdAt: "2026-08-05T09:00:00.000Z",
  createdBy: { kind: "user" },
} as const;

const validPartingLine = {
  id: uuid(1),
  type: "mold_parting_line",
  schemaVersion: 1,
  name: "Parting line",
  outputBodyId: uuid(2),
  parameters: {
    targetOperationId: uuid(3),
    pullDirection: { x: 0, y: 0, z: 1 },
    draftAngleToleranceDeg: 0.5,
  },
  metadata,
} as const;

const validShutoffSurface = {
  id: uuid(10),
  type: "mold_shutoff_surface",
  schemaVersion: 1,
  name: "Shut-off surface",
  outputBodyId: uuid(11),
  parameters: {
    targetOperationId: uuid(3),
    partingLineOperationId: uuid(1),
  },
  metadata,
} as const;

const validPartingSurface = {
  id: uuid(20),
  type: "mold_parting_surface",
  schemaVersion: 1,
  name: "Parting surface",
  outputBodyId: uuid(21),
  parameters: {
    partingLineOperationId: uuid(1),
    shutoffSurfaceOperationId: uuid(11),
    extensionDistanceMm: 25,
  },
  metadata,
} as const;

const validToolingSplit = {
  id: uuid(30),
  type: "mold_tooling_split",
  schemaVersion: 1,
  name: "Tooling split",
  outputBodyId: uuid(31),
  outputBodyIds: [uuid(31), uuid(32)],
  parameters: {
    targetOperationId: uuid(3),
    partingSurfaceOperationId: uuid(21),
    shutoffSurfaceOperationId: uuid(11),
    block: { marginXMm: 20, marginYMm: 20, marginZMm: 20 },
    extraSplitSurfaceOperationIds: [uuid(40)],
  },
  metadata,
} as const;

function withParameters(
  operation: Record<string, unknown>,
  parameters: Record<string, unknown>,
): Record<string, unknown> {
  return {
    ...operation,
    parameters: {
      ...(operation.parameters as Record<string, unknown>),
      ...parameters,
    },
  };
}

function withoutParameterKeys(
  operation: Record<string, unknown>,
  keys: readonly string[],
): Record<string, unknown> {
  return {
    ...operation,
    parameters: Object.fromEntries(
      Object.entries(operation.parameters as Record<string, unknown>).filter(
        ([key]) => !keys.includes(key),
      ),
    ),
  };
}

function withoutKeys(
  operation: Record<string, unknown>,
  keys: readonly string[],
): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(operation).filter(([key]) => !keys.includes(key)),
  );
}

describe("pullDirectionSchema", () => {
  it("accepts a unit vector object, not a tuple", () => {
    expect(pullDirectionSchema.parse({ x: 0, y: 0, z: 1 })).toEqual({
      x: 0,
      y: 0,
      z: 1,
    });
  });

  it("accepts a non-unit, non-zero vector (normalization is not schema-enforced)", () => {
    expect(pullDirectionSchema.safeParse({ x: 3, y: 4, z: 0 }).success).toBe(
      true,
    );
  });

  it("rejects the zero vector", () => {
    expect(pullDirectionSchema.safeParse({ x: 0, y: 0, z: 0 }).success).toBe(
      false,
    );
  });

  it("rejects a tuple — the shape is a keyed object, not [x,y,z]", () => {
    expect(pullDirectionSchema.safeParse([0, 0, 1]).success).toBe(false);
  });

  it("rejects a partial object and unknown keys", () => {
    expect(pullDirectionSchema.safeParse({ x: 0, y: 0 }).success).toBe(false);
    expect(
      pullDirectionSchema.safeParse({ x: 0, y: 0, z: 1, w: 0 }).success,
    ).toBe(false);
  });

  it("rejects non-finite components", () => {
    for (const bad of [Number.NaN, Number.POSITIVE_INFINITY]) {
      expect(
        pullDirectionSchema.safeParse({ x: bad, y: 0, z: 1 }).success,
        String(bad),
      ).toBe(false);
    }
  });
});

describe("draftAngleToleranceDegSchema", () => {
  it("defaults to 0.5", () => {
    expect(draftAngleToleranceDegSchema.parse(undefined)).toBe(0.5);
  });

  it("accepts the boundaries 0 and 30", () => {
    expect(draftAngleToleranceDegSchema.safeParse(0).success).toBe(true);
    expect(draftAngleToleranceDegSchema.safeParse(30).success).toBe(true);
  });

  it("rejects outside [0, 30] and non-finite values", () => {
    for (const bad of [-0.001, 30.001, Number.NaN, Number.POSITIVE_INFINITY]) {
      expect(
        draftAngleToleranceDegSchema.safeParse(bad).success,
        String(bad),
      ).toBe(false);
    }
  });
});

describe("moldPartingLineOperationSchema", () => {
  it("accepts a fully specified production operation", () => {
    expect(moldPartingLineOperationSchema.parse(validPartingLine)).toEqual(
      validPartingLine,
    );
  });

  it("defaults draftAngleToleranceDeg to 0.5 when omitted", () => {
    const parsed = moldPartingLineOperationSchema.parse(
      withoutParameterKeys(validPartingLine, ["draftAngleToleranceDeg"]),
    );
    expect(parsed.parameters.draftAngleToleranceDeg).toBe(0.5);
  });

  it("rejects a missing targetOperationId", () => {
    expect(() =>
      moldPartingLineOperationSchema.parse(
        withoutParameterKeys(validPartingLine, ["targetOperationId"]),
      ),
    ).toThrow();
  });

  it("rejects a non-uuid targetOperationId", () => {
    expect(() =>
      moldPartingLineOperationSchema.parse(
        withParameters(validPartingLine, { targetOperationId: "not-a-uuid" }),
      ),
    ).toThrow();
  });

  it("rejects a missing pullDirection", () => {
    expect(() =>
      moldPartingLineOperationSchema.parse(
        withoutParameterKeys(validPartingLine, ["pullDirection"]),
      ),
    ).toThrow();
  });

  it("rejects a tuple-shaped pullDirection", () => {
    expect(
      moldPartingLineOperationSchema.safeParse(
        withParameters(validPartingLine, { pullDirection: [0, 0, 1] }),
      ).success,
    ).toBe(false);
  });

  it("rejects a zero-vector pullDirection", () => {
    expect(
      moldPartingLineOperationSchema.safeParse(
        withParameters(validPartingLine, {
          pullDirection: { x: 0, y: 0, z: 0 },
        }),
      ).success,
    ).toBe(false);
  });

  it("rejects draftAngleToleranceDeg outside [0, 30]", () => {
    for (const bad of [-1, 30.5, Number.NaN]) {
      expect(
        moldPartingLineOperationSchema.safeParse(
          withParameters(validPartingLine, { draftAngleToleranceDeg: bad }),
        ).success,
        String(bad),
      ).toBe(false);
    }
  });

  it("rejects a missing output body id: mold_parting_line produces a body", () => {
    expect(() =>
      moldPartingLineOperationSchema.parse(
        withoutKeys(validPartingLine, ["outputBodyId"]),
      ),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      moldPartingLineOperationSchema.parse({
        ...validPartingLine,
        legacyId: "not-allowed",
      }),
    ).toThrow();
    expect(() =>
      moldPartingLineOperationSchema.parse(
        withParameters(validPartingLine, { simplify: true }),
      ),
    ).toThrow();
  });
});

describe("moldShutoffSurfaceOperationSchema", () => {
  it("accepts a fully specified production operation", () => {
    expect(
      moldShutoffSurfaceOperationSchema.parse(validShutoffSurface),
    ).toEqual(validShutoffSurface);
  });

  it("rejects a missing targetOperationId or partingLineOperationId", () => {
    expect(() =>
      moldShutoffSurfaceOperationSchema.parse(
        withoutParameterKeys(validShutoffSurface, ["targetOperationId"]),
      ),
    ).toThrow();
    expect(() =>
      moldShutoffSurfaceOperationSchema.parse(
        withoutParameterKeys(validShutoffSurface, ["partingLineOperationId"]),
      ),
    ).toThrow();
  });

  it("rejects a non-uuid targetOperationId or partingLineOperationId", () => {
    expect(() =>
      moldShutoffSurfaceOperationSchema.parse(
        withParameters(validShutoffSurface, { targetOperationId: "nope" }),
      ),
    ).toThrow();
    expect(() =>
      moldShutoffSurfaceOperationSchema.parse(
        withParameters(validShutoffSurface, {
          partingLineOperationId: "nope",
        }),
      ),
    ).toThrow();
  });

  it("rejects a missing output body id: mold_shutoff_surface produces a body", () => {
    expect(() =>
      moldShutoffSurfaceOperationSchema.parse(
        withoutKeys(validShutoffSurface, ["outputBodyId"]),
      ),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      moldShutoffSurfaceOperationSchema.parse({
        ...validShutoffSurface,
        legacyId: "not-allowed",
      }),
    ).toThrow();
    expect(() =>
      moldShutoffSurfaceOperationSchema.parse(
        withParameters(validShutoffSurface, { simplify: true }),
      ),
    ).toThrow();
  });
});

describe("moldPartingSurfaceOperationSchema", () => {
  it("accepts a fully specified production operation with a shutoff reference", () => {
    expect(
      moldPartingSurfaceOperationSchema.parse(validPartingSurface),
    ).toEqual(validPartingSurface);
  });

  it("accepts an omitted shutoffSurfaceOperationId (a true optional)", () => {
    const parsed = moldPartingSurfaceOperationSchema.parse(
      withoutParameterKeys(validPartingSurface, ["shutoffSurfaceOperationId"]),
    );
    expect(parsed.parameters.shutoffSurfaceOperationId).toBeUndefined();
  });

  it("rejects a missing partingLineOperationId", () => {
    expect(() =>
      moldPartingSurfaceOperationSchema.parse(
        withoutParameterKeys(validPartingSurface, ["partingLineOperationId"]),
      ),
    ).toThrow();
  });

  it("rejects a non-uuid partingLineOperationId or shutoffSurfaceOperationId", () => {
    expect(() =>
      moldPartingSurfaceOperationSchema.parse(
        withParameters(validPartingSurface, {
          partingLineOperationId: "nope",
        }),
      ),
    ).toThrow();
    expect(() =>
      moldPartingSurfaceOperationSchema.parse(
        withParameters(validPartingSurface, {
          shutoffSurfaceOperationId: "nope",
        }),
      ),
    ).toThrow();
  });

  it("rejects extensionDistanceMm that is zero, negative, or non-finite", () => {
    for (const bad of [0, -1, Number.NaN, Number.POSITIVE_INFINITY]) {
      expect(
        moldPartingSurfaceOperationSchema.safeParse(
          withParameters(validPartingSurface, { extensionDistanceMm: bad }),
        ).success,
        String(bad),
      ).toBe(false);
    }
  });

  it("rejects a missing output body id: mold_parting_surface produces a body", () => {
    expect(() =>
      moldPartingSurfaceOperationSchema.parse(
        withoutKeys(validPartingSurface, ["outputBodyId"]),
      ),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      moldPartingSurfaceOperationSchema.parse({
        ...validPartingSurface,
        legacyId: "not-allowed",
      }),
    ).toThrow();
    expect(() =>
      moldPartingSurfaceOperationSchema.parse(
        withParameters(validPartingSurface, { simplify: true }),
      ),
    ).toThrow();
  });
});

describe("moldToolingSplitOperationSchema", () => {
  it("accepts a fully specified production operation with an insert split", () => {
    const parsed = moldToolingSplitOperationSchema.parse(validToolingSplit);
    expect(parsed.outputBodyIds).toEqual([uuid(31), uuid(32)]);
    expect(parsed.parameters.extraSplitSurfaceOperationIds).toEqual([uuid(40)]);
  });

  it("accepts the minimal core+cavity pair with no shutoff or extra splits", () => {
    const minimal = {
      ...withoutParameterKeys(validToolingSplit, [
        "shutoffSurfaceOperationId",
        "extraSplitSurfaceOperationIds",
      ]),
    };
    expect(moldToolingSplitOperationSchema.safeParse(minimal).success).toBe(
      true,
    );
  });

  it("accepts an outputBodyIds set larger than 2 (core, cavity, inserts)", () => {
    const threeBody = {
      ...validToolingSplit,
      outputBodyIds: [uuid(31), uuid(32), uuid(33)],
      parameters: {
        ...validToolingSplit.parameters,
        extraSplitSurfaceOperationIds: [uuid(40)],
      },
    };
    expect(moldToolingSplitOperationSchema.safeParse(threeBody).success).toBe(
      true,
    );
  });

  it("requires outputBodyIds (no default, unlike import_step's optional field)", () => {
    const withoutSet = withoutKeys(validToolingSplit, ["outputBodyIds"]);
    expect(() => moldToolingSplitOperationSchema.parse(withoutSet)).toThrow();
  });

  it("requires outputBodyIds to have at least 2 elements — never just 1", () => {
    expect(() =>
      moldToolingSplitOperationSchema.parse({
        ...validToolingSplit,
        outputBodyIds: [uuid(31)],
      }),
    ).toThrow();
    expect(() =>
      moldToolingSplitOperationSchema.parse({
        ...validToolingSplit,
        outputBodyIds: [],
      }),
    ).toThrow();
  });

  it("accepts up to 64 outputBodyIds and rejects 65", () => {
    const sixtyFour = Array.from({ length: 64 }, (_unused, index) =>
      uuid(1000 + index),
    );
    expect(
      moldToolingSplitOperationSchema.safeParse({
        ...validToolingSplit,
        outputBodyId: sixtyFour[0],
        outputBodyIds: sixtyFour,
      }).success,
    ).toBe(true);
    const sixtyFive = Array.from({ length: 65 }, (_unused, index) =>
      uuid(2000 + index),
    );
    expect(
      moldToolingSplitOperationSchema.safeParse({
        ...validToolingSplit,
        outputBodyId: sixtyFive[0],
        outputBodyIds: sixtyFive,
      }).success,
    ).toBe(false);
  });

  it("rejects a non-uuid element in outputBodyIds", () => {
    expect(() =>
      moldToolingSplitOperationSchema.parse({
        ...validToolingSplit,
        outputBodyIds: [uuid(31), "not-a-uuid"],
      }),
    ).toThrow();
  });

  it("rejects a missing targetOperationId or partingSurfaceOperationId", () => {
    expect(() =>
      moldToolingSplitOperationSchema.parse(
        withoutParameterKeys(validToolingSplit, ["targetOperationId"]),
      ),
    ).toThrow();
    expect(() =>
      moldToolingSplitOperationSchema.parse(
        withoutParameterKeys(validToolingSplit, ["partingSurfaceOperationId"]),
      ),
    ).toThrow();
  });

  it("accepts an omitted shutoffSurfaceOperationId (a true optional)", () => {
    const parsed = moldToolingSplitOperationSchema.parse(
      withoutParameterKeys(validToolingSplit, ["shutoffSurfaceOperationId"]),
    );
    expect(parsed.parameters.shutoffSurfaceOperationId).toBeUndefined();
  });

  it("rejects negative block margins but accepts exactly zero", () => {
    expect(
      moldToolingSplitOperationSchema.safeParse(
        withParameters(validToolingSplit, {
          block: { marginXMm: -0.001, marginYMm: 20, marginZMm: 20 },
        }),
      ).success,
    ).toBe(false);
    expect(
      moldToolingSplitOperationSchema.safeParse(
        withParameters(validToolingSplit, {
          block: { marginXMm: 0, marginYMm: 0, marginZMm: 0 },
        }),
      ).success,
    ).toBe(true);
  });

  it("rejects non-finite block margins", () => {
    expect(
      moldToolingSplitOperationSchema.safeParse(
        withParameters(validToolingSplit, {
          block: { marginXMm: Number.NaN, marginYMm: 20, marginZMm: 20 },
        }),
      ).success,
    ).toBe(false);
  });

  it("rejects a missing block", () => {
    expect(() =>
      moldToolingSplitOperationSchema.parse(
        withoutParameterKeys(validToolingSplit, ["block"]),
      ),
    ).toThrow();
  });

  it("accepts an omitted extraSplitSurfaceOperationIds (a true optional)", () => {
    const parsed = moldToolingSplitOperationSchema.parse(
      withoutParameterKeys(validToolingSplit, [
        "extraSplitSurfaceOperationIds",
      ]),
    );
    expect(parsed.parameters.extraSplitSurfaceOperationIds).toBeUndefined();
  });

  it("accepts up to 16 extraSplitSurfaceOperationIds and rejects 17", () => {
    const sixteen = Array.from({ length: 16 }, (_unused, index) =>
      uuid(3000 + index),
    );
    expect(
      moldToolingSplitOperationSchema.safeParse(
        withParameters(validToolingSplit, {
          extraSplitSurfaceOperationIds: sixteen,
        }),
      ).success,
    ).toBe(true);
    const seventeen = Array.from({ length: 17 }, (_unused, index) =>
      uuid(4000 + index),
    );
    expect(
      moldToolingSplitOperationSchema.safeParse(
        withParameters(validToolingSplit, {
          extraSplitSurfaceOperationIds: seventeen,
        }),
      ).success,
    ).toBe(false);
  });

  it("rejects a missing output body id: mold_tooling_split produces a body", () => {
    expect(() =>
      moldToolingSplitOperationSchema.parse(
        withoutKeys(validToolingSplit, ["outputBodyId"]),
      ),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      moldToolingSplitOperationSchema.parse({
        ...validToolingSplit,
        legacyId: "not-allowed",
      }),
    ).toThrow();
    expect(() =>
      moldToolingSplitOperationSchema.parse(
        withParameters(validToolingSplit, { simplify: true }),
      ),
    ).toThrow();
  });

  it(
    "does NOT itself enforce outputBodyIds[0] === outputBodyId — that " +
      "cross-field invariant is @aeth/document-model's document identity " +
      "pass (addOperationIdentityIssues), exactly as it is for import_step " +
      "and unfold, deliberately not a .refine() here (see the schema doc " +
      "comment: a refinement would break the agent tool registry's .omit())",
    () => {
      const mismatched = {
        ...validToolingSplit,
        outputBodyId: uuid(999),
      };
      expect(
        moldToolingSplitOperationSchema.safeParse(mismatched).success,
      ).toBe(true);
    },
  );
});

describe("operationSchema (union routing for mold/tooling wave 1)", () => {
  it("discriminates every mold/tooling operation by type", () => {
    expect(operationSchema.parse(validPartingLine).type).toBe(
      "mold_parting_line",
    );
    expect(operationSchema.parse(validShutoffSurface).type).toBe(
      "mold_shutoff_surface",
    );
    expect(operationSchema.parse(validPartingSurface).type).toBe(
      "mold_parting_surface",
    );
    expect(operationSchema.parse(validToolingSplit).type).toBe(
      "mold_tooling_split",
    );
  });

  it("enforces per-type strictness through the union too", () => {
    expect(() =>
      operationSchema.parse(
        withParameters(validPartingLine, {
          pullDirection: { x: 0, y: 0, z: 0 },
        }),
      ),
    ).toThrow();
    expect(() =>
      operationSchema.parse({
        ...validToolingSplit,
        outputBodyIds: [uuid(31)],
      }),
    ).toThrow();
  });
});

describe("wireOperationSchema (kernel-wire routing for mold/tooling wave 1)", () => {
  it("reuses the persisted schema unchanged for all four types (no ref slots anywhere in this wave)", () => {
    expect(wireOperationSchema.parse(validPartingLine)).toEqual(
      validPartingLine,
    );
    expect(wireOperationSchema.parse(validShutoffSurface)).toEqual(
      validShutoffSurface,
    );
    expect(wireOperationSchema.parse(validPartingSurface)).toEqual(
      validPartingSurface,
    );
    expect(wireOperationSchema.parse(validToolingSplit)).toEqual(
      validToolingSplit,
    );
  });
});

describe("knownOperationTypes", () => {
  it("includes the mold/tooling wave 1 types", () => {
    expect(knownOperationTypes.has("mold_parting_line")).toBe(true);
    expect(knownOperationTypes.has("mold_shutoff_surface")).toBe(true);
    expect(knownOperationTypes.has("mold_parting_surface")).toBe(true);
    expect(knownOperationTypes.has("mold_tooling_split")).toBe(true);
  });

  it("does NOT include mold_draft_analysis — it is not an operation", () => {
    expect(knownOperationTypes.has("mold_draft_analysis")).toBe(false);
  });
});

describe("stagedOperationTypes", () => {
  it("stages every mold/tooling wave 1 type from day one", () => {
    // The exhaustive membership pin lives in catalog-wave1-operations.test.ts;
    // this is a locality check next to the schemas it stages.
    expect(stagedOperationTypes.has("mold_parting_line")).toBe(true);
    expect(stagedOperationTypes.has("mold_shutoff_surface")).toBe(true);
    expect(stagedOperationTypes.has("mold_parting_surface")).toBe(true);
    expect(stagedOperationTypes.has("mold_tooling_split")).toBe(true);
  });
});
