# G3 receipt — two-stage spur gearbox (2026-10-14)

Rung G3 of the challenge ladder (MASTER_PLAN §18): "Two-stage gearbox:
gears, shafts, bearings, housing, seals, certified stack-ups", needing
C14 and C15. Brief: `brief.md`; gear profile helper: `gear.py` (numbers
only; every solid is built by BendCAD). Each run is a fresh
general-purpose subagent with no prior context, driving BendCAD only
through its MCP server via `tools/mcp/mcpc.mjs`; every call is logged in
the run's `calls.jsonl`.

Verdict: **G3 run, not passed.** The gearbox is built, assembled with
every mate solved (dof 0), interference-free by every independent check,
its stack-ups are certified, and every part exports as STEP and STL.
What BendCAD cannot yet do is *certify* that two meshing gears are
disjoint or bound their clearance away from zero: interlocking tooth
flanks defeat the C11 face-box method (§3). The rung's "required
clearances certified" is therefore not met, and the ladder records it.

## 1. Runs

- **Run 1** (binary 1d8a4a6e…, C15 close): 18 parts, assembly solved
  only after the agent worked around a solver defect (§2.2) with world
  `axis`/`plane` mates; all 72 exports written. Its four gear STEP files
  were unreadable by any other reader (§2.1).
- **Run 2** (binary 24d6861e…, both fixes in): 18 parts, 21 mates, the
  assembly a natural mate graph (plates stacked by `coinc`, shafts by
  `axis`+`plane`, gears and bearings `coinc`ed to their shafts):
  `asm solved ninst 18 nmates 21 dof 0 max-residual 4.26e-14`, no
  redundant mates. Every intent accepted as first declared. Report:
  `run2/report.md`.

## 2. Kernel defects found and fixed

1. **STEP writer, B-spline surfaces (C12).** `src/c12/stepw.bend` wrote
   `B_SPLINE_SURFACE_WITH_KNOTS` with `.POLYNOMIAL.` in the
   self-intersect slot and the knot lists in the wrong order
   (`(4,4),(0.,1.),(4,4),(0.,1.)` instead of `(4,4),(4,4),(0.,1.),(0.,1.)`).
   Every slanted prism wall is a Bezier patch, so every gear face but the
   caps and bore was dropped by an independent reader, which then saw no
   solid. C12's oracle journeys only exported analytic solids and
   BendCAD's own reader refuses patch faces, so nothing caught it. Fixed;
   new journey `tests/c12/e2e.py` `step.slanted` (a triangular prism)
   fails on the old binary (oracle: 0 solids) and passes on the fix
   (1 solid, volume 500).
2. **Assembly solve above 16 unknowns (C14).** `asm_rank` in
   `src/c14/asm.bend` passed C05's nested-dissection tree to the sparse
   least-squares solve without permuting columns into that order (C05's
   own solver does, via `lsq_rows`/`gather`). Up to 16 columns the tree
   is one dense leaf and order does not matter; above that the blocks get
   the wrong columns and a consistent mate set reports `conflict`. Fixed
   by permuting rows and gathering the solution exactly as C05 does; the
   now-unused `lsq_of`, its law and two pins are removed and a pin of the
   new permutation is added. New journey `solve.chain_large` (7
   instances, chained `coinc` mates) fails on the old binary (`conflict`,
   residual 13.3) and solves exactly on the fix.

Both fixes pass every gate on the fixed binary: laws (all packets) under
`--check-only` and `--verdict`, mutants 81/81, pins (c14 163/163), and
every suite (c12 e2e 17/17, c14 e2e 16/16, all others unchanged).

## 3. What is certified, and what is not

- Certified: every part's volume interval; `zone` over the H and F
  tolerance envelopes; the assembly solution (exact linear solve, dof 0);
  gear 1 vs the wall frame `disjoint`; point classifications on the line
  of centres (pinion tooth inside the pinion, outside the gear); the PMI
  `check` (flatness conforms) and the axial-gap stack-up, envelope
  [39.65, 40.35] and per state (cold 1, hot 1.001).
- Estimated, not certified: both gear meshes (`relation uncertain`, no
  sample of either gear inside the other, face boxes overlap), mesh
  clearance `[0, 0.136]` (only the zero lower bound certified), gear 2 vs
  the frame (`uncertain`), and every clearance lower bound (all 0, even
  for the certified-disjoint gear 1 / frame pair whose true gap is about
  8.2 mm). Each gear-pair query takes about 15 minutes. These are C11
  limits, recorded for the C11 follow-up: a certified disjointness and
  clearance method for interlocking, box-overlapping solids.
- PMI stacks cannot negate a dimension (`stack-needs-dim`); the agent
  added an explicit negative mirror dimension, which does not follow the
  parameter it mirrors.

## 4. Independent grading (`tools/grade/g3.py`, run 2: PASS)

OCCT (via build123d) is used here only as an independent reader of the
STEP files BendCAD wrote, as AGENTS.md allows; it is not part of
BendCAD. All 18 placed parts read back as one valid solid each, with
volumes equal to BendCAD's certified intervals. The 45 part pairs whose
boxes touch share no volume. For the meshes the grader walks each gear's
cap outline from the STEP file in loop order and measures exact 2D
polygon clearance (the gears are prisms): pinion 1 / gear 1 and pinion 2
/ gear 2 each 0.0974 mm minimum, no edges crossing, no vertex inside the
other (`run2/grade.json`). OCCT's own distance query reported a false
zero for the coplanar gear caps, which is why the grader measures the
outlines directly. A first version of that outline check read the
vertices unordered and wrongly reported an overlap in run 1; with loop
order, run 1's full-addendum gears clear by 0.102 mm, so run 1 had no
overlap either, and run 2's 0.9-addendum tip relief was not needed.

## 5. Renders

`run1/`, `run2/`: `g3_parts.png` (every part), `g3_assembly.png`,
`g3_gear_train.png` (cover and walls removed), `g3_exploded.png` (the
`explode` placements), rendered by `tools/grade/g3_render.py` from the
STL files BendCAD exported.
