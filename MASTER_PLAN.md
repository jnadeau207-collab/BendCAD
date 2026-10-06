# BendCAD Master Plan

**Revision 5 — September 29, 2026 (Amendments A1: C04/C07/C11 boundary; A2: proof methodology; A3: BendCAD is Aethalgard v2, agent-native; A4: certified-rounding membership; A5: C06 closeout ownership; see Amendment record)**

**Objective:** deliver production-qualified binary64 in Bend 2, including actual GPU execution on Metal, then build an independent professional CAD kernel whose geometry and topology algorithms are written in Bend. That kernel is Aethalgard v2: **BendCAD**. It is open source and built to be the world's best CAD kernel for AI agents (§14): never silently wrong, self-explaining, identity by meaning, toleranced and state-aware, fast and massively parallel.

**Acceptance sentence:** a fresh Claude session told "pull up BendCAD and design me a bespoke jet engine" produces a buildable design, meaning:

- analytic geometry, with tolerances and fits that close;
- materials suited to their loads and temperatures;
- an assembly that goes together;
- drawings, BOM and manufacturing data;
- evidence for every claim, labeled by strength.

The challenge ladder (§18) measures progress toward it.

**Present status:** the pre-VibeCAD Aethalgard kernel/reference corpus is recovered. This document specifies future implementation; it does not claim that F64, a Bend-native kernel, or their qualification already exist.

## 1. Three projects, three boundaries

BendCAD is Aethalgard v2 (Amendment A3). It replaces Aethalgard's FreeCAD/OCCT engine, and the whole product, with a Bend-native system. Production Aethalgard v1 (Electron/React/three.js, Engineering Core, headless FreeCAD/OCCT) is frozen: no further feature work, no Bend dependency added to it. v1 remains a reference for UX and product vocabulary: its three.js viewport, command catalog, interaction contracts, MCP/agent-control history and Engineering Core concepts are mined for v2 like `legacy/aethalgard/`.

The Bend language fork is `jnadeau207-collab/bend`. BendCAD's authoritative dependency is the exact commit in root `BEND_PIN`; the initial audited pin is `0b7e2b11c1054f5d0f4eb955cadb47997ef1115d`. Generic scalar representation, U64/F64, compiler/runtime integration, Metal software binary64, backend identity, and conformance work live in that repository. BendCAD does not carry a competing F64 RFC. Advance `BEND_PIN` only to an exact Bend commit that has satisfied the required numeric gate.

`jnadeau207-collab/BendCAD` owns the new CAD kernel, its laws and proofs, professional geometry algorithms, command-line interface, SDK, interchange, and qualification corpus. Its runtime geometry must not depend on FreeCAD, OCCT, PlaneGCS, or another existing CAD kernel.

Compiler backends, operating-system I/O, device dispatch, and a qualified numeric runtime may contain C, C++, JavaScript, and Metal code. Those are declared implementation boundaries, not permission to hide CAD algorithms behind foreign calls. The archived OCCT evaluator may run only as a separately identified test oracle.

The product target is a professional boundary-representation kernel with analytic and NURBS geometry, trimmed surfaces, robust booleans, feature modeling, queries, tessellation, and interchange, designed first for agents (§14). Tolerances, operating states, lineage identity, diagnoses and sensitivities are kernel semantics, not add-ons. Mesh-only or voxel-only modeling is not a substitute. The agent interface is a thin typed layer over the kernel's operation algebra (§16). Viewers and applications are later, thin consumers.

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

Serious BendCAD geometry numerics may begin once the pinned Bend commit closes the host gate. Device claims additionally require the device gate. `BEND_PIN` is `jnadeau207-collab/bend@a4d17acecf79c71696610f0683d8d003bc392920`, tag `numeric/2026-10-05` (branch `numeric-on-upstream`: upstream `653e391b`, then the replayed U64, F64, conformance harness and historical receipt, the min/max and show/read commit `288da083`, the host scheduler, and its conformance receipt). The host and device gates were re-run on this pin: the fork's `conformance/receipts/2026-10-05.txt`. The earlier evidence for `bc01485d` stays in `docs/receipts/bend-pin-2026-09-29.txt`.

