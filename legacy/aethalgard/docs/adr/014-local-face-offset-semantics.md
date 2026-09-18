# ADR-014: `offset` means local face offset — semantics, pipeline, and naming

Date: 2026-07-27
Status: accepted (founder ruling 2026-07-27; gates the plan-04 `### offset`
section and the CAP-034 role table)

## Context

`offset` shipped as a WHOLE-BODY uniform operation and has never been
reachable: it has no verb, and it refuses any element-naming pass, so it is the
one remaining untabled modifier (`UntabledModifiersFailClosed`,
`native/kernel-host/test/naming_registry_test.cpp`).

CAP-012 was scoped to give it a face ref slot alongside chamfer. That split
under PROTOCOL §3 on a measurement: the exit criterion's face push/pull is a
**different kernel operation** from the one `EvaluateOffset` implements, and —
decisively — **the normative plan has no `### offset` section at all**. The
headings run fillet, chamfer, shell, boolean, mirror, patterns, transform,
align, import-mesh, lattice. There was nothing to conform to, so what `offset`
MEANS was escalated as a product ruling rather than guessed at.

The founder ruled on 2026-07-27. This ADR records that ruling, the pipeline the
CAP-034 spikes measured to satisfy it, and the naming consequences — so the
plan-04 section it authorises is a transcription of measurements rather than an
invention.

## Decision

### 1. Semantics

`offset` means **LOCAL FACE OFFSET**: a topological re-trim and stitching
cycle. Shift the target face's underlying surface, recompute its intersections
with the adjacent surfaces, and reconstruct the boundary graph. Faces and
vertices are never moved in isolation, and trims are never translated.

Whole-body `offset` v1 is superseded as the operation's FUTURE but not removed:
an absent face slot keeps evaluating bit-for-bit, the same
absent-slot-is-v1 invariant chamfer established in CAP-012.

### 2. Pipeline (planar targets), as measured

Three OCCT primitives compose to the exact ruled result. Each is already
verified and history-carrying:

1. sweep the target face along its own outward normal by the distance →
   `BRepPrimAPI_MakePrism`;
2. **fuse** that prism (outward) or **cut** it (inward) →
   `BRepAlgoAPI_Fuse` / `BRepAlgoAPI_Cut`;
3. **`ShapeUpgrade_UnifySameDomain`** to reconstruct the boundary graph.

This is the ruled operation, not an approximation of it, because the prism's
side walls lie EXACTLY in the neighbour planes: the boolean therefore re-trims
those neighbours against the moved surface, and they keep their original
surfaces. Step 3 is the ruling's third clause.

Measured on the 90×64×36 box, pinned by `LocalFaceOffsetHistoryFixtures`:

| case       |               volume | faces | valid | attribution |
| ---------- | -------------------: | ----: | ----- | ----------- |
| +5 outward | 236,160 (= 90×64×41) |     6 | YES   | complete    |
| −5 inward  | 178,560 (= 90×64×31) |     6 | YES   | complete    |

Without step 3 the outward case leaves **10** faces — each neighbour split into
original plus extension, same plane, redundant seam. Six is the acceptance
number because it is what "re-trimmed, not split" means.

### 3. Unify is permitted HERE, and only because it carries history

`boolean_combine` deliberately runs **no** unify/simplify stage: unify there
would have to discard the per-entity attribution the naming substrate depends
on. That convention stands.

This path earns a narrow exception on a measurement:
`ShapeUpgrade_UnifySameDomain` exposes its own `BRepTools_History` — the same
type `HarvestOperation` already consumes — so the step **composes** rather than
erases. Measured: zero unattributable faces in either direction.

### 4. Attribution includes identity survival

An entity untouched by a stage passes through by IDENTITY, and history reports
nothing about it. Any attribution check must accept that route as well as
`Modified`/`Generated`, or it manufactures false orphans: the inward case's six
faces are ALL identity survivors, because the cut splits nothing and unify has
nothing to merge.

This is the second time this has surfaced (CAP-013's ByJoin harvest was the
first), so it is recorded here as a general rule rather than a per-operation
note. The eventual offset role table must treat identity survival as a
first-class route, not a special case.

## Consequences

- plan-04 gains a `### offset` section transcribing §1-§2 above, with the role
  table built on §3-§4. That section is the authority the CAP-034 role table
  conforms to; **no offset names may be minted before it lands**, and
  `UntabledModifiersFailClosed` keeps pinning `offset` until they do.
- Scope: the packet budgeted a bespoke surface-intersect/sew core as a large
  native tranche. For PLANAR targets it is not needed. Curved targets and the
  five enumerated hard cases (blend adjacency, neighbour consumption, tangent
  chains, self-intersecting offsets, imported bodies) are untouched by this
  composition and remain the substantial work — a §3 split along
  planar-then-curved is the expected shape.
- `BRepFeat_MakePrism`-style push/pull stays out of scope: it is absent from the
  pinned OCCT install, and the ruling is face offset, not push/pull.

## Alternatives rejected

- **`BRepOffset_MakeOffset::SetOffsetOnFace`.** Measured: a zero global offset
  is rejected outright (`Error() == 4`), and the per-face call varies an offset
  across a skin already being offset everywhere. Offsetting one face of a box
  with it moves all six — a 26-face rounded-skin body at 335,846.16 mm³. That is
  a different operation with a plausible-looking result, which is exactly the
  failure class the ruling excludes.
- **Adding a face ref slot to the whole-body evaluator.** Ships a decorative
  reference: the geometry would ignore it. Refused for the same reason.
