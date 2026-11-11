import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../c04/types.bend as Ty
import ../c04/ops.bend as B4
import ./sf.bend as S
import ./ls.bend as L
import ../c06/iv.bend as I
import ../c07/isect.bend as Y
import ../c03/bpi.bend as BI
import ../c16/skcert.bend as SC



type BR is Data:
  BR{ a: F64, b: F64 }



type SM is Data:
  SM{ brs: List<&2, BR>, near: Bool, zeros: Nat, nt: F64 }



type UV is Data:
  UV{ ok: Bool, u: F64, v: F64 }



type CT is Data:
  CT{ ok: Bool, t: F64, p: V.Point }



type EH is Data:
  EH{ t: F64, p: V.Point, ok: Bool }



type EHS is Data:
  EHS{ hs: List<&2, EH>, near: Bool, nt: F64 }




type CQ is Data:
  CQ{ a: F64, b: F64, ps: List<&2, G.BezP> }



type B6 is Data:
  B6{ x0: F64, x1: F64, y0: F64, y1: F64, z0: F64, z1: F64 }

type PP is Data:
  PP{ a: G.BezP, b: G.BezP }

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
  SM{brs, near, zeros, nt} = m
  brs

def sm_zeros(+m: SM) -> Nat:
  SM{brs, near, zeros, nt} = m
  zeros

def sm_near(+m: SM) -> Bool:
  SM{brs, near, zeros, nt} = m
  near

def sm_nt(+m: SM) -> F64:
  SM{brs, near, zeros, nt} = m
  nt

def nsamp() -> Nat:
  96n

def near_tol(+s: S.SF) -> F64:
  F64.mul(1.0e-9f64, F64.add(1.0f64, F64.mul(S.sf_r(s), S.sf_r(s))))

def samp_go(n: Nat, +s: S.SF, +c: G.GVal, +lo: F64, +step: F64, +k: F64, +pt: F64, +pf: F64,
    +ppf: F64, +tol: F64, +acc: List<&2, BR>, +near: Bool, +zs: Nat, +nt: F64) -> SM:
  match n:
    case 0n: SM{acc, near, zs, nt}
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
      +hit = Bool.and(nr, samesg)
      samp_go(m, s, c, lo, step, F64.add(k, 1.0f64), t, f, pf, tol, nb,
        Bool.or(near, hit), Bool.pick(Nat, zero, Nat.add(zs, 1n), zs), Bool.pick(F64, Bool.and(hit, Bool.not(near)), pt, nt))

def sample(+s: S.SF, +c: G.GVal, +lo: F64, +hi: F64) -> SM:
  +step = F64.div(F64.sub(hi, lo), L.f64_of(nsamp()))
  +f0 = fval(s, c, lo)
  +b0 = Bool.pick(List<&2, BR>, F64.is_eq(f0, 0.0f64), [BR{lo, lo}], [])
  samp_go(nsamp(), s, c, lo, step, 1.0f64, lo, f0, f0, near_tol(s), b0, False{}, 0n, lo)

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

def pl_scan_v(vs: List<&2, F64>, hit: Bool, +vf: F64, +o: V.Point, +e1: V.Dir, +e2: V.Dir, +p: V.Point,
    +u: F64, +v0: F64, +dv: F64) -> UV:
  match vs:
    case []:
      match hit:
        case True{}: UV{True{}, u, vf}
        case False{}: UV{False{}, u, v0}
    case +h <> +t:
      match hit:
        case True{}: UV{True{}, u, vf}
        case False{}:
          +v = F64.add(v0, F64.mul(h, dv))
          pl_scan_v(t, pl_hit(o, e1, e2, p, u, v), v, o, e1, e2, p, u, v0, dv)

def pl_scan_u(us: List<&2, F64>, hit: Bool, +r: UV, +o: V.Point, +e1: V.Dir, +e2: V.Dir, +p: V.Point,
    +u0: F64, +du: F64, +v0: F64, +dv: F64) -> UV:
  match us:
    case []:
      match hit:
        case True{}: r
        case False{}: UV{False{}, u0, v0}
    case +h <> +t:
      match hit:
        case True{}: r
        case False{}:
          +q = pl_scan_v(offs(), False{}, v0, o, e1, e2, p, F64.add(u0, F64.mul(h, du)), v0, dv)
          pl_scan_u(t, uv_ok(q), q, o, e1, e2, p, u0, du, v0, dv)

