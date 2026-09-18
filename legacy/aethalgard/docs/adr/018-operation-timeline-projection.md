# ADR-018: One visible operation timeline is a projection of document truth

Date: 2026-07-29
Status: accepted (CAP-025; delivering-session ruling)

## Context

The v1 design text incorrectly said history was invisible and separately described an agent
timeline. The product now has an ordered, persisted operation graph, one
transaction-controlled undo/redo authority, and operations that may produce
zero, one, or many current bodies. Keeping this model invisible makes ordinary
parametric editing undiscoverable, while adding an independently mutable
feature tree would create a second authority for identity, order, and history.

## Decision

Aethalgard exposes one visible **operation timeline**. It is a strict renderer
projection of `DocumentStateSnapshot.state.operations`, in array order.

- The timeline stores no operation copies and defines no persistence format.
- Row identity is the operation id.
- Each row's selectable body set is `outputBodyIdsOf(operation)` intersected
  with bodies in the current delivered evaluation.
- Activating a row replaces shell-owned selection with that complete current
  set. Zero-output and no-longer-current rows remain visible but select nothing.
- Numeric editing is offered only for the existing `EditableOperation` union
  and commits through `buildDimensionMutation` plus the normal document
  transaction. Non-editable rows are explicitly read-only.
- Undo and redo remain the only history-mutation controls. The timeline does
  not suppress, reorder, replace, rewind, or branch operations.
- The assistant does not receive a second history. Assistant-authored
  operations appear in the same document projection as direct edits.

The presentation is a compact ordered toolpath: a continuous rule and numbered
nodes expose sequence at a glance, while row labels and status text carry all
meaning without color.

## Consequences

The old prohibition on a visible history panel is superseded. The prohibition
on a competing feature graph remains.

Operation selection can highlight an entire CAP-024 birth set without choosing
an arbitrary body. A construction-profile row can be editable while honestly
having no selectable body. Re-evaluation, undo, redo, reopen, and document
replacement refresh row values from the authoritative snapshot rather than
attempting to synchronize a timeline store.

Suppression, reorder, rollback-to-row, checkpoints, and reverse body-to-row
focus require separate contracts and are not implied by this ADR.

## Supersedes / relates

- Supersedes the invisibility sentence in
  `docs/plan/02-design-system/00-overview.md` invariant 5.
- Supersedes the “No feature tree / history panel” sentence in
  `docs/plan/02-design-system/05-editor-layout.md`.
- Preserves `docs/plan/02-design-system/07-agent-experience.md` rule 10: one
  undo stack and no separate AI history.
- Consumes ADR-013's zero/one/many output contract.
