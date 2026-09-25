# C01 operators: robust norms, dot/cross/det, normalize, conditioning-checked
# inverses, frames, rigid transforms. Every publishing op returns CRes:
# finite value or a C00 FailKind (invalid = malformed/degenerate input,
# uncertain = true overflow or failed conditioning). Raw *_raw defs are
# total but may yield nonfinite on true overflow; they are never published
# without re-validation. No naive sqrt(x*x+...) anywhere.

import Base
import ../c00/types.bend as T
import ./types.bend as V

# --- Raw arithmetic core (total; callers re-validate). ---
def v3_add_raw(+a: V.Vec3, +b: V.Vec3) -> V.Vec3:
  V.V3{+ax, +ay, +az} = a
  V.V3{+bx, +by, +bz} = b
  V.V3{F64.add(ax, bx), F64.add(ay, by), F64.add(az, bz)}

def v3_sub_raw(+a: V.Vec3, +b: V.Vec3) -> V.Vec3:
  V.V3{+ax, +ay, +az} = a
  V.V3{+bx, +by, +bz} = b
  V.V3{F64.sub(ax, bx), F64.sub(ay, by), F64.sub(az, bz)}

def v3_scale_raw(+s: F64, +v: V.Vec3) -> V.Vec3:
  V.V3{+x, +y, +z} = v
  V.V3{F64.mul(s, x), F64.mul(s, y), F64.mul(s, z)}

def v2_add_raw(+a: V.Vec2, +b: V.Vec2) -> V.Vec2:
  V.V2{+ax, +ay} = a
  V.V2{+bx, +by} = b
  V.V2{F64.add(ax, bx), F64.add(ay, by)}

def v2_sub_raw(+a: V.Vec2, +b: V.Vec2) -> V.Vec2:
  V.V2{+ax, +ay} = a
  V.V2{+bx, +by} = b
  V.V2{F64.sub(ax, bx), F64.sub(ay, by)}

def v2_scale_raw(+s: F64, +v: V.Vec2) -> V.Vec2:
  V.V2{+x, +y} = v
  V.V2{F64.mul(s, x), F64.mul(s, y)}

# Left-fold sums; the order is the contract (docs/c01-contract.md).
def v3_dot_raw(+a: V.Vec3, +b: V.Vec3) -> F64:
  V.V3{+ax, +ay, +az} = a
  V.V3{+bx, +by, +bz} = b
  F64.add(F64.add(F64.mul(ax, bx), F64.mul(ay, by)), F64.mul(az, bz))

def v2_dot_raw(+a: V.Vec2, +b: V.Vec2) -> F64:
  V.V2{+ax, +ay} = a
  V.V2{+bx, +by} = b
  F64.add(F64.mul(ax, bx), F64.mul(ay, by))

def v3_cross_raw(+a: V.Vec3, +b: V.Vec3) -> V.Vec3:
  V.V3{+ax, +ay, +az} = a
  V.V3{+bx, +by, +bz} = b
  V.V3{F64.sub(F64.mul(ay, bz), F64.mul(az, by)),
    F64.sub(F64.mul(az, bx), F64.mul(ax, bz)),
    F64.sub(F64.mul(ax, by), F64.mul(ay, bx))}

# Cofactor expansion along row 0, left-fold sums.
def m3_det_raw(+m: V.Mat3) -> F64:
  V.M3{+a, +b, +c, +d, +e, +f, +g, +h, +i} = m
  +t0 = F64.sub(F64.mul(e, i), F64.mul(f, h))
  +t1 = F64.sub(F64.mul(d, i), F64.mul(f, g))
  +t2 = F64.sub(F64.mul(d, h), F64.mul(e, g))
  F64.add(F64.sub(F64.mul(a, t0), F64.mul(b, t1)), F64.mul(c, t2))

def m3_mul_raw(+a: V.Mat3, +b: V.Mat3) -> V.Mat3:
  V.M3{+a0, +a1, +a2, +a3, +a4, +a5, +a6, +a7, +a8} = a
  V.M3{+b0, +b1, +b2, +b3, +b4, +b5, +b6, +b7, +b8} = b
  V.M3{F64.add(F64.add(F64.mul(a0, b0), F64.mul(a1, b3)), F64.mul(a2, b6)),
    F64.add(F64.add(F64.mul(a0, b1), F64.mul(a1, b4)), F64.mul(a2, b7)),
    F64.add(F64.add(F64.mul(a0, b2), F64.mul(a1, b5)), F64.mul(a2, b8)),
    F64.add(F64.add(F64.mul(a3, b0), F64.mul(a4, b3)), F64.mul(a5, b6)),
    F64.add(F64.add(F64.mul(a3, b1), F64.mul(a4, b4)), F64.mul(a5, b7)),
    F64.add(F64.add(F64.mul(a3, b2), F64.mul(a4, b5)), F64.mul(a5, b8)),
    F64.add(F64.add(F64.mul(a6, b0), F64.mul(a7, b3)), F64.mul(a8, b6)),
    F64.add(F64.add(F64.mul(a6, b1), F64.mul(a7, b4)), F64.mul(a8, b7)),
    F64.add(F64.add(F64.mul(a6, b2), F64.mul(a7, b5)), F64.mul(a8, b8))}

