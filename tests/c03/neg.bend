# C03 negative tests: every failure arm asserts its structured kind, and
# every rejected constructor publishes only documented defaults (BN-11).
# Ops.bend failure arms append once src/c03/ops.bend lands. selfcheck fails=N.

import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c03/ops.bend as O
import ./check.bend as C

def line_zero() -> G.GRes:
  G.mk_line(C.p000(), C.d000())

def dom_flip() -> G.GRes:
  G.mk_dom(2.0f64, 1.0f64)

def sph_neg() -> G.GRes:
  G.mk_sph(C.p123(), F64.neg(1.0f64))

def bn11_leval() -> G.GRes:
  O.line_eval(G.Ln{V.Pt{C.mx(), 0.0f64, 0.0f64}, C.d100()}, C.mx())

def bn11_nev() -> G.GRes:
  O.nurbs_eval(C.nbk1(), 0.5f64, 0n)

def bn11_plck() -> G.GRes:
  O.plane_checked(C.pl_bad())

def bn11_qdisc() -> G.GRes:
  O.rqb_disc(G.Rq{C.p100(), C.p111(), C.p010(), 1.0f64, F64.nan(),
    1.0f64})

def bn11_wrap() -> G.GRes:
  O.pdom_wrap(G.Pdom{G.Dom{F64.nan(), 10.0f64}, True{}}, 2.0f64)

def wrap_degen1() -> G.GRes:
  O.pdom_wrap(G.Pdom{G.Dom{C.mx(), 0.0f64}, True{}}, F64.neg(C.mx()))

def wrap_degen2() -> G.GRes:
  O.pdom_wrap(G.Pdom{G.Dom{0.0f64, F64.neg(C.mx())}, True{}}, C.mx())

def sph_far() -> G.GRes:
  O.sph_project(C.sp_unit(), V.Pt{C.mx(), C.mx(), 0.0f64})

# Grouped to fit the native backend's arity limit (C02 D2 class).
def neg_g1(f0: U64) -> IO(U64):
  do IO<U64>:
    f1 : U64 <- C.report_gerr("neg-dom-eq",
      G.mk_dom(1.0f64, 1.0f64), "invalid-input", f0)
    f2 : U64 <- C.report_gerr("neg-dom-flip", dom_flip(),
      "invalid-input", f1)
    f3 : U64 <- C.report_gerr("neg-dom-nan",
      G.mk_dom(F64.nan(), 1.0f64), "invalid-input", f2)
    f4 : U64 <- C.report_gerr("neg-dom-inf",
      G.mk_dom(0.0f64, F64{9218868437227405312u64}), "invalid-input",
      f3)
    f5 : U64 <- C.report_gerr("neg-line-nan-p",
      G.mk_line(V.Pt{F64.nan(), 0.0f64, 0.0f64}, C.d100()),
      "invalid-input", f4)
    f6 : U64 <- C.report_gerr("neg-line-nan-d",
      G.mk_line(C.p000(), V.Dr{0.0f64, F64.nan(), 0.0f64}),
      "invalid-input", f5)
    f7 : U64 <- C.report_gerr("neg-line-zero", line_zero(),
      "invalid-input", f6)
    f8 : U64 <- C.report_gerr("neg-plane-nan",
      G.mk_plane(G.Pl{C.p000(), C.d100(),
        V.Dr{0.0f64, 0.0f64, F64.nan()}}),
      "invalid-input", f7)
    f9 : U64 <- C.report_gerr("neg-circ-r0",
      G.mk_circ(C.p000(), C.d100(), C.d010(), 0.0f64),
      "invalid-input", f8)
    f10 : U64 <- C.report_gerr("neg-circ-rneg",
      G.mk_circ(C.p000(), C.d100(), C.d010(), F64.neg(1.0f64)),
      "invalid-input", f9)
    f11 : U64 <- C.report_gerr("neg-circ-rnan",
      G.mk_circ(C.p000(), C.d100(), C.d010(), F64.nan()),
      "invalid-input", f10)
    f12 : U64 <- C.report_gerr("neg-circ-rinf",
      G.mk_circ(C.p000(), C.d100(), C.d010(),
        F64{9218868437227405312u64}),
      "invalid-input", f11)
    f13 : U64 <- C.report_gerr("neg-bez-nan",
      G.mk_bez3(C.p000(), C.p100(), V.Pt{0.0f64, F64.nan(), 0.0f64},
        C.p111()),
      "invalid-input", f12)
    f14 : U64 <- C.report_gerr("neg-rq-w0",
      G.mk_rqbez(C.p100(), C.p111(), C.p010(), 0.0f64,
        G.w_quarter(), 1.0f64),
      "invalid-input", f13)
    f15 : U64 <- C.report_gerr("neg-rq-w1neg",
      G.mk_rqbez(C.p100(), C.p111(), C.p010(), 1.0f64,
        F64.neg(0.5f64), 1.0f64),
      "invalid-input", f14)
    f16 : U64 <- C.report_gerr("neg-rq-wnan",
      G.mk_rqbez(C.p100(), C.p111(), C.p010(), 1.0f64,
        G.w_quarter(), F64.nan()),
      "invalid-input", f15)
    f17 : U64 <- C.report_gerr("neg-bp-nan",
      G.mk_bezp(C.p000(), C.p000(), C.p000(), C.p000(), C.p000(),
        C.p100(), C.p010(), C.p000(), C.p000(), C.p010(), C.p111(),
        V.Pt{F64.nan(), 0.0f64, 0.0f64}, C.p000(), C.p000(),
        C.p000(), C.p000()),
      "invalid-input", f16)
    f18 : U64 <- C.report_gerr("neg-sph-r0",
      G.mk_sph(C.p123(), 0.0f64), "invalid-input", f17)
    f19 : U64 <- C.report_gerr("neg-sph-rneg", sph_neg(),
      "invalid-input", f18)
    f20 : U64 <- C.report_gerr("neg-cyl-axis0",
      G.mk_cyl(C.p000(), C.d000(), 1.0f64), "invalid-input", f19)
    f21 : U64 <- C.report_gerr("neg-cyl-r0",
      G.mk_cyl(C.p000(), C.d001(), 0.0f64), "invalid-input", f20)
    f22 : U64 <- C.report_gerr("neg-cone-k0",
      G.mk_cone(C.p000(), C.d001(), 0.0f64), "invalid-input", f21)
    f23 : U64 <- C.report_gerr("neg-cone-axisnan",
      G.mk_cone(C.p000(), V.Dr{F64.nan(), 0.0f64, 0.0f64}, 0.5f64),
      "invalid-input", f22)
    f24 : U64 <- C.report_gerr("neg-torus-R0",
      G.mk_torus(C.p000(), C.d001(), 0.0f64, 1.0f64),
      "invalid-input", f23)
    f25 : U64 <- C.report_gerr("neg-torus-rneg",
      G.mk_torus(C.p000(), C.d001(), 4.0f64, F64.neg(1.0f64)),
      "invalid-input", f24)
    f26 : U64 <- C.report_gerr("neg-bb-flip",
      G.mk_bbox(C.p100(), C.p000()), "invalid-input", f25)
    f27 : U64 <- C.report_gerr("neg-bb-nan",
      G.mk_bbox(C.p000(), V.Pt{F64.nan(), 1.0f64, 1.0f64}),
      "invalid-input", f26)
    f28 : U64 <- C.report_gerr("neg-tseg-nan",
      G.mk_tseg(C.v2_00(), V.V2{F64.nan(), 1.0f64}),
      "invalid-input", f27)
    return f28

