import { describe, expect, it } from "vitest";

import {
  datumAxisOperationSchema,
  datumPlaneOperationSchema,
  knownOperationTypes,
  maxPatternInstances,
  mirrorOperationSchema,
  modelExcludedOperationTypes,
  nonAuthorableOperationTypes,
  operationSchema,
  patternCircularOperationSchema,
  patternLinearOperationSchema,
  shellOperationSchema,
  stagedOperationTypes,
} from "../src/index.js";

/**
 * Catalog completion wave 1 — schema contracts for datum_plane / datum_axis /
 * shell / mirror / pattern_linear / pattern_circular
 * (docs/design/2026-07-19-catalog-ts-contracts.md §2). Every schema branch is
 * pinned here; document-model acceptance/dependency behavior and the
 * fail-closed kernel refusal are pinned in their own packages.
 */

const uuid = (n: number): string =>
  `018f0f5d-0000-7000-8000-${n.toString(16).padStart(12, "0")}`;

const metadata = {
  createdAt: "2026-07-19T09:00:00.000Z",
  createdBy: { kind: "user" },
} as const;

const baseFaceRef = { query: `faces(op(${uuid(1)})).planar()` } as const;
const axisEdgeRef = { query: "edges(world(z))" } as const;

const validDatumPlaneOffset = {
  id: uuid(10),
  type: "datum_plane",
  schemaVersion: 1,
  name: "Lid plane (+5 mm)",
  parameters: { mode: "offset", offset: 5, base: baseFaceRef },
  metadata,
} as const;

const validDatumPlaneAngled = {
  id: uuid(11),
  type: "datum_plane",
  schemaVersion: 1,
  name: "Tilted lid plane",
  parameters: {
    mode: "angled",
    angle: -30,
    base: baseFaceRef,
    axis: axisEdgeRef,
  },
  metadata,
} as const;

const validDatumPlaneMidplane = {
  id: uuid(12),
  type: "datum_plane",
  schemaVersion: 1,
  name: "Between the walls",
  parameters: {
    mode: "midplane",
    a: { query: `faces(op(${uuid(1)})).role(left)` },
    b: { query: `faces(op(${uuid(1)})).role(right)` },
  },
  metadata,
} as const;

const validDatumAxisTwoPoints = {
  id: uuid(13),
  type: "datum_axis",
  schemaVersion: 1,
  name: "Corner-to-corner axis",
  parameters: {
    mode: "twoPoints",
    a: { query: `vertices(op(${uuid(1)}))` },
    b: { query: `vertices(op(${uuid(2)}))` },
  },
  metadata,
} as const;

const validDatumAxisFaceNormal = {
  id: uuid(14),
  type: "datum_axis",
  schemaVersion: 1,
  name: "Straight up through the pad",
  parameters: {
    mode: "faceNormal",
    position: [10, -5, 0],
    face: baseFaceRef,
  },
  metadata,
} as const;

const validDatumAxisCylinderAxis = {
  id: uuid(15),
  type: "datum_axis",
  schemaVersion: 1,
  name: "Post axis",
  parameters: { mode: "cylinderAxis", face: baseFaceRef },
  metadata,
} as const;

const validShell = {
  id: uuid(16),
  type: "shell",
  schemaVersion: 1,
  name: "Hollow to 1.6 mm, open top",
  outputBodyId: uuid(116),
  parameters: {
    targetOperationId: uuid(1),
    thickness: 1.6,
    direction: "inward",
    openFaces: {
      query: `faces(op(${uuid(1)})).normal(+z)`,
      arity: "any",
      onEmpty: "empty-ok",
    },
  },
  metadata,
} as const;

const validMirror = {
  id: uuid(17),
  type: "mirror",
  schemaVersion: 1,
  name: "Mirror to full bracket",
  outputBodyId: uuid(117),
  parameters: {
    sourceOperationId: uuid(1),
    plane: { query: "faces(world(yz))" },
    merge: true,
  },
  metadata,
} as const;

