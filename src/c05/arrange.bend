import Base
import ../c00/types.bend as T
import ./exact.bend as X
import ./par.bend as P

type Seg is Data:
  Seg{ id: U64, ax: F64, ay: F64, bx: F64, by: F64 }

type VKey is Data:
  VK_end{ seg: U64, end: U64 }
  VK_x{ lo: U64, hi: U64 }

type Pt is Data:
  PF{ x: F64, y: F64 }
  PR{ x: X.Ex, y: X.Ex, w: X.Ex }

type OHE is Data:
  OHE{ from: VKey, to: VKey, srcs: List<&2, U64> }

type Region is Data:
  Region{ outer: List<&2, OHE>, holes: List<&2, List<&2, OHE>> }

type ARes is Data:
  A_ok{ nv: Nat, ne: Nat, nc: Nat, regions: List<&2, Region>,
    dangling: List<&2, OHE> }
  A_err{ kind: T.FailKind }

def s_id(s: Seg) -> U64:
  Seg{id, ax, ay, bx, by} = s
  id

def seg_nil() -> Seg:
  Seg{0u64, 0.0f64, 0.0f64, 1.0f64, 0.0f64}

def f_cmp(+a: F64, +b: F64) -> X.Sgn:
  X.sgn_pick(F64.is_lt(a, b), F64.is_lt(b, a))

def pt_rx(p: Pt) -> X.Ex:
  match p:
    case PF{x, y}: X.ex_of(x)
    case PR{x, y, w}: x

def pt_ry(p: Pt) -> X.Ex:
  match p:
    case PF{x, y}: X.ex_of(y)
    case PR{x, y, w}: y

def pt_rw(p: Pt) -> X.Ex:
  match p:
    case PF{x, y}: X.ex_of(1.0f64)
    case PR{x, y, w}: w

def pt_isf(p: Pt) -> Bool:
  match p:
    case PF{x, y}: True{}
    case PR{x, y, w}: False{}

def pf_x(p: Pt) -> F64:
  match p:
    case PF{x, y}: x
    case PR{x, y, w}: 0.0f64

def pf_y(p: Pt) -> F64:
  match p:
    case PF{x, y}: y
    case PR{x, y, w}: 0.0f64

def cmpx_go(ff: Bool, +p: Pt, +q: Pt) -> X.Sgn:
  match ff:
    case True{}: f_cmp(pf_x(p), pf_x(q))
    case False{}: X.ex_cmp(X.ex_mul(pt_rx(p), pt_rw(q)), X.ex_mul(pt_rx(q), pt_rw(p)))

def cmpy_go(ff: Bool, +p: Pt, +q: Pt) -> X.Sgn:
  match ff:
    case True{}: f_cmp(pf_y(p), pf_y(q))
    case False{}: X.ex_cmp(X.ex_mul(pt_ry(p), pt_rw(q)), X.ex_mul(pt_ry(q), pt_rw(p)))

def pt_cmpx(+p: Pt, +q: Pt) -> X.Sgn:
  cmpx_go(Bool.and(pt_isf(p), pt_isf(q)), p, q)

def pt_cmpy(+p: Pt, +q: Pt) -> X.Sgn:
  cmpy_go(Bool.and(pt_isf(p), pt_isf(q)), p, q)

def lex_go(sx: X.Sgn, +p: Pt, +q: Pt) -> X.Sgn:
  match sx:
    case X.Sz{}: pt_cmpy(p, q)
    case X.Sn{}: X.Sn{}
    case X.Sp{}: X.Sp{}
    case X.Su{}: X.Su{}

def pt_lex(+p: Pt, +q: Pt) -> X.Sgn:
  lex_go(pt_cmpx(p, q), p, q)

def rp_flip(neg: Bool, +x: X.Ex, +y: X.Ex, +w: X.Ex) -> Pt:
  match neg:
    case True{}: PR{X.ex_neg(x), X.ex_neg(y), X.ex_neg(w)}
    case False{}: PR{x, y, w}

def rp_cross(s: Seg, r: Seg) -> Pt:
  Seg{i, +ax, +ay, +bx, +by} = s
  Seg{j, +cx, +cy, +dx, +dy} = r
  +oa = X.orient2(cx, cy, dx, dy, ax, ay)
  +w = X.ex_sub(oa, X.orient2(cx, cy, dx, dy, bx, by))
  rp_flip(X.sgn_is(X.ex_sign(w), X.Sn{}),
    X.ex_add(X.ex_scale(w, ax), X.ex_mul(oa, X.ex_dif(bx, ax))),
    X.ex_add(X.ex_scale(w, ay), X.ex_mul(oa, X.ex_dif(by, ay))), w)

def vk_lt(a: VKey, b: VKey) -> Bool:
  match a b:
    case VK_end{+s1, e1} VK_end{+s2, e2}:
      Bool.or(U64.is_lt(s1, s2), Bool.and(U64.is_eq(s1, s2), U64.is_lt(e1, e2)))
    case VK_end{s1, e1} VK_x{l2, h2}: True{}
    case VK_x{l1, h1} VK_end{s2, e2}: False{}
    case VK_x{+l1, h1} VK_x{+l2, h2}:
      Bool.or(U64.is_lt(l1, l2), Bool.and(U64.is_eq(l1, l2), U64.is_lt(h1, h2)))

def vk_pick(c: Bool, +a: VKey, +b: VKey) -> VKey:
  match c:
    case True{}: a
    case False{}: b

def vk_min(+a: VKey, +b: VKey) -> VKey:
  vk_pick(vk_lt(a, b), a, b)

def sg_opp(a: X.Sgn, b: X.Sgn) -> Bool:
  match a b:
    case X.Sn{} X.Sp{}: True{}
    case X.Sp{} X.Sn{}: True{}
    case _ _: False{}

def sg_unc(a: X.Sgn) -> Bool:
  X.sgn_is(a, X.Su{})

def both_pos(a: X.Sgn, b: X.Sgn) -> X.Sgn:
  match a b:
    case X.Su{} _: X.Su{}
    case _ X.Su{}: X.Su{}
    case X.Sp{} X.Sp{}: X.Sp{}
    case _ _: X.Sn{}

def between(+s: Seg, +px: F64, +py: F64) -> X.Sgn:
  Seg{id, +ax, +ay, +bx, +by} = s
  both_pos(X.dd_sign(px, ax, bx, ax, py, ay, by, ay, True{}),
    X.dd_sign(px, bx, ax, bx, py, by, ay, by, True{}))

def seg_ok(s: Seg) -> Bool:
  Seg{id, +ax, +ay, +bx, +by} = s
  Bool.and(Bool.and(Bool.and(X.fin(ax), X.fin(ay)), Bool.and(X.fin(bx), X.fin(by))),
    Bool.not(Bool.and(F64.is_eq(ax, bx), F64.is_eq(ay, by))))

def id_cmp_go(+a: U64, +b: U64) -> X.Sgn:
  X.sgn_pick(U64.is_lt(a, b), U64.is_lt(b, a))

def id_cmp(a: U64, b: U64) -> X.Sgn:
  id_cmp_go(a, b)

def ids_of(xs: List<&2, Seg>) -> List<&2, U64>:
  match xs:
    case Nil{}: []
    case h <> t: s_id(h) <> ids_of(t)

def all_seg_ok(xs: List<&2, Seg>) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(seg_ok(h), all_seg_ok(t))

def distinct_go(xs: List<&2, U64>, +prev: U64, first: Bool) -> Bool:
  match xs:
    case Nil{}: True{}
    case +h <> t: Bool.and(Bool.or(first, Bool.not(U64.is_eq(h, prev))), distinct_go(t, h, False{}))

def ids_distinct(s: P.So<&2, U64>) -> Bool:
  P.So{ok, xs} = s
  Bool.and(ok, distinct_go(xs, 0u64, True{}))

def segs_ok(+xs: List<&2, Seg>) -> Bool:
  Bool.and(all_seg_ok(xs), ids_distinct(P.msort(~U64, ~id_cmp, ids_of(xs))))

type SI is Data:
  SI{ k: U32, s: Seg }

def si_s(x: SI) -> Seg:
  SI{k, s} = x
  s

def si_k(x: SI) -> U32:
  SI{k, s} = x
  k

def xmin(s: Seg) -> F64:
  Seg{id, ax, ay, bx, by} = s
  F64.min(ax, bx)

def xmax(s: Seg) -> F64:
  Seg{id, ax, ay, bx, by} = s
  F64.max(ax, bx)

def ymin(s: Seg) -> F64:
  Seg{id, ax, ay, bx, by} = s
  F64.min(ay, by)

def ymax(s: Seg) -> F64:
  Seg{id, ax, ay, bx, by} = s
  F64.max(ay, by)

def si_cmp_go(+a: SI, +b: SI) -> X.Sgn:
  f_cmp(xmin(si_s(a)), xmin(si_s(b)))

def si_cmp(a: SI, b: SI) -> X.Sgn:
  si_cmp_go(a, b)

def number(xs: List<&2, Seg>, +k: U32) -> List<&2, SI>:
  match xs:
    case Nil{}: []
    case h <> t: SI{k, h} <> number(t, (k + 1 : U32))

type Pr is Data:
  Pr{ a: SI, b: SI }

def yov(+a: Seg, +b: Seg) -> Bool:
  Bool.and(F64.is_le(ymin(a), ymax(b)), F64.is_le(ymin(b), ymax(a)))

def peek_go(t: List<&2, SI>, +h: SI) -> Bool:
  match t:
    case Nil{}: False{}
    case x <> r: F64.is_le(xmin(si_s(x)), xmax(si_s(h)))

def pr_add(c: Bool, +h: SI, +x: SI, acc: List<&2, Pr>) -> List<&2, Pr>:
  match c:
    case True{}: Pr{h, x} <> acc
    case False{}: acc

