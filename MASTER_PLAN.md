# BendCAD Master Plan

**Revision 1 — September 18, 2026**

**Objective:** deliver production-qualified binary64 in Bend 2, including actual GPU execution on Metal, then build an independent professional CAD kernel whose geometry and topology algorithms are written in Bend.

**Present status:** the pre-VibeCAD Aethalgard kernel/reference corpus is recovered. This document specifies future implementation; it does not claim that F64, a Bend-native kernel, or their qualification already exist.

## 1. Three projects, three boundaries

Production Aethalgard remains the existing Electron/React/Three.js, Engineering Core, and headless FreeCAD/OCCT product. It receives no experimental Bend dependency and is not rewritten or replaced by this program.

The user's Bend fork owns generic language work: U64/F64, numeric semantics, compiler/runtime integration, Metal software arithmetic, other backend implementations, conformance tests, and upstreamable documentation. Pin the fork URL and exact commit when it exists. The inspected upstream baseline is `bendlang/bend` at `0b7e2b11c1054f5d0f4eb955cadb47997ef1115d`; re-audit any delta before implementation. Do not silently substitute another Bend generation or HVM project.

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

## 3. The numerical contract comes before implementation

Bend's existing `w64` layout and Metal `ulong` support are useful foundations, not proof that arbitrary binary64 values can already pass safely through every runtime path. The inspected runtime also has tagged terms, a reference-count bit, sentinel values, and a 48-bit immediate Nat limit. Audit their interaction before adding `F64: W64`. [1]

### 3.1 Representation and observable behavior

Define `U64` and `F64` over `Word(64n)` at the language level. U64 arithmetic is explicitly modulo 2^64 where declared; checked conversions never silently pass through the restricted Nat representation. Shift counts at or beyond the width have a defined result, not backend undefined behavior. Division by zero has one documented cross-backend policy.

F64 stores the IEEE binary64 encoding. `bits(from_bits(x)) == x` must hold for every U64 encoding, including negative zero and NaN payloads. Storage, copying, serialization, and arithmetic are separate contracts: ordinary arithmetic may produce a specified canonical quiet NaN, but merely transporting a supplied NaN must not alter its bits.

The default arithmetic profile is correctly rounded round-to-nearest, ties-to-even for addition, subtraction, multiplication, division, square root, and explicit fused multiply-add. Preserve signed zero, infinities, and gradual underflow. Do not flush subnormals or allow reassociation. `a*b+c` retains two roundings; `fma(a,b,c)` has one. Numeric equality, bit equality, unordered comparisons, and total ordering are distinct APIs.

Add classification, sign operations, `next_up`, `next_down`, floor/ceil/truncation, scaling by powers of two, and defined float/integer conversions. Distinguish truncating `fmod` from IEEE remainder. Document exceptional integer conversions instead of inheriting C undefined behavior.

### 3.2 Rounding and exceptions without hidden global state

Provide a checked numeric layer that takes a rounding mode and returns a value plus exception flags. Initial modes are nearest-even, toward zero, toward positive infinity, and toward negative infinity. Additional modes are named additions, not implied by the phrase “all rounding modes.”

Track invalid operation, division by zero, overflow, underflow, and inexact explicitly. Choose and test tininess-after-rounding semantics. Signaling NaN consumption raises invalid in this checked profile; ordinary arithmetic uses the declared canonical result policy. Never implement parallel Bend semantics using one shared process-global rounding mode or sticky-flag variable.

A backend can first qualify value-only nearest-even operations, but that is not qualification of the checked API or full IEEE behavior. SoftFloat provides a practical executable reference for these distinctions. [2]

### 3.3 Literals and persistence

Keep existing F32 literals compatible. Proposed explicit new spellings are `1.5f64` and `42u64`; finalize grammar in the numeric RFC rather than scattering provisional suffixes through CAD code. Include hexadecimal U64 and bit-exact F64 construction for fixtures.

Parse decimal F64 without an F32 intermediate. Use a defined, locale-independent grammar and correctly rounded conversion. Printing should provide shortest round-trip finite values, preserve negative zero where required, and specify infinity/NaN text. Binary serialization is explicitly little-endian; lossless NaN payload transport uses binary or hex, not ordinary JSON numbers.

Geometric input policy may reject NaNs, infinities, or excessive coordinates. That policy must not narrow the language's binary64 implementation.

## 4. How F64 will actually run on Metal

The baseline Metal implementation uses integer software arithmetic over a 64-bit encoding. It is not two F32 values and not a hidden CPU callback.

Unpack sign, exponent, and significand; classify special values; compute with sufficient integer precision; normalize; retain guard/round/sticky information; round exactly once; encode the result and flags. Multiplication needs the full product of two 53-bit significands. Implement wide arithmetic using tested 64-bit limbs or 32-bit limbs, including carry, borrow, wide multiply, and shift-right-with-jam. Native 128-bit integers are not a prerequisite.

Division and square root must retain enough remainder information for correct rounding. FMA must not round the product before adding the third operand. Cancellation and subnormal boundaries receive dedicated algorithms and tests, not epsilon patches.

