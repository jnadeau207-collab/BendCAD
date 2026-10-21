import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S2
import ../../src/c07/sol.bend as SO
import ../../src/c01/types.bend as V
import ../../src/base/par.bend as B
import ../../src/k3/solve.bend as Q

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

def cfree() -> Q.CL:
  Q.CL{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 0.0f64, False{}}

def hz_s(xs: List<&2, F64>) -> String:
  match xs:
    case []: ""
    case +x <> +t: F64.show(x) ++ " " ++ hz_s(t)

def h_of(n: Nat) -> F64:
  match n:
    case 0n: 10.0f64
    case 1n: 8.0f64
    case 2n: 6.349604207872798f64
    case 3n: 5.039684199579493f64
    case _: 4.0f64

def lvl(+fs: List<&2, SO.Fd>, +h: F64) -> String:
  Q.modes_s(fs, h, 200000.0f64, 0.3f64, 7.85e-9f64, cfree(), 10n, 0.0f64)

def run(+src: String, +which: Nat) -> String:
  +cs = M.ev_part(S2.part_of(S2.ps_xs(S2.parse(src))), [])
  lvl(SO.fds_of(M.bd_brep(M.nr_body(M.ce_r(M.ce_find(cs, 1u64))))), h_of(which))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/tmp/zm.bcd")
    IO.print(run(src, List.length(&1, String, args)))
