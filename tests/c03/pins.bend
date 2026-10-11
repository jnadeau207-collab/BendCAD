import Base

import ../../src/c00/types.bend as T

import ../../src/c01/types.bend as V

import ../../src/c03/types.bend as G

import ../../src/c03/ops.bend as O

import ../../src/base/ex.bend as E

def gok_wrap(v: G.GVal) -> G.GRes:
  G.Gok{v}

def p_bits_eq(+r: G.GRes, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  +p = G.gres_p(r)
  Bool.and(U64.is_eq(F64.bits(V.pt_x(p)), wx),
    Bool.and(U64.is_eq(F64.bits(V.pt_y(p)), wy),
      U64.is_eq(F64.bits(V.pt_z(p)), wz)))

def d_bits_eq(+r: G.GRes, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  +d = G.gres_d(r)
  Bool.and(U64.is_eq(F64.bits(V.dr_x(d)), wx),
    Bool.and(U64.is_eq(F64.bits(V.dr_y(d)), wy),
      U64.is_eq(F64.bits(V.dr_z(d)), wz)))

def f_bits_eq(+r: G.GRes, +w: U64) -> Bool:
  U64.is_eq(F64.bits(G.gres_f(r)), w)

def v2_bits_eq(+r: G.GRes, +wx: U64, +wy: U64) -> Bool:
  +v = G.gres_v2(r)
  Bool.and(U64.is_eq(F64.bits(V.v2_x(v)), wx),
    U64.is_eq(F64.bits(V.v2_y(v)), wy))

def bb_bits_eq(+r: G.GRes, +ax: U64, +ay: U64, +az: U64, +bx: U64,
    +by: U64, +bz: U64) -> Bool:
  +b = G.gres_bb(r)
  +lo = G.bb_lo(b)
  +hi = G.bb_hi(b)
  Bool.and(U64.is_eq(F64.bits(V.pt_x(lo)), ax),
    Bool.and(U64.is_eq(F64.bits(V.pt_y(lo)), ay),
      Bool.and(U64.is_eq(F64.bits(V.pt_z(lo)), az),
        Bool.and(U64.is_eq(F64.bits(V.pt_x(hi)), bx),
          Bool.and(U64.is_eq(F64.bits(V.pt_y(hi)), by),
            U64.is_eq(F64.bits(V.pt_z(hi)), bz))))))

def dom_bits_eq(+r: G.GRes, +wlo: U64, +whi: U64) -> Bool:
  +d = G.gres_dom(r)
  Bool.and(U64.is_eq(F64.bits(G.dom_lo(d)), wlo),
    U64.is_eq(F64.bits(G.dom_hi(d)), whi))

def p000() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def p100() -> V.Point:
  V.Pt{1.0f64, 0.0f64, 0.0f64}

def p010() -> V.Point:
  V.Pt{0.0f64, 1.0f64, 0.0f64}

def p111() -> V.Point:
  V.Pt{1.0f64, 1.0f64, 1.0f64}

def p110() -> V.Point:
  V.Pt{1.0f64, 1.0f64, 0.0f64}

def p123() -> V.Point:
  V.Pt{1.0f64, 2.0f64, 3.0f64}

def d100() -> V.Dir:
  V.Dr{1.0f64, 0.0f64, 0.0f64}

def d010() -> V.Dir:
  V.Dr{0.0f64, 1.0f64, 0.0f64}

def d001() -> V.Dir:
  V.Dr{0.0f64, 0.0f64, 1.0f64}

def d000() -> V.Dir:
  V.Dr{0.0f64, 0.0f64, 0.0f64}

def v2_00() -> V.Vec2:
  V.V2{0.0f64, 0.0f64}

def v2_11() -> V.Vec2:
  V.V2{1.0f64, 1.0f64}

def dom_01() -> G.Dom:
  G.Dom{0.0f64, 1.0f64}

def dom_25() -> G.Dom:
  G.Dom{2.0f64, 5.0f64}

def dom_010() -> G.Dom:
  G.Dom{0.0f64, 10.0f64}

def pdom_per() -> G.Pdom:
  G.Pdom{dom_010(), True{}}

def pdom_cl() -> G.Pdom:
  G.Pdom{dom_010(), False{}}

def ln_x() -> G.Line3:
  G.Ln{p000(), d100()}

def ln_sk() -> G.Line3:
  G.Ln{p111(), V.Dr{0.0f64, 3.0f64, 4.0f64}}

def pl_xy() -> G.Plane3:
  G.Pl{p000(), d100(), d010()}

def pl_d() -> G.Plane3:
  G.Pl{p111(), d100(), d010()}

def pl_bad() -> G.Plane3:
  G.Pl{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, d010()}

def pl_skew() -> G.Plane3:
  G.Pl{p000(), d100(), V.Dr{0.5f64, 0.8660254037844386f64, 0.0f64}}

def cc_unit() -> G.Circle3:
  G.Cc{p000(), d100(), d010(), 1.0f64}

def cc_r2() -> G.Circle3:
  G.Cc{p000(), d100(), d010(), 2.0f64}

def bz_s() -> G.Bez3:
  G.Bz{p000(), p100(), p010(), p111()}

def bz_mx() -> G.Bez3:
  G.Bz{V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64},
    V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64}, p000(), p000()}

def rq_q() -> G.RQBez:
  G.Rq{p100(), p110(), p010(), 1.0f64, G.w_quarter(), 1.0f64}

def rq_p() -> G.RQBez:
  G.Rq{p100(), p110(), p010(), 1.0f64, 1.0f64, 1.0f64}

def rq_h() -> G.RQBez:
  G.Rq{p100(), p110(), p010(), 1.0f64, 2.0f64, 1.0f64}

def bp_flat() -> G.BezP:
  G.Bp{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
    V.Pt{0.0f64, 2.0f64, 0.0f64}, V.Pt{0.0f64, 3.0f64, 0.0f64},
    V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{1.0f64, 1.0f64, 0.0f64},
    V.Pt{1.0f64, 2.0f64, 0.0f64}, V.Pt{1.0f64, 3.0f64, 0.0f64},
    V.Pt{2.0f64, 0.0f64, 0.0f64}, V.Pt{2.0f64, 1.0f64, 0.0f64},
    V.Pt{2.0f64, 2.0f64, 0.0f64}, V.Pt{2.0f64, 3.0f64, 0.0f64},
    V.Pt{3.0f64, 0.0f64, 0.0f64}, V.Pt{3.0f64, 1.0f64, 0.0f64},
    V.Pt{3.0f64, 2.0f64, 0.0f64}, V.Pt{3.0f64, 3.0f64, 0.0f64}}

def bp_bump() -> G.BezP:
  G.Bp{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
    V.Pt{0.0f64, 2.0f64, 0.0f64}, V.Pt{0.0f64, 3.0f64, 0.0f64},
    V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{1.0f64, 1.0f64, 4.0f64},
    V.Pt{1.0f64, 2.0f64, 0.0f64}, V.Pt{1.0f64, 3.0f64, 0.0f64},
    V.Pt{2.0f64, 0.0f64, 0.0f64}, V.Pt{2.0f64, 1.0f64, 0.0f64},
    V.Pt{2.0f64, 2.0f64, 0.0f64}, V.Pt{2.0f64, 3.0f64, 0.0f64},
    V.Pt{3.0f64, 0.0f64, 0.0f64}, V.Pt{3.0f64, 1.0f64, 0.0f64},
    V.Pt{3.0f64, 2.0f64, 0.0f64}, V.Pt{3.0f64, 3.0f64, 0.0f64}}

def sp_unit() -> G.Sphere:
  G.Sp{p000(), 1.0f64}

def cy_z() -> G.Cyl:
  G.Cy{p000(), d001(), 1.0f64}

def co_z() -> G.Cone:
  G.Co{p000(), d001(), 0.5f64}

def to_z() -> G.Torus:
  G.To{p000(), d001(), 4.0f64, 1.0f64}

def ts_diag() -> G.TSeg:
  G.Ts{v2_00(), v2_11()}

def tb_s() -> G.TBez:
  G.Tb{v2_00(), V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}, v2_11()}

def ax_big() -> V.Dir:
  V.Dr{F64{4607182418800026415u64}, 0.0f64, 0.0f64}

def ax_ok() -> V.Dir:
  V.Dr{F64{4607182418800019660u64}, 0.0f64, 0.0f64}

def unwrap_bz(r: G.GRes) -> G.Bez3:
  match r:
    case G.Gok{v}:
      match v:
        case G.GV_bz{w}: w
        case _: G.Bz{p000(), p000(), p000(), p000()}
    case G.Gerr{kind}: G.Bz{p000(), p000(), p000(), p000()}

def unwrap_rq(r: G.GRes) -> G.RQBez:
  match r:
    case G.Gok{v}:
      match v:
        case G.GV_rq{w}: w
        case _: G.Rq{p000(), p000(), p000(), 1.0f64, 1.0f64, 1.0f64}
    case G.Gerr{kind}: G.Rq{p000(), p000(), p000(), 1.0f64, 1.0f64,
      1.0f64}

def unwrap_pl(r: G.GRes) -> G.Plane3:
  match r:
    case G.Gok{v}:
      match v:
        case G.GV_pl{w}: w
        case _: G.Pl{p000(), d100(), d010()}
    case G.Gerr{kind}: G.Pl{p000(), d100(), d010()}

def unwrap_cc(r: G.GRes) -> G.Circle3:
  match r:
    case G.Gok{v}:
      match v:
        case G.GV_cc{w}: w
        case _: G.Cc{p000(), d100(), d010(), 1.0f64}
    case G.Gerr{kind}: G.Cc{p000(), d100(), d010(), 1.0f64}

def unwrap_cy(r: G.GRes) -> G.Cyl:
  match r:
    case G.Gok{v}:
      match v:
        case G.GV_cy{w}: w
        case _: G.Cy{p000(), d001(), 1.0f64}
    case G.Gerr{kind}: G.Cy{p000(), d001(), 1.0f64}

def unwrap_co(r: G.GRes) -> G.Cone:
  match r:
    case G.Gok{v}:
      match v:
        case G.GV_co{w}: w
        case _: G.Co{p000(), d001(), 0.5f64}
    case G.Gerr{kind}: G.Co{p000(), d001(), 0.5f64}

def unwrap_to(r: G.GRes) -> G.Torus:
  match r:
    case G.Gok{v}:
      match v:
        case G.GV_to{w}: w
        case _: G.To{p000(), d001(), 4.0f64, 1.0f64}
    case G.Gerr{kind}: G.To{p000(), d001(), 4.0f64, 1.0f64}

def bb_has(+b: G.BBox3, +qx: F64, +qy: F64, +qz: F64) -> Bool:
  +lo = G.bb_lo(b)
  +hi = G.bb_hi(b)
  Bool.and(F64.is_le(V.pt_x(lo), qx),
    Bool.and(F64.is_le(qx, V.pt_x(hi)),
      Bool.and(F64.is_le(V.pt_y(lo), qy),
        Bool.and(F64.is_le(qy, V.pt_y(hi)),
          Bool.and(F64.is_le(V.pt_z(lo), qz),
            F64.is_le(qz, V.pt_z(hi)))))))

def ev_in_bb(+e: G.GRes, +b: G.GRes) -> Bool:
  +p = G.gres_p(e)
  bb_has(G.gres_bb(b), V.pt_x(p), V.pt_y(p), V.pt_z(p))

def nbk1_ks() -> List<&2, F64>:
  0.0f64 <> 0.0f64 <> 0.0f64 <> 0.0f64 <> 1.0f64 <> 1.0f64 <>
    1.0f64 <> 1.0f64 <> Nil{}

def nbk1_ps() -> List<&2, V.Point>:
  p000() <> p100() <> p010() <> p111() <> Nil{}

def nbk1_ws() -> List<&2, F64>:
  1.0f64 <> 1.0f64 <> 1.0f64 <> 1.0f64 <> Nil{}

def nbk1() -> G.Nurb:
  G.Nb{nbk1_ks(), nbk1_ps(), nbk1_ws()}

def nbk_short() -> G.Nurb:
  G.Nb{0.0f64 <> 0.0f64 <> 0.0f64 <> 0.0f64 <> 1.0f64 <> 1.0f64 <>
    1.0f64 <> Nil{}, nbk1_ps(), nbk1_ws()}

def nbk_uncl() -> G.Nurb:
  G.Nb{0.0f64 <> 0.0f64 <> 0.0f64 <> 0.5f64 <> 1.0f64 <> 1.0f64 <>
    1.0f64 <> 1.0f64 <> Nil{}, nbk1_ps(), nbk1_ws()}

def nbk_dec() -> G.Nurb:
  G.Nb{0.0f64 <> 0.0f64 <> 0.0f64 <> 0.0f64 <> 2.0f64 <> 1.0f64 <>
    1.0f64 <> 1.0f64 <> 1.0f64 <> Nil{},
    p000() <> p100() <> p010() <> p111() <> p123() <> Nil{},
    1.0f64 <> 1.0f64 <> 1.0f64 <> 1.0f64 <> 1.0f64 <> Nil{}}

def nbk_w0() -> G.Nurb:
  G.Nb{nbk1_ks(), nbk1_ps(),
    1.0f64 <> 1.0f64 <> 0.0f64 <> 1.0f64 <> Nil{}}

