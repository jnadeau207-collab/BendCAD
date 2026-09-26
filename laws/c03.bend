# C03 laws: every claim closed by the proof beneath it. Unbounded claims
# live as explicit laws in docs/c03-contract.md; this file proves the
# structural properties generally plus one instance per pipeline arm.
# Pins: F64 bit patterns from python struct (independent oracle).
# Scope: curves, surfaces, trims, NURBS data (MASTER_PLAN §10 C03).

import Base
import ../src/c00/types.bend as T
import ../src/c01/types.bend as V
import ../src/c03/types.bend as G
import ../src/c03/ops.bend as O

# --- Local GVal lifter (identity): lets one law range over all 19 arms.
# Every gok_* ctor below is Gok{arm}, so arm-exhaustiveness here covers
# every constructor's ok/kind shape. ---
def gok_wrap(v: G.GVal) -> G.GRes:
  G.Gok{v}

# --- Bit-equality helpers (exact pins, no show-format dependence) ---
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

# --- Fixtures ---
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

# --- Structural: general over every value arm and failure kind ---
law gok_ok:
  for v: G.GVal
  {G.gres_ok(gok_wrap(v)) == True{} : Bool}

def gok_ok(v):
  match v:
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

law gok_kind_doc:
  for v: G.GVal
  {G.gres_kind(gok_wrap(v)) == T.F_invalid{} : T.FailKind}

def gok_kind_doc(v):
  match v:
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

law gerr_show:
  for k: T.FailKind
  {G.gres_show(G.gerr(k)) == T.FailKind.show(k) : String}

