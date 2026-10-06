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

def nf(+n: Nat) -> F64:
  U64.to_f64(U64.from_nat(n))

def rq_pts(+w: G.RQBez, +j: Nat, +k: Nat) -> List<&2, V.Point>:
  match j:
    case 0n: []
    case 1n+i: List.append(&2, V.Point, rq_pts(w, i, k), [G.gres_p(GO.rqb_eval(w, F64.div(nf(j), nf(Nat.add(k, 1n)))))])

def cc_pts(+w: G.Circle3, +j: Nat, +n: Nat) -> List<&2, V.Point>:
  match j:
    case 0n: []
    case 1n+i:
      List.append(&2, V.Point, cc_pts(w, i, n),
        [G.gres_p(GO.circ_eval(w, F64.add(F64.neg(1.0f64), F64.div(F64.mul(2.0f64, nf(j)), nf(n)))))])

def cv_pts(c: G.GVal) -> List<&2, V.Point>:
  match c:
    case G.GV_rq{+w}: rq_pts(w, 6n, 6n)
    case G.GV_cc{+w}: cc_pts(w, 31n, 32n)
    case _: []

def ek_pts(k: Ty.EdgeKind) -> List<&2, V.Point>:
  match k:
    case Ty.EK_curve{c, d}: cv_pts(c)
    case Ty.EK_degenerate{}: []

def ed_pts(e: Ty.Edge) -> List<&2, V.Point>:
  Ty.Ed{g, v0, v1, k} = e
  ek_pts(k)

def smps(es: List<&2, Ty.Edge>) -> List<&2, List<&2, V.Point>>:
  match es:
    case []: []
    case e <> t: ed_pts(e) <> smps(t)

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

def ctx_of(+b: Ty.Brep) -> Ctx:
  +es = Ty.brep_es(b)
  +ss = smps(es)
  +nv = List.length(&2, Ty.Vertex, Ty.brep_vs(b))
  Ctx{B.tb_of(V.Point, vx_pts(Ty.brep_vs(b)), pz()), B.tb_of(Ty.Edge, es, Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{0n, 0u64}, Ty.EK_degenerate{}}),
    B.tb_of(Ty.Coedge, Ty.brep_ces(b), Ty.Ce{0u64, Ty.HE{0n, 0u64}, True{}, G.GV_f{0.0f64}}),
    B.tb_of(Ty.Loop, Ty.brep_lps(b), Ty.Lp{0u64, [], Ty.LK_outer{}}), B.tb_of(Nat, bases(ss, nv), 0n),
    B.tb_of(List<&2, V.Point>, ss, [])}

def cat_pts(ss: List<&2, List<&2, V.Point>>) -> List<&2, V.Point>:
  match ss:
    case []: []
    case s <> t: List.append(&2, V.Point, s, cat_pts(t))

def all_pts(+b: Ty.Brep) -> List<&2, V.Point>:
  List.append(&2, V.Point, vx_pts(Ty.brep_vs(b)), cat_pts(smps(Ty.brep_es(b))))

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

def tp_id(t: TP) -> Nat:
  TP{id, p} = t
  id

def tp_p(t: TP) -> V.Point:
  TP{id, p} = t
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

def tp_ids(xs: List<&2, TP>) -> List<&2, Nat>:
  match xs:
    case []: []
    case x <> t: tp_id(x) <> tp_ids(t)

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
    case _: 0u64

def face_go(+k: U64, +rs: List<&2, List<&2, TP>>, +c: V.Point) -> List<&2, Tri>:
  match k:
    case 1u64:
      Bool.pick(List<&2, Tri>, Nat.is_eq(List.length(&2, List<&2, TP>, rs), 2n), band_tris(rs),
        cyl1_tris(r_hd(rs)))
    case _: planar_tris(rs)