def m3_app_raw(+m: V.Mat3, +v: V.Vec3) -> V.Vec3:
  V.M3{+a, +b, +c, +d, +e, +f, +g, +h, +i} = m
  V.V3{+x, +y, +z} = v
  V.V3{F64.add(F64.add(F64.mul(a, x), F64.mul(b, y)), F64.mul(c, z)),
    F64.add(F64.add(F64.mul(d, x), F64.mul(e, y)), F64.mul(f, z)),
    F64.add(F64.add(F64.mul(g, x), F64.mul(h, y)), F64.mul(i, z))}

# Scaled hypot: m = max|x|; 0 if m == 0 else m*sqrt(sum (x/m)^2).
# Ratios are in [-1,1], so no spurious overflow at any finite scale.
# WARNING: F64.max swallows NaN (max(a,b) keeps a unless a<b ordered),
# so *_norm_raw can collapse to 0.0 on nonfinite input. Every publishing
# entry below gates on input finiteness FIRST (invalid-input) and never
# trusts a finite result alone. m3_is_rot is safe without a gate: it
# ANDs m3_fin over the input, so nonfinite can only yield False.
def v3_norm_go(+m: F64, +x: F64, +y: F64, +z: F64, zero: Bool) -> F64:
  match zero:
    case True{}: 0.0f64
    case False{}:
      +rx = F64.div(x, m)
      +ry = F64.div(y, m)
      +rz = F64.div(z, m)
      F64.mul(m, F64.sqrt(F64.add(F64.add(F64.mul(rx, rx), F64.mul(ry, ry)),
        F64.mul(rz, rz))))

def v3_norm_raw(+v: V.Vec3) -> F64:
  V.V3{+x, +y, +z} = v
  +m = F64.max(F64.abs(x), F64.max(F64.abs(y), F64.abs(z)))
  v3_norm_go(m, x, y, z, F64.is_eq(m, 0.0f64))

def v2_norm_go(+m: F64, +x: F64, +y: F64, zero: Bool) -> F64:
  match zero:
    case True{}: 0.0f64
    case False{}:
      +rx = F64.div(x, m)
      +ry = F64.div(y, m)
      F64.mul(m, F64.sqrt(F64.add(F64.mul(rx, rx), F64.mul(ry, ry))))

def v2_norm_raw(+v: V.Vec2) -> F64:
  V.V2{+x, +y} = v
  +m = F64.max(F64.abs(x), F64.abs(y))
  v2_norm_go(m, x, y, F64.is_eq(m, 0.0f64))

# --- Validated publishing ops: finite value or structured failure. ---
def fin_or_unc_f(+v: F64, ok: Bool) -> V.CRes:
  match ok:
    case True{}: V.cok_f(v)
    case False{}: V.cerr(T.F_uncertain{})

def fin_or_unc_v3(+v: V.Vec3, ok: Bool) -> V.CRes:
  match ok:
    case True{}: V.cok_v3(v)
    case False{}: V.cerr(T.F_uncertain{})

def fin_or_unc_v2(+v: V.Vec2, ok: Bool) -> V.CRes:
  match ok:
    case True{}: V.cok_v2(v)
    case False{}: V.cerr(T.F_uncertain{})

def fin_or_unc_d(+d: V.Dir, ok: Bool) -> V.CRes:
  match ok:
    case True{}: V.cok_d(d)
    case False{}: V.cerr(T.F_uncertain{})

def fin_or_unc_p(+p: V.Point, ok: Bool) -> V.CRes:
  match ok:
    case True{}: V.cok_p(p)
    case False{}: V.cerr(T.F_uncertain{})

def fin_or_unc_m(+m: V.Mat3, ok: Bool) -> V.CRes:
  match ok:
    case True{}: V.cok_m(m)
    case False{}: V.cerr(T.F_uncertain{})

# Checked constructors: validate components, then build. NOTE: binding a
# constructor application to a shared (+/-) binder hangs the fork checker,
# so validated values are always built component-wise here, never bound
# and re-checked. Callers pass each component expression once.
def v3_checked_go(x: F64, y: F64, z: F64, ok: Bool) -> V.CRes:
  match ok:
    case True{}: V.cok_v3(V.V3{x, y, z})
    case False{}: V.cerr(T.F_uncertain{})

def v3_checked(+x: F64, +y: F64, +z: F64) -> V.CRes:
  v3_checked_go(x, y, z,
    Bool.and(T.is_finite(x), Bool.and(T.is_finite(y), T.is_finite(z))))

def v2_checked_go(x: F64, y: F64, ok: Bool) -> V.CRes:
  match ok:
    case True{}: V.cok_v2(V.V2{x, y})
    case False{}: V.cerr(T.F_uncertain{})

def v2_checked(+x: F64, +y: F64) -> V.CRes:
  v2_checked_go(x, y, Bool.and(T.is_finite(x), T.is_finite(y)))

def d_checked_go(x: F64, y: F64, z: F64, ok: Bool) -> V.CRes:
  match ok:
    case True{}: V.cok_d(V.Dr{x, y, z})
    case False{}: V.cerr(T.F_uncertain{})

def d_checked(+x: F64, +y: F64, +z: F64) -> V.CRes:
  d_checked_go(x, y, z,
    Bool.and(T.is_finite(x), Bool.and(T.is_finite(y), T.is_finite(z))))

def p_checked_go(x: F64, y: F64, z: F64, ok: Bool) -> V.CRes:
  match ok:
    case True{}: V.cok_p(V.Pt{x, y, z})
    case False{}: V.cerr(T.F_uncertain{})

