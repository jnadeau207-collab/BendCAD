import Base
import ./exact.bend as X
import ./par.bend as P

type Sv is Data:
  Sv{ c: U32, v: F64 }

type Rr is Data:
  Rr{ xs: List<&2, Sv>, b: F64 }

type RA is Data:
  RA{ r: List<&2, Sv>, x: List<&2, Sv> }

type RS is Data:
  RS{ rs: List<&2, Sv>, xs: List<&2, Sv>, acc: RA }

type RP is Data:
  RP{ r: Rr, x: Rr }

type CQ is Data:
  CQ{ red: List<&2, U32>, kept: Nat }

def rr_nil() -> Rr:
  Rr{[], 0.0f64}

def sv_c(s: Sv) -> U32:
  Sv{c, v} = s
  c

def sv_v(s: Sv) -> F64:
  Sv{c, v} = s
  v

def sv_cmp_go(+a: Sv, +b: Sv) -> X.Sgn:
  P.u_cmp(sv_c(a), sv_c(b))

def sv_cmp(a: Sv, b: Sv) -> X.Sgn:
  sv_cmp_go(a, b)

def push_go(z: Bool, +c: U32, +v: F64, acc: List<&2, Sv>) -> List<&2, Sv>:
  match z:
    case True{}: acc
    case False{}: Sv{c, v} <> acc

def push(+c: U32, +v: F64, acc: List<&2, Sv>) -> List<&2, Sv>:
  push_go(F64.is_eq(v, 0.0f64), c, v, acc)

def ra_both(+cs: F64, +sn: F64, +c: U32, +a: F64, +e: F64, acc: RA) -> RA:
  RA{r, x} = acc
  RA{push(c, F64.fma(cs, a, (sn * e : F64)), r), push(c, F64.fma(cs, e, F64.neg((sn * a : F64))), x)}

def rot_step(o: X.Sgn, +cs: F64, +sn: F64, +r: Sv, rt: List<&2, Sv>, +x: Sv, xt: List<&2, Sv>,
    acc: RA) -> RS:
  match o:
    case X.Sn{}: RS{rt, x <> xt, ra_both(cs, sn, sv_c(r), sv_v(r), 0.0f64, acc)}
    case X.Sp{}: RS{r <> rt, xt, ra_both(cs, sn, sv_c(x), 0.0f64, sv_v(x), acc)}
    case _: RS{rt, xt, ra_both(cs, sn, sv_c(r), sv_v(r), sv_v(x), acc)}

def rot_go(fuel: Nat, +cs: F64, +sn: F64, st: RS) -> RA:
  match fuel:
    case 0n:
      RS{rs, xs, acc} = st
      acc
    case 1n+f:
      RS{rs, xs, acc} = st
      match rs xs:
        case Nil{} Nil{}: acc
        case +r <> rt Nil{}: rot_go(f, cs, sn, RS{rt, [], ra_both(cs, sn, sv_c(r), sv_v(r), 0.0f64, acc)})
        case Nil{} +x <> xt: rot_go(f, cs, sn, RS{[], xt, ra_both(cs, sn, sv_c(x), 0.0f64, sv_v(x), acc)})
        case +r <> rt +x <> xt: rot_go(f, cs, sn, rot_step(P.u_cmp(sv_c(r), sv_c(x)), cs, sn, r, rt, x, xt, acc))

def slen(xs: List<&2, Sv>) -> Nat:
  match xs:
    case Nil{}: 0n
    case h <> t: 1n+slen(t)

def hyp2(+a: F64, +e: F64) -> F64:
  +m = F64.max(F64.abs(a), F64.abs(e))
  +p = (a / m : F64)
  +q = (e / m : F64)
  (m * F64.sqrt(F64.fma(p, p, (q * q : F64))) : F64)

def rs_tail(xs: List<&2, Sv>) -> List<&2, Sv>:
  match xs:
    case Nil{}: []
    case h <> t: t

def rs_head(xs: List<&2, Sv>) -> F64:
  match xs:
    case Nil{}: 0.0f64
    case h <> t: sv_v(h)

def rs_col(xs: List<&2, Sv>) -> U32:
  match xs:
    case Nil{}: P.inf()
    case h <> t: sv_c(h)

