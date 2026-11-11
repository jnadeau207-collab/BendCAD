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
  LA{ b: Nat, ps: List<&2, V.Point>, ts: List<&2, Tri>, s: String, np: Nat }














type MQ is Data:
  MQ{ chord: F64, ang: F64, n: Nat }














type VX is Data:
  VX{ u: F64, v: F64, p: V.Point }














type TGO is Data:
  TGO{ ts: List<&2, Tri>, ps: List<&2, V.Point>, ok: Bool }

type FG is Data:
  FG{ g: TGO, ns: List<&2, Nat>, ks: List<&2, String> }

type NF is Data:
  NF{ hdr: String, n: Nat, ns: List<&2, Nat>, ks: List<&2, String>, fi: Nat }














type ER2 is Data:
  ER2{ k: U64, t: Nat, a: Nat, b: Nat }




























type CM4 is Data:
  CM4{ su: F64, cu: F64, sv: F64, cv: F64 }














type GS is Data:
  GS{ sf: KS.SF, ur: F64, vr: F64, pu: Bool, pv: Bool }
  GS_st{ sf: KS.SF, c: V.Dir, e1: V.Dir, e2: V.Dir }














type TL is Data:
  TL{ ch: F64, ca: F64 }

type FL is Data:
  FL{ te: Nat, tf: Nat, a: Nat, b: Nat, c: Nat, d: Nat }

type RF is Data:
  RF{ ts: List<&2, Tri>, vt: B.Tb<&2, VX>, nv: Nat }

def nf(+n: Nat) -> F64:
  U64.to_f64(U64.from_nat(n))

def dm_at(+lo: F64, +hi: F64, +f: F64) -> F64:
  F64.add(lo, F64.mul(F64.sub(hi, lo), f))

