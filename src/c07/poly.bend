import Base
import ../c01/types.bend as V
import ../base/par.bend as P
import ../base/ex.bend as E

type Xc is Data:
  Xc{ x: List<&2, E.Ex>, y: List<&2, E.Ex>, z: List<&2, E.Ex>, w: List<&2, E.Ex> }

type Xs is Data:
  X_pl{ o: V.Point, n: List<&2, E.Ex> }
  X_sp{ c: V.Point, rr: E.Ex }
  X_cy{ o: V.Point, a: V.Dir, r: F64 }
  X_co{ o: V.Point, a: V.Dir, k: F64 }
  X_to{ o: V.Point, a: V.Dir, bigr: F64, r: F64 }

def ek(+x: F64) -> E.Ex:
  E.ex_of(x)

def padd(a: List<&2, E.Ex>, +b: List<&2, E.Ex>) -> List<&2, E.Ex>:
  match a:
    case []: b
    case +x <> +t:
      match b:
        case []: x <> t
        case y <> u: E.ex_add(x, y) <> padd(t, u)

def pscale(+s: E.Ex, a: List<&2, E.Ex>) -> List<&2, E.Ex>:
  match a:
    case []: []
    case x <> t: E.ex_mul(s, x) <> pscale(s, t)

def psub(a: List<&2, E.Ex>, +b: List<&2, E.Ex>) -> List<&2, E.Ex>:
  padd(a, pscale(ek(F64.neg(1.0f64)), b))

def pmul(a: List<&2, E.Ex>, +b: List<&2, E.Ex>) -> List<&2, E.Ex>:
  match a:
    case []: []
    case x <> t: padd(pscale(x, b), E.ex_zero() <> pmul(t, b))

def pk(+x: F64) -> List<&2, E.Ex>:
  [ek(x)]

def is_z(s: P.Sgn) -> Bool:
  match s:
    case P.Sz{}: True{}
    case _: False{}

def pzero_all(a: List<&2, E.Ex>) -> Bool:
  match a:
    case []: True{}
    case x <> t: Bool.and(is_z(E.ex_sign(x)), pzero_all(t))

def ptx(p: V.Point) -> F64:
  V.Pt{x, y, z} = p
  x

def pty(p: V.Point) -> F64:
  V.Pt{x, y, z} = p
  y

def ptz(p: V.Point) -> F64:
  V.Pt{x, y, z} = p
  z

def drx(p: V.Dir) -> F64:
  V.Dr{x, y, z} = p
  x

def dry(p: V.Dir) -> F64:
  V.Dr{x, y, z} = p
  y

def drz(p: V.Dir) -> F64:
  V.Dr{x, y, z} = p
  z

def xc_line(+p: V.Point, +d: V.Dir) -> Xc:
  Xc{[ek(ptx(p)), ek(drx(d))], [ek(pty(p)), ek(dry(d))], [ek(ptz(p)), ek(drz(d))], pk(1.0f64)}

def bz_pow(+a: F64, +b: F64, +c: F64, +d: F64) -> List<&2, E.Ex>:
  +ea = ek(a)
  +eb = ek(b)
  +ec = ek(c)
  [ea, E.ex_scale(E.ex_sub(eb, ea), 3.0f64), E.ex_scale(E.ex_add(E.ex_sub(ec, E.ex_scale(eb, 2.0f64)), ea), 3.0f64),
    E.ex_sub(E.ex_add(E.ex_sub(ek(d), E.ex_scale(ec, 3.0f64)), E.ex_scale(eb, 3.0f64)), ea)]

def xc_bez(+p0: V.Point, +p1: V.Point, +p2: V.Point, +p3: V.Point) -> Xc:
  Xc{bz_pow(ptx(p0), ptx(p1), ptx(p2), ptx(p3)), bz_pow(pty(p0), pty(p1), pty(p2), pty(p3)),
    bz_pow(ptz(p0), ptz(p1), ptz(p2), ptz(p3)), pk(1.0f64)}

def rq_pow(+a: E.Ex, +b: E.Ex, +c: E.Ex) -> List<&2, E.Ex>:
  [a, E.ex_scale(E.ex_sub(b, a), 2.0f64), E.ex_add(E.ex_sub(a, E.ex_scale(b, 2.0f64)), c)]

def wx(+w: F64, +x: F64) -> E.Ex:
  E.ex_mul(ek(w), ek(x))

def xc_rq(+p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64, +w1: F64, +w2: F64) -> Xc:
  Xc{rq_pow(wx(w0, ptx(p0)), wx(w1, ptx(p1)), wx(w2, ptx(p2))), rq_pow(wx(w0, pty(p0)), wx(w1, pty(p1)), wx(w2, pty(p2))),
    rq_pow(wx(w0, ptz(p0)), wx(w1, ptz(p1)), wx(w2, ptz(p2))), rq_pow(ek(w0), ek(w1), ek(w2))}

def circ_pow(+c: F64, +r: F64, +u: F64, +v: F64) -> List<&2, E.Ex>:
  +ru = wx(r, u)
  +rv = wx(r, v)
  +ec = ek(c)
  [E.ex_add(ec, ru), E.ex_scale(rv, 4.0f64), E.ex_sub(E.ex_scale(ec, 2.0f64), E.ex_scale(ru, 6.0f64)), E.ex_scale(rv, F64.neg(4.0f64)), E.ex_add(ec, ru)]

