import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ./sf.bend as S
import ./ef.bend as EF
import ./fb.bend as FB
import ./px.bend as PX
import ./ls.bend as L

type ER is Data:
  ER{ key: Nat, va: Nat, vb: Nat, k: Ty.EdgeKind, fwd: Bool }

type PC is Data:
  PC{ va: Nat, vb: Nat, poly: List<&2, V.Vec2>, bnd: Bool, ers: List<&2, ER>, dv: F64 }

type HE is Data:
  HE{ i: Nat, fw: Bool }

type NX is Data:
  NX{ h: HE, w: F64, found: Bool }

type WK is Data:
  WK{ cyc: List<&2, HE>, us: List<&2, Bool>, ok: Bool }

type CY is Data:
  CY{ hes: List<&2, HE>, poly: List<&2, V.Vec2>, wind: F64, area: F64 }

type CS is Data:
  CS{ cys: List<&2, CY>, ok: Bool }

type RG is Data:
  RG{ cys: List<&2, CY>, band: Bool }

type NB is Data:
  NB{ c: CY, d: F64, found: Bool }

type BI is Data:
  BI{ i: Nat, sz: F64, found: Bool }

type RS is Data:
  RS{ rgs: List<&2, RG>, ok: Bool }

type SP is Data:
  SP{ q: V.Vec2, ok: Bool }

def er_key(+e: ER) -> Nat:
  ER{key, va, vb, k, fwd} = e
  key

def er_va(+e: ER) -> Nat:
  ER{key, va, vb, k, fwd} = e
  va

def er_vb(+e: ER) -> Nat:
  ER{key, va, vb, k, fwd} = e
  vb

def er_k(+e: ER) -> Ty.EdgeKind:
  ER{key, va, vb, k, fwd} = e
  k

def er_fwd(+e: ER) -> Bool:
  ER{key, va, vb, k, fwd} = e
  fwd

def pc_va(+p: PC) -> Nat:
  PC{va, vb, poly, bnd, ers, dv} = p
  va

def pc_vb(+p: PC) -> Nat:
  PC{va, vb, poly, bnd, ers, dv} = p
  vb

def pc_poly(+p: PC) -> List<&2, V.Vec2>:
  PC{va, vb, poly, bnd, ers, dv} = p
  poly

def pc_bnd(+p: PC) -> Bool:
  PC{va, vb, poly, bnd, ers, dv} = p
  bnd

def pc_ers(+p: PC) -> List<&2, ER>:
  PC{va, vb, poly, bnd, ers, dv} = p
  ers

def nth_pc(xs: List<&2, PC>, +i: Nat) -> PC:
  match xs:
    case []: PC{0n, 0n, [], False{}, [], 0.0f64}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_pc(t, j)

def he_i(+h: HE) -> Nat:
  HE{i, fw} = h
  i

def he_fw(+h: HE) -> Bool:
  HE{i, fw} = h
  fw

def he_eq(+a: HE, +b: HE) -> Bool:
  Bool.and(Nat.is_eq(he_i(a), he_i(b)), Bool.not(Bool.xor(he_fw(a), he_fw(b))))

def he_from(+pcs: List<&2, PC>, +h: HE) -> Nat:
  +p = nth_pc(pcs, he_i(h))
  Bool.pick(Nat, he_fw(h), pc_va(p), pc_vb(p))

def he_to(+pcs: List<&2, PC>, +h: HE) -> Nat:
  +p = nth_pc(pcs, he_i(h))
  Bool.pick(Nat, he_fw(h), pc_vb(p), pc_va(p))

def he_ok(+pcs: List<&2, PC>, +h: HE) -> Bool:
  Bool.or(he_fw(h), Bool.not(pc_bnd(nth_pc(pcs, he_i(h)))))

def v2sub(+s: S.SF, +a: V.Vec2, +b: V.Vec2) -> V.Vec2:
  +dx = Bool.pick(F64, S.sf_periodic(s), S.ang_diff(V.v2_x(b), V.v2_x(a)), F64.sub(V.v2_x(a), V.v2_x(b)))
  V.V2{dx, F64.sub(V.v2_y(a), V.v2_y(b))}

