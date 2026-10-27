# K3 contract — rotor balance, critical speeds, meshing, finite elements, blends and machinability

Scope (MASTER_PLAN §10 K3): the analysis G4 needs on top of K1/K2
geometry. A part's exact volume moments give its ISO 21940-11 balance
about an axis; a shaft's lateral critical speeds come from Timoshenko beam
elements; any certified solid is meshed into curved quadratic tetrahedra
whose natural frequencies and centrifugal response are computed with a
refinement bound. Every analytic claim is checked against a closed form
inside the suites; no external solver runs.

## 1. Files

| File | Role |
|---|---|
| `src/k3/mom.bend` | Exact first and second moments of volume by the divergence theorem per face (certified intervals); ISO 21940-11 residual and permissible unbalance; products of inertia relative to an axis |
| `src/k3/beam.bend` | Timoshenko beam elements (Friedman–Kosmatka, Cowper shear coefficient), banded LDLᵀ Sturm counts of K − λM, bisection, three-level refinement (N, 2N, 4N) with an observed-ratio extrapolation; the `(rotor ...)` spec parser |
| `src/k3/mesh.bend` | Isosurface stuffing on a body-centred cubic lattice: inside/outside per lattice line by certified ray crossings (C07 face intersection), cut points on crossing edges, vertex warping (α = 0.24999 black edges, 0.41189 red), stencils with minimum-index pyramid and prism splits, conformity and dihedral checks, compaction, sharp-edge recovery (a boundary edge whose ends lie on two faces meeting at a sharp angle snaps its nearer end onto their intersection by two-surface Newton, refused where a tet would invert), T10 elements whose boundary midside nodes lie on the B-rep (on the intersection curve of two common faces, at the closest point of one common analytic face, else by a certified ray along the facet normal; by the certified ray for an edge whose ends lie on different faces, which keeps the geometric error monotone in h); a midside node whose element would invert (a non-positive Jacobian ratio) reverts to the chord midpoint |
| `src/k3/fem.bend` | Affine and isoparametric (curved) T10 elements (4-point and 14-point degree-5 rules), one-time assembly into 3×3 node-block rows with scalar mass blocks, block SpMV (mass-only path when the stiffness factor is zero), block LOBPCG on node-major block vectors cut into 32 chunks (lockstep PCG preconditioner, M-orthonormalisation of [W P] against X, guard vectors, a stop when every wanted residual |Kx − λMx| is below 1e-6 of λmax|Mx|, each finer level started from the previous level's Ritz vectors carried to its nodes by nearest coarse node, symmetric Gram matrices computed by their upper triangle), round-robin parallel Jacobi for the dense eigenproblems, tolerance PCG for static solves |
| `src/k3/solve.bend` | The `modes` and `spin` verbs: clamps, shifts, exact rigid-mode deflation for free parts, inertia relief for free spins, growth and von Mises recovery, three-level bounds |
| `src/k3/div.bend` | Divergence-theorem volume moments of any B-rep from its exact faces, used by mass properties of swept walls |
| `src/k3/mach.bend` | The `machine` verb: ball, flute and holder solids placed along candidate directions, each certified apart from the part by the C07 embedding check; concave radii and sharp concave edges |
| `src/c06/psw.bend` | Path sweeps `(sweep (along PATH) REGION)` and walls `(sweep (wall PATH) REGION)`: profile swept along a closed tangent-continuous path of lines and arcs, a wall closed by flat caps |
| `src/c06/cli.bend` | `balance`, `rotor`, `modes`, `spin`, `machine`; `(material ...)` accepts E and NU |
| `tools/mcp/bendcad-mcp.mjs` | MCP tools `balance`, `rotor`, `modes`, `spin`, `machine` |

## 2. Forms and verbs

```
(material NODE GRADE RHO CTE [E NU])     E in MPa > 0, 0 <= NU < 0.5
balance N PX PY PZ DX DY DZ RPM G
rotor (rotor (seg L OD ID E NU RHO) ... (disc X M JD) (brg X KW KT) (n N) (modes K))
modes N K H [PX PY PZ DX DY DZ R]
spin N RPM H PX PY PZ DX DY DZ R
machine N D FL HD HL AXES NS
(sweep (wall PATH) REGION)
```

A blade-root blend is built, not patched: the blade is a wall sweep whose
profile carries the root fillet and a ledge below the base plane, and
`(union PLATE WALL)` fuses it to the plate through K1. The union is
certified (C07 tangency at shared vertices and station planes, K1 near
contacts at vertices) and its volume is exact.

`modes` and `spin` solve at element sizes H, H/2^(1/3) and H/2^(2/3)
(about 1×, 2× and 4× the nodes). Refinement by a size field (grading
toward thin walls) is open: longest-edge bisection graded by wall
thickness fired inconsistently across the three levels on plates and left
LOBPCG unconverged, so the levels stay uniform lattices. For a sequence a, b, c the observed ratio
q = (a − b)/(b − c) gives, when q > 1.05, the extrapolation
c + (c − b)/(q − 1) and the bound max(|c − b|, |est − c|)
(`status=estimated`); otherwise the bound is twice the larger change
(`status=estimated-nonmonotone`).

## 3. Evidence (tests/k3, laws/k3)

- Balance and rotor journeys: offset and drilled discs against the exact
  centroid offset; pinned slender and thick shafts against Timoshenko's
  closed form; a Jeffcott rotor and an overhung disc against two-degree-of-
  freedom closed forms, all within 1e-4 of the exact speed.
- Mesher (`tests/k3/zmesh.bend`, sphere r = 10, h = 0.5): 410,456 tets,
  no face shared by more than two tets, boundary vertices on the sphere to
  1.8e-15, dihedral angles 17.6° to 146.1°, no degenerate tet. Straight
  volume 4186.10 (inscribed, −6.4e-4); curved T10 volume 4188.789999606
  against 4188.790204786 (−4.9e-8), Jacobian ratio in [0.984, 1.026].
- Element: on a straight-sided mesh the curved path reproduces the affine
  K, M and diag(K) to 1e-15; assembled operators match element-by-element
  application to 1e-15 (`tests/k3/zfemd.bend`).
- Free sphere (Lamb): r = 10 steel at h = 2 (30.8k DOF, 2,037 curved
  elements) gives six rigid modes at 0.02 Hz, torsional l = 2 at
  124,612.1–124,613.1 Hz against 124,609.29 and spheroidal l = 2 at
  131,839.8–131,840.7 against 131,837.54; 14 LOBPCG iterations, 11.6 min.
- Rotating sphere (Chree's cubic solution, derived symbolically): at
  1000 rev/s, h = 2, the equatorial diameter grows within 7.4e-5 and the
  polar within 8.9e-5 of exact; `spin` at H = 5 brackets the external work
  1.4629529 N·mm with est 1.46336 ± 0.00091 from below.
- Thick disc R = 25, t = 5, H = 3 (sharp rim edges snapped): all five
  lowest free modes inside est ± bound of a converged 3-D axisymmetric
  oracle (`tools/oracle/k3/disc_modes.py`), e.g. (0,1) 16570.19 ± 2.93
  against 16568.58; the free spin at 60,000 rev/min gives work 196.000 ±
  0.090 N·mm against 196.049 (`tools/oracle/k3/disc_spin.py`). Mesh volume
  error falls monotonically (−0.073%, −0.035%, −0.019%) where unsnapped
  lattice chamfers gave +0.6%.
- Speed (sphere r = 10, ten modes, three levels, sixteen cores): 301.6 s
  before chunked Gram products, node-major chunked PCG and LOBPCG and exact
  rigid deflation; 83 s after, with identical frequencies.
- Laws (`laws/k3`, check and verdict): transposition keeps its row count
  (vector and scalar blocks), every pyramid splits into two tetrahedra and
  every prism into three, reverting midside nodes and snapping vertices
  keep the node count, and reverting nothing changes nothing; seven
  mutants, all killed.

## 4. Limits and refusals

- Sharp edges are recovered by snapping where it keeps every tet sound;
  an edge left bridging two faces keeps a ray-projected midside node, a
  small geometric error that shrinks monotonically with h. Quantities at
  re-entrant corners (peak stress) do not converge and report
  `estimated-nonmonotone`. H must resolve the thinnest wall (about 0.6 of
  it): coarser levels can agree by chance and give a bound that is too
  tight.
- Refinement by a size field is open (graded bisection parked: it fired
  inconsistently across levels on plates).
- `spin` is linear: no spin softening or stress stiffening.
- A free `spin` (R = 0) refuses (`spin-unsupported`) when the certified
  divergence-theorem moments prove the part unbalanced about the axis
  (centroid off it or products of inertia about it beyond 1e-9 of its
  size); otherwise inertia relief removes the mesh's own small imbalance.
- `material-lacks-elastic-constants`, `node-has-no-material`, open shells
  (`modes-needs-solid`, `spin-needs-solid`) and malformed arguments
  refuse with the usage line.
- Cost: the dense subspace work of LOBPCG (Gram products, combinations
  and the Jacobi eigen-solver of the Rayleigh–Ritz matrix) dominates
  below about 10k nodes; block SpMV dominates above. A 30k-DOF spectrum of
  sixteen modes takes about ten minutes on sixteen cores.
