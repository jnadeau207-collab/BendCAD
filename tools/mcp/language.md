# BendCAD design language (C06–C15)

A design is a list of parameters and nodes. Every node is one operation with a
declared intent. Edits are atomic: a change is committed only if every node
builds a valid solid (checked by the kernel's B-rep validator) and every
node's measured effect matches its intent. Otherwise nothing changes and each
failure is reported as `error KIND | what @ where | why: ... | fix: ...`.

## Edits

- `(param NAME NOM)` or `(param NAME NOM LO HI)` — add or change a parameter
  (nominal value and tolerance zone, `LO <= NOM <= HI`; units are millimetres
  by convention).
- `(node ID OP INTENT)` — add a node, or replace the node with that id.
  A node may only use nodes with smaller positions in the list as inputs.
- `(delete ID)` — remove a node.

## Expressions

Numbers (`12`, `2.5`, `-3`, `1e-3`; no leading `+`, no `inf`/`nan`),
parameter names (`W`), and `(+ a b)`, `(- a b)`, `(- a)`, `(* a b)`, `(/ a b)`.

## Profiles (in the body's local x-y plane)

- `(circle CX CY R)`
- `(path X Y SEG ...)` — starts at (X, Y); each segment ends at a new point;
  the loop closes with a straight line back to the start unless the last
  segment already ends exactly there.
  - `(line X Y)`
  - `(arc CX CY R X Y ccw)` or `(... cw)` — an arc about centre (CX, CY) with
    radius R from the current point to (X, Y). Both endpoints must lie on the
    circle (the kernel certifies this to one unit in the last place; points
    such as `(CX+R, CY)` or tangent points of axis-aligned lines always pass).
- `(region OUTER HOLE ...)` — one outer loop and any number of holes. Loop
  winding does not matter. A region may sit inside a hole of another region
  (an island).

## Operations

- `(box X Y Z)` — the block [0,X] x [0,Y] x [0,Z].
- `(cylinder R H)` — radius R about the z axis, z in [0,H].
- `(prism Z0 Z1 REGION ...)` — extrude regions between heights Z0 < Z1.
- `(pad BASE FACE H REGION ...)` — add material: each region is extruded by H
  outward from a top face (+z) or bottom face (-z).
- `(pocket BASE FACE D REGION ...)` / `(pocket BASE FACE through REGION ...)`
  — remove material to depth D (flat floor) or through the body.
- `(holes BASE FACE D (hole X Y R) ...)` / `(holes BASE FACE through ...)`.
- `(rotate BASE AXIS DEG)` — rotate the placed solid about the world `x`, `y`
  or `z` axis through the origin by DEG degrees (counter-clockwise looking
  down the axis; |DEG| <= 1000000). Rotations and moves compose in order.
  Volume and area are unchanged; the bounding box is a certified enclosure
  (exact to rounding for boxes, cylinders, spheres and tori; arcs inside
  profiles are enclosed by their full circles).
- `(revolve REGION ...)` — a full turn about the z axis. Profile x is the
  radius and profile y is the height (z). The profile must lie in x >= 0; it
  may run along the axis (x = 0) but not cross it, a hole may not touch it,
  and the profile may not meet the axis at a single point between two
  non-axis segments (a pinch). Hole loops become internal cavities.
- `(cone R H)` — base radius R at z = 0, apex at z = H.
- `(sphere R)` — centred at the origin.
- `(torus R r)` — tube radius r about a circle of radius R in the z = 0 plane.
- `(move BASE DX DY DZ TURN)` — place the solid: TURN 0 none, 1 +90 deg about
  z, 2 180 deg about z, 3 -90 deg about z, 4 +90 deg about x, 5 +90 deg about y.
- `(union A B)`, `(difference A B)`, `(intersection A B)` — regularized
  booleans over closed solids whose boundaries do not cross (see Booleans).
- `(import 1 PAYLOAD)` — adopt an encoded format-1 B-rep body (the B1
  section of a BCAD2 archive). The body is fully validated by the B-rep
  checker; anything else is refused loudly and nothing is published.

An unknown operation name is rejected as `unknown-op`.

## Features (C09)

Lengths are ordinary expressions. Angles, twist counts, continuity tags,
edge indices and pattern counts are exact non-negative integers, not
expressions. A combination that is not in this list is `unknown-op` or
`invalid-input` and publishes nothing.

- `(sweep (line Z) REGION ...)` — prism of the regions from height 0 to Z.
  `(guide (line _))` is the same straight path; the proof contains
  `guide: path`. `(twist 0)` is the only twist.
- `(sweep (arc DEG) REGION ...)` — revolve convention (profile x is the
  radius, profile y is the height). DEG is 90, 180, 270, or 360. 90, 180
  and 270 are constructed sectors; 360 is the full revolve. A matching
  `(guide (arc DEG))` records `guide: path`. Partial sweeps are not a
  boolean cut.
- `(sweep (along PATH) REGION)` — one profile loop swept along one closed
  path in the xy plane: O-rings, gaskets, cords, blade-root blends. PATH
  is a counter-clockwise `(path ...)` of lines in any direction and arcs
  of any angle, counter-clockwise (convex) or clockwise (concave), joined
  tangentially, whose signed turns add up to one full turn: racetracks,
  rounded rectangles, crescents and blade footprints. Profile x is the
  offset outward from the path, profile y is z. Turns are revolve
  surfaces about each arc's centre (radius + u on counter-clockwise
  arcs, radius − u on clockwise ones), runs are planes and cylinders.
  Exact stations, no surface intersection; volume and area are certified
  Pappus sums with each turn's angle as a certified interval. A racetrack O-ring of section 3.18 x 1.95:
  `(sweep (along (path 0 -16.69 (line 22.05 -16.69) (arc 22.05 0 16.69
  22.05 16.69 ccw) (line 0 16.69) (arc 0 0 16.69 0 -16.69 ccw))) (region
  (path -0.615 -1.95 (line 0.615 -1.95) (arc 0.615 -0.975 0.975 0.615 0
  ccw) (line -0.615 0) (arc -0.615 -0.975 0.975 -0.615 -1.95 ccw))))`.
  Refusals: `path-piece-degenerate`, `path-not-tangent-continuous`,
  `path-not-one-turn`, `profile-reaches-path-turn-axis`,
  `sweep-needs-one-loop`.
