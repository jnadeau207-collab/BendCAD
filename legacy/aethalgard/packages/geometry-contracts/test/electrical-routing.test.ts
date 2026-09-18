import { describe, expect, it } from "vitest";

import {
  knownOperationTypes,
  operationSchema,
  stagedOperationTypes,
  wireOperationSchema,
  wireRouteOperationSchema,
} from "../src/index.js";

/**
 * Electrical/routing wave 1 — schema contracts for `wire_route`, landed
 * alongside (but from a workstream independent of) the native kernel
 * dispatch for this type. Mirrors the sheet-metal-operations.test.ts /
 * surfacing-operations.test.ts pattern: every schema branch pinned here;
 * document-model acceptance/dependency behavior gets its own test file
 * (document-model/test/electrical-routing.test.ts), and the fail-closed
 * kernel refusal is pinned in kernel-client's own suite.
 *
 * `wire_route` carries TWO required ref slots (`startVertex`, `endVertex`),
 * so — like `edge_flange` and unlike the ref-slot-free surfacing wave 1
 * types — the "fully specified" test below checks individual subfields
 * rather than a whole-object `toEqual`: parsing merges the ref envelope's
 * own defaults (`arity`, `anchors`, `onEmpty`) into each slot.
 */

const uuid = (n: number): string =>
  `018f0f5d-4444-7000-8000-${n.toString(16).padStart(12, "0")}`;

const metadata = {
  createdAt: "2026-08-04T09:00:00.000Z",
  createdBy: { kind: "user" },
} as const;