def bp_hit(+w: G.BezP, +p: V.Point, +u: F64, +v: F64) -> Bool:
  +r = GO.bezp_eval(w, u, v)
  +q = G.gres_p(r)
  Bool.and(G.gres_ok(r), Bool.and(F64.is_eq(V.pt_x(q), V.pt_x(p)),
    Bool.and(F64.is_eq(V.pt_y(q), V.pt_y(p)), F64.is_eq(V.pt_z(q), V.pt_z(p)))))

def bp_scan_v(vs: List<&2, F64>, hit: Bool, +vf: F64, +w: G.BezP, +p: V.Point, +u: F64, +v0: F64,
    +dv: F64) -> UV:
  match vs:
    case []:
      match hit:
        case True{}: UV{True{}, u, vf}
        case False{}: UV{False{}, u, v0}
    case +h <> +t:
      match hit:
        case True{}: UV{True{}, u, vf}
        case False{}:
          +v = F64.max(0.0f64, F64.min(1.0f64, F64.add(v0, F64.mul(h, dv))))
          bp_scan_v(t, bp_hit(w, p, u, v), v, w, p, u, v0, dv)

def bp_scan_u(us: List<&2, F64>, hit: Bool, +r: UV, +w: G.BezP, +p: V.Point, +u0: F64, +du: F64, +v0: F64,
    +dv: F64) -> UV:
  match us:
    case []:
      match hit:
        case True{}: r
        case False{}: UV{False{}, u0, v0}
    case +h <> +t:
      match hit:
        case True{}: r
        case False{}:
          +q = bp_scan_v(offs(), False{}, v0, w, p, F64.max(0.0f64, F64.min(1.0f64, F64.add(u0, F64.mul(h, du)))), v0, dv)
          bp_scan_u(t, uv_ok(q), q, w, p, u0, du, v0, dv)

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

def cl01(+q: V.Vec2) -> V.Vec2:
  V.V2{F64.max(0.0f64, F64.min(1.0f64, V.v2_x(q))), F64.max(0.0f64, F64.min(1.0f64, V.v2_y(q)))}

def bp_newton(n: Nat, +w: G.BezP, +p: V.Point, +q: V.Vec2) -> V.Vec2:
  match n:
    case 0n: q
    case 1n+m: bp_newton(m, w, p, cl01(bp_step(w, p, q)))

def near01(+x: F64) -> F64:
  Bool.pick(F64, F64.is_lt(x, 0.5f64), 0.0f64, 1.0f64)

def bp_d2(+w: G.BezP, +p: V.Point, +u: F64, +v: F64) -> F64:
  +d = S.psub(bp_pt(w, u, v), p)
  S.dot(d, d)

def bsnap_u(+w: G.BezP, +p: V.Point, +q: V.Vec2) -> V.Vec2:
  +u = V.v2_x(q)
  +v = V.v2_y(q)
  +s = near01(u)
  +ok = Bool.and(F64.is_lt(F64.abs(F64.sub(u, s)), 1.0e-5f64), F64.is_le(bp_d2(w, p, s, v), bp_d2(w, p, u, v)))
  V.V2{Bool.pick(F64, ok, s, u), v}

def bsnap_v(+w: G.BezP, +p: V.Point, +q: V.Vec2) -> V.Vec2:
  +u = V.v2_x(q)
  +v = V.v2_y(q)
  +s = near01(v)
  +ok = Bool.and(F64.is_lt(F64.abs(F64.sub(v, s)), 1.0e-5f64), F64.is_le(bp_d2(w, p, u, s), bp_d2(w, p, u, v)))
  V.V2{u, Bool.pick(F64, ok, s, v)}

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
  +uv = bsnap_v(w, p, bsnap_u(w, p, bp_newton(12n, w, p, cl01(V.V2{u1, v1}))))
  +u0 = snap01(V.v2_x(uv))
  +v0 = snap01(V.v2_y(uv))
  bp_scan_u(offs(), False{}, UV{False{}, u0, v0}, w, p, u0, ulp_of(F64.max(u0, 0.5f64)), v0, ulp_of(F64.max(v0, 0.5f64)))