def gerr_show(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law gerr_kind:
  for k: T.FailKind
  {G.gres_kind(G.gerr(k)) == k : T.FailKind}

def gerr_kind(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law gerr_f_zero:
  for k: T.FailKind
  {U64.is_eq(F64.bits(G.gres_f(G.gerr(k))), 0u64) == True{} : Bool}

def gerr_f_zero(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law gerr_p_zero:
  for k: T.FailKind
  {p_bits_eq(G.gerr(k), 0u64, 0u64, 0u64) == True{} : Bool}

def gerr_p_zero(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law gerr_d_zero:
  for k: T.FailKind
  {d_bits_eq(G.gerr(k), 0u64, 0u64, 0u64) == True{} : Bool}

def gerr_d_zero(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law gerr_v2_zero:
  for k: T.FailKind
  {v2_bits_eq(G.gerr(k), 0u64, 0u64) == True{} : Bool}

def gerr_v2_zero(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law gerr_dom_zero:
  for k: T.FailKind
  {dom_bits_eq(G.gerr(k), 0u64, 0u64) == True{} : Bool}

def gerr_dom_zero(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law gerr_bb_zero:
  for k: T.FailKind
  {bb_bits_eq(G.gerr(k), 0u64, 0u64, 0u64, 0u64, 0u64, 0u64)
    == True{} : Bool}

def gerr_bb_zero(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

# --- mk_dom: ok pin + every rejection arm ---
law dom_ok_pin:
  {Bool.and(String.eq(G.gres_show(G.mk_dom(0.0f64, 1.0f64)), "ok"),
    dom_bits_eq(G.mk_dom(0.0f64, 1.0f64), 0u64,
      4607182418800017408u64)) == True{} : Bool}

def dom_ok_pin():
  {==}

law dom_eq_inv:
  {String.eq(G.gres_show(G.mk_dom(1.0f64, 1.0f64)), "invalid-input")
    == True{} : Bool}

def dom_eq_inv():
  {==}

law dom_flip_inv:
  {String.eq(G.gres_show(G.mk_dom(2.0f64, 1.0f64)), "invalid-input")
    == True{} : Bool}

def dom_flip_inv():
  {==}

law dom_nan_inv:
  {String.eq(G.gres_show(G.mk_dom(F64.nan(), 1.0f64)), "invalid-input")
    == True{} : Bool}

def dom_nan_inv():
  {==}

law dom_inf_inv:
  {String.eq(G.gres_show(G.mk_dom(0.0f64,
      F64{9218868437227405312u64})), "invalid-input") == True{} : Bool}

def dom_inf_inv():
  {==}

# --- mk_line: ok pin + every rejection arm ---
law line_ok_pin:
  {String.eq(G.gres_show(G.mk_line(p000(), d100())), "ok")
    == True{} : Bool}

def line_ok_pin():
  {==}

law line_nan_p_inv:
  {String.eq(G.gres_show(G.mk_line(
      V.Pt{F64.nan(), 0.0f64, 0.0f64}, d100())), "invalid-input")
    == True{} : Bool}

def line_nan_p_inv():
  {==}

law line_nan_d_inv:
  {String.eq(G.gres_show(G.mk_line(p000(),
      V.Dr{0.0f64, F64.nan(), 0.0f64})), "invalid-input")
    == True{} : Bool}

def line_nan_d_inv():
  {==}

law line_zero_inv:
  {String.eq(G.gres_show(G.mk_line(p000(), d000())), "invalid-input")
    == True{} : Bool}

def line_zero_inv():
  {==}

law line_negzero_inv:
  {String.eq(G.gres_show(G.mk_line(p000(),
      V.Dr{F64{9223372036854775808u64}, 0.0f64, 0.0f64})),
    "invalid-input") == True{} : Bool}

def line_negzero_inv():
  {==}

# --- mk_plane: ok pin + rejection (takes a Plane3 value) ---
law plane_ok_pin:
  {String.eq(G.gres_show(G.mk_plane(G.Pl{p000(), d100(), d010()})),
    "ok") == True{} : Bool}

def plane_ok_pin():
  {==}

law plane_nan_inv:
  {String.eq(G.gres_show(G.mk_plane(G.Pl{p000(), d100(),
      V.Dr{0.0f64, 0.0f64, F64.nan()}})), "invalid-input")
    == True{} : Bool}

def plane_nan_inv():
  {==}

# --- mk_circ: ok pin + every rejection arm ---
law circ_ok_pin:
  {String.eq(G.gres_show(G.mk_circ(p000(), d100(), d010(), 2.0f64)),
    "ok") == True{} : Bool}

def circ_ok_pin():
  {==}

law circ_r0_inv:
  {String.eq(G.gres_show(G.mk_circ(p000(), d100(), d010(), 0.0f64)),
    "invalid-input") == True{} : Bool}

def circ_r0_inv():
  {==}

law circ_rneg_inv:
  {String.eq(G.gres_show(G.mk_circ(p000(), d100(), d010(),
      F64.neg(1.0f64))), "invalid-input") == True{} : Bool}

def circ_rneg_inv():
  {==}

law circ_rnan_inv:
  {String.eq(G.gres_show(G.mk_circ(p000(), d100(), d010(),
      F64.nan())), "invalid-input") == True{} : Bool}

def circ_rnan_inv():
  {==}

law circ_rinf_inv:
  {String.eq(G.gres_show(G.mk_circ(p000(), d100(), d010(),
      F64{9218868437227405312u64})), "invalid-input")
    == True{} : Bool}

def circ_rinf_inv():
  {==}

# --- mk_bez3: ok pin + rejection ---
law bez_ok_pin:
  {String.eq(G.gres_show(G.mk_bez3(p000(), p100(), p010(), p111())),
    "ok") == True{} : Bool}

def bez_ok_pin():
  {==}

law bez_nan_inv:
  {String.eq(G.gres_show(G.mk_bez3(p000(), p100(),
      V.Pt{0.0f64, F64.nan(), 0.0f64}, p111())), "invalid-input")
    == True{} : Bool}

def bez_nan_inv():
  {==}

# --- mk_rqbez: ok pin (quarter-circle weights) + every weight arm ---
law rq_ok_pin:
  {String.eq(G.gres_show(G.mk_rqbez(p100(), p111(), p010(), 1.0f64,
      G.w_quarter(), 1.0f64)), "ok") == True{} : Bool}

def rq_ok_pin():
  {==}

law rq_w0_inv:
  {String.eq(G.gres_show(G.mk_rqbez(p100(), p111(), p010(), 0.0f64,
      G.w_quarter(), 1.0f64)), "invalid-input") == True{} : Bool}

def rq_w0_inv():
  {==}

law rq_w1neg_inv:
  {String.eq(G.gres_show(G.mk_rqbez(p100(), p111(), p010(), 1.0f64,
      F64.neg(0.5f64), 1.0f64)), "invalid-input") == True{} : Bool}

def rq_w1neg_inv():
  {==}

law rq_wnan_inv:
  {String.eq(G.gres_show(G.mk_rqbez(p100(), p111(), p010(), 1.0f64,
      G.w_quarter(), F64.nan())), "invalid-input") == True{} : Bool}

def rq_wnan_inv():
  {==}

# --- mk_bezp: ok pin + rejection ---
law bp_ok_pin:
  {String.eq(G.gres_show(G.mk_bezp(p000(), p000(), p000(), p000(),
      p000(), p100(), p010(), p000(), p000(), p010(), p111(), p000(),
      p000(), p000(), p000(), p000())), "ok") == True{} : Bool}

def bp_ok_pin():
  {==}

law bp_nan_inv:
  {String.eq(G.gres_show(G.mk_bezp(p000(), p000(), p000(), p000(),
      p000(), p100(), p010(), p000(), p000(), p010(), p111(),
      V.Pt{F64.nan(), 0.0f64, 0.0f64}, p000(), p000(), p000(),
      p000())), "invalid-input") == True{} : Bool}

def bp_nan_inv():
  {==}

# --- Quadrics/torus: ok pins + every rejection arm ---
law sph_ok_pin:
  {String.eq(G.gres_show(G.mk_sph(p123(), 2.0f64)), "ok")
    == True{} : Bool}

def sph_ok_pin():
  {==}

law sph_r0_inv:
  {String.eq(G.gres_show(G.mk_sph(p123(), 0.0f64)), "invalid-input")
    == True{} : Bool}

def sph_r0_inv():
  {==}

law sph_rneg_inv:
  {String.eq(G.gres_show(G.mk_sph(p123(), F64.neg(2.0f64))),
    "invalid-input") == True{} : Bool}

def sph_rneg_inv():
  {==}

law cyl_ok_pin:
  {String.eq(G.gres_show(G.mk_cyl(p000(), d001(), 1.0f64)), "ok")
    == True{} : Bool}

def cyl_ok_pin():
  {==}

law cyl_axis0_inv:
  {String.eq(G.gres_show(G.mk_cyl(p000(), d000(), 1.0f64)),
    "invalid-input") == True{} : Bool}

def cyl_axis0_inv():
  {==}

law cyl_r0_inv:
  {String.eq(G.gres_show(G.mk_cyl(p000(), d001(), 0.0f64)),
    "invalid-input") == True{} : Bool}

def cyl_r0_inv():
  {==}

law cone_ok_pin:
  {String.eq(G.gres_show(G.mk_cone(p000(), d001(), 0.5f64)), "ok")
    == True{} : Bool}

def cone_ok_pin():
  {==}

law cone_k0_inv:
  {String.eq(G.gres_show(G.mk_cone(p000(), d001(), 0.0f64)),
    "invalid-input") == True{} : Bool}

def cone_k0_inv():
  {==}

law cone_axisnan_inv:
  {String.eq(G.gres_show(G.mk_cone(p000(),
      V.Dr{F64.nan(), 0.0f64, 0.0f64}, 0.5f64)), "invalid-input")
    == True{} : Bool}

def cone_axisnan_inv():
  {==}

law torus_ok_pin:
  {String.eq(G.gres_show(G.mk_torus(p000(), d001(), 4.0f64, 1.0f64)),
    "ok") == True{} : Bool}

def torus_ok_pin():
  {==}

law torus_R0_inv:
  {String.eq(G.gres_show(G.mk_torus(p000(), d001(), 0.0f64, 1.0f64)),
    "invalid-input") == True{} : Bool}

def torus_R0_inv():
  {==}

law torus_rneg_inv:
  {String.eq(G.gres_show(G.mk_torus(p000(), d001(), 4.0f64,
      F64.neg(1.0f64))), "invalid-input") == True{} : Bool}

def torus_rneg_inv():
  {==}

# --- mk_bbox: ok pin + every rejection arm ---
law bb_ok_pin:
  {Bool.and(String.eq(G.gres_show(G.mk_bbox(p000(), p111())), "ok"),
    bb_bits_eq(G.mk_bbox(p000(), p111()), 0u64, 0u64, 0u64,
      4607182418800017408u64, 4607182418800017408u64,
      4607182418800017408u64)) == True{} : Bool}

def bb_ok_pin():
  {==}

law bb_flipx_inv:
  {String.eq(G.gres_show(G.mk_bbox(p100(), p000())), "invalid-input")
    == True{} : Bool}

def bb_flipx_inv():
  {==}

law bb_nan_inv:
  {String.eq(G.gres_show(G.mk_bbox(p000(),
      V.Pt{F64.nan(), 1.0f64, 1.0f64})), "invalid-input")
    == True{} : Bool}

def bb_nan_inv():
  {==}

# --- Trims: ok pins + rejections ---
law tseg_ok_pin:
  {String.eq(G.gres_show(G.mk_tseg(v2_00(), v2_11())), "ok")
    == True{} : Bool}

def tseg_ok_pin():
  {==}

law tseg_nan_inv:
  {String.eq(G.gres_show(G.mk_tseg(v2_00(),
      V.V2{F64.nan(), 1.0f64})), "invalid-input") == True{} : Bool}

def tseg_nan_inv():
  {==}

law tbez_ok_pin:
  {String.eq(G.gres_show(G.mk_tbez(v2_00(), v2_11(), v2_00(),
      v2_11())), "ok") == True{} : Bool}

def tbez_ok_pin():
  {==}

law tbez_nan_inv:
  {String.eq(G.gres_show(G.mk_tbez(v2_00(), v2_11(),
      V.V2{0.0f64, F64.nan()}, v2_11())), "invalid-input")
    == True{} : Bool}

def tbez_nan_inv():
  {==}

# --- Scalar predicates: zero/positive classification ---
law dz_zero_true:
  {G.dr_is_zero(d000()) == True{} : Bool}

def dz_zero_true():
  {==}

law dz_negzero_true:
  {G.dr_is_zero(V.Dr{F64{9223372036854775808u64},
    F64{9223372036854775808u64}, F64{9223372036854775808u64}})
    == True{} : Bool}

def dz_negzero_true():
  {==}

law dz_unit_false:
  {G.dr_is_zero(d100()) == False{} : Bool}

def dz_unit_false():
  {==}

law spos_pos_true:
  {G.spos(2.0f64) == True{} : Bool}

def spos_pos_true():
  {==}

law spos_zero_false:
  {G.spos(0.0f64) == False{} : Bool}

def spos_zero_false():
  {==}

law spos_neg_false:
  {G.spos(F64.neg(1.0f64)) == False{} : Bool}

def spos_neg_false():
  {==}

law spos_inf_false:
  {G.spos(F64{9218868437227405312u64}) == False{} : Bool}

def spos_inf_false():
  {==}

law spos_nan_false:
  {G.spos(F64.nan()) == False{} : Bool}

def spos_nan_false():
  {==}

# --- Finiteness predicates: instances ---
law fin_ln_false:
  {G.ln_fin(G.Ln{V.Pt{F64.nan(), 0.0f64, 0.0f64}, d100()})
    == False{} : Bool}

def fin_ln_false():
  {==}

law fin_sp_true:
  {G.sp_fin(G.Sp{p123(), 2.0f64}) == True{} : Bool}

def fin_sp_true():
  {==}

law fin_dom_true:
  {G.dom_fin(G.Dom{0.0f64, 1.0f64}) == True{} : Bool}

def fin_dom_true():
  {==}

law fin_dom_inffalse:
  {G.dom_fin(G.Dom{0.0f64, F64{9218868437227405312u64}})
    == False{} : Bool}

def fin_dom_inffalse():
  {==}

# --- Semantic validity: the centralized layer (C03.1). Constructors
# and evaluators consume these; raw bypasses are malformed input. ---
law val_dom_ok:
  {G.dom_valid(G.Dom{0.0f64, 1.0f64}) == True{} : Bool}

def val_dom_ok():
  {==}

law val_dom_eq:
  {G.dom_valid(G.Dom{1.0f64, 1.0f64}) == False{} : Bool}

def val_dom_eq():
  {==}

law val_dom_flip:
  {G.dom_valid(G.Dom{2.0f64, 1.0f64}) == False{} : Bool}

def val_dom_flip():
  {==}

law val_ln_zero:
  {G.ln_valid(G.Ln{p000(), d000()}) == False{} : Bool}

def val_ln_zero():
  {==}

law val_cc_rneg:
  {G.cc_valid(G.Cc{p000(), d100(), d010(), F64.neg(1.0f64)})
    == False{} : Bool}

def val_cc_rneg():
  {==}

law val_rq_wneg:
  {G.rq_valid(G.Rq{p100(), p110(), p010(), F64.neg(1.0f64),
    1.0f64, 1.0f64}) == False{} : Bool}

def val_rq_wneg():
  {==}

law val_sp_r0:
  {G.sp_valid(G.Sp{p123(), 0.0f64}) == False{} : Bool}

def val_sp_r0():
  {==}

law val_cy_rneg:
  {G.cy_valid(G.Cy{p000(), d001(), F64.neg(1.0f64)})
    == False{} : Bool}

def val_cy_rneg():
  {==}

law val_co_kneg:
  {G.co_valid(G.Co{p000(), d001(), F64.neg(0.5f64)})
    == False{} : Bool}

def val_co_kneg():
  {==}

law val_to_R0:
  {G.to_valid(G.To{p000(), d001(), 0.0f64, 1.0f64})
    == False{} : Bool}

def val_to_R0():
  {==}

# --- Accessor roundtrips (bit-exact) ---
law acc_dom_lo:
  {U64.is_eq(F64.bits(G.dom_lo(G.Dom{2.0f64, 3.0f64})),
    4611686018427387904u64) == True{} : Bool}

def acc_dom_lo():
  {==}

law acc_dom_hi:
  {U64.is_eq(F64.bits(G.dom_hi(G.Dom{2.0f64, 3.0f64})),
    4613937818241073152u64) == True{} : Bool}

def acc_dom_hi():
  {==}

law acc_ln_p:
  {U64.is_eq(F64.bits(V.pt_x(G.ln_p(G.Ln{p123(), d100()}))),
    4607182418800017408u64) == True{} : Bool}

def acc_ln_p():
  {==}

law acc_ln_d:
  {U64.is_eq(F64.bits(V.dr_y(G.ln_d(G.Ln{p123(), d010()}))),
    4607182418800017408u64) == True{} : Bool}

def acc_ln_d():
  {==}

law acc_cc_r:
  {U64.is_eq(F64.bits(G.cc_r(G.Cc{p000(), d100(), d010(), 2.0f64})),
    4611686018427387904u64) == True{} : Bool}

def acc_cc_r():
  {==}

law acc_sp_r:
  {U64.is_eq(F64.bits(G.sp_r(G.Sp{p123(), 3.0f64})),
    4613937818241073152u64) == True{} : Bool}

def acc_sp_r():
  {==}

law acc_bb_hi:
  {U64.is_eq(F64.bits(V.pt_z(G.bb_hi(G.Bb{p000(), p123()}))),
    4613937818241073152u64) == True{} : Bool}

def acc_bb_hi():
  {==}

law acc_ts_b:
  {U64.is_eq(F64.bits(V.v2_x(G.ts_b(G.Ts{v2_00(), v2_11()}))),
    4607182418800017408u64) == True{} : Bool}

def acc_ts_b():
  {==}

# --- Quarter-circle weight pin (python struct sqrt(2)/2) ---
law wq_bits:
  {U64.is_eq(F64.bits(G.w_quarter()), 4604544271217802189u64)
    == True{} : Bool}

def wq_bits():
  {==}

# --- BN-11 (non-publishing failures): rejected constructors publish
# only documented defaults, never partial geometry. ---
law bn11_line_zero:
  {p_bits_eq(G.mk_line(p000(), d000()), 0u64, 0u64, 0u64)
    == True{} : Bool}

def bn11_line_zero():
  {==}

law bn11_dom_flip:
  {dom_bits_eq(G.mk_dom(2.0f64, 1.0f64), 0u64, 0u64) == True{} : Bool}

def bn11_dom_flip():
  {==}

law bn11_sph_neg:
  {Bool.and(String.eq(G.gres_show(G.mk_sph(p123(), F64.neg(1.0f64))),
      "invalid-input"),
    U64.is_eq(F64.bits(G.gres_f(G.mk_sph(p123(), F64.neg(1.0f64)))),
      0u64)) == True{} : Bool}

def bn11_sph_neg():
  {==}

# --- Ops fixtures (raw values; finiteness is gated at every entry) ---
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

# --- Geometry unwrap helpers (documented zero defaults; let behavior
# laws reach through geometry-returning ops without match-in-law). ---
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

# 3D box membership (exact comparisons; boxes are finite-gated).
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

# --- dom_mid/dom_len: pins + gates ---
law dmid_25:
  {f_bits_eq(O.dom_mid(dom_25()), 4615063718147915776u64)
    == True{} : Bool}

def dmid_25():
  {==}

law dmid_nan_inv:
  {String.eq(G.gres_show(O.dom_mid(G.Dom{F64.nan(), 1.0f64})),
    "invalid-input") == True{} : Bool}

def dmid_nan_inv():
  {==}

law dmid_ovf_unc:
  {String.eq(G.gres_show(O.dom_mid(G.Dom{
      F64{9218868437227405310u64}, F64{9218868437227405311u64}})),
    "numerical-uncertainty") == True{} : Bool}

def dmid_ovf_unc():
  {==}

law dlen_25:
  {f_bits_eq(O.dom_len(dom_25()), 4613937818241073152u64)
    == True{} : Bool}

def dlen_25():
  {==}

law dlen_nan_inv:
  {String.eq(G.gres_show(O.dom_len(G.Dom{0.0f64, F64.nan()})),
    "invalid-input") == True{} : Bool}

def dlen_nan_inv():
  {==}

law dlen_ovf_unc:
  {String.eq(G.gres_show(O.dom_len(G.Dom{
      F64{18442240474082181119u64}, F64{9218868437227405311u64}})),
    "numerical-uncertainty") == True{} : Bool}

def dlen_ovf_unc():
  {==}

# Raw degenerate domains rejected at every domain evaluator (C03.1).
law dmid_degen_inv:
  {String.eq(G.gres_show(O.dom_mid(G.Dom{1.0f64, 1.0f64})),
    "invalid-input") == True{} : Bool}

def dmid_degen_inv():
  {==}

law dlen_flip_inv:
  {String.eq(G.gres_show(O.dom_len(G.Dom{2.0f64, 1.0f64})),
    "invalid-input") == True{} : Bool}

def dlen_flip_inv():
  {==}

law clamp_degen_inv:
  {String.eq(G.gres_show(O.dom_clamp(G.Dom{0.0f64, 0.0f64},
      0.0f64)), "invalid-input") == True{} : Bool}

def clamp_degen_inv():
  {==}

law split_degen_inv:
  {String.eq(G.gres_show(O.dom_split_lo(G.Dom{0.0f64, 0.0f64},
      0.0f64)), "invalid-input") == True{} : Bool}

def split_degen_inv():
  {==}

# --- dom_clamp: five positions + gates ---
law clamp_in:
  {f_bits_eq(O.dom_clamp(G.Dom{0.0f64, 5.0f64}, 2.0f64),
    4611686018427387904u64) == True{} : Bool}

def clamp_in():
  {==}

law clamp_lo_edge:
  {f_bits_eq(O.dom_clamp(G.Dom{0.0f64, 5.0f64}, 0.0f64), 0u64)
    == True{} : Bool}

def clamp_lo_edge():
  {==}

law clamp_hi_edge:
  {f_bits_eq(O.dom_clamp(G.Dom{0.0f64, 5.0f64}, 5.0f64),
    4617315517961601024u64) == True{} : Bool}

def clamp_hi_edge():
  {==}

law clamp_under:
  {f_bits_eq(O.dom_clamp(G.Dom{0.0f64, 5.0f64}, F64.neg(1.0f64)),
    0u64) == True{} : Bool}

def clamp_under():
  {==}

law clamp_over:
  {f_bits_eq(O.dom_clamp(G.Dom{0.0f64, 5.0f64}, 7.0f64),
    4617315517961601024u64) == True{} : Bool}

def clamp_over():
  {==}

law clamp_nan_inv:
  {String.eq(G.gres_show(O.dom_clamp(G.Dom{0.0f64, 5.0f64},
      F64.nan())), "invalid-input") == True{} : Bool}

def clamp_nan_inv():
  {==}

law clamp_domnan_inv:
  {String.eq(G.gres_show(O.dom_clamp(G.Dom{F64.nan(), 5.0f64},
      2.0f64)), "invalid-input") == True{} : Bool}

def clamp_domnan_inv():
  {==}

# --- pdom_wrap: periodic arms + clamped fallback + gate ---
law wrap_under:
  {f_bits_eq(O.pdom_wrap(pdom_per(), F64.neg(3.0f64)),
    4619567317775286272u64) == True{} : Bool}

def wrap_under():
  {==}

law wrap_over:
  {f_bits_eq(O.pdom_wrap(pdom_per(), 13.0f64),
    4613937818241073152u64) == True{} : Bool}

def wrap_over():
  {==}

law wrap_in:
  {f_bits_eq(O.pdom_wrap(pdom_per(), 4.0f64),
    4616189618054758400u64) == True{} : Bool}

def wrap_in():
  {==}

law wrap_clamped:
  {f_bits_eq(O.pdom_wrap(pdom_cl(), 13.0f64),
    4621819117588971520u64) == True{} : Bool}

def wrap_clamped():
  {==}

law wrap_nan_inv:
  {String.eq(G.gres_show(O.pdom_wrap(pdom_per(), F64.nan())),
    "invalid-input") == True{} : Bool}

def wrap_nan_inv():
  {==}

law wrap_degen1_inv:
  {String.eq(G.gres_show(O.pdom_wrap(G.Pdom{G.Dom{
      F64{9218868437227405311u64}, 0.0f64}, True{}},
      F64.neg(F64{9218868437227405311u64}))), "invalid-input")
    == True{} : Bool}

def wrap_degen1_inv():
  {==}

law wrap_degen2_inv:
  {String.eq(G.gres_show(O.pdom_wrap(G.Pdom{G.Dom{0.0f64,
      F64.neg(F64{9218868437227405311u64})}, True{}},
      F64{9218868437227405311u64})), "invalid-input")
    == True{} : Bool}

def wrap_degen2_inv():
  {==}

# --- dom_split_lo/hi: halves + strict-interior gate ---
law split_lo_mid:
  {dom_bits_eq(O.dom_split_lo(dom_010(), 4.0f64), 0u64,
    4616189618054758400u64) == True{} : Bool}

def split_lo_mid():
  {==}

law split_hi_mid:
  {dom_bits_eq(O.dom_split_hi(dom_010(), 4.0f64),
    4616189618054758400u64, 4621819117588971520u64)
    == True{} : Bool}

def split_hi_mid():
  {==}

law split_at_lo_inv:
  {String.eq(G.gres_show(O.dom_split_lo(dom_010(), 0.0f64)),
    "invalid-input") == True{} : Bool}

def split_at_lo_inv():
  {==}

law split_at_hi_inv:
  {String.eq(G.gres_show(O.dom_split_hi(dom_010(), 10.0f64)),
    "invalid-input") == True{} : Bool}

def split_at_hi_inv():
  {==}

law split_out_inv:
  {String.eq(G.gres_show(O.dom_split_lo(dom_010(), 20.0f64)),
    "invalid-input") == True{} : Bool}

def split_out_inv():
  {==}

law split_nan_inv:
  {String.eq(G.gres_show(O.dom_split_hi(dom_010(), F64.nan())),
    "invalid-input") == True{} : Bool}

def split_nan_inv():
  {==}

# --- line_eval/line_der: pins + gates ---
law leval_t3:
  {p_bits_eq(O.line_eval(ln_x(), 3.0f64), 4613937818241073152u64,
    0u64, 0u64) == True{} : Bool}

def leval_t3():
  {==}

law leval_tneg:
  {p_bits_eq(O.line_eval(ln_x(), F64.neg(2.0f64)),
    13835058055282163712u64, 0u64, 0u64) == True{} : Bool}

def leval_tneg():
  {==}

law leval_nan_inv:
  {String.eq(G.gres_show(O.line_eval(ln_x(), F64.nan())),
    "invalid-input") == True{} : Bool}

def leval_nan_inv():
  {==}

law leval_ovf_unc:
  {String.eq(G.gres_show(O.line_eval(G.Ln{
        V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, d100()},
      F64{9218868437227405311u64})), "numerical-uncertainty")
    == True{} : Bool}

def leval_ovf_unc():
  {==}

law lder_x:
  {d_bits_eq(O.line_der(ln_x()), 4607182418800017408u64, 0u64, 0u64)
    == True{} : Bool}

def lder_x():
  {==}

law lder_nan_inv:
  {String.eq(G.gres_show(O.line_der(G.Ln{p000(),
      V.Dr{F64.nan(), 0.0f64, 0.0f64}})), "invalid-input")
    == True{} : Bool}

def lder_nan_inv():
  {==}

# Raw zero directions rejected at line evaluators (C03.1).
law leval_zero_inv:
  {String.eq(G.gres_show(O.line_eval(G.Ln{p000(), d000()},
      1.0f64)), "invalid-input") == True{} : Bool}

def leval_zero_inv():
  {==}

law lder_zero_inv:
  {String.eq(G.gres_show(O.line_der(G.Ln{p000(), d000()})),
    "invalid-input") == True{} : Bool}

def lder_zero_inv():
  {==}

# --- line_project/line_dist/line_seg_bbox ---
law lproj_t5:
  {f_bits_eq(O.line_project(ln_x(), V.Pt{5.0f64, 2.0f64, 0.0f64}),
    4617315517961601024u64) == True{} : Bool}

def lproj_t5():
  {==}

law lproj_sk:
  {f_bits_eq(O.line_project(ln_sk(), V.Pt{1.0f64, 2.0f64, 3.0f64}),
    4601597955262077993u64) == True{} : Bool}

def lproj_sk():
  {==}

law lproj_zero_inv:
  {String.eq(G.gres_show(O.line_project(G.Ln{p000(), d000()},
      p111())), "invalid-input") == True{} : Bool}

def lproj_zero_inv():
  {==}

# Nonzero but subnormal direction: d.d underflows to 0, so the
# parameter is uncomputable — uncertainty, not malformed input (C03.1).
law lproj_tiny_unc:
  {String.eq(G.gres_show(O.line_project(G.Ln{p000(),
      V.Dr{F64{1u64}, 0.0f64, 0.0f64}}, p111())),
    "numerical-uncertainty") == True{} : Bool}

def lproj_tiny_unc():
  {==}

law lproj_nan_inv:
  {String.eq(G.gres_show(O.line_project(ln_x(),
      V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")
    == True{} : Bool}

def lproj_nan_inv():
  {==}

law ldist_2:
  {f_bits_eq(O.line_dist(ln_x(), V.Pt{5.0f64, 2.0f64, 0.0f64}),
    4611686018427387904u64) == True{} : Bool}

def ldist_2():
  {==}

law ldist_sk:
  {f_bits_eq(O.line_dist(ln_sk(), V.Pt{1.0f64, 2.0f64, 3.0f64}),
    4600877379321698720u64) == True{} : Bool}

def ldist_sk():
  {==}

law ldist_zero_inv:
  {String.eq(G.gres_show(O.line_dist(G.Ln{p000(), d000()}, p111())),
    "invalid-input") == True{} : Bool}

def ldist_zero_inv():
  {==}

law ldist_tiny_unc:
  {String.eq(G.gres_show(O.line_dist(G.Ln{p000(),
      V.Dr{F64{1u64}, 0.0f64, 0.0f64}}, p111())),
    "numerical-uncertainty") == True{} : Bool}

def ldist_tiny_unc():
  {==}

law ldist_ovf_unc:
  {String.eq(G.gres_show(O.line_dist(ln_x(),
      V.Pt{F64{9218868437227405311u64}, F64{9218868437227405311u64},
        F64{9218868437227405311u64}})), "numerical-uncertainty")
    == True{} : Bool}

def ldist_ovf_unc():
  {==}

law segbb_pin:
  {bb_bits_eq(O.line_seg_bbox(p000(), p123()), 0u64, 0u64, 0u64,
    4607182418800017408u64, 4611686018427387904u64,
    4613937818241073152u64) == True{} : Bool}

def segbb_pin():
  {==}

law segbb_nan_inv:
  {String.eq(G.gres_show(O.line_seg_bbox(p000(),
      V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")
    == True{} : Bool}

def segbb_nan_inv():
  {==}

# --- plane_checked/plane_normal: frame validation arms ---
law plck_ok:
  {String.eq(G.gres_show(O.plane_checked(pl_xy())), "ok")
    == True{} : Bool}

def plck_ok():
  {==}

law plck_scale_inv:
  {String.eq(G.gres_show(O.plane_checked(pl_bad())),
    "invalid-input") == True{} : Bool}

def plck_scale_inv():
  {==}

law plck_skew_inv:
  {String.eq(G.gres_show(O.plane_checked(pl_skew())),
    "invalid-input") == True{} : Bool}

def plck_skew_inv():
  {==}

law plck_nan_inv:
  {String.eq(G.gres_show(O.plane_checked(G.Pl{p000(), d100(),
      V.Dr{F64.nan(), 0.0f64, 0.0f64}})), "invalid-input")
    == True{} : Bool}

def plck_nan_inv():
  {==}

law pln_xyz:
  {d_bits_eq(O.plane_normal(pl_xy()), 0u64, 0u64,
    4607182418800017408u64) == True{} : Bool}

def pln_xyz():
  {==}

law pln_frame_inv:
  {String.eq(G.gres_show(O.plane_normal(pl_bad())),
    "invalid-input") == True{} : Bool}

def pln_frame_inv():
  {==}

# --- plane_eval/plane_project/plane_dist/plane_uv_bbox ---
law pleval_23:
  {p_bits_eq(O.plane_eval(pl_xy(), 2.0f64, 3.0f64),
    4611686018427387904u64, 4613937818241073152u64, 0u64)
    == True{} : Bool}

def pleval_23():
  {==}

law pleval_d:
  {p_bits_eq(O.plane_eval(pl_d(), 2.0f64, 3.0f64),
    4613937818241073152u64, 4616189618054758400u64,
    4607182418800017408u64) == True{} : Bool}

def pleval_d():
  {==}

law pleval_nan_inv:
  {String.eq(G.gres_show(O.plane_eval(pl_xy(), F64.nan(), 0.0f64)),
    "invalid-input") == True{} : Bool}

def pleval_nan_inv():
  {==}

law pleval_ovf_unc:
  {String.eq(G.gres_show(O.plane_eval(G.Pl{
        V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, d100(),
        d010()},
      F64{9218868437227405311u64}, 0.0f64)),
    "numerical-uncertainty") == True{} : Bool}

def pleval_ovf_unc():
  {==}

law pleval_frame_inv:
  {String.eq(G.gres_show(O.plane_eval(pl_bad(), 1.0f64, 1.0f64)),
    "invalid-input") == True{} : Bool}

def pleval_frame_inv():
  {==}

law plproj_234:
  {v2_bits_eq(O.plane_project(pl_xy(), V.Pt{2.0f64, 3.0f64, 4.0f64}),
    4611686018427387904u64, 4613937818241073152u64)
    == True{} : Bool}

def plproj_234():
  {==}

law plproj_nan_inv:
  {String.eq(G.gres_show(O.plane_project(pl_xy(),
      V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")
    == True{} : Bool}

def plproj_nan_inv():
  {==}

law plproj_frame_inv:
  {String.eq(G.gres_show(O.plane_project(pl_bad(), p111())),
    "invalid-input") == True{} : Bool}

def plproj_frame_inv():
  {==}

law pldist_4:
  {f_bits_eq(O.plane_dist(pl_xy(), V.Pt{2.0f64, 3.0f64, 4.0f64}),
    4616189618054758400u64) == True{} : Bool}

def pldist_4():
  {==}

law pldist_d:
  {f_bits_eq(O.plane_dist(pl_d(), V.Pt{1.0f64, 1.0f64, 5.0f64}),
    4616189618054758400u64) == True{} : Bool}

def pldist_d():
  {==}

law pldist_nan_inv:
  {String.eq(G.gres_show(O.plane_dist(pl_xy(),
      V.Pt{0.0f64, F64.nan(), 0.0f64})), "invalid-input")
    == True{} : Bool}

def pldist_nan_inv():
  {==}

law plbb_pin:
  {bb_bits_eq(O.plane_uv_bbox(pl_xy(), 0.0f64, 2.0f64, 0.0f64,
      3.0f64), 0u64, 0u64, 0u64, 4611686018427387904u64,
    4613937818241073152u64, 0u64) == True{} : Bool}

def plbb_pin():
  {==}

law plbb_nan_inv:
  {String.eq(G.gres_show(O.plane_uv_bbox(pl_xy(), 0.0f64, 2.0f64,
      F64.nan(), 3.0f64)), "invalid-input") == True{} : Bool}

def plbb_nan_inv():
  {==}

law plbb_frame_inv:
  {String.eq(G.gres_show(O.plane_uv_bbox(pl_bad(), 0.0f64, 2.0f64,
      0.0f64, 3.0f64)), "invalid-input") == True{} : Bool}

def plbb_frame_inv():
  {==}

# --- circ_checked/circ_eval: rational circle arms ---
law cck_ok:
  {String.eq(G.gres_show(O.circ_checked(cc_unit())), "ok")
    == True{} : Bool}

def cck_ok():
  {==}

law cck_frame_inv:
  {String.eq(G.gres_show(O.circ_checked(G.Cc{p000(),
      V.Dr{2.0f64, 0.0f64, 0.0f64}, d010(), 1.0f64})),
    "invalid-input") == True{} : Bool}

def cck_frame_inv():
  {==}

law cck_r0_inv:
  {String.eq(G.gres_show(O.circ_checked(G.Cc{p000(), d100(), d010(),
      0.0f64})), "invalid-input") == True{} : Bool}

def cck_r0_inv():
  {==}

law ceval_t0:
  {p_bits_eq(O.circ_eval(cc_unit(), 0.0f64),
    4607182418800017408u64, 0u64, 0u64) == True{} : Bool}

def ceval_t0():
  {==}

law ceval_t1:
  {p_bits_eq(O.circ_eval(cc_unit(), 1.0f64),
    13830554455654793216u64, 0u64, 0u64) == True{} : Bool}

def ceval_t1():
  {==}

# Both ends evaluate to the seam bit-exactly (the -0.0 ny coefficient
# at t = -1 is absorbed by the inner +0.0 addend).
law ceval_tneg1:
  {p_bits_eq(O.circ_eval(cc_unit(), F64.neg(1.0f64)),
    13830554455654793216u64, 0u64, 0u64) == True{} : Bool}

def ceval_tneg1():
  {==}

law ceval_t05:
  {p_bits_eq(O.circ_eval(cc_unit(), 0.5f64), 13822087688355336684u64,
    4606822130829827768u64, 0u64) == True{} : Bool}

def ceval_t05():
  {==}

law ceval_r2:
  {p_bits_eq(O.circ_eval(cc_r2(), 0.0f64), 4611686018427387904u64,
    0u64, 0u64) == True{} : Bool}

def ceval_r2():
  {==}

law ceval_t2_inv:
  {String.eq(G.gres_show(O.circ_eval(cc_unit(), 2.0f64)),
    "invalid-input") == True{} : Bool}

def ceval_t2_inv():
  {==}

law ceval_nan_inv:
  {String.eq(G.gres_show(O.circ_eval(cc_unit(), F64.nan())),
    "invalid-input") == True{} : Bool}

def ceval_nan_inv():
  {==}

law ceval_r0_inv:
  {String.eq(G.gres_show(O.circ_eval(G.Cc{p000(), d100(), d010(),
      0.0f64}, 0.5f64)), "invalid-input") == True{} : Bool}

def ceval_r0_inv():
  {==}

law ceval_rneg_inv:
  {String.eq(G.gres_show(O.circ_eval(G.Cc{p000(), d100(), d010(),
      F64.neg(1.0f64)}, 0.5f64)), "invalid-input") == True{} : Bool}

def ceval_rneg_inv():
  {==}

law ceval_ovf_unc:
  {String.eq(G.gres_show(O.circ_eval(G.Cc{
        V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, d100(),
        d010(), F64{9218868437227405311u64}}, 0.0f64)),
    "numerical-uncertainty") == True{} : Bool}

def ceval_ovf_unc():
  {==}

# --- circ_der/circ_seam_pt/circ_bbox ---
law cder_t0:
  {d_bits_eq(O.circ_der(cc_unit(), 0.0f64), 0u64,
    4616189618054758400u64, 0u64) == True{} : Bool}

def cder_t0():
  {==}

# dz is exactly -0.0 here (both scaled terms are -0.0).
law cder_t05:
  {d_bits_eq(O.circ_der(cc_unit(), 0.5f64), 13837471984682434298u64,
    13829617706932300153u64, 9223372036854775808u64)
    == True{} : Bool}

def cder_t05():
  {==}

law cder_t2_inv:
  {String.eq(G.gres_show(O.circ_der(cc_unit(), 2.0f64)),
    "invalid-input") == True{} : Bool}

def cder_t2_inv():
  {==}

law cder_ovf_unc:
  {String.eq(G.gres_show(O.circ_der(G.Cc{p000(), d100(), d010(),
      F64{9218868437227405311u64}}, 0.5f64)),
    "numerical-uncertainty") == True{} : Bool}

def cder_ovf_unc():
  {==}

law cseam_pin:
  {p_bits_eq(O.circ_seam_pt(cc_unit()), 13830554455654793216u64,
    0u64, 0u64) == True{} : Bool}

def cseam_pin():
  {==}

law cseam_r0_inv:
  {String.eq(G.gres_show(O.circ_seam_pt(G.Cc{p000(), d100(), d010(),
      0.0f64})), "invalid-input") == True{} : Bool}

def cseam_r0_inv():
  {==}

law cbb_unit:
  {bb_bits_eq(O.circ_bbox(cc_unit()), 13830554455654793216u64,
    13830554455654793216u64, 0u64, 4607182418800017408u64,
    4607182418800017408u64, 0u64) == True{} : Bool}

def cbb_unit():
  {==}

law cbb_r0_inv:
  {String.eq(G.gres_show(O.circ_bbox(G.Cc{p000(), d100(), d010(),
      0.0f64})), "invalid-input") == True{} : Bool}

def cbb_r0_inv():
  {==}

# --- bez3_eval/bez3_der: Bernstein pins + gates ---
law beval_t0:
  {p_bits_eq(O.bez3_eval(bz_s(), 0.0f64), 0u64, 0u64, 0u64)
    == True{} : Bool}

def beval_t0():
  {==}

law beval_t1:
  {p_bits_eq(O.bez3_eval(bz_s(), 1.0f64), 4607182418800017408u64,
    4607182418800017408u64, 4607182418800017408u64)
    == True{} : Bool}

def beval_t1():
  {==}

law beval_t05:
  {p_bits_eq(O.bez3_eval(bz_s(), 0.5f64), 4602678819172646912u64,
    4602678819172646912u64, 4593671619917905920u64)
    == True{} : Bool}

def beval_t05():
  {==}

law beval_t03:
  {p_bits_eq(O.bez3_eval(bz_s(), 0.3f64), 4602102358420343487u64,
    4596950240446631641u64, 4583439441564520153u64)
    == True{} : Bool}

def beval_t03():
  {==}

law beval_t2_inv:
  {String.eq(G.gres_show(O.bez3_eval(bz_s(), 2.0f64)),
    "invalid-input") == True{} : Bool}

def beval_t2_inv():
  {==}

law beval_nan_inv:
  {String.eq(G.gres_show(O.bez3_eval(bz_s(), F64.nan())),
    "invalid-input") == True{} : Bool}

def beval_nan_inv():
  {==}

law beval_beznan_inv:
  {String.eq(G.gres_show(O.bez3_eval(G.Bz{p000(), p100(),
      V.Pt{F64.nan(), 0.0f64, 0.0f64}, p111()}, 0.5f64)),
    "invalid-input") == True{} : Bool}

def beval_beznan_inv():
  {==}

law bder_t0:
  {d_bits_eq(O.bez3_der(bz_s(), 0.0f64), 4613937818241073152u64,
    0u64, 0u64) == True{} : Bool}

def bder_t0():
  {==}

law bder_t05:
  {d_bits_eq(O.bez3_der(bz_s(), 0.5f64), 0u64,
    4609434218613702656u64, 4604930618986332160u64)
    == True{} : Bool}

def bder_t05():
  {==}

law bder_t2_inv:
  {String.eq(G.gres_show(O.bez3_der(bz_s(), 2.0f64)),
    "invalid-input") == True{} : Bool}

def bder_t2_inv():
  {==}

law bder_ovf_unc:
  {String.eq(G.gres_show(O.bez3_der(bz_mx(), 0.5f64)),
    "numerical-uncertainty") == True{} : Bool}

def bder_ovf_unc():
  {==}

# --- bez3_split_lo/hi: halves meet at the joint; strict gate ---
law bsplit_lo_ok:
  {String.eq(G.gres_show(O.bez3_split_lo(bz_s(), 0.5f64)), "ok")
    == True{} : Bool}

def bsplit_lo_ok():
  {==}

law bsplit_lo_end0:
  {p_bits_eq(O.bez3_end0(unwrap_bz(O.bez3_split_lo(bz_s(),
      0.5f64))), 0u64, 0u64, 0u64) == True{} : Bool}

def bsplit_lo_end0():
  {==}

law bsplit_lo_joint:
  {p_bits_eq(O.bez3_end1(unwrap_bz(O.bez3_split_lo(bz_s(),
      0.5f64))), 4602678819172646912u64, 4602678819172646912u64,
    4593671619917905920u64) == True{} : Bool}

def bsplit_lo_joint():
  {==}

law bsplit_lo_t0_inv:
  {String.eq(G.gres_show(O.bez3_split_lo(bz_s(), 0.0f64)),
    "invalid-input") == True{} : Bool}

def bsplit_lo_t0_inv():
  {==}

law bsplit_lo_t2_inv:
  {String.eq(G.gres_show(O.bez3_split_lo(bz_s(), 2.0f64)),
    "invalid-input") == True{} : Bool}

def bsplit_lo_t2_inv():
  {==}

law bsplit_hi_ok:
  {String.eq(G.gres_show(O.bez3_split_hi(bz_s(), 0.5f64)), "ok")
    == True{} : Bool}

def bsplit_hi_ok():
  {==}

law bsplit_hi_end1:
  {p_bits_eq(O.bez3_end1(unwrap_bz(O.bez3_split_hi(bz_s(),
      0.5f64))), 4607182418800017408u64, 4607182418800017408u64,
    4607182418800017408u64) == True{} : Bool}

def bsplit_hi_end1():
  {==}

law bsplit_hi_joint:
  {p_bits_eq(O.bez3_end0(unwrap_bz(O.bez3_split_hi(bz_s(),
      0.5f64))), 4602678819172646912u64, 4602678819172646912u64,
    4593671619917905920u64) == True{} : Bool}

def bsplit_hi_joint():
  {==}

law bsplit_hi_t1_inv:
  {String.eq(G.gres_show(O.bez3_split_hi(bz_s(), 1.0f64)),
    "invalid-input") == True{} : Bool}

def bsplit_hi_t1_inv():
  {==}

# --- bez3_bbox/bez3_end0/bez3_end1 ---
law bbbox_s:
  {bb_bits_eq(O.bez3_bbox(bz_s()), 0u64, 0u64, 0u64,
    4607182418800017408u64, 4607182418800017408u64,
    4607182418800017408u64) == True{} : Bool}

def bbbox_s():
  {==}

law bbbox_nan_inv:
  {String.eq(G.gres_show(O.bez3_bbox(G.Bz{p000(), p100(), p010(),
      V.Pt{0.0f64, 0.0f64, F64.nan()}})), "invalid-input")
    == True{} : Bool}

def bbbox_nan_inv():
  {==}

law bend0_s:
  {p_bits_eq(O.bez3_end0(bz_s()), 0u64, 0u64, 0u64)
    == True{} : Bool}

def bend0_s():
  {==}

law bend1_s:
  {p_bits_eq(O.bez3_end1(bz_s()), 4607182418800017408u64,
    4607182418800017408u64, 4607182418800017408u64)
    == True{} : Bool}

def bend1_s():
  {==}

law bend_nan_inv:
  {String.eq(G.gres_show(O.bez3_end0(G.Bz{
      V.Pt{F64.nan(), 0.0f64, 0.0f64}, p100(), p010(), p111()})),
    "invalid-input") == True{} : Bool}

def bend_nan_inv():
  {==}

# --- rqb_eval/rqb_der: rational conic pins + gates ---
law qeval_q0:
  {p_bits_eq(O.rqb_eval(rq_q(), 0.0f64), 4607182418800017408u64,
    0u64, 0u64) == True{} : Bool}

def qeval_q0():
  {==}

law qeval_q05:
  {p_bits_eq(O.rqb_eval(rq_q(), 0.5f64), 4604544271217802188u64,
    4604544271217802188u64, 0u64) == True{} : Bool}

def qeval_q05():
  {==}

law qeval_q1:
  {p_bits_eq(O.rqb_eval(rq_q(), 1.0f64), 0u64,
    4607182418800017408u64, 0u64) == True{} : Bool}

def qeval_q1():
  {==}

law qeval_t2_inv:
  {String.eq(G.gres_show(O.rqb_eval(rq_q(), 2.0f64)),
    "invalid-input") == True{} : Bool}

def qeval_t2_inv():
  {==}

law qeval_nan_inv:
  {String.eq(G.gres_show(O.rqb_eval(rq_q(), F64.nan())),
    "invalid-input") == True{} : Bool}

def qeval_nan_inv():
  {==}

# Non-positive conic weights rejected at every conic op (C03.1):
# the enclosure certificate needs D > 0 from positive weights.
law qeval_wneg_inv:
  {String.eq(G.gres_show(O.rqb_eval(G.Rq{p100(), p110(), p010(),
      F64.neg(1.0f64), 1.0f64, 1.0f64}, 0.5f64)),
    "invalid-input") == True{} : Bool}

def qeval_wneg_inv():
  {==}

law qder_q0:
  {d_bits_eq(O.rqb_der(rq_q(), 0.0f64), 0u64,
    4609047870845172685u64, 0u64) == True{} : Bool}

def qder_q0():
  {==}

law qder_t2_inv:
  {String.eq(G.gres_show(O.rqb_der(rq_q(), 2.0f64)),
    "invalid-input") == True{} : Bool}

def qder_t2_inv():
  {==}

law qder_ovf_unc:
  {String.eq(G.gres_show(O.rqb_der(G.Rq{
        V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64},
        V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, p000(),
        1.0f64, 1.0f64, 1.0f64}, 0.5f64)), "numerical-uncertainty")
    == True{} : Bool}

def qder_ovf_unc():
  {==}

law qder_w0_inv:
  {String.eq(G.gres_show(O.rqb_der(G.Rq{p100(), p110(), p010(),
      1.0f64, 0.0f64, 1.0f64}, 0.0f64)), "invalid-input")
    == True{} : Bool}

def qder_w0_inv():
  {==}

# --- rqb_bbox/rqb_disc/rq_quarter ---
law qbb_q:
  {bb_bits_eq(O.rqb_bbox(rq_q()), 0u64, 0u64, 0u64,
    4607182418800017408u64, 4607182418800017408u64, 0u64)
    == True{} : Bool}

def qbb_q():
  {==}

law qbb_nan_inv:
  {String.eq(G.gres_show(O.rqb_bbox(G.Rq{p100(), p111(),
      V.Pt{F64.nan(), 0.0f64, 0.0f64}, 1.0f64, 1.0f64, 1.0f64})),
    "invalid-input") == True{} : Bool}

def qbb_nan_inv():
  {==}

law qbb_wneg_inv:
  {String.eq(G.gres_show(O.rqb_bbox(G.Rq{p100(), p110(), p010(),
      1.0f64, 1.0f64, F64.neg(1.0f64)})), "invalid-input")
    == True{} : Bool}

def qbb_wneg_inv():
  {==}

law qdisc_q:
  {f_bits_eq(O.rqb_disc(rq_q()), 13826050856027422718u64)
    == True{} : Bool}

def qdisc_q():
  {==}

law qdisc_p:
  {f_bits_eq(O.rqb_disc(rq_p()), 0u64) == True{} : Bool}

def qdisc_p():
  {==}

law qdisc_h:
  {f_bits_eq(O.rqb_disc(rq_h()), 4613937818241073152u64)
    == True{} : Bool}

def qdisc_h():
  {==}

law qdisc_nan_inv:
  {String.eq(G.gres_show(O.rqb_disc(G.Rq{p100(), p111(), p010(),
      1.0f64, F64.nan(), 1.0f64})), "invalid-input")
    == True{} : Bool}

def qdisc_nan_inv():
  {==}

law qdisc_w0_inv:
  {String.eq(G.gres_show(O.rqb_disc(G.Rq{p100(), p110(), p010(),
      1.0f64, 0.0f64, 1.0f64})), "invalid-input")
    == True{} : Bool}

def qdisc_w0_inv():
  {==}

law rquarter_ok:
  {String.eq(G.gres_show(O.rq_quarter(p000(), d100(), d010(),
      2.0f64)), "ok") == True{} : Bool}

def rquarter_ok():
  {==}

law rquarter_eval:
  {p_bits_eq(O.rqb_eval(unwrap_rq(O.rq_quarter(p000(), d100(),
      d010(), 2.0f64)), 0.5f64), 4609047870845172684u64,
    4609047870845172684u64, 0u64) == True{} : Bool}

def rquarter_eval():
  {==}

law rquarter_frame_inv:
  {String.eq(G.gres_show(O.rq_quarter(p000(),
      V.Dr{2.0f64, 0.0f64, 0.0f64}, d010(), 2.0f64)),
    "invalid-input") == True{} : Bool}

def rquarter_frame_inv():
  {==}

law rquarter_r0_inv:
  {String.eq(G.gres_show(O.rq_quarter(p000(), d100(), d010(),
      0.0f64)), "invalid-input") == True{} : Bool}

def rquarter_r0_inv():
  {==}

# --- bezp_eval/bezp_du/bezp_dv: tensor pins + gates ---
law peval_flat:
  {p_bits_eq(O.bezp_eval(bp_flat(), 0.5f64, 0.5f64),
    4609434218613702656u64, 4609434218613702656u64, 0u64)
    == True{} : Bool}

def peval_flat():
  {==}

law peval_bump:
  {p_bits_eq(O.bezp_eval(bp_bump(), 0.5f64, 0.5f64),
    4609434218613702656u64, 4609434218613702656u64,
    4603241769126068224u64) == True{} : Bool}

def peval_bump():
  {==}

law peval_c33:
  {p_bits_eq(O.bezp_eval(bp_bump(), 1.0f64, 1.0f64),
    4613937818241073152u64, 4613937818241073152u64, 0u64)
    == True{} : Bool}

def peval_c33():
  {==}

law peval_u2_inv:
  {String.eq(G.gres_show(O.bezp_eval(bp_flat(), 2.0f64, 0.5f64)),
    "invalid-input") == True{} : Bool}

def peval_u2_inv():
  {==}

law peval_nan_inv:
  {String.eq(G.gres_show(O.bezp_eval(bp_flat(), 0.5f64, F64.nan())),
    "invalid-input") == True{} : Bool}

def peval_nan_inv():
  {==}

law pdu_flat:
  {d_bits_eq(O.bezp_du(bp_flat(), 0.5f64, 0.5f64), 0u64,
    4613937818241073152u64, 0u64) == True{} : Bool}

def pdu_flat():
  {==}

law pdu_u2_inv:
  {String.eq(G.gres_show(O.bezp_du(bp_flat(), 2.0f64, 0.5f64)),
    "invalid-input") == True{} : Bool}

def pdu_u2_inv():
  {==}

law pdu_ovf_unc:
  {String.eq(G.gres_show(O.bezp_du(G.Bp{
        V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64},
        V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, p000(),
        p000(), p000(), p000(), p000(), p000(), p000(), p000(),
        p000(), p000(), p000(), p000(), p000(), p000()}, 0.5f64,
      0.5f64)), "numerical-uncertainty") == True{} : Bool}

def pdu_ovf_unc():
  {==}

law pdv_flat:
  {d_bits_eq(O.bezp_dv(bp_flat(), 0.5f64, 0.5f64),
    4613937818241073152u64, 0u64, 0u64) == True{} : Bool}

def pdv_flat():
  {==}

law pdv_v2_inv:
  {String.eq(G.gres_show(O.bezp_dv(bp_flat(), 0.5f64, 2.0f64)),
    "invalid-input") == True{} : Bool}

def pdv_v2_inv():
  {==}

law pdv_ovf_unc:
  {String.eq(G.gres_show(O.bezp_dv(G.Bp{
        V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64},
        V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64},
        V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64},
        V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64},
        V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64},
        V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64},
        V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64},
        V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, p000(),
        p000(), p000(), p000(), p000(), p000(), p000(), p000()},
      0.5f64, 0.5f64)), "numerical-uncertainty") == True{} : Bool}

def pdv_ovf_unc():
  {==}

# --- bezp_bbox/bezp_iso/bezp_corners/bbox_union ---
law pbb_flat:
  {bb_bits_eq(O.bezp_bbox(bp_flat()), 0u64, 0u64, 0u64,
    4613937818241073152u64, 4613937818241073152u64, 0u64)
    == True{} : Bool}

def pbb_flat():
  {==}

law pbb_bump:
  {bb_bits_eq(O.bezp_bbox(bp_bump()), 0u64, 0u64, 0u64,
    4613937818241073152u64, 4613937818241073152u64,
    4616189618054758400u64) == True{} : Bool}

def pbb_bump():
  {==}

law pbb_nan_inv:
  {String.eq(G.gres_show(O.bezp_bbox(G.Bp{p000(), p000(), p000(),
      p000(), p000(), p000(), p000(), p000(), p000(), p000(),
      p000(), p000(), p000(), p000(), p000(),
      V.Pt{F64.nan(), 0.0f64, 0.0f64}})), "invalid-input")
    == True{} : Bool}

def pbb_nan_inv():
  {==}

law piso_u_ok:
  {String.eq(G.gres_show(O.bezp_iso_u(bp_flat(), 0.5f64)), "ok")
    == True{} : Bool}

def piso_u_ok():
  {==}

law piso_u_end0:
  {p_bits_eq(O.bez3_end0(unwrap_bz(O.bezp_iso_u(bp_flat(),
      0.5f64))), 0u64, 4609434218613702656u64, 0u64)
    == True{} : Bool}

def piso_u_end0():
  {==}

law piso_u_u2_inv:
  {String.eq(G.gres_show(O.bezp_iso_u(bp_flat(), 2.0f64)),
    "invalid-input") == True{} : Bool}

def piso_u_u2_inv():
  {==}

law piso_v_ok:
  {String.eq(G.gres_show(O.bezp_iso_v(bp_flat(), 0.5f64)), "ok")
    == True{} : Bool}

def piso_v_ok():
  {==}

law piso_v_end1:
  {p_bits_eq(O.bez3_end1(unwrap_bz(O.bezp_iso_v(bp_flat(),
      0.5f64))), 4609434218613702656u64, 4613937818241073152u64,
    0u64) == True{} : Bool}

def piso_v_end1():
  {==}

law piso_v_v2_inv:
  {String.eq(G.gres_show(O.bezp_iso_v(bp_flat(), 2.0f64)),
    "invalid-input") == True{} : Bool}

def piso_v_v2_inv():
  {==}

law pcorner_pins:
  {Bool.and(p_bits_eq(O.bezp_c00(bp_flat()), 0u64, 0u64, 0u64),
    Bool.and(p_bits_eq(O.bezp_c03(bp_flat()), 0u64,
        4613937818241073152u64, 0u64),
      Bool.and(p_bits_eq(O.bezp_c30(bp_flat()),
          4613937818241073152u64, 0u64, 0u64),
        p_bits_eq(O.bezp_c33(bp_flat()), 4613937818241073152u64,
          4613937818241073152u64, 0u64)))) == True{} : Bool}

def pcorner_pins():
  {==}

law pcorner_nan_inv:
  {String.eq(G.gres_show(O.bezp_c33(G.Bp{p000(), p000(), p000(),
      p000(), p000(), p000(), p000(), p000(), p000(), p000(),
      p000(), p000(), p000(), p000(), p000(),
      V.Pt{0.0f64, F64.nan(), 0.0f64}})), "invalid-input")
    == True{} : Bool}

def pcorner_nan_inv():
  {==}

law bbunion_pin:
  {bb_bits_eq(O.bbox_union(G.Bb{p000(), p111()},
      G.Bb{V.Pt{2.0f64, 2.0f64, 2.0f64},
        V.Pt{3.0f64, 3.0f64, 3.0f64}}), 0u64, 0u64, 0u64,
    4613937818241073152u64, 4613937818241073152u64,
    4613937818241073152u64) == True{} : Bool}

def bbunion_pin():
  {==}

law bbunion_nan_inv:
  {String.eq(G.gres_show(O.bbox_union(G.Bb{p000(), p111()},
      G.Bb{V.Pt{F64.nan(), 0.0f64, 0.0f64}, p111()})),
    "invalid-input") == True{} : Bool}

def bbunion_nan_inv():
  {==}

# --- Quadric frame validation: unit-axis arms + threshold pins ---
law cyck_ok:
  {String.eq(G.gres_show(O.cyl_checked(cy_z())), "ok")
    == True{} : Bool}

def cyck_ok():
  {==}

law cyck_axis2_inv:
  {String.eq(G.gres_show(O.cyl_checked(G.Cy{p000(),
      V.Dr{2.0f64, 0.0f64, 0.0f64}, 1.0f64})), "invalid-input")
    == True{} : Bool}

def cyck_axis2_inv():
  {==}

law cyck_nan_inv:
  {String.eq(G.gres_show(O.cyl_checked(G.Cy{p000(),
      V.Dr{F64.nan(), 0.0f64, 0.0f64}, 1.0f64})), "invalid-input")
    == True{} : Bool}

def cyck_nan_inv():
  {==}

law cyck_axbig_inv:
  {String.eq(G.gres_show(O.cyl_checked(G.Cy{p000(), ax_big(),
      1.0f64})), "invalid-input") == True{} : Bool}

def cyck_axbig_inv():
  {==}

law cyck_axok_ok:
  {String.eq(G.gres_show(O.cyl_checked(G.Cy{p000(), ax_ok(),
      1.0f64})), "ok") == True{} : Bool}

def cyck_axok_ok():
  {==}

# Non-positive radii/slopes rejected at quadric entries (C03.1).
law cyck_rneg_inv:
  {String.eq(G.gres_show(O.cyl_checked(G.Cy{p000(), d001(),
      F64.neg(1.0f64)})), "invalid-input") == True{} : Bool}

def cyck_rneg_inv():
  {==}

law cock_ok:
  {String.eq(G.gres_show(O.cone_checked(co_z())), "ok")
    == True{} : Bool}

def cock_ok():
  {==}

law cock_axis2_inv:
  {String.eq(G.gres_show(O.cone_checked(G.Co{p000(),
      V.Dr{2.0f64, 0.0f64, 0.0f64}, 0.5f64})), "invalid-input")
    == True{} : Bool}

def cock_axis2_inv():
  {==}

law cock_nan_inv:
  {String.eq(G.gres_show(O.cone_checked(G.Co{p000(),
      V.Dr{F64.nan(), 0.0f64, 0.0f64}, 0.5f64})), "invalid-input")
    == True{} : Bool}

def cock_nan_inv():
  {==}

law cock_kneg_inv:
  {String.eq(G.gres_show(O.cone_checked(G.Co{p000(), d001(),
      F64.neg(0.5f64)})), "invalid-input") == True{} : Bool}

def cock_kneg_inv():
  {==}

law tock_ok:
  {String.eq(G.gres_show(O.tor_checked(to_z())), "ok")
    == True{} : Bool}

def tock_ok():
  {==}

law tock_axis2_inv:
  {String.eq(G.gres_show(O.tor_checked(G.To{p000(),
      V.Dr{2.0f64, 0.0f64, 0.0f64}, 4.0f64, 1.0f64})),
    "invalid-input") == True{} : Bool}

def tock_axis2_inv():
  {==}

law tock_nan_inv:
  {String.eq(G.gres_show(O.tor_checked(G.To{p000(),
      V.Dr{F64.nan(), 0.0f64, 0.0f64}, 4.0f64, 1.0f64})),
    "invalid-input") == True{} : Bool}

def tock_nan_inv():
  {==}

law tock_R0_inv:
  {String.eq(G.gres_show(O.tor_checked(G.To{p000(), d001(),
      0.0f64, 1.0f64})), "invalid-input") == True{} : Bool}

def tock_R0_inv():
  {==}

# --- sph_val/sph_grad: implicit value + gradient arms ---
law sphv_on:
  {f_bits_eq(O.sph_val(sp_unit(), p100()), 0u64) == True{} : Bool}

def sphv_on():
  {==}

law sphv_out:
  {f_bits_eq(O.sph_val(sp_unit(), V.Pt{2.0f64, 0.0f64, 0.0f64}),
    4613937818241073152u64) == True{} : Bool}

def sphv_out():
  {==}

law sphv_in:
  {f_bits_eq(O.sph_val(sp_unit(), p000()),
    13830554455654793216u64) == True{} : Bool}

def sphv_in():
  {==}

law sphv_nan_inv:
  {String.eq(G.gres_show(O.sph_val(sp_unit(),
      V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")
    == True{} : Bool}

def sphv_nan_inv():
  {==}

law sphv_ovf_unc:
  {String.eq(G.gres_show(O.sph_val(sp_unit(),
      V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})),
    "numerical-uncertainty") == True{} : Bool}

def sphv_ovf_unc():
  {==}

# Non-positive sphere radii rejected at every sphere op (C03.1).
law sphv_rneg_inv:
  {String.eq(G.gres_show(O.sph_val(G.Sp{p000(), F64.neg(1.0f64)},
      p100())), "invalid-input") == True{} : Bool}

def sphv_rneg_inv():
  {==}

law sphg_123:
  {d_bits_eq(O.sph_grad(sp_unit(), p123()),
    4611686018427387904u64, 4616189618054758400u64,
    4618441417868443648u64) == True{} : Bool}

def sphg_123():
  {==}

law sphg_nan_inv:
  {String.eq(G.gres_show(O.sph_grad(sp_unit(),
      V.Pt{0.0f64, F64.nan(), 0.0f64})), "invalid-input")
    == True{} : Bool}

def sphg_nan_inv():
  {==}

law sphg_ovf_unc:
  {String.eq(G.gres_show(O.sph_grad(sp_unit(),
      V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})),
    "numerical-uncertainty") == True{} : Bool}

def sphg_ovf_unc():
  {==}

law sphg_r0_inv:
  {String.eq(G.gres_show(O.sph_grad(G.Sp{p000(), 0.0f64}, p123())),
    "invalid-input") == True{} : Bool}

def sphg_r0_inv():
  {==}

# --- sph_project/sph_pole_n/sph_pole_s ---
law sphp_200:
  {p_bits_eq(O.sph_project(sp_unit(), V.Pt{2.0f64, 0.0f64, 0.0f64}),
    4607182418800017408u64, 0u64, 0u64) == True{} : Bool}

def sphp_200():
  {==}

# x pin is the scaled formulation (C03.1): fl(0.75/1.25) is the
# correctly-rounded 0.6 (...011); the old (r/n)*m spelling rounded
# fl(fl(1/5)*3) one ulp higher (...012).
law sphp_345:
  {p_bits_eq(O.sph_project(sp_unit(), V.Pt{3.0f64, 4.0f64, 0.0f64}),
    4603579539098121011u64, 4605380978949069210u64, 0u64)
    == True{} : Bool}

def sphp_345():
  {==}

law sphp_center_inv:
  {String.eq(G.gres_show(O.sph_project(sp_unit(), p000())),
    "invalid-input") == True{} : Bool}

def sphp_center_inv():
  {==}

law sphp_nan_inv:
  {String.eq(G.gres_show(O.sph_project(sp_unit(),
      V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")
    == True{} : Bool}

def sphp_nan_inv():
  {==}

law sphp_far_unc:
  {String.eq(G.gres_show(O.sph_project(sp_unit(),
      V.Pt{F64{9218868437227405311u64},
        F64{9218868437227405311u64}, 0.0f64})),
      "numerical-uncertainty") == True{} : Bool}

def sphp_far_unc():
  {==}

law sphp_rneg_inv:
  {String.eq(G.gres_show(O.sph_project(G.Sp{p000(),
      F64.neg(1.0f64)}, V.Pt{2.0f64, 0.0f64, 0.0f64})),
    "invalid-input") == True{} : Bool}

def sphp_rneg_inv():
  {==}

# Scaled projection (C03.1): finite norm + tiny r/n ratio still
# publishes the surface point, never the center. r=1 at DBL_MAX on
# one axis; r=DBL_MIN at DBL_MAX; offset center at DBL_MAX.
law sphp_faraxis_ok:
  {p_bits_eq(O.sph_project(sp_unit(),
      V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}),
    4607182418800017408u64, 0u64, 0u64) == True{} : Bool}

def sphp_faraxis_ok():
  {==}

law sphp_minr_ok:
  {p_bits_eq(O.sph_project(G.Sp{p000(), F64{1u64}},
      V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}),
    1u64, 0u64, 0u64) == True{} : Bool}

def sphp_minr_ok():
  {==}

law sphp_farctr_ok:
  {p_bits_eq(O.sph_project(G.Sp{p100(), 1.0f64},
      V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}),
    4611686018427387904u64, 0u64, 0u64) == True{} : Bool}

def sphp_farctr_ok():
  {==}

law spolen_n:
  {p_bits_eq(O.sph_pole_n(sp_unit(), d001()),
    0u64, 0u64, 4607182418800017408u64) == True{} : Bool}

def spolen_n():
  {==}

law spolen_s:
  {p_bits_eq(O.sph_pole_s(sp_unit(), d001()), 0u64, 0u64,
    13830554455654793216u64) == True{} : Bool}

def spolen_s():
  {==}

law spolen_axis2_inv:
  {String.eq(G.gres_show(O.sph_pole_n(sp_unit(),
      V.Dr{2.0f64, 0.0f64, 0.0f64})), "invalid-input")
    == True{} : Bool}

def spolen_axis2_inv():
  {==}

law spolen_r0_inv:
  {String.eq(G.gres_show(O.sph_pole_n(G.Sp{p000(), 0.0f64},
      d001())), "invalid-input") == True{} : Bool}

def spolen_r0_inv():
  {==}

# --- cyl_val/cyl_grad ---
law cylv_on:
  {f_bits_eq(O.cyl_val(cy_z(), V.Pt{1.0f64, 0.0f64, 5.0f64}), 0u64)
    == True{} : Bool}

def cylv_on():
  {==}

law cylv_off:
  {f_bits_eq(O.cyl_val(cy_z(), V.Pt{2.0f64, 0.0f64, 0.0f64}),
    4613937818241073152u64) == True{} : Bool}

def cylv_off():
  {==}

law cylv_nan_inv:
  {String.eq(G.gres_show(O.cyl_val(cy_z(),
      V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")
    == True{} : Bool}

def cylv_nan_inv():
  {==}

law cylv_axis2_inv:
  {String.eq(G.gres_show(O.cyl_val(G.Cy{p000(),
      V.Dr{2.0f64, 0.0f64, 0.0f64}, 1.0f64}, p100())),
    "invalid-input") == True{} : Bool}

def cylv_axis2_inv():
  {==}

law cylv_ovf_unc:
  {String.eq(G.gres_show(O.cyl_val(cy_z(),
      V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})),
    "numerical-uncertainty") == True{} : Bool}

def cylv_ovf_unc():
  {==}

law cylv_rneg_inv:
  {String.eq(G.gres_show(O.cyl_val(G.Cy{p000(), d001(),
      F64.neg(1.0f64)}, p100())), "invalid-input")
    == True{} : Bool}

def cylv_rneg_inv():
  {==}

law cylg_105:
  {d_bits_eq(O.cyl_grad(cy_z(), V.Pt{1.0f64, 0.0f64, 5.0f64}),
    4611686018427387904u64, 0u64, 0u64) == True{} : Bool}

def cylg_105():
  {==}

law cylg_nan_inv:
  {String.eq(G.gres_show(O.cyl_grad(cy_z(),
      V.Pt{0.0f64, F64.nan(), 0.0f64})), "invalid-input")
    == True{} : Bool}

def cylg_nan_inv():
  {==}

law cylg_axis2_inv:
  {String.eq(G.gres_show(O.cyl_grad(G.Cy{p000(),
      V.Dr{2.0f64, 0.0f64, 0.0f64}, 1.0f64}, p100())),
    "invalid-input") == True{} : Bool}

def cylg_axis2_inv():
  {==}

law cylg_r0_inv:
  {String.eq(G.gres_show(O.cyl_grad(G.Cy{p000(), d001(), 0.0f64},
      p100())), "invalid-input") == True{} : Bool}

def cylg_r0_inv():
  {==}

# --- cone_val/cone_grad/cone_ax ---
law cov_on:
  {f_bits_eq(O.cone_val(co_z(), V.Pt{1.0f64, 0.0f64, 2.0f64}), 0u64)
    == True{} : Bool}

def cov_on():
  {==}

law cov_off:
  {f_bits_eq(O.cone_val(co_z(), V.Pt{2.0f64, 0.0f64, 2.0f64}),
    4613937818241073152u64) == True{} : Bool}

def cov_off():
  {==}

law cov_nan_inv:
  {String.eq(G.gres_show(O.cone_val(co_z(),
      V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")
    == True{} : Bool}

def cov_nan_inv():
  {==}

law cov_axis2_inv:
  {String.eq(G.gres_show(O.cone_val(G.Co{p000(),
      V.Dr{2.0f64, 0.0f64, 0.0f64}, 0.5f64}, p100())),
    "invalid-input") == True{} : Bool}

def cov_axis2_inv():
  {==}

law cov_ovf_unc:
  {String.eq(G.gres_show(O.cone_val(co_z(),
      V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})),
    "numerical-uncertainty") == True{} : Bool}

def cov_ovf_unc():
  {==}

law cov_kneg_inv:
  {String.eq(G.gres_show(O.cone_val(G.Co{p000(), d001(),
      F64.neg(0.5f64)}, p100())), "invalid-input")
    == True{} : Bool}

def cov_kneg_inv():
  {==}

law cog_102:
  {d_bits_eq(O.cone_grad(co_z(), V.Pt{1.0f64, 0.0f64, 2.0f64}),
    4611686018427387904u64, 0u64, 13830554455654793216u64)
    == True{} : Bool}

def cog_102():
  {==}

law cog_nan_inv:
  {String.eq(G.gres_show(O.cone_grad(co_z(),
      V.Pt{0.0f64, F64.nan(), 0.0f64})), "invalid-input")
    == True{} : Bool}

def cog_nan_inv():
  {==}

law cog_axis2_inv:
  {String.eq(G.gres_show(O.cone_grad(G.Co{p000(),
      V.Dr{2.0f64, 0.0f64, 0.0f64}, 0.5f64}, p100())),
    "invalid-input") == True{} : Bool}

def cog_axis2_inv():
  {==}

law cog_k0_inv:
  {String.eq(G.gres_show(O.cone_grad(G.Co{p000(), d001(),
      0.0f64}, p100())), "invalid-input") == True{} : Bool}

def cog_k0_inv():
  {==}

law coax_2:
  {f_bits_eq(O.cone_ax(co_z(), V.Pt{1.0f64, 0.0f64, 2.0f64}),
    4611686018427387904u64) == True{} : Bool}

def coax_2():
  {==}

law coax_neg:
  {f_bits_eq(O.cone_ax(co_z(), V.Pt{0.0f64, 0.0f64,
      F64.neg(3.0f64)}), 13837309855095848960u64) == True{} : Bool}

def coax_neg():
  {==}

law coax_nan_inv:
  {String.eq(G.gres_show(O.cone_ax(co_z(),
      V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")
    == True{} : Bool}

def coax_nan_inv():
  {==}

law coax_axis2_inv:
  {String.eq(G.gres_show(O.cone_ax(G.Co{p000(),
      V.Dr{2.0f64, 0.0f64, 0.0f64}, 0.5f64}, p100())),
    "invalid-input") == True{} : Bool}

def coax_axis2_inv():
  {==}

law coax_kneg_inv:
  {String.eq(G.gres_show(O.cone_ax(G.Co{p000(), d001(),
      F64.neg(0.5f64)}, p123())), "invalid-input")
    == True{} : Bool}

def coax_kneg_inv():
  {==}

# --- tor_val/tor_grad ---
law torv_eq:
  {f_bits_eq(O.tor_val(to_z(), V.Pt{5.0f64, 0.0f64, 0.0f64}), 0u64)
    == True{} : Bool}

def torv_eq():
  {==}

law torv_nan_inv:
  {String.eq(G.gres_show(O.tor_val(to_z(),
      V.Pt{F64.nan(), 0.0f64, 0.0f64})), "invalid-input")
    == True{} : Bool}

def torv_nan_inv():
  {==}

law torv_axis2_inv:
  {String.eq(G.gres_show(O.tor_val(G.To{p000(),
      V.Dr{2.0f64, 0.0f64, 0.0f64}, 4.0f64, 1.0f64}, p100())),
    "invalid-input") == True{} : Bool}

def torv_axis2_inv():
  {==}

law torv_ovf_unc:
  {String.eq(G.gres_show(O.tor_val(to_z(),
      V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64})),
    "numerical-uncertainty") == True{} : Bool}

def torv_ovf_unc():
  {==}

law torv_Rneg_inv:
  {String.eq(G.gres_show(O.tor_val(G.To{p000(), d001(),
      F64.neg(4.0f64), 1.0f64}, p100())), "invalid-input")
    == True{} : Bool}

def torv_Rneg_inv():
  {==}

law torg_eq:
  {d_bits_eq(O.tor_grad(to_z(), V.Pt{5.0f64, 0.0f64, 0.0f64}),
    4639833516098453504u64, 0u64, 0u64) == True{} : Bool}

def torg_eq():
  {==}

law torg_nan_inv:
  {String.eq(G.gres_show(O.tor_grad(to_z(),
      V.Pt{0.0f64, F64.nan(), 0.0f64})), "invalid-input")
    == True{} : Bool}

def torg_nan_inv():
  {==}

law torg_axis2_inv:
  {String.eq(G.gres_show(O.tor_grad(G.To{p000(),
      V.Dr{2.0f64, 0.0f64, 0.0f64}, 4.0f64, 1.0f64}, p100())),
    "invalid-input") == True{} : Bool}

def torg_axis2_inv():
  {==}

law torg_r0_inv:
  {String.eq(G.gres_show(O.tor_grad(G.To{p000(), d001(), 4.0f64,
      0.0f64}, p100())), "invalid-input") == True{} : Bool}

def torg_r0_inv():
  {==}

# --- tseg_eval/tbez_eval: trim evaluation pins + gates ---
law tse_t0:
  {v2_bits_eq(O.tseg_eval(ts_diag(), 0.0f64), 0u64, 0u64)
    == True{} : Bool}

def tse_t0():
  {==}

law tse_t05:
  {v2_bits_eq(O.tseg_eval(ts_diag(), 0.5f64),
    4602678819172646912u64, 4602678819172646912u64)
    == True{} : Bool}

def tse_t05():
  {==}

law tse_t1:
  {v2_bits_eq(O.tseg_eval(ts_diag(), 1.0f64),
    4607182418800017408u64, 4607182418800017408u64)
    == True{} : Bool}

def tse_t1():
  {==}

law tse_u2_inv:
  {String.eq(G.gres_show(O.tseg_eval(ts_diag(), 2.0f64)),
    "invalid-input") == True{} : Bool}

def tse_u2_inv():
  {==}

law tse_nan_inv:
  {String.eq(G.gres_show(O.tseg_eval(ts_diag(), F64.nan())),
    "invalid-input") == True{} : Bool}

def tse_nan_inv():
  {==}

law tse_tsnan_inv:
  {String.eq(G.gres_show(O.tseg_eval(G.Ts{v2_00(),
      V.V2{F64.nan(), 0.0f64}}, 0.5f64)), "invalid-input")
    == True{} : Bool}

def tse_tsnan_inv():
  {==}

law tbe_t0:
  {v2_bits_eq(O.tbez_eval(tb_s(), 0.0f64), 0u64, 0u64)
    == True{} : Bool}

def tbe_t0():
  {==}

law tbe_t05:
  {v2_bits_eq(O.tbez_eval(tb_s(), 0.5f64), 4602678819172646912u64,
    4602678819172646912u64) == True{} : Bool}

def tbe_t05():
  {==}

law tbe_t1:
  {v2_bits_eq(O.tbez_eval(tb_s(), 1.0f64),
    4607182418800017408u64, 4607182418800017408u64)
    == True{} : Bool}

def tbe_t1():
  {==}

law tbe_u2_inv:
  {String.eq(G.gres_show(O.tbez_eval(tb_s(), 2.0f64)),
    "invalid-input") == True{} : Bool}

def tbe_u2_inv():
  {==}

law tbe_nan_inv:
  {String.eq(G.gres_show(O.tbez_eval(tb_s(), F64.nan())),
    "invalid-input") == True{} : Bool}

def tbe_nan_inv():
  {==}

# --- tseg_bbox/tbez_bbox/plane_trim_pt ---
law tsbb_diag:
  {bb_bits_eq(O.tseg_bbox(ts_diag()), 0u64, 0u64, 0u64,
    4607182418800017408u64, 4607182418800017408u64, 0u64)
    == True{} : Bool}

def tsbb_diag():
  {==}

law tsbb_nan_inv:
  {String.eq(G.gres_show(O.tseg_bbox(G.Ts{v2_00(),
      V.V2{0.0f64, F64.nan()}})), "invalid-input") == True{} : Bool}

def tsbb_nan_inv():
  {==}

law tbbb_s:
  {bb_bits_eq(O.tbez_bbox(tb_s()), 0u64, 0u64, 0u64,
    4607182418800017408u64, 4607182418800017408u64, 0u64)
    == True{} : Bool}

def tbbb_s():
  {==}

law tbbb_nan_inv:
  {String.eq(G.gres_show(O.tbez_bbox(G.Tb{v2_00(), v2_11(),
      V.V2{F64.nan(), 0.0f64}, v2_11()})), "invalid-input")
    == True{} : Bool}

def tbbb_nan_inv():
  {==}

law trimpt_23:
  {p_bits_eq(O.plane_trim_pt(pl_xy(), V.V2{2.0f64, 3.0f64}),
    4611686018427387904u64, 4613937818241073152u64, 0u64)
    == True{} : Bool}

def trimpt_23():
  {==}

law trimpt_frame_inv:
  {String.eq(G.gres_show(O.plane_trim_pt(pl_bad(),
      V.V2{2.0f64, 3.0f64})), "invalid-input") == True{} : Bool}

def trimpt_frame_inv():
  {==}

law trimpt_nan_inv:
  {String.eq(G.gres_show(O.plane_trim_pt(pl_xy(),
      V.V2{F64.nan(), 0.0f64})), "invalid-input") == True{} : Bool}

def trimpt_nan_inv():
  {==}

# --- NURBS fixtures: single-span cubic Bezier as NURBS + defects ---
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

# --- nurbs_checked: ok pin + fuel/count/shape/weight gates ---
law nok_ok:
  {String.eq(G.gres_show(O.nurbs_checked(nbk1(), 9n)), "ok")
    == True{} : Bool}

def nok_ok():
  {==}

law nok_fuel0_exh:
  {String.eq(G.gres_show(O.nurbs_checked(nbk1(), 0n)),
    "resource-exhausted") == True{} : Bool}

def nok_fuel0_exh():
  {==}

law nok_fuel5_exh:
  {String.eq(G.gres_show(O.nurbs_checked(nbk1(), 5n)),
    "resource-exhausted") == True{} : Bool}

def nok_fuel5_exh():
  {==}

law nok_badcount_inv:
  {String.eq(G.gres_show(O.nurbs_checked(nbk_short(), 8n)),
    "invalid-input") == True{} : Bool}

def nok_badcount_inv():
  {==}

law nok_uncl_inv:
  {String.eq(G.gres_show(O.nurbs_checked(nbk_uncl(), 9n)),
    "invalid-input") == True{} : Bool}

def nok_uncl_inv():
  {==}

law nok_dec_inv:
  {String.eq(G.gres_show(O.nurbs_checked(nbk_dec(), 10n)),
    "invalid-input") == True{} : Bool}

def nok_dec_inv():
  {==}

law nok_w0_inv:
  {String.eq(G.gres_show(O.nurbs_checked(nbk_w0(), 9n)),
    "invalid-input") == True{} : Bool}

def nok_w0_inv():
  {==}

law nok_wneg_inv:
  {String.eq(G.gres_show(O.nurbs_checked(G.Nb{nbk1_ks(),
      nbk1_ps(),
      1.0f64 <> 1.0f64 <> F64.neg(1.0f64) <> 1.0f64 <> Nil{}},
    9n)), "invalid-input") == True{} : Bool}

def nok_wneg_inv():
  {==}

law nok_nanp_inv:
  {String.eq(G.gres_show(O.nurbs_checked(nbk_nanp(), 9n)),
    "invalid-input") == True{} : Bool}

def nok_nanp_inv():
  {==}

law nok_nank_inv:
  {String.eq(G.gres_show(O.nurbs_checked(nbk_nank(), 9n)),
    "invalid-input") == True{} : Bool}

def nok_nank_inv():
  {==}

# --- nurbs_eval: de Boor pins + gates (t=khi pinned after probing) ---
law nev_t05:
  {p_bits_eq(O.nurbs_eval(nbk1(), 0.5f64, 9n),
    4602678819172646912u64, 4602678819172646912u64,
    4593671619917905920u64) == True{} : Bool}

def nev_t05():
  {==}

law nev_t0:
  {p_bits_eq(O.nurbs_eval(nbk1(), 0.0f64, 9n), 0u64, 0u64, 0u64)
    == True{} : Bool}

def nev_t0():
  {==}

law nev_t1:
  {p_bits_eq(O.nurbs_eval(nbk1(), 1.0f64, 9n),
    4607182418800017408u64, 4607182418800017408u64,
    4607182418800017408u64) == True{} : Bool}

def nev_t1():
  {==}

law nev_t2_inv:
  {String.eq(G.gres_show(O.nurbs_eval(nbk1(), 2.0f64, 9n)),
    "invalid-input") == True{} : Bool}

def nev_t2_inv():
  {==}

law nev_nan_inv:
  {String.eq(G.gres_show(O.nurbs_eval(nbk1(), F64.nan(), 9n)),
    "invalid-input") == True{} : Bool}

def nev_nan_inv():
  {==}

law nev_fuel0_exh:
  {String.eq(G.gres_show(O.nurbs_eval(nbk1(), 0.5f64, 0n)),
    "resource-exhausted") == True{} : Bool}

def nev_fuel0_exh():
  {==}

law nev_fuel5_exh:
  {String.eq(G.gres_show(O.nurbs_eval(nbk1(), 0.5f64, 5n)),
    "resource-exhausted") == True{} : Bool}

def nev_fuel5_exh():
  {==}

law nev_badcount_inv:
  {String.eq(G.gres_show(O.nurbs_eval(nbk_short(), 0.5f64, 8n)),
    "invalid-input") == True{} : Bool}

def nev_badcount_inv():
  {==}

law nev_bez_equiv:
  {ev_eq(O.nurbs_eval(nbk1(), 0.5f64, 9n), O.bez3_eval(bz_s(),
      0.5f64)) == True{} : Bool}

def nev_bez_equiv():
  {==}

# --- BN-8 (bounded iteration): single-step wrap + fuel rejection ---
law bn8_wrap_once:
  {f_bits_eq(O.pdom_wrap(pdom_per(), 25.0f64),
    4624633867356078080u64) == True{} : Bool}

def bn8_wrap_once():
  {==}

# --- BN-10 (certified enclosures): evaluations land inside hulls ---
law bn10_bez:
  {ev_in_bb(O.bez3_eval(bz_s(), 0.3f64), O.bez3_bbox(bz_s()))
    == True{} : Bool}

def bn10_bez():
  {==}

law bn10_circ:
  {ev_in_bb(O.circ_eval(cc_unit(), 0.5f64), O.circ_bbox(cc_unit()))
    == True{} : Bool}

def bn10_circ():
  {==}

law bn10_rqb:
  {ev_in_bb(O.rqb_eval(rq_q(), 0.5f64), O.rqb_bbox(rq_q()))
    == True{} : Bool}

def bn10_rqb():
  {==}

law bn10_bezp:
  {ev_in_bb(O.bezp_eval(bp_bump(), 0.5f64, 0.5f64),
    O.bezp_bbox(bp_bump())) == True{} : Bool}

def bn10_bezp():
  {==}

law bn10_line:
  {ev_in_bb(O.line_eval(ln_x(), 1.5f64),
    O.line_seg_bbox(p000(), V.Pt{3.0f64, 0.0f64, 0.0f64}))
    == True{} : Bool}

def bn10_line():
  {==}

law bn10_plane:
  {ev_in_bb(O.plane_eval(pl_xy(), 1.0f64, 1.0f64),
    O.plane_uv_bbox(pl_xy(), 0.0f64, 2.0f64, 0.0f64, 3.0f64))
    == True{} : Bool}

def bn10_plane():
  {==}

law bn10_tbez:
  {v2_in_bb(O.tbez_eval(tb_s(), 0.3f64), O.tbez_bbox(tb_s()))
    == True{} : Bool}

def bn10_tbez():
  {==}

# --- BN-11 (non-publishing failures): op-level default projections ---
law bn11_leval_ovf:
  {p_bits_eq(O.line_eval(G.Ln{
      V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, d100()},
    F64{9218868437227405311u64}), 0u64, 0u64, 0u64)
    == True{} : Bool}

def bn11_leval_ovf():
  {==}

law bn11_nev_exh:
  {p_bits_eq(O.nurbs_eval(nbk1(), 0.5f64, 0n), 0u64, 0u64, 0u64)
    == True{} : Bool}

def bn11_nev_exh():
  {==}

law bn11_plck_inv:
  {p_bits_eq(O.plane_checked(pl_bad()), 0u64, 0u64, 0u64)
    == True{} : Bool}

def bn11_plck_inv():
  {==}

law bn11_qdisc_nan:
  {f_bits_eq(O.rqb_disc(G.Rq{p100(), p111(), p010(), 1.0f64,
      F64.nan(), 1.0f64}), 0u64) == True{} : Bool}

def bn11_qdisc_nan():
  {==}

law bn11_wrap_inv:
  {f_bits_eq(O.pdom_wrap(G.Pdom{G.Dom{F64.nan(), 10.0f64}, True{}},
      2.0f64), 0u64) == True{} : Bool}

def bn11_wrap_inv():
  {==}
