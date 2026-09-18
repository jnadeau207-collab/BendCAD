# ADR-007: Standalone stdio C++ kernel host

Date: 2026-07-19
Status: accepted (founder decision, 2026-07-19 — records a decision shipped
incrementally since 2026-07-12 and mandated for the record by the
realignment audit, `docs/audits/2026-07-17-plan-realignment.md` §4.B)

## Context

`docs/plan/01-geometry-core/06-kernel-host-process.md` §1–§3 normatively
specifies the kernel host as an **Electron `utilityProcess.fork()` child**
running `packages/kernel-host/dist/main.js`, which loads an N-API module
(`occt_module.node`) linking OCCT. §3 is titled "Why in-process N-API inside
a dedicated process (not raw sidecar C++ binary)" — the raw C++ sidecar is
the explicitly rejected alternative. The app-shell plan repeats the choice:
`docs/plan/04-app-shell/01-process-topology.md` §1 lists P3 `kernel-host` as
`utilityProcess` (Node.js) loading `@aeth/occt-native`, with a note that
`utilityProcess` was chosen over plain `child_process` for Chromium-integrated
crash reporting and `MessagePortMain` renderer↔kernel ports.

What shipped is the rejected alternative, and it shipped for reasons the
plan predates:

- The kernel host is a **standalone C++20 executable**, `aeth-kernel-host`,
  built from `native/kernel-host/` by CMake (no cmake-js, no N-API, no Node
  in the kernel process). Dev builds install to
  `.native-cache/kernel-host-install/bin/`; packaged builds ship it under
  `resources/native/kernel-host/bin/` (`apps/desktop/src/main/kernel-runtime.ts`).
- It is spawned with **`node:child_process.spawn`**
  (`packages/kernel-client/src/native-kernel-client.ts`), not
  `utilityProcess.fork`, by the `KernelSupervisor` running in the Electron
  main process (`apps/desktop/src/main/kernel-runtime.ts` composes it).
- It speaks the **ADR-001 framed stdio protocol**: length-prefixed UTF-8
  JSON control frames on stdin/stdout, binary AEMB mesh packets on a
  dedicated inherited pipe at fd 3 (`ABM1` framing), any framing/UTF-8/JSON/
  schema/magic/length/checksum failure connection-fatal. The wire contract is
  the strict zod schema set in `packages/geometry-contracts`
  (`kernel-protocol.ts`), and the health handshake carries the ADR-002 build
  manifest identity.

This ADR records why the plan's choice was abandoned, what was lost, and
what compensates — so doc 06 §1–3 stops silently contradicting shipped code.

Why the standalone executable won:

1. **Build identity (ADR-002).** The kernel must be reproducible and
   crash-identifiable from a pinned manifest. An N-API module couples the
   kernel binary to Electron's Node ABI: every Electron major bump (≤ every
   16 weeks per plan 04) would re-link the geometry kernel and change the
   binary whose behavior ADR-002 pins. A standalone executable's identity is
   exactly the OCCT manifest + compiler + sources; Electron upgrades cannot
   touch it.
2. **NG-1 protocol findings (ADR-001).** The framing audit concluded that
   corruption must be connection-fatal and that control and mesh streams
   must be separate pipes with bounded decoders. That discipline is natural
   over stdio/fd-3 and testable with any process harness; it has no
   equivalent formulation over `MessagePort` structured clone, where framing
   is implicit and cannot be independently fuzzed.
3. **Verification without Electron.** The same executable is driven by the
   C++ unit suites, `pnpm native:test`, the kernel-client integration suites
   (gated on `AETH_KERNEL_HOST_PATH`), and the NG-2 reference tournament
   (`tools/reference-tournament`) — including the ADR-005 qualifying run —
   with no Electron or display in the loop. The tournament's 100k-case
   corpus generation would have been impractical against a module loadable
   only inside an Electron utility process.
4. **Windows-first (ADR-0001).** One MSVC CMake target with DLLs beside the
   executable is materially simpler to build, sign, and debug on Windows
   than an Electron-ABI `.node` plus prebuild plumbing.

## Decision