def p_checked(+x: F64, +y: F64, +z: F64) -> V.CRes:
  p_checked_go(x, y, z,
    Bool.and(T.is_finite(x), Bool.and(T.is_finite(y), T.is_finite(z))))

def m3_checked_go(a: F64, b: F64, c: F64, d: F64, e: F64, f: F64,
    g: F64, h: F64, i: F64, ok: Bool) -> V.CRes:
  match ok:
    case True{}: V.cok_m(V.M3{a, b, c, d, e, f, g, h, i})
    case False{}: V.cerr(T.F_uncertain{})

def m3_checked(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64,
    +g: F64, +h: F64, +i: F64) -> V.CRes:
  m3_checked_go(a, b, c, d, e, f, g, h, i,
    V.m3_fin(V.M3{a, b, c, d, e, f, g, h, i}))

def v3_dot(+a: V.Vec3, +b: V.Vec3) -> V.CRes:
  +d = v3_dot_raw(a, b)
  fin_or_unc_f(d, T.is_finite(d))

def v2_dot(+a: V.Vec2, +b: V.Vec2) -> V.CRes:
  +d = v2_dot_raw(a, b)
  fin_or_unc_f(d, T.is_finite(d))

def v3_cross(+a: V.Vec3, +b: V.Vec3) -> V.CRes:
  +c = v3_cross_raw(a, b)
  fin_or_unc_v3(c, V.v3_fin(c))

def m3_det(+m: V.Mat3) -> V.CRes:
  +d = m3_det_raw(m)
  fin_or_unc_f(d, T.is_finite(d))

def m3_mul(+a: V.Mat3, +b: V.Mat3) -> V.CRes:
  +c = m3_mul_raw(a, b)
  fin_or_unc_m(c, V.m3_fin(c))

# Input gate: nonfinite entries are malformed (invalid-input, C00
# taxonomy), never trusted to the max-based raw norm. True overflow of
# finite inputs still reports numerical-uncertainty via the result check.
def v3_norm_gate(+v: V.Vec3, fin: Bool) -> V.CRes:
  match fin:
    case True{}:
      +n = v3_norm_raw(v)
      fin_or_unc_f(n, T.is_finite(n))
    case False{}: V.cerr(T.F_invalid{})

def v3_norm(+v: V.Vec3) -> V.CRes:
  v3_norm_gate(v, V.v3_fin(v))

def v2_norm_gate(+v: V.Vec2, fin: Bool) -> V.CRes:
  match fin:
    case True{}:
      +n = v2_norm_raw(v)
      fin_or_unc_f(n, T.is_finite(n))
    case False{}: V.cerr(T.F_invalid{})

def v2_norm(+v: V.Vec2) -> V.CRes:
  v2_norm_gate(v, V.v2_fin(v))

def v3_dist_go(+d: V.Vec3, fin: Bool) -> V.CRes:
  match fin:
    case True{}: v3_norm(d)
    case False{}: V.cerr(T.F_uncertain{})

def v3_dist_gate(+a: V.Vec3, +b: V.Vec3, fin: Bool) -> V.CRes:
  match fin:
    case True{}:
      +d = v3_sub_raw(a, b)
      v3_dist_go(d, V.v3_fin(d))
    case False{}: V.cerr(T.F_invalid{})

def v3_dist(+a: V.Vec3, +b: V.Vec3) -> V.CRes:
  v3_dist_gate(a, b, Bool.and(V.v3_fin(a), V.v3_fin(b)))

def v2_dist_go(+d: V.Vec2, fin: Bool) -> V.CRes:
  match fin:
    case True{}: v2_norm(d)
    case False{}: V.cerr(T.F_uncertain{})

def v2_dist_gate(+a: V.Vec2, +b: V.Vec2, fin: Bool) -> V.CRes:
  match fin:
    case True{}:
      +d = v2_sub_raw(a, b)
      v2_dist_go(d, V.v2_fin(d))
    case False{}: V.cerr(T.F_invalid{})

def v2_dist(+a: V.Vec2, +b: V.Vec2) -> V.CRes:
  v2_dist_gate(a, b, Bool.and(V.v2_fin(a), V.v2_fin(b)))

def v3_add(+a: V.Vec3, +b: V.Vec3) -> V.CRes:
  +c = v3_add_raw(a, b)
  fin_or_unc_v3(c, V.v3_fin(c))

def v3_sub(+a: V.Vec3, +b: V.Vec3) -> V.CRes:
  +c = v3_sub_raw(a, b)
  fin_or_unc_v3(c, V.v3_fin(c))

def v3_scale(+s: F64, +v: V.Vec3) -> V.CRes:
  +c = v3_scale_raw(s, v)
  fin_or_unc_v3(c, V.v3_fin(c))

def v2_add(+a: V.Vec2, +b: V.Vec2) -> V.CRes:
  +c = v2_add_raw(a, b)
  fin_or_unc_v2(c, V.v2_fin(c))

def v2_scale(+s: F64, +v: V.Vec2) -> V.CRes:
  +c = v2_scale_raw(s, v)
  fin_or_unc_v2(c, V.v2_fin(c))

# Normalize: zero -> invalid (no direction exists); nonfinite norm (true
# overflow) -> uncertain; else the unit vector, re-validated, never NaN.
def v3_unit_go(+x: F64, +y: F64, +z: F64, +n: F64, zero: Bool) -> V.CRes:
  match zero:
    case True{}: V.cerr(T.F_invalid{})
    case False{}:
      v3_checked(F64.div(x, n), F64.div(y, n), F64.div(z, n))

