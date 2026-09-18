# ADR-017: The local model is an ATTACHED runtime, not a bundled pack

Date: 2026-07-28
Status: accepted (CAP-023; delivering-session ruling under the standing
no-founder-gating law recorded in PROJECT_STATE.md)

## Context

`docs/plan/03-ai-agent/00-overview.md` locks the upstream inference line to a
**bundled, signed llama-server pack**: the app ships the weights, verifies a
manifest signature against pinned keys, launches its own supervised server, and
therefore knows exactly what it is talking to.

That is not what ships. Lane M attached to a **user-installed Ollama** instead
(`packages/model-runtime/src/ollama/`), and CAP-022 made the agent loop reachable
on that path. The deviation was declared in
`docs/design/2026-07-23-local-model-ollama-provider.md` §4 and never ratified:
`docs/adr/` had no entry for it, so the shipping product contradicted the locked
plan with nothing recording the decision or its terms.

Two of the plan's guarantees do not survive the substitution, and pretending
otherwise is the failure this ADR exists to prevent:

- **Provenance.** There is no manifest and no signature to check. We did not
  build the weights, we cannot attest to them, and the daemon can swap them
  underneath us.
- **Version control.** Ollama self-updates. The design observed 0.32.1 → 0.32.3
  **mid-session**. A version pin is not merely inconvenient; it is unenforceable.

## Decision

### D1 — Ratify the deviation

**Accepted.** The attach path ships, via the plan's own `InferenceServer`
substitution pattern. The seam is unchanged and is the reason this is a
substitution rather than a rewrite: `ChatCompletionBackend.chatCompletion`, one
method (`packages/agent-orchestrator/src/sidecar-model-port.ts`). Everything
above it — the orchestrator, the toolset, the review overlay, the commit path —
cannot tell the two providers apart.

Rejecting would have un-shipped a capability that CAP-022 proved works end to
end, in exchange for a packaging tranche that is explicitly out of scope. The
honest cost of accepting is the two guarantees above, and they are paid below
rather than hidden.

### D4 — `qwen3.5:9b` is the supported default

**Superseded by CAP-140 on 2026-08-11.** The earlier `qwen3:4b` exception was
supported by a 39-operation measurement against the much smaller pre-Sweep
tool surface. Sweep v2 raised the complete authoring surface beyond that
measurement and the product now returns to the plan's 9B floor with
`qwen3.5:9b`. `AETH_OLLAMA_MODEL` remains an explicit operator override; it is
not a silent fallback.

The exact CAP-140 evidence must include a fail-closed live integration run
against the shipped default. A question-only response does not count as an
authored-operation success.

### D5 — Version floor PLUS behaviour probe

**Accepted (option c).** Since a pin is unenforceable, detection now enforces:

1. **A version floor** — `minimumOllamaVersion`, the oldest line whose behaviour
   this build has actually been measured against. The honest statement is not
   "older versions are broken" but "older versions are **unmeasured**", and
   unmeasured fails closed with a remedy.
2. **A window-conformance check** — the model's own context length must be at
   least the window we pin per request. Asking for more does **not** error;
   Ollama returns a smaller window and the assembler then budgets against one
   that does not exist.
3. **The tool-capability check** that already existed.

Every failure is a typed unavailable state carrying the exact remedy, and the
editor stays entirely usable — the honest-degradation rule.

### D6 — Configuration stays environment-gated

**Accepted (option a).** `AETH_OLLAMA_MODEL` and `AETH_OLLAMA_CONTEXT_TOKENS`
remain the surface for M1. The settings-migration option cited an `ai` settings
object that **does not exist** anywhere in `packages/` or `apps/`; adding a
persisted store to hold two variables nobody has asked to change would be new
scope justified by nothing.

### D7 — Provenance: declare unknown, fail closed

**Confirmed.** The pack signature is dropped for this path and **no fact it
anchored is quietly retained**. What we can observe (daemon version, model name,
declared capabilities, reported context length) we report; what we cannot
(weight provenance, tamper-evidence) we do not claim. The agent never asserts a
guarantee it cannot check.

### D8 — VRAM arbitration is out of scope, and says so

**Confirmed.** The doc 07 §6 VRAM ladder governs packs we launch. We do not
launch this one and we do not arbitrate its memory: Ollama decides what to load
and when to evict. The UI must not imply otherwise.

## Consequences

**What we gained.** A working agent with no multi-gigabyte download in the
installer, on hardware the user already configured, with no cloud path at any
point (the client refuses a non-loopback host by construction).

**What we gave up, stated plainly.** No provenance attestation. No version
control — only a floor and a probe. No memory arbitration. A user who updates
Ollama can break the agent, and the failure will be a typed unavailable with a
remedy rather than a silent degradation. That is the trade.

**The one-number rule is now enforced on both paths** (design §7.4): the
context-assembler ceiling must equal the window the runtime was actually
launched with. The pack path violated it — `SidecarModelPort` defaulted to a
131,072 ceiling against a server launched at 8,192, a **16x** overestimate. That
does not fail; the runtime silently drops the head of the transcript, which is
where the system prompt and the entire tool surface live, and the only symptom a
person sees is that the assistant got stupid. `ModelManager` now publishes its
launched window and both compositions bind to it, pinned by tests in both
packages.

**Binding the two numbers immediately exposed a second defect: the pack path's
default window could never have run a single step.** The authoring toolset
measures 7,618 tokens and the assembler reserves 1,536, so the minimum viable
context is 9,287 — against a server launched at 8,192. It was invisible for
exactly the reason above: the budget check passed because it was measured
against a window that did not exist. The first real run with the numbers bound
raised `ContextBudgetError`. The pack default therefore moves off the plan's
floor tier onto its DEFAULT tier (12,288) — not a new number, but the one the
Ollama path already pinned, for the same reason. A host may still size the floor
tier deliberately for a constrained device; what it may not be is the silent
default for a toolset that cannot fit in it.

**Reachability stays conditional.** The agent requires a user-installed Ollama,
and `docs/execution/reachability-ledger.md` says so in the row rather than
claiming an unqualified YES.

## Supersedes / relates

- Deviates from `docs/plan/03-ai-agent/00-overview.md` "Locked upstream" — that
  line remains the target for the packaging tranche; this ADR governs what
  ships until then.
- Design record: `docs/design/2026-07-23-local-model-ollama-provider.md`
  (§4 deviation, §7 budgets, §10 provenance/VRAM, §11 self-update, §17
  measurements).
- D2 (native `/api/chat` transport) and D3 (app mints all ids) were resolved and
  implemented before this ADR and are not reopened.
