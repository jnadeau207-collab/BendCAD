# BendCAD

An independent professional CAD-kernel project for Bend 2.

**Status:** the pre-VibeCAD Aethalgard reference corpus is recovered and hash-verified. Bend F64 and the Bend-native CAD kernel are planned, not implemented or qualified yet.

## Start here

- [Master plan](MASTER_PLAN.md): true binary64 on Metal, compiler/runtime qualification, then the independent Bend geometry and topology kernel.
- [Recovered Aethalgard source](legacy/aethalgard/): immutable source, tests, fixtures, contracts, native build tooling, and historical architecture documents.
- [Recovery provenance](legacy/PROVENANCE.md) and [hash manifest](legacy/manifest.json).

The selected core is 249 files, 4,161,578 bytes, from `jnadeau207-collab/reepo@eeca9ad782640f97bc15423e72319acea310d36f`. Additional recovered architecture/build metadata are also retained. This is the CAD/kernel reference corpus, not a complete restoration of the former desktop application or its full Git history.

Verify the recovered source without network access:

```sh
python3 tools/verify_legacy.py
```

Source verification is not a native build or test result. A dedicated oracle harness must qualify the recovered OCCT-backed implementation separately.

## Project boundaries

Production Aethalgard remains unchanged and separate. Generic U64/F64 work belongs in the user's Bend fork. BendCAD's new geometry and topology algorithms belong here and must be implemented in Bend; existing CAD kernels may serve as separately identified development oracles, not hidden runtime substitutes.

Original source notices and third-party provenance are retained. No new blanket license is applied to the recovered material.
