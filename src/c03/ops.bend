# C03 operators: evaluation, derivatives, subdivision, enclosures,
# projection, trimming composition, NURBS de Boor. Every publishing op
# returns GRes: a finite value or a C00 FailKind (invalid = malformed
# input or out-of-domain parameter, uncertain = true overflow,
# exhausted = NURBS fuel ran out). Raw *_raw defs are total but may
# yield nonfinite on true overflow; they are never published without
# re-validation. Dot/cross/norm reuse C01's exact formulas and
# left-fold order. No transcendental evaluation anywhere: circles are
# rational (stereographic), conics are rational Beziers.

import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ./types.bend as G

# --- Homogeneous work point for rational evaluation (de Boor). ---
type Hpt is Data:
  Hp{ x: F64, y: F64, z: F64, w: F64 }

def hpt_x(h: Hpt) -> F64:
  Hp{x, y, z, w} = h
  x

def hpt_y(h: Hpt) -> F64:
  Hp{x, y, z, w} = h
  y

def hpt_z(h: Hpt) -> F64:
  Hp{x, y, z, w} = h
  z

def hpt_w(h: Hpt) -> F64:
  Hp{x, y, z, w} = h
  w

def hpt_fin(h: Hpt) -> Bool:
  Hp{x, y, z, w} = h
  Bool.and(T.is_finite(x),
    Bool.and(T.is_finite(y),
      Bool.and(T.is_finite(z), T.is_finite(w))))

# --- Raw point/direction arithmetic (total; callers re-validate). ---
def dd_dot_raw(+a: V.Dir, +b: V.Dir) -> F64:
  V.Dr{+ax, +ay, +az} = a
  V.Dr{+bx, +by, +bz} = b
  F64.add(F64.add(F64.mul(ax, bx), F64.mul(ay, by)), F64.mul(az, bz))

def dd_cross_raw(+a: V.Dir, +b: V.Dir) -> V.Dir:
  V.Dr{+ax, +ay, +az} = a
  V.Dr{+bx, +by, +bz} = b
  V.Dr{F64.sub(F64.mul(ay, bz), F64.mul(az, by)),
    F64.sub(F64.mul(az, bx), F64.mul(ax, bz)),
    F64.sub(F64.mul(ax, by), F64.mul(ay, bx))}

def pp_sub_raw(+a: V.Point, +b: V.Point) -> V.Dir:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  V.Dr{F64.sub(ax, bx), F64.sub(ay, by), F64.sub(az, bz)}

def pd_add_raw(+p: V.Point, +s: F64, +d: V.Dir) -> V.Point:
  V.Pt{+px, +py, +pz} = p
  V.Dr{+dx, +dy, +dz} = d
  V.Pt{F64.add(px, F64.mul(s, dx)), F64.add(py, F64.mul(s, dy)),
    F64.add(pz, F64.mul(s, dz))}

def dd_scale_raw(+s: F64, +d: V.Dir) -> V.Dir:
  V.Dr{+x, +y, +z} = d
  V.Dr{F64.mul(s, x), F64.mul(s, y), F64.mul(s, z)}

def dd_add_raw(+a: V.Dir, +b: V.Dir) -> V.Dir:
  V.Dr{+ax, +ay, +az} = a
  V.Dr{+bx, +by, +bz} = b
  V.Dr{F64.add(ax, bx), F64.add(ay, by), F64.add(az, bz)}

def dd_sub_raw(+a: V.Dir, +b: V.Dir) -> V.Dir:
  V.Dr{+ax, +ay, +az} = a
  V.Dr{+bx, +by, +bz} = b
  V.Dr{F64.sub(ax, bx), F64.sub(ay, by), F64.sub(az, bz)}

# Scaled hypot on a direction (C01 v3_norm_raw formula): ratios in
# [-1, 1], so no spurious overflow. F64.max swallows NaN, so every
# publishing use gates input finiteness FIRST.
def d3_norm_go(+m: F64, +x: F64, +y: F64, +z: F64,
    zero: Bool) -> F64:
  match zero:
    case True{}: 0.0f64
    case False{}:
      +rx = F64.div(x, m)
      +ry = F64.div(y, m)
      +rz = F64.div(z, m)
      F64.mul(m, F64.sqrt(F64.add(F64.add(F64.mul(rx, rx),
        F64.mul(ry, ry)), F64.mul(rz, rz))))

def d3_norm_raw(+d: V.Dir) -> F64:
  V.Dr{+x, +y, +z} = d
  +m = F64.max(F64.abs(x), F64.max(F64.abs(y), F64.abs(z)))
  d3_norm_go(m, x, y, z, F64.is_eq(m, 0.0f64))

# Linear interpolation, one formula everywhere: a*s + b*t per slot.
# (Callers pass s = 1-t; the association is the contract.)
def flerp_raw(+a: F64, +b: F64, +s: F64, +t: F64) -> F64:
  F64.add(F64.mul(a, s), F64.mul(b, t))

def plerp_raw(+a: V.Point, +b: V.Point, +s: F64, +t: F64) -> V.Point:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  V.Pt{flerp_raw(ax, bx, s, t), flerp_raw(ay, by, s, t),
    flerp_raw(az, bz, s, t)}

def v2lerp_raw(+a: V.Vec2, +b: V.Vec2, +s: F64, +t: F64) -> V.Vec2:
  V.V2{+ax, +ay} = a
  V.V2{+bx, +by} = b
  V.V2{flerp_raw(ax, bx, s, t), flerp_raw(ay, by, s, t)}

def hlerp_raw(+a: Hpt, +b: Hpt, +s: F64, +t: F64) -> Hpt:
  Hp{+ax, +ay, +az, +aw} = a
  Hp{+bx, +by, +bz, +bw} = b
  Hp{flerp_raw(ax, bx, s, t), flerp_raw(ay, by, s, t),
    flerp_raw(az, bz, s, t), flerp_raw(aw, bw, s, t)}

# Weighted sums with caller-supplied basis values, left-fold order.
def pt_cubic_raw(+p0: V.Point, +p1: V.Point, +p2: V.Point,
    +p3: V.Point, +b0: F64, +b1: F64, +b2: F64, +b3: F64) -> V.Point:
  V.Pt{+x0, +y0, +z0} = p0
  V.Pt{+x1, +y1, +z1} = p1
  V.Pt{+x2, +y2, +z2} = p2
  V.Pt{+x3, +y3, +z3} = p3
  V.Pt{F64.add(F64.add(F64.add(F64.mul(b0, x0), F64.mul(b1, x1)),
      F64.mul(b2, x2)), F64.mul(b3, x3)),
    F64.add(F64.add(F64.add(F64.mul(b0, y0), F64.mul(b1, y1)),
      F64.mul(b2, y2)), F64.mul(b3, y3)),
    F64.add(F64.add(F64.add(F64.mul(b0, z0), F64.mul(b1, z1)),
      F64.mul(b2, z2)), F64.mul(b3, z3))}

def v2_cubic_raw(+p0: V.Vec2, +p1: V.Vec2, +p2: V.Vec2, +p3: V.Vec2,
    +b0: F64, +b1: F64, +b2: F64, +b3: F64) -> V.Vec2:
  V.V2{+x0, +y0} = p0
  V.V2{+x1, +y1} = p1
  V.V2{+x2, +y2} = p2
  V.V2{+x3, +y3} = p3
  V.V2{F64.add(F64.add(F64.add(F64.mul(b0, x0), F64.mul(b1, x1)),
      F64.mul(b2, x2)), F64.mul(b3, x3)),
    F64.add(F64.add(F64.add(F64.mul(b0, y0), F64.mul(b1, y1)),
      F64.mul(b2, y2)), F64.mul(b3, y3))}

def pt_quad_raw(+p0: V.Point, +p1: V.Point, +p2: V.Point, +c0: F64,
    +c1: F64, +c2: F64) -> V.Point:
  V.Pt{+x0, +y0, +z0} = p0
  V.Pt{+x1, +y1, +z1} = p1
  V.Pt{+x2, +y2, +z2} = p2
  V.Pt{F64.add(F64.add(F64.mul(c0, x0), F64.mul(c1, x1)),
      F64.mul(c2, x2)),
    F64.add(F64.add(F64.mul(c0, y0), F64.mul(c1, y1)),
      F64.mul(c2, y2)),
    F64.add(F64.add(F64.mul(c0, z0), F64.mul(c1, z1)),
      F64.mul(c2, z2))}

def dr_quad_raw(+d0: V.Dir, +d1: V.Dir, +d2: V.Dir, +c0: F64,
    +c1: F64, +c2: F64) -> V.Dir:
  V.Dr{+x0, +y0, +z0} = d0
  V.Dr{+x1, +y1, +z1} = d1
  V.Dr{+x2, +y2, +z2} = d2
  V.Dr{F64.add(F64.add(F64.mul(c0, x0), F64.mul(c1, x1)),
      F64.mul(c2, x2)),
    F64.add(F64.add(F64.mul(c0, y0), F64.mul(c1, y1)),
      F64.mul(c2, y2)),
    F64.add(F64.add(F64.mul(c0, z0), F64.mul(c1, z1)),
      F64.mul(c2, z2))}

# --- Publishing gates: value + ok flag + failure kind. ---
def gate_f(+v: F64, ok: Bool, k: T.FailKind) -> G.GRes:
  match ok:
    case True{}: G.gok_f(v)
    case False{}: G.gerr(k)

def gate_p(+v: V.Point, ok: Bool, k: T.FailKind) -> G.GRes:
  match ok:
    case True{}: G.gok_p(v)
    case False{}: G.gerr(k)

def gate_d(+v: V.Dir, ok: Bool, k: T.FailKind) -> G.GRes:
  match ok:
    case True{}: G.gok_d(v)
    case False{}: G.gerr(k)

def gate_v2(+v: V.Vec2, ok: Bool, k: T.FailKind) -> G.GRes:
  match ok:
    case True{}: G.gok_v2(v)
    case False{}: G.gerr(k)

def gate_dom(+v: G.Dom, ok: Bool, k: T.FailKind) -> G.GRes:
  match ok:
    case True{}: G.gok_dom(v)
    case False{}: G.gerr(k)

def gate_bb(+v: G.BBox3, ok: Bool, k: T.FailKind) -> G.GRes:
  match ok:
    case True{}: G.gok_bb(v)
    case False{}: G.gerr(k)

# Orthonormal pair check: each unit within th_unit, |dot| within
# th_unit. Finiteness is conjuncted explicitly (ordered comparisons
# fail closed, but the conjunct documents the boundary).
def uv_frame_ok(+u: V.Dir, +v: V.Dir) -> Bool:
  +nu = d3_norm_raw(u)
  +nv = d3_norm_raw(v)
  +du = F64.abs(F64.sub(nu, 1.0f64))
  +dv = F64.abs(F64.sub(nv, 1.0f64))
  +dp = F64.abs(dd_dot_raw(u, v))
  Bool.and(V.dr_fin(u),
    Bool.and(V.dr_fin(v),
      Bool.and(F64.is_le(du, V.th_unit()),
        Bool.and(F64.is_le(dv, V.th_unit()),
          F64.is_le(dp, V.th_unit())))))

# Unit-axis check for quadric frames.
def ax_unit_ok(+a: V.Dir) -> Bool:
  +n = d3_norm_raw(a)
  Bool.and(V.dr_fin(a),
    F64.is_le(F64.abs(F64.sub(n, 1.0f64)), V.th_unit()))

