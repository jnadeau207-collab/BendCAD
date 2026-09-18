# PROJECT_STATE.md — Current product truth

**Authority:** the only current-state and execution-order document
**Updated:** 2026-08-11
**Default branch:** `claude/aethalgard-cad-concept-ks13vd`
**Exact default head:** `ee906930c0bbac8bb28a2c1f36486069147e4dc5`.
**Qualified integration implementation:** `af85cf3e4060f472cea90024b6826eb9759a00de`.
**Current mode:** capability delivery.
**Active capability:** none. Current task is GOV-006 (`docs/work/governance/parity-program-queue.md`): no capability is admitted; issues #141-#150 remain open and unqueued pending founder direction.
**Last delivered packet:** `docs/work/archive/CAP-140-sweep-associative.md`.
**CAP-140 qualified tip:** `e5d47c8be4e5c036e93e2d86af149cb2988d64e3`.
**CAP-140 status:** DELIVERED — issue #140 closed, PR #180 merged as `ee906930`; evidence `docs/evidence/e5d47c8be4e5c036e93e2d86af149cb2988d64e3.md`; `pnpm cap:freeze` passed 8/8 at that tip; no relative claim against a commercial system was made.
**CAP-139 qualified tip:** `af85cf3e4060f472cea90024b6826eb9759a00de`.
**CAP-139 status:** DELIVERED — issue #139 closed, PR #177 merged as `c1dd4c5b`; exact evidence is `docs/evidence/af85cf3e4060f472cea90024b6826eb9759a00de.md`.
**CAP-138 qualified tip:** `98c385694a2a69c3ba1f66191f72ac4ee241240e`.
**CAP-138 status:** delivered; exact trunk evidence is `docs/evidence/98c385694a2a69c3ba1f66191f72ac4ee241240e.md`.
**Execution order:** `docs/plan/TRUE_NORTH_DOMAIN_PROGRAM.md`. **Machine-readable authority:** `docs/context/manifest.json`

## Current verdict

**Delivered capabilities are historical inputs, not remaining scope.** The
delivered index and archived packets are in
`docs/execution/delivered-capabilities.md`; exact-tip proof is in
`docs/evidence/<sha>.md`, and the manifest is machine authority.

CAP-139 is qualified at `af85cf3e` in PR #177: durable Revolve v2 with arbitrary
associative axes, full angular/Thin/Boolean semantics, complete re-edit,
fail-closed repair, 52/52 topology tournament cases, both packaged renderers
green on Node 24.

**The superiority gate is DELETED (founder ruling, 2026-08-11).** `tools/superiority/`
and `docs/plan/SUPERIORITY_LAW.md` are gone. Comparison against Fusion is a
judgement stated in prose: which capabilities Fusion offers for the feature,
which of those we implement, and whether ours is more complete. Say it plainly,
including when we are behind. Do not build a gate, corpus, or measurement whose
only purpose is to re-derive that judgement.

## Current product directive — 2026-08-08

Aethalgard targets Fusion parity or better across the full CAD-to-manufacturing
stack, not consumer “clips and bins.” Squarespace-grade direct manipulation is
the accessibility layer for normal 3D-printer users; professional sketch,
history, assembly, drawing, CAM, and manufacturing surfaces remain required.
Searchable commands (including Fusion-style S-key) complement visible controls;
a ribbon may be a settings-gated pop-out. The timeline is a light projection of
real parametric history. Humans and the local agent are equal operators of one
typed transaction system; kernel/solver objects are disposable. Older bans on
search, hidden history, or narrowed product scope are superseded.

## CAP-138 trunk is qualified at its actual merge tip

CAP-138 closed through PRs #174 and #175. Its earlier `f214e0e5` evidence did not
qualify the later product changes at trunk `98c38569`; that false-green gap is
corrected by `docs/evidence/98c385694a2a69c3ba1f66191f72ac4ee241240e.md`. The old
**27-of-28 reachability** count is historical only; competitive coverage in
`MASTER_PLAN.md` governs product completeness and roadmap.