- `(loft Z REGION_BOT REGION_TOP)` — bottom at z = 0, top at z = Z.
  Optional `(twist K)` rotates the top loop by K segments. Optional
  `(continuity g0)` or `(continuity g1)`.
- `(chamfer BASE D)` — equal setback on the four vertical edges of a box,
  or both rims of a cylinder. BASE is that box or cylinder node.
- `(fillet BASE R)` — rolling-ball radius on all 12 box edges, or both
  rims of a cylinder.
- `(fillet BASE (edge N) R0 R1)` — one vertical box edge, N = 0, 1, 2 or 3.
  Equal radii are a quarter-cylinder. Unequal radii refuse as
  `fillet-cone-not-certified`: no certified cone exists through the
  blend's exact tangent points.
- `(draft BASE INSET)` — box only. The top rectangle is inset by INSET on
  every side (a negative inset grows the top). The slope is
  `atan(INSET / Z)` and is not an exact bit, so the op stores the setback.
- `(offset BASE D)` — sharp normal offset, not a rolling-ball. Box becomes
  `[−D, X+D] × [−D, Y+D] × [−D, Z+D]`. Cylinder radius becomes `R+D` and
  the height grows by D at each end. Edges stay sharp.
- `(shell BASE T)` — closed wall: the outer solid minus a strictly interior
  solid, one cavity. `(shell BASE T open)` on a box is a blind pocket of
  depth `Z−T`, still a manifold solid.
- `(thicken BASE T)` — outward layer. For T > 0 on a box or cylinder the
  solid equals `(offset BASE T)`. Thicken does not take a negative
  distance. Offset and thicken are sharp normal offsets, not rolling-ball.
- `(pattern BASE (linear NX DX NY DY NZ DZ))` — NX, NY, NZ copies translated
  by multiples of (DX, DY, DZ). Copies must be strictly box-disjoint.
  `1×1×1` carries the base (`pattern-identity`).
- `(pattern BASE (circular N R))` — N = 4 only. Copies at `(R,0,0)`,
  `(0,R,0)`, `(−R,0,0)`, `(0,−R,0)`. The untranslated base is not extra.
- `(pattern-holes BASE FACE (linear NX NY DX DY X0 Y0) (hole R) DEPTH)` and
  `(pattern-holes BASE FACE (circular N RAD CX CY) (hole R) DEPTH)` — the
  existing holes evaluator. DEPTH is a length or `through`. Circular N is 4.
  FACE is `(face NODE CELL top)` or `(face NODE CELL bottom)`.

`zone` on every feature above answers `topology-not-certified-over-zone`.

Refusals, with the `why:` text verbatim:

- `sweep-angle-not-certified`, `guide-not-admitted`, `twist-not-admitted`,
  `continuity-not-met`, `chamfer-base-not-admitted`,
  `fillet-base-not-admitted`, `fillet-edge-not-admitted`,
  `fillet-cone-not-certified`,
  `draft-base-not-admitted`, `offset-base-not-admitted`,
  `shell-base-not-admitted`, `pattern-copies-overlap`,
  `pattern-angle-not-certified`, `pattern-count-not-admitted`
  (unsupported-op).
- `degenerate-feature`, `loft-face-not-planar`, `loft-self-intersection`,
  `loft-topology-mismatch`, `chamfer-consumes-face`, `fillet-consumes-face`,
  `draft-consumes-face`, `offset-self-intersection`, `shell-consumes-solid`
  (invalid-input).
- `features-need-an-extruded-body` (unsupported-op): pad, pocket and holes
  on a fillet, chamfer, loft, arc sweep, draft, offset, shell or pattern.
