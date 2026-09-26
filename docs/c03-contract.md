# C03 packet contract — curves, surfaces, and trimming

Milestone C03 (MASTER_PLAN §10): lines, circles/arcs, conics, planes,
cylinders, cones, spheres, tori, Bezier curves/surfaces, rational
B-splines/NURBS; knots, multiplicities, rational weights, derivatives,
parameter domains, periodic seams, poles, projection, subdivision,
bounding enclosures; trimming curves in surface parameter space from
the outset. Exit: conics, rational quarter-circles, periodic curves,
derivative identities, and surface evaluations agree with
analytic/high-precision references within declared bounds.

Implementation: `src/c03/types.bend` (data + total predicates +
validated constructors + one result type), `src/c03/ops.bend`
(evaluation, derivatives, subdivision, enclosures, projection,
NURBS de Boor). Laws+proofs: `laws/c03.bend` (sibling packet).
Tests: `tests/c03/check.bend`, `tests/c03/neg.bend`,
`tests/c03/pos.bend` (sibling packet).

## 1. Representation policy: a trig-free rational core

Base F64 at `BEND_PIN` provides add/sub/mul/div/sqrt/FMA,
classification, and conversions — no sin/cos/atan2/exp, no floor,
no fmod. C03 therefore admits NO transcendental evaluation and no
angle-valued API. Every curve and surface below is polynomial or
rational in its parameters:

- circles use the rational full-turn map (§5), not angle + cos/sin;
- conics are rational quadratic Beziers classified by a weight
  discriminant, not by focus/directrix angles;
- cones take a slope `k` (radial per unit axial), never a half-angle;
- periodic seams are parameter identifications with honest seam
  points, never branch cuts of a transcendent.

The CAD trigonometric/range-reduction policy required by MASTER_PLAN
§5 is specified here as POLICY, with the implementation reserved:
when qualified trig arrives, it arrives as total Bend functions
`sin_pi`/`cos_pi` (period 2 in half-turns, exact at integers),
`atan2` (exact on the axes), and `reduce_half` (argument reduction
with an explicit out-of-range arm), each with a stated ulp bound,
consuming the `ang` tolerance field, and proven against a
high-precision oracle — never as an FFI call, and never smuggled
through F32. Until then, rotation inputs keep arriving as validated
matrices/frames (C01), and this packet invents no polynomial
pretending to be sine.

## 2. Types (all in `src/c03/types.bend`)

| Type | Fields | Meaning |
|---|---|---|
| `Dom` | `lo, hi` | finite open interval, `lo < hi` |
| `Pdom` | `d, periodic` | domain + seam identification (§4) |
| `Line3` | `p: Point, d: Dir` | point + nonzero direction |
| `Plane3` | `o, u, v` | origin + orthonormal in-plane basis |
| `Circle3` | `c, u, v, r` | center + orthonormal frame + radius |
| `Bez3` | `p0..p3` | cubic Bezier, `t` in `[0, 1]` |
| `RQBez` | `p0,p1,p2, w0,w1,w2` | conic arc, positive weights |
| `BezP` | `p00..p33` | bicubic patch, `(u,v)` in `[0,1]^2` |
| `Sphere/Cyl/Cone/Torus` | frame + radii/slope | implicit quadrics (§6) |
| `BBox3` | `lo, hi` | finite corners, `lo <= hi` |
| `TSeg/TBez` | 2/4 `Vec2` | trim in surface parameter space |
| `Nurb` | `ks, ps, ws` lists | cubic clamped NURBS (§7) |
| `K7/P4/W4/K4` | fixed windows | one de Boor step's data |
| `GVal/GRes` | 19-arm union / ok-or-`FailKind` | the one result type |

`GRes` projectors are total with documented defaults: `gres_f/p/d`
yield zero values off-arm, `gres_v2` yields `(0,0)`, `gres_dom`
yields the degenerate `[0,0]`, `gres_bb` the degenerate zero box;
`gres_kind` of `Gok` yields `F_invalid` BY DOCUMENTED CONVENTION
(mirroring C01 `cres_kind`); gate on `gres_ok`/`gres_show` first.

