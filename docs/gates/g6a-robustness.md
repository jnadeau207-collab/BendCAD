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

Judged on r58 (`docs/receipts/gates/g6a.json`, 2026-11-27, 150 seeds, 8 jobs). Seven seeds draw a revolve profile that `fuzz.py` itself marks invalid (28, 42, 68, 108, 118, 135, 142); the kernel refuses each of them, and the judge checks that and leaves them out of the rates:

| check | status | evidence |
|---|---|---|
| invalid inputs refused, valid inputs accepted | pass | 7 invalid refused, 0 invalid committed, 0 valid refused |
| commit rate overall | fail | 382/429 = 89.0% (r50: 76.2%, k5w: 55.6%) |
| every pair and mode | fail | 19 groups below 99% |
| OCCT | pass | 0 mismatches |
| identity | pass | 0 violations |
| p95 | fail | 11.7 s (r50: 13.4 s) |

What moved r50 to r58: intersection and edge-hit points refined in double-double before certification (reasons 72 and 82), untouched half-circle arcs split before rebuild (reason 42), the plane trim check bounding its own rounding (c04 embedding), and torus membership falling back to (u,v) parity when the surface path is tangent to the face boundary (edge-face-uncertain).

Refusals on r58 (47): validator edge-face-uncertain 17 (seeds 25, 37, 49, 86, 87, 94, 141, 147), c04 embedding 6 (coplanar seeds 112, 113), K1 42 5 (115, 117, 139), K1 72 3 (35), K1 93 3 (102, tangent), K1 82 3 (150, coaxial), timeouts 3 (148), face-face-uncertain 2 (47), K1 40 2 (71, 85 intersections), edge-crossing-uncertain 2 (91), inverted shell 1 (134).

## What closes it

1. General surface-surface intersection in K1 for every quadric pair, torus and revolve, including tangent, seam and coaxial-coincident degeneracies. The refusal reasons are 72, 42, 82 and 97.
2. Coplanar faces left overlapping by K1 (seed 86: two prisms with bases on one plane) and the tangent, coaxial and near-miss positions (93, 82, 42 on seeds 102, 150, 139).
3. Bring the speed tail under 10 s. Measured causes so far: the depth-4 certified octree in `mass` on patch faces (fixed in r1j) and whole-part rotor/stator clearance pairs (use blade-versus-revolve queries).
