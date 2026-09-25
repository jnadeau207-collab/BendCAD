# C01 laws: every claim closed by the proof beneath it. Unbounded claims
# live as explicit M-laws in docs/c01-contract.md; this file proves the
# structural properties generally plus one instance per pipeline arm.
# Pins: F64 bit patterns from python struct (independent oracle).

import Base
import ../src/c00/types.bend as T
import ../src/c01/types.bend as V
import ../src/c01/ops.bend as O

# --- Bit-equality helpers (exact pins, no show-format dependence) ---
def v3_bits_eq(+r: V.CRes, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  +v = V.cres_v3(r)
  Bool.and(U64.is_eq(F64.bits(V.v3_x(v)), wx),
    Bool.and(U64.is_eq(F64.bits(V.v3_y(v)), wy),
      U64.is_eq(F64.bits(V.v3_z(v)), wz)))

def p_bits_eq(+r: V.CRes, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  +p = V.cres_p(r)
  Bool.and(U64.is_eq(F64.bits(V.pt_x(p)), wx),
    Bool.and(U64.is_eq(F64.bits(V.pt_y(p)), wy),
      U64.is_eq(F64.bits(V.pt_z(p)), wz)))

def d_bits_eq(+r: V.CRes, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  +d = V.cres_d(r)
  Bool.and(U64.is_eq(F64.bits(V.dr_x(d)), wx),
    Bool.and(U64.is_eq(F64.bits(V.dr_y(d)), wy),
      U64.is_eq(F64.bits(V.dr_z(d)), wz)))

def m_bits_eq(+r: V.CRes, +w0: U64, +w1: U64, +w2: U64, +w3: U64,
    +w4: U64, +w5: U64, +w6: U64, +w7: U64, +w8: U64) -> Bool:
  +m = V.cres_m(r)
  Bool.and(U64.is_eq(F64.bits(V.m_a(m)), w0),
    Bool.and(U64.is_eq(F64.bits(V.m_b(m)), w1),
      Bool.and(U64.is_eq(F64.bits(V.m_c(m)), w2),
        Bool.and(U64.is_eq(F64.bits(V.m_d(m)), w3),
          Bool.and(U64.is_eq(F64.bits(V.m_e(m)), w4),
            Bool.and(U64.is_eq(F64.bits(V.m_f(m)), w5),
              Bool.and(U64.is_eq(F64.bits(V.m_g(m)), w6),
                Bool.and(U64.is_eq(F64.bits(V.m_h(m)), w7),
                  U64.is_eq(F64.bits(V.m_i(m)), w8)))))))))

# --- Fixtures ---
def v340() -> V.Vec3:
  V.V3{3.0f64, 4.0f64, 0.0f64}

def v000() -> V.Vec3:
  V.V3{0.0f64, 0.0f64, 0.0f64}

def vdbl_axis() -> V.Vec3:
  V.V3{F64{9218868437227405311u64}, 0.0f64, 0.0f64}

def vdbl_diag() -> V.Vec3:
  V.V3{F64{9218868437227405311u64}, F64{9218868437227405311u64}, 0.0f64}

def vsub() -> V.Vec3:
  V.V3{F64{1u64}, F64{1u64}, F64{1u64}}

def v1e300() -> V.Vec3:
  V.V3{F64{9094988921128908188u64}, F64{9094988921128908188u64},
    F64{9094988921128908188u64}}

def m_ident() -> V.Mat3:
  V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64,
    1.0f64}

def m_diag123() -> V.Mat3:
  V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 2.0f64, 0.0f64, 0.0f64, 0.0f64,
    3.0f64}

def m_diag248() -> V.Mat3:
  V.M3{2.0f64, 0.0f64, 0.0f64, 0.0f64, 4.0f64, 0.0f64, 0.0f64, 0.0f64,
    8.0f64}

def m_sing() -> V.Mat3:
  V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64,
    0.0f64}

def m_near() -> V.Mat3:
  V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64,
    F64{4412443251819771522u64}}

def rz90() -> V.Rigid:
  V.Rg{V.M3{0.0f64, F64.neg(1.0f64), 0.0f64, 1.0f64, 0.0f64, 0.0f64,
    0.0f64, 0.0f64, 1.0f64}, 5.0f64, 6.0f64, 7.0f64}

def rt_inv() -> V.CRes:
  O.rg_inv(rz90())

def rt_back_go(ri: V.CRes) -> V.CRes:
  match ri:
    case V.Cok{v}:
      match v:
        case V.CV_rg{r}:
          O.rg_apply_p(r, V.Pt{3.0f64, 7.0f64, 10.0f64})
        case _: V.cerr(T.F_uncertain{})
    case V.Cerr{kind}: V.cerr(kind)

