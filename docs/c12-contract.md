# C12 contract — versioned archive, STEP read/write profile, mesh exports

Scope (MASTER_PLAN §10 C12): BendCAD's versioned B-rep archive with
topology, analytic definitions, parameter curves, units, lineage, and
semantic versioning; a declared STEP read/write profile; mesh exports
including STL/3MF. Hierarchy and placements are preserved where the
profile includes them (one placement per export, one product per solid);
unsupported entities are explicit. No existing CAD kernel is used at
runtime; FreeCAD/OCCT/build123d appear only as oracle comparators in
E2E. Save/reopen never silently replaces analytic geometry with its
display mesh: the archive carries analytic curves and surfaces, and
`reopen -v` lists them per face.

## Laws and pins (A6)

Laws: `laws/c12/LAWS.bend`, proven in `laws/c12/PROOF.bend`. All 64
quantify over their inputs and pass both the checker and the Lean-proven
kernel (`bash tools/laws/check.sh`; MASTER_PLAN A6). Nine planted
mutants (one per family plus two regression) are all killed
(`python3 tools/laws/mutate.py c12`).

Pins: `tests/c12/pins.bend`, fixed-input checks run as compiled code
(`bash tools/pins/run.sh tests/c12/pins.bend`): archive round-trips,
writer entity text, reader recovery on hand-built STEP, STL facets, 3MF
model XML, CRC32 and zip layout.

## 1. Files

| File | Role |
|---|---|
| `src/c12/blob.bend` | B1 payload sections, canonical re-encode gate, `BCAD1` archive envelope (`ar_mk`/`ar_parse`), import measures |
| `src/c12/stepw.bend` | STEP writer: staged entities, mm SI units block, header/footer, multi-solid staging |
| `src/c12/stepr.bend` | STEP reader: tokenizer, entity parser, tables, recovery walks, staged refusals, `sr_file` entry |
| `src/c12/mesh.bend` | OBJ parse, ASCII STL, 3MF model XML, CRC32, store-mode OPC zip |
| `src/c06/cli.bend` | `step`, `archive`, `stl`, `3mf`, `geom step_import/reopen/step_of/stl_of/3mf_of` |
| `tools/mcp/bendcad-mcp.mjs` | Nine C12 tools with CLI-identical text |

## 2. Archive format (normative)

`BCAD1|mm|<lineage>|<B1 payload>`, 13 `|`-separated fields: version
tag, units, lineage, then the ten B1 sections
(`B1|counts|V|E|C|L|F|S|O|top`). `BCAD1` is semantic version 1 of the
archive; any other tag refuses with `archive-bad-version`. Units are
exactly `mm`, the kernel unit; anything else refuses with
`archive-units-not-supported`. Lineage is free text without `|` (empty
allowed). The B1 half must re-encode canonically: `pay_build` parses the
rows and refuses with `payload-not-canonical` unless the canonical
emitter reproduces the input byte for byte, so a hand-edited archive
that parses but is not canonical still refuses.

## 3. STEP profile (normative)

Schema shape: AP203 (`AUTOMOTIVE_DESIGN`), millimetre SI length unit,
radian plane-angle unit, steradian solid-angle unit. The writer emits
exactly this block after the staged entities; the reader accepts a
length unit only when it carries `.MILLI.` + `.METRE.` and refuses any
other length unit with `step-units-not-supported`. Absent units default
to mm (documented; matches OCCT behaviour).

Curves: `LINE`, `CIRCLE`, `TRIMMED_CURVE` over either, complex
`RATIONAL_B_SPLINE_CURVE` and `B_SPLINE_CURVE_WITH_KNOTS` instances only
when they are in rational-quadratic or cubic-bezier form (anything else
refuses with `step-spline-not-bezier-form`). Surfaces: `PLANE`,
`SPHERICAL_SURFACE`, `CYLINDRICAL_SURFACE`, `TOROIDAL_SURFACE`
(`CONICAL_SURFACE` refuses with `step-conical-surface-not-in-profile`;
Bezier-patch faces refuse with `step-bpatch-face-not-in-profile`).
Topology: `VERTEX_POINT`, `EDGE_CURVE`, `ORIENTED_EDGE`, `EDGE_LOOP`,
`FACE_BOUND`, `FACE_OUTER_BOUND`, `ADVANCED_FACE`, `CLOSED_SHELL`,
`MANIFOLD_SOLID_BREP`. `OPEN_SHELL` refuses with
`step-open-shell-not-in-profile`; `BREP_WITH_VOIDS` refuses with
`step-voids-not-in-profile`; vertex loops refuse with
`step-vertex-loop-not-in-profile`; assembly instances (`MAPPED_ITEM`)
refuse with `step-assembly-not-in-profile`. Coedge trims are trim-seg
only.
Solids are single-shell: the writer refuses cavities, and STEP expresses
no multi-shell solid. Faces carry same-sense plus loop ranks; shells
carry kind plus face ranks.

