import Base
import ../src/c00/types.bend as T
import ../src/c01/types.bend as V
import ../src/c03/types.bend as G
import ../src/c03/ops.bend as GO
import ../src/c04/types.bend as Ty
import ../src/c04/ops.bend as Op
import ../src/base/par.bend as B

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
  Ty.Fa{41u64, sf_pl(), hlp_a() <> Nil{}, True{}}

def fa_b() -> Ty.Face:
  Ty.Fa{42u64, sf_cy(), Ty.mk_hlp(1n, 32u64) <> Nil{},
    False{}}

def fas0() -> List<&2, Ty.Face>:
  Nil{}

def fas1() -> List<&2, Ty.Face>:
  fa_a() <> Nil{}

def fas2() -> List<&2, Ty.Face>:
  fa_a() <> fa_b() <> Nil{}

def fas_badarm() -> List<&2, Ty.Face>:
  Ty.Fa{41u64, cv_ln(), hlp1(), True{}} <> Nil{}

def fas_badloops() -> List<&2, Ty.Face>:
  Ty.Fa{41u64, sf_pl(), hlp0(), True{}} <> Nil{}

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
  Ty.Fa{49u64, sf_cy(), hlp1(), False{}}

def sh_r() -> Ty.Shell:
  Ty.Sh{59u64, hfa1(), Ty.SK_inner{}}

def so_r() -> Ty.Solid:
  Ty.So{69u64, hsh_a(), hsh1()}

def cp_r() -> Ty.Compound:
  Ty.Cp{hso1(), hsh1()}

law tok_ok:
  for v: Ty.TVal
  {Ty.tres_ok(Ty.Tok{v}) == True{} : Bool}

def tok_ok(v):
  match v:
    case Ty.T_f{w}: {==}
    case Ty.T_n{w}: {==}
    case Ty.T_b{w}: {==}
    case Ty.T_vx{w}: {==}
    case Ty.T_ed{w}: {==}
    case Ty.T_ce{w}: {==}
    case Ty.T_lp{w}: {==}
    case Ty.T_fa{w}: {==}
    case Ty.T_sh{w}: {==}
    case Ty.T_so{w}: {==}
    case Ty.T_cp{w}: {==}
    case Ty.T_brep{w}: {==}
    case Ty.T_hv{w}: {==}
    case Ty.T_he{w}: {==}
    case Ty.T_hc{w}: {==}
    case Ty.T_hlp{w}: {==}
    case Ty.T_hfa{w}: {==}
    case Ty.T_hsh{w}: {==}
    case Ty.T_hso{w}: {==}

law tok_kind_doc:
  for v: Ty.TVal
  {Ty.tres_kind(Ty.Tok{v}) == T.F_invalid{} : T.FailKind}

def tok_kind_doc(v):
  match v:
    case Ty.T_f{w}: {==}
    case Ty.T_n{w}: {==}
    case Ty.T_b{w}: {==}
    case Ty.T_vx{w}: {==}
    case Ty.T_ed{w}: {==}
    case Ty.T_ce{w}: {==}
    case Ty.T_lp{w}: {==}
    case Ty.T_fa{w}: {==}
    case Ty.T_sh{w}: {==}
    case Ty.T_so{w}: {==}
    case Ty.T_cp{w}: {==}
    case Ty.T_brep{w}: {==}
    case Ty.T_hv{w}: {==}
    case Ty.T_he{w}: {==}
    case Ty.T_hc{w}: {==}
    case Ty.T_hlp{w}: {==}
    case Ty.T_hfa{w}: {==}
    case Ty.T_hsh{w}: {==}
    case Ty.T_hso{w}: {==}

law tok_show_ok:
  for v: Ty.TVal
  {String.eq(Ty.tres_show(Ty.Tok{v}), "ok") == True{} : Bool}

def tok_show_ok(v):
  match v:
    case Ty.T_f{w}: {==}
    case Ty.T_n{w}: {==}
    case Ty.T_b{w}: {==}
    case Ty.T_vx{w}: {==}
    case Ty.T_ed{w}: {==}
    case Ty.T_ce{w}: {==}
    case Ty.T_lp{w}: {==}
    case Ty.T_fa{w}: {==}
    case Ty.T_sh{w}: {==}
    case Ty.T_so{w}: {==}
    case Ty.T_cp{w}: {==}
    case Ty.T_brep{w}: {==}
    case Ty.T_hv{w}: {==}
    case Ty.T_he{w}: {==}
    case Ty.T_hc{w}: {==}
    case Ty.T_hlp{w}: {==}
    case Ty.T_hfa{w}: {==}
    case Ty.T_hsh{w}: {==}
    case Ty.T_hso{w}: {==}

law terr_not_ok:
  for k: T.FailKind
  {Ty.tres_ok(Ty.terr(k)) == False{} : Bool}

