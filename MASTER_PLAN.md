# BendCAD Master Plan

**Revision 3 — September 26, 2026 (Amendment A1: C04/C07/C11 boundary; see Amendment record)**

**Objective:** deliver production-qualified binary64 in Bend 2, including actual GPU execution on Metal, then build an independent professional CAD kernel whose geometry and topology algorithms are written in Bend.

**Present status:** the pre-VibeCAD Aethalgard kernel/reference corpus is recovered. This document specifies future implementation; it does not claim that F64, a Bend-native kernel, or their qualification already exist.

## 1. Three projects, three boundaries

Production Aethalgard remains the existing Electron/React/Three.js, Engineering Core, and headless FreeCAD/OCCT product. It receives no experimental Bend dependency and is not rewritten or replaced by this program.

The Bend language fork is `jnadeau207-collab/bend`. BendCAD's authoritative dependency is the exact commit in root `BEND_PIN`; the initial audited pin is `0b7e2b11c1054f5d0f4eb955cadb47997ef1115d`. Generic scalar representation, U64/F64, compiler/runtime integration, Metal software binary64, backend identity, and conformance work live in that repository. BendCAD does not carry a competing F64 RFC. Advance `BEND_PIN` only to an exact Bend commit that has satisfied the required numeric gate.

`jnadeau207-collab/BendCAD` owns the new CAD kernel, its laws and proofs, professional geometry algorithms, command-line interface, SDK, interchange, and qualification corpus. Its runtime geometry must not depend on FreeCAD, OCCT, PlaneGCS, or another existing CAD kernel.

Compiler backends, operating-system I/O, device dispatch, and a qualified numeric runtime may contain C, C++, JavaScript, and Metal code. Those are declared implementation boundaries, not permission to hide CAD algorithms behind foreign calls. The archived OCCT evaluator may run only as a separately identified test oracle.

The product target is a professional boundary-representation kernel with analytic and NURBS geometry, trimmed surfaces, robust booleans, feature modeling, queries, tessellation, and interchange. Mesh-only or voxel-only modeling is not a substitute. A GUI and a complete CAM/FEM application are separate consumers, not prerequisites for a useful kernel release.

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

Preserve original notices and third-party provenance. Do not place a new blanket license over imported material. Resolve the license for new BendCAD code explicitly; retain the original proprietary/UNLICENSED and third-party distinctions until then.

Three recoverable references remain useful for subsequent archaeology, but are not interchangeable baselines: local-worktree snapshot `1eab12971dcb22c0b75f9d3714ba377d86ab36b5`, archive manifest `213180dd5b2d0c805ae9610bf88be5cd82111b0f`, and the selected tip above. Any additional branch recovery gets its own provenance, not silent mixing.

## 3. Bend is a pinned prerequisite, not part of the CAD kernel

The canonical numeric contract and execution order live in the Bend fork:

- `bend2/docs/F64_CONTRACT.md`
- `bend2/docs/F64_IMPLEMENTATION.md`

This plan does not duplicate them. If Bend's numeric contract changes, change it there first, qualify it there, then advance `BEND_PIN`.

The #797 class shaped the representation: upstream closed `bendlang/bend#797` as not planned, so F32 on JS stays bit-unreliable and F64 geometry is built on the as-bits representation instead, which is immune to that failure. F32 stays out of authoritative geometry; see the host gate in section 4a.

## 4. Required Bend handoff gates

Serious BendCAD geometry numerics may begin once the pinned Bend commit closes the host gate. Device claims additionally require the device gate. Status below is at `BEND_PIN` `jnadeau207-collab/bend@50ec219a` (tag `numeric/2026-09-25`), whose evidence is the fork's `conformance/receipts/2026-09-25.txt`.

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

Implement primitives, extrusion, revolution, pad/pocket semantics, holes, and transformations using the preceding geometry and topology. Handle multiple profile regions, axis crossings, and degenerate input explicitly.

Exit: a parameterized mechanical bracket with a curved boundary and holes is authored through the CLI, validated, measured, serialized, reopened, edited, and tessellated without any existing CAD kernel at runtime. This is the first end-to-end foundation, not the professional-completion ceiling.

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

### C13 — Professional release qualification

Deliver a stable CLI and documented SDK/native integration boundary, reproducible builds, structured errors, resource/cancellation behavior, diagnostics, and compatibility tests across advertised targets. Publish a feature matrix grounded in admitted input domains and tests, not method-name counts.

Qualify a broad, versioned corpus of mechanical parts and pathological geometry; include varied scales, repeated feature edits, mixed analytic/NURBS solids, corrupted input, crash recovery, and long operation sequences. Material performance regressions block release. The professional-grade claim belongs to this evidence, not to a successful compiler run.

## 11. Proof strategy and the trusted boundary

Maintain four separate categories: formally proven properties, certified numerical bounds, experimentally tested behavior, and trusted assumptions. None is silently relabeled as another.

Useful early laws include valid generational references, closed oriented-use cycles, valid mesh indices, failure preserving the accepted revision, deterministic selector cardinality, and constructor preservation of topology invariants under explicitly stated geometric premises.

For example, an extrusion closure theorem must state premises about a valid simple planar region, its holes, a permitted sweep direction, and nondegeneracy. Merely storing `closed = True` is not a proof that geometry bounds a valid solid.

Keep owner-reviewed laws separate from implementation proofs. Changing a law, admitted domain, or tolerance to make a failing implementation pass requires explicit review. No holes, unchecked axioms, or unsafe functions may enter the claimed proof dependency graph unnoticed.

The trusted computing base includes Bend's checker, elaboration/erasure/compiler passes, numeric primitive assumptions, runtime, device compiler, and hardware. A proof about source terms does not automatically prove those implementations correct. Record that boundary and reduce it incrementally rather than claiming infallibility.

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

Use ordinary incremental commits; preserve existing work and do not force-reset branches. Keep generic numerical improvements upstreamable instead of embedding CAD names in Bend's compiler. Do not change production Aethalgard for this side project.

## 13. First execution packet

The host prerequisite gate (§4a) is closed at `BEND_PIN`, so host geometry work may proceed on the qualified F64 substrate; device claims wait on the device gate (§4b).

Work allowed in parallel:

- preserve and verify the immutable Aethalgard reference corpus;
- build oracle adapters outside `legacy/`;
- inventory operation semantics and adversarial fixtures;
- specify CAD-side contracts whose correctness does not depend on pretending F64 already exists.

`BEND_PIN` now names a qualified numeric commit (`numeric/2026-09-25`), so BendCAD starts at C00/C01/C02: failure semantics, mathematical foundation, then robust predicates. It does not start with an OCCT bridge or a box demo.

**Dependency order:** Bend representation soundness → full-width U64/F64 transport → qualified core binary64 → pinned host handoff → BendCAD numerics/predicates → B-rep foundations → intersections/booleans/features → interchange and professional qualification, with device qualification alongside (CUDA receipted; Metal execution pending a Mac).

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
