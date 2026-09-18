import { describe, expect, it } from "vitest";

import {
  manufacturingExportTessellationQuality,
  tessellationQuality,
  tessellationQualityLevels,
  tessellationQualityTable,
  type TessellationQualityLevel,
} from "../src/index.js";

describe("tessellation-quality single-source table", () => {
  it("carries the finding-10 manufacturing-export preset verbatim", () => {
    // These MUST equal the native host constants (kExportLinearDeflectionMm /
    // kExportAngularDeflectionRad / kExportLodTier) and the desktop fixtures —
    // a TS reader and the C++ mesher have to agree on the export identity.
    expect(tessellationQualityTable.manufacturing).toEqual({
      linearDeflectionMm: 0.02,
      angularDeflectionRad: 0.17453292519943295,
      lodTier: 3,
    });
  });

  it("angular tolerance is exactly 10 degrees in radians", () => {
    expect(tessellationQualityTable.manufacturing.angularDeflectionRad).toBe(
      (10 * Math.PI) / 180,
    );
  });

  it("the deflections are finite, positive, and the angle is ≤ π", () => {
    for (const level of tessellationQualityLevels) {
      const quality = tessellationQualityTable[level];
      expect(Number.isFinite(quality.linearDeflectionMm)).toBe(true);
      expect(quality.linearDeflectionMm).toBeGreaterThan(0);
      expect(Number.isFinite(quality.angularDeflectionRad)).toBe(true);
      expect(quality.angularDeflectionRad).toBeGreaterThan(0);
      expect(quality.angularDeflectionRad).toBeLessThanOrEqual(Math.PI);
      expect(Number.isInteger(quality.lodTier)).toBe(true);
    }
  });

  it("the manufacturing tier (3) is above the viewport LOD range (0–2)", () => {
    expect(tessellationQualityTable.manufacturing.lodTier).toBeGreaterThan(2);
  });

  it("every declared level has a table row (exhaustive)", () => {
    for (const level of tessellationQualityLevels) {
      expect(tessellationQualityTable[level]).toBeDefined();
    }
    expect(Object.keys(tessellationQualityTable).sort()).toEqual(
      [...tessellationQualityLevels].sort(),
    );
  });

  it("the convenience alias is the same reference as the table row", () => {
    expect(manufacturingExportTessellationQuality).toBe(
      tessellationQualityTable.manufacturing,
    );
  });

  describe("tessellationQuality accessor", () => {
    it("returns the preset for a known level", () => {
      expect(tessellationQuality("manufacturing")).toBe(
        tessellationQualityTable.manufacturing,
      );
    });

    it("round-trips every declared level", () => {
      for (const level of tessellationQualityLevels) {
        expect(tessellationQuality(level)).toEqual(
          tessellationQualityTable[level],
        );
      }
    });

    it("throws (fails closed) for an unknown level", () => {
      // Cast past the type to prove the runtime guard against a future desync.
      expect(() =>
        tessellationQuality("preview" as TessellationQualityLevel),
      ).toThrow(/Unknown tessellation quality level "preview"/);
    });
  });

  describe("immutability", () => {
    it("the table and its rows are frozen", () => {
      expect(Object.isFrozen(tessellationQualityTable)).toBe(true);
      expect(Object.isFrozen(tessellationQualityTable.manufacturing)).toBe(
        true,
      );
    });

    it("the level list is a readonly tuple", () => {
      expect(tessellationQualityLevels).toEqual(["manufacturing"]);
    });
  });
});
