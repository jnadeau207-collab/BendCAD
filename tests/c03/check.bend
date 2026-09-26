# C03 test support: reporters over GRes + shared fixtures.
# Imported by neg.bend/pos.bend; no main here.

import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G

def verdict(ok: Bool) -> String:
  match ok:
    case True{}: "PASS"
    case False{}: "FAIL"

def bump(f: U64, ok: Bool) -> U64:
  (f + Bool.to_u64(Bool.not(ok)) : U64)

# Gerr of the wanted kind (structured failure, no value published).
def gerr_as(+r: G.GRes, want: String) -> Bool:
  String.eq(G.gres_show(r), want)

def report_gerr(tag: String, +r: G.GRes, +want: String,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(gerr_as(r, want))
      ++ " [" ++ G.gres_show(r) ++ "]")
    return bump(f, gerr_as(r, want))

# Gok F64 pinned to exact bits.
def gf_as(+r: G.GRes, want: U64) -> Bool:
  Bool.and(String.eq(G.gres_show(r), "ok"),
    U64.is_eq(F64.bits(G.gres_f(r)), want))

def report_gf(tag: String, +r: G.GRes, +want: U64,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(gf_as(r, want))
      ++ " [" ++ G.gres_show(r) ++ "]")
    return bump(f, gf_as(r, want))

