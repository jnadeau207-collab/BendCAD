# C04 positive tests: constructor pins, predicate/accessor pins,
# store-op pins, issue-protocol pins, projector conventions,
# brep_checked exit fixtures (seams/cavity/open/pole accept).
# selfcheck fails=N.

import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c04/ops.bend as Op
import ./check.bend as C

def hva() -> Ty.HVertex:
  Ty.mk_hv(0n, 1u64)

def hvb() -> Ty.HVertex:
  Ty.mk_hv(1n, 2u64)

def hea() -> Ty.HEdge:
  Ty.mk_he(0n, 11u64)

def b_pvx() -> Ty.Brep:
  Ty.tres_brep(Ty.vx_push(Ty.brep_empty(), C.p123()))

def b_ped() -> Ty.Brep:
  Ty.tres_brep(Ty.ed_push(Ty.brep_empty(), hva(), hvb(),
    Ty.EK_curve{C.cv_ln(), C.dom_01()}))

def b_pce() -> Ty.Brep:
  Ty.tres_brep(Ty.ce_push(Ty.brep_empty(), hea(), True{},
    C.tr_ts()))

def b_plp() -> Ty.Brep:
  Ty.tres_brep(Ty.lp_push(Ty.brep_empty(), C.hc1(),
    Ty.LK_outer{}))

def b_pfa() -> Ty.Brep:
  Ty.tres_brep(Ty.fa_push(Ty.brep_empty(), C.sf_pl(),
    C.hlp1(), True{}))

def b_psh() -> Ty.Brep:
  Ty.tres_brep(Ty.sh_push(Ty.brep_empty(), C.hfa1(),
    Ty.SK_outer{}))

def b_pso() -> Ty.Brep:
  Ty.tres_brep(Ty.so_push(Ty.brep_empty(),
    Ty.mk_hsh(0n, 51u64), C.hsh0()))

def at_v1() -> Ty.TRes:
  Ty.vx_at(C.vs2(), 1n, 9n)

def res_v() -> Ty.TRes:
  Ty.vx_resolve(C.vs1(), Ty.mk_hv(0n, 1u64), 9n)

def rj() -> Ty.TRes:
  Ty.mk_vx(C.pnan())

# Grouped to fit the native backend's arity limit (C02 D2 class).
def pos_g1(f0: U64) -> IO(U64):
  do IO<U64>:
    f1 : U64 <- C.report_ok("pos-vx-ok",
      Ty.mk_vx(C.p123()), f0)
    f2 : U64 <- C.report_ok("pos-ec-ok",
      Ty.mk_edge_curve(hva(), hvb(), C.cv_ln(),
        C.dom_01()),
      f1)
    f3 : U64 <- C.report_ok("pos-ec-closed-ok",
      Ty.mk_edge_curve(hva(), hva(), C.cv_cc(),
        C.dom_01()),
      f2)
    f4 : U64 <- C.report_ok("pos-ed-ok",
      Ty.mk_edge_degen(hva(), hva()), f3)
    f5 : U64 <- C.report_ok("pos-ce-fwd-ok",
      Ty.mk_coedge(hea(), True{}, C.tr_ts()), f4)
    f6 : U64 <- C.report_ok("pos-ce-rev-ok",
      Ty.mk_coedge(hea(), False{}, C.tr_tb()), f5)
    f7 : U64 <- C.report_ok("pos-lp-ok",
      Ty.mk_loop(C.hc1(), Ty.LK_outer{}), f6)
    f8 : U64 <- C.report_ok("pos-lp-seam2-ok",
      Ty.mk_loop(C.hc2(), Ty.LK_outer{}), f7)
    f9 : U64 <- C.report_ok("pos-fa-ok",
      Ty.mk_face(C.sf_pl(), C.hlp1(), True{}), f8)
    f10 : U64 <- C.report_ok("pos-fa-flip-ok",
      Ty.mk_face(C.sf_cy(), C.hlp1(), False{}), f9)
    f11 : U64 <- C.report_ok("pos-sh-outer-ok",
      Ty.mk_shell(C.hfa1(), Ty.SK_outer{}), f10)
    f12 : U64 <- C.report_ok("pos-sh-inner-ok",
      Ty.mk_shell(C.hfa1(), Ty.SK_inner{}), f11)
    f13 : U64 <- C.report_ok("pos-sh-open-ok",
      Ty.mk_shell(C.hfa1(), Ty.SK_open{}), f12)
    f14 : U64 <- C.report_ok("pos-so-ok",
      Ty.mk_solid(Ty.mk_hsh(0n, 51u64), C.hsh0()),
      f13)
    f15 : U64 <- C.report_ok("pos-so-cav-ok",
      Ty.mk_solid(Ty.mk_hsh(0n, 51u64), C.hsh1()),
      f14)
    f16 : U64 <- C.report_ok("pos-cp-ok",
      Ty.mk_compound(C.hso1(), C.hsh0()), f15)
    f17 : U64 <- C.report_ok("pos-cp-open-ok",
      Ty.mk_compound(C.hso0(), C.hsh1()), f16)
    f18 : U64 <- C.report_tn("pos-tok-n", Ty.tok_n(7n), 7n,
      f17)
    f19 : U64 <- C.report_tf("pos-tok-f", Ty.tok_f(2.0f64),
      4611686018427387904u64, f18)
    f20 : U64 <- C.report_pure("pos-kind-tok",
      String.eq(T.FailKind.show(Ty.tres_kind(Ty.tok_n(1n))),
        "invalid-input"),
      f19)
    f21 : U64 <- C.report_pure("pos-kind-terr",
      String.eq(
        T.FailKind.show(Ty.tres_kind(Ty.terr(
          T.F_exhausted{}))),
        "resource-exhausted"),
      f20)
    f22 : U64 <- C.report_pure("pos-show-ok",
      String.eq(Ty.tres_show(Ty.tok_b(True{})), "ok"),
      f21)
    f23 : U64 <- C.report_pure("pos-show-err",
      String.eq(Ty.tres_show(rj()), "invalid-input"),
      f22)
    f24 : U64 <- C.report_pure("pos-ok-true",
      Ty.tres_ok(Ty.tok_n(0n)), f23)
    f25 : U64 <- C.report_pure("pos-ok-false",
      Bool.not(Ty.tres_ok(rj())), f24)
    return f25