def neg_g2(f28: U64) -> IO(U64):
  do IO<U64>:
    f29 : U64 <- C.report_gerr("neg-tbez-nan",
      G.mk_tbez(C.v2_00(), C.v2_11(), V.V2{0.0f64, F64.nan()},
        C.v2_11()),
      "invalid-input", f28)
    f30 : U64 <- C.report_pure("neg-bn11-line-zero",
      Bool.and(U64.is_eq(F64.bits(V.pt_x(G.gres_p(line_zero()))),
          0u64),
        Bool.and(U64.is_eq(F64.bits(V.pt_y(G.gres_p(line_zero()))),
            0u64),
          U64.is_eq(F64.bits(V.pt_z(G.gres_p(line_zero()))), 0u64))),
      f29)
    f31 : U64 <- C.report_pure("neg-bn11-dom-flip",
      Bool.and(U64.is_eq(F64.bits(G.dom_lo(G.gres_dom(dom_flip()))),
          0u64),
        U64.is_eq(F64.bits(G.dom_hi(G.gres_dom(dom_flip()))), 0u64)),
      f30)
    f32 : U64 <- C.report_pure("neg-bn11-sph-neg",
      U64.is_eq(F64.bits(G.gres_f(sph_neg())), 0u64), f31)
    f33 : U64 <- C.report_gerr("neg-dmid-nan",
      O.dom_mid(G.Dom{F64.nan(), 1.0f64}), "invalid-input", f32)
    f34 : U64 <- C.report_gerr("neg-dmid-ovf",
      O.dom_mid(G.Dom{C.mx(), C.mx()}), "numerical-uncertainty", f33)
    f35 : U64 <- C.report_gerr("neg-dlen-nan",
      O.dom_len(G.Dom{0.0f64, F64.nan()}), "invalid-input", f34)
    f36 : U64 <- C.report_gerr("neg-dlen-ovf",
      O.dom_len(G.Dom{C.nmx(), C.mx()}), "numerical-uncertainty", f35)
    f37 : U64 <- C.report_gerr("neg-clamp-nan-t",
      O.dom_clamp(G.Dom{0.0f64, 5.0f64}, F64.nan()), "invalid-input",
      f36)
    f38 : U64 <- C.report_gerr("neg-clamp-nan-dom",
      O.dom_clamp(G.Dom{F64.nan(), 5.0f64}, 2.0f64), "invalid-input",
      f37)
    f39 : U64 <- C.report_gerr("neg-wrap-nan",
      O.pdom_wrap(C.pdom_per(), F64.nan()), "invalid-input", f38)
    f40 : U64 <- C.report_gerr("neg-split-lo-edge",
      O.dom_split_lo(C.dom_010(), 0.0f64), "invalid-input", f39)
    f41 : U64 <- C.report_gerr("neg-split-lo-out",
      O.dom_split_lo(C.dom_010(), 20.0f64), "invalid-input", f40)
    f42 : U64 <- C.report_gerr("neg-split-hi-edge",
      O.dom_split_hi(C.dom_010(), 10.0f64), "invalid-input", f41)
    f43 : U64 <- C.report_gerr("neg-split-hi-nan",
      O.dom_split_hi(C.dom_010(), F64.nan()), "invalid-input", f42)
    f44 : U64 <- C.report_gerr("neg-leval-nan",
      O.line_eval(C.ln_x(), F64.nan()), "invalid-input", f43)
    f45 : U64 <- C.report_gerr("neg-leval-ovf",
      O.line_eval(G.Ln{V.Pt{C.mx(), 0.0f64, 0.0f64}, C.d100()},
        C.mx()),
      "numerical-uncertainty", f44)
    f46 : U64 <- C.report_gerr("neg-lder-nan",
      O.line_der(G.Ln{C.p000(), V.Dr{F64.nan(), 0.0f64, 0.0f64}}),
      "invalid-input", f45)
    f47 : U64 <- C.report_gerr("neg-lproj-zero",
      O.line_project(G.Ln{C.p000(), C.d000()}, C.p111()),
      "invalid-input", f46)
    f48 : U64 <- C.report_gerr("neg-lproj-nan",
      O.line_project(C.ln_x(), V.Pt{F64.nan(), 0.0f64, 0.0f64}),
      "invalid-input", f47)
    f49 : U64 <- C.report_gerr("neg-ldist-zero",
      O.line_dist(G.Ln{C.p000(), C.d000()}, C.p111()),
      "invalid-input", f48)
    f50 : U64 <- C.report_gerr("neg-ldist-ovf",
      O.line_dist(C.ln_x(), V.Pt{C.mx(), C.mx(), C.mx()}),
      "numerical-uncertainty", f49)
    f51 : U64 <- C.report_gerr("neg-segbb-nan",
      O.line_seg_bbox(C.p000(), V.Pt{F64.nan(), 0.0f64, 0.0f64}),
      "invalid-input", f50)
    f52 : U64 <- C.report_gerr("neg-plck-scale",
      O.plane_checked(C.pl_bad()), "invalid-input", f51)
    f53 : U64 <- C.report_gerr("neg-plck-skew",
      O.plane_checked(C.pl_skew()), "invalid-input", f52)
    f54 : U64 <- C.report_gerr("neg-plck-nan",
      O.plane_checked(G.Pl{C.p000(), C.d100(),
        V.Dr{F64.nan(), 0.0f64, 0.0f64}}),
      "invalid-input", f53)
    f55 : U64 <- C.report_gerr("neg-pln-frame",
      O.plane_normal(C.pl_bad()), "invalid-input", f54)
    f56 : U64 <- C.report_gerr("neg-pleval-nan",
      O.plane_eval(C.pl_xy(), F64.nan(), 0.0f64), "invalid-input",
      f55)
    return f56

