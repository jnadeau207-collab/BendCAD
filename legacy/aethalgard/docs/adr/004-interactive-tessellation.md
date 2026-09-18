# ADR-004: Interactive tessellation policy

- Status: Accepted
- Date: 2026-07-12
- Owners: geometry runtime and viewport

## Context

Tessellation is a presentation artifact, not document authority. Its quality knobs must be explicit
so a runtime upgrade cannot silently change visual fidelity, memory, or selection ownership.

## Decision

`BRepMesh_IncrementalMesh` uses parallel meshing and bbox-relative linear deflection. LOD 0 is the
NG-1 interactive contract: `max(bodyDiagonal × 1e-3, 0.001 mm)` with angular deflection `0.5 rad`.
LOD 1 uses `2.5e-4` and `0.25 rad`; LOD 2 uses `6.25e-5` and `0.1 rad`, retaining the 1 µm floor.
Export-quality meshing remains an NG-3 decision.

Every AEMB descriptor records both deflections, counts, bounds, epoch, byte length, and CRC-32.
Triangles are grouped per OCCT face and carry one dense face owner each. Reversed faces reverse
winding and normals together.

## Consequences

- Visual regression tests can distinguish geometry changes from policy changes.
- AEMB packets are disposable and may be regenerated at another LOD.
- Manufacturing export never treats viewport triangles as B-rep authority.
