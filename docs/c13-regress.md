# C13 regression gates (S3)

One command re-qualifies the release. Future capabilities qualify by
re-running these gates, not by adding new ones: a new packet drops its
`e2e.py` / `neg.py` into `tests/<pkt>/` and the gate discovers it; a new
kernel behavior adds its artifact journey to `tests/c13/e2e.py` and its
bytes to the blessed baseline.

## The three gates

`tests/c13/gate.py` runs every discovered suite and blocks on any red:

```
BENDCAD_BIN=~/bc/bendcad python3 tests/c13/gate.py [substring ...]
```

Discovery is by runner filename (`e2e.py`, `neg.py`, `solid.py`,
`solid_neg.py`, `zone.py`, `corpus.py`, `errors.py`, `perf.py`) under
`tests/*/`, so files like `oracle.py` and `ap242.py` never run as
suites. Arguments filter by path substring (`gate.py c13` runs the C13
suites only). Each suite runs with a timeout (corpus 3h, perf 2h,
default 1h). A suite passes only if it exits 0, writes a fresh
`*-report.json` (mtime after the suite started, so a stale green can
never pass), and reports passed == total > 0. The gate hashes the
binary at start and end: a swap mid-run fails the whole gate.
Per-suite hashes that differ from the gate binary (suites that build
their own binary, like `solid_neg`) are recorded as `foreign_hashes`,
not failures. The report is `tests/c13/gate-report.json`.

`tests/c13/e2e.py` pins canonical bytes. Five journeys build the G3 v3
reference gearbox (`tools/g3/gearbox.py <out> parts`: 4 stages
committed, `asm solved ninst 119 nmates 122 dof 0`) and the C16 sheet,
surface and blade designs, then compare every artifact byte-exactly
against the blessed baseline:

```
BENDCAD_BIN=~/bc/bendcad python3 tests/c13/e2e.py [--bless] [substring ...]
```

Text artifacts (designs, eval/show/flat/surf/blade/check dumps, STEP,
OBJ, gearbox report/assembly) are committed under
`tests/c13/artifacts/`; opaque binaries (archives, STL) are hashed into
`tests/c13/baseline.json` without storing their bytes. A drift fails
the journey and names the artifact plus the first differing line.
`--bless` re-records the baseline and artifacts, but only from a run
whose structural checks all hold: red is never blessable. Re-blessing
after an intended kernel change is a review event — the artifact diff
is the behavior diff. The report is `tests/c13/e2e-report.json`.

`tests/c13/perf.py` blocks material performance regressions. Six
operations (box eval, bracket commit/tess/step, slab archive+reopen,
G3 parts stage) run against committed budgets in
`tests/c13/perf-budget.json`:

```
BENDCAD_BIN=~/bc/bendcad python3 tests/c13/perf.py [--bless] [substring ...]
```

Micro-operations take best-of-3; the G3 stage runs once. `--bless`
sets each budget to 8x observed (4x above 60s) with a 30s floor, so
only a material regression trips the gate; machine noise does not. The
report is `tests/c13/perf-report.json`.

## Rules

The binary must be rebuilt from the tree before every run
(`~/bin/bendbuild`, no other build). Reports (`*-report.json`,
`baseline.json`, `perf-budget.json`, `artifacts/`) are committed in
tree like the other packets' reports. Division with the corpus:
`corpus.py` proves semantics against oracles (it needs
trimesh/build123d); `e2e.py` proves byte-stability with no third-party
imports; `gate.py` proves everything still holds together.

## Version history

1 (2026-10-15): 5 artifact journeys, 6 perf ops, discovery gate over
29 runner files. Unblocks on a two-def compile fix in `src/c06/cli.bend`
(`run_part`, `main_fl`): the checker forbids matching a let-bound local,
so the part and the parsed flags route through helpers that take them
as parameters, mirroring `sens`; and a `U64.to_nat` crash fix in
`src/c13/req.bend` (`cap_max` 2^48-1, user caps saturated with `U64.min`,
regression journey `cap.huge` in `tests/c13/errors.py`); pins the new
`diagnose` tool into the c06 `mcp.session` tool set.
