import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c06/iv.bend as I
import ../c06/sx.bend as S
import ../c06/model.bend as M
import ../c07/sol.bend as SO
import ../c07/xs.bend as Q
import ../c07/rb.bend as R
import ../c08/bool.bend as BO
import ../c10/mesh.bend as M10
import ../base/par.bend as B
import ./qcert.bend as QC
import ./qaccel.bend as QA
import ./qinterf.bend as QI

type Wx is Data:
  Wx{ vs: B.Tb<&2, Ty.Vertex>, es: B.Tb<&2, Ty.Edge>, ces: B.Tb<&2, Ty.Coedge>, lps: B.Tb<&2, Ty.Loop>,
    fas: B.Tb<&2, Ty.Face>, fbx: B.Tb<&2, QA.Ab>, bb: QA.Ab, nf: Nat }

type Wp is Data:
  Wp{ lo: F64, i: Nat, j: Nat }

type Wr is Data:
  Wr{ hi: F64, pruned: Nat, npairs: Nat }

def v_pts(vs: List<&2, Ty.Vertex>) -> List<&2, V.Point>:
  match vs:
    case []: []
    case v <> t: Ty.vx_p(v) <> v_pts(t)

def e_mids(es: List<&2, Ty.Edge>) -> List<&2, V.Point>:
  match es:
    case []: []
    case e <> t: BO.mid_cons(BO.ed_mid(Ty.ed_kind(e)), e_mids(t))

def f_int_go(m: Maybe<&2, List<&2, I.I>>, +rest: List<&2, V.Point>) -> List<&2, V.Point>:
  match m:
    case None{}: rest
    case Some{q}: BO.mid_pt(q) <> rest

def box_lo(+c: V.Point, fs: List<&2, SO.Fd>, +best: F64) -> F64:
  match fs:
    case []: best
    case f <> t: box_lo(c, t, F64.min(best, QA.ab_lo(c, QA.ab_of_iv(SO.fd_bx(f)))))

def near_at(+c: V.Point, ps: List<&2, V.Point>, +hi: F64) -> V.Point:
  match ps:
    case []: c
    case +p <> t:
      Bool.pick(V.Point, F64.is_eq(M10.pt_dist(c, p), hi), p, near_at(c, t, hi))

def near_best(+c: V.Point, ps: List<&2, V.Point>, +best: F64) -> F64:
  match ps:
    case []: best
    case p <> t: near_best(c, t, F64.min(best, M10.pt_dist(c, p)))

def pt_s(+p: V.Point) -> String:
  S.f_show(V.pt_x(p)) ++ "," ++ S.f_show(V.pt_y(p)) ++ "," ++ S.f_show(V.pt_z(p))

def dist_bd(bd: Bool, +unc: Bool, +c: V.Point, +fs: List<&2, SO.Fd>, +ps: List<&2, V.Point>,
    +cert: Bool) -> String:
  match bd:
    case True{}: "distance 0 status=certified state=boundary"
    case False{}:
      +lo = box_lo(c, fs, V.dbl_max())
      +hi = near_best(c, ps, V.dbl_max())
      "distance " ++ QC.bv_show(QC.bv_mk(lo, hi, QC.st_estimated())) ++ " lo=" ++
        Bool.pick(String, cert, "certified", "estimated") ++ " nearest=" ++
        pt_s(near_at(c, ps, hi)) ++ " samples=" ++ Nat.show(List.length(&2, V.Point, ps)) ++
        Bool.pick(String, unc, " classify=uncertain", "")

def wverts_go(ps: List<&2, V.Point>, +mi: List<&2, I.I>, +ti: List<&2, I.I>) -> List<&2, V.Point>:
  match ps:
    case []: []
    case p <> t: QA.ab_wpt(mi, ti, p) <> wverts_go(t, mi, ti)

def ex_c(+p: V.Point, +k: Nat) -> F64:
  Bool.pick(F64, Nat.is_eq(k, 0n), V.pt_x(p), Bool.pick(F64, Nat.is_eq(k, 1n), V.pt_y(p), V.pt_z(p)))

