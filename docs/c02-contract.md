# C02 packet contract — robust predicates and exact-number support

Milestone C02 (MASTER_PLAN §10): orientation2D/3D, incircle/insphere,
segment relations, and classification with a fast bounded-error filter
and exact fallback. Exit: adversarial near-degenerate cases match
independent exact results; uncertain calculations never silently choose
a side.

Implementation: `src/c02/types.bend` (signs, results, constants),
`src/base/ex.bend` (floating-point expansion arithmetic, shared with
C05), `src/c02/ops.bend` (filters, exact expansion kernels, the four
predicates, segment relation, triangle classification). Laws+proofs: `laws/c02.bend`. Tests:
`tests/c02/check.bend` (support), `tests/c02/neg.bend`,
`tests/c02/pos.bend`.

## 1. Signs and result types

`Sign` is the certified output of every predicate: `Sg_neg`, `Sg_zero`,
`Sg_pos` (`neg`/`zero`/`pos`). `PRes = Pok{Sign} | Perr{FailKind}`
carries a certified sign or a C00 failure kind — the C00 taxonomy is
reused verbatim, no new kinds. `Xrel` is the segment relation
(`disjoint`/`touch`/`proper`/`overlap`) in an `Xres`; `Tcls` is the
triangle class (`inside`/`boundary`/`outside`) in a `Tres`.

Projectors are total with documented defaults: `pres_sign` of `Perr`
is `Sg_zero`, `xres_rel` of `Xerr` is `X_disjoint`, `tres_cls` of
`Terr` is `T_out`. `pres_kind`/`xres_kind`/`tres_kind` of an ok-valued
result yield `F_invalid` BY DOCUMENTED CONVENTION (mirroring C01
`cres_kind`); gate on `*_ok`/`*_show` before reading the kind (pinned
`pos-kind-doc`, `neg-pres-zero`, `neg-xrel-default`, `neg-tcls-default`;
proven generally `perr_sign_zero`, `xerr_rel_dis`, `terr_cls_out`).

## 2. Pipeline order (first match wins)

Every predicate runs one total order (`ops.bend`):

1. Any input slot nonfinite → `invalid-input` (every slot of every
   entry path, like the C01 norm family).
2. Any two input points exactly equal → `Pok(Sg_zero)`: repeated
   determinant rows are exactly zero, at any scale, integral or not.
3. Filter floor missed (`det`/`detsum` nonfinite, or
   `detsum < 2^-960`) → exact-or-uncertain (§4).
4. Shortcut: orient2d opposite-sign products, or 3x3/4x4
   positive/negative part exactly zero → the certified NONZERO sign.
5. Error bound `|det| > K·detsum` → the certified NONZERO sign.
6. Exact expansion evaluation of the same determinant (§4) → the
   exact sign of the determinant of the supplied values (zero or not).
7. Else `numerical-uncertainty`: the expansion is not representable
   (a partial product or sum overflows, or a product's rounding error
   falls below the subnormal grid) — an honest abstention, never a
   guessed side.

Zero signs come ONLY from exact paths (steps 2, 6). A computed F64
zero never certifies: `pos-tri-far-exact` pins a case whose computed
determinant is exactly `0.0` with true determinant nonzero, now
decided by the expansion.

## 3. Filter error analysis

Shewchuk Stage-A bounds with conservative power-of-two coefficients
(bit-pinned exact), each with >= 2x margin over the published
A-constant for its determinant size:

| Predicate | Shewchuk A-constant | C02 K | Margin |
|---|---|---|---|
| orient2d | (3+16ε)ε ≈ 3.33e-16 | 8ε = 2^-50 | 2.7x |
| orient3d | (7+56ε)ε ≈ 7.77e-16 | 16ε = 2^-49 | 2.3x |
| incircle | (10+96ε)ε ≈ 11.1e-16 | 32ε = 2^-48 | 3.2x |
| insphere | (16+224ε)ε ≈ 17.8e-16 | 64ε = 2^-47 | 4.0x |

