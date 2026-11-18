# GATE G6b — breadth: a maglev bogie module

Proposed after the G5 evaluation (2026-11-08); written down 2026-11-17.

G5 and G6 are turbomachines: revolved parts, blades and rings. G6b proves the kernel is not a turbomachine specialist. It asks for a mechanism built mostly from plate, sheet, extrusion, fasteners and electromagnetic parts.

## The product

An electromagnetic-suspension (EMS) bogie module for a low-speed urban maglev vehicle. It wraps a steel F-rail, and an agent designs and builds it from one request:

- Levitation magnets: U-core laminated electromagnets with copper coils, with the air gap to the rail set by the design. The coil is a real wound part: copper section, fill factor and turns stated.
- Guidance from the same U-cores' lateral restoring force. No separate guidance magnets.
- A sheet-metal module frame: bends, reliefs, flat patterns exported, with the K-factor stated.
- Secondary suspension: air-spring seats, with the air spring a catalog part held by real fasteners.
- Skids and an emergency landing surface.
- A gap-sensor bracket holding the sensor at its rated standoff.

## Pass criteria

- Certified clearance between magnet poles and rail at the design gap, and at the gap tolerance extremes stated with its source.
- Lift force at the design gap and current. Computed from a stated magnetic-circuit model with material B-H data from a free cited source. The model is labelled COMPUTED.
- Coil current density and temperature rise inside the insulation class (cited).
- Frame stress under the vehicle load case, and certified sheet-metal flat patterns.
- Every fastener a real ISO or DIN part with its clamp checked by `fasten`.
- STEP AP242 export, independent grading, and a design document labelled MEASURED / COMPUTED / PROJECTED.

## What it exercises that G5 and G6 do not

Sheet metal (c16/sheet), laminated stacks as patterns, wound coils, the drawings verb, large flat assemblies, and magnetic analysis as a named function check. That last one is new: a readiness check has no magnetic analysis yet.
