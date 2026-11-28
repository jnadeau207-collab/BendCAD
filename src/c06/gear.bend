import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../base/ex.bend as E
import ./xp.bend as X
import ./prof.bend as F
import ./iv.bend as I
import ../k1/sf.bend as KSF
import ../base/par.bend as B

type Gp is Data:
  Gp{ m: F64, z: F64, ds: F64, rb: F64, ra: F64, rf: F64, rho: F64, psi0: F64, tmax: F64, t0: F64, fa: Bool }

type Ar is Data:
  Ar{ sx: F64, sy: F64, ex: F64, ey: F64, cx: F64, cy: F64, r: F64, ccw: Bool }

type Sn is Data:
  Sn{ ok: Bool, cx: F64, cy: F64, r: F64, ex: F64, ey: F64 }

type Ef is Data:
  Ef{ ok: Bool, x: F64, y: F64 }

def deg(+a: F64) -> F64:
  F64.mul(a, 57.29577951308232f64)

def l_at(xs: List<&2, I.I>, +i: Nat) -> F64:
  match xs:
    case []: F64.nan()
    case +x <> t:
      match i:
        case 0n: I.imid(x)
        case 1n+j: l_at(t, j)

def cosd(+d: F64) -> F64:
  l_at(I.sin_cos_deg(d), 0n)

def sind(+d: F64) -> F64:
  l_at(I.sin_cos_deg(d), 1n)

def alpha() -> F64:
  20.0f64

def inv_a() -> F64:
  F64.sub(F64.div(sind(alpha()), cosd(alpha())), F64.div(alpha(), 57.29577951308232f64))

def asin1(+x: F64) -> F64:
  KSF.atan1(F64.div(x, F64.sqrt(F64.sub(1.0f64, F64.mul(x, x)))))

def rho_f(+m: F64, +rb: F64, +rf: F64) -> F64:
  F64.min(F64.mul(0.38f64, m), F64.mul(0.999f64, F64.div(F64.sub(F64.mul(rb, rb), F64.mul(rf, rf)), F64.mul(2.0f64, rf))))

def gp_mk(+m: F64, +z: F64, +ds: F64, +r: F64, +rb: F64) -> Gp:
  +ra = F64.add(r, m)
  +rf = F64.sub(r, F64.mul(1.25f64, m))
  Gp{m, z, ds, rb, ra, rf, rho_f(m, rb, rf), F64.add(F64.div(F64.sub(F64.mul(1.5707963267948966f64, m), ds), F64.mul(2.0f64, r)), inv_a()),
    F64.div(F64.sqrt(F64.sub(F64.mul(ra, ra), F64.mul(rb, rb))), rb), 0.0f64, False{}}

def gp_b(+m: F64, +z: F64, +ds: F64) -> Gp:
  +r = F64.mul(0.5f64, F64.mul(m, z))
  gp_mk(m, z, ds, r, F64.mul(r, cosd(alpha())))

def form_u(+m: F64, +z: F64) -> F64:
  +sa = sind(alpha())
  F64.sub(F64.mul(F64.mul(0.5f64, F64.mul(m, z)), sa), F64.div(F64.mul(F64.sub(1.25f64, F64.mul(0.38f64, F64.sub(1.0f64, sa))), m), sa))

def gp_set(+g: Gp, +t0: F64, +rho: F64, +fa: Bool) -> Gp:
  Gp{+m, +z, +ds, +rb, +ra, +rf, r0, +psi0, +tmax, a, b} = g
  Gp{m, z, ds, rb, ra, rf, rho, psi0, tmax, t0, fa}

def gp_m(+g: Gp) -> F64:
  Gp{+m, z, ds, rb, ra, rf, rho, psi0, tmax, t0, fa} = g
  m

def gp_z(+g: Gp) -> F64:
  Gp{m, +z, ds, rb, ra, rf, rho, psi0, tmax, t0, fa} = g
  z

def gp_ds(+g: Gp) -> F64:
  Gp{m, z, +ds, rb, ra, rf, rho, psi0, tmax, t0, fa} = g
  ds

def gp_rb(+g: Gp) -> F64:
  Gp{m, z, ds, +rb, ra, rf, rho, psi0, tmax, t0, fa} = g
  rb

def gp_ra(+g: Gp) -> F64:
  Gp{m, z, ds, rb, +ra, rf, rho, psi0, tmax, t0, fa} = g
  ra

def gp_rf(+g: Gp) -> F64:
  Gp{m, z, ds, rb, ra, +rf, rho, psi0, tmax, t0, fa} = g
  rf

def gp_rho(+g: Gp) -> F64:
  Gp{m, z, ds, rb, ra, rf, +rho, psi0, tmax, t0, fa} = g
  rho

def gp_psi0(+g: Gp) -> F64:
  Gp{m, z, ds, rb, ra, rf, rho, +psi0, tmax, t0, fa} = g
  psi0

