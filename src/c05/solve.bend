import Base
import ../c00/types.bend as T
import ../base/par.bend as P
import ./sqr.bend as Q

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
  Dr{ id: U64, r: F64, v: List<&2, Q.Sv> }

type Sol is Data:
  Sv_ok{ ps: List<&2, F64>, dof: Nat, red: List<&2, U64> }
  Sv_conflict{ ids: List<&2, U64> }
  Sv_err{ kind: T.FailKind }

def fat(xs: P.Tb<&2, F64>, i: Nat) -> F64:
  P.tb_get(F64, xs, U32.from_nat(i))

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

def px(+ps: P.Tb<&2, F64>, p: Pt) -> F64:
  fat(ps, pxi(p))

def py(+ps: P.Tb<&2, F64>, p: Pt) -> F64:
  fat(ps, pyi(p))

def m1() -> F64:
  F64.neg(1.0f64)

def hyp(+x: F64, +y: F64) -> F64:
  F64.sqrt(F64.fma(x, x, (y * y : F64)))

def side(+s: F64) -> F64:
  Bool.pick(F64, F64.is_lt(s, 0.0f64), m1(), 1.0f64)

def rows_pair(+id: U64, +p: Pt, +q: Pt, +ps: P.Tb<&2, F64>) -> List<&2, Rw>:
  [Rw{id, False{}, (px(ps, p) - px(ps, q) : F64), [Gv{pxi(p), 1.0f64}, Gv{pxi(q), m1()}]},
   Rw{id, False{}, (py(ps, p) - py(ps, q) : F64), [Gv{pyi(p), 1.0f64}, Gv{pyi(q), m1()}]}]

def row_dir(+id: U64, +bj: Nat, +aj: Nat, +bk: Nat, +ak: Nat, +ps: P.Tb<&2, F64>) -> List<&2, Rw>:
  +uj = (fat(ps, bj) - fat(ps, aj) : F64)
  +uk = (fat(ps, bk) - fat(ps, ak) : F64)
  +l2 = F64.fma(uj, uj, (uk * uk : F64))
  +l = F64.sqrt(l2)
  +l3 = (l * l2 : F64)
  +gj = ((uk * uk : F64) / l3 : F64)
  +gk = (F64.neg((uj * uk : F64)) / l3 : F64)
  [Rw{id, True{}, (uj / l : F64), [Gv{bj, gj}, Gv{aj, F64.neg(gj)}, Gv{bk, gk}, Gv{ak, F64.neg(gk)}]}]

def row_val(+id: U64, +i: Nat, +v: F64, +ps: P.Tb<&2, F64>) -> List<&2, Rw>:
  [Rw{id, False{}, (fat(ps, i) - v : F64), [Gv{i, 1.0f64}]}]

def row_len(+id: U64, +p: Pt, +q: Pt, +ps: P.Tb<&2, F64>, +k: F64,
    g: List<&2, Gv>) -> List<&2, Rw>:
  +dx = (px(ps, p) - px(ps, q) : F64)
  +dy = (py(ps, p) - py(ps, q) : F64)
  +l = hyp(dx, dy)
  +ux = (dx / l : F64)
  +uy = (dy / l : F64)
  [Rw{id, False{}, (l + k : F64),
    Gv{pxi(p), ux} <> Gv{pxi(q), F64.neg(ux)} <> Gv{pyi(p), uy} <> Gv{pyi(q), F64.neg(uy)} <> g}]

def rows_ang(+id: U64, +a: Pt, +b: Pt, +c: Pt, +d: Pt, +cs: F64, +sn: F64, dir: Bool,
    +ps: P.Tb<&2, F64>) -> List<&2, Rw>:
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
  +flip = Bool.and(dir, F64.is_lt(F64.fma(wx, vx, (wy * vy : F64)), 0.0f64))
  +k = Bool.pick(F64, flip, m1(), 1.0f64)
  +gux = (k * ((F64.fma(cs, vy, F64.neg((sn * vx : F64))) / nn : F64) - ((r * ux : F64) / nu : F64) : F64) : F64)
  +guy = (k * ((F64.neg(F64.fma(sn, vy, (cs * vx : F64))) / nn : F64) - ((r * uy : F64) / nu : F64) : F64) : F64)
  +gvx = (k * ((F64.neg(wy) / nn : F64) - ((r * vx : F64) / nv : F64) : F64) : F64)
  +gvy = (k * ((wx / nn : F64) - ((r * vy : F64) / nv : F64) : F64) : F64)
  [Rw{id, True{}, Bool.pick(F64, flip, (side(r) * (2.0f64 - F64.abs(r) : F64) : F64), r),
    [Gv{pxi(b), gux}, Gv{pxi(a), F64.neg(gux)}, Gv{pyi(b), guy}, Gv{pyi(a), F64.neg(guy)},
     Gv{pxi(d), gvx}, Gv{pxi(c), F64.neg(gvx)}, Gv{pyi(d), gvy}, Gv{pyi(c), F64.neg(gvy)}]}]

def sd_of(+a: Pt, +b: Pt, +o: Pt, +ps: P.Tb<&2, F64>) -> F64:
  +ux = (px(ps, b) - px(ps, a) : F64)
  +uy = (py(ps, b) - py(ps, a) : F64)
  +wx = (px(ps, o) - px(ps, a) : F64)
  +wy = (py(ps, o) - py(ps, a) : F64)
  (F64.fma(ux, wy, F64.neg((uy * wx : F64))) / hyp(ux, uy) : F64)

