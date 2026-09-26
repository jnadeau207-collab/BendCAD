# C04 negative tests: every types.bend failure arm asserts its
# structured kind (invalid-input or resource-exhausted), plus
# brep_checked exit counterexamples (dangling/inverted/trim/
# embedding/nonmanifold/repeated-start/profile/ownership/fuel reject).
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

def b0() -> Ty.Brep:
  Ty.brep_empty()

# Grouped to fit the native backend's arity limit (C02 D2 class).
def neg_g1(f0: U64) -> IO(U64):
  do IO<U64>:
    f1 : U64 <- C.report_terr("neg-vx-nan",
      Ty.mk_vx(C.pnan()), "invalid-input", f0)
    f2 : U64 <- C.report_terr("neg-vx-inf",
      Ty.mk_vx(C.pinf()), "invalid-input", f1)
    f3 : U64 <- C.report_terr("neg-ec-surf",
      Ty.mk_edge_curve(hva(), hvb(), C.sf_pl(), C.dom_01()),
      "invalid-input", f2)
    f4 : U64 <- C.report_terr("neg-ec-trim",
      Ty.mk_edge_curve(hva(), hvb(), C.tr_ts(), C.dom_01()),
      "invalid-input", f3)
    f5 : U64 <- C.report_terr("neg-ec-domflip",
      Ty.mk_edge_curve(hva(), hvb(), C.cv_ln(), C.dom_flip()),
      "invalid-input", f4)
    f6 : U64 <- C.report_terr("neg-ec-domeq",
      Ty.mk_edge_curve(hva(), hvb(), C.cv_ln(), C.dom_eq()),
      "invalid-input", f5)
    f7 : U64 <- C.report_terr("neg-ec-domnan",
      Ty.mk_edge_curve(hva(), hvb(), C.cv_ln(), C.dom_nan()),
      "invalid-input", f6)
    f8 : U64 <- C.report_terr("neg-ec-dominf",
      Ty.mk_edge_curve(hva(), hvb(), C.cv_ln(), C.dom_inf()),
      "invalid-input", f7)
    f9 : U64 <- C.report_terr("neg-ed-degen-idx",
      Ty.mk_edge_degen(hva(), hvb()), "invalid-input", f8)
    f10 : U64 <- C.report_terr("neg-ed-degen-gen",
      Ty.mk_edge_degen(Ty.mk_hv(0n, 1u64),
        Ty.mk_hv(0n, 2u64)),
      "invalid-input", f9)
    f11 : U64 <- C.report_terr("neg-ce-curve",
      Ty.mk_coedge(hea(), True{}, C.cv_ln()),
      "invalid-input", f10)
    f12 : U64 <- C.report_terr("neg-ce-surf",
      Ty.mk_coedge(hea(), False{}, C.sf_cy()),
      "invalid-input", f11)
    f13 : U64 <- C.report_terr("neg-ce-nurb",
      Ty.mk_coedge(hea(), True{}, C.cv_nb()),
      "invalid-input", f12)
    return f13

def neg_g2(f13: U64) -> IO(U64):
  do IO<U64>:
    f14 : U64 <- C.report_terr("neg-lp-nil",
      Ty.mk_loop(C.hc0(), Ty.LK_outer{}), "invalid-input",
      f13)
    f15 : U64 <- C.report_terr("neg-fa-curve",
      Ty.mk_face(C.cv_ln(), C.hlp1(), True{}),
      "invalid-input", f14)
    f16 : U64 <- C.report_terr("neg-fa-trim",
      Ty.mk_face(C.tr_ts(), C.hlp1(), True{}),
      "invalid-input", f15)
    f17 : U64 <- C.report_terr("neg-fa-noloops",
      Ty.mk_face(C.sf_pl(), C.hlp0(), True{}),
      "invalid-input", f16)
    f18 : U64 <- C.report_terr("neg-sh-nil",
      Ty.mk_shell(C.hfa0(), Ty.SK_outer{}), "invalid-input",
      f17)
    f19 : U64 <- C.report_terr("neg-psh-vx-nan",
      Ty.vx_push(b0(), C.pnan()), "invalid-input", f18)
    f20 : U64 <- C.report_terr("neg-psh-ed-arm",
      Ty.ed_push(b0(), hva(), hvb(),
        Ty.EK_curve{C.sf_sp(), C.dom_01()}),
      "invalid-input", f19)
    f21 : U64 <- C.report_terr("neg-psh-ed-degen",
      Ty.ed_push(b0(), hva(), hvb(), Ty.EK_degenerate{}),
      "invalid-input", f20)
    f22 : U64 <- C.report_terr("neg-psh-ce-trim",
      Ty.ce_push(b0(), hea(), True{}, C.cv_bz()),
      "invalid-input", f21)
    f23 : U64 <- C.report_terr("neg-psh-lp-nil",
      Ty.lp_push(b0(), C.hc0(), Ty.LK_outer{}),
      "invalid-input", f22)
    f24 : U64 <- C.report_terr("neg-psh-fa-arm",
      Ty.fa_push(b0(), C.cv_cc(), C.hlp1(), True{}),
      "invalid-input", f23)
    f25 : U64 <- C.report_terr("neg-psh-fa-loops",
      Ty.fa_push(b0(), C.sf_pl(), C.hlp0(), True{}),
      "invalid-input", f24)
    f26 : U64 <- C.report_terr("neg-psh-sh-nil",
      Ty.sh_push(b0(), C.hfa0(), Ty.SK_open{}),
      "invalid-input", f25)
    return f26

