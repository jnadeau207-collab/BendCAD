# C08 adversarial findings — triage + closeout

Status: triaged, then fixed and verified per
docs/receipts/c08-2026-10-08.final.txt (closeout with recorded
deferrals). The triage bodies below are kept verbatim as history;
authoritative per-finding verdicts are in "Closeout verdicts".
Packet scope: `src/c08/bool.bend`, C08 wiring in
`src/c06/{model,sx,cli,zone}.bend`, C07 changes in
`src/c07/{emb,xs}.bend`, `src/c04/types.bend`,
`laws/c08.bend`, `laws/c08_build.bend`, `tests/c08/e2e.py`.
Prior workflow child results carried no inspected evidence
(all four summarized as "structured result submitted"),
so every item below was re-derived from the cited bodies.

Method: full read of `src/c08/bool.bend` (1948 lines),
`tests/c08/e2e.py`, `laws/c08_build.bend`, the C08 diffs to
C04/C06/C07 files, and the consumed C07 contracts
(`classify_in` codes, `emb_fi`/`solid_fi` finding vocabulary,
`pl_exact`, `sin_cos_deg`, `vdisj`, cache keys, zone/sens);
plus execution where cheap (see Evidence).

## Evidence state (read first)

- `bend laws/c08.bend --check-only` → **SOME PROOFS FAIL**
  (elaboration error, finding F1). 0 of 371 laws checked.
- `bend src/c08/bool.bend --check-only` → ALL PROOFS CHECK
  (module elaborates; it carries no laws itself).
- `bend laws/c08_build.bend --check-only` → launched during
  triage; still running with no output after 30 minutes,
  terminated at triage scope. Outcome unobserved — rerun as
  part of F1/F8 (if it is merely slow, run it detached per
  the AGENTS.md protocol; if it hangs, that is itself a
  finding against the `_build` laws).
- Installed `/home/jesse/bc/bendcad` (2026-10-07 00:06)
  predates C08: `(union 1 3)` → `unknown-op`. No
  `tests/c08/e2e-report.json` exists. **No C08 runtime
  behavior has ever been observed.** Every "predicted"
  below means: derived statically, awaiting a fresh binary.
- Law/source sha256 at triage time:
  `e956513d…` laws/c08.bend, `03de4082…` laws/c08_build.bend,
  `afa4323d…` src/c08/bool.bend (full hashes in /tmp/c08-sha.txt).

## Closeout verdicts (2026-10-08 final; evidence in the receipt)

Binary 7bf6ac88 (HEAD fd5694e + uncommitted src/c07/mem.bend seam
fix): c08 e2e 106/106, c08 neg 20/20, c06 e2e 55/55, c07 e2e
328/328, c07 solid 34/34, c07 zone 33/33; laws/c08.bend ALL PROOFS
CHECK (477 laws); src/c08/bool.bend ALL PROOFS CHECK.

- F1 FIXED+VERIFIED (laws elaborate, all check).
- F2 FIXED+VERIFIED (fresh binary, e2e 106/106).
- F3 FIXED+VERIFIED (bake-first world boxes; moved chain green).
- F4 FIXED+VERIFIED (interval-placement refusal; exact rotated).
- F5 FIXED+VERIFIED (piercing discriminator; cross.* refuse,
  tangent publishes).
- F6 FIXED+VERIFIED (endpoint exclusion; contact.face/edge/
  vertex publish).
- F7 FIXED+VERIFIED (du x dv triples; orientation laws pass).
- F8 PARTIAL (runtime regression green; law sweep partial:
  c00 38/38, c01 34/34, c02 52/52, c03 417/418, c04 603/603,
  c05 58/65, c06 80/80, c06_build 12/25, c07 13/14, c07_build
  12/17; canonical single-file records missing for c02–c08).
  No C07 law edited to match new behavior.
- F9 FIXED+VERIFIED (unknown-finding mapping; laws pass).
- F10 FIXED+VERIFIED (bx_widen; framestep assertions green).
- F11 FIXED+VERIFIED (arm-parity laws pass).
- F12 FIXED+VERIFIED (Del lineage + faces -v; asserted).
- F13 RENDERING FIXED+VERIFIED (.cav. parity law); resolve
  CLI/MCP wiring DEFERRED (ledger-recorded).
- F14 FIXED+VERIFIED (ambiguity laws PASS).
- F15 FIXED+VERIFIED (disjoint proof boxes; asserted).
- F16 PARTIAL (40 ev_* laws written; checker 6 PASS / 7 TIMEOUT
  / 27 unrun / 0 FAIL; all 40 oracles behaviorally green).
- F17 FIXED+VERIFIED (neg.py 20/20).
- F18 FIXED+VERIFIED (curved/tangent/tangent_cyl green).
- F19 FIXED+VERIFIED (chained/moved/mixed-relations green).
- F20 FIXED+VERIFIED (mirror/kiss incl. inside-touch green).
- F21 FIXED+VERIFIED (L20 every case; sens flip refusal;
  replay bit-identity). No sens code bug; path unchanged.
- F22 OPEN, DEFERRED to a perf packet (contact 10.39 s,
  identical 16.53 s, slanted 100.37 s vs <1 s budget; causes
  localized, no cheap certified win; packet plan in receipt).
