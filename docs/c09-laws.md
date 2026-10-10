# C09 governing laws — professional features

Status: binding on all C09 work, together with `docs/c09-intent.md`.
Where two laws appear to conflict, the earlier one wins. Changing a
law to make a failing implementation pass requires explicit owner
review (MASTER_PLAN §11).

Scope authority: MASTER_PLAN §10 C09. Method authority: A2, §14, §15,
AGENTS.md.

## Validity

- **L1 (real solids).** Every published feature is a manifold solid
  whose faces are admitted C03 surfaces, passed through C04
  `brep_checked` and C07 `check`. A fillet, chamfer, loft, sweep,
  draft, offset, shell, or pattern that cannot produce that solid
  fails. It never publishes a stand-in solid, a mesh, or a partial
  B-rep.
- **L2 (no partial publish).** Failure leaves the accepted design
  unchanged.
- **L3 (uncertainty is failure).** An interval angle, an uncertified
  placement, a boolean that cannot classify, or a validator finding
  fails the feature. Uncertainty never becomes a midpoint solid.
- **L4 (admitted domain is the positive list).** `docs/c09-intent.md`
  §2 is the positive list. Everything else refuses with the why-string
  written there.
- **L5 (no borrowed kernel).** Construction, rank, and assembly are
  Bend in this repo. OCCT is not a runtime.

## Geometry

- **L6 (volumes).** Each ordinary case contains its closed form from
  the intent inside the certified volume interval. The printed measure
  is an interval.
- **L7 (sweep fractions).** An arc sweep of 90, 180, or 270 degrees is
  that fraction of the full revolve of the same profile. 360 degrees
  is that revolve. Any other angle refuses as
  `sweep-angle-not-certified`.
- **L8 (continuity and guides).** A published loft is G0. G1 is
  published only when the tangent planes agree, which the admitted
  planar loft does not, so G1 refuses as `continuity-not-met`. A guide
  that is not the sweep path refuses as `guide-not-admitted`. A
  nonzero sweep twist refuses as `twist-not-admitted`.
- **L9 (corners and variable radius).** The all-edge box fillet
  publishes eight spherical corner faces and twelve cylindrical edge
  faces. The single-edge form publishes a cylinder when the end radii
  are equal and a cone when they differ, and it does not invent sphere
  corners. One constant-radius solid does not qualify the family.
- **L10 (topology evolution).** Chamfer of the four vertical edges of
  a box publishes 10 faces. The all-edge fillet publishes 26. The
  closed box shell publishes one solid with one cavity. Counts come
  from the B-rep, not from the intent text alone.
- **L11 (sharp offset).** Offset and thicken move faces along their
  normals and keep sharp edges. They are not rolling-ball offsets.
  Thicken is the positive direction. Offset owns the signed distance,
  including the identity at 0 and the self-intersection refusal.
- **L12 (patterns are disjoint unions).** A pattern of solids is a
  regularized union of strictly box-disjoint copies. Overlap refuses
  before the crossing intersector. Circular patterns admit only four
  copies at exact quarter-turn translations. Hole patterns are the
  existing holes evaluator at the generated centers.

## Solver

- **L13 (solve bits stay).** `solve`, `solve_go`, and `solve_cl` are
  not modified. Existing C05 bit pins keep their witnesses.
- **L14 (rigidity is rank).** A merge happens only when the existing
  rank-revealing factorization certifies the union is a rigid motion
  (dimension 3, or less where fixes remove motions). A constraint
  count is not a certificate. A path of distances stays a path of
  rigid pairs. A component the decomposer does not admit is reported
  `whole`, not forced into a cluster.
- **L15 (drag copies clean clusters).** `solve_drag` re-solves only
  dirty clusters and their constraint-neighbors. Every clean cluster's
  coordinates are bit-identical to the input.

## Evidence

- **L16 (families).** Each family in the intent has an ordinary case,
  a degenerate case, a downstream edit or replay, a bounded interval,
  and a Bend law or a build law. Missing any one of those, the family
  is not closed.
- **L17 (diagnoses are stable).** The why-strings in the intent are
  the strings the kernel returns. Tests assert them verbatim.
- **L18 (zone).** Every new feature op answers
  `topology-not-certified-over-zone`. None inherits the prism
  certificate by falling through a wildcard.
