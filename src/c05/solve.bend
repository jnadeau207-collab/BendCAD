import Base
import ../c00/types.bend as T

type Pt is Data:
  Pt{ x: Nat, y: Nat }

type Cn is Data:
  K_coinc{ id: U64, p: Pt, q: Pt }
  K_horiz{ id: U64, a: Pt, b: Pt }
  K_vert{ id: U64, a: Pt, b: Pt }
  K_dist{ id: U64, p: Pt, q: Pt, d: F64 }
  K_radius{ id: U64, r: Nat, v: F64 }
  K_angle{ id: U64, a: Pt, b: Pt, c: Pt, d: Pt, cs: F64, sn: F64 }
  K_par{ id: U64, a: Pt, b: Pt, c: Pt, d: Pt }
  K_perp{ id: U64, a: Pt, b: Pt, c: Pt, d: Pt }
  K_tan_lc{ id: U64, a: Pt, b: Pt, o: Pt, r: Nat }
  K_tan_cc{ id: U64, o1: Pt, r1: Nat, o2: Pt, r2: Nat }
  K_on_circ{ id: U64, p: Pt, o: Pt, r: Nat }
  K_fix{ id: U64, i: Nat, v: F64 }
  K_on_line{ id: U64, p: Pt, a: Pt, b: Pt }
  K_midpoint{ id: U64, m: Pt, a: Pt, b: Pt }
  K_equal{ id: U64, a: Pt, b: Pt, c: Pt, d: Pt }
  K_hdist{ id: U64, p: Pt, q: Pt, d: F64 }
  K_vdist{ id: U64, p: Pt, q: Pt, d: F64 }
  K_same{ id: U64, i: Nat, j: Nat }

type Gv is Data:
  Gv{ i: Nat, v: F64 }

type Rw is Data:
  Rw{ id: U64, ang: Bool, r: F64, g: List<&2, Gv> }

type Dr is Data:
  Dr{ id: U64, r: F64, v: List<&2, F64> }

type Sol is Data:
  Sv_ok{ ps: List<&2, F64>, dof: Nat, red: List<&2, U64> }
  Sv_conflict{ ids: List<&2, U64> }
  Sv_err{ kind: T.FailKind }

def fat(xs: List<&2, F64>, i: Nat) -> F64:
  match xs:
    case Nil{}: 0.0f64
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: fat(t, j)

def bat(xs: List<&2, Bool>, i: Nat) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: bat(t, j)

def flen(xs: List<&2, F64>) -> Nat:
  match xs:
    case Nil{}: 0n
    case h <> t: 1n+flen(t)

def blen(xs: List<&2, Bool>) -> Nat:
  match xs:
    case Nil{}: 0n
    case h <> t: 1n+blen(t)

def nfree(xs: List<&2, Bool>) -> Nat:
  match xs:
    case Nil{}: 0n
    case h <> t: Nat.add(Bool.pick(Nat, h, 1n, 0n), nfree(t))

def fin(x: F64) -> Bool:
  (F64.class(x) < 2 : U32)

def all_fin(xs: List<&2, F64>) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(fin(h), all_fin(t))

def pxi(p: Pt) -> Nat:
  Pt{x, y} = p
  x

def pyi(p: Pt) -> Nat:
  Pt{x, y} = p
  y

def px(+ps: List<&2, F64>, p: Pt) -> F64:
  fat(ps, pxi(p))

def py(+ps: List<&2, F64>, p: Pt) -> F64:
  fat(ps, pyi(p))

def m1() -> F64:
  F64.neg(1.0f64)

def hyp(+x: F64, +y: F64) -> F64:
  F64.sqrt(F64.fma(x, x, (y * y : F64)))

def side(+s: F64) -> F64:
  Bool.pick(F64, F64.is_lt(s, 0.0f64), m1(), 1.0f64)

def rows_pair(+id: U64, +p: Pt, +q: Pt, +ps: List<&2, F64>) -> List<&2, Rw>:
  [Rw{id, False{}, (px(ps, p) - px(ps, q) : F64), [Gv{pxi(p), 1.0f64}, Gv{pxi(q), m1()}]},
   Rw{id, False{}, (py(ps, p) - py(ps, q) : F64), [Gv{pyi(p), 1.0f64}, Gv{pyi(q), m1()}]}]

