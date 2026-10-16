# C13 feature matrix

Every claim names its evidence. A claim without a passing gate below it
is not a claim; it is a plan, and lives in §1 as pending. Proof
categories follow MASTER_PLAN §19: proven, certified, estimated,
assumed. Nothing here is counted by method names.

## 1. Ladder rungs

| Rung | Status | Evidence |
|---|---|---|
| G1 mounting bracket | PASSED 2026-10-05 | Five fresh-agent runs over CLI+MCP, briefs A (x3) and B (x2); independent grader `tools/grade/g1.py` verdict PASS on every run; kernel volume intervals contain the exact volume; meshes watertight (`docs/receipts/g1/run1..5/grade.json`, `brief.md`, `brief-b.md`) |
| G3 gearbox | RUN, NOT PASSED as a rung | Fresh-agent MCP runs 1-2 built and solved the 18-part box (run 2: `asm solved ninst 18 nmates 21 dof 0 max-residual 4.26e-14`) with certified volumes, stack-ups and exports, but meshing-gear disjointness and clearance stay estimated, so required clearances are not certified (`docs/receipts/g3/receipt.md` §§1-3) |
| G3 v3 reference gearbox | REFERENCE DESIGN, not a ladder run | Claude-built via `tools/g3/gearbox.py` through the CLI: 25 part designs, 119 instances, 122 mates, dof 0, max-residual 8.53e-14; every volume kernel-certified; housing PMI (13 items ok, AP242 export); OCCT as test-only STEP reader: 119/119 valid solids, 370 touching-box pairs share no volume (87 contacts, 283 clear), 0.1002 mm mesh clearance on both gear meshes (`docs/receipts/g3/v3/receipt.md`, `report.json`, `grade.json`) |
| G2 flanged pump housing | PENDING | Brief is MASTER_PLAN §18 held to `docs/gates/README.md`. Blocked first by G3-L4 (gasket groove) and G3-L7a (threads) |
| G4 centrifugal blower | PENDING | Brief is MASTER_PLAN §18 held to `docs/gates/README.md`. Blocked first by G3-L7c (side holes), G3-L2 (impeller-shaft joints), D-surf-gensec, D-surf-thickcurv, D-surf-360, D-surf-queries |
| G5 micro turbojet | PENDING | Brief is MASTER_PLAN §18 held to `docs/gates/README.md`. Blocked first by G3-L1/L2/L3/L5/L6/L8, D-blade-lean, D-blade-feat, D-blade-curve, C13-R1, and certified cold-and-running clearances |
| G6 HUMPHREY-1 | PENDING | Brief is `docs/gates/g6-humphrey-1.md`. Needs everything above plus G6-owned hot-path certification (D-surf-est, D-surf-checkbez, D-blade-checkbez) |

No matrix claim depends on a pending rung.

## 2. Capability matrix

Admitted domains are `tools/mcp/language.md`; refusal catalogs there
are part of the contract. Evidence paths are the suites, laws and pins
that must pass; measured counts are §4.

