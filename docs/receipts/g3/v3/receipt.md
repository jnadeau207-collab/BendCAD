# G3 v3 receipt — reference gearbox (2026-10-15)

The owner reviewed the run-2 gearbox (`../run2/`) and asked for a gearbox a
person could build and use: a sealed, bolted housing, real catalog bearings
and seals, and shafts that can take torque in and out. This is that design,
engineered and built by Claude from `tools/g3/gearbox.py` through the
BendCAD CLI (a reference design, not a fresh-agent ladder run). Design and
rationale: `docs/g3-gearbox-design.md`.

## 1. Result

- 25 part designs, 119 instances, 122 mates:
  `asm solved ninst 119 nmates 122 dof 0 max-residual 8.53e-14`.
  This solve needed the C14 nested-dissection fix of `../receipt.md` §2.2:
  before it, any assembly above 16 unknowns reported a false conflict.
- Every part's volume is certified by the kernel (`report.json`, `eval`).
- PMI on the housing (`pmi check`: 13 items ok; flatness and parallelism
  of the wall top conform, certified). Shaft end float stack-up
  (interior height + floor pocket + gasket + lid pocket - 2 bearing widths
  - spacer stack): nominal 0.40 mm, certified envelope [0.18, 0.86] mm,
  cold [0.18, 0.86], hot (grow 1.001) [0.18, 0.86]. Exported as STEP AP242
  (`housing_pmi_ap242.stp`, 73 PMI entities).
- Exports: STEP and STL of every part (`parts/`) and of every placed
  instance (`placed/`), plus the complete 6004-2RS bearing as one 13-solid
  STEP (`parts/bearing_6004_2RS.stp`, built from rings, nine balls and two
  seals by twelve certified unions, 5 min).

## 2. Independent grading (`tools/grade/g3.py`, PASS)

OCCT, as a test-only reader of the STEP files BendCAD wrote (AGENTS.md):
all 119 placed parts read back as one valid solid each. The 370 pairs whose
boxes touch share no volume: 87 are designed contacts (seats, fits and
faces at nominal size), 283 are clear. The exact 2D outline check on the
gear caps gives 0.1002 mm minimum clearance on both meshes, no crossing.

Two grader guards were added after OCCT misreported: (1) a boolean whose
common volume exceeds the smaller operand is rejected and the pair is
re-checked by point classification; (2) six placed balls first read back
with zero volume. Their STEP was written from solved translations carrying
1e-14 noise (a sphere centre at z = 68.20000000000002 with its pole vertex
one ulp off); snapping placements to a 1e-9 mm grid before writing them
gave all 54 balls their exact 134.066 mm3. Both are recorded because they
are reader sensitivities a STEP consumer will meet.

## 3. Kernel defect fixed: concentric arc clearance (C06)

Profile and footprint validation bounds each arc piece (up to 90 degrees,
as a rational quadratic) by the triangle of its endpoints and control
point, and refused any pair whose triangles overlap. For concentric arcs
the triangle of a long arc reaches past the inner curve, so a 2 mm ring
built from arcs (a rounded-rectangle wall, crush-flat bores with a relief,
a keyway) was refused as `clearance-not-certified`. `src/c06/prof.bend`
now splits an uncertain arc piece by exact rational-quadratic subdivision
(weight sqrt((1 + w) / 2)) up to five levels and certifies the pair if
every sub-pair separates; sub-triangles lie inside their parent's, so the
test stays conservative. New journeys in `tests/c06/e2e.py`
(`concentric.*`): four rings that were refused now certify with volume
intervals containing the exact value; touching, crossing and internally
tangent arcs are still refused.

## 4. Kernel limits recorded (designed around, not fixed)

Listed in `docs/g3-gearbox-design.md` §3: features on the two faces of
one cell treated as obstacles regardless of z; touching solids not fused by
union; a pocket over a pad grown beneath it refused; ring pockets enclosing
a face hole refused; no CONICAL_SURFACE in the STEP writer; thin tori fail
validation; no threads, pad chamfers or side holes; mesh clearance only
estimated (C11).

## 5. Files

`parts/`, `placed/` (STEP .stp and STL), `gearbox.bcd` (the BendCAD design),
`assembly.txt`, `report.json` (ids, volumes, solve, explode, PMI),
`grade.json`, renders `g3_parts.png`, `g3_assembly.png`,
`g3_gear_train.png`, `g3_section.png`, `g3_exploded.png`.