def neg_g3(f56: U64) -> IO(U64):
  do IO<U64>:
    f57 : U64 <- C.report_gerr("neg-pleval-ovf",
      O.plane_eval(G.Pl{V.Pt{C.mx(), 0.0f64, 0.0f64}, C.d100(),
        C.d010()}, C.mx(), 0.0f64),
      "numerical-uncertainty", f56)
    f58 : U64 <- C.report_gerr("neg-pleval-frame",
      O.plane_eval(C.pl_bad(), 1.0f64, 1.0f64), "invalid-input",
      f57)
    f59 : U64 <- C.report_gerr("neg-plproj-nan",
      O.plane_project(C.pl_xy(), V.Pt{F64.nan(), 0.0f64, 0.0f64}),
      "invalid-input", f58)
    f60 : U64 <- C.report_gerr("neg-plproj-frame",
      O.plane_project(C.pl_bad(), C.p111()), "invalid-input", f59)
    f61 : U64 <- C.report_gerr("neg-pldist-nan",
      O.plane_dist(C.pl_xy(), V.Pt{0.0f64, F64.nan(), 0.0f64}),
      "invalid-input", f60)
    f62 : U64 <- C.report_gerr("neg-plbb-nan",
      O.plane_uv_bbox(C.pl_xy(), 0.0f64, 2.0f64, F64.nan(), 3.0f64),
      "invalid-input", f61)
    f63 : U64 <- C.report_gerr("neg-plbb-frame",
      O.plane_uv_bbox(C.pl_bad(), 0.0f64, 2.0f64, 0.0f64, 3.0f64),
      "invalid-input", f62)
    f64 : U64 <- C.report_gerr("neg-cck-frame",
      O.circ_checked(G.Cc{C.p000(), V.Dr{2.0f64, 0.0f64, 0.0f64},
        C.d010(), 1.0f64}),
      "invalid-input", f63)
    f65 : U64 <- C.report_gerr("neg-cck-r0",
      O.circ_checked(G.Cc{C.p000(), C.d100(), C.d010(), 0.0f64}),
      "invalid-input", f64)
    f66 : U64 <- C.report_gerr("neg-ceval-t2",
      O.circ_eval(C.cc_unit(), 2.0f64), "invalid-input", f65)
    f67 : U64 <- C.report_gerr("neg-ceval-nan",
      O.circ_eval(C.cc_unit(), F64.nan()), "invalid-input", f66)
    f68 : U64 <- C.report_gerr("neg-ceval-r0",
      O.circ_eval(G.Cc{C.p000(), C.d100(), C.d010(), 0.0f64},
        0.5f64),
      "invalid-input", f67)
    f69 : U64 <- C.report_gerr("neg-ceval-ovf",
      O.circ_eval(G.Cc{V.Pt{C.mx(), 0.0f64, 0.0f64}, C.d100(),
        C.d010(), C.mx()}, 0.0f64),
      "numerical-uncertainty", f68)
    f70 : U64 <- C.report_gerr("neg-cder-t2",
      O.circ_der(C.cc_unit(), 2.0f64), "invalid-input", f69)
    f71 : U64 <- C.report_gerr("neg-cder-ovf",
      O.circ_der(G.Cc{C.p000(), C.d100(), C.d010(), C.mx()}, 0.5f64),
      "numerical-uncertainty", f70)
    f72 : U64 <- C.report_gerr("neg-cseam-r0",
      O.circ_seam_pt(G.Cc{C.p000(), C.d100(), C.d010(), 0.0f64}),
      "invalid-input", f71)
    f73 : U64 <- C.report_gerr("neg-cbb-r0",
      O.circ_bbox(G.Cc{C.p000(), C.d100(), C.d010(), 0.0f64}),
      "invalid-input", f72)
    f74 : U64 <- C.report_gerr("neg-beval-t2",
      O.bez3_eval(C.bz_s(), 2.0f64), "invalid-input", f73)
    f75 : U64 <- C.report_gerr("neg-beval-nan",
      O.bez3_eval(C.bz_s(), F64.nan()), "invalid-input", f74)
    f76 : U64 <- C.report_gerr("neg-beval-beznan",
      O.bez3_eval(G.Bz{C.p000(), C.p100(),
        V.Pt{F64.nan(), 0.0f64, 0.0f64}, C.p111()}, 0.5f64),
      "invalid-input", f75)
    f77 : U64 <- C.report_gerr("neg-bder-t2",
      O.bez3_der(C.bz_s(), 2.0f64), "invalid-input", f76)
    f78 : U64 <- C.report_gerr("neg-bder-ovf",
      O.bez3_der(C.bz_mx(), 0.5f64), "numerical-uncertainty", f77)
    f79 : U64 <- C.report_gerr("neg-bsplit-lo0",
      O.bez3_split_lo(C.bz_s(), 0.0f64), "invalid-input", f78)
    f80 : U64 <- C.report_gerr("neg-bsplit-lo2",
      O.bez3_split_lo(C.bz_s(), 2.0f64), "invalid-input", f79)
    f81 : U64 <- C.report_gerr("neg-bsplit-hi1",
      O.bez3_split_hi(C.bz_s(), 1.0f64), "invalid-input", f80)
    f82 : U64 <- C.report_gerr("neg-bbbox-nan",
      O.bez3_bbox(G.Bz{C.p000(), C.p100(), C.p010(),
        V.Pt{0.0f64, 0.0f64, F64.nan()}}),
      "invalid-input", f81)
    f83 : U64 <- C.report_gerr("neg-bend-nan",
      O.bez3_end0(G.Bz{V.Pt{F64.nan(), 0.0f64, 0.0f64}, C.p100(),
        C.p010(), C.p111()}),
      "invalid-input", f82)
    f84 : U64 <- C.report_gerr("neg-qeval-t2",
      O.rqb_eval(C.rq_quarter(), 2.0f64), "invalid-input", f83)
    return f84