def rev_v2(xs: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  List.reverse(&2, V.Vec2, xs)

def dir_out(+s: S.SF, +pcs: List<&2, PC>, +h: HE) -> V.Vec2:
  +ps = Bool.pick(List<&2, V.Vec2>, he_fw(h), pc_poly(nth_pc(pcs, he_i(h))), rev_v2(pc_poly(nth_pc(pcs, he_i(h)))))
  v2sub(s, L.nth_v2(ps, 1n), L.nth_v2(ps, 0n))

def ang(+v: V.Vec2) -> F64:
  S.fatan2(V.v2_y(v), V.v2_x(v))

def cw_from(+t: F64, +a: F64) -> F64:
  +d = F64.sub(t, a)
  +w = F64.sub(d, F64.mul(S.two_pi(), S.f_round(F64.div(F64.sub(d, S.pi()), S.two_pi()))))
  Bool.pick(F64, F64.is_le(w, 0.0f64), F64.add(w, S.two_pi()), w)

def hes_go(xs: List<&2, Nat>) -> List<&2, HE>:
  match xs:
    case []: []
    case +h <> +t: HE{h, True{}} <> (HE{h, False{}} <> hes_go(t))

def all_hes(+n: Nat) -> List<&2, HE>:
  hes_go(L.nat_range(n))

def nx_h(+n: NX) -> HE:
  NX{h, w, found} = n
  h

def nx_found(+n: NX) -> Bool:
  NX{h, w, found} = n
  found

def nx_w(+n: NX) -> F64:
  NX{h, w, found} = n
  w

def pick_go(hs: List<&2, HE>, +s: S.SF, +pcs: List<&2, PC>, +v: Nat, +twin: HE, +t: F64, +best: NX)
    -> NX:
  match hs:
    case []: best
    case +h <> +r:
      +here = Bool.and(Nat.is_eq(he_from(pcs, h), v), Bool.not(he_eq(h, twin)))
      +w = cw_from(t, ang(dir_out(s, pcs, h)))
      +better = Bool.and(here, Bool.or(Bool.not(nx_found(best)), F64.is_lt(w, nx_w(best))))
      pick_go(r, s, pcs, v, twin, t, Bool.pick(NX, better, NX{h, w, True{}}, best))

def next_he(+s: S.SF, +pcs: List<&2, PC>, +hs: List<&2, HE>, +h: HE) -> NX:
  +twin = {HE{he_i(h), Bool.not(he_fw(h))} : HE}
  +v = he_to(pcs, h)
  pick_go(hs, s, pcs, v, twin, ang(dir_out(s, pcs, twin)), NX{h, 0.0f64, False{}})

def he_idx(+h: HE) -> Nat:
  Nat.add(Nat.mul(2n, he_i(h)), Bool.pick(Nat, he_fw(h), 0n, 1n))

def set_used(us: List<&2, Bool>, +i: Nat) -> List<&2, Bool>:
  match us:
    case []: []
    case +h <> +t:
      match i:
        case 0n: True{} <> t
        case 1n+j: h <> set_used(t, j)

def nth_b(xs: List<&2, Bool>, +i: Nat) -> Bool:
  match xs:
    case []: True{}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_b(t, j)

def wk_cyc(+w: WK) -> List<&2, HE>:
  WK{cyc, us, ok} = w
  cyc

def wk_us(+w: WK) -> List<&2, Bool>:
  WK{cyc, us, ok} = w
  us

def wk_ok(+w: WK) -> Bool:
  WK{cyc, us, ok} = w
  ok

def walk(n: Nat, +mode: U64, +s: S.SF, +pcs: List<&2, PC>, +hs: List<&2, HE>, +start: HE,
    +cur: HE, +acc: List<&2, HE>, +us: List<&2, Bool>) -> WK:
  match n:
    case 0n: WK{List.reverse(&2, HE, acc), us, False{}}
    case 1n+(+m):
      match mode:
        case 0u64:
          +nx = next_he(s, pcs, hs, cur)
          +h = nx_h(nx)
          +good = Bool.and(nx_found(nx), he_ok(pcs, h))
          +code = Bool.pick(U64, Bool.not(good), 1u64, Bool.pick(U64, he_eq(h, start), 2u64, 3u64))
          walk(m, code, s, pcs, hs, start, h, acc, us)
        case 1u64: WK{List.reverse(&2, HE, acc), us, False{}}
        case 2u64: WK{List.reverse(&2, HE, acc), us, True{}}
        case _: walk(m, 0u64, s, pcs, hs, start, cur, cur <> acc, set_used(us, he_idx(cur)))

def cy_hes(+c: CY) -> List<&2, HE>:
  CY{hes, poly, wind, area} = c
  hes

def cy_poly(+c: CY) -> List<&2, V.Vec2>:
  CY{hes, poly, wind, area} = c
  poly

def cy_wind(+c: CY) -> F64:
  CY{hes, poly, wind, area} = c
  wind

def cy_area(+c: CY) -> F64:
  CY{hes, poly, wind, area} = c
  area

def shift_x(xs: List<&2, V.Vec2>, +dx: F64) -> List<&2, V.Vec2>:
  match xs:
    case []: []
    case +h <> +t: V.V2{F64.add(V.v2_x(h), dx), V.v2_y(h)} <> shift_x(t, dx)

def he_poly(+pcs: List<&2, PC>, +h: HE) -> List<&2, V.Vec2>:
  Bool.pick(List<&2, V.Vec2>, he_fw(h), pc_poly(nth_pc(pcs, he_i(h))), rev_v2(pc_poly(nth_pc(pcs, he_i(h)))))

def cpoly_go(hs: List<&2, HE>, +s: S.SF, +pcs: List<&2, PC>, +acc: List<&2, V.Vec2>, +have: Bool,
    +last: V.Vec2) -> List<&2, V.Vec2>:
  match hs:
    case []: acc
    case +h <> +t:
      +p = he_poly(pcs, h)
      +p0 = L.nth_v2(p, 0n)
      +dx = Bool.pick(F64, Bool.and(have, S.sf_periodic(s)),
        F64.sub(F64.add(V.v2_x(last), S.ang_diff(V.v2_x(last), V.v2_x(p0))), V.v2_x(p0)), 0.0f64)
      +q = shift_x(p, dx)
      +nq = Bool.pick(List<&2, V.Vec2>, have, FB.drop1(q), q)
      cpoly_go(t, s, pcs, List.append(&2, V.Vec2, acc, nq), True{}, L.last_v2(q, last))

def area_go(ps: List<&2, V.Vec2>, +prev: V.Vec2, +acc: F64) -> F64:
  match ps:
    case []: acc
    case +h <> +t:
      area_go(t, h, F64.add(acc, F64.sub(F64.mul(V.v2_x(prev), V.v2_y(h)), F64.mul(V.v2_x(h), V.v2_y(prev)))))

def poly_area(+ps: List<&2, V.Vec2>) -> F64:
  match ps:
    case []: 0.0f64
    case +h <> +t: F64.mul(0.5f64, area_go(t, h, 0.0f64))

def mk_cy(+s: S.SF, +pcs: List<&2, PC>, +hes: List<&2, HE>) -> CY:
  +p = cpoly_go(hes, s, pcs, [], False{}, V.V2{0.0f64, 0.0f64})
  +x0 = V.v2_x(L.nth_v2(p, 0n))
  +x1 = V.v2_x(L.last_v2(p, V.V2{0.0f64, 0.0f64}))
  +w = Bool.pick(F64, S.sf_periodic(s), S.f_round(F64.div(F64.sub(x1, x0), S.two_pi())), 0.0f64)
  CY{hes, p, w, poly_area(p)}

def cs_cys(+c: CS) -> List<&2, CY>:
  CS{cys, ok} = c
  cys

def cs_ok(+c: CS) -> Bool:
  CS{cys, ok} = c
  ok

def cycles_go(hs: List<&2, HE>, +s: S.SF, +pcs: List<&2, PC>, +all: List<&2, HE>, +fuel: Nat,
    +us: List<&2, Bool>, +acc: List<&2, CY>, +ok: Bool) -> CS:
  match hs:
    case []: CS{List.reverse(&2, CY, acc), ok}
    case +h <> +t:
      +skip = Bool.or(nth_b(us, he_idx(h)), Bool.not(he_ok(pcs, h)))
      +w = walk(Bool.pick(Nat, skip, 0n, fuel), 0u64, s, pcs, all, h, h, [h], set_used(us, he_idx(h)))
      cycles_go(t, s, pcs, all, fuel, Bool.pick(List<&2, Bool>, skip, us, wk_us(w)),
        Bool.pick(List<&2, CY>, skip, acc, mk_cy(s, pcs, wk_cyc(w)) <> acc),
        Bool.pick(Bool, skip, ok, Bool.and(ok, wk_ok(w))))

def fl_go(xs: List<&2, Nat>) -> List<&2, Bool>:
  match xs:
    case []: []
    case +h <> +t: False{} <> fl_go(t)

def false_list(+n: Nat) -> List<&2, Bool>:
  fl_go(L.nat_range(n))

def face_cycles(+s: S.SF, +pcs: List<&2, PC>) -> CS:
  +n = List.length(&2, PC, pcs)
  +all = all_hes(n)
  cycles_go(all, s, pcs, all, Nat.add(Nat.mul(4n, n), 8n), false_list(Nat.mul(2n, n)), [], True{})

def seg_y(+s: S.SF, +a: V.Vec2, +b: V.Vec2, +qx: F64, +up: Bool, +qy: F64) -> List<&2, F64>:
  +ax = V.v2_x(a)
  +bx = V.v2_x(b)
  +x = Bool.pick(F64, S.sf_periodic(s), F64.add(ax, S.ang_diff(ax, qx)), qx)
  +str = Bool.or(Bool.and(F64.is_le(ax, x), F64.is_lt(x, bx)), Bool.and(F64.is_le(bx, x), F64.is_lt(x, ax)))
  +t = F64.div(F64.sub(x, ax), F64.sub(bx, ax))
  +y = F64.add(V.v2_y(a), F64.mul(t, F64.sub(V.v2_y(b), V.v2_y(a))))
  +side = Bool.pick(Bool, up, F64.is_lt(qy, y), F64.is_lt(y, qy))
  Bool.pick(List<&2, F64>, Bool.and(str, side), [y], [])

def ys_go(ps: List<&2, V.Vec2>, +s: S.SF, +prev: V.Vec2, +qx: F64, +up: Bool, +qy: F64) -> List<&2, F64>:
  match ps:
    case []: []
    case +h <> +t: List.append(&2, F64, seg_y(s, prev, h, qx, up, qy), ys_go(t, s, h, qx, up, qy))

def poly_ys(+s: S.SF, +ps: List<&2, V.Vec2>, +qx: F64, +up: Bool, +qy: F64) -> List<&2, F64>:
  match ps:
    case []: []
    case +h <> +t: ys_go(t, s, h, qx, up, qy)

def cy_contains(+s: S.SF, +c: CY, +q: V.Vec2) -> Bool:
  Nat.is_eq(Nat.mod(List.length(&2, F64, poly_ys(s, cy_poly(c), V.v2_x(q), True{}, V.v2_y(q))), 2n), 1n)

def min_abs(ys: List<&2, F64>, +qy: F64, +acc: F64) -> F64:
  match ys:
    case []: acc
    case +h <> +t: min_abs(t, qy, F64.min(acc, F64.abs(F64.sub(h, qy))))

def cy_dist(+s: S.SF, +c: CY, +q: V.Vec2, +up: Bool) -> F64:
  min_abs(poly_ys(s, cy_poly(c), V.v2_x(q), up, V.v2_y(q)), V.v2_y(q), F64.div(1.0f64, 0.0f64))

def rg_cys(+r: RG) -> List<&2, CY>:
  RG{cys, band} = r
  cys

def rg_band(+r: RG) -> Bool:
  RG{cys, band} = r
  band

def is_outer(+c: CY) -> Bool:
  Bool.and(F64.is_eq(cy_wind(c), 0.0f64), F64.is_lt(0.0f64, cy_area(c)))

def is_hole(+c: CY) -> Bool:
  Bool.and(F64.is_eq(cy_wind(c), 0.0f64), F64.is_le(cy_area(c), 0.0f64))

def is_up(+c: CY) -> Bool:
  F64.is_eq(cy_wind(c), 1.0f64)

def is_dn(+c: CY) -> Bool:
  F64.is_eq(cy_wind(c), F64.neg(1.0f64))

def filt(cs: List<&2, CY>, +k: U64) -> List<&2, CY>:
  match cs:
    case []: []
    case +h <> +t:
      +m = Bool.pick(Bool, U64.is_eq(k, 0u64), is_outer(h),
        Bool.pick(Bool, U64.is_eq(k, 1u64), is_hole(h), Bool.pick(Bool, U64.is_eq(k, 2u64), is_up(h), is_dn(h))))
      +rest = filt(t, k)
      Bool.pick(List<&2, CY>, m, h <> rest, rest)

def nb_c(+n: NB) -> CY:
  NB{c, d, found} = n
  c

def nb_found(+n: NB) -> Bool:
  NB{c, d, found} = n
  found

def nb_d(+n: NB) -> F64:
  NB{c, d, found} = n
  d

def nearest(cs: List<&2, CY>, +s: S.SF, +q: V.Vec2, +up: Bool, +best: NB) -> NB:
  match cs:
    case []: best
    case +h <> +t:
      +d = cy_dist(s, h, q, up)
      +pref = Bool.pick(Bool, up, is_dn(h), is_up(h))
      +bpref = Bool.pick(Bool, up, is_dn(nb_c(best)), is_up(nb_c(best)))
      +tie = Bool.and(F64.is_eq(d, nb_d(best)), Bool.and(pref, Bool.not(bpref)))
      +better = Bool.and(F64.is_lt(d, F64.div(1.0f64, 0.0f64)),
        Bool.or(Bool.not(nb_found(best)), Bool.or(F64.is_lt(d, nb_d(best)), tie)))
      nearest(t, s, q, up, Bool.pick(NB, better, NB{h, d, True{}}, best))

def cy0() -> CY:
  CY{[], [], 0.0f64, 0.0f64}

def first_pt(+c: CY) -> V.Vec2:
  L.nth_v2(cy_poly(c), 0n)

def wraps(+cs: List<&2, CY>) -> List<&2, CY>:
  List.append(&2, CY, filt(cs, 2u64), filt(cs, 3u64))

def L_he0(xs: List<&2, HE>) -> HE:
  match xs:
    case []: HE{0n, True{}}
    case +h <> +t: h

def cy_same(+a: CY, +b: CY) -> Bool:
  Bool.and(Nat.is_eq(List.length(&2, HE, cy_hes(a)), List.length(&2, HE, cy_hes(b))),
    he_eq(L_he0(cy_hes(a)), L_he0(cy_hes(b))))

def wrap_but(cs: List<&2, CY>, +x: CY) -> List<&2, CY>:
  match cs:
    case []: []
    case +h <> +t:
      +rest = wrap_but(t, x)
      Bool.pick(List<&2, CY>, cy_same(h, x), rest, h <> rest)

def cand(+a: V.Vec2, +b: V.Vec2, +eps: F64) -> V.Vec2:
  +dx = F64.sub(V.v2_x(b), V.v2_x(a))
  +dy = F64.sub(V.v2_y(b), V.v2_y(a))
  +l = F64.sqrt(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)))
  +mx = F64.mul(0.5f64, F64.add(V.v2_x(a), V.v2_x(b)))
  +my = F64.mul(0.5f64, F64.add(V.v2_y(a), V.v2_y(b)))
  V.V2{F64.sub(mx, F64.mul(eps, dy)), F64.add(my, F64.mul(eps, dx))}

