# C13 corpus (version 1)

The versioned qualification corpus. Gates G2, G4, G5 and G6 qualify by
re-running it, not by rewriting it. If a gate needs a member the corpus
does not have, the member is added here first, with its repeatable
artifact, and the gate re-runs the corpus.

## Run

```
BENDCAD_BIN=~/bc/bendcad python3 tests/c13/corpus.py [member-substring ...]
```

The binary must be rebuilt from the tree before the run (`~/bin/bendbuild`,
no other build). With no arguments all members run; arguments filter by
member-name substring (e.g. `corpus.py g3` runs only `g3.gearbox`).
Members run sequentially in file order. The report is
`tests/c13/corpus-report.json`; member artifacts live under
`/tmp/bc-corpus-c13/` during the run and their sha256 values are recorded
in the report.

## Repeatability rule

Every member builds each design twice from scratch and compares the
canonical kernel outputs byte-exactly (eval, flat, surf, blade, show/apply
replay), and records sha256 of every exported artifact (STEP, OBJ, BCAD1
archive, design file). A member holds only if both builds agree and every
oracle check holds on the recorded binary. The report carries
`corpus_version`, `binary_sha256`, per-member checks and artifact hashes.

## Members

| Member | What it builds | Artifact |
|---|---|---|
| g3.gearbox | G3 v3 reference gearbox via `tools/g3/gearbox.py <out> parts`, twice: 4 stages committed, `asm solved ninst 119 nmates 122 dof 0`, identical bcd/eval/assembly | report.json, gearbox.bcd, assembly.txt |
| sheet.bracket | C16.1 U-bracket (flat, 2 bends, hem): volume, 16 faces, flat legs/developed, tess mesh, STEP 1 solid/16 faces/4 cylinders, archive reopen 16 loops, replay | cb.stp, cb.obj, cb.bin, cb.bcd |
| sheet.edits | Repeated feature edits: param L 100-120-100-140-120-100, all committed, final eval byte-identical to initial, sens reuse | ce.bcd |
| sheet.fold180 | 180-degree fold (pathological tangent construction): ok, volume, 10 faces | cf.bcd |
| surf.cowl | C16.2 cowl patch (area within 1% of oracle) + thickened slab: ok, STEP 1 solid/6 faces/vol 100, archive reopen 6 loops, replay | cs.stp, cs.bin, cs.bcd |
| surf.duct | Taper duct thickened (bezier walls): 16 faces, genus 1, honest check verdict, archive reopen 16 loops | cd.bin, cd.bcd |
| blade.stack | C16.3 twisted 5-section blade (twist 20, taper 75): header, schedule, 130 faces, ruled verdict; prismatic blade STEP 34 faces (32 BSPLINE + 2 PLANE), replay, reopen 34 loops | cp.stp, cp.bin, cp.bcd |
| scale.sweep | Same box at 0.01, 1, 100, 1000 mm: committed, certified volume containment, bbox spans | sc*.bcd |
| mixed.union | Mixed analytic-slab + bezier-duct design commits (1 solid each); cross-domain union refused by name (`bezier-patch-operand`), atomically; both STEPs reimport to 1 solid | mx.bcd, mx2.stp, mx5.stp |
| ring.arcs | Concentric-arc ring and rounded ring volumes; touching/crossing/tangent holes refused by name | ra*.bcd |
| corrupt.inputs | Garbage STEP, malformed entity, conical surface, garbage/bad-version/bad-units archives, garbage step_of/stl_of/3mf_of, missing node: every one refused by name, nothing written, design untouched | kbox.step, kbox.bca |
| crash.recovery | Rejected apply leaves the design byte-identical; archive reopens the identical volume after the design file is deleted; show/apply transcript replays byte-exactly; truncated design never commits and is never overwritten | kr.bin, kr2.bcd |
| long.sequence | Bracket, 40 alternating param edits with interleaved measure/show queries: every step committed, final eval byte-identical to initial, volume exact | kl.bcd |

## Coverage against the C13 exit

Varied scales: `scale.sweep`. Repeated feature edits: `sheet.edits`,
`long.sequence`. Mixed analytic/NURBS solids: `mixed.union`,
`blade.stack`. Corrupted input: `corrupt.inputs`, `crash.recovery`
(truncated design). Crash recovery: `crash.recovery`. Long operation
sequences: `long.sequence`. Pathological geometry: `sheet.fold180`,
`ring.arcs`. Assembly scale: `g3.gearbox`.

## Version history

1 (2026-10-15): 13 members. G3 v3 gearbox at `parts` stage plus C16
sheet-metal, surface and blade designs with replay and export artifacts.
