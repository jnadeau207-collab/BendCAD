# AGENTS

BendCAD is Aethalgard v2: a professional CAD kernel in Bend, built to be the world's best kernel for AI agents (MASTER_PLAN §14). Aethalgard v1 (`C:\dev\Aethalgard_CAD`) is frozen: mine it for UX, vocabulary and lessons, but never modify it.

Judge every design by one question: could an agent drive this alone and trust the answer? Every result must be proven, certified, estimated or assumed, and must say which.

## Mandate

> **make one line execute the full power and prowess of 1,000 lines**

Write the smallest robust implementation that fully expresses the invariant. Every needless layer, duplicate algorithm, special case, wrapper, repeated traversal, and wasted character is a defect.

Short does not mean cryptic or fragile. Never trade correctness, numerical honesty, topology validity, failure semantics, proofs, or adversarial tests for code golf. Compress machinery, not guarantees. One general law or algorithm that deletes a thousand lines is the goal.

Before adding code, try to delete the need for it through a stronger type, reusable primitive, algebraic formulation, or shared evaluator.

## Boundaries

- `BEND_PIN` is the exact Bend dependency. Never track floating Bend `main`.
- Generic scalar/compiler/F64 work belongs in `jnadeau207-collab/bend`, not here.
- `legacy/aethalgard/` is immutable reference material. Do not edit it.
- FreeCAD, OCCT and PlaneGCS may be oracle/test comparators only; they are forbidden as BendCAD runtime geometry implementations.
- No voxel/mesh substitute may satisfy a B-rep milestone.
- No placeholder implementation, silent fallback, fake receipt, weakened tolerance, disabled test, or changed theorem to manufacture green status.
- Failure must never publish partial geometry.

## Work style

Make the smallest coherent commit that closes a contract. Pair implementation with the adversarial test that proves it. Prefer one evaluator path over human/agent variants. Prefer explicit structured failure over guessed geometry.

Read `MASTER_PLAN.md` before implementation. Numeric work begins only after its Bend handoff gate closes.

## Speed and parallelism are law

- Victor's standard: correct, compact, fast, one general mechanism, parallel by construction.
- No `nth` inside a loop, no insertion sorts, no O(n²) where O(n log n) exists. Use balanced trees and arrays, divide-and-conquer, and tree reductions.
- Every operation's contract states its complexity and a latency budget. Receipts carry measured scaling curves and parallel speedup. A performance regression blocks a packet like a failing law.

## Bend toolchain

- The installed `bend` (WSL `~/.bend/bin/bend`, also `bend` in PowerShell via WSL) is built from `BEND_PIN`, tag `numeric/2026-10-05`, and `~/.bend/FORK` records that tag. Never run `bend update`: it silently replaces a fork build with upstream and drops U64/F64. Know which commit your `bend` was built from before reporting numeric results.
- `BEND_PIN` is `a4d17acecf79c71696610f0683d8d003bc392920` (tag `numeric/2026-10-05`) on branch `numeric-on-upstream` (worktree `C:\dev\bend-onto-upstream`): `288da083` plus the host scheduler and its conformance receipt (`conformance/receipts/2026-10-05.txt`). Tags `numeric/2026-09-29` (`bc01485d`) and `numeric/2026-09-25` are earlier pins.
- Upstream merged the fork's emission speedup (#1056) and Base simplifications (as #1153) and closed U64 (#1057) and F64 (#1058): its maintainers will add both themselves and merge no PR for them. Until they ship, the fork is the only source of U64/F64; its `main` is upstream plus those two commits, rebuilt when upstream moves, and each BendCAD pin is a tag `numeric/<date>` that is never deleted. When upstream ships U64 and F64, move the pin to an upstream release and delete this section.
- `bend --check-only` prints `ALL PROOFS CHECK` (before 2.0.32, `All terms check.`); a failed check prints `SOME PROOFS FAIL` and exits 1.

## Laws and qualification

- A law is a claim about every input, as Bend means it: it quantifies (`for x: T`), states the property in `laws/<pkt>/LAWS.bend`, and is proven by a def of the same name in `laws/<pkt>/PROOF.bend` through case analysis, induction and rewriting. Shared lemmas live in `laws/lib/`. A fixed input with a fixed expected output is not a law: it is a pin.
- The gate is `bash tools/laws/check.sh <logdir>`: every `PROOF.bend` must print `ALL PROOFS CHECK` under `--check-only` and again under `--verdict`, the Lean-proven BendTT kernel (elan + `leanprover/lean4:v4.34.0`; never under `ulimit -v`, which starves Lean of threads). The checker alone is not evidence: it has no proof.
- Floats are axiomatic in proofs. The kernel cannot compute the fork's soft-float F64 (it runs out of fuel on `1.0 + 2.0`), so no law may depend on F64 arithmetic computing. F64 values may flow through a law symbolically, and F64 bit operations (`F64.neg`) may be proven at the word level. Numeric behavior is evidenced by pins and E2E against oracles.
- Pins are `tests/<pkt>/pins*.bend`: pairs `name__got()` / `name__want()`, built to an ES module and compared bit-exactly (F64 by bits) by `bash tools/pins/run.sh <files>`, which writes `pins-report.json` beside each file.
- A law must discriminate: `python3 tools/laws/mutate.py` plants a bug for every law family and must see each one fail; add a mutant with every new law family. When fixing a semantic bug, add the law or pin the old behavior fails, and show that it does.
- The checker's head normalization can overflow its stack on a symbolic term that unfolds a large validator (C04's staged `ck_*` chain): state such facts over the stage functions' Bool arguments, or leave them to E2E.
- Mind memory: WSL has about 19 GB. A process that exhausts it crashes the WSL service and kills every detached run with it. Long runs go detached (`setsid nohup … > log`) with the sha256 of law and source bytes recorded at launch.