def pos_g2(f25: U64) -> IO(U64):
  do IO<U64>:
    f26 : U64 <- C.report_pure("pos-isc-ln",
      Ty.gval_is_curve(C.cv_ln()), f25)
    f27 : U64 <- C.report_pure("pos-isc-cc",
      Ty.gval_is_curve(C.cv_cc()), f26)
    f28 : U64 <- C.report_pure("pos-isc-bz",
      Ty.gval_is_curve(C.cv_bz()), f27)
    f29 : U64 <- C.report_pure("pos-isc-rq",
      Ty.gval_is_curve(C.cv_rq()), f28)
    f30 : U64 <- C.report_pure("pos-isc-nb",
      Ty.gval_is_curve(C.cv_nb()), f29)
    f31 : U64 <- C.report_pure("pos-isc-pl-no",
      Bool.not(Ty.gval_is_curve(C.sf_pl())), f30)
    f32 : U64 <- C.report_pure("pos-isc-ts-no",
      Bool.not(Ty.gval_is_curve(C.tr_ts())), f31)
    f33 : U64 <- C.report_pure("pos-iss-pl",
      Ty.gval_is_surf(C.sf_pl()), f32)
    f34 : U64 <- C.report_pure("pos-iss-cy",
      Ty.gval_is_surf(C.sf_cy()), f33)
    f35 : U64 <- C.report_pure("pos-iss-co",
      Ty.gval_is_surf(C.sf_co()), f34)
    f36 : U64 <- C.report_pure("pos-iss-sp",
      Ty.gval_is_surf(C.sf_sp()), f35)
    f37 : U64 <- C.report_pure("pos-iss-to",
      Ty.gval_is_surf(C.sf_to()), f36)
    f38 : U64 <- C.report_pure("pos-iss-bp",
      Ty.gval_is_surf(C.sf_bp()), f37)
    f39 : U64 <- C.report_pure("pos-iss-ln-no",
      Bool.not(Ty.gval_is_surf(C.cv_ln())), f38)
    f40 : U64 <- C.report_pure("pos-iss-tb-no",
      Bool.not(Ty.gval_is_surf(C.tr_tb())), f39)
    f41 : U64 <- C.report_pure("pos-ist-ts",
      Ty.gval_is_trim(C.tr_ts()), f40)
    f42 : U64 <- C.report_pure("pos-ist-tb",
      Ty.gval_is_trim(C.tr_tb()), f41)
    f43 : U64 <- C.report_pure("pos-ist-bz-no",
      Bool.not(Ty.gval_is_trim(C.cv_bz())), f42)
    f44 : U64 <- C.report_pure("pos-ist-sp-no",
      Bool.not(Ty.gval_is_trim(C.sf_sp())), f43)
    f45 : U64 <- C.report_pure("pos-ne-hc1",
      Ty.hce_nonempty(C.hc1()), f44)
    f46 : U64 <- C.report_pure("pos-ne-hc0",
      Bool.not(Ty.hce_nonempty(C.hc0())), f45)
    f47 : U64 <- C.report_pure("pos-ne-hso1",
      Ty.hso_nonempty(C.hso1()), f46)
    f48 : U64 <- C.report_pure("pos-ne-hso0",
      Bool.not(Ty.hso_nonempty(C.hso0())), f47)
    return f48

def pos_g3(f48: U64) -> IO(U64):
  do IO<U64>:
    f49 : U64 <- C.report_pure("pos-vx-valid",
      Ty.vx_valid(C.vx_a()), f48)
    f50 : U64 <- C.report_pure("pos-vx-nan-no",
      Bool.not(Ty.vx_valid(Ty.Vx{0u64, C.pnan()})), f49)
    f51 : U64 <- C.report_pure("pos-ev-curve",
      Ty.edge_valid(C.ed_a()), f50)
    f52 : U64 <- C.report_pure("pos-ev-closed",
      Ty.edge_valid(Ty.Ed{0u64, hva(), hva(),
        Ty.EK_curve{C.cv_ln(), C.dom_01()}}),
      f51)
    f53 : U64 <- C.report_pure("pos-ev-degen",
      Ty.edge_valid(Ty.Ed{0u64, hva(), hva(),
        Ty.EK_degenerate{}}),
      f52)
    f54 : U64 <- C.report_pure("pos-ev-degen-no",
      Bool.not(Ty.edge_valid(Ty.Ed{0u64, hva(), hvb(),
        Ty.EK_degenerate{}})),
      f53)
    f55 : U64 <- C.report_pure("pos-ev-arm-no",
      Bool.not(Ty.edge_valid(Ty.Ed{0u64, hva(), hvb(),
        Ty.EK_curve{C.sf_pl(), C.dom_01()}})),
      f54)
    f56 : U64 <- C.report_pure("pos-eclosed-yes",
      Ty.edge_is_closed(Ty.Ed{0u64, hva(), hva(),
        Ty.EK_curve{C.cv_ln(), C.dom_01()}}),
      f55)
    f57 : U64 <- C.report_pure("pos-eclosed-no",
      Bool.not(Ty.edge_is_closed(C.ed_a())), f56)
    f58 : U64 <- C.report_pure("pos-edegen-yes",
      Ty.edge_is_degenerate(Ty.Ed{0u64, hva(), hva(),
        Ty.EK_degenerate{}}),
      f57)
    f59 : U64 <- C.report_pure("pos-edegen-no",
      Bool.not(Ty.edge_is_degenerate(C.ed_a())), f58)
    f60 : U64 <- C.report_pure("pos-ce-valid",
      Ty.ce_valid(C.ce_a()), f59)
    f61 : U64 <- C.report_pure("pos-ce-arm-no",
      Bool.not(Ty.ce_valid(Ty.Ce{0u64, hea(), True{},
        C.cv_ln()})),
      f60)
    f62 : U64 <- C.report_pure("pos-lp-valid",
      Ty.lp_valid(C.lp_a()), f61)
    f63 : U64 <- C.report_pure("pos-lp-nil-no",
      Bool.not(Ty.lp_valid(Ty.Lp{0u64, C.hc0(),
        Ty.LK_outer{}})),
      f62)
    f64 : U64 <- C.report_pure("pos-fa-valid",
      Ty.fa_valid(C.fa_a()), f63)
    f65 : U64 <- C.report_pure("pos-fa-arm-no",
      Bool.not(Ty.fa_valid(Ty.Fa{0u64, C.cv_cc(),
        C.hlp1(), True{}})),
      f64)
    f66 : U64 <- C.report_pure("pos-fa-loops-no",
      Bool.not(Ty.fa_valid(Ty.Fa{0u64, C.sf_pl(),
        C.hlp0(), True{}})),
      f65)
    f67 : U64 <- C.report_pure("pos-sh-valid",
      Ty.sh_valid(C.sh_a()), f66)
    f68 : U64 <- C.report_pure("pos-sh-nil-no",
      Bool.not(Ty.sh_valid(Ty.Sh{0u64, C.hfa0(),
        Ty.SK_outer{}})),
      f67)
    f69 : U64 <- C.report_pure("pos-so-valid",
      Ty.so_valid(C.so_a()), f68)
    f70 : U64 <- C.report_pure("pos-so-cav-no",
      Bool.not(Ty.so_has_cav(C.so_a())), f69)
    f71 : U64 <- C.report_pure("pos-so-cav-yes",
      Ty.so_has_cav(C.so_b()), f70)
    f72 : U64 <- C.report_pure("pos-cp-sol-yes",
      Ty.cp_has_solids(C.top1()), f71)
    f73 : U64 <- C.report_pure("pos-cp-sol-no",
      Bool.not(Ty.cp_has_solids(C.top0())), f72)
    f74 : U64 <- C.report_pure("pos-cp-sh-yes",
      Ty.cp_has_shells(C.top1()), f73)
    f75 : U64 <- C.report_pure("pos-cp-sh-no",
      Bool.not(Ty.cp_has_shells(C.top0())), f74)
    return f75