def row_ax(+id: U64, +i: Nat, +j: Nat, +ps: List<&2, F64>) -> List<&2, Rw>:
  [Rw{id, False{}, (fat(ps, i) - fat(ps, j) : F64), [Gv{i, 1.0f64}, Gv{j, m1()}]}]

def row_val(+id: U64, +i: Nat, +v: F64, +ps: List<&2, F64>) -> List<&2, Rw>:
  [Rw{id, False{}, (fat(ps, i) - v : F64), [Gv{i, 1.0f64}]}]

def row_len(+id: U64, +p: Pt, +q: Pt, +ps: List<&2, F64>, +k: F64,
    g: List<&2, Gv>) -> List<&2, Rw>:
  +dx = (px(ps, p) - px(ps, q) : F64)
  +dy = (py(ps, p) - py(ps, q) : F64)
  +l = hyp(dx, dy)
  +ux = (dx / l : F64)
  +uy = (dy / l : F64)
  [Rw{id, False{}, (l + k : F64),
    Gv{pxi(p), ux} <> Gv{pxi(q), F64.neg(ux)} <> Gv{pyi(p), uy} <> Gv{pyi(q), F64.neg(uy)} <> g}]

def rows_ang(+id: U64, +a: Pt, +b: Pt, +c: Pt, +d: Pt, +cs: F64, +sn: F64,
    +ps: List<&2, F64>) -> List<&2, Rw>:
  +ux = (px(ps, b) - px(ps, a) : F64)
  +uy = (py(ps, b) - py(ps, a) : F64)
  +vx = (px(ps, d) - px(ps, c) : F64)
  +vy = (py(ps, d) - py(ps, c) : F64)
  +wx = F64.fma(cs, ux, F64.neg((sn * uy : F64)))
  +wy = F64.fma(sn, ux, (cs * uy : F64))
  +nu = F64.fma(ux, ux, (uy * uy : F64))
  +nv = F64.fma(vx, vx, (vy * vy : F64))
  +nn = F64.sqrt((nu * nv : F64))
  +r = (F64.fma(wx, vy, F64.neg((wy * vx : F64))) / nn : F64)
  +gux = ((F64.fma(cs, vy, F64.neg((sn * vx : F64))) / nn : F64) - ((r * ux : F64) / nu : F64) : F64)
  +guy = ((F64.neg(F64.fma(sn, vy, (cs * vx : F64))) / nn : F64) - ((r * uy : F64) / nu : F64) : F64)
  +gvx = ((F64.neg(wy) / nn : F64) - ((r * vx : F64) / nv : F64) : F64)
  +gvy = ((wx / nn : F64) - ((r * vy : F64) / nv : F64) : F64)
  [Rw{id, True{}, r,
    [Gv{pxi(b), gux}, Gv{pxi(a), F64.neg(gux)}, Gv{pyi(b), guy}, Gv{pyi(a), F64.neg(guy)},
     Gv{pxi(d), gvx}, Gv{pxi(c), F64.neg(gvx)}, Gv{pyi(d), gvy}, Gv{pyi(c), F64.neg(gvy)}]}]

def sd_of(+a: Pt, +b: Pt, +o: Pt, +ps: List<&2, F64>) -> F64:
  +ux = (px(ps, b) - px(ps, a) : F64)
  +uy = (py(ps, b) - py(ps, a) : F64)
  +wx = (px(ps, o) - px(ps, a) : F64)
  +wy = (py(ps, o) - py(ps, a) : F64)
  (F64.fma(ux, wy, F64.neg((uy * wx : F64))) / hyp(ux, uy) : F64)

def row_sd(+id: U64, +a: Pt, +b: Pt, +o: Pt, +s: F64, +ps: List<&2, F64>, +k: F64,
    g: List<&2, Gv>) -> List<&2, Rw>:
  +ux = (px(ps, b) - px(ps, a) : F64)
  +uy = (py(ps, b) - py(ps, a) : F64)
  +wx = (px(ps, o) - px(ps, a) : F64)
  +wy = (py(ps, o) - py(ps, a) : F64)
  +n2 = F64.fma(ux, ux, (uy * uy : F64))
  +n = F64.sqrt(n2)
  +sd = (F64.fma(ux, wy, F64.neg((uy * wx : F64))) / n : F64)
  +gux = (s * ((wy / n : F64) - ((sd * ux : F64) / n2 : F64) : F64) : F64)
  +guy = (s * ((F64.neg(wx) / n : F64) - ((sd * uy : F64) / n2 : F64) : F64) : F64)
  +gwx = (s * (F64.neg(uy) / n : F64) : F64)
  +gwy = (s * (ux / n : F64) : F64)
  [Rw{id, False{}, F64.fma(s, sd, k),
    Gv{pxi(b), gux} <> Gv{pyi(b), guy} <> Gv{pxi(o), gwx} <> Gv{pyi(o), gwy}
     <> Gv{pxi(a), F64.neg((gux + gwx : F64))} <> Gv{pyi(a), F64.neg((guy + gwy : F64))} <> g}]

