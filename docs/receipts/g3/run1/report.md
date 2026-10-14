# G3 run 1: two-stage spur gearbox report

Design file: `/home/jesse/g3/gearbox.bcad` (WSL). I built all geometry with BendCAD MCP calls. I used Python only to run `gear.py`. The tool-call log is `C:\dev\BendCAD\docs\receipts\g3\run1\calls.jsonl`.

## Deviations and problems (stated up front)

1. **Part count.** The brief says "all 16 parts", but the parts it lists add up to 18: base, frame, cover, 3 shafts, 4 gears, 6 bearings and 2 seals. I built all 18, each as its own design node.
2. **Log path.** With `BENDCAD_LOG=/mnt/c/...`, as the brief gives it, nothing is logged. The MCP server is a Windows node process, so it cannot open a `/mnt/c` path, and Git Bash also rewrites the variable. The logging failure is silent. I pointed the log at the Windows form of the same file, `C:/dev/BendCAD/docs/receipts/g3/run1/calls.jsonl`.
3. **Git Bash path conversion.** `wsl.exe -e mkdir -p /home/jesse/g3/...` under Git Bash turned the paths into `C:/Program Files/Git/home/...`. That created an empty stray directory, `C:\dev\BendCAD\C:\Program Files\...`. I deleted it and re-ran the command with `MSYS_NO_PATHCONV=1`. Every later call used that setting.
4. **Large `apply` fails silently.** One `apply` holding all 17 remaining nodes (36 KB of edits, mostly the four gear profiles) exited with code 1 and printed nothing, in 0.09 s. The edits probably go on the `wsl.exe` command line, which Windows caps at about 32 K characters. Workaround: I applied the non-gear nodes together and then each gear node on its own (about 5 KB and 12.5 KB). Every one of those applies committed.
5. **The assembly solver reports a false conflict when mates link instances.** My first assembly pinned parts to each other with `coinc` mates (gear to shaft, bearing to plate, plate to plate). Those mates are consistent, but the reply was
   `asm conflict ninst 18 nmates 21 viol [1,2,...,21] max-residual 80 | fix: loosen or correct the violating mates`.
   - **Minimal repro:** 6 instances of node 1 with `(fix 1 a) (coinc 2 b 0 0 0 a 0 0 1) (coinc 3 c 0 0 0 a 0 0 2) (fix 4 d) (fix 5 e) (fix 6 f)` gives `asm conflict ninst 6 nmates 6 viol [1,2,3] max-residual 1.0000000000000002`.
   - **Cases that solve:** the same pattern with 5 instances, and 6 instances when only one `coinc` is present or when every mate is world-referenced (`fix`, `axis`, `plane`).
   - **Second, related fault:** the three housing parts chained by `coinc`, plus three unconstrained instances, should report underconstrained with dof 9. It reports `conflict viol [1,2] max-residual 35` instead.
   - **Workaround:** I pin every instance with world-referenced mates only: `axis` on its shaft axis plus `plane` at its z seat, and `fix` on the base. That solves with dof 0 (section 2). The cost is that the mates do not record part-to-part relations such as "gear sits on shaft".
6. **Mesh and frame checks are not certified.** `interference` returns `uncertain status=estimated` for both gear meshes and for gear against frame. `clearance` gives a certified lower bound of only 0. Details are in section 3.

## 1. Parts and volumes

Parameters with tolerance zones:
- `(param H 70 69.8 70.2)`: housing interior height (the frame height).
- `(param FW 20 19.9 20.1)`: gear face width.

Volume intervals are certified, in mm^3.

