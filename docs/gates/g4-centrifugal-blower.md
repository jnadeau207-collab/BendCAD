# GATE G4 — CENTRIFUGAL BLOWER: a direct-drive process blower in BendCAD

Held to `README.md`: the result decides what BendCAD must become. Where
BendCAD cannot model, analyse or certify a part as specified, the run stops
and the kernel is changed. The part is never simplified to fit the kernel.

You are the design agent. Design and build a complete single-inlet
centrifugal blower in BendCAD through the MCP tools until it is fully
constrained and certified, then submit it to independent grading. The
deliverable has two parts:
- a BendCAD design whose geometry, mass properties, balance, clearances,
  natural frequencies and manufacturability are kernel results (certified
  where the kernel certifies, estimated with a stated error bound where it
  estimates);
- a design document in which every number is labelled MEASURED (published
  data or a catalog datum, with citation), COMPUTED (your calculation,
  assumptions stated) or PROJECTED.

## 1. The blower

Direct-drive industrial process blower for clean air at 20 °C, sea level.

- Duty point 3,000 m³/h at 2.5 kPa total pressure rise, on a two-pole
  IEC motor at 50 Hz (choose the frame and power from a cited catalog;
  model it at catalog dimensions with its B5 flange and shaft key).
- Backward-curved impeller, single inlet. Choose diameter, blade count,
  blade angles and widths and justify them against the duty point with the
  Euler equation, a slip model you cite, and stated losses. Hub disc,
  shroud and blades are one machined aluminium part (EN AW-7075-T6 or
  6082-T6, justified against tip-speed stress), keyed to the motor shaft
  and axially retained.
- Scroll casing with an inlet cone (bellmouth) overlapping the impeller
  shroud eye. The volute follows a cited design rule (free vortex or
  constant velocity); the tongue clearance is a stated fraction of the
  impeller diameter. The casing is bolted to a motor pedestal; the outlet
  ends in a rectangular flange with a bolt pattern.
- Fasteners, key, retaining washer and gasket are real catalog or drawn
  parts with named materials.

## 2. What this gate certifies

- Mass properties per part and in total, from the material densities.
- Impeller balance: the certified centre-of-mass offset from the shaft
  axis and products of inertia, against ISO 21940-11 grade G2.5 at the
  running speed (permissible residual unbalance computed, residual
  certified below it).
- Clearances: impeller to inlet cone (radial and axial overlap), impeller
  to tongue, impeller to casing back wall; certified, at standstill and
  at running speed with the impeller's centrifugal growth computed for its
  material.
- Natural frequencies: the impeller's first modes and the rotor's first
  bending critical speed, computed by the kernel with a stated method and
  a convergence or error bound. The first impeller mode clears 1x, 2x and
  blade-passing excitation by at least 10 % (Campbell diagram); the
  critical speed is at least 1.25 times running speed.
- Manufacturability: the impeller is machinable on a 5-axis mill with a
  tool you name (diameter, flute length, holder), every blade passage
  reachable and every internal corner radius at least the tool radius;
  casing parts are machinable or formable as you specify. Minimum wall
  thicknesses and draft (for any cast part) are kernel results.

## 3. Sizing work you must show

1. Performance: velocity triangles at inlet and outlet, slip, Euler head,
   loss model, predicted pressure rise and shaft power at the duty point,
   and the fan curve over 50–120 % flow (COMPUTED).
2. Impeller stress: centrifugal disc and blade stress at running speed and
   at 120 % overspeed against the alloy's yield with a stated factor.
3. Bearings: the motor's own bearings carry the overhung impeller; check
   the radial load and moment against the motor catalog's permitted
   overhung load.
4. Noise: blade-passing frequency and a cited empirical sound-power
   estimate (PROJECTED).
5. Risk register: surge or stall line, tongue noise, imbalance growth from
   fouling, fatigue at blade roots. Each risk gets evidence, a mitigation
   in the model and the residual exposure.

## 4. BendCAD build requirements

- Every part is its own versioned design node with truthful intent and a
  named material: impeller, inlet cone, scroll casing (with back plate),
  pedestal, motor (catalog envelope with flange, spigot and keyed shaft),
  key, retaining washer and screw, casing fasteners, outlet flange gasket.
- Real geometry, no stand-ins: blades with their true profile and roots
  filleted to the hub and shroud as machined; the volute spiral; bolt
  holes as semantic thread features where tapped.
- Assembly at dof 0 with a stated mate scheme; certified interference
  none, except declared press or key fits.
- STEP AP242 of every part and the assembly; STL at manufacturing
  tolerance.

## 5. Grading and refusals

A fresh grader that did not build the blower reads the exports and checks:
- envelope, inlet and outlet positions and flange patterns;
- impeller to cone and tongue clearances, recomputed from the exported
  geometry;
- mass properties and balance, recomputed;
- blade angles and impeller diameter against the performance claim;
- the natural frequencies, recomputed by an independent method of the
  grader's choosing within the stated error bound.

Issue a named refusal whenever the duty point cannot be met at the stated
efficiency, a §2 item cannot be certified or computed, a frequency margin
fails, or a part is not manufacturable as specified. A clean refusal is a
valid outcome. A decorated miss is not.

## 6. Definition of done

- A versioned BendCAD design of the blower at dof 0.
- All §2 items certified or computed by the kernel with their bounds.
- STEP AP242 and STL exported.
- Independent grading PASS, or named refusals.
- A design document a fan engineer can check number by number.
