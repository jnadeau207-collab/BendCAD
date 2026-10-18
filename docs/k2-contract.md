# K2 contract — materials, threads, fits and certified clearances

Scope (MASTER_PLAN §10 K2): the engineering semantics G2 needs on top of
K1 geometry. Every part carries a named material grade with its density
and thermal expansion; threaded holes and shafts are semantic thread
features with ISO designations and classes; ISO 286 fits are evaluated per
material at every operating temperature; assembly mass, thread engagement
and 2-D clearances between z-extruded parts (gear tip to bore, gear to gear
at one placement, and gear to gear over a full mesh pitch) are certified
intervals. Material and thread data travel in the design file and the STEP
AP242 export. No external kernel runs at any point; oracles are closed
forms and shapely polygon distances computed inside the suites.

## 1. Files

| File | Role |
|---|---|
| `src/c06/model.bend` | `Part` carries `ms: List<Grade>` (`Gr{node, grade, rho, cte}`) and `ts: List<Thr>` (`Th{node, name, face, desig, cls, z0, z1}`) beside params and nodes |
| `src/c06/sx.bend` | `(material ...)` and `(thread ...)` forms: parse, print, persist in `show` |
| `src/c06/cli.bend` | `apply` validates materials and threads with the nodes (`part_errs`); `mass` reports the bound material; `threads N`; `asm mass/engage/gap/mesh`; `pmi fits`; STEP export appends the K2 AP242 block |
| `src/k2/mat.bend` | Grade lookup, binding, validation (`material-node-unknown`, non-positive density, non-finite CTE), the per-part mass line |
| `src/k2/thr.bend` | ISO 261 coarse pitches M3–M36, ISO 965-1 tolerance tables for pitches 0.5–3.5, classes 5H 6H 7H 6G (internal) and 4h 6h 6g 6f 6e (external), the minor/major diameter windows, thread face geometry (cylinder axis, radius, side, axial span) and every refusal |
| `src/k2/fit.bend` | ISO 286-2 IT5–IT11 for nominal sizes to 500 mm, shaft deviations d e f g h js k m n p r s, hole deviations D E F G H JS, temperatures, clearance or interference intervals per state, verdicts |
| `src/k2/kgap.bend` | Planar 2-D traces of z-extruded faces (lines from planes and flat patches, arcs from cylinders, each flagged exact or not), segment/arc distance kernels, box prefilter, certified static gap and branch-and-bound mesh gap over one pitch |
| `src/k2/kasm.bend` | Assembly verbs over the C14 solver: placements feed traces and thread axes |
| `src/k2/kstep.bend` | AP242 `MATERIAL_DESIGNATION`, density and CTE `DESCRIPTIVE_REPRESENTATION_ITEM`s, thread `SHAPE_ASPECT`s with designation and length |

## 2. Forms

```
(material NODE GRADE RHO CTE)                    RHO kg/m3 > 0, CTE 1/K finite
(thread NODE NAME FACE DESIG CLASS Z0 Z1)        DESIG M8 or M8x1.25; Z0 < Z1 along the face axis
```

Both are edits: they go through `apply` with the nodes, are validated
against the evaluated design and are written by `show`. Rebinding a node's
material replaces the earlier grade. A thread is refused unless its face
is a cylinder of the node (`thread-face-not-cylindrical`), its class side
matches the face side (`thread-class-side-mismatch`), its span lies on the
face (`thread-span-outside-face`) and the modelled diameter lies in the
class window: an internal thread's bore must lie in the ISO 965-1 minor
diameter window (`thread-minor-diameter-mismatch`), an external thread's
cylinder in the major diameter window (`thread-major-diameter-mismatch`).
Threads are semantic: the B-rep keeps the cylinder at the tap-drill or
major diameter, as drawings and AP242 do; no helix is modelled.

## 3. What each verb certifies

- `mass N` adds `material GRADE density=RHO cte=CTE mass=[lo, hi] kg`: the
  certified C10 volume interval times the density.
- `asm mass (assembly ...)` lists every instance with its grade and mass
  interval and the total; any instance without a material refuses with
  `material-not-bound`.
- `threads N` prints every thread with designation, class, span, side,
  window, modelled diameter and face.
- `asm engage IA TA IB TB (assembly ...)` requires equal designations and
  coaxial placed axes and prints the axial overlap of the two spans as
  `engagement=[lo, hi]` with `ratio` = engagement / nominal diameter.
