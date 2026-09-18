# Aethalgard recovery provenance

Recovered for BendCAD on September 18, 2026.

## Exact source

- Repository: `jnadeau207-collab/reepo`
- Selected pre-VibeCAD tip: `eeca9ad782640f97bc15423e72319acea310d36f`
- Original root tree: `6054dcc30c440bae1aa584c0bae871301e930a4d`
- Destination: `legacy/aethalgard/`
- Selected core: 249 files, 4,161,578 bytes.

The source repository is private. Recovery used the connected account's authorized read access. Temporary download links were encrypted for the receiver; plaintext access credentials were not committed. Recovered blobs were checked against their original Git object IDs. All temporary receiver workflows and transfer packets have been removed from the current tree; ordinary Git history is preserved.

## Recovery scope

The core preserves the complete `native/kernel-host`, `packages/geometry-contracts`, and `packages/kernel-client` trees; geometry and golden fixtures; native build tooling; the OCCT manifest; and seven historical root architecture/build documents. Additional recovered ADRs, lockfile, and configuration are retained. Exact directory and file identities are recorded in `manifest.json`.

This is not a complete restoration of the former Electron desktop application or its full Git history. The original workspace scripts refer to omitted packages. The source archive is immutable reference material, not a ready-to-ship standalone build.

Two files left at a different snapshot by earlier recovery attempts, `native/kernel-host/CMakeLists.txt` and `native/kernel-host/src/geometry.cpp`, were aligned to the selected tip. The complete native kernel, geometry-contracts, and kernel-client directory hashes now equal their original source directory hashes.

## Other preserved references

- Local-worktree snapshot: `1eab12971dcb22c0b75f9d3714ba377d86ab36b5`
- Consolidated archive manifest: `213180dd5b2d0c805ae9610bf88be5cd82111b0f`

Those references are recorded for archaeology; they are not silently mixed into this selected source baseline.

## Verification boundary

`python3 tools/verify_legacy.py` verifies source identities and core file/byte counts. It does not build OCCT, execute the historical native tests, prove numerical correctness, or qualify BendCAD.

Keep original notices, vendored dependency provenance, and license distinctions. The historical implementation uses OCCT and PlaneGCS; it is an oracle/reference corpus, not a Bend-native kernel. Its old plans and completion statements are historical documents, not current BendCAD requirements or evidence.

Production Aethalgard was not modified for this recovery. New oracle adapters and compatibility changes belong outside this immutable directory.
