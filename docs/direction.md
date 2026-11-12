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

## Oversight

- One scoreboard, generated from receipts (`tools/readme/ladder.py`). A row is done when its receipt says pass.
- `tools/precommit.sh` (identity battery, fuzz gate, law gate) runs before every kernel commit.
- Work is handed out as one bounded packet at a time. A packet returns receipts and is reviewed against the gates before it lands.
- A failure is reported as what is missing and what will be built, never as a limit on what an agent can do.
