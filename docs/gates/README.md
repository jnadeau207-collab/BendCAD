# Proof gates G2–G6: doctrine

Owner direction, 2026-10-15, after the G3 gearbox review.

The result decides what BendCAD must become; BendCAD's current abilities
never decide the result. When a gate needs geometry, a query, a material,
a certificate or an export that BendCAD cannot produce, the gate run stops
and BendCAD is changed until it can. Working around a kernel limit by
changing the design is not allowed. Simplifying a part until the kernel
accepts it is not allowed either.

The G3 review found these failures. Every later gate must avoid them:

- Fake purchased parts. A bearing is rings, rolling elements, cage and
  seals at catalog dimensions, sitting in a practical, serviceable holder.
  Seals, fasteners, dowels and gaskets are real catalog or drawn parts.
- Parts that cannot mate. Every joint names how it is held, located and
  sealed.
- No torque path. Every rotating part says how torque enters and leaves it.
- Wrong or missing material. Every part carries a named material grade.
  Mass properties come from that material's density and are certified by
  the kernel. Material choices are justified for the part's loads and
  temperatures.
- Faceted stand-ins. Blades, vanes and flow-path surfaces are true B-rep
  surfaces at the precision the physics needs.

A gate passes only with independent grading of the exported files and a
design document in which every number is labelled MEASURED, COMPUTED or
PROJECTED. A clean, named refusal is a valid outcome. A decorated miss is
not.

Briefs: G6 is `g6-humphrey-1.md`. The G2, G4 and G5 briefs are in
MASTER_PLAN §18 and are held to this doctrine.
