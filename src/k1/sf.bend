import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G




type SF is Data:
  SF{ kind: U64, o: V.Point, e1: V.Dir, a: V.Dir, r: F64, r2: F64, t0: F64 }
  SF_none{}
  SF_bp{ g: List<&2, G.GVal> }




type FG is Data:
  FG{ f: F64, g: V.Dir }




type BW is Data:
  BW{ a: F64, b: F64, c: F64, d: F64 }

def pt(+x: F64, +y: F64, +z: F64) -> V.Point:
  V.Pt{x, y, z}

def dr(+x: F64, +y: F64, +z: F64) -> V.Dir:
  V.Dr{x, y, z}

def px(+p: V.Point) -> F64:
  V.pt_x(p)

def py(+p: V.Point) -> F64:
  V.pt_y(p)

def pz(+p: V.Point) -> F64:
  V.pt_z(p)

def dx(+d: V.Dir) -> F64:
  V.dr_x(d)

def dy(+d: V.Dir) -> F64:
  V.dr_y(d)

def dz(+d: V.Dir) -> F64:
  V.dr_z(d)

def psub(+a: V.Point, +b: V.Point) -> V.Dir:
  dr(F64.sub(px(a), px(b)), F64.sub(py(a), py(b)), F64.sub(pz(a), pz(b)))

def padd(+p: V.Point, +s: F64, +d: V.Dir) -> V.Point:
  pt(F64.add(px(p), F64.mul(s, dx(d))), F64.add(py(p), F64.mul(s, dy(d))),
    F64.add(pz(p), F64.mul(s, dz(d))))

def dadd(+a: V.Dir, +s: F64, +b: V.Dir) -> V.Dir:
  dr(F64.add(dx(a), F64.mul(s, dx(b))), F64.add(dy(a), F64.mul(s, dy(b))),
    F64.add(dz(a), F64.mul(s, dz(b))))

def dscale(+s: F64, +d: V.Dir) -> V.Dir:
  dr(F64.mul(s, dx(d)), F64.mul(s, dy(d)), F64.mul(s, dz(d)))

def dot(+a: V.Dir, +b: V.Dir) -> F64:
  F64.add(F64.mul(dx(a), dx(b)), F64.add(F64.mul(dy(a), dy(b)), F64.mul(dz(a), dz(b))))

def cross(+a: V.Dir, +b: V.Dir) -> V.Dir:
  dr(F64.sub(F64.mul(dy(a), dz(b)), F64.mul(dz(a), dy(b))),
    F64.sub(F64.mul(dz(a), dx(b)), F64.mul(dx(a), dz(b))),
    F64.sub(F64.mul(dx(a), dy(b)), F64.mul(dy(a), dx(b))))

def dlen(+d: V.Dir) -> F64:
  F64.sqrt(dot(d, d))

def dunit(+d: V.Dir) -> V.Dir:
  +l = dlen(d)
  Bool.pick(V.Dir, F64.is_lt(0.0f64, l), dscale(F64.div(1.0f64, l), d), d)

def dist(+a: V.Point, +b: V.Point) -> F64:
  dlen(psub(a, b))

def pi() -> F64:
  3.141592653589793f64

def two_pi() -> F64:
  6.283185307179586f64

def half_pi() -> F64:
  1.5707963267948966f64

def pio2_hi() -> F64:
  1.5707963267341256f64

def pio2_lo() -> F64:
  6.077100506506192e-11f64

def sin_poly(+x: F64) -> F64:
  +x2 = F64.mul(x, x)
  +q0 = F64.add(F64.neg(7.647163731819816e-13f64), F64.mul(x2, 2.811457254345521e-15f64))
  +q1 = F64.add(1.6059043836821613e-10f64, F64.mul(x2, q0))
  +p = F64.add(F64.neg(2.5052108385441718e-8f64), F64.mul(x2, q1))
  +p1 = F64.add(2.7557319223985893e-6f64, F64.mul(x2, p))
  +p2 = F64.add(F64.neg(1.984126984126984e-4f64), F64.mul(x2, p1))
  +p3 = F64.add(8.333333333333333e-3f64, F64.mul(x2, p2))
  +p4 = F64.add(F64.neg(1.6666666666666666e-1f64), F64.mul(x2, p3))
  F64.add(x, F64.mul(F64.mul(x, x2), p4))

