import Base
import ../c00/types.bend as T
import ../base/ex.bend as E

type I is Data:
  I{ lo: F64, hi: F64 }

def i_lo(a: I) -> F64:
  I{lo, hi} = a
  lo

def i_hi(a: I) -> F64:
  I{lo, hi} = a
  hi

def dn(+x: F64) -> F64:
  E.f64_next_down(x)

def up(+x: F64) -> F64:
  E.f64_next_up(x)

def ipt(+x: F64) -> I:
  I{x, x}

def iok(+a: I) -> Bool:
  Bool.and(T.is_finite(i_lo(a)), Bool.and(T.is_finite(i_hi(a)), F64.is_le(i_lo(a), i_hi(a))))

def iadd(+a: I, +b: I) -> I:
  I{dn(F64.add(i_lo(a), i_lo(b))), up(F64.add(i_hi(a), i_hi(b)))}

def isub(+a: I, +b: I) -> I:
  I{dn(F64.sub(i_lo(a), i_hi(b))), up(F64.sub(i_hi(a), i_lo(b)))}

def ineg(+a: I) -> I:
  I{F64.neg(i_hi(a)), F64.neg(i_lo(a))}

def mn4(+a: F64, +b: F64, +c: F64, +d: F64) -> F64:
  F64.min(F64.min(a, b), F64.min(c, d))

def mx4(+a: F64, +b: F64, +c: F64, +d: F64) -> F64:
  F64.max(F64.max(a, b), F64.max(c, d))

def imul(+a: I, +b: I) -> I:
  +p1 = F64.mul(i_lo(a), i_lo(b))
  +p2 = F64.mul(i_lo(a), i_hi(b))
  +p3 = F64.mul(i_hi(a), i_lo(b))
  +p4 = F64.mul(i_hi(a), i_hi(b))
  I{dn(mn4(p1, p2, p3, p4)), up(mx4(p1, p2, p3, p4))}

def idiv(+a: I, +b: I) -> I:
  +z = Bool.and(F64.is_le(i_lo(b), 0.0f64), F64.is_le(0.0f64, i_hi(b)))
  +p1 = F64.div(i_lo(a), i_lo(b))
  +p2 = F64.div(i_lo(a), i_hi(b))
  +p3 = F64.div(i_hi(a), i_lo(b))
  +p4 = F64.div(i_hi(a), i_hi(b))
  Bool.pick(I, z, I{F64.nan(), F64.nan()}, I{dn(mn4(p1, p2, p3, p4)), up(mx4(p1, p2, p3, p4))})

def isq(+a: I) -> I:
  +l = i_lo(a)
  +h = i_hi(a)
  +m = F64.max(F64.abs(l), F64.abs(h))
  +n = Bool.pick(F64, Bool.and(F64.is_le(l, 0.0f64), F64.is_le(0.0f64, h)), 0.0f64,
    F64.min(F64.abs(l), F64.abs(h)))
  I{F64.max(0.0f64, dn(F64.mul(n, n))), up(F64.mul(m, m))}

def isqrt(+a: I) -> I:
  I{dn(F64.sqrt(F64.max(0.0f64, i_lo(a)))), up(F64.sqrt(i_hi(a)))}

def iscale(+a: I, +k: F64) -> I:
  imul(a, ipt(k))

def ihull(+a: I, +b: I) -> I:
  I{F64.min(i_lo(a), i_lo(b)), F64.max(i_hi(a), i_hi(b))}

def iwiden(+a: I, +e: F64) -> I:
  I{dn(F64.sub(i_lo(a), e)), up(F64.add(i_hi(a), e))}

def of_ex(+e: E.Ex) -> I:
  +v = E.ex_est(e)
  +m = F64.mul(F64.abs(v), 9.094947017729282e-13f64)
  Bool.pick(I, E.ex_ok(e), I{dn(F64.sub(v, m)), up(F64.add(v, m))}, I{F64.nan(), F64.nan()})

