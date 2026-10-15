# GATE G6 — PRESSURE-GAIN CORE: design and build a detonation-core turbojet in BendCAD

Owner brief, 2026-10-15. Held to `README.md` (the result defines BendCAD, not the reverse).

You are the design agent for the final BendCAD proof gate. Your task is to
design, from first principles and published data, a complete bespoke turbojet
whose core uses **pressure-gain combustion**, build it in BendCAD through the
MCP/CLI until the assembly is fully constrained and certified, and submit it
to independent grading. This is a design-and-certification exercise: the
deliverable is a BendCAD model whose geometry, mass properties and clearances
are kernel-certified, plus a cycle deck in which every performance number is
either computed by you from stated assumptions or traced to a published
measured datum. Nothing else counts as done.

## 1. The engine (architecture is fixed — infer everything else)

Working designation: **HUMPHREY-1**. Single-spool, single-shaft turbojet:

1. **Inlet + single-stage centrifugal compressor**, design pressure ratio
   **4.2**, one additive-manufactured impeller. Single centrifugal stages at
   PR 3.8–4.0 are production-proven in this class (JetCat P220/P250); PR 5 is
   research territory — 4.2 is the top of the defensible band. Impeller tip
   speed ≤ 460 m/s. Use a realistic small-scale isentropic efficiency
   (0.70–0.78) and justify your value from scale effects (low Reynolds
   number, relative tip clearance, heat soak) — do not use large-engine
   0.88–0.90 values.
2. **Annular rotating detonation combustor (RDC)** in place of a conventional
   deflagration combustor. This is the novel element and the point of the
   gate. Detonation (Humphrey-cycle) heat addition raises pressure instead of
   dropping ~4%: charge the design the measured costs — a **5% total-pressure
   loss across the turbine guide-vane ring** downstream of the RDC (measured,
   Welsh et al. rigs) and your own computed injector/plenum losses — and
   credit only the net gain your deck actually closes.
3. **Turbine guide-vane ring + shroud in SiC/SiC CMC** (stationary parts
   only), additively manufactured as one monolith with the RDC outer body —
   the "detonation stator". CMC stationary hot parts are in production
   service (LEAP shrouds ~2,400 °F; GE9X liners, HPT nozzles, shrouds).
   **Rotating CMC blades are beyond flight heritage and are forbidden.**
   The vane passages must be shaped to attenuate detonation outflow
   unsteadiness, per the guide-vane rig evidence.
4. **Single-stage axial turbine**, uncooled nickel superalloy (production
   microjet practice), abradable tip shroud. The keystone measured fact you
   may rely on: a production axial turbine (T63) ran behind an RDC for >20
   min cumulative with no visible damage and no significant turbine-efficiency
   penalty (Naples/Hoke/Battelle, ASME JEGTP 141(2), 2019). Carry a
   turbine-efficiency debit for unsteady inflow anyway, and state it.
5. **Convergent nozzle.** No aerospike/plug claims — aerospike heritage is
   rocket-only (XRS-2200) and there is nothing meaningful to compensate at
   this exhaust pressure ratio.
6. **Shaft/bearings:** hybrid ceramic ball bearings, oil-in-fuel lubrication
   (production microjet practice at 55,000–120,000 rpm). One AM monolithic
   rotor group where credible (GE Catalyst pattern: 855 parts → 12).

