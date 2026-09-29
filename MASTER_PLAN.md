# BendCAD Master Plan

**Revision 5 — September 29, 2026 (Amendments A1: C04/C07/C11 boundary; A2: proof methodology; A3: BendCAD is Aethalgard v2, agent-native; see Amendment record)**

**Objective:** deliver production-qualified binary64 in Bend 2, including actual GPU execution on Metal, then build an independent professional CAD kernel whose geometry and topology algorithms are written in Bend. That kernel, with the design model, engineering layer, agent interface and viewer above it, is Aethalgard v2: **BendCAD**, an open-source CAD system built from the kernel up to be driven by an AI agent (§14).

**Acceptance sentence:** a fresh Claude session told "pull up BendCAD and design me a bespoke jet engine" produces a buildable design, meaning:

- analytic geometry, with tolerances and fits that close;
- materials suited to their loads and temperatures;
- an assembly that goes together;
- drawings, BOM and manufacturing data;
- evidence for every claim, labeled by strength.

The challenge ladder (§16) measures progress toward it.

**Present status:** the pre-VibeCAD Aethalgard kernel/reference corpus is recovered. This document specifies future implementation; it does not claim that F64, a Bend-native kernel, or their qualification already exist.

## 1. Three projects, three boundaries

BendCAD is Aethalgard v2 (Amendment A3). It replaces Aethalgard's FreeCAD/OCCT engine, and the whole product, with a Bend-native system. Production Aethalgard v1 (Electron/React/three.js, Engineering Core, headless FreeCAD/OCCT) is frozen: no further feature work, no Bend dependency added to it. v1 remains a reference for UX and product vocabulary: its three.js viewport, command catalog, interaction contracts, MCP/agent-control history and Engineering Core concepts are mined for v2 like `legacy/aethalgard/`.

The Bend language fork is `jnadeau207-collab/bend`. BendCAD's authoritative dependency is the exact commit in root `BEND_PIN`; the initial audited pin is `0b7e2b11c1054f5d0f4eb955cadb47997ef1115d`. Generic scalar representation, U64/F64, compiler/runtime integration, Metal software binary64, backend identity, and conformance work live in that repository. BendCAD does not carry a competing F64 RFC. Advance `BEND_PIN` only to an exact Bend commit that has satisfied the required numeric gate.

`jnadeau207-collab/BendCAD` owns the new CAD kernel, its laws and proofs, professional geometry algorithms, command-line interface, SDK, interchange, and qualification corpus. Its runtime geometry must not depend on FreeCAD, OCCT, PlaneGCS, or another existing CAD kernel.

Compiler backends, operating-system I/O, device dispatch, and a qualified numeric runtime may contain C, C++, JavaScript, and Metal code. Those are declared implementation boundaries, not permission to hide CAD algorithms behind foreign calls. The archived OCCT evaluator may run only as a separately identified test oracle.

The product target is a professional boundary-representation kernel with analytic and NURBS geometry, trimmed surfaces, robust booleans, feature modeling, queries, tessellation, and interchange, plus the layers above it that make it an agent-native CAD system:

- the design model;
- engineering;
- the agent interface;
- the viewer and app;
- deliverables.

Mesh-only or voxel-only modeling is not a substitute. The kernel stays releasable on its own, and every upper layer is a client of the same kernel operations (§14, P1).

## 2. Recovered source and its proper use

The preserved reference source is under `legacy/aethalgard/`, pinned to:

`jnadeau207-collab/reepo@eeca9ad782640f97bc15423e72319acea310d36f`

The selected core contains 249 files: the complete native kernel-host, complete geometry-contracts and kernel-client packages, geometry/golden fixtures, native build tooling, OCCT manifest, and seven root architecture/build documents. Additional recovered architecture and build metadata are retained separately in the same archive. This is not a complete restoration of the old desktop application or its full Git history.

Whole-directory Git tree identities provide the strongest recovery check:

| Original relative directory | Pinned tree SHA |
|---|---|
| `native/kernel-host` | `4b6e7b33552772c4fcdd7ca09944e9fbbfe86f45` |
| `packages/geometry-contracts` | `4af260ff34b672aa28a47cac471dd58287d4c976` |
| `packages/kernel-client` | `5376774b22c999feab935c519e945c1987f063b2` |
| `fixtures/geometry` | `4d036fb38b9fc28042e708d91aab671a8f3b34b9` |
| `fixtures/golden` | `6aa7ba70be35e0c5cc08f68aebc1a976be733603` |
| `tools/build-native` | `1a0c85d07ec1ac1e35cb4c69ee7e2a653fd6c4c5` |

The archive is immutable reference material. Its old plans, completion statements, and test receipts are historical, not evidence that its code builds or passes today. Source integrity and runtime qualification are different gates. The subset's original workspace scripts reference omitted packages and the old desktop; build a dedicated oracle harness outside the archive rather than declaring the subset a standalone application.

Preserve original notices and third-party provenance. Do not place a new blanket license over imported material. New BendCAD code is licensed **Apache-2.0** (owner decision, A3). The `LICENSE` file lands with release packaging (P3), once release artifacts are built from a tree that excludes `legacy/`. Imported material keeps its original proprietary/UNLICENSED and third-party distinctions and never ships in a release artifact.

