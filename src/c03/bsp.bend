import Base
import ../c01/types.bend as V

type H4 is Data:
  H4{ x: F64, y: F64, z: F64, w: F64 }

type Bs is Data:
  Bs{ p: Nat, ks: List<&2, F64>, cs: List<&2, H4> }

type Row is Data:
  Row{ a: List<&2, F64>, b: H4 }

def hx(+h: H4) -> F64:
  H4{x, y, z, w} = h
  x

def hy(+h: H4) -> F64:
  H4{x, y, z, w} = h
  y

def hz(+h: H4) -> F64:
  H4{x, y, z, w} = h
  z

def hw(+h: H4) -> F64:
  H4{x, y, z, w} = h
  w

def h_of(+p: V.Point) -> H4:
  H4{V.pt_x(p), V.pt_y(p), V.pt_z(p), 1.0f64}

def h_pt(+h: H4) -> V.Point:
  V.Pt{F64.div(hx(h), hw(h)), F64.div(hy(h), hw(h)), F64.div(hz(h), hw(h))}

def h_lerp(+a: H4, +b: H4, +t: F64) -> H4:
  H4{F64.add(hx(a), F64.mul(t, F64.sub(hx(b), hx(a)))), F64.add(hy(a), F64.mul(t, F64.sub(hy(b), hy(a)))),
    F64.add(hz(a), F64.mul(t, F64.sub(hz(b), hz(a)))), F64.add(hw(a), F64.mul(t, F64.sub(hw(b), hw(a))))}

def h_add(+a: H4, +b: H4) -> H4:
  H4{F64.add(hx(a), hx(b)), F64.add(hy(a), hy(b)), F64.add(hz(a), hz(b)), F64.add(hw(a), hw(b))}

def h_scale(+s: F64, +a: H4) -> H4:
  H4{F64.mul(s, hx(a)), F64.mul(s, hy(a)), F64.mul(s, hz(a)), F64.mul(s, hw(a))}

def h_zero() -> H4:
  H4{0.0f64, 0.0f64, 0.0f64, 0.0f64}