def pos_g4(f75: U64) -> IO(U64):
  do IO<U64>:
    f76 : U64 <- C.report_pure("pos-eq-hv",
      Ty.hv_eq(hva(), hva()), f75)
    f77 : U64 <- C.report_pure("pos-eq-hv-gen",
      Bool.not(Ty.hv_eq(Ty.mk_hv(0n, 1u64),
        Ty.mk_hv(0n, 2u64))),
      f76)
    f78 : U64 <- C.report_pure("pos-eq-hv-idx",
      Bool.not(Ty.hv_eq(hva(), hvb())), f77)
    f79 : U64 <- C.report_pure("pos-eq-he",
      Ty.he_eq(hea(), hea()), f78)
    f80 : U64 <- C.report_pure("pos-eq-he-no",
      Bool.not(Ty.he_eq(Ty.mk_he(0n, 11u64),
        Ty.mk_he(0n, 12u64))),
      f79)
    f81 : U64 <- C.report_pure("pos-eq-hc",
      Ty.hc_eq(Ty.mk_hc(0n, 21u64),
        Ty.mk_hc(0n, 21u64)),
      f80)
    f82 : U64 <- C.report_pure("pos-eq-hc-no",
      Bool.not(Ty.hc_eq(Ty.mk_hc(0n, 21u64),
        Ty.mk_hc(1n, 21u64))),
      f81)
    f83 : U64 <- C.report_pure("pos-eq-hlp",
      Ty.hlp_eq(Ty.mk_hlp(0n, 31u64),
        Ty.mk_hlp(0n, 31u64)),
      f82)
    f84 : U64 <- C.report_pure("pos-eq-hlp-no",
      Bool.not(Ty.hlp_eq(Ty.mk_hlp(0n, 31u64),
        Ty.mk_hlp(0n, 32u64))),
      f83)
    f85 : U64 <- C.report_pure("pos-eq-hfa",
      Ty.hfa_eq(Ty.mk_hfa(0n, 41u64),
        Ty.mk_hfa(0n, 41u64)),
      f84)
    f86 : U64 <- C.report_pure("pos-eq-hfa-no",
      Bool.not(Ty.hfa_eq(Ty.mk_hfa(0n, 41u64),
        Ty.mk_hfa(0n, 42u64))),
      f85)
    f87 : U64 <- C.report_pure("pos-eq-hsh",
      Ty.hsh_eq(Ty.mk_hsh(0n, 51u64),
        Ty.mk_hsh(0n, 51u64)),
      f86)
    f88 : U64 <- C.report_pure("pos-eq-hsh-no",
      Bool.not(Ty.hsh_eq(Ty.mk_hsh(0n, 51u64),
        Ty.mk_hsh(0n, 52u64))),
      f87)
    f89 : U64 <- C.report_pure("pos-eq-hso",
      Ty.hso_eq(Ty.mk_hso(0n, 61u64),
        Ty.mk_hso(0n, 61u64)),
      f88)
    f90 : U64 <- C.report_pure("pos-eq-hso-no",
      Bool.not(Ty.hso_eq(Ty.mk_hso(0n, 61u64),
        Ty.mk_hso(0n, 62u64))),
      f89)
    f91 : U64 <- C.report_pure("pos-tag-ek-curve",
      U64.is_eq(Ty.ekind_tag(
        Ty.EK_curve{C.cv_ln(), C.dom_01()}), 0u64),
      f90)
    f92 : U64 <- C.report_pure("pos-tag-ek-degen",
      U64.is_eq(Ty.ekind_tag(Ty.EK_degenerate{}), 1u64),
      f91)
    f93 : U64 <- C.report_pure("pos-tag-lk-outer",
      U64.is_eq(Ty.lkind_tag(Ty.LK_outer{}), 0u64),
      f92)
    f94 : U64 <- C.report_pure("pos-tag-lk-inner",
      U64.is_eq(Ty.lkind_tag(Ty.LK_inner{}), 1u64),
      f93)
    f95 : U64 <- C.report_pure("pos-tag-sk-outer",
      U64.is_eq(Ty.skind_tag(Ty.SK_outer{}), 0u64),
      f94)
    f96 : U64 <- C.report_pure("pos-tag-sk-inner",
      U64.is_eq(Ty.skind_tag(Ty.SK_inner{}), 1u64),
      f95)
    f97 : U64 <- C.report_pure("pos-tag-sk-open",
      U64.is_eq(Ty.skind_tag(Ty.SK_open{}), 2u64),
      f96)
    return f97

def pos_g5(f97: U64) -> IO(U64):
  do IO<U64>:
    f98 : U64 <- C.report_pure("pos-tag-prof-solid",
      U64.is_eq(Ty.profile_tag(Ty.P_manifold_solid{}),
        0u64),
      f97)
    f99 : U64 <- C.report_pure("pos-tag-prof-open",
      U64.is_eq(Ty.profile_tag(Ty.P_open_shell{}), 1u64),
      f98)
    f100 : U64 <- C.report_pure("pos-show-prof-solid",
      String.eq(Ty.profile_show(Ty.P_manifold_solid{}),
        "manifold-solid"),
      f99)
    f101 : U64 <- C.report_pure("pos-show-prof-open",
      String.eq(Ty.profile_show(Ty.P_open_shell{}),
        "open-shell"),
      f100)
    f102 : U64 <- C.report_pure("pos-okd-ok",
      Ty.okd_ok(3n), f101)
    f103 : U64 <- C.report_pure("pos-okd-done",
      Ty.okd_done(3n), f102)
    f104 : U64 <- C.report_pure("pos-okd-ok-no",
      Bool.not(Ty.okd_ok(2n)), f103)
    f105 : U64 <- C.report_pure("pos-okd-done-no",
      Bool.not(Ty.okd_done(1n)), f104)
    f106 : U64 <- C.report_pure("pos-okd-all-ok",
      Nat.is_eq(Ty.okd_all(3n, 3n), 3n), f105)
    f107 : U64 <- C.report_pure("pos-okd-all-mix",
      Nat.is_eq(Ty.okd_all(3n, 2n), 2n), f106)
    f108 : U64 <- C.report_pure("pos-allc-vs0",
      Nat.is_eq(Ty.vs_all_c(C.vs0(), 0n), 3n), f107)
    f109 : U64 <- C.report_pure("pos-allc-vs1",
      Nat.is_eq(Ty.vs_all_c(C.vs1(), 9n), 3n), f108)
    f110 : U64 <- C.report_pure("pos-allc-vs-bad",
      Nat.is_eq(Ty.vs_all_c(C.vs_bad(), 9n), 2n), f109)
    f111 : U64 <- C.report_pure("pos-allc-vs-fuel",
      Bool.not(Ty.okd_done(Ty.vs_all_c(C.vs1(), 0n))),
      f110)
    f112 : U64 <- C.report_pure("pos-allc-es1",
      Nat.is_eq(Ty.es_all_c(C.es1(), 9n), 3n), f111)
    f113 : U64 <- C.report_pure("pos-allc-so1",
      Nat.is_eq(Ty.sos_all_c(C.sos1(), 9n), 3n), f112)
    return f113

