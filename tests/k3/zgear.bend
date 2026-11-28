import Base
import ../../src/c06/gear.bend as GR
import ../../src/c06/prof.bend as F
import ../../src/c01/types.bend as V

def segn(r: F.Region) -> Nat:
  match r:
    case F.Rg{o, hs}:
      match o:
        case F.L_path{x, y, ss}: List.length(&2, F.Seg, ss)
        case F.L_circ{cx, cy, rr}: 0n

def gr_s(r: GR.Gr, +z: F64) -> String:
  GR.Gr{+ok, +rg, +nf, +dev} = r
  "z=" ++ F64.show(z) ++ " ok=" ++ Bool.pick(String, ok, "1", "0") ++ " segs=" ++ Nat.show(segn(rg)) ++ " arcs-per-flank=" ++ F64.show(nf) ++ " dev=" ++ F64.show(dev) ++ "\n"

def one(+m: F64, +z: F64, +ds: F64, +bore: F64) -> String:
  +g = GR.gp_of(m, z, ds)
  gr_s(GR.gear_rg(g, bore), z)

def ok_s(r: GR.Gr) -> String:
  GR.Gr{+ok, rg, nf, dev} = r
  Bool.pick(String, ok, "1", "0")

def sweep(n: Nat, +m: F64, +z: F64) -> String:
  match n:
    case 0n: ""
    case 1n+(+k): ok_s(GR.gear_rg(GR.gp_of(m, z, 0.0f64), F64.mul(m, 2.0f64))) ++ sweep(k, m, F64.add(z, 1.0f64))

def info(+m: F64, +z: F64) -> String:
  +g = GR.gp_of(m, z, 0.025f64)
  "m=" ++ F64.show(m) ++ " z=" ++ F64.show(z) ++ " fa=" ++ Bool.pick(String, GR.gp_fa(g), "1", "0") ++ " t0=" ++ F64.show(GR.gp_t0(g)) ++ " rho=" ++ F64.show(GR.gp_rho(g)) ++ " " ++ GR.root_s(g) ++ "
"

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(info(1.0f64, 20.0f64) ++ info(1.0f64, 40.0f64) ++ info(1.0f64, 30.0f64) ++ info(1.0f64, 25.0f64) ++ "m=1   z17-41 " ++ sweep(25n, 1.0f64, 17.0f64) ++ "
m=0.5 z17-41 " ++ sweep(25n, 0.5f64, 17.0f64) ++ "
m=2.5 z17-41 " ++ sweep(25n, 2.5f64, 17.0f64) ++ "
m=4 z17-41 " ++ sweep(25n, 4.0f64, 17.0f64) ++ "
" ++ one(1.0f64, 20.0f64, 0.025f64, 4.0f64) ++ one(1.0f64, 40.0f64, 0.025f64, 5.0f64))
