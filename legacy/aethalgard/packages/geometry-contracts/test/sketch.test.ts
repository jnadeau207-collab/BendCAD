/**
 * CAP-035 (split piece 1) — the `sketch` wire schema.
 *
 * Nothing user-visible ships with this schema, so the assertions have to carry
 * the whole weight: a sketch-bearing document round-trips byte-identically,
 * every invalid graph is refused by the LADDER's own code rather than a generic
 * parse error, and `create_profile` is untouched beside it.
 */
import { describe, expect, it } from "vitest";

import { canonicalOperationBytes } from "../src/operation-hash.js";
import {
  createProfileOperationSchema,
  knownOperationTypes,
  operationSchema,
  sketchOperationSchema,
  stagedOperationTypes,
  type SketchOperation,
} from "../src/operations.js";
import {
  sketchClosedRegion,
  sketchEntityDegeneracy,
  sketchParametersForHashing,
  sketchRegionExtent,
  validateSketch,
  type SketchEntity,
} from "../src/sketch.js";

const OP_ID = "11111111-1111-4111-8111-111111111111";
const ent = (suffix: string) => `ent_${suffix.padEnd(26, "0")}`;
const cst = (suffix: string) => `cst_${suffix.padEnd(26, "0")}`;

const plane = {
  query: `faces(op(${OP_ID})).role(top)`,
  arity: "one" as const,
  anchors: [],
  onEmpty: "error" as const,
};

