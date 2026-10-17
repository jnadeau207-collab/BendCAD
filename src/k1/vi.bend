import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c06/iv.bend as I
import ./sf.bend as S
import ./ef.bend as EF
import ./fb.bend as FB
import ./ls.bend as L

type VA is Data:
  VA{ vol: F64, ar: F64, slv: F64, sla: F64, ok: Bool }

type VR is Data:
  VR{ vol: I.I, ar: I.I, ok: Bool }

def va_vol(+a: VA) -> F64:
  VA{vol, ar, slv, sla, ok} = a
  vol

def va_ar(+a: VA) -> F64:
  VA{vol, ar, slv, sla, ok} = a
  ar

def va_slv(+a: VA) -> F64:
  VA{vol, ar, slv, sla, ok} = a
  slv

def va_sla(+a: VA) -> F64:
  VA{vol, ar, slv, sla, ok} = a
  sla

def va_ok(+a: VA) -> Bool:
  VA{vol, ar, slv, sla, ok} = a
  ok

def va_add(+a: VA, +b: VA) -> VA:
  VA{F64.add(va_vol(a), va_vol(b)), F64.add(va_ar(a), va_ar(b)), F64.add(va_slv(a), va_slv(b)),
    F64.add(va_sla(a), va_sla(b)), Bool.and(va_ok(a), va_ok(b))}

def va0() -> VA:
  VA{0.0f64, 0.0f64, 0.0f64, 0.0f64, True{}}

def va_bad() -> VA:
  VA{0.0f64, 0.0f64, 0.0f64, 0.0f64, False{}}

def ek_tag(+k: Ty.EdgeKind) -> U64:
  match k:
    case Ty.EK_curve{+c, +d}:
      match c:
        case G.GV_ln{w}: 1u64
        case G.GV_cc{w}: 2u64
        case G.GV_rq{w}: 3u64
        case G.GV_bz{w}: 4u64
        case _: 9u64
    case Ty.EK_degenerate{}: 0u64

def rq_of(+g: G.GVal) -> G.RQBez:
  match g:
    case G.GV_rq{w}: w
    case _: G.Rq{S.pt(0.0f64, 0.0f64, 0.0f64), S.pt(0.0f64, 0.0f64, 0.0f64), S.pt(0.0f64, 0.0f64, 0.0f64), 1.0f64, 1.0f64, 1.0f64}

def bz_straight(+g: G.GVal) -> Bool:
  match g:
    case G.GV_bz{w}:
      G.Bz{+p0, +p1, +p2, +p3} = w
      +d = S.psub(p3, p0)
      +e1 = S.dlen(S.cross(d, S.psub(p1, p0)))
      +e2 = S.dlen(S.cross(d, S.psub(p2, p0)))
      +tol = F64.mul(1.0e-12f64, F64.add(1.0f64, S.dot(d, d)))
      Bool.and(F64.is_le(e1, tol), F64.is_le(e2, tol))
    case _: False{}

def arc_center(+p0: V.Point, +cp: V.Point, +p2: V.Point, +w: F64) -> V.Point:
  +m = S.padd(p0, 0.5f64, S.psub(p2, p0))
  +k = F64.div(F64.mul(w, w), F64.sub(1.0f64, F64.mul(w, w)))
  S.padd(m, k, S.psub(m, cp))

def uv_pl(+s: S.SF, +p: V.Point) -> V.Vec2:
  FB.uv_raw(s, p)

def pl_line(+s: S.SF, +a: V.Point, +b: V.Point) -> VA:
  +ua = uv_pl(s, a)
  +ub = uv_pl(s, b)
  +i = F64.mul(F64.mul(0.5f64, F64.add(V.v2_x(ua), V.v2_x(ub))), F64.sub(V.v2_y(ub), V.v2_y(ua)))
  VA{i, i, 0.0f64, 0.0f64, True{}}

def pl_arc(+s: S.SF, +c: V.Point, +a: V.Point, +b: V.Point, +dphi: F64) -> VA:
  +uc = uv_pl(s, c)
  +ua = uv_pl(s, a)
  +ub = uv_pl(s, b)
  +cu = V.v2_x(uc)
  +ax = F64.sub(V.v2_x(ua), cu)
  +ay = F64.sub(V.v2_y(ua), V.v2_y(uc))
  +bx = F64.sub(V.v2_x(ub), cu)
  +by = F64.sub(V.v2_y(ub), V.v2_y(uc))
  +rr = F64.sqrt(F64.add(F64.mul(ax, ax), F64.mul(ay, ay)))
  +p0 = S.fatan2(ay, ax)
  +p1 = F64.add(p0, dphi)
  +i = F64.add(F64.mul(F64.mul(cu, rr), F64.sub(S.fsin(p1), S.fsin(p0))),
    F64.mul(F64.mul(rr, rr), F64.add(F64.mul(0.5f64, dphi), F64.mul(0.25f64, F64.sub(S.fsin(F64.mul(2.0f64, p1)), S.fsin(F64.mul(2.0f64, p0)))))))
  VA{i, i, 0.0f64, 0.0f64, True{}}

