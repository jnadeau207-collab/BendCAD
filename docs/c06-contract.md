# C06 contract — first complete solid-building path, with A0

Scope (MASTER_PLAN §10 C06, §16, §17): primitives, extrusion,
revolution, pad/pocket, holes and placement over C00–C05; multiple
profile regions, axis crossings and degenerate input handled
explicitly; a measured intent check on every operation; the design
model with parameters, tolerance zones and memoized rebuild on edit;
and A0, the agent surface (MCP primary, CLI, Bend library). Exit G1
passed (§12). No existing CAD kernel is used at runtime.

This contract replaces the 2026-10-03 C06 (`types`/`ops`/`eval`: a
box-only builder with a staged diagnosis). Those modules, their
suites and their laws were removed; the R0.4 repairs that lived in
them (full-key cache, fail-fast evaluation, exact clearance, duplicate
ids) are restated against the new code in §11.

## 1. Files

| File | Role |
|---|---|
| `src/c06/xp.bend` | Parameter expressions `Xp` (`k`, `p`, `+ - * /`, negation), evaluation against an `Env` tree, missing-parameter detection, key words for cache keys |
| `src/c06/prof.bend` | Profiles: `Seg` (line, arc), `Loop` (path, circle), `Region` (outer + holes); evaluation into exact pieces, every validity check, cell roles |
| `src/c06/build.bend` | Laminar column model → C04 B-rep in one bulk construction |
| `src/c06/revolve.bend` | Full-turn revolution about z → C04 B-rep with plane, cylinder, cone, sphere and torus faces |
| `src/c06/iv.bend` | Outward-rounded interval arithmetic (add, sub, mul, div, square, sqrt, π, `atan2`, `sin_cos_deg`) for certified measures and placements |
| `src/c06/model.bend` | Ops, design model, per-op builders, measures, effects, intent gate, evaluator with cache |
| `src/c06/sx.bend` | S-expression reader/printer; the design file format; decimal reader |
| `src/c06/tess.bend`, `src/c06/ear.bend` | Tessellation (OBJ), indexed ear clipping with hole bridging |
| `src/c06/zone.bend` | Measures certified over the tolerance envelope (§10a) |
| `src/c06/cli.bend` | The `bendcad` CLI |
| `src/c06/surfx.bend` | Quadric frames and evaluators (unchanged from R0.4; C07 prerequisite) |
| `tools/mcp/bendcad-mcp.mjs`, `tools/mcp/language.md` | MCP server (stdio JSON-RPC) and the agent's language reference |
| `tools/grade/mesh.py`, `tools/grade/g1.py` | Independent graders (watertightness, Euler characteristic, signed volume; G1 rubric) |
| `tests/c06/e2e.py` | End-to-end journeys (§12) |

## 2. Design model

A design is parameters and nodes. `Param{id, name, nominal, lo, hi}`
carries a tolerance zone; `(param W 120 119.9 120.1)`. An edit is
rejected unless all three are finite and `LO <= NOM <= HI`. A node is
`Nd{id, op, intent}`; a node may reference only nodes listed before
it. Expressions evaluate in F64 against the parameter tree; an
unknown name is diagnosed (`unknown-parameter`), never defaulted.
Duplicate node or parameter ids are rejected.

Ops (`model.bend` `Op`):

| Op | Syntax | Body |
|---|---|---|
| `O_box` | `(box X Y Z)` | prism over `[0,X]×[0,Y]`, `z ∈ [0,Z]` |
| `O_cyl` | `(cylinder R H)` | circle radius `R` at the origin, `z ∈ [0,H]` |
| `O_prism` | `(prism Z0 Z1 REGION ...)` | extrusion of any number of regions |
| `O_pad` | `(pad BASE FACE H REGION ...)` | add material outward from a top/bottom face |
| `O_pocket` | `(pocket BASE FACE D\|through REGION ...)` | remove to a flat floor or through |
| `O_holes` | `(holes BASE FACE D\|through (hole X Y R) ...)` | round holes, blind or through |
| `O_move` | `(move BASE DX DY DZ TURN)` | placement: translation and one of six quarter-turn rotations |
| `O_rot` | `(rotate BASE x\|y\|z DEG)` | placement: rotation by any angle about a world axis |
| `O_revolve` | `(revolve REGION ...)` | full turn about z; profile `x` = radius, `y` = height |
| `O_cone`, `O_sph`, `O_tor` | `(cone R H)`, `(sphere R)`, `(torus R r)` | revolve primitives |

