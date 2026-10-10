# C09 intent — professional feature modeling

Status: binding spec for this packet. Implementation, laws, tests, and
the receipt follow this file. `docs/c09-laws.md` is equally binding.
Scope authority: MASTER_PLAN §10 C09. Method authority: A2, §14, §15,
AGENTS.md.

MASTER_PLAN §10 C09 (verbatim): "Add sweep, loft, fillet, chamfer,
draft, offset, shell/thicken, and feature patterns. Cover guide curves,
continuity, twist, self-intersection, variable-radius blends, corner
construction, and topology evolution. Use the same evaluator path for
all future human and agent clients. C09 also owns rigid-cluster
decomposition in the C05 solver, for drag and incremental re-solve over
large single clusters (A5). Exit: each feature family has ordinary
mechanical cases, degenerate cases, repeated downstream edits,
bounded-error reports, and native Bend implementation evidence. One
successful fillet does not qualify the family."

## 0. Decisions that keep the packet honest

Every published solid is built in Bend from C03 surfaces the kernel
already validates (planes, cylinders, cones, spheres, tori, and the
lines, circles, and arcs those faces need) and passes C04
`brep_checked` on the manifold-solid profile and C07 `check` before
publication. A feature that cannot certify that result fails with a
named diagnosis and publishes nothing. No voxel, mesh, OCCT, or
midpoint stand-in. No op returns a plain box and calls it a fillet.

Phenomena the plan says to cover, and that this admitted domain cannot
certify, are refused with the diagnosis named below. A refusal is a
completed out-of-domain case. It is not a substitute for the in-domain
case, which must publish a real solid.

Partial revolution is not a boolean against a half-space. C08 refuses
crossing boundaries (`boundaries-cross-or-overlap`). Sweep angles,
fillets, chamfers, drafts, and lofts are constructed directly.

`solve` / `solve_go` / `solve_cl` stay bit-identical. Rigid-cluster
decomposition is a new entry point (`rigid_report`, `solve_drag`). It
is not wired into the default solve path.

Zone on every new feature op answers
`topology-not-certified-over-zone`. Do not let a new op fall through
`zone.bend`'s prism wildcard.

## 1. Syntax

Same design file as C06–C08. New ops, cache tags in parentheses:

```text
(sweep (line Z) REGION ...)                         (17)
(sweep (arc DEG) REGION ...)                        (18)
(sweep (arc DEG) REGION (guide PATH) (twist T))
(loft Z REGION_BOT REGION_TOP)                      (19)
(loft Z REGION_BOT REGION_TOP (twist K))
(loft Z REGION_BOT REGION_TOP (continuity g0|g1))
(chamfer BASE D)                                    (20)
(fillet BASE R)                                     (21)
(fillet BASE (edge N) R0 R1)                        (22)
(draft BASE INSET)                                  (23)
(offset BASE D)                                     (24)
(shell BASE T)                                      (25)
(shell BASE T open)
(thicken BASE T)                                    (26)
(pattern BASE (linear NX DX NY DY NZ DZ))           (27)
(pattern BASE (circular N R))                       (28)
(pattern-holes BASE FACE (linear NX NY DX DY X0 Y0) (hole R) DEPTH)  (29)
(pattern-holes BASE FACE (circular N RAD CX CY) (hole R) DEPTH)      (30)
```

`DEPTH` is a length or the atom `through`. `DEG`, `T`, `K`, `N`,
counts and edge indices are exact non-negative integers in the source
text (not general expressions), except lengths, which are the usual
`Xp` expressions. `FACE` is the existing `(face NODE CELL top|bottom)`.

Unknown combinations parse as `unknown-op` or `invalid-input` naming
the op. They never publish.

## 2. Families

### Sweep

Profile convention for `(arc DEG)` is the C06 revolve convention:
profile x is the radius, profile y is the height. `(line Z)` uses the
C06 prism convention (region in the local xy plane, extruded from 0
to Z).

