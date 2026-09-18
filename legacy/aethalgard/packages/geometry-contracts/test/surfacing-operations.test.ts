import { describe, expect, it } from "vitest";

import {
  boundarySurfaceOperationSchema,
  knownOperationTypes,
  operationSchema,
  stagedOperationTypes,
  stitchOperationSchema,
  surfaceOffsetOperationSchema,
  thickenOperationSchema,
  wireOperationSchema,
} from "../src/index.js";

/**
 * Surfacing wave 1 — schema contracts for `boundary_surface` / `surface_offset`
 * / `stitch` / `thicken`, landed alongside (but from a workstream independent
 * of) the native kernel dispatch for these four types. Mirrors the
 * sheet-metal-operations.test.ts pattern: every schema branch pinned here;
 * document-model acceptance/dependency behavior gets its own test file
 * (document-model/test/surfacing-operations.test.ts), and the fail-closed
 * kernel refusal is pinned in kernel-client's own suite.
 */

const uuid = (n: number): string =>
  `018f0f5d-3333-7000-8000-${n.toString(16).padStart(12, "0")}`;

const metadata = {
  createdAt: "2026-08-04T09:00:00.000Z",
  createdBy: { kind: "user" },
} as const;

const validBoundarySurface = {
  id: uuid(1),
  type: "boundary_surface",
  schemaVersion: 1,
  name: "Fill the open end",
  outputBodyId: uuid(2),
  parameters: {
    targetOperationId: uuid(3),
  },
  metadata,
} as const;

const validSurfaceOffset = {
  id: uuid(10),
  type: "surface_offset",
  schemaVersion: 1,
  name: "Offset the patch",
  outputBodyId: uuid(11),
  parameters: {
    targetOperationId: uuid(2),
    distanceMm: 2.5,
  },
  metadata,
} as const;

const validStitch = {
  id: uuid(20),
  type: "stitch",
  schemaVersion: 1,
  name: "Sew the panels",
  outputBodyId: uuid(21),
  parameters: {
    firstOperationId: uuid(2),
    secondOperationId: uuid(11),
    toleranceMm: 0.05,
  },
  metadata,
} as const;