The Aethalgard kernel host is a standalone, Node-free C++ executable
(`aeth-kernel-host`) owned by `native/kernel-host/`, spawned and supervised
via `child_process.spawn` by `KernelSupervisor` in
`packages/kernel-client`, speaking the ADR-001 stdio protocol validated by
`packages/geometry-contracts`. There is no `packages/kernel-host` JS
package, no `occt_module.node`, and no N-API surface. Plan 06 §1–§3 (and the
P3 rows of plan 04) are superseded on process mechanics; their _semantic_
content — crash isolation, single-threaded geometry determinism, the typed
service API's intent, cancellation, budgets, the error-taxonomy program —
remains normative and is being landed against the stdio host.

What is lost, explicitly:

- **Chromium crash reporting.** `utilityProcess` children get Crashpad
  minidumps and structured exit-reason codes for free. A `child_process`
  spawn gets an exit code/signal only. Kernel crash _containment_ is intact;
  crash _forensics_ (minidump capture + symbolication for a non-Chromium
  process) becomes an explicit Tranche-F obligation and must not be assumed
  from plan 04's Crashpad rows.
- **`MessagePortMain` renderer↔kernel ports.** With no utility process
  there is no Electron port endpoint to hand the kernel; direct
  renderer↔kernel transport is off the table. The companion divergence —
  all mesh traffic proxying through main — is recorded in ADR-009 §2, with
  its perf-budget re-measure trigger.
- **In-process Node async plumbing.** The plan's Promise-native N-API
  surface is replaced by the request/response/cancel frame protocol and the
  TS-side `KernelRequestQueue`.

What compensates:

- **Supervision and restart** (`packages/kernel-client/src/supervisor.ts`):
  spawn + 2-phase health handshake, liveness, crash-loop breaker with
  exponential backoff, and a monotonic **process epoch** bumped on every
  restart so epoch-local geometry tokens can never survive a crash
  (ADR-003; consumers observe `ready`/`recovered`/`dead`).
- **Fail-closed transport** (ADR-001): both decoders bounded; any corruption
  kills the connection and the process rather than resynchronizing; binary
  packets are correlated to control descriptors by stream sequence and
  CRC-32 and reconciled by `validateMeshDelivery`
  (`packages/geometry-contracts/src/mesh-payload.ts`).
- **Journaled document authority + replay.** The document (the only
  non-derived state) lives in the Electron main process behind
  `apps/desktop/src/main/document-service.ts`'s §2.2 transaction path —
  proposal boundary journaled before evaluation, committed transactions
  fsync'd before acknowledgment. A kernel crash therefore loses nothing the
  user made: recovery is supervisor respawn + re-evaluation of the committed
  document (the host is stateless per request today; the warm replay cache
  is designed in `docs/design/2026-07-17-replay-cache.md` with a
  warm==cold byte-identity gate).

## Consequences

- Doc 06 §1–§3 carry in-place supersession notes pointing here; §5.1's
  `MessagePortTransport` "Impl A", §10.1's `utilityProcess.fork` supervisor
  sketch, and §12's Crashpad note read under this ADR (stdio is the only
  transport; crash forensics are Tranche F). The N-API marshalling rule in
  §2 is void — nothing crosses N-API because N-API does not exist here.
- Plan 04's P3 rows (`01-process-topology.md` §1, `00-overview.md` decision
  2/7) carry correction notes; the shell-side siblings of this decision (no
  IPC codegen, no direct renderer↔kernel ports, proxied mesh traffic) are
  ADR-009's subject — cross-reference, not duplicated here.
- The kernel-host executable remains launchable by plain test harnesses;
  every new kernel capability must stay provable via
  `AETH_KERNEL_HOST_PATH`-gated suites without Electron.
- Kernel crash minidump capture/symbolication is added to the Tranche-F
  hardening scope (it is no longer inherited from Electron).
- `kernelExecutable()` resolution order in
  `apps/desktop/src/main/kernel-runtime.ts` is the single sanctioned spawn
  path: in an UNPACKAGED (dev/test) build the `AETH_KERNEL_HOST_PATH` override
  is honored FIRST, then the `.native-cache` install; in a PACKAGED build the
  override is ignored entirely (`resolveKernelHostOverride` returns `undefined`
  when `isPackaged`) and only the bundled `resources/native` path is trusted.
