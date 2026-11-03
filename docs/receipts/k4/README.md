# K4 receipt — freeform faces in booleans (2026-11-03)

Binary `~/bc/bendcad-k4g` (sha256 3a88211f…cd23), built from commit below.

E2E `tests/k4/e2e.py 20 30`: NACA 4412 blade (17-point sections, span 30,
twist 20 and 30, curved ruled walls) with a 60x60x10 box through its root.
Union, intersection and difference all commit with full C04 + C07
validation in 2.2–2.8 s each. Volume identity |A u B| + |A n B| = |A| + |B|
holds to certified bounds for both twists (gap 7.3e-12). Report:
`e2e-k4g.json`.

Byte identity against the g4zm reference: 12/12 identical (`ident-k4g.txt`).