Three recoverable references remain useful for subsequent archaeology, but are not interchangeable baselines: local-worktree snapshot `1eab12971dcb22c0b75f9d3714ba377d86ab36b5`, archive manifest `213180dd5b2d0c805ae9610bf88be5cd82111b0f`, and the selected tip above. Any additional branch recovery gets its own provenance, not silent mixing.

## 3. Bend is a pinned prerequisite, not part of the CAD kernel

The canonical numeric contract and execution order live in the Bend fork:

- `bend2/docs/F64_CONTRACT.md`
- `bend2/docs/F64_IMPLEMENTATION.md`

This plan does not duplicate them. If Bend's numeric contract changes, change it there first, qualify it there, then advance `BEND_PIN`.

The #797 class shaped the representation: upstream closed `bendlang/bend#797` as not planned, so F32 on JS stays bit-unreliable and F64 geometry is built on the as-bits representation instead, which is immune to that failure. F32 stays out of authoritative geometry; see the host gate in section 4a.

## 4. Required Bend handoff gates

Serious BendCAD geometry numerics may begin once the pinned Bend commit closes the host gate. Device claims additionally require the device gate. Status below is at `BEND_PIN` `jnadeau207-collab/bend@bc01485d` (tag `numeric/2026-09-29`, upstream 777ee0b5 plus U64 and F64), whose evidence is the fork's `conformance/receipts/2026-09-29.txt`; the pin advance is receipted in `docs/receipts/bend-pin-2026-09-29.txt`.

### 4a. Host gate (closed at the pin)

H1. F64 geometry is built on the as-bits representation, immune to the #797 class; F32 stays out of authoritative geometry. (Was 1, 2, redefined: upstream will not fix #797.)
H2. Raw `w64` distinguished from tagged runtime `Term`. (Was 3.)
H3. Arbitrary U64 transport through constructors, arrays, closures, scheduling and host execution. (Was 4.)
H4. Exact F64 `from_bits/bits` transport. (Was 5.)
H5. Qualified add/sub/mul/div/sqrt/FMA and required conversions on host lanes (interpreter, JS, C): 2^20 cases per group over 22 groups with 0 mismatches, plus representation probes and the show/read text check, per the receipt. (Was 6.)

### 4b. Device gate (CUDA closed at the pin; Metal open)

D1. Strict backend identity: `--gpu on` (or `--gpu <size>`) refuses to start without a GPU, runs every `!` wave on the device, and aborts on device fault, so a zero-exit `--gpu on` run proves device execution. The no-flag default still falls back silently and reports no backend, so device claims must always pass `--gpu on`. (Was 7.)
D2. CUDA execution proven: the receipt's `cuda` and `cuda-defs` lanes run the 2^20-case differential, the probes, and the repo `!` tests with 0 mismatches; `cuda-defs` additionally proves the software-float path Metal uses, with all 27 soft-native call sites compiled as their Base defs.
D3. Genuine Metal binary64 executed as GPU-resident integer software arithmetic over `ulong`. OPEN: the Metal scan of emitted C is clean and the defs lanes prove the code path, but nothing has run on Apple hardware yet. This item needs a Mac. (Was 8.)

Device qualification is a gate for device claims, not a reason to freeze host representation work when hardware is unavailable.

## 5. What belongs in BendCAD

With the host handoff gate (§4a) closed at `BEND_PIN`, BendCAD owns the CAD-specific numerical layer:

- Vec2/Vec3, matrices, frames and transforms;
- stable norms and `hypot`;
- CAD-specific trigonometric/range-reduction policy;
- adaptive/exact predicates;
- certified intervals and root isolation where required;
- curve/surface evaluation and conditioning;
- topology, intersections, booleans, features, queries and tessellation.

Generic improvements may later move upstream. They are not prerequisites for closing Bend's scalar contract.

## 6. Legacy Aethalgard is oracle material, never the runtime

Mine `legacy/aethalgard/` for contracts, failure cases, topology behavior, selector/ref behavior, tolerance policy, fixtures and comparison outputs. Reconstruct a separate pinned oracle harness as needed.

FreeCAD, OCCT and PlaneGCS may be test comparators only. No BendCAD runtime geometry algorithm may delegate its implementation to them.

## 7. Dependency discipline

`BEND_PIN` is authoritative.

Do not track Bend `main` implicitly. Do not copy Bend numeric implementations into BendCAD. Do not maintain two numeric RFCs. A Bend upgrade is an explicit change with a receipt against the new exact SHA.

## 8. BendCAD architecture and numerical policy

A kernel request carries typed parameters, units, immutable input revisions, tolerance policy, and resource budget. It returns either a validated result plus provenance or a structured failure. Distinguish invalid input, unsupported operation, numerical uncertainty, nonconvergence, cancellation, and resource exhaustion. An empty intersection can be a successful geometric result; it is not the same as an evaluation failure.

Construct candidate geometry privately, validate it, then publish atomically. Failure must leave the accepted model unchanged. Use an immutable external model and controlled affine ownership internally; topology handles include generation information to detect stale references. Never rely on memory addresses or array ordinals as persistent identity.

