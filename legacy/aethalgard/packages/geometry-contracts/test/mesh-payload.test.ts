import { describe, expect, it } from "vitest";

import {
  aembDirectoryEntryBytes,
  aembHeaderBytes,
  aembMagic,
  aembSectionIds,
  crc32Hex,
  MeshPayloadError,
  MeshReconciliationError,
  parseAembPacket,
  validateMeshDelivery,
  type MeshDescriptor,
} from "../src/index.js";

const align16 = (value: number): number => (value + 15) & ~15;

function emptyAembPacket(): ArrayBuffer {
  const sectionCount = 8;
  const dataOffset = align16(
    aembHeaderBytes + sectionCount * aembDirectoryEntryBytes,
  );
  const buffer = new ArrayBuffer(dataOffset);
  const view = new DataView(buffer);
  view.setUint32(0, aembMagic, true);
  view.setUint16(4, 2, true);
  view.setUint16(6, aembHeaderBytes, true);
  view.setUint32(36, sectionCount, true);
  view.setFloat32(44, 0.2, true);
  view.setFloat32(60, 0.5, true);
  // worldOriginMm (64/72/80) and reserved (88/92) stay the buffer's zero-fill:
  // a [0, 0, 0] origin is finite and in range, reserved zero passes the parser.
  Object.values(aembSectionIds).forEach((id, index) => {
    const entry = aembHeaderBytes + index * aembDirectoryEntryBytes;
    view.setUint32(entry, id, true);
    view.setUint32(entry + 4, dataOffset, true);
  });
  return buffer;
}

/**
 * Explicit-section AEMB2 builder for the parser tests: header counts are
 * derived from the arrays (positions → vertexCount, triangles → triangleCount,
 * faceTable → faceCount, …) so a fixture stays self-consistent unless a test
 * deliberately corrupts one section. Mirrors the kernel host's 16-byte-aligned
 * layout.
 */
interface PacketSections {
  positions: Float32Array;
  normals: Float32Array;
  faceIds: Uint32Array;
  triangles: Uint32Array;
  faceTable: Uint32Array;
  edgeVertices: Float32Array;
  edgeTable: Uint32Array;
  brepVertices: Float32Array;
  /** Body-local minimum corner written to the AEMB2 header (default 0). */
  bboxMin?: readonly [number, number, number];
  /** The f64 rebasing anchor written at offsets 64/72/80 (default 0). */
  worldOrigin?: readonly [number, number, number];
}

function buildPacket(spec: PacketSections): ArrayBuffer {
  const sections = [
    { id: aembSectionIds.positions, values: spec.positions },
    { id: aembSectionIds.normals, values: spec.normals },
    { id: aembSectionIds.faceIds, values: spec.faceIds },
    { id: aembSectionIds.triangles, values: spec.triangles },
    { id: aembSectionIds.faceTable, values: spec.faceTable },
    { id: aembSectionIds.edgeVertices, values: spec.edgeVertices },
    { id: aembSectionIds.edgeTable, values: spec.edgeTable },
    { id: aembSectionIds.brepVertices, values: spec.brepVertices },
  ];
  let length = align16(
    aembHeaderBytes + sections.length * aembDirectoryEntryBytes,
  );
  const ranges = sections.map(({ values }) => {
    const offset = length;
    length = align16(length + values.byteLength);
    return { offset, byteLength: values.byteLength };
  });
  const buffer = new ArrayBuffer(length);
  const view = new DataView(buffer);
  view.setUint32(0, aembMagic, true);
  view.setUint16(4, 2, true);
  view.setUint16(6, aembHeaderBytes, true);
  view.setUint32(12, spec.positions.length / 3, true); // vertexCount
  view.setUint32(16, spec.triangles.length / 3, true); // triangleCount
  view.setUint32(20, spec.faceTable.length / 4, true); // faceCount
  view.setUint32(24, spec.edgeTable.length / 4, true); // edgeCount
  view.setUint32(28, spec.edgeVertices.length / 3, true); // edgeVertexCount
  view.setUint32(32, spec.brepVertices.length / 3, true); // brepVertexCount
  view.setUint32(36, sections.length, true);
  view.setFloat32(44, 0.2, true);
  view.setFloat32(48, spec.bboxMin?.[0] ?? 0, true);
  view.setFloat32(52, spec.bboxMin?.[1] ?? 0, true);
  view.setFloat32(56, spec.bboxMin?.[2] ?? 0, true);
  view.setFloat32(60, 0.5, true);
  view.setFloat64(64, spec.worldOrigin?.[0] ?? 0, true);
  view.setFloat64(72, spec.worldOrigin?.[1] ?? 0, true);
  view.setFloat64(80, spec.worldOrigin?.[2] ?? 0, true);
  sections.forEach(({ id, values }, index) => {
    const range = ranges[index];
    if (!range) throw new Error("missing section range");
    const entry = aembHeaderBytes + index * aembDirectoryEntryBytes;
    view.setUint32(entry, id, true);
    view.setUint32(entry + 4, range.offset, true);
    view.setUint32(entry + 8, range.byteLength, true);
    new Uint8Array(buffer, range.offset, range.byteLength).set(
      new Uint8Array(values.buffer, values.byteOffset, values.byteLength),
    );
  });
  return buffer;
}

