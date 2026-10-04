# C06 builders: solid ops over C00-C05. Total spec builders fail
# closed through brep_checked (stage-attributed diagnosis) and the
# C06 quad-trim check. Intent comparison is the evaluator's publish
# (eval.bend), not this file. Validators: profile/topology up front
# (invalid-input); representability at the gates (uncertain, never
# snapped).
# Contract: docs/c06-contract.md. Style: linear aggregate flow (each
# computed aggregate used once or threaded via _go params); scalars
# dup freely; every recursive walk takes Nat fuel.

import Base
import ../c00/types.bend as T
import ../c00/eval.bend as E0
import ../c01/types.bend as V
import ../c01/ops.bend as C1
import ../c02/types.bend as P
import ../c02/ops.bend as P2
import ../c03/types.bend as G
import ../c03/ops.bend as G3
import ../c04/types.bend as Ty
import ../c04/ops.bend as B4
import ../base/par.bend as B
import ../base/ex.bend as E
import ./types.bend as Y
import ./surfx.bend as SX

# --- Small list helpers (all fuel-bounded walks). ---
def v2_nth_go(xs: List<&2, V.Vec2>, i: Nat, m: Nat) -> V.Vec2:
  match xs:
    case Nil{}: V.V2{0.0f64, 0.0f64}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: v2_nth_go(t, j, m)

def v2_nth(xs: List<&2, V.Vec2>, i: Nat, fuel: Nat) -> V.Vec2:
  match fuel:
    case 0n: V.V2{0.0f64, 0.0f64}
    case 1n+m: v2_nth_go(xs, i, m)

def f_nth_go(xs: List<&2, F64>, i: Nat, m: Nat) -> F64:
  match xs:
    case Nil{}: 0.0f64
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: f_nth_go(t, j, m)

def f_nth(xs: List<&2, F64>, i: Nat, fuel: Nat) -> F64:
  match fuel:
    case 0n: 0.0f64
    case 1n+m: f_nth_go(xs, i, m)

def map_add_go(xs: List<&2, Nat>, +off: Nat, m: Nat) -> List<&2, Nat>:
  match xs:
    case Nil{}: []
    case h <> t: Nat.add(h, off) <> map_add_go(t, off, m)

def map_add(xs: List<&2, Nat>, off: Nat, fuel: Nat) -> List<&2, Nat>:
  match fuel:
    case 0n: xs
    case 1n+m: map_add_go(xs, off, m)

def iv_nth_go(xs: List<&2, Y.Iv>, i: Nat, m: Nat) -> Y.Iv:
  match xs:
    case Nil{}: Y.Iv{0.0f64, 0.0f64}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: iv_nth_go(t, j, m)

def iv_nth(xs: List<&2, Y.Iv>, i: Nat, fuel: Nat) -> Y.Iv:
  match fuel:
    case 0n: Y.Iv{0.0f64, 0.0f64}
    case 1n+m: iv_nth_go(xs, i, m)

# --- Total GVal projector: GV_f{0} default fails every downstream
# class check (curve/surf/trim) loudly at stage A. ---
def gval_def(r: G.GRes) -> G.GVal:
  match r:
    case G.Gok{v}: v
    case G.Gerr{kind}: G.GV_f{0.0f64}

# --- Outward rounding via bit successors. NaN passes through
# (callers gate finiteness); infinities saturate. ---
def fnu_sg(+b: U64, neg: Bool) -> F64:
  match neg:
    case True{}: F64{(b - 1u64 : U64)}
    case False{}: F64{(b + 1u64 : U64)}

def fnu_nz(+b: U64, nzero: Bool, neg: Bool) -> F64:
  match nzero:
    case True{}: F64{1u64}
    case False{}: fnu_sg(b, neg)

def fnu_pi(+b: U64, pinf: Bool, nzero: Bool, neg: Bool) -> F64:
  match pinf:
    case True{}: F64{b}
    case False{}: fnu_nz(b, nzero, neg)

def fnu_go(+b: U64, nan: Bool, pinf: Bool, nzero: Bool,
    neg: Bool) -> F64:
  match nan:
    case True{}: F64{b}
    case False{}: fnu_pi(b, pinf, nzero, neg)

def f64_next_up(+x: F64) -> F64:
  +b = F64.bits(x)
  fnu_go(b, F64.is_nan(x),
    U64.is_eq(b, 9218868437227405312u64),
    U64.is_eq(b, 9223372036854775808u64),
    U64.is_le(9223372036854775808u64, b))

def fnd_sg(+b: U64, neg: Bool) -> F64:
  match neg:
    case True{}: F64{(b + 1u64 : U64)}
    case False{}: F64{(b - 1u64 : U64)}

def fnd_pz(+b: U64, pzero: Bool, neg: Bool) -> F64:
  match pzero:
    case True{}: F64{9223372036854775809u64}
    case False{}: fnd_sg(b, neg)

def fnd_ni(+b: U64, ninf: Bool, pzero: Bool, neg: Bool) -> F64:
  match ninf:
    case True{}: F64{b}
    case False{}: fnd_pz(b, pzero, neg)

def fnd_go(+b: U64, nan: Bool, ninf: Bool, pzero: Bool,
    neg: Bool) -> F64:
  match nan:
    case True{}: F64{b}
    case False{}: fnd_ni(b, ninf, pzero, neg)

def f64_next_down(+x: F64) -> F64:
  +b = F64.bits(x)
  fnd_go(b, F64.is_nan(x),
    U64.is_eq(b, 18442240474082181120u64),
    U64.is_eq(b, 0u64),
    U64.is_le(9223372036854775808u64, b))

# --- Certified interval arithmetic. Each op rounds outward one ulp
# past the correctly-rounded F64 result, so the interval encloses
# the true real value. Nonfinite enclosure fails as uncertain. ---
def iv_gate2(ok: Bool, +lo: F64, +hi: F64) -> Y.SRes:
  match ok:
    case True{}: Y.sok_iv(Y.Iv{lo, hi})
    case False{}:
      Y.serr_uncertain("interval enclosure", "iv",
        "nonfinite-enclosure", "shrink the zone")

def iv_gate(+lo: F64, +hi: F64) -> Y.SRes:
  iv_gate2(Bool.and(T.is_finite(lo),
      Bool.and(T.is_finite(hi), F64.is_le(lo, hi))),
    lo, hi)

def iv_add(a: Y.Iv, b: Y.Iv) -> Y.SRes:
  Y.Iv{+alo, +ahi} = a
  Y.Iv{+blo, +bhi} = b
  iv_gate(f64_next_down(F64.add(alo, blo)),
    f64_next_up(F64.add(ahi, bhi)))

def iv_sub(a: Y.Iv, b: Y.Iv) -> Y.SRes:
  Y.Iv{+alo, +ahi} = a
  Y.Iv{+blo, +bhi} = b
  iv_gate(f64_next_down(F64.sub(alo, bhi)),
    f64_next_up(F64.sub(ahi, blo)))

def iv_mul4_go(+p1: F64, +p2: F64, +p3: F64, +p4: F64) -> Y.SRes:
  +l1 = Bool.pick(F64, F64.is_lt(p1, p2), p1, p2)
  +l2 = Bool.pick(F64, F64.is_lt(p3, p4), p3, p4)
  +h1 = Bool.pick(F64, F64.is_lt(p1, p2), p2, p1)
  +h2 = Bool.pick(F64, F64.is_lt(p3, p4), p4, p3)
  +lo = Bool.pick(F64, F64.is_lt(l1, l2), l1, l2)
  +hi = Bool.pick(F64, F64.is_lt(h1, h2), h2, h1)
  iv_gate(f64_next_down(lo), f64_next_up(hi))

def iv_mul(a: Y.Iv, b: Y.Iv) -> Y.SRes:
  Y.Iv{+alo, +ahi} = a
  Y.Iv{+blo, +bhi} = b
  iv_mul4_go(F64.mul(alo, blo), F64.mul(alo, bhi),
    F64.mul(ahi, blo), F64.mul(ahi, bhi))

def iv_div_go(zero: Bool, +alo: F64, +ahi: F64, +blo: F64,
    +bhi: F64) -> Y.SRes:
  match zero:
    case True{}:
      Y.serr_uncertain("interval division", "iv",
        "divisor-contains-zero", "split the zone")
    case False{}:
      iv_mul4_go(F64.div(alo, blo), F64.div(alo, bhi),
        F64.div(ahi, blo), F64.div(ahi, bhi))

def iv_div(a: Y.Iv, b: Y.Iv) -> Y.SRes:
  Y.Iv{+alo, +ahi} = a
  Y.Iv{+blo, +bhi} = b
  iv_div_go(Bool.and(F64.is_le(blo, 0.0f64),
      F64.is_le(0.0f64, bhi)),
    alo, ahi, blo, bhi)

def iv_neg(a: Y.Iv) -> Y.Iv:
  Y.Iv{+lo, +hi} = a
  Y.Iv{F64.neg(hi), F64.neg(lo)}

def iv_sq_hp(hi_pos: Bool, +lo: F64, +hi: F64) -> Y.SRes:
  match hi_pos:
    case False{}:
      iv_gate(f64_next_down(F64.mul(hi, hi)),
        f64_next_up(F64.mul(lo, lo)))
    case True{}:
      +m = Bool.pick(F64, F64.is_lt(F64.neg(lo), hi), hi,
        F64.neg(lo))
      iv_gate(0.0f64, f64_next_up(F64.mul(m, m)))

def iv_sq_go(lo_neg: Bool, hi_pos: Bool, +lo: F64,
    +hi: F64) -> Y.SRes:
  match lo_neg:
    case False{}:
      iv_gate(f64_next_down(F64.mul(lo, lo)),
        f64_next_up(F64.mul(hi, hi)))
    case True{}: iv_sq_hp(hi_pos, lo, hi)

def iv_sq(a: Y.Iv) -> Y.SRes:
  Y.Iv{+lo, +hi} = a
  iv_sq_go(F64.is_lt(lo, 0.0f64), F64.is_lt(0.0f64, hi),
    lo, hi)

def iv_sqrt_go(neg: Bool, +lo: F64, +hi: F64) -> Y.SRes:
  match neg:
    case True{}:
      Y.serr_invalid("interval sqrt", "iv", "sqrt-negative",
        "clamp the zone at zero")
    case False{}:
      iv_gate(f64_next_down(F64.sqrt(lo)),
        f64_next_up(F64.sqrt(hi)))

def iv_sqrt(a: Y.Iv) -> Y.SRes:
  Y.Iv{+lo, +hi} = a
  iv_sqrt_go(F64.is_lt(lo, 0.0f64), lo, hi)

def iv_pt(+x: F64) -> Y.Iv:
  Y.Iv{x, x}

# Certified pi enclosure: correctly-rounded pi lies strictly
# between, so [pred, succ] encloses true pi (verified in python;
# oracle re-verifies from Decimal).
def pi_iv() -> Y.Iv:
  Y.Iv{F64{4614256656552045847u64},
    F64{4614256656552045849u64}}

# --- Profile validation codes. 0 ok; 1 short; 2 nonfinite;
# 3 repeated-point; 4 zero-area; 5 winding; 6 self-crossing;
# 7 self-touch; 8 spike; 9 hole-outside; 10 loop-touch;
# 11 loop-crossing; 12 hole-nesting; 13 predicate-uncertain;
# 14 axis-crossing; 15 axis-pinch; 16 hole-axis-touch;
# 17 fuel-out; 18 profile-too-large. First-nonzero wins. ---
def pick_nz(+a: U64, b: U64) -> U64:
  Bool.pick(U64, U64.is_eq(a, 0u64), b, a)

