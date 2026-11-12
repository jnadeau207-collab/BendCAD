# BendCAD agent manual

What a piloting agent needs to drive the kernel CLI, written from the brief-ladder baseline of 2026-11-11 (`tests/briefs/`, binary `/home/jesse/bc/bendcad-a15`). Every example is an edit that committed in a brief (`Bn` is the brief in `tests/briefs/briefs.py`) or a query whose output is stored in `docs/receipts/briefs/Bn.json`. Refusals are quoted verbatim. Nothing here is claimed that was not run; section 8 lists what was not exercised. The older language reference is `tools/mcp/language.md`; the CLI does not serve it.

## 1. Invocation

```
BIN DESIGN.bcd new
BIN DESIGN.bcd apply EDIT [EDIT ...]
BIN DESIGN.bcd VERB ARGS...
```

`BIN` is a Linux binary (run it in WSL). Each call reads the design file, evaluates what it needs and exits; nothing is cached between calls, so every query pays for the evaluation of its node again (B5: about 1.4 s per call for a 13-node collar). An unknown verb prints `error unknown command X | use new, show, eval, apply, ...` and nothing more: there is no help verb and no argument synopsis.

`apply` takes one or more edits as separate shell arguments. They are validated together: either all commit (`committed`, the file is rewritten) or nothing changes (`rejected: the design was not changed`). Before the verdict it prints one line per evaluated node:

```
node 3: ok material=remove faces_created=2 faces_modified=2 solids=1 through_holes=4 | volume=[6702.842962562709, 6702.842962576116] area=[...] bbox=[...] ... genus=4 ... | proof: k1-crossing-certified V22 E29 F13 S1
```

or `node N: error KIND | what @ where | why: ... | fix: ...`. A node whose input failed reports `why: input-node-missing-or-failed | fix: fix the input node first`.

## 2. The design-file model

A design is an ordered list of parameters, nodes, materials and thread callouts (`show` prints it; the file is the same text).

- `(param NAME NOM)` or `(param NAME NOM LO HI)`: a number with a tolerance zone. Re-applying it with a new value is an edit; every node that uses it re-evaluates. B1 `(param T 3)` then `(param T 4)`; B3 `(param DS 22 22 22.021)` (an H7 zone typed by hand).
- `(node ID OP INTENT)`: one operation. Re-applying an id replaces that node. B5 replaced its ring with `(node 301 (prism 0 10 (region (circle 0 0 12.5) (circle 0 0 4))) (intent create any 0 1 1))` and the twelve nodes after it re-evaluated.
- `(intent MATERIAL FACES_CREATED FACES_MODIFIED SOLIDS THROUGH_HOLES)`: MATERIAL is `create`, `add`, `remove` or `same`; each count may be `any`. The kernel measures all five and refuses a mismatch: `why: declared material=remove ... through_holes=0 but measured material=remove faces_created=0 faces_modified=0 solids=1 through_holes=1 | fix: fix the operation or declare the effect it has` (B5: a clearance bore that opened into the split). Following the fix worked. A `bend` measures as `add` (B1 probe); `move` and `rotate` are `same`. Intent catches miscounts but not wrong geometry: B7's misplaced holes became sealed cavities and still matched `through_holes 0` (section 7).
- Expressions: numbers, parameter names, `(+ a b)`, `(- a b)`, `(* a b)`, `(/ a b)`. B1 `(line (+ T R) T)`; B2 `(hole (- 30 (/ S 2)) (- 30 (/ S 2)) (/ M 2))`; B7 `(pocket 701 (face 701 0 top) (- H 2) ...)`.
- `(material NODE GRADE RHO CTE [E NU])`: any grade name. B13 `(material 401 100Cr6 7810 11.5e-6)`; B14 `(material 1403 PLA 1240 68e-6 3500 0.36)`.
- `(thread NODE NAME FACE DESIG CLASS Z0 Z1)`: a semantic ISO metric thread on a cylinder face (section 5).

### Face names

`faces NODE` prints durable names and surface kinds; `faces NODE -f` adds each planar face's frame. A name comes from the node that created the face and survives later booleans:

- extrusions and primitives: `nN.cK.top`, `nN.cK.bottom`, `nN.cK.wall.I.J` (cell K is loop K in the order written; I is the segment).
- revolves: every face comes in two halves, `nN.c0.wall.I.0` and `nN.c0.wall.I.1` (B3, B4, B8). Holes placed through either half's frame committed (B3 probe); a thread callout on either half committed (B4 probe).
- tools keep their names: B5's tap bore is `n311.c0.wall.0.0` on node 313.
- a pocket floor is `nN.c0.top` of the pocket node (B7 `n702.c0.top`); a pad top is `nN.cK.top` of the pad node (B7 `n703.c0.top`).
- holes inside a solid become cavity faces `nN.cav.K.I.J` (seen in B7's defect).

A frame line reads `n1.c0.wall.2.0 plane loops=1 frame o=(0,3,0) x=(1,0,0) y=(0,0,-1) n=(0,1,0)`. Feature coordinates on that face are (x, y) in that frame: B1 put a hole at world (25, 3, 8) as `(hole 25 -8 r)` because the frame's y is world -z.

`FACE` in a feature is `(face NODE CELL top|bottom)` or `(face NODE NAME)`. Use the named form for anything raised off the base: on a pad standing on a pocket floor, `(face 703 0 top)` placed B7's insert holes at the wrong height as sealed cavities, while `(face 703 n703.c0.top)` cut them correctly.

## 3. Operations used

Profiles: `(circle CX CY R)`; `(path X Y SEG...)` with `(line X Y)` and `(arc CX CY R X Y ccw|cw)`; `(region OUTER HOLE...)`. Arc endpoints must lie on their circle to about one unit in the last place. Endpoints computed as `C + R(cos a, sin a)` are refused: `why: arc-start-off-circle | fix: put the arc start on its circle (distance to center = radius)` (B14 probe). What worked: snap each endpoint with an exact-rational search of its ulp neighbourhood (`snap` in `tools/g4/blower.py`, used by `blade()` in `tests/briefs/briefs.py`), or use exact points (axis tangents, or square roots such as B9's `2.8284271247461903` for sqrt(8) on a radius-3 circle at y = 1).

| Op | Grammar | Committed example |
|---|---|---|
| box | `(box X Y Z)`, corner at the origin | B2 `(node 1 (box 60 80 6) (intent create 6 0 1 0))` |
| cylinder | `(cylinder R H)`, z axis, z in [0, H] | B9 `(node 921 (cylinder 1.5 40) ...)` |
| torus | `(torus R r)`, centred, z = 0 plane | B8 `(node 803 (torus 41.035 1.765) ...)` |
| prism | `(prism Z0 Z1 REGION...)` | B1 L profile with a concave fillet arc; B6 a 200-point gear outline with a keyed bore; B14 eight blade regions in one prism |
| revolve | `(revolve REGION)`; x is radius, y is z; may run along the axis | B3 housing; B4 shaft from `(path 0 0 ...)` back along the axis; B11 rim `(revolve (region (circle 50 0 5)))` |
| move | `(move BASE DX DY DZ TURN)`; TURN 0 none, 4 = +90 deg about x (the z axis goes to -y), 5 = +90 deg about y (the z axis goes to +x) | B5 `(move 305 8 -4.5 5 4)`; B11 `(move 1103 7 0 0 5)` |
| rotate | `(rotate BASE x\|y\|z DEG)` | B11 `(rotate 1104 z 120)`; B9 `(rotate 915 z 90)` |
| union, difference | `(union A B)`, `(difference A B)` | B11 hub, three spokes and a torus rim (cylinder/torus crossings); B5 three perpendicular cylinders cut through a ring; B9 coaxial relief cuts; B14 eight blades onto a revolved plate |
| holes | `(holes BASE FACE DEPTH\|through (hole X Y R)...)` | B3 `(holes 101 (face 101 n101.c0.wall.2.0) through (hole 17.67766952966369 17.67766952966369 (/ DH 2)) ...)` on a revolve's flange face; B7 blind holes `(holes 703 (face 703 n703.c0.top) 6 (hole 8 8 2) ...)` |
| pocket | `(pocket BASE FACE DEPTH\|through REGION...)` | B2 two slots through; B7 the enclosure cavity; B12 a bearing pocket from the bottom face |
| pad | `(pad BASE FACE H REGION...)` | B7 bosses on `(face 702 n702.c0.top)`; B7 lid lip on `(face 711 0 bottom)` (grows -z); B12 two ribs |
| chamfer on a hole edge | `(chamfer BASE (face N NAME) (circle X Y R) C)`, 45 deg | B12 countersinks `(chamfer 1204 (face 1204 n1201.c0.top) (circle 6 6 2.75) CS)` |
| flat, bend | `(flat L W T)`, `(bend BASE (edge N) R DEG)` | B1 probe `(node 50 (flat 80 30 3) ...)`, `(node 51 (bend 50 (edge 0) 3 90) (intent add any any 1 any))` |
| skin | helix sections from `tools/g5/threads.py` | B10 probe: one turn of internal M3 thread commits; the full length does not (section 7) |

Refused, with the fix and what happened:

- A feature on a curved face: `why: feature-face-not-planar: n301.c0.wall.0.0 | fix: features act on planar faces` (B5 probe, B3). A cross hole or counterbore in a cylindrical surface is a placed cylinder and a `difference` (B5).
- Holes on a bent sheet: `why: features-need-an-extruded-body | fix: features act on prism, box and cylinder bodies along z; other placements need booleans (C08)` (B1 probe).
- `(fillet 102 1)` on a revolve result and `(fillet 701 2)` on a prism: `why: fillet-base-not-admitted | fix: stay inside the admitted feature` (B3, B7 probes). `(shell 701 2 open)` on a prism: `why: shell-base-not-admitted` (B7 probe). The fix does not say what is admitted; `tools/mcp/language.md` does (box, cylinder, one box vertical edge, circular edges in a planar face).
- `(pattern 1450 (circular 8 0))`: `why: pattern-angle-not-certified | fix: stay inside the admitted feature` (B14 probe). `(rotate BLADE z 45)` then `union` committed instead.
- `(countersink ...)`: `why: unknown-op | fix: use box, cylinder, prism, pad, pocket, holes, move, rotate, revolve, cone, sphere, torus, sweep, loft, chamfer, fillet` (B12 probe). The 45-degree hole-edge chamfer is the only countersink.

## 4. Queries and checks used

| Verb | Grammar | What it answered in the briefs |
|---|---|---|
| eval | `eval` | every node's line |
| measure | `measure NODE` | one node's line; B11 `through_holes=4` (rim + three spokes + bore) |
| faces | `faces NODE [-f\|-v]` | names, surface kinds (`plane`, `cylinder`, `cone`, ...), frames |
| check | `check NODE` | `ok: embedded, shells outward, cavities nested` on every committed part |
| mass | `mass NODE [DEPTH]` | certified volume and divergence moments; the octree centroid can be `incomplete` (B1) |
| wall | `wall NODE` | `min-wall [2.999999999971803, 3] certified ...` (B1, 16-19 s); B2 in 1.3 s; no answer in 600 s on B3, B4, B5, B7, B11, B12, B14 |
| clearance | `clearance A B` | exact for coaxial cylinders: the gauge-pin method (B2 `clearance 91 4` gave `[0.09999999966998627, 0.10000000000003212]`) measures a bore; between non-coaxial curved parts it took over 600 s (B8, B9, B13) |
| interf | `interf A B` | `relation disjoint status=certified` (B7 lid on body, B8 O-ring in its groove in 74 s, B6 gears in 440 s); found the real interference of B9's first leaf design |
| dist | `dist NODE X Y Z` | inside a hole: `distance [0, 3.1250390622552344] estimated lo=certified`: it cannot certify a hole size |
| zone | `zone NODE` | refused on a revolve with holes (B3) and on a boolean (B4): `topology-not-certified-over-zone` |
| section | `section NODE A B C D` | B1 at z = 22: `status=estimated` with over 1000 unresolved boxes |
| threads | `threads NODE` | `thread m4 M4x0.7 6H z=[0.5, 7] length=6.5 internal minor=[3.242, 3.422] model=3.3 face=n311.c0.wall.0.0 status=certified` (B5) |
| machine | `machine NODE D FL HD HL AXES NS` | ball-end mill reach only; every drilled hole reports `concave-radius=2.75 below-tool-radius` (B1), so every mill brief reads `not-machinable` |
| balance | `balance NODE PX PY PZ DX DY DZ RPM G` | B14 at 3000 rpm, G6.3: `within status=certified` |
| step | `step NODE FILE` | AP242; OCCT read every exported part back as one solid within the certified volume (receipts `step`); a part with cavities is refused `step-cavities-not-in-profile` |
| tess | `tess NODE OUT.obj [PRESET CHORD ANGLE MAXTRIS PROFILE]` | default preset is the display preset; every mesh that was written is conforming by `tools/mesh/check.py`; B11 refused `tess-mesh-not-closed` |
| stl | `stl NODE OUT.stl 3` | the manufacturing preset: 25-168 s per part |
| pmi fits | `pmi fits (pmi (node N) (temp NAME T)... (fit NAME HN HFACE SN SFACE CLASS KIND))` | B13 H7/h5 printed both temperatures, then `why: fit-not-clearance: seat` |
| asm | `asm solve\|interf\|clear\|mass\|gap\|mesh ... (assembly ...)` | B6 `asm mesh p 20 w 40 (assembly ...)`: `gap=[0.0471, 0.0472] ... verdict=clearance status=certified` in 1.4 s; B13 `asm solve` `dof 0`; B13 `asm interf` (44-71 s) found the real bearing-on-k5 interference and printed `declared press-fit inner status=declared` once declared; `asm clear` on four parts gave no answer in 600 s; B7 `asm gap` |

Assembly form (B13): `(assembly (inst NAME NODE TX TY TZ Q)... (fix ID INST) (coinc ID A AX AY AZ B BX BY BZ))`. `(press NAME A AFACE B BFACE)` is accepted only by `asm interf`; `asm solve`, `asm clear` and `asm mass` refuse the same text with `why: unknown-assembly-entry`. Keep two texts.

`asm gap A B [FACE...]` needs every face of A, and the named faces of B, parallel to z: `why: gap-axes-not-parallel: face n705.c0.wall.0.0 is not parallel to z on body | fix: gap measures parts extruded along z` (B7, a side port). Swapping the parts and naming the body's inner walls was accepted.

## 5. Engineering data the kernel holds

- Threads (ISO 261 / ISO 965-1): model a tapped hole at its tap drill (M4 6H takes 3.242 to 3.422; B5 used 3.3; a bore at the basic minor diameter also commits) and an external thread inside the class's major window (B4 used 7.95 for M8x1 6g). Z0..Z1 is measured along the face axis in world coordinates, oriented so its first non-zero component is positive, over the projections of the face's edge start points. `thread-span-outside-face` does not print that span: for B5's tap along -y it is a world y range (`0.5 7`), not the tool cylinder's 0..13.
- Fits (ISO 286): only inside `pmi fits`, between two cylinders of the same nominal size. A lone bore or shaft cannot take a class.
- Materials: any grade name with density and CTE (E and NU for FE).
- Nothing else. Clearance holes, counterbores, countersinks, keyways, ring grooves, O-ring glands, flanges, gears, bearings and fasteners were all typed by the agent (`docs/receipts/briefs/friction.json`).

## 6. Workarounds that worked

- Gauge pin: a cylinder of radius r - 0.1 coaxial with a bore, then `clearance PIN PART`, certifies the bore radius (B2, B3).
- Cross holes and counterbores on curved surfaces: placed cylinders (`move ... 4`) and `difference` (B5). Make each tool long enough to leave the part: a short tool leaves its end cap inside, visible only as an extra face in `faces -f`.
- Arcs with computed endpoints: ulp snap (B14).
- Gears: polyline teeth from `docs/receipts/g3/gear.py`, checked with `asm mesh` (B6).
- Hinge swing: one `rotate` node per sampled angle and one `clearance` per angle (B9). This samples the swing; it does not certify it.
- Press fits in an assembly: declare them only in the text given to `asm interf`.

## 7. Known wrong or missing answers (repros in `tests/briefs/repro/`)

- `pad_cell_face_sealed_cavity`: holes on `(face PAD 0 top)` cut at the wrong height and commit as sealed cavities.
- `asm_gap_concave_arc`: `asm gap` reports certified interference between concentric corner arcs 0.2 apart.
- `countersink_edit_refused`: `(param CS 2.6)` refuses with k1 reason 42; 2.45, 2.5, 2.55 and 2.7 commit.
- `fit_hh_zero_clearance`: H7/h5 fails `clearance` on a rounding error of -7.1e-15.
- `asm_press_breaks_solve`: see section 4.
- `modelled_thread_reason82`: a 10 mm internal M3 helix differenced from the standoff refuses with k1 reason 82 after about 200 s.
- `tess_curved_boolean_not_closed`: the handwheel cannot be meshed.
- `wall_stepped_revolve`, `clearance_oring_slow`, `asm_clear_slow`, `interf_gears_slow`, `tess_display_slow`: queries far over budget.
- `dist_inside_hole`, `thread_span_frame`: answers that cannot be used as stated.

## 8. Not exercised in this baseline

Verbs: `show`, `sens`, `classify` (used once while diagnosing B7, not in a brief), `extrema` (same), `archive`, `3mf`, `flat`, `surf`, `blade`, `diag`, `rotor`, `modes`, `spin`, `scene`, `view`, `batch`, `serve`, `pmi check|stack|toler|step42`, `asm explode|faces|engage|step`. Edits: `(delete ID)`. Ops: `sphere`, `cone`, `intersection`, `sweep`, `loft`, `fillet` on a box or cylinder, `fillet` on a hole edge, `chamfer` of a box or an edge pair, `draft`, `offset`, `thicken`, `pattern-holes`, `hem`, `naca4`, `blade`, `loft-open`, `sweep-open`, `patch`, `thicken-open`, `import`.