def pos_g6(f113: U64) -> IO(U64):
  do IO<U64>:
    f114 : U64 <- C.report_tn("pos-len-vs0",
      Ty.vx_len(C.vs0(), 9n), 0n, f113)
    f115 : U64 <- C.report_tn("pos-len-vs1",
      Ty.vx_len(C.vs1(), 9n), 1n, f114)
    f116 : U64 <- C.report_tn("pos-len-vs2",
      Ty.vx_len(C.vs2(), 9n), 2n, f115)
    f117 : U64 <- C.report_tn("pos-len-es1",
      Ty.ed_len(C.es1(), 9n), 1n, f116)
    f118 : U64 <- C.report_tn("pos-len-ces1",
      Ty.ce_len(C.ces1(), 9n), 1n, f117)
    f119 : U64 <- C.report_tn("pos-len-lps1",
      Ty.lp_len(C.lps1(), 9n), 1n, f118)
    f120 : U64 <- C.report_tn("pos-len-fas1",
      Ty.fa_len(C.fas1(), 9n), 1n, f119)
    f121 : U64 <- C.report_tn("pos-len-shs1",
      Ty.sh_len(C.shs1(), 9n), 1n, f120)
    f122 : U64 <- C.report_tn("pos-len-sos1",
      Ty.so_len(C.sos1(), 9n), 1n, f121)
    f123 : U64 <- C.report_ok("pos-at-vx-headfree",
      Ty.vx_at(C.vs1(), 0n, 0n), f122)
    f124 : U64 <- C.report_ok("pos-at-so-headfree",
      Ty.so_at(C.sos1(), 0n, 0n), f123)
    f125 : U64 <- C.report_pure("pos-at-vx-1",
      Bool.and(C.ok_as(at_v1()),
        U64.is_eq(Ty.vx_gen(Ty.tres_vx(at_v1())), 2u64)),
      f124)
    f126 : U64 <- C.report_pure("pos-res-vx",
      Bool.and(C.ok_as(res_v()),
        U64.is_eq(F64.bits(V.pt_x(
          Ty.vx_p(Ty.tres_vx(res_v())))), 0u64)),
      f125)
    f127 : U64 <- C.report_ok("pos-res-ed",
      Ty.ed_resolve(C.es1(), Ty.mk_he(0n, 11u64), 9n),
      f126)
    f128 : U64 <- C.report_ok("pos-res-so",
      Ty.so_resolve(C.sos1(), Ty.mk_hso(0n, 61u64), 9n),
      f127)
    f129 : U64 <- C.report_pure("pos-hof-vx",
      Ty.hv_eq(Ty.tres_hv(Ty.vx_handle_of(C.vs1(), 1u64,
        9n)), Ty.mk_hv(0n, 1u64)),
      f128)
    f130 : U64 <- C.report_pure("pos-hof-vx-0head",
      Bool.and(C.ok_as(Ty.vx_handle_of(C.vs1(), 1u64,
          0n)),
        Ty.hv_eq(Ty.tres_hv(Ty.vx_handle_of(C.vs1(), 1u64,
          0n)), Ty.mk_hv(0n, 1u64))),
      f129)
    f131 : U64 <- C.report_pure("pos-hof-ed",
      Ty.he_eq(Ty.tres_he(Ty.ed_handle_of(C.es2(), 12u64,
        9n)), Ty.mk_he(1n, 12u64)),
      f130)
    f132 : U64 <- C.report_pure("pos-iss-vx",
      Ty.hv_eq(Ty.tres_hv(Ty.vx_issued(Ty.brep_empty(),
        9n)), Ty.mk_hv(0n, 1u64)),
      f131)
    f133 : U64 <- C.report_pure("pos-iss-so",
      Ty.hso_eq(Ty.tres_hso(Ty.so_issued(Ty.brep_empty(),
        9n)), Ty.mk_hso(0n, 1u64)),
      f132)
    f134 : U64 <- C.report_tn("pos-snoc-vx",
      Ty.vx_len(Ty.vx_snoc(C.vs1(), C.vx_b()), 9n), 2n,
      f133)
    f135 : U64 <- C.report_tn("pos-snoc-ed",
      Ty.ed_len(Ty.ed_snoc(C.es1(), C.ed_b()), 9n), 2n,
      f134)
    return f135

def pos_g7(f135: U64) -> IO(U64):
  do IO<U64>:
    f136 : U64 <- C.report_ok("pos-psh-vx",
      Ty.vx_push(Ty.brep_empty(), C.p123()), f135)
    f137 : U64 <- C.report_ok("pos-psh-ed",
      Ty.ed_push(Ty.brep_empty(), hva(), hvb(),
        Ty.EK_curve{C.cv_ln(), C.dom_01()}),
      f136)
    f138 : U64 <- C.report_ok("pos-psh-ce",
      Ty.ce_push(Ty.brep_empty(), hea(), True{},
        C.tr_ts()),
      f137)
    f139 : U64 <- C.report_ok("pos-psh-lp",
      Ty.lp_push(Ty.brep_empty(), C.hc1(),
        Ty.LK_outer{}),
      f138)
    f140 : U64 <- C.report_ok("pos-psh-fa",
      Ty.fa_push(Ty.brep_empty(), C.sf_pl(), C.hlp1(),
        True{}),
      f139)
    f141 : U64 <- C.report_ok("pos-psh-sh",
      Ty.sh_push(Ty.brep_empty(), C.hfa1(),
        Ty.SK_outer{}),
      f140)
    f142 : U64 <- C.report_ok("pos-psh-so",
      Ty.so_push(Ty.brep_empty(), Ty.mk_hsh(0n, 51u64),
        C.hsh0()),
      f141)
    f143 : U64 <- C.report_pure("pos-psh-stamp",
      U64.is_eq(Ty.brep_stamp(b_pvx()), 1u64), f142)
    f144 : U64 <- C.report_ok("pos-psh-dangling",
      Ty.ed_push(Ty.brep_empty(), Ty.hv_null(),
        Ty.hv_null(), Ty.EK_curve{C.cv_ln(), C.dom_01()}),
      f143)
    f145 : U64 <- C.report_pure("pos-psh-resolve",
      Bool.and(
        C.ok_as(Ty.vx_resolve(Ty.brep_vs(b_pvx()),
          Ty.mk_hv(0n, 1u64), 9n)),
        U64.is_eq(F64.bits(V.pt_x(Ty.vx_p(Ty.tres_vx(
          Ty.vx_resolve(Ty.brep_vs(b_pvx()),
            Ty.mk_hv(0n, 1u64), 9n))))),
          4607182418800017408u64)),
      f144)
    f146 : U64 <- C.report_pure("pos-iss-names-slot",
      Ty.hv_eq(
        Ty.tres_hv(Ty.vx_issued(Ty.brep_empty(), 9n)),
        Ty.tres_hv(Ty.vx_handle_of(Ty.brep_vs(b_pvx()),
          1u64, 9n))),
      f145)
    f147 : U64 <- C.report_pure("pos-psh-stamp2",
      U64.is_eq(Ty.brep_stamp(Ty.tres_brep(Ty.ed_push(
        b_pvx(), hva(), hvb(),
        Ty.EK_curve{C.cv_ln(), C.dom_01()}))), 2u64),
      f146)
    f148 : U64 <- C.report_ok("pos-mb-empty",
      Ty.mk_brep(C.vs0(), C.es0(), C.ces0(), C.lps0(),
        C.fas0(), C.shs0(), C.sos0(), C.top0(), 0u64, 9n),
      f147)
    f149 : U64 <- C.report_ok("pos-mb-full",
      Ty.mk_brep(C.vs1(), C.es1(), C.ces1(), C.lps1(),
        C.fas1(), C.shs1(), C.sos1(), C.top1(), 61u64, 9n),
      f148)
    f150 : U64 <- C.report_pure("pos-mb-stamp",
      U64.is_eq(Ty.brep_stamp(Ty.tres_brep(Ty.mk_brep(
        C.vs1(), C.es1(), C.ces1(), C.lps1(), C.fas1(),
        C.shs1(), C.sos1(), C.top1(), 61u64, 9n))),
        61u64),
      f149)
    f151 : U64 <- C.report_pure("pos-set-top",
      Ty.cp_has_solids(Ty.brep_top(Ty.brep_set_top(
        C.b_vs1(), C.top1()))),
      f150)
    f152 : U64 <- C.report_pure("pos-empty",
      Bool.and(U64.is_eq(
          Ty.brep_stamp(Ty.brep_empty()), 0u64),
        Bool.not(Ty.cp_has_shells(Ty.brep_top(
          Ty.brep_empty())))),
      f151)
    return f152

