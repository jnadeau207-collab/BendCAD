# C03 curve/surface/trim types: parameter domains, implicit + parametric
# geometry, trimming curves in surface parameter space, NURBS data.
# Data + total predicates + validated constructors + one result type.
# Evaluators: ops.bend. Contract: docs/c03-contract.md.
# Failure arms reuse C00 FailKind (T.FailKind); no new taxonomy.

import Base
import ../c00/types.bend as T
import ../c01/types.bend as V

# --- Parameter domain: a finite open interval lo < hi. Periodic curves
# wrap it (Pdom); clamped curves reject outside parameters. ---
type Dom is Data:
  Dom{ lo: F64, hi: F64 }

# Periodic wrapper: the same interval with seam identification
# (wrap maps hi back to lo). The seam point is an honest geometric
# point, never a guessed branch (contract §6).
type Pdom is Data:
  Pdom{ d: Dom, periodic: Bool }

# --- Lines: point + free direction. The direction must be nonzero;
# unit-ness is NOT required (projectors divide by d.d). ---
type Line3 is Data:
  Ln{ p: V.Point, d: V.Dir }

# --- Planes in frame form: origin + in-plane basis (u, v). The normal
# is u x v. Semantic validation (orthonormality) is ops.bend's
# plane_checked; mk_plane gates finiteness only. ---
type Plane3 is Data:
  Pl{ o: V.Point, u: V.Dir, v: V.Dir }

# --- Circles in frame form with the RATIONAL full-turn parameter
# (tangent-quarter-angle): with D = (1+t^2)^2,
# C(t) = c + r*(nx*u + ny*v),
# nx = (1-6t^2+t^4)/D, ny = 4t(1-t^2)/D, t in [-1, 1].
# t = 0 is c+r*u; t -> +-1 closes the full turn at the single seam
# point c-r*u (up to signed zero: ny is +0.0/-0.0 at +1/-1).
# No transcendental evaluation anywhere. Frame orthonormality is
# ops.bend's circ_checked.
type Circle3 is Data:
  Cc{ c: V.Point, u: V.Dir, v: V.Dir, r: F64 }

# --- Cubic Bezier curve: four finite control points, t in [0, 1]. ---
type Bez3 is Data:
  Bz{ p0: V.Point, p1: V.Point, p2: V.Point, p3: V.Point }

# --- Rational quadratic Bezier = conic arc: three points + three
# strictly positive finite weights. The supporting conic's class is
# sign(w1^2 - w0*w2): ellipse / parabola / hyperbola branch. The
# rational quarter circle is weights (1, sqrt2/2, 1). ---
type RQBez is Data:
  Rq{ p0: V.Point, p1: V.Point, p2: V.Point, w0: F64, w1: F64,
    w2: F64 }

# --- Bicubic tensor-product Bezier patch: 4x4 controls, (u, v) in
# [0, 1]^2. Iso-curves are cubic Beziers (ops.bend). ---
type BezP is Data:
  Bp{ p00: V.Point, p01: V.Point, p02: V.Point, p03: V.Point,
    p10: V.Point, p11: V.Point, p12: V.Point, p13: V.Point,
    p20: V.Point, p21: V.Point, p22: V.Point, p23: V.Point,
    p30: V.Point, p31: V.Point, p32: V.Point, p33: V.Point }

# --- Quadrics in implicit + frame form. Axes must be UNIT (ops.bend's
# *_checked enforce |norm-1| <= 1e-12); value/gradient formulas assume
# it by contract. Cone slope k = radial per unit axial (no angle, no
# trig); the implicit equation is the double cone, one nappe is the
# ax >= 0 side condition (cone_ax). ---
type Sphere is Data:
  Sp{ c: V.Point, r: F64 }

type Cyl is Data:
  Cy{ o: V.Point, a: V.Dir, r: F64 }

type Cone is Data:
  Co{ o: V.Point, a: V.Dir, k: F64 }