def rot_fin(a: RA, +c: U32, +rho: F64, +cs: F64, +sn: F64, +rb: F64, +xb: F64) -> RP:
  RA{nr, nx} = a
  RP{Rr{Sv{c, rho} <> List.reverse(&2, Sv, nr), F64.fma(cs, rb, (sn * xb : F64))},
    Rr{List.reverse(&2, Sv, nx), F64.fma(cs, xb, F64.neg((sn * rb : F64)))}}

def rotate(r: Rr, x: Rr) -> RP:
  Rr{+rx, +rb} = r
  Rr{+xx, +xb} = x
  +a = rs_head(rx)
  +e = rs_head(xx)
  +rho = hyp2(a, e)
  +cs = (a / rho : F64)
  +sn = (e / rho : F64)
  +rt = rs_tail(rx)
  +xt = rs_tail(xx)
  rot_fin(rot_go(1n+Nat.add(slen(rt), slen(xt)), cs, sn, RS{rt, xt, RA{[], []}}), rs_col(rx), rho, cs, sn, rb, xb)

def rr_xs(r: Rr) -> List<&2, Sv>:
  Rr{xs, b} = r
  xs

def is_nil(xs: List<&2, Sv>) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: False{}

def ins(e: Bool, +cur: Rr, +x: Rr) -> RP:
  match e:
    case True{}: RP{x, rr_nil()}
    case False{}: rotate(cur, x)

def rp_r(p: RP) -> Rr:
  RP{r, x} = p
  r

def rp_x(p: RP) -> Rr:
  RP{r, x} = p
  x

type TX is Data:
  TX{ tr: P.Tb<&2, Rr>, xs: List<&2, Sv>, b: F64 }

def rr_b(r: Rr) -> F64:
  Rr{xs, b} = r
  b

def st_step(+tr: P.Tb<&2, Rr>, +h: Sv, +t: List<&2, Sv>, +b: F64) -> TX:
  +c = sv_c(h)
  +cur = P.tb_get(Rr, tr, c)
  +p = ins(is_nil(rr_xs(cur)), cur, Rr{h <> t, b})
  +nx = rp_x(p)
  TX{P.tb_set(Rr, tr, c, rp_r(p)), rr_xs(nx), rr_b(nx)}

def st_go(fuel: Nat, s: TX) -> P.Tb<&2, Rr>:
  match fuel:
    case 0n:
      TX{tr, xs, b} = s
      tr
    case 1n+f:
      TX{+tr, xs, +b} = s
      match xs:
        case Nil{}: tr
        case +h <> +t: st_go(f, st_step(tr, h, t, b))

def st_one(+fuel: Nat, +tr: P.Tb<&2, Rr>, x: Rr) -> P.Tb<&2, Rr>:
  Rr{xs, b} = x
  st_go(fuel, TX{tr, xs, b})

def stream(xs: List<&2, Rr>, +fuel: Nat, +tr: P.Tb<&2, Rr>) -> P.Tb<&2, Rr>:
  match xs:
    case Nil{}: tr
    case x <> t: stream(t, fuel, st_one(fuel, tr, x))

def sdot(xs: List<&2, Sv>, +m: P.Tb<&2, F64>) -> F64:
  match xs:
    case Nil{}: 0.0f64
    case h <> t:
      Sv{+c, v} = h
      F64.fma(v, P.tb_get(F64, m, c), sdot(t, m))

def bk_row(+m: P.Tb<&2, F64>, r: Rr) -> P.Tb<&2, F64>:
  Rr{xs, b} = r
  match xs:
    case Nil{}: m
    case h <> t:
      Sv{+c, v} = h
      P.tb_set(F64, m, c, ((b - sdot(t, m) : F64) / v : F64))

def bk_go(rs: List<&2, Rr>, +m: P.Tb<&2, F64>) -> P.Tb<&2, F64>:
  match rs:
    case Nil{}: m
    case r <> t: bk_go(t, bk_row(m, r))

def rr_col(r: Rr) -> U32:
  Rr{xs, b} = r
  rs_col(xs)

def rr_cmp_go(+a: Rr, +b: Rr) -> X.Sgn:
  P.u_cmp(rr_col(a), rr_col(b))

def rr_cmp(a: Rr, b: Rr) -> X.Sgn:
  rr_cmp_go(a, b)

