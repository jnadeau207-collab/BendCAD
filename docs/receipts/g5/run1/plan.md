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