type Torus is Data:
  To{ o: V.Point, a: V.Dir, R: F64, r: F64 }

# --- Axis-aligned enclosure: two finite corners with lo <= hi
# componentwise (ordered). Produced only by certified hulls. ---
type BBox3 is Data:
  Bb{ lo: V.Point, hi: V.Point }

# --- Trimming curves live in SURFACE parameter space from the outset:
# a segment or cubic Bezier over (u, v). Composition with a surface
# maps them to 3D (plane_trim_pt now; other surfaces in C07/C08). ---
type TSeg is Data:
  Ts{ a: V.Vec2, b: V.Vec2 }

type TBez is Data:
  Tb{ b0: V.Vec2, b1: V.Vec2, b2: V.Vec2, b3: V.Vec2 }

# --- Cubic clamped NURBS: knot/point/weight lists with len(ks) =
# len(ps) + 4 = len(ws) + 4, validated by ops.bend's nurbs_checked
# (finite, nondecreasing, clamped ends, positive weights). Degree is
# FIXED at 3; the kind is content (knot vector + controls), never an
# ordinal or address (BN-7; contract §8). ---
type Nurb is Data:
  Nb{ ks: List<&2, F64>, ps: List<&2, V.Point>, ws: List<&2, F64> }

# --- Fixed windows extracted from NURBS lists for one de Boor step.
# Single-pass fuel-bounded extraction; the rest is fixed-size. ---
type K7 is Data:
  K7{ k0: F64, k1: F64, k2: F64, k3: F64, k4: F64, k5: F64, k6: F64 }

type P4 is Data:
  P4{ q0: V.Point, q1: V.Point, q2: V.Point, q3: V.Point }

type W4 is Data:
  W4{ w0: F64, w1: F64, w2: F64, w3: F64 }

type K4 is Data:
  K4{ k0: F64, k1: F64, k2: F64, k3: F64 }

# --- One value union, one result type: every fallible C03 op returns
# GRes carrying either a value or a C00 FailKind. No NaN/Inf ever hides
# in Gok. ---
type GVal is Data:
  GV_f{ v: F64 }
  GV_p{ v: V.Point }
  GV_d{ v: V.Dir }
  GV_v2{ v: V.Vec2 }
  GV_dom{ v: Dom }
  GV_ln{ v: Line3 }
  GV_pl{ v: Plane3 }
  GV_cc{ v: Circle3 }
  GV_bz{ v: Bez3 }
  GV_rq{ v: RQBez }
  GV_bp{ v: BezP }
  GV_sp{ v: Sphere }
  GV_cy{ v: Cyl }
  GV_co{ v: Cone }
  GV_to{ v: Torus }
  GV_bb{ v: BBox3 }
  GV_nb{ v: Nurb }
  GV_ts{ v: TSeg }
  GV_tb{ v: TBez }

type GRes is Data:
  Gok{ v: GVal }
  Gerr{ kind: T.FailKind }

def gok_f(v: F64) -> GRes:
  Gok{GV_f{v}}

def gok_p(v: V.Point) -> GRes:
  Gok{GV_p{v}}

def gok_d(v: V.Dir) -> GRes:
  Gok{GV_d{v}}

def gok_v2(v: V.Vec2) -> GRes:
  Gok{GV_v2{v}}

def gok_dom(v: Dom) -> GRes:
  Gok{GV_dom{v}}

def gok_ln(v: Line3) -> GRes:
  Gok{GV_ln{v}}

def gok_pl(v: Plane3) -> GRes:
  Gok{GV_pl{v}}

def gok_cc(v: Circle3) -> GRes:
  Gok{GV_cc{v}}

def gok_bz(v: Bez3) -> GRes:
  Gok{GV_bz{v}}

def gok_rq(v: RQBez) -> GRes:
  Gok{GV_rq{v}}

def gok_bp(v: BezP) -> GRes:
  Gok{GV_bp{v}}