Semantic validity is ONE centralized layer (`types.bend`):
`dom_valid` (finite + `lo < hi`), `ln_valid` (finite + nonzero
direction), `cc_valid` (finite + positive radius),
`rq_valid` (finite points + three positive weights),
`sp_valid`/`cy_valid`/`co_valid`/`to_valid` (finite frame +
nonzero axis + positive radii/slope). Constructors AND every
evaluator consume them — a raw value that fails them is malformed
input (§3 step 2), never evaluated. Norm/frame checks
(orthonormality, unit axis) live in `ops.bend` and are conjoined
at each call site (C03.1 hardening).

## 3. Pipeline order (first match wins)

Every evaluator runs one total order (`ops.bend`; `*_go` matches
flags in parameter order):

1. Any input slot nonfinite → `invalid-input` (every slot of every
   entry path, like the C01 norm family and C02 predicates).
2. Malformed spec → `invalid-input`: degenerate domain (`lo >= hi`),
   zero direction, non-orthonormal frame, non-unit quadric axis,
   non-positive radius/weight/slope, bad NURBS
   (counts/knots/weights/clamp). The shape conjuncts are the
   centralized `*_valid` predicates (§2), enforced at constructor
   AND evaluator entries alike — raw bypasses fail here (C03.1).
3. Parameter outside the admitted domain → `invalid-input`
   (`[0,1]` for Beziers, `[-1,1]` for circles, the knot domain
   `[k3, k_{nk-4}]` for NURBS). Out-of-domain is malformed CALLER
   input, never silently clamped — except `dom_clamp`/`pdom_wrap`,
   whose clamping/wrapping IS the documented operation.
4. NURBS fuel exhausted → `resource-exhausted` (explicit, §7).
5. Computed result nonfinite from finite inputs → TRUE overflow →
   `numerical-uncertainty`, never a wrapped or infinite value.
6. Else publish the finite value.

Degenerate geometry that is still well-defined publishes: a Bezier
with coincident controls is a point, a zero-length trim segment is a
point, a whole-circle enclosure is coarse but certified. Coincident
projection (sphere center) is `invalid-input`, like C01 `seg_dir`.

## 4. Domains, seams, periodicity, poles

`mk_dom` requires finite ends with `lo < hi` strictly.
`dom_mid`/`dom_len`/`dom_clamp`/`dom_split_lo/hi`/`pdom_wrap`
all consume `dom_valid` (degenerate/reversed domains →
`invalid-input` at every domain entry, C03.1); overflow of a
VALID domain still → uncertainty. `dom_split_lo/hi` require `t`
strictly inside. `pdom_wrap` is
SINGLE-STEP by contract: one span add/subtract across the seam, clamp
when non-periodic. Multi-turn reduction is a stated follow-up (it
needs the §1 range-reduction policy, not an ad-hoc fmod).
A degenerate domain (`lo >= hi`) is `invalid-input` here as on
every entry path (fixed 2026-09-25: it previously published
`+-inf`); for valid domains the single step provably cannot
overflow (`t+span < hi`, `t-span > lo`, both finite).

Circle seams: `t = +1` and `t = -1` both evaluate to `c - r*u`,
bitwise-equal on the validated path (measured:
`circ-t1 == circ-tn1 == circ-seam_pt`; ordered equality is the
promise, bitwise is the observation). The seam is an ordinary
evaluated point, never a guessed branch.

Sphere poles are explicit degenerate representations per MASTER_PLAN
C04's rule: `sph_pole_n/s` take an explicit unit axis and return
`c +- r*a`; there is no pole hidden in a parametrization because
spheres here are implicit (no UV singularity exists to mishandle).
NURBS end multiplicity (quadruple clamped knots) is the knot-level
analogue of a seam: evaluation at the ends is exact endpoint
interpolation, pinned by the de Boor construction.

