import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c02/types.bend as P
import ../../src/c02/ops.bend as O
import ./check.bend as C

def main() -> IO(Unit):
  do IO<Unit>:
    f1 : U64 <- C.report_ps("pos-o2-ccw",
      O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
        V.V2{0.0f64, 1.0f64}),
      "pos", 0u64)
    f2 : U64 <- C.report_ps("pos-o2-cw",
      O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64},
        V.V2{1.0f64, 0.0f64}),
      "neg", f1)
    f3 : U64 <- C.report_ps("pos-o2-coll",
      O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, 2.0f64},
        V.V2{5.0f64, 5.0f64}),
      "zero", f2)
    f4 : U64 <- C.report_ps("pos-o2-rep",
      O.orient2d(V.V2{0.1f64, 0.2f64}, V.V2{0.1f64, 0.2f64},
        V.V2{3.5f64, 4.5f64}),
      "zero", f3)
    f5 : U64 <- C.report_ps("pos-o2-near",
      O.orient2d(V.V2{C.n25(), C.n25p1()}, V.V2{C.n25p1(), C.n25p2()},
        V.V2{0.0f64, 0.0f64}),
      "neg", f4)
    f6 : U64 <- C.report_ps("pos-o2-big150",
      O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{C.big150(), 0.0f64},
        V.V2{0.0f64, C.big150()}),
      "pos", f5)
    f7 : U64 <- C.report_pure("pos-o2-flip",
      Bool.and(String.eq(P.pres_sign_show(O.orient2d(
          V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
          V.V2{0.0f64, 1.0f64})), "pos"),
        String.eq(P.pres_sign_show(O.orient2d(
          V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64},
          V.V2{0.0f64, 1.0f64})), "neg")),
      f6)
    f8 : U64 <- C.report_ps("pos-o2-near-exact",
      O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, C.w251()},
        V.V2{4.0f64, 4.0f64}), "neg", f7)
    f9 : U64 <- C.report_ps("pos-o2-tiny-exact",
      O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{C.tiny500(), 0.0f64},
        V.V2{0.0f64, C.tiny500()}), "pos", f8)
    f10 : U64 <- C.report_ps("pos-o3-near-exact",
      O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64},
        V.Pt{4.0f64, 0.0f64, 4.0f64}, V.Pt{0.0f64, 4.0f64, 0.0f64},
        V.Pt{2.0f64, 2.0f64, C.w251()}), "neg", f9)
    f11 : U64 <- C.report_ps("pos-ic-near-exact",
      O.incircle(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
        V.V2{0.0f64, 1.0f64}, V.V2{C.q148(), 1.0f64}), "neg", f10)
    f12 : U64 <- C.report_ps("pos-is-near-exact",
      O.insphere(V.Pt{1.0f64, 0.0f64, 0.0f64},
        V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64},
        V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{C.q147(), 1.0f64, 1.0f64}),
      "neg", f11)
    f13 : U64 <- C.report_ps("pos-o3-neg",
      O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64},
        V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
        V.Pt{0.0f64, 0.0f64, 1.0f64}),
      "neg", f12)
    f14 : U64 <- C.report_ps("pos-o3-pos",
      O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64},
        V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{1.0f64, 0.0f64, 0.0f64},
        V.Pt{0.0f64, 0.0f64, 1.0f64}),
      "pos", f13)
    f15 : U64 <- C.report_ps("pos-o3-coplanar",
      O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64},
        V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
        V.Pt{1.0f64, 1.0f64, 0.0f64}),
      "zero", f14)
    f16 : U64 <- C.report_ps("pos-ic-in",
      O.incircle(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
        V.V2{0.0f64, 1.0f64}, V.V2{0.25f64, 0.25f64}),
      "pos", f15)
    f17 : U64 <- C.report_ps("pos-ic-out",
      O.incircle(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
        V.V2{0.0f64, 1.0f64}, V.V2{2.0f64, 2.0f64}),
      "neg", f16)
    f18 : U64 <- C.report_ps("pos-ic-on",
      O.incircle(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
        V.V2{0.0f64, 1.0f64}, V.V2{1.0f64, 1.0f64}),
      "zero", f17)
    f19 : U64 <- C.report_ps("pos-is-in",
      O.insphere(V.Pt{1.0f64, 0.0f64, 0.0f64},
        V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64},
        V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.5f64, 0.5f64, 0.5f64}),
      "pos", f18)
    f20 : U64 <- C.report_ps("pos-is-out",
      O.insphere(V.Pt{1.0f64, 0.0f64, 0.0f64},
        V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64},
        V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{2.0f64, 2.0f64, 2.0f64}),
      "neg", f19)
    f21 : U64 <- C.report_ps("pos-is-on",
      O.insphere(V.Pt{1.0f64, 0.0f64, 0.0f64},
        V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64},
        V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{1.0f64, 1.0f64, 1.0f64}),
      "zero", f20)
    f22 : U64 <- C.report_xr("pos-seg-proper",
      O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, 2.0f64},
        V.V2{0.0f64, 2.0f64}, V.V2{2.0f64, 0.0f64}),
      "proper", f21)
    f23 : U64 <- C.report_xr("pos-seg-touch",
      O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 1.0f64},
        V.V2{1.0f64, 1.0f64}, V.V2{2.0f64, 0.0f64}),
      "touch", f22)
    f24 : U64 <- C.report_xr("pos-seg-disjoint",
      O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
        V.V2{0.0f64, 1.0f64}, V.V2{1.0f64, 1.0f64}),
      "disjoint", f23)
    f25 : U64 <- C.report_xr("pos-seg-overlap",
      O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, 0.0f64},
        V.V2{1.0f64, 0.0f64}, V.V2{3.0f64, 0.0f64}),
      "overlap", f24)
    f26 : U64 <- C.report_xr("pos-seg-ctouch",
      O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
        V.V2{1.0f64, 0.0f64}, V.V2{2.0f64, 0.0f64}),
      "touch", f25)
    f27 : U64 <- C.report_xr("pos-seg-point-on",
      O.seg_seg(V.V2{1.0f64, 1.0f64}, V.V2{1.0f64, 1.0f64},
        V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, 2.0f64}),
      "touch", f26)
    f28 : U64 <- C.report_xr("pos-seg-point-off",
      O.seg_seg(V.V2{1.0f64, 2.0f64}, V.V2{1.0f64, 2.0f64},
        V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, 2.0f64}),
      "disjoint", f27)
    f29 : U64 <- C.report_xr("pos-seg-voverlap",
      O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 2.0f64},
        V.V2{0.0f64, 1.0f64}, V.V2{0.0f64, 3.0f64}),
      "overlap", f28)
    f30 : U64 <- C.report_tc("pos-tri-in",
      O.tri_class(V.V2{1.0f64, 1.0f64}, C.ccw_tri_a(), C.ccw_tri_b(),
        C.ccw_tri_c()),
      "inside", f29)
    f31 : U64 <- C.report_tc("pos-tri-out",
      O.tri_class(V.V2{5.0f64, 5.0f64}, C.ccw_tri_a(), C.ccw_tri_b(),
        C.ccw_tri_c()),
      "outside", f30)
    f32 : U64 <- C.report_tc("pos-tri-bound",
      O.tri_class(V.V2{2.0f64, 0.0f64}, C.ccw_tri_a(), C.ccw_tri_b(),
        C.ccw_tri_c()),
      "boundary", f31)
    f33 : U64 <- C.report_tc("pos-tri-cw",
      O.tri_class(V.V2{1.0f64, 1.0f64}, V.V2{0.0f64, 0.0f64},
        V.V2{0.0f64, 4.0f64}, V.V2{4.0f64, 0.0f64}),
      "inside", f32)
    f34 : U64 <- C.report_pure("pos-kind-doc",
      Bool.and(String.eq(T.FailKind.show(
          P.pres_kind(P.pok(P.Sg_pos{}))), "invalid-input"),
        Bool.and(String.eq(T.FailKind.show(
            P.xres_kind(P.xok(P.X_proper{}))), "invalid-input"),
          String.eq(T.FailKind.show(
            P.tres_kind(P.tok(P.T_in{}))), "invalid-input"))),
      f33)
    f35 : U64 <- C.report_xr("pos-seg-near-exact",
      O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, C.w251()},
        V.V2{4.0f64, 4.0f64}, V.V2{5.0f64, 6.0f64}), "disjoint", f34)
    f36 : U64 <- C.report_tc("pos-tri-far-exact",
      O.tri_class(V.V2{C.p2e60(), 1.0f64}, C.ccw_tri_a(), C.ccw_tri_b(),
        C.ccw_tri_c()), "outside", f35)
    IO.print("selfcheck fails=" ++ U64.show(f36))
