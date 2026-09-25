# C01 positive tests: exact pins incl. extreme scales, round-trip
# transforms, frame maps. Ends in selfcheck fails=N.

import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c01/ops.bend as O
import ./check.bend as C

def v1e300() -> V.Vec3:
  V.V3{F64{9094988921128908188u64}, F64{9094988921128908188u64},
    F64{9094988921128908188u64}}

def v1em300() -> V.Vec3:
  V.V3{F64{118622047889322841u64}, F64{118622047889322841u64}, 0.0f64}

def vsub() -> V.Vec3:
  V.V3{F64{1u64}, F64{1u64}, F64{1u64}}

def vdbl_axis() -> V.Vec3:
  V.V3{F64{9218868437227405311u64}, 0.0f64, 0.0f64}

def m_diag248() -> V.Mat3:
  V.M3{2.0f64, 0.0f64, 0.0f64, 0.0f64, 4.0f64, 0.0f64, 0.0f64, 0.0f64,
    8.0f64}

def m123() -> V.Mat3:
  V.M3{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64, 7.0f64, 8.0f64,
    9.0f64}

def rt_back_go(ri: V.CRes) -> V.CRes:
  match ri:
    case V.Cok{v}:
      match v:
        case V.CV_rg{r}:
          O.rg_apply_p(r, V.Pt{3.0f64, 7.0f64, 10.0f64})
        case _: V.cerr(T.F_uncertain{})
    case V.Cerr{kind}: V.cerr(kind)

def rt_back_val() -> V.CRes:
  rt_back_go(O.rg_inv(C.rz90()))

def comp_go(c: V.CRes) -> V.CRes:
  match c:
    case V.Cok{v}:
      match v:
        case V.CV_rg{r}: O.rg_apply_p(r, C.pt123())
        case _: V.cerr(T.F_uncertain{})
    case V.Cerr{kind}: V.cerr(kind)

def inv_go(i: V.CRes) -> V.CRes:
  match i:
    case V.Cok{v}:
      match v:
        case V.CV_rg{r}: O.rg_compose(C.rz90(), r)
        case _: V.cerr(T.F_uncertain{})
    case V.Cerr{kind}: V.cerr(kind)

def comp_apply() -> V.CRes:
  comp_go(inv_go(O.rg_inv(C.rz90())))