def nbk_nanp() -> G.Nurb:
  G.Nb{nbk1_ks(),
    p000() <> V.Pt{F64.nan(), 0.0f64, 0.0f64} <> p010() <>
      p111() <> Nil{}, nbk1_ws()}

def nbk_nank() -> G.Nurb:
  G.Nb{0.0f64 <> 0.0f64 <> 0.0f64 <> F64.nan() <> 1.0f64 <>
    1.0f64 <> 1.0f64 <> 1.0f64 <> Nil{}, nbk1_ps(), nbk1_ws()}

def ev_eq(+a: G.GRes, +b: G.GRes) -> Bool:
  +pa = G.gres_p(a)
  +pb = G.gres_p(b)
  Bool.and(U64.is_eq(F64.bits(V.pt_x(pa)), F64.bits(V.pt_x(pb))),
    Bool.and(U64.is_eq(F64.bits(V.pt_y(pa)), F64.bits(V.pt_y(pb))),
      U64.is_eq(F64.bits(V.pt_z(pa)), F64.bits(V.pt_z(pb)))))

def v2_in_bb(+e: G.GRes, +b: G.GRes) -> Bool:
  +v = G.gres_v2(e)
  +bb = G.gres_bb(b)
  +lo = G.bb_lo(bb)
  +hi = G.bb_hi(bb)
  Bool.and(F64.is_le(V.pt_x(lo), V.v2_x(v)),
    Bool.and(F64.is_le(V.v2_x(v), V.pt_x(hi)),
      Bool.and(F64.is_le(V.pt_y(lo), V.v2_y(v)),
        F64.is_le(V.v2_y(v), V.pt_y(hi)))))

def hull_bz() -> G.Bez3:
  G.Bz{V.Pt{0.1f64, 0.0f64, 0.0f64}, V.Pt{0.1f64, 1.0f64, 0.0f64},
    V.Pt{0.1f64, 2.0f64, 0.0f64}, V.Pt{0.1f64, 3.0f64, 0.0f64}}

def cy_r() -> G.Cyl:
  G.Cy{V.Pt{10.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 3.2f64}

def q_cyr() -> V.Point:
  V.Pt{(10.0f64 + 3.2f64 : F64), 0.0f64, 5.0f64}

def up3(+x: F64) -> F64:
  E.f64_next_up(E.f64_next_up(E.f64_next_up(x)))

def dom_ok_pin__got() -> Bool:
  Bool.and(String.eq(G.gres_show(G.mk_dom(0.0f64, 1.0f64)), "ok"), dom_bits_eq(G.mk_dom(0.0f64, 1.0f64), 0u64, 4607182418800017408u64))

def dom_ok_pin__want() -> Bool:
  True{}

def dom_eq_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_dom(1.0f64, 1.0f64)), "invalid-input")

def dom_eq_inv__want() -> Bool:
  True{}

def dom_flip_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_dom(2.0f64, 1.0f64)), "invalid-input")

def dom_flip_inv__want() -> Bool:
  True{}

def dom_nan_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_dom(F64.nan(), 1.0f64)), "invalid-input")

def dom_nan_inv__want() -> Bool:
  True{}

def dom_inf_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_dom(0.0f64, F64{9218868437227405312u64})), "invalid-input")

def dom_inf_inv__want() -> Bool:
  True{}

def line_ok_pin__got() -> Bool:
  String.eq(G.gres_show(G.mk_line(p000(), d100())), "ok")

def line_ok_pin__want() -> Bool:
  True{}

def line_nan_p_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_line( V.Pt{F64.nan(), 0.0f64, 0.0f64}, d100())), "invalid-input")

def line_nan_p_inv__want() -> Bool:
  True{}

def line_nan_d_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_line(p000(), V.Dr{0.0f64, F64.nan(), 0.0f64})), "invalid-input")

def line_nan_d_inv__want() -> Bool:
  True{}

def line_zero_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_line(p000(), d000())), "invalid-input")

def line_zero_inv__want() -> Bool:
  True{}

def line_negzero_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_line(p000(), V.Dr{F64{9223372036854775808u64}, 0.0f64, 0.0f64})), "invalid-input")

def line_negzero_inv__want() -> Bool:
  True{}

def plane_ok_pin__got() -> Bool:
  String.eq(G.gres_show(G.mk_plane(G.Pl{p000(), d100(), d010()})), "ok")

def plane_ok_pin__want() -> Bool:
  True{}

def plane_nan_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_plane(G.Pl{p000(), d100(), V.Dr{0.0f64, 0.0f64, F64.nan()}})), "invalid-input")

def plane_nan_inv__want() -> Bool:
  True{}

def circ_ok_pin__got() -> Bool:
  String.eq(G.gres_show(G.mk_circ(p000(), d100(), d010(), 2.0f64)), "ok")

def circ_ok_pin__want() -> Bool:
  True{}

def circ_r0_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_circ(p000(), d100(), d010(), 0.0f64)), "invalid-input")

def circ_r0_inv__want() -> Bool:
  True{}

def circ_rneg_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_circ(p000(), d100(), d010(), F64.neg(1.0f64))), "invalid-input")

def circ_rneg_inv__want() -> Bool:
  True{}

def circ_rnan_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_circ(p000(), d100(), d010(), F64.nan())), "invalid-input")

def circ_rnan_inv__want() -> Bool:
  True{}

def circ_rinf_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_circ(p000(), d100(), d010(), F64{9218868437227405312u64})), "invalid-input")

def circ_rinf_inv__want() -> Bool:
  True{}

def bez_ok_pin__got() -> Bool:
  String.eq(G.gres_show(G.mk_bez3(p000(), p100(), p010(), p111())), "ok")

def bez_ok_pin__want() -> Bool:
  True{}

def bez_nan_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_bez3(p000(), p100(), V.Pt{0.0f64, F64.nan(), 0.0f64}, p111())), "invalid-input")

def bez_nan_inv__want() -> Bool:
  True{}

def rq_ok_pin__got() -> Bool:
  String.eq(G.gres_show(G.mk_rqbez(p100(), p111(), p010(), 1.0f64, G.w_quarter(), 1.0f64)), "ok")

def rq_ok_pin__want() -> Bool:
  True{}

def rq_w0_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_rqbez(p100(), p111(), p010(), 0.0f64, G.w_quarter(), 1.0f64)), "invalid-input")

def rq_w0_inv__want() -> Bool:
  True{}

def rq_w1neg_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_rqbez(p100(), p111(), p010(), 1.0f64, F64.neg(0.5f64), 1.0f64)), "invalid-input")

def rq_w1neg_inv__want() -> Bool:
  True{}

def rq_wnan_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_rqbez(p100(), p111(), p010(), 1.0f64, G.w_quarter(), F64.nan())), "invalid-input")

def rq_wnan_inv__want() -> Bool:
  True{}

def bp_ok_pin__got() -> Bool:
  String.eq(G.gres_show(G.mk_bezp(p000(), p000(), p000(), p000(), p000(), p100(), p010(), p000(), p000(), p010(), p111(), p000(), p000(), p000(), p000(), p000())), "ok")

def bp_ok_pin__want() -> Bool:
  True{}

def bp_nan_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_bezp(p000(), p000(), p000(), p000(), p000(), p100(), p010(), p000(), p000(), p010(), p111(), V.Pt{F64.nan(), 0.0f64, 0.0f64}, p000(), p000(), p000(), p000())), "invalid-input")

def bp_nan_inv__want() -> Bool:
  True{}

def sph_ok_pin__got() -> Bool:
  String.eq(G.gres_show(G.mk_sph(p123(), 2.0f64)), "ok")

def sph_ok_pin__want() -> Bool:
  True{}

def sph_r0_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_sph(p123(), 0.0f64)), "invalid-input")

def sph_r0_inv__want() -> Bool:
  True{}

def sph_rneg_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_sph(p123(), F64.neg(2.0f64))), "invalid-input")

def sph_rneg_inv__want() -> Bool:
  True{}

def cyl_ok_pin__got() -> Bool:
  String.eq(G.gres_show(G.mk_cyl(p000(), d001(), 1.0f64)), "ok")

def cyl_ok_pin__want() -> Bool:
  True{}

def cyl_axis0_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_cyl(p000(), d000(), 1.0f64)), "invalid-input")

def cyl_axis0_inv__want() -> Bool:
  True{}

def cyl_r0_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_cyl(p000(), d001(), 0.0f64)), "invalid-input")

def cyl_r0_inv__want() -> Bool:
  True{}

def cone_ok_pin__got() -> Bool:
  String.eq(G.gres_show(G.mk_cone(p000(), d001(), 0.5f64)), "ok")

def cone_ok_pin__want() -> Bool:
  True{}

def cone_k0_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_cone(p000(), d001(), 0.0f64)), "invalid-input")

def cone_k0_inv__want() -> Bool:
  True{}

def cone_axisnan_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_cone(p000(), V.Dr{F64.nan(), 0.0f64, 0.0f64}, 0.5f64)), "invalid-input")

def cone_axisnan_inv__want() -> Bool:
  True{}

def torus_ok_pin__got() -> Bool:
  String.eq(G.gres_show(G.mk_torus(p000(), d001(), 4.0f64, 1.0f64)), "ok")

def torus_ok_pin__want() -> Bool:
  True{}

def torus_R0_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_torus(p000(), d001(), 0.0f64, 1.0f64)), "invalid-input")

def torus_R0_inv__want() -> Bool:
  True{}

def torus_rneg_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_torus(p000(), d001(), 4.0f64, F64.neg(1.0f64))), "invalid-input")

def torus_rneg_inv__want() -> Bool:
  True{}

def bb_ok_pin__got() -> Bool:
  Bool.and(String.eq(G.gres_show(G.mk_bbox(p000(), p111())), "ok"), bb_bits_eq(G.mk_bbox(p000(), p111()), 0u64, 0u64, 0u64, 4607182418800017408u64, 4607182418800017408u64, 4607182418800017408u64))

def bb_ok_pin__want() -> Bool:
  True{}

def bb_flipx_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_bbox(p100(), p000())), "invalid-input")

def bb_flipx_inv__want() -> Bool:
  True{}

def bb_nan_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_bbox(p000(), V.Pt{F64.nan(), 1.0f64, 1.0f64})), "invalid-input")

def bb_nan_inv__want() -> Bool:
  True{}

def tseg_ok_pin__got() -> Bool:
  String.eq(G.gres_show(G.mk_tseg(v2_00(), v2_11())), "ok")

def tseg_ok_pin__want() -> Bool:
  True{}

def tseg_nan_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_tseg(v2_00(), V.V2{F64.nan(), 1.0f64})), "invalid-input")

def tseg_nan_inv__want() -> Bool:
  True{}

def tbez_ok_pin__got() -> Bool:
  String.eq(G.gres_show(G.mk_tbez(v2_00(), v2_11(), v2_00(), v2_11())), "ok")

def tbez_ok_pin__want() -> Bool:
  True{}

def tbez_nan_inv__got() -> Bool:
  String.eq(G.gres_show(G.mk_tbez(v2_00(), v2_11(), V.V2{0.0f64, F64.nan()}, v2_11())), "invalid-input")

def tbez_nan_inv__want() -> Bool:
  True{}

def dz_zero_true__got() -> Bool:
  G.dr_is_zero(d000())

def dz_zero_true__want() -> Bool:
  True{}

def dz_negzero_true__got() -> Bool:
  G.dr_is_zero(V.Dr{F64{9223372036854775808u64}, F64{9223372036854775808u64}, F64{9223372036854775808u64}})

def dz_negzero_true__want() -> Bool:
  True{}

def dz_unit_false__got() -> Bool:
  G.dr_is_zero(d100())

def dz_unit_false__want() -> Bool:
  False{}

def spos_pos_true__got() -> Bool:
  G.spos(2.0f64)

def spos_pos_true__want() -> Bool:
  True{}

def spos_zero_false__got() -> Bool:
  G.spos(0.0f64)

def spos_zero_false__want() -> Bool:
  False{}

def spos_neg_false__got() -> Bool:
  G.spos(F64.neg(1.0f64))

def spos_neg_false__want() -> Bool:
  False{}

def spos_inf_false__got() -> Bool:
  G.spos(F64{9218868437227405312u64})

def spos_inf_false__want() -> Bool:
  False{}

def spos_nan_false__got() -> Bool:
  G.spos(F64.nan())

def spos_nan_false__want() -> Bool:
  False{}

def fin_ln_false__got() -> Bool:
  G.ln_fin(G.Ln{V.Pt{F64.nan(), 0.0f64, 0.0f64}, d100()})

def fin_ln_false__want() -> Bool:
  False{}

def fin_sp_true__got() -> Bool:
  G.sp_fin(G.Sp{p123(), 2.0f64})

def fin_sp_true__want() -> Bool:
  True{}

def fin_dom_true__got() -> Bool:
  G.dom_fin(G.Dom{0.0f64, 1.0f64})

def fin_dom_true__want() -> Bool:
  True{}

def fin_dom_inffalse__got() -> Bool:
  G.dom_fin(G.Dom{0.0f64, F64{9218868437227405312u64}})

