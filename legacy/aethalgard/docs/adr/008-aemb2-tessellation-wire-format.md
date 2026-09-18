# ADR-008: AEMB2 is the tessellation wire format — ATB1 is retired

Date: 2026-07-19
Status: accepted (founder decision, 2026-07-19 — records the shipped format;
mandated for the record by `docs/audits/2026-07-17-plan-realignment.md` §4.B)

## Context

`docs/plan/05-viewport/02-geometry-pipeline.md` normatively specifies
**ATB1** ("Aethalgard Tessellation Buffer, version 1", magic `0x31425441`,
64-byte header) as the binary contract between the kernel host and the
viewport, including negotiated oct16-normal/u16-index compression flags and
a load-bearing "triangles grouped contiguously by face, ascending face
index" ordering rule. ATB1 was specified before any kernel code existed and
was never implemented.

What shipped is **AEMB** — first AEMB1 (already the packet named on ADR-001's
fd-3 binary stream), then bumped to **AEMB2** when body-local f32 rebasing
over a world-AABB-centre anchor was added (honoring the chapter's own rule
that any change is a version bump, never an in-place mutation). The single
source of truth is code, not this chapter:

- Producer: `native/kernel-host/src/tessellate.cpp` (`EncodeAemb`).
- Parser/validator: `packages/geometry-contracts/src/mesh-payload.ts`
  (`parseAembPacket`, `validateMeshDelivery`, `MeshPayloadError`,
  `meshDescriptorSchema` with `aembFormatSchema = z.literal("AEMB2")`).
- Consumer: `packages/viewport/src/aemb-geometry.ts`; adversarial golden
  fixtures in `packages/viewport/test/aemb-fixture.ts`.

The AEMB1→AEMB2 bump exists because worlds up to ±1e7 mm stored directly as
f32 collapse fine features into ~1 mm float spacing. AEMB2 stores every
coordinate **body-local**: the kernel subtracts the body's world-AABB centre
in f64 _before_ narrowing to f32, and carries that anchor in the header as
full f64 so the viewport re-bases losslessly. The world-space bounding box
moved to the control-channel descriptor (it is no longer on the binary wire);
the header's f32 `bboxMin` became body-local.

## Decision

**AEMB2 is the tessellation wire format. ATB1 is retired unimplemented.**
The byte layout below is transcribed from `mesh-payload.ts` /
`tessellate.cpp` and is normative; the chapter's ATB1 tables are superseded
and survive only as marked historical text (the chapter rewrite is a
separate wave-0.4 doc item).

One packet = one body at one LOD tier: a single little-endian
`ArrayBuffer`; all section payloads 16-byte aligned.

### Header (96 bytes, `aembHeaderBytes`)

| Offset | Type     | Field                | Constraint (fail-closed)                                                                               |
| ------ | -------- | -------------------- | ------------------------------------------------------------------------------------------------------ |
| 0      | `u32`    | magic                | `0x424D4541` (bytes `41 45 4D 42` = ASCII "AEMB")                                                      |
| 4      | `u16`    | version              | `2`                                                                                                    |
| 6      | `u16`    | headerBytes          | `96`                                                                                                   |
| 8      | `u32`    | flags                | producer writes `0`; bits 0–2 reader-tolerated for future negotiation, bits 3–31 must be 0             |
| 12     | `u32`    | vertexCount          | ≤ per-packet cap (`mesh-budget.ts`)                                                                    |
| 16     | `u32`    | triangleCount        | ≤ cap                                                                                                  |
| 20     | `u32`    | faceCount            | ≤ cap                                                                                                  |
| 24     | `u32`    | edgeCount            | ≤ cap                                                                                                  |
| 28     | `u32`    | edgeVertexCount      | ≤ cap                                                                                                  |
| 32     | `u32`    | brepVertexCount      | ≤ cap                                                                                                  |
| 36     | `u32`    | sectionCount         | exactly `8`                                                                                            |
| 40     | `u32`    | lodTier              | 0–2 = viewport tiers (ADR-004); **3 = manufacturing-export profile** (0.02 mm / 10°, `tessellate.cpp`) |
| 44     | `f32`    | deflectionMm         | finite, > 0                                                                                            |
| 48     | `f32[3]` | bboxMin              | **body-local** minimum corner = world min − worldOriginMm                                              |
| 60     | `f32`    | angularDeflectionRad | finite, > 0, ≤ π                                                                                       |
| 64     | `f64[3]` | worldOriginMm        | the rebasing anchor = body world-AABB centre; each component finite,                                   | v   | ≤ `maxModelExtentMm` |
| 88     | `u32`    | reserved             | `0`                                                                                                    |
| 92     | `u32`    | reserved             | `0`                                                                                                    |

### Section directory

