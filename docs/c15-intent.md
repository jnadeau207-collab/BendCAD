# C15 intent — semantic PMI and GD&T

Tolerances must be data the kernel reasons about, not ink on a drawing.
C15 binds dimensions, geometric tolerances and datum reference frames to
durable face selectors, evaluates them through the single existing
evaluator path (nominal bodies plus certified interval envelopes plus
per-state similarity), and exports them as semantic STEP AP242 entities
that an independent reader interprets identically.

## What this packet is

One `pmi` CLI verb and one MCP `pmi` tool with four actions. `check`
validates a `(pmi ...)` set against a design node and evaluates every
tolerance. `stack` evaluates worst-case 1-D stack-ups over the envelope
and operating states. `toler` evaluates interference and clearance
across operating states with an estimated envelope. `step42` exports
the design with its PMI as STEP AP242. The PMI set is evaluated fresh
on every call, so design edits propagate through it; nothing is
persisted, and drawings are deferred (D-drawing).

## E1, and what evaluates what

E1 is named once in the plan and defined nowhere, so the contract
records the interpretation explicitly (C15-INT1): E1 is the existing
evaluator path — `M.ev_part` nominals, `I.*` outward-rounded interval
envelopes, per-state similarity scaling. No second evaluator exists.

Three evaluation depths, each labeled honestly:

- Certified: 1-D stack envelopes (interval sums, outward-rounded);
  flatness on analytic planes (actual error exactly 0); orientation
  conformance/violation when the certified actual-interval sits wholly
  inside or outside the tolerance.
- Estimated: per-state clearance upper bounds (inherited from C11
  sampling); orientation verdicts neither arm closes (`uncertain`);
  envelope interference/clearance (documented widening, never
  certified).
- Refused by name: every tolerance kind outside the declared profile,
  every modifier outside `rfs`, datums on flatness, anything but one
  datum on orientation, non-plane orientation faces, degenerate faces.

## The declared AP242 profile

Full AP242 is a conformance-class ladder this packet does not climb.
It exports a declared minimal semantic subset — datums with
establishment, limits-form size characteristics, flatness and
orientation tolerances with datum references — with entity templates
verified against the STEP Tools AIM EXPRESS library, and defers the
rest (D-ap242-full). The geometry section is byte-shared with the C12
writer, which the E2E differential proves rather than asserts.

## Evidence map

- Laws (`laws/c15/`, `docs/c15-laws.md`): 22 real laws in 6 families —
  selector validity, per-state counts, refusal closure and
  non-publishing, state gating and envelope rendering, emission base
  and failure propagation, parse gates. No accessor laws, no
  whole-body restatements.
- Pins (`tests/c15/pins.bend`): 154 fixed-input pairs — entry vectors,
  face-name rendering, resolution lines, three-valued orientation
  verdicts, stack envelopes to the bit (oracles from independent IEEE
  arithmetic), toler recomposition identity against C11 primitives,
  exact AP242 entity strings, refusal strings, dispatch.
- Journeys (`tests/c15/e2e.py`, `tests/c15/neg.py`): 13 positive
  journeys with hand-derived oracles (stack envelopes exact to the
  float, toler within one ulp of the `clearance` verb by construction,
  independent AP242 reader identity, geometry differential against
  `step`) and 29 refusal journeys, each asserting the design is
  byte-unchanged and `step42` writes no file on refusal.

## Evolution

D-ap242-full (further characteristics, presentation, assembly PMI,
schema validation), D-cert-env (certified envelope interference for
general geometry), D-drf-multi (datum-system simulation for
multi-datum frames), D-state-disp (non-uniform and per-node states),
D-drawing (drawings carrying PMI). The single-datum orientation path is
the extension point all five build on.