def scan(t: List<&2, SI>, +h: SI, go: Bool, acc: List<&2, Pr>) -> List<&2, Pr>:
  match t:
    case Nil{}: acc
    case +x <> +r:
      match go:
        case False{}: acc
        case True{}: scan(r, h, peek_go(r, h), pr_add(yov(si_s(h), si_s(x)), h, x, acc))

def cands(xs: List<&2, SI>, acc: List<&2, Pr>) -> List<&2, Pr>:
  match xs:
    case Nil{}: acc
    case +h <> +t: cands(t, scan(t, h, peek_go(t, h), acc))

type TS is Data:
  TS{ k: U32, key: VKey, p: Pt }

def ts_p(x: TS) -> Pt:
  TS{k, key, p} = x
  p

def ts_cmp_go(+a: TS, +b: TS) -> X.Sgn:
  pt_lex(ts_p(a), ts_p(b))

def ts_cmp(a: TS, b: TS) -> X.Sgn:
  ts_cmp_go(a, b)

def bt_stop(b: X.Sgn, +k: U32, +key: VKey, +px: F64, +py: F64) -> P.So<&2, TS>:
  match b:
    case X.Sp{}: P.So{True{}, [TS{k, key, PF{px, py}}]}
    case X.Su{}: P.So{False{}, []}
    case _: P.So{True{}, []}

def on_stop(o: X.Sgn, +s: Seg, +k: U32, +key: VKey, +px: F64, +py: F64) -> P.So<&2, TS>:
  match o:
    case X.Sz{}: bt_stop(between(s, px, py), k, key, px, py)
    case X.Su{}: P.So{False{}, []}
    case _: P.So{True{}, []}

def xkey(+a: U64, +b: U64) -> VKey:
  VK_x{U64.min(a, b), U64.max(a, b)}

def x_stops(c: Bool, +ka: U32, +kb: U32, +s: Seg, +r: Seg) -> P.So<&2, TS>:
  match c:
    case True{}:
      +key = xkey(s_id(s), s_id(r))
      +p = rp_cross(s, r)
      P.So{True{}, [TS{ka, key, p}, TS{kb, key, p}]}
    case False{}: P.So{True{}, []}

def pr_stops_go(+ka: U32, +kb: U32, +s: Seg, +r: Seg) -> P.So<&2, TS>:
  Seg{+i, +ax, +ay, +bx, +by} = s
  Seg{+j, +cx, +cy, +dx, +dy} = r
  +o1 = X.orient2s(ax, ay, bx, by, cx, cy)
  +o2 = X.orient2s(ax, ay, bx, by, dx, dy)
  +o3 = X.orient2s(cx, cy, dx, dy, ax, ay)
  +o4 = X.orient2s(cx, cy, dx, dy, bx, by)
  +unc = Bool.or(Bool.or(sg_unc(o1), sg_unc(o2)), Bool.or(sg_unc(o3), sg_unc(o4)))
  +st = P.so_cat(TS, P.so_cat(TS, on_stop(o1, s, ka, VK_end{j, 0u64}, cx, cy),
    on_stop(o2, s, ka, VK_end{j, 1u64}, dx, dy)),
    P.so_cat(TS, P.so_cat(TS, on_stop(o3, r, kb, VK_end{i, 0u64}, ax, ay),
      on_stop(o4, r, kb, VK_end{i, 1u64}, bx, by)),
      x_stops(Bool.and(sg_opp(o1, o2), sg_opp(o3, o4)), ka, kb, s, r)))
  P.so_cat(TS, P.So{Bool.not(unc), []}, st)

def pr_stops(pr: Pr) -> P.So<&2, TS>:
  Pr{+a, +b} = pr
  pr_stops_go(si_k(a), si_k(b), si_s(a), si_s(b))

def own_two(+k: U32, s: Seg, rest: List<&2, TS>) -> List<&2, TS>:
  Seg{+id, ax, ay, bx, by} = s
  TS{k, VK_end{id, 0u64}, PF{ax, ay}} <> TS{k, VK_end{id, 1u64}, PF{bx, by}} <> rest

def own_stops(xs: List<&2, SI>) -> List<&2, TS>:
  match xs:
    case Nil{}: []
    case +h <> t: own_two(si_k(h), si_s(h), own_stops(t))

type VX is Data:
  VX{ key: VKey, p: Pt }

type TV is Data:
  TV{ k: U32, v: U32 }

type VG is Data:
  VG{ ok: Bool, vid: U32, cur: VX, vs: List<&2, VX>, tv: List<&2, TV> }

def vx_p(x: VX) -> Pt:
  VX{key, p} = x
  p

def vx_key(x: VX) -> VKey:
  VX{key, p} = x
  key

def vg_cur(g: VG) -> VX:
  VG{ok, vid, cur, vs, tv} = g
  cur

def vg_same(g: VG, x: TS) -> VG:
  VG{ok, +vid, +cur, vs, tv} = g
  TS{k, key, p} = x
  VG{ok, vid, VX{vk_min(vx_key(cur), key), vx_p(cur)}, vs, TV{k, vid} <> tv}

def vg_new(+good: Bool, g: VG, x: TS) -> VG:
  VG{ok, vid, cur, vs, tv} = g
  TS{k, key, p} = x
  +nv = (vid + 1 : U32)
  VG{Bool.and(ok, good), nv, VX{key, p}, cur <> vs, TV{k, nv} <> tv}

def vg_pick(c: X.Sgn, g: VG, x: TS) -> VG:
  match c:
    case X.Sz{}: vg_same(g, x)
    case X.Sn{}: vg_new(True{}, g, x)
    case _: vg_new(False{}, g, x)

def vg_go(xs: List<&2, TS>, +g: VG) -> VG:
  match xs:
    case Nil{}: g
    case +x <> t: vg_go(t, vg_pick(pt_lex(vx_p(vg_cur(g)), ts_p(x)), g, x))

def vgroup(xs: List<&2, TS>) -> VG:
  match xs:
    case Nil{}: VG{True{}, 0, VX{VK_end{0u64, 0u64}, PF{0.0f64, 0.0f64}}, [], []}
    case h <> t:
      TS{+k, key, p} = h
      vg_go(t, VG{True{}, 0, VX{key, p}, [], [TV{k, 0}]})

def vg_verts_go(any: Bool, cur: VX, vs: List<&2, VX>) -> List<&2, VX>:
  match any:
    case True{}: List.reverse(&2, VX, cur <> vs)
    case False{}: []

def vg_verts(g: VG, +any: Bool) -> List<&2, VX>:
  VG{ok, vid, cur, vs, tv} = g
  vg_verts_go(any, cur, vs)

def tv_cmp_go(+a: TV, +b: TV) -> X.Sgn:
  TV{+ka, +va} = a
  TV{+kb, +vb} = b
  P.lex_u(P.u_cmp(ka, kb), va, vb)

def tv_cmp(a: TV, b: TV) -> X.Sgn:
  tv_cmp_go(a, b)

def tv_k(x: TV) -> U32:
  TV{k, v} = x
  k

def tv_v(x: TV) -> U32:
  TV{k, v} = x
  v

type E0 is Data:
  E0{ u: U32, v: U32, k: U32 }

type EP is Data:
  EP{ first: Bool, pk: U32, pv: U32, acc: List<&2, E0> }

def ep_first(s: EP) -> Bool:
  EP{first, pk, pv, acc} = s
  first

def ep_pk(s: EP) -> U32:
  EP{first, pk, pv, acc} = s
  pk

def ep_pv(s: EP) -> U32:
  EP{first, pk, pv, acc} = s
  pv

def ep_acc(s: EP) -> List<&2, E0>:
  EP{first, pk, pv, acc} = s
  acc

def ep_fresh(s: EP, x: TV) -> EP:
  EP{first, pk, pv, acc} = s
  TV{k, v} = x
  EP{False{}, k, v, acc}

def ep_link(s: EP, x: TV) -> EP:
  EP{first, +pk, pv, acc} = s
  TV{k, +v} = x
  EP{False{}, pk, v, E0{pv, v, pk} <> acc}

def ep_pick(fresh: Bool, dup: Bool, s: EP, x: TV) -> EP:
  match fresh dup:
    case True{} _: ep_fresh(s, x)
    case False{} True{}: s
    case False{} False{}: ep_link(s, x)

def ep_go(xs: List<&2, TV>, +s: EP) -> EP:
  match xs:
    case Nil{}: s
    case +x <> t:
      ep_go(t, ep_pick(Bool.or(ep_first(s), Bool.not(U32.is_eq(tv_k(x), ep_pk(s)))),
        U32.is_eq(tv_v(x), ep_pv(s)), s, x))

def lexpos(s: Seg) -> Bool:
  Seg{id, +ax, +ay, +bx, +by} = s
  Bool.or(F64.is_lt(ax, bx), Bool.and(F64.is_eq(ax, bx), F64.is_lt(ay, by)))

type E1 is Data:
  E1{ u: U32, v: U32, k: U32, id: U64, fwd: Bool }

def e1_of(st: P.Tb<&2, Seg>, e: E0) -> E1:
  E0{u, v, +k} = e
  +s = P.tb_get(Seg, st, k)
  E1{u, v, k, s_id(s), lexpos(s)}

def e1_tie(c: X.Sgn, +ia: U64, +ib: U64) -> X.Sgn:
  match c:
    case X.Sz{}: id_cmp_go(ia, ib)
    case _: c

def e1_cmp_go(+a: E1, +b: E1) -> X.Sgn:
  E1{+ua, +va, ka, +ia, fa} = a
  E1{+ub, +vb, kb, +ib, fb} = b
  e1_tie(P.lex_u(P.u_cmp(ua, ub), va, vb), ia, ib)

def e1_cmp(a: E1, b: E1) -> X.Sgn:
  e1_cmp_go(a, b)

type IE is Data:
  IE{ u: U32, v: U32, k: U32, fwd: Bool, srcs: List<&2, U64> }

def ie_u(e: IE) -> U32:
  IE{u, v, k, fwd, srcs} = e
  u