Use separate linear, angular, parameter-space, approximation, and imported-data uncertainty budgets. No universal epsilon and no silently increased tolerance. Operations report the uncertainty introduced and consumed. Normalize units at explicit boundaries and retain units in interchange. F64 values are not an excuse for unbounded coordinate or conditioning promises.

Maintain analytic geometry as authoritative. Tessellation is a derived product with its own quality record. A display may use rebased F32 vertices; that narrowing must never flow back into topology, exact queries, or authoritative model coordinates.

Bend's affine/termination restrictions influence implementation: explicit bounded iteration, partitioned owned arrays, typed scratch arenas, and deterministic batch trees. Exhausted fuel returns an explicit incomplete result rather than a false proof of inconsistency or an `@unsafe` escape into trusted geometry.

## 9. Use the legacy code without becoming its wrapper

Create a replacement ledger: operation, original source path, external algorithm called, intended Bend implementation, law obligations, fixtures, current limitations, and qualification evidence.

Mine `geometry.cpp` for feature and operation semantics; `topology.cpp`, naming and selector files for identity/reference behavior; `sketch_solver.cpp` for constraints and diagnostics; `tessellate.cpp` for geometry transport and precision boundaries; native tests and TypeScript contracts for adversarial cases.

Build `tools/oracle/` as a separate process harness with pinned OCCT, PlaneGCS, compiler, and dependency identities. It is a development dependency only. Reconstruct its dependency closure deliberately; do not mutate historical code to conceal failures. New adapters and necessary compatibility patches live outside the immutable archive.

OCCT output is a comparison, not mathematical truth. Cross-check with analytic volume/area/inertia formulas, high-precision calculations, independently validated topology, and separate interchange readers. Never accept a Bend result solely because it repeats an old defect.

## 10. Ordered CAD-kernel milestones

### C00 — Contracts and failure semantics

Implement typed geometry inputs, units, tolerances, budgets, result statuses, deterministic operation identity, and atomic candidate publication. Exit: malformed input and deliberate cancellation cannot publish partial or nonfinite geometry.

### C01 — Mathematical foundation

Implement Vec2/Vec3, points versus directions, frames, matrices, rigid transforms, normalization, robust distance calculations, derivatives, and needed linear algebra. Define conditioning checks and prevent overflow-prone naive norms. Exit: numerical tests cover extreme scales, near-singular frames, and round-trip transforms within stated bounds.

### C02 — Robust predicates and exact-number support

Implement orientation2D/3D, incircle/insphere, segment relations, and classification with a fast bounded-error filter and exact fallback. Use expansions or multi-limb dyadic/integer arithmetic with independently tested signs. Exact predicates concern the supplied coordinates; they do not repair information lost earlier. Rational arithmetic alone is not a complete representation for arbitrary circle intersections or surface roots. Add certified intervals/root representations where necessary. [6]

Exit: adversarial near-degenerate cases match independent exact results; uncertain calculations never silently choose a side.

### C03 — Curves, surfaces, and trimming

Implement lines, circles/arcs, conics, planes, cylinders, cones, spheres, tori, Bezier curves/surfaces, and rational B-splines/NURBS. Cover knots, multiplicities, rational weights, derivatives, parameter domains, periodic seams, poles, projection, subdivision, and bounding enclosures. Represent trimming curves in surface parameter space from the outset.

Exit: conics, rational quarter-circles, periodic curves, derivative identities, and surface evaluations agree with analytic/high-precision references within declared bounds.

### C04 — Topology that represents real CAD

Implement vertices, edges, oriented edge uses/coedges, loops, faces, shells, solids, cavities, and compounds. Separate an underlying edge from its oriented uses. A closed edge can begin and end at the same vertex; a seam can occur twice on one face; a singular pole requires an explicit degenerate representation.

For the admitted manifold-solid profile, validate that a B-rep is topologically coherent and locally geometrically consistent, using only predicate-level checks over C00–C03 primitives: local incidence; vertex links (each vertex link is a single cycle); edge-use pairing; closed boundaries; shell face-connectedness and orientation-propagation consistency; per-face orientation self-consistency (boundary winding agrees with the `same`-adjusted surface normal) wherever determinable from C03 surface normals; shell ownership (outer kind, cavity kind, single ownership); repeated-vertex / duplicate-incidence detection, including coincident distinct vertices; same-face straight-edge segment-crossing detection over C02 exact predicates; and trim/surface consistency (parametric coincidence where C03 evaluation exists, implicit point-on-surface membership for quadrics). Counting faces or checking Euler's formula alone is not solid validation. Open surfaces remain valid under a different explicitly named profile.

C04 does not prove arbitrary geometric embedding: general curved-edge intersection, cross-face and inter-loop penetration, general geometric self-intersection, global outward shell orientation requiring inside/outside classification, coarse cavity bbox nesting, and exact cavity inside/disjoint classification are explicitly out of C04 scope. Coarse nesting via broad-phase bounds and the inside/outside classification that global outwardness needs belong to C07; exact containment/interference belongs to C11. Full parametric trim coincidence for quadrics waits on the C03 surface-evaluation extension (parameter conventions plus evaluation), a prerequisite to C06/C07, not C04 work.

