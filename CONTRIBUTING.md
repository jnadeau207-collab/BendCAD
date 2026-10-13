# Contributing to BendCAD

Thanks for wanting to help build a CAD kernel agents can trust. This page gets you set up and explains the handful of rules that make that trust possible. The long-form rules are in [AGENTS.md](AGENTS.md) (written for human and AI contributors alike) and the roadmap is [MASTER_PLAN.md](MASTER_PLAN.md).

## Ways to help

- **Try it and break it.** Build a part through the CLI or MCP server and report anything wrong, confusing or slow. A wrong answer is the most valuable bug you can find; a refusal without a useful fix is the second most valuable.
- **Pick up a milestone.** The plan is split into packets (C00–C16). The README says which one is in flight; open an issue before starting a large piece so work doesn't collide.
- **Prove things.** If you like proofs, there are always properties worth stating and proving in `laws/`.
- **Make it faster.** Every operation has a latency budget, and a few are still over it (the receipts in `docs/receipts/` say which).
- **Improve the docs.** If something here took you too long to figure out, make it shorter for the next person.

## Setting up

You need Linux or WSL2, Python 3, Node.js and git.

1. Build Bend from the pinned commit. BendCAD needs 64-bit integers and floats, which live in a fork of Bend until upstream ships them. [`BEND_PIN`](BEND_PIN) names the exact commit of [jnadeau207-collab/bend](https://github.com/jnadeau207-collab/bend). Never run `bend update`: it replaces the fork with upstream and drops those types.
2. Build the CLI: `bend src/c06/cli.bend -o ~/bc/bendcad` (the end-to-end suites look there, or wherever `BENDCAD_BIN` points). The build takes a few minutes and about 5 GB of memory.
3. Proofs use Bend's checker plus its Lean-proven kernel (`--verdict`), which needs [elan](https://github.com/leanprover/elan) with `leanprover/lean4:v4.34.0`.

Set `BEND_NO_TELEMETRY=1` so tool output stays comparable between runs.

## The rules that keep it trustworthy

1. **Never silently wrong.** A result is proven, certified, estimated or assumed, and says which. When the kernel can't decide something, it refuses with a named reason and a fix, and publishes nothing.
2. **Laws are proofs.** A law in `laws/<packet>/LAWS.bend` makes a claim about *every* input and is proven in `PROOF.bend`. A fixed input with a fixed expected answer is a pin (`tests/<packet>/pins*.bend`), not a law. Every new family of laws gets a planted bug in `tools/laws/mutate.py` that it must catch.
3. **End-to-end tests are the evidence.** Behavior is tested by driving the real CLI or MCP server through whole journeys that leave a reproducible report. Unit tests don't count as evidence here.
4. **No comments in code.** Names, types and laws carry the meaning. Explanations belong in the contracts and receipts under `docs/`.
5. **Small, fast, parallel.** Prefer one general mechanism over many special cases. No quadratic loops where a faster algorithm exists. A performance regression blocks a change like a failing test.
6. **All geometry is Bend.** OCCT, FreeCAD and PlaneGCS may serve as test oracles, never as the implementation. A mesh is never a substitute for exact geometry.
7. **Never weaken a check to go green.** Changing a law, a tolerance or a test so that failing code passes needs explicit review.

## Before you open a pull request

Run the gates that cover your change, and paste the summary lines into the PR:

```sh
bash tools/laws/check.sh /tmp/laws        # every law, under both checkers
python3 tools/laws/mutate.py              # every planted bug is caught
bash tools/pins/run.sh tests/*/pins*.bend # every pin holds
python3 tests/c06/e2e.py                  # and every e2e.py / neg.py you touched
```

Keep each PR to one coherent change, paired with the test or law that proves it. Mention the packet it belongs to.

## Questions

Open an issue. There are no silly questions about a geometry kernel; the field is famously full of sharp edges.

By contributing you agree that your work is licensed under the [Apache License 2.0](LICENSE).