# --- Domains: midpoint, length, clamp, single-step periodic wrap,
# subdivision. Wrap is single-step by contract (multi-turn reduction
# needs no-trig range reduction, a stated follow-up). ---
def dom_mid_go(+lo: F64, +hi: F64, ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      +m = F64.div(F64.add(lo, hi), 2.0f64)
      gate_f(m, T.is_finite(m), T.F_uncertain{})
    case False{}: G.gerr(T.F_invalid{})

def dom_mid(+d: G.Dom) -> G.GRes:
  G.Dom{+lo, +hi} = d
  dom_mid_go(lo, hi, G.dom_valid(G.Dom{lo, hi}))

def dom_len_go(+lo: F64, +hi: F64, ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      +l = F64.sub(hi, lo)
      gate_f(l, T.is_finite(l), T.F_uncertain{})
    case False{}: G.gerr(T.F_invalid{})

def dom_len(+d: G.Dom) -> G.GRes:
  G.Dom{+lo, +hi} = d
  dom_len_go(lo, hi, G.dom_valid(G.Dom{lo, hi}))

def dom_clamp_gt(+t: F64, +hi: F64, gt: Bool) -> G.GRes:
  match gt:
    case True{}: G.gok_f(hi)
    case False{}: G.gok_f(t)

def dom_clamp_lt(+t: F64, +lo: F64, +hi: F64, lt: Bool) -> G.GRes:
  match lt:
    case True{}: G.gok_f(lo)
    case False{}: dom_clamp_gt(t, hi, F64.is_gt(t, hi))

def dom_clamp_fin(+lo: F64, +hi: F64, +t: F64, ok: Bool) -> G.GRes:
  match ok:
    case True{}: dom_clamp_lt(t, lo, hi, F64.is_lt(t, lo))
    case False{}: G.gerr(T.F_invalid{})

def dom_clamp(+d: G.Dom, +t: F64) -> G.GRes:
  G.Dom{+lo, +hi} = d
  dom_clamp_fin(lo, hi, t,
    Bool.and(G.dom_valid(G.Dom{lo, hi}), T.is_finite(t)))

def pdom_wrap_hi(+t: F64, +lo: F64, +hi: F64, span: F64,
    under: Bool) -> G.GRes:
  match under:
    case True{}: G.gok_f(F64.add(t, span))
    case False{}: dom_clamp_gt(t, F64.sub(t, span), F64.is_gt(t, hi))

def pdom_wrap_go(+t: F64, +lo: F64, +hi: F64, +span: F64,
    ok: Bool, per: Bool) -> G.GRes:
  match ok:
    case True{}:
      match per:
        case True{}: pdom_wrap_hi(t, lo, hi, span, F64.is_lt(t, lo))
        case False{}: dom_clamp_lt(t, lo, hi, F64.is_lt(t, lo))
    case False{}: G.gerr(T.F_invalid{})

def pdom_wrap(+p: G.Pdom, +t: F64) -> G.GRes:
  G.Pdom{+d, +per} = p
  G.Dom{+lo, +hi} = d
  pdom_wrap_go(t, lo, hi, F64.sub(hi, lo),
    Bool.and(G.dom_valid(G.Dom{lo, hi}), T.is_finite(t)), per)

def dom_split_go(+lo: F64, +hi: F64, +t: F64, fin: Bool,
    inside: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match inside:
        case False{}: G.gerr(T.F_invalid{})
        case True{}: G.gok_dom(G.Dom{lo, t})

def dom_split_lo(+d: G.Dom, +t: F64) -> G.GRes:
  G.Dom{+lo, +hi} = d
  dom_split_go(lo, hi, t, G.dom_valid(G.Dom{lo, hi}),
    Bool.and(F64.is_lt(lo, t), F64.is_lt(t, hi)))

def dom_split_hi_go(+lo: F64, +hi: F64, +t: F64, fin: Bool,
    inside: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match inside:
        case False{}: G.gerr(T.F_invalid{})
        case True{}: G.gok_dom(G.Dom{t, hi})

def dom_split_hi(+d: G.Dom, +t: F64) -> G.GRes:
  G.Dom{+lo, +hi} = d
  dom_split_hi_go(lo, hi, t, G.dom_valid(G.Dom{lo, hi}),
    Bool.and(F64.is_lt(lo, t), F64.is_lt(t, hi)))

# --- Lines: evaluation, direction, projection, distance, bbox. ---
def line_eval_go(+p: V.Point, +d: V.Dir, +t: F64,
    ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      +q = pd_add_raw(p, t, d)
      gate_p(q, V.pt_fin(q), T.F_uncertain{})
    case False{}: G.gerr(T.F_invalid{})

def line_eval(+l: G.Line3, +t: F64) -> G.GRes:
  G.Ln{+p, +d} = l
  line_eval_go(p, d, t,
    Bool.and(G.ln_valid(G.Ln{p, d}), T.is_finite(t)))

def line_der_go(+d: V.Dir, ok: Bool) -> G.GRes:
  match ok:
    case True{}: G.gok_d(d)
    case False{}: G.gerr(T.F_invalid{})

def line_der(+l: G.Line3) -> G.GRes:
  G.Ln{+p, +d} = l
  line_der_go(d, G.ln_valid(G.Ln{p, d}))

# fin is semantic validity (zero direction -> invalid-input here);
# den == 0 past that gate is subnormal underflow of d.d, hence
# numerical-uncertainty, never a misattributed invalid-input.
def line_proj_go(+m: V.Dir, +d: V.Dir, den: F64, fin: Bool,
    zero: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match zero:
        case True{}: G.gerr(T.F_uncertain{})
        case False{}:
          +t = F64.div(dd_dot_raw(m, d), den)
          gate_f(t, T.is_finite(t), T.F_uncertain{})

def line_project(+l: G.Line3, +q: V.Point) -> G.GRes:
  G.Ln{+p, +d} = l
  +m = pp_sub_raw(q, p)
  +den = dd_dot_raw(d, d)
  line_proj_go(m, d, den,
    Bool.and(G.ln_valid(G.Ln{p, d}), V.pt_fin(q)),
    F64.is_eq(den, 0.0f64))

def line_dist_fin(+r: V.Dir, ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      +n = d3_norm_raw(r)
      gate_f(n, T.is_finite(n), T.F_uncertain{})
    case False{}: G.gerr(T.F_uncertain{})

def line_dist_go(+l: G.Line3, +q: V.Point, +t: F64, fin: Bool,
    zero: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match zero:
        case True{}: G.gerr(T.F_uncertain{})
        case False{}:
          +c = pd_add_raw(G.ln_p(l), t, G.ln_d(l))
          +r = pp_sub_raw(q, c)
          line_dist_fin(r, V.dr_fin(r))

def line_dist(+l: G.Line3, +q: V.Point) -> G.GRes:
  G.Ln{+p, +d} = l
  +m = pp_sub_raw(q, p)
  +den = dd_dot_raw(d, d)
  +t = F64.div(dd_dot_raw(m, d), den)
  line_dist_go(l, q, t,
    Bool.and(G.ln_valid(G.Ln{p, d}), V.pt_fin(q)),
    F64.is_eq(den, 0.0f64))

def seg_bbox_go(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64,
    +bz: F64, ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      G.gok_bb(G.Bb{V.Pt{F64.min(ax, bx), F64.min(ay, by),
        F64.min(az, bz)}, V.Pt{F64.max(ax, bx), F64.max(ay, by),
        F64.max(az, bz)}})
    case False{}: G.gerr(T.F_invalid{})

def line_seg_bbox(+a: V.Point, +b: V.Point) -> G.GRes:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  seg_bbox_go(ax, ay, az, bx, by, bz,
    Bool.and(V.pt_fin(V.Pt{ax, ay, az}),
      V.pt_fin(V.Pt{bx, by, bz})))

# --- Planes: frame validation, normal, evaluation, projection,
# distance, uv-rectangle enclosure (exact: evaluation is affine). ---
def plane_checked_go(+o: V.Point, +u: V.Dir, +v: V.Dir, fin: Bool,
    frame: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match frame:
        case False{}: G.gerr(T.F_invalid{})
        case True{}: G.gok_pl(G.Pl{o, u, v})

def plane_checked(+p: G.Plane3) -> G.GRes:
  G.Pl{+o, +u, +v} = p
  plane_checked_go(o, u, v, G.pl_fin(G.Pl{o, u, v}),
    uv_frame_ok(u, v))

def plane_normal_go(+u: V.Dir, +v: V.Dir, fin: Bool,
    frame: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match frame:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +n = dd_cross_raw(u, v)
          gate_d(n, V.dr_fin(n), T.F_uncertain{})

def plane_normal(+p: G.Plane3) -> G.GRes:
  G.Pl{+o, +u, +v} = p
  plane_normal_go(u, v, G.pl_fin(G.Pl{o, u, v}), uv_frame_ok(u, v))

def plane_eval_raw(+o: V.Point, +u: V.Dir, +v: V.Dir, +s: F64,
    +t: F64) -> V.Point:
  V.Pt{+ox, +oy, +oz} = o
  V.Dr{+ux, +uy, +uz} = u
  V.Dr{+vx, +vy, +vz} = v
  V.Pt{F64.add(ox, F64.add(F64.mul(s, ux), F64.mul(t, vx))),
    F64.add(oy, F64.add(F64.mul(s, uy), F64.mul(t, vy))),
    F64.add(oz, F64.add(F64.mul(s, uz), F64.mul(t, vz)))}

def plane_eval_go(+o: V.Point, +u: V.Dir, +v: V.Dir, +s: F64,
    +t: F64, fin: Bool, frame: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match frame:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +q = plane_eval_raw(o, u, v, s, t)
          gate_p(q, V.pt_fin(q), T.F_uncertain{})

def plane_eval(+p: G.Plane3, +s: F64, +t: F64) -> G.GRes:
  G.Pl{+o, +u, +v} = p
  plane_eval_go(o, u, v, s, t,
    Bool.and(G.pl_fin(G.Pl{o, u, v}),
      Bool.and(T.is_finite(s), T.is_finite(t))),
    uv_frame_ok(u, v))

def plane_proj_go(+m: V.Dir, +u: V.Dir, +v: V.Dir, fin: Bool,
    frame: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match frame:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +s = dd_dot_raw(m, u)
          +t = dd_dot_raw(m, v)
          gate_v2(V.V2{s, t}, V.v2_fin(V.V2{s, t}), T.F_uncertain{})

def plane_project(+p: G.Plane3, +q: V.Point) -> G.GRes:
  G.Pl{+o, +u, +v} = p
  +m = pp_sub_raw(q, o)
  plane_proj_go(m, u, v,
    Bool.and(G.pl_fin(G.Pl{o, u, v}), V.pt_fin(q)),
    uv_frame_ok(u, v))

def plane_dist_go(+m: V.Dir, +n: V.Dir, fin: Bool,
    frame: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match frame:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +d = dd_dot_raw(m, n)
          gate_f(d, T.is_finite(d), T.F_uncertain{})

def plane_dist(+p: G.Plane3, +q: V.Point) -> G.GRes:
  G.Pl{+o, +u, +v} = p
  +m = pp_sub_raw(q, o)
  +n = dd_cross_raw(u, v)
  plane_dist_go(m, n,
    Bool.and(G.pl_fin(G.Pl{o, u, v}), V.pt_fin(q)),
    uv_frame_ok(u, v))

# Hull of four finite corners (total on finite inputs; the caller
# gates). F64.min/max are exact on finite inputs.
def bbox4_raw(+a: V.Point, +b: V.Point, +c: V.Point,
    +d: V.Point) -> G.BBox3:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  V.Pt{+cx, +cy, +cz} = c
  V.Pt{+dx, +dy, +dz} = d
  G.Bb{V.Pt{F64.min(F64.min(ax, bx), F64.min(cx, dx)),
      F64.min(F64.min(ay, by), F64.min(cy, dy)),
      F64.min(F64.min(az, bz), F64.min(cz, dz))},
    V.Pt{F64.max(F64.max(ax, bx), F64.max(cx, dx)),
      F64.max(F64.max(ay, by), F64.max(cy, dy)),
      F64.max(F64.max(az, bz), F64.max(cz, dz))}}

def plane_uv_bbox_go(+c00: V.Point, +c01: V.Point, +c10: V.Point,
    +c11: V.Point, fin: Bool, frame: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match frame:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +b = bbox4_raw(c00, c01, c10, c11)
          gate_bb(b, G.bb_fin(b), T.F_uncertain{})

def plane_uv_bbox(+p: G.Plane3, +s0: F64, +s1: F64, +t0: F64,
    +t1: F64) -> G.GRes:
  G.Pl{+o, +u, +v} = p
  +c00 = plane_eval_raw(o, u, v, s0, t0)
  +c01 = plane_eval_raw(o, u, v, s0, t1)
  +c10 = plane_eval_raw(o, u, v, s1, t0)
  +c11 = plane_eval_raw(o, u, v, s1, t1)
  plane_uv_bbox_go(c00, c01, c10, c11,
    Bool.and(G.pl_fin(G.Pl{o, u, v}),
      Bool.and(T.is_finite(s0),
        Bool.and(T.is_finite(s1),
          Bool.and(T.is_finite(t0), T.is_finite(t1))))),
    uv_frame_ok(u, v))

# --- Rational circles: evaluation, derivative, seam, enclosure. ---
def circ_checked_go(+c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64,
    fin: Bool, frame: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match frame:
        case False{}: G.gerr(T.F_invalid{})
        case True{}: G.gok_cc(G.Cc{c, u, v, r})

def circ_checked(+c: G.Circle3) -> G.GRes:
  G.Cc{+c, +u, +v, +r} = c
  circ_checked_go(c, u, v, r, G.cc_valid(G.Cc{c, u, v, r}),
    uv_frame_ok(u, v))

def circ_eval_go(+c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64,
    +t: F64, fin: Bool, frame: Bool, dom: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match frame:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          match dom:
            case False{}: G.gerr(T.F_invalid{})
            case True{}:
              +t2 = F64.mul(t, t)
              +t4 = F64.mul(t2, t2)
              +s1 = F64.add(1.0f64, t2)
              +den = F64.mul(s1, s1)
              +nx = F64.div(F64.add(F64.sub(1.0f64,
                F64.mul(6.0f64, t2)), t4), den)
              +ny = F64.div(F64.mul(F64.mul(4.0f64, t),
                F64.sub(1.0f64, t2)), den)
              +q = pd_add_raw(pd_add_raw(c, F64.mul(r, nx), u),
                F64.mul(r, ny), v)
              gate_p(q, V.pt_fin(q), T.F_uncertain{})

def circ_eval(+c: G.Circle3, +t: F64) -> G.GRes:
  G.Cc{+c, +u, +v, +r} = c
  circ_eval_go(c, u, v, r, t, G.cc_valid(G.Cc{c, u, v, r}),
    uv_frame_ok(u, v),
    Bool.and(F64.is_le(F64.neg(1.0f64), t), F64.is_le(t, 1.0f64)))

def circ_der_go(+u: V.Dir, +v: V.Dir, +r: F64, +t: F64, fin: Bool,
    frame: Bool, dom: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match frame:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          match dom:
            case False{}: G.gerr(T.F_invalid{})
            case True{}:
              +t2 = F64.mul(t, t)
              +t3 = F64.mul(t2, t)
              +t4 = F64.mul(t2, t2)
              +s1 = F64.add(1.0f64, t2)
              +den = F64.mul(s1, s1)
              +n1 = F64.add(F64.sub(1.0f64, F64.mul(6.0f64, t2)),
                t4)
              +n2 = F64.mul(F64.mul(4.0f64, t),
                F64.sub(1.0f64, t2))
              +d1 = F64.add(F64.mul(F64.neg(12.0f64), t),
                F64.mul(4.0f64, t3))
              +d2 = F64.sub(4.0f64, F64.mul(12.0f64, t2))
              +dd = F64.add(F64.mul(4.0f64, t),
                F64.mul(4.0f64, t3))
              +den2 = F64.mul(den, den)
              +dx = F64.div(F64.sub(F64.mul(d1, den),
                F64.mul(n1, dd)), den2)
              +dy = F64.div(F64.sub(F64.mul(d2, den),
                F64.mul(n2, dd)), den2)
              +d = dd_add_raw(dd_scale_raw(F64.mul(r, dx), u),
                dd_scale_raw(F64.mul(r, dy), v))
              gate_d(d, V.dr_fin(d), T.F_uncertain{})

def circ_der(+c: G.Circle3, +t: F64) -> G.GRes:
  G.Cc{+c, +u, +v, +r} = c
  circ_der_go(u, v, r, t, G.cc_valid(G.Cc{c, u, v, r}),
    uv_frame_ok(u, v),
    Bool.and(F64.is_le(F64.neg(1.0f64), t), F64.is_le(t, 1.0f64)))

# Seam point: both t = 1 and t = -1 evaluate here (c - r*u).
def circ_seam_go(+c: V.Point, +u: V.Dir, +r: F64, fin: Bool,
    frame: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match frame:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +q = pd_add_raw(c, F64.neg(r), u)
          gate_p(q, V.pt_fin(q), T.F_uncertain{})

def circ_seam_pt(+c: G.Circle3) -> G.GRes:
  G.Cc{+c, +u, +v, +r} = c
  circ_seam_go(c, u, r, G.cc_valid(G.Cc{c, u, v, r}),
    uv_frame_ok(u, v))

# Coarse certified enclosure: |nx|, |ny| <= 1 for all t (nx^2+ny^2 =
# 1 exactly), so c +- r*(|u| + |v|) componentwise always contains C(t).
def circ_bbox_go(+cx: F64, +cy: F64, +cz: F64, +ux: F64,
    +uy: F64, +uz: F64, +vx: F64, +vy: F64, +vz: F64, +r: F64,
    fin: Bool, frame: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match frame:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +ex = F64.mul(r, F64.add(F64.abs(ux), F64.abs(vx)))
          +ey = F64.mul(r, F64.add(F64.abs(uy), F64.abs(vy)))
          +ez = F64.mul(r, F64.add(F64.abs(uz), F64.abs(vz)))
          +lx = F64.sub(cx, ex)
          +ly = F64.sub(cy, ey)
          +lz = F64.sub(cz, ez)
          +hx = F64.add(cx, ex)
          +hy = F64.add(cy, ey)
          +hz = F64.add(cz, ez)
          gate_bb(G.Bb{V.Pt{lx, ly, lz}, V.Pt{hx, hy, hz}},
            G.bb_fin(G.Bb{V.Pt{lx, ly, lz}, V.Pt{hx, hy, hz}}),
            T.F_uncertain{})

def circ_bbox(+c: G.Circle3) -> G.GRes:
  G.Cc{+c, +u, +v, +r} = c
  V.Pt{+cx, +cy, +cz} = c
  V.Dr{+ux, +uy, +uz} = u
  V.Dr{+vx, +vy, +vz} = v
  circ_bbox_go(cx, cy, cz, ux, uy, uz, vx, vy, vz, r,
    G.cc_valid(G.Cc{c, u, v, r}), uv_frame_ok(u, v))

# --- Cubic Beziers: evaluation (Bernstein, left-fold order), exact
# derivative, de Casteljau subdivision, control hull, endpoints. ---
def bez3_eval_go(+p0: V.Point, +p1: V.Point, +p2: V.Point,
    +p3: V.Point, +t: F64, fin: Bool, dom: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match dom:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +s = F64.sub(1.0f64, t)
          +s2 = F64.mul(s, s)
          +t2 = F64.mul(t, t)
          +b0 = F64.mul(s2, s)
          +b1 = F64.mul(3.0f64, F64.mul(s2, t))
          +b2 = F64.mul(3.0f64, F64.mul(s, t2))
          +b3 = F64.mul(t2, t)
          +q = pt_cubic_raw(p0, p1, p2, p3, b0, b1, b2, b3)
          gate_p(q, V.pt_fin(q), T.F_uncertain{})

def bez3_eval(+b: G.Bez3, +t: F64) -> G.GRes:
  G.Bz{+p0, +p1, +p2, +p3} = b
  bez3_eval_go(p0, p1, p2, p3, t, G.bz_fin(G.Bz{p0, p1, p2, p3}),
    Bool.and(F64.is_le(0.0f64, t), F64.is_le(t, 1.0f64)))

def bez3_der_go(+d0: V.Dir, +d1: V.Dir, +d2: V.Dir, +t: F64,
    fin: Bool, dom: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match dom:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +s = F64.sub(1.0f64, t)
          +c0 = F64.mul(s, s)
          +c1 = F64.mul(2.0f64, F64.mul(s, t))
          +c2 = F64.mul(t, t)
          +d = dr_quad_raw(d0, d1, d2, c0, c1, c2)
          gate_d(d, V.dr_fin(d), T.F_uncertain{})

def bez3_der(+b: G.Bez3, +t: F64) -> G.GRes:
  G.Bz{+p0, +p1, +p2, +p3} = b
  +d0 = dd_scale_raw(3.0f64, pp_sub_raw(p1, p0))
  +d1 = dd_scale_raw(3.0f64, pp_sub_raw(p2, p1))
  +d2 = dd_scale_raw(3.0f64, pp_sub_raw(p3, p2))
  bez3_der_go(d0, d1, d2, t, G.bz_fin(G.Bz{p0, p1, p2, p3}),
    Bool.and(F64.is_le(0.0f64, t), F64.is_le(t, 1.0f64)))

def bez3_split_lo_fin(+p0: V.Point, +a: V.Point, +d: V.Point,
    +f: V.Point, ok: Bool) -> G.GRes:
  match ok:
    case True{}: G.gok_bz(G.Bz{p0, a, d, f})
    case False{}: G.gerr(T.F_uncertain{})

def bez3_split_lo_go(+p0: V.Point, +a: V.Point, +d: V.Point,
    +f: V.Point, fin: Bool, inside: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match inside:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          bez3_split_lo_fin(p0, a, d, f,
            Bool.and(V.pt_fin(a),
              Bool.and(V.pt_fin(d), V.pt_fin(f))))

def bez3_split_lo(+b: G.Bez3, +t: F64) -> G.GRes:
  G.Bz{+p0, +p1, +p2, +p3} = b
  +s = F64.sub(1.0f64, t)
  +a = plerp_raw(p0, p1, s, t)
  +bb = plerp_raw(p1, p2, s, t)
  +c = plerp_raw(p2, p3, s, t)
  +d = plerp_raw(a, bb, s, t)
  +e = plerp_raw(bb, c, s, t)
  +f = plerp_raw(d, e, s, t)
  bez3_split_lo_go(p0, a, d, f, G.bz_fin(G.Bz{p0, p1, p2, p3}),
    Bool.and(F64.is_lt(0.0f64, t), F64.is_lt(t, 1.0f64)))

def bez3_split_hi_fin(+f: V.Point, +e: V.Point, +c: V.Point,
    +p3: V.Point, ok: Bool) -> G.GRes:
  match ok:
    case True{}: G.gok_bz(G.Bz{f, e, c, p3})
    case False{}: G.gerr(T.F_uncertain{})

def bez3_split_hi_go(+f: V.Point, +e: V.Point, +c: V.Point,
    +p3: V.Point, fin: Bool, inside: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match inside:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          bez3_split_hi_fin(f, e, c, p3,
            Bool.and(V.pt_fin(f),
              Bool.and(V.pt_fin(e), V.pt_fin(c))))

def bez3_split_hi(+b: G.Bez3, +t: F64) -> G.GRes:
  G.Bz{+p0, +p1, +p2, +p3} = b
  +s = F64.sub(1.0f64, t)
  +a = plerp_raw(p0, p1, s, t)
  +bb = plerp_raw(p1, p2, s, t)
  +c = plerp_raw(p2, p3, s, t)
  +d = plerp_raw(a, bb, s, t)
  +e = plerp_raw(bb, c, s, t)
  +f = plerp_raw(d, e, s, t)
  bez3_split_hi_go(f, e, c, p3, G.bz_fin(G.Bz{p0, p1, p2, p3}),
    Bool.and(F64.is_lt(0.0f64, t), F64.is_lt(t, 1.0f64)))

def bez3_bbox_go(+p0: V.Point, +p1: V.Point, +p2: V.Point,
    +p3: V.Point, ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      +b = bbox4_raw(p0, p1, p2, p3)
      gate_bb(b, G.bb_fin(b), T.F_uncertain{})
    case False{}: G.gerr(T.F_invalid{})

def bez3_bbox(+b: G.Bez3) -> G.GRes:
  G.Bz{+p0, +p1, +p2, +p3} = b
  bez3_bbox_go(p0, p1, p2, p3, G.bz_fin(G.Bz{p0, p1, p2, p3}))

def bez3_end_go(+p: V.Point, ok: Bool) -> G.GRes:
  match ok:
    case True{}: G.gok_p(p)
    case False{}: G.gerr(T.F_invalid{})

def bez3_end0(+b: G.Bez3) -> G.GRes:
  G.Bz{+p0, +p1, +p2, +p3} = b
  bez3_end_go(p0, G.bz_fin(G.Bz{p0, p1, p2, p3}))

def bez3_end1(+b: G.Bez3) -> G.GRes:
  G.Bz{+p0, +p1, +p2, +p3} = b
  bez3_end_go(p3, G.bz_fin(G.Bz{p0, p1, p2, p3}))

# --- Rational quadratic Beziers = conic arcs: evaluation, quotient-rule
# derivative, hull (certified for positive weights), discriminant,
# quarter-circle constructor. den = sum wB > 0 always: weights are
# positive, B >= 0 on [0, 1], sum B = 1. ---
def rqb_eval_go(+p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64,
    +w1: F64, +w2: F64, +t: F64, fin: Bool, dom: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match dom:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +s = F64.sub(1.0f64, t)
          +b0 = F64.mul(s, s)
          +b1 = F64.mul(2.0f64, F64.mul(s, t))
          +b2 = F64.mul(t, t)
          +c0 = F64.mul(w0, b0)
          +c1 = F64.mul(w1, b1)
          +c2 = F64.mul(w2, b2)
          +den = F64.add(F64.add(c0, c1), c2)
          +num = pt_quad_raw(p0, p1, p2, c0, c1, c2)
          +nx = V.pt_x(num)
          +ny = V.pt_y(num)
          +nz = V.pt_z(num)
          +qx = F64.div(nx, den)
          +qy = F64.div(ny, den)
          +qz = F64.div(nz, den)
          gate_p(V.Pt{qx, qy, qz}, V.pt_fin(V.Pt{qx, qy, qz}),
            T.F_uncertain{})

def rqb_eval(+b: G.RQBez, +t: F64) -> G.GRes:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = b
  rqb_eval_go(p0, p1, p2, w0, w1, w2, t,
    G.rq_valid(G.Rq{p0, p1, p2, w0, w1, w2}),
    Bool.and(F64.is_le(0.0f64, t), F64.is_le(t, 1.0f64)))

# N = sum wB p, D = sum wB; d = (N' D - N D') / D^2 with the exact
# quadratic derivatives N' = 2((w1p1-w0p0)s + (w2p2-w1p1)t),
# D' = 2((w1-w0)s + (w2-w1)t).
def wq_der_raw(+p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64,
    +w1: F64, +w2: F64, +s: F64, +t: F64) -> V.Dir:
  V.Pt{+x0, +y0, +z0} = p0
  V.Pt{+x1, +y1, +z1} = p1
  V.Pt{+x2, +y2, +z2} = p2
  V.Dr{F64.mul(2.0f64, F64.add(
      F64.mul(F64.sub(F64.mul(w1, x1), F64.mul(w0, x0)), s),
      F64.mul(F64.sub(F64.mul(w2, x2), F64.mul(w1, x1)), t))),
    F64.mul(2.0f64, F64.add(
      F64.mul(F64.sub(F64.mul(w1, y1), F64.mul(w0, y0)), s),
      F64.mul(F64.sub(F64.mul(w2, y2), F64.mul(w1, y1)), t))),
    F64.mul(2.0f64, F64.add(
      F64.mul(F64.sub(F64.mul(w1, z1), F64.mul(w0, z0)), s),
      F64.mul(F64.sub(F64.mul(w2, z2), F64.mul(w1, z1)), t)))}

def rqb_der_go(+p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64,
    +w1: F64, +w2: F64, +t: F64, fin: Bool, dom: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match dom:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +s = F64.sub(1.0f64, t)
          +b0 = F64.mul(s, s)
          +b1 = F64.mul(2.0f64, F64.mul(s, t))
          +b2 = F64.mul(t, t)
          +c0 = F64.mul(w0, b0)
          +c1 = F64.mul(w1, b1)
          +c2 = F64.mul(w2, b2)
          +den = F64.add(F64.add(c0, c1), c2)
          +num = pt_quad_raw(p0, p1, p2, c0, c1, c2)
          +nx = V.pt_x(num)
          +ny = V.pt_y(num)
          +nz = V.pt_z(num)
          +e0 = F64.sub(w1, w0)
          +e1 = F64.sub(w2, w1)
          +dd = F64.mul(2.0f64, F64.add(F64.mul(e0, s),
            F64.mul(e1, t)))
          +np = wq_der_raw(p0, p1, p2, w0, w1, w2, s, t)
          +gx = V.dr_x(np)
          +gy = V.dr_y(np)
          +gz = V.dr_z(np)
          +den2 = F64.mul(den, den)
          +dx = F64.div(F64.sub(F64.mul(gx, den), F64.mul(nx, dd)),
            den2)
          +dy = F64.div(F64.sub(F64.mul(gy, den), F64.mul(ny, dd)),
            den2)
          +dz = F64.div(F64.sub(F64.mul(gz, den), F64.mul(nz, dd)),
            den2)
          gate_d(V.Dr{dx, dy, dz},
            V.dr_fin(V.Dr{dx, dy, dz}), T.F_uncertain{})

def rqb_der(+b: G.RQBez, +t: F64) -> G.GRes:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = b
  rqb_der_go(p0, p1, p2, w0, w1, w2, t,
    G.rq_valid(G.Rq{p0, p1, p2, w0, w1, w2}),
    Bool.and(F64.is_le(0.0f64, t), F64.is_le(t, 1.0f64)))

def rqb_bbox_go(+p0: V.Point, +p1: V.Point, +p2: V.Point,
    ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      +b = bbox4_raw(p0, p1, p2, p2)
      gate_bb(b, G.bb_fin(b), T.F_uncertain{})
    case False{}: G.gerr(T.F_invalid{})

def rqb_bbox(+b: G.RQBez) -> G.GRes:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = b
  rqb_bbox_go(p0, p1, p2, G.rq_valid(G.Rq{p0, p1, p2, w0, w1, w2}))

# Discriminant of the supporting conic: w1^2 - w0*w2. Negative =
# ellipse, zero = parabola, positive = hyperbola branch (stated
# standard classification; contract §5).
def rqb_disc_go(+w0: F64, +w1: F64, +w2: F64,
    ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      +d = F64.sub(F64.mul(w1, w1), F64.mul(w0, w2))
      gate_f(d, T.is_finite(d), T.F_uncertain{})
    case False{}: G.gerr(T.F_invalid{})

def rqb_disc(+b: G.RQBez) -> G.GRes:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = b
  rqb_disc_go(w0, w1, w2, G.rq_valid(G.Rq{p0, p1, p2, w0, w1, w2}))

# Rational quarter circle: p0 = c+r*u, p1 = c+r*u+r*v, p2 = c+r*v
# with weights (1, sqrt2/2, 1). Exact circle in exact arithmetic.
def rq_quarter_fin(+p0: V.Point, +p1: V.Point, +p2: V.Point,
    ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      G.gok_rq(G.Rq{p0, p1, p2, 1.0f64, G.w_quarter(), 1.0f64})
    case False{}: G.gerr(T.F_uncertain{})

def rq_quarter_go(+p0: V.Point, +p1: V.Point, +p2: V.Point,
    fin: Bool, frame: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match frame:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          rq_quarter_fin(p0, p1, p2,
            Bool.and(V.pt_fin(p0),
              Bool.and(V.pt_fin(p1), V.pt_fin(p2))))

def rq_quarter(+c: V.Point, +u: V.Dir, +v: V.Dir,
    +r: F64) -> G.GRes:
  +p0 = pd_add_raw(c, r, u)
  +p1 = pd_add_raw(pd_add_raw(c, r, u), r, v)
  +p2 = pd_add_raw(c, r, v)
  rq_quarter_go(p0, p1, p2,
    Bool.and(V.pt_fin(c),
      Bool.and(V.dr_fin(u),
        Bool.and(V.dr_fin(v), T.is_finite(r)))),
    Bool.and(uv_frame_ok(u, v), G.spos(r)))

# --- Bicubic patches: tensor evaluation (rows in u, then column in
# v), exact partials, 16-point hull, iso-curves, corners. ---
def bezp_eval_go(+p00: V.Point, +p01: V.Point, +p02: V.Point,
    +p03: V.Point, +p10: V.Point, +p11: V.Point, +p12: V.Point,
    +p13: V.Point, +p20: V.Point, +p21: V.Point, +p22: V.Point,
    +p23: V.Point, +p30: V.Point, +p31: V.Point, +p32: V.Point,
    +p33: V.Point, +u: F64, +v: F64, fin: Bool,
    dom: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match dom:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +su = F64.sub(1.0f64, u)
          +su2 = F64.mul(su, su)
          +u2 = F64.mul(u, u)
          +a0 = F64.mul(su2, su)
          +a1 = F64.mul(3.0f64, F64.mul(su2, u))
          +a2 = F64.mul(3.0f64, F64.mul(su, u2))
          +a3 = F64.mul(u2, u)
          +sv = F64.sub(1.0f64, v)
          +sv2 = F64.mul(sv, sv)
          +v2 = F64.mul(v, v)
          +c0 = F64.mul(sv2, sv)
          +c1 = F64.mul(3.0f64, F64.mul(sv2, v))
          +c2 = F64.mul(3.0f64, F64.mul(sv, v2))
          +c3 = F64.mul(v2, v)
          +r0 = pt_cubic_raw(p00, p01, p02, p03, a0, a1, a2, a3)
          +r1 = pt_cubic_raw(p10, p11, p12, p13, a0, a1, a2, a3)
          +r2 = pt_cubic_raw(p20, p21, p22, p23, a0, a1, a2, a3)
          +r3 = pt_cubic_raw(p30, p31, p32, p33, a0, a1, a2, a3)
          +q = pt_cubic_raw(r0, r1, r2, r3, c0, c1, c2, c3)
          gate_p(q, V.pt_fin(q), T.F_uncertain{})

def bezp_eval(+b: G.BezP, +u: F64, +v: F64) -> G.GRes:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21,
    +p22, +p23, +p30, +p31, +p32, +p33} = b
  bezp_eval_go(p00, p01, p02, p03, p10, p11, p12, p13, p20, p21,
    p22, p23, p30, p31, p32, p33, u, v,
    G.bp_fin(G.Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20,
      p21, p22, p23, p30, p31, p32, p33}),
    Bool.and(Bool.and(F64.is_le(0.0f64, u), F64.is_le(u, 1.0f64)),
      Bool.and(F64.is_le(0.0f64, v), F64.is_le(v, 1.0f64))))

# d/du: cubic in v of the four row-derivatives at u.
def bezp_du_go(+p00: V.Point, +p01: V.Point, +p02: V.Point,
    +p03: V.Point, +p10: V.Point, +p11: V.Point, +p12: V.Point,
    +p13: V.Point, +p20: V.Point, +p21: V.Point, +p22: V.Point,
    +p23: V.Point, +p30: V.Point, +p31: V.Point, +p32: V.Point,
    +p33: V.Point, +u: F64, +v: F64, fin: Bool,
    dom: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match dom:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +su = F64.sub(1.0f64, u)
          +e0 = F64.mul(su, su)
          +e1 = F64.mul(2.0f64, F64.mul(su, u))
          +e2 = F64.mul(u, u)
          +sv = F64.sub(1.0f64, v)
          +sv2 = F64.mul(sv, sv)
          +v2 = F64.mul(v, v)
          +c0 = F64.mul(sv2, sv)
          +c1 = F64.mul(3.0f64, F64.mul(sv2, v))
          +c2 = F64.mul(3.0f64, F64.mul(sv, v2))
          +c3 = F64.mul(v2, v)
          +g0 = dr_quad_raw(dd_scale_raw(3.0f64, pp_sub_raw(p01,
            p00)), dd_scale_raw(3.0f64, pp_sub_raw(p02, p01)),
            dd_scale_raw(3.0f64, pp_sub_raw(p03, p02)), e0, e1, e2)
          +g1 = dr_quad_raw(dd_scale_raw(3.0f64, pp_sub_raw(p11,
            p10)), dd_scale_raw(3.0f64, pp_sub_raw(p12, p11)),
            dd_scale_raw(3.0f64, pp_sub_raw(p13, p12)), e0, e1, e2)
          +g2 = dr_quad_raw(dd_scale_raw(3.0f64, pp_sub_raw(p21,
            p20)), dd_scale_raw(3.0f64, pp_sub_raw(p22, p21)),
            dd_scale_raw(3.0f64, pp_sub_raw(p23, p22)), e0, e1, e2)
          +g3 = dr_quad_raw(dd_scale_raw(3.0f64, pp_sub_raw(p31,
            p30)), dd_scale_raw(3.0f64, pp_sub_raw(p32, p31)),
            dd_scale_raw(3.0f64, pp_sub_raw(p33, p32)), e0, e1, e2)
          +x0 = V.dr_x(g0)
          +y0 = V.dr_y(g0)
          +z0 = V.dr_z(g0)
          +x1 = V.dr_x(g1)
          +y1 = V.dr_y(g1)
          +z1 = V.dr_z(g1)
          +x2 = V.dr_x(g2)
          +y2 = V.dr_y(g2)
          +z2 = V.dr_z(g2)
          +x3 = V.dr_x(g3)
          +y3 = V.dr_y(g3)
          +z3 = V.dr_z(g3)
          +dx = F64.add(F64.add(F64.add(F64.mul(c0, x0),
            F64.mul(c1, x1)), F64.mul(c2, x2)), F64.mul(c3, x3))
          +dy = F64.add(F64.add(F64.add(F64.mul(c0, y0),
            F64.mul(c1, y1)), F64.mul(c2, y2)), F64.mul(c3, y3))
          +dz = F64.add(F64.add(F64.add(F64.mul(c0, z0),
            F64.mul(c1, z1)), F64.mul(c2, z2)), F64.mul(c3, z3))
          gate_d(V.Dr{dx, dy, dz}, V.dr_fin(V.Dr{dx, dy, dz}),
            T.F_uncertain{})

def bezp_du(+b: G.BezP, +u: F64, +v: F64) -> G.GRes:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21,
    +p22, +p23, +p30, +p31, +p32, +p33} = b
  bezp_du_go(p00, p01, p02, p03, p10, p11, p12, p13, p20, p21,
    p22, p23, p30, p31, p32, p33, u, v,
    G.bp_fin(G.Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20,
      p21, p22, p23, p30, p31, p32, p33}),
    Bool.and(Bool.and(F64.is_le(0.0f64, u), F64.is_le(u, 1.0f64)),
      Bool.and(F64.is_le(0.0f64, v), F64.is_le(v, 1.0f64))))

# d/dv: cubic-derivative of the four row-evals at (u, v).
def bezp_dv_go(+p00: V.Point, +p01: V.Point, +p02: V.Point,
    +p03: V.Point, +p10: V.Point, +p11: V.Point, +p12: V.Point,
    +p13: V.Point, +p20: V.Point, +p21: V.Point, +p22: V.Point,
    +p23: V.Point, +p30: V.Point, +p31: V.Point, +p32: V.Point,
    +p33: V.Point, +u: F64, +v: F64, fin: Bool,
    dom: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match dom:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +su = F64.sub(1.0f64, u)
          +su2 = F64.mul(su, su)
          +u2 = F64.mul(u, u)
          +a0 = F64.mul(su2, su)
          +a1 = F64.mul(3.0f64, F64.mul(su2, u))
          +a2 = F64.mul(3.0f64, F64.mul(su, u2))
          +a3 = F64.mul(u2, u)
          +sv = F64.sub(1.0f64, v)
          +e0 = F64.mul(sv, sv)
          +e1 = F64.mul(2.0f64, F64.mul(sv, v))
          +e2 = F64.mul(v, v)
          +r0 = pt_cubic_raw(p00, p01, p02, p03, a0, a1, a2, a3)
          +r1 = pt_cubic_raw(p10, p11, p12, p13, a0, a1, a2, a3)
          +r2 = pt_cubic_raw(p20, p21, p22, p23, a0, a1, a2, a3)
          +r3 = pt_cubic_raw(p30, p31, p32, p33, a0, a1, a2, a3)
          +d = dr_quad_raw(dd_scale_raw(3.0f64, pp_sub_raw(r1,
            r0)), dd_scale_raw(3.0f64, pp_sub_raw(r2, r1)),
            dd_scale_raw(3.0f64, pp_sub_raw(r3, r2)), e0, e1, e2)
          gate_d(d, V.dr_fin(d), T.F_uncertain{})

def bezp_dv(+b: G.BezP, +u: F64, +v: F64) -> G.GRes:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21,
    +p22, +p23, +p30, +p31, +p32, +p33} = b
  bezp_dv_go(p00, p01, p02, p03, p10, p11, p12, p13, p20, p21,
    p22, p23, p30, p31, p32, p33, u, v,
    G.bp_fin(G.Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20,
      p21, p22, p23, p30, p31, p32, p33}),
    Bool.and(Bool.and(F64.is_le(0.0f64, u), F64.is_le(u, 1.0f64)),
      Bool.and(F64.is_le(0.0f64, v), F64.is_le(v, 1.0f64))))

# Box union (total; exact on finite inputs).
def bb_union_raw(+a: G.BBox3, +b: G.BBox3) -> G.BBox3:
  +alo = G.bb_lo(a)
  +ahi = G.bb_hi(a)
  +blo = G.bb_lo(b)
  +bhi = G.bb_hi(b)
  +alx = V.pt_x(alo)
  +aly = V.pt_y(alo)
  +alz = V.pt_z(alo)
  +ahx = V.pt_x(ahi)
  +ahy = V.pt_y(ahi)
  +ahz = V.pt_z(ahi)
  +blx = V.pt_x(blo)
  +bly = V.pt_y(blo)
  +blz = V.pt_z(blo)
  +bhx = V.pt_x(bhi)
  +bhy = V.pt_y(bhi)
  +bhz = V.pt_z(bhi)
  G.Bb{V.Pt{F64.min(alx, blx), F64.min(aly, bly),
      F64.min(alz, blz)},
    V.Pt{F64.max(ahx, bhx), F64.max(ahy, bhy), F64.max(ahz, bhz)}}

def bbox_union_go(+a: G.BBox3, +b: G.BBox3, ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      +u = bb_union_raw(a, b)
      gate_bb(u, G.bb_fin(u), T.F_uncertain{})
    case False{}: G.gerr(T.F_invalid{})

def bbox_union(+a: G.BBox3, +b: G.BBox3) -> G.GRes:
  bbox_union_go(a, b, Bool.and(G.bb_fin(a), G.bb_fin(b)))

def bezp_bbox_go(+p00: V.Point, +p01: V.Point, +p02: V.Point,
    +p03: V.Point, +p10: V.Point, +p11: V.Point, +p12: V.Point,
    +p13: V.Point, +p20: V.Point, +p21: V.Point, +p22: V.Point,
    +p23: V.Point, +p30: V.Point, +p31: V.Point, +p32: V.Point,
    +p33: V.Point, ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      +b0 = bbox4_raw(p00, p01, p02, p03)
      +b1 = bbox4_raw(p10, p11, p12, p13)
      +b2 = bbox4_raw(p20, p21, p22, p23)
      +b3 = bbox4_raw(p30, p31, p32, p33)
      +u = bb_union_raw(bb_union_raw(b0, b1), bb_union_raw(b2, b3))
      gate_bb(u, G.bb_fin(u), T.F_uncertain{})
    case False{}: G.gerr(T.F_invalid{})

def bezp_bbox(+b: G.BezP) -> G.GRes:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21,
    +p22, +p23, +p30, +p31, +p32, +p33} = b
  bezp_bbox_go(p00, p01, p02, p03, p10, p11, p12, p13, p20, p21,
    p22, p23, p30, p31, p32, p33,
    G.bp_fin(G.Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20,
      p21, p22, p23, p30, p31, p32, p33}))

# Iso-curves are exact cubic Beziers: iso_u fixes u (curve in v over
# row-evals), iso_v fixes v (curve in u over column-evals).
def bezp_iso_fin(+c0: V.Point, +c1: V.Point, +c2: V.Point,
    +c3: V.Point, ok: Bool) -> G.GRes:
  match ok:
    case True{}: G.gok_bz(G.Bz{c0, c1, c2, c3})
    case False{}: G.gerr(T.F_uncertain{})

def bezp_iso_u_go(+c0: V.Point, +c1: V.Point, +c2: V.Point,
    +c3: V.Point, fin: Bool, dom: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match dom:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          bezp_iso_fin(c0, c1, c2, c3,
            Bool.and(V.pt_fin(c0),
              Bool.and(V.pt_fin(c1),
                Bool.and(V.pt_fin(c2), V.pt_fin(c3)))))

def bezp_iso_u(+b: G.BezP, +u: F64) -> G.GRes:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21,
    +p22, +p23, +p30, +p31, +p32, +p33} = b
  +su = F64.sub(1.0f64, u)
  +su2 = F64.mul(su, su)
  +u2 = F64.mul(u, u)
  +a0 = F64.mul(su2, su)
  +a1 = F64.mul(3.0f64, F64.mul(su2, u))
  +a2 = F64.mul(3.0f64, F64.mul(su, u2))
  +a3 = F64.mul(u2, u)
  +r0 = pt_cubic_raw(p00, p01, p02, p03, a0, a1, a2, a3)
  +r1 = pt_cubic_raw(p10, p11, p12, p13, a0, a1, a2, a3)
  +r2 = pt_cubic_raw(p20, p21, p22, p23, a0, a1, a2, a3)
  +r3 = pt_cubic_raw(p30, p31, p32, p33, a0, a1, a2, a3)
  bezp_iso_u_go(r0, r1, r2, r3,
    G.bp_fin(G.Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20,
      p21, p22, p23, p30, p31, p32, p33}),
    Bool.and(F64.is_le(0.0f64, u), F64.is_le(u, 1.0f64)))

def bezp_iso_v_go(+c0: V.Point, +c1: V.Point, +c2: V.Point,
    +c3: V.Point, fin: Bool, dom: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match dom:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          bezp_iso_fin(c0, c1, c2, c3,
            Bool.and(V.pt_fin(c0),
              Bool.and(V.pt_fin(c1),
                Bool.and(V.pt_fin(c2), V.pt_fin(c3)))))

def bezp_iso_v(+b: G.BezP, +v: F64) -> G.GRes:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21,
    +p22, +p23, +p30, +p31, +p32, +p33} = b
  +sv = F64.sub(1.0f64, v)
  +sv2 = F64.mul(sv, sv)
  +v2 = F64.mul(v, v)
  +c0 = F64.mul(sv2, sv)
  +c1 = F64.mul(3.0f64, F64.mul(sv2, v))
  +c2 = F64.mul(3.0f64, F64.mul(sv, v2))
  +c3 = F64.mul(v2, v)
  +q0 = pt_cubic_raw(p00, p10, p20, p30, c0, c1, c2, c3)
  +q1 = pt_cubic_raw(p01, p11, p21, p31, c0, c1, c2, c3)
  +q2 = pt_cubic_raw(p02, p12, p22, p32, c0, c1, c2, c3)
  +q3 = pt_cubic_raw(p03, p13, p23, p33, c0, c1, c2, c3)
  bezp_iso_v_go(q0, q1, q2, q3,
    G.bp_fin(G.Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20,
      p21, p22, p23, p30, p31, p32, p33}),
    Bool.and(F64.is_le(0.0f64, v), F64.is_le(v, 1.0f64)))

def bezp_corner_go(+p: V.Point, ok: Bool) -> G.GRes:
  match ok:
    case True{}: G.gok_p(p)
    case False{}: G.gerr(T.F_invalid{})

def bezp_c00(+b: G.BezP) -> G.GRes:
  bezp_corner_go(G.bp_c00(b), G.bp_fin(b))

def bezp_c03(+b: G.BezP) -> G.GRes:
  bezp_corner_go(G.bp_c03(b), G.bp_fin(b))

def bezp_c30(+b: G.BezP) -> G.GRes:
  bezp_corner_go(G.bp_c30(b), G.bp_fin(b))

def bezp_c33(+b: G.BezP) -> G.GRes:
  bezp_corner_go(G.bp_c33(b), G.bp_fin(b))

# --- Quadrics: unit-axis validation, implicit value + exact gradient,
# sphere projection and poles, cone nappe coordinate. All formulas
# assume a unit axis (enforced by *_checked); m = q - o throughout. ---
def cyl_checked_go(+o: V.Point, +a: V.Dir, +r: F64, fin: Bool,
    unit: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match unit:
        case False{}: G.gerr(T.F_invalid{})
        case True{}: G.gok_cy(G.Cy{o, a, r})

def cyl_checked(+s: G.Cyl) -> G.GRes:
  G.Cy{+o, +a, +r} = s
  cyl_checked_go(o, a, r, G.cy_valid(G.Cy{o, a, r}), ax_unit_ok(a))

def cone_checked_go(+o: V.Point, +a: V.Dir, +k: F64, fin: Bool,
    unit: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match unit:
        case False{}: G.gerr(T.F_invalid{})
        case True{}: G.gok_co(G.Co{o, a, k})

def cone_checked(+s: G.Cone) -> G.GRes:
  G.Co{+o, +a, +k} = s
  cone_checked_go(o, a, k, G.co_valid(G.Co{o, a, k}), ax_unit_ok(a))

def tor_checked_go(+o: V.Point, +a: V.Dir, +R: F64, +r: F64,
    fin: Bool, unit: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match unit:
        case False{}: G.gerr(T.F_invalid{})
        case True{}: G.gok_to(G.To{o, a, R, r})

def tor_checked(+s: G.Torus) -> G.GRes:
  G.To{+o, +a, +R, +r} = s
  tor_checked_go(o, a, R, r, G.to_valid(G.To{o, a, R, r}),
    ax_unit_ok(a))

# Sphere: val = m.m - r^2, grad = 2m.
def sph_val_go(+m: V.Dir, +r: F64, +q: V.Point, ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      +v = F64.sub(dd_dot_raw(m, m), F64.mul(r, r))
      gate_f(v, T.is_finite(v), T.F_uncertain{})
    case False{}: G.gerr(T.F_invalid{})

def sph_val(+s: G.Sphere, +q: V.Point) -> G.GRes:
  G.Sp{+c, +r} = s
  +m = pp_sub_raw(q, c)
  sph_val_go(m, r, q,
    Bool.and(G.sp_valid(G.Sp{c, r}), V.pt_fin(q)))

def sph_grad_go(+m: V.Dir, ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      +g = dd_scale_raw(2.0f64, m)
      gate_d(g, V.dr_fin(g), T.F_uncertain{})
    case False{}: G.gerr(T.F_invalid{})

def sph_grad(+s: G.Sphere, +q: V.Point) -> G.GRes:
  G.Sp{+c, +r} = s
  +m = pp_sub_raw(q, c)
  sph_grad_go(m, Bool.and(G.sp_valid(G.Sp{c, r}), V.pt_fin(q)))

# Sphere projection: c + r*u with u = (m/M)/(n/M), M = max|m_i|;
# q == c is invalid-input (coincident, like C01 seg_dir), never a
# guessed pole. The scalar r/n is NEVER formed: it underflows to
# zero when r << n (r/n <= 2^-1075, the exact halfway value
# 2^-1075 itself rounding to zero under ties-to-even; e.g. r near
# DBL_MIN at a far-field query), collapsing (r/n)*m onto the
# published center;
# even at r = 1, m = (DBL_MAX,0,0) the old spelling lost 1 ulp.
# Here n/M lies in [1, sqrt(3)] and (m/M) in [-1, 1], so the unit
# direction survives every finite scale; the result is re-validated.
def sph_proj_q_raw(+c: V.Point, +r: F64, +mx: F64, +my: F64, +mz: F64,
    +M: F64, +nM: F64) -> V.Point:
  +ux = F64.div(F64.div(mx, M), nM)
  +uy = F64.div(F64.div(my, M), nM)
  +uz = F64.div(F64.div(mz, M), nM)
  pd_add_raw(c, r, V.Dr{ux, uy, uz})

def sph_proj_zero(+c: V.Point, +r: F64, +m: V.Dir, +n: F64,
    zero: Bool, nfin: Bool) -> G.GRes:
  match zero:
    case True{}: G.gerr(T.F_invalid{})
    case False{}:
      match nfin:
        case False{}: G.gerr(T.F_uncertain{})
        case True{}:
          +mx = V.dr_x(m)
          +my = V.dr_y(m)
          +mz = V.dr_z(m)
          +M = F64.max(F64.abs(mx), F64.max(F64.abs(my),
            F64.abs(mz)))
          +q = sph_proj_q_raw(c, r, mx, my, mz, M, F64.div(n, M))
          gate_p(q, V.pt_fin(q), T.F_uncertain{})

def sph_proj_go(+c: V.Point, +r: F64, +m: V.Dir, +n: F64,
    fin: Bool, zero: Bool, nfin: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}: sph_proj_zero(c, r, m, n, zero, nfin)

def sph_project(+s: G.Sphere, +q: V.Point) -> G.GRes:
  G.Sp{+c, +r} = s
  +m = pp_sub_raw(q, c)
  +n = d3_norm_raw(m)
  sph_proj_go(c, r, m, n,
    Bool.and(G.sp_valid(G.Sp{c, r}), V.pt_fin(q)),
    F64.is_eq(n, 0.0f64), T.is_finite(n))

# Sphere poles along an explicit unit axis: c +- r*a.
def sph_pole_go(+c: V.Point, +a: V.Dir, +r: F64, fin: Bool,
    unit: Bool, north: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match unit:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          match north:
            case True{}:
              +q = pd_add_raw(c, r, a)
              gate_p(q, V.pt_fin(q), T.F_uncertain{})
            case False{}:
              +q = pd_add_raw(c, F64.neg(r), a)
              gate_p(q, V.pt_fin(q), T.F_uncertain{})

def sph_pole_n(+s: G.Sphere, +a: V.Dir) -> G.GRes:
  G.Sp{+c, +r} = s
  sph_pole_go(c, a, r,
    Bool.and(G.sp_valid(G.Sp{c, r}), V.dr_fin(a)), ax_unit_ok(a),
    True{})

def sph_pole_s(+s: G.Sphere, +a: V.Dir) -> G.GRes:
  G.Sp{+c, +r} = s
  sph_pole_go(c, a, r,
    Bool.and(G.sp_valid(G.Sp{c, r}), V.dr_fin(a)), ax_unit_ok(a),
    False{})

# Cylinder: ax = m.a; val = (m.m - ax^2) - r^2;
# grad = 2(m - ax*a).
def cyl_val_go(+m: V.Dir, +a: V.Dir, +r: F64, fin: Bool,
    unit: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match unit:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +ax = dd_dot_raw(m, a)
          +v = F64.sub(F64.sub(dd_dot_raw(m, m), F64.mul(ax, ax)),
            F64.mul(r, r))
          gate_f(v, T.is_finite(v), T.F_uncertain{})

def cyl_val(+s: G.Cyl, +q: V.Point) -> G.GRes:
  G.Cy{+o, +a, +r} = s
  +m = pp_sub_raw(q, o)
  cyl_val_go(m, a, r,
    Bool.and(G.cy_valid(G.Cy{o, a, r}), V.pt_fin(q)), ax_unit_ok(a))

def cyl_grad_go(+m: V.Dir, +a: V.Dir, fin: Bool,
    unit: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match unit:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +ax = dd_dot_raw(m, a)
          +g = dd_scale_raw(2.0f64,
            dd_sub_raw(m, dd_scale_raw(ax, a)))
          gate_d(g, V.dr_fin(g), T.F_uncertain{})

def cyl_grad(+s: G.Cyl, +q: V.Point) -> G.GRes:
  G.Cy{+o, +a, +r} = s
  +m = pp_sub_raw(q, o)
  cyl_grad_go(m, a,
    Bool.and(G.cy_valid(G.Cy{o, a, r}), V.pt_fin(q)), ax_unit_ok(a))

# Cone: val = (m.m - ax^2) - k^2*ax^2 (double cone; one nappe is
# ax >= 0 via cone_ax); grad = 2(m - ax*a) - 2k^2*ax*a.
def cone_val_go(+m: V.Dir, +a: V.Dir, +k: F64, fin: Bool,
    unit: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match unit:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +ax = dd_dot_raw(m, a)
          +v = F64.sub(F64.sub(dd_dot_raw(m, m), F64.mul(ax, ax)),
            F64.mul(F64.mul(k, k), F64.mul(ax, ax)))
          gate_f(v, T.is_finite(v), T.F_uncertain{})

def cone_val(+s: G.Cone, +q: V.Point) -> G.GRes:
  G.Co{+o, +a, +k} = s
  +m = pp_sub_raw(q, o)
  cone_val_go(m, a, k,
    Bool.and(G.co_valid(G.Co{o, a, k}), V.pt_fin(q)), ax_unit_ok(a))

def cone_grad_go(+m: V.Dir, +a: V.Dir, +k: F64, fin: Bool,
    unit: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match unit:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +ax = dd_dot_raw(m, a)
          +rad = dd_sub_raw(m, dd_scale_raw(ax, a))
          +g = dd_add_raw(dd_scale_raw(2.0f64, rad),
            dd_scale_raw(F64.mul(F64.neg(2.0f64),
              F64.mul(F64.mul(k, k), ax)), a))
          gate_d(g, V.dr_fin(g), T.F_uncertain{})

def cone_grad(+s: G.Cone, +q: V.Point) -> G.GRes:
  G.Co{+o, +a, +k} = s
  +m = pp_sub_raw(q, o)
  cone_grad_go(m, a, k,
    Bool.and(G.co_valid(G.Co{o, a, k}), V.pt_fin(q)), ax_unit_ok(a))

def cone_ax_go(+m: V.Dir, +a: V.Dir, fin: Bool,
    unit: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match unit:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +ax = dd_dot_raw(m, a)
          gate_f(ax, T.is_finite(ax), T.F_uncertain{})

def cone_ax(+s: G.Cone, +q: V.Point) -> G.GRes:
  G.Co{+o, +a, +k} = s
  +m = pp_sub_raw(q, o)
  cone_ax_go(m, a,
    Bool.and(G.co_valid(G.Co{o, a, k}), V.pt_fin(q)), ax_unit_ok(a))

# Torus: d2 = m.m, S = R^2+r^2; val = (d2-S)^2 - 4R^2(r^2-ax^2);
# grad = 4(d2-S)m + 8R^2*ax*a.
def tor_val_go(+m: V.Dir, +a: V.Dir, +R: F64, +r: F64, fin: Bool,
    unit: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match unit:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +ax = dd_dot_raw(m, a)
          +d2 = dd_dot_raw(m, m)
          +s = F64.add(F64.mul(R, R), F64.mul(r, r))
          +v = F64.sub(F64.mul(F64.sub(d2, s), F64.sub(d2, s)),
            F64.mul(F64.mul(4.0f64, F64.mul(R, R)),
              F64.sub(F64.mul(r, r), F64.mul(ax, ax))))
          gate_f(v, T.is_finite(v), T.F_uncertain{})

def tor_val(+s: G.Torus, +q: V.Point) -> G.GRes:
  G.To{+o, +a, +R, +r} = s
  +m = pp_sub_raw(q, o)
  tor_val_go(m, a, R, r,
    Bool.and(G.to_valid(G.To{o, a, R, r}), V.pt_fin(q)),
    ax_unit_ok(a))

def tor_grad_go(+m: V.Dir, +a: V.Dir, +R: F64, +r: F64, fin: Bool,
    unit: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match unit:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +ax = dd_dot_raw(m, a)
          +d2 = dd_dot_raw(m, m)
          +s = F64.add(F64.mul(R, R), F64.mul(r, r))
          +g = dd_add_raw(dd_scale_raw(F64.mul(4.0f64,
            F64.sub(d2, s)), m), dd_scale_raw(F64.mul(F64.mul(8.0f64,
            F64.mul(R, R)), ax), a))
          gate_d(g, V.dr_fin(g), T.F_uncertain{})

def tor_grad(+s: G.Torus, +q: V.Point) -> G.GRes:
  G.To{+o, +a, +R, +r} = s
  +m = pp_sub_raw(q, o)
  tor_grad_go(m, a, R, r,
    Bool.and(G.to_valid(G.To{o, a, R, r}), V.pt_fin(q)),
    ax_unit_ok(a))

# --- Trims in surface parameter space: segment/cubic evaluation,
# enclosures, plane composition. Other surface compositions arrive
# with C07/C08; the representation is fixed now. ---
def tseg_eval_go(+a: V.Vec2, +b: V.Vec2, +t: F64, fin: Bool,
    dom: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match dom:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +s = F64.sub(1.0f64, t)
          +q = v2lerp_raw(a, b, s, t)
          gate_v2(q, V.v2_fin(q), T.F_uncertain{})

def tseg_eval(+t: G.TSeg, +u: F64) -> G.GRes:
  G.Ts{+a, +b} = t
  tseg_eval_go(a, b, u, G.ts_fin(G.Ts{a, b}),
    Bool.and(F64.is_le(0.0f64, u), F64.is_le(u, 1.0f64)))

def tbez_eval_go(+b0: V.Vec2, +b1: V.Vec2, +b2: V.Vec2, +b3: V.Vec2,
    +t: F64, fin: Bool, dom: Bool) -> G.GRes:
  match fin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match dom:
        case False{}: G.gerr(T.F_invalid{})
        case True{}:
          +s = F64.sub(1.0f64, t)
          +s2 = F64.mul(s, s)
          +t2 = F64.mul(t, t)
          +c0 = F64.mul(s2, s)
          +c1 = F64.mul(3.0f64, F64.mul(s2, t))
          +c2 = F64.mul(3.0f64, F64.mul(s, t2))
          +c3 = F64.mul(t2, t)
          +q = v2_cubic_raw(b0, b1, b2, b3, c0, c1, c2, c3)
          gate_v2(q, V.v2_fin(q), T.F_uncertain{})

def tbez_eval(+t: G.TBez, +u: F64) -> G.GRes:
  G.Tb{+b0, +b1, +b2, +b3} = t
  tbez_eval_go(b0, b1, b2, b3, u, G.tb_fin(G.Tb{b0, b1, b2, b3}),
    Bool.and(F64.is_le(0.0f64, u), F64.is_le(u, 1.0f64)))

# 2D hull, same certificate as the 3D hulls (returned as corners).
def tseg_bbox_go(+ax: F64, +ay: F64, +bx: F64, +by: F64,
    ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      G.gok_bb(G.Bb{V.Pt{F64.min(ax, bx), F64.min(ay, by), 0.0f64},
        V.Pt{F64.max(ax, bx), F64.max(ay, by), 0.0f64}})
    case False{}: G.gerr(T.F_invalid{})

def tseg_bbox(+t: G.TSeg) -> G.GRes:
  G.Ts{+a, +b} = t
  V.V2{+ax, +ay} = a
  V.V2{+bx, +by} = b
  tseg_bbox_go(ax, ay, bx, by, G.ts_fin(G.Ts{a, b}))

def tbez_bbox_go(+x0: F64, +y0: F64, +x1: F64, +y1: F64, +x2: F64,
    +y2: F64, +x3: F64, +y3: F64, ok: Bool) -> G.GRes:
  match ok:
    case True{}:
      G.gok_bb(G.Bb{V.Pt{F64.min(F64.min(x0, x1), F64.min(x2, x3)),
          F64.min(F64.min(y0, y1), F64.min(y2, y3)), 0.0f64},
        V.Pt{F64.max(F64.max(x0, x1), F64.max(x2, x3)),
          F64.max(F64.max(y0, y1), F64.max(y2, y3)), 0.0f64}})
    case False{}: G.gerr(T.F_invalid{})

def tbez_bbox(+t: G.TBez) -> G.GRes:
  G.Tb{+b0, +b1, +b2, +b3} = t
  V.V2{+x0, +y0} = b0
  V.V2{+x1, +y1} = b1
  V.V2{+x2, +y2} = b2
  V.V2{+x3, +y3} = b3
  tbez_bbox_go(x0, y0, x1, y1, x2, y2, x3, y3,
    G.tb_fin(G.Tb{b0, b1, b2, b3}))

# Plane composition: the trim point (u, v) maps through plane_eval.
def plane_trim_pt(+p: G.Plane3, +uv: V.Vec2) -> G.GRes:
  G.Pl{+o, +u, +v} = p
  V.V2{+s, +t} = uv
  plane_eval_go(o, u, v, s, t,
    Bool.and(G.pl_fin(G.Pl{o, u, v}), V.v2_fin(uv)),
    uv_frame_ok(u, v))

# --- NURBS (cubic clamped): fuel-bounded validation walks, knot span,
# window extraction, fixed de Boor. Walk codes pack ok + 2*done as one
# Nat (ok is meaningful only when done; callers check done first).
# Every recursive walk is structural in its list AND fuel-capped; fuel
# exhaustion surfaces as resource-exhausted, never a guess. ---
def code_pack(ok: Bool, done: Bool) -> Nat:
  Nat.add(Bool.pick(Nat, ok, 1n, 0n), Bool.pick(Nat, done, 2n, 0n))

def code_ok(c: Nat) -> Bool:
  Nat.is_eq(Nat.mod(c, 2n), 1n)

def code_done(c: Nat) -> Bool:
  Nat.is_le(2n, c)

def kfin_c(ks: List<&2, F64>, fuel: Nat) -> Nat:
  match ks:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = kfin_c(t, f)
          code_pack(Bool.and(T.is_finite(h), code_ok(rest)),
            code_done(rest))

def knondec_c(ks: List<&2, F64>, fuel: Nat, prev: F64,
    has: Bool) -> Nat:
  match ks:
    case Nil{}: 3n
    case +h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = knondec_c(t, f, h, True{})
          +step = Bool.pick(Bool, has, F64.is_le(prev, h), True{})
          code_pack(Bool.and(step, code_ok(rest)), code_done(rest))

def wpos_c(ws: List<&2, F64>, fuel: Nat) -> Nat:
  match ws:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = wpos_c(t, f)
          code_pack(Bool.and(G.spos(h), code_ok(rest)),
            code_done(rest))

def pfin_c(ps: List<&2, V.Point>, fuel: Nat) -> Nat:
  match ps:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = pfin_c(t, f)
          code_pack(Bool.and(V.pt_fin(h), code_ok(rest)),
            code_done(rest))

# Knot span: last index with k <= t. Best-so-far on exhaustion (the
# value is read only when the shared-fuel fin walk completed).
# INVARANT (stated, load-bearing): span_at takes NO done flag of its
# own; every caller runs it over the SAME knot list with the SAME
# fuel as kfin_c/knondec_c, and reads the span only when those walks
# report done. Same list + same fuel => the span walk consumed one
# fuel per element exactly like the fin walk, so fin-done implies
# span-complete. Keep the list AND the fuel shared at every call site.
def span_at(ks: List<&2, F64>, +t: F64, fuel: Nat, +idx: Nat,
    best: Nat) -> Nat:
  match ks:
    case Nil{}: best
    case h <> t2:
      match fuel:
        case 0n: best
        case 1n+f:
          span_at(t2, t, f, Nat.add(idx, 1n),
            Bool.pick(Nat, F64.is_le(h, t), idx, best))

# Structural drops (bounded by n + length; no fuel needed).
def dropk(ks: List<&2, F64>, n: Nat) -> List<&2, F64>:
  match ks:
    case Nil{}: Nil{}
    case h <> t:
      match n:
        case 0n: h <> t
        case 1n+m: dropk(t, m)

def dropp(ps: List<&2, V.Point>, n: Nat) -> List<&2, V.Point>:
  match ps:
    case Nil{}: Nil{}
    case h <> t:
      match n:
        case 0n: h <> t
        case 1n+m: dropp(t, m)

def dropw(ws: List<&2, F64>, n: Nat) -> List<&2, F64>:
  match ws:
    case Nil{}: Nil{}
    case h <> t:
      match n:
        case 0n: h <> t
        case 1n+m: dropw(t, m)

# Fixed takes with zero fill (total; short reads zero-fill and the
# caller routes through counts, which imply fit — contract §7).
def k7_zero() -> G.K7:
  G.K7{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}

def take7k(ks: List<&2, F64>) -> G.K7:
  match ks:
    case Nil{}: k7_zero()
    case k0 <> t0:
      match t0:
        case Nil{}: k7_zero()
        case k1 <> t1:
          match t1:
            case Nil{}: k7_zero()
            case k2 <> t2:
              match t2:
                case Nil{}: k7_zero()
                case k3 <> t3:
                  match t3:
                    case Nil{}: k7_zero()
                    case k4 <> t4:
                      match t4:
                        case Nil{}: k7_zero()
                        case k5 <> t5:
                          match t5:
                            case Nil{}: k7_zero()
                            case k6 <> t6:
                              G.K7{k0, k1, k2, k3, k4, k5, k6}

def k4_zero() -> G.K4:
  G.K4{0.0f64, 0.0f64, 0.0f64, 0.0f64}

def take4k(ks: List<&2, F64>) -> G.K4:
  match ks:
    case Nil{}: k4_zero()
    case k0 <> t0:
      match t0:
        case Nil{}: k4_zero()
        case k1 <> t1:
          match t1:
            case Nil{}: k4_zero()
            case k2 <> t2:
              match t2:
                case Nil{}: k4_zero()
                case k3 <> t3: G.K4{k0, k1, k2, k3}

def p4_zero() -> G.P4:
  G.P4{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}}

def take4p(ps: List<&2, V.Point>) -> G.P4:
  match ps:
    case Nil{}: p4_zero()
    case q0 <> t0:
      match t0:
        case Nil{}: p4_zero()
        case q1 <> t1:
          match t1:
            case Nil{}: p4_zero()
            case q2 <> t2:
              match t2:
                case Nil{}: p4_zero()
                case q3 <> t3: G.P4{q0, q1, q2, q3}

def w4_zero() -> G.W4:
  G.W4{0.0f64, 0.0f64, 0.0f64, 0.0f64}

def take4w(ws: List<&2, F64>) -> G.W4:
  match ws:
    case Nil{}: w4_zero()
    case w0 <> t0:
      match t0:
        case Nil{}: w4_zero()
        case w1 <> t1:
          match t1:
            case Nil{}: w4_zero()
            case w2 <> t2:
              match t2:
                case Nil{}: w4_zero()
                case w3 <> t3: G.W4{w0, w1, w2, w3}

# de Boor ratio with the standard 0/0 := 0 convention for repeated
# knots (exact-zero test; stated convention, contract §7).
def alpha_go(+num: F64, +den: F64, zero: Bool) -> F64:
  match zero:
    case True{}: 0.0f64
    case False{}: F64.div(num, den)

def alpha_raw(+t: F64, +klo: F64, +khi: F64) -> F64:
  +den = F64.sub(khi, klo)
  alpha_go(F64.sub(t, klo), den, F64.is_eq(den, 0.0f64))

def hpt_of(+p: V.Point, +w: F64) -> Hpt:
  V.Pt{+x, +y, +z} = p
  Hp{F64.mul(w, x), F64.mul(w, y), F64.mul(w, z), w}

# Fixed cubic de Boor on one window (knots k[s-2..s+4] as k0..k6,
# points/weights q/w[s-3..s]). Homogeneous lerps; the caller divides.
def deboor_raw(+w: G.K7, +p: G.P4, +ww: G.W4, +t: F64) -> Hpt:
  +k0 = G.k7_0(w)
  +k1 = G.k7_1(w)
  +k2 = G.k7_2(w)
  +k3 = G.k7_3(w)
  +k4 = G.k7_4(w)
  +k5 = G.k7_5(w)
  +h0 = hpt_of(G.p4_0(p), G.w4_0(ww))
  +h1 = hpt_of(G.p4_1(p), G.w4_1(ww))
  +h2 = hpt_of(G.p4_2(p), G.w4_2(ww))
  +h3 = hpt_of(G.p4_3(p), G.w4_3(ww))
  +a0 = alpha_raw(t, k0, k3)
  +a1 = alpha_raw(t, k1, k4)
  +a2 = alpha_raw(t, k2, k5)
  +m0 = hlerp_raw(h0, h1, F64.sub(1.0f64, a0), a0)
  +m1 = hlerp_raw(h1, h2, F64.sub(1.0f64, a1), a1)
  +m2 = hlerp_raw(h2, h3, F64.sub(1.0f64, a2), a2)
  +b0 = alpha_raw(t, k1, k3)
  +b1 = alpha_raw(t, k2, k4)
  +n0 = hlerp_raw(m0, m1, F64.sub(1.0f64, b0), b0)
  +n1 = hlerp_raw(m1, m2, F64.sub(1.0f64, b1), b1)
  +c = alpha_raw(t, k2, k3)
  hlerp_raw(n0, n1, F64.sub(1.0f64, c), c)

# Whole-curve validation code (counts + walks + clamped ends).
def nok_c(+ks: List<&2, F64>, +ps: List<&2, V.Point>,
    +ws: List<&2, F64>, +fuel: Nat) -> Nat:
  +nk = List.length(&2, F64, ks)
  +nc = List.length(&2, V.Point, ps)
  +nw = List.length(&2, F64, ws)
  +counts = Bool.and(Nat.is_eq(nk, Nat.add(nc, 4n)),
    Bool.and(Nat.is_eq(nw, nc), Nat.is_le(4n, nc)))
  +cf = kfin_c(ks, fuel)
  +cn = knondec_c(ks, fuel, 0.0f64, False{})
  +cw = wpos_c(ws, fuel)
  +cp = pfin_c(ps, fuel)
  +done = Bool.and(code_done(cf),
    Bool.and(code_done(cn),
      Bool.and(code_done(cw), code_done(cp))))
  +nk4 = Nat.sub(nk, 4n)
  +first = take4k(ks)
  +last = take4k(dropk(ks, nk4))
  +cl0 = Bool.and(F64.is_eq(G.k4_0(first), G.k4_1(first)),
    Bool.and(F64.is_eq(G.k4_1(first), G.k4_2(first)),
      F64.is_eq(G.k4_2(first), G.k4_3(first))))
  +cl1 = Bool.and(F64.is_eq(G.k4_0(last), G.k4_1(last)),
    Bool.and(F64.is_eq(G.k4_1(last), G.k4_2(last)),
      F64.is_eq(G.k4_2(last), G.k4_3(last))))
  +ok = Bool.and(counts,
    Bool.and(code_ok(cf),
      Bool.and(code_ok(cn),
        Bool.and(code_ok(cw),
          Bool.and(code_ok(cp), Bool.and(cl0, cl1))))))
  code_pack(ok, done)

def nurbs_checked_go(+n: G.Nurb, done: Bool, ok: Bool) -> G.GRes:
  match done:
    case False{}: G.gerr(T.F_exhausted{})
    case True{}:
      match ok:
        case False{}: G.gerr(T.F_invalid{})
        case True{}: G.gok_nb(n)

def nurbs_checked(+n: G.Nurb, fuel: Nat) -> G.GRes:
  match fuel:
    case 0n: G.gerr(T.F_exhausted{})
    case 1n+f:
      +code = nok_c(G.nb_ks(n), G.nb_ps(n), G.nb_ws(n), f)
      nurbs_checked_go(n, code_done(code), code_ok(code))

def nurbs_eval_fin(+qx: F64, +qy: F64, +qz: F64, tfin: Bool,
    done: Bool, valid: Bool) -> G.GRes:
  match tfin:
    case False{}: G.gerr(T.F_invalid{})
    case True{}:
      match done:
        case False{}: G.gerr(T.F_exhausted{})
        case True{}:
          match valid:
            case False{}: G.gerr(T.F_invalid{})
            case True{}:
              gate_p(V.Pt{qx, qy, qz}, V.pt_fin(V.Pt{qx, qy, qz}),
                T.F_uncertain{})

def nurbs_eval_go(+ks: List<&2, F64>, +ps: List<&2, V.Point>,
    +ws: List<&2, F64>, +t: F64, +fuel: Nat) -> G.GRes:
  +nk = List.length(&2, F64, ks)
  +nc = List.length(&2, V.Point, ps)
  +nw = List.length(&2, F64, ws)
  +counts = Bool.and(Nat.is_eq(nk, Nat.add(nc, 4n)),
    Bool.and(Nat.is_eq(nw, nc), Nat.is_le(4n, nc)))
  +cf = kfin_c(ks, fuel)
  +cn = knondec_c(ks, fuel, 0.0f64, False{})
  +cw = wpos_c(ws, fuel)
  +cp = pfin_c(ps, fuel)
  +done = Bool.and(code_done(cf),
    Bool.and(code_done(cn),
      Bool.and(code_done(cw), code_done(cp))))
  +nk4 = Nat.sub(nk, 4n)
  +nk5 = Nat.sub(nk, 5n)
  +sraw = span_at(ks, t, fuel, 0n, 0n)
  +s1 = Bool.pick(Nat, Nat.is_lt(sraw, 3n), 3n, sraw)
  +sp = Bool.pick(Nat, Nat.is_lt(nk5, s1), nk5, s1)
  +wk = take7k(dropk(ks, Nat.sub(sp, 2n)))
  +wp = take4p(dropp(ps, Nat.sub(sp, 3n)))
  +ww = take4w(dropw(ws, Nat.sub(sp, 3n)))
  +hq = deboor_raw(wk, wp, ww, t)
  +hw = hpt_w(hq)
  +qx = F64.div(hpt_x(hq), hw)
  +qy = F64.div(hpt_y(hq), hw)
  +qz = F64.div(hpt_z(hq), hw)
  +first = take4k(ks)
  +last = take4k(dropk(ks, nk4))
  +cl0 = Bool.and(F64.is_eq(G.k4_0(first), G.k4_1(first)),
    Bool.and(F64.is_eq(G.k4_1(first), G.k4_2(first)),
      F64.is_eq(G.k4_2(first), G.k4_3(first))))
  +cl1 = Bool.and(F64.is_eq(G.k4_0(last), G.k4_1(last)),
    Bool.and(F64.is_eq(G.k4_1(last), G.k4_2(last)),
      F64.is_eq(G.k4_2(last), G.k4_3(last))))
  +klo = G.k4_3(first)
  +khi = G.k4_0(last)
  +dom = Bool.and(F64.is_le(klo, t), F64.is_le(t, khi))
  +valid = Bool.and(counts,
    Bool.and(code_ok(cf),
      Bool.and(code_ok(cn),
        Bool.and(code_ok(cw),
          Bool.and(code_ok(cp),
            Bool.and(cl0, Bool.and(cl1, dom)))))))
  nurbs_eval_fin(qx, qy, qz, T.is_finite(t), done, valid)

def nurbs_eval(+n: G.Nurb, +t: F64, fuel: Nat) -> G.GRes:
  match fuel:
    case 0n: G.gerr(T.F_exhausted{})
    case 1n+f: nurbs_eval_go(G.nb_ks(n), G.nb_ps(n), G.nb_ws(n), t,
      f)