def gp_tmax(+g: Gp) -> F64:
  Gp{m, z, ds, rb, ra, rf, rho, psi0, +tmax, t0, fa} = g
  tmax

def gp_t0(+g: Gp) -> F64:
  Gp{m, z, ds, rb, ra, rf, rho, psi0, tmax, +t0, fa} = g
  t0

def gp_fa(+g: Gp) -> Bool:
  Gp{m, z, ds, rb, ra, rf, rho, psi0, tmax, t0, +fa} = g
  fa

def inv_psi(+g: Gp, +t: F64) -> F64:
  F64.sub(gp_psi0(g), F64.sub(t, KSF.atan1(t)))

def inv_rho(+g: Gp, +t: F64) -> F64:
  F64.mul(gp_rb(g), F64.sqrt(F64.add(1.0f64, F64.mul(t, t))))

def inv_x(+g: Gp, +t: F64) -> F64:
  F64.mul(inv_rho(g, t), cosd(deg(inv_psi(g, t))))

def inv_y(+g: Gp, +t: F64) -> F64:
  F64.mul(inv_rho(g, t), sind(deg(inv_psi(g, t))))

def brk(+g: Gp, +n: F64, +i: F64) -> F64:
  +a = F64.mul(gp_t0(g), gp_t0(g))
  F64.sqrt(F64.add(a, F64.mul(F64.sub(F64.mul(gp_tmax(g), gp_tmax(g)), a), F64.div(i, n))))

def fil_c(+g: Gp, +t: F64, +rho: F64) -> V.Vec2:
  +px = inv_x(g, t)
  +py = inv_y(g, t)
  +qa = F64.sub(gp_psi0(g), t)
  +dx = F64.sub(F64.mul(gp_rb(g), cosd(deg(qa))), px)
  +dy = F64.sub(F64.mul(gp_rb(g), sind(deg(qa))), py)
  +l = F64.sqrt(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)))
  V.V2{F64.sub(px, F64.mul(rho, F64.div(dx, l))), F64.sub(py, F64.mul(rho, F64.div(dy, l)))}

def v2n(+v: V.Vec2) -> F64:
  F64.sqrt(F64.add(F64.mul(V.v2_x(v), V.v2_x(v)), F64.mul(V.v2_y(v), V.v2_y(v))))

def fil_f(+g: Gp, +t: F64, +rho: F64) -> F64:
  F64.sub(v2n(fil_c(g, t, rho)), F64.add(gp_rf(g), rho))

def bis(n: Nat, +g: Gp, +rho: F64, +lo: F64, +hi: F64) -> F64:
  match n:
    case 0n: F64.mul(0.5f64, F64.add(lo, hi))
    case 1n+(+k):
      +m = F64.mul(0.5f64, F64.add(lo, hi))
      +pos = F64.is_lt(0.0f64, fil_f(g, m, rho))
      bis(k, g, rho, Bool.pick(F64, pos, lo, m), Bool.pick(F64, pos, m, hi))

def fa_fit(+g: Gp, +t: F64, +rho: F64) -> Bool:
  +c = fil_c(g, t, rho)
  F64.is_lt(KSF.fatan2(V.v2_y(c), V.v2_x(c)), F64.sub(F64.div(3.141592653589793f64, gp_z(g)), 1.0e-3f64))

def gp_fa2(+g: Gp, +tf: F64, +rho: F64) -> Gp:
  +ts = bis(64n, g, rho, 1.0e-7f64, tf)
  Bool.pick(Gp, fa_fit(g, ts, rho), gp_set(g, ts, rho, True{}), g)

def gp_fa1(ok: Bool, +g: Gp, +tf: F64, +rho: F64) -> Gp:
  match ok:
    case False{}: g
    case True{}: gp_fa2(g, tf, rho)

def gp_of2(+g: Gp, +u: F64, +rho: F64) -> Gp:
  +tf = F64.div(u, gp_rb(g))
  gp_fa1(Bool.and(F64.is_lt(0.0f64, u), Bool.and(F64.is_lt(fil_f(g, 1.0e-7f64, rho), 0.0f64), F64.is_lt(0.0f64, fil_f(g, tf, rho)))), g, tf, rho)

def gp_of(+m: F64, +z: F64, +ds: F64) -> Gp:
  gp_of2(gp_b(m, z, ds), form_u(m, z), F64.mul(0.38f64, m))