def pl_uv(+g: G.GVal, +p: V.Point) -> UV:
  match g:
    case G.GV_pl{w}:
      G.Pl{+o, +e1, +e2} = w
      +d = S.psub(p, o)
      +u0 = S.dot(d, e1)
      +v0 = S.dot(d, e2)
      pl_scan_u(offs(), False{}, UV{False{}, u0, v0}, o, e1, e2, p, u0, ulp_of(u0), v0, ulp_of(v0))
    case G.GV_bp{w}: bp_uv_of(w, p)
    case _: UV{False{}, 0.0f64, 0.0f64}

def bp_on(+w: G.BezP, +p: V.Point) -> Bool:
  +q = S.bp_uv_fine(w, p)
  F64.is_le(BI.bp_gap(w, p, V.v2_x(q), V.v2_y(q)), BI.bp_tol(w))

def bp_flat(+w: G.BezP) -> Bool:
  U64.is_eq(S.sf_kind(S.sf_of(G.GV_bp{w})), S.k_plane())

def or_qr(a: Bool, +g: G.GVal, +p: V.Point) -> Bool:
  match a:
    case True{}: True{}
    case False{}: GO.q_on_r(g, p)

def on_bp(flat: Bool, +w: G.BezP, +p: V.Point) -> Bool:
  match flat:
    case True{}: or_qr(uv_ok(bp_uv_of(w, p)), G.GV_bp{w}, p)
    case False{}: bp_on(w, p)

def pl_ax(g: G.GVal, +p: V.Point) -> Bool:
  match g:
    case G.GV_pl{w}: B4.ax_on(w, p)
    case _: False{}

def pl_ex(obl: Bool, +g: G.GVal, +p: V.Point) -> Bool:
  match obl:
    case True{}: GO.q_on_r(g, p)
    case False{}: pl_ax(g, p)

def pl_on(a: Bool, +g: G.GVal, +p: V.Point) -> Bool:
  match a:
    case True{}: True{}
    case False{}: pl_ex(B4.surf_obl(g), g, p)

def on_g(+g: G.GVal, +p: V.Point) -> Bool:
  match g:
    case G.GV_pl{w}: pl_on(uv_ok(pl_uv(G.GV_pl{w}, p)), G.GV_pl{w}, p)
    case G.GV_bp{w}: on_bp(bp_flat(w), w, p)
    case _: GO.q_on_s(g, p)

def on_all_s(gs: List<&2, G.GVal>, ok: Bool, +p: V.Point) -> Bool:
  match gs:
    case []: ok
    case +h <> +t:
      match ok:
        case True{}: on_all_s(t, on_g(h, p), p)
        case False{}: False{}

def on_all(gs: List<&2, G.GVal>, +p: V.Point) -> Bool:
  on_all_s(gs, True{}, p)

def or_qh(a: Bool, +g: G.GVal, +p: V.Point) -> Bool:
  match a:
    case True{}: True{}
    case False{}:
      +m = F64.max(F64.abs(S.px(p)), F64.max(F64.abs(S.py(p)), F64.abs(S.pz(p))))
      GO.q_on_h(g, p, F64.mul(16.0f64, ulp_of(m)))

def on_c(+g: G.GVal, +p: V.Point) -> Bool:
  match g:
    case G.GV_to{w}: or_qh(on_g(G.GV_to{w}, p), G.GV_to{w}, p)
    case _: on_g(g, p)

def on_all_cs(gs: List<&2, G.GVal>, ok: Bool, +p: V.Point) -> Bool:
  match gs:
    case []: ok
    case +h <> +t:
      match ok:
        case True{}: on_all_cs(t, on_c(h, p), p)
        case False{}: False{}

def on_all_c(gs: List<&2, G.GVal>, +p: V.Point) -> Bool:
  on_all_cs(gs, True{}, p)

def ct_ok(+c: CT) -> Bool:
  CT{ok, t, p} = c
  ok

def ct_t(+c: CT) -> F64:
  CT{ok, t, p} = c
  t

def ct_p(+c: CT) -> V.Point:
  CT{ok, t, p} = c
  p

def cert_cm(okp: Bool, +c: G.GVal, +gs: List<&2, G.GVal>, +tm: F64, +lo: F64, +hi: F64) -> U64:
  match okp:
    case True{}: 1u64
    case False{}: Bool.pick(U64, Bool.and(Bool.and(F64.is_le(lo, tm), F64.is_le(tm, hi)), on_all(gs, ev(c, tm))), 2u64, 3u64)

