# C10 intent — manufacturing-grade tessellation

Status: binding spec for this packet. Implementation, laws, tests, and
the receipt follow this file. `docs/c10-laws.md` is equally binding.
Scope authority: MASTER_PLAN §10 C10. Method authority: A2, §14, §15,
AGENTS.md.

MASTER_PLAN §10 C10 (verbatim): "Implement trim-aware meshing,
consistent shared-edge samples, normal/orientation handling, seam
treatment, and explicit LOD/quality controls. Bound error on the
delivered mesh after welding, simplification, transforms, and numeric
narrowing, not on an intermediate mesh that is later changed. C06
ships a display tessellator: watertight, oriented and sharing edge
samples, with no stated bounds (`docs/c06-contract.md` §10). C10
replaces it. Exit: valid indices, appropriate watertightness,
orientation, and stated chordal/angular bounds hold for the final
output. Sampled quality checks are labeled sampled, not certified.
Display tessellation and manufacturing export remain distinguishable."

## Laws and pins (A6, 2026-10-12)

Laws: `laws/c10/LAWS.bend`, proven in `laws/c10/PROOF.bend`. All 18 quantify over their
inputs and pass both the checker and the Lean-proven kernel (`bend
laws/c10/PROOF.bend --verdict`; MASTER_PLAN A6):

- `q_mk_chord / q_mk_angle / q_mk_max / q_mk_prof`: the quality
  constructor round-trips all four fields, for every input.
- `tres_ok_true / tres_fail_false`: success marks ok and a refusal
  marks failure, for every input.
- `prism_over_budget_refuses / prism_refusal_keeps_estimate /
  lathe_over_budget_refuses / lathe_refusal_keeps_estimate`: the
  production builders `pri_go` and `rev_go` refuse when the budget
  test fails and report the estimate, for every body, quality and
  estimate (L2).
- `strip_tri_count / strip_estimate_exact`: the side strip over two
  rings delivers exactly two triangles per paired sample, and the
  strip estimate `tri_est_strip(n)` is exactly that count, for every
  pair of index rings (L9).
- `ring_seq_len / ring_rep_len / ring_seq_in_range`: every lathe
  ring gets exactly n indices, and a ring based at b names only
  indices below b + n, for every n and b (L6).
- `segs_min_line / segs_min_rq / segs_min_bz`: open curves sample
  from one segment, for every curve and domain.

Pins: `tests/c10/pins.bend`, 42 fixed-input checks, run as compiled code
(`bash tools/pins/run.sh tests/c10/pins.bend`). Preset table bits,
profile tags, budget boundaries, estimator arithmetic, segment counts
on closed inputs, circle span and minimum-segment corners the laws
cannot decide. Where this contract names a closed law (an instance
with no quantified input), it names the pin of the same name: it is
pinned and executed, not proven. There is no `pins_build.bend`: the
e2e journeys pin exact mesh counts instead.

## 0. Decisions that keep the packet honest

C10 replaces the C06 display tessellator (amendment of
`docs/c06-contract.md` §10) but keeps its triangulation core: the
same indexed ear clipping with bridged holes, the same aligned wall
and band strips, the same shared lathe rings (quality-sized,
replacing the fixed 32-step grid), the same shared-edge `Ctx`. What is new is everything the plan asks to be stated: a
quality parameter, per-edge segment counts derived from it, a
pre-build estimate with a budget gate, and a sampled measurement on
the delivered mesh. Orientation handling is unchanged (`fix_go` over
Newell normals); the packet proves it still holds by checking every
edge of every closed journey mesh twice.

The delivered mesh is the sampled mesh. Nothing welds, simplifies,
or re-samples it afterwards; the placement applies once at emit and
is rigid, so chord and angle survive it. The bounds are therefore on
the final output, not on an intermediate.

Measurement is sampled, never certified: each sampled segment
contributes one midpoint chord probe against the true curve, each
sampled circle contributes its angle step. Lines and degenerate
cubics report exact zero. The reply line and the MCP reference say
"sampled, not certified" every time. No output of this packet is
called certified.

Estimate precedes build. The estimator overcounts by construction
(strips count two triangles per ring edge, fans count the ring plus
twice the hole count, lathes count two per ring per profile point),
so `est >= ntris` on every journey and the budget gate never admits
a mesh over budget. A refusal writes nothing and names the estimate,
the budget, and the fix.