- `(line Z)` with Z > 0 delegates to the prism builder. Volume, face
  count, and `check` match the same region as a prism. This is the
  straight guide, twist 0, G0 along the ruling.
- `(arc DEG)` with DEG in {90, 180, 270} constructs that fraction of
  the full revolution. End caps are the coordinate planes of that
  angle (exact). 360 delegates to the existing full revolve, same
  solid as `(revolve REGION ...)`.
- Volume of a partial revolve of an admitted profile is
  `(DEG/360)` times the full-revolve volume. Rectangle
  `[r0,r1] × [z0,z1]` in the rz plane, r0 > 0:
  full volume `π (r1² − r0²) (z1 − z0)`, so 90° is a quarter of that.
- Axis-crossing, pinch, and the other revolve refusals reuse revolve's
  existing why-strings. A partial angle does not admit a profile the
  full turn rejects.
- DEG outside {90, 180, 270, 360} refuses as `sweep-angle-not-certified`.
- Z = 0 or a profile of empty area refuses as `degenerate-feature`.
- `(guide PATH)` is admitted only when PATH is the same line or the
  same arc as the sweep path. The publish proof contains `guide: path`.
  Any other guide refuses as `guide-not-admitted`.
- `(twist T)` admits only T = 0. Any other T refuses as
  `twist-not-admitted`. Omitting guide and twist is T = 0 and no guide
  claim.
- Self-intersection: a simple admitted profile revolved by at most 360°
  does not self-intersect. A self-crossing profile is rejected by the
  profile validator before the sweep. There is no second, quieter path.

### Loft

Two regions, one outer loop each, no holes, straight segments only,
the same segment count. Bottom at z = 0, top at z = Z > 0.
Correspondence is by vertex order. `(twist K)` rotates the top loop
by K segments (K = 0 if omitted).

- Each side quad must be exactly coplanar and of positive area, and
  adjacent side interiors must not overlap. Otherwise
  `loft-face-not-planar` or `loft-self-intersection`, in that order
  (non-planar wins when both apply).
- Different segment counts, an arc or a hole: `loft-topology-mismatch`.
- Z = 0: `degenerate-feature`.
- Identical aligned rectangles (same xy, twist 0) delegate to the
  prism builder. Volume is the base area times Z.
- Parallel rectangles (edges axis-aligned, twist 0), bottom area B1,
  top area B2, midsection area M (the rectangle of averaged vertices):
  volume `Z/6 · (B1 + B2 + 4 M)`. Square side `a` to square side `b`,
  which is the similar special case, is also `Z/3 · (a² + b² + a b)`.
- Default continuity is G0. `(continuity g0)` publishes.
  `(continuity g1)` on a positive-height loft with planar sides
  refuses as `continuity-not-met`: a planar side meets a horizontal
  cap at a right angle, so the tangent planes do not agree. Do not
  report G1 when the planes do not agree.
- One ordinary case is a centered square frustum (sides planar, twist
  0). A second is a non-square rectangular frustum. A third is the
  identical-rectangle prism. Degenerate cases are the refusals above.

### Chamfer

Equal setback `D > 0` measured along each adjacent face.

- Base op is `O_box` or `O_cyl` at its own node, not a moved, rotated,
  featured, or boolean body. Anything else:
  `chamfer-base-not-admitted`.
- Box, all four vertical edges. Profile is the rectangle with four
  corners cut by D. Requires `2D < X` and `2D < Y`. Volume
  `X Y Z − 2 D² Z`. Faces: 10 (octagon prism). Topology evolves from
  the box's 6 faces.
- The same constructor with a single vertical edge is also required,
  as `(chamfer BASE D)` is the four-edge form. The single-edge solid
  is the fillet-edge's chamfer sibling only if it falls out of the
  four-edge builder; do not add a second syntax. Four-edge is the
  ordinary box case. The cylinder is the second ordinary case.
- Cylinder, both rims, 45°. Requires `D < R` and `2D < H`. Faces: two
  planar caps of radius `R − D`, two conical bands, one cylinder of
  height `H − 2D` and radius R. Volume
  `π R² H − 2 π D² (R − D/3)`.
