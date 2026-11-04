# K4 receipt — freeform faces in booleans (2026-11-03)

Binary `~/bc/bendcad-k4g` (sha256 3a88211f…cd23), built from commit below.

E2E `tests/k4/e2e.py 20 30`: NACA 4412 blade (17-point sections, span 30,
twist 20 and 30, curved ruled walls) with a 60x60x10 box through its root.
Union, intersection and difference all commit with full C04 + C07
validation in 2.2–2.8 s each. Volume identity |A u B| + |A n B| = |A| + |B|
holds to certified bounds for both twists (gap 7.3e-12). Report:
`e2e-k4g.json`.

Byte identity against the g4zm reference: 12/12 identical (`ident-k4g.txt`).

## Freeform loft (`skin`), binary k4o (sha256 60061cd6…05b3)

New general freeform solid: `(skin (sec SRC (frame ox oy oz ux uy uz vx vy vz s)) ...)` where SRC is
`(naca N)` or `(run x y x y ...)` runs in the section's own frame. Sections are interpolated in their
frame with cubic B-splines (c03/bsp), skinned across sections, and decomposed exactly into bicubic
Bezier faces with shared iso-curve edges and planar caps. Volume by exact Gauss quadrature of the
divergence integrand; area by Gauss with a split-error band. Self-intersection certificate
(c16/skcert): per-patch Bezier normal cone with subdivision, convex-hull separation with projected
directions and anisotropic subdivision for non-adjacent patches, seam recursion with cone, wedge and
non-folding dihedral rules for adjacent patches, and cap-side containment.

E2E `tests/k4/skin.py` 8/8 (`skin-k4o.json`): self-crossing loft refused; cylinder skin volume within
the spline's 1.06e-6 interpolation error of pi r^2 h; cylinder skin union/intersection with a box keep
the volume identity; tilted+scaled frustum; 4-section twisted tapered NACA 4412 blade (67 faces)
builds in 0.8 s; blade union/intersection with a box keep the volume identity; mass; STEP export with
65 B_SPLINE_SURFACE faces. Byte identity 12/12 (`ident-k4o.txt`).
