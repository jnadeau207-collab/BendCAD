import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as G3

def circ_nx(+t: F64) -> F64:
  +t2 = F64.mul(t, t)
  +t4 = F64.mul(t2, t2)
  +s1 = F64.add(1.0f64, t2)
  +den = F64.mul(s1, s1)
  F64.div(F64.add(F64.sub(1.0f64, F64.mul(6.0f64, t2)), t4),
    den)

def circ_ny(+t: F64) -> F64:
  +t2 = F64.mul(t, t)
  +s1 = F64.add(1.0f64, t2)
  +den = F64.mul(s1, s1)
  F64.div(F64.mul(F64.mul(4.0f64, t), F64.sub(1.0f64, t2)),
    den)

def t_in11(+t: F64) -> Bool:
  Bool.and(F64.is_le(F64.neg(1.0f64), t), F64.is_le(t, 1.0f64))

type QFr is Data:
  QFr{ n1: V.Dir, n2: V.Dir }

def norm3_go(+m: F64, +x: F64, +y: F64, +z: F64,
    zero: Bool) -> F64:
  match zero:
    case True{}: 0.0f64
    case False{}:
      +rx = F64.div(x, m)
      +ry = F64.div(y, m)
      +rz = F64.div(z, m)
      F64.mul(m, F64.sqrt(F64.add(F64.add(F64.mul(rx, rx),
        F64.mul(ry, ry)), F64.mul(rz, rz))))

def norm3(+x: F64, +y: F64, +z: F64) -> F64:
  +m = F64.max(F64.abs(x), F64.max(F64.abs(y), F64.abs(z)))
  norm3_go(m, x, y, z, F64.is_eq(m, 0.0f64))

def qf_wi_yz(y_min: Bool) -> U64:
  match y_min:
    case True{}: 1u64
    case False{}: 2u64

def qf_wi_go(x_min: Bool, y_min: Bool) -> U64:
  match x_min:
    case True{}: 0u64
    case False{}: qf_wi_yz(y_min)

def qf_wi(+ax: F64, +ay: F64, +az: F64) -> U64:
  +xa = F64.abs(ax)
  +ya = F64.abs(ay)
  +za = F64.abs(az)
  qf_wi_go(Bool.and(F64.is_le(xa, ya), F64.is_le(xa, za)),
    F64.is_le(ya, za))

def qf_wpick(+wi: U64, want: U64) -> F64:
  Bool.pick(F64, U64.is_eq(wi, want), 1.0f64, 0.0f64)

def qf_gs_c(+ax: F64, +ay: F64, +az: F64) -> QFr:
  +wi = qf_wi(ax, ay, az)
  +wx = qf_wpick(wi, 0u64)
  +wy = qf_wpick(wi, 1u64)
  +wz = qf_wpick(wi, 2u64)
  +dd = F64.add(F64.add(F64.mul(ax, wx), F64.mul(ay, wy)),
    F64.mul(az, wz))
  +ux = F64.sub(wx, F64.mul(ax, dd))
  +uy = F64.sub(wy, F64.mul(ay, dd))
  +uz = F64.sub(wz, F64.mul(az, dd))
  +n1 = norm3(ux, uy, uz)
  +vx = F64.div(ux, n1)
  +vy = F64.div(uy, n1)
  +vz = F64.div(uz, n1)
  +c2x = F64.sub(F64.mul(ay, vz), F64.mul(az, vy))
  +c2y = F64.sub(F64.mul(az, vx), F64.mul(ax, vz))
  +c2z = F64.sub(F64.mul(ax, vy), F64.mul(ay, vx))
  +n2 = norm3(c2x, c2y, c2z)
  QFr{V.Dr{vx, vy, vz},
    V.Dr{F64.div(c2x, n2), F64.div(c2y, n2),
      F64.div(c2z, n2)}}

def qframe_gz(z: Bool, +ax: F64, +ay: F64, +az: F64) -> QFr:
  match z:
    case True{}:
      QFr{V.Dr{1.0f64, 0.0f64, 0.0f64},
        V.Dr{0.0f64, az, 0.0f64}}
    case False{}: qf_gs_c(ax, ay, az)

