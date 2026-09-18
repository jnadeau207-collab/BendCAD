# ADR-013: Multi-output birth — surfacing a multi-solid import as N selectable bodies

Date: 2026-07-22
Status: **accepted** 2026-07-28 (CAP-024 phase 1; delivering-session ruling
under the standing no-founder-gating law recorded in PROJECT_STATE.md). Its
three recorded residuals are settled in
`docs/design/2026-07-28-multi-output-birth-residuals.md`.

## Context

D-023 landed real geometry ingestion for imported files: `import_mesh`
(`apps/desktop/src/main/manufacturing-mesh-import.ts`) and a faithful multi-solid
STEP import (`apps/desktop/src/main/manufacturing-import.ts`) that retains the
exact Part-21 source and lets the kernel reconstruct the geometry. A STEP file
that contains several disjoint solids is ingested **faithfully** — but as a
single **compound** body. MASTER_PLAN §10.C.4 wants the next step: surface a
multi-solid import as **N separate, individually selectable document bodies**, so
the user can name, reference, transform, boolean, or delete each solid on its
own, exactly as if they had authored them.

That step is blocked not by the importer but by a contract that pervades the
whole document/kernel/selection stack: **one operation produces exactly one
body.** This ADR records why that contract cannot represent N-body birth, and
proposes a concrete design so the work can be scheduled deliberately. It does
**not** implement it.

### Where "one op → one body" is baked in

The birth contract is not a convention in one file; it is an invariant asserted
independently at five layers, each of which would silently produce wrong results
if an operation bore more than one body:

1. **The operation schema — a singular `outputBodyId`.** Every authored
   operation in `packages/geometry-contracts/src/operations.ts` (~30 variants:
   primitives, `import_step`, `import_mesh`, booleans, fillet, hole, transforms,
   shell, patterns, …) carries exactly one branded `outputBodyId: bodyIdSchema`.
   There is no vocabulary for an operation that yields more than one body.

2. **Document-wide uniqueness invariants.** `outputBodyId` is asserted unique
   across the document in two places, both of which treat "the body id of
   operation X" as a scalar:
   - parse time — `addOperationIdentityIssues` in
     `packages/document-model/src/document-schema.ts` collects one `outputBodyId`
     per operation into a `Set` and flags duplicates;
   - live-commit time — `assertUniqueOutputIds` in
     `packages/document-model/src/document.ts` (its `outputBodyIdOf` helper reads
     the single `"outputBodyId" in operation` field). The comment is explicit: a
     duplicate "silently collapses two bodies in the viewport, so it can never
     become committed history."

3. **Topology reference tokens are operation-scoped.** A persisted reference
   (`packages/geometry-contracts/src/refs.ts`) resolves an AQL query to a
   topology token of the form **`t:<opId>/<role>/<ordinal>`**. The element's
   identity is keyed by the **operation** that bore it plus a role and an ordinal
   into that operation's enumeration. Today `<opId>` unambiguously names one
   body, so `t:<opId>/face/3` is a single face. If one operation bore N bodies,
   the token space collapses: the ordinal enumeration would span all N solids'
   faces, and `t:<opId>/face/3` would name a face whose owning body is undefined.
   Every downstream ref (fillet edges, boolean operands via `operation-ref-slots.ts`,
   datum planes, mirror planes) inherits this ambiguity.

4. **Lineage element names share that enumeration.** The integration-tranche
   naming work (N0–N5) mints per-element names (`elementNames` in the evaluation
   result, `packages/geometry-contracts/src/kernel-protocol.ts`) "correlated by
   token through the same enumeration that mints the topology snapshot's tokens."
   Names are therefore per-`opId`, not per-body; N-body birth has no place to
   hang N distinct naming scopes.

5. **The kernel evaluation contract keys bodies 1:1 to operations — and refuses
   fan-out.** The `evaluation` result's `bodies` array
   (`kernel-protocol.ts`) is documented as "one entry per BODY-PRODUCING
   operation," each entry `{ bodyId, operationId, … }` where `bodyId` is that
   op's `outputBodyId`. Its `superRefine` rejects a duplicate `bodyId` **and**
   validates the `operationId` correspondence. Crucially, the boolean path
   states that a result "that would produce several disjoint solids fails the
   request with `GEOMETRY_FAILED`" — the kernel is currently **contractually
   forbidden** from emitting more than one body for one operation. So even the
   compound STEP import is deliberately one body, not N.

