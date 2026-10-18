import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../c04/types.bend as Ty
import ../c04/ops.bend as B4
import ./sf.bend as S
import ./ls.bend as L

type BR is Data:
  BR{ a: F64, b: F64 }

type SM is Data:
  SM{ brs: List<&2, BR>, near: Bool, zeros: Nat }

type UV is Data:
  UV{ ok: Bool, u: F64, v: F64 }

type CT is Data:
  CT{ ok: Bool, t: F64, p: V.Point }

type EH is Data:
  EH{ t: F64, p: V.Point, ok: Bool }

type EHS is Data:
  EHS{ hs: List<&2, EH>, near: Bool }

def ek_curve(+k: Ty.EdgeKind) -> G.GVal:
  match k:
    case Ty.EK_curve{+c, +d}: c
    case Ty.EK_degenerate{}: G.GV_f{0.0f64}

def ek_lo(+k: Ty.EdgeKind) -> F64:
  match k:
    case Ty.EK_curve{+c, +d}: G.dom_lo(d)
    case Ty.EK_degenerate{}: 0.0f64

def ek_hi(+k: Ty.EdgeKind) -> F64:
  match k:
    case Ty.EK_curve{+c, +d}: G.dom_hi(d)
    case Ty.EK_degenerate{}: 0.0f64

def ek_is_curve(+k: Ty.EdgeKind) -> Bool:
  match k:
    case Ty.EK_curve{+c, +d}: True{}
    case Ty.EK_degenerate{}: False{}

def ev(+c: G.GVal, +t: F64) -> V.Point:
  G.gres_p(B4.curve_at(c, t, 64n))

def fval(+s: S.SF, +c: G.GVal, +t: F64) -> F64:
  S.sf_f(s, ev(c, t))

def sgn(+x: F64) -> U64:
  Bool.pick(U64, F64.is_lt(x, 0.0f64), 0u64, Bool.pick(U64, F64.is_lt(0.0f64, x), 2u64, 1u64))

def br_a(+r: BR) -> F64:
  BR{a, b} = r
  a

def br_b(+r: BR) -> F64:
  BR{a, b} = r
  b

def sm_brs(+m: SM) -> List<&2, BR>:
  SM{brs, near, zeros} = m
  brs

def sm_zeros(+m: SM) -> Nat:
  SM{brs, near, zeros} = m
  zeros

def sm_near(+m: SM) -> Bool:
  SM{brs, near, zeros} = m
  near

def nsamp() -> Nat:
  96n

def near_tol(+s: S.SF) -> F64:
  F64.mul(1.0e-9f64, F64.add(1.0f64, F64.mul(S.sf_r(s), S.sf_r(s))))

def samp_go(n: Nat, +s: S.SF, +c: G.GVal, +lo: F64, +step: F64, +k: F64, +pt: F64, +pf: F64,
    +ppf: F64, +tol: F64, +acc: List<&2, BR>, +near: Bool, +zs: Nat) -> SM:
  match n:
    case 0n: SM{acc, near, zs}
    case 1n+m:
      +t = F64.add(lo, F64.mul(k, step))
      +f = fval(s, c, t)
      +cross = Bool.not(U64.is_eq(U64.mul(sgn(pf), 1u64), sgn(f)))
      +zero = F64.is_eq(f, 0.0f64)
      +pzero = F64.is_eq(pf, 0.0f64)
      +nb = Bool.pick(List<&2, BR>, zero, BR{t, t} <> acc,
        Bool.pick(List<&2, BR>, Bool.and(cross, Bool.not(pzero)), BR{pt, t} <> acc, acc))
      +mn = Bool.and(F64.is_le(F64.abs(pf), F64.abs(ppf)), F64.is_le(F64.abs(pf), F64.abs(f)))
      +nr = Bool.and(mn, Bool.and(F64.is_lt(F64.abs(pf), tol), Bool.not(pzero)))
      +samesg = Bool.and(U64.is_eq(sgn(ppf), sgn(pf)), U64.is_eq(sgn(pf), sgn(f)))
      samp_go(m, s, c, lo, step, F64.add(k, 1.0f64), t, f, pf, tol, nb,
        Bool.or(near, Bool.and(nr, samesg)), Bool.pick(Nat, zero, Nat.add(zs, 1n), zs))