## 5. Curves: formulas and summation order

Summation order is part of the contract (as in C01/C02).
Reordering needs a contract amendment and re-pinning.

- Line: `P(t) = p + t*d` per component; every line entry
  consumes `ln_valid` (raw zero directions → `invalid-input`,
  C03.1). `line_project` divides by `d.d`: zero direction fails
  at the validity gate, while `d.d == 0` past it is subnormal
  underflow → `numerical-uncertainty` (never misattributed as
  malformed input); `line_dist` takes the scaled-hypot norm
  of the residual (C01 formula, no spurious overflow) with the
  same two arms.
- Circle (rational full turn, `D = (1+t^2)^2`):
  `nx = (1-6t^2+t^4)/D`, `ny = 4t(1-t^2)/D`,
  `C = c + r*nx*u + r*ny*v`; derivative by exact quotient rule on
  the quartics (`N1' = -12t+4t^3`, `N2' = 4-12t^2`,
  `D' = 4t+4t^3`). Assembly order: inner `c + (r*nx)*u`, then
  `+ (r*ny)*v`. An earlier stereographic draft covered only half
  the circle; the quartic map was verified against an independent
  python oracle (unit deviation ≤ 9e-16 over 2000 samples,
  derivative vs finite differences to 1e-8) before landing.
- Cubic Bezier: Bernstein basis
  `B = ((1-t)^3, 3(1-t)^2 t, 3(1-t)t^2, t^3)` with the exact
  multiplications in `bez3_eval_go`; weighted sum per component as
  a LEFT FOLD `((b0*x0+b1*x1)+b2*x2)+b3*x3`. Derivative is the
  exact quadratic over `3(p_{i+1}-p_i)`. Subdivision is de Casteljau
  with the ONE lerp formula `a*s+b*t`, `s = 1-t` (`flerp_raw`),
  shared by every split/lerp in the packet.
- Conic arc: `N = ΣwB p`, `D = ΣwB` (quadratic Bernstein, left
  folds), `C = N/D`; `D > 0` always (positive weights, `B >= 0`,
  `ΣB = 1`), with positivity enforced by `rq_valid` at every
  conic entry — eval, derivative, bbox, discriminant (C03.1).
  Derivative is the exact quotient rule
  `(N'D-ND')/D^2` with `wq_der_raw`. Discriminant
  `w1^2-w0*w2`: negative ellipse, zero parabola, positive
  hyperbola branch (stated standard classification).
- Rational quarter circle (`rq_quarter`): controls
  `c+r*u`, `c+r*u+r*v`, `c+r*v`, weights `(1, √2/2, 1)` with the
  bit-pinned `w_quarter()`. Midpoint lands 1 ulp from correctly
  rounded √2 (measured bits `4609047870845172684`; the input
  weight is itself the rounded √2/2, so exact √2 output is not
  promised — the §10 bound is).

NURBS evaluation is §7. There is no NURBS derivative yet
(limitation §14); all other families publish exact derivatives.

## 6. Surfaces: planes, quadrics, patches, trims

- Plane: `P(s,t) = o + s*u + t*v`, association
  `o+(s*u)+(t*v)` per component. Projection solves
  `s = m.u, t = m.v` (orthonormal frame, no divide); distance is
  `m.(u×v)`. The uv-rectangle enclosure evaluates the four
  corners (exact: evaluation is affine in `(s,t)`).
- Quadrics (unit axis enforced by `*_checked`, positive radii/slope
  enforced by `sp_valid`/`cy_valid`/`co_valid`/`to_valid` at
  EVERY quadric entry — value, gradient, projection, poles, nappe
  coordinate, and `*_checked` itself, C03.1; `m = q-o`):
  - sphere: `m.m-r^2`, gradient `2m`;
  - cylinder: `(m.m-ax^2)-r^2`, gradient `2(m-ax*a)`;
  - cone: `(m.m-ax^2)-k^2*ax^2`, gradient
    `2(m-ax*a)-2k^2*ax*a`; the implicit equation is the DOUBLE
    cone, one nappe is the `cone_ax >= 0` side condition;
  - torus: `(d2-S)^2-4R^2(r^2-ax^2)` with `d2 = m.m`,
    `S = R^2+r^2`, gradient `4(d2-S)m+8R^2*ax*a`.
  All dot products are C01 left folds; all results re-validated.
