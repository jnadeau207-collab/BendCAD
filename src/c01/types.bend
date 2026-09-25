# C01 foundation types: Vec2/Vec3, Point/Dir newtypes, Mat3, Frame, Rigid.
# Data + total predicates + validated constructors + one result type.
# Fallible geometry: ops.bend. Contract: docs/c01-contract.md.
# Failure arms reuse C00 FailKind (T.FailKind); no new taxonomy.

import Base
import ../c00/types.bend as T

# --- Raw vectors: any three F64, finite or not. Only validated values flow
# into published geometry; ctors below reject nonfinite components. ---
type Vec2 is Data:
  V2{ x: F64, y: F64 }

type Vec3 is Data:
  V3{ x: F64, y: F64, z: F64 }

# Point vs direction: distinct types, distinct operations. A Point is a
# position (no point+point exists); a Dir is a free finite vector, possibly
# zero as data (unit-ness is a checked property, not the type invariant).
type Point is Data:
  Pt{ x: F64, y: F64, z: F64 }

type Dir is Data:
  Dr{ x: F64, y: F64, z: F64 }

# Row-major 3x3: rows (a,b,c) (d,e,f) (g,h,i).
type Mat3 is Data:
  M3{ a: F64, b: F64, c: F64, d: F64, e: F64, f: F64, g: F64, h: F64,
    i: F64 }

# Frame: origin + right-handed orthonormal basis (columns bx, by, bz).
# Constructed only through validation (ops.bend); the basis obligation is
# |norm-1| <= 1e-12, |pairwise dot| <= 1e-12, |det-1| <= 1e-9, det > 0.
type Frame is Data:
  Fr{ ox: F64, oy: F64, oz: F64, xx: F64, xy: F64, xz: F64, yx: F64,
    yy: F64, yz: F64, zx: F64, zy: F64, zz: F64 }

# Rigid transform: proper rotation + translation. Same basis obligation.
type Rigid is Data:
  Rg{ rot: Mat3, tx: F64, ty: F64, tz: F64 }

# --- One value union, one result type: every fallible C01 op returns CRes
# carrying either a value or a C00 FailKind. No NaN/Inf ever hides in Cok. ---
type CVal is Data:
  CV_f{ v: F64 }
  CV_v2{ v: Vec2 }
  CV_v3{ v: Vec3 }
  CV_p{ v: Point }
  CV_d{ v: Dir }
  CV_m{ v: Mat3 }
  CV_fr{ v: Frame }
  CV_rg{ v: Rigid }

type CRes is Data:
  Cok{ v: CVal }
  Cerr{ kind: T.FailKind }

def cok_f(v: F64) -> CRes:
  Cok{CV_f{v}}

def cok_v2(v: Vec2) -> CRes:
  Cok{CV_v2{v}}

def cok_v3(v: Vec3) -> CRes:
  Cok{CV_v3{v}}

def cok_p(v: Point) -> CRes:
  Cok{CV_p{v}}

def cok_d(v: Dir) -> CRes:
  Cok{CV_d{v}}

def cok_m(v: Mat3) -> CRes:
  Cok{CV_m{v}}

def cok_fr(v: Frame) -> CRes:
  Cok{CV_fr{v}}

def cok_rg(v: Rigid) -> CRes:
  Cok{CV_rg{v}}

def cerr(k: T.FailKind) -> CRes:
  Cerr{k}

def cres_ok(r: CRes) -> Bool:
  match r:
    case Cok{v}: True{}
    case Cerr{kind}: False{}

def cres_show(r: CRes) -> String:
  match r:
    case Cok{v}: "ok"
    case Cerr{kind}: T.FailKind.show(kind)

# Total kind projector. There is no ok-valued FailKind, so Cok yields
# F_invalid BY DOCUMENTED CONVENTION (contract §7); gate on cres_ok or
# cres_show before reading the kind. Pinned: pos-kind-doc.
def cres_kind(r: CRes) -> T.FailKind:
  match r:
    case Cok{v}: T.F_invalid{}
    case Cerr{kind}: kind

# Total projectors; documented zeroes unless the arm matches.
def cres_f(r: CRes) -> F64:
  match r:
    case Cok{v}:
      match v:
        case CV_f{w}: w
        case _: 0.0f64
    case Cerr{kind}: 0.0f64

def cres_v2(r: CRes) -> Vec2:
  match r:
    case Cok{v}:
      match v:
        case CV_v2{w}: w
        case _: V2{0.0f64, 0.0f64}
    case Cerr{kind}: V2{0.0f64, 0.0f64}