def left_pt(+c: CY) -> V.Vec2:
  +p = cy_poly(c)
  cand(L.nth_v2(p, 0n), L.nth_v2(p, 1n), 0.0001f64)

def bands(ups: List<&2, CY>, +s: S.SF, +all: List<&2, CY>) -> List<&2, RG>:
  match ups:
    case []: []
    case +h <> +t:
      +nb = nearest(wrap_but(all, h), s, left_pt(h), True{}, NB{cy0(), 0.0f64, False{}})
      +ok = Bool.and(nb_found(nb), is_dn(nb_c(nb)))
      +rest = bands(t, s, all)
      Bool.pick(List<&2, RG>, ok, RG{[h, nb_c(nb)], True{}} <> rest, RG{[h], True{}} <> rest)

def outer_rgs(os: List<&2, CY>) -> List<&2, RG>:
  match os:
    case []: []
    case +h <> +t: RG{[h], False{}} <> outer_rgs(t)

def L_cy0(xs: List<&2, CY>) -> CY:
  match xs:
    case []: cy0()
    case +h <> +t: h

def rg_holds(+s: S.SF, +r: RG, +q: V.Vec2, +wr: List<&2, CY>) -> Bool:
  +c0 = L_cy0(rg_cys(r))
  Bool.pick(Bool, rg_band(r),
    cy_same(nb_c(nearest(wr, s, q, False{}, NB{cy0(), 0.0f64, False{}})), c0),
    cy_contains(s, c0, q))

