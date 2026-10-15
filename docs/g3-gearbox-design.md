# G3 reference gearbox — engineering review and design (v3)

The G3 runs (`docs/receipts/g3/run1`, `run2`) produced a gearbox that was
geometrically valid and kinematically right, but not one anyone could build
and run. The owner's review named three gaps; working through them turned up
more. This document records what was wrong, what a usable gearbox needs, and
the design that closes the gaps, built entirely by BendCAD from
`tools/g3/gearbox.py` (receipt `docs/receipts/g3/v3/receipt.md`).

## 1. What was wrong

| # | Defect | Why it matters |
|---|---|---|
| 1 | Floor, walls and lid were three loose slabs that only touch. | Nothing holds or aligns them; the joint cannot hold lubricant. |
| 2 | Input and output shafts were plain round bars. | No positive drive: a coupling or pulley slips. |
| 3 | "Bearings" were solid rectangular-section rings. | No rolling elements, no seals, no catalog part. |
| 4 | Bearing bores were line-to-line holes through 10 mm plates. | No shoulder, no axial location, no retention; inner rings rubbed the housing. |
| 5 | Gears floated on shafts with nothing transmitting torque or locating them. | Torque and axial position were undefined. |
| 6 | 15-tooth pinions at 20 degrees. | Below the 17-18 tooth minimum: a generated pinion is undercut. |
| 7 | Shaft "seals" were plain rings. | A static ring on a rotating shaft is not a seal. |
| 8 | No mounting, no alignment dowels, no vent, no lubricant plan. | Missing for any real installation. |

## 2. Design

**Gear train.** Module 2, 20 degree pressure angle, 18/54 teeth per stage
(no undercut), centre distance 72 mm, ratio 3 x 3 = 9. Backlash 0.1 mm per
gear by tooth thinning; exact mesh clearance 0.100 mm. Face width 20 (the
stage-2 pinion 22, so the stage-2 gear clears stage 1 axially by 2 mm).
Lewis estimate with Y(18) = 0.309: a steel stage-2 pinion (allowable
150 MPa) carries about 33 N.m, so steel gears are good for roughly
10 N.m in / 60-90 N.m out, printed nylon (20 MPa) for about 1 N.m in /
8 N.m out.

**Shafts and torque path.** Three 20 mm D-profile shafts (flat 2 mm deep at
x = 8, the shape McMaster-Carr sells as D-profile rotary shaft). Every gear
and spacer has a matching D bore, so torque is carried by form, not
friction. The input end (above the lid) and the output end (below the floor)
are the same D profile: a coupling, pulley or sprocket clamps on the flat
with a set screw. The input pinion has a 28 mm hub.

**Bearings.** Six 6004-2RS deep groove ball bearings, 20 x 42 x 12: inner
and outer rings with raceway grooves (radius 3.4 mm, 53 % conformity), nine
6.35 mm balls on a 31 mm pitch circle, a rubber seal disc each side. The
complete bearing is also exported as one 13-solid STEP part for the bill of
materials.

**Bearing seats and axial location.** Each shaft runs in a lower bearing
in a blind 12 mm pocket in the floor and an upper bearing in an 11.3 mm
pocket in the lid. The pockets grip the outer ring with four crush flats
(42.5 mm bore, flats tangent to 42.0) for a printed housing; a machined
housing reams the same bores to H7. A 1 mm relief step (37 mm) under each
outer ring, inside the 38 mm housing-shoulder limit, keeps the inner ring
off the housing. Cross-located arrangement: the spacer stack on each shaft
(spacer, gear(s), spacer) bears on the two inner rings, and its length
leaves an end float certified at 0.18-0.86 mm over the whole tolerance
envelope, cold and hot (§4).

**Housing.** One piece: a 26 mm floor with a mounting flange (four 6.6 mm
holes for M6) and 16 mm walls grown from it, so floor and walls cannot leak
or shift. Cavity corners are radiused 10 mm. The wall top carries ten M5
heat-set inserts and two 5 mm dowel holes. The output seal sits in a bore
under the output bearing, entered from inside, with the shaft leaving
through a 22 mm hole.

