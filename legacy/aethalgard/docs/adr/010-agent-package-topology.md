# ADR-010: Agent package topology — agent-contracts / agent-orchestrator / model-runtime

Date: 2026-07-19
Status: accepted (founder decision, 2026-07-19 — records the shipped
topology; mandated for the record by
`docs/audits/2026-07-17-plan-realignment.md` §4.B bullet 6)

## Context

`docs/plan/03-ai-agent/10-source-tree.md` mandates three packages —
`packages/ai-runtime` (docs 01, 07), `packages/model-manager` (doc 02),
`packages/agent-core` (docs 03–06, 09) — with eslint-boundary rules
(`agent-core → ai-runtime, model-manager, @aeth/op-graph, @aeth/kernel-api`;
`ai-runtime → model-manager (types only)`; `model-manager → nothing`).

None of those packages exists. What shipped (with real code landed:
`SidecarModelPort` 8482f02, context assembler 5c81de2) is a three-way split
along a different axis — **contracts / engine / transport** — matching the
repo-wide ports-and-adapters seam rather than the plan's
runtime/manager/agent axis:

- `packages/agent-contracts` — pure wire/zod contracts, isomorphic, no I/O.
- `packages/agent-orchestrator` — the isomorphic orchestration engine;
  deterministic by injection (no Date/crypto/network), all capabilities
  arriving through ports.
- `packages/model-runtime` — the node-target transport: llama-server
  supervision, loopback HTTP client, model-pack manifest + signing,
  device/memory arbitration.

The plan's axis put the sidecar client and the orchestrator in separate
packages joined by wide concrete interfaces, and split model _management_
from model _runtime_ although both own the same artifacts. The shipped axis
keeps everything the model can see or say in one dependency-free contracts
package, keeps the engine runtime-isomorphic (testable in node vitest with
`DeterministicFakeModel`, embeddable anywhere), and gives node-only concerns
exactly one home.

## Decision

The agent subsystem is these three packages, permanently. Never create
`packages/agent-core`, `packages/ai-runtime`, or `packages/model-manager`.

### Chapter-to-package mapping (docs 01–09 remain semantically normative)

| Plan doc (03-ai-agent)    | Planned home  | Shipped home                                                                                                                                              |
| ------------------------- | ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 01 sidecar architecture   | ai-runtime    | `model-runtime` (`supervisor.ts` lifecycle, `client.ts` loopback HTTP, `server-contract.ts` strict/loose payload schemas, `device.ts` probe)              |
| 02 model manager          | model-manager | `model-runtime` (`manifest.ts` signed pack manifest, `signature.ts` Ed25519); download/store machinery is unbuilt and lands in `model-runtime` when built |
| 03 tool surface           | agent-core    | `agent-contracts` (`tools.ts` operation/meta tool registries, `wire-schema.ts` grammar-safe emitter)                                                      |
| 04 orchestration loop     | agent-core    | `agent-orchestrator` (`orchestrator.ts`, `run-checkpoint.ts` §8.1, `proposals.ts` §8.2–8.3, `sidecar-model-port.ts`, `fake-model.ts`)                     |
| 05 context assembly       | agent-core    | `agent-orchestrator` (`context-assembler.ts`); feedback envelopes in `agent-contracts` (`feedback.ts`)                                                    |
| 06 vision integration     | agent-core    | unbuilt; will land in `agent-orchestrator` (engine) + `model-runtime` (transport)                                                                         |
| 07 VRAM budgeting         | ai-runtime    | `model-runtime` (`memory.ts` reservation ladder)                                                                                                          |
| 08 LoRA pipeline          | ai-runtime    | unbuilt; artifacts ride the `model-runtime` pack manifest                                                                                                 |
| 09 reliability            | agent-core    | split: typed failure envelopes in `agent-contracts` (`feedback.ts`), semantic/structural validation in `agent-orchestrator` (`structural-assessment.ts`)  |
| 10 §4.1 transcript record | agent-core    | `agent-contracts` (`transcript.ts` — replayable, append-only)                                                                                             |
| 11 IPC contracts          | app shell     | unchanged — app shell owns them (per ADR-009's channel discipline)                                                                                        |

### Dependency rule (replaces doc 10's, enforced today)

- `agent-contracts` → `@aeth/geometry-contracts`, `zod`. Nothing else.
- `agent-orchestrator` → `@aeth/agent-contracts`, `@aeth/document-model`,
  `@aeth/geometry-contracts`, `zod` at runtime. `@aeth/kernel-client` and
  `@aeth/model-runtime` are **devDependencies whose TYPES only** are
  imported (erased under `verbatimModuleSyntax`) through narrow structural
  ports — `ChatCompletionBackend` (`sidecar-model-port.ts`) and
  `KernelEvaluationSubmitter` (`kernel-document-port.ts`). The package is
  `aeth.target: "isomorphic"` and never takes a runtime dependency on a
  node-target package.
- `model-runtime` → `@aeth/child-process-env`, `zod`. Node-target; owns
  process spawn and loopback HTTP; grants the model no authority beyond
  inference.
- **Nothing imports Electron** (enforced by the root eslint
  `no-restricted-imports` layer: `packages/**` may not import `electron`).
  Constructing concrete clients (kernel queue, model server client) is
  exclusively an app-composition-root concern in `apps/desktop`.

The plan's `@aeth/op-graph` / `@aeth/kernel-api` names map to the real
`@aeth/document-model` (+ the wire schemas in `@aeth/geometry-contracts`)
and `@aeth/kernel-client` respectively.

## Consequences

- Doc 10 carries an in-place supersession note; its tree and `PlatformAdapter`
  injection sketch are historical. Docs 01–09 continue to be cited by module
  headers as semantic specs, with module paths mapped per the table above.
- The eslint-boundaries package rules doc 10 planned are subsumed by the
  root flat config's layered `no-restricted-imports` plus the
  isomorphic/node `aeth.target` convention; any future boundary tightening
  extends the root config, never per-package configs.
- Agent work that the plan filed under a dead package name must name the
  real package in new design notes and commits (established practice:
  `docs/design/2026-07-18-model-port-adapter.md`,
  `2026-07-18-context-assembler.md`, `2026-07-19-agent-proposal-preview.md`).