def sh_term(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> E.Ex:
  E.ex_sub(E.ex_mul(E.ex_of(ax), E.ex_of(by)),
    E.ex_mul(E.ex_of(bx), E.ex_of(ay)))

def sh_go(xs: List<&2, V.Vec2>, +x0: F64, +y0: F64, +px: F64,
    +py: F64, acc: E.Ex, fuel: Nat) -> E.Ex:
  match xs:
    case Nil{}:
      E.ex_add(acc, sh_term(px, py, x0, y0))
    case +h <> t:
      match fuel:
        case 0n: acc
        case 1n+m:
          sh_go(t, x0, y0, V.v2_x(h), V.v2_y(h),
            E.ex_add(acc, sh_term(px, py, V.v2_x(h),
              V.v2_y(h))),
            m)

def sh_ex(xs: List<&2, V.Vec2>, fuel: Nat) -> E.Ex:
  match xs:
    case Nil{}: E.ex_zero()
    case +h <> t:
      sh_go(t, V.v2_x(h), V.v2_y(h), V.v2_x(h), V.v2_y(h),
        E.ex_zero(), fuel)

def sh_sgn(s: B.Sgn) -> U64:
  match s:
    case B.Sp{}: 1u64
    case B.Sn{}: 2u64
    case B.Sz{}: 0u64
    case B.Su{}: 3u64

def sh_sign(xs: List<&2, V.Vec2>, fuel: Nat) -> U64:
  sh_sgn(E.ex_sign(sh_ex(xs, fuel)))

def sh_map_outer(s: U64) -> U64:
  match s:
    case 0u64: 4u64
    case 1u64: 0u64
    case 2u64: 5u64
    case 3u64: 13u64
    case _: 17u64

def sh_map_hole(s: U64) -> U64:
  match s:
    case 0u64: 4u64
    case 1u64: 5u64
    case 2u64: 0u64
    case 3u64: 13u64
    case _: 17u64

def fin_go(xs: List<&2, V.Vec2>, fuel: Nat) -> U64:
  match xs:
    case Nil{}: 0u64
    case h <> t:
      match fuel:
        case 0n: 17u64
        case 1n+m:
          pick_nz(Bool.pick(U64, V.v2_fin(h), 0u64, 2u64),
            fin_go(t, m))

def fin_code(xs: List<&2, V.Vec2>, fuel: Nat) -> U64:
  fin_go(xs, fuel)

def dist_go(xs: List<&2, V.Vec2>, +fx: F64, +fy: F64, +px: F64,
    +py: F64, fuel: Nat) -> U64:
  match xs:
    case Nil{}:
      Bool.pick(U64, Bool.and(F64.is_eq(px, fx),
        F64.is_eq(py, fy)), 3u64, 0u64)
    case +h <> t:
      match fuel:
        case 0n: 17u64
        case 1n+m:
          pick_nz(Bool.pick(U64, Bool.and(F64.is_eq(px,
            V.v2_x(h)), F64.is_eq(py, V.v2_y(h))), 3u64, 0u64),
            dist_go(t, fx, fy, V.v2_x(h), V.v2_y(h), m))

def dist_code(xs: List<&2, V.Vec2>, fuel: Nat) -> U64:
  match xs:
    case Nil{}: 0u64
    case +h <> t:
      dist_go(t, V.v2_x(h), V.v2_y(h), V.v2_x(h), V.v2_y(h),
        fuel)

# --- Simplicity: pairwise exact segment checks. Adjacent pairs
# admit touch (shared endpoint) but never overlap (spike). ---
def simp_rel(x: P.Xrel, adj: Bool) -> U64:
  match x:
    case P.X_disjoint{}: 0u64
    case P.X_proper{}: 6u64
    case P.X_overlap{}: Bool.pick(U64, adj, 8u64, 6u64)
    case P.X_touch{}: Bool.pick(U64, adj, 0u64, 7u64)

def simp_r(r: P.Xres, adj: Bool) -> U64:
  match r:
    case P.Xok{x}: simp_rel(x, adj)
    case P.Xerr{kind}: 13u64

def simp_j(+xs: List<&2, V.Vec2>, +i: Nat, k: Nat, +jlim: Nat,
    +n: Nat, fuel: Nat) -> U64:
  match k:
    case 0n: 0u64
    case 1n++p:
      match fuel:
        case 0n: 17u64
        case 1n++m:
          +ip1 = Bool.pick(Nat, Nat.is_eq(Nat.add(i, 1n), n),
            0n, Nat.add(i, 1n))
          +jp1 = Bool.pick(Nat, Nat.is_eq(Nat.add(p, 1n), n),
            0n, Nat.add(p, 1n))
          Bool.pick(U64, Nat.is_lt(p, jlim), 0u64,
            pick_nz(simp_r(P2.seg_seg(v2_nth(xs, i, m),
                v2_nth(xs, ip1, m), v2_nth(xs, p, m),
                v2_nth(xs, jp1, m)), False{}),
              simp_j(xs, i, p, jlim, n, m)))

def simp_i(+xs: List<&2, V.Vec2>, k: Nat, +n: Nat,
    fuel: Nat) -> U64:
  match k:
    case 0n: 0u64
    case 1n++p:
      match fuel:
        case 0n: 17u64
        case 1n++m:
          +p1 = Nat.add(p, 1n)
          +i2 = Bool.pick(Nat, Nat.is_eq(p1, n), 0n, p1)
          +i3 = Bool.pick(Nat, Nat.is_eq(Nat.add(i2, 1n), n),
            0n, Nat.add(i2, 1n))
          +is0 = Nat.is_eq(p, 0n)
          +ks = Bool.pick(Nat, is0, Nat.sub(n, 1n), n)
          +jlim = Bool.pick(Nat, is0, 2n, Nat.add(p, 2n))
          pick_nz(simp_r(P2.seg_seg(v2_nth(xs, p, m),
              v2_nth(xs, i2, m), v2_nth(xs, i2, m),
              v2_nth(xs, i3, m)), True{}),
            pick_nz(simp_j(xs, p, ks, jlim, n, m),
              simp_i(xs, p, n, m)))

def simp_loop(xs: List<&2, V.Vec2>, +n: Nat, fuel: Nat) -> U64:
  simp_i(xs, n, n, fuel)

# --- Loop-vs-loop separation: every pair disjoint. ---
def pr_rel(x: P.Xrel) -> U64:
  match x:
    case P.X_disjoint{}: 0u64
    case P.X_touch{}: 10u64
    case P.X_proper{}: 11u64
    case P.X_overlap{}: 11u64

def pr_r(r: P.Xres) -> U64:
  match r:
    case P.Xok{x}: pr_rel(x)
    case P.Xerr{kind}: 13u64

def pr_j(+xs: List<&2, V.Vec2>, +ys: List<&2, V.Vec2>, +i: Nat,
    k: Nat, +n: Nat, +m: Nat, fuel: Nat) -> U64:
  match k:
    case 0n: 0u64
    case 1n++p:
      match fuel:
        case 0n: 17u64
        case 1n++q:
          +ip1 = Bool.pick(Nat, Nat.is_eq(Nat.add(i, 1n), n),
            0n, Nat.add(i, 1n))
          +jp1 = Bool.pick(Nat, Nat.is_eq(Nat.add(p, 1n), m),
            0n, Nat.add(p, 1n))
          pick_nz(pr_r(P2.seg_seg(v2_nth(xs, i, q),
              v2_nth(xs, ip1, q), v2_nth(ys, p, q),
              v2_nth(ys, jp1, q))),
            pr_j(xs, ys, i, p, n, m, q))

def pr_i(+xs: List<&2, V.Vec2>, +ys: List<&2, V.Vec2>, k: Nat,
    +n: Nat, +m: Nat, fuel: Nat) -> U64:
  match k:
    case 0n: 0u64
    case 1n++p:
      match fuel:
        case 0n: 17u64
        case 1n++q:
          pick_nz(pr_j(xs, ys, p, m, n, m, q),
            pr_i(xs, ys, p, n, m, q))

def loop_pair_code(xs: List<&2, V.Vec2>, ys: List<&2, V.Vec2>,
    +n: Nat, +m: Nat, fuel: Nat) -> U64:
  pr_i(xs, ys, n, n, m, fuel)

# --- Point-in-polygon: exact ray casting. Per-edge codes
# (0 pass, 1 cross, 2 boundary, 3 uncertain), then a scalar fold:
# 0 outside, 1 inside, 2 boundary, 3 uncertain. ---
def edge_sg(s: P.Sign, straddle: Bool, upward: Bool,
    bbox: Bool) -> U64:
  match s:
    case P.Sg_zero{}: Bool.pick(U64, bbox, 2u64, 0u64)
    case P.Sg_pos{}:
      Bool.pick(U64, Bool.and(straddle, Bool.not(upward)),
        1u64, 0u64)
    case P.Sg_neg{}:
      Bool.pick(U64, Bool.and(straddle, upward), 1u64, 0u64)

def edge_gr(r: P.PRes, straddle: Bool, upward: Bool,
    bbox: Bool) -> U64:
  match r:
    case P.Pok{s}: edge_sg(s, straddle, upward, bbox)
    case P.Perr{kind}: 3u64

def xor2(+a: Bool, +b: Bool) -> Bool:
  Bool.or(Bool.and(a, Bool.not(b)), Bool.and(Bool.not(a), b))

def pip_edge(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64,
    +by: F64) -> U64:
  +strad = xor2(F64.is_lt(py, ay), F64.is_lt(py, by))
  +up = F64.is_lt(ay, by)
  +minx = Bool.pick(F64, F64.is_lt(ax, bx), ax, bx)
  +maxx = Bool.pick(F64, F64.is_lt(ax, bx), bx, ax)
  +miny = Bool.pick(F64, F64.is_lt(ay, by), ay, by)
  +maxy = Bool.pick(F64, F64.is_lt(ay, by), by, ay)
  +bbox = Bool.and(F64.is_le(minx, px),
    Bool.and(F64.is_le(px, maxx),
      Bool.and(F64.is_le(miny, py), F64.is_le(py, maxy))))
  edge_gr(P2.orient2d(V.V2{ax, ay}, V.V2{bx, by},
      V.V2{px, py}),
    strad, up, bbox)

def pip_go(+px: F64, +py: F64, xs: List<&2, V.Vec2>, +fx: F64,
    +fy: F64, +ax: F64, +ay: F64, fuel: Nat) -> List<&2, U64>:
  match xs:
    case Nil{}: [pip_edge(px, py, ax, ay, fx, fy)]
    case +h <> t:
      match fuel:
        case 0n: [3u64]
        case 1n+m:
          pip_edge(px, py, ax, ay, V.v2_x(h), V.v2_y(h)) <>
            pip_go(px, py, t, fx, fy, V.v2_x(h), V.v2_y(h),
              m)

def fold_go(cs: List<&2, U64>, +cnt: Nat, bnd: Bool, unc: Bool,
    fuel: Nat) -> U64:
  match cs:
    case Nil{}:
      Bool.pick(U64, unc, 3u64,
        Bool.pick(U64, bnd, 2u64,
          Bool.pick(U64, Nat.is_eq(Nat.mod(cnt, 2n), 1n),
            1u64, 0u64)))
    case +h <> t:
      match fuel:
        case 0n: 3u64
        case 1n+m:
          fold_go(t, Nat.add(cnt, Bool.pick(Nat,
              U64.is_eq(h, 1u64), 1n, 0n)),
            Bool.or(bnd, U64.is_eq(h, 2u64)),
            Bool.or(unc, U64.is_eq(h, 3u64)), m)

def fold_codes(cs: List<&2, U64>, fuel: Nat) -> U64:
  fold_go(cs, 0n, False{}, False{}, fuel)

def pip(+px: F64, +py: F64, xs: List<&2, V.Vec2>,
    +fuel: Nat) -> U64:
  match xs:
    case Nil{}: 0u64
    case +h <> t:
      fold_codes(pip_go(px, py, t, V.v2_x(h), V.v2_y(h),
          V.v2_x(h), V.v2_y(h), fuel),
        fuel)

def pip_map(c: U64) -> U64:
  match c:
    case 0u64: 9u64
    case 1u64: 0u64
    case 2u64: 10u64
    case 3u64: 13u64
    case _: 17u64

def nest_map(c: U64) -> U64:
  match c:
    case 0u64: 0u64
    case 1u64: 12u64
    case 2u64: 10u64
    case 3u64: 13u64
    case _: 17u64

def hole_in_go(hs: List<&2, V.Vec2>, +outer: List<&2, V.Vec2>,
    fuel: Nat) -> U64:
  match hs:
    case Nil{}: 0u64
    case +h <> t:
      match fuel:
        case 0n: 17u64
        case 1n++m:
          pick_nz(pip_map(pip(V.v2_x(h), V.v2_y(h), outer,
              m)),
            hole_in_go(t, outer, m))

def holes_len_go(hs: List<&2, List<&2, V.Vec2>>,
    fuel: Nat) -> Nat:
  match hs:
    case Nil{}: 0n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+m:
          Nat.add(List.length(&2, V.Vec2, h),
            holes_len_go(t, m))

def holes_len(hs: List<&2, List<&2, V.Vec2>>,
    fuel: Nat) -> Nat:
  holes_len_go(hs, fuel)

def hole_one(+h: List<&2, V.Vec2>, +outer: List<&2, V.Vec2>,
    +non: Nat, +fuel: Nat) -> U64:
  +m = List.length(&2, V.Vec2, h)
  pick_nz(Bool.pick(U64, Nat.is_le(3n, m), 0u64, 1u64),
    pick_nz(fin_code(h, fuel),
      pick_nz(dist_code(h, fuel),
        pick_nz(sh_map_hole(sh_sign(h, fuel)),
          pick_nz(simp_loop(h, m, fuel),
            pick_nz(hole_in_go(h, outer, fuel),
              loop_pair_code(outer, h, non, m, fuel)))))))

def holes_go(hs: List<&2, List<&2, V.Vec2>>,
    +outer: List<&2, V.Vec2>, +non: Nat, fuel: Nat) -> U64:
  match hs:
    case Nil{}: 0u64
    case h <> t:
      match fuel:
        case 0n: 17u64
        case 1n++m:
          pick_nz(hole_one(h, outer, non, m),
            holes_go(t, outer, non, m))

def ll_nth_go(hs: List<&2, List<&2, V.Vec2>>, i: Nat,
    m: Nat) -> List<&2, V.Vec2>:
  match hs:
    case Nil{}: []
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: ll_nth_go(t, j, m)

def ll_nth(hs: List<&2, List<&2, V.Vec2>>, i: Nat,
    fuel: Nat) -> List<&2, V.Vec2>:
  match fuel:
    case 0n: []
    case 1n+m: ll_nth_go(hs, i, m)

def hh_j(+hs: List<&2, List<&2, V.Vec2>>, +i: Nat, k: Nat,
    fuel: Nat) -> U64:
  match k:
    case 0n: 0u64
    case 1n++p:
      match fuel:
        case 0n: 17u64
        case 1n++m:
          +a = ll_nth(hs, i, m)
          +b = ll_nth(hs, p, m)
          +fp = v2_nth(b, 0n, m)
          +fq = v2_nth(a, 0n, m)
          pick_nz(loop_pair_code(a, b,
              List.length(&2, V.Vec2, a),
              List.length(&2, V.Vec2, b), m),
            pick_nz(nest_map(pip(V.v2_x(fp), V.v2_y(fp), a,
                m)),
              pick_nz(nest_map(pip(V.v2_x(fq), V.v2_y(fq), b,
                  m)),
                hh_j(hs, i, p, m))))

def hh_i(+hs: List<&2, List<&2, V.Vec2>>, k: Nat,
    fuel: Nat) -> U64:
  match k:
    case 0n: 0u64
    case 1n++p:
      match fuel:
        case 0n: 17u64
        case 1n++m:
          pick_nz(hh_j(hs, p, p, m), hh_i(hs, p, m))

def holes_hh(+hs: List<&2, List<&2, V.Vec2>>, fuel: Nat) -> U64:
  hh_i(hs, List.length(&2, List<&2, V.Vec2>, hs), fuel)

def prof_code(+loop: List<&2, V.Vec2>,
    +holes: List<&2, List<&2, V.Vec2>>, +fuel: Nat) -> U64:
  +n = List.length(&2, V.Vec2, loop)
  +tp = Nat.add(n, holes_len(holes, fuel))
  +need = Nat.add(Nat.mul(tp, tp),
    Nat.add(Nat.mul(64n, tp), 64n))
  +over = Bool.not(Nat.is_le(tp, 64n))
  +short = Bool.not(Nat.is_le(need, fuel))
  Bool.pick(U64, over, 18u64,
    Bool.pick(U64, short, 17u64,
      pick_nz(Bool.pick(U64, Nat.is_le(3n, n), 0u64, 1u64),
        pick_nz(fin_code(loop, fuel),
          pick_nz(dist_code(loop, fuel),
            pick_nz(sh_map_outer(sh_sign(loop, fuel)),
              pick_nz(simp_loop(loop, n, fuel),
                pick_nz(holes_go(holes, loop, n, fuel),
                  holes_hh(holes, fuel)))))))))

# --- Exact hole clearance via expansion arithmetic. Raw outcomes:
# 0 clear, 1 too-close, 2 tangent, 3 uncertain. Tangent fails
# closed (breakout). Ex subexpressions are rebuilt, never shared. ---
def ex_sq2(+x: F64, +y: F64) -> E.Ex:
  E.ex_add(E.ex_mul(E.ex_of(x), E.ex_of(x)),
    E.ex_mul(E.ex_of(y), E.ex_of(y)))

def clr_sgn(s: B.Sgn) -> U64:
  match s:
    case B.Sp{}: 0u64
    case B.Sn{}: 1u64
    case B.Sz{}: 2u64
    case B.Su{}: 3u64

def clr_fin(a: E.Ex, b: E.Ex) -> U64:
  clr_sgn(E.ex_cmp(a, b))

def clr_t2(s: B.Sgn, +px: F64, +py: F64, +ax: F64, +ay: F64,
    +bx: F64, +by: F64, +r: F64) -> U64:
  match s:
    case B.Sn{}:
      clr_fin(E.ex_sub(E.ex_mul(ex_sq2(F64.sub(px, ax),
            F64.sub(py, ay)),
          ex_sq2(F64.sub(bx, ax), F64.sub(by, ay))),
        E.ex_mul(E.ex_add(E.ex_mul(E.ex_of(F64.sub(px, ax)),
              E.ex_of(F64.sub(bx, ax))),
            E.ex_mul(E.ex_of(F64.sub(py, ay)),
              E.ex_of(F64.sub(by, ay)))),
          E.ex_add(E.ex_mul(E.ex_of(F64.sub(px, ax)),
              E.ex_of(F64.sub(bx, ax))),
            E.ex_mul(E.ex_of(F64.sub(py, ay)),
              E.ex_of(F64.sub(by, ay)))))),
        E.ex_mul(E.ex_mul(E.ex_of(r), E.ex_of(r)),
          ex_sq2(F64.sub(bx, ax), F64.sub(by, ay))))
    case B.Sz{}:
      clr_fin(ex_sq2(F64.sub(px, bx), F64.sub(py, by)),
        E.ex_mul(E.ex_of(r), E.ex_of(r)))
    case B.Sp{}:
      clr_fin(ex_sq2(F64.sub(px, bx), F64.sub(py, by)),
        E.ex_mul(E.ex_of(r), E.ex_of(r)))
    case B.Su{}: 3u64

def clr_t1(s: B.Sgn, +px: F64, +py: F64, +ax: F64, +ay: F64,
    +bx: F64, +by: F64, +r: F64) -> U64:
  match s:
    case B.Sn{}:
      clr_fin(ex_sq2(F64.sub(px, ax), F64.sub(py, ay)),
        E.ex_mul(E.ex_of(r), E.ex_of(r)))
    case B.Sz{}:
      clr_fin(ex_sq2(F64.sub(px, ax), F64.sub(py, ay)),
        E.ex_mul(E.ex_of(r), E.ex_of(r)))
    case B.Sp{}:
      clr_t2(E.ex_cmp(E.ex_add(E.ex_mul(E.ex_of(F64.sub(px,
                ax)),
              E.ex_of(F64.sub(bx, ax))),
            E.ex_mul(E.ex_of(F64.sub(py, ay)),
              E.ex_of(F64.sub(by, ay)))),
          ex_sq2(F64.sub(bx, ax), F64.sub(by, ay))),
        px, py, ax, ay, bx, by, r)
    case B.Su{}: 3u64

def hole_clr_pt(+px: F64, +py: F64, +ax: F64, +ay: F64,
    +bx: F64, +by: F64, +r: F64) -> U64:
  clr_t1(E.ex_sign(E.ex_add(E.ex_mul(E.ex_of(F64.sub(px, ax)),
            E.ex_of(F64.sub(bx, ax))),
          E.ex_mul(E.ex_of(F64.sub(py, ay)),
            E.ex_of(F64.sub(by, ay))))),
    px, py, ax, ay, bx, by, r)

def clr_map(c: U64) -> U64:
  match c:
    case 0u64: 0u64
    case 1u64: 19u64
    case 2u64: 19u64
    case 3u64: 13u64
    case _: 17u64

def hole_clr_go(xs: List<&2, V.Vec2>, +px: F64, +py: F64,
    +r: F64, +fx: F64, +fy: F64, +ax: F64, +ay: F64,
    fuel: Nat) -> U64:
  match xs:
    case Nil{}:
      clr_map(hole_clr_pt(px, py, ax, ay, fx, fy, r))
    case +h <> t:
      match fuel:
        case 0n: 17u64
        case 1n+m:
          pick_nz(clr_map(hole_clr_pt(px, py, ax, ay,
              V.v2_x(h), V.v2_y(h), r)),
            hole_clr_go(t, px, py, r, fx, fy, V.v2_x(h),
              V.v2_y(h), m))

def hole_clr_loop(+px: F64, +py: F64, +r: F64,
    xs: List<&2, V.Vec2>, fuel: Nat) -> U64:
  match xs:
    case Nil{}: 0u64
    case +h <> t:
      hole_clr_go(t, px, py, r, V.v2_x(h), V.v2_y(h),
        V.v2_x(h), V.v2_y(h), fuel)

def hole_clr_hs(+px: F64, +py: F64, +r: F64,
    hs: List<&2, List<&2, V.Vec2>>, fuel: Nat) -> U64:
  match hs:
    case Nil{}: 0u64
    case h <> t:
      match fuel:
        case 0n: 17u64
        case 1n++m:
          pick_nz(hole_clr_loop(px, py, r, h, m),
            hole_clr_hs(px, py, r, t, m))

def hh_fin(s: B.Sgn) -> U64:
  match s:
    case B.Sn{}: 20u64
    case B.Sz{}: 20u64
    case B.Sp{}: 0u64
    case B.Su{}: 13u64

def hole_hh(+x1: F64, +y1: F64, +r1: F64, +x2: F64, +y2: F64,
    +r2: F64) -> U64:
  hh_fin(E.ex_cmp(ex_sq2(F64.sub(x1, x2), F64.sub(y1, y2)),
    E.ex_mul(E.ex_add(E.ex_of(r1), E.ex_of(r2)),
      E.ex_add(E.ex_of(r1), E.ex_of(r2)))))

def rect_fin(s: B.Sgn) -> U64:
  match s:
    case B.Sn{}: 21u64
    case B.Sz{}: 21u64
    case B.Sp{}: 0u64
    case B.Su{}: 13u64

def hole_rect(+px: F64, +py: F64, +r: F64, +rx0: F64, +ry0: F64,
    +rx1: F64, +ry1: F64) -> U64:
  +cx = Bool.pick(F64, F64.is_lt(px, rx0), rx0,
    Bool.pick(F64, F64.is_lt(rx1, px), rx1, px))
  +cy = Bool.pick(F64, F64.is_lt(py, ry0), ry0,
    Bool.pick(F64, F64.is_lt(ry1, py), ry1, py))
  rect_fin(E.ex_cmp(ex_sq2(F64.sub(px, cx), F64.sub(py, cy)),
    E.ex_mul(E.ex_of(r), E.ex_of(r))))

def hole_boss1(+px: F64, +py: F64, +r: F64, b: Y.Boss) -> U64:
  Y.Bo{+x, +y, +w, +d, +z0, +z1} = b
  hole_rect(px, py, r, x, y, F64.add(x, w), F64.add(y, d))

def hole_boss_go(+px: F64, +py: F64, +r: F64,
    bs: List<&2, Y.Boss>, fuel: Nat) -> U64:
  match bs:
    case Nil{}: 0u64
    case h <> t:
      match fuel:
        case 0n: 17u64
        case 1n++m:
          pick_nz(hole_boss1(px, py, r, h),
            hole_boss_go(px, py, r, t, m))

def rect_loop(+x: F64, +y: F64, +w: F64, +h: F64)
    -> List<&2, V.Vec2>:
  +x1 = F64.add(x, w)
  +y1 = F64.add(y, h)
  V.V2{x, y} <> V.V2{x, y1} <> V.V2{x1, y1} <> V.V2{x1, y} <>
    []

def rect_disj(+x0: F64, +y0: F64, +w0: F64, +h0: F64, +x1: F64,
    +y1: F64, +w1: F64, +h1: F64) -> Bool:
  Bool.or(F64.is_le(F64.add(x0, w0), x1),
    Bool.or(F64.is_le(F64.add(x1, w1), x0),
      Bool.or(F64.is_le(F64.add(y0, h0), y1),
        F64.is_le(F64.add(y1, h1), y0))))

# --- Code mapper: every validation code becomes a diagnosis. ---
def prof_go(code: U64, +loc: String) -> Y.SRes:
  match code:
    case 0u64: Y.sok_u(0u64)
    case 1u64:
      Y.serr_invalid("profile loop", loc, "short-loop",
        "give at least 3 points")
    case 2u64:
      Y.serr_invalid("profile point", loc, "nonfinite-point",
        "replace nonfinite coordinates")
    case 3u64:
      Y.serr_invalid("profile loop", loc, "repeated-point",
        "remove consecutive duplicates")
    case 4u64:
      Y.serr_invalid("profile loop", loc, "zero-area",
        "give nonzero signed area")
    case 5u64:
      Y.serr_invalid("profile loop", loc, "winding",
        "reverse the loop (outer CCW, holes CW)")
    case 6u64:
      Y.serr_invalid("profile loop", loc, "self-crossing",
        "remove the crossing")
    case 7u64:
      Y.serr_invalid("profile loop", loc, "self-touch",
        "separate the touch")
    case 8u64:
      Y.serr_invalid("profile loop", loc, "spike",
        "remove backtracking edges")
    case 9u64:
      Y.serr_invalid("profile hole", loc, "hole-outside",
        "move the hole inside the outer loop")
    case 10u64:
      Y.serr_invalid("profile loops", loc, "loop-touch",
        "separate the loops")
    case 11u64:
      Y.serr_invalid("profile loops", loc, "loop-crossing",
        "separate the loops")
    case 12u64:
      Y.serr_invalid("profile holes", loc, "hole-nesting",
        "unnest the holes")
    case 13u64:
      Y.serr_uncertain("predicate", loc, "predicate-uncertain",
        "perturb coordinates slightly")
    case 14u64:
      Y.serr_invalid("revolve profile", loc, "axis-crossing",
        "keep all y >= 0")
    case 15u64:
      Y.serr_invalid("revolve profile", loc, "axis-pinch",
        "split the axis touch into two vertices")
    case 16u64:
      Y.serr_invalid("revolve hole", loc, "hole-axis-touch",
        "lift the hole off the axis")
    case 17u64:
      Y.serr_exhausted("fuel", loc, "fuel-out",
        "raise the fuel cap")
    case 18u64:
      Y.serr_exhausted("profile", loc, "profile-too-large",
        "stay within 64 points")
    case 19u64:
      Y.serr_invalid("hole", loc, "hole-breakout",
        "move the hole or shrink its radius")
    case 20u64:
      Y.serr_invalid("holes", loc, "hole-merge",
        "separate the holes")
    case 21u64:
      Y.serr_invalid("hole", loc, "hole-into-boss",
        "move the hole off the boss")
    case 22u64:
      Y.serr_invalid("pad", loc, "pad-overlap",
        "separate the footprints")
    case 23u64:
      Y.serr_invalid("footprint", loc, "footprint-outside",
        "keep the footprint inside the face")
    case 24u64:
      Y.serr_unsupported("pocket", loc, "blind-pocket",
        "use depth >= thickness (through) or wait for C08")
    case _:
      Y.serr_invalid("profile", loc, "unknown-code",
        "internal: report this")

def prof_valid(p: Y.Prof, fuel: Nat) -> Y.SRes:
  Y.Pf{+loop, +holes} = p
  prof_go(prof_code(loop, holes, fuel), "profile")

# --- Revolve axis discipline: all y >= 0; axis vertices join at
# most one non-axis edge (else a nonmanifold pinch). Each step
# checks the previous vertex (both its edges are known then); the
# Nil arm checks the last vertex against the closing edge. ---
def rev_ax_go(xs: List<&2, V.Vec2>, +prev_y: F64, +prev_nax: Bool,
    +close_nax: Bool, fuel: Nat) -> U64:
  match xs:
    case Nil{}:
      Bool.pick(U64, Bool.and(F64.is_eq(prev_y, 0.0f64),
        Bool.and(prev_nax, close_nax)), 15u64, 0u64)
    case h <> t:
      match fuel:
        case 0n: 17u64
        case 1n+m:
          +y = V.v2_y(h)
          +nax = Bool.not(Bool.and(F64.is_eq(prev_y, 0.0f64),
            F64.is_eq(y, 0.0f64)))
          pick_nz(Bool.pick(U64, F64.is_lt(y, 0.0f64), 14u64,
              0u64),
            pick_nz(Bool.pick(U64, Bool.and(F64.is_eq(prev_y,
                0.0f64), Bool.and(prev_nax, nax)), 15u64, 0u64),
              rev_ax_go(t, y, nax, close_nax, m)))

def last_y_go(xs: List<&2, V.Vec2>, +carry: F64,
    fuel: Nat) -> F64:
  match xs:
    case Nil{}: carry
    case h <> t:
      match fuel:
        case 0n: carry
        case 1n+m: last_y_go(t, V.v2_y(h), m)

def first_y(xs: List<&2, V.Vec2>) -> F64:
  match xs:
    case Nil{}: 0.0f64
    case h <> t: V.v2_y(h)

def last_y(xs: List<&2, V.Vec2>, fuel: Nat) -> F64:
  match xs:
    case Nil{}: 0.0f64
    case h <> t:
      match fuel:
        case 0n: V.v2_y(h)
        case 1n+m: last_y_go(t, V.v2_y(h), m)

def rev_ax_rest(xs: List<&2, V.Vec2>, +close_nax: Bool,
    +fuel: Nat) -> U64:
  match xs:
    case Nil{}: 0u64
    case h <> t:
      rev_ax_go(t, V.v2_y(h), close_nax, close_nax, fuel)

def rev_ax(+xs: List<&2, V.Vec2>, +fuel: Nat) -> U64:
  +ly = last_y(xs, fuel)
  +fy = first_y(xs)
  +close_nax = Bool.not(Bool.and(F64.is_eq(ly, 0.0f64),
    F64.is_eq(fy, 0.0f64)))
  pick_nz(Bool.pick(U64, F64.is_lt(fy, 0.0f64), 14u64, 0u64),
    rev_ax_rest(xs, close_nax, fuel))

def rev_hole_pts(ys: List<&2, V.Vec2>, fuel: Nat) -> U64:
  match ys:
    case Nil{}: 0u64
    case h <> t:
      match fuel:
        case 0n: 17u64
        case 1n+m:
          pick_nz(Bool.pick(U64, F64.is_lt(0.0f64, V.v2_y(h)),
              0u64, 16u64),
            rev_hole_pts(t, m))

def rev_hole_go(hs: List<&2, List<&2, V.Vec2>>,
    fuel: Nat) -> U64:
  match hs:
    case Nil{}: 0u64
    case h <> t:
      match fuel:
        case 0n: 17u64
        case 1n++m:
          pick_nz(rev_hole_pts(h, m), rev_hole_go(t, m))

def prof_valid_rev(p: Y.Prof, +fuel: Nat) -> Y.SRes:
  Y.Pf{+loop, +holes} = p
  prof_go(pick_nz(prof_code(loop, holes, fuel),
      pick_nz(rev_ax(loop, fuel), rev_hole_go(holes, fuel))),
    "revolve")

# --- Specs: index-addressed entity descriptions. Builders emit
# them; bulk stamps gens, rewrites refs, and assembles. ---
type VSp is Data:
  VS{ p: V.Point }

type ESp is Data:
  ES{ i0: Nat, i1: Nat, curve: G.GVal, dom: G.Dom, degen: Bool }

type CSp is Data:
  CS{ ei: Nat, fwd: Bool, trim: G.GVal }

type LSp is Data:
  LS{ ces: List<&2, Nat>, kind: Ty.LoopKind }

type FSp is Data:
  FS{ surf: G.GVal, loops: List<&2, Nat>, same: Bool }

type SSp is Data:
  SS{ faces: List<&2, Nat>, kind: Ty.ShellKind }

type OSp is Data:
  OS{ outer: Nat, cavs: List<&2, Nat> }

type Spec is Data:
  SP{ vs: List<&2, VSp>, es: List<&2, ESp>, ces: List<&2, CSp>,
    lps: List<&2, LSp>, fas: List<&2, FSp>, shs: List<&2, SSp>,
    sos: List<&2, OSp>, topso: List<&2, Nat>,
    topsh: List<&2, Nat> }

def spec_empty() -> Spec:
  SP{[], [], [], [], [], [], [], [], []}

def spec_nv(sp: Spec) -> Nat:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  List.length(&2, VSp, vs)

def spec_ne(sp: Spec) -> Nat:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  List.length(&2, ESp, es)

def spec_nc(sp: Spec) -> Nat:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  List.length(&2, CSp, ces)

def spec_nl(sp: Spec) -> Nat:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  List.length(&2, LSp, lps)

def spec_nf(sp: Spec) -> Nat:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  List.length(&2, FSp, fas)

def spec_nh(sp: Spec) -> Nat:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  List.length(&2, SSp, shs)

def spec_no(sp: Spec) -> Nat:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  List.length(&2, OSp, sos)

def vs_def() -> VSp:
  VS{V.Pt{0.0f64, 0.0f64, 0.0f64}}

def es_def() -> ESp:
  ES{0n, 0n, G.GV_f{0.0f64}, G.Dom{0.0f64, 1.0f64}, False{}}

def ces_def() -> CSp:
  CS{0n, True{}, G.GV_f{0.0f64}}

def lps_def() -> LSp:
  LS{[], Ty.LK_outer{}}

def fas_def() -> FSp:
  FS{G.GV_f{0.0f64}, [], True{}}

def shs_def() -> SSp:
  SS{[], Ty.SK_outer{}}

def sos_def() -> OSp:
  OS{0n, []}

# --- Balanced tree joins (O(1) join, single O(n) flatten).
# Empty inputs fall back to the default leaf (callers guard
# empties up front, so defaults are unreachable). ---
def tr_lift_d(-A: Data, +ts: List<&2, B.Tr<&2, A>>, +z: A,
    dm: B.Dm) -> B.Tr<&2, A>:
  B.Dm{+d, +k} = dm
  B.tr_lift(A, d, ts, z)

def tr_of_d(-A: Data, +xs: List<&2, A>, +z: A,
    dm: B.Dm) -> B.Tr<&2, A>:
  B.Dm{+d, +k} = dm
  B.tr_lift(A, d, B.tr_leaves(A, xs), z)

def tr_of_list(-A: Data, +xs: List<&2, A>, +z: A) -> B.Tr<&2, A>:
  tr_of_d(A, xs, z,
    B.dims(U32.from_nat(List.length(&2, A, xs))))

def tr_parts(-A: Data, +ll: List<&2, List<&2, A>>, +z: A,
    fuel: Nat) -> List<&2, B.Tr<&2, A>>:
  match ll:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: []
        case 1n+m: tr_of_list(A, h, z) <> tr_parts(A, t, z, m)

def tr_join_d(-A: Data, +ts: List<&2, B.Tr<&2, A>>,
    +z: A) -> B.Tr<&2, A>:
  tr_lift_d(A, ts, z,
    B.dims(U32.from_nat(List.length(&2, B.Tr<&2, A>, ts))))

def tr_join_go(-A: Data, +ll: List<&2, List<&2, A>>, +z: A,
    fuel: Nat) -> B.Tr<&2, A>:
  tr_join_d(A, tr_parts(A, ll, z, fuel), z)

def tr_flat(-A: Data, +t: B.Tr<&2, A>) -> List<&2, A>:
  B.tr_list(A, t, [])

def tr_join_lists(-A: Data, +ll: List<&2, List<&2, A>>, +z: A,
    fuel: Nat) -> List<&2, A>:
  tr_flat(A, tr_join_go(A, ll, z, fuel))

# --- Spec offsets (per-part index relocation). ---
def esp_1(e: ESp, +ov: Nat) -> ESp:
  ES{+i0, +i1, +curve, +dom, +degen} = e
  ES{Nat.add(i0, ov), Nat.add(i1, ov), curve, dom, degen}

def esp_off_l(xs: List<&2, ESp>, +ov: Nat,
    fuel: Nat) -> List<&2, ESp>:
  match xs:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: xs
        case 1n+m: esp_1(h, ov) <> esp_off_l(t, ov, m)

def csp_1(c: CSp, +oe: Nat) -> CSp:
  CS{+ei, +fwd, +trim} = c
  CS{Nat.add(ei, oe), fwd, trim}

def csp_off_l(xs: List<&2, CSp>, +oe: Nat,
    fuel: Nat) -> List<&2, CSp>:
  match xs:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: xs
        case 1n+m: csp_1(h, oe) <> csp_off_l(t, oe, m)

def lsp_1(l: LSp, +oc: Nat, fuel: Nat) -> LSp:
  LS{+ces, +kind} = l
  LS{map_add(ces, oc, fuel), kind}

def lsp_off_l(xs: List<&2, LSp>, +oc: Nat,
    fuel: Nat) -> List<&2, LSp>:
  match xs:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: xs
        case 1n++m: lsp_1(h, oc, m) <> lsp_off_l(t, oc, m)

def fsp_1(f: FSp, +ol: Nat, fuel: Nat) -> FSp:
  FS{+surf, +loops, +same} = f
  FS{surf, map_add(loops, ol, fuel), same}

def fsp_off_l(xs: List<&2, FSp>, +ol: Nat,
    fuel: Nat) -> List<&2, FSp>:
  match xs:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: xs
        case 1n++m: fsp_1(h, ol, m) <> fsp_off_l(t, ol, m)

def ssp_1(s: SSp, +of: Nat, fuel: Nat) -> SSp:
  SS{+faces, +kind} = s
  SS{map_add(faces, of, fuel), kind}

def ssp_off_l(xs: List<&2, SSp>, +of: Nat,
    fuel: Nat) -> List<&2, SSp>:
  match xs:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: xs
        case 1n++m: ssp_1(h, of, m) <> ssp_off_l(t, of, m)

def osp_1(o: OSp, +oh: Nat, fuel: Nat) -> OSp:
  OS{+outer, +cavs} = o
  OS{Nat.add(outer, oh), map_add(cavs, oh, fuel)}

def osp_off_l(xs: List<&2, OSp>, +oh: Nat,
    fuel: Nat) -> List<&2, OSp>:
  match xs:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: xs
        case 1n++m: osp_1(h, oh, m) <> osp_off_l(t, oh, m)

def spec_off(sp: Spec, +ov: Nat, +oe: Nat, +oc: Nat, +ol: Nat,
    +of: Nat, +oh: Nat, +oo: Nat, +fuel: Nat) -> Spec:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  SP{vs, esp_off_l(es, ov, fuel), csp_off_l(ces, oe, fuel),
    lsp_off_l(lps, oc, fuel), fsp_off_l(fas, ol, fuel),
    ssp_off_l(shs, of, fuel), osp_off_l(sos, oh, fuel),
    map_add(topso, oo, fuel), map_add(topsh, oh, fuel)}

def sp_vs(sp: Spec) -> List<&2, VSp>:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  vs

def sp_es(sp: Spec) -> List<&2, ESp>:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  es

def sp_ces(sp: Spec) -> List<&2, CSp>:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  ces

def sp_lps(sp: Spec) -> List<&2, LSp>:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  lps

def sp_fas(sp: Spec) -> List<&2, FSp>:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  fas

def sp_shs(sp: Spec) -> List<&2, SSp>:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  shs

def sp_sos(sp: Spec) -> List<&2, OSp>:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  sos

def sp_topso(sp: Spec) -> List<&2, Nat>:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  topso

def sp_topsh(sp: Spec) -> List<&2, Nat>:
  SP{+vs, +es, +ces, +lps, +fas, +shs, +sos, +topso,
    +topsh} = sp
  topsh

def g_vs(sps: List<&2, Spec>, fuel: Nat) -> List<&2, List<&2, VSp>>:
  match sps:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: []
        case 1n+m: sp_vs(h) <> g_vs(t, m)

def g_es(sps: List<&2, Spec>, fuel: Nat) -> List<&2, List<&2, ESp>>:
  match sps:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: []
        case 1n+m: sp_es(h) <> g_es(t, m)

def g_ces(sps: List<&2, Spec>, fuel: Nat) -> List<&2, List<&2, CSp>>:
  match sps:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: []
        case 1n+m: sp_ces(h) <> g_ces(t, m)

def g_lps(sps: List<&2, Spec>, fuel: Nat) -> List<&2, List<&2, LSp>>:
  match sps:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: []
        case 1n+m: sp_lps(h) <> g_lps(t, m)

def g_fas(sps: List<&2, Spec>, fuel: Nat) -> List<&2, List<&2, FSp>>:
  match sps:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: []
        case 1n+m: sp_fas(h) <> g_fas(t, m)

def g_shs(sps: List<&2, Spec>, fuel: Nat) -> List<&2, List<&2, SSp>>:
  match sps:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: []
        case 1n+m: sp_shs(h) <> g_shs(t, m)

def g_sos(sps: List<&2, Spec>, fuel: Nat) -> List<&2, List<&2, OSp>>:
  match sps:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: []
        case 1n+m: sp_sos(h) <> g_sos(t, m)

def g_topso(sps: List<&2, Spec>, fuel: Nat) -> List<&2, List<&2, Nat>>:
  match sps:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: []
        case 1n+m: sp_topso(h) <> g_topso(t, m)

def g_topsh(sps: List<&2, Spec>, fuel: Nat) -> List<&2, List<&2, Nat>>:
  match sps:
    case Nil{}: []
    case h <> t:
      match fuel:
        case 0n: []
        case 1n+m: sp_topsh(h) <> g_topsh(t, m)

def off_parts(sps: List<&2, Spec>, +ov: Nat, +oe: Nat, +oc: Nat,
    +ol: Nat, +of: Nat, +oh: Nat, +oo: Nat,
    fuel: Nat) -> List<&2, Spec>:
  match sps:
    case Nil{}: []
    case +h <> t:
      match fuel:
        case 0n: []
        case 1n++m:
          spec_off(h, ov, oe, oc, ol, of, oh, oo, m) <>
            off_parts(t, Nat.add(ov, spec_nv(h)),
              Nat.add(oe, spec_ne(h)), Nat.add(oc, spec_nc(h)),
              Nat.add(ol, spec_nl(h)), Nat.add(of, spec_nf(h)),
              Nat.add(oh, spec_nh(h)), Nat.add(oo, spec_no(h)),
              m)

def join_specs(+sps: List<&2, Spec>, +fuel: Nat) -> Spec:
  +os = off_parts(sps, 0n, 0n, 0n, 0n, 0n, 0n, 0n, fuel)
  SP{tr_join_lists(VSp, g_vs(os, fuel), vs_def(), fuel),
    tr_join_lists(ESp, g_es(os, fuel), es_def(), fuel),
    tr_join_lists(CSp, g_ces(os, fuel), ces_def(), fuel),
    tr_join_lists(LSp, g_lps(os, fuel), lps_def(), fuel),
    tr_join_lists(FSp, g_fas(os, fuel), fas_def(), fuel),
    tr_join_lists(SSp, g_shs(os, fuel), shs_def(), fuel),
    tr_join_lists(OSp, g_sos(os, fuel), sos_def(), fuel),
    tr_join_lists(Nat, g_topso(os, fuel), 0n, fuel),
    tr_join_lists(Nat, g_topsh(os, fuel), 0n, fuel)}

# --- Stamping: canonical gens (gen = idx+1) plus the stamp cap
# (stamp = max store length). Builders emit consistent gens directly
# via these smart constructors; no deep restamp pass is needed. ---

def gid(+j: Nat) -> U64:
  (U64.from_nat(j) + 1u64 : U64)

def hv_new(+j: Nat) -> Ty.HVertex:
  Ty.mk_hv(j, gid(j))

def he_new(+j: Nat) -> Ty.HEdge:
  Ty.mk_he(j, gid(j))

def hc_new(+j: Nat) -> Ty.HCoedge:
  Ty.mk_hc(j, gid(j))

def hlp_new(+j: Nat) -> Ty.HLoop:
  Ty.mk_hlp(j, gid(j))

def hfa_new(+j: Nat) -> Ty.HFace:
  Ty.mk_hfa(j, gid(j))

def hsh_new(+j: Nat) -> Ty.HShell:
  Ty.mk_hsh(j, gid(j))

def hso_new(+j: Nat) -> Ty.HSolid:
  Ty.mk_hso(j, gid(j))

# --- Stage A attribution: names the failing store walk. Tags
# 1..21 (store x all/gen/nodup); 100 undecided; 0 defensive. ---
def att3(+a: Nat, +g: Nat, +n: Nat, +base: U64) -> U64:
  Bool.pick(U64, Bool.not(Ty.okd_ok(a)), base,
    Bool.pick(U64, Bool.not(Ty.okd_ok(g)), (base + 1u64 : U64),
      Bool.pick(U64, Bool.not(Ty.okd_ok(n)), (base + 2u64 : U64),
        0u64)))

def att_tag(+vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>,
    +ces: List<&2, Ty.Coedge>, +lps: List<&2, Ty.Loop>,
    +fas: List<&2, Ty.Face>, +shs: List<&2, Ty.Shell>,
    +sos: List<&2, Ty.Solid>, +stamp: U64,
    +fuel: Nat) -> U64:
  +done = Bool.and(Ty.okd_done(Ty.vs_all_c(vs, fuel)),
    Bool.and(Ty.okd_done(Ty.es_all_c(es, fuel)),
      Bool.and(Ty.okd_done(Ty.ces_all_c(ces, fuel)),
        Bool.and(Ty.okd_done(Ty.lps_all_c(lps, fuel)),
          Bool.and(Ty.okd_done(Ty.fas_all_c(fas, fuel)),
            Bool.and(Ty.okd_done(Ty.shs_all_c(shs, fuel)),
              Ty.okd_done(Ty.sos_all_c(sos, fuel))))))))
  Bool.pick(U64, Bool.not(done), 100u64,
    pick_nz(att3(Ty.vs_all_c(vs, fuel),
        Ty.vs_gen_c(vs, stamp, fuel),
        Ty.vs_nodup_c(vs, fuel), 1u64),
      pick_nz(att3(Ty.es_all_c(es, fuel),
          Ty.es_gen_c(es, stamp, fuel),
          Ty.es_nodup_c(es, fuel), 4u64),
        pick_nz(att3(Ty.ces_all_c(ces, fuel),
            Ty.ces_gen_c(ces, stamp, fuel),
            Ty.ces_nodup_c(ces, fuel), 7u64),
          pick_nz(att3(Ty.lps_all_c(lps, fuel),
              Ty.lps_gen_c(lps, stamp, fuel),
              Ty.lps_nodup_c(lps, fuel), 10u64),
            pick_nz(att3(Ty.fas_all_c(fas, fuel),
                Ty.fas_gen_c(fas, stamp, fuel),
                Ty.fas_nodup_c(fas, fuel), 13u64),
              pick_nz(att3(Ty.shs_all_c(shs, fuel),
                  Ty.shs_gen_c(shs, stamp, fuel),
                  Ty.shs_nodup_c(shs, fuel), 16u64),
                att3(Ty.sos_all_c(sos, fuel),
                  Ty.sos_gen_c(sos, stamp, fuel),
                  Ty.sos_nodup_c(sos, fuel), 19u64))))))))

def att_go(tag: U64) -> Y.SRes:
  match tag:
    case 0u64:
      Y.serr_invalid("spec stores", "bulk", "internal-att",
        "internal: report this")
    case 100u64:
      Y.serr_exhausted("spec stores", "bulk", "fuel-out",
        "raise the fuel cap")
    case 1u64:
      Y.serr_invalid("spec stores", "bulk", "vs-all",
        "internal: report this")
    case 2u64:
      Y.serr_invalid("spec stores", "bulk", "vs-gen",
        "internal: report this")
    case 3u64:
      Y.serr_invalid("spec stores", "bulk", "vs-nodup",
        "internal: report this")
    case 4u64:
      Y.serr_invalid("spec stores", "bulk", "es-all",
        "internal: report this")
    case 5u64:
      Y.serr_invalid("spec stores", "bulk", "es-gen",
        "internal: report this")
    case 6u64:
      Y.serr_invalid("spec stores", "bulk", "es-nodup",
        "internal: report this")
    case 7u64:
      Y.serr_invalid("spec stores", "bulk", "ces-all",
        "internal: report this")
    case 8u64:
      Y.serr_invalid("spec stores", "bulk", "ces-gen",
        "internal: report this")
    case 9u64:
      Y.serr_invalid("spec stores", "bulk", "ces-nodup",
        "internal: report this")
    case 10u64:
      Y.serr_invalid("spec stores", "bulk", "lps-all",
        "internal: report this")
    case 11u64:
      Y.serr_invalid("spec stores", "bulk", "lps-gen",
        "internal: report this")
    case 12u64:
      Y.serr_invalid("spec stores", "bulk", "lps-nodup",
        "internal: report this")
    case 13u64:
      Y.serr_invalid("spec stores", "bulk", "fas-all",
        "internal: report this")
    case 14u64:
      Y.serr_invalid("spec stores", "bulk", "fas-gen",
        "internal: report this")
    case 15u64:
      Y.serr_invalid("spec stores", "bulk", "fas-nodup",
        "internal: report this")
    case 16u64:
      Y.serr_invalid("spec stores", "bulk", "shs-all",
        "internal: report this")
    case 17u64:
      Y.serr_invalid("spec stores", "bulk", "shs-gen",
        "internal: report this")
    case 18u64:
      Y.serr_invalid("spec stores", "bulk", "shs-nodup",
        "internal: report this")
    case 19u64:
      Y.serr_invalid("spec stores", "bulk", "sos-all",
        "internal: report this")
    case 20u64:
      Y.serr_invalid("spec stores", "bulk", "sos-gen",
        "internal: report this")
    case 21u64:
      Y.serr_invalid("spec stores", "bulk", "sos-nodup",
        "internal: report this")
    case _:
      Y.serr_invalid("spec stores", "bulk", "unknown-att",
        "internal: report this")

# --- Stage B..L attribution in pipeline order. Stages are
# numbered B=2..L=12; 100+stage means undecided (fuel). ---
def stc(+c: Nat, +stage: U64) -> U64:
  Bool.pick(U64, Bool.not(Ty.okd_done(c)), (100u64 + stage : U64),
    Bool.pick(U64, Bool.not(Ty.okd_ok(c)), stage, 0u64))

def stage_ex(code: U64) -> Y.SRes:
  match code:
    case 102u64:
      Y.serr_exhausted("incidence", "bulk", "fuel-out",
        "raise the fuel cap")
    case 103u64:
      Y.serr_exhausted("edge-use", "bulk", "fuel-out",
        "raise the fuel cap")
    case 104u64:
      Y.serr_exhausted("loop", "bulk", "fuel-out",
        "raise the fuel cap")
    case 105u64:
      Y.serr_exhausted("face-kind", "bulk", "fuel-out",
        "raise the fuel cap")
    case 106u64:
      Y.serr_exhausted("ownership", "bulk", "fuel-out",
        "raise the fuel cap")
    case 107u64:
      Y.serr_exhausted("embedding", "bulk", "fuel-out",
        "raise the fuel cap")
    case 108u64:
      Y.serr_exhausted("vertex-link", "bulk", "fuel-out",
        "raise the fuel cap")
    case 109u64:
      Y.serr_exhausted("shells", "bulk", "fuel-out",
        "raise the fuel cap")
    case 110u64:
      Y.serr_exhausted("vertices", "bulk", "fuel-out",
        "raise the fuel cap")
    case 111u64:
      Y.serr_exhausted("faces", "bulk", "fuel-out",
        "raise the fuel cap")
    case 112u64:
      Y.serr_exhausted("orientation", "bulk", "fuel-out",
        "raise the fuel cap")
    case _:
      Y.serr_invalid("stages", "bulk", "unknown-stage",
        "internal: report this")

def stage_go(code: U64) -> Y.SRes:
  match code:
    case 0u64:
      Y.serr_exhausted("stages", "bulk", "internal-stage",
        "internal: report this")
    case 2u64:
      Y.serr_invalid("incidence", "bulk", "dangling-handle",
        "internal: report this")
    case 3u64:
      Y.serr_invalid("edge-use", "bulk", "edge-use",
        "internal: report this")
    case 4u64:
      Y.serr_invalid("loop", "bulk", "loop-or-trim-meet",
        "internal: report this")
    case 5u64:
      Y.serr_invalid("face-kind", "bulk", "face-kind",
        "internal: report this")
    case 6u64:
      Y.serr_invalid("ownership", "bulk", "ownership",
        "internal: report this")
    case 7u64:
      Y.serr_uncertain("embedding", "bulk", "embedding",
        "use dyadic coordinates (integers/halves)")
    case 8u64:
      Y.serr_invalid("vertex-link", "bulk", "vertex-link",
        "internal: report this")
    case 9u64:
      Y.serr_invalid("shells", "bulk", "disconnected",
        "internal: report this")
    case 10u64:
      Y.serr_invalid("vertices", "bulk", "coincident",
        "separate coincident vertices")
    case 11u64:
      Y.serr_invalid("faces", "bulk", "segment-crossing",
        "increase clearance between loops")
    case 12u64:
      Y.serr_invalid("orientation", "bulk", "orientation",
        "internal: report this")
    case _:
      stage_ex(code)

def diag_brep(+b: Ty.Brep, +fuel: Nat) -> Y.SRes:
  stage_go(pick_nz(stc(B4.brep_incid_c(b, fuel), 2u64),
    pick_nz(stc(B4.brep_use_c(b, Ty.P_manifold_solid{}, fuel),
        3u64),
      pick_nz(stc(B4.brep_loop_c(b, fuel), 4u64),
        pick_nz(stc(B4.brep_facekind_c(b, fuel), 5u64),
          pick_nz(stc(B4.brep_prof_c(b, Ty.P_manifold_solid{},
              fuel), 6u64),
            pick_nz(stc(B4.brep_embed_c(b, fuel), 7u64),
              pick_nz(stc(B4.brep_link_c(b,
                  Ty.P_manifold_solid{}, fuel), 8u64),
                pick_nz(stc(B4.brep_conn_c(b, fuel), 9u64),
                  pick_nz(stc(B4.brep_coin_c(b, fuel), 10u64),
                    pick_nz(stc(B4.brep_xing_c(b, fuel), 11u64),
                      stc(B4.brep_orient_c(b, fuel),
                        12u64))))))))))))

def bulk_c(rb: Ty.TRes, b: Ty.Brep, +fuel: Nat) -> Y.SRes:
  match rb:
    case Ty.Tok{v}:
      match v:
        case Ty.T_brep{w}: Y.sok_brep(w)
        case _: diag_brep(b, fuel)
    case Ty.Terr{kind}: diag_brep(b, fuel)

def bulk_a(ra: Ty.TRes, +vs: List<&2, Ty.Vertex>,
    +es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>,
    +lps: List<&2, Ty.Loop>, +fas: List<&2, Ty.Face>,
    +shs: List<&2, Ty.Shell>, +sos: List<&2, Ty.Solid>,
    +stamp: U64, +fuel: Nat) -> Y.SRes:
  match ra:
    case Ty.Tok{v}:
      match v:
        case Ty.T_brep{+b}:
          bulk_c(B4.brep_checked(b, Ty.P_manifold_solid{}, fuel),
            b, fuel)
        case _:
          att_go(att_tag(vs, es, ces, lps, fas, shs, sos, stamp,
            fuel))
    case Ty.Terr{kind}:
      att_go(att_tag(vs, es, ces, lps, fas, shs, sos, stamp,
        fuel))

# --- Box builder: exact on all validated inputs by identical
# computation. Vertices are single F64.adds of corner+dim; every
# edge/trim eval replays the identical add, so C04's exact
# coincidence checks hold bit-for-bit. Edges run min->max with
# d=+dim over dom [0,1]; trims are in edge (v0->v1) order. ---

def box_fin(+x0: F64, +y0: F64, +z0: F64, +dx: F64, +dy: F64,
    +dz: F64) -> Bool:
  Bool.and(T.is_finite(x0),
    Bool.and(T.is_finite(y0),
      Bool.and(T.is_finite(z0),
        Bool.and(T.is_finite(dx),
          Bool.and(T.is_finite(dy), T.is_finite(dz))))))

def box_pos(+dx: F64, +dy: F64, +dz: F64) -> Bool:
  Bool.and(F64.is_gt(dx, 0.0f64),
    Bool.and(F64.is_gt(dy, 0.0f64), F64.is_gt(dz, 0.0f64)))

def box_sum_fin(+x0: F64, +y0: F64, +z0: F64, +dx: F64,
    +dy: F64, +dz: F64) -> Bool:
  Bool.and(T.is_finite(F64.add(x0, dx)),
    Bool.and(T.is_finite(F64.add(y0, dy)),
      T.is_finite(F64.add(z0, dz))))

# Positional handle refs into the push order below: 8 vertices
# (gens 1-8), 12 edges (9-20), 24 coedges (21-44), 6 loops
# (45-50), 6 faces (51-56), shell 57, solid 58.
def hv_ref(+i: Nat) -> Ty.HVertex:
  Ty.mk_hv(i, (1u64 + U64.from_nat(i) : U64))

def he_ref(+i: Nat) -> Ty.HEdge:
  Ty.mk_he(i, (9u64 + U64.from_nat(i) : U64))

def hc_ref(+i: Nat) -> Ty.HCoedge:
  Ty.mk_hc(i, (21u64 + U64.from_nat(i) : U64))

def hlp_ref(+i: Nat) -> Ty.HLoop:
  Ty.mk_hlp(i, (45u64 + U64.from_nat(i) : U64))

def hfa_ref(+i: Nat) -> Ty.HFace:
  Ty.mk_hfa(i, (51u64 + U64.from_nat(i) : U64))

def ek_x(+p: V.Point, +dx: F64) -> Ty.EdgeKind:
  Ty.EK_curve{G.GV_ln{G.Ln{p, V.Dr{dx, 0.0f64, 0.0f64}}},
    G.Dom{0.0f64, 1.0f64}}

def ek_y(+p: V.Point, +dy: F64) -> Ty.EdgeKind:
  Ty.EK_curve{G.GV_ln{G.Ln{p, V.Dr{0.0f64, dy, 0.0f64}}},
    G.Dom{0.0f64, 1.0f64}}

def ek_z(+p: V.Point, +dz: F64) -> Ty.EdgeKind:
  Ty.EK_curve{G.GV_ln{G.Ln{p, V.Dr{0.0f64, 0.0f64, dz}}},
    G.Dom{0.0f64, 1.0f64}}

def ts2(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> G.GVal:
  G.GV_ts{G.Ts{V.V2{ax, ay}, V.V2{bx, by}}}

def pl_o(+o: V.Point, +u: V.Dir, +v: V.Dir) -> G.GVal:
  G.GV_pl{G.Pl{o, u, v}}

def box_core(+x0: F64, +y0: F64, +z0: F64, +dx: F64, +dy: F64,
    +dz: F64) -> Ty.Brep:
  +x1 = F64.add(x0, dx)
  +y1 = F64.add(y0, dy)
  +z1 = F64.add(z0, dz)
  +ndy = F64.sub(0.0f64, dy)
  +nm1 = F64.sub(0.0f64, 1.0f64)
  b0 = Ty.brep_empty()
  b1 = Ty.tres_brep(Ty.vx_push(b0, V.Pt{x0, y0, z0}))
  b2 = Ty.tres_brep(Ty.vx_push(b1, V.Pt{x1, y0, z0}))
  b3 = Ty.tres_brep(Ty.vx_push(b2, V.Pt{x1, y1, z0}))
  b4 = Ty.tres_brep(Ty.vx_push(b3, V.Pt{x0, y1, z0}))
  b5 = Ty.tres_brep(Ty.vx_push(b4, V.Pt{x0, y0, z1}))
  b6 = Ty.tres_brep(Ty.vx_push(b5, V.Pt{x1, y0, z1}))
  b7 = Ty.tres_brep(Ty.vx_push(b6, V.Pt{x1, y1, z1}))
  b8 = Ty.tres_brep(Ty.vx_push(b7, V.Pt{x0, y1, z1}))
  b9 = Ty.tres_brep(Ty.ed_push(b8, hv_ref(0n), hv_ref(1n),
    ek_x(V.Pt{x0, y0, z0}, dx)))
  b10 = Ty.tres_brep(Ty.ed_push(b9, hv_ref(1n), hv_ref(2n),
    ek_y(V.Pt{x1, y0, z0}, dy)))
  b11 = Ty.tres_brep(Ty.ed_push(b10, hv_ref(3n), hv_ref(2n),
    ek_x(V.Pt{x0, y1, z0}, dx)))
  b12 = Ty.tres_brep(Ty.ed_push(b11, hv_ref(0n), hv_ref(3n),
    ek_y(V.Pt{x0, y0, z0}, dy)))
  b13 = Ty.tres_brep(Ty.ed_push(b12, hv_ref(4n), hv_ref(5n),
    ek_x(V.Pt{x0, y0, z1}, dx)))
  b14 = Ty.tres_brep(Ty.ed_push(b13, hv_ref(5n), hv_ref(6n),
    ek_y(V.Pt{x1, y0, z1}, dy)))
  b15 = Ty.tres_brep(Ty.ed_push(b14, hv_ref(7n), hv_ref(6n),
    ek_x(V.Pt{x0, y1, z1}, dx)))
  b16 = Ty.tres_brep(Ty.ed_push(b15, hv_ref(4n), hv_ref(7n),
    ek_y(V.Pt{x0, y0, z1}, dy)))
  b17 = Ty.tres_brep(Ty.ed_push(b16, hv_ref(0n), hv_ref(4n),
    ek_z(V.Pt{x0, y0, z0}, dz)))
  b18 = Ty.tres_brep(Ty.ed_push(b17, hv_ref(1n), hv_ref(5n),
    ek_z(V.Pt{x1, y0, z0}, dz)))
  b19 = Ty.tres_brep(Ty.ed_push(b18, hv_ref(2n), hv_ref(6n),
    ek_z(V.Pt{x1, y1, z0}, dz)))
  b20 = Ty.tres_brep(Ty.ed_push(b19, hv_ref(3n), hv_ref(7n),
    ek_z(V.Pt{x0, y1, z0}, dz)))
  b21 = Ty.tres_brep(Ty.ce_push(b20, he_ref(3n), True{},
    ts2(0.0f64, 0.0f64, 0.0f64, ndy)))
  b22 = Ty.tres_brep(Ty.ce_push(b21, he_ref(2n), True{},
    ts2(0.0f64, ndy, dx, ndy)))
  b23 = Ty.tres_brep(Ty.ce_push(b22, he_ref(1n), False{},
    ts2(dx, 0.0f64, dx, ndy)))
  b24 = Ty.tres_brep(Ty.ce_push(b23, he_ref(0n), False{},
    ts2(0.0f64, 0.0f64, dx, 0.0f64)))
  b25 = Ty.tres_brep(Ty.ce_push(b24, he_ref(4n), True{},
    ts2(0.0f64, 0.0f64, dx, 0.0f64)))
  b26 = Ty.tres_brep(Ty.ce_push(b25, he_ref(5n), True{},
    ts2(dx, 0.0f64, dx, dy)))
  b27 = Ty.tres_brep(Ty.ce_push(b26, he_ref(6n), False{},
    ts2(0.0f64, dy, dx, dy)))
  b28 = Ty.tres_brep(Ty.ce_push(b27, he_ref(7n), False{},
    ts2(0.0f64, 0.0f64, 0.0f64, dy)))
  b29 = Ty.tres_brep(Ty.ce_push(b28, he_ref(0n), True{},
    ts2(0.0f64, 0.0f64, dx, 0.0f64)))
  b30 = Ty.tres_brep(Ty.ce_push(b29, he_ref(9n), True{},
    ts2(dx, 0.0f64, dx, dz)))
  b31 = Ty.tres_brep(Ty.ce_push(b30, he_ref(4n), False{},
    ts2(0.0f64, dz, dx, dz)))
  b32 = Ty.tres_brep(Ty.ce_push(b31, he_ref(8n), False{},
    ts2(0.0f64, 0.0f64, 0.0f64, dz)))
  b33 = Ty.tres_brep(Ty.ce_push(b32, he_ref(2n), False{},
    ts2(0.0f64, 0.0f64, 0.0f64, dx)))
  b34 = Ty.tres_brep(Ty.ce_push(b33, he_ref(11n), True{},
    ts2(0.0f64, 0.0f64, dz, 0.0f64)))
  b35 = Ty.tres_brep(Ty.ce_push(b34, he_ref(6n), True{},
    ts2(dz, 0.0f64, dz, dx)))
  b36 = Ty.tres_brep(Ty.ce_push(b35, he_ref(10n), False{},
    ts2(0.0f64, dx, dz, dx)))
  b37 = Ty.tres_brep(Ty.ce_push(b36, he_ref(8n), True{},
    ts2(0.0f64, 0.0f64, dz, 0.0f64)))
  b38 = Ty.tres_brep(Ty.ce_push(b37, he_ref(7n), True{},
    ts2(dz, 0.0f64, dz, dy)))
  b39 = Ty.tres_brep(Ty.ce_push(b38, he_ref(11n), False{},
    ts2(0.0f64, dy, dz, dy)))
  b40 = Ty.tres_brep(Ty.ce_push(b39, he_ref(3n), False{},
    ts2(0.0f64, 0.0f64, 0.0f64, dy)))
  b41 = Ty.tres_brep(Ty.ce_push(b40, he_ref(1n), True{},
    ts2(0.0f64, 0.0f64, dy, 0.0f64)))
  b42 = Ty.tres_brep(Ty.ce_push(b41, he_ref(10n), True{},
    ts2(dy, 0.0f64, dy, dz)))
  b43 = Ty.tres_brep(Ty.ce_push(b42, he_ref(5n), False{},
    ts2(0.0f64, dz, dy, dz)))
  b44 = Ty.tres_brep(Ty.ce_push(b43, he_ref(9n), False{},
    ts2(0.0f64, 0.0f64, 0.0f64, dz)))
  b45 = Ty.tres_brep(Ty.lp_push(b44,
    [hc_ref(0n), hc_ref(1n), hc_ref(2n), hc_ref(3n)],
    Ty.LK_outer{}))
  b46 = Ty.tres_brep(Ty.lp_push(b45,
    [hc_ref(4n), hc_ref(5n), hc_ref(6n), hc_ref(7n)],
    Ty.LK_outer{}))
  b47 = Ty.tres_brep(Ty.lp_push(b46,
    [hc_ref(8n), hc_ref(9n), hc_ref(10n), hc_ref(11n)],
    Ty.LK_outer{}))
  b48 = Ty.tres_brep(Ty.lp_push(b47,
    [hc_ref(12n), hc_ref(13n), hc_ref(14n), hc_ref(15n)],
    Ty.LK_outer{}))
  b49 = Ty.tres_brep(Ty.lp_push(b48,
    [hc_ref(16n), hc_ref(17n), hc_ref(18n), hc_ref(19n)],
    Ty.LK_outer{}))
  b50 = Ty.tres_brep(Ty.lp_push(b49,
    [hc_ref(20n), hc_ref(21n), hc_ref(22n), hc_ref(23n)],
    Ty.LK_outer{}))
  b51 = Ty.tres_brep(Ty.fa_push(b50,
    pl_o(V.Pt{x0, y0, z0}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, nm1, 0.0f64}),
    [hlp_ref(0n)], True{}))
  b52 = Ty.tres_brep(Ty.fa_push(b51,
    pl_o(V.Pt{x0, y0, z1}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 1.0f64, 0.0f64}),
    [hlp_ref(1n)], True{}))
  b53 = Ty.tres_brep(Ty.fa_push(b52,
    pl_o(V.Pt{x0, y0, z0}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 1.0f64}),
    [hlp_ref(2n)], True{}))
  b54 = Ty.tres_brep(Ty.fa_push(b53,
    pl_o(V.Pt{x0, y1, z0}, V.Dr{0.0f64, 0.0f64, 1.0f64},
      V.Dr{1.0f64, 0.0f64, 0.0f64}),
    [hlp_ref(3n)], True{}))
  b55 = Ty.tres_brep(Ty.fa_push(b54,
    pl_o(V.Pt{x0, y0, z0}, V.Dr{0.0f64, 0.0f64, 1.0f64},
      V.Dr{0.0f64, 1.0f64, 0.0f64}),
    [hlp_ref(4n)], True{}))
  b56 = Ty.tres_brep(Ty.fa_push(b55,
    pl_o(V.Pt{x1, y0, z0}, V.Dr{0.0f64, 1.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 1.0f64}),
    [hlp_ref(5n)], True{}))
  b57 = Ty.tres_brep(Ty.sh_push(b56,
    [hfa_ref(0n), hfa_ref(1n), hfa_ref(2n), hfa_ref(3n),
      hfa_ref(4n), hfa_ref(5n)],
    Ty.SK_outer{}))
  b58 = Ty.tres_brep(Ty.so_push(b57, Ty.mk_hsh(0n, 57u64),
    []))
  Ty.brep_set_top(b58, Ty.Cp{[Ty.mk_hso(0n, 58u64)], []})