**A row needing an independent per-row action cannot be `listbox`/`option`.**
ARIA forbids an interactive descendant inside a widget role, so a hide/show
button inside `role="option"` fails axe's `nested-interactive`, and a sibling
wrapper still inside `role="listbox"` fails `aria-required-children`. Use
`role="list"`/`"listitem"` with `aria-current` for selection (CAP-028).

**A `key` built from document identity alone does not catch "reopen the file
already open in this window."** CAP-028's ephemeral per-window state
(`hiddenBodyIds`) relied on `Editor` remounting via
`` `${document.id}:${document.path}` ``. Re-opening the SAME already-open file
produces an unchanged key, so React never remounts and per-window ephemeral
state incorrectly survives — found only by the packaged gate's real Save
As → Open walk against a real kernel and real window, not reachable by any
unit test. Fixed with a `reopenSequence` counter bumped on a successful
open/openRecent (never a plain save) and folded into the key. Any future
per-window ephemeral state must assume the same gap until proven otherwise.

**Grounding by parallel research pays for itself on a packet with real admission
questions.** CAP-027 named seven things to verify before coding; a 5-agent
parallel pass answered all seven with file:line citations in under two minutes,
and every downstream design decision traced back to one of those answers.

**An IPC channel that only mints evidence is a different shape than one that
mints a durable reference, even with an identical request envelope.**
`measureEvidence` needed `recordSelection`'s replay without its AQL mint; the fix
was extracting the shared `resolveEvidenceUncached` step, not duplicating the
replay or accepting the side effect. Expect this whenever a read reuses a write.

**THE REMAINING QUEUE IS HARDENED AGAINST STALE PACKET ASSUMPTIONS.** Every
executor reads `docs/work/capabilities/EXECUTION_STANDARD.md`; admission now
requires an exact-base Grounding record, final call-graph ownership, negative
proofs, a shared-surface matrix, packaged/manual evidence, and explicit review
rejection criteria. Queued line numbers and current-state claims are hypotheses,
never authority over the admission tip.

**RELEASE ENGINEERING IS SEPARATE FROM PRODUCT ORDER.** Signing, hosted
services, and public activation are external delivery concerns. They do not
defer the product program, and the packaged artifact itself remains a required
qualification surface for every user-visible capability.

**THE DOCUMENT SCHEMA IS NOW 3.** CAP-024 bumped it for multi-output birth.
v2 and v3 are structurally identical — the version buys the REFUSAL, because a
v2 build meeting `outputBodyIds` hits its own `.strict()` schema and answers
with a raw unrecognized-key error instead of ADR-012's typed version error.
Every "future version" probe and fixture moves UP with the ladder: one the build
can actually open stops testing the refusal and starts silently passing.

**Never order persisted geometry by a READER.** ADR-013 proposed OCCT transfer
order for multi-solid imports; it is stable only for a fixed OCCT build, so an
upgrade that reordered roots would silently remap every body in every such
document with no error anywhere. The rule is canonical GEOMETRIC (volume desc,
centre of mass, bbox diagonal) — a property of the shapes. Ties fail closed.

**A superRefine on an operation schema costs the agent that tool.** The toolset
builds its model-facing inputs by `.omit()`-ing fields off the operation
schemas, and a refinement turns the schema into a ZodEffects that cannot be
omitted from. Put cross-field invariants in the document identity pass.

**A gate that checks the WRONG number reports the opposite of the truth.**
CAP-023 bound the context-assembler ceiling to the window the runtime is
actually launched with (the one-number rule). Doing so immediately proved the
bundled-pack path could never have run a single step: the authoring toolset is
7,618 tokens and the reserve 1,536, a 9,287 minimum against a launched window of
8,192. It had been invisible because the budget check passed — against a window
that did not exist. Prefer binding two numbers together over asserting they
agree.

**Founder-decision packets are RULED by the delivering session.** CAP-023 was
authored as founder-only across six items; all six are ruled in ADR-017 with the
reasoning recorded. A packet that says "present this to the founder" is not a
stop sign under the standing law.

**The agent row is now a CONDITIONAL yes, and the condition is named.** CAP-022
wired the clarification and event seams the orchestrator always had, so the loop
works end to end — but no model pack ships, so it requires a user-installed
Ollama. Recording that as NO was stale; recording it as an unqualified YES would
be a lie. An operation reachable ONLY through the agent still does not count as
reachable, precisely because of that precondition.

