import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ./sf.bend as S
import ./ef.bend as EF
import ./ls.bend as L

type IC is Data:
  IC{ kind: U64, curve: G.GVal, closed: Bool, pts: List<&2, V.Point>, why: U64 }

type DS is Data:
  DS{ ivs: List<&2, V.Vec2>, allpos: Bool, near: Bool, ost: F64, open: Bool }

type PL is Data:
  PL{ pts: List<&2, V.Point>, ok: Bool }

type ICS is Data:
  ICS{ ics: List<&2, IC>, why: U64 }

def ic_none() -> U64:
  0u64

def ic_line() -> U64:
  1u64

def ic_circle() -> U64:
  2u64

def ic_poly() -> U64:
  3u64

def ic_coinc() -> U64:
  4u64

def ic_refuse() -> U64:
  5u64

def ic_kind(+c: IC) -> U64:
  IC{kind, curve, closed, pts, why} = c
  kind

def ic_curve(+c: IC) -> G.GVal:
  IC{kind, curve, closed, pts, why} = c
  curve

def ic_closed(+c: IC) -> Bool:
  IC{kind, curve, closed, pts, why} = c
  closed

def ic_pts(+c: IC) -> List<&2, V.Point>:
  IC{kind, curve, closed, pts, why} = c
  pts

def ic_why(+c: IC) -> U64:
  IC{kind, curve, closed, pts, why} = c
  why

def gnone() -> G.GVal:
  G.GV_f{0.0f64}

def none_ic() -> IC:
  IC{ic_none(), gnone(), False{}, [], 0u64}

def refuse_ic(+why: U64) -> IC:
  IC{ic_refuse(), gnone(), False{}, [], why}

def why_tangent() -> U64:
  71u64

def why_cert() -> U64:
  72u64

def why_kind() -> U64:
  73u64

def is_zero_d(+d: V.Dir) -> Bool:
  Bool.and(F64.is_eq(S.dx(d), 0.0f64), Bool.and(F64.is_eq(S.dy(d), 0.0f64), F64.is_eq(S.dz(d), 0.0f64)))

def axis_aligned(+d: V.Dir) -> Bool:
  +nz = U64.add(Bool.pick(U64, F64.is_eq(S.dx(d), 0.0f64), 0u64, 1u64),
    U64.add(Bool.pick(U64, F64.is_eq(S.dy(d), 0.0f64), 0u64, 1u64),
      Bool.pick(U64, F64.is_eq(S.dz(d), 0.0f64), 0u64, 1u64)))
  U64.is_eq(nz, 1u64)

def snap_plane(+s: S.SF, +p: V.Point) -> V.Point:
  +n = S.sf_a(s)
  +c = S.dot(S.psub(S.sf_o(s), S.pt(0.0f64, 0.0f64, 0.0f64)), n)
  +x = Bool.pick(F64, F64.is_eq(F64.abs(S.dx(n)), 1.0f64), F64.mul(S.dx(n), c), S.px(p))
  +y = Bool.pick(F64, F64.is_eq(F64.abs(S.dy(n)), 1.0f64), F64.mul(S.dy(n), c), S.py(p))
  +z = Bool.pick(F64, F64.is_eq(F64.abs(S.dz(n)), 1.0f64), F64.mul(S.dz(n), c), S.pz(p))
  S.pt(x, y, z)

def refine2(+s1: S.SF, +s2: S.SF, +p: V.Point) -> V.Point:
  +t = S.dunit(S.cross(S.sf_grad(s1, p), S.sf_grad(s2, p)))
  +q = S.newton2(6n, s1, s2, p, t, p)
  +q1 = Bool.pick(V.Point, U64.is_eq(S.sf_kind(s1), S.k_plane()), snap_plane(s1, q), q)
  Bool.pick(V.Point, U64.is_eq(S.sf_kind(s2), S.k_plane()), snap_plane(s2, q1), q1)

def pp_line(+s1: S.SF, +s2: S.SF) -> IC:
  +n1 = S.sf_a(s1)
  +n2 = S.sf_a(s2)
  +d = S.cross(n1, n2)
  +o1 = S.sf_o(s1)
  +o2 = S.sf_o(s2)
  +c1 = S.dot(S.psub(o1, S.pt(0.0f64, 0.0f64, 0.0f64)), n1)
  +c2 = S.dot(S.psub(o2, S.pt(0.0f64, 0.0f64, 0.0f64)), n2)
  +same = F64.is_eq(S.dot(S.psub(o2, o1), n1), 0.0f64)
  +p0 = S.pt(Bool.pick(F64, F64.is_eq(S.dx(d), 0.0f64),
      F64.add(F64.mul(S.dx(n1), c1), F64.mul(S.dx(n2), c2)), 0.0f64),
    Bool.pick(F64, F64.is_eq(S.dy(d), 0.0f64), F64.add(F64.mul(S.dy(n1), c1), F64.mul(S.dy(n2), c2)), 0.0f64),
    Bool.pick(F64, F64.is_eq(S.dz(d), 0.0f64), F64.add(F64.mul(S.dz(n1), c1), F64.mul(S.dz(n2), c2)), 0.0f64))
  +ok = Bool.and(axis_aligned(n1), axis_aligned(n2))
  +n12 = S.dot(n1, n2)
  +n11 = S.dot(n1, n1)
  +n22 = S.dot(n2, n2)
  +dd = S.dot(d, d)
  +g = S.padd(S.padd(S.pt(0.0f64, 0.0f64, 0.0f64), F64.div(F64.sub(F64.mul(c1, n22), F64.mul(c2, n12)), dd), n1),
    F64.div(F64.sub(F64.mul(c2, n11), F64.mul(c1, n12)), dd), n2)
  Bool.pick(IC, is_zero_d(d), Bool.pick(IC, same, IC{ic_coinc(), gnone(), False{}, [], 0u64}, none_ic()),
    IC{ic_line(), G.GV_ln{G.Ln{Bool.pick(V.Point, ok, p0, g), d}}, False{}, [], 0u64})