def cos_poly(+x: F64) -> F64:
  +x2 = F64.mul(x, x)
  +q0 = F64.add(4.779477332387385e-14f64, F64.mul(x2, F64.neg(1.5619206968586225e-16f64)))
  +q1 = F64.add(F64.neg(1.1470745597729725e-11f64), F64.mul(x2, q0))
  +p = F64.add(2.08767569878681e-9f64, F64.mul(x2, q1))
  +p1 = F64.add(F64.neg(2.755731922398589e-7f64), F64.mul(x2, p))
  +p2 = F64.add(2.48015873015873e-5f64, F64.mul(x2, p1))
  +p3 = F64.add(F64.neg(1.388888888888889e-3f64), F64.mul(x2, p2))
  +p4 = F64.add(4.1666666666666664e-2f64, F64.mul(x2, p3))
  +p5 = F64.add(F64.neg(0.5f64), F64.mul(x2, p4))
  F64.add(1.0f64, F64.mul(x2, p5))

def rbig() -> F64:
  6755399441055744.0f64

def f_round(+x: F64) -> F64:
  F64.sub(F64.add(x, rbig()), rbig())

def quad_of(+k: F64) -> U64:
  +m = F64.sub(k, F64.mul(4.0f64, f_round(F64.mul(k, 0.25f64))))
  +n = Bool.pick(F64, F64.is_lt(m, 0.0f64), F64.add(m, 4.0f64), m)
  Bool.pick(U64, F64.is_lt(n, 0.5f64), 0u64,
    Bool.pick(U64, F64.is_lt(n, 1.5f64), 1u64,
      Bool.pick(U64, F64.is_lt(n, 2.5f64), 2u64, 3u64)))

def red_of(+x: F64, +k: F64) -> F64:
  F64.sub(F64.sub(x, F64.mul(k, pio2_hi())), F64.mul(k, pio2_lo()))

def sin_q(+q: U64, +r: F64) -> F64:
  Bool.pick(F64, U64.is_eq(q, 0u64), sin_poly(r),
    Bool.pick(F64, U64.is_eq(q, 1u64), cos_poly(r),
      Bool.pick(F64, U64.is_eq(q, 2u64), F64.neg(sin_poly(r)), F64.neg(cos_poly(r)))))

def cos_q(+q: U64, +r: F64) -> F64:
  Bool.pick(F64, U64.is_eq(q, 0u64), cos_poly(r),
    Bool.pick(F64, U64.is_eq(q, 1u64), F64.neg(sin_poly(r)),
      Bool.pick(F64, U64.is_eq(q, 2u64), F64.neg(cos_poly(r)), sin_poly(r))))

def fsin(+x: F64) -> F64:
  +k = f_round(F64.div(x, half_pi()))
  sin_q(quad_of(k), red_of(x, k))

def fcos(+x: F64) -> F64:
  +k = f_round(F64.div(x, half_pi()))
  cos_q(quad_of(k), red_of(x, k))

def atan_ser(+x: F64) -> F64:
  +x2 = F64.mul(x, x)
  +p = F64.add(F64.div(1.0f64, 15.0f64), F64.mul(x2, F64.div(F64.neg(1.0f64), 17.0f64)))
  +p1 = F64.add(F64.div(F64.neg(1.0f64), 13.0f64), F64.mul(x2, p))
  +p2 = F64.add(F64.div(1.0f64, 11.0f64), F64.mul(x2, p1))
  +p3 = F64.add(F64.div(F64.neg(1.0f64), 9.0f64), F64.mul(x2, p2))
  +p4 = F64.add(F64.div(1.0f64, 7.0f64), F64.mul(x2, p3))
  +p5 = F64.add(F64.div(F64.neg(1.0f64), 5.0f64), F64.mul(x2, p4))
  +p6 = F64.add(F64.div(1.0f64, 3.0f64), F64.mul(x2, p5))
  F64.sub(x, F64.mul(F64.mul(x, x2), p6))

def atan_half(+x: F64) -> F64:
  F64.div(x, F64.add(1.0f64, F64.sqrt(F64.add(1.0f64, F64.mul(x, x)))))