def gok_sp(v: Sphere) -> GRes:
  Gok{GV_sp{v}}

def gok_cy(v: Cyl) -> GRes:
  Gok{GV_cy{v}}

def gok_co(v: Cone) -> GRes:
  Gok{GV_co{v}}

def gok_to(v: Torus) -> GRes:
  Gok{GV_to{v}}

def gok_bb(v: BBox3) -> GRes:
  Gok{GV_bb{v}}

def gok_nb(v: Nurb) -> GRes:
  Gok{GV_nb{v}}

def gok_ts(v: TSeg) -> GRes:
  Gok{GV_ts{v}}

def gok_tb(v: TBez) -> GRes:
  Gok{GV_tb{v}}

def gerr(k: T.FailKind) -> GRes:
  Gerr{k}

def gres_ok(r: GRes) -> Bool:
  match r:
    case Gok{v}: True{}
    case Gerr{kind}: False{}

def gres_show(r: GRes) -> String:
  match r:
    case Gok{v}: "ok"
    case Gerr{kind}: T.FailKind.show(kind)

# Total kind projector. There is no ok-valued FailKind, so Gok yields
# F_invalid BY DOCUMENTED CONVENTION (mirrors C01 cres_kind); gate on
# gres_ok or gres_show before reading the kind.
def gres_kind(r: GRes) -> T.FailKind:
  match r:
    case Gok{v}: T.F_invalid{}
    case Gerr{kind}: kind

# Total projectors; documented zeroes unless the arm matches.
def gres_f(r: GRes) -> F64:
  match r:
    case Gok{v}:
      match v:
        case GV_f{w}: w
        case _: 0.0f64
    case Gerr{kind}: 0.0f64

def gres_p(r: GRes) -> V.Point:
  match r:
    case Gok{v}:
      match v:
        case GV_p{w}: w
        case _: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case Gerr{kind}: V.Pt{0.0f64, 0.0f64, 0.0f64}

def gres_d(r: GRes) -> V.Dir:
  match r:
    case Gok{v}:
      match v:
        case GV_d{w}: w
        case _: V.Dr{0.0f64, 0.0f64, 0.0f64}
    case Gerr{kind}: V.Dr{0.0f64, 0.0f64, 0.0f64}

def gres_v2(r: GRes) -> V.Vec2:
  match r:
    case Gok{v}:
      match v:
        case GV_v2{w}: w
        case _: V.V2{0.0f64, 0.0f64}
    case Gerr{kind}: V.V2{0.0f64, 0.0f64}

def gres_dom(r: GRes) -> Dom:
  match r:
    case Gok{v}:
      match v:
        case GV_dom{w}: w
        case _: Dom{0.0f64, 0.0f64}
    case Gerr{kind}: Dom{0.0f64, 0.0f64}

