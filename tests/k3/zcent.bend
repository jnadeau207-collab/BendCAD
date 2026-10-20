import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S2
import ../../src/c07/sol.bend as SO
import ../../src/c01/types.bend as V
import ../../src/base/par.bend as B
import ../../src/k3/mesh.bend as K
import ../../src/k3/fem.bend as F
import ../../src/k1/sf.bend as S

law read_go:
  for m: File & Result<&1, &1, (U32 & String), String>
  IO(String)

def read_go(m):
  (f, r) = m
  do IO<String>:
    data : String <- IO.pass(String, r)
    x : Unit <- File.close(f)
    return data

law size_go:
  for m: File & Result<&1, &1, (U32 & String), U32>
  IO(String)

def size_go(m):
  (f, r) = m
  do IO<String>:
    n : U32 <- IO.pass(U32, r)
    d : File & Result<&1, &1, (U32 & String), String> <- File.read(f, U32.add(n, 1))
    read_go(d)

law read_file:
  for path: String
  IO(String)

def read_file(path):
  do IO<String>:
    f : File <- IO.try(File, File.open(path, "r"))
    m : File & Result<&1, &1, (U32 & String), U32> <- File.size(f)
    size_go(m)

def gs_l(+g: K.GS) -> List<&2, Bool>:
  K.GS{ok, +s} = g
  s

def ones(n: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m): 1.0f64 <> ones(m)

def xperp(ps: List<&2, V.Point>) -> List<&2, F64>:
  match ps:
    case []: []
    case +p <> +t: V.pt_x(p) <> V.pt_y(p) <> 0.0f64 <> xperp(t)

def ex(+p: V.Point) -> V.Dir:
  +x = V.pt_x(p)
  +y = V.pt_y(p)
  +z = V.pt_z(p)
  +s2 = F64.add(F64.mul(x, x), F64.mul(y, y))
  +zz = F64.mul(z, z)
  +a = F64.add(4.437639539856528e-05f64, F64.add(F64.mul(F64.neg(1.7943272552588895e-07f64), s2), F64.mul(F64.neg(4.1641934414498755e-07f64), zz)))
  +b = F64.add(F64.neg(4.0938787304310226e-05f64), F64.add(F64.mul(3.656364972980378e-07f64, s2), F64.mul(1.2864987867893924e-07f64, zz)))
  S.dr(F64.mul(x, a), F64.mul(y, a), F64.mul(z, b))

type EX is Data:
  EX{ hi: V.Point, ih: Nat, hv: F64, lo: V.Point, il: Nat, lv: F64 }

def ext_go(ps: List<&2, V.Point>, +ax: Nat, +i: Nat, +e: EX) -> EX:
  match ps:
    case []: e
    case +p <> +t:
      EX{+hp, +ih, +hv, +lp, +il, +lv} = e
      +v = Bool.pick(F64, Nat.is_eq(ax, 0n), V.pt_x(p), V.pt_z(p))
      +up = F64.is_lt(hv, v)
      +dn = F64.is_lt(v, lv)
      ext_go(t, ax, Nat.add(i, 1n), EX{Bool.pick(V.Point, up, p, hp), Bool.pick(Nat, up, i, ih), Bool.pick(F64, up, v, hv), Bool.pick(V.Point, dn, p, lp), Bool.pick(Nat, dn, i, il), Bool.pick(F64, dn, v, lv)})

def ud(+u: B.Tb<&2, F64>, +i: Nat) -> V.Dir:
  +k = U32.from_nat(Nat.mul(3n, i))
  S.dr(B.tb_get(F64, u, k), B.tb_get(F64, u, U32.add(k, 1)), B.tb_get(F64, u, U32.add(k, 2)))

def dia(+e: EX, +u: B.Tb<&2, F64>) -> String:
  EX{+hp, +ih, hv, +lp, +il, lv} = e
  +d = S.psub(hp, lp)
  +n = S.dscale(F64.div(1.0f64, F64.sqrt(S.dot(d, d))), d)
  +fe = S.dot(n, S.dadd(ex(hp), F64.neg(1.0f64), ex(lp)))
  +fh = S.dot(n, S.dadd(ud(u, ih), F64.neg(1.0f64), ud(u, il)))
  F64.show(fh) ++ " exact " ++ F64.show(fe) ++ " rel " ++ F64.show(F64.div(F64.sub(fh, fe), fe))

def big() -> F64:
  1.0e30f64

def ex0() -> EX:
  EX{V.Pt{0.0f64, 0.0f64, 0.0f64}, 0n, F64.neg(big()), V.Pt{0.0f64, 0.0f64, 0.0f64}, 0n, big()}

def hd_l(xs: List<&2, List<&2, F64>>) -> List<&2, F64>:
  match xs:
    case []: []
    case +h <> +t: h

def sv_s(+s: F.SV, +ps: List<&2, V.Point>) -> String:
  F.SV{+x, +rz} = s
  +u = B.tb_of(F64, hd_l(x), 0.0f64)
  " rz=" ++ F64.show(rz) ++ "
equator " ++ dia(ext_go(ps, 0n, 0n, ex0()), u) ++ "
poles " ++ dia(ext_go(ps, 2n, 0n, ex0()), u)

def cent(+es: List<&2, F.EL>, +nn: Nat, +ps: List<&2, V.Point>) -> String:
  +fm = F.fm_of(U32.from_nat(nn), es, 200000.0f64, 0.3f64, 7.85e-9f64)
  +w = F64.mul(S.two_pi(), 1000.0f64)
  +f = F.scale(F64.mul(w, w), F.apply_op(fm, True{}, xperp(ps)))
  " curved=" ++ Nat.show(K.n_ec(es, 0n)) ++ sv_s(F.bsolve_tol(fm, ones(Nat.mul(nn, 3n)), [f], 5000n, 1.0e-10f64), ps)

def tm_go(+t: K.TM) -> String:
  K.TM{+ts, +ps, +nn, +nb, +nf, +dv} = t
  "t10 nodes=" ++ Nat.show(nn) ++ " elems=" ++ Nat.show(List.length(&2, K.T10, ts)) ++ cent(K.fe_els(ts, B.tb_of(V.Point, ps, V.Pt{0.0f64, 0.0f64, 0.0f64}), 1.0e-12f64), nn, ps)

def mr_go(+r: K.MR, +fs: List<&2, SO.Fd>) -> String:
  K.MR{+ok, +nv, +nc, +ns, +ts, +pt} = r
  tm_go(K.t10_of(ts, pt, Nat.add(nv, nc), fs))

def run_gr(+fs: List<&2, SO.Fd>, +gr: K.GR, +ga: K.GS, +gb: K.GS) -> String:
  mr_go(K.mesh_gd(K.gd_of(gr, gs_l(ga), gs_l(gb)), gs_l(ga), gs_l(gb), fs, 1000.0f64), fs)

def run_fs(+fs: List<&2, SO.Fd>, +h: F64) -> String:
  +gr = K.grid_of(SO.bbox(fs, []), h)
  run_gr(fs, gr, K.signs_a(fs, gr), K.signs_b(fs, gr))

def run(+src: String, +h: F64) -> String:
  +cs = M.ev_part(S2.part_of(S2.ps_xs(S2.parse(src))), [])
  run_fs(SO.fds_of(M.bd_brep(M.nr_body(M.ce_r(M.ce_find(cs, 1u64))))), h)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/tmp/zm.bcd")
    IO.print(run(src, F64.div(4.0f64, K.nat_f(List.length(&1, String, args)))))