/** One face owning two triangles over a unit square, +Z unit normals. */
function validSquare(): PacketSections {
  return {
    positions: new Float32Array([-1, -1, 0, 1, -1, 0, 1, 1, 0, -1, 1, 0]),
    normals: new Float32Array([0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1]),
    faceIds: new Uint32Array([0, 0]),
    triangles: new Uint32Array([0, 1, 2, 0, 2, 3]),
    faceTable: new Uint32Array([0, 2, 0, 4]),
    edgeVertices: new Float32Array([-1, -1, 0, 1, -1, 0]),
    edgeTable: new Uint32Array([0, 2, 1, 0]),
    brepVertices: new Float32Array([-1, -1, 0]),
  };
}

/**
 * A two-face plate whose face 1 triangles/vertices come FIRST in the buffers
 * (faceIds `[1, 1, 0, 0]`, face 0's face-table row precedes face 1's but points
 * at the later ranges). Replicates `packages/viewport/test/aemb-fixture.ts`
 * `twoFacePlatePacket`: a conformant, order-independent partition the validator
 * must accept.
 */
function reorderedTwoFacePlate(): PacketSections {
  return {
    positions: new Float32Array([
      -10, -5, 0, 0, -5, 0, 0, 5, 0, -10, 5, 0, 0, -5, 0, 10, -5, 0, 10, 5, 0,
      0, 5, 0,
    ]),
    normals: new Float32Array([
      0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1,
    ]),
    triangles: new Uint32Array([4, 5, 6, 4, 6, 7, 0, 1, 2, 0, 2, 3]),
    faceIds: new Uint32Array([1, 1, 0, 0]),
    faceTable: new Uint32Array([2, 2, 0, 4, 0, 2, 4, 4]),
    edgeVertices: new Float32Array([-10, -5, 0, 10, -5, 0]),
    edgeTable: new Uint32Array([0, 2, 1, 0]),
    brepVertices: new Float32Array([-10, -5, 0]),
  };
}

describe("AEMB2 parser", () => {
  it("accepts a structurally complete empty packet", () => {
    expect(parseAembPacket(emptyAembPacket()).sections.size).toBe(8);
  });

  it("rejects unknown reserved flags", () => {
    const buffer = emptyAembPacket();
    new DataView(buffer).setUint32(8, 1 << 12, true);
    expect(() => parseAembPacket(buffer)).toThrow(MeshPayloadError);
  });

  it("rejects an out-of-range section", () => {
    const buffer = emptyAembPacket();
    new DataView(buffer).setUint32(
      aembHeaderBytes + 4,
      buffer.byteLength + 16,
      true,
    );
    expect(() => parseAembPacket(buffer)).toThrow(MeshPayloadError);
  });

  it("rejects a stale AEMB1 header version", () => {
    const buffer = emptyAembPacket();
    new DataView(buffer).setUint16(4, 1, true);
    expect(() => parseAembPacket(buffer)).toThrow(/Unsupported AEMB version/);
  });

  it("rejects a non-zero reserved header word", () => {
    for (const offset of [88, 92]) {
      const buffer = emptyAembPacket();
      new DataView(buffer).setUint32(offset, 1, true);
      expect(() => parseAembPacket(buffer)).toThrow(
        /reserved header bytes are non-zero/,
      );
    }
  });

  it("exposes a finite f64 world origin and rejects an out-of-range one", () => {
    const origin: [number, number, number] = [1_234_567, -7_654_321, 9_999];
    const packet = parseAembPacket(
      buildPacket({ ...validSquare(), worldOrigin: origin }),
    );
    expect([...packet.worldOriginMm]).toEqual(origin);

    const buffer = buildPacket(validSquare());
    // 2e8 mm exceeds the ±1e8 modeling extent the parser enforces.
    new DataView(buffer).setFloat64(64, 2e8, true);
    expect(() => parseAembPacket(buffer)).toThrow(
      /world origin is not finite or exceeds the modeling extent/,
    );
  });
});