def terr_not_ok(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_kind:
  for k: T.FailKind
  {Ty.tres_kind(Ty.terr(k)) == k : T.FailKind}

def terr_kind(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_show:
  for k: T.FailKind
  {Ty.tres_show(Ty.terr(k)) == T.FailKind.show(k) : String}

def terr_show(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_f_zero:
  for k: T.FailKind
  {U64.is_eq(F64.bits(Ty.tres_f(Ty.terr(k))), 0u64)
    == True{} : Bool}

def terr_f_zero(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_n_zero:
  for k: T.FailKind
  {Nat.is_eq(Ty.tres_n(Ty.terr(k)), 0n) == True{} : Bool}

def terr_n_zero(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_b_false:
  for k: T.FailKind
  {Ty.tres_b(Ty.terr(k)) == False{} : Bool}

def terr_b_false(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_vx_zero:
  for k: T.FailKind
  {r_vx_zero(Ty.terr(k)) == True{} : Bool}

def terr_vx_zero(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_ed_dflt:
  for k: T.FailKind
  {r_ed_dflt(Ty.terr(k)) == True{} : Bool}

def terr_ed_dflt(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_ce_dflt:
  for k: T.FailKind
  {r_ce_dflt(Ty.terr(k)) == True{} : Bool}

def terr_ce_dflt(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_lp_dflt:
  for k: T.FailKind
  {r_lp_dflt(Ty.terr(k)) == True{} : Bool}

def terr_lp_dflt(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_fa_dflt:
  for k: T.FailKind
  {r_fa_dflt(Ty.terr(k)) == True{} : Bool}

def terr_fa_dflt(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_sh_dflt:
  for k: T.FailKind
  {r_sh_dflt(Ty.terr(k)) == True{} : Bool}

def terr_sh_dflt(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_so_dflt:
  for k: T.FailKind
  {r_so_dflt(Ty.terr(k)) == True{} : Bool}

def terr_so_dflt(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_cp_empty:
  for k: T.FailKind
  {r_cp_empty(Ty.terr(k)) == True{} : Bool}

def terr_cp_empty(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_brep_empty:
  for k: T.FailKind
  {r_brep_empty(Ty.terr(k)) == True{} : Bool}

def terr_brep_empty(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_hv_null:
  for k: T.FailKind
  {hv_null_chk(Ty.tres_hv(Ty.terr(k))) == True{} : Bool}

def terr_hv_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_he_null:
  for k: T.FailKind
  {he_null_chk(Ty.tres_he(Ty.terr(k))) == True{} : Bool}

def terr_he_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_hc_null:
  for k: T.FailKind
  {hc_null_chk(Ty.tres_hc(Ty.terr(k))) == True{} : Bool}

def terr_hc_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_hlp_null:
  for k: T.FailKind
  {hlp_null_chk(Ty.tres_hlp(Ty.terr(k))) == True{} : Bool}

def terr_hlp_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_hfa_null:
  for k: T.FailKind
  {hfa_null_chk(Ty.tres_hfa(Ty.terr(k))) == True{} : Bool}

def terr_hfa_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_hsh_null:
  for k: T.FailKind
  {hsh_null_chk(Ty.tres_hsh(Ty.terr(k))) == True{} : Bool}

def terr_hsh_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law terr_hso_null:
  for k: T.FailKind
  {hso_null_chk(Ty.tres_hso(Ty.terr(k))) == True{} : Bool}

def terr_hso_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law tok_f_round:
  {U64.is_eq(F64.bits(Ty.tres_f(Ty.tok_f(1.5f64))),
    4609434218613702656u64) == True{} : Bool}

def tok_f_round():
  {==}

law tok_n_round:
  {Nat.is_eq(Ty.tres_n(Ty.tok_n(7n)), 7n) == True{} : Bool}

def tok_n_round():
  {==}

law tok_b_round:
  {Ty.tres_b(Ty.tok_b(True{})) == True{} : Bool}

def tok_b_round():
  {==}

law tok_vx_round:
  {Bool.and(U64.is_eq(Ty.vx_gen(Ty.tres_vx(Ty.tok_vx(vx_r()))),
      9u64),
    pt_bits_eq(Ty.vx_p(Ty.tres_vx(Ty.tok_vx(vx_r()))),
      4607182418800017408u64, 4611686018427387904u64,
      4613937818241073152u64)) == True{} : Bool}

def tok_vx_round():
  {==}

law tok_ed_round:
  {Bool.and(U64.is_eq(Ty.ed_gen(Ty.tres_ed(Ty.tok_ed(ed_r()))),
      19u64),
    Bool.and(Nat.is_eq(Ty.hv_idx(Ty.ed_v0(Ty.tres_ed(
      Ty.tok_ed(ed_r())))), 0n),
      Bool.and(U64.is_eq(Ty.hv_gen(Ty.ed_v1(Ty.tres_ed(
        Ty.tok_ed(ed_r())))), 2u64),
        Bool.and(U64.is_eq(Ty.ekind_tag(Ty.ed_kind(
          Ty.tres_ed(Ty.tok_ed(ed_r())))), 0u64),
          Ty.gval_is_curve(Ty.ekind_curve(Ty.ed_kind(
            Ty.tres_ed(Ty.tok_ed(ed_r()))))))))) == True{} : Bool}

def tok_ed_round():
  {==}

law tok_ce_round:
  {Bool.and(U64.is_eq(Ty.ce_gen(Ty.tres_ce(Ty.tok_ce(ce_r()))),
      29u64),
    Bool.and(Nat.is_eq(Ty.he_idx(Ty.ce_edge(Ty.tres_ce(
      Ty.tok_ce(ce_r())))), 0n),
      Bool.and(Bool.not(Ty.ce_fwd(Ty.tres_ce(Ty.tok_ce(
        ce_r())))),
        Ty.gval_is_trim(Ty.ce_trim(Ty.tres_ce(Ty.tok_ce(
          ce_r()))))))) == True{} : Bool}

def tok_ce_round():
  {==}

law tok_lp_round:
  {Bool.and(U64.is_eq(Ty.lp_gen(Ty.tres_lp(Ty.tok_lp(lp_r()))),
      39u64),
    Bool.and(Ty.hce_nonempty(Ty.lp_ces(Ty.tres_lp(Ty.tok_lp(
      lp_r())))),
      U64.is_eq(Ty.lkind_tag(Ty.lp_kind(Ty.tres_lp(
        Ty.tok_lp(lp_r())))), 1u64))) == True{} : Bool}

def tok_lp_round():
  {==}

law tok_fa_round:
  {Bool.and(U64.is_eq(Ty.fa_gen(Ty.tres_fa(Ty.tok_fa(fa_r()))),
      49u64),
    Bool.and(Ty.gval_is_surf(Ty.fa_surf(Ty.tres_fa(
      Ty.tok_fa(fa_r())))),
      Bool.and(Ty.hlp_nonempty(Ty.fa_loops(Ty.tres_fa(
        Ty.tok_fa(fa_r())))),
        Bool.not(Ty.fa_same(Ty.tres_fa(Ty.tok_fa(
          fa_r()))))))) == True{} : Bool}

def tok_fa_round():
  {==}

law tok_sh_round:
  {Bool.and(U64.is_eq(Ty.sh_gen(Ty.tres_sh(Ty.tok_sh(sh_r()))),
      59u64),
    Bool.and(Ty.hfa_nonempty(Ty.sh_faces(Ty.tres_sh(
      Ty.tok_sh(sh_r())))),
      U64.is_eq(Ty.skind_tag(Ty.sh_kind(Ty.tres_sh(
        Ty.tok_sh(sh_r())))), 1u64))) == True{} : Bool}

def tok_sh_round():
  {==}

law tok_so_round:
  {Bool.and(U64.is_eq(Ty.so_gen(Ty.tres_so(Ty.tok_so(so_r()))),
      69u64),
    Bool.and(Nat.is_eq(Ty.hsh_idx(Ty.so_outer(Ty.tres_so(
      Ty.tok_so(so_r())))), 0n),
      Ty.so_has_cav(Ty.tres_so(Ty.tok_so(so_r())))))
    == True{} : Bool}

def tok_so_round():
  {==}

law tok_cp_round:
  {Bool.and(Ty.cp_has_solids(Ty.tres_cp(Ty.tok_cp(cp_r()))),
    Ty.cp_has_shells(Ty.tres_cp(Ty.tok_cp(cp_r()))))
    == True{} : Bool}

def tok_cp_round():
  {==}

law tok_brep_round:
  {U64.is_eq(Ty.brep_stamp(Ty.tres_brep(Ty.tok_brep(
    b_sos1()))), 61u64) == True{} : Bool}

def tok_brep_round():
  {==}

law tok_hv_round:
  {Bool.and(Nat.is_eq(Ty.hv_idx(Ty.tres_hv(Ty.tok_hv(
    Ty.mk_hv(3n, 4u64)))), 3n),
    U64.is_eq(Ty.hv_gen(Ty.tres_hv(Ty.tok_hv(
      Ty.mk_hv(3n, 4u64)))), 4u64)) == True{} : Bool}

def tok_hv_round():
  {==}

law tok_he_round:
  {Bool.and(Nat.is_eq(Ty.he_idx(Ty.tres_he(Ty.tok_he(
    Ty.mk_he(5n, 6u64)))), 5n),
    U64.is_eq(Ty.he_gen(Ty.tres_he(Ty.tok_he(
      Ty.mk_he(5n, 6u64)))), 6u64)) == True{} : Bool}

def tok_he_round():
  {==}

law tok_hc_round:
  {Bool.and(Nat.is_eq(Ty.hc_idx(Ty.tres_hc(Ty.tok_hc(
    Ty.mk_hc(7n, 8u64)))), 7n),
    U64.is_eq(Ty.hc_gen(Ty.tres_hc(Ty.tok_hc(
      Ty.mk_hc(7n, 8u64)))), 8u64)) == True{} : Bool}

def tok_hc_round():
  {==}

law tok_hlp_round:
  {Bool.and(Nat.is_eq(Ty.hlp_idx(Ty.tres_hlp(Ty.tok_hlp(
    Ty.mk_hlp(9n, 10u64)))), 9n),
    U64.is_eq(Ty.hlp_gen(Ty.tres_hlp(Ty.tok_hlp(
      Ty.mk_hlp(9n, 10u64)))), 10u64)) == True{} : Bool}

def tok_hlp_round():
  {==}

law tok_hfa_round:
  {Bool.and(Nat.is_eq(Ty.hfa_idx(Ty.tres_hfa(Ty.tok_hfa(
    Ty.mk_hfa(11n, 12u64)))), 11n),
    U64.is_eq(Ty.hfa_gen(Ty.tres_hfa(Ty.tok_hfa(
      Ty.mk_hfa(11n, 12u64)))), 12u64)) == True{} : Bool}

def tok_hfa_round():
  {==}

law tok_hsh_round:
  {Bool.and(Nat.is_eq(Ty.hsh_idx(Ty.tres_hsh(Ty.tok_hsh(
    Ty.mk_hsh(13n, 14u64)))), 13n),
    U64.is_eq(Ty.hsh_gen(Ty.tres_hsh(Ty.tok_hsh(
      Ty.mk_hsh(13n, 14u64)))), 14u64)) == True{} : Bool}

def tok_hsh_round():
  {==}

law tok_hso_round:
  {Bool.and(Nat.is_eq(Ty.hso_idx(Ty.tres_hso(Ty.tok_hso(
    Ty.mk_hso(15n, 16u64)))), 15n),
    U64.is_eq(Ty.hso_gen(Ty.tres_hso(Ty.tok_hso(
      Ty.mk_hso(15n, 16u64)))), 16u64)) == True{} : Bool}

def tok_hso_round():
  {==}

law mis_f_zero:
  {U64.is_eq(F64.bits(Ty.tres_f(Ty.tok_n(5n))), 0u64)
    == True{} : Bool}

def mis_f_zero():
  {==}

law mis_n_zero:
  {Nat.is_eq(Ty.tres_n(Ty.tok_f(1.0f64)), 0n)
    == True{} : Bool}

def mis_n_zero():
  {==}

law mis_b_false:
  {Ty.tres_b(Ty.tok_n(9n)) == False{} : Bool}

def mis_b_false():
  {==}

law mis_vx_zero:
  {r_vx_zero(Ty.tok_f(0.0f64)) == True{} : Bool}

def mis_vx_zero():
  {==}

law mis_ed_dflt:
  {r_ed_dflt(Ty.tok_n(0n)) == True{} : Bool}

def mis_ed_dflt():
  {==}

law mis_ce_dflt:
  {r_ce_dflt(Ty.tok_b(True{})) == True{} : Bool}

def mis_ce_dflt():
  {==}

law mis_lp_dflt:
  {r_lp_dflt(Ty.tok_f(3.0f64)) == True{} : Bool}

def mis_lp_dflt():
  {==}

law mis_fa_dflt:
  {r_fa_dflt(Ty.tok_n(1n)) == True{} : Bool}

def mis_fa_dflt():
  {==}

law mis_sh_dflt:
  {r_sh_dflt(Ty.tok_f(4.0f64)) == True{} : Bool}

def mis_sh_dflt():
  {==}

law mis_so_dflt:
  {r_so_dflt(Ty.tok_n(2n)) == True{} : Bool}

def mis_so_dflt():
  {==}

law mis_cp_empty:
  {r_cp_empty(Ty.tok_b(False{})) == True{} : Bool}

def mis_cp_empty():
  {==}

law mis_brep_empty:
  {r_brep_empty(Ty.tok_f(5.0f64)) == True{} : Bool}

def mis_brep_empty():
  {==}

law mis_hv_null:
  {hv_null_chk(Ty.tres_hv(Ty.tok_f(6.0f64))) == True{} : Bool}

def mis_hv_null():
  {==}

law mis_he_null:
  {he_null_chk(Ty.tres_he(Ty.tok_n(3n))) == True{} : Bool}

def mis_he_null():
  {==}

law mis_hc_null:
  {hc_null_chk(Ty.tres_hc(Ty.tok_b(True{}))) == True{} : Bool}

def mis_hc_null():
  {==}

law mis_hlp_null:
  {hlp_null_chk(Ty.tres_hlp(Ty.tok_f(7.0f64)))
    == True{} : Bool}

def mis_hlp_null():
  {==}

law mis_hfa_null:
  {hfa_null_chk(Ty.tres_hfa(Ty.tok_n(4n))) == True{} : Bool}

def mis_hfa_null():
  {==}

law mis_hsh_null:
  {hsh_null_chk(Ty.tres_hsh(Ty.tok_vx(vx_r()))) == True{} : Bool}

def mis_hsh_null():
  {==}

law mis_hso_null:
  {hso_null_chk(Ty.tres_hso(Ty.tok_ed(ed_r()))) == True{} : Bool}

def mis_hso_null():
  {==}

law mk_hv_idx:
  for i: Nat
  for g: U64
  {Ty.hv_idx(Ty.mk_hv(i, g)) == i : Nat}

def mk_hv_idx(i, g):
  {==}

law mk_hv_gen:
  for i: Nat
  for g: U64
  {Ty.hv_gen(Ty.mk_hv(i, g)) == g : U64}

def mk_hv_gen(i, g):
  {==}

law mk_he_idx:
  for i: Nat
  for g: U64
  {Ty.he_idx(Ty.mk_he(i, g)) == i : Nat}

def mk_he_idx(i, g):
  {==}

law mk_he_gen:
  for i: Nat
  for g: U64
  {Ty.he_gen(Ty.mk_he(i, g)) == g : U64}

def mk_he_gen(i, g):
  {==}

law mk_hc_idx:
  for i: Nat
  for g: U64
  {Ty.hc_idx(Ty.mk_hc(i, g)) == i : Nat}

def mk_hc_idx(i, g):
  {==}

law mk_hc_gen:
  for i: Nat
  for g: U64
  {Ty.hc_gen(Ty.mk_hc(i, g)) == g : U64}

def mk_hc_gen(i, g):
  {==}

law mk_hlp_idx:
  for i: Nat
  for g: U64
  {Ty.hlp_idx(Ty.mk_hlp(i, g)) == i : Nat}

def mk_hlp_idx(i, g):
  {==}

law mk_hlp_gen:
  for i: Nat
  for g: U64
  {Ty.hlp_gen(Ty.mk_hlp(i, g)) == g : U64}

def mk_hlp_gen(i, g):
  {==}

law mk_hfa_idx:
  for i: Nat
  for g: U64
  {Ty.hfa_idx(Ty.mk_hfa(i, g)) == i : Nat}

def mk_hfa_idx(i, g):
  {==}

law mk_hfa_gen:
  for i: Nat
  for g: U64
  {Ty.hfa_gen(Ty.mk_hfa(i, g)) == g : U64}

def mk_hfa_gen(i, g):
  {==}

law mk_hsh_idx:
  for i: Nat
  for g: U64
  {Ty.hsh_idx(Ty.mk_hsh(i, g)) == i : Nat}

def mk_hsh_idx(i, g):
  {==}

law mk_hsh_gen:
  for i: Nat
  for g: U64
  {Ty.hsh_gen(Ty.mk_hsh(i, g)) == g : U64}

def mk_hsh_gen(i, g):
  {==}

law mk_hso_idx:
  for i: Nat
  for g: U64
  {Ty.hso_idx(Ty.mk_hso(i, g)) == i : Nat}

def mk_hso_idx(i, g):
  {==}

law mk_hso_gen:
  for i: Nat
  for g: U64
  {Ty.hso_gen(Ty.mk_hso(i, g)) == g : U64}

def mk_hso_gen(i, g):
  {==}

law null_hv:
  {hv_null_chk(Ty.hv_null()) == True{} : Bool}

def null_hv():
  {==}

law null_he:
  {he_null_chk(Ty.he_null()) == True{} : Bool}

def null_he():
  {==}

law null_hc:
  {hc_null_chk(Ty.hc_null()) == True{} : Bool}

def null_hc():
  {==}

law null_hlp:
  {hlp_null_chk(Ty.hlp_null()) == True{} : Bool}

def null_hlp():
  {==}

law null_hfa:
  {hfa_null_chk(Ty.hfa_null()) == True{} : Bool}

def null_hfa():
  {==}

law null_hsh:
  {hsh_null_chk(Ty.hsh_null()) == True{} : Bool}

def null_hsh():
  {==}

law null_hso:
  {hso_null_chk(Ty.hso_null()) == True{} : Bool}

def null_hso():
  {==}

law eq_hv:
  {Bool.and(Ty.hv_eq(Ty.mk_hv(3n, 4u64), Ty.mk_hv(3n, 4u64)),
    Bool.and(Bool.not(Ty.hv_eq(Ty.mk_hv(3n, 4u64),
      Ty.mk_hv(5n, 4u64))),
      Bool.not(Ty.hv_eq(Ty.mk_hv(3n, 4u64),
        Ty.mk_hv(3n, 6u64))))) == True{} : Bool}

def eq_hv():
  {==}

law eq_he:
  {Bool.and(Ty.he_eq(Ty.mk_he(3n, 4u64), Ty.mk_he(3n, 4u64)),
    Bool.and(Bool.not(Ty.he_eq(Ty.mk_he(3n, 4u64),
      Ty.mk_he(5n, 4u64))),
      Bool.not(Ty.he_eq(Ty.mk_he(3n, 4u64),
        Ty.mk_he(3n, 6u64))))) == True{} : Bool}

def eq_he():
  {==}

law eq_hc:
  {Bool.and(Ty.hc_eq(Ty.mk_hc(3n, 4u64), Ty.mk_hc(3n, 4u64)),
    Bool.and(Bool.not(Ty.hc_eq(Ty.mk_hc(3n, 4u64),
      Ty.mk_hc(5n, 4u64))),
      Bool.not(Ty.hc_eq(Ty.mk_hc(3n, 4u64),
        Ty.mk_hc(3n, 6u64))))) == True{} : Bool}

def eq_hc():
  {==}

law eq_hlp:
  {Bool.and(Ty.hlp_eq(Ty.mk_hlp(3n, 4u64),
    Ty.mk_hlp(3n, 4u64)),
    Bool.and(Bool.not(Ty.hlp_eq(Ty.mk_hlp(3n, 4u64),
      Ty.mk_hlp(5n, 4u64))),
      Bool.not(Ty.hlp_eq(Ty.mk_hlp(3n, 4u64),
        Ty.mk_hlp(3n, 6u64))))) == True{} : Bool}

def eq_hlp():
  {==}

law eq_hfa:
  {Bool.and(Ty.hfa_eq(Ty.mk_hfa(3n, 4u64),
    Ty.mk_hfa(3n, 4u64)),
    Bool.and(Bool.not(Ty.hfa_eq(Ty.mk_hfa(3n, 4u64),
      Ty.mk_hfa(5n, 4u64))),
      Bool.not(Ty.hfa_eq(Ty.mk_hfa(3n, 4u64),
        Ty.mk_hfa(3n, 6u64))))) == True{} : Bool}

def eq_hfa():
  {==}

law eq_hsh:
  {Bool.and(Ty.hsh_eq(Ty.mk_hsh(3n, 4u64),
    Ty.mk_hsh(3n, 4u64)),
    Bool.and(Bool.not(Ty.hsh_eq(Ty.mk_hsh(3n, 4u64),
      Ty.mk_hsh(5n, 4u64))),
      Bool.not(Ty.hsh_eq(Ty.mk_hsh(3n, 4u64),
        Ty.mk_hsh(3n, 6u64))))) == True{} : Bool}

def eq_hsh():
  {==}

law eq_hso:
  {Bool.and(Ty.hso_eq(Ty.mk_hso(3n, 4u64),
    Ty.mk_hso(3n, 4u64)),
    Bool.and(Bool.not(Ty.hso_eq(Ty.mk_hso(3n, 4u64),
      Ty.mk_hso(5n, 4u64))),
      Bool.not(Ty.hso_eq(Ty.mk_hso(3n, 4u64),
        Ty.mk_hso(3n, 6u64))))) == True{} : Bool}

def eq_hso():
  {==}

law isc_ln:
  {Ty.gval_is_curve(cv_ln()) == True{} : Bool}

def isc_ln():
  {==}

law isc_cc:
  {Ty.gval_is_curve(cv_cc()) == True{} : Bool}

def isc_cc():
  {==}

law isc_bz:
  {Ty.gval_is_curve(cv_bz()) == True{} : Bool}

def isc_bz():
  {==}

law isc_rq:
  {Ty.gval_is_curve(cv_rq()) == True{} : Bool}

def isc_rq():
  {==}

law isc_nb:
  {Ty.gval_is_curve(cv_nb()) == True{} : Bool}

def isc_nb():
  {==}

law isc_pl_no:
  {Ty.gval_is_curve(sf_pl()) == False{} : Bool}

def isc_pl_no():
  {==}

law isc_ts_no:
  {Ty.gval_is_curve(tr_ts()) == False{} : Bool}

def isc_ts_no():
  {==}

law iss_pl:
  {Ty.gval_is_surf(sf_pl()) == True{} : Bool}

def iss_pl():
  {==}

law iss_cy:
  {Ty.gval_is_surf(sf_cy()) == True{} : Bool}

def iss_cy():
  {==}

law iss_co:
  {Ty.gval_is_surf(sf_co()) == True{} : Bool}

def iss_co():
  {==}

law iss_sp:
  {Ty.gval_is_surf(sf_sp()) == True{} : Bool}

def iss_sp():
  {==}

law iss_to:
  {Ty.gval_is_surf(sf_to()) == True{} : Bool}

def iss_to():
  {==}

law iss_bp:
  {Ty.gval_is_surf(sf_bp()) == True{} : Bool}

def iss_bp():
  {==}

law iss_ln_no:
  {Ty.gval_is_surf(cv_ln()) == False{} : Bool}

def iss_ln_no():
  {==}

law iss_tb_no:
  {Ty.gval_is_surf(tr_tb()) == False{} : Bool}

def iss_tb_no():
  {==}

law ist_ts:
  {Ty.gval_is_trim(tr_ts()) == True{} : Bool}

def ist_ts():
  {==}

law ist_tb:
  {Ty.gval_is_trim(tr_tb()) == True{} : Bool}

def ist_tb():
  {==}

law ist_ln_no:
  {Ty.gval_is_trim(cv_ln()) == False{} : Bool}

def ist_ln_no():
  {==}

law ist_sp_no:
  {Ty.gval_is_trim(sf_sp()) == False{} : Bool}

def ist_sp_no():
  {==}

law ne_hce0:
  {Ty.hce_nonempty(hce0()) == False{} : Bool}

def ne_hce0():
  {==}

law ne_hce1:
  {Ty.hce_nonempty(hc1()) == True{} : Bool}

def ne_hce1():
  {==}

law ne_hlp0:
  {Ty.hlp_nonempty(hlp0()) == False{} : Bool}

def ne_hlp0():
  {==}

law ne_hlp1:
  {Ty.hlp_nonempty(hlp1()) == True{} : Bool}

def ne_hlp1():
  {==}

law ne_hfa0:
  {Ty.hfa_nonempty(hfa0()) == False{} : Bool}

def ne_hfa0():
  {==}

law ne_hfa1:
  {Ty.hfa_nonempty(hfa1()) == True{} : Bool}

def ne_hfa1():
  {==}

law ne_hsh0:
  {Ty.hsh_nonempty(hsh0()) == False{} : Bool}

def ne_hsh0():
  {==}

law ne_hsh1:
  {Ty.hsh_nonempty(hsh1()) == True{} : Bool}

def ne_hsh1():
  {==}

law ne_hso0:
  {Ty.hso_nonempty(hso0()) == False{} : Bool}

def ne_hso0():
  {==}

law ne_hso1:
  {Ty.hso_nonempty(hso1()) == True{} : Bool}

def ne_hso1():
  {==}

law vx_valid_yes:
  {Ty.vx_valid(Ty.Vx{0u64, p123()}) == True{} : Bool}

def vx_valid_yes():
  {==}

law vx_valid_no:
  {Ty.vx_valid(Ty.Vx{0u64, pnan()}) == False{} : Bool}

def vx_valid_no():
  {==}

law ev_curve:
  {Ty.edge_valid(Ty.Ed{0u64, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}}) == True{} : Bool}

def ev_curve():
  {==}

law ev_closed:
  {Ty.edge_valid(Ty.Ed{0u64, hv12(), hv12(),
    Ty.EK_curve{cv_cc(), dom_01()}}) == True{} : Bool}

def ev_closed():
  {==}

law ev_arm_no:
  {Ty.edge_valid(Ty.Ed{0u64, hv01(), hv12(),
    Ty.EK_curve{sf_pl(), dom_01()}}) == False{} : Bool}

def ev_arm_no():
  {==}

law ev_dom_no:
  {Ty.edge_valid(Ty.Ed{0u64, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_flip()}}) == False{} : Bool}

def ev_dom_no():
  {==}

law ev_degen:
  {Ty.edge_valid(Ty.Ed{0u64, hv01(), hv01(),
    Ty.EK_degenerate{}}) == True{} : Bool}

def ev_degen():
  {==}

law ev_degen_no:
  {Ty.edge_valid(Ty.Ed{0u64, hv01(), hv12(),
    Ty.EK_degenerate{}}) == False{} : Bool}

def ev_degen_no():
  {==}

law eclosed_yes:
  {Ty.edge_is_closed(Ty.Ed{0u64, hv12(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}}) == True{} : Bool}

def eclosed_yes():
  {==}

law eclosed_no:
  {Ty.edge_is_closed(Ty.Ed{0u64, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}}) == False{} : Bool}

def eclosed_no():
  {==}

law edegen_yes:
  {Ty.edge_is_degenerate(Ty.Ed{0u64, hv01(), hv01(),
    Ty.EK_degenerate{}}) == True{} : Bool}

def edegen_yes():
  {==}

law edegen_no:
  {Ty.edge_is_degenerate(Ty.Ed{0u64, hv01(), hv12(),
    Ty.EK_curve{cv_ln(), dom_01()}}) == False{} : Bool}

def edegen_no():
  {==}

law ce_valid_yes:
  {Ty.ce_valid(Ty.Ce{0u64, he01(), True{}, tr_ts()})
    == True{} : Bool}

def ce_valid_yes():
  {==}

law ce_valid_no:
  {Ty.ce_valid(Ty.Ce{0u64, he01(), True{}, cv_ln()})
    == False{} : Bool}

def ce_valid_no():
  {==}

law lp_valid_yes:
  {Ty.lp_valid(Ty.Lp{0u64, hc1(), Ty.LK_outer{}})
    == True{} : Bool}

def lp_valid_yes():
  {==}

law lp_valid_no:
  {Ty.lp_valid(Ty.Lp{0u64, hce0(), Ty.LK_outer{}})
    == False{} : Bool}

def lp_valid_no():
  {==}

law fa_valid_yes:
  {Ty.fa_valid(Ty.Fa{0u64, sf_pl(), hlp1(), True{}})
    == True{} : Bool}

def fa_valid_yes():
  {==}

law fa_valid_arm:
  {Ty.fa_valid(Ty.Fa{0u64, cv_ln(), hlp1(), True{}})
    == False{} : Bool}

def fa_valid_arm():
  {==}

law fa_valid_loops:
  {Ty.fa_valid(Ty.Fa{0u64, sf_pl(), hlp0(), True{}})
    == False{} : Bool}

def fa_valid_loops():
  {==}

law sh_valid_yes:
  {Ty.sh_valid(Ty.Sh{0u64, hfa1(), Ty.SK_outer{}})
    == True{} : Bool}

def sh_valid_yes():
  {==}

law sh_valid_no:
  {Ty.sh_valid(Ty.Sh{0u64, hfa0(), Ty.SK_outer{}})
    == False{} : Bool}

def sh_valid_no():
  {==}

law so_valid_yes:
  {Ty.so_valid(Ty.So{0u64, hsh_a(), hsh0()})
    == True{} : Bool}

def so_valid_yes():
  {==}

law so_cav_no:
  {Ty.so_has_cav(Ty.So{0u64, hsh_a(), hsh0()})
    == False{} : Bool}

def so_cav_no():
  {==}

law so_cav_yes:
  {Ty.so_has_cav(Ty.So{0u64, hsh_a(), hsh1()})
    == True{} : Bool}

def so_cav_yes():
  {==}

law cp_sol_no:
  {Ty.cp_has_solids(Ty.Cp{hso0(), hsh0()})
    == False{} : Bool}

def cp_sol_no():
  {==}

law cp_sol_yes:
  {Ty.cp_has_solids(Ty.Cp{hso1(), hsh0()})
    == True{} : Bool}

def cp_sol_yes():
  {==}

law cp_sh_no:
  {Ty.cp_has_shells(Ty.Cp{hso0(), hsh0()})
    == False{} : Bool}

def cp_sh_no():
  {==}

law cp_sh_yes:
  {Ty.cp_has_shells(Ty.Cp{hso0(), hsh1()})
    == True{} : Bool}

def cp_sh_yes():
  {==}

law tag_ek_curve:
  {U64.is_eq(Ty.ekind_tag(Ty.EK_curve{cv_ln(), dom_01()}),
    0u64) == True{} : Bool}

def tag_ek_curve():
  {==}

law tag_ek_degen:
  {U64.is_eq(Ty.ekind_tag(Ty.EK_degenerate{}), 1u64)
    == True{} : Bool}

def tag_ek_degen():
  {==}

law tag_lk_outer:
  {U64.is_eq(Ty.lkind_tag(Ty.LK_outer{}), 0u64)
    == True{} : Bool}

def tag_lk_outer():
  {==}

law tag_lk_inner:
  {U64.is_eq(Ty.lkind_tag(Ty.LK_inner{}), 1u64)
    == True{} : Bool}

def tag_lk_inner():
  {==}

law tag_sk_outer:
  {U64.is_eq(Ty.skind_tag(Ty.SK_outer{}), 0u64)
    == True{} : Bool}

def tag_sk_outer():
  {==}

law tag_sk_inner:
  {U64.is_eq(Ty.skind_tag(Ty.SK_inner{}), 1u64)
    == True{} : Bool}

def tag_sk_inner():
  {==}

law tag_sk_open:
  {U64.is_eq(Ty.skind_tag(Ty.SK_open{}), 2u64)
    == True{} : Bool}

def tag_sk_open():
  {==}

law tag_prof_solid:
  {U64.is_eq(Ty.profile_tag(Ty.P_manifold_solid{}), 0u64)
    == True{} : Bool}

def tag_prof_solid():
  {==}

law tag_prof_open:
  {U64.is_eq(Ty.profile_tag(Ty.P_open_shell{}), 1u64)
    == True{} : Bool}

def tag_prof_open():
  {==}

law show_prof_solid:
  {String.eq(Ty.profile_show(Ty.P_manifold_solid{}),
    "manifold-solid") == True{} : Bool}

def show_prof_solid():
  {==}

law show_prof_open:
  {String.eq(Ty.profile_show(Ty.P_open_shell{}), "open-shell")
    == True{} : Bool}

def show_prof_open():
  {==}

law ekind_is_curve_t:
  {Ty.ekind_is_curve(Ty.EK_curve{cv_ln(), dom_01()})
    == True{} : Bool}

def ekind_is_curve_t():
  {==}

law ekind_is_curve_f:
  {Ty.ekind_is_curve(Ty.EK_degenerate{}) == False{} : Bool}

def ekind_is_curve_f():
  {==}

law ekind_curve_degen:
  {ln_zero_bits(Ty.ekind_curve(Ty.EK_degenerate{}))
    == True{} : Bool}

def ekind_curve_degen():
  {==}

law ekind_dom_degen:
  {Bool.and(U64.is_eq(F64.bits(G.dom_lo(Ty.ekind_dom(
    Ty.EK_degenerate{}))), 0u64),
    U64.is_eq(F64.bits(G.dom_hi(Ty.ekind_dom(
      Ty.EK_degenerate{}))), 0u64)) == True{} : Bool}

def ekind_dom_degen():
  {==}

law ekind_dom_curve:
  {Bool.and(U64.is_eq(F64.bits(G.dom_lo(Ty.ekind_dom(
    Ty.EK_curve{cv_ln(), dom_01()}))), 0u64),
    U64.is_eq(F64.bits(G.dom_hi(Ty.ekind_dom(
      Ty.EK_curve{cv_ln(), dom_01()}))),
      4607182418800017408u64)) == True{} : Bool}

def ekind_dom_curve():
  {==}

law okd_pack_tt:
  {Nat.is_eq(Ty.okd_pack(True{}, True{}), 3n)
    == True{} : Bool}

def okd_pack_tt():
  {==}

law okd_pack_tf:
  {Nat.is_eq(Ty.okd_pack(True{}, False{}), 1n)
    == True{} : Bool}

def okd_pack_tf():
  {==}

law okd_pack_ft:
  {Nat.is_eq(Ty.okd_pack(False{}, True{}), 2n)
    == True{} : Bool}

def okd_pack_ft():
  {==}

law okd_pack_ff:
  {Nat.is_eq(Ty.okd_pack(False{}, False{}), 0n)
    == True{} : Bool}

def okd_pack_ff():
  {==}

law okd_ok_3:
  {Ty.okd_ok(3n) == True{} : Bool}

def okd_ok_3():
  {==}

law okd_ok_2:
  {Ty.okd_ok(2n) == False{} : Bool}

def okd_ok_2():
  {==}

law okd_done_3:
  {Ty.okd_done(3n) == True{} : Bool}

def okd_done_3():
  {==}

law okd_done_1:
  {Ty.okd_done(1n) == False{} : Bool}

def okd_done_1():
  {==}

law okd_all_33:
  {Nat.is_eq(Ty.okd_all(3n, 3n), 3n) == True{} : Bool}

def okd_all_33():
  {==}

law okd_all_30:
  {Nat.is_eq(Ty.okd_all(3n, 0n), 0n) == True{} : Bool}

def okd_all_30():
  {==}

law okd_all_12:
  {Nat.is_eq(Ty.okd_all(1n, 2n), 0n) == True{} : Bool}

def okd_all_12():
  {==}

law mk_vx_ok:
  {Bool.and(String.eq(Ty.tres_show(Ty.mk_vx(p123())), "ok"),
    pt_bits_eq(Ty.vx_p(Ty.tres_vx(Ty.mk_vx(p123()))),
      4607182418800017408u64, 4611686018427387904u64,
      4613937818241073152u64)) == True{} : Bool}

def mk_vx_ok():
  {==}

law mk_vx_gen0:
  {U64.is_eq(Ty.vx_gen(Ty.tres_vx(Ty.mk_vx(p123()))), 0u64)
    == True{} : Bool}

def mk_vx_gen0():
  {==}

law mk_vx_nan:
  {Bool.and(String.eq(Ty.tres_show(Ty.mk_vx(pnan())),
    "invalid-input"),
    r_vx_zero(Ty.mk_vx(pnan()))) == True{} : Bool}

def mk_vx_nan():
  {==}

law mk_vx_inf:
  {String.eq(Ty.tres_show(Ty.mk_vx(pinf())), "invalid-input")
    == True{} : Bool}

def mk_vx_inf():
  {==}

law mk_ec_ok:
  {Bool.and(String.eq(Ty.tres_show(Ty.mk_edge_curve(hv01(),
    hv12(), cv_ln(), dom_01())), "ok"),
    U64.is_eq(Ty.ed_gen(Ty.tres_ed(Ty.mk_edge_curve(hv01(),
      hv12(), cv_ln(), dom_01()))), 0u64)) == True{} : Bool}

def mk_ec_ok():
  {==}

law mk_ec_arm:
  {String.eq(Ty.tres_show(Ty.mk_edge_curve(hv01(), hv12(),
    sf_pl(), dom_01())), "invalid-input") == True{} : Bool}

def mk_ec_arm():
  {==}

law mk_ec_dom:
  {String.eq(Ty.tres_show(Ty.mk_edge_curve(hv01(), hv12(),
    cv_ln(), dom_flip())), "invalid-input") == True{} : Bool}

def mk_ec_dom():
  {==}

law mk_ec_domeq:
  {String.eq(Ty.tres_show(Ty.mk_edge_curve(hv01(), hv12(),
    cv_ln(), dom_eq())), "invalid-input") == True{} : Bool}

def mk_ec_domeq():
  {==}

law mk_ec_domnan:
  {String.eq(Ty.tres_show(Ty.mk_edge_curve(hv01(), hv12(),
    cv_ln(), dom_nan())), "invalid-input") == True{} : Bool}

def mk_ec_domnan():
  {==}

law mk_ec_trim:
  {String.eq(Ty.tres_show(Ty.mk_edge_curve(hv01(), hv12(),
    tr_ts(), dom_01())), "invalid-input") == True{} : Bool}

def mk_ec_trim():
  {==}

law mk_edg_ok:
  {Bool.and(String.eq(Ty.tres_show(Ty.mk_edge_degen(hv01(),
    hv01())), "ok"),
    U64.is_eq(Ty.ed_gen(Ty.tres_ed(Ty.mk_edge_degen(hv01(),
      hv01()))), 0u64)) == True{} : Bool}

def mk_edg_ok():
  {==}

law mk_edg_split:
  {String.eq(Ty.tres_show(Ty.mk_edge_degen(hv01(), hv12())),
    "invalid-input") == True{} : Bool}

def mk_edg_split():
  {==}

law mk_ce_ok:
  {Bool.and(String.eq(Ty.tres_show(Ty.mk_coedge(he01(),
    True{}, tr_ts())), "ok"),
    U64.is_eq(Ty.ce_gen(Ty.tres_ce(Ty.mk_coedge(he01(),
      True{}, tr_ts()))), 0u64)) == True{} : Bool}

def mk_ce_ok():
  {==}

law mk_ce_rev:
  {Bool.and(String.eq(Ty.tres_show(Ty.mk_coedge(he01(),
    False{}, tr_tb())), "ok"),
    Bool.not(Ty.ce_fwd(Ty.tres_ce(Ty.mk_coedge(he01(),
      False{}, tr_tb()))))) == True{} : Bool}

def mk_ce_rev():
  {==}

law mk_ce_trim:
  {String.eq(Ty.tres_show(Ty.mk_coedge(he01(), True{},
    cv_ln())), "invalid-input") == True{} : Bool}

def mk_ce_trim():
  {==}

law mk_ce_surf:
  {String.eq(Ty.tres_show(Ty.mk_coedge(he01(), True{},
    sf_pl())), "invalid-input") == True{} : Bool}

def mk_ce_surf():
  {==}

law mk_lp_ok:
  {Bool.and(String.eq(Ty.tres_show(Ty.mk_loop(hc2(),
    Ty.LK_inner{})), "ok"),
    Bool.and(U64.is_eq(Ty.lp_gen(Ty.tres_lp(Ty.mk_loop(
      hc2(), Ty.LK_inner{}))), 0u64),
      U64.is_eq(Ty.lkind_tag(Ty.lp_kind(Ty.tres_lp(
        Ty.mk_loop(hc2(), Ty.LK_inner{})))), 1u64)))
    == True{} : Bool}

def mk_lp_ok():
  {==}

law mk_lp_nil:
  {String.eq(Ty.tres_show(Ty.mk_loop(hce0(),
    Ty.LK_outer{})), "invalid-input") == True{} : Bool}

def mk_lp_nil():
  {==}

law mk_fa_ok:
  {Bool.and(String.eq(Ty.tres_show(Ty.mk_face(sf_cy(),
    hlp1(), False{})), "ok"),
    Bool.and(U64.is_eq(Ty.fa_gen(Ty.tres_fa(Ty.mk_face(
      sf_cy(), hlp1(), False{}))), 0u64),
      Bool.not(Ty.fa_same(Ty.tres_fa(Ty.mk_face(sf_cy(),
        hlp1(), False{})))))) == True{} : Bool}

def mk_fa_ok():
  {==}

law mk_fa_arm:
  {String.eq(Ty.tres_show(Ty.mk_face(cv_ln(), hlp1(),
    True{})), "invalid-input") == True{} : Bool}

def mk_fa_arm():
  {==}

law mk_fa_loops:
  {String.eq(Ty.tres_show(Ty.mk_face(sf_pl(), hlp0(),
    True{})), "invalid-input") == True{} : Bool}

def mk_fa_loops():
  {==}

law mk_sh_ok:
  {Bool.and(String.eq(Ty.tres_show(Ty.mk_shell(hfa1(),
    Ty.SK_inner{})), "ok"),
    Bool.and(U64.is_eq(Ty.sh_gen(Ty.tres_sh(Ty.mk_shell(
      hfa1(), Ty.SK_inner{}))), 0u64),
      U64.is_eq(Ty.skind_tag(Ty.sh_kind(Ty.tres_sh(
        Ty.mk_shell(hfa1(), Ty.SK_inner{})))), 1u64)))
    == True{} : Bool}

def mk_sh_ok():
  {==}

law mk_sh_nil:
  {String.eq(Ty.tres_show(Ty.mk_shell(hfa0(),
    Ty.SK_outer{})), "invalid-input") == True{} : Bool}

def mk_sh_nil():
  {==}

law mk_so_ok:
  {Bool.and(String.eq(Ty.tres_show(Ty.mk_solid(hsh_a(),
    hsh1())), "ok"),
    Bool.and(U64.is_eq(Ty.so_gen(Ty.tres_so(Ty.mk_solid(
      hsh_a(), hsh1()))), 0u64),
      Ty.so_has_cav(Ty.tres_so(Ty.mk_solid(hsh_a(),
        hsh1()))))) == True{} : Bool}

def mk_so_ok():
  {==}

law mk_cp_ok:
  {Bool.and(String.eq(Ty.tres_show(Ty.mk_compound(hso1(),
    hsh1())), "ok"),
    Bool.and(Ty.cp_has_solids(Ty.tres_cp(Ty.mk_compound(
      hso1(), hsh1()))),
      Ty.cp_has_shells(Ty.tres_cp(Ty.mk_compound(hso1(),
        hsh1()))))) == True{} : Bool}

def mk_cp_ok():
  {==}

law mk_brep_empty:
  {Bool.and(String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es0(),
    ces0(), lps0(), fas0(), shs0(), sos0(), top0(), 7u64,
    0n)), "ok"),
    U64.is_eq(Ty.brep_stamp(Ty.tres_brep(Ty.mk_brep(vs0(),
      es0(), ces0(), lps0(), fas0(), shs0(), sos0(),
      top0(), 7u64, 0n))), 7u64)) == True{} : Bool}

def mk_brep_empty():
  {==}

law mk_brep_full:
  {Bool.and(String.eq(Ty.tres_show(Ty.mk_brep(vs1(), es1(),
    ces1(), lps1(), fas1(), shs1(), sos1(), top1(), 61u64,
    8n)), "ok"),
    U64.is_eq(Ty.brep_stamp(Ty.tres_brep(Ty.mk_brep(vs1(),
      es1(), ces1(), lps1(), fas1(), shs1(), sos1(),
      top1(), 61u64, 8n))), 61u64)) == True{} : Bool}

def mk_brep_full():
  {==}

law mk_brep_vx:
  {String.eq(Ty.tres_show(Ty.mk_brep(vs_bad(), es0(),
    ces0(), lps0(), fas0(), shs0(), sos0(), top0(), 1u64,
    8n)), "invalid-input") == True{} : Bool}

def mk_brep_vx():
  {==}

law mk_brep_es_arm:
  {String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es_badarm(),
    ces0(), lps0(), fas0(), shs0(), sos0(), top0(), 11u64,
    8n)), "invalid-input") == True{} : Bool}

def mk_brep_es_arm():
  {==}

law mk_brep_es_degen:
  {String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es_baddegen(),
    ces0(), lps0(), fas0(), shs0(), sos0(), top0(), 11u64,
    8n)), "invalid-input") == True{} : Bool}

def mk_brep_es_degen():
  {==}

law mk_brep_ces:
  {String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es0(),
    ces_bad(), lps0(), fas0(), shs0(), sos0(), top0(),
    21u64, 8n)), "invalid-input") == True{} : Bool}

