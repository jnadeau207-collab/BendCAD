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

def rvec(n: Nat, +i: F64, +j: F64) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m): S.fsin(F64.add(F64.mul(0.7f64, F64.mul(j, i)), F64.mul(0.3f64, i))) <> rvec(m, i, F64.add(j, 1.0f64))

def starts(k: Nat, +n: Nat, +i: F64) -> List<&2, List<&2, F64>>:
  match k:
    case 0n: []
    case 1n+(+m): rvec(n, i, 1.0f64) <> starts(m, n, F64.add(i, 1.0f64))

def hz(xs: List<&2, F64>, +sg: F64) -> String:
  match xs:
    case []: ""
    case +h <> t: F64.show(F64.div(F64.sqrt(F64.max(0.0f64, F64.sub(h, sg))), S.two_pi())) ++ " " ++ hz(t, sg)

def fin(+s: F.SI, +sg: F64) -> String:
  F.SI{+x, +lam, +it, res} = s
  "iters " ++ Nat.show(it) ++ " " ++ hz(lam, sg)

def modal(+es: List<&2, F.EL>, +nn: Nat, +it: Nat) -> String:
  +sg = {1.0e11f64 : F64}
  +fm = F.fm_sig(F.fm_of(U32.from_nat(nn), es, 200000.0f64, 0.3f64, 7.85e-9f64), sg)
  +n = Nat.mul(nn, 3n)
  " curved=" ++ Nat.show(K.n_ec(es, 0n)) ++ "
hz " ++ fin(F.lobpcg(it, fm, ones(n), 16n, 16n, 1.0e-11f64, starts(16n, n, 1.0f64), []), sg)

def tm_go(+t: K.TM, +it: Nat) -> String:
  K.TM{+ts, +ps, +nn, +nb, +nf, +dv, nl} = t
  "t10 nodes=" ++ Nat.show(nn) ++ " elems=" ++ Nat.show(List.length(&2, K.T10, ts)) ++ " projfail=" ++ Nat.show(nf) ++ modal(K.fe_els(ts, B.tb_of(V.Point, ps, V.Pt{0.0f64, 0.0f64, 0.0f64}), 1.0e-12f64), nn, it)

def mr_go(+r: K.MR, +fs: List<&2, SO.Fd>, +it: Nat) -> String:
  K.MR{+ok, +nv, +nc, +ns, +ts, +pt} = r
  tm_go(K.t10_of(ts, pt, Nat.add(nv, nc), fs), it)

def run_gr(+fs: List<&2, SO.Fd>, +gr: K.GR, +ga: K.GS, +gb: K.GS, +it: Nat) -> String:
  mr_go(K.mesh_gd(K.gd_of(gr, gs_l(ga), gs_l(gb)), gs_l(ga), gs_l(gb), fs, 1000.0f64), fs, it)

def run_fs(+fs: List<&2, SO.Fd>, +h: F64, +it: Nat) -> String:
  +gr = K.grid_of(SO.bbox(fs, []), h)
  run_gr(fs, gr, K.signs_a(fs, gr), K.signs_b(fs, gr), it)

def run(+src: String, +h: F64, +it: Nat) -> String:
  +cs = M.ev_part(S2.part_of(S2.ps_xs(S2.parse(src))), [])
  run_fs(SO.fds_of(M.bd_brep(M.nr_body(M.ce_r(M.ce_find(cs, 1u64))))), h, it)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/tmp/zm.bcd")
    IO.print(run(src, F64.div(4.0f64, K.nat_f(List.length(&1, String, args))), 60n))