def fin_dom_inffalse__want() -> Bool:
  False{}

def val_dom_ok__got() -> Bool:
  G.dom_valid(G.Dom{0.0f64, 1.0f64})

def val_dom_ok__want() -> Bool:
  True{}

def val_dom_eq__got() -> Bool:
  G.dom_valid(G.Dom{1.0f64, 1.0f64})

def val_dom_eq__want() -> Bool:
  False{}

def val_dom_flip__got() -> Bool:
  G.dom_valid(G.Dom{2.0f64, 1.0f64})

def val_dom_flip__want() -> Bool:
  False{}

def val_ln_zero__got() -> Bool:
  G.ln_valid(G.Ln{p000(), d000()})

def val_ln_zero__want() -> Bool:
  False{}

def val_cc_rneg__got() -> Bool:
  G.cc_valid(G.Cc{p000(), d100(), d010(), F64.neg(1.0f64)})

def val_cc_rneg__want() -> Bool:
  False{}

def val_rq_wneg__got() -> Bool:
  G.rq_valid(G.Rq{p100(), p110(), p010(), F64.neg(1.0f64), 1.0f64, 1.0f64})

def val_rq_wneg__want() -> Bool:
  False{}

def val_sp_r0__got() -> Bool:
  G.sp_valid(G.Sp{p123(), 0.0f64})

def val_sp_r0__want() -> Bool:
  False{}

def val_cy_rneg__got() -> Bool:
  G.cy_valid(G.Cy{p000(), d001(), F64.neg(1.0f64)})

def val_cy_rneg__want() -> Bool:
  False{}

def val_co_kneg__got() -> Bool:
  G.co_valid(G.Co{p000(), d001(), F64.neg(0.5f64)})

def val_co_kneg__want() -> Bool:
  False{}

def val_to_R0__got() -> Bool:
  G.to_valid(G.To{p000(), d001(), 0.0f64, 1.0f64})

def val_to_R0__want() -> Bool:
  False{}

def acc_dom_lo__got() -> Bool:
  U64.is_eq(F64.bits(G.dom_lo(G.Dom{2.0f64, 3.0f64})), 4611686018427387904u64)

def acc_dom_lo__want() -> Bool:
  True{}

def acc_dom_hi__got() -> Bool:
  U64.is_eq(F64.bits(G.dom_hi(G.Dom{2.0f64, 3.0f64})), 4613937818241073152u64)

def acc_dom_hi__want() -> Bool:
  True{}

def acc_ln_p__got() -> Bool:
  U64.is_eq(F64.bits(V.pt_x(G.ln_p(G.Ln{p123(), d100()}))), 4607182418800017408u64)

def acc_ln_p__want() -> Bool:
  True{}

def acc_ln_d__got() -> Bool:
  U64.is_eq(F64.bits(V.dr_y(G.ln_d(G.Ln{p123(), d010()}))), 4607182418800017408u64)

def acc_ln_d__want() -> Bool:
  True{}

def acc_cc_r__got() -> Bool:
  U64.is_eq(F64.bits(G.cc_r(G.Cc{p000(), d100(), d010(), 2.0f64})), 4611686018427387904u64)

def acc_cc_r__want() -> Bool:
  True{}

def acc_sp_r__got() -> Bool:
  U64.is_eq(F64.bits(G.sp_r(G.Sp{p123(), 3.0f64})), 4613937818241073152u64)

def acc_sp_r__want() -> Bool:
  True{}

def acc_bb_hi__got() -> Bool:
  U64.is_eq(F64.bits(V.pt_z(G.bb_hi(G.Bb{p000(), p123()}))), 4613937818241073152u64)

def acc_bb_hi__want() -> Bool:
  True{}

def acc_ts_b__got() -> Bool:
  U64.is_eq(F64.bits(V.v2_x(G.ts_b(G.Ts{v2_00(), v2_11()}))), 4607182418800017408u64)

def acc_ts_b__want() -> Bool:
  True{}

def wq_bits__got() -> Bool:
  U64.is_eq(F64.bits(G.w_quarter()), 4604544271217802189u64)

def wq_bits__want() -> Bool:
  True{}

def bn11_line_zero__got() -> Bool:
  p_bits_eq(G.mk_line(p000(), d000()), 0u64, 0u64, 0u64)

def bn11_line_zero__want() -> Bool:
  True{}

def bn11_dom_flip__got() -> Bool:
  dom_bits_eq(G.mk_dom(2.0f64, 1.0f64), 0u64, 0u64)

def bn11_dom_flip__want() -> Bool:
  True{}

def bn11_sph_neg__got() -> Bool:
  Bool.and(String.eq(G.gres_show(G.mk_sph(p123(), F64.neg(1.0f64))), "invalid-input"), U64.is_eq(F64.bits(G.gres_f(G.mk_sph(p123(), F64.neg(1.0f64)))), 0u64))

def bn11_sph_neg__want() -> Bool:
  True{}

def dmid_25__got() -> Bool:
  f_bits_eq(O.dom_mid(dom_25()), 4615063718147915776u64)

def dmid_25__want() -> Bool:
  True{}

def dmid_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.dom_mid(G.Dom{F64.nan(), 1.0f64})), "invalid-input")

def dmid_nan_inv__want() -> Bool:
  True{}

def dmid_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.dom_mid(G.Dom{ F64{9218868437227405310u64}, F64{9218868437227405311u64}})), "numerical-uncertainty")

def dmid_ovf_unc__want() -> Bool:
  True{}

def dlen_25__got() -> Bool:
  f_bits_eq(O.dom_len(dom_25()), 4613937818241073152u64)

def dlen_25__want() -> Bool:
  True{}

def dlen_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.dom_len(G.Dom{0.0f64, F64.nan()})), "invalid-input")

def dlen_nan_inv__want() -> Bool:
  True{}

def dlen_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.dom_len(G.Dom{ F64{18442240474082181119u64}, F64{9218868437227405311u64}})), "numerical-uncertainty")

def dlen_ovf_unc__want() -> Bool:
  True{}

def dmid_degen_inv__got() -> Bool:
  String.eq(G.gres_show(O.dom_mid(G.Dom{1.0f64, 1.0f64})), "invalid-input")

def dmid_degen_inv__want() -> Bool:
  True{}

def dlen_flip_inv__got() -> Bool:
  String.eq(G.gres_show(O.dom_len(G.Dom{2.0f64, 1.0f64})), "invalid-input")

def dlen_flip_inv__want() -> Bool:
  True{}

def clamp_degen_inv__got() -> Bool:
  String.eq(G.gres_show(O.dom_clamp(G.Dom{0.0f64, 0.0f64}, 0.0f64)), "invalid-input")

def clamp_degen_inv__want() -> Bool:
  True{}

def split_degen_inv__got() -> Bool:
  String.eq(G.gres_show(O.dom_split_lo(G.Dom{0.0f64, 0.0f64}, 0.0f64)), "invalid-input")

def split_degen_inv__want() -> Bool:
  True{}

def clamp_in__got() -> Bool:
  f_bits_eq(O.dom_clamp(G.Dom{0.0f64, 5.0f64}, 2.0f64), 4611686018427387904u64)

def clamp_in__want() -> Bool:
  True{}

def clamp_lo_edge__got() -> Bool:
  f_bits_eq(O.dom_clamp(G.Dom{0.0f64, 5.0f64}, 0.0f64), 0u64)

def clamp_lo_edge__want() -> Bool:
  True{}

def clamp_hi_edge__got() -> Bool:
  f_bits_eq(O.dom_clamp(G.Dom{0.0f64, 5.0f64}, 5.0f64), 4617315517961601024u64)

def clamp_hi_edge__want() -> Bool:
  True{}

def clamp_under__got() -> Bool:
  f_bits_eq(O.dom_clamp(G.Dom{0.0f64, 5.0f64}, F64.neg(1.0f64)), 0u64)

def clamp_under__want() -> Bool:
  True{}

def clamp_over__got() -> Bool:
  f_bits_eq(O.dom_clamp(G.Dom{0.0f64, 5.0f64}, 7.0f64), 4617315517961601024u64)

def clamp_over__want() -> Bool:
  True{}

def clamp_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.dom_clamp(G.Dom{0.0f64, 5.0f64}, F64.nan())), "invalid-input")

def clamp_nan_inv__want() -> Bool:
  True{}

def clamp_domnan_inv__got() -> Bool:
  String.eq(G.gres_show(O.dom_clamp(G.Dom{F64.nan(), 5.0f64}, 2.0f64)), "invalid-input")

def clamp_domnan_inv__want() -> Bool:
  True{}

def wrap_under__got() -> Bool:
  f_bits_eq(O.pdom_wrap(pdom_per(), F64.neg(3.0f64)), 4619567317775286272u64)

def wrap_under__want() -> Bool:
  True{}

def wrap_over__got() -> Bool:
  f_bits_eq(O.pdom_wrap(pdom_per(), 13.0f64), 4613937818241073152u64)

def wrap_over__want() -> Bool:
  True{}

def wrap_in__got() -> Bool:
  f_bits_eq(O.pdom_wrap(pdom_per(), 4.0f64), 4616189618054758400u64)

def wrap_in__want() -> Bool:
  True{}

def wrap_clamped__got() -> Bool:
  f_bits_eq(O.pdom_wrap(pdom_cl(), 13.0f64), 4621819117588971520u64)

def wrap_clamped__want() -> Bool:
  True{}

def wrap_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.pdom_wrap(pdom_per(), F64.nan())), "invalid-input")

def wrap_nan_inv__want() -> Bool:
  True{}

def wrap_degen1_inv__got() -> Bool:
  String.eq(G.gres_show(O.pdom_wrap(G.Pdom{G.Dom{ F64{9218868437227405311u64}, 0.0f64}, True{}}, F64.neg(F64{9218868437227405311u64}))), "invalid-input")

def wrap_degen1_inv__want() -> Bool:
  True{}

def wrap_degen2_inv__got() -> Bool:
  String.eq(G.gres_show(O.pdom_wrap(G.Pdom{G.Dom{0.0f64, F64.neg(F64{9218868437227405311u64})}, True{}}, F64{9218868437227405311u64})), "invalid-input")

def wrap_degen2_inv__want() -> Bool:
  True{}

def split_lo_mid__got() -> Bool:
  dom_bits_eq(O.dom_split_lo(dom_010(), 4.0f64), 0u64, 4616189618054758400u64)

def split_lo_mid__want() -> Bool:
  True{}

def split_hi_mid__got() -> Bool:
  dom_bits_eq(O.dom_split_hi(dom_010(), 4.0f64), 4616189618054758400u64, 4621819117588971520u64)

def split_hi_mid__want() -> Bool:
  True{}

def split_at_lo_inv__got() -> Bool:
  String.eq(G.gres_show(O.dom_split_lo(dom_010(), 0.0f64)), "invalid-input")

def split_at_lo_inv__want() -> Bool:
  True{}

def split_at_hi_inv__got() -> Bool:
  String.eq(G.gres_show(O.dom_split_hi(dom_010(), 10.0f64)), "invalid-input")

def split_at_hi_inv__want() -> Bool:
  True{}

def split_out_inv__got() -> Bool:
  String.eq(G.gres_show(O.dom_split_lo(dom_010(), 20.0f64)), "invalid-input")

def split_out_inv__want() -> Bool:
  True{}

def split_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.dom_split_hi(dom_010(), F64.nan())), "invalid-input")

def split_nan_inv__want() -> Bool:
  True{}

def leval_t3__got() -> Bool:
  p_bits_eq(O.line_eval(ln_x(), 3.0f64), 4613937818241073152u64, 0u64, 0u64)

def leval_t3__want() -> Bool:
  True{}

def leval_tneg__got() -> Bool:
  p_bits_eq(O.line_eval(ln_x(), F64.neg(2.0f64)), 13835058055282163712u64, 0u64, 0u64)

def leval_tneg__want() -> Bool:
  True{}

def leval_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.line_eval(ln_x(), F64.nan())), "invalid-input")

def leval_nan_inv__want() -> Bool:
  True{}

def leval_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.line_eval(G.Ln{ V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, d100()}, F64{9218868437227405311u64})), "numerical-uncertainty")

def leval_ovf_unc__want() -> Bool:
  True{}

def lder_x__got() -> Bool:
  d_bits_eq(O.line_der(ln_x()), 4607182418800017408u64, 0u64, 0u64)

def lder_x__want() -> Bool:
  True{}

def lder_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.line_der(G.Ln{p000(), V.Dr{F64.nan(), 0.0f64, 0.0f64}})), "invalid-input")

def lder_nan_inv__want() -> Bool:
  True{}

def leval_zero_inv__got() -> Bool:
  String.eq(G.gres_show(O.line_eval(G.Ln{p000(), d000()}, 1.0f64)), "invalid-input")

def leval_zero_inv__want() -> Bool:
  True{}

def lder_zero_inv__got() -> Bool:
  String.eq(G.gres_show(O.line_der(G.Ln{p000(), d000()})), "invalid-input")

def lder_zero_inv__want() -> Bool:
  True{}

def lproj_t5__got() -> Bool:
  f_bits_eq(O.line_project(ln_x(), V.Pt{5.0f64, 2.0f64, 0.0f64}), 4617315517961601024u64)