def qframe_gy(y: Bool, z: Bool, +ax: F64, +ay: F64,
    +az: F64) -> QFr:
  match y:
    case True{}:
      QFr{V.Dr{0.0f64, 0.0f64, 1.0f64},
        V.Dr{ay, 0.0f64, 0.0f64}}
    case False{}: qframe_gz(z, ax, ay, az)

def qframe_go(x: Bool, y: Bool, z: Bool, +ax: F64, +ay: F64,
    +az: F64) -> QFr:
  match x:
    case True{}:
      QFr{V.Dr{0.0f64, 1.0f64, 0.0f64},
        V.Dr{0.0f64, 0.0f64, ax}}
    case False{}: qframe_gy(y, z, ax, ay, az)

def qframe_c(+ax: F64, +ay: F64, +az: F64) -> QFr:
  qframe_go(Bool.and(F64.is_eq(F64.abs(ax), 1.0f64),
      Bool.and(F64.is_eq(ay, 0.0f64), F64.is_eq(az, 0.0f64))),
    Bool.and(F64.is_eq(ax, 0.0f64),
      Bool.and(F64.is_eq(F64.abs(ay), 1.0f64),
        F64.is_eq(az, 0.0f64))),
    Bool.and(F64.is_eq(ax, 0.0f64),
      Bool.and(F64.is_eq(ay, 0.0f64),
        F64.is_eq(F64.abs(az), 1.0f64))),
    ax, ay, az)

def qframe(a: V.Dir) -> QFr:
  V.Dr{+ax, +ay, +az} = a
  qframe_c(ax, ay, az)

def spine_c(+ox: F64, +oy: F64, +oz: F64, +ax: F64, +ay: F64,
    +az: F64, +h: F64) -> V.Point:
  V.Pt{F64.add(ox, F64.mul(h, ax)),
    F64.add(oy, F64.mul(h, ay)),
    F64.add(oz, F64.mul(h, az))}

def gate_pt(+p: V.Point) -> G.GRes:
  G3.gate_p(p, V.pt_fin(p), T.F_uncertain{})

def surf_cyl_f(+r: F64, +t: F64, +h: F64, +ox: F64, +oy: F64,
    +oz: F64, +ax: F64, +ay: F64, +az: F64, +n1x: F64,
    +n1y: F64, +n1z: F64, +n2x: F64, +n2y: F64,
    +n2z: F64) -> G.GRes:
  +nx = circ_nx(t)
  +ny = circ_ny(t)
  +chx = F64.add(ox, F64.mul(h, ax))
  +chy = F64.add(oy, F64.mul(h, ay))
  +chz = F64.add(oz, F64.mul(h, az))
  +s1 = F64.mul(r, nx)
  +s2 = F64.mul(r, ny)
  +qx = F64.add(F64.add(chx, F64.mul(s1, n1x)),
    F64.mul(s2, n2x))
  +qy = F64.add(F64.add(chy, F64.mul(s1, n1y)),
    F64.mul(s2, n2y))
  +qz = F64.add(F64.add(chz, F64.mul(s1, n1z)),
    F64.mul(s2, n2z))
  gate_pt(V.Pt{qx, qy, qz})

def surf_cyl_s(n1: V.Dir, n2: V.Dir, o: V.Point, a: V.Dir,
    +r: F64, +t: F64, +h: F64) -> G.GRes:
  V.Dr{+n1x, +n1y, +n1z} = n1
  V.Dr{+n2x, +n2y, +n2z} = n2
  V.Pt{+ox, +oy, +oz} = o
  V.Dr{+ax, +ay, +az} = a
  surf_cyl_f(r, t, h, ox, oy, oz, ax, ay, az, n1x, n1y, n1z,
    n2x, n2y, n2z)

def surf_cyl_q(q: QFr, o: V.Point, a: V.Dir, +r: F64, +t: F64,
    +h: F64) -> G.GRes:
  QFr{+n1, +n2} = q
  surf_cyl_s(n1, n2, o, a, r, t, h)