def atan1(+x: F64) -> F64:
  F64.mul(8.0f64, atan_ser(atan_half(atan_half(atan_half(x)))))

def fatan2(+y: F64, +x: F64) -> F64:
  +ax = F64.abs(x)
  +ay = F64.abs(y)
  +zero = Bool.and(F64.is_eq(ax, 0.0f64), F64.is_eq(ay, 0.0f64))
  +a0 = Bool.pick(F64, F64.is_le(ay, ax), atan1(F64.div(ay, ax)),
    F64.sub(half_pi(), atan1(F64.div(ax, ay))))
  +a1 = Bool.pick(F64, F64.is_lt(x, 0.0f64), F64.sub(pi(), a0), a0)
  Bool.pick(F64, zero, 0.0f64, Bool.pick(F64, F64.is_lt(y, 0.0f64), F64.neg(a1), a1))

def wrap_to(+t: F64, +lo: F64) -> F64:
  +k = f_round(F64.div(F64.sub(t, F64.add(lo, pi())), two_pi()))
  F64.sub(t, F64.mul(k, two_pi()))

def ang_diff(+a: F64, +b: F64) -> F64:
  wrap_to(F64.sub(b, a), F64.neg(pi()))

def gbp1(+g: G.GVal) -> G.BezP:
  match g:
    case G.GV_bp{w}: w
    case _: G.Bp{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}}

def gbp(gs: List<&2, G.GVal>) -> G.BezP:
  match gs:
    case []: gbp1(G.GV_f{0.0f64})
    case +h <> t: gbp1(h)

def bw(+t: F64) -> BW:
  +s = F64.sub(1.0f64, t)
  BW{F64.mul(F64.mul(s, s), s), F64.mul(3.0f64, F64.mul(F64.mul(s, s), t)), F64.mul(3.0f64, F64.mul(s, F64.mul(t, t))),
    F64.mul(F64.mul(t, t), t)}

def bwd(+t: F64) -> BW:
  +s = F64.sub(1.0f64, t)
  BW{F64.neg(F64.mul(3.0f64, F64.mul(s, s))), F64.mul(3.0f64, F64.sub(F64.mul(s, s), F64.mul(2.0f64, F64.mul(s, t)))),
    F64.mul(3.0f64, F64.sub(F64.mul(2.0f64, F64.mul(s, t)), F64.mul(t, t))), F64.mul(3.0f64, F64.mul(t, t))}

def pv(+p: V.Point) -> V.Dir:
  dr(px(p), py(p), pz(p))

def cmb(+w: BW, +a: V.Dir, +b: V.Dir, +c: V.Dir, +d: V.Dir) -> V.Dir:
  BW{+wa, +wb, +wc, +wd} = w
  dadd(dadd(dadd(dscale(wa, a), wb, b), wc, c), wd, d)

def cmbp(+w: BW, +a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> V.Dir:
  cmb(w, pv(a), pv(b), pv(c), pv(d))

def bp_sum(+w: G.BezP, +wu: BW, +wv: BW) -> V.Dir:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32, +p33} = w
  cmb(wv, cmbp(wu, p00, p01, p02, p03), cmbp(wu, p10, p11, p12, p13), cmbp(wu, p20, p21, p22, p23),
    cmbp(wu, p30, p31, p32, p33))

def bp_c00(+w: G.BezP) -> V.Point:
  G.Bp{+p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23, p30, p31, p32, p33} = w
  p00

def bp_at(+w: G.BezP, +u: F64, +v: F64) -> V.Point:
  +d = bp_sum(w, bw(u), bw(v))
  pt(dx(d), dy(d), dz(d))

def bp_su(+w: G.BezP, +u: F64, +v: F64) -> V.Dir:
  bp_sum(w, bwd(u), bw(v))

def bp_sv(+w: G.BezP, +u: F64, +v: F64) -> V.Dir:
  bp_sum(w, bw(u), bwd(v))

def bp_nrm(+w: G.BezP, +u: F64, +v: F64) -> V.Dir:
  dunit(cross(bp_su(w, u, v), bp_sv(w, u, v)))

def bp_clamp(+x: F64) -> F64:
  F64.max(F64.neg(0.5f64), F64.min(1.5f64, x))