def pos_g8(f152: U64) -> IO(U64):
  do IO<U64>:
    f153 : U64 <- C.report_pure("pos-dflt-f",
      U64.is_eq(F64.bits(Ty.tres_f(rj())), 0u64), f152)
    f154 : U64 <- C.report_pure("pos-dflt-n",
      Nat.is_eq(Ty.tres_n(rj()), 0n), f153)
    f155 : U64 <- C.report_pure("pos-dflt-b",
      Bool.not(Ty.tres_b(rj())), f154)
    f156 : U64 <- C.report_pure("pos-dflt-vx",
      Bool.and(U64.is_eq(Ty.vx_gen(Ty.tres_vx(rj())),
          0u64),
        Bool.and(U64.is_eq(F64.bits(V.pt_x(Ty.vx_p(
              Ty.tres_vx(rj())))), 0u64),
          Bool.and(U64.is_eq(F64.bits(V.pt_y(Ty.vx_p(
                Ty.tres_vx(rj())))), 0u64),
            U64.is_eq(F64.bits(V.pt_z(Ty.vx_p(
              Ty.tres_vx(rj())))), 0u64)))),
      f155)
    f157 : U64 <- C.report_pure("pos-dflt-ed",
      Bool.and(U64.is_eq(Ty.ekind_tag(Ty.ed_kind(
            Ty.tres_ed(rj()))), 1u64),
        Bool.and(Ty.hv_eq(Ty.ed_v0(Ty.tres_ed(rj())),
            Ty.hv_null()),
          Ty.hv_eq(Ty.ed_v1(Ty.tres_ed(rj())),
            Ty.hv_null()))),
      f156)
    f158 : U64 <- C.report_pure("pos-dflt-ce",
      Bool.and(Bool.not(Ty.ce_fwd(Ty.tres_ce(rj()))),
        Bool.and(Ty.he_eq(Ty.ce_edge(Ty.tres_ce(rj())),
            Ty.he_null()),
          Ty.gval_is_trim(Ty.ce_trim(Ty.tres_ce(rj()))))),
      f157)
    f159 : U64 <- C.report_pure("pos-dflt-lp",
      Bool.and(Bool.not(Ty.hce_nonempty(Ty.lp_ces(
            Ty.tres_lp(rj())))),
        U64.is_eq(Ty.lkind_tag(Ty.lp_kind(
          Ty.tres_lp(rj()))), 0u64)),
      f158)
    f160 : U64 <- C.report_pure("pos-dflt-fa",
      Bool.and(Ty.gval_is_surf(Ty.fa_surf(
            Ty.tres_fa(rj()))),
        Bool.and(Bool.not(Ty.hlp_nonempty(Ty.fa_loops(
              Ty.tres_fa(rj())))),
          Ty.fa_same(Ty.tres_fa(rj())))),
      f159)
    f161 : U64 <- C.report_pure("pos-dflt-sh",
      Bool.and(Bool.not(Ty.hfa_nonempty(Ty.sh_faces(
            Ty.tres_sh(rj())))),
        U64.is_eq(Ty.skind_tag(Ty.sh_kind(
          Ty.tres_sh(rj()))), 2u64)),
      f160)
    f162 : U64 <- C.report_pure("pos-dflt-so",
      Bool.and(Ty.hsh_eq(Ty.so_outer(Ty.tres_so(rj())),
          Ty.hsh_null()),
        Bool.not(Ty.hsh_nonempty(Ty.so_cavities(
          Ty.tres_so(rj()))))),
      f161)
    f163 : U64 <- C.report_pure("pos-dflt-cp",
      Bool.and(Bool.not(Ty.cp_has_solids(
            Ty.tres_cp(rj()))),
        Bool.not(Ty.cp_has_shells(Ty.tres_cp(rj())))),
      f162)
    f164 : U64 <- C.report_pure("pos-dflt-brep",
      U64.is_eq(Ty.brep_stamp(Ty.tres_brep(rj())), 0u64),
      f163)
    f165 : U64 <- C.report_pure("pos-dflt-handles",
      Bool.and(Ty.hv_eq(Ty.tres_hv(rj()), Ty.hv_null()),
        Bool.and(Ty.he_eq(Ty.tres_he(rj()), Ty.he_null()),
          Bool.and(Ty.hc_eq(Ty.tres_hc(rj()),
              Ty.hc_null()),
            Bool.and(Ty.hlp_eq(Ty.tres_hlp(rj()),
                Ty.hlp_null()),
              Bool.and(Ty.hfa_eq(Ty.tres_hfa(rj()),
                  Ty.hfa_null()),
                Bool.and(Ty.hsh_eq(Ty.tres_hsh(rj()),
                    Ty.hsh_null()),
                  Ty.hso_eq(Ty.tres_hso(rj()),
                    Ty.hso_null()))))))),
      f164)
    f166 : U64 <- C.report_pure("pos-dflt-wrong-f",
      U64.is_eq(F64.bits(Ty.tres_f(Ty.tok_n(5n))), 0u64),
      f165)
    f167 : U64 <- C.report_pure("pos-dflt-wrong-n",
      Nat.is_eq(Ty.tres_n(Ty.tok_f(1.0f64)), 0n), f166)
    f168 : U64 <- C.report_pure("pos-dflt-wrong-vx",
      U64.is_eq(Ty.vx_gen(Ty.tres_vx(Ty.tok_n(0n))),
        0u64),
      f167)
    f169 : U64 <- C.report_pure("pos-dflt-wrong-hv",
      Ty.hv_eq(Ty.tres_hv(Ty.tok_brep(Ty.brep_empty())),
        Ty.hv_null()),
      f168)
    f170 : U64 <- C.report_pure("pos-zero-curve",
      Ty.gval_is_curve(Ty.curve_zero()), f169)
    f171 : U64 <- C.report_pure("pos-zero-surf",
      Ty.gval_is_surf(Ty.surf_zero()), f170)
    f172 : U64 <- C.report_pure("pos-zero-trim",
      Ty.gval_is_trim(Ty.trim_zero()), f171)
    f173 : U64 <- C.report_pure("pos-null-self",
      Ty.hv_eq(Ty.hv_null(), Ty.hv_null()), f172)
    return f173

