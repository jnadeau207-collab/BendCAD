# ADR-011: Disposition of the G0–G5 pre-implementation gates under the JIT-research doctrine

Date: 2026-07-19
Status: accepted (founder decision, 2026-07-19 — reconciles the two
constitutions per `docs/audits/2026-07-17-plan-realignment.md` §4.A / §5.1)

## Context

Two documents claim constitutional authority over when implementation may
proceed, and they contradict each other:

- `docs/research/00-production-research-gap-audit.md` (2026-07-12, the
  pre-architecture research program) states normatively: "No implementation
  phase should begin until Gates G0–G4 below have owners, fixtures,
  reproducible results, and signed decision records," and defines gates
  G0–G5 (§5).
- `MASTER_PLAN.md` (2026-07-12/13, the authoritative build plan) §0 states
  the JIT-research doctrine — "Research is just-in-time: investigate a
  question when implementation encounters it, record the decision, encode
  it in tests, and continue" — and §5 defines the nine integration gates
  that actually govern completion.

Actual practice follows MASTER_PLAN: implementation is deep into Tranches
A–E, research has been performed just-in-time (NG-1 protocol audit, NG-2
persistent-naming tournament), and decisions are recorded as ADRs. The
gap-audit document was never amended, so it still reads as a live
constitution forbidding the work that has already shipped.

## Decision

MASTER_PLAN's JIT-research doctrine governs. The G0–G5 framework is
**disposed, not discarded**: each gate's intent is either absorbed into a
mechanism that exists, or retained as a future release gate. The gap-audit
document becomes a historical program record with an amended status header.

| Gate                                    | Disposition                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **G0 — Evidence integrity**             | **Absorbed** into the ADR corpus (ADR-0001, 001–011) + the dated audit/execution records (`docs/audits/`, `docs/execution/`) + the standing review discipline. The single "claim ledger" artifact is retired; the V/M/H/D evidence vocabulary (§2) remains in force for research documents.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **G1 — Kernel/reference feasibility**   | **Absorbed and, for its reference half, CLEARED.** The zero-silent-misreference threshold was discharged by the ADR-005 tournament's qualifying 100,047-case real-OCCT run (2026-07-16: zero silent misreferences for every real entrant; the ordinal control failing at 50.4% — see ADR-005's closing consequence). The kernel validity/latency/crash/determinism half is carried by the standing native suites (`pnpm native:test`), MASTER_PLAN §5 gates 1–3, and per-tranche perf budgets — continuous verification, not a one-time gate. **CAVEAT 2026-07-23: the raw evidence for the CLEARED half no longer exists on disk and was never committed — see the EVIDENCE STATUS note in ADR-005. The clearance is reproducible but not currently falsifiable; re-running the qualification and committing its summary artifacts is an open obligation.** |
| **G2 — Agent feasibility**              | **Deferred to a release gate.** MASTER_PLAN §6 Blocker 5 deliberately decouples architecture from model choice (deterministic fake model first); the AeCAB-style evaluation of the actual bundled weights is a Tranche-D exit obligation before any model ships, not a precondition for building the orchestration engine.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| **G3 — Human usability**                | **Retained as a future release gate**, mapping onto the Tranche C exit (novice + expert workflows without exposing kernel/graph internals) plus §5 gate 8 (accessibility integrity).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **G4 — Manufacturing interoperability** | **Retained as a future release gate**, mapping onto the Tranche E exit (intent → verified slicer → physical part) plus §5 gate 6 (export integrity).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **G5 — Production readiness**           | **Retained as a future release gate**, mapping onto the Tranche F exit (shippable/recoverable/upgradeable): threat model, SLOs, recovery tests, update rollback, SBOM/signing, accessibility audit, support operations.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |

The gap-audit's §3 "immediate corrections" and §4 workstreams remain a
useful research checklist and keep their per-item force where later
documents have not superseded them; its §1/§5 blocking language is void.

## Consequences

- `docs/research/00-production-research-gap-audit.md`'s status header is
  amended in place to point here; the document no longer reads as a live
  constitution contradicting MASTER_PLAN.
- Release readiness for Tranches C/E/F must cite G3/G4/G5 by name when
  those exits are claimed, so the retained gates cannot silently evaporate.
- Future "no code until research" mandates require an ADR naming the
  specific question and its acceptance evidence — the tournament (G1) is
  the template for how a gate is actually discharged: owners, fixtures,
  reproducible results, and a signed decision record, exactly as the
  gap-audit demanded, delivered just-in-time.
