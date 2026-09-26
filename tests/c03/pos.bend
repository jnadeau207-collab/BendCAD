# C03 positive tests: constructor pins, predicate/accessor pins, projector
# conventions. Ops.bend behavior pins append once src/c03/ops.bend lands.
# selfcheck fails=N.

import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c03/ops.bend as O
import ./check.bend as C

# Grouped to fit the native backend's arity limit (C02 D2 class).
def pos_g1(f0: U64) -> IO(U64):
  do IO<U64>:
    f1 : U64 <- C.report_gdom("pos-dom-ok",
      G.mk_dom(0.0f64, 1.0f64), 0u64, 4607182418800017408u64, f0)
    f2 : U64 <- C.report_ok("pos-line-ok",
      G.mk_line(C.p000(), C.d100()), f1)
    f3 : U64 <- C.report_ok("pos-plane-ok",
      G.mk_plane(G.Pl{C.p000(), C.d100(), C.d010()}), f2)
    f4 : U64 <- C.report_ok("pos-circ-ok",
      G.mk_circ(C.p000(), C.d100(), C.d010(), 2.0f64), f3)
    f5 : U64 <- C.report_ok("pos-bez-ok",
      G.mk_bez3(C.p000(), C.p100(), C.p010(), C.p111()), f4)
    f6 : U64 <- C.report_ok("pos-rq-ok",
      G.mk_rqbez(C.p100(), C.p111(), C.p010(), 1.0f64,
        G.w_quarter(), 1.0f64),
      f5)
    f7 : U64 <- C.report_ok("pos-bp-ok",
      G.mk_bezp(C.p000(), C.p000(), C.p000(), C.p000(), C.p000(),
        C.p100(), C.p010(), C.p000(), C.p000(), C.p010(), C.p111(),
        C.p000(), C.p000(), C.p000(), C.p000(), C.p000()),
      f6)
    f8 : U64 <- C.report_ok("pos-sph-ok",
      G.mk_sph(C.p123(), 2.0f64), f7)
    f9 : U64 <- C.report_ok("pos-cyl-ok",
      G.mk_cyl(C.p000(), C.d001(), 1.0f64), f8)
    f10 : U64 <- C.report_ok("pos-cone-ok",
      G.mk_cone(C.p000(), C.d001(), 0.5f64), f9)
    f11 : U64 <- C.report_ok("pos-torus-ok",
      G.mk_torus(C.p000(), C.d001(), 4.0f64, 1.0f64), f10)
    f12 : U64 <- C.report_gbb("pos-bb-ok",
      G.mk_bbox(C.p000(), C.p111()), 0u64, 0u64, 0u64,
      4607182418800017408u64, 4607182418800017408u64,
      4607182418800017408u64, f11)
    f13 : U64 <- C.report_ok("pos-tseg-ok",
      G.mk_tseg(C.v2_00(), C.v2_11()), f12)
    f14 : U64 <- C.report_ok("pos-tbez-ok",
      G.mk_tbez(C.v2_00(), C.v2_11(), C.v2_00(), C.v2_11()), f13)
    f15 : U64 <- C.report_pure("pos-spos-pos", G.spos(2.0f64), f14)
    f16 : U64 <- C.report_pure("pos-spos-zero",
      Bool.not(G.spos(0.0f64)), f15)
    f17 : U64 <- C.report_pure("pos-spos-neg",
      Bool.not(G.spos(F64.neg(1.0f64))), f16)
    f18 : U64 <- C.report_pure("pos-spos-inf",
      Bool.not(G.spos(F64{9218868437227405312u64})), f17)
    f19 : U64 <- C.report_pure("pos-spos-nan",
      Bool.not(G.spos(F64.nan())), f18)
    f20 : U64 <- C.report_pure("pos-dz-zero", G.dr_is_zero(C.d000()),
      f19)
    f21 : U64 <- C.report_pure("pos-dz-unit",
      Bool.not(G.dr_is_zero(C.d100())), f20)
    f22 : U64 <- C.report_pure("pos-fin-ln-false",
      Bool.not(G.ln_fin(G.Ln{V.Pt{F64.nan(), 0.0f64, 0.0f64},
        C.d100()})),
      f21)
    f23 : U64 <- C.report_pure("pos-fin-sp-true",
      G.sp_fin(G.Sp{C.p123(), 2.0f64}), f22)
    f24 : U64 <- C.report_pure("pos-acc-dom",
      Bool.and(U64.is_eq(F64.bits(G.dom_lo(G.Dom{2.0f64, 3.0f64})),
          4611686018427387904u64),
        U64.is_eq(F64.bits(G.dom_hi(G.Dom{2.0f64, 3.0f64})),
          4613937818241073152u64)),
      f23)
    f25 : U64 <- C.report_pure("pos-acc-ln",
      Bool.and(U64.is_eq(F64.bits(
            V.pt_x(G.ln_p(G.Ln{C.p123(), C.d100()}))),
          4607182418800017408u64),
        U64.is_eq(F64.bits(V.dr_y(G.ln_d(G.Ln{C.p123(), C.d010()}))),
          4607182418800017408u64)),
      f24)
    f26 : U64 <- C.report_pure("pos-acc-cc-sp",
      Bool.and(U64.is_eq(F64.bits(
            G.cc_r(G.Cc{C.p000(), C.d100(), C.d010(), 2.0f64})),
          4611686018427387904u64),
        U64.is_eq(F64.bits(G.sp_r(G.Sp{C.p123(), 3.0f64})),
          4613937818241073152u64)),
      f25)
    return f26