The floor `detsum >= 2^-960` keeps the bound itself in the normal
range (minimum bound 2^-1007), so absolute underflow crumbs (at most
~200 roundings × 2^-1075 ≈ 2^-1067 on the insphere path) are
negligible with 2^40 margin, and bound/detsum rounding (relative
ε/2 each) is absorbed by the coefficient margins.

Shortcuts: orient2d's opposite-sign shortcut is sound because inputs
are F64 values (multiples of 2^-1074), so exact differences can never
round to zero from nonzero, and product roundings preserve
sign-or-zero — opposite value signs mean no cancellation. The
P==0/N==0 shortcuts need the VALUE-sign split of the six signed
triples (a +cofactor triple can be negative; splitting by cofactor
position would be WRONG — found and fixed during implementation,
pinned by `o3-neg`): under the floor, a zero part forces the true
determinant to the other side's sign.

Summation order is part of the contract: 3x3 cofactor expansion along
row 0 with C01's exact parenthesization; triples `((x·y)·z)` with
exact negation on the last three; P/N pinned left folds over the six
signed triples; 4x4 Laplace `((r0·m0 − r1·m1) + r2·m2) − r3·m3` with
row0-weighted minor P/N in the same association;
`detsum = P+N`; square columns `dx²+dy²(+dz²)` left folds.
Reordering needs a contract amendment and re-pinning.

Category: stated analysis + pin-tested behavior (§9 differential),
never relabeled as proven (C01 §11 discipline).

## 4. Exact expansion fallback (all finite doubles)

Since R0.2 the fallback is Shewchuk expansion arithmetic
(`src/base/ex.bend`), not a small-integer kernel. An expansion is a
nonoverlapping list of F64 components, least significant first, whose
exact sum is the represented value. Primitives: `two_sum` (Knuth,
6 flops) and `two_prod` (`F64.fma` error term); `ex_grow`/`ex_add`
(grow-expansion with zero elimination), `ex_scale`, `ex_mul`,
`ex_dif` (exact difference of two doubles). The determinant is
evaluated with the SAME cofactor expansion as the filter, over
expansion-valued differences, so its sign is the exact sign of the
determinant of the supplied values. `ex_sign` reads the sign of the
most significant nonzero component.

Representability is tracked, not assumed. Every expansion carries an
`ok` flag, cleared when any `two_sum` result is nonfinite or when a
product is not exactly split: `prod_exact(a, b, p)` requires `p`
finite and `lsb(a) + lsb(b) ≥ 1076` (biased exponents of the lowest
set mantissa bits), i.e. the exact product's lowest bit lies on the
F64 grid, so `p + fma(a, b, −p)` is exact. A cleared flag yields
`Su` → `numerical-uncertainty`. Zero factors are always exact.

Consequence: every finite input whose intermediate products stay
inside the F64 exponent range is decided exactly: integral or not,
near-degenerate or not. Abstention is confined to overflow scale
(coordinates near `DBL_MAX`: `neg-o2-ovf`, `neg-o3-ovf`,
`neg-ic-ovf`, `neg-is-ovf`, `neg-seg-ovf`, `neg-tri-ovf`, and laws
`o2_ovf_unc`, `o3_ovf_unc`, `ic_ovf_unc`, `is_ovf_unc`, `seg_ovf_unc`) and
subnormal-scale products whose error term leaves the grid
(`neg-o2-sub`). Exactness remains about the SUPPLIED coordinates
(MASTER_PLAN §10): the kernel never repairs information lost before
the call.

Cost: the filter decides almost every call in O(1). The fallback is
O(k²) in expansion length k (bounded by the determinant size, at
most a few hundred components for insphere), and runs only when the
filter is silent.

## 5. Sign conventions

- `orient2d(a,b,c)`: pos iff `c` is strictly left of `a→b` (CCW).
  Antisymmetry pinned (`o2-flip`, `pos-o2-flip`).
- `orient3d(a,b,c,d)`: pos iff tet `(a,b,c,d)` is positively
  oriented (d strictly above oriented plane abc).
