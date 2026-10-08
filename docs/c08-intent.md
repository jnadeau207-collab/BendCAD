# C08 intent — general B-rep booleans

Status: implemented (this packet; contract review pending). `src/c08/`
exists; this file defined what C08 must deliver and now also records
what the packet decided and deferred (§13). At closeout it is confirmed
(or corrected by review) into `docs/c08-contract.md`. Binding laws:
`docs/c08-laws.md` (L1–L20).

MASTER_PLAN §10 C08 (verbatim): "Implement regularized union,
difference, and intersection: intersect, split edges/faces, classify
fragments, assemble boundaries, orient shells, validate, and
publish. Handle disjoint solids, containment, coplanar/coincident
faces, tangent contact, thin features, cavities, and legitimate
empty results. Record created/modified/deleted and
one-to-many/many-to-one topology lineage. A durable selector
resolves uniquely, resolves an intended set, or reports
missing/ambiguous; it does not silently choose a nearby face. Exit:
analytic and NURBS cases pass independent geometry checks, volume
identities, repeated edits, and serialization replay. Voxel booleans
are not substituted for this milestone."

## 1. What C08 delivers

Three regularized boolean operators over validated solids, as
content-keyed design-graph ops with measured intent, durable
lineage, and diagnoses:

- `(union A B)`, `(difference A B)`, `(intersection A B)` in the
  design language, where `A` and `B` are earlier nodes evaluating to
  solids (C06 bodies, revolved bodies, moved/rotated bodies, or
  earlier boolean results).
- A pipeline — broad-phase, intersect, split, classify, assemble,
  orient, validate, publish — written in Bend, consuming C07
  intersections (`inter_ss`, `inter_cs`, `inter_cc`), C07 membership
  and classification (`mem`, `sol`), and C04 `brep_checked`, with
  C07 `check` run on every published result.
- Results as compounds of zero or more validated manifold solids
  (§5), certified measures, lineage (§6), and selector resolution
  (§6) through the existing CLI/MCP surface (§4).

C08 closes the C06 limit "booleans between solids" and the C07
limit "booleans that will call `check` on every result".

## 2. Pipeline and stage contracts

Stages run in order; each stage either delivers its postcondition
or fails the operation with a named diagnosis. First-match-wins
diagnosis order follows the stage order (A2 Layer C isolation).

1. **Admit.** Both operands evaluated and valid; every face in the
   admitted domain (§3). Else `unsupported-op` naming the operand,
   node and faces.
2. **Broad-phase.** Sweep-and-prune over face/edge boxes
   (`O((E+F) log(E+F) + k)` candidate pairs, as in C07 `check`).
   Disjoint boxes short-circuit: disjoint union publishes both
   solids carried; disjoint difference publishes A carried;
   disjoint intersection publishes the empty compound. The
   short-circuit is proven by the box test, and the receipt shows
   the boxes.
3. **Intersect.** All face/face, edge/face and edge/edge
   intersections between operands via C07, plus coincidence
   classification (`coin_of`-class: disjoint, touching,
   coincident-same-normal, coincident-opposite-normal). Any
   unresolved box that can touch the result boundary fails as
   `numerical-uncertainty` (L4); purely interior-to-a-face
   uncertainty that classification proves immaterial is reported
   in the regularization report, never silently dropped.
4. **Split.** Edges split at intersection vertices, faces split
   along intersection curves into fragments. Postcondition: every
   fragment is strictly inside, strictly outside, or coincident
   with the other operand — no fragment straddles the other
   operand's boundary. Straddlers that cannot be split fail as
   `numerical-uncertainty`.
5. **Classify.** Each fragment against the other operand (C07
   membership + classification): `in`, `out`, `on-same`,
   `on-opposite`, `uncertain`. `uncertain` on any fragment fails
   the operation (L4). Coincident tie-breaks are per-operator
   constant tables (§5), pinned by Layer A laws.
