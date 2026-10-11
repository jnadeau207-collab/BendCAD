import Base

import ../../src/c01/types.bend as V

import ../../src/c03/types.bend as G

import ../../src/c06/iv.bend as I

import ../../src/c06/xp.bend as X

import ../../src/c06/revolve.bend as RV

import ../../src/c07/ivx.bend as IX

import ../../src/c07/rb.bend as R

import ../../src/c07/im.bend as M

import ../../src/c07/xs.bend as S

import ../../src/c07/mem.bend as Mm

import ../../src/c07/sym.bend as Y

import ../../src/c07/zd.bend as D

import ../../src/c07/zt.bend as ZT

def pt(+x: F64, +y: F64, +z: F64) -> V.Point:
  V.Pt{x, y, z}

def dr(+x: F64, +y: F64, +z: F64) -> V.Dir:
  V.Dr{x, y, z}

def i0() -> I.I:
  I.ipt(0.0f64)

def i1() -> I.I:
  I.ipt(1.0f64)

def xa() -> X.Xp:
  X.X_p{1u64}

def xb() -> X.Xp:
  X.X_p{2u64}

def xk(+v: F64) -> X.Xp:
  X.X_k{v}

def sq_sum() -> X.Xp:
  X.X_sub{X.X_mul{X.X_add{xa(), xb()}, X.X_add{xa(), xb()}}, X.X_add{X.X_add{X.X_mul{xa(), xa()}, X.X_mul{X.X_mul{xk(2.0f64), xa()}, xb()}}, X.X_mul{xb(), xb()}}}

def bez() -> R.Cv:
  R.cv_bez([pt(0.0f64, 0.0f64, 0.0f64), pt(0.0f64, 0.0f64, 0.0f64), pt(3.0f64, 0.0f64, 9.0f64), pt(3.0f64, 0.0f64, 9.0f64)], 0.0f64, 1.0f64)

def full() -> R.Cv:
  R.cv_circle(pt(0.0f64, 0.0f64, 0.0f64), dr(1.0f64, 0.0f64, 0.0f64), dr(0.0f64, 1.0f64, 0.0f64), 2.0f64, F64.neg(1.0f64), 1.0f64)

def co_az_g(g: G.GVal) -> F64:
  match g:
    case G.GV_co{w}:
      G.Co{o, a, k} = w
      V.dr_z(a)
    case _: F64.nan()

def co_az(s: RV.SS) -> F64:
  RV.SS{ok, g, same, plane} = s
  co_az_g(g)

def dom(+a: F64, +b: F64) -> G.Dom:
  G.Dom{a, b}

def xline() -> G.GVal:
  G.GV_ln{G.Ln{pt(0.0f64, 0.0f64, 0.0f64), dr(1.0f64, 0.0f64, 0.0f64)}}

def circ_g() -> G.GVal:
  G.GV_cc{G.Cc{pt(0.0f64, 0.0f64, 0.0f64), dr(1.0f64, 0.0f64, 0.0f64), dr(0.0f64, 1.0f64, 0.0f64), 2.0f64}}

def n_pt(hs: List<&2, S.Hit>) -> Nat:
  match hs:
    case []: 0n
    case h <> t:
      match h:
        case S.H_pt{s, u, p, c}: Nat.add(1n, n_pt(t))
        case _: n_pt(t)

def n_ov(hs: List<&2, S.Hit>) -> Nat:
  match hs:
    case []: 0n
    case h <> t:
      match h:
        case S.H_ov{s, u}: Nat.add(1n, n_ov(t))
        case _: n_ov(t)

def near_iv(+s: I.I, +lo: F64, +hi: F64) -> Bool:
  Bool.and(F64.is_le(I.i_lo(s), lo), Bool.and(F64.is_le(hi, I.i_hi(s)), Bool.and(F64.is_lt(F64.sub(lo, 0.000001f64), I.i_lo(s)), F64.is_lt(I.i_hi(s), F64.add(hi, 0.000001f64)))))