def ie_v(e: IE) -> U32:
  IE{u, v, k, fwd, srcs} = e
  v

def ie_k(e: IE) -> U32:
  IE{u, v, k, fwd, srcs} = e
  k

def ie_fwd(e: IE) -> Bool:
  IE{u, v, k, fwd, srcs} = e
  fwd

def ie_srcs(e: IE) -> List<&2, U64>:
  IE{u, v, k, fwd, srcs} = e
  srcs

def ie_same(acc: List<&2, IE>, +x: E1) -> Bool:
  match acc:
    case Nil{}: False{}
    case +h <> t:
      E1{u, v, k, id, fwd} = x
      Bool.and(U32.is_eq(ie_u(h), u), U32.is_eq(ie_v(h), v))

def ie_join(acc: List<&2, IE>, x: E1) -> List<&2, IE>:
  match acc:
    case Nil{}: []
    case h <> t:
      IE{u, v, k, fwd, srcs} = h
      E1{xu, xv, xk, id, xf} = x
      IE{u, v, k, fwd, List.append(&2, U64, srcs, [id])} <> t

def ie_new(x: E1, acc: List<&2, IE>) -> List<&2, IE>:
  E1{u, v, k, +id, fwd} = x
  IE{u, v, k, fwd, [id]} <> acc

def ie_add(same: Bool, acc: List<&2, IE>, x: E1) -> List<&2, IE>:
  match same:
    case True{}: ie_join(acc, x)
    case False{}: ie_new(x, acc)

def ie_go(xs: List<&2, E1>, +acc: List<&2, IE>) -> List<&2, IE>:
  match xs:
    case Nil{}: List.reverse(&2, IE, acc)
    case +x <> t: ie_go(t, ie_add(ie_same(acc, x), acc, x))

type HO is Data:
  HO{ v: U32, h: U32, s: Seg, neg: Bool }

def ho_v(o: HO) -> U32:
  HO{v, h, s, neg} = o
  v

def ho_h(o: HO) -> U32:
  HO{v, h, s, neg} = o
  h

def ho_s(o: HO) -> Seg:
  HO{v, h, s, neg} = o
  s

def ho_neg(o: HO) -> Bool:
  HO{v, h, s, neg} = o
  neg

def hos(+st: P.Tb<&2, Seg>, es: List<&2, IE>, +e: U32) -> List<&2, HO>:
  match es:
    case Nil{}: []
    case x <> t:
      IE{u, v, +k, +fwd, srcs} = x
      +s = P.tb_get(Seg, st, k)
      +h = (e + e : U32)
      HO{u, h, s, Bool.not(fwd)} <> HO{v, (h + 1 : U32), s, fwd} <> hos(st, t, (e + 1 : U32))

def sgn_flip(neg: Bool, s: X.Sgn) -> X.Sgn:
  match neg:
    case True{}: X.sgn_neg(s)
    case False{}: s

def up_go(sy: X.Sgn, sx: X.Sgn) -> Bool:
  match sy:
    case X.Sp{}: True{}
    case X.Sz{}: X.sgn_is(sx, X.Sp{})
    case _: False{}

def seg_up(s: Seg, +neg: Bool) -> Bool:
  Seg{id, +ax, +ay, +bx, +by} = s
  up_go(sgn_flip(neg, f_cmp(by, ay)), sgn_flip(neg, f_cmp(bx, ax)))

def seg_cross(a: Seg, b: Seg) -> X.Sgn:
  Seg{i, +ax1, +ay1, +bx1, +by1} = a
  Seg{j, +ax2, +ay2, +bx2, +by2} = b
  X.dd_sign(bx1, ax1, by2, ay2, by1, ay1, bx2, ax2, False{})

def ccw_go(u1: Bool, u2: Bool, c: X.Sgn) -> X.Sgn:
  match u1 u2:
    case True{} False{}: X.Sn{}
    case False{} True{}: X.Sp{}
    case _ _: X.sgn_neg(c)

def ho_ccw(+a: HO, +b: HO) -> X.Sgn:
  ccw_go(seg_up(ho_s(a), ho_neg(a)), seg_up(ho_s(b), ho_neg(b)),
    sgn_flip(Bool.xor(ho_neg(a), ho_neg(b)), seg_cross(ho_s(a), ho_s(b))))

def ho_tie(c: X.Sgn, +a: HO, +b: HO) -> X.Sgn:
  match c:
    case X.Sz{}: ho_ccw(a, b)
    case _: c

def ho_cmp_go(+a: HO, +b: HO) -> X.Sgn:
  ho_tie(P.u_cmp(ho_v(a), ho_v(b)), a, b)

def ho_cmp(a: HO, b: HO) -> X.Sgn:
  ho_cmp_go(a, b)

type Grp is Data:
  Grp{ v: U32, hs: List<&2, HO> }

type GS is Data:
  GS{ cv: U32, cur: List<&2, HO>, acc: List<&2, Grp> }

def gs_cv(g: GS) -> U32:
  GS{cv, cur, acc} = g
  cv

def gs_step(same: Bool, g: GS, +x: HO) -> GS:
  match same:
    case True{}:
      GS{cv, cur, acc} = g
      GS{cv, x <> cur, acc}
    case False{}:
      GS{cv, cur, acc} = g
      GS{ho_v(x), [x], Grp{cv, List.reverse(&2, HO, cur)} <> acc}

def gs_go(xs: List<&2, HO>, +g: GS) -> GS:
  match xs:
    case Nil{}: g
    case +x <> t: gs_go(t, gs_step(U32.is_eq(ho_v(x), gs_cv(g)), g, x))

def gs_fin(g: GS) -> List<&2, Grp>:
  GS{cv, cur, acc} = g
  List.reverse(&2, Grp, Grp{cv, List.reverse(&2, HO, cur)} <> acc)

def groups(xs: List<&2, HO>) -> List<&2, Grp>:
  match xs:
    case Nil{}: []
    case +h <> t: gs_fin(gs_go(t, GS{ho_v(h), [h], []}))

type NP is Data:
  NP{ h: U32, n: U32 }

def np_h(x: NP) -> U32:
  NP{h, n} = x
  h

def np_n(x: NP) -> U32:
  NP{h, n} = x
  n

def np_cmp_go(+a: NP, +b: NP) -> X.Sgn:
  P.u_cmp(np_h(a), np_h(b))

def np_cmp(a: NP, b: NP) -> X.Sgn:
  np_cmp_go(a, b)

def np_go(xs: List<&2, HO>, +prev: U32, acc: List<&2, NP>) -> List<&2, NP>:
  match xs:
    case Nil{}: acc
    case +x <> t: np_go(t, ho_h(x), NP{U32.xor(ho_h(x), 1), prev} <> acc)

def last_h(xs: List<&2, HO>, +d: U32) -> U32:
  match xs:
    case Nil{}: d
    case +x <> t: last_h(t, ho_h(x))

def lu_go(xs: List<&2, HO>, +best: U32, found: Bool, +last: U32) -> U32:
  match xs:
    case Nil{}: P.upick(found, best, last)
    case +x <> t:
      +up = seg_up(ho_s(x), ho_neg(x))
      lu_go(t, P.upick(up, ho_h(x), best), Bool.or(found, up), ho_h(x))

def strict_go(xs: List<&2, HO>, +prev: HO) -> Bool:
  match xs:
    case Nil{}: True{}
    case +x <> t: Bool.and(X.sgn_is(ho_ccw(prev, x), X.Sn{}), strict_go(t, x))

def strict(xs: List<&2, HO>) -> Bool:
  match xs:
    case Nil{}: True{}
    case +h <> t: strict_go(t, h)

type GR is Data:
  GR{ ok: Bool, lu: U32, nps: List<&2, NP> }

def gr_of(u: Unit, g: Grp) -> GR:
  Grp{v, +hs} = g
  GR{strict(hs), lu_go(hs, 0, False{}, 0), np_go(hs, last_h(hs, 0), [])}

def gr_ok(x: GR) -> Bool:
  GR{ok, lu, nps} = x
  ok

def gr_lu(x: GR) -> U32:
  GR{ok, lu, nps} = x
  lu

def gr_nps(x: GR) -> List<&2, NP>:
  GR{ok, lu, nps} = x
  nps

def grs_ok(xs: List<&2, GR>) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(gr_ok(h), grs_ok(t))

def grs_lu(xs: List<&2, GR>) -> List<&2, U32>:
  match xs:
    case Nil{}: []
    case h <> t: gr_lu(h) <> grs_lu(t)

def grs_nps(xs: List<&2, GR>) -> List<&2, NP>:
  match xs:
    case Nil{}: []
    case h <> t: List.append(&2, NP, gr_nps(h), grs_nps(t))

def nps_n(xs: List<&2, NP>) -> List<&2, U32>:
  match xs:
    case Nil{}: []
    case h <> t: np_n(h) <> nps_n(t)

type PJ is Data:
  PJ{ m: U32, j: U32 }

type PJT is Data:
  PJT{ tm: P.Tb<&2, U32>, tj: P.Tb<&2, U32> }

def pj_ms(xs: List<&2, PJ>) -> List<&2, U32>:
  match xs:
    case Nil{}: []
    case h <> t:
      PJ{m, j} = h
      m <> pj_ms(t)

def pj_js(xs: List<&2, PJ>) -> List<&2, U32>:
  match xs:
    case Nil{}: []
    case h <> t:
      PJ{m, j} = h
      j <> pj_js(t)

def pj_ctx(+xs: List<&2, PJ>) -> PJT:
  PJT{P.tb_of(U32, pj_ms(xs), 0), P.tb_of(U32, pj_js(xs), 0)}

def pj_step(c: PJT, x: PJ) -> PJ:
  PJT{+tm, +tj} = c
  PJ{+m, +j} = x
  PJ{U32.min(m, P.tb_get(U32, tm, j)), P.tb_get(U32, tj, j)}

