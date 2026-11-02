# Certified clearance re-run, 2026-11-02 (binary bendcad-par13)

Owner ruling 2026-11-02: certified clearance is required now, and every gate's
clearances are re-run through it.

| Gate | Pair | Before (G4 run 1 binary) | par13 |
|---|---|---|---|
| G4 | impeller - inlet cone (1-3) | [0, 1.80] after 19 min, lower bound useless | **[1.4999999995, 1.5000000000005] mm certified, 145 s** |
| G4 | impeller - scroll casing (1-2) | not finished | not finished in 60 min (volute: 43,472 face pairs, non-coaxial) |
| G4 | impeller - front plate (1-13) | not finished in 20 min | not finished in 60 min (non-coaxial) |
| G2 | 8 recorded K2 gear gap queries | certified / uncertain as in run 1 | byte-identical (`g2-gaps-par13.txt`) |

The sampled upper bound for impeller-cone was 1.80 mm; the certified interval
shows the true minimum is 1.50 mm (the design value), so sampling missed the
pinch by 0.3 mm.

Open: the casing and front-plate pairs need a planar-projection bound
(faces perpendicular or parallel to the axis, projected to the xy plane)
before they certify. Until then they are reported as not certified.
