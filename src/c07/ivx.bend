import Base
import ../c00/types.bend as T
import ../c06/iv.bend as I

def iz() -> I.I:
  I.ipt(0.0f64)

def has0(+a: I.I) -> Bool:
  Bool.not(Bool.or(F64.is_lt(0.0f64, I.i_lo(a)), F64.is_lt(I.i_hi(a), 0.0f64)))

def imid(+a: I.I) -> F64:
  F64.add(F64.mul(0.5f64, I.i_lo(a)), F64.mul(0.5f64, I.i_hi(a)))

def iwid(+a: I.I) -> F64:
  I.up(F64.sub(I.i_hi(a), I.i_lo(a)))

def imag(+a: I.I) -> F64:
  F64.max(F64.abs(I.i_lo(a)), F64.abs(I.i_hi(a)))

def iin(+a: I.I, +b: I.I) -> Bool:
  Bool.and(F64.is_lt(I.i_lo(b), I.i_lo(a)), F64.is_lt(I.i_hi(a), I.i_hi(b)))

def isub_of(+a: I.I, +b: I.I) -> Bool:
  Bool.and(F64.is_le(I.i_lo(b), I.i_lo(a)), F64.is_le(I.i_hi(a), I.i_hi(b)))

def idisj(+a: I.I, +b: I.I) -> Bool:
  Bool.or(F64.is_lt(I.i_hi(a), I.i_lo(b)), F64.is_lt(I.i_hi(b), I.i_lo(a)))

def imeet(+a: I.I, +b: I.I) -> I.I:
  I.I{F64.max(I.i_lo(a), I.i_lo(b)), F64.min(I.i_hi(a), I.i_hi(b))}

def ilo_half(+a: I.I) -> I.I:
  I.I{I.i_lo(a), imid(a)}

def ihi_half(+a: I.I) -> I.I:
  I.I{imid(a), I.i_hi(a)}

def iinfl(+a: I.I, +f: F64) -> I.I:
  +e = F64.add(F64.mul(f, iwid(a)), F64.mul(4.440892098500626e-16f64, imag(a)))
  I.iwiden(a, F64.add(e, 4.9406564584124654e-324f64))

def ifin(+a: I.I) -> Bool:
  Bool.and(T.is_finite(I.i_lo(a)), Bool.and(T.is_finite(I.i_hi(a)), F64.is_le(I.i_lo(a), I.i_hi(a))))

def ipos(+a: I.I) -> Bool:
  F64.is_lt(0.0f64, I.i_lo(a))

def ineg_c(+a: I.I) -> Bool:
  F64.is_lt(I.i_hi(a), 0.0f64)

def iof(+lo: F64, +hi: F64) -> I.I:
  I.I{lo, hi}

def ik(+n: F64, +d: F64) -> I.I:
  I.idiv(I.ipt(n), I.ipt(d))

def iaffine(+a: F64, +b: F64, +t: I.I) -> I.I:
  I.iadd(I.ipt(a), I.imul(I.isub(I.ipt(b), I.ipt(a)), t))

def vn(xs: List<&2, I.I>, +i: Nat) -> I.I:
  match xs:
    case []: I.ipt(F64.nan())
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: vn(t, j)

