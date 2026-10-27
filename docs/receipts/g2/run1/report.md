# G2 report: SAE A external gear pump, run 1

## 0. Provenance

This was not a fresh-agent run. The design agent started run 1 through the
MCP tools (`calls.jsonl`, about 270 calls), sized the pump (`calc/`) and built
the 52-node master `/home/jesse/g2/parts/gearpump.bcd`. It then died on usage
limits. The owner ruled that subagents cannot run on this plan, so the main
session finished the run on 2026-10-19/20. It made these changes:

- added the O-ring (node 53);
- re-exported the gear shafts, the O-ring, the front-cover STL and the
  assembly;
- ran the interference checks;
- wrote this report and the independent grader (`tools/grade/g2.py`);
- graded and rendered.

Every kernel defect met on the way was fixed in BendCAD (§9), never by
changing the design. The binary is `/home/jesse/bc/bendcad-g2`, sha256
`26d2c367…`, built from BendCAD main `906a2c3`.

Labels: **MEASURED** means a published datum, with its source. **COMPUTED**
means calculated here, with assumptions stated. **CERTIFIED** means a BendCAD
output with `status=certified`; the file under `q/` is the evidence.
**PROJECTED** means an estimate not yet backed by test.

## 1. The pump

| Item | Value | Label |
|---|---|---|
| Gears | 2 spur, z = 12, m = 1.75, α = 20°, profile shift x = +0.35 (x_min = 0.294 for no undercut at z = 12), addendum coeff 0.88 | COMPUTED (`calc/sizing.json`) |
| Tip / root diameter | da = 25.305, df = 17.85 | COMPUTED |
| Centre distance | a = 22.05 (zero-backlash a = 22.0532; normal backlash 0.091) | COMPUTED |
| Working pressure angle, contact ratio | 26.50°, ε = 1.162 | COMPUTED |
| Gear width | b = 35.0 (body 35.05, side gaps 0.025 nominal) | COMPUTED |
| Displacement | 7.985 cm³/rev kinematic; 2π m² z b = 8.082 (−0.19 %) | COMPUTED |
| Theoretical flow at 3,000 rpm | 23.96 L/min | COMPUTED |
| Ports | suction M22×1.5, pressure M18×1.5, ISO 6149-1 O-ring boss, on opposite side faces, axes ⟂ gear axes | MEASURED (ISO 6149-1) |
| Port velocity | suction 1.44 m/s (≤ 1.5), pressure 4.20 m/s (≤ 5) | COMPUTED |
| Flange | SAE J744 A two-bolt, pilot Ø82.55 h8, holes on 106.4 centres | MEASURED (SAE J744) |
| Drive | SAE J744 11-4 keyed, Ø15.875, key 3.97 | MEASURED (SAE J744) |
| Body, covers | 6082-T6, 2700 kg/m³, α = 23.4e-6 /K | MEASURED (EN 755-2) |
| Gears and shafts | 16MnCr5 case-hardened, 7850 kg/m³ | MEASURED (EN 10084) |
| Bushings | GGB DU 1615 (front drive), DU 1215 (×3), steel/bronze/PTFE, 7600 kg/m³ | MEASURED (GGB DU catalogue) |
| Cover screws | ISO 4762 M8×80, class 12.9 | MEASURED |
| Dowels | ISO 8734 6×50, 100Cr6 | MEASURED |
| Shaft seal | DIN 3760 16×28×7 NBR70 with DC04 insert; circlip DIN 472 28 | MEASURED |
| O-ring | NBR70, 1250 kg/m³, racetrack around both gear centres | MEASURED (ISO 3601-1) |

### O-ring and groove

The groove (agent design, nodes 25 and 44) is a racetrack annulus 14.75–18.28
around both gear centres, depth 1.95, in each cover face. The O-ring is
modelled in its installed, compressed state:

- section 3.18 wide by 1.95 high, a stadium with full radius 0.975, laid
  against the groove's outer (pressure-side) wall;
- centreline radius 16.69;
- one `(sweep (along PATH) REGION)` node (node 53);
- certified volume [802.18036527342, 802.18036527586] mm³, genus 1,
  `check` ok (embedded, outward shell).

The installed section's area, 1.23 × 1.95 + π·0.975² = 5.385 mm², matches a
free circular section of d₂ = 2.62 mm (π·1.31² = 5.391 mm², −0.1 %). That is
the ISO 3601-1 / AS568 −1xx series, compressed with its volume conserved.
Squeeze is (2.62 − 1.95)/2.62 = 25.6 %. COMPUTED. The ISO 3601-2 table row
for groove width and depth is still to be cited (O3).

## 2. Sizing (§3)

All COMPUTED by the agent (`calc/size.py`, `calc/sizing.py`).

- **Displacement.** Exact tooth-space volume, 7.985 cm³/rev, from the
  kinematic formula `2πb(ra² − rw² − π²rb²/(3z²))`.

  The grader recomputes it independently from the exported outlines
  (contact-path flow integral) as 7.815 cm³/rev. Both lie within
  8 ± 3 %. The 2.1 % gap between the two methods comes from the grader
  locating the contact point as the midpoint of the nearest points across
  the 0.047 mm backlash.
