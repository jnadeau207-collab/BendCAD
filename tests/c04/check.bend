# C04 test support: reporters over TRes + shared fixtures.
# Imported by neg.bend/pos.bend; no main here.

import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty

def verdict(ok: Bool) -> String:
  match ok:
    case True{}: "PASS"
    case False{}: "FAIL"

def bump(f: U64, ok: Bool) -> U64:
  (f + Bool.to_u64(Bool.not(ok)) : U64)

# Terr of the wanted kind (structured failure, no value published).
def terr_as(+r: Ty.TRes, want: String) -> Bool:
  String.eq(Ty.tres_show(r), want)

def report_terr(tag: String, +r: Ty.TRes, +want: String,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(terr_as(r, want))
      ++ " [" ++ Ty.tres_show(r) ++ "]")
    return bump(f, terr_as(r, want))

# Tok of any arm.
def ok_as(+r: Ty.TRes) -> Bool:
  String.eq(Ty.tres_show(r), "ok")

def report_ok(tag: String, +r: Ty.TRes, f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(ok_as(r))
      ++ " [" ++ Ty.tres_show(r) ++ "]")
    return bump(f, ok_as(r))

# Tok Nat pinned exactly.
def tn_as(+r: Ty.TRes, want: Nat) -> Bool:
  Bool.and(String.eq(Ty.tres_show(r), "ok"),
    Nat.is_eq(Ty.tres_n(r), want))

def report_tn(tag: String, +r: Ty.TRes, +want: Nat,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(tn_as(r, want))
      ++ " [" ++ Ty.tres_show(r) ++ "]")
    return bump(f, tn_as(r, want))

# Tok F64 pinned to exact bits.
def tf_as(+r: Ty.TRes, want: U64) -> Bool:
  Bool.and(String.eq(Ty.tres_show(r), "ok"),
    U64.is_eq(F64.bits(Ty.tres_f(r)), want))

def report_tf(tag: String, +r: Ty.TRes, +want: U64,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(tf_as(r, want))
      ++ " [" ++ Ty.tres_show(r) ++ "]")
    return bump(f, tf_as(r, want))

def report_pure(tag: String, +ok: Bool, f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(ok))
    return bump(f, ok)

# --- Shared fixtures ---
def p000() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def p100() -> V.Point:
  V.Pt{1.0f64, 0.0f64, 0.0f64}

def p010() -> V.Point:
  V.Pt{0.0f64, 1.0f64, 0.0f64}

def p001() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 1.0f64}

def p110() -> V.Point:
  V.Pt{1.0f64, 1.0f64, 0.0f64}

def p111() -> V.Point:
  V.Pt{1.0f64, 1.0f64, 1.0f64}

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

def dom_01() -> G.Dom:
  G.Dom{0.0f64, 1.0f64}

def dom_flip() -> G.Dom:
  G.Dom{2.0f64, 1.0f64}

def dom_eq() -> G.Dom:
  G.Dom{1.0f64, 1.0f64}

def dom_nan() -> G.Dom:
  G.Dom{F64.nan(), 1.0f64}

def dom_inf() -> G.Dom:
  G.Dom{0.0f64, F64{9218868437227405312u64}}

# Curve arms (all five).
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

# Surface arms (all six).
def sf_pl() -> G.GVal:
  G.GV_pl{G.Pl{p000(), d100(), d010()}}

def p_spc() -> V.Point:
  V.Pt{0.5f64, 0.5f64, 0.25f64}

def p_cyo() -> V.Point:
  V.Pt{0.0f64, 0.5f64, 0.0f64}

def p500() -> V.Point:
  V.Pt{5.0f64, 0.0f64, 0.0f64}

def vs_q() -> List<&2, Ty.Vertex>:
  Ty.Vx{1u64, p000()} <> Ty.Vx{2u64, p001()} <> Ty.Vx{3u64,
    p500()} <> Nil{}

def sf_cy() -> G.GVal:
  G.GV_cy{G.Cy{p_cyo(), d100(), 0.5f64}}

def sf_co() -> G.GVal:
  G.GV_co{G.Co{p000(), d001(), 0.5f64}}

def sf_sp() -> G.GVal:
  G.GV_sp{G.Sp{p_spc(), 0.75f64}}

def sf_to() -> G.GVal:
  G.GV_to{G.To{p000(), d001(), 4.0f64, 1.0f64}}