def so_rr(s: P.So<&2, Rr>) -> List<&2, Rr>:
  P.So{ok, xs} = s
  xs

def nz(xs: List<&2, Sv>) -> List<&2, Sv>:
  match xs:
    case Nil{}: []
    case h <> t:
      Sv{+c, +v} = h
      push(c, v, nz(t))

def nz_rows(rs: List<&2, Rr>) -> List<&2, Rr>:
  match rs:
    case Nil{}: []
    case h <> t:
      Rr{xs, b} = h
      Rr{nz(xs), b} <> nz_rows(t)

def by_lead(+rows: List<&2, Rr>) -> List<&2, Rr>:
  so_rr(P.msort(~Rr, ~rr_cmp, nz_rows(rows)))

def empty_r(+n: U32) -> P.Tb<&2, Rr>:
  P.tb_of(Rr, P.rep_n(Rr, U32.to_nat(n), rr_nil()), rr_nil())

def diag_go(+tf: P.Tb<&2, Bool>, +s: F64, n: Nat, +i: U32) -> List<&2, Rr>:
  match n:
    case 0n: []
    case 1n+k:
      Bool.pick(Rr, P.tb_get(Bool, tf, i), Rr{[Sv{i, s}], 0.0f64}, rr_nil()) <> diag_go(tf, s, k, (i + 1 : U32))

def diag_rows(+n: U32, +tf: P.Tb<&2, Bool>, +s: F64, rows: List<&2, Rr>) -> List<&2, Rr>:
  List.append(&2, Rr, diag_go(tf, s, U32.to_nat(n), 0), rows)

def sw_step(dep: Bool, +j: U32, cq: CQ) -> CQ:
  match dep:
    case True{}:
      CQ{red, kept} = cq
      CQ{j <> red, kept}
    case False{}:
      CQ{red, kept} = cq
      CQ{red, 1n+kept}

def sw_tr(dep: Bool, +j: U32, +tr: P.Tb<&2, Rr>, +cur: Rr, +fuel: Nat) -> P.Tb<&2, Rr>:
  match dep:
    case True{}: st_one(fuel, P.tb_set(Rr, tr, j, rr_nil()), Rr{rs_tail(rr_xs(cur)), 0.0f64})
    case False{}: tr

def sweep(n: Nat, +j: U32, +fuel: Nat, +tr: P.Tb<&2, Rr>, +nb: P.Tb<&2, F64>, cq: CQ) -> CQ:
  match n:
    case 0n: cq
    case 1n+k:
      +cur = P.tb_get(Rr, tr, j)
      +dep = F64.is_le(F64.abs(rs_head(rr_xs(cur))), (F64{4490088828488384512u64} * P.tb_get(F64, nb, j) : F64))
      sweep(k, (j + 1 : U32), fuel, sw_tr(dep, j, tr, cur, fuel), nb, sw_step(dep, j, cq))

def cq_fin(c: CQ) -> CQ:
  CQ{red, kept} = c
  CQ{List.reverse(&2, U32, red), kept}

def rank(+m: U32, +nb: P.Tb<&2, F64>, rows: List<&2, Rr>) -> CQ:
  +fuel = Nat.add(1n, U32.to_nat(m))
  +tr = stream(by_lead(rows), fuel, empty_r(m))
  cq_fin(sweep(U32.to_nat(m), 0, fuel, tr, nb, CQ{[], 0n}))

type AP is Data:
  AP{ vs: List<&2, U32>, rest: List<&2, P.Ed> }

type AS is Data:
  AS{ es: List<&2, P.Ed>, out: List<&2, List<&2, U32>> }

def ed_u(e: P.Ed) -> U32:
  P.Ed{u, v} = e
  u

def ed_v(e: P.Ed) -> U32:
  P.Ed{u, v} = e
  v

def ed_cmp_go(+a: P.Ed, +b: P.Ed) -> X.Sgn:
  P.lex_u(P.u_cmp(ed_u(a), ed_u(b)), ed_v(a), ed_v(b))

def ed_cmp(a: P.Ed, b: P.Ed) -> X.Sgn:
  ed_cmp_go(a, b)

def ed_peek(es: List<&2, P.Ed>, +i: U32) -> Bool:
  match es:
    case Nil{}: False{}
    case h <> t: U32.is_eq(ed_u(h), i)

