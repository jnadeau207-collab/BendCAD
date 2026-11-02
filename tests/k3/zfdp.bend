import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c07/sol.bend as SO
import ../../src/c07/emb.bend as EM
import ../../src/c08/bool.bend as B8
import ../../src/c04/types.bend as Ty
import ../../src/base/par.bend as B
import ../../src/c07/mem.bend as Mm
import ../../src/c07/rb.bend as R
import ../../src/c07/ivx.bend as X
import ../../src/c06/iv.bend as I

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

def placed(+cs: List<&2, M.CE>, +id: U64) -> Ty.Brep:
  +b = M.nr_body(M.ce_r(M.ce_find(cs, id)))
  +pl = M.bd_pl(b)
  B8.xf_brep(M.pl_m(pl), M.pl_tx(pl), M.pl_ty(pl), M.pl_tz(pl), M.bd_brep(b))

def tm(+tag: String, +t0: Nat, +t1: Nat) -> IO(Unit):
  IO.print(tag ++ " " ++ Nat.show(Nat.sub(t1, t0)))

type FR is Data:
  FR{ v: F64 }

def ers_sum(es: List<&2, Mm.Er>, +acc: F64) -> F64:
  match es:
    case []: acc
    case +e <> t: ers_sum(t, F64.add(acc, I.i_lo(X.vn(R.cv_hbox(Mm.er_c(e)), 0n))))

def er_job(+x: Ty.Ix, j: SO.FJ) -> FR:
  SO.FJ{+h, +sh} = j
  +f = Ty.tres_fa(Ty.ix_fa(x, h))
  FR{ers_sum(SO.ea_es(SO.lps_go(Ty.fa_loops(f), x, SO.Ea{[], True{}})), 0.0f64)}

def er_x(x: Ty.Ix, j: SO.FJ) -> FR:
  er_job(x, j)

def fd_job(+x: Ty.Ix, j: SO.FJ) -> FR:
  SO.FJ{+h, +sh} = j
  +d = SO.fd_x(x, h, sh)
  FR{F64.add(I.i_lo(X.vn(SO.fd_bx(d), 0n)), I.i_hi(X.vn(SO.fd_bx(d), 2n)))}

def fd_xx(x: Ty.Ix, j: SO.FJ) -> FR:
  fd_job(x, j)

def fr_sum(xs: List<&2, FR>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> t:
      FR{+v} = x
      fr_sum(t, F64.add(acc, v))

def k1(+b: Ty.Brep) -> IO(Unit):
  +x = Ty.ix_of(b)
  +js = SO.fj_shs(Ty.brep_shs(b), 0n)
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("ers " ++ F64.show(fr_sum(B.pmap_g(~SO.FJ, ~Ty.Ix, ~FR, ~er_x, 1, x, js), 0.0f64)))
    t1 : Nat <- IO.now()
    v : Unit <- tm("edge_records", t0, t1)
    t2 : Nat <- IO.now()
    w : Unit <- IO.print("fds " ++ F64.show(fr_sum(B.pmap_g(~SO.FJ, ~Ty.Ix, ~FR, ~fd_xx, 1, x, js), 0.0f64)))
    t3 : Nat <- IO.now()
    tm("full_fd_box", t2, t3)

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +id = S.u64_of(S.Sx_a{S.arg_at(args, 2n)})
  k1(placed(M.ev_for(p, [id], []), id))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