def ex_better(mx: Bool, +k: Nat, +p: V.Point, +best: V.Point) -> V.Point:
  match mx:
    case True{}: Bool.pick(V.Point, F64.is_lt(ex_c(best, k), ex_c(p, k)), p, best)
    case False{}: Bool.pick(V.Point, F64.is_lt(ex_c(p, k), ex_c(best, k)), p, best)

def ex_wit(ps: List<&2, V.Point>, +k: Nat, +want_max: Bool, +best: V.Point) -> V.Point:
  match ps:
    case []: best
    case p <> t: ex_wit(t, k, want_max, ex_better(want_max, k, p, best))

def pts_min_one(qs: List<&2, V.Point>, +p: V.Point, +best: F64) -> F64:
  match qs:
    case []: best
    case q <> t: pts_min_one(t, p, F64.min(best, M10.pt_dist(p, q)))

def vx_dflt() -> Ty.Vertex:
  Ty.Vx{0u64, V.Pt{0.0f64, 0.0f64, 0.0f64}}

def ed_dflt() -> Ty.Edge:
  Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{0n, 0u64}, Ty.EK_degenerate{}}

def ce_dflt() -> Ty.Coedge:
  Ty.Ce{0u64, Ty.HE{0n, 0u64}, False{}, G.GV_f{0.0f64}}

def lp_dflt() -> Ty.Loop:
  Ty.Lp{0u64, [], Ty.LK_outer{}}

def fa_dflt() -> Ty.Face:
  Ty.Fa{0u64, Ty.surf_zero(), [], True{}, 0.0f64, 0.0f64}

def wx_vs(+x: Wx) -> B.Tb<&2, Ty.Vertex>:
  Wx{vs, es, ces, lps, fas, fbx, bb, nf} = x
  vs

def wx_es(+x: Wx) -> B.Tb<&2, Ty.Edge>:
  Wx{vs, es, ces, lps, fas, fbx, bb, nf} = x
  es

def wx_ces(+x: Wx) -> B.Tb<&2, Ty.Coedge>:
  Wx{vs, es, ces, lps, fas, fbx, bb, nf} = x
  ces

def wx_lps(+x: Wx) -> B.Tb<&2, Ty.Loop>:
  Wx{vs, es, ces, lps, fas, fbx, bb, nf} = x
  lps

def wx_fas(+x: Wx) -> B.Tb<&2, Ty.Face>:
  Wx{vs, es, ces, lps, fas, fbx, bb, nf} = x
  fas

def wx_fbx(+x: Wx) -> B.Tb<&2, QA.Ab>:
  Wx{vs, es, ces, lps, fas, fbx, bb, nf} = x
  fbx

def wx_nf(+x: Wx) -> Nat:
  Wx{vs, es, ces, lps, fas, fbx, bb, nf} = x
  nf

def eb_full(+c: R.Cv, +d: G.Dom) -> List<&2, I.I>:
  G.Dom{+lo, +hi} = d
  R.cv_box(c, I.I{lo, hi})

def eb_cv(m: Maybe<&2, R.Cv>, +d: G.Dom, +pa: V.Point, +pb: V.Point) -> QA.Ab:
  match m:
    case None{}: QA.ab_hull(QA.ab_of3(I.ipt(V.pt_x(pa)), I.ipt(V.pt_y(pa)), I.ipt(V.pt_z(pa))), QA.ab_of3(I.ipt(V.pt_x(pb)), I.ipt(V.pt_y(pb)), I.ipt(V.pt_z(pb))))
    case Some{+c}: QA.ab_of_iv(eb_full(c, d))

def pt_abs(ps: List<&2, V.Point>) -> List<&2, QA.Ab>:
  match ps:
    case []: []
    case V.Pt{+x, +y, +z} <> t: QA.ab_of3(I.ipt(x), I.ipt(y), I.ipt(z)) <> pt_abs(t)

def fb_one(+f: SO.Fd, +bb: QA.Ab) -> QA.Ab:
  Bool.pick(QA.Ab, SO.fd_ok(f), QA.ab_of_iv(SO.fd_bx(f)), bb)