- Sphere projection is the SCALED form `c + r*u` with
  `u = (m/M)/(n/M)`, `M = max|m_i|` (C03.1; `sph_proj_q_raw`).
  The scalar `r/n` is never formed: it underflows to zero when
  `r << n` (`r/n <= 2^-1075` — the exact halfway value rounds to
  zero under IEEE ties-to-even — e.g. `r` near DBL_MIN at a
  far-field query), collapsing `(r/n)*m` onto the published
  center; even at
  `r=1, m=(DBL_MAX,0,0)` the old spelling lost 1 ulp. `n/M` lies
  in `[1, sqrt(3)]` and `m/M` in `[-1,1]`, so the unit direction
  survives every finite scale; a nonfinite norm still →
  uncertainty, coincidence still → invalid. This re-pins the
  `(3,4,0)` case by 1 ulp in x (correctly-rounded 0.6 — the new
  spelling is also the more accurate one).
- Bicubic patch: tensor Bernstein — four row cubics in `u`
  (`pt_cubic_raw`), then one column cubic in `v`. `bezp_du` is
  the column cubic of row-derivatives; `bezp_dv` the
  cubic-derivative of row-evals. Iso-curves are EXACT cubic
  Beziers (row/column evals as controls). Corners evaluate
  exactly (`p00` at `(0,0)`, `p33` at `(1,1)` — `1*x = x`,
  `x+0 = x`).
- Trims: `TSeg`/`TBez` evaluate in `(u,v)` with the same
  Bernstein/lerp formulas as their 3D siblings; `plane_trim_pt`
  composes a trim point through `plane_eval`. Other surface
  compositions arrive with C07/C08; the parameter-space
  representation is fixed now and never retrofitted.

## 7. NURBS: validation, span, de Boor, fuel

Admitted: CUBIC CLAMPED non-periodic NURBS only. Degree is fixed
at 3; periodic NURBS are a stated follow-up (they need the §1
wrap policy at the knot level).

Validation (`nok_c`, also behind `nurbs_checked` echo):
knot/point/weight counts `nk = nc+4`, `nw = nc`, `nc >= 4`;
every knot finite; knots nondecreasing (exact ordered `<=`,
multiplicity allowed and normal); every weight finite and
strictly positive; every control point finite; first and last
four knots exactly equal (clamped). Any violation →
`invalid-input`.

Evaluation (`nurbs_eval`): validate, then find the span (last
index with `k <= t`, clamped into `[3, nk-5]` — the window
`k[s-2..s+4]` needs `s+4 <= nk-1`; an earlier `nk-4` clamp
overran by one at `t = khi` and was fixed 2026-09-25), extract the
7-knot / 4-point / 4-weight window in one fuel-bounded pass per
list, run fixed cubic de Boor in homogeneous coordinates
(`deboor_raw`: 3+2+1 lerps with `alpha = (t-k_j)/(k_hi-k_j)`),
divide. `t` outside `[k3, k_{nk-4}]` → `invalid-input`.

Fuel (BN-8): every list walk takes a `Nat` fuel, consumes one
per element, and reports a packed code `ok + 2*done`. Callers
check `done` FIRST: exhaustion → `resource-exhausted`, and the
`ok`/span/window values are unread. `span_at` takes NO done flag
of its own; every call site runs it over the SAME knot list with
the SAME fuel as `kfin_c`/`knondec_c` and reads the span only
when those walks report done — same list + same fuel implies the
span walk consumed one fuel per element exactly like the fin walk, so
fin-done implies span-complete (stated invariant, load-bearing;
keep the list AND the fuel shared at every call site; classified
§11 BN-10: shared-fuel argument, stated). Drops are
structural in `(list, n)` and need no fuel; takes are fixed
7/4-deep matches with zero fill — and zero fill is UNREACHABLE
under valid counts (span clamp implies fit), so it is a
totality default, never a published guess.