describe("AEMB2 export LOD tier 3 (finding-10)", () => {
  it("accepts a packet whose header declares the export lodTier 3", () => {
    const buffer = buildPacket(validSquare());
    // The dedicated export tessellation reports LOD tier 3 (absolute 0.02 mm),
    // one above the viewport's 0-2 range.
    new DataView(buffer).setUint32(40, 3, true);
    expect(parseAembPacket(buffer).lodTier).toBe(3);
  });

  it("still rejects a lodTier above the export tier", () => {
    const buffer = buildPacket(validSquare());
    new DataView(buffer).setUint32(40, 4, true);
    expect(() => parseAembPacket(buffer)).toThrow(/LOD metadata is invalid/);
  });
});

describe("AEMB2 float finiteness", () => {
  it("accepts the valid baseline square", () => {
    expect(parseAembPacket(buildPacket(validSquare())).vertexCount).toBe(4);
  });

  it("rejects a NaN in the positions section", () => {
    const spec = validSquare();
    spec.positions[0] = Number.NaN;
    expect(() => parseAembPacket(buildPacket(spec))).toThrow(
      /positions contains a non-finite float/,
    );
  });

  it("rejects a +Infinity in the normals section", () => {
    const spec = validSquare();
    spec.normals[1] = Number.POSITIVE_INFINITY;
    expect(() => parseAembPacket(buildPacket(spec))).toThrow(
      /normals contain a non-finite float/,
    );
  });

  it("rejects a NaN in the edge-vertices section", () => {
    const spec = validSquare();
    spec.edgeVertices[0] = Number.NaN;
    expect(() => parseAembPacket(buildPacket(spec))).toThrow(
      /edge vertices contains a non-finite float/,
    );
  });

  it("rejects a NaN in the B-rep vertices section", () => {
    const spec = validSquare();
    spec.brepVertices[0] = Number.NaN;
    expect(() => parseAembPacket(buildPacket(spec))).toThrow(
      /B-rep vertices contains a non-finite float/,
    );
  });

  it("rejects a non-finite bounding-box header", () => {
    const spec = validSquare();
    spec.bboxMin = [Number.NaN, 0, 0];
    expect(() => parseAembPacket(buildPacket(spec))).toThrow(
      /bounding-box header is not finite/,
    );
  });
});

describe("AEMB2 normal magnitude", () => {
  it("rejects a zero-length normal", () => {
    const spec = validSquare();
    spec.normals[0] = 0;
    spec.normals[1] = 0;
    spec.normals[2] = 0;
    expect(() => parseAembPacket(buildPacket(spec))).toThrow(
      /is not unit length/,
    );
  });

  it("accepts a near-unit normal inside the tolerance (|n| = 1.0005)", () => {
    const spec = validSquare();
    spec.normals[2] = 1.0005;
    expect(() => parseAembPacket(buildPacket(spec))).not.toThrow();
  });

  it("rejects a doubled normal (0, 0, 2)", () => {
    const spec = validSquare();
    spec.normals[2] = 2;
    expect(() => parseAembPacket(buildPacket(spec))).toThrow(
      /is not unit length/,
    );
  });
});