Display and manufacturing stay distinguishable: the profile is a
field of the quality, printed on every reply. Presets 0–2 are
display; preset 3 is manufacturing. Overrides are explicit per
field; there is no silent numeric default.

Curve coverage is total over the closed `GVal` curve kinds. Lines
take no interior samples (exact). Circles take chord-plus-angle
samples over their real domain, three segments minimum when closed.
Rational beziers sample on the unit domain (the C06 convention all
builders follow). Cubic beziers in degenerate `Bz{a,a,b,b}` form
take no samples (they are exactly lines); true cubic curves sample
through `bez3_eval`. A shared edge shares one sample list on both
faces (prism `Ctx`, uniform lathe rings), which is what keeps the
mesh watertight.

Refusals follow the house shape. Bad quality is `invalid-input`
naming the field, with the offending preset echoed. A blown budget
is `refused tess-budget-exceeded` with estimate, budget, and fix. A
failed node keeps the old line. In every refusal the design file is
byte-identical and no mesh file appears.

Not in this packet: STL/3MF export (C12); certified error bounds
(they need C11 query machinery); adaptive subdivision past
chord-plus-angle; NURBS edges (no builder emits them).

## 1. Syntax

Same design file as C06–C09. The `tess` command grows trailing
quality arguments (cache tags untouched):

```text
tess NODE OUT [PRESET] [CHORD] [ANGLE] [MAXTRIS] [PROFILE]
```

`PRESET` is 0, 1, 2, or 3 (default 1). `CHORD` is millimetres, a
positive finite number. `ANGLE` is radians, a positive finite
number. `MAXTRIS` is a positive integer. `PROFILE` is `display` or
`manufacturing`. Each override replaces only its preset field; an
omitted field keeps the preset value.

```text
preset  chord  angle  max_tris   profile
0       2.0    0.4    10000000   display
1       1.0    0.2    10000000   display
2       0.25   0.05   10000000   display
3       0.05   0.01   10000000   manufacturing
```

MCP `tessellate` takes the same five optionals (`preset`, `chord`,
`angle`, `maxTris`, `profile`).

Replies, verbatim shapes:

```text
wrote OUT nverts N ntris M est E chord C ang A nsamp S profile P (sampled, not certified)
refused tess-budget-exceeded | tess @ node N | est E max M | fix: coarsen quality (preset 0, larger chord/angle) or raise max-tris
error invalid-input | tess | why: preset P needs 0..3 | fix: tess NODE OUT [0|1|2|3] [CHORD] [ANGLE] [MAXTRIS] [display|manufacturing]
error invalid-input | tess | why: chord needs a positive finite number | fix: give CHORD in millimetres, or omit it for the preset value
error invalid-input | tess | why: angle needs a positive finite number | fix: give ANGLE in radians, or omit it for the preset value
error invalid-input | tess | why: max-tris needs a positive integer | fix: give MAXTRIS, or omit it for the preset value
error invalid-input | tess | why: profile needs display or manufacturing | fix: give display or manufacturing, or omit it for the preset value
error: node failed; nothing tessellated
```

## 2. Quality model

`Q{chord, angle, max_tris, profile}` lives in `src/c10/mesh.bend`
with its constructor, accessors, presets, and validators (`q_ok`,
`q_prof_ok`). Segment counts per edge: length divided by chord plus
one, angle span divided by angle plus one, at least the open/closed
minimum (1, or 3 for a full circle), combined by maximum. Lengths
are control-hull upper bounds widened by one ulp-scale step, so a
count never under-samples its own rule.

The prism estimator counts per face over the shared rings: cylinder
walls count a two-per-edge strip, planar faces count the ring plus
twice the hole count. The lathe estimator counts two triangles per
ring per profile point. Both overcount; `est >= ntris` is asserted
on every journey.

Measurement walks the delivered sample lists: each curve segment
reports the distance from the true curve midpoint to the chord
midpoint; each circle reports its angle step; lines and degenerate
cubics report exact zero. The reply carries the maxima and the
segment count. Orientation is the C06 rule, unchanged.

## 3. Evaluator path