def bp_step(+w: G.BezP, +p: V.Point, +q: V.Vec2) -> V.Vec2:
  +u = V.v2_x(q)
  +v = V.v2_y(q)
  +su = bp_su(w, u, v)
  +sv = bp_sv(w, u, v)
  +r = psub(p, bp_at(w, u, v))
  +a11 = dot(su, su)
  +a12 = dot(su, sv)
  +a22 = dot(sv, sv)
  +b1 = dot(su, r)
  +b2 = dot(sv, r)
  +det = F64.sub(F64.mul(a11, a22), F64.mul(a12, a12))
  +du = F64.div(F64.sub(F64.mul(b1, a22), F64.mul(b2, a12)), det)
  +dv = F64.div(F64.sub(F64.mul(b2, a11), F64.mul(b1, a12)), det)
  Bool.pick(V.Vec2, F64.is_lt(1.0e-300f64, F64.abs(det)), V.V2{bp_clamp(F64.add(u, du)), bp_clamp(F64.add(v, dv))}, q)

def bp_small(+a: V.Vec2, +b: V.Vec2) -> Bool:
  Bool.and(F64.is_le(F64.abs(F64.sub(V.v2_x(a), V.v2_x(b))), 1.0e-15f64), F64.is_le(F64.abs(F64.sub(V.v2_y(a), V.v2_y(b))), 1.0e-15f64))

def bp_nw(n: Nat, done: Bool, +w: G.BezP, +p: V.Point, +q: V.Vec2, +prev: V.Vec2) -> V.Vec2:
  match n:
    case 0n: q
    case 1n+(+m):
      match done:
        case True{}: q
        case False{}: bp_nw(m, bp_small(q, prev), w, p, bp_step(w, p, q), q)

def bp_newton(n: Nat, +w: G.BezP, +p: V.Point, +q: V.Vec2) -> V.Vec2:
  match n:
    case 0n: q
    case 1n+m: bp_nw(m, False{}, w, p, bp_step(w, p, q), q)

def bp_grid() -> List<&2, F64>:
  [0.0f64, 0.25f64, 0.5f64, 0.75f64, 1.0f64]

def seed_v(vs: List<&2, F64>, +w: G.BezP, +p: V.Point, +u: F64, +best: V.Vec2, +bd: F64) -> V.Vec2:
  match vs:
    case []: best
    case +h <> +t:
      +d = dist(p, bp_at(w, u, h))
      +b = F64.is_lt(d, bd)
      seed_v(t, w, p, u, Bool.pick(V.Vec2, b, V.V2{u, h}, best), Bool.pick(F64, b, d, bd))

def seed_d(vs: List<&2, F64>, +w: G.BezP, +p: V.Point, +u: F64, +bd: F64) -> F64:
  match vs:
    case []: bd
    case +h <> +t: seed_d(t, w, p, u, F64.min(bd, dist(p, bp_at(w, u, h))))

def seed_u(us: List<&2, F64>, +w: G.BezP, +p: V.Point, +best: V.Vec2, +bd: F64) -> V.Vec2:
  match us:
    case []: best
    case +h <> +t:
      +b = seed_v(bp_grid(), w, p, h, best, bd)
      seed_u(t, w, p, b, seed_d(bp_grid(), w, p, h, bd))

def bp_uv(+w: G.BezP, +p: V.Point) -> V.Vec2:
  bp_newton(24n, w, p, seed_u(bp_grid(), w, p, V.V2{0.5f64, 0.5f64}, F64.div(1.0f64, 0.0f64)))

def bp_f(+w: G.BezP, +p: V.Point) -> F64:
  +q = bp_uv(w, p)
  dot(psub(p, bp_at(w, V.v2_x(q), V.v2_y(q))), bp_nrm(w, V.v2_x(q), V.v2_y(q)))

def bp_grad(+w: G.BezP, +p: V.Point) -> V.Dir:
  +q = bp_uv(w, p)
  bp_nrm(w, V.v2_x(q), V.v2_y(q))

def sf_kind(+s: SF) -> U64:
  match s:
    case SF{kind, o, e1, a, r, r2, t0}: kind
    case SF_none{}: 0u64
    case SF_bp{gw}: 6u64