6. **Select + assemble.** Keep fragments per the operator's
   selection table, stitch kept fragments into shells along split
   edges (split-edge pairing is exact: each intersection curve
   contributes two opposite uses, one per side), drop what
   regularization forbids (dangling, flaps, spurs) into the
   regularization report (L1). Assembly that cannot close fails
   as `numerical-uncertainty`, never as a patched solid.
7. **Orient + shells.** Shells oriented outward (C07 orientation),
   cavities nested and classified (inside outer, outside each
   other), volume-connected components separated into one solid
   each (L9). Contact-only components stay separate solids in one
   compound.
8. **Validate.** C04 `brep_checked` (manifold-solid profile) then
   C07 `check` (embedding, orientation, cavities) on the assembled
   compound. Any rejection fails the operation naming the stage
   and entities (L2).
9. **Publish.** Certified measures, lineage (§6), effect
   measurement and the intent gate (§7), cache-keyed result (§4).
   Atomic with the rest of evaluation: failure leaves the design
   unchanged (L3).

## 3. Admitted domain

Positive list at closeout; the current floor the implementation
must at least admit:

- Faces: planes, cylinders, cones, spheres, tori (the C07 implicit
  arms) and flat bicubic walls as emitted by `build.bend`
  (decision D2 below covers how).
- Edges: lines, circles/arcs, conics, cubic Béziers, rational
  quadratics — every arm C07 `curve_spans` converts exactly.
- Operands: any evaluated node whose B-rep is valid under C04 +
  C07 `check`, including placed (`move`/`rotate`) bodies and
  earlier boolean results. Cavities admitted; open shells refused
  (`unsupported-op`: booleans are closed-solid operators).

Out of domain (refused, named, never approximated):

- Bézier-patch and NURBS faces while C07 membership answers
  `uncertain` on them (C07 contract §11), except per D1/D2.
- Operands that fail C07 `check`, or whose classification is
  `uncertain` anywhere the boolean needs it.

**D1 (owner/implementer decision): NURBS vs the exit sentence.**
The plan's exit says "analytic and NURBS cases pass". C07 leaves
NURBS membership to C11 ("with freeform trims"). Either C08
extends membership to NURBS faces (preferred if it fits the
packet; it is the only missing piece, since NURBS intersection
is supported), or the packet ships analytic-only and the exit
sentence needs an amendment deferring NURBS booleans to C11.
Decide before stage 4 is built; do not silently narrow the exit.

**D2 (implementer decision): flat bicubic walls.** `build.bend`
emits exactly-planar slanted walls as bicubic patches, which C07
membership cannot certify. Either extend `mem.bend` with an exact
flat-patch → planar reduction, or change the builder to emit
plane faces for exactly-planar walls (a C08-owned fix to an
earlier packet, C07 §8 precedent, with a discriminating law).
General prisms with slanted lines must boolean; the packet may
not admit only axis-parallel prisms.

## 4. Operators, syntax, surface

Model (extends `src/c06/model.bend` `Op`, following its
numbered-key convention with fresh tags):

- `O_union{a, b}`, `O_difference{a, b}`, `O_intersection{a, b}`
  with `a, b : U64` node ids, both strictly earlier nodes.
- Two-input cache keys: the op tag plus both inputs' full keys
  (L14; no hash trust, C06 §8 precedent). A failed or missing
  input fails dependents as `input-node-missing-or-failed`.
- Empty compound is a first-class value: zero solids, certified
  zero volume, lineage recording the emptiness (which operator,
  which inputs). Downstream: `union(empty, X)` publishes X
  carried; `difference(empty, X)` and `intersection(empty, X)`
  publish empty; features (`pad`/`pocket`/`holes`) on an empty
  compound reject as `invalid-input` naming the empty node.

Design syntax (extends `tools/mcp/language.md`):

```text
(union A B) | (difference A B) | (intersection A B)
```

with `(intent MATERIAL FACES_CREATED FACES_MODIFIED SOLIDS
THROUGH_HOLES)` as for every op (§7).

