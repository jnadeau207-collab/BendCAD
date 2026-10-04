# C06 contract — intent-checked solid builders over C00–C05

Scope: the C06 layer builds valid `C04.Brep` solids from operator
graphs, diagnoses failures by pipeline stage, checks quadric trim
points, measures boxes, and publishes results through an intent
gate. One value union, one result type: every fallible C06 op
returns `SRes` (`src/c06/types.bend`).

Files:

- `src/c06/types.bend` — `Diag`/`SRes`/`SVal`, `Body`, `Measure`,
  `Op`/`Param`/`Node`/`Part`, `Built`/`Cache`, `Nm`, profile and
  interval types.
- `src/c06/surfx.bend` — trig-free quadric frames and evaluators
  (cylinder/cone/torus/sphere) used by later builders.
- `src/c06/ops.bend` — profile validator, box builder, staged
  diagnosis.
- `src/c06/eval.bend` — op-graph eval, build hashing, memo cache,
  publish gate, lineage names.

## 1. Result protocol

`SRes = Sok{SVal} | Serr{FailKind, Diag}` with
`Diag{what, loc, why, fix}`. The `FailKind` mapping is fixed:

- `F_invalid` ("invalid-input") — malformed caller input rejected up
  front: non-finite coordinates, non-positive dims, unknown dim id,
  unknown root id, intent/effect mismatch, bad profile.
- `F_uncertain` ("numerical-uncertainty") — representability failure
  at a gate: `corner+dim` overflow, or a build that fails
  `brep_checked` for numerical reasons. Never snapped; the inputs
  are reported, not rounded into validity.
- `F_unsupported` ("unsupported-op") — well-formed requests whose
  builder does not exist yet (all non-box ops, §7).

## 2. Profile validator (`prof_code`)

`prof_code(loop, holes, fuel) -> U64` classifies a 2D profile:
`0` valid; `1–24` the first defect found (open loop, self-touch,
wrong winding, hole outside/overlap, …). Pins: unit square `0`,
bowtie `4`, clockwise square `5`. `pip(x, y, loop, fuel)` returns
`0` outside / `1` inside / `2` on-edge. Predicates are exact
(`P2.orient2d`, `Ex` expansions); tangent contact reports on-edge,
never inside/outside.

## 3. Box builder (`box_checked`)

`box_checked(x0, y0, z0, dx, dy, dz, fuel) -> SRes` validates
(finite inputs, strictly positive dims, finite far corner) then
assembles 8 vertices, 12 edges, 24 coedges, 6 loops, 6 faces,
1 shell, 1 solid through the `C04` push API and runs the full
`brep_checked` pipeline. Push order fixes handle gens positionally
(1–8 vertices, 9–20 edges, 21–44 coedges, 45–50 loops, 51–56
faces, 57 shell, 58 solid).

Exactness (§4 of the old notes, kept here): C04 coincidence is
bit-exact (`F64.is_eq`), and `fl(a + fl(b - a)) == b` is FALSE in
general (counterexample `a=97398.60767117864`,
`b=-971916.5996719621`, found by search). The builder is exact on
ALL validated inputs by identical computation instead:

- vertices are single `F64.add`s of corner+dim;
- every edge eval replays the identical add (edges run min→max
  with `d = +dim` over `dom [0,1]`, so `eval(1)` is the same add);
- plane evals replay the identical add per axis;
- trims are in edge (`v0→v1`) order with coordinates in
  `{0, ±dim}` (negation is exact).

No rounding analysis is needed: each check compares two runs of
the same op sequence. Non-dyadic inputs (`0.1…0.6`), negative
corners, and the FP-adversarial coordinates above all build `ok`;
`1e308+1e308` is rejected `uncertain` before any push runs.

## 4. Staged diagnosis (`bulk_a` / `bulk_c` / `diag_brep`)

`bulk_c` runs `brep_checked`; on `Terr` it re-runs the per-stage
checks (`brep_incid_c` … `brep_orient_c`, stages B–L) and reports
the first failing stage through `stage_ex` with a fix hint.
Stage-A (attribution) failures name the failing store walk via
`att_tag`/`att_go` (tags 1–21, one per store × all/gen/nodup).
Fuel exhaustion reports `100+stage` (undecided), never success.

## 5. Op-graph eval (`ev_part`)

