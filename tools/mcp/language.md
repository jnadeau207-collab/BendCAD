# BendCAD design language (C06)

A design is a list of parameters and nodes. Every node is one operation with a
declared intent. Edits are atomic: a change is committed only if every node
builds a valid solid (checked by the kernel's B-rep validator) and every
node's measured effect matches its intent. Otherwise nothing changes and each
failure is reported as `error KIND | what @ where | why: ... | fix: ...`.

## Edits

- `(param NAME NOM)` or `(param NAME NOM LO HI)` — add or change a parameter
  (nominal value and tolerance zone; units are millimetres by convention).
- `(node ID OP INTENT)` — add a node, or replace the node with that id.
  A node may only use nodes with smaller positions in the list as inputs.
- `(delete ID)` — remove a node.

## Expressions

Numbers (`12`, `2.5`, `-3`), parameter names (`W`), and `(+ a b)`,
`(- a b)`, `(- a)`, `(* a b)`, `(/ a b)`.

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
- `(move BASE DX DY DZ TURN)` — place the solid: TURN 0 none, 1 +90 deg about
  z, 2 180 deg about z, 3 -90 deg about z, 4 +90 deg about x, 5 +90 deg about y.

`FACE` is `(face NODE CELL top)` or `(face NODE CELL bottom)`: the top or
bottom face of a cell. A node's cells are numbered from 0 in the order its
loops appear (each region's outer loop, then its holes; for pads, pockets and
holes, the footprint loops in order). `box` and `cylinder` make cell 0. A
feature footprint must lie strictly inside the selected face and clear of every
feature already on it. Features act along the body's z axis.

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
- `tessellate`: a watertight OBJ mesh.

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
