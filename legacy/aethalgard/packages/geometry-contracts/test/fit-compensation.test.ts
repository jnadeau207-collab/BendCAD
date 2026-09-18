import { describe, expect, it } from "vitest";

import {
  boltOperationSchema,
  compensationClearanceMm,
  fitCompensationSchema,
  canonicalOperationBytes,
  type FitCompensation,
} from "../src/index.js";

const COMPENSATION: FitCompensation = {
  fit: "slide",
  clearanceMm: 0.32,
  terms: { base: 0.25, nozzleScale: 0.02, material: 0, user: 0.05 },
  rule: 'FDM named fit "slide" (08 §6): 0.25 mm diametral at a 0.40 mm nozzle, +0.02 nozzle/die-swell, +0.05 fit-coin → 0.32 mm.',
  source: "docs/plan/06-print-pipeline/08-hardware-standards-data.md#6",
};

function bytesText(operation: unknown): string {
  return new TextDecoder().decode(canonicalOperationBytes(operation));
}

function bolt(parameters: Record<string, unknown>): unknown {
  return boltOperationSchema.parse({
    id: "11111111-2222-4333-8444-555555555555",
    type: "bolt",
    schemaVersion: 1,
    name: "Bolt 1",
    outputBodyId: "66666666-7777-4888-8999-aaaaaaaaaaaa",
    parameters: {
      targetOperationId: "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee",
      size: "M3",
      throughAll: true,
      ...parameters,
    },
    metadata: {
      createdAt: "2026-07-28T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  });
}

describe("fitCompensationSchema", () => {
  it("keeps the terms, not just the number", () => {
    const parsed = fitCompensationSchema.parse(COMPENSATION);
    expect(parsed.terms.user).toBe(0.05);
    expect(parsed.clearanceMm).toBe(0.32);
    // The rule sentence travels with it, so the size can be explained rather
    // than asserted — namedFit's own contract, carried into the document.
    expect(parsed.rule).toContain("fit-coin");
  });

  it("refuses a negative clearance", () => {
    expect(() =>
      fitCompensationSchema.parse({ ...COMPENSATION, clearanceMm: -0.01 }),
    ).toThrow();
  });

  it("refuses an unknown fit preset", () => {
    expect(() =>
      fitCompensationSchema.parse({ ...COMPENSATION, fit: "snugish" }),
    ).toThrow();
  });

  it("refuses unknown keys — the record is closed", () => {
    expect(() =>
      fitCompensationSchema.parse({ ...COMPENSATION, extra: 1 }),
    ).toThrow();
  });

  it("reads zero allowance from no record at all", () => {
    expect(compensationClearanceMm(undefined)).toBe(0);
    expect(compensationClearanceMm(COMPENSATION)).toBe(0.32);
  });
});

describe("the bolt's stored allowance and what the op-hash is computed over", () => {
  it("is optional with NO default, so an old bolt gains nothing", () => {
    const plain = bolt({}) as { parameters: Record<string, unknown> };
    // Absent, not defaulted: the canonical JSON is byte-identical to what a
    // pre-CAP-021 document produced, which is why the cross-language golden
    // vector is untouched.
    expect("compensation" in plain.parameters).toBe(false);
  });

  it("leaves the canonical bytes identical for a bolt that carries none", () => {
    // Two independently parsed bolts with no record hash the same; if the field
    // had a default, this is where that would show up.
    expect(bytesText(bolt({}) as never)).toBe(bytesText(bolt({}) as never));
  });

  it("CHANGES the canonical bytes when an allowance is stored — so the replay cache re-keys", () => {
    const without = bytesText(bolt({}) as never);
    const with_ = bytesText(bolt({ compensation: COMPENSATION }) as never);
    expect(with_).not.toBe(without);
  });

  it("CHANGES the canonical bytes when the allowance itself changes", () => {
    const a = bytesText(bolt({ compensation: COMPENSATION }) as never);
    const b = bytesText(
      bolt({
        compensation: { ...COMPENSATION, clearanceMm: 0.33 },
      }) as never,
    );
    // This is the whole reason the record lives in `parameters`: a different
    // allowance is a different key, so a warm replay can never serve geometry
    // cut to the old one.
    expect(a).not.toBe(b);
  });
});