def cert_code(+c: G.GVal, +gs: List<&2, G.GVal>, +t0: F64, +u: F64, +k: F64, +lo: F64,
    +hi: F64) -> U64:
  +tp = F64.add(t0, F64.mul(k, u))
  cert_cm(Bool.and(Bool.and(F64.is_le(lo, tp), F64.is_le(tp, hi)), on_all(gs, ev(c, tp))), c, gs, F64.sub(t0, F64.mul(k, u)), lo, hi)

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

def nz_go(zs: List<&2, F64>, hit: Bool, +qf: V.Point, +gs: List<&2, G.GVal>, +x: F64, +y: F64, +z: F64,
    +uz: F64) -> CT:
  match zs:
    case []:
      match hit:
        case True{}: CT{True{}, 0.0f64, qf}
        case False{}: CT{False{}, 0.0f64, S.pt(x, y, z)}
    case +h <> +t:
      match hit:
        case True{}: CT{True{}, 0.0f64, qf}
        case False{}:
          +q = S.pt(x, y, F64.add(z, F64.mul(h, uz)))
          nz_go(t, on_all_c(gs, q), q, gs, x, y, z, uz)

def ny_go(ys: List<&2, F64>, hit: Bool, +r: CT, +gs: List<&2, G.GVal>, +x: F64, +y: F64, +z: F64, +uy: F64,
    +uz: F64) -> CT:
  match ys:
    case []:
      match hit:
        case True{}: r
        case False{}: CT{False{}, 0.0f64, S.pt(x, y, z)}
    case +h <> +t:
      match hit:
        case True{}: r
        case False{}:
          +q = nz_go(nudges(), False{}, S.pt(x, y, z), gs, x, F64.add(y, F64.mul(h, uy)), z, uz)
          ny_go(t, ct_ok(q), q, gs, x, y, z, uy, uz)

def nx_go(xs: List<&2, F64>, hit: Bool, +r: CT, +gs: List<&2, G.GVal>, +x: F64, +y: F64, +z: F64, +ux: F64,
    +uy: F64, +uz: F64) -> CT:
  match xs:
    case []:
      match hit:
        case True{}: r
        case False{}: CT{False{}, 0.0f64, S.pt(x, y, z)}
    case +h <> +t:
      match hit:
        case True{}: r
        case False{}:
          +q = ny_go(nudges(), False{}, CT{False{}, 0.0f64, S.pt(x, y, z)}, gs, F64.add(x, F64.mul(h, ux)), y, z, uy, uz)
          nx_go(t, ct_ok(q), q, gs, x, y, z, ux, uy, uz)

def cert_gs(+gs: List<&2, G.GVal>, +p: V.Point) -> CT:
  +x = S.px(p)
  +y = S.py(p)
  +z = S.pz(p)
  nx_go(nudges(), False{}, CT{False{}, 0.0f64, S.pt(x, y, z)}, gs, x, y, z, ulp_of(x), ulp_of(y), ulp_of(z))

def g_at(gs: List<&2, G.GVal>, +i: Nat) -> G.GVal:
  match gs:
    case []: G.GV_f{0.0f64}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: g_at(t, j)

def qnear(+q: V.Point, +p: V.Point, +tol: F64, +best: V.Point) -> V.Point:
  Bool.pick(V.Point, F64.is_le(S.dist(q, p), tol), q, best)

def quarter(c: G.GVal, +p: V.Point) -> V.Point:
  match c:
    case G.GV_cc{w}:
      G.Cc{+o, +u, +v, +r} = w
      +tol = F64.mul(1.0e-12f64, F64.add(1.0f64, r))
      qnear(S.padd(o, r, u), p, tol, qnear(S.padd(o, F64.neg(r), u), p, tol, qnear(S.padd(o, r, v), p, tol, qnear(S.padd(o, F64.neg(r), v), p, tol, p))))
    case _: p

def cert_newton(+c: G.GVal, +gs: List<&2, G.GVal>, +t: F64, +p0: V.Point) -> CT:
  +s1 = S.sf_of(g_at(gs, 0n))
  +s2 = S.sf_of(g_at(gs, 1n))
  +tn = S.dunit(S.cross(S.sf_grad(s1, p0), S.sf_grad(s2, p0)))
  +r = cert_gs(gs, S.newton2(6n, s1, s2, p0, tn, p0))
  CT{ct_ok(r), t, ct_p(r)}