def v3_unit_fin(+x: F64, +y: F64, +z: F64, +n: F64, fin: Bool) -> V.CRes:
  match fin:
    case True{}: v3_unit_go(x, y, z, n, F64.is_eq(n, 0.0f64))
    case False{}: V.cerr(T.F_uncertain{})

def v3_normalize_gate(+x: F64, +y: F64, +z: F64, fin: Bool) -> V.CRes:
  match fin:
    case True{}:
      +n = v3_norm_raw(V.V3{x, y, z})
      v3_unit_fin(x, y, z, n, T.is_finite(n))
    case False{}: V.cerr(T.F_invalid{})

def v3_normalize(+v: V.Vec3) -> V.CRes:
  V.V3{+x, +y, +z} = v
  v3_normalize_gate(x, y, z,
    Bool.and(T.is_finite(x), Bool.and(T.is_finite(y), T.is_finite(z))))

def v2_unit_go(+x: F64, +y: F64, +n: F64, zero: Bool) -> V.CRes:
  match zero:
    case True{}: V.cerr(T.F_invalid{})
    case False{}:
      v2_checked(F64.div(x, n), F64.div(y, n))

def v2_unit_fin(+x: F64, +y: F64, +n: F64, fin: Bool) -> V.CRes:
  match fin:
    case True{}: v2_unit_go(x, y, n, F64.is_eq(n, 0.0f64))
    case False{}: V.cerr(T.F_uncertain{})

def v2_normalize_gate(+x: F64, +y: F64, fin: Bool) -> V.CRes:
  match fin:
    case True{}:
      +n = v2_norm_raw(V.V2{x, y})
      v2_unit_fin(x, y, n, T.is_finite(n))
    case False{}: V.cerr(T.F_invalid{})

def v2_normalize(+v: V.Vec2) -> V.CRes:
  V.V2{+x, +y} = v
  v2_normalize_gate(x, y, Bool.and(T.is_finite(x), T.is_finite(y)))

def dr_unit_go(+x: F64, +y: F64, +z: F64, +n: F64, zero: Bool) -> V.CRes:
  match zero:
    case True{}: V.cerr(T.F_invalid{})
    case False{}:
      d_checked(F64.div(x, n), F64.div(y, n), F64.div(z, n))

def dr_unit_fin(+x: F64, +y: F64, +z: F64, +n: F64, fin: Bool) -> V.CRes:
  match fin:
    case True{}: dr_unit_go(x, y, z, n, F64.is_eq(n, 0.0f64))
    case False{}: V.cerr(T.F_uncertain{})

def dr_unit_gate(+x: F64, +y: F64, +z: F64, fin: Bool) -> V.CRes:
  match fin:
    case True{}:
      +n = v3_norm_raw(V.V3{x, y, z})
      dr_unit_fin(x, y, z, n, T.is_finite(n))
    case False{}: V.cerr(T.F_invalid{})

def dr_unit(+d: V.Dir) -> V.CRes:
  V.Dr{+x, +y, +z} = d
  dr_unit_gate(x, y, z,
    Bool.and(T.is_finite(x), Bool.and(T.is_finite(y), T.is_finite(z))))

# Gradient of the norm at v is v/|v|; same failure arms as normalize.
def v3_grad_norm(+v: V.Vec3) -> V.CRes:
  v3_normalize(v)

# Unit direction from a to b: coincident -> invalid; overflow -> uncertain.
def seg_dir_go(+dx: F64, +dy: F64, +dz: F64, fin: Bool) -> V.CRes:
  match fin:
    case True{}: dr_unit(V.Dr{dx, dy, dz})
    case False{}: V.cerr(T.F_uncertain{})

def seg_dir_gate(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64,
    +bz: F64, fin: Bool) -> V.CRes:
  match fin:
    case True{}:
      +dx = F64.sub(bx, ax)
      +dy = F64.sub(by, ay)
      +dz = F64.sub(bz, az)
      seg_dir_go(dx, dy, dz,
        Bool.and(T.is_finite(dx),
          Bool.and(T.is_finite(dy), T.is_finite(dz))))
    case False{}: V.cerr(T.F_invalid{})

def seg_dir(+a: V.Point, +b: V.Point) -> V.CRes:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  seg_dir_gate(ax, ay, az, bx, by, bz,
    Bool.and(Bool.and(T.is_finite(ax),
      Bool.and(T.is_finite(ay), T.is_finite(az))),
      Bool.and(T.is_finite(bx),
        Bool.and(T.is_finite(by), T.is_finite(bz)))))

# Point/direction algebra. There is deliberately no point+point.
def p_plus_d(+p: V.Point, +d: V.Dir) -> V.CRes:
  V.Pt{+px, +py, +pz} = p
  V.Dr{+dx, +dy, +dz} = d
  p_checked(F64.add(px, dx), F64.add(py, dy), F64.add(pz, dz))

def p_minus_p(+a: V.Point, +b: V.Point) -> V.CRes:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  d_checked(F64.sub(ax, bx), F64.sub(ay, by), F64.sub(az, bz))

def p_dist_go(+dx: F64, +dy: F64, +dz: F64, fin: Bool) -> V.CRes:
  match fin:
    case True{}: v3_norm(V.V3{dx, dy, dz})
    case False{}: V.cerr(T.F_uncertain{})

