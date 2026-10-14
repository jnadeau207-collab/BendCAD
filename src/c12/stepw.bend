import Base
import ../base/num.bend as N
import ../base/par.bend as B
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c06/model.bend as M
import ../c06/tess.bend as TS
import ./blob.bend as BL

type WS is Data:
  WS{ ok: Bool, s: String, why: String, nent: Nat, nprod: Nat }

type ER is Data:
  ER{ ok: Bool, s: String, why: String, n: Nat }

type ER2 is Data:
  ER2{ ok: Bool, s: String, why: String, n: Nat, ids: List<&2, Nat> }

def ws_mk(+ok: Bool, +s: String, +why: String, +nent: Nat, +nprod: Nat) -> WS:
  WS{ok, s, why, nent, nprod}

def ws_ok(+r: WS) -> Bool:
  WS{ok, s, why, nent, nprod} = r
  ok

def ws_s(+r: WS) -> String:
  WS{ok, s, why, nent, nprod} = r
  s

def ws_why(+r: WS) -> String:
  WS{ok, s, why, nent, nprod} = r
  why

def ws_nent(+r: WS) -> Nat:
  WS{ok, s, why, nent, nprod} = r
  nent

def ws_nprod(+r: WS) -> Nat:
  WS{ok, s, why, nent, nprod} = r
  nprod

def er_ok(+s: String, +n: Nat) -> ER:
  ER{True{}, s, "", n}

def er_fail(+why: String, +n: Nat) -> ER:
  ER{False{}, "", why, n}

def er_ok_of(+r: ER) -> Bool:
  ER{ok, s, why, n} = r
  ok

def er_s(+r: ER) -> String:
  ER{ok, s, why, n} = r
  s

def er_why(+r: ER) -> String:
  ER{ok, s, why, n} = r
  why

def er_n(+r: ER) -> Nat:
  ER{ok, s, why, n} = r
  n

def er2_ok(+s: String, +n: Nat, +ids: List<&2, Nat>) -> ER2:
  ER2{True{}, s, "", n, ids}

def er2_fail(+why: String, +n: Nat) -> ER2:
  ER2{False{}, "", why, n, []}

def er2_ok_of(+r: ER2) -> Bool:
  ER2{ok, s, why, n, ids} = r
  ok

def er2_s(+r: ER2) -> String:
  ER2{ok, s, why, n, ids} = r
  s

def er2_why(+r: ER2) -> String:
  ER2{ok, s, why, n, ids} = r
  why

def er2_n(+r: ER2) -> Nat:
  ER2{ok, s, why, n, ids} = r
  n

def er2_ids(+r: ER2) -> List<&2, Nat>:
  ER2{ok, s, why, n, ids} = r
  ids

def er2_er(+r: ER2) -> ER:
  ER{er2_ok_of(r), er2_s(r), er2_why(r), er2_n(r)}

def er_cat_t2(+w: Bool, +a: ER, +b: ER) -> ER:
  match w:
    case True{}: ER{True{}, er_s(a) ++ er_s(b), "", er_n(b)}
    case False{}: b

def er_cat_t(+w: Bool, +a: ER, +b: ER) -> ER:
  match w:
    case True{}: er_cat_t2(er_ok_of(b), a, b)
    case False{}: a

def er_cat(+a: ER, +b: ER) -> ER:
  er_cat_t(er_ok_of(a), a, b)

def er2_cat_t2(+w: Bool, +a: ER2, +b: ER2) -> ER2:
  match w:
    case True{}: ER2{True{}, er2_s(a) ++ er2_s(b), "", er2_n(b), er2_ids(b)}
    case False{}: b

def er2_cat_t(+w: Bool, +a: ER2, +b: ER2) -> ER2:
  match w:
    case True{}: er2_cat_t2(er2_ok_of(b), a, b)
    case False{}: a

def er2_cat_s(+a: ER2, +b: ER2) -> ER2:
  er2_cat_t(er2_ok_of(a), a, b)

def st_has_dot(s: String) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{h, t}:
      +c = N.chr_code(h)
      Bool.or(Bool.or(U32.is_eq(c, 46), U32.is_eq(c, 101)), Bool.or(U32.is_eq(c, 69), st_has_dot(t)))

def st_fix_go(+dot: Bool, +s: String) -> String:
  match dot:
    case True{}: s
    case False{}: s ++ ".0"

def st_fix(+s: String) -> String:
  st_fix_go(st_has_dot(s), s)

def st_fin(+v: F64) -> Bool:
  Bool.and(F64.is_le(F64.neg(1.7976931348623157e308f64), v),
    F64.is_le(v, 1.7976931348623157e308f64))

def sw_f_t2(+w: Bool, +r: BL.NS) -> BL.NS:
  match w:
    case True{}: BL.ns_mk(True{}, st_fix(BL.ns_s(r)))
    case False{}: BL.ns_mk(False{}, BL.ns_s(r))

def sw_f_t(+r: BL.NS, +v: F64) -> BL.NS:
  sw_f_t2(Bool.and(BL.ns_ok(r), st_fin(v)), r)

def sw_f(+v: F64) -> BL.NS:
  sw_f_t(BL.st_num(v), v)

def sw_why1(+r: BL.NS) -> String:
  "step-float-not-exact " ++ BL.ns_s(r)

def sw_why_pick(+w: Bool, +a: BL.NS, +b: BL.NS) -> String:
  match w:
    case True{}: sw_why1(b)
    case False{}: sw_why1(a)

def sw_why_pick3(+wa: Bool, +wb: Bool, +a: BL.NS, +b: BL.NS, +c: BL.NS) -> String:
  match wa:
    case False{}: sw_why1(a)
    case True{}: sw_why_pick(wb, b, c)

def sw_es3_t(+w: Bool, +a: BL.NS, +b: BL.NS, +c: BL.NS, +o: String, +m: String, +p: String,
    +e: String) -> BL.ES:
  match w:
    case True{}: BL.es_ok(o ++ BL.ns_s(a) ++ m ++ BL.ns_s(b) ++ p ++ BL.ns_s(c) ++ e)
    case False{}: BL.es_fail(sw_why_pick3(BL.ns_ok(a), BL.ns_ok(b), a, b, c))

def sw_es3(+a: BL.NS, +b: BL.NS, +c: BL.NS, +o: String, +m: String, +p: String, +e: String) -> BL.ES:
  sw_es3_t(Bool.and(BL.ns_ok(a), Bool.and(BL.ns_ok(b), BL.ns_ok(c))), a, b, c, o, m, p, e)

def sw_pt(+p: V.Point) -> BL.ES:
  sw_es3(sw_f(V.pt_x(p)), sw_f(V.pt_y(p)), sw_f(V.pt_z(p)), "(", ",", ",", ")")

def sw_dir(+d: V.Dir) -> BL.ES:
  sw_es3(sw_f(V.dr_x(d)), sw_f(V.dr_y(d)), sw_f(V.dr_z(d)), "(", ",", ",", ")")

def sw_ent(+id: Nat, +body: String) -> String:
  "#" ++ Nat.show(id) ++ "=" ++ body ++ ";\n"

def sw_ref(+id: Nat) -> String:
  "#" ++ Nat.show(id)

def sw_dmap(+d: V.Dir, +pl: M.Pl) -> V.Dir:
  M.Pl{+m, +tx, +ty, +tz, +mi, +ti} = pl
  +v = M.m3_ap(m, V.dr_x(d), V.dr_y(d), V.dr_z(d))
  V.Dr{M.f_nth(v, 0n), M.f_nth(v, 1n), M.f_nth(v, 2n)}

def sw_norm(+d: V.Dir) -> V.Dir:
  BL.norm3(V.dr_x(d), V.dr_y(d), V.dr_z(d))

def sw_vpt_t2(+w: Bool, +e: BL.ES, +ctr: Nat) -> ER:
  match w:
    case True{}: er_ok(sw_ent(ctr, "CARTESIAN_POINT(''," ++ BL.es_s(e) ++ ")"), Nat.add(ctr, 1n))
    case False{}: er_fail(BL.es_why(e), Nat.add(ctr, 1n))

def sw_vpt_t(+e: BL.ES, +ctr: Nat) -> ER:
  sw_vpt_t2(BL.es_ok_of(e), e, ctr)

def sw_vpt(+v: Ty.Vertex, +pl: M.Pl, +ctr: Nat) -> ER:
  sw_vpt_t(sw_pt(TS.pl_pt(Ty.vx_p(v), pl)), ctr)

def sw_vpts_go(vs: List<&2, Ty.Vertex>, +pl: M.Pl, +ctr: Nat) -> ER:
  match vs:
    case []: ER{True{}, "", "", ctr}
    case v <> t:
      +r = sw_vpt(v, pl, ctr)
      +rr = sw_vpts_go(t, pl, er_n(r))
      er_cat(r, rr)

def sw_line_t(+w: Bool, +e: BL.ES, +i0: Nat, +vbase: Nat, +ctr: Nat) -> ER2:
  match w:
    case False{}: er2_fail(BL.es_why(e), Nat.add(ctr, 3n))
    case True{}:
      er2_ok(sw_ent(ctr, "DIRECTION(''," ++ BL.es_s(e) ++ ")") ++
        sw_ent(Nat.add(ctr, 1n), "VECTOR(''," ++ sw_ref(ctr) ++ ",1.0)") ++
        sw_ent(Nat.add(ctr, 2n), "LINE(''," ++ sw_ref(Nat.add(vbase, i0)) ++ "," ++
          sw_ref(Nat.add(ctr, 1n)) ++ ")"),
        Nat.add(ctr, 3n), [Nat.add(ctr, 2n)])

