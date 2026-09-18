import { z } from "zod";

import { perPacketCountCaps } from "./mesh-budget.js";
import { maxModelExtentMm } from "./operations.js";

export const aembMagic = 0x424d_4541;
export const aembHeaderBytes = 96;
export const aembDirectoryEntryBytes = 16;
export const aembSectionIds = {
  positions: 1,
  normals: 2,
  faceIds: 3,
  triangles: 4,
  faceTable: 5,
  edgeVertices: 6,
  edgeTable: 7,
  brepVertices: 8,
} as const;

export const aembFormatSchema = z.literal("AEMB2");

/**
 * `[minX, minY, minZ, maxX, maxY, maxZ]` in millimetres. Every component is
 * finite and each axis is ordered (min <= max) — a non-finite or inverted box
 * is a broken producer, not a degenerate-but-valid shape. Placing the ordering
 * check on the tuple (rather than the enclosing object) keeps the descriptor
 * and probes objects plain `ZodObject`s so `.extend()` still works downstream.
 */
export const boundingBoxMmSchema = z
  .tuple([
    z.number().finite(),
    z.number().finite(),
    z.number().finite(),
    z.number().finite(),
    z.number().finite(),
    z.number().finite(),
  ])
  .superRefine((box, context) => {
    const axes: readonly (readonly [number, number])[] = [
      [box[0], box[3]],
      [box[1], box[4]],
      [box[2], box[5]],
    ];
    axes.forEach(([min, max], axis) => {
      if (min > max) {
        context.addIssue({
          code: "custom",
          message: `bounding box min exceeds max on axis ${axis}`,
        });
      }
    });
  });

/**
 * The AEMB2 body-local rebasing anchor: the body's world-AABB centre, carried
 * in full f64. Every component is finite and within the shared
 * {@link maxModelExtentMm} envelope — the same bound the kernel enforces before
 * export and `parseAembPacket` re-checks on the header f64s. Subtracting this
 * anchor from a world coordinate yields the body-local value the packet stores
 * as f32; adding it back reconstructs the world coordinate losslessly.
 */
export const worldOriginMmSchema = z.tuple([
  z.number().finite().min(-maxModelExtentMm).max(maxModelExtentMm),
  z.number().finite().min(-maxModelExtentMm).max(maxModelExtentMm),
  z.number().finite().min(-maxModelExtentMm).max(maxModelExtentMm),
]);

export const meshDescriptorSchema = z
  .object({
    streamSequence: z.number().int().nonnegative(),
    packetByteLength: z.number().int().positive(),
    vertexCount: z.number().int().nonnegative(),
    triangleCount: z.number().int().nonnegative(),
    faceCount: z.number().int().nonnegative(),
    edgeCount: z.number().int().nonnegative(),
    edgeVertexCount: z.number().int().nonnegative(),
    brepVertexCount: z.number().int().nonnegative(),
    lodTier: z.number().int().min(0).max(3),
    deflectionMm: z.number().finite().positive(),
    angularDeflectionRad: z.number().finite().positive().max(Math.PI),
    checksumCrc32: z.string().regex(/^[0-9a-f]{8}$/),
    epoch: z.number().int().positive(),
    /** World-space bounding box (f64), UNCHANGED across the AEMB1→AEMB2 bump. */
    boundingBoxMm: boundingBoxMmSchema,
    /** The AEMB2 rebasing anchor = body world-AABB centre (f64). */
    worldOriginMm: worldOriginMmSchema,
    /**
     * Body-local bounding box (f64) = `boundingBoxMm[i] − worldOriginMm[i % 3]`.
     * This is what the packet header's f32 `bboxMin` rounds, so it — not the
     * world box — is what {@link validateMeshDelivery} reconciles against the
     * packet.
     */
    boundingBoxLocalMm: boundingBoxMmSchema,
  })
  .strict();

/**
 * The authoritative per-body descriptor the native evaluation response carries
 * on the control channel, reconciled against the parsed binary packet by
 * {@link validateMeshDelivery}.
 */
