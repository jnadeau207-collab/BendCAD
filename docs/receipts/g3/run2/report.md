# G3 run 2: two-stage spur gearbox, report

The design file is `/home/jesse/g3/gearbox.design`. All 110 tool calls are logged in `C:/dev/BendCAD/docs/receipts/g3/run2/calls.jsonl`. All geometry was built by BendCAD. Python was used only to run `gear.py`, which generated the four gear profiles.

## Parameters

- `(param H 70 69.8 70.2)` is the housing interior height. The wall-frame prism height uses it.
- `(param F 20 19.9 20.1)` is the gear face width. All four gear prisms use it.

`zone` certified both parts over the whole tolerance envelope:
- Node 2 (wall frame): volume [551420.0, 554580.0].
- Node 15 (pinion): volume [7149.08, 7220.93].

## 1. Parts and certified volume intervals (mm^3)

Every part has its own design node in a convenient local frame: z starts at 0, and the shaft axis is at the local origin. The housing parts use the input axis as the origin. Every node declares an exact intent (material, faces created, faces modified, solids, through-holes). The kernel accepted every intent as declared on the first try.

| node | part | operation | volume interval |
|---|---|---|---|
| 1 | base plate | prism 0 10: 230x130 rectangle with three r18 bores at x=0/60/120 (genus 3) | [268463.71940681286, 268463.7194074015] |
| 2 | wall frame | prism 0 H: outer 230x130, inner opening 200x110 (genus 1) | [552999.999996654, 553000.000003346] |
| 3 | cover plate | same as base | [268463.71940681286, 268463.7194074015] |
| 4 | input shaft | cylinder 10 110 | [34557.51918948621, 34557.51918948924] |
| 5 | intermediate shaft | cylinder 10 90 | [28274.3338823071, 28274.333882309173] |
| 6 | output shaft | cylinder 10 110 | [34557.51918948621, 34557.51918948924] |
| 7-12 | 6 bearings | prism 0 10, region r18 with r10 hole | [7037.167544041019, 7037.167544041254] each |
| 13, 14 | 2 seals | prism 0 4, region r16 with r10 hole | [1960.3538158399797, 1960.353815840083] each |
| 15 | stage-1 pinion, 15T | prism 0 F, gear.py 15 0 1 + r10 bore (183 faces) | [7185.000622031322, 7185.000622056703] |
| 16 | stage-1 gear, 45T | prism 0 F, gear.py 45 0 0.9 + r10 bore (453 faces) | [119247.56524000192, 119247.56524024402] |
| 17 | stage-2 pinion, 15T | same as 15 | [7185.000622031322, 7185.000622056703] |
| 18 | stage-2 gear, 45T | same as 16 | [119247.56524000192, 119247.56524024402] |

The tip-diameter figure in the brief is inconsistent. It says ADDENDUM 0.9 gives a tip diameter of 92.6. The formula in the brief (tip radius Z + 2*ADDENDUM) gives 46.8 for the 45-tooth gear, which is a diameter of 93.6. The BendCAD bbox matches 93.6: the 45-tooth gear spans x [-46.735, 46.793]. I used `gear.py` exactly as instructed.

Phase: every gear uses PHASE 0, chosen for these reasons:
- A pinion with PHASE 0 has a tooth at angle 0, which points toward the gear at +x.
- The 45-tooth gear has an odd tooth count, so PHASE 0 puts a tooth at 0 and therefore a gap at pi, which faces the pinion at -x.
- The same holds for stage 2: pinion at x=60, gear at x=120.

## 2. Assembly