def sw_line(+w: G.Line3, +i0: Nat, +pl: M.Pl, +vbase: Nat, +ctr: Nat) -> ER2:
  G.Ln{+p, +d} = w
  +e = sw_dir(sw_norm(sw_dmap(d, pl)))
  sw_line_t(BL.es_ok_of(e), e, i0, vbase, ctr)

def sw_ns(+r: BL.ES) -> BL.NS:
  BL.ns_mk(BL.es_ok_of(r), BL.es_s(r))

def sw_axis2_t(+w: Bool, +a: BL.ES, +b: BL.ES, +c: BL.ES, +ctr: Nat) -> BL.ES:
  match w:
    case False{}: BL.es_fail(sw_why_pick3(BL.es_ok_of(a), BL.es_ok_of(b), sw_ns(a), sw_ns(b), sw_ns(c)))
    case True{}:
      BL.es_ok(sw_ent(ctr, "CARTESIAN_POINT(''," ++ BL.es_s(a) ++ ")") ++
        sw_ent(Nat.add(ctr, 1n), "DIRECTION(''," ++ BL.es_s(b) ++ ")") ++
        sw_ent(Nat.add(ctr, 2n), "DIRECTION(''," ++ BL.es_s(c) ++ ")") ++
        sw_ent(Nat.add(ctr, 3n), "AXIS2_PLACEMENT_3D(''," ++ sw_ref(ctr) ++ "," ++
          sw_ref(Nat.add(ctr, 1n)) ++ "," ++ sw_ref(Nat.add(ctr, 2n)) ++ ")"))

def sw_axis2(+loc: V.Point, +ax: V.Dir, +rf: V.Dir, +ctr: Nat) -> BL.ES:
  +a = sw_pt(loc)
  +b = sw_dir(ax)
  +c = sw_dir(rf)
  sw_axis2_t(Bool.and(BL.es_ok_of(a), Bool.and(BL.es_ok_of(b), BL.es_ok_of(c))), a, b, c, ctr)

def sw_circ_full_t(+w: Bool, +e: BL.ES, +f: BL.NS, +ctr: Nat) -> ER2:
  match w:
    case False{}: er2_fail(sw_why_pick(BL.es_ok_of(e), sw_ns(e), f), Nat.add(ctr, 5n))
    case True{}:
      er2_ok(BL.es_s(e) ++ sw_ent(Nat.add(ctr, 4n), "CIRCLE(''," ++ sw_ref(Nat.add(ctr, 3n)) ++ "," ++
        BL.ns_s(f) ++ ")"),
        Nat.add(ctr, 5n), [Nat.add(ctr, 4n)])

def sw_circ_full(+cc: G.Circle3, +pl: M.Pl, +ctr: Nat) -> ER2:
  G.Cc{+c, +u, +v, +r} = cc
  +mc = TS.pl_pt(c, pl)
  +mu = sw_dmap(u, pl)
  +mv = sw_dmap(v, pl)
  +ax = BL.cross3(V.dr_x(mu), V.dr_y(mu), V.dr_z(mu), V.dr_x(mv), V.dr_y(mv), V.dr_z(mv))
  +e = sw_axis2(mc, ax, mu, ctr)
  +f = sw_f(r)
  sw_circ_full_t(Bool.and(BL.es_ok_of(e), BL.ns_ok(f)), e, f, ctr)

def sw_circ_trim_t(+w: Bool, +e: BL.ES, +f: BL.NS, +i0: Nat, +i1: Nat, +vbase: Nat, +ctr: Nat) -> ER2:
  match w:
    case False{}: er2_fail(sw_why_pick(BL.es_ok_of(e), sw_ns(e), f), Nat.add(ctr, 6n))
    case True{}:
      er2_ok(BL.es_s(e) ++
        sw_ent(Nat.add(ctr, 4n), "CIRCLE(''," ++ sw_ref(Nat.add(ctr, 3n)) ++ "," ++ BL.ns_s(f) ++
          ")") ++
        sw_ent(Nat.add(ctr, 5n), "TRIMMED_CURVE(''," ++ sw_ref(Nat.add(ctr, 4n)) ++ ",(" ++
          sw_ref(Nat.add(vbase, i0)) ++ "),(" ++ sw_ref(Nat.add(vbase, i1)) ++ "),.T.,.CARTESIAN.)"),
        Nat.add(ctr, 6n), [Nat.add(ctr, 5n)])

def sw_circ_trim(+cc: G.Circle3, +i0: Nat, +i1: Nat, +pl: M.Pl, +vbase: Nat, +ctr: Nat) -> ER2:
  G.Cc{+c, +u, +v, +r} = cc
  +mc = TS.pl_pt(c, pl)
  +mu = sw_dmap(u, pl)
  +mv = sw_dmap(v, pl)
  +ax = BL.cross3(V.dr_x(mu), V.dr_y(mu), V.dr_z(mu), V.dr_x(mv), V.dr_y(mv), V.dr_z(mv))
  +e = sw_axis2(mc, ax, mu, ctr)
  +f = sw_f(r)
  sw_circ_trim_t(Bool.and(BL.es_ok_of(e), BL.ns_ok(f)), e, f, i0, i1, vbase, ctr)

def sw_circ_t(+w: Bool, +cc: G.Circle3, +i0: Nat, +i1: Nat, +pl: M.Pl, +vbase: Nat, +ctr: Nat) -> ER2:
  match w:
    case True{}: sw_circ_full(cc, pl, ctr)
    case False{}: sw_circ_trim(cc, i0, i1, pl, vbase, ctr)

def sw_circ(+w: G.Circle3, +lo: F64, +hi: F64, +i0: Nat, +i1: Nat, +pl: M.Pl, +vbase: Nat,
    +ctr: Nat) -> ER2:
  sw_circ_t(Bool.and(Nat.is_eq(i0, i1),
    Bool.and(F64.is_eq(lo, F64.neg(1.0f64)), F64.is_eq(hi, 1.0f64))), w, i0, i1, pl, vbase, ctr)

def sw_ns_bc_t(+w: Bool, +b: BL.ES, +c: BL.ES) -> BL.NS:
  match w:
    case True{}: BL.ns_mk(True{}, "")
    case False{}: BL.ns_mk(False{}, sw_why_pick(BL.es_ok_of(b), sw_ns(b), sw_ns(c)))

def sw_ns_bc(+b: BL.ES, +c: BL.ES) -> BL.NS:
  sw_ns_bc_t(Bool.and(BL.es_ok_of(b), BL.es_ok_of(c)), b, c)

def sw_ns_w_t(+w: Bool, +d: BL.NS, +e: BL.NS, +f: BL.NS) -> BL.NS:
  match w:
    case True{}: BL.ns_mk(True{}, "")
    case False{}: BL.ns_mk(False{}, sw_why_pick3(BL.ns_ok(d), BL.ns_ok(e), d, e, f))

def sw_ns_w(+d: BL.NS, +e: BL.NS, +f: BL.NS) -> BL.NS:
  sw_ns_w_t(Bool.and(BL.ns_ok(d), Bool.and(BL.ns_ok(e), BL.ns_ok(f))), d, e, f)

def sw_why_rq(+a: BL.ES, +b: BL.ES, +c: BL.ES, +d: BL.NS, +e: BL.NS, +f: BL.NS) -> String:
  sw_why_pick3(BL.es_ok_of(a), Bool.and(BL.es_ok_of(b), BL.es_ok_of(c)), sw_ns(a), sw_ns_bc(b, c),
    sw_ns_w(d, e, f))

def sw_rq_go(+w: Bool, +a: BL.ES, +b: BL.ES, +c: BL.ES, +d: BL.NS, +e: BL.NS, +f: BL.NS,
    +ctr: Nat) -> ER2:
  match w:
    case False{}: er2_fail(sw_why_rq(a, b, c, d, e, f), Nat.add(ctr, 4n))
    case True{}:
      er2_ok(sw_ent(ctr, "CARTESIAN_POINT(''," ++ BL.es_s(a) ++ ")") ++
        sw_ent(Nat.add(ctr, 1n), "CARTESIAN_POINT(''," ++ BL.es_s(b) ++ ")") ++
        sw_ent(Nat.add(ctr, 2n), "CARTESIAN_POINT(''," ++ BL.es_s(c) ++ ")") ++
        sw_ent(Nat.add(ctr, 3n), "(BOUNDED_CURVE()B_SPLINE_CURVE(2,(" ++ sw_ref(ctr) ++ "," ++
          sw_ref(Nat.add(ctr, 1n)) ++ "," ++ sw_ref(Nat.add(ctr, 2n)) ++ "),.UNSPECIFIED.,.F.,.F.)" ++
          "B_SPLINE_CURVE_WITH_KNOTS((3,3),(0.,1.),.PIECEWISE_BEZIER_KNOTS.)CURVE()" ++
          "GEOMETRIC_REPRESENTATION_ITEM()RATIONAL_B_SPLINE_CURVE((" ++ BL.ns_s(d) ++ "," ++
          BL.ns_s(e) ++ "," ++ BL.ns_s(f) ++ "))REPRESENTATION_ITEM(''))"),
        Nat.add(ctr, 4n), [Nat.add(ctr, 3n)])

