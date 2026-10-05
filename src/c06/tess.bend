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




def qid(q: QP) -> Nat:
  QP{id, x, y} = q
  id




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




def q_same(+a: QP, +b: QP) -> Bool:
  Bool.and(F64.is_eq(qx(a), qx(b)), F64.is_eq(qy(a), qy(b)))




def ori(+a: QP, +b: QP, +c: QP) -> B.Sgn:
  XE.orient2s(qx(a), qy(a), qx(b), qy(b), qx(c), qy(c))




def in_tri(+a: QP, +b: QP, +c: QP, +q: QP) -> Bool:
  +s1 = ori(a, b, q)
  +s2 = ori(b, c, q)
  +s3 = ori(c, a, q)
  +skip = Bool.or(q_same(q, a), Bool.or(q_same(q, b), q_same(q, c)))
  Bool.and(Bool.not(skip), Bool.and(Bool.not(F.sgn_neg(s1)), Bool.and(Bool.not(F.sgn_neg(s2)), Bool.not(F.sgn_neg(s3)))))




def ang_in(+v: QP, +w1: QP, +w2: QP, +n: QP) -> Bool:
  Bool.and(F.sgn_pos(ori(v, w1, n)), F.sgn_pos(ori(v, n, w2)))



def dup_block(+q: QP, +nb: QP, +a: QP, +b: QP, +c: QP) -> Bool:
  Bool.or(Bool.and(q_same(q, a), ang_in(a, b, c, nb)),
    Bool.or(Bool.and(q_same(q, b), ang_in(b, c, a, nb)), Bool.and(q_same(q, c), ang_in(c, a, b, nb))))



def q_hd(xs: List<&2, QP>, +d: QP) -> QP:
  match xs:
    case []: d
    case x <> t: x



def any_go(xs: List<&2, QP>, +prv: QP, +last: QP, +a: QP, +b: QP, +c: QP) -> Bool:
  match xs:
    case []: False{}
    case +q <> +t:
      +nxt = Bool.pick(QP, Nat.is_eq(List.length(&2, QP, t), 0n), last, q_hd(t, last))
      Bool.or(Bool.or(in_tri(a, b, c, q), Bool.or(dup_block(q, prv, a, b, c), dup_block(q, nxt, a, b, c))),
        any_go(t, q, last, a, b, c))



def any_in(+xs: List<&2, QP>, +a: QP, +b: QP, +c: QP) -> Bool:
  any_go(xs, c, a, a, b, c)



def is_ear(+a: QP, +b: QP, +c: QP, +rest: List<&2, QP>) -> Bool:
  Bool.and(F.sgn_pos(ori(a, b, c)), Bool.not(any_in(rest, a, b, c)))

def q3(+a: QP, +b: QP, +c: QP) -> Tri:
  Tri{qid(a), qid(b), qid(c)}




def clip(f: Nat, r: List<&2, QP>, +n: Nat, +acc: List<&2, Tri>) -> List<&2, Tri>:
  match f:
    case 0n: acc
    case 1n+g:
      match r:
        case []: acc
        case +a <> t1:
          match t1:
            case []: acc
            case +b <> t2:
              match t2:
                case []: acc
                case +c <> +rest:
                  +ear = is_ear(a, b, c, rest)
                  +last = Nat.is_le(n, 3n)
                  clip(g, Bool.pick(List<&2, QP>, last, [], Bool.pick(List<&2, QP>, ear, a <> c <> rest, b <> c <> List.append(&2, QP, rest, [a]))),
                    Bool.pick(Nat, ear, Nat.sub(n, 1n), n), Bool.pick(List<&2, Tri>, Bool.or(ear, last), q3(a, b, c) <> acc, acc))




def edges_of_go(xs: List<&2, QP>, +first: QP, +prev: QP) -> List<&2, List<&2, QP>>:
  match xs:
    case []: [[prev, first]]
    case +x <> t: [prev, x] <> edges_of_go(t, first, x)




def edges_of(r: List<&2, QP>) -> List<&2, List<&2, QP>>:
  match r:
    case []: []
    case +x <> t: edges_of_go(t, x, x)




def q_nth(xs: List<&2, QP>, +i: Nat) -> QP:
  match xs:
    case []: QP{0n, 0.0f64, 0.0f64}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: q_nth(t, j)




