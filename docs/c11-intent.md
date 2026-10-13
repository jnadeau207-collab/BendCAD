# C11 intent: queries, mass properties, and acceleration

C11 is the packet where BendCAD stops being a modeller that also
measures and becomes a modeller an agent can interrogate: distance,
extrema, mass properties, planar sections, interference, clearance,
minimum wall, classification, embedding check, and curve/surface
intersection report through one honest status vocabulary over two
surfaces (CLI verbs and MCP tools) with identical text.

## 1. Goal and non-goals

Goal: every query in MASTER_PLAN §10 C11, each answer labelled
certified, estimated, or incomplete/assumed, each refusal named with a
reason and a fix, each verdict agreeing with analytic fixtures where a
fixture exists, all behind acceleration structures (Morton BVH,
vectorized cells, pruned scans) fast enough to hold the latency budgets
in §7.

Non-goals: exact telling of section topology (the C07 tracer owns curve
topology; C11 reports its curves and its unresolved boxes honestly);
exact minimum wall on curved adjacencies (the method is separately
qualified in §5, curved pairs stay estimated); meshing and toolpath.

## 2. Agent contract

Query verbs never modify the design and never write files. Every verb
reads `design node ...` and prints one report. The report starts with
the answer, states its status, and when the status is not certified
says what is missing (unresolved boxes with a hull, incomplete cells,
boxes-uncertain, plane=mapped). A failed node publishes no geometry:
each verb has its own nothing-measured sentence.

```sh
bendcad d.bcd dist 1 15 5 5
bendcad d.bcd extrema 1
bendcad d.bcd mass 1 4
bendcad d.bcd section 1 0 0 1 5
bendcad d.bcd interf 1 2
bendcad d.bcd clearance 1 2
bendcad d.bcd wall 1
bendcad d.bcd classify 1 5 5 5
bendcad d.bcd check 1
bendcad geom intersect '(line 0 0 0 1 0 0 -5 5)' '(line 0 0 0 0 1 0 -5 5)'
```

The MCP tools `distance`, `extrema`, `mass`, `section`,
`interference`, `clearance`, and `min_wall` run the same verbs and
return the same text.

## 3. Architecture

```
src/c11/qcert.bend    status codes, bound values, refusals, depth budget
src/c11/qaccel.bend   boxes, Morton keys, BVH, index sets, face health
src/c11/qdist.bend    dist, extrema, clearance, min-wall
src/c11/qmass.bend    octree mass properties
src/c11/qsect.bend    section + geom report lines
src/c11/qinterf.bend  classify, check, interference, cavities, placement maps
```

`qcert` is the vocabulary every report shares. `qaccel` is the only
place that allocates search structures; the queries borrow it and never
each other. `qsect` owns the report lines the C07 solver fills, for
both `section` and `geom intersect`, so the two verbs cannot drift.
`qinterf` owns the placement maps every world-space query funnels
through.

## 4. Status vocabulary

`certified` means a sound bound or an exact verdict: the true value
lies inside the printed interval, or the printed verdict follows from
checks that cannot pass on a counterexample. `estimated` means a
sampled or rounded value with a stated provenance (nearest sample,
pruned scan, midpoint plane). `incomplete`/`uncertain`/`assumed` mean
the packet knows it does not know: unresolved solver boxes, incomplete
octree cells, uncertain classifications. The ladder is one-directional:
a certified claim never depends on an estimated input. Face health
gates every certified geometric bound: a bound is certified only when
every face carries an ok descriptor and the descriptors cover every
face.

## 5. Methods

Distance reports a certified lower bound from conservative face boxes
with outward-rounded arithmetic, and an estimated upper bound from the
nearest sample. Extrema reprint the certified measures with sampled
witness vertices. Clearance reuses the relation verdict: interfering
pairs report zero, disjoint pairs report a certified box lower bound,
contained pairs report a trivial zero lower bound with an estimated
upper bound.

Minimum wall is the separately qualified method the plan demands: the
minimum runs over non-adjacent face pairs only (adjacent pairs share a
vertex, so their distance is zero by definition and would drown the
answer), faces join to descriptors by handle, pairs scan in lower-bound
order with upper-bound pruning, and the lower bound is certified only
under the face-health gate. A solid whose faces are pairwise adjacent
reports `none` with reason `all-faces-adjacent`.

Mass properties integrate over an octree of the local face-box hull
to a caller depth (default 4, hard ceiling 6). Volume comes from the
certified measures; the octree cross-checks it. Centroid and inertia
are bounded sums: inside cells contribute their exact cell moments,
uncertain cells contribute their full coordinate-range moment hulls
(each corner product included, so no containment gap), and the
centroidal tensor is shifted in the local frame before the placement
rotation carries it to world (translation invariance falls out; a
moved box shares its inertia intervals with the unmoved box). Depth
is a strict nonnegative integer; anything else refuses.