def sw_rq_t(+w: Bool, +rq: G.RQBez, +pl: M.Pl, +ctr: Nat) -> ER2:
  match w:
    case False{}: er2_fail("step-bspline-dom-not-unit", Nat.add(ctr, 4n))
    case True{}:
      G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = rq
      +a = sw_pt(TS.pl_pt(p0, pl))
      +b = sw_pt(TS.pl_pt(p1, pl))
      +c = sw_pt(TS.pl_pt(p2, pl))
      +d = sw_f(w0)
      +e = sw_f(w1)
      +f = sw_f(w2)
      sw_rq_go(Bool.and(BL.es_ok_of(a), Bool.and(BL.es_ok_of(b), Bool.and(BL.es_ok_of(c),
        Bool.and(BL.ns_ok(d), Bool.and(BL.ns_ok(e), BL.ns_ok(f)))))), a, b, c, d, e, f, ctr)

def sw_rq(+w: G.RQBez, +lo: F64, +hi: F64, +pl: M.Pl, +ctr: Nat) -> ER2:
  sw_rq_t(Bool.and(F64.is_eq(lo, 0.0f64), F64.is_eq(hi, 1.0f64)), w, pl, ctr)

def sw_why_bz(+a: BL.ES, +b: BL.ES, +c: BL.ES, +d: BL.ES) -> String:
  sw_why_pick3(BL.es_ok_of(a), Bool.and(BL.es_ok_of(b), BL.es_ok_of(c)), sw_ns(a), sw_ns_bc(b, c),
    sw_ns(d))

def sw_bz_go(+w: Bool, +a: BL.ES, +b: BL.ES, +c: BL.ES, +d: BL.ES, +ctr: Nat) -> ER2:
  match w:
    case False{}: er2_fail(sw_why_bz(a, b, c, d), Nat.add(ctr, 5n))
    case True{}:
      er2_ok(sw_ent(ctr, "CARTESIAN_POINT(''," ++ BL.es_s(a) ++ ")") ++
        sw_ent(Nat.add(ctr, 1n), "CARTESIAN_POINT(''," ++ BL.es_s(b) ++ ")") ++
        sw_ent(Nat.add(ctr, 2n), "CARTESIAN_POINT(''," ++ BL.es_s(c) ++ ")") ++
        sw_ent(Nat.add(ctr, 3n), "CARTESIAN_POINT(''," ++ BL.es_s(d) ++ ")") ++
        sw_ent(Nat.add(ctr, 4n), "B_SPLINE_CURVE_WITH_KNOTS('',3,(" ++ sw_ref(ctr) ++ "," ++
          sw_ref(Nat.add(ctr, 1n)) ++ "," ++ sw_ref(Nat.add(ctr, 2n)) ++ "," ++
          sw_ref(Nat.add(ctr, 3n)) ++ "),.UNSPECIFIED.,.F.,.F.,(4,4),(0.,1.),.PIECEWISE_BEZIER_KNOTS.)"),
        Nat.add(ctr, 5n), [Nat.add(ctr, 4n)])

def sw_bz_t(+w: Bool, +bz: G.Bez3, +pl: M.Pl, +ctr: Nat) -> ER2:
  match w:
    case False{}: er2_fail("step-bspline-dom-not-unit", Nat.add(ctr, 5n))
    case True{}:
      G.Bz{+p0, +p1, +p2, +p3} = bz
      +a = sw_pt(TS.pl_pt(p0, pl))
      +b = sw_pt(TS.pl_pt(p1, pl))
      +c = sw_pt(TS.pl_pt(p2, pl))
      +d = sw_pt(TS.pl_pt(p3, pl))
      sw_bz_go(Bool.and(BL.es_ok_of(a), Bool.and(BL.es_ok_of(b), Bool.and(BL.es_ok_of(c),
        BL.es_ok_of(d)))), a, b, c, d, ctr)

def sw_bz(+w: G.Bez3, +lo: F64, +hi: F64, +pl: M.Pl, +ctr: Nat) -> ER2:
  sw_bz_t(Bool.and(F64.is_eq(lo, 0.0f64), F64.is_eq(hi, 1.0f64)), w, pl, ctr)

def sw_curve_cv(+curve: G.GVal, +lo: F64, +hi: F64, +i0: Nat, +i1: Nat, +pl: M.Pl, +vbase: Nat,
    +ctr: Nat) -> ER2:
  match curve:
    case G.GV_ln{w}: sw_line(w, i0, pl, vbase, ctr)
    case G.GV_cc{w}: sw_circ(w, lo, hi, i0, i1, pl, vbase, ctr)
    case G.GV_rq{w}: sw_rq(w, lo, hi, pl, ctr)
    case G.GV_bz{w}: sw_bz(w, lo, hi, pl, ctr)
    case _: er2_fail("step-curve-not-in-profile " ++ BL.gv_nm(curve), ctr)

def sw_curve_kind(+k: Ty.EdgeKind, +e: Ty.Edge, +i0: Nat, +i1: Nat, +pl: M.Pl, +vbase: Nat,
    +ctr: Nat) -> ER2:
  match k:
    case Ty.EK_degenerate{}: er2_fail("step-degenerate-edge-not-in-profile", ctr)
    case Ty.EK_curve{+curve, +dom}: sw_curve_cv(curve, G.dom_lo(dom), G.dom_hi(dom), i0, i1, pl,
      vbase, ctr)

def sw_curve_t2(+w: Bool, +e: Ty.Edge, +i0: Nat, +i1: Nat, +pl: M.Pl, +vbase: Nat, +ctr: Nat) -> ER2:
  match w:
    case False{}: er2_fail("step-index-out-of-range", ctr)
    case True{}: sw_curve_kind(Ty.ed_kind(e), e, i0, i1, pl, vbase, ctr)

def sw_curve(+e: Ty.Edge, +nv: Nat, +pl: M.Pl, +vbase: Nat, +ctr: Nat) -> ER2:
  +i0 = BL.hv_i(Ty.ed_v0(e))
  +i1 = BL.hv_i(Ty.ed_v1(e))
  sw_curve_t2(Bool.and(Nat.is_lt(i0, nv), Nat.is_lt(i1, nv)), e, i0, i1, pl, vbase, ctr)

def sw_curves_go(es: List<&2, Ty.Edge>, +nv: Nat, +pl: M.Pl, +vbase: Nat, +ctr: Nat,
    +acc: List<&2, Nat>) -> ER2:
  match es:
    case []: ER2{True{}, "", "", ctr, List.reverse(&2, Nat, acc)}
    case e <> t:
      +r = sw_curve(e, nv, pl, vbase, ctr)
      +rr = sw_curves_go(t, nv, pl, vbase, er2_n(r), List.append(&2, Nat, er2_ids(r), acc))
      er2_cat_s(r, rr)

def sw_surf_pl_t(+w: Bool, +e: BL.ES, +ctr: Nat) -> ER2:
  match w:
    case False{}: er2_fail(BL.es_why(e), Nat.add(ctr, 5n))
    case True{}:
      er2_ok(BL.es_s(e) ++ sw_ent(Nat.add(ctr, 4n), "PLANE(''," ++ sw_ref(Nat.add(ctr, 3n)) ++ ")"),
        Nat.add(ctr, 5n), [Nat.add(ctr, 4n)])

def sw_surf_pl(+w: G.Plane3, +pl: M.Pl, +ctr: Nat) -> ER2:
  G.Pl{+o, +u, +v} = w
  +mo = TS.pl_pt(o, pl)
  +mu = sw_dmap(u, pl)
  +mv = sw_dmap(v, pl)
  +ax = BL.cross3(V.dr_x(mu), V.dr_y(mu), V.dr_z(mu), V.dr_x(mv), V.dr_y(mv), V.dr_z(mv))
  +e = sw_axis2(mo, ax, mu, ctr)
  sw_surf_pl_t(BL.es_ok_of(e), e, ctr)

def sw_surf_sp_t(+w: Bool, +e: BL.ES, +f: BL.NS, +ctr: Nat) -> ER2:
  match w:
    case False{}: er2_fail(sw_why_pick(BL.es_ok_of(e), sw_ns(e), f), Nat.add(ctr, 5n))
    case True{}:
      er2_ok(BL.es_s(e) ++ sw_ent(Nat.add(ctr, 4n), "SPHERICAL_SURFACE(''," ++ sw_ref(Nat.add(ctr,
        3n)) ++ "," ++ BL.ns_s(f) ++ ")"),
        Nat.add(ctr, 5n), [Nat.add(ctr, 4n)])

def sw_surf_sp(+w: G.Sphere, +pl: M.Pl, +ctr: Nat) -> ER2:
  G.Sp{+c, +r} = w
  +e = sw_axis2(TS.pl_pt(c, pl), V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, ctr)
  +f = sw_f(r)
  sw_surf_sp_t(Bool.and(BL.es_ok_of(e), BL.ns_ok(f)), e, f, ctr)

def sw_surf_cy_t(+w: Bool, +e: BL.ES, +f: BL.NS, +ctr: Nat) -> ER2:
  match w:
    case False{}: er2_fail(sw_why_pick(BL.es_ok_of(e), sw_ns(e), f), Nat.add(ctr, 5n))
    case True{}:
      er2_ok(BL.es_s(e) ++ sw_ent(Nat.add(ctr, 4n), "CYLINDRICAL_SURFACE(''," ++ sw_ref(Nat.add(ctr,
        3n)) ++ "," ++ BL.ns_s(f) ++ ")"),
        Nat.add(ctr, 5n), [Nat.add(ctr, 4n)])