def sample(+s: S.SF, +c: G.GVal, +lo: F64, +hi: F64) -> SM:
  +step = F64.div(F64.sub(hi, lo), L.f64_of(nsamp()))
  +f0 = fval(s, c, lo)
  +b0 = Bool.pick(List<&2, BR>, F64.is_eq(f0, 0.0f64), [BR{lo, lo}], [])
  samp_go(nsamp(), s, c, lo, step, 1.0f64, lo, f0, f0, near_tol(s), b0, False{}, 0n)

def bis_code(+s: S.SF, +c: G.GVal, +a: F64, +sa: U64, +b: F64) -> U64:
  +mid = F64.mul(0.5f64, F64.add(a, b))
  +sm = sgn(fval(s, c, mid))
  +stop = Bool.or(Bool.or(F64.is_eq(mid, a), F64.is_eq(mid, b)), U64.is_eq(sm, 1u64))
  Bool.pick(U64, stop, 1u64, Bool.pick(U64, U64.is_eq(sm, sa), 2u64, 3u64))

def bis(n: Nat, +mode: U64, +s: S.SF, +c: G.GVal, +a: F64, +sa: U64, +b: F64) -> F64:
  match n:
    case 0n: F64.mul(0.5f64, F64.add(a, b))
    case 1n+(+m):
      match mode:
        case 0u64: bis(m, bis_code(s, c, a, sa, b), s, c, a, sa, b)
        case 1u64: F64.mul(0.5f64, F64.add(a, b))
        case 2u64: bis(m, 0u64, s, c, F64.mul(0.5f64, F64.add(a, b)), sa, b)
        case _: bis(m, 0u64, s, c, a, sa, F64.mul(0.5f64, F64.add(a, b)))

def root_go(+same: Bool, +s: S.SF, +c: G.GVal, +a: F64, +b: F64) -> F64:
  match same:
    case True{}: a
    case False{}: bis(400n, 0u64, s, c, a, sgn(fval(s, c, a)), b)

def root_of(+s: S.SF, +c: G.GVal, +r: BR) -> F64:
  root_go(F64.is_eq(br_a(r), br_b(r)), s, c, br_a(r), br_b(r))

def ulp_of(+t: F64) -> F64:
  F64.max(F64.mul(F64.abs(t), 2.220446049250313e-16f64), 4.9e-324f64)

def uv_ok(+r: UV) -> Bool:
  UV{ok, u, v} = r
  ok

def uv_u(+r: UV) -> F64:
  UV{ok, u, v} = r
  u

def uv_v(+r: UV) -> F64:
  UV{ok, u, v} = r
  v

def offs() -> List<&2, F64>:
  [0.0f64, 1.0f64, F64.neg(1.0f64), 2.0f64, F64.neg(2.0f64), 3.0f64, F64.neg(3.0f64), 4.0f64,
    F64.neg(4.0f64)]

def pl_hit(+o: V.Point, +e1: V.Dir, +e2: V.Dir, +p: V.Point, +u: F64, +v: F64) -> Bool:
  +q = GO.plane_eval_raw(o, e1, e2, u, v)
  Bool.and(F64.is_eq(V.pt_x(q), V.pt_x(p)),
    Bool.and(F64.is_eq(V.pt_y(q), V.pt_y(p)), F64.is_eq(V.pt_z(q), V.pt_z(p))))

def pl_scan_v(vs: List<&2, F64>, +o: V.Point, +e1: V.Dir, +e2: V.Dir, +p: V.Point, +u: F64,
    +v0: F64, +dv: F64) -> UV:
  match vs:
    case []: UV{False{}, u, v0}
    case +h <> +t:
      +v = F64.add(v0, F64.mul(h, dv))
      Bool.pick(UV, pl_hit(o, e1, e2, p, u, v), UV{True{}, u, v},
        pl_scan_v(t, o, e1, e2, p, u, v0, dv))

def pl_scan_u(us: List<&2, F64>, +o: V.Point, +e1: V.Dir, +e2: V.Dir, +p: V.Point, +u0: F64,
    +du: F64, +v0: F64, +dv: F64) -> UV:
  match us:
    case []: UV{False{}, u0, v0}
    case +h <> +t:
      +r = pl_scan_v(offs(), o, e1, e2, p, F64.add(u0, F64.mul(h, du)), v0, dv)
      Bool.pick(UV, uv_ok(r), r, pl_scan_u(t, o, e1, e2, p, u0, du, v0, dv))

def bp_hit(+w: G.BezP, +p: V.Point, +u: F64, +v: F64) -> Bool:
  +r = GO.bezp_eval(w, u, v)
  +q = G.gres_p(r)
  Bool.and(G.gres_ok(r), Bool.and(F64.is_eq(V.pt_x(q), V.pt_x(p)),
    Bool.and(F64.is_eq(V.pt_y(q), V.pt_y(p)), F64.is_eq(V.pt_z(q), V.pt_z(p)))))