export type MeshDescriptor = z.infer<typeof meshDescriptorSchema>;

export interface AembSection {
  readonly id: number;
  readonly byteOffset: number;
  readonly byteLength: number;
}

export interface AembPacket {
  readonly buffer: ArrayBuffer;
  readonly flags: number;
  readonly vertexCount: number;
  readonly triangleCount: number;
  readonly faceCount: number;
  readonly edgeCount: number;
  readonly edgeVertexCount: number;
  readonly brepVertexCount: number;
  readonly lodTier: number;
  readonly deflectionMm: number;
  readonly angularDeflectionRad: number;
  /** Body-local minimum corner (f32) = world min − {@link worldOriginMm}. */
  readonly bboxMin: readonly [number, number, number];
  /** The AEMB2 rebasing anchor (f64): body world-AABB centre. */
  readonly worldOriginMm: readonly [number, number, number];
  readonly sections: ReadonlyMap<number, AembSection>;
}

export class MeshPayloadError extends Error {
  public constructor(message: string) {
    super(message);
    this.name = "MeshPayloadError";
  }
}

export function crc32Hex(buffer: ArrayBuffer): string {
  let crc = 0xffff_ffff;
  for (const byte of new Uint8Array(buffer)) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) {
      const mask = -(crc & 1);
      crc = (crc >>> 1) ^ (0xedb8_8320 & mask);
    }
  }
  return (~crc >>> 0).toString(16).padStart(8, "0");
}

function assertRange(
  buffer: ArrayBuffer,
  offset: number,
  length: number,
): void {
  if (offset < 0 || length < 0 || offset + length > buffer.byteLength) {
    throw new MeshPayloadError(
      `Section range ${offset}+${length} is outside the packet`,
    );
  }
}

/**
 * A tessellation normal may drift from exact unit length only by float
 * round-off. `1e-3` is orders of magnitude wider than a float32 normalization
 * error (~1e-7) yet far tighter than any corruption (a dropped, doubled, or
 * zeroed component), so it separates conformant packets from broken ones
 * without rejecting the producer's own output.
 */
const kNormalMagnitudeTolerance = 1e-3;
const kNormalMagnitudeMinSq = (1 - kNormalMagnitudeTolerance) ** 2;
const kNormalMagnitudeMaxSq = (1 + kNormalMagnitudeTolerance) ** 2;

/** One face-table row, tagged with the faceId its row position implies. */
interface FaceRange {
  readonly faceId: number;
  readonly firstTriangle: number;
  readonly triangleCount: number;
  readonly firstVertex: number;
  readonly vertexCount: number;
}

/** Rejects a float section that carries a NaN or infinity. */
function assertFiniteFloats(
  buffer: ArrayBuffer,
  section: AembSection,
  label: string,
): void {
  const floats = new Float32Array(
    buffer,
    section.byteOffset,
    section.byteLength / 4,
  );
  for (const value of floats) {
    if (!Number.isFinite(value)) {
      throw new MeshPayloadError(`AEMB2 ${label} contains a non-finite float`);
    }
  }
}

/**
 * Rejects a normals section that carries a non-finite component or a normal
 * whose length departs from unit by more than {@link kNormalMagnitudeTolerance}
 * — a zeroed, dropped, or doubled normal never reaches the renderer's lighting.
 */
function assertFiniteNormals(
  buffer: ArrayBuffer,
  section: AembSection,
  vertexCount: number,
): void {
  const normals = new Float32Array(buffer, section.byteOffset, vertexCount * 3);
  for (let vertex = 0; vertex < vertexCount; vertex += 1) {
    const x = normals[vertex * 3];
    const y = normals[vertex * 3 + 1];
    const z = normals[vertex * 3 + 2];
    if (
      x === undefined ||
      y === undefined ||
      z === undefined ||
      !Number.isFinite(x) ||
      !Number.isFinite(y) ||
      !Number.isFinite(z)
    ) {
      throw new MeshPayloadError("AEMB2 normals contain a non-finite float");
    }
    const magnitudeSquared = x * x + y * y + z * z;
    if (
      magnitudeSquared < kNormalMagnitudeMinSq ||
      magnitudeSquared > kNormalMagnitudeMaxSq
    ) {
      throw new MeshPayloadError(
        `AEMB2 normal at vertex ${vertex} is not unit length (|n|^2=${magnitudeSquared})`,
      );
    }
  }
}