def fnth(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: 0.0f64
    case +h <> t:
      match i:
        case 0n: h
        case 1n+j: fnth(t, j)

def hnth(xs: List<&2, H4>, +i: Nat) -> H4:
  match xs:
    case []: h_zero()
    case +h <> t:
      match i:
        case 0n: h
        case 1n+j: hnth(t, j)

def take_h(+n: Nat, xs: List<&2, H4>) -> List<&2, H4>:
  match n:
    case 0n: []
    case 1n+(+m):
      match xs:
        case []: []
        case +h <> t: h <> take_h(m, t)

def drop_h(+n: Nat, xs: List<&2, H4>) -> List<&2, H4>:
  match n:
    case 0n: xs
    case 1n+(+m):
      match xs:
        case []: []
        case h <> t: drop_h(m, t)

def nf(+n: Nat) -> F64:
  U64.to_f64(U64.from_nat(n))

def span_go(ks: List<&2, F64>, +u: F64, +i: Nat, +lo: Nat, +hi: Nat, +best: Nat) -> Nat:
  match ks:
    case []: best
    case +k <> +t:
      +ok = Bool.and(Bool.and(Nat.is_le(lo, i), Nat.is_le(i, hi)), Bool.and(F64.is_le(k, u), F64.is_lt(k, fnth(t, 0n))))
      span_go(t, u, Nat.add(i, 1n), lo, hi, Bool.pick(Nat, ok, i, best))

def span_of(+p: Nat, +n: Nat, ks: List<&2, F64>, +u: F64) -> Nat:
  span_go(ks, u, 0n, p, Nat.sub(n, 1n), p)

def bf_alpha(+ks: List<&2, F64>, +lo: Nat, +hi: Nat, +u: F64) -> F64:
  +a = fnth(ks, lo)
  +d = F64.sub(fnth(ks, hi), a)
  Bool.pick(F64, F64.is_eq(d, 0.0f64), 0.0f64, F64.div(F64.sub(u, a), d))

def lvl_go(ds: List<&2, H4>, +prev: H4, +ks: List<&2, F64>, +i: Nat, +p: Nat, +r: Nat, +j: Nat, +u: F64) -> List<&2, H4>:
  match ds:
    case []: []
    case +d <> t:
      +lo = Nat.sub(Nat.add(j, i), p)
      +a = bf_alpha(ks, lo, Nat.sub(Nat.add(Nat.add(j, 1n), i), r), u)
      h_lerp(prev, d, a) <> lvl_go(t, d, ks, i, p, r, Nat.add(j, 1n), u)

def lvl(ds: List<&2, H4>, +ks: List<&2, F64>, +i: Nat, +p: Nat, +r: Nat, +u: F64) -> List<&2, H4>:
  match ds:
    case []: []
    case +d <> t: lvl_go(t, d, ks, i, p, r, r, u)

def blos_go(n: Nat, +ds: List<&2, H4>, +ks: List<&2, F64>, +i: Nat, +p: Nat, +r: Nat, +us: List<&2, F64>) -> H4:
  match n:
    case 0n: hnth(ds, 0n)
    case 1n+(+m): blos_go(m, lvl(ds, ks, i, p, r, fnth(us, Nat.sub(r, 1n))), ks, i, p, Nat.add(r, 1n), us)

def blossom(+c: Bs, +i: Nat, +us: List<&2, F64>) -> H4:
  Bs{+p, +ks, +cs} = c
  blos_go(p, take_h(Nat.add(p, 1n), drop_h(Nat.sub(i, p), cs)), ks, i, p, 1n, us)

def bs_n(+c: Bs) -> Nat:
  Bs{p, ks, +cs} = c
  List.length(&2, H4, cs)

def bs_p(+c: Bs) -> Nat:
  Bs{+p, ks, cs} = c
  p

def bs_ks(+c: Bs) -> List<&2, F64>:
  Bs{p, +ks, cs} = c
  ks

def bs_cs(+c: Bs) -> List<&2, H4>:
  Bs{p, ks, +cs} = c
  cs

def reps(+u: F64, n: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m): u <> reps(u, m)

def bs_at(+c: Bs, +u: F64) -> H4:
  +i = span_of(bs_p(c), bs_n(c), bs_ks(c), u)
  blossom(c, i, reps(u, bs_p(c)))

def bez_go(n: Nat, +c: Bs, +i: Nat, +a: F64, +b: F64, +k: Nat) -> List<&2, H4>:
  match n:
    case 0n: []
    case 1n+(+m): blossom(c, i, List.append(&2, F64, reps(a, Nat.sub(bs_p(c), k)), reps(b, k))) <> bez_go(m, c, i, a, b, Nat.add(k, 1n))

def elev3(+xs: List<&2, H4>) -> List<&2, H4>:
  +n = List.length(&2, H4, xs)
  +a = hnth(xs, 0n)
  +b = hnth(xs, 1n)
  +c = hnth(xs, 2n)
  +t = F64.div(1.0f64, 3.0f64)
  +s = F64.div(2.0f64, 3.0f64)
  Bool.pick(List<&2, H4>, Nat.is_eq(n, 2n), [a, h_lerp(a, b, t), h_lerp(a, b, s), b],
    Bool.pick(List<&2, H4>, Nat.is_eq(n, 3n), [a, h_lerp(a, b, s), h_lerp(b, c, t), c],
      Bool.pick(List<&2, H4>, Nat.is_eq(n, 1n), [a, a, a, a], xs)))

def span_bez(+c: Bs, +i: Nat) -> List<&2, H4>:
  +ks = bs_ks(c)
  elev3(bez_go(Nat.add(bs_p(c), 1n), c, i, fnth(ks, i), fnth(ks, Nat.add(i, 1n)), 0n))

def spans_go(n: Nat, +c: Bs, +i: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+(+m):
      +ks = bs_ks(c)
      +rest = spans_go(m, c, Nat.add(i, 1n))
      Bool.pick(List<&2, Nat>, F64.is_lt(fnth(ks, i), fnth(ks, Nat.add(i, 1n))), i <> rest, rest)

def spans(+c: Bs) -> List<&2, Nat>:
  spans_go(Nat.sub(bs_n(c), bs_p(c)), c, bs_p(c))

def bezs_go(+c: Bs, ix: List<&2, Nat>) -> List<&2, List<&2, H4>>:
  match ix:
    case []: []
    case +i <> t: span_bez(c, i) <> bezs_go(c, t)

def bezs(+c: Bs) -> List<&2, List<&2, H4>>:
  bezs_go(c, spans(c))

def pdist(+a: V.Point, +b: V.Point) -> F64:
  +x = F64.sub(V.pt_x(a), V.pt_x(b))
  +y = F64.sub(V.pt_y(a), V.pt_y(b))
  +z = F64.sub(V.pt_z(a), V.pt_z(b))
  F64.sqrt(F64.add(F64.mul(x, x), F64.add(F64.mul(y, y), F64.mul(z, z))))

def cent_go(ps: List<&2, V.Point>, +prev: V.Point, +acc: F64) -> List<&2, F64>:
  match ps:
    case []: []
    case +q <> t:
      +a = F64.add(acc, F64.sqrt(pdist(prev, q)))
      a <> cent_go(t, q, a)

def cents(ps: List<&2, V.Point>) -> List<&2, F64>:
  match ps:
    case []: []
    case +q <> t: 0.0f64 <> cent_go(t, q, 0.0f64)

def lastf(xs: List<&2, F64>, +d: F64) -> F64:
  match xs:
    case []: d
    case +h <> t: lastf(t, h)

def norm_go(xs: List<&2, F64>, +s: F64) -> List<&2, F64>:
  match xs:
    case []: []
    case +h <> t: F64.div(h, s) <> norm_go(t, s)

def params(+ps: List<&2, V.Point>) -> List<&2, F64>:
  +c = cents(ps)
  +s = lastf(c, 1.0f64)
  norm_go(c, Bool.pick(F64, F64.is_lt(0.0f64, s), s, 1.0f64))

def fadd(xs: List<&2, F64>, ys: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> xt:
      match ys:
        case []: x <> xt
        case +y <> yt: F64.add(x, y) <> fadd(xt, yt)

def fscale(xs: List<&2, F64>, +s: F64) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> t: F64.mul(s, x) <> fscale(t, s)

def fsum_take(+n: Nat, xs: List<&2, F64>) -> F64:
  match n:
    case 0n: 0.0f64
    case 1n+(+m):
      match xs:
        case []: 0.0f64
        case +h <> t: F64.add(h, fsum_take(m, t))

def fdrop(+n: Nat, xs: List<&2, F64>) -> List<&2, F64>:
  match n:
    case 0n: xs
    case 1n+(+m):
      match xs:
        case []: []
        case h <> t: fdrop(m, t)

def avg_go(n: Nat, +us: List<&2, F64>, +p: Nat, +j: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m): F64.div(fsum_take(p, fdrop(j, us)), nf(p)) <> avg_go(m, us, p, Nat.add(j, 1n))

def knots_avg(+us: List<&2, F64>, +p: Nat) -> List<&2, F64>:
  +n = List.length(&2, F64, us)
  List.append(&2, F64, reps(0.0f64, Nat.add(p, 1n)),
    List.append(&2, F64, avg_go(Nat.sub(Nat.sub(n, 1n), p), us, p, 1n), reps(1.0f64, Nat.add(p, 1n))))

def deg_for(+m: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_le(m, 3n), Nat.sub(m, 1n), 3n)

def zeros(n: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m): 0.0f64 <> zeros(m)

def set_f(xs: List<&2, F64>, +i: Nat, +v: F64) -> List<&2, F64>:
  match xs:
    case []: []
    case +h <> t:
      match i:
        case 0n: v <> t
        case 1n+j: h <> set_f(t, j, v)

def ucs_go(n: Nat, +k: Nat, +i: Nat) -> List<&2, H4>:
  match n:
    case 0n: []
    case 1n+(+m): Bool.pick(H4, Nat.is_eq(i, k), H4{1.0f64, 0.0f64, 0.0f64, 0.0f64}, h_zero()) <> ucs_go(m, k, Nat.add(i, 1n))

def unit_cs(+n: Nat, +k: Nat) -> List<&2, H4>:
  ucs_go(n, k, 0n)

def basis_row_go(m: Nat, +p: Nat, +ks: List<&2, F64>, +n: Nat, +u: F64, +k: Nat) -> List<&2, F64>:
  match m:
    case 0n: []
    case 1n+(+r): hx(bs_at(Bs{p, ks, unit_cs(n, k)}, u)) <> basis_row_go(r, p, ks, n, u, Nat.add(k, 1n))

def basis_row(+p: Nat, +ks: List<&2, F64>, +n: Nat, +u: F64) -> List<&2, F64>:
  basis_row_go(n, p, ks, n, u, 0n)

def rows_go(+p: Nat, +ks: List<&2, F64>, +n: Nat, us: List<&2, F64>, qs: List<&2, H4>) -> List<&2, Row>:
  match us:
    case []: []
    case +u <> ut:
      match qs:
        case []: []
        case +q <> qt: Row{basis_row(p, ks, n, u), q} <> rows_go(p, ks, n, ut, qt)

def row_a(+r: Row) -> List<&2, F64>:
  Row{+a, b} = r
  a

def row_b(+r: Row) -> H4:
  Row{a, +b} = r
  b

def faxpy(xs: List<&2, F64>, +s: F64, ys: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> xt:
      match ys:
        case []: x <> xt
        case +y <> yt: F64.add(x, F64.mul(s, y)) <> faxpy(xt, s, yt)

def row_axpy(+r: Row, +s: F64, +q: Row) -> Row:
  Row{faxpy(row_a(r), s, row_a(q)), h_add(row_b(r), h_scale(s, row_b(q)))}

def piv_go(rs: List<&2, Row>, +k: Nat, +i: Nat, +best: Nat, +bv: F64) -> Nat:
  match rs:
    case []: best
    case +r <> t:
      +v = F64.abs(fnth(row_a(r), k))
      +take = Bool.and(Nat.is_le(k, i), F64.is_lt(bv, v))
      piv_go(t, k, Nat.add(i, 1n), Bool.pick(Nat, take, i, best), Bool.pick(F64, take, v, bv))

def rnth(rs: List<&2, Row>, +i: Nat) -> Row:
  match rs:
    case []: Row{[], h_zero()}
    case +h <> t:
      match i:
        case 0n: h
        case 1n+j: rnth(t, j)

def rswap_go(rs: List<&2, Row>, +a: Nat, +b: Nat, +ra: Row, +rb: Row, +i: Nat) -> List<&2, Row>:
  match rs:
    case []: []
    case +r <> t:
      Bool.pick(Row, Nat.is_eq(i, a), rb, Bool.pick(Row, Nat.is_eq(i, b), ra, r)) <> rswap_go(t, a, b, ra, rb, Nat.add(i, 1n))

def rswap(+rs: List<&2, Row>, +a: Nat, +b: Nat) -> List<&2, Row>:
  rswap_go(rs, a, b, rnth(rs, a), rnth(rs, b), 0n)

def elim_go(rs: List<&2, Row>, +k: Nat, +pr: Row, +i: Nat) -> List<&2, Row>:
  match rs:
    case []: []
    case +r <> t:
      +f = F64.div(fnth(row_a(r), k), fnth(row_a(pr), k))
      Bool.pick(Row, Nat.is_eq(i, k), r, row_axpy(r, F64.neg(f), pr)) <> elim_go(t, k, pr, Nat.add(i, 1n))

def gj_step(+rs: List<&2, Row>, +k: Nat) -> List<&2, Row>:
  +s = rswap(rs, k, piv_go(rs, k, 0n, k, F64.neg(1.0f64)))
  elim_go(s, k, rnth(s, k), 0n)

def gj_go(n: Nat, +rs: List<&2, Row>, +k: Nat) -> List<&2, Row>:
  match n:
    case 0n: rs
    case 1n+(+m): gj_go(m, gj_step(rs, k), Nat.add(k, 1n))

def sol_go(rs: List<&2, Row>, +k: Nat) -> List<&2, H4>:
  match rs:
    case []: []
    case +r <> t: h_scale(F64.div(1.0f64, fnth(row_a(r), k)), row_b(r)) <> sol_go(t, Nat.add(k, 1n))

def solve(+rs: List<&2, Row>) -> List<&2, H4>:
  sol_go(gj_go(List.length(&2, Row, rs), rs, 0n), 0n)

def interp_k(+p: Nat, +us: List<&2, F64>, +ks: List<&2, F64>, +qs: List<&2, H4>) -> Bs:
  +n = List.length(&2, H4, qs)
  Bs{p, ks, solve(rows_go(p, ks, n, us, qs))}

def interp(+us: List<&2, F64>, +qs: List<&2, H4>) -> Bs:
  +p = deg_for(List.length(&2, H4, qs))
  interp_k(p, us, knots_avg(us, p), qs)

def hs_pts(hs: List<&2, H4>) -> List<&2, V.Point>:
  match hs:
    case []: []
    case +h <> t: h_pt(h) <> hs_pts(t)

def pts_hs(ps: List<&2, V.Point>) -> List<&2, H4>:
  match ps:
    case []: []
    case +p <> t: h_of(p) <> pts_hs(t)