def pj_rounds(r: Nat, +xs: List<&2, PJ>) -> List<&2, PJ>:
  match r:
    case 0n: xs
    case 1n+q: pj_rounds(q, P.pmap(~PJ, ~PJT, ~PJ, ~pj_step, pj_ctx(xs), xs))

def pj_init(xs: List<&2, U32>, +i: U32) -> List<&2, PJ>:
  match xs:
    case Nil{}: []
    case n <> t: PJ{i, n} <> pj_init(t, (i + 1 : U32))

def jump_min(+nxt: List<&2, U32>) -> List<&2, U32>:
  pj_ms(pj_rounds(P.rounds_of(P.ulen(U32, nxt)), pj_init(nxt, 0)))

def ie_eds(es: List<&2, IE>) -> List<&2, P.Ed>:
  match es:
    case Nil{}: []
    case +h <> t: P.Ed{ie_u(h), ie_v(h)} <> ie_eds(t)

def cc_ok(c: P.CC) -> Bool:
  P.CC{ok, ps} = c
  ok

def cc_ps(c: P.CC) -> List<&2, U32>:
  P.CC{ok, ps} = c
  ps

type Comp is Data:
  Comp{ root: U32, outer: U32 }

def comp_add(c: Bool, +i: U32, +lu: P.Tb<&2, U32>, +cy: P.Tb<&2, U32>,
    rest: List<&2, Comp>) -> List<&2, Comp>:
  match c:
    case True{}: Comp{i, P.tb_get(U32, cy, P.tb_get(U32, lu, i))} <> rest
    case False{}: rest

def comps_go(ps: List<&2, U32>, +i: U32, +lu: P.Tb<&2, U32>, +cy: P.Tb<&2, U32>) -> List<&2, Comp>:
  match ps:
    case Nil{}: []
    case p <> t: comp_add(U32.is_eq(p, i), i, lu, cy, comps_go(t, (i + 1 : U32), lu, cy))

type D2 is Data:
  D2{ x: X.Ex, y: X.Ex }

def d2_x(d: D2) -> X.Ex:
  D2{x, y} = d
  x

def d2_y(d: D2) -> X.Ex:
  D2{x, y} = d
  y

def d2_neg(neg: Bool, +x: X.Ex, +y: X.Ex) -> D2:
  match neg:
    case True{}: D2{X.ex_neg(x), X.ex_neg(y)}
    case False{}: D2{x, y}

def seg_d2(s: Seg, +neg: Bool) -> D2:
  Seg{id, +ax, +ay, +bx, +by} = s
  d2_neg(neg, X.ex_dif(bx, ax), X.ex_dif(by, ay))

def seg_a2(s: Seg) -> D2:
  Seg{id, ax, ay, bx, by} = s
  D2{X.ex_of(ax), X.ex_of(ay)}

type EG is Data:
  EG{ e: U32, cu: U32, pu: Pt, pv: Pt, d: D2, a: D2 }

def eg_e(g: EG) -> U32:
  EG{e, cu, pu, pv, d, a} = g
  e

def eg_cu(g: EG) -> U32:
  EG{e, cu, pu, pv, d, a} = g
  cu

def eg_pu(g: EG) -> Pt:
  EG{e, cu, pu, pv, d, a} = g
  pu

def eg_pv(g: EG) -> Pt:
  EG{e, cu, pu, pv, d, a} = g
  pv

def eg_d(g: EG) -> D2:
  EG{e, cu, pu, pv, d, a} = g
  d

def eg_a(g: EG) -> D2:
  EG{e, cu, pu, pv, d, a} = g
  a

def eg_nil() -> EG:
  EG{0, 0, PF{0.0f64, 0.0f64}, PF{0.0f64, 0.0f64}, D2{X.ex_zero(), X.ex_zero()},
    D2{X.ex_zero(), X.ex_zero()}}

def egs(es: List<&2, IE>, +i: U32, +tp: P.Tb<&2, U32>, +vp: P.Tb<&2, Pt>,
    +st: P.Tb<&2, Seg>) -> List<&2, EG>:
  match es:
    case Nil{}: []
    case x <> t:
      IE{+u, v, +k, fwd, srcs} = x
      +s = P.tb_get(Seg, st, k)
      EG{i, P.tb_get(U32, tp, u), P.tb_get(Pt, vp, u), P.tb_get(Pt, vp, v),
        seg_d2(s, Bool.not(fwd)), seg_a2(s)} <> egs(t, (i + 1 : U32), tp, vp, st)

def below_sign(+d: D2, +a: D2, +q: Pt) -> X.Sgn:
  +w = pt_rw(q)
  +t1 = X.ex_sub(pt_ry(q), X.ex_mul(d2_y(a), w))
  +t2 = X.ex_sub(pt_rx(q), X.ex_mul(d2_x(a), w))
  X.ex_sign(X.ex_sub(X.ex_mul(d2_x(d), t1), X.ex_mul(d2_y(d), t2)))

def height_n(+d: D2, +a: D2, +xo: X.Ex, +q: Pt) -> X.Ex:
  +w = pt_rw(q)
  X.ex_add(X.ex_mul(X.ex_mul(d2_y(a), X.ex_mul(d2_x(d), xo)), w),
    X.ex_mul(X.ex_mul(X.ex_sub(pt_rx(q), X.ex_mul(d2_x(a), w)), d2_y(d)), xo))

def tie_go(s: X.Sgn, +d1: D2, +d2: D2) -> X.Sgn:
  match s:
    case X.Sz{}:
      X.ex_sign(X.ex_sub(X.ex_mul(d2_y(d1), d2_x(d2)), X.ex_mul(d2_y(d2), d2_x(d1))))
    case _: s

def lower(+g1: EG, +g2: EG, +q: Pt) -> X.Sgn:
  +d1 = eg_d(g1)
  +d2 = eg_d(g2)
  tie_go(X.ex_cmp(height_n(d1, eg_a(g1), d2_x(d2), q), height_n(d2, eg_a(g2), d2_x(d1), q)), d1, d2)

def in_list(xs: List<&2, U32>, +x: U32) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t: Bool.or(U32.is_eq(h, x), in_list(t, x))

type Cand is Data:
  Cand{ ok: Bool, has: Bool }

def cand_go(+free: Bool, +sp: X.Sgn, +spv: X.Sgn, +vert: X.Sgn, +bel: X.Sgn) -> Cand:
  +unc = Bool.or(Bool.or(sg_unc(sp), sg_unc(spv)), Bool.or(sg_unc(vert), sg_unc(bel)))
  +span = Bool.and(Bool.not(X.sgn_is(sp, X.Sp{})), X.sgn_is(spv, X.Sn{}))
  Cand{Bool.not(unc), Bool.and(Bool.and(free, span),
    Bool.and(Bool.not(X.sgn_is(vert, X.Sz{})), X.sgn_is(bel, X.Sn{})))}

def is_cand(+ex: List<&2, U32>, +g: EG, +q: Pt) -> Cand:
  cand_go(Bool.not(in_list(ex, eg_cu(g))), pt_cmpx(eg_pu(g), q), pt_cmpx(q, eg_pv(g)),
    X.ex_sign(d2_x(eg_d(g))), below_sign(eg_d(g), eg_a(g), q))

type Best is Data:
  Best{ ok: Bool, has: Bool, g: EG }

def best_ok(b: Best) -> Bool:
  Best{ok, has, g} = b
  ok

def best_has(b: Best) -> Bool:
  Best{ok, has, g} = b
  has

def best_g(b: Best) -> EG:
  Best{ok, has, g} = b
  g

def best_pick(c: X.Sgn, +ok: Bool, +g: EG, +b: Best) -> Best:
  match c:
    case X.Sn{}: Best{ok, True{}, g}
    case X.Su{}: Best{False{}, True{}, best_g(b)}
    case _: Best{ok, True{}, best_g(b)}

def best_in(bhas: Bool, +ok: Bool, +g: EG, +b: Best, +q: Pt) -> Best:
  match bhas:
    case False{}: Best{ok, True{}, g}
    case True{}: best_pick(lower(g, best_g(b), q), ok, g, b)

def best_go(has: Bool, +cok: Bool, +g: EG, +q: Pt, +b: Best) -> Best:
  match has:
    case False{}: Best{Bool.and(cok, best_ok(b)), best_has(b), best_g(b)}
    case True{}: best_in(best_has(b), Bool.and(cok, best_ok(b)), g, b, q)

def cand_ok(c: Cand) -> Bool:
  Cand{ok, has} = c
  ok

def cand_has(c: Cand) -> Bool:
  Cand{ok, has} = c
  has

def lowest(xs: List<&2, EG>, +ex: List<&2, U32>, +q: Pt, +b: Best) -> Best:
  match xs:
    case Nil{}: b
    case +g <> t:
      +c = is_cand(ex, g, q)
      lowest(t, ex, q, best_go(cand_has(c), cand_ok(c), g, q, b))

def f_pinf() -> F64:
  F64{9218868437227405312u64}

def f_ninf() -> F64:
  F64{18442240474082181120u64}

def lo_of(ok: Bool, +a: F64) -> F64:
  match ok:
    case True{}: (a - F64.fma(F64.abs(a), F64{4427038433705197568u64}, F64{103582791429521408u64}) : F64)
    case False{}: f_ninf()

def hi_of(ok: Bool, +a: F64) -> F64:
  match ok:
    case True{}: (a + F64.fma(F64.abs(a), F64{4427038433705197568u64}, F64{103582791429521408u64}) : F64)
    case False{}: f_pinf()

def pt_lo(p: Pt) -> F64:
  match p:
    case PF{x, y}: x
    case PR{x, y, w}:
      +a = (X.ex_est(x) / X.ex_est(w) : F64)
      lo_of(X.fin(a), a)

def pt_hi(p: Pt) -> F64:
  match p:
    case PF{x, y}: x
    case PR{x, y, w}:
      +a = (X.ex_est(x) / X.ex_est(w) : F64)
      hi_of(X.fin(a), a)