- **Volumetric efficiency at 210 bar.** VG 46, μ(50 °C) = 0.0265 Pa·s.
  Laminar slot flow through the side, tip, mesh and transition gaps.
  Without wear plates (the fixed side clearance alone), as the gate asks:

  | Case | Side gap | Tip gap | η_v | Slip |
  |---|---|---|---|---|
  | Nominal, 50 °C | 0.031 | 0.035 | **0.705** | 7.06 L/min |
  | Tight, 20 °C | 0.022 | 0.025 | 0.894 | — |
  | Worst hot clearance, 80 °C | 0.0415 | 0.052 | **0.140** | — |

  The side gaps dominate the slip. The design meets the gate's clearance
  windows, but fixed clearances alone give poor efficiency hot. This is
  risk R3 in §7.
- **Wall.** Minimum wall 8.32 mm. Lamé hoop stress at 250 bar is 53.7 MPa
  against 6082-T6 R_p0.2 = 250 MPa (MEASURED, EN 755-2): SF 4.65.
- **Cover.**
  - Separating force over the O-ring area: 46.4 kN.
  - Plate bending stress: 68.3 MPa, SF 3.66.
- **Screws.**
  - External load per screw: 11.6 kN.
  - Preload: 29.6 kN.
  - Residual clamp at peak: 15.9 kN, so no separation.
  - Engagement: 19.95 mm (2.49 d ≥ 1.5 d).
- **Bushings.** Radial gear load at 250 bar: 16.6 kN. In the DU 1615:
  p = 29.1 MPa, v = 2.51 m/s, so PV = 73 MPa·m/s. This **exceeds the DU
  dry-running PV limit, 3.6 MPa·m/s, about 20 times** (MEASURED, GGB DU
  catalogue). Gear-pump DU bushings run oil-lubricated with a hydrodynamic
  film, for which the catalogue's dry limit does not apply. No hydrodynamic
  check was made. This is risk R4.
- **Peak drive torque.** 37.4 N·m.

## 3. Fits and clearances (§2)

Every row is CERTIFIED by BendCAD; the evidence is in `q/`.

| Fit | 20 °C | 80 °C | Verdict | Evidence |
|---|---|---|---|---|
| Tip clearance, drive and idler | [0.025, 0.038] | [0.034, 0.047] | in 0.02–0.06 | `q/pmi_body_stack.txt` (stack `tip_20C` / `tip_80C`); geometric gap [0.0300, ∞) and [0.0300, ∞) in `q/mesh_tipgap_*_f.txt` |
| Side clearance (body length, gear width, cover flatness) | [0.022, 0.029] | [0.0345, 0.0415] | in 0.02–0.05 | `q/pmi_body_stack.txt` (`side_20C` / `side_80C`) |
| Bushing bore to shaft running clearance | [0.0265, 0.0955] | — | DU catalogue journal tolerance | `q/pmi_bush_stack.txt` |
| Bushing OD to cover bore, JS6/r9 press (×4) | interference [0.0175, 0.0715] | [0.0041, 0.0582] (front drive); [0.0071, 0.0611] (others) | positive at both ends | `q/fits.txt` (`verdict=press-certified`) |
| Dowel to body H7/m6 (×2) | [−0.012, 0.008] | [−0.0077, 0.0123] | transition | `q/fits.txt` |
| Dowel to covers E8/m6 (×4) | clearance [0.008, 0.034] | [0.0123, 0.0383] | clearance | `q/fits.txt` |
| Flange pilot h8 | [82.496, 82.550] | — | h8 | `q/pmi_front_stack.txt` |
| Screw thread engagement | 19.95 = 2.49 d | — | ≥ 1.5 d | `q/master_engage.txt` |
| Gear mesh gap | [0.04684, 0.04684] over 240 traces | — | no contact | `q/mesh_gap_gears.txt` |

The 80 °C stacks carry mixed coefficients: aluminium body against steel
gears. BendCAD's PMI states apply one uniform growth factor per state
(`q/pmi_kb_uniform_growth.txt`), so the agent evaluated each material's
state separately and combined them by hand. That is open item O1 (§9).

## 4. Assembly

20 instances. The mate scheme:

- body fixed;
- covers coincident with the body on dowel 0's axis at their faces;
- dowels, bushings, seal and circlip coincident to their bores;
- gears coincident to the body at the chamber centres, 0.025 above the front face;
- key coincident to its keyway;
- screws coincident to their counterbores;
- O-rings coincident to their groove floors.

The solve reaches dof 0, max residual 8.5e-14 (`q/master_solve.txt`).

**Interference.** §4 requires no interference except the four bushing press
fits, which must be certified positive. Results:

- O-ring against body, front: `relation disjoint status=certified
  method=exact-intersection` (`calls.jsonl`, session records).