`FACE` is `(face NODE CELL top|bottom)`. Features act along the body's
own z axis; a moved or rotated body keeps its cells and placement, so
features on it are built in its frame and placed afterwards. An
unknown op name is `unknown-op`.

Placement semantics: a body is its validated local B-rep plus a rigid
motion. Each `rotate` is the exact rotation by the requested angle.
`sin_cos_deg` reduces the angle by quarter turns and then certifies cosine
and sine by Taylor series with a remainder bound, in outward-rounded
intervals; multiples of 90° are exact. The placement carries the composed
rotation and translation as interval entries, and composition keeps
entries exact when the products and sums are (FMA residual and Fast2Sum
checks). Volume and area are invariant. The bounding box is the local box
mapped exactly when the rotation is a signed permutation. Otherwise it is
a geometry-aware certified enclosure:

- vertices map through the interval rotation;
- horizontal circles use the exact ellipse extent `r·sqrt(m_i0² + m_i1²)`;
- revolved arcs use the torus extent;
- arcs in profiles use their full circle.

The result is tight for boxes, cylinders, spheres and tori and encloses
profiles with arcs. Tessellation applies the midpoint matrix (display
only). Rejections: `bad-axis-or-angle` for an unknown axis or a
nonfinite angle with |angle| > 10⁶.

## 3. Profiles (`prof.bend`)

Lines and arcs; an arc is `(arc CX CY R X Y ccw|cw)` from the current
point. Evaluation splits every arc at its quadrant axis points so each
piece is monotone in x and y; circles stay whole. Arc endpoints must
lie on their circle to certified rounding (A4): an endpoint passes
when exact arithmetic shows `|p−c|² − R²` changes sign across its
one-ulp box. Every check below is exact (Shewchuk expansions via
`src/base/ex.bend`) or certified; none uses a tolerance.

`prof_check` returns `CK_ok{loops, parents}` or the first defect with
a stable code. Codes 1–19 are profile/feature codes, 20–24 revolve
codes (`pe_why`/`pe_fix` give the reason and the repair):

| Code | Reason | Code | Reason |
|---|---|---|---|
| 1 | nonfinite-coordinate | 13 | holes-nested |
| 2 | zero-length-segment | 14 | regions-overlap |
| 3 | nonpositive-radius | 15 | clearance-not-certified |
| 4 | arc-start-off-circle | 16 | arc-split-point-not-certified |
| 5 | arc-end-off-circle | 17 | unknown-parameter |
| 6 | arc-endpoints-same-direction | 18 | footprint-outside-face |
| 7 | loop-encloses-no-area | 19 | footprint-contains-or-meets-existing-feature |
| 8 | repeated-point | 20 | profile-crosses-revolve-axis |
| 9 | curves-cross-or-touch | 21 | hole-touches-revolve-axis |
| 10 | adjacent-segments-overlap | 22 | axis-pinch |
| 11 | orientation-uncertain | 23 | consecutive-axis-segments |
| 12 | hole-outside-outer | 24 | surface-not-representable |

Simplicity and loop-pair tests run on sweep candidate pairs (sorted
bounding boxes), not all pairs. Orientation comes from exact area
bounds; clockwise input is normalized, never rejected. Regions may be
islands inside another region's hole; their nesting gives each loop a
role (`K_free`, `K_hole`, `K_in`, `K_root`, `K_obst`).

## 4. Extruded solids (`build.bend`)

Every extruded body is a laminar column model: a forest of cells, each
a loop with a material interval `[lo, hi]`, nested by containment.
Pads add cells, pockets and holes add empty cells inside the face's
cell, and every result is rebuilt from cells, never patched. Walls are
the symmetric difference of a cell's interval with its parent's; top
and bottom faces carry the child loops that pierce them. Edge
geometry: axis-parallel lines are exact `Ln`; slanted lines are
`Bez3(A,A,B,B)` with flat bicubic walls; arcs are rational quadratic
pieces; circles are closed `Circle3` edges with cylinder walls.