def face_tris(f: Ty.Face, +x: Ctx, +ps: B.Tb<&2, V.Point>) -> List<&2, Tri>:
  Ty.Fa{g, +s, ls, +same} = f
  +rs = rings(ls, x)
  +c = cyl_c(s)
  +k = surf_k(s)
  fix_go(face_go(k, rs, c), ps, k, same, newell(r_hd(rs)), c)

def faces_tris(fs: List<&2, Ty.Face>, +x: Ctx, +ps: B.Tb<&2, V.Point>) -> List<&2, Tri>:
  match fs:
    case []: []
    case f <> t: List.append(&2, Tri, face_tris(f, x, ps), faces_tris(t, x, ps))

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

def pri_obj(+b: M.Body) -> String:
  +br = M.bd_brep(b)
  +ps = all_pts(br)
  +tb = B.tb_of(V.Point, ps, pz())
  obj_vs(ps, M.bd_pl(b)) ++ obj_fs(faces_tris(Ty.brep_fas(br), ctx_of(br), tb))

def rq2(j: Nat, +w: G.RQBez, +k: Nat) -> List<&2, V.Vec2>:
  match j:
    case 0n: []
    case 1n+(+i):
      +q = G.gres_p(GO.rqb_eval(w, F64.div(nf(Nat.sub(k, i)), nf(Nat.add(k, 1n)))))
      V.V2{V.pt_x(q), V.pt_z(q)} <> rq2(i, w, k)

def lath_pcs(ps: List<&2, F.Pc>) -> List<&2, V.Vec2>:
  match ps:
    case []: []
    case p <> +t:
      match p:
        case F.P_ln{ax, ay, bx, by}: V.V2{ax, ay} <> lath_pcs(t)
        case F.P_ar{+ax, +ay, px, py, w, bx, by}:
          List.append(&2, V.Vec2, V.V2{ax, ay} <> rq2(6n, G.Rq{V.Pt{ax, 0.0f64, ay}, V.Pt{px, 0.0f64, py}, V.Pt{bx, 0.0f64, by}, 1.0f64, w, 1.0f64}, 6n),
            lath_pcs(t))

def ring_pts(i: Nat, +r: F64, +h: F64, +n: Nat) -> List<&2, V.Point>:
  match i:
    case 0n: []
    case 1n+(+j):
      +t = F64.add(F64.neg(1.0f64), F64.div(F64.mul(2.0f64, nf(Nat.sub(n, Nat.add(j, 1n)))), nf(n)))
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

def lath_lp(+l: F.Lp, +b: Nat, +n: Nat) -> List<&2, Tri>:
  +rs = lath_rings(lath_pcs(F.lp_pcs(l)), n)
  +ids = ids_of(rs, b, n)
  bands(ids, nl_hd(ids))

def lath_pts(+l: F.Lp, +n: Nat) -> List<&2, V.Point>:
  cat_pts(lath_rings(lath_pcs(F.lp_pcs(l)), n))

def la_add(a: LA, +l: F.Lp, +n: Nat) -> LA:
  LA{+b, +ps, +ts} = a
  +p = lath_pts(l, n)
  LA{Nat.add(b, List.length(&2, V.Point, p)), List.append(&2, V.Point, ps, p), List.append(&2, Tri, ts, lath_lp(l, b, n))}

def lath_go(ls: List<&2, F.Lp>, +a: LA, +n: Nat) -> LA:
  match ls:
    case []: a
    case l <> t: lath_go(t, la_add(a, l, n), n)

def la_obj(a: LA, +pl: M.Pl) -> String:
  LA{b, ps, ts} = a
  obj_vs(ps, pl) ++ obj_fs(ts)

def rev_obj(+b: M.Body) -> String:
  la_obj(lath_go(M.bd_rv(b), LA{0n, [], []}, 32n), M.bd_pl(b))

def body_obj(+b: M.Body) -> String:
  Bool.pick(String, Nat.is_eq(List.length(&2, F.Lp, M.bd_rv(b)), 0n), pri_obj(b), rev_obj(b))
