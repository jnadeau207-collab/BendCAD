/**
 * Durable assembly endpoint schema (ASM-005, `assembly-endpoint.ts`, spec
 * §3/§5): `assemblyEndpointSchema` accepts a well-formed `{ occurrenceId,
 * selector, expectedGeometry }` for every declared `expectedGeometry`, its
 * top-level `.refine` refuses a selector whose arity cannot resolve to
 * exactly one entity, `expectedGeometry` stays a closed enum, and the two
 * component-id brands parse only a real UUID. `assemblyEndpointGeometryRules`
 * is the TS half of a cross-language pin whose native mirror lives in
 * `native/kernel-host/src/mate_frame.cpp` — proven equal here, key by key,
 * against the literal table quoted in `assembly-endpoint.ts` and against the
 * committed `fixtures/assemblies/mate-frame-geometry-classes.json`.
 */
import { readFileSync } from "node:fs";

import { describe, expect, it } from "vitest";

import {
  assemblyEndpointGeometryRules,
  assemblyEndpointGeometrySchema,
  assemblyEndpointSchema,
  componentDefinitionIdSchema,
  componentOccurrenceIdSchema,
  type AssemblyEndpointGeometry,
  type ComponentDefinitionId,
  type ComponentOccurrenceId,
} from "../src/index.js";

function uuidAt(index: number): string {
  return `018f0f5d-0000-7000-8000-${index.toString(16).padStart(12, "0")}`;
}

const occurrenceId = uuidAt(1);
const operationId = uuidAt(2);

function selector(overrides: Record<string, unknown> = {}): unknown {
  return {
    query: `faces(op(${operationId}))`,
    arity: "one",
    anchors: [],
    onEmpty: "error",
    ...overrides,
  };
}

function endpoint(
  expectedGeometry: unknown,
  overrides: Record<string, unknown> = {},
): unknown {
  return {
    occurrenceId,
    selector: selector(),
    expectedGeometry,
    ...overrides,
  };
}

describe("assemblyEndpointSchema — expectedGeometry coverage", () => {
  it.each(assemblyEndpointGeometrySchema.options)(
    "accepts a well-formed endpoint for expectedGeometry %s",
    (expectedGeometry) => {
      expect(
        assemblyEndpointSchema.safeParse(endpoint(expectedGeometry)).success,
      ).toBe(true);
    },
  );
});

describe("assemblyEndpointSchema — arity refusal (selector must resolve to exactly one entity)", () => {
  const refusalMessage =
    'An assembly endpoint selector must resolve to exactly one entity (arity "one")';

  it.each(["one-or-more", "any"] as const)(
    "rejects a selector whose arity is %s, with the documented refine message",
    (arity) => {
      const result = assemblyEndpointSchema.safeParse(
        endpoint("plane", { selector: selector({ arity }) }),
      );
      expect(result.success).toBe(false);
      if (result.success) return;
      expect(
        result.error.issues.some((issue) => issue.message === refusalMessage),
      ).toBe(true);
      expect(
        result.error.issues.some(
          (issue) =>
            issue.path.length === 2 &&
            issue.path[0] === "selector" &&
            issue.path[1] === "arity",
        ),
      ).toBe(true);
    },
  );

  it("rejects a {min,max} range arity, with the documented refine message", () => {
    const result = assemblyEndpointSchema.safeParse(
      endpoint("plane", {
        selector: selector({ arity: { min: 1, max: 3 } }),
      }),
    );
    expect(result.success).toBe(false);
    if (result.success) return;
    expect(
      result.error.issues.some((issue) => issue.message === refusalMessage),
    ).toBe(true);
  });

  it('accepts the default arity ("one") that the refusal cases deviate from', () => {
    expect(assemblyEndpointSchema.safeParse(endpoint("plane")).success).toBe(
      true,
    );
  });
});

describe("assemblyEndpointSchema — expectedGeometry enum rejection", () => {
  it("rejects an expectedGeometry value outside the declared union", () => {
    expect(assemblyEndpointSchema.safeParse(endpoint("torus")).success).toBe(
      false,
    );
  });

  it("rejects a missing expectedGeometry", () => {
    const withoutGeometry = endpoint("plane") as Record<string, unknown>;
    delete withoutGeometry.expectedGeometry;
    expect(assemblyEndpointSchema.safeParse(withoutGeometry).success).toBe(
      false,
    );
  });
});