def lproj_t5__want() -> Bool:
  True{}

def lproj_sk__got() -> Bool:
  f_bits_eq(O.line_project(ln_sk(), V.Pt{1.0f64, 2.0f64, 3.0f64}), 4601597955262077993u64)

def lproj_sk__want() -> Bool:
  True{}

def lproj_zero_inv__got() -> Bool:
  String.eq(G.gres_show(O.line_project(G.Ln{p000(), d000()}, p111())), "invalid-input")

def lproj_zero_inv__want() -> Bool:
  True{}

def lproj_tiny_unc__got() -> Bool:
  String.eq(G.gres_show(O.line_project(G.Ln{p000(), V.Dr{F64{1u64}, 0.0f64, 0.0f64}}, p111())), "numerical-uncertainty")

def lproj_tiny_unc__want() -> Bool:
  True{}

def lproj_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.line_project(ln_x(), V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")

def lproj_nan_inv__want() -> Bool:
  True{}

def ldist_2__got() -> Bool:
  f_bits_eq(O.line_dist(ln_x(), V.Pt{5.0f64, 2.0f64, 0.0f64}), 4611686018427387904u64)

def ldist_2__want() -> Bool:
  True{}

def ldist_sk__got() -> Bool:
  f_bits_eq(O.line_dist(ln_sk(), V.Pt{1.0f64, 2.0f64, 3.0f64}), 4600877379321698720u64)

def ldist_sk__want() -> Bool:
  True{}

def ldist_zero_inv__got() -> Bool:
  String.eq(G.gres_show(O.line_dist(G.Ln{p000(), d000()}, p111())), "invalid-input")

def ldist_zero_inv__want() -> Bool:
  True{}

def ldist_tiny_unc__got() -> Bool:
  String.eq(G.gres_show(O.line_dist(G.Ln{p000(), V.Dr{F64{1u64}, 0.0f64, 0.0f64}}, p111())), "numerical-uncertainty")

def ldist_tiny_unc__want() -> Bool:
  True{}

def ldist_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.line_dist(ln_x(), V.Pt{F64{9218868437227405311u64}, F64{9218868437227405311u64}, F64{9218868437227405311u64}})), "numerical-uncertainty")

def ldist_ovf_unc__want() -> Bool:
  True{}

def segbb_pin__got() -> Bool:
  bb_bits_eq(O.line_seg_bbox(p000(), p123()), 0u64, 0u64, 0u64, 4607182418800017408u64, 4611686018427387904u64, 4613937818241073152u64)

def segbb_pin__want() -> Bool:
  True{}

def segbb_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.line_seg_bbox(p000(), V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")

def segbb_nan_inv__want() -> Bool:
  True{}

def plck_ok__got() -> Bool:
  String.eq(G.gres_show(O.plane_checked(pl_xy())), "ok")

def plck_ok__want() -> Bool:
  True{}

def plck_scale_inv__got() -> Bool:
  String.eq(G.gres_show(O.plane_checked(pl_bad())), "invalid-input")

def plck_scale_inv__want() -> Bool:
  True{}

def plck_skew_inv__got() -> Bool:
  String.eq(G.gres_show(O.plane_checked(pl_skew())), "invalid-input")

def plck_skew_inv__want() -> Bool:
  True{}

def plck_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.plane_checked(G.Pl{p000(), d100(), V.Dr{F64.nan(), 0.0f64, 0.0f64}})), "invalid-input")

def plck_nan_inv__want() -> Bool:
  True{}

def pln_xyz__got() -> Bool:
  d_bits_eq(O.plane_normal(pl_xy()), 0u64, 0u64, 4607182418800017408u64)

def pln_xyz__want() -> Bool:
  True{}

def pln_frame_inv__got() -> Bool:
  String.eq(G.gres_show(O.plane_normal(pl_bad())), "invalid-input")

def pln_frame_inv__want() -> Bool:
  True{}

def pleval_23__got() -> Bool:
  p_bits_eq(O.plane_eval(pl_xy(), 2.0f64, 3.0f64), 4611686018427387904u64, 4613937818241073152u64, 0u64)

def pleval_23__want() -> Bool:
  True{}

def pleval_d__got() -> Bool:
  p_bits_eq(O.plane_eval(pl_d(), 2.0f64, 3.0f64), 4613937818241073152u64, 4616189618054758400u64, 4607182418800017408u64)

def pleval_d__want() -> Bool:
  True{}

def pleval_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.plane_eval(pl_xy(), F64.nan(), 0.0f64)), "invalid-input")

def pleval_nan_inv__want() -> Bool:
  True{}

def pleval_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.plane_eval(G.Pl{ V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, d100(), d010()}, F64{9218868437227405311u64}, 0.0f64)), "numerical-uncertainty")

def pleval_ovf_unc__want() -> Bool:
  True{}

def pleval_frame_inv__got() -> Bool:
  String.eq(G.gres_show(O.plane_eval(pl_bad(), 1.0f64, 1.0f64)), "invalid-input")

def pleval_frame_inv__want() -> Bool:
  True{}

def plproj_234__got() -> Bool:
  v2_bits_eq(O.plane_project(pl_xy(), V.Pt{2.0f64, 3.0f64, 4.0f64}), 4611686018427387904u64, 4613937818241073152u64)

def plproj_234__want() -> Bool:
  True{}

def plproj_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.plane_project(pl_xy(), V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")

def plproj_nan_inv__want() -> Bool:
  True{}

def plproj_frame_inv__got() -> Bool:
  String.eq(G.gres_show(O.plane_project(pl_bad(), p111())), "invalid-input")

def plproj_frame_inv__want() -> Bool:
  True{}

def pldist_4__got() -> Bool:
  f_bits_eq(O.plane_dist(pl_xy(), V.Pt{2.0f64, 3.0f64, 4.0f64}), 4616189618054758400u64)

def pldist_4__want() -> Bool:
  True{}

def pldist_d__got() -> Bool:
  f_bits_eq(O.plane_dist(pl_d(), V.Pt{1.0f64, 1.0f64, 5.0f64}), 4616189618054758400u64)

def pldist_d__want() -> Bool:
  True{}

def pldist_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.plane_dist(pl_xy(), V.Pt{0.0f64, F64.nan(), 0.0f64})), "invalid-input")

def pldist_nan_inv__want() -> Bool:
  True{}

def plbb_pin__got() -> Bool:
  bb_bits_eq(O.plane_uv_bbox(pl_xy(), 0.0f64, 2.0f64, 0.0f64, 3.0f64), 0u64, 0u64, 0u64, 4611686018427387904u64, 4613937818241073152u64, 0u64)

def plbb_pin__want() -> Bool:
  True{}

def plbb_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.plane_uv_bbox(pl_xy(), 0.0f64, 2.0f64, F64.nan(), 3.0f64)), "invalid-input")

def plbb_nan_inv__want() -> Bool:
  True{}

def plbb_frame_inv__got() -> Bool:
  String.eq(G.gres_show(O.plane_uv_bbox(pl_bad(), 0.0f64, 2.0f64, 0.0f64, 3.0f64)), "invalid-input")

def plbb_frame_inv__want() -> Bool:
  True{}

def cck_ok__got() -> Bool:
  String.eq(G.gres_show(O.circ_checked(cc_unit())), "ok")

def cck_ok__want() -> Bool:
  True{}

def cck_frame_inv__got() -> Bool:
  String.eq(G.gres_show(O.circ_checked(G.Cc{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, d010(), 1.0f64})), "invalid-input")

def cck_frame_inv__want() -> Bool:
  True{}

def cck_r0_inv__got() -> Bool:
  String.eq(G.gres_show(O.circ_checked(G.Cc{p000(), d100(), d010(), 0.0f64})), "invalid-input")

def cck_r0_inv__want() -> Bool:
  True{}

def ceval_t0__got() -> Bool:
  p_bits_eq(O.circ_eval(cc_unit(), 0.0f64), 4607182418800017408u64, 0u64, 0u64)

def ceval_t0__want() -> Bool:
  True{}

def ceval_t1__got() -> Bool:
  p_bits_eq(O.circ_eval(cc_unit(), 1.0f64), 13830554455654793216u64, 0u64, 0u64)

def ceval_t1__want() -> Bool:
  True{}

def ceval_tneg1__got() -> Bool:
  p_bits_eq(O.circ_eval(cc_unit(), F64.neg(1.0f64)), 13830554455654793216u64, 0u64, 0u64)

def ceval_tneg1__want() -> Bool:
  True{}

def ceval_t05__got() -> Bool:
  p_bits_eq(O.circ_eval(cc_unit(), 0.5f64), 13822087688355336684u64, 4606822130829827768u64, 0u64)

def ceval_t05__want() -> Bool:
  True{}

def ceval_r2__got() -> Bool:
  p_bits_eq(O.circ_eval(cc_r2(), 0.0f64), 4611686018427387904u64, 0u64, 0u64)

def ceval_r2__want() -> Bool:
  True{}

def ceval_t2_inv__got() -> Bool:
  String.eq(G.gres_show(O.circ_eval(cc_unit(), 2.0f64)), "invalid-input")

def ceval_t2_inv__want() -> Bool:
  True{}

def ceval_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.circ_eval(cc_unit(), F64.nan())), "invalid-input")

def ceval_nan_inv__want() -> Bool:
  True{}

def ceval_r0_inv__got() -> Bool:
  String.eq(G.gres_show(O.circ_eval(G.Cc{p000(), d100(), d010(), 0.0f64}, 0.5f64)), "invalid-input")

def ceval_r0_inv__want() -> Bool:
  True{}

def ceval_rneg_inv__got() -> Bool:
  String.eq(G.gres_show(O.circ_eval(G.Cc{p000(), d100(), d010(), F64.neg(1.0f64)}, 0.5f64)), "invalid-input")

def ceval_rneg_inv__want() -> Bool:
  True{}

def ceval_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.circ_eval(G.Cc{ V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, d100(), d010(), F64{9218868437227405311u64}}, 0.0f64)), "numerical-uncertainty")

def ceval_ovf_unc__want() -> Bool:
  True{}

def cder_t0__got() -> Bool:
  d_bits_eq(O.circ_der(cc_unit(), 0.0f64), 0u64, 4616189618054758400u64, 0u64)

def cder_t0__want() -> Bool:
  True{}

def cder_t05__got() -> Bool:
  d_bits_eq(O.circ_der(cc_unit(), 0.5f64), 13837471984682434298u64, 13829617706932300153u64, 9223372036854775808u64)

def cder_t05__want() -> Bool:
  True{}

def cder_t2_inv__got() -> Bool:
  String.eq(G.gres_show(O.circ_der(cc_unit(), 2.0f64)), "invalid-input")

def cder_t2_inv__want() -> Bool:
  True{}

def cder_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.circ_der(G.Cc{p000(), d100(), d010(), F64{9218868437227405311u64}}, 0.5f64)), "numerical-uncertainty")

def cder_ovf_unc__want() -> Bool:
  True{}

def cseam_pin__got() -> Bool:
  p_bits_eq(O.circ_seam_pt(cc_unit()), 13830554455654793216u64, 0u64, 0u64)

def cseam_pin__want() -> Bool:
  True{}

def cseam_r0_inv__got() -> Bool:
  String.eq(G.gres_show(O.circ_seam_pt(G.Cc{p000(), d100(), d010(), 0.0f64})), "invalid-input")

def cseam_r0_inv__want() -> Bool:
  True{}

def cbb_unit__got() -> Bool:
  bb_bits_eq(O.circ_bbox(cc_unit()), 13830554455654793216u64, 13830554455654793216u64, 0u64, 4607182418800017408u64, 4607182418800017408u64, 0u64)

def cbb_unit__want() -> Bool:
  True{}

def cbb_r0_inv__got() -> Bool:
  String.eq(G.gres_show(O.circ_bbox(G.Cc{p000(), d100(), d010(), 0.0f64})), "invalid-input")

def cbb_r0_inv__want() -> Bool:
  True{}

def beval_t0__got() -> Bool:
  p_bits_eq(O.bez3_eval(bz_s(), 0.0f64), 0u64, 0u64, 0u64)

def beval_t0__want() -> Bool:
  True{}

def beval_t1__got() -> Bool:
  p_bits_eq(O.bez3_eval(bz_s(), 1.0f64), 4607182418800017408u64, 4607182418800017408u64, 4607182418800017408u64)

def beval_t1__want() -> Bool:
  True{}

def beval_t05__got() -> Bool:
  p_bits_eq(O.bez3_eval(bz_s(), 0.5f64), 4602678819172646912u64, 4602678819172646912u64, 4593671619917905920u64)

def beval_t05__want() -> Bool:
  True{}

def beval_t03__got() -> Bool:
  p_bits_eq(O.bez3_eval(bz_s(), 0.3f64), 4602102358420343487u64, 4596950240446631641u64, 4583439441564520153u64)

def beval_t03__want() -> Bool:
  True{}

def beval_t2_inv__got() -> Bool:
  String.eq(G.gres_show(O.bez3_eval(bz_s(), 2.0f64)), "invalid-input")

def beval_t2_inv__want() -> Bool:
  True{}

def beval_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.bez3_eval(bz_s(), F64.nan())), "invalid-input")