def box_go(allfin: Bool, dimspos: Bool, sumfin: Bool, +x0: F64,
    +y0: F64, +z0: F64, +dx: F64, +dy: F64, +dz: F64,
    +fuel: Nat) -> Y.SRes:
  match allfin:
    case False{}:
      Y.serr_invalid("corner/dims", "box_checked",
        "non-finite corner or dim", "pass finite F64 inputs")
    case True{}:
      match dimspos:
        case False{}:
          Y.serr_invalid("dims", "box_checked",
            "non-positive dim", "pass strictly positive dims")
        case True{}:
          match sumfin:
            case False{}:
              Y.serr_uncertain("far corner", "box_checked",
                "corner+dim overflows F64",
                "shrink the box or move it toward origin")
            case True{}:
              +b = box_core(x0, y0, z0, dx, dy, dz)
              bulk_c(B4.brep_checked(b, Ty.P_manifold_solid{},
                  fuel), b, fuel)
def box_checked(+x0: F64, +y0: F64, +z0: F64, +dx: F64,
    +dy: F64, +dz: F64, +fuel: Nat) -> Y.SRes:
  box_go(box_fin(x0, y0, z0, dx, dy, dz), box_pos(dx, dy, dz),
    box_sum_fin(x0, y0, z0, dx, dy, dz), x0, y0, z0, dx, dy,
    dz, fuel)

