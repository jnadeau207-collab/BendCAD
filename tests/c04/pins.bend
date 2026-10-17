import Base

import ../../src/c00/types.bend as T

import ../../src/c01/types.bend as V

import ../../src/c03/types.bend as G

import ../../src/c03/ops.bend as GO

import ../../src/c04/types.bend as Ty

import ../../src/c04/ops.bend as Op

import ../../src/base/par.bend as B

def pt_bits_eq(+p: V.Point, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  Bool.and(U64.is_eq(F64.bits(V.pt_x(p)), wx),
    Bool.and(U64.is_eq(F64.bits(V.pt_y(p)), wy),
      U64.is_eq(F64.bits(V.pt_z(p)), wz)))

def dr_bits_eq(+d: V.Dir, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  Bool.and(U64.is_eq(F64.bits(V.dr_x(d)), wx),
    Bool.and(U64.is_eq(F64.bits(V.dr_y(d)), wy),
      U64.is_eq(F64.bits(V.dr_z(d)), wz)))

def v2_bits_eq(+v: V.Vec2, +wx: U64, +wy: U64) -> Bool:
  Bool.and(U64.is_eq(F64.bits(V.v2_x(v)), wx),
    U64.is_eq(F64.bits(V.v2_y(v)), wy))

def ts_zero_bits(t: G.GVal) -> Bool:
  match t:
    case G.GV_ts{w}:
      G.Ts{a, b} = w
      Bool.and(v2_bits_eq(a, 0u64, 0u64),
        v2_bits_eq(b, 0u64, 0u64))
    case _: False{}

def pl_zero_bits(s: G.GVal) -> Bool:
  match s:
    case G.GV_pl{w}:
      G.Pl{o, u, v} = w
      Bool.and(pt_bits_eq(o, 0u64, 0u64, 0u64),
        Bool.and(dr_bits_eq(u, 0u64, 0u64, 0u64),
          dr_bits_eq(v, 0u64, 0u64, 0u64)))
    case _: False{}

def ln_zero_bits(c: G.GVal) -> Bool:
  match c:
    case G.GV_ln{w}:
      G.Ln{p, d} = w
      Bool.and(pt_bits_eq(p, 0u64, 0u64, 0u64),
        dr_bits_eq(d, 0u64, 0u64, 0u64))
    case _: False{}

def hv_null_chk(h: Ty.HVertex) -> Bool:
  Ty.HV{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def he_null_chk(h: Ty.HEdge) -> Bool:
  Ty.HE{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def hc_null_chk(h: Ty.HCoedge) -> Bool:
  Ty.HC{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def hlp_null_chk(h: Ty.HLoop) -> Bool:
  Ty.HL{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def hfa_null_chk(h: Ty.HFace) -> Bool:
  Ty.HF{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def hsh_null_chk(h: Ty.HShell) -> Bool:
  Ty.HS{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def hso_null_chk(h: Ty.HSolid) -> Bool:
  Ty.HSo{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def r_vx_zero(+r: Ty.TRes) -> Bool:
  +v = Ty.tres_vx(r)
  Bool.and(U64.is_eq(Ty.vx_gen(v), 0u64),
    pt_bits_eq(Ty.vx_p(v), 0u64, 0u64, 0u64))

def r_ed_dflt(+r: Ty.TRes) -> Bool:
  +e = Ty.tres_ed(r)
  Bool.and(U64.is_eq(Ty.ed_gen(e), 0u64),
    Bool.and(hv_null_chk(Ty.ed_v0(e)),
      Bool.and(hv_null_chk(Ty.ed_v1(e)),
        U64.is_eq(Ty.ekind_tag(Ty.ed_kind(e)), 1u64))))

def r_ce_dflt(+r: Ty.TRes) -> Bool:
  +c = Ty.tres_ce(r)
  Bool.and(U64.is_eq(Ty.ce_gen(c), 0u64),
    Bool.and(he_null_chk(Ty.ce_edge(c)),
      Bool.and(Bool.not(Ty.ce_fwd(c)),
        ts_zero_bits(Ty.ce_trim(c)))))

def r_lp_dflt(+r: Ty.TRes) -> Bool:
  +l = Ty.tres_lp(r)
  Bool.and(U64.is_eq(Ty.lp_gen(l), 0u64),
    Bool.and(Bool.not(Ty.hce_nonempty(Ty.lp_ces(l))),
      U64.is_eq(Ty.lkind_tag(Ty.lp_kind(l)), 0u64)))

def r_fa_dflt(+r: Ty.TRes) -> Bool:
  +f = Ty.tres_fa(r)
  Bool.and(U64.is_eq(Ty.fa_gen(f), 0u64),
    Bool.and(pl_zero_bits(Ty.fa_surf(f)),
      Bool.and(Bool.not(Ty.hlp_nonempty(Ty.fa_loops(f))),
        Ty.fa_same(f))))

def r_sh_dflt(+r: Ty.TRes) -> Bool:
  +s = Ty.tres_sh(r)
  Bool.and(U64.is_eq(Ty.sh_gen(s), 0u64),
    Bool.and(Bool.not(Ty.hfa_nonempty(Ty.sh_faces(s))),
      U64.is_eq(Ty.skind_tag(Ty.sh_kind(s)), 2u64)))

def r_so_dflt(+r: Ty.TRes) -> Bool:
  +s = Ty.tres_so(r)
  Bool.and(U64.is_eq(Ty.so_gen(s), 0u64),
    Bool.and(hsh_null_chk(Ty.so_outer(s)),
      Bool.not(Ty.hsh_nonempty(Ty.so_cavities(s)))))

def r_cp_empty(+r: Ty.TRes) -> Bool:
  +c = Ty.tres_cp(r)
  Bool.and(Bool.not(Ty.hso_nonempty(Ty.cp_solids(c))),
    Bool.not(Ty.hsh_nonempty(Ty.cp_shells(c))))

def r_brep_empty(+r: Ty.TRes) -> Bool:
  +b = Ty.tres_brep(r)
  Bool.and(U64.is_eq(Ty.brep_stamp(b), 0u64),
    Bool.and(
      Nat.is_eq(Ty.tres_n(Ty.vx_len(Ty.brep_vs(b), 8n)), 0n),
      Bool.not(Ty.cp_has_solids(Ty.brep_top(b)))))

def p000() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def p100() -> V.Point:
  V.Pt{1.0f64, 0.0f64, 0.0f64}

def p010() -> V.Point:
  V.Pt{0.0f64, 1.0f64, 0.0f64}

def p300() -> V.Point:
  V.Pt{3.0f64, 0.0f64, 0.0f64}

def p330() -> V.Point:
  V.Pt{3.0f64, 3.0f64, 0.0f64}

def p030() -> V.Point:
  V.Pt{0.0f64, 3.0f64, 0.0f64}

def p001() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 1.0f64}

def p111() -> V.Point:
  V.Pt{1.0f64, 1.0f64, 1.0f64}

def p110() -> V.Point:
  V.Pt{1.0f64, 1.0f64, 0.0f64}

def q00() -> V.Point:
  V.Pt{1.0f64, 1.0f64, 0.0f64}

def q10() -> V.Point:
  V.Pt{2.0f64, 1.0f64, 0.0f64}

def q11() -> V.Point:
  V.Pt{2.0f64, 2.0f64, 0.0f64}

def q01() -> V.Point:
  V.Pt{1.0f64, 2.0f64, 0.0f64}

def p123() -> V.Point:
  V.Pt{1.0f64, 2.0f64, 3.0f64}

def pnan() -> V.Point:
  V.Pt{F64.nan(), 0.0f64, 0.0f64}

def pinf() -> V.Point:
  V.Pt{F64{9218868437227405312u64}, 0.0f64, 0.0f64}

def d100() -> V.Dir:
  V.Dr{1.0f64, 0.0f64, 0.0f64}

def d010() -> V.Dir:
  V.Dr{0.0f64, 1.0f64, 0.0f64}

def d001() -> V.Dir:
  V.Dr{0.0f64, 0.0f64, 1.0f64}

def d_n100() -> V.Dir:
  V.Dr{F64.neg(1.0f64), 0.0f64, 0.0f64}

def d_0n10() -> V.Dir:
  V.Dr{0.0f64, F64.neg(1.0f64), 0.0f64}

def d300() -> V.Dir:
  V.Dr{3.0f64, 0.0f64, 0.0f64}

def d030() -> V.Dir:
  V.Dr{0.0f64, 3.0f64, 0.0f64}

def d_n300() -> V.Dir:
  V.Dr{F64.neg(3.0f64), 0.0f64, 0.0f64}

def d_0n30() -> V.Dir:
  V.Dr{0.0f64, F64.neg(3.0f64), 0.0f64}

def d_110() -> V.Dir:
  V.Dr{1.0f64, 1.0f64, 0.0f64}

def d_n110() -> V.Dir:
  V.Dr{F64.neg(1.0f64), 1.0f64, 0.0f64}

def v2_00() -> V.Vec2:
  V.V2{0.0f64, 0.0f64}

def v2_10() -> V.Vec2:
  V.V2{1.0f64, 0.0f64}

def v2_01() -> V.Vec2:
  V.V2{0.0f64, 1.0f64}

def v2_11() -> V.Vec2:
  V.V2{1.0f64, 1.0f64}

def v2_30() -> V.Vec2:
  V.V2{3.0f64, 0.0f64}

def v2_33() -> V.Vec2:
  V.V2{3.0f64, 3.0f64}

def v2_03() -> V.Vec2:
  V.V2{0.0f64, 3.0f64}

def w00() -> V.Vec2:
  V.V2{1.0f64, 1.0f64}

def w10() -> V.Vec2:
  V.V2{2.0f64, 1.0f64}

def w11() -> V.Vec2:
  V.V2{2.0f64, 2.0f64}

def w01() -> V.Vec2:
  V.V2{1.0f64, 2.0f64}

def dom_01() -> G.Dom:
  G.Dom{0.0f64, 1.0f64}

def dom_n11() -> G.Dom:
  G.Dom{F64.neg(1.0f64), 1.0f64}

def dom_flip() -> G.Dom:
  G.Dom{2.0f64, 1.0f64}

def dom_eq() -> G.Dom:
  G.Dom{1.0f64, 1.0f64}

def dom_nan() -> G.Dom:
  G.Dom{F64.nan(), 1.0f64}

def cv_ln() -> G.GVal:
  G.GV_ln{G.Ln{p000(), d100()}}

def cv_cc() -> G.GVal:
  G.GV_cc{G.Cc{p000(), d100(), d010(), 1.0f64}}

def cv_bz() -> G.GVal:
  G.GV_bz{G.Bz{p000(), p100(), p010(), p111()}}

def cv_rq() -> G.GVal:
  G.GV_rq{G.Rq{p100(), p110(), p010(), 1.0f64, 1.0f64,
    1.0f64}}

def nb_ks() -> List<&2, F64>:
  0.0f64 <> 0.0f64 <> 0.0f64 <> 0.0f64 <> 1.0f64 <> 1.0f64 <>
    1.0f64 <> 1.0f64 <> Nil{}

def nb_ps() -> List<&2, V.Point>:
  p000() <> p100() <> p010() <> p111() <> Nil{}

def nb_ws() -> List<&2, F64>:
  1.0f64 <> 1.0f64 <> 1.0f64 <> 1.0f64 <> Nil{}

def cv_nb() -> G.GVal:
  G.GV_nb{G.Nb{nb_ks(), nb_ps(), nb_ws()}}

def sf_pl() -> G.GVal:
  G.GV_pl{G.Pl{p000(), d100(), d010()}}

def sf_pl_flip() -> G.GVal:
  G.GV_pl{G.Pl{p000(), d010(), d100()}}

def p_spc() -> V.Point:
  V.Pt{0.5f64, 0.5f64, 0.25f64}

def p_cyo() -> V.Point:
  V.Pt{0.0f64, 0.5f64, 0.0f64}

def p_cy_top() -> V.Point:
  V.Pt{1.0f64, 0.5f64, 0.0f64}

def p_mid01() -> V.Point:
  V.Pt{0.5f64, 0.0f64, 0.0f64}

def p500() -> V.Point:
  V.Pt{5.0f64, 0.0f64, 0.0f64}

def vs_q() -> List<&2, Ty.Vertex>:
  Ty.Vx{1u64, p000()} <> Ty.Vx{2u64, p001()} <> Ty.Vx{3u64,
    p500()} <> Nil{}

def ix_vs(+vs: List<&2, Ty.Vertex>) -> Ty.Ix:
  Ty.ix_mk(vs, Nil{}, Nil{}, Nil{}, Nil{}, Nil{}, Nil{})

def sf_cy() -> G.GVal:
  G.GV_cy{G.Cy{p_cyo(), d100(), 0.5f64}}

def sf_botcap() -> G.GVal:
  G.GV_pl{G.Pl{p010(), d010(), d001()}}

def sf_topcap() -> G.GVal:
  G.GV_pl{G.Pl{p110(), d010(), d001()}}

def cc_bot() -> G.GVal:
  G.GV_cc{G.Cc{p_cyo(), d_0n10(), d001(), 0.5f64}}

def cc_top() -> G.GVal:
  G.GV_cc{G.Cc{p_cy_top(), d_0n10(), d001(), 0.5f64}}

def cc_arc0() -> G.GVal:
  G.GV_cc{G.Cc{p_mid01(), d_n100(), d010(), 0.5f64}}

def cc_arc1() -> G.GVal:
  G.GV_cc{G.Cc{p_mid01(), d_n100(), d_0n10(), 0.5f64}}

def sf_co() -> G.GVal:
  G.GV_co{G.Co{p000(), d001(), 0.5f64}}

def sf_sp() -> G.GVal:
  G.GV_sp{G.Sp{p_spc(), 0.75f64}}

def sf_to() -> G.GVal:
  G.GV_to{G.To{p000(), d001(), 4.0f64, 1.0f64}}

def bp0() -> G.BezP:
  G.Bp{p000(), p100(), p010(), p001(), p110(), p111(),
    p123(), p000(), p100(), p010(), p001(), p110(), p111(),
    p123(), p000(), p100()}

def sf_bp() -> G.GVal:
  G.GV_bp{bp0()}

def tr_ts() -> G.GVal:
  G.GV_ts{G.Ts{v2_00(), v2_11()}}

def tr_tb() -> G.GVal:
  G.GV_tb{G.Tb{v2_00(), v2_10(), v2_01(), v2_11()}}

def tr_00_10() -> G.GVal:
  G.GV_ts{G.Ts{v2_00(), v2_10()}}

def tr_10_11() -> G.GVal:
  G.GV_ts{G.Ts{v2_10(), v2_11()}}

def tr_11_01() -> G.GVal:
  G.GV_ts{G.Ts{v2_11(), v2_01()}}

def tr_01_00() -> G.GVal:
  G.GV_ts{G.Ts{v2_01(), v2_00()}}

def tr_00_11() -> G.GVal:
  G.GV_ts{G.Ts{v2_00(), v2_11()}}

def tr_11_10() -> G.GVal:
  G.GV_ts{G.Ts{v2_11(), v2_10()}}

def tr_10_01() -> G.GVal:
  G.GV_ts{G.Ts{v2_10(), v2_01()}}

def ts_00_30() -> G.GVal:
  G.GV_ts{G.Ts{v2_00(), v2_30()}}

def ts_30_33() -> G.GVal:
  G.GV_ts{G.Ts{v2_30(), v2_33()}}

def ts_33_03() -> G.GVal:
  G.GV_ts{G.Ts{v2_33(), v2_03()}}

def ts_03_00() -> G.GVal:
  G.GV_ts{G.Ts{v2_03(), v2_00()}}

def tq_00_10() -> G.GVal:
  G.GV_ts{G.Ts{w00(), w10()}}

def tq_10_11() -> G.GVal:
  G.GV_ts{G.Ts{w10(), w11()}}

def tq_11_01() -> G.GVal:
  G.GV_ts{G.Ts{w11(), w01()}}

def tq_01_00() -> G.GVal:
  G.GV_ts{G.Ts{w01(), w00()}}

def tr_10_00() -> G.GVal:
  G.GV_ts{G.Ts{v2_10(), v2_00()}}

def tr_01_11() -> G.GVal:
  G.GV_ts{G.Ts{v2_01(), v2_11()}}

def tr_00_01() -> G.GVal:
  G.GV_ts{G.Ts{v2_00(), v2_01()}}

def hv01() -> Ty.HVertex:
  Ty.mk_hv(0n, 1u64)

def hv12() -> Ty.HVertex:
  Ty.mk_hv(1n, 2u64)

def hv23() -> Ty.HVertex:
  Ty.mk_hv(2n, 3u64)

def he01() -> Ty.HEdge:
  Ty.mk_he(0n, 11u64)

def he12() -> Ty.HEdge:
  Ty.mk_he(1n, 12u64)

def hc_a() -> Ty.HCoedge:
  Ty.mk_hc(0n, 21u64)

def hc_b() -> Ty.HCoedge:
  Ty.mk_hc(1n, 22u64)

def hlp_a() -> Ty.HLoop:
  Ty.mk_hlp(0n, 31u64)

def hfa_a() -> Ty.HFace:
  Ty.mk_hfa(0n, 41u64)

def hsh_a() -> Ty.HShell:
  Ty.mk_hsh(0n, 51u64)

def hso_a() -> Ty.HSolid:
  Ty.mk_hso(0n, 61u64)

def hce0() -> List<&2, Ty.HCoedge>:
  Nil{}

def hc1() -> List<&2, Ty.HCoedge>:
  hc_a() <> Nil{}

def hc2() -> List<&2, Ty.HCoedge>:
  hc_a() <> hc_b() <> Nil{}

def hlp0() -> List<&2, Ty.HLoop>:
  Nil{}

def hlp1() -> List<&2, Ty.HLoop>:
  hlp_a() <> Nil{}

def hfa0() -> List<&2, Ty.HFace>:
  Nil{}

def hfa1() -> List<&2, Ty.HFace>:
  hfa_a() <> Nil{}

def hsh0() -> List<&2, Ty.HShell>:
  Nil{}

def hsh1() -> List<&2, Ty.HShell>:
  hsh_a() <> Nil{}

def hso0() -> List<&2, Ty.HSolid>:
  Nil{}

def hso1() -> List<&2, Ty.HSolid>:
  hso_a() <> Nil{}

def vx_a() -> Ty.Vertex:
  Ty.Vx{1u64, p000()}

def vx_b() -> Ty.Vertex:
  Ty.Vx{2u64, p100()}

def vs0() -> List<&2, Ty.Vertex>:
  Nil{}

def vs1() -> List<&2, Ty.Vertex>:
  vx_a() <> Nil{}

def vs2() -> List<&2, Ty.Vertex>:
  vx_a() <> vx_b() <> Nil{}

def vs_bad() -> List<&2, Ty.Vertex>:
  Ty.Vx{1u64, pnan()} <> Nil{}

def vs_gen0() -> List<&2, Ty.Vertex>:
  Ty.Vx{0u64, p000()} <> Nil{}

def vs_dup() -> List<&2, Ty.Vertex>:
  Ty.Vx{1u64, p000()} <> Ty.Vx{1u64, p100()} <> Nil{}

def ed_a() -> Ty.Edge:
  Ty.Ed{11u64, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}}

def ed_b() -> Ty.Edge:
  Ty.Ed{12u64, hv12(), hv23(),
    Ty.EK_curve{cv_cc(), dom_01()}}

def es0() -> List<&2, Ty.Edge>:
  Nil{}

def es1() -> List<&2, Ty.Edge>:
  ed_a() <> Nil{}

def es2() -> List<&2, Ty.Edge>:
  ed_a() <> ed_b() <> Nil{}

def es_badarm() -> List<&2, Ty.Edge>:
  Ty.Ed{11u64, hv01(), hv12(),
    Ty.EK_curve{sf_pl(), dom_01()}} <> Nil{}

def es_baddegen() -> List<&2, Ty.Edge>:
  Ty.Ed{11u64, hv01(), hv12(),
    Ty.EK_degenerate{}} <> Nil{}

def ce_a() -> Ty.Coedge:
  Ty.Ce{21u64, he01(), True{}, tr_ts()}

def ce_b() -> Ty.Coedge:
  Ty.Ce{22u64, he01(), False{}, tr_tb()}

def ces0() -> List<&2, Ty.Coedge>:
  Nil{}

def ces1() -> List<&2, Ty.Coedge>:
  ce_a() <> Nil{}

def ces2() -> List<&2, Ty.Coedge>:
  ce_a() <> ce_b() <> Nil{}

def ces_bad() -> List<&2, Ty.Coedge>:
  Ty.Ce{21u64, he01(), True{}, cv_ln()} <> Nil{}

def lp_a() -> Ty.Loop:
  Ty.Lp{31u64, hc_a() <> Nil{}, Ty.LK_outer{}}

def lp_b() -> Ty.Loop:
  Ty.Lp{32u64, hc2(), Ty.LK_inner{}}

def lps0() -> List<&2, Ty.Loop>:
  Nil{}

def lps1() -> List<&2, Ty.Loop>:
  lp_a() <> Nil{}

def lps2() -> List<&2, Ty.Loop>:
  lp_a() <> lp_b() <> Nil{}

def lps_bad() -> List<&2, Ty.Loop>:
  Ty.Lp{31u64, hce0(), Ty.LK_outer{}} <> Nil{}

def fa_a() -> Ty.Face:
  Ty.Fa{41u64, sf_pl(), hlp_a() <> Nil{}, True{}, 0.0f64, 0.0f64}

def fa_b() -> Ty.Face:
  Ty.Fa{42u64, sf_cy(), Ty.mk_hlp(1n, 32u64) <> Nil{},
    False{}, 0.0f64, 0.0f64}

def fas0() -> List<&2, Ty.Face>:
  Nil{}

def fas1() -> List<&2, Ty.Face>:
  fa_a() <> Nil{}

def fas2() -> List<&2, Ty.Face>:
  fa_a() <> fa_b() <> Nil{}

def fas_badarm() -> List<&2, Ty.Face>:
  Ty.Fa{41u64, cv_ln(), hlp1(), True{}, 0.0f64, 0.0f64} <> Nil{}

def fas_badloops() -> List<&2, Ty.Face>:
  Ty.Fa{41u64, sf_pl(), hlp0(), True{}, 0.0f64, 0.0f64} <> Nil{}

def sh_a() -> Ty.Shell:
  Ty.Sh{51u64, hfa_a() <> Nil{}, Ty.SK_outer{}}

def sh_b() -> Ty.Shell:
  Ty.Sh{52u64, Ty.mk_hfa(1n, 42u64) <> Nil{},
    Ty.SK_inner{}}

def shs0() -> List<&2, Ty.Shell>:
  Nil{}

def shs1() -> List<&2, Ty.Shell>:
  sh_a() <> Nil{}

def shs2() -> List<&2, Ty.Shell>:
  sh_a() <> sh_b() <> Nil{}

def shs_bad() -> List<&2, Ty.Shell>:
  Ty.Sh{51u64, hfa0(), Ty.SK_outer{}} <> Nil{}

def so_a() -> Ty.Solid:
  Ty.So{61u64, hsh_a(), hsh0()}

def so_b() -> Ty.Solid:
  Ty.So{62u64, hsh_a(), hsh1()}

def sos0() -> List<&2, Ty.Solid>:
  Nil{}

def sos1() -> List<&2, Ty.Solid>:
  so_a() <> Nil{}

def sos2() -> List<&2, Ty.Solid>:
  so_a() <> so_b() <> Nil{}

def top0() -> Ty.Compound:
  Ty.Cp{hso0(), hsh0()}

def top1() -> Ty.Compound:
  Ty.Cp{hso1(), hsh1()}

def b_empty() -> Ty.Brep:
  Ty.brep_empty()

def b_fuel_gap() -> Ty.Brep:
  Ty.Br{vs_bad(), es0(), ces0(), lp_b() <> Nil{}, fas0(), shs0(),
    sos0(), top0(), 32u64}

def b_vs1() -> Ty.Brep:
  Ty.Br{vs1(), es0(), ces0(), lps0(), fas0(), shs0(), sos0(),
    top0(), 1u64}

def b_es1() -> Ty.Brep:
  Ty.Br{vs0(), es1(), ces0(), lps0(), fas0(), shs0(), sos0(),
    top0(), 11u64}

def b_ces1() -> Ty.Brep:
  Ty.Br{vs0(), es0(), ces1(), lps0(), fas0(), shs0(), sos0(),
    top0(), 21u64}

def b_lps1() -> Ty.Brep:
  Ty.Br{vs0(), es0(), ces0(), lps1(), fas0(), shs0(), sos0(),
    top0(), 31u64}

def b_fas1() -> Ty.Brep:
  Ty.Br{vs0(), es0(), ces0(), lps0(), fas1(), shs0(), sos0(),
    top0(), 41u64}

def b_shs1() -> Ty.Brep:
  Ty.Br{vs0(), es0(), ces0(), lps0(), fas0(), shs1(), sos0(),
    top0(), 51u64}

def b_sos1() -> Ty.Brep:
  Ty.Br{vs0(), es0(), ces0(), lps0(), fas0(), shs0(), sos1(),
    top0(), 61u64}

def vx_r() -> Ty.Vertex:
  Ty.Vx{9u64, p123()}

def ed_r() -> Ty.Edge:
  Ty.Ed{19u64, hv01(), hv12(),
    Ty.EK_curve{cv_cc(), dom_01()}}

def ce_r() -> Ty.Coedge:
  Ty.Ce{29u64, he01(), False{}, tr_tb()}

def lp_r() -> Ty.Loop:
  Ty.Lp{39u64, hc2(), Ty.LK_inner{}}

def fa_r() -> Ty.Face:
  Ty.Fa{49u64, sf_cy(), hlp1(), False{}, 0.0f64, 0.0f64}

def sh_r() -> Ty.Shell:
  Ty.Sh{59u64, hfa1(), Ty.SK_inner{}}

def so_r() -> Ty.Solid:
  Ty.So{69u64, hsh_a(), hsh1()}

def cp_r() -> Ty.Compound:
  Ty.Cp{hso1(), hsh1()}

def r_pvx() -> Ty.TRes:
  Ty.vx_push(b_empty(), p123())

def b_pvx() -> Ty.Brep:
  Ty.tres_brep(r_pvx())

def h_iss_vx() -> Ty.HVertex:
  Ty.tres_hv(Ty.vx_issued(b_vs1(), 8n))

def h_hof_vx() -> Ty.HVertex:
  Ty.tres_hv(Ty.vx_handle_of(vs2(), 2u64, 8n))

def v_at_vx() -> Ty.Vertex:
  Ty.tres_vx(Ty.vx_at(vs2(), 1n, 8n))

def r_res_vx() -> Ty.TRes:
  Ty.vx_resolve(vs2(), Ty.mk_hv(1n, 2u64), 8n)

def v_res_vx() -> Ty.Vertex:
  Ty.tres_vx(r_res_vx())

def r_ped() -> Ty.TRes:
  Ty.ed_push(b_empty(), hv01(), hv12(), Ty.EK_curve{cv_ln(), dom_01()})

def b_ped() -> Ty.Brep:
  Ty.tres_brep(r_ped())

def h_iss_ed() -> Ty.HEdge:
  Ty.tres_he(Ty.ed_issued(b_es1(), 8n))

def h_hof_ed() -> Ty.HEdge:
  Ty.tres_he(Ty.ed_handle_of(es2(), 12u64, 8n))

def v_at_ed() -> Ty.Edge:
  Ty.tres_ed(Ty.ed_at(es2(), 1n, 8n))

def r_res_ed() -> Ty.TRes:
  Ty.ed_resolve(es2(), Ty.mk_he(1n, 12u64), 8n)

def v_res_ed() -> Ty.Edge:
  Ty.tres_ed(r_res_ed())

def r_pce() -> Ty.TRes:
  Ty.ce_push(b_empty(), he01(), True{}, tr_ts())

def b_pce() -> Ty.Brep:
  Ty.tres_brep(r_pce())

def h_iss_ce() -> Ty.HCoedge:
  Ty.tres_hc(Ty.ce_issued(b_ces1(), 8n))

def h_hof_ce() -> Ty.HCoedge:
  Ty.tres_hc(Ty.ce_handle_of(ces2(), 22u64, 8n))

def v_at_ce() -> Ty.Coedge:
  Ty.tres_ce(Ty.ce_at(ces2(), 1n, 8n))

def r_res_ce() -> Ty.TRes:
  Ty.ce_resolve(ces2(), Ty.mk_hc(1n, 22u64), 8n)

def v_res_ce() -> Ty.Coedge:
  Ty.tres_ce(r_res_ce())

def r_plp() -> Ty.TRes:
  Ty.lp_push(b_empty(), hc1(), Ty.LK_outer{})

def b_plp() -> Ty.Brep:
  Ty.tres_brep(r_plp())

def h_iss_lp() -> Ty.HLoop:
  Ty.tres_hlp(Ty.lp_issued(b_lps1(), 8n))

def h_hof_lp() -> Ty.HLoop:
  Ty.tres_hlp(Ty.lp_handle_of(lps2(), 32u64, 8n))

def v_at_lp() -> Ty.Loop:
  Ty.tres_lp(Ty.lp_at(lps2(), 1n, 8n))

def r_res_lp() -> Ty.TRes:
  Ty.lp_resolve(lps2(), Ty.mk_hlp(1n, 32u64), 8n)

def v_res_lp() -> Ty.Loop:
  Ty.tres_lp(r_res_lp())

def r_pfa() -> Ty.TRes:
  Ty.fa_push(b_empty(), sf_pl(), hlp1(), True{})

def b_pfa() -> Ty.Brep:
  Ty.tres_brep(r_pfa())

def h_iss_fa() -> Ty.HFace:
  Ty.tres_hfa(Ty.fa_issued(b_fas1(), 8n))

def h_hof_fa() -> Ty.HFace:
  Ty.tres_hfa(Ty.fa_handle_of(fas2(), 42u64, 8n))

def v_at_fa() -> Ty.Face:
  Ty.tres_fa(Ty.fa_at(fas2(), 1n, 8n))

def r_res_fa() -> Ty.TRes:
  Ty.fa_resolve(fas2(), Ty.mk_hfa(1n, 42u64), 8n)

def v_res_fa() -> Ty.Face:
  Ty.tres_fa(r_res_fa())

def r_psh() -> Ty.TRes:
  Ty.sh_push(b_empty(), hfa1(), Ty.SK_outer{})

def b_psh() -> Ty.Brep:
  Ty.tres_brep(r_psh())

def h_iss_sh() -> Ty.HShell:
  Ty.tres_hsh(Ty.sh_issued(b_shs1(), 8n))

def h_hof_sh() -> Ty.HShell:
  Ty.tres_hsh(Ty.sh_handle_of(shs2(), 52u64, 8n))

def v_at_sh() -> Ty.Shell:
  Ty.tres_sh(Ty.sh_at(shs2(), 1n, 8n))

def r_res_sh() -> Ty.TRes:
  Ty.sh_resolve(shs2(), Ty.mk_hsh(1n, 52u64), 8n)

def v_res_sh() -> Ty.Shell:
  Ty.tres_sh(r_res_sh())

def r_pso() -> Ty.TRes:
  Ty.so_push(b_empty(), hsh_a(), hsh0())

def b_pso() -> Ty.Brep:
  Ty.tres_brep(r_pso())

def h_iss_so() -> Ty.HSolid:
  Ty.tres_hso(Ty.so_issued(b_sos1(), 8n))

def h_hof_so() -> Ty.HSolid:
  Ty.tres_hso(Ty.so_handle_of(sos2(), 62u64, 8n))

def v_at_so() -> Ty.Solid:
  Ty.tres_so(Ty.so_at(sos2(), 1n, 8n))

def r_res_so() -> Ty.TRes:
  Ty.so_resolve(sos2(), Ty.mk_hso(1n, 62u64), 8n)

def v_res_so() -> Ty.Solid:
  Ty.tres_so(r_res_so())

def tr_closed() -> G.GVal:
  G.GV_ts{G.Ts{v2_00(), v2_00()}}

def tr_bad() -> G.GVal:
  G.GV_ts{G.Ts{V.V2{2.0f64, 2.0f64}, V.V2{3.0f64, 3.0f64}}}

def b_sphere_digon_control() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_ts()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc0 <> hc1 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.sh_push(b7, hfa0 <> Nil{}, Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 8u64)
  +b9 = Ty.tres_brep(Ty.so_push(b8, hsh_out, hsh0()))
  +hso0x = Ty.mk_hso(0n, 9u64)
  Ty.brep_set_top(b9, Ty.Cp{hso0x <> Nil{}, hsh0()})

def b_cyl_digon_ruling_control() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_ts()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc0 <> hc1 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_cy(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.sh_push(b7, hfa0 <> Nil{}, Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 8u64)
  +b9 = Ty.tres_brep(Ty.so_push(b8, hsh_out, hsh0()))
  +hso0x = Ty.mk_hso(0n, 9u64)
  Ty.brep_set_top(b9, Ty.Cp{hso0x <> Nil{}, hsh0()})

def b_cyl_side() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p010()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p110()))
  +hvB = Ty.mk_hv(0n, 1u64)
  +hvT = Ty.mk_hv(1n, 2u64)
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hvB, hvB,
    Ty.EK_curve{cc_bot(), dom_n11()}))
  +heB = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ed_push(b3, hvB, hvT,
    Ty.EK_curve{G.GV_ln{G.Ln{p010(), d100()}}, dom_01()}))
  +heS = Ty.mk_he(1n, 4u64)
  +b5 = Ty.tres_brep(Ty.ed_push(b4, hvT, hvT,
    Ty.EK_curve{cc_top(), dom_n11()}))
  +heT = Ty.mk_he(2n, 5u64)
  +b6 = Ty.tres_brep(Ty.ce_push(b5, heB, True{}, tr_00_10()))
  +b7 = Ty.tres_brep(Ty.ce_push(b6, heB, False{}, tr_closed()))
  +b8 = Ty.tres_brep(Ty.ce_push(b7, heS, True{}, tr_10_11()))
  +b9 = Ty.tres_brep(Ty.ce_push(b8, heS, False{}, tr_00_01()))
  +b10 = Ty.tres_brep(Ty.ce_push(b9, heT, True{}, tr_11_01()))
  +b11 = Ty.tres_brep(Ty.ce_push(b10, heT, False{}, tr_closed()))
  +hcBT = Ty.mk_hc(0n, 6u64)
  +hcBF = Ty.mk_hc(1n, 7u64)
  +hcST = Ty.mk_hc(2n, 8u64)
  +hcSF = Ty.mk_hc(3n, 9u64)
  +hcTT = Ty.mk_hc(4n, 10u64)
  +hcTF = Ty.mk_hc(5n, 11u64)
  +b12 = Ty.tres_brep(Ty.lp_push(b11,
    hcBT <> hcST <> hcTT <> hcSF <> Nil{}, Ty.LK_outer{}))
  +b13 = Ty.tres_brep(Ty.lp_push(b12, hcBF <> Nil{},
    Ty.LK_outer{}))
  +b14 = Ty.tres_brep(Ty.lp_push(b13, hcTF <> Nil{},
    Ty.LK_outer{}))
  +hlpS = Ty.mk_hlp(0n, 12u64)
  +hlpB = Ty.mk_hlp(1n, 13u64)
  +hlpT = Ty.mk_hlp(2n, 14u64)
  +b15 = Ty.tres_brep(Ty.fa_push(b14, sf_cy(), hlpS <> Nil{},
    True{}))
  +b16 = Ty.tres_brep(Ty.fa_push(b15, sf_botcap(), hlpB <> Nil{},
    True{}))
  +b17 = Ty.tres_brep(Ty.fa_push(b16, sf_topcap(), hlpT <> Nil{},
    True{}))
  +hfaS = Ty.mk_hfa(0n, 15u64)
  +hfaB = Ty.mk_hfa(1n, 16u64)
  +hfaT = Ty.mk_hfa(2n, 17u64)
  +b18 = Ty.tres_brep(Ty.sh_push(b17,
    hfaS <> hfaB <> hfaT <> Nil{}, Ty.SK_outer{}))
  +hshS = Ty.mk_hsh(0n, 18u64)
  +b19 = Ty.tres_brep(Ty.so_push(b18, hshS, hsh0()))
  +hsoS = Ty.mk_hso(0n, 19u64)
  Ty.brep_set_top(b19, Ty.Cp{hsoS <> Nil{}, hsh0()})

def b_sphere_curved() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +hvN = Ty.mk_hv(0n, 1u64)
  +hvS = Ty.mk_hv(1n, 2u64)
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hvN, hvS,
    Ty.EK_curve{cc_arc0(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_ts()))
  +b6 = Ty.tres_brep(Ty.ed_push(b5, hvN, hvS,
    Ty.EK_curve{cc_arc1(), dom_01()}))
  +he1 = Ty.mk_he(1n, 6u64)
  +b7 = Ty.tres_brep(Ty.ce_push(b6, he1, True{}, tr_ts()))
  +b8 = Ty.tres_brep(Ty.ce_push(b7, he1, False{}, tr_ts()))
  +e0f = Ty.mk_hc(0n, 4u64)
  +e0b = Ty.mk_hc(1n, 5u64)
  +e1f = Ty.mk_hc(2n, 7u64)
  +e1b = Ty.mk_hc(3n, 8u64)
  +b9 = Ty.tres_brep(Ty.lp_push(b8, e0f <> e1b <> Nil{},
    Ty.LK_outer{}))
  +b10 = Ty.tres_brep(Ty.lp_push(b9, e1f <> e0b <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 9u64)
  +hlp1 = Ty.mk_hlp(1n, 10u64)
  +b11 = Ty.tres_brep(Ty.fa_push(b10, sf_sp(), hlp0 <> Nil{},
    True{}))
  +b12 = Ty.tres_brep(Ty.fa_push(b11, sf_sp(), hlp1 <> Nil{},
    True{}))
  +hfa0 = Ty.mk_hfa(0n, 11u64)
  +hfa1 = Ty.mk_hfa(1n, 12u64)
  +b13 = Ty.tres_brep(Ty.sh_push(b12, hfa0 <> hfa1 <> Nil{},
    Ty.SK_outer{}))
  +hshS = Ty.mk_hsh(0n, 13u64)
  +b14 = Ty.tres_brep(Ty.so_push(b13, hshS, hsh0()))
  +hsoS = Ty.mk_hso(0n, 14u64)
  Ty.brep_set_top(b14, Ty.Cp{hsoS <> Nil{}, hsh0()})

def b_open() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.ed_push(b1, hv01(), hv01(),
    Ty.EK_degenerate{}))
  +he0 = Ty.mk_he(0n, 2u64)
  +b3 = Ty.tres_brep(Ty.ce_push(b2, he0, True{}, tr_closed()))
  +hc0 = Ty.mk_hc(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.lp_push(b3, hc0 <> Nil{}, Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 4u64)
  +b5 = Ty.tres_brep(Ty.fa_push(b4, sf_pl(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 5u64)
  +b6 = Ty.tres_brep(Ty.sh_push(b5, hfa0 <> Nil{}, Ty.SK_open{}))
  +hsh0 = Ty.mk_hsh(0n, 6u64)
  Ty.brep_set_top(b6, Ty.Cp{hso0(), hsh0 <> Nil{}})

def b_pole() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.ed_push(b1, hv01(), hv01(),
    Ty.EK_degenerate{}))
  +he0 = Ty.mk_he(0n, 2u64)
  +b3 = Ty.tres_brep(Ty.ce_push(b2, he0, True{}, tr_closed()))
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, False{}, tr_closed()))
  +hc0 = Ty.mk_hc(0n, 3u64)
  +hc1 = Ty.mk_hc(1n, 4u64)
  +b5 = Ty.tres_brep(Ty.lp_push(b4, hc0 <> Nil{}, Ty.LK_outer{}))
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc1 <> Nil{}, Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 5u64)
  +hlp1 = Ty.mk_hlp(1n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{}, True{}))
  +b8 = Ty.tres_brep(Ty.fa_push(b7, sf_sp(), hlp1 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +hfa1 = Ty.mk_hfa(1n, 8u64)
  +b9 = Ty.tres_brep(Ty.sh_push(b8, hfa0 <> hfa1 <> Nil{},
    Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 9u64)
  +b10 = Ty.tres_brep(Ty.so_push(b9, hsh_out, hsh0()))
  +hso0x = Ty.mk_hso(0n, 10u64)
  Ty.brep_set_top(b10, Ty.Cp{hso0x <> Nil{}, hsh0()})

def b_cav() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_ts()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc0 <> hc1 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.sh_push(b7, hfa0 <> Nil{}, Ty.SK_outer{}))
  +b9 = Ty.tres_brep(Ty.vx_push(b8, p010()))
  +b10 = Ty.tres_brep(Ty.vx_push(b9, p110()))
  +hvN2 = Ty.mk_hv(2n, 9u64)
  +hvS2 = Ty.mk_hv(3n, 10u64)
  +b11 = Ty.tres_brep(Ty.ed_push(b10, hvN2, hvS2,
    Ty.EK_curve{G.GV_ln{G.Ln{p010(), d100()}}, dom_01()}))
  +he1 = Ty.mk_he(1n, 11u64)
  +b12 = Ty.tres_brep(Ty.ce_push(b11, he1, True{}, tr_ts()))
  +b13 = Ty.tres_brep(Ty.ce_push(b12, he1, False{}, tr_ts()))
  +hc2x = Ty.mk_hc(2n, 12u64)
  +hc3x = Ty.mk_hc(3n, 13u64)
  +b14 = Ty.tres_brep(Ty.lp_push(b13, hc2x <> hc3x <> Nil{},
    Ty.LK_outer{}))
  +hlp1x = Ty.mk_hlp(1n, 14u64)
  +b15 = Ty.tres_brep(Ty.fa_push(b14, sf_sp(), hlp1x <> Nil{},
    True{}))
  +hfa1x = Ty.mk_hfa(1n, 15u64)
  +b16 = Ty.tres_brep(Ty.sh_push(b15, hfa1x <> Nil{}, Ty.SK_inner{}))
  +hsh_in = Ty.mk_hsh(1n, 16u64)
  +hsh_out = Ty.mk_hsh(0n, 8u64)
  +b17 = Ty.tres_brep(Ty.so_push(b16, hsh_out, hsh_in <> Nil{}))
  +hso0 = Ty.mk_hso(0n, 17u64)
  Ty.brep_set_top(b17, Ty.Cp{hso0 <> Nil{}, hsh0()})

def b_dang() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +hvBad = Ty.mk_hv(5n, 99u64)
  Ty.tres_brep(Ty.ed_push(b1, hv01(), hvBad,
    Ty.EK_curve{cv_ln(), dom_01()}))

def b_inv() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, True{}, tr_ts()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc0 <> hc1 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.sh_push(b7, hfa0 <> Nil{}, Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 8u64)
  +b9 = Ty.tres_brep(Ty.so_push(b8, hsh_out, hsh0()))
  +hso0x = Ty.mk_hso(0n, 9u64)
  Ty.brep_set_top(b9, Ty.Cp{hso0x <> Nil{}, hsh0()})

def b_trimx() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_bad()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc0 <> hc1 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.sh_push(b7, hfa0 <> Nil{}, Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 8u64)
  +b9 = Ty.tres_brep(Ty.so_push(b8, hsh_out, hsh0()))
  +hso0x = Ty.mk_hso(0n, 9u64)
  Ty.brep_set_top(b9, Ty.Cp{hso0x <> Nil{}, hsh0()})

def b_embx() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p010()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_ts()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc0 <> hc1 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.sh_push(b7, hfa0 <> Nil{}, Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 8u64)
  +b9 = Ty.tres_brep(Ty.so_push(b8, hsh_out, hsh0()))
  +hso0x = Ty.mk_hso(0n, 9u64)
  Ty.brep_set_top(b9, Ty.Cp{hso0x <> Nil{}, hsh0()})

def b_nonm() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_ts()))
  +b6 = Ty.tres_brep(Ty.ce_push(b5, he0, True{}, tr_ts()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +hc2 = Ty.mk_hc(2n, 6u64)
  +b7 = Ty.tres_brep(Ty.lp_push(b6, hc0 <> hc1 <> hc2 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.fa_push(b7, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 8u64)
  +b9 = Ty.tres_brep(Ty.sh_push(b8, hfa0 <> Nil{}, Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 9u64)
  +b10 = Ty.tres_brep(Ty.so_push(b9, hsh_out, hsh0()))
  +hso0x = Ty.mk_hso(0n, 10u64)
  Ty.brep_set_top(b10, Ty.Cp{hso0x <> Nil{}, hsh0()})

def b_selfx() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p010()))
  +b2 = Ty.tres_brep(Ty.ed_push(b1, hv01(), hv01(),
    Ty.EK_curve{cc_bot(), dom_n11()}))
  +he0 = Ty.mk_he(0n, 2u64)
  +b3 = Ty.tres_brep(Ty.ce_push(b2, he0, True{}, tr_closed()))
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, False{}, tr_closed()))
  +hc0 = Ty.mk_hc(0n, 3u64)
  +b5 = Ty.tres_brep(Ty.lp_push(b4, hc0 <> hc0 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 5u64)
  +b6 = Ty.tres_brep(Ty.fa_push(b5, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.sh_push(b6, hfa0 <> Nil{}, Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.so_push(b7, hsh_out, hsh0()))
  +hso0x = Ty.mk_hso(0n, 8u64)
  Ty.brep_set_top(b8, Ty.Cp{hso0x <> Nil{}, hsh0()})

def b_alias() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_ts()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc0 <> hc1 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.sh_push(b7, hfa0 <> Nil{}, Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 8u64)
  +b9 = Ty.tres_brep(Ty.so_push(b8, hsh_out, hsh_out <> Nil{}))
  +hso0x = Ty.mk_hso(0n, 9u64)
  Ty.brep_set_top(b9, Ty.Cp{hso0x <> Nil{}, hsh0()})

def b_outerkind() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_ts()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc0 <> hc1 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.sh_push(b7, hfa0 <> Nil{}, Ty.SK_inner{}))
  +hsh_out = Ty.mk_hsh(0n, 8u64)
  +b9 = Ty.tres_brep(Ty.so_push(b8, hsh_out, hsh0()))
  +hso0x = Ty.mk_hso(0n, 9u64)
  Ty.brep_set_top(b9, Ty.Cp{hso0x <> Nil{}, hsh0()})

def b_cavdup() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_ts()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc0 <> hc1 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{},
    True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.sh_push(b7, hfa0 <> Nil{}, Ty.SK_outer{}))
  +b9 = Ty.tres_brep(Ty.vx_push(b8, p000()))
  +b10 = Ty.tres_brep(Ty.vx_push(b9, p100()))
  +hvN2 = Ty.mk_hv(2n, 9u64)
  +hvS2 = Ty.mk_hv(3n, 10u64)
  +b11 = Ty.tres_brep(Ty.ed_push(b10, hvN2, hvS2,
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he1 = Ty.mk_he(1n, 11u64)
  +b12 = Ty.tres_brep(Ty.ce_push(b11, he1, True{}, tr_ts()))
  +b13 = Ty.tres_brep(Ty.ce_push(b12, he1, False{}, tr_ts()))
  +hc2x = Ty.mk_hc(2n, 12u64)
  +hc3x = Ty.mk_hc(3n, 13u64)
  +b14 = Ty.tres_brep(Ty.lp_push(b13, hc2x <> hc3x <> Nil{},
    Ty.LK_outer{}))
  +hlp1x = Ty.mk_hlp(1n, 14u64)
  +b15 = Ty.tres_brep(Ty.fa_push(b14, sf_sp(), hlp1x <> Nil{},
    True{}))
  +hfa1x = Ty.mk_hfa(1n, 15u64)
  +b16 = Ty.tres_brep(Ty.sh_push(b15, hfa1x <> Nil{}, Ty.SK_inner{}))
  +hsh_in = Ty.mk_hsh(1n, 16u64)
  +hsh_out = Ty.mk_hsh(0n, 8u64)
  +b17 = Ty.tres_brep(Ty.so_push(b16, hsh_out,
    hsh_in <> hsh_in <> Nil{}))
  +hso0 = Ty.mk_hso(0n, 17u64)
  Ty.brep_set_top(b17, Ty.Cp{hso0 <> Nil{}, hsh0()})

def b_reuse() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_ts()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc0 <> hc1 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.sh_push(b7, hfa0 <> Nil{}, Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 8u64)
  +b9 = Ty.tres_brep(Ty.so_push(b8, hsh_out, hsh0()))
  +b10 = Ty.tres_brep(Ty.so_push(b9, hsh_out, hsh0()))
  +hso0x = Ty.mk_hso(0n, 9u64)
  +hso1x = Ty.mk_hso(1n, 10u64)
  Ty.brep_set_top(b10, Ty.Cp{hso0x <> hso1x <> Nil{}, hsh0()})

def b_cpshare() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_ts()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc0 <> hc1 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.sh_push(b7, hfa0 <> Nil{}, Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 8u64)
  +b9 = Ty.tres_brep(Ty.so_push(b8, hsh_out, hsh0()))
  +hso0x = Ty.mk_hso(0n, 9u64)
  Ty.brep_set_top(b9, Ty.Cp{hso0x <> Nil{}, hsh_out <> Nil{}})

def b_pinch() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.vx_push(b2, p010()))
  +hvS = Ty.mk_hv(0n, 1u64)
  +hvA = Ty.mk_hv(1n, 2u64)
  +hvB = Ty.mk_hv(2n, 3u64)
  +b4 = Ty.tres_brep(Ty.ed_push(b3, hvS, hvA,
    Ty.EK_curve{cv_ln(), dom_01()}))
  +heA = Ty.mk_he(0n, 4u64)
  +b5 = Ty.tres_brep(Ty.ce_push(b4, heA, True{}, tr_ts()))
  +b6 = Ty.tres_brep(Ty.ce_push(b5, heA, False{}, tr_ts()))
  +b7 = Ty.tres_brep(Ty.ed_push(b6, hvS, hvB,
    Ty.EK_curve{G.GV_ln{G.Ln{p000(), d010()}}, dom_01()}))
  +heB = Ty.mk_he(1n, 7u64)
  +b8 = Ty.tres_brep(Ty.ce_push(b7, heB, True{}, tr_ts()))
  +b9 = Ty.tres_brep(Ty.ce_push(b8, heB, False{}, tr_ts()))
  +hcA0 = Ty.mk_hc(0n, 5u64)
  +hcA1 = Ty.mk_hc(1n, 6u64)
  +hcB0 = Ty.mk_hc(2n, 8u64)
  +hcB1 = Ty.mk_hc(3n, 9u64)
  +b10 = Ty.tres_brep(Ty.lp_push(b9, hcA0 <> hcA1 <> Nil{},
    Ty.LK_outer{}))
  +b11 = Ty.tres_brep(Ty.lp_push(b10, hcB0 <> hcB1 <> Nil{},
    Ty.LK_outer{}))
  +hlpA = Ty.mk_hlp(0n, 10u64)
  +hlpB = Ty.mk_hlp(1n, 11u64)
  +b12 = Ty.tres_brep(Ty.fa_push(b11, sf_sp(), hlpA <> Nil{},
    True{}))
  +b13 = Ty.tres_brep(Ty.fa_push(b12, sf_sp(), hlpB <> Nil{},
    True{}))
  +hfaA = Ty.mk_hfa(0n, 12u64)
  +hfaB = Ty.mk_hfa(1n, 13u64)
  +b14 = Ty.tres_brep(Ty.sh_push(b13, hfaA <> Nil{},
    Ty.SK_outer{}))
  +b15 = Ty.tres_brep(Ty.sh_push(b14, hfaB <> Nil{},
    Ty.SK_outer{}))
  +hshA = Ty.mk_hsh(0n, 14u64)
  +hshB = Ty.mk_hsh(1n, 15u64)
  +b16 = Ty.tres_brep(Ty.so_push(b15, hshA, hsh0()))
  +b17 = Ty.tres_brep(Ty.so_push(b16, hshB, hsh0()))
  +hsoA = Ty.mk_hso(0n, 16u64)
  +hsoB = Ty.mk_hso(1n, 17u64)
  Ty.brep_set_top(b17, Ty.Cp{hsoA <> hsoB <> Nil{}, hsh0()})

def b_offquad() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p001()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{G.GV_ln{G.Ln{p000(), d001()}}, dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_ts()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc0 <> hc1 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.sh_push(b7, hfa0 <> Nil{}, Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 8u64)
  +b9 = Ty.tres_brep(Ty.so_push(b8, hsh_out, hsh0()))
  +hso0x = Ty.mk_hso(0n, 9u64)
  Ty.brep_set_top(b9, Ty.Cp{hso0x <> Nil{}, hsh0()})

def b_split() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.vx_push(b2, p010()))
  +b4 = Ty.tres_brep(Ty.vx_push(b3, p110()))
  +hvA0 = Ty.mk_hv(0n, 1u64)
  +hvA1 = Ty.mk_hv(1n, 2u64)
  +hvB0 = Ty.mk_hv(2n, 3u64)
  +hvB1 = Ty.mk_hv(3n, 4u64)
  +b5 = Ty.tres_brep(Ty.ed_push(b4, hvA0, hvA1,
    Ty.EK_curve{cv_ln(), dom_01()}))
  +heA = Ty.mk_he(0n, 5u64)
  +b6 = Ty.tres_brep(Ty.ce_push(b5, heA, True{}, tr_ts()))
  +b7 = Ty.tres_brep(Ty.ce_push(b6, heA, False{}, tr_ts()))
  +b8 = Ty.tres_brep(Ty.ed_push(b7, hvB0, hvB1,
    Ty.EK_curve{G.GV_ln{G.Ln{p010(), d100()}}, dom_01()}))
  +heB = Ty.mk_he(1n, 8u64)
  +b9 = Ty.tres_brep(Ty.ce_push(b8, heB, True{}, tr_ts()))
  +b10 = Ty.tres_brep(Ty.ce_push(b9, heB, False{}, tr_ts()))
  +hcA0 = Ty.mk_hc(0n, 6u64)
  +hcA1 = Ty.mk_hc(1n, 7u64)
  +hcB0 = Ty.mk_hc(2n, 9u64)
  +hcB1 = Ty.mk_hc(3n, 10u64)
  +b11 = Ty.tres_brep(Ty.lp_push(b10, hcA0 <> hcA1 <> Nil{},
    Ty.LK_outer{}))
  +b12 = Ty.tres_brep(Ty.lp_push(b11, hcB0 <> hcB1 <> Nil{},
    Ty.LK_outer{}))
  +hlpA = Ty.mk_hlp(0n, 11u64)
  +hlpB = Ty.mk_hlp(1n, 12u64)
  +b13 = Ty.tres_brep(Ty.fa_push(b12, sf_sp(), hlpA <> Nil{},
    True{}))
  +b14 = Ty.tres_brep(Ty.fa_push(b13, sf_sp(), hlpB <> Nil{},
    True{}))
  +hfaA = Ty.mk_hfa(0n, 13u64)
  +hfaB = Ty.mk_hfa(1n, 14u64)
  +b15 = Ty.tres_brep(Ty.sh_push(b14, hfaA <> hfaB <> Nil{},
    Ty.SK_outer{}))
  +hshS = Ty.mk_hsh(0n, 15u64)
  +b16 = Ty.tres_brep(Ty.so_push(b15, hshS, hsh0()))
  +hsoS = Ty.mk_hso(0n, 16u64)
  Ty.brep_set_top(b16, Ty.Cp{hsoS <> Nil{}, hsh0()})

def b_coin() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_ts()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_ts()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +b6 = Ty.tres_brep(Ty.lp_push(b5, hc0 <> hc1 <> Nil{},
    Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 6u64)
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 7u64)
  +b8 = Ty.tres_brep(Ty.sh_push(b7, hfa0 <> Nil{}, Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 8u64)
  +b9 = Ty.tres_brep(Ty.so_push(b8, hsh_out, hsh0()))
  +b10 = Ty.tres_brep(Ty.vx_push(b9, p000()))
  +hso0x = Ty.mk_hso(0n, 9u64)
  Ty.brep_set_top(b10, Ty.Cp{hso0x <> Nil{}, hsh0()})

def b_xing() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p110()))
  +b3 = Ty.tres_brep(Ty.vx_push(b2, p100()))
  +b4 = Ty.tres_brep(Ty.vx_push(b3, p010()))
  +hv0 = Ty.mk_hv(0n, 1u64)
  +hv1 = Ty.mk_hv(1n, 2u64)
  +hv2 = Ty.mk_hv(2n, 3u64)
  +hv3 = Ty.mk_hv(3n, 4u64)
  +b5 = Ty.tres_brep(Ty.ed_push(b4, hv0, hv1,
    Ty.EK_curve{G.GV_ln{G.Ln{p000(), d_110()}}, dom_01()}))
  +he0 = Ty.mk_he(0n, 5u64)
  +b6 = Ty.tres_brep(Ty.ce_push(b5, he0, True{}, tr_00_11()))
  +b7 = Ty.tres_brep(Ty.ce_push(b6, he0, False{}, tr_00_11()))
  +b8 = Ty.tres_brep(Ty.ed_push(b7, hv1, hv2,
    Ty.EK_curve{G.GV_ln{G.Ln{p110(), d_0n10()}}, dom_01()}))
  +he1 = Ty.mk_he(1n, 8u64)
  +b9 = Ty.tres_brep(Ty.ce_push(b8, he1, True{}, tr_11_10()))
  +b10 = Ty.tres_brep(Ty.ce_push(b9, he1, False{}, tr_11_10()))
  +b11 = Ty.tres_brep(Ty.ed_push(b10, hv2, hv3,
    Ty.EK_curve{G.GV_ln{G.Ln{p100(), d_n110()}}, dom_01()}))
  +he2 = Ty.mk_he(2n, 11u64)
  +b12 = Ty.tres_brep(Ty.ce_push(b11, he2, True{}, tr_10_01()))
  +b13 = Ty.tres_brep(Ty.ce_push(b12, he2, False{}, tr_10_01()))
  +b14 = Ty.tres_brep(Ty.ed_push(b13, hv3, hv0,
    Ty.EK_curve{G.GV_ln{G.Ln{p010(), d_0n10()}}, dom_01()}))
  +he3 = Ty.mk_he(3n, 14u64)
  +b15 = Ty.tres_brep(Ty.ce_push(b14, he3, True{}, tr_01_00()))
  +b16 = Ty.tres_brep(Ty.ce_push(b15, he3, False{}, tr_01_00()))
  +hc0 = Ty.mk_hc(0n, 6u64)
  +hc2 = Ty.mk_hc(2n, 9u64)
  +hc4 = Ty.mk_hc(4n, 12u64)
  +hc6 = Ty.mk_hc(6n, 15u64)
  +hc1 = Ty.mk_hc(1n, 7u64)
  +hc3 = Ty.mk_hc(3n, 10u64)
  +hc5 = Ty.mk_hc(5n, 13u64)
  +hc7 = Ty.mk_hc(7n, 16u64)
  +b17 = Ty.tres_brep(Ty.lp_push(b16,
    hc0 <> hc2 <> hc4 <> hc6 <> Nil{}, Ty.LK_outer{}))
  +b18 = Ty.tres_brep(Ty.lp_push(b17,
    hc7 <> hc5 <> hc3 <> hc1 <> Nil{}, Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 17u64)
  +hlp1 = Ty.mk_hlp(1n, 18u64)
  +b19 = Ty.tres_brep(Ty.fa_push(b18, sf_pl(), hlp0 <> Nil{},
    True{}))
  +b20 = Ty.tres_brep(Ty.fa_push(b19, sf_pl(), hlp1 <> Nil{},
    True{}))
  +hfa0 = Ty.mk_hfa(0n, 19u64)
  +hfa1 = Ty.mk_hfa(1n, 20u64)
  +b21 = Ty.tres_brep(Ty.sh_push(b20, hfa0 <> hfa1 <> Nil{},
    Ty.SK_outer{}))
  +hshS = Ty.mk_hsh(0n, 21u64)
  +b22 = Ty.tres_brep(Ty.so_push(b21, hshS, hsh0()))
  +hsoS = Ty.mk_hso(0n, 22u64)
  Ty.brep_set_top(b22, Ty.Cp{hsoS <> Nil{}, hsh0()})

def b_invface() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.vx_push(b2, p110()))
  +b4 = Ty.tres_brep(Ty.vx_push(b3, p010()))
  +hv0 = Ty.mk_hv(0n, 1u64)
  +hv1 = Ty.mk_hv(1n, 2u64)
  +hv2 = Ty.mk_hv(2n, 3u64)
  +hv3 = Ty.mk_hv(3n, 4u64)
  +b5 = Ty.tres_brep(Ty.ed_push(b4, hv0, hv1,
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 5u64)
  +b6 = Ty.tres_brep(Ty.ce_push(b5, he0, True{}, tr_00_10()))
  +b7 = Ty.tres_brep(Ty.ce_push(b6, he0, False{}, tr_00_10()))
  +b8 = Ty.tres_brep(Ty.ed_push(b7, hv1, hv2,
    Ty.EK_curve{G.GV_ln{G.Ln{p100(), d010()}}, dom_01()}))
  +he1 = Ty.mk_he(1n, 8u64)
  +b9 = Ty.tres_brep(Ty.ce_push(b8, he1, True{}, tr_10_11()))
  +b10 = Ty.tres_brep(Ty.ce_push(b9, he1, False{}, tr_10_11()))
  +b11 = Ty.tres_brep(Ty.ed_push(b10, hv2, hv3,
    Ty.EK_curve{G.GV_ln{G.Ln{p110(), d_n100()}}, dom_01()}))
  +he2 = Ty.mk_he(2n, 11u64)
  +b12 = Ty.tres_brep(Ty.ce_push(b11, he2, True{}, tr_11_01()))
  +b13 = Ty.tres_brep(Ty.ce_push(b12, he2, False{}, tr_11_01()))
  +b14 = Ty.tres_brep(Ty.ed_push(b13, hv3, hv0,
    Ty.EK_curve{G.GV_ln{G.Ln{p010(), d_0n10()}}, dom_01()}))
  +he3 = Ty.mk_he(3n, 14u64)
  +b15 = Ty.tres_brep(Ty.ce_push(b14, he3, True{}, tr_01_00()))
  +b16 = Ty.tres_brep(Ty.ce_push(b15, he3, False{}, tr_01_00()))
  +hc0 = Ty.mk_hc(0n, 6u64)
  +hc2 = Ty.mk_hc(2n, 9u64)
  +hc4 = Ty.mk_hc(4n, 12u64)
  +hc6 = Ty.mk_hc(6n, 15u64)
  +hc1 = Ty.mk_hc(1n, 7u64)
  +hc3 = Ty.mk_hc(3n, 10u64)
  +hc5 = Ty.mk_hc(5n, 13u64)
  +hc7 = Ty.mk_hc(7n, 16u64)
  +b17 = Ty.tres_brep(Ty.lp_push(b16,
    hc0 <> hc2 <> hc4 <> hc6 <> Nil{}, Ty.LK_outer{}))
  +b18 = Ty.tres_brep(Ty.lp_push(b17,
    hc7 <> hc5 <> hc3 <> hc1 <> Nil{}, Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 17u64)
  +hlp1 = Ty.mk_hlp(1n, 18u64)
  +b19 = Ty.tres_brep(Ty.fa_push(b18, sf_pl(), hlp0 <> Nil{},
    False{}))
  +b20 = Ty.tres_brep(Ty.fa_push(b19, sf_pl(), hlp1 <> Nil{},
    False{}))
  +hfa0 = Ty.mk_hfa(0n, 19u64)
  +hfa1 = Ty.mk_hfa(1n, 20u64)
  +b21 = Ty.tres_brep(Ty.sh_push(b20, hfa0 <> hfa1 <> Nil{},
    Ty.SK_outer{}))
  +hshS = Ty.mk_hsh(0n, 21u64)
  +b22 = Ty.tres_brep(Ty.so_push(b21, hshS, hsh0()))
  +hsoS = Ty.mk_hso(0n, 22u64)
  Ty.brep_set_top(b22, Ty.Cp{hsoS <> Nil{}, hsh0()})

def b_oriprop() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.vx_push(b2, p110()))
  +b4 = Ty.tres_brep(Ty.vx_push(b3, p010()))
  +hv0 = Ty.mk_hv(0n, 1u64)
  +hv1 = Ty.mk_hv(1n, 2u64)
  +hv2 = Ty.mk_hv(2n, 3u64)
  +hv3 = Ty.mk_hv(3n, 4u64)
  +b5 = Ty.tres_brep(Ty.ed_push(b4, hv0, hv1,
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 5u64)
  +b6 = Ty.tres_brep(Ty.ce_push(b5, he0, True{}, tr_00_10()))
  +b7 = Ty.tres_brep(Ty.ce_push(b6, he0, False{}, tr_00_10()))
  +b8 = Ty.tres_brep(Ty.ed_push(b7, hv1, hv2,
    Ty.EK_curve{G.GV_ln{G.Ln{p100(), d010()}}, dom_01()}))
  +he1 = Ty.mk_he(1n, 8u64)
  +b9 = Ty.tres_brep(Ty.ce_push(b8, he1, True{}, tr_10_11()))
  +b10 = Ty.tres_brep(Ty.ce_push(b9, he1, False{}, tr_10_11()))
  +b11 = Ty.tres_brep(Ty.ed_push(b10, hv2, hv3,
    Ty.EK_curve{G.GV_ln{G.Ln{p110(), d_n100()}}, dom_01()}))
  +he2 = Ty.mk_he(2n, 11u64)
  +b12 = Ty.tres_brep(Ty.ce_push(b11, he2, True{}, tr_11_01()))
  +b13 = Ty.tres_brep(Ty.ce_push(b12, he2, False{}, tr_11_01()))
  +b14 = Ty.tres_brep(Ty.ed_push(b13, hv3, hv0,
    Ty.EK_curve{G.GV_ln{G.Ln{p010(), d_0n10()}}, dom_01()}))
  +he3 = Ty.mk_he(3n, 14u64)
  +b15 = Ty.tres_brep(Ty.ce_push(b14, he3, True{}, tr_01_00()))
  +b16 = Ty.tres_brep(Ty.ce_push(b15, he3, False{}, tr_01_00()))
  +hc0 = Ty.mk_hc(0n, 6u64)
  +hc2 = Ty.mk_hc(2n, 9u64)
  +hc4 = Ty.mk_hc(4n, 12u64)
  +hc6 = Ty.mk_hc(6n, 15u64)
  +hc1 = Ty.mk_hc(1n, 7u64)
  +hc3 = Ty.mk_hc(3n, 10u64)
  +hc5 = Ty.mk_hc(5n, 13u64)
  +hc7 = Ty.mk_hc(7n, 16u64)
  +b17 = Ty.tres_brep(Ty.lp_push(b16,
    hc0 <> hc2 <> hc4 <> hc6 <> Nil{}, Ty.LK_outer{}))
  +b18 = Ty.tres_brep(Ty.lp_push(b17,
    hc7 <> hc5 <> hc3 <> hc1 <> Nil{}, Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 17u64)
  +hlp1 = Ty.mk_hlp(1n, 18u64)
  +b19 = Ty.tres_brep(Ty.fa_push(b18, sf_pl(), hlp0 <> Nil{},
    True{}))
  +b20 = Ty.tres_brep(Ty.fa_push(b19, sf_pl(), hlp1 <> Nil{},
    False{}))
  +hfa0 = Ty.mk_hfa(0n, 19u64)
  +hfa1 = Ty.mk_hfa(1n, 20u64)
  +b21 = Ty.tres_brep(Ty.sh_push(b20, hfa0 <> hfa1 <> Nil{},
    Ty.SK_outer{}))
  +hshS = Ty.mk_hsh(0n, 21u64)
  +b22 = Ty.tres_brep(Ty.so_push(b21, hshS, hsh0()))
  +hsoS = Ty.mk_hso(0n, 22u64)
  Ty.brep_set_top(b22, Ty.Cp{hsoS <> Nil{}, hsh0()})

def b_hole() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p300()))
  +b3 = Ty.tres_brep(Ty.vx_push(b2, p330()))
  +b4 = Ty.tres_brep(Ty.vx_push(b3, p030()))
  +b5 = Ty.tres_brep(Ty.vx_push(b4, q00()))
  +b6 = Ty.tres_brep(Ty.vx_push(b5, q10()))
  +b7 = Ty.tres_brep(Ty.vx_push(b6, q11()))
  +b8 = Ty.tres_brep(Ty.vx_push(b7, q01()))
  +hv0 = Ty.mk_hv(0n, 1u64)
  +hv1 = Ty.mk_hv(1n, 2u64)
  +hv2 = Ty.mk_hv(2n, 3u64)
  +hv3 = Ty.mk_hv(3n, 4u64)
  +hv4 = Ty.mk_hv(4n, 5u64)
  +hv5 = Ty.mk_hv(5n, 6u64)
  +hv6 = Ty.mk_hv(6n, 7u64)
  +hv7 = Ty.mk_hv(7n, 8u64)
  +b9 = Ty.tres_brep(Ty.ed_push(b8, hv0, hv1,
    Ty.EK_curve{G.GV_ln{G.Ln{p000(), d300()}}, dom_01()}))
  +he0 = Ty.mk_he(0n, 9u64)
  +b10 = Ty.tres_brep(Ty.ce_push(b9, he0, True{},
    ts_00_30()))
  +b11 = Ty.tres_brep(Ty.ed_push(b10, hv1, hv2,
    Ty.EK_curve{G.GV_ln{G.Ln{p300(), d030()}}, dom_01()}))
  +he1 = Ty.mk_he(1n, 11u64)
  +b12 = Ty.tres_brep(Ty.ce_push(b11, he1, True{},
    ts_30_33()))
  +b13 = Ty.tres_brep(Ty.ed_push(b12, hv2, hv3,
    Ty.EK_curve{G.GV_ln{G.Ln{p330(), d_n300()}}, dom_01()}))
  +he2 = Ty.mk_he(2n, 13u64)
  +b14 = Ty.tres_brep(Ty.ce_push(b13, he2, True{},
    ts_33_03()))
  +b15 = Ty.tres_brep(Ty.ed_push(b14, hv3, hv0,
    Ty.EK_curve{G.GV_ln{G.Ln{p030(), d_0n30()}}, dom_01()}))
  +he3 = Ty.mk_he(3n, 15u64)
  +b16 = Ty.tres_brep(Ty.ce_push(b15, he3, True{},
    ts_03_00()))
  +b17 = Ty.tres_brep(Ty.ed_push(b16, hv4, hv5,
    Ty.EK_curve{G.GV_ln{G.Ln{q00(), d100()}}, dom_01()}))
  +he4 = Ty.mk_he(4n, 17u64)
  +b18 = Ty.tres_brep(Ty.ce_push(b17, he4, False{},
    tq_00_10()))
  +b19 = Ty.tres_brep(Ty.ed_push(b18, hv5, hv6,
    Ty.EK_curve{G.GV_ln{G.Ln{q10(), d010()}}, dom_01()}))
  +he5 = Ty.mk_he(5n, 19u64)
  +b20 = Ty.tres_brep(Ty.ce_push(b19, he5, False{},
    tq_10_11()))
  +b21 = Ty.tres_brep(Ty.ed_push(b20, hv6, hv7,
    Ty.EK_curve{G.GV_ln{G.Ln{q11(), d_n100()}}, dom_01()}))
  +he6 = Ty.mk_he(6n, 21u64)
  +b22 = Ty.tres_brep(Ty.ce_push(b21, he6, False{},
    tq_11_01()))
  +b23 = Ty.tres_brep(Ty.ed_push(b22, hv7, hv4,
    Ty.EK_curve{G.GV_ln{G.Ln{q01(), d_0n10()}}, dom_01()}))
  +he7 = Ty.mk_he(7n, 23u64)
  +b24 = Ty.tres_brep(Ty.ce_push(b23, he7, False{},
    tq_01_00()))
  +hc0 = Ty.mk_hc(0n, 10u64)
  +hc1 = Ty.mk_hc(1n, 12u64)
  +hc2 = Ty.mk_hc(2n, 14u64)
  +hc3 = Ty.mk_hc(3n, 16u64)
  +hc4 = Ty.mk_hc(4n, 18u64)
  +hc5 = Ty.mk_hc(5n, 20u64)
  +hc6 = Ty.mk_hc(6n, 22u64)
  +hc7 = Ty.mk_hc(7n, 24u64)
  +b25 = Ty.tres_brep(Ty.lp_push(b24,
    hc0 <> hc1 <> hc2 <> hc3 <> Nil{}, Ty.LK_outer{}))
  +b26 = Ty.tres_brep(Ty.lp_push(b25,
    hc7 <> hc6 <> hc5 <> hc4 <> Nil{}, Ty.LK_inner{}))
  +hlp0 = Ty.mk_hlp(0n, 25u64)
  +hlp1 = Ty.mk_hlp(1n, 26u64)
  +b27 = Ty.tres_brep(Ty.fa_push(b26, sf_pl(),
    hlp0 <> hlp1 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 27u64)
  +b28 = Ty.tres_brep(Ty.sh_push(b27, hfa0 <> Nil{},
    Ty.SK_open{}))
  +hshH = Ty.mk_hsh(0n, 28u64)
  Ty.brep_set_top(b28, Ty.Cp{hso0(), hshH <> Nil{}})

def b_hole_bad() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p300()))
  +b3 = Ty.tres_brep(Ty.vx_push(b2, p330()))
  +b4 = Ty.tres_brep(Ty.vx_push(b3, p030()))
  +b5 = Ty.tres_brep(Ty.vx_push(b4, q00()))
  +b6 = Ty.tres_brep(Ty.vx_push(b5, q10()))
  +b7 = Ty.tres_brep(Ty.vx_push(b6, q11()))
  +b8 = Ty.tres_brep(Ty.vx_push(b7, q01()))
  +hv0 = Ty.mk_hv(0n, 1u64)
  +hv1 = Ty.mk_hv(1n, 2u64)
  +hv2 = Ty.mk_hv(2n, 3u64)
  +hv3 = Ty.mk_hv(3n, 4u64)
  +hv4 = Ty.mk_hv(4n, 5u64)
  +hv5 = Ty.mk_hv(5n, 6u64)
  +hv6 = Ty.mk_hv(6n, 7u64)
  +hv7 = Ty.mk_hv(7n, 8u64)
  +b9 = Ty.tres_brep(Ty.ed_push(b8, hv0, hv1,
    Ty.EK_curve{G.GV_ln{G.Ln{p000(), d300()}}, dom_01()}))
  +he0 = Ty.mk_he(0n, 9u64)
  +b10 = Ty.tres_brep(Ty.ce_push(b9, he0, True{},
    ts_00_30()))
  +b11 = Ty.tres_brep(Ty.ed_push(b10, hv1, hv2,
    Ty.EK_curve{G.GV_ln{G.Ln{p300(), d030()}}, dom_01()}))
  +he1 = Ty.mk_he(1n, 11u64)
  +b12 = Ty.tres_brep(Ty.ce_push(b11, he1, True{},
    ts_30_33()))
  +b13 = Ty.tres_brep(Ty.ed_push(b12, hv2, hv3,
    Ty.EK_curve{G.GV_ln{G.Ln{p330(), d_n300()}}, dom_01()}))
  +he2 = Ty.mk_he(2n, 13u64)
  +b14 = Ty.tres_brep(Ty.ce_push(b13, he2, True{},
    ts_33_03()))
  +b15 = Ty.tres_brep(Ty.ed_push(b14, hv3, hv0,
    Ty.EK_curve{G.GV_ln{G.Ln{p030(), d_0n30()}}, dom_01()}))
  +he3 = Ty.mk_he(3n, 15u64)
  +b16 = Ty.tres_brep(Ty.ce_push(b15, he3, True{},
    ts_03_00()))
  +b17 = Ty.tres_brep(Ty.ed_push(b16, hv4, hv5,
    Ty.EK_curve{G.GV_ln{G.Ln{q00(), d100()}}, dom_01()}))
  +he4 = Ty.mk_he(4n, 17u64)
  +b18 = Ty.tres_brep(Ty.ce_push(b17, he4, True{},
    tq_00_10()))
  +b19 = Ty.tres_brep(Ty.ed_push(b18, hv5, hv6,
    Ty.EK_curve{G.GV_ln{G.Ln{q10(), d010()}}, dom_01()}))
  +he5 = Ty.mk_he(5n, 19u64)
  +b20 = Ty.tres_brep(Ty.ce_push(b19, he5, True{},
    tq_10_11()))
  +b21 = Ty.tres_brep(Ty.ed_push(b20, hv6, hv7,
    Ty.EK_curve{G.GV_ln{G.Ln{q11(), d_n100()}}, dom_01()}))
  +he6 = Ty.mk_he(6n, 21u64)
  +b22 = Ty.tres_brep(Ty.ce_push(b21, he6, True{},
    tq_11_01()))
  +b23 = Ty.tres_brep(Ty.ed_push(b22, hv7, hv4,
    Ty.EK_curve{G.GV_ln{G.Ln{q01(), d_0n10()}}, dom_01()}))
  +he7 = Ty.mk_he(7n, 23u64)
  +b24 = Ty.tres_brep(Ty.ce_push(b23, he7, True{},
    tq_01_00()))
  +hc0 = Ty.mk_hc(0n, 10u64)
  +hc1 = Ty.mk_hc(1n, 12u64)
  +hc2 = Ty.mk_hc(2n, 14u64)
  +hc3 = Ty.mk_hc(3n, 16u64)
  +hc4 = Ty.mk_hc(4n, 18u64)
  +hc5 = Ty.mk_hc(5n, 20u64)
  +hc6 = Ty.mk_hc(6n, 22u64)
  +hc7 = Ty.mk_hc(7n, 24u64)
  +b25 = Ty.tres_brep(Ty.lp_push(b24,
    hc0 <> hc1 <> hc2 <> hc3 <> Nil{}, Ty.LK_outer{}))
  +b26 = Ty.tres_brep(Ty.lp_push(b25,
    hc4 <> hc5 <> hc6 <> hc7 <> Nil{}, Ty.LK_inner{}))
  +hlp0 = Ty.mk_hlp(0n, 25u64)
  +hlp1 = Ty.mk_hlp(1n, 26u64)
  +b27 = Ty.tres_brep(Ty.fa_push(b26, sf_pl(),
    hlp0 <> hlp1 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 27u64)
  +b28 = Ty.tres_brep(Ty.sh_push(b27, hfa0 <> Nil{},
    Ty.SK_open{}))
  +hshH = Ty.mk_hsh(0n, 28u64)
  Ty.brep_set_top(b28, Ty.Cp{hso0(), hshH <> Nil{}})

def b_hole_bad2() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p300()))
  +b3 = Ty.tres_brep(Ty.vx_push(b2, p330()))
  +b4 = Ty.tres_brep(Ty.vx_push(b3, p030()))
  +b5 = Ty.tres_brep(Ty.vx_push(b4, q00()))
  +b6 = Ty.tres_brep(Ty.vx_push(b5, q10()))
  +b7 = Ty.tres_brep(Ty.vx_push(b6, q11()))
  +b8 = Ty.tres_brep(Ty.vx_push(b7, q01()))
  +hv0 = Ty.mk_hv(0n, 1u64)
  +hv1 = Ty.mk_hv(1n, 2u64)
  +hv2 = Ty.mk_hv(2n, 3u64)
  +hv3 = Ty.mk_hv(3n, 4u64)
  +hv4 = Ty.mk_hv(4n, 5u64)
  +hv5 = Ty.mk_hv(5n, 6u64)
  +hv6 = Ty.mk_hv(6n, 7u64)
  +hv7 = Ty.mk_hv(7n, 8u64)
  +b9 = Ty.tres_brep(Ty.ed_push(b8, hv0, hv1,
    Ty.EK_curve{G.GV_ln{G.Ln{p000(), d300()}}, dom_01()}))
  +he0 = Ty.mk_he(0n, 9u64)
  +b10 = Ty.tres_brep(Ty.ce_push(b9, he0, False{},
    ts_00_30()))
  +b11 = Ty.tres_brep(Ty.ed_push(b10, hv1, hv2,
    Ty.EK_curve{G.GV_ln{G.Ln{p300(), d030()}}, dom_01()}))
  +he1 = Ty.mk_he(1n, 11u64)
  +b12 = Ty.tres_brep(Ty.ce_push(b11, he1, False{},
    ts_30_33()))
  +b13 = Ty.tres_brep(Ty.ed_push(b12, hv2, hv3,
    Ty.EK_curve{G.GV_ln{G.Ln{p330(), d_n300()}}, dom_01()}))
  +he2 = Ty.mk_he(2n, 13u64)
  +b14 = Ty.tres_brep(Ty.ce_push(b13, he2, False{},
    ts_33_03()))
  +b15 = Ty.tres_brep(Ty.ed_push(b14, hv3, hv0,
    Ty.EK_curve{G.GV_ln{G.Ln{p030(), d_0n30()}}, dom_01()}))
  +he3 = Ty.mk_he(3n, 15u64)
  +b16 = Ty.tres_brep(Ty.ce_push(b15, he3, False{},
    ts_03_00()))
  +b17 = Ty.tres_brep(Ty.ed_push(b16, hv4, hv5,
    Ty.EK_curve{G.GV_ln{G.Ln{q00(), d100()}}, dom_01()}))
  +he4 = Ty.mk_he(4n, 17u64)
  +b18 = Ty.tres_brep(Ty.ce_push(b17, he4, False{},
    tq_00_10()))
  +b19 = Ty.tres_brep(Ty.ed_push(b18, hv5, hv6,
    Ty.EK_curve{G.GV_ln{G.Ln{q10(), d010()}}, dom_01()}))
  +he5 = Ty.mk_he(5n, 19u64)
  +b20 = Ty.tres_brep(Ty.ce_push(b19, he5, False{},
    tq_10_11()))
  +b21 = Ty.tres_brep(Ty.ed_push(b20, hv6, hv7,
    Ty.EK_curve{G.GV_ln{G.Ln{q11(), d_n100()}}, dom_01()}))
  +he6 = Ty.mk_he(6n, 21u64)
  +b22 = Ty.tres_brep(Ty.ce_push(b21, he6, False{},
    tq_11_01()))
  +b23 = Ty.tres_brep(Ty.ed_push(b22, hv7, hv4,
    Ty.EK_curve{G.GV_ln{G.Ln{q01(), d_0n10()}}, dom_01()}))
  +he7 = Ty.mk_he(7n, 23u64)
  +b24 = Ty.tres_brep(Ty.ce_push(b23, he7, False{},
    tq_01_00()))
  +hc0 = Ty.mk_hc(0n, 10u64)
  +hc1 = Ty.mk_hc(1n, 12u64)
  +hc2 = Ty.mk_hc(2n, 14u64)
  +hc3 = Ty.mk_hc(3n, 16u64)
  +hc4 = Ty.mk_hc(4n, 18u64)
  +hc5 = Ty.mk_hc(5n, 20u64)
  +hc6 = Ty.mk_hc(6n, 22u64)
  +hc7 = Ty.mk_hc(7n, 24u64)
  +b25 = Ty.tres_brep(Ty.lp_push(b24,
    hc3 <> hc2 <> hc1 <> hc0 <> Nil{}, Ty.LK_outer{}))
  +b26 = Ty.tres_brep(Ty.lp_push(b25,
    hc7 <> hc6 <> hc5 <> hc4 <> Nil{}, Ty.LK_inner{}))
  +hlp0 = Ty.mk_hlp(0n, 25u64)
  +hlp1 = Ty.mk_hlp(1n, 26u64)
  +b27 = Ty.tres_brep(Ty.fa_push(b26, sf_pl(),
    hlp0 <> hlp1 <> Nil{}, False{}))
  +hfa0 = Ty.mk_hfa(0n, 27u64)
  +b28 = Ty.tres_brep(Ty.sh_push(b27, hfa0 <> Nil{},
    Ty.SK_open{}))
  +hshH = Ty.mk_hsh(0n, 28u64)
  Ty.brep_set_top(b28, Ty.Cp{hso0(), hshH <> Nil{}})

def b_diffparam() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p100()))
  +b3 = Ty.tres_brep(Ty.vx_push(b2, p110()))
  +b4 = Ty.tres_brep(Ty.vx_push(b3, p010()))
  +hv0 = Ty.mk_hv(0n, 1u64)
  +hv1 = Ty.mk_hv(1n, 2u64)
  +hv2 = Ty.mk_hv(2n, 3u64)
  +hv3 = Ty.mk_hv(3n, 4u64)
  +b5 = Ty.tres_brep(Ty.ed_push(b4, hv0, hv1,
    Ty.EK_curve{cv_ln(), dom_01()}))
  +he0 = Ty.mk_he(0n, 5u64)
  +b6 = Ty.tres_brep(Ty.ce_push(b5, he0, True{}, tr_00_10()))
  +b7 = Ty.tres_brep(Ty.ce_push(b6, he0, False{}, tr_00_01()))
  +b8 = Ty.tres_brep(Ty.ed_push(b7, hv1, hv2,
    Ty.EK_curve{G.GV_ln{G.Ln{p100(), d010()}}, dom_01()}))
  +he1 = Ty.mk_he(1n, 8u64)
  +b9 = Ty.tres_brep(Ty.ce_push(b8, he1, True{}, tr_10_11()))
  +b10 = Ty.tres_brep(Ty.ce_push(b9, he1, False{},
    tr_01_11()))
  +b11 = Ty.tres_brep(Ty.ed_push(b10, hv2, hv3,
    Ty.EK_curve{G.GV_ln{G.Ln{p110(), d_n100()}}, dom_01()}))
  +he2 = Ty.mk_he(2n, 11u64)
  +b12 = Ty.tres_brep(Ty.ce_push(b11, he2, True{},
    tr_11_01()))
  +b13 = Ty.tres_brep(Ty.ce_push(b12, he2, False{},
    tr_11_10()))
  +b14 = Ty.tres_brep(Ty.ed_push(b13, hv3, hv0,
    Ty.EK_curve{G.GV_ln{G.Ln{p010(), d_0n10()}}, dom_01()}))
  +he3 = Ty.mk_he(3n, 14u64)
  +b15 = Ty.tres_brep(Ty.ce_push(b14, he3, True{},
    tr_01_00()))
  +b16 = Ty.tres_brep(Ty.ce_push(b15, he3, False{},
    tr_10_00()))
  +hc0 = Ty.mk_hc(0n, 6u64)
  +hc2 = Ty.mk_hc(2n, 9u64)
  +hc4 = Ty.mk_hc(4n, 12u64)
  +hc6 = Ty.mk_hc(6n, 15u64)
  +hc1 = Ty.mk_hc(1n, 7u64)
  +hc3 = Ty.mk_hc(3n, 10u64)
  +hc5 = Ty.mk_hc(5n, 13u64)
  +hc7 = Ty.mk_hc(7n, 16u64)
  +b17 = Ty.tres_brep(Ty.lp_push(b16,
    hc0 <> hc2 <> hc4 <> hc6 <> Nil{}, Ty.LK_outer{}))
  +b18 = Ty.tres_brep(Ty.lp_push(b17,
    hc7 <> hc5 <> hc3 <> hc1 <> Nil{}, Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 17u64)
  +hlp1 = Ty.mk_hlp(1n, 18u64)
  +b19 = Ty.tres_brep(Ty.fa_push(b18, sf_pl(), hlp0 <> Nil{},
    True{}))
  +b20 = Ty.tres_brep(Ty.fa_push(b19, sf_pl_flip(),
    hlp1 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 19u64)
  +hfa1 = Ty.mk_hfa(1n, 20u64)
  +b21 = Ty.tres_brep(Ty.sh_push(b20, hfa0 <> hfa1 <> Nil{},
    Ty.SK_outer{}))
  +hshS = Ty.mk_hsh(0n, 21u64)
  +b22 = Ty.tres_brep(Ty.so_push(b21, hshS, hsh0()))
  +hsoS = Ty.mk_hso(0n, 22u64)
  Ty.brep_set_top(b22, Ty.Cp{hsoS <> Nil{}, hsh0()})

def l1_v0() -> Ty.HVertex:
  Ty.mk_hv(0n, 1u64)

def l1_v1() -> Ty.HVertex:
  Ty.mk_hv(1n, 2u64)

def l1_v2() -> Ty.HVertex:
  Ty.mk_hv(2n, 3u64)

def l1_he0() -> Ty.HEdge:
  Ty.mk_he(0n, 4u64)

def l1_he1() -> Ty.HEdge:
  Ty.mk_he(1n, 5u64)

def l1_hc0() -> Ty.HCoedge:
  Ty.mk_hc(0n, 6u64)

def l1_hc1() -> Ty.HCoedge:
  Ty.mk_hc(1n, 7u64)

def l1_hl0() -> Ty.HLoop:
  Ty.mk_hlp(0n, 8u64)

def l1_hl1() -> Ty.HLoop:
  Ty.mk_hlp(1n, 9u64)

def l1_hf0() -> Ty.HFace:
  Ty.mk_hfa(0n, 10u64)

def l1_hf1() -> Ty.HFace:
  Ty.mk_hfa(1n, 11u64)

def l1_p0() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def l1_p1() -> V.Point:
  V.Pt{1.0f64, 0.0f64, 0.0f64}

def l1_d0() -> V.Dir:
  V.Dr{1.0f64, 0.0f64, 0.0f64}

def l1_d1() -> V.Dir:
  V.Dr{0.0f64, 1.0f64, 0.0f64}

def l1_ln() -> G.GVal:
  G.GV_ln{G.Ln{l1_p0(), l1_d0()}}

def l1_dom() -> G.Dom:
  G.Dom{0.0f64, 1.0f64}

def l1_pl() -> G.GVal:
  G.GV_pl{G.Pl{l1_p0(), l1_d0(), l1_d1()}}

def l1_cc() -> G.GVal:
  G.GV_cc{G.Cc{l1_p0(), l1_d0(), l1_d1(), 1.0f64}}

def l1_uva() -> V.Vec2:
  V.V2{0.0f64, 0.0f64}

def l1_uvb() -> V.Vec2:
  V.V2{1.0f64, 0.0f64}

def l1_uvx() -> V.Vec2:
  V.V2{2.0f64, 0.0f64}

def l1_es_line() -> List<&2, Ty.Edge>:
  Ty.Ed{4u64, l1_v0(), l1_v1(),
    Ty.EK_curve{l1_ln(), l1_dom()}} <> Nil{}

def l1_es_pair() -> List<&2, Ty.Edge>:
  Ty.Ed{4u64, l1_v0(), l1_v1(),
    Ty.EK_curve{l1_ln(), l1_dom()}} <>
    Ty.Ed{5u64, l1_v0(), l1_v2(),
      Ty.EK_curve{l1_ln(), l1_dom()}} <> Nil{}

def l1_es_degen() -> List<&2, Ty.Edge>:
  Ty.Ed{4u64, l1_v0(), l1_v0(), Ty.EK_degenerate{}} <> Nil{}

def l1_es_cc() -> List<&2, Ty.Edge>:
  Ty.Ed{4u64, l1_v0(), l1_v1(),
    Ty.EK_curve{l1_cc(), l1_dom()}} <> Nil{}

def l1_es_chain() -> List<&2, Ty.Edge>:
  Ty.Ed{4u64, l1_v0(), l1_v1(),
    Ty.EK_curve{l1_ln(), l1_dom()}} <>
    Ty.Ed{5u64, l1_v1(), l1_v0(),
      Ty.EK_curve{l1_ln(), l1_dom()}} <> Nil{}

def l1_ces_seam(+f: Bool) -> List<&2, Ty.Coedge>:
  Ty.Ce{6u64, l1_he0(), f, Ty.trim_zero()} <>
    Ty.Ce{7u64, l1_he0(), Bool.not(f), Ty.trim_zero()} <>
    Nil{}

def l1_ces_same() -> List<&2, Ty.Coedge>:
  Ty.Ce{6u64, l1_he0(), True{}, Ty.trim_zero()} <>
    Ty.Ce{7u64, l1_he0(), True{}, Ty.trim_zero()} <> Nil{}

def l1_ces_distinct() -> List<&2, Ty.Coedge>:
  Ty.Ce{6u64, l1_he0(), True{}, Ty.trim_zero()} <>
    Ty.Ce{7u64, l1_he1(), True{}, Ty.trim_zero()} <> Nil{}

def l1_ces_one() -> List<&2, Ty.Coedge>:
  Ty.Ce{6u64, l1_he0(), True{}, Ty.trim_zero()} <> Nil{}

def l1_ces_chain(+gap: Bool) -> List<&2, Ty.Coedge>:
  Ty.Ce{6u64, l1_he0(), True{},
    G.GV_ts{G.Ts{l1_uva(), l1_uvb()}}} <>
    Ty.Ce{7u64, l1_he1(), True{},
      Bool.pick(G.GVal, gap,
        G.GV_ts{G.Ts{l1_uvx(), l1_uva()}},
        G.GV_ts{G.Ts{l1_uvb(), l1_uva()}})} <> Nil{}

def l1_vs2() -> List<&2, Ty.Vertex>:
  Ty.Vx{1u64, l1_p0()} <> Ty.Vx{2u64, l1_p1()} <> Nil{}

def l1_lps_pair() -> List<&2, Ty.Loop>:
  Ty.Lp{8u64, l1_hc0() <> Nil{}, Ty.LK_outer{}} <>
    Ty.Lp{9u64, l1_hc1() <> Nil{}, Ty.LK_outer{}} <> Nil{}

def l1_fas_pair() -> List<&2, Ty.Face>:
  Ty.Fa{10u64, l1_pl(), l1_hl0() <> Nil{}, True{}, 0.0f64, 0.0f64} <>
    Ty.Fa{11u64, l1_pl(), l1_hl1() <> Nil{}, True{}, 0.0f64, 0.0f64} <> Nil{}

def l1_b_share() -> Ty.Brep:
  Ty.Br{Nil{}, l1_es_line(), l1_ces_seam(True{}),
    l1_lps_pair(), l1_fas_pair(), Nil{}, Nil{},
    Ty.Cp{Nil{}, Nil{}}, 12u64}

def l1_b_split() -> Ty.Brep:
  Ty.Br{Nil{}, l1_es_pair(), l1_ces_distinct(),
    l1_lps_pair(), l1_fas_pair(), Nil{}, Nil{},
    Ty.Cp{Nil{}, Nil{}}, 12u64}

def l1_b_step() -> Ty.Brep:
  Ty.Br{Nil{}, l1_es_line(), l1_ces_seam(True{}),
    Ty.Lp{8u64, l1_hc0() <> l1_hc1() <> Nil{},
      Ty.LK_outer{}} <> Nil{}, Nil{}, Nil{}, Nil{},
    Ty.Cp{Nil{}, Nil{}}, 12u64}

def l1_lps_outer() -> List<&2, Ty.Loop>:
  Ty.Lp{8u64, l1_hc0() <> Nil{}, Ty.LK_outer{}} <> Nil{}

def l1_lps_twoouter() -> List<&2, Ty.Loop>:
  Ty.Lp{8u64, l1_hc0() <> Nil{}, Ty.LK_outer{}} <>
    Ty.Lp{9u64, l1_hc1() <> Nil{}, Ty.LK_outer{}} <> Nil{}

def l1_lps_inner() -> List<&2, Ty.Loop>:
  Ty.Lp{8u64, l1_hc0() <> Nil{}, Ty.LK_inner{}} <> Nil{}

def l1_ixv(+vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>,
    +ces: List<&2, Ty.Coedge>) -> Ty.Ix:
  Ty.ix_mk(vs, es, ces, Nil{}, Nil{}, Nil{}, Nil{})

def l1_ix(+es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>) -> Ty.Ix:
  Ty.ix_mk(Nil{}, es, ces, Nil{}, Nil{}, Nil{}, Nil{})

def l1_ixl(+lps: List<&2, Ty.Loop>) -> Ty.Ix:
  Ty.ix_mk(Nil{}, Nil{}, Nil{}, lps, Nil{}, Nil{}, Nil{})

def l1_b_ec(+es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>) -> Ty.Brep:
  Ty.Br{Nil{}, es, ces, Nil{}, Nil{}, Nil{}, Nil{},
    Ty.Cp{Nil{}, Nil{}}, 12u64}

def l1_b_single() -> Ty.Brep:
  Ty.Br{Nil{}, l1_es_line(), l1_ces_one(),
    Ty.Lp{8u64, l1_hc0() <> Nil{}, Ty.LK_outer{}} <> Nil{}, Nil{},
    Nil{}, Nil{}, Ty.Cp{Nil{}, Nil{}}, 12u64}

def l1_shs_pair() -> List<&2, Ty.Shell>:
  Ty.Sh{13u64, l1_hf0() <> l1_hf1() <> Nil{}, Ty.SK_outer{}} <> Nil{}

def l1_rho_x() -> Ty.HCoedge:
  Ty.mk_hc(4n, 23u64)

def l1_b_rho() -> Ty.Brep:
  Ty.Br{Ty.Vx{1u64, l1_p0()} <> Ty.Vx{2u64, l1_p1()} <>
      Ty.Vx{3u64, V.Pt{0.0f64, 1.0f64, 0.0f64}} <> Nil{},
    Ty.Ed{4u64, l1_v0(), l1_v1(), Ty.EK_curve{l1_ln(), l1_dom()}} <>
      Ty.Ed{5u64, l1_v1(), l1_v0(), Ty.EK_curve{l1_ln(), l1_dom()}} <>
      Ty.Ed{22u64, l1_v2(), l1_v0(), Ty.EK_curve{l1_ln(), l1_dom()}} <>
      Nil{},
    Ty.Ce{6u64, l1_he0(), True{}, Ty.trim_zero()} <>
      Ty.Ce{7u64, l1_he1(), True{}, Ty.trim_zero()} <>
      Ty.Ce{20u64, l1_he0(), False{}, Ty.trim_zero()} <>
      Ty.Ce{21u64, l1_he0(), True{}, Ty.trim_zero()} <>
      Ty.Ce{23u64, Ty.mk_he(2n, 22u64), True{}, Ty.trim_zero()} <> Nil{},
    Ty.Lp{8u64, l1_hc0() <> l1_hc1() <> Nil{}, Ty.LK_outer{}} <>
      Ty.Lp{9u64, Ty.mk_hc(2n, 20u64) <> Nil{}, Ty.LK_outer{}} <>
      Ty.Lp{30u64, l1_rho_x() <> Ty.mk_hc(3n, 21u64) <> Nil{},
        Ty.LK_outer{}} <> Nil{},
    Nil{}, Nil{}, Nil{}, Ty.Cp{Nil{}, Nil{}}, 12u64}

def l1_orb_rho() -> Op.Orb:
  Op.orb_of(l1_b_rho(), Ty.ix_of(l1_b_rho()), Op.hmap_of(l1_b_rho()))

def l1_rho_id(+h: Ty.HCoedge) -> U32:
  Op.oc_id(Op.OC{l1_orb_rho(), Ty.ix_of(l1_b_rho())}, h)

def nb_p0() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def nb_p3() -> V.Point:
  V.Pt{3.0f64, 0.0f64, 0.0f64}

def nb_curve() -> G.GVal:
  G.GV_nb{G.Nb{[0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 1.0f64, 1.0f64, 1.0f64],
    [nb_p0(), V.Pt{1.0f64, 1.0f64, 0.0f64}, V.Pt{2.0f64, 1.0f64, 0.0f64}, nb_p3()],
    [1.0f64, 1.0f64, 1.0f64, 1.0f64]}}

def b_nb_edge() -> Ty.Brep:
  Ty.Br{[Ty.Vx{1u64, nb_p0()}, Ty.Vx{2u64, nb_p3()}],
    [Ty.Ed{3u64, Ty.HV{0n, 1u64}, Ty.HV{1n, 2u64},
      Ty.EK_curve{nb_curve(), G.Dom{0.0f64, 1.0f64}}}],
    [], [], [], [], [], Ty.Cp{[], []}, 3u64}

def cc_rbv() -> G.Circle3:
  G.Cc{V.Pt{0.0f64, 10.0f64, 0.0f64}, d_0n10(), d001(), 3.2f64}

def cc_rtv() -> G.Circle3:
  G.Cc{V.Pt{5.0f64, 10.0f64, 0.0f64}, d_0n10(), d001(), 3.2f64}

def cc_rb() -> G.GVal:
  G.GV_cc{cc_rbv()}

def cc_rt() -> G.GVal:
  G.GV_cc{cc_rtv()}

def p_cr0() -> V.Point:
  G.gres_p(GO.circ_eval(cc_rbv(), 1.0f64))

def p_cr1() -> V.Point:
  G.gres_p(GO.circ_eval(cc_rtv(), 1.0f64))

def d_cr() -> V.Dir:
  V.Dr{5.0f64, 0.0f64, 0.0f64}

def sf_cr() -> G.GVal:
  G.GV_cy{G.Cy{V.Pt{0.0f64, 10.0f64, 0.0f64}, d100(), 3.2f64}}

def sf_crb() -> G.GVal:
  G.GV_pl{G.Pl{p_cr0(), d010(), d001()}}

def sf_crt() -> G.GVal:
  G.GV_pl{G.Pl{p_cr1(), d010(), d001()}}

def b_cyl_round() -> Ty.Brep:
  +b0 = Ty.brep_empty()
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p_cr0()))
  +b2 = Ty.tres_brep(Ty.vx_push(b1, p_cr1()))
  +hvB = Ty.mk_hv(0n, 1u64)
  +hvT = Ty.mk_hv(1n, 2u64)
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hvB, hvB,
    Ty.EK_curve{cc_rb(), dom_n11()}))
  +heB = Ty.mk_he(0n, 3u64)
  +b4 = Ty.tres_brep(Ty.ed_push(b3, hvB, hvT,
    Ty.EK_curve{G.GV_ln{G.Ln{p_cr0(), d_cr()}}, dom_01()}))
  +heS = Ty.mk_he(1n, 4u64)
  +b5 = Ty.tres_brep(Ty.ed_push(b4, hvT, hvT,
    Ty.EK_curve{cc_rt(), dom_n11()}))
  +heT = Ty.mk_he(2n, 5u64)
  +b6 = Ty.tres_brep(Ty.ce_push(b5, heB, True{}, tr_00_10()))
  +b7 = Ty.tres_brep(Ty.ce_push(b6, heB, False{}, tr_closed()))
  +b8 = Ty.tres_brep(Ty.ce_push(b7, heS, True{}, tr_10_11()))
  +b9 = Ty.tres_brep(Ty.ce_push(b8, heS, False{}, tr_00_01()))
  +b10 = Ty.tres_brep(Ty.ce_push(b9, heT, True{}, tr_11_01()))
  +b11 = Ty.tres_brep(Ty.ce_push(b10, heT, False{}, tr_closed()))
  +hcBT = Ty.mk_hc(0n, 6u64)
  +hcBF = Ty.mk_hc(1n, 7u64)
  +hcST = Ty.mk_hc(2n, 8u64)
  +hcSF = Ty.mk_hc(3n, 9u64)
  +hcTT = Ty.mk_hc(4n, 10u64)
  +hcTF = Ty.mk_hc(5n, 11u64)
  +b12 = Ty.tres_brep(Ty.lp_push(b11,
    hcBT <> hcST <> hcTT <> hcSF <> Nil{}, Ty.LK_outer{}))
  +b13 = Ty.tres_brep(Ty.lp_push(b12, hcBF <> Nil{},
    Ty.LK_outer{}))
  +b14 = Ty.tres_brep(Ty.lp_push(b13, hcTF <> Nil{},
    Ty.LK_outer{}))
  +hlpS = Ty.mk_hlp(0n, 12u64)
  +hlpB = Ty.mk_hlp(1n, 13u64)
  +hlpT = Ty.mk_hlp(2n, 14u64)
  +b15 = Ty.tres_brep(Ty.fa_push(b14, sf_cr(), hlpS <> Nil{},
    True{}))
  +b16 = Ty.tres_brep(Ty.fa_push(b15, sf_crb(), hlpB <> Nil{},
    True{}))
  +b17 = Ty.tres_brep(Ty.fa_push(b16, sf_crt(), hlpT <> Nil{},
    True{}))
  +hfaS = Ty.mk_hfa(0n, 15u64)
  +hfaB = Ty.mk_hfa(1n, 16u64)
  +hfaT = Ty.mk_hfa(2n, 17u64)
  +b18 = Ty.tres_brep(Ty.sh_push(b17,
    hfaS <> hfaB <> hfaT <> Nil{}, Ty.SK_outer{}))
  +hshS = Ty.mk_hsh(0n, 18u64)
  +b19 = Ty.tres_brep(Ty.so_push(b18, hshS, hsh0()))
  +hsoS = Ty.mk_hso(0n, 19u64)
  Ty.brep_set_top(b19, Ty.Cp{hsoS <> Nil{}, hsh0()})