def mk_brep_ces():
  {==}

law mk_brep_lps:
  {String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es0(), ces0(),
    lps_bad(), fas0(), shs0(), sos0(), top0(), 31u64,
    8n)), "invalid-input") == True{} : Bool}

def mk_brep_lps():
  {==}

law mk_brep_fas_arm:
  {String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es0(), ces0(),
    lps0(), fas_badarm(), shs0(), sos0(), top0(), 41u64,
    8n)), "invalid-input") == True{} : Bool}

def mk_brep_fas_arm():
  {==}

law mk_brep_fas_loops:
  {String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es0(), ces0(),
    lps0(), fas_badloops(), shs0(), sos0(), top0(), 41u64,
    8n)), "invalid-input") == True{} : Bool}

def mk_brep_fas_loops():
  {==}

law mk_brep_shs:
  {String.eq(Ty.tres_show(Ty.mk_brep(vs0(), es0(), ces0(),
    lps0(), fas0(), shs_bad(), sos0(), top0(), 51u64,
    8n)), "invalid-input") == True{} : Bool}

def mk_brep_shs():
  {==}

law mk_brep_fuel:
  {String.eq(Ty.tres_show(Ty.mk_brep(vs1(), es0(), ces0(),
    lps0(), fas0(), shs0(), sos0(), top0(), 1u64, 0n)),
    "resource-exhausted") == True{} : Bool}

def mk_brep_fuel():
  {==}

law mk_brep_stamp:
  {String.eq(Ty.tres_show(Ty.mk_brep(vs1(), es0(), ces0(),
    lps0(), fas0(), shs0(), sos0(), top0(), 0u64, 8n)),
    "invalid-input") == True{} : Bool}

def mk_brep_stamp():
  {==}

law mk_brep_gen0:
  {String.eq(Ty.tres_show(Ty.mk_brep(vs_gen0(), es0(), ces0(),
    lps0(), fas0(), shs0(), sos0(), top0(), 1u64, 8n)),
    "invalid-input") == True{} : Bool}

def mk_brep_gen0():
  {==}

law mk_brep_dup:
  {String.eq(Ty.tres_show(Ty.mk_brep(vs_dup(), es0(), ces0(),
    lps0(), fas0(), shs0(), sos0(), top0(), 1u64, 8n)),
    "invalid-input") == True{} : Bool}

def mk_brep_dup():
  {==}

law gen_vs_ok:
  {Nat.is_eq(Ty.vs_gen_c(vs1(), 1u64, 8n), 3n) == True{} : Bool}

def gen_vs_ok():
  {==}

law gen_vs_stamp:
  {Nat.is_eq(Ty.vs_gen_c(vs1(), 0u64, 8n), 2n) == True{} : Bool}

def gen_vs_stamp():
  {==}

law gen_vs_zero:
  {Nat.is_eq(Ty.vs_gen_c(vs_gen0(), 1u64, 8n), 2n)
    == True{} : Bool}

def gen_vs_zero():
  {==}

law gen_vs_fuel:
  {Nat.is_eq(Ty.vs_gen_c(vs1(), 1u64, 0n), 0n) == True{} : Bool}

def gen_vs_fuel():
  {==}

law nodup_vs_ok:
  {Nat.is_eq(Ty.vs_nodup_c(vs2(), 8n), 3n) == True{} : Bool}

def nodup_vs_ok():
  {==}

law nodup_vs_dup:
  {Nat.is_eq(Ty.vs_nodup_c(vs_dup(), 8n), 2n) == True{} : Bool}

def nodup_vs_dup():
  {==}

law nodup_vs_fuel:
  {Nat.is_eq(Ty.vs_nodup_c(vs1(), 0n), 0n) == True{} : Bool}

def nodup_vs_fuel():
  {==}

law allc_vs0:
  {Nat.is_eq(Ty.vs_all_c(vs0(), 8n), 3n) == True{} : Bool}

def allc_vs0():
  {==}

law allc_vs1:
  {Nat.is_eq(Ty.vs_all_c(vs1(), 8n), 3n) == True{} : Bool}

def allc_vs1():
  {==}

law allc_vs2:
  {Nat.is_eq(Ty.vs_all_c(vs2(), 8n), 3n) == True{} : Bool}

def allc_vs2():
  {==}

law allc_vs_bad:
  {Nat.is_eq(Ty.vs_all_c(vs_bad(), 8n), 2n)
    == True{} : Bool}

def allc_vs_bad():
  {==}

law allc_vs_fuel:
  {Nat.is_eq(Ty.vs_all_c(vs1(), 0n), 0n) == True{} : Bool}