def sf_o(+s: SF) -> V.Point:
  match s:
    case SF{kind, o, e1, a, r, r2, t0}: o
    case SF_none{}: pt(0.0f64, 0.0f64, 0.0f64)
    case SF_bp{gw}: bp_c00(gbp(gw))

def sf_e1(+s: SF) -> V.Dir:
  match s:
    case SF{kind, o, e1, a, r, r2, t0}: e1
    case SF_none{}: dr(1.0f64, 0.0f64, 0.0f64)
    case SF_bp{gw}: dunit(bp_su(gbp(gw), 0.5f64, 0.5f64))

def sf_e2(+s: SF) -> V.Dir:
  match s:
    case SF{kind, o, e1, a, r, r2, t0}: cross(a, e1)
    case SF_none{}: dr(0.0f64, 1.0f64, 0.0f64)
    case SF_bp{gw}: dunit(bp_sv(gbp(gw), 0.5f64, 0.5f64))

def sf_a(+s: SF) -> V.Dir:
  match s:
    case SF{kind, o, e1, a, r, r2, t0}: a
    case SF_none{}: dr(0.0f64, 0.0f64, 1.0f64)
    case SF_bp{gw}: bp_nrm(gbp(gw), 0.5f64, 0.5f64)

def sf_r(+s: SF) -> F64:
  match s:
    case SF{kind, o, e1, a, r, r2, t0}: r
    case SF_none{}: 0.0f64
    case SF_bp{gw}: 0.0f64

def sf_r2(+s: SF) -> F64:
  match s:
    case SF{kind, o, e1, a, r, r2, t0}: r2
    case SF_none{}: 0.0f64
    case SF_bp{gw}: 0.0f64

def sf_t0(+s: SF) -> F64:
  match s:
    case SF{kind, o, e1, a, r, r2, t0}: t0
    case SF_none{}: 0.0f64
    case SF_bp{gw}: 0.0f64

def k_bp() -> U64:
  6u64

def is_bp(+s: SF) -> Bool:
  U64.is_eq(sf_kind(s), k_bp())

def k_none() -> U64:
  0u64

def k_plane() -> U64:
  1u64

def k_cyl() -> U64:
  2u64

def k_cone() -> U64:
  3u64

def k_sph() -> U64:
  4u64

def is_sph(+s: SF) -> Bool:
  U64.is_eq(sf_kind(s), k_sph())

def k_tor() -> U64:
  5u64

def is_tor(+s: SF) -> Bool:
  U64.is_eq(sf_kind(s), k_tor())

def sf_none() -> SF:
  SF_none{}

def perp_of(+a: V.Dir) -> V.Dir:
  +ax = F64.abs(dx(a))
  +ay = F64.abs(dy(a))
  +az = F64.abs(dz(a))
  +t = Bool.pick(V.Dir, Bool.and(F64.is_le(ax, ay), F64.is_le(ax, az)), dr(1.0f64, 0.0f64, 0.0f64),
    Bool.pick(V.Dir, F64.is_le(ay, az), dr(0.0f64, 1.0f64, 0.0f64), dr(0.0f64, 0.0f64, 1.0f64)))
  +exact = Bool.or(Bool.and(F64.is_eq(dx(a), 0.0f64), F64.is_eq(dy(a), 0.0f64)),
    Bool.or(Bool.and(F64.is_eq(dy(a), 0.0f64), F64.is_eq(dz(a), 0.0f64)),
      Bool.and(F64.is_eq(dx(a), 0.0f64), F64.is_eq(dz(a), 0.0f64))))
  +ex = Bool.pick(V.Dir, F64.is_eq(F64.abs(dz(a)), 1.0f64), dr(1.0f64, 0.0f64, 0.0f64),
    Bool.pick(V.Dir, F64.is_eq(F64.abs(dx(a)), 1.0f64), dr(0.0f64, 1.0f64, 0.0f64),
      dr(0.0f64, 0.0f64, 1.0f64)))
  Bool.pick(V.Dir, exact, ex, dunit(cross(a, t)))

def off_max(ps: List<&2, V.Point>, +o: V.Point, +n: V.Dir, +acc: F64) -> F64:
  match ps:
    case []: acc
    case +h <> +t: off_max(t, o, n, F64.max(acc, F64.abs(dot(psub(h, o), n))))

