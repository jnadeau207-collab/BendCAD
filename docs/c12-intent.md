# C12 intent: interchange and durable identity

C12 is the packet where BendCAD stops being a closed modeller and
becomes a citizen of the CAD world: a versioned B-rep archive that
carries analytic geometry with lineage, a declared STEP read/write
profile with named refusals instead of silent substitution, and STL/3MF
mesh exports on the same CLI and MCP paths as everything else. An agent
can export a node, hand the file to any independent reader, reimport a
foreign file, and trust every answer because every answer is proven,
certified, estimated, or a named refusal.

## 1. Goal and non-goals

Goal: every line of MASTER_PLAN §10 C12 — archive, profile, mesh
exports, hierarchy/placements where the profile includes them, explicit
unsupported entities — with the exit proven by independent readers
(dimensions, units, orientation, holes, multiple solids, surfaces,
product structure), save/reopen fidelity for analytic geometry, and
bounded imports. Non-goals: unit conversion, cavities in STEP, cone and
general-NURBS geometry, compressed 3MF, mesh import, assemblies (see §8
and the contract §8).

## 2. Agent contract

```sh
bendcad d.bcd step 1 box.step
bendcad d.bcd archive 1 box.bca 'shoebox demo'
bendcad d.bcd stl 1 box.stl 1
bendcad d.bcd 3mf 1 box.3mf 1
bendcad geom step_import /tmp/oracle_box.step box.bca
bendcad geom reopen box.bca -v
bendcad geom step_of box.bca box2.step
bendcad geom stl_of box.bca box.stl 1
bendcad geom 3mf_of box.bca box.3mf 1
```

Export verbs read `design node out [quality…]` and print one `wrote`
line with entity/triangle counts. `step_import` prints an `imported`
line with the same measures `eval` prints, and optionally saves the
archive. `reopen` prints units, lineage, and measures; `-v` adds the
face list with analytic surface types, which is the standing proof that
reopen did not substitute a mesh. The MCP tools `step_export`,
`step_import`, `archive`, `reopen`, `step_of`, `stl_export`, `stl_of`,
`threemf_export`, `threemf_of` run the same verbs and return the same
text.

## 3. Architecture

```
src/c12/blob.bend    B1 rows + canonical gate + BCAD1 envelope + measures
src/c12/stepw.bend   STEP writer: stages, units block, header/footer
src/c12/stepr.bend   STEP reader: scan, tables, recovery, staged gates
src/c12/mesh.bend    OBJ parse, STL text, 3MF XML, CRC32, zip bytes
```

`blob` is the interchange kernel: every format funnels through B1 rows,
and the canonical re-encode gate (`pay_build`) refuses anything that
parses but is not canonical. The writer stages entities per brep with
continued ids and appends the mm SI block; multi-solid staging chains
breps with one product each. The reader runs one tolerant pass — scan,
sort, dedupe, table, then vertex/edge/face/loop/coedge/shell/solid
walks — and each stage refuses by name with the entity id. The mesh
module parses the C10 tessellation output (never the B-rep directly, so
mesh exports cannot disagree with `tess`) and emits text or zip bytes.

## 4. Status vocabulary

`wrote` lines carry counts. Mesh lines add `(sampled, not certified)`,
inheriting the tessellation's honest status. Import and reopen lines
reuse the `ok … | volume=…` vocabulary of `eval`, including the proof
field when the import carries one. Refusals start with `refused` or
`error`, name the packet reason (`step-*`, `archive-*`, `payload-*`,
`mesh-*`, `tess-budget-exceeded`), and say how to fix it. There is no
estimated geometry on the interchange paths: an import either validates
fully (including the C04 manifold certificate through `op_blob`) or
refuses.

## 5. Methods

Recovery is direct, never search: placement frames normalize in place,
circle frames orthonormalize by Gram subtraction, circle parameters
recover by rational tan-half-angle, line trims project planar onto the
recovered axis, quadric trims default to zero (documented; quadric
coedge parameters are display-only in this profile). Rational and bezier
curves recover only exact quadratic-rational and cubic-bezier knot
vectors; everything else refuses by name. Degenerate edges, seam edges,
pcurves, and surface curves are refused or skipped per the contract —
never guessed.

The 3MF writer hand-rolls a store-mode zip because the kernel's text IO
is UTF-8: fixed XML parts plus the model XML go through `File.write_bytes`
with a bitwise IEEE CRC32. Store mode is valid OPC; readers accept it
(E2E proves it with an independent reader).

## 6. Refusals

§6 of the contract lists all 60+ reasons. Each names its stage and
carries the entity id where one exists. A failed node publishes no file:
each export verb has its own nothing-exported sentence. Refusal dispatch
uses `match` (lazy); `Bool.pick` evaluates both arms and is never a
guard. Failure never publishes partial geometry: writers assemble the
whole string before the single `write_file`/`write_bytes` call.

## 7. Complexity and latency

Contract §7 states the bounds (sorts O(n log n), walks O(n), CRC O(8n),
facet lookup O(log n)) and the budgets. Measured numbers land in the
receipt.

## 8. Bend rules this packet learned

String-literal `case` patterns work and kill whole tokenizer states —
but a variable matches only before any later binder does, so match the
earlier binder first. `Bool.pick` on lists selects results without
matching, which breaks mutual-recursion cycles at O(n²) on tiny inputs.
`File.write_bytes` takes `List U32` and is the only binary path. List
literals and `<>` chains need annotated helpers (`sr_tp2`, `mo_l2`) or
inference fails. Fuel-first recursion with the counter after the fuel
satisfies termination left-to-right. `U32.from_nat` bridges Nat indices
into `B.tb_get`.

## 9. Evidence map

- `laws/c12/LAWS.bend`, `laws/c12/PROOF.bend`: 64 laws over envelope
  gates, classifier totality, staging counts, refusal closure, section
  scan, mesh gates, and structure; see `docs/c12-laws.md`.
- `tests/c12/pins.bend`: fixed-input pins over archives, writer text,
  reader recovery, STL, 3MF XML, CRC, and zip layout.
- `tests/c12/e2e.py`, `tests/c12/neg.py`: oracle-validated journeys
  (build123d/OCCT read our STEP; trimesh reads our STL/3MF), oracle
  imports, save/reopen fidelity, MCP parity, and refusal journeys.
- `docs/receipts/c12-2026-10-13.txt`: the A2 exit matrix with measured
  evidence.

## 10. Deferrals

See contract §8: unit conversion, STEP cavities, cone/NURBS geometry,
deflate 3MF, mesh import, binary STL, assembly round-trip.

## 11. Reproduction

Rebuild the binary with the packet's two-stage recipe (see the receipt
§1), then:

```sh
python3 tests/c12/e2e.py
python3 tests/c12/neg.py
bash tools/pins/run.sh tests/c12/pins.bend
bash tools/laws/check.sh /tmp/laws-c12
python3 tools/laws/mutate.py c12
```