The B-rep is built in one bulk construction: entities are created with
their final generations (`gen = idx + 1`), so building `n` entities is
`O(n log n)`. This closes R0's C04 `push`-is-`O(n)` item (F13). Every
result goes through C04 `brep_checked` before publication; a build
that fails it is `numerical-uncertainty`, never repaired.

## 5. Revolved solids (`revolve.bend`)

A region is turned once about z. Each profile segment yields two
half-faces (upper and lower), so there are no seam edges and no poles;
circles appear only at segment junctions. Lines map to planes,
cylinders and cones; arcs to spheres or tori. A cone's apex and slope
are certified by an ulp search. Holes become cavity shells.
Axis handling is explicit: a profile on the axis may run along it,
crossing it is code 20, a hole touching it 21, a pinch 22, two
consecutive axis segments 23, and a surface the C03 arms cannot carry
exactly 24. Pads, pockets and holes on a revolved body are
`unsupported-op` (`features-need-an-extruded-body`); they belong to
C08/C09.

## 6. Measures

Volume and area are certified intervals, not estimates: prisms by
exact-piece integrals in outward-rounded interval arithmetic
(certified `atan` by series with double reduction for arc sectors),
revolved bodies by Pappus over the same pieces. The bounding box and
the linear uncertainty (max one ulp of the largest coordinate on a
curved face) are reported with them. Genus is the Euler–Poincaré
count over shells. Every E2E and law volume check asserts that the
exact closed-form value lies inside the interval (§12).

## 7. Effects and the intent gate

`(intent MATERIAL FACES_CREATED FACES_MODIFIED SOLIDS THROUGH_HOLES)`;
any field may be `any`. The effect is measured from the result, never
taken from the op kind: material by comparing the certified volume
intervals of input and output (`add`, `remove`, `same`, `create`),
faces created and modified by lineage names and face signatures,
solids and genus from the B-rep. A mismatch rejects the node with
both the declared and the measured effect.

## 8. Evaluation, cache, transactions

`ev_part(part, old)` evaluates nodes in order. A node's key is its op,
its evaluated expression words and the keys of its inputs; an entry is
reused only when the full key matches (no hash trust, R0.4). Editing a
parameter rebuilds exactly the nodes whose keys changed; law
`cache_partial` pins reuse `[T, T, T, F]` when only the last node
changes. A failed input fails its dependents
(`input-node-missing-or-failed`). `apply` is atomic: edits are applied
to a copy, the whole part is evaluated, and the file is written only
if every node is valid and meets its intent.

## 9. Durable names, sensitivities, serialization

Faces are named `nN.cK.top`, `nN.cK.bottom` and `nN.cK.wall.I.J`
(segment `I` of cell `K`, wall interval `J`); names depend on the
graph, not on parameter values. `sens P N` estimates derivatives of
volume, area and bounding box by a central difference with
`h = max(|P|, 1)·2⁻²⁰`, and refuses when either side changes topology
or fails. The design file is `(bendcad 1)` followed by params and
nodes; floats print as shortest decimal when that reads back to the
same bits, otherwise `b:<bits>`. Reading uses the exact decimal fast
path (mantissa ≤ 2⁵³, power of ten ≤ 22, one correctly rounded
operation; otherwise `F64.read`), bit-identical to `F64.read` and
reducible by the checker. Reopening and rewriting is byte-stable
(E2E `bracket.serialize_stable`).

## 10. A0: CLI, MCP, library

CLI: `bendcad FILE new|show|eval|faces N|measure N|sens P N|zone N|apply EDIT...|tess N OUT`.
Failures print `error KIND | what @ where | why: … | fix: …` with
`KIND` one of `invalid-input`, `numerical-uncertainty`,
`unsupported-op`. MCP (`tools/mcp/bendcad-mcp.mjs`): tools
`reference`, `new_design`, `apply`, `show`, `evaluate`, `measure`,
`faces`, `sensitivity`, `zone`, `tessellate`; a rejected apply returns
`isError`. `apply` takes an array of edits or one string holding
several. The Bend library is the modules above
(`M.ev_part`, `S.part_of`, `S.part_show`, `T.body_obj`).

