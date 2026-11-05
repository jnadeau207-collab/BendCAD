import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c02/types.bend as P
import ../c02/ops.bend as P2
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../c04/types.bend as Ty
import ../base/par.bend as B
import ../c05/exact.bend as XE
import ../base/ex.bend as E
import ./ear.bend as EA
import ./prof.bend as F
import ./model.bend as M
import ../c10/mesh.bend as M10
import ../k1/sf.bend as KS














type QP is Data:
  QP{ id: Nat, x: F64, y: F64 }














type TP is Data:
  TP{ id: Nat, p: V.Point }














type Tri is Data:
  Tri{ a: Nat, b: Nat, c: Nat }














type Ctx is Data:
  Ctx{ vs: B.Tb<&2, V.Point>, es: B.Tb<&2, Ty.Edge>, ces: B.Tb<&2, Ty.Coedge>, lps: B.Tb<&2, Ty.Loop>,
    sb: B.Tb<&2, Nat>, smp: B.Tb<&2, List<&2, V.Point>> }














type LA is Data:
  LA{ b: Nat, ps: List<&2, V.Point>, ts: List<&2, Tri> }














type MQ is Data:
  MQ{ chord: F64, ang: F64, n: Nat }














type VX is Data:
  VX{ u: F64, v: F64, p: V.Point }














type TGO is Data:
  TGO{ ts: List<&2, Tri>, ps: List<&2, V.Point>, ok: Bool }














type ER2 is Data:
  ER2{ k: U64, t: Nat, a: Nat, b: Nat }














type EC is Data:
  EC{ a: Nat, b: Nat, t1: Nat, t2: Nat, d: F64 }














type CM4 is Data:
  CM4{ su: F64, cu: F64, sv: F64, cv: F64 }














type GS is Data:
  GS{ sf: KS.SF, ur: F64, vr: F64, pu: Bool, pv: Bool }














type RF is Data:
  RF{ ts: List<&2, Tri>, vt: B.Tb<&2, VX>, nv: Nat }

def nf(+n: Nat) -> F64:
  U64.to_f64(U64.from_nat(n))