def neg_g3(f26: U64) -> IO(U64):
  do IO<U64>:
    f27 : U64 <- C.report_terr("neg-at-vx-oob",
      Ty.vx_at(C.vs1(), 1n, 9n), "invalid-input", f26)
    f28 : U64 <- C.report_terr("neg-at-ed-oob",
      Ty.ed_at(C.es1(), 1n, 9n), "invalid-input", f27)
    f29 : U64 <- C.report_terr("neg-at-ce-oob",
      Ty.ce_at(C.ces1(), 1n, 9n), "invalid-input", f28)
    f30 : U64 <- C.report_terr("neg-at-lp-oob",
      Ty.lp_at(C.lps1(), 1n, 9n), "invalid-input", f29)
    f31 : U64 <- C.report_terr("neg-at-fa-oob",
      Ty.fa_at(C.fas1(), 1n, 9n), "invalid-input", f30)
    f32 : U64 <- C.report_terr("neg-at-sh-oob",
      Ty.sh_at(C.shs1(), 1n, 9n), "invalid-input", f31)
    f33 : U64 <- C.report_terr("neg-at-so-oob",
      Ty.so_at(C.sos1(), 1n, 9n), "invalid-input", f32)
    f34 : U64 <- C.report_terr("neg-res-vx-stale",
      Ty.vx_resolve(C.vs1(), Ty.mk_hv(0n, 99u64), 9n),
      "invalid-input", f33)
    f35 : U64 <- C.report_terr("neg-res-ed-stale",
      Ty.ed_resolve(C.es1(), Ty.mk_he(0n, 99u64), 9n),
      "invalid-input", f34)
    f36 : U64 <- C.report_terr("neg-res-ce-stale",
      Ty.ce_resolve(C.ces1(), Ty.mk_hc(0n, 99u64), 9n),
      "invalid-input", f35)
    f37 : U64 <- C.report_terr("neg-res-lp-stale",
      Ty.lp_resolve(C.lps1(), Ty.mk_hlp(0n, 99u64), 9n),
      "invalid-input", f36)
    f38 : U64 <- C.report_terr("neg-res-fa-stale",
      Ty.fa_resolve(C.fas1(), Ty.mk_hfa(0n, 99u64), 9n),
      "invalid-input", f37)
    f39 : U64 <- C.report_terr("neg-res-sh-stale",
      Ty.sh_resolve(C.shs1(), Ty.mk_hsh(0n, 99u64), 9n),
      "invalid-input", f38)
    f40 : U64 <- C.report_terr("neg-res-so-stale",
      Ty.so_resolve(C.sos1(), Ty.mk_hso(0n, 99u64), 9n),
      "invalid-input", f39)
    f41 : U64 <- C.report_terr("neg-res-vx-oob",
      Ty.vx_resolve(C.vs1(), Ty.mk_hv(5n, 1u64), 9n),
      "invalid-input", f40)
    f42 : U64 <- C.report_terr("neg-res-so-oob",
      Ty.so_resolve(C.sos1(), Ty.mk_hso(5n, 61u64), 9n),
      "invalid-input", f41)
    f43 : U64 <- C.report_terr("neg-hof-vx-unknown",
      Ty.vx_handle_of(C.vs1(), 99u64, 9n), "invalid-input",
      f42)
    f44 : U64 <- C.report_terr("neg-hof-ed-unknown",
      Ty.ed_handle_of(C.es1(), 99u64, 9n), "invalid-input",
      f43)
    f45 : U64 <- C.report_terr("neg-hof-ce-unknown",
      Ty.ce_handle_of(C.ces1(), 99u64, 9n), "invalid-input",
      f44)
    f46 : U64 <- C.report_terr("neg-hof-lp-unknown",
      Ty.lp_handle_of(C.lps1(), 99u64, 9n), "invalid-input",
      f45)
    f47 : U64 <- C.report_terr("neg-hof-fa-unknown",
      Ty.fa_handle_of(C.fas1(), 99u64, 9n), "invalid-input",
      f46)
    f48 : U64 <- C.report_terr("neg-hof-sh-unknown",
      Ty.sh_handle_of(C.shs1(), 99u64, 9n), "invalid-input",
      f47)
    f49 : U64 <- C.report_terr("neg-hof-so-unknown",
      Ty.so_handle_of(C.sos1(), 99u64, 9n), "invalid-input",
      f48)
    f50 : U64 <- C.report_terr("neg-hof-vx-empty",
      Ty.vx_handle_of(C.vs0(), 1u64, 9n), "invalid-input",
      f49)
    f51 : U64 <- C.report_terr("neg-hof-so-empty",
      Ty.so_handle_of(C.sos0(), 61u64, 9n),
      "invalid-input", f50)
    return f51

