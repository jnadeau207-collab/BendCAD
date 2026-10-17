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

def why_nonaxis() -> U64:
  74u64

def is_zero_d(+d: V.Dir) -> Bool:
  Bool.and(F64.is_eq(S.dx(d), 0.0f64), Bool.and(F64.is_eq(S.dy(d), 0.0f64), F64.is_eq(S.dz(d), 0.0f64)))

def axis_aligned(+d: V.Dir) -> Bool:
  +nz = U64.add(Bool.pick(U64, F64.is_eq(S.dx(d), 0.0f64), 0u64, 1u64),
    U64.add(Bool.pick(U64, F64.is_eq(S.dy(d), 0.0f64), 0u64, 1u64),
      Bool.pick(U64, F64.is_eq(S.dz(d), 0.0f64), 0u64, 1u64)))
  U64.is_eq(nz, 1u64)

def cert_on2(+g1: G.GVal, +g2: G.GVal, +p: V.Point) -> Bool:
  Bool.and(EF.on_g(g1, p), EF.on_g(g2, p))

def nudges() -> List<&2, F64>:
  [0.0f64, 1.0f64, F64.neg(1.0f64), 2.0f64, F64.neg(2.0f64)]

def nz_go(zs: List<&2, F64>, +g1: G.GVal, +g2: G.GVal, +x: F64, +y: F64, +z: F64, +uz: F64)
    -> EF.CT:
  match zs:
    case []: EF.CT{False{}, 0.0f64, S.pt(x, y, z)}
    case +h <> +t:
      +q = S.pt(x, y, F64.add(z, F64.mul(h, uz)))
      Bool.pick(EF.CT, cert_on2(g1, g2, q), EF.CT{True{}, 0.0f64, q}, nz_go(t, g1, g2, x, y, z, uz))

def ny_go(ys: List<&2, F64>, +g1: G.GVal, +g2: G.GVal, +x: F64, +y: F64, +z: F64, +uy: F64,
    +uz: F64) -> EF.CT:
  match ys:
    case []: EF.CT{False{}, 0.0f64, S.pt(x, y, z)}
    case +h <> +t:
      +r = nz_go(nudges(), g1, g2, x, F64.add(y, F64.mul(h, uy)), z, uz)
      Bool.pick(EF.CT, EF.ct_ok(r), r, ny_go(t, g1, g2, x, y, z, uy, uz))

def nx_go(xs: List<&2, F64>, +g1: G.GVal, +g2: G.GVal, +x: F64, +y: F64, +z: F64, +ux: F64,
    +uy: F64, +uz: F64) -> EF.CT:
  match xs:
    case []: EF.CT{False{}, 0.0f64, S.pt(x, y, z)}
    case +h <> +t:
      +r = ny_go(nudges(), g1, g2, F64.add(x, F64.mul(h, ux)), y, z, uy, uz)
      Bool.pick(EF.CT, EF.ct_ok(r), r, nx_go(t, g1, g2, x, y, z, ux, uy, uz))

def cert_pt(+g1: G.GVal, +g2: G.GVal, +p: V.Point) -> EF.CT:
  +x = S.px(p)
  +y = S.py(p)
  +z = S.pz(p)
  nx_go(nudges(), g1, g2, x, y, z, EF.ulp_of(x), EF.ulp_of(y), EF.ulp_of(z))

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
  Bool.pick(IC, Bool.not(ok), refuse_ic(why_nonaxis()),
    Bool.pick(IC, is_zero_d(d), Bool.pick(IC, same, IC{ic_coinc(), gnone(), False{}, [], 0u64}, none_ic()),
      IC{ic_line(), G.GV_ln{G.Ln{p0, d}}, False{}, [], 0u64}))

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

def ell_go(n: Nat, +sp: S.SF, +sc: S.SF, +gp: G.GVal, +gc: G.GVal, +k: F64, +step: F64,
    +acc: List<&2, V.Point>, +ok: Bool) -> IC:
  match n:
    case 0n:
      Bool.pick(IC, ok, IC{ic_poly(), gnone(), True{}, List.reverse(&2, V.Point, acc), 0u64},
        refuse_ic(why_cert()))
    case 1n+m:
      +p = refine2(sp, sc, ell_pt(sp, sc, F64.mul(k, step)))
      +c = cert_pt(gp, gc, p)
      ell_go(m, sp, sc, gp, gc, F64.add(k, 1.0f64), step, EF.ct_p(c) <> acc, Bool.and(ok, EF.ct_ok(c)))