def rq_pts(+w: G.RQBez, +j: Nat, +k: Nat, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match j:
    case 0n: acc
    case 1n+i: rq_pts(w, i, k, G.gres_p(GO.rqb_eval(w, F64.div(nf(j), nf(Nat.add(k, 1n))))) <> acc)

def cc_pts(+w: G.Circle3, +j: Nat, +n: Nat, +lo: F64, +hi: F64, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match j:
    case 0n: acc
    case 1n+i: cc_pts(w, i, n, lo, hi, G.gres_p(GO.circ_eval(w, M10.cc_par(lo, hi, F64.div(nf(j), nf(n))))) <> acc)

def bz_pts(+w: G.Bez3, +j: Nat, +k: Nat, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match j:
    case 0n: acc
    case 1n+i: bz_pts(w, i, k, G.gres_p(GO.bez3_eval(w, F64.div(nf(j), nf(Nat.add(k, 1n))))) <> acc)

def rq_go(+w: G.RQBez, +d: G.Dom, +q: M10.Q) -> List<&2, V.Point>:
  +s = M10.segs_edge(G.GV_rq{w}, d, q)
  +m = Nat.sub(s, 1n)
  rq_pts(w, m, m, [])

def cc_go2(+w: G.Circle3, +d: G.Dom, +q: M10.Q) -> List<&2, V.Point>:
  G.Dom{+lo, +hi} = d
  +s = M10.segs_edge(G.GV_cc{w}, d, q)
  cc_pts(w, Nat.sub(s, 1n), s, lo, hi, [])

def pt_eq(+a: V.Point, +b: V.Point) -> Bool:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  Bool.and(F64.is_eq(ax, bx), Bool.and(F64.is_eq(ay, by), F64.is_eq(az, bz)))

def bz_line(+w: G.Bez3) -> Bool:
  G.Bz{+p0, +p1, +p2, +p3} = w
  Bool.and(pt_eq(p0, p1), pt_eq(p2, p3))

def bz_pick(+line: Bool, +w: G.Bez3, +m: Nat) -> List<&2, V.Point>:
  match line:
    case True{}: []
    case False{}: bz_pts(w, m, m, [])

def bz_go(+w: G.Bez3, +d: G.Dom, +q: M10.Q) -> List<&2, V.Point>:
  +s = M10.segs_edge(G.GV_bz{w}, d, q)
  bz_pick(bz_line(w), w, Nat.sub(s, 1n))

def cv_pts(+c: G.GVal, +d: G.Dom, +q: M10.Q) -> List<&2, V.Point>:
  match c:
    case G.GV_rq{+w}: rq_go(w, d, q)
    case G.GV_cc{+w}: cc_go2(w, d, q)
    case G.GV_bz{+w}: bz_go(w, d, q)
    case _: []

def ek_pts(k: Ty.EdgeKind, +q: M10.Q) -> List<&2, V.Point>:
  match k:
    case Ty.EK_curve{c, d}: cv_pts(c, d, q)
    case Ty.EK_degenerate{}: []

def ed_pts(e: Ty.Edge, +q: M10.Q) -> List<&2, V.Point>:
  Ty.Ed{g, v0, v1, k} = e
  ek_pts(k, q)

def smps(es: List<&2, Ty.Edge>, +q: M10.Q) -> List<&2, List<&2, V.Point>>:
  match es:
    case []: []
    case e <> t: ed_pts(e, q) <> smps(t, q)

def bases(ss: List<&2, List<&2, V.Point>>, +b: Nat) -> List<&2, Nat>:
  match ss:
    case []: []
    case +s <> t: b <> bases(t, Nat.add(b, List.length(&2, V.Point, s)))

def vx_pts(vs: List<&2, Ty.Vertex>) -> List<&2, V.Point>:
  match vs:
    case []: []
    case v <> t:
      Ty.Vx{g, p} = v
      p <> vx_pts(t)

def pz() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def ctx_of(+b: Ty.Brep, +q: M10.Q) -> Ctx:
  +es = Ty.brep_es(b)
  +ss = smps(es, q)
  +nv = List.length(&2, Ty.Vertex, Ty.brep_vs(b))
  Ctx{B.tb_of(V.Point, vx_pts(Ty.brep_vs(b)), pz()), B.tb_of(Ty.Edge, es, Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{0n, 0u64}, Ty.EK_degenerate{}}),
    B.tb_of(Ty.Coedge, Ty.brep_ces(b), Ty.Ce{0u64, Ty.HE{0n, 0u64}, True{}, G.GV_f{0.0f64}}),
    B.tb_of(Ty.Loop, Ty.brep_lps(b), Ty.Lp{0u64, [], Ty.LK_outer{}}), B.tb_of(Nat, bases(ss, nv), 0n),
    B.tb_of(List<&2, V.Point>, ss, [])}

def cat_pts(ss: List<&2, List<&2, V.Point>>) -> List<&2, V.Point>:
  match ss:
    case []: []
    case s <> t: List.append(&2, V.Point, s, cat_pts(t))

def all_pts(+b: Ty.Brep, +q: M10.Q) -> List<&2, V.Point>:
  List.append(&2, V.Point, vx_pts(Ty.brep_vs(b)), cat_pts(smps(Ty.brep_es(b), q)))

def ux(+i: Nat) -> U32:
  U32.from_nat(i)

def tps_of(ps: List<&2, V.Point>, +b: Nat) -> List<&2, TP>:
  match ps:
    case []: []
    case p <> t: TP{b, p} <> tps_of(t, Nat.add(b, 1n))

def tp_rev(xs: List<&2, TP>, +acc: List<&2, TP>) -> List<&2, TP>:
  match xs:
    case []: acc
    case x <> t: tp_rev(t, x <> acc)

def hv_i(h: Ty.HVertex) -> Nat:
  Ty.HV{idx, gen} = h
  idx

def he_i(h: Ty.HEdge) -> Nat:
  Ty.HE{idx, gen} = h
  idx

def hc_i(h: Ty.HCoedge) -> Nat:
  Ty.HC{idx, gen} = h
  idx

def hl_i(h: Ty.HLoop) -> Nat:
  Ty.HL{idx, gen} = h
  idx

def ce_pts(+x: Ctx, +h: Ty.HCoedge) -> List<&2, TP>:
  Ctx{+vs, +es, +ces, +lps, +sb, +smp} = x
  +ce = B.tb_get(Ty.Coedge, ces, ux(hc_i(h)))
  +fwd = Ty.ce_fwd(ce)
  +ei = he_i(Ty.ce_edge(ce))
  +e = B.tb_get(Ty.Edge, es, ux(ei))
  +s = tps_of(B.tb_get(List<&2, V.Point>, smp, ux(ei)), B.tb_get(Nat, sb, ux(ei)))
  +st = Bool.pick(Ty.HVertex, fwd, Ty.ed_v0(e), Ty.ed_v1(e))
  TP{hv_i(st), B.tb_get(V.Point, vs, ux(hv_i(st)))} <> Bool.pick(List<&2, TP>, fwd, s, tp_rev(s, []))

def ring_go(hs: List<&2, Ty.HCoedge>, +x: Ctx) -> List<&2, TP>:
  match hs:
    case []: []
    case h <> t: List.append(&2, TP, ce_pts(x, h), ring_go(t, x))

def ring(+x: Ctx, +h: Ty.HLoop) -> List<&2, TP>:
  Ctx{vs, es, ces, +lps, sb, smp} = x
  ring_go(Ty.lp_ces(B.tb_get(Ty.Loop, lps, ux(hl_i(h)))), x)

def rings(hs: List<&2, Ty.HLoop>, +x: Ctx) -> List<&2, List<&2, TP>>:
  match hs:
    case []: []
    case h <> t: ring(x, h) <> rings(t, x)

def qx(q: QP) -> F64:
  QP{id, x, y} = q
  x

def qy(q: QP) -> F64:
  QP{id, x, y} = q
  y

def tp_id(+t: TP) -> Nat:
  TP{+id, p} = t
  id

def tp_p(+t: TP) -> V.Point:
  TP{id, +p} = t
  p

def nw_add(+n: V.Point, +a: V.Point, +b: V.Point) -> V.Point:
  V.Pt{F64.add(V.pt_x(n), F64.mul(F64.sub(V.pt_y(a), V.pt_y(b)), F64.add(V.pt_z(a), V.pt_z(b)))),
    F64.add(V.pt_y(n), F64.mul(F64.sub(V.pt_z(a), V.pt_z(b)), F64.add(V.pt_x(a), V.pt_x(b)))),
    F64.add(V.pt_z(n), F64.mul(F64.sub(V.pt_x(a), V.pt_x(b)), F64.add(V.pt_y(a), V.pt_y(b))))}

def nw_go(xs: List<&2, TP>, +first: V.Point, +prev: V.Point, +n: V.Point) -> V.Point:
  match xs:
    case []: nw_add(n, prev, first)
    case +x <> t: nw_go(t, first, tp_p(x), nw_add(n, prev, tp_p(x)))

def newell(r: List<&2, TP>) -> V.Point:
  match r:
    case []: pz()
    case +x <> t: nw_go(t, tp_p(x), tp_p(x), pz())

def ax_of(+n: V.Point) -> U64:
  +ax = F64.abs(V.pt_x(n))
  +ay = F64.abs(V.pt_y(n))
  +az = F64.abs(V.pt_z(n))
  Bool.pick(U64, Bool.and(F64.is_le(ay, ax), F64.is_le(az, ax)), 0u64, Bool.pick(U64, F64.is_le(az, ay), 1u64, 2u64))

def proj(+t: TP, +ax: U64) -> QP:
  match ax:
    case 0u64: QP{tp_id(t), V.pt_y(tp_p(t)), V.pt_z(tp_p(t))}
    case 1u64: QP{tp_id(t), V.pt_z(tp_p(t)), V.pt_x(tp_p(t))}
    case _: QP{tp_id(t), V.pt_x(tp_p(t)), V.pt_y(tp_p(t))}

def projs(xs: List<&2, TP>, +ax: U64) -> List<&2, QP>:
  match xs:
    case []: []
    case x <> t: proj(x, ax) <> projs(t, ax)

def q_area_go(xs: List<&2, QP>, +first: QP, +prev: QP, +acc: E.Ex) -> E.Ex:
  match xs:
    case []: E.ex_add(acc, F.cr_ex(qx(prev), qy(prev), qx(first), qy(first)))
    case +x <> t: q_area_go(t, first, x, E.ex_add(acc, F.cr_ex(qx(prev), qy(prev), qx(x), qy(x))))

def q_ccw(r: List<&2, QP>) -> Bool:
  match r:
    case []: True{}
    case +x <> t: F.sgn_pos(E.ex_sign(q_area_go(t, x, x, E.ex_zero())))

def q_rev(xs: List<&2, QP>, +acc: List<&2, QP>) -> List<&2, QP>:
  match xs:
    case []: acc
    case x <> t: q_rev(t, x <> acc)

def tri_flip(xs: List<&2, Tri>) -> List<&2, Tri>:
  match xs:
    case []: []
    case x <> t:
      Tri{a, b, c} = x
      Tri{a, c, b} <> tri_flip(t)

def qrevs(hs: List<&2, List<&2, QP>>) -> List<&2, List<&2, QP>>:
  match hs:
    case []: []
    case h <> t: q_rev(h, []) <> qrevs(t)

def to_ea(xs: List<&2, QP>) -> List<&2, EA.QP>:
  match xs:
    case []: []
    case q <> t:
      QP{id, x, y} = q
      EA.QP{id, x, y} <> to_ea(t)

def to_eas(hs: List<&2, List<&2, QP>>) -> List<&2, List<&2, EA.QP>>:
  match hs:
    case []: []
    case h <> t: to_ea(h) <> to_eas(t)

def of_ea(ts: List<&2, EA.Tri>) -> List<&2, Tri>:
  match ts:
    case []: []
    case x <> t:
      EA.Tri{a, b, c} = x
      Tri{a, b, c} <> of_ea(t)

def tri_poly(+o: List<&2, QP>, +hs: List<&2, List<&2, QP>>) -> List<&2, Tri>:
  of_ea(EA.tri_poly(to_ea(o), to_eas(hs)))

def clip_rings(+o: List<&2, QP>, +hs: List<&2, List<&2, QP>>) -> List<&2, Tri>:
  +ccw = q_ccw(o)
  +fo = Bool.pick(List<&2, QP>, ccw, o, q_rev(o, []))
  +fh = Bool.pick(List<&2, List<&2, QP>>, ccw, hs, qrevs(hs))
  +ts = tri_poly(fo, fh)
  Bool.pick(List<&2, Tri>, ccw, ts, tri_flip(ts))

def projs_all(rs: List<&2, List<&2, TP>>, +ax: U64) -> List<&2, List<&2, QP>>:
  match rs:
    case []: []
    case r <> t: projs(r, ax) <> projs_all(t, ax)

def r_hd(rs: List<&2, List<&2, TP>>) -> List<&2, TP>:
  match rs:
    case []: []
    case r <> t: r

def r_tl(rs: List<&2, List<&2, TP>>) -> List<&2, List<&2, TP>>:
  match rs:
    case []: []
    case r <> t: t

def ql_hd(rs: List<&2, List<&2, QP>>) -> List<&2, QP>:
  match rs:
    case []: []
    case r <> t: r

def ql_tl(rs: List<&2, List<&2, QP>>) -> List<&2, List<&2, QP>>:
  match rs:
    case []: []
    case r <> t: t

def planar_tris(+rs: List<&2, List<&2, TP>>) -> List<&2, Tri>:
  +qs = projs_all(rs, ax_of(newell(r_hd(rs))))
  clip_rings(ql_hd(qs), ql_tl(qs))

def bp_n() -> Nat:
  8n

def bp_dsub(+a: V.Point, +b: V.Point) -> V.Dir:
  V.Dr{F64.sub(V.pt_x(a), V.pt_x(b)), F64.sub(V.pt_y(a), V.pt_y(b)), F64.sub(V.pt_z(a), V.pt_z(b))}

def bp_cros(+a: V.Dir, +b: V.Dir) -> V.Dir:
  V.Dr{F64.sub(F64.mul(V.dr_y(a), V.dr_z(b)), F64.mul(V.dr_z(a), V.dr_y(b))),
    F64.sub(F64.mul(V.dr_z(a), V.dr_x(b)), F64.mul(V.dr_x(a), V.dr_z(b))),
    F64.sub(F64.mul(V.dr_x(a), V.dr_y(b)), F64.mul(V.dr_y(a), V.dr_x(b)))}

def bp_nr2(+d: V.Dir) -> F64:
  F64.add(F64.add(F64.mul(V.dr_x(d), V.dr_x(d)), F64.mul(V.dr_y(d), V.dr_y(d))),
    F64.mul(V.dr_z(d), V.dr_z(d)))

def bp_dot(+a: V.Dir, +b: V.Dir) -> F64:
  F64.add(F64.add(F64.mul(V.dr_x(a), V.dr_x(b)), F64.mul(V.dr_y(a), V.dr_y(b))),
    F64.mul(V.dr_z(a), V.dr_z(b)))

def bp_dev(+p: V.Point, +o: V.Point, +n: V.Dir, +tol: F64) -> Bool:
  F64.is_le(F64.abs(bp_dot(bp_dsub(p, o), n)), tol)

def bp_flat(+w: G.BezP, +o: V.Point, +n: V.Dir, +tol: F64) -> Bool:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30,
    +p31, +p32, +p33} = w
  Bool.and(bp_dev(p00, o, n, tol),
    Bool.and(bp_dev(p01, o, n, tol),
      Bool.and(bp_dev(p02, o, n, tol),
        Bool.and(bp_dev(p03, o, n, tol),
          Bool.and(bp_dev(p10, o, n, tol),
            Bool.and(bp_dev(p11, o, n, tol),
              Bool.and(bp_dev(p12, o, n, tol),
                Bool.and(bp_dev(p13, o, n, tol),
                  Bool.and(bp_dev(p20, o, n, tol),
                    Bool.and(bp_dev(p21, o, n, tol),
                      Bool.and(bp_dev(p22, o, n, tol),
                        Bool.and(bp_dev(p23, o, n, tol),
                          Bool.and(bp_dev(p30, o, n, tol),
                            Bool.and(bp_dev(p31, o, n, tol),
                              Bool.and(bp_dev(p32, o, n, tol), bp_dev(p33, o, n, tol))))))))))))))))

def bp_planar(+w: G.BezP) -> Bool:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30,
    +p31, +p32, +p33} = w
  +e1 = bp_dsub(p03, p00)
  +e2 = bp_dsub(p30, p00)
  +n = bp_cros(e1, e2)
  +nl = F64.sqrt(bp_nr2(n))
  +ex = F64.max(F64.sqrt(bp_nr2(e1)), F64.sqrt(bp_nr2(e2)))
  Bool.pick(Bool, F64.is_eq(nl, 0.0f64), False{},
    bp_flat(G.Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23, p30, p31, p32, p33},
      p00, n, F64.mul(1.0e-9f64, F64.mul(nl, ex))))

