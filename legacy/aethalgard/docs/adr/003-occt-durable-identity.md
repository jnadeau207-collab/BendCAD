# ADR-003: OCCT durable identity doctrine

- Status: Accepted
- Date: 2026-07-12
- Owners: document model and geometry runtime

## Context

OCCT 8 distinguishes durable BRepGraph identity from process-local traversal identifiers. Persisting
or transmitting a session-local integer would silently bind future edits to unrelated topology after
re-evaluation or process recovery.

## Decision

Only `UID`, `RefUID`, and `ItemUID` may become durable BRepGraph identities. `NodeId`, `RefId`,
`RepId`, AEMB face indices, edge indices, and vertex indices are epoch-local. They must never enter
the operation graph, journal, `.aeth` container, or cross a kernel process epoch.

NG-1 therefore labels mesh ownership with dense face indices plus an explicit process/evaluation
epoch. Durable selector resolution remains fail-closed and enters in NG-2.

## Consequences

- Renderer selection tokens are discarded whenever the supervisor epoch changes.
- A later persistent-reference implementation cannot reinterpret NG-1 indices as stable IDs.
- Ambiguous or missing durable resolution is an explicit error, never an auto-commit.