def cert_q(+ok: Bool, +q: V.Point, +c: G.GVal, +gs: List<&2, G.GVal>, +t: F64, +p0: V.Point) -> CT:
  match ok:
    case True{}: CT{True{}, t, q}
    case False{}: cert_newton(c, gs, t, p0)

def cert_snap(+c: G.GVal, +gs: List<&2, G.GVal>, +t: F64) -> CT:
  +p0 = ev(c, t)
  +q = quarter(c, p0)
  cert_q(on_all(gs, q), q, c, gs, t, p0)

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
  EHS{hs, near, nt} = e
  hs

def ehs_near(+e: EHS) -> Bool:
  EHS{hs, near, nt} = e
  near

def ehs_nt(+e: EHS) -> F64:
  EHS{hs, near, nt} = e
  nt

def edge_hits_go(+isc: Bool, +s: S.SF, +c: G.GVal, +gs: List<&2, G.GVal>, +lo: F64, +hi: F64)
    -> EHS:
  match isc:
    case True{}:
      +sm = sample(s, c, lo, hi)
      +emb = Nat.is_le(3n, sm_zeros(sm))
      Bool.pick(EHS, emb, EHS{[], False{}, lo}, EHS{List.reverse(&2, EH, hits_go(sm_brs(sm), s, c, gs, lo, hi)), sm_near(sm), sm_nt(sm)})
    case False{}: EHS{[], False{}, lo}

def yh_go(hs: List<&2, Y.Hx>, +c: G.GVal, +gs: List<&2, G.GVal>, +lo: F64, +hi: F64) -> List<&2, EH>:
  match hs:
    case []: []
    case +h <> +t:
      match h:
        case Y.Hx_uv{+sp, u, v, b, k}:
          +ct = cert_t(c, gs, I.imid(sp), lo, hi)
          EH{ct_t(ct), ct_p(ct), ct_ok(ct)} <> yh_go(t, c, gs, lo, hi)
        case Y.Hx_un3{+sp, u, v}: EH{I.imid(sp), ev(c, I.imid(sp)), False{}} <> yh_go(t, c, gs, lo, hi)
        case Y.Hx_c{w}: EH{lo, ev(c, lo), False{}} <> yh_go(t, c, gs, lo, hi)

def eh_lt(+a: EH, +b: EH) -> Bool:
  F64.is_lt(eh_t(a), eh_t(b))

def eh_ins(+x: EH, xs: List<&2, EH>) -> List<&2, EH>:
  match xs:
    case []: [x]
    case +h <> +t: Bool.pick(List<&2, EH>, eh_lt(x, h), x <> h <> t, h <> eh_ins(x, t))

def eh_sort(xs: List<&2, EH>) -> List<&2, EH>:
  match xs:
    case []: []
    case +h <> +t: eh_ins(h, eh_sort(t))

def b6_pts(ps: List<&2, V.Point>, +acc: B6) -> B6:
  match ps:
    case []: acc
    case +p <> t:
      B6{+x0, +x1, +y0, +y1, +z0, +z1} = acc
      b6_pts(t, B6{F64.min(x0, V.pt_x(p)), F64.max(x1, V.pt_x(p)), F64.min(y0, V.pt_y(p)), F64.max(y1, V.pt_y(p)),
        F64.min(z0, V.pt_z(p)), F64.max(z1, V.pt_z(p))})

def b6_pad(+bx: B6, +pad: F64) -> B6:
  B6{+x0, +x1, +y0, +y1, +z0, +z1} = bx
  +e = F64.add(pad, F64.mul(1.0e-9f64, F64.add(1.0f64, F64.max(F64.max(F64.abs(x0), F64.abs(x1)), F64.max(F64.max(F64.abs(y0), F64.abs(y1)), F64.max(F64.abs(z0), F64.abs(z1)))))))
  B6{F64.sub(x0, e), F64.add(x1, e), F64.sub(y0, e), F64.add(y1, e), F64.sub(z0, e), F64.add(z1, e)}

def b6_of(+ps: List<&2, V.Point>, +pad: F64) -> B6:
  +inf = F64.div(1.0f64, 0.0f64)
  b6_pad(b6_pts(ps, B6{inf, F64.neg(inf), inf, F64.neg(inf), inf, F64.neg(inf)}), pad)