def row_sd(+id: U64, +a: Pt, +b: Pt, +o: Pt, +s: F64, +ps: P.Tb<&2, F64>, +k: F64,
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

def rows_mid(+id: U64, +m: Pt, +a: Pt, +b: Pt, +ps: P.Tb<&2, F64>) -> List<&2, Rw>:
  [Rw{id, False{}, F64.fma(2.0f64, px(ps, m), F64.neg((px(ps, a) + px(ps, b) : F64))),
    [Gv{pxi(m), 2.0f64}, Gv{pxi(a), m1()}, Gv{pxi(b), m1()}]},
   Rw{id, False{}, F64.fma(2.0f64, py(ps, m), F64.neg((py(ps, a) + py(ps, b) : F64))),
    [Gv{pyi(m), 2.0f64}, Gv{pyi(a), m1()}, Gv{pyi(b), m1()}]}]

def rows_eq(+id: U64, +a: Pt, +b: Pt, +c: Pt, +d: Pt, +ps: P.Tb<&2, F64>) -> List<&2, Rw>:
  +dx = (px(ps, d) - px(ps, c) : F64)
  +dy = (py(ps, d) - py(ps, c) : F64)
  +l = hyp(dx, dy)
  +ux = (dx / l : F64)
  +uy = (dy / l : F64)
  row_len(id, b, a, ps, F64.neg(l),
    [Gv{pxi(d), F64.neg(ux)}, Gv{pxi(c), ux}, Gv{pyi(d), F64.neg(uy)}, Gv{pyi(c), uy}])

def row_off(+id: U64, +i: Nat, +j: Nat, +d: F64, +ps: P.Tb<&2, F64>) -> List<&2, Rw>:
  [Rw{id, False{}, ((fat(ps, j) - fat(ps, i) : F64) - d : F64), [Gv{j, 1.0f64}, Gv{i, m1()}]}]

def rows_tcc(+id: U64, +o1: Pt, +r1: Nat, +o2: Pt, +r2: Nat,
    +ps: P.Tb<&2, F64>, +ps0: P.Tb<&2, F64>) -> List<&2, Rw>:
  +a = fat(ps0, r1)
  +b = fat(ps0, r2)
  +inn = F64.is_lt(hyp((px(ps0, o1) - px(ps0, o2) : F64), (py(ps0, o1) - py(ps0, o2) : F64)),
    F64.max(a, b))
  +s = side((a - b : F64))
  +k1 = Bool.pick(F64, inn, F64.neg(s), m1())
  +k2 = Bool.pick(F64, inn, s, m1())
  row_len(id, o1, o2, ps, F64.fma(k1, fat(ps, r1), (k2 * fat(ps, r2) : F64)),
    [Gv{r1, k1}, Gv{r2, k2}])

def rows_of(c: Cn, +ps: P.Tb<&2, F64>, +ps0: P.Tb<&2, F64>) -> List<&2, Rw>:
  match c:
    case K_coinc{id, p, q}: rows_pair(id, p, q, ps)
    case K_horiz{id, +a, +b}: row_dir(id, pyi(b), pyi(a), pxi(b), pxi(a), ps)
    case K_vert{id, +a, +b}: row_dir(id, pxi(b), pxi(a), pyi(b), pyi(a), ps)
    case K_dist{id, p, q, d}: row_len(id, p, q, ps, F64.neg(d), [])
    case K_radius{id, r, v}: row_val(id, r, v, ps)
    case K_angle{id, a, b, c, d, cs, sn}: rows_ang(id, a, b, c, d, cs, sn, True{}, ps)
    case K_par{id, a, b, c, d}: rows_ang(id, a, b, c, d, 1.0f64, 0.0f64, False{}, ps)
    case K_perp{id, a, b, c, d}: rows_ang(id, a, b, c, d, 0.0f64, 1.0f64, False{}, ps)
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

def all_rows(cs: List<&2, Cn>, +ps: P.Tb<&2, F64>, +ps0: P.Tb<&2, F64>) -> List<&2, Rw>:
  match cs:
    case Nil{}: []
    case h <> t: List.append(&2, Rw, rows_of(h, ps, ps0), all_rows(t, ps, ps0))

def rad_pos(+ps: P.Tb<&2, F64>, +r: Nat) -> Bool:
  F64.is_lt(0.0f64, fat(ps, r))

def cn_rad(c: Cn, +ps: P.Tb<&2, F64>) -> Bool:
  match c:
    case K_radius{id, r, v}: rad_pos(ps, r)
    case K_tan_lc{id, a, b, o, r}: rad_pos(ps, r)
    case K_tan_cc{id, o1, r1, o2, r2}: Bool.and(rad_pos(ps, r1), rad_pos(ps, r2))
    case K_on_circ{id, p, o, r}: rad_pos(ps, r)
    case _: True{}

def rad_ok(cs: List<&2, Cn>, +ps: P.Tb<&2, F64>) -> Bool:
  match cs:
    case Nil{}: True{}
    case h <> t: Bool.and(cn_rad(h, ps), rad_ok(t, ps))

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

def gv_sv(g: List<&2, Gv>) -> List<&2, Q.Sv>:
  match g:
    case Nil{}: []
    case h <> t:
      Gv{i, v} = h
      Q.Sv{U32.from_nat(i), v} <> gv_sv(t)

def so_sv(s: P.So<&2, Q.Sv>) -> List<&2, Q.Sv>:
  P.So{ok, xs} = s
  xs

type Ac is Data:
  Ac{ c: U32, a: F64, out: List<&2, Q.Sv> }

def ac_c(ac: Ac) -> U32:
  Ac{c, a, out} = ac
  c

def ac_step(same: Bool, ac: Ac, +d: U32, +v: F64) -> Ac:
  match same:
    case True{}:
      Ac{c, a, out} = ac
      Ac{c, (a + v : F64), out}
    case False{}:
      Ac{c, a, out} = ac
      Ac{d, v, Q.Sv{c, a} <> out}

def ac_go(xs: List<&2, Q.Sv>, +ac: Ac) -> Ac:
  match xs:
    case Nil{}: ac
    case h <> t:
      Q.Sv{+d, +v} = h
      ac_go(t, ac_step(U32.is_eq(ac_c(ac), d), ac, d, v))

def ac_fin(ac: Ac) -> List<&2, Q.Sv>:
  Ac{c, a, out} = ac
  List.reverse(&2, Q.Sv, Q.Sv{c, a} <> out)

def groups(xs: List<&2, Q.Sv>) -> List<&2, Q.Sv>:
  match xs:
    case Nil{}: []
    case h <> t:
      Q.Sv{c, v} = h
      ac_fin(ac_go(t, Ac{c, v, []}))

def col_sums(+xs: List<&2, Q.Sv>) -> List<&2, Q.Sv>:
  groups(so_sv(P.msort(~Q.Sv, ~Q.sv_cmp, xs)))

def sv_keep(k: Bool, +c: U32, +v: F64, rest: List<&2, Q.Sv>) -> List<&2, Q.Sv>:
  match k:
    case True{}: Q.Sv{c, v} <> rest
    case False{}: rest

def sv_wm(xs: List<&2, Q.Sv>, +ft: P.Tb<&2, Bool>, +w: F64) -> List<&2, Q.Sv>:
  match xs:
    case Nil{}: []
    case h <> t:
      Q.Sv{+c, v} = h
      sv_keep(P.tb_get(Bool, ft, c), c, (v * w : F64), sv_wm(t, ft, w))

def drows(rs: List<&2, Rw>, +ft: P.Tb<&2, Bool>, +tl: F64, +ta: F64) -> List<&2, Dr>:
  match rs:
    case Nil{}: []
    case h <> t:
      Rw{id, ang, r, g} = h
      +w = Bool.pick(F64, ang, (1.0f64 / ta : F64), (1.0f64 / tl : F64))
      Dr{id, (r * w : F64), sv_wm(col_sums(gv_sv(g)), ft, w)} <> drows(t, ft, tl, ta)

def dr_v(d: Dr) -> List<&2, Q.Sv>:
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

def res_of(ds: List<&2, Dr>) -> List<&2, F64>:
  match ds:
    case Nil{}: []
    case h <> t: dr_r(h) <> res_of(t)

def maxabs(xs: List<&2, F64>) -> F64:
  match xs:
    case Nil{}: 0.0f64
    case h <> t: F64.max(F64.abs(h), maxabs(t))

def sv_sq(xs: List<&2, Q.Sv>) -> F64:
  match xs:
    case Nil{}: 0.0f64
    case h <> t:
      Q.Sv{c, +v} = h
      F64.fma(v, v, sv_sq(t))

def sv_scale(xs: List<&2, Q.Sv>, +k: F64, acc: List<&2, Q.Sv>) -> List<&2, Q.Sv>:
  match xs:
    case Nil{}: acc
    case h <> t:
      Q.Sv{c, v} = h
      sv_scale(t, k, Q.Sv{c, (v * k : F64)} <> acc)

def sv_sqs(xs: List<&2, Q.Sv>, acc: List<&2, Q.Sv>) -> List<&2, Q.Sv>:
  match xs:
    case Nil{}: acc
    case h <> t:
      Q.Sv{c, +v} = h
      sv_sqs(t, Q.Sv{c, (v * v : F64)} <> acc)

def jr_all(ds: List<&2, Dr>) -> List<&2, Q.Sv>:
  match ds:
    case Nil{}: []
    case h <> t:
      Dr{id, r, v} = h
      sv_scale(v, r, jr_all(t))

def sq_all(ds: List<&2, Dr>) -> List<&2, Q.Sv>:
  match ds:
    case Nil{}: []
    case h <> t: sv_sqs(dr_v(h), sq_all(t))

def sv_max(xs: List<&2, Q.Sv>) -> F64:
  match xs:
    case Nil{}: 0.0f64
    case h <> t: F64.max(F64.abs(Q.sv_v(h)), sv_max(t))

def sv_nrm(+xs: List<&2, Q.Sv>) -> F64:
  F64.sqrt(sv_sq(xs))

def col_max(+ds: List<&2, Dr>) -> F64:
  sv_max(col_sums(sq_all(ds)))

def jtr_nrm(+ds: List<&2, Dr>) -> F64:
  sv_nrm(col_sums(jr_all(ds)))

def fro2(ds: List<&2, Dr>) -> F64:
  match ds:
    case Nil{}: 0.0f64
    case h <> t: (sv_sq(dr_v(h)) + fro2(t) : F64)

def lin_res(ds: List<&2, Dr>, +dt: P.Tb<&2, F64>) -> List<&2, F64>:
  match ds:
    case Nil{}: []
    case h <> t:
      Dr{id, r, v} = h
      (r + Q.sdot(v, dt) : F64) <> lin_res(t, dt)

type Tj is Data:
  Tj{ c: U32, j: U32, v: F64 }

def tj_c(x: Tj) -> U32:
  Tj{c, j, v} = x
  c

def tj_cmp_go(+a: Tj, +b: Tj) -> P.Sgn:
  P.u_cmp(tj_c(a), tj_c(b))

def tj_cmp(a: Tj, b: Tj) -> P.Sgn:
  tj_cmp_go(a, b)

def tj_row(xs: List<&2, Q.Sv>, +j: U32, acc: List<&2, Tj>) -> List<&2, Tj>:
  match xs:
    case Nil{}: acc
    case h <> t:
      Q.Sv{c, v} = h
      Tj{c, j, v} <> tj_row(t, j, acc)

def tj_all(ds: List<&2, Dr>, +j: U32) -> List<&2, Tj>:
  match ds:
    case Nil{}: []
    case h <> t: tj_row(dr_v(h), j, tj_all(t, (j + 1 : U32)))

type Bg is Data:
  Bg{ c: U32, cur: List<&2, Q.Sv>, out: List<&2, Q.Rr> }

def bg_c(b: Bg) -> U32:
  Bg{c, cur, out} = b
  c

def bg_step(same: Bool, b: Bg, x: Tj) -> Bg:
  match same:
    case True{}:
      Bg{c, cur, out} = b
      Tj{xc, j, v} = x
      Bg{c, Q.Sv{j, v} <> cur, out}
    case False{}:
      Bg{c, cur, out} = b
      Tj{xc, j, v} = x
      Bg{xc, [Q.Sv{j, v}], Q.Rr{List.reverse(&2, Q.Sv, cur), 0.0f64} <> out}

def bg_go(xs: List<&2, Tj>, +b: Bg) -> Bg:
  match xs:
    case Nil{}: b
    case +x <> t: bg_go(t, bg_step(U32.is_eq(tj_c(x), bg_c(b)), b, x))

def bg_fin(b: Bg) -> List<&2, Q.Rr>:
  Bg{c, cur, out} = b
  Q.Rr{List.reverse(&2, Q.Sv, cur), 0.0f64} <> out

def so_tj(s: P.So<&2, Tj>) -> List<&2, Tj>:
  P.So{ok, xs} = s
  xs

def brows(xs: List<&2, Tj>) -> List<&2, Q.Rr>:
  match xs:
    case Nil{}: []
    case h <> t:
      Tj{c, j, v} = h
      bg_fin(bg_go(t, Bg{c, [Q.Sv{j, v}], []}))

def dr_nrms(ds: List<&2, Dr>) -> List<&2, F64>:
  match ds:
    case Nil{}: []
    case h <> t: sv_nrm(dr_v(h)) <> dr_nrms(t)

def dr_ids(ds: List<&2, Dr>) -> List<&2, U64>:
  match ds:
    case Nil{}: []
    case h <> t: dr_id(h) <> dr_ids(t)

def id_keep(k: Bool, +x: U64, rest: List<&2, U64>) -> List<&2, U64>:
  match k:
    case True{}: x <> rest
    case False{}: rest

def dedup_go(xs: List<&2, U64>, +prev: U64, first: Bool) -> List<&2, U64>:
  match xs:
    case Nil{}: []
    case +h <> t: id_keep(Bool.or(first, Bool.not(U64.is_eq(h, prev))), h, dedup_go(t, h, False{}))

def dedup(+xs: List<&2, U64>) -> List<&2, U64>:
  dedup_go(xs, 0u64, True{})

def js_ids(js: List<&2, U32>, +it: P.Tb<&2, U64>) -> List<&2, U64>:
  match js:
    case Nil{}: []
    case j <> t: P.tb_get(U64, it, j) <> js_ids(t, it)

def cq_red(c: Q.CQ) -> List<&2, U32>:
  Q.CQ{red, kept} = c
  red

def cq_kept(c: Q.CQ) -> Nat:
  Q.CQ{red, kept} = c
  kept

def viol(ds: List<&2, Dr>) -> List<&2, U64>:
  match ds:
    case Nil{}: []
    case +h <> t: id_keep(F64.is_lt(1.0f64, F64.abs(dr_r(h))), dr_id(h), viol(t))

def canon(xs: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case Nil{}: []
    case h <> t: (h + 0.0f64 : F64) <> canon(t)

def p2(n: Nat) -> F64:
  match n:
    case 0n: 1.0f64
    case 1n+m: (0.5f64 * p2(m) : F64)

def ptb(+ps: List<&2, F64>) -> P.Tb<&2, F64>:
  P.tb_of(F64, ps, 0.0f64)


type Od is Data:
  Od{ pm: P.Tb<&2, U32>, nt: Q.NT, fp: P.Tb<&2, Bool> }

type Cx is Data:
  Cx{ cs: List<&2, Cn>, ps0: P.Tb<&2, F64>, ft: P.Tb<&2, Bool>, np: Nat, nf: Nat,
    tl: F64, ta: F64, lmin: F64, lmax: F64, od: Od }

def cx_od(c: Cx) -> Od:
  Cx{cs, ps0, ft, np, nf, tl, ta, lmin, lmax, od} = c
  od

def sv_pm(xs: List<&2, Q.Sv>, +pm: P.Tb<&2, U32>) -> List<&2, Q.Sv>:
  match xs:
    case Nil{}: []
    case h <> t:
      Q.Sv{c, v} = h
      Q.Sv{P.tb_get(U32, pm, c), v} <> sv_pm(t, pm)

def lsq_rows(ds: List<&2, Dr>, +pm: P.Tb<&2, U32>) -> List<&2, Q.Rr>:
  match ds:
    case Nil{}: []
    case h <> t:
      Dr{id, r, v} = h
      Q.Rr{so_sv(P.msort(~Q.Sv, ~Q.sv_cmp, sv_pm(v, pm))), F64.neg(r)} <> lsq_rows(t, pm)

def gather(n: Nat, +i: U32, +pm: P.Tb<&2, U32>, +xt: P.Tb<&2, F64>) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m: P.tb_get(F64, xt, P.tb_get(U32, pm, i)) <> gather(m, (i + 1 : U32), pm, xt)

def gat_b(xs: List<&2, U32>, +ft: P.Tb<&2, Bool>) -> List<&2, Bool>:
  match xs:
    case Nil{}: []
    case h <> t: P.tb_get(Bool, ft, h) <> gat_b(t, ft)

def cl_es(xs: List<&2, Q.Sv>, +c: U32, acc: List<&2, P.Ed>) -> List<&2, P.Ed>:
  match xs:
    case Nil{}: acc
    case h <> t: P.Ed{c, Q.sv_c(h)} <> cl_es(t, c, acc)

def row_es(xs: List<&2, Q.Sv>, acc: List<&2, P.Ed>) -> List<&2, P.Ed>:
  match xs:
    case Nil{}: acc
    case h <> +t: row_es(t, cl_es(t, Q.sv_c(h), acc))

def ds_es(ds: List<&2, Dr>) -> List<&2, P.Ed>:
  match ds:
    case Nil{}: []
    case h <> t: row_es(dr_v(h), ds_es(t))

def od_mk(x: Q.ND, +np: U32, +ft: P.Tb<&2, Bool>) -> Od:
  Q.ND{+ord, t} = x
  Od{Q.mp_set(ord, 0, P.tb_of(U32, P.rep_n(U32, U32.to_nat(np), 0), 0)), t, P.tb_of(Bool, gat_b(ord, ft), False{})}

def od_of(+ds: List<&2, Dr>, +np: U32, +ft: P.Tb<&2, Bool>) -> Od:
  od_mk(Q.nd_order(np, ds_es(ds)), np, ft)

def od_step(o: Od, +npu: U32, +lam: F64, +ds: List<&2, Dr>) -> List<&2, F64>:
  Od{+pm, nt, fp} = o
  gather(U32.to_nat(npu), 0, pm, ptb(Q.lsq_nt(npu, nt, Q.diag_rows(npu, fp, F64.sqrt(lam), lsq_rows(ds, pm)))))

type St is Data:
  St{ ps: List<&2, F64>, lam: F64, nu: F64, cost: F64, done: Bool, ds: List<&2, Dr> }

type RQ is Data:
  RQ{ ok: Bool, ds: List<&2, Dr> }

def st_done(s: St) -> Bool:
  St{ps, lam, nu, cost, done, ds} = s
  done

def st_ps(s: St) -> List<&2, F64>:
  St{ps, lam, nu, cost, done, ds} = s
  ps

def rows_at(cx: Cx, +ps: List<&2, F64>) -> RQ:
  Cx{+cs, +ps0, +ft, np, nf, +tl, +ta, lmin, lmax, od} = cx
  +pt = ptb(ps)
  +rs = all_rows(cs, pt, ps0)
  RQ{Bool.and(rad_ok(cs, pt), rows_ok(rs)), drows(rs, ft, tl, ta)}

def rq_ok(r: RQ) -> Bool:
  RQ{ok, ds} = r
  ok

def rq_ds(r: RQ) -> List<&2, Dr>:
  RQ{ok, ds} = r
  ds

def cx_np(c: Cx) -> Nat:
  Cx{cs, ps0, ft, np, nf, tl, ta, lmin, lmax, od} = c
  np

def cx_nf(c: Cx) -> Nat:
  Cx{cs, ps0, ft, np, nf, tl, ta, lmin, lmax, od} = c
  nf

def cx_lmin(c: Cx) -> F64:
  Cx{cs, ps0, ft, np, nf, tl, ta, lmin, lmax, od} = c
  lmin

def cx_lmax(c: Cx) -> F64:
  Cx{cs, ps0, ft, np, nf, tl, ta, lmin, lmax, od} = c
  lmax

def cx_cs(c: Cx) -> List<&2, Cn>:
  Cx{cs, ps0, ft, np, nf, tl, ta, lmin, lmax, od} = c
  cs

def cx_tl(c: Cx) -> F64:
  Cx{cs, ps0, ft, np, nf, tl, ta, lmin, lmax, od} = c
  tl

def gain(+rho: F64) -> F64:
  +t = ((2.0f64 * rho : F64) - 1.0f64 : F64)
  F64.max((1.0f64 / 3.0f64 : F64), (1.0f64 - ((t * t : F64) * t : F64) : F64))

def lm_step(+cx: Cx, st: St) -> St:
  St{+ps, +lam, +nu, +cost, done, +ds} = st
  +npu = U32.from_nat(cx_np(cx))
  +dl = od_step(cx_od(cx), npu, lam, ds)
  +lr = lin_res(ds, ptb(dl))
  +pred = (cost - dot(lr, lr) : F64)
  +q = axpy(1.0f64, dl, ps)
  +rq = rows_at(cx, q)
  +dq = rq_ds(rq)
  +rt = res_of(dq)
  +c2 = dot(rt, rt)
  +tiny = F64.is_le(nrm(dl), (p2(45n) * (1.0f64 + nrm(ps) : F64) : F64))
  +up = (lam * nu : F64)
  +gl = F64.max((lam * gain(((cost - c2 : F64) / pred : F64)) : F64), cx_lmin(cx))
  Bool.pick(St, Bool.and(Bool.and(rq_ok(rq), fin(c2)), Bool.and(F64.is_lt(c2, cost), F64.is_lt(0.0f64, pred))),
    St{q, gl, 2.0f64, c2,
      Bool.or(Bool.or(tiny, F64.is_eq(c2, 0.0f64)), F64.is_lt(cx_lmax(cx), gl)), dq},
    St{ps, up, (2.0f64 * nu : F64), cost, Bool.or(tiny, F64.is_lt(cx_lmax(cx), up)), ds})

def lm(fuel: Nat, done: Bool, +cx: Cx, +st: St) -> St:
  match fuel:
    case 0n: st
    case 1n+f:
      match done:
        case True{}: st
        case False{}:
          +s2 = lm_step(cx, st)
          lm(f, st_done(s2), cx, s2)

def ok_of(+ds: List<&2, Dr>, +ps: List<&2, F64>, +k: Nat) -> Sol:
  +m = P.ulen(Dr, ds)
  +cq = Q.rank(m, P.tb_of(F64, dr_nrms(ds), 0.0f64), brows(so_tj(P.msort(~Tj, ~tj_cmp, tj_all(ds, 0)))))
  Sv_ok{canon(ps), Nat.sub(k, cq_kept(cq)), dedup(js_ids(cq_red(cq), P.tb_of(U64, dr_ids(ds), 0u64)))}

def conflict_go(stat: Bool, +ds: List<&2, Dr>) -> Sol:
  match stat:
    case True{}: Sv_conflict{dedup(viol(ds))}
    case False{}: Sv_err{T.F_nonconverged{}}

def classify_go(solved: Bool, +cx: Cx, +ps: List<&2, F64>, +ds: List<&2, Dr>) -> Sol:
  match solved:
    case True{}: ok_of(ds, ps, cx_nf(cx))
    case False{}:
      +rt = res_of(ds)
      conflict_go(F64.is_le(jtr_nrm(ds), ((p2(26n) * F64.sqrt(fro2(ds)) : F64) * nrm(rt) : F64)), ds)

def seg_long(+ps: P.Tb<&2, F64>, +a: Pt, +b: Pt, +tl: F64) -> Bool:
  F64.is_lt(tl, hyp((px(ps, b) - px(ps, a) : F64), (py(ps, b) - py(ps, a) : F64)))

def rad_long(+ps: P.Tb<&2, F64>, +r: Nat, +tl: F64) -> Bool:
  F64.is_lt(tl, fat(ps, r))

def cn_geo(c: Cn, +ps: P.Tb<&2, F64>, +tl: F64) -> Bool:
  match c:
    case K_horiz{id, a, b}: seg_long(ps, a, b, tl)
    case K_vert{id, a, b}: seg_long(ps, a, b, tl)
    case K_radius{id, r, v}: rad_long(ps, r, tl)
    case K_angle{id, a, b, c, d, cs, sn}: Bool.and(seg_long(ps, a, b, tl), seg_long(ps, c, d, tl))
    case K_par{id, a, b, c, d}: Bool.and(seg_long(ps, a, b, tl), seg_long(ps, c, d, tl))
    case K_perp{id, a, b, c, d}: Bool.and(seg_long(ps, a, b, tl), seg_long(ps, c, d, tl))
    case K_tan_lc{id, a, b, o, r}: Bool.and(seg_long(ps, a, b, tl), rad_long(ps, r, tl))
    case K_tan_cc{id, o1, r1, o2, r2}: Bool.and(rad_long(ps, r1, tl), rad_long(ps, r2, tl))
    case K_on_circ{id, p, o, r}: rad_long(ps, r, tl)
    case K_on_line{id, p, a, b}: seg_long(ps, a, b, tl)
    case K_midpoint{id, m, a, b}: seg_long(ps, a, b, tl)
    case K_equal{id, a, b, c, d}: Bool.and(seg_long(ps, a, b, tl), seg_long(ps, c, d, tl))
    case _: True{}

def geo_ok(cs: List<&2, Cn>, +ps: P.Tb<&2, F64>, +tl: F64) -> Bool:
  match cs:
    case Nil{}: True{}
    case h <> t: Bool.and(cn_geo(h, ps, tl), geo_ok(t, ps, tl))

def solved_at(+cx: Cx, +ps: List<&2, F64>, +ds: List<&2, Dr>) -> Bool:
  Bool.and(geo_ok(cx_cs(cx), ptb(ps), cx_tl(cx)), F64.is_le(maxabs(res_of(ds)), 1.0f64))

def classify(+cx: Cx, +ps: List<&2, F64>) -> Sol:
  +ds = rq_ds(rows_at(cx, ps))
  classify_go(solved_at(cx, ps, ds), cx, ps, ds)

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

def mk_cx(cs: List<&2, Cn>, ps0: P.Tb<&2, F64>, ft: P.Tb<&2, Bool>, np: Nat, nf: Nat,
    tl: F64, ta: F64, lmin: F64, lmax: F64, od: Od) -> Cx:
  Cx{cs, ps0, ft, np, nf, tl, ta, lmin, lmax, od}

def run(ok: Bool, +cs: List<&2, Cn>, +ps: List<&2, F64>, +free: List<&2, Bool>, +np: Nat,
    +tl: F64, +ta: F64, fuel: Nat) -> Sol:
  match ok:
    case False{}: Sv_err{T.F_invalid{}}
    case True{}:
      +pt = ptb(ps)
      +ft = P.tb_of(Bool, free, False{})
      +ds = drows(all_rows(cs, pt, pt), ft, tl, ta)
      +rt = res_of(ds)
      +l0 = (p2(10n) * F64.max(col_max(ds), 1.0f64) : F64)
      +lf = (p2(30n) * l0 : F64)
      +cx = mk_cx(cs, pt, ft, np, nfree(free), tl, ta, lf, (1152921504606846976.0f64 * l0 : F64), od_of(ds, U32.from_nat(np), ft))
      classify(cx, st_ps(lm(fuel, False{}, cx, St{ps, lf, 2.0f64, dot(rt, rt), False{}, ds})))

def pt_refs(p: Pt, acc: List<&2, Nat>) -> List<&2, Nat>:
  Pt{x, y} = p
  x <> y <> acc

def cn_refs(c: Cn) -> List<&2, Nat>:
  match c:
    case K_coinc{id, p, q}: pt_refs(p, pt_refs(q, []))
    case K_horiz{id, a, b}: pt_refs(a, pt_refs(b, []))
    case K_vert{id, a, b}: pt_refs(a, pt_refs(b, []))
    case K_dist{id, p, q, d}: pt_refs(p, pt_refs(q, []))
    case K_radius{id, r, v}: [r]
    case K_angle{id, a, b, c, d, cs, sn}: pt_refs(a, pt_refs(b, pt_refs(c, pt_refs(d, []))))
    case K_par{id, a, b, c, d}: pt_refs(a, pt_refs(b, pt_refs(c, pt_refs(d, []))))
    case K_perp{id, a, b, c, d}: pt_refs(a, pt_refs(b, pt_refs(c, pt_refs(d, []))))
    case K_tan_lc{id, a, b, o, r}: pt_refs(a, pt_refs(b, pt_refs(o, [r])))
    case K_tan_cc{id, o1, r1, o2, r2}: pt_refs(o1, pt_refs(o2, [r1, r2]))
    case K_on_circ{id, p, o, r}: pt_refs(p, pt_refs(o, [r]))
    case K_fix{id, i, v}: [i]
    case K_on_line{id, p, a, b}: pt_refs(p, pt_refs(a, pt_refs(b, [])))
    case K_midpoint{id, m, a, b}: pt_refs(m, pt_refs(a, pt_refs(b, [])))
    case K_equal{id, a, b, c, d}: pt_refs(a, pt_refs(b, pt_refs(c, pt_refs(d, []))))
    case K_hdist{id, p, q, d}: pt_refs(p, pt_refs(q, []))
    case K_vdist{id, p, q, d}: pt_refs(p, pt_refs(q, []))
    case K_same{id, i, j}: [i, j]

def tr_min(t: P.Tr<&2, U32>) -> U32:
  match t:
    case P.TL{v}: v
    case P.TN{l, r}: tr_min(l)

def z_of(t: P.Tr<&2, U32>, +x: U32) -> Bool:
  match t:
    case P.TL{v}: False{}
    case P.TN{l, r}: U32.is_lt(x, tr_min(r))

def bs_go(t: P.Tr<&2, U32>, +x: U32, +base: U32, +n: U32, z: Bool) -> U32:
  match t z:
    case P.TL{v} _: base
    case P.TN{+l, r} True{}: bs_go(l, x, base, U32.shr(n), z_of(l, x))
    case P.TN{l, +r} False{}:
      +h = U32.shr(n)
      bs_go(r, x, (base + h : U32), h, z_of(r, x))

def bs(tb: P.Tb<&2, U32>, +x: U32) -> U32:
  P.Tb{+n, +t} = tb
  bs_go(t, x, 0, n, z_of(t, x))

def lx(+m: P.Tb<&2, U32>, +i: Nat) -> Nat:
  U32.to_nat(bs(m, U32.from_nat(i)))

def lpt(+m: P.Tb<&2, U32>, p: Pt) -> Pt:
  Pt{x, y} = p
  Pt{lx(m, x), lx(m, y)}

def cn_map(+m: P.Tb<&2, U32>, c: Cn) -> Cn:
  match c:
    case K_coinc{id, p, q}: K_coinc{id, lpt(m, p), lpt(m, q)}
    case K_horiz{id, a, b}: K_horiz{id, lpt(m, a), lpt(m, b)}
    case K_vert{id, a, b}: K_vert{id, lpt(m, a), lpt(m, b)}
    case K_dist{id, p, q, d}: K_dist{id, lpt(m, p), lpt(m, q), d}
    case K_radius{id, r, v}: K_radius{id, lx(m, r), v}
    case K_angle{id, a, b, c, d, cs, sn}: K_angle{id, lpt(m, a), lpt(m, b), lpt(m, c), lpt(m, d), cs, sn}
    case K_par{id, a, b, c, d}: K_par{id, lpt(m, a), lpt(m, b), lpt(m, c), lpt(m, d)}
    case K_perp{id, a, b, c, d}: K_perp{id, lpt(m, a), lpt(m, b), lpt(m, c), lpt(m, d)}
    case K_tan_lc{id, a, b, o, r}: K_tan_lc{id, lpt(m, a), lpt(m, b), lpt(m, o), lx(m, r)}
    case K_tan_cc{id, o1, r1, o2, r2}: K_tan_cc{id, lpt(m, o1), lx(m, r1), lpt(m, o2), lx(m, r2)}
    case K_on_circ{id, p, o, r}: K_on_circ{id, lpt(m, p), lpt(m, o), lx(m, r)}
    case K_fix{id, i, v}: K_fix{id, lx(m, i), v}
    case K_on_line{id, p, a, b}: K_on_line{id, lpt(m, p), lpt(m, a), lpt(m, b)}
    case K_midpoint{id, mm, a, b}: K_midpoint{id, lpt(m, mm), lpt(m, a), lpt(m, b)}
    case K_equal{id, a, b, c, d}: K_equal{id, lpt(m, a), lpt(m, b), lpt(m, c), lpt(m, d)}
    case K_hdist{id, p, q, d}: K_hdist{id, lpt(m, p), lpt(m, q), d}
    case K_vdist{id, p, q, d}: K_vdist{id, lpt(m, p), lpt(m, q), d}
    case K_same{id, i, j}: K_same{id, lx(m, i), lx(m, j)}

def cns_map(+m: P.Tb<&2, U32>, cs: List<&2, Cn>) -> List<&2, Cn>:
  match cs:
    case Nil{}: []
    case c <> t: cn_map(m, c) <> cns_map(m, t)

type CI is Data:
  CI{ lab: U32, ci: U32, c: Cn }

def ci_lab(x: CI) -> U32:
  CI{lab, ci, c} = x
  lab

def ci_ci(x: CI) -> U32:
  CI{lab, ci, c} = x
  ci

def ci_cmp_go(+a: CI, +b: CI) -> P.Sgn:
  P.lex_u(P.u_cmp(ci_lab(a), ci_lab(b)), ci_ci(a), ci_ci(b))

def ci_cmp(a: CI, b: CI) -> P.Sgn:
  ci_cmp_go(a, b)

def u32s(xs: List<&2, Nat>) -> List<&2, U32>:
  match xs:
    case Nil{}: []
    case h <> t: U32.from_nat(h) <> u32s(t)

def ed_if(c: Bool, +u: U32, +v: U32, acc: List<&2, P.Ed>) -> List<&2, P.Ed>:
  match c:
    case True{}: P.Ed{u, v} <> acc
    case False{}: acc

def ref_edges(+ft: P.Tb<&2, Bool>, +node: U32, rs: List<&2, U32>, acc: List<&2, P.Ed>) -> List<&2, P.Ed>:
  match rs:
    case Nil{}: acc
    case +r <> t: ref_edges(ft, node, t, ed_if(P.tb_get(Bool, ft, r), r, node, acc))

def edges_of(+ft: P.Tb<&2, Bool>, +np: U32, cs: List<&2, Cn>, +ci: U32, acc: List<&2, P.Ed>) -> List<&2, P.Ed>:
  match cs:
    case Nil{}: acc
    case c <> t: edges_of(ft, np, t, (ci + 1 : U32), ref_edges(ft, (np + ci : U32), u32s(cn_refs(c)), acc))

def labs_ci(+lt: P.Tb<&2, U32>, +np: U32, cs: List<&2, Cn>, +ci: U32) -> List<&2, CI>:
  match cs:
    case Nil{}: []
    case c <> t: CI{P.tb_get(U32, lt, (np + ci : U32)), ci, c} <> labs_ci(lt, np, t, (ci + 1 : U32))

type CL is Data:
  CL{ cis: List<&2, U32>, cs: List<&2, Cn> }

type CB is Data:
  CB{ lab: U32, cis: List<&2, U32>, cs: List<&2, Cn>, out: List<&2, CL> }

def cb_lab(b: CB) -> U32:
  CB{lab, cis, cs, out} = b
  lab

def cb_step(same: Bool, b: CB, x: CI) -> CB:
  match same:
    case True{}:
      CB{lab, cis, cs, out} = b
      CI{l, ci, c} = x
      CB{lab, ci <> cis, c <> cs, out}
    case False{}:
      CB{lab, cis, cs, out} = b
      CI{l, ci, c} = x
      CB{l, [ci], [c], CL{List.reverse(&2, U32, cis), List.reverse(&2, Cn, cs)} <> out}

def cb_go(xs: List<&2, CI>, +b: CB) -> CB:
  match xs:
    case Nil{}: b
    case +x <> t: cb_go(t, cb_step(U32.is_eq(ci_lab(x), cb_lab(b)), b, x))

def cb_fin(b: CB) -> List<&2, CL>:
  CB{lab, cis, cs, out} = b
  List.reverse(&2, CL, CL{List.reverse(&2, U32, cis), List.reverse(&2, Cn, cs)} <> out)

def clusters(xs: List<&2, CI>) -> List<&2, CL>:
  match xs:
    case Nil{}: []
    case h <> t:
      CI{+l, ci, c} = h
      cb_fin(cb_go(t, CB{l, [ci], [c], []}))

def refs_all(cs: List<&2, Cn>) -> List<&2, U32>:
  match cs:
    case Nil{}: []
    case c <> t: List.append(&2, U32, u32s(cn_refs(c)), refs_all(t))

def uniq_pick(c: Bool, +h: U32, rest: List<&2, U32>) -> List<&2, U32>:
  match c:
    case True{}: h <> rest
    case False{}: rest

def uniq_go(xs: List<&2, U32>, +prev: U32, first: Bool) -> List<&2, U32>:
  match xs:
    case Nil{}: []
    case +h <> t:
      uniq_pick(Bool.or(first, Bool.not(U32.is_eq(h, prev))), h, uniq_go(t, h, False{}))

def so_u(s: P.So<&2, U32>) -> List<&2, U32>:
  P.So{ok, xs} = s
  xs

def refs_of(cs: List<&2, Cn>) -> List<&2, U32>:
  uniq_go(so_u(P.msort(~U32, ~P.u_cmp, refs_all(cs))), 0, True{})

type CR is Data:
  CR{ sol: Sol, refs: List<&2, U32>, cis: List<&2, U32>, ids: List<&2, U64>, fr: List<&2, Bool> }

type GC is Data:
  GC{ pt: P.Tb<&2, F64>, ft: P.Tb<&2, Bool>, tl: F64, ta: F64, fuel: Nat }

def gets_f(+t: P.Tb<&2, F64>, rs: List<&2, U32>) -> List<&2, F64>:
  match rs:
    case Nil{}: []
    case r <> tl: P.tb_get(F64, t, r) <> gets_f(t, tl)

def gets_b(+t: P.Tb<&2, Bool>, rs: List<&2, U32>) -> List<&2, Bool>:
  match rs:
    case Nil{}: []
    case r <> tl: P.tb_get(Bool, t, r) <> gets_b(t, tl)

def ids_of(cs: List<&2, Cn>) -> List<&2, U64>:
  match cs:
    case Nil{}: []
    case c <> t: cn_id(c) <> ids_of(t)

def cl_solve_go(+g: GC, x: CL) -> CR:
  GC{+pt, +ft, +tl, +ta, +fuel} = g
  CL{+cis, +cs} = x
  +refs = refs_of(cs)
  +m = P.tb_of(U32, refs, P.inf())
  +lcs = cns_map(m, cs)
  +lps = gets_f(pt, refs)
  +lfr = gets_b(ft, refs)
  +k = U32.to_nat(P.ulen(U32, refs))
  +lpt = ptb(lps)
  +ok = Bool.and(rad_ok(lcs, lpt), rows_ok(all_rows(lcs, lpt, lpt)))
  CR{run(ok, lcs, lps, lfr, k, tl, ta, fuel), refs, cis, ids_of(cs), lfr}

def cl_solve(g: GC, x: CL) -> CR:
  cl_solve_go(g, x)

type IX is Data:
  IX{ ci: U32, id: U64 }

type PV is Data:
  PV{ i: U32, v: F64 }

def ix_ci(x: IX) -> U32:
  IX{ci, id} = x
  ci

def ix_id(x: IX) -> U64:
  IX{ci, id} = x
  id

def ix_cmp_go(+a: IX, +b: IX) -> P.Sgn:
  P.u_cmp(ix_ci(a), ix_ci(b))

def ix_cmp(a: IX, b: IX) -> P.Sgn:
  ix_cmp_go(a, b)

def pv_i(x: PV) -> U32:
  PV{i, v} = x
  i

def pv_v(x: PV) -> F64:
  PV{i, v} = x
  v

def pv_cmp_go(+a: PV, +b: PV) -> P.Sgn:
  P.u_cmp(pv_i(a), pv_i(b))

def pv_cmp(a: PV, b: PV) -> P.Sgn:
  pv_cmp_go(a, b)

def ix_if(c: Bool, +ci: U32, +id: U64, rest: List<&2, IX>) -> List<&2, IX>:
  match c:
    case True{}: IX{ci, id} <> rest
    case False{}: rest

def w_hit(ids: List<&2, U64>, want: List<&2, U64>) -> Bool:
  match ids:
    case Nil{}: False{}
    case d <> t:
      match want:
        case Nil{}: False{}
        case w <> u: U64.is_eq(d, w)

def w_tail(hit: Bool, want: List<&2, U64>) -> List<&2, U64>:
  match hit:
    case True{}:
      match want:
        case Nil{}: []
        case w <> u: u
    case False{}: want

def ix_go(cis: List<&2, U32>, ids: List<&2, U64>, want: List<&2, U64>, +hit: Bool) -> List<&2, IX>:
  match cis:
    case Nil{}: []
    case +c <> ct:
      match ids:
        case Nil{}: []
        case +d <> +dt:
          +w2 = w_tail(hit, want)
          ix_if(hit, c, d, ix_go(ct, dt, w2, w_hit(dt, w2)))

def ix_pairs(cis: List<&2, U32>, +ids: List<&2, U64>, +want: List<&2, U64>) -> List<&2, IX>:
  ix_go(cis, ids, want, w_hit(ids, want))

def pv_if(c: Bool, +i: U32, +v: F64, rest: List<&2, PV>) -> List<&2, PV>:
  match c:
    case True{}: PV{i, v} <> rest
    case False{}: rest

def pv_pairs(rs: List<&2, U32>, ps: List<&2, F64>, fr: List<&2, Bool>) -> List<&2, PV>:
  match rs:
    case Nil{}: []
    case r <> rt:
      match ps:
        case Nil{}: []
        case p <> pt:
          match fr:
            case Nil{}: []
            case f <> ft: pv_if(f, r, p, pv_pairs(rt, pt, ft))

type MG is Data:
  MG{ inv: Bool, conf: Bool, nc: Bool, cix: List<&2, IX>, rix: List<&2, IX>, pvs: List<&2, PV>,
    dof: Nat, fi: Nat }

def is_inv(k: T.FailKind) -> Bool:
  match k:
    case T.F_invalid{}: True{}
    case _: False{}

def mg_sol(s: Sol, m: MG, +refs: List<&2, U32>, +cis: List<&2, U32>, +ids: List<&2, U64>,
    +fr: List<&2, Bool>) -> MG:
  match s:
    case Sv_err{kind}:
      MG{inv, conf, nc, cix, rix, pvs, dof, fi} = m
      +bad = is_inv(kind)
      MG{Bool.or(inv, bad), conf, Bool.or(nc, Bool.not(bad)), cix, rix, pvs, dof, fi}
    case Sv_conflict{cids}:
      MG{inv, conf, nc, cix, rix, pvs, dof, fi} = m
      MG{inv, True{}, nc, List.append(&2, IX, ix_pairs(cis, ids, cids), cix), rix, pvs, dof, fi}
    case Sv_ok{ps, d, red}:
      MG{inv, conf, nc, cix, rix, pvs, dof, fi} = m
      MG{inv, conf, nc, cix, List.append(&2, IX, ix_pairs(cis, ids, red), rix),
        List.append(&2, PV, pv_pairs(refs, ps, fr), pvs), Nat.add(dof, d), Nat.add(fi, nfree(fr))}

def mg_add(m: MG, x: CR) -> MG:
  CR{sol, refs, cis, ids, fr} = x
  mg_sol(sol, m, refs, cis, ids, fr)

def mg_go(xs: List<&2, CR>, m: MG) -> MG:
  match xs:
    case Nil{}: m
    case h <> t: mg_go(t, mg_add(m, h))

def ixs_id(xs: List<&2, IX>) -> List<&2, U64>:
  match xs:
    case Nil{}: []
    case h <> t: ix_id(h) <> ixs_id(t)

def so_ix(s: P.So<&2, IX>) -> List<&2, U64>:
  P.So{ok, xs} = s
  ixs_id(xs)

def so_pv(s: P.So<&2, PV>) -> List<&2, PV>:
  P.So{ok, xs} = s
  xs

def pv_peek(xs: List<&2, PV>, +i: U32) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t: U32.is_eq(pv_i(h), i)

def pv_tail(xs: List<&2, PV>) -> List<&2, PV>:
  match xs:
    case Nil{}: []
    case h <> t: t

def pv_hv(xs: List<&2, PV>, +d: F64) -> F64:
  match xs:
    case Nil{}: d
    case h <> t: pv_v(h)

def scatter(ps: List<&2, F64>, +i: U32, +pvs: List<&2, PV>, hit: Bool) -> List<&2, F64>:
  match ps:
    case Nil{}: []
    case p <> t:
      match hit:
        case True{}:
          +j = (i + 1 : U32)
          +rest = pv_tail(pvs)
          (pv_hv(pvs, p) + 0.0f64 : F64) <> scatter(t, j, rest, pv_peek(rest, j))
        case False{}:
          +j = (i + 1 : U32)
          (p + 0.0f64 : F64) <> scatter(t, j, pvs, pv_peek(pvs, j))

def mg_out(inv: Bool, conf: Bool, nc: Bool, +cix: List<&2, IX>, +rix: List<&2, IX>,
    +pvs: List<&2, PV>, +dof: Nat, +ps: List<&2, F64>) -> Sol:
  match inv conf nc:
    case True{} _ _: Sv_err{T.F_invalid{}}
    case False{} True{} _: Sv_conflict{so_ix(P.msort(~IX, ~ix_cmp, cix))}
    case False{} False{} True{}: Sv_err{T.F_nonconverged{}}
    case False{} False{} False{}:
      +sp = so_pv(P.msort(~PV, ~pv_cmp, pvs))
      Sv_ok{scatter(ps, 0, sp, pv_peek(sp, 0)), dof, so_ix(P.msort(~IX, ~ix_cmp, rix))}

def mg_fin(m: MG, +ps: List<&2, F64>, +free: List<&2, Bool>) -> Sol:
  MG{inv, conf, nc, cix, rix, pvs, dof, fi} = m
  mg_out(inv, conf, nc, cix, rix, pvs, Nat.add(dof, Nat.sub(nfree(free), fi)), ps)

def all_cn_ok(cs: List<&2, Cn>, +np: Nat) -> Bool:
  match cs:
    case Nil{}: True{}
    case c <> t: Bool.and(cn_ok(c, np), all_cn_ok(t, np))

def u64_cmp_go(+a: U64, +b: U64) -> P.Sgn:
  P.sgn_pick(U64.is_lt(a, b), U64.is_lt(b, a))

def u64_cmp(a: U64, b: U64) -> P.Sgn:
  u64_cmp_go(a, b)

def distinct_go(xs: List<&2, U64>, +prev: U64, first: Bool) -> Bool:
  match xs:
    case Nil{}: True{}
    case +h <> t: Bool.and(Bool.or(first, Bool.not(U64.is_eq(h, prev))), distinct_go(t, h, False{}))

def so_ids_ok(s: P.So<&2, U64>) -> Bool:
  P.So{ok, xs} = s
  Bool.and(ok, distinct_go(xs, 0u64, True{}))

def cns_valid(+cs: List<&2, Cn>, +np: Nat) -> Bool:
  Bool.and(all_cn_ok(cs, np), so_ids_ok(P.msort(~U64, ~u64_cmp, ids_of(cs))))

def cc_labs(c: P.CC) -> List<&2, U32>:
  P.CC{ok, ps} = c
  ps

def so_ci(s: P.So<&2, CI>) -> List<&2, CI>:
  P.So{ok, xs} = s
  xs

def cc_ok(c: P.CC) -> Bool:
  P.CC{ok, ps} = c
  ok

def solve_cl(ok: Bool, +cc: P.CC, +npu: U32, +ps: List<&2, F64>, +free: List<&2, Bool>, +cs: List<&2, Cn>,
    +ft: P.Tb<&2, Bool>, +tl: F64, +ta: F64, +fuel: Nat) -> Sol:
  match ok:
    case False{}: Sv_err{T.F_nonconverged{}}
    case True{}:
      +lt = P.tb_of(U32, cc_labs(cc), 0)
      +cls = clusters(so_ci(P.msort(~CI, ~ci_cmp, labs_ci(lt, npu, cs, 0))))
      +g = {GC{P.tb_of(F64, ps, 0.0f64), ft, tl, ta, fuel} : GC}
      +crs = P.pmap(~CL, ~GC, ~CR, ~cl_solve, g, cls)
      mg_fin(mg_go(crs, MG{False{}, False{}, False{}, [], [], [], 0n, 0n}), ps, free)

def solve_go(valid: Bool, +ps: List<&2, F64>, +free: List<&2, Bool>, +cs: List<&2, Cn>, +tl: F64,
    +ta: F64, +fuel: Nat, +np: Nat) -> Sol:
  match valid:
    case False{}: Sv_err{T.F_invalid{}}
    case True{}:
      +npu = U32.from_nat(np)
      +ft = P.tb_of(Bool, free, False{})
      +cc = P.components((npu + P.ulen(Cn, cs) : U32), edges_of(ft, npu, cs, 0, []))
      solve_cl(cc_ok(cc), cc, npu, ps, free, cs, ft, tl, ta, fuel)

def solve(+ps: List<&2, F64>, +free: List<&2, Bool>, +cs: List<&2, Cn>, tol: T.Tol,
    +fuel: Nat) -> Sol:
  T.Tol{+lin, +ang, par, apx, imp} = tol
  +np = flen(ps)
  +valid = Bool.and(Bool.and(Bool.and(all_fin(ps), Nat.is_eq(blen(free), np)),
    Bool.and(T.tol_pos(lin), T.tol_pos(ang))), cns_valid(cs, np))
  solve_go(valid, ps, free, cs, lin, ang, fuel, np)

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