- `loft-not-certified` (numerical-uncertainty): a loft the rectangle
  classifier does not own. A boolean or validator inside shell, pattern or
  sweep that cannot certify returns that failure and publishes nothing.
- `kind-not-decomposed`, `rigid-budget`: `rigid_report` / `solve_drag`
  answers for a constraint kind outside the decomposable set, or a
  component with more than 32 points. There is no design-file syntax;
  `solve` itself is unchanged.

## Booleans

Operands must be closed solids with plane, cylinder, cone, sphere, torus or
exactly-flat patch faces, line, cubic, circle or rational-quadratic edges, and
certified-exact placements (`move` and quarter turns). Disjoint, contained,
contact-only and identical operands evaluate on the fast paths; operands
whose boundaries cross, touch or coincide go through K1 face splitting and
publish with `proof: k1-crossing-certified`. A union of solids that touch
across a face fuses into one solid. Intersection curves that are lines,
circles or planar conics are exact edges; other curves are cubic edges with
a measured deviation bound carried in the volume and area intervals.
Cavity faces are named `nN.cav.K.I.J`. A face that survives as several
pieces is named `NAME.p0`, `NAME.p1`, ...; selecting the unsplit name
refuses with `ambiguous-selector` and lists the pieces.

Refusals, with the `why:` text the kernel returns verbatim. When K1 could
not certify a case the text ends with `[k1 reason N]` (see
`docs/k1-contract.md` for the codes):

- `curved-surface-operand` (unsupported-op): an operand has a curved Bezier
  or NURBS face.
- `non-manifold-result` (unsupported-op): the regularized result would meet
  itself at isolated points (for example the union of equal-radius cross
  bores); change a radius or offset an operand.
- `interval-placement` (unsupported-op): a general-angle rotation baked at an
  uncertified midpoint; use `move` or quarter turns.
- `open-shell-operand`, `nurbs-operand`, `bezier-patch-operand`,
  `face-kind-not-supported`, `edge-kind-not-supported` (unsupported-op): the
  operand is outside the admitted domain.
- `contact-not-certified` (numerical-uncertainty): touching-only solids with
  no strict sample either way (e.g. distinct-node identicals).
- `uncertain-classification`, `no-container-sample`,
  `inconsistent-classification`, `validation-rejected`,
  `intersect-rejected`, `operand-failed-check` (numerical-uncertainty):
  classification or validation could not certify; an unrecognized future
  finding code reports as `unknown-finding: <code>` (numerical-uncertainty).
- `zone` on a boolean node answers `topology-not-certified-over-zone`.

Disjoint unions carry their proof: `proof: disjoint-boxes A[...] B[...]` with
both operand world boxes. Deleted lineage (`faces N -v`) lists consumed
input faces with reasons (`classified-away`, ...).

`FACE` is `(face NODE CELL top)` or `(face NODE CELL bottom)` for the top or
bottom face of a cell of an extruded body, or `(face NODE NAME)` for any
planar face by its name in `faces NODE`. A node's cells are numbered from 0
in the order its loops appear (each region's outer loop, then its holes; for
pads, pockets and holes, the footprint loops in order). `box` and `cylinder`
make cell 0. On a cell face, features act along the body's z axis; on a named
face they act along that face's outward normal, with the region given in the
frame printed by `faces NODE -f` (origin `o`, x, y = n x x, outward normal
`n`). Features apply to boolean results and to footprints that enclose or
cross earlier features. A hole must lie inside its face
(`curves-cross-or-touch` otherwise). `(chamfer BASE (face N NAME) (circle X
Y R) C)` chamfers the circular hole or boss edge of radius R in that face at
45 degrees by C; `(fillet BASE (face N NAME) (circle X Y R) RHO)` rounds
the same edge with radius RHO (0 < RHO < R); `(chamfer BASE (edge N NAME1
NAME2) C)` chamfers the convex straight edge between two named planar faces.
Tangent contact along a curve (a ball on a shaft of the same radius, a
fillet meeting its face) certifies; contact at isolated points refuses as
`non-manifold-result`.

## Intent

`(intent MATERIAL FACES_CREATED FACES_MODIFIED SOLIDS THROUGH_HOLES)`

- MATERIAL: `create` (first solid), `add`, `remove`, `same`.
- FACES_CREATED: faces whose lineage names are new at this node.
- FACES_MODIFIED: existing faces whose boundary changed (e.g. a top face that
  gains a hole).
- SOLIDS: solids in the result.
- THROUGH_HOLES: total through-holes (genus) of the result, counted from the
  B-rep with the Euler-Poincare formula.

Any count may be `any`. The kernel measures every field from the result
(material by comparing certified volume intervals) and rejects a mismatch.

## Queries

- `evaluate`: per node, the measured effect, certified volume and area
  intervals, bounding box, vertex/edge/face/solid counts, genus and the linear
  uncertainty (vertices of curved faces are within one ulp of their surfaces).