function sketch(
  overrides: Partial<SketchOperation["parameters"]> = {},
): unknown {
  return {
    id: OP_ID,
    type: "sketch",
    schemaVersion: 1,
    name: "Sketch 1",
    parameters: { plane, entities: [], constraints: [], ...overrides },
    metadata: {
      createdAt: "2026-07-27T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  };
}

const line = (id: string, p1: [number, number], p2: [number, number]) =>
  ({ eid: ent(id), kind: "line", p1, p2, construction: false }) as SketchEntity;

describe("the operation envelope", () => {
  it("accepts an EMPTY sketch — plan 02 says zero entities is legal", () => {
    // Refusing this would make the first moment of every sketch an error.
    const parsed = sketchOperationSchema.safeParse(sketch());
    expect(parsed.success).toBe(true);
  });

  it("produces NO body — there is no outputBodyId to set", () => {
    const parsed = sketchOperationSchema.parse(sketch());
    expect("outputBodyId" in parsed).toBe(false);
    expect("outputProfileId" in parsed).toBe(false);
  });

  it("is .strict() — an unknown parameter is refused, not ignored", () => {
    const parsed = sketchOperationSchema.safeParse(
      sketch({ regions: [] } as never),
    );
    expect(parsed.success).toBe(false);
  });

  it("requires an OPERATION-level plane reference (ADR-003)", () => {
    const parsed = sketchOperationSchema.safeParse(
      sketch({ plane: undefined } as never),
    );
    expect(parsed.success).toBe(false);
  });

  it("preserves grounded entity ids as part of the typed persisted system", () => {
    const anchor = ent("A");
    const parsed = sketchOperationSchema.parse(
      sketch({
        entities: [line("A", [0, 0], [10, 0])],
        grounded: [anchor],
      }),
    );

    expect(parsed.parameters.grounded).toEqual([anchor]);
    expect("grounded" in sketchOperationSchema.parse(sketch()).parameters).toBe(
      false,
    );
  });

  it("persists projected geometry as a reference-bearing sketch member", () => {
    const parsed = sketchOperationSchema.parse(
      sketch({
        projected: [
          {
            eid: ent("P"),
            source: {
              query: `edges(op(${OP_ID})).role(top-edge)`,
              arity: "one",
              anchors: [],
              onEmpty: "error",
            },
            mode: "project",
            construction: true,
          },
        ],
      }),
    );
    expect(parsed.parameters.projected).toHaveLength(1);
    expect(parsed.parameters.projected[0]?.source.query).toContain("edges(op(");
    expect(parsed.parameters.projected[0]?.construction).toBe(true);
  });

  it("refuses a projected eid that collides with authored geometry", () => {
    const parsed = sketchOperationSchema.safeParse(
      sketch({
        entities: [line("A", [0, 0], [10, 0])],
        projected: [
          {
            eid: ent("A"),
            source: plane,
            mode: "project",
            construction: true,
          },
        ],
      }),
    );
    expect(parsed.success).toBe(false);
  });
});

describe("entity ids", () => {
  it("insists on the `ent_` + ULID form", () => {
    for (const bad of ["line-1", "ent_short", "ENT_" + "0".repeat(26)]) {
      const parsed = sketchOperationSchema.safeParse(
        sketch({
          entities: [
            { eid: bad, kind: "line", p1: [0, 0], p2: [10, 0] } as never,
          ],
        }),
      );
      expect(parsed.success, bad).toBe(false);
    }
  });

  it("rejects Crockford's excluded letters (I, L, O, U)", () => {
    // A ULID alphabet that accepted them would let two ids that read the same
    // to a person be different to the machine.
    const parsed = sketchOperationSchema.safeParse(
      sketch({
        entities: [
          { eid: `ent_${"I".repeat(26)}`, kind: "point", at: [0, 0] } as never,
        ],
      }),
    );
    expect(parsed.success).toBe(false);
  });
});

describe("all eleven plan-02 entity kinds parse", () => {
  it("round-trips one of each", () => {
    const entities = [
      { eid: ent("A"), kind: "point", at: [1, 2] },
      { eid: ent("B"), kind: "line", p1: [0, 0], p2: [10, 0] },
      {
        eid: ent("C"),
        kind: "polyline",
        points: [
          [0, 0],
          [5, 0],
          [5, 5],
        ],
      },
      {
        eid: ent("D"),
        kind: "rectangle",
        mode: "center",
        position: [0, 0],
        width: 20,
        height: 10,
      },
      { eid: ent("E"), kind: "circle", center: [0, 0], radius: 5 },
      {
        eid: ent("F"),
        kind: "arc-center",
        center: [0, 0],
        radius: 5,
        startAngle: 0,
        endAngle: 90,
      },
      {
        eid: ent("G"),
        kind: "arc-three-point",
        p1: [0, 0],
        p2: [5, 5],
        p3: [10, 0],
      },
      {
        eid: ent("H"),
        kind: "ellipse",
        center: [0, 0],
        radiusX: 4,
        radiusY: 8,
      },
      {
        eid: ent("J"),
        kind: "polygon",
        center: [0, 0],
        sides: 6,
        circumradius: 9,
      },
      { eid: ent("K"), kind: "slot", p1: [0, 0], p2: [20, 0], width: 6 },
      {
        eid: ent("M"),
        kind: "spline",
        points: [
          [0, 0],
          [5, 5],
          [10, 0],
        ],
      },
    ];
    const parsed = sketchOperationSchema.safeParse(
      sketch({ entities } as never),
    );
    expect(parsed.success).toBe(true);
    if (!parsed.success) return;
    expect(parsed.data.parameters.entities).toHaveLength(11);
    // `radiusX < radiusY` is legal — lowering swaps the major axis, so refusing
    // it here would reject a sketch the kernel builds correctly.
    const ellipse = parsed.data.parameters.entities.find(
      (entity) => entity.kind === "ellipse",
    );
    expect(ellipse?.kind === "ellipse" && ellipse.radiusX).toBe(4);
  });

  it("defaults construction to false and leaves snapHints absent", () => {
    const parsed = sketchOperationSchema.parse(
      sketch({ entities: [line("A", [0, 0], [10, 0])] } as never),
    );
    const entity = parsed.parameters.entities[0];
    expect(entity?.construction).toBe(false);
    // ABSENT, not present-and-empty: an optional field that materialises as []
    // would be a different document byte-for-byte on every round trip.
    expect(entity === undefined ? true : "snapHints" in entity).toBe(false);
  });
});

describe("the degeneracy ladder — E_SKETCH_ZERO_ENTITY", () => {
  it("refuses a line with coincident endpoints", () => {
    const issue = sketchEntityDegeneracy(line("A", [0, 0], [0, 0]));
    expect(issue?.code).toBe("E_SKETCH_ZERO_ENTITY");
    expect(issue?.message).toBe("A line needs two different endpoints.");
  });

  it("refuses a COLLINEAR three-point arc — it defines no circle", () => {
    const issue = sketchEntityDegeneracy({
      eid: ent("G"),
      kind: "arc-three-point",
      p1: [0, 0],
      p2: [5, 0],
      p3: [10, 0],
      construction: false,
    });
    expect(issue?.code).toBe("E_SKETCH_ZERO_ENTITY");
    expect(issue?.message).toContain("straight line");
  });

  it("accepts a three-point arc that is only NEARLY collinear", () => {
    // The bar is a real area threshold, not "looks straight" — a shallow arc
    // is a legitimate shape and must not be refused.
    expect(
      sketchEntityDegeneracy({
        eid: ent("G"),
        kind: "arc-three-point",
        p1: [0, 0],
        p2: [5, 0.01],
        p3: [10, 0],
        construction: false,
      }),
    ).toBeUndefined();
  });

  it("checks a CLOSED polyline's implicit closing segment", () => {
    // The repeated pair is first-to-last, which only exists because it closes.
    const issue = sketchEntityDegeneracy({
      eid: ent("C"),
      kind: "polyline",
      points: [
        [0, 0],
        [5, 0],
        [0, 0],
      ],
      closed: true,
      construction: false,
    });
    expect(issue?.code).toBe("E_SKETCH_ZERO_ENTITY");
  });

  it("refuses a two-point CLOSED polyline — a line drawn twice", () => {
    const issue = sketchEntityDegeneracy({
      eid: ent("C"),
      kind: "polyline",
      points: [
        [0, 0],
        [5, 0],
      ],
      closed: true,
      construction: false,
    });
    expect(issue?.code).toBe("E_SKETCH_ZERO_ENTITY");
    expect(issue?.message).toContain("at least three points");
  });
});

describe("the reference ladder — E_SKETCH_UNKNOWN_ANCHOR", () => {
  it("refuses a constraint naming a shape that is not in the sketch", () => {
    // The sketch form of the dropped-reference class this project refuses
    // everywhere: the solver would ignore it or crash, both worse than saying.
    const parsed = sketchOperationSchema.parse(
      sketch({
        entities: [line("A", [0, 0], [10, 0])],
        constraints: [
          {
            cid: cst("1"),
            kind: "distance",
            a: { eid: ent("A"), at: "start" },
            b: { eid: ent("Z"), at: "end" },
            value: 10,
          },
        ],
      } as never),
    );
    const issues = validateSketch(parsed);
    expect(issues.map((issue) => issue.code)).toEqual([
      "E_SKETCH_UNKNOWN_ANCHOR",
    ]);
    expect(issues[0]?.id).toBe(cst("1"));
  });

  it("refuses grounding a shape that is not in the sketch", () => {
    const missing = ent("Z");
    const parsed = sketchOperationSchema.parse(
      sketch({
        entities: [line("A", [0, 0], [10, 0])],
        grounded: [missing],
      }),
    );

    expect(validateSketch(parsed)).toEqual([
      {
        code: "E_SKETCH_UNKNOWN_ANCHOR",
        id: missing,
        message: "This grounded shape is no longer in the sketch.",
      },
    ]);
  });

  it("passes a constraint whose anchors all exist", () => {
    const parsed = sketchOperationSchema.parse(
      sketch({
        entities: [line("A", [0, 0], [10, 0]), line("B", [10, 0], [10, 10])],
        constraints: [
          {
            cid: cst("1"),
            kind: "coincident",
            a: { eid: ent("A"), at: "end" },
            b: { eid: ent("B"), at: "start" },
          },
          { cid: cst("2"), kind: "horizontal", eid: ent("A") },
        ],
      } as never),
    );
    expect(validateSketch(parsed)).toEqual([]);
  });
});

describe("direction relations name entities, not anchors", () => {
  const relation = (kind: "parallel" | "perpendicular", b: string) => ({
    cid: cst("1"),
    kind,
    a: ent("A"),
    b,
  });

  it.each(["parallel", "perpendicular"] as const)("parses a %s", (kind) => {
    const parsed = sketchOperationSchema.parse(
      sketch({
        entities: [line("A", [0, 0], [10, 0]), line("B", [0, 5], [8, 11])],
        constraints: [relation(kind, ent("B"))],
      } as never),
    );
    expect(parsed.parameters.constraints[0]).toEqual({
      cid: cst("1"),
      kind,
      a: ent("A"),
      b: ent("B"),
    });
    expect(validateSketch(parsed)).toEqual([]);
  });

  it("carries a relation to a missing line up the reference ladder", () => {
    // The `default:` branch of the anchor check reads `constraint.eid`, which
    // these records do not have — so a relation that was not handled by name
    // would silently pass validation instead of being refused.
    const parsed = sketchOperationSchema.parse(
      sketch({
        entities: [line("A", [0, 0], [10, 0])],
        constraints: [relation("parallel", ent("Z"))],
      } as never),
    );
    const issues = validateSketch(parsed);
    expect(issues.map((issue) => issue.code)).toEqual([
      "E_SKETCH_UNKNOWN_ANCHOR",
    ]);
    expect(issues[0]?.id).toBe(cst("1"));
  });

  it("refuses an anchor record where an entity id belongs", () => {
    expect(() =>
      sketchOperationSchema.parse(
        sketch({
          entities: [line("A", [0, 0], [10, 0]), line("B", [0, 5], [8, 11])],
          constraints: [
            {
              cid: cst("1"),
              kind: "parallel",
              a: { eid: ent("A"), at: "start" },
              b: { eid: ent("B"), at: "start" },
            },
          ],
        } as never),
      ),
    ).toThrow();
  });
});

describe("the id-integrity ladder — E_DOC_DUPLICATE_ID", () => {
  it("refuses two entities sharing an id", () => {
    const parsed = sketchOperationSchema.parse(
      sketch({
        entities: [line("A", [0, 0], [10, 0]), line("A", [0, 5], [10, 5])],
      } as never),
    );
    expect(validateSketch(parsed).map((issue) => issue.code)).toEqual([
      "E_DOC_DUPLICATE_ID",
    ]);
  });

  it("refuses grounding the same entity more than once", () => {
    const duplicate = ent("A");
    const parsed = sketchOperationSchema.parse(
      sketch({
        entities: [line("A", [0, 0], [10, 0])],
        grounded: [duplicate, duplicate],
      }),
    );

    expect(validateSketch(parsed)).toEqual([
      {
        code: "E_DOC_DUPLICATE_ID",
        id: duplicate,
        message: "The same shape is grounded more than once.",
      },
    ]);
  });
});

describe("snapHints are normatively INERT", () => {
  const withHint = () =>
    sketchOperationSchema.parse(
      sketch({
        entities: [
          {
            ...line("A", [0, 0], [10, 0]),
            snapHints: [{ kind: "horizontal", targets: [ent("B")] }],
          },
        ],
      } as never),
    );

  it("parse and keep them — they are how re-opening re-derives snapping", () => {
    const entity = withHint().parameters.entities[0];
    expect(entity && "snapHints" in entity && entity.snapHints).toHaveLength(1);
  });

  it("are DROPPED before hashing, so editing one recomputes nothing", () => {
    // Plan 02 §10.1's exclusion list, asserted rather than left as prose.
    const hashed = sketchParametersForHashing(withHint());
    expect("snapHints" in (hashed.entities[0] ?? {})).toBe(false);
    // And a sketch WITHOUT hints hashes to the same parameters as one with.
    const plain = sketchOperationSchema.parse(
      sketch({ entities: [line("A", [0, 0], [10, 0])] } as never),
    );
    expect(hashed).toEqual(sketchParametersForHashing(plain));
  });

  it("tolerate a dangling target rather than failing the document", () => {
    // A hint that has gone stale must never fail a document that is valid.
    const parsed = sketchOperationSchema.safeParse(
      sketch({
        entities: [
          {
            ...line("A", [0, 0], [10, 0]),
            snapHints: [{ kind: "coincident", targets: ["ent_gone"] }],
          },
        ],
      } as never),
    );
    expect(parsed.success).toBe(true);
    if (!parsed.success) return;
    expect(validateSketch(parsed.data)).toEqual([]);
  });
});

describe("the stored solution (ADR-016 determinism)", () => {
  it("is absent until the solver has accepted one", () => {
    expect(
      sketchOperationSchema.parse(sketch()).parameters.solution,
    ).toBeUndefined();
  });

  it("round-trips the accepted coordinates BYTE-IDENTICALLY", () => {
    // Replay re-solves and asserts agreement against exactly these numbers, so
    // a lossy round trip here would make the determinism contract unenforceable.
    const document = sketch({
      entities: [line("A", [0, 0], [10, 0])],
      solution: {
        entities: [{ eid: ent("A"), values: [0, 0, 9.999999999999998, 1e-17] }],
        degreesOfFreedom: 0,
      },
    } as never);
    const once = sketchOperationSchema.parse(document);
    const twice = sketchOperationSchema.parse(JSON.parse(JSON.stringify(once)));
    expect(JSON.stringify(twice)).toBe(JSON.stringify(once));
    expect(twice.parameters.solution?.entities[0]?.values[2]).toBe(
      9.999999999999998,
    );
  });

  it("records ZERO degrees of freedom as the fully-constrained state", () => {
    const parsed = sketchOperationSchema.parse(
      sketch({
        solution: { entities: [], degreesOfFreedom: 0 },
      } as never),
    );
    expect(parsed.parameters.solution?.degreesOfFreedom).toBe(0);
    // Negative is not a state a solver can be in.
    expect(
      sketchOperationSchema.safeParse(
        sketch({ solution: { entities: [], degreesOfFreedom: -1 } } as never),
      ).success,
    ).toBe(false);
  });
});

describe("the kind is IN the operation union (review fix 1)", () => {
  // A schema outside the union is not an operation kind: a document carrying
  // one would not parse, so proving the standalone schema round-trips proved
  // nothing about a sketch-bearing DOCUMENT.
  it("parses through operationSchema, not just its own schema", () => {
    const parsed = operationSchema.safeParse(
      sketch({ entities: [line("A", [0, 0], [10, 0])] } as never),
    );
    expect(parsed.success).toBe(true);
    if (!parsed.success) return;
    expect(parsed.data.type).toBe("sketch");
  });

  it("is a KNOWN type, so it never degrades to the Gate-9 unknown shape", () => {
    expect(knownOperationTypes.has("sketch")).toBe(true);
  });

  it("round-trips through the union byte-identically", () => {
    const once = operationSchema.parse(
      sketch({
        entities: [line("A", [0, 0], [10, 0])],
        solution: {
          entities: [{ eid: ent("A"), values: [0, 0, 9.999999999999998] }],
          degreesOfFreedom: 2,
        },
      } as never),
    );
    const twice = operationSchema.parse(JSON.parse(JSON.stringify(once)));
    expect(JSON.stringify(twice)).toBe(JSON.stringify(once));
  });

  it("stays staged for WIRE BUDGET now that it executes — the offset pattern", () => {
    // REWRITTEN at CAP-037, not deleted (PROTOCOL §5). The old reason — "no
    // kernel executor exists yet" — is now FALSE: geometry.cpp has a sketch arm
    // and server.cpp re-solves every stored solution before any geometry runs.
    //
    // It stays staged anyway, and the reason changed rather than expired.
    // `stagedOperationTypes` is consumed by exactly one thing: the agent wire
    // toolset (modelExcludedOperationTypes derives from it). Nothing in
    // document-model or the desktop app gates AUTHORING on it, so a person can
    // draw a sketch while the model cannot call one. Un-staging would only
    // publish the tool to the model, and that costs wire-schema tokens against a
    // pin set at the measured minimum — a separate ruling, exactly as `offset`
    // is staged for budget while executing for real.
    expect(stagedOperationTypes.has("sketch")).toBe(true);
  });
});

describe("the op-hash honours the snapHints exclusion (review fix 2)", () => {
  /**
   * The hasher consumes the WIRE ref form and fails closed on the persisted
   * `{query}` shape (N6 A′), so the plane slot is swapped for its ast before
   * hashing — exactly what the executor hands it.
   */
  const canonical = (operation: unknown): string => {
    const parsed = operation as { parameters: Record<string, unknown> };
    return new TextDecoder().decode(
      canonicalOperationBytes({
        ...parsed,
        parameters: {
          ...parsed.parameters,
          plane: {
            ast: {
              kind: "faces",
              scope: [{ source: "op", opId: OP_ID }],
              filters: [
                { name: "role", args: [{ arg: "ident", value: "top" }] },
              ],
            },
            arity: "one",
            onEmpty: "error",
          },
        },
      }),
    );
  };

  const withHints = operationSchema.parse(
    sketch({
      entities: [
        {
          ...line("A", [0, 0], [10, 0]),
          snapHints: [{ kind: "horizontal", targets: [ent("B")] }],
        },
      ],
    } as never),
  );
  const withoutHints = operationSchema.parse(
    sketch({ entities: [line("A", [0, 0], [10, 0])] } as never),
  );

  it("is snapHints-INVARIANT — editing a hint recomputes nothing", () => {
    expect(canonical(withHints)).toBe(canonical(withoutHints));
  });

  it("is still SOLUTION-sensitive — the solved answer is load-bearing", () => {
    // The exclusion must not leak into the rest of the sketch: the solution is
    // exactly what replay re-derives and asserts against.
    const solved = operationSchema.parse(
      sketch({
        entities: [line("A", [0, 0], [10, 0])],
        solution: {
          entities: [{ eid: ent("A"), values: [0, 0, 10, 0] }],
          degreesOfFreedom: 0,
        },
      } as never),
    );
    expect(canonical(solved)).not.toBe(canonical(withoutHints));
  });

  it("is ENTITY-sensitive — moving a point changes the hash", () => {
    const moved = operationSchema.parse(
      sketch({ entities: [line("A", [0, 0], [10, 5])] } as never),
    );
    expect(canonical(moved)).not.toBe(canonical(withoutHints));
  });
});

describe("create_profile is untouched", () => {
  it("still parses exactly as before, beside the new kind", () => {
    // The entity sketch is a NEW operation kind, never a migration — every
    // document authored by CAP-015 must keep working unchanged.
    const profile = createProfileOperationSchema.parse({
      id: OP_ID,
      type: "create_profile",
      schemaVersion: 1,
      name: "Sketch 1",
      outputProfileId: "22222222-2222-4222-8222-222222222222",
      parameters: {
        shape: { kind: "rectangle", width: 40, depth: 30 },
        placement: {
          origin: [0, 0, 0],
          zDirection: [0, 0, 1],
          xDirection: [1, 0, 0],
        },
      },
      metadata: {
        createdAt: "2026-07-27T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    });
    expect(profile.type).toBe("create_profile");
    expect(profile.parameters.shape.kind).toBe("rectangle");
  });
});

/* --- CAP-038: the closed region ----------------------------------------- */

const arc = (
  id: string,
  center: [number, number],
  radius: number,
  startAngle: number,
  endAngle: number,
) =>
  ({
    eid: ent(id),
    kind: "arc-center",
    center,
    radius,
    startAngle,
    endAngle,
    ccw: true,
    construction: false,
  }) as SketchEntity;

/** The four sides of a 40 x 30 rectangle, authored end-to-start in order. */
const SQUARE: SketchEntity[] = [
  line("A", [0, 0], [40, 0]),
  line("B", [40, 0], [40, 30]),
  line("C", [40, 30], [0, 30]),
  line("D", [0, 30], [0, 0]),
];

function requiredEntity(
  values: readonly SketchEntity[],
  index: number,
): SketchEntity {
  const value = values[index];
  if (value === undefined)
    throw new Error(`Missing test entity at ${String(index)}`);
  return value;
}

function regionOf(overrides: Partial<SketchOperation["parameters"]>) {
  return sketchClosedRegion(sketchOperationSchema.parse(sketch(overrides)));
}

describe("the closed region", () => {
  it("walks a four-line contour in authoring order", () => {
    const region = regionOf({ entities: SQUARE });
    expect(region.ok).toBe(true);
    if (!region.ok) return;
    expect(region.segments.map((segment) => segment.eid)).toEqual(
      SQUARE.map((entity) => entity.eid),
    );
    // Endpoints, not counts: a walk that returned the right NUMBER of
    // segments in the wrong order would pass a count assertion.
    expect(region.segments[0]).toMatchObject({
      kind: "line",
      start: [0, 0],
      end: [40, 0],
    });
  });

  it("REFUSES an open contour, naming both ends and the gap", () => {
    const open = [...SQUARE.slice(0, 3), line("D", [0, 30], [0, 2])];
    const region = regionOf({ entities: open });
    expect(region.ok).toBe(false);
    if (region.ok) return;
    // The refusal has to be actionable: which two entities, and how far apart.
    expect(region.message).toContain(ent("D"));
    expect(region.message).toContain(ent("A"));
    expect(region.message).toContain("2.000 mm");
  });

  it("never stitches a gap shut by tolerance", () => {
    // 1e-6 is the degeneracy floor; at exactly the floor the gap is real.
    const almost = [...SQUARE.slice(0, 3), line("D", [0, 30], [0, 1e-6])];
    expect(regionOf({ entities: almost }).ok).toBe(false);
    // A hair under it is nothing at all, by the same rule the schema uses.
    const closed = [...SQUARE.slice(0, 3), line("D", [0, 30], [0, 9e-7])];
    expect(regionOf({ entities: closed }).ok).toBe(true);
  });

  it("accepts the criterion's mixed line/arc contour", () => {
    // A rounded corner: the arc's own endpoints have to be derived from its
    // centre, radius and angles, and a walk that compared centres instead
    // would read this contour as open.
    const contour: SketchEntity[] = [
      line("A", [0, 0], [10, 0]),
      arc("B", [10, 10], 10, -90, 0),
      line("C", [20, 10], [0, 10]),
      line("D", [0, 10], [0, 0]),
    ];
    const region = regionOf({ entities: contour });
    expect(region.ok).toBe(true);
    if (!region.ok) return;
    expect(region.segments[1]).toMatchObject({ kind: "arc", radius: 10 });
  });

  it("takes the SOLVED coordinates, so a solved contour closes", () => {
    // The placed coordinates leave a 5 mm gap; the solution closes it. The
    // region a person sees is the solved one, and so is the one that extrudes.
    const placed = [...SQUARE.slice(0, 3), line("D", [0, 30], [0, 5])];
    expect(regionOf({ entities: placed }).ok).toBe(false);
    const region = regionOf({
      entities: placed,
      solution: {
        entities: [{ eid: ent("D"), values: [0, 30, 0, 0] }],
        degreesOfFreedom: 0,
      },
    });
    expect(region.ok).toBe(true);
    if (!region.ok) return;
    expect(region.segments[3]).toMatchObject({ end: [0, 0] });
  });

  it("IGNORES a solution vector of the wrong length", () => {
    // Half-applying a solution would draw a shape that is neither what was
    // placed nor what was solved.
    const region = regionOf({
      entities: SQUARE,
      solution: {
        entities: [{ eid: ent("A"), values: [1, 2] }],
        degreesOfFreedom: 1,
      },
    });
    expect(region.ok).toBe(true);
    if (!region.ok) return;
    expect(region.segments[0]).toMatchObject({ start: [0, 0], end: [40, 0] });
  });

  it("accepts a single circle — it is a closed loop on its own", () => {
    const circle = {
      eid: ent("K"),
      kind: "circle",
      center: [5, 5],
      radius: 12,
      construction: false,
    } as SketchEntity;
    const region = regionOf({ entities: [circle] });
    expect(region.ok).toBe(true);
    if (!region.ok) return;
    expect(region.segments).toHaveLength(1);
    expect(region.segments[0]).toMatchObject({ kind: "circle", radius: 12 });
  });

  it("arranges a circle beside a contour as a second independent region", () => {
    const circle = {
      eid: ent("K"),
      kind: "circle",
      center: [5, 5],
      radius: 12,
      construction: false,
    } as SketchEntity;
    const region = regionOf({ entities: [...SQUARE, circle] });
    expect(region.ok).toBe(true);
    if (!region.ok) return;
    expect(region.loops).toHaveLength(2);
    expect(
      region.loops.some((loop) =>
        loop.segments.some((segment) => segment.kind === "circle"),
      ),
    ).toBe(true);
  });

  it("arranges independently authored nested loops as a material region and a hole", () => {
    const inner: SketchEntity[] = [
      line("E", [10, 10], [30, 10]),
      line("F", [30, 10], [30, 20]),
      line("G", [30, 20], [10, 20]),
      line("H", [10, 20], [10, 10]),
    ];
    // Deliberately interleave and reverse the authored order. The arrangement
    // is driven by endpoint identity, not by the order the records arrived in.
    const region = regionOf({
      entities: [
        requiredEntity(inner, 2),
        requiredEntity(SQUARE, 1),
        requiredEntity(inner, 0),
        requiredEntity(SQUARE, 3),
        requiredEntity(SQUARE, 0),
        requiredEntity(inner, 3),
        requiredEntity(SQUARE, 2),
        requiredEntity(inner, 1),
      ],
    });
    expect(region.ok).toBe(true);
    if (!region.ok) return;
    expect(region.loops).toHaveLength(2);
    expect(region.loops.filter((loop) => loop.isHole)).toHaveLength(1);
    expect(region.loops.find((loop) => loop.isHole)?.depth).toBe(1);
  });

  it("refuses a single line, and a sketch of only construction guides", () => {
    expect(regionOf({ entities: [line("A", [0, 0], [10, 0])] }).ok).toBe(false);
    const guide = { ...line("A", [0, 0], [10, 0]), construction: true };
    const region = regionOf({ entities: [guide as SketchEntity] });
    expect(region.ok).toBe(false);
    if (region.ok) return;
    expect(region.message).toContain("construction guides");
  });

  it("EXCLUDES construction geometry from the boundary walk", () => {
    // A centreline through the middle of a closed square must not break it.
    const guide = {
      ...line("G", [0, 15], [40, 15]),
      construction: true,
    } as SketchEntity;
    expect(regionOf({ entities: [...SQUARE, guide] }).ok).toBe(true);
  });

  it("measures the region's bounding half-extent", () => {
    const region = regionOf({ entities: SQUARE });
    expect(region.ok).toBe(true);
    if (!region.ok) return;
    expect(sketchRegionExtent(region.segments)).toEqual({
      halfU: 20,
      halfV: 15,
      center: [20, 15],
    });
  });

  it("bounds an arc by its whole circle, the safe direction for an axis", () => {
    // A quarter arc's swept span is smaller than its circle; a revolve axis
    // placed at the tangent of the SWEPT extent could cross the region.
    const contour: SketchEntity[] = [
      line("A", [0, 0], [10, 0]),
      arc("B", [10, 10], 10, -90, 0),
      line("C", [20, 10], [0, 10]),
      line("D", [0, 10], [0, 0]),
    ];
    const region = regionOf({ entities: contour });
    expect(region.ok).toBe(true);
    if (!region.ok) return;
    expect(sketchRegionExtent(region.segments).halfU).toBeCloseTo(10, 9);
  });
});
