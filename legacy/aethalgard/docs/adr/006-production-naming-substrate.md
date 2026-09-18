# ADR-006: Production naming substrate — lineage names under the token registry

Date: 2026-07-16
Status: accepted (founder decision, 2026-07-16)

## Context

Two authoritative documents disagreed about how persistent naming should be
implemented, and neither cited the other:

- `docs/plan/01-geometry-core/05-selector-query-language.md` §6.5 (NORMATIVE,
  pre-dating the NG-2 research) rejected "realthunder-style string-encoded
  element maps" in favor of a `NamingRegistry` minting tokens
  `t:<opId>/<role>/<ordinal>` whose ordinals come from a geometric canonical
  key (quantized centroid/measure sort).
- `docs/research/02-ng2-persistent-naming.md` (§4, §9) recommended, and the
  NG-2 tournament built, exactly the rejected design: deterministic
  lineage-name strings (`n1:` grammar, `native/kernel-host/src/element_names.hpp`)
  with FreeCAD-style four-pass naming and survivor-congruence matching.

The tournament then produced decisive evidence. On the 100,119-case
manifest-pinned corpus across ten strata (plus the imported-step stratum
measured separately), the history element map over lineage names held **zero
silent misreferences with the highest coverage of any entrant**, resolving
Case B re-evaluations (pattern collapse, suppression) that no
attribute/geometric strategy can decide — while the ordinal control, the
purely positional/geometric family §6.4's canonical key belongs to,
misreferenced 52% of the corpus. The audit
(`docs/review/session-review-2026-07-16.md` §3) surfaced the unreconciled
conflict as a blocker for integration work.

Plan 05 §6.5's three objections to string element maps were, in order:
(a) names must be re-derivable from replay anyway; (b) a registry allows
aliasing without unbounded name growth; (c) OCCT 8 makes `IsSame`-keyed maps
cheap. None of these is an objection to the design as actually built: the
`n1:` names ARE re-derived per evaluation (proven byte-deterministic across
host processes), growth is bounded by the grammar's SHA-256 hashing of
over-threshold segments, and the names live in evidence/registry structures —
never embedded in the B-rep. What §6.5 actually rejected was FreeCAD's
_storage_ model; what the research validated was the _identity derivation_
model. Those are separable, and the measurement says the identity model wins.

## Decision

**Synthesis: keep plan 05's surface, replace its correspondence spine.**

1. **AQL stays the only persisted reference language.** Queries + anchors per
   plan 01 §7.1 and plan 05 §§1–5, 7–9 are unchanged. No `n1:` string ever
   appears in a persisted document reference.
2. **Tokens stay the epoch-local handles.** `t:<opId>/<role>/<ordinal>`
   remains the presentation/selection currency for the UI, agent, and
   tessellation packets, exactly as plan 05 §6.1 specifies.
3. **The registry's identity spine is the lineage name.** At harvest, every
   `NamingRecord` additionally stores the entity's `n1:` lineage name
   (computed by the existing `element_names.cpp` machinery). Within a role
   bucket, ordinals are assigned by lexicographic order of **normalized
   lineage names** — deterministic and geometry-independent — with the
   geometric canonical key demoted to a tie-break used only where the grammar
   REQUIRES twins to collide (identical normalized names). A persisted
   reference whose resolution depends on distinguishing such twins resolves
   ambiguous, never positionally.
4. **Cross-replay correspondence uses the proven hybrid lattice.**
   Re-resolution (plan 05 §9), anchor disambiguation (§9.3), and empty-recovery
   (§9.4) combine two channels per the role-typed lattice meet the tournament
   verified (research §6; `tools/reference-tournament/src/resolvers/hybrid.ts`):
   the **history channel** (survivor congruence over normalized lineage
   names — equality, or extension by Modified-only segments) and the
   **signature channel** (plan 05 §9.3's attribute/anchor scoring, which is
   the AQL entrant's fail-closed discipline). A silent rebinding requires both
   independent channels to agree; disagreement demotes to typed ambiguity.
   This carries the tournament's zero-misreference safety property into the
   product resolver by construction.
5. **Authored durable ids are deferred, not rejected.** Research §11.1's
   proof-tier channel (mint a durable id when the user first selects an
   entity) is the only mechanism that survives true symmetry for authored
   references. The lattice already models a `proof` tier; the document model
   will add authored ids in a later tranche without changing this
   architecture.
6. **Formal winner selection still follows ADR-005.** This ADR fixes the
   _architecture_ (which is winner-robust — the production resolver is the
   hybrid combination regardless of which single entrant ranks first); the
   qualifying run over the countersigned, eligibility-cleared corpus
   completes the ADR-005 selection record.

## Consequences

- Plan 05 §6.4/§6.5 are amended in place (revision note added) to match this
  decision; §6's harvest procedure gains the lineage-name recording step.
- The kernel-host `NamingRegistry` implementation (integration tranche)
  reuses `element_names.cpp` rather than implementing a second naming scheme.
- `includeElementNames` must thread through `evaluate_document` (today it is
  `mutation_case`-only) — this is also the tournament's highest-leverage
  coverage follow-up, so product and harness share the work.
- The reference tournament remains the standing regression harness: any
  change to the naming substrate must keep every real entrant's safety gate
  green at qualification scale.
- FreeCAD-style _storage_ (names embedded in shapes/documents) remains
  rejected; nothing is persisted beyond what replay re-derives.
