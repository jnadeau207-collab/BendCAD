import Base
import ../../src/c01/types.bend as V
import ../../src/c03/bsp.bend as Q
import ../../src/c06/iv.bend as I
import ../../src/c16/skin.bend as SK
import ../../src/k1/sf.bend as S

def circ_go(n: Nat, +k: Nat, +m: Nat, +r: F64) -> List<&2, V.Vec2>:
  match n:
    case 0n: []
    case 1n+(+j):
      +t = F64.mul(S.two_pi(), F64.div(Q.nf(k), Q.nf(m)))
      V.V2{F64.mul(r, S.fcos(t)), F64.mul(r, S.fsin(t))} <> circ_go(j, Nat.add(k, 1n), m, r)

def fr_z(+z: F64, +tw: F64) -> SK.Fr:
  SK.Fr{V.Pt{0.0f64, 0.0f64, z}, V.Dr{S.fcos(tw), S.fsin(tw), 0.0f64}, V.Dr{F64.neg(S.fsin(tw)), S.fcos(tw), 0.0f64}, 1.0f64}

def circ_sec(+r: F64, +z: F64) -> SK.Sc:
  SK.Sc{([circ_go(37n, 0n, 36n, r)]), fr_z(z, 0.0f64)}

def naca_sec(+z: F64, +tw: F64) -> SK.Sc:
  SK.Sc{(SK.naca_runs(4u64, 4u64, 12u64, 40.0f64, 24n)), fr_z(z, tw)}

def ivs(+a: I.I) -> String:
  "[" ++ F64.show(I.i_lo(a)) ++ "," ++ F64.show(I.i_hi(a)) ++ "]"

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(ivs(SK.skr_vol(SK.sk_run([circ_sec(F64.add(9.0f64, Q.nf(List.length(&1, String, args))), 0.0f64), circ_sec(10.0f64, 20.0f64)], 1u64))))