def ell_pt(+sp: S.SF, +sc: S.SF, +th: F64) -> V.Point:
  +n = S.sf_a(sp)
  +an = S.dot(S.sf_a(sc), n)
  +rr = S.sf_r(sc)
  +k = S.dot(S.psub(S.sf_o(sp), S.sf_o(sc)), n)
  +h = F64.div(F64.sub(k, F64.mul(rr, F64.add(F64.mul(S.fcos(th), S.dot(S.sf_e1(sc), n)),
    F64.mul(S.fsin(th), S.dot(S.sf_e2(sc), n))))), an)
  S.sf_at(sc, th, h)

def nloop() -> Nat:
  64n

def ell_go(n: Nat, +sp: S.SF, +sc: S.SF, +gs: List<&2, G.GVal>, +k: F64, +step: F64,
    +acc: List<&2, V.Point>, +ok: Bool) -> IC:
  match n:
    case 0n:
      Bool.pick(IC, ok, IC{ic_poly(), gnone(), True{}, List.reverse(&2, V.Point, acc), 0u64},
        refuse_ic(why_cert()))
    case 1n+m:
      +p = refine2(sp, sc, ell_pt(sp, sc, F64.mul(k, step)))
      +c = EF.cert_gs(gs, p)
      ell_go(m, sp, sc, gs, F64.add(k, 1.0f64), step, EF.ct_p(c) <> acc, Bool.and(ok, EF.ct_ok(c)))

def pc_delta(+sp: S.SF, +sc: S.SF) -> F64:
  S.dot(S.psub(S.sf_o(sc), S.sf_o(sp)), S.sf_a(sp))

def pc_q(+sp: S.SF, +sc: S.SF) -> F64:
  +d = pc_delta(sp, sc)
  F64.sub(F64.mul(S.sf_r(sc), S.sf_r(sc)), F64.mul(d, d))

def pc_code(+sp: S.SF, +sc: S.SF) -> U64:
  +n = S.sf_a(sp)
  +a = S.sf_a(sc)
  +q = pc_q(sp, sc)
  Bool.pick(U64, is_zero_d(S.cross(a, n)), 1u64,
      Bool.pick(U64, F64.is_eq(S.dot(a, n), 0.0f64),
        Bool.pick(U64, F64.is_lt(0.0f64, q), 2u64, Bool.pick(U64, F64.is_eq(q, 0.0f64), 3u64, 4u64)),
        5u64))

def pc_circle(+sp: S.SF, +sc: S.SF) -> IC:
  +o = S.sf_o(sc)
  +a = S.sf_a(sc)
  +h = S.dot(S.psub(S.sf_o(sp), o), a)
  IC{ic_circle(), G.GV_cc{G.Cc{S.padd(o, h, a), S.sf_e1(sc), S.sf_e2(sc), S.sf_r(sc)}}, True{}, [], 0u64}

def pc_two(+sp: S.SF, +sc: S.SF) -> IC:
  +n = S.sf_a(sp)
  +a = S.sf_a(sc)
  +o = S.sf_o(sc)
  +delta = pc_delta(sp, sc)
  +s = F64.sqrt(F64.max(pc_q(sp, sc), 0.0f64))
  +w = S.cross(a, n)
  +l1 = S.padd(S.padd(o, s, w), F64.neg(delta), n)
  +l2 = S.padd(S.padd(o, F64.neg(s), w), F64.neg(delta), n)
  IC{ic_line(), G.GV_ln{G.Ln{l1, a}}, False{}, [l1, l2], 0u64}

def pc_tan(+sp: S.SF, +sc: S.SF) -> IC:
  +n = S.sf_a(sp)
  +a = S.sf_a(sc)
  IC{ic_line(), G.GV_ln{G.Ln{S.padd(S.sf_o(sc), F64.neg(pc_delta(sp, sc)), n), a}}, False{}, [], 0u64}

def pc_disp(+code: U64, +sp: S.SF, +sc: S.SF, +gs: List<&2, G.GVal>) -> IC:
  match code:
    case 1u64: pc_circle(sp, sc)
    case 2u64: pc_two(sp, sc)
    case 3u64: pc_tan(sp, sc)
    case 4u64: none_ic()
    case _: ell_go(nloop(), sp, sc, gs, 0.0f64, F64.div(S.two_pi(), L.f64_of(nloop())), [], True{})

def pc_go(+sp: S.SF, +sc: S.SF, +gs: List<&2, G.GVal>) -> IC:
  pc_disp(pc_code(sp, sc), sp, sc, gs)

def k_dir(+sk: S.SF, +th: F64) -> V.Dir:
  +k = S.sf_r(sk)
  S.dadd(S.dadd(S.sf_a(sk), F64.mul(k, S.fcos(th)), S.sf_e1(sk)), F64.mul(k, S.fsin(th)), S.sf_e2(sk))

def pk_pt(+sp: S.SF, +sk: S.SF, +th: F64) -> V.Point:
  +n = S.sf_a(sp)
  +num = S.dot(S.psub(S.sf_o(sp), S.sf_o(sk)), n)
  S.sf_at(sk, th, F64.div(num, S.dot(n, k_dir(sk, th))))

def pk_ell(n: Nat, +sp: S.SF, +sk: S.SF, +gs: List<&2, G.GVal>, +i: F64, +step: F64,
    +acc: List<&2, V.Point>, +ok: Bool) -> IC:
  match n:
    case 0n:
      Bool.pick(IC, ok, IC{ic_poly(), gnone(), True{}, List.reverse(&2, V.Point, acc), 0u64},
        refuse_ic(why_cert()))
    case 1n+m:
      +p = refine2(sp, sk, pk_pt(sp, sk, F64.mul(i, step)))
      +c = EF.cert_gs(gs, p)
      pk_ell(m, sp, sk, gs, F64.add(i, 1.0f64), step, EF.ct_p(c) <> acc, Bool.and(ok, EF.ct_ok(c)))

def k_circ(+sk: S.SF, +h: F64) -> IC:
  +o = S.sf_o(sk)
  IC{ic_circle(), G.GV_cc{G.Cc{S.padd(o, h, S.sf_a(sk)), S.sf_e1(sk), S.sf_e2(sk), F64.mul(S.sf_r(sk), h)}}, True{}, [], 0u64}