def fb_at(fs: List<&2, SO.Fd>, +i: Nat, +bb: QA.Ab) -> QA.Ab:
  match fs:
    case []: bb
    case +f <> t: Bool.pick(QA.Ab, Nat.is_eq(SO.fd_fi(f), i), fb_one(f, bb), fb_at(t, i, bb))

def fb_align(+fs: List<&2, SO.Fd>, +bb: QA.Ab, +n: Nat, +i: Nat) -> List<&2, QA.Ab>:
  match n:
    case 0n: []
    case 1n+m: fb_at(fs, i, bb) <> fb_align(fs, bb, m, Nat.add(i, 1n))

def ce_edge_id(+x: Wx, +h: Ty.HCoedge) -> Nat:
  Ty.HC{+ci, +g} = h
  Ty.he_idx(Ty.ce_edge(B.tb_get(Ty.Coedge, wx_ces(x), U32.from_nat(ci))))

def ce_edges(hs: List<&2, Ty.HCoedge>, +x: Wx) -> List<&2, Nat>:
  match hs:
    case []: []
    case h <> t: ce_edge_id(x, h) <> ce_edges(t, x)

def fa_edges(hs: List<&2, Ty.HLoop>, +x: Wx) -> List<&2, Nat>:
  match hs:
    case []: []
    case Ty.HL{+li, +g} <> t:
      List.append(&2, Nat, ce_edges(Ty.lp_ces(B.tb_get(Ty.Loop, wx_lps(x), U32.from_nat(li))), x), fa_edges(t, x))

def edge_vs(+e: Ty.Edge) -> List<&2, Nat>:
  Ty.Ed{g, h0, h1, k} = e
  Ty.HV{+a, +ga} = h0
  Ty.HV{+b, +gb} = h1
  [a, b]

def edges_vs(es: List<&2, Nat>, +x: Wx) -> List<&2, Nat>:
  match es:
    case []: []
    case i <> t: List.append(&2, Nat, edge_vs(B.tb_get(Ty.Edge, wx_es(x), U32.from_nat(i))), edges_vs(t, x))

def face_eset(+x: Wx, +i: Nat) -> List<&2, Nat>:
  QA.n_dedup(fa_edges(Ty.fa_loops(B.tb_get(Ty.Face, wx_fas(x), U32.from_nat(i))), x))

def face_vset(+x: Wx, es: List<&2, Nat>) -> List<&2, Nat>:
  QA.n_dedup(edges_vs(es, x))

def face_vpts(vs: List<&2, Nat>, +x: Wx) -> List<&2, V.Point>:
  match vs:
    case []: []
    case i <> t: Ty.vx_p(B.tb_get(Ty.Vertex, wx_vs(x), U32.from_nat(i))) <> face_vpts(t, x)

def face_mids(es: List<&2, Nat>, +x: Wx) -> List<&2, V.Point>:
  match es:
    case []: []
    case i <> t: BO.mid_cons(BO.ed_mid(Ty.ed_kind(B.tb_get(Ty.Edge, wx_es(x), U32.from_nat(i)))), face_mids(t, x))

def face_smps(+x: Wx, +es: List<&2, Nat>, +vs: List<&2, Nat>) -> List<&2, V.Point>:
  List.append(&2, V.Point, face_vpts(vs, x), face_mids(es, x))

def face_box(+x: Wx, +i: Nat) -> QA.Ab:
  B.tb_get(QA.Ab, wx_fbx(x), U32.from_nat(i))

def wp_lt(a: Wp, b: Wp) -> B.Sgn:
  Wp{+la, +ia, +ja} = a
  Wp{+lb, +ib, +jb} = b
  Bool.pick(B.Sgn, F64.is_eq(la, lb),
    Bool.pick(B.Sgn, Nat.is_eq(ia, ib), B.sgn_pick(Nat.is_lt(ja, jb), Nat.is_lt(jb, ja)),
      B.sgn_pick(Nat.is_lt(ia, ib), Nat.is_lt(ib, ia))),
    B.sgn_pick(F64.is_lt(la, lb), F64.is_lt(lb, la)))

def wp_so(s: B.So<&2, Wp>) -> List<&2, Wp>:
  B.So{ok, xs} = s
  xs