def tok_f_round__got() -> Bool:
  U64.is_eq(F64.bits(Ty.tres_f(Ty.tok_f(1.5f64))), 4609434218613702656u64)

def tok_f_round__want() -> Bool:
  True{}

def tok_n_round__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.tok_n(7n)), 7n)

def tok_n_round__want() -> Bool:
  True{}

def tok_b_round__got() -> Bool:
  Ty.tres_b(Ty.tok_b(True{}))

def tok_b_round__want() -> Bool:
  True{}

def tok_vx_round__got() -> Bool:
  Bool.and(U64.is_eq(Ty.vx_gen(Ty.tres_vx(Ty.tok_vx(vx_r()))), 9u64), pt_bits_eq(Ty.vx_p(Ty.tres_vx(Ty.tok_vx(vx_r()))), 4607182418800017408u64, 4611686018427387904u64, 4613937818241073152u64))

def tok_vx_round__want() -> Bool:
  True{}

def tok_ed_round__got() -> Bool:
  Bool.and(U64.is_eq(Ty.ed_gen(Ty.tres_ed(Ty.tok_ed(ed_r()))), 19u64), Bool.and(Nat.is_eq(Ty.hv_idx(Ty.ed_v0(Ty.tres_ed( Ty.tok_ed(ed_r())))), 0n), Bool.and(U64.is_eq(Ty.hv_gen(Ty.ed_v1(Ty.tres_ed( Ty.tok_ed(ed_r())))), 2u64), Bool.and(U64.is_eq(Ty.ekind_tag(Ty.ed_kind( Ty.tres_ed(Ty.tok_ed(ed_r())))), 0u64), Ty.gval_is_curve(Ty.ekind_curve(Ty.ed_kind( Ty.tres_ed(Ty.tok_ed(ed_r())))))))))