def rg_size(+r: RG) -> F64:
  Bool.pick(F64, rg_band(r), F64.div(1.0f64, 0.0f64), cy_area(L_cy0(rg_cys(r))))

def bi_i(+b: BI) -> Nat:
  BI{i, sz, found} = b
  i

def bi_found(+b: BI) -> Bool:
  BI{i, sz, found} = b
  found

def bi_sz(+b: BI) -> F64:
  BI{i, sz, found} = b
  sz

def best_rg(rs: List<&2, RG>, +s: S.SF, +q: V.Vec2, +wr: List<&2, CY>, +i: Nat, +best: BI) -> BI:
  match rs:
    case []: best
    case +h <> +t:
      +ok = rg_holds(s, h, q, wr)
      +sz = rg_size(h)
      +better = Bool.and(ok, Bool.or(Bool.not(bi_found(best)), F64.is_lt(sz, bi_sz(best))))
      best_rg(t, s, q, wr, Nat.add(i, 1n), Bool.pick(BI, better, BI{i, sz, True{}}, best))

def add_hole(rs: List<&2, RG>, +i: Nat, +c: CY) -> List<&2, RG>:
  match rs:
    case []: []
    case +h <> +t:
      match i:
        case 0n: RG{List.append(&2, CY, rg_cys(h), [c]), rg_band(h)} <> t
        case 1n+j: h <> add_hole(t, j, c)

