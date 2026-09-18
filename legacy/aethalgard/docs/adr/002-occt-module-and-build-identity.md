# ADR-002: OCCT module set and build identity

- Status: Accepted
- Date: 2026-07-12
- Owners: native build

## Context

The kernel must be reproducible, crash-isolated, and legally redistributable. A floating OCCT tag,
implicit system package, or developer-machine shared library would make geometry behavior and crash
reports non-identifiable.

## Decision

Build shared OCCT `V8_0_0_p1` at commit
`4f95ecaa3b690e34988d42e2ca7fe882e7a8bc7d`. The canonical inputs live in
`native/third_party/occt.manifest.json`; its SHA-256 is compiled into the kernel health response.
The requested roots are TKPrim, TKMesh, TKDESTEP, and TKShHealing. CMake resolves the necessary
foundation, modeling, TKBO, application-framework, and STEP transitive closure. Draw, tests,
documentation, and optional GUI/graphics dependencies are disabled.

CMake 4.1.0, Ninja 1.13.0, and clang-format 22.1.8 are workspace-local pinned tools. Runtime
libraries and OCCT resources are materialized beside the host; Linux uses `$ORIGIN/../lib`, macOS
uses `@loader_path/../lib`, and Windows places DLLs beside the executable.

## Consequences

- A health report identifies the exact source and manifest, compiler, build type, and protocol.
- Native caches are keyed by the manifest hash and never committed.
- LGPL dynamic-linking notices and source publication remain a packaging-tranche obligation.