type SX is Data:
  SX{ x0: F64, sc: F64, s: U32 }

def slab(+c: SX, +x: F64) -> U32:
  SX{+x0, +sc, +s} = c
  +t = F64.min(F64.max(((x - x0 : F64) * sc : F64), 0.0f64), U32.to_f64(s))
  U32.min(F64.to_u32(t), (s - 1 : U32))

def eg_lo(g: EG) -> F64:
  EG{e, cu, pu, pv, d, a} = g
  F64.min(pt_lo(pu), pt_lo(pv))

def eg_hi(g: EG) -> F64:
  EG{e, cu, pu, pv, d, a} = g
  F64.max(pt_hi(pu), pt_hi(pv))

def fin_min(xs: List<&2, EG>, +acc: F64) -> F64:
  match xs:
    case Nil{}: acc
    case +g <> t:
      +v = eg_lo(g)
      fin_min(t, P.upick_f(X.fin(v), F64.min(acc, v), acc))

def fin_max(xs: List<&2, EG>, +acc: F64) -> F64:
  match xs:
    case Nil{}: acc
    case +g <> t:
      +v = eg_hi(g)
      fin_max(t, P.upick_f(X.fin(v), F64.max(acc, v), acc))

def sx_mk(+x0: F64, +x1: F64, +s: U32) -> SX:
  +span = (x1 - x0 : F64)
  SX{x0, P.upick_f(Bool.and(X.fin(span), F64.is_lt(0.0f64, span)), (U32.to_f64(s) / span : F64), 0.0f64), s}

def slabs_n(+n: U32) -> U32:
  +d = P.dm_d(P.dims(n))
  P.dm_pow(Nat.div(1n+d, 2n))

type KG is Data:
  KG{ s: U32, g: EG }

def kg_s(x: KG) -> U32:
  KG{s, g} = x
  s

def kg_g(x: KG) -> EG:
  KG{s, g} = x
  g

def kg_cmp_go(+a: KG, +b: KG) -> X.Sgn:
  P.u_cmp(kg_s(a), kg_s(b))

def kg_cmp(a: KG, b: KG) -> X.Sgn:
  kg_cmp_go(a, b)

def emit(fuel: Nat, stop: Bool, +s: U32, +s1: U32, +g: EG, acc: List<&2, KG>) -> List<&2, KG>:
  match fuel:
    case 0n: acc
    case 1n+f:
      match stop:
        case True{}: acc
        case False{}: emit(f, U32.is_eq(s, s1), (s + 1 : U32), s1, g, KG{s, g} <> acc)

def emits(xs: List<&2, EG>, +c: SX, +fuel: Nat, acc: List<&2, KG>) -> List<&2, KG>:
  match xs:
    case Nil{}: acc
    case +g <> t: emits(t, c, fuel, emit(fuel, False{}, slab(c, eg_lo(g)), slab(c, eg_hi(g)), g, acc))

type SLB is Data:
  SLB{ i: U32, cur: List<&2, EG>, out: List<&2, List<&2, EG>> }

def slb_i(b: SLB) -> U32:
  SLB{i, cur, out} = b
  i

def slb_step(same: Bool, b: SLB, +x: KG) -> SLB:
  match same:
    case True{}:
      SLB{i, cur, out} = b
      SLB{i, kg_g(x) <> cur, out}
    case False{}:
      SLB{+i, cur, out} = b
      +gap = U32.to_nat(((kg_s(x) - i : U32) - 1 : U32))
      SLB{kg_s(x), [kg_g(x)], List.append(&2, List<&2, EG>, P.rep_n(List<&2, EG>, gap, []), cur <> out)}

def slb_go(xs: List<&2, KG>, +b: SLB) -> SLB:
  match xs:
    case Nil{}: b
    case +x <> t: slb_go(t, slb_step(U32.is_eq(kg_s(x), slb_i(b)), b, x))

def slb_fin(b: SLB, +s: U32) -> List<&2, List<&2, EG>>:
  SLB{+i, cur, out} = b
  List.reverse(&2, List<&2, EG>, List.append(&2, List<&2, EG>,
    P.rep_n(List<&2, EG>, U32.to_nat(((s - i : U32) - 1 : U32)), []), cur <> out))

def slab_lists(+kgs: List<&2, KG>, +s: U32) -> List<&2, List<&2, EG>>:
  slb_fin(slb_go(kgs, SLB{0, [], []}), s)

type LC is Data:
  LC{ sl: P.Tb<&2, List<&2, EG>>, sx: SX, sf: Nat, cyc: P.Tb<&2, U32>, oc: P.Tb<&2, U32>, vp: P.Tb<&2, Pt>, fuel: Nat }

def lc_sl(c: LC) -> P.Tb<&2, List<&2, EG>>:
  LC{sl, sx, sf, cyc, oc, vp, fuel} = c
  sl

def lc_sx(c: LC) -> SX:
  LC{sl, sx, sf, cyc, oc, vp, fuel} = c
  sx

def lc_sf(c: LC) -> Nat:
  LC{sl, sx, sf, cyc, oc, vp, fuel} = c
  sf

def lc_cyc(c: LC) -> P.Tb<&2, U32>:
  LC{sl, sx, sf, cyc, oc, vp, fuel} = c
  cyc

def lc_oc(c: LC) -> P.Tb<&2, U32>:
  LC{sl, sx, sf, cyc, oc, vp, fuel} = c
  oc

def lc_vp(c: LC) -> P.Tb<&2, Pt>:
  LC{sl, sx, sf, cyc, oc, vp, fuel} = c
  vp

def lc_fuel(c: LC) -> Nat:
  LC{sl, sx, sf, cyc, oc, vp, fuel} = c
  fuel

type SR is Data:
  SR{ done: Bool, face: U32, add: U32, ok: Bool }

def sr_of(has: Bool, +ok: Bool, +e: U32, +c: LC) -> SR:
  match has:
    case False{}: SR{True{}, P.inf(), P.inf(), ok}
    case True{}:
      +f = P.tb_get(U32, lc_cyc(c), ((e + e : U32) + 1 : U32))
      +d = P.tb_get(U32, lc_oc(c), f)
      SR{U32.is_eq(d, P.inf()), f, d, ok}

def lowest_sl(fuel: Nat, stop: Bool, +c: LC, +s: U32, +s1: U32, +ex: List<&2, U32>,
    +q: Pt, +b: Best) -> Best:
  match fuel:
    case 0n: b
    case 1n+f:
      match stop:
        case True{}: b
        case False{}:
          lowest_sl(f, U32.is_eq(s, s1), c, (s + 1 : U32), s1, ex, q,
            lowest(P.tb_get(List<&2, EG>, lc_sl(c), s), ex, q, b))

def loc_step(+c: LC, +ex: List<&2, U32>, +q: Pt) -> SR:
  +sx = lc_sx(c)
  +b = lowest_sl(lc_sf(c), False{}, c, slab(sx, pt_lo(q)), slab(sx, pt_hi(q)), ex, q,
    Best{True{}, False{}, eg_nil()})
  sr_of(best_has(b), best_ok(b), eg_e(best_g(b)), c)

type LR is Data:
  LR{ ok: Bool, face: U32 }

def loc_go(fuel: Nat, st: SR, +c: LC, +ex: List<&2, U32>, +q: Pt, +acc: Bool) -> LR:
  match fuel:
    case 0n: LR{False{}, P.inf()}
    case 1n+g:
      SR{done, +face, +add, +ok} = st
      match done:
        case True{}: LR{Bool.and(acc, ok), face}
        case False{}:
          +ex2 = {add <> ex : List<&2, U32>}
          loc_go(g, loc_step(c, ex2, q), c, ex2, q, Bool.and(acc, ok))

def loc_comp_go(+c: LC, x: Comp) -> LR:
  Comp{+root, outer} = x
  +q = P.tb_get(Pt, lc_vp(c), root)
  +ex = {[root] : List<&2, U32>}
  loc_go(lc_fuel(c), loc_step(c, ex, q), c, ex, q, True{})

type KV is Data:
  KV{ k: U32, v: U32 }

def kv_k(x: KV) -> U32:
  KV{k, v} = x
  k

def kv_v(x: KV) -> U32:
  KV{k, v} = x
  v

def kv_cmp_go(+a: KV, +b: KV) -> X.Sgn:
  P.u_cmp(kv_k(a), kv_k(b))

def kv_cmp(a: KV, b: KV) -> X.Sgn:
  kv_cmp_go(a, b)

def kv_peek(xs: List<&2, KV>, +i: U32) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t: U32.is_eq(kv_k(h), i)

def kv_tail(xs: List<&2, KV>) -> List<&2, KV>:
  match xs:
    case Nil{}: []
    case h <> t: t

def kv_hv(xs: List<&2, KV>, +d: U32) -> U32:
  match xs:
    case Nil{}: d
    case h <> t: kv_v(h)

def fill_go(ds: List<&2, U32>, +i: U32, +kvs: List<&2, KV>, hit: Bool, +dflt: U32,
    +self: Bool) -> List<&2, U32>:
  match ds:
    case Nil{}: []
    case c <> t:
      match hit:
        case True{}:
          +j = (i + 1 : U32)
          +rest = kv_tail(kvs)
          kv_hv(kvs, dflt) <> fill_go(t, j, rest, kv_peek(rest, j), dflt, self)
        case False{}:
          +j = (i + 1 : U32)
          P.upick(Bool.and(self, U32.is_eq(c, i)), i, dflt) <> fill_go(t, j, kvs, kv_peek(kvs, j), dflt, self)

def fill(+ds: List<&2, U32>, +kvs: List<&2, KV>, +dflt: U32, +self: Bool) -> List<&2, U32>:
  fill_go(ds, 0, kvs, kv_peek(kvs, 0), dflt, self)

