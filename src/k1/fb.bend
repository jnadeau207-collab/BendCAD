import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ./sf.bend as S
import ./ef.bend as EF
import ./ls.bend as L
import ../base/par.bend as B

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

def ce_edges(cs: List<&2, Ty.Coedge>) -> List<&2, Nat>:
  match cs:
    case []: []
    case +c <> +t: Ty.he_idx(Ty.ce_edge(c)) <> ce_edges(t)

def lp_hcs(ls: List<&2, Ty.Loop>) -> List<&2, List<&2, Ty.HCoedge>>:
  match ls:
    case []: []
    case +l <> +t: Ty.lp_ces(l) <> lp_hcs(t)

def hcs_has(hs: List<&2, Ty.HCoedge>, +ce: B.Tb<&2, Nat>, +e: Nat) -> Bool:
  match hs:
    case []: False{}
    case +h <> +t: Bool.or(Nat.is_eq(B.tb_get(Nat, ce, U32.from_nat(Ty.hc_idx(h))), e), hcs_has(t, ce, e))

def hls_has(hs: List<&2, Ty.HLoop>, +lp: B.Tb<&2, List<&2, Ty.HCoedge>>, +ce: B.Tb<&2, Nat>, +e: Nat) -> Bool:
  match hs:
    case []: False{}
    case +h <> +t: Bool.or(hcs_has(B.tb_get(List<&2, Ty.HCoedge>, lp, U32.from_nat(hl_i(h))), ce, e), hls_has(t, lp, ce, e))

def efaces_go(fs: List<&2, Ty.Face>, +lp: B.Tb<&2, List<&2, Ty.HCoedge>>, +ce: B.Tb<&2, Nat>, +e: Nat, +i: Nat) -> List<&2, Nat>:
  match fs:
    case []: []
    case +h <> +t:
      +rest = efaces_go(t, lp, ce, e, Nat.add(i, 1n))
      Bool.pick(List<&2, Nat>, hls_has(Ty.fa_loops(h), lp, ce, e), i <> rest, rest)

def edge_faces(+b: Ty.Brep, +e: Nat) -> List<&2, Nat>:
  efaces_go(Ty.brep_fas(b), B.tb_of(List<&2, Ty.HCoedge>, lp_hcs(Ty.brep_lps(b)), []), B.tb_of(Nat, ce_edges(Ty.brep_ces(b)), 0n), e, 0n)

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

def at_pole(+s: S.SF, +q: V.Vec2) -> Bool:
  Bool.and(S.is_sph(s), F64.is_le(F64.sub(S.sf_r(s), F64.abs(V.v2_y(q))), F64.mul(1.0e-12f64, S.sf_r(s))))

def unwrap(+s: S.SF, +prev: V.Vec2, +q: V.Vec2) -> V.Vec2:
  Bool.pick(V.Vec2, at_pole(s, q), V.V2{V.v2_x(prev), V.v2_y(q)},
    Bool.pick(V.Vec2, S.sf_periodic(s),
      V.V2{F64.add(V.v2_x(prev), S.ang_diff(V.v2_x(prev), V.v2_x(q))), V.v2_y(q)}, q))

