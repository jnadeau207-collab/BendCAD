import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c07/sol.bend as SO
import ../../src/c01/types.bend as V
import ../../src/base/par.bend as B
import ../../src/k3/mesh.bend as K

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

def gs_s(+g: K.GS, +h: F64) -> String:
  K.GS{+ok, +s} = g
  +n = K.n_in(s, 0n)
  "ok=" ++ Bool.pick(String, ok, "1", "0") ++ " in=" ++ Nat.show(n) ++ " vol~" ++ F64.show(F64.mul(K.nat_f(n), F64.mul(h, F64.mul(h, h))))

def dims(+gr: K.GR) -> String:
  K.GR{gx, gy, gz, gh, +nx, +ny, +nz} = gr
  Nat.show(nx) ++ "x" ++ Nat.show(ny) ++ "x" ++ Nat.show(nz)

def gs_s2(+g: K.GS) -> List<&2, Bool>:
  K.GS{ok, +s} = g
  s

def gs_ok(+g: K.GS) -> Bool:
  K.GS{+ok, s} = g
  ok

def rdev(+pt: B.Tb<&2, V.Point>, +v: Nat) -> F64:
  +p = B.tb_get(V.Point, pt, U32.from_nat(v))
  F64.abs(F64.sub(F64.sqrt(F64.add(F64.add(F64.mul(V.pt_x(p), V.pt_x(p)), F64.mul(V.pt_y(p), V.pt_y(p))), F64.mul(V.pt_z(p), V.pt_z(p)))), 10.0f64))

def bdev(ks: List<&2, K.FK>, +pt: B.Tb<&2, V.Point>, +acc: F64) -> F64:
  match ks:
    case []: acc
    case +k <> t:
      K.FK{+a, +b, +c} = k
      bdev(t, pt, F64.max(acc, F64.max(rdev(pt, a), F64.max(rdev(pt, b), rdev(pt, c)))))

def fc_s(+f: K.FC, +pt: B.Tb<&2, V.Point>) -> String:
  K.FC{+n1, +n2, +bad, +bk} = f
  " bfaces=" ++ Nat.show(n1) ++ " ifaces=" ++ Nat.show(n2) ++ " over=" ++ Nat.show(bad) ++ " bdev=" ++ F64.show(bdev(bk, pt, 0.0f64))

def qd_s(+q: K.QD) -> String:
  K.QD{+lo, +hi, +nd} = q
  " cosdih=[" ++ F64.show(lo) ++ "," ++ F64.show(hi) ++ "] degen=" ++ Nat.show(nd)

def jv_s(+j: K.JV) -> String:
  K.JV{+v, +lo, +hi} = j
  " vol10=" ++ F64.show(v) ++ " jratio=[" ++ F64.show(lo) ++ "," ++ F64.show(hi) ++ "]"

def tm_s(+t: K.TM) -> String:
  K.TM{+ts, +ps, +nn, +nb, +nf, +dv} = t
  "t10 nodes=" ++ Nat.show(nn) ++ " elems=" ++ Nat.show(List.length(&2, K.T10, ts)) ++ " bedges=" ++ Nat.show(nb) ++ " projfail=" ++ Nat.show(nf) ++ " maxmove=" ++ F64.show(dv) ++ jv_s(K.t10_vols(ts, B.tb_of(V.Point, ps, V.Pt{0.0f64, 0.0f64, 0.0f64}), K.JV{0.0f64, 1.0e30f64, F64.neg(1.0e30f64)}))

def mr_s(+r: K.MR, +fs: List<&2, SO.Fd>) -> String:
  K.MR{+ok, +nv, +nc, +ns, +ts, +pt} = r
  tm_s(K.t10_of(ts, pt, Nat.add(nv, nc), fs)) ++ "
ok=" ++ Bool.pick(String, ok, "1", "0") ++ " nv=" ++ Nat.show(nv) ++ " cuts=" ++ Nat.show(nc) ++ " snaps=" ++ Nat.show(ns) ++ " tets=" ++ Nat.show(List.length(&2, K.T4, ts)) ++ " vol=" ++ F64.show(K.vol_sum(ts, pt, 0.0f64)) ++ fc_s(K.faces(ts), pt) ++ qd_s(K.quality(ts, pt, 1.0e-9f64, K.QD{1.0f64, F64.neg(1.0f64), 0n}))

def run_gr(+fs: List<&2, SO.Fd>, +gr: K.GR, +ga: K.GS, +gb: K.GS) -> String:
  "grid " ++ dims(gr) ++ " signs=" ++ Bool.pick(String, Bool.and(gs_ok(ga), gs_ok(gb)), "1", "0") ++ " " ++ mr_s(K.mesh_gd(K.gd_of(gr, gs_s2(ga), gs_s2(gb)), gs_s2(ga), gs_s2(gb), fs, 1000.0f64), fs)

def run_fs(+fs: List<&2, SO.Fd>, +h: F64) -> String:
  +gr = K.grid_of(SO.bbox(fs, []), h)
  run_gr(fs, gr, K.signs_a(fs, gr), K.signs_b(fs, gr))

def run(+src: String, +h: F64) -> String:
  +cs = M.ev_part(S.part_of(S.ps_xs(S.parse(src))), [])
  run_fs(SO.fds_of(M.bd_brep(M.nr_body(M.ce_r(M.ce_find(cs, 1u64))))), h)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/tmp/zm.bcd")
    IO.print(run(src, F64.div(1.0f64, K.nat_f(List.length(&1, String, args)))))