def neg_g4(f84: U64) -> IO(U64):
  do IO<U64>:
    f85 : U64 <- C.report_gerr("neg-qeval-nan",
      O.rqb_eval(C.rq_quarter(), F64.nan()), "invalid-input", f84)
    f86 : U64 <- C.report_gerr("neg-qder-t2",
      O.rqb_der(C.rq_quarter(), 2.0f64), "invalid-input", f85)
    f87 : U64 <- C.report_gerr("neg-qder-ovf",
      O.rqb_der(G.Rq{V.Pt{C.nmx(), 0.0f64, 0.0f64},
        V.Pt{C.mx(), 0.0f64, 0.0f64}, C.p000(), 1.0f64, 1.0f64,
        1.0f64}, 0.5f64),
      "numerical-uncertainty", f86)
    f88 : U64 <- C.report_gerr("neg-qbb-nan",
      O.rqb_bbox(G.Rq{C.p100(), C.p111(),
        V.Pt{F64.nan(), 0.0f64, 0.0f64}, 1.0f64, 1.0f64, 1.0f64}),
      "invalid-input", f87)
    f89 : U64 <- C.report_gerr("neg-qdisc-nan",
      O.rqb_disc(G.Rq{C.p100(), C.p111(), C.p010(), 1.0f64,
        F64.nan(), 1.0f64}),
      "invalid-input", f88)
    f90 : U64 <- C.report_gerr("neg-rquarter-frame",
      O.rq_quarter(C.p000(), V.Dr{2.0f64, 0.0f64, 0.0f64}, C.d010(),
        2.0f64),
      "invalid-input", f89)
    f91 : U64 <- C.report_gerr("neg-rquarter-r0",
      O.rq_quarter(C.p000(), C.d100(), C.d010(), 0.0f64),
      "invalid-input", f90)
    f92 : U64 <- C.report_gerr("neg-peval-u2",
      O.bezp_eval(C.bp_flat(), 2.0f64, 0.5f64), "invalid-input", f91)
    f93 : U64 <- C.report_gerr("neg-peval-nan",
      O.bezp_eval(C.bp_flat(), 0.5f64, F64.nan()), "invalid-input",
      f92)
    f94 : U64 <- C.report_gerr("neg-pdu-u2",
      O.bezp_du(C.bp_flat(), 2.0f64, 0.5f64), "invalid-input", f93)
    f95 : U64 <- C.report_gerr("neg-pdu-ovf",
      O.bezp_du(G.Bp{V.Pt{C.nmx(), 0.0f64, 0.0f64},
        V.Pt{C.mx(), 0.0f64, 0.0f64}, C.p000(), C.p000(), C.p000(),
        C.p000(), C.p000(), C.p000(), C.p000(), C.p000(), C.p000(),
        C.p000(), C.p000(), C.p000(), C.p000(), C.p000()}, 0.5f64,
        0.5f64),
      "numerical-uncertainty", f94)
    f96 : U64 <- C.report_gerr("neg-pdv-v2",
      O.bezp_dv(C.bp_flat(), 0.5f64, 2.0f64), "invalid-input", f95)
    f97 : U64 <- C.report_gerr("neg-pdv-ovf",
      O.bezp_dv(G.Bp{V.Pt{C.nmx(), 0.0f64, 0.0f64},
        V.Pt{C.nmx(), 0.0f64, 0.0f64}, V.Pt{C.nmx(), 0.0f64, 0.0f64},
        V.Pt{C.nmx(), 0.0f64, 0.0f64}, V.Pt{C.mx(), 0.0f64, 0.0f64},
        V.Pt{C.mx(), 0.0f64, 0.0f64}, V.Pt{C.mx(), 0.0f64, 0.0f64},
        V.Pt{C.mx(), 0.0f64, 0.0f64}, C.p000(), C.p000(), C.p000(),
        C.p000(), C.p000(), C.p000(), C.p000(), C.p000()}, 0.5f64,
        0.5f64),
      "numerical-uncertainty", f96)
    f98 : U64 <- C.report_gerr("neg-pbb-nan",
      O.bezp_bbox(G.Bp{C.p000(), C.p000(), C.p000(), C.p000(),
        C.p000(), C.p000(), C.p000(), C.p000(), C.p000(), C.p000(),
        C.p000(), C.p000(), C.p000(), C.p000(), C.p000(),
        V.Pt{F64.nan(), 0.0f64, 0.0f64}}),
      "invalid-input", f97)
    f99 : U64 <- C.report_gerr("neg-piso-u2",
      O.bezp_iso_u(C.bp_flat(), 2.0f64), "invalid-input", f98)
    f100 : U64 <- C.report_gerr("neg-piso-v2",
      O.bezp_iso_v(C.bp_flat(), 2.0f64), "invalid-input", f99)
    f101 : U64 <- C.report_gerr("neg-pcorner-nan",
      O.bezp_c33(G.Bp{C.p000(), C.p000(), C.p000(), C.p000(),
        C.p000(), C.p000(), C.p000(), C.p000(), C.p000(), C.p000(),
        C.p000(), C.p000(), C.p000(), C.p000(), C.p000(),
        V.Pt{0.0f64, F64.nan(), 0.0f64}}),
      "invalid-input", f100)
    f102 : U64 <- C.report_gerr("neg-bbunion-nan",
      O.bbox_union(G.Bb{C.p000(), C.p111()},
        G.Bb{V.Pt{F64.nan(), 0.0f64, 0.0f64}, C.p111()}),
      "invalid-input", f101)
    f103 : U64 <- C.report_gerr("neg-cyck-axis2",
      O.cyl_checked(G.Cy{C.p000(), V.Dr{2.0f64, 0.0f64, 0.0f64},
        1.0f64}),
      "invalid-input", f102)
    f104 : U64 <- C.report_gerr("neg-cyck-nan",
      O.cyl_checked(G.Cy{C.p000(), V.Dr{F64.nan(), 0.0f64, 0.0f64},
        1.0f64}),
      "invalid-input", f103)
    f105 : U64 <- C.report_gerr("neg-cyck-axbig",
      O.cyl_checked(G.Cy{C.p000(), C.ax_big(), 1.0f64}),
      "invalid-input", f104)
    f106 : U64 <- C.report_gerr("neg-cock-axis2",
      O.cone_checked(G.Co{C.p000(), V.Dr{2.0f64, 0.0f64, 0.0f64},
        0.5f64}),
      "invalid-input", f105)
    f107 : U64 <- C.report_gerr("neg-cock-nan",
      O.cone_checked(G.Co{C.p000(), V.Dr{F64.nan(), 0.0f64, 0.0f64},
        0.5f64}),
      "invalid-input", f106)
    f108 : U64 <- C.report_gerr("neg-tock-axis2",
      O.tor_checked(G.To{C.p000(), V.Dr{2.0f64, 0.0f64, 0.0f64},
        4.0f64, 1.0f64}),
      "invalid-input", f107)
    f109 : U64 <- C.report_gerr("neg-tock-nan",
      O.tor_checked(G.To{C.p000(), V.Dr{F64.nan(), 0.0f64, 0.0f64},
        4.0f64, 1.0f64}),
      "invalid-input", f108)
    f110 : U64 <- C.report_gerr("neg-sphv-nan",
      O.sph_val(C.sp_unit(), V.Pt{F64.nan(), 0.0f64, 0.0f64}),
      "invalid-input", f109)
    f111 : U64 <- C.report_gerr("neg-sphv-ovf",
      O.sph_val(C.sp_unit(), V.Pt{C.mx(), 0.0f64, 0.0f64}),
      "numerical-uncertainty", f110)
    f112 : U64 <- C.report_gerr("neg-sphg-nan",
      O.sph_grad(C.sp_unit(), V.Pt{0.0f64, F64.nan(), 0.0f64}),
      "invalid-input", f111)
    return f112

