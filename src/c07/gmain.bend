import Base
import ./gsx.bend as GQ

def args_l(xs: List<String>) -> List<&2, String>:
  match xs:
    case []: []
    case x <> t: x <> args_l(t)

def drop1(xs: List<&2, String>) -> List<&2, String>:
  match xs:
    case []: []
    case x <> t: t

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(GQ.geom(drop1(drop1(args_l(args)))))