def allc_vs_fuel():
  {==}

law allc_es1:
  {Nat.is_eq(Ty.es_all_c(es1(), 8n), 3n) == True{} : Bool}

def allc_es1():
  {==}

law allc_ces1:
  {Nat.is_eq(Ty.ces_all_c(ces1(), 8n), 3n) == True{} : Bool}

def allc_ces1():
  {==}

law allc_lps1:
  {Nat.is_eq(Ty.lps_all_c(lps1(), 8n), 3n) == True{} : Bool}

def allc_lps1():
  {==}

law allc_fas1:
  {Nat.is_eq(Ty.fas_all_c(fas1(), 8n), 3n) == True{} : Bool}

def allc_fas1():
  {==}

law allc_shs1:
  {Nat.is_eq(Ty.shs_all_c(shs1(), 8n), 3n) == True{} : Bool}

def allc_shs1():
  {==}

law allc_sos1:
  {Nat.is_eq(Ty.sos_all_c(sos1(), 8n), 3n) == True{} : Bool}

def allc_sos1():
  {==}

law snoc_vx:
  {Nat.is_eq(Ty.tres_n(Ty.vx_len(Ty.vx_snoc(vs1(), vx_b()),
    8n)), 2n) == True{} : Bool}

def snoc_vx():
  {==}

law snoc_ed:
  {Nat.is_eq(Ty.tres_n(Ty.ed_len(Ty.ed_snoc(es1(), ed_b()),
    8n)), 2n) == True{} : Bool}

def snoc_ed():
  {==}

law empty_stamp:
  {U64.is_eq(Ty.brep_stamp(b_empty()), 0u64)
    == True{} : Bool}

def empty_stamp():
  {==}

law empty_top:
  {Bool.and(Bool.not(Ty.cp_has_solids(Ty.brep_top(
    b_empty()))),
    Bool.not(Ty.cp_has_shells(Ty.brep_top(b_empty()))))
    == True{} : Bool}

def empty_top():
  {==}

law empty_vs_len:
  {Nat.is_eq(Ty.tres_n(Ty.vx_len(Ty.brep_vs(b_empty()),
    8n)), 0n) == True{} : Bool}

def empty_vs_len():
  {==}

law set_top:
  {Bool.and(Ty.cp_has_solids(Ty.brep_top(Ty.brep_set_top(
    b_empty(), top1()))),
    Ty.cp_has_shells(Ty.brep_top(Ty.brep_set_top(
      b_empty(), top1())))) == True{} : Bool}

def set_top():
  {==}

law zero_curve:
  {ln_zero_bits(Ty.curve_zero()) == True{} : Bool}

def zero_curve():
  {==}

law zero_surf:
  {pl_zero_bits(Ty.surf_zero()) == True{} : Bool}

def zero_surf():
  {==}

law zero_trim:
  {ts_zero_bits(Ty.trim_zero()) == True{} : Bool}

def zero_trim():
  {==}

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

law vx_len2:
  {Nat.is_eq(Ty.tres_n(Ty.vx_len(vs2(), 8n)), 2n) == True{} : Bool}

def vx_len2():
  {==}

law vx_len0:
  {Nat.is_eq(Ty.tres_n(Ty.vx_len(vs0(), 8n)), 0n) == True{} : Bool}

def vx_len0():
  {==}

law vx_len_fuel:
  {String.eq(Ty.tres_show(Ty.vx_len(vs1(), 0n)), "resource-exhausted") == True{} : Bool}

def vx_len_fuel():
  {==}

law vx_at_gen:
  {U64.is_eq(Ty.vx_gen(v_at_vx()), 2u64) == True{} : Bool}

def vx_at_gen():
  {==}

law vx_at_headfree:
  {String.eq(Ty.tres_show(Ty.vx_at(vs1(), 0n, 0n)), "ok") == True{} : Bool}

def vx_at_headfree():
  {==}

law vx_at_oob:
  {String.eq(Ty.tres_show(Ty.vx_at(vs1(), 5n, 8n)), "invalid-input") == True{} : Bool}

def vx_at_oob():
  {==}

law vx_at_fuel:
  {String.eq(Ty.tres_show(Ty.vx_at(vs2(), 1n, 0n)), "resource-exhausted") == True{} : Bool}

def vx_at_fuel():
  {==}

law vx_res_ok:
  {Bool.and(String.eq(Ty.tres_show(r_res_vx()), "ok"),
    U64.is_eq(Ty.vx_gen(v_res_vx()), 2u64)) == True{} : Bool}

def vx_res_ok():
  {==}

law vx_res_stale:
  {String.eq(Ty.tres_show(Ty.vx_resolve(vs1(), Ty.mk_hv(0n, 99u64), 8n)), "invalid-input") == True{} : Bool}

def vx_res_stale():
  {==}

law vx_res_oob:
  {String.eq(Ty.tres_show(Ty.vx_resolve(vs1(), Ty.mk_hv(5n, 1u64), 8n)), "invalid-input") == True{} : Bool}

def vx_res_oob():
  {==}

law vx_res_fuel:
  {String.eq(Ty.tres_show(Ty.vx_resolve(vs2(), Ty.mk_hv(1n, 2u64), 0n)), "resource-exhausted") == True{} : Bool}

def vx_res_fuel():
  {==}

law vx_hof_idx:
  {Bool.and(Nat.is_eq(Ty.hv_idx(h_hof_vx()), 1n),
    U64.is_eq(Ty.hv_gen(h_hof_vx()), 2u64)) == True{} : Bool}

def vx_hof_idx():
  {==}

law vx_hof_unknown:
  {String.eq(Ty.tres_show(Ty.vx_handle_of(vs2(), 99u64, 8n)), "invalid-input") == True{} : Bool}

def vx_hof_unknown():
  {==}

law vx_hof_empty:
  {String.eq(Ty.tres_show(Ty.vx_handle_of(vs0(), 1u64, 8n)), "invalid-input") == True{} : Bool}

def vx_hof_empty():
  {==}

law vx_hof_fuel:
  {String.eq(Ty.tres_show(Ty.vx_handle_of(vs2(), 2u64, 0n)), "resource-exhausted") == True{} : Bool}

def vx_hof_fuel():
  {==}

law vx_hof_head0:
  {Nat.is_eq(Ty.hv_idx(Ty.tres_hv(Ty.vx_handle_of(vs1(), 1u64, 0n))), 0n) == True{} : Bool}

def vx_hof_head0():
  {==}

law vx_iss_idx:
  {Bool.and(Nat.is_eq(Ty.hv_idx(h_iss_vx()), 1n),
    U64.is_eq(Ty.hv_gen(h_iss_vx()), 2u64)) == True{} : Bool}

def vx_iss_idx():
  {==}

law vx_iss_fuel:
  {String.eq(Ty.tres_show(Ty.vx_issued(b_vs1(), 0n)), "resource-exhausted") == True{} : Bool}

def vx_iss_fuel():
  {==}

law vx_push_ok:
  {Bool.and(String.eq(Ty.tres_show(r_pvx()), "ok"),
    Bool.and(U64.is_eq(Ty.brep_stamp(b_pvx()), 1u64),
      Nat.is_eq(Ty.tres_n(Ty.vx_len(Ty.brep_vs(b_pvx()), 8n)), 1n))) == True{} : Bool}

def vx_push_ok():
  {==}

law vx_push_res:
  {String.eq(Ty.tres_show(Ty.vx_resolve(Ty.brep_vs(b_pvx()), Ty.mk_hv(0n, 1u64), 8n)), "ok") == True{} : Bool}

def vx_push_res():
  {==}

law vx_push_bad:
  {String.eq(Ty.tres_show(Ty.vx_push(b_empty(), pnan())), "invalid-input") == True{} : Bool}

def vx_push_bad():
  {==}

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

law ed_len2:
  {Nat.is_eq(Ty.tres_n(Ty.ed_len(es2(), 8n)), 2n) == True{} : Bool}

def ed_len2():
  {==}

law ed_len0:
  {Nat.is_eq(Ty.tres_n(Ty.ed_len(es0(), 8n)), 0n) == True{} : Bool}

def ed_len0():
  {==}

law ed_len_fuel:
  {String.eq(Ty.tres_show(Ty.ed_len(es1(), 0n)), "resource-exhausted") == True{} : Bool}

def ed_len_fuel():
  {==}

law ed_at_gen:
  {U64.is_eq(Ty.ed_gen(v_at_ed()), 12u64) == True{} : Bool}

def ed_at_gen():
  {==}

law ed_at_headfree:
  {String.eq(Ty.tres_show(Ty.ed_at(es1(), 0n, 0n)), "ok") == True{} : Bool}

def ed_at_headfree():
  {==}

law ed_at_oob:
  {String.eq(Ty.tres_show(Ty.ed_at(es1(), 5n, 8n)), "invalid-input") == True{} : Bool}

def ed_at_oob():
  {==}

law ed_at_fuel:
  {String.eq(Ty.tres_show(Ty.ed_at(es2(), 1n, 0n)), "resource-exhausted") == True{} : Bool}

def ed_at_fuel():
  {==}

law ed_res_ok:
  {Bool.and(String.eq(Ty.tres_show(r_res_ed()), "ok"),
    U64.is_eq(Ty.ed_gen(v_res_ed()), 12u64)) == True{} : Bool}

def ed_res_ok():
  {==}

law ed_res_stale:
  {String.eq(Ty.tres_show(Ty.ed_resolve(es1(), Ty.mk_he(0n, 99u64), 8n)), "invalid-input") == True{} : Bool}

def ed_res_stale():
  {==}

law ed_res_oob:
  {String.eq(Ty.tres_show(Ty.ed_resolve(es1(), Ty.mk_he(5n, 11u64), 8n)), "invalid-input") == True{} : Bool}

def ed_res_oob():
  {==}

law ed_res_fuel:
  {String.eq(Ty.tres_show(Ty.ed_resolve(es2(), Ty.mk_he(1n, 12u64), 0n)), "resource-exhausted") == True{} : Bool}

def ed_res_fuel():
  {==}

law ed_hof_idx:
  {Bool.and(Nat.is_eq(Ty.he_idx(h_hof_ed()), 1n),
    U64.is_eq(Ty.he_gen(h_hof_ed()), 12u64)) == True{} : Bool}

def ed_hof_idx():
  {==}

law ed_hof_unknown:
  {String.eq(Ty.tres_show(Ty.ed_handle_of(es2(), 99u64, 8n)), "invalid-input") == True{} : Bool}

def ed_hof_unknown():
  {==}

law ed_hof_empty:
  {String.eq(Ty.tres_show(Ty.ed_handle_of(es0(), 11u64, 8n)), "invalid-input") == True{} : Bool}

def ed_hof_empty():
  {==}

law ed_hof_fuel:
  {String.eq(Ty.tres_show(Ty.ed_handle_of(es2(), 12u64, 0n)), "resource-exhausted") == True{} : Bool}

def ed_hof_fuel():
  {==}

law ed_hof_head0:
  {Nat.is_eq(Ty.he_idx(Ty.tres_he(Ty.ed_handle_of(es1(), 11u64, 0n))), 0n) == True{} : Bool}

def ed_hof_head0():
  {==}

law ed_iss_idx:
  {Bool.and(Nat.is_eq(Ty.he_idx(h_iss_ed()), 1n),
    U64.is_eq(Ty.he_gen(h_iss_ed()), 12u64)) == True{} : Bool}

def ed_iss_idx():
  {==}

law ed_iss_fuel:
  {String.eq(Ty.tres_show(Ty.ed_issued(b_es1(), 0n)), "resource-exhausted") == True{} : Bool}

def ed_iss_fuel():
  {==}

law ed_push_ok:
  {Bool.and(String.eq(Ty.tres_show(r_ped()), "ok"),
    Bool.and(U64.is_eq(Ty.brep_stamp(b_ped()), 1u64),
      Nat.is_eq(Ty.tres_n(Ty.ed_len(Ty.brep_es(b_ped()), 8n)), 1n))) == True{} : Bool}

def ed_push_ok():
  {==}

law ed_push_res:
  {String.eq(Ty.tres_show(Ty.ed_resolve(Ty.brep_es(b_ped()), Ty.mk_he(0n, 1u64), 8n)), "ok") == True{} : Bool}

def ed_push_res():
  {==}

law ed_push_arm:
  {String.eq(Ty.tres_show(Ty.ed_push(b_empty(), hv01(), hv12(), Ty.EK_curve{sf_pl(), dom_01()})), "invalid-input") == True{} : Bool}

def ed_push_arm():
  {==}

law ed_push_degen:
  {String.eq(Ty.tres_show(Ty.ed_push(b_empty(), hv01(), hv12(), Ty.EK_degenerate{})), "invalid-input") == True{} : Bool}

def ed_push_degen():
  {==}

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

law ce_len2:
  {Nat.is_eq(Ty.tres_n(Ty.ce_len(ces2(), 8n)), 2n) == True{} : Bool}

def ce_len2():
  {==}

law ce_len0:
  {Nat.is_eq(Ty.tres_n(Ty.ce_len(ces0(), 8n)), 0n) == True{} : Bool}

def ce_len0():
  {==}

law ce_len_fuel:
  {String.eq(Ty.tres_show(Ty.ce_len(ces1(), 0n)), "resource-exhausted") == True{} : Bool}

def ce_len_fuel():
  {==}

law ce_at_gen:
  {U64.is_eq(Ty.ce_gen(v_at_ce()), 22u64) == True{} : Bool}

def ce_at_gen():
  {==}

law ce_at_headfree:
  {String.eq(Ty.tres_show(Ty.ce_at(ces1(), 0n, 0n)), "ok") == True{} : Bool}

def ce_at_headfree():
  {==}

law ce_at_oob:
  {String.eq(Ty.tres_show(Ty.ce_at(ces1(), 5n, 8n)), "invalid-input") == True{} : Bool}

def ce_at_oob():
  {==}

law ce_at_fuel:
  {String.eq(Ty.tres_show(Ty.ce_at(ces2(), 1n, 0n)), "resource-exhausted") == True{} : Bool}

def ce_at_fuel():
  {==}

law ce_res_ok:
  {Bool.and(String.eq(Ty.tres_show(r_res_ce()), "ok"),
    U64.is_eq(Ty.ce_gen(v_res_ce()), 22u64)) == True{} : Bool}

def ce_res_ok():
  {==}

law ce_res_stale:
  {String.eq(Ty.tres_show(Ty.ce_resolve(ces1(), Ty.mk_hc(0n, 99u64), 8n)), "invalid-input") == True{} : Bool}

def ce_res_stale():
  {==}

law ce_res_oob:
  {String.eq(Ty.tres_show(Ty.ce_resolve(ces1(), Ty.mk_hc(5n, 21u64), 8n)), "invalid-input") == True{} : Bool}

def ce_res_oob():
  {==}

law ce_res_fuel:
  {String.eq(Ty.tres_show(Ty.ce_resolve(ces2(), Ty.mk_hc(1n, 22u64), 0n)), "resource-exhausted") == True{} : Bool}

def ce_res_fuel():
  {==}

law ce_hof_idx:
  {Bool.and(Nat.is_eq(Ty.hc_idx(h_hof_ce()), 1n),
    U64.is_eq(Ty.hc_gen(h_hof_ce()), 22u64)) == True{} : Bool}

def ce_hof_idx():
  {==}

law ce_hof_unknown:
  {String.eq(Ty.tres_show(Ty.ce_handle_of(ces2(), 99u64, 8n)), "invalid-input") == True{} : Bool}

def ce_hof_unknown():
  {==}

law ce_hof_empty:
  {String.eq(Ty.tres_show(Ty.ce_handle_of(ces0(), 21u64, 8n)), "invalid-input") == True{} : Bool}

def ce_hof_empty():
  {==}

law ce_hof_fuel:
  {String.eq(Ty.tres_show(Ty.ce_handle_of(ces2(), 22u64, 0n)), "resource-exhausted") == True{} : Bool}

def ce_hof_fuel():
  {==}

law ce_hof_head0:
  {Nat.is_eq(Ty.hc_idx(Ty.tres_hc(Ty.ce_handle_of(ces1(), 21u64, 0n))), 0n) == True{} : Bool}

def ce_hof_head0():
  {==}

law ce_iss_idx:
  {Bool.and(Nat.is_eq(Ty.hc_idx(h_iss_ce()), 1n),
    U64.is_eq(Ty.hc_gen(h_iss_ce()), 22u64)) == True{} : Bool}

def ce_iss_idx():
  {==}

law ce_iss_fuel:
  {String.eq(Ty.tres_show(Ty.ce_issued(b_ces1(), 0n)), "resource-exhausted") == True{} : Bool}

def ce_iss_fuel():
  {==}

law ce_push_ok:
  {Bool.and(String.eq(Ty.tres_show(r_pce()), "ok"),
    Bool.and(U64.is_eq(Ty.brep_stamp(b_pce()), 1u64),
      Nat.is_eq(Ty.tres_n(Ty.ce_len(Ty.brep_ces(b_pce()), 8n)), 1n))) == True{} : Bool}

def ce_push_ok():
  {==}

law ce_push_res:
  {String.eq(Ty.tres_show(Ty.ce_resolve(Ty.brep_ces(b_pce()), Ty.mk_hc(0n, 1u64), 8n)), "ok") == True{} : Bool}

def ce_push_res():
  {==}

law ce_push_trim:
  {String.eq(Ty.tres_show(Ty.ce_push(b_empty(), he01(), True{}, cv_ln())), "invalid-input") == True{} : Bool}

def ce_push_trim():
  {==}

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

law lp_len2:
  {Nat.is_eq(Ty.tres_n(Ty.lp_len(lps2(), 8n)), 2n) == True{} : Bool}

def lp_len2():
  {==}

law lp_len0:
  {Nat.is_eq(Ty.tres_n(Ty.lp_len(lps0(), 8n)), 0n) == True{} : Bool}

def lp_len0():
  {==}

law lp_len_fuel:
  {String.eq(Ty.tres_show(Ty.lp_len(lps1(), 0n)), "resource-exhausted") == True{} : Bool}

def lp_len_fuel():
  {==}

law lp_at_gen:
  {U64.is_eq(Ty.lp_gen(v_at_lp()), 32u64) == True{} : Bool}

def lp_at_gen():
  {==}

law lp_at_headfree:
  {String.eq(Ty.tres_show(Ty.lp_at(lps1(), 0n, 0n)), "ok") == True{} : Bool}