def pk_code(+sp: S.SF, +sk: S.SF) -> U64:
  +n = S.sf_a(sp)
  +num = S.dot(S.psub(S.sf_o(sp), S.sf_o(sk)), n)
  +c = S.dot(n, S.sf_a(sk))
  +ne1 = S.dot(n, S.sf_e1(sk))
  +ne2 = S.dot(n, S.sf_e2(sk))
  +sw = F64.mul(S.sf_r(sk), F64.sqrt(F64.add(F64.mul(ne1, ne1), F64.mul(ne2, ne2))))
  +side = F64.mul(num, c)
  Bool.pick(U64, F64.is_eq(num, 0.0f64), 3u64,
      Bool.pick(U64, F64.is_le(F64.abs(c), sw), 5u64,
        Bool.pick(U64, F64.is_lt(side, 0.0f64), 4u64,
          Bool.pick(U64, is_zero_d(S.cross(n, S.sf_a(sk))), 1u64, 2u64))))

def pk_disp(+code: U64, +sp: S.SF, +sk: S.SF, +gs: List<&2, G.GVal>) -> IC:
  match code:
    case 1u64: k_circ(sk, F64.div(S.dot(S.psub(S.sf_o(sp), S.sf_o(sk)), S.sf_a(sp)), S.dot(S.sf_a(sp), S.sf_a(sk))))
    case 2u64: pk_ell(nloop(), sp, sk, gs, 0.0f64, F64.div(S.two_pi(), L.f64_of(nloop())), [], True{})
    case 3u64: refuse_ic(why_tangent())
    case 4u64: none_ic()
    case _: refuse_ic(why_kind())

def pk_go(+sp: S.SF, +sk: S.SF, +gs: List<&2, G.GVal>) -> IC:
  pk_disp(pk_code(sp, sk), sp, sk, gs)

def coax(+o1: V.Point, +a1: V.Dir, +o2: V.Point, +a2: V.Dir) -> Bool:
  Bool.and(is_zero_d(S.cross(a1, a2)), is_zero_d(S.cross(S.psub(o2, o1), a1)))

def ck_go(+sc: S.SF, +sk: S.SF) -> IC:
  +ok = coax(S.sf_o(sc), S.sf_a(sc), S.sf_o(sk), S.sf_a(sk))
  Bool.pick(IC, ok, k_circ(sk, F64.div(S.sf_r(sc), S.sf_r(sk))), refuse_ic(why_kind()))

def kk_x(+s1: S.SF, +s2: S.SF) -> F64:
  +sg = S.dot(S.sf_a(s1), S.sf_a(s2))
  +x2 = S.dot(S.psub(S.sf_o(s2), S.sf_o(s1)), S.sf_a(s1))
  +k1 = S.sf_r(s1)
  +k2 = S.sf_r(s2)
  F64.div(F64.neg(F64.mul(F64.mul(k2, sg), x2)), F64.sub(k1, F64.mul(k2, sg)))

def kk_go(+s1: S.SF, +s2: S.SF) -> IC:
  +ok = coax(S.sf_o(s1), S.sf_a(s1), S.sf_o(s2), S.sf_a(s2))
  +sg = S.dot(S.sf_a(s1), S.sf_a(s2))
  +x2 = S.dot(S.psub(S.sf_o(s2), S.sf_o(s1)), S.sf_a(s1))
  +den = F64.sub(S.sf_r(s1), F64.mul(S.sf_r(s2), sg))
  +x = kk_x(s1, s2)
  +h2 = F64.mul(sg, F64.sub(x, x2))
  +hit = Bool.and(F64.is_lt(0.0f64, x), F64.is_lt(0.0f64, h2))
  Bool.pick(IC, Bool.not(ok), refuse_ic(why_kind()),
    Bool.pick(IC, F64.is_eq(den, 0.0f64), Bool.pick(IC, F64.is_eq(x2, 0.0f64), IC{ic_coinc(), gnone(), False{}, [], 0u64}, none_ic()),
      Bool.pick(IC, hit, k_circ(s1, x), none_ic())))

def quad_of(+s1: S.SF, +s2: S.SF, +th: F64) -> V.Dir:
  +p0 = S.sf_at(s1, th, 0.0f64)
  +w = S.sf_tan_v(s1, th)
  +a2 = S.sf_a(s2)
  +d = S.psub(p0, S.sf_o(s2))
  +kn = U64.is_eq(S.sf_kind(s2), S.k_cone())
  +k = S.sf_r(s2)
  +c = Bool.pick(F64, kn, F64.add(1.0f64, F64.mul(k, k)), Bool.pick(F64, S.is_sph(s2), 0.0f64, 1.0f64))
  +e = Bool.pick(F64, kn, 0.0f64, F64.mul(k, k))
  +ca = S.dot(w, a2)
  +ww = Bool.pick(F64, U64.is_eq(S.sf_kind(s1), S.k_cone()), S.dot(w, w), 1.0f64)
  +qa = F64.sub(ww, F64.mul(c, F64.mul(ca, ca)))
  +dh = S.dot(d, a2)
  +qb = F64.mul(2.0f64, F64.sub(S.dot(d, w), F64.mul(c, F64.mul(dh, ca))))
  +qc = F64.sub(F64.sub(S.dot(d, d), F64.mul(c, F64.mul(dh, dh))), e)
  S.dr(qa, qb, qc)

def disc(+s1: S.SF, +s2: S.SF, +th: F64) -> F64:
  +q = quad_of(s1, s2, th)
  F64.sub(F64.mul(S.dy(q), S.dy(q)), F64.mul(4.0f64, F64.mul(S.dx(q), S.dz(q))))

def hroot(+s1: S.SF, +s2: S.SF, +th: F64, +plus: Bool) -> F64:
  +q = quad_of(s1, s2, th)
  +qa = S.dx(q)
  +qb = S.dy(q)
  +dd = F64.sqrt(F64.max(0.0f64, F64.sub(F64.mul(qb, qb), F64.mul(4.0f64, F64.mul(qa, S.dz(q))))))
  F64.div(F64.add(F64.neg(qb), Bool.pick(F64, plus, dd, F64.neg(dd))), F64.mul(2.0f64, qa))