def ap_go(es: List<&2, P.Ed>, +i: U32, acc: List<&2, U32>, hit: Bool) -> AP:
  match es hit:
    case h <> +t True{}: ap_go(t, i, ed_v(h) <> acc, ed_peek(t, i))
    case _ _: AP{acc, es}

def as_mk(a: AP, out: List<&2, List<&2, U32>>) -> AS:
  AP{vs, rest} = a
  AS{rest, vs <> out}

def adj_step(+i: U32, s: AS) -> AS:
  AS{+es, out} = s
  as_mk(ap_go(es, i, [], ed_peek(es, i)), out)

def adj_go(n: Nat, +i: U32, s: AS) -> AS:
  match n:
    case 0n: s
    case 1n+m: adj_go(m, (i + 1 : U32), adj_step(i, s))

def as_out(s: AS) -> List<&2, List<&2, U32>>:
  AS{+es, out} = s
  List.reverse(&2, List<&2, U32>, out)

def ed_keep(k: Bool, +e: P.Ed, rest: List<&2, P.Ed>) -> List<&2, P.Ed>:
  match k:
    case True{}: e <> rest
    case False{}: rest

def ed_uniq(es: List<&2, P.Ed>, +pu: U32, +pv: U32, first: Bool) -> List<&2, P.Ed>:
  match es:
    case Nil{}: []
    case +h <> t:
      +u = ed_u(h)
      +v = ed_v(h)
      ed_keep(Bool.and(Bool.not(U32.is_eq(u, v)), Bool.or(first, Bool.not(Bool.and(U32.is_eq(u, pu), U32.is_eq(v, pv))))),
        h, ed_uniq(t, u, v, False{}))

def ed_both(es: List<&2, P.Ed>) -> List<&2, P.Ed>:
  match es:
    case Nil{}: []
    case h <> t:
      P.Ed{+u, +v} = h
      P.Ed{u, v} <> P.Ed{v, u} <> ed_both(t)

def so_ed(s: P.So<&2, P.Ed>) -> List<&2, P.Ed>:
  P.So{ok, xs} = s
  xs

def adj_of(+n: U32, +es: List<&2, P.Ed>) -> List<&2, List<&2, U32>>:
  +ss = ed_uniq(so_ed(P.msort(~P.Ed, ~ed_cmp, ed_both(es))), 0, 0, True{})
  as_out(adj_go(U32.to_nat(n), 0, AS{ss, []}))

type BV is Data:
  BV{ lvl: P.Tb<&2, U32>, nx: List<&2, U32> }

def bv_pick(fresh: Bool, +d: U32, +lvl: P.Tb<&2, U32>, nx: List<&2, U32>, +q: U32) -> BV:
  match fresh:
    case True{}: BV{P.tb_set(U32, lvl, q, d), q <> nx}
    case False{}: BV{lvl, nx}

def bv_nb(+d: U32, s: BV, +q: U32) -> BV:
  BV{+lvl, nx} = s
  bv_pick(U32.is_eq(P.tb_get(U32, lvl, q), P.inf()), d, lvl, nx, q)

def bv_nbs(qs: List<&2, U32>, +d: U32, s: BV) -> BV:
  match qs:
    case Nil{}: s
    case q <> t: bv_nbs(t, d, bv_nb(d, s, q))

def bv_fr(fr: List<&2, U32>, +adj: P.Tb<&2, List<&2, U32>>, +d: U32, s: BV) -> BV:
  match fr:
    case Nil{}: s
    case v <> t: bv_fr(t, adj, d, bv_nbs(P.tb_get(List<&2, U32>, adj, v), d, s))

type BF is Data:
  BF{ lvl: P.Tb<&2, U32>, fr: List<&2, U32>, d: U32, last: List<&2, U32> }

def bf_mk(v: BV, +d: U32, fr: List<&2, U32>) -> BF:
  BV{lvl, nx} = v
  BF{lvl, nx, d, fr}

def bf_go(fuel: Nat, +adj: P.Tb<&2, List<&2, U32>>, b: BF) -> BF:
  match fuel:
    case 0n: b
    case 1n+f:
      BF{lvl, fr, d, last} = b
      match fr:
        case Nil{}: BF{lvl, [], d, last}
        case +h <> +t:
          +d1 = (d + 1 : U32)
          bf_go(f, adj, bf_mk(bv_fr(h <> t, adj, d1, BV{lvl, []}), d1, h <> t))