Sections solve the plane against each face through the C07 solver and
tally curves, unresolved boxes, and coincidences per face plus a
summary. Identity placements solve the requested plane; anything else
maps the plane at interval midpoints (the same map classification
uses), labels the report `plane=mapped`, and caps the status at
estimated. Planar sections of planar faces can defeat the generic
tracer along axis-degenerate lines; those faces report their unresolved
boxes with a hull instead of curves, and the summary stays estimated.
Grazing sections (a plane through face boundary edges) can exceed any
practical latency and are not journeyed; coincidence detection is
journeyed through `geom intersect` instead, which short-circuits.

Interference decides disjoint by boxes first, then runs a subdivision
witness search over the overlap box (depth 4, cell centers classified
strictly inside both solids), gated on neither body containing the
other, then falls back to the sample ladder: inside either way by
strict samples plus disjoint shells plus box containment, then
interference by a strict sample either way, then disjoint by samples,
else uncertain. Containment wins over the witness because a shared
interior point is still just containment. Contact-only pairs answer
uncertain. AABB
overlap is never confused with interference: the trap journey nests a
small box in a boolean cavity with overlapping boxes and asserts
certified disjoint. A protruding tool would need face splitting, which
C08 honestly refuses, so the trap uses a nested cavity tool. Cavities
report per cavity: inside, outside, or nesting-uncertain.

Circle sections of cylinders and spheres resolve into arc branches
with small end joints and report estimated with every sample on the
analytic circle; no full-solid certified section journey exists yet,
because at least one face stays unresolved on every solid tried.

## 6. Refusals

`invalid-input` covers non-finite coordinates, degenerate planes, and
out-of-range or non-numeric depths, each with the verb, the reason, and
the corrected syntax. A failed node maps to the verb's
nothing-measured sentence. Refusals publish no geometry and leave the
design byte-identical. Every branch is lazy: a refusal never evaluates
the pipeline it refuses (strict Boolean choice evaluates both arms, so
refusal dispatch uses `match`).

## 7. Complexity and latency

Let n be faces, m samples, and d octree depth. BVH build is
O(n log n), box queries prune to O(log n) per probe, wall scans
O(n^2) pairs with pruning, mass visits 8^d cells in parallel,
classification and section cost what the C07 solver costs on the face
count. Measured on this machine (16 cores):

- `mass` box depth 4: 4096 cells, about 0.6 s; depth 6: 262144 cells
  (see the E2E report for the packet's measured time).
- `dist`, `extrema`, `wall`, `interf`, `clearance` on single boxes:
  well under a second each.
- `section` on planar boxes: minutes per verb when the tracer
  subdivides to fuel (about 33k unresolved boxes per degenerate face);
  curved circle sections resolve in seconds.
- Full C11 E2E plus neg: see the receipt for the measured total.

## 8. Bend rules this packet learned

Callees precede callers: a forward reference fails the check with an
unfilled-definition error, so definitions read bottom-up. `match`
scrutinises a variable, never a call — name the intermediate. `match`
is the only lazy branch: `Bool.pick` evaluates both arms, so any guard
that protects an expensive or fallible pipeline must be a `match`.
Negative number literals do not exist; write `F64.neg`. Termination
reads arguments left to right: a counter that grows must sit after the
fuel that shrinks. Interval placement maps run at midpoints; any status
stronger than estimated must say so or gate on identity.

## 9. Evidence map

- `laws/c11/LAWS.bend`, `laws/c11/PROOF.bend`: 61 laws over
  constructors, codes, counts, indexes, verdicts, and refusals; see
  `docs/c11-laws.md`.
- `tests/c11/pins.bend`: fixed-input pins over status codes, box
  corners, parse boundaries, matrix order, and report strings.
- `tests/c11/e2e.py`, `tests/c11/neg.py`: analytic agreement, trap and
  contact journeys, accel scaling, MCP parity, and refusal journeys.
- `docs/receipts/c11-2026-10-12.txt`: the A2 exit matrix with measured
  evidence.

## 10. Deferrals

- Exact planar-section lines: axis-degenerate plane/face pairs report
  estimated with unresolved boxes. An exact interval line-plus-clip
  path would certify them; it is not built.
- Tighter inertia bounds: dependency widening through the mass and
  centroid intervals keeps depth-4 inertia wide; an affine or Taylor
  form would tighten it.
- Section latency on degenerate faces: the tracer subdivides to fuel
  before admitting defeat; a degeneracy pre-check would fail fast.
- Native soft-float NaN handling: some `F64` comparisons spin on NaN
  instead of returning false (toolchain bug, out of scope); C11 routes
  every untrusted float through `T.is_finite` under `match` first.

## 11. Reproduction

Rebuild the binary with the packet's two-stage recipe (single-command
build no longer fits any safe scope; see the receipt §1), then:

```sh
python3 tests/c11/e2e.py
python3 tests/c11/neg.py
bash tools/pins/run.sh tests/c11/pins.bend
bash tools/laws/check.sh /tmp/laws-c11
python3 tools/laws/mutate.py c11
```