def ccpt(+s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>, +th: F64, +plus: Bool) -> EF.CT:
  +p = refine2(s1, s2, S.sf_at(s1, th, hroot(s1, s2, th, plus)))
  EF.cert_gs(gs, p)

def ds_ivs(+d: DS) -> List<&2, V.Vec2>:
  DS{ivs, allpos, near, ost, open} = d
  ivs

def ds_allpos(+d: DS) -> Bool:
  DS{ivs, allpos, near, ost, open} = d
  allpos

def ds_near(+d: DS) -> Bool:
  DS{ivs, allpos, near, ost, open} = d
  near

def nscan() -> Nat:
  512n

def dbis(n: Nat, +s1: S.SF, +s2: S.SF, +a: F64, +b: F64, +apos: Bool) -> F64:
  match n:
    case 0n: Bool.pick(F64, apos, a, b)
    case 1n+(+m):
      +mid = F64.mul(0.5f64, F64.add(a, b))
      +mpos = F64.is_lt(0.0f64, disc(s1, s2, mid))
      +na = Bool.pick(F64, Bool.not(Bool.xor(mpos, apos)), mid, a)
      +nb = Bool.pick(F64, Bool.not(Bool.xor(mpos, apos)), b, mid)
      dbis(m, s1, s2, na, nb, apos)