describe("componentDefinitionIdSchema / componentOccurrenceIdSchema", () => {
  const validUuid = uuidAt(3);

  it("accepts a v4-shaped UUID string", () => {
    expect(componentDefinitionIdSchema.safeParse(validUuid).success).toBe(true);
    expect(componentOccurrenceIdSchema.safeParse(validUuid).success).toBe(true);
  });

  it("rejects a non-UUID string", () => {
    expect(componentDefinitionIdSchema.safeParse("not-a-uuid").success).toBe(
      false,
    );
    expect(componentOccurrenceIdSchema.safeParse("not-a-uuid").success).toBe(
      false,
    );
  });

  // Compile-time-only: this package's tsconfig `include` is `src/**/*.ts`
  // (test/ is excluded from `tsc -b`), so nothing in `pnpm check:static`
  // currently gates a `@ts-expect-error` in this file. It is asserted anyway
  // because the brand is a real structural property of these schemas — a
  // bare `string` (no nominal brand tag) is not assignable to the branded
  // output type without going through `.parse`/`.safeParse`.
  it("brands ComponentDefinitionId/ComponentOccurrenceId against a bare string", () => {
    const bareDefinitionId: string = validUuid;
    const bareOccurrenceId: string = validUuid;
    // @ts-expect-error a bare `string` lacks ComponentDefinitionId's brand tag
    const brandedDefinitionId: ComponentDefinitionId = bareDefinitionId;
    // @ts-expect-error a bare `string` lacks ComponentOccurrenceId's brand tag
    const brandedOccurrenceId: ComponentOccurrenceId = bareOccurrenceId;
    expect(brandedDefinitionId).toBe(validUuid);
    expect(brandedOccurrenceId).toBe(validUuid);
  });
});

describe("assemblyEndpointGeometryRules — cross-language pin", () => {
  // Quoted verbatim from `assembly-endpoint.ts`'s own table and its RULING
  // comment: "axis" and "line" share the identical analytic requirement (a
  // straight edge/datum axis, CurveClass === "line"); "coordinate_frame" is
  // structurally accepted but has no resolvable selectorKind/analyticClasses
  // because no kernel operation in this tree can produce one yet.
  const documentedRules: Record<
    AssemblyEndpointGeometry,
    {
      readonly selectorKind: "faces" | "edges" | "vertices" | undefined;
      readonly analyticClasses: readonly string[] | undefined;
    }
  > = {
    point: { selectorKind: "vertices", analyticClasses: ["point"] },
    line: { selectorKind: "edges", analyticClasses: ["line"] },
    axis: { selectorKind: "edges", analyticClasses: ["line"] },
    circle: { selectorKind: "edges", analyticClasses: ["circle"] },
    plane: { selectorKind: "faces", analyticClasses: ["plane"] },
    cylinder: { selectorKind: "faces", analyticClasses: ["cylinder"] },
    cone: { selectorKind: "faces", analyticClasses: ["cone"] },
    sphere: { selectorKind: "faces", analyticClasses: ["sphere"] },
    coordinate_frame: { selectorKind: undefined, analyticClasses: undefined },
  };

  it.each(assemblyEndpointGeometrySchema.options)(
    "matches the documented rule for %s exactly",
    (geometry) => {
      expect(assemblyEndpointGeometryRules[geometry]).toEqual(
        documentedRules[geometry],
      );
    },
  );

  it("carries exactly the declared expectedGeometry keys, no more and no fewer", () => {
    expect(Object.keys(assemblyEndpointGeometryRules).sort()).toEqual(
      [...assemblyEndpointGeometrySchema.options].sort(),
    );
  });

  it("equals the committed native cross-language pin fixture", () => {
    // Mirrors the `readFileSync(new URL(..., import.meta.url), "utf8")`
    // idiom used by `operation-hash.test.ts` (this same package) and
    // `document-model/test/selector-print-golden.test.ts` to resolve a
    // repo-root `fixtures/` path from a package's `test/` directory.
    const fixture: unknown = JSON.parse(
      readFileSync(
        new URL(
          "../../../fixtures/assemblies/mate-frame-geometry-classes.json",
          import.meta.url,
        ),
        "utf8",
      ),
    );
    // JSON has no `undefined`: the committed fixture (and `mate_frame.cpp`'s
    // own copy of this table) represents `coordinate_frame`'s unresolvable
    // rule as explicit `null` fields rather than omitting the keys, so the
    // JSON-shape projection normalizes the same way before comparing.
    const jsonShape = Object.fromEntries(
      Object.entries(assemblyEndpointGeometryRules).map(([geometry, rule]) => [
        geometry,
        {
          selectorKind: rule.selectorKind ?? null,
          analyticClasses: rule.analyticClasses ?? null,
        },
      ]),
    );
    expect(fixture).toEqual(jsonShape);
  });
});
