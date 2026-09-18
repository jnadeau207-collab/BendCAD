# Aethalgard — Concept Research

_Compiled July 2026. Sources verified against current releases, papers, and product pages as of this month; links inline._

> **Historical research note (2026-08-08):** This document records founding
> evidence and hypotheses. Current product law is defined by `AGENTS.md`,
> `PROJECT_STATE.md`, `MASTER_PLAN.md`, and
> `docs/plan/TRUE_NORTH_DOMAIN_PROGRAM.md`. Any founding UX statement below
> that bans command search, hides history, or removes professional sketch
> capabilities is superseded.

> **[2026-07-19 status note.]** This is the founding research document, kept verbatim as the
> record of what the project was decided on. A later research pass —
> [`docs/research/01-domain-research-findings.md`](docs/research/01-domain-research-findings.md)
> (2026-07-12) — **falsified five specific claims below**; each carries an in-place
> bracketed correction pointer at the claim itself (market white-space §2.2 / F-18, the
> OCCT 8.0.0 pin §4.1 / F-03, the Manifold repair guarantee and lib3mf plan §4.3 /
> F-06+F-07, the model-tier recommendations §5.1 / F-13, and the UX-study generalization
> §6.1 / F-14). Where a correction has since been resolved by an accepted decision, the
> pointer names the ADR. Read the corrections as authoritative over this document.

Aethalgard is desktop CAD-to-manufacturing software with a Squarespace-grade
click/drag/drop/resize accessibility layer and a local agentic AI packaged
inside the download. This document is the founding research: where the market
gap is, how the thing should be architected, which model to bundle, what the
UX doctrine must be, how to package and ship it, and where the risks are.

---

## 1. Executive summary

- **The gap is real and nobody occupies it.** Between TinkerCAD (no dimensions, no parametrics, users outgrow it in months) and Fusion 360 (a professional paradigm with a months-long learning curve) there is essentially nothing mainstream. Every funded AI-CAD startup (Zoo, Adam, Camfer, Backflip) targets professional engineers with cloud-hosted, credit-metered AI. Every consumer AI tool (Meshy, Tripo, MakerLab) outputs non-parametric meshes — wrong representation for repair parts and brackets. No one ships **local agentic AI + drag-drop parametric CAD for normal people**.
- **The founder's instinct on code is correct: the agent should not write code.** The shared medium between the UI, the agent, and the geometry kernel should be a **JSON-serializable operation graph** (sketch → extrude → fillet → boolean...) replayed by the kernel. This is literally how every commercial parametric CAD works internally. Benchmarks show one-shot LLM code generation tops out at ~76–84% even for frontier models on _simple_ parts and collapses on complex topology; per-operation tool calls with kernel feedback after each step convert generation into a repairable loop.
- **The geometry kernel decision makes itself: Open CASCADE (OCCT) 8.0.** It is the only production-complete open kernel (booleans, fillets, STEP). Every credible open project sits on it. The two projects that tried to write new kernels for this exact concept — Fornjot and CADmium — are both dead as of 2025–2026.
- **The local model is a solved supply problem in mid-2026.** Apache-2.0 models (Qwen3.6, Gemma 4) now deliver strong agentic tool-calling in the 9B–27B range that fits consumer GPUs and Macs. Ship a three-tier download-on-first-run: Qwen3.5-9B (8 GB floor) → Gemma 4 26B-A4B (16 GB default) → Qwen3.6-27B (24 GB+ "high quality"), served by a bundled llama.cpp sidecar with grammar-enforced JSON tool calls, plus a CAD-domain LoRA adapter.
- **The UX mandate has empirical backing.** A 2025 comparative study supports
  direct spatial manipulation as an accessibility layer for novices. It does
  not justify removing professional sketch, constraint, feature, or history
  capabilities. Current law keeps those capabilities available through a
  direct-manipulation-first surface, a light visible timeline, and searchable
  command invocation.
- **Packaging: Electron + native OCCT module + three.js viewport** — the exact architecture Plasticity shipped commercially. Tauri is disqualified for the viewport by WebKitGTK/WKWebView graphics inconsistency. Thin installer, weights downloaded on first run, sized to detected VRAM.
- **Print pipeline: 3MF first, STEP as the pro differentiator.** All major slicers (Bambu Studio, OrcaSlicer, PrusaSlicer) now import STEP natively; 3MF is the de facto interchange format. Hand off via file association and `bambustudio://`-style deep links in v1; embed an AGPL slicing engine as an arm's-length sidecar later.

---

## 2. The market gap

### 2.1 The TinkerCAD ceiling and the Fusion cliff

