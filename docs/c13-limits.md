# C13 kernel-limit registry

Every known kernel limit with the gate that needs it fixed. A limit is
fixed in the kernel; no gate works around one by changing the design
(`docs/gates/README.md`). Limits already recorded in
`docs/g3-gearbox-design.md` §3 or the C16 receipts keep their source; this
file adds the gate each one blocks and the limits the corpus build found.

## From G3 §3 (gearbox review)

| ID | Limit | First gate needing the fix |
|---|---|---|
| G3-L1 | Side-blind cell obstacles: features on the two faces of one cell interact even when they cannot meet in z; every bore chain must be cut from one side | G5: turbine discs and casings need bore chains from both sides |
| G3-L2 | Touching booleans keep solids separate; pads must lie strictly inside the face they grow from | G5: one-piece rotor group (GE Catalyst pattern in the G6 brief starts at G5-style rotors); G4 for impeller-shaft joints |
| G3-L3 | Pocket in a head over a shank grown beneath it is refused (socket-head screws unmodellable) | G5: engine assembly needs socket-head cap screws |
| G3-L4 | Ring pocket whose inner edge encloses a face hole is refused (no O-ring/gasket grooves) | G2: the pump-housing brief names a gasket groove |
| G3-L5 | STEP writer has no CONICAL_SURFACE | G5: convergent nozzle cone and bearing cones must export |
| G3-L6 | Thin tori (R/r beyond about 8-12) fail validation (no garter springs) | G5: lip-seal garter springs; G6 if G5 draws them as notes |
| G3-L7a | No threads (tapped holes and screws at nominal diameters) | G2: bolted flange; G4/G5 carry the same need if G2 nuts-and-bolts it |
| G3-L7b | No chamfers on pad edges | G5: blade edges and machined lead-ins; G4 if its DFM calls them out |
| G3-L7c | No side holes | G4: blower casing mountings; G5: engine mountings and instrumentation |
| G3-L8 | Meshing-gear disjointness and clearance estimated, not certified (C11) | G5: cold-and-running clearances must be certified, not estimated |

## From the C16 receipts (deferral IDs unchanged)

| ID | Limit | First gate needing the fix |
|---|---|---|
| D-sheet-z | Z/S doubles refused; U pairs must share direction | None on the ladder; closes with the Z-fold sub-packet |
| D-sheet-asym | Unequal U radii refused (bit-compared) | None on the ladder; closes with asymmetric-U tables |
| D-sheet-side | Width-edge bends refused | None on the ladder; closes with the width-edge construction |
| D-sheet-hembend | Flat-leg hems on bent parts and bends after hems refused | None on the ladder; closes with hem-aware bend tables |
| D-sheet-features | Pockets/holes on sheet bodies refused | None on the ladder; closes with sheet-feature pockets |
| OM-rtfloor | R/T floor at 1.0 is an industry minimum with margin; the true C04/C07 floor below 1.0 is unprobed | None on the ladder; probe when a design needs tighter radii |
| D-surf-queries | Only `surf` is the certified open reporter; mass/extrema/section/tess over open shells run uncertified | G4: blower volute panels need certified mass and section |
| D-surf-gensec | Sweep profiles are rect only; slanted (cone-wall) profiles refused | G4: volute and diffuser passages are not rectilinear |
| D-surf-thickcurv | No curved offsets; curved patches and cone-wall sectors cannot thicken | G4: casing walls need curved offsets |
| D-surf-360 | No closed tubes (360-degree sweep refused) | G4: inlet and discharge ducts; G5 for the tailpipe |
| D-surf-est | Patch area and boundary lengths are estimates (oracle-checked within 1%) | G6: HUMPHREY-1 flow-path surfaces at physics precision; G4/G5 may accept estimates labelled as such |
| D-surf-checkbez | Duct `check` carries the C09 bezier verdict instead of `ok:` | G6: full certification of the hot gas path; G4/G5 accept the honest verdict |
| D-blade-checkbez | Blade `check` reports `face-check-unsupported` on bezier walls plus one honest `orientation-uncertain` on non-prismatic stacks | G6: certified hot-section blades; G5 accepts the build-time certificate plus honest verdict |
| D-blade-curve | Section properties are certified intervals of the stored NPTS-gon, not the smooth curve | G5: KJ-66 blade sections at drawing precision |
| D-blade-feat | Features refuse on blades | G5: blade roots and shroud joints |
| D-blade-lean | Stack leans only through taper about the leading edge; no explicit lean/sweep | G5: real compressor/turbine blades lean and sweep |
| D-blade-cosine | Stations are uniform; no cosine clustering | G5: endwall resolution for tip-clearance work |
| D-buildmem | The CLI builds only via `~/bin/bendbuild` (15G compile scope, may spill into swap) | C13 itself (reproducible-builds exit); no ladder gate |

## Found by the C13 corpus build (new)

| ID | Limit | First gate needing the fix |
|---|---|---|
| C13-S1-none | The S1 corpus build added no new kernel limit: every member reuses CLI behaviour already proven green by the C06, C12 and C16 suites, and the G3 `parts` run is the committed v3 reference. Kernel limits encountered at corpus run time are recorded here with the `C13-R*` prefix. | — |
| C13-R1 | Booleans across the analytic/NURBS boundary are refused (`bezier-patch-operand`); mixed-domain parts must join as assemblies, not unions | G5: first gate likely to boolean NURBS flow surfaces into analytic stock in one part |
| C13-R2 | `~/bin/bendbuild` embeds its mktemp dir in the binary (`strings` shows `/var/tmp/bendbuild.XXXXXX`, same length every build); same-source rebuilds differ byte-wise at equal size, so the binary sha256 is per-build, not per-source | C13 closeout (reproducible-builds exit); fix by compiling from a stable path or `-ffile-prefix-map`, then rebuild twice and compare |

## Found by the C13 errors+resources build (S2)

| ID | Limit | First gate needing the fix |
|---|---|---|
| C13-S2-exitcode | Request failures print an envelope and exit 0; nonzero is reserved for crash/unreadable input. No `--json` flag or exit-code taxonomy yet. | C13 diagnostics if it wants either; no ladder gate |
| C13-S2-geomflags | The `geom` path takes no `--max-nodes`/`--cancelled`; only design verbs are gated. | Any gate needing bounded imports |
| C13-S2-crashraw | A CLI crash (nonzero, no envelope) surfaces raw via MCP with `ok: false` and no diagnostics. | C13 diagnostics |
| C13-S2-legacy | Legacy error shapes stay byte-stable for the neg suites (listed in `docs/c13-errors.md`); new code must emit grammar or JSON, ratcheted by the sweep. | — |
| C13-S2-nodebudget | `--max-nodes` bounds design size (node count), not work: `sens` evaluates 3x, tess/mass/STEP keep their own budgets. | Any gate needing work budgets |
| C13-S2-dead | `src/c00/eval.bend` and `src/c05/arrange.bend` are unreachable from CLI/MCP but kept with green C00/C05 laws+pins; deletion orphans laws, tests, pins, bench and mutants. | C13 closeout |

## Disposition rule

A gate that hits a limit not on this list stops, records it here with the
gate as owner, and the kernel is changed until the corpus member covering
that behaviour holds. C13 scope (corpus, errors, resources, diagnostics,
compat) fixes only what the C13 exit owns; geometry and certificate limits
stay with their gate.