- F23 FIXED+VERIFIED (xb_bo constructor laws PASS).
- F24 FIXED+VERIFIED (Maybe skip + coin_contact; check green).
- F25 FIXED+VERIFIED (language.md + ledger C08 rows present).
- P0-NEW (sampling) FIXED+VERIFIED: (a) committed edge-midpoint
  sampling + 12 laws + tangent_cyl/neg cases; (b) uncommitted
  roots_go closed-seam dedup in src/c07/mem.bend (tangent_cyl
  99/106 FAIL → 106/106 PASS; open curves unaffected).

Deferrals: c08_build checker verdicts 34/40 (D1), F22 packet
(D2), canonical c02–c08 single-file records (D3), laws/c07.bend
full verdict (D4, pre-existing slowness), solid_neg 11/13
pre-existing stale expects at HEAD (D5, out of scope), resolve
wiring (D6). C11 scope (crossing fusion, per-solid measures,
certified interval placements) refused loudly, not deferred.

## Ordered fix list (triage history; verdicts above win)

### F1 (P0, blocker) — `laws/c08.bend` does not elaborate; zero laws checked

- Severity: P0 (blocks all Layer A/B evidence; L17/L19).
- File:line: [laws/c08.bend](/mnt/c/dev/BendCAD/laws/c08.bend:80) (`src_op`).
- Failing input: `bend laws/c08.bend --check-only`.
- Expected vs actual: expected `ALL PROOFS CHECK`; actual
  `SOME PROOFS FAIL`: "a parameter or field scrutinee (a match
  cannot scrutinize a computed value)" at
  `M.Pt{ps, ns} = S.part_of(ps_xs(S.parse(src)))`.
  The helper is used by the last three laws (`sx_parse_*`),
  so the whole 371-law file is unchecked, including the D2
  discriminating laws and the `emb_ee_*` contact laws.
- Concrete fix: bind then match:
  `+p = S.part_of(ps_xs(S.parse(src)))` /
  `M.Pt{ps, ns} = p` (or match on `p`). Re-run
  `--check-only`; record the outcome. Then audit for further
  failures the checker stopped short of.

### F2 (P0, blocker) — no binary contains C08; the E2E suite never ran

- Severity: P0 (blocks every runtime claim in §13 and every
  "committed journey" in `tests/c08/e2e.py`).
- File:line: [tests/c08/e2e.py](/mnt/c/dev/BendCAD/tests/c08/e2e.py:1)
  (missing `tests/c08/e2e-report.json`); binary
  `/home/jesse/bc/bendcad`.
- Failing input: any C08 op on the installed binary, e.g.
  `(node 4 (union 1 3) (intent add 0 0 2 0))`.
- Expected vs actual: expected boolean evaluation; actual
  `error invalid-input | union @ node 4 | why: unknown-op`.
- Concrete fix: build a fresh binary from this tree
  (`bend src/c06/cli.bend -o <out>`), run
  `BENDCAD_BIN=<out> python3 tests/c08/e2e.py`, commit
  `tests/c08/e2e-report.json`. Expect red on first run
  (F6 predicts the three contact journeys fail); triage the
  red before any closeout claim. Do this before all other
  runtime fixes.

### F3 (P0, silent wrong result) — stale stored bbox on placed boolean results defeats the broad-phase

- Severity: P0 (silent wrong geometry; L1/L2/L20).
- File:line: [src/c08/bool.bend](/mnt/c/dev/BendCAD/src/c08/bool.bend:1923)
  (`run_broad` trusts `In.bb`); [src/c06/model.bend](/mnt/c/dev/BendCAD/src/c06/model.bend:1019)
  (`op_move`/`op_rot` preserve `xb_mx` verbatim).
- Mechanism: non-boolean bodies recompute world-frame measures
  on demand (`body_mx` empty-`mx` path → `prism_ms`, which is
  placement-aware). Boolean results instead store
  `bool_stored_ms` (`Xb.mx`, model.bend:1219). A later
  `move`/`rotate` keeps the stored box, so `In.bb` is in the
  pre-move frame while the baked brep is in the world frame.
  `bx_disjoint` on mismatched frames can claim "proven
  disjoint" over truly overlapping solids.
- Failing input:
  `(node 1 (box 10 10 10))`, `(node 2 (box 10 10 10))`,
  `(node 3 (move 2 20 0 0 0))`,
  `(node 4 (union 1 3))` → stored bb ≈ [0,30] (world, correct
  at creation), `(node 5 (move 4 100 0 0 0))`,
  `(node 6 (box 10 10 10))`, `(node 7 (move 6 100 0 0 0))`,
  `(node 8 (intersection 5 7))`. Local/stale boxes [0,30] vs
  [100,110] read disjoint.
- Expected vs actual: expected carry/refusal per true overlap
  (world boxes both ≈ [100,130]); actual: `intersection`
  publishes the empty compound, and the mirrored
  `difference` would silently carry A. (`union` is saved by
  `append_valid` re-validation; `difference`/`intersection`
  short-circuit without it.)
- Concrete fix (defense in depth, do both): (a) in `run_broad`,
  bake first and recompute operand world boxes from baked
  vertices (widened by rounding + `bake_lin`), never trusting
  `In.bb` for the disjoint decision; (b) in `op_move`/`op_rot`,
  refresh a non-empty stored `Ms` bbox through the placement
  delta (`pl_bb` exists for exactly this). Add a regression
  journey chaining boolean → move → boolean with an L20
  assertion. Note `measure` on a moved boolean also shows the
  stale box today (same root cause, display-only).