def arc_dphi(+s: S.SF, +c: V.Point, +a: V.Point, +b: V.Point, +m: V.Point) -> F64:
  +uc = uv_pl(s, c)
  +ua = uv_pl(s, a)
  +ub = uv_pl(s, b)
  +um = uv_pl(s, m)
  +pa = S.fatan2(F64.sub(V.v2_y(ua), V.v2_y(uc)), F64.sub(V.v2_x(ua), V.v2_x(uc)))
  +pb = S.fatan2(F64.sub(V.v2_y(ub), V.v2_y(uc)), F64.sub(V.v2_x(ub), V.v2_x(uc)))
  +pm = S.fatan2(F64.sub(V.v2_y(um), V.v2_y(uc)), F64.sub(V.v2_x(um), V.v2_x(uc)))
  F64.add(S.ang_diff(pa, pm), S.ang_diff(pm, pb))

def cyl_seg(+s: S.SF, +c: V.Point, +ta: V.Vec2, +tb: V.Vec2) -> VA:
  +r = S.sf_r(s)
  +d = S.psub(S.sf_o(s), c)
  +c1 = S.dot(d, S.sf_e1(s))
  +c2 = S.dot(d, S.sf_e2(s))
  +t0 = V.v2_x(ta)
  +t1 = V.v2_x(tb)
  +h0 = V.v2_y(ta)
  +h1 = V.v2_y(tb)
  +dt = F64.sub(t1, t0)
  +dh = F64.sub(h1, h0)
  +parea = F64.neg(F64.mul(F64.mul(0.5f64, F64.add(h0, h1)), dt))
  +g0 = F64.sub(F64.neg(F64.mul(c1, S.fcos(t0))), F64.mul(c2, S.fsin(t0)))
  +g1 = F64.sub(F64.neg(F64.mul(c1, S.fcos(t1))), F64.mul(c2, S.fsin(t1)))
  +f0 = F64.sub(F64.mul(c1, S.fsin(t0)), F64.mul(c2, S.fcos(t0)))
  +small = F64.is_lt(F64.abs(dt), 1.0e-9f64)
  +f2 = Bool.pick(F64, small, F64.mul(f0, dh), F64.mul(F64.div(dh, dt), F64.sub(g1, g0)))
  +v = F64.add(F64.mul(F64.div(F64.mul(r, r), 3.0f64), parea), F64.mul(F64.div(r, 3.0f64), f2))
  VA{v, F64.mul(r, parea), 0.0f64, 0.0f64, True{}}

def seg_poly_go(ps: List<&2, V.Vec2>, +s: S.SF, +c: V.Point, +prev: V.Vec2, +acc: VA) -> VA:
  match ps:
    case []: acc
    case +h <> +t: seg_poly_go(t, s, c, h, va_add(acc, cyl_seg(s, c, prev, h)))

def cyl_poly(+ps: List<&2, V.Vec2>, +s: S.SF, +c: V.Point) -> VA:
  match ps:
    case []: va0()
    case +h <> +t: seg_poly_go(t, s, c, h, va0())

def cyl_curve(+s: S.SF, +c: V.Point, +k: Ty.EdgeKind, +fw: Bool) -> VA:
  +lo = EF.ek_lo(k)
  +hi = EF.ek_hi(k)
  +a = Bool.pick(F64, fw, lo, hi)
  +b = Bool.pick(F64, fw, hi, lo)
  +p0 = FB.uv_raw(s, EF.ev(EF.ek_curve(k), a))
  cyl_poly(FB.poly_of(s, k, a, b, p0), s, c)

def chord_dev(+s1: S.SF, +s2: S.SF, +a: V.Point, +b: V.Point) -> F64:
  +m = S.padd(a, 0.5f64, S.psub(b, a))
  +t = S.dunit(S.psub(b, a))
  +q = S.newton2(8n, s1, s2, m, t, m)
  S.dist(m, q)

def cc_of(+g: G.GVal) -> G.Circle3:
  match g:
    case G.GV_cc{w}: w
    case _: G.Cc{S.pt(0.0f64, 0.0f64, 0.0f64), S.dr(1.0f64, 0.0f64, 0.0f64), S.dr(0.0f64, 1.0f64, 0.0f64), 1.0f64}

