import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c06/iv.bend as I
import ./ivx.bend as X

type Rb is Data:
  Rb{ x: List<&2, I.I>, y: List<&2, I.I>, z: List<&2, I.I>, w: List<&2, I.I> }

type Cv is Data:
  Cv{ rb: Rb, a: F64, b: F64 }

def comb(+a: I.I, +b: I.I, +t: I.I) -> I.I:
  I.iadd(a, I.imul(t, I.isub(b, a)))

def tl(cs: List<&2, I.I>) -> List<&2, I.I>:
  match cs:
    case []: []
    case c <> t: t

def zipc(xs: List<&2, I.I>, ys: List<&2, I.I>, +t: I.I) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> u:
      match ys:
        case []: []
        case y <> v: comb(x, y, t) <> zipc(u, v, t)

def lvl(+cs: List<&2, I.I>, +t: I.I) -> List<&2, I.I>:
  zipc(cs, tl(cs), t)

def blossom(ts: List<&2, I.I>, cs: List<&2, I.I>) -> I.I:
  match ts:
    case []: X.vn(cs, 0n)
    case t <> u: blossom(u, lvl(cs, t))

def reps(n: Nat, +a: I.I, +rest: List<&2, I.I>) -> List<&2, I.I>:
  match n:
    case 0n: rest
    case 1n+m: a <> reps(m, a, rest)

def restr_go(n: Nat, +cs: List<&2, I.I>, +a: I.I, +b: I.I, +d: Nat, +i: Nat) -> List<&2, I.I>:
  match n:
    case 0n: []
    case 1n+m: blossom(reps(Nat.sub(d, i), a, reps(i, b, [])), cs) <> restr_go(m, cs, a, b, d, Nat.add(i, 1n))

def restr(+cs: List<&2, I.I>, +a: I.I, +b: I.I) -> List<&2, I.I>:
  +n = List.length(&2, I.I, cs)
  restr_go(n, cs, a, b, Nat.sub(n, 1n), 0n)

def hull(cs: List<&2, I.I>) -> I.I:
  match cs:
    case []: I.I{F64.div(1.0f64, 0.0f64), F64.neg(F64.div(1.0f64, 0.0f64))}
    case +c <> t: I.ihull(c, hull(t))

def hodo_go(cs: List<&2, I.I>, +d: F64) -> List<&2, I.I>:
  match cs:
    case []: []
    case +c <> t:
      match t:
        case []: []
        case +c2 <> u: I.imul(I.ipt(d), I.isub(c2, c)) <> hodo_go(t, d)

def hodo(+cs: List<&2, I.I>) -> List<&2, I.I>:
  hodo_go(cs, U64.to_f64(U64.from_nat(Nat.sub(List.length(&2, I.I, cs), 1n))))

