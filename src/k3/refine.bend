import Base
import ../c01/types.bend as V
import ../c07/sol.bend as SO
import ../base/par.bend as B
import mesh.bend as K

type EK is Data:
  EK{ lo: Nat, hi: Nat }

def ek(+a: Nat, +b: Nat) -> EK:
  EK{Nat.min(a, b), Nat.max(a, b)}

def ek_lo(+e: EK) -> Nat:
  EK{+lo, hi} = e
  lo

def ek_hi(+e: EK) -> Nat:
  EK{lo, +hi} = e
  hi

def ek_cmp2(+x: EK, +y: EK) -> B.Sgn:
  K.lex(K.ncmp2(ek_lo(x), ek_lo(y)), K.ncmp2(ek_hi(x), ek_hi(y)))

def ek_cmp(x: EK, y: EK) -> B.Sgn:
  ek_cmp2(x, y)

def ek_eq(+x: EK, +y: EK) -> Bool:
  Bool.and(Nat.is_eq(ek_lo(x), ek_lo(y)), Nat.is_eq(ek_hi(x), ek_hi(y)))

def so_ek(s: B.So<&2, EK>) -> List<&2, EK>:
  B.So{ok, +xs} = s
  xs

def uniq_ek(xs: List<&2, EK>, +prev: EK, +first: Bool) -> List<&2, EK>:
  match xs:
    case []: []
    case +x <> +t:
      +rest = uniq_ek(t, x, False{})
      Bool.pick(List<&2, EK>, Bool.and(Bool.not(first), ek_eq(x, prev)), rest, x <> rest)

def sort_ek(+xs: List<&2, EK>) -> List<&2, EK>:
  uniq_ek(so_ek(B.msort(~EK, ~ek_cmp, xs)), EK{0n, 0n}, True{})

def pos(+pt: B.Tb<&2, V.Point>, +i: Nat) -> V.Point:
  B.tb_get(V.Point, pt, U32.from_nat(i))

def elen(+pt: B.Tb<&2, V.Point>, +e: EK) -> F64:
  K.dlen(K.psub(pos(pt, ek_lo(e)), pos(pt, ek_hi(e))))

def t_es(+t: K.T4) -> List<&2, EK>:
  K.T4{+a, +b, +c, +d} = t
  [ek(a, b), ek(a, c), ek(a, d), ek(b, c), ek(b, d), ek(c, d)]

def longer(+pt: B.Tb<&2, V.Point>, +x: EK, +y: EK) -> EK:
  +lx = elen(pt, x)
  +ly = elen(pt, y)
  Bool.pick(EK, Bool.or(F64.is_lt(ly, lx), Bool.and(F64.is_eq(lx, ly), B.sgn_is(ek_cmp2(x, y), B.Sn{}))), x, y)

def longest_go(es: List<&2, EK>, +pt: B.Tb<&2, V.Point>, +best: EK) -> EK:
  match es:
    case []: best
    case +e <> +t: longest_go(t, pt, longer(pt, e, best))

def L_hd(xs: List<&2, EK>) -> EK:
  match xs:
    case []: EK{0n, 0n}
    case +x <> t: x

def longest(+pt: B.Tb<&2, V.Point>, +t: K.T4) -> EK:
  +es = t_es(t)
  longest_go(es, pt, L_hd(es))

type ST is Data:
  ST{ t: B.Tb<&2, EK>, n: Nat, lg: Nat }

def lg2(f: Nat, +n: Nat, +acc: Nat) -> Nat:
  match f:
    case 0n: acc
    case 1n+g: Bool.pick(Nat, Nat.is_eq(n, 0n), acc, lg2(g, Nat.div(n, 2n), Nat.add(acc, 1n)))

def st_of(+xs: List<&2, EK>) -> ST:
  +n = List.length(&2, EK, xs)
  ST{B.tb_of(EK, xs, EK{0n, 0n}), n, Nat.add(lg2(64n, n, 0n), 2n)}

def lb(f: Nat, done: Bool, +t: B.Tb<&2, EK>, +lo: Nat, +hi: Nat, +k: EK) -> Nat:
  match f:
    case 0n: lo
    case 1n+g:
      match done:
        case True{}: lo
        case False{}:
          +mid = Nat.div(Nat.add(lo, hi), 2n)
          +less = B.sgn_is(ek_cmp2(B.tb_get(EK, t, U32.from_nat(mid)), k), B.Sn{})
          +lo2 = Bool.pick(Nat, less, Nat.add(mid, 1n), lo)
          +hi2 = Bool.pick(Nat, less, hi, mid)
          lb(g, Bool.not(Nat.is_lt(lo2, hi2)), t, lo2, hi2, k)