def pl_curve(+s: S.SF, +k: Ty.EdgeKind, +fw: Bool, +pa: V.Point, +pb: V.Point) -> VA:
  +g = EF.ek_curve(k)
  +lo = EF.ek_lo(k)
  +hi = EF.ek_hi(k)
  +m = EF.ev(g, F64.mul(0.5f64, F64.add(lo, hi)))
  +ctr = Bool.pick(V.Point, U64.is_eq(ek_tag(k), 2u64), G.cc_c(cc_of(g)),
    arc_center(G.rq_p0(rq_of(g)), G.rq_p1(rq_of(g)), G.rq_p2(rq_of(g)), G.rq_w1(rq_of(g))))
  +q0 = EF.ev(g, lo)
  +q1 = EF.ev(g, hi)
  +full = Bool.and(U64.is_eq(ek_tag(k), 2u64), F64.is_eq(F64.sub(hi, lo), 2.0f64))
  +q3 = EF.ev(g, F64.add(lo, F64.mul(0.25f64, F64.sub(hi, lo))))
  +q4 = EF.ev(g, F64.add(lo, F64.mul(0.75f64, F64.sub(hi, lo))))
  +dfw = Bool.pick(F64, full,
    F64.add(F64.add(arc_dphi(s, ctr, q0, m, q3), arc_dphi(s, ctr, m, q1, q4)), 0.0f64),
    arc_dphi(s, ctr, q0, q1, m))
  +d = Bool.pick(F64, fw, dfw, F64.neg(dfw))
  pl_arc(s, ctr, pa, pb, d)

def bz_of(+g: G.GVal) -> G.Bez3:
  match g:
    case G.GV_bz{w}: w
    case _: G.Bz{S.pt(0.0f64, 0.0f64, 0.0f64), S.pt(0.0f64, 0.0f64, 0.0f64), S.pt(0.0f64, 0.0f64, 0.0f64), S.pt(0.0f64, 0.0f64, 0.0f64)}

def bern_d(+a: F64, +b: F64, +c: F64, +d: F64, +t: F64) -> F64:
  +s = F64.sub(1.0f64, t)
  F64.mul(3.0f64, F64.add(F64.add(F64.mul(F64.mul(s, s), F64.sub(b, a)), F64.mul(F64.mul(2.0f64, F64.mul(s, t)), F64.sub(c, b))),
    F64.mul(F64.mul(t, t), F64.sub(d, c))))

def bern(+a: F64, +b: F64, +c: F64, +d: F64, +t: F64) -> F64:
  +s = F64.sub(1.0f64, t)
  F64.add(F64.add(F64.mul(F64.mul(s, F64.mul(s, s)), a), F64.mul(F64.mul(3.0f64, F64.mul(s, F64.mul(s, t))), b)),
    F64.add(F64.mul(F64.mul(3.0f64, F64.mul(s, F64.mul(t, t))), c), F64.mul(F64.mul(t, F64.mul(t, t)), d)))

def gl_term(+u0: F64, +u1: F64, +u2: F64, +u3: F64, +v0: F64, +v1: F64, +v2: F64, +v3: F64, +t: F64) -> F64:
  F64.mul(bern(u0, u1, u2, u3, t), bern_d(v0, v1, v2, v3, t))

def gl3(+u0: F64, +u1: F64, +u2: F64, +u3: F64, +v0: F64, +v1: F64, +v2: F64, +v3: F64) -> F64:
  +r = {0.7745966692414834f64 : F64}
  +a = F64.mul(0.5f64, F64.sub(1.0f64, r))
  +b = F64.mul(0.5f64, F64.add(1.0f64, r))
  +w = F64.div(5.0f64, 9.0f64)
  +w2 = F64.div(8.0f64, 9.0f64)
  F64.mul(0.5f64, F64.add(F64.add(F64.mul(w, gl_term(u0, u1, u2, u3, v0, v1, v2, v3, a)),
    F64.mul(w2, gl_term(u0, u1, u2, u3, v0, v1, v2, v3, 0.5f64))), F64.mul(w, gl_term(u0, u1, u2, u3, v0, v1, v2, v3, b))))

def pl_bz(+s: S.SF, +g: G.GVal, +fw: Bool) -> VA:
  +bz = bz_of(g)
  +q0 = uv_pl(s, G.bz_p0(bz))
  +q1 = uv_pl(s, G.bz_p1(bz))
  +q2 = uv_pl(s, G.bz_p2(bz))
  +q3 = uv_pl(s, G.bz_p3(bz))
  +i = gl3(V.v2_x(q0), V.v2_x(q1), V.v2_x(q2), V.v2_x(q3), V.v2_y(q0), V.v2_y(q1), V.v2_y(q2), V.v2_y(q3))
  +si = Bool.pick(F64, fw, i, F64.neg(i))
  VA{si, si, 0.0f64, 0.0f64, True{}}