**Explicitly rejected — do not add:** wave rotor (documented sealing/leakage
failure mode; a second unproven integration voids the design's premise),
recuperator or intercooler (WR21 proves the physics and also proves the
weight/volume kills this gate's compactness requirement), wet compression
(industrial only, not flight-proven), cooled turbine blades (not
manufacturable/credible at this scale), any second novel element. The design
gets exactly one miracle, and it is the combustor.

## 2. Fuel — the honest hard part, designed, not waved away

Neat Jet-A has **not** been shown to sustain rotating detonation at
compressor-delivery conditions in the open literature. Published liquid-
kerosene RDC operation required pre-vaporisation and/or hydrogen addition
(~9–13% by mass) and/or O₂ enrichment (~29%) and/or air at ~707–765 K. Your
design must therefore carry an explicit fuel-preparation system:

- Pre-vaporise the Jet-A using compressor-delivery air and exhaust-side heat
  (a vaporiser loop in the model, with volume and mass carried in the design
  and in the mass-properties certificate).
- Hydrogen pilot injection at the RDC injector face (~10% of fuel energy),
  sourced from a small pilot reservoir that is part of the assembly.
- Start and part-power on deflagration: the rig record shows the annulus runs
  as rapid deflagration below φ ≈ 0.5 with stable detonation above φ ≈ 0.82.
  Model the start sequence as a state in your design document.

If your cycle/sizing work shows this fuel system cannot close inside the
envelope of §3, issue a named refusal for the fuel system (see §6) instead of
silently assuming neat Jet-A detonates.

## 3. Targets (the benchmark is production hardware, not other studies)

Baseline to beat — PBS TJ150 (datasheet): 1,500 N / 337 lbf, TSFC
1.167 lb/lbf/h, 272 mm diameter, 520 mm length, 19.6 kg, 55,300 rpm.
PBS TJ100: 1,300 N, TSFC 1.138, 272 mm, 625 mm, 19.5 kg.

HUMPHREY-1 must meet or beat, inside the same envelope:

- **Thrust ≥ 1,500 N** sea-level static.
- **TSFC ≤ 1.05 lb/lbf/h** at max thrust (≈10% better than the best
  production engine in class), with 1.00 as stretch. Justification must come
  from your own cycle deck: pressure-gain combustion pays most at low PR
  (published turboshaft cycle studies: >7% relative efficiency benefit at low
  PR, vanishing at PR ≈15; sober bound for pressure-gain combustion overall:
  +5–7 points simple-cycle thermal efficiency — Gülen). Any TSFC your deck
  cannot close with the §1 charges applied is a refusal, not a rounding
  exercise.
- **Diameter ≤ 272 mm, length ≤ 560 mm, dry mass ≤ 19.6 kg** (kernel
  mass-properties certificate, with the fuel-prep system included).
- **Assembly fully constrained (dof 0)**, zero certified interference, and
  the §5 clearances certified by the kernel, not eyeballed.

## 4. Sizing work you must show (the "infer" half of this gate)

Produce a design document alongside the model containing, in order:

1. **Cycle deck** — Brayton baseline (same compressor, deflagration combustor
   with 4% pressure drop) vs Humphrey variant (RDC with your net pressure
   gain after all §1 charges), same TIT limit, same component efficiencies.
   Report thermal efficiency, specific thrust, TSFC for both. The delta is
   the design's claimed advantage; it may not exceed what this comparison
   produces.
2. **Compressor sizing** — mass flow from the thrust target, impeller
   inlet/outlet diameters, blade counts, tip speed, diffuser type, surge
   margin statement.
3. **RDC sizing from detonation physics** — choose the annulus mean diameter
   and **channel height from detonation cell size** for the §2 mixture at
   delivery pressure/temperature, with margin, citing the cell-size data you
   used. Derive wave count and wave rotation frequency from wave speed
   (~1,800–2,000 m/s class for these mixtures) and annulus circumference;
   state the resulting unsteady forcing frequency on the turbine and check it
   against the T63 precedent (subsonic axial stage, kHz-class unsteadiness,
   efficiency preserved).
4. **Turbine sizing** — stage loading, blade height, and the **cold tip
   clearance you will certify (≤ 0.15 mm)** with the thermal-growth argument
   that keeps it positive at temperature. (Why this matters: ~+1%
   clearance/blade-height ≈ −1.5% efficiency, ≈+3% fuel — Rolls-Royce data.
   At this scale the clearance certificate *is* an efficiency claim.)
5. **Rotordynamics** — shaft critical speeds vs operating range, bearing
   loads, and the AM rotor group's balance provisions.
6. **Risk register** — combustor–turbine interface loss, injector–detonation
   coupling and mode control, fuel prep, thermal durability (state honestly:
   the longest continuous RDC runs anywhere are ~300 s, KIT, hydrogen — this
   gate certifies a *design*, not a 4,000 h TBO), starting, NOx unknowns.
   Every risk gets: published evidence, design mitigation in the model, and
   residual exposure. No risk may be listed as "none".

## 5. BendCAD build requirements

- Build through the MCP tools / CLI as a versioned design: compressor,
  RDC annulus + injector ring, detonation stator (CMC NGV + shroud monolith),
  turbine, rotor group, bearings + housings, casing, vaporiser loop, pilot
  reservoir, nozzle, front/rear frames. Instance-qualified faces on every
  interface that matters (C14 lineage).
- Mates to **dof 0** with a stated mate scheme per joint (fix/coincident/
  plane/axis as appropriate).
- **Certified queries, all green:** interference = none; clearances —
  turbine tip clearance, compressor tip clearance, RDC annulus channel
  height uniformity around the full circumference, bearing-seat fits,
  minimum wall on the RDC outer body and vaporiser loop.
- **Semantic PMI/GD&T (C15)** on the physics-critical dimensions: annulus
  channel height, tip clearances, bearing bores, injector orifice pattern —
  with certified tolerance stacks.
- **Mass properties certificate** vs the §3 mass target, per-part and total.
- Tessellation at manufacturing quality on all flow-path surfaces; blade and
  vane surfaces are true B-rep surfaces, not faceted stand-ins.

## 6. Grading and refusals

- Export **STEP AP242** and hand the export plus the design document to
  independent grading (a fresh agent/session that did not build it):
  read the STEP back, measure envelope, annulus channel height, tip
  clearances and injector pattern from the export, recompute mass properties
  from the export, and recompute the cycle deck's headline numbers from the
  geometry (flow areas, PR, annulus size). PASS requires the export, the
  model and the deck to agree within stated tolerances.
- Issue a **named refusal** — do not fudge, shrink the claim silently, or
  average away a miss — whenever: the cycle deck cannot close TSFC ≤ 1.05
  with all charges applied; the RDC channel cannot fit its cell-size
  requirement inside the envelope; a certified clearance or interference
  query fails; the mass certificate exceeds 19.6 kg; or grading finds the
  STEP export disagrees with the model. A refusal names the target, the
  computed value, and the physics that blocks it. A clean refusal is a valid
  gate outcome; a decorated miss is not.
- Label every number in the design document **MEASURED** (published test
  data, with citation), **COMPUTED** (your deck, assumptions stated), or
  **PROJECTED** (study claims). The T63 turbine result, the 5% guide-vane
  loss, the CMC and AM service records and the TJ150 datasheet are MEASURED.
  The engine's own TSFC is COMPUTED until hardware exists, and must be
  written that way everywhere it appears.

## 7. Definition of done

A versioned BendCAD design of HUMPHREY-1, dof 0, all §5 certificates green,
STEP AP242 exported, independent grading PASS (or named refusals on the
specific targets that failed), and a design document in which a competent
turbomachinery engineer can check every number. The engine you are describing
has never been built; the physics of every part of it has. Keep both halves
of that sentence true in everything you write.
