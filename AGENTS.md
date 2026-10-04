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

- The installed `bend` (WSL `~/.bend/bin/bend`, also `bend` in PowerShell via WSL) is the old pin `bc01485d`, not `BEND_PIN`. Never run `bend update`: it silently replaces a fork build with upstream and drops U64/F64. Do not report a pin result from that binary.
- `BEND_PIN` is `288da0836f419b57323283b971fe44b363ff1193` on local branch `numeric-on-upstream` in `C:\dev\bend-onto-upstream`. Run it from source: `export PATH=$HOME/.bun/bin:$PATH` and `bun bend2/main.ts` in that worktree. Tag `numeric/2026-09-29` (`bc01485d`) is the previous pin; `~/.bend/FORK` still records that tag. Know which commit your `bend` was built from before reporting numeric results.
- Upstream merged the fork's emission speedup (#1056) and Base simplifications (as #1153) and closed U64 (#1057) and F64 (#1058): its maintainers will add both themselves and merge no PR for them. Until they ship, the fork is the only source of U64/F64; its `main` is upstream plus those two commits, rebuilt when upstream moves, and each BendCAD pin is a tag `numeric/<date>` that is never deleted. When upstream ships U64 and F64, move the pin to an upstream release and delete this section.
- `bend --check-only` prints `ALL PROOFS CHECK` (before 2.0.32, `All terms check.`); a failed check prints `SOME PROOFS FAIL` and exits 1.

## Laws and qualification

- Every packet closeout checks every law file (`laws/c00.bend` … `laws/cNN.bend`) in full on the pinned `bend`, however long it takes. Long runs go detached (`setsid nohup … > log`), with the sha256 of the law and source bytes recorded at launch; come back for every result. A law is never left unchecked for time.
- Use the whole machine: split a law file into parallel chunks (`lawchunks.py`, chunks at `laws/` depth) for per-law timing and fast feedback, and also keep one full single-file run as the canonical record. Run oracle seeds and suite lanes in parallel.
- Mind memory: WSL has about 19 GB. A process that exhausts it crashes the WSL service and kills every detached run with it.
- Closed laws pin floats by `F64.bits`, never by `F64.show`: the checker does not evaluate `show`.
- `bend <file> --verdict` rechecks with the Lean-proven BendTT kernel (needs elan + `leanprover/lean4:v4.34.0`, installed). It fails on any law that evaluates F64. The stock kernel runs out of its 400M-step fuel on a single `1.0 + 2.0`; a 1000× fuel build exhausts memory. Kernel-checked F64 needs a native F64 in BendTT, which is fork work. Until then, report `--check-only` evidence and say that `--verdict` is unavailable for F64 laws.
- A law must discriminate: when fixing a semantic bug, add a closed law that the old behavior would fail, and show that it does.