def lp_at_headfree():
  {==}

law lp_at_oob:
  {String.eq(Ty.tres_show(Ty.lp_at(lps1(), 5n, 8n)), "invalid-input") == True{} : Bool}

def lp_at_oob():
  {==}

law lp_at_fuel:
  {String.eq(Ty.tres_show(Ty.lp_at(lps2(), 1n, 0n)), "resource-exhausted") == True{} : Bool}

def lp_at_fuel():
  {==}

law lp_res_ok:
  {Bool.and(String.eq(Ty.tres_show(r_res_lp()), "ok"),
    U64.is_eq(Ty.lp_gen(v_res_lp()), 32u64)) == True{} : Bool}

def lp_res_ok():
  {==}

law lp_res_stale:
  {String.eq(Ty.tres_show(Ty.lp_resolve(lps1(), Ty.mk_hlp(0n, 99u64), 8n)), "invalid-input") == True{} : Bool}

def lp_res_stale():
  {==}

law lp_res_oob:
  {String.eq(Ty.tres_show(Ty.lp_resolve(lps1(), Ty.mk_hlp(5n, 31u64), 8n)), "invalid-input") == True{} : Bool}

def lp_res_oob():
  {==}

law lp_res_fuel:
  {String.eq(Ty.tres_show(Ty.lp_resolve(lps2(), Ty.mk_hlp(1n, 32u64), 0n)), "resource-exhausted") == True{} : Bool}

def lp_res_fuel():
  {==}

law lp_hof_idx:
  {Bool.and(Nat.is_eq(Ty.hlp_idx(h_hof_lp()), 1n),
    U64.is_eq(Ty.hlp_gen(h_hof_lp()), 32u64)) == True{} : Bool}

def lp_hof_idx():
  {==}

law lp_hof_unknown:
  {String.eq(Ty.tres_show(Ty.lp_handle_of(lps2(), 99u64, 8n)), "invalid-input") == True{} : Bool}

def lp_hof_unknown():
  {==}

law lp_hof_empty:
  {String.eq(Ty.tres_show(Ty.lp_handle_of(lps0(), 31u64, 8n)), "invalid-input") == True{} : Bool}

def lp_hof_empty():
  {==}

law lp_hof_fuel:
  {String.eq(Ty.tres_show(Ty.lp_handle_of(lps2(), 32u64, 0n)), "resource-exhausted") == True{} : Bool}

def lp_hof_fuel():
  {==}

law lp_hof_head0:
  {Nat.is_eq(Ty.hlp_idx(Ty.tres_hlp(Ty.lp_handle_of(lps1(), 31u64, 0n))), 0n) == True{} : Bool}

def lp_hof_head0():
  {==}

law lp_iss_idx:
  {Bool.and(Nat.is_eq(Ty.hlp_idx(h_iss_lp()), 1n),
    U64.is_eq(Ty.hlp_gen(h_iss_lp()), 32u64)) == True{} : Bool}

def lp_iss_idx():
  {==}

law lp_iss_fuel:
  {String.eq(Ty.tres_show(Ty.lp_issued(b_lps1(), 0n)), "resource-exhausted") == True{} : Bool}

def lp_iss_fuel():
  {==}

law lp_push_ok:
  {Bool.and(String.eq(Ty.tres_show(r_plp()), "ok"),
    Bool.and(U64.is_eq(Ty.brep_stamp(b_plp()), 1u64),
      Nat.is_eq(Ty.tres_n(Ty.lp_len(Ty.brep_lps(b_plp()), 8n)), 1n))) == True{} : Bool}

def lp_push_ok():
  {==}

law lp_push_res:
  {String.eq(Ty.tres_show(Ty.lp_resolve(Ty.brep_lps(b_plp()), Ty.mk_hlp(0n, 1u64), 8n)), "ok") == True{} : Bool}

def lp_push_res():
  {==}

law lp_push_nil:
  {String.eq(Ty.tres_show(Ty.lp_push(b_empty(), hce0(), Ty.LK_outer{})), "invalid-input") == True{} : Bool}

def lp_push_nil():
  {==}

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

law fa_len2:
  {Nat.is_eq(Ty.tres_n(Ty.fa_len(fas2(), 8n)), 2n) == True{} : Bool}

def fa_len2():
  {==}

law fa_len0:
  {Nat.is_eq(Ty.tres_n(Ty.fa_len(fas0(), 8n)), 0n) == True{} : Bool}

def fa_len0():
  {==}

law fa_len_fuel:
  {String.eq(Ty.tres_show(Ty.fa_len(fas1(), 0n)), "resource-exhausted") == True{} : Bool}

def fa_len_fuel():
  {==}

law fa_at_gen:
  {U64.is_eq(Ty.fa_gen(v_at_fa()), 42u64) == True{} : Bool}

def fa_at_gen():
  {==}

law fa_at_headfree:
  {String.eq(Ty.tres_show(Ty.fa_at(fas1(), 0n, 0n)), "ok") == True{} : Bool}

def fa_at_headfree():
  {==}

law fa_at_oob:
  {String.eq(Ty.tres_show(Ty.fa_at(fas1(), 5n, 8n)), "invalid-input") == True{} : Bool}

def fa_at_oob():
  {==}

law fa_at_fuel:
  {String.eq(Ty.tres_show(Ty.fa_at(fas2(), 1n, 0n)), "resource-exhausted") == True{} : Bool}

def fa_at_fuel():
  {==}

law fa_res_ok:
  {Bool.and(String.eq(Ty.tres_show(r_res_fa()), "ok"),
    U64.is_eq(Ty.fa_gen(v_res_fa()), 42u64)) == True{} : Bool}

def fa_res_ok():
  {==}

law fa_res_stale:
  {String.eq(Ty.tres_show(Ty.fa_resolve(fas1(), Ty.mk_hfa(0n, 99u64), 8n)), "invalid-input") == True{} : Bool}

def fa_res_stale():
  {==}

law fa_res_oob:
  {String.eq(Ty.tres_show(Ty.fa_resolve(fas1(), Ty.mk_hfa(5n, 41u64), 8n)), "invalid-input") == True{} : Bool}

def fa_res_oob():
  {==}

law fa_res_fuel:
  {String.eq(Ty.tres_show(Ty.fa_resolve(fas2(), Ty.mk_hfa(1n, 42u64), 0n)), "resource-exhausted") == True{} : Bool}

def fa_res_fuel():
  {==}

law fa_hof_idx:
  {Bool.and(Nat.is_eq(Ty.hfa_idx(h_hof_fa()), 1n),
    U64.is_eq(Ty.hfa_gen(h_hof_fa()), 42u64)) == True{} : Bool}

def fa_hof_idx():
  {==}

law fa_hof_unknown:
  {String.eq(Ty.tres_show(Ty.fa_handle_of(fas2(), 99u64, 8n)), "invalid-input") == True{} : Bool}

def fa_hof_unknown():
  {==}

law fa_hof_empty:
  {String.eq(Ty.tres_show(Ty.fa_handle_of(fas0(), 41u64, 8n)), "invalid-input") == True{} : Bool}

def fa_hof_empty():
  {==}

law fa_hof_fuel:
  {String.eq(Ty.tres_show(Ty.fa_handle_of(fas2(), 42u64, 0n)), "resource-exhausted") == True{} : Bool}

def fa_hof_fuel():
  {==}

law fa_hof_head0:
  {Nat.is_eq(Ty.hfa_idx(Ty.tres_hfa(Ty.fa_handle_of(fas1(), 41u64, 0n))), 0n) == True{} : Bool}

def fa_hof_head0():
  {==}

law fa_iss_idx:
  {Bool.and(Nat.is_eq(Ty.hfa_idx(h_iss_fa()), 1n),
    U64.is_eq(Ty.hfa_gen(h_iss_fa()), 42u64)) == True{} : Bool}

def fa_iss_idx():
  {==}

law fa_iss_fuel:
  {String.eq(Ty.tres_show(Ty.fa_issued(b_fas1(), 0n)), "resource-exhausted") == True{} : Bool}

def fa_iss_fuel():
  {==}

law fa_push_ok:
  {Bool.and(String.eq(Ty.tres_show(r_pfa()), "ok"),
    Bool.and(U64.is_eq(Ty.brep_stamp(b_pfa()), 1u64),
      Nat.is_eq(Ty.tres_n(Ty.fa_len(Ty.brep_fas(b_pfa()), 8n)), 1n))) == True{} : Bool}

def fa_push_ok():
  {==}

law fa_push_res:
  {String.eq(Ty.tres_show(Ty.fa_resolve(Ty.brep_fas(b_pfa()), Ty.mk_hfa(0n, 1u64), 8n)), "ok") == True{} : Bool}

def fa_push_res():
  {==}

law fa_push_arm:
  {String.eq(Ty.tres_show(Ty.fa_push(b_empty(), cv_ln(), hlp1(), True{})), "invalid-input") == True{} : Bool}

def fa_push_arm():
  {==}

law fa_push_loops:
  {String.eq(Ty.tres_show(Ty.fa_push(b_empty(), sf_pl(), hlp0(), True{})), "invalid-input") == True{} : Bool}

def fa_push_loops():
  {==}

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

law sh_len2:
  {Nat.is_eq(Ty.tres_n(Ty.sh_len(shs2(), 8n)), 2n) == True{} : Bool}

def sh_len2():
  {==}

law sh_len0:
  {Nat.is_eq(Ty.tres_n(Ty.sh_len(shs0(), 8n)), 0n) == True{} : Bool}

def sh_len0():
  {==}

law sh_len_fuel:
  {String.eq(Ty.tres_show(Ty.sh_len(shs1(), 0n)), "resource-exhausted") == True{} : Bool}

def sh_len_fuel():
  {==}

law sh_at_gen:
  {U64.is_eq(Ty.sh_gen(v_at_sh()), 52u64) == True{} : Bool}

def sh_at_gen():
  {==}

law sh_at_headfree:
  {String.eq(Ty.tres_show(Ty.sh_at(shs1(), 0n, 0n)), "ok") == True{} : Bool}

def sh_at_headfree():
  {==}

law sh_at_oob:
  {String.eq(Ty.tres_show(Ty.sh_at(shs1(), 5n, 8n)), "invalid-input") == True{} : Bool}

def sh_at_oob():
  {==}

law sh_at_fuel:
  {String.eq(Ty.tres_show(Ty.sh_at(shs2(), 1n, 0n)), "resource-exhausted") == True{} : Bool}

def sh_at_fuel():
  {==}

law sh_res_ok:
  {Bool.and(String.eq(Ty.tres_show(r_res_sh()), "ok"),
    U64.is_eq(Ty.sh_gen(v_res_sh()), 52u64)) == True{} : Bool}

def sh_res_ok():
  {==}

law sh_res_stale:
  {String.eq(Ty.tres_show(Ty.sh_resolve(shs1(), Ty.mk_hsh(0n, 99u64), 8n)), "invalid-input") == True{} : Bool}

def sh_res_stale():
  {==}

law sh_res_oob:
  {String.eq(Ty.tres_show(Ty.sh_resolve(shs1(), Ty.mk_hsh(5n, 51u64), 8n)), "invalid-input") == True{} : Bool}

def sh_res_oob():
  {==}

law sh_res_fuel:
  {String.eq(Ty.tres_show(Ty.sh_resolve(shs2(), Ty.mk_hsh(1n, 52u64), 0n)), "resource-exhausted") == True{} : Bool}

def sh_res_fuel():
  {==}

law sh_hof_idx:
  {Bool.and(Nat.is_eq(Ty.hsh_idx(h_hof_sh()), 1n),
    U64.is_eq(Ty.hsh_gen(h_hof_sh()), 52u64)) == True{} : Bool}

def sh_hof_idx():
  {==}

law sh_hof_unknown:
  {String.eq(Ty.tres_show(Ty.sh_handle_of(shs2(), 99u64, 8n)), "invalid-input") == True{} : Bool}

def sh_hof_unknown():
  {==}

law sh_hof_empty:
  {String.eq(Ty.tres_show(Ty.sh_handle_of(shs0(), 51u64, 8n)), "invalid-input") == True{} : Bool}

def sh_hof_empty():
  {==}

law sh_hof_fuel:
  {String.eq(Ty.tres_show(Ty.sh_handle_of(shs2(), 52u64, 0n)), "resource-exhausted") == True{} : Bool}

def sh_hof_fuel():
  {==}

law sh_hof_head0:
  {Nat.is_eq(Ty.hsh_idx(Ty.tres_hsh(Ty.sh_handle_of(shs1(), 51u64, 0n))), 0n) == True{} : Bool}

def sh_hof_head0():
  {==}

law sh_iss_idx:
  {Bool.and(Nat.is_eq(Ty.hsh_idx(h_iss_sh()), 1n),
    U64.is_eq(Ty.hsh_gen(h_iss_sh()), 52u64)) == True{} : Bool}

def sh_iss_idx():
  {==}

law sh_iss_fuel:
  {String.eq(Ty.tres_show(Ty.sh_issued(b_shs1(), 0n)), "resource-exhausted") == True{} : Bool}

def sh_iss_fuel():
  {==}

law sh_push_ok:
  {Bool.and(String.eq(Ty.tres_show(r_psh()), "ok"),
    Bool.and(U64.is_eq(Ty.brep_stamp(b_psh()), 1u64),
      Nat.is_eq(Ty.tres_n(Ty.sh_len(Ty.brep_shs(b_psh()), 8n)), 1n))) == True{} : Bool}

def sh_push_ok():
  {==}

law sh_push_res:
  {String.eq(Ty.tres_show(Ty.sh_resolve(Ty.brep_shs(b_psh()), Ty.mk_hsh(0n, 1u64), 8n)), "ok") == True{} : Bool}

def sh_push_res():
  {==}

law sh_push_nil:
  {String.eq(Ty.tres_show(Ty.sh_push(b_empty(), hfa0(), Ty.SK_outer{})), "invalid-input") == True{} : Bool}

def sh_push_nil():
  {==}

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

law so_len2:
  {Nat.is_eq(Ty.tres_n(Ty.so_len(sos2(), 8n)), 2n) == True{} : Bool}

def so_len2():
  {==}

law so_len0:
  {Nat.is_eq(Ty.tres_n(Ty.so_len(sos0(), 8n)), 0n) == True{} : Bool}

def so_len0():
  {==}

law so_len_fuel:
  {String.eq(Ty.tres_show(Ty.so_len(sos1(), 0n)), "resource-exhausted") == True{} : Bool}

def so_len_fuel():
  {==}

law so_at_gen:
  {U64.is_eq(Ty.so_gen(v_at_so()), 62u64) == True{} : Bool}

def so_at_gen():
  {==}

law so_at_headfree:
  {String.eq(Ty.tres_show(Ty.so_at(sos1(), 0n, 0n)), "ok") == True{} : Bool}

def so_at_headfree():
  {==}

law so_at_oob:
  {String.eq(Ty.tres_show(Ty.so_at(sos1(), 5n, 8n)), "invalid-input") == True{} : Bool}

def so_at_oob():
  {==}

law so_at_fuel:
  {String.eq(Ty.tres_show(Ty.so_at(sos2(), 1n, 0n)), "resource-exhausted") == True{} : Bool}

def so_at_fuel():
  {==}

law so_res_ok:
  {Bool.and(String.eq(Ty.tres_show(r_res_so()), "ok"),
    U64.is_eq(Ty.so_gen(v_res_so()), 62u64)) == True{} : Bool}

def so_res_ok():
  {==}

law so_res_stale:
  {String.eq(Ty.tres_show(Ty.so_resolve(sos1(), Ty.mk_hso(0n, 99u64), 8n)), "invalid-input") == True{} : Bool}

def so_res_stale():
  {==}

law so_res_oob:
  {String.eq(Ty.tres_show(Ty.so_resolve(sos1(), Ty.mk_hso(5n, 61u64), 8n)), "invalid-input") == True{} : Bool}

def so_res_oob():
  {==}

law so_res_fuel:
  {String.eq(Ty.tres_show(Ty.so_resolve(sos2(), Ty.mk_hso(1n, 62u64), 0n)), "resource-exhausted") == True{} : Bool}

def so_res_fuel():
  {==}

law so_hof_idx:
  {Bool.and(Nat.is_eq(Ty.hso_idx(h_hof_so()), 1n),
    U64.is_eq(Ty.hso_gen(h_hof_so()), 62u64)) == True{} : Bool}

def so_hof_idx():
  {==}

law so_hof_unknown:
  {String.eq(Ty.tres_show(Ty.so_handle_of(sos2(), 99u64, 8n)), "invalid-input") == True{} : Bool}

def so_hof_unknown():
  {==}

law so_hof_empty:
  {String.eq(Ty.tres_show(Ty.so_handle_of(sos0(), 61u64, 8n)), "invalid-input") == True{} : Bool}

def so_hof_empty():
  {==}

law so_hof_fuel:
  {String.eq(Ty.tres_show(Ty.so_handle_of(sos2(), 62u64, 0n)), "resource-exhausted") == True{} : Bool}

def so_hof_fuel():
  {==}

law so_hof_head0:
  {Nat.is_eq(Ty.hso_idx(Ty.tres_hso(Ty.so_handle_of(sos1(), 61u64, 0n))), 0n) == True{} : Bool}

def so_hof_head0():
  {==}

law so_iss_idx:
  {Bool.and(Nat.is_eq(Ty.hso_idx(h_iss_so()), 1n),
    U64.is_eq(Ty.hso_gen(h_iss_so()), 62u64)) == True{} : Bool}

def so_iss_idx():
  {==}

law so_iss_fuel:
  {String.eq(Ty.tres_show(Ty.so_issued(b_sos1(), 0n)), "resource-exhausted") == True{} : Bool}

def so_iss_fuel():
  {==}

law so_push_ok:
  {Bool.and(String.eq(Ty.tres_show(r_pso()), "ok"),
    Bool.and(U64.is_eq(Ty.brep_stamp(b_pso()), 1u64),
      Nat.is_eq(Ty.tres_n(Ty.so_len(Ty.brep_sos(b_pso()), 8n)), 1n))) == True{} : Bool}

def so_push_ok():
  {==}

law so_push_res:
  {String.eq(Ty.tres_show(Ty.so_resolve(Ty.brep_sos(b_pso()), Ty.mk_hso(0n, 1u64), 8n)), "ok") == True{} : Bool}

def so_push_res():
  {==}