def pos_g2(f26: U64) -> IO(U64):
  do IO<U64>:
    f27 : U64 <- C.report_pure("pos-wq",
      U64.is_eq(F64.bits(G.w_quarter()), 4604544271217802189u64),
      f26)
    f28 : U64 <- C.report_pure("pos-kind-doc",
      Bool.and(String.eq(T.FailKind.show(
          G.gres_kind(G.gok_f(1.0f64))), "invalid-input"),
        Bool.and(String.eq(T.FailKind.show(
            G.gres_kind(G.gok_p(C.p000()))), "invalid-input"),
          Bool.and(String.eq(T.FailKind.show(
              G.gres_kind(G.gok_bb(C.bb_unit()))), "invalid-input"),
            String.eq(T.FailKind.show(
              G.gres_kind(G.gok_dom(G.Dom{0.0f64, 1.0f64}))),
              "invalid-input")))),
      f27)
    f29 : U64 <- C.report_pure("pos-gok-show",
      Bool.and(String.eq(G.gres_show(G.gok_f(1.0f64)), "ok"),
        Bool.and(G.gres_ok(G.gok_p(C.p000())),
          G.gres_ok(G.gok_v2(C.v2_11())))),
      f28)
    f30 : U64 <- C.report_gf("pos-dmid", O.dom_mid(C.dom_25()),
      4615063718147915776u64, f29)
    f31 : U64 <- C.report_gf("pos-dlen", O.dom_len(C.dom_25()),
      4613937818241073152u64, f30)
    f32 : U64 <- C.report_gf("pos-clamp-in",
      O.dom_clamp(G.Dom{0.0f64, 5.0f64}, 2.0f64),
      4611686018427387904u64, f31)
    f33 : U64 <- C.report_gf("pos-clamp-lo",
      O.dom_clamp(G.Dom{0.0f64, 5.0f64}, 0.0f64), 0u64, f32)
    f34 : U64 <- C.report_gf("pos-clamp-hi",
      O.dom_clamp(G.Dom{0.0f64, 5.0f64}, 5.0f64),
      4617315517961601024u64, f33)
    f35 : U64 <- C.report_gf("pos-clamp-under",
      O.dom_clamp(G.Dom{0.0f64, 5.0f64}, F64.neg(1.0f64)), 0u64,
      f34)
    f36 : U64 <- C.report_gf("pos-clamp-over",
      O.dom_clamp(G.Dom{0.0f64, 5.0f64}, 7.0f64),
      4617315517961601024u64, f35)
    f37 : U64 <- C.report_gf("pos-wrap-under",
      O.pdom_wrap(C.pdom_per(), F64.neg(3.0f64)),
      4619567317775286272u64, f36)
    f38 : U64 <- C.report_gf("pos-wrap-over",
      O.pdom_wrap(C.pdom_per(), 13.0f64), 4613937818241073152u64,
      f37)
    f39 : U64 <- C.report_gf("pos-wrap-in",
      O.pdom_wrap(C.pdom_per(), 4.0f64), 4616189618054758400u64,
      f38)
    f40 : U64 <- C.report_gf("pos-wrap-clamped",
      O.pdom_wrap(C.pdom_cl(), 13.0f64), 4621819117588971520u64,
      f39)
    f41 : U64 <- C.report_gdom("pos-split-lo",
      O.dom_split_lo(C.dom_010(), 4.0f64), 0u64,
      4616189618054758400u64, f40)
    f42 : U64 <- C.report_gdom("pos-split-hi",
      O.dom_split_hi(C.dom_010(), 4.0f64), 4616189618054758400u64,
      4621819117588971520u64, f41)
    f43 : U64 <- C.report_gp("pos-leval-t3", O.line_eval(C.ln_x(),
      3.0f64), 4613937818241073152u64, 0u64, 0u64, f42)
    f44 : U64 <- C.report_gp("pos-leval-tneg", O.line_eval(C.ln_x(),
      F64.neg(2.0f64)), 13835058055282163712u64, 0u64, 0u64, f43)
    f45 : U64 <- C.report_gd("pos-lder", O.line_der(C.ln_x()),
      4607182418800017408u64, 0u64, 0u64, f44)
    f46 : U64 <- C.report_gf("pos-lproj-t5",
      O.line_project(C.ln_x(), V.Pt{5.0f64, 2.0f64, 0.0f64}),
      4617315517961601024u64, f45)
    f47 : U64 <- C.report_gf("pos-lproj-sk",
      O.line_project(C.ln_sk(), V.Pt{1.0f64, 2.0f64, 3.0f64}),
      4601597955262077993u64, f46)
    f48 : U64 <- C.report_gf("pos-ldist-2",
      O.line_dist(C.ln_x(), V.Pt{5.0f64, 2.0f64, 0.0f64}),
      4611686018427387904u64, f47)
    f49 : U64 <- C.report_gf("pos-ldist-sk",
      O.line_dist(C.ln_sk(), V.Pt{1.0f64, 2.0f64, 3.0f64}),
      4600877379321698720u64, f48)
    f50 : U64 <- C.report_gbb("pos-segbb",
      O.line_seg_bbox(C.p000(), C.p123()), 0u64, 0u64, 0u64,
      4607182418800017408u64, 4611686018427387904u64,
      4613937818241073152u64, f49)
    f51 : U64 <- C.report_ok("pos-plck-ok", O.plane_checked(C.pl_xy()),
      f50)
    f52 : U64 <- C.report_gd("pos-pln", O.plane_normal(C.pl_xy()), 0u64,
      0u64, 4607182418800017408u64, f51)
    return f52