# --- C06 quad-trim check (surfx conventions): a parametric point on
# a quadric surface must evaluate to a finite point. Non-quad
# surfaces are caller error (the C04 stages own plane/bezier
# trims); G-layer failures keep their kind; non-finite points are
# representability failures, never snapped. Success is sok_u(0),
# the prof_go convention. ---
def trim_quad_fin(fx: Bool, fy: Bool, fz: Bool) -> Y.SRes:
  match fx:
    case False{}:
      Y.serr_uncertain("quad trim", "trim_quad",
        "nonfinite-point", "shrink the coordinates")
    case True{}:
      match fy:
        case False{}:
          Y.serr_uncertain("quad trim", "trim_quad",
            "nonfinite-point", "shrink the coordinates")
        case True{}:
          match fz:
            case False{}:
              Y.serr_uncertain("quad trim", "trim_quad",
                "nonfinite-point", "shrink the coordinates")
            case True{}: Y.sok_u(0u64)

def trim_quad_pt(p: V.Point) -> Y.SRes:
  V.Pt{+x, +y, +z} = p
  trim_quad_fin(T.is_finite(x), T.is_finite(y),
    T.is_finite(z))

def trim_quad_v(v: G.GVal) -> Y.SRes:
  match v:
    case G.GV_p{p}: trim_quad_pt(p)
    case _:
      Y.serr_unsupported("quad trim", "trim_quad",
        "internal-trim", "internal: report this")

