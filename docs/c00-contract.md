# C00 packet contract — typed inputs, budgets, statuses, atomic publication

Milestone C00 (MASTER_PLAN §10): typed geometry inputs, units, tolerances,
budgets, result statuses, deterministic operation identity, atomic candidate
publication. Exit: malformed input and deliberate cancellation cannot publish
partial or nonfinite geometry.

Implementation: `src/c00/types.bend` (data + total predicates),
`src/c00/eval.bend` (boundary, fuel threading, identity, publish).
Laws+proofs: `laws/c00.bend` (38 laws, all proven).
Tests: `tests/c00/check.bend` (support), `tests/c00/neg.bend` (16 checks),
`tests/c00/positive.bend` (13 checks).

## 1. Request envelope

`Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled}`:

| Field | Meaning |
|---|---|
| `op` | Typed operation: `K_len`, `K_isect`, or `K_unknown{tag}` |
| `unit` | Length unit tag (`U_mm/cm/m/in`); travels with the request |
| `p0..p3` | Four scalar slots. EVERY slot is boundary-validated even when the op ignores it |
| `rev` | Immutable input revision the request reads |
| `tol` | Tolerance policy (§4) |
| `budget` | Resource budget (§4) |
| `bytes` | Declared payload size, checked against the byte ceiling |
| `cancelled` | Cooperative cancellation sample, checked first |

## 2. Pipeline order (first match wins)

`run` (`src/c00/eval.bend`) routes in this total order:

1. `cancelled` → `Failed(cancelled)` — cancellation is honored before any
   content is inspected, so a cancelled malformed request reports
   `cancelled`, never `invalid-input`.
2. `bytes > max_bytes` → `Failed(resource-exhausted)`.
3. `fuel == 0` → `Incomplete(used=0)` — the boundary is starved; nothing
   inspected, nothing published.
4. Tolerance/param validation fails → `Failed(invalid-input)`.
5. `fuel == 1` → `Incomplete(used=1)` — the boundary was paid for and passed;
   no fuel remains for the op. A fuel-1 request with bad content still
   reports `invalid-input` (step 4 precedes): fuel shortage masks no verdict.
6. `K_unknown` → `Failed(unsupported-op)`.
7. Op-shape checks (`K_len`: `p0 < 0`; `K_isect`: `lo > hi`) fail →
   `Failed(invalid-input)`.
8. Normalized candidate nonfinite → `Failed(numerical-uncertainty)`.
9. `K_isect` disjoint → `Ok(S_empty)` with the model UNCHANGED.
10. Else `publish`: `Ok(S_value)` with model `rev+1, count+1`, folded checksum.

## 3. Status taxonomy

Exactly MASTER_PLAN §8's six failures, plus two non-failure outcomes:

| Outcome | Renders as | Model | Meaning |
|---|---|---|---|
| `Ok(S_value{v})` | `ok-value` | advanced | published witness `v` |
| `Ok(S_empty)` | `ok-empty` | UNCHANGED | proven-empty result; success, not failure |
| `Incomplete{used}` | `incomplete` | UNCHANGED | fuel exhausted before a verdict; resumable |
| `Failed(invalid)` | `invalid-input` | UNCHANGED | malformed request or params |
| `Failed(unsupported)` | `unsupported-op` | UNCHANGED | unknown op tag |
| `Failed(uncertain)` | `numerical-uncertainty` | UNCHANGED | normalization overflow |
| `Failed(nonconverged)` | `nonconvergence` | — | RESERVED: no C00 trigger; no iterative solver until C05 |
| `Failed(cancelled)` | `cancelled` | UNCHANGED | cooperative cancellation |
| `Failed(exhausted)` | `resource-exhausted` | UNCHANGED | byte ceiling crossed |

Every outcome arm carries the deterministic op id: failures are attributed
by construction (legacy `kernelErrorSchema` requires TIMEOUT attribution via
`operationId`; C00 attributes every outcome, `laws/c00.bend`
`failed_attributed`, `incomplete_attributed`, `empty_attributed`).

`Incomplete` is never trusted geometry: it carries no candidate and the
input model. There is no `@unsafe` in C00 sources (verified by grep).

## 4. Budgets

Tolerance policy `Tol{lin, ang, par, apx, imp}`: separate linear, angular,
parameter-space, approximation, and imported-data budgets. No universal
epsilon exists anywhere in C00. Each entry must be finite AND strictly
positive — `is_lt(0, x)` alone would admit `+Inf`, so the finiteness
conjunct is load-bearing (`tol_pos`, `src/c00/types.bend`). C00 validates
all five; later milestones consume their own field.

Resource budget `Budget{fuel, max_bytes}`: evaluator steps + byte ceiling.
C00 models no wall clock: time budgets belong to the supervisor
(legacy `kernelRequestDeadlineMs`, `kernel-protocol-core.ts:83-90`), not
the evaluator. Fuel cost model: boundary 1 + op 1 (see §2 steps 3–5).

## 5. Operation identity

`op_id` is FNV-1a/64 over content words: version (`0xC00`), op tag + extra
word (the pair separates `K_len` from `K_unknown{1}`), unit tag, the four
param bit-patterns, input revision, the five tolerance bit-patterns.
Excluded: fuel, byte ceiling/declared bytes, cancellation — execution, not
content (legacy `operation-hash.ts` `excludedKeys`); re-running with more
fuel yields the same id. Identity, not a cryptographic commitment.

## 6. Input boundary