**TinkerCAD** hit [100M lifetime users in Nov 2025](https://www.tinkercad.com/blog/celebrating-100m), adding ~10M/year — an enormous validated top-of-funnel for drag-drop CAD. But it has no parametric dimensions, no constraints, no fillets/chamfers, no assemblies, is cloud-only, and users report [outgrowing it within months](https://www.selfcad.com/blog/8-best-tinkercad-alternatives). It also has **no built-in generative AI as of mid-2026**.

The default graduation target is **Autodesk Fusion**, whose free personal tier is progressively squeezed ([10 active cloud documents, no simulation, view-only sharing](https://www.autodesk.com/products/fusion-360/personal)) and whose full parametric paradigm — sketches, constraints, feature timeline — is exactly the mental model novices fail at. Between the two sits almost nothing:

| Product                                                                                     | Position                                                    | Why it doesn't close the gap                                                              |
| ------------------------------------------------------------------------------------------- | ----------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| [Shapr3D](https://www.shapr3d.com/pricing)                                                  | Friendlier-than-Fusion direct+parametric hybrid (Parasolid) | Priced for professionals ($299/yr); free tier exports low-res STL only; no AI agent       |
| [SelfCAD](https://www.capterra.com/p/177228/SelfCAD/)                                       | Browser/desktop beginner modeler + slicer, ~$12/mo          | Low mindshare, no meaningful AI                                                           |
| [Plasticity](https://www.plasticity.xyz/buy)                                                | Desktop NURBS "CAD for artists," $175 perpetual             | Direct modeling without parametric history; targets concept artists, not functional parts |
| [Onshape free](https://www.onshape.com/en/pricing)                                          | Full parametric, cloud                                      | All documents public; pro paradigm; AI is docs-Q&A only                                   |
| [FreeCAD 1.1](https://blog.freecad.org/2026/03/25/freecad-version-1-1-released/) (Mar 2026) | Free, open, local, parametric                               | Engineer paradigm, famously steep; no AI                                                  |
| [Womp](https://womp.com/)                                                                   | Browser SDF "digital clay" for beginners                    | Organic/decorative; not dimension-accurate; STL/OBJ only, no STEP                         |

Recurring beginner complaints across all of them: (a) TinkerCAD can't do precise work; (b) everything else demands the sketch-constraint-feature mental model; (c) free tiers are strategically hobbled; (d) cloud dependence and subscription fatigue.

### 2.2 The AI-CAD landscape (mid-2026)

**Zoo (formerly KittyCAD)** is the closest architectural analog and the most important company to study. Their stack: own GPU geometry engine, **KCL** code-as-source-of-truth (every GUI action is a KCL edit), [Design Studio v1](https://zoo.dev/blog/zoo-design-studio-v1) (May 2025), and **[Zookeeper](https://zoo.dev/research/zookeeper)** (Jan 2026) — a conversational agent with engine-level tools that writes/executes/debugs KCL, inspects geometry via multi-view snapshots, and computes mass properties. It validates the agent-drives-CAD pattern end to end. But: [the geometry engine runs in Zoo's cloud and the web viewport is literally a video stream over WebSockets](https://zoo.dev/docs/faq); the AI is credit-metered ($20–$399/mo tiers); and they explicitly target "mechanical engineers and serious hardware teams."

The rest of the funded field has moved _away_ from consumers:

- **[Adam](https://adam.new/)** (YC W25, [$4.1M seed](https://techcrunch.com/2025/10/31/yc-alum-adam-raises-4-1m-to-turn-viral-text-to-3d-tool-into-ai-copilot/)) went viral with consumer text-to-CAD, then repositioned as an enterprise copilot inside Onshape/Fusion/SolidWorks — abandoning the maker wedge.
- **[Camfer](https://camfer.dev/)** (YC S24, $4.8M): AI mechanical engineer inside SolidWorks/Onshape. Pro-dependent, cloud.
- **[Backflip](https://www.backflip.ai/)** ($30M, Markforged founders): 3D-scan/mesh → parametric CAD reverse engineering. Genuinely hard tech, pro workflows.
- **Incumbents**: Fusion shipped [AutoConstrain and an NL assistant](https://www.engineering.com/3-new-ai-features-in-autodesk-fusion/); SolidWorks announced the [Leo engineering agent](https://develop3d.com/cad/new-solidworks-ai-agents-added-at-3dexperience-world/) (2026). All cloud, all aimed at existing professional users.
- **Mesh-generation players** ([Meshy](https://www.meshy.ai/pricing) — 10M+ users, integrated into MakerWorld; Tripo; [TRELLIS 2](https://trellis2.app/blog/what-is-trellis-3d) — open-source MIT 4B image-to-3D that runs locally): all output meshes with no editable dimensions, features, or accurate holes/threads/fits. Fine for figurines; wrong representation for the parts people actually need.

**"Vibe designing" is an active 2026 meme** with multiple micro-entrants (VibeCAD variants, [open-source agent-skills-for-CAD projects](https://github.com/rawwerks/VibeCAD)) but no funded player owns "agentic CAD for consumers."

> **[2026-07-19 correction — falsified by later research.]** The §1 "gap is real and nobody
> occupies it" framing and this section's white-space claim are stale: Zoo shipped the
> Zookeeper conversational agent and Autodesk exposed direct Fusion actions through MCP
> (May 2026). Those systems remain cloud/pro-oriented, which preserves the **local
> novice-to-physical-part** opportunity — but not the broader "nobody occupies AI CAD"
> claim. See `docs/research/01-domain-research-findings.md` **F-18**.

### 2.3 The audience and the strategic threat: Bambu Lab

Bambu sold [approximately 2.7 million printers in 2025 (approximately $1.5 billion in revenue, 37% of global sub-$2,500 shipments)](https://www.tomshardware.com/3d-printing/bambu-lab-overtakes-creality-as-the-worlds-top-selling-budget-3d-printer-brand). [MakerWorld has 10M MAU](https://3dprint.com/324181/bambu-lab-says-2025-was-a-breakout-year-10-million-monthly-users-and-real-business-growth/), 2.6M models, 83% one-year retention. What those users actually design/print: **organizers, repair/replacement parts, brackets, tech accessories, toys, fit-to-my-thing customizations** — precisely the simple-to-moderate parametric parts current AI handles well.

Evidence of demand for easy creation: [MakerLab's no-CAD tools reached ~310K users by end-2025](https://3dprintingindustry.com/news/bambu-lab-data-highlights-sustained-3d-printing-activity-and-creator-growth-on-makerworld-249474/); the [Parametric Model Maker](https://forum.bambulab.com/t/create-customizable-models-on-maker-world-using-parametric-model-maker/156334) (Fusion-powered parameter sliders on the model page) is a flagship feature; OpenSCAD customizers (Gridfinity, gear generators) stay wildly popular despite awful UX. **Millions print daily; only hundreds of thousands create. The blocker is CAD skill**, and the current fixes are cloud mesh-AI toys or sliders on someone else's model.

Bambu is assembling exactly Aethalgard's audience and could bundle "easy CAD" into its ecosystem — it is both the biggest competitive threat and the obvious distribution/integration target.

---

## 3. The core architecture decision: the agent does not write code

The founder's open question was: _"the agent writes the code for the cad — if we even need that. maybe we do not need code to create the step files — maybe there is another way."_

**There is, and it's the right way. The answer is a structured operation graph.**

### 3.1 Why not code

- **The benchmark evidence is unambiguous.** [CadQueryEval](https://github.com/danwahl/cadqueryeval) (July 2026 run, 60+ models): the best frontier models score ~76–84% on 25 _simple_ natural-language→CadQuery tasks; mid models 30–60%; hardest tasks 2–19%. [Text2CAD-Bench](https://arxiv.org/html/2605.18430) (2026): invalidity jumps to **68–93% on sweeps/lofts/shells**. Failure modes are non-watertight output, wrong volumes, topological errors — exactly the failures a consumer cannot diagnose. And these are frontier cloud models; a bundled 9–27B local model sits below them.
- **One-shot code is unrepairable; operations are.** When a script fails, the agent must debug a program. When _operation 7 of 9_ fails ("fillet failed on edge query X, max radius 1.2mm"), the kernel tells the agent exactly what to fix, and operations 1–6 stand. Research supports the loop approach: [CADFusion](https://arxiv.org/abs/2501.19054) shows visual/geometric feedback materially improves output; [CAD-Assistant](https://cadassistant.github.io/) (ICCV 2025) demonstrates a planner executing iteratively against a CAD API, adapting to evolving geometry state.
- **Code is an opaque medium for the UI.** If the source of truth is a script, every drag of a handle must round-trip through code parsing/rewriting (Zoo does exactly this with KCL, at significant engineering cost, for an audience that _wants_ code). Aethalgard's audience never wants to see code.

### 3.2 The operation graph is how CAD already works

Every history-based parametric system — SolidWorks, Fusion, Onshape, FreeCAD — is internally a **serialized DAG of feature/operation records replayed by the kernel**. Code is not the internal representation anywhere except code-CAD tools.

- **Onshape is the strongest prior art**: a Part Studio _is_ a feature list; their REST API creates and edits features as **structured JSON**; [FeatureScript](https://cad.onshape.com/FsDoc/) exists only to define new feature _types_, not to use the product. Features-as-JSON-over-API works at industrial scale.
- Geometry references in Onshape are **queries** — declarative selectors like "faces created by feature X" — not raw topology IDs. This matters enormously (see §3.4).

### 3.3 The recommended architecture

```
                    ┌──────────────────────────────┐
                    │   Operation Graph (JSON DAG)  │   ← single source of truth
                    │  sketch → extrude → fillet →  │      serialized to disk,
                    │  boolean → pattern → shell    │      one undo stack, diffable
                    └──────┬───────────────┬───────┘
              edits as ops │               │ edits as tool calls
                           │               │ (one op at a time,
                    ┌──────┴─────┐   ┌─────┴──────────┐
                    │ Drag-drop  │   │  Local agent    │
                    │ UI (handles│   │ (llama.cpp      │
                    │ , snapping)│   │  sidecar)       │
                    └──────┬─────┘   └─────┬──────────┘
                           │               │ kernel feedback after each op:
                           └───────┬───────┘ success / failure reason / bbox /
                                   │         mass properties / screenshot
                        ┌──────────┴──────────┐
                        │  OCCT 8.0 kernel     │  replays the graph →
                        │  (native module)     │  B-rep → tessellation,
                        └──────────┬──────────┘  STEP, 3MF
                                   │
                     viewport (three.js) · exporters
```

1. **The document is a JSON-serializable operation DAG** — node types: `sketch`, `extrude`, `revolve`, `fillet`, `chamfer`, `boolean`, `pattern`, `shell`, `hole`, `text`, `import` — with parameters and _query-based_ geometry references.
2. **The kernel replays the graph.** A resize is a parameter edit + replay. Every open success in this space (FreeCAD, Dune 3D, chili3d, CadQuery/build123d) is an operation-replay layer over OCCT.
3. **The agent emits operations as grammar-constrained tool calls, one at a time, with kernel feedback after each** (op succeeded / fillet failed on edge query / resulting bounding box / mass properties / rendered snapshot for vision models). This converts a ~76–84% one-shot proposition into a repairable loop — and it's the same pattern Zoo's Zookeeper validated, minus the cloud.
4. **The UI and agent are symmetric clients of the same graph**, so undo/redo, diffing, "explain what the AI did," and accept/reject-per-operation all fall out of one mechanism.
5. **Code becomes an optional export, not the medium.** An op-graph is trivially transpilable to build123d/KCL-style code for power users later; the reverse is not true.

### 3.4 The one deep engineering problem: persistent naming

Downstream operations that reference faces/edges break when upstream edits regenerate topology — [the classic persistent naming problem](https://www.researchgate.net/publication/221115805_A_survey_of_the_persistent_naming_problem). It is _the_ deep-work item of this architecture; everything else is assembly of mature parts.

Mitigations, designed in from day 1:

- **Selector queries as references, never raw topology IDs** — CadQuery selectors and Onshape queries prove the pattern: ">Z faces of extrude1", "edges created by fillet2". Queries are also far more natural for an LLM to emit _and_ for a UI click to record (a face-click records the query that selects that face, not its ID).
- **OCCT history/ancestry tracking** underneath; realthunder's topological-naming algorithm [shipped in FreeCAD 1.0 with negligible performance cost](https://www.ondsel.com/blog/toponaming-problem-is-history/), proving tractability.

### 3.5 Cautionary tales and living references

- **Dead: kernel-from-scratch.** [Fornjot was archived June 2026](https://fornjot.app/blog/shutting-down-fornjot/) after 6 years ("goals not reached"). [CADmium](https://github.com/CADmium-Co) — literally the "JSON operation graph in the browser" concept — was archived Sept 2025, killed by kernel-from-scratch ambition, **not** by the concept.
- **Alive: OCCT-based op-graph apps.** [chili3d](https://github.com/xiangechen/chili3d) (TS + three.js + OCCT-WASM, transaction history, 4.7k★ — AGPL-3.0, so reference-only or paid license), [Dune 3D](https://dune3d.org/) (one developer shipped a parametric OCCT app with STEP and fillets), [brepjs](https://github.com/andymai/brepjs) (modern TS API over an OCCT 8 WASM build, ~4 MB, active July 2026, ships a coding-agent integration — someone is already building agent-drives-CAD on this exact stack).

---

## 4. Geometry stack

### 4.1 Kernel: OCCT 8.0 — the only realistic choice

| Kernel                                                                               | License                      | July 2026 status                                                                                                                                          | Verdict                                                                                                  |
| ------------------------------------------------------------------------------------ | ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **[Open CASCADE 8.0](https://github.com/Open-Cascade-SAS/OCCT/releases)** (May 2026) | LGPL 2.1 + linking exception | Robust booleans, fillets/chamfers, STEP AP203/214/242 read+write; 8.0 adds graph-based topology, STEP reads up to 75% faster                              | **Use it.** Gnarly C++ API, occasional fillet failures on degenerate edges — the known tax everyone pays |
| [Truck](https://github.com/ricosjp/truck) (Rust)                                     | Apache-2.0                   | v0.6 Jul 2026, active                                                                                                                                     | **No production fillets**; not viable as sole kernel                                                     |
| Fornjot                                                                              | —                            | **Dead** (archived Jun 2026)                                                                                                                              | Cautionary tale                                                                                          |
| SolveSpace kernel                                                                    | GPLv3                        | Fragile NURBS booleans, no fillets                                                                                                                        | Only its constraint _solver_ is interesting                                                              |
| Parasolid / ACIS                                                                     | Commercial                   | ISVs report [component licensing consuming 15–17% of revenue](https://www.engineering.com/spatial-acis-cgm-and-the-future-of-geometric-modeling-kernels/) | Non-starter for a bootstrapped desktop app                                                               |
| Zoo's engine                                                                         | Proprietary, **hosted**      | Cloud-only command stream                                                                                                                                 | Architectural prior art; cannot be bundled                                                               |

Bindings: [OCP](https://pypi.org/project/cadquery-ocp/) (Python, what CadQuery/build123d use), [opencascade.js](https://ocjs.org/) (WASM, tracks OCCT 8), or a native N-API module for full performance and threading (recommended — see §7).

> **[2026-07-19 correction — falsified by later research.]** "OCCT 8.0" is not a
> production pin: OCCT published the `V8_0_0_p1` hot patch on 2026-06-17, and a version
> string fixes neither compiler, build options, nor ABI. The kernel identity is a **build
> manifest**, not a semantic version — resolved and shipped as
> `docs/adr/002-occt-module-and-build-identity.md` (manifest-pinned `V8_0_0_p1` build,
> `native/third_party/occt.manifest.json`). See
> `docs/research/01-domain-research-findings.md` **F-03** (and **F-04** on why bit-for-bit
> B-rep determinism was replaced by semantic determinism within a tolerance envelope).

### 4.2 Implicit/SDF modeling: a future operation node, not the foundation

[Fidget](https://github.com/mkeeter/fidget) (Rust, MPL-2.0, active, JIT-compiled SDFs, manifold meshing) is excellent for organic shapes, lattices, and blends that never fail a boolean — and mesh export is 100% sufficient for hobbyist printing. But implicit modeling loses faces/edges as first-class entities (breaking "click a face, add a hole") and **no open library does robust general SDF→STEP** ([even nTop complexity-gates this](https://support.ntop.com/hc/en-us/articles/7323484481555-How-to-export-geometry-as-a-CAD-part-STEP-or-Parasolid)). Right role: an optional lattice/organic node inside the B-rep pipeline (implicit → [Manifold](https://github.com/elalish/manifold)-meshed body), post-v1.

### 4.3 Formats and print pipeline

- **All three major slicers import STEP natively** now ([OrcaSlicer since 1.10](https://github.com/OrcaSlicer/OrcaSlicer/wiki/import_export), Bambu Studio, PrusaSlicer) — STEP gives the slicer exact geometry to tessellate at its own resolution (visibly better curved surfaces).
- **3MF is the de facto interchange format** of the Bambu/Orca/Prusa family (STL is legacy: no units, easily broken). Write core-spec 3MF via [lib3mf](https://github.com/3MFConsortium/lib3mf) (BSD) + targeted vendor extensions for Bambu/Orca/Prusa.
- **Pipeline: export 3MF as primary, STEP as the "pro" differentiator** and the bridge to Fusion/FreeCAD users.
- **[Manifold](https://github.com/elalish/manifold)** (guaranteed-watertight mesh booleans; now OpenSCAD's default backend) for the final mesh-out stage and any implicit/mesh ops.
- **Printability checks are build-it-thin features, not dependencies**: overhang detection = per-face normal angle on our own tessellation; wall thickness = ray-cast/SDF thickness (e.g. trimesh's approach); manifoldness guaranteed by Manifold.

> **[2026-07-19 correction — falsified by later research.]** Two claims above do not hold:
> (1) **Manifold guarantees manifold output only from manifold input** — it is not a
> repair gate for arbitrary broken meshes, and "manifoldness guaranteed by Manifold" is
> technically false (`docs/research/01-domain-research-findings.md` **F-06**); (2) the
> "write 3MF via lib3mf + vendor extensions" plan was superseded by **F-07**'s three-way
> contract split (`AETH-3MF-CORE` / production / vendor adapters). As shipped, neither
> Manifold nor lib3mf is a dependency: `packages/interchange` hand-writes deterministic
> core 3MF and **proves** manifoldness per export (directed-edge census + signed-volume
> orientation gate, `interchange/src/mesh.ts`); see `docs/plan/06-print-pipeline/02-threemf-format.md`.

### 4.4 Viewport

**three.js** (MIT) is the proven CAD-viewport path — chili3d, replicad, CascadeStudio, and (with a commercial kernel) Plasticity all render OCCT-style tessellations this way. Face/edge picking via per-face triangle-ID attributes + GPU picking; `TransformControls` + [three-viewport-gizmo](https://fennec-hub.github.io/three-viewport-gizmo/) for drag/resize/orientation. Selection/highlight is hand-rolled but well-trodden. Babylon.js is the fallback if built-in gizmos/highlighting prove worth the weight; wgpu/bevy only if the whole app went native Rust (it shouldn't — §7).

---

## 5. The local agent

### 5.1 Model landscape, July 2026

The consumer-range open-weight race is now **Qwen (Alibaba) vs Gemma (Google), both Apache 2.0**. Meta exited open weights (Llama 4 was the last open family; its successor is API-only). The giant open models (DeepSeek V4, GLM-5.2, Kimi K2.x) are far beyond consumer hardware and irrelevant for bundling.

**Recommended three-tier bundle** (all Apache 2.0 — unconditionally redistributable inside a commercial app):

| Tier        | Model                     | Disk (Q4) | Hardware                                                                     | Why                                                                                                                                                                                                   |
| ----------- | ------------------------- | --------- | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Floor       | **Qwen3.5-9B**            | ~5.5 GB   | 8 GB VRAM GPU / 16 GB Mac                                                    | "New default for 8GB VRAM"; at the ~8B reliable-agent floor — pair with tight harness                                                                                                                 |
| **Default** | **Gemma 4 26B-A4B (MoE)** | ~12.7 GB  | 16 GB VRAM / 24 GB Mac; degrades gracefully to CPU-offload (only ~4B active) | [First Apache-2.0 Gemma](https://the-decoder.com/googles-gemma-4-is-now-available-with-apache-2-0-licensing-for-the-first-time/); native function calling + JSON mode; community BFCL v4 non-live 89% |
| High        | **Qwen3.6-27B (dense)**   | ~17 GB    | 24 GB GPU / 32 GB+ Mac                                                       | [Best agentic model that fits one consumer GPU](https://huggingface.co/Qwen/Qwen3.6-27B) — SWE-bench Verified 77.2, Terminal-Bench 2.0 tied with frontier closed models; thinking mode; vision        |

Hardware reality (why three tiers): per the June 2026 Steam survey, **8 GB VRAM is still the modal GPU tier** (16 GB ≈ 24.5% and rising); the base MacBook Air M5 ships with 16 GB unified memory. The 9B floor covers ~80–90% of the target base; the 26B default covers ~35–45%; the 27B high tier ~5–10% today, growing.

> **[2026-07-19 correction — falsified by later research.]** These model names are
> **candidates, not tiers**: availability and Apache-2.0 redistribution were verified, but
> fitness was not — community reports show tool-call stalls and template/runtime
> sensitivity, common GGUFs are third-party quantizations, and coding benchmarks are not
> substitutes for CAD-state reliability. Model selection remains **blocked until exact
> Aethalgard-owned, signed packs pass AeCAB under simultaneous viewport workloads**. See
> `docs/research/01-domain-research-findings.md` **F-13** (and **F-09**/**F-10** on what
> AeCAB must measure before any "reliable agent" claim).

Known weakness to engineer around: **multi-turn agentic reliability** (Gemma 4 26B community multi-turn BFCL ≈ 45%). Mitigations: grammar enforcement, app-side validation/retry, iteration caps, and the domain LoRA below.

### 5.2 Runtime: llama.cpp sidecar

- Bundle **llama.cpp `llama-server`** (MIT) as a child process speaking the OpenAI-compatible API locally — the pattern the whole 2026 ecosystem converged on (Jan.ai bundles llama.cpp; Msty literally bundles a renamed Ollama). Per-backend builds (CUDA / **Vulkan as universal AMD-Intel-NVIDIA fallback** / Metal / AVX2 CPU) with a runtime GPU probe.
- **No consumer app ships weights inside the installer.** Universal pattern: thin installer (<500 MB) + guided download-on-first-run from a CDN, hardware detection choosing the tier. Weights stay outside the signed bundle (avoids re-notarizing 15 GB); they're immutable blobs — only the app binary needs delta updates.
- **Grammar-enforced tool calls**: llama.cpp converts JSON Schemas to GBNF grammars that mask logits — the model _cannot_ emit syntactically invalid JSON; "lazy grammars" preserve free-text reasoning until the tool-call token. Grammar guarantees syntax, not semantics — so validate function names/argument ranges app-side, retry on failure, cap agent loops (~10 iterations).
- Optionally **MLX on Apple Silicon** for ~20%+ speed (M5's neural accelerators give ~4× faster prefill); llama.cpp-Metal everywhere is the simpler v1.

### 5.3 Domain fine-tuning: cheap and worth it

QLoRA fine-tuning a 9–27B model on CAD tool-call traces costs **tens to hundreds of dollars per experiment** (a demonstrated Qwen3.5 fine-tune cost ~$11 of A100 time); the real cost is building the trace dataset and evals. The [AgentFloor result](https://arxiv.org/pdf/2605.00334) — LoRA can't rescue models below ~7–8B, and gains are real above it — matches the tier floor. Ship the ~100–500 MB CAD-domain adapter separately from the base model and update it independently (llama.cpp loads LoRA at runtime). This directly attacks the multi-turn weakness in our narrow domain. [Seek-CAD](https://arxiv.org/pdf/2505.17702) (local DeepSeek with self-refinement for parametric CAD) is direct evidence local models can do this work.

### 5.4 VRAM contention: LLM + viewport on one GPU

This is real, under-engineered anywhere, and both a risk and a differentiator. LLM overflow to system RAM drops 10–15 tok/s to 1–3 tok/s; the viewport needs its own headroom; KV cache grows with context. Design in from day 1: model tier picked by detected VRAM, context caps, partial GPU offload (`n_gpu_layers`), **idle weight unload**, CPU-only fallback, and on Apple Silicon exploit unified memory (the best consumer target for this product). **No shipped consumer product has solved simultaneous LLM+viewport contention elegantly.**

---

## 6. UX doctrine

### 6.1 The empirical basis

- A [2025 comparative study](https://arxiv.org/html/2510.12146) found the abstract sketch→constrain→extrude workflow imposes high cognitive load: novice SUS scores were **47 (traditional CAD) vs 65 (direct manipulation)** — a 38% gap; 2 of 3 true novices abandoned traditional CAD entirely; direct manipulation let novices "figure things out by just looking and trying."

> **[2026-07-19 correction — falsified by later research.]** This evidence was
> overgeneralized: the cited study compared an **AR prototype** against SolidWorks with 20
> participants of whom only **three** were true novices — the "65 vs 47" comparison is
> n=3, overall SUS was 64.4 vs 58.5, workload differences were not significant, and the
> prototype lacked precision input. It is directional inspiration, not product validation;
> Aethalgard requires its own preregistered study (desktop pointer/keyboard,
> exact-dimension tasks, delayed retention, physical-output correctness). See
> `docs/research/01-domain-research-findings.md` **F-14** (and **F-15** on why the
> no-shortcut expansion of the founder's palette ban needs an accessibility-grade
> keyboard story).

- Novices [can't even _identify_ constraints](<https://cad-journal.net/files/vol_18/CAD_18(3)_2021_612-623.pdf>), let alone author them; feature-tree parent/child dependencies are the most error-prone concept for non-experts; and 3D camera navigation is [its own documented failure mode](https://tech.yahoo.com/general/articles/why-3d-software-feels-confusing-100000536.html).
- Products that solved parts of it each contribute one proven decision:
  **TinkerCAD** (hole-vs-solid as a _property_ lowers command burden),
  **Shapr3D** (pro kernel + adaptive minimal surface), **SketchUp** (inference
  snapping that _explains itself_: "On Edge", "Parallel", "Midpoint"), and
  **Gravity Sketch** (proof that direct 3D control can be discoverable). These
  are accessibility lessons, not reasons to remove professional CAD depth.

### 6.2 The doctrine

1. **Keep professional sketch, constraint, feature, and history capabilities
   available without making them the only entry path.** Direct manipulation is
   the primary accessibility layer; the light operation timeline projects the
   authoritative parametric history without becoming an intrusive feature-tree
   wall.
2. **Direct-manipulation grammar**: push/pull faces; TinkerCAD-style corner/edge handles with **clickable dimension callouts** (click the number, type "42.5" — typing digits into a visible on-object field is precision, not a command palette).
3. **Inference and authored constraints coexist**: SketchUp-style snapping with
   visual explanation supports direct manipulation, while professional sketch
   mode supports explicit authored constraints and deterministic solving.
4. **A work-grid that materializes only during drag/resize** ([Squarespace Fluid Engine pattern](https://engineering.squarespace.com/blog/2022/developing-fluid-engine)), mm-quantized, per-object independence — moving one part never disturbs others.
5. **Remix/template-first entry** (the MakerWorld customizer lesson): parameter sliders on curated templates as the default first-run experience; a drag-from-library parts tray (screw bosses, hinges, Gridfinity bases) that auto-orients and mates on drop; blank canvas is the _advanced_ path.
6. **A "can't get lost" camera**: constrained turntable orbit by default, always-visible ground plane, one-tap reframe. Navigation is a first-class failure mode, not a detail.
7. **Selection-anchored contextual controls** showing only currently-valid operations (Shapr3D's adaptive UI; Canva's floating toolbar) — never an icon wall, never a global mode switch; progressive disclosure via an "advanced drawer" per panel.
8. **Searchable command invocation is valid.** A Fusion-style S-key/search entry
   point may complement visible menus, direct manipulation, and the agent. No
   capability may depend on memorizing a shortcut; visible controls remain a
   complete path.

### 6.3 The agent contract (anti-Clippy rules)

Synthesized from what shipped and worked in 2025–2026 ([Figma Design Agent](https://www.figma.com/blog/the-figma-agent-is-here/), [Ask Canva's layer-preserving edits](https://www.canva.com/newsroom/news/canva-create-2026-ai/), Cursor's per-change accept/reject — [whose removal caused a user revolt](https://forum.cursor.com/t/bring-back-per-change-apply-inline-diff-review-you-re-throwing-away-your-best-ux-advantage/160856), and the v0/Lovable click-element-to-scope-prompt loop):

1. **Selection-scoped and invoked, not proactive.** Click a face/part → prompt applies to _that_. Proactive interjection only on strong signals ("this will tip over when printed") and always dismissible.
2. **Layer-preserving output**: agent edits produce ordinary editable parametric objects — never baked meshes. Trust collapses on the first opaque blob.
3. **Action Plan → live narrated actions on the shared canvas → Variations → per-operation accept/reject.** The user watches operations land one by one and can interrupt/steer mid-run.
4. **One timeline of truth**: agent edits, manual edits, and imports share a single unlimited undo stack; automatic checkpoint before any multi-step agent run.
5. **Clarify before drawing**: for ambiguous asks, the agent asks one good question (with a guess as default) rather than guessing silently — novices can't specify dimensions up front ([research line on clarification agents](https://arxiv.org/pdf/2602.03045)).

The operation-graph architecture makes every one of these nearly free: a "proposal" is a set of graph operations not yet committed; "accept/reject per change" is per-node; "explain what the AI did" is the op list in plain language.

---

## 7. Packaging and shell

### 7.1 Electron + native kernel module (the Plasticity proof)

**The decisive precedent: [Plasticity](https://grokipedia.com/page/plasticity_software)** — a commercial artist-CAD app shipped as **Electron + three.js frontend + C++ geometry kernel bound as a native Node module**, Win/mac(ARM+Intel)/Linux. That is Aethalgard's architecture proof, with OCCT in place of their commercial kernel.

Tauri 2.x was seriously considered and is **disqualified by its webviews for a GPU-heavy viewport**: WebKitGTK on Linux has [documented WebGL latency, NVIDIA blank-window bugs requiring software-rendering workarounds](https://v2.tauri.app/develop/debug/linux-graphics/), and [WebGPU is not enabled by default in WKWebView](https://webo360solutions.com/blog/webgpu-browser-support/) on macOS. Electron ships Chromium everywhere → identical WebGL2/WebGPU on all three platforms, mature signing/auto-update (electron-builder; Squirrel-class delta updates), and the 2026 guidance is explicit: [reach for Electron when UI is rendering-heavy and must look identical everywhere](https://www.pkgpulse.com/guides/electron-vs-tauri-2026). Accept the bundle-size cost; it's noise next to the model download anyway.

### 7.2 Shipping shape

- **Thin installer** (<500 MB: app + OCCT module + llama.cpp binaries for each backend) + **first-run tiered model download** with hardware detection and a clear "what you get at your tier" explanation.
- Weights outside the signed bundle; delta updates for the app only; LoRA adapter updated independently of base weights.
- Code signing: macOS $99/yr + notarization (mandatory); Windows via [Azure Trusted Signing at ~$10/mo](https://melatonin.dev/blog/code-signing-on-windows-with-azure-trusted-signing/).
- Kernel placement: native N-API OCCT module in-process for speed, with the option to move it to a sidecar process later for crash isolation (a kernel crash must not take down the user's document — journal the op graph so replay recovers state).

### 7.3 Slicer integration

- **v1: hand off.** Export 3MF (+ STEP) → invoke the installed slicer via OS file association and **URL-protocol deep links** (`bambustudio://`, `orcaslicer://`, `prusaslicer://` — the mechanism behind Printables' "Open in slicer" button).
- **v1.5: embedded preflight** — "this will print / this will fail" (overhangs, stability, wall thickness) without full slicing. This is where average humans actually get hurt today.
- **v2: embedded slicing** via CuraEngine or libslic3r — both AGPL, so run **unmodified as an arm's-length CLI sidecar**; expose one "Print quality: draft / standard / strong" control, never expert settings.
- **Never trust embedded print profiles** — re-derive from known-good presets for the user's printer (the MakerWorld safety pattern).
- **Bambu direct-print is unstable political ground** (the 2025–2026 [Bambu Connect authorization-control controversy](https://consumerrights.wiki/w/Bambu_Lab_Authorization_Control_System), C&D letters); the escape hatch is LAN-only Developer Mode (MQTT/FTP). Prusa/Klipper ecosystems (PrusaLink, Moonraker) are open. Treat direct-print as a per-vendor adapter, not core.

---

## 8. Risks and open questions

| #   | Risk                                                                                                   | Severity                         | Mitigation                                                                                                                                                 |
| --- | ------------------------------------------------------------------------------------------------------ | -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Persistent naming** — topological references breaking on upstream edits                              | High (the one deep-tech problem) | Query-based selectors from day 1 + OCCT ancestry tracking; FreeCAD 1.0 proves tractability                                                                 |
| 2   | **Local-model reliability on multi-turn agentic work** (multi-turn BFCL ≈ 45–66% for the bundle tiers) | High                             | Per-op feedback loop (not one-shot), grammar enforcement, validation/retry, iteration caps, domain LoRA, per-op accept/reject UX that makes failures cheap |
| 3   | **OCCT fillet/boolean failures on edge cases**                                                         | Medium                           | Known tax; constrain the op vocabulary to what's robust, surface friendly errors, journal+replay for recovery                                              |
| 4   | **VRAM contention** LLM vs viewport on 8 GB GPUs                                                       | Medium-high                      | §5.4 budgeting as a first-class product feature; Apple Silicon unified memory is the best-case target                                                      |
| 5   | **Bambu bundles "easy CAD"** into MakerWorld/MakerLab                                                  | Strategic                        | Speed; local/offline/unmetered as the moat cloud players won't copy; position for integration rather than pure competition                                 |
| 6   | **Model-download friction** (5–17 GB first run)                                                        | Medium                           | Tiered download with instant-start 9B; app usable (manual CAD) while the model downloads                                                                   |
| 7   | **Scope creep toward pro CAD** (assemblies, drawings, surfacing)                                       | Medium                           | The audience designs brackets/organizers/repair parts — benchmarks say exactly this class is what AI+kernel handles well today; stay there                 |
| 8   | **AGPL contamination** (chili3d as code reference, slicer engines)                                     | Low                              | chili3d = reference-only or paid license; AGPL slicers = unmodified arm's-length sidecar                                                                   |
| 9   | Fast-moving model landscape (bundle choice stale in 12 mo)                                             | Low                              | Runtime + weights decoupled from app; tiers are config, not architecture                                                                                   |

Open questions for the founder:

1. **Business model** — Plasticity-style perpetual license ($100–200 one-time) fits the local/anti-subscription positioning perfectly and is validated; freemium with a paid "high tier model + STEP export" is the alternative. Subscriptions contradict the pitch.
2. **Windows/Mac first, or Mac-lean?** Apple Silicon unified memory is technically the best target for LLM+viewport, but Steam-class Windows machines are where the printer owners are. (Research says: build for both, tune the model tiers per platform.)
3. **Name-collision hygiene**: nothing found squatting "Aethalgard" in software; fresh trademark search advised before launch.
4. **The old Aethalgard viewer**: confirmed not reusable in spirit — this stack (Electron + three.js over OCCT tessellation with op-graph selection semantics) is purpose-built differently; the repo starts blank, as it has.

---

## 9. Recommended stack and phased plan

### The stack, in one table

| Layer             | Choice                                                                           | License              |
| ----------------- | -------------------------------------------------------------------------------- | -------------------- |
| Document model    | **JSON operation DAG** with query-based references (ours — the core IP)          | —                    |
| Geometry kernel   | **OCCT 8.0** via native N-API module                                             | LGPL 2.1 + exception |
| Mesh out / repair | **Manifold** + **lib3mf**                                                        | Apache-2.0 / BSD     |
| Viewport          | **three.js** (WebGL2/WebGPU), GPU picking, on-object gizmos                      | MIT                  |
| Shell             | **Electron** + electron-builder auto-update                                      | MIT                  |
| Agent runtime     | **llama.cpp `llama-server`** sidecar (CUDA/Vulkan/Metal/CPU, runtime probe)      | MIT                  |
| Models            | **Qwen3.5-9B / Gemma 4 26B-A4B / Qwen3.6-27B**, download-on-first-run + CAD LoRA | Apache-2.0           |
| Export            | **3MF primary, STEP pro**, slicer deep-links                                     | —                    |

> **[2026-07-19 correction pointers.]** Table rows amended by later findings: geometry
> kernel — manifest-pinned `V8_0_0_p1`, not "8.0" (F-03 / ADR-002); mesh out/repair —
> Manifold is not a repair guarantee and lib3mf is not shipped (F-06/F-07; the shipped
> writer is `packages/interchange`); models — candidates pending AeCAB qualification, not
> locked tiers (F-13). See `docs/research/01-domain-research-findings.md`.

### Phase 0 — Proof of the two risky things (weeks, not months)

Build nothing but: (a) op-graph → OCCT replay → three.js viewport with face-click-records-a-query selection; (b) a local model (start with Gemma 4 26B-A4B) driving that graph via grammar-enforced tool calls with per-op kernel feedback. Success = "make a box, shell it 2mm, fillet the top edges 3mm, cut two 5mm holes" spoken in plain English by a non-CAD user, producing a printable 3MF, fully offline. This de-risks #1 and #2 simultaneously.

### Phase 1 — MVP (the "repair part" release)

Direct-manipulation editor (handles, dimension callouts, inference snapping, ground plane, can't-get-lost camera), parts tray with ~20 curated primitives/fixtures, template gallery with parameter sliders, agent side panel with Action Plan → narrate → accept/reject, 3MF/STEP export + slicer deep links, three-tier model download.

### Phase 2 — v1

Print preflight ("will this print?"), image-in ("photo of a damaged part" →
agent drafts the part — vision is already in the bundle tiers), library growth
(Gridfinity and hinges; thread designation/standards data can land early, while
full modeled Thread work waits for core solids and professional Hole, joining,
drawing-note, or CAM-tapping consumers), LoRA v2 trained on real usage traces,
Mac MLX path, checkpoint/branching for agent runs.

### Phase 3 — beyond

Embedded slicing sidecar, implicit/lattice node (Fidget), community template exchange / MakerWorld integration, code _export_ for graduates.

---

_Research compiled from four parallel investigations (competitive landscape; geometry kernels & representations; local models & runtimes; UX & packaging), each verified against primary sources in July 2026. Key single sources worth reading in full: [Zoo's Zookeeper writeup](https://zoo.dev/research/zookeeper) (the agent-drives-engine pattern, done cloud-side), [CadQueryEval results](https://github.com/danwahl/cadqueryeval) (why one-shot code generation isn't enough), the [Fornjot shutdown post](https://fornjot.app/blog/shutting-down-fornjot/) (why we don't write a kernel), and the [AR-CAD novice study](https://arxiv.org/html/2510.12146) (why the direct-manipulation mandate is right)._