type GQ is Data:
  GQ{ x: F64, w: F64 }

def gl4() -> List<&2, GQ>:
  [GQ{F64.neg(0.8611363115940526f64), 0.3478548451374538f64}, GQ{F64.neg(0.3399810435848563f64), 0.6521451548625461f64},
    GQ{0.3399810435848563f64, 0.6521451548625461f64}, GQ{0.8611363115940526f64, 0.3478548451374538f64}]

def gl8() -> List<&2, GQ>:
  [GQ{F64.neg(0.9602898564975363f64), 0.1012285362903763f64}, GQ{F64.neg(0.7966664774136267f64), 0.2223810344533745f64},
    GQ{F64.neg(0.5255324099163290f64), 0.3137066458778873f64}, GQ{F64.neg(0.1834346424956498f64), 0.3626837833783620f64},
    GQ{0.1834346424956498f64, 0.3626837833783620f64}, GQ{0.5255324099163290f64, 0.3137066458778873f64},
    GQ{0.7966664774136267f64, 0.2223810344533745f64}, GQ{0.9602898564975363f64, 0.1012285362903763f64}]

def bz_der(+g: G.GVal, +t: F64) -> V.Dir:
  +bz = bz_of(g)
  +p0 = G.bz_p0(bz)
  +p1 = G.bz_p1(bz)
  +p2 = G.bz_p2(bz)
  +p3 = G.bz_p3(bz)
  S.dr(bern_d(S.px(p0), S.px(p1), S.px(p2), S.px(p3), t), bern_d(S.py(p0), S.py(p1), S.py(p2), S.py(p3), t),
    bern_d(S.pz(p0), S.pz(p1), S.pz(p2), S.pz(p3), t))

def cyl_node(+s: S.SF, +c1: F64, +c2: F64, +g: G.GVal, +t: F64) -> VA:
  +r = S.sf_r(s)
  +d = S.psub(EF.ev(g, t), S.sf_o(s))
  +dd = bz_der(g, t)
  +x = S.dot(d, S.sf_e1(s))
  +y = S.dot(d, S.sf_e2(s))
  +h = S.dot(d, S.sf_a(s))
  +xp = S.dot(dd, S.sf_e1(s))
  +yp = S.dot(dd, S.sf_e2(s))
  +hp = S.dot(dd, S.sf_a(s))
  +rho2 = F64.add(F64.mul(x, x), F64.mul(y, y))
  +rho = F64.sqrt(rho2)
  +thp = F64.div(F64.sub(F64.mul(x, yp), F64.mul(y, xp)), rho2)
  +pa = F64.mul(F64.neg(h), thp)
  +f2 = F64.mul(F64.sub(F64.mul(c1, F64.div(y, rho)), F64.mul(c2, F64.div(x, rho))), hp)
  VA{F64.add(F64.mul(F64.div(F64.mul(r, r), 3.0f64), pa), F64.mul(F64.div(r, 3.0f64), f2)), F64.mul(r, pa), 0.0f64, 0.0f64, True{}}

def cyl_q(qs: List<&2, GQ>, +s: S.SF, +c1: F64, +c2: F64, +g: G.GVal, +m: F64, +hw: F64, +acc: VA) -> VA:
  match qs:
    case []: acc
    case +q <> +t:
      GQ{+x, +w} = q
      +v = cyl_node(s, c1, c2, g, F64.add(m, F64.mul(hw, x)))
      +k = F64.mul(w, hw)
      cyl_q(t, s, c1, c2, g, m, hw, va_add(acc, VA{F64.mul(k, va_vol(v)), F64.mul(k, va_ar(v)), 0.0f64, 0.0f64, True{}}))

def cyl_bz(+s: S.SF, +c: V.Point, +k: Ty.EdgeKind, +fw: Bool) -> VA:
  +d = S.psub(S.sf_o(s), c)
  +c1 = S.dot(d, S.sf_e1(s))
  +c2 = S.dot(d, S.sf_e2(s))
  +g = EF.ek_curve(k)
  +lo = EF.ek_lo(k)
  +hi = EF.ek_hi(k)
  +m = F64.mul(0.5f64, F64.add(lo, hi))
  +hw = F64.mul(0.5f64, F64.sub(hi, lo))
  +a8 = cyl_q(gl8(), s, c1, c2, g, m, hw, va0())
  +a4 = cyl_q(gl4(), s, c1, c2, g, m, hw, va0())
  +sg = Bool.pick(F64, fw, 1.0f64, F64.neg(1.0f64))
  VA{F64.mul(sg, va_vol(a8)), F64.mul(sg, va_ar(a8)), F64.abs(F64.sub(va_vol(a8), va_vol(a4))),
    F64.abs(F64.sub(va_ar(a8), va_ar(a4))), True{}}