def sw_surf_cy(+w: G.Cyl, +pl: M.Pl, +ctr: Nat) -> ER2:
  G.Cy{+o, +a, +r} = w
  +ma = sw_norm(sw_dmap(a, pl))
  +e = sw_axis2(TS.pl_pt(o, pl), ma, BL.perp_of(V.dr_x(ma), V.dr_y(ma), V.dr_z(ma)), ctr)
  +f = sw_f(r)
  sw_surf_cy_t(Bool.and(BL.es_ok_of(e), BL.ns_ok(f)), e, f, ctr)

def sw_surf_to_t(+w: Bool, +e: BL.ES, +f: BL.NS, +g: BL.NS, +ctr: Nat) -> ER2:
  match w:
    case False{}: er2_fail(sw_why_pick3(BL.es_ok_of(e), BL.ns_ok(f), sw_ns(e), f, g),
      Nat.add(ctr, 5n))
    case True{}:
      er2_ok(BL.es_s(e) ++ sw_ent(Nat.add(ctr, 4n), "TOROIDAL_SURFACE(''," ++ sw_ref(Nat.add(ctr,
        3n)) ++ "," ++ BL.ns_s(f) ++ "," ++ BL.ns_s(g) ++ ")"),
        Nat.add(ctr, 5n), [Nat.add(ctr, 4n)])

def sw_surf_to(+w: G.Torus, +pl: M.Pl, +ctr: Nat) -> ER2:
  G.To{+o, +a, +R, +r} = w
  +ma = sw_norm(sw_dmap(a, pl))
  +e = sw_axis2(TS.pl_pt(o, pl), ma, BL.perp_of(V.dr_x(ma), V.dr_y(ma), V.dr_z(ma)), ctr)
  +f = sw_f(R)
  +g = sw_f(r)
  sw_surf_to_t(Bool.and(BL.es_ok_of(e), Bool.and(BL.ns_ok(f), BL.ns_ok(g))), e, f, g, ctr)

def sw_bp_ok(+e00: BL.ES, +e01: BL.ES, +e02: BL.ES, +e03: BL.ES, +e10: BL.ES, +e11: BL.ES,
    +e12: BL.ES, +e13: BL.ES, +e20: BL.ES, +e21: BL.ES, +e22: BL.ES, +e23: BL.ES, +e30: BL.ES,
    +e31: BL.ES, +e32: BL.ES, +e33: BL.ES) -> Bool:
  Bool.and(BL.es_ok_of(e00), Bool.and(BL.es_ok_of(e01), Bool.and(BL.es_ok_of(e02),
    Bool.and(BL.es_ok_of(e03), Bool.and(BL.es_ok_of(e10), Bool.and(BL.es_ok_of(e11),
      Bool.and(BL.es_ok_of(e12), Bool.and(BL.es_ok_of(e13), Bool.and(BL.es_ok_of(e20),
        Bool.and(BL.es_ok_of(e21), Bool.and(BL.es_ok_of(e22), Bool.and(BL.es_ok_of(e23),
          Bool.and(BL.es_ok_of(e30), Bool.and(BL.es_ok_of(e31), Bool.and(BL.es_ok_of(e32),
            BL.es_ok_of(e33))))))))))))))))

def sw_bp_row(+e0: BL.ES, +e1: BL.ES, +e2: BL.ES, +e3: BL.ES, +ctr: Nat) -> String:
  sw_ent(ctr, "CARTESIAN_POINT(''," ++ BL.es_s(e0) ++ ")") ++
    sw_ent(Nat.add(ctr, 1n), "CARTESIAN_POINT(''," ++ BL.es_s(e1) ++ ")") ++
    sw_ent(Nat.add(ctr, 2n), "CARTESIAN_POINT(''," ++ BL.es_s(e2) ++ ")") ++
    sw_ent(Nat.add(ctr, 3n), "CARTESIAN_POINT(''," ++ BL.es_s(e3) ++ ")")

def sw_bp_why3_pick(+w: Bool, +e: BL.ES, +rest: String) -> String:
  match w:
    case False{}: BL.es_why(e)
    case True{}: rest

def sw_bp_why3(es: List<&2, BL.ES>) -> String:
  match es:
    case []: "step-float-not-exact"
    case +e <> t: sw_bp_why3_pick(BL.es_ok_of(e), e, sw_bp_why3(t))

def sw_bp_why_t2(+w: Bool, +e01: BL.ES, +e02: BL.ES, +e03: BL.ES, +e10: BL.ES, +e11: BL.ES,
    +e12: BL.ES, +e13: BL.ES, +e20: BL.ES, +e21: BL.ES, +e22: BL.ES, +e23: BL.ES, +e30: BL.ES,
    +e31: BL.ES, +e32: BL.ES, +e33: BL.ES) -> String:
  match w:
    case False{}: BL.es_why(e01)
    case True{}: sw_bp_why3([e02, e03, e10, e11, e12, e13, e20, e21, e22, e23, e30, e31, e32, e33])

def sw_bp_why2(+e01: BL.ES, +e02: BL.ES, +e03: BL.ES, +e10: BL.ES, +e11: BL.ES, +e12: BL.ES,
    +e13: BL.ES, +e20: BL.ES, +e21: BL.ES, +e22: BL.ES, +e23: BL.ES, +e30: BL.ES, +e31: BL.ES,
    +e32: BL.ES, +e33: BL.ES) -> String:
  sw_bp_why_t2(BL.es_ok_of(e01), e01, e02, e03, e10, e11, e12, e13, e20, e21, e22, e23, e30, e31, e32,
    e33)

def sw_bp_why_t(+w: Bool, +e00: BL.ES, +e01: BL.ES, +e02: BL.ES, +e03: BL.ES, +e10: BL.ES, +e11: BL.ES,
    +e12: BL.ES, +e13: BL.ES, +e20: BL.ES, +e21: BL.ES, +e22: BL.ES, +e23: BL.ES, +e30: BL.ES,
    +e31: BL.ES, +e32: BL.ES, +e33: BL.ES) -> String:
  match w:
    case False{}: BL.es_why(e00)
    case True{}: sw_bp_why2(e01, e02, e03, e10, e11, e12, e13, e20, e21, e22, e23, e30, e31, e32, e33)

def sw_bp_why(+e00: BL.ES, +e01: BL.ES, +e02: BL.ES, +e03: BL.ES, +e10: BL.ES, +e11: BL.ES,
    +e12: BL.ES, +e13: BL.ES, +e20: BL.ES, +e21: BL.ES, +e22: BL.ES, +e23: BL.ES, +e30: BL.ES,
    +e31: BL.ES, +e32: BL.ES, +e33: BL.ES) -> String:
  sw_bp_why_t(BL.es_ok_of(e00), e00, e01, e02, e03, e10, e11, e12, e13, e20, e21, e22, e23, e30, e31,
    e32, e33)

def sw_bp_pts_t(+w: Bool, +e00: BL.ES, +e01: BL.ES, +e02: BL.ES, +e03: BL.ES, +e10: BL.ES, +e11: BL.ES,
    +e12: BL.ES, +e13: BL.ES, +e20: BL.ES, +e21: BL.ES, +e22: BL.ES, +e23: BL.ES, +e30: BL.ES,
    +e31: BL.ES, +e32: BL.ES, +e33: BL.ES, +ctr: Nat) -> ER2:
  match w:
    case False{}: er2_fail(sw_bp_why(e00, e01, e02, e03, e10, e11, e12, e13, e20, e21, e22, e23, e30,
      e31, e32, e33), Nat.add(ctr, 17n))
    case True{}:
      er2_ok(sw_bp_row(e00, e01, e02, e03, ctr) ++ sw_bp_row(e10, e11, e12, e13, Nat.add(ctr, 4n)) ++
        sw_bp_row(e20, e21, e22, e23, Nat.add(ctr, 8n)) ++
        sw_bp_row(e30, e31, e32, e33, Nat.add(ctr, 12n)) ++
        sw_ent(Nat.add(ctr, 16n), "B_SPLINE_SURFACE_WITH_KNOTS('',3,3,((" ++ sw_ref(ctr) ++ "," ++
          sw_ref(Nat.add(ctr, 1n)) ++ "," ++ sw_ref(Nat.add(ctr, 2n)) ++ "," ++
          sw_ref(Nat.add(ctr, 3n)) ++ "),(" ++ sw_ref(Nat.add(ctr, 4n)) ++ "," ++
          sw_ref(Nat.add(ctr, 5n)) ++ "," ++ sw_ref(Nat.add(ctr, 6n)) ++ "," ++
          sw_ref(Nat.add(ctr, 7n)) ++ "),(" ++ sw_ref(Nat.add(ctr, 8n)) ++ "," ++
          sw_ref(Nat.add(ctr, 9n)) ++ "," ++ sw_ref(Nat.add(ctr, 10n)) ++ "," ++
          sw_ref(Nat.add(ctr, 11n)) ++ "),(" ++ sw_ref(Nat.add(ctr, 12n)) ++ "," ++
          sw_ref(Nat.add(ctr, 13n)) ++ "," ++ sw_ref(Nat.add(ctr, 14n)) ++ "," ++
          sw_ref(Nat.add(ctr, 15n)) ++ ")),.UNSPECIFIED.,.F.,.F.,.F.,(4,4),(4,4),(0.,1.)," ++
          "(0.,1.),.PIECEWISE_BEZIER_KNOTS.)"),
        Nat.add(ctr, 17n), [Nat.add(ctr, 16n)])

