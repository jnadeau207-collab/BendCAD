# C01 negative tests: every failure arm asserts its structured kind and
# that no NaN leaks through projectors. Ends in selfcheck fails=N.

import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c01/ops.bend as O
import ./check.bend as C

def m_sing() -> V.Mat3:
  V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64,
    0.0f64}

def m_near() -> V.Mat3:
  V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64,
    F64{4412443251819771522u64}}

def m_zero() -> V.Mat3:
  V.M3{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64,
    0.0f64}

def m_2i() -> V.Mat3:
  V.M3{2.0f64, 0.0f64, 0.0f64, 0.0f64, 2.0f64, 0.0f64, 0.0f64, 0.0f64,
    2.0f64}

def vdbl() -> V.Vec3:
  V.V3{F64{9218868437227405311u64}, F64{9218868437227405311u64},
    0.0f64}

def main() -> IO(Unit):
  do IO<Unit>:
    f1 : U64 <- C.report_err("neg-nan-v3",
      V.mk_v3(F64.nan(), 0.0f64, 0.0f64), "invalid-input", 0u64)
    f2 : U64 <- C.report_err("neg-inf-v3-slot2",
      V.mk_v3(1.0f64, 1.0f64, F64{9218868437227405312u64}),
      "invalid-input", f1)
    f3 : U64 <- C.report_err("neg-nan-v2",
      V.mk_v2(0.0f64, F64.nan()), "invalid-input", f2)
    f4 : U64 <- C.report_err("neg-inf-pt",
      V.mk_pt(F64{9218868437227405312u64}, 0.0f64, 0.0f64),
      "invalid-input", f3)
    f5 : U64 <- C.report_err("neg-ninf-dr",
      V.mk_dr(0.0f64, F64{18442240474082181120u64}, 0.0f64),
      "invalid-input", f4)
    f6 : U64 <- C.report_err("neg-nan-m3",
      V.mk_m3(1.0f64, 0.0f64, 0.0f64, 0.0f64, F64.nan(), 0.0f64,
        0.0f64, 0.0f64, 1.0f64),
      "invalid-input", f5)
    f7 : U64 <- C.report_err("neg-snan-v3",
      V.mk_v3(F64{9218868437227405313u64}, 0.0f64, 0.0f64),
      "invalid-input", f6)
    f8 : U64 <- C.report_err("neg-unit-zero-v3",
      O.v3_normalize(C.v000()), "invalid-input", f7)
    f9 : U64 <- C.report_err("neg-unit-zero-v2",
      O.v2_normalize(V.V2{0.0f64, 0.0f64}), "invalid-input", f8)
    f10 : U64 <- C.report_err("neg-dr-zero",
      O.dr_unit(V.Dr{0.0f64, 0.0f64, 0.0f64}), "invalid-input", f9)
    f11 : U64 <- C.report_err("neg-seg-coincident",
      O.seg_dir(C.pt123(), C.pt123()), "invalid-input", f10)
    f12 : U64 <- C.report_err("neg-inv-singular", O.m3_inv(m_sing()),
      "numerical-uncertainty", f11)
    f13 : U64 <- C.report_err("neg-inv-near", O.m3_inv(m_near()),
      "numerical-uncertainty", f12)
    f14 : U64 <- C.report_err("neg-inv-zero", O.m3_inv(m_zero()),
      "numerical-uncertainty", f13)
    f15 : U64 <- C.report_err("neg-frame-ortho",
      O.mk_frame(0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64,
        0.6f64, 0.8f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64),
      "invalid-input", f14)
    f16 : U64 <- C.report_err("neg-frame-lefthand",
      O.mk_frame(0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64,
        0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, F64.neg(1.0f64)),
      "invalid-input", f15)
    f17 : U64 <- C.report_err("neg-frame-nonunit",
      O.mk_frame(0.0f64, 0.0f64, 0.0f64, 2.0f64, 0.0f64, 0.0f64,
        0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64),
      "invalid-input", f16)
    f18 : U64 <- C.report_err("neg-frame-nan",
      O.mk_frame(F64.nan(), 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64,
        0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64),
      "invalid-input", f17)
    f19 : U64 <- C.report_err("neg-basis-parallel",
      O.frame_basis(V.Pt{0.0f64, 0.0f64, 0.0f64},
        V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{0.0f64, 0.0f64, 2.0f64}),
      "numerical-uncertainty", f18)
    f20 : U64 <- C.report_err("neg-basis-zeroz",
      O.frame_basis(V.Pt{0.0f64, 0.0f64, 0.0f64},
        V.Dr{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}),
      "invalid-input", f19)
    f21 : U64 <- C.report_err("neg-norm-overflow", O.v3_norm(vdbl()),
      "numerical-uncertainty", f20)
    f22 : U64 <- C.report_err("neg-dot-overflow",
      O.v3_dot(vdbl(), vdbl()), "numerical-uncertainty", f21)
    f23 : U64 <- C.report_err("neg-dist-overflow",
      O.p_dist(V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64},
        V.Pt{F64{18442240474082181119u64}, 0.0f64, 0.0f64}),
      "numerical-uncertainty", f22)
    f24 : U64 <- C.report_err("neg-rigid-badrot",
      O.mk_rigid(m_2i(), 0.0f64, 0.0f64, 0.0f64), "invalid-input",
      f23)
    f25 : U64 <- C.report_err("neg-rigid-nant",
      O.mk_rigid(V.m3_ident(), F64.nan(), 0.0f64, 0.0f64),
      "invalid-input", f24)
    f26 : U64 <- C.report_pure("neg-no-nan-leak",
      Bool.and(U64.is_eq(F64.bits(V.cres_f(O.v3_norm(vdbl()))), 0u64),
        Bool.and(
          U64.is_eq(F64.bits(V.v3_x(V.cres_v3(O.v3_normalize(
            C.v000())))), 0u64),
          U64.is_eq(F64.bits(V.m_a(V.cres_m(O.m3_inv(m_sing())))),
            0u64))),
      f25)
    # Norm-family input gates: NaN in each slot, other slots zero, is
    # malformed (invalid-input), never a swallowed 0.0 ok.
    f27 : U64 <- C.report_err("neg-norm-nan-x0",
      O.v3_norm(V.V3{F64.nan(), 0.0f64, 0.0f64}), "invalid-input",
      f26)
    f28 : U64 <- C.report_err("neg-norm-nan-y0",
      O.v3_norm(V.V3{0.0f64, F64.nan(), 0.0f64}), "invalid-input",
      f27)
    f29 : U64 <- C.report_err("neg-norm-nan-z0",
      O.v3_norm(V.V3{0.0f64, 0.0f64, F64.nan()}), "invalid-input",
      f28)
    f30 : U64 <- C.report_err("neg-norm-nan-x1",
      O.v3_norm(V.V3{F64.nan(), 1.0f64, 2.0f64}), "invalid-input",
      f29)
    f31 : U64 <- C.report_err("neg-norm-nan-y1",
      O.v3_norm(V.V3{1.0f64, F64.nan(), 2.0f64}), "invalid-input",
      f30)
    g32 : U64 <- C.report_err("neg-norm-nan-z1",
      O.v3_norm(V.V3{1.0f64, 2.0f64, F64.nan()}), "invalid-input",
      f31)
    f33 : U64 <- C.report_err("neg-norm2-nan-x0",
      O.v2_norm(V.V2{F64.nan(), 0.0f64}), "invalid-input", g32)
    f34 : U64 <- C.report_err("neg-norm2-nan-y0",
      O.v2_norm(V.V2{0.0f64, F64.nan()}), "invalid-input", f33)
    f35 : U64 <- C.report_err("neg-norm2-nan-x1",
      O.v2_norm(V.V2{F64.nan(), 1.0f64}), "invalid-input", f34)
    f36 : U64 <- C.report_err("neg-norm2-nan-y1",
      O.v2_norm(V.V2{1.0f64, F64.nan()}), "invalid-input", f35)
    # Same gate for infinities (every nonfinite class, every width).
    f37 : U64 <- C.report_err("neg-norm-inf-x",
      O.v3_norm(V.V3{F64{9218868437227405312u64}, 0.0f64, 0.0f64}),
      "invalid-input", f36)
    f38 : U64 <- C.report_err("neg-norm-ninf-y",
      O.v3_norm(V.V3{0.0f64, F64{18442240474082181120u64}, 0.0f64}),
      "invalid-input", f37)
    f39 : U64 <- C.report_err("neg-norm-inf-z",
      O.v3_norm(V.V3{1.0f64, 2.0f64, F64{9218868437227405312u64}}),
      "invalid-input", f38)
    f40 : U64 <- C.report_err("neg-norm2-inf",
      O.v2_norm(V.V2{0.0f64, F64{9218868437227405312u64}}),
      "invalid-input", f39)
    # The same vectors through normalize: gated before the raw norm.
    f41 : U64 <- C.report_err("neg-unit-nan-x0",
      O.v3_normalize(V.V3{F64.nan(), 0.0f64, 0.0f64}),
      "invalid-input", f40)
    f42 : U64 <- C.report_err("neg-unit-nan-y0",
      O.v3_normalize(V.V3{0.0f64, F64.nan(), 0.0f64}),
      "invalid-input", f41)
    f43 : U64 <- C.report_err("neg-unit-nan-z0",
      O.v3_normalize(V.V3{0.0f64, 0.0f64, F64.nan()}),
      "invalid-input", f42)
    f44 : U64 <- C.report_err("neg-unit-nan-x1",
      O.v3_normalize(V.V3{F64.nan(), 1.0f64, 2.0f64}),
      "invalid-input", f43)
    f45 : U64 <- C.report_err("neg-unit-nan-y1",
      O.v3_normalize(V.V3{1.0f64, F64.nan(), 2.0f64}),
      "invalid-input", f44)
    f46 : U64 <- C.report_err("neg-unit-nan-z1",
      O.v3_normalize(V.V3{1.0f64, 2.0f64, F64.nan()}),
      "invalid-input", f45)
    f47 : U64 <- C.report_err("neg-unit2-nan-x0",
      O.v2_normalize(V.V2{F64.nan(), 0.0f64}), "invalid-input",
      f46)
    f48 : U64 <- C.report_err("neg-unit2-nan-y0",
      O.v2_normalize(V.V2{0.0f64, F64.nan()}), "invalid-input",
      f47)
    f49 : U64 <- C.report_err("neg-unit2-nan-x1",
      O.v2_normalize(V.V2{F64.nan(), 1.0f64}), "invalid-input",
      f48)
    f50 : U64 <- C.report_err("neg-unit2-nan-y1",
      O.v2_normalize(V.V2{1.0f64, F64.nan()}), "invalid-input",
      f49)
    # The same vectors through dist (against the origin): gated inputs.
    f51 : U64 <- C.report_err("neg-dist-nan-x0",
      O.v3_dist(V.V3{F64.nan(), 0.0f64, 0.0f64}, C.v000()),
      "invalid-input", f50)
    f52 : U64 <- C.report_err("neg-dist-nan-y0",
      O.v3_dist(V.V3{0.0f64, F64.nan(), 0.0f64}, C.v000()),
      "invalid-input", f51)
    f53 : U64 <- C.report_err("neg-dist-nan-z0",
      O.v3_dist(V.V3{0.0f64, 0.0f64, F64.nan()}, C.v000()),
      "invalid-input", f52)
    f54 : U64 <- C.report_err("neg-dist-nan-x1",
      O.v3_dist(V.V3{F64.nan(), 1.0f64, 2.0f64}, C.v000()),
      "invalid-input", f53)
    f55 : U64 <- C.report_err("neg-dist-nan-y1",
      O.v3_dist(V.V3{1.0f64, F64.nan(), 2.0f64}, C.v000()),
      "invalid-input", f54)
    f56 : U64 <- C.report_err("neg-dist-nan-z1",
      O.v3_dist(V.V3{1.0f64, 2.0f64, F64.nan()}, C.v000()),
      "invalid-input", f55)
    f57 : U64 <- C.report_err("neg-dist2-nan-x0",
      O.v2_dist(V.V2{F64.nan(), 0.0f64}, V.V2{0.0f64, 0.0f64}),
      "invalid-input", f56)
    f58 : U64 <- C.report_err("neg-dist2-nan-y0",
      O.v2_dist(V.V2{0.0f64, F64.nan()}, V.V2{0.0f64, 0.0f64}),
      "invalid-input", f57)
    f59 : U64 <- C.report_err("neg-dist2-nan-x1",
      O.v2_dist(V.V2{F64.nan(), 1.0f64}, V.V2{0.0f64, 0.0f64}),
      "invalid-input", f58)
    f60 : U64 <- C.report_err("neg-dist2-nan-y1",
      O.v2_dist(V.V2{1.0f64, F64.nan()}, V.V2{0.0f64, 0.0f64}),
      "invalid-input", f59)
    # Gated siblings: point/dir/frame entries pin invalid-input too.
    f61 : U64 <- C.report_err("neg-seg-nan",
      O.seg_dir(C.pt123(), V.Pt{F64.nan(), 0.0f64, 0.0f64}),
      "invalid-input", f60)
    f62 : U64 <- C.report_err("neg-pdist-nan",
      O.p_dist(V.Pt{0.0f64, F64.nan(), 0.0f64}, C.pt123()),
      "invalid-input", f61)
    f63 : U64 <- C.report_err("neg-drunit-nan",
      O.dr_unit(V.Dr{1.0f64, F64.nan(), 1.0f64}), "invalid-input",
      f62)
    f64 : U64 <- C.report_err("neg-grad-nan",
      O.v3_grad_norm(V.V3{0.0f64, 0.0f64, F64.nan()}),
      "invalid-input", f63)
    f65 : U64 <- C.report_err("neg-basis-nanz",
      O.frame_basis(V.Pt{0.0f64, 0.0f64, 0.0f64},
        V.Dr{F64.nan(), 0.0f64, 1.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}),
      "invalid-input", f64)
    f66 : U64 <- C.report_err("neg-basis-nanx",
      O.frame_basis(V.Pt{0.0f64, 0.0f64, 0.0f64},
        V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{1.0f64, F64.nan(), 0.0f64}),
      "invalid-input", f65)
    # Result-validated regime (contrast): polynomial ops propagate NaN
    # to a nonfinite result and report numerical-uncertainty.
    f67 : U64 <- C.report_err("neg-dot-nan-unc",
      O.v3_dot(V.V3{F64.nan(), 1.0f64, 2.0f64},
        V.V3{1.0f64, 2.0f64, 3.0f64}),
      "numerical-uncertainty", f66)
    f68 : U64 <- C.report_err("neg-inv-nan-unc",
      O.m3_inv(V.M3{F64.nan(), 0.0f64, 0.0f64, 0.0f64, 1.0f64,
        0.0f64, 0.0f64, 0.0f64, 1.0f64}),
      "numerical-uncertainty", f67)
    f69 : U64 <- C.report_pure("neg-nan-proj-zero",
      U64.is_eq(F64.bits(V.cres_f(O.v3_norm(
        V.V3{0.0f64, F64.nan(), 0.0f64}))), 0u64),
      f68)
    IO.print("selfcheck fails=" ++ U64.show(f69))
