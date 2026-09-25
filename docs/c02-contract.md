# C02 packet contract — robust predicates and exact-number support

Milestone C02 (MASTER_PLAN §10): orientation2D/3D, incircle/insphere,
segment relations, and classification with a fast bounded-error filter
and exact fallback. Exit: adversarial near-degenerate cases match
independent exact results; uncertain calculations never silently choose
a side.

Implementation: `src/c02/types.bend` (signs, results, constants, exact
small-integer domain, sign-magnitude arithmetic), `src/c02/ops.bend`
(filters, exact kernels, the four predicates, segment relation,
triangle classification). Laws+proofs: `laws/c02.bend`. Tests:
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
6. All coordinates integral within the predicate's exact domain →
   the exact determinant sign (zero or not).
7. Else `numerical-uncertainty`: filter silent, exact domain
   inapplicable — an honest abstention, never a guessed side.

Zero signs come ONLY from exact paths (steps 2, 6). A computed F64
zero never certifies: `neg-tri-unc` pins a case whose computed
determinant is exactly `0.0` with true determinant `+4` → uncertain.

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

## 4. Exact small-integer domains

`sint_of` detects integrality by truncation roundtrip:
`mag = to_u64(|x|)`, ok iff `to_f64(mag) == |x|` and `mag <= lim`
(all mags < 2^53 convert exactly; `-0.0` normalizes to `+0`).
Determinants run in sign-magnitude `SB` arithmetic over U64 with
these domains and maxima (wrap impossible by construction):

| Predicate | \|coord\| limit | Max \|det\| | U64 margin |
|---|---|---|---|
| orient2d | 2^26 | 2^55 | 9 bits |
| orient3d | 2^12 | 6·2^39 < 2^42 | 22 bits |
| incircle | 2^8 | 6·2^37 < 2^40 | 24 bits |
| insphere | 2^8 | 4·2^50 = 2^52 | 12 bits |

Exactness is about the SUPPLIED coordinates (MASTER_PLAN §10): the
kernel signs the determinant of the given F64 values exactly when
they are small integers; it never repairs information lost earlier.
For orient3d/incircle integer domains the filter already decides
every nonzero case (`|det| >= 1` exceeds `K·detsum_max`), so their
exact path fires for zeros (pinned `o3-coplanar_zero`, `ic-on_zero`,
`is-on_zero`); orient2d/insphere admit nonzero exact wins (pinned
`o2-near_neg`: true det −1, filter bound ≈ 2.0).

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
`numerical-uncertainty`: near-degenerate non-integral inputs,
overflow-scale products (`neg-o2-ovf`: DBL_MAX axes),
subnormal-floor detsum (`neg-o2-tiny`), computed-zero-with-nonzero-
truth (`neg-tri-unc`). `unsupported-op`, `nonconvergence` (still
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
  integer zeros (`o2-coll-zero`, `o3-coplanar-zero`, `ic/ic/on`,
  `is-on-zero`). Tested: computed-zero pins report uncertain
  (`neg-tri-unc`, stress truth-zero-nonintegral cases).
- P3 (exact completeness on domains): integer inputs within §4
  limits are always decided exactly. Tested: every must-exact
  stress case decided (0 misses), `pos-sint-*` boundary pins.
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

Truth oracle: python `Fraction` on the exact supplied F64 values
(spec: exactness is about the supplied coordinates) plus `struct`
bit pins; an independent F64 path model predicted filter-vs-exact
routing for every pinned case. Differential: 1313 randomized +
near-degenerate predicate cases and 404 seg/tri cases (independent
barycentric + parametric oracles, themselves cross-checked),
0 contradictions, all integer-domain cases decided exactly. Suite
runs on three lanes (interpreted, native, JS) with byte-identical
stdout; see the receipt for hashes and counts.

## 10. Limitations (honest scope, not placeholders)

- Overflow-scale products and subnormal-floor detsums report
  uncertainty even when the sign looks obvious (pinned
  `neg-o2-ovf`, `neg-o2-tiny`); 1e150-scale is decided (`pos-o2-big150`).
- Exactness covers small-integer coordinates (§4) only; general
  expansion arithmetic is NOT implemented — non-integral
  near-degenerate inputs abstain honestly instead.
- incircle/insphere return raw determinant signs without
  orientation canonicalization (§5).
- §3 bounds are stated + pin/differential-tested, not
  machine-proved.
- Native-backend workaround (fork bug at BEND_PIN): a nested
  `Bool.or` of 3+ user-def calls with shared binders miscompiles on
  the C lane (returns True; interp/JS correct; minimal repro in the
  receipt). C02 let-binds every repeated-point test before
  combining (`ops.bend` NOTE at `pteq2`) — no semantic effect:
  all three lanes agree byte-identically on suite + stress.
- No certified-interval/root-isolation types: signs suffice for
  the admitted predicates (MASTER_PLAN §10 "where necessary" does
  not trigger here); root isolation belongs to C07 intersections.
- insphere nonzero exact wins are covered by analysis + stress,
  with laws pinning the zero arm; only orient2d pins a nonzero
  exact win by name (`o2-near_neg`).