def sf_of(+g: G.GVal) -> SF:
  match g:
    case G.GV_pl{w}:
      G.Pl{+o, +u, +v} = w
      SF{k_plane(), o, u, cross(u, v), 0.0f64, 0.0f64, 0.0f64}
    case G.GV_cy{w}:
      G.Cy{+o, +a, +r} = w
      +e1 = perp_of(a)
      SF{k_cyl(), o, e1, a, r, 0.0f64, 0.0f64}
    case G.GV_co{w}:
      G.Co{+o, +a, +k} = w
      +e1 = perp_of(a)
      SF{k_cone(), o, e1, a, k, 0.0f64, 0.0f64}
    case G.GV_to{w}:
      G.To{+o, +a, +bigr, +r} = w
      +e1 = perp_of(a)
      SF{k_tor(), o, e1, a, bigr, r, 0.0f64}
    case G.GV_sp{w}:
      G.Sp{+c, +r} = w
      SF{k_sph(), c, dr(1.0f64, 0.0f64, 0.0f64), dr(0.0f64, 0.0f64, 1.0f64), r, 0.0f64, 0.0f64}
    case G.GV_bp{w}:
      G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32, +p33} = w
      +e1 = dunit(psub(p03, p00))
      +a = dunit(cross(e1, psub(p30, p00)))
      +flat = F64.is_lt(off_max([p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23, p30, p31, p32, p33], p00, a, 0.0f64),
        F64.mul(1.0e-12f64, F64.add(1.0f64, dlen(psub(p33, p00)))))
      Bool.pick(SF, flat, SF{k_plane(), p00, e1, a, 0.0f64, 0.0f64, 0.0f64}, SF_bp{[G.GV_bp{G.Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23, p30, p31, p32, p33}}]})
    case _: sf_none()

def sf_ok(+s: SF) -> Bool:
  Bool.not(U64.is_eq(sf_kind(s), k_none()))

def tor_v(+s: SF, +d: V.Dir) -> F64:
  +h = dot(d, sf_a(s))
  +rho = dlen(dadd(d, F64.neg(h), sf_a(s)))
  wrap_to(F64.sub(fatan2(h, F64.sub(rho, sf_r(s))), sf_t0(s)), F64.neg(pi()))

def sf_uv_a(+s: SF, +p: V.Point) -> V.Vec2:
  +d = psub(p, sf_o(s))
  Bool.pick(V.Vec2, U64.is_eq(sf_kind(s), k_plane()), V.V2{dot(d, sf_e1(s)), dot(d, sf_e2(s))},
    V.V2{fatan2(dot(d, sf_e2(s)), dot(d, sf_e1(s))), Bool.pick(F64, is_tor(s), tor_v(s, d), dot(d, sf_a(s)))})

def sf_uv(+s: SF, +p: V.Point) -> V.Vec2:
  match s:
    case SF_bp{gw}: bp_uv(gbp(gw), p)
    case _: sf_uv_a(s, p)

def sph_rad(+r: F64, +v: F64) -> F64:
  F64.sqrt(F64.max(0.0f64, F64.mul(F64.add(r, v), F64.sub(r, v))))

def sf_rad(+s: SF, +v: F64) -> F64:
  Bool.pick(F64, U64.is_eq(sf_kind(s), k_cone()), F64.mul(sf_r(s), v),
    Bool.pick(F64, is_sph(s), sph_rad(sf_r(s), v),
      Bool.pick(F64, is_tor(s), F64.add(sf_r(s), F64.mul(sf_r2(s), fcos(F64.add(v, sf_t0(s))))), sf_r(s))))

def sf_h(+s: SF, +v: F64) -> F64:
  Bool.pick(F64, is_tor(s), F64.mul(sf_r2(s), fsin(F64.add(v, sf_t0(s)))), v)

def sf_at_a(+s: SF, +u: F64, +v: F64) -> V.Point:
  +o = sf_o(s)
  +rr = sf_rad(s, v)
  Bool.pick(V.Point, U64.is_eq(sf_kind(s), k_plane()), padd(padd(o, u, sf_e1(s)), v, sf_e2(s)),
    padd(padd(padd(o, sf_h(s, v), sf_a(s)), F64.mul(rr, fcos(u)), sf_e1(s)), F64.mul(rr, fsin(u)), sf_e2(s)))

