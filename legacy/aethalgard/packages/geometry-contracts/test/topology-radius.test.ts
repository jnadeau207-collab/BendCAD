import { describe, expect, it } from "vitest";

import { topologyEntitySchema } from "../src/topology.js";

const baseEntity = {
  token: "te:8:0:f:0",
  kind: "face" as const,
  geometryClass: "cylinder" as const,
  measure: 125.663706,
  centroid: [0, 0, 5] as const,
  orientation: "forward" as const,
  adjacentTokens: [] as const,
  provenanceOperationId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d51",
  axis: [0, 0, 1] as const,
};

describe("topologyEntitySchema evidence contract", () => {
  it("requires an explicit radius field on every topology entity", () => {
    expect(() => topologyEntitySchema.parse(baseEntity)).toThrow();
  });

  it("accepts a finite non-negative analytic radius", () => {
    expect(
      topologyEntitySchema.parse({ ...baseEntity, radius: 10 }),
    ).toMatchObject({ radius: 10 });
    expect(
      topologyEntitySchema.parse({ ...baseEntity, radius: 0 }),
    ).toMatchObject({ radius: 0 });
  });

  it("allows synthetic analytic entities to omit optional evidence with null", () => {
    expect(
      topologyEntitySchema.parse({
        ...baseEntity,
        axis: null,
        radius: null,
      }),
    ).toMatchObject({ axis: null, radius: null });
  });

  it("uses null explicitly when the geometry has no single radius", () => {
    expect(
      topologyEntitySchema.parse({
        ...baseEntity,
        geometryClass: "plane",
        radius: null,
      }),
    ).toMatchObject({ radius: null });
  });

  it.each([-1, Number.NaN, Number.POSITIVE_INFINITY])(
    "rejects invalid radius %s",
    (radius) => {
      expect(() =>
        topologyEntitySchema.parse({ ...baseEntity, radius }),
      ).toThrow();
    },
  );

  it.each([
    { kind: "face", geometryClass: "line" },
    { kind: "edge", geometryClass: "plane" },
    { kind: "vertex", geometryClass: "circle" },
  ] as const)(
    "rejects $geometryClass on topology kind $kind",
    ({ kind, geometryClass }) => {
      expect(() =>
        topologyEntitySchema.parse({
          ...baseEntity,
          kind,
          geometryClass,
          axis: null,
          radius: null,
        }),
      ).toThrow(/incompatible/);
    },
  );

  it("rejects non-null radius evidence on a non-radial class", () => {
    expect(() =>
      topologyEntitySchema.parse({
        ...baseEntity,
        geometryClass: "plane",
        radius: 5,
      }),
    ).toThrow(/cannot carry radius/);
  });

  it("rejects non-null axis evidence on a non-axial class", () => {
    expect(() =>
      topologyEntitySchema.parse({
        ...baseEntity,
        geometryClass: "sphere",
        radius: null,
      }),
    ).toThrow(/cannot carry axis/);
  });

  it.each([
    { axis: [0, 0, 0] },
    { axis: [0, 0, 2] },
    { axis: [0.5, 0.5, 0.5] },
  ] as const)("rejects non-unit axis evidence $axis", ({ axis }) => {
    expect(() =>
      topologyEntitySchema.parse({ ...baseEntity, axis, radius: 10 }),
    ).toThrow(/unit vector/);
  });

  it.each([
    { axis: [-1, 0, 0] },
    { axis: [0, -1, 0] },
    { axis: [0, 0, -1] },
  ] as const)("rejects non-canonical undirected axis $axis", ({ axis }) => {
    expect(() =>
      topologyEntitySchema.parse({ ...baseEntity, axis, radius: 10 }),
    ).toThrow(/canonical positive sign/);
  });

  it("accepts a negative directed plane normal", () => {
    expect(
      topologyEntitySchema.parse({
        ...baseEntity,
        geometryClass: "plane",
        axis: [-1, 0, 0],
        radius: null,
      }),
    ).toMatchObject({ axis: [-1, 0, 0] });
  });
});