const validWireRoute = {
  id: uuid(1),
  type: "wire_route",
  schemaVersion: 1,
  name: "Route the harness lead",
  outputBodyId: uuid(2),
  parameters: {
    startVertex: { query: `vertices(op(${uuid(3)}))` },
    endVertex: { query: `vertices(op(${uuid(4)}))` },
    waypoints: [
      [10, 0, 5],
      [10, 20, 5],
    ],
    diameterMm: 3,
    minimumBendRadiusMm: 12,
    wireType: "wire",
    netName: "SIG_1",
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

describe("wireRouteOperationSchema", () => {
  it("accepts a fully specified production operation", () => {
    const parsed = wireRouteOperationSchema.parse(validWireRoute);
    expect(parsed.parameters.startVertex.query).toBe(
      validWireRoute.parameters.startVertex.query,
    );
    expect(parsed.parameters.endVertex.query).toBe(
      validWireRoute.parameters.endVertex.query,
    );
    expect(parsed.parameters.waypoints).toEqual(
      validWireRoute.parameters.waypoints,
    );
    expect(parsed.parameters.diameterMm).toBe(3);
    expect(parsed.parameters.minimumBendRadiusMm).toBe(12);
    expect(parsed.parameters.wireType).toBe("wire");
    expect(parsed.parameters.netName).toBe("SIG_1");
  });

  it("applies the ref envelope defaults to both the startVertex and endVertex slots", () => {
    const parsed = wireRouteOperationSchema.parse(validWireRoute);
    expect(parsed.parameters.startVertex.arity).toBe("one");
    expect(parsed.parameters.startVertex.onEmpty).toBe("error");
    expect(parsed.parameters.startVertex.anchors).toEqual([]);
    expect(parsed.parameters.endVertex.arity).toBe("one");
    expect(parsed.parameters.endVertex.onEmpty).toBe("error");
    expect(parsed.parameters.endVertex.anchors).toEqual([]);
  });

  it("defaults waypoints to an empty array when omitted", () => {
    const parsed = wireRouteOperationSchema.parse(
      withoutParameterKeys(validWireRoute, ["waypoints"]),
    );
    expect(parsed.parameters.waypoints).toEqual([]);
  });

  it("accepts an explicitly empty waypoints array — a direct point-to-point run is legal, unlike sweep's required 2-point path", () => {
    expect(
      wireRouteOperationSchema.safeParse(
        withParameters(validWireRoute, { waypoints: [] }),
      ).success,
    ).toBe(true);
  });

  it("accepts up to 64 waypoints and rejects 65", () => {
    const sixtyFour = Array.from({ length: 64 }, (_, index) => [index, 0, 0]);
    expect(
      wireRouteOperationSchema.safeParse(
        withParameters(validWireRoute, { waypoints: sixtyFour }),
      ).success,
    ).toBe(true);
    const sixtyFive = Array.from({ length: 65 }, (_, index) => [index, 0, 0]);
    expect(
      wireRouteOperationSchema.safeParse(
        withParameters(validWireRoute, { waypoints: sixtyFive }),
      ).success,
    ).toBe(false);
  });

  it("rejects a waypoint outside the supported modeling extent (point3Schema reused directly)", () => {
    expect(
      wireRouteOperationSchema.safeParse(
        withParameters(validWireRoute, {
          waypoints: [[20_000_000, 0, 0]],
        }),
      ).success,
    ).toBe(false);
  });

  it("defaults wireType to wire when omitted", () => {
    const parsed = wireRouteOperationSchema.parse(
      withoutParameterKeys(validWireRoute, ["wireType"]),
    );
    expect(parsed.parameters.wireType).toBe("wire");
  });

  it("accepts the cable wireType", () => {
    expect(
      wireRouteOperationSchema.safeParse(
        withParameters(validWireRoute, { wireType: "cable" }),
      ).success,
    ).toBe(true);
  });

  it("rejects unknown wireType values", () => {
    expect(
      wireRouteOperationSchema.safeParse(
        withParameters(validWireRoute, { wireType: "conduit" }),
      ).success,
    ).toBe(false);
  });

  it("leaves netName undefined when omitted (true optional, no schema default)", () => {
    const parsed = wireRouteOperationSchema.parse(
      withoutParameterKeys(validWireRoute, ["netName"]),
    );
    expect(parsed.parameters.netName).toBeUndefined();
  });

  it("rejects an empty-string netName", () => {
    expect(
      wireRouteOperationSchema.safeParse(
        withParameters(validWireRoute, { netName: "" }),
      ).success,
    ).toBe(false);
  });

  it("rejects a netName over 120 characters", () => {
    expect(
      wireRouteOperationSchema.safeParse(
        withParameters(validWireRoute, { netName: "x".repeat(121) }),
      ).success,
    ).toBe(false);
  });

  it.each(invalidMillimeters)("rejects invalid diameterMm %s", (value) => {
    expect(() =>
      wireRouteOperationSchema.parse(
        withParameters(validWireRoute, { diameterMm: value }),
      ),
    ).toThrow();
  });

  it.each(invalidMillimeters)(
    "rejects invalid minimumBendRadiusMm %s",
    (value) => {
      expect(() =>
        wireRouteOperationSchema.parse(
          withParameters(validWireRoute, { minimumBendRadiusMm: value }),
        ),
      ).toThrow();
    },
  );

  it("rejects a missing startVertex (required, no legal absent case)", () => {
    expect(() =>
      wireRouteOperationSchema.parse(
        withoutParameterKeys(validWireRoute, ["startVertex"]),
      ),
    ).toThrow();
  });

  it("rejects a missing endVertex (required, no legal absent case)", () => {
    expect(() =>
      wireRouteOperationSchema.parse(
        withoutParameterKeys(validWireRoute, ["endVertex"]),
      ),
    ).toThrow();
  });

  it("rejects a non-uuid-scoped startVertex/endVertex query only insofar as the envelope requires a non-empty string", () => {
    // Full AQL grammar/kind validation is document-model's job (plan 05
    // §4.2); the geometry-contracts envelope only requires a non-empty,
    // length-bounded query string. Proven end to end (kind-mismatch,
    // rootedness) in document-model/test/electrical-routing.test.ts.
    expect(
      wireRouteOperationSchema.safeParse(
        withParameters(validWireRoute, { startVertex: { query: "" } }),
      ).success,
    ).toBe(false);
  });

  it("rejects a missing output body id: wire_route produces a body", () => {
    expect(() =>
      wireRouteOperationSchema.parse(
        withoutKeys(validWireRoute, ["outputBodyId"]),
      ),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      wireRouteOperationSchema.parse({
        ...validWireRoute,
        legacyId: "not-allowed",
      }),
    ).toThrow();
    expect(() =>
      wireRouteOperationSchema.parse(
        withParameters(validWireRoute, { simplify: true }),
      ),
    ).toThrow();
  });
});

describe("operationSchema (union routing for electrical wave 1)", () => {
  it("discriminates the wire_route operation by type", () => {
    expect(operationSchema.parse(validWireRoute).type).toBe("wire_route");
  });

  it("enforces per-type strictness through the union too", () => {
    expect(() =>
      operationSchema.parse(
        withParameters(validWireRoute, { wireType: "conduit" }),
      ),
    ).toThrow();
    expect(() =>
      operationSchema.parse(
        withoutParameterKeys(validWireRoute, ["endVertex"]),
      ),
    ).toThrow();
  });
});

describe("wireOperationSchema (kernel-wire routing for electrical wave 1)", () => {
  it("validates both startVertex and endVertex against the wire {ast} form", () => {
    const wireWireRoute = {
      ...validWireRoute,
      parameters: {
        ...validWireRoute.parameters,
        startVertex: {
          ast: {
            kind: "vertices",
            scope: [{ source: "op", opId: uuid(3) }],
            filters: [],
          },
          arity: "one",
          anchors: [],
          onEmpty: "error",
        },
        endVertex: {
          ast: {
            kind: "vertices",
            scope: [{ source: "op", opId: uuid(4) }],
            filters: [],
          },
          arity: "one",
          anchors: [],
          onEmpty: "error",
        },
      },
    };
    const parsed = wireOperationSchema.parse(wireWireRoute);
    if (parsed.type !== "wire_route") throw new Error("wrong type");
    expect(parsed.parameters.startVertex.ast).toEqual({
      kind: "vertices",
      scope: [{ source: "op", opId: uuid(3) }],
      filters: [],
    });
    expect(parsed.parameters.endVertex.ast).toEqual({
      kind: "vertices",
      scope: [{ source: "op", opId: uuid(4) }],
      filters: [],
    });

    // The persisted {query} form is refused on the wire (ast is required)…
    expect(wireOperationSchema.safeParse(validWireRoute).success).toBe(false);
    // …and symmetrically the wire {ast} form is refused by the persisted
    // union (query is required) — the two schemas never accept each other's
    // ref-slot shape, exactly like fillet v2 / shell / mirror / datum_* /
    // edge_flange.
    expect(operationSchema.safeParse(wireWireRoute).success).toBe(false);
  });
});

describe("knownOperationTypes", () => {
  it("includes the electrical wave 1 type", () => {
    expect(knownOperationTypes.has("wire_route")).toBe(true);
  });
});

describe("stagedOperationTypes", () => {
  it("stages wire_route from day one", () => {
    // The exhaustive membership pin lives in catalog-wave1-operations.test.ts;
    // this is a locality check next to the schema it stages.
    expect(stagedOperationTypes.has("wire_route")).toBe(true);
  });
});