def samp_go(n: Nat, +s: S.SF, +c: G.GVal, +t0: F64, +dt: F64, +k: F64, +prev: V.Vec2,
    +acc: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  match n:
    case 0n: acc
    case 1n+m:
      +q = unwrap(s, prev, uv_raw(s, EF.ev(c, F64.add(t0, F64.mul(k, dt)))))
      samp_go(m, s, c, t0, dt, F64.add(k, 1.0f64), q, q <> acc)

def pole_head(+s: S.SF, xs: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  match xs:
    case []: []
    case +h <> +t:
      match t:
        case []: [h]
        case +h2 <> +t2:
          Bool.pick(List<&2, V.Vec2>, at_pole(s, h), V.V2{V.v2_x(h2), V.v2_y(h)} <> h2 <> t2, h <> h2 <> t2)

def poly_of(+s: S.SF, +k: Ty.EdgeKind, +t0: F64, +t1: F64, +start: V.Vec2) -> List<&2, V.Vec2>:
  +n = nseg(k)
  +c = EF.ek_curve(k)
  +dt = F64.div(F64.sub(t1, t0), L.f64_of(n))
  pole_head(s, List.reverse(&2, V.Vec2, samp_go(n, s, c, t0, dt, 1.0f64, start, [start])))

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

def wedge(+a: V.Dir, +b: V.Dir, +d: V.Dir, +n: V.Dir) -> Bool:
  +ad = F64.is_le(0.0f64, S.dot(S.cross(a, d), n))
  +db = F64.is_le(0.0f64, S.dot(S.cross(d, b), n))
  Bool.pick(Bool, F64.is_le(0.0f64, S.dot(S.cross(a, b), n)), Bool.and(ad, db), Bool.or(ad, db))

def arc_dist(+c0: V.Point, +n: V.Dir, +r: F64, +pa: V.Point, +pb: V.Point, +pm: V.Point, +p: V.Point) -> F64:
  +a = S.psub(pa, c0)
  +b = S.psub(pb, c0)
  +q = S.psub(p, c0)
  +d = S.dadd(q, F64.neg(S.dot(q, n)), n)
  +inside = Bool.pick(Bool, wedge(a, b, S.psub(pm, c0), n), wedge(a, b, d, n), wedge(b, a, d, n))
  Bool.pick(F64, inside, circ_dist(c0, n, r, p), F64.min(S.dist(p, pa), S.dist(p, pb)))

def curve_dist(+c: G.GVal, +lo: F64, +hi: F64, +p: V.Point) -> F64:
  match c:
    case G.GV_ln{w}:
      G.Ln{+p0, +d} = w
      seg3_dist(S.padd(p0, lo, d), S.padd(p0, hi, d), p)
    case G.GV_cc{w}:
      G.Cc{+c0, +u, +v, +r} = w
      +full = F64.is_le(6.283185307179586f64, F64.sub(hi, lo))
      Bool.pick(F64, full, circ_dist(c0, S.dunit(S.cross(u, v)), r, p),
        arc_dist(c0, S.dunit(S.cross(u, v)), r, EF.ev(G.GV_cc{G.Cc{c0, u, v, r}}, lo), EF.ev(G.GV_cc{G.Cc{c0, u, v, r}}, hi),
          EF.ev(G.GV_cc{G.Cc{c0, u, v, r}}, F64.mul(0.5f64, F64.add(lo, hi))), p))
    case G.GV_rq{w}:
      G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = w
      +m = S.padd(p0, 0.5f64, S.psub(p2, p0))
      +kk = F64.div(F64.mul(w1, w1), F64.sub(1.0f64, F64.mul(w1, w1)))
      +c0 = S.padd(m, kk, S.psub(m, p1))
      +n = S.dunit(S.cross(S.psub(p0, c0), S.psub(p1, c0)))
      arc_dist(c0, n, S.dist(p0, c0), p0, p2, S.padd(c0, S.dist(p0, c0), S.dunit(S.psub(p1, c0))), p)
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

def sph_axes() -> List<&2, V.Dir>:
  +k = {0.5773502691896258f64 : F64}
  [S.dr(0.0f64, 0.0f64, 1.0f64), S.dr(1.0f64, 0.0f64, 0.0f64), S.dr(0.0f64, 1.0f64, 0.0f64), S.dr(k, k, k),
    S.dr(k, F64.neg(k), k), S.dr(F64.neg(k), k, k), S.dr(k, k, F64.neg(k))]

def pole_clear(+ls: List<&2, List<&2, CE>>, +b: Ty.Brep, +o: V.Point, +r: F64, +a: V.Dir) -> F64:
  F64.min(lps_dist(ls, b, S.padd(o, r, a), F64.div(1.0f64, 0.0f64)),
    lps_dist(ls, b, S.padd(o, F64.neg(r), a), F64.div(1.0f64, 0.0f64)))

def best_ax(xs: List<&2, V.Dir>, +ls: List<&2, List<&2, CE>>, +b: Ty.Brep, +o: V.Point, +r: F64,
    +best: V.Dir, +bd: F64) -> V.Dir:
  match xs:
    case []: best
    case +h <> +t:
      +d = pole_clear(ls, b, o, r, h)
      +better = F64.is_lt(bd, d)
      best_ax(t, ls, b, o, r, Bool.pick(V.Dir, better, h, best), Bool.pick(F64, better, d, bd))

def sph_frame(+s: S.SF, +ls: List<&2, List<&2, CE>>, +b: Ty.Brep) -> S.SF:
  +a = best_ax(sph_axes(), ls, b, S.sf_o(s), S.sf_r(s), S.sf_a(s), F64.neg(1.0f64))
  +e1 = S.perp_of(a)
  S.SF{S.k_sph(), S.sf_o(s), e1, a, S.sf_r(s), 0.0f64, 0.0f64}

def tor_acc(cs: List<&2, CE>, +s: S.SF, +b: Ty.Brep, +acc: V.Vec2) -> V.Vec2:
  match cs:
    case []: acc
    case +h <> +t:
      +v = S.tor_v(s, S.psub(ce_start3(b, h), S.sf_o(s)))
      tor_acc(t, s, b, V.V2{F64.add(V.v2_x(acc), S.fcos(v)), F64.add(V.v2_y(acc), S.fsin(v))})

def tor_accs(ls: List<&2, List<&2, CE>>, +s: S.SF, +b: Ty.Brep, +acc: V.Vec2) -> V.Vec2:
  match ls:
    case []: acc
    case +h <> +t: tor_accs(t, s, b, tor_acc(h, s, b, acc))

def tor_frame(+s: S.SF, +ls: List<&2, List<&2, CE>>, +b: Ty.Brep) -> S.SF:
  +m = tor_accs(ls, s, b, V.V2{0.0f64, 0.0f64})
  S.SF{S.k_tor(), S.sf_o(s), S.sf_e1(s), S.sf_a(s), S.sf_r(s), S.sf_r2(s), S.fatan2(V.v2_y(m), V.v2_x(m))}

def sf_pick(+k: U64, +s: S.SF, +b: Ty.Brep, +fi: Nat) -> S.SF:
  match k:
    case 4u64: sph_frame(s, face_ce(b, fi), b)
    case 5u64: tor_frame(s, face_ce(b, fi), b)
    case _: s

def face_sf(+b: Ty.Brep, +fi: Nat) -> S.SF:
  +s = S.sf_of(face_surf(b, fi))
  sf_pick(S.sf_kind(s), s, b, fi)

def face_polys(+b: Ty.Brep, +fi: Nat) -> List<&2, List<&2, V.Vec2>>:
  face_polys_go(face_ce(b, fi), face_sf(b, fi), b)

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

def lps_turn(ls: List<&2, List<&2, CE>>, +s: S.SF, +b: Ty.Brep, +acc: F64) -> F64:
  match ls:
    case []: acc
    case +h <> +t: lps_turn(t, s, b, F64.add(acc, lp_turn(h, s, b, 0.0f64)))

def north(+b: Ty.Brep, +fi: Nat, +s: S.SF) -> Bool:
  +w = S.f_round(F64.div(lps_turn(face_ce(b, fi), s, b, 0.0f64), S.two_pi()))
  +sg = Bool.pick(F64, face_same(b, fi), w, F64.neg(w))
  Bool.and(S.is_sph(s), F64.is_lt(0.0f64, sg))

def pip_face(+b: Ty.Brep, +fi: Nat, +s: S.SF, +q: V.Vec2) -> Bool:
  Bool.xor(pip(s, face_polys(b, fi), q), north(b, fi, s))

def pt_in_face(+b: Ty.Brep, +fi: Nat, +p: V.Point) -> Bool:
  +s = face_sf(b, fi)
  pip_face(b, fi, s, uv_raw(s, p))

def tor_bb(+s: S.SF) -> BB:
  +o = S.sf_o(s)
  +a = S.sf_a(s)
  +w = F64.add(S.sf_r(s), S.sf_r2(s))
  +r2 = S.sf_r2(s)
  +hx = F64.add(F64.mul(w, F64.sqrt(F64.max(0.0f64, F64.sub(1.0f64, F64.mul(S.dx(a), S.dx(a)))))), F64.mul(r2, F64.abs(S.dx(a))))
  +hy = F64.add(F64.mul(w, F64.sqrt(F64.max(0.0f64, F64.sub(1.0f64, F64.mul(S.dy(a), S.dy(a)))))), F64.mul(r2, F64.abs(S.dy(a))))
  +hz = F64.add(F64.mul(w, F64.sqrt(F64.max(0.0f64, F64.sub(1.0f64, F64.mul(S.dz(a), S.dz(a)))))), F64.mul(r2, F64.abs(S.dz(a))))
  BB{F64.sub(V.pt_x(o), hx), F64.add(V.pt_x(o), hx), F64.sub(V.pt_y(o), hy), F64.add(V.pt_y(o), hy),
    F64.sub(V.pt_z(o), hz), F64.add(V.pt_z(o), hz)}

def sph_bb(+s: S.SF) -> BB:
  +r = S.sf_r(s)
  +o = S.sf_o(s)
  BB{F64.sub(V.pt_x(o), r), F64.add(V.pt_x(o), r), F64.sub(V.pt_y(o), r), F64.add(V.pt_y(o), r),
    F64.sub(V.pt_z(o), r), F64.add(V.pt_z(o), r)}

def bb_meet(+a: BB, +b: BB) -> BB:
  BB{+ax0, +ax1, +ay0, +ay1, +az0, +az1} = a
  BB{+bx0, +bx1, +by0, +by1, +bz0, +bz1} = b
  BB{F64.max(ax0, bx0), F64.min(ax1, bx1), F64.max(ay0, by0), F64.min(ay1, by1), F64.max(az0, bz0), F64.min(az1, bz1)}

def face_bb(+b: Ty.Brep, +fi: Nat) -> BB:
  +s = S.sf_of(face_surf(b, fi))
  +ls = face_ce(b, fi)
  +e0 = lps_bb(ls, b, bb_empty())
  +tip = Bool.and(U64.is_eq(S.sf_kind(s), S.k_cone()), Nat.is_eq(Nat.mod(wraps_go(ls, s, b, 0n), 2n), 1n))
  +e1 = Bool.pick(BB, tip, bb_join(e0, bb_pt(S.sf_o(s))), Bool.pick(BB, S.is_sph(s), bb_join(e0, sph_bb(s)),
    Bool.pick(BB, S.is_tor(s), bb_meet(bb_pad(e0, F64.mul(2.0f64, S.sf_r2(s))), bb_join(e0, tor_bb(s))), e0)))
  bb_pad(e1, F64.add(F64.add(F64.mul(1.0e-7f64, F64.add(1.0f64, bb_span(e1))), Ty.fa_slv(L.nth_f(Ty.brep_fas(b), fi))), 1.0e-9f64))

def plane_n(+g: G.GVal) -> V.Dir:
  S.sf_a(S.sf_of(g))

def is_plane(+g: G.GVal) -> Bool:
  U64.is_eq(S.sf_kind(S.sf_of(g)), S.k_plane())

def coplanar(+ga: G.GVal, +gb: G.GVal) -> Bool:
  +sa = S.sf_of(ga)
  +sb = S.sf_of(gb)
  +na = S.sf_a(sa)
  +nb = S.sf_a(sb)
  +par = F64.is_eq(S.dlen(S.cross(na, nb)), 0.0f64)
  +on = F64.is_eq(S.dot(S.psub(S.sf_o(sb), S.sf_o(sa)), na), 0.0f64)
  Bool.and(Bool.and(is_plane(ga), is_plane(gb)), Bool.and(par, on))
