# Certified clearance and fast build, 2026-11-03 (binary bendcad-fb7)

| Pair (G4 blower) | Certified cold clearance | Time |
|---|---|---|
| impeller - inlet cone | [1.4999999995, 1.5000000000005] mm | 143 s |
| impeller - front plate | [39.8630467962, 39.8630467978] mm | 79 s |
| impeller - scroll casing | [9.9999999995, 10.0] mm | 136 s |

About 60 s of each time is evaluating the blower design. G2 gear gaps
re-run identical (`../clearance-2026-11-02/g2-gaps-par13.txt`).

Build: `tools/build/fastbuild.sh` (split C into 32 units, 10 parallel
compiles) builds the kernel in 6.4 min instead of 33 (gen 249 s, cc 133 s);
impeller output identical (`rotor-time-fb1.txt`, 70.5 s).

Checks on fb7: ident 12/12 identical, corpus 18/18, K1 pins 22/22, C08
487/487, C15 154/154, C11 E2E 36/36.