def main() -> IO(Unit):
  do IO<Unit>:
    f1 : U64 <- C.report_f("pos-norm-345", O.v3_norm(C.v340()),
      4617315517961601024u64, 0u64)
    f2 : U64 <- C.report_f("pos-norm-dbl-axis", O.v3_norm(vdbl_axis()),
      9218868437227405311u64, f1)
    f3 : U64 <- C.report_f("pos-norm-1e300", O.v3_norm(v1e300()),
      9098591558598742040u64, f2)
    f4 : U64 <- C.report_f("pos-norm-1e-300", O.v3_norm(v1em300()),
      121120607792669222u64, f3)
    f5 : U64 <- C.report_f("pos-norm-sub", O.v3_norm(vsub()), 2u64, f4)
    f6 : U64 <- C.report_f("pos-dist-345",
      O.p_dist(V.Pt{0.0f64, 0.0f64, 0.0f64},
        V.Pt{3.0f64, 4.0f64, 0.0f64}),
      4617315517961601024u64, f5)
    f7 : U64 <- C.report_v3("pos-unit-340", O.v3_normalize(C.v340()),
      4603579539098121011u64, 4605380978949069210u64, 0u64, f6)
    f8 : U64 <- C.report_v3("pos-unit-dbl", O.v3_normalize(vdbl_axis()),
      4607182418800017408u64, 0u64, 0u64, f7)
    f9 : U64 <- C.report_f("pos-dot-32",
      O.v3_dot(V.V3{1.0f64, 2.0f64, 3.0f64},
        V.V3{4.0f64, 5.0f64, 6.0f64}),
      4629700416936869888u64, f8)
    f10 : U64 <- C.report_v3("pos-cross-123",
      O.v3_cross(V.V3{1.0f64, 2.0f64, 3.0f64},
        V.V3{4.0f64, 5.0f64, 6.0f64}),
      13837309855095848960u64, 4618441417868443648u64,
      13837309855095848960u64, f9)
    f11 : U64 <- C.report_f("pos-det-123",
      O.m3_det(V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 2.0f64, 0.0f64,
        0.0f64, 0.0f64, 3.0f64}),
      4618441417868443648u64, f10)
    f12 : U64 <- C.report_m("pos-inv-248", O.m3_inv(m_diag248()),
      4602678819172646912u64, 9223372036854775808u64, 0u64,
      9223372036854775808u64, 4598175219545276416u64,
      9223372036854775808u64, 0u64, 9223372036854775808u64,
      4593671619917905920u64, f11)
    f13 : U64 <- C.report_p("pos-rt-fwd",
      O.rg_apply_p(C.rz90(), C.pt123()),
      4613937818241073152u64, 4619567317775286272u64,
      4621819117588971520u64, f12)
    f14 : U64 <- C.report_p("pos-rt-back", rt_back_val(),
      4607182418800017408u64, 4611686018427387904u64,
      4613937818241073152u64, f13)
    f15 : U64 <- C.report_p("pos-compose-ident", comp_apply(),
      4607182418800017408u64, 4611686018427387904u64,
      4613937818241073152u64, f14)
    f16 : U64 <- C.report_d("pos-dir-notrans",
      O.rg_apply_d(C.rz90(), V.Dr{0.0f64, 0.0f64, 1.0f64}),
      0u64, 0u64, 4607182418800017408u64, f15)
    f17 : U64 <- C.report_pure("pos-frame-basis-ok",
      String.eq(V.cres_show(O.frame_basis(
        V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64},
        V.Dr{1.0f64, 0.0f64, 0.0f64})), "ok"), f16)
    f18 : U64 <- C.report_d("pos-seg-dir",
      O.seg_dir(V.Pt{0.0f64, 0.0f64, 0.0f64},
        V.Pt{0.0f64, 0.0f64, 5.0f64}),
      0u64, 0u64, 4607182418800017408u64, f17)
    f19 : U64 <- C.report_v3("pos-grad",
      O.v3_grad_norm(V.V3{0.0f64, 0.0f64, 5.0f64}),
      0u64, 0u64, 4607182418800017408u64, f18)
    f20 : U64 <- C.report_p("pos-frame-world",
      O.fr_to_world(C.fr_ident(), C.pt123()),
      4607182418800017408u64, 4611686018427387904u64,
      4613937818241073152u64, f19)
    f21 : U64 <- C.report_p("pos-frame-local",
      O.fr_to_local(C.fr_ident(), C.pt123()),
      4607182418800017408u64, 4611686018427387904u64,
      4613937818241073152u64, f20)
    # Every budgeted op pins at least one exact value (Finding 2).
    f22 : U64 <- C.report_f("pos-v2norm-34",
      O.v2_norm(V.V2{3.0f64, 4.0f64}), 4617315517961601024u64, f21)
    f23 : U64 <- C.report_f("pos-v3dist-345",
      O.v3_dist(V.V3{0.0f64, 0.0f64, 0.0f64},
        V.V3{3.0f64, 4.0f64, 0.0f64}),
      4617315517961601024u64, f22)
    f24 : U64 <- C.report_f("pos-v2dist-345",
      O.v2_dist(V.V2{0.0f64, 0.0f64}, V.V2{3.0f64, 4.0f64}),
      4617315517961601024u64, f23)
    f25 : U64 <- C.report_f("pos-v2dot-14",
      O.v2_dot(V.V2{1.0f64, 2.0f64}, V.V2{4.0f64, 5.0f64}),
      4624070917402656768u64, f24)
    f26 : U64 <- C.report_v3("pos-v3add",
      O.v3_add(V.V3{1.0f64, 2.0f64, 3.0f64},
        V.V3{4.0f64, 5.0f64, 6.0f64}),
      4617315517961601024u64, 4619567317775286272u64,
      4621256167635550208u64, f25)
    f27 : U64 <- C.report_v3("pos-v3sub",
      O.v3_sub(V.V3{4.0f64, 5.0f64, 6.0f64},
        V.V3{1.0f64, 2.0f64, 3.0f64}),
      4613937818241073152u64, 4613937818241073152u64,
      4613937818241073152u64, f26)
    f28 : U64 <- C.report_v3("pos-v3scale",
      O.v3_scale(2.0f64, V.V3{1.0f64, 2.0f64, 3.0f64}),
      4611686018427387904u64, 4616189618054758400u64,
      4618441417868443648u64, f27)
    f29 : U64 <- C.report_d("pos-dadd",
      O.d_add(V.Dr{1.0f64, 2.0f64, 3.0f64},
        V.Dr{4.0f64, 5.0f64, 6.0f64}),
      4617315517961601024u64, 4619567317775286272u64,
      4621256167635550208u64, f28)
    f30 : U64 <- C.report_d("pos-dscale",
      O.d_scale(0.5f64, V.Dr{2.0f64, 4.0f64, 6.0f64}),
      4607182418800017408u64, 4611686018427387904u64,
      4613937818241073152u64, f29)
    f31 : U64 <- C.report_v2("pos-v2add",
      O.v2_add(V.V2{1.0f64, 2.0f64}, V.V2{4.0f64, 5.0f64}),
      4617315517961601024u64, 4619567317775286272u64, f30)
    g32 : U64 <- C.report_v2("pos-v2scale",
      O.v2_scale(2.0f64, V.V2{1.0f64, 2.0f64}),
      4611686018427387904u64, 4616189618054758400u64, f31)
    f33 : U64 <- C.report_m("pos-mul-ident", O.m3_mul(V.m3_ident(), m123()),
      4607182418800017408u64, 4611686018427387904u64,
      4613937818241073152u64, 4616189618054758400u64,
      4617315517961601024u64, 4618441417868443648u64,
      4619567317775286272u64, 4620693217682128896u64,
      4621256167635550208u64, g32)
    f34 : U64 <- C.report_v2("pos-v2unit-34",
      O.v2_normalize(V.V2{3.0f64, 4.0f64}),
      4603579539098121011u64, 4605380978949069210u64, f33)
    f35 : U64 <- C.report_d("pos-drunit-005",
      O.dr_unit(V.Dr{0.0f64, 0.0f64, 5.0f64}),
      0u64, 0u64, 4607182418800017408u64, f34)
    f36 : U64 <- C.report_v3("pos-applyv",
      O.rg_apply_v(C.rz90(), V.V3{0.0f64, 0.0f64, 1.0f64}),
      0u64, 0u64, 4607182418800017408u64, f35)
    f37 : U64 <- C.report_pure("pos-jac",
      U64.is_eq(F64.bits(V.m_b(O.rg_jac(C.rz90()))),
        13830554455654793216u64), f36)
    f38 : U64 <- C.report_p("pos-pplus",
      O.p_plus_d(V.Pt{1.0f64, 2.0f64, 3.0f64},
        V.Dr{4.0f64, 5.0f64, 6.0f64}),
      4617315517961601024u64, 4619567317775286272u64,
      4621256167635550208u64, f37)
    f39 : U64 <- C.report_d("pos-pminus",
      O.p_minus_p(V.Pt{4.0f64, 5.0f64, 6.0f64},
        V.Pt{1.0f64, 2.0f64, 3.0f64}),
      4613937818241073152u64, 4613937818241073152u64,
      4613937818241073152u64, f38)
    # Normalize unit-ness, honestly bounded (Finding 3): exactly 1.0
    # in the normal range; subnormal-magnitude inputs pin exact bits
    # and are NOT unit (measured deviation in the contract).
    f40 : U64 <- C.report_f("pos-unit-is-unit",
      O.v3_norm(V.cres_v3(O.v3_normalize(C.v340()))),
      4607182418800017408u64, f39)
    f41 : U64 <- C.report_v3("pos-unit-sub3",
      O.v3_normalize(V.V3{F64{1u64}, F64{1u64}, F64{1u64}}),
      4602678819172646912u64, 4602678819172646912u64,
      4602678819172646912u64, f40)
    f42 : U64 <- C.report_v2("pos-unit-sub2",
      O.v2_normalize(V.V2{F64{1u64}, F64{1u64}}),
      4607182418800017408u64, 4607182418800017408u64, f41)
    f43 : U64 <- C.report_d("pos-drunit-sub3",
      O.dr_unit(V.Dr{F64{1u64}, F64{1u64}, F64{1u64}}),
      4602678819172646912u64, 4602678819172646912u64,
      4602678819172646912u64, f42)
    # cres_kind total-default convention (Finding 4): Cok yields
    # F_invalid by documentation; Cerr passes its kind through.
    f44 : U64 <- C.report_pure("pos-kind-doc",
      Bool.and(String.eq(T.FailKind.show(
          V.cres_kind(V.cok_f(1.0f64))), "invalid-input"),
        String.eq(T.FailKind.show(
          V.cres_kind(V.cerr(T.F_uncertain{}))),
          "numerical-uncertainty")),
      f43)
    IO.print("selfcheck fails=" ++ U64.show(f44))