def pc_delta(+sp: S.SF, +sc: S.SF) -> F64:
  S.dot(S.psub(S.sf_o(sc), S.sf_o(sp)), S.sf_a(sp))

def pc_q(+sp: S.SF, +sc: S.SF) -> F64:
  +d = pc_delta(sp, sc)
  F64.sub(F64.mul(S.sf_r(sc), S.sf_r(sc)), F64.mul(d, d))

def pc_code(+sp: S.SF, +sc: S.SF) -> U64:
  +n = S.sf_a(sp)
  +a = S.sf_a(sc)
  +q = pc_q(sp, sc)
  Bool.pick(U64, Bool.not(axis_aligned(n)), 0u64,
    Bool.pick(U64, is_zero_d(S.cross(a, n)), 1u64,
      Bool.pick(U64, F64.is_eq(S.dot(a, n), 0.0f64),
        Bool.pick(U64, F64.is_lt(0.0f64, q), 2u64, Bool.pick(U64, F64.is_eq(q, 0.0f64), 3u64, 4u64)),
        5u64)))

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

def pc_disp(+code: U64, +sp: S.SF, +sc: S.SF, +gp: G.GVal, +gc: G.GVal) -> IC:
  match code:
    case 0u64: refuse_ic(why_nonaxis())
    case 1u64: pc_circle(sp, sc)
    case 2u64: pc_two(sp, sc)
    case 3u64: refuse_ic(why_tangent())
    case 4u64: none_ic()
    case _: ell_go(nloop(), sp, sc, gp, gc, 0.0f64, F64.div(S.two_pi(), L.f64_of(nloop())), [], True{})

def pc_go(+sp: S.SF, +sc: S.SF, +gp: G.GVal, +gc: G.GVal) -> IC:
  pc_disp(pc_code(sp, sc), sp, sc, gp, gc)

def disc(+s1: S.SF, +s2: S.SF, +th: F64) -> F64:
  +p0 = S.sf_at(s1, th, 0.0f64)
  +a1 = S.sf_a(s1)
  +a2 = S.sf_a(s2)
  +d = S.psub(p0, S.sf_o(s2))
  +ca = S.dot(a1, a2)
  +qa = F64.sub(1.0f64, F64.mul(ca, ca))
  +dh = S.dot(d, a2)
  +qb = F64.mul(2.0f64, F64.sub(S.dot(d, a1), F64.mul(dh, ca)))
  +qc = F64.sub(F64.sub(S.dot(d, d), F64.mul(dh, dh)), F64.mul(S.sf_r(s2), S.sf_r(s2)))
  F64.sub(F64.mul(qb, qb), F64.mul(4.0f64, F64.mul(qa, qc)))

def hroot(+s1: S.SF, +s2: S.SF, +th: F64, +plus: Bool) -> F64:
  +p0 = S.sf_at(s1, th, 0.0f64)
  +a1 = S.sf_a(s1)
  +a2 = S.sf_a(s2)
  +d = S.psub(p0, S.sf_o(s2))
  +ca = S.dot(a1, a2)
  +qa = F64.sub(1.0f64, F64.mul(ca, ca))
  +dh = S.dot(d, a2)
  +qb = F64.mul(2.0f64, F64.sub(S.dot(d, a1), F64.mul(dh, ca)))
  +qc = F64.sub(F64.sub(S.dot(d, d), F64.mul(dh, dh)), F64.mul(S.sf_r(s2), S.sf_r(s2)))
  +dd = F64.sqrt(F64.max(0.0f64, F64.sub(F64.mul(qb, qb), F64.mul(4.0f64, F64.mul(qa, qc)))))
  F64.div(F64.add(F64.neg(qb), Bool.pick(F64, plus, dd, F64.neg(dd))), F64.mul(2.0f64, qa))

def ccpt(+s1: S.SF, +s2: S.SF, +g1: G.GVal, +g2: G.GVal, +th: F64, +plus: Bool) -> EF.CT:
  +p = refine2(s1, s2, S.sf_at(s1, th, hroot(s1, s2, th, plus)))
  cert_pt(g1, g2, p)

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