def rs_rgs(+r: RS) -> List<&2, RG>:
  RS{rgs, ok} = r
  rgs

def rs_ok(+r: RS) -> Bool:
  RS{rgs, ok} = r
  ok

def holes_go(hs: List<&2, CY>, +s: S.SF, +wr: List<&2, CY>, +r: RS) -> RS:
  match hs:
    case []: r
    case +h <> +t:
      +b = best_rg(rs_rgs(r), s, left_pt(h), wr, 0n, BI{0n, 0.0f64, False{}})
      holes_go(t, s, wr, Bool.pick(RS, bi_found(b), RS{add_hole(rs_rgs(r), bi_i(b), h), rs_ok(r)},
        RS{rs_rgs(r), False{}}))

def bands_ok(rs: List<&2, RG>) -> Bool:
  match rs:
    case []: True{}
    case +h <> +t: Bool.and(Nat.is_eq(List.length(&2, CY, rg_cys(h)), 2n), bands_ok(t))

def odd_wind(cs: List<&2, CY>) -> Bool:
  match cs:
    case []: False{}
    case +h <> +t: Bool.or(F64.is_lt(1.0f64, F64.abs(cy_wind(h))), odd_wind(t))

def regions(+s: S.SF, +cs: List<&2, CY>) -> RS:
  +wr = wraps(cs)
  +bs = bands(filt(cs, 2u64), s, wr)
  +base = List.append(&2, RG, outer_rgs(filt(cs, 0u64)), bs)
  +r = holes_go(filt(cs, 1u64), s, wr, RS{base, True{}})
  RS{rs_rgs(r), Bool.and(Bool.and(rs_ok(r), bands_ok(bs)), Bool.not(odd_wind(cs)))}