def ctr_go(+ax: F64, +ay: F64, +bx: F64, +by: F64, +rr: F64, +rb: F64) -> Ar:
  +mx = F64.mul(0.5f64, F64.add(ax, bx))
  +my = F64.mul(0.5f64, F64.add(ay, by))
  +ux = F64.sub(bx, ax)
  +uy = F64.sub(by, ay)
  +c = F64.sqrt(F64.add(F64.mul(ux, ux), F64.mul(uy, uy)))
  +r = F64.max(rr, F64.mul(0.50005f64, c))
  +h = F64.sqrt(F64.sub(F64.mul(r, r), F64.mul(F64.mul(0.25f64, c), c)))
  +px = F64.add(mx, F64.mul(h, F64.div(F64.neg(uy), c)))
  +py = F64.add(my, F64.mul(h, F64.div(ux, c)))
  +qx = F64.sub(mx, F64.mul(h, F64.div(F64.neg(uy), c)))
  +qy = F64.sub(my, F64.mul(h, F64.div(ux, c)))
  +dp = F64.abs(F64.sub(F64.sqrt(F64.add(F64.mul(px, px), F64.mul(py, py))), rb))
  +dq = F64.abs(F64.sub(F64.sqrt(F64.add(F64.mul(qx, qx), F64.mul(qy, qy))), rb))
  Bool.pick(Ar, F64.is_le(dp, dq), Ar{ax, ay, bx, by, px, py, r, True{}}, Ar{ax, ay, bx, by, qx, qy, r, True{}})

def ar_dir(+a: Ar) -> Ar:
  Ar{+sx, +sy, +ex, +ey, +cx, +cy, +r, cw} = a
  Ar{sx, sy, ex, ey, cx, cy, r, F64.is_lt(0.0f64, F64.sub(F64.mul(F64.sub(sx, cx), F64.sub(ey, cy)), F64.mul(F64.sub(sy, cy), F64.sub(ex, cx))))}

def flank_arc(+g: Gp, +ta: F64, +tb: F64) -> Ar:
  ar_dir(ctr_go(inv_x(g, tb), inv_y(g, tb), inv_x(g, ta), inv_y(g, ta), F64.mul(gp_rb(g), F64.mul(0.5f64, F64.add(ta, tb))), gp_rb(g)))

def dev_go(n: Nat, +g: Gp, +t: F64, +dt: F64, +cx: F64, +cy: F64, +r: F64, +acc: F64) -> F64:
  match n:
    case 0n: acc
    case 1n+(+k):
      +dx = F64.sub(inv_x(g, t), cx)
      +dy = F64.sub(inv_y(g, t), cy)
      dev_go(k, g, F64.add(t, dt), dt, cx, cy, r, F64.max(acc, F64.abs(F64.sub(F64.sqrt(F64.add(F64.mul(dx, dx), F64.mul(dy, dy))), r))))

def ar_cx(+a: Ar) -> F64:
  Ar{sx, sy, ex, ey, +cx, cy, r, cw} = a
  cx

def ar_cy(+a: Ar) -> F64:
  Ar{sx, sy, ex, ey, cx, +cy, r, cw} = a
  cy

def ar_r(+a: Ar) -> F64:
  Ar{sx, sy, ex, ey, cx, cy, +r, cw} = a
  r

def k2_of(+rb: F64, +tb: F64, +r: F64) -> F64:
  F64.add(F64.mul(rb, F64.sqrt(F64.add(1.0f64, F64.mul(tb, tb)))), F64.div(F64.mul(F64.mul(rb, tb), F64.mul(rb, tb)), F64.mul(0.5f64, r)))

def seg_go(+g: Gp, +ta: F64, +tb: F64, +a: Ar, +k2: F64) -> F64:
  +nn = Nat.add(U64.to_nat(F64.to_u64(F64.mul(F64.sqrt(F64.div(k2, 8.0e-5f64)), F64.sub(tb, ta)))), 8n)
  +dt = F64.div(F64.sub(tb, ta), U64.to_f64(U64.from_nat(nn)))
  F64.add(F64.add(dev_go(Nat.add(nn, 1n), g, ta, dt, ar_cx(a), ar_cy(a), ar_r(a), 0.0f64), F64.mul(F64.mul(0.125f64, k2), F64.mul(dt, dt))), 1.0e-12f64)

def seg_dev(+g: Gp, +ta: F64, +tb: F64) -> F64:
  +a = flank_arc(g, ta, tb)
  seg_go(g, ta, tb, a, k2_of(gp_rb(g), tb, ar_r(a)))

def flank_dev(n: Nat, +g: Gp, +nf: F64, +i: F64, +acc: F64) -> F64:
  match n:
    case 0n: acc
    case 1n+(+k): flank_dev(k, g, nf, F64.add(i, 1.0f64), F64.max(acc, seg_dev(g, brk(g, nf, i), brk(g, nf, F64.add(i, 1.0f64)))))

def gear_dev(+g: Gp, +nf: F64) -> F64:
  flank_dev(U64.to_nat(F64.to_u64(nf)), g, nf, 0.0f64, 0.0f64)

type Nd is Data:
  Nd{ nf: F64, dev: F64 }