def surf_cyl_go(ok: Bool, o: V.Point, +a: V.Dir, +r: F64,
    +t: F64, +h: F64) -> G.GRes:
  match ok:
    case False{}: G.gerr(T.F_invalid{})
    case True{}: surf_cyl_q(qframe(a), o, a, r, t, h)

def surf_cyl(c: G.Cyl, +t: F64, +h: F64) -> G.GRes:
  G.Cy{+o, +a, +r} = c
  surf_cyl_go(Bool.and(Bool.and(G.cy_valid(c), G3.ax_unit_ok(a)),
      Bool.and(T.is_finite(t),
        Bool.and(T.is_finite(h), t_in11(t)))),
    o, a, r, t, h)

def surf_cone_f(+rh: F64, +t: F64, +h: F64, +ox: F64, +oy: F64,
    +oz: F64, +ax: F64, +ay: F64, +az: F64, +n1x: F64,
    +n1y: F64, +n1z: F64, +n2x: F64, +n2y: F64,
    +n2z: F64) -> G.GRes:
  +nx = circ_nx(t)
  +ny = circ_ny(t)
  +chx = F64.add(ox, F64.mul(h, ax))
  +chy = F64.add(oy, F64.mul(h, ay))
  +chz = F64.add(oz, F64.mul(h, az))
  +s1 = F64.mul(rh, nx)
  +s2 = F64.mul(rh, ny)
  +qx = F64.add(F64.add(chx, F64.mul(s1, n1x)),
    F64.mul(s2, n2x))
  +qy = F64.add(F64.add(chy, F64.mul(s1, n1y)),
    F64.mul(s2, n2y))
  +qz = F64.add(F64.add(chz, F64.mul(s1, n1z)),
    F64.mul(s2, n2z))
  gate_pt(V.Pt{qx, qy, qz})

def surf_cone_s(n1: V.Dir, n2: V.Dir, o: V.Point, a: V.Dir,
    +k: F64, +t: F64, +h: F64) -> G.GRes:
  V.Dr{+n1x, +n1y, +n1z} = n1
  V.Dr{+n2x, +n2y, +n2z} = n2
  V.Pt{+ox, +oy, +oz} = o
  V.Dr{+ax, +ay, +az} = a
  surf_cone_f(F64.mul(k, h), t, h, ox, oy, oz, ax, ay, az,
    n1x, n1y, n1z, n2x, n2y, n2z)

def surf_cone_q(q: QFr, o: V.Point, a: V.Dir, +k: F64, +t: F64,
    +h: F64) -> G.GRes:
  QFr{+n1, +n2} = q
  surf_cone_s(n1, n2, o, a, k, t, h)

def surf_cone_go(ok: Bool, o: V.Point, +a: V.Dir, +k: F64,
    +t: F64, +h: F64) -> G.GRes:
  match ok:
    case False{}: G.gerr(T.F_invalid{})
    case True{}: surf_cone_q(qframe(a), o, a, k, t, h)

def surf_cone(c: G.Cone, +t: F64, +h: F64) -> G.GRes:
  G.Co{+o, +a, +k} = c
  surf_cone_go(Bool.and(Bool.and(G.co_valid(c), G3.ax_unit_ok(a)),
      Bool.and(T.is_finite(t),
        Bool.and(T.is_finite(h),
          Bool.and(t_in11(t), F64.is_le(0.0f64, h))))),
    o, a, k, t, h)