def bfs(+n: U32, +adj: P.Tb<&2, List<&2, U32>>, +s: U32) -> BF:
  +l0 = P.tb_set(U32, P.tb_of(U32, P.rep_n(U32, U32.to_nat(n), P.inf()), P.inf()), s, 0)
  bf_go(1n+U32.to_nat(n), adj, BF{l0, [s], 0, [s]})

def bf_lvl(b: BF) -> P.Tb<&2, U32>:
  BF{lvl, fr, d, last} = b
  lvl

def bf_d(b: BF) -> U32:
  BF{lvl, fr, d, last} = b
  d

def bf_far(b: BF) -> U32:
  BF{lvl, fr, d, last} = b
  match last:
    case Nil{}: 0
    case h <> t: h

type Pt3 is Data:
  Pt3{ a: List<&2, U32>, s: List<&2, U32>, b: List<&2, U32> }

def p3_add(k: U32, +v: U32, p: Pt3) -> Pt3:
  match k:
    case 0:
      Pt3{a, s, b} = p
      Pt3{v <> a, s, b}
    case 1:
      Pt3{a, s, b} = p
      Pt3{a, v <> s, b}
    case _:
      Pt3{a, s, b} = p
      Pt3{a, s, v <> b}

def side_of(+l: U32, +mid: U32, cut: Bool) -> U32:
  match cut:
    case True{}: P.upick(U32.is_eq(l, P.inf()), 2, 0)
    case False{}: P.upick(U32.is_lt(l, mid), 0, P.upick(U32.is_eq(l, mid), 1, 2))

def split_go(n: Nat, +i: U32, +lvl: P.Tb<&2, U32>, +mid: U32, +cut: Bool, p: Pt3) -> Pt3:
  match n:
    case 0n: p
    case 1n+m: split_go(m, (i + 1 : U32), lvl, mid, cut, p3_add(side_of(P.tb_get(U32, lvl, i), mid, cut), i, p))

def reached(n: Nat, +i: U32, +lvl: P.Tb<&2, U32>) -> Bool:
  match n:
    case 0n: True{}
    case 1n+m: Bool.and(Bool.not(U32.is_eq(P.tb_get(U32, lvl, i), P.inf())), reached(m, (i + 1 : U32), lvl))

type SG is Data:
  SG{ n: U32, adj: List<&2, List<&2, U32>>, gid: List<&2, U32> }

type SP is Data:
  SP{ a: SG, b: SG, s: List<&2, U32> }

def is_nil_u(xs: List<&2, U32>) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: False{}

def u_keep(k: Bool, +x: U32, rest: List<&2, U32>) -> List<&2, U32>:
  match k:
    case True{}: x <> rest
    case False{}: rest

def mp_set(xs: List<&2, U32>, +i: U32, +m: P.Tb<&2, U32>) -> P.Tb<&2, U32>:
  match xs:
    case Nil{}: m
    case h <> t: mp_set(t, (i + 1 : U32), P.tb_set(U32, m, h, i))

def nb_map(qs: List<&2, U32>, +m: P.Tb<&2, U32>) -> List<&2, U32>:
  match qs:
    case Nil{}: []
    case q <> t:
      +x = P.tb_get(U32, m, q)
      u_keep(Bool.not(U32.is_eq(x, P.inf())), x, nb_map(t, m))

def sub_adj(vs: List<&2, U32>, +adj: P.Tb<&2, List<&2, U32>>, +m: P.Tb<&2, U32>) -> List<&2, List<&2, U32>>:
  match vs:
    case Nil{}: []
    case v <> t: nb_map(P.tb_get(List<&2, U32>, adj, v), m) <> sub_adj(t, adj, m)

def sub_gid(vs: List<&2, U32>, +gt: P.Tb<&2, U32>) -> List<&2, U32>:
  match vs:
    case Nil{}: []
    case v <> t: P.tb_get(U32, gt, v) <> sub_gid(t, gt)

def sub(+n: U32, +adj: P.Tb<&2, List<&2, U32>>, +gt: P.Tb<&2, U32>, +vs: List<&2, U32>) -> SG:
  +m = mp_set(vs, 0, P.tb_of(U32, P.rep_n(U32, U32.to_nat(n), P.inf()), P.inf()))
  SG{P.ulen(U32, vs), sub_adj(vs, adj, m), sub_gid(vs, gt)}