def sw_bp_pts(+w: G.BezP, +pl: M.Pl, +ctr: Nat) -> ER2:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32,
    +p33} = w
  +e00 = sw_pt(TS.pl_pt(p00, pl))
  +e01 = sw_pt(TS.pl_pt(p01, pl))
  +e02 = sw_pt(TS.pl_pt(p02, pl))
  +e03 = sw_pt(TS.pl_pt(p03, pl))
  +e10 = sw_pt(TS.pl_pt(p10, pl))
  +e11 = sw_pt(TS.pl_pt(p11, pl))
  +e12 = sw_pt(TS.pl_pt(p12, pl))
  +e13 = sw_pt(TS.pl_pt(p13, pl))
  +e20 = sw_pt(TS.pl_pt(p20, pl))
  +e21 = sw_pt(TS.pl_pt(p21, pl))
  +e22 = sw_pt(TS.pl_pt(p22, pl))
  +e23 = sw_pt(TS.pl_pt(p23, pl))
  +e30 = sw_pt(TS.pl_pt(p30, pl))
  +e31 = sw_pt(TS.pl_pt(p31, pl))
  +e32 = sw_pt(TS.pl_pt(p32, pl))
  +e33 = sw_pt(TS.pl_pt(p33, pl))
  sw_bp_pts_t(sw_bp_ok(e00, e01, e02, e03, e10, e11, e12, e13, e20, e21, e22, e23, e30, e31, e32, e33),
    e00, e01, e02, e03, e10, e11, e12, e13, e20, e21, e22, e23, e30, e31, e32, e33, ctr)

def sw_surf_kind(+g: G.GVal, +pl: M.Pl, +ctr: Nat) -> ER2:
  match g:
    case G.GV_pl{w}: sw_surf_pl(w, pl, ctr)
    case G.GV_sp{w}: sw_surf_sp(w, pl, ctr)
    case G.GV_cy{w}: sw_surf_cy(w, pl, ctr)
    case G.GV_to{w}: sw_surf_to(w, pl, ctr)
    case G.GV_bp{w}: sw_bp_pts(w, pl, ctr)
    case _: er2_fail("step-surface-not-in-profile " ++ BL.gv_nm(g), ctr)

def sw_surf(+f: Ty.Face, +pl: M.Pl, +ctr: Nat) -> ER2:
  sw_surf_kind(Ty.fa_surf(f), pl, ctr)

def sw_surfs_go(fs: List<&2, Ty.Face>, +pl: M.Pl, +ctr: Nat, +acc: List<&2, Nat>) -> ER2:
  match fs:
    case []: ER2{True{}, "", "", ctr, List.reverse(&2, Nat, acc)}
    case f <> t:
      +r = sw_surf(f, pl, ctr)
      +rr = sw_surfs_go(t, pl, er2_n(r), List.append(&2, Nat, er2_ids(r), acc))
      er2_cat_s(r, rr)

def sw_vx(+i: Nat, +vbase: Nat, +ctr: Nat) -> ER:
  er_ok(sw_ent(ctr, "VERTEX_POINT(''," ++ sw_ref(Nat.add(vbase, i)) ++ ")"), Nat.add(ctr, 1n))

def sw_vxs_go(+k: Nat, +nv: Nat, +vbase: Nat, +ctr: Nat) -> ER:
  match k:
    case 0n: ER{True{}, "", "", ctr}
    case 1n+j:
      +r = sw_vx(Nat.sub(nv, k), vbase, ctr)
      +rr = sw_vxs_go(j, nv, vbase, er_n(r))
      er_cat(r, rr)

def sw_ecurve(+cid: Nat, +i0: Nat, +i1: Nat, +vxs: Nat, +ctr: Nat) -> ER:
  er_ok(sw_ent(ctr, "EDGE_CURVE(''," ++ sw_ref(Nat.add(vxs, i0)) ++ "," ++ sw_ref(Nat.add(vxs, i1)) ++
    "," ++ sw_ref(cid) ++ ",.T.)"), Nat.add(ctr, 1n))

def sw_ecurve_t2(+w: Bool, +cid: Nat, +i0: Nat, +i1: Nat, +vxs: Nat, +ctr: Nat) -> ER:
  match w:
    case False{}: er_fail("step-index-out-of-range", Nat.add(ctr, 1n))
    case True{}: sw_ecurve(cid, i0, i1, vxs, ctr)

def sw_ecurves_go(es: List<&2, Ty.Edge>, +ids: List<&2, Nat>, +nv: Nat, +vxs: Nat, +ctr: Nat) -> ER:
  match es:
    case []: ER{True{}, "", "", ctr}
    case +e <> t:
      match ids:
        case []: ER{False{}, "", "step-internal-id-mismatch", ctr}
        case +cid <> tids:
          +i0 = BL.hv_i(Ty.ed_v0(e))
          +i1 = BL.hv_i(Ty.ed_v1(e))
          +r = sw_ecurve_t2(Bool.and(Nat.is_lt(i0, nv), Nat.is_lt(i1, nv)), cid, i0, i1, vxs, ctr)
          +rr = sw_ecurves_go(t, tids, nv, vxs, er_n(r))
          er_cat(r, rr)

def sw_oedge_fw(+fwd: Bool, +i: Nat, +ecbase: Nat, +ctr: Nat) -> ER:
  match fwd:
    case True{}: er_ok(sw_ent(ctr, "ORIENTED_EDGE('',*,*," ++ sw_ref(Nat.add(ecbase, i)) ++ ",.T.)"),
      Nat.add(ctr, 1n))
    case False{}: er_ok(sw_ent(ctr, "ORIENTED_EDGE('',*,*," ++ sw_ref(Nat.add(ecbase, i)) ++ ",.F.)"),
      Nat.add(ctr, 1n))

def sw_oedge_t2(+w: Bool, +ce: Ty.Coedge, +i: Nat, +ecbase: Nat, +ctr: Nat) -> ER:
  match w:
    case False{}: er_fail("step-index-out-of-range", Nat.add(ctr, 1n))
    case True{}: sw_oedge_fw(Ty.ce_fwd(ce), i, ecbase, ctr)

def sw_oedge(+ce: Ty.Coedge, +ne: Nat, +ecbase: Nat, +ctr: Nat) -> ER:
  +i = BL.he_i(Ty.ce_edge(ce))
  sw_oedge_t2(Nat.is_lt(i, ne), ce, i, ecbase, ctr)

def sw_oedges_go(es: List<&2, Ty.Coedge>, +ne: Nat, +ecbase: Nat, +ctr: Nat) -> ER:
  match es:
    case []: ER{True{}, "", "", ctr}
    case e <> t:
      +r = sw_oedge(e, ne, ecbase, ctr)
      +rr = sw_oedges_go(t, ne, ecbase, er_n(r))
      er_cat(r, rr)

def sw_bok_go(hs: List<&2, Ty.HCoedge>, +nce: Nat) -> Bool:
  match hs:
    case []: True{}
    case h <> t: Bool.and(Nat.is_lt(BL.hc_i(h), nce), sw_bok_go(t, nce))

def sw_bref_go(hs: List<&2, Ty.HCoedge>, +oebase: Nat, +acc: List<&2, String>) -> BL.ES:
  match hs:
    case []: BL.es_ok("(" ++ BL.jn(List.reverse(&2, String, acc), ",") ++ ")")
    case h <> t: sw_bref_go(t, oebase, sw_ref(Nat.add(oebase, BL.hc_i(h))) <> acc)

def sw_bref_t(+w: Bool, hs: List<&2, Ty.HCoedge>, +oebase: Nat, +acc: List<&2, String>) -> BL.ES:
  match w:
    case False{}: BL.es_fail("step-index-out-of-range")
    case True{}: sw_bref_go(hs, oebase, acc)

def sw_bound_refs(+hs: List<&2, Ty.HCoedge>, +nce: Nat, +oebase: Nat, +acc: List<&2, String>) ->
    BL.ES:
  sw_bref_t(sw_bok_go(hs, nce), hs, oebase, acc)

def sw_loop_t(+w: Bool, +e: BL.ES, +ctr: Nat) -> ER:
  match w:
    case False{}: er_fail(BL.es_why(e), Nat.add(ctr, 1n))
    case True{}: er_ok(sw_ent(ctr, "EDGE_LOOP(''," ++ BL.es_s(e) ++ ")"), Nat.add(ctr, 1n))

def sw_loop_e(+empty: Bool, +lp: Ty.Loop, +nce: Nat, +oebase: Nat, +ctr: Nat) -> ER:
  match empty:
    case True{}: er_fail("step-empty-loop-not-in-profile", Nat.add(ctr, 1n))
    case False{}:
      +e = sw_bound_refs(Ty.lp_ces(lp), nce, oebase, [])
      sw_loop_t(BL.es_ok_of(e), e, ctr)

def sw_loop(+lp: Ty.Loop, +nce: Nat, +oebase: Nat, +ctr: Nat) -> ER:
  sw_loop_e(Nat.is_eq(List.length(&2, Ty.HCoedge, Ty.lp_ces(lp)), 0n), lp, nce, oebase, ctr)

def er2_lift(+r: ER, +ids: List<&2, Nat>) -> ER2:
  ER2{er_ok_of(r), er_s(r), er_why(r), er_n(r), ids}