def coedge_disp(+code: U64, +s: S.SF, +c: V.Point, +k: Ty.EdgeKind, +fw: Bool, +pa: V.Point,
    +pb: V.Point) -> VA:
  match code:
    case 0u64: va_bad()
    case 1u64: pl_line(s, pa, pb)
    case 2u64: pl_curve(s, k, fw, pa, pb)
    case 4u64: pl_bz(s, EF.ek_curve(k), fw)
    case 5u64: cyl_bz(s, c, k, fw)
    case _: cyl_curve(s, c, k, fw)

def coedge_va(+s: S.SF, +c: V.Point, +k: Ty.EdgeKind, +fw: Bool, +pa: V.Point, +pb: V.Point) -> VA:
  +tag = ek_tag(k)
  +isp = U64.is_eq(S.sf_kind(s), S.k_plane())
  +ok = Bool.and(Bool.not(U64.is_eq(tag, 0u64)), Bool.not(U64.is_eq(tag, 9u64)))
  coedge_disp(Bool.pick(U64, Bool.not(ok), 0u64,
    Bool.pick(U64, isp, Bool.pick(U64, U64.is_eq(tag, 1u64), 1u64, Bool.pick(U64, U64.is_eq(tag, 4u64), 4u64, 2u64)),
      Bool.pick(U64, U64.is_eq(tag, 4u64), 5u64, 3u64))),
    s, c, k, fw, pa, pb)

def curve_dev(+s1: S.SF, +s2: S.SF, +g: G.GVal) -> F64:
  +a = EF.ev(g, 0.0f64)
  +b = EF.ev(g, 1.0f64)
  +t = S.dunit(S.psub(b, a))
  +m1 = EF.ev(g, 0.25f64)
  +m2 = EF.ev(g, 0.5f64)
  +m3 = EF.ev(g, 0.75f64)
  F64.max(S.dist(m1, S.newton2(8n, s1, s2, m1, t, m1)),
    F64.max(S.dist(m2, S.newton2(8n, s1, s2, m2, t, m2)), S.dist(m3, S.newton2(8n, s1, s2, m3, t, m3))))

def samp_dev_go(n: Nat, +s: S.SF, +g: G.GVal, +lo: F64, +dt: F64, +k: F64, +best: F64) -> F64:
  match n:
    case 0n: best
    case 1n+m:
      +t0 = F64.add(lo, F64.mul(k, dt))
      +ua = FB.uv_raw(s, EF.ev(g, t0))
      +ub = FB.unwrap(s, ua, FB.uv_raw(s, EF.ev(g, F64.add(t0, dt))))
      +um = FB.unwrap(s, ua, FB.uv_raw(s, EF.ev(g, F64.add(t0, F64.mul(0.5f64, dt)))))
      +sc = S.sf_rad(s, V.v2_y(um))
      +du = F64.mul(sc, F64.sub(V.v2_x(um), F64.mul(0.5f64, F64.add(V.v2_x(ua), V.v2_x(ub)))))
      +dv = F64.sub(V.v2_y(um), F64.mul(0.5f64, F64.add(V.v2_y(ua), V.v2_y(ub))))
      samp_dev_go(m, s, g, lo, dt, F64.add(k, 1.0f64), F64.max(best, F64.sqrt(F64.add(F64.mul(du, du), F64.mul(dv, dv)))))

def samp_dev(+s: S.SF, +k: Ty.EdgeKind) -> F64:
  +lo = EF.ek_lo(k)
  +n = FB.nseg(k)
  +dt = F64.div(F64.sub(EF.ek_hi(k), lo), L.f64_of(n))
  Bool.pick(F64, Bool.or(U64.is_eq(S.sf_kind(s), S.k_plane()), U64.is_eq(S.sf_kind(s), S.k_cyl())), 0.0f64,
    F64.mul(2.0f64, samp_dev_go(n, s, EF.ek_curve(k), lo, dt, 0.0f64, 0.0f64)))

