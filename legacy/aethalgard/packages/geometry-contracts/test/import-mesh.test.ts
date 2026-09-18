import { describe, expect, it } from "vitest";

import {
  bytesToHex,
  canonicalOperationBytes,
  cumulativeOperationHash,
  importMeshOperationSchema,
  knownOperationTypes,
  maxImportMeshSourceChars,
  modelExcludedOperationTypes,
  operationSchema,
  sha256,
  stagedOperationTypes,
} from "../src/index.js";

/** The exact `sourceSha256` the schema/native contract expects for `source`. */
function sha256Hex(source: string): string {
  return bytesToHex(sha256(new TextEncoder().encode(source)));
}

// A stand-in base64 `aeth-mesh-v1` payload. The schema never decodes the mesh —
// only the bytes' shape and integrity anchor — so an opaque base64 string is
// exactly what the operation carries; the kernel is the layer that turns these
// bytes into a body (mesh_import_test.cpp pins the real decode + sew).
const meshSource = "QUVUSE1FU0gAAAAAdGhpcy1pcy1hLXN0YW5kLWluLXBheWxvYWQ=";

const validImportMesh = {
  id: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d80",
  type: "import_mesh",
  schemaVersion: 1,
  name: "Imported widget",
  outputBodyId: "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d81",
  parameters: {
    source: meshSource,
    sourceSha256: sha256Hex(meshSource),
  },
  metadata: {
    createdAt: "2026-07-21T12:00:00.000Z",
    createdBy: { kind: "import", sourceName: "widget.stl" },
  },
} as const;

describe("importMeshOperationSchema", () => {
  it("accepts a well-formed import_mesh through both the direct schema and the union", () => {
    expect(importMeshOperationSchema.parse(validImportMesh).type).toBe(
      "import_mesh",
    );
    expect(operationSchema.parse(validImportMesh).type).toBe("import_mesh");
  });

  it("registers import_mesh as a known operation type", () => {
    expect(knownOperationTypes.has("import_mesh")).toBe(true);
  });

  it("keeps import_mesh out of the agent's model-facing wire surface", () => {
    // It executes end-to-end but is human/UI-driven ingestion, never an
    // agent-authorable tool — a permanent wire exclusion. It is NOT a
    // catalog-wave staging member (that set is the enablement ledger).
    expect(modelExcludedOperationTypes.has("import_mesh")).toBe(true);
    expect(stagedOperationTypes.has("import_mesh")).toBe(false);
  });

  it("accepts agent and user provenance too (the shared metadata arm set)", () => {
    expect(() =>
      importMeshOperationSchema.parse({
        ...validImportMesh,
        metadata: {
          createdAt: "2026-07-21T12:00:00.000Z",
          createdBy: { kind: "user" },
        },
      }),
    ).not.toThrow();
  });

  it("rejects an empty source", () => {
    expect(
      importMeshOperationSchema.safeParse({
        ...validImportMesh,
        parameters: { source: "", sourceSha256: sha256Hex("") },
      }).success,
    ).toBe(false);
  });

  it("rejects a source longer than the ingest bound", () => {
    const tooLong = "A".repeat(maxImportMeshSourceChars + 1);
    expect(
      importMeshOperationSchema.safeParse({
        ...validImportMesh,
        parameters: { source: tooLong, sourceSha256: sha256Hex(tooLong) },
      }).success,
    ).toBe(false);
  });

  it("rejects a malformed sourceSha256 (not 64 lowercase hex)", () => {
    for (const bad of [
      "not-a-hash",
      sha256Hex(meshSource).toUpperCase(),
      sha256Hex(meshSource).slice(0, 63),
      `${sha256Hex(meshSource).slice(0, 63)}g`,
    ]) {
      expect(
        importMeshOperationSchema.safeParse({
          ...validImportMesh,
          parameters: { source: meshSource, sourceSha256: bad },
        }).success,
        bad,
      ).toBe(false);
    }
  });

  it("rejects unknown parameter keys (closed object)", () => {
    expect(
      importMeshOperationSchema.safeParse({
        ...validImportMesh,
        parameters: {
          source: meshSource,
          sourceSha256: sha256Hex(meshSource),
          format: "stl",
        },
      }).success,
    ).toBe(false);
  });

  it("requires an outputBodyId (it is a body-birth operation)", () => {
    const { outputBodyId, ...withoutBody } = validImportMesh;
    void outputBodyId;
    expect(importMeshOperationSchema.safeParse(withoutBody).success).toBe(
      false,
    );
  });
});

describe("import_mesh op-hash contract", () => {
  const documentId = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d00";
  const kernelGeomVersion = "occt-8.0.0+aeth.test";

  it("content-addresses the source: a changed source cascades the hash", () => {
    const otherSource = `${meshSource.slice(0, -4)}ZZZ=`;
    const changed = {
      ...validImportMesh,
      parameters: {
        source: otherSource,
        sourceSha256: sha256Hex(otherSource),
      },
    };
    expect(bytesToHex(canonicalOperationBytes(changed))).not.toBe(
      bytesToHex(canonicalOperationBytes(validImportMesh)),
    );
    expect(
      cumulativeOperationHash(documentId, kernelGeomVersion, [changed]),
    ).not.toBe(
      cumulativeOperationHash(documentId, kernelGeomVersion, [validImportMesh]),
    );
  });

  it("excludes name and metadata: same bytes from a differently-named file share a cache line", () => {
    const renamed = {
      ...validImportMesh,
      name: "A different display name",
      metadata: {
        createdAt: "2030-01-01T00:00:00.000Z",
        createdBy: { kind: "import", sourceName: "renamed-part.obj" },
      },
    };
    expect(
      cumulativeOperationHash(documentId, kernelGeomVersion, [renamed]),
    ).toBe(
      cumulativeOperationHash(documentId, kernelGeomVersion, [validImportMesh]),
    );
  });
});
