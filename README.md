# BendCAD

Aethalgard v2: an open-source professional CAD kernel in Bend 2, built to be the world's best kernel for AI agents. It is never silently wrong and explains its failures. Identity is by meaning. Toleranced, state-dependent geometry is native. Sensitivities come with every answer. It is fast and massively parallel by law (MASTER_PLAN §14–§15).

**Status:** C00–C07 closed. C00–C05 have laws, three-lane tests and independent oracles:

- contracts;
- math foundation;
- exact predicates;
- curves and surfaces;
- B-rep topology;
- planar arrangements and the sketch solver.

R0, the speed and parallelism rebuild, is closed: C05 rebuilt (R0.1), C04 validation on a store index and C02 exact for all finite doubles (R0.2), the solver started at its damping floor (R0.3), and the audit repairs (R0.4). Its residuals are owned by later milestones (MASTER_PLAN A5).

C06 + A0 is closed (`docs/receipts/c06.1-2026-10-05.txt`). It covers:

- primitives, extrusion of multi-region profiles with arcs, pad, pocket, holes, placement and revolution;
- an intent check on every op, measured from the result;
- certified volume and area intervals, also over tolerance zones for primitives;
- the design model with memoized rebuild;
- sensitivities and watertight tessellation;
- the `bendcad` CLI and MCP server (`tools/mcp/`).

Challenge G1 passed: fresh agents built and edited a parameterized bracket through MCP, and an independent grader passed every run (`docs/receipts/g1/`).

C07 is closed (`docs/receipts/c07-2026-10-06.txt`). It adds:

- certified curve/curve, curve/surface and surface/surface intersection, with every unresolved region reported;
- point classification (`classify`);
- an embedding, orientation and cavity check for any solid (`check`);
- tolerance-envelope measures for every operation, once the topology is certified constant over the zone.

Next is C08. New code is Apache-2.0. The LICENSE file ships with release packaging; `legacy/` is reference-only and never released.

## Pins

- Bend language: [`BEND_PIN`](BEND_PIN) — `jnadeau207-collab/bend@a4d17acecf79c71696610f0683d8d003bc392920` (tag `numeric/2026-10-05`, branch `numeric-on-upstream`; `numeric/2026-09-29` is the earlier pin `bc01485d`)
- Numeric contract lives in that fork: `bend2/docs/F64_CONTRACT.md`, `bend2/docs/F64_IMPLEMENTATION.md`
- Advance `BEND_PIN` only after a Bend numeric gate. Never track floating `main`.

## Start here

- [AGENTS.md](AGENTS.md): coding mandate and hard lines
- [MASTER_PLAN.md](MASTER_PLAN.md): the kernel roadmap (C00–C16), the agent kernel's properties (§14), speed and parallelism law (§15), interface and scope (§16), milestone order (§17), and the challenge ladder (§18)
- [tools/mcp/language.md](tools/mcp/language.md): the design language agents use through the MCP server (`tools/mcp/bendcad-mcp.mjs`) or the `bendcad` CLI (`src/c06/cli.bend`)
- [docs/c06-contract.md](docs/c06-contract.md): what C06 builds, measures and refuses
- [docs/c07-contract.md](docs/c07-contract.md): intersections, classification, embedding and envelope topology
- [legacy/aethalgard/](legacy/aethalgard/): immutable reference corpus
- [legacy/PROVENANCE.md](legacy/PROVENANCE.md), [legacy/manifest.json](legacy/manifest.json)

Recovered core: 249 files, 4,161,578 bytes, from `jnadeau207-collab/reepo@eeca9ad782640f97bc15423e72319acea310d36f`. Not a desktop restore.

```sh
python3 tools/verify_legacy.py
```

Hash verification is not a build, test, or qualification result.

## Boundaries

Production Aethalgard is untouched. Scalar/compiler/F64 work is in the Bend fork. Geometry and topology live here and must be written in Bend. OCCT/FreeCAD/PlaneGCS are oracles only. Mesh/voxel is not a B-rep substitute.