- `D <= 0`: `degenerate-feature`. Setback that eats a face:
  `chamfer-consumes-face`.

### Fillet

Rolling-ball constant radius, plus one variable-radius edge.

- Base op is `O_box` or `O_cyl`, same restriction as chamfer.
  Otherwise `fillet-base-not-admitted`.
- `(fillet BASE R)` on a box, `R > 0`, `2R` strictly less than each
  of X, Y, Z. All 12 edges. Topology: 6 planes, 12 quarter-cylinders,
  8 sphere octants (corner construction; the octants are not optional).
  Vertices 24, edges 48, faces 26, Euler characteristic 2.
  Let `a = X − 2R`, `b = Y − 2R`, `c = Z − 2R`. Volume
  `a b c + 2 (a b + b c + c a) R + π (a + b + c) R² + (4/3) π R³`.
- `(fillet BASE R)` on a cylinder, both rims, quarter-tori of tube
  radius R (the name R here is the fillet radius; call the cylinder
  radius `Rc`). Requires fillet radius `< Rc` and `2 · fillet < H`.
  Faces: two caps, two quarter-tori, one cylinder. One rim removes
  `π r² (2 Rc − r) − (π²/2) (Rc − r) r²`. The result volume is the
  cylinder volume minus twice that.
- `(fillet BASE (edge N) R0 R1)` on a box only. N is 0, 1, 2, or 3,
  the vertical edge at `(x, y)` in `{(0,0), (X,0), (X,Y), (0,Y)}`
  respectively. `R0 > 0`, `R1 > 0`, and twice the larger radius is
  strictly less than both X and Y. The blend is a quarter-cylinder
  when `R0 = R1` and a quarter-cone when they differ (linear radius
  along the edge). No sphere corner on this single-edge form: the
  edge's vertices stay on the unfilled horizontal edges. Faces: 7.
  Let `I = H (R0² + R0 R1 + R1²) / 3`. Removed volume
  `(1 − π/4) I`. Result volume is `X Y Z` minus that.
- Other N, a cylinder plus an edge selector, or a nonpositive radius:
  `fillet-edge-not-admitted` or `degenerate-feature`, whichever
  applies (nonpositive radius wins).
- Radius that eats a face: `fillet-consumes-face`.
- Variable radius other than this linear edge law is not a second
  syntax. This edge law is the admitted variable-radius blend.

### Draft

`(draft BASE INSET)` on an `O_box`. The bottom rectangle is the box
bottom. The top rectangle is inset by `INSET` on every side (negative
inset grows the top). Side faces are planes. This is a length, not an
angle: a transcendental draft angle is not parsed. Document in
`language.md` that the slope is `atan(INSET / Z)` and is not an exact
bit, so the op takes the setback.

- `2 INSET >= X` or `2 INSET >= Y` when inset is positive:
  `draft-consumes-face`. Other bases: `draft-base-not-admitted`.
- INSET = 0 publishes the same box. Proof text contains
  `draft-identity`. Material `same`.
- Otherwise volume
  `Z (X Y − INSET (X + Y) + (4/3) INSET²)`,
  which is the prismatoid formula. Faces: 6.

### Offset

Face offset: each face moves along its outward normal and the faces
are re-intersected. Sharp edges stay sharp. This is not a rolling-ball
offset; `language.md` says so. There is no rolling-ball syntax.

- Box: result is the box `[−D, X+D] × [−D, Y+D] × [−D, Z+D]`,
  provided each extended length is strictly positive. Volume
  `(X+2D)(Y+2D)(Z+2D)`.
- Cylinder: radius `R+D`, z from `−D` to `H+D`, provided `R+D > 0`
  and `H+2D > 0`. Volume `π (R+D)² (H+2D)`.
- A nonpositive extended length refuses as `offset-self-intersection`.
- D = 0 publishes the same solid. Proof contains `offset-identity`.
- Other bases: `offset-base-not-admitted`.