describe("AEMB2 face-table partition", () => {
  it("accepts the reordered (face-1-first) two-face plate", () => {
    const packet = parseAembPacket(buildPacket(reorderedTwoFacePlate()));
    expect(packet.faceCount).toBe(2);
    expect(packet.triangleCount).toBe(4);
    expect(packet.sections.size).toBe(8);
  });

  it("accepts a degenerate all-empty packet (faceCount = triangleCount = 0)", () => {
    const packet = parseAembPacket(
      buildPacket({
        positions: new Float32Array(0),
        normals: new Float32Array(0),
        faceIds: new Uint32Array(0),
        triangles: new Uint32Array(0),
        faceTable: new Uint32Array(0),
        edgeVertices: new Float32Array(0),
        edgeTable: new Uint32Array(0),
        brepVertices: new Float32Array(0),
      }),
    );
    expect(packet.faceCount).toBe(0);
    expect(packet.triangleCount).toBe(0);
  });

  it("accepts a null-triangulation face sandwiched between two real faces", () => {
    const packet = parseAembPacket(
      buildPacket({
        positions: new Float32Array([
          -10, -5, 0, 0, -5, 0, 0, 5, 0, -10, 5, 0, 0, -5, 0, 10, -5, 0, 10, 5,
          0, 0, 5, 0,
        ]),
        normals: new Float32Array([
          0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0,
          1,
        ]),
        triangles: new Uint32Array([0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7]),
        faceIds: new Uint32Array([0, 0, 2, 2]),
        // Row 1 is a null-triangulation face: zero triangles, zero vertices,
        // its cursors matching the boundary between the two real faces.
        faceTable: new Uint32Array([0, 2, 0, 4, 2, 0, 4, 0, 2, 2, 4, 4]),
        edgeVertices: new Float32Array([-10, -5, 0, 10, -5, 0]),
        edgeTable: new Uint32Array([0, 2, 1, 0]),
        brepVertices: new Float32Array([-10, -5, 0]),
      }),
    );
    expect(packet.faceCount).toBe(3);
    expect(packet.triangleCount).toBe(4);
  });

  it("rejects a gap in the triangle ranges", () => {
    const spec = reorderedTwoFacePlate();
    // Face 1 now owns only triangle 0; triangle 1 is owned by nobody.
    spec.faceTable[5] = 1;
    expect(() => parseAembPacket(buildPacket(spec))).toThrow(
      /does not tile the triangle buffer/,
    );
  });

  it("rejects an overlap in the triangle ranges", () => {
    const spec = reorderedTwoFacePlate();
    // Face 1 now claims triangles 0..2, overlapping face 0 at triangle 2.
    spec.faceTable[5] = 3;
    expect(() => parseAembPacket(buildPacket(spec))).toThrow(
      /does not tile the triangle buffer/,
    );
  });

  it("rejects a gap in the vertex ranges", () => {
    const spec = reorderedTwoFacePlate();
    // Face 0 now owns only vertices 0..2; vertex 3 is owned by nobody.
    spec.faceTable[3] = 3;
    expect(() => parseAembPacket(buildPacket(spec))).toThrow(
      /does not tile the vertex buffer/,
    );
  });

  it("rejects an overlap in the vertex ranges", () => {
    const spec = reorderedTwoFacePlate();
    // Face 0 now claims vertices 0..4, overlapping face 1 at vertex 4.
    spec.faceTable[3] = 5;
    expect(() => parseAembPacket(buildPacket(spec))).toThrow(
      /does not tile the vertex buffer/,
    );
  });

  it("rejects a triangle whose declared owner lies about its face", () => {
    const spec = reorderedTwoFacePlate();
    // Triangle 2 lives in face 0's range but claims faceId 1.
    spec.faceIds[2] = 1;
    expect(() => parseAembPacket(buildPacket(spec))).toThrow(
      /disagrees with the face table entry/,
    );
  });

  it("rejects a triangle referencing a vertex owned by another face (finding-8 regression)", () => {
    const spec = reorderedTwoFacePlate();
    // Triangle 2 belongs to face 0 (vertices 0..3) but now references vertex 4,
    // which is a globally valid index owned by face 1 — the exact leak the old
    // global `index < vertexCount` check let through.
    spec.triangles[8] = 4;
    expect(() => parseAembPacket(buildPacket(spec))).toThrow(
      /outside its face's vertex range/,
    );
  });
});

