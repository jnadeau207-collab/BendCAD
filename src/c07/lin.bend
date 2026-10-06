import Base
import ../c00/types.bend as T

def fnth(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: F64.nan()
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: fnth(t, j)

def rnth(rs: List<&2, List<&2, F64>>, +i: Nat) -> List<&2, F64>:
  match rs:
    case []: []
    case r <> t:
      match i:
        case 0n: r
        case 1n+j: rnth(t, j)

def rscale(r: List<&2, F64>, +s: F64) -> List<&2, F64>:
  match r:
    case []: []
    case x <> t: F64.mul(x, s) <> rscale(t, s)

def raxpy(r: List<&2, F64>, +s: F64, p: List<&2, F64>) -> List<&2, F64>:
  match r:
    case []: []
    case x <> t:
      match p:
        case []: []
        case y <> u: F64.sub(x, F64.mul(s, y)) <> raxpy(t, s, u)

def unit_row(n: Nat, +i: Nat, +j: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m: Bool.pick(F64, Nat.is_eq(i, j), 1.0f64, 0.0f64) <> unit_row(m, i, Nat.add(j, 1n))

def augment(rs: List<&2, List<&2, F64>>, +n: Nat, +i: Nat) -> List<&2, List<&2, F64>>:
  match rs:
    case []: []
    case r <> t: List.append(&2, F64, r, unit_row(n, i, 0n)) <> augment(t, n, Nat.add(i, 1n))

def piv_go(rs: List<&2, List<&2, F64>>, +k: Nat, +i: Nat, +best: Nat, +bv: F64) -> Nat:
  match rs:
    case []: best
    case r <> t:
      +a = F64.abs(fnth(r, k))
      +take = Bool.and(Nat.is_le(k, i), F64.is_lt(bv, a))
      piv_go(t, k, Nat.add(i, 1n), Bool.pick(Nat, take, i, best), Bool.pick(F64, take, a, bv))

def swap_go(rs: List<&2, List<&2, F64>>, +a: Nat, +b: Nat, +ra: List<&2, F64>, +rb: List<&2, F64>, +i: Nat) -> List<&2, List<&2, F64>>:
  match rs:
    case []: []
    case r <> t: Bool.pick(List<&2, F64>, Nat.is_eq(i, a), rb, Bool.pick(List<&2, F64>, Nat.is_eq(i, b), ra, r)) <> swap_go(t, a, b, ra, rb, Nat.add(i, 1n))

def swap(+rs: List<&2, List<&2, F64>>, +a: Nat, +b: Nat) -> List<&2, List<&2, F64>>:
  swap_go(rs, a, b, rnth(rs, a), rnth(rs, b), 0n)

def elim_go(rs: List<&2, List<&2, F64>>, +k: Nat, +pr: List<&2, F64>, +i: Nat) -> List<&2, List<&2, F64>>:
  match rs:
    case []: []
    case +r <> t: Bool.pick(List<&2, F64>, Nat.is_eq(i, k), pr, raxpy(r, fnth(r, k), pr)) <> elim_go(t, k, pr, Nat.add(i, 1n))

def gj_step(+rs: List<&2, List<&2, F64>>, +k: Nat) -> List<&2, List<&2, F64>>:
  +p = piv_go(rs, k, 0n, k, 0.0f64)
  +sw = swap(rs, k, p)
  +pv = fnth(rnth(sw, k), k)
  +pr = rscale(rnth(sw, k), F64.div(1.0f64, pv))
  elim_go(sw, k, pr, 0n)

def gj_go(n: Nat, +rs: List<&2, List<&2, F64>>, +k: Nat) -> List<&2, List<&2, F64>>:
  match n:
    case 0n: rs
    case 1n+m: gj_go(m, gj_step(rs, k), Nat.add(k, 1n))

def rdrop(n: Nat, r: List<&2, F64>) -> List<&2, F64>:
  match n:
    case 0n: r
    case 1n+m:
      match r:
        case []: []
        case x <> t: rdrop(m, t)

def right_half(rs: List<&2, List<&2, F64>>, +n: Nat) -> List<&2, List<&2, F64>>:
  match rs:
    case []: []
    case r <> t: rdrop(n, r) <> right_half(t, n)

def rfin(r: List<&2, F64>) -> Bool:
  match r:
    case []: True{}
    case +x <> t: Bool.and(T.is_finite(x), rfin(t))

def mfin(rs: List<&2, List<&2, F64>>) -> Bool:
  match rs:
    case []: True{}
    case r <> t: Bool.and(rfin(r), mfin(t))

def inv(+rs: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  +n = List.length(&2, List<&2, F64>, rs)
  +r = right_half(gj_go(n, augment(rs, n, 0n), 0n), n)
  Bool.pick(List<&2, List<&2, F64>>, mfin(r), r, [])
