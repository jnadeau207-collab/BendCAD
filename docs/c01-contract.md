# C01 packet contract — mathematical foundation

Milestone C01 (MASTER_PLAN §10): Vec2/Vec3, points versus directions,
frames, matrices, rigid transforms, normalization, robust distance
calculations, derivatives, needed linear algebra. Conditioning checks and
no overflow-prone naive norms. Exit: numerical tests cover extreme
scales, near-singular frames, and round-trip transforms within stated
bounds.

Implementation: `src/c01/types.bend` (data + validated constructors +
one result type), `src/c01/ops.bend` (arithmetic core, conditioning,
frames, rigids). Laws+proofs: `laws/c01.bend`. Tests:
`tests/c01/check.bend` (support), `tests/c01/neg.bend`,
`tests/c01/pos.bend`.

## 1. Point-vs-direction distinction

`Point` is a position; `Dir` is a free finite vector (possibly zero as
data). The type system, not convention, separates them: there is no
point+point and no scalar+point. The admitted combinations are:

| Op | Signature | Meaning |
|---|---|---|
| `p_minus_p` | Point × Point → Dir | displacement, fails on true overflow |
| `p_plus_d` | Point × Dir → Point | translation, fails on true overflow |
| `p_dist` | Point × Point → F64 | robust distance (§3) |
| `seg_dir` | Point × Point → Dir | unit direction a→b; coincident → invalid |
| `d_add/d_scale` | Dir × Dir / F64 × Dir → Dir | free-vector algebra |
| `dr_unit` | Dir → Dir | unit direction; zero → invalid |
| `rg_apply_p` | Rigid × Point → Point | rotation + translation |
| `rg_apply_d/v` | Rigid × Dir/Vec3 → Dir/Vec3 | rotation ONLY; translation ignored |

`Vec2`/`Vec3` are raw coordinate triples for intermediate algebra;
`Point`/`Dir` carry the geometric meaning. A `Dir` need not be unit:
unit-ness is a checked property (`m3_is_rot`, frame validation), and
`dr_unit`/`v3_normalize` fail closed on zero rather than publish NaN.

## 2. Frames and rigid transforms

A `Frame` is an origin plus three orthonormal basis columns
(bx, by, bz), right-handed. A `Rigid` is a proper rotation matrix plus
a translation vector. Both rest on one obligation, `m3_is_rot`:

- each row unit: |‖row‖ − 1| ≤ 1e-12 (`th_unit`);
- pairwise orthogonal: |dot| ≤ 1e-12;
- right-handed with unit determinant: det > 0 and |det − 1| ≤ 1e-9
  (`th_det`).

`mk_frame`/`mk_rigid` reject anything else as `invalid-input`
(malformed frame spec). Composition re-checks the product and reports
`numerical-uncertainty` if rounding drift broke the obligation — a
single compose/invert/apply round-trip passes with ~1e-16 vs 1e-12
margin; long un-renormalized chains are NOT promised to stay valid
(§10). Inversion is exact-transpose based, never a general solve.