def sw_loops_go(ls: List<&2, Ty.Loop>, +nce: Nat, +oebase: Nat, +ctr: Nat,
    +acc: List<&2, Nat>) -> ER2:
  match ls:
    case []: ER2{True{}, "", "", ctr, List.reverse(&2, Nat, acc)}
    case l <> t:
      +r = sw_loop(l, nce, oebase, ctr)
      +rr = sw_loops_go(t, nce, oebase, er_n(r), ctr <> acc)
      er2_cat_s(er2_lift(r, []), rr)

def sw_bound_kind(+k: Ty.LoopKind, +lid: Nat, +ctr: Nat) -> ER:
  match k:
    case Ty.LK_outer{}: er_ok(sw_ent(ctr, "FACE_OUTER_BOUND(''," ++ sw_ref(lid) ++ ",.T.)"),
      Nat.add(ctr, 1n))
    case Ty.LK_inner{}: er_ok(sw_ent(ctr, "FACE_BOUND(''," ++ sw_ref(lid) ++ ",.T.)"),
      Nat.add(ctr, 1n))

def sw_bound(+lp: Ty.Loop, +lid: Nat, +ctr: Nat) -> ER:
  sw_bound_kind(Ty.lp_kind(lp), lid, ctr)

def sw_bounds_go(ls: List<&2, Ty.Loop>, +lids: List<&2, Nat>, +ctr: Nat,
    +acc: List<&2, Nat>) -> ER2:
  match ls:
    case []: ER2{True{}, "", "", ctr, List.reverse(&2, Nat, acc)}
    case l <> t:
      match lids:
        case []: ER2{False{}, "", "step-internal-id-mismatch", ctr, []}
        case +lid <> tids:
          +r = sw_bound(l, lid, ctr)
          +rr = sw_bounds_go(t, tids, er_n(r), ctr <> acc)
          er2_cat_s(er2_lift(r, []), rr)

def sw_fok_go(hs: List<&2, Ty.HLoop>, +nlp: Nat) -> Bool:
  match hs:
    case []: True{}
    case h <> t: Bool.and(Nat.is_lt(BL.hl_i(h), nlp), sw_fok_go(t, nlp))

def sw_fref_go(hs: List<&2, Ty.HLoop>, +lbbase: Nat, +acc: List<&2, String>) -> BL.ES:
  match hs:
    case []: BL.es_ok("(" ++ BL.jn(List.reverse(&2, String, acc), ",") ++ ")")
    case h <> t: sw_fref_go(t, lbbase, sw_ref(Nat.add(lbbase, BL.hl_i(h))) <> acc)

def sw_fref_t(+w: Bool, hs: List<&2, Ty.HLoop>, +lbbase: Nat, +acc: List<&2, String>) -> BL.ES:
  match w:
    case False{}: BL.es_fail("step-index-out-of-range")
    case True{}: sw_fref_go(hs, lbbase, acc)

def sw_face_refs(+hs: List<&2, Ty.HLoop>, +nlp: Nat, +lbbase: Nat, +acc: List<&2, String>) -> BL.ES:
  sw_fref_t(sw_fok_go(hs, nlp), hs, lbbase, acc)

def sw_face_sm(+sm: Bool, +e: BL.ES, +sid: Nat, +ctr: Nat) -> ER:
  match sm:
    case True{}: er_ok(sw_ent(ctr, "ADVANCED_FACE(''," ++ BL.es_s(e) ++ "," ++ sw_ref(sid) ++
      ",.T.)"), Nat.add(ctr, 1n))
    case False{}: er_ok(sw_ent(ctr, "ADVANCED_FACE(''," ++ BL.es_s(e) ++ "," ++ sw_ref(sid) ++
      ",.F.)"), Nat.add(ctr, 1n))

def sw_face_t(+w: Bool, +e: BL.ES, +f: Ty.Face, +sid: Nat, +ctr: Nat) -> ER:
  match w:
    case False{}: er_fail(BL.es_why(e), Nat.add(ctr, 1n))
    case True{}: sw_face_sm(Ty.fa_same(f), e, sid, ctr)

def sw_face(+f: Ty.Face, +sid: Nat, +nlp: Nat, +lbbase: Nat, +ctr: Nat) -> ER:
  +e = sw_face_refs(Ty.fa_loops(f), nlp, lbbase, [])
  sw_face_t(BL.es_ok_of(e), e, f, sid, ctr)

def sw_faces_go(fs: List<&2, Ty.Face>, +ids: List<&2, Nat>, +nlp: Nat, +lbbase: Nat, +ctr: Nat) ->
    ER:
  match fs:
    case []: ER{True{}, "", "", ctr}
    case f <> t:
      match ids:
        case []: ER{False{}, "", "step-internal-id-mismatch", ctr}
        case +sid <> tids:
          +r = sw_face(f, sid, nlp, lbbase, ctr)
          +rr = sw_faces_go(t, tids, nlp, lbbase, er_n(r))
          er_cat(r, rr)

def sw_sok_go(hs: List<&2, Ty.HFace>, +nf: Nat) -> Bool:
  match hs:
    case []: True{}
    case h <> t: Bool.and(Nat.is_lt(BL.hf_i(h), nf), sw_sok_go(t, nf))

def sw_sref_go(hs: List<&2, Ty.HFace>, +fabase: Nat, +acc: List<&2, String>) -> BL.ES:
  match hs:
    case []: BL.es_ok("(" ++ BL.jn(List.reverse(&2, String, acc), ",") ++ ")")
    case h <> t: sw_sref_go(t, fabase, sw_ref(Nat.add(fabase, BL.hf_i(h))) <> acc)

def sw_sref_t(+w: Bool, hs: List<&2, Ty.HFace>, +fabase: Nat, +acc: List<&2, String>) -> BL.ES:
  match w:
    case False{}: BL.es_fail("step-index-out-of-range")
    case True{}: sw_sref_go(hs, fabase, acc)

def sw_shell_refs(+hs: List<&2, Ty.HFace>, +nf: Nat, +fabase: Nat, +acc: List<&2, String>) -> BL.ES:
  sw_sref_t(sw_sok_go(hs, nf), hs, fabase, acc)

def sw_shell_kind(+k: Ty.ShellKind, +e: BL.ES, +ctr: Nat) -> ER:
  match k:
    case Ty.SK_open{}: er_fail("step-open-shell-not-in-profile", Nat.add(ctr, 1n))
    case Ty.SK_outer{}: er_ok(sw_ent(ctr, "CLOSED_SHELL(''," ++ BL.es_s(e) ++ ")"), Nat.add(ctr, 1n))
    case Ty.SK_inner{}: er_ok(sw_ent(ctr, "CLOSED_SHELL(''," ++ BL.es_s(e) ++ ")"), Nat.add(ctr, 1n))

def sw_shell_t(+w: Bool, +e: BL.ES, +sh: Ty.Shell, +ctr: Nat) -> ER:
  match w:
    case False{}: er_fail(BL.es_why(e), Nat.add(ctr, 1n))
    case True{}: sw_shell_kind(Ty.sh_kind(sh), e, ctr)

def sw_shell(+sh: Ty.Shell, +nf: Nat, +fabase: Nat, +ctr: Nat) -> ER:
  +e = sw_shell_refs(Ty.sh_faces(sh), nf, fabase, [])
  sw_shell_t(BL.es_ok_of(e), e, sh, ctr)

def sw_shells_go(ss: List<&2, Ty.Shell>, +nf: Nat, +fabase: Nat, +ctr: Nat) -> ER:
  match ss:
    case []: ER{True{}, "", "", ctr}
    case s <> t:
      +r = sw_shell(s, nf, fabase, ctr)
      +rr = sw_shells_go(t, nf, fabase, er_n(r))
      er_cat(r, rr)

def sw_solid_t2(+w: Bool, +i: Nat, +shbase: Nat, +ctr: Nat) -> ER:
  match w:
    case False{}: er_fail("step-index-out-of-range", Nat.add(ctr, 1n))
    case True{}: er_ok(sw_ent(ctr, "MANIFOLD_SOLID_BREP(''," ++ sw_ref(Nat.add(shbase, i)) ++ ")"),
      Nat.add(ctr, 1n))

def sw_solid_cav(hs: List<&2, Ty.HShell>, +so: Ty.Solid, +nsh: Nat, +shbase: Nat, +ctr: Nat) -> ER:
  match hs:
    case []:
      +i = Ty.hsh_idx(Ty.so_outer(so))
      sw_solid_t2(Nat.is_lt(i, nsh), i, shbase, ctr)
    case _ <> _: er_fail("step-cavities-not-in-profile", Nat.add(ctr, 1n))

def sw_solid(+so: Ty.Solid, +nsh: Nat, +shbase: Nat, +ctr: Nat) -> ER:
  sw_solid_cav(Ty.so_cavities(so), so, nsh, shbase, ctr)

def sw_solids_go(ss: List<&2, Ty.Solid>, +nsh: Nat, +shbase: Nat, +ctr: Nat) -> ER:
  match ss:
    case []: ER{True{}, "", "", ctr}
    case s <> t:
      +r = sw_solid(s, nsh, shbase, ctr)
      +rr = sw_solids_go(t, nsh, shbase, er_n(r))
      er_cat(r, rr)

def sw_head() -> String:
  "ISO-10303-21;\nHEADER;\nFILE_DESCRIPTION(('BendCAD export'),'2;1');\nFILE_NAME('bendcad.step','',('BendCAD'),('BendCAD'),'BendCAD','BendCAD','');\nFILE_SCHEMA(('AUTOMOTIVE_DESIGN'));\nENDSEC;\nDATA;\n"