def neg_g4(f51: U64) -> IO(U64):
  do IO<U64>:
    f52 : U64 <- C.report_terr("neg-len-vx-0",
      Ty.vx_len(C.vs1(), 0n), "resource-exhausted", f51)
    f53 : U64 <- C.report_terr("neg-len-ed-0",
      Ty.ed_len(C.es1(), 0n), "resource-exhausted", f52)
    f54 : U64 <- C.report_terr("neg-len-ce-0",
      Ty.ce_len(C.ces1(), 0n), "resource-exhausted", f53)
    f55 : U64 <- C.report_terr("neg-len-lp-0",
      Ty.lp_len(C.lps1(), 0n), "resource-exhausted", f54)
    f56 : U64 <- C.report_terr("neg-len-fa-0",
      Ty.fa_len(C.fas1(), 0n), "resource-exhausted", f55)
    f57 : U64 <- C.report_terr("neg-len-sh-0",
      Ty.sh_len(C.shs1(), 0n), "resource-exhausted", f56)
    f58 : U64 <- C.report_terr("neg-len-so-0",
      Ty.so_len(C.sos1(), 0n), "resource-exhausted", f57)
    f59 : U64 <- C.report_terr("neg-at-vx-0",
      Ty.vx_at(C.vs2(), 1n, 0n), "resource-exhausted",
      f58)
    f60 : U64 <- C.report_terr("neg-at-ed-0",
      Ty.ed_at(C.es2(), 1n, 0n), "resource-exhausted",
      f59)
    f61 : U64 <- C.report_terr("neg-at-ce-0",
      Ty.ce_at(C.ces2(), 1n, 0n), "resource-exhausted",
      f60)
    f62 : U64 <- C.report_terr("neg-at-lp-0",
      Ty.lp_at(C.lps2(), 1n, 0n), "resource-exhausted",
      f61)
    f63 : U64 <- C.report_terr("neg-at-fa-0",
      Ty.fa_at(C.fas2(), 1n, 0n), "resource-exhausted",
      f62)
    f64 : U64 <- C.report_terr("neg-at-sh-0",
      Ty.sh_at(C.shs2(), 1n, 0n), "resource-exhausted",
      f63)
    f65 : U64 <- C.report_terr("neg-at-so-0",
      Ty.so_at(C.sos2(), 1n, 0n), "resource-exhausted",
      f64)
    f66 : U64 <- C.report_terr("neg-res-vx-0",
      Ty.vx_resolve(C.vs2(), Ty.mk_hv(1n, 2u64), 0n),
      "resource-exhausted", f65)
    f67 : U64 <- C.report_terr("neg-res-ed-0",
      Ty.ed_resolve(C.es2(), Ty.mk_he(1n, 12u64), 0n),
      "resource-exhausted", f66)
    return f67