def p_dist_gate(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64,
    +bz: F64, fin: Bool) -> V.CRes:
  match fin:
    case True{}:
      +dx = F64.sub(ax, bx)
      +dy = F64.sub(ay, by)
      +dz = F64.sub(az, bz)
      p_dist_go(dx, dy, dz,
        Bool.and(T.is_finite(dx),
          Bool.and(T.is_finite(dy), T.is_finite(dz))))
    case False{}: V.cerr(T.F_invalid{})

def p_dist(+a: V.Point, +b: V.Point) -> V.CRes:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  p_dist_gate(ax, ay, az, bx, by, bz,
    Bool.and(Bool.and(T.is_finite(ax),
      Bool.and(T.is_finite(ay), T.is_finite(az))),
      Bool.and(T.is_finite(bx),
        Bool.and(T.is_finite(by), T.is_finite(bz)))))

def d_add(+a: V.Dir, +b: V.Dir) -> V.CRes:
  V.Dr{+ax, +ay, +az} = a
  V.Dr{+bx, +by, +bz} = b
  d_checked(F64.add(ax, bx), F64.add(ay, by), F64.add(az, bz))

def d_scale(+s: F64, +d: V.Dir) -> V.CRes:
  V.Dr{+x, +y, +z} = d
  d_checked(F64.mul(s, x), F64.mul(s, y), F64.mul(s, z))

# --- Conditioning: the rotation obligation behind Frame and Rigid. ---
# Rows unit within 1e-12, pairwise orthogonal within 1e-12, det within
# 1e-9 of +1. All comparisons fail closed on nonfinite (F64.is_le is
# False unless ordered), and finiteness is also checked explicitly.
def unit_ok(+n: F64) -> Bool:
  Bool.and(T.is_finite(n),
    F64.is_le(F64.abs(F64.sub(n, 1.0f64)), V.th_unit()))

def ortho_ok(+d: F64) -> Bool:
  Bool.and(T.is_finite(d), F64.is_le(F64.abs(d), V.th_unit()))

def det_ok(+d: F64) -> Bool:
  Bool.and(T.is_finite(d),
    Bool.and(F64.is_lt(0.0f64, d),
      F64.is_le(F64.abs(F64.sub(d, 1.0f64)), V.th_det())))

def m3_is_rot_go(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64,
    +f: F64, +g: F64, +h: F64, +i: F64) -> Bool:
  +n0 = v3_norm_raw(V.V3{a, b, c})
  +n1 = v3_norm_raw(V.V3{d, e, f})
  +n2 = v3_norm_raw(V.V3{g, h, i})
  +q01 = v3_dot_raw(V.V3{a, b, c}, V.V3{d, e, f})
  +q02 = v3_dot_raw(V.V3{a, b, c}, V.V3{g, h, i})
  +q12 = v3_dot_raw(V.V3{d, e, f}, V.V3{g, h, i})
  +dt = m3_det_raw(V.M3{a, b, c, d, e, f, g, h, i})
  Bool.and(V.m3_fin(V.M3{a, b, c, d, e, f, g, h, i}),
    Bool.and(unit_ok(n0),
      Bool.and(unit_ok(n1),
        Bool.and(unit_ok(n2),
          Bool.and(ortho_ok(q01),
            Bool.and(ortho_ok(q02),
              Bool.and(ortho_ok(q12), det_ok(dt))))))))

def m3_is_rot(m: V.Mat3) -> Bool:
  V.M3{a, b, c, d, e, f, g, h, i} = m
  m3_is_rot_go(a, b, c, d, e, f, g, h, i)

def mk_frame_go(+ox: F64, +oy: F64, +oz: F64, +xx: F64, +xy: F64,
    +xz: F64, +yx: F64, +yy: F64, +yz: F64, +zx: F64, +zy: F64,
    +zz: F64, ok: Bool) -> V.CRes:
  match ok:
    case True{}:
      V.cok_fr(V.Fr{ox, oy, oz, xx, xy, xz, yx, yy, yz, zx, zy, zz})
    case False{}: V.cerr(T.F_invalid{})

# Basis arrives as columns; the rotation check runs on rows.
def mk_frame(+ox: F64, +oy: F64, +oz: F64, +xx: F64, +xy: F64,
    +xz: F64, +yx: F64, +yy: F64, +yz: F64, +zx: F64, +zy: F64,
    +zz: F64) -> V.CRes:
  +fin = Bool.and(T.is_finite(ox),
    Bool.and(T.is_finite(oy),
      Bool.and(T.is_finite(oz),
        Bool.and(T.is_finite(xx),
          Bool.and(T.is_finite(xy),
            Bool.and(T.is_finite(xz),
              Bool.and(T.is_finite(yx),
                Bool.and(T.is_finite(yy),
                  Bool.and(T.is_finite(yz),
                    Bool.and(T.is_finite(zx),
                      Bool.and(T.is_finite(zy), T.is_finite(zz))))))))))))
  mk_frame_go(ox, oy, oz, xx, xy, xz, yx, yy, yz, zx, zy, zz,
    Bool.and(fin, m3_is_rot(V.M3{xx, yx, zx, xy, yy, zy, xz, yz, zz})))