Tessellation writes a watertight OBJ: shared samples per edge, planar
faces by indexed ear clipping (point grid, candidate stack, bridged
holes), walls and bands as aligned strips, revolved bodies on a
32-step lathe grid. Manufacturing-grade tessellation (chordal and
angular bounds) is C10.

## 10a. Tolerance envelope (`zone.bend`)

`zone(part, N)` evaluates every parameter expression over its
`[lo, hi]` zone in outward-rounded interval arithmetic and returns
volume and area intervals that hold for every parameter assignment in
the envelope. It certifies only where topology provably cannot change
across the envelope. Box, cylinder, cone, sphere and torus qualify when
every dimension interval is certified positive and, for the torus,
`R − r` is certified positive. A move keeps its base's measures.
Results:

- `dimension-not-certified-positive-over-zone` (`invalid-input`) when a
  dimension can reach zero or below anywhere in the envelope.
- `zone-not-ordered` (`invalid-input`) when a stored zone violates
  `lo <= nom <= hi`.
- `envelope-topology-not-certified` (`unsupported-op`) for profiles and
  features, which need a topology-constancy certificate over parameter
  boxes. That certificate is C07 work (MASTER_PLAN A5).

This replaces and extends the box-only `ms_zone` of the 2026-10-03 C06.

## 11. R0.4 repairs restated

- Cache: full-key match (`M.keq`), law `cache_partial`.
- Fail-fast evaluation: one recursive call per node; a failed node
  stops its dependents (`ev_bad_input_node`).
- Duplicate ids rejected (`ev_dup_ids`).
- Exact clearance: hole/feature clearance compares exact expansions
  of coordinate differences; failures to certify are code 15, never
  passes.
- Surface evaluators: `surfx.bend` unchanged, its 47 laws kept.

## 12. Evidence

- Laws: 102 in two files.
  - `laws/c06.bend` has 77: 47 `surfx`, plus expressions, arcs, the
    twelve profile codes, revolve-axis and missing-input verdicts, the
    tolerance envelope, certified sine/cosine, placement exactness and
    unknown ops. It is checked as one file.
  - `laws/c06_build.bend` has 25 that each run a full evaluation (parse,
    build, C04 `brep_checked`, certified measures, effects) inside the
    normalizer: verdict strings for every op family and rejection,
    volume containment, cache reuse and ear clipping. Each costs 10–45
    minutes there (soft-float B-rep validation), so the file is checked
    one law per process in parallel, on the same pinned compiler and
    snapshot.
  - Profile and evaluator laws parse real design text. They reduce
    because the decimal reader is checker-evaluable.
  - Each zone, trigonometry and placement law fails on a mutant that
    breaks the property it pins. Profile and evaluator laws parse real design text; they
  reduce because the decimal reader is checker-evaluable.
- E2E `tests/c06/e2e.py` → `tests/c06/e2e-report.json` and
  `tests/c06/e2e-meshes/`: bracket build/reopen/serialize/sensitivity
  (and cache reuse inside it)/faces/edit/mesh/delete, five primitives with meshes, revolve cavity,
  counterbore, island, quarter-turn placement, general rotations
  (tight boxes for box/cylinder/torus/sphere, enclosure for arcs,
  features on rotated bodies, mesh inside the certified box), seven
  atomic rejections (file unchanged), tolerance-envelope queries and
  rejected zones, an MCP JSON-RPC session, and performance budgets.
  Every volume check requires the closed-form value inside the
  certified interval; every mesh is checked by `tools/grade/mesh.py`
  (watertight, Euler characteristic, signed volume).
- G1: `docs/receipts/g1/`, five passing runs by fresh agents over two
  briefs.

Performance (native, one thread, this machine): bracket build 0.12 s;
100 through holes build 0.11 s, tessellate 1.6 s; 400 holes 0.26 s and
9.7 s; 1,600 holes build 0.84 s, tessellate 59 s.

## 13. Limits and owners

- Booleans between solids, features on revolved bodies, fillets and
  chamfers: C08/C09.
- General curve/surface intersection, self-intersection beyond the
  profile checks: C07.
- Tessellation quality bounds and batch evaluation: C10. Tessellation
  is the slow path at scale (59 s for 1,600 holes).
- Partial revolution (angle < 360°): C09.