# Gok Point pinned to exact component bits.
def gp_as(+r: G.GRes, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  +p = G.gres_p(r)
  Bool.and(String.eq(G.gres_show(r), "ok"),
    Bool.and(U64.is_eq(F64.bits(V.pt_x(p)), wx),
      Bool.and(U64.is_eq(F64.bits(V.pt_y(p)), wy),
        U64.is_eq(F64.bits(V.pt_z(p)), wz))))

def report_gp(tag: String, +r: G.GRes, +wx: U64, +wy: U64, +wz: U64,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(gp_as(r, wx, wy, wz))
      ++ " [" ++ G.gres_show(r) ++ "]")
    return bump(f, gp_as(r, wx, wy, wz))

# Gok Dir pinned to exact component bits.
def gd_as(+r: G.GRes, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  +d = G.gres_d(r)
  Bool.and(String.eq(G.gres_show(r), "ok"),
    Bool.and(U64.is_eq(F64.bits(V.dr_x(d)), wx),
      Bool.and(U64.is_eq(F64.bits(V.dr_y(d)), wy),
        U64.is_eq(F64.bits(V.dr_z(d)), wz))))

def report_gd(tag: String, +r: G.GRes, +wx: U64, +wy: U64, +wz: U64,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(gd_as(r, wx, wy, wz))
      ++ " [" ++ G.gres_show(r) ++ "]")
    return bump(f, gd_as(r, wx, wy, wz))

# Gok Vec2 pinned to exact component bits.
def gv2_as(+r: G.GRes, +wx: U64, +wy: U64) -> Bool:
  +v = G.gres_v2(r)
  Bool.and(String.eq(G.gres_show(r), "ok"),
    Bool.and(U64.is_eq(F64.bits(V.v2_x(v)), wx),
      U64.is_eq(F64.bits(V.v2_y(v)), wy)))

def report_gv2(tag: String, +r: G.GRes, +wx: U64, +wy: U64,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(gv2_as(r, wx, wy))
      ++ " [" ++ G.gres_show(r) ++ "]")
    return bump(f, gv2_as(r, wx, wy))

# Gok Dom pinned to exact endpoint bits.
def gdom_as(+r: G.GRes, +wlo: U64, +whi: U64) -> Bool:
  +d = G.gres_dom(r)
  Bool.and(String.eq(G.gres_show(r), "ok"),
    Bool.and(U64.is_eq(F64.bits(G.dom_lo(d)), wlo),
      U64.is_eq(F64.bits(G.dom_hi(d)), whi)))

def report_gdom(tag: String, +r: G.GRes, +wlo: U64, +whi: U64,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(gdom_as(r, wlo, whi))
      ++ " [" ++ G.gres_show(r) ++ "]")
    return bump(f, gdom_as(r, wlo, whi))

# Gok BBox3 pinned to exact corner bits.
def gbb_as(+r: G.GRes, +ax: U64, +ay: U64, +az: U64, +bx: U64,
    +by: U64, +bz: U64) -> Bool:
  +b = G.gres_bb(r)
  +lo = G.bb_lo(b)
  +hi = G.bb_hi(b)
  Bool.and(String.eq(G.gres_show(r), "ok"),
    Bool.and(U64.is_eq(F64.bits(V.pt_x(lo)), ax),
      Bool.and(U64.is_eq(F64.bits(V.pt_y(lo)), ay),
        Bool.and(U64.is_eq(F64.bits(V.pt_z(lo)), az),
          Bool.and(U64.is_eq(F64.bits(V.pt_x(hi)), bx),
            Bool.and(U64.is_eq(F64.bits(V.pt_y(hi)), by),
              U64.is_eq(F64.bits(V.pt_z(hi)), bz)))))))

def report_gbb(tag: String, +r: G.GRes, +ax: U64, +ay: U64, +az: U64,
    +bx: U64, +by: U64, +bz: U64, f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(gbb_as(r, ax, ay, az, bx, by, bz))
      ++ " [" ++ G.gres_show(r) ++ "]")
    return bump(f, gbb_as(r, ax, ay, az, bx, by, bz))

def report_pure(tag: String, +ok: Bool, f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(ok))
    return bump(f, ok)

# Projected point is the documented zero default. Single op call per
# use site: repeating a big op 3x in one Bool tree exceeds the native
# backend's 255 arity limit (C02 D2 class); let-bind instead.
def gres_p_is_zero(+r: G.GRes) -> Bool:
  +p = G.gres_p(r)
  Bool.and(U64.is_eq(F64.bits(V.pt_x(p)), 0u64),
    Bool.and(U64.is_eq(F64.bits(V.pt_y(p)), 0u64),
      U64.is_eq(F64.bits(V.pt_z(p)), 0u64)))

# Gok of any arm (geometry values have no projector; the show pin plus
# ops.bend behavior pins carry them).
def ok_as(+r: G.GRes) -> Bool:
  String.eq(G.gres_show(r), "ok")

def report_ok(tag: String, +r: G.GRes, f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(ok_as(r))
      ++ " [" ++ G.gres_show(r) ++ "]")
    return bump(f, ok_as(r))

# --- Shared fixtures ---
def p000() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def p100() -> V.Point:
  V.Pt{1.0f64, 0.0f64, 0.0f64}

def p010() -> V.Point:
  V.Pt{0.0f64, 1.0f64, 0.0f64}

def p001() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 1.0f64}

def p111() -> V.Point:
  V.Pt{1.0f64, 1.0f64, 1.0f64}

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

def v2_10() -> V.Vec2:
  V.V2{1.0f64, 0.0f64}

def ln_x() -> G.Line3:
  G.Ln{p000(), d100()}

def pl_xy() -> G.Plane3:
  G.Pl{p000(), d100(), d010()}

def cc_unit() -> G.Circle3:
  G.Cc{p000(), d100(), d010(), 1.0f64}

def bz_s() -> G.Bez3:
  G.Bz{p000(), p100(), p010(), p111()}

def p110() -> V.Point:
  V.Pt{1.0f64, 1.0f64, 0.0f64}

def rq_quarter() -> G.RQBez:
  G.Rq{p100(), p110(), p010(), 1.0f64, G.w_quarter(), 1.0f64}

def sp_unit() -> G.Sphere:
  G.Sp{p000(), 1.0f64}

def cy_z() -> G.Cyl:
  G.Cy{p000(), d001(), 1.0f64}

def co_z() -> G.Cone:
  G.Co{p000(), d001(), 0.5f64}

def to_z() -> G.Torus:
  G.To{p000(), d001(), 4.0f64, 1.0f64}

def bb_unit() -> G.BBox3:
  G.Bb{p000(), p111()}

def ts_diag() -> G.TSeg:
  G.Ts{v2_00(), v2_11()}

def tb_s() -> G.TBez:
  G.Tb{v2_00(), v2_10(), V.V2{0.0f64, 1.0f64}, v2_11()}

def mx() -> F64:
  F64{9218868437227405311u64}

# DBL_MAX minus one ulp: Dom{mxm1(), mx()} is a VALID domain whose
# midpoint sum overflows (C03.1 overflow fixture).
def mxm1() -> F64:
  F64{9218868437227405310u64}

def nmx() -> F64:
  F64{18442240474082181119u64}

def dom_25() -> G.Dom:
  G.Dom{2.0f64, 5.0f64}

def dom_010() -> G.Dom:
  G.Dom{0.0f64, 10.0f64}

def pdom_per() -> G.Pdom:
  G.Pdom{dom_010(), True{}}

def pdom_cl() -> G.Pdom:
  G.Pdom{dom_010(), False{}}

def ln_sk() -> G.Line3:
  G.Ln{p111(), V.Dr{0.0f64, 3.0f64, 4.0f64}}

def pl_d() -> G.Plane3:
  G.Pl{p111(), d100(), d010()}

def pl_bad() -> G.Plane3:
  G.Pl{p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, d010()}

def pl_skew() -> G.Plane3:
  G.Pl{p000(), d100(), V.Dr{0.5f64, 0.8660254037844386f64, 0.0f64}}

def cc_r2() -> G.Circle3:
  G.Cc{p000(), d100(), d010(), 2.0f64}

def bz_mx() -> G.Bez3:
  G.Bz{V.Pt{mx(), 0.0f64, 0.0f64}, V.Pt{nmx(), 0.0f64, 0.0f64},
    p000(), p000()}

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

def ax_big() -> V.Dir:
  V.Dr{F64{4607182418800026415u64}, 0.0f64, 0.0f64}

def ax_ok() -> V.Dir:
  V.Dr{F64{4607182418800019660u64}, 0.0f64, 0.0f64}

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

# Geometry unwraps (documented zero defaults).
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

# 3D box membership for enclosure probes.
def ev_in_bb(+e: G.GRes, +b: G.GRes) -> Bool:
  +p = G.gres_p(e)
  +bb = G.gres_bb(b)
  +lo = G.bb_lo(bb)
  +hi = G.bb_hi(bb)
  Bool.and(F64.is_le(V.pt_x(lo), V.pt_x(p)),
    Bool.and(F64.is_le(V.pt_x(p), V.pt_x(hi)),
      Bool.and(F64.is_le(V.pt_y(lo), V.pt_y(p)),
        Bool.and(F64.is_le(V.pt_y(p), V.pt_y(hi)),
          Bool.and(F64.is_le(V.pt_z(lo), V.pt_z(p)),
            F64.is_le(V.pt_z(p), V.pt_z(hi)))))))

def v2_in_bb(+e: G.GRes, +b: G.GRes) -> Bool:
  +v = G.gres_v2(e)
  +bb = G.gres_bb(b)
  +lo = G.bb_lo(bb)
  +hi = G.bb_hi(bb)
  Bool.and(F64.is_le(V.pt_x(lo), V.v2_x(v)),
    Bool.and(F64.is_le(V.v2_x(v), V.pt_x(hi)),
      Bool.and(F64.is_le(V.pt_y(lo), V.v2_y(v)),
        F64.is_le(V.v2_y(v), V.pt_y(hi)))))

def ev_eq(+a: G.GRes, +b: G.GRes) -> Bool:
  +pa = G.gres_p(a)
  +pb = G.gres_p(b)
  Bool.and(U64.is_eq(F64.bits(V.pt_x(pa)), F64.bits(V.pt_x(pb))),
    Bool.and(U64.is_eq(F64.bits(V.pt_y(pa)), F64.bits(V.pt_y(pb))),
      U64.is_eq(F64.bits(V.pt_z(pa)), F64.bits(V.pt_z(pb)))))