def tok_ed_round__want() -> Bool:
  True{}

def tok_ce_round__got() -> Bool:
  Bool.and(U64.is_eq(Ty.ce_gen(Ty.tres_ce(Ty.tok_ce(ce_r()))), 29u64), Bool.and(Nat.is_eq(Ty.he_idx(Ty.ce_edge(Ty.tres_ce( Ty.tok_ce(ce_r())))), 0n), Bool.and(Bool.not(Ty.ce_fwd(Ty.tres_ce(Ty.tok_ce( ce_r())))), Ty.gval_is_trim(Ty.ce_trim(Ty.tres_ce(Ty.tok_ce( ce_r())))))))

def tok_ce_round__want() -> Bool:
  True{}

def tok_lp_round__got() -> Bool:
  Bool.and(U64.is_eq(Ty.lp_gen(Ty.tres_lp(Ty.tok_lp(lp_r()))), 39u64), Bool.and(Ty.hce_nonempty(Ty.lp_ces(Ty.tres_lp(Ty.tok_lp( lp_r())))), U64.is_eq(Ty.lkind_tag(Ty.lp_kind(Ty.tres_lp( Ty.tok_lp(lp_r())))), 1u64)))

def tok_lp_round__want() -> Bool:
  True{}

def tok_fa_round__got() -> Bool:
  Bool.and(U64.is_eq(Ty.fa_gen(Ty.tres_fa(Ty.tok_fa(fa_r()))), 49u64), Bool.and(Ty.gval_is_surf(Ty.fa_surf(Ty.tres_fa( Ty.tok_fa(fa_r())))), Bool.and(Ty.hlp_nonempty(Ty.fa_loops(Ty.tres_fa( Ty.tok_fa(fa_r())))), Bool.not(Ty.fa_same(Ty.tres_fa(Ty.tok_fa( fa_r())))))))