def span_le(hs: List<&2, S.Hit>, +slo: F64, +shi: F64, +tlo: F64, +thi: F64) -> Bool:
  match hs:
    case []: False{}
    case h <> t:
      match h:
        case S.H_ov{s, u}: Bool.and(near_iv(s, slo, shi), near_iv(u, tlo, thi))
        case _: span_le(t, slo, shi, tlo, thi)

def one_span(+hs: List<&2, S.Hit>, +slo: F64, +shi: F64, +tlo: F64, +thi: F64) -> Bool:
  Bool.and(Nat.is_eq(n_pt(hs), 0n), Bool.and(Nat.is_eq(n_ov(hs), 1n), span_le(hs, slo, shi, tlo, thi)))

def ok_grad_unit_first__got() -> List<&2, I.I>:
  D.ge(3n, 0n)

def ok_grad_unit_first__want() -> List<&2, I.I>:
  [i1(), i0(), i0()]

def ok_grad_unit_mid__got() -> List<&2, I.I>:
  D.ge(3n, 1n)

def ok_grad_unit_mid__want() -> List<&2, I.I>:
  [i0(), i1(), i0()]

def ok_grad_unit_last__got() -> List<&2, I.I>:
  D.ge(3n, 2n)

def ok_grad_unit_last__want() -> List<&2, I.I>:
  [i0(), i0(), i1()]

def ok_sym_binomial__got() -> Bool:
  Y.is_zero(sq_sum())

def ok_sym_binomial__want() -> Bool:
  True{}

def neg_sym_distinct__got() -> Bool:
  Y.is_zero(X.X_sub{xa(), xb()})

def neg_sym_distinct__want() -> Bool:
  False{}

def ok_sym_quotient__got() -> Bool:
  Y.same(X.X_div{X.X_mul{xa(), xb()}, xb()}, xa())

def ok_sym_quotient__want() -> Bool:
  True{}

def ok_arc_identity__got() -> Bool:
  ZT.on_circ(xa(), xb(), X.X_sub{xa(), xb()}, xb(), xb())

def ok_arc_identity__want() -> Bool:
  True{}

def neg_arc_identity__got() -> Bool:
  ZT.on_circ(xk(10.0f64), X.X_add{xa(), xb()}, xk(10.0f64), xa(), xa())

def neg_arc_identity__want() -> Bool:
  False{}

def ok_restr_whole_exact__got() -> R.Rb:
  R.cv_rb(bez())

def ok_restr_whole_exact__want() -> R.Rb:
  R.Rb{[I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(3.0f64), I.ipt(3.0f64)], [i0(), i0(), i0(), i0()], [I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(9.0f64), I.ipt(9.0f64)], [i1(), i1(), i1(), i1()]}

def neg_full_circle_whole_box__got() -> Bool:
  IX.vfin(R.cv_box(full(), I.I{0.0f64, 1.0f64}))

def neg_full_circle_whole_box__want() -> Bool:
  False{}

def ok_class_mask__got() -> Bool:
  S.has_cls([S.H_pt{i0(), i0(), [i0(), i0(), i0()], 33u64}], 1u64)

def ok_class_mask__want() -> Bool:
  True{}

def ok_cone_axis_below_apex__got() -> F64:
  co_az(RV.ss_cone(RV.CN{True{}, 9.0f64, 0.6666666666666666f64}, 6.0f64, 0.0f64, 0.0f64, 9.0f64))

def ok_cone_axis_below_apex__want() -> F64:
  F64.neg(1.0f64)

def ok_lines_overlap_span__got() -> Bool:
  one_span(S.inter_cc(xline(), dom(0.0f64, 6.0f64), xline(), dom(3.0f64, 9.0f64), 8n), 3.0f64, 6.0f64, 3.0f64, 6.0f64)

def ok_lines_overlap_span__want() -> Bool:
  True{}

def ok_full_circle_only_overlap__got() -> Bool:
  one_span(S.inter_cc(circ_g(), dom(F64.neg(1.0f64), 1.0f64), circ_g(), dom(F64.neg(1.0f64), 1.0f64), 8n), F64.neg(1.0f64), 1.0f64, F64.neg(1.0f64), 1.0f64)

def ok_full_circle_only_overlap__want() -> Bool:
  True{}