### Shell and thicken

- `(shell BASE T)`, T > 0, base `O_box` or `O_cyl`. Closed wall.
  Implemented as a C08 containment difference of the outer solid and
  a strictly interior solid (inset box, or coaxial inner cylinder of
  radius `R−T` and height `H−2T`). The result is one solid with one
  cavity, not a void-free solid. Box volume
  `X Y Z − (X−2T)(Y−2T)(Z−2T)`. Cylinder volume
  `π R² H − π (R−T)² (H−2T)`. Face count 12 for the box (6 outer +
  6 cavity). If the boolean cannot certify the cavity, shell fails
  with the boolean's diagnosis. Do not publish the outer solid alone.
- `(shell BASE T open)` on a box only. A manifold bin: the outer box
  with a blind pocket of depth `Z−T` and footprint inset by T. Volume
  `X Y Z − (X−2T)(Y−2T)(Z−T)`. Not an open shell. The evaluator
  publishes manifold solids; do not publish `P_open_shell`.
- T that eats the solid (`2T >= X` or `2T >= Y` or `2T >= Z` on a
  box; `T >= R` or `2T >= H` on a cylinder; open shell also
  `T >= Z`): `shell-consumes-solid`. T <= 0: `degenerate-feature`.
  Other bases, or `open` on a cylinder: `shell-base-not-admitted`.
- `(thicken BASE T)`, T > 0, base `O_box` or `O_cyl`. Outward layer.
  The solid equals `(offset BASE T)` and the original solid is inside
  it. A law pins equal volume intervals for thicken and offset on the
  same box. T <= 0: `degenerate-feature`. Thicken is not a synonym
  that accepts a negative distance; offset owns the signed distance.

### Patterns

- Linear: `NX, NY, NZ >= 1`. Copy `(i, j, k)` is the base translated
  by `(i DX, j DY, k DZ)` for `i = 0..NX−1` and likewise for j, k.
  The `(0,0,0)` copy is the base in place. Copies must be strictly
  box-disjoint. The result is their regularized union (C08). Overlap
  refuses as `pattern-copies-overlap` without attempting a crossing
  boolean. `1×1×1` publishes the base carried, proof `pattern-identity`.
- Circular: N = 4 only. Four translated copies of the base, by
  `(R,0,0)`, `(0,R,0)`, `(−R,0,0)`, `(0,−R,0)`. The untranslated base
  is not an extra copy. R = 0 or any N other than 4:
  `pattern-angle-not-certified`. Overlap:
  `pattern-copies-overlap`. Quarter-turn placement is exact; do not
  bake a general angle.
- A count of 0 refuses as `pattern-count-not-admitted`.
- Hole patterns call the existing holes evaluator. Linear positions
  are `(X0 + i DX, Y0 + j DY)`. Circular positions are
  `(CX + RAD, CY)`, `(CX, CY + RAD)`, `(CX − RAD, CY)`,
  `(CX, CY − RAD)`, N = 4 only. Clearance, depth, and `through`
  reuse the holes diagnoses. Do not reimplement pocket cutting.
- Downstream: a pattern node can be `move`d by an exact `move` and
  then united with a disjoint solid. Pad, pocket, and holes on a
  fillet, chamfer, loft, sweep-arc, draft, offset, shell, or pattern
  result reuse the existing feature refusal (extruded bodies only).
  Assert that refusal and that the design file is unchanged.

### Rigid-cluster decomposition

In `src/c05/solve.bend`. Do not change `solve`, `solve_go`, or
`solve_cl`.

`rigid_report(ps, free, cs, tol, fuel)` returns a partition of one
connected component of point-carrying constraints, or a single
`whole` answer.

Constraints that may be decomposed: `K_coinc`, `K_horiz`, `K_vert`,
`K_dist`, `K_fix`, `K_on_line`, `K_midpoint`, `K_equal`, `K_hdist`,
`K_vdist`, `K_same`. Any other kind in the component, or more than
32 points, returns `whole` with a named reason
(`kind-not-decomposed` or `rigid-budget`). `whole` is reported. It
is not a silent fallback inside `solve`.

