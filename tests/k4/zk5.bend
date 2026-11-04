import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c06/build.bend as BD
import ../../src/c03/bsp.bend as Q
import ../../src/c16/skin.bend as SK
import ../../src/k1/sf.bend as S
import ../../src/k1/fb.bend as FB
import ../../src/k1/px.bend as PX
import ../../src/k1/co.bend as CO
import ../../src/k1/gw.bend as W
import ../../src/k1/gb.bend as GB
import ../../src/k1/asm.bend as K1
import ../../src/k1/ss.bend as SS

def fr_z(+z: F64) -> SK.Fr:
  SK.Fr{V.Pt{0.0f64, 0.0f64, z}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}, 1.0f64}

def circ_go(n: Nat, +k: Nat, +m: Nat, +r: F64) -> List<&2, V.Vec2>:
  match n:
    case 0n: []
    case 1n+(+j):
      +t = F64.mul(S.two_pi(), F64.div(Q.nf(k), Q.nf(m)))
      V.V2{F64.mul(r, S.fcos(t)), F64.mul(r, S.fsin(t))} <> circ_go(j, Nat.add(k, 1n), m, r)

def csec(+z: F64) -> SK.Sc:
  SK.Sc{([circ_go(37n, 0n, 36n, 10.0f64)]), fr_z(z)}

def sq() -> List<&2, List<&2, V.Vec2>>:
  +a = {V.V2{F64.neg(15.0f64), F64.neg(15.0f64)} : V.Vec2}
  +b = {V.V2{15.0f64, F64.neg(15.0f64)} : V.Vec2}
  +c = {V.V2{15.0f64, 15.0f64} : V.Vec2}
  +d = {V.V2{F64.neg(15.0f64), 15.0f64} : V.Vec2}
  [[a, b], [b, c], [c, d], [d, a]]

def ssec(+z: F64) -> SK.Sc:
  SK.Sc{(sq()), fr_z(z)}

def bt_b(bt: BD.Bt) -> Ty.Brep:
  BD.Bt{+b, fns} = bt
  b

def brep(+cs: List<&2, SK.Sc>) -> Ty.Brep:
  bt_b(SK.skr_bt(SK.sk_run(cs, 1u64)))

def vinfo(+ra: Ty.Brep, +rb: Ty.Brep, +v: Nat) -> String:
  +va = PX.add_vs(Ty.brep_vs(ra), PX.GV{[], 0n}, [])
  +vb = PX.add_vs(Ty.brep_vs(rb), PX.vm_g(va), [])
  +hs = PX.all_hits(FB.kb_of(ra), FB.kb_of(rb), PX.vm_g(vb))
  +cr = PX.all_chains(PX.hs_hs(hs), FB.kb_of(ra), FB.kb_of(rb), PX.hs_g(hs))
  +p = PX.gv_pt(PX.cr_g(cr), v)
  " v" ++ Nat.show(v) ++ "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

def runk(+op: U64, +k: F64) -> String:
  +ra = brep([csec(F64.sub(k, 10.0f64)), csec(F64.add(k, 10.0f64))])
  +rb = brep([ssec(F64.sub(k, 15.0f64)), ssec(F64.sub(k, 5.0f64))])
  +kr = GB.gbrun(op, ra, rb)
  "op " ++ U64.show(op) ++ " ok " ++ (Bool.pick(String, K1.kr_ok(kr), "y", "n")) ++ " why " ++ U64.show(K1.kr_why(kr)) ++ vinfo(ra, rb, U64.to_nat(U64.mod(U64.div(K1.kr_why(kr), 1000u64), 10000u64))) ++ vinfo(ra, rb, U64.to_nat(U64.div(K1.kr_why(kr), 10000000u64))) ++ "; "

def both(+k: F64) -> String:
  runk(14u64, k) ++ runk(16u64, k)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(both(F64.add(9.0f64, Q.nf(List.length(&1, String, args)))))