def tok_fa_round__want() -> Bool:
  True{}

def tok_sh_round__got() -> Bool:
  Bool.and(U64.is_eq(Ty.sh_gen(Ty.tres_sh(Ty.tok_sh(sh_r()))), 59u64), Bool.and(Ty.hfa_nonempty(Ty.sh_faces(Ty.tres_sh( Ty.tok_sh(sh_r())))), U64.is_eq(Ty.skind_tag(Ty.sh_kind(Ty.tres_sh( Ty.tok_sh(sh_r())))), 1u64)))

def tok_sh_round__want() -> Bool:
  True{}

def tok_so_round__got() -> Bool:
  Bool.and(U64.is_eq(Ty.so_gen(Ty.tres_so(Ty.tok_so(so_r()))), 69u64), Bool.and(Nat.is_eq(Ty.hsh_idx(Ty.so_outer(Ty.tres_so( Ty.tok_so(so_r())))), 0n), Ty.so_has_cav(Ty.tres_so(Ty.tok_so(so_r())))))

def tok_so_round__want() -> Bool:
  True{}

def tok_cp_round__got() -> Bool:
  Bool.and(Ty.cp_has_solids(Ty.tres_cp(Ty.tok_cp(cp_r()))), Ty.cp_has_shells(Ty.tres_cp(Ty.tok_cp(cp_r()))))

