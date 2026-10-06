import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c06/iv.bend as I
import ./ivx.bend as X

type Im is Data:
  M_pl{ o: List<&2, I.I>, n: List<&2, I.I> }
  M_sp{ c: List<&2, I.I>, r: I.I }
  M_cy{ o: List<&2, I.I>, a: List<&2, I.I>, r: I.I }
  M_co{ o: List<&2, I.I>, a: List<&2, I.I>, k: I.I }
  M_to{ o: List<&2, I.I>, a: List<&2, I.I>, bigr: I.I, r: I.I }

def p3(p: V.Point) -> List<&2, I.I>:
  V.Pt{x, y, z} = p
  [I.ipt(x), I.ipt(y), I.ipt(z)]

def d3(d: V.Dir) -> List<&2, I.I>:
  V.Dr{x, y, z} = d
  [I.ipt(x), I.ipt(y), I.ipt(z)]

def cross(+a: List<&2, I.I>, +b: List<&2, I.I>) -> List<&2, I.I>:
  [I.isub(I.imul(X.vn(a, 1n), X.vn(b, 2n)), I.imul(X.vn(a, 2n), X.vn(b, 1n))),
    I.isub(I.imul(X.vn(a, 2n), X.vn(b, 0n)), I.imul(X.vn(a, 0n), X.vn(b, 2n))),
    I.isub(I.imul(X.vn(a, 0n), X.vn(b, 1n)), I.imul(X.vn(a, 1n), X.vn(b, 0n)))]

def im_plane(o: V.Point, u: V.Dir, v: V.Dir) -> Im:
  M_pl{p3(o), cross(d3(u), d3(v))}

def im_sphere(c: V.Point, +r: F64) -> Im:
  M_sp{p3(c), I.ipt(r)}

def im_cyl(o: V.Point, a: V.Dir, +r: F64) -> Im:
  M_cy{p3(o), d3(a), I.ipt(r)}

def im_cone(o: V.Point, a: V.Dir, +k: F64) -> Im:
  M_co{p3(o), d3(a), I.ipt(k)}

def im_torus(o: V.Point, a: V.Dir, +bigr: F64, +r: F64) -> Im:
  M_to{p3(o), d3(a), I.ipt(bigr), I.ipt(r)}

def vscale(+s: I.I, xs: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t: I.imul(s, x) <> vscale(s, t)

def im_val(s: Im, +p: List<&2, I.I>) -> I.I:
  match s:
    case M_pl{o, n}: X.vdot(n, X.vsub(p, o))
    case M_sp{o, r}:
      +m = X.vsub(p, o)
      I.isub(X.vdot(m, m), I.isq(r))
    case M_cy{o, +a, +r}:
      +m = X.vsub(p, o)
      +aa = X.vdot(a, a)
      I.isub(I.isub(I.imul(aa, X.vdot(m, m)), I.isq(X.vdot(a, m))), I.imul(aa, I.isq(r)))
    case M_co{o, +a, +k}:
      +m = X.vsub(p, o)
      I.isub(I.imul(X.vdot(a, a), X.vdot(m, m)), I.imul(I.iadd(I.ipt(1.0f64), I.isq(k)), I.isq(X.vdot(a, m))))
    case M_to{o, +a, +bigr, +r}:
      +m = X.vsub(p, o)
      +aa = X.vdot(a, a)
      +mm = X.vdot(m, m)
      +w = I.isub(I.iadd(mm, I.isq(bigr)), I.isq(r))
      I.isub(I.imul(aa, I.isq(w)), I.imul(I.imul(I.ipt(4.0f64), I.isq(bigr)), I.isub(I.imul(aa, mm), I.isq(X.vdot(a, m)))))

def im_grad(s: Im, +p: List<&2, I.I>) -> List<&2, I.I>:
  match s:
    case M_pl{o, n}: n
    case M_sp{o, r}: vscale(I.ipt(2.0f64), X.vsub(p, o))
    case M_cy{o, +a, r}:
      +m = X.vsub(p, o)
      X.vsub(vscale(I.imul(I.ipt(2.0f64), X.vdot(a, a)), m), vscale(I.imul(I.ipt(2.0f64), X.vdot(a, m)), a))
    case M_co{o, +a, +k}:
      +m = X.vsub(p, o)
      X.vsub(vscale(I.imul(I.ipt(2.0f64), X.vdot(a, a)), m), vscale(I.imul(I.imul(I.ipt(2.0f64), I.iadd(I.ipt(1.0f64), I.isq(k))), X.vdot(a, m)), a))
    case M_to{o, +a, +bigr, +r}:
      +m = X.vsub(p, o)
      +aa = X.vdot(a, a)
      +w = I.isub(I.iadd(X.vdot(m, m), I.isq(bigr)), I.isq(r))
      +c8 = I.imul(I.ipt(8.0f64), I.isq(bigr))
      X.vsub(vscale(I.isub(I.imul(I.imul(I.ipt(4.0f64), aa), w), I.imul(c8, aa)), m), vscale(I.imul(I.ineg(c8), X.vdot(a, m)), a))

def im_side(s: Im, +p: List<&2, I.I>) -> I.I:
  match s:
    case M_co{o, a, k}: X.vdot(a, X.vsub(p, o))
    case _: I.ipt(1.0f64)

def im_kind(s: Im) -> String:
  match s:
    case M_pl{o, n}: "plane"
    case M_sp{o, r}: "sphere"
    case M_cy{o, a, r}: "cylinder"
    case M_co{o, a, k}: "cone"
    case M_to{o, a, bigr, r}: "torus"