def vis(+m: QP, +p: QP, es: List<&2, List<&2, QP>>) -> Bool:
  match es:
    case []: True{}
    case +e <> t:
      +u = q_nth(e, 0n)
      +v = q_nth(e, 1n)
      +touch = Bool.or(q_same(u, m), Bool.or(q_same(v, m), Bool.or(q_same(u, p), q_same(v, p))))
      Bool.and(Bool.or(touch, U64.is_eq(F.seg_seg_ok(qx(m), qy(m), qx(p), qy(p), qx(u), qy(u), qx(v), qy(v)), 0u64)), vis(m, p, t))




def d2(+a: QP, +b: QP) -> F64:
  +dx = F64.sub(qx(a), qx(b))
  +dy = F64.sub(qy(a), qy(b))
  F64.add(F64.mul(dx, dx), F64.mul(dy, dy))




def id_cnt(xs: List<&2, QP>, +id: Nat) -> Nat:
  match xs:
    case []: 0n
    case x <> t: Nat.add(Bool.pick(Nat, Nat.is_eq(qid(x), id), 1n, 0n), id_cnt(t, id))




def best_go(xs: List<&2, QP>, +all: List<&2, QP>, +m: QP, +es: List<&2, List<&2, QP>>, +i: Nat, +bi: Nat, +bd: F64) -> Nat:
  match xs:
    case []: bi
    case +p <> t:
      +d = d2(m, p)
      +ok = Bool.and(F64.is_lt(d, bd), Bool.and(Bool.not(q_same(p, m)),
        Bool.and(Nat.is_eq(id_cnt(all, qid(p)), 1n), vis(m, p, es))))
      best_go(t, all, m, es, Nat.add(i, 1n), Bool.pick(Nat, ok, i, bi), Bool.pick(F64, ok, d, bd))




def maxx_go(xs: List<&2, QP>, +i: Nat, +bi: Nat, +bx: F64) -> Nat:
  match xs:
    case []: bi
    case +p <> t:
      +b = F64.is_lt(bx, qx(p))
      maxx_go(t, Nat.add(i, 1n), Bool.pick(Nat, b, i, bi), Bool.pick(F64, b, qx(p), bx))




def q_take(xs: List<&2, QP>, +n: Nat) -> List<&2, QP>:
  match xs:
    case []: []
    case x <> t:
      match n:
        case 0n: []
        case 1n+m: x <> q_take(t, m)




def q_drop(xs: List<&2, QP>, +n: Nat) -> List<&2, QP>:
  match xs:
    case []: []
    case x <> +t:
      match n:
        case 0n: x <> t
        case 1n+m: q_drop(t, m)




def edges_all(hs: List<&2, List<&2, QP>>) -> List<&2, List<&2, QP>>:
  match hs:
    case []: []
    case h <> t: List.append(&2, List<&2, QP>, edges_of(h), edges_all(t))




def splice(+o: List<&2, QP>, +h: List<&2, QP>, +others: List<&2, List<&2, QP>>) -> List<&2, QP>:
  +im = maxx_go(h, 0n, 0n, F64.neg(F64.div(1.0f64, 0.0f64)))
  +m = q_nth(h, im)
  +es = List.append(&2, List<&2, QP>, edges_of(o), List.append(&2, List<&2, QP>, edges_of(h), edges_all(others)))
  +ip = best_go(o, o, m, es, 0n, 0n, F64.div(1.0f64, 0.0f64))
  +p = q_nth(o, ip)
  List.append(&2, QP, q_take(o, Nat.add(ip, 1n)), List.append(&2, QP, q_drop(h, im),
    List.append(&2, QP, q_take(h, im), m <> p <> q_drop(o, Nat.add(ip, 1n)))))




def bridge(hs: List<&2, List<&2, QP>>, +o: List<&2, QP>) -> List<&2, QP>:
  match hs:
    case []: o
    case h <> +t: bridge(t, splice(o, h, t))




def ql_len(+r: List<&2, QP>) -> Nat:
  List.length(&2, QP, r)




def tri_poly(+o: List<&2, QP>, +hs: List<&2, List<&2, QP>>) -> List<&2, Tri>:
  +r = bridge(hs, o)
  +n = ql_len(r)
  clip(Nat.add(Nat.mul(n, n), 8n), r, n, [])




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
  M.Pl{m, +tx, +ty, +tz} = pl
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




def body_obj(+b: M.Body) -> String:
  +br = M.bd_brep(b)
  +ps = all_pts(br)
  +tb = B.tb_of(V.Point, ps, pz())
  obj_vs(ps, M.bd_pl(b)) ++ obj_fs(faces_tris(Ty.brep_fas(br), ctx_of(br), tb))