def gres_bb(r: GRes) -> BBox3:
  match r:
    case Gok{v}:
      match v:
        case GV_bb{w}: w
        case _: Bb{V.Pt{0.0f64, 0.0f64, 0.0f64},
          V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case Gerr{kind}: Bb{V.Pt{0.0f64, 0.0f64, 0.0f64},
      V.Pt{0.0f64, 0.0f64, 0.0f64}}

# --- Exact constants as bit patterns (no parser dependence). ---
# Rational quarter-circle middle weight sqrt(2)/2 (python struct).
def w_quarter() -> F64:
  F64{4604544271217802189u64}

def one_o2() -> F64:
  0.5f64

# --- Raw accessors (total; no validation, no failure). ---
def dom_lo(d: Dom) -> F64:
  Dom{lo, hi} = d
  lo

def dom_hi(d: Dom) -> F64:
  Dom{lo, hi} = d
  hi

def pdom_d(p: Pdom) -> Dom:
  Pdom{d, periodic} = p
  d

def pdom_periodic(p: Pdom) -> Bool:
  Pdom{d, periodic} = p
  periodic

def ln_p(l: Line3) -> V.Point:
  Ln{p, d} = l
  p

def ln_d(l: Line3) -> V.Dir:
  Ln{p, d} = l
  d

def pl_o(p: Plane3) -> V.Point:
  Pl{o, u, v} = p
  o

def pl_u(p: Plane3) -> V.Dir:
  Pl{o, u, v} = p
  u

def pl_v(p: Plane3) -> V.Dir:
  Pl{o, u, v} = p
  v

def cc_c(c: Circle3) -> V.Point:
  Cc{c, u, v, r} = c
  c

def cc_u(c: Circle3) -> V.Dir:
  Cc{c, u, v, r} = c
  u

def cc_v(c: Circle3) -> V.Dir:
  Cc{c, u, v, r} = c
  v

def cc_r(c: Circle3) -> F64:
  Cc{c, u, v, r} = c
  r

def bz_p0(b: Bez3) -> V.Point:
  Bz{p0, p1, p2, p3} = b
  p0

def bz_p1(b: Bez3) -> V.Point:
  Bz{p0, p1, p2, p3} = b
  p1

def bz_p2(b: Bez3) -> V.Point:
  Bz{p0, p1, p2, p3} = b
  p2

def bz_p3(b: Bez3) -> V.Point:
  Bz{p0, p1, p2, p3} = b
  p3

def rq_p0(b: RQBez) -> V.Point:
  Rq{p0, p1, p2, w0, w1, w2} = b
  p0

def rq_p1(b: RQBez) -> V.Point:
  Rq{p0, p1, p2, w0, w1, w2} = b
  p1

def rq_p2(b: RQBez) -> V.Point:
  Rq{p0, p1, p2, w0, w1, w2} = b
  p2

def rq_w0(b: RQBez) -> F64:
  Rq{p0, p1, p2, w0, w1, w2} = b
  w0

def rq_w1(b: RQBez) -> F64:
  Rq{p0, p1, p2, w0, w1, w2} = b
  w1

def rq_w2(b: RQBez) -> F64:
  Rq{p0, p1, p2, w0, w1, w2} = b
  w2

def bp_c00(b: BezP) -> V.Point:
  Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23,
    p30, p31, p32, p33} = b
  p00

def bp_c03(b: BezP) -> V.Point:
  Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23,
    p30, p31, p32, p33} = b
  p03

def bp_c30(b: BezP) -> V.Point:
  Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23,
    p30, p31, p32, p33} = b
  p30

def bp_c33(b: BezP) -> V.Point:
  Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23,
    p30, p31, p32, p33} = b
  p33

def sp_c(s: Sphere) -> V.Point:
  Sp{c, r} = s
  c

def sp_r(s: Sphere) -> F64:
  Sp{c, r} = s
  r

def cy_o(s: Cyl) -> V.Point:
  Cy{o, a, r} = s
  o

def cy_a(s: Cyl) -> V.Dir:
  Cy{o, a, r} = s
  a

def cy_r(s: Cyl) -> F64:
  Cy{o, a, r} = s
  r

def co_o(s: Cone) -> V.Point:
  Co{o, a, k} = s
  o

def co_a(s: Cone) -> V.Dir:
  Co{o, a, k} = s
  a

def co_k(s: Cone) -> F64:
  Co{o, a, k} = s
  k

def to_o(s: Torus) -> V.Point:
  To{o, a, R, r} = s
  o

def to_a(s: Torus) -> V.Dir:
  To{o, a, R, r} = s
  a

def to_R(s: Torus) -> F64:
  To{o, a, R, r} = s
  R

def to_r(s: Torus) -> F64:
  To{o, a, R, r} = s
  r

def bb_lo(b: BBox3) -> V.Point:
  Bb{lo, hi} = b
  lo

def bb_hi(b: BBox3) -> V.Point:
  Bb{lo, hi} = b
  hi

def ts_a(t: TSeg) -> V.Vec2:
  Ts{a, b} = t
  a