| node | part | operation | intent | volume interval |
|---|---|---|---|---|
| 1 | base plate | prism 0 10: 230x130 outline, bores dia 36 at x=0, 60, 120 | create 9 0 1 3 | [268463.71940681286, 268463.7194074015] |
| 2 | wall frame | prism 0 H: outline with 200x110 opening | create 10 0 1 1 | [552999.999996654, 553000.000003346] |
| 3 | cover plate | same as base | create 9 0 1 3 | [268463.71940681286, 268463.7194074015] |
| 4 | input shaft | cylinder 10 110 | create 3 0 1 0 | [34557.51918948621, 34557.51918948924] |
| 5 | intermediate shaft | cylinder 10 90 | create 3 0 1 0 | [28274.3338823071, 28274.333882309173] |
| 6 | output shaft | cylinder 10 110 | create 3 0 1 0 | [34557.51918948621, 34557.51918948924] |
| 7 | stage-1 pinion, 15 teeth | prism 0 FW: `gear.py 15 0` profile, bore circle r 10 | create 183 0 1 1 | [7185.000622031322, 7185.000622056703] |
| 8 | stage-1 gear, 45 teeth | prism 0 FW: `gear.py 45 0` profile, bore r 10 | create 453 0 1 1 | [119515.25653140295, 119515.2565316455] |
| 9 | stage-2 pinion, 15 teeth | as node 7 | create 183 0 1 1 | [7185.000622031322, 7185.000622056703] |
| 10 | stage-2 gear, 45 teeth | as node 8 | create 453 0 1 1 | [119515.25653140295, 119515.2565316455] |
| 11-16 | bearings: base x0, x60, x120; cover x0, x60, x120 | prism 0 10: ring r 18 / r 10 | create 4 0 1 1 | [7037.167544041019, 7037.167544041254] each |
| 17, 18 | seals: input (top), output (bottom) | prism 0 4: ring r 16 / r 10 | create 4 0 1 1 | [1960.3538158399797, 1960.353815840083] each |

All 18 nodes build and evaluate `ok`, and each one's measured effect matches its declared intent.