def neg_g5(f112: U64) -> IO(U64):
  do IO<U64>:
    f113 : U64 <- C.report_gerr("neg-sphg-ovf",
      O.sph_grad(C.sp_unit(), V.Pt{C.mx(), 0.0f64, 0.0f64}),
      "numerical-uncertainty", f112)
    f114 : U64 <- C.report_gerr("neg-sphp-center",
      O.sph_project(C.sp_unit(), C.p000()), "invalid-input", f113)
    f115 : U64 <- C.report_gerr("neg-sphp-nan",
      O.sph_project(C.sp_unit(), V.Pt{F64.nan(), 0.0f64, 0.0f64}),
      "invalid-input", f114)
    f116 : U64 <- C.report_gerr("neg-spole-axis2",
      O.sph_pole_n(C.sp_unit(), V.Dr{2.0f64, 0.0f64, 0.0f64}),
      "invalid-input", f115)
    f117 : U64 <- C.report_gerr("neg-cylv-nan",
      O.cyl_val(C.cy_z(), V.Pt{F64.nan(), 0.0f64, 0.0f64}),
      "invalid-input", f116)
    f118 : U64 <- C.report_gerr("neg-cylv-axis2",
      O.cyl_val(G.Cy{C.p000(), V.Dr{2.0f64, 0.0f64, 0.0f64},
        1.0f64}, C.p100()),
      "invalid-input", f117)
    f119 : U64 <- C.report_gerr("neg-cylv-ovf",
      O.cyl_val(C.cy_z(), V.Pt{C.mx(), 0.0f64, 0.0f64}),
      "numerical-uncertainty", f118)
    f120 : U64 <- C.report_gerr("neg-cylg-nan",
      O.cyl_grad(C.cy_z(), V.Pt{0.0f64, F64.nan(), 0.0f64}),
      "invalid-input", f119)
    f121 : U64 <- C.report_gerr("neg-cylg-axis2",
      O.cyl_grad(G.Cy{C.p000(), V.Dr{2.0f64, 0.0f64, 0.0f64},
        1.0f64}, C.p100()),
      "invalid-input", f120)
    f122 : U64 <- C.report_gerr("neg-cov-nan",
      O.cone_val(C.co_z(), V.Pt{F64.nan(), 0.0f64, 0.0f64}),
      "invalid-input", f121)
    f123 : U64 <- C.report_gerr("neg-cov-axis2",
      O.cone_val(G.Co{C.p000(), V.Dr{2.0f64, 0.0f64, 0.0f64},
        0.5f64}, C.p100()),
      "invalid-input", f122)
    f124 : U64 <- C.report_gerr("neg-cov-ovf",
      O.cone_val(C.co_z(), V.Pt{C.mx(), 0.0f64, 0.0f64}),
      "numerical-uncertainty", f123)
    f125 : U64 <- C.report_gerr("neg-cog-nan",
      O.cone_grad(C.co_z(), V.Pt{0.0f64, F64.nan(), 0.0f64}),
      "invalid-input", f124)
    f126 : U64 <- C.report_gerr("neg-cog-axis2",
      O.cone_grad(G.Co{C.p000(), V.Dr{2.0f64, 0.0f64, 0.0f64},
        0.5f64}, C.p100()),
      "invalid-input", f125)
    f127 : U64 <- C.report_gerr("neg-coax-nan",
      O.cone_ax(C.co_z(), V.Pt{F64.nan(), 0.0f64, 0.0f64}),
      "invalid-input", f126)
    f128 : U64 <- C.report_gerr("neg-coax-axis2",
      O.cone_ax(G.Co{C.p000(), V.Dr{2.0f64, 0.0f64, 0.0f64},
        0.5f64}, C.p100()),
      "invalid-input", f127)
    f129 : U64 <- C.report_gerr("neg-torv-nan",
      O.tor_val(C.to_z(), V.Pt{F64.nan(), 0.0f64, 0.0f64}),
      "invalid-input", f128)
    f130 : U64 <- C.report_gerr("neg-torv-axis2",
      O.tor_val(G.To{C.p000(), V.Dr{2.0f64, 0.0f64, 0.0f64},
        4.0f64, 1.0f64}, C.p100()),
      "invalid-input", f129)
    f131 : U64 <- C.report_gerr("neg-torv-ovf",
      O.tor_val(C.to_z(), V.Pt{C.mx(), 0.0f64, 0.0f64}),
      "numerical-uncertainty", f130)
    f132 : U64 <- C.report_gerr("neg-torg-nan",
      O.tor_grad(C.to_z(), V.Pt{0.0f64, F64.nan(), 0.0f64}),
      "invalid-input", f131)
    f133 : U64 <- C.report_gerr("neg-torg-axis2",
      O.tor_grad(G.To{C.p000(), V.Dr{2.0f64, 0.0f64, 0.0f64},
        4.0f64, 1.0f64}, C.p100()),
      "invalid-input", f132)
    f134 : U64 <- C.report_gerr("neg-tse-u2",
      O.tseg_eval(C.ts_diag(), 2.0f64), "invalid-input", f133)
    f135 : U64 <- C.report_gerr("neg-tse-nan",
      O.tseg_eval(C.ts_diag(), F64.nan()), "invalid-input", f134)
    f136 : U64 <- C.report_gerr("neg-tse-tsnan",
      O.tseg_eval(G.Ts{C.v2_00(), V.V2{F64.nan(), 0.0f64}}, 0.5f64),
      "invalid-input", f135)
    f137 : U64 <- C.report_gerr("neg-tbe-u2",
      O.tbez_eval(C.tb_s(), 2.0f64), "invalid-input", f136)
    f138 : U64 <- C.report_gerr("neg-tbe-nan",
      O.tbez_eval(C.tb_s(), F64.nan()), "invalid-input", f137)
    f139 : U64 <- C.report_gerr("neg-tsbb-nan",
      O.tseg_bbox(G.Ts{C.v2_00(), V.V2{0.0f64, F64.nan()}}),
      "invalid-input", f138)
    f140 : U64 <- C.report_gerr("neg-tbbb-nan",
      O.tbez_bbox(G.Tb{C.v2_00(), C.v2_11(), V.V2{F64.nan(), 0.0f64},
        C.v2_11()}),
      "invalid-input", f139)
    return f140

