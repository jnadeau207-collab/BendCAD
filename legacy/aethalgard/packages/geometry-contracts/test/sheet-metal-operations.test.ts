import { describe, expect, it } from "vitest";

import {
  baseFlangeOperationSchema,
  edgeFlangeOperationSchema,
  knownOperationTypes,
  operationSchema,
  stagedOperationTypes,
  unfoldOperationSchema,
  wireOperationSchema,
} from "../src/index.js";

/**
 * Sheet-metal wave 1 — schema contracts for `base_flange` / `edge_flange` /
 * `unfold`, landed alongside (but from a workstream independent of) the
 * native kernel dispatch for these three types. Mirrors the
 * catalog-wave1-operations.test.ts pattern: every schema branch pinned here;
 * document-model acceptance/dependency behavior gets its own test file
 * (document-model/test/sheet-metal-operations.test.ts), and the fail-closed
 * kernel refusal is pinned in kernel-client's own suite.
 */

const uuid = (n: number): string =>
  `018f0f5d-1111-7000-8000-${n.toString(16).padStart(12, "0")}`;

const metadata = {
  createdAt: "2026-08-04T09:00:00.000Z",
  createdBy: { kind: "user" },
} as const;

const validBaseFlange = {
  id: uuid(1),
  type: "base_flange",
  schemaVersion: 1,
  name: "Base flange",
  outputBodyId: uuid(2),
  parameters: {
    profileOperationId: uuid(3),
    thicknessMm: 1.2,
    direction: "normal",
  },
  metadata,
} as const;

const validEdgeFlange = {
  id: uuid(10),
  type: "edge_flange",
  schemaVersion: 1,
  name: "Side flange",
  outputBodyId: uuid(11),
  parameters: {
    targetOperationId: uuid(2),
    edge: { query: `edges(op(${uuid(2)}))` },
    flangeLengthMm: 12,
    bendAngleDeg: 90,
    bendRadiusMm: 1.5,
    thicknessMm: 1.2,
    kFactor: 0.4,
    reliefType: "rectangular",
    reliefDepthMm: 0.5,
  },
  metadata,
} as const;