def mk_rigid_go(+m: V.Mat3, +tx: F64, +ty: F64, +tz: F64, ok: Bool) -> V.CRes:
  match ok:
    case True{}: V.cok_rg(V.Rg{m, tx, ty, tz})
    case False{}: V.cerr(T.F_invalid{})

def mk_rigid(+m: V.Mat3, +tx: F64, +ty: F64, +tz: F64) -> V.CRes:
  mk_rigid_go(m, tx, ty, tz,
    Bool.and(Bool.and(T.is_finite(tx),
      Bool.and(T.is_finite(ty), T.is_finite(tz))), m3_is_rot(m)))

def rg_ident() -> V.Rigid:
  V.Rg{V.m3_ident(), 0.0f64, 0.0f64, 0.0f64}

def rg_of_frame(+fr: V.Frame) -> V.Rigid:
  V.Fr{+ox, +oy, +oz, +xx, +xy, +xz, +yx, +yy, +yz, +zx, +zy, +zz} = fr
  V.Rg{V.M3{xx, yx, zx, xy, yy, zy, xz, yz, zz}, ox, oy, oz}

def fr_of_rigid(+r: V.Rigid) -> V.Frame:
  V.Rg{+m, +tx, +ty, +tz} = r
  V.M3{+a, +b, +c, +d, +e, +f, +g, +h, +i} = m
  V.Fr{tx, ty, tz, a, d, g, b, e, h, c, f, i}

# Jacobian of rigid application w.r.t. the point: the rotation block.
def rg_jac(+r: V.Rigid) -> V.Mat3:
  V.Rg{+m, +tx, +ty, +tz} = r
  m

# --- Scaled-adjugate inverse: B = A/s with |bij| <= 1, so cofactors and
# det(B) (<= 6) cannot overflow. |det(B)| <= 1e-12 -> uncertain. ---
def m3_maxabs(+m: V.Mat3) -> F64:
  V.M3{+a, +b, +c, +d, +e, +f, +g, +h, +i} = m
  F64.max(F64.abs(a),
    F64.max(F64.abs(b),
      F64.max(F64.abs(c),
        F64.max(F64.abs(d),
          F64.max(F64.abs(e),
            F64.max(F64.abs(f),
              F64.max(F64.abs(g),
                F64.max(F64.abs(h), F64.abs(i)))))))))

def m3_inv_q(+c11: F64, +c21: F64, +c31: F64, +c12: F64, +c22: F64,
    +c32: F64, +c13: F64, +c23: F64, +c33: F64, +q: F64) -> V.CRes:
  m3_checked(F64.div(c11, q), F64.div(c21, q), F64.div(c31, q),
    F64.div(c12, q), F64.div(c22, q), F64.div(c32, q), F64.div(c13, q),
    F64.div(c23, q), F64.div(c33, q))

# Cofactors of B = A/s; adjugate entries below are transposed.
def m3_inv_cof(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64,
    +g: F64, +h: F64, +i: F64, +s: F64, +db: F64) -> V.CRes:
  +c11 = F64.sub(F64.mul(F64.div(e, s), F64.div(i, s)),
    F64.mul(F64.div(f, s), F64.div(h, s)))
  +c12 = F64.sub(F64.mul(F64.div(d, s), F64.div(i, s)),
    F64.mul(F64.div(f, s), F64.div(g, s)))
  +c13 = F64.sub(F64.mul(F64.div(d, s), F64.div(h, s)),
    F64.mul(F64.div(e, s), F64.div(g, s)))
  +c21 = F64.sub(F64.mul(F64.div(b, s), F64.div(i, s)),
    F64.mul(F64.div(c, s), F64.div(h, s)))
  +c22 = F64.sub(F64.mul(F64.div(a, s), F64.div(i, s)),
    F64.mul(F64.div(c, s), F64.div(g, s)))
  +c23 = F64.sub(F64.mul(F64.div(a, s), F64.div(h, s)),
    F64.mul(F64.div(b, s), F64.div(g, s)))
  +c31 = F64.sub(F64.mul(F64.div(b, s), F64.div(f, s)),
    F64.mul(F64.div(c, s), F64.div(e, s)))
  +c32 = F64.sub(F64.mul(F64.div(a, s), F64.div(f, s)),
    F64.mul(F64.div(c, s), F64.div(d, s)))
  +c33 = F64.sub(F64.mul(F64.div(a, s), F64.div(e, s)),
    F64.mul(F64.div(b, s), F64.div(d, s)))
  m3_inv_q(c11, F64.neg(c21), c31, F64.neg(c12), c22, F64.neg(c32),
    c13, F64.neg(c23), c33, F64.mul(s, db))

def m3_inv_det_go(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64,
    +g: F64, +h: F64, +i: F64, +s: F64, +db: F64, tiny: Bool) -> V.CRes:
  match tiny:
    case True{}: V.cerr(T.F_uncertain{})
    case False{}: m3_inv_cof(a, b, c, d, e, f, g, h, i, s, db)

def m3_inv_det(+m: V.Mat3, +s: F64, +db: F64, tiny: Bool) -> V.CRes:
  V.M3{+a, +b, +c, +d, +e, +f, +g, +h, +i} = m
  m3_inv_det_go(a, b, c, d, e, f, g, h, i, s, db, tiny)

