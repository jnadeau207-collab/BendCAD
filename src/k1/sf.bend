import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G

type SF is Data:
  SF{ kind: U64, o: V.Point, e1: V.Dir, e2: V.Dir, a: V.Dir, r: F64, nx: SF }
  SF_none{}

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

def sf_kind(+s: SF) -> U64:
  match s:
    case SF{kind, o, e1, e2, a, r, nx}: kind
    case SF_none{}: 0u64

def sf_o(+s: SF) -> V.Point:
  match s:
    case SF{kind, o, e1, e2, a, r, nx}: o
    case SF_none{}: pt(0.0f64, 0.0f64, 0.0f64)

def sf_e1(+s: SF) -> V.Dir:
  match s:
    case SF{kind, o, e1, e2, a, r, nx}: e1
    case SF_none{}: dr(1.0f64, 0.0f64, 0.0f64)

def sf_e2(+s: SF) -> V.Dir:
  match s:
    case SF{kind, o, e1, e2, a, r, nx}: e2
    case SF_none{}: dr(0.0f64, 1.0f64, 0.0f64)

def sf_a(+s: SF) -> V.Dir:
  match s:
    case SF{kind, o, e1, e2, a, r, nx}: a
    case SF_none{}: dr(0.0f64, 0.0f64, 1.0f64)

def sf_r(+s: SF) -> F64:
  match s:
    case SF{kind, o, e1, e2, a, r, nx}: r
    case SF_none{}: 0.0f64

def k_none() -> U64:
  0u64

def k_plane() -> U64:
  1u64

def k_cyl() -> U64:
  2u64

def k_cone() -> U64:
  3u64

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

def sf_of(+g: G.GVal) -> SF:
  match g:
    case G.GV_pl{w}:
      G.Pl{+o, +u, +v} = w
      SF{k_plane(), o, u, v, cross(u, v), 0.0f64, SF_none{}}
    case G.GV_cy{w}:
      G.Cy{+o, +a, +r} = w
      +e1 = perp_of(a)
      SF{k_cyl(), o, e1, cross(a, e1), a, r, SF_none{}}
    case G.GV_co{w}:
      G.Co{+o, +a, +k} = w
      +e1 = perp_of(a)
      SF{k_cone(), o, e1, cross(a, e1), a, k, SF_none{}}
    case G.GV_bp{w}:
      G.Bp{+p00, p01, p02, +p03, p10, p11, p12, p13, p20, p21, p22, p23, +p30, p31, p32, p33} = w
      +e1 = dunit(psub(p03, p00))
      +a = dunit(cross(e1, psub(p30, p00)))
      +flat = F64.is_lt(F64.abs(dot(psub(p33, p00), a)), F64.mul(1.0e-12f64, F64.add(1.0f64, dlen(psub(p33, p00)))))
      Bool.pick(SF, flat, SF{k_plane(), p00, e1, cross(a, e1), a, 0.0f64, SF_none{}}, sf_none())
    case _: sf_none()

def sf_ok(+s: SF) -> Bool:
  Bool.not(U64.is_eq(sf_kind(s), k_none()))

def sf_uv(+s: SF, +p: V.Point) -> V.Vec2:
  +d = psub(p, sf_o(s))
  Bool.pick(V.Vec2, U64.is_eq(sf_kind(s), k_plane()), V.V2{dot(d, sf_e1(s)), dot(d, sf_e2(s))},
    V.V2{fatan2(dot(d, sf_e2(s)), dot(d, sf_e1(s))), dot(d, sf_a(s))})

def sf_rad(+s: SF, +v: F64) -> F64:
  Bool.pick(F64, U64.is_eq(sf_kind(s), k_cone()), F64.mul(sf_r(s), v), sf_r(s))

def sf_at(+s: SF, +u: F64, +v: F64) -> V.Point:
  +o = sf_o(s)
  +rr = sf_rad(s, v)
  Bool.pick(V.Point, U64.is_eq(sf_kind(s), k_plane()), padd(padd(o, u, sf_e1(s)), v, sf_e2(s)),
    padd(padd(padd(o, v, sf_a(s)), F64.mul(rr, fcos(u)), sf_e1(s)), F64.mul(rr, fsin(u)), sf_e2(s)))

def sf_grad(+s: SF, +p: V.Point) -> V.Dir:
  +d = psub(p, sf_o(s))
  +h = dot(d, sf_a(s))
  +rad = dadd(d, F64.neg(h), sf_a(s))
  +k = sf_r(s)
  Bool.pick(V.Dir, U64.is_eq(sf_kind(s), k_plane()), sf_a(s),
    Bool.pick(V.Dir, U64.is_eq(sf_kind(s), k_cone()), dscale(2.0f64, dadd(rad, F64.neg(F64.mul(F64.mul(k, k), h)), sf_a(s))),
      dscale(2.0f64, rad)))

def sf_normal(+s: SF, +p: V.Point) -> V.Dir:
  dunit(sf_grad(s, p))

def sf_f(+s: SF, +p: V.Point) -> F64:
  +d = psub(p, sf_o(s))
  +h = dot(d, sf_a(s))
  +rad = dadd(d, F64.neg(h), sf_a(s))
  +rr = Bool.pick(F64, U64.is_eq(sf_kind(s), k_cone()), F64.mul(sf_r(s), h), sf_r(s))
  Bool.pick(F64, U64.is_eq(sf_kind(s), k_plane()), h,
    F64.mul(F64.add(dlen(rad), rr), F64.sub(dlen(rad), rr)))

def sf_tan_u(+s: SF, +u: F64, +v: F64) -> V.Dir:
  +rr = sf_rad(s, v)
  Bool.pick(V.Dir, U64.is_eq(sf_kind(s), k_plane()), sf_e1(s),
    dadd(dscale(F64.neg(F64.mul(rr, fsin(u))), sf_e1(s)), F64.mul(rr, fcos(u)), sf_e2(s)))

def sf_tan_v(+s: SF, +u: F64) -> V.Dir:
  +k = sf_r(s)
  Bool.pick(V.Dir, U64.is_eq(sf_kind(s), k_plane()), sf_e2(s),
    Bool.pick(V.Dir, U64.is_eq(sf_kind(s), k_cone()),
      dadd(dadd(sf_a(s), F64.mul(k, fcos(u)), sf_e1(s)), F64.mul(k, fsin(u)), sf_e2(s)), sf_a(s)))

def sf_periodic(+s: SF) -> Bool:
  Bool.or(U64.is_eq(sf_kind(s), k_cyl()), U64.is_eq(sf_kind(s), k_cone()))

def det3(+a: V.Dir, +b: V.Dir, +c: V.Dir) -> F64:
  dot(a, cross(b, c))

def solve3(+a: V.Dir, +b: V.Dir, +c: V.Dir, +r: V.Dir) -> V.Dir:
  +d = det3(a, b, c)
  +ok = F64.is_lt(1.0e-300f64, F64.abs(d))
  +x = dadd(dadd(dscale(dx(r), cross(b, c)), dy(r), cross(c, a)), dz(r), cross(a, b))
  Bool.pick(V.Dir, ok, dscale(F64.div(1.0f64, d), x), dr(0.0f64, 0.0f64, 0.0f64))

def newton2_step(+s1: SF, +s2: SF, +p: V.Point, +t: V.Dir, +p0: V.Point) -> V.Point:
  +g1 = sf_grad(s1, p)
  +g2 = sf_grad(s2, p)
  +f1 = sf_f(s1, p)
  +f2 = sf_f(s2, p)
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