- **Local frames:** each part's local origin is at the bottom of the part on its own axis. The plates and frame use the input-shaft axis as local x=0, y=0.
- **Placed copies:** nodes 101-118 are `(move N tx ty tz 0)` at the solved translations, with intent `same 0 0 1 g` (g is the part's through-hole count). All are ok and keep the same volume intervals.
- **Gear phase:** both tooth counts (15, 45) are odd, so phase 0 on every gear puts a pinion tooth on +x, facing its mate. The mating 45-tooth gear then has a gap on -x, at the line of centres.
- **Phase check by `classify` (certified ray casting):**
  - Stage 1, world point (16,0,20): inside pinion 107, outside gear 108. That is the pinion tooth sitting in the gear gap.
  - Stage 1, point (17.6,0,20): inside gear 108, outside pinion 107.
  - Stage 2 gives the same result at (76,0,50) and (77.6,0,50) for nodes 109 and 110.

## 2. Assembly

Assembly text as solved:

```
(assembly
  (inst base 1 0 0 -10 0)
  (inst frame 2 0 0 0 0)
  (inst cover 3 0 0 70 0)
  (inst shin 4 0 0 -10 0)
  (inst shmid 5 60 0 -10 0)
  (inst shout 6 120 0 -30 0)
  (inst pin1 7 0 0 10 0)
  (inst gear1 8 60 0 10 0)
  (inst pin2 9 60 0 40 0)
  (inst gear2 10 120 0 40 0)
  (inst brb0 11 0 0 -10 0)
  (inst brb60 12 60 0 -10 0)
  (inst brb120 13 120 0 -10 0)
  (inst brc0 14 0 0 70 0)
  (inst brc60 15 60 0 70 0)
  (inst brc120 16 120 0 70 0)
  (inst sealin 17 0 0 80 0)
  (inst sealout 18 120 0 -14 0)
  (fix 1 base)
  (axis 2 frame 0 0 0 0 0 0 0 0 1)
  (plane 3 frame 0 0 0 0 0 1 0)
  (axis 4 cover 0 0 0 0 0 0 0 0 1)
  (plane 5 cover 0 0 0 0 0 1 70)
  (axis 6 shin 0 0 0 0 0 0 0 0 1)
  (plane 7 shin 0 0 0 0 0 1 -10)
  (axis 8 shmid 0 0 0 60 0 0 0 0 1)
  (plane 9 shmid 0 0 0 0 0 1 -10)
  (axis 10 shout 0 0 0 120 0 0 0 0 1)
  (plane 11 shout 0 0 0 0 0 1 -30)
  (axis 12 pin1 0 0 0 0 0 0 0 0 1)
  (plane 13 pin1 0 0 0 0 0 1 10)
  (axis 14 gear1 0 0 0 60 0 0 0 0 1)
  (plane 15 gear1 0 0 0 0 0 1 10)
  (axis 16 pin2 0 0 0 60 0 0 0 0 1)
  (plane 17 pin2 0 0 0 0 0 1 40)
  (axis 18 gear2 0 0 0 120 0 0 0 0 1)
  (plane 19 gear2 0 0 0 0 0 1 40)
  (axis 20 brb0 0 0 0 0 0 0 0 0 1)
  (plane 21 brb0 0 0 0 0 0 1 -10)
  (axis 22 brb60 0 0 0 60 0 0 0 0 1)
  (plane 23 brb60 0 0 0 0 0 1 -10)
  (axis 24 brb120 0 0 0 120 0 0 0 0 1)
  (plane 25 brb120 0 0 0 0 0 1 -10)
  (axis 26 brc0 0 0 0 0 0 0 0 0 1)
  (plane 27 brc0 0 0 0 0 0 1 70)
  (axis 28 brc60 0 0 0 60 0 0 0 0 1)
  (plane 29 brc60 0 0 0 0 0 1 70)
  (axis 30 brc120 0 0 0 120 0 0 0 0 1)
  (plane 31 brc120 0 0 0 0 0 1 70)
  (axis 32 sealin 0 0 0 0 0 0 0 0 1)
  (plane 33 sealin 0 0 0 0 0 1 80)
  (axis 34 sealout 0 0 0 120 0 0 0 0 1)
  (plane 35 sealout 0 0 0 0 0 1 -14))
```

Solve result (`assembly solve`):

```
asm solved ninst 18 nmates 35 dof 0 max-residual 0
inst base node 1 t=0 0 -10 q=0
inst frame node 2 t=-0 0 0 q=0
inst cover node 3 t=-0 0 70 q=0
inst shin node 4 t=-0 0 -10 q=0
inst shmid node 5 t=60 0 -10 q=0
inst shout node 6 t=120 0 -30 q=0
inst pin1 node 7 t=-0 0 10 q=0
inst gear1 node 8 t=60 0 10 q=0
inst pin2 node 9 t=60 0 40 q=0
inst gear2 node 10 t=120 0 40 q=0
inst brb0 node 11 t=-0 0 -10 q=0
inst brb60 node 12 t=60 0 -10 q=0
inst brb120 node 13 t=120 0 -10 q=0
inst brc0 node 14 t=-0 0 70 q=0
inst brc60 node 15 t=60 0 70 q=0
inst brc120 node 16 t=120 0 70 q=0
inst sealin node 17 t=-0 0 80 q=0
inst sealout node 18 t=120 0 -14 q=0
redundant []
lineage asm(base=n1,frame=n2,...,sealout=n18) mates[1..35]
```

- **Degrees of freedom:** 0, with no redundant mates and max residual 0. The assembly is fully constrained in translation.
- **Rotation:** the solver does not represent rotation of the shafts and gears about z. Orientations are fixed per instance (q=0).
- **Why world mates:** this mate form is the workaround for Deviation 5. The part-to-part version I wanted was rejected as `asm conflict ninst 18 nmates 21 viol [1..21] max-residual 80`. It had the same instances, with these mates:

```
  (fix 1 base)
  (coinc 2 frame 0 0 0 base 0 0 10)
  (coinc 3 cover 0 0 0 frame 0 0 70)
  (axis 4 shin 0 0 0 0 0 0 0 0 1)   (plane 5 shin 0 0 0 0 0 1 -10)
  (axis 6 shmid 0 0 0 60 0 0 0 0 1) (plane 7 shmid 0 0 0 0 0 1 -10)
  (axis 8 shout 0 0 0 120 0 0 0 0 1) (plane 9 shout 0 0 20 0 0 1 -10)
  (coinc 10 pin1 0 0 0 shin 0 0 20)  (coinc 11 gear1 0 0 0 shmid 0 0 20)
  (coinc 12 pin2 0 0 0 shmid 0 0 50) (coinc 13 gear2 0 0 0 shout 0 0 70)
  (coinc 14 brb0 0 0 0 base 0 0 0) (coinc 15 brb60 0 0 0 base 60 0 0) (coinc 16 brb120 0 0 0 base 120 0 0)
  (coinc 17 brc0 0 0 0 cover 0 0 0) (coinc 18 brc60 0 0 0 cover 60 0 0) (coinc 19 brc120 0 0 0 cover 120 0 0)
  (coinc 20 sealin 0 0 0 cover 0 0 10) (coinc 21 sealout 0 0 4 shout 0 0 0)
```

Exploded placements (`assembly explode`, direction 0 0 1, gap 40; instance k moves k x 40 along +z):

```
asm exploded ninst 18 dir=0 0 1 gap=40
inst base node 1 t=0 0 -10 q=0
inst frame node 2 t=0 0 40 q=0
inst cover node 3 t=0 0 150 q=0
inst shin node 4 t=0 0 110 q=0
inst shmid node 5 t=60 0 150 q=0
inst shout node 6 t=120 0 170 q=0
inst pin1 node 7 t=0 0 250 q=0
inst gear1 node 8 t=60 0 290 q=0
inst pin2 node 9 t=60 0 360 q=0
inst gear2 node 10 t=120 0 400 q=0
inst brb0 node 11 t=0 0 390 q=0
inst brb60 node 12 t=60 0 430 q=0
inst brb120 node 13 t=120 0 470 q=0
inst brc0 node 14 t=0 0 590 q=0
inst brc60 node 15 t=60 0 630 q=0
inst brc120 node 16 t=120 0 670 q=0
inst sealin node 17 t=0 0 720 q=0
inst sealout node 18 t=120 0 666 q=0
```

## 3. Mesh checks

All checks ran on the placed copies (move nodes). Run times:
- `interference` or `clearance` on a gear pair: about 14.5 min per call.
- the same calls on gear against frame: about 5.6 min per call.

| pair | interference | clearance |
|---|---|---|
| stage 1: pinion 107 vs gear 108 | `relation uncertain status=estimated a:in=0 out=1267 uncertain=0 b:in=0 out=3157 uncertain=0 boxes-overlap=1` | `clearance [0, 0.1591411426124586] estimated lo=certified samples=1267x3157` |
| stage 2: pinion 109 vs gear 110 | `relation uncertain status=estimated a:in=0 out=1267 uncertain=0 b:in=0 out=3157 uncertain=0 boxes-overlap=1` | `clearance [0, 0.1591411426124586] estimated lo=certified samples=1267x3157` |
| gear 108 vs frame 102 | `relation uncertain status=estimated a:in=0 out=3157 uncertain=0 b:in=0 out=58 uncertain=0 boxes-overlap=1` | `clearance [0, 14.248983110584208] estimated lo=certified samples=3157x58` |
| gear 110 vs frame 102 | `relation uncertain status=estimated a:in=0 out=3157 uncertain=0 b:in=0 out=58 uncertain=0 boxes-overlap=1` | `clearance [0, 12.809661269270311] estimated lo=certified samples=3157x58` |

**What BendCAD certifies:**
- **Volumes and areas:** every part's volume and area intervals.
- **Tooth-in-gap:** the `classify` results in section 1 (certified ray casting). On the line of centres a pinion tooth sits in a gear gap, in both stages.
- **No interference was found:** neither interference call reached a certified `interference` verdict, because no sample was strictly inside the other solid. Disjointness is not certified either.
- **Clearance lower bound of 0 only:** every clearance's certified lower bound is 0. Taken alone, that says nothing about a positive gap.
- **8.01 mm at two tip points:** a positive certified lower bound for gear-to-frame came only from point `distance` queries.
  - Gear-1 tooth tip at world (60, 46.99, 20) to frame 102: `distance [8.009999999999943, 18.585211863199184] estimated lo=certified`.
  - Point (166.99, 0, 50), which lies on gear 2's tip circle, to frame 102: `distance [8.009999999999815, 21.544375135983866] estimated lo=certified`.
  - So those two tip points clear the walls by at least 8.01 mm, certified. This is not a bound for the whole gear.

**What BendCAD only estimates:**
- **Mesh non-overlap:** that each meshing pair does not overlap rests on samples only. None of the 1267 pinion samples and none of the 3157 gear samples fell inside the other solid.
- **Mesh backlash gap:** the sampled closest approach of 0.159 mm, against a design backlash of 0.1 mm, is an estimated upper bound.
- **Gear-to-frame gap:** the sampled upper bounds are 14.25 mm and 12.81 mm. The frame had only 58 samples, so these bounds are loose; the true minimum is about 8 mm.

BendCAD did not certify that either full gear mesh is free of interference, or that the gears are disjoint from the frame.

## 4. PMI (housing, node 1)

```
(pmi (node 1)
  (datum A n1.c0.bottom)
  (dim dH H)
  (dim dFW FW)
  (dim dSeat -10 -10.05 -9.95)
  (dim dFWneg -20 -20.1 -19.9)
  (tol t1 flatness 0.02 n1.c0.top rfs)
  (state cold 1) (state hot 1.001)
  (stack gap1 dH dFWneg dSeat))
```

**`check`:** `pmi ok 9 items`.
- `datum A ok n1.c0.bottom plane`
- `dim dH nominal 70 zone [69.8, 70.2]`
- `dim dFW nominal 20 zone [19.9, 20.1]`
- `tol t1 flatness conforms actual 0 certified`
- plus both states and the stack.

**Signs in stack-ups:** a stack sums its dims and has no syntax for subtracting one. `(stack gap1 dH (- dFW) dSeat)` was refused with `why: stack-needs-dim`, and `-dFW` with `why: unknown-dim -dFW`.
- The axial gap between the stage-1 gear top and the cover underside is H - 10 (gear seat) - FW.
- I entered it as `dH` plus an explicit `dFWneg -20 [-20.1,-19.9]` that mirrors the FW zone, plus `dSeat -10 [-10.05,-9.95]`.
- The cost: `dFWneg` does not follow the FW parameter if FW is edited.

**`stack`:**

```
pmi node 1 stacks 1 states 2
stack gap1 nominal 40 envelope [39.64999999999997, 40.35000000000003] certified
state cold grow 1 [39.64999999999996, 40.35000000000004]
state hot grow 1.001 [39.68964999999996, 40.39035000000003]
```

**`step42`:** `wrote /home/jesse/g3/housing_pmi_ap242.stp ap242 PMI 42 entities`.

## 5. Exports

All 72 exports succeeded.
- **Part nodes 1-18:** `/home/jesse/g3/parts/<name>.step` and `/home/jesse/g3/parts/<name>.stl`.
- **Move nodes 101-118:** `/home/jesse/g3/placed/<name>.step` and `/home/jesse/g3/placed/<name>.stl`.

Reply sizes (STEP entities, STL triangles) were the same for the part and placed versions:

| name | node / placed node | STEP entities | STL triangles |
|---|---|---|---|
| base | 1 / 101 | 260 | 1392 |
| frame | 2 / 102 | 282 | 32 |
| cover | 3 / 103 | 260 | 1392 |
| shaft_in | 4 / 104 | 68 | 248 |
| shaft_mid | 5 / 105 | 68 | 248 |
| shaft_out | 6 / 106 | 68 | 248 |
| pinion1 | 7 / 107 | 8320 | 972 |
| gear1 | 8 / 108 | 20740 | 2052 |
| pinion2 | 9 / 109 | 8320 | 972 |
| gear2 | 10 / 110 | 20740 | 2052 |
| bearing_base_x0 | 11 / 111 | 102 | 708 |
| bearing_base_x60 | 12 / 112 | 102 | 708 |
| bearing_base_x120 | 13 / 113 | 102 | 708 |
| bearing_cover_x0 | 14 / 114 | 102 | 708 |
| bearing_cover_x60 | 15 / 115 | 102 | 708 |
| bearing_cover_x120 | 16 / 116 | 102 | 708 |
| seal_in | 17 / 117 | 102 | 656 |
| seal_out | 18 / 118 | 102 | 656 |

- **Measurement status:** every STL reply labels its measurements "sampled, not certified".
- **Spot check of a placed STL:** `placed/gear1.stl` spans x 13.07..106.99 and z 10..30. `parts/gear1.stl` spans x -46.93..46.99 and z 0..20.
- **Other output files:**
  - PMI export: `/home/jesse/g3/housing_pmi_ap242.stp`
  - Design: `/home/jesse/g3/gearbox.bcad`