Exit: valid sphere/cylinder seams and cavities are accepted; dangling, inverted (coedge-level and face winding/normal mismatch), repeated-vertex/coincident-vertex, same-face straight-edge crossing, vertex-link pinch, disconnected-shell, and nonmanifold topological counterexamples are diagnosed appropriately. The words "self-intersection" / "self-intersecting" are reserved for general geometric self-intersection (C07); C04 checks and receipts must use "repeated-vertex / duplicate-incidence" and "segment-crossing" for the C04-level detections.

### C05 — Planar arrangements and sketch solving

Construct planar regions with intersections, nested loops, holes, disconnected islands, and deterministic boundary identity. Develop a Bend-native constraint solver with residual/Jacobian evaluation, stable factorization, rank diagnosis, bounded iteration, and explicit degrees of freedom, conflicts, redundancy, and nonconvergence.

Start with coincidence, horizontal/vertical, distance, radius, angle, parallel/perpendicular, and tangency, then extend curve constraints. The solver must not declare a system inconsistent merely because an iteration budget expires. PlaneGCS is a test comparator, not the shipping solver.

### C06 — First complete solid-building path

Implement primitives, extrusion, revolution, pad/pocket semantics, holes, and transformations using the preceding geometry and topology. Handle multiple profile regions, axis crossings, and degenerate input explicitly. Every operation states its intended effect (added/removed material, created/modified faces), and the kernel checks the effect against that intent before publishing (§15, lesson 2).

C06 also delivers the minimal design-model evaluator: parts built from ops, parameters, and rebuild on edit. It pairs with A0 (§15).

Exit (G1, §16): a parameterized mechanical bracket with a curved boundary and holes is authored by a fresh agent session from a written brief, through the agent interface. It is then validated, measured, serialized, reopened, edited and tessellated, with no existing CAD kernel at runtime, graded by independent checks, and the transcript is kept in the receipt. This is the first end-to-end foundation, not the professional-completion ceiling.

### C07 — General intersections

Implement curve/curve, curve/surface, and surface/surface intersection with broad-phase bounds, subdivision/root isolation, refinement, endpoint classification, and complete admitted-domain coverage. Include tangency, coincidence, overlapping intervals, seams, and singularities. Newton iteration can refine an isolated candidate; it cannot by itself establish that all intersections were found.

Exit: return intersection curves and topology/parameter correspondence, not only sampled points. Unresolved regions remain explicit uncertainty. C07 owns general geometric self-intersection detection (curved-edge crossings, cross-face and inter-loop penetration) excluded from C04, the broad-phase bounds that coarse cavity nesting checks build on, and the inside/outside classification that global outward shell orientation needs. Prerequisite shared with C06: parametric evaluation and parameter conventions for every C03 surface arm (the C03 surface-evaluation extension).

### C08 — General B-rep booleans

Implement regularized union, difference, and intersection: intersect, split edges/faces, classify fragments, assemble boundaries, orient shells, validate, and publish. Handle disjoint solids, containment, coplanar/coincident faces, tangent contact, thin features, cavities, and legitimate empty results.

Record created/modified/deleted and one-to-many/many-to-one topology lineage. A durable selector resolves uniquely, resolves an intended set, or reports missing/ambiguous; it does not silently choose a nearby face.

Exit: analytic and NURBS cases pass independent geometry checks, volume identities, repeated edits, and serialization replay. Voxel booleans are not substituted for this milestone.

### C09 — Professional feature modeling

Add sweep, loft, fillet, chamfer, draft, offset, shell/thicken, and feature patterns. Cover guide curves, continuity, twist, self-intersection, variable-radius blends, corner construction, and topology evolution. Use the same evaluator path for all future human and agent clients.

Exit: each feature family has ordinary mechanical cases, degenerate cases, repeated downstream edits, bounded-error reports, and native Bend implementation evidence. One successful fillet does not qualify the family.

### C10 — Manufacturing-grade tessellation

Implement trim-aware meshing, consistent shared-edge samples, normal/orientation handling, seam treatment, and explicit LOD/quality controls. Bound error on the delivered mesh after welding, simplification, transforms, and numeric narrowing, not on an intermediate mesh that is later changed.

Exit: valid indices, appropriate watertightness, orientation, and stated chordal/angular bounds hold for the final output. Sampled quality checks are labeled sampled, not certified. Display tessellation and manufacturing export remain distinguishable.

### C11 — Professional queries

Implement closest point/distance, extrema, sections, intersections, area, volume, centroid, inertia, interference, clearance, and acceleration structures. Use certified bounds or explicitly bounded numerical integration where required. An AABB overlap is not exact interference; incomplete searching is not proof of clearance.

Exit: queries agree with analytic/high-precision fixtures and report incomplete or approximate status honestly. Minimum-wall claims require a separately qualified method, not a few successful ray samples. C11 owns exact cavity inside/disjoint classification and the inside/outside/interference machinery behind it.

### C12 — Interchange and durable identity

Define BendCAD's versioned B-rep archive with topology, analytic/NURBS definitions, parameter curves, units, lineage, and semantic versioning. Implement a declared STEP read/write profile and mesh exports including STL/3MF. Preserve hierarchy and placements where the profile includes them; unsupported entities are explicit.

Exit: independent readers validate dimensions, units, orientation, holes, multiple solids, surfaces, and product structure. Saving/reopening does not silently replace analytic geometry with its display mesh. Imports have memory, recursion, entity-count, and numeric bounds.