def L_tail_cy(xs: List<&2, CY>) -> List<&2, CY>:
  xs

def drop1c(xs: List<&2, CY>) -> List<&2, CY>:
  match xs:
    case []: []
    case +h <> +t: t

def drop2(xs: List<&2, CY>) -> List<&2, CY>:
  drop1c(drop1c(xs))

def hole_part(+r: RG) -> List<&2, CY>:
  Bool.pick(List<&2, CY>, rg_band(r), drop2(rg_cys(r)), drop1c(rg_cys(r)))

def any_contains(cs: List<&2, CY>, +s: S.SF, +q: V.Vec2) -> Bool:
  match cs:
    case []: False{}
    case +h <> +t: Bool.or(cy_contains(s, h, q), any_contains(t, s, q))

def rg_inside(+s: S.SF, +r: RG, +q: V.Vec2) -> Bool:
  +cs = rg_cys(r)
  +c0 = L_cy0(cs)
  +inb = Bool.pick(Bool, rg_band(r),
    Bool.and(cy_same(nb_c(nearest(L_tail_cy(cs), s, q, False{}, NB{cy0(), 0.0f64, False{}})), c0),
      F64.is_lt(cy_dist(s, c0, q, False{}), F64.div(1.0f64, 0.0f64))),
    cy_contains(s, c0, q))
  Bool.and(inb, Bool.not(any_contains(hole_part(r), s, q)))

