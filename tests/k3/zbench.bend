import Base
import ../../src/k3/fem.bend as F

def mk(n: Nat, +x: F64) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m): x <> mk(m, F64.add(x, 1.0e-7f64))

def reps(n: Nat, +xs: List<&2, F64>, +ys: List<&2, F64>, +acc: F64) -> F64:
  match n:
    case 0n: acc
    case 1n+(+m): reps(m, xs, ys, F64.add(acc, F.dot_l(xs, ys, 0.0f64)))

def reps_ax(n: Nat, +xs: List<&2, F64>, +ys: List<&2, F64>) -> List<&2, F64>:
  match n:
    case 0n: ys
    case 1n+(+m): reps_ax(m, xs, F.axpy(1.0e-9f64, xs, ys))

def run(+na: Nat) -> String:
  +xs = mk(1000000n, 1.0f64)
  +ys = mk(1000000n, 2.0f64)
  +k = Nat.mul(na, 10n)
  F64.show(Bool.pick(F64, Nat.is_lt(1n, na), F.dot_l(reps_ax(k, xs, ys), xs, 0.0f64), reps(k, xs, ys, 0.0f64)))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(run(List.length(&1, String, args)))