def nd_pick(ok: Bool, +d12: F64, +g: Gp) -> Nd:
  match ok:
    case True{}: Nd{12.0f64, d12}
    case False{}: Nd{24.0f64, gear_dev(g, 24.0f64)}

def nd_go(+d12: F64, +g: Gp) -> Nd:
  nd_pick(F64.is_le(d12, 1.0e-3f64), d12, g)

def nf_dev(+g: Gp) -> Nd:
  nd_go(gear_dev(g, 12.0f64), g)

def nd_nf(+x: Nd) -> F64:
  Nd{+nf, dev} = x
  nf

def nd_dev(+x: Nd) -> F64:
  Nd{nf, +dev} = x
  dev

def on_c(+cx: F64, +cy: F64, +r: F64, +x: F64, +y: F64) -> Bool:
  GO.q_on_r(G.GV_cy{G.Cy{V.Pt{cx, cy, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, r}}, V.Pt{x, y, 0.0f64})

def ustep(n: Nat, +x: F64, +up: Bool) -> F64:
  match n:
    case 0n: x
    case 1n+(+k): ustep(k, Bool.pick(F64, up, E.f64_next_up(x), E.f64_next_down(x)), up)

def uoff(+x: F64, +k: F64) -> F64:
  ustep(U64.to_nat(F64.to_u64(F64.abs(k))), x, F64.is_lt(0.0f64, k))

def offs() -> List<&2, F64>:
  [0.0f64, 1.0f64, F64.neg(1.0f64), 2.0f64, F64.neg(2.0f64), 3.0f64, F64.neg(3.0f64), 4.0f64, F64.neg(4.0f64)]

def sn_ok(+s: Sn) -> Bool:
  Sn{+ok, cx, cy, r, ex, ey} = s
  ok

def dist(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> F64:
  +dx = F64.sub(ax, bx)
  +dy = F64.sub(ay, by)
  F64.sqrt(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)))

def ulp_of(+sx: F64, +sy: F64, +ex: F64, +ey: F64) -> F64:
  +m = F64.max(F64.max(F64.abs(sx), F64.abs(sy)), F64.max(F64.abs(ex), F64.abs(ey)))
  F64.sub(E.f64_next_up(m), m)

def roffs() -> List<&2, F64>:
  [0.0f64, 1.0f64, F64.neg(1.0f64), 2.0f64, F64.neg(2.0f64), 3.0f64, F64.neg(3.0f64), 4.0f64, F64.neg(4.0f64), 5.0f64, F64.neg(5.0f64), 6.0f64, F64.neg(6.0f64), 7.0f64, F64.neg(7.0f64), 8.0f64, F64.neg(8.0f64)]


def ef_ok(+e: Ef) -> Bool:
  Ef{+ok, x, y} = e
  ok

def te_j(js: List<&2, F64>, found: Bool, +best: Ef, +i: F64, +h: F64, +cx: F64, +cy: F64, +r: F64, +ex: F64, +ey: F64) -> Ef:
  match js:
    case []: best
    case +j <> t:
      match found:
        case True{}: best
        case False{}:
          +x = F64.add(ex, F64.mul(i, h))
          +y = F64.add(ey, F64.mul(j, h))
          +hit = on_c(cx, cy, r, x, y)
          te_j(t, hit, Ef{hit, x, y}, i, h, cx, cy, r, ex, ey)

def te_i(ks: List<&2, F64>, found: Bool, +best: Ef, +h: F64, +cx: F64, +cy: F64, +r: F64, +ex: F64, +ey: F64) -> Ef:
  match ks:
    case []: best
    case +i <> t:
      match found:
        case True{}: best
        case False{}:
          +e = te_j(roffs(), False{}, Ef{False{}, ex, ey}, i, h, cx, cy, r, ex, ey)
          te_i(t, ef_ok(e), e, h, cx, cy, r, ex, ey)

def sn_ef(e: Ef, +cx: F64, +cy: F64, +r: F64) -> Sn:
  Ef{+ok, +x, +y} = e
  Sn{ok, cx, cy, r, x, y}

def tr_e(fx: Bool, +cx: F64, +cy: F64, +r: F64, +h: F64, +ex: F64, +ey: F64) -> Sn:
  match fx:
    case True{}: Sn{on_c(cx, cy, r, ex, ey), cx, cy, r, ex, ey}
    case False{}: sn_ef(te_i(roffs(), False{}, Ef{False{}, ex, ey}, h, cx, cy, r, ex, ey), cx, cy, r)

def tr_at(sok: Bool, +fx: Bool, +cx: F64, +cy: F64, +r: F64, +h: F64, +ex: F64, +ey: F64) -> Sn:
  match sok:
    case False{}: Sn{False{}, cx, cy, r, ex, ey}
    case True{}: tr_e(fx, cx, cy, r, h, ex, ey)

