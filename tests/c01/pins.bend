import Base

import ../../src/c00/types.bend as T

import ../../src/c01/types.bend as V

import ../../src/c01/ops.bend as O

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

def entry_vec__got() -> Bool:
  Bool.and(String.eq(V.cres_show(V.mk_v3(F64.nan(), 0.0f64, 0.0f64)), "invalid-input"), String.eq(V.cres_show(V.mk_v2(F64{9218868437227405312u64}, 0.0f64)), "invalid-input"))

def entry_vec__want() -> Bool:
  True{}

def entry_pdm__got() -> Bool:
  Bool.and(String.eq(V.cres_show(V.mk_pt(0.0f64, F64.nan(), 0.0f64)), "invalid-input"), Bool.and(String.eq(V.cres_show(V.mk_dr(0.0f64, 0.0f64, F64{18442240474082181120u64})), "invalid-input"), String.eq(V.cres_show(V.mk_m3(1.0f64, 0.0f64, 0.0f64, 0.0f64, F64.nan(), 0.0f64, 0.0f64, 0.0f64, 1.0f64)), "invalid-input")))

def entry_pdm__want() -> Bool:
  True{}

def norm345__got() -> U64:
  F64.bits(V.cres_f(O.v3_norm(v340())))

def norm345__want() -> U64:
  4617315517961601024u64

def norm_zero__got() -> U64:
  F64.bits(V.cres_f(O.v3_norm(v000())))

def norm_zero__want() -> U64:
  0u64

def norm_dbl_axis__got() -> U64:
  F64.bits(V.cres_f(O.v3_norm(vdbl_axis())))

def norm_dbl_axis__want() -> U64:
  9218868437227405311u64

def norm_dbl_diag_unc__got() -> String:
  V.cres_show(O.v3_norm(vdbl_diag()))

def norm_dbl_diag_unc__want() -> String:
  "numerical-uncertainty"

def norm_sub__got() -> U64:
  F64.bits(V.cres_f(O.v3_norm(vsub())))

def norm_sub__want() -> U64:
  2u64

def norm_1e300__got() -> U64:
  F64.bits(V.cres_f(O.v3_norm(v1e300())))

def norm_1e300__want() -> U64:
  9098591558598742040u64

def unit340__got() -> Bool:
  v3_bits_eq(O.v3_normalize(v340()), 4603579539098121011u64, 4605380978949069210u64, 0u64)

def unit340__want() -> Bool:
  True{}

def unit_zero_inv__got() -> String:
  V.cres_show(O.v3_normalize(v000()))

def unit_zero_inv__want() -> String:
  "invalid-input"

def drunit_zero_inv__got() -> String:
  V.cres_show(O.dr_unit(V.Dr{0.0f64, 0.0f64, 0.0f64}))

def drunit_zero_inv__want() -> String:
  "invalid-input"

def dot32__got() -> U64:
  F64.bits(V.cres_f(O.v3_dot(V.V3{1.0f64, 2.0f64, 3.0f64}, V.V3{4.0f64, 5.0f64, 6.0f64})))

def dot32__want() -> U64:
  4629700416936869888u64

def cross_pins__got() -> Bool:
  v3_bits_eq(O.v3_cross(V.V3{1.0f64, 2.0f64, 3.0f64}, V.V3{4.0f64, 5.0f64, 6.0f64}), 13837309855095848960u64, 4618441417868443648u64, 13837309855095848960u64)

def cross_pins__want() -> Bool:
  True{}

def det_ident__got() -> U64:
  F64.bits(V.cres_f(O.m3_det(m_ident())))

def det_ident__want() -> U64:
  4607182418800017408u64

def det_diag123__got() -> U64:
  F64.bits(V.cres_f(O.m3_det(m_diag123())))

def det_diag123__want() -> U64:
  4618441417868443648u64