CLI/MCP: `faces`, `measure`, `sens`, `zone`, `tess`, `classify`
and `check` work on boolean nodes unchanged. `zone` over boolean
nodes requires the C07 topology-constancy certificate extended
across the boolean boundary (parameters must keep every kept /
dropped classification strict); where that does not certify,
`zone` answers `topology-not-certified-over-zone`. MCP gains no
new tool except through the existing `apply` op set; `reference`
documents the three ops.

## 5. Edge-case catalog (all must be specified, tested, receipted)

- **Disjoint:** union carries both; difference carries A;
  intersection publishes empty (L7). Proven by broad-phase boxes.
- **Containment:** A strictly inside B (and reverse) for all three
  operators, certified by classification, including touching-from-
  inside (kissing interior wall).
- **Coplanar/coincident:** face-on-face overlap (partial and
  full), same-normal and opposite-normal; box-on-box with shared
  face; cylinder-in-cylindrical-hole line contact. Selection per
  the operator tie-break table; coincident classification is
  exact-aware, never snapped (L8).
- **Tangent contact:** kissing spheres, sphere on plane, tangent
  cylinders; union publishes two solids in one compound (L9);
  intersection publishes empty (regularized: contact has no
  interior); difference publishes A carried.
- **Edge/vertex contact:** boxes sharing an edge or a vertex only;
  same multi-solid/empty/carried outcomes as tangent contact.
- **Thin features:** thin wall kept by union, thin fin surviving
  difference, near-coincident parallel faces. Published with
  certified thickness where computable; below certifiable
  resolution the operation fails naming the fragments (L10).
- **Cavities:** booleans that create cavities (enclosed void),
  destroy cavities (drilling into one), merge cavities, and meet
  existing cavities; cavity shells validated per C07 nesting.
- **Multi-region operands:** operands with several solids/islands
  (C06 multi-region prisms) on either side; pairwise fragment
  bookkeeping stays exact across components.
- **Self-touching results:** results that touch themselves at a
  vertex or along an edge after assembly split into separate
  solids; a result that would be non-manifold as one solid is
  never published as one solid (L9).
- **Repeated/degenerate input:** `union(A, A)`, `difference(A,
  A)` (empty), `intersection(A, A)` (A carried); difference that
  removes everything (empty); intersection equal to one operand
  (carried, with lineage saying so).
- **Placed operands:** booleans across `move`/`rotate` placements,
  including general-angle rotations with interval placements;
  classification consumes the certified placement, not the
  display midpoint.
- **Parameter edits:** boolean nodes rebuild incrementally on
  parameter change with full-key cache reuse; edits that flip any
  classification rebuild (no stale topology), and `sens` refuses
  across a topology change (C06 §9 precedent).

## 6. Lineage and selectors

Lineage (L11) is a per-result record, derived from the run:

- Each published entity: `created` (from which intersection
  curve(s) and which input faces), `fragment-of` (input entity +
  fragment index: the one-to-many arm), `carried` (input entity,
  unmodified), or `merged` (input entities fused: many-to-one).
- Each consumed input entity not surviving: `deleted` with the
  reason (classified away, regularized away with the report
  entry, merged).
- Fragments keep the input entity's lineage prefix extended by
  the boolean node id, so names stay lineage-by-meaning (§14.3),
  never positional.

Selectors (L12): the existing `(face NODE CELL top|bottom)` form
keeps working for C06 nodes. C08 adds a lineage selector that
addresses boolean-result entities by (node, provenance): it
resolves to one entity, to an explicitly intended set (documented
set semantics, e.g. all fragments of one input face), or fails as
`missing`/`ambiguous` with candidates listed. Resolution is a
pure function of stored lineage; no geometric search, no nearest
match. Features (`pad`/`pocket`/`holes`) and later packets
address boolean faces through these selectors — C08 must also
lift the C06 `features-need-an-extruded-body` refusal where the
result face is planar and the feature machinery applies, or
refuse with a C08-specific reason (decide at closeout; document
either way).