def s_on(near: Bool, +cx: F64, +cy: F64, +r: F64, +sx: F64, +sy: F64) -> Bool:
  match near:
    case False{}: False{}
    case True{}: on_c(cx, cy, r, sx, sy)

def tr2(rs: List<&2, F64>, found: Bool, +best: Sn, +fx: Bool, +cx: F64, +cy: F64, +r0: F64, +h: F64, +sx: F64, +sy: F64, +ex: F64, +ey: F64) -> Sn:
  match rs:
    case []: best
    case +k <> t:
      match found:
        case True{}: best
        case False{}:
          +r = uoff(r0, k)
          +s = tr_at(s_on(F64.is_le(F64.abs(F64.sub(dist(sx, sy, cx, cy), r)), F64.mul(16.0f64, h)), cx, cy, r, sx, sy), fx, cx, cy, r, h, ex, ey)
          tr2(t, sn_ok(s), s, fx, cx, cy, r0, h, sx, sy, ex, ey)

def sn_at(+fx: Bool, +x: F64, +y: F64, +h: F64, +sx: F64, +sy: F64, +ex: F64, +ey: F64) -> Sn:
  tr2(roffs(), False{}, Sn{False{}, x, y, 0.0f64, ex, ey}, fx, x, y, dist(sx, sy, x, y), h, sx, sy, ex, ey)

def try_c(js: List<&2, F64>, found: Bool, +best: Sn, +fx: Bool, +i: F64, +h: F64, +cx: F64, +cy: F64, +sx: F64, +sy: F64, +ex: F64, +ey: F64) -> Sn:
  match js:
    case []: best
    case +j <> t:
      match found:
        case True{}: best
        case False{}:
          +s = sn_at(fx, F64.add(cx, F64.mul(i, h)), F64.add(cy, F64.mul(j, h)), h, sx, sy, ex, ey)
          try_c(t, sn_ok(s), s, fx, i, h, cx, cy, sx, sy, ex, ey)

def try_i(ks: List<&2, F64>, found: Bool, +best: Sn, +fx: Bool, +h: F64, +cx: F64, +cy: F64, +sx: F64, +sy: F64, +ex: F64, +ey: F64) -> Sn:
  match ks:
    case []: best
    case +i <> t:
      match found:
        case True{}: best
        case False{}:
          +s = try_c(roffs(), False{}, Sn{False{}, cx, cy, 0.0f64, ex, ey}, fx, i, h, cx, cy, sx, sy, ex, ey)
          try_i(t, sn_ok(s), s, fx, h, cx, cy, sx, sy, ex, ey)

def eq_k(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64) -> F64:
  +ux = F64.sub(bx, ax)
  +uy = F64.sub(by, ay)
  +c2 = F64.add(F64.mul(ux, ux), F64.mul(uy, uy))
  +da = dist(ax, ay, cx, cy)
  +db = dist(bx, by, cx, cy)
  F64.neg(F64.div(F64.mul(F64.sub(da, db), F64.mul(0.5f64, F64.add(da, db))), c2))

def eq_c(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64) -> V.Vec2:
  +k = eq_k(ax, ay, bx, by, cx, cy)
  V.V2{F64.add(cx, F64.mul(k, F64.sub(bx, ax))), F64.add(cy, F64.mul(k, F64.sub(by, ay)))}

def eq_c2(+ax: F64, +ay: F64, +bx: F64, +by: F64, +c: V.Vec2) -> V.Vec2:
  eq_c(ax, ay, bx, by, V.v2_x(c), V.v2_y(c))

def snap_at(+fx: Bool, +c: V.Vec2, +sx: F64, +sy: F64, +ex: F64, +ey: F64) -> Sn:
  try_i(roffs(), False{}, Sn{False{}, V.v2_x(c), V.v2_y(c), 0.0f64, ex, ey}, fx, ulp_of(sx, sy, ex, ey), V.v2_x(c), V.v2_y(c), sx, sy, ex, ey)

def snap_f(+fx: Bool, +a: Ar) -> Sn:
  Ar{+sx, +sy, +ex, +ey, +cx, +cy, +r, cw} = a
  snap_at(fx, eq_c2(sx, sy, ex, ey, eq_c(sx, sy, ex, ey, cx, cy)), sx, sy, ex, ey)

def snap(+a: Ar) -> Sn:
  snap_f(False{}, a)

type Ac is Data:
  Ac{ ok: Bool, segs: List<&2, F.Seg>, px: F64, py: F64 }

def xk(+v: F64) -> X.Xp:
  X.X_k{v}

def ac_sn(sn: Sn, +ok: Bool, +segs: List<&2, F.Seg>, +ccw: Bool) -> Ac:
  Sn{+sok, +scx, +scy, +sr, +sex, +sey} = sn
  Ac{Bool.and(ok, sok), F.S_arc{xk(scx), xk(scy), xk(sr), xk(sex), xk(sey), ccw} <> segs, sex, sey}