def sf_bp() -> G.GVal:
  G.GV_bp{G.Bp{p000(), p100(), p010(), p001(), p110(), p111(),
    p123(), p000(), p100(), p010(), p001(), p110(), p111(),
    p123(), p000(), p100()}}

# Trim arms (both).
def tr_ts() -> G.GVal:
  G.GV_ts{G.Ts{v2_00(), v2_11()}}

def tr_tb() -> G.GVal:
  G.GV_tb{G.Tb{v2_00(), v2_10(), v2_01(), v2_11()}}

# Unit-square trim legs (square/xing fixtures; each maps through
# sf_pl to its loop's vertex chain for G coincidence).
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

# Handle member lists: empty (typed) and singleton.
def hc0() -> List<&2, Ty.HCoedge>:
  Nil{}

def hc1() -> List<&2, Ty.HCoedge>:
  Ty.mk_hc(0n, 21u64) <> Nil{}

def hc2() -> List<&2, Ty.HCoedge>:
  Ty.mk_hc(0n, 21u64) <> Ty.mk_hc(1n, 22u64) <> Nil{}

def hlp0() -> List<&2, Ty.HLoop>:
  Nil{}

def hlp1() -> List<&2, Ty.HLoop>:
  Ty.mk_hlp(0n, 31u64) <> Nil{}

def hfa0() -> List<&2, Ty.HFace>:
  Nil{}

def hfa1() -> List<&2, Ty.HFace>:
  Ty.mk_hfa(0n, 41u64) <> Nil{}

def hsh0() -> List<&2, Ty.HShell>:
  Nil{}

def hsh1() -> List<&2, Ty.HShell>:
  Ty.mk_hsh(0n, 51u64) <> Nil{}

def hso0() -> List<&2, Ty.HSolid>:
  Nil{}

def hso1() -> List<&2, Ty.HSolid>:
  Ty.mk_hso(0n, 61u64) <> Nil{}

# Entity slots: valid values with known gens.
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
  Ty.Ed{11u64, Ty.mk_hv(0n, 1u64), Ty.mk_hv(1n, 2u64),
    Ty.EK_curve{cv_ln(), dom_01()}}

def ed_b() -> Ty.Edge:
  Ty.Ed{12u64, Ty.mk_hv(1n, 2u64), Ty.mk_hv(2n, 3u64),
    Ty.EK_curve{cv_cc(), dom_01()}}

def es0() -> List<&2, Ty.Edge>:
  Nil{}

def es1() -> List<&2, Ty.Edge>:
  ed_a() <> Nil{}

def es2() -> List<&2, Ty.Edge>:
  ed_a() <> ed_b() <> Nil{}

def es_badarm() -> List<&2, Ty.Edge>:
  Ty.Ed{11u64, Ty.mk_hv(0n, 1u64), Ty.mk_hv(1n, 2u64),
    Ty.EK_curve{sf_pl(), dom_01()}} <> Nil{}

def es_baddegen() -> List<&2, Ty.Edge>:
  Ty.Ed{11u64, Ty.mk_hv(0n, 1u64), Ty.mk_hv(1n, 2u64),
    Ty.EK_degenerate{}} <> Nil{}

def ce_a() -> Ty.Coedge:
  Ty.Ce{21u64, Ty.mk_he(0n, 11u64), True{}, tr_ts()}

def ce_b() -> Ty.Coedge:
  Ty.Ce{22u64, Ty.mk_he(0n, 11u64), False{}, tr_tb()}

def ces0() -> List<&2, Ty.Coedge>:
  Nil{}

def ces1() -> List<&2, Ty.Coedge>:
  ce_a() <> Nil{}

def ces2() -> List<&2, Ty.Coedge>:
  ce_a() <> ce_b() <> Nil{}

def ces_bad() -> List<&2, Ty.Coedge>:
  Ty.Ce{21u64, Ty.mk_he(0n, 11u64), True{}, cv_ln()} <>
    Nil{}

def lp_a() -> Ty.Loop:
  Ty.Lp{31u64, Ty.mk_hc(0n, 21u64) <> Nil{},
    Ty.LK_outer{}}

def lp_b() -> Ty.Loop:
  Ty.Lp{32u64, hc2(), Ty.LK_inner{}}

def lps0() -> List<&2, Ty.Loop>:
  Nil{}

def lps1() -> List<&2, Ty.Loop>:
  lp_a() <> Nil{}

def lps2() -> List<&2, Ty.Loop>:
  lp_a() <> lp_b() <> Nil{}