Immediately after the header: 8 entries × 16 bytes
(`aembDirectoryEntryBytes`): `u32 sectionId`, `u32 byteOffset` (16-aligned,
≥ directory end), `u32 byteLength`, `u32 reserved (0)`. Duplicate ids,
overlapping ranges, or out-of-buffer ranges reject the packet.

### Sections (`aembSectionIds`)

| id  | Name         | Element   | Byte length        | Content                                                                                                                                    |
| --- | ------------ | --------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | positions    | `f32 × 3` | vertexCount·12     | body-local mm; finite (NaN/∞ reject)                                                                                                       |
| 2   | normals      | `f32 × 3` | vertexCount·12     | unit length within 1e-3 magnitude tolerance, finite                                                                                        |
| 3   | faceIds      | `u32`     | triangleCount·4    | **per-TRIANGLE** owning-face id (ATB1 had per-vertex FACE_IDS — changed)                                                                   |
| 4   | triangles    | `u32 × 3` | triangleCount·12   | vertex indices; each triangle's vertices must lie inside its owning face's vertex range                                                    |
| 5   | faceTable    | 16 B/row  | faceCount·16       | `u32 firstTriangle, u32 triangleCount, u32 firstVertex, u32 vertexCount`; row index = faceId                                               |
| 6   | edgeVertices | `f32 × 3` | edgeVertexCount·12 | edge polyline points, finite                                                                                                               |
| 7   | edgeTable    | 16 B/row  | edgeCount·16       | `u32 firstVertex, u32 vertexCount, u32 flags, u32 reserved(0)`; flags bit0 SHARP(1), bit1 SMOOTH(2), bit2 BOUNDARY(4), bits 3–31 must be 0 |
| 8   | brepVertices | `f32 × 3` | brepVertexCount·12 | B-rep vertex positions (pick/snap points), finite                                                                                          |

### Validation semantics (differ deliberately from ATB1)

- **No storage-order mandate.** ATB1 made "triangles grouped by ascending
  face index" load-bearing. AEMB2 instead asserts a **partition**: the face
  table's triangle ranges must tile `[0, triangleCount)` and its vertex
  ranges `[0, vertexCount)` with no gap/overlap, every triangle's dense
  `faceIds` owner must equal its covering row, and each triangle may only
  reference vertices of its own face — but the rows may be stored in any
  order. The golden fixtures are adversarial about exactly this
  (`twoFacePlatePacket` stores face 1's triangles first;
  `multiEdgePlatePacket` stores edge polylines out of table order).
- **No negotiated compression.** ATB1's oct16-normals/u16-indices flag bits
  do not exist; unknown flag bits fail closed instead.
- **Pre-allocation caps.** Every header count is checked against
  `perPacketCountCaps` before any count sizes an allocation or loop.
- **Delivery reconciliation.** Packets ride ADR-001's fd-3 `ABM1` frames and
  are reconciled against the control-channel `MeshDescriptor`
  (`validateMeshDelivery`): unique `streamSequence`, evaluation epoch match,
  exact byte length, CRC-32 over the exact bytes, all counts, LOD metadata
  under `Math.fround`-exact float equality, f64-exact `worldOriginMm`, and
  `Math.fround`-exact body-local bbox min. Any disagreement is protocol
  corruption → `MeshReconciliationError` → connection poisoned (ADR-001),
  never a policy rejection.

### Version discipline

ATB1's own rule carries forward: any layout change is a version bump
(AEMB3), never an in-place mutation. The `u16 version` field and
`aembFormatSchema` literal gate both sides.

## Consequences

- `docs/plan/05-viewport/02-geometry-pipeline.md` §2 (all ATB1 byte tables),
  the ATB1 references in §§1, 3, 4, 6, 9, and the "ATB1" upstream-contract
  note are superseded — the chapter carries in-place pointer notes to this
  ADR; the full byte-exact chapter rewrite is owned by the wave-0.4 plan-
  chapter item. The string "ATB1" may survive only in historical/superseded
  notes.
- The renderer consumes sections as zero-copy typed-array views over the
  packet buffer (`aemb-geometry.ts`); `faceIds` being per-triangle means
  per-face picking/highlight derives from the face table, not a per-vertex
  attribute, and the viewport builds its own per-vertex attribute when a
  shader needs one.
- Envelope metadata that ATB1 kept in the JSON message (`bboxMax`,
  appearance, instancing) is NOT part of AEMB2; today's control-channel
  carrier is the kernel evaluation response's `meshDescriptorSchema` entry.
  Instancing/appearance remain future control-plane concerns and must not
  be added to the binary format without a version bump.
- Any future producer/parser change updates `tessellate.cpp`,
  `mesh-payload.ts`, and the fixtures in the same change — the established
  cross-language golden-fixture discipline
  (`docs/design/2026-07-17-op-hash-contract.md` precedent).