def neg_g5(f67: U64) -> IO(U64):
  do IO<U64>:
    f68 : U64 <- C.report_terr("neg-hof-vx-0",
      Ty.vx_handle_of(C.vs2(), 2u64, 0n),
      "resource-exhausted", f67)
    f69 : U64 <- C.report_terr("neg-hof-ed-0",
      Ty.ed_handle_of(C.es2(), 12u64, 0n),
      "resource-exhausted", f68)
    f70 : U64 <- C.report_terr("neg-hof-ce-0",
      Ty.ce_handle_of(C.ces2(), 22u64, 0n),
      "resource-exhausted", f69)
    f71 : U64 <- C.report_terr("neg-hof-lp-0",
      Ty.lp_handle_of(C.lps2(), 32u64, 0n),
      "resource-exhausted", f70)
    f72 : U64 <- C.report_terr("neg-hof-fa-0",
      Ty.fa_handle_of(C.fas2(), 42u64, 0n),
      "resource-exhausted", f71)
    f73 : U64 <- C.report_terr("neg-hof-sh-0",
      Ty.sh_handle_of(C.shs2(), 52u64, 0n),
      "resource-exhausted", f72)
    f74 : U64 <- C.report_terr("neg-hof-so-0",
      Ty.so_handle_of(C.sos2(), 62u64, 0n),
      "resource-exhausted", f73)
    f75 : U64 <- C.report_terr("neg-iss-vx-0",
      Ty.vx_issued(C.b_vs1(), 0n), "resource-exhausted",
      f74)
    f76 : U64 <- C.report_terr("neg-iss-ed-0",
      Ty.ed_issued(C.b_es1(), 0n), "resource-exhausted",
      f75)
    f77 : U64 <- C.report_terr("neg-iss-ce-0",
      Ty.ce_issued(C.b_ces1(), 0n), "resource-exhausted",
      f76)
    f78 : U64 <- C.report_terr("neg-iss-lp-0",
      Ty.lp_issued(C.b_lps1(), 0n), "resource-exhausted",
      f77)
    f79 : U64 <- C.report_terr("neg-iss-fa-0",
      Ty.fa_issued(C.b_fas1(), 0n), "resource-exhausted",
      f78)
    f80 : U64 <- C.report_terr("neg-iss-sh-0",
      Ty.sh_issued(C.b_shs1(), 0n), "resource-exhausted",
      f79)
    f81 : U64 <- C.report_terr("neg-iss-so-0",
      Ty.so_issued(C.b_sos1(), 0n), "resource-exhausted",
      f80)
    return f81

def neg_g6(f81: U64) -> IO(U64):
  do IO<U64>:
    f82 : U64 <- C.report_terr("neg-mb-vx",
      Ty.mk_brep(C.vs_bad(), C.es0(), C.ces0(), C.lps0(),
        C.fas0(), C.shs0(), C.sos0(), C.top0(), 1u64, 9n),
      "invalid-input", f81)
    f83 : U64 <- C.report_terr("neg-mb-es-arm",
      Ty.mk_brep(C.vs0(), C.es_badarm(), C.ces0(), C.lps0(),
        C.fas0(), C.shs0(), C.sos0(), C.top0(), 11u64, 9n),
      "invalid-input", f82)
    f84 : U64 <- C.report_terr("neg-mb-es-degen",
      Ty.mk_brep(C.vs0(), C.es_baddegen(), C.ces0(),
        C.lps0(), C.fas0(), C.shs0(), C.sos0(), C.top0(),
        11u64, 9n),
      "invalid-input", f83)
    f85 : U64 <- C.report_terr("neg-mb-ces",
      Ty.mk_brep(C.vs0(), C.es0(), C.ces_bad(), C.lps0(),
        C.fas0(), C.shs0(), C.sos0(), C.top0(), 21u64, 9n),
      "invalid-input", f84)
    f86 : U64 <- C.report_terr("neg-mb-lps",
      Ty.mk_brep(C.vs0(), C.es0(), C.ces0(), C.lps_bad(),
        C.fas0(), C.shs0(), C.sos0(), C.top0(), 31u64, 9n),
      "invalid-input", f85)
    f87 : U64 <- C.report_terr("neg-mb-fas-arm",
      Ty.mk_brep(C.vs0(), C.es0(), C.ces0(), C.lps0(),
        C.fas_badarm(), C.shs0(), C.sos0(), C.top0(), 41u64,
        9n),
      "invalid-input", f86)
    f88 : U64 <- C.report_terr("neg-mb-fas-loops",
      Ty.mk_brep(C.vs0(), C.es0(), C.ces0(), C.lps0(),
        C.fas_badloops(), C.shs0(), C.sos0(), C.top0(),
        41u64, 9n),
      "invalid-input", f87)
    f89 : U64 <- C.report_terr("neg-mb-shs",
      Ty.mk_brep(C.vs0(), C.es0(), C.ces0(), C.lps0(),
        C.fas0(), C.shs_bad(), C.sos0(), C.top0(), 51u64,
        9n),
      "invalid-input", f88)
    f90 : U64 <- C.report_terr("neg-mb-fuel-vs",
      Ty.mk_brep(C.vs1(), C.es0(), C.ces0(), C.lps0(),
        C.fas0(), C.shs0(), C.sos0(), C.top0(), 1u64, 0n),
      "resource-exhausted", f89)
    f91 : U64 <- C.report_terr("neg-mb-fuel-so",
      Ty.mk_brep(C.vs0(), C.es0(), C.ces0(), C.lps0(),
        C.fas0(), C.shs0(), C.sos1(), C.top0(), 61u64, 0n),
      "resource-exhausted", f90)
    f92 : U64 <- C.report_terr("neg-mb-stamp",
      Ty.mk_brep(C.vs1(), C.es0(), C.ces0(), C.lps0(),
        C.fas0(), C.shs0(), C.sos0(), C.top0(), 0u64, 9n),
      "invalid-input", f91)
    f93 : U64 <- C.report_terr("neg-mb-gen0",
      Ty.mk_brep(C.vs_gen0(), C.es0(), C.ces0(), C.lps0(),
        C.fas0(), C.shs0(), C.sos0(), C.top0(), 1u64, 9n),
      "invalid-input", f92)
    f94 : U64 <- C.report_terr("neg-mb-dup",
      Ty.mk_brep(C.vs_dup(), C.es0(), C.ces0(), C.lps0(),
        C.fas0(), C.shs0(), C.sos0(), C.top0(), 1u64, 9n),
      "invalid-input", f93)
    return f94

