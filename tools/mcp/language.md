# BendCAD design language (C06–C08)

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

An unknown operation name is rejected as `unknown-op`.

## Booleans

Operands must be closed solids with plane, cylinder, cone, sphere, torus or
exactly-flat-patch faces, line, cubic, circle or rational-quadratic edges,
and certified-exact placements (`move` and quarter turns). Disjoint,
contained, contact-only and identical operands evaluate; anything else is
refused loudly and nothing is published. Contact never fuses: solids meeting
in a point, a curve or a zero-volume patch keep one solid per
volume-connected component. Cavity faces are named `nN.cav.K.I.J`.

Refusals, with the `why:` text the kernel returns verbatim:

- `boundaries-cross-or-overlap` (unsupported-op): boundaries genuinely cross
  (face splitting is not implemented); move the operands apart or nest one
  inside the other.
- `mixed-solid-relations` (unsupported-op): one operand has solids both
  inside and outside the other.
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
- `feature-on-boolean-result` (invalid-input): pads, pockets and holes apply
  to extruded bodies, not to boolean results; carried faces stay addressable
  through their original selectors.
- `zone` on a boolean node answers `topology-not-certified-over-zone`.

Disjoint unions carry their proof: `proof: disjoint-boxes A[...] B[...]` with
both operand world boxes. Deleted lineage (`faces N -v`) lists consumed
input faces with reasons (`classified-away`, ...); most non-crossing cases
have empty deleted lists.

`FACE` is `(face NODE CELL top)` or `(face NODE CELL bottom)`: the top or
bottom face of a cell. A node's cells are numbered from 0 in the order its
loops appear (each region's outer loop, then its holes; for pads, pockets and
holes, the footprint loops in order). `box` and `cylinder` make cell 0. A
feature footprint must lie strictly inside the selected face and clear of every
feature already on it. Features act along the body's z axis. Pads, pockets
and holes apply to extruded bodies (box, cylinder, prism and their features,
moved or not); on a revolved body they are rejected as `unsupported-op`.

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
- `tessellate`: a watertight OBJ mesh.
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
