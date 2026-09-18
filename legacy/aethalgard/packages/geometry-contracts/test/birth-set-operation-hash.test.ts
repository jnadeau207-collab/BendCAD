/**
 * The birth set participates in the op-hash, and costs existing documents
 * nothing (CAP-024 / ADR-013).
 *
 * `canonicalOperationBytes` hashes every key except name/metadata/anchors/
 * snapHints, so `outputBodyIds` is covered with no hasher change and no
 * `excludedKeys` change — the same property CAP-021's fit compensation relies
 * on. That is worth MEASURING rather than assuming, twice over:
 *
 * - a different birth set must be a different hash, or the native BodyPool
 *   replay cache would serve the bodies of a previous import;
 * - an import that declares no set must produce the bytes it always did, or
 *   every existing document's cache key moves underneath it on upgrade.
 */
import { describe, expect, it } from "vitest";

import { bytesToHex, canonicalOperationBytes, sha256 } from "../src/index.js";

const OP = "018f0f5d-7b3a-7cc1-9d22-7a0a96d30d11";
const BODY = (n: number): string =>
  `018f0f5d-7b3a-7cc1-9d22-7a0a96d30d${String(n).padStart(2, "0")}`;

function importStep(
  outputBodyIds?: readonly string[],
): Record<string, unknown> {
  return {
    id: OP,
    type: "import_step",
    schemaVersion: 1,
    name: "Imported",
    outputBodyId: BODY(1),
    ...(outputBodyIds === undefined ? {} : { outputBodyIds }),
    parameters: { source: "ISO-10303-21;", sourceSha256: "a".repeat(64) },
    metadata: {
      createdAt: "2026-07-28T00:00:00.000Z",
      createdBy: { kind: "user" },
    },
  };
}

const hashOf = (operation: unknown): string =>
  bytesToHex(sha256(canonicalOperationBytes(operation)));

describe("a single-solid import is untouched", () => {
  it("produces the same bytes with the field absent as it always did", () => {
    // THE UPGRADE-SAFETY PIN. The field is optional with NO default, so an
    // import that predates fan-out serializes identically — its op-hash and its
    // replay-cache key do not move when this contract grows.
    const bytes = canonicalOperationBytes(importStep());
    const text = new TextDecoder().decode(bytes);
    expect(text).not.toContain("outputBodyIds");
    expect(text).toContain('"outputBodyId":');
  });

  it("is NOT equal to the same import that declares a one-body set", () => {
    // Declaring `[body0]` explicitly is a different document than declaring
    // nothing, so it must hash differently — otherwise the two would share a
    // cache entry while carrying different persisted content.
    expect(hashOf(importStep())).not.toBe(hashOf(importStep([BODY(1)])));
  });
});

describe("the birth set changes the hash", () => {
  it("hashes a two-body import differently from a one-body one", () => {
    expect(hashOf(importStep([BODY(1)]))).not.toBe(
      hashOf(importStep([BODY(1), BODY(2)])),
    );
  });

  it("is ORDER-SENSITIVE", () => {
    // The order is the canonical geometric order, and it decides which solid is
    // index 0 — which every reference and every element name is scoped to. Two
    // orders are two different documents and must never share a cache entry.
    expect(hashOf(importStep([BODY(1), BODY(2)]))).not.toBe(
      hashOf(importStep([BODY(2), BODY(1)])),
    );
  });

  it("distinguishes a changed member", () => {
    expect(hashOf(importStep([BODY(1), BODY(2)]))).not.toBe(
      hashOf(importStep([BODY(1), BODY(3)])),
    );
  });

  it("is stable for the same set", () => {
    expect(hashOf(importStep([BODY(1), BODY(2)]))).toBe(
      hashOf(importStep([BODY(1), BODY(2)])),
    );
  });

  it("ignores name and metadata, as it always has", () => {
    const a = importStep([BODY(1), BODY(2)]);
    const b = {
      ...importStep([BODY(1), BODY(2)]),
      name: "Renamed",
      metadata: {
        createdAt: "2030-01-01T00:00:00.000Z",
        createdBy: { kind: "agent", runId: OP },
      },
    };
    expect(hashOf(a)).toBe(hashOf(b));
  });
});
