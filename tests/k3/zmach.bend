import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c08/bool.bend as B8
import ../../src/k3/mach.bend as K
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

def placed(+b: M.Body) -> Ty.Brep:
  +p = M.bd_pl(b)
  B8.xf_brep(M.pl_m(p), M.pl_tx(p), M.pl_ty(p), M.pl_tz(p), M.bd_brep(b))

def run(+src: String, +na: Nat) -> String:
  +cs = M.ev_part(S.part_of(S.ps_xs(S.parse(src))), [])
  K.machine(placed(M.nr_body(M.ce_r(M.ce_find(cs, 1u64)))), K.TL{1.0f64, 20.0f64, 5.0f64, 40.0f64}, Nat.is_lt(1n, na), 3n)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/tmp/zp.bcd")
    IO.print(run(src, List.length(&1, String, args)))