### 4a. Host gate (closed for `numeric/2026-10-05`)

H1. F64 geometry is built on the as-bits representation, immune to the #797 class; F32 stays out of authoritative geometry. (Was 1, 2, redefined: upstream will not fix #797.)
H2. Raw `w64` distinguished from tagged runtime `Term`. (Was 3.)
H3. Arbitrary U64 transport through constructors, arrays, closures, scheduling and host execution. (Was 4.)
H4. Exact F64 `from_bits/bits` transport. (Was 5.)
H5. Qualified add/sub/mul/div/sqrt/FMA and required conversions on host lanes (interpreter, JS, C): 2^20 cases per group over 22 groups with 0 mismatches, plus representation probes and the show/read text check, per the receipt. (Was 6.)

### 4b. Device gate (CUDA closed for `numeric/2026-10-05`; Metal open)

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

Implement primitives, extrusion, revolution, pad/pocket semantics, holes, and transformations using the preceding geometry and topology. Handle multiple profile regions, axis crossings, and degenerate input explicitly. Every operation states its intended effect (added/removed material, created/modified faces), and the kernel checks the effect against that intent before publishing (§14, property 4).

C06 also delivers the minimal design-model evaluator: parts built from ops, parameters, and rebuild on edit. It pairs with A0 (§17).

Exit (G1, §18): a parameterized mechanical bracket with a curved boundary and holes is authored by a fresh agent session from a written brief, through the agent interface. It is then validated, measured, serialized, reopened, edited and tessellated, with no existing CAD kernel at runtime, graded by independent checks, and the transcript is kept in the receipt. This is the first end-to-end foundation, not the professional-completion ceiling.

### C07 — General intersections

Implement curve/curve, curve/surface, and surface/surface intersection with broad-phase bounds, subdivision/root isolation, refinement, endpoint classification, and complete admitted-domain coverage. Include tangency, coincidence, overlapping intervals, seams, and singularities. Newton iteration can refine an isolated candidate; it cannot by itself establish that all intersections were found.

Exit: return intersection curves and topology/parameter correspondence, not only sampled points. Unresolved regions remain explicit uncertainty. C07 owns general geometric self-intersection detection (curved-edge crossings, cross-face and inter-loop penetration) excluded from C04, the broad-phase bounds that coarse cavity nesting checks build on, and the inside/outside classification that global outward shell orientation needs. Prerequisite shared with C06: parametric evaluation and parameter conventions for every C03 surface arm (the C03 surface-evaluation extension). C07 also owns certifying that a design's topology is constant over a parameter box, which tolerance-envelope evaluation needs (A5).

### C08 — General B-rep booleans

Implement regularized union, difference, and intersection: intersect, split edges/faces, classify fragments, assemble boundaries, orient shells, validate, and publish. Handle disjoint solids, containment, coplanar/coincident faces, tangent contact, thin features, cavities, and legitimate empty results.

Record created/modified/deleted and one-to-many/many-to-one topology lineage. A durable selector resolves uniquely, resolves an intended set, or reports missing/ambiguous; it does not silently choose a nearby face.

Exit: analytic and NURBS cases pass independent geometry checks, volume identities, repeated edits, and serialization replay. Voxel booleans are not substituted for this milestone.

### C09 — Professional feature modeling

Add sweep, loft, fillet, chamfer, draft, offset, shell/thicken, and feature patterns. Cover guide curves, continuity, twist, self-intersection, variable-radius blends, corner construction, and topology evolution. Use the same evaluator path for all future human and agent clients.

C09 also owns rigid-cluster decomposition in the C05 solver, for drag and incremental re-solve over large single clusters (A5).

Exit: each feature family has ordinary mechanical cases, degenerate cases, repeated downstream edits, bounded-error reports, and native Bend implementation evidence. One successful fillet does not qualify the family.