def lps_bad() -> List<&2, Ty.Loop>:
  Ty.Lp{31u64, hc0(), Ty.LK_outer{}} <> Nil{}

def fa_a() -> Ty.Face:
  Ty.Fa{41u64, sf_pl(), Ty.mk_hlp(0n, 31u64) <> Nil{},
    True{}}

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
  Ty.Sh{51u64, Ty.mk_hfa(0n, 41u64) <> Nil{},
    Ty.SK_outer{}}

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
  Ty.So{61u64, Ty.mk_hsh(0n, 51u64), hsh0()}

def so_b() -> Ty.Solid:
  Ty.So{62u64, Ty.mk_hsh(0n, 51u64), hsh1()}

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

# One-store breps for issued/fuel tests.
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

def b_full() -> Ty.Brep:
  Ty.Br{vs1(), es1(), ces1(), lps1(), fas1(), shs1(), sos1(),
    top1(), 61u64}

# --- brep_checked exit fixtures (push-protocol breps; verdicts pinned
# in laws ck_* and asserted in pos_g10/neg_g7). Handles name issued
# slots: hv01/hv12 are the first two pushed vertices. ---
def hv01() -> Ty.HVertex:
  Ty.mk_hv(0n, 1u64)

def hv12() -> Ty.HVertex:
  Ty.mk_hv(1n, 2u64)

def tr_closed() -> G.GVal:
  G.GV_ts{G.Ts{v2_00(), v2_00()}}

def tr_bad() -> G.GVal:
  G.GV_ts{G.Ts{V.V2{2.0f64, 2.0f64}, V.V2{3.0f64, 3.0f64}}}

def b_sphere() -> Ty.Brep:
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

def b_cyl() -> Ty.Brep:
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
  +b7 = Ty.tres_brep(Ty.fa_push(b6, sf_sp(), hlp0 <> Nil{},
    True{}))
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
  +b1 = Ty.tres_brep(Ty.vx_push(b0, p000()))
  +b2 = Ty.tres_brep(Ty.ed_push(b1, hv01(), hv01(),
    Ty.EK_degenerate{}))
  +b3 = Ty.tres_brep(Ty.ed_push(b2, hv01(), hv01(),
    Ty.EK_degenerate{}))
  +he0 = Ty.mk_he(0n, 2u64)
  +he1 = Ty.mk_he(1n, 3u64)
  +b4 = Ty.tres_brep(Ty.ce_push(b3, he0, True{}, tr_closed()))
  +b5 = Ty.tres_brep(Ty.ce_push(b4, he0, False{}, tr_closed()))
  +b6 = Ty.tres_brep(Ty.ce_push(b5, he1, True{}, tr_closed()))
  +b7 = Ty.tres_brep(Ty.ce_push(b6, he1, False{}, tr_closed()))
  +hc0 = Ty.mk_hc(0n, 4u64)
  +hc1 = Ty.mk_hc(1n, 5u64)
  +hc2 = Ty.mk_hc(2n, 6u64)
  +hc3 = Ty.mk_hc(3n, 7u64)
  +b8 = Ty.tres_brep(Ty.lp_push(b7,
    hc0 <> hc1 <> hc2 <> hc3 <> Nil{}, Ty.LK_outer{}))
  +hlp0 = Ty.mk_hlp(0n, 8u64)
  +b9 = Ty.tres_brep(Ty.fa_push(b8, sf_sp(), hlp0 <> Nil{}, True{}))
  +hfa0 = Ty.mk_hfa(0n, 9u64)
  +b10 = Ty.tres_brep(Ty.sh_push(b9, hfa0 <> Nil{}, Ty.SK_outer{}))
  +hsh_out = Ty.mk_hsh(0n, 10u64)
  +b11 = Ty.tres_brep(Ty.so_push(b10, hsh_out, hsh0()))
  +hso0x = Ty.mk_hso(0n, 11u64)
  Ty.brep_set_top(b11, Ty.Cp{hso0x <> Nil{}, hsh0()})

# C04.1 ownership fixtures: outer-kind + shell-ownership violations.
# Each is invalid-input under P_manifold_solid (stage F), diagnosed
# by laws ck_alias/ck_outerkind/ck_cavdup/ck_reuse/ck_cpshare and
# asserted in neg_g8. Value-level push still accepts them (shape-only
# by design); brep_checked is the verdict.
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