- `incircle(a,b,c,d)`: RAW translated-determinant sign, no
  orientation canonicalization: with `(a,b,c)` CCW, pos iff `d` is
  strictly inside circle(a,b,c).
- `insphere(a,b,c,d,e)`: RAW sign: with tet `(a,b,c,d)` positively
  oriented, pos iff `e` is strictly inside sphere(a,b,c,d).
- Repeated input points → zero in all four (repeated rows; the
  determinant is truly zero even where the geometry is degenerate —
  callers needing nondegeneracy check it separately, as `tri_class`
  does for its triangle).

## 6. Segment relation and triangle classification

`seg_seg(a,b,c,d)` runs `o1..o4 = orient2d(a,b,c), (a,b,d), (c,d,a),
(c,d,b)`; first sub-failure in that order wins propagation. Signs
decide: both pairs strictly opposite → `proper`; point-segment cases
first (point-point equality, point-on-segment via zero+bbox);
collinear (`z1 && z2`) → 1D overlap on the dominant axis of `ab`
(positive length `overlap`, single point `touch`, else `disjoint`);
any zero with its endpoint on the other segment → `touch`; else
`disjoint`. Zero signs are exact and every comparison (equality,
bbox, 1D overlap) is exact on F64 values, so the relation is EXACT
whenever the four orientations decide.

`tri_class(p,a,b,c)` gates on `o0 = orient2d(a,b,c)`: failure
propagates, zero → `invalid-input` (degenerate triangle is
malformed). Edge signs `o1..o3 = (a,b,p), (b,c,p), (c,a,p)` decide:
with `o0` positive, inside iff no edge sign is neg, boundary iff
inside-sided with a zero (a zero with the other signs inside-sided
forces `p` onto that edge segment — no bbox needed), else outside;
mirrored for `o0` negative. First edge failure in `o1..o3` order
wins propagation.

## 7. Failure arms (C00 statuses reused, no new taxonomy)

`invalid-input`: nonfinite in any slot of any entry (all four
predicates, both combinators), degenerate triangle. (Zero-area
segments are ADMITTED as points, not malformed.)
`numerical-uncertainty`: only when the exact expansion is not
representable (§4): overflow-scale products (`neg-*-ovf`) and
subnormal products whose rounding error leaves the F64 grid
(`neg-o2-sub`). Near-degenerate finite inputs of moderate magnitude,
integral or not, are always decided. `unsupported-op`, `nonconvergence` (still
reserved), `cancelled`, `resource-exhausted`, and `Incomplete` have
no C02 trigger: C02 ops are pure O(1) functions with no dispatch,
no iteration, and no fuel threading — the C00 pipeline keeps that
machinery. Combinators propagate the first sub-failure in fixed
documented order (§6).

## 8. Explicit general laws

Bend rejects open laws, so `laws/c02.bend` proves every claim it
states; the unbounded claims live here explicitly, grounded by the
proven instances and tests named beside them.

- P1 (filter soundness): every filter-certified nonzero sign equals
  the exact determinant sign of the supplied coordinates. Proven:
  shortcut/bound instances per predicate (`o2-ccw/cw/big150`,
  `o3-neg/pos`, `ic-in/out`, `is-in/out`). Tested: `pos-*` pins +
  1717-case differential vs independent Fraction truth, 0
  contradictions (§9).
- P2 (zero exactness): zero is published only by exact paths.
  Proven: rep-shortcut on NON-INTEGRAL duplicates (`o2-rep-zero`),
  expansion zeros (`o2-coll-zero`, `o3-coplanar-zero`, `ic-on-zero`,
  `is-on-zero`). Tested: computed-zero-with-nonzero-truth pins are
  decided with the true sign (`pos-tri-far-exact`), stress
  truth-zero non-integral cases decided zero.
