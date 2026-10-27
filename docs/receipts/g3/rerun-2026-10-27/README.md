# G3 re-run on the K3 kernel (2026-10-27)

`tools/g3/gearbox.py` rebuilt the v3 gearbox from scratch on
`/home/jesse/bc/bendcad` = `bendcad-k3z` (sha256 `bfa3cffe…`, `build.txt`)
in 23 min 30 s, and `tools/grade/g3.py` graded the 119 placed STEP files
with OCCT (`grade.log`, `grade.json`).

- Stages housing, lid, drivetrain, purchased: committed.
- `asm solved ninst 119 nmates 122 dof 0 max-residual 8.53e-14`.
- All 45 node volume intervals identical to `../v3/report.json`.
- PMI check (13 items) and the shaft end-float stack identical: nominal
  0.40 mm, certified envelope [0.18, 0.86] mm, hot [0.18018, 0.86086].
- Grading PASS: 119 parts, each one valid solid; 370 touching pairs, no
  interference; gear outline meshes 0.1002 mm minimum clearance, no
  crossing, on both stages.
