import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../base/ex.bend as E
import ./sf.bend as S

type D is Data:
  D{ h: F64, l: F64 }

type P3 is Data:
  P3{ x: D, y: D, z: D }

def d_f(+x: F64) -> D:
  D{x, 0.0f64}

def d_fix(+s: F64, +e: F64) -> D:
  +h = F64.add(s, e)
  D{h, F64.sub(e, F64.sub(h, s))}

def d_add(+a: D, +b: D) -> D:
  D{+ah, +al} = a
  D{+bh, +bl} = b
  +t = E.two_sum(ah, bh)
  d_fix(E.tw_hi(t), F64.add(E.tw_lo(t), F64.add(al, bl)))

def d_neg(+a: D) -> D:
  D{+h, +l} = a
  D{F64.neg(h), F64.neg(l)}

def d_sub(+a: D, +b: D) -> D:
  d_add(a, d_neg(b))

def d_mul(+a: D, +b: D) -> D:
  D{+ah, +al} = a
  D{+bh, +bl} = b
  +t = E.two_prod(ah, bh)
  d_fix(E.tw_hi(t), F64.add(E.tw_lo(t), F64.add(F64.mul(ah, bl), F64.mul(al, bh))))

def d_sc(+a: D, +x: F64) -> D:
  d_mul(a, d_f(x))

def d_hi(+a: D) -> F64:
  D{+h, +l} = a
  F64.add(h, l)

def ff(+a: F64, +b: F64) -> D:
  d_mul(d_f(a), d_f(b))

def p3_of(+p: V.Point) -> P3:
  V.Pt{+x, +y, +z} = p
  P3{d_f(x), d_f(y), d_f(z)}

def p3_pt(+p: P3) -> V.Point:
  P3{+x, +y, +z} = p
  V.Pt{d_hi(x), d_hi(y), d_hi(z)}

def p3_rel(+p: P3, +o: V.Point) -> P3:
  P3{+x, +y, +z} = p
  V.Pt{+ox, +oy, +oz} = o
  P3{d_sub(x, d_f(ox)), d_sub(y, d_f(oy)), d_sub(z, d_f(oz))}

def p3_mv(+p: P3, +d: V.Dir) -> P3:
  P3{+x, +y, +z} = p
  V.Dr{+dx, +dy, +dz} = d
  P3{d_sub(x, d_f(dx)), d_sub(y, d_f(dy)), d_sub(z, d_f(dz))}

def p3_sq(+m: P3) -> D:
  P3{+x, +y, +z} = m
  d_add(d_add(d_mul(x, x), d_mul(y, y)), d_mul(z, z))

def p3_dot(+m: P3, +a: V.Dir) -> D:
  P3{+x, +y, +z} = m
  V.Dr{+ax, +ay, +az} = a
  d_add(d_add(d_sc(x, ax), d_sc(y, ay)), d_sc(z, az))

def p3_dot3(+m: P3, +n: P3) -> D:
  P3{+x, +y, +z} = m
  P3{+nx, +ny, +nz} = n
  d_add(d_add(d_mul(x, nx), d_mul(y, ny)), d_mul(z, nz))

def dsq(+a: V.Dir) -> D:
  V.Dr{+ax, +ay, +az} = a
  d_add(d_add(ff(ax, ax), ff(ay, ay)), ff(az, az))

def pl_n(+u: V.Dir, +v: V.Dir) -> P3:
  V.Dr{+ux, +uy, +uz} = u
  V.Dr{+vx, +vy, +vz} = v
  P3{d_sub(ff(uy, vz), ff(uz, vy)), d_sub(ff(uz, vx), ff(ux, vz)), d_sub(ff(ux, vy), ff(uy, vx))}

def cyl_r(+o: V.Point, +a: V.Dir, +r: F64, +q: P3) -> D:
  +m = p3_rel(q, o)
  +aa = dsq(a)
  +am = p3_dot(m, a)
  d_sub(d_sub(d_mul(aa, p3_sq(m)), d_mul(am, am)), d_mul(aa, ff(r, r)))