def branch_go(n: Nat, +s1: S.SF, +s2: S.SF, +g1: G.GVal, +g2: G.GVal, +a: F64, +b: F64,
    +k: F64, +nn: F64, +plus: Bool, +acc: List<&2, V.Point>, +ok: Bool) -> PL:
  match n:
    case 0n: PL{acc, ok}
    case 1n+m:
      +th = cheb(a, b, k, nn)
      +c = ccpt(s1, s2, g1, g2, th, plus)
      branch_go(m, s1, s2, g1, g2, a, b, F64.add(k, 1.0f64), nn, plus, EF.ct_p(c) <> acc,
        Bool.and(ok, EF.ct_ok(c)))

def full_go(n: Nat, +s1: S.SF, +s2: S.SF, +g1: G.GVal, +g2: G.GVal, +k: F64, +step: F64,
    +plus: Bool, +acc: List<&2, V.Point>, +ok: Bool) -> PL:
  match n:
    case 0n: PL{List.reverse(&2, V.Point, acc), ok}
    case 1n+m:
      +c = ccpt(s1, s2, g1, g2, F64.mul(k, step), plus)
      full_go(m, s1, s2, g1, g2, F64.add(k, 1.0f64), step, plus, EF.ct_p(c) <> acc,
        Bool.and(ok, EF.ct_ok(c)))

def nbr() -> Nat:
  40n

def loop_of_iv(+s1: S.SF, +s2: S.SF, +g1: G.GVal, +g2: G.GVal, +iv: V.Vec2) -> PL:
  +a = V.v2_x(iv)
  +b = V.v2_y(iv)
  +nn = L.f64_of(nbr())
  +up = branch_go(Nat.add(nbr(), 1n), s1, s2, g1, g2, a, b, 0.0f64, nn, True{}, [], True{})
  +dn = branch_go(Nat.sub(nbr(), 1n), s1, s2, g1, g2, b, a, 1.0f64, nn, False{}, [], True{})
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

def loops_go(ivs: List<&2, V.Vec2>, +s1: S.SF, +s2: S.SF, +g1: G.GVal, +g2: G.GVal) -> ICS:
  match ivs:
    case []: ICS{[], 0u64}
    case +h <> +t:
      +pl = loop_of_iv(s1, s2, g1, g2, h)
      +rest = loops_go(t, s1, s2, g1, g2)
      Bool.pick(ICS, pl_ok(pl),
        ICS{IC{ic_poly(), gnone(), True{}, pl_pts(pl), 0u64} <> ics_ics(rest), ics_why(rest)},
        ICS{ics_ics(rest), why_cert()})

def cc_full(+s1: S.SF, +s2: S.SF, +g1: G.GVal, +g2: G.GVal) -> ICS:
  +n = Nat.mul(nloop(), 2n)
  +step = F64.div(S.two_pi(), L.f64_of(n))
  +p1 = full_go(n, s1, s2, g1, g2, 0.0f64, step, True{}, [], True{})
  +p2 = full_go(n, s1, s2, g1, g2, 0.0f64, step, False{}, [], True{})
  Bool.pick(ICS, Bool.and(pl_ok(p1), pl_ok(p2)),
    ICS{[IC{ic_poly(), gnone(), True{}, pl_pts(p1), 0u64}, IC{ic_poly(), gnone(), True{}, pl_pts(p2), 0u64}], 0u64},
    ICS{[], why_cert()})

def ds_ost(+d: DS) -> F64:
  DS{ivs, allpos, near, ost, open} = d
  ost

def cc_ivs(+s1: S.SF, +s2: S.SF, +g1: G.GVal, +g2: G.GVal, +ds: DS) -> ICS:
  +r = List.reverse(&2, V.Vec2, ds_ivs(ds))
  loops_go(wrap_ivs(r, F64.sub(ds_ost(ds), S.two_pi())), s1, s2, g1, g2)

def cc_disp(+code: U64, +s1: S.SF, +s2: S.SF, +g1: G.GVal, +g2: G.GVal, +ds: DS) -> ICS:
  match code:
    case 0u64: ICS{[], why_tangent()}
    case 1u64: cc_full(s1, s2, g1, g2)
    case _: cc_ivs(s1, s2, g1, g2, ds)

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