Selection and undo ride on top of these:

- **Selection** keys the viewport's selectable units by `bodyId`. N-body birth
  would give N selectable bodies "for free" _if_ the four layers above minted N
  distinct body ids and non-ambiguous tokens — which they cannot.
- **Undo/redo** operate on operations (transactions over the operation list). One
  op = one body birth, so undoing an import removes its one body. Multi-birth
  requires that undoing a single birth op atomically removes/restores **all N**
  of its bodies, and that any operation referencing one of the N is invalidated
  as a set — a fan-out the transaction/dependency machinery
  (`packages/document-model/src/dependencies.ts`) does not model.

### Why the obvious workarounds do not work

- **"Just split the import into N `import_step` operations."** Breaks provenance
  (one file becomes N unrelated ops), determinism (the split must be stable and
  reproducible across replays and the RFC-8785 op-hash in
  `packages/geometry-contracts/src/operation-hash.ts`), and the retained-source
  model (each op would have to retain the whole file or an unspecified slice).
  It also contradicts how the kernel actually ingests one STEP compound.
- **"Reuse `outputBodyId` for the first solid and let refs point at the compound."**
  That is exactly today's behavior — a single compound body — and gives the user
  no independent selection, naming, or editing of the constituent solids, which
  is the entire point of §10.C.4.

The birth contract is load-bearing correctness machinery, not incidental. It
must be widened deliberately, at a schema-version boundary, not patched.

## Decision (accepted)

Introduce a **multi-output birth** contract, scoped narrowly to birth
(root-producing) operations, behind a `documentSchemaVersion` bump (current is
`2`; this is `3`). Feature operations (fillet, boolean, transform, …) stay
strictly 1:1 — only importers gain fan-out — to keep the blast radius contained.

1. **A dedicated multi-output birth field, not a rewrite of every op.** Give
   birth operations an ordered, non-empty, document-unique
   `outputBodyIds: BodyId[]` (the existing single-output ops keep their scalar
   `outputBodyId`). A new `import_step` / `import_mesh` schema version carries
   `outputBodyIds` (one id per constituent solid, in a **stable kernel-defined
   order** — e.g. STEP `SHAPE_DEFINITION_REPRESENTATION` order, pinned so replay
   and op-hash are deterministic). The importer mints N body ids up front and
   records them in the operation; the retained source is unchanged (still one
   file, one op).

2. **Body-scoped topology tokens.** Extend the token grammar in `refs.ts` from
   `t:<opId>/<role>/<ordinal>` to carry the birth body dimension, e.g.
   **`t:<opId>:<outputIndex>/<role>/<ordinal>`** (single-output ops use
   `outputIndex` 0, or omit it for a back-compatible token that the parser reads
   as index 0). Enumeration becomes per-(op, output body), so element identity,
   names, and refs are unambiguous per solid. This is the crux change; naming
   (N0/N4/N5), the selector evaluator, and the kernel's token minting all consume
   this grammar and must move together.

3. **Kernel evaluation fan-out.** Relax the `bodies`-array contract in
   `kernel-protocol.ts` from "one entry per body-producing operation" to "one
   entry per **born body**, each carrying its `operationId` **and** a stable
   `outputIndex`." The `superRefine` keeps `bodyId` global-unique but allows
   several entries to share an `operationId`. The boolean's "several disjoint
   solids ⇒ `GEOMETRY_FAILED`" clause stays for **feature** ops (a fillet must
   never silently fragment a part); only declared birth ops may fan out, and only
   up to the `outputBodyIds` they declared (a mismatch between declared count and
   produced count is a hard `GEOMETRY_FAILED`, never a silent truncation —
   Aethalgard does not fabricate or drop bodies).

4. **Generalize the uniqueness invariants.** `assertUniqueOutputIds`
   (`document.ts`) and `addOperationIdentityIssues` (`document-schema.ts`) collect
   **all** of an operation's output body ids (scalar or list) into the
   document-wide uniqueness set. `outputBodyIdOf` becomes `outputBodyIdsOf`
   returning `readonly BodyId[]`.