def wall_lo(+x: Wx, +i: Nat, +h: Nat) -> F64:
  QA.ab_ab_lo(face_box(x, i), face_box(x, h))

def wall_drop_go(le: Bool, +x: Wx, +i: Nat, +h: Nat) -> Bool:
  match le:
    case True{}: True{}
    case False{}: QA.n_share(face_vset(x, face_eset(x, i)), face_vset(x, face_eset(x, h)))

def wall_drop(+x: Wx, +i: Nat, +h: Nat) -> Bool:
  wall_drop_go(Nat.is_le(h, i), x, i, h)

def wall_cons(drop: Bool, +x: Wx, +i: Nat, +h: Nat, +acc: List<&2, Wp>) -> List<&2, Wp>:
  match drop:
    case True{}: acc
    case False{}: Wp{wall_lo(x, i, h), i, h} <> acc

def wall_hs(+x: Wx, +i: Nat, +j: Nat, +acc: List<&2, Wp>) -> List<&2, Wp>:
  match j:
    case 0n: acc
    case 1n+(+h): wall_hs(x, i, h, wall_cons(wall_drop(x, i, h), x, i, h, acc))

def wall_i(+x: Wx, +i: Nat, +acc: List<&2, Wp>) -> List<&2, Wp>:
  match i:
    case 0n: acc
    case 1n+(+k): wall_i(x, k, wall_hs(x, k, wx_nf(x), acc))

def wall_pairs(+x: Wx) -> List<&2, Wp>:
  wall_i(x, wx_nf(x), [])

def wall_fin(+lo: F64, w: Wr, +x: Wx, cert: Bool) -> String:
  Wr{+hi, +pr, +np} = w
  "min-wall " ++ QC.bv_show(QC.bv_mk(lo, hi, QC.st_estimated())) ++ " " ++
    Bool.pick(String, cert, "lo=certified", "lo=estimated boxes-uncertain") ++
    " faces=" ++ Nat.show(wx_nf(x)) ++ " pairs=" ++ Nat.show(np) ++ " pruned=" ++ Nat.show(pr)

def f_ints(fs: List<&2, SO.Fd>) -> List<&2, V.Point>:
  match fs:
    case []: []
    case f <> t: f_int_go(SO.interior(f), f_ints(t))

def smps_of(+b: Ty.Brep) -> List<&2, V.Point>:
  List.append(&2, V.Point, v_pts(Ty.brep_vs(b)),
    List.append(&2, V.Point, e_mids(Ty.brep_es(b)), f_ints(SO.fds_of(b))))

def dist_in(inn: Bool, +k: U64, +c: V.Point, +fs: List<&2, SO.Fd>, +ps: List<&2, V.Point>,
    +cert: Bool) -> String:
  match inn:
    case True{}: "distance 0 status=certified state=inside"
    case False{}: dist_bd(U64.is_eq(k, 3u64), U64.is_eq(k, 2u64), c, fs, ps, cert)

def wverts(+b: M.Body) -> List<&2, V.Point>:
  +pl = M.bd_pl(b)
  wverts_go(v_pts(Ty.brep_vs(M.bd_brep(b))), M.pl_mi(pl), M.pl_ti(pl))

def ex_zero() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def extrema_s(r: M.NR) -> String:
  match r:
    case M.NR_err{k, d}: "error: node failed; nothing measured"
    case M.NR_ok{+b, fx}:
      +m = M.body_ms(b)
      +ps = wverts(b)
      +z = ex_zero()
      "extrema x=[" ++ S.f_show(M.ms_x0(m)) ++ ", " ++ S.f_show(M.ms_x1(m)) ++ "] y=[" ++
        S.f_show(M.ms_y0(m)) ++ ", " ++ S.f_show(M.ms_y1(m)) ++ "] z=[" ++ S.f_show(M.ms_z0(m)) ++
        ", " ++ S.f_show(M.ms_z1(m)) ++ "] status=certified\n" ++ "witnesses xmin=" ++ pt_s(ex_wit(ps, 0n, False{}, z)) ++
        " xmax=" ++ pt_s(ex_wit(ps, 0n, True{}, z)) ++ " ymin=" ++ pt_s(ex_wit(ps, 1n, False{}, z)) ++
        " ymax=" ++ pt_s(ex_wit(ps, 1n, True{}, z)) ++ " zmin=" ++ pt_s(ex_wit(ps, 2n, False{}, z)) ++
        " zmax=" ++ pt_s(ex_wit(ps, 2n, True{}, z)) ++ " status=sampled"

