# BendCAD direction (Amendment A8, 2026-11-11)

Owner direction: the kernel is solid enough to start from. It now has to become something a normal person can use, through an agent. This strengthens the scope of MASTER_PLAN. Nothing in it is removed or redirected.

## The product

A person tells an agent what they need. The agent pilots BendCAD. The result is a design that works and can be made, which the person can look at, check and change.

That is one product with three parts:

| Part | Role |
|---|---|
| Kernel | Geometry, topology, tolerances, checks. Every answer is certified or refused with a diagnosis. |
| Engineering data | The standards, catalogs and material tables engineers work from, held as cited data the kernel and the agent both read. |
| Viewer | Where the person sees the live design, the checks, and changes it. Also where the agent looks. |

The premise is not in question: engineers work from data and inspection, and both can be given to an agent. When an agent fails to produce a working, makeable part, the cause is a missing capability or missing data in this repository, and it gets built.

## What "it just works" means

A brief is one sentence or one paragraph. It passes when all six hold, each with a receipt:

1. **It builds.** The agent reaches a committed design using only the documented vocabulary. Refusals on the way are counted; each one names a fix that works.
2. **It works.** Every requirement in the brief is a check that reports pass, fail or not-analyzed. A brief passes with no fail and no not-analyzed among the things it asked for.
3. **It can be made.** For the declared process (3-axis mill, lathe, FDM or SLA print, sheet): standard tools reach every feature, standard sizes are used where a standard exists, and the STEP, STL and drawing outputs are valid for another tool.
4. **It can be seen and changed.** The viewer opens the design file itself. A person changes a dimension and the part, its checks and its neighbours update.
5. **It is fast.** Budgets below.
6. **It is evidenced.** Every claim above cites a receipt in `docs/receipts/`.

## Speed budgets

| Step | Budget |
|---|---|
| One edit to a visible, re-checked part | 5 s |
| An everyday part from nothing (kernel time) | 60 s |
| A 25-part assembly to a viewable scene | 60 s |
| Manufacturing-quality export of one part | 5 min |

Measured on 2026-11-11, none of these is met for curved or threaded work: a 100-hole plate tessellates in 227 s (1.98 s on 1 November), one freeform blade yields 186,156 triangles against an estimate of 8,454, a set of M3 screws with modelled threads takes 50 minutes to build, and the G5 scene took 72 minutes.

## Scope added by A8

| Item | What it adds | Builds on |
|---|---|---|
| S1 Engineering data | Threads, fits, fasteners, bearings, keys, retaining rings, O-rings, clearance and tap-drill holes, counterbores, general tolerances, materials, stock and cutter sizes. Each record carries its standard and source. | K2 threads, fits, materials; `engineering-core` |
| S2 Standard features by construction | Tapped hole, modelled thread, counterbore, countersink, keyway, ring groove, O-ring groove, bearing seat. Each is built directly as certified topology from the data record, not found by a general boolean. | C09 features, K1, K4 |
| S3 Function and manufacture as kernel facts | A design carries its requirements; the kernel reports each as pass, fail or not-analyzed, including reach, wall, undercut and standard-size checks for the declared process. | Evaluation 2026-11-10 step E, K3 machinability |
| S4 Viewer as product | Opens the design file, shows the feature tree, checks and sections, edits parameters, and renders fixed inspection views to image files for the agent. | `viewer/`, kernel `scene` and `view` |
| S5 Agent manual | One reference for every operation, query and check, generated from examples that run in the E2E suite. | C06–C16, K1–K4 CLI |
| S6 Speed budgets | The table above, enforced by the brief ladder. | §15 |

Still required, unchanged: K5 (one face-local intersection solver, special positions as answers), conforming tessellation, human editing (evaluation step F), G5 to readiness all-pass, G6.

## Two ladders

The gate ladder (G1–G6, MASTER_PLAN §18) measures depth. The brief ladder measures whether everyday requests just work. A brief is run from its sentence alone.