| Area | Admitted capability | Evidence |
|---|---|---|
| Parametric design (C06) | Prism/pad/pocket/holes over arc profiles, truthful-intent edits, atomic commit (failure publishes nothing), certified volume intervals, bbox, faces, sens, zone over tolerance envelopes | `tests/c06/e2e.py`, `tests/c06/pins*.bend`, `laws/c06/` |
| Constraint sketch (C05/C07) | Exact/interval solve with named refusals; circular pattern N=4; envelope evaluation of profiles ahead of G2 | `tests/c07/e2e.py`, `solid.py`, `solid_neg.py`, `zone.py`, `tests/c07/pins*.bend`, `laws/c05/`, `laws/c07/` |
| Booleans (C08) | Regularized union/diff/inter over admitted solids; touching solids stay separate (G3-L2); analytic/NURBS mixes refused (C13-R1) | `tests/c08/e2e.py`, `neg.py`, `tests/c08/pins*.bend`, `laws/c08/` |
| Features (C09) | Holes, pockets, pads, equal-end-radii fillets; unequal radii refused before build (A7); curved-wall verdicts stay honest | `tests/c09/e2e.py`, `neg.py`, `tests/c09/pins*.bend`, `laws/c09/` |
| Tessellation (C10) | Presets 0-3 with tess-budget-exceeded refusal; watertight output on admitted solids (G1 meshes) | `tests/c10/e2e.py`, `neg.py`, `tests/c10/pins.bend`, `laws/c10/` |
| Queries (C11) | Certified box disjoint/inside/interference, mass intervals (depth 0-6), section, wall, extrema; mesh clearance ESTIMATED only (G3-L8); clearance lower bounds 0 | `tests/c11/e2e.py`, `neg.py`, `tests/c11/pins.bend`, `laws/c11/` |
| Interchange (C12) | STEP/AP242 and STL/3MF export, `.bcd` archive with envelope checks, STEP import of analytic solids; no CONICAL_SURFACE on write (G3-L5); corrupted input refused, nothing written | `tests/c12/e2e.py`, `neg.py`, `tests/c12/pins.bend`, `laws/c12/` |
| Assemblies (C14) | Exact linear solve with dof, coinc/axis/plane/fix mates, interf/clear/explode/faces; conflicts publish no solution | `tests/c14/e2e.py`, `neg.py`, `tests/c14/pins.bend`, `laws/c14/` |
| PMI (C15) | check/stack/toler over declared states, AP242 export; stacks cannot negate a dimension | `tests/c15/e2e.py`, `neg.py`, `tests/c15/pins.bend`, `laws/c15/` |
| Sheet metal (C16.1) | Flat and single-bent sheet, bends 90/180, one hem, K-factor zones; D-sheet-* refusals named | `tests/c16.1/e2e.py`, `neg.py`, `tests/c16.1/pins.bend`, `laws/c16.1/` |
| Surfaces (C16.2) | Patch/loft/sweep-open shells, sweep 90/180/270, thicken-open; `surf` is the certified reporter; patch area ESTIMATED within 1% (D-surf-est); no 360 tubes (D-surf-360) | `tests/c16.2/e2e.py`, `neg.py`, `tests/c16.2/pins.bend`, `laws/c16.2/` |
| Blades (C16.3) | Ruled NACA4 stacks, 2-8 sections, twist 0/10/20/30, taper 50/75/100, 17/33/65 points; section props certified over the stored NPTS-gon (D-blade-curve); no lean/sweep/features (D-blade-lean, D-blade-feat) | `tests/c16.3/e2e.py`, `neg.py`, `tests/c16.3/pins.bend`, `laws/c16.3/` |
| Errors/resources (C13) | Structured `error KIND | ...` envelope (6 kinds) and `refused WHY | ...`; `--max-nodes`/`--cancelled` gate design verbs; `diagnose` JSONL; MCP diagnostics + timeout-as-cancelled; printed verdicts exit 0 | `tests/c13/errors.py`, `tests/c13/pins.bend`, `laws/c13/`, `docs/c13-errors.md` |
| Corpus (C13) | 13 versioned members, every one double-built and byte-compared: G3 parts, sheet/surf/blade designs, scale sweep, mixed assembly, ring arcs, corrupt inputs, crash recovery, 40-edit sequence | `tests/c13/corpus.py`, `docs/c13-corpus.md` |
| Regression gate (C13) | Every runner discovered by filename, fresh-report rule, binary-swap block; perf budgets block release | `tests/c13/gate.py`, `tests/c13/perf.py`, `tests/c13/e2e.py`, `docs/c13-regress.md` |

Known limits that bound the rows above are the registry
`docs/c13-limits.md` (G3-L*, D-*, C13-*); each names the first gate
needing the fix.

## 3. C13 exit checklist

| Exit requirement (MASTER_PLAN §10) | Where it is |
|---|---|
| Stable CLI | `src/c06/cli.bend` design verbs + `geom`, flags `--max-nodes`/`--cancelled`, `diagnose`; error grammar in `tools/mcp/language.md` § Errors |
| Documented SDK/native boundary | `tools/mcp/language.md` (admitted domains + refusals), `tools/mcp/bendcad-mcp.mjs` (35 tools, diagnostics, timeout, caps) |
| Reproducible builds | `~/bin/bendbuild` from `src/c06/cli.bend`; binary sha256 recorded in every report (§4) |
| Structured errors | `src/c13/err.bend`, `docs/c13-errors.md`, sweep ratchet in `tests/c13/errors.py` |
| Resource/cancellation | `src/c13/req.bend` gate (cancel > budget > dispatch), per-op tess/mass/blob/STEP budgets, MCP timeout |
| Diagnostics | `diagnose` verb (JSONL), MCP `diagnostics` array, `diagnose` MCP tool |
| Compatibility tests | Oracle re-reads in the e2e suites (OCCT/FreeCAD/PlaneGCS as test-only comparators), STEP round-trips, `step.slanted` regression journey |
| Versioned corpus | `tests/c13/corpus.py` + `docs/c13-corpus.md` covering scales, repeated edits, mixed analytic/NURBS, corrupted input, crash recovery, long sequences |
| Perf regressions block | `tests/c13/perf.py` + `perf-budget.json`, gate doctrine `docs/c13-regress.md` |

## 4. Measured counts (final binary 6b0bd9d5)

Laws 575/575 both modes (20/20 packets). Mutants 145/145 killed.
Pins 2569/2569 over 23 files. Journeys 996/996 over 29 suites
(958 pre-C13 re-proven + 38 new: corpus 13/13, e2e 5/5, errors 14/14,
perf 6/6). G3 v3 `parts`: 4 stages committed,
`asm solved ninst 119 nmates 122 dof 0 max-residual 8.526512829121202e-14`.
Full table: `docs/receipts/c13-2026-10-15.txt` §§2–5.