- P3 (exact completeness): every finite input whose expansion is
  representable (§4) is decided exactly. Proven: non-integral
  near-degenerate instances per predicate (`o2_near_exact`,
  `o2_tiny_exact`, `o3_near_exact`, `ic_near_exact`,
  `is_near_exact`, and `seg_near_exact` for the combinator), each of
  which the pre-R0.2 kernel reported
  uncertain. Tested: the R0.2 oracle (§9) finds 0 moderate-magnitude
  uncertain results; the pre-R0.2 kernel gives 464–468 per seed on
  the same cases.
- P4 (entry boundary): nonfinite in any component of any entry
  fails as `invalid-input`. Proven: per-predicate instances.
  Tested: `neg-*-nan/inf/ninf` for every entry path.
- P5 (combinator exactness): seg/tri relations are exact on
  decided signs. Proven: all-relation instances. Tested: seg/tri
  stress vs independent barycentric/parametric oracles (404/404).
- P6 (orientation conventions): antisymmetry and the §5 geometric
  readings. Proven: `o2-flip`. Tested: `pos-o2-flip`, `pos-tri-cw`
  (mirrored-triangle inside), in/out/on pins per predicate.

## 9. Verification

```sh
export PATH=$HOME/.bend/bin:$HOME/.bun/bin:$PATH; export BEND_NO_TELEMETRY=1
bend src/c02/types.bend --check-only
bend src/c02/ops.bend --check-only
bend laws/c02.bend --check-only
bend tests/c02/check.bend --check-only
bend tests/c02/neg.bend
bend tests/c02/pos.bend
grep -rn '@unsafe' src/c02 laws/c02.bend tests/c02  # no matches
grep -rn 'F32\|f32' src/c02 laws/c02.bend tests/c02  # no matches
```

R0.2 oracle: `python tools/oracle/c02/oracles.py` generates 1324
cases per seed (random, near-degenerate by construction, integral
and non-integral, subnormal and overflow scale), evaluates them
natively, and compares with `Fraction` truth: wrong sign = 0 (any
magnitude), uncertain at moderate magnitude = 0.

Pre-R0.2 truth oracle: python `Fraction` on the exact supplied F64 values
(spec: exactness is about the supplied coordinates) plus `struct`
bit pins; an independent F64 path model predicted filter-vs-exact
routing for every pinned case. Differential: 1313 randomized +
near-degenerate predicate cases and 404 seg/tri cases (independent
barycentric + parametric oracles, themselves cross-checked),
0 contradictions, all integer-domain cases decided exactly. Suite
runs on three lanes (interpreted, native, JS) with byte-identical
stdout; see the receipt for hashes and counts.

## 10. Limitations (honest scope, not placeholders)

- Overflow-scale products and subnormal products whose error term
  leaves the F64 grid report uncertainty even when the sign looks
  obvious (pinned `neg-*-ovf`, `neg-o2-sub`); 1e150-scale is decided
  (`pos-o2-big150`). Scaling inputs by a power of two before the
  call would extend the decided range; not implemented.
- incircle/insphere return raw determinant signs without
  orientation canonicalization (§5).
- §3 bounds are stated + pin/differential-tested, not
  machine-proved.
- Native-backend workaround: at `numeric/2026-09-25` a nested
  `Bool.or` of 3+ user-def calls with shared binders miscompiled on
  the C lane (returned True; interp/JS correct; minimal repro in the
  C02 receipt). C02 let-binds every repeated-point test before
  combining (`pteq2`), with no semantic effect: all three lanes
  agree byte-identically on suite + stress. The miscompile is gone
  since `bc01485d`: re-run 2026-10-05, the repro gives `F`
  natively at `bc01485d` and on every lane at `numeric/2026-10-05`,
  and still `T` natively at `50ec219a`. The let-binding stays.
- No certified-interval/root-isolation types: signs suffice for
  the admitted predicates (MASTER_PLAN §10 "where necessary" does
  not trigger here); root isolation belongs to C07 intersections.
- insphere nonzero exact wins are covered by analysis + stress,
  with laws pinning the zero arm; only orient2d pins a nonzero
  exact win by name (`o2-near_neg`).