/**
 * Proves the face table is a consistent partition. Sorted by first-triangle
 * (ties broken by ascending count so a zero-width null-triangulation face is
 * consumed before the real face that shares its cursor), the triangle ranges
 * must tile `[0, triangleCount)` with no gap or overlap; independently, the
 * vertex ranges must tile `[0, vertexCount)`. The order the faces appear in
 * the table is irrelevant — only the set of ranges is asserted — so a
 * conformant packet whose faces are stored out of ascending order still
 * passes. Returns the triangle-sorted ranges for the ownership pass.
 */
function assertFacePartition(
  faces: readonly FaceRange[],
  triangleCount: number,
  vertexCount: number,
): readonly FaceRange[] {
  const byTriangle = [...faces].sort(
    (left, right) =>
      left.firstTriangle - right.firstTriangle ||
      left.triangleCount - right.triangleCount,
  );
  let triangleCursor = 0;
  for (const face of byTriangle) {
    if (face.firstTriangle !== triangleCursor) {
      throw new MeshPayloadError(
        "AEMB2 face table does not tile the triangle buffer",
      );
    }
    triangleCursor += face.triangleCount;
  }
  if (triangleCursor !== triangleCount) {
    throw new MeshPayloadError(
      "AEMB2 face table does not tile the triangle buffer",
    );
  }

  const byVertex = [...faces].sort(
    (left, right) =>
      left.firstVertex - right.firstVertex ||
      left.vertexCount - right.vertexCount,
  );
  let vertexCursor = 0;
  for (const face of byVertex) {
    if (face.firstVertex !== vertexCursor) {
      throw new MeshPayloadError(
        "AEMB2 face table does not tile the vertex buffer",
      );
    }
    vertexCursor += face.vertexCount;
  }
  if (vertexCursor !== vertexCount) {
    throw new MeshPayloadError(
      "AEMB2 face table does not tile the vertex buffer",
    );
  }

  return byTriangle;
}

/**
 * Single forward pass proving every triangle is owned by the face-table entry
 * whose range contains it: the dense per-triangle face-owner id must equal that
 * entry's faceId, and all three vertex indices must fall inside that entry's
 * vertex range. The owner-scoped vertex check is stricter than a global
 * `index < vertexCount` bound — it also catches a triangle referencing a vertex
 * that belongs to a DIFFERENT face — and so subsumes the global triangle-index
 * and face-owner range checks entirely.
 */
function assertTriangleOwnership(
  triangles: Uint32Array,
  faceIds: Uint32Array,
  byTriangleStart: readonly FaceRange[],
  triangleCount: number,
): void {
  let cursor = 0;
  for (let triangle = 0; triangle < triangleCount; triangle += 1) {
    let owner = byTriangleStart[cursor];
    while (
      owner !== undefined &&
      triangle >= owner.firstTriangle + owner.triangleCount
    ) {
      cursor += 1;
      owner = byTriangleStart[cursor];
    }
    if (
      owner === undefined ||
      triangle < owner.firstTriangle ||
      triangle >= owner.firstTriangle + owner.triangleCount
    ) {
      throw new MeshPayloadError(
        `AEMB2 triangle ${triangle} is not owned by any face-table range`,
      );
    }
    const declaredOwner = faceIds[triangle];
    if (declaredOwner !== owner.faceId) {
      throw new MeshPayloadError(
        `AEMB2 triangle ${triangle} owner ${declaredOwner ?? "undefined"} ` +
          `disagrees with the face table entry ${owner.faceId}`,
      );
    }
    const vertexEnd = owner.firstVertex + owner.vertexCount;
    for (let corner = 0; corner < 3; corner += 1) {
      const index = triangles[triangle * 3 + corner] ?? 0;
      if (index < owner.firstVertex || index >= vertexEnd) {
        throw new MeshPayloadError(
          `AEMB2 triangle ${triangle} references vertex ${index} outside ` +
            `its face's vertex range [${owner.firstVertex}, ${vertexEnd})`,
        );
      }
    }
  }
}

