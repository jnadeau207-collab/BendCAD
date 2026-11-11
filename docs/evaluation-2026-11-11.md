# BendCAD evaluation, 2026-11-11

Everything here was run on 2026-11-11 in a 4-core, 15 GB Linux container, with `bend` built from `BEND_PIN` (`a4d17ace`, tag `numeric/2026-10-05`), Lean 4.34.0 for `--verdict`, and OCCT through build123d 0.13 as the oracle. Times are on 4 shared cores with other jobs running, so they are comparable within a table, not with the owner's 16-core receipts. It follows `docs/evaluation-2026-11-10.md` and measures what changed since.

## The short version

- The two speed commits of 11 November (`fc48c64`, `4e10100`) are real on the whole fuzz corpus and change no answer: every one of 429 operations decides as before, CPU in committed operations falls 6.5x and in refusals 3.9x. They also broke three law packages (C04, C14, K2); the proofs are repaired, and no law statement changed.
- Commit rates did not move. General position commits 58 of 144 operations, the same as on 5 November. The speed work made refusing cheap; it did not make the kernel refuse less.
- The tessellator's zero-area "T-junction fillers" were a refinement loop: a Delaunay flip undid each bisection on a curved patch, so the same midpoint was inserted every round, 44 times over. With that loop broken, the bare K4 blade goes from 34,508 zero-area triangles and edges shared by up to 180 triangles to 431 zero-area triangles and every edge shared by exactly two. It is not yet conforming.
- A torus paired with a sphere, cone or another torus off-axis was refused for want of a table entry; the general torus tracer the table already used for planes and cylinders handles them. On the full corpus that is 22 more operations committed (265 to 287 of 429, general position 58 to 63), none lost, no identity or OCCT disagreement, at the price of 11 refusals that now trace before refusing and take longer.
- A line crossing an arc in a profile was reported as "numerical-uncertainty, increase the clearance"; it is now a certified crossing, refused as invalid input with the right fix.

## 1. Re-baseline at 4e10100

| Check | Result |
|---|---|
| Full fuzz, 150 cases (`docs/receipts/eval-fuzz-4e10100-150.json`) | 265/429 committed, identical per operation to a4; 0 identity violations, 0 OCCT mismatches in 82 checks |
| Identity battery, be91f6c vs 4e10100 | 12/12 byte-identical; with four torus, revolve and skin cases added, 4e10100 vs this branch 16/16 (`docs/receipts/k4/ident-t7.txt`) |
| Law gate, check-only and verdict | 21 of 24 packages pass; c04, c14 and k2 fail on 4e10100 and pass on be91f6c. After the proof repairs, 24/24 on this branch (`docs/receipts/laws-2026-11-11.txt`) |
| Planted mutants (`tools/laws/mutate.py`) | 159/163 on the branch: three K2 mutants pointed at code `fc48c64` had rewritten (no mutation site), so the press-fit laws had silently lost mutation coverage, and the C10 budget mutant made the checker reduce the whole tessellator and never finished. After retargeting: 163/163 |
| G5 readiness | 0/10 (last run 9 November; the gate itself was a proxy for four checks, see §5) |
| C06 E2E on the new kernel | 60 rows pass, including the new profile refusal; `perf.holes100` takes 880 s against a 5 s budget and `perf.holes400` times out. The last recorded run (1 November, before the general tessellator) took 1.98 s and 13,212 triangles; 4e10100 takes over 15 minutes. The suite was not re-run when the tessellator was replaced, so this regression went unnoticed for a week |

Where the fuzz spends CPU:

| Binary | Committed | General | CPU, commits | CPU, refusals | Median refusal | Refusals > 60 s |
|---|---|---|---|---|---|---|
| k5w, 5 Nov | 250 | 58/144 | 4,614 s | 28,490 s | 45.2 s | 94 |
| a4, 10 Nov | 265 | 58/144 | 4,465 s | 30,534 s | 57.7 s | 92 |
| 4e10100, 11 Nov | 265 | 58/144 | 692 s | 7,862 s | 7.5 s | 8 |

Seed 25 (sphere and prism) still times out on all three operations and is 5,400 s of the refusal total.

The 7 cases whose base solid failed are all revolve profiles where the generator's line runs back across its arc (crossing parameter 0.32 to 0.98 along the line). The harness now checks each profile independently; the kernel was right to refuse all seven.

## 2. What the law gate found

