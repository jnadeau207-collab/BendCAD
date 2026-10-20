import Base
import ../../src/c01/types.bend as V
import ../../src/k1/sf.bend as S
import ../../src/k3/fem.bend as F

def mask_of(xs: List<&2, V.Point>) -> List<&2, F64>:
  match xs:
    case []: []
    case +p <> +t:
      +m = Bool.pick(F64, F64.is_lt(V.pt_x(p), 1.0e-9f64), 0.0f64, 1.0f64)
      m <> m <> m <> mask_of(t)

def gvec(xs: List<&2, V.Point>) -> List<&2, F64>:
  match xs:
    case []: []
    case +p <> +t: 0.0f64 <> 0.0f64 <> F64.neg(1.0f64) <> gvec(t)

def tip(xs: List<&2, V.Point>, us: List<&2, F64>, +s: F64, +n: F64) -> F64:
  match xs:
    case []: F64.div(s, n)
    case +p <> +t:
      match us:
        case []: F64.div(s, n)
        case +ux <> +r1:
          match r1:
            case []: F64.div(s, n)
            case +uy <> +r2:
              match r2:
                case []: F64.div(s, n)
                case +uz <> +r3:
                  +at = F64.is_lt(99.999999f64, V.pt_x(p))
                  tip(t, r3, Bool.pick(F64, at, F64.add(s, uz), s), Bool.pick(F64, at, F64.add(n, 1.0f64), n))

def rvec(n: Nat, +i: F64, +j: F64) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m: S.fsin(F64.add(F64.mul(0.7f64, F64.mul(j, i)), F64.mul(0.3f64, i))) <> rvec(m, i, F64.add(j, 1.0f64))

def starts(k: Nat, +n: Nat, +i: F64) -> List<&2, List<&2, F64>>:
  match k:
    case 0n: []
    case 1n+m: rvec(n, i, 1.0f64) <> starts(m, n, F64.add(i, 1.0f64))

def hz(xs: List<&2, F64>) -> String:
  match xs:
    case []: ""
    case +h <> +t: F64.show(F64.div(F64.sqrt(h), S.two_pi())) ++ " " ++ hz(t)

def fin(+s: F.SI) -> String:
  F.SI{+x, +lam, it} = s
  hz(lam)

def run(+mh: F.MH, +it: Nat) -> String:
  F.MH{+nn, +es, +xs} = mh
  +fm = F.fm_of(nn, es, 200000.0f64, 0.3f64, 7.85e-9f64)
  +mask = mask_of(xs)
  +n = Nat.mul(U32.to_nat(nn), 3n)
  "nodes " ++ U32.show(nn) ++ " hz " ++ fin(F.lobpcg(it, fm, mask, 6n, 6n, 0.0f64, starts(6n, n, 1.0f64)))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(run(F.box_mesh(100.0f64, 10.0f64, 10.0f64, 20n, 2n, 2n), U64.to_nat(U64.from_nat(List.length(&1, String, args)))))