def ts_b(t: TSeg) -> V.Vec2:
  Ts{a, b} = t
  b

def tb_b0(t: TBez) -> V.Vec2:
  Tb{b0, b1, b2, b3} = t
  b0

def tb_b1(t: TBez) -> V.Vec2:
  Tb{b0, b1, b2, b3} = t
  b1

def tb_b2(t: TBez) -> V.Vec2:
  Tb{b0, b1, b2, b3} = t
  b2

def tb_b3(t: TBez) -> V.Vec2:
  Tb{b0, b1, b2, b3} = t
  b3

def nb_ks(n: Nurb) -> List<&2, F64>:
  Nb{ks, ps, ws} = n
  ks

def nb_ps(n: Nurb) -> List<&2, V.Point>:
  Nb{ks, ps, ws} = n
  ps

def nb_ws(n: Nurb) -> List<&2, F64>:
  Nb{ks, ps, ws} = n
  ws

def k4_0(w: K4) -> F64:
  K4{k0, k1, k2, k3} = w
  k0

def k4_1(w: K4) -> F64:
  K4{k0, k1, k2, k3} = w
  k1

def k4_2(w: K4) -> F64:
  K4{k0, k1, k2, k3} = w
  k2

def k4_3(w: K4) -> F64:
  K4{k0, k1, k2, k3} = w
  k3

def k7_0(w: K7) -> F64:
  K7{k0, k1, k2, k3, k4, k5, k6} = w
  k0

def k7_1(w: K7) -> F64:
  K7{k0, k1, k2, k3, k4, k5, k6} = w
  k1

def k7_2(w: K7) -> F64:
  K7{k0, k1, k2, k3, k4, k5, k6} = w
  k2

def k7_3(w: K7) -> F64:
  K7{k0, k1, k2, k3, k4, k5, k6} = w
  k3

def k7_4(w: K7) -> F64:
  K7{k0, k1, k2, k3, k4, k5, k6} = w
  k4

def k7_5(w: K7) -> F64:
  K7{k0, k1, k2, k3, k4, k5, k6} = w
  k5

def k7_6(w: K7) -> F64:
  K7{k0, k1, k2, k3, k4, k5, k6} = w
  k6

def p4_0(w: P4) -> V.Point:
  P4{q0, q1, q2, q3} = w
  q0

def p4_1(w: P4) -> V.Point:
  P4{q0, q1, q2, q3} = w
  q1

def p4_2(w: P4) -> V.Point:
  P4{q0, q1, q2, q3} = w
  q2

def p4_3(w: P4) -> V.Point:
  P4{q0, q1, q2, q3} = w
  q3

def w4_0(w: W4) -> F64:
  W4{w0, w1, w2, w3} = w
  w0

def w4_1(w: W4) -> F64:
  W4{w0, w1, w2, w3} = w
  w1

def w4_2(w: W4) -> F64:
  W4{w0, w1, w2, w3} = w
  w2

def w4_3(w: W4) -> F64:
  W4{w0, w1, w2, w3} = w
  w3

# --- Finiteness: the entry boundary, mirroring C00 is_finite. ---
def dom_fin(d: Dom) -> Bool:
  Dom{lo, hi} = d
  Bool.and(T.is_finite(lo), T.is_finite(hi))

def ln_fin(l: Line3) -> Bool:
  Ln{p, d} = l
  Bool.and(V.pt_fin(p), V.dr_fin(d))

def pl_fin(p: Plane3) -> Bool:
  Pl{o, u, v} = p
  Bool.and(V.pt_fin(o), Bool.and(V.dr_fin(u), V.dr_fin(v)))

def cc_fin(c: Circle3) -> Bool:
  Cc{c, u, v, r} = c
  Bool.and(V.pt_fin(c),
    Bool.and(V.dr_fin(u), Bool.and(V.dr_fin(v), T.is_finite(r))))

