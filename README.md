# BendCAD

An independent professional CAD kernel for Bend 2.

**Status:** Aethalgard reference corpus recovered and hash-verified. Bend F64 implemented and receipted at `BEND_PIN`; the Bend-native kernel is planned, not implemented.

## Pins

- Bend language: [`BEND_PIN`](BEND_PIN) — `jnadeau207-collab/bend@50ec219a6b5c52316f4d1622816cceedd437fa95` (tag `numeric/2026-09-25`)
- Numeric contract lives in that fork: `bend2/docs/F64_CONTRACT.md`, `bend2/docs/F64_IMPLEMENTATION.md`
- Advance `BEND_PIN` only after a Bend numeric gate. Never track floating `main`.

## Start here

- [AGENTS.md](AGENTS.md): coding mandate and hard lines
- [MASTER_PLAN.md](MASTER_PLAN.md): CAD kernel after the Bend handoff
- [legacy/aethalgard/](legacy/aethalgard/): immutable reference corpus
- [legacy/PROVENANCE.md](legacy/PROVENANCE.md), [legacy/manifest.json](legacy/manifest.json)

Recovered core: 249 files, 4,161,578 bytes, from `jnadeau207-collab/reepo@eeca9ad782640f97bc15423e72319acea310d36f`. Not a desktop restore.

```sh
python3 tools/verify_legacy.py
```

Hash verification is not a build, test, or qualification result.

## Boundaries

Production Aethalgard is untouched. Scalar/compiler/F64 work is in the Bend fork. Geometry and topology live here and must be written in Bend. OCCT/FreeCAD/PlaneGCS are oracles only. Mesh/voxel is not a B-rep substitute.