law so_push_cav:
  {Ty.so_has_cav(Ty.tres_so(Ty.so_at(Ty.brep_sos(Ty.tres_brep(
    Ty.so_push(b_empty(), hsh_a(), hsh1()))), 0n, 8n)))
    == True{} : Bool}

def so_push_cav():
  {==}

law hsh_nd_empty:
  {Nat.is_eq(Op.hsh_nodup_c(hsh0(), 8n), 3n) == True{} : Bool}

def hsh_nd_empty():
  {==}

law hsh_nd_single:
  {Nat.is_eq(Op.hsh_nodup_c(hsh1(), 8n), 3n) == True{} : Bool}

def hsh_nd_single():
  {==}

law hsh_nd_dup:
  {Nat.is_eq(Op.hsh_nodup_c(hsh_a() <> hsh_a() <> Nil{}, 8n), 2n)
    == True{} : Bool}

def hsh_nd_dup():
  {==}

law hsh_nd_fuel:
  {Nat.is_eq(Op.hsh_nodup_c(hsh1(), 0n), 0n) == True{} : Bool}

def hsh_nd_fuel():
  {==}

law hsh_fo_absent:
  {Nat.is_eq(Op.hsh_nodup_c(hsh_a() <> Ty.mk_hsh(1n, 52u64) <> Nil{},
    8n), 3n) == True{} : Bool}

def hsh_fo_absent():
  {==}

law hsh_fo_hit:
  {Nat.is_eq(Op.hsh_nodup_c(hsh_a() <> hsh1(), 8n), 2n)
    == True{} : Bool}

def hsh_fo_hit():
  {==}

law so_shl_single:
  {Nat.is_eq(Op.hsh_nodup_c(Op.so_sh_list(so_a()), 8n), 3n)
    == True{} : Bool}

def so_shl_single():
  {==}

law so_shl_alias:
  {Nat.is_eq(Op.hsh_nodup_c(Op.so_sh_list(so_b()), 8n), 2n)
    == True{} : Bool}

def so_shl_alias():
  {==}

law outer_kind_ok:
  {Nat.is_eq(Op.sos_outer_kind_c(sos1(), shs1(), 8n, 8n), 3n)
    == True{} : Bool}

def outer_kind_ok():
  {==}

law outer_kind_bad:
  {Nat.is_eq(Op.sos_outer_kind_c(
    Ty.So{61u64, Ty.mk_hsh(1n, 52u64), hsh0()} <> Nil{},
    shs2(), 8n, 8n), 2n) == True{} : Bool}

def outer_kind_bad():
  {==}

law outer_kind_fuel:
  {Nat.is_eq(Op.sos_outer_kind_c(sos1(), shs1(), 0n, 8n), 0n)
    == True{} : Bool}

def outer_kind_fuel():
  {==}

law own_single_ok:
  {Nat.is_eq(Op.sos_own_c(sos1(), 8n, 8n), 3n) == True{} : Bool}

def own_single_ok():
  {==}

law own_alias_no:
  {Nat.is_eq(Op.sos_own_c(so_b() <> Nil{}, 8n, 8n), 2n)
    == True{} : Bool}

def own_alias_no():
  {==}

law own_reuse_no:
  {Nat.is_eq(Op.sos_own_c(so_a() <> so_a() <> Nil{}, 8n, 8n),
    2n) == True{} : Bool}

def own_reuse_no():
  {==}

law own_fuel:
  {Nat.is_eq(Op.sos_own_c(sos1(), 0n, 8n), 0n) == True{} : Bool}

def own_fuel():
  {==}

law cpown_disjoint_ok:
  {Nat.is_eq(Op.cp_sh_own_c(top0(), sos1(), 8n), 3n)
    == True{} : Bool}

def cpown_disjoint_ok():
  {==}

law cpown_share_no:
  {Nat.is_eq(Op.cp_sh_own_c(Ty.Cp{hso0(), hsh1()}, sos1(), 8n),
    2n) == True{} : Bool}

def cpown_share_no():
  {==}

law cpown_dup_no:
  {Nat.is_eq(Op.cp_sh_own_c(
    Ty.Cp{hso0(), hsh_a() <> hsh_a() <> Nil{}}, sos0(), 8n),
    2n) == True{} : Bool}

def cpown_dup_no():
  {==}

law hlf_absent:
  {Op.hks_distinct(Op.hss_keys(Ty.mk_hsh(1n, 52u64) <> Nil{},
    Op.hss_keys(hsh1(), Nil{}))) == True{} : Bool}

def hlf_absent():
  {==}

law hlf_hit:
  {Op.hks_distinct(Op.hss_keys(hsh1(), Op.hss_keys(hsh1(), Nil{})))
    == False{} : Bool}

def hlf_hit():
  {==}

law hfos_absent:
  {Op.hks_distinct(Op.hss_keys(hsh0(),
    Op.hks_sorted_uniq(Op.sos_skeys(sos1(), Nil{}))))
    == True{} : Bool}

def hfos_absent():
  {==}

law hfos_hit:
  {Op.hks_distinct(Op.hss_keys(hsh1(),
    Op.hks_sorted_uniq(Op.sos_skeys(sos1(), Nil{}))))
    == False{} : Bool}

def hfos_hit():
  {==}

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

law ck_sphere:
  {String.eq(Ty.tres_show(Op.brep_checked(b_sphere_digon_control(),
    Ty.P_manifold_solid{}, 12n)), "ok") == True{} : Bool}

def ck_sphere():
  {==}

law ck_cyl:
  {String.eq(Ty.tres_show(Op.brep_checked(b_cyl_digon_ruling_control(),
    Ty.P_manifold_solid{}, 12n)), "ok") == True{} : Bool}

def ck_cyl():
  {==}

law ck_cav:
  {String.eq(Ty.tres_show(Op.brep_checked(b_cav(),
    Ty.P_manifold_solid{}, 20n)), "ok") == True{} : Bool}

def ck_cav():
  {==}

law ck_open:
  {String.eq(Ty.tres_show(Op.brep_checked(b_open(),
    Ty.P_open_shell{}, 12n)), "ok") == True{} : Bool}

def ck_open():
  {==}

law ck_pole:
  {String.eq(Ty.tres_show(Op.brep_checked(b_pole(),
    Ty.P_manifold_solid{}, 12n)), "ok") == True{} : Bool}

def ck_pole():
  {==}

law ck_dang:
  {String.eq(Ty.tres_show(Op.brep_checked(b_dang(),
    Ty.P_manifold_solid{}, 12n)), "invalid-input") == True{} : Bool}

def ck_dang():
  {==}

law ck_inv:
  {String.eq(Ty.tres_show(Op.brep_checked(b_inv(),
    Ty.P_manifold_solid{}, 12n)), "invalid-input") == True{} : Bool}

def ck_inv():
  {==}

law ck_trimx:
  {String.eq(Ty.tres_show(Op.brep_checked(b_trimx(),
    Ty.P_manifold_solid{}, 12n)), "invalid-input") == True{} : Bool}

def ck_trimx():
  {==}

law ck_embx:
  {String.eq(Ty.tres_show(Op.brep_checked(b_embx(),
    Ty.P_manifold_solid{}, 12n)), "invalid-input") == True{} : Bool}

def ck_embx():
  {==}

law ck_nonm:
  {String.eq(Ty.tres_show(Op.brep_checked(b_nonm(),
    Ty.P_manifold_solid{}, 12n)), "invalid-input") == True{} : Bool}

def ck_nonm():
  {==}

law ck_selfx:
  {String.eq(Ty.tres_show(Op.brep_checked(b_selfx(),
    Ty.P_manifold_solid{}, 12n)), "invalid-input") == True{} : Bool}

def ck_selfx():
  {==}

law ck_open_solid:
  {String.eq(Ty.tres_show(Op.brep_checked(b_open(),
    Ty.P_manifold_solid{}, 12n)), "invalid-input") == True{} : Bool}

def ck_open_solid():
  {==}

law ck_fuel:
  {String.eq(Ty.tres_show(Op.brep_checked(b_sphere_digon_control(),
    Ty.P_manifold_solid{}, 0n)), "resource-exhausted")
    == True{} : Bool}

def ck_fuel():
  {==}

law ck_fuel_ix:
  {Bool.and(Nat.is_eq(Ty.ix_bound(b_fuel_gap()), 2n),
    Bool.and(Nat.is_eq(Ty.ix_bound(b_sphere_digon_control()), 2n),
    Bool.and(String.eq(Ty.tres_show(Ty.mk_brep(Ty.brep_vs(b_fuel_gap()),
      Ty.brep_es(b_fuel_gap()), Ty.brep_ces(b_fuel_gap()),
      Ty.brep_lps(b_fuel_gap()), Ty.brep_fas(b_fuel_gap()),
      Ty.brep_shs(b_fuel_gap()), Ty.brep_sos(b_fuel_gap()),
      Ty.brep_top(b_fuel_gap()), Ty.brep_stamp(b_fuel_gap()), 1n)),
      "invalid-input"),
    Bool.and(String.eq(Ty.tres_show(Op.brep_checked(b_fuel_gap(),
      Ty.P_manifold_solid{}, 1n)), "resource-exhausted"),
    Bool.and(Bool.not(String.eq(Ty.tres_show(Op.brep_checked(b_fuel_gap(),
      Ty.P_manifold_solid{}, 1n)), "ok")),
    Bool.and(String.eq(Ty.tres_show(Op.brep_checked(b_fuel_gap(),
      Ty.P_manifold_solid{}, 2n)), "invalid-input"),
    Bool.and(String.eq(Ty.tres_show(Op.brep_checked(
      b_sphere_digon_control(), Ty.P_manifold_solid{}, 2n)), "ok"),
      String.eq(Ty.tres_show(Op.brep_checked(b_sphere_digon_control(),
        Ty.P_manifold_solid{}, 1n)), "resource-exhausted"))))))))
    == True{} : Bool}

def ck_fuel_ix():
  {==}

law ck_stage_fuel:
  {Bool.and(Nat.is_eq(Op.brep_incid_c(b_fuel_gap(), 1n), 0n),
    Bool.and(Nat.is_eq(Op.brep_orient_c(b_fuel_gap(), 1n), 0n),
    Bool.and(Nat.is_eq(Op.brep_incid_c(b_sphere_digon_control(), 1n), 0n),
    Bool.and(Nat.is_eq(Op.brep_orient_c(b_sphere_digon_control(), 1n), 0n),
    Bool.and(Nat.is_eq(Op.brep_orient_cert_c(b_sphere_digon_control(), 1n), 0n),
    Bool.and(Nat.is_eq(Op.brep_incid_c(b_sphere_digon_control(), 2n), 3n),
    Bool.and(Nat.is_eq(Op.brep_orient_c(b_sphere_digon_control(), 2n), 3n),
      Nat.is_eq(Op.brep_orient_cert_c(b_sphere_digon_control(), 2n), 1n))))))))
    == True{} : Bool}

def ck_stage_fuel():
  {==}

law ck_alias:
  {String.eq(Ty.tres_show(Op.brep_checked(b_alias(),
    Ty.P_manifold_solid{}, 12n)), "invalid-input") == True{} : Bool}

def ck_alias():
  {==}

law ck_outerkind:
  {String.eq(Ty.tres_show(Op.brep_checked(b_outerkind(),
    Ty.P_manifold_solid{}, 12n)), "invalid-input") == True{} : Bool}

def ck_outerkind():
  {==}

law ck_cavdup:
  {String.eq(Ty.tres_show(Op.brep_checked(b_cavdup(),
    Ty.P_manifold_solid{}, 20n)), "invalid-input") == True{} : Bool}

def ck_cavdup():
  {==}

law ck_reuse:
  {String.eq(Ty.tres_show(Op.brep_checked(b_reuse(),
    Ty.P_manifold_solid{}, 12n)), "invalid-input") == True{} : Bool}

def ck_reuse():
  {==}

law ck_cpshare:
  {String.eq(Ty.tres_show(Op.brep_checked(b_cpshare(),
    Ty.P_manifold_solid{}, 12n)), "invalid-input") == True{} : Bool}

def ck_cpshare():
  {==}

law ck_pinch:
  {String.eq(Ty.tres_show(Op.brep_checked(b_pinch(),
    Ty.P_manifold_solid{}, 20n)), "invalid-input") == True{} : Bool}

def ck_pinch():
  {==}

law qmem_spon:
  {Op.vx_surf_on(ix_vs(vs_q()), Ty.mk_hv(0n, 1u64), sf_sp())
    == True{} : Bool}

def qmem_spon():
  {==}

law qmem_cyon:
  {Op.vx_surf_on(ix_vs(vs_q()), Ty.mk_hv(0n, 1u64), sf_cy())
    == True{} : Bool}

def qmem_cyon():
  {==}

law qmem_con:
  {Op.vx_surf_on(ix_vs(vs_q()), Ty.mk_hv(0n, 1u64), sf_co())
    == True{} : Bool}

def qmem_con():
  {==}

law qmem_toon:
  {Op.vx_surf_on(ix_vs(vs_q()), Ty.mk_hv(2n, 3u64), sf_to())
    == True{} : Bool}

def qmem_toon():
  {==}

law ck_offquad:
  {String.eq(Ty.tres_show(Op.brep_checked(b_offquad(),
    Ty.P_manifold_solid{}, 12n)), "invalid-input") == True{} : Bool}

def ck_offquad():
  {==}

law ck_split:
  {String.eq(Ty.tres_show(Op.brep_checked(b_split(),
    Ty.P_manifold_solid{}, 20n)), "invalid-input") == True{} : Bool}

def ck_split():
  {==}

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

law coin_sphere:
  {Op.brep_coin_c(b_sphere_digon_control(), 12n) == 3n : Nat}

def coin_sphere():
  {==}

law coin_dup:
  {Op.brep_coin_c(b_coin(), 12n) == 2n : Nat}

def coin_dup():
  {==}

law coin_fuel:
  {Ty.okd_done(Op.brep_coin_c(b_sphere_digon_control(), 0n)) == False{} : Bool}

def coin_fuel():
  {==}

law link_sq:
  {Op.vx_link_ok(b_oriprop(), Ty.mk_hv(0n, 1u64), 20n)
    == 3n : Nat}

def link_sq():
  {==}

law link_pinch:
  {Op.vx_link_ok(b_pinch(), Ty.mk_hv(0n, 1u64), 20n)
    == 2n : Nat}

def link_pinch():
  {==}

law segx_cross:
  {Op.segx_pair(p000(), p110(), p100(), p010()) == True{} : Bool}

def segx_cross():
  {==}

law segx_clean:
  {Op.segx_pair(p000(), p100(), p110(), p010())
    == False{} : Bool}

def segx_clean():
  {==}

law xing_clean:
  {Op.brep_xing_c(b_oriprop(), 20n) == 3n : Nat}

def xing_clean():
  {==}

law xing_hit:
  {Op.brep_xing_c(b_xing(), 20n) == 2n : Nat}

def xing_hit():
  {==}

law orient_sq:
  {Op.brep_orient_c(b_oriprop(), 20n) == 3n : Nat}

def orient_sq():
  {==}

law orient_invface:
  {Op.brep_orient_c(b_invface(), 20n) == 2n : Nat}

def orient_invface():
  {==}

law orient_hole:
  {Op.brep_orient_c(b_hole(), 20n) == 3n : Nat}

def orient_hole():
  {==}

law orient_hole_bad:
  {Op.brep_orient_c(b_hole_bad(), 20n) == 2n : Nat}

def orient_hole_bad():
  {==}

law orient_hole_bad2:
  {Op.brep_orient_c(b_hole_bad2(), 20n) == 2n : Nat}

def orient_hole_bad2():
  {==}

law orient_diffparam:
  {Op.brep_orient_c(b_diffparam(), 20n) == 3n : Nat}

def orient_diffparam():
  {==}

law recheck_sphere:
  {Op.brep_recheck_c(b_sphere_digon_control(), 12n) == 3n : Nat}

def recheck_sphere():
  {==}

law recheck_oriprop:
  {Op.brep_recheck_c(b_oriprop(), 20n) == 3n : Nat}

def recheck_oriprop():
  {==}

law recheck_invface:
  {Op.brep_recheck_c(b_invface(), 20n) == 2n : Nat}

def recheck_invface():
  {==}

law recheck_diffparam:
  {Op.brep_recheck_c(b_diffparam(), 20n) == 3n : Nat}

def recheck_diffparam():
  {==}

law recheck_hole:
  {Op.brep_recheck_c(b_hole(), 20n) == 3n : Nat}

def recheck_hole():
  {==}

law cert_oriprop:
  {Op.cnt_count(Op.brep_orient_cert_c(b_oriprop(), 20n)) == 2n : Nat}

def cert_oriprop():
  {==}

law skip_oriprop:
  {Op.cnt_count(Op.brep_orient_skip_c(b_oriprop(), 20n)) == 0n : Nat}

def skip_oriprop():
  {==}

law cert_invface:
  {Op.cnt_count(Op.brep_orient_cert_c(b_invface(), 20n)) == 2n : Nat}

def cert_invface():
  {==}

law cert_sphere:
  {Op.cnt_count(Op.brep_orient_cert_c(b_sphere_digon_control(), 12n)) == 0n : Nat}

def cert_sphere():
  {==}

law skip_sphere:
  {Op.cnt_count(Op.brep_orient_skip_c(b_sphere_digon_control(), 12n)) == 1n : Nat}

def skip_sphere():
  {==}

law cert_hole:
  {Op.cnt_count(Op.brep_orient_cert_c(b_hole(), 20n)) == 2n : Nat}

def cert_hole():
  {==}

law skip_hole:
  {Op.cnt_count(Op.brep_orient_skip_c(b_hole(), 20n)) == 0n : Nat}

def skip_hole():
  {==}

law bezp_z00pos:
  {F64.is_lt(0.0f64,
    V.dr_z(G.gres_d(Op.bezp_normal_at(bp0(), 0.0f64, 0.0f64)))) == True{} : Bool}

def bezp_z00pos():
  {==}

law bezp_z11neg:
  {F64.is_lt(V.dr_z(G.gres_d(Op.bezp_normal_at(bp0(), 1.0f64, 1.0f64))),
    0.0f64) == True{} : Bool}

def bezp_z11neg():
  {==}

law ck_coin:
  {String.eq(Ty.tres_show(Op.brep_checked(b_coin(),
    Ty.P_manifold_solid{}, 12n)), "invalid-input") == True{} : Bool}

def ck_coin():
  {==}

