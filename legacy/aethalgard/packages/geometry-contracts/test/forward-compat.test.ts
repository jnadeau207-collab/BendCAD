import { describe, expect, it } from "vitest";

import {
  isKnownOperation,
  isUnknownOperation,
  knownOperationTypes,
  operationSchema,
  persistedOperationSchema,
  unknownOperationSchema,
} from "../src/index.js";

const uuid = (n: number): string =>
  `018f0f5d-0000-7000-8000-${n.toString(16).padStart(12, "0")}`;

const validBox = {
  id: uuid(1),
  type: "create_box",
  schemaVersion: 1,
  name: "Box",
  outputBodyId: uuid(2),
  parameters: {
    width: 10,
    depth: 10,
    height: 10,
    placement: {
      origin: [0, 0, 0],
      zDirection: [0, 0, 1],
      xDirection: [1, 0, 0],
    },
  },
  metadata: {
    createdAt: "2026-07-12T18:00:00.000Z",
    createdBy: { kind: "user" },
  },
};

// An operation authored by a NEWER build: a type this build has never heard of,
// carrying a vendor payload no known schema declares.
const futureOp = {
  id: uuid(3),
  type: "loft_multi_v9",
  schemaVersion: 9,
  name: "Future feature",
  profileOperationIds: [uuid(4)],
  vendorPayload: { blend: "cubic", nested: { depth: 3 } },
};

describe("known operation type set (Gate 9)", () => {
  it("names exactly the discriminated-union members", () => {
    expect(knownOperationTypes.size).toBe(40);
    expect(knownOperationTypes.has("fillet")).toBe(true);
    // CAP-035 piece 1: the entity sketch is a KNOWN kind the moment its schema
    // lands — a kind outside the union is not an operation kind at all. It is
    // staged (see catalog-wave1-operations) until piece 2 lands the executor.
    expect(knownOperationTypes.has("sketch")).toBe(true);
    // Fastener-after-snap (MASTER_PLAN §9): known but staged (kernel refuses
    // UNSUPPORTED_OPERATION until the native executor lands).
    expect(knownOperationTypes.has("bolt")).toBe(true);
    expect(knownOperationTypes.has("clasp")).toBe(true);
    // STEP ingestion (defect D-019): a known, executable body-birth operation.
    expect(knownOperationTypes.has("import_step")).toBe(true);
    // Mesh ingestion (defect D-023): likewise a known, executable body-birth.
    expect(knownOperationTypes.has("import_mesh")).toBe(true);
    // Catalog wave 1: known (Gate 9 no longer shields them) even though the
    // kernel refuses them UNSUPPORTED_OPERATION until native execution lands.
    expect(knownOperationTypes.has("shell")).toBe(true);
    expect(knownOperationTypes.has("datum_plane")).toBe(true);
    expect(knownOperationTypes.has("pattern_circular")).toBe(true);
    // Sheet-metal wave 1: known (Gate 9 no longer shields them) even though
    // the kernel refuses them UNSUPPORTED_OPERATION until native execution
    // lands (staged — see catalog-wave1-operations.test.ts's staged pin).
    expect(knownOperationTypes.has("base_flange")).toBe(true);
    expect(knownOperationTypes.has("edge_flange")).toBe(true);
    expect(knownOperationTypes.has("unfold")).toBe(true);
    // Surfacing wave 1: known (Gate 9 no longer shields them) even though
    // the kernel refuses them UNSUPPORTED_OPERATION until native execution
    // lands (staged — see catalog-wave1-operations.test.ts's staged pin).
    expect(knownOperationTypes.has("boundary_surface")).toBe(true);
    expect(knownOperationTypes.has("surface_offset")).toBe(true);
    expect(knownOperationTypes.has("stitch")).toBe(true);
    expect(knownOperationTypes.has("thicken")).toBe(true);
    // Electrical wave 1: known (Gate 9 no longer shields it) even though
    // the kernel refuses it UNSUPPORTED_OPERATION until native execution
    // lands (staged — see catalog-wave1-operations.test.ts's staged pin).
    expect(knownOperationTypes.has("wire_route")).toBe(true);
    // Mold/tooling wave 1: known (Gate 9 no longer shields them) even
    // though the kernel refuses them UNSUPPORTED_OPERATION until native
    // execution lands (staged — see catalog-wave1-operations.test.ts's
    // staged pin). `mold_draft_analysis` is deliberately NOT in this set:
    // it is a read-only top-level kernel RPC method, not an operation type.
    expect(knownOperationTypes.has("mold_parting_line")).toBe(true);
    expect(knownOperationTypes.has("mold_shutoff_surface")).toBe(true);
    expect(knownOperationTypes.has("mold_parting_surface")).toBe(true);
    expect(knownOperationTypes.has("mold_tooling_split")).toBe(true);
    expect(knownOperationTypes.has("mold_draft_analysis")).toBe(false);
    expect(knownOperationTypes.has("loft_multi_v9")).toBe(false);
  });
});

describe("persistedOperationSchema forward-compatibility", () => {
  it("parses a known operation through its fully typed schema", () => {
    const parsed = persistedOperationSchema.parse(validBox);
    expect(isKnownOperation(parsed)).toBe(true);
    expect(isUnknownOperation(parsed)).toBe(false);
    expect(parsed).toEqual(operationSchema.parse(validBox));
  });

  it("preserves an unknown future operation verbatim — never discards it", () => {
    const parsed = persistedOperationSchema.parse(futureOp);
    expect(isUnknownOperation(parsed)).toBe(true);
    expect(isKnownOperation(parsed)).toBe(false);
    // Every field survives, including the payload the schema never declared.
    expect(parsed).toEqual(futureOp);
  });

  it("still REJECTS a malformed KNOWN operation (corruption is not forward-compat)", () => {
    const malformedFillet = {
      id: uuid(5),
      type: "fillet",
      schemaVersion: 1,
      name: "x",
      // missing outputBodyId / parameters / metadata
    };
    expect(persistedOperationSchema.safeParse(malformedFillet).success).toBe(
      false,
    );
    // The unknown branch also refuses it: its type IS known, so it must satisfy
    // the typed schema rather than degrade to "unknown".
    expect(unknownOperationSchema.safeParse(malformedFillet).success).toBe(
      false,
    );
  });

  it("requires an id even on an unknown operation (identity namespaces span it)", () => {
    expect(
      persistedOperationSchema.safeParse({ type: "future_thing", foo: 1 })
        .success,
    ).toBe(false);
  });
});