### C10 — Manufacturing-grade tessellation

Implement trim-aware meshing, consistent shared-edge samples, normal/orientation handling, seam treatment, and explicit LOD/quality controls. Bound error on the delivered mesh after welding, simplification, transforms, and numeric narrowing, not on an intermediate mesh that is later changed.

C06 ships a display tessellator: watertight, oriented and sharing edge samples, with no stated bounds (`docs/c06-contract.md` §10). C10 replaces it.

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

C13 runs last. It qualifies the release after C14–C16 have delivered the ladder rungs (§18) the release claims.

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

`BEND_PIN` named a qualified numeric commit (`numeric/2026-09-29`) when BendCAD began, so it started at C00/C01/C02: failure semantics, mathematical foundation, then robust predicates, not an OCCT bridge or a box demo. C00–C05 are closed (C05.1 at `48ab78c`). R0, the speed and parallelism rebuild of C00–C05, is closed (§15, A5). C06 + A0 is closed: G1 passed (§18; receipt `docs/receipts/c06.1-2026-10-05.txt`). C07 is closed (`docs/c07-contract.md`, receipt `docs/receipts/c07-2026-10-06.txt`). Next is C08.

**Dependency order:** Bend representation soundness → full-width U64/F64 transport → qualified core binary64 → pinned host handoff → BendCAD numerics/predicates → B-rep foundations → intersections/booleans/features → interchange and professional qualification, with device qualification alongside (CUDA receipted; Metal execution pending a Mac).

## 14. The world's best kernel for agents (Amendment A3)

The product is the kernel. An agent designing a jet engine needs a
kernel it can trust without looking, query instead of eyeballing, and
explore at massive scale. It needs these nine properties. Every packet
advances them and none may regress them.

1. **Never silently wrong.** Laws on every operation, exact
   predicates, certified bounds. When a result cannot be established,
   the kernel says "uncertain" rather than guessing. C05.1 is the
   pattern: every residual's zero set is audited, and discriminating
   laws pin it.
2. **Every failure is a diagnosis.** A failure says what failed, where
   (by durable name), why (machine-readable), and the smallest known
   fix. The C05 solver's named conflicts, dof and redundancy are the
   template for every operation.
3. **Identity by meaning, forever.** Every vertex, edge, face, feature
   and parameter is named by lineage: the operation that made it,
   from what inputs. After an edit a name resolves exactly, or fails
   loudly as missing or ambiguous. Nothing is positional.
4. **Checked intent.** An operation carries its intended effect:
   material added or removed, faces created, cardinality, topology
   class. The kernel verifies the effect before publishing, so a
   valid-looking wrong result becomes a visible error.
5. **The design is a pure, content-addressed operation graph.** Each
   node is keyed by its full content: its operation, evaluated
   parameters, declared intent and its inputs' keys. Reuse requires an
   exact key match; no hash is trusted (C00's `op_id` identifies a
   request for cancellation and display). This gives:
   - memoized, incremental rebuilds;
   - free branching and exact diffs;
   - bit-identical results on every lane.

   Designs are written as Bend programs that build the graph. The
   graph, not the program text, is canonical. Requirements are checks
   on the graph, and laws where they are cheap enough to prove.
6. **Toleranced, state-dependent geometry is native.** A jet engine
   lives on microns:
   - bearing fits of a few µm;
   - blade profiles within a few hundredths of a millimetre;
   - tip clearances that thermal and centrifugal growth move by
     more than their tolerance.

   So a dimension is a nominal plus a tolerance zone, and a design is
   evaluated in named operating states (cold build, hot running,
   overspeed). Fit, clearance and interference are certified:
   - over the whole tolerance envelope, by interval/affine arithmetic
     (worst case);
   - statistically, by massively parallel sampling;
   - in every state, by composing displacement fields the analysis
     layer supplies.