- Full assembly, independent grader (`grade.json` check `interference.full`,
  pair data `q/interf_occt.json`). OCCT booleans over all 190 instance pairs;
  67 have touching bounding boxes and each of those was intersected.
  Results:
  - The four bushing press fits touch at nominal size, with zero common
    volume. Their interference is the declared JS6/r9 fit, which BendCAD
    certifies as positive at both ends (§3, `q/fits.txt`).
  - The four M8 screws overlap the front cover by 278.27599 mm³ each. That
    is exactly the thread engagement: the 6.8 mm tap-drill bore to the 8 mm
    major diameter over the certified 19.95 mm engagement
    (π/4·(8² − 6.8²)·19.95 = 278.27599 mm³). The threads are declared
    (`thread 38 tap0..3 M8 6H`).
  - Every other pair is clear or touching. **No undeclared interference.**
- Full assembly through BendCAD `asm interf`: two runs are still going after
  46 h (serial) and 8 h (parallel pair loop), so there is no native result
  for the 20-instance assembly. That is open item O4.

## 5. Mass (§4)

Certified per part in `parts.txt`. Total for 20 instances:
**[1.764914429, 1.764914482] kg**. The grader's STEP total is 1.764914455.

## 6. Export and grading

- STEP AP242 per part and of the assembly; STL per part, all in
  `/home/jesse/g2/export/`.
- The front-cover STL is at preset 2 (23,649 triangles), because preset 3
  does not finish (open item O2).
- `grade.json` holds the independent grader's results: 25/25 checks pass
  (graded again on 2026-10-27, adding `interference.full`).
- Renders: `g2_assembly.png`, `g2_exploded.png`, `g2_section.png`.

## 7. Risk register

| Risk | Evidence | Mitigation in the model | Residual |
|---|---|---|---|
| R1 Cavitation at suction | suction 1.44 m/s at 23.96 L/min | M22 suction port larger than the M18 pressure port | PROJECTED low at 40–60 °C; inlet line sizing is the installer's |
| R2 Trapped oil at the mesh | ε = 1.16 traps a volume | relief grooves in both covers, half-gap 2.31 mm (`calc/sizing.json`) | PROJECTED; no CFD |
| R3 Side-clearance thermal closure and slip | η_v 0.705 nominal, 0.140 at worst hot clearance | side clearance certified 0.022–0.0415 over 20–80 °C, never closing | high slip hot; pressure-balanced bushing blocks or wear plates would fix it (optional in the gate, not modelled) |
| R4 Bushing wear | PV 73 MPa·m/s, about 20 × the dry DU limit | DU in oil, hydrodynamic film | unverified; needs a hydrodynamic check or test |

## 8. Gate refusals

None of the gate's refusal triggers fires:

- displacement is within ±3 %;
- every §2 fit is certified;
- wall SF is 4.65;
- the export agrees with the model (25/25).

## 9. Kernel blockers met and fixed in BendCAD

1. **Torus validation for inexact radii.** The O-ring torus with
   R = 24.155 failed validation. The C03 exact torus residual is fixed.
   Commit `31f91f9`.
2. **Evaluation speed.** Asm interf took over 4 h and master evaluation
   over 50 min. Fixed with face lookup trees, a first-hit sampler and
   single-tail recursions. Master evaluation now takes about 10 min.
   Commit `b87c860`.
3. **O-ring as one solid.** Cutting a revolved ring in half and unioning it
   with bars needs a tangent torus/cylinder intersection, which K1 refuses
   (reason 73). The fix is the new C06 path sweep `(sweep (along PATH)
   REGION)`, together with:
   - K1 hit certification on axis planes;
   - C04 Amendment A5: certified near-evaluation and scale-box membership;
   - C07 tight torus and cylinder boxes and transversal separation for G1
     joints.

   Commit `906a2c3`.
4. **Contact certification.** The sampling interference check could only
   answer "uncertain" for parts in contact, such as a seated O-ring. C11
   now tries the exact boolean intersection first, and an empty result
   certifies disjoint interiors. Commit `906a2c3`.

Open items:

- **O1.** PMI states apply one growth factor, so mixed-material thermal
  stacks need per-material states combined by hand.
- **O2.** Tessellation of the front cover at preset 3 does not finish
  (stopped after 4.5 h); preset 2 takes 23.6 min. A kernel performance
  defect.
- **O3.** The O-ring free section (2.62 mm) and squeeze (25.6 %) are
  computed above. The ISO 3601-2 table row for the groove is not cited.
- **O4.** Interference of a contacting pair costs about 10 min through `asm
  interf`. The same boolean costs about 30 s as a model node and 2 min
  50 s through `interf A B`, even when an operand carries a `move`
  placement. So the cost is specific to the assembly route. A call-graph
  profile puts it in C07 rational-Bézier arithmetic (`RB_ZIPC`, `RB_LVL`,
  `RB_BLOSSOM`, `RB_REPS`). Exact placements were tested and are not the
  cause. A parallel pair loop (`B.pmap_g` over the pairs) reaches only about
  1.6 cores: the few contacting pairs dominate, and every CLI call first
  re-evaluates the whole 52-node master (about 10 min). On 2026-10-27 the
  20-instance run had not finished after 46 h serial or 8 h parallel. The
  independent OCCT check above covers the gate. Open; it is the subject of
  the speed work that follows G2.