```
(assembly
  (inst base 1 0 0 -10 0) (inst wall 2 0 0 0 0) (inst cover 3 0 0 0 0)
  (inst shaft_in 4 0 0 0 0) (inst shaft_mid 5 0 0 0 0) (inst shaft_out 6 0 0 0 0)
  (inst brg_in_lo 7 0 0 0 0) (inst brg_mid_lo 8 0 0 0 0) (inst brg_out_lo 9 0 0 0 0)
  (inst brg_in_hi 10 0 0 0 0) (inst brg_mid_hi 11 0 0 0 0) (inst brg_out_hi 12 0 0 0 0)
  (inst seal_in 13 0 0 0 0) (inst seal_out 14 0 0 0 0)
  (inst pinion1 15 0 0 0 0) (inst gear1 16 0 0 0 0) (inst pinion2 17 0 0 0 0) (inst gear2 18 0 0 0 0)
  (fix 1 base)
  (coinc 2 wall 0 0 0 base 0 0 10)
  (coinc 3 cover 0 0 0 wall 0 0 70)
  (axis 4 shaft_in 0 0 0 0 0 0 0 0 1)    (plane 5 shaft_in 0 0 0 0 0 1 -10)
  (axis 6 shaft_mid 0 0 0 60 0 0 0 0 1)  (plane 7 shaft_mid 0 0 0 0 0 1 -10)
  (axis 8 shaft_out 0 0 0 120 0 0 0 0 1) (plane 9 shaft_out 0 0 0 0 0 1 -30)
  (coinc 10 brg_in_lo 0 0 0 shaft_in 0 0 0)
  (coinc 11 brg_mid_lo 0 0 0 shaft_mid 0 0 0)
  (coinc 12 brg_out_lo 0 0 0 shaft_out 0 0 20)
  (coinc 13 brg_in_hi 0 0 0 shaft_in 0 0 80)
  (coinc 14 brg_mid_hi 0 0 0 shaft_mid 0 0 80)
  (coinc 15 brg_out_hi 0 0 0 shaft_out 0 0 100)
  (coinc 16 seal_in 0 0 0 shaft_in 0 0 90)
  (coinc 17 seal_out 0 0 0 shaft_out 0 0 16)
  (coinc 18 pinion1 0 0 0 shaft_in 0 0 20)
  (coinc 19 gear1 0 0 0 shaft_mid 0 0 20)
  (coinc 20 pinion2 0 0 0 shaft_mid 0 0 50)
  (coinc 21 gear2 0 0 0 shaft_out 0 0 70))
```

**Solve:** `asm solved ninst 18 nmates 21 dof 0 max-residual 4.263256414560601e-14`, `redundant []`. The assembly is fully constrained.

Solved translations, in world coordinates:

| instance | translation |
|---|---|
| base | (0, 0, -10) |
| wall | (0, 0, 0) |
| cover | (0, 0, 70) |
| shaft_in | (0, 0, -10) |
| shaft_mid | (60, 0, -9.999999999999993) |
| shaft_out | (119.99999999999999, 0, -29.99999999999999) |
| brg_in_lo / mid_lo / out_lo | z = -10 (out_lo at x 120.00000000000003) |
| brg_*_hi | z = 70 |
| seal_in | (0, 0, 80) |
| seal_out | (120.00000000000001, 0, -13.999999999999991) |
| pinion1 | (0, 0, 10) |
| gear1 | (60, 0, 10.000000000000007) |
| pinion2 | (60, 0, 40.00000000000001) |
| gear2 | (120, 0, 40) |

Two notes on the solve:
- Shaft rotation is not represented. Orientations are fixed per instance, so the mates solve translations only and dof 0 says nothing about spin.
- The mate values are literal numbers (for example 70 for the cover). Mates do not reference the parameter H, so a change to H would move the top face of the wall, but the cover mate would not follow it.

My own error, now fixed: the first solve had the base instance at (0, 0, 0), which put the housing 10 mm too high relative to the shafts. I corrected the base to (0, 0, -10) and re-solved; the result above is the corrected one. Placed copies 101-118 were made as `move` nodes at the solved translations, using the printed values literally. Each move declares `(intent same 0 0 1 g)`, and the kernel accepted all of them.

**Explode** along z with gap 25: instance k moves k*25 from its solved placement.

| instance | exploded z | instance | exploded z |
|---|---|---|---|
| base | -10 | brg_mid_hi | 320 |
| wall | 25 | brg_out_hi | 345 |
| cover | 120 | seal_in | 380 |
| shaft_in | 65 | seal_out | 311 |
| shaft_mid | 90 | pinion1 | 360 |
| shaft_out | 95.00000000000001 | gear1 | 385 |
| brg_in_lo | 140 | pinion2 | 440 |
| brg_mid_lo | 165 | gear2 | 465 |
| brg_out_lo | 190 | | |
| brg_in_hi | 295 | | |

x and y are unchanged by the explode.

## 3. Mesh and housing checks (placed copies)

| pair | interference | clearance |
|---|---|---|
| stage 1: pinion 115 vs gear 116 | `relation uncertain status=estimated a:in=0 out=1267 uncertain=0 b:in=0 out=3157 uncertain=0 boxes-overlap=1` (15 min) | `[0, 0.1364490253437204] estimated lo=certified samples=1267x3157` (15 min) |
| stage 2: pinion 117 vs gear 118 | `relation uncertain status=estimated`, identical counts (15 min) | `[0, 0.13644902534372255] estimated lo=certified` (17 min) |
| gear1 116 vs wall frame 102 | `relation disjoint status=certified` (5.6 min) | `[0, 14.377746109698178] estimated lo=certified samples=3157x58` |
| gear2 118 vs wall frame 102 | `relation uncertain status=estimated a:in=0 out=3157 b:in=0 out=58 boxes-overlap=1` | `[0, 12.936567680185346] estimated lo=certified samples=3157x58` |