def bp_curved(+s: G.GVal) -> Bool:
  match s:
    case G.GV_bp{+w}: Bool.not(bp_planar(w))
    case _: False{}

def bp_ev(+b: G.BezP, +u: F64, +v: F64) -> V.Point:
  G.gres_p(GO.bezp_eval(b, u, v))

def bp_row_go(+k: Nat, +b: G.BezP, +v: F64, +n: Nat) -> List<&2, V.Point>:
  match k:
    case 0n: [bp_ev(b, 1.0f64, v)]
    case 1n+j: List.append(&2, V.Point, [bp_ev(b, F64.div(nf(Nat.sub(n, k)), nf(n)), v)],
      bp_row_go(j, b, v, n))

def bp_grid_go(+k: Nat, +b: G.BezP, +n: Nat) -> List<&2, V.Point>:
  match k:
    case 0n: bp_row_go(n, b, 1.0f64, n)
    case 1n+j: List.append(&2, V.Point, bp_row_go(n, b, F64.div(nf(Nat.sub(n, k)), nf(n)), n),
      bp_grid_go(j, b, n))

def bp_grid(+b: G.BezP) -> List<&2, V.Point>:
  +n = bp_n()
  bp_grid_go(n, b, n)

def bp_cell(+i: Nat, +j: Nat, +base: Nat, +w: Nat) -> List<&2, Tri>:
  +a = Nat.add(base, Nat.add(Nat.mul(j, w), i))
  +b = Nat.add(a, 1n)
  +c = Nat.add(a, w)
  +d = Nat.add(c, 1n)
  [Tri{a, b, d}, Tri{a, d, c}]

def bp_trow_go(+k: Nat, +j: Nat, +base: Nat, +w: Nat, +n: Nat) -> List<&2, Tri>:
  match k:
    case 0n: []
    case 1n+t: List.append(&2, Tri, bp_cell(Nat.sub(n, k), j, base, w), bp_trow_go(t, j, base, w, n))

def bp_tgrid_go(+k: Nat, +base: Nat, +w: Nat, +n: Nat) -> List<&2, Tri>:
  match k:
    case 0n: []
    case 1n+t: List.append(&2, Tri, bp_trow_go(n, Nat.sub(n, k), base, w, n),
      bp_tgrid_go(t, base, w, n))

def bp_tris(+base: Nat) -> List<&2, Tri>:
  +n = bp_n()
  bp_tgrid_go(n, base, Nat.add(n, 1n), n)

def bp_grid_of(+s: G.GVal) -> List<&2, V.Point>:
  match s:
    case G.GV_bp{+w}: bp_grid(w)
    case _: []

def face_bp_go(+solo: Bool, +s: G.GVal) -> List<&2, V.Point>:
  match solo:
    case False{}: []
    case True{}: Bool.pick(List<&2, V.Point>, bp_curved(s), bp_grid_of(s), [])

def bp_used() -> Nat:
  +w = Nat.add(bp_n(), 1n)
  Nat.mul(w, w)

def bp_est() -> Nat:
  Nat.mul(2n, Nat.mul(bp_n(), bp_n()))

def bp_solo(ls: List<&2, Ty.HLoop>) -> Bool:
  Nat.is_eq(List.length(&2, Ty.HLoop, ls), 1n)

def bp_ps_of(fs: List<&2, Ty.Face>) -> List<&2, V.Point>:
  match fs:
    case []: []
    case f <> t:
      Ty.Fa{g, +s, ls, +same, slv, sla} = f
      List.append(&2, V.Point, face_bp_go(bp_solo(ls), s), bp_ps_of(t))

def tp_ids(r: List<&2, TP>) -> List<&2, Nat>:
  match r:
    case []: []
    case +h <> t: tp_id(h) <> tp_ids(t)