def ac_addf(+fx: Bool, +a: Ar, +acc: Ac) -> Ac:
  Ar{sx, sy, +ex, +ey, +cx, +cy, +r, +ccw} = a
  Ac{+ok, +segs, +px, +py} = acc
  ac_sn(snap_f(fx, Ar{px, py, ex, ey, cx, cy, r, ccw}), ok, segs, ccw)

def ac_add(+a: Ar, +acc: Ac) -> Ac:
  ac_addf(False{}, a, acc)

def ln_add(+x: F64, +y: F64, +acc: Ac) -> Ac:
  Ac{+ok, +segs, px, py} = acc
  Ac{ok, F.S_line{xk(x), xk(y)} <> segs, x, y}

def rot(+c: F64, +s: F64, +x: F64, +y: F64) -> V.Vec2:
  V.V2{F64.sub(F64.mul(c, x), F64.mul(s, y)), F64.add(F64.mul(s, x), F64.mul(c, y))}

def ar_rot(+c: F64, +s: F64, +a: Ar) -> Ar:
  Ar{+sx, +sy, +ex, +ey, +cx, +cy, +r, +ccw} = a
  +p = rot(c, s, sx, sy)
  +q = rot(c, s, ex, ey)
  +o = rot(c, s, cx, cy)
  Ar{V.v2_x(p), V.v2_y(p), V.v2_x(q), V.v2_y(q), V.v2_x(o), V.v2_y(o), r, ccw}

def ar_mir(+a: Ar) -> Ar:
  Ar{+sx, +sy, +ex, +ey, +cx, +cy, +r, +ccw} = a
  Ar{ex, F64.neg(ey), sx, F64.neg(sy), cx, F64.neg(cy), r, ccw}

def up_arcs(n: Nat, +g: Gp, +nf: F64, +i: F64, +acc: List<&2, Ar>) -> List<&2, Ar>:
  match n:
    case 0n: acc
    case 1n+(+k): up_arcs(k, g, nf, F64.add(i, 1.0f64), flank_arc(g, brk(g, nf, i), brk(g, nf, F64.add(i, 1.0f64))) <> acc)

def lo_arcs(xs: List<&2, Ar>, +acc: List<&2, Ar>) -> List<&2, Ar>:
  match xs:
    case []: acc
    case +a <> t: lo_arcs(t, ar_mir(a) <> acc)

def add_arcs(xs: List<&2, Ar>, +c: F64, +s: F64, +acc: Ac) -> Ac:
  match xs:
    case []: acc
    case +a <> t: add_arcs(t, c, s, ac_add(ar_rot(c, s, a), acc))

def pol(+r: F64, +a: F64) -> V.Vec2:
  V.V2{F64.mul(r, cosd(deg(a))), F64.mul(r, sind(deg(a)))}

def proj(+c: V.Vec2, +u: V.Vec2) -> V.Vec2:
  +k = F64.add(F64.mul(V.v2_x(c), V.v2_x(u)), F64.mul(V.v2_y(c), V.v2_y(u)))
  V.V2{F64.mul(k, V.v2_x(u)), F64.mul(k, V.v2_y(u))}

def to_root(+c: V.Vec2, +rho: F64) -> V.Vec2:
  +n = F64.sqrt(F64.add(F64.mul(V.v2_x(c), V.v2_x(c)), F64.mul(V.v2_y(c), V.v2_y(c))))
  +k = F64.div(F64.sub(n, rho), n)
  V.V2{F64.mul(k, V.v2_x(c)), F64.mul(k, V.v2_y(c))}

def root_ar(+g: Gp, +th: F64) -> List<&2, Ar>:
  +rf = gp_rf(g)
  +rho = gp_rho(g)
  +rc = F64.add(rf, rho)
  +bt = asin1(F64.div(rho, rc))
  +p0 = gp_psi0(g)
  +step = F64.div(6.283185307179586f64, gp_z(g))
  +c1 = pol(rc, F64.add(th, F64.add(p0, bt)))
  +c2 = pol(rc, F64.sub(F64.add(th, step), F64.add(p0, bt)))
  +q1 = proj(c1, pol(1.0f64, F64.add(th, p0)))
  +q2 = to_root(c1, rho)
  +q3 = to_root(c2, rho)
  +q4 = proj(c2, pol(1.0f64, F64.sub(F64.add(th, step), p0)))
  [Ar{V.v2_x(q1), V.v2_y(q1), V.v2_x(q2), V.v2_y(q2), V.v2_x(c1), V.v2_y(c1), rho, False{}},
   Ar{V.v2_x(q2), V.v2_y(q2), V.v2_x(q3), V.v2_y(q3), 0.0f64, 0.0f64, rf, True{}},
   Ar{V.v2_x(q3), V.v2_y(q3), V.v2_x(q4), V.v2_y(q4), V.v2_x(c2), V.v2_y(c2), rho, False{}}]