def pos_g3(f52: U64) -> IO(U64):
  do IO<U64>:
    f53 : U64 <- C.report_gp("pos-pleval-23",
      O.plane_eval(C.pl_xy(), 2.0f64, 3.0f64),
      4611686018427387904u64, 4613937818241073152u64, 0u64, f52)
    f54 : U64 <- C.report_gp("pos-pleval-d",
      O.plane_eval(C.pl_d(), 2.0f64, 3.0f64),
      4613937818241073152u64, 4616189618054758400u64,
      4607182418800017408u64, f53)
    f55 : U64 <- C.report_gv2("pos-plproj",
      O.plane_project(C.pl_xy(), V.Pt{2.0f64, 3.0f64, 4.0f64}),
      4611686018427387904u64, 4613937818241073152u64, f54)
    f56 : U64 <- C.report_gf("pos-pldist-4",
      O.plane_dist(C.pl_xy(), V.Pt{2.0f64, 3.0f64, 4.0f64}),
      4616189618054758400u64, f55)
    f57 : U64 <- C.report_gf("pos-pldist-d",
      O.plane_dist(C.pl_d(), V.Pt{1.0f64, 1.0f64, 5.0f64}),
      4616189618054758400u64, f56)
    f58 : U64 <- C.report_gbb("pos-plbb",
      O.plane_uv_bbox(C.pl_xy(), 0.0f64, 2.0f64, 0.0f64, 3.0f64),
      0u64, 0u64, 0u64, 4611686018427387904u64,
      4613937818241073152u64, 0u64, f57)
    f59 : U64 <- C.report_ok("pos-cck-ok",
      O.circ_checked(C.cc_unit()), f58)
    f60 : U64 <- C.report_gp("pos-ceval-t0", O.circ_eval(C.cc_unit(),
      0.0f64), 4607182418800017408u64, 0u64, 0u64, f59)
    f61 : U64 <- C.report_gp("pos-ceval-t1", O.circ_eval(C.cc_unit(),
      1.0f64), 13830554455654793216u64, 0u64, 0u64, f60)
    f62 : U64 <- C.report_gp("pos-ceval-tneg1", O.circ_eval(
      C.cc_unit(), F64.neg(1.0f64)), 13830554455654793216u64, 0u64,
      0u64, f61)
    f63 : U64 <- C.report_gp("pos-ceval-t05", O.circ_eval(
      C.cc_unit(), 0.5f64), 13822087688355336684u64,
      4606822130829827768u64, 0u64, f62)
    f64 : U64 <- C.report_gp("pos-ceval-r2", O.circ_eval(C.cc_r2(),
      0.0f64), 4611686018427387904u64, 0u64, 0u64, f63)
    f65 : U64 <- C.report_gd("pos-cder-t0", O.circ_der(C.cc_unit(),
      0.0f64), 0u64, 4616189618054758400u64, 0u64, f64)
    f66 : U64 <- C.report_gd("pos-cder-t05", O.circ_der(C.cc_unit(),
      0.5f64), 13837471984682434298u64, 13829617706932300153u64,
      9223372036854775808u64, f65)
    f67 : U64 <- C.report_gp("pos-cseam", O.circ_seam_pt(C.cc_unit()),
      13830554455654793216u64, 0u64, 0u64, f66)
    f68 : U64 <- C.report_gbb("pos-cbb", O.circ_bbox(C.cc_unit()),
      13830554455654793216u64, 13830554455654793216u64, 0u64,
      4607182418800017408u64, 4607182418800017408u64, 0u64, f67)
    f69 : U64 <- C.report_gp("pos-beval-t0", O.bez3_eval(C.bz_s(),
      0.0f64), 0u64, 0u64, 0u64, f68)
    f70 : U64 <- C.report_gp("pos-beval-t1", O.bez3_eval(C.bz_s(),
      1.0f64), 4607182418800017408u64, 4607182418800017408u64,
      4607182418800017408u64, f69)
    f71 : U64 <- C.report_gp("pos-beval-t05", O.bez3_eval(C.bz_s(),
      0.5f64), 4602678819172646912u64, 4602678819172646912u64,
      4593671619917905920u64, f70)
    f72 : U64 <- C.report_gp("pos-beval-t03", O.bez3_eval(C.bz_s(),
      0.3f64), 4602102358420343487u64, 4596950240446631641u64,
      4583439441564520153u64, f71)
    f73 : U64 <- C.report_gd("pos-bder-t0", O.bez3_der(C.bz_s(),
      0.0f64), 4613937818241073152u64, 0u64, 0u64, f72)
    f74 : U64 <- C.report_gd("pos-bder-t05", O.bez3_der(C.bz_s(),
      0.5f64), 0u64, 4609434218613702656u64, 4604930618986332160u64,
      f73)
    f75 : U64 <- C.report_ok("pos-bsplit-lo-ok",
      O.bez3_split_lo(C.bz_s(), 0.5f64), f74)
    f76 : U64 <- C.report_gp("pos-bsplit-lo-end0",
      O.bez3_end0(C.unwrap_bz(O.bez3_split_lo(C.bz_s(), 0.5f64))),
      0u64, 0u64, 0u64, f75)
    f77 : U64 <- C.report_gp("pos-bsplit-lo-joint",
      O.bez3_end1(C.unwrap_bz(O.bez3_split_lo(C.bz_s(), 0.5f64))),
      4602678819172646912u64, 4602678819172646912u64,
      4593671619917905920u64, f76)
    f78 : U64 <- C.report_ok("pos-bsplit-hi-ok",
      O.bez3_split_hi(C.bz_s(), 0.5f64), f77)
    return f78