def bp_scan_v(vs: List<&2, F64>, +w: G.BezP, +p: V.Point, +u: F64, +v0: F64, +dv: F64) -> UV:
  match vs:
    case []: UV{False{}, u, v0}
    case +h <> +t:
      +v = F64.max(0.0f64, F64.min(1.0f64, F64.add(v0, F64.mul(h, dv))))
      Bool.pick(UV, bp_hit(w, p, u, v), UV{True{}, u, v}, bp_scan_v(t, w, p, u, v0, dv))

def bp_scan_u(us: List<&2, F64>, +w: G.BezP, +p: V.Point, +u0: F64, +du: F64, +v0: F64, +dv: F64) -> UV:
  match us:
    case []: UV{False{}, u0, v0}
    case +h <> +t:
      +r = bp_scan_v(offs(), w, p, F64.max(0.0f64, F64.min(1.0f64, F64.add(u0, F64.mul(h, du)))), v0, dv)
      Bool.pick(UV, uv_ok(r), r, bp_scan_u(t, w, p, u0, du, v0, dv))

def snap01(+x: F64) -> F64:
  Bool.pick(F64, F64.is_lt(F64.abs(x), 1.0e-12f64), 0.0f64, Bool.pick(F64, F64.is_lt(F64.abs(F64.sub(x, 1.0f64)), 1.0e-12f64), 1.0f64, x))

def bp_pt(+w: G.BezP, +u: F64, +v: F64) -> V.Point:
  G.gres_p(GO.bezp_eval(w, F64.max(0.0f64, F64.min(1.0f64, u)), F64.max(0.0f64, F64.min(1.0f64, v))))

def bp_step(+w: G.BezP, +p: V.Point, +q: V.Vec2) -> V.Vec2:
  +u = V.v2_x(q)
  +v = V.v2_y(q)
  +h = {1.0e-6f64 : F64}
  +uh = Bool.pick(F64, F64.is_lt(u, 0.5f64), F64.add(u, h), F64.sub(u, h))
  +vh = Bool.pick(F64, F64.is_lt(v, 0.5f64), F64.add(v, h), F64.sub(v, h))
  +p0 = bp_pt(w, u, v)
  +ju = S.dscale(F64.div(1.0f64, F64.sub(uh, u)), S.psub(bp_pt(w, uh, v), p0))
  +jv = S.dscale(F64.div(1.0f64, F64.sub(vh, v)), S.psub(bp_pt(w, u, vh), p0))
  +r = S.psub(p, p0)
  +a11 = S.dot(ju, ju)
  +a12 = S.dot(ju, jv)
  +a22 = S.dot(jv, jv)
  +b1 = S.dot(ju, r)
  +b2 = S.dot(jv, r)
  +det = F64.sub(F64.mul(a11, a22), F64.mul(a12, a12))
  +du = F64.div(F64.sub(F64.mul(b1, a22), F64.mul(b2, a12)), det)
  +dv = F64.div(F64.sub(F64.mul(b2, a11), F64.mul(b1, a12)), det)
  +ok = F64.is_lt(1.0e-300f64, F64.abs(det))
  Bool.pick(V.Vec2, ok, V.V2{F64.add(u, du), F64.add(v, dv)}, q)

def bp_newton(n: Nat, +w: G.BezP, +p: V.Point, +q: V.Vec2) -> V.Vec2:
  match n:
    case 0n: q
    case 1n+m: bp_newton(m, w, p, bp_step(w, p, q))

def bp_uv_of(+w: G.BezP, +p: V.Point) -> UV:
  G.Bp{+p00, p01, p02, +p03, p10, p11, p12, p13, p20, p21, p22, p23, +p30, p31, p32, p33} = w
  +a = S.psub(p03, p00)
  +b = S.psub(p30, p00)
  +d = S.psub(p, p00)
  +aa = S.dot(a, a)
  +ab = S.dot(a, b)
  +bb = S.dot(b, b)
  +da = S.dot(d, a)
  +db = S.dot(d, b)
  +det = F64.sub(F64.mul(aa, bb), F64.mul(ab, ab))
  +u1 = F64.div(F64.sub(F64.mul(da, bb), F64.mul(db, ab)), det)
  +v1 = F64.div(F64.sub(F64.mul(db, aa), F64.mul(da, ab)), det)
  +uv = bp_newton(12n, w, p, V.V2{u1, v1})
  +u0 = snap01(V.v2_x(uv))
  +v0 = snap01(V.v2_y(uv))
  bp_scan_u(offs(), w, p, u0, ulp_of(F64.max(u0, 0.5f64)), v0, ulp_of(F64.max(v0, 0.5f64)))