describe("AEMB2 per-packet count caps (finding-8)", () => {
  it("rejects a header whose triangleCount exceeds the per-packet cap", () => {
    // The cap fires on the raw header count before any section byte-length
    // check, so a bare structurally-empty packet with an inflated count is
    // enough — no 500k-triangle body need be materialised.
    const buffer = emptyAembPacket();
    new DataView(buffer).setUint32(16, 500_001, true); // triangleCount
    expect(() => parseAembPacket(buffer)).toThrow(MeshPayloadError);
    expect(() => parseAembPacket(buffer)).toThrow(/exceeds the per-packet cap/);
  });

  it("rejects a header whose vertexCount exceeds the per-packet cap", () => {
    const buffer = emptyAembPacket();
    new DataView(buffer).setUint32(12, 300_001, true); // vertexCount
    expect(() => parseAembPacket(buffer)).toThrow(/exceeds the per-packet cap/);
  });
});

/**
 * Builds a descriptor that exactly reconciles with `buffer`: counts and LOD
 * metadata are read back from the parsed packet, the CRC covers the exact
 * bytes, and the bounding box carries the packet's min corner. `streamSequence`
 * defaults to 1; `epoch` is supplied by the caller.
 */
function matchingDescriptor(buffer: ArrayBuffer, epoch = 7): MeshDescriptor {
  const packet = parseAembPacket(buffer);
  const origin = [...packet.worldOriginMm] as [number, number, number];
  // Body-local box whose min is exactly the packet header's f32 bboxMin, so it
  // reconciles under Math.fround; world box is that plus the rebasing anchor.
  const local: [number, number, number, number, number, number] = [
    packet.bboxMin[0],
    packet.bboxMin[1],
    packet.bboxMin[2],
    packet.bboxMin[0] + 1,
    packet.bboxMin[1] + 1,
    packet.bboxMin[2] + 1,
  ];
  return {
    streamSequence: 1,
    packetByteLength: buffer.byteLength,
    vertexCount: packet.vertexCount,
    triangleCount: packet.triangleCount,
    faceCount: packet.faceCount,
    edgeCount: packet.edgeCount,
    edgeVertexCount: packet.edgeVertexCount,
    brepVertexCount: packet.brepVertexCount,
    lodTier: packet.lodTier,
    deflectionMm: packet.deflectionMm,
    angularDeflectionRad: packet.angularDeflectionRad,
    checksumCrc32: crc32Hex(buffer),
    epoch,
    boundingBoxMm: local.map((value, axis) => value + origin[axis % 3]) as [
      number,
      number,
      number,
      number,
      number,
      number,
    ],
    worldOriginMm: origin,
    boundingBoxLocalMm: local,
  };
}