const validThicken = {
  id: uuid(30),
  type: "thicken",
  schemaVersion: 1,
  name: "Thicken the patch",
  outputBodyId: uuid(31),
  parameters: {
    targetOperationId: uuid(2),
    thicknessMm: 1.5,
    direction: "normal",
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

const invalidMillimeters = [
  0,
  -1,
  Number.NaN,
  Number.POSITIVE_INFINITY,
  1_000_001,
] as const;

describe("boundarySurfaceOperationSchema", () => {
  it("accepts a fully specified production operation", () => {
    expect(boundarySurfaceOperationSchema.parse(validBoundarySurface)).toEqual(
      validBoundarySurface,
    );
  });

  it("has no edge selector: targetOperationId is the only parameter", () => {
    // Deliberate v1 scope (see the schema doc comment): the v1 selector
    // grammar has no predicate for "free/open boundary edges", and the
    // native executor resolves the target's whole free boundary itself
    // rather than an authored selection — so a would-be boundaryEdges ref is
    // rejected as an unknown field, exactly like any other schema drift.
    expect(
      boundarySurfaceOperationSchema.safeParse(
        withParameters(validBoundarySurface, {
          boundaryEdges: { query: `edges(op(${uuid(3)}))` },
        }),
      ).success,
    ).toBe(false);
  });

  it("rejects a missing targetOperationId", () => {
    expect(() =>
      boundarySurfaceOperationSchema.parse(
        withoutParameterKeys(validBoundarySurface, ["targetOperationId"]),
      ),
    ).toThrow();
  });

  it("rejects a non-uuid targetOperationId", () => {
    expect(() =>
      boundarySurfaceOperationSchema.parse(
        withParameters(validBoundarySurface, {
          targetOperationId: "not-a-uuid",
        }),
      ),
    ).toThrow();
  });

  it("rejects a missing output body id: boundary_surface produces a body", () => {
    expect(() =>
      boundarySurfaceOperationSchema.parse(
        withoutKeys(validBoundarySurface, ["outputBodyId"]),
      ),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      boundarySurfaceOperationSchema.parse({
        ...validBoundarySurface,
        legacyId: "not-allowed",
      }),
    ).toThrow();
    expect(() =>
      boundarySurfaceOperationSchema.parse(
        withParameters(validBoundarySurface, { simplify: true }),
      ),
    ).toThrow();
  });
});

describe("surfaceOffsetOperationSchema", () => {
  it("accepts a fully specified production operation", () => {
    expect(surfaceOffsetOperationSchema.parse(validSurfaceOffset)).toEqual(
      validSurfaceOffset,
    );
  });

  it("accepts both a positive and a negative non-zero distance", () => {
    for (const distanceMm of [0.001, 1, 1_000_000, -0.001, -1, -1_000_000]) {
      expect(
        surfaceOffsetOperationSchema.safeParse(
          withParameters(validSurfaceOffset, { distanceMm }),
        ).success,
        `distanceMm ${String(distanceMm)}`,
      ).toBe(true);
    }
  });

  it("rejects a distance of exactly zero — a zero offset is not an edit", () => {
    expect(
      surfaceOffsetOperationSchema.safeParse(
        withParameters(validSurfaceOffset, { distanceMm: 0 }),
      ).success,
    ).toBe(false);
    expect(
      surfaceOffsetOperationSchema.safeParse(
        withParameters(validSurfaceOffset, { distanceMm: -0 }),
      ).success,
    ).toBe(false);
  });

  it("rejects a distance beyond the modeling extent, and non-finite values", () => {
    for (const distanceMm of [
      1_000_001,
      -1_000_001,
      Number.NaN,
      Number.POSITIVE_INFINITY,
      Number.NEGATIVE_INFINITY,
    ]) {
      expect(
        surfaceOffsetOperationSchema.safeParse(
          withParameters(validSurfaceOffset, { distanceMm }),
        ).success,
        `distanceMm ${String(distanceMm)}`,
      ).toBe(false);
    }
  });

  it("rejects a non-uuid targetOperationId", () => {
    expect(() =>
      surfaceOffsetOperationSchema.parse(
        withParameters(validSurfaceOffset, {
          targetOperationId: "not-a-uuid",
        }),
      ),
    ).toThrow();
  });

  it("rejects a missing output body id: surface_offset produces a body", () => {
    expect(() =>
      surfaceOffsetOperationSchema.parse(
        withoutKeys(validSurfaceOffset, ["outputBodyId"]),
      ),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      surfaceOffsetOperationSchema.parse({
        ...validSurfaceOffset,
        legacyId: "not-allowed",
      }),
    ).toThrow();
    expect(() =>
      surfaceOffsetOperationSchema.parse(
        withParameters(validSurfaceOffset, { simplify: true }),
      ),
    ).toThrow();
  });
});

describe("stitchOperationSchema", () => {
  it("accepts a fully specified production operation", () => {
    expect(stitchOperationSchema.parse(validStitch)).toEqual(validStitch);
  });

  it("defaults toleranceMm to 0.01 when omitted", () => {
    const parsed = stitchOperationSchema.parse(
      withoutParameterKeys(validStitch, ["toleranceMm"]),
    );
    expect(parsed.parameters.toleranceMm).toBe(0.01);
  });

  it.each(invalidMillimeters)("rejects invalid toleranceMm %s", (value) => {
    expect(() =>
      stitchOperationSchema.parse(
        withParameters(validStitch, { toleranceMm: value }),
      ),
    ).toThrow();
  });

  it("rejects firstOperationId and secondOperationId being the same operation", () => {
    const result = stitchOperationSchema.safeParse(
      withParameters(validStitch, { secondOperationId: uuid(2) }),
    );
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(
        result.error.issues.some(
          (issue) =>
            issue.message ===
              "firstOperationId and secondOperationId must reference distinct operations" &&
            issue.path.at(-1) === "secondOperationId",
        ),
      ).toBe(true);
    }
  });

  it("rejects a non-uuid firstOperationId or secondOperationId", () => {
    expect(() =>
      stitchOperationSchema.parse(
        withParameters(validStitch, { firstOperationId: "not-a-uuid" }),
      ),
    ).toThrow();
    expect(() =>
      stitchOperationSchema.parse(
        withParameters(validStitch, { secondOperationId: "not-a-uuid" }),
      ),
    ).toThrow();
  });

  it("rejects a missing output body id: stitch produces a body", () => {
    expect(() =>
      stitchOperationSchema.parse(withoutKeys(validStitch, ["outputBodyId"])),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      stitchOperationSchema.parse({ ...validStitch, legacyId: "not-allowed" }),
    ).toThrow();
    expect(() =>
      stitchOperationSchema.parse(
        withParameters(validStitch, { simplify: true }),
      ),
    ).toThrow();
  });
});

describe("thickenOperationSchema", () => {
  it("accepts a fully specified production operation", () => {
    expect(thickenOperationSchema.parse(validThicken)).toEqual(validThicken);
  });

  it("defaults direction to normal when omitted", () => {
    const parsed = thickenOperationSchema.parse(
      withoutParameterKeys(validThicken, ["direction"]),
    );
    expect(parsed.parameters.direction).toBe("normal");
  });

  it("accepts reverse and symmetric directions", () => {
    for (const direction of ["reverse", "symmetric"]) {
      expect(
        thickenOperationSchema.safeParse(
          withParameters(validThicken, { direction }),
        ).success,
        direction,
      ).toBe(true);
    }
  });

  it("rejects unknown direction values", () => {
    expect(
      thickenOperationSchema.safeParse(
        withParameters(validThicken, { direction: "sideways" }),
      ).success,
    ).toBe(false);
  });

  it.each(invalidMillimeters)("rejects invalid thicknessMm %s", (value) => {
    expect(() =>
      thickenOperationSchema.parse(
        withParameters(validThicken, { thicknessMm: value }),
      ),
    ).toThrow();
  });

  it("rejects a non-uuid targetOperationId", () => {
    expect(() =>
      thickenOperationSchema.parse(
        withParameters(validThicken, { targetOperationId: "not-a-uuid" }),
      ),
    ).toThrow();
  });

  it("rejects a missing output body id: thicken produces a body", () => {
    expect(() =>
      thickenOperationSchema.parse(withoutKeys(validThicken, ["outputBodyId"])),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      thickenOperationSchema.parse({
        ...validThicken,
        legacyId: "not-allowed",
      }),
    ).toThrow();
    expect(() =>
      thickenOperationSchema.parse(
        withParameters(validThicken, { simplify: true }),
      ),
    ).toThrow();
  });
});

describe("operationSchema (union routing for surfacing wave 1)", () => {
  it("discriminates every surfacing operation by type", () => {
    expect(operationSchema.parse(validBoundarySurface).type).toBe(
      "boundary_surface",
    );
    expect(operationSchema.parse(validSurfaceOffset).type).toBe(
      "surface_offset",
    );
    expect(operationSchema.parse(validStitch).type).toBe("stitch");
    expect(operationSchema.parse(validThicken).type).toBe("thicken");
  });

  it("enforces per-type strictness through the union too", () => {
    expect(() =>
      operationSchema.parse(
        withParameters(validSurfaceOffset, { distanceMm: 0 }),
      ),
    ).toThrow();
    expect(() =>
      operationSchema.parse(
        withParameters(validStitch, { secondOperationId: uuid(2) }),
      ),
    ).toThrow();
  });
});

describe("wireOperationSchema (kernel-wire routing for surfacing wave 1)", () => {
  it("reuses the persisted schema unchanged for all four types (no ref slots anywhere in this wave)", () => {
    // boundary_surface carries no ref slot (see its schema doc comment: no
    // v1 selector predicate exists for "free/open boundary edges", so the
    // native executor resolves the boundary directly from the target's own
    // topology) — so, like surface_offset/stitch/thicken, it needs no
    // `…SchemaWith(wireOperationRefSchema)` wire variant at all.
    expect(wireOperationSchema.parse(validBoundarySurface)).toEqual(
      validBoundarySurface,
    );
    expect(wireOperationSchema.parse(validSurfaceOffset)).toEqual(
      validSurfaceOffset,
    );
    expect(wireOperationSchema.parse(validStitch)).toEqual(validStitch);
    expect(wireOperationSchema.parse(validThicken)).toEqual(validThicken);
  });
});

describe("knownOperationTypes", () => {
  it("includes the surfacing wave 1 types", () => {
    expect(knownOperationTypes.has("boundary_surface")).toBe(true);
    expect(knownOperationTypes.has("surface_offset")).toBe(true);
    expect(knownOperationTypes.has("stitch")).toBe(true);
    expect(knownOperationTypes.has("thicken")).toBe(true);
  });
});

describe("stagedOperationTypes", () => {
  it("stages every surfacing wave 1 type from day one", () => {
    // The exhaustive membership pin lives in catalog-wave1-operations.test.ts;
    // this is a locality check next to the schemas it stages.
    expect(stagedOperationTypes.has("boundary_surface")).toBe(true);
    expect(stagedOperationTypes.has("surface_offset")).toBe(true);
    expect(stagedOperationTypes.has("stitch")).toBe(true);
    expect(stagedOperationTypes.has("thicken")).toBe(true);
  });
});