Treat `metal-softfloat` as candidate implementation/prior art. Its author-reported TestFloat results are useful, but are not our own qualification; its documented value-only coverage does not establish exception-flag behavior. Pin and inspect its source and license before reuse, and reproduce relevant tests on our generated Bend path. [3]

Prefer one portable software semantic implementation that is directly testable on the CPU and can be compiled for Metal. Native CPU/CUDA instructions are optional optimized implementations of that contract. An independently maintained SoftFloat build and high-precision oracle are needed so the port is not its own sole judge.

Expose actual backend selection and require-device execution. A requested Metal qualification run with no functioning GPU must fail or report NOT RUN. A successful CPU fallback is not Metal evidence.

## 5. Exact Bend integration work

| Area | Required change |
|---|---|
| `bend2/base.bend` | U64/F64 types, bit conversions, numeric API, explicit rounding/flag types, documentation of trusted primitives. |
| `bend2/bend.ts` | Width-aware Word construction, parser/printer support, literal validation, constant handling, and checker-visible representation. Keep 64-bit integers out of lossy JS Number paths. |
| `bend2/comp.ts` | Audit `WORDS`, `OPTIMIZED`, `OPERATIONS`, `NATIVE`, layouts, constructors/destructors, constant folding, and C/JS/device lowering. |
| Native runtime | Untagged payload versus boxed value handling, function arguments/returns, closure captures, arrays, ownership/refcounts, scheduler frames, and CPU/GPU transport. |
| Driver and backend setup | Pin toolchains, strict numeric compiler options, Metal language/SDK requirements, device identity, and no-fallback qualification mode. |
| Tests | Parser, checker, layout, generic-container, ABI, arithmetic, text/binary round-trip, scheduling, and actual-device suites. |

Exercise F64 inside records, generic lists, arrays, optional values, captured closures, fork/join continuations, foreign returns, and serialized packets. A scalar `1.0 + 2.0` test cannot expose most representation defects.

C/CPU and CUDA may use native doubles only for operations that meet the contract under controlled settings. Disable fast-math, reassociation, unwanted contraction, and subnormal flushing. Verify the actual generated code and observable results.

JavaScript may use Number for qualified arithmetic, but U64 uses BigInt and bit conversion uses DataView. Raw NaN payload preservation requires an appropriate raw/boxed representation. Explicit FMA, directed rounding, and flags need software support where JavaScript does not expose the required operation. “JS already has doubles” is not sufficient.

The initial formal trust boundary may include opaque F64 primitives. Do not invent arithmetic theorems for them. Later, define a bit-level model and prove software operations/refinements incrementally. Floating-point reasoning is possible; it is not obtained merely by copying F32 declarations.

## 6. Qualification and performance

Use Berkeley TestFloat/SoftFloat for core operations, hand-derived boundary cases, and MPFR-backed references for wider numerical functions. A finite fuzz run is evidence, not a proof over all inputs. MPFR has different default exponent/subnormal behavior, so configure binary64 emulation or compute increasing-precision enclosures until the target rounding is unambiguous; blindly rounding one high-precision value twice is not a sound universal oracle. [2][4][5]

Every promised basic operation requires zero mismatches against its declared value/flag/NaN policy on the admitted suite. Include both signs, every exponent class, halfway cases, exact cancellation, overflow thresholds, gradual underflow, signaling/quiet NaNs, F32 conversions, U64 values above 2^53, and encodings resembling runtime tags or sentinels.

Run vectors through compiled Bend, not just an isolated C or Metal library. Save source/compiler commits, generated-kernel digest, device and driver, OS/SDK, compiler flags, rounding profile, vector counts by operation, seeds, failures, and actual execution backend. Never substitute another commit's receipt.

GPU speed is measured, not assumed. Benchmark per-operation latency, batched throughput, register pressure, divergence, allocation cost, dispatch overhead, memory traffic, compiler time, and end-to-end geometry workloads. Compare equivalent algorithms and numeric contracts. Keep deterministic reduction trees; parallel scheduling does not make floating-point addition associative.

Initial target matrix: Linux CPU, macOS CPU, macOS Metal on real Apple hardware, NVIDIA CUDA on an explicitly supported host, and JavaScript. Windows-native support gets a separate runtime/toolchain gate; WSL results are not relabeled native Windows. No advertised platform is qualified through another platform's tests.

## 7. Ordered numeric work packets

| Packet | Deliverable and exit criterion |
|---|---|
| N00 | Pin the Bend fork/baseline; reproduce existing tests; write the numeric RFC and backend support matrix; inventory known failures and trusted boundaries. |
| N01 | U64 plus raw F64 representation, literals, containers, and ABI. Full-width round trips work without Nat truncation, tag collision, or NaN payload loss. |
| N02 | Portable software core: wide integer helpers, basic binary64 operations, FMA, conversions, rounding and flags. Independent differential suite passes. |
| N03 | C/CPU and JavaScript integration, constant handling, text/binary I/O. Compiled Bend results match the pinned contract. |
| N04 | Metal integration through the real Bend GPU route. Required-device conformance passes; no F32 emulation or CPU substitution. |
| N05 | CUDA integration and cross-backend conformance, including explicit FMA and subnormal behavior. |
| N06 | CAD numeric library: qualified trigonometry, inverse trigonometry, `atan2`, `hypot`, exponential/logarithmic functions and powers, stable linear algebra, outward-rounded intervals. |
| N07 | Performance work, compiler regression controls, packaging, documentation, and reviewable upstream contributions. No optimization weakens semantics. |