def oc_kvs(xs: List<&2, Comp>) -> List<&2, KV>:
  match xs:
    case Nil{}: []
    case h <> t:
      Comp{root, outer} = h
      KV{outer, root} <> oc_kvs(t)

type NJ is Data:
  NJ{ term: Bool, face: U32, nxt: U32, ok: Bool }

def nj_from(has: Bool, +ok: Bool, +e: U32, +c: LC, +pos: P.Tb<&2, U32>) -> NJ:
  match has:
    case False{}: NJ{True{}, P.inf(), 0, ok}
    case True{}:
      +f = P.tb_get(U32, lc_cyc(c), ((e + e : U32) + 1 : U32))
      +d = P.tb_get(U32, lc_oc(c), f)
      +t = U32.is_eq(d, P.inf())
      NJ{t, f, P.upick(t, 0, P.tb_get(U32, pos, d)), ok}

type NC is Data:
  NC{ lc: LC, pos: P.Tb<&2, U32> }

def nj_of_go(+c: NC, x: Comp) -> NJ:
  NC{+lc, +pos} = c
  Comp{+root, outer} = x
  +q = P.tb_get(Pt, lc_vp(lc), root)
  +sx = lc_sx(lc)
  +b = lowest_sl(lc_sf(lc), False{}, lc, slab(sx, pt_lo(q)), slab(sx, pt_hi(q)), [root], q,
    Best{True{}, False{}, eg_nil()})
  nj_from(best_has(b), best_ok(b), eg_e(best_g(b)), lc, pos)

def nj_of(c: NC, x: Comp) -> NJ:
  nj_of_go(c, x)

def nj_hop(term: Bool, +x: NJ, +y: NJ) -> NJ:
  match term:
    case True{}: x
    case False{}:
      NJ{xt, xf, xn, xo} = x
      NJ{yt, yf, yn, yo} = y
      NJ{yt, yf, yn, Bool.and(xo, yo)}

def nj_term(x: NJ) -> Bool:
  NJ{term, face, nxt, ok} = x
  term

def nj_nxt(x: NJ) -> U32:
  NJ{term, face, nxt, ok} = x
  nxt

def nj_step_go(+t: P.Tb<&2, NJ>, +x: NJ) -> NJ:
  nj_hop(nj_term(x), x, P.tb_get(NJ, t, nj_nxt(x)))

def nj_step(t: P.Tb<&2, NJ>, x: NJ) -> NJ:
  nj_step_go(t, x)

def nj_rounds(r: Nat, +xs: List<&2, NJ>) -> List<&2, NJ>:
  match r:
    case 0n: xs
    case 1n+q:
      nj_rounds(q, P.pmap(~NJ, ~P.Tb<&2, NJ>, ~NJ, ~nj_step, P.tb_of(NJ, xs, NJ{True{}, P.inf(), 0, True{}}), xs))

type CJ is Data:
  CJ{ c: Comp, j: NJ }

def cjs(xs: List<&2, Comp>, ys: List<&2, NJ>) -> List<&2, CJ>:
  match xs:
    case Nil{}: []
    case h <> t:
      match ys:
        case Nil{}: []
        case y <> yt: CJ{h, y} <> cjs(t, yt)

def lr_pick(term: Bool, +c: LC, +x: Comp, +j: NJ) -> LR:
  match term:
    case True{}:
      NJ{t, face, nxt, ok} = j
      LR{ok, face}
    case False{}: loc_comp_go(c, x)

def lr_of_go(+c: LC, x: CJ) -> LR:
  CJ{+cm, +j} = x
  lr_pick(nj_term(j), c, cm, j)

def lr_of(c: LC, x: CJ) -> LR:
  lr_of_go(c, x)

def pos_kvs(xs: List<&2, Comp>, +i: U32) -> List<&2, KV>:
  match xs:
    case Nil{}: []
    case h <> t:
      Comp{root, outer} = h
      KV{root, i} <> pos_kvs(t, (i + 1 : U32))

def rg_kv(c: Comp, l: LR) -> KV:
  Comp{root, outer} = c
  LR{ok, face} = l
  KV{outer, face}

def rg_kvs(xs: List<&2, Comp>, ls: List<&2, LR>) -> List<&2, KV>:
  match xs:
    case Nil{}: []
    case h <> t:
      match ls:
        case Nil{}: []
        case l <> lt: rg_kv(h, l) <> rg_kvs(t, lt)

def lrs_ok(xs: List<&2, LR>) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t:
      LR{ok, face} = h
      Bool.and(ok, lrs_ok(t))

type KC is Data:
  KC{ nx: P.Tb<&2, U32>, cy: P.Tb<&2, U32>, rg: P.Tb<&2, U32>, fuel: Nat }

def kc_nx(c: KC) -> P.Tb<&2, U32>:
  KC{nx, cy, rg, fuel} = c
  nx

def kc_fuel(c: KC) -> Nat:
  KC{nx, cy, rg, fuel} = c
  fuel

def rg_at(+c: KC, +h: U32) -> U32:
  KC{nx, cy, rg, fuel} = c
  P.tb_get(U32, rg, P.tb_get(U32, cy, h))

def kept_in(+c: KC, +g: U32, +f: U32) -> Bool:
  Bool.and(U32.is_eq(rg_at(c, g), f), Bool.not(U32.is_eq(rg_at(c, U32.xor(g, 1)), f)))

def nk_go(fuel: Nat, hit: Bool, +c: KC, +g: U32, +f: U32) -> U32:
  match fuel:
    case 0n: g
    case 1n+q:
      match hit:
        case True{}: g
        case False{}:
          +g2 = P.tb_get(U32, kc_nx(c), U32.xor(g, 1))
          nk_go(q, kept_in(c, g2, f), c, g2, f)

type NK is Data:
  NK{ kept: Bool, f: U32, nk: U32 }

def nk_pick(kept: Bool, +c: KC, +h: U32, +f: U32) -> U32:
  match kept:
    case True{}:
      +g0 = P.tb_get(U32, kc_nx(c), h)
      nk_go(kc_fuel(c), kept_in(c, g0, f), c, g0, f)
    case False{}: h

def nk_of_go(+c: KC, +h: U32) -> NK:
  +f = rg_at(c, h)
  +kept = Bool.and(Bool.not(U32.is_eq(f, P.inf())), Bool.not(U32.is_eq(rg_at(c, U32.xor(h, 1)), f)))
  NK{kept, f, nk_pick(kept, c, h, f)}

def nk_of(c: KC, h: U32) -> NK:
  nk_of_go(c, h)

def nk_nk(x: NK) -> U32:
  NK{kept, f, nk} = x
  nk

def nks_nk(xs: List<&2, NK>) -> List<&2, U32>:
  match xs:
    case Nil{}: []
    case h <> t: nk_nk(h) <> nks_nk(t)

type ST is Data:
  ST{ h: U32, f: U32 }

def st_add(c: Bool, +h: U32, +f: U32, rest: List<&2, ST>) -> List<&2, ST>:
  match c:
    case True{}: ST{h, f} <> rest
    case False{}: rest

def st_nk(x: NK, +m: U32, +i: U32, rest: List<&2, ST>) -> List<&2, ST>:
  NK{kept, f, nk} = x
  st_add(Bool.and(kept, U32.is_eq(m, i)), i, f, rest)

def starts(xs: List<&2, NK>, ms: List<&2, U32>, +i: U32) -> List<&2, ST>:
  match xs:
    case Nil{}: []
    case x <> t:
      match ms:
        case Nil{}: []
        case m <> mt: st_nk(x, m, i, starts(t, mt, (i + 1 : U32)))

type WC is Data:
  WC{ tn: P.Tb<&2, U32>, te: P.Tb<&2, IE>, st: P.Tb<&2, Seg>, vk: P.Tb<&2, VKey>, fuel: Nat }

def wc_tn(c: WC) -> P.Tb<&2, U32>:
  WC{tn, te, st, vk, fuel} = c
  tn

def wc_te(c: WC) -> P.Tb<&2, IE>:
  WC{tn, te, st, vk, fuel} = c
  te

def wc_st(c: WC) -> P.Tb<&2, Seg>:
  WC{tn, te, st, vk, fuel} = c
  st

def wc_fuel(c: WC) -> Nat:
  WC{tn, te, st, vk, fuel} = c
  fuel

def walk(fuel: Nat, stop: Bool, +tn: P.Tb<&2, U32>, +h0: U32, +h: U32,
    acc: List<&2, U32>) -> List<&2, U32>:
  match fuel:
    case 0n: List.reverse(&2, U32, acc)
    case 1n+q:
      match stop:
        case True{}: List.reverse(&2, U32, acc)
        case False{}:
          +nx = P.tb_get(U32, tn, h)
          walk(q, U32.is_eq(nx, h0), tn, h0, nx, h <> acc)

def he_even(+h: U32) -> Bool:
  U32.is_eq(U32.and(h, 1), 0)

def he_org(+te: P.Tb<&2, IE>, +h: U32) -> U32:
  +e = P.tb_get(IE, te, U32.shr(h))
  P.upick(he_even(h), ie_u(e), ie_v(e))

def he_neg(+te: P.Tb<&2, IE>, +h: U32) -> Bool:
  +f = ie_fwd(P.tb_get(IE, te, U32.shr(h)))
  Bool.xor(he_even(h), f)

def he_seg(+te: P.Tb<&2, IE>, +st: P.Tb<&2, Seg>, +h: U32) -> Seg:
  P.tb_get(Seg, st, ie_k(P.tb_get(IE, te, U32.shr(h))))

def orgs(+te: P.Tb<&2, IE>, hs: List<&2, U32>) -> List<&2, U32>:
  match hs:
    case Nil{}: []
    case h <> t: he_org(te, h) <> orgs(te, t)

def minidx(xs: List<&2, U32>, +i: U32, +bi: U32, +bv: U32) -> U32:
  match xs:
    case Nil{}: bi
    case +x <> t:
      +lt = U32.is_lt(x, bv)
      minidx(t, (i + 1 : U32), P.upick(lt, i, bi), P.upick(lt, x, bv))