export function parseAembPacket(buffer: ArrayBuffer): AembPacket {
  if (buffer.byteLength < aembHeaderBytes) {
    throw new MeshPayloadError("AEMB2 packet is shorter than its fixed header");
  }
  const view = new DataView(buffer);
  if (view.getUint32(0, true) !== aembMagic)
    throw new MeshPayloadError("Invalid AEMB2 magic");
  if (
    view.getUint16(4, true) !== 2 ||
    view.getUint16(6, true) !== aembHeaderBytes
  )
    throw new MeshPayloadError("Unsupported AEMB version");
  const flags = view.getUint32(8, true);
  if ((flags & ~0b111) !== 0)
    throw new MeshPayloadError("AEMB2 reserved flags are non-zero");
  // The two reserved u32s that pad the 96-byte header to a 16-byte multiple
  // must be zero: a non-zero value is a producer writing a header layout this
  // reader does not understand.
  if (view.getUint32(88, true) !== 0 || view.getUint32(92, true) !== 0)
    throw new MeshPayloadError("AEMB2 reserved header bytes are non-zero");

  const vertexCount = view.getUint32(12, true);
  const triangleCount = view.getUint32(16, true);
  const faceCount = view.getUint32(20, true);
  const edgeCount = view.getUint32(24, true);
  const edgeVertexCount = view.getUint32(28, true);
  const brepVertexCount = view.getUint32(32, true);
  const sectionCount = view.getUint32(36, true);
  const lodTier = view.getUint32(40, true);
  const deflectionMm = view.getFloat32(44, true);
  const angularDeflectionRad = view.getFloat32(60, true);
  if (
    sectionCount !== Object.keys(aembSectionIds).length ||
    lodTier > 3 ||
    !Number.isFinite(deflectionMm) ||
    deflectionMm <= 0 ||
    !Number.isFinite(angularDeflectionRad) ||
    angularDeflectionRad <= 0 ||
    angularDeflectionRad > Math.PI
  ) {
    throw new MeshPayloadError("AEMB2 LOD metadata is invalid");
  }

  // Per-packet count ceilings (finding-8): reject an absurd header before any
  // count is trusted to size a section allocation or a validation loop. The
  // eval-wide totals are a separate budget enforced by the caller.
  const perPacketCaps: readonly (readonly [string, number, number])[] = [
    ["triangleCount", triangleCount, perPacketCountCaps.triangleCount],
    ["vertexCount", vertexCount, perPacketCountCaps.vertexCount],
    ["faceCount", faceCount, perPacketCountCaps.faceCount],
    ["edgeCount", edgeCount, perPacketCountCaps.edgeCount],
    ["edgeVertexCount", edgeVertexCount, perPacketCountCaps.edgeVertexCount],
    ["brepVertexCount", brepVertexCount, perPacketCountCaps.brepVertexCount],
  ];
  for (const [field, actual, cap] of perPacketCaps) {
    if (actual > cap) {
      throw new MeshPayloadError(
        `AEMB2 ${field} ${actual} exceeds the per-packet cap ${cap}`,
      );
    }
  }

  assertRange(buffer, aembHeaderBytes, sectionCount * aembDirectoryEntryBytes);
  const sections = new Map<number, AembSection>();
  const directoryEnd = aembHeaderBytes + sectionCount * aembDirectoryEntryBytes;
  for (let index = 0; index < sectionCount; index += 1) {
    const entry = aembHeaderBytes + index * aembDirectoryEntryBytes;
    const id = view.getUint32(entry, true);
    const byteOffset = view.getUint32(entry + 4, true);
    const byteLength = view.getUint32(entry + 8, true);
    const reserved = view.getUint32(entry + 12, true);
    if (
      reserved !== 0 ||
      byteOffset < directoryEnd ||
      byteOffset % 16 !== 0 ||
      sections.has(id)
    ) {
      throw new MeshPayloadError("AEMB2 section directory is malformed");
    }
    assertRange(buffer, byteOffset, byteLength);
    sections.set(id, { id, byteOffset, byteLength });
  }
  const orderedSections = [...sections.values()].sort(
    (left, right) => left.byteOffset - right.byteOffset,
  );
  for (let index = 1; index < orderedSections.length; index += 1) {
    const previous = orderedSections[index - 1];
    const current = orderedSections[index];
    if (
      previous &&
      current &&
      previous.byteOffset + previous.byteLength > current.byteOffset
    ) {
      throw new MeshPayloadError("AEMB2 sections overlap");
    }
  }

  const expected = new Map<number, number>([
    [aembSectionIds.positions, vertexCount * 12],
    [aembSectionIds.normals, vertexCount * 12],
    [aembSectionIds.faceIds, triangleCount * 4],
    [aembSectionIds.triangles, triangleCount * 12],
    [aembSectionIds.faceTable, faceCount * 16],
    [aembSectionIds.edgeVertices, edgeVertexCount * 12],
    [aembSectionIds.edgeTable, edgeCount * 16],
    [aembSectionIds.brepVertices, brepVertexCount * 12],
  ]);
  for (const [id, byteLength] of expected) {
    if (sections.get(id)?.byteLength !== byteLength) {
      throw new MeshPayloadError(
        `AEMB2 section ${id} has the wrong byte length`,
      );
    }
  }

  // Float finiteness: corrupt positions/normals/edge/B-rep coordinates must
  // never reach Three.js. Every section is present and correctly sized by the
  // byte-length pass above.
  const positions = sections.get(aembSectionIds.positions);
  if (!positions)
    throw new MeshPayloadError("AEMB2 positions section is missing");
  assertFiniteFloats(buffer, positions, "positions");

  const normals = sections.get(aembSectionIds.normals);
  if (!normals) throw new MeshPayloadError("AEMB2 normals section is missing");
  assertFiniteNormals(buffer, normals, vertexCount);

  const edgeVertexSection = sections.get(aembSectionIds.edgeVertices);
  if (!edgeVertexSection)
    throw new MeshPayloadError("AEMB2 edge-vertices section is missing");
  assertFiniteFloats(buffer, edgeVertexSection, "edge vertices");

  const brepVertexSection = sections.get(aembSectionIds.brepVertices);
  if (!brepVertexSection)
    throw new MeshPayloadError("AEMB2 B-rep vertices section is missing");
  assertFiniteFloats(buffer, brepVertexSection, "B-rep vertices");

  const bboxMin: [number, number, number] = [
    view.getFloat32(48, true),
    view.getFloat32(52, true),
    view.getFloat32(56, true),
  ];
  if (!bboxMin.every((value) => Number.isFinite(value))) {
    throw new MeshPayloadError("AEMB2 bounding-box header is not finite");
  }

  // The f64 rebasing anchor (body world-AABB centre) at offsets 64/72/80.
  // Finite and inside the shared modeling envelope: a corrupt or absurd origin
  // would silently displace the whole body once the viewport re-adds it.
  const worldOriginMm: [number, number, number] = [
    view.getFloat64(64, true),
    view.getFloat64(72, true),
    view.getFloat64(80, true),
  ];
  if (
    !worldOriginMm.every(
      (value) => Number.isFinite(value) && Math.abs(value) <= maxModelExtentMm,
    )
  ) {
    throw new MeshPayloadError(
      "AEMB2 world origin is not finite or exceeds the modeling extent",
    );
  }

  const triangles = sections.get(aembSectionIds.triangles);
  if (!triangles)
    throw new MeshPayloadError("AEMB2 triangle section is missing");
  const indices = new Uint32Array(
    buffer,
    triangles.byteOffset,
    triangleCount * 3,
  );

  const faceIds = sections.get(aembSectionIds.faceIds);
  if (!faceIds)
    throw new MeshPayloadError("AEMB2 face-owner section is missing");
  const faceOwners = new Uint32Array(buffer, faceIds.byteOffset, triangleCount);

  const faceTable = sections.get(aembSectionIds.faceTable);
  if (!faceTable) throw new MeshPayloadError("AEMB2 face table is missing");
  const faceRows = new Uint32Array(buffer, faceTable.byteOffset, faceCount * 4);
  const faces: FaceRange[] = [];
  for (let face = 0; face < faceCount; face += 1) {
    const firstTriangle = faceRows[face * 4] ?? 0;
    const ownedTriangles = faceRows[face * 4 + 1] ?? 0;
    const firstVertex = faceRows[face * 4 + 2] ?? 0;
    const ownedVertices = faceRows[face * 4 + 3] ?? 0;
    // Precise early message for a single row that overruns the buffers; the
    // partition/ownership passes below prove the ranges tile and own correctly.
    if (
      firstTriangle + ownedTriangles > triangleCount ||
      firstVertex + ownedVertices > vertexCount
    ) {
      throw new MeshPayloadError("AEMB2 face table range is invalid");
    }
    faces.push({
      faceId: face,
      firstTriangle,
      triangleCount: ownedTriangles,
      firstVertex,
      vertexCount: ownedVertices,
    });
  }
  const byTriangleStart = assertFacePartition(
    faces,
    triangleCount,
    vertexCount,
  );
  assertTriangleOwnership(indices, faceOwners, byTriangleStart, triangleCount);

  const edgeTable = sections.get(aembSectionIds.edgeTable);
  if (!edgeTable) throw new MeshPayloadError("AEMB2 edge table is missing");
  const edges = new Uint32Array(buffer, edgeTable.byteOffset, edgeCount * 4);
  for (let edge = 0; edge < edgeCount; edge += 1) {
    const firstVertex = edges[edge * 4] ?? 0;
    const ownedVertices = edges[edge * 4 + 1] ?? 0;
    const flags = edges[edge * 4 + 2] ?? 0;
    const reserved = edges[edge * 4 + 3] ?? 0;
    if (
      firstVertex + ownedVertices > edgeVertexCount ||
      (flags & ~0b111) !== 0 ||
      reserved !== 0
    ) {
      throw new MeshPayloadError("AEMB2 edge table entry is invalid");
    }
  }

  return {
    buffer,
    flags,
    vertexCount,
    triangleCount,
    faceCount,
    edgeCount,
    edgeVertexCount,
    brepVertexCount,
    lodTier,
    deflectionMm,
    angularDeflectionRad,
    bboxMin,
    worldOriginMm,
    sections,
  };
}