def trim_quad_map(r: G.GRes) -> Y.SRes:
  match r:
    case G.Gok{v}: trim_quad_v(v)
    case G.Gerr{kind}:
      Y.serr(kind,
        Y.mk_diag("quad trim", "trim_quad", "eval-failed",
          "check the (u,v) domain and radii"))

def trim_quad_go(quad: Bool, s: G.GVal, +u: F64,
    +v: F64) -> Y.SRes:
  match quad:
    case True{}: trim_quad_map(SX.surf_at(s, u, v))
    case False{}:
      Y.serr_invalid("surface", "trim_quad", "not-quad",
        "route plane/bezier trims through the C04 stages")

def trim_quad(+s: G.GVal, +u: F64, +v: F64) -> Y.SRes:
  trim_quad_go(SX.surf_is_quad(s), s, u, v)

# --- Box measure: certified volume/area intervals over the dims
# (outward-rounded, so they enclose the true reals), exact bbox
# corners replaying box_core's adds, entity counts from the brep.
# Bad inputs are invalid; enclosure overflow is uncertain. ---
def ms_bin_iv(op: U64, x: Y.Iv, y: Y.Iv) -> Y.SRes:
  match op:
    case 0u64: iv_add(x, y)
    case _: iv_mul(x, y)

def ms_bin_vb(op: U64, x: Y.Iv, vb: Y.SVal) -> Y.SRes:
  match vb:
    case Y.SV_iv{y}: ms_bin_iv(op, x, y)
    case _:
      Y.serr_unsupported("measure", "ms_box",
        "internal-measure", "internal: report this")

