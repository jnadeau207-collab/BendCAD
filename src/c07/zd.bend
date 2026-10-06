import Base
import ../c06/iv.bend as I
import ./ivx.bend as V

type Dv is Data:
  Dv{ v: I.I, g: List<&2, I.I> }

def gz(n: Nat) -> List<&2, I.I>:
  match n:
    case 0n: []
    case 1n+m: I.ipt(0.0f64) <> gz(m)

def ge(n: Nat, +i: Nat) -> List<&2, I.I>:
  match n:
    case 0n: []
    case 1n+(+m): Bool.pick(List<&2, I.I>, Nat.is_eq(i, 0n), I.ipt(1.0f64) <> gz(m), I.ipt(0.0f64) <> ge(m, Nat.sub(i, 1n)))

def dk(+n: Nat, +v: I.I) -> Dv:
  Dv{v, gz(n)}

def dvar(+n: Nat, +i: Nat, +v: I.I) -> Dv:
  Dv{v, ge(n, i)}

def gadd(xs: List<&2, I.I>, +ys: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: ys
    case +x <> +t:
      match ys:
        case []: x <> t
        case y <> u: I.iadd(x, y) <> gadd(t, u)

def gsc(+s: I.I, xs: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t: I.imul(s, x) <> gsc(s, t)

def gcomb(+a: I.I, xs: List<&2, I.I>, +b: I.I, ys: List<&2, I.I>) -> List<&2, I.I>:
  gadd(gsc(a, xs), gsc(b, ys))

def dval(d: Dv) -> I.I:
  Dv{v, g} = d
  v

def dgrad(d: Dv) -> List<&2, I.I>:
  Dv{v, g} = d
  g

def dadd(+a: Dv, +b: Dv) -> Dv:
  Dv{I.iadd(dval(a), dval(b)), gadd(dgrad(a), dgrad(b))}

def dneg(+a: Dv) -> Dv:
  Dv{I.ineg(dval(a)), gsc(I.ipt(F64.neg(1.0f64)), dgrad(a))}

def dsub(+a: Dv, +b: Dv) -> Dv:
  dadd(a, dneg(b))

def dmul(+a: Dv, +b: Dv) -> Dv:
  +x = dval(a)
  +y = dval(b)
  Dv{I.imul(x, y), gcomb(y, dgrad(a), x, dgrad(b))}

def dsc(+s: I.I, +a: Dv) -> Dv:
  Dv{I.imul(s, dval(a)), gsc(s, dgrad(a))}

def ddiv(+a: Dv, +b: Dv) -> Dv:
  +x = dval(a)
  +y = dval(b)
  +q = I.idiv(x, y)
  Dv{q, gsc(I.idiv(I.ipt(1.0f64), y), gadd(dgrad(a), gsc(I.ineg(q), dgrad(b))))}

def dsq(+a: Dv) -> Dv:
  dmul(a, a)

def dsqrt(+a: Dv) -> Dv:
  +r = I.isqrt(dval(a))
  Dv{r, gsc(I.idiv(I.ipt(0.5f64), r), dgrad(a))}

def datan(+c: Dv, +d: Dv, +val: I.I) -> Dv:
  +x = dval(c)
  +y = dval(d)
  +den = I.iadd(I.isq(x), I.isq(y))
  Dv{val, gcomb(I.idiv(y, den), dgrad(c), I.idiv(I.ineg(x), den), dgrad(d))}

def dsincos(+f: Dv, +cs: List<&2, I.I>) -> List<&2, Dv>:
  +c = V.vn(cs, 0n)
  +s = V.vn(cs, 1n)
  +g = dgrad(f)
  [Dv{c, gsc(I.ineg(s), g)}, Dv{s, gsc(c, g)}]

def gdot(xs: List<&2, I.I>, ys: List<&2, I.I>) -> I.I:
  match xs:
    case []: I.ipt(0.0f64)
    case x <> t:
      match ys:
        case []: I.ipt(0.0f64)
        case y <> u: I.iadd(I.imul(x, y), gdot(t, u))

def mvf(+mid: Dv, +box: Dv, +w: List<&2, I.I>) -> I.I:
  +m = I.iadd(dval(mid), gdot(dgrad(box), w))
  +b = dval(box)
  V.iof(F64.max(I.i_lo(m), I.i_lo(b)), F64.min(I.i_hi(m), I.i_hi(b)))