def m3_inv_db_go(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64,
    +g: F64, +h: F64, +i: F64, +s: F64, zero: Bool) -> V.CRes:
  match zero:
    case True{}: V.cerr(T.F_uncertain{})
    case False{}:
      +db = m3_det_raw(V.M3{F64.div(a, s), F64.div(b, s), F64.div(c, s),
        F64.div(d, s), F64.div(e, s), F64.div(f, s), F64.div(g, s),
        F64.div(h, s), F64.div(i, s)})
      m3_inv_det(V.M3{a, b, c, d, e, f, g, h, i}, s, db,
        Bool.or(Bool.not(T.is_finite(db)),
          F64.is_le(F64.abs(db), V.th_sing())))

def m3_inv_db(+m: V.Mat3, +s: F64, zero: Bool) -> V.CRes:
  V.M3{+a, +b, +c, +d, +e, +f, +g, +h, +i} = m
  m3_inv_db_go(a, b, c, d, e, f, g, h, i, s, zero)

def m3_inv(+m: V.Mat3) -> V.CRes:
  +s = m3_maxabs(m)
  m3_inv_db(m, s, F64.is_eq(s, 0.0f64))

# --- Rigid compose / invert / apply. ---
def rg_compose_rot_go(+r: V.Mat3, +tx: F64, +ty: F64, +tz: F64,
    ok: Bool) -> V.CRes:
  match ok:
    case True{}: V.cok_rg(V.Rg{r, tx, ty, tz})
    case False{}: V.cerr(T.F_uncertain{})

def rg_compose_rot(+r: V.Mat3, +t: V.Vec3, ok: Bool) -> V.CRes:
  V.V3{+tx, +ty, +tz} = t
  rg_compose_rot_go(r, tx, ty, tz, ok)

def rg_compose_go(+r: V.Mat3, +t: V.Vec3, fin: Bool) -> V.CRes:
  match fin:
    case True{}: rg_compose_rot(r, t, m3_is_rot(r))
    case False{}: V.cerr(T.F_uncertain{})

def rg_compose(+a: V.Rigid, +b: V.Rigid) -> V.CRes:
  V.Rg{+ra, +tax, +tay, +taz} = a
  V.Rg{+rb, +tbx, +tby, +tbz} = b
  +r = m3_mul_raw(ra, rb)
  +t = v3_add_raw(m3_app_raw(ra, V.V3{tbx, tby, tbz}), V.V3{tax, tay, taz})
  rg_compose_go(r, t, Bool.and(V.m3_fin(r), V.v3_fin(t)))

def rg_inv_go(+rt: V.Mat3, +t: V.Vec3, fin: Bool) -> V.CRes:
  match fin:
    case True{}: rg_compose_rot(rt, V.v3_neg(t), m3_is_rot(rt))
    case False{}: V.cerr(T.F_uncertain{})

def rg_inv(+r: V.Rigid) -> V.CRes:
  V.Rg{+m, +tx, +ty, +tz} = r
  +rt = V.m3_trans(m)
  +t = m3_app_raw(rt, V.V3{tx, ty, tz})
  rg_inv_go(rt, t, V.v3_fin(t))

def rg_apply_p_go(+tx: F64, +ty: F64, +tz: F64, +q: V.Vec3) -> V.CRes:
  V.V3{+qx, +qy, +qz} = q
  p_checked(F64.add(qx, tx), F64.add(qy, ty), F64.add(qz, tz))

def rg_apply_p(+r: V.Rigid, +p: V.Point) -> V.CRes:
  V.Rg{+m, +tx, +ty, +tz} = r
  V.Pt{+px, +py, +pz} = p
  rg_apply_p_go(tx, ty, tz, m3_app_raw(m, V.V3{px, py, pz}))

def rg_apply_d_go(+q: V.Vec3) -> V.CRes:
  V.V3{+qx, +qy, +qz} = q
  d_checked(qx, qy, qz)

def rg_apply_d(+r: V.Rigid, +d: V.Dir) -> V.CRes:
  V.Rg{+m, +tx, +ty, +tz} = r
  V.Dr{+dx, +dy, +dz} = d
  rg_apply_d_go(m3_app_raw(m, V.V3{dx, dy, dz}))

def rg_apply_v(+r: V.Rigid, +v: V.Vec3) -> V.CRes:
  V.Rg{+m, +tx, +ty, +tz} = r
  +q = m3_app_raw(m, v)
  fin_or_unc_v3(q, V.v3_fin(q))

# Frame maps run through the one rigid path (no duplicate algorithm).
def fr_to_world(+fr: V.Frame, +p: V.Point) -> V.CRes:
  rg_apply_p(rg_of_frame(fr), p)

def fr_to_local_go(+p: V.Point, +ri: V.CRes) -> V.CRes:
  match ri:
    case V.Cok{v}:
      match v:
        case V.CV_rg{r}: rg_apply_p(r, p)
        case _: V.cerr(T.F_uncertain{})
    case V.Cerr{kind}: V.cerr(kind)

def fr_to_local(+fr: V.Frame, +p: V.Point) -> V.CRes:
  fr_to_local_go(p, rg_inv(rg_of_frame(fr)))