def cres_v3(r: CRes) -> Vec3:
  match r:
    case Cok{v}:
      match v:
        case CV_v3{w}: w
        case _: V3{0.0f64, 0.0f64, 0.0f64}
    case Cerr{kind}: V3{0.0f64, 0.0f64, 0.0f64}

def cres_p(r: CRes) -> Point:
  match r:
    case Cok{v}:
      match v:
        case CV_p{w}: w
        case _: Pt{0.0f64, 0.0f64, 0.0f64}
    case Cerr{kind}: Pt{0.0f64, 0.0f64, 0.0f64}

def cres_d(r: CRes) -> Dir:
  match r:
    case Cok{v}:
      match v:
        case CV_d{w}: w
        case _: Dr{0.0f64, 0.0f64, 0.0f64}
    case Cerr{kind}: Dr{0.0f64, 0.0f64, 0.0f64}

def cres_m(r: CRes) -> Mat3:
  match r:
    case Cok{v}:
      match v:
        case CV_m{w}: w
        case _: M3{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64,
          0.0f64, 0.0f64}
    case Cerr{kind}: M3{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64,
      0.0f64, 0.0f64, 0.0f64}

def cres_fr(r: CRes) -> Frame:
  match r:
    case Cok{v}:
      match v:
        case CV_fr{w}: w
        case _: Fr{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64,
          0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}
    case Cerr{kind}: Fr{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64,
      0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}

def cres_rg(r: CRes) -> Rigid:
  match r:
    case Cok{v}:
      match v:
        case CV_rg{w}: w
        case _: Rg{M3{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64,
          0.0f64, 0.0f64}, 0.0f64, 0.0f64, 0.0f64}
    case Cerr{kind}: Rg{M3{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64,
      0.0f64, 0.0f64, 0.0f64}, 0.0f64, 0.0f64, 0.0f64}

# --- Exact constants as bit patterns (no parser dependence). ---
def dbl_max() -> F64:
  F64{9218868437227405311u64}

def min_sub() -> F64:
  F64{1u64}

def th_unit() -> F64:
  F64{4427486594234968593u64}

def th_par() -> F64:
  F64{4427486594234968593u64}

def th_det() -> F64:
  F64{4472406533629990549u64}

def th_sing() -> F64:
  F64{4427486594234968593u64}

# --- Finiteness: the entry boundary, mirroring C00 is_finite. ---
def v2_fin(v: Vec2) -> Bool:
  V2{x, y} = v
  Bool.and(T.is_finite(x), T.is_finite(y))

def v3_fin(v: Vec3) -> Bool:
  V3{x, y, z} = v
  Bool.and(T.is_finite(x), Bool.and(T.is_finite(y), T.is_finite(z)))

def pt_fin(p: Point) -> Bool:
  Pt{x, y, z} = p
  Bool.and(T.is_finite(x), Bool.and(T.is_finite(y), T.is_finite(z)))

def dr_fin(d: Dir) -> Bool:
  Dr{x, y, z} = d
  Bool.and(T.is_finite(x), Bool.and(T.is_finite(y), T.is_finite(z)))

def m3_fin(m: Mat3) -> Bool:
  M3{a, b, c, d, e, f, g, h, i} = m
  Bool.and(T.is_finite(a),
    Bool.and(T.is_finite(b),
      Bool.and(T.is_finite(c),
        Bool.and(T.is_finite(d),
          Bool.and(T.is_finite(e),
            Bool.and(T.is_finite(f),
              Bool.and(T.is_finite(g),
                Bool.and(T.is_finite(h), T.is_finite(i)))))))))

# --- Validated constructors: nonfinite smuggling fails as invalid-input. ---
def mk_v2_go(x: F64, y: F64, ok: Bool) -> CRes:
  match ok:
    case True{}: cok_v2(V2{x, y})
    case False{}: cerr(T.F_invalid{})

def mk_v2(+x: F64, +y: F64) -> CRes:
  mk_v2_go(x, y, Bool.and(T.is_finite(x), T.is_finite(y)))

def mk_v3_go(x: F64, y: F64, z: F64, ok: Bool) -> CRes:
  match ok:
    case True{}: cok_v3(V3{x, y, z})
    case False{}: cerr(T.F_invalid{})

def mk_v3(+x: F64, +y: F64, +z: F64) -> CRes:
  mk_v3_go(x, y, z,
    Bool.and(T.is_finite(x), Bool.and(T.is_finite(y), T.is_finite(z))))