- `faces`: durable face names `nN.cK.top`, `nN.cK.bottom`, `nN.cK.wall.I.J`
  (wall of segment I of cell K, wall interval J). Names do not change when
  parameters change.
- `sensitivity`: estimated derivatives (central difference) of volume, area
  and bounding box with respect to a parameter, or the reason none exists.
- `zone`: volume and area certified over the whole tolerance envelope, i.e.
  for every parameter value inside its `[LO, HI]` zone. Every operation is
  covered: primitives by closed forms; prisms, revolves, pads, pockets and
  holes once the kernel certifies that the design's topology cannot change
  anywhere in the zone (arc endpoints stay on their circles for every
  parameter value, no two profile segments, holes or footprints touch,
  shared corners stay corners, depths leave material, revolve profiles stay
  off the axis). If that certificate fails even after splitting the zone
  the answer is `topology-not-certified-over-zone` (numerical-uncertainty):
  narrow the zones or move the features apart. Bounds are tight to within
  rounding when a measure is monotone in each parameter.
- `tessellate`: a watertight OBJ mesh with stated quality. Optional
  `preset` 0 (draft: chord 2 mm, angle 0.4 rad), 1 (default: 1 mm,
  0.2 rad), 2 (fine: 0.25 mm, 0.05 rad) or 3 (manufacturing:
  0.05 mm, 0.01 rad); `chord`, `angle`, `maxTris` and
  `profile` (`display` or `manufacturing`) override the preset.
  Shared edges share samples, indices are valid, and every edge
  of a closed solid belongs to exactly two triangles. The reply
  names vertex/triangle counts, the pre-build estimate, and the
  sampled chord/angle maxima, labeled sampled, not certified.
  When the estimate tops the budget nothing is written and the
  answer is `refused tess-budget-exceeded` with the estimate, the
  budget, and the fix (coarsen quality or raise the budget).
- `classify NODE X Y Z`: is the world point `inside`, `outside` or on the
  `boundary` of the node's solid (within 2^-40 of the part size)? Certified
  by exact ray casting; a point that sits on an edge seen from every
  direction answers `uncertain`.
- `check NODE`: certifies that the solid is embedded (no two edges cross,
  no edge pierces a face, no faces penetrate or overlap), that every shell
  faces outward and that cavities sit inside the outer shell and apart. It
  prints `ok: ...` or one line per finding (`edge-crossing E1 E2`,
  `edge-face-penetration E F`, `face-penetration F1 F2`, `face-overlap F1
  F2`, `inverted-shell S`, `cavity-outside S O`, `cavities-nested S1 S2`,
  or a `...-uncertain` variant). Contacts within 2^-20 of the part size of
  a shared edge or vertex belong to that edge or vertex.
- `dist NODE X Y Z`: closest point and distance from the world point to
  the node's solid. Inside or on the boundary answers `distance 0` with
  `status=certified`; otherwise the answer is an interval `[lo, hi]` with
  `status=estimated`: the lower bound is certified (no surface point is
  nearer than the face boxes), the upper bound is the nearest evaluated
  sample (`nearest=X,Y,Z`, `samples=N`).
- `extrema NODE`: the certified world-coordinate bounds of the node's
  solid (`status=certified`), plus the nearest vertex witness per bound
  (`status=sampled`: a witness need not attain the bound on curved faces).
- `mass NODE [DEPTH]`: mass properties at unit density. `volume` and
  `area` are the certified measure intervals; `centroid` and the
  centroidal `inertia` tensor (xx yy zz xy xz yz) come from bounded
  octree integration at depth DEPTH (0-6, default 4) with
  `cells=in/out/uncertain`. A cell counts as inside or outside only when
  its centre classifies strictly and no face box meets the cell, so the
  volume interval is certified; every sum is accumulated in outward
  rounded intervals. Empty certain volume answers `incomplete`.
- `section NODE A B C D`: section of the node's solid by the world plane
  `ax+by+cz=d`. One block per face with the plane/surface intersection
  curves (sample points with parameters on both surfaces), explicit
  unresolved boxes, and `coincident` faces lying in the plane, then
  `summary faces= curves= unresolved= coincident= status=`: `certified`
  when every face resolved, else `estimated`.
- `interf A B`: the exact relation between the solids of two nodes:
  `disjoint`, `inside a-in-b`, `inside b-in-a` or `interference`, each
  with `status=certified`, else `uncertain` with per-side
  in/out/uncertain sample counts. When the boxes overlap, the exact
  boolean intersection of the two placed solids is tried first: an empty
  result is `relation disjoint status=certified method=exact-intersection`
  (disjoint interiors: solids that touch along faces, edges or tangent
  curves, such as an O-ring seated in its gland, share no volume). A
  non-empty result keeps the sampled verdict (containment, certified
  interference); when sampling is uncertain it becomes `relation
  interference status=certified method=exact-intersection volume=[lo, hi]`.
  If the boolean refuses, sampling alone decides. Disjointness and containment are
  certified by strict samples plus disjoint face boxes; interference is
  certified by a strictly inside sample. AABB overlap alone is never
  reported as interference. The reply starts with the exact per-solid
  cavity verdicts (`cavity C inside O`, `cavities C D disjoint`, each
  `certified` or `estimated`).
