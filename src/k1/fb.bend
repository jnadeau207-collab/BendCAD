import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ./sf.bend as S
import ./ef.bend as EF
import ./ls.bend as L

type CE is Data:
  CE{ e: Nat, fwd: Bool }

def ce_e(+c: CE) -> Nat:
  CE{e, fwd} = c
  e

def ce_fw(+c: CE) -> Bool:
  CE{e, fwd} = c
  fwd

def hl_i(+h: Ty.HLoop) -> Nat:
  Ty.HL{+i, +g} = h
  i

def hcs_ce(hs: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>) -> List<&2, CE>:
  match hs:
    case []: []
    case +h <> +t:
      +c = L.nth_c(ces, Ty.hc_idx(h))
      CE{Ty.he_idx(Ty.ce_edge(c)), Ty.ce_fwd(c)} <> hcs_ce(t, ces)

def hls_ce(hs: List<&2, Ty.HLoop>, +b: Ty.Brep) -> List<&2, List<&2, CE>>:
  match hs:
    case []: []
    case +h <> +t:
      hcs_ce(Ty.lp_ces(L.nth_l(Ty.brep_lps(b), hl_i(h))), Ty.brep_ces(b)) <> hls_ce(t, b)

def face_ce(+b: Ty.Brep, +fi: Nat) -> List<&2, List<&2, CE>>:
  hls_ce(Ty.fa_loops(L.nth_f(Ty.brep_fas(b), fi)), b)

def ces_has(cs: List<&2, CE>, +e: Nat) -> Bool:
  match cs:
    case []: False{}
    case +h <> +t: Bool.or(Nat.is_eq(ce_e(h), e), ces_has(t, e))

def lps_has(ls: List<&2, List<&2, CE>>, +e: Nat) -> Bool:
  match ls:
    case []: False{}
    case +h <> +t: Bool.or(ces_has(h, e), lps_has(t, e))

def efaces_go(fs: List<&2, Ty.Face>, +b: Ty.Brep, +e: Nat, +i: Nat) -> List<&2, Nat>:
  match fs:
    case []: []
    case +h <> +t:
      +rest = efaces_go(t, b, e, Nat.add(i, 1n))
      Bool.pick(List<&2, Nat>, lps_has(hls_ce(Ty.fa_loops(h), b), e), i <> rest, rest)

def edge_faces(+b: Ty.Brep, +e: Nat) -> List<&2, Nat>:
  efaces_go(Ty.brep_fas(b), b, e, 0n)

def face_surf(+b: Ty.Brep, +fi: Nat) -> G.GVal:
  Ty.fa_surf(L.nth_f(Ty.brep_fas(b), fi))

def face_same(+b: Ty.Brep, +fi: Nat) -> Bool:
  Ty.fa_same(L.nth_f(Ty.brep_fas(b), fi))

def nfaces(+b: Ty.Brep) -> Nat:
  List.length(&2, Ty.Face, Ty.brep_fas(b))

def nedges(+b: Ty.Brep) -> Nat:
  List.length(&2, Ty.Edge, Ty.brep_es(b))

def edge_at(+b: Ty.Brep, +e: Nat) -> Ty.Edge:
  L.nth_e(Ty.brep_es(b), e)

def vpt(+b: Ty.Brep, +v: Ty.HVertex) -> V.Point:
  Ty.vx_p(L.nth_v(Ty.brep_vs(b), Ty.hv_idx(v)))

def is_line(+k: Ty.EdgeKind) -> Bool:
  match k:
    case Ty.EK_curve{+c, +d}:
      match c:
        case G.GV_ln{w}: True{}
        case _: False{}
    case Ty.EK_degenerate{}: False{}

def nseg(+k: Ty.EdgeKind) -> Nat:
  Bool.pick(Nat, is_line(k), 1n, 32n)

def uv_raw(+s: S.SF, +p: V.Point) -> V.Vec2:
  S.sf_uv(s, p)

def unwrap(+s: S.SF, +prev: V.Vec2, +q: V.Vec2) -> V.Vec2:
  Bool.pick(V.Vec2, S.sf_periodic(s),
    V.V2{F64.add(V.v2_x(prev), S.ang_diff(V.v2_x(prev), V.v2_x(q))), V.v2_y(q)}, q)