def mk_pt_go(x: F64, y: F64, z: F64, ok: Bool) -> CRes:
  match ok:
    case True{}: cok_p(Pt{x, y, z})
    case False{}: cerr(T.F_invalid{})

def mk_pt(+x: F64, +y: F64, +z: F64) -> CRes:
  mk_pt_go(x, y, z,
    Bool.and(T.is_finite(x), Bool.and(T.is_finite(y), T.is_finite(z))))

def mk_dr_go(x: F64, y: F64, z: F64, ok: Bool) -> CRes:
  match ok:
    case True{}: cok_d(Dr{x, y, z})
    case False{}: cerr(T.F_invalid{})

def mk_dr(+x: F64, +y: F64, +z: F64) -> CRes:
  mk_dr_go(x, y, z,
    Bool.and(T.is_finite(x), Bool.and(T.is_finite(y), T.is_finite(z))))

def mk_m3_go(a: F64, b: F64, c: F64, d: F64, e: F64, f: F64, g: F64,
    h: F64, i: F64, ok: Bool) -> CRes:
  match ok:
    case True{}: cok_m(M3{a, b, c, d, e, f, g, h, i})
    case False{}: cerr(T.F_invalid{})

def mk_m3(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64, +g: F64,
    +h: F64, +i: F64) -> CRes:
  mk_m3_go(a, b, c, d, e, f, g, h, i, m3_fin(M3{a, b, c, d, e, f, g, h, i}))

# --- Raw component accessors (total; no validation, no failure). ---
def v2_x(v: Vec2) -> F64:
  V2{x, y} = v
  x

def v2_y(v: Vec2) -> F64:
  V2{x, y} = v
  y

def v3_x(v: Vec3) -> F64:
  V3{x, y, z} = v
  x

def v3_y(v: Vec3) -> F64:
  V3{x, y, z} = v
  y

def v3_z(v: Vec3) -> F64:
  V3{x, y, z} = v
  z

def pt_x(p: Point) -> F64:
  Pt{x, y, z} = p
  x

def pt_y(p: Point) -> F64:
  Pt{x, y, z} = p
  y

def pt_z(p: Point) -> F64:
  Pt{x, y, z} = p
  z

def dr_x(d: Dir) -> F64:
  Dr{x, y, z} = d
  x

def dr_y(d: Dir) -> F64:
  Dr{x, y, z} = d
  y

def dr_z(d: Dir) -> F64:
  Dr{x, y, z} = d
  z

def m_a(m: Mat3) -> F64:
  M3{a, b, c, d, e, f, g, h, i} = m
  a

def m_b(m: Mat3) -> F64:
  M3{a, b, c, d, e, f, g, h, i} = m
  b

def m_c(m: Mat3) -> F64:
  M3{a, b, c, d, e, f, g, h, i} = m
  c

def m_d(m: Mat3) -> F64:
  M3{a, b, c, d, e, f, g, h, i} = m
  d

def m_e(m: Mat3) -> F64:
  M3{a, b, c, d, e, f, g, h, i} = m
  e

def m_f(m: Mat3) -> F64:
  M3{a, b, c, d, e, f, g, h, i} = m
  f

def m_g(m: Mat3) -> F64:
  M3{a, b, c, d, e, f, g, h, i} = m
  g

def m_h(m: Mat3) -> F64:
  M3{a, b, c, d, e, f, g, h, i} = m
  h

def m_i(m: Mat3) -> F64:
  M3{a, b, c, d, e, f, g, h, i} = m
  i

# --- Raw exact ops: total reordering/negation, finite-preserving always.
# Arithmetic (add/sub/scale/mul) can overflow truly; validated wrappers live
# in ops.bend and re-check finiteness. ---
def v3_neg(v: Vec3) -> Vec3:
  V3{x, y, z} = v
  V3{F64.neg(x), F64.neg(y), F64.neg(z)}

def v2_neg(v: Vec2) -> Vec2:
  V2{x, y} = v
  V2{F64.neg(x), F64.neg(y)}

def m3_trans(m: Mat3) -> Mat3:
  M3{a, b, c, d, e, f, g, h, i} = m
  M3{a, d, g, b, e, h, c, f, i}

def m3_ident() -> Mat3:
  M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64,
    1.0f64}

def v3_zero() -> Vec3:
  V3{0.0f64, 0.0f64, 0.0f64}

def v2_zero() -> Vec2:
  V2{0.0f64, 0.0f64}