# C04.2 vertex-link fixture: two 1-edge cells sharing exactly one
# vertex (a pinch). Valid through stage G; stage H must diagnose
# invalid-input (two disjoint link orbits at the shared vertex).
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
  +b14 = Ty.tres_brep(Ty.sh_push(b13, hfaA <> Nil{}, Ty.SK_outer{}))
  +b15 = Ty.tres_brep(Ty.sh_push(b14, hfaB <> Nil{}, Ty.SK_outer{}))
  +hshA = Ty.mk_hsh(0n, 14u64)
  +hshB = Ty.mk_hsh(1n, 15u64)
  +b16 = Ty.tres_brep(Ty.so_push(b15, hshA, hsh0()))
  +b17 = Ty.tres_brep(Ty.so_push(b16, hshB, hsh0()))
  +hsoA = Ty.mk_hso(0n, 16u64)
  +hsoB = Ty.mk_hso(1n, 17u64)
  Ty.brep_set_top(b17, Ty.Cp{hsoA <> hsoB <> Nil{}, hsh0()})

# C04.2 quadric-membership fixture: b_sphere shape on the z-axis
# edge, but v1 sits off the sphere face. Passes every stage except
# the G quadric vertex-membership walk (invalid-input).
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

# C04.2 connectedness fixture: one shell, two unconnected digon
# cells (four distinct on-sphere points). Passes A-H; stage I must
# diagnose invalid-input (disconnected shell).
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

# Stage J fixture: b_sphere shape plus one unused vertex coincident
# with v0. Passes A-I; stage J must diagnose invalid-input.
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

# Stage K fixture: bowtie (self-crossing) quad loop on a plane face
# plus its reversed twin face (solid pairing). Passes A-J; stage K
# must diagnose invalid-input (e0/e2 cross at the square center).
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
  +b7 = Ty.tres_brep(Ty.ce_push(b6, he0, False{}, tr_00_10()))
  +b8 = Ty.tres_brep(Ty.ed_push(b7, hv1, hv2,
    Ty.EK_curve{G.GV_ln{G.Ln{p110(), d_0n10()}}, dom_01()}))
  +he1 = Ty.mk_he(1n, 8u64)
  +b9 = Ty.tres_brep(Ty.ce_push(b8, he1, True{}, tr_11_10()))
  +b10 = Ty.tres_brep(Ty.ce_push(b9, he1, False{}, tr_10_11()))
  +b11 = Ty.tres_brep(Ty.ed_push(b10, hv2, hv3,
    Ty.EK_curve{G.GV_ln{G.Ln{p100(), d_n110()}}, dom_01()}))
  +he2 = Ty.mk_he(2n, 11u64)
  +b12 = Ty.tres_brep(Ty.ce_push(b11, he2, True{}, tr_10_01()))
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
    True{}))
  +hfa0 = Ty.mk_hfa(0n, 19u64)
  +hfa1 = Ty.mk_hfa(1n, 20u64)
  +b21 = Ty.tres_brep(Ty.sh_push(b20, hfa0 <> hfa1 <> Nil{},
    Ty.SK_outer{}))
  +hshS = Ty.mk_hsh(0n, 21u64)
  +b22 = Ty.tres_brep(Ty.so_push(b21, hshS, hsh0()))
  +hsoS = Ty.mk_hso(0n, 22u64)
  Ty.brep_set_top(b22, Ty.Cp{hsoS <> Nil{}, hsh0()})

# Stage L-orientation fixture: clean (non-crossing) quad loop whose
# CCW winding disagrees with the same=False-adjusted plane normal.
# Passes A-K; per-face orientation must diagnose invalid-input.
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
    True{}))
  +hfa0 = Ty.mk_hfa(0n, 19u64)
  +hfa1 = Ty.mk_hfa(1n, 20u64)
  +b21 = Ty.tres_brep(Ty.sh_push(b20, hfa0 <> hfa1 <> Nil{},
    Ty.SK_outer{}))
  +hshS = Ty.mk_hsh(0n, 21u64)
  +b22 = Ty.tres_brep(Ty.so_push(b21, hshS, hsh0()))
  +hsoS = Ty.mk_hso(0n, 22u64)
  Ty.brep_set_top(b22, Ty.Cp{hsoS <> Nil{}, hsh0()})

# Stage L-propagation fixture: clean quad, both faces
# per-face-consistent (CCW/same=True, CW/same=False) but the shared
# edges join faces with disagreeing same flags. Passes A-K and
# per-face orientation; propagation must diagnose invalid-input.
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
