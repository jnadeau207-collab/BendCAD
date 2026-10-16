# C13 structured errors and resources (S2)

One envelope, one gate, one parser. Every failure an agent can meet on the
CLI+MCP production paths is either a grammar line, a JSON line, or a frozen
legacy line, and `tests/c13/errors.py` fails if any error-shaped line falls
outside those three.

## Envelope

`src/c13/err.bend` owns the grammar. The text form is

```
error KIND | what @ where | why: ... | fix: ...
```

Request-level failures raised where no location is known omit the
`@ where` (`error KIND | what | why: ... | fix: ...`); both shapes are
grammar lines and both parse into MCP diagnostics (with `loc: null`).
Per-node failures carry a `node N: ` prefix before the grammar line;
both parsers strip the prefix and keep the node id.

with KIND and its stable machine code:

| KIND | Code | Meaning |
|---|---|---|
| invalid-input | 1 | Bad request: syntax, unknown node, out-of-domain argument |
| unsupported-op | 2 | Admitted language, refused construction (named why) |
| numerical-uncertainty | 3 | Could not certify; nothing published |
| nonconvergence | 4 | Iterative method did not converge |
| cancelled | 5 | Request cancelled before or during dispatch |
| resource-exhausted | 6 | Request exceeded its budget |

The JSON form carries the same fields plus the node id:

```
{"node":N,"ok":false,"code":C,"kind":"...","what":"...","loc":"...","why":"...","fix":"..."}
```

Strings are JSON-escaped (`"` and `\` short, C0 controls as `\u00XX`);
all other characters pass through. `{"node":N,"ok":true}` marks success.

## Verbs and flags

`diag` evaluates the design and prints one JSON object per node, one per
line, in evaluation order. Request-level refusals print a single line with
`"node":0`. An empty design prints nothing.

Flags come between the design and the verb and apply to that request only:

```
bendcad <design> [--max-nodes N] [--cancelled] <verb> [args...]
```

`--max-nodes N` refuses designs with more than N nodes with
`node-budget-exceeded` before anything is evaluated. `--cancelled` refuses
at once with `request-cancelled`; cancellation wins over budget. The
default cap is 2^64-1 (no design file can reach it). Unknown flags and bad
values are refused as `invalid-input` naming the token. Flags after the
verb are verb arguments, not flags. `new` accepts flags vacuously (nothing
is evaluated). The `geom` path takes no flags.

A printed verdict always exits 0; nonzero means the CLI never reached its
verdict (crash or unreadable file). Failure never publishes partial
geometry: refused `apply` leaves the design byte-identical, refused exports
write nothing, and refused queries print the refusal instead of measures.

## Gate

`src/c13/req.bend` decides every request in O(nodes): parse the flags,
count the node ids, refuse cancelled/over-budget before the first
evaluation. Laws in `laws/c13` prove the code range (index validity), the
exact-budget boundary (counts vs estimates, by induction), the zero-budget
refusal, and cancel precedence; each family kills its planted mutant.
Fixed shapes (codes, envelope, JSON, escaping, decisions, counts, flag
parses) are pinned in `tests/c13/pins.bend`.

## MCP

`tools/mcp/bendcad-mcp.mjs` maps every CLI call onto structured results:

- `diagnostics`: the parsed failures of the call (grammar lines with codes,
  `diag` JSON lines, `refused`/`unknown-command`/legacy/`rejected` lines
  with `code: null`). Successes carry `[]`. Informational lines are skipped.
- Timeout (`BENDCAD_TIMEOUT_MS`, default 600000) kills the CLI and reports
  `cancelled`/`cli-exceeded-timeout`; a signal death reports
  `cancelled`/`cli-killed-by-signal-SIG`. A nonzero exit with no envelope
  stays raw with `ok: false`.
- `BENDCAD_MAX_NODES`, when set, prepends `--max-nodes` to every design
  call (never to `geom`).
- New `diagnose` tool: the `diag` verb over MCP. `isError` is true for
  grammar, legacy, rejected and `"ok":false` lines alike.

## Legacy shapes (frozen)

Kept byte-stable by the neg suites; new code must not add more:

- `error: node failed; nothing <verb>` from queries and exports on failed
  or missing nodes (C11/C12 neg suites).
- `error: the nominal design fails at this node`, `error: unknown
  parameter P`, `no derivative: ...` from `sens`.
- `error: node N; nothing flattened|surfaced|bladed`, `node failed` from
  flat/surf/blade/faces paths.
- `rejected: the design was not changed` from refused `apply`.
- `error: node N...` tails inside asm/pmi reports.

## Re-run protocol

```
~/bin/bendbuild
BENDCAD_BIN=~/bc/bendcad python3 tests/c13/errors.py
```

The binary must be rebuilt from the tree before the run. The report is
`tests/c13/errors-report.json`. A new failure mode qualifies by extending
the sweep battery: if a new `error*`/`refused*` line does not parse, the
sweep fails until the grammar or the parser covers it. Later capabilities
re-run this file unchanged.

## Dead-code disposition

`src/c00/eval.bend` (Request/Budget/cancel/run) and `src/c05/arrange.bend`
are imported by no file under `src/` (verified by grep): they are not on
the CLI+MCP production paths. Both stay, with their green C00/C05
laws, pins and mutants, as grandfathered packets: deleting either would
orphan `laws/c00`, `laws/c05`, `tests/c00`, `tests/c05`, pins reports,
bench fixtures and mutant entries, which is a closeout decision, not S2
work. S2 adds no law over them. The gate reuses C00's staged-gate pattern
(cancel, then budget, then dispatch) in production shape; `solve.bend`
stays live via `src/c14/asm.bend`.

## Contracts

`E.line`, `E.code`, `E.json_ok`, `E.json_err`: O(fields). `E.esc`: O(n)
single pass with reverse accumulator. `R.over_ids`, `R.parse`,
`R.dec_of`: O(nodes) / O(argv) / O(1). `diag`: one `ev_part` plus O(nodes)
rendering. No per-request work is superlinear in the design.

## Version history

1 (2026-10-15): S2. Envelope, diag verb, flags, gate, MCP diagnostics,
12 journeys plus observed missing-file records.