## 7. Intent gate and failure taxonomy

Intent (L13) reuses the C06 five-field form. Measurement, from
the result only:

- MATERIAL: `create` for a first-solid boolean over fresh
  operands is wrong — booleans combine existing solids, so the
  vocabulary is `add` (union growing volume), `remove`
  (difference shrinking it), `same` (carried/empty outcomes),
  measured by certified volume-interval comparison of inputs vs
  result. Intersection that keeps a strict part of both inputs
  measures `remove` relative to each input; the gate compares
  against the union of inputs. Exact comparison rules are Layer A
  laws.
- FACES_CREATED / FACES_MODIFIED from lineage counts; SOLIDS from
  the published compound; THROUGH_HOLES (genus) from the B-rep.

Failure kinds reuse C00 `FailKind`; every failure carries what,
where (durable names), why (machine-readable), and the smallest
known fix (C05 diagnosis template, §14.2):

- `invalid-input`: bad node refs, open-shell operand, feature on
  an empty compound, intent mismatch (with declared vs measured).
- `unsupported-op`: out-of-domain face (names it), NURBS operand
  if D1 defers, unresolved-but-structurally-excluded cases.
- `numerical-uncertainty`: unresolved intersection boxes on the
  boundary, `uncertain` fragment classification, unclosable
  assembly, failed C04/C07 validation of the candidate, zone
  topology not certified.
- `resource-exhausted`: budget/fuel genuinely out (never a
  mislabeled all-pass; R0.4 precedent). Fuel-out returns
  incomplete, never a false verdict (§8).

## 8. Complexity and latency budgets (closeout gates, L15)

- Broad-phase: `O((E+F) log(E+F) + k)` candidate pairs (C07
  `check` precedent); pairwise intersection and classification
  parallel over pairs/fragments (L16).
- Budgets (native, this machine class; receipt re-measures):
  small (≤ 20 faces per operand, analytic): < 1 s single-thread;
  medium (bracket-class, ≤ 200 faces per operand): < 10 s
  single-thread, < 5 s on 16 threads with measured speedup;
  scaling suite to a 1,600-hole plate differenced against a box,
  with a scaling curve, not just a pass.
- Tessellation of boolean results reuses C10-bound machinery
  (C06 display tessellator until C10); tessellation cost is
  reported separately from boolean cost.

## 9. Non-goals

- Fillets, chamfers, sweeps, lofts, offsets, shells, patterns:
  C09. (C08 delivers the boolean substrate they build on.)
- Manufacturing-grade tessellation bounds: C10. General queries
  (closest point, clearance, exact interference): C11.
- NURBS booleans if D1 defers them (then a named C11 item, by
  amendment — not silent).
- Assemblies, PMI/GD&T, interchange, release qualification:
  C14/C15/C12/C13.
- Partial revolution, features on revolved bodies beyond §6's
  selector-lifting decision: stays refused with reasons.
- Any mesh/voxel path, any OCCT/FreeCAD runtime call, any
  tolerance snap: forbidden (L5, L6, L8).

## 10. Acceptance criteria (exit)

1. All three operators publish validated results (§2.8) across
   the §5 catalog, analytic at minimum, NURBS per D1.
2. Volume identities hold on every E2E case (L20); closed-form
   volumes inside certified intervals.
3. Lineage complete on every published result (L11); selectors
   resolve/miss per L12 with no silent choice; serialization
   replay reproduces lineage and measures bit-identically.
4. Repeated edits rebuild incrementally (cache reuse pinned by a
   law, C06 `cache_partial` precedent); no stale topology after
   a classification flip.
5. Every failure kind in §7 demonstrated by a failing-then-fixed
   journey (diagnosis → repair → green), with file-unchanged
   atomicity on rejection (C06 E2E precedent).
6. A2 exit receipt matrix complete: every row PASS with closed
   law witness + green runtime witness; Layer C isolation shown
   per negative fixture.