def neg_g6(f140: U64) -> IO(U64):
  do IO<U64>:
    f141 : U64 <- C.report_gerr("neg-trimpt-frame",
      O.plane_trim_pt(C.pl_bad(), V.V2{2.0f64, 3.0f64}),
      "invalid-input", f140)
    f142 : U64 <- C.report_gerr("neg-trimpt-nan",
      O.plane_trim_pt(C.pl_xy(), V.V2{F64.nan(), 0.0f64}),
      "invalid-input", f141)
    f143 : U64 <- C.report_gerr("neg-nok-fuel0",
      O.nurbs_checked(C.nbk1(), 0n), "resource-exhausted", f142)
    f144 : U64 <- C.report_gerr("neg-nok-fuel5",
      O.nurbs_checked(C.nbk1(), 5n), "resource-exhausted", f143)
    f145 : U64 <- C.report_gerr("neg-nok-badcount",
      O.nurbs_checked(C.nbk_short(), 8n), "invalid-input", f144)
    f146 : U64 <- C.report_gerr("neg-nok-uncl",
      O.nurbs_checked(C.nbk_uncl(), 9n), "invalid-input", f145)
    f147 : U64 <- C.report_gerr("neg-nok-dec",
      O.nurbs_checked(C.nbk_dec(), 10n), "invalid-input", f146)
    f148 : U64 <- C.report_gerr("neg-nok-w0",
      O.nurbs_checked(C.nbk_w0(), 9n), "invalid-input", f147)
    f149 : U64 <- C.report_gerr("neg-nok-nanp",
      O.nurbs_checked(C.nbk_nanp(), 9n), "invalid-input", f148)
    f150 : U64 <- C.report_gerr("neg-nok-nank",
      O.nurbs_checked(C.nbk_nank(), 9n), "invalid-input", f149)
    f151 : U64 <- C.report_gerr("neg-nev-t2",
      O.nurbs_eval(C.nbk1(), 2.0f64, 9n), "invalid-input", f150)
    f152 : U64 <- C.report_gerr("neg-nev-nan",
      O.nurbs_eval(C.nbk1(), F64.nan(), 9n), "invalid-input", f151)
    f153 : U64 <- C.report_gerr("neg-nev-fuel0",
      O.nurbs_eval(C.nbk1(), 0.5f64, 0n), "resource-exhausted",
      f152)
    f154 : U64 <- C.report_gerr("neg-nev-fuel5",
      O.nurbs_eval(C.nbk1(), 0.5f64, 5n), "resource-exhausted",
      f153)
    f155 : U64 <- C.report_gerr("neg-nev-badcount",
      O.nurbs_eval(C.nbk_short(), 0.5f64, 8n), "invalid-input",
      f154)
    return f155

