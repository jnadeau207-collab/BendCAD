# C10 governing laws — manufacturing-grade tessellation

Status: binding on all C10 work, together with `docs/c10-intent.md`.
Where two laws appear to conflict, the earlier one wins. Changing a
law to make a failing implementation pass requires explicit owner
review (MASTER_PLAN §11).

Scope authority: MASTER_PLAN §10 C10. Method authority: A2, §14, §15,
AGENTS.md.

## Validity

- **L1 (stated bounds).** Every tessellation names its chord and
  angle quality and reports the sampled maxima against them. No mesh
  ships without stated bounds.
- **L2 (estimate first).** The triangle estimate precedes the build
  and the budget gate precedes the write. A refusal writes nothing.
- **L3 (sampled, not certified).** Quality measurements are labeled
  sampled, not certified, on every reply and in the MCP reference.
  Nothing in this packet claims certification.
- **L4 (profiles distinguishable).** Display and manufacturing are a
  printed field of every reply. Preset 3 is manufacturing; presets
  0–2 are display; overrides are explicit.
- **L5 (no borrowed kernel).** Sampling, estimation, triangulation,
  and measurement are Bend in this repo. No meshing library is a
  runtime.

## Geometry

- **L6 (valid indices).** Every triangle index is 1-based and names
  a written vertex.
- **L7 (watertight).** Every edge of a closed solid's mesh belongs
  to exactly two triangles. Shared edges share one sample list.
- **L8 (orientation).** The C06 orientation rule is preserved: faces
  emit oriented triangles under the same outward-normal fix. This
  packet changes sampling density, never winding.
- **L9 (estimate sound).** The estimate is greater than or equal to
  the emitted triangle count on every journey.
- **L10 (bounds hold on samples).** The sampled chord and angle
  maxima are within the requested quality on every journey.

## Evidence

- **L11 (journeys).** Prism, lathe, cavity, slanted-profile,
  arc-profile, preset, override, refusal, and replay journeys each
  pin exact counts, watertightness, the Euler characteristic, the
  estimate inequality, and the bounds. Missing any one of those, the
  journey is not closed.
- **L12 (diagnoses are stable).** The why-strings in the intent are
  the strings the kernel returns. Tests assert them verbatim, with
  the fix present and no file written.
- **L13 (C06 amended).** `docs/c06-contract.md` §10 points at this
  packet. The display tessellator is replaced; its triangulation
  core is preserved, not forked.