| Brief | Request | Process |
|---|---|---|
| B1 | L-bracket, 3 mm plate, two M5 clearance holes per leg, inside fillet | sheet or mill |
| B2 | NEMA 17 motor mount plate: 31 mm bolt square, 22 mm pilot, M3 clearance, two adjustment slots | mill |
| B3 | Flanged housing for a 608 bearing: H7 seat, shoulder, retaining-ring groove, four-bolt flange | lathe and mill |
| B4 | 8 mm shaft: two k5 bearing seats, shoulder, keyway, ring groove, M8x1 thread, chamfers | lathe |
| B5 | Split shaft collar for 8 mm with an M4 cap screw: counterbore one side, tapped the other | mill |
| B6 | Spur gear pair, module 1, 20 and 40 teeth, bores with keyways, centre distance certified | mill or print |
| B7 | Electronics enclosure 100 x 60 x 30 with lid, four M3 insert bosses, rounded edges, cable port | print |
| B8 | Pipe flange with bolt circle, raised face and O-ring groove to the standard | lathe and mill |
| B9 | Butt hinge: two leaves, knuckles, pin, clearance certified through the swing | mill |
| B10 | M3 x 10 hex standoff with a tapped through hole, thread modelled | lathe |
| B11 | Handwheel: revolved rim and hub, three spokes, D-bore | print |
| B12 | Bearing cap with a pocket, two ribs and four countersunk holes | mill |
| B13 | Assembly of B3, B4, B5 and a 608 bearing: fits, clearances and interference certified | — |
| B14 | Small radial fan wheel with eight backward-curved blades on a hub with a bore | print |

Each brief leaves `docs/receipts/briefs/<id>.json`: build time, refusals met and how each was cleared, checks, OCCT agreement on the exported STEP, mesh conformity, edit time and the budget verdicts. The ladder grows as real requests arrive.

## Order of work

1. **Baseline.** Run the brief ladder on the current kernel and record what fails, by measurement. Write the agent manual from what ran.
2. **Clear the blockers the baseline shows**, most briefs blocked first. Known today: tessellation time and conformity, modelled threads, curved booleans in general position (63 of 144 commit).
3. **Live document in the viewer**: open, tree, edit, checks, inspection renders.
4. **Data library and the function and manufacture checks.**
5. **G5** rebuilt on the result, readiness all-pass, then G6.

## Baseline (2026-11-12, kernel `a15`)

Measured by `tests/briefs/run.py`; receipts in `docs/receipts/briefs/`, scoreboard in `docs/receipts/briefs/summary.md`, every refusal and gap in `friction.json`, reproducers in `tests/briefs/repro/`, vocabulary in `docs/agent-manual.md`.

- 13 of 14 briefs build, each in 0.03 to 5.2 s of kernel time. B10 does not: its modelled thread is refused.
- OCCT agrees with the certified volume on every exported part. Every mesh that was written is conforming.
- No brief passes. 70 required checks are not-analyzed and 3 fail.

| Rank | Blocker | Briefs |
|---|---|---|
| 1 | Wrong answers: holes on a pad's cell face commit as sealed cavities; `asm gap` certifies an interference that does not exist; H7/h5 refused on a rounding error of 7e-15 | B7, B13 |
| 2 | `wall` gives no answer on revolved or boolean parts in 600 s | B3, B4, B5, B7, B11, B12, B14 |
| 3 | Display tessellation takes 15 to 49 s on prismatic parts (39,410 triangles against an estimate of 2,588); one part cannot be meshed | B5, B6, B7, B9, B11 |
| 4 | `clearance`, `asm clear` and `interf` take 440 s to over 600 s on non-coaxial curved pairs | B6, B8, B9, B13 |
| 5 | No query certifies a hole size; no drill, flat end mill or tap in `machine`; no lathe, print or drawing output | all |
| 6 | Standard features and their data are typed by the agent: clearance hole, counterbore, countersink, keyway, ring groove, O-ring gland, tapped hole, modelled thread | all |
| 7 | An everyday edit is refused (countersink 2.6); `press` breaks three assembly verbs; a refusal names no usable fix (`thread-span-outside-face`) | B5, B12, B13 |

Wrong answers rank first whatever their count: a kernel that is sometimes silently wrong cannot be piloted.

Packets, in order, one at a time:

| Packet | Closes |
|---|---|
| P2 Wrong answers and refused everyday edits | ranks 1 and 7, hole-size query |
| P3 Display tessellation of analytic faces inside the edit budget | rank 3 |
| P4 `wall` and clearance on curved parts | ranks 2 and 4 |
| P5 Standard features by construction, with their data (S1, S2) | rank 6, B10 |
| P6 Process checks and drawing output (S3) | rank 5 |
| P7 Live document in the viewer (S4) | acceptance point 4 |

The ladder is re-run after every packet; a packet lands when its briefs move and nothing else regresses.

Progress:

| Packet | Kernel | Result |
|---|---|---|
| P2 | `p2` | Six of seven reproducers pass (`docs/receipts/briefs/repro.json`; all seven fail on `a15`). Cell faces resolve to their named face and a cut that would seal a void is refused; `asm gap` uses the exact span of an arc face; fits are computed from the tabulated deviations; one assembly grammar for every verb; `thread-span-outside-face` prints the admissible span; `faces -f` prints certified cylinder, cone, sphere and torus parameters. B7 6/1/5 to 7/0/5, B13 3/1/5 to 4/0/5. Identity 16/16, fuzz gate unchanged, laws and 163 mutants hold, K2 E2E 34/34, K2 refusals 20/20. |
| P3 | `p3` | Analytic faces meshed directly from their boundary samples (planes, cylinders, cones) or a parameter grid stitched to them (spheres, tori, and ruled faces whose boundary alone overshoots the chord), each triangle with a certified deviation bound (`docs/receipts/briefs/mesh.json`, failing p2 run in `mesh-p2.json`). Every brief part meshes conforming within 0.13 s beyond evaluation on one core (enclosure 143 s to 1.0 s, 39,410 to 1,664 triangles); 100-hole plate 589 s to 3.1 s; 25/100/400 holes scale with slope 1.06; B11 meshes (cause of the old refusal: phantom padding points in the ear clipper's grid). Edit budget now met by B5, B6, B7, B9; B11 misses it on evaluation (three 5 s re-evaluations), B12 on the refused countersink edit. Identity 16/16, fuzz gate 0 regressions, C06 E2E 66/66 (64/66 on p2), K2 E2E 34/34, K2 refusals 20/20. |
| P3 follow-up | `p3t` | The mesh judge now fails coincident triangles and triangles further than twice the preset angle (floor 0.1 rad) from the surface normal, and gained six everyday curved cases at two presets (`docs/receipts/briefs/mesh.json`, 43 of 47; the same judge on `p3` is `mesh-curved-p3.json`, 24 of 46). Faces cut from a sphere mesh directly in a chart centred on the face (dimple 2,294 to 366 triangles, 0.43 to 0.05 s). A sphere with flats and a cross-drilled bar, both refused on `p3`, mesh. Edge-on triangles along curved boundaries are gone (B5 collar 33 to 0, worst normal 1.55 to 0.11 rad). The manufacturing preset stays on the direct path (B11 785,990 triangles in 24 s and 1.5 GB), the O-ring STL no longer crashes, and the deviation bound is outward-rounded. Display times are unchanged (worst brief part 0.28 s, 100-hole plate 3.3 s). Still failing: B10 (thread, P5), the two freeform blade rows (zero-area triangles, as before) and B11 at preset 2 on normals. Identity 16/16, fuzz gate 0 regressions, laws hold (`precommit-p3t.txt`), C06 E2E 66/66, K2 E2E 34/34, K2 refusals 20/20. The one row slower than `p3` is the B11 manufacturing STL (88 s against 64 s), which now writes the 785,990 triangles its preset angle asks for instead of 249,580. |
| P4 | `p4f` | `wall` and `clearance` share one certified search over face, edge and vertex cells (`src/c11/qclear.bend`). `wall` is the smallest distance between points of two faces whose inward normals are opposed along the segment; every brief part now answers, B11 in 21 s and the rest in 0.6-4.3 s (none answered in 600 s on `p3t`), and nine everyday solids in 0.01-1.2 s. The search stopped stalling because the bounds became exact where the geometry allows it: radial distance from an axis computed as a cross product (the old form lost the whole interval far along the axis), opposed points on one sphere, cylinder or torus at least twice its radius apart, critical pairs of two planes, two lines or a line and a plane exactly an offset apart, no opposed normals on one cone, edge arcs stored as rational quadratics recognised as circles, each face's radial extent from its edges, and cells off their own surface discarded. Witnesses are found by rays along the normal and by alternating projection, and are accepted only on their own surfaces. `clearance` on the hinge leaves answers 0.4 at all four angles in 4-16 s and `asm clear` on four parts in 98 s (no answer in 600 s on `p3t`); pin-in-bore stays at 0.4 s. Reproducers 9 of 14 (`docs/receipts/briefs/repro.json`): still failing are the tapered-bore lip (`wall` reads 10 where the lip is 0.5: its thinnest span runs between two edges of one face, which opposed faces cannot see), the O-ring seat at 47 s against 30 (the interference check that touching parts need), gear `interf` at 100 s against 20 (unchanged), `asm clear` at 98 s against 60, and the countersink K1 defect. Brief ladder (`docs/receipts/briefs/summary.md`): required checks passing B7 7 to 8, B8 4 to 5, B9 4 to 8, B11 2 to 3, B12 3 to 4, B13 4 to 5, B14 3 to 4; B3 gains a certified failure (its housing has a 1.5 mm wall where the brief asks for 2); B4 and B5 are designed at exactly the 1.0 mm minimum and read [0.99999999999999822, 1.0000000000000013], which an outward-rounded bound cannot decide against `>= 1.0`. No brief regressed. Identity 16/16, fuzz gate 0 regressions, laws hold (`precommit-p4f.txt`), C11 E2E 36/36, query timings in `queries-p4f.txt`. |

Carried forward:

- The countersink edit (rank 7) is one K1 difference that fails its edge-use check for some sizes and not their neighbours (`tests/corpus/k1/countersink-74-6-difference.json`). It belongs with the curved-boolean robustness work.
- An external thread callout on a bare cylinder of the root diameter is accepted and labelled `root-core`. P5 makes that binding come only from the thread feature, and makes the diameter-mismatch refusal print the admissible windows.
- The c14 `asm clear` and `asm interf` paths are unreachable now that K2 answers both verbs; they are removed with their laws moved, not left as a second evaluator.
- On a torus with a large ring and a thin tube, the triangles joining a seam or a pocket to the first grid row lean by about (0.5 + R/8r) times the preset angle, because the grid columns sit between the seam's samples. B11 (R/r = 10) reports 0.168 rad at preset 2 against a limit of 0.1, on 95 of 34,104 triangles. Aligning the grid to the seam samples was built and measured: it fixes a plain seam and fails where the seam is interrupted (the spoke holes) or the two seams carry different counts. The fix is a first row that conforms to the boundary. Fillets on round edges will be such tori.
- The STL writer re-reads the mesh text it has just produced: the B8 O-ring takes 139 s to write where its mesh takes 16 s.
- B11 misses the edit budget on evaluation, not on meshing: the handwheel takes about 5 s to evaluate and apply, check and tess each evaluate it again.
- `wall` does not see a thin span that runs between two edges of one face (a tapered-bore lip, the web of an annulus). Face-to-edge pairs were built and measured: their opposed points lie on the face boundary, where membership is uncertain, so they never confirm. The fix is an in-face width between edges of one face, with each edge's inward direction in the face.
- Touching parts spend most of `clearance` in the interference check (B8 O-ring seat 47 s), and gear `interf` takes 100 s in the exact intersection. Certified separation first was measured and is slower on the gears (137 s), so `interf` keeps the exact intersection first.

## Oversight

- One scoreboard, generated from receipts (`tools/readme/ladder.py`). A row is done when its receipt says pass.
- `tools/precommit.sh` (identity battery, fuzz gate, law gate) runs before every kernel commit.
- Work is handed out as one bounded packet at a time. A packet returns receipts and is reviewed against the gates before it lands.
- A failure is reported as what is missing and what will be built, never as a limit on what an agent can do.
