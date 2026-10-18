# K1 contract — crossing booleans and features anywhere

Scope (MASTER_PLAN §10 K1): regularized union, difference and intersection
of solids whose boundaries cross, touch or coincide; features on any
planar face, boolean results included; edge chamfers on circular hole and
boss edges; cones through booleans, STEP and the archive. G2 is the first
gate that depends on it. No external kernel runs at any point; oracles are
closed-form volumes computed in the suites, the C04/C07 validators, and
OCCT reading the STEP export inside the test harness only.

## 1. Files

| File | Role |
|---|---|
| `src/k1/sf.bend` | Surface frames: plane, cylinder, cone (apex, axis, slope). Parameter maps, implicit forms, gradients, Newton projection |
| `src/k1/ef.bend` | Edge–face hits with exact certification on planes and the one-ulp-box rule on quadrics |
| `src/k1/ss.bend` | Closed-form surface–surface intersection: plane/plane, plane/cylinder, cylinder/cylinder (parallel, skew by discriminant scan, equal-radius intersecting axes as two planar ellipses), plane/cone, cylinder/cone and cone/cone when coaxial |
| `src/k1/fb.bend` | Face boundaries in parameter space, point-in-face, face bounding boxes (cone tips included), coplanarity |
| `src/k1/px.bend` | Chains between break points, cubic Hermite intersection edges with midpoint-matched tangents and a measured deviation bound |
| `src/k1/gw.bend` | Per-face piece graph, cycle walk, regions, bands and holes, sample points |
| `src/k1/co.bend` | Coincident planar faces: crossings, T-junctions, ON classification |
| `src/k1/gb.bend` | `gbrun`: hits, coincident pairs, chains, per-face regions, classification, emission |
| `src/k1/asm.bend` | Shell and solid assembly, cavity detection, certification of indices and edge use |
| `src/k1/vi.bend` | Certified volume and area: divergence theorem per face (plane, cylinder, cone), Gauss–Legendre on cubic edges, sliver bounds for tolerant edges |
| `src/c08/bool.bend` | K1 dispatch: fast paths first, K1 when they fail or when a union of face-touching solids would stay split; geometric lineage; tight result boxes |
| `src/c06/model.bend`, `sx.bend`, `cli.bend` | `(face NODE NAME)` selectors, features on named planar faces, `(chamfer BASE (face N NAME) (circle X Y R) C)`, `faces N -f` frames |
| `src/c07/mem.bend`, `sol.bend`, `isect.bend`, `emb.bend` | Parameter-space membership for tolerant faces, nappe-aware cones, exact equal-radius cylinder intersection, NaN-safe unresolved hits, orientation over every face |
| `src/c12/stepw.bend`, `stepr.bend`, `blob.bend` | `CONICAL_SURFACE` write and read; cones in the archive |

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

`(chamfer BASE (face N NAME) (circle X Y R) C)` chamfers the circular
edge of radius R in that face at 45° by C. The kernel decides hole or
boss from the face's own material just outside the circle and removes a
revolved triangle whose hypotenuse is the chamfer cone, extended into
the hole's void or the air beside the boss so that no tool face
coincides with a part face.

## 5. Refusals and reason codes

Refusals are named. When K1 cannot certify a crossing case the C08
message ends with `[k1 reason N]`:

| N | Meaning |
|---|---|
| 2 | An operand has a sphere, torus or freeform face (`curved-surface-operand`) |
| 31 | A shell's container could not be decided |
| 40 | The result is empty after classification |
| 41, 42, 43 | Index, edge-use or tolerance certification of the assembled result failed |
| 44 | Assembly counts disagree with emission |
| 71 | Tangent plane/cylinder contact (fillets need it; see §7) |
| 72 | An intersection point could not be certified on both surfaces |
| 73 | Surface pair outside §1 (non-coaxial cone pairs, open plane/cone conics) |
| 74 | A plane meeting a curved surface is not axis-aligned |
| 81 | An edge passes too close to a face to separate crossing from touching |
| 82 | An edge–face hit could not be certified |
| 83 | An edge ends inside a face that no coplanar face of its own solid covers |
| 86 | Internal: an intersection kind reached emission without a handler |
| 91, 92 | A region had no certifiable sample point, or its classification was uncertain |
| 93, 94 | Piece cycles or regions did not close |
| 95 | A trim point could not be placed exactly on its plane |
| 97 | Coplanar crossing computation failed |

Results that would be non-manifold, such as the union or intersection of
equal-radius cross bores, which touch themselves at two tangent points,
are refused as `non-manifold-result`. The difference of the same
operands is certified.

## 6. Evidence

- `tests/k1/corpus.py` (10 members): perpendicular bores of equal and
  unequal radius, an off-axis passage, a port into a figure-eight
  chamber, a counterbore, an O-ring groove, a countersink with a
  through bore (cones), features on side faces of plain and boolean
  bodies, hole and boss chamfers, and the G3 limits L1, L3 and L4. Each
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
- Pins (`tests/k1/pins.bend`, 15): closed-form cone intersections and
  dispatch codes, box disjointness, the cone area term, split-piece
  names, membership choice, sphere refusal, outward-frame handedness.

## 7. Not yet delivered

- Sphere and torus faces in booleans (reason 2), and fillets, which need
  tangent plane/cylinder contact (reason 71) and torus tools.
- Placements by a general rotation (`interval-placement`), and features
  on faces whose frame is not axis-aligned (`feature-face-oblique`).
- Open conics on cones and non-coaxial cone pairs (reason 73).
- Chamfers on straight edges (G3-L7b for pad edges).
- Coplanar faces of one surface that end up adjacent are not merged
  into one face; the result is valid but carries extra faces.