7. **Sensitivities with every answer.** Every measure and query
   returns its derivatives with respect to design parameters, where
   they exist, and says where they do not (topology changes). The
   C05 Jacobians are the seed. Sensitivities drive repair hints,
   tolerance allocation and optimization.
8. **Perception as structure.** The agent queries, it does not look:
   - which faces bound this pocket;
   - thinnest wall here, certified;
   - what changed since the previous revision;
   - the full stack-up behind this clearance.

   Rendering is a debugging aid for humans, never the interface.
9. **Fast and massively parallel.** See §15. This is Bend law, not an
   optimization.

## 15. Speed and parallelism are law

Victor's standard applies to every packet: correct, compact, fast, one
general mechanism, and parallel by construction.

- **Measured, not assumed.** Every operation's contract states its
  complexity and a latency budget. Receipts include scaling curves.
  A performance regression blocks a packet like a failing law.
- **Shapes that parallelize.** Use balanced trees and arrays, never
  `nth` inside a loop. Use divide-and-conquer and tree reductions,
  never long sequential folds where a tree exists. Batch operations
  (variants, samples, tessellation, stack-ups) map over independent
  work. Parallel claims are qualified by measured speedup on the
  thread and GPU lanes (§4b), not by the absence of sequential code.
- **Interactive by default.** A local edit to a large part re-evaluates
  only the dirty subgraph (§14, property 5). Agent feedback loops must
  stay interactive at jet-engine scale.
- **Before R0 (measured 2026-09-29, native lane).** C05 was correct
  and verified, but not Bend-grade: arrangement 100 segments 220 s
  (200 did not finish); solver 160 parameters 3.5 s. The causes were
  list-based insertion sorts, positional lookups inside loops, and a
  dense solver.
- **R0.1 — C05 rebuilt (done, 2026-09-30).** Sort-and-sweep candidate
  pairs, parallel merge sorts, pointer jumping and Shiloach–Vishkin
  components, a slab index for nesting (replaced at R0.4); the solver
  splits into independent clusters solved in parallel, each on a
  sparse Jacobian with a nested-dissection multifrontal Givens
  factorization and a sparse rank-revealing QR. Semantics unchanged (laws, oracles,
  three-lane identity); receipt `docs/receipts/r0.1-2026-09-30.txt`.

  | Engine | Size | Before | R0.1 |
  |---|---|---|---|
  | Arrangement | 100 segments | 220 s | 0.2 s |
  | Arrangement | 10,004-segment plate | — | 1.0 s |
  | Arrangement | 40,004-segment plate | — | 5.5 s |
  | Solver | 8,000 parameters, 1,000 parts | — | 0.6 s |
  | Solver | 24,000 parameters, 3,000 parts | — | 2.0 s |
  | Solver | 10,002-parameter chain, one cluster | — | 3.7 s |
  | Solver | 3,200-parameter grid, one cluster | — | 5.0 s |

- **R0 audit of C00–C04.** C00, C01 and C02 hold no collections.
  C03 revalidates a NURBS knot vector and scans for the span on every
  evaluation (O(k) per point): acceptable until batch evaluation
  (C10), where a validated handle with tree-indexed knots replaces it.
  C04 validation is roughly cubic: a plane face with 101 loops (404
  entities) checks in 16 s, dominated by same-face crossing (stage K)
  and shell connectivity (stage I), and every handle resolve walks a
  list.
