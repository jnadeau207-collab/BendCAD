import { describe, expect, it } from "vitest";

import {
  kernelProtocolVersion,
  kernelResponseSchema,
  resolvedEntitySchema,
} from "../src/index.js";

const entity = {
  token: "t:aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa/side/0",
  kind: "face" as const,
  bodyId: "bbbbbbbb-2222-4b22-8b22-bbbbbbbbbbbb",
  centroid: [0, 0, 0] as const,
  area: 100,
  surface: "plane" as const,
  normal: [0, 0, 1] as const,
  adjHash: "0123456789abcdef",
};

describe("topology adjacency wire contract", () => {
  it("accepts a deterministic lowercase incidence signature", () => {
    expect(resolvedEntitySchema.parse(entity).adjHash).toBe("0123456789abcdef");
  });

  it("rejects non-hex or uppercase incidence signatures", () => {
    expect(() =>
      resolvedEntitySchema.parse({ ...entity, adjHash: "NOT-HEX" }),
    ).toThrow();
  });

  it("admits an enhanced query response without weakening legacy responses", () => {
    const response = kernelResponseSchema.parse({
      protocolVersion: kernelProtocolVersion,
      requestId: "cccccccc-3333-4c33-8c33-cccccccccccc",
      ok: true,
      result: {
        type: "query",
        entities: [entity],
        diagnostics: [],
        stageCardinalities: [1],
      },
    });
    expect(response.ok).toBe(true);
    if (response.ok && response.result.type === "query") {
      expect(response.result.entities[0]?.adjHash).toBe("0123456789abcdef");
    }
  });
});