def qdiv(xs: List<&2, I.I>, ws: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t:
      match ws:
        case []: []
        case w <> u: I.idiv(x, w) <> qdiv(t, u)

def allpos(ws: List<&2, I.I>) -> Bool:
  match ws:
    case []: True{}
    case +w <> t: Bool.and(X.ipos(w), allpos(t))

def allone(ws: List<&2, I.I>) -> Bool:
  match ws:
    case []: True{}
    case +w <> t: Bool.and(Bool.and(F64.is_eq(I.i_lo(w), 1.0f64), F64.is_eq(I.i_hi(w), 1.0f64)), allone(t))

def rs(+cs: List<&2, I.I>, +t: I.I) -> List<&2, I.I>:
  restr(cs, I.ipt(I.i_lo(t)), I.ipt(I.i_hi(t)))

def coord_box(+xs: List<&2, I.I>, +ws: List<&2, I.I>) -> I.I:
  Bool.pick(I.I, allpos(ws), hull(qdiv(xs, ws)), I.idiv(hull(xs), hull(ws)))

def rb_box(r: Rb, +t: I.I) -> List<&2, I.I>:
  Rb{+x, +y, +z, +w} = r
  +ws = rs(w, t)
  [coord_box(rs(x, t), ws), coord_box(rs(y, t), ws), coord_box(rs(z, t), ws)]

def qder(+n: I.I, +dn: I.I, +w: I.I, +dw: I.I) -> I.I:
  I.idiv(I.isub(I.imul(dn, w), I.imul(n, dw)), I.isq(w))

def coord_der(+xs: List<&2, I.I>, +ws: List<&2, I.I>, +t: I.I, +poly: Bool) -> I.I:
  +dn = hull(rs(hodo(xs), t))
  Bool.pick(I.I, poly, dn, qder(hull(rs(xs, t)), dn, hull(rs(ws, t)), hull(rs(hodo(ws), t))))

def rb_der(r: Rb, +t: I.I) -> List<&2, I.I>:
  Rb{+x, +y, +z, +w} = r
  +poly = allone(w)
  [coord_der(x, w, t, poly), coord_der(y, w, t, poly), coord_der(z, w, t, poly)]

def cv_box(c: Cv, +t: I.I) -> List<&2, I.I>:
  Cv{rb, a, b} = c
  rb_box(rb, t)

def cv_der(c: Cv, +t: I.I) -> List<&2, I.I>:
  Cv{rb, a, b} = c
  rb_der(rb, t)

def cv_par(c: Cv, +t: I.I) -> I.I:
  Cv{rb, +a, +b} = c
  X.iaffine(a, b, t)

def cv_rb(c: Cv) -> Rb:
  Cv{rb, a, b} = c
  rb

def pmul(+a: F64, +b: F64) -> I.I:
  I.imul(I.ipt(a), I.ipt(b))

def lin_c(+p: F64, +d: F64, +lo: F64, +hi: F64) -> List<&2, I.I>:
  [I.iadd(I.ipt(p), pmul(lo, d)), I.iadd(I.ipt(p), pmul(hi, d))]

def ones(n: Nat) -> List<&2, I.I>:
  match n:
    case 0n: []
    case 1n+m: I.ipt(1.0f64) <> ones(m)

def cv_line(p: V.Point, d: V.Dir, +lo: F64, +hi: F64) -> Cv:
  V.Pt{+px, +py, +pz} = p
  V.Dr{+dx, +dy, +dz} = d
  Cv{Rb{lin_c(px, dx, lo, hi), lin_c(py, dy, lo, hi), lin_c(pz, dz, lo, hi), ones(2n)}, lo, hi}

def pts_x(ps: List<&2, V.Point>) -> List<&2, I.I>:
  match ps:
    case []: []
    case p <> t:
      V.Pt{x, y, z} = p
      I.ipt(x) <> pts_x(t)

def pts_y(ps: List<&2, V.Point>) -> List<&2, I.I>:
  match ps:
    case []: []
    case p <> t:
      V.Pt{x, y, z} = p
      I.ipt(y) <> pts_y(t)

def pts_z(ps: List<&2, V.Point>) -> List<&2, I.I>:
  match ps:
    case []: []
    case p <> t:
      V.Pt{x, y, z} = p
      I.ipt(z) <> pts_z(t)

def wmul(xs: List<&2, I.I>, ws: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t:
      match ws:
        case []: []
        case w <> u: I.imul(x, w) <> wmul(t, u)

def rb_cut(r: Rb, +lo: F64, +hi: F64) -> Rb:
  Rb{x, y, z, w} = r
  +a = I.ipt(lo)
  +b = I.ipt(hi)
  Rb{restr(x, a, b), restr(y, a, b), restr(z, a, b), restr(w, a, b)}

def rb_sel(whole: Bool, +r: Rb, +lo: F64, +hi: F64) -> Rb:
  match whole:
    case True{}: r
    case False{}: rb_cut(r, lo, hi)

def rb_restr(+r: Rb, +lo: F64, +hi: F64) -> Rb:
  rb_sel(Bool.and(F64.is_eq(lo, 0.0f64), F64.is_eq(hi, 1.0f64)), r, lo, hi)

def cv_bez(+ps: List<&2, V.Point>, +lo: F64, +hi: F64) -> Cv:
  Cv{rb_restr(Rb{pts_x(ps), pts_y(ps), pts_z(ps), ones(List.length(&2, V.Point, ps))}, lo, hi), lo, hi}

def cv_rat(+ps: List<&2, V.Point>, +ws: List<&2, F64>, +lo: F64, +hi: F64) -> Cv:
  +wi = X.vpts(ws)
  Cv{rb_restr(Rb{wmul(pts_x(ps), wi), wmul(pts_y(ps), wi), wmul(pts_z(ps), wi), wi}, lo, hi), lo, hi}

def pw_d() -> List<&2, F64>:
  [1.0f64, 0.0f64, 2.0f64, 0.0f64, 1.0f64]

def pw_n1() -> List<&2, F64>:
  [1.0f64, 0.0f64, F64.neg(6.0f64), 0.0f64, 1.0f64]

def pw_n2() -> List<&2, F64>:
  [0.0f64, 4.0f64, 0.0f64, F64.neg(4.0f64), 0.0f64]

def pw_comb(ds: List<&2, F64>, n1: List<&2, F64>, n2: List<&2, F64>, +c: F64, +ru: I.I, +rv: I.I) -> List<&2, I.I>:
  match ds:
    case []: []
    case d <> t:
      match n1:
        case []: []
        case a <> u:
          match n2:
            case []: []
            case b <> v: I.iadd(I.iadd(pmul(c, d), I.imul(I.ipt(a), ru)), I.imul(I.ipt(b), rv)) <> pw_comb(t, u, v, c, ru, rv)

def pw_eval(ps: List<&2, I.I>, +t: I.I) -> I.I:
  match ps:
    case []: I.ipt(0.0f64)
    case p <> u: I.iadd(p, I.imul(t, pw_eval(u, t)))

def pw_der(ps: List<&2, I.I>, +k: F64) -> List<&2, I.I>:
  match ps:
    case []: []
    case p <> u: I.imul(I.ipt(k), p) <> pw_der(u, F64.add(k, 1.0f64))

def pw_tl(ps: List<&2, I.I>) -> List<&2, I.I>:
  match ps:
    case []: []
    case p <> u: u

def tshift_go(n: Nat, +ps: List<&2, I.I>, +a: I.I, +h: I.I, +j: F64, +hp: I.I, +fact: F64) -> List<&2, I.I>:
  match n:
    case 0n: []
    case 1n+m:
      I.imul(I.idiv(pw_eval(ps, a), I.ipt(fact)), hp) <> tshift_go(m, pw_der(pw_tl(ps), 1.0f64), a, h, F64.add(j, 1.0f64), I.imul(hp, h), F64.mul(fact, F64.add(j, 1.0f64)))

def tshift(+ps: List<&2, I.I>, +a: F64, +b: F64) -> List<&2, I.I>:
  tshift_go(List.length(&2, I.I, ps), ps, I.ipt(a), I.isub(I.ipt(b), I.ipt(a)), 0.0f64, I.ipt(1.0f64), 1.0f64)

def binom_go(n: Nat, +nn: F64, +k: F64, +i: F64, +acc: F64) -> F64:
  match n:
    case 0n: acc
    case 1n+m:
      Bool.pick(F64, F64.is_lt(k, i), acc, binom_go(m, nn, k, F64.add(i, 1.0f64), F64.div(F64.mul(acc, F64.add(F64.sub(nn, k), i)), i)))

def binom(+n: F64, +k: F64) -> F64:
  binom_go(64n, n, k, 1.0f64, 1.0f64)

def bz_coef_go(qs: List<&2, I.I>, +i: F64, +d: F64, +j: F64) -> I.I:
  match qs:
    case []: I.ipt(0.0f64)
    case q <> u:
      Bool.pick(I.I, F64.is_le(j, i), I.iadd(I.imul(X.ik(binom(i, j), binom(d, j)), q), bz_coef_go(u, i, d, F64.add(j, 1.0f64))), I.ipt(0.0f64))

def p2b_go(n: Nat, +qs: List<&2, I.I>, +d: F64, +i: F64) -> List<&2, I.I>:
  match n:
    case 0n: []
    case 1n+m: bz_coef_go(qs, i, d, 0.0f64) <> p2b_go(m, qs, d, F64.add(i, 1.0f64))

def p2b(+qs: List<&2, I.I>) -> List<&2, I.I>:
  +n = List.length(&2, I.I, qs)
  p2b_go(n, qs, U64.to_f64(U64.from_nat(Nat.sub(n, 1n))), 0.0f64)

def circ_coord(+c: F64, +r: F64, +u: F64, +v: F64, +lo: F64, +hi: F64) -> List<&2, I.I>:
  p2b(tshift(pw_comb(pw_d(), pw_n1(), pw_n2(), c, pmul(r, u), pmul(r, v)), lo, hi))

def cv_circle(c: V.Point, u: V.Dir, v: V.Dir, +r: F64, +lo: F64, +hi: F64) -> Cv:
  V.Pt{+cx, +cy, +cz} = c
  V.Dr{+ux, +uy, +uz} = u
  V.Dr{+vx, +vy, +vz} = v
  Cv{Rb{circ_coord(cx, r, ux, vx, lo, hi), circ_coord(cy, r, uy, vy, lo, hi), circ_coord(cz, r, uz, vz, lo, hi),
    p2b(tshift(X.vpts(pw_d()), lo, hi))}, lo, hi}

def box_go(d: Nat, fin: Bool, +b: List<&2, I.I>, +c: Cv, +lo: F64, +hi: F64) -> List<&2, I.I>:
  match d:
    case 0n: b
    case 1n+(+e):
      match fin:
        case True{}: b
        case False{}:
          +m = F64.mul(0.5f64, F64.add(lo, hi))
          +b1 = cv_box(c, I.I{lo, m})
          +b2 = cv_box(c, I.I{m, hi})
          X.vhull(box_go(e, X.vfin(b1), b1, c, lo, m), box_go(e, X.vfin(b2), b2, c, m, hi))

def cv_hbox(+c: Cv) -> List<&2, I.I>:
  +b = cv_box(c, I.I{0.0f64, 1.0f64})
  box_go(6n, X.vfin(b), b, c, 0.0f64, 1.0f64)