- **R0.2 — C04 validation and C02 exactness (done, 2026-10-01).**
  `brep_checked` runs on a store index (`Ty.Ix`, tree-backed, `O(log n)`
  resolve) with every stage a sort, grouped pass, pointer jump or
  sweep: edge uses and seams by sorted keys, vertex links by pointer
  jumping on the `twin(prev())` graph, shell connectivity by
  edge-incidence sort and `components`, coincidence by sort, crossings
  by a bounding-box sweep. A stage decides iff fuel covers the longest
  store or member list (the §8 contract, now exact; R0.4 adds each
  NURBS edge's `nk + 1`); one verdict
  changed on purpose: a vertex orbit that never returns is invalid,
  no longer fuel-out. C02's exact fallback is now Shewchuk expansion
  arithmetic (`src/base/ex.bend`, shared with C05), so every finite
  input of moderate magnitude is decided, not only small integers.
  Evidence: a differential oracle against the old validator (1026
  mutated breps, 0 unexplained mismatches; 10/10 planted bugs caught);
  C04 laws: 94 restated, 5 new; C02 laws: 6 restated from uncertain to
  exact, 4 new overflow laws, the 5 small-integer laws removed with
  their kernel; every law pinning a changed verdict fails on the old
  code; all law files checked in full; receipt `docs/receipts/r0.2-2026-10-01.txt`.

  | Workload | Before | R0.2 |
  |---|---|---|
  | Holed plate, 404 entities | 16.2 s | 0.19 s |
  | Holed plate, 6,404 entities | — | 5.0 s |
  | Comb prism, 80 entities | 24.1 s | 0.24 s |
  | Comb prism, 1,000 entities | — | 3.7 s |

  C04 `push` was `O(n)` per entity (list stores), so building `n`
  entities by push was `O(n²)`. Closed at C06: every builder constructs
  its B-rep in one bulk pass with final generations, `O(n log n)`
  (`docs/c06-contract.md` §4); a plate with 1,600 holes builds in
  0.84 s.
- **R0.3 — single-cluster latency and the parallel lanes
  (2026-10-01).** The solver starts at the floor of its damping
  clamp (`2^-30 λ₀`) and keeps the ceiling (`2^60 λ₀`). The times
  below are the R0.3 receipt's. "Pinned" there is `~/.bend/bin/bend`
  at `bc01485d`; R0.4 re-measured on its own pin (below). The 0.81 s
  grid and 1.06 s chain are not that pin. They are the side binary
  `/home/jesse/bend-r03/bin/bend`, compiled 2026-10-01 from
  `0759b75046bc4946438c6b812ee2f64549c07b63`. That side scheduler
  engages one thread per occupied row and drains a small frontier
  flat. `0759b750` is not an ancestor of `BEND_PIN`, and it was not
  replayed onto the upstream pool. R0.1 on this machine, previous
  damping: chain 3.71 s, grid 5.02 s. A banged GPU call on this
  WSL2 machine fails closed (no concurrent managed access).
  Rigid-cluster decomposition and tree-shaped BendCAD sequences
  are not in this packet. Receipt `docs/receipts/r0.3-2026-10-01.txt`.

  | Workload | R0.1 | Pinned t1 | Pinned, 16 threads | Side `0759b750` t1 | Side `0759b750`, 16 threads |
  |---|---|---|---|---|---|
  | sol-chain-5000, 10,002 parameters | 3.71 s | 1.42 s | 1.38 s | 1.46 s | 1.06 s |
  | sol-grid-40, 3,200 parameters | 5.02 s | 1.63 s | 1.63 s | 1.60 s | 0.81 s |
  | sol-truss-16, 16×16 | — | 0.58 s | 7.03 s | 0.57 s | 0.38 s |
  | sol-rects-1500 | — | 1.03 s | 0.76 s | 1.03 s | 0.97 s |

  The truss row at 16 threads is 7.03 s on the pinned compiler and
  0.38 s on the side scheduler. A sentence that no speedup above
  2× was measured is false next to that row. sol-rects-1500 at 16
  threads is slower on the side scheduler (0.97 s vs 0.76 s). A3
  disposition: historical regression on the side scheduler, not a
  number re-measured here.

  The host scheduler is on the pin since R0.4: `numeric/2026-10-05`
  (`a4d17ace`) is `288da083` plus the side scheduler's turns
  replayed onto upstream's pool, a listed small frontier, and a turn tag
  that closes a double-drain race the first replay had. Measured
  2026-10-05 with the pinned binary, idle, best of 3, 16 threads,
  against `288da083`: grid 1.5 → 0.8 s, chain 1.3 → 1.0 s, truss
  0.5 → 0.4 s, `pm_map` 0.5 → 0.1 s, a 40,004-segment plate
  3.6 → 2.71 s; rects, best of 10, 0.69 → 0.58 s (the side scheduler's
  rects regression is gone). Single-thread times did not move.

- **R0.4 — audit repairs (2026-10-05).** A line-by-line audit of
  C00–C06 and R0.1–R0.3 recorded sixteen findings; every semantic
  repair has a law that fails on the predecessor (receipt
  `docs/receipts/r0.4-2026-10-05.txt`):
  - nesting (R0.1) scanned whole slabs: `m` nested squares were
    `O(m²)` (2,000 squares 6.4 s). A left ray on a segment tree with
    vertically sorted nodes makes it `O(log² E)` per component with
    acyclic chains (2,000 squares 1.1 s; plate and random unchanged or
    faster); `region_key` sorts instead of inserting;
  - C05 published a face that touches itself at a vertex as one loop
    through that vertex twice, though its contract promises simple
    loops and GEOS hole parity (a new nesting oracle family found it:
    13 of 600 cases, the same on the R0.1 code). Each walked cycle is
    now split into simple cycles;
  - C06 cache reuse trusted a 64-bit linear hash, and two parts were
    built to collide, so a cache hit republished the other part's box.
    Entries now match on the full key, which also covers coordinates,
    profiles, hole specs and transforms;
  - C06 surface evaluators accepted non-unit axes (C03 rejects them),
    and `qframe` gave left-handed frames on `-X`, `-Y`, `-Z`;
  - C06 hole clearance rounded coordinate differences before its exact
    arithmetic;
  - C06 `evm` was not fail-fast (`Bool.pick` evaluates both arms);
    duplicate node and param ids were accepted;
  - C06 profile checks looked points up by position inside loops
    (`O(n³)`); about a hundred unreachable definitions were removed;
  - C06 reported an all-pass diagnosis as `resource-exhausted`;
  - C04 `ix_bound` ignored NURBS knot lists, so a valid NURBS edge
    decided `invalid` at fuels between the bound and its knot count;
  - the C03 contract claimed control hulls contain every evaluated
    point; evaluation can leave the hull by an ulp or two (pinned);
  - stale contract rows, twelve committed scratch law files, comments
    in code, and a CI workflow that never checked `laws/c05.bend` or
    the C05/C06/base sources.
- **Exit budgets:** 10,000-segment arrangements interactive: met for
  CAD-like input at R0.1, and for nested profiles since R0.4 (8,000
  segments as 2,000 nested squares: 1.1 s on one thread, 0.8 s on
  16; 6.4 s at R0.1).
  10,000-parameter sketches on the pin at R0.4, 16 threads: chain
  1.0 s, grid 0.8 s (one thread: 1.4 s and 1.5 s). The GPU lane was
  run and refused to start on this machine.
- **R0 closed (2026-10-05, A5).** Every exit budget above is met. The
  residuals have owners: rigid-cluster decomposition goes to C09, the
  first milestone with drag and incremental re-solve over large single
  clusters (the 10,000-parameter budgets are met without it). List
  spines become trees in the milestone whose budget first measures
  them: measured hot paths already are (C04 index, C05 sweeps and
  nesting, the C06 bulk builder and tessellation point grid), and C03
  knot lists go at C10 as recorded above. The GPU lane belongs to the
  device gate (§4b): this WSL2 machine has no concurrent managed
  access, so GPU evidence needs a native Linux or macOS host. No
  C00–C06 claim depends on a GPU.

## 16. Interface and scope

- **Thin, typed, fast.** The agent interface is the operation algebra
  itself: operations, queries, diagnoses, sensitivities and
  transactions, exposed through MCP (primary), a CLI and the Bend
  library. There is no separate application layer between the agent
  and the kernel.
- **No app port now.** Aethalgard v1 is frozen (A3) and its viewer is
  not ported. A viewer, if built later, is a thin consumer of kernel
  tessellation and graph events, and it inherits §15: it cannot be
  slow.
- **Engineering where the kernel needs it.** Tolerances and fits are
  kernel semantics (§14, property 6; C15). Materials, analysis and
  domain packs arrive when the challenge ladder requires them.
  Analysis may use declared, labeled external open solvers until
  Bend-native ones replace them. Geometry is Bend-only, always.

## 17. Milestone order

1. **R0: speed and parallelism rebuild of C00–C05** (§15). R0.1
   (C05), R0.2 (C04 validation, C02 exactness), R0.3 (solver
   damping floor, host scheduler, GPU lane attempted) and R0.4 (audit
   repairs, the scheduler on the pin) are recorded. R0 is closed;
   its residuals are owned by C09 (rigid-cluster decomposition), by
   the milestone that measures each list spine, and by the device
   gate (GPU lane) (A5).
2. **C06 + A0.** Solids as content-keyed, intent-checked
   operations with lineage names and diagnosed failures; the graph
   evaluator with memoized incremental rebuild; the tolerance model
   (nominal + zone, certified interval evaluation). A0 is the MCP/CLI
   surface over it. Exit: G1. **Closed 2026-10-05**: G1 passed
   (`docs/receipts/g1/`). Every dimension carries its zone, and every
   measure is a certified interval at any parameter point. Volume and
   area are also certified over the whole envelope for primitives and
   their placements (`zone`). Envelope evaluation of profiles and
   features moves to C07 as a G2 prerequisite (A5).
3. **C07 → C08 → C09.** Intersections, booleans, features. This is
   where existing kernels are weakest, and where agents need the most
   robustness, because an agent cannot hand-repair a failed fillet.
   Sensitivities (§14, property 7) are built in, not bolted on.
4. **C14 → C15.** Assemblies with certified interference and
   clearance across the tolerance envelope and operating states;
   semantic GD&T.
5. **C10 → C11 → C12 → C16 → C13.** Tessellation, queries,
   interchange and specialized modeling in ladder order, then release
   qualification.

## 18. The challenge ladder

Each rung is an internal, graded eval, run by a fresh agent session
from a written brief using only BendCAD. Independent grader code
(not BendCAD's own checks), plus human review at the higher rungs,
decides pass or fail. Each run leaves an artifact: transcript,
design, deliverables and grader report. A rung counts once it passes
repeatably across seeds and briefs.

| Rung | Challenge | Needs |
|---|---|---|
| G1 | Parameterized mounting bracket, curved boundary, holes | R0, C06, A0 |
| G2 | Flanged pump housing: bolt pattern, gasket groove, fits certified over tolerances | C07–C09, tolerance model |
| G3 | Two-stage gearbox: gears, shafts, bearings, housing, seals, certified stack-ups | C14, C15 |
| G4 | Centrifugal blower with modal analysis and machining DFM | analysis, C10–C11 |
| G5 | Micro turbojet, KJ-66 class (~100 N), drawings a shop can build from; clearances certified in cold and running states | C16 blades, state-dependent geometry |
| G6 | Bespoke jet engine from a performance brief | everything |

G1 passed on 2026-10-05. Fresh agents ran brief A three times over two
transports (CLI, then MCP) and brief B twice, the last run on the final
C06 binary; an independent grader passed every run (`docs/receipts/g1/`).

## 19. What stays honest

- "Buildable" and "certified airworthy" are different claims. The
  ladder targets buildable, with evidence. Combustion, creep life,
  high-fidelity turbomachinery CFD and certification are
  research-grade, and are reported as estimates with stated methods
  until qualified methods exist.
- The §11 proof categories (proven, certified, estimated, assumed)
  apply to every design check as they do to every kernel result.
- The Bend `--verdict` kernel cannot yet evaluate F64. The trusted
  base includes the TypeScript checker until BendTT gains native F64
  (fork work).

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

**A3 — 2026-09-29: BendCAD is Aethalgard v2, the world's best kernel for agents.** Owner direction: BendCAD is version 2 of Aethalgard, open source. Its acceptance sentence is a fresh agent session designing a buildable, evidenced jet engine.

The first text of this amendment (`a1547de`) is superseded. It planned a viewer port and an application layer. The owner rejected that as a premature product pivot, and it is replaced here, before any packet ran under it.

The amendment:

- makes the kernel the product (§14, nine properties);
- makes speed and massive parallelism law, with measured budgets (§15);
- measures the current engines and schedules the R0 rebuild of C00–C05 before C06 (§15, §17);
- limits the interface to a thin typed layer over the operation algebra, with no app port (§16);
- adds C14 assemblies, C15 semantic PMI/GD&T and C16 specialized modeling, with tolerances and operating states as native kernel semantics;
- keeps the internal challenge ladder as the product test, with no external benchmark (§18);
- re-states C06's exit as G1.

Owner decisions:

- designs are Bend programs that build a content-addressed operation graph, and the graph is canonical;
- declared, labeled external solvers are allowed for analysis only, and geometry is Bend-only;
- new code is Apache-2.0 (the LICENSE ships at release, excluding `legacy/`);
- Aethalgard v1 is frozen;
- v2 is named BendCAD;
- MCP is the primary transport.

Correctness rules (laws, A2 proof layers, failure semantics, no borrowed kernels) are unchanged.

**A4 — 2026-10-05: certified-rounding membership for curved faces.** C04 decided whether a vertex lies on a sphere, cylinder, cone or torus by the exact zero of one F64 evaluation. F64 dimensions cannot meet that rule (a 3.2 mm radius about `x = 10` has no F64 point on it), so every curved solid would fail validation. Owner decision: a vertex is on a quadric when exact arithmetic shows the implicit equation is zero there or changes sign across the vertex's one-ulp box, which proves an exact surface point lies within one ulp per coordinate; operations report that bound as linear uncertainty. Planes and lines stay exact. Recorded in `docs/c03-contract.md` (G11) and `docs/c04-contract.md` §17, with laws that fail on the predecessor.

**A5 — 2026-10-05: C06 closeout ownership.** The owner asked for C00–C06 to be closed clean, with every R0 item closed or owned by a named later milestone in this plan. This amendment records the owners:

- Rigid-cluster decomposition goes to C09. The R0 exit budgets are met without it (10,000-parameter chain 1.0 s, grid 0.8 s). The first need is drag and incremental re-solve over large single clusters, which C09 brings.
- Tree-shaped sequences: each remaining list spine converts in the milestone whose budget first measures it. The measured hot paths are already trees or sorts (C04 index, C05, the C06 bulk builder). C03 knot lists convert at C10.
- The GPU lane belongs to the device gate (§4b). It needs a host with concurrent managed access, which this WSL2 machine lacks.
- The C04 `push` cost is closed by the C06 bulk builder.
- Tolerance envelope. §17 put "the tolerance model (nominal + zone, certified interval evaluation)" under C06, but §18 makes the tolerance model a G2 prerequisite. C06 ships:
  - a nominal and a zone on every dimension (`LO <= NOM <= HI`, enforced on edit);
  - certified interval measures at any parameter point;
  - `zone`: volume and area certified over the whole envelope wherever topology provably cannot change across it. That covers box, cylinder, cone, sphere and torus while their dimensions stay certified positive (and `R > r` for the torus), and placements of them. This is a superset of the box-only `ms_zone` that C06 had before.

  Profiles and features need a certificate that topology stays constant across the zone. C06 predicates certify single points only, and tangent junctions such as rounded corners defeat simple clearance-margin bounds. That certificate is parameter-box intersection work, so envelope evaluation of profiles and features moves to C07, ahead of G2. Delivered in C07 (`docs/c07-contract.md` §6).