`frame_basis(o, z, x)` builds a frame Gram-Schmidt style (cf. legacy
`PlacementFrame`, `geometry.cpp:180-194`): normalize z, project x
orthogonal, y = z × x. Zero input is `invalid-input`; (near-)parallel
input — projected remnant ≤ 1e-12 · ‖x‖ (`th_par`, RELATIVE, unlike
legacy's absolute 1e-9) — is `numerical-uncertainty`.

Frame maps run through the one rigid path: `fr_to_world` is
`rg_apply_p ∘ rg_of_frame`; `fr_to_local` inverts first. No duplicate
algorithm. Angle-based constructors (axis/angle, Euler, quaternion)
are absent: Bend has no qualified trigonometric primitives yet, and
C01 invents none; rotation inputs arrive as validated matrices
(C03 owns the trigonometric policy per MASTER_PLAN §5).

## 3. Norm policy: scaled hypot, never naive

`v3_norm_raw`/`v2_norm_raw` compute m = max|xᵢ| and return
m·√(Σ(xᵢ/m)²), 0 when m = 0. Every ratio is in [−1, 1], so the sum of
squares (≤ 3) and its root can never overflow spuriously: given
finite input, the only nonfinite outcome is TRUE overflow (exact
norm > DBL_MAX), reported as `numerical-uncertainty`. There is no
`sqrt(x*x+y*y+z*z)` in any source (verified by grep: `sqrt` occurs
only in the two scaled definitions). Distances (`v2_dist`,
`v3_dist`, `p_dist`) difference first (overflow there is true
overflow → uncertainty), then take the scaled norm.

`F64.max` swallows NaN (it keeps `a` unless `a<b` is ordered), so the
raw scaled norm can collapse to 0.0 on nonfinite input. Every
publishing norm entry therefore gates on INPUT finiteness first and
reports `invalid-input` for any nonfinite entry — never trusting a
finite result alone. Gated: `v2/v3_norm`, `v2/v3_normalize`,
`dr_unit` (hence `v3_grad_norm`), `v2/v3_dist`, `p_dist`, `seg_dir`,
`frame_basis` (origin, z, and x inputs). Audited closed without a
gate: `m3_is_rot` (ANDs `m3_fin` over its input, so nonfinite yields
`False`), `m3_inv` (its `m3_maxabs` NaN either poisons the scaled
determinant or trips the zero arm — both `uncertain`), and the
rigid/frame apply/compose paths (no norm use; NaN propagates through
mul/add to a nonfinite result → `uncertain`). Pinned: `neg-norm-*`,
`neg-unit-*`, `neg-dist-*`, `neg-seg-nan`, `neg-pdist-nan`,
`neg-drunit-nan`, `neg-grad-nan`, `neg-basis-nan*`,
`neg-dot-nan-unc`, `neg-inv-nan-unc`.

Summation order is part of the contract: dot products, determinants
(cofactor expansion along row 0), and matrix products are LEFT FOLDS
with the exact parenthesization in `ops.bend`. Reordering needs a
contract amendment and re-pinning, because rounding differs.

## 4. Conditioning checks with explicit thresholds

| Check | Threshold | Fail arm |
|---|---|---|
| Frame/rigid basis unit (`unit_ok`) | ‖row‖ within 1e-12 of 1 | invalid (spec) |
| Frame/rigid orthogonality (`ortho_ok`) | |dot| ≤ 1e-12 | invalid (spec) |
| Handedness/determinant (`det_ok`) | det > 0, |det−1| ≤ 1e-9 | invalid (spec) |
| `frame_basis` parallelism | remnant ≤ 1e-12 · ‖x‖ | uncertain |
| `m3_inv` scaled singularity | |det(B)| ≤ 1e-12, B = A/max|A| | uncertain |
| `m3_inv` zero matrix | max|A| = 0 | uncertain |
| `normalize`/`dr_unit` zero | norm = 0 exactly | invalid |
| `normalize` true overflow | norm = +Inf | uncertain |
| norm-family nonfinite input | any input slot nonfinite (§3 gate list) | invalid (malformed) |

`m3_inv` is a scaled adjugate: B = A/s with s = max|Aᵢⱼ| has entries
in [−1, 1], so cofactors and det(B) (≤ 6 in magnitude) cannot
overflow; A⁻¹ = adj(B)/(s·det B), re-validated finite. The 1e-12
singularity threshold applies to the SCALE-FREE det(B), so
diag(1e300, 1e300, 1e300) inverts exactly while diag(1, 1, 1e-13)
fails honestly. All threshold comparisons fail closed on nonfinite
(`F64.is_le` is False unless ordered), and finiteness is also
checked explicitly.

## 5. Per-op uncertainty budgets (MASTER_PLAN §8)

No universal epsilon. Each op names its Tol field and bound; results
in the normal range carry relative bounds, subnormal results carry
absolute bounds (all in ulp of the result):

| Op | Budget field | Bound (normal range) |
|---|---|---|
| `v2/v3_norm`, `v2/v3_dist`, `p_dist` | lin | ≤ 6 ulp relative |
| `v3_normalize`, `v2_normalize`, `dr_unit` | ang | direction ≤ 6 ulp/component; unit: ‖u‖−1 within ±2 ulp, normal-range inputs only |
| `v3_grad_norm`, `seg_dir` | ang | as normalize |
| `v2/v3_dot`, `v3_cross`, `m3_det`, `m3_mul` | lin | ≤ n ulp relative absent cancellation (n = terms); cancellation → absolute bound |
| `m3_inv` | lin | ≤ 64 ulp relative when admitted (det(B) > 1e-12) |
| `rg_compose/inv/apply`, frame maps | lin | ≤ 8 ulp relative per application |
| `p_plus_d`, `p_minus_p`, `v_add/sub/scale`, `d_add/d_scale` | lin | ≤ 2 ulp (one rounding + validation) |

The normalize unit bound is honest about subnormals: each published
component is `xᵢ/n` correctly rounded, and in the normal range the
published vector is unit to ±2 ulp (measured exactly 1.0:
`pos-unit-is-unit`). But when ‖v‖ itself is subnormal, `n` rounds
coarsely and the direction scale degrades: `normalize(min-sub³)` =
(0.5, 0.5, 0.5) with ‖u‖ = 0.866 (deviation 0.134), and
`v2_normalize(min-sub²)` = (1.0, 1.0) with ‖u‖ = √2. Subnormal-
magnitude inputs are therefore EXCLUDED from the unit promise; their
exact bits are pinned instead (`pos-unit-sub3`, `pos-unit-sub2`,
`pos-drunit-sub3`).

Exact ops consume no budget: `rg_jac`, `v2/v3_neg`, `m3_trans`,
`rg_of_frame`/`fr_of_rigid`, `rg_ident` reorder or copy values
without rounding (`pos-jac` pins one).

`par`/`apx`/`imp` are validated but unconsumed (reserved for C03
curves, C10 tessellation, C12 import). Every budgeted op above has at
least one exact pin in `tests/c01/pos.bend` (norm/dist/dot/add/sub/
scale/mul/normalize/unit/apply/jac/point-dir rows: `pos-v2norm-34`,
`pos-v3dist-345`, `pos-v2dist-345`, `pos-v2dot-14`, `pos-v3add`,
`pos-v3sub`, `pos-v3scale`, `pos-dadd`, `pos-dscale`, `pos-v2add`,
`pos-v2scale`, `pos-mul-ident`, `pos-v2unit-34`, `pos-drunit-005`,
`pos-applyv`, `pos-jac`, `pos-pplus`, `pos-pminus`, plus the §3/§8
pins). Bounds are analytic claims tested at those pinned values and
the laws; they are not machine-checked proofs (category: tested
behavior + stated analysis, per §11 discipline — never relabeled as
proven).

## 6. Overflow/underflow policy at extreme scales

- Entry: every constructor validates finiteness component-wise;
  NaN/±Inf (including sNaN payloads and negative NaN — all have
  `F64.class` ≥ 2) fails as `invalid-input`, in EVERY slot. The norm
  family gates its inputs identically (§3 gate list): nonfinite in,
  `invalid-input` out, before any max-based arithmetic runs.
- True overflow (exact result beyond DBL_MAX: DBL_MAX-diagonal norm,
  DBL_MAX−(−DBL_MAX) difference, overflowing dot/matmul/apply):
  `numerical-uncertainty`, never a wrapped or infinite value.
- Spurious overflow is impossible by construction in norm/dist/
  normalize/unit/frame-orthogonalization/inverse (all scaled);
  dot/cross/det/matmul are naive-order but validate-and-fail, so a
  spurious intermediate yields uncertainty, never a wrong number.
- Underflow to zero/subnormal is ACCEPTED (the value is finite):
  relative bounds loosen to absolute error ≤ 4 ulp near zero; e.g.
  ‖(5e-324, 5e-324, 5e-324)‖ = 1e-323 (bits 2), tested.
- −0.0 is valid input and compares equal to +0.0; published zeroes
  may be either sign only where IEEE exactness allows (tests pin
  exact bits).

## 7. Failure arms (C00 statuses reused, no new taxonomy)

`CRes = Cok{CVal} | Cerr{FailKind}` reuses `src/c00/types.bend`'
`FailKind` verbatim: `invalid-input` (malformed/degenerate: nonfinite
entry to constructors AND to the norm family (§3 gate list),
non-orthonormal frame spec, zero normalize, coincident `seg_dir`),
`numerical-uncertainty` (true overflow, failed conditioning:
singular/near-singular inverse, parallel frame basis, compose drift
— plus nonfinite smuggled past constructors into result-validated
polynomial ops: dot/cross/det/mul/add/sub/scale/inv/apply/compose
propagate NaN to a nonfinite result, where input-malformation and
true overflow are indistinguishable by design, so all report
uncertainty; pinned `neg-dot-nan-unc`, `neg-inv-nan-unc`).
`unsupported-op`, `nonconvergence` (still reserved), `cancelled`,
`resource-exhausted`, and `Incomplete` have no C01 trigger: C01 ops
are pure O(1) functions with no dispatch, no iteration, and no fuel
threading — the C00 pipeline keeps that machinery. `Cok` values are
always finite (every publishing arm re-validates); projectors
(`cres_f`, `cres_v3`, …) are total with documented zeroes on
mismatched arms. `cres_kind` is total too: `FailKind` has no
ok-valued arm, so `Cok` yields `F_invalid` BY DOCUMENTED CONVENTION
— gate on `cres_ok`/`cres_show` before reading the kind (pinned
`pos-kind-doc`). `m3_is_rot` is a `Bool`, not a `CRes`: nonfinite
input yields `False` via its explicit `m3_fin` conjunct.

## 8. Explicit general laws

Bend rejects open laws, so `laws/c01.bend` proves every claim it
states; the unbounded claims live here explicitly, grounded by the
proven instances and tests named beside them.

- M1 (scaled norm never spuriously overflows): for finite v with
  exact ‖v‖ ≤ DBL_MAX, `v3_norm` publishes. Proven: axis-DBL_MAX,
  1e300-cube, min-subnormal instances. Tested: `pos-norm-*`.
- M2 (zero/degenerate never publishes): normalize of zero,
  `seg_dir` of coincident points, inverse of singular matrices are
  `Cerr`, and `Cerr` projectors yield documented zeroes, never NaN.
  Proven: `normalize_zero_*`, `seg_coincident`, `inv_*`
  instances + `cerr_zero_*`. Tested: all `neg-*`.
- M3 (round-trip identity): invert-then-apply and compose-with-
  inverse restore the input within §5 bounds. Proven: exact Rz90
  round-trip instance. Tested: `pos-rt-*`.
- M4 (point/direction separation): translation never affects `Dir`
  application; no point+point exists (by construction — the symbol
  is absent, grep-verified). Proven: `dir_ignores_translation`.
  Tested: `pos-dir-notrans`.
- M5 (frame obligation): every published `Frame`/`Rigid` satisfies
  `m3_is_rot`; `frame_basis` output is right-handed orthonormal
  within §2 thresholds. Proven: `frame_ident_ok`,
  `frame_basis_ok` instances + rejection instances. Tested:
  `pos-frame-*`, `neg-frame-*`.
- M6 (entry boundary): nonfinite in any component of any
  constructor fails as `invalid-input`. Proven: per-type instances.
  Tested: `neg-nan-*`, `neg-inf-*` for every entry path. The norm
  family gates identically (§3): `neg-norm-*`, `neg-unit-*`,
  `neg-dist-*`, `neg-seg-nan`, `neg-pdist-nan`, `neg-drunit-nan`,
  `neg-grad-nan`, `neg-basis-nan*`; result-validated polynomial ops
  report `uncertain` instead (`neg-dot-nan-unc`, `neg-inv-nan-unc`).

## 9. Verification

```sh
export PATH=$HOME/.bend/bin:$HOME/.bun/bin:$PATH; export BEND_NO_TELEMETRY=1
bend src/c01/types.bend --check-only
bend src/c01/ops.bend --check-only
bend laws/c01.bend --check-only
bend tests/c01/check.bend --check-only
bend tests/c01/neg.bend
bend tests/c01/pos.bend
grep -rn '@unsafe' src/c01 laws/c01.bend tests/c01  # no matches
grep -rn 'F32\|f32' src/c01 laws/c01.bend tests/c01  # no matches
```

Bit pins come from python `struct` (independent oracle); norm pins
use the same scaled formula evaluated by an independent engine.

## 10. Limitations (honest scope, not placeholders)

- No angle-based rotation constructors (no qualified trig in Bend;
  C03 owns that policy). Rotations arrive as validated matrices.
- No re-orthonormalization primitive: long compose chains may drift
  past 1e-12 and then honestly fail; single round-trips are exact
  or within §5.
- `par`/`apx`/`imp` tolerance fields validated, unconsumed.
- Curve/surface derivatives belong to C03; C01 provides the norm
  gradient, segment directions, and rigid Jacobians (the linear
  part C02/C03 build on).
- §5 ulp bounds are stated + pin-tested, not machine-proved.
- Subnormal-magnitude normalize inputs publish exact-scaled
  directions that are NOT unit (measured ‖u‖ = 0.866 for all-min-sub
  v3, √2 for all-min-sub v2); unit-ness is promised for normal-range
  inputs only (§5).
