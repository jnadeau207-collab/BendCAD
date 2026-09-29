import Base
import ../c00/types.bend as T
import ./exact.bend as X

type Seg is Data:
  Seg{ id: U64, ax: F64, ay: F64, bx: F64, by: F64 }

type RPt is Data:
  RPt{ x: X.Ex, y: X.Ex, w: X.Ex }

type VKey is Data:
  VK_end{ seg: U64, end: U64 }
  VK_x{ lo: U64, hi: U64 }

type Stop is Data:
  Stop{ key: VKey, p: RPt }

type Stops is Data:
  Stops{ ok: Bool, xs: List<&2, Stop> }

def s_id(s: Seg) -> U64:
  Seg{id, ax, ay, bx, by} = s
  id

def s_dx(s: Seg) -> X.Ex:
  Seg{id, ax, ay, bx, by} = s
  X.ex_dif(bx, ax)

def s_dy(s: Seg) -> X.Ex:
  Seg{id, ax, ay, bx, by} = s
  X.ex_dif(by, ay)

def rp_of(+x: F64, +y: F64) -> RPt:
  RPt{X.ex_of(x), X.ex_of(y), X.ex_of(1.0f64)}

def rp_a(s: Seg) -> RPt:
  Seg{id, ax, ay, bx, by} = s
  rp_of(ax, ay)

def rp_b(s: Seg) -> RPt:
  Seg{id, ax, ay, bx, by} = s
  rp_of(bx, by)

def rp_x(p: RPt) -> X.Ex:
  RPt{x, y, w} = p
  x

def rp_y(p: RPt) -> X.Ex:
  RPt{x, y, w} = p
  y

def rp_w(p: RPt) -> X.Ex:
  RPt{x, y, w} = p
  w

def rp_flip(p: RPt, neg: Bool) -> RPt:
  RPt{x, y, w} = p
  match neg:
    case True{}: RPt{X.ex_neg(x), X.ex_neg(y), X.ex_neg(w)}
    case False{}: RPt{x, y, w}

def rp_cross(s: Seg, r: Seg) -> RPt:
  Seg{i, +ax, +ay, +bx, +by} = s
  Seg{j, +cx, +cy, +dx, +dy} = r
  +oa = X.orient2(cx, cy, dx, dy, ax, ay)
  +w = X.ex_sub(oa, X.orient2(cx, cy, dx, dy, bx, by))
  +px = X.ex_add(X.ex_scale(w, ax), X.ex_mul(oa, X.ex_dif(bx, ax)))
  +py = X.ex_add(X.ex_scale(w, ay), X.ex_mul(oa, X.ex_dif(by, ay)))
  rp_flip(RPt{px, py, w}, X.sgn_is(X.ex_sign(w), X.Sn{}))

def rp_cmpx(+p: RPt, +q: RPt) -> X.Sgn:
  X.ex_cmp(X.ex_mul(rp_x(p), rp_w(q)), X.ex_mul(rp_x(q), rp_w(p)))

def rp_cmpy(+p: RPt, +q: RPt) -> X.Sgn:
  X.ex_cmp(X.ex_mul(rp_y(p), rp_w(q)), X.ex_mul(rp_y(q), rp_w(p)))

def lex_go(sx: X.Sgn, +p: RPt, +q: RPt) -> X.Sgn:
  match sx:
    case X.Sz{}: rp_cmpy(p, q)
    case X.Sn{}: X.Sn{}
    case X.Sp{}: X.Sp{}
    case X.Su{}: X.Su{}

def rp_lex(+p: RPt, +q: RPt) -> X.Sgn:
  lex_go(rp_cmpx(p, q), p, q)

def rp_along(+p: RPt, +q: RPt, +s: Seg) -> X.Sgn:
  +ex = X.ex_sub(X.ex_mul(rp_x(q), rp_w(p)), X.ex_mul(rp_x(p), rp_w(q)))
  +ey = X.ex_sub(X.ex_mul(rp_y(q), rp_w(p)), X.ex_mul(rp_y(p), rp_w(q)))
  X.ex_sign(X.ex_add(X.ex_mul(ex, s_dx(s)), X.ex_mul(ey, s_dy(s))))

def both_pos(a: X.Sgn, b: X.Sgn) -> X.Sgn:
  match a b:
    case X.Su{} _: X.Su{}
    case _ X.Su{}: X.Su{}
    case X.Sp{} X.Sp{}: X.Sp{}
    case _ _: X.Sn{}

def between(+s: Seg, +px: F64, +py: F64) -> X.Sgn:
  Seg{id, +ax, +ay, +bx, +by} = s
  +d1 = X.ex_add(X.ex_mul(X.ex_dif(px, ax), X.ex_dif(bx, ax)),
    X.ex_mul(X.ex_dif(py, ay), X.ex_dif(by, ay)))
  +d2 = X.ex_add(X.ex_mul(X.ex_dif(px, bx), X.ex_dif(ax, bx)),
    X.ex_mul(X.ex_dif(py, by), X.ex_dif(ay, by)))
  both_pos(X.ex_sign(d1), X.ex_sign(d2))

def vk_lt(a: VKey, b: VKey) -> Bool:
  match a b:
    case VK_end{+s1, e1} VK_end{+s2, e2}:
      Bool.or(U64.is_lt(s1, s2), Bool.and(U64.is_eq(s1, s2), U64.is_lt(e1, e2)))
    case VK_end{s1, e1} VK_x{l2, h2}: True{}
    case VK_x{l1, h1} VK_end{s2, e2}: False{}
    case VK_x{+l1, h1} VK_x{+l2, h2}:
      Bool.or(U64.is_lt(l1, l2), Bool.and(U64.is_eq(l1, l2), U64.is_lt(h1, h2)))

def stop_p(s: Stop) -> RPt:
  Stop{key, p} = s
  p

def stop_k(s: Stop) -> VKey:
  Stop{key, p} = s
  key

def stops_ok(s: Stops) -> Bool:
  Stops{ok, xs} = s
  ok

def stops_xs(s: Stops) -> List<&2, Stop>:
  Stops{ok, xs} = s
  xs

def sg_opp(a: X.Sgn, b: X.Sgn) -> Bool:
  match a b:
    case X.Sn{} X.Sp{}: True{}
    case X.Sp{} X.Sn{}: True{}
    case _ _: False{}

def sg_unc(a: X.Sgn) -> Bool:
  X.sgn_is(a, X.Su{})

def sg_zero(a: X.Sgn) -> Bool:
  X.sgn_is(a, X.Sz{})

def add_if(ins: X.Sgn, +st: Stop, +acc: Stops) -> Stops:
  match ins:
    case X.Sp{}: Stops{stops_ok(acc), st <> stops_xs(acc)}
    case X.Su{}: Stops{False{}, stops_xs(acc)}
    case _: acc

def on_add(on: X.Sgn, +s: Seg, +k: VKey, +px: F64, +py: F64,
    acc: Stops) -> Stops:
  match on:
    case X.Sz{}: add_if(between(s, px, py), Stop{k, rp_of(px, py)}, acc)
    case X.Su{}: Stops{False{}, stops_xs(acc)}
    case _: acc

def cross_add(c: Bool, +s: Seg, +r: Seg, +acc: Stops) -> Stops:
  match c:
    case True{}:
      Stops{stops_ok(acc), Stop{VK_x{U64.min(s_id(s), s_id(r)),
        U64.max(s_id(s), s_id(r))}, rp_cross(s, r)} <> stops_xs(acc)}
    case False{}: acc

