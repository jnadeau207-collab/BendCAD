import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ./sf.bend as S
import ../c03/bpi.bend as BI
import ./ef.bend as EF
import ./ls.bend as L




type BX is Data:
  BX{ x0: F64, x1: F64, y0: F64, y1: F64, z0: F64, z1: F64 }



type MP is Data:
  MP{ cir: Bool, ph: F64, pr: F64, dh: F64, dr: F64, rad: F64 }

type RX is Data:
  RX{ hs: List<&2, V.Vec2>, bad: Bool }

type IC is Data:
  IC{ kind: U64, curve: G.GVal, closed: Bool, pts: List<&2, V.Point>, why: U64 }




type DS is Data:
  DS{ ivs: List<&2, V.Vec2>, allpos: Bool, near: Bool, ost: F64, open: Bool }




type PL is Data:
  PL{ pts: List<&2, V.Point>, ok: Bool }




type ICS is Data:
  ICS{ ics: List<&2, IC>, why: U64 }




type FS is Data:
  FS{ ics: ICS, seen: List<&2, V.Point> }

type FP is Data:
  FP{ sb: S.SF, s1: S.SF, s2: S.SF, h: F64, gs: List<&2, G.GVal>, bx: BX, vd: V.Vec2, tb: BX }




type TR is Data:
  TR{ pts: List<&2, V.Point>, closed: Bool, ok: Bool }

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

def sep_tol(+x: F64) -> F64:
  F64.mul(1.0e-9f64, F64.add(1.0f64, F64.abs(x)))

def ax_dist(+p: V.Point, +o: V.Point, +a: V.Dir) -> F64:
  +v = S.psub(p, o)
  F64.div(S.dlen(S.cross(v, a)), S.dlen(a))

def fr_rad(+s: S.SF) -> F64:
  +k = S.sf_kind(s)
  Bool.pick(F64, Bool.or(U64.is_eq(k, S.k_cyl()), S.is_sph(s)), S.sf_r(s),
    Bool.pick(F64, S.is_tor(s), S.sf_r2(s), F64.div(1.0f64, 0.0f64)))

def fr_side(+w: G.BezP) -> F64:
  G.Bp{+p00, p01, p02, +p03, p10, p11, p12, p13, p20, p21, p22, p23, +p30, p31, p32, +p33} = w
  +sp = BI.bp_span(w)
  +m = F64.min(F64.min(S.dist(p00, p03), S.dist(p30, p33)), F64.min(S.dist(p00, p30), S.dist(p03, p33)))
  F64.min(F64.div(sp, 48.0f64), F64.max(F64.div(m, 8.0f64), F64.mul(1.0e-4f64, sp)))

def fr_span(+s: S.SF) -> F64:
  match s:
    case S.SF_bp{gw}: fr_side(S.gbp(gw))
    case _: F64.div(1.0f64, 0.0f64)

def fr_h(+s1: S.SF, +s2: S.SF) -> F64:
  F64.min(F64.min(fr_span(s1), fr_span(s2)), F64.min(F64.div(fr_rad(s1), 8.0f64), F64.div(fr_rad(s2), 8.0f64)))

def fr_pt(+s: S.SF, +a: F64, +b: F64, +vd: V.Vec2) -> V.Point:
  match s:
    case S.SF_bp{gw}: S.bp_at(S.gbp(gw), a, b)
    case _: S.sf_at(s, F64.mul(S.two_pi(), a), F64.add(V.v2_x(vd), F64.mul(F64.sub(V.v2_y(vd), V.v2_x(vd)), b)))

def fr_g(+sb: S.SF, +so: S.SF, +u: F64, +v: F64, +vd: V.Vec2) -> F64:
  S.sf_f(so, fr_pt(sb, u, v, vd))

def fr_n() -> F64:
  12.0f64

def fr_flip(+a: F64, +b: F64) -> Bool:
  Bool.or(Bool.and(F64.is_lt(a, 0.0f64), F64.is_le(0.0f64, b)), Bool.and(F64.is_le(0.0f64, a), F64.is_lt(b, 0.0f64)))

def fr_frac(+a: F64, +b: F64) -> F64:
  +d = F64.sub(a, b)
  Bool.pick(F64, F64.is_eq(d, 0.0f64), 0.5f64, F64.div(a, d))

