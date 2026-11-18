# GATE G6a — robustness: every boolean an agent asks for, answered and right

Proposed after the G5 evaluation (2026-11-08); written down 2026-11-17 with a runnable judge.

G5 passed only by steering around refusals. A kernel an agent can trust must answer the boolean it is asked, certify the answer, and do it fast. G6a measures exactly that on a seeded corpus of primitive pairs in every placement mode, and nothing else.

## Corpus

`tests/eval/fuzz.py`: seeds 1-150. Each seed draws two primitives from box, prism, cylinder, cone, sphere, torus and revolve, and places them in one of seven modes: general, near-miss, tangent, coaxial, axis, coplanar or seam. Then it runs union, intersection and difference. Each committed result is checked against the volume identity (union + intersection = A + B; difference = A - intersection) and against OCCT's volume of the same operation.

## Pass criteria (all must hold)

| check | target |
|---|---|
| commit rate, all operations | 99% or more |
| commit rate, every pair x mode group | 99% or more |
| wrong answers against OCCT | 0. A disagreement counts until it is attributed. A kernel answer whose certified interval excludes OCCT's value, with OCCT shown right by an independent integration, is a wrong answer. |
| volume-identity violations | 0 |
| p95 operation time | under 10 s on the 16-thread reference machine |

## Judge

`python3 tests/gates/g6a.py [N] [JOBS] [FIRST_SEED]` runs the corpus on `FUZZ_BIN` and writes `docs/receipts/gates/g6a.json`. The checks are in the same pass/fail/evidence form as `tools/g5/readiness.py`. Exit 0 only when every check passes.

## Measured state

Judged on the 150-seed k5w corpus (`docs/receipts/eval-fuzz-k5w-150.json`):

| check | status | evidence |
|---|---|---|
| commit rate overall | fail | 250/450 = 55.6% |
| every pair and mode | fail | 47 groups below 99%; cone/torus/revolve pairs and the seam and axis modes are the worst |
| OCCT | fail on k5w, cleared since | 11 volume disagreements of about 2.4e-5 relative, every one involving a prism. Seed 2 rerun on r1j: OCCT 10305.760592611 inside the kernel's certified [10305.76059260, 10305.76059262]. The 42-seed gate baseline on p9q records 0 mismatches. |
| identity | pass | 0 violations |
| p95 | fail | 338.8 s |

## What closes it

1. General surface-surface intersection in K1 for every quadric pair, torus and revolve, including tangent, seam and coaxial-coincident degeneracies. The refusal reasons are 72, 42, 82 and 97.
2. A fresh 150-seed judge run on the current kernel, to replace the k5w figures above.
3. Bring the speed tail under 10 s. Measured causes so far: the depth-4 certified octree in `mass` on patch faces (fixed in r1j) and whole-part rotor/stator clearance pairs (use blade-versus-revolve queries).