def sp_q(+r: SP) -> V.Vec2:
  SP{q, ok} = r
  q

def sp_ok(+r: SP) -> Bool:
  SP{q, ok} = r
  ok

def eps_list() -> List<&2, F64>:
  [0.5f64, 0.25f64, 0.1f64, 0.03f64, 0.01f64, 0.001f64, 0.0001f64]

def try_eps(es: List<&2, F64>, +s: S.SF, +r: RG, +a: V.Vec2, +b: V.Vec2) -> SP:
  match es:
    case []: SP{a, False{}}
    case +h <> +t:
      +q = cand(a, b, h)
      Bool.pick(SP, rg_inside(s, r, q), SP{q, True{}}, try_eps(t, s, r, a, b))

def try_segs(ps: List<&2, V.Vec2>, +s: S.SF, +r: RG, +prev: V.Vec2) -> SP:
  match ps:
    case []: SP{prev, False{}}
    case +h <> +t:
      +x = try_eps(eps_list(), s, r, prev, h)
      Bool.pick(SP, sp_ok(x), x, try_segs(t, s, r, h))

def sample_go(+p: List<&2, V.Vec2>, +s: S.SF, +r: RG) -> SP:
  match p:
    case []: SP{V.V2{0.0f64, 0.0f64}, False{}}
    case +h <> +t: try_segs(t, s, r, h)

def sample_pt(+s: S.SF, +r: RG) -> SP:
  sample_go(cy_poly(L_cy0(rg_cys(r))), s, r)

def L_rng(+n: Nat) -> List<&2, Nat>:
  L.nat_range(n)

def pc_dv(+p: PC) -> F64:
  PC{va, vb, poly, bnd, ers, dv} = p
  dv
