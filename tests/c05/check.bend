import Base
import ../../src/c00/types.bend as T
import ../../src/c05/arrange.bend as A
import ../../src/c05/solve.bend as S

type Case is Data:
  Case{ tag: String, got: String, want: String }

def verdict(ok: Bool) -> String:
  match ok:
    case True{}: "PASS"
    case False{}: "FAIL"

def report(c: Case, f: U64) -> IO(U64):
  Case{tag, +got, +want} = c
  +ok = String.eq(got, want)
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(ok) ++ " [" ++ got ++ "]")
    return (f + Bool.to_u64(Bool.not(ok)) : U64)

def run_all(cs: List<&2, Case>, f: U64) -> IO(U64):
  match cs:
    case Nil{}:
      do IO<U64>:
        return f
    case h <> t:
      do IO<U64>:
        g : U64 <- report(h, f)
        r : U64 <- run_all(t, g)
        return r

def finish(cs: List<&2, Case>) -> IO(Unit):
  do IO<Unit>:
    n : U64 <- run_all(cs, 0u64)
    IO.print("selfcheck fails=" ++ U64.show(n))

def sq(+id: U64, +x0: F64, +y0: F64, +x1: F64, +y1: F64) -> List<&2, A.Seg>:
  [A.Seg{id, x0, y0, x1, y0}, A.Seg{(id + 1u64 : U64), x1, y0, x1, y1},
   A.Seg{(id + 2u64 : U64), x1, y1, x0, y1}, A.Seg{(id + 3u64 : U64), x0, y1, x0, y0}]

def cat(xs: List<&2, A.Seg>, ys: List<&2, A.Seg>) -> List<&2, A.Seg>:
  List.append(&2, A.Seg, xs, ys)

def rev(xs: List<&2, A.Seg>, acc: List<&2, A.Seg>) -> List<&2, A.Seg>:
  match xs:
    case Nil{}: acc
    case h <> t: rev(t, h <> acc)

def arr(xs: List<&2, A.Seg>, fuel: Nat) -> String:
  A.ares_show(A.arrange(xs, fuel))

def tol() -> T.Tol:
  T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64)

def pt(x: Nat, y: Nat) -> S.Pt:
  S.Pt{x, y}

def sol(ps: List<&2, F64>, fr: List<&2, Bool>, cs: List<&2, S.Cn>, fuel: Nat) -> String:
  S.sol_show(S.solve(ps, fr, cs, tol(), fuel))

def sol_t(ps: List<&2, F64>, fr: List<&2, Bool>, cs: List<&2, S.Cn>, t: T.Tol,
    fuel: Nat) -> String:
  S.sol_show(S.solve(ps, fr, cs, t, fuel))

def ff(n: Nat) -> List<&2, Bool>:
  match n:
    case 0n: []
    case 1n+m: False{} <> ff(m)

def tt(n: Nat) -> List<&2, Bool>:
  match n:
    case 0n: []
    case 1n+m: True{} <> tt(m)

def line_ps() -> List<&2, F64>:
  [0.0f64, 0.0f64, 7.0f64, 3.0f64]

def line_fr() -> List<&2, Bool>:
  [False{}, False{}, True{}, True{}]

def two_ps() -> List<&2, F64>:
  [0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 5.0f64, 8.0f64, 9.0f64]

def two_fr() -> List<&2, Bool>:
  List.append(&2, Bool, ff(6n), tt(2n))