const validUnfold = {
  id: uuid(20),
  type: "unfold",
  schemaVersion: 1,
  name: "Flat pattern",
  outputBodyId: uuid(21),
  outputBodyIds: [uuid(21), uuid(22)],
  parameters: {
    targetOperationId: uuid(11),
    kFactorOverride: 0.42,
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

const invalidMillimeters = [
  0,
  -1,
  Number.NaN,
  Number.POSITIVE_INFINITY,
  1_000_001,
] as const;

describe("baseFlangeOperationSchema", () => {
  it("accepts a fully specified production operation", () => {
    expect(baseFlangeOperationSchema.parse(validBaseFlange)).toEqual(
      validBaseFlange,
    );
  });

  it("defaults direction to normal when omitted", () => {
    const parsed = baseFlangeOperationSchema.parse(
      withoutParameterKeys(validBaseFlange, ["direction"]),
    );
    expect(parsed.parameters.direction).toBe("normal");
  });

  it("accepts the reverse direction", () => {
    expect(
      baseFlangeOperationSchema.safeParse(
        withParameters(validBaseFlange, { direction: "reverse" }),
      ).success,
    ).toBe(true);
  });

  it("rejects unknown direction values", () => {
    expect(
      baseFlangeOperationSchema.safeParse(
        withParameters(validBaseFlange, { direction: "sideways" }),
      ).success,
    ).toBe(false);
  });

  it.each(invalidMillimeters)("rejects invalid thicknessMm %s", (value) => {
    expect(() =>
      baseFlangeOperationSchema.parse(
        withParameters(validBaseFlange, { thicknessMm: value }),
      ),
    ).toThrow();
  });

  it("rejects a non-uuid profileOperationId", () => {
    expect(() =>
      baseFlangeOperationSchema.parse(
        withParameters(validBaseFlange, { profileOperationId: "not-a-uuid" }),
      ),
    ).toThrow();
  });

  it("rejects a missing output body id: base_flange produces a body", () => {
    const withoutOutput = Object.fromEntries(
      Object.entries(validBaseFlange).filter(([key]) => key !== "outputBodyId"),
    );
    expect(() => baseFlangeOperationSchema.parse(withoutOutput)).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      baseFlangeOperationSchema.parse({
        ...validBaseFlange,
        legacyId: "not-allowed",
      }),
    ).toThrow();
    expect(() =>
      baseFlangeOperationSchema.parse(
        withParameters(validBaseFlange, { simplify: true }),
      ),
    ).toThrow();
  });
});

describe("edgeFlangeOperationSchema", () => {
  it("accepts a fully specified operation with an edge ref and explicit relief", () => {
    const parsed = edgeFlangeOperationSchema.parse(validEdgeFlange);
    expect(parsed.parameters.edge.query).toBe(
      validEdgeFlange.parameters.edge.query,
    );
    expect(parsed.parameters.kFactor).toBe(0.4);
    expect(parsed.parameters.reliefType).toBe("rectangular");
    expect(parsed.parameters.reliefDepthMm).toBe(0.5);
  });

  it("applies the ref envelope defaults to the edge slot", () => {
    const minimal = withParameters(validEdgeFlange, {
      edge: { query: `edges(op(${uuid(2)}))` },
    });
    const parsed = edgeFlangeOperationSchema.parse(minimal);
    expect(parsed.parameters.edge.arity).toBe("one");
    expect(parsed.parameters.edge.onEmpty).toBe("error");
    expect(parsed.parameters.edge.anchors).toEqual([]);
  });

  it("defaults kFactor to 0.44 and reliefType to rectangular when omitted", () => {
    const parsed = edgeFlangeOperationSchema.parse(
      withoutParameterKeys(validEdgeFlange, ["kFactor", "reliefType"]),
    );
    expect(parsed.parameters.kFactor).toBe(0.44);
    expect(parsed.parameters.reliefType).toBe("rectangular");
  });

  it("leaves reliefDepthMm undefined when omitted (no schema default)", () => {
    const parsed = edgeFlangeOperationSchema.parse(
      withoutParameterKeys(validEdgeFlange, ["reliefDepthMm"]),
    );
    expect(parsed.parameters.reliefDepthMm).toBeUndefined();
  });

  it("accepts bendAngleDeg at its boundaries: just above 0, and 180 (a hem)", () => {
    for (const bendAngleDeg of [0.0001, 1, 90, 179.9999, 180]) {
      expect(
        edgeFlangeOperationSchema.safeParse(
          withParameters(validEdgeFlange, { bendAngleDeg }),
        ).success,
        `bendAngleDeg ${String(bendAngleDeg)}`,
      ).toBe(true);
    }
  });

  it("rejects bendAngleDeg of 0 (not a bend) and anything past 180", () => {
    for (const bendAngleDeg of [
      0,
      -1,
      180.0001,
      181,
      360,
      Number.NaN,
      Number.POSITIVE_INFINITY,
      Number.NEGATIVE_INFINITY,
    ]) {
      expect(
        edgeFlangeOperationSchema.safeParse(
          withParameters(validEdgeFlange, { bendAngleDeg }),
        ).success,
        `bendAngleDeg ${String(bendAngleDeg)}`,
      ).toBe(false);
    }
  });

  it("accepts kFactor at its boundaries (0 and 1)", () => {
    for (const kFactor of [0, 1]) {
      expect(
        edgeFlangeOperationSchema.safeParse(
          withParameters(validEdgeFlange, { kFactor }),
        ).success,
        `kFactor ${String(kFactor)}`,
      ).toBe(true);
    }
  });

  it("rejects kFactor outside [0, 1]", () => {
    for (const kFactor of [-0.0001, 1.0001, -1, 2, Number.NaN]) {
      expect(
        edgeFlangeOperationSchema.safeParse(
          withParameters(validEdgeFlange, { kFactor }),
        ).success,
        `kFactor ${String(kFactor)}`,
      ).toBe(false);
    }
  });

  it.each(invalidMillimeters)("rejects invalid flangeLengthMm %s", (value) => {
    expect(() =>
      edgeFlangeOperationSchema.parse(
        withParameters(validEdgeFlange, { flangeLengthMm: value }),
      ),
    ).toThrow();
  });

  it.each(invalidMillimeters)("rejects invalid bendRadiusMm %s", (value) => {
    expect(() =>
      edgeFlangeOperationSchema.parse(
        withParameters(validEdgeFlange, { bendRadiusMm: value }),
      ),
    ).toThrow();
  });

  it.each(invalidMillimeters)("rejects invalid thicknessMm %s", (value) => {
    expect(() =>
      edgeFlangeOperationSchema.parse(
        withParameters(validEdgeFlange, { thicknessMm: value }),
      ),
    ).toThrow();
  });

  it("rejects a missing edge (required, unlike shell's optional openFaces)", () => {
    expect(() =>
      edgeFlangeOperationSchema.parse(
        withoutParameterKeys(validEdgeFlange, ["edge"]),
      ),
    ).toThrow();
  });

  it("rejects a non-uuid targetOperationId", () => {
    expect(() =>
      edgeFlangeOperationSchema.parse(
        withParameters(validEdgeFlange, { targetOperationId: "not-a-uuid" }),
      ),
    ).toThrow();
  });

  it("rejects unknown reliefType values", () => {
    expect(
      edgeFlangeOperationSchema.safeParse(
        withParameters(validEdgeFlange, { reliefType: "chamfered" }),
      ).success,
    ).toBe(false);
  });

  it("accepts the none relief type without a depth", () => {
    expect(
      edgeFlangeOperationSchema.safeParse(
        withoutParameterKeys(
          withParameters(validEdgeFlange, { reliefType: "none" }),
          ["reliefDepthMm"],
        ),
      ).success,
    ).toBe(true);
  });

  it("rejects a missing output body id: edge_flange produces a body", () => {
    const withoutOutput = Object.fromEntries(
      Object.entries(validEdgeFlange).filter(([key]) => key !== "outputBodyId"),
    );
    expect(() => edgeFlangeOperationSchema.parse(withoutOutput)).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      edgeFlangeOperationSchema.parse({
        ...validEdgeFlange,
        legacyId: "not-allowed",
      }),
    ).toThrow();
    expect(() =>
      edgeFlangeOperationSchema.parse(
        withParameters(validEdgeFlange, { simplify: true }),
      ),
    ).toThrow();
  });
});