def tok_cp_round__want() -> Bool:
  True{}

def tok_brep_round__got() -> Bool:
  U64.is_eq(Ty.brep_stamp(Ty.tres_brep(Ty.tok_brep( b_sos1()))), 61u64)

def tok_brep_round__want() -> Bool:
  True{}

def tok_hv_round__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hv_idx(Ty.tres_hv(Ty.tok_hv( Ty.mk_hv(3n, 4u64)))), 3n), U64.is_eq(Ty.hv_gen(Ty.tres_hv(Ty.tok_hv( Ty.mk_hv(3n, 4u64)))), 4u64))

def tok_hv_round__want() -> Bool:
  True{}

def tok_he_round__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.he_idx(Ty.tres_he(Ty.tok_he( Ty.mk_he(5n, 6u64)))), 5n), U64.is_eq(Ty.he_gen(Ty.tres_he(Ty.tok_he( Ty.mk_he(5n, 6u64)))), 6u64))

def tok_he_round__want() -> Bool:
  True{}

def tok_hc_round__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hc_idx(Ty.tres_hc(Ty.tok_hc( Ty.mk_hc(7n, 8u64)))), 7n), U64.is_eq(Ty.hc_gen(Ty.tres_hc(Ty.tok_hc( Ty.mk_hc(7n, 8u64)))), 8u64))

def tok_hc_round__want() -> Bool:
  True{}

def tok_hlp_round__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hlp_idx(Ty.tres_hlp(Ty.tok_hlp( Ty.mk_hlp(9n, 10u64)))), 9n), U64.is_eq(Ty.hlp_gen(Ty.tres_hlp(Ty.tok_hlp( Ty.mk_hlp(9n, 10u64)))), 10u64))

def tok_hlp_round__want() -> Bool:
  True{}

def tok_hfa_round__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hfa_idx(Ty.tres_hfa(Ty.tok_hfa( Ty.mk_hfa(11n, 12u64)))), 11n), U64.is_eq(Ty.hfa_gen(Ty.tres_hfa(Ty.tok_hfa( Ty.mk_hfa(11n, 12u64)))), 12u64))

def tok_hfa_round__want() -> Bool:
  True{}

def tok_hsh_round__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hsh_idx(Ty.tres_hsh(Ty.tok_hsh( Ty.mk_hsh(13n, 14u64)))), 13n), U64.is_eq(Ty.hsh_gen(Ty.tres_hsh(Ty.tok_hsh( Ty.mk_hsh(13n, 14u64)))), 14u64))

def tok_hsh_round__want() -> Bool:
  True{}

def tok_hso_round__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hso_idx(Ty.tres_hso(Ty.tok_hso( Ty.mk_hso(15n, 16u64)))), 15n), U64.is_eq(Ty.hso_gen(Ty.tres_hso(Ty.tok_hso( Ty.mk_hso(15n, 16u64)))), 16u64))

def tok_hso_round__want() -> Bool:
  True{}

def mis_f_zero__got() -> Bool:
  U64.is_eq(F64.bits(Ty.tres_f(Ty.tok_n(5n))), 0u64)

def mis_f_zero__want() -> Bool:
  True{}

def mis_n_zero__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.tok_f(1.0f64)), 0n)

def mis_n_zero__want() -> Bool:
  True{}

def mis_b_false__got() -> Bool:
  Ty.tres_b(Ty.tok_n(9n))

def mis_b_false__want() -> Bool:
  False{}

def mis_vx_zero__got() -> Bool:
  r_vx_zero(Ty.tok_f(0.0f64))

def mis_vx_zero__want() -> Bool:
  True{}

def mis_ed_dflt__got() -> Bool:
  r_ed_dflt(Ty.tok_n(0n))

def mis_ed_dflt__want() -> Bool:
  True{}

def mis_ce_dflt__got() -> Bool:
  r_ce_dflt(Ty.tok_b(True{}))

def mis_ce_dflt__want() -> Bool:
  True{}

def mis_lp_dflt__got() -> Bool:
  r_lp_dflt(Ty.tok_f(3.0f64))

def mis_lp_dflt__want() -> Bool:
  True{}

def mis_fa_dflt__got() -> Bool:
  r_fa_dflt(Ty.tok_n(1n))

def mis_fa_dflt__want() -> Bool:
  True{}

def mis_sh_dflt__got() -> Bool:
  r_sh_dflt(Ty.tok_f(4.0f64))

def mis_sh_dflt__want() -> Bool:
  True{}

def mis_so_dflt__got() -> Bool:
  r_so_dflt(Ty.tok_n(2n))

def mis_so_dflt__want() -> Bool:
  True{}

def mis_cp_empty__got() -> Bool:
  r_cp_empty(Ty.tok_b(False{}))

def mis_cp_empty__want() -> Bool:
  True{}

def mis_brep_empty__got() -> Bool:
  r_brep_empty(Ty.tok_f(5.0f64))

def mis_brep_empty__want() -> Bool:
  True{}

def mis_hv_null__got() -> Bool:
  hv_null_chk(Ty.tres_hv(Ty.tok_f(6.0f64)))

def mis_hv_null__want() -> Bool:
  True{}

def mis_he_null__got() -> Bool:
  he_null_chk(Ty.tres_he(Ty.tok_n(3n)))

def mis_he_null__want() -> Bool:
  True{}

def mis_hc_null__got() -> Bool:
  hc_null_chk(Ty.tres_hc(Ty.tok_b(True{})))

def mis_hc_null__want() -> Bool:
  True{}

def mis_hlp_null__got() -> Bool:
  hlp_null_chk(Ty.tres_hlp(Ty.tok_f(7.0f64)))

def mis_hlp_null__want() -> Bool:
  True{}

def mis_hfa_null__got() -> Bool:
  hfa_null_chk(Ty.tres_hfa(Ty.tok_n(4n)))

def mis_hfa_null__want() -> Bool:
  True{}

def mis_hsh_null__got() -> Bool:
  hsh_null_chk(Ty.tres_hsh(Ty.tok_vx(vx_r())))

def mis_hsh_null__want() -> Bool:
  True{}

def mis_hso_null__got() -> Bool:
  hso_null_chk(Ty.tres_hso(Ty.tok_ed(ed_r())))

def mis_hso_null__want() -> Bool:
  True{}

def null_hv__got() -> Bool:
  hv_null_chk(Ty.hv_null())

def null_hv__want() -> Bool:
  True{}

def null_he__got() -> Bool:
  he_null_chk(Ty.he_null())

def null_he__want() -> Bool:
  True{}

def null_hc__got() -> Bool:
  hc_null_chk(Ty.hc_null())

def null_hc__want() -> Bool:
  True{}

def null_hlp__got() -> Bool:
  hlp_null_chk(Ty.hlp_null())

def null_hlp__want() -> Bool:
  True{}

def null_hfa__got() -> Bool:
  hfa_null_chk(Ty.hfa_null())

def null_hfa__want() -> Bool:
  True{}

def null_hsh__got() -> Bool:
  hsh_null_chk(Ty.hsh_null())

def null_hsh__want() -> Bool:
  True{}

def null_hso__got() -> Bool:
  hso_null_chk(Ty.hso_null())

def null_hso__want() -> Bool:
  True{}

def eq_hv__got() -> Bool:
  Bool.and(Ty.hv_eq(Ty.mk_hv(3n, 4u64), Ty.mk_hv(3n, 4u64)), Bool.and(Bool.not(Ty.hv_eq(Ty.mk_hv(3n, 4u64), Ty.mk_hv(5n, 4u64))), Bool.not(Ty.hv_eq(Ty.mk_hv(3n, 4u64), Ty.mk_hv(3n, 6u64)))))

def eq_hv__want() -> Bool:
  True{}

def eq_he__got() -> Bool:
  Bool.and(Ty.he_eq(Ty.mk_he(3n, 4u64), Ty.mk_he(3n, 4u64)), Bool.and(Bool.not(Ty.he_eq(Ty.mk_he(3n, 4u64), Ty.mk_he(5n, 4u64))), Bool.not(Ty.he_eq(Ty.mk_he(3n, 4u64), Ty.mk_he(3n, 6u64)))))

def eq_he__want() -> Bool:
  True{}

def eq_hc__got() -> Bool:
  Bool.and(Ty.hc_eq(Ty.mk_hc(3n, 4u64), Ty.mk_hc(3n, 4u64)), Bool.and(Bool.not(Ty.hc_eq(Ty.mk_hc(3n, 4u64), Ty.mk_hc(5n, 4u64))), Bool.not(Ty.hc_eq(Ty.mk_hc(3n, 4u64), Ty.mk_hc(3n, 6u64)))))

def eq_hc__want() -> Bool:
  True{}

def eq_hlp__got() -> Bool:
  Bool.and(Ty.hlp_eq(Ty.mk_hlp(3n, 4u64), Ty.mk_hlp(3n, 4u64)), Bool.and(Bool.not(Ty.hlp_eq(Ty.mk_hlp(3n, 4u64), Ty.mk_hlp(5n, 4u64))), Bool.not(Ty.hlp_eq(Ty.mk_hlp(3n, 4u64), Ty.mk_hlp(3n, 6u64)))))

def eq_hlp__want() -> Bool:
  True{}

def eq_hfa__got() -> Bool:
  Bool.and(Ty.hfa_eq(Ty.mk_hfa(3n, 4u64), Ty.mk_hfa(3n, 4u64)), Bool.and(Bool.not(Ty.hfa_eq(Ty.mk_hfa(3n, 4u64), Ty.mk_hfa(5n, 4u64))), Bool.not(Ty.hfa_eq(Ty.mk_hfa(3n, 4u64), Ty.mk_hfa(3n, 6u64)))))

def eq_hfa__want() -> Bool:
  True{}

def eq_hsh__got() -> Bool:
  Bool.and(Ty.hsh_eq(Ty.mk_hsh(3n, 4u64), Ty.mk_hsh(3n, 4u64)), Bool.and(Bool.not(Ty.hsh_eq(Ty.mk_hsh(3n, 4u64), Ty.mk_hsh(5n, 4u64))), Bool.not(Ty.hsh_eq(Ty.mk_hsh(3n, 4u64), Ty.mk_hsh(3n, 6u64)))))

def eq_hsh__want() -> Bool:
  True{}

def eq_hso__got() -> Bool:
  Bool.and(Ty.hso_eq(Ty.mk_hso(3n, 4u64), Ty.mk_hso(3n, 4u64)), Bool.and(Bool.not(Ty.hso_eq(Ty.mk_hso(3n, 4u64), Ty.mk_hso(5n, 4u64))), Bool.not(Ty.hso_eq(Ty.mk_hso(3n, 4u64), Ty.mk_hso(3n, 6u64)))))

def eq_hso__want() -> Bool:
  True{}

def isc_ln__got() -> Bool:
  Ty.gval_is_curve(cv_ln())

def isc_ln__want() -> Bool:
  True{}

def isc_cc__got() -> Bool:
  Ty.gval_is_curve(cv_cc())

def isc_cc__want() -> Bool:
  True{}

def isc_bz__got() -> Bool:
  Ty.gval_is_curve(cv_bz())

def isc_bz__want() -> Bool:
  True{}

def isc_rq__got() -> Bool:
  Ty.gval_is_curve(cv_rq())

def isc_rq__want() -> Bool:
  True{}

def isc_nb__got() -> Bool:
  Ty.gval_is_curve(cv_nb())

def isc_nb__want() -> Bool:
  True{}

def isc_pl_no__got() -> Bool:
  Ty.gval_is_curve(sf_pl())

def isc_pl_no__want() -> Bool:
  False{}

def isc_ts_no__got() -> Bool:
  Ty.gval_is_curve(tr_ts())

def isc_ts_no__want() -> Bool:
  False{}

def iss_pl__got() -> Bool:
  Ty.gval_is_surf(sf_pl())

def iss_pl__want() -> Bool:
  True{}

def iss_cy__got() -> Bool:
  Ty.gval_is_surf(sf_cy())

def iss_cy__want() -> Bool:
  True{}

def iss_co__got() -> Bool:
  Ty.gval_is_surf(sf_co())

def iss_co__want() -> Bool:
  True{}

def iss_sp__got() -> Bool:
  Ty.gval_is_surf(sf_sp())

def iss_sp__want() -> Bool:
  True{}

def iss_to__got() -> Bool:
  Ty.gval_is_surf(sf_to())

def iss_to__want() -> Bool:
  True{}

def iss_bp__got() -> Bool:
  Ty.gval_is_surf(sf_bp())

def iss_bp__want() -> Bool:
  True{}

def iss_ln_no__got() -> Bool:
  Ty.gval_is_surf(cv_ln())

def iss_ln_no__want() -> Bool:
  False{}

def iss_tb_no__got() -> Bool:
  Ty.gval_is_surf(tr_tb())

def iss_tb_no__want() -> Bool:
  False{}

def ist_ts__got() -> Bool:
  Ty.gval_is_trim(tr_ts())

def ist_ts__want() -> Bool:
  True{}

def ist_tb__got() -> Bool:
  Ty.gval_is_trim(tr_tb())

def ist_tb__want() -> Bool:
  True{}

def ist_ln_no__got() -> Bool:
  Ty.gval_is_trim(cv_ln())

def ist_ln_no__want() -> Bool:
  False{}

def ist_sp_no__got() -> Bool:
  Ty.gval_is_trim(sf_sp())

def ist_sp_no__want() -> Bool:
  False{}

def ne_hce0__got() -> Bool:
  Ty.hce_nonempty(hce0())

def ne_hce0__want() -> Bool:
  False{}

def ne_hce1__got() -> Bool:
  Ty.hce_nonempty(hc1())

def ne_hce1__want() -> Bool:
  True{}

def ne_hlp0__got() -> Bool:
  Ty.hlp_nonempty(hlp0())

def ne_hlp0__want() -> Bool:
  False{}

def ne_hlp1__got() -> Bool:
  Ty.hlp_nonempty(hlp1())

def ne_hlp1__want() -> Bool:
  True{}

def ne_hfa0__got() -> Bool:
  Ty.hfa_nonempty(hfa0())

def ne_hfa0__want() -> Bool:
  False{}

def ne_hfa1__got() -> Bool:
  Ty.hfa_nonempty(hfa1())

def ne_hfa1__want() -> Bool:
  True{}

def ne_hsh0__got() -> Bool:
  Ty.hsh_nonempty(hsh0())

def ne_hsh0__want() -> Bool:
  False{}

def ne_hsh1__got() -> Bool:
  Ty.hsh_nonempty(hsh1())

def ne_hsh1__want() -> Bool:
  True{}

def ne_hso0__got() -> Bool:
  Ty.hso_nonempty(hso0())

def ne_hso0__want() -> Bool:
  False{}

def ne_hso1__got() -> Bool:
  Ty.hso_nonempty(hso1())

def ne_hso1__want() -> Bool:
  True{}

def vx_valid_yes__got() -> Bool:
  Ty.vx_valid(Ty.Vx{0u64, p123()})

def vx_valid_yes__want() -> Bool:
  True{}

def vx_valid_no__got() -> Bool:
  Ty.vx_valid(Ty.Vx{0u64, pnan()})

def vx_valid_no__want() -> Bool:
  False{}

def ev_curve__got() -> Bool:
  Ty.edge_valid(Ty.Ed{0u64, hv01(), hv12(), Ty.EK_curve{cv_ln(), dom_01()}})

def ev_curve__want() -> Bool:
  True{}

def ev_closed__got() -> Bool:
  Ty.edge_valid(Ty.Ed{0u64, hv12(), hv12(), Ty.EK_curve{cv_cc(), dom_01()}})

def ev_closed__want() -> Bool:
  True{}

def ev_arm_no__got() -> Bool:
  Ty.edge_valid(Ty.Ed{0u64, hv01(), hv12(), Ty.EK_curve{sf_pl(), dom_01()}})

def ev_arm_no__want() -> Bool:
  False{}

def ev_dom_no__got() -> Bool:
  Ty.edge_valid(Ty.Ed{0u64, hv01(), hv12(), Ty.EK_curve{cv_ln(), dom_flip()}})

def ev_dom_no__want() -> Bool:
  False{}

def ev_degen__got() -> Bool:
  Ty.edge_valid(Ty.Ed{0u64, hv01(), hv01(), Ty.EK_degenerate{}})

def ev_degen__want() -> Bool:
  True{}

def ev_degen_no__got() -> Bool:
  Ty.edge_valid(Ty.Ed{0u64, hv01(), hv12(), Ty.EK_degenerate{}})

def ev_degen_no__want() -> Bool:
  False{}

def eclosed_yes__got() -> Bool:
  Ty.edge_is_closed(Ty.Ed{0u64, hv12(), hv12(), Ty.EK_curve{cv_ln(), dom_01()}})

def eclosed_yes__want() -> Bool:
  True{}

def eclosed_no__got() -> Bool:
  Ty.edge_is_closed(Ty.Ed{0u64, hv01(), hv12(), Ty.EK_curve{cv_ln(), dom_01()}})

def eclosed_no__want() -> Bool:
  False{}

def edegen_yes__got() -> Bool:
  Ty.edge_is_degenerate(Ty.Ed{0u64, hv01(), hv01(), Ty.EK_degenerate{}})

def edegen_yes__want() -> Bool:
  True{}

def edegen_no__got() -> Bool:
  Ty.edge_is_degenerate(Ty.Ed{0u64, hv01(), hv12(), Ty.EK_curve{cv_ln(), dom_01()}})

def edegen_no__want() -> Bool:
  False{}

def ce_valid_yes__got() -> Bool:
  Ty.ce_valid(Ty.Ce{0u64, he01(), True{}, tr_ts()})

def ce_valid_yes__want() -> Bool:
  True{}

def ce_valid_no__got() -> Bool:
  Ty.ce_valid(Ty.Ce{0u64, he01(), True{}, cv_ln()})

def ce_valid_no__want() -> Bool:
  False{}

def lp_valid_yes__got() -> Bool:
  Ty.lp_valid(Ty.Lp{0u64, hc1(), Ty.LK_outer{}})

def lp_valid_yes__want() -> Bool:
  True{}

def lp_valid_no__got() -> Bool:
  Ty.lp_valid(Ty.Lp{0u64, hce0(), Ty.LK_outer{}})

def lp_valid_no__want() -> Bool:
  False{}

def fa_valid_yes__got() -> Bool:
  Ty.fa_valid(Ty.Fa{0u64, sf_pl(), hlp1(), True{}, 0.0f64, 0.0f64})

def fa_valid_yes__want() -> Bool:
  True{}

def fa_valid_arm__got() -> Bool:
  Ty.fa_valid(Ty.Fa{0u64, cv_ln(), hlp1(), True{}, 0.0f64, 0.0f64})

def fa_valid_arm__want() -> Bool:
  False{}

def fa_valid_loops__got() -> Bool:
  Ty.fa_valid(Ty.Fa{0u64, sf_pl(), hlp0(), True{}, 0.0f64, 0.0f64})

def fa_valid_loops__want() -> Bool:
  False{}

def sh_valid_yes__got() -> Bool:
  Ty.sh_valid(Ty.Sh{0u64, hfa1(), Ty.SK_outer{}})

def sh_valid_yes__want() -> Bool:
  True{}

def sh_valid_no__got() -> Bool:
  Ty.sh_valid(Ty.Sh{0u64, hfa0(), Ty.SK_outer{}})

def sh_valid_no__want() -> Bool:
  False{}

def so_valid_yes__got() -> Bool:
  Ty.so_valid(Ty.So{0u64, hsh_a(), hsh0()})

def so_valid_yes__want() -> Bool:
  True{}

def so_cav_no__got() -> Bool:
  Ty.so_has_cav(Ty.So{0u64, hsh_a(), hsh0()})

def so_cav_no__want() -> Bool:
  False{}

def so_cav_yes__got() -> Bool:
  Ty.so_has_cav(Ty.So{0u64, hsh_a(), hsh1()})

def so_cav_yes__want() -> Bool:
  True{}

def cp_sol_no__got() -> Bool:
  Ty.cp_has_solids(Ty.Cp{hso0(), hsh0()})

def cp_sol_no__want() -> Bool:
  False{}

def cp_sol_yes__got() -> Bool:
  Ty.cp_has_solids(Ty.Cp{hso1(), hsh0()})

def cp_sol_yes__want() -> Bool:
  True{}

def cp_sh_no__got() -> Bool:
  Ty.cp_has_shells(Ty.Cp{hso0(), hsh0()})

def cp_sh_no__want() -> Bool:
  False{}

def cp_sh_yes__got() -> Bool:
  Ty.cp_has_shells(Ty.Cp{hso0(), hsh1()})

def cp_sh_yes__want() -> Bool:
  True{}

def tag_ek_curve__got() -> Bool:
  U64.is_eq(Ty.ekind_tag(Ty.EK_curve{cv_ln(), dom_01()}), 0u64)

def tag_ek_curve__want() -> Bool:
  True{}

def tag_ek_degen__got() -> Bool:
  U64.is_eq(Ty.ekind_tag(Ty.EK_degenerate{}), 1u64)

def tag_ek_degen__want() -> Bool:
  True{}

def tag_lk_outer__got() -> Bool:
  U64.is_eq(Ty.lkind_tag(Ty.LK_outer{}), 0u64)

def tag_lk_outer__want() -> Bool:
  True{}

def tag_lk_inner__got() -> Bool:
  U64.is_eq(Ty.lkind_tag(Ty.LK_inner{}), 1u64)

def tag_lk_inner__want() -> Bool:
  True{}

def tag_sk_outer__got() -> Bool:
  U64.is_eq(Ty.skind_tag(Ty.SK_outer{}), 0u64)

def tag_sk_outer__want() -> Bool:
  True{}

def tag_sk_inner__got() -> Bool:
  U64.is_eq(Ty.skind_tag(Ty.SK_inner{}), 1u64)

def tag_sk_inner__want() -> Bool:
  True{}

def tag_sk_open__got() -> Bool:
  U64.is_eq(Ty.skind_tag(Ty.SK_open{}), 2u64)

def tag_sk_open__want() -> Bool:
  True{}

def tag_prof_solid__got() -> Bool:
  U64.is_eq(Ty.profile_tag(Ty.P_manifold_solid{}), 0u64)

def tag_prof_solid__want() -> Bool:
  True{}

def tag_prof_open__got() -> Bool:
  U64.is_eq(Ty.profile_tag(Ty.P_open_shell{}), 1u64)

def tag_prof_open__want() -> Bool:
  True{}

def show_prof_solid__got() -> Bool:
  String.eq(Ty.profile_show(Ty.P_manifold_solid{}), "manifold-solid")

def show_prof_solid__want() -> Bool:
  True{}

def show_prof_open__got() -> Bool:
  String.eq(Ty.profile_show(Ty.P_open_shell{}), "open-shell")

def show_prof_open__want() -> Bool:
  True{}

def ekind_is_curve_t__got() -> Bool:
  Ty.ekind_is_curve(Ty.EK_curve{cv_ln(), dom_01()})

def ekind_is_curve_t__want() -> Bool:
  True{}