def pl_uv(+g: G.GVal, +p: V.Point) -> UV:
  match g:
    case G.GV_pl{w}:
      G.Pl{+o, +e1, +e2} = w
      +d = S.psub(p, o)
      +u0 = S.dot(d, e1)
      +v0 = S.dot(d, e2)
      pl_scan_u(offs(), o, e1, e2, p, u0, ulp_of(u0), v0, ulp_of(v0))
    case G.GV_bp{w}: bp_uv_of(w, p)
    case _: UV{False{}, 0.0f64, 0.0f64}

def on_g(+g: G.GVal, +p: V.Point) -> Bool:
  match g:
    case G.GV_pl{w}: Bool.or(uv_ok(pl_uv(G.GV_pl{w}, p)), Bool.and(B4.surf_obl(G.GV_pl{w}), GO.q_on_r(G.GV_pl{w}, p)))
    case G.GV_bp{w}: Bool.or(uv_ok(bp_uv_of(w, p)), GO.q_on_r(G.GV_bp{w}, p))
    case _: GO.q_on_r(g, p)

def on_all(gs: List<&2, G.GVal>, +p: V.Point) -> Bool:
  match gs:
    case []: True{}
    case +h <> +t: Bool.and(on_g(h, p), on_all(t, p))

def ct_ok(+c: CT) -> Bool:
  CT{ok, t, p} = c
  ok

def ct_t(+c: CT) -> F64:
  CT{ok, t, p} = c
  t

def ct_p(+c: CT) -> V.Point:
  CT{ok, t, p} = c
  p

def cert_code(+c: G.GVal, +gs: List<&2, G.GVal>, +t0: F64, +u: F64, +k: F64, +lo: F64,
    +hi: F64) -> U64:
  +tp = F64.add(t0, F64.mul(k, u))
  +tm = F64.sub(t0, F64.mul(k, u))
  +okp = Bool.and(Bool.and(F64.is_le(lo, tp), F64.is_le(tp, hi)), on_all(gs, ev(c, tp)))
  +okm = Bool.and(Bool.and(F64.is_le(lo, tm), F64.is_le(tm, hi)), on_all(gs, ev(c, tm)))
  Bool.pick(U64, okp, 1u64, Bool.pick(U64, okm, 2u64, 3u64))

def cert_go(n: Nat, +mode: U64, +c: G.GVal, +gs: List<&2, G.GVal>, +t0: F64, +u: F64, +k: F64,
    +lo: F64, +hi: F64) -> CT:
  match n:
    case 0n: CT{False{}, t0, ev(c, t0)}
    case 1n+(+m):
      match mode:
        case 0u64: cert_go(m, cert_code(c, gs, t0, u, k, lo, hi), c, gs, t0, u, k, lo, hi)
        case 1u64: CT{True{}, F64.add(t0, F64.mul(k, u)), ev(c, F64.add(t0, F64.mul(k, u)))}
        case 2u64: CT{True{}, F64.sub(t0, F64.mul(k, u)), ev(c, F64.sub(t0, F64.mul(k, u)))}
        case _: cert_go(m, 0u64, c, gs, t0, u, F64.add(k, 1.0f64), lo, hi)

def nudges() -> List<&2, F64>:
  [0.0f64, 1.0f64, F64.neg(1.0f64), 2.0f64, F64.neg(2.0f64)]

def nz_go(zs: List<&2, F64>, +gs: List<&2, G.GVal>, +x: F64, +y: F64, +z: F64, +uz: F64) -> CT:
  match zs:
    case []: CT{False{}, 0.0f64, S.pt(x, y, z)}
    case +h <> +t:
      +q = S.pt(x, y, F64.add(z, F64.mul(h, uz)))
      Bool.pick(CT, on_all(gs, q), CT{True{}, 0.0f64, q}, nz_go(t, gs, x, y, z, uz))

def ny_go(ys: List<&2, F64>, +gs: List<&2, G.GVal>, +x: F64, +y: F64, +z: F64, +uy: F64, +uz: F64) -> CT:
  match ys:
    case []: CT{False{}, 0.0f64, S.pt(x, y, z)}
    case +h <> +t:
      +r = nz_go(nudges(), gs, x, F64.add(y, F64.mul(h, uy)), z, uz)
      Bool.pick(CT, ct_ok(r), r, ny_go(t, gs, x, y, z, uy, uz))