def bz_fin(b: Bez3) -> Bool:
  Bz{p0, p1, p2, p3} = b
  Bool.and(V.pt_fin(p0),
    Bool.and(V.pt_fin(p1), Bool.and(V.pt_fin(p2), V.pt_fin(p3))))

def rq_fin(b: RQBez) -> Bool:
  Rq{p0, p1, p2, w0, w1, w2} = b
  Bool.and(V.pt_fin(p0),
    Bool.and(V.pt_fin(p1),
      Bool.and(V.pt_fin(p2),
        Bool.and(T.is_finite(w0),
          Bool.and(T.is_finite(w1), T.is_finite(w2))))))

def bp_fin(b: BezP) -> Bool:
  Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23,
    p30, p31, p32, p33} = b
  Bool.and(V.pt_fin(p00),
    Bool.and(V.pt_fin(p01),
      Bool.and(V.pt_fin(p02),
        Bool.and(V.pt_fin(p03),
          Bool.and(V.pt_fin(p10),
            Bool.and(V.pt_fin(p11),
              Bool.and(V.pt_fin(p12),
                Bool.and(V.pt_fin(p13),
                  Bool.and(V.pt_fin(p20),
                    Bool.and(V.pt_fin(p21),
                      Bool.and(V.pt_fin(p22),
                        Bool.and(V.pt_fin(p23),
                          Bool.and(V.pt_fin(p30),
                            Bool.and(V.pt_fin(p31),
                              Bool.and(V.pt_fin(p32),
                                V.pt_fin(p33))))))))))))))))

def sp_fin(s: Sphere) -> Bool:
  Sp{c, r} = s
  Bool.and(V.pt_fin(c), T.is_finite(r))

def cy_fin(s: Cyl) -> Bool:
  Cy{o, a, r} = s
  Bool.and(V.pt_fin(o), Bool.and(V.dr_fin(a), T.is_finite(r)))

def co_fin(s: Cone) -> Bool:
  Co{o, a, k} = s
  Bool.and(V.pt_fin(o), Bool.and(V.dr_fin(a), T.is_finite(k)))

def to_fin(s: Torus) -> Bool:
  To{o, a, R, r} = s
  Bool.and(V.pt_fin(o),
    Bool.and(V.dr_fin(a), Bool.and(T.is_finite(R), T.is_finite(r))))

def bb_fin(b: BBox3) -> Bool:
  Bb{lo, hi} = b
  Bool.and(V.pt_fin(lo), V.pt_fin(hi))

def ts_fin(t: TSeg) -> Bool:
  Ts{a, b} = t
  Bool.and(V.v2_fin(a), V.v2_fin(b))

def tb_fin(t: TBez) -> Bool:
  Tb{b0, b1, b2, b3} = t
  Bool.and(V.v2_fin(b0),
    Bool.and(V.v2_fin(b1), Bool.and(V.v2_fin(b2), V.v2_fin(b3))))

# A direction is degenerate iff exactly the zero vector (ordered
# equality; -0.0 == +0.0, so signed zeroes are zero too).
def dr_is_zero(d: V.Dir) -> Bool:
  V.Dr{x, y, z} = d
  Bool.and(F64.is_eq(x, 0.0f64),
    Bool.and(F64.is_eq(y, 0.0f64), F64.is_eq(z, 0.0f64)))

# Strictly positive finite scalar (radius, weight, slope): the
# is_lt conjunct alone would admit +Inf, so finiteness is load-bearing.
def spos(+x: F64) -> Bool:
  Bool.and(T.is_finite(x), F64.is_lt(0.0f64, x))

# --- Validated constructors: malformed input fails as invalid-input.
# Semantic checks needing norms/orthonormality live in ops.bend. ---
def mk_dom_go(lo: F64, hi: F64, ok: Bool) -> GRes:
  match ok:
    case True{}: gok_dom(Dom{lo, hi})
    case False{}: gerr(T.F_invalid{})

