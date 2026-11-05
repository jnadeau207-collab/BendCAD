import Base
import ../../src/c06/vsrv.bend as VS

def to2(xs: List<&1, String>) -> List<&2, String>:
  match xs:
    case []: []
    case h <> t: h <> to2(t)

def go(+args: List<&2, String>) -> IO(Unit):
  VS.view(8790, VS.v_nth(args, 1n))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(to2(args))