def rt_back_val() -> V.CRes:
  rt_back_go(rt_inv())

# --- Structural: general over every value/kind ---
law cres_ok_ok:
  for v: V.CVal
  {V.cres_ok(V.Cok{v}) == True{} : Bool}

def cres_ok_ok(v):
  {==}

law cres_show_err:
  for k: T.FailKind
  {V.cres_show(V.Cerr{k}) == T.FailKind.show(k) : String}

def cres_show_err(k):
  {==}

law cerr_zero_f:
  for k: T.FailKind
  {F64.bits(V.cres_f(V.Cerr{k})) == 0u64 : U64}

def cerr_zero_f(k):
  {==}

law cerr_zero_v3:
  for k: T.FailKind
  {V.cres_v3(V.Cerr{k}) == V.V3{0.0f64, 0.0f64, 0.0f64} : V.Vec3}

def cerr_zero_v3(k):
  {==}

# --- Entry boundary: nonfinite rejected in every constructor ---
law entry_vec:
  {Bool.and(String.eq(V.cres_show(V.mk_v3(F64.nan(), 0.0f64, 0.0f64)),
      "invalid-input"),
    String.eq(V.cres_show(V.mk_v2(F64{9218868437227405312u64}, 0.0f64)),
      "invalid-input")) == True{} : Bool}

def entry_vec():
  {==}

law entry_pdm:
  {Bool.and(String.eq(V.cres_show(V.mk_pt(0.0f64, F64.nan(), 0.0f64)),
      "invalid-input"),
    Bool.and(String.eq(V.cres_show(V.mk_dr(0.0f64, 0.0f64,
        F64{18442240474082181120u64})), "invalid-input"),
      String.eq(V.cres_show(V.mk_m3(1.0f64, 0.0f64, 0.0f64, 0.0f64,
        F64.nan(), 0.0f64, 0.0f64, 0.0f64, 1.0f64)), "invalid-input")))
    == True{} : Bool}

def entry_pdm():
  {==}

# --- Scaled norms: exact pins, no spurious overflow, true overflow fails ---
law norm345:
  {F64.bits(V.cres_f(O.v3_norm(v340()))) == 4617315517961601024u64 : U64}

def norm345():
  {==}

law norm_zero:
  {F64.bits(V.cres_f(O.v3_norm(v000()))) == 0u64 : U64}

def norm_zero():
  {==}

law norm_dbl_axis:
  {F64.bits(V.cres_f(O.v3_norm(vdbl_axis()))) == 9218868437227405311u64
    : U64}

def norm_dbl_axis():
  {==}

law norm_dbl_diag_unc:
  {V.cres_show(O.v3_norm(vdbl_diag())) == "numerical-uncertainty" : String}

def norm_dbl_diag_unc():
  {==}

law norm_sub:
  {F64.bits(V.cres_f(O.v3_norm(vsub()))) == 2u64 : U64}

def norm_sub():
  {==}

law norm_1e300:
  {F64.bits(V.cres_f(O.v3_norm(v1e300()))) == 9098591558598742040u64
    : U64}

def norm_1e300():
  {==}

# --- Normalize: unit pins; zero fails, never NaN ---
law unit340:
  {v3_bits_eq(O.v3_normalize(v340()), 4603579539098121011u64,
    4605380978949069210u64, 0u64) == True{} : Bool}

def unit340():
  {==}

law unit_zero_inv:
  {V.cres_show(O.v3_normalize(v000())) == "invalid-input" : String}

def unit_zero_inv():
  {==}

law drunit_zero_inv:
  {V.cres_show(O.dr_unit(V.Dr{0.0f64, 0.0f64, 0.0f64}))
    == "invalid-input" : String}

def drunit_zero_inv():
  {==}

# --- dot / cross / det exact pins ---
law dot32:
  {F64.bits(V.cres_f(O.v3_dot(V.V3{1.0f64, 2.0f64, 3.0f64},
    V.V3{4.0f64, 5.0f64, 6.0f64}))) == 4629700416936869888u64 : U64}

def dot32():
  {==}

law cross_pins:
  {v3_bits_eq(O.v3_cross(V.V3{1.0f64, 2.0f64, 3.0f64},
    V.V3{4.0f64, 5.0f64, 6.0f64}), 13837309855095848960u64,
    4618441417868443648u64, 13837309855095848960u64) == True{} : Bool}

def cross_pins():
  {==}

law det_ident:
  {F64.bits(V.cres_f(O.m3_det(m_ident()))) == 4607182418800017408u64
    : U64}