Repeated-knot convention: `alpha` uses `0/0 := 0` on an
exact-zero denominator (standard de Boor/NURBS convention,
stated — the same convention every NURBS implementation uses
at full-multiplicity knots).

## 8. Identity (BN-7)

Curve/surface/trim identity is CONTENT: the validated
spec (frame components, control points, knot vector, weights,
domain ends). There are no ordinals, no heap addresses, no
indices-into-a-model anywhere in `src/c03`. List positions
inside a `Nurb` are structural places in an immutable value
(the de Boor window slides over content), not persistent
references; generational topology handles arrive in C04 and
will wrap these contents, never replace them.

## 9. Failure arms (C00 statuses reused, no new taxonomy)

`invalid-input`: nonfinite in any slot of any entry; degenerate
domain; out-of-domain parameter; zero direction; non-orthonormal
frame or non-unit axis (malformed SPEC); non-positive
radius/weight/slope; bad NURBS (counts, knots, weights, clamp);
coincident sphere projection. The shape conjuncts are enforced
at evaluator entries, not just constructors (§2 centralized
`*_valid` layer, C03.1). `numerical-uncertainty`: true
overflow — a nonfinite result computed from finite inputs
(re-validation at every publishing arm), including a far-field
sphere projection whose `|q-c|` overflows (fixed 2026-09-25:
it previously published the center) and subnormal `d.d`
underflow in `line_project`/`line_dist` (C03.1: a valid nonzero
direction whose parameter is uncomputable). Whenever the scaled
projection's norm is finite it publishes the surface point —
never the center (C03.1). `resource-exhausted`:
NURBS fuel ran out (walks + span). `unsupported-op`,
`nonconvergence` (still reserved — no iterative solver until
C05), `cancelled`, and `Incomplete` have no C03 trigger: C03
ops are pure functions; the C00 pipeline keeps dispatch, fuel
threading at the request level, and cancellation. Every failure
arm publishes nothing: error projectors yield documented
defaults, never NaN (BN-11; sibling `neg-*` + `neg-bn11-*`
pins).

## 10. Enclosures and bounds (all certified or stated)

- Bezier/Bezier-patch/rational hulls: Bernstein basis is
  nonnegative with unit sum on the domain (polynomial/rational
  with positive weights), so the control hull CONTAINS the
  curve/patch — certified enclosure, coarse by design. Same
  certificate for trim hulls and the plane uv-rectangle (affine
  exactness at corners).
- Whole-circle box: `nx^2+ny^2 = 1` in exact arithmetic, so
  `|nx|,|ny| <= 1` and `c +- r*(|u|+|v|)` contains `C(t)` —
  certified, coarse (arceconomy is a follow-up).
- Evaluation accuracy (normal range, stated + oracle-pinned,
  never relabeled as proven): Bernstein/de Boor evals carry
  relative error ≤ ~10 ulp absent cancellation (each output is
  O(10) roundings deep); the quarter-circle midpoint sits 1 ulp
  from correctly-rounded √2 with `r^2` deviation 9e-16
  (measured §5); circle unit deviation ≤ 9e-16 over 2000
  samples (measured §5). Cancellation (near-coincident
  controls, high-multiplicity knots) loosens relative bounds
  to absolute ones — reported, not hidden.
- Thresholds inherited from C01, unchanged: frame unit/ortho
  `1e-12` (`V.th_unit`), axis unit `1e-12`. No new epsilon.

## 11. Bend-native gates (BN-1..BN-12)