5. **Dependencies, undo, and selection as sets.** The dependency graph
   (`dependencies.ts`) treats a birth op as the producer of its whole body set;
   undo/redo of that op adds/removes the set atomically, and invalidation of any
   member invalidates all consumers of any member together. Selection already
   keys by `bodyId`, so N declared bodies become N selectable units with no
   selection-layer change beyond receiving N ids from evaluation.

### Migration / compatibility

- **Schema version = `documentSchemaVersion` 3, governed by ADR-012.** A document
  using multi-output birth is unrepresentable in schema 2, so per ADR-012 an
  older build **politely refuses** a schema-3 document (typed
  `AethDocumentVersionError`) — it never silently drops the extra bodies. The
  ladder gets a strict 2→3 rung in `packages/project-file/src/migrations.ts`;
  the natural rung is a no-op for content (no existing v2 document contains a
  multi-output op) plus the compile-enforced constant bump, satisfying ADR-012's
  contiguity + drift-guard rules.
- **Token grammar is forward-and-back compatible by construction.** Single-output
  ops keep emitting `t:<opId>/<role>/<ordinal>`; the extended parser reads a
  missing `outputIndex` as `0`. Existing persisted refs therefore continue to
  resolve unchanged, and only multi-birth ops ever emit the `:<outputIndex>`
  form. This keeps the change from rewriting every existing document's refs.
- **Op-hash / replay-cache determinism.** The RFC-8785 op-hash
  (`operation-hash.ts`) must include `outputBodyIds` in canonical order; the
  stable kernel-defined solid ordering (decision 1) is what makes the hash — and
  therefore the replay cache and the differential warm==cold gate — deterministic
  across machines. The ordering rule must be pinned and tested before any of this
  lands.
- **Anchors stay hints.** Reference anchors remain excluded from hashing and
  non-authoritative (`refs.ts` doctrine); the body dimension changes token
  identity, not the two-channel resolution lattice.

## Ruling record (2026-07-28, CAP-024)

All five decisions above are **ratified as written**. The three residuals the
ADR recorded are ruled in
`docs/design/2026-07-28-multi-output-birth-residuals.md`:

1. **Solid ordering is CANONICAL GEOMETRIC, not reader order** — volume desc,
   then centre of mass (x, y, z) asc, then bbox diagonal desc. Reader order was
   rejected outright: it is stable only for a fixed OCCT build, so an OCCT
   upgrade that reordered roots would silently remap every body in every
   multi-solid document, with every reference then resolving to the wrong
   geometry and no error anywhere. A geometric key is a property of the shapes,
   so identical bytes give an identical order forever. A tie on all three keys
   is impossible for genuinely disjoint solids and therefore fails closed rather
   than choosing arbitrarily.
2. **The output index lives in the TOKEN**, `t:<opId>:<outputIndex>/<role>/<ordinal>`,
   with a missing index parsed as 0. An envelope field would let two different
   solids of the same op mint the identical token, destroying the one property a
   token exists to have.
3. **No grouping entity.** The ordered `outputBodyIds` list on the operation IS
   the birth set; a second source of membership could only disagree with it.

## Consequences

- The importer stops collapsing a multi-solid STEP/mesh into a compound: the user
  gets N first-class, independently named, referenceable, editable, deletable
  bodies from one deterministic import operation with intact single-file
  provenance — the §10.C.4 goal.
- The change is a coordinated, schema-versioned tranche across five layers
  (op schema, document invariants, ref/token grammar, naming enumeration, kernel
  evaluation) plus dependency/undo fan-out. It cannot be delivered as an
  importer-only patch; that is precisely why this ADR gates it.
- Blast radius is bounded by scoping fan-out to birth ops only: feature
  operations, the "no silent fragmentation" boolean guard, and every existing
  single-output op are untouched, and existing documents/refs migrate trivially
  (refuse-on-newer for the file, index-0 default for tokens).
- Residual open questions for the implementing tranche, to be settled in a design
  note before code:
  - the exact stable ordering rule for STEP solids (and the mesh analogue when a
    mesh import yields multiple lumps) and its test corpus;
  - whether `outputIndex` lives in the token as `:<n>` or the ref envelope grows a
    `body` field (the ADR picks the token form for locality; revisit if the
    selector evaluator prefers an envelope field);
  - the UI affordance for the birth set (a group/collapse in the model tree) —
    out of scope here, but the data model above must not preclude it.