def pair_stops(+s: Seg, +r: Seg, acc: Stops) -> Stops:
  Seg{i, +ax, +ay, +bx, +by} = s
  Seg{j, +cx, +cy, +dx, +dy} = r
  +o1 = X.ex_sign(X.orient2(ax, ay, bx, by, cx, cy))
  +o2 = X.ex_sign(X.orient2(ax, ay, bx, by, dx, dy))
  +o3 = X.ex_sign(X.orient2(cx, cy, dx, dy, ax, ay))
  +o4 = X.ex_sign(X.orient2(cx, cy, dx, dy, bx, by))
  +a1 = on_add(o1, s, VK_end{j, 0u64}, cx, cy, acc)
  +a2 = on_add(o2, s, VK_end{j, 1u64}, dx, dy, a1)
  +a3 = cross_add(Bool.and(sg_opp(o1, o2), sg_opp(o3, o4)), s, r, a2)
  Stops{Bool.and(stops_ok(a3), Bool.not(Bool.or(Bool.or(sg_unc(o1),
    sg_unc(o2)), Bool.or(sg_unc(o3), sg_unc(o4))))), stops_xs(a3)}

def skip_same(same: Bool, +s: Seg, +r: Seg, acc: Stops) -> Stops:
  match same:
    case True{}: acc
    case False{}: pair_stops(s, r, acc)

def seg_stops_go(rs: List<&2, Seg>, +s: Seg, acc: Stops) -> Stops:
  match rs:
    case Nil{}: acc
    case +r <> t:
      seg_stops_go(t, s, skip_same(U64.is_eq(s_id(s), s_id(r)), s, r, acc))

def stop_min(+a: Stop, +b: Stop) -> Stop:
  Bool.pick(Stop, vk_lt(stop_k(a), stop_k(b)), a, b)

def ins_pick(c: X.Sgn, +h: Stop, +st: Stop, t: List<&2, Stop>,
    +later: Stops) -> Stops:
  match c:
    case X.Sp{}: Stops{stops_ok(later), h <> stops_xs(later)}
    case X.Sn{}: Stops{True{}, st <> h <> t}
    case X.Sz{}: Stops{True{}, stop_min(st, h) <> t}
    case X.Su{}: Stops{False{}, h <> t}

def ins_go(xs: List<&2, Stop>, +st: Stop, +s: Seg) -> Stops:
  match xs:
    case Nil{}: Stops{True{}, [st]}
    case +h <> +t:
      ins_pick(rp_along(stop_p(h), stop_p(st), s), h, st, t, ins_go(t, st, s))

def isort_go(xs: List<&2, Stop>, +s: Seg, acc: Stops) -> Stops:
  match xs:
    case Nil{}: acc
    case h <> t:
      Stops{ok, ys} = acc
      +r = ins_go(ys, h, s)
      isort_go(t, s, Stops{Bool.and(ok, stops_ok(r)), stops_xs(r)})

def seg_sorted(+s: Seg, +all: List<&2, Seg>) -> Stops:
  Seg{i, +ax, +ay, +bx, +by} = s
  +raw = seg_stops_go(all, s,
    Stops{True{}, [Stop{VK_end{i, 0u64}, rp_of(ax, ay)},
      Stop{VK_end{i, 1u64}, rp_of(bx, by)}]})
  +srt = isort_go(stops_xs(raw), s, Stops{True{}, []})
  Stops{Bool.and(stops_ok(raw), stops_ok(srt)), stops_xs(srt)}

type Vtx is Data:
  Vtx{ key: VKey, p: RPt }

type Vs is Data:
  Vs{ ok: Bool, xs: List<&2, Vtx> }

def vx_p(v: Vtx) -> RPt:
  Vtx{key, p} = v
  p

def vx_k(v: Vtx) -> VKey:
  Vtx{key, p} = v
  key

def vs_ok(s: Vs) -> Bool:
  Vs{ok, xs} = s
  ok

def vs_xs(s: Vs) -> List<&2, Vtx>:
  Vs{ok, xs} = s
  xs

def vx_min(+a: Vtx, +b: Vtx) -> Vtx:
  Bool.pick(Vtx, vk_lt(vx_k(a), vx_k(b)), a, b)

def vins_pick(c: X.Sgn, +h: Vtx, +v: Vtx, t: List<&2, Vtx>, +later: Vs) -> Vs:
  match c:
    case X.Sn{}: Vs{vs_ok(later), h <> vs_xs(later)}
    case X.Sp{}: Vs{True{}, v <> h <> t}
    case X.Sz{}: Vs{True{}, vx_min(v, h) <> t}
    case X.Su{}: Vs{False{}, h <> t}

def vins_go(xs: List<&2, Vtx>, +v: Vtx) -> Vs:
  match xs:
    case Nil{}: Vs{True{}, [v]}
    case +h <> +t:
      vins_pick(rp_lex(vx_p(h), vx_p(v)), h, v, t, vins_go(t, v))

def vtab_go(xs: List<&2, Stop>, acc: Vs) -> Vs:
  match xs:
    case Nil{}: acc
    case +h <> t:
      Vs{ok, ys} = acc
      +r = vins_go(ys, Vtx{stop_k(h), stop_p(h)})
      vtab_go(t, Vs{Bool.and(ok, vs_ok(r)), vs_xs(r)})

type Ix is Data:
  Ix{ ok: Bool, i: Nat }

def ix_ok(x: Ix) -> Bool:
  Ix{ok, i} = x
  ok

def ix_i(x: Ix) -> Nat:
  Ix{ok, i} = x
  i

def find_pick(c: X.Sgn, +i: Nat, +later: Ix) -> Ix:
  match c:
    case X.Sz{}: Ix{True{}, i}
    case X.Su{}: Ix{False{}, 0n}
    case _: later

def vfind_go(xs: List<&2, Vtx>, +p: RPt, +i: Nat) -> Ix:
  match xs:
    case Nil{}: Ix{False{}, 0n}
    case h <> t:
      find_pick(rp_lex(vx_p(h), p), i, vfind_go(t, p, 1n+i))

def vfind(+vs: List<&2, Vtx>, +p: RPt) -> Ix:
  vfind_go(vs, p, 0n)

type IE is Data:
  IE{ u: Nat, v: Nat, sid: U64, fwd: Bool, srcs: List<&2, U64> }

type Es is Data:
  Es{ ok: Bool, xs: List<&2, IE> }

def ie_u(e: IE) -> Nat:
  IE{u, v, sid, fwd, srcs} = e
  u

def ie_v(e: IE) -> Nat:
  IE{u, v, sid, fwd, srcs} = e
  v

def ie_sid(e: IE) -> U64:
  IE{u, v, sid, fwd, srcs} = e
  sid

def ie_fwd(e: IE) -> Bool:
  IE{u, v, sid, fwd, srcs} = e
  fwd

def ie_srcs(e: IE) -> List<&2, U64>:
  IE{u, v, sid, fwd, srcs} = e
  srcs

def es_ok(s: Es) -> Bool:
  Es{ok, xs} = s
  ok

def es_xs(s: Es) -> List<&2, IE>:
  Es{ok, xs} = s
  xs

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