def rows_mid(+id: U64, +m: Pt, +a: Pt, +b: Pt, +ps: List<&2, F64>) -> List<&2, Rw>:
  [Rw{id, False{}, F64.fma(2.0f64, px(ps, m), F64.neg((px(ps, a) + px(ps, b) : F64))),
    [Gv{pxi(m), 2.0f64}, Gv{pxi(a), m1()}, Gv{pxi(b), m1()}]},
   Rw{id, False{}, F64.fma(2.0f64, py(ps, m), F64.neg((py(ps, a) + py(ps, b) : F64))),
    [Gv{pyi(m), 2.0f64}, Gv{pyi(a), m1()}, Gv{pyi(b), m1()}]}]

def rows_eq(+id: U64, +a: Pt, +b: Pt, +c: Pt, +d: Pt, +ps: List<&2, F64>) -> List<&2, Rw>:
  +dx = (px(ps, d) - px(ps, c) : F64)
  +dy = (py(ps, d) - py(ps, c) : F64)
  +l = hyp(dx, dy)
  +ux = (dx / l : F64)
  +uy = (dy / l : F64)
  row_len(id, b, a, ps, F64.neg(l),
    [Gv{pxi(d), F64.neg(ux)}, Gv{pxi(c), ux}, Gv{pyi(d), F64.neg(uy)}, Gv{pyi(c), uy}])

def row_off(+id: U64, +i: Nat, +j: Nat, +d: F64, +ps: List<&2, F64>) -> List<&2, Rw>:
  [Rw{id, False{}, ((fat(ps, j) - fat(ps, i) : F64) - d : F64), [Gv{j, 1.0f64}, Gv{i, m1()}]}]

def rows_tcc(+id: U64, +o1: Pt, +r1: Nat, +o2: Pt, +r2: Nat,
    +ps: List<&2, F64>, +ps0: List<&2, F64>) -> List<&2, Rw>:
  +a = fat(ps0, r1)
  +b = fat(ps0, r2)
  +inn = F64.is_lt(hyp((px(ps0, o1) - px(ps0, o2) : F64), (py(ps0, o1) - py(ps0, o2) : F64)),
    F64.max(a, b))
  +s = side((a - b : F64))
  +k1 = Bool.pick(F64, inn, F64.neg(s), m1())
  +k2 = Bool.pick(F64, inn, s, m1())
  row_len(id, o1, o2, ps, F64.fma(k1, fat(ps, r1), (k2 * fat(ps, r2) : F64)),
    [Gv{r1, k1}, Gv{r2, k2}])

def rows_of(c: Cn, +ps: List<&2, F64>, +ps0: List<&2, F64>) -> List<&2, Rw>:
  match c:
    case K_coinc{id, p, q}: rows_pair(id, p, q, ps)
    case K_horiz{id, a, b}: row_ax(id, pyi(a), pyi(b), ps)
    case K_vert{id, a, b}: row_ax(id, pxi(a), pxi(b), ps)
    case K_dist{id, p, q, d}: row_len(id, p, q, ps, F64.neg(d), [])
    case K_radius{id, r, v}: row_val(id, r, v, ps)
    case K_angle{id, a, b, c, d, cs, sn}: rows_ang(id, a, b, c, d, cs, sn, ps)
    case K_par{id, a, b, c, d}: rows_ang(id, a, b, c, d, 1.0f64, 0.0f64, ps)
    case K_perp{id, a, b, c, d}: rows_ang(id, a, b, c, d, 0.0f64, 1.0f64, ps)
    case K_tan_lc{id, +a, +b, +o, +r}:
      row_sd(id, a, b, o, side(sd_of(a, b, o, ps0)), ps, F64.neg(fat(ps, r)), [Gv{r, m1()}])
    case K_tan_cc{id, o1, r1, o2, r2}: rows_tcc(id, o1, r1, o2, r2, ps, ps0)
    case K_on_circ{id, p, o, +r}: row_len(id, p, o, ps, F64.neg(fat(ps, r)), [Gv{r, m1()}])
    case K_fix{id, i, v}: row_val(id, i, v, ps)
    case K_on_line{id, p, a, b}: row_sd(id, a, b, p, 1.0f64, ps, 0.0f64, [])
    case K_midpoint{id, m, a, b}: rows_mid(id, m, a, b, ps)
    case K_equal{id, a, b, c, d}: rows_eq(id, a, b, c, d, ps)
    case K_hdist{id, p, q, d}: row_off(id, pxi(p), pxi(q), d, ps)
    case K_vdist{id, p, q, d}: row_off(id, pyi(p), pyi(q), d, ps)
    case K_same{id, +i, +j}: row_off(id, i, j, 0.0f64, ps)

