# ADR-015: Kernel-robustness doctrine — six standing rules for OCCT work

Date: 2026-07-27
Status: accepted (founder SOTA directive 2026-07-27; GOV-003)

## Context

The founder's standing directive is that the bar is world-class CAD on
everything, and the kernel is where CAD systems live or die. We build on OCCT:
the best open kernel, and not Parasolid-class in robustness. Its weak corners —
booleans on marginal geometry, tolerance stacking, local operations — are
exactly where direct editing lands.

Thirteen capabilities have now shipped against it, and the practices that kept
them honest were adopted case by case: feasibility probes, fail-closed refusals,
measured bounds, fixture-pinned history. They work. They are also **habit, not
law** — nothing in the control plane requires the next packet to use them, and
two of them were adopted only after a near-miss.

This ADR makes them law. The detail, and the incident behind each rule, is in
`docs/design/2026-07-27-kernel-robustness-doctrine.md`.

## Decision

Six rules bind every kernel-touching packet:

1. **Fixture corpus.** Tracked and growing; every kernel-touching capability
   adds its cases; fixtures are superseded with a reason, never deleted.
2. **Per-operation tolerance budgets.** Declared input envelope and output
   guarantee, asserted in gates. Tolerance inflation to make something work is
   refused — budget it or refuse the operation.
3. **Differential fuzzing**, scheduled rather than per-commit: valid geometry or
   a typed refusal, never a crash, an invalid shape, or a hang past the
   watchdog. Failures minimize into permanent fixtures.
4. **History verification before naming.** Pin `Modified` / `Generated` /
   identity-survivor behaviour per operation against the pinned OCCT, in fixture
   translation units, BEFORE any name is minted.
5. **Kernel upgrade protocol.** A version bump replays the whole corpus, the
   history fixtures and the goldens; drift is a recorded decision.
6. **Refusal quality is a product surface.** Every refusal names what failed and
   the measured bound where one exists.

Two sub-rules of §4 are promoted here because they are properties of OCCT
history in general, not of the operations that found them:

- **Identity survival is a first-class attribution route.** History reports what
  an algorithm CHANGED; untouched entities pass through by identity and history
  says nothing about them. A check accepting only `Modified`/`Generated`
  manufactures false orphans. (Found in CAP-013, again in CAP-034; also
  ADR-014 §4.)
- **A role the history cannot distinguish must not be invented.** A role is what
  `role(...)` selectors resolve against, so a guessed role is a wrong answer to
  a user query. Corrections go in the spec, not the code. (CAP-012's
  `chamfer-corner`.)

## Consequences

- PROTOCOL gains an amendment: kernel-touching packets MUST cite corpus coverage
  and tolerance budget in their Verification section. That amendment cites this
  ADR.
- §2 is designed and landed: budgets are per-operation constants in absolute
  millimetres, stated over max-of-all-kinds, asserted by the
  `tolerance-budget` native gate. Measuring it corrected this ADR's own draft —
  tolerance turned out to be scale-invariant and parameter-independent, and the
  inflated entity kind MIGRATES under composition. It also produced the finding
  that budgets do not compose by `max()`: chamfer-then-fillet reaches 1.0633e-4
  mm, above the kernel linear tolerance both members respect.
- §3's runner remains the packet's own named split candidate. **This ADR states
  the law; for §3 it does not claim the machinery exists.**
- The corpus is today entirely synthetic. Real-world STEP and known-nasty
  geometry are the missing half and the point of §1; until they land, §1 is
  aspiration backed by an intake rule rather than coverage.

## Alternatives rejected

- **Leave the practices as habit.** They survived thirteen capabilities on
  attention alone, and twice only barely: CAP-008 and CAP-010 both discovered
  mid-capability that the fixtures they needed did not exist. Habit does not
  survive a distracted week.
- **Per-commit fuzzing.** This machine already swaps when the native, desktop
  and Electron chains run in parallel. A fuzz lane competing with the standing
  matrix would make the matrix flaky — trading a real signal for a speculative
  one.
