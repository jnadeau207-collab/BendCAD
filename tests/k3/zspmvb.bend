import Base
import ../../src/c01/types.bend as V
import ../../src/k1/sf.bend as S
import ../../src/k3/fem.bend as F
import ../../src/base/par.bend as B

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
  F.SI{+x, +lam} = s
  hz(lam)

def ns_ps(ns: List<&2, U32>, +pt: B.Tb<&2, V.Point>) -> List<&2, V.Point>:
  match ns:
    case []: []
    case +n <> +t: B.tb_get(V.Point, pt, n) <> ns_ps(t, pt)

def to_ec(es: List<&2, F.EL>, +pt: B.Tb<&2, V.Point>) -> List<&2, F.EL>:
  match es:
    case []: []
    case +e <> +t: F.EC{F.el_ns(e), ns_ps(F.el_ns(e), pt)} <> to_ec(t, pt)

def nrm(+xs: List<&2, F64>) -> F64:
  F64.sqrt(F.dot_l(xs, xs, 0.0f64))

def rel(+a: List<&2, F64>, +b: List<&2, F64>) -> String:
  F64.show(F64.div(nrm(F.axpy(F64.neg(1.0f64), a, b)), nrm(a)))

def kcopy(n: Nat, +x: V.Dir) -> List<&2, V.Dir>:
  match n:
    case 0n: []
    case 1n+(+m): x <> kcopy(m, x)

def nodes_k(xs: List<&2, V.Dir>, +k: Nat) -> List<&2, List<&2, V.Dir>>:
  match xs:
    case []: []
    case +x <> +t: kcopy(k, x) <> nodes_k(t, k)

def breps(n: Nat, +rows: List<&2, List<&2, F.BE>>, +x: List<&2, List<&2, V.Dir>>) -> List<&2, List<&2, V.Dir>>:
  match n:
    case 0n: x
    case 1n+(+m): breps(m, rows, F.bspmv(rows, 1.0e-6f64, 0.0f64, x))

def bnorm(xs: List<&2, List<&2, V.Dir>>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> +t: bnorm(t, F64.add(acc, nrm(F.flat(x))))

def runb(+mh: F.MH, +it: Nat, +k: Nat) -> String:
  F.MH{+nn, +es0, +xs} = mh
  +rows = F.assemble(es0, 115384.61538461538f64, 76923.07692307692f64)
  +x = F.trip(rvec(Nat.mul(U32.to_nat(nn), 3n), 1.0f64, 1.0f64))
  F64.show(bnorm(breps(it, rows, nodes_k(x, k)), 0.0f64))

def reps(n: Nat, +fm: F.FM, +x: List<&2, F64>) -> List<&2, F64>:
  match n:
    case 0n: x
    case 1n+(+m): reps(m, fm, F.scale(1.0e-6f64, F.apply_op(fm, False{}, x)))

def run(+mh: F.MH, +it: Nat) -> String:
  F.MH{+nn, +es0, +xs} = mh
  +f0 = F.fm_of(nn, es0, 200000.0f64, 0.3f64, 7.85e-9f64)
  +x = rvec(Nat.mul(U32.to_nat(nn), 3n), 1.0f64, 1.0f64)
  F64.show(nrm(reps(it, f0, x)))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(runb(F.box_mesh(100.0f64, 10.0f64, 10.0f64, 20n, 2n, 2n), 100n, List.length(&1, String, args)))
