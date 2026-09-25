# AGENTS

BendCAD builds a new professional CAD kernel in Bend. Production Aethalgard is separate and must not be modified by this project.

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

## Bend toolchain

- The installed `bend` (WSL `~/.bend/bin/bend`, also `bend` in PowerShell via WSL) is compiled from the fork `jnadeau207-collab/bend`, not from an upstream release. Never run `bend update`: it silently replaces the fork build with upstream and drops U64/F64.
- Installed from fork tag `numeric/2026-09-25` (commit `50ec219a`), the `BEND_PIN` commit; `~/.bend/FORK` records provenance. Know which commit your `bend` was built from before reporting numeric results. Rebuild from the fork checkout with `bun build --compile --target=bun-linux-x64 ./bend2/main.ts --outfile ~/.bend/bin/bend`, then refresh `~/.bend/bend2` and `~/.bend/guide` from it.
- Fork work reaches upstream through bendlang/bend PRs #1056 (emission), #1057 (U64), #1058 (F64) and #1059 (base helpers), all open as of 2026-09-25. When all four are merged and the install is switched to an upstream release, this section is obsolete and should be deleted.
- Never delete a `pr/*` branch in the fork while its PR is open: GitHub auto-closes a PR when its head branch is deleted.