def surf_tor_f(+R: F64, +r: F64, +t: F64, +s: F64, +ox: F64,
    +oy: F64, +oz: F64, +ax: F64, +ay: F64, +az: F64,
    +n1x: F64, +n1y: F64, +n1z: F64, +n2x: F64, +n2y: F64,
    +n2z: F64) -> G.GRes:
  +nxs = circ_nx(s)
  +nys = circ_ny(s)
  +nxt = circ_nx(t)
  +nyt = circ_ny(t)
  +w = F64.add(R, F64.mul(r, nxs))
  +hs = F64.mul(r, nys)
  +csx = F64.add(ox, F64.mul(hs, ax))
  +csy = F64.add(oy, F64.mul(hs, ay))
  +csz = F64.add(oz, F64.mul(hs, az))
  +s1 = F64.mul(w, nxt)
  +s2 = F64.mul(w, nyt)
  +qx = F64.add(F64.add(csx, F64.mul(s1, n1x)),
    F64.mul(s2, n2x))
  +qy = F64.add(F64.add(csy, F64.mul(s1, n1y)),
    F64.mul(s2, n2y))
  +qz = F64.add(F64.add(csz, F64.mul(s1, n1z)),
    F64.mul(s2, n2z))
  gate_pt(V.Pt{qx, qy, qz})

def surf_tor_s(n1: V.Dir, n2: V.Dir, o: V.Point, a: V.Dir,
    +R: F64, +r: F64, +t: F64, +s: F64) -> G.GRes:
  V.Dr{+n1x, +n1y, +n1z} = n1
  V.Dr{+n2x, +n2y, +n2z} = n2
  V.Pt{+ox, +oy, +oz} = o
  V.Dr{+ax, +ay, +az} = a
  surf_tor_f(R, r, t, s, ox, oy, oz, ax, ay, az, n1x, n1y,
    n1z, n2x, n2y, n2z)

def surf_tor_q(q: QFr, o: V.Point, a: V.Dir, +R: F64, +r: F64,
    +t: F64, +s: F64) -> G.GRes:
  QFr{+n1, +n2} = q
  surf_tor_s(n1, n2, o, a, R, r, t, s)

def surf_tor_go(ok: Bool, o: V.Point, +a: V.Dir, +R: F64,
    +r: F64, +t: F64, +s: F64) -> G.GRes:
  match ok:
    case False{}: G.gerr(T.F_invalid{})
    case True{}: surf_tor_q(qframe(a), o, a, R, r, t, s)

def surf_tor(c: G.Torus, +t: F64, +s: F64) -> G.GRes:
  G.To{+o, +a, +R, +r} = c
  surf_tor_go(Bool.and(Bool.and(G.to_valid(c), G3.ax_unit_ok(a)),
      Bool.and(F64.is_lt(r, R),
        Bool.and(T.is_finite(t),
          Bool.and(T.is_finite(s),
            Bool.and(t_in11(t), t_in11(s)))))),
    o, a, R, r, t, s)

def surf_sph_f(+r: F64, +u: F64, +v: F64, +cx: F64, +cy: F64,
    +cz: F64) -> G.GRes:
  +uu = F64.mul(u, u)
  +vv = F64.mul(v, v)
  +suv = F64.add(uu, vv)
  +den = F64.add(1.0f64, suv)
  +nx = F64.div(F64.mul(2.0f64, u), den)
  +ny = F64.div(F64.mul(2.0f64, v), den)
  +nz = F64.div(F64.sub(1.0f64, suv), den)
  +qx = F64.add(cx, F64.mul(r, nx))
  +qy = F64.add(cy, F64.mul(r, ny))
  +qz = F64.add(cz, F64.mul(r, nz))
  gate_pt(V.Pt{qx, qy, qz})

def surf_sph_q(c: V.Point, +r: F64, +u: F64, +v: F64) -> G.GRes:
  V.Pt{+cx, +cy, +cz} = c
  surf_sph_f(r, u, v, cx, cy, cz)

def surf_sph_go(ok: Bool, c: V.Point, +r: F64, +u: F64,
    +v: F64) -> G.GRes:
  match ok:
    case False{}: G.gerr(T.F_invalid{})
    case True{}: surf_sph_q(c, r, u, v)

def surf_sph(c: G.Sphere, +u: F64, +v: F64) -> G.GRes:
  G.Sp{+cp, +r} = c
  surf_sph_go(Bool.and(G.sp_valid(c),
      Bool.and(T.is_finite(u), T.is_finite(v))),
    cp, r, u, v)

