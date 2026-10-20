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
  Q.CL{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 0.0f64}

def go(m: Bool, +fs: List<&2, SO.Fd>) -> String:
  match m:
    case True{}: Q.modes_s(fs, 5.0f64, 200000.0f64, 0.3f64, 7.85e-9f64, cfree(), 3n, 0.0f64)
    case False{}: Q.spin_s(fs, 5.0f64, 200000.0f64, 0.3f64, 7.85e-9f64, cfree(), 6283.185307179586f64)

def run(+src: String, +which: Nat) -> String:
  +cs = M.ev_part(S2.part_of(S2.ps_xs(S2.parse(src))), [])
  go(Nat.is_eq(which, 1n), SO.fds_of(M.bd_brep(M.nr_body(M.ce_r(M.ce_find(cs, 1u64))))))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/tmp/zm.bcd")
    IO.print(run(src, List.length(&1, String, args)))