def ie_norm(+u: Nat, +v: Nat, +sid: U64) -> IE:
  Bool.pick(IE, Nat.is_lt(u, v), IE{u, v, sid, True{}, [sid]},
    IE{v, u, sid, False{}, [sid]})

def eins_go(xs: List<&2, IE>, +e: IE) -> List<&2, IE>:
  match xs:
    case Nil{}: [e]
    case +h <> +t:
      +same = Bool.and(Nat.is_eq(ie_u(h), ie_u(e)), Nat.is_eq(ie_v(h), ie_v(e)))
      Bool.pick(List<&2, IE>, same,
        IE{ie_u(h), ie_v(h), ie_sid(h), ie_fwd(h),
          ids_union(ie_srcs(e), ie_srcs(h))} <> t,
        h <> eins_go(t, e))

def chain_go(xs: List<&2, Stop>, +prev: Stop, +vs: List<&2, Vtx>, +sid: U64,
    +acc: Es) -> Es:
  match xs:
    case Nil{}: acc
    case +h <> t:
      +a = vfind(vs, stop_p(prev))
      +b = vfind(vs, stop_p(h))
      +ok = Bool.and(es_ok(acc), Bool.and(ix_ok(a), ix_ok(b)))
      chain_go(t, h, vs, sid,
        Es{ok, eins_go(es_xs(acc), ie_norm(ix_i(a), ix_i(b), sid))})

def chain(xs: List<&2, Stop>, +vs: List<&2, Vtx>, +sid: U64, acc: Es) -> Es:
  match xs:
    case Nil{}: acc
    case h <> t: chain_go(t, h, vs, sid, acc)

def nth(-A: Data, xs: List<&2, A>, i: Nat, +d: A) -> A:
  match xs:
    case Nil{}: d
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth(A, t, j, d)

def set_nth(-A: Data, xs: List<&2, A>, i: Nat, +x: A) -> List<&2, A>:
  match xs:
    case Nil{}: []
    case h <> t:
      match i:
        case 0n: x <> t
        case 1n+j: h <> set_nth(A, t, j, x)

def len(-A: Data, xs: List<&2, A>) -> Nat:
  match xs:
    case Nil{}: 0n
    case h <> t: 1n+len(A, t)

def seg_nil() -> Seg:
  Seg{0u64, 0.0f64, 0.0f64, 1.0f64, 0.0f64}

def seg_of(xs: List<&2, Seg>, +id: U64) -> Seg:
  match xs:
    case Nil{}: seg_nil()
    case +h <> t:
      Bool.pick(Seg, U64.is_eq(s_id(h), id), h, seg_of(t, id))

def ie_nil() -> IE:
  IE{0n, 0n, 0u64, True{}, []}

type HE is Data:
  HE{ e: Nat, d: Bool }

type D2 is Data:
  D2{ x: X.Ex, y: X.Ex }

type HD is Data:
  HD{ h: HE, dir: D2 }

def he_e(h: HE) -> Nat:
  HE{e, d} = h
  e

def he_d(h: HE) -> Bool:
  HE{e, d} = h
  d

def he_twin(h: HE) -> HE:
  HE{e, d} = h
  HE{e, Bool.not(d)}

def he_eq(+a: HE, +b: HE) -> Bool:
  Bool.and(Nat.is_eq(he_e(a), he_e(b)), Bool.not(Bool.xor(he_d(a), he_d(b))))

def hd_h(x: HD) -> HE:
  HD{h, dir} = x
  h

def hd_dir(x: HD) -> D2:
  HD{h, dir} = x
  dir

def d2_x(d: D2) -> X.Ex:
  D2{x, y} = d
  x

def d2_y(d: D2) -> X.Ex:
  D2{x, y} = d
  y

def d2_flip(d: D2, neg: Bool) -> D2:
  D2{x, y} = d
  match neg:
    case True{}: D2{X.ex_neg(x), X.ex_neg(y)}
    case False{}: D2{x, y}

def he_org(+es: List<&2, IE>, +h: HE) -> Nat:
  +e = nth(IE, es, he_e(h), ie_nil())
  Bool.pick(Nat, he_d(h), ie_u(e), ie_v(e))

def he_head(+es: List<&2, IE>, +h: HE) -> Nat:
  he_org(es, he_twin(h))

def he_dir(+segs: List<&2, Seg>, +es: List<&2, IE>, +h: HE) -> D2:
  +e = nth(IE, es, he_e(h), ie_nil())
  +s = seg_of(segs, ie_sid(e))
  d2_flip(D2{s_dx(s), s_dy(s)}, Bool.xor(ie_fwd(e), he_d(h)))

def up_go(sy: X.Sgn, sx: X.Sgn) -> Bool:
  match sy:
    case X.Sp{}: True{}
    case X.Sz{}: X.sgn_is(sx, X.Sp{})
    case _: False{}

def d2_up(+d: D2) -> Bool:
  up_go(X.ex_sign(d2_y(d)), X.ex_sign(d2_x(d)))

def d2_cross(+a: D2, +b: D2) -> X.Sgn:
  X.ex_sign(X.ex_sub(X.ex_mul(d2_x(a), d2_y(b)), X.ex_mul(d2_y(a), d2_x(b))))

def ccw_go(u1: Bool, u2: Bool, +a: D2, +b: D2) -> X.Sgn:
  match u1 u2:
    case True{} False{}: X.Sn{}
    case False{} True{}: X.Sp{}
    case _ _: X.sgn_neg(d2_cross(a, b))

def ccw_cmp(+a: D2, +b: D2) -> X.Sgn:
  ccw_go(d2_up(a), d2_up(b), a, b)

def d2_unc(+d: D2) -> Bool:
  Bool.or(X.sgn_is(X.ex_sign(d2_x(d)), X.Su{}), X.sgn_is(X.ex_sign(d2_y(d)), X.Su{}))

type Hs is Data:
  Hs{ ok: Bool, xs: List<&2, HD> }

def hs_ok(s: Hs) -> Bool:
  Hs{ok, xs} = s
  ok

def hs_xs(s: Hs) -> List<&2, HD>:
  Hs{ok, xs} = s
  xs

def hins_pick(c: X.Sgn, +h: HD, +v: HD, t: List<&2, HD>, +later: Hs) -> Hs:
  match c:
    case X.Sn{}: Hs{hs_ok(later), h <> hs_xs(later)}
    case X.Sp{}: Hs{True{}, v <> h <> t}
    case X.Sz{}: Hs{False{}, h <> t}
    case X.Su{}: Hs{False{}, h <> t}

def hins_go(xs: List<&2, HD>, +v: HD) -> Hs:
  match xs:
    case Nil{}: Hs{True{}, [v]}
    case +h <> +t:
      hins_pick(ccw_cmp(hd_dir(h), hd_dir(v)), h, v, t, hins_go(t, v))

def out_go(es: List<&2, IE>, +i: Nat, +k: Nat, +segs: List<&2, Seg>,
    +all: List<&2, IE>, +acc: Hs) -> Hs:
  match es:
    case Nil{}: acc
    case +e <> t:
      +h = Bool.pick(HE, Nat.is_eq(ie_u(e), i), HE{k, True{}}, HE{k, False{}})
      +touch = Bool.or(Nat.is_eq(ie_u(e), i), Nat.is_eq(ie_v(e), i))
      +dir = he_dir(segs, all, h)
      +r = hins_go(hs_xs(acc), HD{h, dir})
      +acc2 = Bool.pick(Hs, touch,
        Hs{Bool.and(hs_ok(acc), Bool.and(hs_ok(r), Bool.not(d2_unc(dir)))),
          hs_xs(r)}, acc)
      out_go(t, i, 1n+k, segs, all, acc2)

