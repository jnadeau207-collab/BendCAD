import { describe, expect, it } from "vitest";

import {
  bytesToHex,
  canonicalOperationBytes,
  cumulativeOperationHash,
  importStepOperationSchema,
  knownOperationTypes,
  maxImportStepSourceChars,
  modelExcludedOperationTypes,
  operationSchema,
  sha256,
  stagedOperationTypes,
} from "../src/index.js";

/** The exact `sourceSha256` the schema/native contract expects for `source`. */
function sha256Hex(source: string): string {
  return bytesToHex(sha256(new TextEncoder().encode(source)));
}

// A minimal but well-formed ISO-10303-21 exchange structure (a single planar
// slab need not be modeled here — the schema never parses geometry, only the
// bytes' shape and integrity anchor). The kernel is the layer that turns these
// bytes into a body; these tests pin the CONTRACT the operation carries.
const stepSource = [
  "ISO-10303-21;",
  "HEADER;",
  "FILE_DESCRIPTION((''),'2;1');",
  "FILE_NAME('bracket.step','2026-07-21T00:00:00',(''),(''),'','','');",
  "FILE_SCHEMA(('AUTOMOTIVE_DESIGN { 1 0 10303 214 }'));",
  "ENDSEC;",
  "DATA;",
  "#1=CARTESIAN_POINT('',(0.,0.,0.));",
  "ENDSEC;",
  "END-ISO-10303-21;",
  "",
].join("\n");

const validImportStep = {
  id: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d80",
  type: "import_step",
  schemaVersion: 1,
  name: "Imported bracket",
  outputBodyId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d81",
  parameters: {
    source: stepSource,
    sourceSha256: sha256Hex(stepSource),
  },
  metadata: {
    createdAt: "2026-07-21T12:00:00.000Z",
    createdBy: { kind: "import", sourceName: "bracket.step" },
  },
} as const;

describe("importStepOperationSchema", () => {
  it("accepts a well-formed import_step through both the direct schema and the union", () => {
    expect(importStepOperationSchema.parse(validImportStep).type).toBe(
      "import_step",
    );
    expect(operationSchema.parse(validImportStep).type).toBe("import_step");
  });

  it("registers import_step as a known operation type", () => {
    expect(knownOperationTypes.has("import_step")).toBe(true);
  });

  it("keeps import_step out of the agent's model-facing wire surface", () => {
    // It executes end-to-end but is human/UI-driven ingestion, never an
    // agent-authorable tool — a permanent wire exclusion. It is NOT a
    // catalog-wave staging member (that set is the enablement ledger).
    expect(modelExcludedOperationTypes.has("import_step")).toBe(true);
    expect(stagedOperationTypes.has("import_step")).toBe(false);
  });

  it("accepts agent and user provenance too (the shared metadata arm set)", () => {
    expect(() =>
      importStepOperationSchema.parse({
        ...validImportStep,
        metadata: {
          createdAt: "2026-07-21T12:00:00.000Z",
          createdBy: { kind: "user" },
        },
      }),
    ).not.toThrow();
  });

  it("rejects an empty source", () => {
    expect(
      importStepOperationSchema.safeParse({
        ...validImportStep,
        parameters: { source: "", sourceSha256: sha256Hex("") },
      }).success,
    ).toBe(false);
  });

  it("rejects a source longer than the ingest bound", () => {
    const tooLong = "A".repeat(maxImportStepSourceChars + 1);
    expect(
      importStepOperationSchema.safeParse({
        ...validImportStep,
        parameters: { source: tooLong, sourceSha256: sha256Hex(tooLong) },
      }).success,
    ).toBe(false);
  });

  it("rejects a malformed sourceSha256 (not 64 lowercase hex)", () => {
    for (const bad of [
      "not-a-hash",
      sha256Hex(stepSource).toUpperCase(),
      sha256Hex(stepSource).slice(0, 63),
      `${sha256Hex(stepSource).slice(0, 63)}g`,
    ]) {
      expect(
        importStepOperationSchema.safeParse({
          ...validImportStep,
          parameters: { source: stepSource, sourceSha256: bad },
        }).success,
        bad,
      ).toBe(false);
    }
  });

  it("rejects unknown parameter keys (closed object)", () => {
    expect(
      importStepOperationSchema.safeParse({
        ...validImportStep,
        parameters: {
          source: stepSource,
          sourceSha256: sha256Hex(stepSource),
          declaredUnit: "mm",
        },
      }).success,
    ).toBe(false);
  });

  it("requires an outputBodyId (it is a body-birth operation)", () => {
    const { outputBodyId, ...withoutBody } = validImportStep;
    void outputBodyId;
    expect(importStepOperationSchema.safeParse(withoutBody).success).toBe(
      false,
    );
  });
});

describe("import_step op-hash contract", () => {
  const documentId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d00";
  const kernelGeomVersion = "occt-8.0.0+aeth.test";

  it("content-addresses the source: a changed source cascades the hash", () => {
    const otherSource = stepSource.replace("0.,0.,0.", "1.,0.,0.");
    const changed = {
      ...validImportStep,
      parameters: {
        source: otherSource,
        sourceSha256: sha256Hex(otherSource),
      },
    };
    expect(bytesToHex(canonicalOperationBytes(changed))).not.toBe(
      bytesToHex(canonicalOperationBytes(validImportStep)),
    );
    expect(
      cumulativeOperationHash(documentId, kernelGeomVersion, [changed]),
    ).not.toBe(
      cumulativeOperationHash(documentId, kernelGeomVersion, [validImportStep]),
    );
  });

  it("excludes name and metadata: same bytes from a differently-named file share a cache line", () => {
    const renamed = {
      ...validImportStep,
      name: "A different display name",
      metadata: {
        createdAt: "2030-01-01T00:00:00.000Z",
        createdBy: { kind: "import", sourceName: "renamed-part.stp" },
      },
    };
    expect(
      cumulativeOperationHash(documentId, kernelGeomVersion, [renamed]),
    ).toBe(
      cumulativeOperationHash(documentId, kernelGeomVersion, [validImportStep]),
    );
  });
});