- `clearance A B`: clearance between the solids of two nodes. Proven
  interference answers `clearance 0` with `status=certified`; otherwise
  the answer is an interval `[lo, hi]` with `status=estimated` and a
  certified lower bound (`lo=certified`).
- `wall NODE`: minimum wall thickness by the qualified exhaustive method:
  every non-adjacent face pair contributes a certified lower bound, and
  samples contribute the upper bound (`status=estimated lo=certified`,
  with face/pair/prune counts). Faces sharing a vertex are adjacent and
  excluded; a solid with no non-adjacent pair answers `min-wall none`.
  A depth or plane argument outside its domain is `invalid-input` and
  publishes nothing, as do all query failures.
- `diagnose`: one JSON object per evaluated node (`{"node":N,"ok":true}`
  or `{"node":N,"ok":false,"code":C,"kind":...,"what":...,"loc":...,
  `"why":...,"fix":...}`), one per line. Machine-readable form of the
  eval failures; see Errors and resources.

## Geometry queries

`intersect A B [BOX]` intersects two curves, a curve and a surface, or two
surfaces, independent of any design. It returns certified points (with the
parameters on each input and a class such as `interior`, `a-start`,
`a-end`, `seam` or `tangent ...`), overlaps (parameter ranges where the
inputs coincide), traced intersection curves (closed or open, with sample
points and parameters on both surfaces) and every unresolved region as an
explicit box. Nothing found inside a box that is not reported unresolved
means no intersection there. Surface/surface queries need `BOX`.

- `(line PX PY PZ DX DY DZ T0 T1)` — point plus parameter times direction.
- `(circle CX CY CZ UX UY UZ VX VY VZ R T0 T1)` — `U`, `V` orthogonal unit
  directions; parameter `t` in `[-1, 1]` is the full circle, at angle
  `4 atan t` from `U` toward `V` (the seam is `t = -1 = 1`).
- `(bezier X0 Y0 Z0 X1 Y1 Z1 X2 Y2 Z2 X3 Y3 Z3 T0 T1)` — cubic.
- `(conic X0 Y0 Z0 X1 Y1 Z1 X2 Y2 Z2 W0 W1 W2 T0 T1)` — rational quadratic.
- `(nurbs (knots K...) (pt X Y Z W) ...)` — cubic NURBS curve.
- `(plane OX OY OZ UX UY UZ VX VY VZ)`, `(sphere CX CY CZ R)`,
  `(cylinder OX OY OZ AX AY AZ R)`, `(cone OX OY OZ AX AY AZ K)` (apex `O`,
  axis `A`, radius `K` per unit height, the nappe on the `A` side),
  `(torus OX OY OZ AX AY AZ R r)`, `(bezpatch X00 Y00 Z00 ... )` (16
  control points, row by row).
- `BOX` is `(box X0 X1 Y0 Y1 Z0 Z1)`.

## Assemblies

`assembly` solves and queries an assembly: named instances of design nodes
with placements, plus mates. Actions: `solve` (solved placements, kinematic
dof, redundant mates, lineage), `interf` and `clear` (pairwise certified
interference and clearance over the solved placements), `explode` (exploded
placements along a direction) and `faces` (assembly-qualified durable face
names `INST.nN.cK.top|bottom|wall.I.J`). The assembly text is one
`(assembly ...)` form; it is solved fresh on every call, so design edits
propagate through it.

- `(inst NAME NODE TX TY TZ Q)` — instance of design node `NODE` with
  initial translation and turn code `Q` (0-5, as `move`).
- `(fix ID INST)` — pin the instance to its declared translation.
- `(coinc ID A AX AY AZ B BX BY BZ)` — the point `(AX,AY,AZ)` in A's node
  frame coincides with `(BX,BY,BZ)` in B's node frame.
- `(plane ID INST BX BY BZ NX NY NZ D)` — the instance point lies on the
  world plane `NX x + NY y + NZ z = D`.
- `(axis ID INST BX BY BZ PX PY PZ DX DY DZ)` — the instance point lies on
  the world axis through `P` along `D`.

Orientations are fixed per instance; mates solve translations exactly as a
linear system through the C05 rank machinery, so `dof` is 3 per instance
minus the rank, redundant mate ids are reported, and an inconsistent set is
a named `conflict` with the violating mate ids and no placements published.
`solve` on an underconstrained assembly reports `underconstrained` with one
satisfying configuration. `explode` needs `dx dy dz gap`: instance `k` moves
`k * gap * dir` from its solved placement.

```
(assembly
  (inst housing 1 0 0 0 0)
  (inst shaft 2 0 0 10 0)
  (fix 1 housing)
  (axis 2 shaft 0 0 0 0 0 0 0 0 1)
  (plane 3 shaft 0 0 5 0 0 1 10))
