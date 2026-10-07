# C07 contract — general intersections, solid classification and embedding, envelope topology

Scope (MASTER_PLAN §10 C07, A1, A5): curve/curve, curve/surface and
surface/surface intersection with broad-phase bounds, subdivision and
root isolation, refinement, endpoint and seam classification and full
coverage of the admitted domain, including tangency, coincidence,
overlap, seams and singular points; intersection curves with their
parameter correspondence; general geometric self-intersection of B-reps
(curved-edge crossings, cross-face and inter-loop penetration, which A1
moved here from C04); the inside/outside classification that global
outward orientation needs; broad-phase cavity nesting; and the
certificate that a design's topology is constant over a parameter box,
which lets `zone` cover profiles and features (A5). Unresolved regions
are always reported, never dropped. No existing CAD kernel is used at
runtime.

## 1. Files

| File | Role |
|---|---|
| `src/c07/ivx.bend`, `lin.bend` | Interval vectors and matrices; Gauss–Jordan inverse |
| `src/c07/rb.bend` | Rational Bézier curves with interval control points: blossoms, restriction, hulls, hodographs, enclosures `cv_box`, `cv_der`, `cv_hbox`; exact conversion of lines, Béziers, conics and circles |
| `src/c07/im.bend` | Implicit forms of planes and quadrics (value and gradient enclosures, cone nappe side) |
| `src/c07/poly.bend`, `exc.bend` | Exact composition of a curve into a surface's implicit form (expansion arithmetic, Shewchuk compression, truncation with an error bound) |
| `src/c07/eng.bend` | The solver: problem kinds, branch and bound with Krawczyk certification, budgets, rescue, face-root collection |
| `src/c07/xs.bend` | Curve/surface and curve/curve intersection, coincidence tests, arc and line overlap, endpoint deflation |
| `src/c07/ss.bend`, `par.bend` | Surface/surface tracing into ordered branches with parameter correspondence |
| `src/c07/bp.bend`, `nb.bend`, `isect.bend` | Bézier patches, NURBS curve spans and the public `inter_cs`, `inter_cc`, `inter_ss` |
| `src/c07/mem.bend` | Face membership of a point |
| `src/c07/sol.bend` | Point classification, shell orientation, cavity nesting |
| `src/c07/emb.bend` | Embedding (self-intersection) check |
| `src/c07/sym.bend` | Exact rational normal form of parameter expressions; identity proofs |
| `src/c07/zt.bend`, `zd.bend` | Zone primitives, separation and corner certificates, interval dual numbers, envelope measures |
| `src/c07/gsx.bend`, `gmain.bend` | `geom intersect` syntax and report |
| `src/c06/zone.bend`, `src/c06/cli.bend` | `zone`, `classify`, `check` wiring |

## 2. Intersection engine

Every curve is a rational Bézier on `[0, 1]` with interval control
points (`Rb`); lines, cubics, conics and circles convert exactly, and a
full circle is one quartic rational piece (its weights stay positive in
exact arithmetic even though their Bernstein coefficients dip below
zero, so whole-edge boxes use `cv_hbox`, which subdivides until every
piece is finite). Planes and quadrics are exact homogeneous implicit
forms evaluated as interval value and gradient.

`solve` runs branch and bound over the problem's box. A box is excluded
when an enclosure of the residual excludes zero, certified when the
Krawczyk operator maps it into itself (square systems), and split
otherwise at off-center fractions so structured inputs never land on a
split. Curve-type problems (one equation fewer than unknowns) certify a
box when the Jacobian is regular there and exactly two certified roots
sit on its faces. Budgets halve per child (2^22, 2^26, 2^30, 2^34 for
one to four unknowns); a box below the domain-scaled noise width or out
of budget is reported unresolved. Unresolved boxes are rescued only into
existing certified roots, never clipped.

Curve/surface intersection with an implicit surface composes the curve
exactly into the implicit form (`P_h`), so the residual polynomial is
exact. An identically zero composition is an overlap; exact roots at
the domain ends are divided out exactly before isolation and reported
as points with their multiplicity (class `tangent` when it is two or
more). Same-circle arcs and collinear lines are resolved by periodic
parameter ranges: positive-length intersections are overlaps, touching
ends are points. Coplanar pairs use the 2D system, others the 3D one.
Surface/surface tracing finds the branch points on the box faces,
pairs them per overlap group, walks ordered branches and samples them
with parameters on both surfaces (`par.bend` charts).

