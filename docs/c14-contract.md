# C14 contract — assemblies with solved mates and certified queries

Scope (MASTER_PLAN §10 C14): components, placements, mates/joints and
kinematic degrees of freedom, reusing the C05 solver's rank/dof
machinery; interference and clearance through C11 queries with certified
status; exploded views; assembly-level lineage and durable selectors.
One `asm` CLI verb plus one MCP `assembly` tool. Orientations are fixed
per instance (the `move` turn code); mates solve translations exactly as
a linear system. No existing CAD kernel is used at runtime; E2E oracles
are hand-derived analytic expectations computed by no kernel code path.

## Laws and pins (A6)

Laws: `laws/c14/LAWS.bend`, proven in `laws/c14/PROOF.bend`. All 153
quantify over their inputs and pass both the checker and the Lean-proven
kernel (`bash tools/laws/check.sh`; MASTER_PLAN A6). Nineteen planted
mutants are all killed (`python3 tools/laws/mutate.py`).

Pins: `tests/c14/pins.bend`, 164 fixed-input `__got`/`__want` pairs run
as compiled code (`bash tools/pins/run.sh tests/c14/pins.bend`): parse,
mate arities, solver rows, residual audit, renders, and dispatch. Every
want was hand-derived from `src/c14/asm.bend` before running.

## 1. Files

| File | Role |
|---|---|
| `src/c14/asm.bend` | Assembly kernel: s-expr parse, mate rows, C05 solve, residual audit, pair queries, explode, faces, dispatch (`asm_go`) |
| `src/c06/cli.bend` | `asm` command (code 22) dispatching to `AS.asm_go`, help text |
| `tools/mcp/bendcad-mcp.mjs` | One `assembly` tool with CLI-identical text |
| `tools/mcp/language.md` | Assemblies language section |

## 2. Assembly text format (normative)

The assembly is one `(assembly ...)` s-expr, solved fresh on every call,
so design edits propagate through it. Entries are instances or mates in
any order; anything else refuses with `unknown-assembly-entry`. An
assembly with no instance refuses with `assembly-needs-instance`; a
non-form refuses with `assembly-parse-failed`.

`(inst NAME NODE TX TY TZ Q)` names an instance of design node `NODE`
with initial translation and turn code `Q` (0–5, as `move`). Names must
be distinct (`duplicate-instance`); `Q` out of range or a non-finite
number refuses with `bad-instance`. A mate naming no instance refuses
with `unknown-instance`; an instance naming no design node refuses with
`unknown-node <inst>`; an instance naming a failed node refuses with
`error: node <N>; nothing assembled`. Mate ids are `U64`.

## 3. Mate kinds (normative)

| Mate | Rows | Meaning |
|---|---|---|
| `(fix ID INST)` | 3 | Pin the instance to its declared translation |
| `(coinc ID A AX AY AZ B BX BY BZ)` | 3 | Point A in A's node frame coincides with point B in B's node frame; A and B must differ |
| `(plane ID INST BX BY BZ NX NY NZ D)` | 1 | The instance point lies on world plane `NX x + NY y + NZ z = D`; the normal must be nonzero |
| `(axis ID INST BX BY BZ PX PY PZ DX DY DZ)` | 2 | The instance point lies on the world axis through `P` along `D`; the direction must be nonzero |

Wrong arity, a self-coincidence, a zero normal, a zero direction, or a
non-finite number refuses with `bad-mate` and a fix naming the exact
expected shape. Node-frame points are mapped to world offsets through
the instance's fixed orientation before rows are built.

## 4. Solve semantics (normative)

Unknowns are the 3 translations per instance in instance order (`col_of`
packs three per instance). `asm_rows` concatenates every mate's rows;
`decl_ts` is the declared-translation vector. The system solves through
the C05 machinery: `Q.rank` for rank/redundancy, `Q.lsq_nt` over
`Q.nd_order` for the least-squares solution.

- `dof` is `3n − rank`. Redundant mate ids are reported (`redundant
  [...]`); an empty list renders `[]`.
