# BendCAD evaluation, 2026-11-10

This replaces the review written on branch `claude/bendcad-review-roadmap-9ptqf4`, which has been deleted. That review was written without running the kernel. Everything under "Measured" below was run today on this machine and can be repeated with the commands at the end.

## The short version

- Bend is not what makes the kernel slow. A Bend loop doing certified interval arithmetic runs at the speed of the same loop in C.
- The kernel is slow because the cost of a boolean follows the surfaces involved, not the size of the answer. It took 41.6 s to find that a box and a torus have no intersection curves, and 131 s to commit the union of those two bodies, which do not touch.
- The kernel refuses because intersection is a table of 23 hand-written surface-pair cases. Refusals sit where the table is thin (torus, cone, revolve) and at special positions (tangent, coincident, through an apex), which are reported as errors when they are ordinary geometry with a defined answer.
- The 11 disagreements with OCCT in the last fuzz receipt were never explained. Checked today: the kernel is right. The STEP writer exports the flat walls of an extruded profile as bicubic spline surfaces, and OCCT integrates those approximately.
- "Does the product work" is still a script written per machine. It needs to be a set of physical facts the kernel can compute about any assembly, so the same mechanism serves a hammer, a telephone pole and a school bus.

## Measured

### 1. The language is at parity with C

Four million evaluations of a cubic Bézier in outward-rounded interval arithmetic, one core:

| Loop | Time | Per evaluation |
|---|---|---|
| Bend, control points in a fixed record | 0.467 s | 117 ns |
| C, same arithmetic, structs | 0.447 s | 112 ns |
| Bend, control points in a `List` (what `src/c07/rb.bend` does) | 1.23 s | 308 ns |
| C, heap-allocated linked list | 0.597 s | 149 ns |
| Bend, 16M record evaluations through `pmap_g`, 16 threads | 0.247 s wall, 2.97 s CPU | 7.6x faster than one core |

Lists cost 2.6x on the innermost loop. That is worth taking, but it is a factor of 2.6 against a problem that is four to five orders of magnitude wide. A process start plus one box commits in 0.010 s, so there is no fixed overhead to blame either.

### 2. Where a boolean spends its time

Stage timings from `tests/k3/zstage.bend` on four cases from the fuzz corpus. Times are milliseconds for one pass through the stage.

| Case | Chains found | `all_hits` | `all_chains` | `run_emit` | `vcore` (checker) | Share in `all_chains` |
|---|---|---|---|---|---|---|
| seed 78, prism and cylinder, general position | 3 | 256 | 1,947 | 86 | 247 | 76% |
| seed 103, revolve and sphere, refused (reason 73) | 8 | 8 | 5,468 | 165 | 391 | 90% |
| seed 5, torus and cone, rejected by the checker | 4 | 17 | 6,825 | 181 | 15 | 97% |
| seed 127, box and torus that do not touch | 0 | 2 | 41,558 | 43 | 22 | 99.8% |

`all_chains` is the construction of intersection curves between face pairs (`src/k1/px.bend:1668`, calling `SS.ssi_b`). Nothing else matters to the total.

Reading the code it calls explains the numbers:

- **Work is done on whole surfaces, then thrown away.** For a plane and a torus, `fr_tor` (`src/k1/ss.bend:900`) seeds on a grid over the entire torus against the unbounded plane, marches each loop for up to 1,200 steps, and certifies every point. The face boundaries are consulted only afterwards. Each of the box's six planes slices the full torus even though no face of the box reaches it. That is the 41.6 s.
- **A curve is a string of individually certified points.** A plane cutting a cylinder is an ellipse with a closed form. `ell_go` (`src/k1/ss.bend:175`) samples it at 64 points and certifies each one by nudging it one unit in the last place at a time until the exact predicates accept it (`EF.cert_gs`). The ellipse then leaves the kernel as spline pieces: the STEP file for seed 78's union contains 8 `B_SPLINE_CURVE_WITH_KNOTS` and no `ELLIPSE`.
- **Seeding is a sample.** The marching path finds loops by sign changes on a 12 by 13 grid. A loop smaller than a grid cell produces no sign change. The checker downstream is what stands between that and a wrong result.

Not measured: how `all_chains` time divides between seeding, marching and certifying.

### 3. Where the kernel refuses

Re-aggregated from `docs/receipts/eval-fuzz-k5w-150.json` (binary k5w, 5 November, before the 9 November fixes). The rate on the current binary has not been re-measured.

- 250 of 450 operations committed.
- Operations involving a torus: 138 operations, 54 committed, and 63% of all time spent in the run.
- Planar-only operations: 27 operations, 24 committed, median 0.42 s.