On the line between centres, `classify` gives certified exact ray-cast answers:
- Stage 1: points (13.5, 0, 20) and (16.8, 0, 20) are inside pinion 115 and outside gear 116.
- Stage 2: points (73.5, 0, 50) and (76.8, 0, 50) are inside pinion 117 and outside gear 118.

So a pinion tooth sits in the gap of the gear on the line of centres for both stages.

**What BendCAD certifies:**
- Gear1 and the wall frame are disjoint.
- The four classify answers above.
- Every clearance lower bound. All of them are 0, so they carry no information.

**What BendCAD only estimates:**
- That the meshing gears do not overlap. Every sample of each gear (1267 and 3157) lies outside the other, but the face boxes overlap. The kernel does not certify disjointness of the interlocking tooth flanks.
- The mesh gap upper bound of about 0.136 mm. This is consistent with the 0.1 mm backlash, but it is a sample, not a proven minimum.
- Gear2 against the frame, which stayed `uncertain` even though gear1 was certified disjoint.

My own geometry says the radial clearance to the frame is 8.2 mm: the opening is 55 mm in y and 175 mm in x, against a tip radius of 46.8 mm. The sampled upper bounds of 14.4 and 12.9 mm are loose. No part of the "no overlap in the meshes" claim is certified.

## 4. PMI

```
(pmi (node 1) (datum A n1.c0.bottom) (dim dH H) (dim dF F)
  (dim dGearSeat -10 -10.05 -9.95) (dim dFace -20 -20.1 -19.9)
  (tol t1 flatness 0.02 n1.c0.top rfs) (state cold 1) (state hot 1.001)
  (stack gap1 dH dGearSeat dFace))
```

**Check** reported `pmi ok 9 items`:
- `datum A ok n1.c0.bottom plane`
- dH: nominal 70, zone [69.8, 70.2]
- dF: nominal 20, zone [19.9, 20.1]
- `tol t1 flatness conforms actual 0 certified`

**Stack:** the gap is the cover underside (H) minus the gear seat (10) minus the face width (F).
- Envelope: `nominal 40 envelope [39.64999999999997, 40.35000000000003] certified`
- Cold: [39.64999999999996, 40.35000000000004]
- Hot (grow 1.001): [39.68964999999996, 40.39035000000003]

**Refusal:** I first tried `(stack gap1 dH dGearSeat (- dF))`. BendCAD answered `error invalid-input | pmi stack | why: stack-needs-dim | fix: write (stack NAME DIM...) with a name and one or more dim names`. Stack terms cannot be negated, so I added `dFace`, an explicit negative mirror of the F zone, and the face-width term in the stack uses that. dF is still declared as the parameter-bound dimension.

**step42:** `wrote /home/jesse/g3/housing_base_pmi.stp ap242 PMI 42 entities`. The PMI is bound to the base plate, node 1.

## 5. Exported files

Every export succeeded and nothing was refused. STEP replies list entity counts:
- Gears: 8320 (15T) and 20740 (45T).
- Housing: 260 and 282.

STL replies carry the label "sampled, not certified". A spot check of the placed STLs showed shaft_out spanning z [-30, 80] and gear2 spanning x [73.26, 166.79].

Under `/home/jesse/g3/parts/` (part nodes 1-18) and `/home/jesse/g3/placed/` (move nodes 101-118), each directory has `NAME.stp` and `NAME.stl` for every NAME in:

base, wall, cover, shaft_in, shaft_mid, shaft_out, brg_in_lo, brg_mid_lo, brg_out_lo, brg_in_hi, brg_mid_hi, brg_out_hi, seal_in, seal_out, pinion1, gear1, pinion2, gear2

That is 72 files. Also exported:
- `/home/jesse/g3/housing_base_pmi.stp` (AP242 with PMI)
- `/home/jesse/g3/gearbox.design`

## Refusals and deviations

1. The PMI stack refused the negated term `(- dF)` with `stack-needs-dim`. I worked around it with the explicit dim `dFace`.
2. Both mesh interference checks and the gear2-vs-frame check came back `uncertain`/estimated, not refused. The results are reported above as estimates.
3. The tip diameter in the brief (92.6) differs from what `gear.py` produces and BendCAD measured (93.6).
4. The Bash tool caps foreground calls at 600 s, so the 15-minute queries ran as one background job and I collected their output when it finished.
