# G1 re-run on the K3 kernel (2026-10-27)

Each run's final design (`../runN/*.bcd`) re-evaluated, re-tessellated
(`tess 4` bracket, `tess 3` strap, as in the original sessions) and
re-graded by `tools/grade/g1.py` / `g1b.py` with the original session logs,
on `/home/jesse/bc/bendcad` = `bendcad-k3z`
(sha256 `bfa3cffe4077aeb0660252d93ee4e8436dbb03fbe1ecfb12b966a458ab17edc8`).

| Run | Part | Verdict | Kernel volume interval | Exact |
|---|---|---|---|---|
| 1 | bracket | PASS | [96101.23811419433, 96101.23811437626] | 96101.23811428528 |
| 2 | bracket | PASS | same | same |
| 3 | strap | PASS | [38566.636759935805, 38566.63676004896] | 38566.63675999238 |
| 4 | bracket | PASS | same as run 1 | same |
| 5 | strap | PASS | same as run 3 | same |

Every original verdict was PASS; none changed. `runN/grade.json` holds
each full grade.