```

## Sheet metal (C16.1)

`(flat L W T)` is the blank: the block [0,L] x [0,W] x [0,T].
`(bend BASE (edge N) R DEG)` bends the flange past edge N of a flat or
single-bent sheet with inner radius R: N 0 is the +x end up, 1 the +x
end down, 2 the -x end up, 3 the -x end down; DEG is 90 or 180. The
bend line sits at mid-length; R/T must clear the certified bound and
the blank must exceed twice the outer radius. `(hem BASE (edge N) L)`
folds a closed hem of length L: on a flat end it doubles the sheet
over L, after a single 90-degree bend it folds the bent flange tip.
Double bends form U channels (opposite ends, same direction, equal
radii); a hem may then fold one flange tip. Anything else — a third
bend, a Z, a 180 with a hem, a bend after a hem, a second hem — is
refused by name and publishes nothing. Bends keep every dimension an
expression of the design parameters, so param edits propagate through
the part and its flat pattern. Pockets, holes and zones do not apply
to sheet bodies: they answer the existing refusals.

`flat NODE KLO KHI` reports the flat pattern of a sheet node over the
K-factor zone 0 < KLO <= KHI < 1: one certified allowance interval
per bend, the hem lines, the developed runs, the developed length
interval and the blank box. The MCP `flat_pattern` tool takes
(design, node, klo, khi) and prints the same text.

## Surface modeling (C16.2)

`(loft-open Z BOT TOP)` is the open walls of the C09 admitted planar loft:
two axis-aligned rect loops, G0, no caps. `(sweep-open (arc DEG) REGION)`
is the open walls of one axis-aligned rect profile revolved DEG degrees
(90, 180 or 270) about the z axis, no end caps. `(patch (pt X Y Z) x 16)`
is one bicubic Bezier face through 16 control points. `(thicken-open BASE T)`
closes an open shell into a solid with wall thickness T: rect patches close
to slabs, rect ducts and rect sectors to tubes with a through-channel.
Curved patches, cone walls and oversize T refuse by name and publish nothing.
Open shells validate under the open-shell-1 profile; check, classify, dist,
interf, clearance and wall refuse open shells by name, and STEP export and
archive of an open shell are refused — thicken first, then measure and export.

`surf NODE` reports an open-shell node: one row per boundary edge with its
durable name `nN.eI` and certified or estimated length, the area, the
boundary length and the bounding box. The MCP `surface` tool takes
(design, node) and prints the same text.

```
(node 1 (loft-open 8
  (region (path 0 0 (line 10 0) (line 10 5) (line 0 5)))
  (region (path 1 1 (line 9 1) (line 9 4) (line 1 4))))
  (intent create any any any any))
```

## Blade sections (C16.3)

`(naca4 M P T C NPTS)` is a NACA 4-digit section of chord C: max
camber M percent, camber position P tenths, max thickness T percent,
NPTS uniform stations per surface (17, 33 or 65). Digits admit M 0-9,
P 0-9 with P nonzero when M is nonzero, T 06-24; the section publishes
as the unit-span slab so it measures like any solid. `(blade S0 S1 ...
Z TWIST TAPER)` stacks 2 to 8 naca4 sections into one ruled-loft solid
over span Z: linear twist schedule to TWIST degrees (0, 10, 20 or 30)
about the quarter-chord stacking axis, linear taper to TAPER tip-chord
percent (50, 75 or 100). Sections must share points and chord; anything
else is refused by name and publishes nothing. Blades are closed solids:
measure, check, tessellate, STEP and archive all apply; features, zones
and pockets answer the existing refusals.

`blade NODE` reports a blade node: one row per section with its digits,
chord, stacking height, certified area, centroid, max thickness and max
camber intervals, the stacking-axis deviation and the twist schedule.
The MCP `blade` tool takes (design, node) and prints the same text.

```
(node 1 (naca4 4 4 12 100 17) (intent create any any any any))
(node 2 (naca4 4 4 12 100 17) (intent create any any any any))
(node 3 (blade 1 2 200 20 75) (intent create any any any any))
```

## Semantic PMI

`pmi` binds dimensions, tolerances and datum reference frames to durable
face selectors, with ISO GPS / ASME Y14.5 semantics. Actions: `check`
(validate and evaluate every entry), `stack` (worst-case 1-D stack-ups
over the tolerance envelope and operating states), `toler` (per-state
interference/clearance plus the envelope estimate) and `step42` (STEP
AP242 export carrying the PMI). The PMI text is one `(pmi ...)` form,
evaluated fresh on every call, so design edits propagate through it.

- `(node N)` or `(nodes A B)` — the design node every selector resolves
  against (`check`, `stack`, `step42`), or the toler pair.
- `(datum NAME SEL)` — datum bound to a face selector exactly as printed
  by `faces` (`nN.cK.top|bottom|wall.I.J`).
- `(dim NAME PARAM)` — size dimension bound to a design parameter (nominal
  and zone come from the parameter); `(dim NAME NOM LO HI)` — explicit
  numbers.
- `(tol NAME KIND T SEL rfs DATUM...)` — tolerance of kind `flatness`,
  `perpendicularity` or `parallelism` with value `T` on face `SEL`; the
  datum references list in DRF order (`flatness` takes none, orientation
  takes exactly one).
- `(state NAME GROW)` — operating state: uniform growth `GROW` about the
  design origin (finite, positive).
- `(stack NAME DIM...)` — a 1-D stack-up over one or more dims.

```
(pmi (node 1)
  (datum A n1.c0.top)
  (dim dW W)
  (tol t1 flatness 0.02 n1.c0.bottom rfs)
  (tol t2 perpendicularity 0.05 n1.c0.wall.0.0 rfs A)
  (state cold 1) (state hot 1.002)
  (stack s1 dW))
