import Base
import ../src/c01/types.bend as V
import ../src/c03/types.bend as G
import ../src/c06/iv.bend as I
import ../src/c06/xp.bend as X
import ../src/c06/revolve.bend as RV
import ../src/c07/ivx.bend as IX
import ../src/c07/rb.bend as R
import ../src/c07/im.bend as M
import ../src/c07/xs.bend as S
import ../src/c07/mem.bend as Mm
import ../src/c07/sym.bend as Y
import ../src/c07/zd.bend as D
import ../src/c07/zt.bend as ZT



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

def p2(+x: F64, +y: F64) -> List<&2, I.I>:
  [I.ipt(x), I.ipt(y)]

def seg(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> ZT.Pm:
  ZT.Pl{p2(ax, ay), p2(bx, by), xk(ax), xk(bx)}

def disc() -> Mm.Fc:
  Mm.Fc{M.M_pl{[i0(), i0(), i0()], [i0(), i0(), i1()]}, True{}, [Mm.Er{full(), True{}}]}

def disc_im() -> M.Im:
  M.M_pl{[i0(), i0(), i0()], [i0(), i0(), i1()]}

def q3(+x: F64, +y: F64) -> List<&2, I.I>:
  [I.ipt(x), I.ipt(y), i0()]

def flat_line() -> R.Cv:
  R.cv_line(pt(0.0f64, 0.0f64, 0.0f64), dr(1.0f64, 1.0f64, 0.0f64), 0.0f64, 1.0f64)

def rise_line() -> R.Cv:
  R.cv_line(pt(0.0f64, 0.0f64, F64.neg(1.0f64)), dr(0.0f64, 0.0f64, 1.0f64), 0.0f64, 2.0f64)

def tan_conic() -> G.GVal:
  G.GV_rq{G.Rq{pt(8.0f64, 50.0f64, 0.0f64), pt(0.0f64, 50.0f64, 0.0f64), pt(0.0f64, 42.0f64, 0.0f64), 1.0f64, 0.7071067811865476f64, 1.0f64}}

def yz_plane() -> G.GVal:
  G.GV_pl{G.Pl{pt(0.0f64, 0.0f64, 0.0f64), dr(0.0f64, 1.0f64, 0.0f64), dr(0.0f64, 0.0f64, 1.0f64)}}

law ok_grad_unit_first:
  {D.ge(3n, 0n) == [i1(), i0(), i0()] : List<&2, I.I>}

def ok_grad_unit_first():
  {==}

law ok_grad_unit_mid:
  {D.ge(3n, 1n) == [i0(), i1(), i0()] : List<&2, I.I>}

def ok_grad_unit_mid():
  {==}

law ok_sym_binomial:
  {Y.is_zero(sq_sum()) == True{} : Bool}

def ok_sym_binomial():
  {==}

law neg_sym_distinct:
  {Y.is_zero(X.X_sub{xa(), xb()}) == False{} : Bool}

def neg_sym_distinct():
  {==}

law ok_sym_quotient:
  {Y.same(X.X_div{X.X_mul{xa(), xb()}, xb()}, xa()) == True{} : Bool}

def ok_sym_quotient():
  {==}

law ok_arc_identity:
  {ZT.on_circ(xa(), xb(), X.X_sub{xa(), xb()}, xb(), xb()) == True{} : Bool}

def ok_arc_identity():
  {==}

law neg_arc_identity:
  {ZT.on_circ(xk(10.0f64), X.X_add{xa(), xb()}, xk(10.0f64), xa(), xa()) == False{} : Bool}

def neg_arc_identity():
  {==}

law ok_restr_whole_exact:
  {R.cv_rb(bez()) == R.Rb{[I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(3.0f64), I.ipt(3.0f64)], [i0(), i0(), i0(), i0()], [I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(9.0f64), I.ipt(9.0f64)], [i1(), i1(), i1(), i1()]} : R.Rb}

def ok_restr_whole_exact():
  {==}

law neg_full_circle_whole_box:
  {IX.vfin(R.cv_box(full(), I.I{0.0f64, 1.0f64})) == False{} : Bool}

def neg_full_circle_whole_box():
  {==}

law ok_full_circle_hbox:
  {IX.vfin(R.cv_hbox(full())) == True{} : Bool}

def ok_full_circle_hbox():
  {==}

law ok_arcs_complementary_points:
  {n_pt(S.inter_cc(circ(), dom(0.0f64, 1.0f64), circ(), dom(F64.neg(1.0f64), 0.0f64), 40n)) == 2n : Nat}

def ok_arcs_complementary_points():
  {==}

law ok_arcs_complementary_no_overlap:
  {n_ov(S.inter_cc(circ(), dom(0.0f64, 1.0f64), circ(), dom(F64.neg(1.0f64), 0.0f64), 40n)) == 0n : Nat}

def ok_arcs_complementary_no_overlap():
  {==}

law ok_arcs_overlap:
  {n_ov(S.inter_cc(circ(), dom(F64.neg(0.5f64), 0.5f64), circ(), dom(0.0f64, 1.0f64), 40n)) == 1n : Nat}

def ok_arcs_overlap():
  {==}

law ok_lines_touch:
  {n_pt(S.inter_cc(xline(), dom(0.0f64, 6.0f64), xline(), dom(F64.neg(6.0f64), 0.0f64), 40n)) == 1n : Nat}

def ok_lines_touch():
  {==}

law neg_lines_touch_overlap:
  {n_ov(S.inter_cc(xline(), dom(0.0f64, 6.0f64), xline(), dom(F64.neg(6.0f64), 0.0f64), 40n)) == 0n : Nat}

def neg_lines_touch_overlap():
  {==}

law ok_tangent_endpoint_class:
  {first_cls(S.inter_cs(tan_conic(), dom(0.0f64, 1.0f64), yz_plane(), 40n)) == 34u64 : U64}

def ok_tangent_endpoint_class():
  {==}

law ok_class_mask:
  {S.has_cls([S.H_pt{i0(), i0(), [i0(), i0(), i0()], 33u64}], 1u64) == True{} : Bool}

def ok_class_mask():
  {==}

law ok_cone_axis_below_apex:
  {co_az(RV.ss_cone(RV.CN{True{}, 9.0f64, 0.6666666666666666f64}, 6.0f64, 0.0f64, 0.0f64, 9.0f64)) == F64.neg(1.0f64) : F64}

def ok_cone_axis_below_apex():
  {==}

law ok_semicircle_sweep:
  {ZT.in_02pi(ZT.sweep(p2(0.0f64, 0.0f64), p2(1.0f64, 0.0f64), p2(F64.neg(1.0f64), 0.0f64), True{})) == True{} : Bool}

def ok_semicircle_sweep():
  {==}

law ok_corner_square:
  {ZT.cone(seg(0.0f64, 0.0f64, 1.0f64, 0.0f64), seg(1.0f64, 0.0f64, 1.0f64, 1.0f64), True{}, False{}, 0.125f64) == True{} : Bool}

def ok_corner_square():
  {==}

law neg_corner_foldback:
  {ZT.cone(seg(0.0f64, 0.0f64, 1.0f64, 0.0f64), seg(1.0f64, 0.0f64, 0.0f64, 0.0f64), True{}, False{}, 0.125f64) == False{} : Bool}

def neg_corner_foldback():
  {==}

law ok_separated_segments:
  {ZT.sep_in(seg(0.0f64, 0.0f64, 1.0f64, 0.0f64), seg(0.0f64, 1.0f64, 1.0f64, 1.0f64), I.I{0.0f64, 1.0f64}, I.I{0.0f64, 1.0f64}) == True{} : Bool}

def ok_separated_segments():
  {==}

law neg_crossing_segments:
  {ZT.sep_in(seg(0.0f64, 0.0f64, 1.0f64, 1.0f64), seg(0.0f64, 1.0f64, 1.0f64, 0.0f64), I.I{0.0f64, 1.0f64}, I.I{0.0f64, 1.0f64}) == False{} : Bool}

def neg_crossing_segments():
  {==}

law ok_flat_edge_in_cut:
  {Mm.flat(flat_line(), disc_im()) == True{} : Bool}

def ok_flat_edge_in_cut():
  {==}

law neg_flat_edge_crossing:
  {Mm.flat(rise_line(), disc_im()) == False{} : Bool}

def neg_flat_edge_crossing():
  {==}

law ok_member_inside_disc:
  {Mm.member(disc(), q3(0.5f64, 0.25f64), disc_im()) == 1u64 : U64}

def ok_member_inside_disc():
  {==}

law ok_member_outside_disc:
  {Mm.member(disc(), q3(3.0f64, 0.5f64), disc_im()) == 0u64 : U64}

def ok_member_outside_disc():
  {==}