def ekind_is_curve_f__got() -> Bool:
  Ty.ekind_is_curve(Ty.EK_degenerate{})

def ekind_is_curve_f__want() -> Bool:
  False{}

def ekind_curve_degen__got() -> Bool:
  ln_zero_bits(Ty.ekind_curve(Ty.EK_degenerate{}))

def ekind_curve_degen__want() -> Bool:
  True{}

def ekind_dom_degen__got() -> Bool:
  Bool.and(U64.is_eq(F64.bits(G.dom_lo(Ty.ekind_dom( Ty.EK_degenerate{}))), 0u64), U64.is_eq(F64.bits(G.dom_hi(Ty.ekind_dom( Ty.EK_degenerate{}))), 0u64))

def ekind_dom_degen__want() -> Bool:
  True{}

def ekind_dom_curve__got() -> Bool:
  Bool.and(U64.is_eq(F64.bits(G.dom_lo(Ty.ekind_dom( Ty.EK_curve{cv_ln(), dom_01()}))), 0u64), U64.is_eq(F64.bits(G.dom_hi(Ty.ekind_dom( Ty.EK_curve{cv_ln(), dom_01()}))), 4607182418800017408u64))

def ekind_dom_curve__want() -> Bool:
  True{}

def okd_pack_tt__got() -> Bool:
  Nat.is_eq(Ty.okd_pack(True{}, True{}), 3n)

def okd_pack_tt__want() -> Bool:
  True{}

def okd_pack_tf__got() -> Bool:
  Nat.is_eq(Ty.okd_pack(True{}, False{}), 1n)

def okd_pack_tf__want() -> Bool:
  True{}

def okd_pack_ft__got() -> Bool:
  Nat.is_eq(Ty.okd_pack(False{}, True{}), 2n)

def okd_pack_ft__want() -> Bool:
  True{}

def okd_pack_ff__got() -> Bool:
  Nat.is_eq(Ty.okd_pack(False{}, False{}), 0n)

def okd_pack_ff__want() -> Bool:
  True{}

def okd_ok_3__got() -> Bool:
  Ty.okd_ok(3n)

def okd_ok_3__want() -> Bool:
  True{}

def okd_ok_2__got() -> Bool:
  Ty.okd_ok(2n)

def okd_ok_2__want() -> Bool:
  False{}

def okd_done_3__got() -> Bool:
  Ty.okd_done(3n)

def okd_done_3__want() -> Bool:
  True{}

def okd_done_1__got() -> Bool:
  Ty.okd_done(1n)

def okd_done_1__want() -> Bool:
  False{}

def okd_all_33__got() -> Bool:
  Nat.is_eq(Ty.okd_all(3n, 3n), 3n)

def okd_all_33__want() -> Bool:
  True{}

def okd_all_30__got() -> Bool:
  Nat.is_eq(Ty.okd_all(3n, 0n), 0n)

def okd_all_30__want() -> Bool:
  True{}

def okd_all_12__got() -> Bool:
  Nat.is_eq(Ty.okd_all(1n, 2n), 0n)

def okd_all_12__want() -> Bool:
  True{}

def mk_vx_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(Ty.mk_vx(p123())), "ok"), pt_bits_eq(Ty.vx_p(Ty.tres_vx(Ty.mk_vx(p123()))), 4607182418800017408u64, 4611686018427387904u64, 4613937818241073152u64))

def mk_vx_ok__want() -> Bool:
  True{}

def mk_vx_gen0__got() -> Bool:
  U64.is_eq(Ty.vx_gen(Ty.tres_vx(Ty.mk_vx(p123()))), 0u64)

def mk_vx_gen0__want() -> Bool:
  True{}

def mk_vx_nan__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(Ty.mk_vx(pnan())), "invalid-input"), r_vx_zero(Ty.mk_vx(pnan())))

def mk_vx_nan__want() -> Bool:
  True{}

def mk_vx_inf__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_vx(pinf())), "invalid-input")

def mk_vx_inf__want() -> Bool:
  True{}

def mk_ec_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(Ty.mk_edge_curve(hv01(), hv12(), cv_ln(), dom_01())), "ok"), U64.is_eq(Ty.ed_gen(Ty.tres_ed(Ty.mk_edge_curve(hv01(), hv12(), cv_ln(), dom_01()))), 0u64))

def mk_ec_ok__want() -> Bool:
  True{}

def mk_ec_arm__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_edge_curve(hv01(), hv12(), sf_pl(), dom_01())), "invalid-input")

def mk_ec_arm__want() -> Bool:
  True{}

def mk_ec_dom__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_edge_curve(hv01(), hv12(), cv_ln(), dom_flip())), "invalid-input")

def mk_ec_dom__want() -> Bool:
  True{}

def mk_ec_domeq__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_edge_curve(hv01(), hv12(), cv_ln(), dom_eq())), "invalid-input")

def mk_ec_domeq__want() -> Bool:
  True{}

def mk_ec_domnan__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_edge_curve(hv01(), hv12(), cv_ln(), dom_nan())), "invalid-input")

def mk_ec_domnan__want() -> Bool:
  True{}

def mk_ec_trim__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_edge_curve(hv01(), hv12(), tr_ts(), dom_01())), "invalid-input")

def mk_ec_trim__want() -> Bool:
  True{}

def mk_edg_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(Ty.mk_edge_degen(hv01(), hv01())), "ok"), U64.is_eq(Ty.ed_gen(Ty.tres_ed(Ty.mk_edge_degen(hv01(), hv01()))), 0u64))

def mk_edg_ok__want() -> Bool:
  True{}

def mk_edg_split__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_edge_degen(hv01(), hv12())), "invalid-input")

def mk_edg_split__want() -> Bool:
  True{}

def mk_ce_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(Ty.mk_coedge(he01(), True{}, tr_ts())), "ok"), U64.is_eq(Ty.ce_gen(Ty.tres_ce(Ty.mk_coedge(he01(), True{}, tr_ts()))), 0u64))

def mk_ce_ok__want() -> Bool:
  True{}

def mk_ce_rev__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(Ty.mk_coedge(he01(), False{}, tr_tb())), "ok"), Bool.not(Ty.ce_fwd(Ty.tres_ce(Ty.mk_coedge(he01(), False{}, tr_tb())))))

def mk_ce_rev__want() -> Bool:
  True{}

def mk_ce_trim__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_coedge(he01(), True{}, cv_ln())), "invalid-input")

def mk_ce_trim__want() -> Bool:
  True{}

def mk_ce_surf__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_coedge(he01(), True{}, sf_pl())), "invalid-input")

def mk_ce_surf__want() -> Bool:
  True{}

def mk_lp_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(Ty.mk_loop(hc2(), Ty.LK_inner{})), "ok"), Bool.and(U64.is_eq(Ty.lp_gen(Ty.tres_lp(Ty.mk_loop( hc2(), Ty.LK_inner{}))), 0u64), U64.is_eq(Ty.lkind_tag(Ty.lp_kind(Ty.tres_lp( Ty.mk_loop(hc2(), Ty.LK_inner{})))), 1u64)))

def mk_lp_ok__want() -> Bool:
  True{}

def mk_lp_nil__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_loop(hce0(), Ty.LK_outer{})), "invalid-input")

def mk_lp_nil__want() -> Bool:
  True{}

def mk_fa_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(Ty.mk_face(sf_cy(), hlp1(), False{})), "ok"), Bool.and(U64.is_eq(Ty.fa_gen(Ty.tres_fa(Ty.mk_face( sf_cy(), hlp1(), False{}))), 0u64), Bool.not(Ty.fa_same(Ty.tres_fa(Ty.mk_face(sf_cy(), hlp1(), False{}))))))

def mk_fa_ok__want() -> Bool:
  True{}

def mk_fa_arm__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_face(cv_ln(), hlp1(), True{})), "invalid-input")

def mk_fa_arm__want() -> Bool:
  True{}

def mk_fa_loops__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_face(sf_pl(), hlp0(), True{})), "invalid-input")

def mk_fa_loops__want() -> Bool:
  True{}

def mk_sh_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(Ty.mk_shell(hfa1(), Ty.SK_inner{})), "ok"), Bool.and(U64.is_eq(Ty.sh_gen(Ty.tres_sh(Ty.mk_shell( hfa1(), Ty.SK_inner{}))), 0u64), U64.is_eq(Ty.skind_tag(Ty.sh_kind(Ty.tres_sh( Ty.mk_shell(hfa1(), Ty.SK_inner{})))), 1u64)))

def mk_sh_ok__want() -> Bool:
  True{}

def mk_sh_nil__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_shell(hfa0(), Ty.SK_outer{})), "invalid-input")

def mk_sh_nil__want() -> Bool:
  True{}

def mk_so_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(Ty.mk_solid(hsh_a(), hsh1())), "ok"), Bool.and(U64.is_eq(Ty.so_gen(Ty.tres_so(Ty.mk_solid( hsh_a(), hsh1()))), 0u64), Ty.so_has_cav(Ty.tres_so(Ty.mk_solid(hsh_a(), hsh1())))))

def mk_so_ok__want() -> Bool:
  True{}

def mk_cp_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(Ty.mk_compound(hso1(), hsh1())), "ok"), Bool.and(Ty.cp_has_solids(Ty.tres_cp(Ty.mk_compound( hso1(), hsh1()))), Ty.cp_has_shells(Ty.tres_cp(Ty.mk_compound(hso1(), hsh1())))))

def mk_cp_ok__want() -> Bool:
  True{}

def mk_brep_empty__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es0(), ces0(), lps0(), fas0(), shs0(), sos0(), top0(), 7u64, 0n)), "ok"), U64.is_eq(Ty.brep_stamp(Ty.tres_brep(Ty.mk_brep(vs0(), es0(), ces0(), lps0(), fas0(), shs0(), sos0(), top0(), 7u64, 0n))), 7u64))

def mk_brep_empty__want() -> Bool:
  True{}

def mk_brep_full__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(Ty.mk_brep(vs1(), es1(), ces1(), lps1(), fas1(), shs1(), sos1(), top1(), 61u64, 8n)), "ok"), U64.is_eq(Ty.brep_stamp(Ty.tres_brep(Ty.mk_brep(vs1(), es1(), ces1(), lps1(), fas1(), shs1(), sos1(), top1(), 61u64, 8n))), 61u64))

def mk_brep_full__want() -> Bool:
  True{}

def mk_brep_vx__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_brep(vs_bad(), es0(), ces0(), lps0(), fas0(), shs0(), sos0(), top0(), 1u64, 8n)), "invalid-input")

def mk_brep_vx__want() -> Bool:
  True{}

def mk_brep_es_arm__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es_badarm(), ces0(), lps0(), fas0(), shs0(), sos0(), top0(), 11u64, 8n)), "invalid-input")

def mk_brep_es_arm__want() -> Bool:
  True{}

def mk_brep_es_degen__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es_baddegen(), ces0(), lps0(), fas0(), shs0(), sos0(), top0(), 11u64, 8n)), "invalid-input")

def mk_brep_es_degen__want() -> Bool:
  True{}

def mk_brep_ces__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es0(), ces_bad(), lps0(), fas0(), shs0(), sos0(), top0(), 21u64, 8n)), "invalid-input")

def mk_brep_ces__want() -> Bool:
  True{}

def mk_brep_lps__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es0(), ces0(), lps_bad(), fas0(), shs0(), sos0(), top0(), 31u64, 8n)), "invalid-input")

def mk_brep_lps__want() -> Bool:
  True{}

def mk_brep_fas_arm__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es0(), ces0(), lps0(), fas_badarm(), shs0(), sos0(), top0(), 41u64, 8n)), "invalid-input")

def mk_brep_fas_arm__want() -> Bool:
  True{}

def mk_brep_fas_loops__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es0(), ces0(), lps0(), fas_badloops(), shs0(), sos0(), top0(), 41u64, 8n)), "invalid-input")

def mk_brep_fas_loops__want() -> Bool:
  True{}

def mk_brep_shs__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es0(), ces0(), lps0(), fas0(), shs_bad(), sos0(), top0(), 51u64, 8n)), "invalid-input")

def mk_brep_shs__want() -> Bool:
  True{}

def mk_brep_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_brep(vs1(), es0(), ces0(), lps0(), fas0(), shs0(), sos0(), top0(), 1u64, 0n)), "resource-exhausted")

def mk_brep_fuel__want() -> Bool:
  True{}

def mk_brep_stamp__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_brep(vs1(), es0(), ces0(), lps0(), fas0(), shs0(), sos0(), top0(), 0u64, 8n)), "invalid-input")

def mk_brep_stamp__want() -> Bool:
  True{}

def mk_brep_gen0__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_brep(vs_gen0(), es0(), ces0(), lps0(), fas0(), shs0(), sos0(), top0(), 1u64, 8n)), "invalid-input")

def mk_brep_gen0__want() -> Bool:
  True{}

def mk_brep_dup__got() -> Bool:
  String.eq(Ty.tres_show(Ty.mk_brep(vs_dup(), es0(), ces0(), lps0(), fas0(), shs0(), sos0(), top0(), 1u64, 8n)), "invalid-input")

def mk_brep_dup__want() -> Bool:
  True{}

def gen_vs_ok__got() -> Bool:
  Nat.is_eq(Ty.vs_gen_c(vs1(), 1u64, 8n), 3n)

def gen_vs_ok__want() -> Bool:
  True{}

def gen_vs_stamp__got() -> Bool:
  Nat.is_eq(Ty.vs_gen_c(vs1(), 0u64, 8n), 2n)

def gen_vs_stamp__want() -> Bool:
  True{}

def gen_vs_zero__got() -> Bool:
  Nat.is_eq(Ty.vs_gen_c(vs_gen0(), 1u64, 8n), 2n)

def gen_vs_zero__want() -> Bool:
  True{}

def gen_vs_fuel__got() -> Bool:
  Nat.is_eq(Ty.vs_gen_c(vs1(), 1u64, 0n), 0n)

def gen_vs_fuel__want() -> Bool:
  True{}

def nodup_vs_ok__got() -> Bool:
  Nat.is_eq(Ty.vs_nodup_c(vs2(), 8n), 3n)

def nodup_vs_ok__want() -> Bool:
  True{}

def nodup_vs_dup__got() -> Bool:
  Nat.is_eq(Ty.vs_nodup_c(vs_dup(), 8n), 2n)

def nodup_vs_dup__want() -> Bool:
  True{}

def nodup_vs_fuel__got() -> Bool:
  Nat.is_eq(Ty.vs_nodup_c(vs1(), 0n), 0n)

def nodup_vs_fuel__want() -> Bool:
  True{}

def allc_vs0__got() -> Bool:
  Nat.is_eq(Ty.vs_all_c(vs0(), 8n), 3n)

def allc_vs0__want() -> Bool:
  True{}

def allc_vs1__got() -> Bool:
  Nat.is_eq(Ty.vs_all_c(vs1(), 8n), 3n)

def allc_vs1__want() -> Bool:
  True{}

def allc_vs2__got() -> Bool:
  Nat.is_eq(Ty.vs_all_c(vs2(), 8n), 3n)

def allc_vs2__want() -> Bool:
  True{}

def allc_vs_bad__got() -> Bool:
  Nat.is_eq(Ty.vs_all_c(vs_bad(), 8n), 2n)

def allc_vs_bad__want() -> Bool:
  True{}

def allc_vs_fuel__got() -> Bool:
  Nat.is_eq(Ty.vs_all_c(vs1(), 0n), 0n)

def allc_vs_fuel__want() -> Bool:
  True{}

def allc_es1__got() -> Bool:
  Nat.is_eq(Ty.es_all_c(es1(), 8n), 3n)

def allc_es1__want() -> Bool:
  True{}

def allc_ces1__got() -> Bool:
  Nat.is_eq(Ty.ces_all_c(ces1(), 8n), 3n)

def allc_ces1__want() -> Bool:
  True{}

def allc_lps1__got() -> Bool:
  Nat.is_eq(Ty.lps_all_c(lps1(), 8n), 3n)

def allc_lps1__want() -> Bool:
  True{}

def allc_fas1__got() -> Bool:
  Nat.is_eq(Ty.fas_all_c(fas1(), 8n), 3n)

def allc_fas1__want() -> Bool:
  True{}

def allc_shs1__got() -> Bool:
  Nat.is_eq(Ty.shs_all_c(shs1(), 8n), 3n)

def allc_shs1__want() -> Bool:
  True{}

def allc_sos1__got() -> Bool:
  Nat.is_eq(Ty.sos_all_c(sos1(), 8n), 3n)

def allc_sos1__want() -> Bool:
  True{}

def snoc_vx__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.vx_len(Ty.vx_snoc(vs1(), vx_b()), 8n)), 2n)

def snoc_vx__want() -> Bool:
  True{}

def snoc_ed__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.ed_len(Ty.ed_snoc(es1(), ed_b()), 8n)), 2n)

def snoc_ed__want() -> Bool:
  True{}

def empty_stamp__got() -> Bool:
  U64.is_eq(Ty.brep_stamp(b_empty()), 0u64)

def empty_stamp__want() -> Bool:
  True{}

def empty_top__got() -> Bool:
  Bool.and(Bool.not(Ty.cp_has_solids(Ty.brep_top( b_empty()))), Bool.not(Ty.cp_has_shells(Ty.brep_top(b_empty()))))

def empty_top__want() -> Bool:
  True{}

def empty_vs_len__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.vx_len(Ty.brep_vs(b_empty()), 8n)), 0n)

def empty_vs_len__want() -> Bool:
  True{}

def set_top__got() -> Bool:
  Bool.and(Ty.cp_has_solids(Ty.brep_top(Ty.brep_set_top( b_empty(), top1()))), Ty.cp_has_shells(Ty.brep_top(Ty.brep_set_top( b_empty(), top1()))))

def set_top__want() -> Bool:
  True{}

def zero_curve__got() -> Bool:
  ln_zero_bits(Ty.curve_zero())

def zero_curve__want() -> Bool:
  True{}

def zero_surf__got() -> Bool:
  pl_zero_bits(Ty.surf_zero())

def zero_surf__want() -> Bool:
  True{}

def zero_trim__got() -> Bool:
  ts_zero_bits(Ty.trim_zero())

def zero_trim__want() -> Bool:
  True{}

def vx_len2__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.vx_len(vs2(), 8n)), 2n)

def vx_len2__want() -> Bool:
  True{}

def vx_len0__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.vx_len(vs0(), 8n)), 0n)

def vx_len0__want() -> Bool:
  True{}

def vx_len_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.vx_len(vs1(), 0n)), "resource-exhausted")

def vx_len_fuel__want() -> Bool:
  True{}

def vx_at_gen__got() -> Bool:
  U64.is_eq(Ty.vx_gen(v_at_vx()), 2u64)

def vx_at_gen__want() -> Bool:
  True{}

def vx_at_headfree__got() -> Bool:
  String.eq(Ty.tres_show(Ty.vx_at(vs1(), 0n, 0n)), "ok")

def vx_at_headfree__want() -> Bool:
  True{}

def vx_at_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.vx_at(vs1(), 5n, 8n)), "invalid-input")

def vx_at_oob__want() -> Bool:
  True{}

def vx_at_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.vx_at(vs2(), 1n, 0n)), "resource-exhausted")

def vx_at_fuel__want() -> Bool:
  True{}

def vx_res_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_res_vx()), "ok"), U64.is_eq(Ty.vx_gen(v_res_vx()), 2u64))

def vx_res_ok__want() -> Bool:
  True{}

def vx_res_stale__got() -> Bool:
  String.eq(Ty.tres_show(Ty.vx_resolve(vs1(), Ty.mk_hv(0n, 99u64), 8n)), "invalid-input")

def vx_res_stale__want() -> Bool:
  True{}

def vx_res_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.vx_resolve(vs1(), Ty.mk_hv(5n, 1u64), 8n)), "invalid-input")

def vx_res_oob__want() -> Bool:
  True{}

def vx_res_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.vx_resolve(vs2(), Ty.mk_hv(1n, 2u64), 0n)), "resource-exhausted")

def vx_res_fuel__want() -> Bool:
  True{}

def vx_hof_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hv_idx(h_hof_vx()), 1n), U64.is_eq(Ty.hv_gen(h_hof_vx()), 2u64))

def vx_hof_idx__want() -> Bool:
  True{}

def vx_hof_unknown__got() -> Bool:
  String.eq(Ty.tres_show(Ty.vx_handle_of(vs2(), 99u64, 8n)), "invalid-input")

def vx_hof_unknown__want() -> Bool:
  True{}

def vx_hof_empty__got() -> Bool:
  String.eq(Ty.tres_show(Ty.vx_handle_of(vs0(), 1u64, 8n)), "invalid-input")

def vx_hof_empty__want() -> Bool:
  True{}

def vx_hof_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.vx_handle_of(vs2(), 2u64, 0n)), "resource-exhausted")

def vx_hof_fuel__want() -> Bool:
  True{}

def vx_hof_head0__got() -> Bool:
  Nat.is_eq(Ty.hv_idx(Ty.tres_hv(Ty.vx_handle_of(vs1(), 1u64, 0n))), 0n)

def vx_hof_head0__want() -> Bool:
  True{}

def vx_iss_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hv_idx(h_iss_vx()), 1n), U64.is_eq(Ty.hv_gen(h_iss_vx()), 2u64))

def vx_iss_idx__want() -> Bool:
  True{}

def vx_iss_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.vx_issued(b_vs1(), 0n)), "resource-exhausted")

def vx_iss_fuel__want() -> Bool:
  True{}

def vx_push_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_pvx()), "ok"), Bool.and(U64.is_eq(Ty.brep_stamp(b_pvx()), 1u64), Nat.is_eq(Ty.tres_n(Ty.vx_len(Ty.brep_vs(b_pvx()), 8n)), 1n)))

def vx_push_ok__want() -> Bool:
  True{}

def vx_push_res__got() -> Bool:
  String.eq(Ty.tres_show(Ty.vx_resolve(Ty.brep_vs(b_pvx()), Ty.mk_hv(0n, 1u64), 8n)), "ok")

def vx_push_res__want() -> Bool:
  True{}

def vx_push_bad__got() -> Bool:
  String.eq(Ty.tres_show(Ty.vx_push(b_empty(), pnan())), "invalid-input")

def vx_push_bad__want() -> Bool:
  True{}

def ed_len2__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.ed_len(es2(), 8n)), 2n)

def ed_len2__want() -> Bool:
  True{}

def ed_len0__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.ed_len(es0(), 8n)), 0n)

def ed_len0__want() -> Bool:
  True{}

def ed_len_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_len(es1(), 0n)), "resource-exhausted")

def ed_len_fuel__want() -> Bool:
  True{}

def ed_at_gen__got() -> Bool:
  U64.is_eq(Ty.ed_gen(v_at_ed()), 12u64)

def ed_at_gen__want() -> Bool:
  True{}

def ed_at_headfree__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_at(es1(), 0n, 0n)), "ok")

def ed_at_headfree__want() -> Bool:
  True{}

def ed_at_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_at(es1(), 5n, 8n)), "invalid-input")

def ed_at_oob__want() -> Bool:
  True{}

def ed_at_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_at(es2(), 1n, 0n)), "resource-exhausted")

def ed_at_fuel__want() -> Bool:
  True{}

def ed_res_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_res_ed()), "ok"), U64.is_eq(Ty.ed_gen(v_res_ed()), 12u64))

def ed_res_ok__want() -> Bool:
  True{}

def ed_res_stale__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_resolve(es1(), Ty.mk_he(0n, 99u64), 8n)), "invalid-input")

def ed_res_stale__want() -> Bool:
  True{}

def ed_res_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_resolve(es1(), Ty.mk_he(5n, 11u64), 8n)), "invalid-input")

def ed_res_oob__want() -> Bool:
  True{}

def ed_res_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_resolve(es2(), Ty.mk_he(1n, 12u64), 0n)), "resource-exhausted")

def ed_res_fuel__want() -> Bool:
  True{}

def ed_hof_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.he_idx(h_hof_ed()), 1n), U64.is_eq(Ty.he_gen(h_hof_ed()), 12u64))

def ed_hof_idx__want() -> Bool:
  True{}

def ed_hof_unknown__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_handle_of(es2(), 99u64, 8n)), "invalid-input")

def ed_hof_unknown__want() -> Bool:
  True{}

def ed_hof_empty__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_handle_of(es0(), 11u64, 8n)), "invalid-input")

def ed_hof_empty__want() -> Bool:
  True{}

def ed_hof_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_handle_of(es2(), 12u64, 0n)), "resource-exhausted")

def ed_hof_fuel__want() -> Bool:
  True{}

def ed_hof_head0__got() -> Bool:
  Nat.is_eq(Ty.he_idx(Ty.tres_he(Ty.ed_handle_of(es1(), 11u64, 0n))), 0n)

def ed_hof_head0__want() -> Bool:
  True{}

def ed_iss_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.he_idx(h_iss_ed()), 1n), U64.is_eq(Ty.he_gen(h_iss_ed()), 12u64))

def ed_iss_idx__want() -> Bool:
  True{}

def ed_iss_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_issued(b_es1(), 0n)), "resource-exhausted")

def ed_iss_fuel__want() -> Bool:
  True{}

def ed_push_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_ped()), "ok"), Bool.and(U64.is_eq(Ty.brep_stamp(b_ped()), 1u64), Nat.is_eq(Ty.tres_n(Ty.ed_len(Ty.brep_es(b_ped()), 8n)), 1n)))

def ed_push_ok__want() -> Bool:
  True{}

def ed_push_res__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_resolve(Ty.brep_es(b_ped()), Ty.mk_he(0n, 1u64), 8n)), "ok")

def ed_push_res__want() -> Bool:
  True{}

def ed_push_arm__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_push(b_empty(), hv01(), hv12(), Ty.EK_curve{sf_pl(), dom_01()})), "invalid-input")

def ed_push_arm__want() -> Bool:
  True{}

def ed_push_degen__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ed_push(b_empty(), hv01(), hv12(), Ty.EK_degenerate{})), "invalid-input")

def ed_push_degen__want() -> Bool:
  True{}

def ce_len2__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.ce_len(ces2(), 8n)), 2n)

def ce_len2__want() -> Bool:
  True{}

def ce_len0__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.ce_len(ces0(), 8n)), 0n)

def ce_len0__want() -> Bool:
  True{}

def ce_len_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ce_len(ces1(), 0n)), "resource-exhausted")

def ce_len_fuel__want() -> Bool:
  True{}

def ce_at_gen__got() -> Bool:
  U64.is_eq(Ty.ce_gen(v_at_ce()), 22u64)

def ce_at_gen__want() -> Bool:
  True{}

