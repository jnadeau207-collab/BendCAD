import { describe, expect, it } from "vitest";

import { operationSchema, wireOperationSchema } from "../src/index.js";

const PROFILE = "11111111-1111-4111-8111-111111111111";
const SEED = "22222222-2222-4222-8222-222222222222";
const BODY = "33333333-3333-4333-8333-333333333333";
const OP = "44444444-4444-4444-8444-444444444444";

const metadata = {
  createdAt: "2026-08-09T00:00:00.000Z",
  createdBy: { kind: "user" as const },
};

const persistedRef = (query: string) => ({
  query,
  arity: "one" as const,
  anchors: [],
  onEmpty: "error" as const,
});
const wireRef = (kind: "edges" | "faces", operationId: string) => ({
  ast: {
    kind,
    scope: [{ source: "op" as const, opId: operationId }],
    filters: [],
  },
  arity: "one" as const,
  anchors: [],
  onEmpty: "error" as const,
});

function sweep(ref: ReturnType<typeof persistedRef>) {
  return {
    id: OP,
    type: "sweep" as const,
    schemaVersion: 2 as const,
    name: "Sweep",
    outputBodyId: BODY,
    parameters: {
      profileOperationId: PROFILE,
      path: [ref],
      guideRail: ref,
      guideSurface: persistedRef(`faces(op(${SEED}))`),
      boolean: { mode: "newBody" as const },
    },
    metadata,
  };
}

function validSweep() {
  return {
    id: OP,
    type: "sweep" as const,
    schemaVersion: 2 as const,
    name: "Sweep",
    outputBodyId: BODY,
    parameters: {
      profileOperationId: PROFILE,
      path: [persistedRef(`edges(op(${SEED}))`)],
      extent: { mode: "full" as const },
      orientation: "natural" as const,
      pathDirection: "forward" as const,
      boolean: { mode: "newBody" as const },
    },
    metadata,
  };
}

describe("associative Sweep constraints", () => {
  it("rejects simultaneous Sweep rail and surface guides before native evaluation", () => {
    const value = sweep(persistedRef(`edges(op(${SEED}))`));
    expect(operationSchema.safeParse(value).success).toBe(false);
  });

  it("enforces the same Sweep guide invariant on the wire surface", () => {
    const value = {
      ...sweep(persistedRef(`edges(op(${SEED}))`)),
      parameters: {
        ...sweep(persistedRef(`edges(op(${SEED}))`)).parameters,
        path: [wireRef("edges", SEED)],
        guideRail: wireRef("edges", SEED),
        guideSurface: wireRef("faces", SEED),
      },
    };
    expect(wireOperationSchema.safeParse(value).success).toBe(false);
  });

  it("rejects fixed orientation combined with a competing guide mode", () => {
    const base = validSweep();
    expect(
      operationSchema.safeParse({
        ...base,
        parameters: {
          ...base.parameters,
          orientation: "fixed",
          guideRail: persistedRef(`edges(op(${SEED}))`),
        },
      }).success,
    ).toBe(false);
    expect(
      wireOperationSchema.safeParse({
        ...base,
        parameters: {
          ...base.parameters,
          orientation: "fixed",
          path: [wireRef("edges", SEED)],
          guideSurface: wireRef("faces", SEED),
        },
      }).success,
    ).toBe(false);
  });

  it("rejects persisted Sweep refs whose topology head does not match the slot", () => {
    const base = validSweep();
    expect(operationSchema.safeParse(base).success).toBe(true);
    expect(
      operationSchema.safeParse({
        ...base,
        parameters: {
          ...base.parameters,
          path: [persistedRef(`faces(op(${SEED}))`)],
        },
      }).success,
    ).toBe(false);
    expect(
      operationSchema.safeParse({
        ...base,
        parameters: {
          ...base.parameters,
          guideRail: persistedRef(`faces(op(${SEED}))`),
        },
      }).success,
    ).toBe(false);
    expect(
      operationSchema.safeParse({
        ...base,
        parameters: {
          ...base.parameters,
          faceProfile: persistedRef(`edges(op(${SEED}))`),
          profileOperationId: undefined,
        },
      }).success,
    ).toBe(false);
  });

  it("rejects wire Sweep refs whose AST kind does not match the slot", () => {
    const base = {
      ...validSweep(),
      parameters: {
        ...validSweep().parameters,
        path: [wireRef("edges", SEED)],
      },
    };
    expect(wireOperationSchema.safeParse(base).success).toBe(true);
    expect(
      wireOperationSchema.safeParse({
        ...base,
        parameters: { ...base.parameters, path: [wireRef("faces", SEED)] },
      }).success,
    ).toBe(false);
    expect(
      wireOperationSchema.safeParse({
        ...base,
        parameters: {
          ...base.parameters,
          guideSurface: wireRef("edges", SEED),
        },
      }).success,
    ).toBe(false);
  });
});