- Every row's residual is audited against a 1e-9 relative bound
  (`row_bad`: `|e + r| > 1e-9 * (1 + max(|e|, |r|))`). Any violating row
  makes the verdict `AS_conf` with the violating mate ids, rendered as
  `asm conflict ... viol [...] max-residual <r>`, publishing no
  placements and no lineage.
- Zero rows (no mates) is `underconstrained`: the declared translations
  are the one reported configuration with `dof = 3n`.
- Reports render `asm solved|underconstrained ninst <n> nmates <m> dof
  <d> max-residual <r>`, one `inst <name> node <N> t=<x> <y> <z> q=<Q>`
  line each, `redundant [...]`, and `lineage asm(<name>=n<N>,...)
  mates[...]`.

## 5. Query paths (normative)

All queries solve first and act on the solved placements; a conflict or
refusal on the solve path refuses the query the same way.

- `interf`: every unordered instance pair through C11 `QI.rel_s`,
  rendered `pair <a> <b>` plus `relation disjoint|interference status=
  certified ...` or the honest `relation uncertain status=estimated
  ...`. Touching boxes report what C11 reports; claiming no interference
  the kernel cannot certify is forbidden.
- `clear`: every pair through C11 `QD.clear_s`, rendered `clearance
  [<lo>, <hi>] estimated lo=certified ...` or `clearance 0 status=
  certified state=interference`.
- `explode DX DY DZ GAP`: solved placements offset by `k * gap * dir`
  for instance index `k`, rendered `asm exploded ninst <n> dir=<dx>
  <dy> <dz> gap=<g>` plus `inst` lines. A non-finite or zero direction
  refuses with `need DX DY DZ GAP finite with a nonzero direction`.
- `faces INST`: assembly-qualified durable face names
  `INST.n<node>.c<gen>.top|bottom|wall.<i>.<j>` with surface kind and
  loop counts, rendered one per line. A missing instance name refuses
  with `need an instance name`; an unknown one with `unknown-instance
  <name>`.

## 6. Refusal catalog

Dispatch: `unknown verb`. Parse: `assembly-parse-failed`,
`assembly-needs-instance`, `bad-instance`, `duplicate-instance`,
`unknown-assembly-entry`, `bad-mate`, `unknown-instance`,
`unknown-node <inst>`, `error: node <N>; nothing assembled`. Solve:
`asm conflict ... viol [...]` with `fix: loosen or correct the
violating mates`. Explode: `need DX DY DZ GAP finite with a nonzero
direction`. Faces: `need an instance name`, `unknown-instance <name>`.
Every refusal leaves the design file byte-unchanged and publishes no
geometry; neg journeys assert both.

## 7. Complexity and latency budgets

Parse is O(entries); row build is O(mates); declared translations are
O(instances); the C05 rank/lsq runs over 3n unknowns; the residual audit
is O(rows); pair queries run one C11 query per unordered instance pair;
explode and faces are O(instances) and O(faces). Budgets: `solve` under
30 s, `interf`/`clear` under 60 s (they inherit C11 subdivision cost on
near-touch pairs), `explode`/`faces` under 10 s. Measured numbers land
in the receipt; a regression past budget blocks the packet.

## 8. Deferrals

D-rot: orientations are fixed per instance; mates solve translations
only. Full rigid-body mates (rotation solving, revolute/prismatic and
other joint types) are deferred. D-g3: no G3-gearbox assembly journey
exists; the exit's assembly mechanics are proven on box/hole fixtures
and the rung still needs C15 stack-ups. D-tol-stack: interference and
clearance are evaluated at nominal placements, not across the tolerance
envelope and operating states (C15/state-dependent geometry owns that).
D-motion: underconstrained assemblies report one configuration; motion
sweeps and joint limits are deferred (explode is a static offset, not
motion). D-axis-law: the exact kind-4→`rows_axis` identity law is
deferred to pins/E2E (the arity law plus pins and the plane+axis journey
cover it). D-buildmem: the -O3 compile now peaks between 17G and 18G on
a 19G WSL box; raising the WSL cap toward 32G host RAM, or backend
no-fuse work in the bend repo, is needed before the next packet's growth.
