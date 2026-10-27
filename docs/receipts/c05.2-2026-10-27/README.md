# C05.2 sketch solver soundness (2026-10-27)

## Defect

`classify_go` reported `conflict` whenever Levenberg–Marquardt stopped at a
stationary point with a nonzero residual. For nonlinear constraints
(distances, perpendicularity, angles), that point can be a local minimum of a
consistent sketch. On the seeded oracle below (seed 2, 1500 random sketches
with known solutions), 22 consistent sketches were reported as conflicts.

## Fix (`src/c05/solve.bend`)

1. When the first solve does not certify its conflict, the solver retries by
   homotopy from the start point. It solves G(x) = F(x) − s·F(x0) for s
   stepping from 15/16 down to 0, warm-starting each step (`hom`, `retry`,
   residual offset `ho` in `Cx`).
2. A conflict is reported as `conflict` only when an exact argument proves
   the system has no solution (`certify`):
   - every constraint is linear, so a stationary point is a global minimum;
   - a violated constraint whose referenced parameters are all fixed;
   - two constraints on the same point pair that disagree (two different
     distances; horizontal plus vertical, or coincident, plus a nonzero
     distance);
   - three violated distances that close a triangle and break the triangle
     inequality.
3. Any other stationary residual is `unresolved [...] status=estimated`.
   `Sv_conflict` now carries `cert`, and a merge across components is
   certified only if every component's conflict is.

## Evidence

`tools/oracle/c05/run.sh` regenerates every file here: seeded cases, a probe
build, and an independent judge (numpy rank/dof and residuals; Shapely and
the Euler formula for arrangements).

- `summary.txt`:
  - Solver, 1500 cases: 0 wrong answers.
    - ok: 1089 PASS, 1 unresolved (honest).
    - redundant: 198 PASS, 5 unresolved (honest).
    - conflict: 205 PASS, 2 `err nonconverged` (weak, not wrong).
  - Arrangement: 500/500 PASS.
- `stress_time.txt`: 13.6 s for all 1500 solves.
- `scale.txt`: a rigid chain of n points (2n − 3 distances) solves to oracle
  dof and residual at every size. Times: n=10 0.01 s, n=50 0.04 s,
  n=100 0.19 s, n=200 0.68 s.
- Laws:
  - `laws/c05`: check and `--verdict` both ALL PROOFS CHECK.
  - New laws: `uncertified_conflict_is_estimated` and
    `certified_conflict_is_conflict`.
  - The conflict laws now quantify over `cert`.
  - Mutants: c05 163/163 killed (`tools/laws/mutate-report.json`).
- Pins:
  - c05 31/31, c09 50/50, c14 163/163, each with an unchanged report hash.

## Open

The sketch solver and arrangement are not reachable from the design language
(`docs/language.md`: no design-file sketch syntax). C14 uses its own
assembly solver. Agents therefore cannot yet build constraint sketches.