| Surface pair | Committed |
|---|---|
| cone and torus | 0 of 24 |
| revolve and torus | 0 of 9 |
| revolve and revolve | 0 of 6 |
| cone and revolve | 0 of 6 |
| cylinder and revolve | 1 of 18 |
| revolve and sphere | 3 of 21 |
| box and revolve | 4 of 18 |
| prism and torus | 10 of 30 |
| box and box, sphere and sphere, cylinder and sphere, box and prism | all |

Where the 200 refusals came from:

| Origin | Count |
|---|---|
| The constructor gave up with a reason code (71, 72, 73, 82 and others: tangency, uncertified curve, unsupported configuration) | 113 |
| The constructor built a result and the checker rejected it | 63 |
| An earlier node had failed, so the input was missing | 21 |
| Timed out at 1,800 s | 3 |

Two things stand out.

Refusing is the expensive path. Committed operations had a median of 0.98 s; refused ones 45 s.

The 63 checker rejections are the constructor and the checker disagreeing about the same geometry. The user is told `numerical-uncertainty ... fix: report these operands`. That is not a diagnosis an agent can act on, and the doctrine says failures are diagnoses.

### 4. The unexplained oracle disagreements

The receipt lists 11 committed unions out of 78 whose volume disagreed with OCCT by 3e-6 to 2.5e-5 relative. They were recorded and left. All 11 involve a prism.

- The kernel's volume for 40 random prisms matches the exact shoelace value to 4e-16 relative (`tests/review/prism_volume.py`). The kernel is right.
- The STEP file for a six-sided prism contains 6 `B_SPLINE_SURFACE_WITH_KNOTS` and 12 `B_SPLINE_CURVE_WITH_KNOTS`. A box exports 6 `PLANE` and 12 `LINE`. Flat walls made by extruding a profile are written as bicubic patches.

So the oracle is being handed splines where there are planes. Anything else that reads the file (CAM, another CAD system, a drawing) gets the same. Whether those walls are also patches inside the kernel's own intersection dispatch was not measured.

## What this says about the design

Speed and robustness are one problem. The kernel has no single way to intersect two faces. It has a dispatch table (`ssi_disp`, `src/k1/ss.bend:1120`) with one entry per pair of surface kinds, each written separately, each producing points, each with its own handling of special positions. Three consequences:

1. Every new surface kind adds a row and a column to the table. A kernel meant for any product cannot grow that way.
2. Special positions are handled per case or not at all, so they surface as refusals.
3. Certification is applied to points after the fact, so its cost scales with how many points were sampled on how much surface, not with what the two faces actually do to each other.

The speed packets so far (demand-driven evaluation, the `serve` cache, parallel face work, validating only changed pairs) made the kernel avoid repeating this work. None of them changed the work.

## Plan

Ordered by what depends on what. No durations.

### A. One intersection, local to the faces

Replace the table as the way curves are found with one solver that takes two trimmed faces and returns their intersection.

- It starts from the faces, not the surfaces: a box hierarchy over each trimmed face, descended together, subdividing only where both faces are present. Two faces that do not meet are separated by their boxes and cost almost nothing.
- It works on every surface kind the kernel has, because planes, cylinders, cones, spheres, tori, revolves of lines and arcs, and patches are all rational patches, and `src/c07` already has interval hulls, restriction and subdivision for those.
- It certifies branches, not points. For each piece of curve it proves that exactly one branch passes through a tube (an interval Newton test on the two surface equations). Any point on the branch can then be produced to any accuracy on demand, with a bound.
- The existing closed forms stay, as recognisers. Once a branch is found and certified, recognising it as a line, circle or ellipse upgrades it to the exact curve. A closed form is never the only way a curve can be found, so a missing table entry can no longer cause a refusal.

Done means, as E2E artifacts:

- Disjoint and near-miss operations cost about the same as box against box, for every surface kind. Seed 127 is the first case.
- Operation time tracks the number of intersection branches, shown on a sweep where the answer is held fixed and the surfaces around it grow.
- A new surface kind can be added without writing any pair-specific intersection code.

### B. Special positions are answers

Tangent contact, coincident faces, a plane through a cone apex, a curve along a seam: regularised boolean semantics define the result in every one of these. The solver in A extends to classify them by adding the condition that the two normals are parallel, which isolates touch points and tangent curves the same way it isolates ordinary branches.

Each boolean then gets a defined outcome per class: a transversal curve cuts, a tangent curve or touch point contributes nothing to a regularised result, an overlap region merges or cancels by orientation.

Done means the tangent, coplanar, coaxial and seam placements in the fuzz commit at the same rate as general position, and reason codes 71, 72, 73 and 82 no longer exist as refusals.

### C. The constructor hands its proof to the checker

Today the checker re-derives everything and sometimes disagrees. With A, the constructor already holds a certificate for every branch. The checker should verify those certificates rather than rediscover the geometry. That is cheaper, and it removes the class of failure where two pieces of code reach different conclusions about the same curve.

