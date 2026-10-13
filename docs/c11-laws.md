# C11 laws: what the kernel proves about queries

C11 proves 65 laws over the production query paths (`dist`, `extrema`,
`mass`, `section`, `interf`, `clearance`, `wall`, `classify`, `check`,
`geom intersect`). Every law quantifies over its inputs, lives in
`laws/c11/LAWS.bend`, and is proven in `laws/c11/PROOF.bend` through
reduction plus one induction (`ak_ids_len`). All 65 pass both
`--check-only` and `--verdict`. Twelve planted mutants (one per family
plus one for the inside-order fix) are all killed.

## Families

1. Box constructors (8 laws). `ab_mk` keeps its six fields and `ab_of3`
   keeps interval endpoints. Killed mutant: `ab_mk` swaps `x0`/`x1`.
2. Hull and duality (5 laws). Hull takes coordinate-wise extrema,
   overlap is the negation of disjoint, and BVH nodes and leaves report
   their boxes. Killed mutant: `ab_overlap` drops the negation.
3. Bound values (3 laws). `bv_mk` keeps its bounds and status code.
   Killed mutant: `bv_mk` swaps its bounds.
4. Refusal closure (12 laws). Every query entry point maps a failed node
   to its nothing-measured refusal, the depth and finiteness guards
   map a false check to the exact `invalid-input` refusal, and the
   interference witness stays silent without overlap. Killed mutants:
   `dist_s` rewords its refusal, and `wit_go` fires without overlap.
5. Verdict constructors (15 laws). Each certified verdict is produced by
   exactly one constructor branch: disjoint and inside relations for both
   sides, inside and boundary distances, empty walls, outside and nested
   cavities, the incomplete-mass report, the missing-descriptor
   section record, and the subdivision-witness interference line with
   its pass-through fallback. Killed mutants: `rel_pair_go` rewords
   disjoint, the inside-a verdict names the wrong side, and `wit_line`
   rewords the witness verdict.
6. Summary counts (11 laws). Report counters agree with their inputs:
   empty summaries count zero, hit codes classify, accumulator and
   concatenation add counts, and branch tallies match list lengths.
   Killed mutant: `cnt` counts one on the empty list.
7. Index validity (7 laws). Identifiers survive extraction with length
   preserved, membership and sharing are empty on empty input,
   subdivision at depth zero is the identity, and face-descriptor lookup
   by handle falls back to the body box. Killed mutant: `n_mem` claims
   membership in the empty list.
8. Parse and plane refusal (3 laws). A parsed depth keeps its digits, a
   missing plane refuses, and a missing descriptor degrades the face it
   belongs to. Killed mutant: `mass_dn` maps every input to 99.
9. Witness short-circuit (1 law). A found witness survives the rest of
   the batch list untouched. Killed mutant: `wit_batches` drops a
   found witness.

## What is not proven

Floats are axiomatic in proofs, so the laws state shapes, codes,
counts, and refusal and verdict dispatch — never that a floating-point
bound is correct. The numeric claims rest on construction plus evidence:

- Certified lower bounds are built from outward-rounded interval
  arithmetic (`ab_lo`, `ab_ab_lo`) over conservative face boxes, and are
  labelled certified only when every face carries an ok descriptor that
  covers every face. Pins check the arithmetic on fixed inputs; E2E
  journeys check agreement with analytic distances, areas, volumes,
  centroids, and inertia on boxes, cylinders, spheres, slabs, and cones.
- BVH pruning soundness (a pruned subtree holds no overlapping box)
  follows from hull containment; journeys check that every certified
  disjoint and inside verdict agrees with analytic fixtures.
- Mass containment (volume, centroid, inertia intervals contain the true
  integrals) follows from conservative cell classification and full
  coordinate-range moment hulls on uncertain cells; journeys check
  containment plus tightening with depth, and translation invariance
  of centroidal inertia on a moved box.
- Witness soundness (a point strictly inside both solids is
  interference; containment suppresses the witness) follows from
  construction; journeys check certified interference on overlap and
  cavity pairs and certified inside on containment pairs.
- Section agreement follows from the C07 solver plus honest status;
  journeys check circle samples against analytic radii and check that
  unresolved faces report estimated with their boxes listed.

Five semantic bugs died during C11, each with the law, pin, or journey
the old behavior fails: the `inside` verdicts sat behind the
`interference` branch and could never fire (new laws `rel_vb_ainb`
and `rel_vb_bina` fail on the old order); the inertia tensor assembly
ran in reverse (new `mmul`/`mmult` pins fail on the old order);
uncertain mass cells carried midpoint moments that miss the empty
subset and off-center subsets (the `mass.cylinder` journey fails on
the old sums); the octree briefly ran in the world frame against
local-frame faces (the `mass.moved_invariance` journey fails on the
old root); and the first witness search fired on containment (the
`interf.inside_a`/`inside_b` journeys fail on the ungated search).