def surf_at(s: G.GVal, u: F64, v: F64) -> G.GRes:
  match s:
    case G.GV_pl{w}: G3.plane_eval(w, u, v)
    case G.GV_bp{w}: G3.bezp_eval(w, u, v)
    case G.GV_cy{w}: surf_cyl(w, u, v)
    case G.GV_co{w}: surf_cone(w, u, v)
    case G.GV_to{w}: surf_tor(w, u, v)
    case G.GV_sp{w}: surf_sph(w, u, v)
    case _: G.gerr(T.F_unsupported{})

def surf_kind_tag(s: G.GVal) -> U64:
  match s:
    case G.GV_pl{w}: 0u64
    case G.GV_bp{w}: 1u64
    case G.GV_cy{w}: 2u64
    case G.GV_co{w}: 3u64
    case G.GV_to{w}: 4u64
    case G.GV_sp{w}: 5u64
    case _: 99u64

def surf_kind_show(s: G.GVal) -> String:
  match s:
    case G.GV_pl{w}: "plane"
    case G.GV_bp{w}: "bezp"
    case G.GV_cy{w}: "cyl"
    case G.GV_co{w}: "cone"
    case G.GV_to{w}: "torus"
    case G.GV_sp{w}: "sphere"
    case _: "other"

def surf_is_quad(s: G.GVal) -> Bool:
  match s:
    case G.GV_sp{w}: True{}
    case G.GV_cy{w}: True{}
    case G.GV_co{w}: True{}
    case G.GV_to{w}: True{}
    case _: False{}

def ring_cyl_s(n1: V.Dir, n2: V.Dir, o: V.Point, a: V.Dir,
    +r: F64, +h: F64) -> G.GRes:
  V.Pt{+ox, +oy, +oz} = o
  V.Dr{+ax, +ay, +az} = a
  G.mk_circ(V.Pt{F64.add(ox, F64.mul(h, ax)),
      F64.add(oy, F64.mul(h, ay)),
      F64.add(oz, F64.mul(h, az))},
    n1, n2, r)

def ring_cyl_q(q: QFr, o: V.Point, a: V.Dir, +r: F64,
    +h: F64) -> G.GRes:
  QFr{+n1, +n2} = q
  ring_cyl_s(n1, n2, o, a, r, h)

def ring_cyl_go(ok: Bool, o: V.Point, +a: V.Dir, +r: F64,
    +h: F64) -> G.GRes:
  match ok:
    case False{}: G.gerr(T.F_invalid{})
    case True{}: ring_cyl_q(qframe(a), o, a, r, h)

def ring_cyl(c: G.Cyl, +h: F64) -> G.GRes:
  G.Cy{+o, +a, +r} = c
  ring_cyl_go(Bool.and(Bool.and(G.cy_valid(c), G3.ax_unit_ok(a)),
      T.is_finite(h)),
    o, a, r, h)

def ring_cone_s(n1: V.Dir, n2: V.Dir, o: V.Point, a: V.Dir,
    +rh: F64, +h: F64) -> G.GRes:
  V.Pt{+ox, +oy, +oz} = o
  V.Dr{+ax, +ay, +az} = a
  G.mk_circ(V.Pt{F64.add(ox, F64.mul(h, ax)),
      F64.add(oy, F64.mul(h, ay)),
      F64.add(oz, F64.mul(h, az))},
    n1, n2, rh)

def ring_cone_q(q: QFr, o: V.Point, a: V.Dir, +k: F64,
    +h: F64) -> G.GRes:
  QFr{+n1, +n2} = q
  ring_cone_s(n1, n2, o, a, F64.mul(k, h), h)

def ring_cone_go(ok: Bool, o: V.Point, +a: V.Dir, +k: F64,
    +h: F64) -> G.GRes:
  match ok:
    case False{}: G.gerr(T.F_invalid{})
    case True{}: ring_cone_q(qframe(a), o, a, k, h)