def sf_at(+s: SF, +u: F64, +v: F64) -> V.Point:
  match s:
    case SF_bp{gw}: bp_at(gbp(gw), u, v)
    case _: sf_at_a(s, u, v)

def sf_grad_a(+s: SF, +p: V.Point) -> V.Dir:
  +d = psub(p, sf_o(s))
  +h = dot(d, sf_a(s))
  +rad = dadd(d, F64.neg(h), sf_a(s))
  +k = sf_r(s)
  +q = F64.sub(F64.add(dot(d, d), F64.mul(k, k)), F64.mul(sf_r2(s), sf_r2(s)))
  +tg = dadd(dscale(F64.mul(4.0f64, q), d), F64.neg(F64.mul(8.0f64, F64.mul(k, k))), rad)
  Bool.pick(V.Dir, U64.is_eq(sf_kind(s), k_plane()), sf_a(s),
    Bool.pick(V.Dir, U64.is_eq(sf_kind(s), k_cone()), dscale(2.0f64, dadd(rad, F64.neg(F64.mul(F64.mul(k, k), h)), sf_a(s))),
      Bool.pick(V.Dir, is_tor(s), tg, dscale(2.0f64, Bool.pick(V.Dir, is_sph(s), d, rad)))))

def sf_grad(+s: SF, +p: V.Point) -> V.Dir:
  match s:
    case SF_bp{gw}: bp_grad(gbp(gw), p)
    case _: sf_grad_a(s, p)

def sf_normal(+s: SF, +p: V.Point) -> V.Dir:
  dunit(sf_grad(s, p))

def sf_f_a(+s: SF, +p: V.Point) -> F64:
  +d = psub(p, sf_o(s))
  +h = dot(d, sf_a(s))
  +rad = dadd(d, F64.neg(h), sf_a(s))
  +rr = Bool.pick(F64, U64.is_eq(sf_kind(s), k_cone()), F64.mul(sf_r(s), h), sf_r(s))
  +m = Bool.pick(F64, is_sph(s), dlen(d), dlen(rad))
  +bigr = sf_r(s)
  +q = F64.sub(F64.add(dot(d, d), F64.mul(bigr, bigr)), F64.mul(sf_r2(s), sf_r2(s)))
  +ft = F64.sub(F64.mul(q, q), F64.mul(F64.mul(4.0f64, F64.mul(bigr, bigr)), dot(rad, rad)))
  Bool.pick(F64, U64.is_eq(sf_kind(s), k_plane()), h,
    Bool.pick(F64, is_tor(s), ft, F64.mul(F64.add(m, rr), F64.sub(m, rr))))

def sf_f(+s: SF, +p: V.Point) -> F64:
  match s:
    case SF_bp{gw}: bp_f(gbp(gw), p)
    case _: sf_f_a(s, p)

def sf_tan_u_a(+s: SF, +u: F64, +v: F64) -> V.Dir:
  +rr = sf_rad(s, v)
  Bool.pick(V.Dir, U64.is_eq(sf_kind(s), k_plane()), sf_e1(s),
    dadd(dscale(F64.neg(F64.mul(rr, fsin(u))), sf_e1(s)), F64.mul(rr, fcos(u)), sf_e2(s)))

def sf_tan_u(+s: SF, +u: F64, +v: F64) -> V.Dir:
  match s:
    case SF_bp{gw}: bp_su(gbp(gw), u, v)
    case _: sf_tan_u_a(s, u, v)

def sf_tan_v_a(+s: SF, +u: F64) -> V.Dir:
  +k = sf_r(s)
  Bool.pick(V.Dir, U64.is_eq(sf_kind(s), k_plane()), sf_e2(s),
    Bool.pick(V.Dir, U64.is_eq(sf_kind(s), k_cone()),
      dadd(dadd(sf_a(s), F64.mul(k, fcos(u)), sf_e1(s)), F64.mul(k, fsin(u)), sf_e2(s)), sf_a(s)))