def pts_min(ps: List<&2, V.Point>, +qs: List<&2, V.Point>, +best: F64) -> F64:
  match ps:
    case []: best
    case p <> t: pts_min(t, qs, pts_min_one(qs, p, best))

def clear_int(hit: Bool, +a: M.Body, +b: M.Body) -> String:
  match hit:
    case True{}: "clearance 0 status=certified state=interference"
    case False{}:
      +sa = QI.sms_of(a)
      +sb = QI.sms_of(b)
      +lo = QA.ab_ab_lo(QI.wbox(a), QI.wbox(b))
      +hi = pts_min(sa, sb, V.dbl_max())
      "clearance " ++ QC.bv_show(QC.bv_mk(lo, hi, QC.st_estimated())) ++ " lo=certified samples=" ++
        Nat.show(List.length(&2, V.Point, sa)) ++ "x" ++ Nat.show(List.length(&2, V.Point, sb))

def eb_of(+k: Ty.EdgeKind, +pa: V.Point, +pb: V.Point) -> QA.Ab:
  match k:
    case Ty.EK_degenerate{}: QA.ab_of3(I.ipt(V.pt_x(pa)), I.ipt(V.pt_y(pa)), I.ipt(V.pt_z(pa)))
    case Ty.EK_curve{+g, +d}: eb_cv(Q.gv_cv(g, d), d, pa, pb)

def wall_step(skip: Bool, +x: Wx, +lo: F64, +i: Nat, +j: Nat, +hi: F64, +pr: Nat, +np: Nat) -> Wr:
  match skip:
    case True{}: Wr{hi, Nat.add(pr, 1n), Nat.add(np, 1n)}
    case False{}:
      Wr{F64.min(hi, pts_min(face_smps(x, face_eset(x, i), face_vset(x, face_eset(x, i))),
        face_smps(x, face_eset(x, j), face_vset(x, face_eset(x, j))), hi)), pr, Nat.add(np, 1n)}

def dist_out(+k: U64, +c: V.Point, +fs: List<&2, SO.Fd>, +ps: List<&2, V.Point>, +cert: Bool) -> String:
  dist_in(U64.is_eq(k, 1u64), k, c, fs, ps, cert)

def dist_fin(ok: Bool, +b: M.Body, +x: F64, +y: F64, +z: F64) -> String:
  match ok:
    case False{}: "error invalid-input | dist | why: the point needs three finite numbers | fix: dist NODE X Y Z"
    case True{}:
      +fs = SO.fds_of(M.bd_brep(b))
      dist_out(SO.classify(fs, QI.loc_pt(M.bd_pl(b), x, y, z)), QI.loc_pt(M.bd_pl(b), x, y, z), fs,
        smps_of(M.bd_brep(b)), QA.fd_allok(fs))

def dist_s(r: M.NR, +x: F64, +y: F64, +z: F64) -> String:
  match r:
    case M.NR_err{k, d}: "error: node failed; nothing measured"
    case M.NR_ok{+b, fx}:
      Bool.pick(String, M.bd_open(b), "refused dist-needs-solid | dist | fix: thicken-open the shell to a solid first",
        dist_fin(QI.fin3(x, y, z), b, x, y, z))

def clear_go(+a: M.Body, +b: M.Body) -> String:
  clear_int(QI.rel_interf(a, b), a, b)