describe("unfoldOperationSchema", () => {
  it("accepts a fully specified two-body birth", () => {
    const parsed = unfoldOperationSchema.parse(validUnfold);
    expect(parsed.outputBodyIds).toEqual([uuid(21), uuid(22)]);
    expect(parsed.parameters.kFactorOverride).toBe(0.42);
  });

  it("accepts an omitted kFactorOverride (a true optional)", () => {
    const parsed = unfoldOperationSchema.parse(
      withoutParameterKeys(validUnfold, ["kFactorOverride"]),
    );
    expect(parsed.parameters.kFactorOverride).toBeUndefined();
  });

  it("rejects kFactorOverride outside [0, 1]", () => {
    for (const kFactorOverride of [-0.0001, 1.0001, Number.NaN]) {
      expect(
        unfoldOperationSchema.safeParse(
          withParameters(validUnfold, { kFactorOverride }),
        ).success,
        `kFactorOverride ${String(kFactorOverride)}`,
      ).toBe(false);
    }
  });

  it("requires outputBodyIds (no default, unlike import_step's optional field)", () => {
    const withoutSet = Object.fromEntries(
      Object.entries(validUnfold).filter(
        (entry) => entry[0] !== "outputBodyIds",
      ),
    );
    expect(() => unfoldOperationSchema.parse(withoutSet)).toThrow();
  });

  it("requires outputBodyIds to have exactly two elements", () => {
    expect(() =>
      unfoldOperationSchema.parse({
        ...validUnfold,
        outputBodyIds: [uuid(21)],
      }),
    ).toThrow();
    expect(() =>
      unfoldOperationSchema.parse({
        ...validUnfold,
        outputBodyIds: [uuid(21), uuid(22), uuid(23)],
      }),
    ).toThrow();
    expect(() =>
      unfoldOperationSchema.parse({ ...validUnfold, outputBodyIds: [] }),
    ).toThrow();
  });

  it("rejects a non-uuid element in outputBodyIds", () => {
    expect(() =>
      unfoldOperationSchema.parse({
        ...validUnfold,
        outputBodyIds: [uuid(21), "not-a-uuid"],
      }),
    ).toThrow();
  });

  it("rejects a non-uuid targetOperationId", () => {
    expect(() =>
      unfoldOperationSchema.parse(
        withParameters(validUnfold, { targetOperationId: "not-a-uuid" }),
      ),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      unfoldOperationSchema.parse({ ...validUnfold, legacyId: "not-allowed" }),
    ).toThrow();
    expect(() =>
      unfoldOperationSchema.parse(
        withParameters(validUnfold, { simplify: true }),
      ),
    ).toThrow();
  });

  it(
    "does NOT itself enforce outputBodyIds[0] === outputBodyId — that " +
      "cross-field invariant is @aeth/document-model's document identity " +
      "pass (addOperationIdentityIssues), exactly as it is for import_step, " +
      "deliberately not a .refine() here (see the schema doc comment: a " +
      "refinement would break the agent tool registry's .omit())",
    () => {
      const mismatched = {
        ...validUnfold,
        outputBodyId: uuid(999),
        outputBodyIds: [uuid(21), uuid(22)],
      };
      // The schema alone accepts this even though outputBodyIds[0] !==
      // outputBodyId; @aeth/document-model/test/sheet-metal-operations.test.ts
      // proves the document-level pass refuses it.
      expect(unfoldOperationSchema.safeParse(mismatched).success).toBe(true);
    },
  );
});