def sw_foot() -> String:
  "ENDSEC;\nEND-ISO-10303-21;\n"

def sw_vlen_go(xs: List<&2, Ty.Vertex>, +n: Nat) -> Nat:
  match xs:
    case []: n
    case _ <> t: sw_vlen_go(t, Nat.add(n, 1n))

def sw_list_len(xs: List<&2, Ty.Vertex>) -> Nat:
  sw_vlen_go(xs, 0n)

def sw_elen_go(xs: List<&2, Ty.Edge>, +n: Nat) -> Nat:
  match xs:
    case []: n
    case _ <> t: sw_elen_go(t, Nat.add(n, 1n))

def sw_clen_go(xs: List<&2, Ty.Coedge>, +n: Nat) -> Nat:
  match xs:
    case []: n
    case _ <> t: sw_clen_go(t, Nat.add(n, 1n))

def sw_llen_go(xs: List<&2, Ty.Loop>, +n: Nat) -> Nat:
  match xs:
    case []: n
    case _ <> t: sw_llen_go(t, Nat.add(n, 1n))

def sw_flen_go(xs: List<&2, Ty.Face>, +n: Nat) -> Nat:
  match xs:
    case []: n
    case _ <> t: sw_flen_go(t, Nat.add(n, 1n))

def sw_slen_go(xs: List<&2, Ty.Shell>, +n: Nat) -> Nat:
  match xs:
    case []: n
    case _ <> t: sw_slen_go(t, Nat.add(n, 1n))

def sw_olen_go(xs: List<&2, Ty.Solid>, +n: Nat) -> Nat:
  match xs:
    case []: n
    case _ <> t: sw_olen_go(t, Nat.add(n, 1n))

