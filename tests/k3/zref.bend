import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c07/sol.bend as SO
import ../../src/c01/types.bend as V
import ../../src/base/par.bend as B
import ../../src/k3/mesh.bend as K
import ../../src/k3/refine.bend as R

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

def jv_s(+j: K.JV) -> String:
  K.JV{+v, +lo, +hi} = j
  " vol10=" ++ F64.show(v) ++ " jratio=[" ++ F64.show(lo) ++ "," ++ F64.show(hi) ++ "]"

def tm_s(+t: K.TM) -> String:
  K.TM{+ts, +ps, +nn, +nb, +nf, +dv, +nl} = t
  "nodes=" ++ Nat.show(nn) ++ " elems=" ++ Nat.show(List.length(&2, K.T10, ts)) ++ " bedges=" ++ Nat.show(nb) ++ " projfail=" ++ Nat.show(nf) ++ " linearized=" ++ Nat.show(nl) ++ " maxmove=" ++ F64.show(dv) ++ jv_s(K.t10_vols(ts, B.tb_of(V.Point, ps, V.Pt{0.0f64, 0.0f64, 0.0f64}), K.JV{0.0f64, 1.0e30f64, F64.neg(1.0e30f64)}))

def fc_s(+f: K.FC) -> String:
  K.FC{+n1, +n2, +bad, bk} = f
  " bfaces=" ++ Nat.show(n1) ++ " ifaces=" ++ Nat.show(n2) ++ " over=" ++ Nat.show(bad)

def ar(fs: List<&2, K.FK>, +pt: B.Tb<&2, V.Point>, +acc: F64) -> F64:
  match fs:
    case []: acc
    case +f <> +r:
      K.FK{+a, +b, +c} = f
      +pa = R.pos(pt, a)
      ar(r, pt, F64.add(acc, F64.mul(0.5f64, K.dlen(K.cross(K.psub(R.pos(pt, b), pa), K.psub(R.pos(pt, c), pa))))))

def fc_bk(+f: K.FC) -> List<&2, K.FK>:
  K.FC{n1, n2, bad, +bk} = f
  bk

def rs_s(+s: R.RS, +fs: List<&2, SO.Fd>) -> String:
  R.RS{+ts, +pt, +n, +r, +ne, +bad, st} = s
  +fc = K.faces(ts)
  "rounds=" ++ Nat.show(r) ++ " new=" ++ Nat.show(ne) ++ " bad=" ++ Nat.show(bad) ++ " tets=" ++ Nat.show(List.length(&2, K.T4, ts)) ++ " vol4=" ++ F64.show(K.vol_sum(ts, pt, 0.0f64)) ++ " area=" ++ F64.show(ar(fc_bk(fc), pt, 0.0f64)) ++ fc_s(fc) ++ "
  " ++ tm_s(K.t10_of(ts, pt, n, fs))

def mr_s(+mr: K.MR, +span: F64, +fs: List<&2, SO.Fd>, +kf: F64, +nr: Nat) -> String:
  K.MR{ok2, +nv, +nc, ns, +ts, +pt} = mr
  rs_s(R.rounds(nr, False{}, fs, kf, span, R.RS{ts, pt, Nat.add(nv, nc), 0n, 0n, 0n, False{}}), fs)

def mo_s(+mo: K.MO, +fs: List<&2, SO.Fd>, +kf: F64, +nr: Nat) -> String:
  K.MO{ok, +mr, +span} = mo
  mr_s(mr, span, fs, kf, nr)

def rt_s(+r: R.RT) -> String:
  R.RT{+tr, +f} = r
  K.TR{+ok, +tm} = tr
  R.rf_s(f) ++ " ok=" ++ Bool.pick(String, ok, "1", "0") ++ " " ++ tm_s(tm)

def br_e(+xs: List<&2, K.FS>, +pt: B.Tb<&2, V.Point>, +i: Nat, +j: Nat) -> Nat:
  +pa = R.pos(pt, i)
  +pb = R.pos(pt, j)
  +tol = F64.mul(1.0e-6f64, K.dlen(K.psub(pb, pa)))
  +ia = K.hits(xs, pa, tol, 0n, [])
  +ib = K.hits(xs, pb, tol, 0n, [])
  Bool.pick(Nat, Bool.and(Bool.not(Bool.or(K.n_nil0(ia), K.n_nil0(ib))), Bool.not(K.meets(ia, ib))), 1n, 0n)

def brs(ks: List<&2, K.FK>, +xs: List<&2, K.FS>, +pt: B.Tb<&2, V.Point>, +acc: Nat) -> Nat:
  match ks:
    case []: acc
    case +k <> +t:
      K.FK{+a, +b, +c} = k
      brs(t, xs, pt, Nat.add(acc, Nat.add(br_e(xs, pt, a, b), Nat.add(br_e(xs, pt, a, c), br_e(xs, pt, b, c)))))

def br_mr(+mr: K.MR, +fs: List<&2, SO.Fd>) -> String:
  K.MR{ok, nv, nc, ns, +ts, +pt} = mr
  " bridges=" ++ Nat.show(brs(fc_bk(K.faces(ts)), K.fs_of(fs), pt, 0n))

def br_mo(+mo: K.MO, +fs: List<&2, SO.Fd>) -> String:
  K.MO{ok, +mr, span} = mo
  br_mr(mr, fs)

def lvl(+fs: List<&2, SO.Fd>, +h: F64, +hc: F64) -> String:
  "h=" ++ F64.show(h) ++ br_mo(K.mo_of(fs, h), fs) ++ " " ++ rt_s(R.tm_ref(fs, h, F64.div(h, hc))) ++ "
"

def run(+src: String, +k: Nat) -> String:
  +cs = M.ev_part(S.part_of(S.ps_xs(S.parse(src))), [])
  +fs = SO.fds_of(M.bd_brep(M.nr_body(M.ce_r(M.ce_find(cs, 1u64)))))
  +h = K.nat_f(k)
  +h1 = F64.div(h, 1.2599210498948732f64)
  lvl(fs, h, h) ++ lvl(fs, h1, h) ++ lvl(fs, F64.div(h1, 1.2599210498948732f64), h)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/tmp/zr.bcd")
    IO.print(run(src, List.length(&1, String, args)))