def sf_tan_v(+s: SF, +u: F64) -> V.Dir:
  match s:
    case SF_bp{gw}: bp_sv(gbp(gw), u, 0.5f64)
    case _: sf_tan_v_a(s, u)

def sf_periodic(+s: SF) -> Bool:
  Bool.or(Bool.or(U64.is_eq(sf_kind(s), k_cyl()), U64.is_eq(sf_kind(s), k_cone())), Bool.or(is_sph(s), is_tor(s)))

def det3(+a: V.Dir, +b: V.Dir, +c: V.Dir) -> F64:
  dot(a, cross(b, c))

def solve3(+a: V.Dir, +b: V.Dir, +c: V.Dir, +r: V.Dir) -> V.Dir:
  +d = det3(a, b, c)
  +ok = F64.is_lt(1.0e-300f64, F64.abs(d))
  +x = dadd(dadd(dscale(dx(r), cross(b, c)), dy(r), cross(c, a)), dz(r), cross(a, b))
  Bool.pick(V.Dir, ok, dscale(F64.div(1.0f64, d), x), dr(0.0f64, 0.0f64, 0.0f64))

def fg_f(+r: FG) -> F64:
  FG{+f, g} = r
  f

def fg_g(+r: FG) -> V.Dir:
  FG{f, +g} = r
  g

def bp_fg(+w: G.BezP, +p: V.Point) -> FG:
  +q = bp_uv(w, p)
  +n = bp_nrm(w, V.v2_x(q), V.v2_y(q))
  FG{dot(psub(p, bp_at(w, V.v2_x(q), V.v2_y(q))), n), n}

def sf_fg(+s: SF, +p: V.Point) -> FG:
  match s:
    case SF_bp{gw}: bp_fg(gbp(gw), p)
    case _: FG{sf_f_a(s, p), sf_grad_a(s, p)}

def newton2_step(+s1: SF, +s2: SF, +p: V.Point, +t: V.Dir, +p0: V.Point) -> V.Point:
  +r1 = sf_fg(s1, p)
  +r2 = sf_fg(s2, p)
  +g1 = fg_g(r1)
  +g2 = fg_g(r2)
  +f1 = fg_f(r1)
  +f2 = fg_f(r2)
  +f3 = dot(psub(p, p0), t)
  +rows = solve3(g1, g2, t, dr(f1, f2, f3))
  pt(F64.sub(px(p), dx(rows)), F64.sub(py(p), dy(rows)), F64.sub(pz(p), dz(rows)))

def newton2(n: Nat, +s1: SF, +s2: SF, +p: V.Point, +t: V.Dir, +p0: V.Point) -> V.Point:
  match n:
    case 0n: p
    case 1n+m: newton2(m, s1, s2, newton2_step(s1, s2, p, t, p0), t, p0)

def newton3_step(+s1: SF, +s2: SF, +s3: SF, +p: V.Point) -> V.Point:
  +rows = solve3(sf_grad(s1, p), sf_grad(s2, p), sf_grad(s3, p),
    dr(sf_f(s1, p), sf_f(s2, p), sf_f(s3, p)))
  pt(F64.sub(px(p), dx(rows)), F64.sub(py(p), dy(rows)), F64.sub(pz(p), dz(rows)))

def newton3(n: Nat, +s1: SF, +s2: SF, +s3: SF, +p: V.Point) -> V.Point:
  match n:
    case 0n: p
    case 1n+m: newton3(m, s1, s2, s3, newton3_step(s1, s2, s3, p))

def bp_grid5() -> List<&2, F64>:
  [0.0f64, 0.25f64, 0.5f64, 0.75f64, 1.0f64]

def seed5_u(us: List<&2, F64>, +w: G.BezP, +p: V.Point, +best: V.Vec2, +bd: F64) -> V.Vec2:
  match us:
    case []: best
    case +h <> +t:
      +b = seed_v(bp_grid5(), w, p, h, best, bd)
      seed5_u(t, w, p, b, seed_d(bp_grid5(), w, p, h, bd))

def bp_uv_fine(+w: G.BezP, +p: V.Point) -> V.Vec2:
  bp_newton(40n, w, p, seed5_u(bp_grid5(), w, p, V.V2{0.5f64, 0.5f64}, F64.div(1.0f64, 0.0f64)))
