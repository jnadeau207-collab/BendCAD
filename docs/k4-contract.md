# K4 — Freeform faces in solids and booleans (contract)

General CAD capability, not a gate feature: car panels, bottles, handles,
hulls, ergonomic housings and turbomachinery blades all need solids
bounded by freeform surfaces that take part in booleans. G5 (compressor
impeller, NGV and turbine blades) is the first consumer.

## 1. Positive list

- General-angle placement in booleans: a rotated operand is baked at its
  midpoint matrix and its certified placement error is added to its
  linear uncertainty (landed, c07e44e).
- Freeform solids: a closed solid bounded by bicubic Bezier patches
  (and later NURBS), built from section curves (ruled and lofted walls,
  caps), validated on the manifold-solid profile.
- Booleans between freeform and analytic solids (plane, cylinder, cone,
  sphere, torus) and between two freeform solids:
  - edge-face hits: cubic and rational edges against patches by certified
    curve-surface intersection;
  - face-face curves: patch against implicit surface (C07 `bi_go`) and
    patch against patch (C07 `SS.trace`), carried as certified curves
    with explicit bounds;
  - trimming and classification in each patch's own (u, v) domain with
    certified point inversion;
  - lineage, durable names and volume identities as for analytic K1.
- Mass properties, STEP AP242 export and tessellation of the results.

## 2. Speed (acceptance, not aspiration)

The end state must keep part work interactive: a blade-to-hub union and
a full 12-blade impeller evaluate in seconds to at most a few minutes on
the reference machine, through the cached front end (`~/bin/bc`).
Any K4 path slower than that is not done.

## 3. Exit

A corpus of freeform-versus-analytic and freeform-versus-freeform cases
(blade on hub, filleted handle, hull through bulkhead, two lofted
bodies) passes the volume identity |A u B| + |A n B| = |A| + |B| to
certified bounds, the B-rep checker, STEP round trip and replay; every
earlier gate stays green; the G5 impeller and turbine build within the
speed bound above.