def ce_at_headfree__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ce_at(ces1(), 0n, 0n)), "ok")

def ce_at_headfree__want() -> Bool:
  True{}

def ce_at_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ce_at(ces1(), 5n, 8n)), "invalid-input")

def ce_at_oob__want() -> Bool:
  True{}

def ce_at_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ce_at(ces2(), 1n, 0n)), "resource-exhausted")

def ce_at_fuel__want() -> Bool:
  True{}

def ce_res_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_res_ce()), "ok"), U64.is_eq(Ty.ce_gen(v_res_ce()), 22u64))

def ce_res_ok__want() -> Bool:
  True{}

def ce_res_stale__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ce_resolve(ces1(), Ty.mk_hc(0n, 99u64), 8n)), "invalid-input")

def ce_res_stale__want() -> Bool:
  True{}

def ce_res_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ce_resolve(ces1(), Ty.mk_hc(5n, 21u64), 8n)), "invalid-input")

def ce_res_oob__want() -> Bool:
  True{}

def ce_res_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ce_resolve(ces2(), Ty.mk_hc(1n, 22u64), 0n)), "resource-exhausted")

def ce_res_fuel__want() -> Bool:
  True{}

def ce_hof_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hc_idx(h_hof_ce()), 1n), U64.is_eq(Ty.hc_gen(h_hof_ce()), 22u64))

def ce_hof_idx__want() -> Bool:
  True{}

def ce_hof_unknown__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ce_handle_of(ces2(), 99u64, 8n)), "invalid-input")

def ce_hof_unknown__want() -> Bool:
  True{}

def ce_hof_empty__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ce_handle_of(ces0(), 21u64, 8n)), "invalid-input")

def ce_hof_empty__want() -> Bool:
  True{}

def ce_hof_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ce_handle_of(ces2(), 22u64, 0n)), "resource-exhausted")

def ce_hof_fuel__want() -> Bool:
  True{}

def ce_hof_head0__got() -> Bool:
  Nat.is_eq(Ty.hc_idx(Ty.tres_hc(Ty.ce_handle_of(ces1(), 21u64, 0n))), 0n)

def ce_hof_head0__want() -> Bool:
  True{}

def ce_iss_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hc_idx(h_iss_ce()), 1n), U64.is_eq(Ty.hc_gen(h_iss_ce()), 22u64))

def ce_iss_idx__want() -> Bool:
  True{}

def ce_iss_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ce_issued(b_ces1(), 0n)), "resource-exhausted")

def ce_iss_fuel__want() -> Bool:
  True{}

def ce_push_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_pce()), "ok"), Bool.and(U64.is_eq(Ty.brep_stamp(b_pce()), 1u64), Nat.is_eq(Ty.tres_n(Ty.ce_len(Ty.brep_ces(b_pce()), 8n)), 1n)))

def ce_push_ok__want() -> Bool:
  True{}

def ce_push_res__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ce_resolve(Ty.brep_ces(b_pce()), Ty.mk_hc(0n, 1u64), 8n)), "ok")

def ce_push_res__want() -> Bool:
  True{}

def ce_push_trim__got() -> Bool:
  String.eq(Ty.tres_show(Ty.ce_push(b_empty(), he01(), True{}, cv_ln())), "invalid-input")

def ce_push_trim__want() -> Bool:
  True{}

def lp_len2__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.lp_len(lps2(), 8n)), 2n)

def lp_len2__want() -> Bool:
  True{}

def lp_len0__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.lp_len(lps0(), 8n)), 0n)

def lp_len0__want() -> Bool:
  True{}

def lp_len_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.lp_len(lps1(), 0n)), "resource-exhausted")

def lp_len_fuel__want() -> Bool:
  True{}

def lp_at_gen__got() -> Bool:
  U64.is_eq(Ty.lp_gen(v_at_lp()), 32u64)

def lp_at_gen__want() -> Bool:
  True{}

def lp_at_headfree__got() -> Bool:
  String.eq(Ty.tres_show(Ty.lp_at(lps1(), 0n, 0n)), "ok")

def lp_at_headfree__want() -> Bool:
  True{}

def lp_at_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.lp_at(lps1(), 5n, 8n)), "invalid-input")

def lp_at_oob__want() -> Bool:
  True{}

def lp_at_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.lp_at(lps2(), 1n, 0n)), "resource-exhausted")

def lp_at_fuel__want() -> Bool:
  True{}

def lp_res_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_res_lp()), "ok"), U64.is_eq(Ty.lp_gen(v_res_lp()), 32u64))

def lp_res_ok__want() -> Bool:
  True{}

def lp_res_stale__got() -> Bool:
  String.eq(Ty.tres_show(Ty.lp_resolve(lps1(), Ty.mk_hlp(0n, 99u64), 8n)), "invalid-input")

def lp_res_stale__want() -> Bool:
  True{}

def lp_res_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.lp_resolve(lps1(), Ty.mk_hlp(5n, 31u64), 8n)), "invalid-input")

def lp_res_oob__want() -> Bool:
  True{}

def lp_res_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.lp_resolve(lps2(), Ty.mk_hlp(1n, 32u64), 0n)), "resource-exhausted")

def lp_res_fuel__want() -> Bool:
  True{}

def lp_hof_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hlp_idx(h_hof_lp()), 1n), U64.is_eq(Ty.hlp_gen(h_hof_lp()), 32u64))

def lp_hof_idx__want() -> Bool:
  True{}

def lp_hof_unknown__got() -> Bool:
  String.eq(Ty.tres_show(Ty.lp_handle_of(lps2(), 99u64, 8n)), "invalid-input")

def lp_hof_unknown__want() -> Bool:
  True{}

def lp_hof_empty__got() -> Bool:
  String.eq(Ty.tres_show(Ty.lp_handle_of(lps0(), 31u64, 8n)), "invalid-input")

def lp_hof_empty__want() -> Bool:
  True{}

def lp_hof_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.lp_handle_of(lps2(), 32u64, 0n)), "resource-exhausted")

def lp_hof_fuel__want() -> Bool:
  True{}

def lp_hof_head0__got() -> Bool:
  Nat.is_eq(Ty.hlp_idx(Ty.tres_hlp(Ty.lp_handle_of(lps1(), 31u64, 0n))), 0n)

def lp_hof_head0__want() -> Bool:
  True{}

def lp_iss_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hlp_idx(h_iss_lp()), 1n), U64.is_eq(Ty.hlp_gen(h_iss_lp()), 32u64))

def lp_iss_idx__want() -> Bool:
  True{}

def lp_iss_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.lp_issued(b_lps1(), 0n)), "resource-exhausted")

def lp_iss_fuel__want() -> Bool:
  True{}

def lp_push_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_plp()), "ok"), Bool.and(U64.is_eq(Ty.brep_stamp(b_plp()), 1u64), Nat.is_eq(Ty.tres_n(Ty.lp_len(Ty.brep_lps(b_plp()), 8n)), 1n)))

def lp_push_ok__want() -> Bool:
  True{}

def lp_push_res__got() -> Bool:
  String.eq(Ty.tres_show(Ty.lp_resolve(Ty.brep_lps(b_plp()), Ty.mk_hlp(0n, 1u64), 8n)), "ok")

def lp_push_res__want() -> Bool:
  True{}

def lp_push_nil__got() -> Bool:
  String.eq(Ty.tres_show(Ty.lp_push(b_empty(), hce0(), Ty.LK_outer{})), "invalid-input")

def lp_push_nil__want() -> Bool:
  True{}

def fa_len2__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.fa_len(fas2(), 8n)), 2n)

def fa_len2__want() -> Bool:
  True{}

def fa_len0__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.fa_len(fas0(), 8n)), 0n)

def fa_len0__want() -> Bool:
  True{}

def fa_len_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_len(fas1(), 0n)), "resource-exhausted")

def fa_len_fuel__want() -> Bool:
  True{}

def fa_at_gen__got() -> Bool:
  U64.is_eq(Ty.fa_gen(v_at_fa()), 42u64)

def fa_at_gen__want() -> Bool:
  True{}

def fa_at_headfree__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_at(fas1(), 0n, 0n)), "ok")

def fa_at_headfree__want() -> Bool:
  True{}

def fa_at_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_at(fas1(), 5n, 8n)), "invalid-input")

def fa_at_oob__want() -> Bool:
  True{}

def fa_at_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_at(fas2(), 1n, 0n)), "resource-exhausted")

def fa_at_fuel__want() -> Bool:
  True{}

def fa_res_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_res_fa()), "ok"), U64.is_eq(Ty.fa_gen(v_res_fa()), 42u64))

def fa_res_ok__want() -> Bool:
  True{}

def fa_res_stale__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_resolve(fas1(), Ty.mk_hfa(0n, 99u64), 8n)), "invalid-input")

def fa_res_stale__want() -> Bool:
  True{}

def fa_res_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_resolve(fas1(), Ty.mk_hfa(5n, 41u64), 8n)), "invalid-input")

def fa_res_oob__want() -> Bool:
  True{}

def fa_res_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_resolve(fas2(), Ty.mk_hfa(1n, 42u64), 0n)), "resource-exhausted")

def fa_res_fuel__want() -> Bool:
  True{}

def fa_hof_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hfa_idx(h_hof_fa()), 1n), U64.is_eq(Ty.hfa_gen(h_hof_fa()), 42u64))

def fa_hof_idx__want() -> Bool:
  True{}

def fa_hof_unknown__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_handle_of(fas2(), 99u64, 8n)), "invalid-input")

def fa_hof_unknown__want() -> Bool:
  True{}

def fa_hof_empty__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_handle_of(fas0(), 41u64, 8n)), "invalid-input")

def fa_hof_empty__want() -> Bool:
  True{}

def fa_hof_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_handle_of(fas2(), 42u64, 0n)), "resource-exhausted")

def fa_hof_fuel__want() -> Bool:
  True{}

def fa_hof_head0__got() -> Bool:
  Nat.is_eq(Ty.hfa_idx(Ty.tres_hfa(Ty.fa_handle_of(fas1(), 41u64, 0n))), 0n)

def fa_hof_head0__want() -> Bool:
  True{}

def fa_iss_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hfa_idx(h_iss_fa()), 1n), U64.is_eq(Ty.hfa_gen(h_iss_fa()), 42u64))

def fa_iss_idx__want() -> Bool:
  True{}

def fa_iss_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_issued(b_fas1(), 0n)), "resource-exhausted")

def fa_iss_fuel__want() -> Bool:
  True{}

def fa_push_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_pfa()), "ok"), Bool.and(U64.is_eq(Ty.brep_stamp(b_pfa()), 1u64), Nat.is_eq(Ty.tres_n(Ty.fa_len(Ty.brep_fas(b_pfa()), 8n)), 1n)))

def fa_push_ok__want() -> Bool:
  True{}

def fa_push_res__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_resolve(Ty.brep_fas(b_pfa()), Ty.mk_hfa(0n, 1u64), 8n)), "ok")

def fa_push_res__want() -> Bool:
  True{}

def fa_push_arm__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_push(b_empty(), cv_ln(), hlp1(), True{})), "invalid-input")

def fa_push_arm__want() -> Bool:
  True{}

def fa_push_loops__got() -> Bool:
  String.eq(Ty.tres_show(Ty.fa_push(b_empty(), sf_pl(), hlp0(), True{})), "invalid-input")

def fa_push_loops__want() -> Bool:
  True{}

def sh_len2__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.sh_len(shs2(), 8n)), 2n)

def sh_len2__want() -> Bool:
  True{}

def sh_len0__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.sh_len(shs0(), 8n)), 0n)

def sh_len0__want() -> Bool:
  True{}

def sh_len_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.sh_len(shs1(), 0n)), "resource-exhausted")

def sh_len_fuel__want() -> Bool:
  True{}

def sh_at_gen__got() -> Bool:
  U64.is_eq(Ty.sh_gen(v_at_sh()), 52u64)

def sh_at_gen__want() -> Bool:
  True{}

def sh_at_headfree__got() -> Bool:
  String.eq(Ty.tres_show(Ty.sh_at(shs1(), 0n, 0n)), "ok")

def sh_at_headfree__want() -> Bool:
  True{}

def sh_at_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.sh_at(shs1(), 5n, 8n)), "invalid-input")

def sh_at_oob__want() -> Bool:
  True{}

def sh_at_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.sh_at(shs2(), 1n, 0n)), "resource-exhausted")

def sh_at_fuel__want() -> Bool:
  True{}

def sh_res_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_res_sh()), "ok"), U64.is_eq(Ty.sh_gen(v_res_sh()), 52u64))

def sh_res_ok__want() -> Bool:
  True{}

def sh_res_stale__got() -> Bool:
  String.eq(Ty.tres_show(Ty.sh_resolve(shs1(), Ty.mk_hsh(0n, 99u64), 8n)), "invalid-input")

def sh_res_stale__want() -> Bool:
  True{}

def sh_res_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.sh_resolve(shs1(), Ty.mk_hsh(5n, 51u64), 8n)), "invalid-input")

def sh_res_oob__want() -> Bool:
  True{}

def sh_res_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.sh_resolve(shs2(), Ty.mk_hsh(1n, 52u64), 0n)), "resource-exhausted")

def sh_res_fuel__want() -> Bool:
  True{}

def sh_hof_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hsh_idx(h_hof_sh()), 1n), U64.is_eq(Ty.hsh_gen(h_hof_sh()), 52u64))

def sh_hof_idx__want() -> Bool:
  True{}

def sh_hof_unknown__got() -> Bool:
  String.eq(Ty.tres_show(Ty.sh_handle_of(shs2(), 99u64, 8n)), "invalid-input")

def sh_hof_unknown__want() -> Bool:
  True{}

def sh_hof_empty__got() -> Bool:
  String.eq(Ty.tres_show(Ty.sh_handle_of(shs0(), 51u64, 8n)), "invalid-input")

def sh_hof_empty__want() -> Bool:
  True{}

def sh_hof_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.sh_handle_of(shs2(), 52u64, 0n)), "resource-exhausted")

def sh_hof_fuel__want() -> Bool:
  True{}

def sh_hof_head0__got() -> Bool:
  Nat.is_eq(Ty.hsh_idx(Ty.tres_hsh(Ty.sh_handle_of(shs1(), 51u64, 0n))), 0n)

def sh_hof_head0__want() -> Bool:
  True{}

def sh_iss_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hsh_idx(h_iss_sh()), 1n), U64.is_eq(Ty.hsh_gen(h_iss_sh()), 52u64))

def sh_iss_idx__want() -> Bool:
  True{}

def sh_iss_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.sh_issued(b_shs1(), 0n)), "resource-exhausted")

def sh_iss_fuel__want() -> Bool:
  True{}

def sh_push_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_psh()), "ok"), Bool.and(U64.is_eq(Ty.brep_stamp(b_psh()), 1u64), Nat.is_eq(Ty.tres_n(Ty.sh_len(Ty.brep_shs(b_psh()), 8n)), 1n)))

def sh_push_ok__want() -> Bool:
  True{}

def sh_push_res__got() -> Bool:
  String.eq(Ty.tres_show(Ty.sh_resolve(Ty.brep_shs(b_psh()), Ty.mk_hsh(0n, 1u64), 8n)), "ok")

def sh_push_res__want() -> Bool:
  True{}

def sh_push_nil__got() -> Bool:
  String.eq(Ty.tres_show(Ty.sh_push(b_empty(), hfa0(), Ty.SK_outer{})), "invalid-input")

def sh_push_nil__want() -> Bool:
  True{}

def so_len2__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.so_len(sos2(), 8n)), 2n)

def so_len2__want() -> Bool:
  True{}

def so_len0__got() -> Bool:
  Nat.is_eq(Ty.tres_n(Ty.so_len(sos0(), 8n)), 0n)

def so_len0__want() -> Bool:
  True{}

def so_len_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.so_len(sos1(), 0n)), "resource-exhausted")

def so_len_fuel__want() -> Bool:
  True{}

def so_at_gen__got() -> Bool:
  U64.is_eq(Ty.so_gen(v_at_so()), 62u64)

def so_at_gen__want() -> Bool:
  True{}

def so_at_headfree__got() -> Bool:
  String.eq(Ty.tres_show(Ty.so_at(sos1(), 0n, 0n)), "ok")

def so_at_headfree__want() -> Bool:
  True{}

def so_at_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.so_at(sos1(), 5n, 8n)), "invalid-input")

def so_at_oob__want() -> Bool:
  True{}

def so_at_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.so_at(sos2(), 1n, 0n)), "resource-exhausted")

def so_at_fuel__want() -> Bool:
  True{}

def so_res_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_res_so()), "ok"), U64.is_eq(Ty.so_gen(v_res_so()), 62u64))

def so_res_ok__want() -> Bool:
  True{}

def so_res_stale__got() -> Bool:
  String.eq(Ty.tres_show(Ty.so_resolve(sos1(), Ty.mk_hso(0n, 99u64), 8n)), "invalid-input")

def so_res_stale__want() -> Bool:
  True{}

def so_res_oob__got() -> Bool:
  String.eq(Ty.tres_show(Ty.so_resolve(sos1(), Ty.mk_hso(5n, 61u64), 8n)), "invalid-input")

def so_res_oob__want() -> Bool:
  True{}

def so_res_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.so_resolve(sos2(), Ty.mk_hso(1n, 62u64), 0n)), "resource-exhausted")

def so_res_fuel__want() -> Bool:
  True{}

def so_hof_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hso_idx(h_hof_so()), 1n), U64.is_eq(Ty.hso_gen(h_hof_so()), 62u64))

def so_hof_idx__want() -> Bool:
  True{}

def so_hof_unknown__got() -> Bool:
  String.eq(Ty.tres_show(Ty.so_handle_of(sos2(), 99u64, 8n)), "invalid-input")

def so_hof_unknown__want() -> Bool:
  True{}

def so_hof_empty__got() -> Bool:
  String.eq(Ty.tres_show(Ty.so_handle_of(sos0(), 61u64, 8n)), "invalid-input")

def so_hof_empty__want() -> Bool:
  True{}

def so_hof_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.so_handle_of(sos2(), 62u64, 0n)), "resource-exhausted")

def so_hof_fuel__want() -> Bool:
  True{}

def so_hof_head0__got() -> Bool:
  Nat.is_eq(Ty.hso_idx(Ty.tres_hso(Ty.so_handle_of(sos1(), 61u64, 0n))), 0n)

def so_hof_head0__want() -> Bool:
  True{}

def so_iss_idx__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.hso_idx(h_iss_so()), 1n), U64.is_eq(Ty.hso_gen(h_iss_so()), 62u64))

def so_iss_idx__want() -> Bool:
  True{}

def so_iss_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Ty.so_issued(b_sos1(), 0n)), "resource-exhausted")

def so_iss_fuel__want() -> Bool:
  True{}

def so_push_ok__got() -> Bool:
  Bool.and(String.eq(Ty.tres_show(r_pso()), "ok"), Bool.and(U64.is_eq(Ty.brep_stamp(b_pso()), 1u64), Nat.is_eq(Ty.tres_n(Ty.so_len(Ty.brep_sos(b_pso()), 8n)), 1n)))

def so_push_ok__want() -> Bool:
  True{}

def so_push_res__got() -> Bool:
  String.eq(Ty.tres_show(Ty.so_resolve(Ty.brep_sos(b_pso()), Ty.mk_hso(0n, 1u64), 8n)), "ok")

def so_push_res__want() -> Bool:
  True{}

def so_push_cav__got() -> Bool:
  Ty.so_has_cav(Ty.tres_so(Ty.so_at(Ty.brep_sos(Ty.tres_brep( Ty.so_push(b_empty(), hsh_a(), hsh1()))), 0n, 8n)))

def so_push_cav__want() -> Bool:
  True{}

def hsh_nd_empty__got() -> Bool:
  Nat.is_eq(Op.hsh_nodup_c(hsh0(), 8n), 3n)

def hsh_nd_empty__want() -> Bool:
  True{}

def hsh_nd_single__got() -> Bool:
  Nat.is_eq(Op.hsh_nodup_c(hsh1(), 8n), 3n)

def hsh_nd_single__want() -> Bool:
  True{}

def hsh_nd_dup__got() -> Bool:
  Nat.is_eq(Op.hsh_nodup_c(hsh_a() <> hsh_a() <> Nil{}, 8n), 2n)

def hsh_nd_dup__want() -> Bool:
  True{}

def hsh_nd_fuel__got() -> Bool:
  Nat.is_eq(Op.hsh_nodup_c(hsh1(), 0n), 0n)

def hsh_nd_fuel__want() -> Bool:
  True{}

def hsh_fo_absent__got() -> Bool:
  Nat.is_eq(Op.hsh_nodup_c(hsh_a() <> Ty.mk_hsh(1n, 52u64) <> Nil{}, 8n), 3n)

def hsh_fo_absent__want() -> Bool:
  True{}

def hsh_fo_hit__got() -> Bool:
  Nat.is_eq(Op.hsh_nodup_c(hsh_a() <> hsh1(), 8n), 2n)

def hsh_fo_hit__want() -> Bool:
  True{}

def so_shl_single__got() -> Bool:
  Nat.is_eq(Op.hsh_nodup_c(Op.so_sh_list(so_a()), 8n), 3n)

def so_shl_single__want() -> Bool:
  True{}

def so_shl_alias__got() -> Bool:
  Nat.is_eq(Op.hsh_nodup_c(Op.so_sh_list(so_b()), 8n), 2n)

def so_shl_alias__want() -> Bool:
  True{}

def outer_kind_ok__got() -> Bool:
  Nat.is_eq(Op.sos_outer_kind_c(sos1(), shs1(), 8n, 8n), 3n)

def outer_kind_ok__want() -> Bool:
  True{}

def outer_kind_bad__got() -> Bool:
  Nat.is_eq(Op.sos_outer_kind_c( Ty.So{61u64, Ty.mk_hsh(1n, 52u64), hsh0()} <> Nil{}, shs2(), 8n, 8n), 2n)

def outer_kind_bad__want() -> Bool:
  True{}

def outer_kind_fuel__got() -> Bool:
  Nat.is_eq(Op.sos_outer_kind_c(sos1(), shs1(), 0n, 8n), 0n)

def outer_kind_fuel__want() -> Bool:
  True{}

def own_single_ok__got() -> Bool:
  Nat.is_eq(Op.sos_own_c(sos1(), 8n, 8n), 3n)

def own_single_ok__want() -> Bool:
  True{}

def own_alias_no__got() -> Bool:
  Nat.is_eq(Op.sos_own_c(so_b() <> Nil{}, 8n, 8n), 2n)

def own_alias_no__want() -> Bool:
  True{}

def own_reuse_no__got() -> Bool:
  Nat.is_eq(Op.sos_own_c(so_a() <> so_a() <> Nil{}, 8n, 8n), 2n)

def own_reuse_no__want() -> Bool:
  True{}

def own_fuel__got() -> Bool:
  Nat.is_eq(Op.sos_own_c(sos1(), 0n, 8n), 0n)

def own_fuel__want() -> Bool:
  True{}

def cpown_disjoint_ok__got() -> Bool:
  Nat.is_eq(Op.cp_sh_own_c(top0(), sos1(), 8n), 3n)

def cpown_disjoint_ok__want() -> Bool:
  True{}

def cpown_share_no__got() -> Bool:
  Nat.is_eq(Op.cp_sh_own_c(Ty.Cp{hso0(), hsh1()}, sos1(), 8n), 2n)

def cpown_share_no__want() -> Bool:
  True{}

def cpown_dup_no__got() -> Bool:
  Nat.is_eq(Op.cp_sh_own_c( Ty.Cp{hso0(), hsh_a() <> hsh_a() <> Nil{}}, sos0(), 8n), 2n)

def cpown_dup_no__want() -> Bool:
  True{}

def hlf_absent__got() -> Bool:
  Op.hks_distinct(Op.hss_keys(Ty.mk_hsh(1n, 52u64) <> Nil{}, Op.hss_keys(hsh1(), Nil{})))

def hlf_absent__want() -> Bool:
  True{}

def hlf_hit__got() -> Bool:
  Op.hks_distinct(Op.hss_keys(hsh1(), Op.hss_keys(hsh1(), Nil{})))

def hlf_hit__want() -> Bool:
  False{}

def hfos_absent__got() -> Bool:
  Op.hks_distinct(Op.hss_keys(hsh0(), Op.hks_sorted_uniq(Op.sos_skeys(sos1(), Nil{}))))

def hfos_absent__want() -> Bool:
  True{}

def hfos_hit__got() -> Bool:
  Op.hks_distinct(Op.hss_keys(hsh1(), Op.hks_sorted_uniq(Op.sos_skeys(sos1(), Nil{}))))

def hfos_hit__want() -> Bool:
  False{}

def ck_sphere__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_sphere_digon_control(), Ty.P_manifold_solid{}, 12n)), "ok")

def ck_sphere__want() -> Bool:
  True{}

def ck_cyl__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_cyl_digon_ruling_control(), Ty.P_manifold_solid{}, 12n)), "ok")

def ck_cyl__want() -> Bool:
  True{}

def ck_cav__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_cav(), Ty.P_manifold_solid{}, 20n)), "ok")

def ck_cav__want() -> Bool:
  True{}

def ck_open__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_open(), Ty.P_open_shell{}, 12n)), "ok")

def ck_open__want() -> Bool:
  True{}

def ck_pole__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_pole(), Ty.P_manifold_solid{}, 12n)), "ok")

def ck_pole__want() -> Bool:
  True{}

def ck_dang__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_dang(), Ty.P_manifold_solid{}, 12n)), "invalid-input")

def ck_dang__want() -> Bool:
  True{}

def ck_inv__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_inv(), Ty.P_manifold_solid{}, 12n)), "invalid-input")

def ck_inv__want() -> Bool:
  True{}

def ck_trimx__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_trimx(), Ty.P_manifold_solid{}, 12n)), "invalid-input")

def ck_trimx__want() -> Bool:
  True{}

def ck_embx__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_embx(), Ty.P_manifold_solid{}, 12n)), "invalid-input")

def ck_embx__want() -> Bool:
  True{}

def ck_nonm__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_nonm(), Ty.P_manifold_solid{}, 12n)), "invalid-input")

def ck_nonm__want() -> Bool:
  True{}

def ck_selfx__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_selfx(), Ty.P_manifold_solid{}, 12n)), "invalid-input")

def ck_selfx__want() -> Bool:
  True{}

def ck_open_solid__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_open(), Ty.P_manifold_solid{}, 12n)), "invalid-input")

def ck_open_solid__want() -> Bool:
  True{}

def ck_fuel__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_sphere_digon_control(), Ty.P_manifold_solid{}, 0n)), "resource-exhausted")