law ck_xing:
  {String.eq(Ty.tres_show(Op.brep_checked(b_xing(),
    Ty.P_manifold_solid{}, 20n)), "invalid-input") == True{} : Bool}

def ck_xing():
  {==}

law ck_invface:
  {String.eq(Ty.tres_show(Op.brep_checked(b_invface(),
    Ty.P_manifold_solid{}, 20n)), "invalid-input") == True{} : Bool}

def ck_invface():
  {==}

law ck_oriprop_ok:
  {String.eq(Ty.tres_show(Op.brep_checked(b_oriprop(),
    Ty.P_manifold_solid{}, 20n)), "ok") == True{} : Bool}

def ck_oriprop_ok():
  {==}

law ck_split_open:
  {String.eq(Ty.tres_show(Op.brep_checked(b_split(),
    Ty.P_open_shell{}, 20n)), "invalid-input") == True{} : Bool}

def ck_split_open():
  {==}

law ck_hole_bad:
  {String.eq(Ty.tres_show(Op.brep_checked(b_hole_bad(),
    Ty.P_open_shell{}, 20n)), "invalid-input") == True{} : Bool}

def ck_hole_bad():
  {==}

law ck_hole_bad2:
  {String.eq(Ty.tres_show(Op.brep_checked(b_hole_bad2(),
    Ty.P_open_shell{}, 20n)), "invalid-input") == True{} : Bool}

def ck_hole_bad2():
  {==}

law ck_hole_ok:
  {String.eq(Ty.tres_show(Op.brep_checked(b_hole(),
    Ty.P_open_shell{}, 20n)), "ok") == True{} : Bool}

def ck_hole_ok():
  {==}

law ck_diffparam_ok:
  {String.eq(Ty.tres_show(Op.brep_checked(b_diffparam(),
    Ty.P_manifold_solid{}, 20n)), "ok") == True{} : Bool}

def ck_diffparam_ok():
  {==}

law ck_cyl_side:
  {String.eq(Ty.tres_show(Op.brep_checked(b_cyl_side(),
    Ty.P_manifold_solid{}, 20n)), "ok") == True{} : Bool}

def ck_cyl_side():
  {==}

law ck_sphere_curved:
  {String.eq(Ty.tres_show(Op.brep_checked(b_sphere_curved(),
    Ty.P_manifold_solid{}, 20n)), "ok") == True{} : Bool}

def ck_sphere_curved():
  {==}

law xing_defg:
  {Bool.and(Nat.is_eq(Op.brep_loop_c(b_xing(), 20n), 3n),
    Bool.and(Nat.is_eq(Op.brep_facekind_c(b_xing(), 20n), 3n),
      Bool.and(Nat.is_eq(Op.brep_prof_c(b_xing(),
        Ty.P_manifold_solid{}, 20n), 3n),
        Nat.is_eq(Op.brep_embed_c(b_xing(), 20n), 3n))))
    == True{} : Bool}

def xing_defg():
  {==}

law xing_hijk:
  {Bool.and(Nat.is_eq(Op.brep_link_c(b_xing(),
      Ty.P_manifold_solid{}, 20n), 3n),
    Bool.and(Nat.is_eq(Op.brep_conn_c(b_xing(), 20n), 3n),
      Bool.and(Nat.is_eq(Op.brep_coin_c(b_xing(), 20n), 3n),
        Nat.is_eq(Op.brep_xing_c(b_xing(), 20n), 2n))))
    == True{} : Bool}

def xing_hijk():
  {==}

law selfx_dup:
  {Bool.and(Nat.is_eq(Op.brep_loop_c(b_selfx(), 12n), 2n),
    Nat.is_eq(Op.brep_embed_c(b_selfx(), 12n), 3n))
    == True{} : Bool}

def selfx_dup():
  {==}
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
  Ty.Fa{10u64, l1_pl(), l1_hl0() <> Nil{}, True{}} <>
    Ty.Fa{11u64, l1_pl(), l1_hl1() <> Nil{}, True{}} <> Nil{}

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

law l1_use_solid_spec:
  for c: Nat
  for t: Bool
  for f: Bool
  {Op.use_rule_ok(c, t, f, Ty.P_manifold_solid{})
    == Bool.and(Nat.is_eq(c, 2n), Bool.and(t, f)) : Bool}

def l1_use_solid_spec(c, t, f):
  {==}

law l1_use_open_spec:
  for c: Nat
  for t: Bool
  for f: Bool
  {Op.use_rule_ok(c, t, f, Ty.P_open_shell{})
    == Bool.or(Nat.is_eq(c, 1n),
      Bool.and(Nat.is_eq(c, 2n), Bool.and(t, f))) : Bool}

def l1_use_open_spec(c, t, f):
  {==}

law l1_use_solid_non2:
  for c: Nat
  for t: Bool
  for f: Bool
  {Bool.or(Nat.is_eq(c, 2n),
    Bool.not(Op.use_rule_ok(c, t, f,
      Ty.P_manifold_solid{}))) == True{} : Bool}

def l1_use_solid_non2(c, t, f):
  match c:
    case 0n: {==}
    case 1n+0n: {==}
    case 1n+(1n+0n): {==}
    case 1n+(1n+(1n+g)): {==}

law l1_use_solid_pair:
  for t: Bool
  for f: Bool
  {Op.use_rule_ok(2n, t, f, Ty.P_manifold_solid{})
    == Bool.and(t, f) : Bool}

def l1_use_solid_pair(t, f):
  match t:
    case True{}:
      match f:
        case True{}: {==}
        case False{}: {==}
    case False{}:
      match f:
        case True{}: {==}
        case False{}: {==}

law l1_use_open_1:
  for t: Bool
  for f: Bool
  {Op.use_rule_ok(1n, t, f, Ty.P_open_shell{})
    == True{} : Bool}

def l1_use_open_1(t, f):
  {==}

law l1_use_open_non12:
  for c: Nat
  for t: Bool
  for f: Bool
  {Bool.or(Bool.or(Nat.is_eq(c, 1n), Nat.is_eq(c, 2n)),
    Bool.not(Op.use_rule_ok(c, t, f, Ty.P_open_shell{})))
    == True{} : Bool}

def l1_use_open_non12(c, t, f):
  match c:
    case 0n: {==}
    case 1n+0n: {==}
    case 1n+(1n+0n): {==}
    case 1n+(1n+(1n+g)): {==}

law l1_use_open_pair:
  for t: Bool
  for f: Bool
  {Op.use_rule_ok(2n, t, f, Ty.P_open_shell{})
    == Bool.and(t, f) : Bool}

def l1_use_open_pair(t, f):
  match t:
    case True{}:
      match f:
        case True{}: {==}
        case False{}: {==}
    case False{}:
      match f:
        case True{}: {==}
        case False{}: {==}

law l1_use_go_nil:
  for i: Nat
  for keys: List<&2, Op.UK>
  for prof: Ty.Profile
  {Op.use_go(Nil{}, i, keys, prof) == True{} : Bool}

def l1_use_go_nil(i, keys, prof):
  {==}

law l1_es_use_nil:
  for ces: List<&2, Ty.Coedge>
  for prof: Ty.Profile
  {Op.use_ok(l1_b_ec(Nil{}, ces), prof) == True{} : Bool}

def l1_es_use_nil(ces, prof):
  {==}

law l1_seam_use:
  for f: Bool
  {Op.use_ok(l1_b_ec(l1_es_line(), l1_ces_seam(f)),
    Ty.P_manifold_solid{}) == True{} : Bool}

def l1_seam_use(f):
  match f:
    case True{}: {==}
    case False{}: {==}

law l1_seam_use_same:
  {Op.use_ok(l1_b_ec(l1_es_line(), l1_ces_same()),
    Ty.P_manifold_solid{}) == False{} : Bool}

def l1_seam_use_same():
  {==}

law l1_outer_rule:
  for g: U64
  for su: G.GVal
  for ls: List<&2, Ty.HLoop>
  for sa: Bool
  for x: Ty.Ix
  {Op.fas_kind_ok(Ty.Fa{g, su, ls, sa} <> Nil{}, x)
    == Bool.and(Nat.is_eq(Op.hls_outer(ls, x), 1n), True{}) : Bool}

def l1_outer_rule(g, su, ls, sa, x):
  {==}

law l1_outer_one:
  {Op.hls_outer(l1_hl0() <> Nil{}, l1_ixl(l1_lps_outer()))
    == 1n : Nat}

def l1_outer_one():
  {==}

law l1_outer_two:
  {Op.hls_outer(l1_hl0() <> l1_hl1() <> Nil{},
    l1_ixl(l1_lps_twoouter())) == 2n : Nat}

def l1_outer_two():
  {==}

law l1_outer_zero:
  {Op.hls_outer(l1_hl0() <> Nil{}, l1_ixl(l1_lps_inner()))
    == 0n : Nat}

def l1_outer_zero():
  {==}

law l1_noopen_open:
  {Op.shs_no_open_c(Ty.Sh{1u64, Nil{}, Ty.SK_open{}}
    <> Nil{}, 1n) == 2n : Nat}

def l1_noopen_open():
  {==}

law l1_noopen_outer:
  {Op.shs_no_open_c(Ty.Sh{1u64, Nil{}, Ty.SK_outer{}}
    <> Nil{}, 1n) == 3n : Nat}

def l1_noopen_outer():
  {==}

law l1_ov_start:
  for a: Ty.HVertex
  for b: Ty.HVertex
  for f: Bool
  {Op.o_v_start(Ty.Ed{0u64, a, b, Ty.EK_degenerate{}},
    f) == Bool.pick(Ty.HVertex, f, a, b) : Ty.HVertex}

def l1_ov_start(a, b, f):
  match f:
    case True{}: {==}
    case False{}: {==}

law l1_ov_end:
  for a: Ty.HVertex
  for b: Ty.HVertex
  for f: Bool
  {Op.o_v_end(Ty.Ed{0u64, a, b, Ty.EK_degenerate{}},
    f) == Bool.pick(Ty.HVertex, f, b, a) : Ty.HVertex}

def l1_ov_end(a, b, f):
  match f:
    case True{}: {==}
    case False{}: {==}

law l1_ov_swap:
  for a: Ty.HVertex
  for b: Ty.HVertex
  for f: Bool
  {Op.o_v_start(Ty.Ed{0u64, a, b, Ty.EK_degenerate{}},
    f) == Op.o_v_end(Ty.Ed{0u64, a, b,
      Ty.EK_degenerate{}}, Bool.not(f)) : Ty.HVertex}

def l1_ov_swap(a, b, f):
  match f:
    case True{}: {==}
    case False{}: {==}

law l1_closed_start:
  for a: Ty.HVertex
  for f: Bool
  {Op.o_v_start(Ty.Ed{0u64, a, a, Ty.EK_degenerate{}},
    f) == a : Ty.HVertex}

def l1_closed_start(a, f):
  match f:
    case True{}: {==}
    case False{}: {==}

law l1_closed_end:
  for a: Ty.HVertex
  for f: Bool
  {Op.o_v_end(Ty.Ed{0u64, a, a, Ty.EK_degenerate{}},
    f) == a : Ty.HVertex}

def l1_closed_end(a, f):
  match f:
    case True{}: {==}
    case False{}: {==}

law l1_trim_ts_start:
  for a: V.Vec2
  for b: V.Vec2
  {Op.trim_start(G.GV_ts{G.Ts{a, b}}) == a : V.Vec2}

def l1_trim_ts_start(a, b):
  {==}

law l1_trim_ts_end:
  for a: V.Vec2
  for b: V.Vec2
  {Op.trim_end(G.GV_ts{G.Ts{a, b}}) == b : V.Vec2}

def l1_trim_ts_end(a, b):
  {==}

law l1_trim_tb_start:
  for b0: V.Vec2
  for b1: V.Vec2
  for b2: V.Vec2
  for b3: V.Vec2
  {Op.trim_start(G.GV_tb{G.Tb{b0, b1, b2, b3}})
    == b0 : V.Vec2}

def l1_trim_tb_start(b0, b1, b2, b3):
  {==}

law l1_trim_tb_end:
  for b0: V.Vec2
  for b1: V.Vec2
  for b2: V.Vec2
  for b3: V.Vec2
  {Op.trim_end(G.GV_tb{G.Tb{b0, b1, b2, b3}})
    == b3 : V.Vec2}

def l1_trim_tb_end(b0, b1, b2, b3):
  {==}

law l1_trim_o_start:
  for t: G.GVal
  for f: Bool
  {Op.trim_o_start(t, f)
    == Bool.pick(V.Vec2, f, Op.trim_start(t),
      Op.trim_end(t)) : V.Vec2}

def l1_trim_o_start(t, f):
  match f:
    case True{}: {==}
    case False{}: {==}

law l1_trim_o_end:
  for t: G.GVal
  for f: Bool
  {Op.trim_o_end(t, f)
    == Bool.pick(V.Vec2, f, Op.trim_end(t),
      Op.trim_start(t)) : V.Vec2}

def l1_trim_o_end(t, f):
  match f:
    case True{}: {==}
    case False{}: {==}

law l1_trim_swap:
  for t: G.GVal
  for f: Bool
  {Op.trim_o_start(t, f)
    == Op.trim_o_end(t, Bool.not(f)) : V.Vec2}

def l1_trim_swap(t, f):
  match f:
    case True{}: {==}
    case False{}: {==}

law l1_closure:
  for x: Ty.Ix
  for pv: Ty.HVertex
  for fv: Ty.HVertex
  for pt: V.Vec2
  for ft: V.Vec2
  {Op.loop_rest_go(Nil{}, x, pv, fv, pt, ft)
    == Bool.and(Ty.hv_eq(pv, fv), Op.v2_eq(pt, ft)) : Bool}

def l1_closure(x, pv, fv, pt, ft):
  {==}

law l1_closure_vmiss:
  {Op.loop_rest_go(Nil{}, l1_ix(Nil{}, Nil{}), l1_v0(), l1_v1(),
    l1_uva(), l1_uva()) == False{} : Bool}

def l1_closure_vmiss():
  {==}

law l1_closure_tmiss:
  {Op.loop_rest_go(Nil{}, l1_ix(Nil{}, Nil{}), l1_v0(), l1_v0(),
    l1_uva(), l1_uvb()) == False{} : Bool}

def l1_closure_tmiss():
  {==}

law l1_chain_ok:
  {Op.loop_rest_go(l1_hc1() <> Nil{},
    l1_ix(l1_es_chain(), l1_ces_chain(False{})), l1_v1(), l1_v0(),
    l1_uvb(), l1_uva()) == True{} : Bool}

def l1_chain_ok():
  {==}

law l1_chain_gap:
  {Op.loop_rest_go(l1_hc1() <> Nil{},
    l1_ix(l1_es_chain(), l1_ces_chain(True{})), l1_v1(), l1_v0(),
    l1_uvb(), l1_uva()) == False{} : Bool}

def l1_chain_gap():
  {==}

law l1_nodup_nil:
  for fuel: Nat
  {Op.hc_nodup_c(Nil{}, fuel) == 3n : Nat}

def l1_nodup_nil(fuel):
  match fuel:
    case 0n: {==}
    case 1n+f: {==}

law l1_nodup_single:
  for h: Ty.HCoedge
  {Op.hc_nodup_c(h <> Nil{}, 2n) == 3n : Nat}

def l1_nodup_single(h):
  {==}

law l1_nodup_dup:
  {Op.hc_nodup_c(l1_hc0() <> l1_hc0() <> Nil{}, 3n)
    == 2n : Nat}

def l1_nodup_dup():
  {==}

law l1_nodup_distinct:
  {Op.hc_nodup_c(l1_hc0() <> l1_hc1() <> Nil{}, 3n)
    == 3n : Nat}

def l1_nodup_distinct():
  {==}

law l1_seam_run_nil:
  for pk: Op.HK
  for pf: Bool
  for run: Nat
  {Op.seam_go(Nil{}, pk, pf, run) == True{} : Bool}

def l1_seam_run_nil(pk, pf, run):
  {==}

law l1_seam_go_nil:
  for x: Ty.Ix
  {Op.loop_seam_ok(Nil{}, x) == True{} : Bool}

def l1_seam_go_nil(x):
  {==}

law l1_seam_accept:
  for f: Bool
  {Op.loop_seam_ok(l1_hc0() <> l1_hc1() <> Nil{},
    l1_ix(l1_es_line(), l1_ces_seam(f))) == True{} : Bool}

def l1_seam_accept(f):
  match f:
    case True{}: {==}
    case False{}: {==}

law l1_seam_same:
  {Op.loop_seam_ok(l1_hc0() <> l1_hc1() <> Nil{},
    l1_ix(l1_es_line(), l1_ces_same())) == False{} : Bool}

def l1_seam_same():
  {==}

law l1_seam_skip:
  {Op.loop_seam_ok(l1_hc0() <> l1_hc1() <> Nil{},
    l1_ix(l1_es_pair(), l1_ces_distinct())) == True{} : Bool}

def l1_seam_skip():
  {==}

law l1_pole_nil:
  for +hcs: List<&2, Ty.HCoedge>
  for +x: Ty.Ix
  {Op.loop_pole_ok(hcs, x)
    == Bool.or(Nat.is_eq(Op.hcs_ndeg(hcs, x), 0n),
      Bool.and(Nat.is_eq(List.length(&2, Ty.HCoedge, hcs), 1n),
        Nat.is_eq(Op.hcs_ndeg(hcs, x), 1n))) : Bool}

def l1_pole_nil(hcs, x):
  {==}

law l1_pole_single:
  {Op.loop_pole_ok(l1_hc0() <> Nil{},
    l1_ix(l1_es_degen(), l1_ces_one())) == True{} : Bool}

def l1_pole_single():
  {==}

law l1_pole_two:
  {Op.loop_pole_ok(l1_hc0() <> l1_hc1() <> Nil{},
    l1_ix(l1_es_degen(), l1_ces_seam(True{}))) == False{} : Bool}

def l1_pole_two():
  {==}

law l1_pole_clean:
  {Op.loop_pole_ok(l1_hc0() <> Nil{},
    l1_ix(l1_es_line(), l1_ces_one())) == True{} : Bool}

def l1_pole_clean():
  {==}

law l1_mem_nil:
  {Op.khas(Op.ktb(Nil{}), Op.hc_key(l1_hc0())) == False{} : Bool}

def l1_mem_nil():
  {==}

law l1_mem_hit:
  {Op.khas(Op.ktb(Op.hcs_keys(l1_hc0() <> Nil{}, Nil{})),
    Op.hc_key(l1_hc0())) == True{} : Bool}