def pos_g4(f78: U64) -> IO(U64):
  do IO<U64>:
    f79 : U64 <- C.report_gp("pos-bsplit-hi-end1",
      O.bez3_end1(C.unwrap_bz(O.bez3_split_hi(C.bz_s(), 0.5f64))),
      4607182418800017408u64, 4607182418800017408u64,
      4607182418800017408u64, f78)
    f80 : U64 <- C.report_gp("pos-bsplit-hi-joint",
      O.bez3_end0(C.unwrap_bz(O.bez3_split_hi(C.bz_s(), 0.5f64))),
      4602678819172646912u64, 4602678819172646912u64,
      4593671619917905920u64, f79)
    f81 : U64 <- C.report_gbb("pos-bbbox", O.bez3_bbox(C.bz_s()), 0u64,
      0u64, 0u64, 4607182418800017408u64, 4607182418800017408u64,
      4607182418800017408u64, f80)
    f82 : U64 <- C.report_gp("pos-bend0", O.bez3_end0(C.bz_s()), 0u64,
      0u64, 0u64, f81)
    f83 : U64 <- C.report_gp("pos-bend1", O.bez3_end1(C.bz_s()),
      4607182418800017408u64, 4607182418800017408u64,
      4607182418800017408u64, f82)
    f84 : U64 <- C.report_gp("pos-qeval-q0", O.rqb_eval(C.rq_quarter(),
      0.0f64), 4607182418800017408u64, 0u64, 0u64, f83)
    f85 : U64 <- C.report_gp("pos-qeval-q05", O.rqb_eval(
      C.rq_quarter(), 0.5f64), 4604544271217802188u64,
      4604544271217802188u64, 0u64, f84)
    f86 : U64 <- C.report_gp("pos-qeval-q1", O.rqb_eval(C.rq_quarter(),
      1.0f64), 0u64, 4607182418800017408u64, 0u64, f85)
    f87 : U64 <- C.report_gd("pos-qder-q0", O.rqb_der(C.rq_quarter(),
      0.0f64), 0u64, 4609047870845172685u64, 0u64, f86)
    f88 : U64 <- C.report_gbb("pos-qbb", O.rqb_bbox(C.rq_quarter()),
      0u64, 0u64, 0u64, 4607182418800017408u64,
      4607182418800017408u64, 0u64, f87)
    f89 : U64 <- C.report_gf("pos-qdisc-q", O.rqb_disc(C.rq_quarter()),
      13826050856027422718u64, f88)
    f90 : U64 <- C.report_gf("pos-qdisc-p", O.rqb_disc(C.rq_p()), 0u64,
      f89)
    f91 : U64 <- C.report_gf("pos-qdisc-h", O.rqb_disc(C.rq_h()),
      4613937818241073152u64, f90)
    f92 : U64 <- C.report_ok("pos-rquarter-ok",
      O.rq_quarter(C.p000(), C.d100(), C.d010(), 2.0f64), f91)
    f93 : U64 <- C.report_gp("pos-rquarter-eval",
      O.rqb_eval(C.unwrap_rq(O.rq_quarter(C.p000(), C.d100(),
        C.d010(), 2.0f64)), 0.5f64), 4609047870845172684u64,
      4609047870845172684u64, 0u64, f92)
    f94 : U64 <- C.report_gp("pos-peval-flat",
      O.bezp_eval(C.bp_flat(), 0.5f64, 0.5f64),
      4609434218613702656u64, 4609434218613702656u64, 0u64, f93)
    f95 : U64 <- C.report_gp("pos-peval-bump",
      O.bezp_eval(C.bp_bump(), 0.5f64, 0.5f64),
      4609434218613702656u64, 4609434218613702656u64,
      4603241769126068224u64, f94)
    f96 : U64 <- C.report_gp("pos-peval-c33",
      O.bezp_eval(C.bp_bump(), 1.0f64, 1.0f64),
      4613937818241073152u64, 4613937818241073152u64, 0u64, f95)
    f97 : U64 <- C.report_gd("pos-pdu-flat",
      O.bezp_du(C.bp_flat(), 0.5f64, 0.5f64), 0u64,
      4613937818241073152u64, 0u64, f96)
    f98 : U64 <- C.report_gd("pos-pdv-flat",
      O.bezp_dv(C.bp_flat(), 0.5f64, 0.5f64),
      4613937818241073152u64, 0u64, 0u64, f97)
    f99 : U64 <- C.report_gbb("pos-pbb-flat", O.bezp_bbox(C.bp_flat()),
      0u64, 0u64, 0u64, 4613937818241073152u64,
      4613937818241073152u64, 0u64, f98)
    f100 : U64 <- C.report_gbb("pos-pbb-bump", O.bezp_bbox(C.bp_bump()),
      0u64, 0u64, 0u64, 4613937818241073152u64,
      4613937818241073152u64, 4616189618054758400u64, f99)
    f101 : U64 <- C.report_ok("pos-piso-u-ok",
      O.bezp_iso_u(C.bp_flat(), 0.5f64), f100)
    f102 : U64 <- C.report_gp("pos-piso-u-end0",
      O.bez3_end0(C.unwrap_bz(O.bezp_iso_u(C.bp_flat(), 0.5f64))),
      0u64, 4609434218613702656u64, 0u64, f101)
    f103 : U64 <- C.report_ok("pos-piso-v-ok",
      O.bezp_iso_v(C.bp_flat(), 0.5f64), f102)
    f104 : U64 <- C.report_gp("pos-piso-v-end1",
      O.bez3_end1(C.unwrap_bz(O.bezp_iso_v(C.bp_flat(), 0.5f64))),
      4609434218613702656u64, 4613937818241073152u64, 0u64, f103)
    return f104