def pos_g9(f173: U64) -> IO(U64):
  do IO<U64>:
    f174 : U64 <- C.report_pure("pos-gen-vs-ok",
      Nat.is_eq(Ty.vs_gen_c(C.vs1(), 1u64, 9n), 3n), f173)
    f175 : U64 <- C.report_pure("pos-gen-vs-stamp",
      Nat.is_eq(Ty.vs_gen_c(C.vs1(), 0u64, 9n), 2n), f174)
    f176 : U64 <- C.report_pure("pos-gen-vs-zero",
      Nat.is_eq(Ty.vs_gen_c(C.vs_gen0(), 1u64, 9n), 2n),
      f175)
    f177 : U64 <- C.report_pure("pos-gen-vs-fuel",
      Bool.not(Ty.okd_done(Ty.vs_gen_c(C.vs1(), 1u64, 0n))),
      f176)
    f178 : U64 <- C.report_pure("pos-nodup-vs-ok",
      Nat.is_eq(Ty.vs_nodup_c(C.vs2(), 9n), 3n), f177)
    f179 : U64 <- C.report_pure("pos-nodup-vs-dup",
      Nat.is_eq(Ty.vs_nodup_c(C.vs_dup(), 9n), 2n), f178)
    f180 : U64 <- C.report_pure("pos-nodup-vs-fuel",
      Bool.not(Ty.okd_done(Ty.vs_nodup_c(C.vs1(), 0n))),
      f179)
    f181 : U64 <- C.report_pure("pos-hsh-nd-ok",
      Nat.is_eq(Op.hsh_nodup_c(C.hsh1(), 9n), 3n), f180)
    f182 : U64 <- C.report_pure("pos-hsh-nd-dup",
      Nat.is_eq(Op.hsh_nodup_c(Ty.mk_hsh(0n, 51u64) <>
        C.hsh1(), 9n), 2n),
      f181)
    f183 : U64 <- C.report_pure("pos-so-shl-alias",
      Nat.is_eq(Op.hsh_nodup_c(Op.so_sh_list(C.so_b()),
        9n), 2n),
      f182)
    f184 : U64 <- C.report_pure("pos-qmem-spon",
      Op.vx_surf_on(Ty.ix_mk(C.vs_q(), [], [], [], [], [], []), Ty.mk_hv(0n, 1u64), C.sf_sp()),
      f183)
    f185 : U64 <- C.report_pure("pos-qmem-spoff",
      Bool.not(Op.vx_surf_on(Ty.ix_mk(C.vs_q(), [], [], [], [], [], []), Ty.mk_hv(1n, 2u64), C.sf_sp())),
      f184)
    f186 : U64 <- C.report_pure("pos-qmem-cyon",
      Op.vx_surf_on(Ty.ix_mk(C.vs_q(), [], [], [], [], [], []), Ty.mk_hv(0n, 1u64), C.sf_cy()),
      f185)
    f187 : U64 <- C.report_pure("pos-qmem-cyoff",
      Bool.not(Op.vx_surf_on(Ty.ix_mk(C.vs_q(), [], [], [], [], [], []), Ty.mk_hv(1n, 2u64), C.sf_cy())),
      f186)
    f188 : U64 <- C.report_pure("pos-qmem-con",
      Op.vx_surf_on(Ty.ix_mk(C.vs_q(), [], [], [], [], [], []), Ty.mk_hv(0n, 1u64), C.sf_co()),
      f187)
    f189 : U64 <- C.report_pure("pos-qmem-cooff",
      Bool.not(Op.vx_surf_on(Ty.ix_mk(C.vs_q(), [], [], [], [], [], []), Ty.mk_hv(1n, 2u64), C.sf_co())),
      f188)
    f190 : U64 <- C.report_pure("pos-qmem-toon",
      Op.vx_surf_on(Ty.ix_mk(C.vs_q(), [], [], [], [], [], []), Ty.mk_hv(2n, 3u64), C.sf_to()),
      f189)
    f191 : U64 <- C.report_pure("pos-qmem-tooff",
      Bool.not(Op.vx_surf_on(Ty.ix_mk(C.vs_q(), [], [], [], [], [], []), Ty.mk_hv(0n, 1u64), C.sf_to())),
      f190)
    f192 : U64 <- C.report_pure("pos-conn-split",
      Nat.is_eq(Op.brep_conn_c(C.b_split(), 20n), 2n),
      f191)
    f193 : U64 <- C.report_pure("pos-conn-sphere",
      Nat.is_eq(Op.brep_conn_c(C.b_sphere_digon_control(), 12n), 3n),
      f192)
    return f193

def pos_g10(f193: U64) -> IO(U64):
  do IO<U64>:
    f194 : U64 <- C.report_ok("pos-ck-sphere",
      Op.brep_checked(C.b_sphere_digon_control(), Ty.P_manifold_solid{}, 12n),
      f193)
    f194b : U64 <- C.report_ok("pos-ck-sphere-bound",
      Op.brep_checked(C.b_sphere_digon_control(), Ty.P_manifold_solid{}, 2n),
      f194)
    f195 : U64 <- C.report_ok("pos-ck-cyl",
      Op.brep_checked(C.b_cyl_digon_ruling_control(), Ty.P_manifold_solid{}, 12n),
      f194b)
    f196 : U64 <- C.report_ok("pos-ck-cav",
      Op.brep_checked(C.b_cav(), Ty.P_manifold_solid{}, 20n),
      f195)
    f197 : U64 <- C.report_ok("pos-ck-open",
      Op.brep_checked(C.b_open(), Ty.P_open_shell{}, 12n),
      f196)
    f198 : U64 <- C.report_ok("pos-ck-pole",
      Op.brep_checked(C.b_pole(), Ty.P_manifold_solid{}, 12n),
      f197)
    return f198

def pos_g11(f198: U64) -> IO(U64):
  do IO<U64>:
    f199 : U64 <- C.report_pure("pos-coin-sphere",
      Nat.is_eq(Op.brep_coin_c(C.b_sphere_digon_control(), 12n), 3n), f198)
    f200 : U64 <- C.report_pure("pos-coin-dup",
      Nat.is_eq(Op.brep_coin_c(C.b_coin(), 12n), 2n), f199)
    f201 : U64 <- C.report_pure("pos-coin-fuel",
      Bool.not(Ty.okd_done(Op.brep_coin_c(C.b_sphere_digon_control(), 0n))),
      f200)
    f202 : U64 <- C.report_pure("pos-link-sq",
      Nat.is_eq(Op.vx_link_ok(C.b_oriprop(),
        Ty.mk_hv(0n, 1u64), 20n), 3n),
      f201)
    f203 : U64 <- C.report_pure("pos-link-pinch",
      Nat.is_eq(Op.vx_link_ok(C.b_pinch(),
        Ty.mk_hv(0n, 1u64), 20n), 2n),
      f202)
    f204 : U64 <- C.report_pure("pos-segx-cross",
      Op.segx_pair(C.p000(), C.p110(), C.p100(), C.p010()),
      f203)
    f205 : U64 <- C.report_pure("pos-segx-clean",
      Bool.not(Op.segx_pair(C.p000(), C.p100(), C.p110(),
        C.p010())),
      f204)
    f206 : U64 <- C.report_pure("pos-xing-clean",
      Nat.is_eq(Op.brep_xing_c(C.b_oriprop(), 20n), 3n),
      f205)
    f207 : U64 <- C.report_pure("pos-xing-hit",
      Nat.is_eq(Op.brep_xing_c(C.b_xing(), 20n), 2n), f206)
    f208 : U64 <- C.report_pure("pos-xing-fuel",
      Bool.not(Ty.okd_done(Op.brep_xing_c(C.b_sphere_digon_control(), 0n))),
      f207)
    f209 : U64 <- C.report_pure("pos-orient-sq",
      Nat.is_eq(Op.brep_orient_c(C.b_oriprop(), 20n), 3n),
      f208)
    f210 : U64 <- C.report_pure("pos-orient-invface",
      Nat.is_eq(Op.brep_orient_c(C.b_invface(), 20n), 2n),
      f209)
    f211 : U64 <- C.report_pure("pos-recheck-sphere",
      Nat.is_eq(Op.brep_recheck_c(C.b_sphere_digon_control(), 12n), 3n),
      f210)
    f212 : U64 <- C.report_pure("pos-recheck-oriprop",
      Nat.is_eq(Op.brep_recheck_c(C.b_oriprop(), 20n), 3n),
      f211)
    f213 : U64 <- C.report_pure("pos-recheck-pinch",
      Nat.is_eq(Op.brep_recheck_c(C.b_pinch(), 20n), 3n),
      f212)
    f214 : U64 <- C.report_pure("pos-orient-hole",
      Nat.is_eq(Op.brep_orient_c(C.b_hole(), 20n), 3n),
      f213)
    f215 : U64 <- C.report_pure("pos-orient-hole-bad",
      Nat.is_eq(Op.brep_orient_c(C.b_hole_bad(), 20n), 2n),
      f214)
    f216 : U64 <- C.report_pure("pos-orient-hole-bad2",
      Nat.is_eq(Op.brep_orient_c(C.b_hole_bad2(), 20n), 2n),
      f215)
    f217 : U64 <- C.report_pure("pos-orient-diffparam",
      Nat.is_eq(Op.brep_orient_c(C.b_diffparam(), 20n), 3n),
      f216)
    f218 : U64 <- C.report_pure("pos-recheck-invface",
      Nat.is_eq(Op.brep_recheck_c(C.b_invface(), 20n), 2n),
      f217)
    f219 : U64 <- C.report_pure("pos-recheck-diffparam",
      Nat.is_eq(Op.brep_recheck_c(C.b_diffparam(), 20n), 3n),
      f218)
    f220 : U64 <- C.report_pure("pos-recheck-hole",
      Nat.is_eq(Op.brep_recheck_c(C.b_hole(), 20n), 3n),
      f219)
    f221 : U64 <- C.report_ok("pos-ck-oriprop",
      Op.brep_checked(C.b_oriprop(), Ty.P_manifold_solid{},
        20n),
      f220)
    f222 : U64 <- C.report_ok("pos-ck-hole-open",
      Op.brep_checked(C.b_hole(), Ty.P_open_shell{}, 20n),
      f221)
    f223 : U64 <- C.report_ok("pos-ck-diffparam",
      Op.brep_checked(C.b_diffparam(), Ty.P_manifold_solid{},
        20n),
      f222)
    return f223