def beval_nan_inv__want() -> Bool:
  True{}

def beval_beznan_inv__got() -> Bool:
  String.eq(G.gres_show(O.bez3_eval(G.Bz{p000(), p100(), V.Pt{F64.nan(), 0.0f64, 0.0f64}, p111()}, 0.5f64)), "invalid-input")

def beval_beznan_inv__want() -> Bool:
  True{}

def bder_t0__got() -> Bool:
  d_bits_eq(O.bez3_der(bz_s(), 0.0f64), 4613937818241073152u64, 0u64, 0u64)

def bder_t0__want() -> Bool:
  True{}

def bder_t05__got() -> Bool:
  d_bits_eq(O.bez3_der(bz_s(), 0.5f64), 0u64, 4609434218613702656u64, 4604930618986332160u64)

def bder_t05__want() -> Bool:
  True{}

def bder_t2_inv__got() -> Bool:
  String.eq(G.gres_show(O.bez3_der(bz_s(), 2.0f64)), "invalid-input")

def bder_t2_inv__want() -> Bool:
  True{}

def bder_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.bez3_der(bz_mx(), 0.5f64)), "numerical-uncertainty")

def bder_ovf_unc__want() -> Bool:
  True{}

def bsplit_lo_ok__got() -> Bool:
  String.eq(G.gres_show(O.bez3_split_lo(bz_s(), 0.5f64)), "ok")

def bsplit_lo_ok__want() -> Bool:
  True{}

def bsplit_lo_end0__got() -> Bool:
  p_bits_eq(O.bez3_end0(unwrap_bz(O.bez3_split_lo(bz_s(), 0.5f64))), 0u64, 0u64, 0u64)

def bsplit_lo_end0__want() -> Bool:
  True{}

def bsplit_lo_joint__got() -> Bool:
  p_bits_eq(O.bez3_end1(unwrap_bz(O.bez3_split_lo(bz_s(), 0.5f64))), 4602678819172646912u64, 4602678819172646912u64, 4593671619917905920u64)

def bsplit_lo_joint__want() -> Bool:
  True{}

def bsplit_lo_t0_inv__got() -> Bool:
  String.eq(G.gres_show(O.bez3_split_lo(bz_s(), 0.0f64)), "invalid-input")

def bsplit_lo_t0_inv__want() -> Bool:
  True{}

def bsplit_lo_t2_inv__got() -> Bool:
  String.eq(G.gres_show(O.bez3_split_lo(bz_s(), 2.0f64)), "invalid-input")

def bsplit_lo_t2_inv__want() -> Bool:
  True{}

def bsplit_hi_ok__got() -> Bool:
  String.eq(G.gres_show(O.bez3_split_hi(bz_s(), 0.5f64)), "ok")

def bsplit_hi_ok__want() -> Bool:
  True{}

def bsplit_hi_end1__got() -> Bool:
  p_bits_eq(O.bez3_end1(unwrap_bz(O.bez3_split_hi(bz_s(), 0.5f64))), 4607182418800017408u64, 4607182418800017408u64, 4607182418800017408u64)

def bsplit_hi_end1__want() -> Bool:
  True{}

def bsplit_hi_joint__got() -> Bool:
  p_bits_eq(O.bez3_end0(unwrap_bz(O.bez3_split_hi(bz_s(), 0.5f64))), 4602678819172646912u64, 4602678819172646912u64, 4593671619917905920u64)

def bsplit_hi_joint__want() -> Bool:
  True{}

def bsplit_hi_t1_inv__got() -> Bool:
  String.eq(G.gres_show(O.bez3_split_hi(bz_s(), 1.0f64)), "invalid-input")

def bsplit_hi_t1_inv__want() -> Bool:
  True{}

def bbbox_s__got() -> Bool:
  bb_bits_eq(O.bez3_bbox(bz_s()), 0u64, 0u64, 0u64, 4607182418800017408u64, 4607182418800017408u64, 4607182418800017408u64)

def bbbox_s__want() -> Bool:
  True{}

def bbbox_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.bez3_bbox(G.Bz{p000(), p100(), p010(), V.Pt{0.0f64, 0.0f64, F64.nan()}})), "invalid-input")

def bbbox_nan_inv__want() -> Bool:
  True{}

def bend0_s__got() -> Bool:
  p_bits_eq(O.bez3_end0(bz_s()), 0u64, 0u64, 0u64)

def bend0_s__want() -> Bool:
  True{}

def bend1_s__got() -> Bool:
  p_bits_eq(O.bez3_end1(bz_s()), 4607182418800017408u64, 4607182418800017408u64, 4607182418800017408u64)

def bend1_s__want() -> Bool:
  True{}

def bend_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.bez3_end0(G.Bz{ V.Pt{F64.nan(), 0.0f64, 0.0f64}, p100(), p010(), p111()})), "invalid-input")

def bend_nan_inv__want() -> Bool:
  True{}

def qeval_q0__got() -> Bool:
  p_bits_eq(O.rqb_eval(rq_q(), 0.0f64), 4607182418800017408u64, 0u64, 0u64)

def qeval_q0__want() -> Bool:
  True{}

def qeval_q05__got() -> Bool:
  p_bits_eq(O.rqb_eval(rq_q(), 0.5f64), 4604544271217802188u64, 4604544271217802188u64, 0u64)

def qeval_q05__want() -> Bool:
  True{}

def qeval_q1__got() -> Bool:
  p_bits_eq(O.rqb_eval(rq_q(), 1.0f64), 0u64, 4607182418800017408u64, 0u64)

def qeval_q1__want() -> Bool:
  True{}

def qeval_t2_inv__got() -> Bool:
  String.eq(G.gres_show(O.rqb_eval(rq_q(), 2.0f64)), "invalid-input")

def qeval_t2_inv__want() -> Bool:
  True{}

def qeval_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.rqb_eval(rq_q(), F64.nan())), "invalid-input")

def qeval_nan_inv__want() -> Bool:
  True{}

def qeval_wneg_inv__got() -> Bool:
  String.eq(G.gres_show(O.rqb_eval(G.Rq{p100(), p110(), p010(), F64.neg(1.0f64), 1.0f64, 1.0f64}, 0.5f64)), "invalid-input")

def qeval_wneg_inv__want() -> Bool:
  True{}

def qder_q0__got() -> Bool:
  d_bits_eq(O.rqb_der(rq_q(), 0.0f64), 0u64, 4609047870845172685u64, 0u64)

def qder_q0__want() -> Bool:
  True{}

def qder_t2_inv__got() -> Bool:
  String.eq(G.gres_show(O.rqb_der(rq_q(), 2.0f64)), "invalid-input")

def qder_t2_inv__want() -> Bool:
  True{}

def qder_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.rqb_der(G.Rq{ V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64}, V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, p000(), 1.0f64, 1.0f64, 1.0f64}, 0.5f64)), "numerical-uncertainty")

def qder_ovf_unc__want() -> Bool:
  True{}

def qder_w0_inv__got() -> Bool:
  String.eq(G.gres_show(O.rqb_der(G.Rq{p100(), p110(), p010(), 1.0f64, 0.0f64, 1.0f64}, 0.0f64)), "invalid-input")

def qder_w0_inv__want() -> Bool:
  True{}

def qbb_q__got() -> Bool:
  bb_bits_eq(O.rqb_bbox(rq_q()), 0u64, 0u64, 0u64, 4607182418800017408u64, 4607182418800017408u64, 0u64)

def qbb_q__want() -> Bool:
  True{}

def qbb_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.rqb_bbox(G.Rq{p100(), p111(), V.Pt{F64.nan(), 0.0f64, 0.0f64}, 1.0f64, 1.0f64, 1.0f64})), "invalid-input")

def qbb_nan_inv__want() -> Bool:
  True{}

def qbb_wneg_inv__got() -> Bool:
  String.eq(G.gres_show(O.rqb_bbox(G.Rq{p100(), p110(), p010(), 1.0f64, 1.0f64, F64.neg(1.0f64)})), "invalid-input")

def qbb_wneg_inv__want() -> Bool:
  True{}

def qdisc_q__got() -> Bool:
  f_bits_eq(O.rqb_disc(rq_q()), 13826050856027422718u64)

def qdisc_q__want() -> Bool:
  True{}

def qdisc_p__got() -> Bool:
  f_bits_eq(O.rqb_disc(rq_p()), 0u64)

def qdisc_p__want() -> Bool:
  True{}

def qdisc_h__got() -> Bool:
  f_bits_eq(O.rqb_disc(rq_h()), 4613937818241073152u64)

def qdisc_h__want() -> Bool:
  True{}

def qdisc_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.rqb_disc(G.Rq{p100(), p111(), p010(), 1.0f64, F64.nan(), 1.0f64})), "invalid-input")

def qdisc_nan_inv__want() -> Bool:
  True{}

def qdisc_w0_inv__got() -> Bool:
  String.eq(G.gres_show(O.rqb_disc(G.Rq{p100(), p110(), p010(), 1.0f64, 0.0f64, 1.0f64})), "invalid-input")

def qdisc_w0_inv__want() -> Bool:
  True{}

def rquarter_ok__got() -> Bool:
  String.eq(G.gres_show(O.rq_quarter(p000(), d100(), d010(), 2.0f64)), "ok")

def rquarter_ok__want() -> Bool:
  True{}

def rquarter_eval__got() -> Bool:
  p_bits_eq(O.rqb_eval(unwrap_rq(O.rq_quarter(p000(), d100(), d010(), 2.0f64)), 0.5f64), 4609047870845172684u64, 4609047870845172684u64, 0u64)

def rquarter_eval__want() -> Bool:
  True{}

def rquarter_frame_inv__got() -> Bool:
  String.eq(G.gres_show(O.rq_quarter(p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, d010(), 2.0f64)), "invalid-input")

def rquarter_frame_inv__want() -> Bool:
  True{}

def rquarter_r0_inv__got() -> Bool:
  String.eq(G.gres_show(O.rq_quarter(p000(), d100(), d010(), 0.0f64)), "invalid-input")

def rquarter_r0_inv__want() -> Bool:
  True{}

def peval_flat__got() -> Bool:
  p_bits_eq(O.bezp_eval(bp_flat(), 0.5f64, 0.5f64), 4609434218613702656u64, 4609434218613702656u64, 0u64)

def peval_flat__want() -> Bool:
  True{}

def peval_bump__got() -> Bool:
  p_bits_eq(O.bezp_eval(bp_bump(), 0.5f64, 0.5f64), 4609434218613702656u64, 4609434218613702656u64, 4603241769126068224u64)

def peval_bump__want() -> Bool:
  True{}

def peval_c33__got() -> Bool:
  p_bits_eq(O.bezp_eval(bp_bump(), 1.0f64, 1.0f64), 4613937818241073152u64, 4613937818241073152u64, 0u64)

def peval_c33__want() -> Bool:
  True{}

def peval_u2_inv__got() -> Bool:
  String.eq(G.gres_show(O.bezp_eval(bp_flat(), 2.0f64, 0.5f64)), "invalid-input")

def peval_u2_inv__want() -> Bool:
  True{}

def peval_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.bezp_eval(bp_flat(), 0.5f64, F64.nan())), "invalid-input")

def peval_nan_inv__want() -> Bool:
  True{}

def pdu_flat__got() -> Bool:
  d_bits_eq(O.bezp_du(bp_flat(), 0.5f64, 0.5f64), 0u64, 4613937818241073152u64, 0u64)

def pdu_flat__want() -> Bool:
  True{}

def pdu_u2_inv__got() -> Bool:
  String.eq(G.gres_show(O.bezp_du(bp_flat(), 2.0f64, 0.5f64)), "invalid-input")

def pdu_u2_inv__want() -> Bool:
  True{}

def pdu_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.bezp_du(G.Bp{ V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64}, V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000()}, 0.5f64, 0.5f64)), "numerical-uncertainty")

def pdu_ovf_unc__want() -> Bool:
  True{}

def pdv_flat__got() -> Bool:
  d_bits_eq(O.bezp_dv(bp_flat(), 0.5f64, 0.5f64), 4613937818241073152u64, 0u64, 0u64)

def pdv_flat__want() -> Bool:
  True{}

def pdv_v2_inv__got() -> Bool:
  String.eq(G.gres_show(O.bezp_dv(bp_flat(), 0.5f64, 2.0f64)), "invalid-input")

def pdv_v2_inv__want() -> Bool:
  True{}

def pdv_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.bezp_dv(G.Bp{ V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64}, V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64}, V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64}, V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64}, V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000()}, 0.5f64, 0.5f64)), "numerical-uncertainty")

def pdv_ovf_unc__want() -> Bool:
  True{}

def pbb_flat__got() -> Bool:
  bb_bits_eq(O.bezp_bbox(bp_flat()), 0u64, 0u64, 0u64, 4613937818241073152u64, 4613937818241073152u64, 0u64)

def pbb_flat__want() -> Bool:
  True{}

def pbb_bump__got() -> Bool:
  bb_bits_eq(O.bezp_bbox(bp_bump()), 0u64, 0u64, 0u64, 4613937818241073152u64, 4613937818241073152u64, 4616189618054758400u64)

def pbb_bump__want() -> Bool:
  True{}