def neg_g7(f94: U64) -> IO(U64):
  do IO<U64>:
    f95 : U64 <- C.report_terr("neg-ck-dang",
      Op.brep_checked(C.b_dang(), Ty.P_manifold_solid{}, 12n),
      "invalid-input", f94)
    f96 : U64 <- C.report_terr("neg-ck-inv",
      Op.brep_checked(C.b_inv(), Ty.P_manifold_solid{}, 12n),
      "invalid-input", f95)
    f97 : U64 <- C.report_terr("neg-ck-trimx",
      Op.brep_checked(C.b_trimx(), Ty.P_manifold_solid{}, 12n),
      "invalid-input", f96)
    f98 : U64 <- C.report_terr("neg-ck-embx",
      Op.brep_checked(C.b_embx(), Ty.P_manifold_solid{}, 12n),
      "invalid-input", f97)
    f99 : U64 <- C.report_terr("neg-ck-nonm",
      Op.brep_checked(C.b_nonm(), Ty.P_manifold_solid{}, 12n),
      "invalid-input", f98)
    f100 : U64 <- C.report_terr("neg-ck-selfx",
      Op.brep_checked(C.b_selfx(), Ty.P_manifold_solid{}, 12n),
      "invalid-input", f99)
    f101 : U64 <- C.report_terr("neg-ck-open-solid",
      Op.brep_checked(C.b_open(), Ty.P_manifold_solid{}, 12n),
      "invalid-input", f100)
    f102 : U64 <- C.report_terr("neg-ck-fuel",
      Op.brep_checked(C.b_sphere(), Ty.P_manifold_solid{}, 0n),
      "resource-exhausted", f101)
    return f102

def neg_g8(f102: U64) -> IO(U64):
  do IO<U64>:
    f103 : U64 <- C.report_terr("neg-ck-alias",
      Op.brep_checked(C.b_alias(), Ty.P_manifold_solid{}, 12n),
      "invalid-input", f102)
    f104 : U64 <- C.report_terr("neg-ck-outerkind",
      Op.brep_checked(C.b_outerkind(), Ty.P_manifold_solid{}, 12n),
      "invalid-input", f103)
    f105 : U64 <- C.report_terr("neg-ck-cavdup",
      Op.brep_checked(C.b_cavdup(), Ty.P_manifold_solid{}, 20n),
      "invalid-input", f104)
    f106 : U64 <- C.report_terr("neg-ck-reuse",
      Op.brep_checked(C.b_reuse(), Ty.P_manifold_solid{}, 12n),
      "invalid-input", f105)
    f107 : U64 <- C.report_terr("neg-ck-cpshare",
      Op.brep_checked(C.b_cpshare(), Ty.P_manifold_solid{}, 12n),
      "invalid-input", f106)
    return f107

def main() -> IO(Unit):
  do IO<Unit>:
    a1 : U64 <- neg_g1(0u64)
    a2 : U64 <- neg_g2(a1)
    a3 : U64 <- neg_g3(a2)
    a4 : U64 <- neg_g4(a3)
    a5 : U64 <- neg_g5(a4)
    a6 : U64 <- neg_g6(a5)
    a7 : U64 <- neg_g7(a6)
    a8 : U64 <- neg_g8(a7)
    IO.print("selfcheck fails=" ++ U64.show(a8))
