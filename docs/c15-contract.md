# C15 contract — semantic PMI and GD&T

Scope (MASTER_PLAN §10 C15): dimensions, tolerances and datum reference
frames bound to durable selectors, with ISO GPS / ASME Y14.5 semantics,
evaluated by E1 and exported with STEP AP242. One `pmi` CLI verb plus
one MCP `pmi` tool. No existing CAD kernel is used at runtime; E2E
oracles are hand-derived analytic expectations plus a suite-side
independent AP242 PMI reader computed by no kernel code path.

## 0. Interpretation decisions (owner unavailable)

E1 is named only at MASTER_PLAN:231 and defined nowhere in the plan,
docs, or code (verified by tree-wide search). AP242 appears only at
MASTER_PLAN:231/233. G4's exit mentions C15 while its Needs column
lists only analysis/C10–C11. The following decisions fix the contract;
each is recorded here rather than guessed silently:

- C15-INT1 (E1): E1 is the single existing evaluator path — `M.ev_part`
  nominal evaluation, `I.*` outward-rounded interval envelopes, and
  per-state similarity scaling. No second evaluator is built.
- C15-INT2 (AP242): a declared minimal semantic PMI profile (§5),
  FILE_SCHEMA `AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF`, with
  entity templates verified against the STEP Tools AIM EXPRESS library
  (steptools.com/docs/stp_aim). Full conformance classes deferred
  (D-ap242-full).
- C15-INT3 (envelope/states): 1-D stack-ups are certified over the
  envelope (interval arithmetic); per-state point verdicts are exact
  under the declared uniform-growth state semantics (similarity);
  envelope interference/clearance is an estimated widening with a
  documented estimator, never certified. This closes C14 D-tol-stack
  with the residual D-cert-env recorded in §8.
- C15-INT4 (evaluated kinds): `flatness`, `perpendicularity`,
  `parallelism` evaluate; every other tolerance kind is refused by
  name (A7 precedent). Modifiers: `rfs` only.
- C15-INT5 (G4 exit): drawings deferred (D-drawing). "An independent
  reader interprets identically" is evidenced by the suite-side
  independent AP242 PMI reader (§5) plus a geometry-section
  differential against the C12 `step` export.

## Laws and pins (A6)

Laws: `laws/c15/LAWS.bend`, proven in `laws/c15/PROOF.bend`. All
quantify over their inputs and pass both the checker and the Lean-proven
kernel (`bash tools/laws/check.sh`). Every law family kills its planted
mutant (`python3 tools/laws/mutate.py`). Fewer real laws beat many:
there are no accessor laws and no whole-body restatements.

Pins: `tests/c15/pins.bend`, fixed-input `__got`/`__want` pairs run as
compiled code (`bash tools/pins/run.sh tests/c15/pins.bend`). Every want
was hand-derived before running.

## 1. Files

| File | Role |
|---|---|
| `src/c15/pmi.bend` | PMI kernel: s-expr parse, selector/datum/dim resolution, conformance evaluation, stack-ups, per-state toler, AP242 entity block, dispatch (`pmi_go`, `pmi_file`) |
| `src/c12/stepw.bend` | Additive only: `sw_head42`, `sw_env42`, `sw_wrap42` (AP242 wrap with PMI block). No existing body is edited |
| `src/c06/cli.bend` | `pmi` command (code 23) dispatching to `PM.pmi_go`/`PM.pmi_file`, help text |
| `tools/mcp/bendcad-mcp.mjs` | One `pmi` tool with CLI-identical text |
| `tools/mcp/language.md` | Semantic PMI language section |

## 2. PMI text format (normative)