| Gate | Verdict | Evidence |
|------|---------|----------|
| BN-1 | PASS | Packet implementation is exactly `src/c03/types.bend` + `src/c03/ops.bend`; both check (`bend … --check-only` → `All terms check.`). No authoritative algorithm in another language. |
| BN-2 | PASS | `grep -rn '@unsafe' src/c03` is empty (verified this session); no `@unsafe` in file, no law without proof in `src/` (laws live in `laws/`, sibling packet). |
| BN-3 | PASS | `grep -rn 'F32\|f32' src/c03` is empty; every scalar is the pinned as-bits F64 path (`F64{bits}`/`1.0f64` literals only). No display narrowing exists in this packet. |
| BN-4 | PASS | No foreign/FFI call: the only imports are `Base`, `../c00/types.bend`, `../c01/types.bend`, `./types.bend`. Boundary list: none. |
| BN-5 | PASS | No OCCT/FreeCAD/PlaneGCS reference in `src/c03` (grep empty); `legacy/` untouched (`git status` clean for `legacy/`). No oracle harness in this packet. |
| BN-6 | PASS | No GPU claim in this packet — hence no GPU path to fall back from. All evaluation is host F64; device execution is never asserted. |
| BN-7 | PASS | §8: content identity only; no ordinals/addresses/indices-as-identity. `Nurb` lists are immutable content; windows slide structurally. |
| BN-8 | PASS | All recursion is structural (list tail / `Nat` predecessor) AND fuel-capped where input-sized: NURBS walks take `Nat` fuel, exhaustion → explicit `resource-exhausted` (`nurbs_eval` fuel-0 pin). No unbounded recursion. |
| BN-9 | PASS | No expensive batch op executes in this packet (single-point evals, one de Boor step per call); the parallel decomposition is specified for the batch layer (§12) and needs no code here. |
| BN-10 | PASS | Every shortcut classified: hull/circle enclosures = certified bounds (§10); Bernstein/de Boor/quotient formulas = exact identities, oracle-pinned bitwise (§5, smoke §13); `0/0 := 0` at repeated knots = stated standard convention (§7); shared-fuel span `done` = stated argument (§7); wrap single-step overflow-freedom on valid domains = stated arithmetic argument (§4); span clamp `nk-5` window-fit = stated index argument (§7, fixed 2026-09-25 with `nev_t1` + `neg-wrap-degen*` + `neg-sph-far` pins); scaled projection (`n/M` in `[1,sqrt(3)]`, `m/M` in `[-1,1]`) = stated arithmetic argument (§6, C03.1 with `sphp_faraxis/minr/farctr/mixed` pins); thresholds inherited from C01 = stated + pin-tested (§10); trig ABSENT by policy (§1). No unlabeled shortcut. |
| BN-11 | PASS | Every `Gerr` arm returns no value: projectors yield documented zero/default values (§2); sibling `neg-*`/`neg-bn11-*` assert kinds + defaults, `fails=0`. |
| BN-12 | PASS | Packet verified at BendCAD HEAD `0f41d98a` + untracked `src/c03/` (this session; re-hash at commit), `BEND_PIN jnadeau207-collab/bend@50ec219a6b5c52316f4d1622816cceedd437fa95`, `~/.bend/FORK` tag `numeric/2026-09-25`, `bend` = `~/.bend/bin/bend` (Bend 2.0.27, fork build). Toolchain env: `PATH=$HOME/.bend/bin:$HOME/.bun/bin:$PATH`, `BEND_NO_TELEMETRY=1`. |

Gate count: 12 (BN-1 through BN-12).

## 12. Parallel decomposition notes (BN-9)

This packet executes single-point evaluations only, so no batch
code ships. The batch layer (later packets, same formulas) decomposes
as: (a) NURBS multi-point evaluation partitions by knot span —
spans are independent once windows are extracted, one owned window
per task, deterministic left-to-right result assembly; (b) Bezier
subdivision forms a deterministic binary tree (de Casteljau halves
are independent); (c) patch grids partition by `(u,v)` tiles with
owned output ranges; (d) enclosure/validation walks are
single-pass folds, parallelized by segmented reduction only if
lists ever grow large (they are small today). No shared mutable
state, no atomics, no GPU claim until the device gate closes.