E2E: `tests/c07/e2e.py` (327 cases: random curve/surface and
curve/curve against an exact Sturm oracle, specials for tangency,
endpoints, seams, nappes, through-apex lines, coincident curves, arc
overlaps and touching, an endpoint tangency class, surface/surface
families with tangency and coincidence, graph patches and NURBS).

## 3. Face membership

`member(face, q)` decides whether a point on a face's surface lies
inside the face (1), outside (0) or cannot be certified (2). It walks a
path on the surface from `q` to a boundary point `R` and counts certified
crossings of the boundary edges with the path's cut planes: a segment on
planes; on cylinders, cones, spheres and tori a meridian leg and a
parallel leg, in either order (the reverse order makes arrival
transverse when `R` sits on a parallel edge). The parity, combined with
the arrival side at `R` (sign of `d · (N × T)`), gives the answer. Edges
whose control net lies in a cut plane, tangencies and unresolved roots
make that attempt uncertain; each edge is tried at three points and in
both orders before answering 2.

## 4. Point classification, orientation, cavities

`classify NODE X Y Z` first checks the point against every face it is
within `2^-40` of the part size of (distance to the surface plus
membership) and answers `boundary`. Otherwise it casts rays in up to
seven fixed directions: every certified simple hit inside a face is a
crossing, and a ray that meets a tangency, an edge, an overlap or an
unsupported face is discarded. The first clean ray decides by parity;
if none is clean the answer is `uncertain`.

Orientation: for each shell, an interior point of one face (offset from
an edge midpoint inward, projected onto the surface, certified by
membership) shoots rays along directions within the outward normal's
open half-space, counting crossings of the faces of the same solid
only. Even parity means the shell faces outward. Cavities: each cavity
is classified against the outer shell (must be inside) and against
every other cavity (must be outside), after a box test.

## 5. Embedding check

`check NODE` certifies, for every pair of entities whose boxes overlap
(sweep and prune over sorted boxes, `O((E+F) log(E+F) + k)` candidate
pairs, checked in parallel):

- **Edge/edge.** Intersections other than shared vertices are crossings
  (or overlaps). At a shared vertex the corner cell of the parameter
  square is excluded only when the restricted control nets of both edges
  lie in cones separated by a plane with margin `m > 0`; every
  intersection inside the cell is then within `gap / m` of the vertex,
  where `gap` is the distance between the two edges' endpoints, and the
  cell is excluded only when that radius is within tolerance. Control
  points equal to the endpoint in the input data are skipped exactly, so
  degenerate parametrizations (doubled control points) do not defeat the
  test.
- **Edge/face.** For edges not bounding the face: points inside the face
  (membership 1) are penetrations; overlaps are decided by the
  membership of a point of the overlap. An edge lying on another face of
  the same surface (exactly coincident surfaces of its own faces) is
  decided by the membership of its midpoint.
- **Face/face.** Exactly coincident surfaces are checked for overlap with
  interior points of each face; planes, and planes or cylinders parallel
  to a common direction, cannot meet in closed curves and are skipped;
  planes cut coaxial cylinders, cones and tori, and spheres, in exact
  circles; everything else is traced. Samples on a closed component
  keep the worse rank: both interiors is a penetration and ends the
  walk; an uncertain membership outranks an outside sample; an outside
  sample alone is harmless; boundary contact that is not two interiors
  is harmless. A sample on a plane or a right cylinder whose box is
  disjoint from the hull of that face's boundary-edge boxes is outside,
  including when the point lies on the supporting surface. Sphere, cone
  and torus faces keep the membership answer. An empty or non-finite
  hull keeps the membership answer. Each unresolved trace box is
  reported as `face-face-uncertain`. Open components end on face
  boundaries and are covered by the edge/face checks.

Tolerances: shared-vertex corners `2^-30` of the part size; boundary
proximity `2^-20` of the part size. Findings name the entities; anything
not certified is reported as `...-uncertain`.

## 6. Topology constant over a parameter box (A5)