def chord_sl(+b: Ty.Brep, +e: Nat, +s: S.SF, +c: V.Point, +pa: V.Point, +pb: V.Point) -> VA:
  +fs = FB.edge_faces(b, e)
  +s1 = S.sf_of(FB.face_surf(b, L.nth_n(fs, 0n)))
  +s2 = S.sf_of(FB.face_surf(b, L.nth_n(fs, 1n)))
  +k = Ty.ed_kind(FB.edge_at(b, e))
  +g = EF.ek_curve(k)
  +d = F64.add(F64.add(F64.mul(2.0f64, curve_dev(s1, s2, g)), samp_dev(s, k)), 1.0e-12f64)
  +l = F64.mul(1.1f64, S.dist(pa, pb))
  +rm = F64.add(F64.max(S.dist(pa, c), S.dist(pb, c)), d)
  VA{0.0f64, 0.0f64, F64.div(F64.mul(F64.mul(d, l), rm), 3.0f64), F64.mul(d, l), True{}}

def chord_maybe(+isc: Bool, +b: Ty.Brep, +e: Nat, +s: S.SF, +c: V.Point, +pa: V.Point, +pb: V.Point) -> VA:
  match isc:
    case True{}: chord_sl(b, e, s, c, pa, pb)
    case False{}: va0()

def ces_va(cs: List<&2, FB.CE>, +b: Ty.Brep, +s: S.SF, +c: V.Point, +acc: VA) -> VA:
  match cs:
    case []: acc
    case +h <> +t:
      +ed = FB.edge_at(b, FB.ce_e(h))
      +fw = FB.ce_fw(h)
      +p0 = FB.vpt(b, Ty.ed_v0(ed))
      +p1 = FB.vpt(b, Ty.ed_v1(ed))
      +pa = Bool.pick(V.Point, fw, p0, p1)
      +pb = Bool.pick(V.Point, fw, p1, p0)
      +x = coedge_va(s, c, Ty.ed_kind(ed), fw, pa, pb)
      +sl = chord_maybe(U64.is_eq(ek_tag(Ty.ed_kind(ed)), 4u64), b, FB.ce_e(h), s, c, pa, pb)
      ces_va(t, b, s, c, va_add(va_add(acc, x), sl))

def lps_va(ls: List<&2, List<&2, FB.CE>>, +b: Ty.Brep, +s: S.SF, +c: V.Point, +acc: VA) -> VA:
  match ls:
    case []: acc
    case +h <> +t: lps_va(t, b, s, c, ces_va(h, b, s, c, acc))

def face_va_go(+b: Ty.Brep, +fi: Nat, +c: V.Point) -> VA:
  +g = FB.face_surf(b, fi)
  +s = S.sf_of(g)
  +raw = lps_va(FB.face_ce(b, fi), b, s, c, va0())
  +isp = U64.is_eq(S.sf_kind(s), S.k_plane())
  +d = S.dot(S.psub(S.sf_o(s), c), S.sf_a(s))
  +vol = Bool.pick(F64, isp, F64.mul(F64.div(d, 3.0f64), va_vol(raw)), va_vol(raw))
  VA{vol, F64.abs(va_ar(raw)), va_slv(raw), va_sla(raw), Bool.and(va_ok(raw), S.sf_ok(s))}

def pv(+p: V.Point) -> V.Dir:
  S.psub(p, S.pt(0.0f64, 0.0f64, 0.0f64))

def ang_at(+c: V.Point, +u: V.Dir, +w: V.Dir, +p: V.Point) -> F64:
  +d = S.psub(p, c)
  S.fatan2(S.dot(d, w), S.dot(d, u))

def arc_j(+c: V.Point, +a: V.Point, +m: V.Point, +b: V.Point, +q3: V.Point, +q4: V.Point, +full: Bool) -> V.Dir:
  +u = S.dunit(S.psub(a, c))
  +nm = S.dunit(S.cross(S.psub(a, c), S.psub(Bool.pick(V.Point, full, q3, m), c)))
  +w = S.cross(nm, u)
  +fm = ang_at(c, u, w, m)
  +f3 = ang_at(c, u, w, q3)
  +f4 = ang_at(c, u, w, q4)
  +fb = ang_at(c, u, w, b)
  +dphi = Bool.pick(F64, full,
    F64.add(F64.add(S.ang_diff(0.0f64, f3), S.ang_diff(f3, fm)), F64.add(S.ang_diff(fm, f4), S.ang_diff(f4, fb))),
    F64.add(S.ang_diff(0.0f64, fm), S.ang_diff(fm, fb)))
  +rr = S.dist(a, c)
  S.dadd(S.cross(pv(c), S.psub(b, a)), F64.mul(F64.mul(rr, rr), dphi), nm)

