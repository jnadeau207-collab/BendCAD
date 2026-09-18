# ADR-012: Schema-version policy — physical refusal, document ladder, op envelope

Date: 2026-07-19
Status: accepted (founder decision, 2026-07-19)

## Context

Gate 9 (MASTER_PLAN §5: _unknown ops degrade visibly, never discard the graph_) landed in
two slices for the operation vocabulary (`docs/design/2026-07-17-gate9-forward-compat.md`):
unknown operations persist byte-for-byte, the document opens read-only, and the viewport
degrades visibly. That note explicitly deferred the remaining forward-compat questions —
what happens when `documentSchemaVersion` or the container's `aethSchemaVersion` moves,
and what happens to container entries an older build does not recognize.

Before this decision the answers were accidental:

- `readAethFile` accepted `documentSchemaVersion` 1|2 through an ad-hoc union in
  `aethManifestSchema` plus an inline check, with the v1→v2 conversion hidden inside
  `@aeth/document-model`'s `documentStateSchema` transform — no ordered ladder, no record
  of what was applied, nothing forcing a future v2→v3 step to exist when the version bumps.
- `writeAethFile` built the archive from exactly `manifest.json` + `document.json`, so the
  reserved entries a newer build may add (`thumbnails/`, `checkpoints/`, `assets/`) were
  silently DROPPED when an older build re-saved — a "never discard" violation one layer
  below the op graph. `readAethFile` reported such entries by name only; their bytes were
  unrecoverable by the save path even in principle.

`.aeth` carries three independently-evolving vocabularies, and they need three different
compatibility disciplines, not one.

## Decision

Three tiers, each with its own policy (implemented in Gate 9 slice 3,
`docs/design/2026-07-19-gate9-migration-ladder.md`):

1. **`aethSchemaVersion` = physical container layout → refuse politely, never migrate.**
   A different physical layout means the bytes cannot be trusted to parse at all, so an
   unknown version refuses with the typed `AethVersionError` naming the found and supported
   versions, and the file on disk is untouched. The loose `manifestVersionProbeSchema`
   guarantees a newer writer can always be identified well enough to refuse politely.

2. **`documentSchemaVersion` = a migratable ladder.** `@aeth/project-file`
   `src/migrations.ts` owns an ordered registry of pure N→N+1 raw-JSON steps
   (`documentSchemaMigrations`), run by `readAethFile` BEFORE the document parse. Policy
   points, each fail-closed:
   - the supported window (`supportedDocumentSchemaVersions`) is contiguous from the
     earliest supported version to the current one; a NEWER document refuses with the typed
     `AethDocumentVersionError` (migration is strictly older-file-on-newer-build);
   - every rung validates its input against the strict from-version schema first —
     corruption is not migratable, and a rung must never mask a malformed field it happens
     to overwrite — and asserts its output declares the next version;
   - each applied rung produces a one-line record (`AppliedDocumentMigration`), surfaced
     through `AethFileContents.migrations` and the document service's recovery report;
   - migration happens IN MEMORY at open; the file is rewritten only by the next save,
     which always stamps the CURRENT version (the writer never persists a back-version);
   - compile-time drift guards (the `currentDocumentSchemaVersion` assignment and the
     mapped `Record<MigratableDocumentSchemaVersion, …>` registry) make bumping
     `@aeth/document-model`'s `documentSchemaVersion` without writing the corresponding
     ladder step a compile error. v1→v2 (the parameters table) is the first rung,
     formalizing what was previously implicit.

3. **Op vocabulary = the landed unknown-op envelope.** Unknown operation TYPES are not a
   schema-version matter: they persist byte-for-byte (`unknownOperationSchema`), open the
   document read-only (`DocumentForwardCompatError`), degrade visibly in the viewport, and
   round-trip on save. The ladder never rewrites operation payloads it does not understand
   (rungs operate on the raw JSON, and the strict gates keep unknown-op tolerance exactly
   as wide as `persistedOperationSchema` defines it).

**Corollary — unknown container entries are preserved, not dropped.**
`AethFileContents.additionalEntries` now carries `{ name, data }`; the document service
retains the bytes for the session and every save (`writeAethFile`'s `additionalEntries`
option) re-emits them byte-identically after the writer-owned entries, as STORED entries
(byte-identity is literal; a highly-compressible preserved entry can never trip the
decompression-ratio budget the reader enforces). Re-save refuses with the typed
`AethEntryCollisionError` only when a preserved entry collides with a writer-owned name
(`manifest.json`, `document.json`) or duplicates another preserved entry — ambiguity is
refused honestly, never resolved by overwrite. A committed fixture corpus
(`packages/project-file/test/fixtures/*.aeth`) pins v1 readability and the preservation
round-trip against real bytes.

## Consequences

- Opening old files is now an auditable, tested pipeline: version probe → polite refusal
  outside the window → recorded rungs → strict current-version parse. Callers (and, later,
  UI) can show exactly what a migration did; nothing migrates silently.
- Adding documentSchemaVersion 3 is a bounded, compile-enforced task: bump the constant in
  `@aeth/document-model`, append 3 to the supported window, register the 2→3 rung with its
  strict v2 input gate, add fixtures. Forgetting any of these fails the build or the ladder
  tests, not the user.
- An older build is now a safe citizen of a newer build's files twice over: unknown ops
  survive (slice 1) and unknown container entries survive (this slice). The only remaining
  hard refusals are honest ones: newer physical layout, newer document schema, corrupt
  content.
- The container size budgets still bound exactly what the writer emits; when reserved
  entries become first-class (thumbnails written by US), the budgets and the writer-owned
  name set must be extended deliberately (flagged in `container.ts`).
- `@aeth/document-model`'s internal v1 tolerance in `documentStateSchema` remains for
  direct parse callers; the container boundary migrates first, so that tolerance is now a
  redundant belt, not the mechanism of record.
