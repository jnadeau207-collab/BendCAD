# C14 intent: assemblies with solved mates and certified queries

C14 is the packet where BendCAD stops placing one solid at a time and
starts assembling machines: named instances of design nodes with
placements, mates that solve exactly, kinematic degrees of freedom with
named redundancy and conflicts, interference and clearance with certified
status, exploded views, and assembly-level lineage with durable
selectors. An agent can mate two boxes, read the residual, trust a
certified clearance, explode the stack, and know that a conflicting mate
set publishes nothing. Every answer is proven, certified, estimated, or
a named refusal.

## 1. Goal and non-goals

Goal: every line of MASTER_PLAN §10 C14 — components, placements,
mates/joints, kinematic dof over the C05 rank machinery, interference
and clearance through C11 with certified status, exploded views,
assembly lineage and durable selectors — with the exit's assembly
mechanics (mates solved, no interference, clearances certified, edits
propagating) proven on fixtures. Non-goals: rotation-solving mates,
joint types beyond fix/coincident/plane/axis, tolerance-envelope and
operating-state evaluation, motion sweeps, and the G3 gearbox rung
itself (see §10 and the contract §8).

## 2. Agent contract

```sh
bendcad d.bcd asm solve '(assembly (inst a 1 0 0 0 0) (inst b 2 0 0 0 0) (fix 1 a) (coinc 2 a 14 5 5 b 0 2 2))'
bendcad d.bcd asm interf '(assembly ...)'
bendcad d.bcd asm clear '(assembly ...)'
bendcad d.bcd asm explode 0 0 1 5 '(assembly ...)'
bendcad d.bcd asm faces b '(assembly ...)'
```

`solve` prints one `asm solved|underconstrained|conflict` line with
dof, max-residual, redundant or violating mate ids, then placements and
lineage (conflicts print placements never). `interf` and `clear` print
one `pair` block per unordered instance pair with C11's certified or
honestly-estimated verdict. `explode` prints offset placements;
`faces` prints `INST`-qualified durable face names with surface kinds
and loop counts. The MCP `assembly` tool takes `design`, `action`,
`assembly` (plus `inst` for faces, `dx/dy/dz/gap` for explode) and
returns the same text.

## 3. Architecture

```
src/c14/asm.bend    parse, mate rows, C05 solve, residual audit, pair queries, explode, faces, dispatch
```

One file, one entry (`asm_go`): the s-expr parses into instances and
mates (two staged scans with exact refusals), mates lower to linear
translation rows, the C05 rank/lsq machinery solves, a 1e-9 relative
residual audit accepts or conflicts, and the five verbs render from the
solved placements. Pair queries place each instance's evaluated node
result at its solved translation and call straight into C11; faces
qualify C06 face rows with the instance name. There is exactly one
solve path and one audit; every verb shares them.

## 4. Status vocabulary

`solve` reports `solved` (dof plus residual), `underconstrained` (one
configuration, dof 3n), or `conflict` (violating mate ids, no
placements). `redundant [...]` names mates the rank audit found
dependent. Pair relations reuse C11's vocabulary verbatim: `disjoint`
or `interference` with `status=certified`, else `uncertain` with
`status=estimated`. Clearances print `[lo, hi] estimated lo=certified`
or `0 status=certified state=interference`. Refusals start with `error`
or `asm conflict`, name the reason, and say how to fix it. Nothing
estimated is ever labelled certified.

## 5. Methods

Mates are linear in translations once orientations are fixed, so each
mate kind lowers to a fixed row count (fix 3, coincident 3, plane 1,
axis 2) over unknowns packed three per instance. Node-frame mate points
are mapped through the instance's fixed turn code before rows are built.
Rank comes from `Q.rank` over norm-sorted rows, the solution from
`Q.lsq_nt` over `Q.nd_order`, redundancy from the C05 kept/dropped
columns mapped back to mate ids — the same machinery C05 receipted, not
a second solver. The audit re-evaluates every row against the solution
and conflicts on any row past the bound, so a least-squares fit to an
inconsistent set can never print as solved.

## 6. Refusals

§6 of the contract lists every reason. Parse refusals fire per stage in
scan order with the exact expected shape as the fix; unknown instances,
nodes, and verbs are named; failed nodes refuse with `nothing
assembled`; conflicts name the violating mates. Dispatch uses `match`
on the verb code; failure never publishes partial geometry because the
conflict verdict carries no solution and writers render only from a
solution.

## 7. Complexity and latency

Contract §7 states the bounds (parse O(entries), rows O(mates), audit
O(rows), one C11 query per pair) and the budgets (solve < 30 s,
interf/clear < 60 s, explode/faces < 10 s). Measured numbers land in
the receipt.

## 8. What this packet reuses

The C05 solver's rank, least-squares, and ordering definitions move
into the binary for the first time through this packet (they had no
runtime caller before); C14 adds no solver of its own. Pair queries are
thin placements over C11 `rel_s`/`clear_s`; face rows reuse the C06
face/surface definitions; turn codes reuse the `move` orientation
convention. Reuse is by direct call, never by copy.

## 9. Evidence map

- `laws/c14/LAWS.bend`, `laws/c14/PROOF.bend`: 154 laws over
  scans, parse stages, solver wiring, the residual audit, reports,
  placement, faces, and dispatch; see `docs/c14-laws.md`.
- `tests/c14/pins.bend`: 164 hand-derived fixed-input pins over the
  same path.
- `tests/c14/e2e.py`, `tests/c14/neg.py`: 15 analytic-oracle journeys
  (solve/under/redundant/conflict/plane-axis, disjoint/overlap/touch,
  certified clearance, interference clearance, explode, box/hole faces,
  edit propagation, MCP parity) and 18 verbatim refusal journeys, each
  asserting the design file is byte-unchanged.
- `docs/receipts/c14-2026-10-13.txt`: the A2 exit matrix with measured
  evidence.

## 10. Deferrals

See contract §8: fixed-orientation translation-only mates (D-rot), no
G3-gearbox journey yet (D-g3), nominal-placement queries (D-tol-stack),
one-configuration underconstrained reports (D-motion), the exact
axis-identity law (D-axis-law), and the 17–18G compile peak (D-buildmem).

## 11. Reproduction

Rebuild the binary with the packet's two-stage recipe (see the receipt
§1; the compile scope is 18G — 17G provably OOMs this tree), then:

```sh
python3 tests/c14/e2e.py
python3 tests/c14/neg.py
bash tools/pins/run.sh tests/c14/pins.bend
bash tools/laws/check.sh /tmp/laws-c14
python3 tools/laws/mutate.py
```
