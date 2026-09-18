# World-class topology audit — 2026-07-31

## Verdict

Topology is one of the defining systems of professional CAD. Exact B-rep
geometry is necessary, but it is not sufficient: the product must continue to
mean the same face, edge, vertex, body, datum, and component occurrence after
parameters change, features are inserted, a definition is reused, a document
is reopened, or the kernel process restarts.

Aethalgard's core topology architecture is strong and safety-oriented. It is
not qualified as "world's best" merely because this document exists. That claim
requires the exact-tip gates and mutation corpus below to pass. The cardinal
rule remains **zero silent misreferences**: missing and ambiguous are acceptable
and attributable; silently acting on a different entity is not.

## Architectural truth

The topology stack has five distinct identities. They must never collapse into
one another:

1. **Exact OCCT B-rep identity** — live `TopoDS_Shape` identity during one
   replay state.
2. **History-derived naming identity** — deterministic lineage names and live
   presentation tokens harvested from OCCT operation history.
3. **Durable semantic identity** — parsed AQL plus an `OperationRef` anchor.
4. **Assembly scope** — a definition-local selector paired with a durable
   occurrence UUID.
5. **Presentation identity** — epoch-local face/edge/vertex rows, GPU pick keys,
   and renderer presentation UUIDs.

Only layer 3 and the occurrence UUID from layer 4 may enter persistent feature,
mate, joint, measurement, or agent transactions. Layer 5 is evidence used to
record layer 3; it is never durable CAD state.

## Existing strengths confirmed

- Naming is built from operation history, not geometric nearest-neighbor
  guessing.
- Maps and role tables are deterministically ordered.
- One-to-one modifications preserve alias chains.
- Splits and genuine twin collisions refuse rather than silently selecting a
  child.
- Multi-output birth tokens encode the output index.
- Query evaluation is exact-B-rep and canonically ordered.
- The resolver requires independent history and signature channels to agree.
- Replayed selection recording verifies the complete AEMB topology packet and
  operation provenance before minting a durable reference.
- Assembly endpoints already use the correct model: `{ occurrenceId,
selector }`; the selector remains definition-local.

## Defects repaired in this audit

### Assembly definition replay

Assembly presentation UUIDs are now mapped back to exactly one retained
occurrence, definition revision, and definition body. Selection recording
replays the exact retained lowered operation program and accepts it only when
operation provenance and every AEMB topology section reproduce the displayed
definition body. Persisted references stay definition-local; returned
measurement evidence is transformed into occurrence-world coordinates.

### Multi-output token identity

The selection recorder no longer hand-parses
`t:<operationId>:<outputIndex>/<role>/<ordinal>` as though `:<outputIndex>` were
part of the operation UUID. A nonzero output body is recorded through an exact
token-source query only after the kernel proves that query returns the same
body and topology token.

### Analytic anchor evidence

`OperationRef` anchors may now retain analytic axis origin/direction and radius.
These fields are optional and backward-compatible. They are hints only; they do
not replace AQL or naming history.

### Exact incidence signature

Query entities now carry an optional `adjHash`: a deterministic FNV-1a hash of
sorted live naming tokens on immediate incident exact B-rep entities. It is
computed from faces/edges/vertices and OCCT incidence, never tessellation,
proximity, or dense entity rows. The recorder persists it in the anchor.

### Safety-monotonic native enrichment

The native resolver first runs the established resolver unchanged. Richer
axis/radius/incidence scoring is considered only if that resolver returned
`Ambiguous`. It may upgrade the result only when:

- lineage history uniquely names candidate X;
- the enriched signature independently names candidate X;
- the enriched score clears a minimum threshold and a strong runner-up margin.

A missing channel, tie, or disagreement remains `Ambiguous`.

### Durable/presentation boundary

Strict contract tests now reject `entityIndex`, `faceIndex`, `edgeIndex`,
`presentationBodyId`, `processEpoch`, and `evaluationEpoch` from persisted
`OperationRef` values.

## Exact-tip qualification required

Run on the qualified Windows machine from a clean checkout of the exact head:

```powershell
node --version
pnpm --version
pnpm install --lockfile-only
pnpm install --frozen-lockfile
pnpm check:static
pnpm typecheck
pnpm test
pnpm native:test
pnpm native:test:electron
pnpm pack
```

The authoritative all-in-one gate remains:

```powershell
pnpm check
```

The gate result must record the exact commit SHA. A green run from an earlier
commit does not qualify this topology tranche.

## Topology-specific evidence required from those gates

- Multi-output import: each born body records and re-resolves its own selected
  faces, edges, and vertices.
- Assembly reuse: two occurrences of one definition record the same
  definition-local selector but retain distinct occurrence scope and world
  evidence.
- Parameter edits: dimension, fillet, chamfer, shell, hole, pattern, boolean,
  and transform mutations either preserve the intended reference or return a
  typed missing/ambiguous refusal.
- Split/merge: no parent token silently chooses a child after a split; no merge
  invents provenance.
- Reopen and journal recovery: references re-resolve from persisted semantic
  state without renderer rows or hidden caches.
- Kernel restart: epoch-local picks are invalidated; persisted refs remain
  semantic and replayable.
- Adversarial twins: equal measure, equal radius, coaxial, mirrored, repeated,
  and imported symmetric entities never resolve from signature alone.

## Remaining boundaries — fail closed, do not overclaim

These are legitimate future topology surfaces, not permission to guess today:

- authored `sketch`, `tag`, and `world` selector sources;
- `bodies` and `regions` query heads;
- full datum-plane/axis/frame source reachability through the generic selector
  evaluator;
- broader qualified mutation corpora across every operation in the eventual
  professional feature catalog;
- STEP/XDE cross-document product-structure and external-definition update
  survival;
- exact per-occurrence subentity highlight rendering, which is presentation
  work and must not be confused with durable identity correctness.

Until each boundary lands, unsupported requests must remain explicit
`UNSUPPORTED_OPERATION`, missing, or ambiguous. They must never fall back to a
similar-looking entity.
