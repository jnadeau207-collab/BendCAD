import { describe, expect, it } from "vitest";

import {
  booleanCombineOperationSchema,
  createBoxOperationSchema,
  createConeOperationSchema,
  createCylinderOperationSchema,
  createProfileOperationSchema,
  createSphereOperationSchema,
  extrudeOperationSchema,
  holeOperationSchema,
  operationSchema,
} from "../src/index.js";

const validBox = {
  id: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d5e",
  type: "create_box",
  schemaVersion: 1,
  name: "Main body",
  outputBodyId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d5f",
  parameters: {
    width: 100,
    depth: 60,
    height: 30,
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
} as const;

const validCylinder = {
  id: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d60",
  type: "create_cylinder",
  schemaVersion: 1,
  name: "Boss",
  outputBodyId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d61",
  parameters: {
    radius: 25,
    height: 80,
    placement: {
      origin: [0, 0, 0],
      zDirection: [0, 0, 1],
      xDirection: [1, 0, 0],
    },
  },
  metadata: {
    createdAt: "2026-07-13T09:00:00.000Z",
    createdBy: { kind: "user" },
  },
} as const;

const validSphere = {
  id: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d62",
  type: "create_sphere",
  schemaVersion: 1,
  name: "Ball",
  outputBodyId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d63",
  parameters: {
    radius: 30,
    placement: {
      origin: [0, 0, 0],
      zDirection: [0, 0, 1],
      xDirection: [1, 0, 0],
    },
  },
  metadata: {
    createdAt: "2026-07-13T09:00:00.000Z",
    createdBy: { kind: "user" },
  },
} as const;

const validProfile = {
  id: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d70",
  type: "create_profile",
  schemaVersion: 1,
  name: "Base plate profile",
  outputProfileId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d71",
  parameters: {
    shape: { kind: "rectangle", width: 80, depth: 50 },
    placement: {
      origin: [0, 0, 0],
      zDirection: [0, 0, 1],
      xDirection: [1, 0, 0],
    },
  },
  metadata: {
    createdAt: "2026-07-13T09:00:00.000Z",
    createdBy: { kind: "user" },
  },
} as const;

const validExtrude = {
  id: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d72",
  type: "extrude",
  schemaVersion: 1,
  name: "Base plate",
  outputBodyId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d73",
  parameters: {
    profileOperationId: validProfile.id,
    distance: 30,
    direction: "normal",
  },
  metadata: {
    createdAt: "2026-07-13T09:00:00.000Z",
    createdBy: { kind: "user" },
  },
} as const;

const validBoolean = {
  id: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d74",
  type: "boolean_combine",
  schemaVersion: 1,
  name: "Bracket with hole",
  outputBodyId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d75",
  parameters: {
    kind: "cut",
    targetOperationId: validBox.id,
    toolOperationId: validCylinder.id,
  },
  metadata: {
    createdAt: "2026-07-13T09:00:00.000Z",
    createdBy: { kind: "user" },
  },
} as const;

const validHole = {
  id: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d76",
  type: "hole",
  schemaVersion: 1,
  name: "Bolt hole",
  outputBodyId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d77",
  parameters: {
    targetOperationId: validBox.id,
    placement: {
      origin: [15, 0, 15],
      zDirection: [0, 0, -1],
      xDirection: [1, 0, 0],
    },
    size: { kind: "radius", radius: 8 },
    depth: 10,
    throughAll: false,
  },
  metadata: {
    createdAt: "2026-07-13T09:00:00.000Z",
    createdBy: { kind: "user" },
  },
} as const;

function profileWithShape(shape: unknown): unknown {
  return {
    ...validProfile,
    parameters: { ...validProfile.parameters, shape },
  };
}

const invalidLengths = [
  0,
  -1,
  Number.NaN,
  Number.POSITIVE_INFINITY,
  1_000_001,
] as const;

describe("createBoxOperationSchema", () => {
  it("accepts a fully specified production operation", () => {
    expect(createBoxOperationSchema.parse(validBox)).toEqual(validBox);
  });

  it.each(invalidLengths)("rejects invalid width %s", (width) => {
    expect(() =>
      createBoxOperationSchema.parse({
        ...validBox,
        parameters: { ...validBox.parameters, width },
      }),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      createBoxOperationSchema.parse({ ...validBox, legacyId: "not-allowed" }),
    ).toThrow();
  });
});

describe("createCylinderOperationSchema", () => {
  it("accepts a fully specified production operation", () => {
    expect(createCylinderOperationSchema.parse(validCylinder)).toEqual(
      validCylinder,
    );
  });

  it("accepts the millimetre upper boundary exactly", () => {
    const parsed = createCylinderOperationSchema.parse({
      ...validCylinder,
      parameters: { ...validCylinder.parameters, radius: 1_000_000 },
    });
    expect(parsed.parameters.radius).toBe(1_000_000);
  });

  it.each(invalidLengths)("rejects invalid radius %s", (radius) => {
    expect(() =>
      createCylinderOperationSchema.parse({
        ...validCylinder,
        parameters: { ...validCylinder.parameters, radius },
      }),
    ).toThrow();
  });

  it.each(invalidLengths)("rejects invalid height %s", (height) => {
    expect(() =>
      createCylinderOperationSchema.parse({
        ...validCylinder,
        parameters: { ...validCylinder.parameters, height },
      }),
    ).toThrow();
  });

  it("rejects a zero-length placement direction", () => {
    expect(() =>
      createCylinderOperationSchema.parse({
        ...validCylinder,
        parameters: {
          ...validCylinder.parameters,
          placement: {
            origin: [0, 0, 0],
            zDirection: [0, 0, 0],
            xDirection: [1, 0, 0],
          },
        },
      }),
    ).toThrow();
  });

  it("rejects a malformed placement with unknown fields", () => {
    expect(() =>
      createCylinderOperationSchema.parse({
        ...validCylinder,
        parameters: {
          ...validCylinder.parameters,
          placement: {
            origin: [0, 0, 0],
            zDirection: [0, 0, 1],
            xDirection: [1, 0, 0],
            twist: 45,
          },
        },
      }),
    ).toThrow();
  });

  it("rejects a placement origin outside the modeling extent", () => {
    expect(() =>
      createCylinderOperationSchema.parse({
        ...validCylinder,
        parameters: {
          ...validCylinder.parameters,
          placement: {
            origin: [10_000_001, 0, 0],
            zDirection: [0, 0, 1],
            xDirection: [1, 0, 0],
          },
        },
      }),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      createCylinderOperationSchema.parse({
        ...validCylinder,
        legacyId: "not-allowed",
      }),
    ).toThrow();
  });

  it("rejects sphere-shaped parameters that are missing the height", () => {
    expect(() =>
      createCylinderOperationSchema.parse({
        ...validCylinder,
        parameters: {
          radius: 25,
          placement: validCylinder.parameters.placement,
        },
      }),
    ).toThrow();
  });
});

describe("createConeOperationSchema", () => {
  const cone = (radiusTop: number) => ({
    id: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d64",
    type: "create_cone",
    schemaVersion: 1,
    name: "Frustum",
    outputBodyId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d65",
    parameters: {
      radiusBottom: 10,
      radiusTop,
      height: 25,
      placement: {
        origin: [0, 0, 0],
        zDirection: [0, 0, 1],
        xDirection: [1, 0, 0],
      },
    },
    metadata: {
      createdAt: "2026-07-13T09:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });

  it("rejects equal radii with the primitive repair code", () => {
    const parsed = createConeOperationSchema.safeParse(cone(10));
    expect(parsed.success).toBe(false);
    if (parsed.success) return;
    expect(parsed.error.issues[0]?.message).toContain(
      "E_PRIM_CONE_EQUAL_RADII",
    );
  });

  it("uses the documented relative equality tolerance", () => {
    expect(createConeOperationSchema.safeParse(cone(10 + 9e-9)).success).toBe(
      false,
    );
    expect(createConeOperationSchema.safeParse(cone(10 + 11e-9)).success).toBe(
      true,
    );
  });
});

describe("createSphereOperationSchema", () => {
  it("accepts a fully specified production operation", () => {
    expect(createSphereOperationSchema.parse(validSphere)).toEqual(validSphere);
  });

  it.each(invalidLengths)("rejects invalid radius %s", (radius) => {
    expect(() =>
      createSphereOperationSchema.parse({
        ...validSphere,
        parameters: { ...validSphere.parameters, radius },
      }),
    ).toThrow();
  });

  it("rejects a stray height parameter so the surface stays exact", () => {
    expect(() =>
      createSphereOperationSchema.parse({
        ...validSphere,
        parameters: { ...validSphere.parameters, height: 10 },
      }),
    ).toThrow();
  });

  it("rejects a malformed placement with a non-vector direction", () => {
    expect(() =>
      createSphereOperationSchema.parse({
        ...validSphere,
        parameters: {
          ...validSphere.parameters,
          placement: {
            origin: [0, 0, 0],
            zDirection: [0, 0],
            xDirection: [1, 0, 0],
          },
        },
      }),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      createSphereOperationSchema.parse({
        ...validSphere,
        legacyId: "not-allowed",
      }),
    ).toThrow();
  });
});

describe("createProfileOperationSchema", () => {
  it("accepts a rectangle profile", () => {
    expect(createProfileOperationSchema.parse(validProfile)).toEqual(
      validProfile,
    );
  });

  it("accepts a circle profile", () => {
    const circle = profileWithShape({ kind: "circle", radius: 20 });
    expect(
      createProfileOperationSchema.parse(circle).parameters.shape.kind,
    ).toBe("circle");
  });

  it("accepts a rounded rectangle strictly below the corner-radius bound", () => {
    const rounded = profileWithShape({
      kind: "roundedRectangle",
      width: 80,
      depth: 50,
      cornerRadius: 24.999,
    });
    expect(
      createProfileOperationSchema.parse(rounded).parameters.shape.kind,
    ).toBe("roundedRectangle");
  });

  it("rejects a cornerRadius at exactly min(width, depth) / 2", () => {
    expect(() =>
      createProfileOperationSchema.parse(
        profileWithShape({
          kind: "roundedRectangle",
          width: 80,
          depth: 50,
          cornerRadius: 25,
        }),
      ),
    ).toThrow();
  });

  it("rejects a cornerRadius above min(width, depth) / 2", () => {
    expect(() =>
      createProfileOperationSchema.parse(
        profileWithShape({
          kind: "roundedRectangle",
          width: 80,
          depth: 50,
          cornerRadius: 26,
        }),
      ),
    ).toThrow();
  });

  it.each(invalidLengths)("rejects invalid rectangle width %s", (width) => {
    expect(() =>
      createProfileOperationSchema.parse(
        profileWithShape({ kind: "rectangle", width, depth: 50 }),
      ),
    ).toThrow();
  });

  it.each(invalidLengths)("rejects invalid circle radius %s", (radius) => {
    expect(() =>
      createProfileOperationSchema.parse(
        profileWithShape({ kind: "circle", radius }),
      ),
    ).toThrow();
  });

  it("rejects unknown profile shape kinds", () => {
    expect(() =>
      createProfileOperationSchema.parse(
        profileWithShape({ kind: "ellipse", radius: 20 }),
      ),
    ).toThrow();
  });

  it("rejects mixed shape parameters so each kind stays exact", () => {
    expect(() =>
      createProfileOperationSchema.parse(
        profileWithShape({ kind: "circle", radius: 20, width: 80 }),
      ),
    ).toThrow();
  });

  it("rejects an output body id: profiles produce no body", () => {
    expect(() =>
      createProfileOperationSchema.parse({
        ...validProfile,
        outputBodyId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d7f",
      }),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      createProfileOperationSchema.parse({
        ...validProfile,
        legacyId: "not-allowed",
      }),
    ).toThrow();
  });
});

describe("extrudeOperationSchema", () => {
  it("accepts a fully specified production operation", () => {
    expect(extrudeOperationSchema.parse(validExtrude)).toEqual(validExtrude);
  });

  it("accepts the millimetre distance upper boundary exactly", () => {
    const parsed = extrudeOperationSchema.parse({
      ...validExtrude,
      parameters: { ...validExtrude.parameters, distance: 1_000_000 },
    });
    expect(parsed.parameters.distance).toBe(1_000_000);
  });

  it.each(invalidLengths)("rejects invalid distance %s", (distance) => {
    expect(() =>
      extrudeOperationSchema.parse({
        ...validExtrude,
        parameters: { ...validExtrude.parameters, distance },
      }),
    ).toThrow();
  });

  it("rejects a non-uuid profile operation reference", () => {
    expect(() =>
      extrudeOperationSchema.parse({
        ...validExtrude,
        parameters: {
          ...validExtrude.parameters,
          profileOperationId: "not-a-uuid",
        },
      }),
    ).toThrow();
  });

  it("rejects directions other than the v1 normal", () => {
    expect(() =>
      extrudeOperationSchema.parse({
        ...validExtrude,
        parameters: { ...validExtrude.parameters, direction: "reverse" },
      }),
    ).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      extrudeOperationSchema.parse({
        ...validExtrude,
        legacyId: "not-allowed",
      }),
    ).toThrow();
  });
});

describe("booleanCombineOperationSchema", () => {
  it.each(["union", "cut", "intersect"] as const)(
    "accepts a fully specified %s operation",
    (kind) => {
      const operation = {
        ...validBoolean,
        parameters: { ...validBoolean.parameters, kind },
      };
      expect(booleanCombineOperationSchema.parse(operation)).toEqual(operation);
    },
  );

  it("rejects unknown boolean kinds", () => {
    expect(() =>
      booleanCombineOperationSchema.parse({
        ...validBoolean,
        parameters: { ...validBoolean.parameters, kind: "xor" },
      }),
    ).toThrow();
  });

  it("rejects a boolean whose target and tool are the same operation", () => {
    expect(() =>
      booleanCombineOperationSchema.parse({
        ...validBoolean,
        parameters: {
          ...validBoolean.parameters,
          toolOperationId: validBoolean.parameters.targetOperationId,
        },
      }),
    ).toThrow();
  });

  it.each(["targetOperationId", "toolOperationId"] as const)(
    "rejects a non-uuid %s",
    (referenceKey) => {
      expect(() =>
        booleanCombineOperationSchema.parse({
          ...validBoolean,
          parameters: {
            ...validBoolean.parameters,
            [referenceKey]: "not-a-uuid",
          },
        }),
      ).toThrow();
    },
  );

  it("rejects a missing output body id: a boolean produces a body", () => {
    const withoutOutput = Object.fromEntries(
      Object.entries(validBoolean).filter(([key]) => key !== "outputBodyId"),
    );
    expect(() => booleanCombineOperationSchema.parse(withoutOutput)).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      booleanCombineOperationSchema.parse({
        ...validBoolean,
        legacyId: "not-allowed",
      }),
    ).toThrow();
  });

  it("rejects stray geometric parameters: booleans only reference bodies", () => {
    expect(() =>
      booleanCombineOperationSchema.parse({
        ...validBoolean,
        parameters: { ...validBoolean.parameters, tolerance: 0.01 },
      }),
    ).toThrow();
  });
});

describe("holeOperationSchema", () => {
  it("accepts a fully specified blind-depth operation", () => {
    expect(holeOperationSchema.parse(validHole)).toEqual(validHole);
  });

  it("accepts a throughAll operation with depth omitted", () => {
    const blindParameters = Object.fromEntries(
      Object.entries(validHole.parameters).filter(([key]) => key !== "depth"),
    );
    const parsed = holeOperationSchema.parse({
      ...validHole,
      parameters: { ...blindParameters, throughAll: true },
    });
    expect(parsed.parameters.throughAll).toBe(true);
    expect(parsed.parameters.depth).toBeUndefined();
  });

  it("defaults the placement to a straight-down drilling axis, unlike shape primitives", () => {
    const withoutPlacement = Object.fromEntries(
      Object.entries(validHole.parameters).filter(
        ([key]) => key !== "placement",
      ),
    );
    const parsed = holeOperationSchema.parse({
      ...validHole,
      parameters: withoutPlacement,
    });
    expect(parsed.parameters.placement).toEqual({
      origin: [0, 0, 0],
      zDirection: [0, 0, -1],
      xDirection: [1, 0, 0],
    });
  });

  it("accepts a diameter-specified size", () => {
    const parsed = holeOperationSchema.parse({
      ...validHole,
      parameters: {
        ...validHole.parameters,
        size: { kind: "diameter", diameter: 16 },
      },
    });
    expect(parsed.parameters.size).toEqual({ kind: "diameter", diameter: 16 });
  });

  it("rejects a depth given alongside throughAll", () => {
    expect(() =>
      holeOperationSchema.parse({
        ...validHole,
        parameters: { ...validHole.parameters, throughAll: true },
      }),
    ).toThrow();
  });

  it("rejects a missing depth when throughAll is false", () => {
    const withoutDepth = Object.fromEntries(
      Object.entries(validHole.parameters).filter(([key]) => key !== "depth"),
    );
    expect(() =>
      holeOperationSchema.parse({ ...validHole, parameters: withoutDepth }),
    ).toThrow();
  });

  it.each(invalidLengths)("rejects an invalid radius %s", (radius) => {
    expect(() =>
      holeOperationSchema.parse({
        ...validHole,
        parameters: {
          ...validHole.parameters,
          size: { kind: "radius", radius },
        },
      }),
    ).toThrow();
  });

  it.each(invalidLengths)("rejects an invalid diameter %s", (diameter) => {
    expect(() =>
      holeOperationSchema.parse({
        ...validHole,
        parameters: {
          ...validHole.parameters,
          size: { kind: "diameter", diameter },
        },
      }),
    ).toThrow();
  });

  it.each(invalidLengths)("rejects an invalid depth %s", (depth) => {
    expect(() =>
      holeOperationSchema.parse({
        ...validHole,
        parameters: { ...validHole.parameters, depth },
      }),
    ).toThrow();
  });

  it("rejects mixed radius/diameter size parameters", () => {
    expect(() =>
      holeOperationSchema.parse({
        ...validHole,
        parameters: {
          ...validHole.parameters,
          size: { kind: "radius", radius: 8, diameter: 16 },
        },
      }),
    ).toThrow();
  });

  it("rejects unknown size kinds", () => {
    expect(() =>
      holeOperationSchema.parse({
        ...validHole,
        parameters: {
          ...validHole.parameters,
          size: { kind: "counterbore", radius: 8 },
        },
      }),
    ).toThrow();
  });

  it("rejects a non-uuid targetOperationId", () => {
    expect(() =>
      holeOperationSchema.parse({
        ...validHole,
        parameters: {
          ...validHole.parameters,
          targetOperationId: "not-a-uuid",
        },
      }),
    ).toThrow();
  });

  it("rejects a missing output body id: a hole produces a body", () => {
    const withoutOutput = Object.fromEntries(
      Object.entries(validHole).filter(([key]) => key !== "outputBodyId"),
    );
    expect(() => holeOperationSchema.parse(withoutOutput)).toThrow();
  });

  it("rejects unknown fields so schema drift is explicit", () => {
    expect(() =>
      holeOperationSchema.parse({ ...validHole, legacyId: "not-allowed" }),
    ).toThrow();
  });
});

describe("operationSchema", () => {
  it("discriminates every production operation by type", () => {
    expect(operationSchema.parse(validBox).type).toBe("create_box");
    expect(operationSchema.parse(validCylinder).type).toBe("create_cylinder");
    expect(operationSchema.parse(validSphere).type).toBe("create_sphere");
    expect(operationSchema.parse(validProfile).type).toBe("create_profile");
    expect(operationSchema.parse(validExtrude).type).toBe("extrude");
    expect(operationSchema.parse(validBoolean).type).toBe("boolean_combine");
    expect(operationSchema.parse(validHole).type).toBe("hole");
  });

  it("enforces target/tool distinctness through the union too", () => {
    expect(() =>
      operationSchema.parse({
        ...validBoolean,
        parameters: {
          ...validBoolean.parameters,
          toolOperationId: validBoolean.parameters.targetOperationId,
        },
      }),
    ).toThrow();
  });

  it("rejects unknown operation types", () => {
    expect(() =>
      operationSchema.parse({ ...validSphere, type: "create_torus" }),
    ).toThrow();
  });

  it("enforces the rounded-rectangle corner bound through the union too", () => {
    expect(() =>
      operationSchema.parse(
        profileWithShape({
          kind: "roundedRectangle",
          width: 10,
          depth: 40,
          cornerRadius: 5,
        }),
      ),
    ).toThrow();
  });
});