def st_find(+s: ST, +k: EK) -> Nat:
  ST{+t, +n, +g} = s
  +i = lb(g, Bool.not(Nat.is_lt(0n, n)), t, 0n, n, k)
  Bool.pick(Nat, Bool.and(Nat.is_lt(i, n), ek_eq(B.tb_get(EK, t, U32.from_nat(i)), k)), i, n)

def st_n(+s: ST) -> Nat:
  ST{t, +n, g} = s
  n

def st_has(+s: ST, +k: EK) -> Bool:
  Nat.is_lt(st_find(s, k), st_n(s))

type BF is Data:
  BF{ k: K.FK, a: Nat, b: Nat, c: Nat, o: Nat, t: Nat }

def bf_k(+f: BF) -> K.FK:
  BF{+k, a, b, c, o, t} = f
  k

def bf_cmp(x: BF, y: BF) -> B.Sgn:
  K.fk_cmp2(bf_k(x), bf_k(y))

def so_bf(s: B.So<&2, BF>) -> List<&2, BF>:
  B.So{ok, +xs} = s
  xs

def t_bfs(ts: List<&2, K.T4>, +i: Nat, +acc: List<&2, BF>) -> List<&2, BF>:
  match ts:
    case []: acc
    case +t <> +r:
      K.T4{+a, +b, +c, +d} = t
      t_bfs(r, Nat.add(i, 1n), BF{K.key3(a, b, c), a, b, c, d, i} <> (BF{K.key3(a, b, d), a, b, d, c, i} <> (BF{K.key3(a, c, d), a, c, d, b, i} <>
        (BF{K.key3(b, c, d), b, c, d, a, i} <> acc))))

def nxt_eq(xs: List<&2, BF>, +k: K.FK) -> Bool:
  match xs:
    case []: False{}
    case +x <> t: K.fk_eq(bf_k(x), k)

def lone(xs: List<&2, BF>, +prev: K.FK, +first: Bool) -> List<&2, BF>:
  match xs:
    case []: []
    case +x <> +t:
      +dup_prev = Bool.and(Bool.not(first), K.fk_eq(bf_k(x), prev))
      +dup_next = nxt_eq(t, bf_k(x))
      +rest = lone(t, bf_k(x), False{})
      Bool.pick(List<&2, BF>, Bool.or(dup_prev, dup_next), rest, x <> rest)

def bfaces(+ts: List<&2, K.T4>) -> List<&2, BF>:
  lone(so_bf(B.msort(~BF, ~bf_cmp, t_bfs(ts, 0n, []))), K.FK{0n, 0n, 0n}, True{})

def onrm(+pt: B.Tb<&2, V.Point>, +f: BF) -> V.Dir:
  BF{k, +a, +b, +c, +o, t} = f
  +pa = pos(pt, a)
  +n = K.cross(K.psub(pos(pt, b), pa), K.psub(pos(pt, c), pa))
  Bool.pick(V.Dir, F64.is_lt(0.0f64, K.ddot(n, K.psub(pos(pt, o), pa))), K.dsc(F64.neg(1.0f64), n), n)

def fctr(+pt: B.Tb<&2, V.Point>, +f: BF) -> V.Point:
  BF{k, +a, +b, +c, o, t} = f
  +pa = pos(pt, a)
  K.padd(pa, K.dsc(0.3333333333333333f64, K.dadd(K.psub(pos(pt, b), pa), K.psub(pos(pt, c), pa))))

def fedge(+pt: B.Tb<&2, V.Point>, +f: BF) -> F64:
  BF{k, +a, +b, +c, o, t} = f
  F64.max(elen(pt, ek(a, b)), F64.max(elen(pt, ek(a, c)), elen(pt, ek(b, c))))

def first_gt(ts: List<&2, F64>, +d: F64, +dflt: F64) -> F64:
  match ts:
    case []: dflt
    case +x <> +r: Bool.pick(F64, F64.is_lt(d, x), x, first_gt(r, d, dflt))

type TC is Data:
  TC{ fs: List<&2, SO.Fd>, pt: B.Tb<&2, V.Point>, ln: F64, xs: List<&2, K.FS> }