def ring_cone(c: G.Cone, +h: F64) -> G.GRes:
  G.Co{+o, +a, +k} = c
  ring_cone_go(Bool.and(Bool.and(G.co_valid(c), G3.ax_unit_ok(a)),
      Bool.and(T.is_finite(h), F64.is_lt(0.0f64, h))),
    o, a, k, h)

def ring_tor_p_s(n1: V.Dir, n2: V.Dir, o: V.Point, a: V.Dir,
    +w: F64, +hs: F64) -> G.GRes:
  V.Pt{+ox, +oy, +oz} = o
  V.Dr{+ax, +ay, +az} = a
  G.mk_circ(V.Pt{F64.add(ox, F64.mul(hs, ax)),
      F64.add(oy, F64.mul(hs, ay)),
      F64.add(oz, F64.mul(hs, az))},
    n1, n2, w)

def ring_tor_p_q(q: QFr, o: V.Point, a: V.Dir, +R: F64, +r: F64,
    +s: F64) -> G.GRes:
  QFr{+n1, +n2} = q
  ring_tor_p_s(n1, n2, o, a,
    F64.add(R, F64.mul(r, circ_nx(s))),
    F64.mul(r, circ_ny(s)))

def ring_tor_p_go(ok: Bool, o: V.Point, +a: V.Dir, +R: F64,
    +r: F64, +s: F64) -> G.GRes:
  match ok:
    case False{}: G.gerr(T.F_invalid{})
    case True{}: ring_tor_p_q(qframe(a), o, a, R, r, s)

def ring_tor_p(c: G.Torus, +s: F64) -> G.GRes:
  G.To{+o, +a, +R, +r} = c
  ring_tor_p_go(Bool.and(Bool.and(G.to_valid(c), G3.ax_unit_ok(a)),
      Bool.and(F64.is_lt(r, R),
        Bool.and(T.is_finite(s), t_in11(s)))),
    o, a, R, r, s)

def ring_tor_m_s(n1: V.Dir, n2: V.Dir, o: V.Point, a: V.Dir,
    +R: F64, +r: F64, +t: F64) -> G.GRes:
  V.Dr{+n1x, +n1y, +n1z} = n1
  V.Dr{+n2x, +n2y, +n2z} = n2
  V.Pt{+ox, +oy, +oz} = o
  +nx = circ_nx(t)
  +ny = circ_ny(t)
  +s1 = F64.mul(R, nx)
  +s2 = F64.mul(R, ny)
  G.mk_circ(V.Pt{F64.add(F64.add(ox, F64.mul(s1, n1x)),
        F64.mul(s2, n2x)),
      F64.add(F64.add(oy, F64.mul(s1, n1y)),
        F64.mul(s2, n2y)),
      F64.add(F64.add(oz, F64.mul(s1, n1z)),
        F64.mul(s2, n2z))},
    V.Dr{F64.add(F64.mul(nx, n1x), F64.mul(ny, n2x)),
      F64.add(F64.mul(nx, n1y), F64.mul(ny, n2y)),
      F64.add(F64.mul(nx, n1z), F64.mul(ny, n2z))},
    a, r)

def ring_tor_m_q(q: QFr, o: V.Point, a: V.Dir, +R: F64, +r: F64,
    +t: F64) -> G.GRes:
  QFr{+n1, +n2} = q
  ring_tor_m_s(n1, n2, o, a, R, r, t)

def ring_tor_m_go(ok: Bool, o: V.Point, +a: V.Dir, +R: F64,
    +r: F64, +t: F64) -> G.GRes:
  match ok:
    case False{}: G.gerr(T.F_invalid{})
    case True{}: ring_tor_m_q(qframe(a), o, a, R, r, t)

def ring_tor_m(c: G.Torus, +t: F64) -> G.GRes:
  G.To{+o, +a, +R, +r} = c
  ring_tor_m_go(Bool.and(Bool.and(G.to_valid(c), G3.ax_unit_ok(a)),
      Bool.and(F64.is_lt(r, R),
        Bool.and(T.is_finite(t), t_in11(t)))),
    o, a, R, r, t)
