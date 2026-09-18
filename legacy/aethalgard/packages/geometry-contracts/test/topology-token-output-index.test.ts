/**
 * The body-scoped topology token (CAP-024 / ADR-013 decision 2).
 *
 * `t:<opId>[:<outputIndex>]/<role>/<ordinal>`. The index lives in the TOKEN
 * rather than beside it, because element enumeration is per-(op, output body):
 * with the index in the envelope, face 3 of solid A and face 3 of solid B of the
 * same multi-solid import would mint the identical string and the token would
 * stop naming exactly one entity.
 *
 * The back-compatibility half matters just as much as the new form. An index of
 * 0 emits the LEGACY bytes, so every single-output operation mints exactly what
 * it always did — which is what lets a schema-2 document round-trip
 * byte-identically through a build that understands schema 3.
 */
import { describe, expect, it } from "vitest";

import {
  formatTopologyToken,
  parseTopologyToken,
  topologyTokenSchema,
} from "../src/refs.js";

const OP = "11111111-2222-4333-8444-555555555555";
const LEGACY_OP = "op_3xk7";

describe("legacy tokens keep working, unchanged", () => {
  it("accepts a token with no output index", () => {
    expect(topologyTokenSchema.safeParse(`t:${OP}/face/3`).success).toBe(true);
  });

  it("reads a missing index as body 0", () => {
    expect(parseTopologyToken(`t:${OP}/face/3`)).toEqual({
      operationId: OP,
      outputIndex: 0,
      role: "face",
      ordinal: 3,
    });
  });

  it("still accepts the legacy op_<base32> id form", () => {
    expect(parseTopologyToken(`t:${LEGACY_OP}/edge/0`)).toEqual({
      operationId: LEGACY_OP,
      outputIndex: 0,
      role: "edge",
      ordinal: 0,
    });
  });

  it("emits the LEGACY bytes for index 0", () => {
    // THE BYTE-IDENTITY PIN. A single-output op must mint exactly the token it
    // minted before this contract grew, or every existing document's refs,
    // op-hashes and replay-cache keys move underneath it.
    expect(
      formatTopologyToken({ operationId: OP, role: "face", ordinal: 3 }),
    ).toBe(`t:${OP}/face/3`);
    expect(
      formatTopologyToken({
        operationId: OP,
        outputIndex: 0,
        role: "face",
        ordinal: 3,
      }),
    ).toBe(`t:${OP}/face/3`);
  });
});

describe("body-scoped tokens", () => {
  it("accepts and round-trips an indexed token", () => {
    const token = `t:${OP}:2/face/3`;
    expect(topologyTokenSchema.safeParse(token).success).toBe(true);
    expect(parseTopologyToken(token)).toEqual({
      operationId: OP,
      outputIndex: 2,
      role: "face",
      ordinal: 3,
    });
    const parsed = parseTopologyToken(token);
    if (parsed === undefined) throw new Error("token did not parse");
    expect(formatTopologyToken(parsed)).toBe(token);
  });

  it("distinguishes the same ordinal on different born bodies", () => {
    // THE WHOLE POINT. Without the index these two are the same string, and a
    // reference to one resolves to the other.
    const a = formatTopologyToken({
      operationId: OP,
      outputIndex: 1,
      role: "face",
      ordinal: 3,
    });
    const b = formatTopologyToken({
      operationId: OP,
      outputIndex: 2,
      role: "face",
      ordinal: 3,
    });
    expect(a).not.toBe(b);
    expect(parseTopologyToken(a)?.outputIndex).toBe(1);
    expect(parseTopologyToken(b)?.outputIndex).toBe(2);
  });

  it("scopes the index to the op id, not to the role", () => {
    const parsed = parseTopologyToken(`t:${OP}:7/edge/12`);
    expect(parsed?.operationId).toBe(OP);
    expect(parsed?.outputIndex).toBe(7);
    expect(parsed?.role).toBe("edge");
    expect(parsed?.ordinal).toBe(12);
  });

  it("round-trips every index through format→parse", () => {
    for (const outputIndex of [0, 1, 9, 10, 137]) {
      const token = formatTopologyToken({
        operationId: OP,
        outputIndex,
        role: "face",
        ordinal: 0,
      });
      expect(parseTopologyToken(token)?.outputIndex).toBe(outputIndex);
    }
  });
});

describe("the grammar still refuses what it always refused", () => {
  it("rejects a non-numeric index", () => {
    expect(topologyTokenSchema.safeParse(`t:${OP}:x/face/3`).success).toBe(
      false,
    );
    expect(parseTopologyToken(`t:${OP}:x/face/3`)).toBeUndefined();
  });

  it("rejects a negative index", () => {
    expect(topologyTokenSchema.safeParse(`t:${OP}:-1/face/3`).success).toBe(
      false,
    );
  });

  it("rejects a missing role or ordinal", () => {
    expect(topologyTokenSchema.safeParse(`t:${OP}:1/face`).success).toBe(false);
    expect(topologyTokenSchema.safeParse(`t:${OP}:1//3`).success).toBe(false);
  });

  it("rejects a malformed operation id", () => {
    expect(topologyTokenSchema.safeParse("t:not-a-uuid:1/face/3").success).toBe(
      false,
    );
  });

  it("rejects a second index separator", () => {
    expect(topologyTokenSchema.safeParse(`t:${OP}:1:2/face/3`).success).toBe(
      false,
    );
  });

  it("returns undefined rather than a partial parse for a non-token", () => {
    expect(parseTopologyToken("not a token")).toBeUndefined();
    expect(parseTopologyToken("")).toBeUndefined();
  });
});