N02 and backend harness work can overlap after N00/N01. The immediate first release is qualified numeric infrastructure, not a CAD demo. Archive qualification and oracle design can proceed in parallel; numerical CAD implementation starts after the relevant numeric gates, including genuine Metal execution, pass.

Transcendentals are a separate work package, not silently included in “SoftFloat works.” Use algorithms with documented argument reduction, domain behavior, and error bounds. Correct rounding is required where claimed; otherwise publish a proven or measured bound with its status and domain. Large-angle trigonometry must not narrow through F32.

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

For the admitted manifold-solid profile, validate local incidence and vertex links, orientation, closed boundaries, trimming consistency, and geometric embedding. Counting faces or checking Euler's formula alone is not solid validation. Open surfaces remain valid under a different explicitly named profile.

Exit: valid sphere/cylinder seams and cavities are accepted; dangling, inverted, self-intersecting, and nonmanifold counterexamples are diagnosed appropriately.

### C05 — Planar arrangements and sketch solving

Construct planar regions with intersections, nested loops, holes, disconnected islands, and deterministic boundary identity. Develop a Bend-native constraint solver with residual/Jacobian evaluation, stable factorization, rank diagnosis, bounded iteration, and explicit degrees of freedom, conflicts, redundancy, and nonconvergence.

Start with coincidence, horizontal/vertical, distance, radius, angle, parallel/perpendicular, and tangency, then extend curve constraints. The solver must not declare a system inconsistent merely because an iteration budget expires. PlaneGCS is a test comparator, not the shipping solver.

### C06 — First complete solid-building path

Implement primitives, extrusion, revolution, pad/pocket semantics, holes, and transformations using the preceding geometry and topology. Handle multiple profile regions, axis crossings, and degenerate input explicitly.

Exit: a parameterized mechanical bracket with a curved boundary and holes is authored through the CLI, validated, measured, serialized, reopened, edited, and tessellated without any existing CAD kernel at runtime. This is the first end-to-end foundation, not the professional-completion ceiling.

### C07 — General intersections

Implement curve/curve, curve/surface, and surface/surface intersection with broad-phase bounds, subdivision/root isolation, refinement, endpoint classification, and complete admitted-domain coverage. Include tangency, coincidence, overlapping intervals, seams, and singularities. Newton iteration can refine an isolated candidate; it cannot by itself establish that all intersections were found.

Exit: return intersection curves and topology/parameter correspondence, not only sampled points. Unresolved regions remain explicit uncertainty.

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

Exit: queries agree with analytic/high-precision fixtures and report incomplete or approximate status honestly. Minimum-wall claims require a separately qualified method, not a few successful ray samples.

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

## 13. The first execution packet

**N00/N01: establish the numeric contract and prove full-width representation before arithmetic optimization.**

After the fork is identified, pin it and record baseline checks. Add the U64/F64 surface with explicit literals and bit conversion, implement the native/JS representation changes, and test full-width values through all generic storage and execution paths.

The acceptance set must distinguish `1 + 2^-52` from 1, preserve the smallest binary64 subnormal, round halfway values correctly, transport `0xffffffffffffffff` without confusing it with a runtime sentinel, preserve negative zero and supplied NaN payload bits, reject overflowing U64 literals, and expose the actual execution backend. Scalar arithmetic acceptance belongs to N02/N03; real Metal arithmetic acceptance belongs to N04.

The next packet is the qualified software arithmetic core, not an OCCT bridge, a viewer redesign, or a box demo.

**Dependency order:** immutable recovery and baseline → full-width representation → specified software binary64 → compiled CPU/JS and actual Metal qualification → CUDA and CAD math → robust predicates and B-rep foundations → intersections/booleans/features → interchange and professional qualification.

## Primary references

[1] Bend inspected compiler/runtime: https://github.com/bendlang/bend/blob/0b7e2b11c1054f5d0f4eb955cadb47997ef1115d/bend2/comp.ts ; language/base files and guide in the same pinned tree.

[2] Berkeley SoftFloat interface and arithmetic semantics: https://www.jhauser.us/arithmetic/SoftFloat-3/doc/SoftFloat.html

[3] Metal software-binary64 prior art and author-reported qualification limits: https://github.com/guyfischman/metal-softfloat/blob/main/docs/ieee754_conformance.md ; pin the implementation commit before adoption.

[4] Berkeley TestFloat: https://www.jhauser.us/arithmetic/TestFloat.html

[5] MPFR manual and binary64 emulation considerations: https://www.mpfr.org/mpfr-4.2.2/mpfr.html

[6] Shewchuk, adaptive-precision geometric predicates: https://www.cs.cmu.edu/~quake/robust.html

These references motivate the design. No cited external test result is presented as a BendCAD test run.