def no_edges(xs: List<&2, List<&2, U32>>) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(is_nil_u(h), no_edges(t))

def sg_nil() -> SG:
  SG{0, [], []}

def sp_leaf(+gid: List<&2, U32>) -> SP:
  SP{sg_nil(), sg_nil(), gid}

def sp_parts(+n: U32, +at: P.Tb<&2, List<&2, U32>>, +gt: P.Tb<&2, U32>, p: Pt3) -> SP:
  Pt3{a, s, b} = p
  SP{sub(n, at, gt, a), sub(n, at, gt, b), sub_gid(s, gt)}

def sp_flat(flat: Bool, +n: U32, +at: P.Tb<&2, List<&2, U32>>, +gt: P.Tb<&2, U32>, p: Pt3, +gid: List<&2, U32>) -> SP:
  match flat:
    case True{}: sp_leaf(gid)
    case False{}: sp_parts(n, at, gt, p)

def sp_cut(leaf: Bool, +n: U32, +at: P.Tb<&2, List<&2, U32>>, +gid: List<&2, U32>) -> SP:
  match leaf:
    case True{}: sp_leaf(gid)
    case False{}:
      +b2 = bfs(n, at, bf_far(bfs(n, at, 0)))
      +lvl = bf_lvl(b2)
      +cut = Bool.not(reached(U32.to_nat(n), 0, lvl))
      +d = bf_d(b2)
      +flat = Bool.and(Bool.not(cut), U32.is_lt(d, 2))
      sp_flat(flat, n, at, P.tb_of(U32, gid, 0), split_go(U32.to_nat(n), 0, lvl, U32.shr(d), cut, Pt3{[], [], []}), gid)

def split(g: SG) -> SP:
  SG{+n, +adj, +gid} = g
  sp_cut(Bool.or(U32.is_lt(n, 17), no_edges(adj)), n, P.tb_of(List<&2, U32>, adj, []), gid)

def sp_a(x: SP) -> SG:
  SP{a, b, s} = x
  a

def sp_b(x: SP) -> SG:
  SP{a, b, s} = x
  b

def sp_s(x: SP) -> List<&2, U32>:
  SP{a, b, s} = x
  s

def sg_leaf(g: SG) -> Bool:
  SG{n, adj, gid} = g
  Bool.or(U32.is_lt(n, 17), no_edges(adj))

type NT is Data:
  NL{ n: U32 }
  NN{ a: NT, b: NT, s: U32 }

type ND is Data:
  ND{ ord: List<&2, U32>, t: NT }

def nt_n(t: NT) -> U32:
  match t:
    case NL{n}: n
    case NN{a, b, s}: ((nt_n(a) + nt_n(b) : U32) + s : U32)

def nd_leaf(g: SG) -> ND:
  SG{+n, adj, gid} = g
  ND{gid, NL{n}}

def nd_join(x: ND, y: ND, +s: List<&2, U32>) -> ND:
  ND{xo, xt} = x
  ND{yo, yt} = y
  ND{List.append(&2, U32, xo, List.append(&2, U32, yo, s)), NN{xt, yt, P.ulen(U32, s)}}

def nd_go(fuel: Nat, stop: Bool, g: SG) -> ND:
  match fuel stop:
    case _ True{}: nd_leaf(g)
    case 0n False{}: nd_leaf(g)
    case 1n+(+f) False{}:
      +sp = split(g)
      +a = sp_a(sp)
      +b = sp_b(sp)
      x y = nd_go(f, sg_leaf(a), a) nd_go(f, sg_leaf(b), b)
      nd_join(x, y, sp_s(sp))

def nd_order(+n: U32, +es: List<&2, P.Ed>) -> ND:
  +g = {SG{n, adj_of(n, es), P.iota_n(U32.to_nat(n), 0)} : SG}
  nd_go(64n, sg_leaf(g), g)

def rr_keep(k: Bool, +x: Rr, rest: List<&2, Rr>) -> List<&2, Rr>:
  match k:
    case True{}: x <> rest
    case False{}: rest

type LX is Data:
  LX{ tr: P.Tb<&2, Rr>, xs: List<&2, Sv>, b: F64 }