const validPatternLinear = {
  id: uuid(18),
  type: "pattern_linear",
  schemaVersion: 1,
  name: "4x2 ventilation holes",
  outputBodyId: uuid(118),
  parameters: {
    seedOperationId: uuid(2),
    count: 4,
    spacing: 12,
    direction: [1, 0, 0],
    count2: 2,
    spacing2: 15,
    direction2: [0, 1, 0],
    op: "subtract",
    targetOperationId: uuid(1),
    consumeSeed: true,
  },
  metadata,
} as const;

const validPatternCircular = {
  id: uuid(19),
  type: "pattern_circular",
  schemaVersion: 1,
  name: "6 bolt holes",
  outputBodyId: uuid(119),
  parameters: {
    seedOperationId: uuid(2),
    axis: axisEdgeRef,
    count: 6,
    totalAngle: 360,
    rotateInstances: true,
    op: "subtract",
    targetOperationId: uuid(1),
    consumeSeed: true,
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

describe("datumPlaneOperationSchema", () => {
  it.each([
    ["offset", validDatumPlaneOffset],
    ["angled", validDatumPlaneAngled],
    ["midplane", validDatumPlaneMidplane],
  ] as const)(
    "accepts a fully specified %s datum plane",
    (_mode, operation) => {
      const parsed = datumPlaneOperationSchema.parse(operation);
      expect(parsed.parameters.mode).toBe(operation.parameters.mode);
    },
  );

  it("applies the ref envelope defaults to the base slot", () => {
    const parsed = datumPlaneOperationSchema.parse(validDatumPlaneOffset);
    if (parsed.parameters.mode !== "offset") throw new Error("wrong mode");
    expect(parsed.parameters.base.arity).toBe("one");
    expect(parsed.parameters.base.onEmpty).toBe("error");
    expect(parsed.parameters.base.anchors).toEqual([]);
  });

  it("mints no body: an outputBodyId is rejected", () => {
    expect(() =>
      datumPlaneOperationSchema.parse({
        ...validDatumPlaneOffset,
        outputBodyId: uuid(200),
      }),
    ).toThrow();
    expect(() =>
      datumPlaneOperationSchema.parse({
        ...validDatumPlaneOffset,
        outputProfileId: uuid(200),
      }),
    ).toThrow();
  });

  it("accepts the signed offset bounds exactly and rejects past them", () => {
    for (const offset of [10_000_000, -10_000_000, 0]) {
      const parsed = datumPlaneOperationSchema.parse(
        withParameters(validDatumPlaneOffset, { offset }),
      );
      if (parsed.parameters.mode !== "offset") throw new Error("wrong mode");
      expect(parsed.parameters.offset).toBe(offset);
    }
    for (const offset of [
      10_000_001,
      -10_000_001,
      Number.NaN,
      Number.POSITIVE_INFINITY,
      "5",
    ]) {
      expect(() =>
        datumPlaneOperationSchema.parse(
          withParameters(validDatumPlaneOffset, { offset }),
        ),
      ).toThrow();
    }
  });

  it("bounds the angled rotation to one full turn either way", () => {
    for (const angle of [360, -360, 0.25]) {
      expect(
        datumPlaneOperationSchema.safeParse(
          withParameters(validDatumPlaneAngled, { angle }),
        ).success,
      ).toBe(true);
    }
    for (const angle of [360.5, -361, Number.NaN]) {
      expect(
        datumPlaneOperationSchema.safeParse(
          withParameters(validDatumPlaneAngled, { angle }),
        ).success,
      ).toBe(false);
    }
  });

  it("refuses params/refs not applicable to the chosen mode", () => {
    // offset mode must not carry the angled/midplane slots.
    expect(() =>
      datumPlaneOperationSchema.parse(
        withParameters(validDatumPlaneOffset, { axis: axisEdgeRef }),
      ),
    ).toThrow();
    expect(() =>
      datumPlaneOperationSchema.parse(
        withParameters(validDatumPlaneOffset, { angle: 15 }),
      ),
    ).toThrow();
    // midplane must not carry a base plane or an offset.
    expect(() =>
      datumPlaneOperationSchema.parse(
        withParameters(validDatumPlaneMidplane, { base: baseFaceRef }),
      ),
    ).toThrow();
    expect(() =>
      datumPlaneOperationSchema.parse(
        withParameters(validDatumPlaneMidplane, { offset: 5 }),
      ),
    ).toThrow();
  });

  it("refuses a mode with its required slots missing", () => {
    expect(() =>
      datumPlaneOperationSchema.parse(
        withoutParameterKeys(validDatumPlaneOffset, ["base"]),
      ),
    ).toThrow();
    expect(() =>
      datumPlaneOperationSchema.parse(
        withoutParameterKeys(validDatumPlaneAngled, ["axis"]),
      ),
    ).toThrow();
    expect(() =>
      datumPlaneOperationSchema.parse(
        withoutParameterKeys(validDatumPlaneMidplane, ["b"]),
      ),
    ).toThrow();
  });

  it("rejects unknown modes and malformed ref envelopes", () => {
    expect(() =>
      datumPlaneOperationSchema.parse(
        withParameters(validDatumPlaneOffset, { mode: "tangent" }),
      ),
    ).toThrow();
    expect(() =>
      datumPlaneOperationSchema.parse(
        withParameters(validDatumPlaneOffset, { base: { query: "" } }),
      ),
    ).toThrow();
    expect(() =>
      datumPlaneOperationSchema.parse(
        withParameters(validDatumPlaneOffset, {
          base: { query: "faces(op(op_a))", ast: {} },
        }),
      ),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      datumPlaneOperationSchema.parse({
        ...validDatumPlaneOffset,
        legacyId: "not-allowed",
      }),
    ).toThrow();
  });
});

describe("datumAxisOperationSchema", () => {
  it.each([
    ["twoPoints", validDatumAxisTwoPoints],
    ["faceNormal", validDatumAxisFaceNormal],
    ["cylinderAxis", validDatumAxisCylinderAxis],
  ] as const)("accepts a fully specified %s datum axis", (_mode, operation) => {
    const parsed = datumAxisOperationSchema.parse(operation);
    expect(parsed.parameters.mode).toBe(operation.parameters.mode);
  });

  it("mints no body: an outputBodyId is rejected", () => {
    expect(() =>
      datumAxisOperationSchema.parse({
        ...validDatumAxisCylinderAxis,
        outputBodyId: uuid(200),
      }),
    ).toThrow();
  });

  it("requires position exactly for faceNormal", () => {
    expect(() =>
      datumAxisOperationSchema.parse(
        withoutParameterKeys(validDatumAxisFaceNormal, ["position"]),
      ),
    ).toThrow();
    expect(() =>
      datumAxisOperationSchema.parse(
        withParameters(validDatumAxisCylinderAxis, { position: [0, 0, 0] }),
      ),
    ).toThrow();
    expect(() =>
      datumAxisOperationSchema.parse(
        withParameters(validDatumAxisTwoPoints, { position: [0, 0, 0] }),
      ),
    ).toThrow();
  });

  it("bounds the faceNormal position to the modeling extent", () => {
    expect(
      datumAxisOperationSchema.safeParse(
        withParameters(validDatumAxisFaceNormal, {
          position: [10_000_000, 0, 0],
        }),
      ).success,
    ).toBe(true);
    expect(
      datumAxisOperationSchema.safeParse(
        withParameters(validDatumAxisFaceNormal, {
          position: [10_000_001, 0, 0],
        }),
      ).success,
    ).toBe(false);
    expect(
      datumAxisOperationSchema.safeParse(
        withParameters(validDatumAxisFaceNormal, {
          position: [0, Number.NaN, 0],
        }),
      ).success,
    ).toBe(false);
  });

  it("requires both endpoints for twoPoints and only the face otherwise", () => {
    expect(() =>
      datumAxisOperationSchema.parse(
        withoutParameterKeys(validDatumAxisTwoPoints, ["b"]),
      ),
    ).toThrow();
    expect(() =>
      datumAxisOperationSchema.parse(
        withParameters(validDatumAxisTwoPoints, { face: baseFaceRef }),
      ),
    ).toThrow();
    expect(() =>
      datumAxisOperationSchema.parse(
        withoutParameterKeys(validDatumAxisCylinderAxis, ["face"]),
      ),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      datumAxisOperationSchema.parse({
        ...validDatumAxisTwoPoints,
        legacyId: "not-allowed",
      }),
    ).toThrow();
  });
});

const invalidLengths = [
  0,
  -1,
  Number.NaN,
  Number.POSITIVE_INFINITY,
  1_000_001,
] as const;

describe("shellOperationSchema", () => {
  it("accepts a fully specified shell with an openFaces ref", () => {
    const parsed = shellOperationSchema.parse(validShell);
    expect(parsed.parameters.openFaces?.arity).toBe("any");
    expect(parsed.parameters.openFaces?.onEmpty).toBe("empty-ok");
  });

  it("defaults direction to inward and allows a closed hollow shell (no openFaces)", () => {
    const parsed = shellOperationSchema.parse(
      withoutParameterKeys(validShell, ["direction", "openFaces"]),
    );
    expect(parsed.parameters.direction).toBe("inward");
    expect(parsed.parameters.openFaces).toBeUndefined();
  });

  it("accepts the outward direction and rejects unknown directions", () => {
    expect(
      shellOperationSchema.safeParse(
        withParameters(validShell, { direction: "outward" }),
      ).success,
    ).toBe(true);
    expect(
      shellOperationSchema.safeParse(
        withParameters(validShell, { direction: "sideways" }),
      ).success,
    ).toBe(false);
  });

  it.each(invalidLengths)("rejects invalid thickness %s", (thickness) => {
    expect(() =>
      shellOperationSchema.parse(withParameters(validShell, { thickness })),
    ).toThrow();
  });

  it("rejects a non-uuid targetOperationId and a missing output body id", () => {
    expect(() =>
      shellOperationSchema.parse(
        withParameters(validShell, { targetOperationId: "not-a-uuid" }),
      ),
    ).toThrow();
    const withoutOutput = Object.fromEntries(
      Object.entries(validShell).filter(([key]) => key !== "outputBodyId"),
    );
    expect(() => shellOperationSchema.parse(withoutOutput)).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      shellOperationSchema.parse({ ...validShell, legacyId: "not-allowed" }),
    ).toThrow();
    expect(() =>
      shellOperationSchema.parse(
        withParameters(validShell, { simplify: true }),
      ),
    ).toThrow();
  });
});

describe("mirrorOperationSchema", () => {
  it("accepts a merge mirror across a world plane", () => {
    const parsed = mirrorOperationSchema.parse(validMirror);
    expect(parsed.parameters.merge).toBe(true);
    expect(parsed.parameters.plane.query).toBe("faces(world(yz))");
    // Ref envelope defaults are applied to the plane slot.
    expect(parsed.parameters.plane.arity).toBe("one");
    expect(parsed.parameters.plane.onEmpty).toBe("error");
    expect(parsed.parameters.plane.anchors).toEqual([]);
  });

  it("defaults merge to false (independent mirrored body)", () => {
    const parsed = mirrorOperationSchema.parse(
      withoutParameterKeys(validMirror, ["merge"]),
    );
    expect(parsed.parameters.merge).toBe(false);
  });

  it("requires the plane ref and a body-producing envelope", () => {
    expect(() =>
      mirrorOperationSchema.parse(withoutParameterKeys(validMirror, ["plane"])),
    ).toThrow();
    const withoutOutput = Object.fromEntries(
      Object.entries(validMirror).filter(([key]) => key !== "outputBodyId"),
    );
    expect(() => mirrorOperationSchema.parse(withoutOutput)).toThrow();
  });

  it("rejects a non-uuid sourceOperationId and unknown fields", () => {
    expect(() =>
      mirrorOperationSchema.parse(
        withParameters(validMirror, { sourceOperationId: "not-a-uuid" }),
      ),
    ).toThrow();
    expect(() =>
      mirrorOperationSchema.parse({ ...validMirror, legacyId: "no" }),
    ).toThrow();
  });
});

describe("patternLinearOperationSchema", () => {
  it("accepts a fully specified 2D subtract pattern", () => {
    expect(patternLinearOperationSchema.parse(validPatternLinear)).toEqual(
      validPatternLinear,
    );
  });

  it("defaults count2/op/consumeSeed for a minimal 1D fuse pattern", () => {
    const parsed = patternLinearOperationSchema.parse({
      ...validPatternLinear,
      parameters: {
        seedOperationId: uuid(2),
        count: 4,
        spacing: 12,
        direction: [1, 0, 0],
      },
    });
    expect(parsed.parameters.count2).toBe(1);
    expect(parsed.parameters.op).toBe("fuseInstances");
    expect(parsed.parameters.consumeSeed).toBe(true);
    expect(parsed.parameters.targetOperationId).toBeUndefined();
  });

  it("accepts count 1 (a single-copy pattern) and negative spacing", () => {
    expect(
      patternLinearOperationSchema.safeParse(
        withParameters(validPatternLinear, { count: 1, spacing: -12 }),
      ).success,
    ).toBe(true);
  });

  it.each([0, -1, 2.5, maxPatternInstances + 1, Number.NaN])(
    "rejects invalid count %s",
    (count) => {
      expect(
        patternLinearOperationSchema.safeParse(
          withParameters(validPatternLinear, { count }),
        ).success,
      ).toBe(false);
    },
  );

  it.each([0, 1e-7, 1_000_001, Number.NaN, Number.POSITIVE_INFINITY])(
    "rejects invalid spacing %s",
    (spacing) => {
      expect(
        patternLinearOperationSchema.safeParse(
          withParameters(validPatternLinear, { spacing }),
        ).success,
      ).toBe(false);
    },
  );

  it("caps the instance grid at the pattern budget", () => {
    expect(
      patternLinearOperationSchema.safeParse(
        withParameters(validPatternLinear, { count: 32, count2: 32 }),
      ).success,
    ).toBe(true);
    expect(
      patternLinearOperationSchema.safeParse(
        withParameters(validPatternLinear, { count: 33, count2: 32 }),
      ).success,
    ).toBe(false);
  });

  it("requires spacing2 + direction2 exactly when count2 > 1", () => {
    expect(
      patternLinearOperationSchema.safeParse(
        withoutParameterKeys(validPatternLinear, ["spacing2"]),
      ).success,
    ).toBe(false);
    expect(
      patternLinearOperationSchema.safeParse(
        withoutParameterKeys(validPatternLinear, ["direction2"]),
      ).success,
    ).toBe(false);
    // A 1D pattern must not carry second-direction leftovers.
    expect(
      patternLinearOperationSchema.safeParse(
        withParameters(
          withoutParameterKeys(validPatternLinear, ["direction2"]),
          { count2: 1 },
        ),
      ).success,
    ).toBe(false);
    expect(
      patternLinearOperationSchema.safeParse(
        withParameters(
          withoutParameterKeys(validPatternLinear, ["spacing2", "direction2"]),
          { count2: 1 },
        ),
      ).success,
    ).toBe(true);
  });

  it("rejects a second direction within 1 degree of colinear (both senses)", () => {
    for (const direction2 of [
      [1, 0, 0], // parallel
      [-1, 0, 0], // anti-parallel — same degeneracy, deliberately rejected
      [1, 0.001, 0], // ~0.06 degrees off
    ]) {
      expect(
        patternLinearOperationSchema.safeParse(
          withParameters(validPatternLinear, { direction2 }),
        ).success,
      ).toBe(false);
    }
    // 2 degrees off is comfortably legal.
    expect(
      patternLinearOperationSchema.safeParse(
        withParameters(validPatternLinear, {
          direction2: [Math.cos(Math.PI / 90), Math.sin(Math.PI / 90), 0],
        }),
      ).success,
    ).toBe(true);
  });

  it("requires a target for union/subtract and forbids one for fuseInstances", () => {
    expect(
      patternLinearOperationSchema.safeParse(
        withoutParameterKeys(validPatternLinear, ["targetOperationId"]),
      ).success,
    ).toBe(false);
    expect(
      patternLinearOperationSchema.safeParse(
        withParameters(validPatternLinear, { op: "fuseInstances" }),
      ).success,
    ).toBe(false);
    expect(
      patternLinearOperationSchema.safeParse(
        withParameters(
          withoutParameterKeys(validPatternLinear, ["targetOperationId"]),
          { op: "fuseInstances" },
        ),
      ).success,
    ).toBe(true);
  });

  it("rejects a pattern whose target is its own seed (self-tool)", () => {
    expect(
      patternLinearOperationSchema.safeParse(
        withParameters(validPatternLinear, { targetOperationId: uuid(2) }),
      ).success,
    ).toBe(false);
  });

  it("rejects unknown op kinds and unknown fields", () => {
    expect(
      patternLinearOperationSchema.safeParse(
        withParameters(validPatternLinear, { op: "intersect" }),
      ).success,
    ).toBe(false);
    expect(
      patternLinearOperationSchema.safeParse({
        ...validPatternLinear,
        legacyId: "no",
      }).success,
    ).toBe(false);
  });
});

describe("patternCircularOperationSchema", () => {
  it("accepts a fully specified bolt circle", () => {
    const parsed = patternCircularOperationSchema.parse(validPatternCircular);
    expect(parsed).toEqual({
      ...validPatternCircular,
      parameters: {
        ...validPatternCircular.parameters,
        // Ref envelope defaults are applied to the axis slot.
        axis: { ...axisEdgeRef, arity: "one", anchors: [], onEmpty: "error" },
      },
    });
  });

  it("defaults totalAngle/rotateInstances/op/consumeSeed", () => {
    const parsed = patternCircularOperationSchema.parse({
      ...validPatternCircular,
      parameters: {
        seedOperationId: uuid(2),
        axis: axisEdgeRef,
        count: 6,
      },
    });
    expect(parsed.parameters.totalAngle).toBe(360);
    expect(parsed.parameters.rotateInstances).toBe(true);
    expect(parsed.parameters.op).toBe("fuseInstances");
    expect(parsed.parameters.consumeSeed).toBe(true);
  });

  it.each([1, 0, 2.5, maxPatternInstances + 1])(
    "rejects invalid count %s (a circular pattern needs at least 2)",
    (count) => {
      expect(
        patternCircularOperationSchema.safeParse(
          withParameters(validPatternCircular, { count }),
        ).success,
      ).toBe(false);
    },
  );

  it("bounds totalAngle to (0, 360]", () => {
    for (const totalAngle of [360, 90, 0.5]) {
      expect(
        patternCircularOperationSchema.safeParse(
          withParameters(validPatternCircular, { totalAngle }),
        ).success,
      ).toBe(true);
    }
    for (const totalAngle of [0, -90, 360.5, Number.NaN]) {
      expect(
        patternCircularOperationSchema.safeParse(
          withParameters(validPatternCircular, { totalAngle }),
        ).success,
      ).toBe(false);
    }
  });

  it("requires the axis ref", () => {
    expect(
      patternCircularOperationSchema.safeParse(
        withoutParameterKeys(validPatternCircular, ["axis"]),
      ).success,
    ).toBe(false);
  });

  it("enforces the same target rules as pattern_linear", () => {
    expect(
      patternCircularOperationSchema.safeParse(
        withoutParameterKeys(validPatternCircular, ["targetOperationId"]),
      ).success,
    ).toBe(false);
    expect(
      patternCircularOperationSchema.safeParse(
        withParameters(validPatternCircular, { targetOperationId: uuid(2) }),
      ).success,
    ).toBe(false);
    expect(
      patternCircularOperationSchema.safeParse(
        withParameters(
          withoutParameterKeys(validPatternCircular, ["targetOperationId"]),
          { op: "fuseInstances" },
        ),
      ).success,
    ).toBe(true);
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(
      patternCircularOperationSchema.safeParse({
        ...validPatternCircular,
        legacyId: "no",
      }).success,
    ).toBe(false);
  });
});

describe("operationSchema (union routing for wave 1)", () => {
  it("discriminates every wave-1 operation by type", () => {
    expect(operationSchema.parse(validDatumPlaneOffset).type).toBe(
      "datum_plane",
    );
    expect(operationSchema.parse(validDatumAxisTwoPoints).type).toBe(
      "datum_axis",
    );
    expect(operationSchema.parse(validShell).type).toBe("shell");
    expect(operationSchema.parse(validMirror).type).toBe("mirror");
    expect(operationSchema.parse(validPatternLinear).type).toBe(
      "pattern_linear",
    );
    expect(operationSchema.parse(validPatternCircular).type).toBe(
      "pattern_circular",
    );
  });

  it("enforces per-mode strictness through the union too", () => {
    expect(() =>
      operationSchema.parse(
        withParameters(validDatumPlaneOffset, { axis: axisEdgeRef }),
      ),
    ).toThrow();
    expect(() =>
      operationSchema.parse(
        withParameters(validPatternLinear, { targetOperationId: uuid(2) }),
      ),
    ).toThrow();
  });
});

describe("stagedOperationTypes", () => {
  it("is exactly the wave-1 set, and every member is a known type", () => {
    // The staged set is the enablement ledger for the catalog wave: native
    // executor lands -> its type leaves this set (and thereby auto-enters
    // the agent's wire toolset). Pinning the membership makes an accidental
    // add/remove a deliberate, reviewed act.
    //
    // 2026-07-26: `mirror`, `pattern_linear` and `pattern_circular` LEFT the
    // set. CAP-007 measured all three executing in the packaged app against
    // real kernel volume probes, so a model call no longer fails closed with
    // UNSUPPORTED_OPERATION — the only reason they were staged. `shell` and
    // both `datum_*` types stay: shell's `openFaces` slot and the datum
    // registry threading are still open (CAP-009 / CAP-014).
    //
    // 2026-07-27 (CAP-034): `offset` JOINED the set, and it is the first member
    // staged for a reason other than "does not execute". It executes; it is
    // staged for wire BUDGET (its v2 `face` slot costs 148 tokens against a pin
    // set at the measured minimum). The verb still ships to users. See the
    // rationale on `stagedOperationTypes` itself — un-staging it is a one-line
    // edit plus a pin re-measure, not new work.
    //
    // 2026-07-27 (CAP-035 piece 1): `sketch` JOINED the set, back on the
    // original reason — the wire schema lands here, the kernel executor lands
    // in piece 2, so until then a sketch reaching evaluate_document would hit a
    // dispatch arm that does not exist. Staged is the honest refusal.
    //
    // 2026-08-04 (sheet-metal wave 1): `base_flange`, `edge_flange`, and
    // `unfold` JOINED the set from day one. Their TS contracts land in the
    // same change as — but from a workstream independent of — the native
    // kernel dispatch for these three types, so a model call fails closed
    // until both sides are proven working together and someone deliberately
    // un-stages them, exactly the treatment brand-new `shell` got.
    //
    // 2026-08-04 (surfacing wave 1): `boundary_surface`, `surface_offset`,
    // `stitch`, and `thicken` JOINED the set the same day, for the identical
    // reason — a second, concurrent workstream lands the native kernel
    // dispatch for these four types against the same field names.
    //
    // 2026-08-04 (electrical wave 1): `wire_route` JOINED the set the same
    // day, for the identical reason — a concurrent, independent workstream
    // lands the native kernel dispatch for this one type against the same
    // field names.
    //
    // 2026-08-05 (mold/tooling wave 1): `mold_parting_line`,
    // `mold_shutoff_surface`, `mold_parting_surface`, and
    // `mold_tooling_split` JOINED the set the same reasoning applies to
    // every wave above — a concurrent, independent workstream lands the
    // native kernel dispatch for these four types against the same field
    // names. `mold_draft_analysis` is never a candidate for this set: it is
    // not an operation at all, so it cannot be staged or un-staged as one —
    // see operations.ts's mold/tooling wave 1 section note.
    expect([...stagedOperationTypes].sort()).toEqual([
      "base_flange",
      "boundary_surface",
      "datum_axis",
      "datum_plane",
      "edge_flange",
      "mold_parting_line",
      "mold_parting_surface",
      "mold_shutoff_surface",
      "mold_tooling_split",
      "offset",
      "shell",
      "sketch",
      "stitch",
      "surface_offset",
      "thicken",
      "unfold",
      "wire_route",
    ]);
    for (const staged of stagedOperationTypes) {
      expect(knownOperationTypes.has(staged), staged).toBe(true);
    }
  });
});

describe("nonAuthorableOperationTypes", () => {
  it("is exactly the two ingestion types, and nothing else, ever", () => {
    // The PERMANENT half of `modelExcludedOperationTypes`, split out from the
    // staging ledger on 2026-08-07 so the two reasons stop being conflated.
    // These two are not staged and never will be: they execute end-to-end, but
    // their geometry is a PRESERVED FILE (a retained STEP text / a checked mesh
    // payload) that no model — 4B sidecar or 200k-context frontier agent —
    // can synthesize into a tool call. A type arriving here is a claim that no
    // agent surface may ever author it; a type that merely lacks budget or an
    // executor belongs in `stagedOperationTypes` instead.
    expect([...nonAuthorableOperationTypes].sort()).toEqual([
      "import_mesh",
      "import_step",
    ]);
    for (const type of nonAuthorableOperationTypes) {
      expect(knownOperationTypes.has(type), type).toBe(true);
    }
  });

  it("is disjoint from stagedOperationTypes — two reasons, never one", () => {
    for (const type of nonAuthorableOperationTypes) {
      expect(stagedOperationTypes.has(type), type).toBe(false);
    }
    for (const staged of stagedOperationTypes) {
      expect(nonAuthorableOperationTypes.has(staged), staged).toBe(false);
    }
  });
});

describe("modelExcludedOperationTypes", () => {
  it("is unchanged by the staging/non-authorable split: the same 19 types", () => {
    // The 2026-08-07 refactor rewrote this set as
    // `[...stagedOperationTypes, ...nonAuthorableOperationTypes]` so the
    // MCP/frontier surface could subtract only the second half. That is a
    // documentation change, NOT a behavior change: this membership is what the
    // SIDECAR wire surface filters by, and its golden token pins (12,573 total
    // / 6,213 for propose_transaction) sit at exactly zero headroom. One name
    // moving here moves those pins. Pinned literally so it cannot drift as a
    // side effect of anything.
    expect([...modelExcludedOperationTypes].sort()).toEqual([
      "base_flange",
      "boundary_surface",
      "datum_axis",
      "datum_plane",
      "edge_flange",
      "import_mesh",
      "import_step",
      "mold_parting_line",
      "mold_parting_surface",
      "mold_shutoff_surface",
      "mold_tooling_split",
      "offset",
      "shell",
      "sketch",
      "stitch",
      "surface_offset",
      "thicken",
      "unfold",
      "wire_route",
    ]);
  });

  it("is exactly the union of its two halves, with no third source", () => {
    const union = [
      ...new Set([...stagedOperationTypes, ...nonAuthorableOperationTypes]),
    ].sort();
    expect([...modelExcludedOperationTypes].sort()).toEqual(union);
    expect(modelExcludedOperationTypes.size).toBe(
      stagedOperationTypes.size + nonAuthorableOperationTypes.size,
    );
    for (const type of modelExcludedOperationTypes) {
      expect(knownOperationTypes.has(type), type).toBe(true);
    }
  });

  it("keeps every staged type available to a surface that skips the budget", () => {
    // The frontier/MCP surface (`@aeth/agent-contracts` `frontierToolNames`)
    // subtracts `nonAuthorableOperationTypes` ONLY. Asserting the arithmetic
    // here — in the package that owns the sets — means a future change that
    // folds the two reasons back together fails at the source rather than
    // silently re-hiding 17 executable operations from frontier agents.
    const frontierVisible = [...modelExcludedOperationTypes]
      .filter((type) => !nonAuthorableOperationTypes.has(type))
      .sort();
    expect(frontierVisible).toEqual([...stagedOperationTypes].sort());
    expect(frontierVisible).toHaveLength(17);
  });
});