def samp_go(n: Nat, +s: S.SF, +c: G.GVal, +t0: F64, +dt: F64, +k: F64, +prev: V.Vec2,
    +acc: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  match n:
    case 0n: acc
    case 1n+m:
      +q = unwrap(s, prev, uv_raw(s, EF.ev(c, F64.add(t0, F64.mul(k, dt)))))
      samp_go(m, s, c, t0, dt, F64.add(k, 1.0f64), q, q <> acc)

def poly_of(+s: S.SF, +k: Ty.EdgeKind, +t0: F64, +t1: F64, +start: V.Vec2) -> List<&2, V.Vec2>:
  +n = nseg(k)
  +c = EF.ek_curve(k)
  +dt = F64.div(F64.sub(t1, t0), L.f64_of(n))
  List.reverse(&2, V.Vec2, samp_go(n, s, c, t0, dt, 1.0f64, start, [start]))

def ce_poly(+s: S.SF, +b: Ty.Brep, +c: CE, +start: V.Vec2) -> List<&2, V.Vec2>:
  +ed = edge_at(b, ce_e(c))
  +k = Ty.ed_kind(ed)
  +fw = ce_fw(c)
  poly_of(s, k, Bool.pick(F64, fw, EF.ek_lo(k), EF.ek_hi(k)), Bool.pick(F64, fw, EF.ek_hi(k), EF.ek_lo(k)), start)

def ce_start3(+b: Ty.Brep, +c: CE) -> V.Point:
  +ed = edge_at(b, ce_e(c))
  vpt(b, Bool.pick(Ty.HVertex, ce_fw(c), Ty.ed_v0(ed), Ty.ed_v1(ed)))

def drop1(xs: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  match xs:
    case []: []
    case +h <> +t: t

def loop_poly_go(cs: List<&2, CE>, +s: S.SF, +b: Ty.Brep, +start: V.Vec2,
    +acc: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  match cs:
    case []: acc
    case +h <> +t:
      +p = ce_poly(s, b, h, start)
      loop_poly_go(t, s, b, L.last_v2(p, start), List.append(&2, V.Vec2, acc, drop1(p)))

def loop_poly(+s: S.SF, +b: Ty.Brep, +cs: List<&2, CE>) -> List<&2, V.Vec2>:
  match cs:
    case []: []
    case +h <> +t:
      +st = uv_raw(s, ce_start3(b, h))
      loop_poly_go(h <> t, s, b, st, [st])

def face_polys_go(ls: List<&2, List<&2, CE>>, +s: S.SF, +b: Ty.Brep) -> List<&2, List<&2, V.Vec2>>:
  match ls:
    case []: []
    case +h <> +t: loop_poly(s, b, h) <> face_polys_go(t, s, b)

def face_polys(+b: Ty.Brep, +fi: Nat) -> List<&2, List<&2, V.Vec2>>:
  face_polys_go(face_ce(b, fi), S.sf_of(face_surf(b, fi)), b)

def seg_cross(+s: S.SF, +a: V.Vec2, +bb: V.Vec2, +q: V.Vec2) -> Bool:
  +ax = V.v2_x(a)
  +bx = V.v2_x(bb)
  +qx = Bool.pick(F64, S.sf_periodic(s), F64.add(ax, S.ang_diff(ax, V.v2_x(q))), V.v2_x(q))
  +str = Bool.or(Bool.and(F64.is_le(ax, qx), F64.is_lt(qx, bx)), Bool.and(F64.is_le(bx, qx), F64.is_lt(qx, ax)))
  +t = F64.div(F64.sub(qx, ax), F64.sub(bx, ax))
  +y = F64.add(V.v2_y(a), F64.mul(t, F64.sub(V.v2_y(bb), V.v2_y(a))))
  Bool.and(str, F64.is_lt(V.v2_y(q), y))

def poly_cross(ps: List<&2, V.Vec2>, +s: S.SF, +q: V.Vec2, +prev: V.Vec2, +n: Nat) -> Nat:
  match ps:
    case []: n
    case +h <> +t:
      poly_cross(t, s, q, h, Bool.pick(Nat, seg_cross(s, prev, h, q), Nat.add(n, 1n), n))

def polys_cross(ls: List<&2, List<&2, V.Vec2>>, +s: S.SF, +q: V.Vec2) -> Nat:
  match ls:
    case []: 0n
    case +h <> +t:
      match h:
        case []: polys_cross(t, s, q)
        case +a <> +r: Nat.add(poly_cross(r, s, q, a, 0n), polys_cross(t, s, q))

def pip(+s: S.SF, +ls: List<&2, List<&2, V.Vec2>>, +q: V.Vec2) -> Bool:
  Nat.is_eq(Nat.mod(polys_cross(ls, s, q), 2n), 1n)

def pt_in_face(+b: Ty.Brep, +fi: Nat, +p: V.Point) -> Bool:
  +s = S.sf_of(face_surf(b, fi))
  pip(s, face_polys(b, fi), uv_raw(s, p))

def circ_dist(+c0: V.Point, +n: V.Dir, +r: F64, +p: V.Point) -> F64:
  +q = S.psub(p, c0)
  +oop = S.dot(q, n)
  +rad = S.dlen(S.dadd(q, F64.neg(oop), n))
  +dr = F64.sub(rad, r)
  F64.sqrt(F64.add(F64.mul(dr, dr), F64.mul(oop, oop)))

def seg3_dist(+a: V.Point, +b: V.Point, +p: V.Point) -> F64:
  +d = S.psub(b, a)
  +l2 = S.dot(d, d)
  +t0 = Bool.pick(F64, F64.is_lt(0.0f64, l2), F64.div(S.dot(S.psub(p, a), d), l2), 0.0f64)
  +t = F64.min(1.0f64, F64.max(0.0f64, t0))
  S.dist(p, S.padd(a, t, d))

def curve_dist(+c: G.GVal, +lo: F64, +hi: F64, +p: V.Point) -> F64:
  match c:
    case G.GV_ln{w}:
      G.Ln{+p0, +d} = w
      seg3_dist(S.padd(p0, lo, d), S.padd(p0, hi, d), p)
    case G.GV_cc{w}:
      G.Cc{+c0, +u, +v, +r} = w
      circ_dist(c0, S.dunit(S.cross(u, v)), r, p)
    case G.GV_rq{w}:
      G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = w
      +m = S.padd(p0, 0.5f64, S.psub(p2, p0))
      +kk = F64.div(F64.mul(w1, w1), F64.sub(1.0f64, F64.mul(w1, w1)))
      +c0 = S.padd(m, kk, S.psub(m, p1))
      circ_dist(c0, S.dunit(S.cross(S.psub(p0, c0), S.psub(p1, c0))), S.dist(p0, c0), p)
    case G.GV_bz{w}:
      G.Bz{+p0, +p1, +p2, +p3} = w
      seg3_dist(p0, p3, p)
    case _: F64.div(1.0f64, 0.0f64)

def ces_dist(cs: List<&2, CE>, +b: Ty.Brep, +p: V.Point, +best: F64) -> F64:
  match cs:
    case []: best
    case +h <> +t:
      +k = Ty.ed_kind(edge_at(b, ce_e(h)))
      ces_dist(t, b, p, F64.min(best, curve_dist(EF.ek_curve(k), EF.ek_lo(k), EF.ek_hi(k), p)))

def lps_dist(ls: List<&2, List<&2, CE>>, +b: Ty.Brep, +p: V.Point, +best: F64) -> F64:
  match ls:
    case []: best
    case +h <> +t: lps_dist(t, b, p, ces_dist(h, b, p, best))

def bnd_near(+b: Ty.Brep, +fi: Nat, +p: V.Point) -> Bool:
  F64.is_lt(lps_dist(face_ce(b, fi), b, p, F64.div(1.0f64, 0.0f64)), 1.0e-7f64)

type BB is Data:
  BB{ x0: F64, x1: F64, y0: F64, y1: F64, z0: F64, z1: F64 }

def bb_pt(+p: V.Point) -> BB:
  BB{V.pt_x(p), V.pt_x(p), V.pt_y(p), V.pt_y(p), V.pt_z(p), V.pt_z(p)}

def bb_join(+a: BB, +b: BB) -> BB:
  BB{+ax0, +ax1, +ay0, +ay1, +az0, +az1} = a
  BB{+bx0, +bx1, +by0, +by1, +bz0, +bz1} = b
  BB{F64.min(ax0, bx0), F64.max(ax1, bx1), F64.min(ay0, by0), F64.max(ay1, by1), F64.min(az0, bz0), F64.max(az1, bz1)}

def bb_pad(+a: BB, +e: F64) -> BB:
  BB{+x0, +x1, +y0, +y1, +z0, +z1} = a
  BB{F64.sub(x0, e), F64.add(x1, e), F64.sub(y0, e), F64.add(y1, e), F64.sub(z0, e), F64.add(z1, e)}

def bb_span(+a: BB) -> F64:
  BB{+x0, +x1, +y0, +y1, +z0, +z1} = a
  F64.max(F64.sub(x1, x0), F64.max(F64.sub(y1, y0), F64.sub(z1, z0)))

def bb_dis(+a: BB, +b: BB) -> Bool:
  BB{+ax0, +ax1, +ay0, +ay1, +az0, +az1} = a
  BB{+bx0, +bx1, +by0, +by1, +bz0, +bz1} = b
  Bool.or(F64.is_lt(ax1, bx0), Bool.or(F64.is_lt(bx1, ax0), Bool.or(F64.is_lt(ay1, by0),
    Bool.or(F64.is_lt(by1, ay0), Bool.or(F64.is_lt(az1, bz0), F64.is_lt(bz1, az0))))))

def bb_empty() -> BB:
  BB{1.0e300f64, F64.neg(1.0e300f64), 1.0e300f64, F64.neg(1.0e300f64), 1.0e300f64, F64.neg(1.0e300f64)}

def bb_huge() -> BB:
  BB{F64.neg(1.0e300f64), 1.0e300f64, F64.neg(1.0e300f64), 1.0e300f64, F64.neg(1.0e300f64), 1.0e300f64}

def half_of(+u: F64, +v: F64, +r: F64) -> F64:
  F64.mul(r, F64.sqrt(F64.add(F64.mul(u, u), F64.mul(v, v))))

def cc_bb(+c: G.Circle3) -> BB:
  G.Cc{+o, +e1, +e2, +r} = c
  +hx = half_of(V.dr_x(e1), V.dr_x(e2), r)
  +hy = half_of(V.dr_y(e1), V.dr_y(e2), r)
  +hz = half_of(V.dr_z(e1), V.dr_z(e2), r)
  BB{F64.sub(V.pt_x(o), hx), F64.add(V.pt_x(o), hx), F64.sub(V.pt_y(o), hy), F64.add(V.pt_y(o), hy),
    F64.sub(V.pt_z(o), hz), F64.add(V.pt_z(o), hz)}

def curve_bb(+g: G.GVal, +lo: F64, +hi: F64) -> BB:
  match g:
    case G.GV_ln{w}: bb_join(bb_pt(EF.ev(g, lo)), bb_pt(EF.ev(g, hi)))
    case G.GV_cc{w}: cc_bb(w)
    case G.GV_rq{w}:
      G.Rq{+p0, +p1, +p2, w0, w1, w2} = w
      bb_join(bb_pt(p0), bb_join(bb_pt(p1), bb_pt(p2)))
    case G.GV_bz{w}:
      G.Bz{+p0, +p1, +p2, +p3} = w
      bb_join(bb_join(bb_pt(p0), bb_pt(p1)), bb_join(bb_pt(p2), bb_pt(p3)))
    case _: bb_huge()

def ek_bb(+k: Ty.EdgeKind) -> BB:
  match k:
    case Ty.EK_curve{+c, +d}: curve_bb(c, EF.ek_lo(k), EF.ek_hi(k))
    case Ty.EK_degenerate{}: bb_huge()

def ces_bb(cs: List<&2, CE>, +b: Ty.Brep, +acc: BB) -> BB:
  match cs:
    case []: acc
    case +h <> +t: ces_bb(t, b, bb_join(acc, ek_bb(Ty.ed_kind(edge_at(b, ce_e(h))))))

def lps_bb(ls: List<&2, List<&2, CE>>, +b: Ty.Brep, +acc: BB) -> BB:
  match ls:
    case []: acc
    case +h <> +t: lps_bb(t, b, ces_bb(h, b, acc))

def ce_turn(+s: S.SF, +b: Ty.Brep, +h: CE) -> F64:
  +k = Ty.ed_kind(edge_at(b, ce_e(h)))
  +lo = EF.ek_lo(k)
  +hi = EF.ek_hi(k)
  +a = Bool.pick(F64, ce_fw(h), lo, hi)
  +z = Bool.pick(F64, ce_fw(h), hi, lo)
  +ps = poly_of(s, k, a, z, uv_raw(s, EF.ev(EF.ek_curve(k), a)))
  F64.sub(V.v2_x(L.nth_v2(ps, Nat.sub(List.length(&2, V.Vec2, ps), 1n))), V.v2_x(L.nth_v2(ps, 0n)))

def lp_turn(cs: List<&2, CE>, +s: S.SF, +b: Ty.Brep, +acc: F64) -> F64:
  match cs:
    case []: acc
    case +h <> +t: lp_turn(t, s, b, F64.add(acc, ce_turn(s, b, h)))

def wraps_go(ls: List<&2, List<&2, CE>>, +s: S.SF, +b: Ty.Brep, +n: Nat) -> Nat:
  match ls:
    case []: n
    case +h <> +t:
      +w = F64.is_lt(3.0f64, F64.abs(lp_turn(h, s, b, 0.0f64)))
      wraps_go(t, s, b, Bool.pick(Nat, w, Nat.add(n, 1n), n))

def face_bb(+b: Ty.Brep, +fi: Nat) -> BB:
  +s = S.sf_of(face_surf(b, fi))
  +ls = face_ce(b, fi)
  +e0 = lps_bb(ls, b, bb_empty())
  +tip = Bool.and(U64.is_eq(S.sf_kind(s), S.k_cone()), Nat.is_eq(Nat.mod(wraps_go(ls, s, b, 0n), 2n), 1n))
  +e1 = Bool.pick(BB, tip, bb_join(e0, bb_pt(S.sf_o(s))), e0)
  bb_pad(e1, F64.add(F64.add(F64.mul(1.0e-7f64, F64.add(1.0f64, bb_span(e1))), Ty.fa_slv(L.nth_f(Ty.brep_fas(b), fi))), 1.0e-9f64))