def nth_u(xs: List<&2, U32>, +i: U32, +d: U32) -> U32:
  match xs:
    case Nil{}: d
    case +x <> t: P.upick(U32.is_eq(i, 0), x, nth_u(t, (i - 1 : U32), d))

def he_cross(+te: P.Tb<&2, IE>, +st: P.Tb<&2, Seg>, +a: U32, +b: U32) -> X.Sgn:
  sgn_flip(Bool.xor(he_neg(te, a), he_neg(te, b)), seg_cross(he_seg(te, st, a), he_seg(te, st, b)))

type LP is Data:
  LP{ f: U32, hs: List<&2, U32>, key: List<&2, U32>, turn: X.Sgn }

def lp_mk(+c: WC, +f: U32, +hs: List<&2, U32>) -> LP:
  +te = wc_te(c)
  +st = wc_st(c)
  +os = orgs(te, hs)
  +n = P.ulen(U32, hs)
  +m = minidx(os, 0, 0, P.inf())
  +hin = nth_u(hs, P.upick(U32.is_eq(m, 0), (n - 1 : U32), (m - 1 : U32)), 0)
  +hout = nth_u(hs, m, 0)
  +z = U32.is_eq(m, 0)
  LP{f, List.append(&2, U32, P.drop_u(U32, hs, m, z), P.take_u(U32, hs, m, z)),
    List.append(&2, U32, P.drop_u(U32, os, m, z), P.take_u(U32, os, m, z)),
    he_cross(te, st, hin, hout)}

def lp_of_go(+c: WC, s: ST) -> LP:
  ST{+h, +f} = s
  lp_mk(c, f, walk(wc_fuel(c), False{}, wc_tn(c), h, h, []))

def lp_of(c: WC, s: ST) -> LP:
  lp_of_go(c, s)

def lex_pick(c: X.Sgn, r: X.Sgn) -> X.Sgn:
  match c:
    case X.Sz{}: r
    case _: c

def nl_cmp(a: List<&2, U32>, b: List<&2, U32>) -> X.Sgn:
  match a b:
    case Nil{} Nil{}: X.Sz{}
    case Nil{} _: X.Sn{}
    case _ Nil{}: X.Sp{}
    case Con{+x, xt} Con{+y, yt}: lex_pick(P.u_cmp(x, y), nl_cmp(xt, yt))

def lp_f(x: LP) -> U32:
  LP{f, hs, key, turn} = x
  f

def lp_key(x: LP) -> List<&2, U32>:
  LP{f, hs, key, turn} = x
  key

def lp_hs(x: LP) -> List<&2, U32>:
  LP{f, hs, key, turn} = x
  hs

def lp_turn(x: LP) -> X.Sgn:
  LP{f, hs, key, turn} = x
  turn

def lp_cmp_go(+a: LP, +b: LP) -> X.Sgn:
  lex_pick(P.u_cmp(lp_f(a), lp_f(b)), nl_cmp(lp_key(a), lp_key(b)))

def lp_cmp(a: LP, b: LP) -> X.Sgn:
  lp_cmp_go(a, b)

def ohe_of(+te: P.Tb<&2, IE>, +vk: P.Tb<&2, VKey>, +h: U32) -> OHE:
  OHE{P.tb_get(VKey, vk, he_org(te, h)), P.tb_get(VKey, vk, he_org(te, U32.xor(h, 1))),
    ie_srcs(P.tb_get(IE, te, U32.shr(h)))}

def ohes(+te: P.Tb<&2, IE>, +vk: P.Tb<&2, VKey>, hs: List<&2, U32>) -> List<&2, OHE>:
  match hs:
    case Nil{}: []
    case h <> t: ohe_of(te, vk, h) <> ohes(te, vk, t)

type RR is Data:
  RR{ key: List<&2, U32>, reg: Region }

type RB is Data:
  RB{ ok: Bool, cf: U32, outs: List<&2, LP>, holes: List<&2, LP>, acc: List<&2, RR> }

def holes_ohe(+te: P.Tb<&2, IE>, +vk: P.Tb<&2, VKey>, xs: List<&2, LP>) -> List<&2, List<&2, OHE>>:
  match xs:
    case Nil{}: []
    case h <> t: ohes(te, vk, lp_hs(h)) <> holes_ohe(te, vk, t)

def rb_close(+te: P.Tb<&2, IE>, +vk: P.Tb<&2, VKey>, +ok: Bool, outs: List<&2, LP>,
    holes: List<&2, LP>, acc: List<&2, RR>) -> RB:
  match outs:
    case Nil{}: RB{False{}, 0, [], [], acc}
    case +o <> rest:
      match rest:
        case Nil{}:
          +ho = holes_ohe(te, vk, List.reverse(&2, LP, holes))
          RB{ok, 0, [], [], RR{lp_key(o), Region{ohes(te, vk, lp_hs(o)), ho}} <> acc}
        case r <> rt: RB{False{}, 0, [], [], acc}

def rb_ok(b: RB) -> Bool:
  RB{ok, cf, outs, holes, acc} = b
  ok

def rb_acc(b: RB) -> List<&2, RR>:
  RB{ok, cf, outs, holes, acc} = b
  acc

def rb_cf(b: RB) -> U32:
  RB{ok, cf, outs, holes, acc} = b
  cf

def rb_put(t: X.Sgn, b: RB, +x: LP) -> RB:
  match t:
    case X.Sp{}:
      RB{ok, cf, outs, holes, acc} = b
      RB{ok, cf, x <> outs, holes, acc}
    case X.Sn{}:
      RB{ok, cf, outs, holes, acc} = b
      RB{ok, cf, outs, x <> holes, acc}
    case _:
      RB{ok, cf, outs, holes, acc} = b
      RB{False{}, cf, outs, holes, acc}

def rb_new(+te: P.Tb<&2, IE>, +vk: P.Tb<&2, VKey>, b: RB, +x: LP) -> RB:
  RB{ok, cf, outs, holes, acc} = b
  +c = rb_close(te, vk, ok, outs, holes, acc)
  rb_put(lp_turn(x), RB{rb_ok(c), lp_f(x), [], [], rb_acc(c)}, x)

def rb_step(same: Bool, +te: P.Tb<&2, IE>, +vk: P.Tb<&2, VKey>, b: RB, +x: LP) -> RB:
  match same:
    case True{}: rb_put(lp_turn(x), b, x)
    case False{}: rb_new(te, vk, b, x)

def rb_go(xs: List<&2, LP>, +te: P.Tb<&2, IE>, +vk: P.Tb<&2, VKey>, +b: RB) -> RB:
  match xs:
    case Nil{}: b
    case +x <> t: rb_go(t, te, vk, rb_step(U32.is_eq(lp_f(x), rb_cf(b)), te, vk, b, x))

def rb_fin(+te: P.Tb<&2, IE>, +vk: P.Tb<&2, VKey>, b: RB) -> RB:
  RB{ok, cf, outs, holes, acc} = b
  rb_close(te, vk, ok, outs, holes, acc)

def regions_of(+te: P.Tb<&2, IE>, +vk: P.Tb<&2, VKey>, xs: List<&2, LP>) -> RB:
  match xs:
    case Nil{}: RB{True{}, 0, [], [], []}
    case +x <> t:
      rb_fin(te, vk, rb_go(t, te, vk, rb_put(lp_turn(x), RB{True{}, lp_f(x), [], [], []}, x)))

def rr_key(r: RR) -> List<&2, U32>:
  RR{key, reg} = r
  key

def rr_reg(r: RR) -> Region:
  RR{key, reg} = r
  reg

def rr_cmp_go(+a: RR, +b: RR) -> X.Sgn:
  nl_cmp(rr_key(a), rr_key(b))

def rr_cmp(a: RR, b: RR) -> X.Sgn:
  rr_cmp_go(a, b)

def rrs_reg(xs: List<&2, RR>) -> List<&2, Region>:
  match xs:
    case Nil{}: []
    case h <> t: rr_reg(h) <> rrs_reg(t)

type DC is Data:
  DC{ kc: KC, te: P.Tb<&2, IE>, vk: P.Tb<&2, VKey> }

def dang_pick(c: Bool, +te: P.Tb<&2, IE>, +vk: P.Tb<&2, VKey>, +h: U32) -> List<&2, OHE>:
  match c:
    case True{}: [ohe_of(te, vk, h)]
    case False{}: []

def dang_of_go(+c: DC, +e: U32) -> List<&2, OHE>:
  DC{+kc, +te, +vk} = c
  +h = (e + e : U32)
  dang_pick(U32.is_eq(rg_at(kc, h), rg_at(kc, (h + 1 : U32))), te, vk, h)

def dang_of(c: DC, e: U32) -> List<&2, OHE>:
  dang_of_go(c, e)

def ie_nil() -> IE:
  IE{0, 0, 0, True{}, []}

def vx_keys(xs: List<&2, VX>) -> List<&2, VKey>:
  match xs:
    case Nil{}: []
    case h <> t: vx_key(h) <> vx_keys(t)

def vx_ps(xs: List<&2, VX>) -> List<&2, Pt>:
  match xs:
    case Nil{}: []
    case h <> t: vx_p(h) <> vx_ps(t)

def vg_tv(g: VG) -> List<&2, TV>:
  VG{ok, vid, cur, vs, tv} = g
  tv

def vg_ok(g: VG) -> Bool:
  VG{ok, vid, cur, vs, tv} = g
  ok

def so_ok(-A: Data, s: P.So<&2, A>) -> Bool:
  P.So{ok, xs} = s
  ok

def so_xs(-A: Data, s: P.So<&2, A>) -> List<&2, A>:
  P.So{ok, xs} = s
  xs

def has_any(-A: Data, xs: List<&2, A>) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t: True{}

