import { describe, expect, it } from "vitest";

import { topologySnapshotSchema } from "../src/topology.js";

const provenanceOperationId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d51";

const face = {
  token: "te:1:0:f:0",
  kind: "face" as const,
  geometryClass: "plane" as const,
  measure: 100,
  centroid: [0, 0, 0] as const,
  orientation: "forward" as const,
  adjacentTokens: ["te:1:0:e:0"],
  provenanceOperationId,
  axis: [0, 0, 1] as const,
  radius: null,
};

const vertex = {
  token: "te:1:0:v:0",
  kind: "vertex" as const,
  geometryClass: "point" as const,
  measure: 0,
  centroid: [0, 0, 0] as const,
  orientation: "forward" as const,
  adjacentTokens: ["te:1:0:e:0"],
  provenanceOperationId,
  axis: null,
  radius: null,
};

const edge = {
  token: "te:1:0:e:0",
  kind: "edge" as const,
  geometryClass: "line" as const,
  measure: 10,
  centroid: [0, 0, 0] as const,
  orientation: "forward" as const,
  adjacentTokens: [face.token, vertex.token],
  provenanceOperationId,
  axis: [1, 0, 0] as const,
  radius: null,
};

function snapshot(entities: readonly unknown[]) {
  return {
    snapshotId: "snapshot-1",
    evaluationEpoch: 1,
    entities,
  };
}

const validEntities = [face, edge, vertex] as const;

describe("topologySnapshotSchema token and incidence integrity", () => {
  it("accepts unique reciprocal face-edge-vertex incidence", () => {
    expect(
      topologySnapshotSchema.safeParse(snapshot(validEntities)).success,
    ).toBe(true);
  });

  it("rejects duplicate entity tokens", () => {
    expect(() =>
      topologySnapshotSchema.parse(
        snapshot([
          face,
          { ...edge, token: face.token, adjacentTokens: [] },
          vertex,
        ]),
      ),
    ).toThrow(/Duplicate topology token/);
  });

  it("rejects duplicate adjacency entries", () => {
    expect(() =>
      topologySnapshotSchema.parse(
        snapshot([
          { ...face, adjacentTokens: [edge.token, edge.token] },
          edge,
          vertex,
        ]),
      ),
    ).toThrow(/Duplicate adjacent topology token/);
  });

  it("rejects adjacency references to absent entities", () => {
    expect(() =>
      topologySnapshotSchema.parse(
        snapshot([{ ...face, adjacentTokens: ["te:1:0:e:99"] }, edge, vertex]),
      ),
    ).toThrow(/absent from the snapshot/);
  });

  it("rejects self-adjacency", () => {
    expect(() =>
      topologySnapshotSchema.parse(
        snapshot([{ ...face, adjacentTokens: [face.token] }, edge, vertex]),
      ),
    ).toThrow(/cannot be adjacent to itself/);
  });

  it("rejects incidence between incompatible topology levels", () => {
    expect(() =>
      topologySnapshotSchema.parse(
        snapshot([
          { ...face, adjacentTokens: [vertex.token] },
          { ...edge, adjacentTokens: [vertex.token] },
          { ...vertex, adjacentTokens: [face.token, edge.token] },
        ]),
      ),
    ).toThrow(/face cannot be adjacent to vertex/);
  });

  it("rejects one-way adjacency", () => {
    expect(() =>
      topologySnapshotSchema.parse(
        snapshot([face, { ...edge, adjacentTokens: [vertex.token] }, vertex]),
      ),
    ).toThrow(/not reciprocal/);
  });
});