def inv_ident__got() -> Bool:
  m_bits_eq(O.m3_inv(m_ident()), 4607182418800017408u64, 9223372036854775808u64, 0u64, 9223372036854775808u64, 4607182418800017408u64, 9223372036854775808u64, 0u64, 9223372036854775808u64, 4607182418800017408u64)

def inv_ident__want() -> Bool:
  True{}

def inv_diag248__got() -> Bool:
  m_bits_eq(O.m3_inv(m_diag248()), 4602678819172646912u64, 9223372036854775808u64, 0u64, 9223372036854775808u64, 4598175219545276416u64, 9223372036854775808u64, 0u64, 9223372036854775808u64, 4593671619917905920u64)

def inv_diag248__want() -> Bool:
  True{}

def inv_sing_unc__got() -> String:
  V.cres_show(O.m3_inv(m_sing()))

def inv_sing_unc__want() -> String:
  "numerical-uncertainty"

def inv_near_unc__got() -> String:
  V.cres_show(O.m3_inv(m_near()))

def inv_near_unc__want() -> String:
  "numerical-uncertainty"

def seg_coincident_inv__got() -> String:
  V.cres_show(O.seg_dir(V.Pt{1.0f64, 2.0f64, 3.0f64}, V.Pt{1.0f64, 2.0f64, 3.0f64}))

def seg_coincident_inv__want() -> String:
  "invalid-input"

def pt_algebra__got() -> Bool:
  Bool.and(p_bits_eq(O.p_plus_d(V.Pt{1.0f64, 2.0f64, 3.0f64}, V.Dr{4.0f64, 5.0f64, 6.0f64}), 4617315517961601024u64, 4619567317775286272u64, 4621256167635550208u64), d_bits_eq(O.p_minus_p(V.Pt{4.0f64, 5.0f64, 6.0f64}, V.Pt{1.0f64, 2.0f64, 3.0f64}), 4613937818241073152u64, 4613937818241073152u64, 4613937818241073152u64))

def pt_algebra__want() -> Bool:
  True{}

def mk_rigid_ok__got() -> String:
  V.cres_show(O.mk_rigid(V.M3{0.0f64, F64.neg(1.0f64), 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64}, 5.0f64, 6.0f64, 7.0f64))

def mk_rigid_ok__want() -> String:
  "ok"

def rt_fwd__got() -> Bool:
  p_bits_eq(O.rg_apply_p(rz90(), V.Pt{1.0f64, 2.0f64, 3.0f64}), 4613937818241073152u64, 4619567317775286272u64, 4621819117588971520u64)

def rt_fwd__want() -> Bool:
  True{}

def rt_back__got() -> Bool:
  p_bits_eq(rt_back_val(), 4607182418800017408u64, 4611686018427387904u64, 4613937818241073152u64)

def rt_back__want() -> Bool:
  True{}

def dir_notrans__got() -> Bool:
  d_bits_eq(O.rg_apply_d(rz90(), V.Dr{0.0f64, 0.0f64, 1.0f64}), 0u64, 0u64, 4607182418800017408u64)

def dir_notrans__want() -> Bool:
  True{}

def frame_ident_ok__got() -> String:
  V.cres_show(O.mk_frame(0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64))

def frame_ident_ok__want() -> String:
  "ok"

def frame_ortho_inv__got() -> String:
  V.cres_show(O.mk_frame(0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.6f64, 0.8f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64))

def frame_ortho_inv__want() -> String:
  "invalid-input"

def frame_lefthand_inv__got() -> String:
  V.cres_show(O.mk_frame(0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, F64.neg(1.0f64)))

def frame_lefthand_inv__want() -> String:
  "invalid-input"

def frame_basis_ok__got() -> String:
  V.cres_show(O.frame_basis(V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}))

def frame_basis_ok__want() -> String:
  "ok"

def frame_basis_par_unc__got() -> String:
  V.cres_show(O.frame_basis(V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{0.0f64, 0.0f64, 2.0f64}))

def frame_basis_par_unc__want() -> String:
  "numerical-uncertainty"
