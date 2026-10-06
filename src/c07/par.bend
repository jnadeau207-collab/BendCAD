import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c06/iv.bend as I
import ../c06/surfx.bend as SX
import ./ivx.bend as X
import ./im.bend as M
import ./xs.bend as Q

def vsc(+s: I.I, xs: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t: I.imul(s, x) <> vsc(s, t)

def q1(q: SX.QFr) -> List<&2, I.I>:
  SX.QFr{n1, n2} = q
  M.d3(n1)

def q2(q: SX.QFr) -> List<&2, I.I>:
  SX.QFr{n1, n2} = q
  M.d3(n2)

def fr1(a: V.Dir) -> List<&2, I.I>:
  q1(SX.qframe(a))

def fr2(a: V.Dir) -> List<&2, I.I>:
  q2(SX.qframe(a))

def plane_par(+o: V.Point, +u: V.Dir, +v: V.Dir, +p: List<&2, I.I>) -> List<&2, I.I>:
  +m = X.vsub(p, M.p3(o))
  +uu = M.d3(u)
  +vv = M.d3(v)
  +a = X.vdot(uu, uu)
  +b = X.vdot(uu, vv)
  +c = X.vdot(vv, vv)
  +um = X.vdot(uu, m)
  +vm = X.vdot(vv, m)
  +det = I.isub(I.imul(a, c), I.isq(b))
  [I.idiv(I.isub(I.imul(c, um), I.imul(b, vm)), det), I.idiv(I.isub(I.imul(a, vm), I.imul(b, um)), det)]

def axial(+o: V.Point, +a: V.Dir, +p: List<&2, I.I>) -> I.I:
  +aa = M.d3(a)
  I.idiv(X.vdot(X.vsub(p, M.p3(o)), aa), X.vdot(aa, aa))

def perp(+o: V.Point, +a: V.Dir, +p: List<&2, I.I>) -> List<&2, I.I>:
  X.vsub(X.vsub(p, M.p3(o)), vsc(axial(o, a, p), M.d3(a)))

def ang(+a: V.Dir, +mp: List<&2, I.I>, +rho: I.I) -> I.I:
  Q.inv_circ(I.idiv(X.vdot(mp, fr1(a)), rho), I.idiv(X.vdot(mp, fr2(a)), rho))

def sf_par(g: G.GVal, +p: List<&2, I.I>) -> List<&2, I.I>:
  match g:
    case G.GV_pl{w}:
      G.Pl{o, u, v} = w
      plane_par(o, u, v, p)
    case G.GV_cy{w}:
      G.Cy{+o, +a, r} = w
      [ang(a, perp(o, a, p), I.ipt(r)), axial(o, a, p)]
    case G.GV_co{w}:
      G.Co{+o, +a, +k} = w
      +h = axial(o, a, p)
      [ang(a, perp(o, a, p), I.imul(I.ipt(k), h)), h]
    case G.GV_to{w}:
      G.To{+o, +a, +bigr, +r} = w
      +mp = perp(o, a, p)
      +rho = I.isqrt(X.vdot(mp, mp))
      [ang(a, mp, rho), Q.inv_circ(I.idiv(I.isub(rho, I.ipt(bigr)), I.ipt(r)), I.idiv(axial(o, a, p), I.ipt(r)))]
    case G.GV_sp{w}:
      G.Sp{c, r} = w
      +n = vsc(I.idiv(I.ipt(1.0f64), I.ipt(r)), X.vsub(p, M.p3(c)))
      +d = I.iadd(I.ipt(1.0f64), X.vn(n, 2n))
      [I.idiv(X.vn(n, 0n), d), I.idiv(X.vn(n, 1n), d)]
    case _: []
