# C08 governing laws — regularized B-rep booleans

Status: binding on all C08 work. These laws govern the C08
implementation, its machine-checked laws (`laws/c08.bend`,
`laws/c08_build.bend`), and its closeout. They are ordered; where
two laws appear to conflict, the earlier one wins. Changing a law
to make a failing implementation pass requires explicit owner
review (MASTER_PLAN §11). Closeout qualifications that need that
review (D1 NURBS deferral, D3 non-crossing scope, the L9/L2
contact-validation reading) are recorded in
`docs/c08-intent.md` §13, not in the law text below.

Scope authority: MASTER_PLAN §10 C08. Method authority: A2 proof
layers, §14 agent properties, §15 speed law, AGENTS.md boundaries.

## Regularization and validity

- **L1 (regularized operators).** The three operators are the
  regularized set operators on closed solids: `union(A,B) = reg(A ∪
  B)`, `difference(A,B) = reg(A − B)`, `intersection(A,B) = reg(A ∩
  B)`, where `reg(X) = closure(interior(X))`. Dangling faces, flap
  edges, spur vertices and isolated lower-dimensional debris are
  never published; what regularization drops is reported, not
  silently discarded (§14.4).
- **L2 (valid output, always).** Every published result passes C04
  `brep_checked` on the manifold-solid profile AND C07 `check`
  (embedding, orientation, cavities) before publication. A boolean
  that cannot produce a fully validated result fails; it never
  publishes a best-effort B-rep.
- **L3 (no partial publish).** Failure at any pipeline stage leaves
  the accepted design unchanged (MASTER_PLAN §8, AGENTS.md). No
  partial splits, half-classified fragments, or unoriented shells
  escape the operation.
- **L4 (uncertainty is failure).** Any unresolved C07 box on the
  result boundary, any `uncertain` classification of a kept or
  dropped fragment, or any unclassifiable coincidence decides the
  whole operation as `numerical-uncertainty`. Uncertainty never
  resolves by vote, by epsilon snap, or by dropping the fragment.

## Honesty about domain

- **L5 (admitted domain is explicit).** C08 publishes a positive list
  of surface/curve arms it consumes (drawn from what C07 can both
  intersect and classify). An operand face outside that list rejects
  the operation as `unsupported-op` naming the faces — never as a
  wrong solid, never by approximating the face.
- **L6 (no borrowed kernel).** Splitting, classification, assembly
  and orientation are Bend code in this repo. OCCT/FreeCAD are test
  oracles only. No voxel or mesh substitute satisfies any C08
  milestone (AGENTS.md).
- **L7 (empty is success).** A legitimately empty regularized result
  (paradigmatically disjoint `intersection`) publishes as an empty
  compound with zero solids and a measured effect — it is not an
  error, and it is not the same as evaluation failure (§8).

## Degenerate and coincident geometry

- **L8 (coincidence is classified, not snapped).** Coplanar and
  coincident faces, tangent contact, shared patches and overlapping
  edges are decided by exact/coincident-aware classification with
  explicit tie-break rules per operator (same-normal vs
  opposite-normal coincidence), pinned by closed laws. No tolerance
  snap merges or separates surfaces.
- **L9 (contact is not fusion).** Solids meeting only in a point,
  a curve, or a patch of zero volume keep one solid per
  volume-connected component in the published compound; contact never
  fuses components and never produces a non-manifold "solid".
- **L10 (thin is reported).** Thin but positive-volume features
  publish with their certified thickness where computable; features
  below certifiable resolution fail as `numerical-uncertainty` with
  the offending fragments named. Nothing thin is silently healed or
  silently dropped.

## Lineage, selectors, intent

- **L11 (complete lineage).** Every published face, edge and vertex
  records its provenance: created (from an intersection curve),
  modified (a classified fragment of an input entity, one-to-many),
  or carried (unmodified input entity); merges record many-to-one.
  Deleted input entities are listed as deleted. Lineage is derived
  from the run, never reconstructed by position matching.
- **L12 (selectors never guess).** A durable selector resolves to
  exactly one entity, to an explicitly intended set, or fails loudly
  as missing/ambiguous. It never silently chooses a nearby face
  (MASTER_PLAN §10 C08, §14.3).
- **L13 (checked intent).** Every boolean node carries declared
  intent; the kernel measures the effect from the result (material
  change, faces created/modified, solids, genus) and rejects on
  mismatch (§14.4). The empty intersection's measured effect is
  `(same 0 0 0 0)`-class with zero solids, and the gate accepts a
  matching declaration.
- **L14 (determinism).** Same inputs, same operation, same pin:
  bit-identical B-rep, lineage and measures on every lane. No
  addresses, no ordinals, no wall-clock, no iteration-order leaks in
  persistent identity (§14.5).

## Speed and scale

- **L15 (budgets are gates).** The intent's complexity and latency
  budgets are closeout gates. A performance regression blocks the
  packet like a failing law (§15). Receipts carry scaling curves and
  parallel speedup on the thread lane.
- **L16 (parallel by construction).** Pairwise intersection,
  fragment classification and per-pair checks map over independent
  work with tree reductions; no `nth`-in-a-loop, no sequential fold
  where a tree exists (AGENTS.md, §15).

## Proof and qualification

- **L17 (A2 layers).** Closeout qualifies under Amendment A2: Layer
  A semantic laws (regularization predicate, selection tables, no
  exit fixture referenced), Layer B closed implementation theorems,
  Layer C stage-isolated fixtures (each negative fails exactly one
  stage), Layer D independent evidence — recorded in the exit
  receipt matrix.
- **L18 (discriminating laws).** Every semantic fix ships a closed
  law the old behavior fails, demonstrated against the predecessor
  (AGENTS.md). Floats pinned by `F64.bits`, never `F64.show`.
- **L19 (full check).** Closeout checks every law file in full on
  the pinned `bend` (`laws/c00.bend` … `laws/c08.bend`), with the
  sha256 of law and source bytes recorded at launch (AGENTS.md).
- **L20 (volume identities).** Certified volume intervals obey
  `V(A∪B) + V(A∩B) = V(A) + V(B)` (interval containment) on every
  E2E case, and each result's closed-form volume lies inside its
  interval. A violated identity fails the run, not the tolerance.

