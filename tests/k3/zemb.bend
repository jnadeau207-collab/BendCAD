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

def body_of(cs: List<&2, M.CE>, +id: U64) -> M.Body:
  M.nr_body(M.ce_r(M.ce_find(cs, id)))

def fi_s(fs: List<&2, SO.Fi>) -> String:
  match fs:
    case []: ""
    case +f <> +t:
      SO.Fi{+c, +a, +b} = f
      c ++ " " ++ Nat.show(a) ++ " " ++ Nat.show(b) ++ "
" ++ fi_s(t)

def run(+src: String) -> String:
  +cs = M.ev_part(S.part_of(S.ps_xs(S.parse(src))), [])
  +bc = B8.brep_append(M.bd_brep(body_of(cs, 2u64)), M.bd_brep(body_of(cs, 10u64)))
  +fds = SO.fds_of(bc)
  "findings:
" ++ fi_s(EM.emb_fi(bc, fds)) ++ "solid:
" ++ fi_s(SO.solid_fi(bc, fds))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/tmp/zp.bcd")
    IO.print(run(src))