def bz_j(+g: G.GVal) -> V.Dir:
  +bz = bz_of(g)
  +p0 = G.bz_p0(bz)
  +p1 = G.bz_p1(bz)
  +p2 = G.bz_p2(bz)
  +p3 = G.bz_p3(bz)
  +x = F64.sub(gl3(S.py(p0), S.py(p1), S.py(p2), S.py(p3), S.pz(p0), S.pz(p1), S.pz(p2), S.pz(p3)),
    gl3(S.pz(p0), S.pz(p1), S.pz(p2), S.pz(p3), S.py(p0), S.py(p1), S.py(p2), S.py(p3)))
  +y = F64.sub(gl3(S.pz(p0), S.pz(p1), S.pz(p2), S.pz(p3), S.px(p0), S.px(p1), S.px(p2), S.px(p3)),
    gl3(S.px(p0), S.px(p1), S.px(p2), S.px(p3), S.pz(p0), S.pz(p1), S.pz(p2), S.pz(p3)))
  +z = F64.sub(gl3(S.px(p0), S.px(p1), S.px(p2), S.px(p3), S.py(p0), S.py(p1), S.py(p2), S.py(p3)),
    gl3(S.py(p0), S.py(p1), S.py(p2), S.py(p3), S.px(p0), S.px(p1), S.px(p2), S.px(p3)))
  S.dr(x, y, z)

def edge_j(+k: Ty.EdgeKind) -> V.Dir:
  +tag = ek_tag(k)
  +g = EF.ek_curve(k)
  +lo = EF.ek_lo(k)
  +hi = EF.ek_hi(k)
  +q0 = EF.ev(g, lo)
  +q1 = EF.ev(g, hi)
  +m = EF.ev(g, F64.mul(0.5f64, F64.add(lo, hi)))
  +q3 = EF.ev(g, F64.add(lo, F64.mul(0.25f64, F64.sub(hi, lo))))
  +q4 = EF.ev(g, F64.add(lo, F64.mul(0.75f64, F64.sub(hi, lo))))
  +ctr = Bool.pick(V.Point, U64.is_eq(tag, 2u64), G.cc_c(cc_of(g)),
    arc_center(G.rq_p0(rq_of(g)), G.rq_p1(rq_of(g)), G.rq_p2(rq_of(g)), G.rq_w1(rq_of(g))))
  +full = Bool.and(U64.is_eq(tag, 2u64), F64.is_eq(F64.sub(hi, lo), 2.0f64))
  Bool.pick(V.Dir, U64.is_eq(tag, 1u64), S.cross(pv(q0), pv(q1)),
    Bool.pick(V.Dir, U64.is_eq(tag, 4u64), bz_j(g), arc_j(ctr, q0, m, q1, q3, q4, full)))

def ces_j(cs: List<&2, FB.CE>, +b: Ty.Brep, +acc: V.Dir) -> V.Dir:
  match cs:
    case []: acc
    case +h <> +t:
      +j = edge_j(Ty.ed_kind(FB.edge_at(b, FB.ce_e(h))))
      ces_j(t, b, S.dadd(acc, Bool.pick(F64, FB.ce_fw(h), 1.0f64, F64.neg(1.0f64)), j))

def lps_j(ls: List<&2, List<&2, FB.CE>>, +b: Ty.Brep, +acc: V.Dir) -> V.Dir:
  match ls:
    case []: acc
    case +h <> +t: lps_j(t, b, ces_j(h, b, acc))

def cone_seg(+kq: F64, +ta: V.Vec2, +tb: V.Vec2) -> F64:
  +h0 = V.v2_y(ta)
  +h1 = V.v2_y(tb)
  +dt = F64.sub(V.v2_x(tb), V.v2_x(ta))
  F64.mul(kq, F64.neg(F64.div(F64.mul(dt, F64.add(F64.add(F64.mul(h0, h0), F64.mul(h0, h1)), F64.mul(h1, h1))), 6.0f64)))

def cone_pg(ps: List<&2, V.Vec2>, +kq: F64, +prev: V.Vec2, +acc: F64) -> F64:
  match ps:
    case []: acc
    case +h <> +t: cone_pg(t, kq, h, F64.add(acc, cone_seg(kq, prev, h)))

def cone_poly(+ps: List<&2, V.Vec2>, +kq: F64) -> F64:
  match ps:
    case []: 0.0f64
    case +h <> +t: cone_pg(t, kq, h, 0.0f64)