def nx_go(xs: List<&2, F64>, +gs: List<&2, G.GVal>, +x: F64, +y: F64, +z: F64, +ux: F64, +uy: F64,
    +uz: F64) -> CT:
  match xs:
    case []: CT{False{}, 0.0f64, S.pt(x, y, z)}
    case +h <> +t:
      +r = ny_go(nudges(), gs, F64.add(x, F64.mul(h, ux)), y, z, uy, uz)
      Bool.pick(CT, ct_ok(r), r, nx_go(t, gs, x, y, z, ux, uy, uz))

def cert_gs(+gs: List<&2, G.GVal>, +p: V.Point) -> CT:
  +x = S.px(p)
  +y = S.py(p)
  +z = S.pz(p)
  nx_go(nudges(), gs, x, y, z, ulp_of(x), ulp_of(y), ulp_of(z))

def g_at(gs: List<&2, G.GVal>, +i: Nat) -> G.GVal:
  match gs:
    case []: G.GV_f{0.0f64}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: g_at(t, j)

def cert_snap(+c: G.GVal, +gs: List<&2, G.GVal>, +t: F64) -> CT:
  +s1 = S.sf_of(g_at(gs, 0n))
  +s2 = S.sf_of(g_at(gs, 1n))
  +p0 = ev(c, t)
  +tn = S.dunit(S.cross(S.sf_grad(s1, p0), S.sf_grad(s2, p0)))
  +r = cert_gs(gs, S.newton2(6n, s1, s2, p0, tn, p0))
  CT{ct_ok(r), t, ct_p(r)}

def cert_fb(+r: CT, +c: G.GVal, +gs: List<&2, G.GVal>, +t: F64) -> CT:
  match r:
    case CT{ok, tt, p}:
      match ok:
        case True{}: CT{True{}, tt, p}
        case False{}: cert_snap(c, gs, t)

def cert_t0(+ok: Bool, +c: G.GVal, +gs: List<&2, G.GVal>, +t: F64, +lo: F64, +hi: F64) -> CT:
  match ok:
    case True{}: CT{True{}, t, ev(c, t)}
    case False{}: cert_fb(cert_go(128n, 0u64, c, gs, t, ulp_of(t), 1.0f64, lo, hi), c, gs, t)

def cert_t(+c: G.GVal, +gs: List<&2, G.GVal>, +t: F64, +lo: F64, +hi: F64) -> CT:
  cert_t0(on_all(gs, ev(c, t)), c, gs, t, lo, hi)

def eh_t(+h: EH) -> F64:
  EH{t, p, ok} = h
  t

def eh_p(+h: EH) -> V.Point:
  EH{t, p, ok} = h
  p

def eh_ok(+h: EH) -> Bool:
  EH{t, p, ok} = h
  ok

def hits_go(brs: List<&2, BR>, +s: S.SF, +c: G.GVal, +gs: List<&2, G.GVal>, +lo: F64, +hi: F64)
    -> List<&2, EH>:
  match brs:
    case []: []
    case +h <> +t:
      +r = root_of(s, c, h)
      +ct = cert_t(c, gs, r, lo, hi)
      EH{ct_t(ct), ct_p(ct), ct_ok(ct)} <> hits_go(t, s, c, gs, lo, hi)

def ehs_hs(+e: EHS) -> List<&2, EH>:
  EHS{hs, near} = e
  hs

def ehs_near(+e: EHS) -> Bool:
  EHS{hs, near} = e
  near

def edge_hits_go(+isc: Bool, +s: S.SF, +c: G.GVal, +gs: List<&2, G.GVal>, +lo: F64, +hi: F64)
    -> EHS:
  match isc:
    case True{}:
      +sm = sample(s, c, lo, hi)
      +emb = Nat.is_le(3n, sm_zeros(sm))
      Bool.pick(EHS, emb, EHS{[], False{}}, EHS{List.reverse(&2, EH, hits_go(sm_brs(sm), s, c, gs, lo, hi)), sm_near(sm)})
    case False{}: EHS{[], False{}}

def edge_hits(+k: Ty.EdgeKind, +s: S.SF, +gs: List<&2, G.GVal>) -> EHS:
  edge_hits_go(ek_is_curve(k), s, ek_curve(k), gs, ek_lo(k), ek_hi(k))