def pbb_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.bezp_bbox(G.Bp{p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), V.Pt{F64.nan(), 0.0f64, 0.0f64}})), "invalid-input")

def pbb_nan_inv__want() -> Bool:
  True{}

def piso_u_ok__got() -> Bool:
  String.eq(G.gres_show(O.bezp_iso_u(bp_flat(), 0.5f64)), "ok")

def piso_u_ok__want() -> Bool:
  True{}

def piso_u_end0__got() -> Bool:
  p_bits_eq(O.bez3_end0(unwrap_bz(O.bezp_iso_u(bp_flat(), 0.5f64))), 0u64, 4609434218613702656u64, 0u64)

def piso_u_end0__want() -> Bool:
  True{}

def piso_u_u2_inv__got() -> Bool:
  String.eq(G.gres_show(O.bezp_iso_u(bp_flat(), 2.0f64)), "invalid-input")

def piso_u_u2_inv__want() -> Bool:
  True{}

def piso_v_ok__got() -> Bool:
  String.eq(G.gres_show(O.bezp_iso_v(bp_flat(), 0.5f64)), "ok")

def piso_v_ok__want() -> Bool:
  True{}

def piso_v_end1__got() -> Bool:
  p_bits_eq(O.bez3_end1(unwrap_bz(O.bezp_iso_v(bp_flat(), 0.5f64))), 4609434218613702656u64, 4613937818241073152u64, 0u64)

def piso_v_end1__want() -> Bool:
  True{}

def piso_v_v2_inv__got() -> Bool:
  String.eq(G.gres_show(O.bezp_iso_v(bp_flat(), 2.0f64)), "invalid-input")

def piso_v_v2_inv__want() -> Bool:
  True{}

def pcorner_pins__got() -> Bool:
  Bool.and(p_bits_eq(O.bezp_c00(bp_flat()), 0u64, 0u64, 0u64), Bool.and(p_bits_eq(O.bezp_c03(bp_flat()), 0u64, 4613937818241073152u64, 0u64), Bool.and(p_bits_eq(O.bezp_c30(bp_flat()), 4613937818241073152u64, 0u64, 0u64), p_bits_eq(O.bezp_c33(bp_flat()), 4613937818241073152u64, 4613937818241073152u64, 0u64))))

def pcorner_pins__want() -> Bool:
  True{}

def pcorner_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.bezp_c33(G.Bp{p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), p000(), V.Pt{0.0f64, F64.nan(), 0.0f64}})), "invalid-input")

def pcorner_nan_inv__want() -> Bool:
  True{}

def bbunion_pin__got() -> Bool:
  bb_bits_eq(O.bbox_union(G.Bb{p000(), p111()}, G.Bb{V.Pt{2.0f64, 2.0f64, 2.0f64}, V.Pt{3.0f64, 3.0f64, 3.0f64}}), 0u64, 0u64, 0u64, 4613937818241073152u64, 4613937818241073152u64, 4613937818241073152u64)

def bbunion_pin__want() -> Bool:
  True{}

def bbunion_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.bbox_union(G.Bb{p000(), p111()}, G.Bb{V.Pt{F64.nan(), 0.0f64, 0.0f64}, p111()})), "invalid-input")

def bbunion_nan_inv__want() -> Bool:
  True{}

def cyck_ok__got() -> Bool:
  String.eq(G.gres_show(O.cyl_checked(cy_z())), "ok")

def cyck_ok__want() -> Bool:
  True{}

def cyck_axis2_inv__got() -> Bool:
  String.eq(G.gres_show(O.cyl_checked(G.Cy{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, 1.0f64})), "invalid-input")

def cyck_axis2_inv__want() -> Bool:
  True{}

def cyck_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.cyl_checked(G.Cy{p000(), V.Dr{F64.nan(), 0.0f64, 0.0f64}, 1.0f64})), "invalid-input")

def cyck_nan_inv__want() -> Bool:
  True{}

def cyck_axbig_inv__got() -> Bool:
  String.eq(G.gres_show(O.cyl_checked(G.Cy{p000(), ax_big(), 1.0f64})), "invalid-input")

def cyck_axbig_inv__want() -> Bool:
  True{}

def cyck_axok_ok__got() -> Bool:
  String.eq(G.gres_show(O.cyl_checked(G.Cy{p000(), ax_ok(), 1.0f64})), "ok")

def cyck_axok_ok__want() -> Bool:
  True{}

def cyck_rneg_inv__got() -> Bool:
  String.eq(G.gres_show(O.cyl_checked(G.Cy{p000(), d001(), F64.neg(1.0f64)})), "invalid-input")

def cyck_rneg_inv__want() -> Bool:
  True{}

def cock_ok__got() -> Bool:
  String.eq(G.gres_show(O.cone_checked(co_z())), "ok")

def cock_ok__want() -> Bool:
  True{}

def cock_axis2_inv__got() -> Bool:
  String.eq(G.gres_show(O.cone_checked(G.Co{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, 0.5f64})), "invalid-input")

def cock_axis2_inv__want() -> Bool:
  True{}

def cock_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.cone_checked(G.Co{p000(), V.Dr{F64.nan(), 0.0f64, 0.0f64}, 0.5f64})), "invalid-input")

def cock_nan_inv__want() -> Bool:
  True{}

def cock_kneg_inv__got() -> Bool:
  String.eq(G.gres_show(O.cone_checked(G.Co{p000(), d001(), F64.neg(0.5f64)})), "invalid-input")

def cock_kneg_inv__want() -> Bool:
  True{}

def tock_ok__got() -> Bool:
  String.eq(G.gres_show(O.tor_checked(to_z())), "ok")

def tock_ok__want() -> Bool:
  True{}

def tock_axis2_inv__got() -> Bool:
  String.eq(G.gres_show(O.tor_checked(G.To{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, 4.0f64, 1.0f64})), "invalid-input")

def tock_axis2_inv__want() -> Bool:
  True{}

def tock_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.tor_checked(G.To{p000(), V.Dr{F64.nan(), 0.0f64, 0.0f64}, 4.0f64, 1.0f64})), "invalid-input")

def tock_nan_inv__want() -> Bool:
  True{}

def tock_R0_inv__got() -> Bool:
  String.eq(G.gres_show(O.tor_checked(G.To{p000(), d001(), 0.0f64, 1.0f64})), "invalid-input")

def tock_R0_inv__want() -> Bool:
  True{}

def sphv_on__got() -> Bool:
  f_bits_eq(O.sph_val(sp_unit(), p100()), 0u64)

def sphv_on__want() -> Bool:
  True{}

def sphv_out__got() -> Bool:
  f_bits_eq(O.sph_val(sp_unit(), V.Pt{2.0f64, 0.0f64, 0.0f64}), 4613937818241073152u64)

def sphv_out__want() -> Bool:
  True{}

def sphv_in__got() -> Bool:
  f_bits_eq(O.sph_val(sp_unit(), p000()), 13830554455654793216u64)

def sphv_in__want() -> Bool:
  True{}

def sphv_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.sph_val(sp_unit(), V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")

def sphv_nan_inv__want() -> Bool:
  True{}

def sphv_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.sph_val(sp_unit(), V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})), "numerical-uncertainty")

def sphv_ovf_unc__want() -> Bool:
  True{}

def sphv_rneg_inv__got() -> Bool:
  String.eq(G.gres_show(O.sph_val(G.Sp{p000(), F64.neg(1.0f64)}, p100())), "invalid-input")

def sphv_rneg_inv__want() -> Bool:
  True{}

def sphg_123__got() -> Bool:
  d_bits_eq(O.sph_grad(sp_unit(), p123()), 4611686018427387904u64, 4616189618054758400u64, 4618441417868443648u64)

def sphg_123__want() -> Bool:
  True{}

def sphg_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.sph_grad(sp_unit(), V.Pt{0.0f64, F64.nan(), 0.0f64})), "invalid-input")

def sphg_nan_inv__want() -> Bool:
  True{}

def sphg_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.sph_grad(sp_unit(), V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})), "numerical-uncertainty")

def sphg_ovf_unc__want() -> Bool:
  True{}

def sphg_r0_inv__got() -> Bool:
  String.eq(G.gres_show(O.sph_grad(G.Sp{p000(), 0.0f64}, p123())), "invalid-input")

def sphg_r0_inv__want() -> Bool:
  True{}

def sphp_200__got() -> Bool:
  p_bits_eq(O.sph_project(sp_unit(), V.Pt{2.0f64, 0.0f64, 0.0f64}), 4607182418800017408u64, 0u64, 0u64)

def sphp_200__want() -> Bool:
  True{}

def sphp_345__got() -> Bool:
  p_bits_eq(O.sph_project(sp_unit(), V.Pt{3.0f64, 4.0f64, 0.0f64}), 4603579539098121011u64, 4605380978949069210u64, 0u64)

def sphp_345__want() -> Bool:
  True{}

def sphp_center_inv__got() -> Bool:
  String.eq(G.gres_show(O.sph_project(sp_unit(), p000())), "invalid-input")

def sphp_center_inv__want() -> Bool:
  True{}

def sphp_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.sph_project(sp_unit(), V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")

def sphp_nan_inv__want() -> Bool:
  True{}

def sphp_far_unc__got() -> Bool:
  String.eq(G.gres_show(O.sph_project(sp_unit(), V.Pt{F64{9218868437227405311u64}, F64{9218868437227405311u64}, 0.0f64})), "numerical-uncertainty")

def sphp_far_unc__want() -> Bool:
  True{}

def sphp_rneg_inv__got() -> Bool:
  String.eq(G.gres_show(O.sph_project(G.Sp{p000(), F64.neg(1.0f64)}, V.Pt{2.0f64, 0.0f64, 0.0f64})), "invalid-input")

def sphp_rneg_inv__want() -> Bool:
  True{}

def sphp_faraxis_ok__got() -> Bool:
  p_bits_eq(O.sph_project(sp_unit(), V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}), 4607182418800017408u64, 0u64, 0u64)

def sphp_faraxis_ok__want() -> Bool:
  True{}

def sphp_minr_ok__got() -> Bool:
  p_bits_eq(O.sph_project(G.Sp{p000(), F64{1u64}}, V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}), 1u64, 0u64, 0u64)

def sphp_minr_ok__want() -> Bool:
  True{}

def sphp_farctr_ok__got() -> Bool:
  p_bits_eq(O.sph_project(G.Sp{p100(), 1.0f64}, V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}), 4611686018427387904u64, 0u64, 0u64)

def sphp_farctr_ok__want() -> Bool:
  True{}

def spolen_n__got() -> Bool:
  p_bits_eq(O.sph_pole_n(sp_unit(), d001()), 0u64, 0u64, 4607182418800017408u64)

def spolen_n__want() -> Bool:
  True{}

def spolen_s__got() -> Bool:
  p_bits_eq(O.sph_pole_s(sp_unit(), d001()), 0u64, 0u64, 13830554455654793216u64)

def spolen_s__want() -> Bool:
  True{}

def spolen_axis2_inv__got() -> Bool:
  String.eq(G.gres_show(O.sph_pole_n(sp_unit(), V.Dr{2.0f64, 0.0f64, 0.0f64})), "invalid-input")

def spolen_axis2_inv__want() -> Bool:
  True{}

def spolen_r0_inv__got() -> Bool:
  String.eq(G.gres_show(O.sph_pole_n(G.Sp{p000(), 0.0f64}, d001())), "invalid-input")

def spolen_r0_inv__want() -> Bool:
  True{}

def cylv_on__got() -> Bool:
  f_bits_eq(O.cyl_val(cy_z(), V.Pt{1.0f64, 0.0f64, 5.0f64}), 0u64)

def cylv_on__want() -> Bool:
  True{}

def cylv_off__got() -> Bool:
  f_bits_eq(O.cyl_val(cy_z(), V.Pt{2.0f64, 0.0f64, 0.0f64}), 4613937818241073152u64)

def cylv_off__want() -> Bool:
  True{}

def cylv_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.cyl_val(cy_z(), V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")

def cylv_nan_inv__want() -> Bool:
  True{}

def cylv_axis2_inv__got() -> Bool:
  String.eq(G.gres_show(O.cyl_val(G.Cy{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, 1.0f64}, p100())), "invalid-input")

def cylv_axis2_inv__want() -> Bool:
  True{}

def cylv_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.cyl_val(cy_z(), V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})), "numerical-uncertainty")

def cylv_ovf_unc__want() -> Bool:
  True{}

def cylv_rneg_inv__got() -> Bool:
  String.eq(G.gres_show(O.cyl_val(G.Cy{p000(), d001(), F64.neg(1.0f64)}, p100())), "invalid-input")

def cylv_rneg_inv__want() -> Bool:
  True{}

def cylg_105__got() -> Bool:
  d_bits_eq(O.cyl_grad(cy_z(), V.Pt{1.0f64, 0.0f64, 5.0f64}), 4611686018427387904u64, 0u64, 0u64)

def cylg_105__want() -> Bool:
  True{}

def cylg_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.cyl_grad(cy_z(), V.Pt{0.0f64, F64.nan(), 0.0f64})), "invalid-input")

def cylg_nan_inv__want() -> Bool:
  True{}