def root_go(xs: List<&2, Ar>, +acc: Ac) -> Ac:
  match xs:
    case []: acc
    case +a <> t: root_go(t, ac_add(a, acc))

def tip_ar(+g: Gp, +c: F64, +s: F64) -> Ar:
  +t = gp_tmax(g)
  +x = inv_x(g, t)
  +y = inv_y(g, t)
  ar_rot(c, s, Ar{x, F64.neg(y), x, y, 0.0f64, 0.0f64, gp_ra(g), True{}})

def t_start(+g: Gp, +k: F64) -> V.Vec2:
  pol(inv_rho(g, gp_t0(g)), F64.sub(F64.div(F64.mul(6.283185307179586f64, k), gp_z(g)), inv_psi(g, gp_t0(g))))

def tooth(+g: Gp, +up: List<&2, Ar>, +lo: List<&2, Ar>, +k: F64, +last: Bool, +acc: Ac) -> Ac:
  +th = F64.div(F64.mul(6.283185307179586f64, k), gp_z(g))
  +c = cosd(deg(th))
  +s = sind(deg(th))
  +rb = gp_rb(g)
  +p0 = gp_psi0(g)
  +b1 = rot(c, s, F64.mul(rb, cosd(deg(p0))), F64.mul(rb, sind(deg(p0))))
  +rc = F64.add(gp_rf(g), gp_rho(g))
  +q1 = proj(pol(rc, F64.add(th, F64.add(p0, asin1(F64.div(gp_rho(g), rc))))), pol(1.0f64, F64.add(th, p0)))
  +nb = t_start(g, F64.add(k, 1.0f64))
  +a1 = add_arcs(lo, c, s, acc)
  +a2 = ac_add(tip_ar(g, c, s), a1)
  +a3 = add_arcs(up, c, s, a2)
  +a4 = root_go(root_ar(g, th), ln_add(V.v2_x(q1), V.v2_y(q1), a3))
  Bool.pick(Ac, last, a4, ln_add(V.v2_x(nb), V.v2_y(nb), a4))

type Tc is Data:
  Tc{ g: Gp, up: List<&2, Ar>, lo: List<&2, Ar> }

def tooth_k2(+c: Tc, +k: F64) -> Ac:
  Tc{+g, +up, +lo} = c
  +p = t_start(g, k)
  tooth(g, up, lo, k, F64.is_eq(F64.add(k, 1.0f64), gp_z(g)), Ac{True{}, [], V.v2_x(p), V.v2_y(p)})

def tooth_k(c: Tc, k: F64) -> Ac:
  tooth_k2(c, k)

def ks_of(n: Nat, +k: F64) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+j): k <> ks_of(j, F64.add(k, 1.0f64))

def ac_px(a: Ac) -> F64:
  Ac{ok, segs, +px, py} = a
  px

def ac_py(a: Ac) -> F64:
  Ac{ok, segs, px, +py} = a
  py

def ac_okk(a: Ac) -> Bool:
  Ac{+ok, segs, px, py} = a
  ok

def ac_segs(a: Ac) -> List<&2, F.Seg>:
  Ac{ok, +segs, px, py} = a
  segs

def segs_rev(xs: List<&2, F.Seg>, +acc: List<&2, F.Seg>) -> List<&2, F.Seg>:
  match xs:
    case []: acc
    case +x <> t: segs_rev(t, x <> acc)

type Gr is Data:
  Gr{ ok: Bool, rg: F.Region, nf: F64, dev: F64 }

def cat_go(xs: List<&2, Ac>, +ok: Bool, +acc: List<&2, F.Seg>) -> Ac:
  match xs:
    case []: Ac{ok, acc, 0.0f64, 0.0f64}
    case +a <> t: cat_go(t, Bool.and(ok, ac_okk(a)), List.append(&2, F.Seg, acc, segs_rev(ac_segs(a), [])))

def teeth(+g: Gp, +up: List<&2, Ar>, +lo: List<&2, Ar>) -> Ac:
  cat_go(B.pmap_g(~F64, ~Tc, ~Ac, ~tooth_k, 1, Tc{g, up, lo}, ks_of(U64.to_nat(F64.to_u64(gp_z(g))), 0.0f64)), True{}, [])

def v2s(+v: V.Vec2, +k: F64) -> V.Vec2:
  V.V2{F64.mul(k, V.v2_x(v)), F64.mul(k, V.v2_y(v))}