def cone_ces(cs: List<&2, FB.CE>, +b: Ty.Brep, +s: S.SF, +c: V.Point, +kq: F64, +acc: VA) -> VA:
  match cs:
    case []: acc
    case +h <> +t:
      +ed = FB.edge_at(b, FB.ce_e(h))
      +fw = FB.ce_fw(h)
      +k = Ty.ed_kind(ed)
      +p0 = FB.vpt(b, Ty.ed_v0(ed))
      +p1 = FB.vpt(b, Ty.ed_v1(ed))
      +pa = Bool.pick(V.Point, fw, p0, p1)
      +pb = Bool.pick(V.Point, fw, p1, p0)
      +lo = EF.ek_lo(k)
      +hi = EF.ek_hi(k)
      +a0 = Bool.pick(F64, fw, lo, hi)
      +b0 = Bool.pick(F64, fw, hi, lo)
      +ar = cone_poly(FB.poly_of(s, k, a0, b0, FB.uv_raw(s, EF.ev(EF.ek_curve(k), a0))), kq)
      +sl = chord_maybe(U64.is_eq(ek_tag(k), 4u64), b, FB.ce_e(h), s, c, pa, pb)
      cone_ces(t, b, s, c, kq, va_add(acc, va_add(VA{0.0f64, ar, 0.0f64, 0.0f64, True{}}, sl)))

def cone_lps(ls: List<&2, List<&2, FB.CE>>, +b: Ty.Brep, +s: S.SF, +c: V.Point, +kq: F64, +acc: VA) -> VA:
  match ls:
    case []: acc
    case +h <> +t: cone_lps(t, b, s, c, kq, cone_ces(h, b, s, c, kq, acc))

def cone_va(+b: Ty.Brep, +fi: Nat, +s: S.SF, +c: V.Point) -> VA:
  +k = S.sf_r(s)
  +kq = F64.mul(k, F64.sqrt(F64.add(1.0f64, F64.mul(k, k))))
  +ls = FB.face_ce(b, fi)
  +j = lps_j(ls, b, S.dr(0.0f64, 0.0f64, 0.0f64))
  +raw = cone_lps(ls, b, s, c, kq, va0())
  +vol = F64.div(S.dot(S.psub(S.sf_o(s), c), j), 6.0f64)
  VA{vol, F64.abs(va_ar(raw)), va_slv(raw), va_sla(raw), va_ok(raw)}

def face_kv(+cone: Bool, +b: Ty.Brep, +fi: Nat, +c: V.Point) -> VA:
  match cone:
    case True{}: cone_va(b, fi, S.sf_of(FB.face_surf(b, fi)), c)
    case False{}: face_va_go(b, fi, c)

def face_va(+b: Ty.Brep, +fi: Nat, +c: V.Point) -> VA:
  face_kv(U64.is_eq(S.sf_kind(S.sf_of(FB.face_surf(b, fi))), S.k_cone()), b, fi, c)

def faces_va(fs: List<&2, Nat>, +b: Ty.Brep, +c: V.Point, +acc: VA) -> VA:
  match fs:
    case []: acc
    case +h <> +t: faces_va(t, b, c, va_add(acc, face_va(b, h, c)))

def vs_box(vs: List<&2, Ty.Vertex>, +lo: V.Point, +hi: V.Point) -> List<&2, V.Point>:
  match vs:
    case []: [lo, hi]
    case +h <> +t:
      +p = Ty.vx_p(h)
      vs_box(t, S.pt(F64.min(S.px(lo), S.px(p)), F64.min(S.py(lo), S.py(p)), F64.min(S.pz(lo), S.pz(p))),
        S.pt(F64.max(S.px(hi), S.px(p)), F64.max(S.py(hi), S.py(p)), F64.max(S.pz(hi), S.pz(p))))

def center_of(+b: Ty.Brep) -> V.Point:
  +p0 = Ty.vx_p(L.nth_v(Ty.brep_vs(b), 0n))
  +bx = vs_box(Ty.brep_vs(b), p0, p0)
  +lo = L.nth_p(bx, 0n)
  +hi = L.nth_p(bx, 1n)
  S.padd(lo, 0.5f64, S.psub(hi, lo))

def vr_vol(+r: VR) -> I.I:
  VR{vol, ar, ok} = r
  vol

def vr_ar(+r: VR) -> I.I:
  VR{vol, ar, ok} = r
  ar

def vr_ok(+r: VR) -> Bool:
  VR{vol, ar, ok} = r
  ok

def widen(+x: F64, +e: F64) -> I.I:
  +m = F64.add(F64.add(e, F64.mul(F64.abs(x), 1.0e-12f64)), 1.0e-12f64)
  I.I{F64.sub(x, m), F64.add(x, m)}

def brep_vol(+b: Ty.Brep) -> VR:
  +c = center_of(b)
  +a = faces_va(L.nat_range(FB.nfaces(b)), b, c, va0())
  VR{widen(va_vol(a), va_slv(a)), widen(va_ar(a), va_sla(a)), va_ok(a)}