def det_ident():
  {==}

law det_diag123:
  {F64.bits(V.cres_f(O.m3_det(m_diag123()))) == 4618441417868443648u64
    : U64}

def det_diag123():
  {==}

# --- Inverse: exact pins; singular and near-singular fail honestly ---
# Off-diagonal b/d/f/h are negated cofactors: -(+0.0) = -0.0 (exact).
law inv_ident:
  {m_bits_eq(O.m3_inv(m_ident()), 4607182418800017408u64,
    9223372036854775808u64, 0u64, 9223372036854775808u64,
    4607182418800017408u64, 9223372036854775808u64, 0u64,
    9223372036854775808u64, 4607182418800017408u64) == True{} : Bool}

def inv_ident():
  {==}

law inv_diag248:
  {m_bits_eq(O.m3_inv(m_diag248()), 4602678819172646912u64,
    9223372036854775808u64, 0u64, 9223372036854775808u64,
    4598175219545276416u64, 9223372036854775808u64, 0u64,
    9223372036854775808u64, 4593671619917905920u64) == True{} : Bool}

def inv_diag248():
  {==}

law inv_sing_unc:
  {V.cres_show(O.m3_inv(m_sing())) == "numerical-uncertainty" : String}

def inv_sing_unc():
  {==}

law inv_near_unc:
  {V.cres_show(O.m3_inv(m_near())) == "numerical-uncertainty" : String}

def inv_near_unc():
  {==}

# --- Point/direction algebra pins; coincident seg_dir fails ---
law seg_coincident_inv:
  {V.cres_show(O.seg_dir(V.Pt{1.0f64, 2.0f64, 3.0f64},
    V.Pt{1.0f64, 2.0f64, 3.0f64})) == "invalid-input" : String}

def seg_coincident_inv():
  {==}

law pt_algebra:
  {Bool.and(p_bits_eq(O.p_plus_d(V.Pt{1.0f64, 2.0f64, 3.0f64},
      V.Dr{4.0f64, 5.0f64, 6.0f64}), 4617315517961601024u64,
      4619567317775286272u64, 4621256167635550208u64),
    d_bits_eq(O.p_minus_p(V.Pt{4.0f64, 5.0f64, 6.0f64},
      V.Pt{1.0f64, 2.0f64, 3.0f64}), 4613937818241073152u64,
      4613937818241073152u64, 4613937818241073152u64)) == True{} : Bool}

def pt_algebra():
  {==}

# --- Rigid round-trip: exact Rz90 forward and back ---
law mk_rigid_ok:
  {V.cres_show(O.mk_rigid(V.M3{0.0f64, F64.neg(1.0f64), 0.0f64, 1.0f64,
    0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64}, 5.0f64, 6.0f64, 7.0f64))
    == "ok" : String}

def mk_rigid_ok():
  {==}

law rt_fwd:
  {p_bits_eq(O.rg_apply_p(rz90(), V.Pt{1.0f64, 2.0f64, 3.0f64}),
    4613937818241073152u64, 4619567317775286272u64,
    4621819117588971520u64) == True{} : Bool}

def rt_fwd():
  {==}

law rt_back:
  {p_bits_eq(rt_back_val(), 4607182418800017408u64, 4611686018427387904u64,
    4613937818241073152u64) == True{} : Bool}

def rt_back():
  {==}

law dir_notrans:
  {d_bits_eq(O.rg_apply_d(rz90(), V.Dr{0.0f64, 0.0f64, 1.0f64}), 0u64,
    0u64, 4607182418800017408u64) == True{} : Bool}

def dir_notrans():
  {==}

# --- Frames: obligation enforced, basis builder exact on axes ---
law frame_ident_ok:
  {V.cres_show(O.mk_frame(0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64,
    0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64))
    == "ok" : String}

def frame_ident_ok():
  {==}

law frame_ortho_inv:
  {V.cres_show(O.mk_frame(0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64,
    0.0f64, 0.6f64, 0.8f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64))
    == "invalid-input" : String}

def frame_ortho_inv():
  {==}

law frame_lefthand_inv:
  {V.cres_show(O.mk_frame(0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64,
    0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64,
    F64.neg(1.0f64))) == "invalid-input" : String}

def frame_lefthand_inv():
  {==}

law frame_basis_ok:
  {V.cres_show(O.frame_basis(V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}))
    == "ok" : String}

def frame_basis_ok():
  {==}

law frame_basis_par_unc:
  {V.cres_show(O.frame_basis(V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{0.0f64, 0.0f64, 2.0f64}))
    == "numerical-uncertainty" : String}

def frame_basis_par_unc():
  {==}