def bb_edges(es: List<&2, Ty.Edge>, +vs: B.Tb<&2, Ty.Vertex>, +acc: QA.Ab) -> QA.Ab:
  match es:
    case []: acc
    case e <> t:
      Ty.Ed{+g, +h0, +h1, +k} = e
      Ty.HV{+a, +ga} = h0
      Ty.HV{+b, +gb} = h1
      bb_edges(t, vs, QA.ab_hull(acc, eb_of(k, Ty.vx_p(B.tb_get(Ty.Vertex, vs, U32.from_nat(a))), Ty.vx_p(B.tb_get(Ty.Vertex, vs, U32.from_nat(b))))))

def bb_seed(ps: List<&2, QA.Ab>, +vs: B.Tb<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>) -> QA.Ab:
  match ps:
    case []: bb_edges(es, vs, QA.ab_zero())
    case p <> t: bb_edges(es, vs, QA.abs_hull_go(t, p))

def wall_scan(ps: List<&2, Wp>, +x: Wx, +w: Wr) -> Wr:
  match ps:
    case []: w
    case Wp{+lo, +i, +j} <> t:
      Wr{+hi, +pr, +np} = w
      wall_scan(t, x, wall_step(Bool.not(F64.is_lt(lo, hi)), x, lo, i, j, hi, pr, np))

def wall_rep(ps: List<&2, Wp>, +x: Wx, cert: Bool) -> String:
  match ps:
    case []: "min-wall none status=certified reason=all-faces-adjacent"
    case Wp{+lo, +i, +j} <> t: wall_fin(lo, wall_scan(Wp{lo, i, j} <> t, x, Wr{V.dbl_max(), 0n, 0n}), x, cert)

def clear_s(ra: M.NR, rb: M.NR) -> String:
  match ra:
    case M.NR_err{k, d}: "error: node failed; nothing measured"
    case M.NR_ok{+a, fa}:
      match rb:
        case M.NR_err{k, d}: "error: node failed; nothing measured"
        case M.NR_ok{+b, fb}:
          Bool.pick(String, Bool.or(M.bd_open(a), M.bd_open(b)),
            "refused clearance-needs-solid | clearance | fix: thicken-open the shell to a solid first", clear_go(a, b))

def bb_of(+b: Ty.Brep) -> QA.Ab:
  bb_seed(pt_abs(v_pts(Ty.brep_vs(b))), B.tb_of(Ty.Vertex, Ty.brep_vs(b), vx_dflt()), Ty.brep_es(b))

def wx_of(+b: Ty.Brep, +fs: List<&2, SO.Fd>) -> Wx:
  +fas = Ty.brep_fas(b)
  +bb = bb_of(b)
  +nf = List.length(&2, Ty.Face, fas)
  Wx{B.tb_of(Ty.Vertex, Ty.brep_vs(b), vx_dflt()), B.tb_of(Ty.Edge, Ty.brep_es(b), ed_dflt()),
    B.tb_of(Ty.Coedge, Ty.brep_ces(b), ce_dflt()), B.tb_of(Ty.Loop, Ty.brep_lps(b), lp_dflt()),
    B.tb_of(Ty.Face, fas, fa_dflt()), B.tb_of(QA.Ab, fb_align(fs, bb, nf, 0n), QA.ab_zero()), bb, nf}

def wall_out(+x: Wx, cert: Bool) -> String:
  +ps = wp_so(B.msort(~Wp, ~wp_lt, wall_pairs(x)))
  wall_rep(ps, x, cert)

def wall_body(has: Bool, +b: M.Body) -> String:
  match has:
    case False{}: "min-wall none status=certified reason=no-faces"
    case True{}:
      +br = M.bd_brep(b)
      +fs = SO.fds_of(br)
      wall_out(wx_of(br, fs), Bool.and(QA.fd_allok(fs),
        Nat.is_eq(List.length(&2, Ty.Face, Ty.brep_fas(br)), List.length(&2, SO.Fd, fs))))

def wall_s(r: M.NR) -> String:
  match r:
    case M.NR_err{k, d}: "error: node failed; nothing measured"
    case M.NR_ok{+b, fx}:
      Bool.pick(String, M.bd_open(b), "refused wall-needs-solid | wall | fix: thicken-open the shell to a solid first",
        wall_body(Bool.not(Nat.is_eq(List.length(&2, Ty.Face, Ty.brep_fas(M.bd_brep(b))), 0n)), b))