### F4 (P1, uncertified results) — interval placements are baked at the midpoint and consumed as truth

- Severity: P1 (certification hole; intent section 5
  placed-operands clause: "classification consumes the
  certified placement, not the display midpoint").
- File:line: [src/c06/model.bend](/mnt/c/dev/BendCAD/src/c06/model.bend:1194)
  (`bool_in` takes `pl_m`/`pl_tx..tz`, i.e. midpoint only);
  [src/c08/bool.bend](/mnt/c/dev/BendCAD/src/c08/bool.bend:1761)
  (`bake_of`). Placement intervals exist (`Pl.mi/ti`,
  `rot_im`, model.bend) but `In` does not carry them.
- Failing input: the committed `rotated` journey
  ([tests/c08/e2e.py](/mnt/c/dev/BendCAD/tests/c08/e2e.py:314)):
  `(rotate 2 z 45)` then boolean. `sin_cos_deg` is exact only
  at 90-degree multiples ([src/c06/iv.bend](/mnt/c/dev/BendCAD/src/c06/iv.bend:139));
  at 45 degrees the placement is an interval (`pl_exact` false,
  model.bend:382), so the true solid differs from the baked
  midpoint solid. A near-touching case can then classify
  definitively-but-wrongly — the header claim "bake rounding
  can only fail loudly" (bool.bend:32-38) is false for
  interval midpoints: rounding fails loudly, midpoint error
  does not.
- Expected vs actual: expected certified placement consumed,
  or refusal; actual: midpoint consumed silently, result
  published as certified.
- Concrete fix: thread `pl_exact` (or the interval radius)
  into `In`; refuse non-exact placements as `unsupported-op`
  (`interval-placement`, a C11 item) in `run_admit`.
  Convert the `rotated` journey to exact placements
  (quarter-turn `q` codes, 90-degree-multiple `rotate`) and add an
  inexact-angle refusal journey. Alternative (larger):
  widen boxes by the placement radius and fail on
  near-touch; still refuses, but covers more cases.

### F5 (P1, over-lenient) — cross-solid edge/face point hits are all admitted as contact, piercings included

- Severity: P1 (soundness-critical invariant unstated and
  untested; L1/L2/L4 depend on it).
- File:line: `src/c07/emb.bend`, `ef_hit` `H_pt` arm (C08
  diff): cross pairs map every point hit to
  `contact-edge-face` (info, admitted by `fi_partition`,
  bool.bend:1117, and CLI `fi_real`).
- Mechanism: a transverse piercing (edge of B through the
  interior of a face of A) reports the same code as a tangent
  touch. Soundness then rests on an unstated backstop: "every
  transverse edge/face piercing also yields a failing
  face/face finding (`face-penetration`) or an uncertain
  finding." That holds only if C07 face/face detection is
  complete (exact for planes; certified-or-uncertain for
  curved). No law states the invariant; no test pins it.
  Vertex sampling cannot save it: an edge can pierce with
  both endpoints outside the other solid.
- Failing input (adversarial probe to add): pole-through-box —
  A = `(box 10 10 10)` at origin, B = thin box spanning
  z in [-5,15] over x,y in [4,6] (boundaries genuinely cross);
  `(union A B)`, `(difference A B)`, `(intersection A B)`.
- Expected vs actual: expected `boundaries-cross-or-overlap`
  on all three (via the face/face backstop); actual today:
  unobserved (F2) — if the backstop ever misses, `union`
  silently publishes interpenetrating solids with a wrong
  volume (1080 vs true 1040 here) and a violated L20.
- Concrete fix, pick one: (a) sound discriminator in the
  cross `H_pt` arm: classify the edge's endpoints against the
  other solid (`SO.classify_in` is available); strictly
  inside implies piercing implies keep a failing code;
  outside-or-on implies contact. (b) Keep admission, but state
  the backstop invariant in `docs/c08-intent.md`, and pin it
  with adversarial E2E: pole-through-box, sphere-through-box
  and edge-through-cylinder must refuse; tangent
  sphere-on-plane and kissing spheres must publish. (a) is
  preferred: it does not borrow C07 completeness informally.

### F6 (P1, over-strict) — cross-solid edge/edge point hits always fail, breaking L9 contact publishing

- Severity: P1 (the three committed contact journeys are
  predicted to refuse; L9).
- File:line: `src/c07/emb.bend`, `ee_hit` `H_pt` arm (C08
  diff has no `cross` branch there): every point hit →
  `edge-crossing` (fail). The proximity exclusion `sv`
  requires shared vertex *indices* (`ee`, `sh_pt(s0/s1…)`),
  which never match across solids.
- Mechanism: broad-phase uses strict `idisj`
  ([src/c07/ivx.bend](/mnt/c/dev/BendCAD/src/c07/ivx.bend:26)),
  so endpoint-touching edge boxes are tested, the exact test
  returns `H_pt` at the shared vertex position, and the pair
  fails. This hits `contact.face` (box1 edge
  (0,0,0)-(10,0,0) meets box2 edge (10,0,0)-(10,10,0) at
  (10,0,0)), `contact.edge` (shared-edge endpoints), and
  `contact.vertex` alike.
- Failing input: the committed `contact` journeys
  ([tests/c08/e2e.py](/mnt/c/dev/BendCAD/tests/c08/e2e.py:157)).
- Expected vs actual: expected `add/2 solids` + `ok:` check;
  predicted actual: `boundaries-cross-or-overlap` refusal on
  all three (static derivation; confirm on the F2 binary —
  if any passes, record why, since the mechanism above says
  none should).
- Concrete fix: position-based endpoint exclusion for cross
  pairs only: in `ee`, when `cross`, build `sv` from both
  edges' endpoint *positions* (or map cross `H_pt` within
  `tol` of either edge's endpoints to `contact-edge-edge`
  info); interior-interior cross hits must still fail as
  `edge-crossing` (transverse crossings are real). Add laws:
  `emb_ee_cross_endpoint_is_contact`,
  `emb_ee_cross_interior_still_fails`. Note the asymmetry
  this leaves: edge/edge point touch fails-or-admits by
  position (fixed here), edge/face by F5 — keep the two
  consistent and cross-referenced.