`fc48c64` rewrote 138 list predicates as short-circuit accumulators (`f_zz`). The new definitions equal the old ones for every input, but they no longer reduce to the `Bool.and` and `Bool.or` forms the proofs used, so `l1_outer_rule`, `l1_lines_cons`, `fins_cons`, `inst_has_cons`, `u_has_cons` and the K2 press-fit verdict laws stopped checking. The commit had been verified by the identity battery alone. Each proof now goes through one lemma, `f_zz(t, b) == Bool.and(b, f_zz(t, True))` or its `Bool.or` dual, proved by cases. `tools/precommit.sh` now runs the law gate with the identity battery and the fuzz gate, so this class of break is caught before a commit.

## 3. The tessellator

Measured with `tools/mesh/check.py`, which welds exactly and reports zero-area triangles, edge-use counts, same-direction pairs and T-junctions. The old check paired directed edges and passed all of this.

| Mesh (preset 2) | Zero-area | Edge uses | Same-direction pairs | Volume vs certified |
|---|---|---|---|---|
| Blade (node 3), 4e10100 | 34,508 of 179,656 | 2 to 180 | 5,022 | -0.05% |
| Blade, flip margin (t1) | 423 | all 2 | 0 | -0.06% |
| Blade, all changes (t7) | 431 of 186,156 | all 2 | 0 | -0.05% |
| Blade-box union (node 6), 4e10100 | 58,641 of 176,050 | 2 to 42+ | many | |
| Union, flip margin (t3) | 3,183 of 168,086 | 2 (two edges 4) | 4 | -0.003% |
| Union, all changes (t7) | 3,061 of 158,450 | 2 (two edges 4) | 4 | -0.003% |
| 100-hole plate (C06 `perf.holes100`), 4e10100 | stopped after 15 min | | | |
| Plate, all changes (t7) | 0 of 288,372, conforming | all 2 | 0 | 227 s |

Mechanisms, found with the probe `tests/k4/ztd.bend`, which dumps one face's refinement in (u, v):

1. **Split, flip, split again.** A bisection puts the midpoint on the segment in (u, v). Next round, the Delaunay pass flips the edge from that midpoint to the opposite vertex, restoring the original edge: the uv convexity test was a strict sign test, and rounding of the midpoint made the cross product about 1e-15 with the right sign, while the 3D cotangent criterion favoured the flip. The same (u, v) midpoint was inserted once per round, 44 copies by the end of the fuel. A flip now needs both new triangles non-degenerate in (u, v) with a scale-free margin.
2. **Boundary slivers.** A triangle on a face boundary whose boundary edge carries error above tolerance (the edge is shared and cannot be split from one side) keeps having its other two edges marked; each bisection halves the apex's distance to the boundary (u = 1 - 2^-24, 2^-29, 2^-34 in the dump). An edge is no longer marked by the error test when either adjacent triangle is a 3D sliver. Measured, this changed little (blade 423 to 431, union 3,183 to 3,061): the remaining zero-area triangles are near-duplicate vertices 1e-14 to 6e-8 mm apart whose origin is not yet found.
3. **Fans from the ear clipper.** On a hole wall the clipped bridged ring spans most of the circumference in u; its diagonals fail the angle test, and longest-edge closure then refines the wall isotropically. Flipping to Delaunay convergence before refinement cut one wall from 17,388 to about 2,800 triangles. A strip needs 252: closure still splits the 8 mm axial edges whenever a diagonal is marked.

The 100-hole plate of the C06 suite had regressed from 1.98 s (1 November, last recorded run) to over 15 minutes on 4e10100 when the general tessellator replaced the old one; nobody re-ran the suite. It is now conforming in 227 s, still far over its 5 s budget.

Faces now tessellate in parallel (`pmap_g` over faces, new-vertex ids shifted by a prefix count afterwards); the output is byte-identical to the sequential one, and the blade takes 4 min 33 s instead of 10 min 55 s on these cores.

## 4. Booleans

| Change | Effect |
|---|---|
| Non-coaxial torus pairs go to the general torus tracer (`src/k1/ss.bend` `rev_go2`) instead of `why_kind` (reason 73) | Fuzz gate: seed 92 (sphere/torus, near miss) commits all three operations with volume identity and OCCT agreement; no committed operation lost. Full fuzz (`docs/receipts/eval-fuzz-k1tor-150.json`): 287/429 committed (+22, all torus or revolve with sphere or cone), general position 63/144, coplanar 30/39, near miss 60/69; none lost; 0 identity violations; 0 OCCT mismatches in 89. Slower: 11 refusals (seed 34 torus/cone 34 to 192 s; refusals over 60 s 8 to 15) |
| Profile line against arc: proven crossing | Seed 118's profile is refused as `invalid-input ... curves-cross-or-touch` instead of `numerical-uncertainty ... clearance-not-certified`; the C06 E2E carries it |