/**
 * A parsed packet disagreed with the authoritative descriptor the control
 * channel promised for it (CRC, byte length, a count, LOD tier, tessellation
 * tolerance, bounding box, epoch, or stream-sequence uniqueness). Any such
 * disagreement means the binary and control channels have desynchronized —
 * protocol corruption (ADR-001), not a policy rejection — so the caller must
 * poison the connection. Carries the offending `field` and the descriptor's
 * `streamSequence` so the fault names the exact body.
 */
export class MeshReconciliationError extends MeshPayloadError {
  public constructor(
    message: string,
    public readonly field: string,
    public readonly streamSequence: number,
  ) {
    super(message);
    this.name = "MeshReconciliationError";
  }
}

/**
 * The single boundary a mesh packet clears before it enters an evaluation
 * snapshot: proves every descriptor field against the parsed packet, the
 * descriptor's `streamSequence` is unique within `seen`, its CRC32 covers the
 * exact bytes, and its epoch matches the evaluation. Cheapest, most decisive
 * checks first (duplicate/epoch/byte-length/CRC) so a corrupt delivery is
 * rejected before the packet is parsed. Any failure throws
 * {@link MeshReconciliationError}; on success the sequence is recorded in
 * `seen` and the validated {@link AembPacket} is returned.
 *
 * Descriptor floats arrive as f64 JSON but the wire stores f32, so the
 * tolerance/bbox comparisons round the descriptor with `Math.fround` and
 * demand an EXACT match — a conformant host writes the identical f32 to both
 * the header and the descriptor, so anything but equality is corruption.
 */