`ev_part(part, old_cache, fuel) -> EvRes{cc, last}` evaluates
nodes in list order (caller-topological), fail-fast: the first
node error halts the walk with that error. `Part` carries the
intent declared before the build. Node build hashes are FNV-1
over the op tag, the op's dim ids, the bits of `nom`, `lo`, and
`hi` for each of those dims (`F64.bits`), any input node id
embedded in the op, and `Node.ins`, in that order. The B-rep is
the nominal solid. A present
dim whose zone fails `lo <= nom <= hi` with `lo > 0` is
`invalid-input` and does not build. `ms_zone` certifies the
volume as the outward product of the three `[lo, hi]` intervals.
`ms_nom_vol` is the nominal-point product; those two disagree
when a zone is wider than its nominal.

Cache reuse is all-or-nothing. If every node hash matches the
old cache and every op is a box, the cache is reused and the
root is looked up. Publish then runs `gate_publish` on the
stored effect and the part intent: agreement returns the body,
a mismatch is `invalid-input` and does not return the body.
A cache whose hashes match but whose op is not a box is not
reused; the walk calls `ev_op` and returns `unsupported-op`.
Otherwise every node rebuilds. Per-node partial reuse is future
work. `O_box` resolves three dim ids to nominals and builds at
the origin; every other op returns `unsupported-op` naming the
pending builder. Unknown dim ids and unknown root ids are
`invalid-input`.

`gate_publish(fx, intent)` compares all five effect fields
(`mat/fc/fm/shells/holes`). `ev_part` calls it on every publish
of a root body, including a cache hit. A direct call still
returns `SV_fx` on agreement and `invalid-input` on a mismatch.
`box_names(node)` issues the 26 lineage names (6 faces role 0,
12 edges role 1, 8 vertices role 2) under the creator node id.

## 6. Bend-linearity rules this layer follows

Bend matches only on params and match binders — never on
let-bound computed values ("give the value its own def") — with
at most two scrutinees, no mutual recursion, and nested matches
only on binders of the immediately enclosing single match.
Consequences used throughout: decisions computed in argument
position and matched as callee params (the `base/par.bend`
`tr_set` pattern); `Bool.pick` over aggregates for branches on
computed values inside a self-recursive walk (see `evm`, with the
shared result evaluated once); single syntactic use per match
binder unless `+`-annotated; leaf-first definition order.

## 7. Pending scope (explicitly not built)

Primitive builders (`cyl`/`sph`/`cone`/`tor`), general
profile extrude/revolve, hole/pocket/pad surgery, `xform`,
forest compounds and merge restamping, and per-node partial
cache reuse. All fail closed through `unsupported-op` or
`invalid-input` today; no stub returns success. A cache hit
does not turn an unsupported op into success. `join_specs` is
kept for a later compound and has no caller. The box path that
runs is `box_checked` then `bulk_c`. Partial reuse is future
work; a full-hash hit is not the same body once an input id,
dim id, or zone bound (`nom`, `lo`, or `hi`) changes.

## 8. Box measure (`ms_box`)

`ms_box(dx, dy, dz, x0, y0, z0, brep) -> SRes` returns `SV_ms`
with certified volume/area intervals over the dims
(`vol=(dx*dy)*dz`, `area=2*(xy+yz+zx)`, outward-rounded, so
each encloses the true real), exact bbox corners replaying
`box_core`'s adds, and entity counts from the brep. Non-finite
or non-positive inputs are `invalid-input`, and a non-finite
corner sum is `uncertain`, the same three gates as
`box_checked` (`box_fin`, `box_pos`, `box_sum_fin`). Enclosure
overflow is also `uncertain`. The
`1×2×3` pins (`vol=[6-2ulp,6+3ulp]`,
`area=[22-3ulp,22+4ulp]`, bits in laws §S) straddle the exact
values, verified independently in Python.

## 9. Quad-trim check (`trim_quad`)

`trim_quad(s, u, v) -> SRes` evaluates a parametric point on a
quadric surface through `surfx.surf_at` and requires a finite
point. Non-quad surfaces are `invalid-input` (`not-quad`; the
C04 stages own plane/bezier trims); G-layer failures keep
their kind (`invalid` for domain/radii violations,
`uncertain` for `gate_pt` overflow); non-finite points are
`uncertain`, never snapped. Success is `sok_u(0)`, the
`prof_go` convention.