def on3(xs: List<&2, Nat>, +ys: List<&2, Nat>, +zs: List<&2, Nat>) -> Bool:
  match xs:
    case []: False{}
    case +x <> +t: Bool.or(Bool.and(K.has_n(ys, x), K.has_n(zs, x)), on3(t, ys, zs))

def one_face(+xs: List<&2, K.FS>, +pt: B.Tb<&2, V.Point>, +f: BF, +tol: F64) -> Bool:
  BF{k, +a, +b, +c, o, t} = f
  on3(K.hits(xs, pos(pt, a), tol, 0n, []), K.hits(xs, pos(pt, b), tol, 0n, []), K.hits(xs, pos(pt, c), tol, 0n, []))

def thick_g(+c: TC, +f: BF) -> F64:
  TC{+fs, +pt, +ln, +xs} = c
  +n = onrm(pt, f)
  +u = K.dsc(F64.neg(F64.div(1.0f64, K.dlen(n))), n)
  +e = fedge(pt, f)
  Bool.pick(F64, one_face(xs, pt, f, F64.mul(1.0e-6f64, e)), first_gt(K.lx_ts(K.seg_xs(fs, fctr(pt, f), u, ln)), F64.mul(0.1f64, e), ln), ln)

def thick_f(c: TC, f: BF) -> F64:
  thick_g(c, f)

def bf_t(+f: BF) -> Nat:
  BF{k, a, b, c, o, +t} = f
  t

def marks(fs: List<&2, BF>, ths: List<&2, F64>, +tt: B.Tb<&2, K.T4>, +pt: B.Tb<&2, V.Point>, +kf: F64) -> List<&2, Nat>:
  match fs:
    case []: []
    case +f <> +r:
      match ths:
        case []: []
        case +h <> +q:
          +i = bf_t(f)
          +rest = marks(r, q, tt, pt, kf)
          Bool.pick(List<&2, Nat>, F64.is_lt(F64.mul(kf, h), elen(pt, longest(pt, B.tb_get(K.T4, tt, U32.from_nat(i))))), i <> rest, rest)

type TE is Data:
  TE{ e: EK, t: Nat }

def te_e(+x: TE) -> EK:
  TE{+e, t} = x
  e

def te_t(+x: TE) -> Nat:
  TE{e, +t} = x
  t

def te_cmp(x: TE, y: TE) -> B.Sgn:
  ek_cmp2(te_e(x), te_e(y))

def so_te(s: B.So<&2, TE>) -> List<&2, TE>:
  B.So{ok, +xs} = s
  xs

def te_six(es: List<&2, EK>, +i: Nat, +acc: List<&2, TE>) -> List<&2, TE>:
  match es:
    case []: acc
    case +e <> +r: te_six(r, i, TE{e, i} <> acc)

def tes_of(ts: List<&2, K.T4>, +i: Nat, +acc: List<&2, TE>) -> List<&2, TE>:
  match ts:
    case []: acc
    case +t <> +r: tes_of(r, Nat.add(i, 1n), te_six(t_es(t), i, acc))

def te_hd(xs: List<&2, TE>) -> TE:
  match xs:
    case []: TE{EK{0n, 0n}, 0n}
    case +x <> t: x

def te_tl(xs: List<&2, TE>) -> List<&2, TE>:
  match xs:
    case []: []
    case x <> +t: t

def ek_tl(xs: List<&2, EK>) -> List<&2, EK>:
  match xs:
    case []: []
    case x <> +t: t

def te_nil(xs: List<&2, TE>) -> Bool:
  match xs:
    case []: True{}
    case x <> t: False{}

def ek_nil(xs: List<&2, EK>) -> Bool:
  match xs:
    case []: True{}
    case x <> t: False{}

