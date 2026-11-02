# GATE G5 — MICRO TURBOJET: a KJ-66-class engine a shop can build

Held to `README.md`: the result decides what BendCAD must become. Where
BendCAD cannot model, analyse or certify a part as specified, the run stops
and the kernel is changed. The part is never simplified to fit the kernel.
The ladder line (MASTER_PLAN §18) is the brief's core: a micro turbojet of
the KJ-66 class (about 100 N), drawings a shop can build from, clearances
certified in the cold and running states.

You are the design agent. Design and build a complete single-spool micro
turbojet in BendCAD through the MCP tools until it is fully constrained and
certified, then submit it to independent grading. The deliverable has three
parts:
- a BendCAD design whose geometry, mass properties, balance, clearances,
  natural frequencies and manufacturability are kernel results (certified
  where the kernel certifies, estimated with a stated error bound where it
  estimates);
- a drawing set a machine shop can build from: every manufactured part
  dimensioned and toleranced with semantic PMI bound to the model;
- a design document in which every number is labelled MEASURED (published
  data or a catalog datum, with citation), COMPUTED (your calculation,
  assumptions stated) or PROJECTED.

## 1. The engine

Single-spool turbojet for model and research use, running on kerosene
(Jet A-1) with oil-in-fuel lubrication.

- Design point: static sea-level thrust 100 N ± 10 %, ISA, at a shaft speed
  you choose and justify. Show the cycle: mass flow, compressor pressure
  ratio and efficiency, turbine inlet temperature, turbine efficiency,
  nozzle exit conditions, fuel flow and specific fuel consumption.
- Single-stage centrifugal compressor of the KJ-66 class (impeller tip
  diameter 60–70 mm), with a vaned radial diffuser and an axial
  straightener. The impeller is a real part: blades with their true
  surfaces, splitters if you use them, hub and bore, machined from a named
  aluminium alloy justified against tip-speed stress and inlet temperature.
- Annular combustor with a stated fuel injection scheme (vaporiser tubes or
  atomisers), primary, secondary and dilution holes sized from a cited
  method, a liner of a named heat-resistant alloy.
- Nozzle guide vane ring and single-stage axial turbine. Blades are true
  airfoil sections stacked along a defined line (C16 blades), the turbine a
  cast or machined nickel superalloy you name and justify against creep and
  stress at the turbine inlet temperature.
- Shaft, two rolling bearings at catalog dimensions (hybrid ceramic or steel,
  cited), preload spring, shaft tunnel with an oil-in-fuel feed, nut and
  retention. The torque path from turbine to compressor is explicit.
- Outer casing, intake, exhaust nozzle, fuel and oil manifolds, glow plug or
  igniter boss and starter interface. Every joint names how it is held,
  located and sealed.

## 2. What this gate certifies

- Mass properties per part and in total, from the material densities.
- Rotor balance: the certified centre-of-mass offset and products of
  inertia of the rotor group about the shaft axis against ISO 21940-11 at
  a grade you justify for the running speed.
- Clearances in two operating states, cold (20 °C, standstill) and running
  (design speed, with the part temperatures you state):
  - compressor blade tip to shroud contour;
  - turbine blade tip to shroud;
  - rotor to stator axial gaps (impeller back face, turbine disc to NGV);
  - bearing fits: inner ring on shaft and outer ring in tunnel.
  Running clearances include centrifugal growth of each rotor part for its
  material at speed and thermal growth of every part by its own CTE at its
  stated temperature.
- Natural frequencies: the compressor and turbine wheels' first modes and
  the rotor's first bending critical speed, computed by the kernel with a
  stated method and a convergence or error bound. Show the Campbell diagram
  with 1x, 2x, blade-passing and NGV-passing excitations, and the margin of
  the critical speed over running speed.
- Manufacturability: the impeller is machinable on a 5-axis mill with a
  named tool, every passage reachable and every internal corner radius at
  least the tool radius; every other part machinable or formable as you
  specify. Minimum wall thicknesses are kernel results.

## 3. Sizing work you must show

1. Cycle and component matching at the design point and at 50 %, 75 % and
   110 % of design speed (COMPUTED, with a cited map shape or loss model).
2. Compressor: velocity triangles, slip from a cited model, diffuser
   throat sizing.
3. Turbine: velocity triangles, Zweifel or equivalent loading, stage
   efficiency estimate with its basis.
4. Combustor: air split, liner pressure drop, primary-zone equivalence
   ratio, liner wall temperature estimate (PROJECTED where no method is
   certified).
5. Stress: impeller and turbine disc and blade-root stress at design speed
   and at 120 % overspeed against the materials' strength at temperature
   with a stated factor; turbine blade creep life (PROJECTED).
6. Bearings: speed factor n·dm against the catalog limit, load and life.
7. Risk register: surge, rub at transient, bearing failure, blade creep,
   combustor burn-through. Each risk gets evidence, a mitigation in the
   model and the residual exposure.

## 4. BendCAD build requirements

- Every part is its own versioned design node with truthful intent and a
  named material: impeller, diffuser, straightener, combustor liner and
  dome, NGV ring, turbine wheel, shaft, bearings, preload spring, shaft
  tunnel, outer casing, intake, nozzle, manifolds, nut, fasteners, seals.
- Real geometry, no stand-ins: impeller and turbine blades with their true
  surfaces and root blends; combustor holes as features; tapped holes as
  semantic thread features.
- Assembly at dof 0 with a stated mate scheme; certified interference
  none, except declared press fits.
- Drawings: every manufactured part carries semantic PMI (C15) sufficient to
  make it: dimensions, tolerances, datums, surface finish and material.
- STEP AP242 with PMI of every part and the assembly; STL at manufacturing
  tolerance.

## 5. Grading and refusals

A fresh grader that did not build the engine reads the exports and checks:
- envelope, intake and nozzle areas against the cycle claim;
- blade counts, impeller and turbine diameters and blade angles against
  the velocity triangles;
- mass properties and balance, recomputed;
- cold and running clearances, recomputed from the exported geometry and
  the stated growth;
- that every manufactured part's PMI fully defines it (no missing size or
  position), interpreted from AP242;
- the natural frequencies, recomputed by an independent method within the
  stated error bound.

Issue a named refusal whenever the thrust cannot be met at the stated
component efficiencies, a §2 item cannot be certified or computed, a
frequency or clearance margin fails, or a part is not manufacturable as
specified. A clean refusal is a valid outcome. A decorated miss is not.

## 6. Definition of done

- A versioned BendCAD design of the engine at dof 0.
- All §2 items certified or computed by the kernel with their bounds, in
  both operating states.
- The drawing set as AP242 PMI, STEP and STL exported.
- Independent grading PASS, or named refusals.
- A design document an engine engineer can check number by number.
