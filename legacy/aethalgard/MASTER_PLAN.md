# Aethalgard — Product and Architecture Constitution

**Authority:** immutable product scope, architecture boundaries, and integrity gates  
**Current status:** see `PROJECT_STATE.md`  
**Current task:** see `docs/context/manifest.json`  
**Detailed requirements:** load selectively through `docs/spec/INDEX.md`  
**Founding full blueprint:** archived at `docs/archive/founding/MASTER_PLAN_2026-07-12.md`

## 1. Product directive

Aethalgard is a production desktop CAD-to-manufacturing system for serious mechanical design without traditional CAD ceremony.

It is not a box editor, block visualizer, mesh toy, AI wrapper, simplified demo, or disposable prototype. Early shapes are conformance fixtures proving the final architecture; they do not bound the product.

The product bar is Fusion parity or better across the full CAD-to-manufacturing
stack. Aethalgard is not a consumer “clips and bins” product. Its
Squarespace-grade direct-manipulation surface is the accessibility layer for
normal 3D-printer users, while professional sketching, parametric history,
assemblies, drawings, CAM, and the other manufacturing domains remain first-
class product scope.

The finished system provides:

- precise direct manipulation of editable parametric geometry;
- a broad professional mechanical modeling catalog;
- professional multi-part assemblies with reusable definitions and occurrences, mates, joints, kinematics, configurations, exploded states, BOM, interference, clearance, and collision-aware motion;
- durable semantic references across model and assembly revision;
- a local agent operating the same typed transactions as the human editor;
- STEP, 3MF, mesh, printer-profile, preflight, and slicer workflows;
- a professional multi-plate print workspace with true bed geometry, several simultaneously visible build plates, print-only instances, deterministic arrangement, spatial preflight, and per-plate output;
- crash recovery, migrations, diagnostics, signed distribution, and commercial application hardening;
- a premium, accessible, geometry-first user experience.

The primary experience is direct manipulation with a light, non-intrusive
history surface. The authoritative operation timeline is visible when useful;
parametric history is never treated as an invisible implementation detail. A
searchable command surface (including a Fusion-style S-key entry point) may
coexist with the direct surface, and a settings-gated ribbon pop-out is allowed
without becoming required primary chrome.

The authoritative assembly architecture and implementation program is `docs/plan/07-assemblies/00-assembly-system.md`. Assemblies are required product scope, not an optional post-release expansion.

The authoritative multi-plate manufacturing architecture and implementation program is `docs/plan/06-print-pipeline/09-multi-plate-print-workspace.md`. Visible, editable, persistent print plates are required product scope, not a slicer-only or post-release convenience.

## 2. Architectural law

### 2.1 Authority boundaries

- **Electron main/document authority** owns committed documents, transactions, undo, journals, checkpoints, file lifecycle, per-window services, and the persisted print-layout graph.
- **Kernel host** is a disposable OCCT evaluator. Kernel objects are never the durable document.
- **Assembly host** is a disposable constraint/kinematics/collision evaluator. Solver objects, collision worlds, and warm-start state are never the durable document.
- **Renderer** owns presentation, camera, hover, gesture state, print-bed overview spacing, and manipulation previews. It emits typed intent and never edits committed state directly.
- **Agent orchestrator** assembles context and proposes typed transactions. It cannot bypass validation or gain arbitrary file, shell, process, or network authority.

Humans and the local agent are equal operators of the same typed document and
transaction path. Durable history, topology, and intent live in the document
graph; kernel and solver instances are evaluators only.

- **Model runtime** performs inference behind a replaceable local-only interface.
- **Import/export workers** operate behind validated, resource-bounded contracts while preserving original imported data.

### 2.2 One mutation path

Manual gestures, forms, templates, imports, assembly authoring, print-plate authoring, and agent actions all use one path:

1. validate the typed request;
2. resolve document, occurrence, print-source, and semantic topology references;
3. create a proposed graph revision;
4. journal the proposal boundary;
5. evaluate geometry and assembly state in their disposable hosts;
6. validate bodies, semantic probes, solve status, print layout, and requested analysis;
7. publish a proposed render epoch;
8. commit or abort atomically;
9. append undo and provenance;
10. schedule durable recovery state.

No surface may mutate around this path.

### 2.3 Geometry identity

Topology indices and tokens are evaluation-epoch local. Durable references are semantic queries bound to operation provenance and verified against class, adjacency, orientation, measure, and set intent.

Resolution is explicit: proven entity, proven set, missing, ambiguous, or invalidated. Only proven results evaluate automatically. Fingerprints may offer repair candidates; they may never silently substitute geometry.

### 2.4 Assembly identity

A component definition owns geometry; a component occurrence owns one placement. Occurrence identity is a durable UUID/path, never a body-array ordinal, mesh row, or solver handle. An assembly endpoint scopes a durable definition-level selector to one occurrence. Component placement never consumes or rewrites part geometry.