def touch(f: Nat, +te: List<&2, TE>, +es: List<&2, EK>, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match f:
    case 0n: acc
    case 1n+g:
      +fin = Bool.or(te_nil(te), ek_nil(es))
      +x = te_hd(te)
      +c = ek_cmp2(te_e(x), L_hd(es))
      +gt = B.sgn_is(c, B.Sp{})
      +eq = B.sgn_is(c, B.Sz{})
      Bool.pick(List<&2, Nat>, fin, acc, touch(g, Bool.pick(List<&2, TE>, gt, te, te_tl(te)), Bool.pick(List<&2, EK>, gt, ek_tl(es), es),
        Bool.pick(List<&2, Nat>, eq, te_t(x) <> acc, acc)))

def longs(xs: List<&2, Nat>, +tt: B.Tb<&2, K.T4>, +pt: B.Tb<&2, V.Point>, +acc: List<&2, EK>) -> List<&2, EK>:
  match xs:
    case []: acc
    case +i <> +r: longs(r, tt, pt, longest(pt, B.tb_get(K.T4, tt, U32.from_nat(i))) <> acc)

def closure(f: Nat, done: Bool, +te: List<&2, TE>, +tt: B.Tb<&2, K.T4>, +pt: B.Tb<&2, V.Point>, +es: List<&2, EK>) -> List<&2, EK>:
  match f:
    case 0n: es
    case 1n+g:
      match done:
        case True{}: es
        case False{}:
          +n0 = List.length(&2, EK, es)
          +fu = Nat.add(Nat.add(List.length(&2, TE, te), n0), 1n)
          +e2 = sort_ek(List.append(&2, EK, es, longs(touch(fu, te, es, []), tt, pt, [])))
          closure(g, Nat.is_eq(List.length(&2, EK, e2), n0), te, tt, pt, e2)

type BN is Data:
  BN{ e: EK, n: V.Dir }

def bn_e(+x: BN) -> EK:
  BN{+e, n} = x
  e

def bn_cmp(x: BN, y: BN) -> B.Sgn:
  ek_cmp2(bn_e(x), bn_e(y))

def so_bn(s: B.So<&2, BN>) -> List<&2, BN>:
  B.So{ok, +xs} = s
  xs

def bns(fs: List<&2, BF>, +pt: B.Tb<&2, V.Point>, +acc: List<&2, BN>) -> List<&2, BN>:
  match fs:
    case []: acc
    case +f <> +r:
      BF{k, +a, +b, +c, o, t} = f
      +n = onrm(pt, f)
      bns(r, pt, BN{ek(a, b), n} <> (BN{ek(a, c), n} <> (BN{ek(b, c), n} <> acc)))

type MQ is Data:
  MQ{ e: EK, bd: Bool, n: V.Dir }

def zdir() -> V.Dir:
  V.Dr{0.0f64, 0.0f64, 1.0f64}

def bn_hd(xs: List<&2, BN>) -> BN:
  match xs:
    case []: BN{EK{0n, 0n}, zdir()}
    case +x <> t: x

def bn_tl(xs: List<&2, BN>) -> List<&2, BN>:
  match xs:
    case []: []
    case x <> +t: t

def mq_dir(+x: BN) -> V.Dir:
  BN{e, +n} = x
  n

def bn_nil(xs: List<&2, BN>) -> Bool:
  match xs:
    case []: True{}
    case x <> t: False{}

def bjoin(f: Nat, +es: List<&2, EK>, +bs: List<&2, BN>, +acc: List<&2, MQ>) -> List<&2, MQ>:
  match f:
    case 0n: acc
    case 1n+g:
      +fin = ek_nil(es)
      +nob = bn_nil(bs)
      +e = L_hd(es)
      +b = bn_hd(bs)
      +c = ek_cmp2(bn_e(b), e)
      +lt = Bool.and(Bool.not(nob), B.sgn_is(c, B.Sn{}))
      +eq = Bool.and(Bool.not(nob), B.sgn_is(c, B.Sz{}))
      Bool.pick(List<&2, MQ>, fin, acc, bjoin(g, Bool.pick(List<&2, EK>, lt, es, ek_tl(es)), Bool.pick(List<&2, BN>, Bool.or(lt, eq), bn_tl(bs), bs),
        Bool.pick(List<&2, MQ>, lt, acc, MQ{e, eq, mq_dir(b)} <> acc)))

type MV is Data:
  MV{ p: V.Point, l: V.Point }

def mid_r(+c: K.PX, +q: MQ) -> MV:
  MQ{+e, +bd, +n} = q
  +pt = K.px_pt(c)
  +pa = pos(pt, ek_lo(e))
  +pb = pos(pt, ek_hi(e))
  +m = K.padd(pa, K.dsc(0.5f64, K.psub(pb, pa)))
  +r = K.mid_e(bd, c, pa, pb, n, True{})
  +ok = Bool.and(K.mp_ok(r), F64.is_lt(K.dlen(K.psub(K.mp_p(r), m)), F64.mul(0.5f64, K.dlen(K.psub(pb, pa)))))
  MV{Bool.pick(V.Point, ok, K.mp_p(r), m), m}

def mid_q(c: K.PX, q: MQ) -> MV:
  mid_r(c, q)

def mv_ps(xs: List<&2, MV>) -> List<&2, V.Point>:
  match xs:
    case []: []
    case +x <> +t:
      MV{+p, l} = x
      p <> mv_ps(t)

def mv_ls(xs: List<&2, MV>) -> List<&2, V.Point>:
  match xs:
    case []: []
    case +x <> +t:
      MV{p, +l} = x
      l <> mv_ls(t)

type CE is Data:
  CE{ e: EK, s: Nat, on: Bool }

def ce_of(+st: ST, +e: EK, +s: Nat) -> CE:
  CE{e, s, st_has(st, e)}

def ce_best(+pt: B.Tb<&2, V.Point>, +x: CE, +y: CE) -> CE:
  CE{+ex, +sx, +ox} = x
  CE{+ey, +sy, +oy} = y
  +xw = Bool.and(ox, Bool.or(Bool.not(oy), ek_eq(longer(pt, ex, ey), ex)))
  Bool.pick(CE, xw, CE{ex, sx, ox}, CE{ey, sy, oy})

def kids(+s: Nat, +t: K.T4, +m: Nat) -> List<&2, K.T4>:
  K.T4{+a, +b, +c, +d} = t
  Bool.pick(List<&2, K.T4>, Nat.is_eq(s, 0n), [K.T4{a, m, c, d}, K.T4{m, b, c, d}],
    Bool.pick(List<&2, K.T4>, Nat.is_eq(s, 1n), [K.T4{a, b, m, d}, K.T4{m, b, c, d}],
      Bool.pick(List<&2, K.T4>, Nat.is_eq(s, 2n), [K.T4{a, b, c, m}, K.T4{m, b, c, d}],
        Bool.pick(List<&2, K.T4>, Nat.is_eq(s, 3n), [K.T4{a, b, m, d}, K.T4{a, m, c, d}],
          Bool.pick(List<&2, K.T4>, Nat.is_eq(s, 4n), [K.T4{a, b, c, m}, K.T4{a, m, c, d}], [K.T4{a, b, c, m}, K.T4{a, b, m, d}])))))

type SX is Data:
  SX{ st: ST, pt: B.Tb<&2, V.Point>, n: Nat }

def best_of(+x: SX, +t: K.T4) -> CE:
  SX{+st, +pt, n} = x
  K.T4{+a, +b, +c, +d} = t
  ce_best(pt, ce_best(pt, ce_best(pt, ce_of(st, ek(a, b), 0n), ce_of(st, ek(a, c), 1n)), ce_best(pt, ce_of(st, ek(a, d), 2n), ce_of(st, ek(b, c), 3n))),
    ce_best(pt, ce_of(st, ek(b, d), 4n), ce_of(st, ek(c, d), 5n)))

def ce_on(+c: CE) -> Bool:
  CE{e, s, +on} = c
  on

def ce_kids(+c: CE, +x: SX, +t: K.T4) -> List<&2, K.T4>:
  CE{+e, +s, on} = c
  SX{+st, pt, +n} = x
  kids(s, t, Nat.add(n, st_find(st, e)))

def split_go(f: Nat, +x: SX, +ws: List<&2, K.T4>, +acc: List<&2, K.T4>) -> List<&2, K.T4>:
  match f:
    case 0n: List.append(&2, K.T4, ws, acc)
    case 1n+g:
      match ws:
        case []: acc
        case +t <> +r:
          +c = best_of(x, t)
          +on = ce_on(c)
          split_go(g, x, Bool.pick(List<&2, K.T4>, on, List.append(&2, K.T4, ce_kids(c, x, t), r), r), Bool.pick(List<&2, K.T4>, on, acc, t <> acc))

def sdet(+pt: B.Tb<&2, V.Point>, +t: K.T4) -> F64:
  K.T4{+a, +b, +c, +d} = t
  +pa = pos(pt, a)
  K.det3(K.psub(pos(pt, b), pa), K.psub(pos(pt, c), pa), K.psub(pos(pt, d), pa))

def mpush(+v: Nat, +n: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  Bool.pick(List<&2, Nat>, Nat.is_lt(v, n), acc, Nat.sub(v, n) <> acc)

def t_mids(+t: K.T4, +n: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  K.T4{+a, +b, +c, +d} = t
  mpush(a, n, mpush(b, n, mpush(c, n, mpush(d, n, acc))))

def bad_m(ts: List<&2, K.T4>, +pt: B.Tb<&2, V.Point>, +s0: F64, +n: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match ts:
    case []: acc
    case +t <> +r: bad_m(r, pt, s0, n, Bool.pick(List<&2, Nat>, F64.is_lt(0.0f64, F64.mul(s0, sdet(pt, t))), acc, t_mids(t, n, acc)))

type SR is Data:
  SR{ ts: List<&2, K.T4>, bad: List<&2, Nat> }

type SC is Data:
  SC{ x: SX, p2: B.Tb<&2, V.Point> }

def split_u(+c: SC, +t: K.T4) -> SR:
  SC{+x, +p2} = c
  SX{st, +pt, +n} = x
  +ls = split_go(128n, x, [t], [])
  SR{ls, bad_m(ls, p2, sdet(pt, t), n, [])}

def split_t(c: SC, t: K.T4) -> SR:
  split_u(c, t)

def sr_cat(xs: List<&2, SR>, +acc: SR) -> SR:
  match xs:
    case []: acc
    case +x <> +r:
      SR{+ts, +b} = x
      SR{+ta, +ba} = acc
      sr_cat(r, SR{List.append(&2, K.T4, ts, ta), List.append(&2, Nat, b, ba)})

type RS is Data:
  RS{ ts: List<&2, K.T4>, pt: B.Tb<&2, V.Point>, n: Nat, r: Nat, ne: Nat, bad: Nat, stop: Bool }

def rs_stop(+s: RS) -> Bool:
  RS{ts, pt, n, r, ne, bad, +stop} = s
  stop

def zt4() -> K.T4:
  K.T4{0n, 0n, 0n, 0n}

type BR is Data:
  BR{ ts: List<&2, K.T4>, pt: B.Tb<&2, V.Point>, bad: Nat }

type BX is Data:
  BX{ ms: List<&2, V.Point>, br: BR }

def bx_of(+sr: SR, +ms: List<&2, V.Point>, +ls: List<&2, V.Point>, +p2: B.Tb<&2, V.Point>) -> BX:
  SR{+cs, +bad} = sr
  +bs = K.sort_u(bad)
  BX{K.revert(ms, ls, bs, 0n), BR{cs, p2, List.length(&2, Nat, bs)}}

def bx_bad(+x: BX) -> Nat:
  BX{ms, +br} = x
  BR{ts, pt, +b} = br
  b

def bx_br(+x: BX) -> BR:
  BX{ms, +br} = x
  br

def bfix(f: Nat, done: Bool, +ts: List<&2, K.T4>, +base: List<&2, V.Point>, +ls: List<&2, V.Point>, +sx: SX, +x: BX) -> BX:
  match f:
    case 0n: x
    case 1n+g:
      match done:
        case True{}: x
        case False{}:
          BX{+ms, br} = x
          +p2 = B.tb_of(V.Point, List.append(&2, V.Point, base, ms), K.origin())
          +x2 = bx_of(sr_cat(B.pmap_g(~K.T4, ~SC, ~SR, ~split_t, 64, SC{sx, p2}, ts), SR{[], []}), ms, ls, p2)
          bfix(g, Nat.is_eq(bx_bad(x2), 0n), ts, base, ls, sx, x2)

def bisect(+fs: List<&2, SO.Fd>, +ts: List<&2, K.T4>, +pt: B.Tb<&2, V.Point>, +n: Nat, +bf: List<&2, BF>, +es: List<&2, EK>) -> BR:
  +mq = bjoin(Nat.add(Nat.add(List.length(&2, EK, es), Nat.mul(3n, List.length(&2, BF, bf))), 1n), es, so_bn(B.msort(~BN, ~bn_cmp, bns(bf, pt, []))), [])
  +mv = B.pmap_g(~MQ, ~K.PX, ~MV, ~mid_q, 8, K.px_of(fs, pt), List.reverse(&2, MQ, mq))
  +base = B.take_u(V.Point, B.tb_list(V.Point, pt), U32.from_nat(n), Nat.is_eq(n, 0n))
  bx_br(bfix(5n, False{}, ts, base, mv_ls(mv), SX{st_of(es), pt, n}, BX{mv_ps(mv), BR{ts, pt, 1n}}))

def step3(+br: BR, +ts: List<&2, K.T4>, +pt: B.Tb<&2, V.Point>, +n: Nat, +r: Nat, +ne: Nat, +ns: Nat) -> RS:
  BR{+t2, +p2, +bad} = br
  Bool.pick(RS, Nat.is_eq(bad, 0n), RS{t2, p2, Nat.add(n, ns), Nat.add(r, 1n), Nat.add(ne, ns), 0n, False{}}, RS{ts, pt, n, r, ne, bad, True{}})

def step2(none: Bool, +fs: List<&2, SO.Fd>, +s: RS, +bf: List<&2, BF>, +mk: List<&2, Nat>) -> RS:
  match none:
    case True{}:
      RS{+ts, +pt, +n, +r, +ne, b, st} = s
      RS{ts, pt, n, r, ne, 0n, True{}}
    case False{}:
      RS{+ts, +pt, +n, +r, +ne, b, st} = s
      +tt = B.tb_of(K.T4, ts, zt4())
      +te = so_te(B.msort(~TE, ~te_cmp, tes_of(ts, 0n, [])))
      +es = closure(200n, False{}, te, tt, pt, sort_ek(longs(mk, tt, pt, [])))
      +ns = List.length(&2, EK, es)
      step3(bisect(fs, ts, pt, n, bf, es), ts, pt, n, r, ne, ns)

def step(+fs: List<&2, SO.Fd>, +kf: F64, +ln: F64, +s: RS) -> RS:
  RS{+ts, +pt, n, r, ne, b, st} = s
  +bf = bfaces(ts)
  +th = B.pmap_g(~BF, ~TC, ~F64, ~thick_f, 8, TC{fs, pt, ln, K.fs_of(fs)}, bf)
  +mk = marks(bf, th, B.tb_of(K.T4, ts, zt4()), pt, kf)
  step2(Nat.is_eq(List.length(&2, Nat, mk), 0n), fs, s, bf, mk)

def rounds(f: Nat, done: Bool, +fs: List<&2, SO.Fd>, +kf: F64, +ln: F64, +s: RS) -> RS:
  match f:
    case 0n: s
    case 1n+g:
      match done:
        case True{}: s
        case False{}:
          +s2 = step(fs, kf, ln, s)
          rounds(g, rs_stop(s2), fs, kf, ln, s2)

type RF is Data:
  RF{ r: Nat, a: Nat, bad: Nat, unmet: Bool }

type RT is Data:
  RT{ tr: K.TR, rf: RF }

def rf_s(+f: RF) -> String:
  RF{+r, +a, +b, +u} = f
  " graded=" ++ Nat.show(r) ++ "/" ++ Nat.show(a) ++ Bool.pick(String, Nat.is_eq(b, 0n), "", "/stop" ++ Nat.show(b)) ++ Bool.pick(String, u, "/unmet", "")

def rt_rs(+s: RS, +ok: Bool, +ok2: Bool, +ns: Nat, +fs: List<&2, SO.Fd>) -> RT:
  RS{+t2, +p2, +n2, +r, +ne, +bad, +st} = s
  RT{K.tm_mr(K.MR{ok2, n2, 0n, ns, t2, p2}, ok, fs), RF{r, ne, bad, Bool.and(Bool.not(st), Nat.is_lt(0n, r))}}

def rt_mr(+mr: K.MR, +ok: Bool, +span: F64, +fs: List<&2, SO.Fd>, +kf: F64, +nr: Nat) -> RT:
  K.MR{+ok2, +nv, +nc, +ns, +ts, +pt} = mr
  rt_rs(rounds(nr, Bool.not(F64.is_lt(0.0f64, kf)), fs, kf, span, RS{ts, pt, Nat.add(nv, nc), 0n, 0n, 0n, False{}}), ok, ok2, ns, fs)

def rt_of(+mo: K.MO, +fs: List<&2, SO.Fd>, +kf: F64, +nr: Nat) -> RT:
  K.MO{+ok, +mr, +span} = mo
  rt_mr(mr, ok, span, fs, kf, nr)

def tm_ref(+fs: List<&2, SO.Fd>, +h: F64, +kf: F64) -> RT:
  rt_of(K.mo_of(fs, h), fs, kf, 6n)