The PMI set is one `(pmi ...)` form, evaluated fresh on every call, so
design edits propagate through it. Entries are `(node N)` or
`(nodes A B)` plus item entries in any order; anything else refuses
with `unknown-pmi-entry`. A form with no node entry refuses with
`pmi-needs-node`; a non-form refuses with `pmi-parse-failed`; a second
node entry refuses with `duplicate-node`. Item names are atoms without
quote or backslash characters (refused by the entry's own gate).

`(node N)` selects the design node every selector resolves against
(`check`, `stack`, `step42`). `(nodes A B)` selects the toler pair.
A singular entry where a pair is required, or a pair where a singular
is required, refuses with `pmi-needs-node` and a fix naming the
wanted shape.
`N`/`A`/`B` naming no evaluated node refuses with `unknown-node N`;
naming a failed node refuses with `error: node N; nothing evaluated`
(`toler`: `nothing compared`).

Item entries:

- `(datum NAME SEL)` — datum `NAME` bound to durable face selector
  `SEL`, a face-name atom exactly as printed by `faces`
  (`nN.cK.top|bottom|wall.I.J`, `nN.cav.K.I.J`). Any resolved face kind
  is accepted. `SEL` resolving to no face refuses with
  `unknown-selector SEL`; a malformed entry refuses with `bad-datum`.
- `(dim NAME PARAM)` — size dimension bound to design parameter
  `PARAM`; nominal and zone come from the parameter's `Dm`. `PARAM`
  naming no parameter refuses with `unknown-param PARAM`.
- `(dim NAME NOM LO HI)` — size dimension with explicit numbers;
  non-finite numbers or `LO <= NOM <= HI` violated refuses with
  `bad-dim`.
- `(tol NAME KIND T SEL rfs D*)` — tolerance `NAME` of kind `KIND`
  with value `T` on face `SEL`, `rfs`, and datum references `D*`
  (DRF order = listed order). `T` must be finite and `>= 0`
  (`bad-tol`). `KIND` outside `flatness|perpendicularity|parallelism`
  refuses with `unsupported-tol-kind KIND`. A modifier outside `rfs`
  refuses with `unsupported-modifier M`. `flatness` with any datum
  refuses with `tol-kind-takes-no-datum` (schema WR1 forbids datum
  references on flatness). `perpendicularity`/`parallelism` with
  other than exactly one datum refuses with `tol-needs-one-datum`.
  Each `D` must name a datum (`unknown-datum D`).
- `(state NAME GROW)` — operating state: uniform growth `GROW`
  about the design origin. `GROW` must be finite and `> 0`
  (`bad-state`).
- `(stack NAME DIM...)` — 1-D stack-up over one or more dim entries.
  Zero dims refuses with `stack-needs-dim`; each `DIM` must name a
  dim entry (`unknown-dim DIM`).

Names are distinct per item kind (`duplicate-datum`, `duplicate-dim`,
`duplicate-tol`, `duplicate-state`, `duplicate-stack`). Entries are
validated in listed order; the first failure is reported.

## 3. Evaluation semantics (normative)

E1 (C15-INT1) is `M.ev_part` plus intervals plus similarity. All
queries resolve selectors against the freshly evaluated node bodies;
a refusal anywhere refuses the verb the same way.

- `check`: validates every entry, resolves every selector, and
  evaluates every tolerance. Report lines per entry plus
  `pmi node N items K` and `pmi ok K items`. Tolerance verdicts:
  - `flatness` on a non-plane face refuses with
    `tol-face-not-plane` (kind named). On a plane face the actual
    form error is exactly 0 (analytic plane): `conforms` iff
    `0 <= T`, `certified`.
  - `perpendicularity`/`parallelism`: target and datum faces must be
    planes (`tol-face-not-plane`, `tol-datum-not-plane`). The actual
    deviation is `extent * sin(dev)` as a certified interval: plane
    normals are unit-normalized with interval arithmetic, `sin(dev)`
    is `|dot|` (perpendicularity, exact sine of the deviation from
    90°) or `sqrt(1 - dot^2)` (parallelism), and `extent` is the
    certified face bounding-box diagonal over the face's vertices.
    `conforms` iff `hi <= T`, `violates` iff `lo > T`, else the
    verdict line reports `uncertain` with the interval. Degenerate
    input (no vertices, zero normal) refuses with
    `tol-degenerate-face`.
- `stack`: for every stack and every state (default: one `nominal`
  state at grow 1.0 when no state is listed): nominal is the F64 sum
  of dim nominals; the envelope is the interval sum of dim zones via
  outward-rounded `I.iadd`, scaled per state by `I.iscale`
  (`certified`). Report: `stack NAME nominal N envelope [LO, HI]
  certified` plus one `state ST [LO, HI]` line per state.
- `toler`: nodes A B with states (default `nominal`). The nominal
  relation block is `QI.rel_s` verbatim. Per state: the relation word
  is `QI.rel_pair` (similarity-invariant, exact under the declared
  state semantics) and clearance recomposes the C11 `clear_int`
  primitives identically (`QI.rel_interf`, `QI.sms_of`, `QI.wbox`,
  `QA.ab_ab_lo`, `QD.pts_min`), scaled by grow with outward rounding
  (`estimated lo=certified`, C11's vocabulary). Envelope lines are
  estimated, never certified: `envelope clearance [lo-W, hi+W]
  estimated widen=W` with `W` the total design zone width
  (sum of `hi-lo` over every design parameter), and
  `envelope relation WORD status=estimated widen=W` carrying the
  nominal verdict word.
- `step42 OUT`: validates exactly like `check` (resolution-level;
  `violates`/`uncertain` verdicts do not block export, entry errors
  do) and writes the AP242 file (§5). Any refusal writes no file.

## 4. Query paths (normative)

- `pmi check '(pmi ...)'`: §3 check report.
- `pmi stack '(pmi ...)'`: §3 stack report.
- `pmi toler '(pmi (nodes A B) ...)'`: §3 toler report.
- `pmi step42 OUT '(pmi ...)'`: §3 file write; prints
  `wrote OUT ap242 PMI <n> entities`.

## 5. AP242 export profile (normative)

`sw_wrap42` emits the C12 geometry section byte-identically (`sw_stage`
plus units plus envelope, with AP242 header strings and
`APPLICATION_PROTOCOL_DEFINITION` `managed_model_based_3d_engineering`/2020), then the
PMI entity block starting at base id `erent+20` (`erent` = geometry
entity counter), then the foot. Shared ids: length unit `erent`,
product-definition-shape `erent+10`, representation context `erent+16`.
Entity templates (verified against the STEP Tools AIM EXPRESS library;
partial entities in a complex instance in alphabetical order, the C12
convention):

- datum (3 entities): `(DATUM_FEATURE()SHAPE_ASPECT('df-NAME','SEL',#pds,.T.))`,
  `SHAPE_ASPECT_RELATIONSHIP('','',#df,#datum)`,
  `(DATUM('NAME')SHAPE_ASPECT('','',#pds,.F.))`.
- dim (9 entities): `SHAPE_ASPECT('size','NAME',#pds,.T.)`,
  `DIMENSIONAL_SIZE(#sa,'NAME')`, nominal/lower/upper measure items
  `(MEASURE_REPRESENTATION_ITEM()MEASURE_WITH_UNIT(LENGTH_MEASURE(v),#u0)REPRESENTATION_ITEM(tag))`
  each wrapped in
  `(REPRESENTATION(tag,(#mi),#ctx)SHAPE_DIMENSION_REPRESENTATION()SHAPE_REPRESENTATION())`,
  and
  `(DIMENSIONAL_CHARACTERISTIC_REPRESENTATION(#ds,#nom)INDEPENDENT_LIMITS_OF_LINEAR_DIMENSIONAL_SIZE_CHARACTERISTIC_REPRESENTATION((#lo,#hi)))`.
- flatness (3 entities): `SHAPE_ASPECT('tol-face','SEL',#pds,.T.)`,
  `(LENGTH_MEASURE_WITH_UNIT()MEASURE_WITH_UNIT(LENGTH_MEASURE(T),#u0))`,
  `FLATNESS_TOLERANCE('NAME','flatness',#mag,#sa)`.
- perpendicularity/parallelism (4 entities): face aspect and magnitude
  as flatness, `DATUM_REFERENCE(1,#datum)`, and
  `(GEOMETRIC_TOLERANCE('NAME','kind',#mag,#sa)GEOMETRIC_TOLERANCE_WITH_DATUM_REFERENCE((#dr))PERPENDICULARITY_TOLERANCE())`
  (resp. `PARALLELISM_TOLERANCE()`).

Items export in PMI listing order (datums, dims, tols interleaved as
listed). States and stacks are evaluation context and are not exported.
The independent reader (`tests/c15/ap242.py`, no kernel code) parses
these entities back and requires every datum identification, dim
nominal/zone, tol kind/value/target/datum to equal the requested PMI
exactly, every `#ref` to resolve, and parentheses balanced. Full
AP242 conformance classes are deferred (D-ap242-full).

## 6. Refusal catalog

Dispatch: `unknown verb`. Parse: `pmi-parse-failed`, `pmi-needs-node`,
`unknown-pmi-entry`, `duplicate-datum|dim|tol|state|stack`, `bad-datum`,
`bad-dim`, `bad-tol`, `bad-state`, `stack-needs-dim`, `unknown-param`,
`unknown-dim`, `unknown-datum`, `unknown-selector SEL`. Kinds:
`unsupported-tol-kind KIND`, `unsupported-modifier M`,
`tol-kind-takes-no-datum`, `tol-needs-one-datum`,
`tol-face-not-plane`, `tol-datum-not-plane`, `tol-degenerate-face`.
Nodes: `unknown-node N`, `error: node N; nothing evaluated|compared`,
`duplicate-node`, `step42-needs-output`.
Writer profile refusals (`step-*`) propagate from `sw_stage`. Every
refusal leaves the design file byte-unchanged and (`step42`) writes no
file; neg journeys assert both.

## 7. Complexity and latency budgets

Parse is O(entries); resolution is O(entries × faces); orientation
evaluation builds one Tb per queried body (O(verts+edges)) and walks
one face's coedges (O(coedges log n)); stacks are O(dims × states);
toler runs one C11 pair plus O(states); step42 runs `sw_stage` plus
O(PMI entities). Budgets: `check` under 30 s, `stack` under 10 s,
`toler`/`step42` under 60 s. Measured numbers land in the receipt; a
regression past budget blocks the packet.

## 8. Deferrals

D-ap242-full: full AP242 conformance classes (presentation PMI,
further geometric characteristics, assembly PMI, schema validation
against the MIM) beyond the §5 declared profile. D-cert-env:
certified envelope interference/clearance for general geometry
(parameter-box C11); the §3 envelope lines stay estimated until then.
D-drf-multi: multi-datum reference frames (datum-system simulation);
orientation takes exactly one datum. D-state-disp: non-uniform
displacement fields and per-node states; states are global uniform
growth. D-drawing: drawings carrying PMI (G4/G5 rung work).
D-buildmem (carried from C14): the CLI builds only via
~/bin/bendbuild (15G compile scope, spilling into the 24G swap);
raising the WSL cap or backend no-fuse work is needed before
further growth.