def ccw_at(+i: Nat, +segs: List<&2, Seg>, +es: List<&2, IE>) -> Hs:
  out_go(es, i, 0n, segs, es, Hs{True{}, []})

type Tab is Data:
  Tab{ ok: Bool, rows: List<&2, List<&2, HD>> }

def tab_go(n: Nat, +i: Nat, +segs: List<&2, Seg>, +es: List<&2, IE>,
    +acc: Tab) -> Tab:
  match n:
    case 0n: acc
    case 1n+m:
      Tab{ok, rows} = acc
      +r = ccw_at(i, segs, es)
      tab_go(m, 1n+i, segs, es, Tab{Bool.and(ok, hs_ok(r)),
        List.append(&2, List<&2, HD>, rows, [hs_xs(r)])})

def tab_ok(t: Tab) -> Bool:
  Tab{ok, rows} = t
  ok

def tab_rows(t: Tab) -> List<&2, List<&2, HD>>:
  Tab{ok, rows} = t
  rows

def hd_nil() -> HD:
  HD{HE{0n, True{}}, D2{X.ex_zero(), X.ex_zero()}}

def hid(+h: HE) -> Nat:
  Nat.add(Nat.mul(2n, he_e(h)), Bool.pick(Nat, he_d(h), 0n, 1n))

def he_of(+i: Nat) -> HE:
  HE{Nat.div(i, 2n), Nat.is_eq(Nat.mod(i, 2n), 0n)}

def pos_go(xs: List<&2, HD>, +h: HE, +i: Nat) -> Nat:
  match xs:
    case Nil{}: 0n
    case x <> t:
      Bool.pick(Nat, he_eq(hd_h(x), h), i, pos_go(t, h, 1n+i))

def prev_in(+xs: List<&2, HD>, +i: Nat) -> HE:
  match i:
    case 0n: hd_h(nth(HD, xs, Nat.sub(len(HD, xs), 1n), hd_nil()))
    case 1n+j: hd_h(nth(HD, xs, j, hd_nil()))

def row_of(+rows: List<&2, List<&2, HD>>, +w: Nat) -> List<&2, HD>:
  nth(List<&2, HD>, rows, w, [])

def he_next(+rows: List<&2, List<&2, HD>>, +es: List<&2, IE>, +h: HE) -> HE:
  +row = row_of(rows, he_head(es, h))
  prev_in(row, pos_go(row, he_twin(h), 0n))

def unset() -> Nat:
  1000000n

type Cy is Data:
  Cy{ ok: Bool, xs: List<&2, Nat>, n: Nat }

def cy_ok(c: Cy) -> Bool:
  Cy{ok, xs, n} = c
  ok

def cy_xs(c: Cy) -> List<&2, Nat>:
  Cy{ok, xs, n} = c
  xs

def cy_n(c: Cy) -> Nat:
  Cy{ok, xs, n} = c
  n

def trace_go(fuel: Nat, stop: Bool, +h0: HE, +h: HE, +c: Nat,
    +rows: List<&2, List<&2, HD>>, +es: List<&2, IE>,
    cyc: List<&2, Nat>) -> Cy:
  match fuel:
    case 0n: Cy{False{}, cyc, 0n}
    case 1n+f:
      match stop:
        case True{}: Cy{True{}, cyc, 0n}
        case False{}:
          +nx = he_next(rows, es, h)
          trace_go(f, he_eq(nx, h0), h0, nx, c, rows, es,
            set_nth(Nat, cyc, hid(h), c))

def cyc_pick(un: Bool, +h: HE, +c: Nat, +fuel: Nat,
    +rows: List<&2, List<&2, HD>>, +es: List<&2, IE>, +acc: Cy) -> Cy:
  match un:
    case True{}:
      +r = trace_go(fuel, False{}, h, h, c, rows, es, cy_xs(acc))
      Cy{Bool.and(cy_ok(acc), cy_ok(r)), cy_xs(r), cy_n(acc)}
    case False{}: acc

def cyc_all(n: Nat, +i: Nat, +c: Nat, +fuel: Nat,
    +rows: List<&2, List<&2, HD>>, +es: List<&2, IE>, +acc: Cy) -> Cy:
  match n:
    case 0n: Cy{cy_ok(acc), cy_xs(acc), c}
    case 1n+m:
      +un = Nat.is_eq(nth(Nat, cy_xs(acc), i, 0n), unset())
      cyc_all(m, 1n+i, Bool.pick(Nat, un, 1n+c, c), fuel, rows, es,
        cyc_pick(un, he_of(i), c, fuel, rows, es, acc))