### F7 (P1) — D2 fallback plane triples flip the normal sign

- Severity: P1 (silent wrong orientation on flat patches with
  degenerate first triples; breaks `same`-flag meaning,
  `sos_or` verdicts).
- File:line: `src/c07/xs.bend`, `bp_pick3`/`bp_pick4` (C08
  diff): fallback triples `(p00,p30,p33)` and `(p03,p30,p33)`.
- Mechanism: the primary triple yields
  (p03-p00)x(p30-p00), approximately du x dv, matching the
  patch. Triple 2 preserves the sign (du x (du+dv) = du x dv),
  but triple 3 gives dv x (du+dv) = -(du x dv) and triple 4
  gives (dv-du) x dv = -(du x dv). A flat patch whose earlier
  triples are collinear (sliver corners) gets an
  exactly-planar but exactly-flipped plane; downstream
  `M.M_pl` half-space/orientation verdicts invert. The
  all-16-points coplanarity check itself is sound (exact
  expansions; degenerate nets correctly None).
- Failing input: flat bicubic patch with p00,p03,p30
  collinear but the net planar and non-degenerate (e.g.
  p00=(0,0,0), p03=(1,0,0), p30=(2,0,0), p33=(2,1,0), rest
  coplanar on z=0); `gv_im` gives plane; use as a boolean
  operand face or check `sos_or` on a body containing it.
- Expected vs actual: expected normal approximately du x dv
  (patch orientation preserved); actual: negated normal.
- Concrete fix: swap the 2nd/3rd corner args in triples 3
  and 4 — `(p00,p33,p30)` and `(p03,p33,p30)` restore du x dv —
  or negate the resulting `E3`. Add the discriminating law
  (flat patch with collinear first triple; old code yields
  the flipped normal) and a `gv_im` orientation law pinning
  du x dv across all four arms.

### F8 (P1, process) — L19 full law check never ran on the modified tree; C07 behavior changed under C07's laws

- Severity: P1 (closeout blocker; L17/L19; AGENTS.md).
- File:line: `laws/c00.bend` … `laws/c08.bend` vs modified
  `src/c07/{emb,xs}.bend`, `src/c04/types.bend`,
  `src/c06/{model,sx,cli,zone}.bend`; no C08 row in
  `docs/receipts/`.
- Mechanism: C08 changes C07 semantics in three ways that
  C07 laws may pin: (a) `gv_im` on flat bicubic now returns
  `Some` (D2) where C07 membership was `uncertain` — any C07
  law asserting uncertain-on-bezier now fails; (b) `emb_fi`
  cross-solid pairs now report `contact-*` info where C07
  reported failures; (c) CLI `check_s` now filters `contact-*`
  via `fi_real` (cli.bend diff). Single-solid `emb` behavior
  should be identical (`cross=false` recovers old codes),
  but that is unverified. `shmap_of` (c04/types diff) is a
  pure addition and safe.
- Failing input: `bend laws/c07.bend --check-only` (and the
  c00..c08 full sweep) on this tree — never run.
- Expected vs actual: expected all-green with sha256
  recorded at launch; actual: unknown.
- Concrete fix: run the full sweep per the AGENTS.md detached
  protocol (record sha256 of law+source bytes at launch;
  mind the 19 GB WSL ceiling). Reconcile any C07-law red
  through owner review — C07 laws are binding on C07, so a
  C08-motivated change to a C07 law needs the same explicit
  review as a C08 law change (c08-laws.md preamble,
  MASTER_PLAN section 11). Do not "fix" red by editing C07
  laws to match new behavior without that review.

### F9 (P2) — unknown future finding codes mislabel as crossing/overlap instead of uncertainty

- Severity: P2 (wrong diagnosis; L4 fail-closed direction).
- File:line: [src/c08/bool.bend](/mnt/c/dev/BendCAD/src/c08/bool.bend:1783)
  (`intersect_fail` final else arm).