**A native gate that had never run is now running.** `apps/desktop` was absent
from `native:test`'s package filter, so its native-gated suites executed in no
lane at all — they were not skipping, they were passing by never being loaded.
The durable rule: a fail-closed gate only fails closed if something IMPORTS it;
adding a `*.native.integration.test.ts` to a package outside the lane's filter
buys nothing.

**CAP-019/CAP-020 reachability is weaker than the rest:** their fastener and
rail-to-face claims use packaged keyboard/activate twins rather than a packaged
drag gate, as recorded in `docs/evidence/256f8679efb7857824cb03b4334db0d86d2719e5.md`.

**CAP-029/030/031/033/039 shipped (2026-07-29);** details and remaining facts
are in `docs/execution/delivered-capabilities.md`.

**A refactor that renames a surface can silently disarm its gates.** CAP-039's
FloatingPanel → inspector-dock migration proved that selectors and tests must
be updated together; a green run against a dead selector proves nothing.

## Standing law

**THE BAR IS SOTA WORLD-CLASS CAD, ON EVERYTHING.** Every admission and every
review asks: world-class, or merely works? **Merely works is a review defect**,
enforced. Bar artifacts: **GOV-003** (robustness doctrine → ADR-015, MERGED) and
**GOV-004** (sketcher research → ADR-016 ACCEPTED, MERGED; its executor was the
CAP-035…038 program).

**Turn discipline (founder ruling, 2026-07-28), codified in `AGENTS.md`.** A
capability turn ends only at fully resolved, merged, and the issue CLOSED.
Stopping mid-capability is forbidden; context exhaustion is not a stopping
reason (sessions auto-compact and this control plane is built to survive it);
creating new GitHub issues is forbidden — work discovered mid-capability is
completed in the same turn under the active packet.

**No founder gating (founder ruling, 2026-07-28).** There are no
founder-blocked questions and no founder testing gate. Where a queued packet
names a founder decision, the delivering session MAKES that decision under the
SOTA bar and records it as a ruling in the packet and here. Certificates,
code signing, notarisation, and any other paid or identity-bound artifact are
OUT OF SCOPE — deliver everything that does not require them, and state plainly
what a real signing identity would add.

**THE FOUNDER RULED ON OFFSET (2026-07-27).** `offset` means **LOCAL FACE
OFFSET** done correctly at the topological core — a re-trim-and-stitch cycle:
shift the underlying surface, recompute intersections with neighbours,
reconstruct the boundary graph; BRep invariants preserved and the
dropped-reference failure class excluded by construction AND by test. Delivered
as **CAP-034** (merge `9877cf6`).

## Rules a delivering session must obey

- **Shared-surface matrix rule.** A capability that changes a SHARED surface must
  re-run every packaged gate that READS it — CAP-015 merged the primitive-catalog
  gate red, and CAP-038's region refusal broke CAP-037's determinism fixture.
- **Re-ground every queued packet at admission.** Packets were authored far from
  the tree; CAP-009's SHRANK on contact and three of CAP-038's own grounding
  claims were wrong. Read the tree, correct the packet, then design.
- **Face-placed authoring uses kernel f64 geometry, never the f32 display mesh**
  (CAP-005 ruling, §4 seam `fcac374`). The hole ships POSITIONAL v1: origin is
  the kernel's own face centroid. Limits: no face-following on upstream edits;
  centroid entry; void centroid refused.
- **Author from the DURABLE selector, never re-minted pick data.** A pending or
  failed recording BLOCKS the verb; no verb falls back to all-edges. Proven by
  measurement (one edge 219.75 mm³ vs all-twelve 2609.56; the grown box's
  selector followed at 274.69). Limits: fillet/chamfer are SINGLE-EDGE, and a
  person cannot trigger re-resolution today (CAP-025/026).
- **An import is the ONE birth with no authored construction frame** (CAP-011),
  so it mints FLAT per-kind roles (`imported-face`/`-edge`/`-vertex`); identity
  rests on the lineage name. The import birth IS the copied-body mint with an
  empty correspondence map.