def rep(n: Nat, +x: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: x <> rep(m, x)

def iota(n: Nat, +i: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: i <> iota(m, 1n+i)

def cycles(+rows: List<&2, List<&2, HD>>, +es: List<&2, IE>) -> Cy:
  +nh = Nat.mul(2n, len(IE, es))
  cyc_all(nh, 0n, 0n, 1n+nh, rows, es, Cy{True{}, rep(nh, unset()), 0n})

def relax_go(es: List<&2, IE>, +lab: List<&2, Nat>) -> List<&2, Nat>:
  match es:
    case Nil{}: lab
    case +e <> t:
      +m = Nat.min(nth(Nat, lab, ie_u(e), 0n), nth(Nat, lab, ie_v(e), 0n))
      relax_go(t, set_nth(Nat, set_nth(Nat, lab, ie_u(e), m), ie_v(e), m))

def relax(n: Nat, +es: List<&2, IE>, lab: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n: lab
    case 1n+m: relax(m, es, relax_go(es, lab))

def labels(+nv: Nat, +es: List<&2, IE>) -> List<&2, Nat>:
  relax(nv, es, iota(nv, 0n))

def last_up(xs: List<&2, HD>, +best: HE, +last: HE, found: Bool) -> HE:
  match xs:
    case Nil{}: Bool.pick(HE, found, best, last)
    case +x <> t:
      +up = d2_up(hd_dir(x))
      last_up(t, Bool.pick(HE, up, hd_h(x), best), hd_h(x), Bool.or(found, up))

type Comp is Data:
  Comp{ root: Nat, outer: Nat }

def comp_root(c: Comp) -> Nat:
  Comp{root, outer} = c
  root

def comp_outer(c: Comp) -> Nat:
  Comp{root, outer} = c
  outer

def comps_go(n: Nat, +i: Nat, +lab: List<&2, Nat>,
    +rows: List<&2, List<&2, HD>>, +cyc: List<&2, Nat>) -> List<&2, Comp>:
  match n:
    case 0n: []
    case 1n+m:
      +rest = comps_go(m, 1n+i, lab, rows, cyc)
      +h = last_up(row_of(rows, i), hd_h(hd_nil()), hd_h(hd_nil()), False{})
      Bool.pick(List<&2, Comp>, Nat.is_eq(nth(Nat, lab, i, 0n), i),
        Comp{i, nth(Nat, cyc, hid(h), 0n)} <> rest, rest)

type Fid is Data:
  F_in{ c: Nat }
  F_inf{}

def fid_eq(a: Fid, b: Fid) -> Bool:
  match a b:
    case F_in{x} F_in{y}: Nat.is_eq(x, y)
    case F_inf{} F_inf{}: True{}
    case _ _: False{}

def in_list(xs: List<&2, Nat>, +x: Nat) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t: Bool.or(Nat.is_eq(h, x), in_list(t, x))

def vpt(+vs: List<&2, Vtx>, +i: Nat) -> RPt:
  vx_p(nth(Vtx, vs, i, Vtx{VK_end{0u64, 0u64}, rp_of(0.0f64, 0.0f64)}))

type Cand is Data:
  Cand{ ok: Bool, has: Bool, e: Nat }

def cand_ok(c: Cand) -> Bool:
  Cand{ok, has, e} = c
  ok

def cand_has(c: Cand) -> Bool:
  Cand{ok, has, e} = c
  has

def cand_e(c: Cand) -> Nat:
  Cand{ok, has, e} = c
  e

def s_axy(s: Seg) -> D2:
  Seg{id, ax, ay, bx, by} = s
  D2{X.ex_of(ax), X.ex_of(ay)}

def line_pt(+segs: List<&2, Seg>, +es: List<&2, IE>, +e: Nat) -> D2:
  s_axy(seg_of(segs, ie_sid(nth(IE, es, e, ie_nil()))))

def below_sign(+d: D2, +a: D2, +q: RPt) -> X.Sgn:
  +w = rp_w(q)
  +t1 = X.ex_sub(rp_y(q), X.ex_mul(d2_y(a), w))
  +t2 = X.ex_sub(rp_x(q), X.ex_mul(d2_x(a), w))
  X.ex_sign(X.ex_sub(X.ex_mul(d2_x(d), t1), X.ex_mul(d2_y(d), t2)))

def height_n(+d: D2, +a: D2, +xo: X.Ex, +q: RPt) -> X.Ex:
  +w = rp_w(q)
  X.ex_add(X.ex_mul(X.ex_mul(d2_y(a), X.ex_mul(d2_x(d), xo)), w),
    X.ex_mul(X.ex_mul(X.ex_sub(rp_x(q), X.ex_mul(d2_x(a), w)), d2_y(d)), xo))

def tie_go(s: X.Sgn, +d1: D2, +d2: D2) -> X.Sgn:
  match s:
    case X.Sz{}:
      X.ex_sign(X.ex_sub(X.ex_mul(d2_y(d1), d2_x(d2)), X.ex_mul(d2_y(d2), d2_x(d1))))
    case _: s

def lower(+segs: List<&2, Seg>, +es: List<&2, IE>, +e1: Nat, +e2: Nat,
    +q: RPt) -> X.Sgn:
  +d1 = he_dir(segs, es, HE{e1, True{}})
  +d2 = he_dir(segs, es, HE{e2, True{}})
  +n1 = height_n(d1, line_pt(segs, es, e1), d2_x(d2), q)
  +n2 = height_n(d2, line_pt(segs, es, e2), d2_x(d1), q)
  tie_go(X.ex_cmp(n1, n2), d1, d2)

def cand_go(+ok: Bool, +sp: X.Sgn, +spv: X.Sgn, +vert: X.Sgn, +bel: X.Sgn) -> Cand:
  +unc = Bool.or(Bool.or(X.sgn_is(sp, X.Su{}), X.sgn_is(spv, X.Su{})),
    Bool.or(X.sgn_is(vert, X.Su{}), X.sgn_is(bel, X.Su{})))
  +span = Bool.and(Bool.not(X.sgn_is(sp, X.Sp{})), X.sgn_is(spv, X.Sn{}))
  +good = Bool.and(Bool.and(ok, span),
    Bool.and(Bool.not(X.sgn_is(vert, X.Sz{})), X.sgn_is(bel, X.Sn{})))
  Cand{Bool.not(unc), good, 0n}

def is_cand(+segs: List<&2, Seg>, +es: List<&2, IE>, +vs: List<&2, Vtx>,
    +lab: List<&2, Nat>, +ex: List<&2, Nat>, +e: Nat, +q: RPt) -> Cand:
  +ie = nth(IE, es, e, ie_nil())
  +d = he_dir(segs, es, HE{e, True{}})
  cand_go(Bool.not(in_list(ex, nth(Nat, lab, ie_u(ie), 0n))),
    rp_cmpx(vpt(vs, ie_u(ie)), q), rp_cmpx(q, vpt(vs, ie_v(ie))),
    X.ex_sign(d2_x(d)), below_sign(d, line_pt(segs, es, e), q))

def best_pick(c: X.Sgn, +e: Nat, +b: Cand) -> Cand:
  match c:
    case X.Sn{}: Cand{cand_ok(b), True{}, e}
    case X.Su{}: Cand{False{}, cand_has(b), cand_e(b)}
    case _: b

def best_in(bhas: Bool, +bok: Bool, +be: Nat, +ok: Bool, +e: Nat,
    +segs: List<&2, Seg>, +es: List<&2, IE>, +q: RPt) -> Cand:
  match bhas:
    case False{}: Cand{Bool.and(ok, bok), True{}, e}
    case True{}:
      best_pick(lower(segs, es, e, be, q), e, Cand{Bool.and(ok, bok), True{}, be})

def best_go(ce: Cand, +e: Nat, +segs: List<&2, Seg>, +es: List<&2, IE>,
    +q: RPt, +b: Cand) -> Cand:
  Cand{ok, has, x} = ce
  match has:
    case False{}: Cand{Bool.and(ok, cand_ok(b)), cand_has(b), cand_e(b)}
    case True{}: best_in(cand_has(b), cand_ok(b), cand_e(b), ok, e, segs, es, q)

def lowest(n: Nat, +e: Nat, +segs: List<&2, Seg>, +es: List<&2, IE>,
    +vs: List<&2, Vtx>, +lab: List<&2, Nat>, +ex: List<&2, Nat>, +q: RPt,
    +b: Cand) -> Cand:
  match n:
    case 0n: b
    case 1n+m:
      lowest(m, 1n+e, segs, es, vs, lab, ex, q,
        best_go(is_cand(segs, es, vs, lab, ex, e, q), e, segs, es, q, b))

def comp_of_outer(cs: List<&2, Comp>, +c: Nat) -> Ix:
  match cs:
    case Nil{}: Ix{False{}, 0n}
    case +x <> t:
      Bool.pick(Ix, Nat.is_eq(comp_outer(x), c), Ix{True{}, comp_root(x)},
        comp_of_outer(t, c))

type Step is Data:
  St_done{ f: Fid, ok: Bool }
  St_more{ d: Nat, ok: Bool }

def step_of(+b: Cand, +cyc: List<&2, Nat>, +cs: List<&2, Comp>) -> Step:
  +c = nth(Nat, cyc, hid(HE{cand_e(b), False{}}), 0n)
  +d = comp_of_outer(cs, c)
  Bool.pick(Step, cand_has(b),
    Bool.pick(Step, ix_ok(d), St_more{ix_i(d), cand_ok(b)},
      St_done{F_in{c}, cand_ok(b)}),
    St_done{F_inf{}, cand_ok(b)})

def loc_step(+segs: List<&2, Seg>, +es: List<&2, IE>, +vs: List<&2, Vtx>,
    +lab: List<&2, Nat>, +ex: List<&2, Nat>, +q: RPt, +cyc: List<&2, Nat>,
    +cs: List<&2, Comp>) -> Step:
  step_of(lowest(len(IE, es), 0n, segs, es, vs, lab, ex, q,
    Cand{True{}, False{}, 0n}), cyc, cs)

type Loc is Data:
  Loc{ ok: Bool, f: Fid }

def loc_ok(l: Loc) -> Bool:
  Loc{ok, f} = l
  ok

def loc_f(l: Loc) -> Fid:
  Loc{ok, f} = l
  f

def loc_go(fuel: Nat, st: Step, +segs: List<&2, Seg>, +es: List<&2, IE>,
    +vs: List<&2, Vtx>, +lab: List<&2, Nat>, +ex: List<&2, Nat>, +q: RPt,
    +cyc: List<&2, Nat>, +cs: List<&2, Comp>, +ok: Bool) -> Loc:
  match fuel:
    case 0n: Loc{False{}, F_inf{}}
    case 1n+f:
      match st:
        case St_done{fd, o}: Loc{Bool.and(ok, o), fd}
        case St_more{d, o}:
          +ex2 = {d <> ex : List<&2, Nat>}
          loc_go(f, loc_step(segs, es, vs, lab, ex2, q, cyc, cs), segs, es, vs,
            lab, ex2, q, cyc, cs, Bool.and(ok, o))

def locate(+segs: List<&2, Seg>, +es: List<&2, IE>, +vs: List<&2, Vtx>,
    +lab: List<&2, Nat>, +cyc: List<&2, Nat>, +cs: List<&2, Comp>,
    +root: Nat) -> Loc:
  +q = vpt(vs, root)
  loc_go(1n+len(Comp, cs), loc_step(segs, es, vs, lab, [root], q, cyc, cs),
    segs, es, vs, lab, [root], q, cyc, cs, True{})

def in_s(+f: Nat, +hs: List<&2, Nat>, +c: Nat) -> Bool:
  Bool.or(Nat.is_eq(f, c), in_list(hs, c))

def in_k(+f: Nat, +hs: List<&2, Nat>, +cyc: List<&2, Nat>, +h: HE) -> Bool:
  Bool.and(in_s(f, hs, nth(Nat, cyc, hid(h), 0n)),
    Bool.not(in_s(f, hs, nth(Nat, cyc, hid(he_twin(h)), 0n))))

def rot_go(fuel: Nat, hit: Bool, +cur: HE, +row: List<&2, HD>, +f: Nat,
    +hs: List<&2, Nat>, +cyc: List<&2, Nat>) -> HE:
  match fuel:
    case 0n: cur
    case 1n+g:
      match hit:
        case True{}: cur
        case False{}:
          +nx = prev_in(row, pos_go(row, cur, 0n))
          rot_go(g, in_k(f, hs, cyc, nx), nx, row, f, hs, cyc)

def next_k(+rows: List<&2, List<&2, HD>>, +es: List<&2, IE>, +f: Nat,
    +hs: List<&2, Nat>, +cyc: List<&2, Nat>, +h: HE) -> HE:
  +row = row_of(rows, he_head(es, h))
  rot_go(1n+len(HD, row), False{}, he_twin(h), row, f, hs, cyc)

type Lp is Data:
  Lp{ ok: Bool, hs: List<&2, HE>, seen: List<&2, Nat> }

def lp_ok(l: Lp) -> Bool:
  Lp{ok, hs, seen} = l
  ok

def lp_hs(l: Lp) -> List<&2, HE>:
  Lp{ok, hs, seen} = l
  hs

def lp_seen(l: Lp) -> List<&2, Nat>:
  Lp{ok, hs, seen} = l
  seen

def tloop_go(fuel: Nat, stop: Bool, +h0: HE, +h: HE,
    +rows: List<&2, List<&2, HD>>, +es: List<&2, IE>, +f: Nat,
    +hs: List<&2, Nat>, +cyc: List<&2, Nat>, +acc: Lp) -> Lp:
  match fuel:
    case 0n: Lp{False{}, lp_hs(acc), lp_seen(acc)}
    case 1n+g:
      match stop:
        case True{}: acc
        case False{}:
          Lp{ok, xs, seen} = acc
          +nx = next_k(rows, es, f, hs, cyc, h)
          tloop_go(g, he_eq(nx, h0), h0, nx, rows, es, f, hs, cyc,
            Lp{ok, List.append(&2, HE, xs, [h]), hid(h) <> seen})

type Ls is Data:
  Ls{ ok: Bool, loops: List<&2, List<&2, HE>>, seen: List<&2, Nat> }

def ls_ok(l: Ls) -> Bool:
  Ls{ok, loops, seen} = l
  ok

def ls_loops(l: Ls) -> List<&2, List<&2, HE>>:
  Ls{ok, loops, seen} = l
  loops

def ls_seen(l: Ls) -> List<&2, Nat>:
  Ls{ok, loops, seen} = l
  seen

def loop_pick(start: Bool, +h: HE, +fuel: Nat, +rows: List<&2, List<&2, HD>>,
    +es: List<&2, IE>, +f: Nat, +hs: List<&2, Nat>, +cyc: List<&2, Nat>,
    +acc: Ls) -> Ls:
  match start:
    case False{}: acc
    case True{}:
      +r = tloop_go(fuel, False{}, h, h, rows, es, f, hs, cyc,
        Lp{True{}, [], ls_seen(acc)})
      Ls{Bool.and(ls_ok(acc), lp_ok(r)),
        List.append(&2, List<&2, HE>, ls_loops(acc), [lp_hs(r)]), lp_seen(r)}

def loops_go(n: Nat, +i: Nat, +fuel: Nat, +rows: List<&2, List<&2, HD>>,
    +es: List<&2, IE>, +f: Nat, +hs: List<&2, Nat>, +cyc: List<&2, Nat>,
    +acc: Ls) -> Ls:
  match n:
    case 0n: acc
    case 1n+m:
      +h = he_of(i)
      +start = Bool.and(in_k(f, hs, cyc, h), Bool.not(in_list(ls_seen(acc), i)))
      loops_go(m, 1n+i, fuel, rows, es, f, hs, cyc,
        loop_pick(start, h, fuel, rows, es, f, hs, cyc, acc))

def org_min_go(xs: List<&2, HE>, +es: List<&2, IE>, +i: Nat, +bi: Nat,
    +bv: Nat) -> Nat:
  match xs:
    case Nil{}: bi
    case +h <> t:
      +o = he_org(es, h)
      +lt = Nat.is_lt(o, bv)
      org_min_go(t, es, 1n+i, Bool.pick(Nat, lt, i, bi), Bool.pick(Nat, lt, o, bv))

def org_min(+xs: List<&2, HE>, +es: List<&2, IE>) -> Nat:
  org_min_go(xs, es, 0n, 0n, unset())

def he_nil() -> HE:
  HE{0n, True{}}

def loop_turn(+xs: List<&2, HE>, +segs: List<&2, Seg>, +es: List<&2, IE>) -> X.Sgn:
  +m = org_min(xs, es)
  +n = len(HE, xs)
  +hin = nth(HE, xs, Bool.pick(Nat, Nat.is_eq(m, 0n), Nat.sub(n, 1n),
    Nat.sub(m, 1n)), he_nil())
  d2_cross(he_dir(segs, es, hin), he_dir(segs, es, nth(HE, xs, m, he_nil())))

def drop_n(-A: Data, n: Nat, xs: List<&2, A>) -> List<&2, A>:
  match n:
    case 0n: xs
    case 1n+m:
      match xs:
        case Nil{}: []
        case h <> t: drop_n(A, m, t)

def take_n(-A: Data, n: Nat, xs: List<&2, A>) -> List<&2, A>:
  match n:
    case 0n: []
    case 1n+m:
      match xs:
        case Nil{}: []
        case h <> t: h <> take_n(A, m, t)

def rot_min(+xs: List<&2, HE>, +es: List<&2, IE>) -> List<&2, HE>:
  +m = org_min(xs, es)
  List.append(&2, HE, drop_n(HE, m, xs), take_n(HE, m, xs))

type OHE is Data:
  OHE{ from: VKey, to: VKey, srcs: List<&2, U64> }

type Region is Data:
  Region{ outer: List<&2, OHE>, holes: List<&2, List<&2, OHE>> }

def vtx_nil() -> Vtx:
  Vtx{VK_end{0u64, 0u64}, rp_of(0.0f64, 0.0f64)}

def ohe_of(+vs: List<&2, Vtx>, +es: List<&2, IE>, +h: HE) -> OHE:
  +vn = vtx_nil()
  OHE{vx_k(nth(Vtx, vs, he_org(es, h), vn)), vx_k(nth(Vtx, vs, he_head(es, h), vn)),
    ie_srcs(nth(IE, es, he_e(h), ie_nil()))}

def ohes(xs: List<&2, HE>, +vs: List<&2, Vtx>, +es: List<&2, IE>) -> List<&2, OHE>:
  match xs:
    case Nil{}: []
    case h <> t: ohe_of(vs, es, h) <> ohes(t, vs, es)

def orgs(xs: List<&2, HE>, +es: List<&2, IE>) -> List<&2, Nat>:
  match xs:
    case Nil{}: []
    case h <> t: he_org(es, h) <> orgs(t, es)

def nl_lt(a: List<&2, Nat>, b: List<&2, Nat>) -> Bool:
  match a b:
    case Nil{} Nil{}: False{}
    case Nil{} _: True{}
    case _ Nil{}: False{}
    case Con{+x, xt} Con{+y, yt}:
      Bool.or(Nat.is_lt(x, y), Bool.and(Nat.is_eq(x, y), nl_lt(xt, yt)))

def lins_go(xs: List<&2, List<&2, HE>>, +l: List<&2, HE>, +es: List<&2, IE>)
    -> List<&2, List<&2, HE>>:
  match xs:
    case Nil{}: [l]
    case +h <> +t:
      Bool.pick(List<&2, List<&2, HE>>, nl_lt(orgs(l, es), orgs(h, es)),
        l <> h <> t, h <> lins_go(t, l, es))

def lsort(xs: List<&2, List<&2, HE>>, +es: List<&2, IE>,
    acc: List<&2, List<&2, HE>>) -> List<&2, List<&2, HE>>:
  match xs:
    case Nil{}: acc
    case h <> t: lsort(t, es, lins_go(acc, h, es))

type RL is Data:
  RL{ ok: Bool, outer: List<&2, List<&2, HE>>, holes: List<&2, List<&2, HE>> }

def rl_ok(r: RL) -> Bool:
  RL{ok, outer, holes} = r
  ok

def rl_outer(r: RL) -> List<&2, List<&2, HE>>:
  RL{ok, outer, holes} = r
  outer

def rl_holes(r: RL) -> List<&2, List<&2, HE>>:
  RL{ok, outer, holes} = r
  holes

def split_pick(t: X.Sgn, +l: List<&2, HE>, +acc: RL) -> RL:
  match t:
    case X.Sp{}: RL{rl_ok(acc), l <> rl_outer(acc), rl_holes(acc)}
    case X.Sn{}: RL{rl_ok(acc), rl_outer(acc), l <> rl_holes(acc)}
    case _: RL{False{}, rl_outer(acc), rl_holes(acc)}

def split_go(xs: List<&2, List<&2, HE>>, +segs: List<&2, Seg>,
    +es: List<&2, IE>, +acc: RL) -> RL:
  match xs:
    case Nil{}: acc
    case +l <> t:
      split_go(t, segs, es, split_pick(loop_turn(l, segs, es), rot_min(l, es), acc))

type Face is Data:
  Face{ c: Nat, loc: Fid }

def face_of(fs: List<&2, Face>, +c: Nat) -> Fid:
  match fs:
    case Nil{}: F_in{c}
    case +x <> t:
      Face{fc, fl} = x
      Bool.pick(Fid, Nat.is_eq(fc, c), fl, face_of(t, c))

def locs_go(cs: List<&2, Comp>, +segs: List<&2, Seg>, +es: List<&2, IE>,
    +vs: List<&2, Vtx>, +lab: List<&2, Nat>, +cyc: List<&2, Nat>,
    +all: List<&2, Comp>, +ok: Bool, acc: List<&2, Face>) -> Loc_all:
  match cs:
    case Nil{}: Loc_all{ok, acc}
    case +c <> t:
      +l = locate(segs, es, vs, lab, cyc, all, comp_root(c))
      locs_go(t, segs, es, vs, lab, cyc, all, Bool.and(ok, loc_ok(l)),
        Face{comp_outer(c), loc_f(l)} <> acc)

type Loc_all is Data:
  Loc_all{ ok: Bool, fs: List<&2, Face> }

def holes_of(fs: List<&2, Face>, +f: Nat) -> List<&2, Nat>:
  match fs:
    case Nil{}: []
    case +x <> +t:
      Face{fc, fl} = x
      Bool.pick(List<&2, Nat>, fid_eq(fl, F_in{f}), fc <> holes_of(t, f),
        holes_of(t, f))

type RR is Data:
  RR{ ok: Bool, key: List<&2, Nat>, reg: Region }

def rr_key(r: RR) -> List<&2, Nat>:
  RR{ok, key, reg} = r
  key

def holes_ohe(xs: List<&2, List<&2, HE>>, +vs: List<&2, Vtx>, +es: List<&2, IE>)
    -> List<&2, List<&2, OHE>>:
  match xs:
    case Nil{}: []
    case h <> t: ohes(h, vs, es) <> holes_ohe(t, vs, es)

def region_at(+f: Nat, +fs: List<&2, Face>, +rows: List<&2, List<&2, HD>>,
    +segs: List<&2, Seg>, +es: List<&2, IE>, +vs: List<&2, Vtx>,
    +cyc: List<&2, Nat>) -> RR:
  +hs = holes_of(fs, f)
  +nh = Nat.mul(2n, len(IE, es))
  +ls = loops_go(nh, 0n, 1n+nh, rows, es, f, hs, cyc, Ls{True{}, [], []})
  +rl = split_go(ls_loops(ls), segs, es, RL{True{}, [], []})
  +outer = nth(List<&2, HE>, rl_outer(rl), 0n, [])
  +holes = lsort(rl_holes(rl), es, [])
  +good = Bool.and(Bool.and(ls_ok(ls), rl_ok(rl)),
    Nat.is_eq(len(List<&2, HE>, rl_outer(rl)), 1n))
  RR{good, orgs(outer, es), Region{ohes(outer, vs, es), holes_ohe(holes, vs, es)}}


def rr_ok(r: RR) -> Bool:
  RR{ok, key, reg} = r
  ok

def rr_reg(r: RR) -> Region:
  RR{ok, key, reg} = r
  reg

def rins_go(xs: List<&2, RR>, +r: RR) -> List<&2, RR>:
  match xs:
    case Nil{}: [r]
    case +h <> +t:
      Bool.pick(List<&2, RR>, nl_lt(rr_key(r), rr_key(h)), r <> h <> t,
        h <> rins_go(t, r))

type Rs is Data:
  Rs{ ok: Bool, xs: List<&2, RR> }

def rs_ok(r: Rs) -> Bool:
  Rs{ok, xs} = r
  ok

def rs_xs(r: Rs) -> List<&2, RR>:
  Rs{ok, xs} = r
  xs

def reg_pick(bounded: Bool, +c: Nat, +fs: List<&2, Face>,
    +rows: List<&2, List<&2, HD>>, +segs: List<&2, Seg>, +es: List<&2, IE>,
    +vs: List<&2, Vtx>, +cyc: List<&2, Nat>, +acc: Rs) -> Rs:
  match bounded:
    case False{}: acc
    case True{}:
      +r = region_at(c, fs, rows, segs, es, vs, cyc)
      Rs{Bool.and(rs_ok(acc), rr_ok(r)), rins_go(rs_xs(acc), r)}

def regs_go(n: Nat, +c: Nat, +outs: List<&2, Nat>, +fs: List<&2, Face>,
    +rows: List<&2, List<&2, HD>>, +segs: List<&2, Seg>, +es: List<&2, IE>,
    +vs: List<&2, Vtx>, +cyc: List<&2, Nat>, +acc: Rs) -> Rs:
  match n:
    case 0n: acc
    case 1n+m:
      regs_go(m, 1n+c, outs, fs, rows, segs, es, vs, cyc,
        reg_pick(Bool.not(in_list(outs, c)), c, fs, rows, segs, es, vs, cyc, acc))

def rs_regs(xs: List<&2, RR>) -> List<&2, Region>:
  match xs:
    case Nil{}: []
    case h <> t: rr_reg(h) <> rs_regs(t)

def outs_of(cs: List<&2, Comp>) -> List<&2, Nat>:
  match cs:
    case Nil{}: []
    case h <> t: comp_outer(h) <> outs_of(t)

def he_fwd(e: Nat) -> HE:
  HE{e, True{}}

def dang_go(n: Nat, +e: Nat, +fs: List<&2, Face>, +cyc: List<&2, Nat>,
    +vs: List<&2, Vtx>, +es: List<&2, IE>) -> List<&2, OHE>:
  match n:
    case 0n: []
    case 1n+m:
      +rest = dang_go(m, 1n+e, fs, cyc, vs, es)
      +h = he_fwd(e)
      +same = fid_eq(face_of(fs, nth(Nat, cyc, hid(h), 0n)),
        face_of(fs, nth(Nat, cyc, hid(he_twin(h)), 0n)))
      Bool.pick(List<&2, OHE>, same, ohe_of(vs, es, h) <> rest, rest)

type ARes is Data:
  A_ok{ nv: Nat, ne: Nat, nc: Nat, regions: List<&2, Region>,
    dangling: List<&2, OHE> }
  A_err{ kind: T.FailKind }

def seg_ok(s: Seg) -> Bool:
  Seg{id, +ax, +ay, +bx, +by} = s
  Bool.and(Bool.and(Bool.and(X.fin(ax), X.fin(ay)), Bool.and(X.fin(bx), X.fin(by))),
    Bool.not(Bool.and(F64.is_eq(ax, bx), F64.is_eq(ay, by))))

def id_free(xs: List<&2, Seg>, +id: U64) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(Bool.not(U64.is_eq(s_id(h), id)), id_free(t, id))

def segs_ok(xs: List<&2, Seg>) -> Bool:
  match xs:
    case Nil{}: True{}
    case +h <> +t: Bool.and(Bool.and(seg_ok(h), id_free(t, s_id(h))), segs_ok(t))

type Sl is Data:
  Sl{ sid: U64, xs: List<&2, Stop> }

type Ss is Data:
  Ss{ ok: Bool, xs: List<&2, Sl> }

def ss_ok(s: Ss) -> Bool:
  Ss{ok, xs} = s
  ok

def ss_xs(s: Ss) -> List<&2, Sl>:
  Ss{ok, xs} = s
  xs

def all_stops(xs: List<&2, Seg>, +all: List<&2, Seg>) -> Ss:
  match xs:
    case Nil{}: Ss{True{}, []}
    case +h <> t:
      +r = seg_sorted(h, all)
      +rest = all_stops(t, all)
      Ss{Bool.and(stops_ok(r), ss_ok(rest)), Sl{s_id(h), stops_xs(r)} <> ss_xs(rest)}

def flat_stops(xs: List<&2, Sl>) -> List<&2, Stop>:
  match xs:
    case Nil{}: []
    case h <> t:
      Sl{sid, ys} = h
      List.append(&2, Stop, ys, flat_stops(t))

def chains(xs: List<&2, Sl>, +vs: List<&2, Vtx>, acc: Es) -> Es:
  match xs:
    case Nil{}: acc
    case h <> t:
      Sl{sid, ys} = h
      chains(t, vs, chain(ys, vs, sid, acc))

def la_ok(l: Loc_all) -> Bool:
  Loc_all{ok, fs} = l
  ok

def la_fs(l: Loc_all) -> List<&2, Face>:
  Loc_all{ok, fs} = l
  fs

def arr_build(+segs: List<&2, Seg>) -> ARes:
  +ss = all_stops(segs, segs)
  +vt = vtab_go(flat_stops(ss_xs(ss)), Vs{True{}, []})
  +vs = vs_xs(vt)
  +et = chains(ss_xs(ss), vs, Es{True{}, []})
  +es = es_xs(et)
  +nv = len(Vtx, vs)
  +tab = tab_go(nv, 0n, segs, es, Tab{True{}, []})
  +rows = tab_rows(tab)
  +cy = cycles(rows, es)
  +cyc = cy_xs(cy)
  +lab = labels(nv, es)
  +cs = comps_go(nv, 0n, lab, rows, cyc)
  +la = locs_go(cs, segs, es, vs, lab, cyc, cs, True{}, [])
  +fs = la_fs(la)
  +rs = regs_go(cy_n(cy), 0n, outs_of(cs), fs, rows, segs, es, vs, cyc, Rs{True{}, []})
  +ok = Bool.and(Bool.and(Bool.and(ss_ok(ss), vs_ok(vt)), Bool.and(es_ok(et), tab_ok(tab))),
    Bool.and(Bool.and(cy_ok(cy), la_ok(la)), rs_ok(rs)))
  Bool.pick(ARes, ok,
    A_ok{nv, len(IE, es), len(Comp, cs), rs_regs(rs_xs(rs)),
      dang_go(len(IE, es), 0n, fs, cyc, vs, es)},
    A_err{T.F_uncertain{}})

def arrange_fuel(within: Bool, +segs: List<&2, Seg>) -> ARes:
  match within:
    case True{}: arr_build(segs)
    case False{}: A_err{T.F_exhausted{}}

def arrange_go(valid: Bool, +segs: List<&2, Seg>, +fuel: Nat) -> ARes:
  match valid:
    case True{}: arrange_fuel(Nat.is_le(len(Seg, segs), fuel), segs)
    case False{}: A_err{T.F_invalid{}}

def arrange(+segs: List<&2, Seg>, +fuel: Nat) -> ARes:
  arrange_go(segs_ok(segs), segs, fuel)

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
