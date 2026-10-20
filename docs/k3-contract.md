# K3 contract — rotor balance, critical speeds, meshing and finite elements

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
| `src/k3/mesh.bend` | Isosurface stuffing on a body-centred cubic lattice: inside/outside per lattice line by certified ray crossings (C07 face intersection), cut points on crossing edges, vertex warping (α = 0.24999 black edges, 0.41189 red), stencils with minimum-index pyramid and prism splits, conformity and dihedral checks, compaction, T10 elements with boundary midside nodes projected onto the faces along the face normal |
| `src/k3/fem.bend` | Affine and isoparametric (curved) T10 elements (4-point and 14-point degree-5 rules), one-time assembly into 3×3 node-block rows with scalar mass blocks, block SpMV, block LOBPCG (lockstep PCG preconditioner, M-orthonormalisation of [W P] against X, guard vectors, eigenvalue-change stop), tolerance PCG for static solves |
| `src/k3/solve.bend` | The `modes` and `spin` verbs: clamps, shifts, rigid-mode detection, inertia relief for free spins, growth and von Mises recovery, three-level bounds |
| `src/c06/cli.bend` | `balance`, `rotor`, `modes`, `spin`; `(material ...)` accepts E and NU |
| `tools/mcp/bendcad-mcp.mjs` | MCP tools `balance`, `rotor`, `modes`, `spin` |

## 2. Forms and verbs

```
(material NODE GRADE RHO CTE [E NU])     E in MPa > 0, 0 <= NU < 0.5
balance N PX PY PZ DX DY DZ RPM G
rotor (rotor (seg L OD ID E NU RHO) ... (disc X M JD) (brg X KW KT) (n N) (modes K))
modes N K H [PX PY PZ DX DY DZ R]
spin N RPM H PX PY PZ DX DY DZ R
```

`modes` and `spin` solve at element sizes H, H/2^(1/3) and H/2^(2/3)
(about 1×, 2× and 4× the nodes). For a sequence a, b, c the observed ratio
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
- Laws (`laws/k3`, check and verdict): transposition keeps its row count
  (vector and scalar blocks), every pyramid splits into two tetrahedra and
  every prism into three; four mutants, all killed.

## 4. Limits and refusals

- Sharp edges are rounded at the lattice scale (isosurface stuffing
  places boundary vertices on the surface, not on edges). The three-level
  bound carries this geometric error; quantities at re-entrant corners
  (peak stress) do not converge and report `estimated-nonmonotone`.
- `spin` is linear: no spin softening or stress stiffening.
- A free `spin` (R = 0) applies inertia relief and refuses
  (`spin-unsupported`) when the rigid-body part of the load exceeds 1e-3
  of it, i.e. the part is not balanced about the axis.
- `material-lacks-elastic-constants`, `node-has-no-material`, open shells
  (`modes-needs-solid`, `spin-needs-solid`) and malformed arguments
  refuse with the usage line.
- Cost: the dense subspace work of LOBPCG (Gram products, combinations
  and the Jacobi eigen-solver of the Rayleigh–Ritz matrix) dominates
  below about 10k nodes; block SpMV dominates above. A 30k-DOF spectrum of
  sixteen modes takes about ten minutes on sixteen cores.