def fr_su(i: Nat, +sb: S.SF, +so: S.SF, +vd: V.Vec2, +j: F64, +acc: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  match i:
    case 0n: acc
    case 1n+(+m):
      +x = L.f64_of(m)
      +n = fr_n()
      +v = F64.div(j, n)
      +a = fr_g(sb, so, F64.div(x, n), v, vd)
      +b = fr_g(sb, so, F64.div(F64.add(x, 1.0f64), n), v, vd)
      fr_su(m, sb, so, vd, j, Bool.pick(List<&2, V.Vec2>, fr_flip(a, b), V.V2{F64.div(F64.add(x, fr_frac(a, b)), n), v} <> acc, acc))

def fr_sv(i: Nat, +sb: S.SF, +so: S.SF, +vd: V.Vec2, +j: F64, +acc: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  match i:
    case 0n: acc
    case 1n+(+m):
      +x = L.f64_of(m)
      +n = fr_n()
      +u = F64.div(j, n)
      +a = fr_g(sb, so, u, F64.div(x, n), vd)
      +b = fr_g(sb, so, u, F64.div(F64.add(x, 1.0f64), n), vd)
      fr_sv(m, sb, so, vd, j, Bool.pick(List<&2, V.Vec2>, fr_flip(a, b), V.V2{u, F64.div(F64.add(x, fr_frac(a, b)), n)} <> acc, acc))

def fr_rows(j: Nat, +sb: S.SF, +so: S.SF, +vd: V.Vec2, +acc: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  match j:
    case 0n: acc
    case 1n+(+m):
      +x = L.f64_of(m)
      fr_rows(m, sb, so, vd, fr_sv(12n, sb, so, vd, x, fr_su(12n, sb, so, vd, x, acc)))

def fr_seeds(+sb: S.SF, +so: S.SF, +vd: V.Vec2) -> List<&2, V.Vec2>:
  fr_rows(13n, sb, so, vd, [])

def fr_tan(+s1: S.SF, +s2: S.SF, +p: V.Point) -> V.Dir:
  S.cross(S.sf_grad(s1, p), S.sf_grad(s2, p))

def fr_near(ps: List<&2, V.Point>, +p: V.Point, +r: F64) -> Bool:
  match ps:
    case []: False{}
    case +h <> +t: Bool.or(F64.is_lt(S.dist(h, p), r), fr_near(t, p, r))

def fs_ics(+f: FS) -> ICS:
  FS{ics, seen} = f
  ics

def fs_seen(+f: FS) -> List<&2, V.Point>:
  FS{ics, seen} = f
  seen

def tr_pts(+r: TR) -> List<&2, V.Point>:
  TR{pts, closed, ok} = r
  pts

def fr_dir(+s1: S.SF, +s2: S.SF, +p: V.Point, +d: V.Dir) -> V.Dir:
  +t = S.dunit(fr_tan(s1, s2, p))
  Bool.pick(V.Dir, F64.is_lt(S.dot(t, d), 0.0f64), S.dscale(F64.neg(1.0f64), t), t)

def fr_dom(+x: F64) -> Bool:
  Bool.and(F64.is_le(F64.neg(0.02f64), x), F64.is_le(x, 1.02f64))

def fr_in(+s: S.SF, +p: V.Point) -> Bool:
  match s:
    case S.SF_bp{gw}:
      +q = S.bp_uv(S.gbp(gw), p)
      Bool.and(fr_dom(V.v2_x(q)), fr_dom(V.v2_y(q)))
    case _: True{}

def fr_tok(+s1: S.SF, +s2: S.SF, +p: V.Point) -> Bool:
  F64.is_lt(F64.mul(1.0e-6f64, F64.mul(S.dlen(S.sf_grad(s1, p)), S.dlen(S.sf_grad(s2, p)))), S.dlen(fr_tan(s1, s2, p)))

def bx_all() -> BX:
  +inf = F64.div(1.0f64, 0.0f64)
  BX{F64.neg(inf), inf, F64.neg(inf), inf, F64.neg(inf), inf}

def bx_in(+b: BX, +p: V.Point) -> Bool:
  BX{+x0, +x1, +y0, +y1, +z0, +z1} = b
  Bool.and(Bool.and(Bool.and(F64.is_le(x0, S.px(p)), F64.is_le(S.px(p), x1)), Bool.and(F64.is_le(y0, S.py(p)), F64.is_le(S.py(p), y1))),
    Bool.and(F64.is_le(z0, S.pz(p)), F64.is_le(S.pz(p), z1)))

def fr_code(+s1: S.SF, +s2: S.SF, +h: F64, +p: V.Point, +q0: V.Point, +q: V.Point, +st: V.Point, +cc: Bool, +k: Nat, +tb: BX) -> U64:
  +good = Bool.and(fr_tok(s1, s2, p), F64.is_lt(S.dist(q, q0), F64.mul(0.5f64, h)))
  +cl = Bool.and(cc, Bool.and(Nat.is_le(4n, k), F64.is_lt(S.dist(q, st), F64.mul(0.6f64, h))))
  +inq = Bool.and(Bool.and(fr_in(s1, q), fr_in(s2, q)), bx_in(tb, q))
  Bool.pick(U64, Bool.not(good), 3u64, Bool.pick(U64, cl, 1u64, Bool.pick(U64, inq, 0u64, 2u64)))

def fr_go(n: Nat, +mode: U64, +s1: S.SF, +s2: S.SF, +h: F64, +p: V.Point, +d: V.Dir, +st: V.Point, +cc: Bool,
    +k: Nat, +tb: BX, +acc: List<&2, V.Point>) -> TR:
  match n:
    case 0n: TR{acc, False{}, False{}}
    case 1n+(+m):
      match mode:
        case 9u64:
          +t = fr_dir(s1, s2, p, d)
          +q0 = S.padd(p, h, t)
          +q = S.newton2(8n, s1, s2, q0, t, q0)
          fr_go(m, fr_code(s1, s2, h, p, q0, q, st, cc, k, tb), s1, s2, h, q, t, st, cc, k, tb, acc)
        case 0u64: fr_go(m, 9u64, s1, s2, h, p, d, st, cc, Nat.add(k, 1n), tb, p <> acc)
        case 1u64: TR{acc, True{}, True{}}
        case 2u64: TR{p <> acc, False{}, True{}}
        case _: TR{acc, False{}, False{}}

def tr_closed(+r: TR) -> Bool:
  TR{pts, closed, ok} = r
  closed

def tr_ok(+r: TR) -> Bool:
  TR{pts, closed, ok} = r
  ok

def fr_back(cl: Bool, +f: TR, +s1: S.SF, +s2: S.SF, +h: F64, +p0: V.Point, +t0: V.Dir, +tb: BX) -> TR:
  match cl:
    case True{}: TR{List.reverse(&2, V.Point, tr_pts(f)), True{}, tr_ok(f)}
    case False{}:
      +b = fr_go(1200n, 9u64, s1, s2, h, p0, S.dscale(F64.neg(1.0f64), t0), p0, False{}, 0n, tb, [])
      TR{List.append(&2, V.Point, tr_pts(b), List.reverse(&2, V.Point, tr_pts(f))), False{}, Bool.and(tr_ok(f), tr_ok(b))}

def fr_seed(+s1: S.SF, +s2: S.SF, +h: F64, +p0: V.Point, +tb: BX) -> TR:
  +t0 = S.dunit(fr_tan(s1, s2, p0))
  +f = fr_go(1200n, 9u64, s1, s2, h, p0, t0, p0, True{}, 0n, tb, [p0])
  fr_back(tr_closed(f), f, s1, s2, h, p0, t0, tb)

def fr_cert(ps: List<&2, V.Point>, +s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>, +bx: BX, +acc: List<&2, V.Point>, +ok: Bool) -> PL:
  match ps:
    case []: PL{List.reverse(&2, V.Point, acc), ok}
    case +h <> +t:
      +c = EF.cert_gs(gs, h)
      +need = Bool.and(Bool.and(fr_in(s1, h), fr_in(s2, h)), bx_in(bx, h))
      fr_cert(t, s1, s2, gs, bx, Bool.pick(V.Point, EF.ct_ok(c), EF.ct_p(c), h) <> acc, Bool.and(ok, Bool.or(Bool.not(need), EF.ct_ok(c))))

def fr_add(+tr: TR, +s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>, +bx: BX, +rest: ICS) -> ICS:
  +pl = fr_cert(tr_pts(tr), s1, s2, gs, bx, [], tr_ok(tr))
  +n = List.length(&2, V.Point, pl_pts(pl))
  Bool.pick(ICS, Bool.and(pl_ok(pl), Nat.is_le(3n, n)),
    ICS{IC{ic_poly(), gnone(), tr_closed(tr), pl_pts(pl), 0u64} <> ics_ics(rest), ics_why(rest)},
    ICS{ics_ics(rest), why_cert()})

def fr_one(skip: Bool, +p: V.Point, +s1: S.SF, +s2: S.SF, +h: F64, +gs: List<&2, G.GVal>, +bx: BX, +tb: BX, +seen: List<&2, V.Point>,
    +rest: ICS) -> FS:
  match skip:
    case True{}: FS{rest, seen}
    case False{}:
      +tr = fr_seed(s1, s2, h, p, tb)
      FS{fr_add(tr, s1, s2, gs, bx, rest), List.append(&2, V.Point, tr_pts(tr), seen)}

def fr_all(qs: List<&2, V.Vec2>, +c: FP, +fs: FS) -> ICS:
  match qs:
    case []: fs_ics(fs)
    case +q <> +t:
      FP{+sb, +s1, +s2, +h, +gs, +bx, +vd, +tb} = c
      +p1 = fr_pt(sb, V.v2_x(q), V.v2_y(q), vd)
      +tn = S.dunit(fr_tan(s1, s2, p1))
      +p = S.newton2(10n, s1, s2, p1, tn, p1)
      +on = F64.is_lt(F64.max(F64.abs(S.sf_f(s1, p)), F64.abs(S.sf_f(s2, p))), F64.mul(1.0e-6f64, h))
      +skip = Bool.or(Bool.not(on), fr_near(fs_seen(fs), p, F64.mul(1.5f64, h)))
      fr_all(t, FP{sb, s1, s2, h, gs, bx, vd, tb}, fr_one(skip, p, s1, s2, h, gs, bx, tb, fs_seen(fs), fs_ics(fs)))

def vd_tor() -> V.Vec2:
  V.V2{F64.neg(S.pi()), S.pi()}

def fr_tor(+so: S.SF, +st: S.SF, +gs: List<&2, G.GVal>, +bx: BX) -> ICS:
  fr_all(fr_seeds(st, so, vd_tor()), FP{st, so, st, fr_h(so, st), gs, bx, vd_tor(), bx_all()}, FS{ICS{[], 0u64}, []})

def bx_hr(+b: BX, +o: V.Point, +a: V.Dir) -> V.Vec2:
  BX{+x0, +x1, +y0, +y1, +z0, +z1} = b
  +c = S.dot(S.psub(S.pt(F64.mul(0.5f64, F64.add(x0, x1)), F64.mul(0.5f64, F64.add(y0, y1)), F64.mul(0.5f64, F64.add(z0, z1))), o), a)
  +r = F64.mul(0.5f64, F64.add(F64.mul(F64.abs(S.dx(a)), F64.sub(x1, x0)), F64.add(F64.mul(F64.abs(S.dy(a)), F64.sub(y1, y0)), F64.mul(F64.abs(S.dz(a)), F64.sub(z1, z0)))))
  +e = F64.mul(1.0e-9f64, F64.add(F64.abs(c), r))
  V.V2{F64.sub(F64.sub(c, r), e), F64.add(F64.add(c, r), e)}

def bx_diag(+b: BX) -> F64:
  BX{+x0, +x1, +y0, +y1, +z0, +z1} = b
  S.dist(S.pt(x0, y0, z0), S.pt(x1, y1, z1))

def bx_pad(+b: BX) -> BX:
  BX{+x0, +x1, +y0, +y1, +z0, +z1} = b
  +e = F64.mul(0.02f64, bx_diag(BX{x0, x1, y0, y1, z0, z1}))
  BX{F64.sub(x0, e), F64.add(x1, e), F64.sub(y0, e), F64.add(y1, e), F64.sub(z0, e), F64.add(z1, e)}

def fr_cone(+so: S.SF, +sk: S.SF, +gs: List<&2, G.GVal>, +bx: BX) -> ICS:
  +vd = bx_hr(bx, S.sf_o(sk), S.sf_a(sk))
  +h = F64.min(fr_h(so, sk), F64.div(bx_diag(bx), 40.0f64))
  +fin = Bool.and(F64.is_lt(V.v2_x(vd), V.v2_y(vd)), F64.is_lt(h, F64.div(1.0f64, 0.0f64)))
  Bool.pick(ICS, fin, fr_all(fr_seeds(sk, so, vd), FP{sk, so, sk, h, gs, bx, vd, bx_pad(bx)}, FS{ICS{[], 0u64}, []}), ICS{[], why_kind()})

def pk_ics_go(gen: Bool, +sp: S.SF, +sk: S.SF, +gs: List<&2, G.GVal>, +bx: BX) -> ICS:
  match gen:
    case True{}: fr_cone(sp, sk, gs, bx)
    case False{}: one(pk_go(sp, sk, gs))

def pk_ics(+sp: S.SF, +sk: S.SF, +gs: List<&2, G.GVal>, +bx: BX) -> ICS:
  pk_ics_go(U64.is_eq(pk_code(sp, sk), 5u64), sp, sk, gs, bx)

def tp_sep(+n: V.Dir, +a: V.Dir, +dl: F64, +sp: S.SF, +st: S.SF, +gs: List<&2, G.GVal>, +bx: BX) -> ICS:
  +c = F64.div(S.dot(a, n), F64.mul(S.dlen(a), S.dlen(n)))
  +ext = F64.add(F64.mul(S.sf_r(st), F64.sqrt(F64.max(0.0f64, F64.sub(1.0f64, F64.mul(c, c))))), S.sf_r2(st))
  +d = F64.div(F64.abs(dl), S.dlen(n))
  Bool.pick(ICS, F64.is_lt(F64.add(ext, sep_tol(ext)), d), ICS{[], 0u64}, fr_tor(sp, st, gs, bx))

def tp_go(+sp: S.SF, +st: S.SF, +gs: List<&2, G.GVal>, +bx: BX) -> ICS:
  +n = S.sf_a(sp)
  +a = S.sf_a(st)
  +dl = S.dot(S.psub(S.sf_o(sp), S.sf_o(st)), n)
  +perp = is_zero_d(S.cross(a, n))
  +axial = Bool.and(F64.is_eq(S.dot(a, n), 0.0f64), F64.is_eq(dl, 0.0f64))
  Bool.pick(ICS, perp, tp_perp(st, F64.mul(dl, S.dot(a, n))),
    Bool.pick(ICS, axial, tp_axial(sp, st), tp_sep(n, a, dl, sp, st, gs, bx)))

def tcy_sep(+sc: S.SF, +st: S.SF, +gs: List<&2, G.GVal>, +bx: BX) -> ICS:
  +ac = S.sf_a(sc)
  +at = S.sf_a(st)
  +bigr = S.sf_r(st)
  +r = S.sf_r2(st)
  +rc = S.sf_r(sc)
  +d = ax_dist(S.sf_o(st), S.sf_o(sc), ac)
  +par = F64.is_le(S.dlen(S.cross(ac, at)), F64.mul(1.0e-12f64, F64.mul(S.dlen(ac), S.dlen(at))))
  +out = F64.is_lt(F64.add(F64.add(F64.add(bigr, r), rc), sep_tol(d)), d)
  +hole = Bool.and(par, F64.is_lt(F64.add(F64.add(F64.add(d, r), rc), sep_tol(bigr)), bigr))
  Bool.pick(ICS, Bool.or(out, hole), ICS{[], 0u64}, fr_tor(sc, st, gs, bx))

def tcy_go(+sc: S.SF, +st: S.SF, +gs: List<&2, G.GVal>, +bx: BX) -> ICS:
  +ok = coax(S.sf_o(sc), S.sf_a(sc), S.sf_o(st), S.sf_a(st))
  +o = S.sf_o(st)
  +a = S.sf_a(st)
  +dr = F64.sub(S.sf_r(sc), S.sf_r(st))
  +r = S.sf_r2(st)
  +q = F64.mul(F64.add(r, dr), F64.sub(r, dr))
  +w = F64.sqrt(F64.max(0.0f64, q))
  +rc = S.sf_r(sc)
  Bool.pick(ICS, Bool.not(ok), tcy_sep(sc, st, gs, bx),
    Bool.pick(ICS, F64.is_lt(q, 0.0f64), ICS{[], 0u64},
      Bool.pick(ICS, F64.is_eq(q, 0.0f64), ics_of([tc(o, a, 0.0f64, rc)]),
        ics_of([tc(o, a, w, rc), tc(o, a, F64.neg(w), rc)]))))

def ks_sel(+sk: S.SF, +ss: S.SF, +gs: List<&2, G.GVal>) -> ICS:
  Bool.pick(ICS, is_zero_d(S.cross(S.psub(S.sf_o(ss), S.sf_o(sk)), S.sf_a(sk))), ks_go(sk, ss), cc_skew_go(False{}, sk, ss, gs))

def fr_ssi(+s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>, +bx: BX) -> ICS:
  +b1 = S.is_bp(s1)
  +sb = Bool.pick(S.SF, b1, s1, s2)
  +so = Bool.pick(S.SF, b1, s2, s1)
  fr_all(fr_seeds(sb, so, V.V2{0.0f64, 1.0f64}), FP{sb, s1, s2, fr_h(s1, s2), gs, bx, V.V2{0.0f64, 1.0f64}, bx_all()}, FS{ICS{[], 0u64}, []})

def mp_of(+s: S.SF, +o: V.Point, +a: V.Dir) -> List<&2, MP>:
  +hc = S.dot(S.psub(S.sf_o(s), o), a)
  +k = S.sf_kind(s)
  +r = S.sf_r(s)
  Bool.pick(List<&2, MP>, U64.is_eq(k, S.k_plane()), [MP{False{}, hc, 0.0f64, 0.0f64, 1.0f64, 0.0f64}],
    Bool.pick(List<&2, MP>, U64.is_eq(k, S.k_cyl()), [MP{False{}, 0.0f64, r, 1.0f64, 0.0f64, 0.0f64}],
      Bool.pick(List<&2, MP>, U64.is_eq(k, S.k_cone()), [MP{False{}, hc, 0.0f64, 1.0f64, r, 0.0f64}, MP{False{}, hc, 0.0f64, 1.0f64, F64.neg(r), 0.0f64}],
        Bool.pick(List<&2, MP>, U64.is_eq(k, S.k_sph()), [MP{True{}, hc, 0.0f64, 0.0f64, 0.0f64, r}],
          [MP{True{}, hc, r, 0.0f64, 0.0f64, S.sf_r2(s)}]))))

def rx_add(+x: RX, +y: RX) -> RX:
  RX{+a, +p} = x
  RX{+b, +q} = y
  RX{List.append(&2, V.Vec2, a, b), Bool.or(p, q)}

def mp_ll(+m: MP, +n: MP, +sc: F64) -> RX:
  MP{c1, +p1h, +p1r, +d1h, +d1r, r1} = m
  MP{c2, +p2h, +p2r, +d2h, +d2r, r2} = n
  +det = F64.sub(F64.mul(d1r, d2h), F64.mul(d1h, d2r))
  +ex = F64.sub(p2h, p1h)
  +ey = F64.sub(p2r, p1r)
  +t = F64.div(F64.sub(F64.mul(ey, d2h), F64.mul(ex, d2r)), det)
  +par = F64.is_le(F64.abs(det), F64.mul(1.0e-12f64, F64.add(F64.abs(F64.mul(d1r, d2h)), F64.abs(F64.mul(d1h, d2r)))))
  +off = F64.abs(F64.sub(F64.mul(ex, d1r), F64.mul(ey, d1h)))
  Bool.pick(RX, par, RX{[], F64.is_le(off, F64.mul(1.0e-12f64, sc))}, RX{[V.V2{F64.add(p1h, F64.mul(t, d1h)), F64.add(p1r, F64.mul(t, d1r))}], False{}})

def mp_lc(+m: MP, +n: MP, +sc: F64) -> RX:
  MP{c1, +ph, +pr, +dh, +dr, r1} = m
  MP{c2, +ch, +cr, d2h, d2r, +rr} = n
  +fh = F64.sub(ph, ch)
  +fr = F64.sub(pr, cr)
  +qa = F64.add(F64.mul(dh, dh), F64.mul(dr, dr))
  +qb = F64.mul(2.0f64, F64.add(F64.mul(fh, dh), F64.mul(fr, dr)))
  +qc = F64.sub(F64.add(F64.mul(fh, fh), F64.mul(fr, fr)), F64.mul(rr, rr))
  +disc = F64.sub(F64.mul(qb, qb), F64.mul(4.0f64, F64.mul(qa, qc)))
  +tan = F64.is_le(F64.abs(disc), F64.mul(1.0e-10f64, F64.mul(qb, qb)))
  +sq = F64.sqrt(F64.max(disc, 0.0f64))
  +t1 = F64.div(F64.sub(F64.neg(qb), sq), F64.mul(2.0f64, qa))
  +t2 = F64.div(F64.add(F64.neg(qb), sq), F64.mul(2.0f64, qa))
  Bool.pick(RX, tan, RX{[], True{}}, Bool.pick(RX, F64.is_lt(disc, 0.0f64), RX{[], False{}},
    RX{[V.V2{F64.add(ph, F64.mul(t1, dh)), F64.add(pr, F64.mul(t1, dr))}, V.V2{F64.add(ph, F64.mul(t2, dh)), F64.add(pr, F64.mul(t2, dr))}], False{}}))

def mp_cc(+m: MP, +n: MP, +sc: F64) -> RX:
  MP{c1, +ah, +ar, d1h, d1r, +r1} = m
  MP{c2, +bh, +br, d2h, d2r, +r2} = n
  +dh = F64.sub(bh, ah)
  +dr = F64.sub(br, ar)
  +d = F64.sqrt(F64.add(F64.mul(dh, dh), F64.mul(dr, dr)))
  +far = Bool.or(F64.is_lt(F64.add(r1, r2), d), F64.is_lt(d, F64.abs(F64.sub(r1, r2))))
  +e = F64.mul(1.0e-12f64, sc)
  +tan = Bool.or(F64.is_le(F64.abs(F64.sub(d, F64.add(r1, r2))), e), F64.is_le(F64.abs(F64.sub(d, F64.abs(F64.sub(r1, r2)))), e))
  +l = F64.div(F64.add(F64.sub(F64.mul(r1, r1), F64.mul(r2, r2)), F64.mul(d, d)), F64.mul(2.0f64, d))
  +hh = F64.sqrt(F64.max(F64.sub(F64.mul(r1, r1), F64.mul(l, l)), 0.0f64))
  +mh = F64.add(ah, F64.mul(F64.div(l, d), dh))
  +mr = F64.add(ar, F64.mul(F64.div(l, d), dr))
  +ux = F64.div(F64.neg(dr), d)
  +uy = F64.div(dh, d)
  Bool.pick(RX, tan, RX{[], True{}}, Bool.pick(RX, Bool.or(far, F64.is_le(d, e)), RX{[], F64.is_le(d, e)},
    RX{[V.V2{F64.add(mh, F64.mul(hh, ux)), F64.add(mr, F64.mul(hh, uy))}, V.V2{F64.sub(mh, F64.mul(hh, ux)), F64.sub(mr, F64.mul(hh, uy))}], False{}}))

def mp_c(+m: MP) -> Bool:
  MP{+c, ph, pr, dh, dr, rad} = m
  c

def mp_x1(a: Bool, b: Bool, +m: MP, +n: MP, +sc: F64) -> RX:
  match a:
    case True{}:
      match b:
        case True{}: mp_cc(m, n, sc)
        case False{}: mp_lc(n, m, sc)
    case False{}:
      match b:
        case True{}: mp_lc(m, n, sc)
        case False{}: mp_ll(m, n, sc)

def mp_x(+m: MP, +n: MP, +sc: F64) -> RX:
  mp_x1(mp_c(m), mp_c(n), m, n, sc)

def mp_row(+m: MP, ns: List<&2, MP>, +sc: F64) -> RX:
  match ns:
    case []: RX{[], False{}}
    case +n <> t: rx_add(mp_x(m, n, sc), mp_row(m, t, sc))

def mp_all(ms: List<&2, MP>, +ns: List<&2, MP>, +sc: F64) -> RX:
  match ms:
    case []: RX{[], False{}}
    case +m <> t: rx_add(mp_row(m, ns, sc), mp_all(t, ns, sc))

def rx_circ(hs: List<&2, V.Vec2>, +o: V.Point, +a: V.Dir, +sc: F64) -> List<&2, IC>:
  match hs:
    case []: []
    case +h <> t:
      +rest = rx_circ(t, o, a, sc)
      Bool.pick(List<&2, IC>, F64.is_lt(F64.mul(1.0e-9f64, sc), V.v2_y(h)), tc(o, a, V.v2_x(h), V.v2_y(h)) <> rest, rest)

def rx_ics(+x: RX, +o: V.Point, +a: V.Dir, +sc: F64) -> ICS:
  RX{+hs, +bad} = x
  Bool.pick(ICS, bad, ICS{[], why_tangent()}, ICS{rx_circ(hs, o, a, sc), 0u64})

def rev_sc(+s1: S.SF, +s2: S.SF) -> F64:
  F64.add(1.0f64, F64.add(F64.add(S.dlen(S.psub(S.sf_o(s1), S.sf_o(s2))), F64.abs(S.sf_r(s1))), F64.add(F64.abs(S.sf_r(s2)), F64.add(F64.abs(S.sf_r2(s1)), F64.abs(S.sf_r2(s2))))))

def rev_ok(+st: S.SF, +so: S.SF) -> Bool:
  Bool.pick(Bool, U64.is_eq(S.sf_kind(so), S.k_sph()), is_zero_d(S.cross(S.psub(S.sf_o(so), S.sf_o(st)), S.sf_a(st))),
    coax(S.sf_o(st), S.sf_a(st), S.sf_o(so), S.sf_a(so)))

def rev_go2(ok: Bool, +st: S.SF, +so: S.SF) -> ICS:
  match ok:
    case False{}: ICS{[], why_kind()}
    case True{}:
      +o = S.sf_o(st)
      +a = S.sf_a(st)
      +sc = rev_sc(st, so)
      rx_ics(mp_all(mp_of(st, o, a), mp_of(so, o, a), sc), o, a, sc)

def rev_go(+s1: S.SF, +s2: S.SF) -> ICS:
  +t1 = S.is_tor(s1)
  +st = Bool.pick(S.SF, t1, s1, s2)
  +so = Bool.pick(S.SF, t1, s2, s1)
  rev_go2(Bool.and(S.is_tor(st), rev_ok(st, so)), st, so)

def ssi_disp(+code: U64, +s1: S.SF, +s2: S.SF, +gs: List<&2, G.GVal>, +bx: BX) -> ICS:
  match code:
    case 0u64: one(pp_line(s1, s2))
    case 1u64: pc_lines(pc_go(s1, s2, gs))
    case 2u64: pc_lines(pc_go(s2, s1, gs))
    case 3u64: cc_par(s1, s2)
    case 4u64: cc_skew(s1, s2, gs)
    case 5u64: pk_ics(s1, s2, gs, bx)
    case 6u64: pk_ics(s2, s1, gs, bx)
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
    case 18u64: tp_go(s1, s2, gs, bx)
    case 19u64: tp_go(s2, s1, gs, bx)
    case 20u64: tcy_go(s1, s2, gs, bx)
    case 21u64: tcy_go(s2, s1, gs, bx)
    case 22u64: fr_ssi(s1, s2, gs, bx)
    case 10u64: rev_go(s1, s2)
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

def ssi_code_a(+s1: S.SF, +s2: S.SF) -> U64:
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

def ssi_code(+s1: S.SF, +s2: S.SF) -> U64:
  Bool.pick(U64, Bool.or(S.is_bp(s1), S.is_bp(s2)), 22u64, ssi_code_a(s1, s2))

def ssi_bf(far: Bool, +g1: G.GVal, +g2: G.GVal, +bx: BX) -> ICS:
  match far:
    case True{}: ICS{[], 0u64}
    case False{}:
      +s1 = S.sf_of(g1)
      +s2 = S.sf_of(g2)
      ssi_disp(ssi_code(s1, s2), s1, s2, {[g1, g2] : List<&2, G.GVal>}, bx)

def ssi_b(+g1: G.GVal, +g2: G.GVal, +bx: BX) -> ICS:
  ssi_bf(EF.gg_far(g1, g2), g1, g2, bx)

def ssi(+g1: G.GVal, +g2: G.GVal) -> ICS:
  ssi_b(g1, g2, bx_all())

def fr_seed_first(qs: List<&2, V.Vec2>) -> V.Vec2:
  match qs:
    case []: V.V2{0.5f64, 0.5f64}
    case +h <> t: h