def pi_i() -> I:
  I{F64{4614256656552045847u64}, F64{4614256656552045849u64}}

def half_pi() -> I:
  I{F64{4609753056924675351u64}, F64{4609753056924675353u64}}

def red(+x: I) -> I:
  idiv(x, iadd(ipt(1.0f64), isqrt(iadd(ipt(1.0f64), isq(x)))))

def ser_go(n: Nat, +x2: I, +p: I, +k: F64, +acc: I, +neg: Bool) -> I:
  match n:
    case 0n: acc
    case 1n+m:
      +t = idiv(p, ipt(k))
      ser_go(m, x2, imul(p, x2), F64.add(k, 2.0f64), Bool.pick(I, neg, isub(acc, t), iadd(acc, t)), Bool.not(neg))

def atan_small(+y: I) -> I:
  +x2 = isq(y)
  +s = ser_go(14n, x2, imul(y, x2), 3.0f64, y, True{})
  +tail = up(F64.div(up(F64.mul(F64.max(F64.abs(i_lo(y)), F64.abs(i_hi(y))), 1.0e-20f64)), 1.0f64))
  iwiden(s, tail)

def atan01(+x: I) -> I:
  iscale(atan_small(red(red(x))), 4.0f64)

def atan2q(+c: I, +d: I) -> I:
  Bool.pick(I, F64.is_le(i_hi(c), i_lo(d)), atan01(idiv(c, d)),
    isub(half_pi(), atan01(idiv(d, c))))

def clamp1(+a: I) -> I:
  I{F64.max(F64.neg(1.0f64), i_lo(a)), F64.min(1.0f64, i_hi(a))}

def tay_go(n: Nat, +x2: I, +p: I, +k: F64, +acc: I, +neg: Bool) -> I:
  match n:
    case 0n: acc
    case 1n+m:
      +q = idiv(imul(p, x2), ipt(F64.mul(k, F64.add(k, 1.0f64))))
      tay_go(m, x2, q, F64.add(k, 2.0f64), Bool.pick(I, neg, isub(acc, q), iadd(acc, q)), Bool.not(neg))

def sin_small(+t: I) -> I:
  iwiden(tay_go(14n, isq(t), t, 2.0f64, t, True{}), 1.0e-30f64)

def cos_small(+t: I) -> I:
  iwiden(tay_go(14n, isq(t), ipt(1.0f64), 1.0f64, ipt(1.0f64), True{}), 1.0e-30f64)

def quad(+k: U64, +c: I, +s: I) -> List<&2, I>:
  match k:
    case 0u64: [c, s]
    case 1u64: [ineg(s), c]
    case 2u64: [ineg(c), ineg(s)]
    case _: [s, ineg(c)]

def sc_exact(+k: U64) -> List<&2, I>:
  quad(k, ipt(1.0f64), ipt(0.0f64))

def sc_red(+d: F64, +kf: F64, +k: U64) -> List<&2, I>:
  +t = imul(isub(ipt(d), ipt(F64.mul(90.0f64, kf))), idiv(pi_i(), ipt(180.0f64)))
  quad(k, clamp1(cos_small(t)), clamp1(sin_small(t)))

def sin_cos_deg(+d: F64) -> List<&2, I>:
  +neg = F64.is_lt(d, 0.0f64)
  +n = F64.to_u64(F64.add(F64.div(F64.abs(d), 90.0f64), 0.5f64))
  +kf = Bool.pick(F64, neg, F64.neg(U64.to_f64(n)), U64.to_f64(n))
  +k = Bool.pick(U64, neg, U64.sub(4u64, U64.mod(n, 4u64)), U64.mod(n, 4u64))
  +k4 = U64.mod(k, 4u64)
  Bool.pick(List<&2, I>, F64.is_eq(d, F64.mul(90.0f64, kf)), sc_exact(k4), sc_red(d, kf, k4))
