import {
  maxDocumentOperationsBytes,
  operationsSerializedByteLength,
} from "@aeth/geometry-contracts";
import { defaultMaxControlFrameBytes } from "@aeth/ipc";
import { describe, expect, it } from "vitest";

/**
 * Pins the ONE document-size envelope to the kernel control-frame budget so the
 * two constants can never drift apart. `evaluate_document` and `export_step`
 * send the whole operations array in a single control frame, so the envelope
 * must ride inside that frame with real headroom for the request envelope and
 * (for export) an output path. Without this test, someone could raise
 * `maxDocumentOperationsBytes` past what the frame can carry and reintroduce the
 * "a mutation-accepted document cannot be evaluated" contradiction the envelope
 * exists to remove.
 */
describe("document-size envelope fits the kernel control frame", () => {
  it("leaves real headroom under the control frame for the request envelope and an export path", () => {
    const maxOutputPathBytes = 32_768; // export_step outputPath max (kernel-protocol)
    // Generous fixed overhead for protocolVersion, requestId + documentId
    // UUIDs, method, revision, includeTopology, and JSON structure.
    const requestEnvelopeOverheadBytes = 4_096;
    const worstCaseRequestBytes =
      maxDocumentOperationsBytes +
      maxOutputPathBytes +
      requestEnvelopeOverheadBytes;

    expect(worstCaseRequestBytes).toBeLessThan(defaultMaxControlFrameBytes);
    // Not a hairline fit: keep at least 512 KiB of slack.
    expect(defaultMaxControlFrameBytes - worstCaseRequestBytes).toBeGreaterThan(
      512 * 1024,
    );
  });

  it("measures the serialized byte length of an operations array", () => {
    expect(operationsSerializedByteLength([])).toBe(2); // "[]"
    expect(operationsSerializedByteLength([{ a: 1 }])).toBe(
      new TextEncoder().encode('[{"a":1}]').byteLength,
    );
  });
});