def cylg_axis2_inv__got() -> Bool:
  String.eq(G.gres_show(O.cyl_grad(G.Cy{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, 1.0f64}, p100())), "invalid-input")

def cylg_axis2_inv__want() -> Bool:
  True{}

def cylg_r0_inv__got() -> Bool:
  String.eq(G.gres_show(O.cyl_grad(G.Cy{p000(), d001(), 0.0f64}, p100())), "invalid-input")

def cylg_r0_inv__want() -> Bool:
  True{}

def cov_on__got() -> Bool:
  f_bits_eq(O.cone_val(co_z(), V.Pt{1.0f64, 0.0f64, 2.0f64}), 0u64)

def cov_on__want() -> Bool:
  True{}

def cov_off__got() -> Bool:
  f_bits_eq(O.cone_val(co_z(), V.Pt{2.0f64, 0.0f64, 2.0f64}), 4613937818241073152u64)

def cov_off__want() -> Bool:
  True{}

def cov_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.cone_val(co_z(), V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")

def cov_nan_inv__want() -> Bool:
  True{}

def cov_axis2_inv__got() -> Bool:
  String.eq(G.gres_show(O.cone_val(G.Co{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, 0.5f64}, p100())), "invalid-input")

def cov_axis2_inv__want() -> Bool:
  True{}

def cov_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.cone_val(co_z(), V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})), "numerical-uncertainty")

def cov_ovf_unc__want() -> Bool:
  True{}

def cov_kneg_inv__got() -> Bool:
  String.eq(G.gres_show(O.cone_val(G.Co{p000(), d001(), F64.neg(0.5f64)}, p100())), "invalid-input")

def cov_kneg_inv__want() -> Bool:
  True{}

def cog_102__got() -> Bool:
  d_bits_eq(O.cone_grad(co_z(), V.Pt{1.0f64, 0.0f64, 2.0f64}), 4611686018427387904u64, 0u64, 13830554455654793216u64)

def cog_102__want() -> Bool:
  True{}

def cog_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.cone_grad(co_z(), V.Pt{0.0f64, F64.nan(), 0.0f64})), "invalid-input")

def cog_nan_inv__want() -> Bool:
  True{}

def cog_axis2_inv__got() -> Bool:
  String.eq(G.gres_show(O.cone_grad(G.Co{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, 0.5f64}, p100())), "invalid-input")

def cog_axis2_inv__want() -> Bool:
  True{}

def cog_k0_inv__got() -> Bool:
  String.eq(G.gres_show(O.cone_grad(G.Co{p000(), d001(), 0.0f64}, p100())), "invalid-input")

def cog_k0_inv__want() -> Bool:
  True{}

def coax_2__got() -> Bool:
  f_bits_eq(O.cone_ax(co_z(), V.Pt{1.0f64, 0.0f64, 2.0f64}), 4611686018427387904u64)

def coax_2__want() -> Bool:
  True{}

def coax_neg__got() -> Bool:
  f_bits_eq(O.cone_ax(co_z(), V.Pt{0.0f64, 0.0f64, F64.neg(3.0f64)}), 13837309855095848960u64)

def coax_neg__want() -> Bool:
  True{}

def coax_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.cone_ax(co_z(), V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")

def coax_nan_inv__want() -> Bool:
  True{}

def coax_axis2_inv__got() -> Bool:
  String.eq(G.gres_show(O.cone_ax(G.Co{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, 0.5f64}, p100())), "invalid-input")

def coax_axis2_inv__want() -> Bool:
  True{}

def coax_kneg_inv__got() -> Bool:
  String.eq(G.gres_show(O.cone_ax(G.Co{p000(), d001(), F64.neg(0.5f64)}, p123())), "invalid-input")

def coax_kneg_inv__want() -> Bool:
  True{}

def torv_eq__got() -> Bool:
  f_bits_eq(O.tor_val(to_z(), V.Pt{5.0f64, 0.0f64, 0.0f64}), 0u64)

def torv_eq__want() -> Bool:
  True{}

def torv_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.tor_val(to_z(), V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")

def torv_nan_inv__want() -> Bool:
  True{}

def torv_axis2_inv__got() -> Bool:
  String.eq(G.gres_show(O.tor_val(G.To{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, 4.0f64, 1.0f64}, p100())), "invalid-input")

def torv_axis2_inv__want() -> Bool:
  True{}

def torv_ovf_unc__got() -> Bool:
  String.eq(G.gres_show(O.tor_val(to_z(), V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})), "numerical-uncertainty")

def torv_ovf_unc__want() -> Bool:
  True{}

def torv_Rneg_inv__got() -> Bool:
  String.eq(G.gres_show(O.tor_val(G.To{p000(), d001(), F64.neg(4.0f64), 1.0f64}, p100())), "invalid-input")

def torv_Rneg_inv__want() -> Bool:
  True{}

def torg_eq__got() -> Bool:
  d_bits_eq(O.tor_grad(to_z(), V.Pt{5.0f64, 0.0f64, 0.0f64}), 4639833516098453504u64, 0u64, 0u64)

def torg_eq__want() -> Bool:
  True{}

def torg_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.tor_grad(to_z(), V.Pt{0.0f64, F64.nan(), 0.0f64})), "invalid-input")

def torg_nan_inv__want() -> Bool:
  True{}

def torg_axis2_inv__got() -> Bool:
  String.eq(G.gres_show(O.tor_grad(G.To{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, 4.0f64, 1.0f64}, p100())), "invalid-input")

def torg_axis2_inv__want() -> Bool:
  True{}

def torg_r0_inv__got() -> Bool:
  String.eq(G.gres_show(O.tor_grad(G.To{p000(), d001(), 4.0f64, 0.0f64}, p100())), "invalid-input")

def torg_r0_inv__want() -> Bool:
  True{}

def tse_t0__got() -> Bool:
  v2_bits_eq(O.tseg_eval(ts_diag(), 0.0f64), 0u64, 0u64)

def tse_t0__want() -> Bool:
  True{}

def tse_t05__got() -> Bool:
  v2_bits_eq(O.tseg_eval(ts_diag(), 0.5f64), 4602678819172646912u64, 4602678819172646912u64)

def tse_t05__want() -> Bool:
  True{}

def tse_t1__got() -> Bool:
  v2_bits_eq(O.tseg_eval(ts_diag(), 1.0f64), 4607182418800017408u64, 4607182418800017408u64)

def tse_t1__want() -> Bool:
  True{}

def tse_u2_inv__got() -> Bool:
  String.eq(G.gres_show(O.tseg_eval(ts_diag(), 2.0f64)), "invalid-input")

def tse_u2_inv__want() -> Bool:
  True{}

def tse_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.tseg_eval(ts_diag(), F64.nan())), "invalid-input")

def tse_nan_inv__want() -> Bool:
  True{}

def tse_tsnan_inv__got() -> Bool:
  String.eq(G.gres_show(O.tseg_eval(G.Ts{v2_00(), V.V2{F64.nan(), 0.0f64}}, 0.5f64)), "invalid-input")

def tse_tsnan_inv__want() -> Bool:
  True{}

def tbe_t0__got() -> Bool:
  v2_bits_eq(O.tbez_eval(tb_s(), 0.0f64), 0u64, 0u64)

def tbe_t0__want() -> Bool:
  True{}

def tbe_t05__got() -> Bool:
  v2_bits_eq(O.tbez_eval(tb_s(), 0.5f64), 4602678819172646912u64, 4602678819172646912u64)

def tbe_t05__want() -> Bool:
  True{}

def tbe_t1__got() -> Bool:
  v2_bits_eq(O.tbez_eval(tb_s(), 1.0f64), 4607182418800017408u64, 4607182418800017408u64)

def tbe_t1__want() -> Bool:
  True{}

def tbe_u2_inv__got() -> Bool:
  String.eq(G.gres_show(O.tbez_eval(tb_s(), 2.0f64)), "invalid-input")

def tbe_u2_inv__want() -> Bool:
  True{}

def tbe_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.tbez_eval(tb_s(), F64.nan())), "invalid-input")

def tbe_nan_inv__want() -> Bool:
  True{}

def tsbb_diag__got() -> Bool:
  bb_bits_eq(O.tseg_bbox(ts_diag()), 0u64, 0u64, 0u64, 4607182418800017408u64, 4607182418800017408u64, 0u64)

def tsbb_diag__want() -> Bool:
  True{}

def tsbb_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.tseg_bbox(G.Ts{v2_00(), V.V2{0.0f64, F64.nan()}})), "invalid-input")

def tsbb_nan_inv__want() -> Bool:
  True{}

def tbbb_s__got() -> Bool:
  bb_bits_eq(O.tbez_bbox(tb_s()), 0u64, 0u64, 0u64, 4607182418800017408u64, 4607182418800017408u64, 0u64)

def tbbb_s__want() -> Bool:
  True{}

def tbbb_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.tbez_bbox(G.Tb{v2_00(), v2_11(), V.V2{F64.nan(), 0.0f64}, v2_11()})), "invalid-input")

def tbbb_nan_inv__want() -> Bool:
  True{}

def trimpt_23__got() -> Bool:
  p_bits_eq(O.plane_trim_pt(pl_xy(), V.V2{2.0f64, 3.0f64}), 4611686018427387904u64, 4613937818241073152u64, 0u64)

def trimpt_23__want() -> Bool:
  True{}

def trimpt_frame_inv__got() -> Bool:
  String.eq(G.gres_show(O.plane_trim_pt(pl_bad(), V.V2{2.0f64, 3.0f64})), "invalid-input")

def trimpt_frame_inv__want() -> Bool:
  True{}

def trimpt_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.plane_trim_pt(pl_xy(), V.V2{F64.nan(), 0.0f64})), "invalid-input")

def trimpt_nan_inv__want() -> Bool:
  True{}

def nok_ok__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_checked(nbk1(), 9n)), "ok")

def nok_ok__want() -> Bool:
  True{}

def nok_fuel0_exh__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_checked(nbk1(), 0n)), "resource-exhausted")

def nok_fuel0_exh__want() -> Bool:
  True{}

def nok_fuel5_exh__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_checked(nbk1(), 5n)), "resource-exhausted")

def nok_fuel5_exh__want() -> Bool:
  True{}

def nok_badcount_inv__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_checked(nbk_short(), 8n)), "invalid-input")

def nok_badcount_inv__want() -> Bool:
  True{}

def nok_uncl_inv__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_checked(nbk_uncl(), 9n)), "invalid-input")

def nok_uncl_inv__want() -> Bool:
  True{}

def nok_dec_inv__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_checked(nbk_dec(), 10n)), "invalid-input")

def nok_dec_inv__want() -> Bool:
  True{}

def nok_w0_inv__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_checked(nbk_w0(), 9n)), "invalid-input")

def nok_w0_inv__want() -> Bool:
  True{}

def nok_wneg_inv__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_checked(G.Nb{nbk1_ks(), nbk1_ps(), 1.0f64 <> 1.0f64 <> F64.neg(1.0f64) <> 1.0f64 <> Nil{}}, 9n)), "invalid-input")

def nok_wneg_inv__want() -> Bool:
  True{}

def nok_nanp_inv__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_checked(nbk_nanp(), 9n)), "invalid-input")

def nok_nanp_inv__want() -> Bool:
  True{}

def nok_nank_inv__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_checked(nbk_nank(), 9n)), "invalid-input")

def nok_nank_inv__want() -> Bool:
  True{}

def nev_t05__got() -> Bool:
  p_bits_eq(O.nurbs_eval(nbk1(), 0.5f64, 9n), 4602678819172646912u64, 4602678819172646912u64, 4593671619917905920u64)

def nev_t05__want() -> Bool:
  True{}

def nev_t0__got() -> Bool:
  p_bits_eq(O.nurbs_eval(nbk1(), 0.0f64, 9n), 0u64, 0u64, 0u64)

def nev_t0__want() -> Bool:
  True{}

def nev_t1__got() -> Bool:
  p_bits_eq(O.nurbs_eval(nbk1(), 1.0f64, 9n), 4607182418800017408u64, 4607182418800017408u64, 4607182418800017408u64)

def nev_t1__want() -> Bool:
  True{}

def nev_t2_inv__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_eval(nbk1(), 2.0f64, 9n)), "invalid-input")

def nev_t2_inv__want() -> Bool:
  True{}

def nev_nan_inv__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_eval(nbk1(), F64.nan(), 9n)), "invalid-input")

def nev_nan_inv__want() -> Bool:
  True{}

def nev_fuel0_exh__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_eval(nbk1(), 0.5f64, 0n)), "resource-exhausted")

def nev_fuel0_exh__want() -> Bool:
  True{}

def nev_fuel5_exh__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_eval(nbk1(), 0.5f64, 5n)), "resource-exhausted")

def nev_fuel5_exh__want() -> Bool:
  True{}

def nev_badcount_inv__got() -> Bool:
  String.eq(G.gres_show(O.nurbs_eval(nbk_short(), 0.5f64, 8n)), "invalid-input")

def nev_badcount_inv__want() -> Bool:
  True{}

def nev_bez_equiv__got() -> Bool:
  ev_eq(O.nurbs_eval(nbk1(), 0.5f64, 9n), O.bez3_eval(bz_s(), 0.5f64))

def nev_bez_equiv__want() -> Bool:
  True{}