def ms_bin_vv(op: U64, va: Y.SVal, vb: Y.SVal) -> Y.SRes:
  match va:
    case Y.SV_iv{x}: ms_bin_vb(op, x, vb)
    case _:
      Y.serr_unsupported("measure", "ms_box",
        "internal-measure", "internal: report this")

def ms_bin_r(op: U64, va: Y.SVal, b: Y.SRes) -> Y.SRes:
  match b:
    case Y.Serr{k, dg}: Y.Serr{k, dg}
    case Y.Sok{vb}: ms_bin_vv(op, va, vb)

def ms_bin2(op: U64, a: Y.SRes, b: Y.SRes) -> Y.SRes:
  match a:
    case Y.Serr{k, dg}: Y.Serr{k, dg}
    case Y.Sok{va}: ms_bin_r(op, va, b)

def ms_asm_va(vol: Y.Iv, va: Y.SVal, +x0: F64, +y0: F64,
    +z0: F64, +dx: F64, +dy: F64, +dz: F64,
    +b: Ty.Brep) -> Y.SRes:
  match va:
    case Y.SV_iv{area}:
      Y.sok_ms(Y.mk_ms(vol, area, V.Pt{x0, y0, z0},
        V.Pt{F64.add(x0, dx), F64.add(y0, dy),
          F64.add(z0, dz)},
        List.length(&2, Ty.Vertex, Ty.brep_vs(b)),
        List.length(&2, Ty.Edge, Ty.brep_es(b)),
        List.length(&2, Ty.Face, Ty.brep_fas(b))))
    case _:
      Y.serr_unsupported("measure", "ms_box",
        "internal-measure", "internal: report this")