type LO is Data:
  LO{ tr: P.Tb<&2, Rr>, esc: Rr }

def lx_lead(x: LX) -> U32:
  LX{tr, xs, b} = x
  rs_col(xs)

def lx_step(+lo: U32, +tr: P.Tb<&2, Rr>, +h: Sv, +t: List<&2, Sv>, +b: F64) -> LX:
  +c = (sv_c(h) - lo : U32)
  +cur = P.tb_get(Rr, tr, c)
  +p = ins(is_nil(rr_xs(cur)), cur, Rr{h <> t, b})
  +nx = rp_x(p)
  LX{P.tb_set(Rr, tr, c, rp_r(p)), rr_xs(nx), rr_b(nx)}

def lx_go(fuel: Nat, esc: Bool, +lo: U32, +hi: U32, s: LX) -> LO:
  match fuel esc:
    case _ True{}:
      LX{tr, xs, b} = s
      LO{tr, Rr{xs, b}}
    case 0n False{}:
      LX{tr, xs, b} = s
      LO{tr, rr_nil()}
    case 1n+f False{}:
      LX{+tr, xs, +b} = s
      match xs:
        case Nil{}: LO{tr, rr_nil()}
        case +h <> +t:
          +nx = lx_step(lo, tr, h, t, b)
          lx_go(f, Bool.not(U32.is_lt(lx_lead(nx), hi)), lo, hi, nx)

type LF is Data:
  LF{ tr: P.Tb<&2, Rr>, out: List<&2, Rr> }

def lf_add(o: LO, out: List<&2, Rr>) -> LF:
  LO{tr, +esc} = o
  LF{tr, rr_keep(Bool.not(is_nil(rr_xs(esc))), esc, out)}

def lf_row(+fuel: Nat, +lo: U32, +hi: U32, s: LF, x: Rr) -> LF:
  LF{tr, out} = s
  Rr{+xs, b} = x
  lf_add(lx_go(fuel, Bool.not(U32.is_lt(rs_col(xs), hi)), lo, hi, LX{tr, xs, b}), out)

def lf_go(rows: List<&2, Rr>, +fuel: Nat, +lo: U32, +hi: U32, s: LF) -> LF:
  match rows:
    case Nil{}: s
    case x <> t: lf_go(t, fuel, lo, hi, lf_row(fuel, lo, hi, s, x))

type FR is Data:
  FR{ rs: List<&2, Rr>, cs: List<&2, Rr> }

def nonnil(rs: List<&2, Rr>) -> List<&2, Rr>:
  match rs:
    case Nil{}: []
    case +h <> t: rr_keep(Bool.not(is_nil(rr_xs(h))), h, nonnil(t))

def lf_fin(s: LF) -> FR:
  LF{tr, out} = s
  FR{nonnil(P.tb_list(Rr, tr)), out}

def local(+lo: U32, +hi: U32, rows: List<&2, Rr>) -> FR:
  +w = (hi - lo : U32)
  lf_fin(lf_go(rows, 1n+U32.to_nat(w), lo, hi, LF{empty_r(w), []}))

type P3 is Data:
  P3{ a: List<&2, Rr>, b: List<&2, Rr>, s: List<&2, Rr> }

def p3_put(k: U32, x: Rr, p: P3) -> P3:
  match k:
    case 0:
      P3{pa, pb, ps} = p
      P3{x <> pa, pb, ps}
    case 1:
      P3{pa, pb, ps} = p
      P3{pa, x <> pb, ps}
    case _:
      P3{pa, pb, ps} = p
      P3{pa, pb, x <> ps}

def part3(rows: List<&2, Rr>, +ma: U32, +mb: U32, p: P3) -> P3:
  match rows:
    case Nil{}: p
    case +x <> t:
      +c = rr_col(x)
      part3(t, ma, mb, p3_put(P.upick(U32.is_lt(c, ma), 0, P.upick(U32.is_lt(c, mb), 1, 2)), x, p))

def p3_a(p: P3) -> List<&2, Rr>:
  P3{a, b, s} = p
  List.reverse(&2, Rr, a)

def p3_b(p: P3) -> List<&2, Rr>:
  P3{a, b, s} = p
  List.reverse(&2, Rr, b)