def xc_circle(+c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64) -> Xc:
  Xc{circ_pow(ptx(c), r, drx(u), drx(v)), circ_pow(pty(c), r, dry(u), dry(v)), circ_pow(ptz(c), r, drz(u), drz(v)),
    [ek(1.0f64), E.ex_zero(), ek(2.0f64), E.ex_zero(), ek(1.0f64)]}

def xc_w(c: Xc) -> List<&2, E.Ex>:
  Xc{x, y, z, w} = c
  w

def mvec(c: Xc, +o: V.Point) -> List<&2, List<&2, E.Ex>>:
  Xc{x, y, z, +w} = c
  [psub(x, pscale(ek(ptx(o)), w)), psub(y, pscale(ek(pty(o)), w)), psub(z, pscale(ek(ptz(o)), w))]

def pv(ms: List<&2, List<&2, E.Ex>>, +i: Nat) -> List<&2, E.Ex>:
  match ms:
    case []: []
    case m <> t:
      match i:
        case 0n: m
        case 1n+j: pv(t, j)

def pdot(+ms: List<&2, List<&2, E.Ex>>, +ns: List<&2, List<&2, E.Ex>>) -> List<&2, E.Ex>:
  padd(padd(pmul(pv(ms, 0n), pv(ns, 0n)), pmul(pv(ms, 1n), pv(ns, 1n))), pmul(pv(ms, 2n), pv(ns, 2n)))

def adot(+a: V.Dir, +ms: List<&2, List<&2, E.Ex>>) -> List<&2, E.Ex>:
  padd(padd(pscale(ek(drx(a)), pv(ms, 0n)), pscale(ek(dry(a)), pv(ms, 1n))), pscale(ek(drz(a)), pv(ms, 2n)))

def nth_e(xs: List<&2, E.Ex>, +i: Nat) -> E.Ex:
  match xs:
    case []: E.ex_zero()
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: nth_e(t, j)

def ndot(+n: List<&2, E.Ex>, +ms: List<&2, List<&2, E.Ex>>) -> List<&2, E.Ex>:
  padd(padd(pscale(nth_e(n, 0n), pv(ms, 0n)), pscale(nth_e(n, 1n), pv(ms, 1n))), pscale(nth_e(n, 2n), pv(ms, 2n)))

def eaa(+a: V.Dir) -> E.Ex:
  E.ex_add(E.ex_add(E.ex_mul(ek(drx(a)), ek(drx(a))), E.ex_mul(ek(dry(a)), ek(dry(a)))), E.ex_mul(ek(drz(a)), ek(drz(a))))

def ecross(+u: V.Dir, +v: V.Dir) -> List<&2, E.Ex>:
  [E.ex_sub(E.ex_mul(ek(dry(u)), ek(drz(v))), E.ex_mul(ek(drz(u)), ek(dry(v)))),
    E.ex_sub(E.ex_mul(ek(drz(u)), ek(drx(v))), E.ex_mul(ek(drx(u)), ek(drz(v)))),
    E.ex_sub(E.ex_mul(ek(drx(u)), ek(dry(v))), E.ex_mul(ek(dry(u)), ek(drx(v))))]

def xs_plane(+o: V.Point, +u: V.Dir, +v: V.Dir) -> Xs:
  X_pl{o, ecross(u, v)}

def comp_go(s: Xs, +c: Xc, +ww: List<&2, E.Ex>) -> List<&2, E.Ex>:
  match s:
    case X_pl{o, n}: ndot(n, mvec(c, o))
    case X_sp{o, rr}:
      +m = mvec(c, o)
      psub(pdot(m, m), pscale(rr, ww))
    case X_cy{o, +a, +r}:
      +m = mvec(c, o)
      +aa = eaa(a)
      +am = adot(a, m)
      psub(psub(pscale(aa, pdot(m, m)), pmul(am, am)), pscale(E.ex_mul(aa, E.ex_mul(ek(r), ek(r))), ww))
    case X_co{o, +a, +k}:
      +m = mvec(c, o)
      +am = adot(a, m)
      psub(pscale(eaa(a), pdot(m, m)), pscale(E.ex_add(ek(1.0f64), E.ex_mul(ek(k), ek(k))), pmul(am, am)))
    case X_to{o, +a, +bigr, +r}:
      +m = mvec(c, o)
      +aa = eaa(a)
      +mm = pdot(m, m)
      +am = adot(a, m)
      +rr = E.ex_mul(ek(bigr), ek(bigr))
      +q = padd(mm, pscale(E.ex_sub(rr, E.ex_mul(ek(r), ek(r))), ww))
      psub(pscale(aa, pmul(q, q)), pmul(pscale(E.ex_scale(rr, 4.0f64), ww), psub(pscale(aa, mm), pmul(am, am))))

def comp(+c: Xc, s: Xs) -> List<&2, E.Ex>:
  +w = xc_w(c)
  comp_go(s, c, pmul(w, w))

def on_surf(+c: Xc, s: Xs) -> Bool:
  pzero_all(comp(c, s))

def pdrop2(a: List<&2, E.Ex>) -> List<&2, E.Ex>:
  match a:
    case []: []
    case x <> t:
      match t:
        case []: []
        case y <> u: u

def side(+c: Xc, s: Xs) -> List<&2, E.Ex>:
  match s:
    case X_co{o, a, k}: adot(a, mvec(c, o))
    case _: []