Whatever disagreement remains is a kernel defect, and the kernel should treat it as one:

- Reduce the failing operation automatically to the smallest pair of bodies that still fails (drop faces, round dimensions, remove placements while the failure persists).
- Store that reproducer in a corpus in the repo. The corpus is rerun by a local script before a kernel commit, next to the identity battery.
- Report the geometric cause and an edit that would succeed, in place of "report these operands".

### D. Output keeps what the kernel knows

A plane leaves as a plane, an ellipse as an ellipse, a straight edge as a line. The file is then read back and compared: same face kinds, same counts, volume inside the kernel's interval. The OCCT comparison has to end with zero unexplained disagreements; an unexplained one is recorded as a defect, not as a number in a receipt.

### E. Function as kernel facts

The complaint about the last review's "set of broken engines" is right: fixtures for one product teach the system about one product. The general version is that the kernel computes physical facts about any assembly, and a requirement is a comparison against one of those facts.

The facts:

| Fact | What the kernel computes | Examples it serves |
|---|---|---|
| Spaces | The empty regions between parts as solids, with the faces that bound them, their openings, what connects to what, and the smallest section along a path | Does the cabin seal; does the fluid get from inlet to outlet; can a hand or a tool reach the fastener |
| Restraint | Which faces touch or are fastened, how each body can still move, and what resists each load direction | Does the hammer head stay on the handle; is the pole held at the ground line; is the seat held in a crash direction |
| Motion | Each moving body swept through its range, with interference along the sweep | Door swing; steering lock to lock; a rotor past its casing |
| Load | The path from an applied load to ground through contacts and joints, with stress and deflection margins | Wind on the pole; impact on the hammer; a full bus on its frame |
| Mass | Mass, centre of gravity, inertia, tipping margin | Bus stability; hammer balance |
| Make | For each part and a declared process: tool reach, minimum wall and radius, undercuts | Whether each part can be produced at all |
| State | Any of the above at a temperature, load or tolerance extreme | Fits when hot; clearance under load |

Some of this exists already (certified clearance, K3 FEM, mass properties), and some exists only as G5 scripts (`readiness.py`, the CFD case). None of it is a query on the design graph.

Three rules make this more than a checklist:

1. **A requirement is a node in the graph.** It names a fact, a bound and a state. Its value is pass, fail or not analysed, with the evidence attached. "Done" is computed from those nodes.
2. **Coverage is measured by perturbing the design at hand.** For every feature and driving dimension, the kernel removes it or pushes it past its tolerance and re-evaluates the requirements. The output is two lists: features that no requirement notices, and requirements that nothing can break. This works on whatever is being designed and needs no fixtures. It also depends on A, because it re-runs the design many times.
3. **Every sentence of the brief maps to a requirement or is listed as uncovered.** Perturbation finds unguarded features; it cannot find a function nobody asked for. This table is the part the owner reads, and it is short.

### F. Human editing through the same graph

A person does not need a separate document format. The kernel already tags faces with the node that made them. Picking a face in the viewer should show that node and its parameters; changing one writes an ordinary edit to the graph and re-evaluates only what depends on it. Requirements update in the same pass.

This was not measured today. It is gated on A: any edit that touches a curved boolean currently costs seconds to minutes, and direct editing is not usable at that speed.

## Order

A first. B, C, the perturbation half of E and all of F depend on it. D is independent and small. The fact queries in E can be built alongside A, starting with spaces and restraint, since those serve the widest range of products.

G5R stays paused as instructed. Its open kernel defects (the torus and cylinder case among them) fall inside A and B.

## Not proposed

- GitHub CI or any hosted service.
- Changing language. The measurement says there is nothing to gain.
- Flattening the interval lists as the speed plan. It is a 2.6x item and should be done as part of A, not instead of it.
- Product-specific fixtures.
- Any schedule.

## How to repeat

All commands run in WSL from the repo root, with `ulimit -s unlimited`.

| Result | Command |
|---|---|
| Bend loop timings | Build `tests/review/zraw.bend` as `tools/build/probe.sh` does, then run with no argument (record), one argument (list), two arguments (parallel) |
| C loop timings | `zig cc -O2 tests/review/zraw.c -lm`, same argument convention |
| A fuzz case kept on disk | `FUZZ_BIN=~/bc/bendcad-k6w python3 tests/review/gen_case.py SEED OUT.bcd` (prints the placed node id) |
| Stage timings | `/var/tmp/probe.zstage OUT.bcd 1 PLACED_ID` (probe built 9 November from `tests/k3/zstage.bend`) |
| Prism volumes against exact | `FUZZ_BIN=~/bc/bendcad-k6w python3 tests/review/prism_volume.py /var/tmp/pv.bcd` |
| Export entity counts | `bendcad-k6w FILE.bcd step NODE out.stp`, then count entity names in `out.stp` |