def cone_r(+o: V.Point, +a: V.Dir, +k: F64, +q: P3) -> D:
  +m = p3_rel(q, o)
  +am = p3_dot(m, a)
  d_sub(d_mul(dsq(a), p3_sq(m)), d_mul(d_add(d_f(1.0f64), ff(k, k)), d_mul(am, am)))

def tor_r(+o: V.Point, +a: V.Dir, +bigr: F64, +r: F64, +q: P3) -> D:
  +m = p3_rel(q, o)
  +aa = dsq(a)
  +am = p3_dot(m, a)
  +d2 = p3_sq(m)
  +w = d_sub(d_add(d2, ff(bigr, bigr)), ff(r, r))
  d_sub(d_mul(aa, d_mul(w, w)), d_sc(d_sc(d_sub(d_mul(aa, d2), d_mul(am, am)), bigr), F64.mul(4.0f64, bigr)))

def res(g: G.GVal, +q: P3) -> D:
  match g:
    case G.GV_sp{w}:
      G.Sp{+c, +r} = w
      d_sub(p3_sq(p3_rel(q, c)), ff(r, r))
    case G.GV_cy{w}:
      G.Cy{+o, +a, +r} = w
      cyl_r(o, a, r, q)
    case G.GV_co{w}:
      G.Co{+o, +a, +k} = w
      cone_r(o, a, k, q)
    case G.GV_to{w}:
      G.To{+o, +a, +bigr, +r} = w
      tor_r(o, a, bigr, r, q)
    case G.GV_pl{w}:
      G.Pl{+o, +u, +v} = w
      p3_dot3(p3_rel(q, o), pl_n(u, v))
    case _: d_f(0.0f64)

def an(g: G.GVal) -> Bool:
  match g:
    case G.GV_sp{w}: True{}
    case G.GV_cy{w}: True{}
    case G.GV_co{w}: True{}
    case G.GV_to{w}: True{}
    case G.GV_pl{w}: True{}
    case _: False{}

def ax_g(+m: V.Dir, +a: V.Dir, +c: F64) -> V.Dir:
  +aa = S.dot(a, a)
  +am = S.dot(m, a)
  S.dadd(S.dscale(F64.mul(2.0f64, aa), m), F64.neg(F64.mul(2.0f64, F64.mul(c, am))), a)

def tor_g(+m: V.Dir, +a: V.Dir, +bigr: F64, +r: F64) -> V.Dir:
  +aa = S.dot(a, a)
  +am = S.dot(m, a)
  +w = F64.sub(F64.add(S.dot(m, m), F64.mul(bigr, bigr)), F64.mul(r, r))
  +b8 = F64.mul(8.0f64, F64.mul(bigr, bigr))
  S.dadd(S.dscale(F64.sub(F64.mul(4.0f64, F64.mul(aa, w)), F64.mul(b8, aa)), m), F64.mul(b8, am), a)

def grad(g: G.GVal, +p: V.Point) -> V.Dir:
  match g:
    case G.GV_sp{w}:
      G.Sp{+c, +r} = w
      S.dscale(2.0f64, S.psub(p, c))
    case G.GV_cy{w}:
      G.Cy{+o, +a, +r} = w
      ax_g(S.psub(p, o), a, 1.0f64)
    case G.GV_co{w}:
      G.Co{+o, +a, +k} = w
      ax_g(S.psub(p, o), a, F64.add(1.0f64, F64.mul(k, k)))
    case G.GV_to{w}:
      G.To{+o, +a, +bigr, +r} = w
      tor_g(S.psub(p, o), a, bigr, r)
    case G.GV_pl{w}:
      G.Pl{+o, +u, +v} = w
      S.cross(u, v)
    case _: S.dr(0.0f64, 0.0f64, 0.0f64)