- `asm gap IA IB [FACE ...] (assembly ...)` traces the z-parallel faces of
  both placed parts into the xy plane (planes and flat patches give
  segments, cylinders give arcs; horizontal faces are skipped; any other
  face refuses with `gap-faces-not-extruded` or `gap-axes-not-parallel`)
  and reports the minimum distance between traces whose z spans overlap,
  `gap=[lo, hi]` with `verdict=clearance|interference|contact` and
  `status=certified|uncertain`. Naming faces restricts the second part.
- `asm mesh IA ZA IB ZB (assembly ...)` rotates A about its placed origin
  by θ and B about its own by −(ZA/ZB)θ over one pitch of A
  (θ ∈ [0, 2π/ZA]) and certifies the minimum gap over the whole pitch by
  bisection with per-pair bounds. Every trace pair carries its own
  Lipschitz constant `L` = reach(a) + (ZA/ZB) reach(b) (the largest
  distance of a trace point from its rotation centre) and its distances
  at the interval ends; on `[θ0, θ1]` the pair is at least
  `min(d(θ0), d(θ1)) − L(θ1 − θ0)/2` apart. A pair whose bound exceeds
  the best measured gap leaves the subtree, so refinement works only on
  the pairs in contact. An interval closes when the best measured gap is
  within 1e-4 mm of its bound, or at depth 24. `hi` is a gap measured at
  some θ; `lo` holds for every θ. The printed `lipschitz` is the largest
  pair constant.
- `pmi fits (pmi (node N) (temp NAME T)... (fit NAME HN HFACE SN SFACE CLASS KIND)...)`
  reads the nominal size from the two cylinders (they must agree to 1e-6
  and be at most 500 mm), takes hole and shaft limits from ISO 286 and, at
  each temperature, scales hole and shaft limits by `1 + CTE (T − 20)` of
  their own bound materials. KIND `clearance`, `press` or `transition`
  must hold at every state (`fit-not-clearance`, `fit-not-press`). States
  other than 20 °C need both materials (`material-not-bound`).
- `step N FILE` writes the material and every thread of node N's part
  into the AP242 file beside the geometry.

## 4. Measured on the suites

`tests/k2/e2e.py` (21 journeys), `tests/k2/neg.py` (16 refusals),
`tests/k2/pins.bend` (24 pins against ISO 286-2 and ISO 965-2 table values
and closed-form distances) and `laws/k2` (6 quantified laws, each killed by
its mutant in `tools/laws/mutate.py`):

- 6082-T6 10 x 20 x 30 block: mass [0.0162 − 1.6e-14, 0.0162 + 1.6e-14] kg.
- M8x1.25 6H tap at 6.8: minor window [6.647, 6.912]; screw engagement
  12 ± 3e-11, ratio 1.5. M8 6g major window [7.760, 7.972]; a shank
  modelled at the basic 8.000 is accepted and printed `basic`.
- H7/g6 at 20 mm, aluminium hub on steel shaft: clearance [0.007, 0.041]
  at 20 °C and [0.02128483, 0.05532328] at 80 °C. H7/p6 with an
  aluminium shaft: interference positive at both states. H7/k6:
  [−0.015, 0.019] cold and [−0.00073, 0.03331] hot, transition at both;
  H7/g6 declared transition is refused.
- Module 3, 12/12 involute gears from `docs/receipts/g3/gear.py` at
  36 mm centres (144 flank traces each): the rotating mesh gap over one
  pitch is [0.0934962, 0.0935961] in 0.4 s and encloses the shapely
  oracle 0.0935961 (4,000 samples plus ternary refinement); the static
  gap [0.130751770, 0.130751770] and the tip-to-bore gap
  [0.0399998896, 0.0399998903] enclose the oracle values.
- Gear tip to bore 0.04 and gear to gear 0.05 on cylinders: widths below
  1.3e-9.

## 5. Limits

| ID | Limit | Gate that needs it |
|---|---|---|
| K2-L1 | `gap` and `mesh` take z-extruded parts only (faces parallel to z); bevel, helical and worm gears refuse | G5 if the engine carries helical gears |
| K2-L2 | Holes take D–H and JS deviations; K M N P R S holes (shaft-basis press fits) refuse as unknown classes | None on the ladder; G2 uses hole-basis fits |
| K2-L3 | Threads are ISO metric only (M3–M36 coarse, fine pitches 0.5–3.5); no UNC/UNF, BSP, NPT or ISO 6149 port threads by name | G2 ports: ISO 6149-1 ports are metric fine (M14x1.5, M18x1.5, M22x1.5) and are covered |
| K2-L4 | Thermal growth is linear and uniform about the part origin per material; no temperature fields | G5: hot-section clearances need gradients |