def rq_pts(+w: G.RQBez, +j: Nat, +k: Nat, +lo: F64, +hi: F64, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match j:
    case 0n: acc
    case 1n+i: rq_pts(w, i, k, lo, hi, G.gres_p(GO.rqb_eval(w, dm_at(lo, hi, F64.div(nf(j), nf(Nat.add(k, 1n)))))) <> acc)

def cc_pts(+w: G.Circle3, +j: Nat, +n: Nat, +lo: F64, +hi: F64, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match j:
    case 0n: acc
    case 1n+i: cc_pts(w, i, n, lo, hi, G.gres_p(GO.circ_eval(w, M10.cc_par(lo, hi, F64.div(nf(j), nf(n))))) <> acc)

def bz_pts(+w: G.Bez3, +j: Nat, +k: Nat, +lo: F64, +hi: F64, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match j:
    case 0n: acc
    case 1n+i: bz_pts(w, i, k, lo, hi, G.gres_p(GO.bez3_eval(w, dm_at(lo, hi, F64.div(nf(j), nf(Nat.add(k, 1n)))))) <> acc)

def rq_go(+w: G.RQBez, +d: G.Dom, +q: M10.Q) -> List<&2, V.Point>:
  G.Dom{+lo, +hi} = d
  +s = M10.segs_edge(G.GV_rq{w}, G.Dom{lo, hi}, q)
  +m = Nat.sub(s, 1n)
  rq_pts(w, m, m, lo, hi, [])

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

def bz_pick(+line: Bool, +w: G.Bez3, +m: Nat, +lo: F64, +hi: F64) -> List<&2, V.Point>:
  match line:
    case True{}: []
    case False{}: bz_pts(w, m, m, lo, hi, [])

def bz_go(+w: G.Bez3, +d: G.Dom, +q: M10.Q) -> List<&2, V.Point>:
  G.Dom{+lo, +hi} = d
  +s = M10.segs_edge(G.GV_bz{w}, G.Dom{lo, hi}, q)
  bz_pick(bz_line(w), w, Nat.sub(s, 1n), lo, hi)

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

def meas_bz_go(+line: Bool, +w: G.Bez3, +ps: List<&2, V.Point>, +s: Nat, +lo: F64, +hi: F64) -> MQ:
  match line:
    case True{}: MQ{0.0f64, 0.0f64, 1n}
    case False{}: MQ{segs_go(G.GV_bz{w}, ps, lo, hi, s, 0.0f64), 0.0f64, s}

def meas_bz(+w: G.Bez3, +ps: List<&2, V.Point>, +s: Nat, +lo: F64, +hi: F64) -> MQ:
  meas_bz_go(bz_line(w), w, ps, s, lo, hi)

def meas_rq(+w: G.RQBez, +d: G.Dom, +ps: List<&2, V.Point>, +s: Nat) -> MQ:
  G.Dom{+lo, +hi} = d
  MQ{segs_go(G.GV_rq{w}, ps, lo, hi, s, 0.0f64), F64.div(F64.mul(M10.rq_turn(w), F64.abs(F64.sub(hi, lo))), nf(s)), s}

def meas_bzd(+w: G.Bez3, +d: G.Dom, +ps: List<&2, V.Point>, +s: Nat) -> MQ:
  G.Dom{+lo, +hi} = d
  meas_bz(w, ps, s, lo, hi)

def meas_curve(+c: G.GVal, +d: G.Dom, +ps: List<&2, V.Point>, +s: Nat) -> MQ:
  match c:
    case G.GV_ln{l}: MQ{0.0f64, 0.0f64, 1n}
    case G.GV_rq{+w}: meas_rq(w, d, ps, s)
    case G.GV_cc{+w}: meas_cc(w, d, ps, s)
    case G.GV_bz{+w}: meas_bzd(w, d, ps, s)
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

def tri_s(+t: Tri) -> String:
  Tri{a, b, c} = t
  "f " ++ Nat.show(Nat.add(a, 1n)) ++ " " ++ Nat.show(Nat.add(b, 1n)) ++ " " ++ Nat.show(Nat.add(c, 1n)) ++ "\n"

def obj_fs(ts: List<&2, Tri>) -> String:
  match ts:
    case []: ""
    case +t <> r: tri_s(t) ++ obj_fs(r)

def s_hd(xs: List<&2, String>) -> String:
  match xs:
    case []: "other"
    case +x <> t: x

def s_tl(xs: List<&2, String>) -> List<&2, String>:
  match xs:
    case []: []
    case x <> +t: t

def nx_face(ns: List<&2, Nat>, +ks: List<&2, String>, +fi: Nat, +m: Nat) -> NF:
  match ns:
    case []: NF{"", m, [], [], fi}
    case +n <> u: NF{"g f" ++ Nat.show(fi) ++ " " ++ s_hd(ks) ++ "\n", n, u, s_tl(ks), Nat.add(fi, 1n)}

def nf_hdr(+x: NF) -> String:
  NF{+h, n, ns, ks, fi} = x
  h

def nf_n(+x: NF) -> Nat:
  NF{h, +n, ns, ks, fi} = x
  n

def nf_ns(+x: NF) -> List<&2, Nat>:
  NF{h, n, +ns, ks, fi} = x
  ns

def nf_ks(+x: NF) -> List<&2, String>:
  NF{h, n, ns, +ks, fi} = x
  ks

def nf_fi(+x: NF) -> Nat:
  NF{h, n, ns, ks, +fi} = x
  fi

def obj_fg(fuel: Nat, ts: List<&2, Tri>, +ns: List<&2, Nat>, +ks: List<&2, String>, +k: Nat, +fi: Nat) -> String:
  match fuel:
    case 0n: ""
    case 1n+f:
      match ts:
        case []: ""
        case +t <> +r:
          match k:
            case 0n:
              +x = nx_face(ns, ks, fi, Nat.add(List.length(&2, Tri, r), 1n))
              nf_hdr(x) ++ obj_fg(f, t <> r, nf_ns(x), nf_ks(x), nf_n(x), nf_fi(x))
            case 1n+j: tri_s(t) ++ obj_fg(f, r, ns, ks, j, fi)

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
    case False{}:
      M10.Tres{+k, +w, +obj, +nv, +nt, +est, +chord, +ang, +nsamp} = r
      M10.Tres{False{}, "tess-mesh-not-closed", obj, nv, nt, est, chord, ang, nsamp}

def use_gen(f: Ty.Face, +x: Ctx) -> Bool:
  Ty.Fa{g, +s, +ls, same, slv, sla} = f
  +k = KS.sf_kind(KS.sf_of(s))
  Bool.or(U64.is_le(k, 6u64), Bool.not(Nat.is_eq(List.length(&2, Ty.HLoop, ls), 0n)))

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

def gs_pu(+g: GS) -> Bool:
  match g:
    case GS{sf, ur, vr, +pu, pv}: pu
    case GS_st{sf, c, e1, e2}: False{}

def gs_pv(+g: GS) -> Bool:
  match g:
    case GS{sf, ur, vr, pu, +pv}: pv
    case GS_st{sf, c, e1, e2}: False{}

def gs_of(+sf: KS.SF, +rs: List<&2, List<&2, TP>>) -> GS:
  gs_mk(sf, cm_rings(rs, sf, CM4{0.0f64, 0.0f64, 0.0f64, 0.0f64}))

def gs_sf(+g: GS) -> KS.SF:
  match g:
    case GS{+sf, ur, vr, pu, pv}: sf
    case GS_st{+sf, c, e1, e2}: sf

def st_uv(+sf: KS.SF, +c: V.Dir, +e1: V.Dir, +e2: V.Dir, +p: V.Point) -> V.Vec2:
  +d = KS.dscale(F64.div(1.0f64, KS.sf_r(sf)), KS.psub(p, KS.sf_o(sf)))
  +k = F64.add(1.0f64, KS.dot(d, c))
  V.V2{F64.div(KS.dot(d, e1), k), F64.div(KS.dot(d, e2), k)}

def st_at(+sf: KS.SF, +c: V.Dir, +e1: V.Dir, +e2: V.Dir, +x: F64, +y: F64) -> V.Point:
  +q = F64.add(F64.mul(x, x), F64.mul(y, y))
  +r = F64.div(KS.sf_r(sf), F64.add(1.0f64, q))
  KS.padd(KS.padd(KS.padd(KS.sf_o(sf), F64.mul(r, F64.sub(1.0f64, q)), c), F64.mul(r, F64.mul(2.0f64, x)), e1), F64.mul(r, F64.mul(2.0f64, y)), e2)

def g_uvw(+g: GS, +p: V.Point) -> V.Vec2:
  match g:
    case GS{+sf, +ur, +vr, +pu, +pv}:
      +w = KS.sf_uv(sf, p)
      V.V2{Bool.pick(F64, pu, KS.ang_diff(ur, V.v2_x(w)), V.v2_x(w)), Bool.pick(F64, pv, KS.ang_diff(vr, V.v2_y(w)), V.v2_y(w))}
    case GS_st{+sf, +c, +e1, +e2}: st_uv(sf, c, e1, e2, p)

def g_uv(+g: GS, +p: V.Point) -> V.Vec2:
  g_uvw(g, p)

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
  match g:
    case GS{+sf, +ur, +vr, +pu, +pv}: KS.sf_at(sf, Bool.pick(F64, pu, F64.add(u, ur), u), Bool.pick(F64, pv, F64.add(v, vr), v))
    case GS_st{+sf, +c, +e1, +e2}: st_at(sf, c, e1, e2, u, v)

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

def sf_nrm(+sf: KS.SF, +w: VX) -> V.Dir:
  match sf:
    case KS.SF_bp{gw}: KS.bp_nrm(KS.gbp(gw), vx_u(w), vx_v(w))
    case _: KS.sf_normal(sf, vx_p(w))

def e_bad(+g: GS, +va: VX, +vb: VX, +tol: TL) -> Bool:
  TL{+ch, +ca} = tol
  +sf = gs_sf(g)
  Bool.or(F64.is_lt(ch, e_dev(g, va, vb)), F64.is_lt(KS.dot(sf_nrm(sf, va), sf_nrm(sf, vb)), ca))

def vxl(+vt: B.Tb<&2, VX>, +a: Nat, +b: Nat) -> F64:
  p_dist(vx_p(B.tb_get(VX, vt, U32.from_nat(a))), vx_p(B.tb_get(VX, vt, U32.from_nat(b))))

def vx_mid(+g: GS, +va: VX, +vb: VX) -> VX:
  +um = F64.mul(0.5f64, F64.add(vx_u(va), vx_u(vb)))
  +wm = F64.mul(0.5f64, F64.add(vx_v(va), vx_v(vb)))
  VX{um, wm, g_at(g, um, wm)}

def k_cmp(+x: U64, +y: U64) -> B.Sgn:
  B.sgn_pick(U64.is_lt(x, y), U64.is_lt(y, x))

def er_cmp(a: ER2, b: ER2) -> B.Sgn:
  k_cmp(er_k(a), er_k(b))

def rep_bl(n: Nat) -> List<&2, Bool>:
  match n:
    case 0n: []
    case 1n+m: False{} <> rep_bl(m)

def rep_nn(n: Nat, +x: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: x <> rep_nn(m, x)

def ed_a(+t: Tri, +l: Nat) -> Nat:
  Tri{+a, +b, +c} = t
  Bool.pick(Nat, Nat.is_eq(l, 0n), a, Bool.pick(Nat, Nat.is_eq(l, 1n), b, c))

def ed_b(+t: Tri, +l: Nat) -> Nat:
  Tri{+a, +b, +c} = t
  Bool.pick(Nat, Nat.is_eq(l, 0n), b, Bool.pick(Nat, Nat.is_eq(l, 1n), c, a))

def l_nx(+l: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_eq(l, 2n), 0n, Nat.add(l, 1n))

def loc(+t: Tri, +x: Nat) -> Nat:
  Tri{+a, +b, c} = t
  Bool.pick(Nat, Nat.is_eq(x, a), 0n, Bool.pick(Nat, Nat.is_eq(x, b), 1n, 2n))

def ent(+tt: B.Tb<&2, Tri>, +e: ER2) -> Nat:
  Nat.add(Nat.mul(3n, er_t(e)), loc(B.tb_get(Tri, tt, U32.from_nat(er_t(e))), er_a(e)))

def tw_go(n: Nat, es: List<&2, ER2>, +tt: B.Tb<&2, Tri>, +tw: B.Tb<&2, Nat>) -> B.Tb<&2, Nat>:
  match n:
    case 0n: tw
    case 1n+(+m):
      match es:
        case []: tw
        case +e <> +t:
          match t:
            case []: tw
            case +f <> +t2:
              +pair = U64.is_eq(er_k(e), er_k(f))
              +ie = ent(tt, e)
              +jf = ent(tt, f)
              tw_go(m, Bool.pick(List<&2, ER2>, pair, t2, f <> t2), tt,
                Bool.pick(B.Tb<&2, Nat>, pair, B.tb_set(Nat, B.tb_set(Nat, tw, U32.from_nat(ie), jf), U32.from_nat(jf), ie), tw))

def mk_l(+t: Tri, +i: Nat, +l: Nat, +g: GS, +vt: B.Tb<&2, VX>, +tw: B.Tb<&2, Nat>, +sent: Nat, +tol: TL, +fat: B.Tb<&2, Bool>, +mk: B.Tb<&2, Bool>) -> B.Tb<&2, Bool>:
  +e = Nat.add(Nat.mul(3n, i), l)
  +o = B.tb_get(Nat, tw, U32.from_nat(e))
  +both = Bool.and(B.tb_get(Bool, fat, U32.from_nat(i)), B.tb_get(Bool, fat, U32.from_nat(Nat.div(o, 3n))))
  +hit = Bool.and(Bool.and(Nat.is_lt(o, sent), both), e_bad(g, B.tb_get(VX, vt, U32.from_nat(ed_a(t, l))), B.tb_get(VX, vt, U32.from_nat(ed_b(t, l))), tol))
  Bool.pick(B.Tb<&2, Bool>, hit, B.tb_set(Bool, B.tb_set(Bool, mk, U32.from_nat(e), True{}), U32.from_nat(o), True{}), mk)

def p3(+vt: B.Tb<&2, VX>, +i: Nat) -> V.Point:
  vx_p(B.tb_get(VX, vt, U32.from_nat(i)))

def t_fat(+t: Tri, +vt: B.Tb<&2, VX>) -> Bool:
  Tri{+a, +b, +c} = t
  +u = KS.psub(p3(vt, b), p3(vt, a))
  +v = KS.psub(p3(vt, c), p3(vt, a))
  +w = KS.psub(p3(vt, c), p3(vt, b))
  +l2 = F64.max(KS.dot(u, u), F64.max(KS.dot(v, v), KS.dot(w, w)))
  F64.is_lt(F64.mul(1.0e-4f64, l2), KS.dlen(KS.cross(u, v)))

def fats(ts: List<&2, Tri>, +vt: B.Tb<&2, VX>) -> List<&2, Bool>:
  match ts:
    case []: []
    case +t <> r: t_fat(t, vt) <> fats(r, vt)

def mk_go(ts: List<&2, Tri>, +i: Nat, +g: GS, +vt: B.Tb<&2, VX>, +tw: B.Tb<&2, Nat>, +sent: Nat, +tol: TL, +fat: B.Tb<&2, Bool>, +mk: B.Tb<&2, Bool>) -> B.Tb<&2, Bool>:
  match ts:
    case []: mk
    case +t <> r: mk_go(r, Nat.add(i, 1n), g, vt, tw, sent, tol, fat, mk_l(t, i, 2n, g, vt, tw, sent, tol, fat, mk_l(t, i, 1n, g, vt, tw, sent, tol, fat, mk_l(t, i, 0n, g, vt, tw, sent, tol, fat, mk))))

def t_ll(+t: Tri, +vt: B.Tb<&2, VX>, +w0: F64, +w1: F64, +w2: F64) -> Nat:
  Bool.pick(Nat, Bool.and(F64.is_le(w1, w0), F64.is_le(w2, w0)), 0n, Bool.pick(Nat, F64.is_le(w2, w1), 1n, 2n))

def t_len(+t: Tri, +vt: B.Tb<&2, VX>, +l: Nat) -> F64:
  vxl(vt, ed_a(t, l), ed_b(t, l))

type MK is Data:
  MK{ mk: B.Tb<&2, Bool>, ch: Bool }

def cl_go(ts: List<&2, Tri>, +i: Nat, +vt: B.Tb<&2, VX>, +tw: B.Tb<&2, Nat>, +sent: Nat, +mk: B.Tb<&2, Bool>, +ch: Bool) -> MK:
  match ts:
    case []: MK{mk, ch}
    case +t <> r:
      +e0 = Nat.mul(3n, i)
      +any = Bool.or(B.tb_get(Bool, mk, U32.from_nat(e0)), Bool.or(B.tb_get(Bool, mk, U32.from_nat(Nat.add(e0, 1n))), B.tb_get(Bool, mk, U32.from_nat(Nat.add(e0, 2n)))))
      +el = Nat.add(e0, t_ll(t, vt, t_len(t, vt, 0n), t_len(t, vt, 1n), t_len(t, vt, 2n)))
      +o = B.tb_get(Nat, tw, U32.from_nat(el))
      +need = Bool.and(Bool.and(any, Bool.not(B.tb_get(Bool, mk, U32.from_nat(el)))), Nat.is_lt(o, sent))
      cl_go(r, Nat.add(i, 1n), vt, tw, sent, Bool.pick(B.Tb<&2, Bool>, need, B.tb_set(Bool, B.tb_set(Bool, mk, U32.from_nat(el), True{}), U32.from_nat(o), True{}), mk), Bool.or(ch, need))

def mk_mk(+r: MK) -> B.Tb<&2, Bool>:
  MK{+mk, ch} = r
  mk

def mk_ch(+r: MK) -> Bool:
  MK{mk, +ch} = r
  ch

def closure(n: Nat, go: Bool, +ts: List<&2, Tri>, +vt: B.Tb<&2, VX>, +tw: B.Tb<&2, Nat>, +sent: Nat, +mk: B.Tb<&2, Bool>) -> B.Tb<&2, Bool>:
  match n:
    case 0n: mk
    case 1n+(+m):
      match go:
        case False{}: mk
        case True{}:
          +r = cl_go(ts, 0n, vt, tw, sent, mk, False{})
          closure(m, mk_ch(r), ts, vt, tw, sent, mk_mk(r))

def own(+mk: B.Tb<&2, Bool>, +tw: B.Tb<&2, Nat>, +e: Nat) -> Bool:
  Bool.and(B.tb_get(Bool, mk, U32.from_nat(e)), Nat.is_lt(e, B.tb_get(Nat, tw, U32.from_nat(e))))

def cnt_go(n: Nat, +e: Nat, +mk: B.Tb<&2, Bool>, +tw: B.Tb<&2, Nat>, +acc: Nat) -> Nat:
  match n:
    case 0n: acc
    case 1n+(+m): cnt_go(m, Nat.add(e, 1n), mk, tw, Bool.pick(Nat, own(mk, tw, e), Nat.add(acc, 1n), acc))

type MD is Data:
  MD{ md: B.Tb<&2, Nat>, vt: B.Tb<&2, VX>, k: Nat }

def md_put(on: Bool, +t: Tri, +l: Nat, +e: Nat, +o: Nat, +g: GS, +r: MD) -> MD:
  match on:
    case False{}: r
    case True{}:
      MD{+md, +vt, +k} = r
      +m = vx_mid(g, B.tb_get(VX, vt, U32.from_nat(ed_a(t, l))), B.tb_get(VX, vt, U32.from_nat(ed_b(t, l))))
      MD{B.tb_set(Nat, B.tb_set(Nat, md, U32.from_nat(e), k), U32.from_nat(o), k), B.tb_set(VX, vt, U32.from_nat(k), m), Nat.add(k, 1n)}

def md_l(+t: Tri, +i: Nat, +l: Nat, +g: GS, +mk: B.Tb<&2, Bool>, +tw: B.Tb<&2, Nat>, +r: MD) -> MD:
  +e = Nat.add(Nat.mul(3n, i), l)
  md_put(own(mk, tw, e), t, l, e, B.tb_get(Nat, tw, U32.from_nat(e)), g, r)

def md_go(ts: List<&2, Tri>, +i: Nat, +g: GS, +mk: B.Tb<&2, Bool>, +tw: B.Tb<&2, Nat>, +r: MD) -> MD:
  match ts:
    case []: r
    case +t <> rest: md_go(rest, Nat.add(i, 1n), g, mk, tw, md_l(t, i, 2n, g, mk, tw, md_l(t, i, 1n, g, mk, tw, md_l(t, i, 0n, g, mk, tw, r))))

def w_of(+mk: B.Tb<&2, Bool>, +e: Nat, +t: Tri, +vt: B.Tb<&2, VX>, +l: Nat) -> F64:
  Bool.pick(F64, B.tb_get(Bool, mk, U32.from_nat(e)), t_len(t, vt, l), F64.neg(1.0f64))

def sub_half(on: Bool, +x: Nat, +y: Nat, +z: Nat, +h: Nat) -> List<&2, Tri>:
  match on:
    case False{}: [Tri{x, y, z}]
    case True{}: [Tri{x, y, h}, Tri{x, h, z}]

def sub_any(on: Bool, +t: Tri, +e0: Nat, +mk: B.Tb<&2, Bool>, +md: B.Tb<&2, Nat>, +vt: B.Tb<&2, VX>) -> List<&2, Tri>:
  match on:
    case False{}: [t]
    case True{}:
      +l = t_ll(t, vt, w_of(mk, e0, t, vt, 0n), w_of(mk, Nat.add(e0, 1n), t, vt, 1n), w_of(mk, Nat.add(e0, 2n), t, vt, 2n))
      +lq = l_nx(l)
      +lr = l_nx(lq)
      +p = ed_a(t, l)
      +q = ed_b(t, l)
      +rr = ed_b(t, lq)
      +m = B.tb_get(Nat, md, U32.from_nat(Nat.add(e0, l)))
      List.append(&2, Tri, sub_half(B.tb_get(Bool, mk, U32.from_nat(Nat.add(e0, lr))), m, rr, p, B.tb_get(Nat, md, U32.from_nat(Nat.add(e0, lr)))),
        sub_half(B.tb_get(Bool, mk, U32.from_nat(Nat.add(e0, lq))), m, q, rr, B.tb_get(Nat, md, U32.from_nat(Nat.add(e0, lq)))))

def sub_tri(+t: Tri, +i: Nat, +mk: B.Tb<&2, Bool>, +md: B.Tb<&2, Nat>, +vt: B.Tb<&2, VX>) -> List<&2, Tri>:
  +e0 = Nat.mul(3n, i)
  sub_any(Bool.or(B.tb_get(Bool, mk, U32.from_nat(e0)), Bool.or(B.tb_get(Bool, mk, U32.from_nat(Nat.add(e0, 1n))), B.tb_get(Bool, mk, U32.from_nat(Nat.add(e0, 2n))))), t, e0, mk, md, vt)

def sub_go(ts: List<&2, Tri>, +i: Nat, +mk: B.Tb<&2, Bool>, +md: B.Tb<&2, Nat>, +vt: B.Tb<&2, VX>) -> List<&2, Tri>:
  match ts:
    case []: []
    case +t <> r: List.append(&2, Tri, sub_tri(t, i, mk, md, vt), sub_go(r, Nat.add(i, 1n), mk, md, vt))

def uvo(+vt: B.Tb<&2, VX>, +a: Nat, +b: Nat, +c: Nat) -> F64:
  +pa = B.tb_get(VX, vt, U32.from_nat(a))
  +pb = B.tb_get(VX, vt, U32.from_nat(b))
  +pc = B.tb_get(VX, vt, U32.from_nat(c))
  F64.sub(F64.mul(F64.sub(vx_u(pb), vx_u(pa)), F64.sub(vx_v(pc), vx_v(pa))), F64.mul(F64.sub(vx_v(pb), vx_v(pa)), F64.sub(vx_u(pc), vx_u(pa))))

def opq(+vt: B.Tb<&2, VX>, +a: Nat, +b: Nat, +c: Nat) -> F64:
  +u = KS.psub(p3(vt, a), p3(vt, c))
  +v = KS.psub(p3(vt, b), p3(vt, c))
  F64.div(KS.dot(u, v), F64.max(KS.dlen(KS.cross(u, v)), 1.0e-300f64))

def opp(+t: Tri, +a: Nat) -> Nat:
  ed_b(t, l_nx(loc(t, a)))

def uvl2(+vt: B.Tb<&2, VX>, +a: Nat, +b: Nat) -> F64:
  +pa = B.tb_get(VX, vt, U32.from_nat(a))
  +pb = B.tb_get(VX, vt, U32.from_nat(b))
  +du = F64.sub(vx_u(pb), vx_u(pa))
  +dv = F64.sub(vx_v(pb), vx_v(pa))
  F64.add(F64.mul(du, du), F64.mul(dv, dv))

def uv_fat(+vt: B.Tb<&2, VX>, +s: F64, +a: Nat, +b: Nat, +c: Nat) -> Bool:
  F64.is_lt(F64.mul(1.0e-9f64, F64.max(uvl2(vt, a, b), F64.max(uvl2(vt, b, c), uvl2(vt, c, a)))), F64.mul(s, uvo(vt, a, b, c)))

def fl_ok(+vt: B.Tb<&2, VX>, +a: Nat, +b: Nat, +c: Nat, +d: Nat) -> Bool:
  +o = uvo(vt, a, b, c)
  +s = Bool.pick(F64, F64.is_lt(0.0f64, o), 1.0f64, F64.neg(1.0f64))
  Bool.and(Bool.and(uv_fat(vt, s, a, d, c), uv_fat(vt, s, d, b, c)),
    F64.is_lt(F64.add(opq(vt, a, b, c), opq(vt, a, b, d)), F64.neg(1.0e-9f64)))

def fl_go(n: Nat, es: List<&2, ER2>, +tt: B.Tb<&2, Tri>, +vt: B.Tb<&2, VX>, +used: B.Tb<&2, Bool>, +acc: List<&2, FL>) -> List<&2, FL>:
  match n:
    case 0n: acc
    case 1n+(+m):
      match es:
        case []: acc
        case +e <> +t:
          match t:
            case []: acc
            case +f <> +t2:
              +pair = U64.is_eq(er_k(e), er_k(f))
              +te = er_t(e)
              +tf = er_t(f)
              +a = er_a(e)
              +b = er_b(e)
              +c = opp(B.tb_get(Tri, tt, U32.from_nat(te)), a)
              +d = opp(B.tb_get(Tri, tt, U32.from_nat(tf)), b)
              +ok = Bool.and(Bool.and(pair, Bool.not(Bool.or(B.tb_get(Bool, used, U32.from_nat(te)), B.tb_get(Bool, used, U32.from_nat(tf))))), fl_ok(vt, a, b, c, d))
              fl_go(m, Bool.pick(List<&2, ER2>, pair, t2, f <> t2), tt, vt,
                Bool.pick(B.Tb<&2, Bool>, ok, B.tb_set(Bool, B.tb_set(Bool, used, U32.from_nat(te), True{}), U32.from_nat(tf), True{}), used),
                Bool.pick(List<&2, FL>, ok, FL{te, tf, a, b, c, d} <> acc, acc))

def fl_apply(fs: List<&2, FL>, +tt: B.Tb<&2, Tri>) -> B.Tb<&2, Tri>:
  match fs:
    case []: tt
    case +x <> r:
      FL{+te, +tf, +a, +b, +c, +d} = x
      fl_apply(r, B.tb_set(Tri, B.tb_set(Tri, tt, U32.from_nat(te), Tri{a, d, c}), U32.from_nat(tf), Tri{d, b, c}))

def tb_tris(n: Nat, +tt: B.Tb<&2, Tri>, +i: Nat) -> List<&2, Tri>:
  match n:
    case 0n: []
    case 1n+(+m): B.tb_get(Tri, tt, U32.from_nat(i)) <> tb_tris(m, tt, Nat.add(i, 1n))

def flips(n: Nat, go: Bool, +ts: List<&2, Tri>, +vt: B.Tb<&2, VX>) -> List<&2, Tri>:
  match n:
    case 0n: ts
    case 1n+(+m):
      match go:
        case False{}: ts
        case True{}:
          +nt = List.length(&2, Tri, ts)
          +tt = B.tb_of(Tri, ts, Tri{0n, 0n, 0n})
          +fs = fl_go(Nat.mul(3n, nt), so_er(B.msort(~ER2, ~er_cmp, tri_ers(ts, 0n))), tt, vt, B.tb_of(Bool, rep_bl(nt), False{}), [])
          flips(m, Bool.not(Nat.is_eq(List.length(&2, FL, fs), 0n)), tb_tris(nt, fl_apply(fs, tt), 0n), vt)

def rf_sub(+ts: List<&2, Tri>, +mk: B.Tb<&2, Bool>, +d: MD, +vt0: B.Tb<&2, VX>) -> RF:
  MD{+md, +vt, +nv} = d
  RF{sub_go(ts, 0n, mk, md, vt0), vt, nv}

def rf_step(go: Bool, +r: RF, +g: GS, +mk: B.Tb<&2, Bool>, +tw: B.Tb<&2, Nat>, +ne: Nat) -> RF:
  match go:
    case False{}: r
    case True{}:
      RF{+ts, +vt, +nv} = r
      rf_sub(ts, mk, md_go(ts, 0n, g, mk, tw, MD{B.tb_of(Nat, rep_nn(ne, 0n), 0n), vt, nv}), vt)

def ref_go(n: Nat, done: Bool, +r: RF, +g: GS, +nx: B.Tb<&2, Nat>, +nb: Nat, +cap: Nat, +tol: TL) -> RF:
  match n:
    case 0n: r
    case 1n+(+m):
      match done:
        case True{}: r
        case False{}:
          RF{+ts0, +vt, +nv} = r
          +ts = flips(3n, True{}, ts0, vt)
          +nt = List.length(&2, Tri, ts)
          +ne = Nat.mul(3n, nt)
          +es = so_er(B.msort(~ER2, ~er_cmp, tri_ers(ts, 0n)))
          +tt = B.tb_of(Tri, ts, Tri{0n, 0n, 0n})
          +tw = tw_go(ne, es, tt, B.tb_of(Nat, rep_nn(ne, ne), ne))
          +mk0 = mk_go(ts, 0n, g, vt, tw, ne, tol, B.tb_of(Bool, List.append(&2, Bool, fats(ts, vt), [False{}]), False{}), B.tb_of(Bool, rep_bl(ne), False{}))
          +mk = closure(64n, True{}, ts, vt, tw, ne, mk0)
          +k = cnt_go(ne, 0n, mk, tw, 0n)
          +fits = Nat.is_le(Nat.add(nv, k), cap)
          +go = Bool.and(Nat.is_lt(0n, k), fits)
          ref_go(m, Bool.not(go), rf_step(go, RF{ts, vt, nv}, g, mk, tw, ne), g, nx, nb, cap, tol)

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

def nx_is(+x: Nat, +y: Nat, +nx: B.Tb<&2, Nat>, +nb: Nat) -> Nat:
  Bool.pick(Nat, Bool.and(Bool.and(Nat.is_lt(x, nb), Nat.is_lt(y, nb)), Nat.is_eq(B.tb_get(Nat, nx, U32.from_nat(x)), y)), 1n, 0n)

def t_fw(+t: Tri, +nx: B.Tb<&2, Nat>, +nb: Nat) -> Nat:
  Tri{+a, +b, +c} = t
  Nat.add(nx_is(a, b, nx, nb), Nat.add(nx_is(b, c, nx, nb), nx_is(c, a, nx, nb)))

def t_bw(+t: Tri, +nx: B.Tb<&2, Nat>, +nb: Nat) -> Nat:
  Tri{+a, +b, +c} = t
  Nat.add(nx_is(b, a, nx, nb), Nat.add(nx_is(c, b, nx, nb), nx_is(a, c, nx, nb)))

def ts_fw(ts: List<&2, Tri>, +nx: B.Tb<&2, Nat>, +nb: Nat, +acc: Nat) -> Nat:
  match ts:
    case []: acc
    case +t <> r: ts_fw(r, nx, nb, Nat.add(acc, t_fw(t, nx, nb)))

def ts_bw(ts: List<&2, Tri>, +nx: B.Tb<&2, Nat>, +nb: Nat, +acc: Nat) -> Nat:
  match ts:
    case []: acc
    case +t <> r: ts_bw(r, nx, nb, Nat.add(acc, t_bw(t, nx, nb)))

def gen_fin(+r: RF, +sf: KS.SF, +same: Bool, +gid: B.Tb<&2, Nat>, +nb: Nat, +base: Nat, +ok: Bool, +nx: B.Tb<&2, Nat>) -> TGO:
  RF{+ts, +vt, +nv} = r
  +fw = ts_fw(ts, nx, nb, 0n)
  +bw = ts_bw(ts, nx, nb, 0n)
  +d = ts_dot(ts, vt, sf, 0.0f64)
  +rev = Bool.pick(Bool, Nat.is_eq(fw, bw), F64.is_lt(Bool.pick(F64, same, d, F64.neg(d)), 0.0f64), Nat.is_lt(fw, bw))
  TGO{g_out(ts, rev, gid, nb, base), g_newps(Nat.sub(nv, nb), vt, nb), ok}

def uw_next(+g: GS, +prev: V.Vec2, +w: V.Vec2) -> V.Vec2:
  +pu = gs_pu(g)
  +pv = gs_pv(g)
  V.V2{Bool.pick(F64, pu, F64.add(V.v2_x(prev), KS.ang_diff(V.v2_x(prev), V.v2_x(w))), V.v2_x(w)),
    Bool.pick(F64, pv, F64.add(V.v2_y(prev), KS.ang_diff(V.v2_y(prev), V.v2_y(w))), V.v2_y(w))}

def uw_q(r: List<&2, TP>, +g: GS, +prev: V.Vec2, +i: Nat) -> List<&2, QP>:
  match r:
    case []: []
    case +h <> t:
      +w = uw_next(g, prev, g_uv(g, tp_p(h)))
      QP{i, V.v2_x(w), V.v2_y(w)} <> uw_q(t, g, w, Nat.add(i, 1n))

def uw_v(r: List<&2, TP>, +g: GS, +prev: V.Vec2) -> List<&2, VX>:
  match r:
    case []: []
    case +h <> t:
      +w = uw_next(g, prev, g_uv(g, tp_p(h)))
      VX{V.v2_x(w), V.v2_y(w), tp_p(h)} <> uw_v(t, g, w)

def tp0(r: List<&2, TP>) -> TP:
  match r:
    case []: TP{0n, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case +h <> t: h

def r_mu(r: List<&2, TP>, +g: GS, +prev: V.Vec2, +n: F64, +acc: F64) -> F64:
  match r:
    case []: F64.div(acc, F64.max(n, 1.0f64))
    case +h <> t:
      +w = uw_next(g, prev, g_uv(g, tp_p(h)))
      r_mu(t, g, w, F64.add(n, 1.0f64), F64.add(acc, V.v2_x(w)))


def r_w0(+r: List<&2, TP>, +g: GS, +ref: F64, +first: Bool) -> V.Vec2:
  +w = g_uv(g, tp_p(tp0(r)))
  +m = r_mu(r, g, w, 0.0f64, 0.0f64)
  +sh = F64.sub(F64.sub(ref, m), KS.ang_diff(m, ref))
  Bool.pick(V.Vec2, Bool.or(first, Bool.not(gs_pu(g))), w, V.V2{F64.add(V.v2_x(w), sh), V.v2_y(w)})

def uw_qs(rs: List<&2, List<&2, TP>>, +g: GS, +i: Nat, +ref: F64, +first: Bool) -> List<&2, List<&2, QP>>:
  match rs:
    case []: []
    case +r <> t:
      +w0 = r_w0(r, g, ref, first)
      +ref2 = Bool.pick(F64, first, r_mu(r, g, w0, 0.0f64, 0.0f64), ref)
      uw_q(r, g, w0, i) <> uw_qs(t, g, Nat.add(i, List.length(&2, TP, r)), ref2, False{})

def uw_vs(rs: List<&2, List<&2, TP>>, +g: GS, +ref: F64, +first: Bool) -> List<&2, VX>:
  match rs:
    case []: []
    case +r <> t:
      +w0 = r_w0(r, g, ref, first)
      +ref2 = Bool.pick(F64, first, r_mu(r, g, w0, 0.0f64, 0.0f64), ref)
      List.append(&2, VX, uw_v(r, g, w0), uw_vs(t, g, ref2, False{}))

def uw_end(r: List<&2, TP>, +g: GS, +prev: V.Vec2) -> V.Vec2:
  match r:
    case []: prev
    case +h <> t: uw_end(t, g, uw_next(g, prev, g_uv(g, tp_p(h))))

def r_wrap(+r: List<&2, TP>, +g: GS) -> F64:
  +w0 = g_uv(g, tp_p(tp0(r)))
  +we = uw_next(g, uw_end(r, g, w0), w0)
  F64.sub(V.v2_x(we), V.v2_x(w0))

def rs_at(rs: List<&2, List<&2, TP>>, +i: Nat) -> List<&2, TP>:
  match rs:
    case []: []
    case +h <> t:
      match i:
        case 0n: h
        case 1n+(+j): rs_at(t, j)

def band_of(+g: GS, +rs: List<&2, List<&2, TP>>) -> Bool:
  +pu = gs_pu(g)
  +a = r_wrap(rs_at(rs, 0n), g)
  +b = r_wrap(rs_at(rs, 1n), g)
  Bool.and(Bool.and(pu, Nat.is_eq(List.length(&2, List<&2, TP>, rs), 2n)),
    Bool.and(Bool.and(F64.is_lt(KS.pi(), F64.abs(a)), F64.is_lt(KS.pi(), F64.abs(b))), F64.is_lt(F64.mul(a, b), 0.0f64)))

def near_j(r: List<&2, TP>, +g: GS, +u0: F64, +i: Nat, +bi: Nat, +bd: F64) -> Nat:
  match r:
    case []: bi
    case +h <> t:
      +d = F64.abs(KS.ang_diff(u0, V.v2_x(g_uv(g, tp_p(h)))))
      near_j(t, g, u0, Nat.add(i, 1n), Bool.pick(Nat, F64.is_lt(d, bd), i, bi), F64.min(d, bd))

def tp_take(r: List<&2, TP>, +n: Nat) -> List<&2, TP>:
  match r:
    case []: []
    case +h <> t:
      match n:
        case 0n: []
        case 1n+(+m): h <> tp_take(t, m)

def tp_drop(r: List<&2, TP>, +n: Nat) -> List<&2, TP>:
  match r:
    case []: []
    case +h <> +t:
      match n:
        case 0n: h <> t
        case 1n+(+m): tp_drop(t, m)

def bd_ring(+rs: List<&2, List<&2, TP>>, +g: GS) -> List<&2, TP>:
  +ra = rs_at(rs, 0n)
  +rb = rs_at(rs, 1n)
  +a0 = tp0(ra)
  +j = near_j(rb, g, V.v2_x(g_uv(g, tp_p(a0))), 0n, 0n, F64.div(1.0f64, 0.0f64))
  +rb2 = List.append(&2, TP, tp_drop(rb, j), tp_take(rb, j))
  List.append(&2, TP, ra, a0 <> List.append(&2, TP, rb2, [tp0(rb2)]))

def gen_core(+rs: List<&2, List<&2, TP>>, +g: GS, +qs: List<&2, List<&2, QP>>, +vxs: List<&2, VX>, +sf: KS.SF, +same: Bool, +base: Nat, +tol: TL) -> TGO:
  +t0 = clip_rings(ql_hd(qs), ql_tl(qs))
  +nb = rings_n(rs)
  +cap = Nat.add(Nat.mul(6n, nb), 8192n)
  +vt = B.tb_of(VX, List.append(&2, VX, vxs, rep_vx(cap)), vx0())
  +nx = B.tb_of(Nat, g_nx(rs, 0n), 0n)
  +td = flips(Nat.add(List.length(&2, Tri, t0), 8n), True{}, t0, vt)
  +r = ref_go(48n, False{}, RF{td, vt, nb}, g, nx, nb, Nat.add(nb, cap), tol)
  gen_fin(r, sf, same, B.tb_of(Nat, g_ids(rs), 0n), nb, base, Bool.not(Nat.is_eq(List.length(&2, Tri, t0), 0n)), nx)

def is_pole(+g: GS, +p: V.Point) -> Bool:
  +sf = gs_sf(g)
  +h = F64.abs(KS.dot(KS.psub(p, KS.sf_o(sf)), KS.sf_a(sf)))
  Bool.and(gs_pu(g), Bool.and(KS.is_sph(sf), F64.is_le(F64.mul(KS.sf_r(sf), F64.sub(1.0f64, 1.0e-9f64)), h)))

def pole_k() -> Nat:
  16n

def tp_rep(n: Nat, +h: TP) -> List<&2, TP>:
  match n:
    case 0n: [h]
    case 1n+(+m): h <> tp_rep(m, h)

def dup_poles(r: List<&2, TP>, +g: GS) -> List<&2, TP>:
  match r:
    case []: []
    case +h <> t: List.append(&2, TP, Bool.pick(List<&2, TP>, is_pole(g, tp_p(h)), tp_rep(pole_k(), h), [h]), dup_poles(t, g))

def dup_rings(rs: List<&2, List<&2, TP>>, +g: GS) -> List<&2, List<&2, TP>>:
  match rs:
    case []: []
    case +r <> t: dup_poles(r, g) <> dup_rings(t, g)

def jmp(+a: F64, +b: F64, +ch: F64) -> F64:
  +d = KS.ang_diff(a, b)
  Bool.pick(F64, F64.is_lt(F64.sub(KS.pi(), 1.0e-6f64), F64.abs(d)), F64.mul(ch, KS.pi()), d)

def nx_np(r: List<&2, TP>, +g: GS) -> V.Vec2:
  match r:
    case []: V.V2{0.0f64, 0.0f64}
    case +h <> t: Bool.pick(V.Vec2, is_pole(g, tp_p(h)), nx_np(t, g), g_uv(g, tp_p(h)))

def uw_ws(r: List<&2, TP>, +g: GS, +prev: V.Vec2, +pi: Nat, +u0: F64, +ch: F64) -> List<&2, V.Vec2>:
  match r:
    case []: []
    case +h <> +t:
      +raw = g_uv(g, tp_p(h))
      +pl = is_pole(g, tp_p(h))
      +first = Nat.is_eq(pi, 0n)
      +a = Bool.pick(F64, first, V.v2_x(prev), u0)
      +d = jmp(a, V.v2_x(nx_np(t, g)), ch)
      +w = Bool.pick(V.Vec2, pl, V.V2{Bool.pick(F64, first, a, F64.add(a, F64.div(F64.mul(d, U64.to_f64(U64.from_nat(pi))), U64.to_f64(U64.from_nat(pole_k()))))), V.v2_y(raw)},
        uw_next(g, prev, raw))
      +last = Bool.and(pl, Nat.is_eq(pi, pole_k()))
      +pi2 = Bool.pick(Nat, Bool.and(pl, Bool.not(last)), Nat.add(pi, 1n), 0n)
      w <> uw_ws(t, g, w, pi2, a, Bool.pick(F64, last, F64.neg(ch), ch))

def rings_ws(rs: List<&2, List<&2, TP>>, +g: GS, +ref: F64, +first: Bool, +ch: F64) -> List<&2, List<&2, V.Vec2>>:
  match rs:
    case []: []
    case +r <> t:
      +w0 = r_w0(r, g, ref, first)
      +ref2 = Bool.pick(F64, first, r_mu(r, g, w0, 0.0f64, 0.0f64), ref)
      uw_ws(r, g, w0, 0n, 0.0f64, ch) <> rings_ws(t, g, ref2, False{}, ch)

def ws_q(ws: List<&2, V.Vec2>, +i: Nat) -> List<&2, QP>:
  match ws:
    case []: []
    case +w <> t: QP{i, V.v2_x(w), V.v2_y(w)} <> ws_q(t, Nat.add(i, 1n))

def wss_q(ws: List<&2, List<&2, V.Vec2>>, +i: Nat) -> List<&2, List<&2, QP>>:
  match ws:
    case []: []
    case +w <> t: ws_q(w, i) <> wss_q(t, Nat.add(i, List.length(&2, V.Vec2, w)))

def ws_v(ws: List<&2, V.Vec2>, r: List<&2, TP>) -> List<&2, VX>:
  match ws:
    case []: []
    case +w <> t:
      match r:
        case []: []
        case +h <> u: VX{V.v2_x(w), V.v2_y(w), tp_p(h)} <> ws_v(t, u)

def wss_v(ws: List<&2, List<&2, V.Vec2>>, rs: List<&2, List<&2, TP>>) -> List<&2, VX>:
  match ws:
    case []: []
    case +w <> t:
      match rs:
        case []: []
        case +r <> u: List.append(&2, VX, ws_v(w, r), wss_v(t, u))

def ws_hd(ws: List<&2, V.Vec2>) -> V.Vec2:
  match ws:
    case []: V.V2{0.0f64, 0.0f64}
    case +w <> t: w

def ws_area(ws: List<&2, V.Vec2>, +first: V.Vec2, +acc: F64) -> F64:
  match ws:
    case []: acc
    case +w <> +t:
      +n = Bool.pick(V.Vec2, Nat.is_eq(List.length(&2, V.Vec2, t), 0n), first, ws_hd(t))
      ws_area(t, first, F64.add(acc, F64.sub(F64.mul(V.v2_x(w), V.v2_y(n)), F64.mul(V.v2_x(n), V.v2_y(w)))))

def wss_hd(ws: List<&2, List<&2, V.Vec2>>) -> List<&2, V.Vec2>:
  match ws:
    case []: []
    case +w <> t: w

def gen_np(+rs0: List<&2, List<&2, TP>>, +g: GS, +sf: KS.SF, +same: Bool, +base: Nat, +tol: TL) -> TGO:
  +rs = dup_rings(rs0, g)
  +w1 = wss_hd(rings_ws(rs, g, 0.0f64, True{}, 1.0f64))
  +pos = F64.is_lt(0.0f64, ws_area(w1, ws_hd(w1), 0.0f64))
  +ch = Bool.pick(F64, Bool.xor(pos, same), F64.neg(1.0f64), 1.0f64)
  +wss = rings_ws(rs, g, 0.0f64, True{}, ch)
  gen_core(rs, g, wss_q(wss, 0n), wss_v(wss, rs), sf, same, base, tol)

def gen_bd(band: Bool, +rs0: List<&2, List<&2, TP>>, +g: GS, +sf: KS.SF, +same: Bool, +base: Nat, +tol: TL) -> TGO:
  match band:
    case False{}: gen_np(rs0, g, sf, same, base, tol)
    case True{}:
      +r = bd_ring(rs0, g)
      +w0 = g_uv(g, tp_p(tp0(r)))
      gen_core([r], g, [uw_q(r, g, w0, 0n)], uw_v(r, g, w0), sf, same, base, tol)

def sph_ax(+sf: KS.SF, +ax: Nat) -> KS.SF:
  +o = KS.sf_o(sf)
  +r = KS.sf_r(sf)
  Bool.pick(KS.SF, Nat.is_eq(ax, 1n), KS.SF{KS.k_sph(), o, V.Dr{0.0f64, 1.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, r, 0.0f64, 0.0f64},
    Bool.pick(KS.SF, Nat.is_eq(ax, 2n), KS.SF{KS.k_sph(), o, V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}, r, 0.0f64, 0.0f64},
      KS.SF{KS.k_sph(), o, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, r, 0.0f64, 0.0f64}))

def rs_wrap_zz(rs: List<&2, List<&2, TP>>, zz: Bool, +g: GS) -> Bool:
  match rs:
    case []: zz
    case +r <> t:
      match zz:
        case True{}: True{}
        case False{}: rs_wrap_zz(t, F64.is_lt(KS.pi(), F64.abs(r_wrap(r, g))), g)

def rs_wrap(rs: List<&2, List<&2, TP>>, +g: GS) -> Bool:
  rs_wrap_zz(rs, False{}, g)

def sph_try(+sf: KS.SF, +rs: List<&2, List<&2, TP>>, +ax: Nat) -> Bool:
  rs_wrap(rs, gs_of(sph_ax(sf, ax), rs))

def sph_pick(+sf: KS.SF, +rs: List<&2, List<&2, TP>>) -> KS.SF:
  Bool.pick(KS.SF, Bool.not(KS.is_sph(sf)), sf,
    Bool.pick(KS.SF, Bool.not(sph_try(sf, rs, 0n)), sph_ax(sf, 0n),
      Bool.pick(KS.SF, Bool.not(sph_try(sf, rs, 1n)), sph_ax(sf, 1n),
        Bool.pick(KS.SF, Bool.not(sph_try(sf, rs, 2n)), sph_ax(sf, 2n), sf))))

def rs_nw(rs: List<&2, List<&2, TP>>, +acc: V.Dir) -> V.Dir:
  match rs:
    case []: acc
    case +r <> t:
      +n = newell(r)
      rs_nw(t, V.Dr{F64.add(V.dr_x(acc), V.pt_x(n)), F64.add(V.dr_y(acc), V.pt_y(n)), F64.add(V.dr_z(acc), V.pt_z(n))})

def st_of(+sf: KS.SF, +c: V.Dir) -> GS:
  +x = F64.abs(V.dr_x(c))
  +y = F64.abs(V.dr_y(c))
  +z = F64.abs(V.dr_z(c))
  +e = Bool.pick(V.Dir, Bool.and(F64.is_le(x, y), F64.is_le(x, z)), V.Dr{1.0f64, 0.0f64, 0.0f64}, Bool.pick(V.Dir, F64.is_le(y, z), V.Dr{0.0f64, 1.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}))
  +e1 = KS.dunit(KS.cross(e, c))
  GS_st{sf, c, e1, KS.cross(c, e1)}

def st_area(rs: List<&2, List<&2, TP>>, +g: GS, +acc: F64) -> F64:
  match rs:
    case []: acc
    case +r <> t:
      +ws = uw_ws(r, g, V.V2{0.0f64, 0.0f64}, 0n, 0.0f64, 1.0f64)
      st_area(t, g, F64.add(acc, ws_area(ws, ws_hd(ws), 0.0f64)))

def st_ok(+g: GS, +rs: List<&2, List<&2, TP>>, +same: Bool) -> Bool:
  Bool.xor(F64.is_lt(st_area(rs, g, 0.0f64), 0.0f64), same)

def gen_ax(+rs0: List<&2, List<&2, TP>>, +sf0: KS.SF, +same: Bool, +base: Nat, +tol: TL) -> TGO:
  +sf = sph_pick(sf0, rs0)
  +g0 = gs_of(sf, rs0)
  gen_bd(band_of(g0, rs0), rs0, g0, sf, same, base, tol)

def gen_pick(st: Bool, +gs: GS, +rs0: List<&2, List<&2, TP>>, +sf0: KS.SF, +same: Bool, +base: Nat, +tol: TL) -> TGO:
  match st:
    case True{}: gen_np(rs0, gs, sf0, same, base, tol)
    case False{}: gen_ax(rs0, sf0, same, base, tol)

def gen_st(+rs0: List<&2, List<&2, TP>>, +sf: KS.SF, +same: Bool, +base: Nat, +tol: TL) -> TGO:
  +m = rs_nw(rs0, V.Dr{0.0f64, 0.0f64, 0.0f64})
  +c = KS.dunit(m)
  +ga = st_of(sf, c)
  +gb = st_of(sf, KS.dscale(F64.neg(1.0f64), c))
  +lean = F64.is_lt(F64.mul(1.0e-6f64, F64.mul(KS.sf_r(sf), KS.sf_r(sf))), KS.dlen(m))
  +oka = Bool.and(lean, st_ok(ga, rs0, same))
  +okb = Bool.and(lean, st_ok(gb, rs0, same))
  gen_pick(Bool.or(oka, okb), Bool.pick(GS, oka, ga, gb), rs0, sf, same, base, tol)

def gen_sp(sph: Bool, +rs0: List<&2, List<&2, TP>>, +sf0: KS.SF, +same: Bool, +base: Nat, +tol: TL) -> TGO:
  match sph:
    case True{}: gen_st(rs0, sf0, same, base, tol)
    case False{}: gen_ax(rs0, sf0, same, base, tol)

def gen_rs(+rs0: List<&2, List<&2, TP>>, +sf0: KS.SF, +same: Bool, +base: Nat, +tol: TL) -> TGO:
  gen_sp(KS.is_sph(sf0), rs0, sf0, same, base, tol)

def gen_face(f: Ty.Face, +x: Ctx, +base: Nat, +tol: TL) -> TGO:
  Ty.Fa{g, +s, +ls, +same, slv, sla} = f
  gen_rs(rings(ls, x), KS.sf_of(s), same, base, tol)

def face_tg(use: Bool, f: Ty.Face, +x: Ctx, +ps: B.Tb<&2, V.Point>, +bbase: Nat, +gbase: Nat, +tol: TL) -> TGO:
  match use:
    case True{}: gen_face(f, x, gbase, tol)
    case False{}: TGO{face_tris(f, x, ps, bbase), [], True{}}

def gt_nt(+a: TGO) -> Nat:
  TGO{+ts, ps, ok} = a
  List.length(&2, Tri, ts)

def sk_s(s: G.GVal) -> String:
  match s:
    case G.GV_pl{w}: "plane"
    case G.GV_cy{w}: "cylinder"
    case G.GV_co{w}: "cone"
    case G.GV_sp{w}: "sphere"
    case G.GV_to{w}: "torus"
    case G.GV_bp{w}: "bicubic"
    case G.GV_nb{w}: "nurbs"
    case _: "other"

def fa_sk(f: Ty.Face) -> String:
  Ty.Fa{g, +s, ls, same, slv, sla} = f
  sk_s(s)

def fg_add(+r: TGO, +k: String, +b: FG) -> FG:
  FG{+g, +ns, +ks} = b
  FG{gt_add(r, g), gt_nt(r) <> ns, k <> ks}

type FI is Data:
  FI{ f: Ty.Face, bb: Nat }

type FC is Data:
  FC{ x: Ctx, ps: B.Tb<&2, V.Point>, g0: Nat, tol: TL }

type FR is Data:
  FR{ r: TGO, k: String }

def fis(fs: List<&2, Ty.Face>, +bb: Nat, +x: Ctx) -> List<&2, FI>:
  match fs:
    case []: []
    case +f <> t: FI{f, bb} <> fis(t, Nat.add(bb, Bool.pick(Nat, use_gen(f, x), 0n, face_bp_used(f))), x)

def face_par(c: FC, i: FI) -> FR:
  FC{+x, +ps, +g0, +tol} = c
  FI{+f, +bb} = i
  FR{face_tg(use_gen(f, x), f, x, ps, bb, g0, tol), fa_sk(f)}

def ix_sh(+i: Nat, +g0: Nat, +d: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_lt(i, g0), i, Nat.add(i, d))

def ts_sh(ts: List<&2, Tri>, +g0: Nat, +d: Nat) -> List<&2, Tri>:
  match ts:
    case []: []
    case +t <> r:
      Tri{+a, +b, +c} = t
      Tri{ix_sh(a, g0, d), ix_sh(b, g0, d), ix_sh(c, g0, d)} <> ts_sh(r, g0, d)

def fr_fold(rs: List<&2, FR>, +g0: Nat, +d: Nat) -> FG:
  match rs:
    case []: FG{TGO{[], [], True{}}, [], []}
    case +h <> t:
      FR{+tg, +k} = h
      TGO{+ts, +ps, +ok} = tg
      fg_add(TGO{ts_sh(ts, g0, d), ps, ok}, k, fr_fold(t, g0, Nat.add(d, List.length(&2, V.Point, ps))))

def faces_tg(fs: List<&2, Ty.Face>, +x: Ctx, +ps: B.Tb<&2, V.Point>, +bbase: Nat, +gbase: Nat, +tol: TL) -> FG:
  fr_fold(B.pmap_g(~FI, ~FC, ~FR, ~face_par, 1, FC{x, ps, gbase, tol}, fis(fs, bbase, x)), gbase, 0n)

def pri_fin(+gt: TGO, +ns: List<&2, Nat>, +ks: List<&2, String>, +all: List<&2, V.Point>, +b: M.Body, +est: Nat, +mq: MQ, +es: String) -> M10.Tres:
  TGO{+ts, +gp, +gok} = gt
  +all2 = List.append(&2, V.Point, all, gp)
  +nt = List.length(&2, Tri, ts)
  pri_out(Bool.and(gok, closed(ts)), M10.tres_ok(obj_vs(all2, M.bd_pl(b)) ++ obj_fg(Nat.add(Nat.add(nt, List.length(&2, Nat, ns)), 1n), ts, ns, ks, 0n, 0n) ++ es,
    List.length(&2, V.Point, all2), List.length(&2, Tri, ts), est,
    mq_chord(mq), mq_ang(mq), mq_n(mq)))

def e_pt(+p: V.Point, +pl: M.Pl) -> String:
  +q = pl_pt(p, pl)
  " " ++ F64.show(V.pt_x(q)) ++ " " ++ F64.show(V.pt_y(q)) ++ " " ++ F64.show(V.pt_z(q))

def e_pts(ps: List<&2, V.Point>, +pl: M.Pl) -> String:
  match ps:
    case []: ""
    case +p <> t: e_pt(p, pl) ++ e_pts(t, pl)

def e_kind(k: Ty.EdgeKind, +a: V.Point, +b: V.Point, +s: List<&2, V.Point>, +pl: M.Pl) -> String:
  match k:
    case Ty.EK_degenerate{}: ""
    case _: "e" ++ e_pt(a, pl) ++ e_pts(s, pl) ++ e_pt(b, pl) ++ "\n"

def e_line(e: Ty.Edge, +s: List<&2, V.Point>, +vt: B.Tb<&2, V.Point>, +pl: M.Pl) -> String:
  Ty.Ed{g, v0, v1, k} = e
  e_kind(k, B.tb_get(V.Point, vt, ux(hv_i(v0))), B.tb_get(V.Point, vt, ux(hv_i(v1))), s, pl)

def obj_es(es: List<&2, Ty.Edge>, ss: List<&2, List<&2, V.Point>>, +vt: B.Tb<&2, V.Point>, +pl: M.Pl) -> String:
  match es:
    case []: ""
    case e <> t:
      match ss:
        case []: ""
        case +s <> u: e_line(e, s, vt, pl) ++ obj_es(t, u, vt, pl)

def fg_fin(+fg: FG, +all: List<&2, V.Point>, +b: M.Body, +est: Nat, +mq: MQ, +es: String) -> M10.Tres:
  FG{+gt, +ns, +ks} = fg
  pri_fin(gt, ns, ks, all, b, est, mq, es)

def pri_emit(+b: M.Body, +q: M10.Q, +est: Nat) -> M10.Tres:
  +br = M.bd_brep(b)
  +ps = all_pts(br, q)
  +all = List.append(&2, V.Point, ps, bp_ps_of(Ty.brep_fas(br)))
  +tb = B.tb_of(V.Point, all, pz())
  +ss = smps(Ty.brep_es(br), q)
  +mq = meas_go(Ty.brep_es(br), ss, vx_pts(Ty.brep_vs(br)))
  fg_fin(faces_tg(Ty.brep_fas(br), ctx_of(br, q), tb, List.length(&2, V.Point, ps), List.length(&2, V.Point, all), TL{M10.q_chord(q), KS.fcos(M10.q_angle(q))}), all, b, est, mq,
    obj_es(Ty.brep_es(br), ss, tb, M.bd_pl(b)))

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

def s_rep(n: Nat, +x: String) -> List<&2, String>:
  match n:
    case 0n: []
    case 1n+m: x <> s_rep(m, x)

def ln_kind(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> String:
  Bool.pick(String, F64.is_eq(ax, bx), Bool.pick(String, F64.is_eq(ax, 0.0f64), "axis", "cylinder"),
    Bool.pick(String, F64.is_eq(ay, by), "plane", "cone"))

def ar_kind(+ax: F64, +px: F64, +w: F64, +bx: F64) -> String:
  +mx = F64.mul(0.5f64, F64.add(ax, bx))
  +cx = F64.sub(px, F64.div(F64.sub(px, mx), F64.sub(1.0f64, F64.mul(w, w))))
  Bool.pick(String, F64.is_lt(F64.abs(cx), 0.0000001f64), "sphere", "torus")

def pc_h(+pi: Nat) -> String:
  "g p" ++ Nat.show(pi) ++ " "

def pc_tags(p: F.Pc, +q: M10.Q, +pi: Nat) -> List<&2, String>:
  match p:
    case F.P_ln{+ax, +ay, +bx, +by}: [pc_h(pi) ++ ln_kind(ax, ay, bx, by) ++ "\n"]
    case F.P_ar{+ax, +ay, +px, +py, +w, +bx, +by}:
      (pc_h(pi) ++ ar_kind(ax, px, w, bx) ++ "\n") <> s_rep(Nat.sub(arc_segs(ax, ay, px, py, w, bx, by, q), 1n), "")

def lath_tags(ps: List<&2, F.Pc>, +q: M10.Q, +pi: Nat) -> List<&2, String>:
  match ps:
    case []: []
    case p <> t: List.append(&2, String, pc_tags(p, q, pi), lath_tags(t, q, Nat.add(pi, 1n)))

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

def bands(rs: List<&2, List<&2, Nat>>, +first: List<&2, Nat>) -> List<&2, List<&2, Tri>>:
  match rs:
    case []: []
    case +r <> +t:
      +nx = Bool.pick(List<&2, Nat>, Nat.is_eq(List.length(&2, List<&2, Nat>, t), 0n), first, nl_hd(t))
      +ax = Bool.and(Nat.is_eq(n_hd(r), n_hd(n_drop(r, 1n))), Nat.is_eq(n_hd(nx), n_hd(n_drop(nx, 1n))))
      Bool.pick(List<&2, Tri>, ax, [], band(r, nx, n_hd(r), n_hd(nx))) <> bands(t, first)

def tl_cat(xs: List<&2, List<&2, Tri>>) -> List<&2, Tri>:
  match xs:
    case []: []
    case x <> t: List.append(&2, Tri, x, tl_cat(t))

def obj_tag(bl: List<&2, List<&2, Tri>>, +tags: List<&2, String>) -> String:
  match bl:
    case []: ""
    case x <> t:
      match tags:
        case []: obj_fs(x) ++ obj_tag(t, [])
        case g <> u: g ++ obj_fs(x) ++ obj_tag(t, u)

def lath_rmax(qs: List<&2, V.Vec2>) -> F64:
  match qs:
    case []: 0.0f64
    case v <> t: F64.max(F64.abs(V.v2_x(v)), lath_rmax(t))

def lath_lp(+pcs: List<&2, V.Vec2>, +n: Nat, +b: Nat) -> List<&2, List<&2, Tri>>:
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
  LA{+b, +ps, +ts, +s, +np} = a
  +pcs = lath_pcs(F.lp_pcs(l), q)
  +n = rings_max(pcs, q)
  +p = lath_pts(pcs, n)
  +bl = lath_lp(pcs, n, b)
  LA{Nat.add(b, List.length(&2, V.Point, p)), List.append(&2, V.Point, ps, p),
    List.append(&2, Tri, ts, tl_cat(bl)), s ++ obj_tag(bl, lath_tags(F.lp_pcs(l), q, np)),
    Nat.add(np, List.length(&2, F.Pc, F.lp_pcs(l)))}

def lath_go(ls: List<&2, F.Lp>, +a: LA, +q: M10.Q) -> LA:
  match ls:
    case []: a
    case l <> t: lath_go(t, la_add(a, l, q), q)

def la_obj(a: LA, +pl: M.Pl) -> String:
  LA{b, +ps, ts, +s, np} = a
  obj_vs(ps, pl) ++ s

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
  LA{b, ps, ts, s, np} = a
  ps

def la_ts(+a: LA) -> List<&2, Tri>:
  LA{b, ps, ts, s, np} = a
  ts

def rev_emit2(+a: LA, +b: M.Body, +q: M10.Q, +est: Nat) -> M10.Tres:
  +mq = rev_mq_go(M.bd_rv(b), q)
  M10.tres_ok(la_obj(a, M.bd_pl(b)), List.length(&2, V.Point, la_ps(a)), List.length(&2, Tri, la_ts(a)), est,
    mq_chord(mq), mq_ang(mq), mq_n(mq))

def rev_emit(+b: M.Body, +q: M10.Q, +est: Nat) -> M10.Tres:
  rev_emit2(lath_go(M.bd_rv(b), LA{0n, [], [], "", 0n}, q), b, q, est)

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