def mk_dom(+lo: F64, +hi: F64) -> GRes:
  mk_dom_go(lo, hi,
    Bool.and(T.is_finite(lo),
      Bool.and(T.is_finite(hi), F64.is_lt(lo, hi))))

def mk_line_go(p: V.Point, d: V.Dir, ok: Bool) -> GRes:
  match ok:
    case True{}: gok_ln(Ln{p, d})
    case False{}: gerr(T.F_invalid{})

def mk_line(+p: V.Point, +d: V.Dir) -> GRes:
  mk_line_go(p, d,
    Bool.and(V.pt_fin(p),
      Bool.and(V.dr_fin(d), Bool.not(dr_is_zero(d)))))

def mk_plane_go(o: V.Point, u: V.Dir, v: V.Dir, ok: Bool) -> GRes:
  match ok:
    case True{}: gok_pl(Pl{o, u, v})
    case False{}: gerr(T.F_invalid{})

def mk_plane(p: Plane3) -> GRes:
  Pl{+o, +u, +v} = p
  mk_plane_go(o, u, v, pl_fin(Pl{o, u, v}))

def mk_circ_go(c: V.Point, u: V.Dir, v: V.Dir, r: F64,
    ok: Bool) -> GRes:
  match ok:
    case True{}: gok_cc(Cc{c, u, v, r})
    case False{}: gerr(T.F_invalid{})

def mk_circ(+c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64) -> GRes:
  mk_circ_go(c, u, v, r,
    Bool.and(V.pt_fin(c),
      Bool.and(V.dr_fin(u), Bool.and(V.dr_fin(v), spos(r)))))

def mk_bez3_go(p0: V.Point, p1: V.Point, p2: V.Point, p3: V.Point,
    ok: Bool) -> GRes:
  match ok:
    case True{}: gok_bz(Bz{p0, p1, p2, p3})
    case False{}: gerr(T.F_invalid{})

def mk_bez3(+p0: V.Point, +p1: V.Point, +p2: V.Point,
    +p3: V.Point) -> GRes:
  mk_bez3_go(p0, p1, p2, p3, bz_fin(Bz{p0, p1, p2, p3}))

def mk_rqbez_go(p0: V.Point, p1: V.Point, p2: V.Point, w0: F64,
    w1: F64, w2: F64, ok: Bool) -> GRes:
  match ok:
    case True{}: gok_rq(Rq{p0, p1, p2, w0, w1, w2})
    case False{}: gerr(T.F_invalid{})

def mk_rqbez(+p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64,
    +w1: F64, +w2: F64) -> GRes:
  mk_rqbez_go(p0, p1, p2, w0, w1, w2,
    Bool.and(V.pt_fin(p0),
      Bool.and(V.pt_fin(p1),
        Bool.and(V.pt_fin(p2),
          Bool.and(spos(w0), Bool.and(spos(w1), spos(w2)))))))

def mk_bezp_go(p00: V.Point, p01: V.Point, p02: V.Point, p03: V.Point,
    p10: V.Point, p11: V.Point, p12: V.Point, p13: V.Point,
    p20: V.Point, p21: V.Point, p22: V.Point, p23: V.Point,
    p30: V.Point, p31: V.Point, p32: V.Point, p33: V.Point,
    ok: Bool) -> GRes:
  match ok:
    case True{}: gok_bp(Bp{p00, p01, p02, p03, p10, p11, p12, p13,
      p20, p21, p22, p23, p30, p31, p32, p33})
    case False{}: gerr(T.F_invalid{})

def mk_bezp(+p00: V.Point, +p01: V.Point, +p02: V.Point, +p03: V.Point,
    +p10: V.Point, +p11: V.Point, +p12: V.Point, +p13: V.Point,
    +p20: V.Point, +p21: V.Point, +p22: V.Point, +p23: V.Point,
    +p30: V.Point, +p31: V.Point, +p32: V.Point, +p33: V.Point) -> GRes:
  mk_bezp_go(p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22,
    p23, p30, p31, p32, p33,
    bp_fin(Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20, p21,
      p22, p23, p30, p31, p32, p33}))

