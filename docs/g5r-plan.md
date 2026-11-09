# G5R: make the G5 micro turbojet a real machine

Owner direction (2026-11-09):

- Bolts have heads and threads, and their holes have matching threads.
- Bearings have balls and spin.
- Every part that connects must have a physical way to connect.
- Rotating and flow parts must work in tolerance and to spec.
- Everything must show in the viewer, including smoke from a solved flow through the running machine.
- Do not cheap out.

Done means `tools/g5/readiness.py` reports every check `pass` (AGENTS.md, "Function, not proxies"). Today it reports 0/10.

## 1. Design point (one source)

`tools/g5/cycle.py` produces `cycle.json`, and every number that states the design point is generated from it:

| Quantity | Value |
|---|---|
| Shaft speed | 118,486 r/min |
| Impeller tip speed | 409 m/s |
| Compressor pressure ratio | 2.4 |
| Air mass flow | 0.265 kg/s |
| Turbine inlet temperature | 973 K |
| Thrust | 99 N |

The 99,700 r/min in the plan and the viewer is wrong and is removed. A readiness check compares every stated speed with `cycle.json`.

## 2. Combustor (annular, vaporiser type)

Sizing, at T3 399 K, p3 about 240 kPa (rho 2.10 kg/m³), a liner pressure drop of 4% (jet velocity about 96 m/s) and discharge coefficient 0.6:

- Total effective hole area: about 1,320 mm².
- Total geometric hole area: about 2,200 mm².
- Planned split: dilution about 50%, secondary 30%, vaporisers plus primary 20%.

| Row | z (mm) | Outer wall, r 46 | Inner wall, r 22 |
|---|---|---|---|
| Primary | 72 | 18 × Ø4.0 | 12 × Ø3.0 |
| Secondary | 95 | 18 × Ø5.0 | 12 × Ø3.5 |
| Dilution | 125 | 12 × Ø9.0 | 12 × Ø5.0 |

Fuel and the rear seal:

- **Vaporiser sticks:** 6 tubes, OD 4.5, ID 3.5, at r 34. They pass through the dome from z 50 to z 85, and their mouths open to plenum air.
- **Fuel ring:** hollow, at z 45–48, fed through one radial casing port.
- **Needles:** six Ø0.8 / Ø0.4 needles run radially in, then turn axially into each stick mouth.
- **Rear seal:** both liner walls end in slip joints over the NGV shroud OD and hub OD, with 0.05 mm radial clearance. All air then passes through the liner holes. The 0.5 mm bypass slots are removed.

CFD verifies the split and the pressure drop (section 6). Hole sizes are tuned until the split is within ±10% of plan.

## 3. Joints: every one has a physical connection

| Joint | Connection |
|---|---|
| Casing to front cover | Front-cover flange turned to a 53.2 spigot, z 16–20. The casing slips over it. 8 radial M3x0.5 6g screws go into M3 6H tapped holes 7 mm deep. |
| Diffuser plus straightener | Made as one part (merged). |
| Diffuser to front cover | Every third diffuser vane thickened to a 6 mm wedge (18 vanes). 6 axial M3 screws run through those vanes into tapped holes in the front cover. |
| Tunnel to diffuser | The diffuser's back disc extends inward behind the impeller (0.5 mm running gap). The tunnel front flange is fixed to it with 6 M3 socket screws from the rear into tapped bosses. |
| NGV to tunnel | NGV hub flange, 6 M3 axial screws into the tunnel rear face, tapped. |
| Exhaust to casing | Exhaust front flange as a spigot inside the casing, 8 radial M3 screws. |
| Intake to front cover | Spigot plus 4 M3 axial screws. |
| Shaft ends | M8x1 6g threads at both ends, nuts M8x1 6H. The impeller and turbine are clamped against the bearing inner rings through spacers. |
| Bearings | 608 hybrid. Outer rings in the tunnel bore at H7/k6 (checked with `pmi fits` cold and hot). Inner rings on the shaft at k5. |
| Bearing preload | Spring preload, with the spring seated on a shoulder. |
| Glow plug | M5x0.8 tapped boss on the casing, with the plug body modelled. |
| Fuel and lube ports | M5x0.8 tapped ports with banjo-style fittings modelled. |

