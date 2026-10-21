# K1 contract — crossing booleans and features anywhere

Scope (MASTER_PLAN §10 K1): regularized union, difference and intersection
of solids whose boundaries cross, touch or coincide, with plane, cylinder,
cone, sphere, torus and flat-patch faces; features on any planar face,
boolean results included; chamfers on circular hole and boss edges and on
straight edges; fillets on circular hole and boss edges; cones through
booleans, STEP and the archive. G2 is the first
gate that depends on it. No external kernel runs at any point; oracles are
closed-form volumes computed in the suites, the C04/C07 validators, and
OCCT reading the STEP export inside the test harness only.

## 1. Files

| File | Role |
|---|---|
| `src/k1/sf.bend` | Surface frames: plane, cylinder, cone (apex, axis, slope), sphere, torus (major and minor radius, tube-angle offset). Parameter maps, implicit forms, gradients, Newton projection |
| `src/k1/ef.bend` | Edge–face hits with exact certification on planes and the one-ulp-box rule on quadrics |
| `src/k1/ss.bend` | Surface–surface intersection: closed forms for plane/plane, plane/cylinder (tangent lines included), parallel cylinders, equal-radius cylinders with intersecting axes (two planar ellipses), plane/cone, and coaxial cylinder/cone and cone/cone; every other cylinder or cone pair by a discriminant scan over the rulings of one surface against the exact quadratic of the other |
| `src/k1/fb.bend` | Face boundaries in parameter space, per-face frames (sphere axes chosen with both poles clear of the face's edges, torus tube angle centred on the face), pole-aware point-in-face, face bounding boxes (cone tips, spheres and tori included), coplanarity |
| `src/k1/px.bend` | Edge–face hits (crossings on another face's boundary and endpoint touches become shared vertices), vertices of one operand splitting edges of the other, chains between break points, one-sided chains along existing edges, cubic Hermite intersection edges with midpoint-matched tangents and a measured deviation bound |
| `src/k1/gw.bend` | Per-face piece graph, cycle walk, regions, bands, polar caps on spheres and cone tips, holes, sample points |
| `src/k1/co.bend` | Coincident planar faces: crossings, T-junctions, ON classification |
| `src/k1/gb.bend` | `gbrun`: hits, coincident pairs, chains, per-face regions, classification, emission; coincident arcs merge by endpoints and arc midpoint |
| `src/k1/asm.bend` | Shell and solid assembly, cavity detection, certification of indices and edge use |
| `src/k1/vi.bend` | Certified volume and area: divergence theorem per face (plane, cylinder, cone, sphere by Archimedes' area element, torus by Green's theorem in the tube angle), Gauss–Legendre on curved edges with the order difference as bound, sliver bounds for tolerant edges |
| `src/c08/bool.bend` | K1 dispatch: fast paths first, K1 when they fail or when a union of face-touching solids would stay split; geometric lineage; tight result boxes |
| `src/c06/model.bend`, `sx.bend`, `cli.bend` | `(face NODE NAME)` selectors, features on named planar faces, `(chamfer BASE (face N NAME) (circle X Y R) C)`, `faces N -f` frames |
| `src/c07/mem.bend`, `sol.bend`, `isect.bend`, `emb.bend` | Parameter-space membership for tolerant faces, nappe-aware cones, sphere membership retried over several axes, closed-form equal-radius cylinder, coaxial sphere/cylinder, coaxial torus/cylinder and plane/sphere intersections, circle checks that accept boundary samples on shared edges, NaN-safe unresolved hits, orientation over every face |
| `src/c12/stepw.bend`, `stepr.bend`, `blob.bend` | `CONICAL_SURFACE` write and read; cones in the archive |
| `src/c03/ops.bend`, `src/c04/ops.bend` | Exact implicit forms for planes and flat patches; the one-ulp-box vertex rule extended to oblique planes and flat patches (axis-aligned planes keep the exact parametric rule) |

## 2. What a boolean certifies

A committed K1 result passes the full C04/C07 validator (`vcore`) and
carries a volume and area interval computed from the result's own
boundary. The interval is the exact divergence integral of the B-rep
plus three bounded terms: Gauss–Legendre order difference on curved
edges, the measured deviation of every tolerant edge from the true
intersection curve (twice the Newton projection distance at three
interior points), and floating-point widening. Measured on the corpus:
the perpendicular cross-bore difference encloses 906.7652525 in a band
of 7.4e-6; the countersink with a through bore encloses 874.8598926320
in 1.8e-9.

Intersection curves that are lines, circles or planar conic arcs are
exact edges. Other intersection curves are cubic Hermite segments
interpolating certified points on both surfaces, with tangents from the
cross product of the surface gradients, scaled so the cubic passes
through the Newton-projected midpoint. Faces bounded by such edges are
tolerant (`slv` is the deviation bound) and C07 tests membership on
them in the face's parameter space, consistently with the region the
kernel built.

## 3. Lineage

Every face of a K1 result is matched to the operand face it came from
by surface coincidence and membership of an interior point. A source
face that survives as several pieces gives names `NAME.p0`, `NAME.p1`,
… in result order. A selector naming the unsplit face is refused with
`ambiguous-selector` and the piece names. Boolean effects
(`faces_created`, `faces_modified`) are measured on these names.

## 4. Features anywhere

`(pad|pocket|holes BASE (face NODE NAME) …)` acts on the named planar
face of any body, boolean results included. The region is given in the
face's outward frame printed by `faces NODE -f`: origin `o`, x along
the surface's u axis, n the outward normal, y = n × x. Pads span
[0, h] along n and pockets [−d, 0], so a feature never touches material
above its face; `through` spans the whole body. The tool is placed
exactly when x, y and n are axis directions and the boolean runs
through K1.

`(chamfer BASE (edge N NAME1 NAME2) C)` chamfers the convex straight
edge where two named planar faces meet, at 45° by C, removing a
triangular prism along the edge that extends into the air at both ends.

`(chamfer BASE (face N NAME) (circle X Y R) C)` chamfers the circular
edge of radius R in that face at 45° by C, and `(fillet BASE (face N NAME)
(circle X Y R) RHO)` rounds it with radius RHO. The fillet removes a
revolved region bounded by a torus that is tangent to the face and to the
hole or boss wall; the two tangent circles are exact edges. The kernel decides hole or
boss from the face's own material just outside the circle and removes a
revolved triangle whose hypotenuse is the chamfer cone, extended into
the hole's void or the air beside the boss so that no tool face
coincides with a part face.

## 5. Refusals and reason codes

Refusals are named. When K1 cannot certify a crossing case the C08
message ends with `[k1 reason N]`:

| N | Meaning |
|---|---|
| 2 | An operand has a curved Bezier or NURBS face (`curved-surface-operand`) |
| 31 | A shell's container could not be decided |
| 40 | The result is empty after classification |
| 41, 42, 43 | Index, edge-use or tolerance certification of the assembled result failed |
| 44 | Assembly counts disagree with emission |
| 71 | Two surfaces touch at isolated points or nearly touch along a scanned curve (a plane through a cone apex, skew quadrics grazing) |
| 72 | An intersection point could not be certified on both surfaces |
| 73 | Surface pair outside §1 (a plane meeting a cone in an open conic; a torus against anything but a coaxial cylinder, a plane perpendicular to its axis or a plane through its axis) |
| 81 | An edge passes too close to a face to separate crossing from touching |
| 82 | An edge–face hit could not be certified |
| 86 | Internal: an intersection kind reached emission without a handler |
| 91, 92 | A region had no certifiable sample point, or its classification was uncertain |
| 93, 94 | Piece cycles or regions did not close |
| 95 | A trim point could not be placed exactly on its plane |
| 97 | Coplanar crossing computation failed |

Results that would be non-manifold, such as the union or intersection of
equal-radius cross bores, which touch themselves at two tangent points,
are refused as `non-manifold-result`. The difference of the same
operands is certified.

Face pairs whose surfaces K1 cannot intersect (a torus against a
non-coaxial cylinder or torus) are first tested for separation, and a
separated pair is not intersected: their boxes are disjoint; one face's
box, or the vertices of its sector polygons, lies strictly inside a
cylinder or sphere carrying the other face, or strictly outside it; one
face's box lies outside the wedge (the two half-planes through the axis
at the face's end angles, span below 180 degrees) of a cylinder or torus
face; or, for two faces with parallel axes, every piece of one face's
annular sector cover (eight convex polygons: radial sides, inner chord,
two tangent lines to the outer arc, all widened by 1e-9) is separated
from every piece of the other's by a separating axis. This is what lets
the blades of an impeller, curved walls 60 degrees apart, be unioned one
after another onto the hub.

Tangent contact along a curve is not refused: a plane tangent to a
cylinder along a line, a sphere or cone tangent to a coaxial cylinder,
and a torus tangent to a plane or cylinder along a circle all give exact
edges, and the faces on either side classify from interior samples. Revolved
parts meeting along shared seams (a ball on a shaft of the same radius, a
sphere centred on a box corner) are certified: an edge crossing the other
solid's edge or ending on it becomes a shared vertex, a vertex lying on the
other solid's edge splits that edge, and an intersection running along an
existing edge reuses it.

An edge that passes near a face only at one of the other solid's
vertices lying on the edge (a blade's fillet seam ending where a fillet
torus touches the base plane) is not refused as reason 81. A torus face is
boxed by the meet of its edges' box widened by twice the tube radius and
the torus box; edge distances to circular trims are measured to the
trimmed arc, not the full circle. A coedge reversed against its curve
keeps its trim points in loop order.

## 6. Oblique planes

A vertex on an axis-aligned plane must be hit exactly by the plane's own
evaluation, as before. A vertex on an oblique plane or a flat Bézier
patch (slanted prism walls, hex sockets, chamfer faces) is certified
the way quadric vertices are: the exact implicit function changes sign
inside the vertex's one-ulp box, and every trim evaluates to within four
ulps of the point's magnitude. Patch parameters come from Newton
iterations on the patch's own evaluation followed by an ulp scan.

## 7. Evidence

- `tests/k1/corpus.py` (15 members): perpendicular bores of equal and
  unequal radius, an off-axis passage, a port into a figure-eight
  chamber, a counterbore, an O-ring groove, a countersink with a
  through bore (cones), features on side faces of plain and boolean
  bodies, hole and boss chamfers, straight-edge chamfers, the G3
  limits L1, L3 (socket-head screw with hex socket) and L4, a gear-pump
  body (figure-eight chamber, O-ring groove following it, side port),
  spheres (a spherical dimple, a ball on a shaft of equal radius, a
  sphere lens) and fillets on a hole rim and a boss rim. Each
  checks closed-form volumes, |A∪B| + |A∩B| = |A| + |B|, the B-rep
  checker, genus, STEP volume read back by OCCT to 1e-6, replay, and
  archive reopen.
- `tests/c08/e2e.py`, `tests/c08/neg.py`: the C08 crossing, flush,
  touching and feature-on-boolean journeys flipped from refusal to
  certified results.
- Laws (`laws/k1`): face-box disjointness is symmetric (the pair
  prefilter cannot depend on operand order); faces without tolerant
  edges always use the certified surface-path membership; lineage emits
  exactly one name per result face. Each family kills its mutant.
- Pins (`tests/k1/pins.bend`): closed-form cone, sphere and torus
  intersections (tangent circles included) and dispatch codes, box
  disjointness, the cone area term, split-piece names, membership choice,
  sphere admission and curved-patch refusal, outward-frame handedness.

## 8. Not yet delivered

- A torus against a surface that is not coaxial with it (reason 73); fillet
  tools are coaxial with the edge they round, so they do not need this.
- Fillets on straight edges and on concave edges (boss bases); chamfers on
  concave edges.
- Placements by a general rotation (`interval-placement`), and features
  on faces whose frame is not axis-aligned (`feature-face-oblique`).
  Oblique faces made by prisms and booleans are supported; rotating an
  operand by a general angle is not.
- Open conics where a plane meets a cone at or beyond its slope (reason 73).
- Coplanar faces of one surface that end up adjacent are not merged
  into one face; the result is valid but carries extra faces.
