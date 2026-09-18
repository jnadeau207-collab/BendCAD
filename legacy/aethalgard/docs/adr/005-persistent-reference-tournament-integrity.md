# ADR-005: Persistent-reference tournament integrity boundary

Date: 2026-07-12  
Status: accepted

## Context

The first T-01 scaffold flattened each case into before/after entity attributes. It also placed the
mutation stratum in `programId`, embedded oracle-like labels in adjacency/provenance strings, accepted
any ambiguity candidate set as correct, allowed crash-only resolvers to pass, and described the
observed failure rate as a 95% upper bound. That harness could select an unsafe architecture while
appearing statistically rigorous.

The four required entrants do not have equivalent implementations over flattened attributes. OCAF
`TNaming`, algorithm-history maps, and BRepGraph/provenance hybrids require native, strategy-owned
state during mutation and may resolve asynchronously.

## Decision

1. A case has a strict entrant-visible envelope and a separate oracle envelope. The runner never
   passes the oracle, mutation stratum, or hidden lineage to an entrant.
2. Resolver hooks are asynchronous and may retain opaque native strategy state. Attribute snapshots
   are evidence, not a replacement for OCAF/history execution.
3. Every resolver result is runtime-validated. Candidate sets must be non-empty, unique, and refer
   to entities in the after snapshot.
4. Safety, coverage, qualification, and ranking are separate:
   - crashes, malformed results, or silent misreferences fail safety;
   - zero automatic resolutions cannot enter selection;
   - synthetic or incomplete OCCT corpora can never enter production selection;
   - only a qualifying real-OCCT corpus may select the winner.
5. Reports retain every outcome, attach/resolve timing, mutation-stratified counts, automatic
   resolution rate, correct outcome rate, and Wilson 95% upper endpoints both per completed case and
   per automatic resolution.
6. Qualification requires the exact OCCT build manifest, at least 100,000 pairs, and all mandatory
   strata. Human-reviewed adversarial oracles remain required for semantic split/merge/ambiguity
   cases.
7. Kernel protocol v2 gains an additive `includeTopology` request flag. Returned snapshots contain
   epoch-local face/edge/vertex tokens, analytic class, measure, centroid, orientation, incidence,
   and producing operation ID. None is declared durable identity.

## Consequences

The synthetic generator remains useful for mechanics and negative controls but is permanently marked
non-qualifying. The first real source evaluates parameter-perturbed boxes through the pinned native
host and proves topology extraction, token reminting, incidence validation, and oracle separation.
It is also non-qualifying: six box faces are a transport fixture, not evidence that persistent naming
is solved.

The next native work is a mutation-fixture executable/session that records complete OCCT algorithm
history and OCAF evolution for the full T-01 matrix. The four entrants are implemented only against
that common real mutation program; no flattened substitute may be reported as an OCAF or history
result.

**Closing (2026-07-19): the bar this ADR set was subsequently cleared.** On 2026-07-16, after the
founder countersigned all five oracle-review items (`docs/execution/ng-2-oracle-review-pack.md`),
the runner executed the qualifying run: a fresh-seed (20260717), manifest-pinned, eleven-stratum,
**100,047-case** real-OCCT corpus (byte-identical `contentDigestSha256` verified across attempts).
`qualificationFailures` was empty for every real entrant — **zero silent misreferences for all five**
(aql v2, history-map, ocaf-tnaming, hybrid, hybrid3), while the ordinal negative control
misreferenced 50,397 cases (50.4%) and failed its safety gate, proving the safety split
discriminates. Under §6's selection semantics AQL v2 ranked first (0.6368 automatic resolution);
per ADR-006 the production resolver combines the qualified channels rather than shipping one
entrant. Full record with per-entrant tables and run provenance:
`docs/execution/ng-2-tournament-foundation-results.md` ("THE QUALIFYING RUN"); raw per-strategy
reports from the `tools/reference-tournament` runner (`report.json` + `summary.md` per entrant)
preserved at `.native-cache/tournament-runs/qual-20260717/reports/` (uncommitted by design —
native caches never enter the repo, ADR-002).

> **EVIDENCE STATUS 2026-07-23 — the raw reports are GONE.**
> `.native-cache/tournament-runs/` no longer exists on any machine. Because the
> reports were never committed, the qualifying run's per-entrant `report.json` /
> `summary.md` artifacts are **unrecoverable**, and the zero-silent-misreference
> claim — this project's foundational technical claim — currently rests on the
> summary tables transcribed into
> `docs/execution/ng-2-tournament-foundation-results.md` rather than on
> falsifiable primary evidence. The harness itself is fully committed
> (`tools/reference-tournament/`), so the run is **reproducible but not
> re-verifiable in place**.
>
> Consequence: "uncommitted by design" was the wrong disposition for a
> gate-discharging artifact. ADR-002's rule (native caches never enter the repo)
> is about build outputs, not evidence. The remedy is to re-run the qualification
> and commit the _summary_ artifacts (small, text, deterministic) alongside the
> content digest, keeping only the bulk case corpus out of the tree.