def n_rot(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case []: []
    case x <> t: List.append(&2, Nat, t, [x])

def n_rev(xs: List<&2, Nat>, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case []: acc
    case x <> t: n_rev(t, x <> acc)

def n_last(xs: List<&2, Nat>, +d: Nat) -> Nat:
  match xs:
    case []: d
    case x <> t: n_last(t, x)

def n_init(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case []: []
    case x <> t:
      match t:
        case []: []
        case y <> u: x <> n_init(y <> u)

def n_rotr(+xs: List<&2, Nat>) -> List<&2, Nat>:
  Bool.pick(List<&2, Nat>, Nat.is_eq(List.length(&2, Nat, xs), 0n), [], n_last(xs, 0n) <> n_init(xs))

def n_take(xs: List<&2, Nat>, +k: Nat) -> List<&2, Nat>:
  match xs:
    case []: []
    case x <> t:
      match k:
        case 0n: []
        case 1n+j: x <> n_take(t, j)

def n_drop(xs: List<&2, Nat>, +k: Nat) -> List<&2, Nat>:
  match xs:
    case []: []
    case x <> +t:
      match k:
        case 0n: x <> t
        case 1n+j: n_drop(t, j)

def n_hd(xs: List<&2, Nat>) -> Nat:
  match xs:
    case []: 0n
    case x <> t: x

def strip_open(as: List<&2, Nat>, +bs: List<&2, Nat>) -> List<&2, Tri>:
  match as:
    case []: []
    case +a <> at:
      match at:
        case []: []
        case +a2 <> au:
          +b = n_hd(bs)
          +b2 = n_hd(n_drop(bs, 1n))
          Tri{a, a2, b2} <> Tri{a, b2, b} <> strip_open(a2 <> au, n_drop(bs, 1n))

def same_xy(+p: V.Point, +q: V.Point) -> Bool:
  Bool.and(F64.is_eq(V.pt_x(p), V.pt_x(q)), F64.is_eq(V.pt_y(p), V.pt_y(q)))

def tp_nth(xs: List<&2, TP>, +i: Nat) -> TP:
  match xs:
    case []: TP{0n, pz()}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: tp_nth(t, j)

def cyl1_tris(+r: List<&2, TP>) -> List<&2, Tri>:
  +ids0 = tp_ids(r)
  +vfirst = same_xy(tp_p(tp_nth(r, 0n)), tp_p(tp_nth(r, 1n)))
  +ids = Bool.pick(List<&2, Nat>, vfirst, n_rot(ids0), ids0)
  +k = Nat.div(List.length(&2, Nat, ids), 2n)
  strip_open(n_take(ids, k), n_rev(n_drop(ids, k), []))

def strip_go(bs: List<&2, Nat>, ts: List<&2, Nat>, +b0: Nat, +t0: Nat) -> List<&2, Tri>:
  match bs:
    case []: []
    case +b <> +bt:
      match ts:
        case []: []
        case +t <> +tt:
          +bn = Bool.pick(Nat, Nat.is_eq(List.length(&2, Nat, bt), 0n), b0, n_hd(bt))
          +tn = Bool.pick(Nat, Nat.is_eq(List.length(&2, Nat, tt), 0n), t0, n_hd(tt))
          Tri{b, bn, tn} <> Tri{b, tn, t} <> strip_go(bt, tt, b0, t0)

def band_tris(+rs: List<&2, List<&2, TP>>) -> List<&2, Tri>:
  +b = tp_ids(r_hd(rs))
  +t = n_rotr(n_rev(tp_ids(r_hd(r_tl(rs))), []))
  strip_go(b, t, n_hd(b), n_hd(t))

def cyl_c(s: G.GVal) -> V.Point:
  match s:
    case G.GV_cy{w}:
      G.Cy{o, a, r} = w
      o
    case _: pz()

def tri_n(+ps: B.Tb<&2, V.Point>, t: Tri) -> V.Point:
  Tri{+a, +b, +c} = t
  +pa = B.tb_get(V.Point, ps, ux(a))
  +pb = B.tb_get(V.Point, ps, ux(b))
  +pc = B.tb_get(V.Point, ps, ux(c))
  nw_add(nw_add(nw_add(pz(), pa, pb), pb, pc), pc, pa)

def tri_c(+ps: B.Tb<&2, V.Point>, t: Tri) -> V.Point:
  Tri{+a, +b, +c} = t
  +pa = B.tb_get(V.Point, ps, ux(a))
  +pb = B.tb_get(V.Point, ps, ux(b))
  +pc = B.tb_get(V.Point, ps, ux(c))
  V.Pt{F64.add(F64.add(V.pt_x(pa), V.pt_x(pb)), V.pt_x(pc)), F64.add(F64.add(V.pt_y(pa), V.pt_y(pb)), V.pt_y(pc)), 0.0f64}

def dot3(+a: V.Point, +b: V.Point) -> F64:
  F64.add(F64.add(F64.mul(V.pt_x(a), V.pt_x(b)), F64.mul(V.pt_y(a), V.pt_y(b))), F64.mul(V.pt_z(a), V.pt_z(b)))

def out_n(+k: U64, +same: Bool, +n: V.Point, +c: V.Point, +ctr: V.Point) -> V.Point:
  +sg = Bool.pick(F64, same, 1.0f64, F64.neg(1.0f64))
  Bool.pick(V.Point, U64.is_eq(k, 1u64),
    V.Pt{F64.mul(sg, F64.sub(V.pt_x(ctr), F64.mul(3.0f64, V.pt_x(c)))), F64.mul(sg, F64.sub(V.pt_y(ctr), F64.mul(3.0f64, V.pt_y(c)))), 0.0f64}, n)

def tri_one_flip(t: Tri) -> Tri:
  Tri{a, b, c} = t
  Tri{a, c, b}

def fix_go(ts: List<&2, Tri>, +ps: B.Tb<&2, V.Point>, +k: U64, +same: Bool, +n: V.Point, +c: V.Point) -> List<&2, Tri>:
  match ts:
    case []: []
    case +t <> r:
      +d = dot3(tri_n(ps, t), out_n(k, same, n, c, tri_c(ps, t)))
      Bool.pick(Tri, F64.is_lt(d, 0.0f64), tri_one_flip(t), t) <> fix_go(r, ps, k, same, n, c)

def surf_k(s: G.GVal) -> U64:
  match s:
    case G.GV_cy{w}: 1u64
    case G.GV_bp{w}: 2u64
    case _: 0u64

def face_go(+k: U64, +rs: List<&2, List<&2, TP>>, +c: V.Point) -> List<&2, Tri>:
  match k:
    case 1u64:
      Bool.pick(List<&2, Tri>, Nat.is_eq(List.length(&2, List<&2, TP>, rs), 2n), band_tris(rs),
        cyl1_tris(r_hd(rs)))
    case _: planar_tris(rs)

def face_bp_used(f: Ty.Face) -> Nat:
  Ty.Fa{g, +s, ls, +same, slv, sla} = f
  Bool.pick(Nat, Bool.and(Bool.and(U64.is_eq(surf_k(s), 2u64), bp_solo(ls)), bp_curved(s)), bp_used(), 0n)

def face_tris(f: Ty.Face, +x: Ctx, +ps: B.Tb<&2, V.Point>, +base: Nat) -> List<&2, Tri>:
  Ty.Fa{g, +s, +ls, +same, slv, sla} = f
  +rs = rings(ls, x)
  +c = cyl_c(s)
  +k = surf_k(s)
  +isbp = Bool.and(Bool.and(U64.is_eq(k, 2u64), bp_solo(ls)), bp_curved(s))
  fix_go(Bool.pick(List<&2, Tri>, isbp, bp_tris(base), face_go(k, rs, c)), ps, k, same,
    newell(r_hd(rs)), c)

def faces_tris(fs: List<&2, Ty.Face>, +x: Ctx, +ps: B.Tb<&2, V.Point>, +base: Nat) -> List<&2, Tri>:
  match fs:
    case []: []
    case +f <> t:
      List.append(&2, Tri, face_tris(f, x, ps, base), faces_tris(t, x, ps, Nat.add(base, face_bp_used(f))))

def rings_n(rs: List<&2, List<&2, TP>>) -> Nat:
  match rs:
    case []: 0n
    case r <> t: Nat.add(List.length(&2, TP, r), rings_n(t))

def rings_h(rs: List<&2, List<&2, TP>>) -> Nat:
  match rs:
    case []: 0n
    case r <> t: Nat.add(1n, rings_h(t))

def est_face(f: Ty.Face, +x: Ctx) -> Nat:
  Ty.Fa{g, +s, ls, +same, slv, sla} = f
  +rs = rings(ls, x)
  +n = rings_n(rs)
  +h = rings_h(rs)
  +k = surf_k(s)
  Bool.pick(Nat, U64.is_eq(k, 1u64), M10.tri_est_strip(n),
    Bool.pick(Nat, Bool.and(Bool.and(U64.is_eq(k, 2u64), Nat.is_eq(h, 1n)), bp_curved(s)), bp_est(),
      M10.tri_est_add(n, Nat.mul(2n, h))))

def est_faces(fs: List<&2, Ty.Face>, +x: Ctx) -> Nat:
  match fs:
    case []: 0n
    case f <> t: M10.tri_est_add(est_face(f, x), est_faces(t, x))

def mq_chord(+m: MQ) -> F64:
  MQ{chord, ang, n} = m
  chord

def mq_ang(+m: MQ) -> F64:
  MQ{chord, ang, n} = m
  ang

def mq_n(+m: MQ) -> Nat:
  MQ{chord, ang, n} = m
  n

def pt_nth(ps: List<&2, V.Point>, +i: Nat) -> V.Point:
  match ps:
    case []: pz()
    case p <> t:
      match i:
        case 0n: p
        case 1n+j: pt_nth(t, j)

def pt_mid(+a: V.Point, +b: V.Point) -> V.Point:
  V.Pt{F64.mul(0.5f64, F64.add(V.pt_x(a), V.pt_x(b))), F64.mul(0.5f64, F64.add(V.pt_y(a), V.pt_y(b))),
    F64.mul(0.5f64, F64.add(V.pt_z(a), V.pt_z(b)))}

def ev_at(+c: G.GVal, +t: F64) -> V.Point:
  match c:
    case G.GV_rq{+w}: G.gres_p(GO.rqb_eval(w, t))
    case G.GV_cc{+w}: G.gres_p(GO.circ_eval(w, t))
    case G.GV_bz{+w}: G.gres_p(GO.bez3_eval(w, t))
    case _: pz()

def seg_tm(c: G.GVal, +lo: F64, +hi: F64, +f: F64) -> F64:
  match c:
    case G.GV_cc{w}: M10.cc_par(lo, hi, f)
    case _: F64.add(lo, F64.mul(F64.sub(hi, lo), f))

def segs_walk(+c: G.GVal, ps: List<&2, V.Point>, +a: V.Point, +lo: F64, +hi: F64, +s: Nat, +i: Nat, +acc: F64) -> F64:
  match ps:
    case []: acc
    case +b <> +t:
      segs_walk(c, t, b, lo, hi, s, Nat.add(i, 1n), F64.max(acc, M10.pt_dist(ev_at(c, seg_tm(c, lo, hi, F64.div(F64.add(nf(i), 0.5f64), nf(s)))), pt_mid(a, b))))

def segs_go(+c: G.GVal, ps: List<&2, V.Point>, +lo: F64, +hi: F64, +s: Nat, +acc: F64) -> F64:
  match ps:
    case []: acc
    case +a <> +t: segs_walk(c, t, a, lo, hi, s, 0n, acc)

def edge_ang_step(+c: G.GVal, +d: G.Dom, +s: Nat) -> F64:
  match c:
    case G.GV_cc{w}: F64.div(M10.cc_span(d), nf(s))
    case _: 0.0f64

def meas_cc(+w: G.Circle3, +d: G.Dom, +ps: List<&2, V.Point>, +s: Nat) -> MQ:
  G.Dom{+lo, +hi} = d
  MQ{segs_go(G.GV_cc{w}, ps, lo, hi, s, 0.0f64), edge_ang_step(G.GV_cc{w}, d, s), s}

def meas_bz_go(+line: Bool, +w: G.Bez3, +ps: List<&2, V.Point>, +s: Nat) -> MQ:
  match line:
    case True{}: MQ{0.0f64, 0.0f64, 1n}
    case False{}: MQ{segs_go(G.GV_bz{w}, ps, 0.0f64, 1.0f64, s, 0.0f64), 0.0f64, s}

def meas_bz(+w: G.Bez3, +ps: List<&2, V.Point>, +s: Nat) -> MQ:
  meas_bz_go(bz_line(w), w, ps, s)

def meas_curve(+c: G.GVal, +d: G.Dom, +ps: List<&2, V.Point>, +s: Nat) -> MQ:
  match c:
    case G.GV_ln{l}: MQ{0.0f64, 0.0f64, 1n}
    case G.GV_rq{+w}: MQ{segs_go(G.GV_rq{w}, ps, 0.0f64, 1.0f64, s, 0.0f64), F64.div(M10.rq_turn(w), nf(s)), s}
    case G.GV_cc{+w}: meas_cc(w, d, ps, s)
    case G.GV_bz{+w}: meas_bz(w, ps, s)
    case _: MQ{0.0f64, 0.0f64, s}

def meas_kind(k: Ty.EdgeKind, +ss: List<&2, V.Point>, +vs: List<&2, V.Point>, +v0: Ty.HVertex, +v1: Ty.HVertex) -> MQ:
  match k:
    case Ty.EK_degenerate{}: MQ{0.0f64, 0.0f64, 0n}
    case Ty.EK_curve{c, d}:
      +ps = List.append(&2, V.Point, [pt_nth(vs, hv_i(v0))],
        List.append(&2, V.Point, ss, [pt_nth(vs, hv_i(v1))]))
      +s = Nat.sub(List.length(&2, V.Point, ps), 1n)
      meas_curve(c, d, ps, s)

def meas_edge(e: Ty.Edge, +ss: List<&2, V.Point>, +vs: List<&2, V.Point>) -> MQ:
  Ty.Ed{g, v0, v1, k} = e
  meas_kind(k, ss, vs, v0, v1)

def mq_max(+a: MQ, +b: MQ) -> MQ:
  MQ{F64.max(mq_chord(a), mq_chord(b)), F64.max(mq_ang(a), mq_ang(b)), Nat.add(mq_n(a), mq_n(b))}

def meas_go(es: List<&2, Ty.Edge>, ss: List<&2, List<&2, V.Point>>, +vs: List<&2, V.Point>) -> MQ:
  match es:
    case []: MQ{0.0f64, 0.0f64, 0n}
    case e <> t:
      match ss:
        case []: MQ{0.0f64, 0.0f64, 0n}
        case s <> u: mq_max(meas_edge(e, s, vs), meas_go(t, u, vs))

def pl_pt(+p: V.Point, +pl: M.Pl) -> V.Point:
  M.Pl{m, +tx, +ty, +tz, mi, ti} = pl
  +v = M.m3_ap(m, V.pt_x(p), V.pt_y(p), V.pt_z(p))
  V.Pt{F64.add(M.f_nth(v, 0n), tx), F64.add(M.f_nth(v, 1n), ty), F64.add(M.f_nth(v, 2n), tz)}

def obj_vs(ps: List<&2, V.Point>, +pl: M.Pl) -> String:
  match ps:
    case []: ""
    case p <> t:
      +q = pl_pt(p, pl)
      "v " ++ F64.show(V.pt_x(q)) ++ " " ++ F64.show(V.pt_y(q)) ++ " " ++ F64.show(V.pt_z(q)) ++ "\n" ++ obj_vs(t, pl)

def obj_fs(ts: List<&2, Tri>) -> String:
  match ts:
    case []: ""
    case t <> r:
      Tri{a, b, c} = t
      "f " ++ Nat.show(Nat.add(a, 1n)) ++ " " ++ Nat.show(Nat.add(b, 1n)) ++ " " ++ Nat.show(Nat.add(c, 1n)) ++ "\n" ++ obj_fs(r)

def ek(+a: Nat, +b: Nat) -> U64:
  U64.add(U64.mul(U64.from_nat(a), 4294967296u64), U64.from_nat(b))

def dir_es(ts: List<&2, Tri>, +fw: List<&2, U64>, +bk: List<&2, U64>) -> List<&2, List<&2, U64>>:
  match ts:
    case []: [fw, bk]
    case t <> +r:
      Tri{+a, +b, +c} = t
      dir_es(r, ek(a, b) <> ek(b, c) <> ek(c, a) <> fw, ek(b, a) <> ek(c, b) <> ek(a, c) <> bk)

def u_cmp_go(+a: U64, +b: U64) -> B.Sgn:
  B.sgn_pick(U64.is_lt(a, b), U64.is_lt(b, a))

def u_cmp(a: U64, b: U64) -> B.Sgn:
  u_cmp_go(a, b)

def so_u(s: B.So<&2, U64>) -> List<&2, U64>:
  B.So{ok, xs} = s
  xs

def u_same(xs: List<&2, U64>, ys: List<&2, U64>) -> Bool:
  match xs:
    case []:
      match ys:
        case []: True{}
        case _: False{}
    case +x <> +t:
      match ys:
        case []: False{}
        case +y <> +u: Bool.and(U64.is_eq(x, y), u_same(t, u))

def es_hd(xs: List<&2, List<&2, U64>>) -> List<&2, U64>:
  match xs:
    case []: []
    case +x <> t: x

def es_tl(xs: List<&2, List<&2, U64>>) -> List<&2, U64>:
  match xs:
    case []: []
    case x <> +t: es_hd(t)

def closed(+ts: List<&2, Tri>) -> Bool:
  +es = dir_es(ts, [], [])
  u_same(so_u(B.msort(~U64, ~u_cmp, es_hd(es))), so_u(B.msort(~U64, ~u_cmp, es_tl(es))))

def pri_out(ok: Bool, +r: M10.Tres) -> M10.Tres:
  match ok:
    case True{}: r
    case False{}: M10.tres_fail("tess-mesh-not-closed")

def use_gen(f: Ty.Face, +x: Ctx) -> Bool:
  Ty.Fa{g, +s, +ls, same, slv, sla} = f
  +k = KS.sf_kind(KS.sf_of(s))
  Bool.and(Bool.not(U64.is_eq(k, 1u64)), Bool.not(Bool.and(U64.is_eq(k, 2u64), Nat.is_eq(List.length(&2, Ty.HLoop, ls), 2n))))

def gt_add(+a: TGO, +b: TGO) -> TGO:
  TGO{+ta, +pa, +oa} = a
  TGO{+tb, +pb, +ob} = b
  TGO{List.append(&2, Tri, ta, tb), List.append(&2, V.Point, pa, pb), Bool.and(oa, ob)}

def gt_np(+a: TGO) -> Nat:
  TGO{ts, +ps, ok} = a
  List.length(&2, V.Point, ps)

def cm_add(+acc: CM4, +w: V.Vec2) -> CM4:
  CM4{+su, +cu, +sv, +cv} = acc
  CM4{F64.add(su, KS.fsin(V.v2_x(w))), F64.add(cu, KS.fcos(V.v2_x(w))), F64.add(sv, KS.fsin(V.v2_y(w))), F64.add(cv, KS.fcos(V.v2_y(w)))}

def cm_ring(r: List<&2, TP>, +sf: KS.SF, +acc: CM4) -> CM4:
  match r:
    case []: acc
    case +h <> t: cm_ring(t, sf, cm_add(acc, KS.sf_uv(sf, tp_p(h))))

def cm_rings(rs: List<&2, List<&2, TP>>, +sf: KS.SF, +acc: CM4) -> CM4:
  match rs:
    case []: acc
    case +r <> t: cm_rings(t, sf, cm_ring(r, sf, acc))

def g_pu(+sf: KS.SF) -> Bool:
  +k = KS.sf_kind(sf)
  Bool.and(U64.is_le(2u64, k), U64.is_le(k, 5u64))

def g_pv(+sf: KS.SF) -> Bool:
  U64.is_eq(KS.sf_kind(sf), 5u64)

def gs_mk(+sf: KS.SF, +c: CM4) -> GS:
  CM4{+su, +cu, +sv, +cv} = c
  GS{sf, KS.fatan2(su, cu), KS.fatan2(sv, cv), g_pu(sf), g_pv(sf)}

def gs_of(+sf: KS.SF, +rs: List<&2, List<&2, TP>>) -> GS:
  gs_mk(sf, cm_rings(rs, sf, CM4{0.0f64, 0.0f64, 0.0f64, 0.0f64}))

def g_uvw(+g: GS, +w: V.Vec2) -> V.Vec2:
  GS{sf, +ur, +vr, +pu, +pv} = g
  V.V2{Bool.pick(F64, pu, KS.ang_diff(ur, V.v2_x(w)), V.v2_x(w)), Bool.pick(F64, pv, KS.ang_diff(vr, V.v2_y(w)), V.v2_y(w))}

def gs_sf(+g: GS) -> KS.SF:
  GS{+sf, ur, vr, pu, pv} = g
  sf

def g_uv(+g: GS, +p: V.Point) -> V.Vec2:
  g_uvw(g, KS.sf_uv(gs_sf(g), p))

def g_qp(r: List<&2, TP>, +g: GS, +i: Nat) -> List<&2, QP>:
  match r:
    case []: []
    case +h <> t:
      +w = g_uv(g, tp_p(h))
      QP{i, V.v2_x(w), V.v2_y(w)} <> g_qp(t, g, Nat.add(i, 1n))

def g_qps(rs: List<&2, List<&2, TP>>, +g: GS, +i: Nat) -> List<&2, List<&2, QP>>:
  match rs:
    case []: []
    case +r <> t: g_qp(r, g, i) <> g_qps(t, g, Nat.add(i, List.length(&2, TP, r)))

def g_vx(r: List<&2, TP>, +g: GS) -> List<&2, VX>:
  match r:
    case []: []
    case +h <> t:
      +w = g_uv(g, tp_p(h))
      VX{V.v2_x(w), V.v2_y(w), tp_p(h)} <> g_vx(t, g)

def g_vxs(rs: List<&2, List<&2, TP>>, +g: GS) -> List<&2, VX>:
  match rs:
    case []: []
    case +r <> t: List.append(&2, VX, g_vx(r, g), g_vxs(t, g))

def g_ids(rs: List<&2, List<&2, TP>>) -> List<&2, Nat>:
  match rs:
    case []: []
    case +r <> t: List.append(&2, Nat, tp_ids(r), g_ids(t))

def g_links(n: Nat, +b: Nat, +i: Nat, +len: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: Nat.add(b, Bool.pick(Nat, Nat.is_eq(Nat.add(i, 1n), len), 0n, Nat.add(i, 1n))) <> g_links(m, b, Nat.add(i, 1n), len)

def g_nx(rs: List<&2, List<&2, TP>>, +b: Nat) -> List<&2, Nat>:
  match rs:
    case []: []
    case +r <> t:
      +n = List.length(&2, TP, r)
      List.append(&2, Nat, g_links(n, b, 0n, n), g_nx(t, Nat.add(b, n)))

def vx0() -> VX:
  VX{0.0f64, 0.0f64, V.Pt{0.0f64, 0.0f64, 0.0f64}}

def rep_vx(n: Nat) -> List<&2, VX>:
  match n:
    case 0n: []
    case 1n+m: vx0() <> rep_vx(m)

def ekey(+a: Nat, +b: Nat) -> U64:
  +lo = Bool.pick(Nat, Nat.is_lt(a, b), a, b)
  +hi = Bool.pick(Nat, Nat.is_lt(a, b), b, a)
  U64.add(U64.mul(U64.from_nat(lo), 4294967296u64), U64.from_nat(hi))

def tri_ers(ts: List<&2, Tri>, +i: Nat) -> List<&2, ER2>:
  match ts:
    case []: []
    case +t <> r:
      Tri{+a, +b, +c} = t
      ER2{ekey(a, b), i, a, b} <> ER2{ekey(b, c), i, b, c} <> ER2{ekey(c, a), i, c, a} <> tri_ers(r, Nat.add(i, 1n))

def so_er(s: B.So<&2, ER2>) -> List<&2, ER2>:
  B.So{ok, xs} = s
  xs

def is_bnd(+nx: B.Tb<&2, Nat>, +nb: Nat, +a: Nat, +b: Nat) -> Bool:
  Bool.and(Bool.and(Nat.is_lt(a, nb), Nat.is_lt(b, nb)),
    Bool.or(Nat.is_eq(B.tb_get(Nat, nx, U32.from_nat(a)), b), Nat.is_eq(B.tb_get(Nat, nx, U32.from_nat(b)), a)))

def g_at(+g: GS, +u: F64, +v: F64) -> V.Point:
  GS{+sf, +ur, +vr, +pu, +pv} = g
  KS.sf_at(sf, Bool.pick(F64, pu, F64.add(u, ur), u), Bool.pick(F64, pv, F64.add(v, vr), v))

def p_mid(+a: V.Point, +b: V.Point) -> V.Point:
  V.Pt{F64.mul(0.5f64, F64.add(V.pt_x(a), V.pt_x(b))), F64.mul(0.5f64, F64.add(V.pt_y(a), V.pt_y(b))), F64.mul(0.5f64, F64.add(V.pt_z(a), V.pt_z(b)))}

def p_dist(+a: V.Point, +b: V.Point) -> F64:
  +x = F64.sub(V.pt_x(a), V.pt_x(b))
  +y = F64.sub(V.pt_y(a), V.pt_y(b))
  +z = F64.sub(V.pt_z(a), V.pt_z(b))
  F64.sqrt(F64.add(F64.mul(x, x), F64.add(F64.mul(y, y), F64.mul(z, z))))

def vx_u(+x: VX) -> F64:
  VX{+u, v, p} = x
  u

def vx_v(+x: VX) -> F64:
  VX{u, +v, p} = x
  v

def vx_p(+x: VX) -> V.Point:
  VX{u, v, +p} = x
  p

def e_dev(+g: GS, +va: VX, +vb: VX) -> F64:
  p_dist(g_at(g, F64.mul(0.5f64, F64.add(vx_u(va), vx_u(vb))), F64.mul(0.5f64, F64.add(vx_v(va), vx_v(vb)))), p_mid(vx_p(va), vx_p(vb)))

def ec_mk(take: Bool, +ae: Nat, +be: Nat, +te: Nat, +tf: Nat, +d: F64, +rest: List<&2, EC>) -> List<&2, EC>:
  match take:
    case True{}: EC{ae, be, te, tf, d} <> rest
    case False{}: rest

def er_k(+e: ER2) -> U64:
  ER2{+k, t, a, b} = e
  k

def er_t(+e: ER2) -> Nat:
  ER2{k, +t, a, b} = e
  t

def er_a(+e: ER2) -> Nat:
  ER2{k, t, +a, b} = e
  a

def er_b(+e: ER2) -> Nat:
  ER2{k, t, a, +b} = e
  b

def ecands(n: Nat, es: List<&2, ER2>, +g: GS, +vt: B.Tb<&2, VX>, +nx: B.Tb<&2, Nat>, +nb: Nat, +tol: F64) -> List<&2, EC>:
  match n:
    case 0n: []
    case 1n+(+m):
      match es:
        case []: []
        case +e <> +t:
          match t:
            case []: []
            case +f <> +t2:
              +ae = er_a(e)
              +be = er_b(e)
              +pair = U64.is_eq(er_k(e), er_k(f))
              +d = e_dev(g, B.tb_get(VX, vt, U32.from_nat(ae)), B.tb_get(VX, vt, U32.from_nat(be)))
              +take = Bool.and(Bool.and(pair, Bool.not(is_bnd(nx, nb, ae, be))), F64.is_lt(tol, d))
              ec_mk(take, ae, be, er_t(e), er_t(f), d, ecands(m, Bool.pick(List<&2, ER2>, pair, t2, f <> t2), g, vt, nx, nb, tol))

def so_ec(s: B.So<&2, EC>) -> List<&2, EC>:
  B.So{ok, xs} = s
  xs

def pick_go(cs: List<&2, EC>, +used: B.Tb<&2, Bool>, +acc: List<&2, EC>, +room: Nat) -> List<&2, EC>:
  match cs:
    case []: acc
    case +c <> t:
      EC{+a, +b, +t1, +t2, +d} = c
      +free = Bool.and(Bool.not(B.tb_get(Bool, used, U32.from_nat(t1))), Bool.not(B.tb_get(Bool, used, U32.from_nat(t2))))
      +ok = Bool.and(free, Nat.is_lt(0n, room))
      pick_go(t, Bool.pick(B.Tb<&2, Bool>, ok, B.tb_set(Bool, B.tb_set(Bool, used, U32.from_nat(t1), True{}), U32.from_nat(t2), True{}), used),
        Bool.pick(List<&2, EC>, ok, EC{a, b, t1, t2, d} <> acc, acc), Bool.pick(Nat, ok, Nat.sub(room, 1n), room))

def rep_bl(n: Nat) -> List<&2, Bool>:
  match n:
    case 0n: []
    case 1n+m: False{} <> rep_bl(m)

def rep_nn(n: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: 0n <> rep_nn(m)

def mark_sp(cs: List<&2, EC>, +sp: B.Tb<&2, Nat>, +k: Nat) -> B.Tb<&2, Nat>:
  match cs:
    case []: sp
    case +c <> t:
      EC{a, b, +t1, +t2, d} = c
      mark_sp(t, B.tb_set(Nat, B.tb_set(Nat, sp, U32.from_nat(t1), Nat.add(k, 1n)), U32.from_nat(t2), Nat.add(k, 1n)), Nat.add(k, 1n))

def vx_mid(+g: GS, +va: VX, +vb: VX) -> VX:
  +um = F64.mul(0.5f64, F64.add(vx_u(va), vx_u(vb)))
  +wm = F64.mul(0.5f64, F64.add(vx_v(va), vx_v(vb)))
  VX{um, wm, g_at(g, um, wm)}

def add_mids(cs: List<&2, EC>, +g: GS, +vt: B.Tb<&2, VX>, +nv: Nat) -> B.Tb<&2, VX>:
  match cs:
    case []: vt
    case +c <> t:
      EC{+a, +b, t1, t2, d} = c
      +m = vx_mid(g, B.tb_get(VX, vt, U32.from_nat(a)), B.tb_get(VX, vt, U32.from_nat(b)))
      add_mids(t, g, B.tb_set(VX, vt, U32.from_nat(nv), m), Nat.add(nv, 1n))

def ec_at(cs: List<&2, EC>, +i: Nat) -> EC:
  match cs:
    case []: EC{0n, 0n, 0n, 0n, 0.0f64}
    case +c <> t:
      match i:
        case 0n: c
        case 1n+(+j): ec_at(t, j)

def ec_a(+c: EC) -> Nat:
  EC{+a, b, t1, t2, d} = c
  a

def ec_b(+c: EC) -> Nat:
  EC{a, +b, t1, t2, d} = c
  b

def split_tri(+t: Tri, +ea: Nat, +eb: Nat, +m: Nat) -> List<&2, Tri>:
  Tri{+a, +b, +c} = t
  +ab = Bool.or(Bool.and(Nat.is_eq(a, ea), Nat.is_eq(b, eb)), Bool.and(Nat.is_eq(a, eb), Nat.is_eq(b, ea)))
  +bc = Bool.or(Bool.and(Nat.is_eq(b, ea), Nat.is_eq(c, eb)), Bool.and(Nat.is_eq(b, eb), Nat.is_eq(c, ea)))
  Bool.pick(List<&2, Tri>, ab, [Tri{a, m, c}, Tri{m, b, c}],
    Bool.pick(List<&2, Tri>, bc, [Tri{b, m, a}, Tri{m, c, a}], [Tri{c, m, b}, Tri{m, a, b}]))

def sp_tri(s: Nat, +t: Tri, +cs: List<&2, EC>, +nv0: Nat) -> List<&2, Tri>:
  match s:
    case 0n: [t]
    case 1n+(+j):
      +c = ec_at(cs, j)
      split_tri(t, ec_a(c), ec_b(c), Nat.add(nv0, j))

def resplit(ts: List<&2, Tri>, +sp: B.Tb<&2, Nat>, +cs: List<&2, EC>, +nv0: Nat, +i: Nat) -> List<&2, Tri>:
  match ts:
    case []: []
    case +t <> r:
      List.append(&2, Tri, sp_tri(B.tb_get(Nat, sp, U32.from_nat(i)), t, cs, nv0), resplit(r, sp, cs, nv0, Nat.add(i, 1n)))

def k_cmp(+x: U64, +y: U64) -> B.Sgn:
  B.sgn_pick(U64.is_lt(x, y), U64.is_lt(y, x))

def er_cmp(a: ER2, b: ER2) -> B.Sgn:
  k_cmp(er_k(a), er_k(b))

def ec_d(+c: EC) -> F64:
  EC{a, b, t1, t2, +d} = c
  d

def d_cmp(+x: F64, +y: F64) -> B.Sgn:
  B.sgn_pick(F64.is_lt(y, x), F64.is_lt(x, y))

def ec_cmp(a: EC, b: EC) -> B.Sgn:
  d_cmp(ec_d(a), ec_d(b))

def ref_go(n: Nat, done: Bool, +r: RF, +g: GS, +nx: B.Tb<&2, Nat>, +nb: Nat, +cap: Nat, +tol: F64) -> RF:
  match n:
    case 0n: r
    case 1n+(+m):
      match done:
        case True{}: r
        case False{}:
          RF{+ts, +vt, +nv} = r
          +nt = List.length(&2, Tri, ts)
          +es = so_er(B.msort(~ER2, ~er_cmp, tri_ers(ts, 0n)))
          +cs = so_ec(B.msort(~EC, ~ec_cmp, ecands(Nat.mul(3n, nt), es, g, vt, nx, nb, tol)))
          +room = Bool.pick(Nat, Nat.is_lt(nv, cap), Nat.sub(cap, nv), 0n)
          +acc = List.reverse(&2, EC, pick_go(cs, B.tb_of(Bool, rep_bl(nt), False{}), [], room))
          +k = List.length(&2, EC, acc)
          ref_go(m, Nat.is_eq(k, 0n), RF{resplit(ts, mark_sp(acc, B.tb_of(Nat, rep_nn(nt), 0n), 0n), acc, nv, 0n),
            add_mids(acc, g, vt, nv), Nat.add(nv, k)}, g, nx, nb, cap, tol)

def v3sub(+a: V.Point, +b: V.Point) -> V.Dir:
  V.Dr{F64.sub(V.pt_x(a), V.pt_x(b)), F64.sub(V.pt_y(a), V.pt_y(b)), F64.sub(V.pt_z(a), V.pt_z(b))}

def v3cross(+a: V.Dir, +b: V.Dir) -> V.Dir:
  V.Dr{F64.sub(F64.mul(V.dr_y(a), V.dr_z(b)), F64.mul(V.dr_z(a), V.dr_y(b))),
    F64.sub(F64.mul(V.dr_z(a), V.dr_x(b)), F64.mul(V.dr_x(a), V.dr_z(b))),
    F64.sub(F64.mul(V.dr_x(a), V.dr_y(b)), F64.mul(V.dr_y(a), V.dr_x(b)))}

def v3dot(+a: V.Dir, +b: V.Dir) -> F64:
  F64.add(F64.add(F64.mul(V.dr_x(a), V.dr_x(b)), F64.mul(V.dr_y(a), V.dr_y(b))), F64.mul(V.dr_z(a), V.dr_z(b)))

def p3c(+a: V.Point, +b: V.Point, +c: V.Point) -> V.Point:
  V.Pt{F64.div(F64.add(F64.add(V.pt_x(a), V.pt_x(b)), V.pt_x(c)), 3.0f64), F64.div(F64.add(F64.add(V.pt_y(a), V.pt_y(b)), V.pt_y(c)), 3.0f64),
    F64.div(F64.add(F64.add(V.pt_z(a), V.pt_z(b)), V.pt_z(c)), 3.0f64)}

def t_dot(+t: Tri, +vt: B.Tb<&2, VX>, +sf: KS.SF) -> F64:
  Tri{+a, +b, +c} = t
  +pa = vx_p(B.tb_get(VX, vt, U32.from_nat(a)))
  +pb = vx_p(B.tb_get(VX, vt, U32.from_nat(b)))
  +pc = vx_p(B.tb_get(VX, vt, U32.from_nat(c)))
  v3dot(v3cross(v3sub(pb, pa), v3sub(pc, pa)), KS.sf_grad(sf, p3c(pa, pb, pc)))

def ts_dot(ts: List<&2, Tri>, +vt: B.Tb<&2, VX>, +sf: KS.SF, +acc: F64) -> F64:
  match ts:
    case []: acc
    case +t <> r: ts_dot(r, vt, sf, F64.add(acc, t_dot(t, vt, sf)))

def g_flip(+t: Tri, +rev: Bool) -> Tri:
  Tri{+a, +b, +c} = t
  Bool.pick(Tri, rev, Tri{a, c, b}, Tri{a, b, c})

def g_ids_map(+i: Nat, +gid: B.Tb<&2, Nat>, +nb: Nat, +base: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_lt(i, nb), B.tb_get(Nat, gid, U32.from_nat(i)), Nat.add(base, Nat.sub(i, nb)))

def g_map(+t: Tri, +gid: B.Tb<&2, Nat>, +nb: Nat, +base: Nat) -> Tri:
  Tri{+a, +b, +c} = t
  Tri{g_ids_map(a, gid, nb, base), g_ids_map(b, gid, nb, base), g_ids_map(c, gid, nb, base)}

def g_out(ts: List<&2, Tri>, +rev: Bool, +gid: B.Tb<&2, Nat>, +nb: Nat, +base: Nat) -> List<&2, Tri>:
  match ts:
    case []: []
    case +t <> r:
      g_map(g_flip(t, rev), gid, nb, base) <> g_out(r, rev, gid, nb, base)

def g_newps(n: Nat, +vt: B.Tb<&2, VX>, +i: Nat) -> List<&2, V.Point>:
  match n:
    case 0n: []
    case 1n+(+m): vx_p(B.tb_get(VX, vt, U32.from_nat(i))) <> g_newps(m, vt, Nat.add(i, 1n))

def gen_fin(+r: RF, +sf: KS.SF, +same: Bool, +gid: B.Tb<&2, Nat>, +nb: Nat, +base: Nat, +ok: Bool) -> TGO:
  RF{+ts, +vt, +nv} = r
  +d = ts_dot(ts, vt, sf, 0.0f64)
  +rev = F64.is_lt(Bool.pick(F64, same, d, F64.neg(d)), 0.0f64)
  TGO{g_out(ts, rev, gid, nb, base), g_newps(Nat.sub(nv, nb), vt, nb), ok}

def gen_rs(+rs: List<&2, List<&2, TP>>, +sf: KS.SF, +same: Bool, +base: Nat, +tol: F64) -> TGO:
  +g = gs_of(sf, rs)
  +qs = g_qps(rs, g, 0n)
  +t0 = clip_rings(ql_hd(qs), ql_tl(qs))
  +nb = rings_n(rs)
  +cap = Nat.add(Nat.mul(6n, nb), 256n)
  +vt = B.tb_of(VX, List.append(&2, VX, g_vxs(rs, g), rep_vx(cap)), vx0())
  +nx = B.tb_of(Nat, g_nx(rs, 0n), 0n)
  +r = ref_go(48n, False{}, RF{t0, vt, nb}, g, nx, nb, Nat.add(nb, cap), tol)
  gen_fin(r, sf, same, B.tb_of(Nat, g_ids(rs), 0n), nb, base, Bool.not(Nat.is_eq(List.length(&2, Tri, t0), 0n)))

def gen_face(f: Ty.Face, +x: Ctx, +base: Nat, +tol: F64) -> TGO:
  Ty.Fa{g, +s, +ls, +same, slv, sla} = f
  gen_rs(rings(ls, x), KS.sf_of(s), same, base, tol)

def face_tg(use: Bool, f: Ty.Face, +x: Ctx, +ps: B.Tb<&2, V.Point>, +bbase: Nat, +gbase: Nat, +tol: F64) -> TGO:
  match use:
    case True{}: gen_face(f, x, gbase, tol)
    case False{}: TGO{face_tris(f, x, ps, bbase), [], True{}}

def faces_tg(fs: List<&2, Ty.Face>, +x: Ctx, +ps: B.Tb<&2, V.Point>, +bbase: Nat, +gbase: Nat, +tol: F64) -> TGO:
  match fs:
    case []: TGO{[], [], True{}}
    case +f <> t:
      +u = use_gen(f, x)
      +r = face_tg(u, f, x, ps, bbase, gbase, tol)
      gt_add(r, faces_tg(t, x, ps, Nat.add(bbase, Bool.pick(Nat, u, 0n, face_bp_used(f))), Nat.add(gbase, gt_np(r)), tol))

def pri_fin(+gt: TGO, +all: List<&2, V.Point>, +b: M.Body, +est: Nat, +mq: MQ) -> M10.Tres:
  TGO{+ts, +gp, +gok} = gt
  +all2 = List.append(&2, V.Point, all, gp)
  pri_out(Bool.and(gok, closed(ts)), M10.tres_ok(obj_vs(all2, M.bd_pl(b)) ++ obj_fs(ts),
    List.length(&2, V.Point, all2), List.length(&2, Tri, ts), est,
    mq_chord(mq), mq_ang(mq), mq_n(mq)))

def pri_emit(+b: M.Body, +q: M10.Q, +est: Nat) -> M10.Tres:
  +br = M.bd_brep(b)
  +ps = all_pts(br, q)
  +all = List.append(&2, V.Point, ps, bp_ps_of(Ty.brep_fas(br)))
  +tb = B.tb_of(V.Point, all, pz())
  +mq = meas_go(Ty.brep_es(br), smps(Ty.brep_es(br), q), vx_pts(Ty.brep_vs(br)))
  pri_fin(faces_tg(Ty.brep_fas(br), ctx_of(br, q), tb, List.length(&2, V.Point, ps), List.length(&2, V.Point, all), M10.q_chord(q)), all, b, est, mq)

def pri_go(+ok: Bool, +b: M.Body, +q: M10.Q, +est: Nat) -> M10.Tres:
  match ok:
    case False{}: M10.tres_fail_est("tess-budget-exceeded", est)
    case True{}: pri_emit(b, q, est)

def pri_q(+b: M.Body, +q: M10.Q) -> M10.Tres:
  +br = M.bd_brep(b)
  +est = est_faces(Ty.brep_fas(br), ctx_of(br, q))
  pri_go(M10.budget_ok(est, M10.q_max(q)), b, q, est)

def rq2(j: Nat, +w: G.RQBez, +k: Nat) -> List<&2, V.Vec2>:
  match j:
    case 0n: []
    case 1n+(+i):
      +q = G.gres_p(GO.rqb_eval(w, F64.div(nf(Nat.sub(k, i)), nf(Nat.add(k, 1n)))))
      V.V2{V.pt_x(q), V.pt_z(q)} <> rq2(i, w, k)

def arc_segs(+ax: F64, +ay: F64, +px: F64, +py: F64, +w: F64, +bx: F64, +by: F64,
    +q: M10.Q) -> Nat:
  M10.segs_edge(G.GV_rq{G.Rq{V.Pt{ax, 0.0f64, ay}, V.Pt{px, 0.0f64, py}, V.Pt{bx, 0.0f64, by}, 1.0f64, w, 1.0f64}},
    G.Dom{0.0f64, 1.0f64}, q)

def lath_pcs(ps: List<&2, F.Pc>, +q: M10.Q) -> List<&2, V.Vec2>:
  match ps:
    case []: []
    case p <> +t:
      match p:
        case F.P_ln{ax, ay, bx, by}: V.V2{ax, ay} <> lath_pcs(t, q)
        case F.P_ar{+ax, +ay, +px, +py, +w, +bx, +by}:
          +m = Nat.sub(arc_segs(ax, ay, px, py, w, bx, by, q), 1n)
          List.append(&2, V.Vec2, V.V2{ax, ay} <> rq2(m, G.Rq{V.Pt{ax, 0.0f64, ay}, V.Pt{px, 0.0f64, py}, V.Pt{bx, 0.0f64, by}, 1.0f64, w, 1.0f64}, m),
            lath_pcs(t, q))

def ring_segs(+r: F64, +q: M10.Q) -> Nat:
  M10.even_up(M10.nat_max(3n, M10.nat_max(M10.segs_arc(r, 6.283185307179586f64, M10.q_chord(q)),
    M10.segs_ang(6.283185307179586f64, M10.q_angle(q)))))

def rings_max(qs: List<&2, V.Vec2>, +q: M10.Q) -> Nat:
  match qs:
    case []: 3n
    case v <> t: M10.nat_max(ring_segs(V.v2_x(v), q), rings_max(t, q))

def ring_pts(i: Nat, +r: F64, +h: F64, +n: Nat) -> List<&2, V.Point>:
  match i:
    case 0n: []
    case 1n+(+j):
      +t = M10.cc_par(F64.neg(1.0f64), 1.0f64, F64.div(nf(Nat.sub(n, Nat.add(j, 1n))), nf(n)))
      G.gres_p(GO.circ_eval(G.Cc{V.Pt{0.0f64, 0.0f64, h}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}, r}, t)) <> ring_pts(j, r, h, n)

def lath_ring(+q: V.Vec2, +n: Nat) -> List<&2, V.Point>:
  Bool.pick(List<&2, V.Point>, F64.is_lt(0.0f64, V.v2_x(q)), ring_pts(n, V.v2_x(q), V.v2_y(q), n), [V.Pt{0.0f64, 0.0f64, V.v2_y(q)}])

def lath_rings(qs: List<&2, V.Vec2>, +n: Nat) -> List<&2, List<&2, V.Point>>:
  match qs:
    case []: []
    case q <> t: lath_ring(q, n) <> lath_rings(t, n)

def n_rep(n: Nat, +b: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: b <> n_rep(m, b)

def n_seq(n: Nat, +b: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: b <> n_seq(m, Nat.add(b, 1n))

def ring_ids(+pts: List<&2, V.Point>, +b: Nat, +n: Nat) -> List<&2, Nat>:
  Bool.pick(List<&2, Nat>, Nat.is_eq(List.length(&2, V.Point, pts), 1n), n_rep(n, b), n_seq(n, b))

def ids_of(rs: List<&2, List<&2, V.Point>>, +b: Nat, +n: Nat) -> List<&2, List<&2, Nat>>:
  match rs:
    case []: []
    case +r <> t: ring_ids(r, b, n) <> ids_of(t, Nat.add(b, List.length(&2, V.Point, r)), n)

def band(as: List<&2, Nat>, +bs: List<&2, Nat>, +a0: Nat, +b0: Nat) -> List<&2, Tri>:
  match as:
    case []: []
    case +a <> +at:
      +a2 = Bool.pick(Nat, Nat.is_eq(List.length(&2, Nat, at), 0n), a0, n_hd(at))
      +b = n_hd(bs)
      +b2 = Bool.pick(Nat, Nat.is_le(List.length(&2, Nat, bs), 1n), b0, n_hd(n_drop(bs, 1n)))
      +t1 = Bool.pick(List<&2, Tri>, Nat.is_eq(a, a2), [], [Tri{a, a2, b}])
      +t2 = Bool.pick(List<&2, Tri>, Nat.is_eq(b, b2), [], [Tri{a2, b2, b}])
      List.append(&2, Tri, t1, List.append(&2, Tri, t2, band(at, n_drop(bs, 1n), a0, b0)))

def nl_hd(xs: List<&2, List<&2, Nat>>) -> List<&2, Nat>:
  match xs:
    case []: []
    case x <> t: x

def bands(rs: List<&2, List<&2, Nat>>, +first: List<&2, Nat>) -> List<&2, Tri>:
  match rs:
    case []: []
    case +r <> +t:
      +nx = Bool.pick(List<&2, Nat>, Nat.is_eq(List.length(&2, List<&2, Nat>, t), 0n), first, nl_hd(t))
      +ax = Bool.and(Nat.is_eq(n_hd(r), n_hd(n_drop(r, 1n))), Nat.is_eq(n_hd(nx), n_hd(n_drop(nx, 1n))))
      List.append(&2, Tri, Bool.pick(List<&2, Tri>, ax, [], band(r, nx, n_hd(r), n_hd(nx))), bands(t, first))

def lath_rmax(qs: List<&2, V.Vec2>) -> F64:
  match qs:
    case []: 0.0f64
    case v <> t: F64.max(F64.abs(V.v2_x(v)), lath_rmax(t))

def lath_lp(+pcs: List<&2, V.Vec2>, +n: Nat, +b: Nat) -> List<&2, Tri>:
  +rs = lath_rings(pcs, n)
  +ids = ids_of(rs, b, n)
  bands(ids, nl_hd(ids))

def lath_pts(+pcs: List<&2, V.Vec2>, +n: Nat) -> List<&2, V.Point>:
  cat_pts(lath_rings(pcs, n))

def lath_est(+pcs: List<&2, V.Vec2>, +n: Nat) -> Nat:
  Nat.mul(Nat.mul(2n, n), List.length(&2, V.Vec2, pcs))

def lath_chord(+pcs: List<&2, V.Vec2>, +n: Nat) -> F64:
  F64.div(F64.mul(4.934802200544679f64, lath_rmax(pcs)), F64.mul(nf(n), nf(n)))

def lath_ang(+n: Nat) -> F64:
  F64.div(6.283185307179586f64, nf(n))

def la_add(a: LA, +l: F.Lp, +q: M10.Q) -> LA:
  LA{+b, +ps, +ts} = a
  +pcs = lath_pcs(F.lp_pcs(l), q)
  +n = rings_max(pcs, q)
  +p = lath_pts(pcs, n)
  LA{Nat.add(b, List.length(&2, V.Point, p)), List.append(&2, V.Point, ps, p),
    List.append(&2, Tri, ts, lath_lp(pcs, n, b))}

def lath_go(ls: List<&2, F.Lp>, +a: LA, +q: M10.Q) -> LA:
  match ls:
    case []: a
    case l <> t: lath_go(t, la_add(a, l, q), q)

def la_obj(a: LA, +pl: M.Pl) -> String:
  LA{b, ps, ts} = a
  obj_vs(ps, pl) ++ obj_fs(ts)

def rev_est_go(ls: List<&2, F.Lp>, +q: M10.Q) -> Nat:
  match ls:
    case []: 0n
    case l <> t:
      +pcs = lath_pcs(F.lp_pcs(l), q)
      M10.tri_est_add(lath_est(pcs, rings_max(pcs, q)), rev_est_go(t, q))

def rev_mq_go(ls: List<&2, F.Lp>, +q: M10.Q) -> MQ:
  match ls:
    case []: MQ{0.0f64, 0.0f64, 0n}
    case l <> t:
      +pcs = lath_pcs(F.lp_pcs(l), q)
      +n = rings_max(pcs, q)
      mq_max(MQ{lath_chord(pcs, n), lath_ang(n), n}, rev_mq_go(t, q))

def la_ps(+a: LA) -> List<&2, V.Point>:
  LA{b, ps, ts} = a
  ps

def la_ts(+a: LA) -> List<&2, Tri>:
  LA{b, ps, ts} = a
  ts

def rev_emit2(+a: LA, +b: M.Body, +q: M10.Q, +est: Nat) -> M10.Tres:
  +mq = rev_mq_go(M.bd_rv(b), q)
  M10.tres_ok(la_obj(a, M.bd_pl(b)), List.length(&2, V.Point, la_ps(a)), List.length(&2, Tri, la_ts(a)), est,
    mq_chord(mq), mq_ang(mq), mq_n(mq))

def rev_emit(+b: M.Body, +q: M10.Q, +est: Nat) -> M10.Tres:
  rev_emit2(lath_go(M.bd_rv(b), LA{0n, [], []}, q), b, q, est)

def rev_go(+ok: Bool, +b: M.Body, +q: M10.Q, +est: Nat) -> M10.Tres:
  match ok:
    case False{}: M10.tres_fail_est("tess-budget-exceeded", est)
    case True{}: rev_emit(b, q, est)

def rev_q(+b: M.Body, +q: M10.Q) -> M10.Tres:
  +est = rev_est_go(M.bd_rv(b), q)
  rev_go(M10.budget_ok(est, M10.q_max(q)), b, q, est)

def body_go(+norev: Bool, +b: M.Body, +q: M10.Q) -> M10.Tres:
  match norev:
    case False{}: rev_q(b, q)
    case True{}: pri_q(b, q)

def body_q(+b: M.Body, +q: M10.Q) -> M10.Tres:
  body_go(Nat.is_eq(List.length(&2, F.Lp, M.bd_rv(b)), 0n), b, q)