def l1_mem_hit():
  {==}

law l1_mem_miss:
  {Op.khas(Op.ktb(Op.hcs_keys(l1_hc0() <> Nil{}, Nil{})),
    Op.hc_key(l1_hc1())) == False{} : Bool}

def l1_mem_miss():
  {==}

law l1_last_nil:
  for d: Ty.HCoedge
  {Op.hc_last(Nil{}, d) == d : Ty.HCoedge}

def l1_last_nil(d):
  {==}

law l1_prev_nil:
  {Op.hm_prev(Op.hmap_of(l1_b_step()), Ty.mk_hc(5n, 99u64))
    == Ty.mk_hc(5n, 99u64) : Ty.HCoedge}

def l1_prev_nil():
  {==}

law l1_prev_mid:
  {Op.hm_prev(Op.hmap_of(l1_b_step()), l1_hc1())
    == l1_hc0() : Ty.HCoedge}

def l1_prev_mid():
  {==}

law l1_prev_wrap:
  {Op.hm_prev(Op.hmap_of(l1_b_step()), l1_hc0())
    == l1_hc1() : Ty.HCoedge}

def l1_prev_wrap():
  {==}

law l1_prev_single:
  {Op.hm_prev(Op.hmap_of(l1_b_single()), l1_hc0())
    == l1_hc0() : Ty.HCoedge}

def l1_prev_single():
  {==}

law l1_hcprev_nil:
  {Op.hm_prev(Op.hmap_of(l1_b_ec(Nil{}, Nil{})), l1_hc0())
    == l1_hc0() : Ty.HCoedge}

def l1_hcprev_nil():
  {==}

law l1_twin_nil:
  {Op.hm_twin(Op.hmap_of(l1_b_split()), Ty.ix_of(l1_b_split()),
    l1_hc0()) == l1_hc0() : Ty.HCoedge}

def l1_twin_nil():
  {==}

law l1_twin_first:
  {Op.hm_twin(Op.hmap_of(l1_b_share()), Ty.ix_of(l1_b_share()),
    l1_hc0()) == l1_hc1() : Ty.HCoedge}

def l1_twin_first():
  {==}

law l1_twin_second:
  {Op.hm_twin(Op.hmap_of(l1_b_share()), Ty.ix_of(l1_b_share()),
    l1_hc1()) == l1_hc0() : Ty.HCoedge}

def l1_twin_second():
  {==}

law l1_twin_miss:
  {Op.hm_twin(Op.hmap_of(l1_b_single()), Ty.ix_of(l1_b_single()),
    l1_hc0()) == l1_hc0() : Ty.HCoedge}

def l1_twin_miss():
  {==}

law l1_step:
  {Op.hm_step(Op.hmap_of(l1_b_step()), Ty.ix_of(l1_b_step()),
    l1_hc1()) == l1_hc1() : Ty.HCoedge}

def l1_step():
  {==}

law l1_nondegen_curve:
  {Op.hc_nondegen(l1_ix(l1_es_line(), l1_ces_seam(True{})),
    l1_hc0()) == True{} : Bool}

def l1_nondegen_curve():
  {==}

law l1_nondegen_degen:
  {Op.hc_nondegen(l1_ix(l1_es_degen(), l1_ces_one()), l1_hc0())
    == False{} : Bool}

def l1_nondegen_degen():
  {==}

law l1_orbit_tail:
  {Op.orb_cyc(l1_orb_rho(), l1_rho_id(l1_rho_x()))
    == False{} : Bool}

def l1_orbit_tail():
  {==}

law l1_orbit_cycle:
  {Op.orb_cyc(l1_orb_rho(), l1_rho_id(l1_hc0()))
    == True{} : Bool}

def l1_orbit_cycle():
  {==}

law l1_orbit_tail_step:
  {Op.orb_nx(l1_orb_rho(), l1_rho_id(l1_rho_x()))
    == l1_rho_id(l1_hc0()) : U32}

def l1_orbit_tail_step():
  {==}

law l1_vxlink_rho:
  {Op.vx_link_ok(l1_b_rho(), l1_v2(), 20n) == 2n : Nat}

def l1_vxlink_rho():
  {==}

law l1_vxlink_fuel0:
  {Op.vx_link_ok(b_oriprop(), Ty.mk_hv(0n, 1u64), 0n) == 0n : Nat}

def l1_vxlink_fuel0():
  {==}

law l1_link_open:
  for b: Ty.Brep
  for fuel: Nat
  {Op.brep_link_c(b, Ty.P_open_shell{}, fuel) == 3n : Nat}

def l1_link_open(b, fuel):
  {==}

law l1_cov_nil:
  for i: Nat
  for cls: List<&2, Op.CL>
  {Op.cov_go(Nil{}, i, cls) == True{} : Bool}

def l1_cov_nil(i, cls):
  {==}

law l1_start_nil:
  for x: Ty.Ix
  for i: Nat
  {Op.svs_of(Nil{}, x, i) == Nil{} : List<&2, Op.SV>}

def l1_start_nil(x, i):
  {==}

law l1_have_nil:
  for x: Ty.Ix
  for p: U32
  for acc: List<&2, Op.EP>
  {Op.hcs_ekeys(Nil{}, x, p, acc) == acc : List<&2, Op.EP>}

def l1_have_nil(x, p, acc):
  {==}

law l1_have_hit:
  {Op.hcs_ekeys(l1_hc0() <> Nil{},
    l1_ix(l1_es_line(), l1_ces_seam(True{})), 0, Nil{})
    == Op.EP{Op.he_key(l1_he0()), 0} <> Nil{} : List<&2, Op.EP>}

def l1_have_hit():
  {==}

law l1_have_miss:
  {Op.hcs_ekeys(l1_hc1() <> Nil{},
    l1_ix(l1_es_pair(), l1_ces_distinct()), 0, Nil{})
    == Op.EP{Op.he_key(l1_he1()), 0} <> Nil{} : List<&2, Op.EP>}

def l1_have_miss():
  {==}

law l1_share_nil:
  for x: Ty.Ix
  {Op.sh_adj(Nil{}, x) == Nil{} : List<&2, B.Ed>}

def l1_share_nil(x):
  {==}

law l1_share_pos:
  {Op.sh_adj(l1_hf0() <> l1_hf1() <> Nil{}, Ty.ix_of(l1_b_share()))
    == B.Ed{0, 1} <> Nil{} : List<&2, B.Ed>}

def l1_share_pos():
  {==}

law l1_share_neg:
  {Op.sh_adj(l1_hf0() <> l1_hf1() <> Nil{}, Ty.ix_of(l1_b_split()))
    == Nil{} : List<&2, B.Ed>}

def l1_share_neg():
  {==}

law l1_hls_nil:
  for x: Ty.Ix
  for p: U32
  for acc: List<&2, Op.EP>
  {Op.hls_ekeys(Nil{}, x, p, acc) == acc : List<&2, Op.EP>}

def l1_hls_nil(x, p, acc):
  {==}

law l1_hlps_nil:
  for x: Ty.Ix
  for p: U32
  {Op.hfs_ekeys(Nil{}, x, p) == Nil{} : List<&2, Op.EP>}

def l1_hlps_nil(x, p):
  {==}

law l1_faces_share:
  {Op.shs_conn_ok(l1_shs_pair(), Ty.ix_of(l1_b_share()))
    == True{} : Bool}

def l1_faces_share():
  {==}

law l1_faces_split:
  {Op.shs_conn_ok(l1_shs_pair(), Ty.ix_of(l1_b_split()))
    == False{} : Bool}

def l1_faces_split():
  {==}

law l1_conn_nil:
  for x: Ty.Ix
  {Op.sh_conn_ok(Nil{}, x) == True{} : Bool}

def l1_conn_nil(x):
  {==}

law l1_conn:
  {Op.sh_conn_ok(l1_hf0() <> l1_hf1() <> Nil{},
    Ty.ix_of(l1_b_share())) == True{} : Bool}

def l1_conn():
  {==}

law l1_conn_split:
  {Op.sh_conn_ok(l1_hf0() <> l1_hf1() <> Nil{},
    Ty.ix_of(l1_b_split())) == False{} : Bool}

def l1_conn_split():
  {==}

law l1_conn_dup_face:
  {Op.sh_conn_ok(l1_hf0() <> l1_hf0() <> Nil{},
    Ty.ix_of(l1_b_share())) == False{} : Bool}

def l1_conn_dup_face():
  {==}

law l1_conn_rule:
  for ok: Bool
  for ps: List<&2, U32>
  {Op.cc_conn(B.CC{ok, ps}) == Bool.and(ok, Op.all_zero(ps)) : Bool}

def l1_conn_rule(ok, ps):
  {==}

law l1_line_ln:
  for w: G.Line3
  {Op.gval_is_line(G.GV_ln{w}) == True{} : Bool}

def l1_line_ln(w):
  {==}

law l1_line_cc:
  for w: G.Circle3
  {Op.gval_is_line(G.GV_cc{w}) == False{} : Bool}

def l1_line_cc(w):
  {==}

law l1_line_bz:
  for w: G.Bez3
  {Op.gval_is_line(G.GV_bz{w}) == False{} : Bool}

def l1_line_bz(w):
  {==}

law l1_line_rq:
  for w: G.RQBez
  {Op.gval_is_line(G.GV_rq{w}) == False{} : Bool}

def l1_line_rq(w):
  {==}

law l1_line_nb:
  for w: G.Nurb
  {Op.gval_is_line(G.GV_nb{w}) == False{} : Bool}

def l1_line_nb(w):
  {==}

law l1_line_pl:
  for w: G.Plane3
  {Op.gval_is_line(G.GV_pl{w}) == False{} : Bool}

def l1_line_pl(w):
  {==}

law l1_ekind_curve:
  for c: G.GVal
  for d: G.Dom
  {Op.ekind_is_line(Ty.EK_curve{c, d})
    == Op.gval_is_line(c) : Bool}

def l1_ekind_curve(c, d):
  {==}

law l1_ekind_degen:
  {Op.ekind_is_line(Ty.EK_degenerate{}) == False{} : Bool}

def l1_ekind_degen():
  {==}

law l1_edge_line:
  for g: U64
  for v0: Ty.HVertex
  for v1: Ty.HVertex
  for k: Ty.EdgeKind
  {Op.edge_is_line(Ty.Ed{g, v0, v1, k})
    == Op.ekind_is_line(k) : Bool}

def l1_edge_line(g, v0, v1, k):
  {==}

law l1_lines_nil:
  for x: Ty.Ix
  {Op.hcs_all_lines(Nil{}, x) == True{} : Bool}

def l1_lines_nil(x):
  {==}

law l1_lines_cons:
  for h: Ty.HCoedge
  for t: List<&2, Ty.HCoedge>
  for +x: Ty.Ix
  {Op.hcs_all_lines(h <> t, x)
    == Bool.and(Op.edge_is_line(Ty.tres_ed(Ty.ix_ed(x,
      Ty.ce_edge(Ty.tres_ce(Ty.ix_ce(x, h)))))),
      Op.hcs_all_lines(t, x)) : Bool}

def l1_lines_cons(h, t, x):
  {==}

law l1_lines_pos:
  {Op.hcs_all_lines(l1_hc0() <> Nil{},
    l1_ix(l1_es_line(), l1_ces_seam(True{}))) == True{} : Bool}

def l1_lines_pos():
  {==}

law l1_lines_neg:
  {Op.hcs_all_lines(l1_hc0() <> Nil{},
    l1_ix(l1_es_cc(), l1_ces_one())) == False{} : Bool}

def l1_lines_neg():
  {==}

law l1_plane_pos:
  for w: G.Plane3
  {Op.surf_is_plane(G.GV_pl{w}) == True{} : Bool}

def l1_plane_pos(w):
  {==}

law l1_plane_cy:
  for w: G.Cyl
  {Op.surf_is_plane(G.GV_cy{w}) == False{} : Bool}

def l1_plane_cy(w):
  {==}

law l1_plane_co:
  for w: G.Cone
  {Op.surf_is_plane(G.GV_co{w}) == False{} : Bool}

def l1_plane_co(w):
  {==}

law l1_plane_sp:
  for w: G.Sphere
  {Op.surf_is_plane(G.GV_sp{w}) == False{} : Bool}

def l1_plane_sp(w):
  {==}

law l1_plane_to:
  for w: G.Torus
  {Op.surf_is_plane(G.GV_to{w}) == False{} : Bool}

def l1_plane_to(w):
  {==}

law l1_plane_bp:
  for w: G.BezP
  {Op.surf_is_plane(G.GV_bp{w}) == False{} : Bool}

def l1_plane_bp(w):
  {==}

law l1_varying_nofail:
  for +s: G.GVal
  for hcs: List<&2, Ty.HCoedge>
  for x: Ty.Ix
  for same: Bool
  for kind: Ty.LoopKind
  {Bool.or(Op.surf_is_plane(s),
    Bool.not(Nat.is_eq(Op.loop_orient_class(hcs, x, s, same, kind),
      2n))) == True{} : Bool}

def l1_varying_nofail(s, hcs, x, same, kind):
  match s:
    case G.GV_f{w}: {==}
    case G.GV_p{w}: {==}
    case G.GV_d{w}: {==}
    case G.GV_v2{w}: {==}
    case G.GV_dom{w}: {==}
    case G.GV_ln{w}: {==}
    case G.GV_pl{w}: {==}
    case G.GV_cc{w}: {==}
    case G.GV_bz{w}: {==}
    case G.GV_rq{w}: {==}
    case G.GV_bp{w}: {==}
    case G.GV_sp{w}: {==}
    case G.GV_cy{w}: {==}
    case G.GV_co{w}: {==}
    case G.GV_to{w}: {==}
    case G.GV_bb{w}: {==}
    case G.GV_nb{w}: {==}
    case G.GV_ts{w}: {==}
    case G.GV_tb{w}: {==}

law l1_plnorm_unsupported:
  for s: G.GVal
  {Bool.or(Op.surf_is_plane(s),
    Bool.not(G.gres_ok(Op.plane_normal_of(s))))
    == True{} : Bool}

def l1_plnorm_unsupported(s):
  match s:
    case G.GV_f{w}: {==}
    case G.GV_p{w}: {==}
    case G.GV_d{w}: {==}
    case G.GV_v2{w}: {==}
    case G.GV_dom{w}: {==}
    case G.GV_ln{w}: {==}
    case G.GV_pl{w}: {==}
    case G.GV_cc{w}: {==}
    case G.GV_bz{w}: {==}
    case G.GV_rq{w}: {==}
    case G.GV_bp{w}: {==}
    case G.GV_sp{w}: {==}
    case G.GV_cy{w}: {==}
    case G.GV_co{w}: {==}
    case G.GV_to{w}: {==}
    case G.GV_bb{w}: {==}
    case G.GV_nb{w}: {==}
    case G.GV_ts{w}: {==}
    case G.GV_tb{w}: {==}

law l1_curved_skip:
  {Op.loop_orient_class(l1_hc0() <> Nil{},
    l1_ixv(l1_vs2(), l1_es_cc(), l1_ces_one()), l1_pl(), True{},
    Ty.LK_outer{}) == 0n : Nat}

def l1_curved_skip():
  {==}

law l1_orient_c_spec:
  for +hcs: List<&2, Ty.HCoedge>
  for +x: Ty.Ix
  for +surf: G.GVal
  for +same: Bool
  for +kind: Ty.LoopKind
  {Op.loop_orient_c(hcs, x, surf, same, kind)
    == Ty.okd_pack(Bool.not(Nat.is_eq(Op.loop_orient_class(hcs, x,
      surf, same, kind), 2n)), True{}) : Nat}

def l1_orient_c_spec(hcs, x, surf, same, kind):
  {==}

law l1_oct_hls_nil:
  for x: Ty.Ix
  for surf: G.GVal
  for same: Bool
  for o: Op.OCt
  {Op.hls_oct(Nil{}, x, surf, same, o) == o : Op.OCt}

def l1_oct_hls_nil(x, surf, same, o):
  {==}

law l1_oct_skip:
  for bad: Bool
  for cert: Nat
  for skip: Nat
  {Op.oct_add(Op.OCt{bad, cert, skip}, 0n)
    == Op.OCt{Bool.or(bad, False{}), Nat.add(cert, 0n),
      Nat.add(skip, 1n)} : Op.OCt}

def l1_oct_skip(bad, cert, skip):
  {==}

law l1_oct_fas_nil:
  for x: Ty.Ix
  for o: Op.OCt
  {Op.fas_oct(Nil{}, x, o) == o : Op.OCt}

def l1_oct_fas_nil(x, o):
  {==}

law l1_oct_bad:
  for bad: Bool
  for cert: Nat
  for skip: Nat
  {Op.oct_add(Op.OCt{bad, cert, skip}, 2n)
    == Op.OCt{Bool.or(bad, True{}), Nat.add(cert, 1n),
      Nat.add(skip, 0n)} : Op.OCt}

def l1_oct_bad(bad, cert, skip):
  {==}

law l1_cnt_false:
  for n: Nat
  {Op.cnt_pack(n, False{}) == 0n : Nat}

def l1_cnt_false(n):
  {==}

law l1_cnt_round:
  {Op.cnt_count(Op.cnt_pack(2n, True{})) == 2n : Nat}

def l1_cnt_round():
  {==}

law l1_cnt_done:
  {Op.cnt_done(Op.cnt_pack(2n, True{})) == True{} : Bool}

def l1_cnt_done():
  {==}

law l1_cnt_zero:
  {Bool.and(Bool.not(Op.cnt_done(0n)),
    Nat.is_eq(Op.cnt_count(0n), 0n)) == True{} : Bool}

def l1_cnt_zero():
  {==}

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

law ck_fuel_nurbs:
  {Nat.is_eq(Ty.ix_bound(b_nb_edge()), 9n) == True{} : Bool}

def ck_fuel_nurbs():
  {==}

law ck_embed_nurbs_short:
  {Op.brep_embed_c(b_nb_edge(), 2n) == 0n : Nat}

def ck_embed_nurbs_short():
  {==}

law ck_embed_nurbs_full:
  {Op.brep_embed_c(b_nb_edge(), 9n) == 3n : Nat}

def ck_embed_nurbs_full():
  {==}

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

law ck_cyl_round:
  {String.eq(Ty.tres_show(Op.brep_checked(b_cyl_round(),
    Ty.P_manifold_solid{}, 20n)), "ok") == True{} : Bool}

def ck_cyl_round():
  {==}