### C14 — Assemblies

Components, placements, mates/joints and kinematic degrees of freedom (reusing the C05 solver's rank/dof machinery). Interference and clearance through C11 queries, with certified status. Exploded views. Assembly-level lineage and durable selectors.

Exit: G3's gearbox assembles with every mate solved, no interference, the required clearances certified, and edits propagating through the assembly.

### C15 — Semantic PMI and GD&T

Dimensions, tolerances and datum reference frames bound to durable selectors, with ISO GPS / ASME Y14.5 semantics, evaluated by E1 and exported with STEP AP242.

Exit: G4's drawings and AP242 export carry machine-readable tolerances that an independent reader interprets identically.

### C16 — Specialized modeling (in ladder order)

Sheet metal, surface modeling, and blade/airfoil section and stacking (for G5), each as its own packet when the ladder needs it.

### C13 — Professional release qualification

C13 runs last. It qualifies the release after C14–C16 and the A/E/P tracks (§15) have delivered the ladder rungs the release claims.

Deliver a stable CLI and documented SDK/native integration boundary, reproducible builds, structured errors, resource/cancellation behavior, diagnostics, and compatibility tests across advertised targets. Publish a feature matrix grounded in admitted input domains and tests, not method-name counts.

Qualify a broad, versioned corpus of mechanical parts and pathological geometry; include varied scales, repeated feature edits, mixed analytic/NURBS solids, corrupted input, crash recovery, and long operation sequences. Material performance regressions block release. The professional-grade claim belongs to this evidence, not to a successful compiler run.

## 11. Proof strategy and the trusted boundary

Maintain four separate categories: formally proven properties, certified numerical bounds, experimentally tested behavior, and trusted assumptions. None is silently relabeled as another.

Useful early laws include valid generational references, closed oriented-use cycles, valid mesh indices, failure preserving the accepted revision, deterministic selector cardinality, and constructor preservation of topology invariants under explicitly stated geometric premises.

For example, an extrusion closure theorem must state premises about a valid simple planar region, its holes, a permitted sweep direction, and nondegeneracy. Merely storing `closed = True` is not a proof that geometry bounds a valid solid.

Keep owner-reviewed laws separate from implementation proofs. Changing a law, admitted domain, or tolerance to make a failing implementation pass requires explicit review. No holes, unchecked axioms, or unsafe functions may enter the claimed proof dependency graph unnoticed.

The trusted computing base includes Bend's checker, elaboration/erasure/compiler passes, numeric primitive assumptions, runtime, device compiler, and hardware. A proof about source terms does not automatically prove those implementations correct. Record that boundary and reduce it incrementally rather than claiming infallibility.

Proof methodology (Amendment A2, binding on every packet closeout from C04 on): Layer A semantic invariants, Layer B implementation theorems, Layer C stage-isolated adversarial fixtures, Layer D independent qualification — recorded in a per-packet exit receipt matrix with columns exit req, formal spec, predicate, pos witness, neg witness, stage-isolated, independent evidence, status. See the Amendment record.

## 12. Repository structure and delivery discipline

Grow directories as implementations arrive; do not fill the repository with placeholder files:

```text
BendCAD/
  MASTER_PLAN.md
  legacy/aethalgard/          # Immutable historical reference
  legacy/PROVENANCE.md
  legacy/manifest.json
  src/
    numerics/ predicates/ geometry/ topology/
    sketch/ intersection/ boolean/ features/
    queries/ tessellation/ io/ api/
  laws/ proofs/
  tests/                     # Unit, adversarial, differential, round-trip, performance
  tools/oracle/
  tools/verify_legacy.py
  docs/
```

One work packet has a contract, implementation, negative tests, relevant laws, and a receipt at the tested commit. Track planned, implemented, verified, and released separately. No placeholder functions, silent fallback kernels, tests disabled to manufacture green status, or completion claims from a different SHA.

Use ordinary incremental commits; preserve existing work and do not force-reset branches. Keep generic numerical improvements upstreamable instead of embedding CAD names in Bend's compiler. Aethalgard v1 is frozen (A3): do not change it; mine it.

## 13. First execution packet

The host prerequisite gate (§4a) is closed at `BEND_PIN`, so host geometry work may proceed on the qualified F64 substrate; device claims wait on the device gate (§4b).

Work allowed in parallel:

- preserve and verify the immutable Aethalgard reference corpus;
- build oracle adapters outside `legacy/`;
- inventory operation semantics and adversarial fixtures;
- specify CAD-side contracts whose correctness does not depend on pretending F64 already exists.

`BEND_PIN` names a qualified numeric commit (`numeric/2026-09-29`), so BendCAD started at C00/C01/C02: failure semantics, mathematical foundation, then robust predicates, not an OCCT bridge or a box demo. C00–C05 are closed (C05.1 at `48ab78c`). The next packet is C06 + A0 (§15): solids and the design-model evaluator, protocol v0, and the G1 harness.

**Dependency order:** Bend representation soundness → full-width U64/F64 transport → qualified core binary64 → pinned host handoff → BendCAD numerics/predicates → B-rep foundations → intersections/booleans/features → interchange and professional qualification, with device qualification alongside (CUDA receipted; Metal execution pending a Mac).

## 14. Agent-native architecture (Amendment A3)

### 14.1 Lessons from Aethalgard v1

Each lesson is something v1 did that v2 must not.

1. **The agent was a guest behind human UI state.** MCP exposed only
   the ribbon a human had selected. There was no tool to change
   workbench. Mutations required an attested human gesture. v2: the
   agent is a first-class principal. Human approval is a *policy*
   (which operations need sign-off), never an *interaction
   dependency*.
2. **Valid payloads did the wrong thing.** A pocket added material;
   patterns mirrored. v2: every operation states its intended effect
   (added/removed volume, created/modified faces), and the kernel
   checks the effect against the intent before publishing. A
   mismatch is a structured failure.
3. **Green suites did not exercise the product.** 61% of journey
   assertions never ran; journeys opened the app and sat idle. v2:
   the challenge ladder (§16) is the product test, run by an agent,
   graded by independent checks, leaving an artifact.
4. **Truth was split.** FreeCAD owned geometry, Core owned revisions,
   the renderer owned presentation, and generators went stale between
   them. v2: one authority. The kernel's design model is the only
   source of truth, and everything else derives from it by
   hash-checked projection.
5. **Identity was positional.** "Face12" rebinds silently after an
   edit. v2: durable semantic selectors (C08 lineage) resolve to
   exactly the intended set, or report missing/ambiguous.

### 14.2 Principles

P1. **One evaluator.** Humans, agents, scripts and the viewer all
call the same operations through the same protocol. The human UI is
a client of the agent interface, not the other way round.

P2. **Addressable by meaning.** Anything that can be referenced has a
durable name:

- parts, features, faces by role ("bore of bearing seat 2");
- parameters, requirements, materials.

Names survive edits or fail loudly.

P3. **Every answer carries its status.** Each result says whether it
is proven, certified (a bound), estimated (a method and its
convergence), or assumed, with units and uncertainty. An agent never
has to guess how much to trust a number.

P4. **Failures explain themselves.** Every failure carries:

- what failed, and where (selectors);
- why, in machine-readable form;
- the smallest known change that would fix it, when one is known.

C05 already does this for sketches: named conflicting constraints,
dof, redundancy.

P5. **Design is text.** A design is a deterministic, diffable,
versioned, branchable document. The agent can read it whole, edit it
precisely, and replay it. Interactive edits emit the same text.

P6. **Verification is the product.** Requirements are executable
checks bound to the design. A design is "done" when every requirement
passes with evidence of the stated strength. The agent cannot declare
completion; the checks do.

P7. **Perception parity.** Anything a human can see, the agent can
query as structure *and* view as an image:

- named views, sections and exploded views;
- highlighted selectors;
- revision diffs.

P8. **Bounded, incremental, cancellable.** Long work (booleans,
meshing, analysis) runs as jobs with budgets, progress and partial
results. Budget expiry is reported honestly, never as a false answer.
This is the C05 rule, generalized.

P9. **Evals are the spec.** Agent capability is measured by
design-from-brief challenges with independent graders. A regression
on the ladder blocks release, like a failing law.

### 14.3 Layers

```text
L6  Deliverables      STEP AP242 + semantic PMI, drawings, BOM, 3MF/STL, inspection plans, (later) CAM
L5  Human app         viewer (Aethalgard three.js, rebuilt on kernel tessellation), agent activity, review/approve, direct manipulation -> ops
L4  Agent interface   protocol (MCP transport + CLI + SDK), sessions, transactions, jobs, perception, skills
L3  Engineering       materials, tolerances/fits/stack-up, standard parts, analysis (FEA, thermal, fluid), DFM, domain packs
L2  Design model      design graph: parts, sketches, features, assemblies, parameters, requirements, materials, PMI; text form; revisions/branches
L1  Kernel            C00–C13: numerics, predicates, curves/surfaces, topology, sketches, solids, intersections, booleans, features, tessellation, queries, interchange
L0  Bend fork         U64/F64 on every lane, GPU (CUDA; Metal pending), BendTT kernel (native F64 for --verdict)
```

Runtime shape:

- The kernel and design model run as one native Bend binary: a local
  daemon plus a CLI, from Bend's C lane.
- Bend's JS lane gives a browser build of the same code for the
  viewer and for sharing.
- The GPU lane serves batch work: tessellation, meshing, analysis
  kernels.
- The agent interface is a thin protocol layer over the daemon.

**Design representation (A3 decision).** A design is a declarative
design graph in a small text format, interpreted by the kernel
binary:

- parts, sketches, features, assemblies;
- parameters, requirements, materials, PMI.

It is deterministic, diffable, branchable and replayable, and it is
the only source of truth. Requirements are runtime checks with P3
status. Generators that need code (blades, gears, patterns) are Bend
plug-ins compiled into the kernel. Kernel algorithms keep laws; design
requirements keep evidence.

## 15. Tracks and milestones

Four tracks advance together. Each milestone is a packet with a
contract, laws, negative tests, a receipt, and (from A0 on) an agent
transcript.

### Kernel track (C)

C06–C13 as in Revision 4, with these additions:

- **C06** also delivers the minimal design-model evaluator (parts
  built from ops, parameters, rebuild on edit). This is the first
  thing the agent drives.
- **C05.2** (after C07): curved-edge arrangements (arcs and circles
  in regions). The solver already handles arcs.
- **C14 Assemblies**: components, placements, mates/joints,
  kinematic DOF, interference and clearance (C11 queries), exploded
  views.
- **C15 PMI/GD&T**: semantic dimensions and tolerances bound to
  durable selectors, datum reference frames, ISO GPS / ASME Y14.5
  semantics, exported with STEP AP242.
- **C16 Specialized modeling** (as needed by the ladder): sheet metal,
  surface modeling, blade/airfoil sections.

### Agent track (A)

- **A0 Protocol v0** (with C06). Sessions, transactions
  (begin/commit/rollback), create/edit/query/verify, structured
  results and failures, design text v0, job model. MCP (Streamable
  HTTP and stdio) is the primary transport, with a CLI and SDK over
  the same protocol. Exit: G1.
- **A1 Perception.** Rendered named views, sections, highlights and
  revision diffs as images, plus structured summaries (tree, mass
  properties, bounding boxes, open issues).
- **A2 Requirements.** A requirement language (dimensions, fits,
  clearances, mass, envelope, stress/thermal margins, DFM rules)
  compiled to checks with P3 status. "Done" = all checks pass.
- **A3 Durable references.** Semantic selectors across edits (with
  C08 lineage). Agent edits of an early feature propagate or fail
  loudly.
- **A4 Challenge harness.** A fresh-session runner, briefs,
  independent graders, scoring, regression tracking (§16).
- **A5 Skills.** BendCAD workflows as Claude skills, shipped in the
  repo:
  - design process (requirements → layout → detail → verify);
  - DFM review;
  - tolerance stack-up;
  - analysis setup;
  - drawing production.
- **A6 Project memory.** A design journal, decisions with rationale,
  open issues and assumptions, stored with the design, so
  multi-session work on a large product (an engine) stays coherent.

### Engineering track (E)

- **E0 Materials.** Properties with sources and uncertainty,
  temperature dependence, allowables by process and condition.
- **E1 Tolerancing.** ISO 286 fits, GD&T evaluation, stack-up
  analysis (worst-case, RSS, Monte Carlo).
- **E2 Standard parts.** Parametric fasteners, bearings, seals,
  springs and gears from standards, with their engineering data
  (preload, life, ratings).
- **E3 Structural analysis.** Meshing from kernel geometry; linear
  static and modal FEA with convergence evidence; rotordynamics.
  Bend-native is the target (the GPU lane fits FEA). Until it exists,
  a declared external open solver (for example CalculiX) may run as a
  labeled, replaceable analysis tool (A3 decision). Every result
  names its solver, and each such tool has a Bend-native replacement
  milestone. Geometry never leaves Bend.
- **E4 Thermal and fluid.** 1D networks first; 3D CFD later, under
  the same declared-external-solver rule as E3.
- **E5 DFM.** Machining, additive, casting and sheet-metal rules
  checked against the model, with process-aware tolerances and cost.
- **E6 Domain packs.** Turbomachinery (cycle analysis, velocity
  triangles, blade design), gears, bearings, bolted joints, pressure
  vessels. Added in ladder order.

### Product track (P)

- **P0 Viewer.** Aethalgard's three.js viewport rebuilt on kernel
  tessellation (C10) and design-model events.
- **P1 App shell.** Desktop and web; shows agent sessions live;
  review and approve by policy.
- **P2 Direct manipulation.** Drags and picks emit design-model ops
  (§14.2, P1).
- **P3 Release.** v1 → v2 migration (STEP import of v1 designs),
  packaging, documentation, open-source launch.

## 16. The challenge ladder

Each rung is an eval.

- **Brief:** a written brief of the kind a customer would write.
- **Run:** a fresh agent session with only BendCAD's interface and
  skills.
- **Grading:** independent graders. These are separate code, not
  BendCAD's own checks, plus human review at the higher rungs.
- **Pass:** every graded requirement met, with evidence of the
  stated strength.
- **Artifact:** transcript, design, deliverables and grader report.

A rung passing once is a demo; passing repeatably across seeds and
briefs is capability.

| Rung | Challenge | Exercises |
|---|---|---|
| G1 | Parameterized mounting bracket, curved boundary, holes | C06, A0 |
| G2 | Flanged pump housing with bolt pattern, gasket groove, fits | C07–C09, A1–A2, E1 |
| G3 | Two-stage gearbox: gears, shafts, bearings, housing, seals, stack-up | C14, E1–E3, E6 gears |
| G4 | Centrifugal blower assembly with modal FEA and DFM for machining | E3, E5, C15 drawings |
| G5 | Micro turbojet, KJ-66 class (~100 N): centrifugal compressor, annular combustor, axial turbine, shaft and bearings, nozzle; drawings a hobby shop can build from | E6 turbomachinery, E0 hot-section materials, A6 |
| G6 | Bespoke jet engine from a performance brief | everything |

G5 has public ground truth: hobbyists build that class of engine from
drawings. That makes it the first rung where "buildable" can be
checked against the real world, eventually by building one.

## 17. What stays honest

- "Buildable" and "certified" are different claims. The ladder
  targets buildable, with analysis evidence. Airworthiness
  certification, combustion chemistry, creep-life prediction and
  high-fidelity turbomachinery CFD are research-grade. BendCAD must
  report them as estimates with stated methods until qualified
  methods exist. It never presents an estimate as a guarantee.
- The four proof categories of §11 extend to designs. A requirement
  check is labeled proven, certified, estimated or assumed exactly as
  kernel results are.
- The Bend `--verdict` kernel cannot yet evaluate F64. The trusted
  base includes the TypeScript checker until BendTT gains native F64
  (fork work, planned under L0).

## Primary references

[1] Bend fork and initial audited baseline: https://github.com/jnadeau207-collab/bend/tree/0b7e2b11c1054f5d0f4eb955cadb47997ef1115d ; canonical numeric contract and implementation program live in the fork.

[2] Berkeley SoftFloat interface and arithmetic semantics: https://www.jhauser.us/arithmetic/SoftFloat-3/doc/SoftFloat.html

[3] Metal software-binary64 prior art and author-reported qualification limits: https://github.com/guyfischman/metal-softfloat/blob/main/docs/ieee754_conformance.md ; pin the implementation commit before adoption.

[4] Berkeley TestFloat: https://www.jhauser.us/arithmetic/TestFloat.html

[5] MPFR manual and binary64 emulation considerations: https://www.mpfr.org/mpfr-4.2.2/mpfr.html

[6] Shewchuk, adaptive-precision geometric predicates: https://www.cs.cmu.edu/~quake/robust.html

[7] Bend F32 JS representation soundness defect: https://github.com/bendlang/bend/issues/797

These references motivate the design. No cited external test result is presented as a BendCAD test run.

## Amendment record

**A1 — 2026-09-26: C04/C07/C11 boundary.** The C04 exit wording ("vertex links, orientation, ... self-intersecting ... diagnosed") was broader than the machinery the roadmap stages at C07 (general intersection: broad-phase bounds, subdivision/root isolation) and C11 (interference/containment classification). C04.1 had narrowed scope by contract deferral instead of by plan authority. This amendment resolves the inconsistency by plan authority: C04 means topologically coherent and locally geometrically consistent (predicate-level checks over C00–C03 only), with the C04 inclusion list, the C07/C11 exclusion list, and the self-intersection terminology reservation now stated in the C04 section above. C04.1 (`4cae05d`) is therefore incomplete against the amended C04: it lacks vertex-link validation, per-face orientation self-consistency, shell connectedness, coincident-vertex detection, same-face segment-crossing detection, and quadric implicit membership. Those six are the C04 completion list; nothing else may be pulled into C04 without a further amendment.

**A2 — 2026-09-27: proof methodology.** Every packet closeout qualifies its exit criteria in four layers, recorded in an exit receipt matrix with exactly these columns: exit req, formal spec, predicate, pos witness, neg witness, stage-isolated, independent evidence, status. Layer A (semantic invariant): fixture-independent laws stating what each validation stage MEANS (quantified binders and micro-stores only — no exit fixture referenced), so stage semantics are pinned independently of fixture plumbing. Layer B (implementation theorem): closed laws over the actual implementation — one instance per pipeline arm (constructors, walks, verdicts) plus end-to-end accept/reject instances — all machine-checked. Layer C (stage-isolated adversarial fixtures): every negative exit fixture fails EXACTLY one stage (passing all earlier stages under the contract's first-match-wins order) and every positive exit fixture traverses all stages; isolation is corroborated by unit/walk-code pins, never asserted from the end-to-end verdict alone. Layer D (independent qualification): evidence independent of the artifact being qualified — triple-lane byte-equality, regression-hash reproduction against predecessor receipts, and independent oracle scripts or Layer-A cross-checks where no oracle script exists; carried-oracle scope limits are stated, never silent. A matrix row is PASS only when its law witness is closed AND its runtime witness is green on the qualifying lanes. The C04 closeout (`docs/c04-contract.md` §15) is the first matrix under this amendment.

**A3 — 2026-09-29: BendCAD is Aethalgard v2, agent-native.** Owner direction: BendCAD is version 2 of Aethalgard, the first agent-native professional CAD system, open source, built so that a fresh agent session can design a buildable product (up to a bespoke jet engine) through an interface made for the agent.

This amendment:

- replaces the §1 "not a replacement for Aethalgard" boundary;
- brings the design model, engineering, agent interface, app and deliverables into scope (§14–§17);
- re-states C06's exit as a graded agent run (G1);
- adds C14 assemblies, C15 semantic PMI/GD&T and C16 specialized modeling, and the A/E/P tracks;
- makes the challenge ladder (§16) the product test.

Owner decisions:

- designs are a declarative text graph interpreted by the kernel (not Bend programs); generators are Bend plug-ins;
- declared, labeled external open solvers are allowed for analysis only until Bend-native ones replace them; geometry is Bend-only without exception;
- new code is Apache-2.0;
- Aethalgard v1 is frozen now;
- v2 is named BendCAD.

MCP is the primary agent transport. Correctness rules (laws, A2 proof layers, failure semantics, no borrowed kernels) are unchanged. The proposal text this amendment adopts is §14–§17.