def stein_go(n: Nat, +s1: S.SF, +g1: G.GVal, +g2: G.GVal, +o: V.Point, +m: V.Dir, +k: F64, +step: F64,
    +acc: List<&2, V.Point>, +ok: Bool) -> PL:
  match n:
    case 0n: PL{List.reverse(&2, V.Point, acc), ok}
    case 1n+mm:
      +c = cert_pt(g1, g2, stein_pt(s1, o, m, F64.mul(k, step)))
      stein_go(mm, s1, g1, g2, o, m, F64.add(k, 1.0f64), step, EF.ct_p(c) <> acc, Bool.and(ok, EF.ct_ok(c)))

def stein(+s1: S.SF, +s2: S.SF, +g1: G.GVal, +g2: G.GVal) -> ICS:
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
  +l1 = stein_go(Nat.mul(nloop(), 2n), s1, g1, g2, o, m1, 0.0f64, step, [], True{})
  +l2 = stein_go(Nat.mul(nloop(), 2n), s1, g1, g2, o, m2, 0.0f64, step, [], True{})
  +okp = Bool.and(cert_on2(g1, g2, pp), cert_on2(g1, g2, pm))
  Bool.pick(ICS, Bool.and(okp, Bool.and(pl_ok(l1), pl_ok(l2))),
    ICS{[IC{ic_poly(), gnone(), True{}, pl_pts(l1), 0u64}, IC{ic_poly(), gnone(), True{}, pl_pts(l2), 0u64},
      IC{ic_brk(), gnone(), False{}, [pp, pm], 0u64}], 0u64},
    ICS{[], why_cert()})

def cc_skew_go(+st: Bool, +s1: S.SF, +s2: S.SF, +g1: G.GVal, +g2: G.GVal) -> ICS:
  match st:
    case True{}: stein(s1, s2, g1, g2)
    case False{}:
      +ds = disc_scan(s1, s2)
      cc_disp(Bool.pick(U64, ds_near(ds), 0u64, Bool.pick(U64, ds_allpos(ds), 1u64, 2u64)), s1, s2, g1, g2, ds)

def cc_skew(+s1: S.SF, +s2: S.SF, +g1: G.GVal, +g2: G.GVal) -> ICS:
  cc_skew_go(stein_ok(s1, s2), s1, s2, g1, g2)

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
      Bool.pick(ICS, F64.is_eq(y2, 0.0f64), ICS{[], why_tangent()}, ICS{[], 0u64})))

def one(+c: IC) -> ICS:
  Bool.pick(ICS, U64.is_eq(ic_kind(c), ic_refuse()), ICS{[], ic_why(c)},
    Bool.pick(ICS, U64.is_eq(ic_kind(c), ic_none()), ICS{[], 0u64}, ICS{[c], 0u64}))

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

def ssi_disp(+code: U64, +s1: S.SF, +s2: S.SF, +g1: G.GVal, +g2: G.GVal) -> ICS:
  match code:
    case 0u64: one(pp_line(s1, s2))
    case 1u64: pc_lines(pc_go(s1, s2, g1, g2))
    case 2u64: pc_lines(pc_go(s2, s1, g2, g1))
    case 3u64: cc_par(s1, s2)
    case 4u64: cc_skew(s1, s2, g1, g2)
    case _: ICS{[], why_kind()}

def ssi_code(+s1: S.SF, +s2: S.SF) -> U64:
  +k1 = S.sf_kind(s1)
  +k2 = S.sf_kind(s2)
  +pl = S.k_plane()
  +cy = S.k_cyl()
  Bool.pick(U64, Bool.and(U64.is_eq(k1, pl), U64.is_eq(k2, pl)), 0u64,
    Bool.pick(U64, Bool.and(U64.is_eq(k1, pl), U64.is_eq(k2, cy)), 1u64,
      Bool.pick(U64, Bool.and(U64.is_eq(k1, cy), U64.is_eq(k2, pl)), 2u64,
        Bool.pick(U64, Bool.and(U64.is_eq(k1, cy), U64.is_eq(k2, cy)),
          Bool.pick(U64, is_zero_d(S.cross(S.sf_a(s1), S.sf_a(s2))), 3u64, 4u64), 5u64))))

def ssi(+g1: G.GVal, +g2: G.GVal) -> ICS:
  +s1 = S.sf_of(g1)
  +s2 = S.sf_of(g2)
  ssi_disp(ssi_code(s1, s2), s1, s2, g1, g2)