def fn_(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: F64.nan()
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: fn_(t, j)

def vset(xs: List<&2, I.I>, +i: Nat, +v: I.I) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t:
      match i:
        case 0n: v <> t
        case 1n+j: x <> vset(t, j, v)

def vdrop(xs: List<&2, I.I>, +i: Nat) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t:
      match i:
        case 0n: t
        case 1n+j: x <> vdrop(t, j)

def vins(i: Nat, xs: List<&2, I.I>, +v: I.I) -> List<&2, I.I>:
  match i:
    case 0n: v <> xs
    case 1n+j:
      match xs:
        case []: [v]
        case x <> t: x <> vins(j, t, v)

def vadd(xs: List<&2, I.I>, ys: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t:
      match ys:
        case []: []
        case y <> u: I.iadd(x, y) <> vadd(t, u)

def vsub(xs: List<&2, I.I>, ys: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t:
      match ys:
        case []: []
        case y <> u: I.isub(x, y) <> vsub(t, u)

def vmid(xs: List<&2, I.I>) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> t: imid(x) <> vmid(t)

def vpts(xs: List<&2, F64>) -> List<&2, I.I>:
  match xs:
    case []: []
    case +x <> t: I.ipt(x) <> vpts(t)

def vin(xs: List<&2, I.I>, ys: List<&2, I.I>) -> Bool:
  match xs:
    case []: True{}
    case x <> t:
      match ys:
        case []: False{}
        case y <> u: Bool.and(iin(x, y), vin(t, u))

def vsub_of(xs: List<&2, I.I>, ys: List<&2, I.I>) -> Bool:
  match xs:
    case []: True{}
    case x <> t:
      match ys:
        case []: False{}
        case y <> u: Bool.and(isub_of(x, y), vsub_of(t, u))

def vdisj(xs: List<&2, I.I>, ys: List<&2, I.I>) -> Bool:
  match xs:
    case []: False{}
    case x <> t:
      match ys:
        case []: False{}
        case y <> u: Bool.or(idisj(x, y), vdisj(t, u))

def vmeet(xs: List<&2, I.I>, ys: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t:
      match ys:
        case []: []
        case y <> u: imeet(x, y) <> vmeet(t, u)

def vhull(xs: List<&2, I.I>, ys: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t:
      match ys:
        case []: []
        case y <> u: I.ihull(x, y) <> vhull(t, u)

def vany0_not(xs: List<&2, I.I>) -> Bool:
  match xs:
    case []: False{}
    case +x <> t: Bool.or(Bool.not(has0(x)), vany0_not(t))

def vfin(xs: List<&2, I.I>) -> Bool:
  match xs:
    case []: True{}
    case +x <> t: Bool.and(ifin(x), vfin(t))

def vwid(xs: List<&2, I.I>) -> F64:
  match xs:
    case []: 0.0f64
    case +x <> t: F64.max(iwid(x), vwid(t))

def vinfl(xs: List<&2, I.I>, +f: F64) -> List<&2, I.I>:
  match xs:
    case []: []
    case +x <> t: iinfl(x, f) <> vinfl(t, f)

def vdot(xs: List<&2, I.I>, ys: List<&2, I.I>) -> I.I:
  match xs:
    case []: iz()
    case x <> t:
      match ys:
        case []: iz()
        case y <> u: I.iadd(I.imul(x, y), vdot(t, u))

def fdot(xs: List<&2, F64>, ys: List<&2, I.I>) -> I.I:
  match xs:
    case []: iz()
    case x <> t:
      match ys:
        case []: iz()
        case y <> u: I.iadd(I.imul(I.ipt(x), y), fdot(t, u))

def mv(ms: List<&2, List<&2, I.I>>, +xs: List<&2, I.I>) -> List<&2, I.I>:
  match ms:
    case []: []
    case r <> t: vdot(r, xs) <> mv(t, xs)

def fmv(ms: List<&2, List<&2, F64>>, +xs: List<&2, I.I>) -> List<&2, I.I>:
  match ms:
    case []: []
    case r <> t: fdot(r, xs) <> fmv(t, xs)

def col(ms: List<&2, List<&2, I.I>>, +j: Nat) -> List<&2, I.I>:
  match ms:
    case []: []
    case r <> t: vn(r, j) <> col(t, j)

def cols(n: Nat, +ms: List<&2, List<&2, I.I>>, +j: Nat) -> List<&2, List<&2, I.I>>:
  match n:
    case 0n: []
    case 1n+m: col(ms, j) <> cols(m, ms, Nat.add(j, 1n))

def fm_row(+y: List<&2, F64>, +cs: List<&2, List<&2, I.I>>) -> List<&2, I.I>:
  match cs:
    case []: []
    case c <> t: fdot(y, c) <> fm_row(y, t)

def fmm(ys: List<&2, List<&2, F64>>, +cs: List<&2, List<&2, I.I>>) -> List<&2, List<&2, I.I>>:
  match ys:
    case []: []
    case y <> t: fm_row(y, cs) <> fmm(t, cs)

def id_minus_row(r: List<&2, I.I>, +i: Nat, +j: Nat) -> List<&2, I.I>:
  match r:
    case []: []
    case +x <> t: Bool.pick(I.I, Nat.is_eq(i, j), I.isub(I.ipt(1.0f64), x), I.ineg(x)) <> id_minus_row(t, i, Nat.add(j, 1n))

def id_minus(ms: List<&2, List<&2, I.I>>, +i: Nat) -> List<&2, List<&2, I.I>>:
  match ms:
    case []: []
    case r <> t: id_minus_row(r, i, 0n) <> id_minus(t, Nat.add(i, 1n))

def mdrop_col(ms: List<&2, List<&2, I.I>>, +k: Nat) -> List<&2, List<&2, I.I>>:
  match ms:
    case []: []
    case r <> t: vdrop(r, k) <> mdrop_col(t, k)

def mmid_row(r: List<&2, I.I>) -> List<&2, F64>:
  match r:
    case []: []
    case +x <> t: imid(x) <> mmid_row(t)

def mmid(ms: List<&2, List<&2, I.I>>) -> List<&2, List<&2, F64>>:
  match ms:
    case []: []
    case r <> t: mmid_row(r) <> mmid(t)
