# GATE G2 — FLANGED PUMP HOUSING: an SAE A external gear pump in BendCAD

Held to `README.md`: the result decides what BendCAD must become. Where
BendCAD cannot model a part as specified, the run stops and the kernel is
changed. The part is never simplified to fit the kernel.

You are the design agent. Design and build a complete external gear pump in
BendCAD through the MCP tools until it is fully constrained and certified.
Then submit it to independent grading. The deliverable has two parts:
- a BendCAD design whose geometry, mass properties, fits and clearances are
  kernel-certified;
- a design document in which every number is labelled MEASURED (published
  data or a catalog datum, with citation), COMPUTED (your calculation,
  assumptions stated) or PROJECTED.

## 1. The pump

Fixed-displacement external gear pump for mobile hydraulics. It mounts on an
SAE J744 A two-bolt flange and is driven by a keyed or splined shaft.

- Displacement 8 cm³/rev ±3 %, rated 3,000 rpm, rated outlet pressure
  210 bar continuous, 250 bar peak. ISO VG 46 mineral oil, 40–60 °C.
- Two spur gears, 20° pressure angle. Choose the module and tooth count
  yourself (10–14 teeth is the class), and justify the choice against
  displacement, flow ripple and undercut. If you choose fewer than 17 teeth,
  give the profile shift you use to avoid undercut. Drive gear and shaft may
  be one piece. The idler gear runs on its own shaft.
- Body: one-piece 6082-T6 aluminium centre section. It has a figure-eight
  gear chamber, and the suction and pressure ports enter through opposite
  side faces, perpendicular to the gear axes. The suction port is larger
  than the pressure port. Use ISO 6149-1 or SAE J1926 straight-thread O-ring
  boss ports at sizes you justify from port velocity: suction ≤ 1.5 m/s,
  pressure ≤ 5 m/s.
- Front cover carrying the SAE J744 A flange: pilot Ø82.55 h8 and two
  mounting holes on 106.4 mm centres. The rear cover is plain. Covers are
  bolted to the body with four socket head cap screws ISO 4762 (property
  class 12.9) into threaded holes, located by two dowel pins ISO 8734, and
  sealed by an O-ring in a groove that follows the figure-eight chamber with
  margin. Choose AS568 or ISO 3601 cross-section, groove width and depth from
  the standard's static face-seal table, and cite it.
- Bearings: four DU-type PTFE-lined steel-backed plain bushings (catalog
  dimensions, cited) pressed into the covers. Wear plates and pressure-
  balanced bushing blocks are optional. If you omit them, say what
  volumetric efficiency the fixed side clearance alone gives.
- Shaft seal: one radial lip seal, DIN 3760 or catalog equivalent, in the
  front cover, retained by a circlip DIN 472.
- Drive end: SAE J744 11-4 keyed shaft (Ø15.875 with a 3.97 key) or 9T 16/32
  spline. Model whichever you choose, and the key if keyed.
- Materials: every part carries a named grade and its density. Gears and
  shafts are case-hardened steel (16MnCr5 or 20MnCr5). Body and covers are
  6082-T6. Screws, dowels, seal, O-ring (NBR 70) and bushings use their
  catalog materials.

## 2. The fits this gate certifies

At this size these clearances decide whether the pump works:

- Gear tip to chamber bore radial clearance: choose a value in
  0.02–0.06 mm and certify it over the tolerance envelope. Too large and
  slip flow grows; too small and the gears contact the bore at temperature.
- Gear face to cover axial (side) clearance: choose a value in
  0.02–0.05 mm. This is the dominant leakage path. Certify the full stack:
  body length, gear width and cover flatness.
- Bushing bore to shaft running clearance, from the bushing catalog.
- Bushing outside diameter to cover bore press fit (interference certified
  positive at both ends of the envelope).
- Dowel fits: transition fit in one part, clearance in the other.
- Flange pilot h8 and screw thread engagement length (≥ 1.5 d in aluminium).

Every fit above becomes semantic PMI (C15) bound to durable selectors, with
a certified stack or fit evaluated at 20 °C and at 80 °C (aluminium and steel
grow differently; carry both coefficients).

## 3. Sizing work you must show

1. Displacement from gear geometry: the exact tooth-space volume, not just
   the 2π m² z b estimate. Theoretical flow at 3,000 rpm.
2. Volumetric efficiency estimate at 210 bar from slip through the side
   gaps and tip gaps (laminar slot-flow model, viscosity of VG 46 at 50 °C).
   State it as COMPUTED.
3. Port sizing from the velocity limits.
4. Body wall and cover stresses at 250 bar peak: chamber pressure acting on
   the projected areas. Thick-wall or plate estimate for the minimum wall,
   against 6082-T6 yield with a stated safety factor. Screw preload and
   joint separation check for the four cover screws.
5. Bushing load (pressure-induced radial load on the gears) against the
   bushing catalog PV limit.
6. Risk register: cavitation at suction, trapped-oil pressure at the mesh
   (relief grooves: design them or state why not), side-clearance thermal
   closure, bushing wear. Each risk gets evidence, a mitigation in the
   model, and the residual exposure.

## 4. BendCAD build requirements

- Every part is its own versioned design node with truthful intent:
  - body, front cover and rear cover;
  - drive and idler gear shafts, and the key;
  - four bushings, the lip seal, the circlip, the O-ring;
  - four cover screws and two dowels.
- Real geometry, no stand-ins:
  - side ports with their thread minor bore, spot face and O-ring boss
    counterbore;
  - threaded holes as semantic thread features: designation, class and
    length carried in PMI and in the STEP AP242 export;
  - socket head screws with their hex socket;
  - the O-ring groove around the chamber;
  - involute gear teeth.
- Assembly at dof 0 with a stated mate scheme. Certified interference: none,
  except the bushing press fits, which are certified positive interference.
  Certified clearances as listed in §2.
- Mass properties certificate per part and in total, from the material
  densities.
- STEP AP242 export of every part and the assembly. STL at manufacturing
  tolerance.

## 5. Grading and refusals

A fresh grader that did not build the pump reads the STEP export and checks:
- the envelope and port positions;
- gear tip and side clearances, recomputed from the exported geometry;
- the displacement, recomputed from the exported gear and chamber geometry;
- mass properties.

PASS requires model, export and document to agree within stated
tolerances.

Issue a named refusal whenever:
- displacement misses 8 cm³/rev ±3 %;
- a §2 fit cannot be certified;
- the wall stress check fails;
- the export disagrees with the model.

A refusal names the target, the computed value and the physics that blocks
it. A clean refusal is a valid gate outcome. A decorated miss is not.

## 6. Definition of done

- A versioned BendCAD design of the pump at dof 0.
- All §2 fits certified.
- STEP AP242 and STL exported.
- Independent grading PASS, or named refusals.
- A design document in which a hydraulic engineer can check every number.
