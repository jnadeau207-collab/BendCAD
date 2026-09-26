# Bend-native gates checklist (permanent, per-packet)

Status: permanent. Every future work packet MUST copy the BN-1..BN-12
table into its receipt (and reference it from its contract), recording
PASS or FAIL per gate with concrete evidence. A FAIL on any gate blocks
that packet's release claim until resolved or explicitly scoped out with
owner review.

Scope: authoritative geometry and topology algorithms in BendCAD
(`src/`, `laws/`, `tests/`). Declared implementation boundaries from
`MASTER_PLAN.md` still apply: compiler backends, OS I/O, device
dispatch, and a qualified numeric runtime may contain C/C++/JS/Metal;
the archived OCCT evaluator may run only as a separately identified
test oracle. Those boundaries never excuse hiding a CAD algorithm
behind a foreign call.

Conventions:

- PASS = gate holds for this packet; cite the evidence (grep command +
  output, file:line, receipt section, law name, test name).
- FAIL = gate violated; cite the violation and the blocking follow-up.
- N/A is forbidden. If a gate is out of scope for a packet, record PASS
  with the positive reason (e.g. "no GPU claim in this packet, hence no
  GPU path to fall back from"), never a blank.
- Evidence must be at the packet's tested commit. No completion claims
  from a different SHA.
- `legacy/` is immutable reference material; it is never packet
  implementation and never edited to satisfy a gate.
- Never run `bend update` (it replaces the fork build with upstream).
  Never commit/push as part of packet verification.

## Gates BN-1..BN-12

| Gate | Verbatim intent | What counts as evidence |
|------|-----------------|-------------------------|
| BN-1 | All authoritative algorithmic code is Bend. | List of packet implementation files (all `.bend` under `src/`); no authoritative algorithm in another language. Cite `git status`/file list + sha256 as in prior receipts. |
| BN-2 | No `@unsafe` in trusted geometry. | `grep -rn "@unsafe" src/ laws/ tests/` output (must be empty for trusted geometry); any `@unsafe` elsewhere needs explicit boundary justification. |
| BN-3 | No F32 in authoritative geometry. | `grep` for `F32`/f32 constructors in packet sources is empty; authoritative scalars are the pinned as-bits F64 path. Display-only F32 narrowing, if any, is identified and proven not to flow back into topology, exact queries, or model coordinates. |
| BN-4 | No foreign/FFI implementation of geometry. | No foreign call implements a CAD algorithm; compiler/runtime/device-dispatch boundaries only, each named. Cite the boundary list or "none". |
| BN-5 | No OCCT/FreeCAD/PlaneGCS runtime dependency. | Runtime geometry does not call them; they appear only as separately identified test comparators/oracle harness outside `legacy/`. Cite oracle separation or "not used". |
| BN-6 | No hidden CPU fallback for claimed GPU path. | If the packet claims GPU execution: device-gate proof (strict backend identity, `--gpu on` semantics, device-fault abort); else the explicit statement that no GPU claim is made. Silent fallback is FAIL. |
| BN-7 | No persistent identity from array position/address. | Handles/refs carry generation/content identity (never memory addresses or array ordinals as persistent identity). Cite the types/laws (e.g. generational refs) or the packet's stated identity mechanism. |
| BN-8 | All recursion terminates or is explicitly rejected. | Bounded iteration/fuel threading with explicit `Incomplete`/rejection on exhaustion; no unbounded recursion admitted silently. Cite fuel/bound mechanism + negative tests. |
| BN-9 | Every expensive batch algorithm has a parallel decomposition. | Batch work states its partitioned owned arrays / scratch arenas / deterministic batch-tree decomposition; cite design section or "no expensive batch op in this packet". |
| BN-10 | Every numerical shortcut has proof OR certified bound OR explicit experimental classification. | Each filter/shortcut cites its law, its error-bound analysis, or its explicitly labeled experimental classification. Unlabeled shortcuts are FAIL. |
| BN-11 | Every failure path is non-publishing. | Every `Failed`/`Incomplete` arm returns the input model unchanged; cite per-arm laws (e.g. `*_keeps_model`) + negative tests asserting `model_equal(outcome, pre)`. |
| BN-12 | Every receipt identifies exact Bend commit and BendCAD commit. | Receipt records `BEND_PIN` exact SHA, `~/.bend/FORK` provenance, BendCAD HEAD SHA, per-file sha256, and toolchain env. Missing or floating identities are FAIL. |

## Per-packet copy/paste block

```text
## Bend-native gates (BN-1..BN-12)
| Gate | Verdict | Evidence |
|------|---------|----------|
| BN-1 | PASS/FAIL | ... |
| BN-2 | PASS/FAIL | ... |
| BN-3 | PASS/FAIL | ... |
| BN-4 | PASS/FAIL | ... |
| BN-5 | PASS/FAIL | ... |
| BN-6 | PASS/FAIL | ... |
| BN-7 | PASS/FAIL | ... |
| BN-8 | PASS/FAIL | ... |
| BN-9 | PASS/FAIL | ... |
| BN-10 | PASS/FAIL | ... |
| BN-11 | PASS/FAIL | ... |
| BN-12 | PASS/FAIL | ... |
```

Gate count: 12 (BN-1 through BN-12).
