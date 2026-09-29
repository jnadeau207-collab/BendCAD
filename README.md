# BendCAD

Aethalgard v2: an open-source, agent-native professional CAD system written in Bend 2. The Bend kernel, with a design model, an engineering layer, an agent interface and a viewer, is built so that an AI agent can design buildable products, not just shapes (MASTER_PLAN §14–§17).

**Status:** C00–C05 closed with laws, three-lane tests and independent oracles:

- contracts;
- math foundation;
- exact predicates;
- curves and surfaces;
- B-rep topology;
- planar arrangements and the sketch solver.

The receipt is `docs/receipts/c05.1-2026-09-29.txt` at `48ab78c`. Next: C06 solids with A0, the agent protocol, graded by challenge G1. New code is Apache-2.0. The LICENSE file ships with release packaging; `legacy/` is reference-only and never released.

## Pins

- Bend language: [`BEND_PIN`](BEND_PIN) — `jnadeau207-collab/bend@bc01485d64a4454c08d74e343f9f1964859986c3` (tag `numeric/2026-09-29`)
- Numeric contract lives in that fork: `bend2/docs/F64_CONTRACT.md`, `bend2/docs/F64_IMPLEMENTATION.md`
- Advance `BEND_PIN` only after a Bend numeric gate. Never track floating `main`.

## Start here

- [AGENTS.md](AGENTS.md): coding mandate and hard lines
- [MASTER_PLAN.md](MASTER_PLAN.md): the kernel roadmap (C00–C16), the agent-native architecture and tracks (§14–§15), and the challenge ladder (§16)
- [legacy/aethalgard/](legacy/aethalgard/): immutable reference corpus
- [legacy/PROVENANCE.md](legacy/PROVENANCE.md), [legacy/manifest.json](legacy/manifest.json)

Recovered core: 249 files, 4,161,578 bytes, from `jnadeau207-collab/reepo@eeca9ad782640f97bc15423e72319acea310d36f`. Not a desktop restore.

```sh
python3 tools/verify_legacy.py
```

Hash verification is not a build, test, or qualification result.

## Boundaries

Production Aethalgard is untouched. Scalar/compiler/F64 work is in the Bend fork. Geometry and topology live here and must be written in Bend. OCCT/FreeCAD/PlaneGCS are oracles only. Mesh/voxel is not a B-rep substitute.