```

## Materials, threads and fits (K2)

Two more edits go through `apply` with the nodes and persist in `show`:

- `(material NODE GRADE RHO CTE [E NU])` — named grade (`6082-T6`, `16MnCr5`,
  `NBR70`), density in kg/m3 and linear expansion in 1/K. `mass N` then
  prints the mass interval in kg; rebinding replaces the grade.
- `(thread NODE NAME FACE DESIG CLASS Z0 Z1)` — ISO metric thread on the
  cylinder `FACE` (as printed by `faces`), designation `M8` (coarse pitch)
  or `M8x1.25`, class `5H 6H 7H 6G` on holes or `4h 6h 6g 6f 6e` on
  shafts, axial span `Z0..Z1` along the face axis. Model a tapped hole at
  its tap-drill diameter (inside the ISO 965-1 minor window; M8 6H takes
  6.647–6.912, so 6.8) and a screw at its major diameter; the kernel
  refuses a bore outside the window. `threads N` lists them; `step`
  exports material and threads as AP242 data.

Assembly verbs on the same `(assembly ...)` text:

- `asm mass (assembly ...)` — per-instance and total mass; every instance
  needs a material.
- `asm engage IA THREAD IB THREAD (assembly ...)` — certified axial
  engagement of two coaxial threads of one designation, with the ratio to
  the diameter (aim for 1.5 d or more in aluminium).
- `asm gap IA IB [FACE ...] (assembly ...)` — certified minimum gap
  between two placed z-extruded parts (gear tip to bore, gear to gear).
- `asm mesh IA ZA IB ZB (assembly ...)` — certified minimum gap of two
  meshing gears over one full pitch: A turns about its placed origin, B
  turns the other way at ZA/ZB. Model each gear centred on its node
  origin with the tooth phase it has at assembly.
- `(press NAME A AFACE B BFACE)` inside the assembly form declares a press
  fit between the hole face of one instance and the shaft face of the
  other (face names as `faces` prints them). `asm interf` certifies the
  interference with a witness point inside both parts, prints the radial
  interference and `declared press-fit NAME status=declared` instead of a
  defect, and refuses a declaration that does not interfere. Certify the
  fit classes and temperatures with `pmi fits` (KIND `press`).
- `asm step FILE (assembly ...)` — STEP AP242 of the solved assembly: every
  placed instance is its own solid, in instance order (printed after the
  write).

Fits are PMI: `pmi fits (pmi (node N) (temp NAME T)... (fit NAME HN HFACE SN SFACE CLASS KIND)...)`
evaluates ISO 286 classes (`H7/g6`, `H7/p6`, `H7/k6`; holes D E F G H JS,
shafts d e f g h js k m n p r s, grades 5–11, up to 500 mm) on two
cylinders of one nominal size, at every temperature, growing each part
with its own material. `KIND` is `clearance`, `press` or `transition` and
must hold at every temperature; otherwise the fit is refused with the
per-state intervals printed.

```
(material 1 6082-T6 2700 23.4e-6)
(thread 3 tap8 n2.c0.wall.0.0 M8x1.25 6H 8 20)
pmi fits (pmi (node 2) (temp cold 20) (temp hot 80)
  (fit run 2 n2.c0.wall.0.0 3 n3.c0.wall.0.0 H7/g6 clearance))
asm mesh drive 12 idler 12 (assembly (inst body 4 0 0 0 0) (inst drive 1 30 30 0 0)
  (inst idler 2 66 30 0 0) (fix 1 body) (fix 2 drive) (fix 3 idler))