def ms_asm_vv(vv: Y.SVal, va: Y.SVal, +x0: F64, +y0: F64,
    +z0: F64, +dx: F64, +dy: F64, +dz: F64,
    +b: Ty.Brep) -> Y.SRes:
  match vv:
    case Y.SV_iv{vol}:
      ms_asm_va(vol, va, x0, y0, z0, dx, dy, dz, b)
    case _:
      Y.serr_unsupported("measure", "ms_box",
        "internal-measure", "internal: report this")

def ms_asm_r(vv: Y.SVal, ra: Y.SRes, +x0: F64, +y0: F64,
    +z0: F64, +dx: F64, +dy: F64, +dz: F64,
    +b: Ty.Brep) -> Y.SRes:
  match ra:
    case Y.Serr{k, dg}: Y.Serr{k, dg}
    case Y.Sok{va}: ms_asm_vv(vv, va, x0, y0, z0, dx, dy, dz, b)

def ms_asm(rv: Y.SRes, ra: Y.SRes, +x0: F64, +y0: F64,
    +z0: F64, +dx: F64, +dy: F64, +dz: F64,
    +b: Ty.Brep) -> Y.SRes:
  match rv:
    case Y.Serr{k, dg}: Y.Serr{k, dg}
    case Y.Sok{vv}: ms_asm_r(vv, ra, x0, y0, z0, dx, dy, dz, b)

