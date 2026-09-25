# C02 negative tests: every failure arm asserts its structured kind, and
# every near-degenerate non-exact case asserts honest uncertainty (never
# a guessed side). Ends in selfcheck fails=N.

import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c02/types.bend as P
import ../../src/c02/ops.bend as O
import ./check.bend as C

def o2_unc() -> P.PRes:
  O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, C.w251()},
    V.V2{4.0f64, 4.0f64})

def seg_unc() -> P.Xres:
  O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, C.w251()},
    V.V2{4.0f64, 4.0f64}, V.V2{5.0f64, 6.0f64})

def tri_unc() -> P.Tres:
  O.tri_class(V.V2{C.p2e60(), 1.0f64}, C.ccw_tri_a(), C.ccw_tri_b(),
    C.ccw_tri_c())

def main() -> IO(Unit):
  do IO<Unit>:
    f1 : U64 <- C.report_perr("neg-o2-nan-a",
      O.orient2d(V.V2{F64.nan(), 0.0f64}, V.V2{1.0f64, 0.0f64},
        V.V2{0.0f64, 1.0f64}),
      "invalid-input", 0u64)
    f2 : U64 <- C.report_perr("neg-o2-nan-c",
      O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
        V.V2{0.0f64, F64.nan()}),
      "invalid-input", f1)
    f3 : U64 <- C.report_perr("neg-o2-inf",
      O.orient2d(V.V2{0.0f64, 0.0f64},
        V.V2{F64{9218868437227405312u64}, 0.0f64},
        V.V2{0.0f64, 1.0f64}),
      "invalid-input", f2)
    f4 : U64 <- C.report_perr("neg-o2-unc", o2_unc(),
      "numerical-uncertainty", f3)
    f5 : U64 <- C.report_perr("neg-o2-ovf",
      O.orient2d(V.V2{0.0f64, 0.0f64},
        V.V2{F64{9218868437227405311u64}, 0.0f64},
        V.V2{0.0f64, F64{9218868437227405311u64}}),
      "numerical-uncertainty", f4)
    f6 : U64 <- C.report_perr("neg-o2-tiny",
      O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{C.tiny500(), 0.0f64},
        V.V2{0.0f64, C.tiny500()}),
      "numerical-uncertainty", f5)
    f7 : U64 <- C.report_perr("neg-o3-nan",
      O.orient3d(V.Pt{F64.nan(), 0.0f64, 0.0f64},
        V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
        V.Pt{0.0f64, 0.0f64, 1.0f64}),
      "invalid-input", f6)
    f8 : U64 <- C.report_perr("neg-o3-ninf",
      O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64},
        V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
        V.Pt{F64{18442240474082181120u64}, 0.0f64, 1.0f64}),
      "invalid-input", f7)
    f9 : U64 <- C.report_perr("neg-o3-unc",
      O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64},
        V.Pt{4.0f64, 0.0f64, 4.0f64}, V.Pt{0.0f64, 4.0f64, 0.0f64},
        V.Pt{2.0f64, 2.0f64, C.w251()}),
      "numerical-uncertainty", f8)
    f10 : U64 <- C.report_perr("neg-ic-nan",
      O.incircle(V.V2{F64.nan(), 0.0f64}, V.V2{1.0f64, 0.0f64},
        V.V2{0.0f64, 1.0f64}, V.V2{0.25f64, 0.25f64}),
      "invalid-input", f9)
    f11 : U64 <- C.report_perr("neg-ic-inf",
      O.incircle(V.V2{0.0f64, 0.0f64},
        V.V2{1.0f64, F64{9218868437227405312u64}},
        V.V2{0.0f64, 1.0f64}, V.V2{0.25f64, 0.25f64}),
      "invalid-input", f10)
    f12 : U64 <- C.report_perr("neg-ic-unc",
      O.incircle(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
        V.V2{0.0f64, 1.0f64}, V.V2{C.q148(), 1.0f64}),
      "numerical-uncertainty", f11)
    f13 : U64 <- C.report_perr("neg-is-nan",
      O.insphere(V.Pt{F64.nan(), 0.0f64, 0.0f64},
        V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64},
        V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.5f64, 0.5f64, 0.5f64}),
      "invalid-input", f12)
    f14 : U64 <- C.report_perr("neg-is-ninf",
      O.insphere(V.Pt{1.0f64, 0.0f64, 0.0f64},
        V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64},
        V.Pt{0.0f64, 0.0f64, F64{18442240474082181120u64}},
        V.Pt{0.5f64, 0.5f64, 0.5f64}),
      "invalid-input", f13)
    f15 : U64 <- C.report_perr("neg-is-unc",
      O.insphere(V.Pt{1.0f64, 0.0f64, 0.0f64},
        V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64},
        V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{C.q147(), 1.0f64, 1.0f64}),
      "numerical-uncertainty", f14)
    f16 : U64 <- C.report_xerr("neg-seg-nan",
      O.seg_seg(V.V2{F64.nan(), 0.0f64}, V.V2{2.0f64, 2.0f64},
        V.V2{0.0f64, 2.0f64}, V.V2{2.0f64, 0.0f64}),
      "invalid-input", f15)
    f17 : U64 <- C.report_xerr("neg-seg-unc", seg_unc(),
      "numerical-uncertainty", f16)
    f18 : U64 <- C.report_terr("neg-tri-nan",
      O.tri_class(V.V2{F64.nan(), 0.0f64}, C.ccw_tri_a(),
        C.ccw_tri_b(), C.ccw_tri_c()),
      "invalid-input", f17)
    f19 : U64 <- C.report_terr("neg-tri-inf",
      O.tri_class(V.V2{1.0f64, 1.0f64},
        V.V2{0.0f64, F64{9218868437227405312u64}}, C.ccw_tri_b(),
        C.ccw_tri_c()),
      "invalid-input", f18)
    f20 : U64 <- C.report_terr("neg-tri-degen",
      O.tri_class(V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64},
        V.V2{1.0f64, 1.0f64}, V.V2{2.0f64, 2.0f64}),
      "invalid-input", f19)
    f21 : U64 <- C.report_terr("neg-tri-unc", tri_unc(),
      "numerical-uncertainty", f20)
    f22 : U64 <- C.report_pure("neg-pres-zero",
      String.eq(P.pres_sign_show(o2_unc()), "zero"), f21)
    f23 : U64 <- C.report_pure("neg-xrel-default",
      String.eq(P.xres_rel_show(seg_unc()), "disjoint"), f22)
    f24 : U64 <- C.report_pure("neg-tcls-default",
      String.eq(P.tres_cls_show(tri_unc()), "outside"), f23)
    IO.print("selfcheck fails=" ++ U64.show(f24))