def b6_dis(+a: B6, +b: B6) -> Bool:
  B6{+ax0, +ax1, +ay0, +ay1, +az0, +az1} = a
  B6{+bx0, +bx1, +by0, +by1, +bz0, +bz1} = b
  Bool.or(Bool.or(Bool.or(F64.is_lt(ax1, bx0), F64.is_lt(bx1, ax0)), Bool.or(F64.is_lt(ay1, by0), F64.is_lt(by1, ay0))),
    Bool.or(F64.is_lt(az1, bz0), F64.is_lt(bz1, az0)))

def b6_diag(+a: B6) -> F64:
  B6{+x0, +x1, +y0, +y1, +z0, +z1} = a
  +dx = F64.sub(x1, x0)
  +dy = F64.sub(y1, y0)
  +dz = F64.sub(z1, z0)
  F64.sqrt(F64.add(F64.mul(dx, dx), F64.add(F64.mul(dy, dy), F64.mul(dz, dz))))

def cv_rad(+c: G.GVal) -> F64:
  match c:
    case G.GV_cc{w}:
      G.Cc{o, u, v, +r} = w
      r
    case G.GV_rq{w}:
      G.Rq{+p0, +p1, +p2, w0, +w1, w2} = w
      +m = S.padd(p0, 0.5f64, S.psub(p2, p0))
      +kk = F64.div(F64.mul(w1, w1), F64.sub(1.0f64, F64.mul(w1, w1)))
      +c0 = S.padd(m, kk, S.psub(m, p1))
      S.dist(p0, c0)
    case _: 0.0f64

def cv_kind(+c: G.GVal) -> U64:
  match c:
    case G.GV_ln{w}: 1u64
    case G.GV_bz{w}: 2u64
    case G.GV_cc{w}: 3u64
    case G.GV_rq{w}: 3u64
    case _: 0u64

def bz_dv(+p0: V.Point, +p1: V.Point, +p2: V.Point, +p3: V.Point, +t: F64) -> V.Dir:
  +s = F64.sub(1.0f64, t)
  S.dscale(3.0f64, S.dadd(S.dadd(S.dscale(F64.mul(s, s), S.psub(p1, p0)), F64.mul(2.0f64, F64.mul(s, t)), S.psub(p2, p1)), F64.mul(t, t), S.psub(p3, p2)))

def bz_cp(+c: G.GVal, +a: F64, +b: F64) -> List<&2, V.Point>:
  match c:
    case G.GV_bz{w}:
      G.Bz{+p0, +p1, +p2, +p3} = w
      +h = F64.div(F64.sub(b, a), 3.0f64)
      +pa = ev(c, a)
      +pb = ev(c, b)
      [pa, S.padd(pa, h, bz_dv(p0, p1, p2, p3, a)), S.padd(pb, F64.neg(h), bz_dv(p0, p1, p2, p3, b)), pb]
    case _: [ev(c, a), ev(c, b)]

def bp0(ps: List<&2, G.BezP>, +d: G.BezP) -> G.BezP:
  match ps:
    case []: d
    case +h <> t: h

def cbox(k: U64, +c: G.GVal, +a: F64, +b: F64) -> B6:
  match k:
    case 1u64: b6_of([ev(c, a), ev(c, b)], 0.0f64)
    case 2u64: b6_of(bz_cp(c, a, b), 0.0f64)
    case _:
      +pa = ev(c, a)
      +pb = ev(c, b)
      +pm = ev(c, F64.mul(0.5f64, F64.add(a, b)))
      +ch = F64.add(S.dist(pa, pm), S.dist(pm, pb))
      +r = cv_rad(c)
      +sag = Bool.pick(F64, F64.is_lt(0.0f64, r), F64.div(F64.mul(ch, ch), F64.mul(4.0f64, r)), ch)
      b6_of([pa, pb, pm], sag)

def cq_a(+q: CQ) -> F64:
  CQ{+a, b, ps} = q
  a

def cq_b(+q: CQ) -> F64:
  CQ{a, +b, ps} = q
  b

def cq_ps(+q: CQ) -> List<&2, G.BezP>:
  CQ{a, b, +ps} = q
  ps

def cq_quads(+a: F64, +b: F64, ps: List<&2, G.BezP>) -> List<&2, CQ>:
  match ps:
    case []: []
    case +p <> t: CQ{a, b, [p]} <> cq_quads(a, b, t)