Refusal classes on 4e10100 (fuzz, by `why` and K1 reason):

| Count | Class | Main pairs |
|---|---|---|
| 27 | edge-face penetration, reason 73 (no table entry) | sphere/torus 12, cone/torus 9 |
| 21 | edge-face penetration, reason 72 (curve not certified) | cylinder/torus 6 |
| 21 | edge-face penetration, reason 82 | spread |
| 18 | checker rejects the constructor's result (C04 embedding) | prism/torus 6 |
| 12 | intersect-rejected, reason 73 | cone/torus 6 |
| 11 | face-face uncertain | revolve/sphere 4 |

The torus fallback addresses the reason-73 rows. Reasons 72 and 82 and the checker rejections are what K5 (MASTER_PLAN §10) is for: one face-local solver that certifies branches, with special positions classified rather than refused. That has not started.

## 5. G5

The readiness gate counted the CFD, FEM, modes and lube checks as passed whenever a JSON file existed in their directory. Each now reads its receipt and compares measured values with `cycle.json` and the G5R plan. No such receipt exists, so all four are not-analyzed, as before. The mesh check now uses the full conformity measure. G5 was not rebuilt here: its design lives on the owner's machine (`/home/jesse/g5/g5.bcd`) and its tessellation took 72 minutes on 16 cores.

## 6. G5R items

- Defect 11 (a thread callout cannot bind to a modelled thread): a callout now binds to every face whose name or lineage base is its FACE, on one cylinder, over the union of their spans. Verified on one- and two-turn M3 threads, where the core stays a single face; the split-piece case occurs in the owner's M8 shaft builds and is not exercised here.
- `tools/g5/thr_cases.py` never finished: `int_helix` used phase 0, and the seam-avoidance loop in `helix_secs` cannot succeed when the first section sits on the seam. Fixed, and the loop now refuses a seam phase instead of spinning.
- Defect 6 (trace loses a segment at a periodic wrap) is open, with its workaround still in `threads.py`.
- CFD, FEM, modes, bearings and lube: not run. The OpenFOAM case is generated but no solver ran; readiness reports those four not-analyzed, now for the right reason.

## 7. G4 re-grade

Run 1 failed four checks, all missing manufacturing-quality STL exports of curved parts (impeller, casing, cone, motor). `tools/g4/regrade.py` rebuilds run 1's design on a given kernel and exports and grades every part into `docs/receipts/g4/run2`. On binary t7 the design committed and all 14 STEP files exported in under a second each, but the impeller STL at preset 3 (chord 0.05 mm, angle 0.01 rad) was still running after 55 minutes on these 4 cores, so the re-grade did not finish in this session. G4 stays at 44/50.

## 8. Still open

- K5, the general intersection solver: not started. The torus fallback routes one table hole to an existing general tracer and costs time on refusals.
- The fuzz's three timeouts (seed 25, sphere and prism) and its 142 refusals.
- Tessellation: the blade and union are not conforming yet, and cylinder walls refine isotropically (plate 227 s against a 5 s budget).
- The reducer's 16 reproducers are shallow (0 to 2 reduction steps); naming the geometric cause and a succeeding edit is not done.
- Pins: c00 to c07 hold in full (33, 30, 44, 409, 500, 31, 82 + 25, 14 + 17). `tests/c08/pins.bend` had not compiled since early November (none of its 486 pins ran); repaired, 486/486. c08 `pins_build` onwards had not finished when this was written. The full C13 regression gate was not run; the C06 E2E was, and fails only on the plate budget.
- G5 itself was not rebuilt: its design lives on the owner's machine and took 72 minutes to tessellate on 16 cores.

## How to repeat

| Result | Command |
|---|---|
| Kernel build | `bash tools/build/fastbuild.sh OUT` (clang when zig is absent) |
| Fuzz | `FUZZ_BIN=BIN python3 tests/eval/fuzz.py 150 JOBS OUT.json` |
| Fuzz gate | `FUZZ_BIN=BIN python3 tests/eval/gate.py` |
| Everything before a commit | `tools/precommit.sh REF_BIN NEW_BIN` |
| Mesh conformity | `BIN DESIGN tess NODE OUT.obj 2 && python3 tools/mesh/check.py OUT.obj` |
| One face's refinement | build `tests/k4/ztd.bend`, run `probe DESIGN NODE FACE` |
| Reproducers | `python3 tools/reduce/reduce.py replay` |
