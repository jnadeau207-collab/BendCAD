# GATE G6c — the raised jet engine: one request, zero workaround edits

Proposed after the G5 evaluation (2026-11-08); written down 2026-11-17.

G5 was built by an agent that knew the kernel's limits. Edits were chosen to avoid refusals:

- disjoint blade rings unioned as balanced trees;
- bosses nudged off coplanar caps;
- blade-versus-revolve clearance queries in place of whole-part ones.

G6c is the same class of machine, a 100-200 N micro turbojet, raised to production practice and built from ONE natural-language request by an agent that is not told any of those tricks.

## Request (verbatim to the agent)

"Design and build a 150 N class micro turbojet with a centrifugal compressor, annular combustor, single-stage axial turbine and convergent nozzle, ready to manufacture, with every functional check passing."

## Pass criteria

- The agent's edit log contains no workaround edit. A workaround is any edit whose only purpose is to avoid a kernel refusal: it changes the design intent and is reverted when the kernel is fixed. Graded by an independent reviewer from the log.
- The `tools/g5/readiness.py` checks generalised to the new design, all `pass`:
  - design point;
  - liner air admission;
  - fuel to the primary zone;
  - running clearances;
  - bearing speed;
  - conforming meshes;
  - CFD (three mesh levels, converged, mass flow and pressure ratio near the cycle, liner split near the plan);
  - FEM stress and creep;
  - rotor and blade modes;
  - lubrication paths.
- Real parts: bearings, fasteners, seals and fittings at catalog dimensions; materials cited from free sources.
- The few-minutes product rule: idea to finished, checked part in minutes per part, measured.

## Prerequisites

G6a passed. The G5 readiness checks all passing on the G5 design.