def w0() -> G.BezP:
  +z = S.pt(0.0f64, 0.0f64, 0.0f64)
  G.Bp{z, z, z, z, z, z, z, z, z, z, z, z, z, z, z, z}

def cs_far_go(n: Nat, +k: U64, +c: G.GVal, +qs: List<&2, CQ>) -> Bool:
  match n:
    case 0n: False{}
    case 1n+(+m):
      match qs:
        case []: True{}
        case +q <> +t:
          +a = cq_a(q)
          +b = cq_b(q)
          +p = bp0(cq_ps(q), w0())
          +cb = cbox(k, c, a, b)
          +pb = b6_of(SC.pts16(p), 0.0f64)
          +dis = b6_dis(cb, pb)
          +cut_c = F64.is_le(b6_diag(pb), b6_diag(cb))
          +mid = F64.mul(0.5f64, F64.add(a, b))
          +kids = Bool.pick(List<&2, CQ>, cut_c, [CQ{a, mid, [p]}, CQ{mid, b, [p]}], cq_quads(a, b, SC.quads(p)))
          cs_far_go(m, k, c, Bool.pick(List<&2, CQ>, dis, t, List.append(&2, CQ, kids, t)))

def cs_far(+c: G.GVal, +lo: F64, +hi: F64, +w: G.BezP) -> Bool:
  +k = cv_kind(c)
  Bool.and(Bool.not(U64.is_eq(k, 0u64)), cs_far_go(1500n, k, c, [CQ{lo, hi, [w]}]))

def pp_l(qs: List<&2, G.BezP>, +o: G.BezP, +left: Bool) -> List<&2, PP>:
  match qs:
    case []: []
    case +q <> t: Bool.pick(PP, left, PP{q, o}, PP{o, q}) <> pp_l(t, o, left)

def pp_box(+p: G.BezP) -> B6:
  b6_of(SC.pts16(p), 1.0e-9f64)

def bb_far_go(n: Nat, +qs: List<&2, PP>) -> Bool:
  match n:
    case 0n: False{}
    case 1n+(+m):
      match qs:
        case []: True{}
        case +q <> +t:
          PP{+a, +b} = q
          +ba = pp_box(a)
          +bb = pp_box(b)
          +la = F64.is_le(b6_diag(bb), b6_diag(ba))
          +kids = Bool.pick(List<&2, PP>, la, pp_l(SC.quads(a), b, True{}), pp_l(SC.quads(b), a, False{}))
          bb_far_go(m, Bool.pick(List<&2, PP>, b6_dis(ba, bb), t, List.append(&2, PP, kids, t)))

def bb_far(+a: G.BezP, +b: G.BezP) -> Bool:
  bb_far_go(4000n, [PP{a, b}])

def gb_far(+w: G.BezP, +g: G.GVal) -> Bool:
  match g:
    case G.GV_bp{v}: bb_far(w, v)
    case _: False{}

def gg_far(+g1: G.GVal, +g2: G.GVal) -> Bool:
  match g1:
    case G.GV_bp{w}: gb_far(w, g2)
    case _: False{}

def bp_hits_go(isc: Bool, +w: G.BezP, +c: G.GVal, +gs: List<&2, G.GVal>, +lo: F64, +hi: F64) -> EHS:
  match isc:
    case True{}: EHS{eh_sort(yh_go(Y.inter_cs_w(c, G.Dom{lo, hi}, G.GV_bp{w}, 40n), c, gs, lo, hi)), False{}, lo}
    case False{}: EHS{[], False{}, lo}

def bp_hits(+isc: Bool, +w: G.BezP, +c: G.GVal, +gs: List<&2, G.GVal>, +lo: F64, +hi: F64) -> EHS:
  bp_hits_go(Bool.and(isc, Bool.not(cs_far(c, lo, hi, w))), w, c, gs, lo, hi)

def edge_hits(+k: Ty.EdgeKind, +s: S.SF, +gs: List<&2, G.GVal>) -> EHS:
  match s:
    case S.SF_bp{gw}: bp_hits(ek_is_curve(k), S.gbp(gw), ek_curve(k), gs, ek_lo(k), ek_hi(k))
    case _: edge_hits_go(ek_is_curve(k), s, ek_curve(k), gs, ek_lo(k), ek_hi(k))