def ms_box_go(fin: Bool, pos: Bool, sumfin: Bool, +dx: F64,
    +dy: F64, +dz: F64, +x0: F64, +y0: F64, +z0: F64,
    +b: Ty.Brep) -> Y.SRes:
  match fin:
    case False{}:
      Y.serr_invalid("corner/dims", "ms_box",
        "non-finite corner or dim", "pass finite F64 inputs")
    case True{}:
      match pos:
        case False{}:
          Y.serr_invalid("dims", "ms_box",
            "non-positive dim", "pass strictly positive dims")
        case True{}:
          match sumfin:
            case False{}:
              Y.serr_uncertain("far corner", "ms_box",
                "corner+dim overflows F64",
                "shrink the box or move it toward origin")
            case True{}:
              ms_asm(ms_bin2(1u64, iv_mul(iv_pt(dx), iv_pt(dy)),
                  Y.sok_iv(iv_pt(dz))),
                ms_bin2(1u64,
                  ms_bin2(0u64,
                    ms_bin2(0u64, iv_mul(iv_pt(dx), iv_pt(dy)),
                      iv_mul(iv_pt(dy), iv_pt(dz))),
                    iv_mul(iv_pt(dz), iv_pt(dx))),
                  Y.sok_iv(iv_pt(2.0f64))),
                x0, y0, z0, dx, dy, dz, b)

def ms_box(+dx: F64, +dy: F64, +dz: F64, +x0: F64,
    +y0: F64, +z0: F64, +b: Ty.Brep) -> Y.SRes:
  ms_box_go(box_fin(x0, y0, z0, dx, dy, dz),
    box_pos(dx, dy, dz),
    box_sum_fin(x0, y0, z0, dx, dy, dz),
    dx, dy, dz, x0, y0, z0, b)

# Volume over the tolerance zones. iv_of_dm is the factor. The
# nominal-point product is a different function, so a law can see
# a substitution of nom for [lo, hi].
def ms_zone_ok(+w: Y.Dim, +h: Y.Dim, +d: Y.Dim) -> Bool:
  Bool.and(Y.dm_valid_pos(w),
    Bool.and(Y.dm_valid_pos(h), Y.dm_valid_pos(d)))

def ms_zone_vol(+w: Y.Dim, +h: Y.Dim, +d: Y.Dim) -> Y.SRes:
  ms_bin2(1u64, iv_mul(Y.iv_of_dm(w), Y.iv_of_dm(h)),
    Y.sok_iv(Y.iv_of_dm(d)))

def ms_nom_vol(+w: Y.Dim, +h: Y.Dim, +d: Y.Dim) -> Y.SRes:
  ms_bin2(1u64, iv_mul(iv_pt(Y.dm_nom(w)), iv_pt(Y.dm_nom(h))),
    Y.sok_iv(iv_pt(Y.dm_nom(d))))

def ms_zone_go(ok: Bool, +w: Y.Dim, +h: Y.Dim, +d: Y.Dim) -> Y.SRes:
  match ok:
    case False{}:
      Y.serr_invalid("dims", "ms_zone", "zone",
        "lo <= nom <= hi and lo > 0")
    case True{}: ms_zone_vol(w, h, d)

def ms_zone(+w: Y.Dim, +h: Y.Dim, +d: Y.Dim) -> Y.SRes:
  ms_zone_go(ms_zone_ok(w, h, d), w, h, d)