def dmax(+d: V.Dir) -> F64:
  F64.max(F64.abs(S.dx(d)), F64.max(F64.abs(S.dy(d)), F64.abs(S.dz(d))))

def pmax(+p: V.Point) -> F64:
  F64.max(F64.abs(S.px(p)), F64.max(F64.abs(S.py(p)), F64.abs(S.pz(p))))

def small(+d: V.Dir, +p: V.Point) -> Bool:
  +m = dmax(d)
  Bool.and(F64.is_eq(m, m), F64.is_le(m, F64.mul(1.0e-7f64, F64.add(1.0f64, pmax(p)))))

def mv_if(+q: P3, +d: V.Dir, +p: V.Point) -> P3:
  Bool.pick(P3, small(d, p), p3_mv(q, d), q)

def st2(+g1: G.GVal, +g2: G.GVal, +q: P3) -> P3:
  +p = p3_pt(q)
  +n1 = grad(g1, p)
  +n2 = grad(g2, p)
  mv_if(q, S.solve3(n1, n2, S.cross(n1, n2), S.dr(d_hi(res(g1, q)), d_hi(res(g2, q)), 0.0f64)), p)

def st3(+g1: G.GVal, +g2: G.GVal, +g3: G.GVal, +q: P3) -> P3:
  +p = p3_pt(q)
  mv_if(q, S.solve3(grad(g1, p), grad(g2, p), grad(g3, p), S.dr(d_hi(res(g1, q)), d_hi(res(g2, q)), d_hi(res(g3, q)))), p)

def it2(n: Nat, +g1: G.GVal, +g2: G.GVal, +q: P3) -> P3:
  match n:
    case 0n: q
    case 1n+m: it2(m, g1, g2, st2(g1, g2, q))

def it3(n: Nat, +g1: G.GVal, +g2: G.GVal, +g3: G.GVal, +q: P3) -> P3:
  match n:
    case 0n: q
    case 1n+m: it3(m, g1, g2, g3, st3(g1, g2, g3, q))

def indep(+g1: G.GVal, +g2: G.GVal, +g3: G.GVal, +p: V.Point) -> Bool:
  +a = grad(g1, p)
  +b = grad(g2, p)
  +c = grad(g3, p)
  +s = F64.mul(S.dlen(a), F64.mul(S.dlen(b), S.dlen(c)))
  F64.is_lt(F64.mul(1.0e-6f64, s), F64.abs(S.det3(a, b, c)))

def two(ok: Bool, +g1: G.GVal, +g2: G.GVal, +p: V.Point) -> V.Point:
  match ok:
    case False{}: p
    case True{}: p3_pt(it2(4n, g1, g2, p3_of(p)))

def three(ok: Bool, +g1: G.GVal, +g2: G.GVal, +g3: G.GVal, +p: V.Point) -> V.Point:
  match ok:
    case False{}: two(Bool.and(an(g1), an(g2)), g1, g2, p)
    case True{}: p3_pt(it3(4n, g1, g2, g3, p3_of(p)))

def ref_t(t: List<&2, G.GVal>, +g1: G.GVal, +g2: G.GVal, +p: V.Point) -> V.Point:
  match t:
    case []: two(Bool.and(an(g1), an(g2)), g1, g2, p)
    case +g3 <> r: three(Bool.and(Bool.and(an(g1), an(g2)), Bool.and(an(g3), indep(g1, g2, g3, p))), g1, g2, g3, p)

def ref_s(t: List<&2, G.GVal>, +g1: G.GVal, +p: V.Point) -> V.Point:
  match t:
    case []: p
    case +g2 <> r: ref_t(r, g1, g2, p)

def refine(gs: List<&2, G.GVal>, +p: V.Point) -> V.Point:
  match gs:
    case []: p
    case +g1 <> t: ref_s(t, g1, p)
