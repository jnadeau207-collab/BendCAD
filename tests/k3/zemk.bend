import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c07/sol.bend as SO
import ../../src/c07/emb.bend as EM
import ../../src/c08/bool.bend as B8
import ../../src/c04/types.bend as Ty

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

def only(ps: List<&2, EM.Pr>, +k: U64) -> List<&2, EM.Pr>:
  match ps:
    case []: []
    case +p <> +t:
      EM.Pr{+pk, +a, +b} = p
      +rest = only(t, k)
      Bool.pick(List<&2, EM.Pr>, U64.is_eq(pk, k), p <> rest, rest)

def kind(+cx: EM.Cx, +ps: List<&2, EM.Pr>, +k: U64, +tag: String) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print(tag ++ " pairs " ++ Nat.show(List.length(&2, EM.Pr, only(ps, k))) ++ " fi " ++ Nat.show(List.length(&2, SO.Fi, EM.run_prs(cx, only(ps, k)))))
    t1 : Nat <- IO.now()
    tm(tag, t0, t1)

def k3(+cx: EM.Cx, +ps: List<&2, EM.Pr>) -> IO(Unit):
  do IO<Unit>:
    u : Unit <- kind(cx, ps, 0u64, "ee")
    v : Unit <- kind(cx, ps, 1u64, "ef")
    kind(cx, ps, 2u64, "ff")

def k2(+b: Ty.Brep, +fds: List<&2, SO.Fd>) -> IO(Unit):
  +x = Ty.ix_of(b)
  +egs = EM.egs_go(Ty.brep_es(b), Ty.ix_tv(x))
  +fgs = EM.shs_fg(Ty.brep_shs(b), x, fds, Ty.shmap_of(b), 0n)
  +cx = EM.mk_cx(egs, fgs, EM.tol_of(SO.bbox(fds, [])), List.length(&2, Ty.Solid, Ty.brep_sos(b)))
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("sweep pairs " ++ Nat.show(List.length(&2, EM.Pr, EM.sweep(EM.its_of(egs, fgs)))))
    t1 : Nat <- IO.now()
    v : Unit <- tm("sweep", t0, t1)
    k3(cx, EM.sweep(EM.its_of(egs, fgs)))

def k1(+b: Ty.Brep) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("fds " ++ Nat.show(List.length(&2, SO.Fd, SO.fds_of(b))))
    t1 : Nat <- IO.now()
    v : Unit <- tm("fds_of", t0, t1)
    k2(b, SO.fds_of(b))

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