def ck_fuel__want() -> Bool:
  True{}

def ck_fuel_ix__got() -> Bool:
  Bool.and(Nat.is_eq(Ty.ix_bound(b_fuel_gap()), 2n), Bool.and(Nat.is_eq(Ty.ix_bound(b_sphere_digon_control()), 2n), Bool.and(String.eq(Ty.tres_show(Ty.mk_brep(Ty.brep_vs(b_fuel_gap()), Ty.brep_es(b_fuel_gap()), Ty.brep_ces(b_fuel_gap()), Ty.brep_lps(b_fuel_gap()), Ty.brep_fas(b_fuel_gap()), Ty.brep_shs(b_fuel_gap()), Ty.brep_sos(b_fuel_gap()), Ty.brep_top(b_fuel_gap()), Ty.brep_stamp(b_fuel_gap()), 1n)), "invalid-input"), Bool.and(String.eq(Ty.tres_show(Op.brep_checked(b_fuel_gap(), Ty.P_manifold_solid{}, 1n)), "resource-exhausted"), Bool.and(Bool.not(String.eq(Ty.tres_show(Op.brep_checked(b_fuel_gap(), Ty.P_manifold_solid{}, 1n)), "ok")), Bool.and(String.eq(Ty.tres_show(Op.brep_checked(b_fuel_gap(), Ty.P_manifold_solid{}, 2n)), "invalid-input"), Bool.and(String.eq(Ty.tres_show(Op.brep_checked( b_sphere_digon_control(), Ty.P_manifold_solid{}, 2n)), "ok"), String.eq(Ty.tres_show(Op.brep_checked(b_sphere_digon_control(), Ty.P_manifold_solid{}, 1n)), "resource-exhausted"))))))))

def ck_fuel_ix__want() -> Bool:
  True{}

def ck_stage_fuel__got() -> Bool:
  Bool.and(Nat.is_eq(Op.brep_incid_c(b_fuel_gap(), 1n), 0n), Bool.and(Nat.is_eq(Op.brep_orient_c(b_fuel_gap(), 1n), 0n), Bool.and(Nat.is_eq(Op.brep_incid_c(b_sphere_digon_control(), 1n), 0n), Bool.and(Nat.is_eq(Op.brep_orient_c(b_sphere_digon_control(), 1n), 0n), Bool.and(Nat.is_eq(Op.brep_orient_cert_c(b_sphere_digon_control(), 1n), 0n), Bool.and(Nat.is_eq(Op.brep_incid_c(b_sphere_digon_control(), 2n), 3n), Bool.and(Nat.is_eq(Op.brep_orient_c(b_sphere_digon_control(), 2n), 3n), Nat.is_eq(Op.brep_orient_cert_c(b_sphere_digon_control(), 2n), 1n))))))))

def ck_stage_fuel__want() -> Bool:
  True{}

def ck_alias__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_alias(), Ty.P_manifold_solid{}, 12n)), "invalid-input")

def ck_alias__want() -> Bool:
  True{}

def ck_outerkind__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_outerkind(), Ty.P_manifold_solid{}, 12n)), "invalid-input")

def ck_outerkind__want() -> Bool:
  True{}

def ck_cavdup__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_cavdup(), Ty.P_manifold_solid{}, 20n)), "invalid-input")

def ck_cavdup__want() -> Bool:
  True{}

def ck_reuse__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_reuse(), Ty.P_manifold_solid{}, 12n)), "invalid-input")

def ck_reuse__want() -> Bool:
  True{}

def ck_cpshare__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_cpshare(), Ty.P_manifold_solid{}, 12n)), "invalid-input")

def ck_cpshare__want() -> Bool:
  True{}

def ck_pinch__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_pinch(), Ty.P_manifold_solid{}, 20n)), "invalid-input")

def ck_pinch__want() -> Bool:
  True{}

def qmem_spon__got() -> Bool:
  Op.vx_surf_on(ix_vs(vs_q()), Ty.mk_hv(0n, 1u64), sf_sp())

def qmem_spon__want() -> Bool:
  True{}

def qmem_cyon__got() -> Bool:
  Op.vx_surf_on(ix_vs(vs_q()), Ty.mk_hv(0n, 1u64), sf_cy())

def qmem_cyon__want() -> Bool:
  True{}

def qmem_con__got() -> Bool:
  Op.vx_surf_on(ix_vs(vs_q()), Ty.mk_hv(0n, 1u64), sf_co())

def qmem_con__want() -> Bool:
  True{}

def qmem_toon__got() -> Bool:
  Op.vx_surf_on(ix_vs(vs_q()), Ty.mk_hv(2n, 3u64), sf_to())

def qmem_toon__want() -> Bool:
  True{}

def ck_offquad__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_offquad(), Ty.P_manifold_solid{}, 12n)), "invalid-input")

def ck_offquad__want() -> Bool:
  True{}

def ck_split__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_split(), Ty.P_manifold_solid{}, 20n)), "invalid-input")

def ck_split__want() -> Bool:
  True{}

def coin_sphere__got() -> Nat:
  Op.brep_coin_c(b_sphere_digon_control(), 12n)

def coin_sphere__want() -> Nat:
  3n

def coin_dup__got() -> Nat:
  Op.brep_coin_c(b_coin(), 12n)

def coin_dup__want() -> Nat:
  2n

def coin_fuel__got() -> Bool:
  Ty.okd_done(Op.brep_coin_c(b_sphere_digon_control(), 0n))

def coin_fuel__want() -> Bool:
  False{}

def link_sq__got() -> Nat:
  Op.vx_link_ok(b_oriprop(), Ty.mk_hv(0n, 1u64), 20n)

def link_sq__want() -> Nat:
  3n

def link_pinch__got() -> Nat:
  Op.vx_link_ok(b_pinch(), Ty.mk_hv(0n, 1u64), 20n)

def link_pinch__want() -> Nat:
  2n

def segx_cross__got() -> Bool:
  Op.segx_pair(p000(), p110(), p100(), p010())

def segx_cross__want() -> Bool:
  True{}

def segx_clean__got() -> Bool:
  Op.segx_pair(p000(), p100(), p110(), p010())

def segx_clean__want() -> Bool:
  False{}

def xing_clean__got() -> Nat:
  Op.brep_xing_c(b_oriprop(), 20n)

def xing_clean__want() -> Nat:
  3n

def xing_hit__got() -> Nat:
  Op.brep_xing_c(b_xing(), 20n)

def xing_hit__want() -> Nat:
  2n

def orient_sq__got() -> Nat:
  Op.brep_orient_c(b_oriprop(), 20n)

def orient_sq__want() -> Nat:
  3n

def orient_invface__got() -> Nat:
  Op.brep_orient_c(b_invface(), 20n)

def orient_invface__want() -> Nat:
  2n

def orient_hole__got() -> Nat:
  Op.brep_orient_c(b_hole(), 20n)

def orient_hole__want() -> Nat:
  3n

def orient_hole_bad__got() -> Nat:
  Op.brep_orient_c(b_hole_bad(), 20n)

def orient_hole_bad__want() -> Nat:
  2n

def orient_hole_bad2__got() -> Nat:
  Op.brep_orient_c(b_hole_bad2(), 20n)

def orient_hole_bad2__want() -> Nat:
  2n

def orient_diffparam__got() -> Nat:
  Op.brep_orient_c(b_diffparam(), 20n)

def orient_diffparam__want() -> Nat:
  3n

def recheck_sphere__got() -> Nat:
  Op.brep_recheck_c(b_sphere_digon_control(), 12n)

def recheck_sphere__want() -> Nat:
  3n

def recheck_oriprop__got() -> Nat:
  Op.brep_recheck_c(b_oriprop(), 20n)

def recheck_oriprop__want() -> Nat:
  3n

def recheck_invface__got() -> Nat:
  Op.brep_recheck_c(b_invface(), 20n)

def recheck_invface__want() -> Nat:
  2n

def recheck_diffparam__got() -> Nat:
  Op.brep_recheck_c(b_diffparam(), 20n)

def recheck_diffparam__want() -> Nat:
  3n

def recheck_hole__got() -> Nat:
  Op.brep_recheck_c(b_hole(), 20n)

def recheck_hole__want() -> Nat:
  3n

def cert_oriprop__got() -> Nat:
  Op.cnt_count(Op.brep_orient_cert_c(b_oriprop(), 20n))

def cert_oriprop__want() -> Nat:
  2n

def skip_oriprop__got() -> Nat:
  Op.cnt_count(Op.brep_orient_skip_c(b_oriprop(), 20n))

def skip_oriprop__want() -> Nat:
  0n

def cert_invface__got() -> Nat:
  Op.cnt_count(Op.brep_orient_cert_c(b_invface(), 20n))

def cert_invface__want() -> Nat:
  2n

def cert_sphere__got() -> Nat:
  Op.cnt_count(Op.brep_orient_cert_c(b_sphere_digon_control(), 12n))

def cert_sphere__want() -> Nat:
  0n

def skip_sphere__got() -> Nat:
  Op.cnt_count(Op.brep_orient_skip_c(b_sphere_digon_control(), 12n))

def skip_sphere__want() -> Nat:
  1n

def cert_hole__got() -> Nat:
  Op.cnt_count(Op.brep_orient_cert_c(b_hole(), 20n))

def cert_hole__want() -> Nat:
  2n

def skip_hole__got() -> Nat:
  Op.cnt_count(Op.brep_orient_skip_c(b_hole(), 20n))

def skip_hole__want() -> Nat:
  0n

def bezp_z00pos__got() -> Bool:
  F64.is_lt(0.0f64, V.dr_z(G.gres_d(Op.bezp_normal_at(bp0(), 0.0f64, 0.0f64))))

def bezp_z00pos__want() -> Bool:
  True{}

def bezp_z11neg__got() -> Bool:
  F64.is_lt(V.dr_z(G.gres_d(Op.bezp_normal_at(bp0(), 1.0f64, 1.0f64))), 0.0f64)

def bezp_z11neg__want() -> Bool:
  True{}

def ck_coin__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_coin(), Ty.P_manifold_solid{}, 12n)), "invalid-input")

def ck_coin__want() -> Bool:
  True{}

def ck_xing__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_xing(), Ty.P_manifold_solid{}, 20n)), "invalid-input")

def ck_xing__want() -> Bool:
  True{}

def ck_invface__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_invface(), Ty.P_manifold_solid{}, 20n)), "invalid-input")

def ck_invface__want() -> Bool:
  True{}

def ck_oriprop_ok__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_oriprop(), Ty.P_manifold_solid{}, 20n)), "ok")

def ck_oriprop_ok__want() -> Bool:
  True{}

def ck_split_open__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_split(), Ty.P_open_shell{}, 20n)), "invalid-input")

def ck_split_open__want() -> Bool:
  True{}

def ck_hole_bad__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_hole_bad(), Ty.P_open_shell{}, 20n)), "invalid-input")

def ck_hole_bad__want() -> Bool:
  True{}

def ck_hole_bad2__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_hole_bad2(), Ty.P_open_shell{}, 20n)), "invalid-input")

def ck_hole_bad2__want() -> Bool:
  True{}

def ck_hole_ok__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_hole(), Ty.P_open_shell{}, 20n)), "ok")

def ck_hole_ok__want() -> Bool:
  True{}

def ck_diffparam_ok__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_diffparam(), Ty.P_manifold_solid{}, 20n)), "ok")

def ck_diffparam_ok__want() -> Bool:
  True{}

def ck_cyl_side__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_cyl_side(), Ty.P_manifold_solid{}, 20n)), "ok")

def ck_cyl_side__want() -> Bool:
  True{}

def ck_sphere_curved__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_sphere_curved(), Ty.P_manifold_solid{}, 20n)), "ok")

def ck_sphere_curved__want() -> Bool:
  True{}

def xing_defg__got() -> Bool:
  Bool.and(Nat.is_eq(Op.brep_loop_c(b_xing(), 20n), 3n), Bool.and(Nat.is_eq(Op.brep_facekind_c(b_xing(), 20n), 3n), Bool.and(Nat.is_eq(Op.brep_prof_c(b_xing(), Ty.P_manifold_solid{}, 20n), 3n), Nat.is_eq(Op.brep_embed_c(b_xing(), 20n), 3n))))

def xing_defg__want() -> Bool:
  True{}

def xing_hijk__got() -> Bool:
  Bool.and(Nat.is_eq(Op.brep_link_c(b_xing(), Ty.P_manifold_solid{}, 20n), 3n), Bool.and(Nat.is_eq(Op.brep_conn_c(b_xing(), 20n), 3n), Bool.and(Nat.is_eq(Op.brep_coin_c(b_xing(), 20n), 3n), Nat.is_eq(Op.brep_xing_c(b_xing(), 20n), 2n))))

def xing_hijk__want() -> Bool:
  True{}

def selfx_dup__got() -> Bool:
  Bool.and(Nat.is_eq(Op.brep_loop_c(b_selfx(), 12n), 2n), Nat.is_eq(Op.brep_embed_c(b_selfx(), 12n), 3n))

def selfx_dup__want() -> Bool:
  True{}

def l1_seam_use_same__got() -> Bool:
  Op.use_ok(l1_b_ec(l1_es_line(), l1_ces_same()), Ty.P_manifold_solid{})

def l1_seam_use_same__want() -> Bool:
  False{}

def l1_outer_one__got() -> Nat:
  Op.hls_outer(l1_hl0() <> Nil{}, l1_ixl(l1_lps_outer()))

def l1_outer_one__want() -> Nat:
  1n

def l1_outer_two__got() -> Nat:
  Op.hls_outer(l1_hl0() <> l1_hl1() <> Nil{}, l1_ixl(l1_lps_twoouter()))

def l1_outer_two__want() -> Nat:
  2n

def l1_outer_zero__got() -> Nat:
  Op.hls_outer(l1_hl0() <> Nil{}, l1_ixl(l1_lps_inner()))

def l1_outer_zero__want() -> Nat:
  0n

def l1_noopen_open__got() -> Nat:
  Op.shs_no_open_c(Ty.Sh{1u64, Nil{}, Ty.SK_open{}} <> Nil{}, 1n)

def l1_noopen_open__want() -> Nat:
  2n

def l1_noopen_outer__got() -> Nat:
  Op.shs_no_open_c(Ty.Sh{1u64, Nil{}, Ty.SK_outer{}} <> Nil{}, 1n)

def l1_noopen_outer__want() -> Nat:
  3n

def l1_closure_vmiss__got() -> Bool:
  Op.loop_rest_go(Nil{}, l1_ix(Nil{}, Nil{}), l1_v0(), l1_v1(), l1_uva(), l1_uva())

def l1_closure_vmiss__want() -> Bool:
  False{}

def l1_closure_tmiss__got() -> Bool:
  Op.loop_rest_go(Nil{}, l1_ix(Nil{}, Nil{}), l1_v0(), l1_v0(), l1_uva(), l1_uvb())

def l1_closure_tmiss__want() -> Bool:
  False{}

def l1_chain_ok__got() -> Bool:
  Op.loop_rest_go(l1_hc1() <> Nil{}, l1_ix(l1_es_chain(), l1_ces_chain(False{})), l1_v1(), l1_v0(), l1_uvb(), l1_uva())

def l1_chain_ok__want() -> Bool:
  True{}

def l1_chain_gap__got() -> Bool:
  Op.loop_rest_go(l1_hc1() <> Nil{}, l1_ix(l1_es_chain(), l1_ces_chain(True{})), l1_v1(), l1_v0(), l1_uvb(), l1_uva())

def l1_chain_gap__want() -> Bool:
  False{}

def l1_nodup_dup__got() -> Nat:
  Op.hc_nodup_c(l1_hc0() <> l1_hc0() <> Nil{}, 3n)

def l1_nodup_dup__want() -> Nat:
  2n

def l1_nodup_distinct__got() -> Nat:
  Op.hc_nodup_c(l1_hc0() <> l1_hc1() <> Nil{}, 3n)

def l1_nodup_distinct__want() -> Nat:
  3n

def l1_seam_same__got() -> Bool:
  Op.loop_seam_ok(l1_hc0() <> l1_hc1() <> Nil{}, l1_ix(l1_es_line(), l1_ces_same()))

def l1_seam_same__want() -> Bool:
  False{}

def l1_seam_skip__got() -> Bool:
  Op.loop_seam_ok(l1_hc0() <> l1_hc1() <> Nil{}, l1_ix(l1_es_pair(), l1_ces_distinct()))

def l1_seam_skip__want() -> Bool:
  True{}

def l1_pole_single__got() -> Bool:
  Op.loop_pole_ok(l1_hc0() <> Nil{}, l1_ix(l1_es_degen(), l1_ces_one()))

def l1_pole_single__want() -> Bool:
  True{}

def l1_pole_two__got() -> Bool:
  Op.loop_pole_ok(l1_hc0() <> l1_hc1() <> Nil{}, l1_ix(l1_es_degen(), l1_ces_seam(True{})))

def l1_pole_two__want() -> Bool:
  False{}

def l1_pole_clean__got() -> Bool:
  Op.loop_pole_ok(l1_hc0() <> Nil{}, l1_ix(l1_es_line(), l1_ces_one()))

def l1_pole_clean__want() -> Bool:
  True{}

def l1_mem_nil__got() -> Bool:
  Op.khas(Op.ktb(Nil{}), Op.hc_key(l1_hc0()))

def l1_mem_nil__want() -> Bool:
  False{}

def l1_mem_hit__got() -> Bool:
  Op.khas(Op.ktb(Op.hcs_keys(l1_hc0() <> Nil{}, Nil{})), Op.hc_key(l1_hc0()))

def l1_mem_hit__want() -> Bool:
  True{}

def l1_mem_miss__got() -> Bool:
  Op.khas(Op.ktb(Op.hcs_keys(l1_hc0() <> Nil{}, Nil{})), Op.hc_key(l1_hc1()))

def l1_mem_miss__want() -> Bool:
  False{}

def l1_prev_nil__got() -> Ty.HCoedge:
  Op.hm_prev(Op.hmap_of(l1_b_step()), Ty.mk_hc(5n, 99u64))

def l1_prev_nil__want() -> Ty.HCoedge:
  Ty.mk_hc(5n, 99u64)

def l1_prev_mid__got() -> Ty.HCoedge:
  Op.hm_prev(Op.hmap_of(l1_b_step()), l1_hc1())

def l1_prev_mid__want() -> Ty.HCoedge:
  l1_hc0()

def l1_prev_wrap__got() -> Ty.HCoedge:
  Op.hm_prev(Op.hmap_of(l1_b_step()), l1_hc0())

def l1_prev_wrap__want() -> Ty.HCoedge:
  l1_hc1()

def l1_prev_single__got() -> Ty.HCoedge:
  Op.hm_prev(Op.hmap_of(l1_b_single()), l1_hc0())

def l1_prev_single__want() -> Ty.HCoedge:
  l1_hc0()

def l1_hcprev_nil__got() -> Ty.HCoedge:
  Op.hm_prev(Op.hmap_of(l1_b_ec(Nil{}, Nil{})), l1_hc0())

def l1_hcprev_nil__want() -> Ty.HCoedge:
  l1_hc0()

def l1_twin_nil__got() -> Ty.HCoedge:
  Op.hm_twin(Op.hmap_of(l1_b_split()), Ty.ix_of(l1_b_split()), l1_hc0())

def l1_twin_nil__want() -> Ty.HCoedge:
  l1_hc0()

def l1_twin_first__got() -> Ty.HCoedge:
  Op.hm_twin(Op.hmap_of(l1_b_share()), Ty.ix_of(l1_b_share()), l1_hc0())

def l1_twin_first__want() -> Ty.HCoedge:
  l1_hc1()

def l1_twin_second__got() -> Ty.HCoedge:
  Op.hm_twin(Op.hmap_of(l1_b_share()), Ty.ix_of(l1_b_share()), l1_hc1())

def l1_twin_second__want() -> Ty.HCoedge:
  l1_hc0()

def l1_twin_miss__got() -> Ty.HCoedge:
  Op.hm_twin(Op.hmap_of(l1_b_single()), Ty.ix_of(l1_b_single()), l1_hc0())

def l1_twin_miss__want() -> Ty.HCoedge:
  l1_hc0()

def l1_step__got() -> Ty.HCoedge:
  Op.hm_step(Op.hmap_of(l1_b_step()), Ty.ix_of(l1_b_step()), l1_hc1())

def l1_step__want() -> Ty.HCoedge:
  l1_hc1()

def l1_nondegen_curve__got() -> Bool:
  Op.hc_nondegen(l1_ix(l1_es_line(), l1_ces_seam(True{})), l1_hc0())

def l1_nondegen_curve__want() -> Bool:
  True{}

def l1_nondegen_degen__got() -> Bool:
  Op.hc_nondegen(l1_ix(l1_es_degen(), l1_ces_one()), l1_hc0())

def l1_nondegen_degen__want() -> Bool:
  False{}

def l1_orbit_tail__got() -> Bool:
  Op.orb_cyc(l1_orb_rho(), l1_rho_id(l1_rho_x()))

def l1_orbit_tail__want() -> Bool:
  False{}

def l1_orbit_cycle__got() -> Bool:
  Op.orb_cyc(l1_orb_rho(), l1_rho_id(l1_hc0()))

def l1_orbit_cycle__want() -> Bool:
  True{}

def l1_orbit_tail_step__got() -> U32:
  Op.orb_nx(l1_orb_rho(), l1_rho_id(l1_rho_x()))

def l1_orbit_tail_step__want() -> U32:
  l1_rho_id(l1_hc0())

def l1_vxlink_rho__got() -> Nat:
  Op.vx_link_ok(l1_b_rho(), l1_v2(), 20n)

def l1_vxlink_rho__want() -> Nat:
  2n

def l1_vxlink_fuel0__got() -> Nat:
  Op.vx_link_ok(b_oriprop(), Ty.mk_hv(0n, 1u64), 0n)

def l1_vxlink_fuel0__want() -> Nat:
  0n

def l1_have_hit__got() -> List<&2, Op.EP>:
  Op.hcs_ekeys(l1_hc0() <> Nil{}, l1_ix(l1_es_line(), l1_ces_seam(True{})), 0, Nil{})

def l1_have_hit__want() -> List<&2, Op.EP>:
  Op.EP{Op.he_key(l1_he0()), 0} <> Nil{}

def l1_have_miss__got() -> List<&2, Op.EP>:
  Op.hcs_ekeys(l1_hc1() <> Nil{}, l1_ix(l1_es_pair(), l1_ces_distinct()), 0, Nil{})

def l1_have_miss__want() -> List<&2, Op.EP>:
  Op.EP{Op.he_key(l1_he1()), 0} <> Nil{}

def l1_share_pos__got() -> List<&2, B.Ed>:
  Op.sh_adj(l1_hf0() <> l1_hf1() <> Nil{}, Ty.ix_of(l1_b_share()))

def l1_share_pos__want() -> List<&2, B.Ed>:
  B.Ed{0, 1} <> Nil{}

def l1_share_neg__got() -> List<&2, B.Ed>:
  Op.sh_adj(l1_hf0() <> l1_hf1() <> Nil{}, Ty.ix_of(l1_b_split()))

def l1_share_neg__want() -> List<&2, B.Ed>:
  Nil{}

def l1_faces_share__got() -> Bool:
  Op.shs_conn_ok(l1_shs_pair(), Ty.ix_of(l1_b_share()))

def l1_faces_share__want() -> Bool:
  True{}

def l1_faces_split__got() -> Bool:
  Op.shs_conn_ok(l1_shs_pair(), Ty.ix_of(l1_b_split()))

def l1_faces_split__want() -> Bool:
  False{}

def l1_conn__got() -> Bool:
  Op.sh_conn_ok(l1_hf0() <> l1_hf1() <> Nil{}, Ty.ix_of(l1_b_share()))

def l1_conn__want() -> Bool:
  True{}

def l1_conn_split__got() -> Bool:
  Op.sh_conn_ok(l1_hf0() <> l1_hf1() <> Nil{}, Ty.ix_of(l1_b_split()))

def l1_conn_split__want() -> Bool:
  False{}

def l1_conn_dup_face__got() -> Bool:
  Op.sh_conn_ok(l1_hf0() <> l1_hf0() <> Nil{}, Ty.ix_of(l1_b_share()))

def l1_conn_dup_face__want() -> Bool:
  False{}

def l1_ekind_degen__got() -> Bool:
  Op.ekind_is_line(Ty.EK_degenerate{})

def l1_ekind_degen__want() -> Bool:
  False{}

def l1_lines_pos__got() -> Bool:
  Op.hcs_all_lines(l1_hc0() <> Nil{}, l1_ix(l1_es_line(), l1_ces_seam(True{})))

def l1_lines_pos__want() -> Bool:
  True{}

def l1_lines_neg__got() -> Bool:
  Op.hcs_all_lines(l1_hc0() <> Nil{}, l1_ix(l1_es_cc(), l1_ces_one()))

def l1_lines_neg__want() -> Bool:
  False{}

def l1_curved_skip__got() -> Nat:
  Op.loop_orient_class(l1_hc0() <> Nil{}, l1_ixv(l1_vs2(), l1_es_cc(), l1_ces_one()), l1_pl(), True{}, Ty.LK_outer{})

def l1_curved_skip__want() -> Nat:
  0n

def l1_cnt_round__got() -> Nat:
  Op.cnt_count(Op.cnt_pack(2n, True{}))

def l1_cnt_round__want() -> Nat:
  2n

def l1_cnt_done__got() -> Bool:
  Op.cnt_done(Op.cnt_pack(2n, True{}))

def l1_cnt_done__want() -> Bool:
  True{}

def l1_cnt_zero__got() -> Bool:
  Bool.and(Bool.not(Op.cnt_done(0n)), Nat.is_eq(Op.cnt_count(0n), 0n))

def l1_cnt_zero__want() -> Bool:
  True{}

def ck_fuel_nurbs__got() -> Bool:
  Nat.is_eq(Ty.ix_bound(b_nb_edge()), 9n)

def ck_fuel_nurbs__want() -> Bool:
  True{}

def ck_embed_nurbs_short__got() -> Nat:
  Op.brep_embed_c(b_nb_edge(), 2n)

def ck_embed_nurbs_short__want() -> Nat:
  0n

def ck_embed_nurbs_full__got() -> Nat:
  Op.brep_embed_c(b_nb_edge(), 9n)

def ck_embed_nurbs_full__want() -> Nat:
  3n

def ck_cyl_round__got() -> Bool:
  String.eq(Ty.tres_show(Op.brep_checked(b_cyl_round(), Ty.P_manifold_solid{}, 20n)), "ok")

def ck_cyl_round__want() -> Bool:
  True{}