### 2.5 Print-layout identity

A print plate and print instance own manufacturing placement only. They reference durable document-body or assembly-occurrence sources and never mutate CAD geometry or assembly poses. Print-instance identity is a UUID, never a body ID alone, plate ordinal, viewport pick row, or slicer-object index. Persisted poses are plate-local; the transforms used to spread several beds across the viewport are presentation-only and may never reach preflight, slicing, or export.

A saved plate binds to an immutable resolved printer/bed snapshot and expected profile revision. Mutable global profile selection cannot silently resize or reinterpret committed print jobs.

### 2.6 Durable documents

`.aeth` is a versioned container whose operation, assembly, and print-layout graphs remain authoritative. It also carries metadata, previews, recovery tessellation, evaluation manifests, semantic probes, migrations, retained source imports, cached external-component snapshots, and resolved plate snapshots needed to open visibly and diagnose failed replay.

### 2.7 Geometry transport

Control traffic uses versioned typed IPC. Large geometry uses a versioned binary packet carrying positions, normals, triangles, analytic topology ownership, edge wires, vertices, bounds, epoch identity, units, quality metadata, and optional analysis channels. Repeated assembly occurrences and print instances share source geometry and carry separate rigid transforms and durable occurrence/instance identity.

## 3. Integrity gates

1. **Mutation integrity:** failure or ambiguity may occur; silent mutation of the wrong geometry, occurrence, plate, or print instance may not.
2. **Crash integrity:** committed work survives renderer, kernel, assembly, agent, worker, export, and arrangement termination.
3. **Replay integrity:** saved operations, assembly relations, and print layouts reproduce semantically equivalent bodies, poses, plate placements, and profile meaning within declared tolerances for the pinned build.
4. **Agent integrity:** every AI mutation is valid, attributable, previewable, reversible, and evaluated through the normal transaction path.
5. **Viewport integrity:** displayed epoch, occurrence/print instance, picked topology, plate, callouts, and committed revision agree.
6. **Assembly integrity:** mate/joint endpoints, solved poses, remaining DOF, conflicts, and collision state agree; no stale or ambiguous relationship evaluates silently.
7. **Print-layout integrity:** plate-local coordinates, displayed overview transforms, profile snapshots, source revisions, spatial validation, and exported transforms agree; arrangement never silently drops, rotates, scales, or reassigns an instance.
8. **Analysis integrity:** interactive estimates and exact B-rep interference/clearance results are never conflated; incomplete analysis or preflight never reports clear.
9. **Export integrity:** units, transforms, identities, hierarchy, plate membership, and dimensions survive independent downstream import.
10. **Resource integrity:** editor interaction wins over kernel, assembly solving, arrangement, rendering, import, inference, and background analysis throughput.
11. **Accessibility integrity:** essential operations have visible keyboard and non-drag paths.
12. **File integrity:** unknown or failed replay degrades visibly without discarding the original graphs or recovery representation.
13. **Product-truth integrity:** capability is not called complete until it is reachable and qualified in the packaged application.

## 4. Cumulative implementation tranches

- **Runtime spine:** secure process topology, document authority, IPC, native hosts, supervision, binary transport, viewport, logging, deterministic fixtures, and recovery.
- **Geometry and document foundation:** complete v1 modeling grammar, semantic reference production and consumption, replay, undo, persistence, and pathological geometry tests.
- **World-class editor and viewport:** selection, picking, handles, snapping, dimensions, camera, inspection, analysis, accessibility, and polished product composition.
- **Professional assemblies:** reusable definitions/occurrences, mates, joints, deterministic solve and diagnosis, live kinematics, collision/interference/clearance, configurations, motion studies, exploded states, BOM, and structured interchange.
- **Agent-native CAD:** local model lifecycle, constrained tools, context assembly, proposal/review/repair flow, deterministic and real-model evaluation across part, assembly, and manufacturing work.
- **Manufacturing closure:** standards-compliant interchange, profiles, preflight, orientation, multi-plate placement and arrangement, spatial plate validation, per-plate slicer/output handoff, fit compensation, and physical validation.
- **Commercial hardening:** packaging, signing, updates, rollback, diagnostics, hostile-input defense, migration corpus, accessibility, licensing, and support tooling.

The tranches are cumulative. Nothing is thrown away after a demo.

## 5. Delivery law

- Research is just in time and ends in a recorded decision, implementation, and regression test.
- Plans do not outrank current product evidence.
- Hidden executor volume does not outrank user reachability.
- No silent fallback changes the user’s intended workflow.
- No completion claim reuses evidence from a different SHA.
- Existing AI branches are untrusted reconciliation inputs, not presumed capability branches.
- Each substantial capability has one task ID, one packet, one clean branch, one generated-body PR, one user-visible exit criterion, and one exact-tip evidence set.
- One capability per branch and PR unless inseparability is explicitly proven.
- Every task leaves the repository green or explicitly records the exact failing gate.
