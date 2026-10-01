import Base
import ../../../src/c00/types.bend as T
import ../../../src/c01/types.bend as V
import ../../../src/c03/types.bend as G
import ../../../src/c04/types.bend as Ty
import ../../../src/c04/ops.bend as Op
import ./ref/ops.bend as R

def l1_v0() -> Ty.HVertex:
  Ty.mk_hv(0n, 1u64)


def l1_v1() -> Ty.HVertex:
  Ty.mk_hv(1n, 2u64)


def l1_v2() -> Ty.HVertex:
  Ty.mk_hv(2n, 3u64)


def l1_he0() -> Ty.HEdge:
  Ty.mk_he(0n, 4u64)


def l1_he1() -> Ty.HEdge:
  Ty.mk_he(1n, 5u64)


def l1_hc0() -> Ty.HCoedge:
  Ty.mk_hc(0n, 6u64)


def l1_hc1() -> Ty.HCoedge:
  Ty.mk_hc(1n, 7u64)


def l1_p0() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}


def l1_p1() -> V.Point:
  V.Pt{1.0f64, 0.0f64, 0.0f64}


def l1_d0() -> V.Dir:
  V.Dr{1.0f64, 0.0f64, 0.0f64}


def l1_ln() -> G.GVal:
  G.GV_ln{G.Ln{l1_p0(), l1_d0()}}


def l1_dom() -> G.Dom:
  G.Dom{0.0f64, 1.0f64}


def l1_rho_x() -> Ty.HCoedge:
  Ty.mk_hc(4n, 23u64)


def l1_b_rho() -> Ty.Brep:
  Ty.Br{Ty.Vx{1u64, l1_p0()} <> Ty.Vx{2u64, l1_p1()} <>
      Ty.Vx{3u64, V.Pt{0.0f64, 1.0f64, 0.0f64}} <> Nil{},
    Ty.Ed{4u64, l1_v0(), l1_v1(), Ty.EK_curve{l1_ln(), l1_dom()}} <>
      Ty.Ed{5u64, l1_v1(), l1_v0(), Ty.EK_curve{l1_ln(), l1_dom()}} <>
      Ty.Ed{22u64, l1_v2(), l1_v0(), Ty.EK_curve{l1_ln(), l1_dom()}} <>
      Nil{},
    Ty.Ce{6u64, l1_he0(), True{}, Ty.trim_zero()} <>
      Ty.Ce{7u64, l1_he1(), True{}, Ty.trim_zero()} <>
      Ty.Ce{20u64, l1_he0(), False{}, Ty.trim_zero()} <>
      Ty.Ce{21u64, l1_he0(), True{}, Ty.trim_zero()} <>
      Ty.Ce{23u64, Ty.mk_he(2n, 22u64), True{}, Ty.trim_zero()} <> Nil{},
    Ty.Lp{8u64, l1_hc0() <> l1_hc1() <> Nil{}, Ty.LK_outer{}} <>
      Ty.Lp{9u64, Ty.mk_hc(2n, 20u64) <> Nil{}, Ty.LK_outer{}} <>
      Ty.Lp{30u64, l1_rho_x() <> Ty.mk_hc(3n, 21u64) <> Nil{},
        Ty.LK_outer{}} <> Nil{},
    Nil{}, Nil{}, Nil{}, Ty.Cp{Nil{}, Nil{}}, 12u64}


def main() -> String:
  "old vx_link_ok(rho, v2, fuel 20) = " ++ Nat.show(R.vx_link_ok(l1_b_rho(), l1_v2(), 20n, 20n))
  ++ " (fuel 2000: " ++ Nat.show(R.vx_link_ok(l1_b_rho(), l1_v2(), 2000n, 2000n))
  ++ "); new = " ++ Nat.show(Op.vx_link_ok(l1_b_rho(), l1_v2(), 20n))
