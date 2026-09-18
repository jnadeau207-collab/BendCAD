# ADR-009: App-shell IPC divergences — hand-audited preload, proxied mesh traffic, spawned kernel

Date: 2026-07-19
Status: accepted (founder decision, 2026-07-19 — records three linked
shipped divergences; mandated for the record by
`docs/audits/2026-07-17-plan-realignment.md` §4.B bullets 1–3)

## Context

Three app-shell decisions in `docs/plan/04-app-shell/` were abandoned in
code without a record. They are one set — they share a root cause (the
standalone stdio kernel host, ADR-007) and a shared discipline (a small,
hand-audited, fail-closed IPC surface):

1. **No IPC codegen.** Plan 02 §3 mandates `packages/ipc-contracts` (Zod
   channel declarations) + `tools/ipc-codegen` generating the preload
   bridge, per-process routers, JSON Schemas, and a wire-snapshot CI gate —
   and calls hand-writing preload code "forbidden" (§3.2). Neither package
   was ever built. The shipped preload is hand-written
   (`apps/desktop/src/preload/index.ts`), a thin frozen
   `window.aethalgard` bridge of `ipcRenderer.invoke` wrappers.
2. **No direct renderer↔kernel `MessagePort`.** Plan 00 §2 decision 5 and
   plan 01 §1.1's diagram put bulk mesh traffic on direct renderer↔kernel
   `MessagePort` pairs so megabytes never traverse main. Shipped: **all
   mesh traffic proxies through main** — the renderer invokes
   `aeth:geometry:evaluate-document`; main drives the kernel queue,
   reconciles every AEMB2 packet, and returns bodies + packet
   `ArrayBuffer`s over the ipcMain/ipcRenderer bridge by structured clone
   (`apps/desktop/src/main/geometry-ipc.ts`, `document-evaluation.ts`).
3. **P3 is `child_process.spawn`, not `utilityProcess`.** Plan 01 §1's P3
   row and its note ("P3 is `utilityProcess`, not a plain `child_process`
   fork") are inverted by ADR-007: the kernel host is a standalone C++
   executable, which cannot be a `utilityProcess` (that API forks Node
   entry points). See ADR-007 for the rationale and the lost/compensating
   trade — not restated here.

## Decision

### 1. Hand-audited preload instead of codegen — permanent at the current surface, with a stated re-open trigger

The codegen machinery existed to keep a ~40-channel, five-link surface
honest. The shipped surface is one link (renderer↔main) and ~14 channels in
four domains (document, geometry, manufacturing export — 3MF/STEP/STL — and
printer-profile / window-chrome). At that size, generated indirection costs more than it
protects, and the plan's real goals are met by construction:

- **Schema-first validation stands.** Every renderer payload is zod
  `.strict()`-validated at `ipcMain.handle`
  (`document-ipc.ts` `commitRequestSchema`; every handler maps failures
  into the serializable `DocumentIpcError` envelope, never a rejection).
- **The contract has one source of truth.** Channel names + types live in
  `apps/desktop/src/shared/*-ipc.ts` — types and `Object.freeze`d
  channel-name constants only, importable from both bundles, no
  Electron/Node imports.
- **The bridge is guarded and audited.** Every privileged channel goes
  through `guardedIpcHandle` (`ipc-guard.ts`, fails closed until
  configured: top-frame, app-owned window, trusted origin);
  `apps/desktop/test/preload-artifact.test.ts` asserts the built preload
  is sandbox-compatible CommonJS and exposes exactly the declared
  channels on both sides; `ipc-guard.test.ts` pins the trust gate.

**Re-open trigger:** if the channel catalog approaches the plan's full v1
surface (multi-window/multi-document, agent/model/settings/license
domains — order tens of channels) or a second bridge consumer appears,
mechanize then. Until that trigger, hand-writing this preload is the
sanctioned pattern (the shared-contract + guard + artifact-test discipline
is mandatory for every new channel), and plan 02 §3.2's "forbidden" no
longer binds.

### 2. Mesh traffic proxies through main — deferred-until-perf-data, not permanent

The direct-port design assumed a `MessagePortMain`-capable kernel process;
ADR-007 removed that endpoint, and the fail-closed packet gate
(`validateMeshDelivery` — CRC, counts, epoch, stream-sequence uniqueness)
lives with the supervisor in main, which would otherwise be bypassed. With
today's single scratch document and foundation-scale meshes, the proxy is
correct and simple: renderer → main invoke → kernel queue → reconciled
packets → structured-clone response.

The plan attached budgets that this path has **not yet been measured
against**:

- viewport plan (`docs/plan/05-viewport/02-geometry-pipeline.md` §1):
  ≤ 6 ms for a 30 MB packet crossing a process boundary;
- plan 04 `02-ipc-architecture.md` §9.7: control-plane RTT p95 ≤ 5 ms under
  editor load; mesh GPU-visible latency p95 ≤ 20 ms/MB.

The proxy adds one extra structured-clone hop (kernel→main buffer, then
main→renderer clone) versus the planned single hop. **Re-measure trigger
(binding):** when the perf harness lands (plan 04 `11 §5` / viewport
`11 §6`), or before shipping interactive re-tessellation during drags
(≥ 15 Hz preview), or before any document class whose full sync exceeds
~10 MB of packets — whichever comes first. If the proxied path breaches
the budgets, the recorded fallback is a dedicated bulk channel that
bypasses the invoke round-trip (main→renderer push after main-side
reconciliation), and only if that still fails, a broker `MessagePort`
carrying already-reconciled packets. The AEMB2 format itself is
transport-agnostic (ADR-008) and does not change in any of these outcomes.

### 3. `child_process.spawn`, not `utilityProcess` — permanent

Decided by ADR-007 (standalone C++ host). Consequences for the shell:
supervision, backoff, crash-loop breaking, and epoch bumping are
`KernelSupervisor`'s job (`packages/kernel-client`), not Electron's; kernel
crash minidumps are a Tranche-F obligation. Plan 01's P3 row is corrected
in place.

## Consequences

- Supersession pointers are added in place to plan 04
  `00-overview.md` (decisions 2, 4, 5, 7), `01-process-topology.md`
  (P3 row + §1 notes), and `02-ipc-architecture.md` (status header, §1
  transport map, §3.2 artifact table, §4). No "forbidden"/"mandated"
  sentence in plan 04 contradicts shipped code without an adjacent pointer.
- The rest of plan 02 (envelope protocol, credit backpressure, coalescing,
  cancellation semantics, channel catalog, budgets) remains the normative
  _design vocabulary_ for the surfaces that do not exist yet; each lands
  against this ADR's transport reality when built, and §9.7's budgets stay
  binding on whatever transport serves them.
- Every new privileged channel MUST ship with: a `src/shared/*-ipc.ts`
  contract module, zod validation at the boundary, `guardedIpcHandle`
  registration, and coverage in the preload-artifact channel list — this
  is the enforcement that replaces codegen drift-checking.
- The two open triggers above (preload mechanization; mesh-path
  re-measurement) are owned by the tranche that first trips them, and the
  measurement result must be recorded against this ADR.