def dscan_acc(+down: Bool, +s1: S.SF, +s2: S.SF, +prev: F64, +th: F64, +start: F64,
    +acc: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  match down:
    case True{}: V.V2{start, dbis(80n, s1, s2, prev, th, True{})} <> acc
    case False{}: acc

def dscan_start(+up: Bool, +s1: S.SF, +s2: S.SF, +prev: F64, +th: F64, +start: F64) -> F64:
  match up:
    case True{}: dbis(80n, s1, s2, prev, th, False{})
    case False{}: start

def dscan(n: Nat, +s1: S.SF, +s2: S.SF, +k: F64, +step: F64, +prev: F64, +ppos: Bool,
    +start: F64, +acc: List<&2, V.Vec2>, +allpos: Bool, +near: Bool, +tol: F64, +pprev: F64)
    -> DS:
  match n:
    case 0n: DS{acc, allpos, near, start, ppos}
    case 1n+m:
      +th = F64.mul(k, step)
      +dv = disc(s1, s2, th)
      +pos = F64.is_lt(0.0f64, dv)
      +up = Bool.and(pos, Bool.not(ppos))
      +down = Bool.and(Bool.not(pos), ppos)
      +mn = Bool.and(F64.is_le(F64.abs(pprev), F64.abs(dv)), F64.is_lt(F64.abs(dv), tol))
      dscan(m, s1, s2, F64.add(k, 1.0f64), step, th, pos, dscan_start(up, s1, s2, prev, th, start),
        dscan_acc(down, s1, s2, prev, th, start, acc), Bool.and(allpos, pos),
        Bool.or(near, mn), tol, dv)

def disc_scan(+s1: S.SF, +s2: S.SF) -> DS:
  +step = F64.div(S.two_pi(), L.f64_of(nscan()))
  +d0 = disc(s1, s2, 0.0f64)
  +r = F64.max(S.sf_r(s1), S.sf_r(s2))
  +tol = F64.mul(1.0e-10f64, F64.mul(r, F64.mul(r, F64.mul(r, r))))
  dscan(nscan(), s1, s2, 1.0f64, step, 0.0f64, F64.is_lt(0.0f64, d0), F64.neg(1.0f64), [],
    F64.is_lt(0.0f64, d0), False{}, tol, d0)

def cheb(+a: F64, +b: F64, +k: F64, +n: F64) -> F64:
  +s = F64.div(k, n)
  F64.add(a, F64.mul(F64.sub(b, a), F64.mul(0.5f64, F64.sub(1.0f64, S.fcos(F64.mul(S.pi(), s))))))

def pl_pts(+p: PL) -> List<&2, V.Point>:
  PL{pts, ok} = p
  pts

def pl_ok(+p: PL) -> Bool:
  PL{pts, ok} = p
  ok

def branch_go(n: Nat, +s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>, +a: F64, +b: F64,
    +k: F64, +nn: F64, +plus: Bool, +acc: List<&2, V.Point>, +ok: Bool) -> PL:
  match n:
    case 0n: PL{acc, ok}
    case 1n+m:
      +th = cheb(a, b, k, nn)
      +c = ccpt(s1, s2, gs, th, plus)
      branch_go(m, s1, s2, gs, a, b, F64.add(k, 1.0f64), nn, plus, EF.ct_p(c) <> acc,
        Bool.and(ok, EF.ct_ok(c)))

def full_go(n: Nat, +s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>, +k: F64, +step: F64,
    +plus: Bool, +acc: List<&2, V.Point>, +ok: Bool) -> PL:
  match n:
    case 0n: PL{List.reverse(&2, V.Point, acc), ok}
    case 1n+m:
      +c = ccpt(s1, s2, gs, F64.mul(k, step), plus)
      full_go(m, s1, s2, gs, F64.add(k, 1.0f64), step, plus, EF.ct_p(c) <> acc,
        Bool.and(ok, EF.ct_ok(c)))

def nbr() -> Nat:
  40n

def loop_of_iv(+s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>, +iv: V.Vec2) -> PL:
  +a = V.v2_x(iv)
  +b = V.v2_y(iv)
  +nn = L.f64_of(nbr())
  +up = branch_go(Nat.add(nbr(), 1n), s1, s2, gs, a, b, 0.0f64, nn, True{}, [], True{})
  +dn = branch_go(Nat.sub(nbr(), 1n), s1, s2, gs, b, a, 1.0f64, nn, False{}, [], True{})
  PL{List.append(&2, V.Point, List.reverse(&2, V.Point, pl_pts(up)), List.reverse(&2, V.Point, pl_pts(dn))),
    Bool.and(pl_ok(up), pl_ok(dn))}

def wrap_ivs(ivs: List<&2, V.Vec2>, +first: F64) -> List<&2, V.Vec2>:
  match ivs:
    case []: []
    case +h <> +t:
      Bool.pick(List<&2, V.Vec2>, F64.is_lt(V.v2_x(h), 0.0f64), V.V2{first, V.v2_y(h)} <> t,
        h <> wrap_ivs(t, first))

def ics_ics(+c: ICS) -> List<&2, IC>:
  ICS{ics, why} = c
  ics

def ics_why(+c: ICS) -> U64:
  ICS{ics, why} = c
  why

def loops_go(ivs: List<&2, V.Vec2>, +s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>) -> ICS:
  match ivs:
    case []: ICS{[], 0u64}
    case +h <> +t:
      +pl = loop_of_iv(s1, s2, gs, h)
      +rest = loops_go(t, s1, s2, gs)
      Bool.pick(ICS, pl_ok(pl),
        ICS{IC{ic_poly(), gnone(), True{}, pl_pts(pl), 0u64} <> ics_ics(rest), ics_why(rest)},
        ICS{ics_ics(rest), why_cert()})

def cc_full(+s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>) -> ICS:
  +n = Nat.mul(nloop(), 2n)
  +step = F64.div(S.two_pi(), L.f64_of(n))
  +p1 = full_go(n, s1, s2, gs, 0.0f64, step, True{}, [], True{})
  +p2 = full_go(n, s1, s2, gs, 0.0f64, step, False{}, [], True{})
  Bool.pick(ICS, Bool.and(pl_ok(p1), pl_ok(p2)),
    ICS{[IC{ic_poly(), gnone(), True{}, pl_pts(p1), 0u64}, IC{ic_poly(), gnone(), True{}, pl_pts(p2), 0u64}], 0u64},
    ICS{[], why_cert()})

def ds_ost(+d: DS) -> F64:
  DS{ivs, allpos, near, ost, open} = d
  ost

def cc_ivs(+s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>, +ds: DS) -> ICS:
  +r = List.reverse(&2, V.Vec2, ds_ivs(ds))
  loops_go(wrap_ivs(r, F64.sub(ds_ost(ds), S.two_pi())), s1, s2, gs)

def cc_disp(+code: U64, +s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>, +ds: DS) -> ICS:
  match code:
    case 0u64: ICS{[], why_tangent()}
    case 1u64: cc_full(s1, s2, gs)
    case _: cc_ivs(s1, s2, gs, ds)

def stein_ok(+s1: S.SF, +s2: S.SF) -> Bool:
  +n = S.cross(S.sf_a(s1), S.sf_a(s2))
  +d = S.psub(S.sf_o(s2), S.sf_o(s1))
  Bool.and(F64.is_eq(S.sf_r(s1), S.sf_r(s2)), Bool.and(F64.is_eq(S.dot(d, n), 0.0f64), Bool.not(is_zero_d(n))))

def ic_brk() -> U64:
  6u64

def stein_o(+s1: S.SF, +s2: S.SF) -> V.Point:
  +a1 = S.sf_a(s1)
  +a2 = S.sf_a(s2)
  +d = S.psub(S.sf_o(s2), S.sf_o(s1))
  +c = S.dot(a1, a2)
  +den = F64.sub(1.0f64, F64.mul(c, c))
  +t = F64.div(F64.sub(S.dot(d, a1), F64.mul(c, S.dot(d, a2))), den)
  S.padd(S.sf_o(s1), t, a1)

def stein_pt(+s1: S.SF, +o: V.Point, +m: V.Dir, +th: F64) -> V.Point:
  +a = S.sf_a(s1)
  +r = S.sf_r(s1)
  +k = S.dot(S.psub(o, S.sf_o(s1)), m)
  +h = F64.div(F64.sub(k, F64.mul(r, F64.add(F64.mul(S.fcos(th), S.dot(S.sf_e1(s1), m)), F64.mul(S.fsin(th), S.dot(S.sf_e2(s1), m))))), S.dot(a, m))
  S.sf_at(s1, th, h)

def stein_go(n: Nat, +s1: S.SF, +gs: List<&2, G.GVal>, +o: V.Point, +m: V.Dir, +k: F64, +step: F64,
    +acc: List<&2, V.Point>, +ok: Bool) -> PL:
  match n:
    case 0n: PL{List.reverse(&2, V.Point, acc), ok}
    case 1n+mm:
      +c = EF.cert_gs(gs, stein_pt(s1, o, m, F64.mul(k, step)))
      stein_go(mm, s1, gs, o, m, F64.add(k, 1.0f64), step, EF.ct_p(c) <> acc, Bool.and(ok, EF.ct_ok(c)))

def stein(+s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>) -> ICS:
  +o = stein_o(s1, s2)
  +a1 = S.sf_a(s1)
  +a2 = S.sf_a(s2)
  +m1 = S.dunit(S.dadd(a1, 1.0f64, a2))
  +m2 = S.dunit(S.dadd(a1, F64.neg(1.0f64), a2))
  +n = S.dunit(S.cross(a1, a2))
  +r = S.sf_r(s1)
  +pp = S.padd(o, r, n)
  +pm = S.padd(o, F64.neg(r), n)
  +step = F64.div(S.two_pi(), L.f64_of(Nat.mul(nloop(), 2n)))
  +l1 = stein_go(Nat.mul(nloop(), 2n), s1, gs, o, m1, 0.0f64, step, [], True{})
  +l2 = stein_go(Nat.mul(nloop(), 2n), s1, gs, o, m2, 0.0f64, step, [], True{})
  +okp = Bool.and(EF.on_all(gs, pp), EF.on_all(gs, pm))
  Bool.pick(ICS, Bool.and(okp, Bool.and(pl_ok(l1), pl_ok(l2))),
    ICS{[IC{ic_poly(), gnone(), True{}, pl_pts(l1), 0u64}, IC{ic_poly(), gnone(), True{}, pl_pts(l2), 0u64},
      IC{ic_brk(), gnone(), False{}, [pp, pm], 0u64}], 0u64},
    ICS{[], why_cert()})

def cc_skew_go(+st: Bool, +s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>) -> ICS:
  match st:
    case True{}: stein(s1, s2, gs)
    case False{}:
      +ds = disc_scan(s1, s2)
      cc_disp(Bool.pick(U64, ds_near(ds), 0u64, Bool.pick(U64, ds_allpos(ds), 1u64, 2u64)), s1, s2, gs, ds)

def cc_skew(+s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>) -> ICS:
  cc_skew_go(stein_ok(s1, s2), s1, s2, gs)

def cc_par(+s1: S.SF, +s2: S.SF) -> ICS:
  +a = S.sf_a(s1)
  +d = S.psub(S.sf_o(s2), S.sf_o(s1))
  +dp = S.dadd(d, F64.neg(S.dot(d, a)), a)
  +dd = S.dlen(dp)
  +r1 = S.sf_r(s1)
  +r2 = S.sf_r(s2)
  +coax = F64.is_eq(dd, 0.0f64)
  +x = F64.div(F64.add(F64.sub(F64.mul(dd, dd), F64.mul(r2, r2)), F64.mul(r1, r1)), F64.mul(2.0f64, dd))
  +y2 = F64.sub(F64.mul(r1, r1), F64.mul(x, x))
  +y = F64.sqrt(F64.max(0.0f64, y2))
  +u = S.dscale(F64.div(1.0f64, dd), dp)
  +w = S.cross(a, u)
  +l1 = S.padd(S.padd(S.sf_o(s1), x, u), y, w)
  +l2 = S.padd(S.padd(S.sf_o(s1), x, u), F64.neg(y), w)
  Bool.pick(ICS, coax,
    Bool.pick(ICS, F64.is_eq(r1, r2), ICS{[IC{ic_coinc(), gnone(), False{}, [], 0u64}], 0u64}, ICS{[], 0u64}),
    Bool.pick(ICS, F64.is_lt(0.0f64, y2),
      ICS{[IC{ic_line(), G.GV_ln{G.Ln{l1, a}}, False{}, [], 0u64}, IC{ic_line(), G.GV_ln{G.Ln{l2, a}}, False{}, [], 0u64}], 0u64},
      Bool.pick(ICS, F64.is_eq(y2, 0.0f64), ICS{[IC{ic_line(), G.GV_ln{G.Ln{l1, a}}, False{}, [], 0u64}], 0u64}, ICS{[], 0u64})))

def sp_circ(+c: V.Point, +n: V.Dir, +rho: F64) -> IC:
  +e1 = S.perp_of(n)
  IC{ic_circle(), G.GV_cc{G.Cc{c, e1, S.cross(n, e1), rho}}, True{}, [], 0u64}

def q_ic(+q: F64, +ic: IC) -> IC:
  Bool.pick(IC, F64.is_lt(0.0f64, q), ic, Bool.pick(IC, F64.is_eq(q, 0.0f64), refuse_ic(why_tangent()), none_ic()))

def ps_go(+sp: S.SF, +ss: S.SF) -> IC:
  +n = S.sf_a(sp)
  +dl = S.dot(S.psub(S.sf_o(ss), S.sf_o(sp)), n)
  +r = S.sf_r(ss)
  +q = F64.mul(F64.add(r, dl), F64.sub(r, dl))
  +e1 = S.sf_e1(sp)
  q_ic(q, IC{ic_circle(), G.GV_cc{G.Cc{S.padd(S.sf_o(ss), F64.neg(dl), n), e1, S.cross(n, e1), F64.sqrt(F64.max(0.0f64, q))}}, True{}, [], 0u64})

def sss_go(+s1: S.SF, +s2: S.SF) -> IC:
  +v = S.psub(S.sf_o(s2), S.sf_o(s1))
  +d = S.dlen(v)
  +r1 = S.sf_r(s1)
  +r2 = S.sf_r(s2)
  +x = F64.div(F64.add(F64.mul(d, d), F64.mul(F64.add(r1, r2), F64.sub(r1, r2))), F64.mul(2.0f64, d))
  +q = F64.mul(F64.add(r1, x), F64.sub(r1, x))
  +u = S.dscale(F64.div(1.0f64, d), v)
  Bool.pick(IC, F64.is_eq(d, 0.0f64),
    Bool.pick(IC, F64.is_eq(r1, r2), IC{ic_coinc(), gnone(), False{}, [], 0u64}, none_ic()),
    q_ic(q, sp_circ(S.padd(S.sf_o(s1), x, u), u, F64.sqrt(F64.max(0.0f64, q)))))

def two_ics(+a: IC, +b: IC) -> ICS:
  Bool.pick(ICS, U64.is_eq(ic_kind(a), ic_refuse()), ICS{[], ic_why(a)},
    Bool.pick(ICS, U64.is_eq(ic_kind(a), ic_none()), ICS{[], 0u64}, ICS{[a, b], 0u64}))

def cs_coax(+sc: S.SF, +ss: S.SF) -> ICS:
  +a = S.sf_a(sc)
  +hc = S.dot(S.psub(S.sf_o(ss), S.sf_o(sc)), a)
  +rs = S.sf_r(ss)
  +rc = S.sf_r(sc)
  +q = F64.mul(F64.add(rs, rc), F64.sub(rs, rc))
  +t = F64.sqrt(F64.max(0.0f64, q))
  +o = S.sf_o(sc)
  Bool.pick(ICS, F64.is_eq(q, 0.0f64), ICS{[sp_circ(S.padd(o, hc, a), a, rc)], 0u64},
    two_ics(q_ic(q, sp_circ(S.padd(o, F64.add(hc, t), a), a, rc)), sp_circ(S.padd(o, F64.sub(hc, t), a), a, rc)))

def cs_go(+sc: S.SF, +ss: S.SF, +gs: List<&2, G.GVal>) -> ICS:
  Bool.pick(ICS, is_zero_d(S.cross(S.psub(S.sf_o(ss), S.sf_o(sc)), S.sf_a(sc))), cs_coax(sc, ss),
    cc_skew_go(False{}, sc, ss, gs))

def ks_root(+k: F64, +hc: F64, +rs: F64, +plus: Bool) -> F64:
  +qa = F64.add(1.0f64, F64.mul(k, k))
  +qq = F64.sub(F64.mul(hc, hc), F64.mul(qa, F64.sub(F64.mul(hc, hc), F64.mul(rs, rs))))
  +sq = F64.sqrt(F64.max(0.0f64, qq))
  F64.div(F64.add(hc, Bool.pick(F64, plus, sq, F64.neg(sq))), qa)

def ks_one(+sk: S.SF, +h: F64) -> IC:
  Bool.pick(IC, F64.is_lt(0.0f64, F64.mul(S.sf_r(sk), h)), k_circ(sk, h), none_ic())

def ks_list(+a: IC, +b: IC) -> ICS:
  +la = Bool.pick(List<&2, IC>, U64.is_eq(ic_kind(a), ic_circle()), [a], [])
  +lb = Bool.pick(List<&2, IC>, U64.is_eq(ic_kind(b), ic_circle()), [b], [])
  ICS{List.append(&2, IC, la, lb), 0u64}

def ks_go(+sk: S.SF, +ss: S.SF) -> ICS:
  +a = S.sf_a(sk)
  +ok = is_zero_d(S.cross(S.psub(S.sf_o(ss), S.sf_o(sk)), a))
  +k = S.sf_r(sk)
  +hc = S.dot(S.psub(S.sf_o(ss), S.sf_o(sk)), a)
  +rs = S.sf_r(ss)
  +qa = F64.add(1.0f64, F64.mul(k, k))
  +qq = F64.sub(F64.mul(hc, hc), F64.mul(qa, F64.sub(F64.mul(hc, hc), F64.mul(rs, rs))))
  Bool.pick(ICS, Bool.not(ok), ICS{[], why_kind()},
    Bool.pick(ICS, F64.is_eq(qq, 0.0f64), ks_list(ks_one(sk, F64.div(hc, qa)), none_ic()),
      Bool.pick(ICS, F64.is_lt(qq, 0.0f64), ICS{[], 0u64},
        ks_list(ks_one(sk, ks_root(k, hc, rs, True{})), ks_one(sk, ks_root(k, hc, rs, False{}))))))

def one(+c: IC) -> ICS:
  Bool.pick(ICS, U64.is_eq(ic_kind(c), ic_refuse()), ICS{[], ic_why(c)},
    Bool.pick(ICS, U64.is_eq(ic_kind(c), ic_none()), ICS{[], 0u64}, ICS{[c], 0u64}))

def ck_ics(+co: Bool, +sc: S.SF, +sk: S.SF, +gs: List<&2, G.GVal>) -> ICS:
  match co:
    case True{}: one(Bool.pick(IC, U64.is_eq(S.sf_kind(sc), S.k_cone()), kk_go(sc, sk), ck_go(sc, sk)))
    case False{}: cc_skew_go(False{}, sc, sk, gs)

def ln_of(+g: G.GVal) -> G.Line3:
  match g:
    case G.GV_ln{w}: w
    case _: G.Ln{S.pt(0.0f64, 0.0f64, 0.0f64), S.dr(1.0f64, 0.0f64, 0.0f64)}

def pc_two_lines(+pts: List<&2, V.Point>, +d: V.Dir) -> ICS:
  ICS{[IC{ic_line(), G.GV_ln{G.Ln{L.nth_p(pts, 0n), d}}, False{}, [], 0u64},
    IC{ic_line(), G.GV_ln{G.Ln{L.nth_p(pts, 1n), d}}, False{}, [], 0u64}], 0u64}

def pc_lines_d(+code: U64, +c: IC) -> ICS:
  match code:
    case 1u64: pc_two_lines(ic_pts(c), G.ln_d(ln_of(ic_curve(c))))
    case _: one(c)

def pc_lines(+c: IC) -> ICS:
  pc_lines_d(Bool.pick(U64, Bool.and(U64.is_eq(ic_kind(c), ic_line()), Nat.is_eq(List.length(&2, V.Point, ic_pts(c)), 2n)), 1u64, 0u64), c)

def tc(+o: V.Point, +a: V.Dir, +h: F64, +rho: F64) -> IC:
  sp_circ(S.padd(o, h, a), a, rho)

def ics_of(cs: List<&2, IC>) -> ICS:
  ICS{cs, 0u64}

def tp_perp(+st: S.SF, +h: F64) -> ICS:
  +o = S.sf_o(st)
  +a = S.sf_a(st)
  +bigr = S.sf_r(st)
  +r = S.sf_r2(st)
  +q = F64.mul(F64.add(r, h), F64.sub(r, h))
  +w = F64.sqrt(F64.max(0.0f64, q))
  Bool.pick(ICS, F64.is_lt(q, 0.0f64), ICS{[], 0u64},
    Bool.pick(ICS, F64.is_eq(q, 0.0f64), ics_of([tc(o, a, h, bigr)]),
      ics_of([tc(o, a, h, F64.add(bigr, w)), tc(o, a, h, F64.sub(bigr, w))])))

def tp_axial(+sp: S.SF, +st: S.SF) -> ICS:
  +n = S.sf_a(sp)
  +o = S.sf_o(st)
  +w = S.dunit(S.cross(S.sf_a(st), n))
  +bigr = S.sf_r(st)
  +r = S.sf_r2(st)
  ics_of([sp_circ(S.padd(o, bigr, w), n, r), sp_circ(S.padd(o, F64.neg(bigr), w), n, r)])

def tp_go(+sp: S.SF, +st: S.SF) -> ICS:
  +n = S.sf_a(sp)
  +a = S.sf_a(st)
  +dl = S.dot(S.psub(S.sf_o(sp), S.sf_o(st)), n)
  +perp = is_zero_d(S.cross(a, n))
  +axial = Bool.and(F64.is_eq(S.dot(a, n), 0.0f64), F64.is_eq(dl, 0.0f64))
  Bool.pick(ICS, perp, tp_perp(st, F64.mul(dl, S.dot(a, n))),
    Bool.pick(ICS, axial, tp_axial(sp, st), ICS{[], why_kind()}))

def tcy_go(+sc: S.SF, +st: S.SF) -> ICS:
  +ok = coax(S.sf_o(sc), S.sf_a(sc), S.sf_o(st), S.sf_a(st))
  +o = S.sf_o(st)
  +a = S.sf_a(st)
  +dr = F64.sub(S.sf_r(sc), S.sf_r(st))
  +r = S.sf_r2(st)
  +q = F64.mul(F64.add(r, dr), F64.sub(r, dr))
  +w = F64.sqrt(F64.max(0.0f64, q))
  +rc = S.sf_r(sc)
  Bool.pick(ICS, Bool.not(ok), ICS{[], why_kind()},
    Bool.pick(ICS, F64.is_lt(q, 0.0f64), ICS{[], 0u64},
      Bool.pick(ICS, F64.is_eq(q, 0.0f64), ics_of([tc(o, a, 0.0f64, rc)]),
        ics_of([tc(o, a, w, rc), tc(o, a, F64.neg(w), rc)]))))

def ks_sel(+sk: S.SF, +ss: S.SF, +gs: List<&2, G.GVal>) -> ICS:
  Bool.pick(ICS, is_zero_d(S.cross(S.psub(S.sf_o(ss), S.sf_o(sk)), S.sf_a(sk))), ks_go(sk, ss), cc_skew_go(False{}, sk, ss, gs))

def ssi_disp(+code: U64, +s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>) -> ICS:
  match code:
    case 0u64: one(pp_line(s1, s2))
    case 1u64: pc_lines(pc_go(s1, s2, gs))
    case 2u64: pc_lines(pc_go(s2, s1, gs))
    case 3u64: cc_par(s1, s2)
    case 4u64: cc_skew(s1, s2, gs)
    case 5u64: one(pk_go(s1, s2, gs))
    case 6u64: one(pk_go(s2, s1, gs))
    case 7u64: ck_ics(coax(S.sf_o(s1), S.sf_a(s1), S.sf_o(s2), S.sf_a(s2)), s1, s2, gs)
    case 8u64: ck_ics(coax(S.sf_o(s1), S.sf_a(s1), S.sf_o(s2), S.sf_a(s2)), s2, s1, gs)
    case 9u64: ck_ics(coax(S.sf_o(s1), S.sf_a(s1), S.sf_o(s2), S.sf_a(s2)), s1, s2, gs)
    case 11u64: one(ps_go(s1, s2))
    case 12u64: one(ps_go(s2, s1))
    case 13u64: one(sss_go(s1, s2))
    case 14u64: cs_go(s1, s2, gs)
    case 15u64: cs_go(s2, s1, gs)
    case 16u64: ks_sel(s1, s2, gs)
    case 17u64: ks_sel(s2, s1, gs)
    case 18u64: tp_go(s1, s2)
    case 19u64: tp_go(s2, s1)
    case 20u64: tcy_go(s1, s2)
    case 21u64: tcy_go(s2, s1)
    case _: ICS{[], why_kind()}

def to_code(+k1: U64, +k2: U64) -> U64:
  +to = S.k_tor()
  +pl = S.k_plane()
  +cy = S.k_cyl()
  Bool.pick(U64, Bool.and(U64.is_eq(k1, pl), U64.is_eq(k2, to)), 18u64,
    Bool.pick(U64, Bool.and(U64.is_eq(k1, to), U64.is_eq(k2, pl)), 19u64,
      Bool.pick(U64, Bool.and(U64.is_eq(k1, cy), U64.is_eq(k2, to)), 20u64,
        Bool.pick(U64, Bool.and(U64.is_eq(k1, to), U64.is_eq(k2, cy)), 21u64, 10u64))))

def sp_code(+k1: U64, +k2: U64) -> U64:
  +sp = S.k_sph()
  +pl = S.k_plane()
  +cy = S.k_cyl()
  +co = S.k_cone()
  Bool.pick(U64, Bool.and(U64.is_eq(k1, pl), U64.is_eq(k2, sp)), 11u64,
    Bool.pick(U64, Bool.and(U64.is_eq(k1, sp), U64.is_eq(k2, pl)), 12u64,
      Bool.pick(U64, Bool.and(U64.is_eq(k1, sp), U64.is_eq(k2, sp)), 13u64,
        Bool.pick(U64, Bool.and(U64.is_eq(k1, cy), U64.is_eq(k2, sp)), 14u64,
          Bool.pick(U64, Bool.and(U64.is_eq(k1, sp), U64.is_eq(k2, cy)), 15u64,
            Bool.pick(U64, Bool.and(U64.is_eq(k1, co), U64.is_eq(k2, sp)), 16u64,
              Bool.pick(U64, Bool.and(U64.is_eq(k1, sp), U64.is_eq(k2, co)), 17u64, to_code(k1, k2))))))))

def ssi_code(+s1: S.SF, +s2: S.SF) -> U64:
  +k1 = S.sf_kind(s1)
  +k2 = S.sf_kind(s2)
  +pl = S.k_plane()
  +cy = S.k_cyl()
  +co = S.k_cone()
  Bool.pick(U64, Bool.and(U64.is_eq(k1, pl), U64.is_eq(k2, pl)), 0u64,
    Bool.pick(U64, Bool.and(U64.is_eq(k1, pl), U64.is_eq(k2, cy)), 1u64,
      Bool.pick(U64, Bool.and(U64.is_eq(k1, cy), U64.is_eq(k2, pl)), 2u64,
        Bool.pick(U64, Bool.and(U64.is_eq(k1, cy), U64.is_eq(k2, cy)),
          Bool.pick(U64, is_zero_d(S.cross(S.sf_a(s1), S.sf_a(s2))), 3u64, 4u64),
          Bool.pick(U64, Bool.and(U64.is_eq(k1, pl), U64.is_eq(k2, co)), 5u64,
            Bool.pick(U64, Bool.and(U64.is_eq(k1, co), U64.is_eq(k2, pl)), 6u64,
              Bool.pick(U64, Bool.and(U64.is_eq(k1, cy), U64.is_eq(k2, co)), 7u64,
                Bool.pick(U64, Bool.and(U64.is_eq(k1, co), U64.is_eq(k2, cy)), 8u64,
                  Bool.pick(U64, Bool.and(U64.is_eq(k1, co), U64.is_eq(k2, co)), 9u64, sp_code(k1, k2))))))))))

def ssi(+g1: G.GVal, +g2: G.GVal) -> ICS:
  +s1 = S.sf_of(g1)
  +s2 = S.sf_of(g2)
  ssi_disp(ssi_code(s1, s2), s1, s2, {[g1, g2] : List<&2, G.GVal>})
