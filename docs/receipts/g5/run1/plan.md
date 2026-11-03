# G5 run 1: design point and build order

Design point (COMPUTED, `tools/g5/cycle.py`, `cycle.json`): 99.3 N static
sea-level thrust at 0.265 kg/s, compressor PR 2.4 at 0.74, turbine inlet
973 K at 0.80, combustor 5 % pressure loss, fuel 4.4 g/s, 66 mm impeller at
345 m/s tip (99,700 r/min), exhaust 875 K, unchoked nozzle exit 46.4 mm.

Assumed efficiencies are COMPUTED placeholders until each component is
sized (brief sec. 3); every one gets a cited basis in the design document.

Build order, each a versioned BendCAD node with a named material:
1. shaft, bearings (catalog), preload spring, tunnel;
2. compressor impeller (machined 7075-T6), diffuser, straightener;
3. NGV ring and axial turbine (Inconel 713C), true airfoil sections (C16);
4. combustor liner and dome, injection, igniter boss;
5. casing, intake, nozzle, manifolds, fasteners and seals;
6. assembly at dof 0, certified cold clearances (`clearance A B 0.001`),
   running clearances = certified cold minus computed centrifugal and
   thermal growth; modes, balance, PMI drawings, STEP/STL, grading.

## Compressor sizing (COMPUTED, `cycle.json`)

Wiesner slip with 6 main + 6 splitter blades (Z = 12) and 30 deg
backsweep gives slip 0.837; at exit flow coefficient 0.30 the required
111 kJ/kg needs a 409 m/s tip on the 66 mm wheel: 118,500 r/min. The 608
hybrid bearings then run at n*dm = 1.78e6 mm/min, a risk-register item
against the cited catalog limit.

## K4 kernel packet (what G5 needs that BendCAD lacks)

Measured refusals while building G5 parts:

1. `pattern-angle-not-certified` and `interval-placement`: N-fold rotated
   copies (7 balls, 12 impeller blades, NGV and turbine rows) could not be
   placed. Fixed in fb8: a general rotation is admitted in booleans and its
   certified placement error (`pl_slop`) is added to the operand's linear
   uncertainty. Open: overlapping coplanar faces between a rotated and an
   unrotated operand fail validation (`edge-crossing-uncertain`).
2. Freeform blade solids: 3D impeller blades (pressure and suction
   surfaces as bicubic or NURBS patches, trimmed by hub and shroud) are not
   buildable, and booleans refuse curved freeform faces
   (`curved-surface-operand`). Needed: a closed blade solid from two
   surfaces plus caps, admitted in K1 booleans with certified
   surface-surface intersection.
3. Turbine airfoils: C16.3 admits NACA 4-digit sections (max camber 9 %)
   with twist in 10 deg steps; turbine rows need high-turning sections
   (camber line plus thickness distribution) and arbitrary twist.