def all_rows(cs: List<&2, Cn>, +ps: List<&2, F64>, +ps0: List<&2, F64>) -> List<&2, Rw>:
  match cs:
    case Nil{}: []
    case h <> t: List.append(&2, Rw, rows_of(h, ps, ps0), all_rows(t, ps, ps0))

def g_fin(g: List<&2, Gv>) -> Bool:
  match g:
    case Nil{}: True{}
    case h <> t:
      Gv{i, v} = h
      Bool.and(fin(v), g_fin(t))

def rows_ok(rs: List<&2, Rw>) -> Bool:
  match rs:
    case Nil{}: True{}
    case h <> t:
      Rw{id, ang, r, g} = h
      Bool.and(Bool.and(fin(r), g_fin(g)), rows_ok(t))

def gsum(g: List<&2, Gv>, +k: Nat) -> F64:
  match g:
    case Nil{}: 0.0f64
    case h <> t:
      Gv{i, v} = h
      (Bool.pick(F64, Nat.is_eq(i, k), v, 0.0f64) + gsum(t, k) : F64)

def dense(n: Nat, +k: Nat, +g: List<&2, Gv>, +free: List<&2, Bool>,
    +w: F64) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m:
      Bool.pick(F64, bat(free, k), (gsum(g, k) * w : F64), 0.0f64)
        <> dense(m, 1n+k, g, free, w)

def drows(rs: List<&2, Rw>, +np: Nat, +free: List<&2, Bool>, +tl: F64,
    +ta: F64) -> List<&2, Dr>:
  match rs:
    case Nil{}: []
    case h <> t:
      Rw{id, ang, r, +g} = h
      +w = Bool.pick(F64, ang, (1.0f64 / ta : F64), (1.0f64 / tl : F64))
      Dr{id, (r * w : F64), dense(np, 0n, g, free, w)} <> drows(t, np, free, tl, ta)

def dr_v(d: Dr) -> List<&2, F64>:
  Dr{id, r, v} = d
  v

def dr_r(d: Dr) -> F64:
  Dr{id, r, v} = d
  r

def dr_id(d: Dr) -> U64:
  Dr{id, r, v} = d
  id

def dot(xs: List<&2, F64>, ys: List<&2, F64>) -> F64:
  match xs:
    case Nil{}: 0.0f64
    case x <> xt:
      match ys:
        case Nil{}: 0.0f64
        case y <> yt: F64.fma(x, y, dot(xt, yt))

def nrm(+xs: List<&2, F64>) -> F64:
  F64.sqrt(dot(xs, xs))