def pos_g12(f223: U64) -> IO(U64):
  do IO<U64>:
    f224 : U64 <- C.report_ok("pos-ck-h-seam",
      Op.brep_checked(C.b_h_seam(), Ty.P_manifold_solid{},
        12n),
      f223)
    f225 : U64 <- C.report_ok("pos-ck-h-pole",
      Op.brep_checked(C.b_h_pole(), Ty.P_manifold_solid{},
        12n),
      f224)
    f226 : U64 <- C.report_ok("pos-ck-h-highval",
      Op.brep_checked(C.b_h_highval(), Ty.P_manifold_solid{},
        20n),
      f225)
    f227 : U64 <- C.report_pure("pos-own-loop-clean",
      Nat.is_eq(Op.fas_loop_own_c(Ty.brep_fas(C.b_sphere_digon_control()),
        12n, 12n), 3n),
      f226)
    f228 : U64 <- C.report_pure("pos-own-loop-hit",
      Nat.is_eq(Op.fas_loop_own_c(Ty.brep_fas(C.b_alias_loop()),
        12n, 12n), 2n),
      f227)
    f229 : U64 <- C.report_pure("pos-own-face-clean",
      Nat.is_eq(Op.shs_face_own_c(Ty.brep_shs(C.b_sphere_digon_control()),
        12n, 12n), 3n),
      f228)
    f230 : U64 <- C.report_pure("pos-own-face-hit",
      Nat.is_eq(Op.shs_face_own_c(Ty.brep_shs(C.b_alias_face()),
        12n, 12n), 2n),
      f229)
    f231 : U64 <- C.report_pure("pos-own-solid-clean",
      Nat.is_eq(Op.cp_so_own_c(Ty.brep_top(C.b_sphere_digon_control()), 12n),
        3n),
      f230)
    f232 : U64 <- C.report_pure("pos-own-solid-hit",
      Nat.is_eq(Op.cp_so_own_c(Ty.brep_top(C.b_alias_solid()),
        12n), 2n),
      f231)
    f233 : U64 <- C.report_pure("pos-own-open-loop-hit",
      Nat.is_eq(Op.brep_prof_c(C.b_alias_loop(),
        Ty.P_open_shell{}, 12n), 2n),
      f232)
    f234 : U64 <- C.report_pure("pos-own-open-solid-skip",
      Nat.is_eq(Op.brep_prof_c(C.b_alias_solid(),
        Ty.P_open_shell{}, 12n), 3n),
      f233)
    f235 : U64 <- C.report_pure("pos-link-highval",
      Nat.is_eq(Op.vx_link_ok(C.b_h_highval(),
        Ty.mk_hv(0n, 1u64), 20n), 3n),
      f234)
    f236 : U64 <- C.report_pure("pos-link-seam",
      Nat.is_eq(Op.vx_link_ok(C.b_h_seam(),
        Ty.mk_hv(0n, 1u64), 12n), 3n),
      f235)
    f237 : U64 <- C.report_pure("pos-link-pole",
      Nat.is_eq(Op.vx_link_ok(C.b_h_pole(),
        Ty.mk_hv(0n, 1u64), 12n), 3n),
      f236)
    f238 : U64 <- C.report_pure("pos-link-disc",
      Nat.is_eq(Op.vx_link_ok(C.b_h_disc(),
        Ty.mk_hv(0n, 1u64), 20n), 2n),
      f237)
    return f238

