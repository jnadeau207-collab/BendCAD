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