def mk_sph_go(c: V.Point, r: F64, ok: Bool) -> GRes:
  match ok:
    case True{}: gok_sp(Sp{c, r})
    case False{}: gerr(T.F_invalid{})

def mk_sph(+c: V.Point, +r: F64) -> GRes:
  mk_sph_go(c, r, Bool.and(V.pt_fin(c), spos(r)))

def mk_cyl_go(o: V.Point, a: V.Dir, r: F64, ok: Bool) -> GRes:
  match ok:
    case True{}: gok_cy(Cy{o, a, r})
    case False{}: gerr(T.F_invalid{})

def mk_cyl(+o: V.Point, +a: V.Dir, +r: F64) -> GRes:
  mk_cyl_go(o, a, r,
    Bool.and(V.pt_fin(o),
      Bool.and(V.dr_fin(a),
        Bool.and(Bool.not(dr_is_zero(a)), spos(r)))))

def mk_cone_go(o: V.Point, a: V.Dir, k: F64, ok: Bool) -> GRes:
  match ok:
    case True{}: gok_co(Co{o, a, k})
    case False{}: gerr(T.F_invalid{})

def mk_cone(+o: V.Point, +a: V.Dir, +k: F64) -> GRes:
  mk_cone_go(o, a, k,
    Bool.and(V.pt_fin(o),
      Bool.and(V.dr_fin(a),
        Bool.and(Bool.not(dr_is_zero(a)), spos(k)))))

def mk_torus_go(o: V.Point, a: V.Dir, R: F64, r: F64,
    ok: Bool) -> GRes:
  match ok:
    case True{}: gok_to(To{o, a, R, r})
    case False{}: gerr(T.F_invalid{})

def mk_torus(+o: V.Point, +a: V.Dir, +R: F64, +r: F64) -> GRes:
  mk_torus_go(o, a, R, r,
    Bool.and(V.pt_fin(o),
      Bool.and(V.dr_fin(a),
        Bool.and(Bool.not(dr_is_zero(a)),
          Bool.and(spos(R), spos(r))))))

def mk_bbox_go(lo: V.Point, hi: V.Point, ok: Bool) -> GRes:
  match ok:
    case True{}: gok_bb(Bb{lo, hi})
    case False{}: gerr(T.F_invalid{})

def mk_bbox(lo: V.Point, hi: V.Point) -> GRes:
  V.Pt{+lx, +ly, +lz} = lo
  V.Pt{+hx, +hy, +hz} = hi
  mk_bbox_go(V.Pt{lx, ly, lz}, V.Pt{hx, hy, hz},
    Bool.and(V.pt_fin(V.Pt{lx, ly, lz}),
      Bool.and(V.pt_fin(V.Pt{hx, hy, hz}),
        Bool.and(F64.is_le(lx, hx),
          Bool.and(F64.is_le(ly, hy), F64.is_le(lz, hz))))))

def mk_tseg_go(a: V.Vec2, b: V.Vec2, ok: Bool) -> GRes:
  match ok:
    case True{}: gok_ts(Ts{a, b})
    case False{}: gerr(T.F_invalid{})

def mk_tseg(+a: V.Vec2, +b: V.Vec2) -> GRes:
  mk_tseg_go(a, b, ts_fin(Ts{a, b}))

def mk_tbez_go(b0: V.Vec2, b1: V.Vec2, b2: V.Vec2, b3: V.Vec2,
    ok: Bool) -> GRes:
  match ok:
    case True{}: gok_tb(Tb{b0, b1, b2, b3})
    case False{}: gerr(T.F_invalid{})

def mk_tbez(+b0: V.Vec2, +b1: V.Vec2, +b2: V.Vec2,
    +b3: V.Vec2) -> GRes:
  mk_tbez_go(b0, b1, b2, b3, tb_fin(Tb{b0, b1, b2, b3}))