def pos_g13(f238: U64) -> IO(U64):
  do IO<U64>:
    f239 : U64 <- C.report_pure("pos-orient-planecurve",
      Nat.is_eq(Op.brep_orient_c(C.b_planecurve(), 20n), 3n),
      f238)
    f240 : U64 <- C.report_pure("pos-orient-bezskip",
      Nat.is_eq(Op.brep_orient_c(C.b_bezskip(), 20n), 3n),
      f239)
    f241 : U64 <- C.report_pure("pos-orient-spvar",
      Nat.is_eq(Op.brep_orient_c(C.b_spvar(), 20n), 3n),
      f240)
    f242 : U64 <- C.report_pure("pos-recheck-spvar",
      Nat.is_eq(Op.brep_recheck_c(C.b_spvar(), 20n), 3n),
      f241)
    f243 : U64 <- C.report_pure("pos-cert-oriprop",
      Bool.and(Op.cnt_done(Op.brep_orient_cert_c(C.b_oriprop(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_cert_c(C.b_oriprop(), 20n)), 2n)),
      f242)
    f244 : U64 <- C.report_pure("pos-skip-oriprop",
      Bool.and(Op.cnt_done(Op.brep_orient_skip_c(C.b_oriprop(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_skip_c(C.b_oriprop(), 20n)), 0n)),
      f243)
    f245 : U64 <- C.report_pure("pos-cert-invface",
      Bool.and(Op.cnt_done(Op.brep_orient_cert_c(C.b_invface(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_cert_c(C.b_invface(), 20n)), 2n)),
      f244)
    f246 : U64 <- C.report_pure("pos-skip-invface",
      Bool.and(Op.cnt_done(Op.brep_orient_skip_c(C.b_invface(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_skip_c(C.b_invface(), 20n)), 0n)),
      f245)
    f247 : U64 <- C.report_pure("pos-cert-hole",
      Bool.and(Op.cnt_done(Op.brep_orient_cert_c(C.b_hole(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_cert_c(C.b_hole(), 20n)), 2n)),
      f246)
    f248 : U64 <- C.report_pure("pos-skip-hole",
      Bool.and(Op.cnt_done(Op.brep_orient_skip_c(C.b_hole(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_skip_c(C.b_hole(), 20n)), 0n)),
      f247)
    f249 : U64 <- C.report_pure("pos-cert-sphere",
      Bool.and(Op.cnt_done(Op.brep_orient_cert_c(C.b_sphere_digon_control(), 12n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_cert_c(C.b_sphere_digon_control(), 12n)), 0n)),
      f248)
    f250 : U64 <- C.report_pure("pos-skip-sphere",
      Bool.and(Op.cnt_done(Op.brep_orient_skip_c(C.b_sphere_digon_control(), 12n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_skip_c(C.b_sphere_digon_control(), 12n)), 1n)),
      f249)
    f251 : U64 <- C.report_pure("pos-cert-planecurve",
      Bool.and(Op.cnt_done(Op.brep_orient_cert_c(C.b_planecurve(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_cert_c(C.b_planecurve(), 20n)), 0n)),
      f250)
    f252 : U64 <- C.report_pure("pos-skip-planecurve",
      Bool.and(Op.cnt_done(Op.brep_orient_skip_c(C.b_planecurve(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_skip_c(C.b_planecurve(), 20n)), 1n)),
      f251)
    f253 : U64 <- C.report_pure("pos-cert-bezskip",
      Bool.and(Op.cnt_done(Op.brep_orient_cert_c(C.b_bezskip(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_cert_c(C.b_bezskip(), 20n)), 0n)),
      f252)
    f254 : U64 <- C.report_pure("pos-skip-bezskip",
      Bool.and(Op.cnt_done(Op.brep_orient_skip_c(C.b_bezskip(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_skip_c(C.b_bezskip(), 20n)), 1n)),
      f253)
    f255 : U64 <- C.report_pure("pos-cert-spvar",
      Bool.and(Op.cnt_done(Op.brep_orient_cert_c(C.b_spvar(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_cert_c(C.b_spvar(), 20n)), 0n)),
      f254)
    f256 : U64 <- C.report_pure("pos-skip-spvar",
      Bool.and(Op.cnt_done(Op.brep_orient_skip_c(C.b_spvar(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_skip_c(C.b_spvar(), 20n)), 1n)),
      f255)
    f257 : U64 <- C.report_pure("pos-cert-fuel",
      Bool.not(Op.cnt_done(Op.brep_orient_cert_c(C.b_oriprop(), 0n))),
      f256)
    f258 : U64 <- C.report_pure("pos-bezp-ok00",
      G.gres_ok(Op.bezp_normal_at(C.bp0(), 0.0f64, 0.0f64)),
      f257)
    f259 : U64 <- C.report_pure("pos-bezp-ok11",
      G.gres_ok(Op.bezp_normal_at(C.bp0(), 1.0f64, 1.0f64)),
      f258)
    f260 : U64 <- C.report_pure("pos-bezp-z00pos",
      F64.is_lt(0.0f64,
        V.dr_z(G.gres_d(Op.bezp_normal_at(C.bp0(), 0.0f64, 0.0f64)))),
      f259)
    f261 : U64 <- C.report_pure("pos-bezp-z11neg",
      F64.is_lt(V.dr_z(G.gres_d(Op.bezp_normal_at(C.bp0(), 1.0f64, 1.0f64))),
        0.0f64),
      f260)
    f262 : U64 <- C.report_pure("pos-bezp-baduv",
      Bool.not(G.gres_ok(Op.bezp_normal_at(C.bp0(), 2.0f64, 0.5f64))),
      f261)
    return f262

def pos_g14(f262: U64) -> IO(U64):
  do IO<U64>:
    f263 : U64 <- C.report_ok("pos-ck-cyl-side",
      Op.brep_checked(C.b_cyl_side(), Ty.P_manifold_solid{},
        20n),
      f262)
    f264 : U64 <- C.report_ok("pos-ck-sphere-curved",
      Op.brep_checked(C.b_sphere_curved(),
        Ty.P_manifold_solid{}, 20n),
      f263)
    f265 : U64 <- C.report_pure("pos-hdisc-d",
      Nat.is_eq(Op.brep_loop_c(C.b_h_disc(), 20n), 3n),
      f264)
    f266 : U64 <- C.report_pure("pos-hdisc-e",
      Nat.is_eq(Op.brep_facekind_c(C.b_h_disc(), 20n), 3n),
      f265)
    f267 : U64 <- C.report_pure("pos-hdisc-f",
      Nat.is_eq(Op.brep_prof_c(C.b_h_disc(),
        Ty.P_manifold_solid{}, 20n), 3n),
      f266)
    f268 : U64 <- C.report_pure("pos-hdisc-g",
      Nat.is_eq(Op.brep_embed_c(C.b_h_disc(), 20n), 3n),
      f267)
    f269 : U64 <- C.report_pure("pos-hdisc-h",
      Nat.is_eq(Op.brep_link_c(C.b_h_disc(),
        Ty.P_manifold_solid{}, 20n), 2n),
      f268)
    f270 : U64 <- C.report_pure("pos-xing-d",
      Nat.is_eq(Op.brep_loop_c(C.b_xing(), 20n), 3n),
      f269)
    f271 : U64 <- C.report_pure("pos-xing-e",
      Nat.is_eq(Op.brep_facekind_c(C.b_xing(), 20n), 3n),
      f270)
    f272 : U64 <- C.report_pure("pos-xing-f",
      Nat.is_eq(Op.brep_prof_c(C.b_xing(),
        Ty.P_manifold_solid{}, 20n), 3n),
      f271)
    f273 : U64 <- C.report_pure("pos-xing-g",
      Nat.is_eq(Op.brep_embed_c(C.b_xing(), 20n), 3n),
      f272)
    f274 : U64 <- C.report_pure("pos-xing-h",
      Nat.is_eq(Op.brep_link_c(C.b_xing(),
        Ty.P_manifold_solid{}, 20n), 3n),
      f273)
    f275 : U64 <- C.report_pure("pos-xing-i",
      Nat.is_eq(Op.brep_conn_c(C.b_xing(), 20n), 3n),
      f274)
    f276 : U64 <- C.report_pure("pos-xing-j",
      Nat.is_eq(Op.brep_coin_c(C.b_xing(), 20n), 3n),
      f275)
    f277 : U64 <- C.report_pure("pos-cert-cyl-side",
      Bool.and(Op.cnt_done(Op.brep_orient_cert_c(C.b_cyl_side(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_cert_c(C.b_cyl_side(), 20n)), 0n)),
      f276)
    f278 : U64 <- C.report_pure("pos-skip-cyl-side",
      Bool.and(Op.cnt_done(Op.brep_orient_skip_c(C.b_cyl_side(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_skip_c(C.b_cyl_side(), 20n)), 3n)),
      f277)
    f279 : U64 <- C.report_pure("pos-cert-sphere-curved",
      Bool.and(Op.cnt_done(Op.brep_orient_cert_c(C.b_sphere_curved(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_cert_c(C.b_sphere_curved(), 20n)), 0n)),
      f278)
    f280 : U64 <- C.report_pure("pos-skip-sphere-curved",
      Bool.and(Op.cnt_done(Op.brep_orient_skip_c(C.b_sphere_curved(), 20n)),
        Nat.is_eq(Op.cnt_count(Op.brep_orient_skip_c(C.b_sphere_curved(), 20n)), 2n)),
      f279)
    f281 : U64 <- C.report_pure("pos-selfx-d",
      Nat.is_eq(Op.brep_loop_c(C.b_selfx(), 12n), 2n),
      f280)
    f282 : U64 <- C.report_pure("pos-selfx-g",
      Nat.is_eq(Op.brep_embed_c(C.b_selfx(), 12n), 3n),
      f281)
    return f282

def main() -> IO(Unit):
  do IO<Unit>:
    a1 : U64 <- pos_g1(0u64)
    a2 : U64 <- pos_g2(a1)
    a3 : U64 <- pos_g3(a2)
    a4 : U64 <- pos_g4(a3)
    a5 : U64 <- pos_g5(a4)
    a6 : U64 <- pos_g6(a5)
    a7 : U64 <- pos_g7(a6)
    a8 : U64 <- pos_g8(a7)
    a9 : U64 <- pos_g9(a8)
    a10 : U64 <- pos_g10(a9)
    a11 : U64 <- pos_g11(a10)
    a12 : U64 <- pos_g12(a11)
    a13 : U64 <- pos_g13(a12)
    a14 : U64 <- pos_g14(a13)
    IO.print("selfcheck fails=" ++ U64.show(a14))