- Mechanism: the code partition (`is_contact`,
  `is_uncertain_code`, `is_unsupported_code`, bool.bend:182-193)
  is complete against today's C07 vocabulary (verified:
  every `Fi{` site in `src/c07/{emb,sol}.bend` maps to the
  intended arm). But an unrecognized code falls into
  `boundaries-cross-or-overlap` (unsupported-op) — including
  a future `*-uncertain` code, which L4 wants reported as
  `numerical-uncertainty`.
- Failing input: any future C07 code outside the three
  lists (no failing input exists today by construction).
- Expected vs actual: expected fail-closed toward
  uncertainty with the raw code preserved; actual:
  mislabeled as crossing/overlap.
- Concrete fix: in `intersect_fail`, map unrecognized codes
  to `fk_uncertain()` with `why` carrying the raw code
  (e.g. `unknown-finding: <code> ...`), keeping
  `boundaries-cross-or-overlap` for the known transverse
  codes. Add a law pinning one known code per arm plus an
  unknown-code case.

### F10 (P2) — stored result bbox ignores bake rounding

- Severity: P2 (low practical impact today: sub-ulp error
  cannot hide a macroscopic overlap; becomes load-bearing
  only combined with F3-class frame errors).
- File:line: [src/c08/bool.bend](/mnt/c/dev/BendCAD/src/c08/bool.bend:1804)
  (`append_out`: `bbx = bx_hull(bb, bb2)`);
  [src/c08/bool.bend](/mnt/c/dev/BendCAD/src/c08/bool.bend:1829)
  (`cavity_valid`: `bb` = minuend's box).
- Failing input: any append/cavity result: baked vertices
  can sit ~1ulp outside the input boxes (float bake
  arithmetic), so the stored box can be unsound by ~1ulp;
  a later broad-phase over 1ulp-touching boxes then
  misfires (outcomes stay correct for pure touch — union
  re-validates, difference-carry and intersection-empty are
  the regularized answers for touch — but the proof is void).
- Expected vs actual: expected outward-rounded stored box;
  actual: exact hull of input boxes.
- Concrete fix: widen the stored box by `bake_lin`-scale
  (one line: a `BX` widen helper applied in `append_out`
  and `cavity_valid`). Regression: framestep assertion that
  every result vertex is inside the stored box.

### F11 (P2) — `xf_gval` catch-all silently skips unlisted geometry arms

- Severity: P2 (landmine; fail-closed today via admit).
- File:line: [src/c08/bool.bend](/mnt/c/dev/BendCAD/src/c08/bool.bend:549)
  (`case _: g`).
- Mechanism: `G.GVal` has arms `xf_gval` does not transform
  (`GV_f/p/d/v2/dom/ts/tb`, c03/types.bend:70-87). Today
  `edge_code` (bool.bend:933) and `surf_admit` via `gv_im`
  (bool.bend:911) reject every unlisted arm before baking,
  so the catch-all is unreachable for admitted operands.
  But admitting a new arm later (edit `edge_code`, forget
  `xf_gval`) silently bakes a mixed-frame brep.
- Failing input: none today (unreachable by construction).
- Expected vs actual: expected bake total over the admitted
  domain by construction; actual: parity by convention.
- Concrete fix: add an arm-parity law (every `edge_code`-0
  arm and every `surf_admit`-0 arm has a non-identity `xf`
  arm), or restructure so an unhandled admitted arm is a
  type error rather than identity. One law, no runtime cost.

### F12 (P2) — deleted-input lineage is not recorded (L11)

- Severity: P2 (L11 requires deleted-with-reason; only
  survivors are stored).
- File:line: [src/c08/bool.bend](/mnt/c/dev/BendCAD/src/c08/bool.bend:277)
  ("Deleted input entities are derived: operand fns minus
  result fns"); `Out` (bool.bend:267) has no deleted field;
  `faces` lists survivors only.
- Failing input: `(difference big small)` cavity case:
  input faces survive-or-transplant, but nothing records
  which input entities were consumed as interior (and in
  crossing-fusion scope, which were classified away — the
  subtraction is not even well-defined once faces split).
- Expected vs actual: expected per-result record with
  `deleted` entries + reasons; actual: derivable only by
  the reader diffing two `faces` listings, with no reason
  codes.
- Concrete fix: add the deleted list (entity + reason:
  classified-away / regularized-away+report-entry / merged)
  to `Out` and the publish path; surface it in `faces -v`
  or a lineage report; E2E-assert deleted entries on cavity
  and carry cases. (In non-crossing scope most cases have
  empty deleted lists — assert that too; the field is the
  contract.)

### F13 (P2) — lineage selector unwired; two inconsistent lineage renderings

- Severity: P2 (L12 half-met; operator-visible inconsistency).
- File:line: [src/c08/bool.bend](/mnt/c/dev/BendCAD/src/c08/bool.bend:312)
  (`B8.fn_show` renders role 4 as `n4.cav.k.i.j`) vs
  [src/c06/cli.bend](/mnt/c/dev/BendCAD/src/c06/cli.bend:157)
  (`fn_s` renders role 4 as `n4.c0.wall.i.j`). `resolve`
  (bool.bend:358) has no CLI/MCP caller (verified by grep;
  §13 self-reports "wiring deferred").
- Failing input: `(difference big small)` cavity result,
  then `faces 4`: created cavity faces print as
  `n4.c0.wall.…`, indistinguishable in form from carried
  wall faces (only the node id differs), while kernel
  diagnostics (`res_show`) would print `n4.cav.…`.
- Expected vs actual: expected one rendering, and a wired
  resolve/miss surface per L12; actual: two renderings,
  no surface.
- Concrete fix: render role 4 distinctly in `fn_s` too
  (`.cav.`), add a rendering-parity law, and either wire
  `resolve` to a CLI/MCP surface or record the L12
  downgrade as an owner-review item at closeout (D4-lifting
  scope). Update the `containment.faces` E2E expectation to
  the unified form when fixed.

### F14 (P3) — `res_full` ambiguity arm drops the matching indices

- Severity: P3 (degraded loud failure; arm deemed
  unreachable while lineage prefixes stay unique).
- File:line: [src/c08/bool.bend](/mnt/c/dev/BendCAD/src/c08/bool.bend:341)
  (`res_full`: multi-match → `R_amb{[]}`).
- Failing input: any lineage with two identical full
  five-word patterns (unreachable today; reachable if split
  fragments ever share prefixes).
- Expected vs actual: expected `ambiguous (2 faces match)`
  with candidates; actual: `ambiguous (0 faces match)`.
- Concrete fix: accumulate matching indices in `res_full`
  (thread an `acc` like `res_pre_go`) and print them via
  `res_names`. One law with a duplicated-prefix micro-store.

### F15 (P3) — disjoint-proof boxes not recorded in the receipt

- Severity: P3 (intent §2.2: "the receipt shows the boxes").
- File:line: [src/c08/bool.bend](/mnt/c/dev/BendCAD/src/c08/bool.bend:1825)
  (`run_disjoint`); `Out` carries only the result hull.
- Failing input: any disjoint boolean: the published result
  carries no trace of the operand boxes that proved
  disjointness, so the proof is uncheckable post hoc.
- Expected vs actual: expected operand world boxes in the
  result/receipt; actual: result hull only.
- Concrete fix: include both operand world boxes in `Out`
  (or the publish report) for disjoint outcomes; E2E-assert
  their presence on the `disjoint` journey.

### F16 (P1, test gap) — no full-evaluation law covers the cavity transplant, contact, or any refusal

- Severity: P1 (L17 Layer B; the most complex code —
  `cav_build`/flip/transplant, bool.bend:1442-1469 — has
  zero closed-implementation theorems).
- File:line: [laws/c08_build.bend](/mnt/c/dev/BendCAD/laws/c08_build.bend:1)
  (16 laws: disjoint/identical/contained-union/inter, empty
  algebra, features, intent, zone, 2 volumes). Its header
  delegates contact/cavity/crossing to `e2e.py` — which
  never ran (F2).
- Failing input: N/A (missing coverage, not a red test).
- Expected vs actual: expected one law per full boolean
  evaluation per the file's own contract; actual: no law
  exercises `cavity`/`cav_build`, contact appends,
  crossing refusal, `difference`-contained-empties,
  `mixed-solid-relations`, uncertain classification, or
  any admit refusal (open-shell / nurbs / bezier-patch /
  edge-kind).
- Concrete fix: add, in this order:
  `ev_diff_contained` (cavity: `remove/6/0/1/0`, vol ∋ 7936),
  `ev_union_contact_face`, `ev_cross_union_refused`
  (verbatim `boundaries-cross-or-overlap`),
  `ev_diff_ainb_empty`, `ev_mixed_solids_refused`,
  `ev_nurbs_refused`, `ev_open_shell_refused`. Run them
  one-per-process in parallel per the C06/C07 `_build`
  precedent.

### F17 (P1, test gap) — no C08 negative suite (Layer C)

- Severity: P1 (L17; intent §11 requires one composed
  journey per §7 failure kind, each failing exactly one
  stage).
- File:line: `tests/c08/` (only `e2e.py`; no `neg.py`;
  cf. C07 `solid_neg.py` 13-composition precedent).
- Failing input: N/A — missing: `uncertain-classification`,
  `no-container-sample`, `inconsistent-classification`,
  `contact-not-certified`, `mixed-solid-relations`,
  `nurbs-operand`, `bezier-patch-operand`,
  `edge-kind-not-supported`, `open-shell-operand`,
  `operand-failed-check`, `validation-rejected`,
  `intersect-rejected`. (Crossing refusal and
  feature/intent failures exist as journeys/laws.)
- Expected vs actual: expected stage-isolated fixtures with
  verbatim diagnoses; actual: none.
- Concrete fix: add `tests/c08/neg.py` (or extend `e2e.py`)
  with one journey per kind above, asserting the failing
  stage follows §2 first-match-wins order. The
  `mixed-solid-relations` journey doubles as the
  multi-solid-operand test (F19).

### F18 (P1, test gap) — no curved-operand E2E at all

- Severity: P1 (§5 catalog, §10 exit "analytic cases pass").
- File:line: [tests/c08/e2e.py](/mnt/c/dev/BendCAD/tests/c08/e2e.py:1)
  (every journey uses boxes/prisms).
- Failing input: N/A — missing: cylinder/sphere/cone/torus/
  revolve operands in disjoint, containment, and contact
  configurations; tangent sphere-on-plane union (2 solids);
  kissing spheres; cylinder-in-cylindrical-hole line contact
  (the last two are §5-named cases).
- Expected vs actual: expected analytic curved coverage
  with volume oracles; actual: planar-only.
- Concrete fix: add journeys with closed-form volume oracles
  (sphere-in-box containment difference → curved-wall
  cavity; disjoint cylinder+sphere union; tangent
  sphere-on-plane union → 2 solids + empty intersection).
  These also pin the F5 backstop on curved faces.

### F19 (P1, test gap) — no chained-boolean or multi-solid-operand E2E

- Severity: P1 (§5 multi-region operands; D3 scope claims
  per-solid bookkeeping "stays exact").
- File:line: [tests/c08/e2e.py](/mnt/c/dev/BendCAD/tests/c08/e2e.py:1)
  (booleans feed booleans only in `empty_algebra`).
- Failing input: N/A — missing: boolean result as operand
  (union then difference), multi-region prism operand,
  multi-solid minuend with per-solid containers, and the
  F3 regression (boolean → move → boolean).
- Expected vs actual: expected exact cross-component
  fragment bookkeeping proven by journeys; actual:
  untested, including the `cav_conts` multi-container path
  (bool.bend:1195) and the `mixed-solid-relations` refusal
  (bool.bend:1884).
- Concrete fix: add journeys: (a) `(difference (union A B)
  C)` with C inside one append component; (b) multi-region
  prism operand; (c) mixed containment → verbatim
  `mixed-solid-relations`; (d) F3's moved-boolean chain.

### F20 (P2, test gap) — one-directional containment; thin-contact geometries untested

- Severity: P2 (§5 catalog rows).
- File:line: [tests/c08/e2e.py](/mnt/c/dev/BendCAD/tests/c08/e2e.py:125)
  (`containment` uses only the (big, small) order).
- Failing input: N/A — missing mirrored journeys
  (`union`/`difference`/`intersection` in (small, big)
  order, exercising `dec_ainb` outcomes: carry-B,
  empty, carry-A), touching-from-inside containment,
  and cylinder-in-hole line contact (both self-reported
  pending in §13).
- Expected vs actual: expected both operand orders and the
  two named contact geometries; actual: one order, planar
  contact only.
- Concrete fix: add mirrored containment journeys plus the
  two §13-pending geometries (kissing interior wall for
  union/intersection carry; difference must fail loud —
  pinched cavity — or publish per the documented rule).

### F21 (P2, test gap) — L20 asserted on one journey; sens-flip, replay-lineage unasserted

- Severity: P2 (L20/L13/L11/L14 corollaries).
- File:line: [tests/c08/e2e.py](/mnt/c/dev/BendCAD/tests/c08/e2e.py:96)
  (identity only on `disjoint`); `sens_cache` (e2e.py:302)
  tests the no-flip case only; `disjoint.reopen` asserts
  volume only.
- Failing input: N/A — missing assertions, not missing code.
- Expected vs actual: expected per L20 "on every E2E case"
  (`V(A∪B)+V(A∩B)=V(A)+V(B)` interval containment +
  closed-form-in-interval); expected sens refusal across a
  boolean topology flip ("no derivative: topology changes",
  the `fns_eq` arm, cli.bend:239); expected lineage
  bit-identity across serialization replay (L11); actual:
  one identity, one no-flip sens, volume-only replay.
- Concrete fix: assert L20 on containment/cavity, contact,
  and empty-algebra journeys; add a param-driven
  disjoint→overlap flip journey asserting sens refusal and
  cache-key rebuild (no stale topology); assert `faces`
  output identical across reopen.

### F22 (P2, closeout) — budgets, fuzz oracle, scaling curves unrun (L15/L16/L17-D)

- Severity: P2 (self-reported in §13 D3; closeout gates).
- File:line: intent §8 vs `tests/c08/` (no bench, no fuzz,
  no scaling suite).
- Failing input: N/A — missing: §8 small/medium latency
  budgets with re-measurement, 16-thread speedup on the
  medium case, 1,600-hole-plate scaling curve, differential
  fuzz vs the OCCT oracle (0 unexplained mismatches).
- Expected vs actual: expected receipts with curves and
  speedup; actual: E2E timings only (once F2 runs).
- Concrete fix: run the §8 suite as specified; record in
  the C08 receipt. If any budget fails, it blocks the
  packet like a failing law (L15) — only then profile the
  known O(n²) hot paths (`sm_dedup`, per-sample `ag_set`,
  `cav_fns_go`/`n_has` scans, `container_go` re-subsets).

### F23 (P3) — `vc` conflates "C08-assembled" with "validated" (D4 detector is naming-fragile)

- Severity: P3 (correct today; one future writer away from
  silently breaking features on plain bodies).
- File:line: [src/c06/model.bend](/mnt/c/dev/BendCAD/src/c06/model.bend:942)
  (`isBool = xb_vc(bd_xb(b))` → `feature-on-boolean-result`);
  only writer of `True` is `bool_body` (model.bend:1219;
  verified: `ck_go` stores `xb_id()` = False, moves/rotates
  preserve, CLI check does not mutate).
- Mechanism: carry returns the original body, so carry of
  plain stays False (features allowed, matching
  `empty.feature_on_carry_ok`) and carry of assembled stays
  True (refused per D4) — all consistent. The hazard is
  purely the name/contract: `vc` reads as "validated", so a
  future change marking C07-checked bodies `vc=True` would
  refuse features on them with no type error.
- Failing input: none today.
- Expected vs actual: expected an explicit boolean-origin
  flag; actual: overloaded validation bit.
- Concrete fix: rename to `bool_origin` (or add a second
  bit) with a law pinning exactly which constructors set it
  (`bool_body` True; `ck_go`/moves/carries preserve).

### F24 (P3) — phantom origin samples on loopless faces; CLI check weaker than the publish gate

- Severity: P3 (both fail-closed today; robustness notes).
- File:line: [src/c08/bool.bend](/mnt/c/dev/BendCAD/src/c08/bool.bend:974)
  (`lp_v0`/`fa_v0` default `Pt{0,0,0}`);
  [src/c06/cli.bend](/mnt/c/dev/BendCAD/src/c06/cli.bend:442)
  (`check_s`: C07 findings only, no C04, no `coin_contact`).
- Mechanism: (a) a face with no loops contributes a (0,0,0)
  sample to its solid's aggregate — unreachable after the
  intersect-stage `vcore`, because C04 `fas_kind_ok`
  requires exactly one outer loop per face (c04/ops.bend).
  (b) CLI `check` re-verifies less than the kernel publish
  gate (`vcore` = C04-minus-coin + contact coin + C07
  pair). Since `.bcd` files store ops (re-eval always
  re-runs the gate), no hole follows — but a reader trusting
  CLI `check` as "the L2 check" over-reads it.
- Failing input: none reachable today.
- Expected vs actual: expected total sampling and a
  re-verification matching the gate; actual: default
  samples, subset check.
- Concrete fix: (a) return `Maybe`/skip empty-loop faces in
  `face_pts` instead of defaulting to the origin (one law
  on a loopless micro-brep); (b) run `coin_contact`
  (same module, cheap) in CLI `check_s` so CLI
  re-verification matches the publish gate, and document
  that full C04 ran at publish.

### F25 (P3, docs) — language reference and replacement ledger lack C08

- Severity: P3 (intent §4, §11).
- File:line: `tools/mcp/language.md` (no
  union/difference/intersection; verified by grep);
  `docs/replacement-ledger.md` (no C08 rows; verified).
- Failing input: N/A.
- Expected vs actual: expected the three ops documented
  (syntax, intent form, diagnoses) and ledger rows
  (operation, mined source or "none mined", Bend
  implementation, laws, fixtures, limits); actual: absent.
- Concrete fix: write both at closeout; the `reference` MCP
  text must match the implemented diagnoses verbatim
  (F9/F17 verbatim strings).

## Explicitly checked and cleared (no finding)

- `classify_in` code convention (0 out / 1 in / 2 uncertain /
  3 boundary, sol.bend:304 `cl_pick` + `cl_go` default 2):
  matches C08's `ag_mask`/`ag_fold`/`cav_sample_go`
  assumptions exactly. No L4 gap here.
- Finding-code partition: every `Fi{` emission site in
  `src/c07/{emb,sol}.bend` maps to the intended
  contact/uncertain/unsupported/transverse arm. Only the
  unknown-code default is wrong (F9).
- Cache keys: `ev_nodes` (model.bend:1478) builds
  `op_w ++ it_w ++ key(base) ++ key(base2)` — both inputs'
  full keys included, satisfying L14 at the model layer;
  param edits rebuild by construction. `sens` topology-flip
  refusal via `fns_eq` (cli.bend:239) covers booleans
  generically (outcome flips always change kept `fns`).
- Zone: `z_go` refuses all three boolean ops and recurses
  through move/rot to the boolean base (zone.bend:126-128),
  so placed booleans refuse too. Matches the E2E.
- `sameab`+empty mixed arms in `empty_outcome`
  (bool.bend:1664-1694) are unreachable (same node id
  implies same body implies same emptiness) — harmless.
- `outcome_go` intersection both-keep arm is unreachable
  (`decide` maps both-in to 3 first) — defensive, harmless.
- Conics (intent §3 "edges") are rq-encoded (`gsx.bend:48`
  parses `conic` to `GV_rq`), which `edge_code` admits.
  No over-refusal.
- `prism_ms`/`rev_ms` are placement-aware and non-boolean
  bodies recompute measures on demand, so `In.bb` is
  world-frame sound except via F3's stored-`Ms` path.
- L9/L2 contact-validation qualification and D1/D3/D4
  scopings are recorded as owner-review items in §13;
  this triage takes no position beyond F8 (run the checks
  first) — except where the code contradicts the record
  (F6/F7, which are code bugs, not scope notes).

## Suggested fix order (by dependency)

1. F1 (unbreak laws) → F8 (full sweep; tells you what else
   is red, including F7's blast radius on C07 laws).
2. F2 (fresh binary + first E2E run; confirms F6, grounds
   F5/F18-F21).
3. F6 + F7 (unbreak contact publishing and flat-patch
   orientation; both block §5 rows).
4. F3 + F4 (close the silent-wrong/certification holes;
   each with its regression journey).
5. F5 (discriminator or documented+tested backstop).
6. F16 + F17 (Layer B/C coverage for everything above).
7. F18–F21 (catalog breadth + assertion depth).
8. F9–F15, F22–F25 (diagnoses, lineage, budgets, flags,
   display consistency, docs).