7. Budgets in §8 met with scaling curves and 16-thread speedup
   in the receipt; every law file checked in full on the pin
   (L19); independent checks (§11) green.

## 11. Test plan

- **Laws.** `laws/c08.bend`: Layer A semantic laws (regularized
  selection tables, tie-breaks, intent comparison, empty/compound
  semantics, lineage well-formedness) on micro-stores, plus fast
  Layer B verdict laws. `laws/c08_build.bend`: one law per full
  boolean evaluation (parse → boolean → C04 + C07 validation →
  measures → lineage), checked one-per-process in parallel, C06/C07
  `_build` precedent. Floats by `F64.bits`.
- **E2E.** `tests/c08/e2e.py` → `tests/c08/e2e-report.json`,
  following the `tests/c07/e2e.py` + `solid.py` + `zone.py`
  pattern: one journey per §5 bullet with analytic volume
  oracles, plus edit/replay journeys and atomic-rejection
  journeys. New oracles beside it: a volume-identity checker and
  a lineage/selector checker; reuse `tools/grade/mesh.py` for
  tessellated results.
- **Differential.** Random analytic-operand fuzz vs the OCCT
  oracle harness (`tools/oracle/`, C07 precedent): volume
  agreement within certified intervals, 0 unexplained
  mismatches; seeds and mismatch policy in the receipt. OCCT is
  a comparator, never truth (§9 of the plan).
- **Negative suite.** One composed B-rep journey per §7 failure
  kind (C07 `solid_neg.py` precedent: 13 compositions), each
  failing exactly one stage (§2 order) with the diagnosis
  asserted verbatim.
- **Lanes.** Three-lane byte-identity where the harness supports
  it (C05 precedent); thread-lane speedup measured for the §8
  medium case. `--verdict` unavailable for F64 laws (AGENTS.md);
  report `--check-only` evidence.
- **Ledger.** `docs/replacement-ledger.md` gains the C08 rows
  (operation, mined source or "none mined", Bend implementation,
  laws, fixtures, limits) at closeout.

## 12. Suggested build order (not a contract)

1. Admit + broad-phase + operand plumbing (two-input nodes, cache
   keys, empty compound value, short-circuits) with E2E.
2. Intersect + split on planes/boxes, then cylinders/spheres;
   coincidence classification.
3. Classify + select + assemble + orient; regularization report.
4. Validate wiring (C04 + C07 `check`), measures, lineage,
   selectors, intent gate.
5. Coplanar/tangent/thin/cavity hardening (§5), D1/D2 closure.
6. Laws (A then B), fuzz oracle, negative suite, budgets, A2
   matrix, receipt.

## 13. Packet record — decisions, scope, and deferrals

This section is the implementation record. Items marked
**owner review** change or narrow the sections above and need explicit
review before closeout qualifies (laws doc preamble, MASTER_PLAN §11).

**D1: NURBS deferred (owner review).** NURBS operands are refused as
`nurbs-operand` (`surf_admit_nb`, law-pinned). C07 membership answers
`uncertain` on NURBS faces, so no boolean over them can certify
classification; extending membership is C11 freeform-trims work. The
§10 exit sentence "analytic and NURBS cases pass" is NOT met for
NURBS; it needs the amendment this section anticipated, deferring
NURBS booleans to C11. Until amended, the packet ships analytic-only.

**D2: closed.** Flat bicubic walls reduce to planes exactly in
`gv_im` (`src/c07/xs.bend`, expansion-arithmetic normal), pinned by
discriminating laws (`d2_flat_patch_admitted`,
`d2_curved_patch_refused` in `laws/c08.bend`: the old behavior fails
the first). General prisms boolean.

**D3: non-crossing scope (owner review).** This packet implements
every stage for operand pairs whose boundaries do not cross:
disjoint, contained, contact-only, identical, and empty algebra.
Crossing or overlapping boundaries fail as
`boundaries-cross-or-overlap` (unsupported-op): fusing them needs
face splitting and shell assembly, which this packet does not
implement. Consequences against the sections above:
- §2 stages 3–6 run in full for admitted pairs; split is a certified
  no-op past the intersect stage (the intersect validation proves no
  straddlers exist). Crossing pairs fail at stage 3, first-match-wins.