```

## Errors and resources

Every kernel failure is `error KIND | what @ where | why: ... | fix: ...`
(request-level failures without a known location omit the `@ where`;
per-node failures prefix the line with `node N: `)
with KIND one of `invalid-input` (1), `unsupported-op` (2),
`numerical-uncertainty` (3), `nonconvergence` (4), `cancelled` (5),
`resource-exhausted` (6). Budget and profile refusals are
`refused WHY | ... | fix: ...` and write nothing, as do all failures.
`diagnose` renders the same failures as JSON lines. Flags before the verb
bound a request: `--max-nodes N` refuses designs with more than N nodes
(`node-budget-exceeded`, nothing evaluated) and `--cancelled` refuses at
once (`request-cancelled`); both default off. The MCP server reports its
own timeout as `cancelled`/`cli-exceeded-timeout` (raise
`BENDCAD_TIMEOUT_MS`), honours `BENDCAD_MAX_NODES` on every design call,
and attaches a `diagnostics` array with the parsed failures to every tool
result. A printed verdict always exits 0; nonzero means the CLI never
reached its verdict (crash or unreadable file).

## Example

```
(param W 80 79.9 80.1)
(param H 50)
(param T 6)
(param R 8)
(node 1 (prism 0 T (region (path R 0 (line (- W R) 0) (arc (- W R) R R W R ccw)
   (line W (- H R)) (arc (- W R) (- H R) R (- W R) H ccw) (line R H)
   (arc R (- H R) R 0 (- H R) ccw) (line 0 R) (arc R R R R 0 ccw))))
   (intent create 10 0 1 0))
(node 2 (holes 1 (face 1 0 top) through (hole 10 10 3) (hole (- W 10) 10 3))
   (intent remove 2 2 1 2))
```

## Rotor analysis (K3)

- `mass N` also prints `moments volume=… centroid … inertia-centroid …
  status=certified method=divergence`: exact first and second moments of
  volume by the divergence theorem per face, certified intervals.
- `balance N PX PY PZ DX DY DZ RPM G`: ISO 21940-11 residual unbalance of
  node N about the axis through (PX, PY, PZ) along (DX, DY, DZ), at RPM, for
  balance grade G (mm/s, e.g. 2.5). Needs a material on N. Prints the
  certified mass, centroid offset from the axis, residual U = m·e (g·mm),
  permissible U_per = m·G/ω (g·mm), the products of inertia relative to the
  axis (kg·mm², zero when the axis is principal) and `within`, `exceeds`
  (both certified) or `undecided` when the intervals overlap.
- `rotor SPEC`: lateral critical speeds of a shaft by Timoshenko beam
  elements (shear deformation and rotary inertia) and Sturm-sequence
  bisection. SPEC is `(rotor (seg L OD ID E NU RHO) … (disc X M JD)
  (brg X KW KT) (n N) (modes K))`: segments in order along the axis (mm,
  E in MPa, RHO in kg/m³), rigid discs (kg, diametral inertia kg·mm²) and
  bearing springs (N/mm, N·mm/rad) at segment ends. Each speed is solved
  at N, 2N and 4N elements per segment; the observed convergence ratio
  gives the extrapolated speed and the interval is ± the last change
  (`status=estimated bound=refinement`). Gyroscopic stiffening is not
  modelled (conservative for forward whirl of overhung discs).

## Finite elements (K3)

`(material NODE GRADE RHO CTE E NU)` adds Young's modulus E in MPa and
Poisson's ratio NU (0 <= NU < 0.5) to a grade; `modes` and `spin` need
them.

- `modes N K H [PX PY PZ DX DY DZ R]`: the first K elastic natural
  frequencies (Hz) of node N's solid. The solid is meshed by isosurface
  stuffing on a body-centred cubic lattice of spacing H (inside/outside
  by certified ray crossings, cut points on the faces, warped vertices,
  dihedral angles bounded away from 0 and 180 degrees) into quadratic
  tetrahedra whose boundary midside nodes are projected onto the faces
  (curved, isoparametric). The spectrum is solved by block LOBPCG with a
  lockstep PCG preconditioner. Without the clamp the part is free and the
  six rigid modes are skipped; with it every mesh node within R of the
  axis through (PX, PY, PZ) along (DX, DY, DZ) is fixed (a bore keyed to
  a shaft). Each mode is solved at H, H/2^(1/3) and H/2^(2/3); the line
  `mode I hz=[A, B, C] est=E bound=D status=estimated` gives the three
  values, the extrapolation from the observed convergence ratio and a
  bound (the larger of the last change and the extrapolation step;
  `estimated-nonmonotone` doubles the larger change when the levels do
  not converge monotonically). Sharp edges are rounded at the scale of the
  lattice, so the bound includes that geometric error. Size H to the
  thinnest wall: the finest level has about four times the nodes of the
  first.
- `spin N RPM H PX PY PZ DX DY DZ R`: linear centrifugal response at RPM
  about the axis, with nodes within R of it clamped, or a free part when
  R = 0 (refused unless the centrifugal load is self-equilibrated about
  the axis). Prints, at the three levels with extrapolation and bound,
  `tip_growth_mm` (radial displacement of the outermost node),
  `max_growth_mm`, `max_von_mises_mpa` (at element quadrature points;
  re-entrant corners do not converge and show as non-monotone) and
  `work_nmm` (external work of the centrifugal load, twice the strain
  energy, converging from below). Spin softening is not modelled.
