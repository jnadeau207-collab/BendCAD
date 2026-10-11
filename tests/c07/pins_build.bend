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

def dom(+a: F64, +b: F64) -> G.Dom:
  G.Dom{a, b}

def circ() -> G.GVal:
  G.GV_cc{G.Cc{pt(0.0f64, 0.0f64, 0.0f64), dr(1.0f64, 0.0f64, 0.0f64), dr(0.0f64, 1.0f64, 0.0f64), 2.0f64}}

def xline() -> G.GVal:
  G.GV_ln{G.Ln{pt(0.0f64, 0.0f64, 0.0f64), dr(1.0f64, 0.0f64, 0.0f64)}}

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

def first_cls(hs: List<&2, S.Hit>) -> U64:
  match hs:
    case []: 999u64
    case h <> t:
      match h:
        case S.H_pt{s, u, p, c}: c
        case _: first_cls(t)

def i0() -> I.I:
  I.ipt(0.0f64)

def i1() -> I.I:
  I.ipt(1.0f64)

def xk(+v: F64) -> X.Xp:
  X.X_k{v}

def full() -> R.Cv:
  R.cv_circle(pt(0.0f64, 0.0f64, 0.0f64), dr(1.0f64, 0.0f64, 0.0f64), dr(0.0f64, 1.0f64, 0.0f64), 2.0f64, F64.neg(1.0f64), 1.0f64)

def p2(+x: F64, +y: F64) -> List<&2, I.I>:
  [I.ipt(x), I.ipt(y)]

def seg(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> ZT.Pm:
  ZT.Pl{p2(ax, ay), p2(bx, by), xk(ax), xk(bx)}

def disc_im() -> M.Im:
  M.M_pl{[i0(), i0(), i0()], [i0(), i0(), i1()]}

def flat_line() -> R.Cv:
  R.cv_line(pt(0.0f64, 0.0f64, 0.0f64), dr(1.0f64, 1.0f64, 0.0f64), 0.0f64, 1.0f64)

def rise_line() -> R.Cv:
  R.cv_line(pt(0.0f64, 0.0f64, F64.neg(1.0f64)), dr(0.0f64, 0.0f64, 1.0f64), 0.0f64, 2.0f64)

def tan_conic() -> G.GVal:
  G.GV_rq{G.Rq{pt(8.0f64, 50.0f64, 0.0f64), pt(0.0f64, 50.0f64, 0.0f64), pt(0.0f64, 42.0f64, 0.0f64), 1.0f64, 0.7071067811865476f64, 1.0f64}}

def yz_plane() -> G.GVal:
  G.GV_pl{G.Pl{pt(0.0f64, 0.0f64, 0.0f64), dr(0.0f64, 1.0f64, 0.0f64), dr(0.0f64, 0.0f64, 1.0f64)}}

def ok_full_circle_hbox__got() -> Bool:
  IX.vfin(R.cv_hbox(full()))

def ok_full_circle_hbox__want() -> Bool:
  True{}

def ok_arcs_complementary_points__got() -> Nat:
  n_pt(S.inter_cc(circ(), dom(0.0f64, 1.0f64), circ(), dom(F64.neg(1.0f64), 0.0f64), 40n))

def ok_arcs_complementary_points__want() -> Nat:
  2n

def ok_arcs_complementary_no_overlap__got() -> Nat:
  n_ov(S.inter_cc(circ(), dom(0.0f64, 1.0f64), circ(), dom(F64.neg(1.0f64), 0.0f64), 40n))

def ok_arcs_complementary_no_overlap__want() -> Nat:
  0n

def ok_arcs_overlap__got() -> Nat:
  n_ov(S.inter_cc(circ(), dom(F64.neg(0.5f64), 0.5f64), circ(), dom(0.0f64, 1.0f64), 40n))

def ok_arcs_overlap__want() -> Nat:
  1n

def ok_lines_touch__got() -> Nat:
  n_pt(S.inter_cc(xline(), dom(0.0f64, 6.0f64), xline(), dom(F64.neg(6.0f64), 0.0f64), 40n))

def ok_lines_touch__want() -> Nat:
  1n

def neg_lines_touch_overlap__got() -> Nat:
  n_ov(S.inter_cc(xline(), dom(0.0f64, 6.0f64), xline(), dom(F64.neg(6.0f64), 0.0f64), 40n))

def neg_lines_touch_overlap__want() -> Nat:
  0n

def ok_tangent_endpoint_class__got() -> U64:
  first_cls(S.inter_cs(tan_conic(), dom(0.0f64, 1.0f64), yz_plane(), 40n))

def ok_tangent_endpoint_class__want() -> U64:
  34u64

def ok_semicircle_sweep__got() -> Bool:
  ZT.in_02pi(ZT.sweep(p2(0.0f64, 0.0f64), p2(1.0f64, 0.0f64), p2(F64.neg(1.0f64), 0.0f64), True{}))

def ok_semicircle_sweep__want() -> Bool:
  True{}

def ok_corner_square__got() -> Bool:
  ZT.cone(seg(0.0f64, 0.0f64, 1.0f64, 0.0f64), seg(1.0f64, 0.0f64, 1.0f64, 1.0f64), True{}, False{}, 0.125f64)

def ok_corner_square__want() -> Bool:
  True{}

def neg_corner_foldback__got() -> Bool:
  ZT.cone(seg(0.0f64, 0.0f64, 1.0f64, 0.0f64), seg(1.0f64, 0.0f64, 0.0f64, 0.0f64), True{}, False{}, 0.125f64)

def neg_corner_foldback__want() -> Bool:
  False{}

def ok_separated_segments__got() -> Bool:
  ZT.sep_in(seg(0.0f64, 0.0f64, 1.0f64, 0.0f64), seg(0.0f64, 1.0f64, 1.0f64, 1.0f64), I.I{0.0f64, 1.0f64}, I.I{0.0f64, 1.0f64})

def ok_separated_segments__want() -> Bool:
  True{}

def neg_crossing_segments__got() -> Bool:
  ZT.sep_in(seg(0.0f64, 0.0f64, 1.0f64, 1.0f64), seg(0.0f64, 1.0f64, 1.0f64, 0.0f64), I.I{0.0f64, 1.0f64}, I.I{0.0f64, 1.0f64})

def neg_crossing_segments__want() -> Bool:
  False{}

def ok_flat_edge_in_cut__got() -> Bool:
  Mm.flat(flat_line(), disc_im())

def ok_flat_edge_in_cut__want() -> Bool:
  True{}

def neg_flat_edge_crossing__got() -> Bool:
  Mm.flat(rise_line(), disc_im())

def neg_flat_edge_crossing__want() -> Bool:
  False{}

def ok_finish_even_keeps_arrival__got() -> U64:
  Mm.finish(Mm.Cn{2n, False{}}, 1u64)

def ok_finish_even_keeps_arrival__want() -> U64:
  1u64

def ok_finish_odd_flips_arrival__got() -> U64:
  Mm.finish(Mm.Cn{1n, False{}}, 1u64)

def ok_finish_odd_flips_arrival__want() -> U64:
  0u64

def ok_finish_uncertain__got() -> Bool:
  Bool.and(U64.is_eq(Mm.finish(Mm.Cn{1n, True{}}, 1u64), 2u64), U64.is_eq(Mm.finish(Mm.Cn{2n, False{}}, 2u64), 2u64))

def ok_finish_uncertain__want() -> Bool:
  True{}