- **Primitives keep `replace_operation`** or dimension editing silently
  disappears; everything else appends a consuming `transform` carrying NAME and
  SELECTION onward (CAP-008).
- **The verb invents no analytic ceiling** (CAP-009) — that would block legal
  geometry or promise what the kernel cannot build. Refuse with the kernel's own
  measured bound, and never clamp to it.
- **A sketch may not REFUSE a document over what it does not enclose** (CAP-038)
  — a sketch used only as a path or guide is a real thing; the named refusal
  belongs where a person can act on it, while drawing.
- **A printed-fit allowance is STORED on the feature, never read live from the
  active profile at evaluation** (CAP-021,
  `docs/design/2026-07-28-fit-compensation-seam.md`). Threading a live profile
  in would break determinism, serve stale bodies from the replay cache, and let
  a committed hole silently re-cut when the file moves machines. Because the
  record sits in `parameters` it is already inside the op-hash — so every future
  fit/clearance/thread consumer stores the same record rather than inventing a
  parallel path.
- **Every future agent-wire un-staging must state the operation-ceiling cost**
  (the wire went 80 operations → 47), not just the token pin.

## Verification traps (all recorded in `docs/context/RECIPES.md`)

1. **`check:static` is the TypeScript-ONLY lane.** `check-static-workspace.mjs`
   sets `AETH_ALLOW_MISSING_KERNEL=1`, so every native-gated file SKIPS inside
   it. Native coverage comes only from `native:test` / `native:test:electron`;
   wrapping `check:static` in `with-msvc.ps1` makes C++ compile, not the native
   gate run.
2. **Turbo caches the `test` task** — a later run can report `54/54` while
   executing nothing. Require `Cached: 0 cached` before a static row enters
   evidence.
3. **`with-msvc.ps1` inherits the SYSTEM Node** (v25, which `engines` rejects)
   unless the pinned Node 24 and the RECIPES XDG/`CI` variables are exported
   BEFORE invoking it. And `CI=true` makes `gh` refuse keyring auth — export
   `GH_TOKEN=$(gh auth token)`.
4. **RAM LAW.** Serialized lanes only (`TURBO_CONCURRENCY=1`, vitest
   `--maxWorkers=1`), ONE verification chain at a time, and reap orphaned
   node/vitest/Electron-under-test processes. Never kill the founder's Claude
   desktop or Ollama.
5. **Remote CI is billing-disabled; local gates are the only proof.** Ignore red
   PR checks.

## How any session continues (cold-start execution order)

1. Read `AGENTS.md`, then this file, then the packet named above.
2. If a capability is **active** in `docs/context/manifest.json`, continue it
   exactly within its packet. Do not broaden it.
3. If no capability is active, continue the current integration tranche under
   its packet. Deferred capabilities are not queue entries. Once the tranche
   is complete and no blocker exists, **admit the next queued capability** (the
   `capabilities.queued` array is the order):
   create `cap/<CAP-ID>-<slug>` from the current pushed trunk tip, move the
   packet `queued/` → `active/`, fill in branch/base/PR fields, register it in
   the manifest as active, and open the PR with `pnpm context:pr`.
4. Implement only what the packet owns; freeze; run the packet's verification
   matrix at the frozen tip; record evidence; merge; archive the packet; close
   the issue; delete the branch; update this file — all as one closure sequence.
5. Run `pnpm context:check` before presenting anything as complete.

## Execution queue

**The shell gate is released and CAP-139 is delivered/#139 closed.** The
qualified product implementation is `e5d47c8b` (CAP-140), landed at trunk tip `ee906930`. **No capability is active.** Phase 2A resumes at #141 Loft, which must be re-grounded at current trunk and admitted through PROTOCOL section 2 first; Phase 2B is #147 Construction geometry, #142 Fillet, #143 Chamfer,
#148 Boolean, #149 Shell, #150 Press Pull, #151 Transform (parallel only where
ownership is disjoint); Phase 3 is #144–#146 patterns; Phase 4 is #155–#157
Surfacing, #158–#161 Sheet Metal, #162 Assemblies; Phase 5 is #168 BOM → #167
Drawings, #164 CAM, #165 Simulation, #163 Harness, #166 Mold. #152 means
professional catalog/component placement; #153 means viewport snap-mating; full
#154 Thread remains deferred until its core/Hole/joining/drawing/CAM consumers
need it. CAP-030 standards/designation data is valid early substrate.