def p3_s(p: P3) -> List<&2, Rr>:
  P3{a, b, s} = p
  s

def fr_rs(f: FR) -> List<&2, Rr>:
  FR{rs, cs} = f
  rs

def fr_cs(f: FR) -> List<&2, Rr>:
  FR{rs, cs} = f
  cs

def cols_row(xs: List<&2, Sv>, acc: List<&2, U32>) -> List<&2, U32>:
  match xs:
    case Nil{}: acc
    case h <> t: cols_row(t, sv_c(h) <> acc)

def cols_all(rs: List<&2, Rr>, acc: List<&2, U32>) -> List<&2, U32>:
  match rs:
    case Nil{}: acc
    case h <> t: cols_all(t, cols_row(rr_xs(h), acc))

def so_u(s: P.So<&2, U32>) -> List<&2, U32>:
  P.So{ok, xs} = s
  xs

def uniq_go(xs: List<&2, U32>, +prev: U32, first: Bool) -> List<&2, U32>:
  match xs:
    case Nil{}: []
    case +h <> t: u_keep(Bool.or(first, Bool.not(U32.is_eq(h, prev))), h, uniq_go(t, h, False{}))

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

def rm_sv(xs: List<&2, Sv>, +m: P.Tb<&2, U32>, +fwd: Bool) -> List<&2, Sv>:
  match xs:
    case Nil{}: []
    case h <> t:
      Sv{+c, v} = h
      Sv{P.upick(fwd, bs(m, c), P.tb_get(U32, m, c)), v} <> rm_sv(t, m, fwd)

def rm_rows(rs: List<&2, Rr>, +m: P.Tb<&2, U32>, +fwd: Bool) -> List<&2, Rr>:
  match rs:
    case Nil{}: []
    case h <> t:
      Rr{xs, b} = h
      Rr{rm_sv(xs, m, fwd), b} <> rm_rows(t, m, fwd)

def tri(+cs: List<&2, Rr>) -> List<&2, Rr>:
  +cols = uniq_go(so_u(P.msort(~U32, ~P.u_cmp, cols_all(cs, []))), 0, True{})
  +k = P.ulen(U32, cols)
  +m = P.tb_of(U32, cols, P.inf())
  +tr = stream(by_lead(rm_rows(cs, m, True{})), 1n+U32.to_nat(k), empty_r(k))
  rm_rows(nonnil(P.tb_list(Rr, tr)), m, False{})

def fr_tri(f: FR) -> FR:
  FR{rs, cs} = f
  FR{rs, tri(cs)}

def fr_join(x: FR, y: FR, +mb: U32, +s: U32, sr: List<&2, Rr>) -> FR:
  FR{xr, xc} = x
  FR{yr, yc} = y
  +fs = local(mb, (mb + s : U32), by_lead(List.append(&2, Rr, sr, List.append(&2, Rr, xc, yc))))
  FR{List.append(&2, Rr, xr, List.append(&2, Rr, yr, fr_rs(fs))), tri(fr_cs(fs))}

def fact(t: NT, +lo: U32, rows: List<&2, Rr>) -> FR:
  match t:
    case NL{+n}: fr_tri(local(lo, (lo + n : U32), rows))
    case NN{+a, +b, +s}:
      +ma = (lo + nt_n(a) : U32)
      +mb = (ma + nt_n(b) : U32)
      +p = part3(rows, ma, mb, P3{[], [], []})
      x y = fact(a, lo, p3_a(p)) fact(b, ma, p3_b(p))
      fr_join(x, y, mb, s, p3_s(p))

def place(rs: List<&2, Rr>, +tr: P.Tb<&2, Rr>) -> P.Tb<&2, Rr>:
  match rs:
    case Nil{}: tr
    case +r <> t: place(t, P.tb_set(Rr, tr, rr_col(r), r))

def lsq_nt(+n: U32, +t: NT, rows: List<&2, Rr>) -> List<&2, F64>:
  +tr = place(fr_rs(fact(t, 0, by_lead(rows))), empty_r(n))
  +m = bk_go(List.reverse(&2, Rr, P.tb_list(Rr, tr)), P.tb_of(F64, P.rep_n(F64, U32.to_nat(n), 0.0f64), 0.0f64))
  P.take_u(F64, P.tb_list(F64, m), n, U32.is_eq(n, 0))
