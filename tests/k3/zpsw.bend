import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c06/iv.bend as I
import ../../src/c01/types.bend as V
import ../../src/base/par.bend as B

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

def nr_s(r: M.NR) -> String:
  match r:
    case M.NR_err{k, d}:
      M.Dg{+w, +l, +y, +f} = d
      "error " ++ w ++ " @ " ++ l ++ " why: " ++ y
    case M.NR_ok{+b, fx}:
      +v = M.ms_vol(M.body_ms(b))
      "ok volume=[" ++ F64.show(I.i_lo(v)) ++ ", " ++ F64.show(I.i_hi(v)) ++ "]"

def ces_s(cs: List<&2, M.CE>) -> String:
  match cs:
    case []: ""
    case +c <> t:
      M.CE{+id, k, +r} = c
      "node " ++ U64.show(id) ++ ": " ++ nr_s(r) ++ "
" ++ ces_s(t)

def run(+src: String) -> String:
  ces_s(M.ev_part(S.part_of(S.ps_xs(S.parse(src))), []))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/tmp/zp.bcd")
    IO.print(run(src))