**Optional external activation is not part of the current product queue.**
Signing identities, hosted feeds, and paid services are activated only when
their real external prerequisites exist; no product capability waits on them.

**The product roadmap is not a release backlog.** Packaged reachability is
qualified alongside each capability; signing, hosted feeds, and public-service
activation are handled only when their external prerequisites exist.

1. **Agent:** delivered. CAP-022 wired the panel; CAP-023 ruled the runtime
   deviation as **ADR-017** and enforced it.
2. **Product depth: delivered.** CAP-025 delivered the authoritative timeline
   under ADR-018; CAP-026 delivered named parameters and raw expression
   editing; CAP-027 delivered kernel-evidenced measurement; CAP-028 delivered
   the model outliner (list/select/hide/show every body); CAP-029 delivered
   the template engine and all ten first-set templates.
3. **Programs: delivered.** CAP-030 delivered the joining-J0 thread-designation
   parser/resolver + preview.
4. **Commercial foundation: CAP-031 delivered** (release settings UI, #56 —
   diagnostics consent + update channel, license-token work deferred to
   Follow-on candidates).
5. **CAP-033 delivered** (multi-window re-land, #58 — queue-order exception,
   founder-directed 2026-07-29). Re-grounding
   found the multi-window isolation architecture (per-window
   `DocumentLifecycle`/registry) already fully built by D-020; the only real
   gap was a reachable "New Window" control and a packaged two-window gate
   proving lock refusal/close-one-survives/commit isolation, both now shipped.
6. **CAP-039 DELIVERED** (#94, merge `5e1f6c1`, PRs #122 + #124) — the final
   shell consolidation, run after every product surface as intended. One
   frameless 48 px title row carries the whole command set (OS title bar and
   menu bar both retired, `titleBarStyle: "hidden"` + a `titleBarOverlay` at
   the same height); File/Import/Export are dropdowns; every panel — Operations,
   Outliner, Assistant, Printer, Settings, and the contextual Dimensions and
   Sketch editors — is a registration in ONE governed inspector dock behind a
   right-edge instrument spine, with a one-active-panel budget replacing the
   independently draggable floating windows.
7. **Current program:** #138 Extrude and #139 Revolve are delivered; #140
   Sweep is active. The remaining Phase 2 core modeling lanes run through
   #151, then surfacing, sheet-metal, assembly, drawings, CAM, simulation,
   harness, mold, and BOM per `docs/plan/TRUE_NORTH_DOMAIN_PROGRAM.md`.

Governance: `GOV-002` plan-corpus reconciliation is merged; `GOV-005`
differential fuzzing (`docs/work/governance/`) remains queued and does not block
the product queue.

**GOV-003 MERGED (`fe471ad`).** ADR-015 makes six OCCT-robustness rules law:
the corpus intake rule (`fixtures/README.md`), PROTOCOL §6a (a kernel-touching
packet MUST state corpus coverage and tolerance budget, and a review that finds
them missing is a review defect), and §2 per-operation tolerance budgets as a
native gate. **Budgets do not compose by `max()`:** chamfer then fillet reaches
1.0633e-4 mm, above the kernel linear tolerance both members respect.

## Explicitly forbidden now

- creating more than one active capability per owned surface;
- pre-creating branches for queued capabilities;
- reviving any closed, archived, or discarded branch;
- hidden kernel expansion before visible product recovery;
- reading legacy PR prose, diaries, or transcripts as current instructions;
- working in any checkout other than `C:\dev\Aethalgard_CAD`;
- claiming historical green runs as evidence for a newer head;
- opening new GitHub issues — the queue above is fixed and closed. **This
  includes the protocol §3 "packet split" exception**: CAP-029 self-invoked
  it at admission (queuing #115/CAP-041) and the founder ruled that was not
  authorized, reversing it the same day. Do not self-invoke a split on an
  admission-time read alone — attempt the real design first; a scope that
  looks like it needs new engine capability from a skim may not once actually
  built (CAP-029's own seven "deferred" templates all shipped on the
  unmodified engine).