def neg_g7(f155: U64) -> IO(U64):
  do IO<U64>:
    f156 : U64 <- C.report_pure("neg-bn11-leval-ovf",
      C.gres_p_is_zero(bn11_leval()), f155)
    f157 : U64 <- C.report_pure("neg-bn11-nev-exh",
      C.gres_p_is_zero(bn11_nev()), f156)
    f158 : U64 <- C.report_pure("neg-bn11-plck",
      C.gres_p_is_zero(bn11_plck()), f157)
    f159 : U64 <- C.report_pure("neg-bn11-qdisc",
      U64.is_eq(F64.bits(G.gres_f(bn11_qdisc())), 0u64), f158)
    f160 : U64 <- C.report_pure("neg-bn11-wrap",
      U64.is_eq(F64.bits(G.gres_f(bn11_wrap())), 0u64), f159)
    # Corrected pins (src fixed 2026-09-25: degenerate wrap domains
    # rejected, far-field sphere projection abstains; the NURBS t=khi
    # endpoint pin lives in pos.bend as pos-nev-t1).
    f161 : U64 <- C.report_gerr("neg-wrap-degen1", wrap_degen1(),
      "invalid-input", f160)
    f162 : U64 <- C.report_gerr("neg-wrap-degen2", wrap_degen2(),
      "invalid-input", f161)
    f163 : U64 <- C.report_gerr("neg-sph-far", sph_far(),
      "numerical-uncertainty", f162)
    return f163

def main() -> IO(Unit):
  do IO<Unit>:
    a1 : U64 <- neg_g1(0u64)
    a2 : U64 <- neg_g2(a1)
    a3 : U64 <- neg_g3(a2)
    a4 : U64 <- neg_g4(a3)
    a5 : U64 <- neg_g5(a4)
    a6 : U64 <- neg_g6(a5)
    a7 : U64 <- neg_g7(a6)
    IO.print("selfcheck fails=" ++ U64.show(a7))