Entities outside this list (product/context/presentation/pcurve
scaffolding, typed-argument wrappers, unknown names) parse and are
skipped by kind, except at use sites: a face or edge that resolves to an
unsupported or missing definition fails loudly with the entity id
(`step-curve-not-in-profile #N`, `step-surface-not-in-profile #N`).
There is no silent substitution anywhere on the path.

## 4. Import bounds (normative)

Entity cap 100000 (`step-too-many-entities`), payload cap 2000000 chars
(`payload-too-large` / `archive-too-large`), record cap 500000 per
section (`payload-records-overflow`), archive sections exactly 13
(`archive-sections-count`, `archive-sections-overflow`). Every recursion
is fuel-first or structural on its input; recovery never searches
(ulp grids, snap rounds) — frames normalize directly, circles recover by
rational tan-half-angle, trims project planar or default to zero on
quadrics.

## 5. Mesh exports (normative)

STL is ASCII (`solid bendcad` … `endsolid bendcad`), facet normals are
normalized cross products (zero on degenerate facets), coordinates print
with round-trip `f_show`. 3MF is a store-mode (uncompressed) OPC zip
with `[Content_Types].xml`, `_rels/.rels`, and `3D/3dmodel.model` in
millimetres, written through `File.write_bytes`; CRC32 is the IEEE
bitwise algorithm. Both derive from the C10 tessellation of the node or
archive solid and are labelled sampled, not certified. Triangle budgets
refuse with `tess-budget-exceeded` before any byte is written.

## 6. Refusal catalog

Archive: `archive-bad-version`, `archive-units-not-supported`,
`archive-bad-envelope`, `archive-sections-count`,
`archive-sections-overflow`, `archive-too-large`,
plus the `payload-*` family from the B1 gate. Reader: `step-too-many-entities`,
`step-entity-parse-failed`, `step-sort-failed`, `step-duplicate-id`,
`step-units-not-supported`, `step-open-shell-not-in-profile`,
`step-no-solid`, `step-voids-not-in-profile`, `step-assembly-not-in-profile`,
`step-bad-vertex-point #N`, `step-bad-pole-vertex #N`, `step-edge-bad-vertex #N`,
`step-edge-bad-sense #N`, `step-edge-bad-curve #N`,
`step-line-recovery-failed #N`, `step-circle-recovery-failed #N`,
`step-trim-recovery-failed #N`, `step-spline-not-bezier-form #N`,
`step-wrapped-curve-failed #N`, `step-curve-not-in-profile #N`,
`step-face-bad-bounds #N`, `step-face-bad-sense #N`,
`step-face-bad-loop #N`, `step-vertex-loop-not-in-profile face #N`,
`step-face-failed #N`, `step-plane-recovery-failed #N`,
`step-sphere-recovery-failed #N`, `step-cylinder-recovery-failed #N`,
`step-torus-recovery-failed #N`, `step-surface-not-in-profile #N`,
`step-bpatch-face-not-in-profile`,
`step-conical-surface-not-in-profile`, `step-bound-bad-loop #N`,
`step-bound-in-two-faces #N`, `step-bound-without-face #N`,
`step-loop-failed #N`, `step-coedge-in-two-loops #N`,
`step-coedge-without-loop #N`, `step-coedge-trim-failed #N`,
`step-coedge-failed #N`, `step-bad-shell #N`, `step-bad-solid #N`.
Writer: the `step-*` B1 emission failures plus `payload-curve-not-in-profile`
and `payload-surface-not-in-profile` with the offending kind name.
Mesh: `mesh-bad-vertex`, `mesh-bad-face`, `mesh-empty`,
`mesh-index-out-of-range`, `tess-budget-exceeded`. Every refusal names
its stage; none publishes partial geometry.

## 7. Complexity and latency budgets

Entity sort O(n log n); table build and binary search O(n log n);
recovery walks O(n) with O(log n) lookups; row emission O(n); archive
and canonical gates O(n); CRC32 O(8n) bit ops; STL facet lookup O(log n)
per corner over the vertex table. Budgets: oracle box/hole/sphere/torus
imports under 30 s each; STEP export of a shoebox solid under 10 s;
STL/3MF of a preset-1 box under 60 s. Measured numbers land in the
receipt; a regression past budget blocks the packet.

## 8. Deferrals

Non-mm unit conversion (refused, not converted); STEP cavities (writer
refuses; STEP expresses no multi-shell solid); cone, Bezier-curve, and
general NURBS geometry (refused by name); deflate compression for 3MF
(store mode only); 3MF/STL import (exports only); binary STL (ASCII
only); assembly/product-structure round-trip beyond one product per
solid (C14 owns assemblies).