# Frame from two directions (Gram-Schmidt, cf. legacy PlacementFrame):
# normalize z, orthogonalize x against it, y = z cross x. Zero input ->
# invalid; parallel/near-parallel (relative 1e-12) -> uncertain.
def frame_basis_fin(+ox: F64, +oy: F64, +oz: F64, +zx: F64, +zy: F64,
    +zz: F64, +px: F64, +py: F64, +pz: F64, +np: F64) -> V.CRes:
  +ux = F64.div(px, np)
  +uy = F64.div(py, np)
  +uz = F64.div(pz, np)
  +yx = F64.sub(F64.mul(zy, uz), F64.mul(zz, uy))
  +yy = F64.sub(F64.mul(zz, ux), F64.mul(zx, uz))
  +yz = F64.sub(F64.mul(zx, uy), F64.mul(zy, ux))
  mk_frame(ox, oy, oz, ux, uy, uz, yx, yy, yz, zx, zy, zz)

def frame_basis_par_go(+ox: F64, +oy: F64, +oz: F64, +zx: F64, +zy: F64,
    +zz: F64, +px: F64, +py: F64, +pz: F64, +np: F64,
    par: Bool) -> V.CRes:
  match par:
    case True{}: V.cerr(T.F_uncertain{})
    case False{}: frame_basis_fin(ox, oy, oz, zx, zy, zz, px, py, pz, np)

def frame_basis_par(+o: V.Point, +zx: F64, +zy: F64, +zz: F64, +px: F64,
    +py: F64, +pz: F64, +nx: F64, +np: F64, par: Bool) -> V.CRes:
  V.Pt{+ox, +oy, +oz} = o
  frame_basis_par_go(ox, oy, oz, zx, zy, zz, px, py, pz, np, par)

def frame_basis_xp(+o: V.Point, +zx: F64, +zy: F64, +zz: F64, +xx: F64,
    +xy: F64, +xz: F64, +nx: F64, fin: Bool) -> V.CRes:
  match fin:
    case True{}:
      +dd = F64.add(F64.add(F64.mul(xx, zx), F64.mul(xy, zy)),
        F64.mul(xz, zz))
      +px = F64.sub(xx, F64.mul(zx, dd))
      +py = F64.sub(xy, F64.mul(zy, dd))
      +pz = F64.sub(xz, F64.mul(zz, dd))
      +np = v3_norm_raw(V.V3{px, py, pz})
      frame_basis_par(o, zx, zy, zz, px, py, pz, nx, np,
        Bool.or(Bool.not(T.is_finite(np)),
          F64.is_le(np, F64.mul(V.th_par(), nx))))
    case False{}: V.cerr(T.F_uncertain{})

def frame_basis_xv(+o: V.Point, +zx: F64, +zy: F64, +zz: F64, +xx: F64,
    +xy: F64, +xz: F64, +nx: F64, zero: Bool) -> V.CRes:
  match zero:
    case True{}: V.cerr(T.F_invalid{})
    case False{}:
      frame_basis_xp(o, zx, zy, zz, xx, xy, xz, nx,
        Bool.and(V.dr_fin(V.Dr{zx, zy, zz}),
          Bool.and(T.is_finite(xx),
            Bool.and(T.is_finite(xy), T.is_finite(xz)))))

# Leaf-first: par <- xp <- xv <- xn2 <- zv <- zn <- xn <- basis.

def frame_basis_xn2(+o: V.Point, +zx: F64, +zy: F64, +zz: F64, +xx: F64,
    +xy: F64, +xz: F64, +nx: F64, fin: Bool) -> V.CRes:
  match fin:
    case True{}:
      frame_basis_xv(o, zx, zy, zz, xx, xy, xz, nx,
        F64.is_eq(nx, 0.0f64))
    case False{}: V.cerr(T.F_uncertain{})

def frame_basis_zv(+o: V.Point, +zx: F64, +zy: F64, +zz: F64, +xx: F64,
    +xy: F64, +xz: F64, +nz: F64, zero: Bool) -> V.CRes:
  match zero:
    case True{}: V.cerr(T.F_invalid{})
    case False{}:
      +ux = F64.div(zx, nz)
      +uy = F64.div(zy, nz)
      +uz = F64.div(zz, nz)
      +nx = v3_norm_raw(V.V3{xx, xy, xz})
      frame_basis_xn2(o, ux, uy, uz, xx, xy, xz, nx, T.is_finite(nx))

def frame_basis_zn(+o: V.Point, +zx: F64, +zy: F64, +zz: F64, +xx: F64,
    +xy: F64, +xz: F64, +nz: F64, fin: Bool) -> V.CRes:
  match fin:
    case True{}:
      frame_basis_zv(o, zx, zy, zz, xx, xy, xz, nz,
        F64.is_eq(nz, 0.0f64))
    case False{}: V.cerr(T.F_uncertain{})

def frame_basis_xn(+o: V.Point, +z: V.Dir, +x: V.Dir) -> V.CRes:
  V.Dr{+zxx, +zyx, +zzx} = z
  V.Dr{+xxx, +xyx, +xzx} = x
  +nz = v3_norm_raw(V.V3{zxx, zyx, zzx})
  frame_basis_zn(o, zxx, zyx, zzx, xxx, xyx, xzx, nz, T.is_finite(nz))

def frame_basis_gate(+o: V.Point, +z: V.Dir, +x: V.Dir,
    fin: Bool) -> V.CRes:
  match fin:
    case True{}: frame_basis_xn(o, z, x)
    case False{}: V.cerr(T.F_invalid{})

def frame_basis(+o: V.Point, +z: V.Dir, +x: V.Dir) -> V.CRes:
  frame_basis_gate(o, z, x,
    Bool.and(V.pt_fin(o), Bool.and(V.dr_fin(z), V.dr_fin(x))))