`zone NODE` for prisms, pads, pockets, holes and revolves certifies that
nothing in the design's combinatorial structure can change for any
parameter value in the zone, then bounds the measures:

1. **Identities.** Arc endpoints lie on their circles identically
   (`sym.bend` proves `(x-cx)^2 + (y-cy)^2 - r^2 = 0` in the exact
   rational normal form over the parameters), and loops close exactly.
2. **Non-degeneracy.** Segment lengths, radii and arc sweeps stay
   certified positive and below `2π`.
3. **Separation.** Every pair of non-adjacent primitives (within a
   loop, between loops of a profile, between a footprint and its face
   and sibling features) is separated by interval branch and bound over
   the primitives' parameters with the zone's intervals; adjacent
   primitives pass the corner cone test at their shared vertex.
4. **Heights.** Feature amounts stay positive, blind cuts leave
   material, and every comparison between a cell's heights and its
   parent's keeps its nominal sign or holds as an identity.
5. **Revolve.** Profiles stay off the axis except where a segment lies on
   it identically, and leave the axis transversally.

If the certificate fails, the zone is bisected along its widest
parameter (three levels) and certified piecewise. Volume and area use
interval dual numbers (value plus gradient) in mean-value form; where a
gradient component has constant sign over the box the bound is
evaluated at the corresponding corner, so monotone measures are tight to
rounding. Failure answers `topology-not-certified-over-zone`
(`numerical-uncertainty`).

## 7. A0

CLI: `classify`, `check`, `geom intersect A B [BOX]`, and `zone` for
every operation. MCP tools `classify`, `check`, `intersect`, updated
`zone`; `tools/mcp/language.md` documents the geometry syntax and the
answers.

## 8. Fixes to earlier packets found here

- Revolve emitted every cone on the `+z` nappe; cone faces below their
  apex lay on the nappe their surface does not contain (`revolve.bend`,
  law `ok_cone_axis_below_apex`).
- Full-circle whole-edge boxes were NaN; rays and broad phases used them
  (`cv_hbox`, laws `neg_full_circle_whole_box`, `ok_full_circle_hbox`).
- Same-circle arcs and collinear lines reported whole-domain overlaps
  when they only touched (laws `ok_arcs_*`, `ok_lines_touch`).
- An overlap's parameters are the clipped span on each curve. Two full
  circles of one circle are one overlap; a seam point whose parameter
  lies inside that overlap is dropped (`ok_lines_overlap_span`,
  `ok_full_circle_only_overlap`).
- Whole-domain restriction widened exact control points
  (`ok_restr_whole_exact`).
- `pmap` ran expensive items sequentially below 128 per chunk;
  `pmap_g` takes the grain.

## 9. Evidence

See the receipt `docs/receipts/c07-*.txt` for the commit, law runs and
E2E reports: `tests/c07/e2e.py`, `solid.py` (classification against
analytic oracles on ten parts and boundary points), `solid_neg.py`
(thirteen composed B-reps: inverted shells, cavities outside, nested or
crossing, overlapping and touching solids), `zone.py` (envelope
enclosure against sampled certified evaluations and analytic ranges,
tightness, four refusals). Laws: `laws/c07.bend` (one file) and
`laws/c07_build.bend` (one law per process).

## 10. Complexity and latency

| Query | Complexity | Measured (this machine) |
|---|---|---|
| `intersect` (curve/surface, curve/curve) | budgeted branch and bound | mean 0.114 s, max 0.384 s over 328 cases |
| `classify` | rays × faces with box culling | median 0.106–0.175 s on every E2E part |
| `check` | `O((E+F) log(E+F) + k)` pairs, parallel | 0.106–0.798 s on the ten E2E parts; 0.583 / 1.53 / 5.39 s for 25 / 100 / 400 holes |
| `zone` (profiles, features) | pairs of primitives with sweep pruning; eight dual evaluations | 0.105–0.244 s on the timed calls |

## 11. Limits and owners

- Bézier-patch and NURBS faces: intersections are supported. Membership
  and classification answer uncertain on them. An edge or face the
  embedding checker cannot certify is reported as
  `edge-check-unsupported` or `face-check-unsupported` (C11 with
  freeform trims).
- Exact containment and interference between solids: C11.
- Booleans that will call `check` on every result: C08.