def pos_g5(f104: U64) -> IO(U64):
  do IO<U64>:
    f105 : U64 <- C.report_gp("pos-pcorner-c00", O.bezp_c00(C.bp_flat()),
      0u64, 0u64, 0u64, f104)
    f106 : U64 <- C.report_gp("pos-pcorner-c03", O.bezp_c03(C.bp_flat()),
      0u64, 4613937818241073152u64, 0u64, f105)
    f107 : U64 <- C.report_gp("pos-pcorner-c30", O.bezp_c30(C.bp_flat()),
      4613937818241073152u64, 0u64, 0u64, f106)
    f108 : U64 <- C.report_gp("pos-pcorner-c33", O.bezp_c33(C.bp_flat()),
      4613937818241073152u64, 4613937818241073152u64, 0u64, f107)
    f109 : U64 <- C.report_gbb("pos-bbunion",
      O.bbox_union(G.Bb{C.p000(), C.p111()},
        G.Bb{V.Pt{2.0f64, 2.0f64, 2.0f64},
          V.Pt{3.0f64, 3.0f64, 3.0f64}}),
      0u64, 0u64, 0u64, 4613937818241073152u64,
      4613937818241073152u64, 4613937818241073152u64, f108)
    f110 : U64 <- C.report_ok("pos-cyck-ok",
      O.cyl_checked(C.cy_z()), f109)
    f111 : U64 <- C.report_ok("pos-cyck-axok",
      O.cyl_checked(G.Cy{C.p000(), C.ax_ok(), 1.0f64}), f110)
    f112 : U64 <- C.report_ok("pos-cock-ok",
      O.cone_checked(C.co_z()), f111)
    f113 : U64 <- C.report_ok("pos-tock-ok",
      O.tor_checked(C.to_z()), f112)
    f114 : U64 <- C.report_gf("pos-sphv-on",
      O.sph_val(C.sp_unit(), C.p100()), 0u64, f113)
    f115 : U64 <- C.report_gf("pos-sphv-out",
      O.sph_val(C.sp_unit(), V.Pt{2.0f64, 0.0f64, 0.0f64}),
      4613937818241073152u64, f114)
    f116 : U64 <- C.report_gf("pos-sphv-in",
      O.sph_val(C.sp_unit(), C.p000()), 13830554455654793216u64,
      f115)
    f117 : U64 <- C.report_gd("pos-sphg",
      O.sph_grad(C.sp_unit(), C.p123()), 4611686018427387904u64,
      4616189618054758400u64, 4618441417868443648u64, f116)
    f118 : U64 <- C.report_gp("pos-sphp-200",
      O.sph_project(C.sp_unit(), V.Pt{2.0f64, 0.0f64, 0.0f64}),
      4607182418800017408u64, 0u64, 0u64, f117)
    f119 : U64 <- C.report_gp("pos-sphp-345",
      O.sph_project(C.sp_unit(), V.Pt{3.0f64, 4.0f64, 0.0f64}),
      4603579539098121011u64, 4605380978949069210u64, 0u64, f118)
    f120 : U64 <- C.report_gp("pos-spole-n",
      O.sph_pole_n(C.sp_unit(), C.d001()), 0u64, 0u64,
      4607182418800017408u64, f119)
    f121 : U64 <- C.report_gp("pos-spole-s",
      O.sph_pole_s(C.sp_unit(), C.d001()), 0u64, 0u64,
      13830554455654793216u64, f120)
    f122 : U64 <- C.report_gf("pos-cylv-on",
      O.cyl_val(C.cy_z(), V.Pt{1.0f64, 0.0f64, 5.0f64}), 0u64,
      f121)
    f123 : U64 <- C.report_gf("pos-cylv-off",
      O.cyl_val(C.cy_z(), V.Pt{2.0f64, 0.0f64, 0.0f64}),
      4613937818241073152u64, f122)
    f124 : U64 <- C.report_gd("pos-cylg",
      O.cyl_grad(C.cy_z(), V.Pt{1.0f64, 0.0f64, 5.0f64}),
      4611686018427387904u64, 0u64, 0u64, f123)
    f125 : U64 <- C.report_gf("pos-cov-on",
      O.cone_val(C.co_z(), V.Pt{1.0f64, 0.0f64, 2.0f64}), 0u64,
      f124)
    f126 : U64 <- C.report_gf("pos-cov-off",
      O.cone_val(C.co_z(), V.Pt{2.0f64, 0.0f64, 2.0f64}),
      4613937818241073152u64, f125)
    f127 : U64 <- C.report_gd("pos-cog",
      O.cone_grad(C.co_z(), V.Pt{1.0f64, 0.0f64, 2.0f64}),
      4611686018427387904u64, 0u64, 13830554455654793216u64, f126)
    f128 : U64 <- C.report_gf("pos-coax-2",
      O.cone_ax(C.co_z(), V.Pt{1.0f64, 0.0f64, 2.0f64}),
      4611686018427387904u64, f127)
    f129 : U64 <- C.report_gf("pos-coax-neg",
      O.cone_ax(C.co_z(), V.Pt{0.0f64, 0.0f64, F64.neg(3.0f64)}),
      13837309855095848960u64, f128)
    f130 : U64 <- C.report_gf("pos-torv-eq",
      O.tor_val(C.to_z(), V.Pt{5.0f64, 0.0f64, 0.0f64}), 0u64,
      f129)
    return f130

