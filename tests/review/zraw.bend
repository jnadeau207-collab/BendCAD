import Base
import ../../src/c06/iv.bend as I
import ../../src/c07/rb.bend as R
import ../../src/base/par.bend as B

type C4 is Data:
  C4{ a: I.I, b: I.I, c: I.I, d: I.I }

type F4 is Data:
  F4{ a: F64, b: F64, c: F64, d: F64 }

def fc(+a: F64, +b: F64, +t: F64) -> F64:
  F64.add(a, F64.mul(t, F64.sub(b, a)))

def ev_f(c: F4, +t: F64) -> F64:
  F4{+a, +b, +c2, +d} = c
  +p = fc(a, b, t)
  +q = fc(b, c2, t)
  +r = fc(c2, d, t)
  fc(fc(p, q, t), fc(q, r, t), t)

def ev_r(c: C4, +t: I.I) -> I.I:
  C4{+a, +b, +c2, +d} = c
  +p = R.comb(a, b, t)
  +q = R.comb(b, c2, t)
  +r = R.comb(c2, d, t)
  R.comb(R.comb(p, q, t), R.comb(q, r, t), t)

def ev_l(+cs: List<&2, I.I>, +t: I.I) -> I.I:
  R.blossom(R.reps(3n, t, []), cs)

def loop_f(n: Nat, +c: F4, +t: F64, +acc: F64) -> F64:
  match n:
    case 0n: acc
    case 1n+(+m): loop_f(m, c, F64.add(t, 1.0e-8f64), F64.add(acc, ev_f(c, t)))

def loop_r(n: Nat, +c: C4, +t: F64, +acc: F64) -> F64:
  match n:
    case 0n: acc
    case 1n+(+m): loop_r(m, c, F64.add(t, 1.0e-8f64), F64.add(acc, I.i_lo(ev_r(c, I.ipt(t)))))

def loop_l(n: Nat, +cs: List<&2, I.I>, +t: F64, +acc: F64) -> F64:
  match n:
    case 0n: acc
    case 1n+(+m): loop_l(m, cs, F64.add(t, 1.0e-8f64), F64.add(acc, I.i_lo(ev_l(cs, I.ipt(t)))))

def c4() -> C4:
  C4{I.ipt(1.0f64), I.ipt(2.5f64), I.ipt(0.5f64), I.ipt(3.0f64)}

def cl() -> List<&2, I.I>:
  I.ipt(1.0f64) <> I.ipt(2.5f64) <> I.ipt(0.5f64) <> I.ipt(3.0f64) <> []

def chunk(n: Nat, k: U32) -> F64:
  loop_r(n, c4(), F64.mul(1.0e-3f64, U32.to_f64(k)), 0.0f64)

def sum(xs: List<&2, F64>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case x <> t: sum(t, F64.add(acc, x))

def go3(j: Nat) -> F64:
  match j:
    case 0n: sum(B.pmap_g(~U32, ~Nat, ~F64, ~chunk, 1, 250000n, B.iota_n(64n, 0)), 0.0f64)
    case 1n+i: 0.0f64

def go2(j: Nat) -> F64:
  match j:
    case 0n: loop_l(4000000n, cl(), 0.0f64, 0.0f64)
    case 1n+i: go3(i)

def go1(j: Nat) -> F64:
  match j:
    case 0n: loop_r(4000000n, c4(), 0.0f64, 0.0f64)
    case 1n+i: go2(i)

def go(k: Nat) -> F64:
  match k:
    case 0n: loop_f(4000000n, F4{1.0f64, 2.5f64, 0.5f64, 3.0f64}, 0.0f64, 0.0f64)
    case 1n+j: go1(j)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(F64.show(go(List.length(&1, String, args))))