def sw_sids_go(+k: Nat, +base: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match k:
    case 0n: List.reverse(&2, Nat, acc)
    case 1n+j: sw_sids_go(j, Nat.add(base, 1n), base <> acc)

def sw_sids(+base: Nat, +n: Nat) -> List<&2, Nat>:
  sw_sids_go(n, base, [])

def sw_stage_cat(+r1: ER, +r2: ER2, +r3: ER2, +r4: ER, +r5: ER, +r6: ER, +r7: ER2, +r8: ER2, +r9: ER,
    +r10: ER, +r11: ER, +sobase: Nat, +nso: Nat) -> ER2:
  +a = er2_cat_s(er2_lift(r1, []), r2)
  +b = er2_cat_s(a, r3)
  +c = er2_cat_s(b, er2_lift(r4, []))
  +d = er2_cat_s(c, er2_lift(r5, []))
  +e = er2_cat_s(d, er2_lift(r6, []))
  +f = er2_cat_s(e, r7)
  +g = er2_cat_s(f, r8)
  +h = er2_cat_s(g, er2_lift(r9, []))
  +k = er2_cat_s(h, er2_lift(r10, []))
  +m = er2_cat_s(k, er2_lift(r11, []))
  ER2{er2_ok_of(m), er2_s(m), er2_why(m), er2_n(m), sw_sids(sobase, nso)}

def sw_stage_go(+b: Ty.Brep, +pl: M.Pl, +ctr: Nat, +nv: Nat, +ne: Nat, +nce: Nat, +nlp: Nat, +nf: Nat,
    +nsh: Nat, +nso: Nat) -> ER2:
  +vbase = ctr
  +r1 = sw_vpts_go(Ty.brep_vs(b), pl, ctr)
  +r2 = sw_curves_go(Ty.brep_es(b), nv, pl, vbase, er_n(r1), [])
  +r3 = sw_surfs_go(Ty.brep_fas(b), pl, er2_n(r2), [])
  +r4 = sw_vxs_go(nv, nv, vbase, er2_n(r3))
  +r5 = sw_ecurves_go(Ty.brep_es(b), er2_ids(r2), nv, er2_n(r3), er_n(r4))
  +r6 = sw_oedges_go(Ty.brep_ces(b), ne, er_n(r4), er_n(r5))
  +r7 = sw_loops_go(Ty.brep_lps(b), nce, er_n(r5), er_n(r6), [])
  +r8 = sw_bounds_go(Ty.brep_lps(b), er2_ids(r7), er2_n(r7), [])
  +r9 = sw_faces_go(Ty.brep_fas(b), er2_ids(r3), nlp, er2_n(r7), er2_n(r8))
  +r10 = sw_shells_go(Ty.brep_shs(b), nf, er2_n(r8), er_n(r9))
  +r11 = sw_solids_go(Ty.brep_sos(b), nsh, er_n(r9), er_n(r10))
  sw_stage_cat(r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, er_n(r10), nso)

def sw_stage_nso(+w: Bool, +b: Ty.Brep, +pl: M.Pl, +ctr: Nat, +nv: Nat, +ne: Nat, +nce: Nat,
    +nlp: Nat, +nf: Nat, +nsh: Nat, +nso: Nat) -> ER2:
  match w:
    case False{}: er2_fail("step-no-solid", ctr)
    case True{}: sw_stage_go(b, pl, ctr, nv, ne, nce, nlp, nf, nsh, nso)

def sw_stage(+b: Ty.Brep, +pl: M.Pl, +ctr: Nat) -> ER2:
  +nv = sw_vlen_go(Ty.brep_vs(b), 0n)
  +ne = sw_elen_go(Ty.brep_es(b), 0n)
  +nce = sw_clen_go(Ty.brep_ces(b), 0n)
  +nlp = sw_llen_go(Ty.brep_lps(b), 0n)
  +nf = sw_flen_go(Ty.brep_fas(b), 0n)
  +nsh = sw_slen_go(Ty.brep_shs(b), 0n)
  +nso = sw_olen_go(Ty.brep_sos(b), 0n)
  sw_stage_nso(Nat.is_lt(0n, nso), b, pl, ctr, nv, ne, nce, nlp, nf, nsh, nso)

def sw_sid_cat(+w: Bool, +r: ER2, +a: ER2, +b: ER2) -> ER2:
  match w:
    case False{}: r
    case True{}: ER2{True{}, er2_s(r), "", er2_n(r), List.append(&2, Nat, er2_ids(a), er2_ids(b))}

def sw_stages_acc_t(+w: Bool, +p: BL.PR, +pl: M.Pl, +acc: ER2) -> ER2:
  match w:
    case False{}: ER2{False{}, er2_s(acc), BL.pr_why(p), er2_n(acc), er2_ids(acc)}
    case True{}:
      +b = sw_stage(BL.pr_b(p), pl, er2_n(acc))
      +r = er2_cat_s(acc, b)
      sw_sid_cat(er2_ok_of(r), r, acc, b)

def sw_stages_acc(+p: BL.PR, +pl: M.Pl, +acc: ER2) -> ER2:
  sw_stages_acc_t(BL.pr_ok_of(p), p, pl, acc)

def sw_stages_go(ps: List<&2, BL.PR>, +pl: M.Pl, +acc: ER2) -> ER2:
  match ps:
    case []: acc
    case p <> t: sw_stages_go(t, pl, sw_stages_acc(p, pl, acc))

def sw_units(+n: Nat) -> String:
  "#" ++ Nat.show(n) ++ " = ( LENGTH_UNIT() NAMED_UNIT(*) SI_UNIT(.MILLI.,.METRE.) );\n" ++
    "#" ++ Nat.show(Nat.add(n, 1n)) ++
    " = ( NAMED_UNIT(*) PLANE_ANGLE_UNIT() SI_UNIT($,.RADIAN.) );\n" ++
    "#" ++ Nat.show(Nat.add(n, 2n)) ++
    " = ( NAMED_UNIT(*) SI_UNIT($,.STERADIAN.) SOLID_ANGLE_UNIT() );\n"

def sw_env_sids_go(xs: List<&2, Nat>, +acc: String) -> String:
  match xs:
    case []: acc
    case h <> t: sw_env_sids_go(t, acc ++ "," ++ sw_ref(h))

def sw_env_sids(+xs: List<&2, Nat>) -> String:
  sw_env_sids_go(xs, "")

def sw_env(+u0: Nat, +e0: Nat, +sids: List<&2, Nat>) -> String:
  sw_ent(e0, "APPLICATION_CONTEXT('core data for automotive mechanical design processes')") ++
    sw_ent(Nat.add(e0, 1n), "APPLICATION_PROTOCOL_DEFINITION('international standard','automotive_design',2000," ++
      sw_ref(e0) ++ ")") ++
    sw_ent(Nat.add(e0, 2n), "PRODUCT_CONTEXT(''," ++ sw_ref(e0) ++ ",'mechanical')") ++
    sw_ent(Nat.add(e0, 3n), "PRODUCT_DEFINITION_CONTEXT('part definition'," ++ sw_ref(e0) ++
      ",'design')") ++
    sw_ent(Nat.add(e0, 4n), "PRODUCT('BENDCAD','BENDCAD','',(" ++ sw_ref(Nat.add(e0, 2n)) ++ "))") ++
    sw_ent(Nat.add(e0, 5n), "PRODUCT_DEFINITION_FORMATION('',''," ++ sw_ref(Nat.add(e0, 4n)) ++ ")") ++
    sw_ent(Nat.add(e0, 6n), "PRODUCT_DEFINITION('design',''," ++ sw_ref(Nat.add(e0, 5n)) ++ "," ++
      sw_ref(Nat.add(e0, 3n)) ++ ")") ++
    sw_ent(Nat.add(e0, 7n), "PRODUCT_DEFINITION_SHAPE('',''," ++ sw_ref(Nat.add(e0, 6n)) ++ ")") ++
    sw_ent(Nat.add(e0, 8n), "CARTESIAN_POINT('',(0.0,0.0,0.0))") ++
    sw_ent(Nat.add(e0, 9n), "DIRECTION('',(0.0,0.0,1.0))") ++
    sw_ent(Nat.add(e0, 10n), "DIRECTION('',(1.0,0.0,0.0))") ++
    sw_ent(Nat.add(e0, 11n), "AXIS2_PLACEMENT_3D(''," ++ sw_ref(Nat.add(e0, 8n)) ++ "," ++
      sw_ref(Nat.add(e0, 9n)) ++ "," ++ sw_ref(Nat.add(e0, 10n)) ++ ")") ++
    sw_ent(Nat.add(e0, 12n), "ADVANCED_BREP_SHAPE_REPRESENTATION('',(" ++ sw_ref(Nat.add(e0, 11n)) ++
      sw_env_sids(sids) ++ ")," ++ sw_ref(Nat.add(e0, 13n)) ++ ")") ++
    sw_ent(Nat.add(e0, 13n), "( GEOMETRIC_REPRESENTATION_CONTEXT(3) " ++
      "GLOBAL_UNCERTAINTY_ASSIGNED_CONTEXT((" ++ sw_ref(Nat.add(e0, 15n)) ++ ")) " ++
      "GLOBAL_UNIT_ASSIGNED_CONTEXT((" ++ sw_ref(u0) ++ "," ++ sw_ref(Nat.add(u0, 1n)) ++ "," ++
      sw_ref(Nat.add(u0, 2n)) ++ ")) REPRESENTATION_CONTEXT('','') )") ++
    sw_ent(Nat.add(e0, 14n), "SHAPE_DEFINITION_REPRESENTATION(" ++ sw_ref(Nat.add(e0, 7n)) ++ "," ++
      sw_ref(Nat.add(e0, 12n)) ++ ")") ++
    sw_ent(Nat.add(e0, 15n), "UNCERTAINTY_MEASURE_WITH_UNIT(LENGTH_MEASURE(0.0000001)," ++
      sw_ref(u0) ++ ",'distance_accuracy_value','confusion accuracy')") ++
    sw_ent(Nat.add(e0, 16n), "PRODUCT_RELATED_PRODUCT_CATEGORY('part',$,(" ++
      sw_ref(Nat.add(e0, 4n)) ++ "))")

def sw_wrap_t(+w: Bool, +r: ER2, +np: Nat) -> WS:
  match w:
    case False{}: WS{False{}, "", er2_why(r), 0n, 0n}
    case True{}: WS{True{}, sw_head() ++ er2_s(r) ++ sw_units(er2_n(r)) ++
      sw_env(er2_n(r), Nat.add(er2_n(r), 3n), er2_ids(r)) ++ sw_foot(), "",
      Nat.add(er2_n(r), 19n), np}

def sw_wrap(+r: ER2, +np: Nat) -> WS:
  sw_wrap_t(er2_ok_of(r), r, np)

def sw_ms(+b: M.Body) -> WS:
  sw_wrap(sw_stage(M.bd_brep(b), M.bd_pl(b), 1n), 1n)

def sw_pr_go(+w: Bool, +p: BL.PR, +pl: M.Pl) -> WS:
  match w:
    case False{}: WS{False{}, "", BL.pr_why(p), 0n, 0n}
    case True{}: sw_wrap(sw_stage(BL.pr_b(p), pl, 1n), 1n)

def sw_pr(+p: BL.PR, +pl: M.Pl) -> WS:
  sw_pr_go(BL.pr_ok_of(p), p, pl)

def sw_head42() -> String:
  "ISO-10303-21;\nHEADER;\nFILE_DESCRIPTION(('BendCAD AP242 PMI export'),'2;1');\nFILE_NAME('bendcad.step','',('BendCAD'),('BendCAD'),'BendCAD','BendCAD','');\nFILE_SCHEMA(('AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF'));\nENDSEC;\nDATA;\n"

def sw_env42(+u0: Nat, +e0: Nat, +sids: List<&2, Nat>) -> String:
  sw_ent(e0, "APPLICATION_CONTEXT('managed model based 3d engineering')") ++
    sw_ent(Nat.add(e0, 1n), "APPLICATION_PROTOCOL_DEFINITION('international standard','managed_model_based_3d_engineering',2020," ++
      sw_ref(e0) ++ ")") ++
    sw_ent(Nat.add(e0, 2n), "PRODUCT_CONTEXT(''," ++ sw_ref(e0) ++ ",'mechanical')") ++
    sw_ent(Nat.add(e0, 3n), "PRODUCT_DEFINITION_CONTEXT('part definition'," ++ sw_ref(e0) ++
      ",'design')") ++
    sw_ent(Nat.add(e0, 4n), "PRODUCT('BENDCAD','BENDCAD','',(" ++ sw_ref(Nat.add(e0, 2n)) ++ "))") ++
    sw_ent(Nat.add(e0, 5n), "PRODUCT_DEFINITION_FORMATION('',''," ++ sw_ref(Nat.add(e0, 4n)) ++ ")") ++
    sw_ent(Nat.add(e0, 6n), "PRODUCT_DEFINITION('design',''," ++ sw_ref(Nat.add(e0, 5n)) ++ "," ++
      sw_ref(Nat.add(e0, 3n)) ++ ")") ++
    sw_ent(Nat.add(e0, 7n), "PRODUCT_DEFINITION_SHAPE('',''," ++ sw_ref(Nat.add(e0, 6n)) ++ ")") ++
    sw_ent(Nat.add(e0, 8n), "CARTESIAN_POINT('',(0.0,0.0,0.0))") ++
    sw_ent(Nat.add(e0, 9n), "DIRECTION('',(0.0,0.0,1.0))") ++
    sw_ent(Nat.add(e0, 10n), "DIRECTION('',(1.0,0.0,0.0))") ++
    sw_ent(Nat.add(e0, 11n), "AXIS2_PLACEMENT_3D(''," ++ sw_ref(Nat.add(e0, 8n)) ++ "," ++
      sw_ref(Nat.add(e0, 9n)) ++ "," ++ sw_ref(Nat.add(e0, 10n)) ++ ")") ++
    sw_ent(Nat.add(e0, 12n), "ADVANCED_BREP_SHAPE_REPRESENTATION('',(" ++ sw_ref(Nat.add(e0, 11n)) ++
      sw_env_sids(sids) ++ ")," ++ sw_ref(Nat.add(e0, 13n)) ++ ")") ++
    sw_ent(Nat.add(e0, 13n), "( GEOMETRIC_REPRESENTATION_CONTEXT(3) " ++
      "GLOBAL_UNCERTAINTY_ASSIGNED_CONTEXT((" ++ sw_ref(Nat.add(e0, 15n)) ++ ")) " ++
      "GLOBAL_UNIT_ASSIGNED_CONTEXT((" ++ sw_ref(u0) ++ "," ++ sw_ref(Nat.add(u0, 1n)) ++ "," ++
      sw_ref(Nat.add(u0, 2n)) ++ ")) REPRESENTATION_CONTEXT('','') )") ++
    sw_ent(Nat.add(e0, 14n), "SHAPE_DEFINITION_REPRESENTATION(" ++ sw_ref(Nat.add(e0, 7n)) ++ "," ++
      sw_ref(Nat.add(e0, 12n)) ++ ")") ++
    sw_ent(Nat.add(e0, 15n), "UNCERTAINTY_MEASURE_WITH_UNIT(LENGTH_MEASURE(0.0000001)," ++
      sw_ref(u0) ++ ",'distance_accuracy_value','confusion accuracy')") ++
    sw_ent(Nat.add(e0, 16n), "PRODUCT_RELATED_PRODUCT_CATEGORY('part',$,(" ++
      sw_ref(Nat.add(e0, 4n)) ++ "))")

def sw_wrap42_t(+w: Bool, +r: ER2, +np: Nat, +pmi_s: String, +pmi_n: Nat) -> WS:
  match w:
    case False{}: WS{False{}, "", er2_why(r), 0n, 0n}
    case True{}: WS{True{}, sw_head42() ++ er2_s(r) ++ sw_units(er2_n(r)) ++
      sw_env42(er2_n(r), Nat.add(er2_n(r), 3n), er2_ids(r)) ++ pmi_s ++ sw_foot(), "",
      Nat.add(Nat.add(er2_n(r), 19n), pmi_n), np}

def sw_wrap42(+r: ER2, +np: Nat, +pmi_s: String, +pmi_n: Nat) -> WS:
  sw_wrap42_t(er2_ok_of(r), r, np, pmi_s, pmi_n)

def sw_ms42(+b: M.Body, +pmi_s: String, +pmi_n: Nat) -> WS:
  sw_wrap42(sw_stage(M.bd_brep(b), M.bd_pl(b), 1n), 1n, pmi_s, pmi_n)

def sw_plen_go(ps: List<&2, BL.PR>, +n: Nat) -> Nat:
  match ps:
    case []: n
    case _ <> t: sw_plen_go(t, Nat.add(n, 1n))

def sw_two(+b: M.Body, +ps: List<&2, BL.PR>, +pl: M.Pl) -> WS:
  sw_wrap(sw_stages_go(ps, pl, sw_stage(M.bd_brep(b), M.bd_pl(b), 1n)), Nat.add(1n, sw_plen_go(ps, 0n)))