def bn8_wrap_once__got() -> Bool:
  f_bits_eq(O.pdom_wrap(pdom_per(), 25.0f64), 4624633867356078080u64)

def bn8_wrap_once__want() -> Bool:
  True{}

def bn10_bez__got() -> Bool:
  ev_in_bb(O.bez3_eval(bz_s(), 0.3f64), O.bez3_bbox(bz_s()))

def bn10_bez__want() -> Bool:
  True{}

def bn10_circ__got() -> Bool:
  ev_in_bb(O.circ_eval(cc_unit(), 0.5f64), O.circ_bbox(cc_unit()))

def bn10_circ__want() -> Bool:
  True{}

def bn10_rqb__got() -> Bool:
  ev_in_bb(O.rqb_eval(rq_q(), 0.5f64), O.rqb_bbox(rq_q()))

def bn10_rqb__want() -> Bool:
  True{}

def bn10_bezp__got() -> Bool:
  ev_in_bb(O.bezp_eval(bp_bump(), 0.5f64, 0.5f64), O.bezp_bbox(bp_bump()))

def bn10_bezp__want() -> Bool:
  True{}

def bn10_line__got() -> Bool:
  ev_in_bb(O.line_eval(ln_x(), 1.5f64), O.line_seg_bbox(p000(), V.Pt{3.0f64, 0.0f64, 0.0f64}))

def bn10_line__want() -> Bool:
  True{}

def bn10_plane__got() -> Bool:
  ev_in_bb(O.plane_eval(pl_xy(), 1.0f64, 1.0f64), O.plane_uv_bbox(pl_xy(), 0.0f64, 2.0f64, 0.0f64, 3.0f64))

def bn10_plane__want() -> Bool:
  True{}

def bn10_tbez__got() -> Bool:
  v2_in_bb(O.tbez_eval(tb_s(), 0.3f64), O.tbez_bbox(tb_s()))

def bn10_tbez__want() -> Bool:
  True{}

def bn11_leval_ovf__got() -> Bool:
  p_bits_eq(O.line_eval(G.Ln{ V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, d100()}, F64{9218868437227405311u64}), 0u64, 0u64, 0u64)

def bn11_leval_ovf__want() -> Bool:
  True{}

def bn11_nev_exh__got() -> Bool:
  p_bits_eq(O.nurbs_eval(nbk1(), 0.5f64, 0n), 0u64, 0u64, 0u64)

def bn11_nev_exh__want() -> Bool:
  True{}

def bn11_plck_inv__got() -> Bool:
  p_bits_eq(O.plane_checked(pl_bad()), 0u64, 0u64, 0u64)

def bn11_plck_inv__want() -> Bool:
  True{}

def bn11_qdisc_nan__got() -> Bool:
  f_bits_eq(O.rqb_disc(G.Rq{p100(), p111(), p010(), 1.0f64, F64.nan(), 1.0f64}), 0u64)

def bn11_qdisc_nan__want() -> Bool:
  True{}

def bn11_wrap_inv__got() -> Bool:
  f_bits_eq(O.pdom_wrap(G.Pdom{G.Dom{F64.nan(), 10.0f64}, True{}}, 2.0f64), 0u64)

def bn11_wrap_inv__want() -> Bool:
  True{}

def sphon_on__got() -> Bool:
  O.sph_on(sp_unit(), p100())

def sphon_on__want() -> Bool:
  True{}

def sphon_0608__got() -> Bool:
  O.sph_on(sp_unit(), V.Pt{0.6f64, 0.8f64, 0.0f64})

def sphon_0608__want() -> Bool:
  True{}

def sphon_off__got() -> Bool:
  O.sph_on(sp_unit(), V.Pt{2.0f64, 0.0f64, 0.0f64})

def sphon_off__want() -> Bool:
  False{}

def sphon_near__got() -> Bool:
  O.sph_on(sp_unit(), V.Pt{G.w_quarter(), G.w_quarter(), 0.0f64})

def sphon_near__want() -> Bool:
  False{}

def sphon_nan__got() -> Bool:
  O.sph_on(sp_unit(), V.Pt{F64.nan(), 0.0f64, 0.0f64})

def sphon_nan__want() -> Bool:
  False{}

def sphon_ovf__got() -> Bool:
  O.sph_on(sp_unit(), V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})

def sphon_ovf__want() -> Bool:
  False{}

def sphon_rneg__got() -> Bool:
  O.sph_on(G.Sp{p000(), F64.neg(1.0f64)}, p100())

def sphon_rneg__want() -> Bool:
  False{}

def cylon_on__got() -> Bool:
  O.cyl_on(cy_z(), V.Pt{1.0f64, 0.0f64, 5.0f64})

def cylon_on__want() -> Bool:
  True{}

def cylon_off__got() -> Bool:
  O.cyl_on(cy_z(), V.Pt{2.0f64, 0.0f64, 0.0f64})

def cylon_off__want() -> Bool:
  False{}

def cylon_near__got() -> Bool:
  O.cyl_on(cy_z(), V.Pt{G.w_quarter(), G.w_quarter(), 0.0f64})

def cylon_near__want() -> Bool:
  False{}

def cylon_nan__got() -> Bool:
  O.cyl_on(cy_z(), V.Pt{F64.nan(), 0.0f64, 0.0f64})

def cylon_nan__want() -> Bool:
  False{}

def cylon_ovf__got() -> Bool:
  O.cyl_on(cy_z(), V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})

def cylon_ovf__want() -> Bool:
  False{}

def cylon_axis2__got() -> Bool:
  O.cyl_on(G.Cy{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, 1.0f64}, V.Pt{1.0f64, 0.0f64, 5.0f64})

def cylon_axis2__want() -> Bool:
  False{}

def cylon_rneg__got() -> Bool:
  O.cyl_on(G.Cy{p000(), d001(), F64.neg(1.0f64)}, p100())

def cylon_rneg__want() -> Bool:
  False{}

def conon_on__got() -> Bool:
  O.cone_on(co_z(), V.Pt{1.0f64, 0.0f64, 2.0f64})

def conon_on__want() -> Bool:
  True{}

def conon_neg__got() -> Bool:
  O.cone_on(co_z(), V.Pt{F64.neg(1.0f64), 0.0f64, F64.neg(2.0f64)})

def conon_neg__want() -> Bool:
  True{}

def conon_apex__got() -> Bool:
  O.cone_on(co_z(), p000())

def conon_apex__want() -> Bool:
  True{}

def conon_off__got() -> Bool:
  O.cone_on(co_z(), V.Pt{2.0f64, 0.0f64, 2.0f64})

def conon_off__want() -> Bool:
  False{}

def conon_near__got() -> Bool:
  O.cone_on(co_z(), V.Pt{1.0f64, 1.0f64, F64.mul(4.0f64, G.w_quarter())})

def conon_near__want() -> Bool:
  False{}

def conon_nan__got() -> Bool:
  O.cone_on(co_z(), V.Pt{F64.nan(), 0.0f64, 0.0f64})

def conon_nan__want() -> Bool:
  False{}

def conon_ovf__got() -> Bool:
  O.cone_on(co_z(), V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})

def conon_ovf__want() -> Bool:
  False{}

def conon_axis2__got() -> Bool:
  O.cone_on(G.Co{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, 0.5f64}, V.Pt{1.0f64, 0.0f64, 2.0f64})

def conon_axis2__want() -> Bool:
  False{}

def conon_kneg__got() -> Bool:
  O.cone_on(G.Co{p000(), d001(), F64.neg(0.5f64)}, p100())

def conon_kneg__want() -> Bool:
  False{}

def toron_out__got() -> Bool:
  O.tor_on(to_z(), V.Pt{5.0f64, 0.0f64, 0.0f64})

def toron_out__want() -> Bool:
  True{}

def toron_in__got() -> Bool:
  O.tor_on(to_z(), V.Pt{3.0f64, 0.0f64, 0.0f64})

def toron_in__want() -> Bool:
  True{}

def toron_top__got() -> Bool:
  O.tor_on(to_z(), V.Pt{4.0f64, 0.0f64, 1.0f64})

def toron_top__want() -> Bool:
  True{}

def toron_off__got() -> Bool:
  O.tor_on(to_z(), V.Pt{2.0f64, 0.0f64, 0.0f64})

def toron_off__want() -> Bool:
  False{}

def toron_near__got() -> Bool:
  O.tor_on(to_z(), V.Pt{F64.add(4.0f64, G.w_quarter()), 0.0f64, G.w_quarter()})

def toron_near__want() -> Bool:
  False{}

def toron_nan__got() -> Bool:
  O.tor_on(to_z(), V.Pt{F64.nan(), 0.0f64, 0.0f64})

def toron_nan__want() -> Bool:
  False{}

def toron_ovf__got() -> Bool:
  O.tor_on(to_z(), V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})

def toron_ovf__want() -> Bool:
  False{}

def toron_axis2__got() -> Bool:
  O.tor_on(G.To{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, 4.0f64, 1.0f64}, V.Pt{5.0f64, 0.0f64, 0.0f64})

def toron_axis2__want() -> Bool:
  False{}

def toron_Rneg__got() -> Bool:
  O.tor_on(G.To{p000(), d001(), F64.neg(4.0f64), 1.0f64}, p100())

def toron_Rneg__want() -> Bool:
  False{}

def bez_hull_x_hi__got() -> U64:
  F64.bits(V.pt_x(G.bb_hi(G.gres_bb(O.bez3_bbox(hull_bz())))))

def bez_hull_x_hi__want() -> U64:
  4591870180066957722u64

def bez_eval_above_hull__got() -> U64:
  F64.bits(V.pt_x(G.gres_p(O.bez3_eval(hull_bz(), 0.1f64))))

def bez_eval_above_hull__want() -> U64:
  4591870180066957723u64

def bez_eval_below_hull__got() -> U64:
  F64.bits(V.pt_x(G.gres_p(O.bez3_eval(hull_bz(), 0.3f64))))

def bez_eval_below_hull__want() -> U64:
  4591870180066957720u64

def cylon_r_round__got() -> Bool:
  O.q_on_r(G.GV_cy{cy_r()}, q_cyr())

def cylon_r_round__want() -> Bool:
  True{}

def cylon_x_round__got() -> Bool:
  O.cyl_on(cy_r(), q_cyr())

def cylon_x_round__want() -> Bool:
  False{}

def cylon_r_far__got() -> Bool:
  O.q_on_r(G.GV_cy{cy_r()}, V.Pt{up3((10.0f64 + 3.2f64 : F64)), 0.0f64, 5.0f64})

def cylon_r_far__want() -> Bool:
  False{}

def cylon_r_off__got() -> Bool:
  O.q_on_r(G.GV_cy{cy_r()}, V.Pt{(10.0f64 + 3.200001f64 : F64), 0.0f64, 5.0f64})

def cylon_r_off__want() -> Bool:
  False{}

def cylon_r_exact__got() -> Bool:
  O.q_on_r(G.GV_cy{G.Cy{V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 0.5f64}}, V.Pt{1.5f64, 0.0f64, 7.0f64})

def cylon_r_exact__want() -> Bool:
  True{}

def cylon_r_axis__got() -> Bool:
  O.q_on_r(G.GV_cy{G.Cy{V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 2.0f64}, 0.5f64}}, V.Pt{1.5f64, 0.0f64, 7.0f64})

def cylon_r_axis__want() -> Bool:
  False{}

def sphon_r_round__got() -> Bool:
  O.q_on_r(G.GV_sp{G.Sp{V.Pt{0.1f64, 0.2f64, 0.3f64}, 0.7f64}}, V.Pt{(0.1f64 + 0.7f64 : F64), 0.2f64, 0.3f64})

def sphon_r_round__want() -> Bool:
  True{}

def toron_r_round__got() -> Bool:
  O.q_on_r(G.GV_to{G.To{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 2.3f64, 0.45f64}}, V.Pt{(2.3f64 + 0.45f64 : F64), 0.0f64, 0.0f64})

def toron_r_round__want() -> Bool:
  True{}

def toron_x_round__got() -> Bool:
  O.tor_on(G.To{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 2.3f64, 0.45f64}, V.Pt{(2.3f64 + 0.45f64 : F64), 0.0f64, 0.0f64})

def toron_x_round__want() -> Bool:
  False{}

def conon_r_round__got() -> Bool:
  O.q_on_r(G.GV_co{G.Co{V.Pt{1.0f64, 1.0f64, 1.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 0.3f64}}, V.Pt{(1.0f64 + (0.3f64 * 2.1f64 : F64) : F64), 1.0f64, (1.0f64 + 2.1f64 : F64)})

def conon_r_round__want() -> Bool:
  True{}

def conon_x_round__got() -> Bool:
  O.cone_on(G.Co{V.Pt{1.0f64, 1.0f64, 1.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 0.3f64}, V.Pt{(1.0f64 + (0.3f64 * 2.1f64 : F64) : F64), 1.0f64, (1.0f64 + 2.1f64 : F64)})

def conon_x_round__want() -> Bool:
  False{}

def qon_r_plane__got() -> Bool:
  O.q_on_r(G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}}}, V.Pt{1.0f64, 1.0f64, 0.0f64})

def qon_r_plane__want() -> Bool:
  False{}