def axpy(+a: F64, xs: List<&2, F64>, ys: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case Nil{}: []
    case x <> xt:
      match ys:
        case Nil{}: []
        case y <> yt: F64.fma(a, x, y) <> axpy(a, xt, yt)

def scal(+a: F64, xs: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case Nil{}: []
    case x <> xt: (a * x : F64) <> scal(a, xt)

def zeros(n: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m: 0.0f64 <> zeros(m)

def res_of(ds: List<&2, Dr>) -> List<&2, F64>:
  match ds:
    case Nil{}: []
    case h <> t: dr_r(h) <> res_of(t)

def maxabs(xs: List<&2, F64>) -> F64:
  match xs:
    case Nil{}: 0.0f64
    case h <> t: F64.max(F64.abs(h), maxabs(t))

def colk(ds: List<&2, Dr>, +k: Nat) -> List<&2, F64>:
  match ds:
    case Nil{}: []
    case h <> t: fat(dr_v(h), k) <> colk(t, k)

def eye(n: Nat, +j: Nat, +k: Nat, +s: F64) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m: Bool.pick(F64, Nat.is_eq(j, k), s, 0.0f64) <> eye(m, 1n+j, k, s)

def cols(n: Nat, +k: Nat, +np: Nat, +ds: List<&2, Dr>,
    +s: F64) -> List<&2, List<&2, F64>>:
  match n:
    case 0n: []
    case 1n+m:
      List.append(&2, F64, colk(ds, k), eye(np, 0n, k, s)) <> cols(m, 1n+k, np, ds, s)

def diag(n: Nat, +k: Nat, +ds: List<&2, Dr>) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m:
      +c = colk(ds, k)
      dot(c, c) <> diag(m, 1n+k, ds)

def lin_res(ds: List<&2, Dr>, +dl: List<&2, F64>) -> List<&2, F64>:
  match ds:
    case Nil{}: []
    case h <> t:
      Dr{id, r, v} = h
      (r + dot(v, dl) : F64) <> lin_res(t, dl)

type Tri is Data:
  Tri{ d: F64, rs: List<&2, F64>, z: F64 }

def dots(+q: List<&2, F64>, cs: List<&2, List<&2, F64>>) -> List<&2, F64>:
  match cs:
    case Nil{}: []
    case h <> t: dot(q, h) <> dots(q, t)

def subs(+q: List<&2, F64>, cs: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match cs:
    case Nil{}: []
    case +h <> t: axpy(F64.neg(dot(q, h)), q, h) <> subs(q, t)

def mgs(n: Nat, cs: List<&2, List<&2, F64>>, +b: List<&2, F64>) -> List<&2, Tri>:
  match n:
    case 0n: []
    case 1n+m:
      match cs:
        case Nil{}: []
        case +a <> +rest:
          +r = nrm(a)
          +q = scal((1.0f64 / r : F64), a)
          +z = dot(q, b)
          Tri{r, dots(q, rest), z} <> mgs(m, subs(q, rest), axpy(F64.neg(z), q, b))

def back(ts: List<&2, Tri>) -> List<&2, F64>:
  match ts:
    case Nil{}: []
    case t <> rest:
      Tri{d, rs, z} = t
      +xs = back(rest)
      ((z - dot(rs, xs) : F64) / d : F64) <> xs

def mask(free: List<&2, Bool>, xs: List<&2, F64>) -> List<&2, F64>:
  match free:
    case Nil{}: []
    case f <> ft:
      match xs:
        case Nil{}: []
        case x <> xt: Bool.pick(F64, f, x, 0.0f64) <> mask(ft, xt)

type Cx is Data:
  Cx{ cs: List<&2, Cn>, ps0: List<&2, F64>, free: List<&2, Bool>, np: Nat,
    tl: F64, ta: F64, lmin: F64, lmax: F64 }

type St is Data:
  St{ ps: List<&2, F64>, lam: F64, nu: F64, cost: F64, done: Bool }

def st_done(s: St) -> Bool:
  St{ps, lam, nu, cost, done} = s
  done

def st_ps(s: St) -> List<&2, F64>:
  St{ps, lam, nu, cost, done} = s
  ps

def drs_at(cx: Cx, +ps: List<&2, F64>) -> List<&2, Dr>:
  Cx{cs, ps0, +free, +np, +tl, +ta, lmin, lmax} = cx
  drows(all_rows(cs, ps, ps0), np, free, tl, ta)

def ok_at(cx: Cx, +ps: List<&2, F64>) -> Bool:
  Cx{cs, ps0, free, np, tl, ta, lmin, lmax} = cx
  rows_ok(all_rows(cs, ps, ps0))

def p2(n: Nat) -> F64:
  match n:
    case 0n: 1.0f64
    case 1n+m: (0.5f64 * p2(m) : F64)

def cx_free(c: Cx) -> List<&2, Bool>:
  Cx{cs, ps0, free, np, tl, ta, lmin, lmax} = c
  free

def cx_np(c: Cx) -> Nat:
  Cx{cs, ps0, free, np, tl, ta, lmin, lmax} = c
  np

def cx_lmin(c: Cx) -> F64:
  Cx{cs, ps0, free, np, tl, ta, lmin, lmax} = c
  lmin

def cx_lmax(c: Cx) -> F64:
  Cx{cs, ps0, free, np, tl, ta, lmin, lmax} = c
  lmax

def gain(+rho: F64) -> F64:
  +t = ((2.0f64 * rho : F64) - 1.0f64 : F64)
  F64.max((1.0f64 / 3.0f64 : F64), (1.0f64 - ((t * t : F64) * t : F64) : F64))

def lm_step(+cx: Cx, st: St) -> St:
  St{+ps, +lam, +nu, +cost, done} = st
  +np = cx_np(cx)
  +ds = drs_at(cx, ps)
  +dl = mask(cx_free(cx), back(mgs(np, cols(np, 0n, np, ds, F64.sqrt(lam)),
    List.append(&2, F64, scal(m1(), res_of(ds)), zeros(np)))))
  +lr = lin_res(ds, dl)
  +pred = (cost - dot(lr, lr) : F64)
  +q = axpy(1.0f64, dl, ps)
  +rt = res_of(drs_at(cx, q))
  +c2 = dot(rt, rt)
  +tiny = F64.is_le(nrm(dl), (p2(45n) * (1.0f64 + nrm(ps) : F64) : F64))
  +up = (lam * nu : F64)
  Bool.pick(St, Bool.and(Bool.and(ok_at(cx, q), fin(c2)), Bool.and(F64.is_lt(c2, cost), F64.is_lt(0.0f64, pred))),
    St{q, F64.max((lam * gain(((cost - c2 : F64) / pred : F64)) : F64), cx_lmin(cx)), 2.0f64, c2,
      Bool.or(tiny, F64.is_eq(c2, 0.0f64))},
    St{ps, up, (2.0f64 * nu : F64), cost, Bool.or(tiny, F64.is_lt(cx_lmax(cx), up))})

def lm(fuel: Nat, done: Bool, +cx: Cx, +st: St) -> St:
  match fuel:
    case 0n: st
    case 1n+f:
      match done:
        case True{}: st
        case False{}:
          +s2 = lm_step(cx, st)
          lm(f, st_done(s2), cx, s2)

def jtr(ds: List<&2, Dr>, acc: List<&2, F64>) -> List<&2, F64>:
  match ds:
    case Nil{}: acc
    case h <> t:
      Dr{id, r, v} = h
      jtr(t, axpy(r, v, acc))

def fro2(ds: List<&2, Dr>) -> F64:
  match ds:
    case Nil{}: 0.0f64
    case h <> t:
      Dr{id, r, +v} = h
      (dot(v, v) + fro2(t) : F64)

def id_has(xs: List<&2, U64>, +x: U64) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t: Bool.or(U64.is_eq(h, x), id_has(t, x))

def id_add(+xs: List<&2, U64>, +x: U64) -> List<&2, U64>:
  Bool.pick(List<&2, U64>, id_has(xs, x), xs, List.append(&2, U64, xs, [x]))

def proj(qs: List<&2, List<&2, F64>>, v: List<&2, F64>) -> List<&2, F64>:
  match qs:
    case Nil{}: v
    case +q <> t:
      +w = v
      proj(t, axpy(F64.neg(dot(q, w)), q, w))

type Gs is Data:
  Gs{ qs: List<&2, List<&2, F64>>, n: Nat, red: List<&2, U64> }

def gs_add(acc: Gs, +id: U64, +v: List<&2, F64>) -> Gs:
  Gs{+qs, +n, +red} = acc
  +w = proj(qs, proj(qs, v))
  +nw = nrm(w)
  Bool.pick(Gs, F64.is_le(nw, (p2(26n) * nrm(v) : F64)),
    Gs{qs, n, id_add(red, id)},
    Gs{scal((1.0f64 / nw : F64), w) <> qs, 1n+n, red})

def gs(ds: List<&2, Dr>, acc: Gs) -> Gs:
  match ds:
    case Nil{}: acc
    case +h <> t: gs(t, gs_add(acc, dr_id(h), dr_v(h)))

def viol(ds: List<&2, Dr>, +acc: List<&2, U64>) -> List<&2, U64>:
  match ds:
    case Nil{}: acc
    case +h <> t:
      viol(t, Bool.pick(List<&2, U64>, F64.is_lt(1.0f64, F64.abs(dr_r(h))), id_add(acc, dr_id(h)), acc))

def canon(xs: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case Nil{}: []
    case h <> t: (h + 0.0f64 : F64) <> canon(t)

def ok_of(g: Gs, +ps: List<&2, F64>, +k: Nat) -> Sol:
  Gs{qs, n, red} = g
  Sv_ok{canon(ps), Nat.sub(k, n), red}

def conflict_go(stat: Bool, +ds: List<&2, Dr>) -> Sol:
  match stat:
    case True{}: Sv_conflict{viol(ds, [])}
    case False{}: Sv_err{T.F_nonconverged{}}

def classify_go(solved: Bool, +cx: Cx, +ps: List<&2, F64>, +ds: List<&2, Dr>) -> Sol:
  match solved:
    case True{}:
      ok_of(gs(ds, Gs{[], 0n, []}), ps, nfree(cx_free(cx)))
    case False{}:
      +rt = res_of(ds)
      conflict_go(F64.is_le(nrm(jtr(ds, zeros(cx_np(cx)))),
        ((p2(26n) * F64.sqrt(fro2(ds)) : F64) * nrm(rt) : F64)), ds)

def classify(+cx: Cx, +ps: List<&2, F64>) -> Sol:
  +ds = drs_at(cx, ps)
  classify_go(F64.is_le(maxabs(res_of(ds)), 1.0f64), cx, ps, ds)

def pt_ok(p: Pt, +np: Nat) -> Bool:
  Pt{x, y} = p
  Bool.and(Nat.is_lt(x, np), Nat.is_lt(y, np))

def pt_eq(p: Pt, q: Pt) -> Bool:
  Pt{x, y} = p
  Pt{u, v} = q
  Bool.and(Nat.is_eq(x, u), Nat.is_eq(y, v))

def two_ok(+p: Pt, +q: Pt, +np: Nat) -> Bool:
  Bool.and(Bool.not(pt_eq(p, q)), Bool.and(pt_ok(p, np), pt_ok(q, np)))

def lines_ok(+a: Pt, +b: Pt, +c: Pt, +d: Pt, +np: Nat) -> Bool:
  +same = Bool.or(Bool.and(pt_eq(a, c), pt_eq(b, d)), Bool.and(pt_eq(a, d), pt_eq(b, c)))
  Bool.and(Bool.not(same), Bool.and(two_ok(a, b, np), two_ok(c, d, np)))

def pos(+x: F64) -> Bool:
  Bool.and(fin(x), F64.is_lt(0.0f64, x))

def cn_ok(c: Cn, +np: Nat) -> Bool:
  match c:
    case K_coinc{id, p, q}: two_ok(p, q, np)
    case K_horiz{id, a, b}: two_ok(a, b, np)
    case K_vert{id, a, b}: two_ok(a, b, np)
    case K_dist{id, p, q, d}: Bool.and(two_ok(p, q, np), pos(d))
    case K_radius{id, r, v}: Bool.and(Nat.is_lt(r, np), pos(v))
    case K_angle{id, a, b, c, d, +cs, +sn}:
      +e = F64.abs((F64.fma(cs, cs, (sn * sn : F64)) - 1.0f64 : F64))
      Bool.and(lines_ok(a, b, c, d, np), Bool.and(Bool.and(fin(cs), fin(sn)), F64.is_le(e, p2(40n))))
    case K_par{id, a, b, c, d}: lines_ok(a, b, c, d, np)
    case K_perp{id, a, b, c, d}: lines_ok(a, b, c, d, np)
    case K_tan_lc{id, a, b, o, r}:
      Bool.and(two_ok(a, b, np), Bool.and(pt_ok(o, np), Nat.is_lt(r, np)))
    case K_tan_cc{id, o1, r1, o2, r2}:
      Bool.and(two_ok(o1, o2, np), Bool.and(Nat.is_lt(r1, np), Nat.is_lt(r2, np)))
    case K_on_circ{id, p, o, r}: Bool.and(two_ok(p, o, np), Nat.is_lt(r, np))
    case K_fix{id, i, v}: Bool.and(Nat.is_lt(i, np), fin(v))
    case K_on_line{id, p, a, b}: Bool.and(two_ok(a, b, np), pt_ok(p, np))
    case K_midpoint{id, m, a, b}: Bool.and(two_ok(a, b, np), pt_ok(m, np))
    case K_equal{id, a, b, c, d}: Bool.and(two_ok(a, b, np), two_ok(c, d, np))
    case K_hdist{id, p, q, d}: Bool.and(two_ok(p, q, np), fin(d))
    case K_vdist{id, p, q, d}: Bool.and(two_ok(p, q, np), fin(d))
    case K_same{id, +i, +j}: Bool.and(Bool.not(Nat.is_eq(i, j)), Bool.and(Nat.is_lt(i, np), Nat.is_lt(j, np)))

def cn_id(c: Cn) -> U64:
  match c:
    case K_coinc{id, p, q}: id
    case K_horiz{id, a, b}: id
    case K_vert{id, a, b}: id
    case K_dist{id, p, q, d}: id
    case K_radius{id, r, v}: id
    case K_angle{id, a, b, c, d, cs, sn}: id
    case K_par{id, a, b, c, d}: id
    case K_perp{id, a, b, c, d}: id
    case K_tan_lc{id, a, b, o, r}: id
    case K_tan_cc{id, o1, r1, o2, r2}: id
    case K_on_circ{id, p, o, r}: id
    case K_fix{id, i, v}: id
    case K_on_line{id, p, a, b}: id
    case K_midpoint{id, m, a, b}: id
    case K_equal{id, a, b, c, d}: id
    case K_hdist{id, p, q, d}: id
    case K_vdist{id, p, q, d}: id
    case K_same{id, i, j}: id

def cns_ok(cs: List<&2, Cn>, +np: Nat, +seen: List<&2, U64>) -> Bool:
  match cs:
    case Nil{}: True{}
    case +h <> t:
      +id = cn_id(h)
      Bool.and(Bool.and(cn_ok(h, np), Bool.not(id_has(seen, id))), cns_ok(t, np, id <> seen))

def mk_cx(cs: List<&2, Cn>, ps0: List<&2, F64>, free: List<&2, Bool>, np: Nat,
    tl: F64, ta: F64, lmin: F64, lmax: F64) -> Cx:
  Cx{cs, ps0, free, np, tl, ta, lmin, lmax}

def run(ok: Bool, +cs: List<&2, Cn>, +ps: List<&2, F64>, +free: List<&2, Bool>, +np: Nat,
    +tl: F64, +ta: F64, fuel: Nat) -> Sol:
  match ok:
    case False{}: Sv_err{T.F_invalid{}}
    case True{}:
      +ds = drows(all_rows(cs, ps, ps), np, free, tl, ta)
      +rt = res_of(ds)
      +l0 = (p2(10n) * F64.max(maxabs(diag(np, 0n, ds)), 1.0f64) : F64)
      +cx = mk_cx(cs, ps, free, np, tl, ta, (p2(30n) * l0 : F64), (1152921504606846976.0f64 * l0 : F64))
      classify(cx, st_ps(lm(fuel, False{}, cx, St{ps, l0, 2.0f64, dot(rt, rt), False{}})))

def solve(+ps: List<&2, F64>, +free: List<&2, Bool>, +cs: List<&2, Cn>, tol: T.Tol,
    fuel: Nat) -> Sol:
  T.Tol{+lin, +ang, par, apx, imp} = tol
  +np = flen(ps)
  +valid = Bool.and(Bool.and(Bool.and(all_fin(ps), Nat.is_eq(blen(free), np)),
    Bool.and(T.tol_pos(lin), T.tol_pos(ang))), cns_ok(cs, np, []))
  run(Bool.and(valid, rows_ok(all_rows(cs, ps, ps))), cs, ps, free, np, lin, ang, fuel)

def ids_tail(xs: List<&2, U64>) -> String:
  match xs:
    case Nil{}: ""
    case h <> t: "," ++ U64.show(h) ++ ids_tail(t)

def ids_show(xs: List<&2, U64>) -> String:
  match xs:
    case Nil{}: ""
    case h <> t: U64.show(h) ++ ids_tail(t)

def vals_show(xs: List<&2, F64>) -> String:
  match xs:
    case Nil{}: ""
    case h <> t: " " ++ F64.show(h) ++ vals_show(t)

def sol_show(s: Sol) -> String:
  match s:
    case Sv_ok{ps, dof, red}:
      "ok dof=" ++ Nat.show(dof) ++ " red=[" ++ ids_show(red) ++ "] ps=" ++ vals_show(ps)
    case Sv_conflict{ids}: "conflict [" ++ ids_show(ids) ++ "]"
    case Sv_err{kind}: "err " ++ T.FailKind.show(kind)