def fa_tooth(+g: Gp, +up: List<&2, Ar>, +lo: List<&2, Ar>, +k: F64, +last: Bool, +acc: Ac) -> Ac:
  +th = F64.div(F64.mul(6.283185307179586f64, k), gp_z(g))
  +th1 = F64.div(F64.mul(6.283185307179586f64, F64.add(k, 1.0f64)), gp_z(g))
  +c = cosd(deg(th))
  +s = sind(deg(th))
  +c1 = cosd(deg(th1))
  +s1 = sind(deg(th1))
  +cl = fil_c(g, gp_t0(g), gp_rho(g))
  +rl = v2s(cl, F64.div(gp_rf(g), v2n(cl)))
  +cw1 = rot(c, s, V.v2_x(cl), V.v2_y(cl))
  +rw1 = rot(c, s, V.v2_x(rl), V.v2_y(rl))
  +cw2 = rot(c1, s1, V.v2_x(cl), F64.neg(V.v2_y(cl)))
  +rw2 = rot(c1, s1, V.v2_x(rl), F64.neg(V.v2_y(rl)))
  +nb = Bool.pick(V.Vec2, last, t_start(g, 0.0f64), t_start(g, F64.add(k, 1.0f64)))
  +a3 = add_arcs(up, c, s, ac_add(tip_ar(g, c, s), add_arcs(lo, c, s, acc)))
  +a4 = ac_add(Ar{0.0f64, 0.0f64, V.v2_x(rw1), V.v2_y(rw1), V.v2_x(cw1), V.v2_y(cw1), gp_rho(g), False{}}, a3)
  +a5 = ac_add(Ar{0.0f64, 0.0f64, V.v2_x(rw2), V.v2_y(rw2), 0.0f64, 0.0f64, gp_rf(g), True{}}, a4)
  ac_addf(last, Ar{0.0f64, 0.0f64, V.v2_x(nb), V.v2_y(nb), V.v2_x(cw2), V.v2_y(cw2), gp_rho(g), False{}}, a5)

def fa_teeth(n: Nat, +g: Gp, +up: List<&2, Ar>, +lo: List<&2, Ar>, +k: F64, +acc: Ac) -> Ac:
  match n:
    case 0n: acc
    case 1n+(+j): fa_teeth(j, g, up, lo, F64.add(k, 1.0f64), fa_tooth(g, up, lo, k, Nat.is_eq(j, 0n), acc))

def ac_rev(a: Ac) -> Ac:
  Ac{+ok, +segs, +px, +py} = a
  Ac{ok, segs_rev(segs, []), px, py}

def teeth_any(fa: Bool, +g: Gp, +up: List<&2, Ar>, +lo: List<&2, Ar>, +x0: F64, +y0: F64) -> Ac:
  match fa:
    case True{}: ac_rev(fa_teeth(U64.to_nat(F64.to_u64(gp_z(g))), g, up, lo, 0.0f64, Ac{True{}, [], x0, y0}))
    case False{}: teeth(g, up, lo)

def root_s(+g: Gp) -> String:
  Bool.pick(String, gp_fa(g), "root: fillet arc of radius 0.38 m tangent to the involute at d=" ++ F64.show(F64.mul(2.0f64, inv_rho(g, gp_t0(g)))) ++
    " (below the form circle of the ISO 53 rack) and to the root circle, not the generated trochoid",
    "root: radial line and fillet arc of radius " ++ F64.show(gp_rho(g)) ++ ", not the generated trochoid")

def gr_of(a: Ac, +x0: F64, +y0: F64, +bore: F64, +nf: F64, +dev: F64) -> Gr:
  Ac{+ok, +segs, ex, ey} = a
  Gr{ok, F.Rg{F.L_path{xk(x0), xk(y0), segs}, [F.L_circ{xk(0.0f64), xk(0.0f64), xk(bore)}]}, nf, dev}

def gear_rg(+g: Gp, +bore: F64) -> Gr:
  +nd = nf_dev(g)
  +nf = nd_nf(nd)
  +up = up_arcs(U64.to_nat(F64.to_u64(nf)), g, nf, 0.0f64, [])
  +lo = lo_arcs(up, [])
  +p0 = t_start(g, 0.0f64)
  gr_of(teeth_any(gp_fa(g), g, up, lo, V.v2_x(p0), V.v2_y(p0)), V.v2_x(p0), V.v2_y(p0), bore, nf, nd_dev(nd))

def contact_ratio(+g1: Gp, +g2: Gp) -> F64:
  +a = F64.mul(gp_m(g1), F64.mul(0.5f64, F64.add(gp_z(g1), gp_z(g2))))
  +l1 = F64.sqrt(F64.sub(F64.mul(gp_ra(g1), gp_ra(g1)), F64.mul(gp_rb(g1), gp_rb(g1))))
  +l2 = F64.sqrt(F64.sub(F64.mul(gp_ra(g2), gp_ra(g2)), F64.mul(gp_rb(g2), gp_rb(g2))))
  F64.div(F64.sub(F64.add(l1, l2), F64.mul(a, sind(alpha()))), F64.mul(F64.mul(3.141592653589793f64, gp_m(g1)), cosd(alpha())))