Nonfinite rejection uses the fork classifier: `is_finite(x)` iff
`F64.class(x) < 2` (0 zero, 1 finite, 2 inf, 3 nan). NaN and ±Inf are
rejected in every param slot AND every tolerance entry before dispatch.
`-0.0` is a valid zero length (ordered equal to `+0.0`).

Unit normalization happens ONLY in `to_mm` (mm/cm/m = 1/10/1000,
inch = 25.4). Finite × finite can still overflow to +Inf, so the candidate
is re-validated after normalization; overflow fails as
`numerical-uncertainty`, never as trusted geometry.

## 7. Demo ops (scalar witnesses)

C00's ops exercise the pipeline; their geometric content is intentionally
scalar. Each witness is exactly specified, not a placeholder:

- `K_len`: `p0` must be a finite non-negative length in `unit`; the
  published witness is its mm value.
- `K_isect`: overlap of `[p0,p1]` and `[p2,p3]` in `unit`, normalized to mm.
  Touching intervals (`lo == hi`) overlap. The published witness is the
  overlap's lower bound; a disjoint pair is `S_empty` success. Full
  intersection curves arrive in C07.

## 8. Explicit general laws

Bend rejects open laws (`bend` fails a file containing any law without a
proving def), so `laws/c00.bend` proves every claim it states: 3 fully
general laws plus 35 arm instances. The unbounded claims are stated here
explicitly; each is grounded by the proven instances and adversarial tests
named beside it.

- L1 (cancellation atomicity): for every model `m` and request `r`,
  `run(m, cancel_req(r))` publishes nothing and returns `m`.
  Proven: `cancel_atomic`, `cancel_explicit`. Tested: `neg-cancelled`,
  `neg-cancel-beats-malformed`.
- L2 (failure atomicity): every `Failed`/`Incomplete` arm returns the input
  model and no candidate. Proven per arm: `fuel0_keeps_model`,
  `bytes_keeps_model`, `nan_keeps_model`, `unknown_keeps_model`,
  `overflow_keeps_model`. Tested: all 16 `neg-*` checks assert
  `model_equal(outcome, pre)`.
- L3 (nonfinite never publishes): no `Ok(S_value)` carries a nonfinite
  witness. Proven per path: boundary rejection (`nan_rejected`,
  `inftol_rejected`), candidate re-validation (`overflow_uncertain`),
  exact finite witnesses (`len_value_bits`, `isect_hit_value`, `unit_*`).
  Tested: `neg-nan-param`, `neg-inf-param`, `neg-ninf-unused-slot`,
  `neg-overflow-uncertain`, all `pos-*` bit pins.
- L4 (empty succeeds distinctly): disjoint intersection is `Ok(S_empty)`,
  never failure, and advances no revision. Proven: `empty_is_success`,
  `empty_keeps_model`, `empty_attributed`. Tested: `pos-isect-empty`,
  `pos-empty-attributed`, `pos-isect-touch` (boundary).
- L5 (fuel honesty): fuel 0/1 yields explicit `Incomplete` (or a learned
  `invalid-input`), never geometry and never a false verdict. Proven:
  `fuel0_incomplete`, `fuel1_incomplete`, `fuel1_reports_invalid`.
  Tested: `neg-fuel-zero`, `neg-fuel-one`, `neg-fuel-one-reports-invalid`.
- L6 (identity excludes execution): `op_id` is constant across fuel, byte,
  and cancellation changes. Proven generally: `opid_excludes_fuel`,
  `opid_excludes_cancel`, `opid_excludes_bytes`. Tested:
  `pos-opid-ignores-fuel`, `pos-opid-ignores-cancel`,
  `pos-opid-deterministic`, `pos-opid-content-sensitive`,
  `pos-opid-unit-sensitive`.
- L7 (attribution): every outcome carries its request's `op_id`. Proven:
  `failed_attributed`, `incomplete_attributed`, `empty_attributed`.
- L8 (single publication): a valid request advances the model exactly one
  revision with the specified witness. Proven: `len_advances_rev`,
  `len_advances_count`, `len_checksum`, `len_value_bits`, `isect_hit_*`.
  Tested: all `pos-len-*`, `pos-isect-overlap`.

## 9. Verification

Pins: F64 bit patterns from python `struct` (independent oracle); the
`op_id` golden `13445760837015884352` and publish checksum
`1099231252310917555` for the laws fixture are cross-checked by an
independent python FNV-1a implementation.

```sh
export PATH=$HOME/.bend/bin:$HOME/.bun/bin:$PATH; export BEND_NO_TELEMETRY=1
bend src/c00/types.bend --check-only   # All terms check.
bend src/c00/eval.bend --check-only    # All terms check.
bend laws/c00.bend --check-only        # All terms check (38 laws proven).
bend tests/c00/check.bend --check-only # All terms check.
bend tests/c00/neg.bend                # 16 PASS, selfcheck fails=0
bend tests/c00/positive.bend           # 13 PASS, selfcheck fails=0
grep -rn '@unsafe' src/c00 laws/c00.bend tests/c00  # no matches
```

## 10. Limitations (honest scope, not placeholders)

- No wall-clock enforcement: `Budget` is fuel + bytes; the supervisor owns
  time (mined: `kernel-protocol-core.ts:58-90`).
- `F_nonconverged` is taxonomy-complete but triggerless until C05's solver.
- `op_id` is FNV-1a identity, not a hash commitment; no collision
  resistance is claimed.
- `outcome_value` is meaningful only for `ok-value` and
  `outcome_fuel_used` only for `incomplete` (documented total-function
  zeroes elsewhere).
- Model `rev`/`count`/`sum` are the C00 accepted-model record; generational
  topology handles arrive in C04.