- §5: disjoint, containment carry outcomes, repeated/degenerate
  input, and translated operands are implemented and E2E-observed;
  coplanar/coincident contact, tangent contact, edge/vertex
  contact, cavity creation, and rotated operands are implemented
  with E2E journeys committed in `tests/c08/e2e.py` (observed
  green in `tests/c08/e2e-report.json`; re-confirm at closeout
  after the finding fixes land). Destroying, merging, or meeting existing
  cavities needs crossing fusion and is refused. Thin features
  publish as ordinary contact/disjoint outcomes *without*
  certified thickness (L10's thickness certificate is not
  computed — a gap, not a silent heal). Touching-from-inside
  containment and cylinder-in-hole line contact run through the
  contact path; dedicated touching-from-inside E2E is committed
  (`kiss_inside`), cylinder-in-hole line contact E2E is still
  pending. Self-touching assembly cannot occur without splitting
  (nothing is ever fused), so L9's splitting rule is vacuous in
  this scope. Parameter edits reuse full-key cache entries;
  `sens` refuses across topology change via the lineage
  comparison (C06 precedent).
- §10 item 1 is met for the §5 rows above, not for crossing
  fusion; item 7 (budgets, fuzz oracle, scaling curves) is not
  run in this packet beyond the E2E timings in
  `tests/c08/e2e-report.json`.

**D4: features on boolean results refuse (C08 reason).** Per §6's
either-way clause, `pad`/`pocket`/`holes` on a C08-assembled result
(or a carry of one) refuse as `feature-on-boolean-result`
(`invalid-input`): assembled bodies carry operand-frame cells
against a world-frame B-rep, so the feature machinery cannot apply
soundly. Carries of never-booleaned bodies keep working (their
cells are consistent). Lifting features onto boolean results via
the lineage selectors is deferred to the selector-lifting item.

**Selectors (§6): resolution done, wiring deferred (owner review).**
`resolve` in `src/c08/bool.bend` is the pure lineage selector L12
requires (one entity, intended set, or loud missing/ambiguous —
never a silent choice), pinned by laws (`resolve_*`). It is not
wired to any CLI/MCP surface in this packet, so L12's
resolve/miss surface is not operator-reachable; that wiring rides
with the D4 selector-lifting item, because the selector syntax,
the `reference` documentation, and the feature-lifting semantics
are one design unit and must not ship piecemeal. `faces` lists
result lineage words today (`-v` adds deleted-with-reason), and
both lineage renderings print created faces identically
(`n4.cav.k.i.j` in `fn_s` and `fn_show`, pinned two-sided by law
`fn_show_created_role` and the `containment.cavity` E2E
expectation — F13 rendering half closed).

**Intent gate scoping (L13).** Carried and empty outcomes measure
`same` (republished unchanged / the doc-pinned empty class). The
§7 sentence "intersection that keeps a strict part of both inputs
measures `remove`" governs crossing fusion, which is out of scope
(D3); in this scope every intersection outcome is a carry or empty.
Assembled union measures `add`, contained difference `remove`.

**L9/L2 qualification (owner review).** Contact-only compounds
publish per L9, but strict L2 demands unmodified C04
`brep_checked`: contact compounds cannot pass C04's coincidence
stage as written (shared-patch vertices coincide by design), so
validation runs C04 minus `coin_c`, plus a contact-aware
coincidence check (per-solid exact duplicates fail; inter-solid
touch is admitted), plus C07 orientation/nesting, plus the
contact-aware `emb_fi` (cross-solid overlap reports `contact-*`
instead of failing; transverse crossings and all uncertain or
unsupported findings still fail). The `contact-*` codes are
information, admitted by both the kernel gate and CLI `check`.
This reading needs owner review at closeout.


