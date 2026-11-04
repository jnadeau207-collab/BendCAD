import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c03/bsp.bend as Q
import ../../src/c06/iv.bend as I
import ../../src/c16/skin.bend as SK
import ../../src/c16/skcert.bend as SC
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
  SK.Sc{(SK.naca_runs(4u64, 4u64, 12u64, 40.0f64, 33n)), fr_z(z, tw)}

def ivs(+a: I.I) -> String:
  "[" ++ F64.show(I.i_lo(a)) ++ "," ++ F64.show(I.i_hi(a)) ++ "]"

def cks(+c: SC.Ck) -> String:
  SC.Ck{+ok, +a, +b} = c
  Bool.pick(String, ok, "ok", "FAIL " ++ Nat.show(a) ++ " " ++ Nat.show(b))

def tilt_fr(+z: F64, +a: F64) -> SK.Fr:
  SK.Fr{V.Pt{0.0f64, 0.0f64, z}, V.Dr{S.fcos(a), 0.0f64, S.fsin(a)}, V.Dr{0.0f64, 1.0f64, 0.0f64}, 1.0f64}

def sec_of(+f: SK.Fr, +rs: List<&2, List<&2, V.Vec2>>) -> SK.Sc:
  SK.Sc{(rs), f}

def tilt_sec(+r: F64, +z: F64, +a: F64) -> SK.Sc:
  sec_of(tilt_fr(z, a), [circ_go(37n, 0n, 36n, r)])

def cyl_p(+k: F64) -> SK.SkR:
  SK.sk_run([circ_sec(k, F64.sub(k, 10.0f64)), circ_sec(k, F64.add(k, 10.0f64))], 1u64)

def cone_p(+k: F64) -> SK.SkR:
  SK.sk_run([circ_sec(k, F64.sub(k, 10.0f64)), circ_sec(F64.mul(0.5f64, k), F64.add(k, 10.0f64))], 1u64)

def bl_p(+k: F64) -> SK.SkR:
  SK.sk_run([naca_sec(F64.sub(k, 10.0f64), F64.sub(k, 11.0f64)), naca_sec(F64.sub(k, 0.0f64), F64.mul(0.0157f64, k)), naca_sec(F64.add(k, 10.0f64), F64.mul(0.0314f64, k)), naca_sec(F64.add(k, 20.0f64), F64.mul(0.0471f64, k))], 1u64)

def bad_p(+k: F64) -> SK.SkR:
  SK.sk_run([circ_sec(k, F64.sub(k, 10.0f64)), tilt_sec(k, F64.sub(k, 5.0f64), F64.sub(k, 8.6037366f64))], 1u64)

def show(+c: SK.SkR, +d: SK.SkR, +e: SK.SkR, +f: SK.SkR) -> String:
  "cyl " ++ cks(SK.skr_ck(c)) ++ " cone " ++ cks(SK.skr_ck(d)) ++ " blade " ++ cks(SK.skr_ck(e)) ++ " bad " ++ cks(SK.skr_ck(f)) ++ " areas " ++ ivs(SK.skr_ar(c)) ++ " " ++ ivs(SK.skr_ar(e))

def run(+k: F64) -> String:
  show(cyl_p(k), cone_p(k), bl_p(k), bad_p(k))

def dirs_s(+a: G.BezP, +b: G.BezP) -> String:
  +pa = SC.pts16(a)
  +pb = SC.pts16(b)
  +dc = S.dunit(S.psub(SC.cen(pa, V.Dr{0.0f64, 0.0f64, 0.0f64}, 0.0f64), SC.cen(pb, V.Dr{0.0f64, 0.0f64, 0.0f64}, 0.0f64)))
  "dc " ++ F64.show(V.dr_x(dc)) ++ "," ++ F64.show(V.dr_y(dc)) ++ "," ++ F64.show(V.dr_z(dc)) ++ " amin " ++ F64.show(SC.dmin(pa, dc, SC.inf())) ++ " amax " ++ F64.show(SC.dmax(pa, dc, F64.neg(SC.inf()))) ++
    " bmin " ++ F64.show(SC.dmin(pb, dc, SC.inf())) ++ " bmax " ++ F64.show(SC.dmax(pb, dc, F64.neg(SC.inf()))) ++ " sep " ++ (Bool.pick(String, SC.sep_pp(a, b, 1.0e-8f64), "y", "n")) ++ " rec " ++ (Bool.pick(String, SC.sep_rec(a, b, 3n, 1.0e-8f64), "y", "n"))

def pair_dbg(+k: F64) -> String:
  +g = SK.grid(SK.orient([circ_sec(k, F64.sub(k, 10.0f64)), circ_sec(k, F64.add(k, 10.0f64))]))
  dirs_s(SK.pat(g, 0n, 0n), SK.pat(g, 33n, 0n))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(run(F64.add(9.0f64, Q.nf(List.length(&1, String, args)))))