A cluster is a set of point indices. Seeds are the pairs (or larger
supports) of those constraints. Merge two clusters only when the
existing rank-revealing factorization, on the constraints internal to
the union, certifies that the union is a rigid body: its free-motion
dimension is 3, or less when fixes inside the union remove rigid
motions. Counting `2n−3` is not the certificate. Redundant constraints
may remain (a rectangle with both diagonals is still one rigid
cluster). A path of three distances on four points is three rigid
pairs, not one cluster. A triangle of three distances is one cluster.

`solve_drag(ps, free, cs, tol, fuel, dirty)` re-solves only clusters
that contain a dirty parameter index, plus clusters that share a
constraint with a dirty cluster, and copies every clean cluster's
coordinates from `ps` bit-identically. Two disjoint distance pairs:
dirtying a coordinate of the first leaves the second pair's
coordinates bit-identical. The result is the usual `Sol` plus the
cluster list. Clean clusters are not iterated.

Laws pin: the path of three distances (3 clusters), the rigid
triangle (1), the rectangle with one diagonal (1), a `K_tan_cc`
component (`whole`), and the disjoint-pair drag bit-identity.

## 3. Evaluator, intent, lineage, measures

New ops are `Op` arms in `src/c06/model.bend`, parsed and printed in
`src/c06/sx.bend`, dispatched from `op_build`. Cache tags are the
integers in §1. `op_w`, `op_base`, `op_has_base`, `op_name`, and every
other exhaustive `Op` match gain an arm. `zone.bend`'s four `Op`
matches gain an explicit arm that returns
`topology-not-certified-over-zone` for each new op, before any
wildcard.

Construction lives in `src/c09/feat.bend`. Revolve changes that the
partial sweep needs live in `src/c06/revolve.bend` and are called from
feat or model, not copied.

Intent uses the existing five-field gate, measured from the result:

- material `create` for sweep and loft;
- `remove` when the certified volume is strictly below the base;
- `add` when it is strictly above (offset growth, thicken, draft
  growth, union pattern);
- `same` for identities, carries, and equal volumes.
- faces created: every face of a from-scratch construction;
- faces modified: 0 on those constructions;
- a consumed base's faces are deleted lineage, with a reason
  (`chamfered`, `filleted`, `drafted`, `offset`, `shelled`,
  `thickened`, `patterned`);
- solids and through-holes come from the published B-rep.

Measures are the existing certified intervals. Tests assert that the
analytic value lies inside the printed interval. The interval is the
bounded-error report. Do not print a bare float as the volume.

Failure leaves the design unchanged. Diagnoses use C00 fail kinds:

- `invalid-input`: malformed arguments, intent mismatch, feature on a
  non-extruded result (existing text);
- `unsupported-op`: the `*-not-admitted`, `*-not-certified`,
  `continuity-not-met`, `pattern-copies-overlap` refusals;
- `numerical-uncertainty`: a boolean or validator inside shell,
  pattern, or sweep could not certify;
- `degenerate-feature` is `invalid-input`.

Every why-string above is verbatim and stable.

## 4. Complexity

Direct constructions (box fillet, chamfer, loft, draft, offset) are
O(1) in the input size they admit (fixed topology). Patterns are O(N)
unions of disjoint solids and must not call the crossing intersector.
Rigid merge is O(c²) rank calls on the clusters of one component, c
bounded by 32.

Budgets on this machine, one thread, admitted fixtures in §5: each
direct feature under 1 s; a 4-copy pattern under 5 s; `rigid_report`
on the law fixtures under 1 s. The receipt records the measured
times. A miss is a recorded budget miss, not a reason to drop the
case or weaken the check.

## 5. Tests and laws

`tests/c09/e2e.py` copies the `tests/c08/e2e.py` harness (`BENDCAD_BIN`,
`fresh`, `record`, `vol`, `fx`, `check`, `faces`, `measure`). It
writes `tests/c09/e2e-report.json`. Minimum journeys:

- sweep line vs the same prism (volumes equal, both contain the
  analytic value);
- sweep arc 90, 180, 270, 360 of rectangle r in [2,4], z in [0,3]
  (volumes 9π, 18π, 27π, 36π);
- sweep 360 face-count equals revolve of the same region;
- loft centered squares 10 → 6, height 5 (volume `980/3`);
- loft non-square rectangles, twist 0, prismatoid volume;
- loft identical rectangles equals the prism volume;
- chamfer four vertical edges of a 10-cube, D = 1 (volume 980,
  10 faces);
- chamfer both rims of cylinder R = 5, H = 10, D = 1
  (volume `722 π / 3`);
- fillet all 12 edges of a 10-cube, R = 1 (volume `896 + 76 π / 3`,
  26 faces, 8 sphere faces, 12 cylinder faces, 6 planes);
- fillet both rims of cylinder R = 5, H = 10, fillet radius 1
  (volume `232 π + 4 π²`);
- fillet edge 0 of a 10-cube, R0 = 1, R1 = 1, and again R0 = 1,
  R1 = 2 (constant and variable volumes from §2, 7 faces);
- draft of box 10×8×6, inset 1 (volume 380) and inset 0 (identity);
- offset box by 1 (volume 1728) and cylinder R = 5, H = 10 by 1
  (volume `432 π`);
- thicken of that box equals the offset volume;
- shell closed box T = 1 (volume 488, one cavity, `check` ok) and
  open box (volume 424);
- shell closed cylinder;
- linear pattern 2×1×1, DX = 20, of a 10-cube (volume 2000,
  2 solids) then `move` and disjoint `union`;
- circular pattern N = 4, R = 20, of a 10-cube (volume 4000,
  4 solids);
- linear and circular hole patterns whose analytic volumes are
  `box − n π r² depth` (through or blind), with `check` ok;
- parameter edit: rebuild the all-edge fillet after the box X
  changes, volume follows §2;
- replay: serialize, reopen, bit-identical volume text.

`tests/c09/neg.py` writes `neg-report.json`. One journey per
diagnosis in §2, asserted verbatim, design file unchanged on
rejection. Include: bad sweep angle, foreign guide, nonzero twist,
loft segment mismatch, loft g1, non-planar or self-intersecting loft,
chamfer and fillet on a moved body, consuming radii, zero radius,
draft consume, offset self-intersection, shell consume, pattern
overlap, circular N = 3, pad on a fillet result.

`laws/c09.bend`: parser round-trips, cache tags, the volume-formula
helpers' `F64.bits`, refusal classifiers, and the five rigid-cluster
laws. `laws/c09_build.bend`: one full evaluation per ordinary family
member (box fillet, box chamfer, square loft, arc-90 sweep, closed
shell), floats by `F64.bits`. A law must fail on the old behavior it
exists to forbid (a fillet that returns the untouched box, a drag
that rewrites a clean cluster, a g1 loft that publishes).

## 6. Docs

Update `tools/mcp/language.md` with the syntax and the verbatim
diagnoses. Append a C09 section to `docs/replacement-ledger.md`.
Point `docs/c06-contract.md`'s "partial revolution" line at this
packet once the arc sweep publishes. Do not edit `legacy/`.

README and MASTER_PLAN "Next is C08" flip to C09 closed / next is C10
only after the check phase has a green e2e, a green neg suite, and
`laws/c09.bend` printing `ALL PROOFS CHECK`. The receipt is
`docs/receipts/c09-2026-10-09.txt`, written from those runs, not
before them.

## 7. Bend rules for this tree

`Bool.pick` evaluates both arms. Use `match` to skip work. A match
scrutinee is a parameter or a field, never a computed call. Bind,
then match. Do not run `bend update`. Do not edit `legacy/`. Do not
weaken a volume, a diagnosis, or a law to go green. Do not commit or
push.