def res_pick(ok: Bool, r: ARes) -> ARes:
  match ok:
    case True{}: r
    case False{}: A_err{T.F_uncertain{}}

def arr_build(+segs: List<&2, Seg>) -> ARes:
  +sis = number(segs, 0)
  +st = P.tb_of(Seg, segs, seg_nil())
  +ssort = P.msort(~SI, ~si_cmp, sis)
  +pst = P.pflat(~Pr, ~TS, ~pr_stops, cands(so_xs(SI, ssort), []))
  +tsort = P.msort(~TS, ~ts_cmp, List.append(&2, TS, own_stops(sis), so_xs(TS, pst)))
  +tss = so_xs(TS, tsort)
  +vg = vgroup(tss)
  +verts = vg_verts(vg, has_any(TS, tss))
  +tvs = P.msort(~TV, ~tv_cmp, vg_tv(vg))
  +e0 = ep_acc(ep_go(so_xs(TV, tvs), EP{True{}, 0, 0, []}))
  +e1 = P.msort(~E1, ~e1_cmp, P.pmap(~E0, ~P.Tb<&2, Seg>, ~E1, ~e1_of, st, e0))
  +es = ie_go(so_xs(E1, e1), [])
  +hsort = P.msort(~HO, ~ho_cmp, hos(st, es, 0))
  +grs = P.pmap(~Grp, ~Unit, ~GR, ~gr_of, Unit{}, groups(so_xs(HO, hsort)))
  +nps = P.msort(~NP, ~np_cmp, grs_nps(grs))
  +nxt = nps_n(so_xs(NP, nps))
  +cyl = jump_min(nxt)
  +tcy = P.tb_of(U32, cyl, 0)
  +tlu = P.tb_of(U32, grs_lu(grs), 0)
  +nv = P.ulen(VX, verts)
  +cc = P.components(nv, ie_eds(es))
  +ps = cc_ps(cc)
  +comps = comps_go(ps, 0, tlu, tcy)
  +vp = P.tb_of(Pt, vx_ps(verts), PF{0.0f64, 0.0f64})
  +eg = egs(es, 0, P.tb_of(U32, ps, 0), vp, st)
  +ock = P.msort(~KV, ~kv_cmp, oc_kvs(comps))
  +oc = P.tb_of(U32, fill(cyl, so_xs(KV, ock), P.inf(), False{}), P.inf())
  +nc = P.ulen(Comp, comps)
  +ns = slabs_n(P.ulen(IE, es))
  +sx = sx_mk(fin_min(eg, f_pinf()), fin_max(eg, f_ninf()), ns)
  +sfu = U32.to_nat((ns + 1 : U32))
  +kgs = P.msort(~KG, ~kg_cmp, emits(eg, sx, sfu, []))
  +sl = P.tb_of(List<&2, EG>, slab_lists(so_xs(KG, kgs), ns), [])
  +lc = {LC{sl, sx, sfu, tcy, oc, vp, U32.to_nat((nc + 1 : U32))} : LC}
  +pos = P.tb_of(U32, fill(P.iota_go(VX, verts, 0), pos_kvs(comps, 0), P.inf(), False{}), P.inf())
  +njs = nj_rounds(1n+P.rounds_of(nc), P.pmap(~Comp, ~NC, ~NJ, ~nj_of, NC{lc, pos}, comps))
  +lrs = P.pmap(~CJ, ~LC, ~LR, ~lr_of, lc, cjs(comps, njs))
  +rgk = P.msort(~KV, ~kv_cmp, rg_kvs(comps, lrs))
  +rg = P.tb_of(U32, fill(cyl, so_xs(KV, rgk), P.inf(), True{}), P.inf())
  +hfuel = U32.to_nat((P.ulen(U32, cyl) + 1 : U32))
  +kc = {KC{P.tb_of(U32, nxt, 0), tcy, rg, hfuel} : KC}
  +nks = P.pmap(~U32, ~KC, ~NK, ~nk_of, kc, P.iota_go(U32, cyl, 0))
  +nkl = nks_nk(nks)
  +sts = starts(nks, jump_min(nkl), 0)
  +te = P.tb_of(IE, es, ie_nil())
  +vk = P.tb_of(VKey, vx_keys(verts), VK_end{0u64, 0u64})
  +lps = P.pmap(~ST, ~WC, ~LP, ~lp_of, WC{P.tb_of(U32, nkl, 0), te, st, vk, hfuel}, sts)
  +lsort = P.msort(~LP, ~lp_cmp, lps)
  +rb = regions_of(te, vk, so_xs(LP, lsort))
  +rsort = P.msort(~RR, ~rr_cmp, rb_acc(rb))
  +dang = List.concat(&2, OHE, P.pmap(~U32, ~DC, ~List<&2, OHE>, ~dang_of, DC{kc, te, vk}, P.iota_go(IE, es, 0)))
  +ok = P.ands([so_ok(SI, ssort), so_ok(TS, pst), so_ok(TS, tsort), vg_ok(vg), so_ok(TV, tvs),
    so_ok(E1, e1), so_ok(HO, hsort), grs_ok(grs), so_ok(NP, nps), cc_ok(cc), so_ok(KV, ock),
    lrs_ok(lrs), so_ok(KV, rgk), so_ok(LP, lsort), rb_ok(rb), so_ok(RR, rsort)])
  res_pick(ok, A_ok{U32.to_nat(nv), U32.to_nat(P.ulen(IE, es)), U32.to_nat(nc),
    rrs_reg(so_xs(RR, rsort)), dang})

def arrange_fuel(within: Bool, +segs: List<&2, Seg>) -> ARes:
  match within:
    case True{}: arr_build(segs)
    case False{}: A_err{T.F_exhausted{}}

def len_nat(-A: Data, xs: List<&2, A>) -> Nat:
  match xs:
    case Nil{}: 0n
    case h <> t: 1n+len_nat(A, t)

def arrange_go(valid: Bool, +segs: List<&2, Seg>, +fuel: Nat) -> ARes:
  match valid:
    case True{}: arrange_fuel(Nat.is_le(len_nat(Seg, segs), fuel), segs)
    case False{}: A_err{T.F_invalid{}}

def arrange(+segs: List<&2, Seg>, +fuel: Nat) -> ARes:
  arrange_go(segs_ok(segs), segs, fuel)

def id_ins(xs: List<&2, U64>, +x: U64) -> List<&2, U64>:
  match xs:
    case Nil{}: [x]
    case +h <> +t:
      Bool.pick(List<&2, U64>, U64.is_lt(x, h), x <> h <> t,
        Bool.pick(List<&2, U64>, U64.is_eq(x, h), h <> t, h <> id_ins(t, x)))

def ids_union(xs: List<&2, U64>, ys: List<&2, U64>) -> List<&2, U64>:
  match xs:
    case Nil{}: ys
    case h <> t: ids_union(t, id_ins(ys, h))

def vk_show(k: VKey) -> String:
  match k:
    case VK_end{seg, end}: "e" ++ U64.show(seg) ++ "." ++ U64.show(end)
    case VK_x{lo, hi}: "x" ++ U64.show(lo) ++ "." ++ U64.show(hi)

def ids_tail(xs: List<&2, U64>) -> String:
  match xs:
    case Nil{}: ""
    case h <> t: "," ++ U64.show(h) ++ ids_tail(t)

def ids_show(xs: List<&2, U64>) -> String:
  match xs:
    case Nil{}: ""
    case h <> t: U64.show(h) ++ ids_tail(t)

def loop_show(xs: List<&2, OHE>) -> String:
  match xs:
    case Nil{}: ""
    case h <> t:
      OHE{from, to, srcs} = h
      " " ++ vk_show(from) ++ "[" ++ ids_show(srcs) ++ "]" ++ loop_show(t)

def holes_show(xs: List<&2, List<&2, OHE>>) -> String:
  match xs:
    case Nil{}: ""
    case h <> t: " |" ++ loop_show(h) ++ holes_show(t)

def regs_show(xs: List<&2, Region>) -> String:
  match xs:
    case Nil{}: ""
    case h <> t:
      Region{outer, holes} = h
      " {" ++ loop_show(outer) ++ holes_show(holes) ++ " }" ++ regs_show(t)

def dang_show(xs: List<&2, OHE>) -> String:
  match xs:
    case Nil{}: ""
    case h <> t:
      OHE{from, to, srcs} = h
      " " ++ vk_show(from) ++ "-" ++ vk_show(to) ++ dang_show(t)

def ares_show(r: ARes) -> String:
  match r:
    case A_ok{nv, ne, nc, regions, dangling}:
      "v=" ++ Nat.show(nv) ++ " e=" ++ Nat.show(ne) ++ " c=" ++ Nat.show(nc)
        ++ " R" ++ regs_show(regions) ++ " D" ++ dang_show(dangling)
    case A_err{kind}: "err " ++ T.FailKind.show(kind)

def loop_ids(xs: List<&2, OHE>, acc: List<&2, U64>) -> List<&2, U64>:
  match xs:
    case Nil{}: acc
    case h <> t:
      OHE{from, to, srcs} = h
      loop_ids(t, ids_union(srcs, acc))

def holes_ids(xs: List<&2, List<&2, OHE>>, acc: List<&2, U64>) -> List<&2, U64>:
  match xs:
    case Nil{}: acc
    case h <> t: holes_ids(t, loop_ids(h, acc))

def region_key(r: Region) -> List<&2, U64>:
  Region{outer, holes} = r
  holes_ids(holes, loop_ids(outer, []))

def keys_show(xs: List<&2, Region>) -> String:
  match xs:
    case Nil{}: ""
    case h <> t: " [" ++ ids_show(region_key(h)) ++ "]" ++ keys_show(t)

def ares_keys(r: ARes) -> String:
  match r:
    case A_ok{nv, ne, nc, regions, dangling}: "keys" ++ keys_show(regions)
    case A_err{kind}: "err " ++ T.FailKind.show(kind)