Every screw is a real part: a socket cap head, a shank, and a true helical ISO 68 external thread. Every tapped hole carries the matching internal thread. The kernel's thread callouts (`(thread ...)`) record the ISO designation and class and certify engagement with `asm engage` (at least 1.5d in aluminium).

## 4. Kernel work

1. **Helical thread solid.**
   - A `skin` loft per quarter turn commits in 0.11 s.
   - A full turn is refused: the start cap and the flank one turn later are 0.068 mm apart (M3x0.5) and the generic self-intersection test cannot certify that.
   - Add a helix sweep operation that knows the turn spacing analytically and certifies separation from pitch minus tooth width.
   - Output: bicubic patches with a certified deviation from the true helicoid.
   - External threads union with the core; internal threads are subtracted from the tap-drill bore.
   - E2E: thread form and pitch measured from the B-rep against ISO 68, and engagement certified.
2. **Conforming tessellation.**
   - Remove the T-junction fillers (impeller 116k, turbine 179k, NGV 5.3k zero-area triangles).
   - Boundary refinement must split both sides of a shared edge.
   - E2E: zero zero-area triangles and every edge used exactly twice.
   - CFD meshing depends on this.
3. **Intent on tangent holes.** A hole exactly tangent to a face is measured as `material=same`. Fix the tangent degeneracy and add a pin.
4. **`wall` performance.** A plate with two holes ran past 10 minutes, against about 1 s with one hole. Find the stall.
5. **Parallel `scene`.** Tessellate parts in parallel inside the kernel.

## 5. Verification (each check is a receipt)

- **Certified clearances:** all stator pairs, swept rotor envelopes, and running clearances (cold minus thermal and centrifugal growth, using FEM temperatures and spin growth).
- **Thread engagement and fits** at cold and hot states.
- **Rotor balance and mass properties:** certified.
- **FEM:**
  - centrifugal plus thermal stress in the impeller (7075-T6) and the turbine (IN713C);
  - creep margin;
  - blade and disc modes with a Campbell diagram;
  - rotor critical speeds on the bearing stiffness.
- **Bearings:** L10 life, n·dm against the cited catalog limit, and lubrication flow.
- **Fuel path and lube path:** connectivity from inlet port to needle tips and to both bearings.

## 6. CFD (OpenFOAM 2412 in Docker, `opencfd/openfoam-default:2412`, 16 cores)

1. **Geometry:** the kernel exports the conforming fluid-boundary surfaces as STL, with the rotor zones marked.
2. **Mesh:** `snappyHexMesh` with refinement at blades, holes and gaps. A mesh-independence study uses three levels.
3. **Solver:**
   - `rhoSimpleFoam` steady compressible RANS, k-omega SST.
   - Rotating frame (MRF) zones for the impeller and turbine at the design speed.
   - Combustion as a volumetric heat release in the primary and secondary zones, sized from fuel flow × LHV. This is labelled as a model, not reacting chemistry.
   - A reacting `reactingFoam` run comes later if needed.
4. **Receipts:**
   - mass flow;
   - compressor pressure ratio;
   - liner hole flow split;
   - pressure losses;
   - turbine inlet temperature profile;
   - thrust;
   - recirculation and dead zones (a reversed-flow volume report).

   Each is compared with `cycle.json`.
5. **Export:** the velocity, temperature and turbulence fields, plus seeded streamlines, are exported for the viewer.

## 7. Viewer

1. **Smoke:** particles advected through the solved velocity field. They are emitted at the intake and in the fuel spray, coloured by speed, temperature or turbulent kinetic energy, and run in sync with the rotor spin.
2. **Section planes** show field contours.
3. **Threads** render from the true helical B-rep.
4. **Bearings:** balls orbit at the cage speed and spin about their own axes.
5. **Readiness panel:** every check with pass, fail or not-analyzed, linked to its receipt.

## Order

| Step | What |
|---|---|
| A | Design point, combustor, sealing, joints with thread callouts, lube path, in `jet.py` |
| B1 | Kernel helix operation |
| B2 | Conforming tessellation |
| C | CFD pipeline |
| D | Viewer smoke |
| E | FEM, modes, bearings |
| F | Readiness all-pass |