describe("validateMeshDelivery (finding-7)", () => {
  const epoch = 7;

  it("accepts a matching descriptor+packet pair and records the sequence", () => {
    const buffer = buildPacket(validSquare());
    const descriptor = matchingDescriptor(buffer, epoch);
    const seen = new Set<number>();
    const packet = validateMeshDelivery(descriptor, buffer, seen, epoch);
    expect(packet.vertexCount).toBe(4);
    expect(seen.has(descriptor.streamSequence)).toBe(true);
  });

  it("reconciles the local box and origin for a body at a large world origin", () => {
    const buffer = buildPacket({
      ...validSquare(),
      bboxMin: [-1, -1, 0],
      worldOrigin: [5_000_000, -3_000_000, 250_000],
    });
    const descriptor = matchingDescriptor(buffer, epoch);
    expect(descriptor.worldOriginMm).toEqual([5_000_000, -3_000_000, 250_000]);
    const packet = validateMeshDelivery(descriptor, buffer, new Set(), epoch);
    expect([...packet.worldOriginMm]).toEqual([5_000_000, -3_000_000, 250_000]);
  });

  it("rejects a descriptor whose streamSequence was already seen", () => {
    const buffer = buildPacket(validSquare());
    const descriptor = matchingDescriptor(buffer, epoch);
    const seen = new Set<number>([descriptor.streamSequence]);
    try {
      validateMeshDelivery(descriptor, buffer, seen, epoch);
      expect.unreachable();
    } catch (error) {
      expect(error).toBeInstanceOf(MeshReconciliationError);
      expect((error as MeshReconciliationError).field).toBe("streamSequence");
    }
  });

  it("rejects a descriptor whose epoch does not match the evaluation", () => {
    const buffer = buildPacket(validSquare());
    const descriptor = matchingDescriptor(buffer, epoch);
    try {
      validateMeshDelivery(descriptor, buffer, new Set(), epoch + 1);
      expect.unreachable();
    } catch (error) {
      expect(error).toBeInstanceOf(MeshReconciliationError);
      expect((error as MeshReconciliationError).field).toBe("epoch");
      expect((error as MeshReconciliationError).streamSequence).toBe(
        descriptor.streamSequence,
      );
    }
  });

  const fieldCases: readonly {
    name: string;
    field: string;
    mutate: (descriptor: MeshDescriptor) => void;
  }[] = [
    {
      name: "CRC",
      field: "checksumCrc32",
      mutate: (d) => {
        d.checksumCrc32 =
          d.checksumCrc32 === "00000000" ? "ffffffff" : "00000000";
      },
    },
    {
      name: "byte length",
      field: "packetByteLength",
      mutate: (d) => {
        d.packetByteLength += 1;
      },
    },
    {
      name: "vertexCount",
      field: "vertexCount",
      mutate: (d) => {
        d.vertexCount += 1;
      },
    },
    {
      name: "triangleCount",
      field: "triangleCount",
      mutate: (d) => {
        d.triangleCount += 1;
      },
    },
    {
      name: "faceCount",
      field: "faceCount",
      mutate: (d) => {
        d.faceCount += 1;
      },
    },
    {
      name: "edgeCount",
      field: "edgeCount",
      mutate: (d) => {
        d.edgeCount += 1;
      },
    },
    {
      name: "edgeVertexCount",
      field: "edgeVertexCount",
      mutate: (d) => {
        d.edgeVertexCount += 1;
      },
    },
    {
      name: "brepVertexCount",
      field: "brepVertexCount",
      mutate: (d) => {
        d.brepVertexCount += 1;
      },
    },
    {
      name: "lodTier",
      field: "lodTier",
      mutate: (d) => {
        d.lodTier = d.lodTier === 2 ? 1 : d.lodTier + 1;
      },
    },
    {
      name: "deflectionMm",
      field: "deflectionMm",
      mutate: (d) => {
        d.deflectionMm += 1;
      },
    },
    {
      name: "angularDeflectionRad",
      field: "angularDeflectionRad",
      mutate: (d) => {
        d.angularDeflectionRad += 0.1;
      },
    },
    {
      name: "boundingBoxLocalMm[0]",
      field: "boundingBoxLocalMm",
      mutate: (d) => {
        d.boundingBoxLocalMm[0] += 1;
      },
    },
    {
      name: "worldOriginMm[0]",
      field: "worldOriginMm",
      mutate: (d) => {
        d.worldOriginMm[0] += 1;
      },
    },
  ];

  it.each(fieldCases)(
    "rejects a $name mismatch as MeshReconciliationError",
    ({ field, mutate }) => {
      const buffer = buildPacket(validSquare());
      const descriptor = matchingDescriptor(buffer, epoch);
      mutate(descriptor);
      const seen = new Set<number>();
      try {
        validateMeshDelivery(descriptor, buffer, seen, epoch);
        expect.unreachable(`expected ${field} mismatch to throw`);
      } catch (error) {
        expect(error).toBeInstanceOf(MeshReconciliationError);
        expect((error as MeshReconciliationError).field).toBe(field);
        expect((error as MeshReconciliationError).streamSequence).toBe(
          descriptor.streamSequence,
        );
      }
      // A rejected delivery must not record its sequence.
      expect(seen.has(descriptor.streamSequence)).toBe(false);
    },
  );
});