**Gasket and lid.** A full-face die-cut gasket (1 mm nitrile-cork or
fibre, 0.9 mm compressed) covers the wall top, punched for the ten bolts
and two dowels. The 26 mm lid is held by ten ISO 4017 M5 x 35 hex head
screws, located by two ISO 8734 5 x 16 dowel pins, carries the three upper
bearing pockets, the input seal bore above the input bearing, and a 12 mm
fill/vent port with a push-in vent plug.

**Seals.** Two radial lip seals, DIN 3760 type A, 20 x 35 x 7, in 35 mm
H8 bores, lips toward the gears.

**Lubrication.** Semi-fluid gear grease (NLGI 00), about 150 g, filled
through the vent port.

## 3. What BendCAD could not model, and how the design responds

Recorded as kernel limits, not hidden:

- Features on the two faces of one cell interact even when they cannot meet
  in z (the C06 cell tree treats every child cell as an obstacle on both
  sides). Response: every bore chain is cut from one side (bearing pocket,
  then seal bore, then through hole).
- Booleans of touching solids keep them separate (C08), and pads must lie
  strictly inside the face they grow from. Response: separate gears on
  D-shafts rather than gear-shafts cut in one piece.
- A pocket in a head over a shank grown beneath it is refused. Response:
  hex head screws rather than socket head.
- A ring pocket whose inner edge encloses a hole of the face (an O-ring
  groove round the cavity) is refused. Response: the flat gasket.
- The STEP writer has no CONICAL_SURFACE. Response: seal lips modelled with
  cylinders, planes and a torus.
- Thin tori (R/r beyond about 8-12) fail validation. Response: the seal's
  garter spring is not modelled.
- No threads (tapped holes and screws at nominal diameters), no chamfers on
  pad edges (seal lead-in chamfers are a drawing note), no side holes.
- Meshing-gear disjointness and clearance are estimated, not certified (C11).

One defect found here was fixed rather than designed around: profile
clearance between concentric arcs was never certified (a 2 mm-thick ring
built from arcs was refused). See the receipt.

## 4. Fits and stack-up (PMI, certified)

| Feature | Size | Tolerance |
|---|---|---|
| Housing interior height H | 46 | +/-0.03 |
| Floor pocket depth | 12 | +/-0.03 |
| Gasket, compressed | 0.9 | 0.8 to 1.0 |
| Lid pocket depth | 11.3 | +/-0.03 |
| Bearing width (two) | 12 | 0 / -0.12 |
| Spacer stack length | 45.8 | +/-0.03 |
| Wall top flatness | | 0.05 |
| Wall top parallel to datum A (floor bottom) | | 0.05 |

End float = H + floor pocket + gasket + lid pocket - 2 x bearing width -
stack length: nominal 0.40 mm, certified [0.18, 0.86] mm, cold
[0.18, 0.86] and hot (1.001) [0.18, 0.86]. Bearing seat (machined) 42 H7,
journal 20 k5, seal bore 35 H8.

## 5. Bill of materials

| Qty | Part | Source |
|---|---|---|
| 1 | Housing (floor + walls), PETG/ASA or 6061 | made |
| 1 | Lid | made |
| 3 | D-profile shaft 20 mm (lengths 118.5, 71, 118.5) | McMaster-Carr class, cut to length |
| 1 | Input pinion 18T with hub, D bore | made |
| 1 | Stage-1 gear 54T, D bore | made |
| 1 | Stage-2 pinion 18T, D bore | made |
| 1 | Stage-2 gear 54T, D bore | made |
| 6 | Spacer, 24 OD, D bore (2, 2, 1.8, 1.8, 15.8, 24 mm) | made |
| 6 | 6004-2RS bearing 20 x 42 x 12 | McMaster-Carr class |
| 2 | Radial lip seal 20 x 35 x 7, DIN 3760 A, NBR | McMaster-Carr class |
| 1 | Gasket, 0.9 mm compressed, die-cut | made |
| 10 | M5 x 35 hex head screw, ISO 4017 | McMaster-Carr class |
| 10 | M5 heat-set insert, 9.5 mm | McMaster-Carr class |
| 2 | Dowel pin 5 x 16, ISO 8734 | McMaster-Carr class |
| 4 | M5 set screw (gear and coupling flats, not modelled) | McMaster-Carr class |
| 1 | Push-in vent plug, 12 mm | McMaster-Carr class |
| ~150 g | Semi-fluid gear grease NLGI 00 | consumable |