export function validateMeshDelivery(
  descriptor: MeshDescriptor,
  packetBuffer: ArrayBuffer,
  seen: Set<number>,
  expectedEpoch: number,
): AembPacket {
  if (seen.has(descriptor.streamSequence)) {
    throw new MeshReconciliationError(
      `Duplicate streamSequence ${descriptor.streamSequence}`,
      "streamSequence",
      descriptor.streamSequence,
    );
  }
  if (descriptor.epoch !== expectedEpoch) {
    throw new MeshReconciliationError(
      `Descriptor epoch ${descriptor.epoch} != evaluation epoch ${expectedEpoch}`,
      "epoch",
      descriptor.streamSequence,
    );
  }
  if (packetBuffer.byteLength !== descriptor.packetByteLength) {
    throw new MeshReconciliationError(
      `Packet ${packetBuffer.byteLength} bytes != descriptor ${descriptor.packetByteLength}`,
      "packetByteLength",
      descriptor.streamSequence,
    );
  }
  const actualCrc = crc32Hex(packetBuffer);
  if (actualCrc !== descriptor.checksumCrc32) {
    throw new MeshReconciliationError(
      `Packet CRC ${actualCrc} != descriptor ${descriptor.checksumCrc32}`,
      "checksumCrc32",
      descriptor.streamSequence,
    );
  }
  const packet = parseAembPacket(packetBuffer);
  const counts: readonly (readonly [string, number, number])[] = [
    ["vertexCount", packet.vertexCount, descriptor.vertexCount],
    ["triangleCount", packet.triangleCount, descriptor.triangleCount],
    ["faceCount", packet.faceCount, descriptor.faceCount],
    ["edgeCount", packet.edgeCount, descriptor.edgeCount],
    ["edgeVertexCount", packet.edgeVertexCount, descriptor.edgeVertexCount],
    ["brepVertexCount", packet.brepVertexCount, descriptor.brepVertexCount],
    ["lodTier", packet.lodTier, descriptor.lodTier],
  ];
  for (const [field, actual, expected] of counts) {
    if (actual !== expected) {
      throw new MeshReconciliationError(
        `Packet ${field} ${actual} != descriptor ${expected}`,
        field,
        descriptor.streamSequence,
      );
    }
  }
  if (Math.fround(descriptor.deflectionMm) !== packet.deflectionMm) {
    throw new MeshReconciliationError(
      "deflectionMm mismatch",
      "deflectionMm",
      descriptor.streamSequence,
    );
  }
  if (
    Math.fround(descriptor.angularDeflectionRad) !== packet.angularDeflectionRad
  ) {
    throw new MeshReconciliationError(
      "angularDeflectionRad mismatch",
      "angularDeflectionRad",
      descriptor.streamSequence,
    );
  }
  // The packet header stores only the body-LOCAL minimum corner (f32) and the
  // f64 rebasing anchor — the world box is no longer on the wire (AEMB2). So the
  // origin reconciles exactly (both sides are the same f64) and the local box
  // min reconciles under `Math.fround` (the descriptor's f64 rounds to the
  // header's f32). The world `boundingBoxMm` is descriptor-only metadata.
  for (const axis of [0, 1, 2] as const) {
    if (descriptor.worldOriginMm[axis] !== packet.worldOriginMm[axis]) {
      throw new MeshReconciliationError(
        `worldOriginMm[${axis}] mismatch`,
        "worldOriginMm",
        descriptor.streamSequence,
      );
    }
    if (
      Math.fround(descriptor.boundingBoxLocalMm[axis]) !== packet.bboxMin[axis]
    ) {
      throw new MeshReconciliationError(
        `boundingBoxLocalMm[${axis}] mismatch`,
        "boundingBoxLocalMm",
        descriptor.streamSequence,
      );
    }
  }
  seen.add(descriptor.streamSequence);
  return packet;
}