`TS.body_q` dispatches on revolve content: bodies without lathe
profiles go to `pri_q`, bodies with them to `rev_q`. Both estimate
first, gate on the budget, then emit a `Tres{ok, why, obj, nverts,
ntris, est, chord, ang, nsamp}`. The prism path builds one `Ctx`
over the whole B-rep so shared edges share samples, then runs the
unchanged `faces_tris`. The lathe path subdivides each profile by
quality, takes the uniform ring count as the maximum over the
profile (shared rings keep bands watertight), and emits bands plus
the sampled quality triple. The CLI parses quality, validates it
before touching the node result, and prints the `Tres`.

## 4. Complexity

Sampling, estimating, emitting, and measuring are each linear in
their input: edges and faces for the estimate, segments for the
mesh and the measurement. No stage is exponential and no stage
re-samples. Recorded tessellation times on this machine class: box
and cylinder presets under 0.01 s, revolve preset 3 (5,032
triangles) 0.05 s, shell cavity under 0.1 s. Tessellation cost is
reported separately from boolean cost (C08 §8).

## 5. Tests and laws

`tests/c10/e2e.py` copies the `tests/c09/e2e.py` harness
(`BENDCAD_BIN`, `fresh`, `record`) and writes
`tests/c10/e2e-report.json`. Every mesh journey parses the reply
line, re-reads the OBJ, and asserts valid indices, every edge in
exactly two triangles, the Euler characteristic, `est >= ntris`,
measured within requested bounds, and the exact counts:

- box default (8 verts, 12 tris, euler 2);
- cylinder default (64 verts, 124 tris, euler 2);
- cylinder presets 0, 2, 3 (60, 500, 2,512 tris; preset 3
  manufacturing);
- revolve default and preset 3 (256, 5,032 tris, euler 0);
- chord override (more tris than default, chord within 0.1) and
  manufacturing profile override;
- budget refusal (est 196, max 10, no file, design unchanged);
- replay (byte-identical meshes);
- triangle prism with slanted (degenerate-cubic) edges (6 verts,
  8 tris, euler 2, chord 0);
- D-profile prism with an arc (22 verts, 40 tris, euler 2);
- closed-box shell cavity (euler 4, two closed shells).

`tests/c10/neg.py` writes `neg-report.json`. One journey per
diagnosis in §1, asserted verbatim with the fix present, the mesh
file absent, and the design file unchanged: preset out of range,
preset garbage, zero/negative/garbage chord and angle, zero/garbage
max-tris, bad profile, failed node.

Pins (A6): `tests/c10/pins.bend`, 42 checks (preset bits, profile
tags, budget boundaries, estimator arithmetic, closed segment
counts, span corners). Laws in `laws/c10/` prove the constructor,
result, gate, and minimum-segment rules for every input. A law or
pin must fail on the old behavior it exists to forbid (a preset
table edit fails pins; an undercounting estimate fails every e2e
journey; a gate that builds past refusal fails the refusal journey).

## 6. Docs

`tools/mcp/language.md` documents the quality arguments, the reply
shapes, the sampled label, and the refusal. A C10 section goes into
`docs/replacement-ledger.md`. `docs/c06-contract.md` §10 is amended:
the display tessellator is replaced by this packet, its
triangulation core preserved. Do not edit `legacy/`.

README and MASTER_PLAN "Next is C10" flip to C10 closed / next is
C11 only after the check phase has a green e2e, a green neg suite,
green pins, and `tools/laws/check.sh` printing `ALL PROOFS CHECK`
for every law file. The receipt is
`docs/receipts/c10-2026-10-12.txt`, written from those runs, not
before them.

This packet also closes the C09.1 latency deferral: `shell.closed_box`
is re-measured under its 1 s budget (receipt §5), and the C08 D2
cases are re-measured with the fixed kernel. The deferral records
point at the receipt.

## 7. Bend rules for this tree

`Bool.pick` evaluates both arms. Use `match` to skip work. A match
scrutinee is a parameter or a field, never a computed call. Bind,
then match. In this tree the C08 boolean dispatch and the C07
`m2` rank are already `match`-dispatched so untaken arms never
evaluate (c10 receipt §1 and §5, replacement ledger C10). Do not
run `bend update`. Do not edit `legacy/`. Do not weaken a volume,
a diagnosis, or a law to go green. Do not commit or push.