describe("operationSchema (union routing for sheet-metal wave 1)", () => {
  it("discriminates every sheet-metal operation by type", () => {
    expect(operationSchema.parse(validBaseFlange).type).toBe("base_flange");
    expect(operationSchema.parse(validEdgeFlange).type).toBe("edge_flange");
    expect(operationSchema.parse(validUnfold).type).toBe("unfold");
  });

  it("enforces per-type strictness through the union too", () => {
    expect(() =>
      operationSchema.parse(
        withParameters(validEdgeFlange, { bendAngleDeg: 0 }),
      ),
    ).toThrow();
    expect(() =>
      operationSchema.parse(withParameters(validEdgeFlange, { kFactor: 1.5 })),
    ).toThrow();
    expect(() =>
      operationSchema.parse({
        ...validUnfold,
        outputBodyIds: [uuid(21)],
      }),
    ).toThrow();
  });
});

describe("wireOperationSchema (kernel-wire routing for sheet-metal wave 1)", () => {
  it("reuses the persisted schema unchanged for base_flange and unfold (no ref slots)", () => {
    expect(wireOperationSchema.parse(validBaseFlange)).toEqual(validBaseFlange);
    expect(wireOperationSchema.parse(validUnfold)).toEqual(validUnfold);
  });

  it("validates edge_flange's edge slot against the wire {ast} form", () => {
    const wireEdgeFlange = {
      ...validEdgeFlange,
      parameters: {
        ...validEdgeFlange.parameters,
        edge: {
          ast: {
            kind: "edges",
            scope: [{ source: "op", opId: uuid(2) }],
            filters: [],
          },
          arity: "one",
          anchors: [],
          onEmpty: "error",
        },
      },
    };
    const parsed = wireOperationSchema.parse(wireEdgeFlange);
    if (parsed.type !== "edge_flange") throw new Error("wrong type");
    expect(parsed.parameters.edge.ast).toEqual({
      kind: "edges",
      scope: [{ source: "op", opId: uuid(2) }],
      filters: [],
    });

    // The persisted {query} form is refused on the wire (ast is required)…
    expect(wireOperationSchema.safeParse(validEdgeFlange).success).toBe(false);
    // …and symmetrically the wire {ast} form is refused by the persisted
    // union (query is required) — the two schemas never accept each other's
    // ref-slot shape, exactly like fillet v2 / shell / mirror / datum_*.
    expect(operationSchema.safeParse(wireEdgeFlange).success).toBe(false);
  });
});

describe("knownOperationTypes", () => {
  it("includes the sheet-metal wave 1 types", () => {
    expect(knownOperationTypes.has("base_flange")).toBe(true);
    expect(knownOperationTypes.has("edge_flange")).toBe(true);
    expect(knownOperationTypes.has("unfold")).toBe(true);
  });
});

describe("stagedOperationTypes", () => {
  it("stages every sheet-metal wave 1 type from day one", () => {
    // The exhaustive membership pin lives in
    // catalog-wave1-operations.test.ts; this is a locality check next to the
    // schemas it stages.
    expect(stagedOperationTypes.has("base_flange")).toBe(true);
    expect(stagedOperationTypes.has("edge_flange")).toBe(true);
    expect(stagedOperationTypes.has("unfold")).toBe(true);
  });
});