def pos_g6(f130: U64) -> IO(U64):
  do IO<U64>:
    f131 : U64 <- C.report_gd("pos-torg-eq",
      O.tor_grad(C.to_z(), V.Pt{5.0f64, 0.0f64, 0.0f64}),
      4639833516098453504u64, 0u64, 0u64, f130)
    f132 : U64 <- C.report_gv2("pos-tse-t0",
      O.tseg_eval(C.ts_diag(), 0.0f64), 0u64, 0u64, f131)
    f133 : U64 <- C.report_gv2("pos-tse-t05",
      O.tseg_eval(C.ts_diag(), 0.5f64), 4602678819172646912u64,
      4602678819172646912u64, f132)
    f134 : U64 <- C.report_gv2("pos-tse-t1",
      O.tseg_eval(C.ts_diag(), 1.0f64), 4607182418800017408u64,
      4607182418800017408u64, f133)
    f135 : U64 <- C.report_gv2("pos-tbe-t0",
      O.tbez_eval(C.tb_s(), 0.0f64), 0u64, 0u64, f134)
    f136 : U64 <- C.report_gv2("pos-tbe-t05",
      O.tbez_eval(C.tb_s(), 0.5f64), 4602678819172646912u64,
      4602678819172646912u64, f135)
    f137 : U64 <- C.report_gv2("pos-tbe-t1",
      O.tbez_eval(C.tb_s(), 1.0f64), 4607182418800017408u64,
      4607182418800017408u64, f136)
    f138 : U64 <- C.report_gbb("pos-tsbb", O.tseg_bbox(C.ts_diag()), 0u64,
      0u64, 0u64, 4607182418800017408u64, 4607182418800017408u64,
      0u64, f137)
    f139 : U64 <- C.report_gbb("pos-tbbb", O.tbez_bbox(C.tb_s()), 0u64,
      0u64, 0u64, 4607182418800017408u64, 4607182418800017408u64,
      0u64, f138)
    f140 : U64 <- C.report_gp("pos-trimpt-23",
      O.plane_trim_pt(C.pl_xy(), V.V2{2.0f64, 3.0f64}),
      4611686018427387904u64, 4613937818241073152u64, 0u64, f139)
    f141 : U64 <- C.report_ok("pos-nok-ok",
      O.nurbs_checked(C.nbk1(), 9n), f140)
    f142 : U64 <- C.report_gp("pos-nev-t05",
      O.nurbs_eval(C.nbk1(), 0.5f64, 9n), 4602678819172646912u64,
      4602678819172646912u64, 4593671619917905920u64, f141)
    f143 : U64 <- C.report_gp("pos-nev-t0",
      O.nurbs_eval(C.nbk1(), 0.0f64, 9n), 0u64, 0u64, 0u64, f142)
    f144 : U64 <- C.report_pure("pos-nev-bez-equiv",
      C.ev_eq(O.nurbs_eval(C.nbk1(), 0.5f64, 9n),
        O.bez3_eval(C.bz_s(), 0.5f64)),
      f143)
    f145 : U64 <- C.report_gf("pos-bn8-wrap-once",
      O.pdom_wrap(C.pdom_per(), 25.0f64), 4624633867356078080u64,
      f144)
    f146 : U64 <- C.report_pure("pos-bn8-nok-fuel",
      String.eq(G.gres_show(O.nurbs_checked(C.nbk1(), 5n)),
        "resource-exhausted"),
      f145)
    f147 : U64 <- C.report_pure("pos-bn10-bez",
      C.ev_in_bb(O.bez3_eval(C.bz_s(), 0.3f64),
        O.bez3_bbox(C.bz_s())),
      f146)
    f148 : U64 <- C.report_pure("pos-bn10-circ",
      C.ev_in_bb(O.circ_eval(C.cc_unit(), 0.5f64),
        O.circ_bbox(C.cc_unit())),
      f147)
    f149 : U64 <- C.report_pure("pos-bn10-rqb",
      C.ev_in_bb(O.rqb_eval(C.rq_quarter(), 0.5f64),
        O.rqb_bbox(C.rq_quarter())),
      f148)
    f150 : U64 <- C.report_pure("pos-bn10-bezp",
      C.ev_in_bb(O.bezp_eval(C.bp_bump(), 0.5f64, 0.5f64),
        O.bezp_bbox(C.bp_bump())),
      f149)
    f151 : U64 <- C.report_pure("pos-bn10-line",
      C.ev_in_bb(O.line_eval(C.ln_x(), 1.5f64),
        O.line_seg_bbox(C.p000(), V.Pt{3.0f64, 0.0f64, 0.0f64})),
      f150)
    f152 : U64 <- C.report_pure("pos-bn10-plane",
      C.ev_in_bb(O.plane_eval(C.pl_xy(), 1.0f64, 1.0f64),
        O.plane_uv_bbox(C.pl_xy(), 0.0f64, 2.0f64, 0.0f64, 3.0f64)),
      f151)
    f153 : U64 <- C.report_pure("pos-bn10-tbez",
      C.v2_in_bb(O.tbez_eval(C.tb_s(), 0.3f64),
        O.tbez_bbox(C.tb_s())),
      f152)
    f154 : U64 <- C.report_gp("pos-nev-t1",
      O.nurbs_eval(C.nbk1(), 1.0f64, 9n), 4607182418800017408u64,
      4607182418800017408u64, 4607182418800017408u64, f153)
    return f154