## 13. Verification

```sh
export PATH=$HOME/.bend/bin:$HOME/.bun/bin:$PATH; export BEND_NO_TELEMETRY=1
bend src/c03/types.bend --check-only  # All terms check.
bend src/c03/ops.bend --check-only    # All terms check.
bend laws/c03.bend --check-only       # All terms check (sibling).
bend tests/c03/check.bend --check-only
bend tests/c03/neg.bend               # selfcheck fails=0 (sibling)
bend tests/c03/pos.bend               # selfcheck fails=0 (sibling)
grep -rn '@unsafe' src/c03            # no matches
grep -rn 'F32\|f32' src/c03           # no matches
```

Independent oracle: python `struct`/IEEE-754 emulation of the exact
contract formulas. Bitwise matches observed this session:
`bez3_eval` midpoint, `rqb_eval` quarter midpoint
(`4609047870845172684`), `rqb_disc` (`13826050856027422718`),
circle seam triple equality, NURBS single-span = Bernstein
midpoint, patch corners. A half-circle stereographic draft was
caught by this oracle and replaced with the quartic map (§5).

## 14. Limitations (honest scope, not placeholders)

- Cubic clamped non-periodic NURBS only; no NURBS derivative, no
  knot insertion/refinement, no periodic NURBS, no NURBS surfaces
  (tensor NURBS patches are a C07 follow-up; Bezier
  patches cover surfaces now).
- No transcendental evaluation at all (§1 policy reserves it);
  single-step periodic wrap only.
- No general projection (closest point) except line/plane/sphere
  closed forms; no curve/curve or curve/surface intersection
  (C07 owns both).
- Enclosures are coarse-but-certified (whole-circle box, control
  hulls); arc-tight boxes and Bernstein-subdivision enclosures
  are follow-ups.
- §10 ulp bounds are stated + pin-tested, not machine-proved.
- Trim composition exists for planes only; other surfaces in
  C07/C08.

## 15. Explicit general laws (for `laws/c03.bend`)

Bend rejects open laws, so sibling `laws/c03.bend` proves every
claim it states; the unbounded claims live here explicitly:

- G1 (entry boundary): nonfinite in any slot of any entry fails
  as `invalid-input`. Grounded: per-type `mk_*`/`*_fin` instances
  + sibling `neg-*-nan` checks.
- G2 (domain honesty): out-of-domain parameters fail, never clamp
  silently (except `dom_clamp`/`pdom_wrap`, whose clamping is the
  spec). Grounded: `bez-bad`, `circ-bad`, `neval-lo` pins.
- G3 (seam identity): `circ_eval(cc,1) == circ_eval(cc,-1) ==
  circ_seam_pt(cc)` (ordered equality; bitwise observed).
- G4 (rational circle/conic exactness): published circle points
  satisfy `nx^2+ny^2 = 1` to §10 bounds; the quarter midpoint is
  the pinned 1-ulp point; `rqb_disc` signs the supporting conic.
- G5 (derivative identities): line/circle/Bezier/conic/patch
  derivatives are the exact formulas of §5–§6 (pinned at
  endpoints/midpoints; NURBS excluded per §14).
- G6 (enclosure soundness): every published `BBox3` contains the
  evaluated set (§10 certificates).
- G7 (NURBS totality): valid inputs always evaluate (single-span
  NURBS = Bernstein on the nose); invalid inputs fail by §3
  order; short fuel fails as `resource-exhausted`, never a guess.
- G8 (non-publishing failure): every `Gerr` arm carries no value
  (projector defaults, §2/§9; sibling `neg-bn11-*`).
- G9 (evaluator-boundary validity, C03.1): raw malformed values
  fail at evaluator entries, never evaluated (centralized
  `*_valid` layer, §2). Grounded: `val_*` + `neg-g8` pins per
  entry family, `sphp_faraxis/minr/farctr/mixed` for the scaled
  projection, `lproj/ldist_tiny_unc` for the subnormal arm.