# C03.1: scaled sphere projection at extreme scales — finite norm
# with a tiny r/n ratio still publishes the surface point.
def pos_g7(f154: U64) -> IO(U64):
  do IO<U64>:
    f155 : U64 <- C.report_gp("pos-sphp-faraxis",
      O.sph_project(C.sp_unit(), V.Pt{C.mx(), 0.0f64, 0.0f64}),
      4607182418800017408u64, 0u64, 0u64, f154)
    f156 : U64 <- C.report_gp("pos-sphp-minr",
      O.sph_project(G.Sp{C.p000(), F64{1u64}},
        V.Pt{C.mx(), 0.0f64, 0.0f64}),
      1u64, 0u64, 0u64, f155)
    f157 : U64 <- C.report_gp("pos-sphp-farctr",
      O.sph_project(G.Sp{C.p100(), 1.0f64},
        V.Pt{C.mx(), 0.0f64, 0.0f64}),
      4611686018427387904u64, 0u64, 0u64, f156)
    f158 : U64 <- C.report_gp("pos-sphp-mixed",
      O.sph_project(C.sp_unit(), V.Pt{C.mx(), F64{1u64}, 0.0f64}),
      4607182418800017408u64, 0u64, 0u64, f157)
    return f158

def main() -> IO(Unit):
  do IO<Unit>:
    a1 : U64 <- pos_g1(0u64)
    a2 : U64 <- pos_g2(a1)
    a3 : U64 <- pos_g3(a2)
    a4 : U64 <- pos_g4(a3)
    a5 : U64 <- pos_g5(a4)
    a6 : U64 <- pos_g6(a5)
    a7 : U64 <- pos_g7(a6)
    IO.print("selfcheck fails=" ++ U64.show(a7))
