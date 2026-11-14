import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c04/ops.bend as B4
import ../base/par.bend as B
import ../c06/model.bend as M
import ../c06/build.bend as BD
import ../c06/xp.bend as X
import ../c06/sx.bend as S
import ../k1/sf.bend as KS
import ./std.bend as SD
import ./thr.bend as KT

type Ax is Data:
  Ax{ p: V.Point, n: V.Dir }

type Ent is Data:
  Ent{ nd: U64, i: Nat, k: U64, h: M.Hs, ax: Ax, rb: F64, std: String, g: List<&2, F64> }

type Cf is Data:
  Cf{ cone: Bool, r: F64, o: V.Point, nm: String, lo: F64, hi: F64 }

type Pf is Data:
  Pf{ o: V.Point, n: V.Dir, ls: List<&2, Ty.HLoop> }

type Vr is Data:
  Vr{ ok: Bool, s: String }

def dsub(+a: V.Point, +b: V.Point) -> V.Dir:
  V.Dr{F64.sub(V.pt_x(a), V.pt_x(b)), F64.sub(V.pt_y(a), V.pt_y(b)), F64.sub(V.pt_z(a), V.pt_z(b))}

def ddot(+a: V.Dir, +b: V.Dir) -> F64:
  F64.add(F64.add(F64.mul(V.dr_x(a), V.dr_x(b)), F64.mul(V.dr_y(a), V.dr_y(b))), F64.mul(V.dr_z(a), V.dr_z(b)))

def dlen(+a: V.Dir) -> F64:
  F64.sqrt(ddot(a, a))

def dmn(+a: V.Dir, +b: V.Dir) -> V.Dir:
  V.Dr{F64.sub(V.dr_x(a), V.dr_x(b)), F64.sub(V.dr_y(a), V.dr_y(b)), F64.sub(V.dr_z(a), V.dr_z(b))}

def dsc(+a: V.Dir, +k: F64) -> V.Dir:
  V.Dr{F64.mul(V.dr_x(a), k), F64.mul(V.dr_y(a), k), F64.mul(V.dr_z(a), k)}

def tol(+x: F64) -> F64:
  F64.mul(1.0e-9f64, F64.add(1.0f64, F64.abs(x)))

def near(+a: F64, +b: F64) -> Bool:
  F64.is_le(F64.abs(F64.sub(a, b)), tol(b))

def r6(+x: F64) -> F64:
  F64.div(KS.f_round(F64.mul(x, 1.0e6f64)), 1.0e6f64)

def ax_p(+a: Ax) -> V.Point:
  Ax{+p, n} = a
  p

def ax_n(+a: Ax) -> V.Dir:
  Ax{p, +n} = a
  n

def depth(+a: Ax, +q: V.Point) -> F64:
  ddot(dsub(ax_p(a), q), ax_n(a))

def par(+d: V.Dir, +n: V.Dir) -> Bool:
  F64.is_le(dlen(M.dcross(d, n)), F64.mul(1.0e-9f64, F64.mul(dlen(d), dlen(n))))

def coax(+d: V.Dir, +o: V.Point, +a: Ax) -> Bool:
  +p = ax_p(a)
  +sc = tol(dlen(dsub(p, V.Pt{0.0f64, 0.0f64, 0.0f64})))
  Bool.and(par(d, ax_n(a)), F64.is_le(dlen(M.dcross(dsub(p, o), d)), F64.mul(sc, dlen(d))))

def hs0() -> M.Hs:
  M.Hs{0u64, "", "", X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}}

def ent_ax(+bb: M.Body, +f: M.Sel, +base: U64, +x: F64, +y: F64) -> Ax:
  +nm = M.sel_name(bb, f, base)
  +fr = M.frame_of(M.fa_nth(Ty.brep_fas(M.bd_brep(bb)), M.name_idx(M.bd_fns(bb), nm, 0n)))
  +q = M.hs_loc_of(String.is_empty(M.sel_nm(f)), fr, x, y)
  +pl = M.bd_pl(bb)
  Ax{M.pl_pt(M.fr_o(M.fr_at(fr, V.v2_x(q), V.v2_y(q))), pl), M.pl_dir(M.fr_n(fr), pl)}

def ents_hs(hs: List<&2, M.Hs>, +nd: U64, +i: Nat, +bb: M.Body, +f: M.Sel, +base: U64, +e: X.Env, +acc: List<&2, Ent>) -> List<&2, Ent>:
  match hs:
    case []: acc
    case +h <> +t:
      M.Hs{+k, sz, cls, +x, +y, r} = h
      +rest = ents_hs(t, nd, Nat.add(i, 1n), bb, f, base, e, acc)
      Bool.pick(List<&2, Ent>, U64.is_eq(k, 0u64), rest, Ent{nd, i, k, h, ent_ax(bb, f, base, X.xp_ev(x, e), X.xp_ev(y, e)), M.hs_bore(h, e), "", []} <> rest)

def cyl_at(+bb: M.Body, +f: M.Sel) -> M.Cyf:
  M.cyf_of(M.fa_nth(Ty.brep_fas(M.bd_brep(bb)), M.name_idx(M.bd_fns(bb), M.sel_nm(f), 0n)))

def ent_gv(+bb: M.Body, +f: M.Sel, +std: String, +z: F64, +nd: U64) -> Ent:
  +c = cyl_at(bb, f)
  +a = M.ax_canon(M.cyf_a(c))
  +r = M.cyf_r(c)
  +row = SD.row(M.gv_tab(std), M.d_nom(F64.mul(2.0f64, r)))
  +pl = M.bd_pl(bb)
  Ent{nd, 0n, 10u64, hs0(), Ax{M.pl_pt(M.ax_at(M.cyf_o(c), a, z), pl), M.pl_dir(a, pl)}, r, std,
    [z, F64.mul(2.0f64, r), SD.fv_go(row, 2n), SD.fv_go(row, 3n), SD.fv_go(row, 4n), SD.fv_go(row, 0n)]}

def ent_kw(+bb: M.Body, +f: M.Sel, +side: U64, +l: F64, +z: F64, +thru: Bool, +nd: U64) -> Ent:
  +br = M.bd_brep(bb)
  +fa = M.fa_nth(Ty.brep_fas(br), M.name_idx(M.bd_fns(bb), M.sel_nm(f), 0n))
  +c = M.cyf_of(fa)
  +a = M.ax_canon(M.cyf_a(c))
  +r = M.cyf_r(c)
  +sh = M.cyf_sh(c)
  +row = SD.row("key", M.d_nom(F64.mul(2.0f64, r)))
  +sp = M.kw_span(bb, fa, a, thru)
  +z0 = Bool.pick(F64, thru, V.v2_x(sp), z)
  +pl = M.bd_pl(bb)
  +sd = M.pl_dir(M.side_dir(side), pl)
  Ent{nd, 0n, 11u64, hs0(), Ax{M.pl_pt(M.ax_at(M.cyf_o(c), a, z0), pl), M.pl_dir(a, pl)}, r, Bool.pick(String, sh, "shaft", "hub"),
    [SD.fv_go(row, 2n), SD.fv_go(row, Bool.pick(Nat, sh, 4n, 5n)), Bool.pick(F64, thru, F64.sub(V.v2_y(sp), V.v2_x(sp)), l),
      V.dr_x(sd), V.dr_y(sd), V.dr_z(sd), F64.mul(2.0f64, r)]}

type St is Data:
  St{ go: Bool, n: U64, acc: List<&2, Ent> }

def st_go(+s: St) -> Bool:
  St{+g, n, acc} = s
  g

def st_n(+s: St) -> U64:
  St{g, +n, acc} = s
  n

def st_acc(+s: St) -> List<&2, Ent>:
  St{g, n, +acc} = s
  acc

def step_d(+o: M.Op, +acc: List<&2, Ent>) -> St:
  St{M.op_has_base(o), M.op_base(o), acc}

def bbody(+cs: List<&2, M.CE>, +base: U64) -> M.Body:
  M.nr_body(M.ce_r(M.ce_find(cs, base)))

def step(o: M.Op, +n: U64, +cs: List<&2, M.CE>, +e: X.Env, +acc: List<&2, Ent>) -> St:
  match o:
    case M.O_sholes{+base, +f, +hs, d, thru}: St{True{}, base, ents_hs(hs, n, 0n, bbody(cs, base), f, base, e, acc)}
    case M.O_groove{+base, +f, +std, +z}: St{True{}, base, ent_gv(bbody(cs, base), f, std, X.xp_ev(z, e), n) <> acc}
    case M.O_keyway{+base, +f, +side, +l, +z, +thru}:
      St{True{}, base, ent_kw(bbody(cs, base), f, side, X.xp_ev(l, e), X.xp_ev(z, e), thru, n) <> acc}
    case M.O_move{base, tx, ty, tz, q}: St{False{}, 0u64, acc}
    case M.O_rot{base, ax, deg}: St{False{}, 0u64, acc}
    case _: step_d(o, acc)

def walk(fuel: Nat, +ns: List<&2, M.Node>, +s: St, +cs: List<&2, M.CE>, +e: X.Env) -> List<&2, Ent>:
  match fuel:
    case 0n: st_acc(s)
    case 1n+k: walk(k, ns, Bool.pick(St, st_go(s), step(M.nd_op(ns, st_n(s)), st_n(s), cs, e, st_acc(s)), s), cs, e)

def cf_of(s: G.GVal, +nm: String, +ls: List<&2, Ty.HLoop>, +tl: B.Tb<&2, Ty.Loop>, +tc: B.Tb<&2, Ty.Coedge>, +te: B.Tb<&2, Ty.Edge>, +tv: B.Tb<&2, Ty.Vertex>,
    +pl: M.Pl, +a: Ax, +acc: List<&2, Cf>) -> List<&2, Cf>:
  match s:
    case G.GV_cy{w}:
      G.Cy{+o, +d, +r} = w
      +ow = M.pl_pt(o, pl)
      +x = M.lps_ext(ls, tl, tc, te, tv, pl, ax_p(a), M.dneg(ax_n(a)), M.ext0())
      Bool.pick(List<&2, Cf>, coax(M.pl_dir(d, pl), ow, a), Cf{False{}, r, ow, nm, V.v2_x(x), V.v2_y(x)} <> acc, acc)
    case G.GV_co{w}:
      G.Co{+o, +d, +k} = w
      +ow = M.pl_pt(o, pl)
      +x = M.lps_ext(ls, tl, tc, te, tv, pl, ax_p(a), M.dneg(ax_n(a)), M.ext0())
      Bool.pick(List<&2, Cf>, coax(M.pl_dir(d, pl), ow, a), Cf{True{}, F64.abs(k), ow, nm, V.v2_x(x), V.v2_y(x)} <> acc, acc)
    case _: acc

def cfs_go(fs: List<&2, BD.Fn>, fas: List<&2, Ty.Face>, +tl: B.Tb<&2, Ty.Loop>, +tc: B.Tb<&2, Ty.Coedge>, +te: B.Tb<&2, Ty.Edge>, +tv: B.Tb<&2, Ty.Vertex>,
    +pl: M.Pl, +a: Ax, +acc: List<&2, Cf>) -> List<&2, Cf>:
  match fs:
    case []: acc
    case f <> t:
      match fas:
        case []: acc
        case +fa <> u:
          Ty.Fa{g, +sf, +ls, same, slv, sla} = fa
          cfs_go(t, u, tl, tc, te, tv, pl, a, cf_of(sf, BD.fn_name(f), ls, tl, tc, te, tv, pl, a, acc))

def cfs(+b: M.Body, +a: Ax) -> List<&2, Cf>:
  +br = M.bd_brep(b)
  cfs_go(M.bd_fns(b), Ty.brep_fas(br), M.tl_of(br), M.tc_of(br), M.te_of(br), M.tv_of(br), M.bd_pl(b), a, [])

def cf_find(xs: List<&2, Cf>, +cone: Bool, +r: F64) -> Maybe<&2, Cf>:
  match xs:
    case []: None{}
    case +h <> +t:
      Cf{+c, +rr, +o, +nm, +lo, +hi} = h
      Bool.pick(Maybe<&2, Cf>, Bool.and(Bool.not(Bool.xor(c, cone)), near(rr, r)), Some{Cf{c, rr, o, nm, lo, hi}}, cf_find(t, cone, r))

def cf_span(xs: List<&2, Cf>, +r: F64, +acc: V.Vec2) -> V.Vec2:
  match xs:
    case []: acc
    case +h <> +t:
      Cf{+c, +rr, o, nm, +lo, +hi} = h
      cf_span(t, r, Bool.pick(V.Vec2, Bool.and(Bool.not(c), near(rr, r)), M.v2_add(M.v2_add(acc, lo), hi), acc))

def cf_some(m: Maybe<&2, Cf>) -> Bool:
  match m:
    case None{}: False{}
    case Some{c}: True{}

def cf_get(m: Maybe<&2, Cf>) -> Cf:
  match m:
    case None{}: Cf{False{}, F64.nan(), V.Pt{0.0f64, 0.0f64, 0.0f64}, "", F64.nan(), F64.nan()}
    case Some{c}: c

def cf_nm(+c: Cf) -> String:
  Cf{cone, r, o, +nm, lo, hi} = c
  nm

def cf_lo(+c: Cf) -> F64:
  Cf{cone, r, o, nm, +lo, hi} = c
  lo

def cf_hi(+c: Cf) -> F64:
  Cf{cone, r, o, nm, lo, +hi} = c
  hi

def cf_o(+c: Cf) -> V.Point:
  Cf{cone, r, +o, nm, lo, hi} = c
  o

def pf_of(s: G.GVal, +ls: List<&2, Ty.HLoop>, +pl: M.Pl, +acc: List<&2, Pf>) -> List<&2, Pf>:
  match s:
    case G.GV_pl{w}:
      G.Pl{+o, +u, +v} = w
      Pf{M.pl_pt(o, pl), M.pl_dir(M.dcross(u, v), pl), ls} <> acc
    case _: acc

def pfs_go(fas: List<&2, Ty.Face>, +pl: M.Pl, +acc: List<&2, Pf>) -> List<&2, Pf>:
  match fas:
    case []: acc
    case +fa <> u:
      Ty.Fa{g, +sf, +ls, same, slv, sla} = fa
      pfs_go(u, pl, pf_of(sf, ls, pl, acc))

def pf_find(xs: List<&2, Pf>, +p: V.Point, +d: V.Dir, +off: F64) -> Maybe<&2, Pf>:
  match xs:
    case []: None{}
    case +h <> +t:
      Pf{+o, +n, +ls} = h
      Bool.pick(Maybe<&2, Pf>, Bool.and(par(n, d), near(ddot(dsub(o, p), d), off)), Some{Pf{o, n, ls}}, pf_find(t, p, d, off))

def pf_some(m: Maybe<&2, Pf>) -> Bool:
  match m:
    case None{}: False{}
    case Some{c}: True{}

def pf_ls(m: Maybe<&2, Pf>) -> List<&2, Ty.HLoop>:
  match m:
    case None{}: []
    case Some{c}:
      Pf{o, n, +ls} = c
      ls

def pang(+x: F64, +y: F64) -> F64:
  +s = F64.add(F64.abs(x), F64.abs(y))
  Bool.pick(F64, F64.is_le(0.0f64, y),
    Bool.pick(F64, F64.is_le(0.0f64, x), F64.div(y, s), F64.sub(1.0f64, F64.div(x, s))),
    Bool.pick(F64, F64.is_lt(x, 0.0f64), F64.sub(2.0f64, F64.div(y, s)), F64.add(3.0f64, F64.div(x, s))))

def m4(+x: F64) -> F64:
  Bool.pick(F64, F64.is_lt(x, 0.0f64), F64.add(x, 4.0f64), x)

def arc_len(+a0: F64, +am: F64, +a1: F64, +closed: Bool) -> F64:
  +l = m4(F64.sub(a1, a0))
  Bool.pick(F64, closed, 4.0f64, Bool.pick(F64, F64.is_le(m4(F64.sub(am, a0)), l), l, F64.sub(4.0f64, l)))

def e1_of(+n: V.Dir) -> V.Dir:
  Bool.pick(V.Dir, F64.is_lt(F64.abs(V.dr_x(n)), 0.9f64), M.dcross(n, V.Dr{1.0f64, 0.0f64, 0.0f64}), M.dcross(n, V.Dr{0.0f64, 1.0f64, 0.0f64}))

def on_circ(+a: Ax, +q: V.Point, +re: F64) -> Bool:
  +v = dsub(q, ax_p(a))
  +h = ddot(v, ax_n(a))
  +rho = dlen(dmn(v, dsc(ax_n(a), h)))
  Bool.and(F64.is_le(F64.abs(h), tol(re)), near(rho, re))

def q_ang(+a: Ax, +q: V.Point) -> F64:
  +v = dsub(q, ax_p(a))
  +e1 = e1_of(ax_n(a))
  pang(ddot(v, e1), ddot(v, M.dcross(ax_n(a), e1)))

def gpt(r: G.GRes) -> Maybe<&2, V.Point>:
  match r:
    case G.Gok{v}:
      match v:
        case G.GV_p{p}: Some{p}
        case _: None{}
    case G.Gerr{k}: None{}

def ed_mid(+k: Ty.EdgeKind) -> Maybe<&2, V.Point>:
  +d = Ty.ekind_dom(k)
  gpt(B4.curve_at(Ty.ekind_curve(k), F64.mul(0.5f64, F64.add(G.dom_lo(d), G.dom_hi(d))), 64n))

def mid_cov(m: Maybe<&2, V.Point>, +a: Ax, +p0: V.Point, +p1: V.Point, +closed: Bool, +pl: M.Pl, +re: F64) -> F64:
  match m:
    case None{}: 0.0f64
    case Some{+q}:
      +qm = M.pl_pt(q, pl)
      Bool.pick(F64, Bool.and(on_circ(a, p0, re), Bool.and(on_circ(a, p1, re), on_circ(a, qm, re))),
        arc_len(q_ang(a, p0), q_ang(a, qm), q_ang(a, p1), closed), 0.0f64)

def cov_go(es: List<&2, Ty.Edge>, +tv: B.Tb<&2, Ty.Vertex>, +pl: M.Pl, +a: Ax, +re: F64, +acc: F64) -> F64:
  match es:
    case []: acc
    case +ed <> +t:
      Ty.Ed{g, +v0, +v1, +k} = ed
      +p0 = M.vpt(tv, v0, pl)
      +p1 = M.vpt(tv, v1, pl)
      +c = Bool.pick(F64, Bool.and(on_circ(a, p0, re), on_circ(a, p1, re)),
        mid_cov(ed_mid(k), a, p0, p1, Nat.is_eq(Ty.hv_idx(v0), Ty.hv_idx(v1)), pl, re), 0.0f64)
      cov_go(t, tv, pl, a, re, F64.add(acc, c))

def opens(+b: M.Body, +a: Ax, +re: F64) -> Bool:
  +br = M.bd_brep(b)
  F64.is_le(F64.sub(4.0f64, 1.0e-9f64), cov_go(Ty.brep_es(br), M.tv_of(br), M.bd_pl(b), a, re, 0.0f64))

def iv_s(+x: F64) -> String:
  "[" ++ S.f_show(x) ++ ", " ++ S.f_show(x) ++ "]"

def n_s(+x: F64) -> String:
  S.f_show(r6(x))

def pt_s(+p: V.Point) -> String:
  "(" ++ S.f_show(F64.add(V.pt_x(p), 0.0f64)) ++ "," ++ S.f_show(F64.add(V.pt_y(p), 0.0f64)) ++ "," ++ S.f_show(F64.add(V.pt_z(p), 0.0f64)) ++ ")"

def dir_s(+d: V.Dir) -> String:
  "(" ++ S.f_show(F64.add(V.dr_x(d), 0.0f64)) ++ "," ++ S.f_show(F64.add(V.dr_y(d), 0.0f64)) ++ "," ++ S.f_show(F64.add(V.dr_z(d), 0.0f64)) ++ ")"

def found_s(+m: Maybe<&2, Cf>, +r: F64, +what: String) -> String:
  Bool.pick(String, cf_some(m), " " ++ what ++ "=" ++ iv_s(F64.mul(2.0f64, r)), " " ++ what ++ "=missing")

def bore_vr(+cs: List<&2, Cf>, +b: M.Body, +a: Ax, +rb: F64, +re: F64) -> Vr:
  +m = cf_find(cs, False{}, rb)
  +op = opens(b, a, re)
  Vr{Bool.and(cf_some(m), op), found_s(m, rb, "bore") ++ " want=" ++ S.f_show(F64.mul(2.0f64, rb)) ++ Bool.pick(String, op, " opens=full-circle", " opens=not-a-full-circle")}

def vr_ok(+v: Vr) -> Bool:
  Vr{+o, s} = v
  o

def vr_s(+v: Vr) -> String:
  Vr{o, +s} = v
  s

def vr_and(+a: Vr, +b: Vr) -> Vr:
  Vr{Bool.and(vr_ok(a), vr_ok(b)), vr_s(a) ++ vr_s(b)}

def v_clear(+cs: List<&2, Cf>, +b: M.Body, +a: Ax, +rb: F64, +cls: String) -> Vr:
  vr_and(bore_vr(cs, b, a, rb, rb), Vr{True{}, " (ISO 273 " ++ M.hs_series(cls) ++ ")"})

def v_cbore(+cs: List<&2, Cf>, +b: M.Body, +a: Ax, +rb: F64, +sz: String) -> Vr:
  +f = SD.fa(sz)
  +cd = SD.fv(f, 8n)
  +ct = SD.fv(f, 9n)
  +dk = SD.fv(f, 6n)
  +kk = SD.fv(f, 7n)
  +m = cf_find(cs, False{}, F64.mul(0.5f64, cd))
  +dep = cf_hi(cf_get(m))
  +fit = Bool.and(F64.is_le(dk, cd), F64.is_le(kk, dep))
  vr_and(bore_vr(cs, b, a, rb, F64.mul(0.5f64, cd)),
    Vr{Bool.and(Bool.and(cf_some(m), near(dep, ct)), fit),
      found_s(m, F64.mul(0.5f64, cd), "counterbore") ++ " depth=" ++ n_s(dep) ++ " want=" ++ S.f_show(cd) ++ "x" ++ S.f_show(ct) ++
      " (DIN 974-1) head ISO 4762 dk=" ++ S.f_show(dk) ++ " k=" ++ S.f_show(kk) ++ " radial-clearance=" ++ n_s(F64.mul(0.5f64, F64.sub(cd, dk))) ++
      " below-face=" ++ n_s(F64.sub(dep, kk))})

def v_csk(+cs: List<&2, Cf>, +b: M.Body, +a: Ax, +rb: F64, +sz: String) -> Vr:
  +f = SD.fa(sz)
  +d2 = SD.fv(f, 12n)
  +dk = SD.fv(f, 10n)
  +m = cf_find(cs, True{}, 1.0f64)
  +df = F64.mul(2.0f64, F64.abs(depth(a, cf_o(cf_get(m)))))
  vr_and(bore_vr(cs, b, a, rb, F64.mul(0.5f64, d2)),
    Vr{Bool.and(Bool.and(cf_some(m), near(df, d2)), F64.is_le(dk, df)),
      Bool.pick(String, cf_some(m), " cone=90deg face-diameter=" ++ n_s(df), " cone=missing") ++ " want=" ++ S.f_show(d2) ++
      " (DIN 74 F) head ISO 10642 dk=" ++ S.f_show(dk) ++ " below-face=" ++ n_s(F64.mul(0.5f64, F64.sub(df, dk)))})

def win_of(+sz: String, +cls: String) -> V.Vec2:
  +ds = KT.desig(sz)
  KT.win(KT.cls_code(cls), ds, KT.pr_or(KT.pr_find(KT.pitches(), KT.ds_p(ds))))

def v_tap(+cs: List<&2, Cf>, +b: M.Body, +a: Ax, +rb: F64, +sz: String, +cls: String) -> Vr:
  +c = M.hs_cls(cls)
  +w = win_of(sz, c)
  +dm = F64.mul(2.0f64, rb)
  +inw = Bool.and(F64.is_le(F64.sub(V.v2_x(w), 1.0e-9f64), dm), F64.is_le(dm, F64.add(V.v2_y(w), 1.0e-9f64)))
  vr_and(bore_vr(cs, b, a, rb, rb),
    Vr{inw, " tap-drill=" ++ S.f_show(dm) ++ " (ISO 2306) minor-window=[" ++ S.f_show(KT.r3(V.v2_x(w))) ++ ", " ++ S.f_show(KT.r3(V.v2_y(w))) ++
      "] (ISO 965-1 " ++ c ++ ") thread " ++ KT.ds_name(KT.desig(sz)) ++ " " ++ c})

def v_ring(+b: M.Body, +a: Ax, +std: String, +g: List<&2, F64>) -> Vr:
  +z = SD.fv_go(g, 0n)
  +d1 = SD.fv_go(g, 1n)
  +d2 = SD.fv_go(g, 2n)
  +m = SD.fv_go(g, 3n)
  +nmin = SD.fv_go(g, 4n)
  +cs = cfs(b, Ax{ax_p(a), M.dneg(ax_n(a))})
  +f = cf_find(cs, False{}, F64.mul(0.5f64, d2))
  +lo = cf_lo(cf_get(f))
  +hi = cf_hi(cf_get(f))
  +sp = cf_span(cs, F64.mul(0.5f64, d1), M.ext0())
  +ok = Bool.and(cf_some(f), Bool.and(near(lo, 0.0f64), near(F64.sub(hi, lo), m)))
  Vr{ok, " d1=" ++ S.f_show(SD.fv_go(g, 5n)) ++ " face-d=" ++ n_s(d1) ++ " z=[" ++ S.f_show(z) ++ ", " ++ n_s(F64.add(z, m)) ++ "]:" ++ found_s(f, F64.mul(0.5f64, d2), "groove-diameter") ++
    " width=" ++ n_s(F64.sub(hi, lo)) ++ " want=" ++ S.f_show(d2) ++ "x" ++ S.f_show(m) ++ " margins=" ++ n_s(F64.sub(lo, V.v2_x(sp))) ++ "," ++
    n_s(F64.sub(V.v2_y(sp), hi)) ++ " n-min=" ++ S.f_show(nmin)}

def v_key(+b: M.Body, +a: Ax, +std: String, +g: List<&2, F64>) -> Vr:
  +bw = SD.fv_go(g, 0n)
  +t = SD.fv_go(g, 1n)
  +l = SD.fv_go(g, 2n)
  +sd = {V.Dr{SD.fv_go(g, 3n), SD.fv_go(g, 4n), SD.fv_go(g, 5n)} : V.Dir}
  +d1 = SD.fv_go(g, 6n)
  +sh = String.eq(std, "shaft")
  +p = ax_p(a)
  +w = M.dcross(sd, ax_n(a))
  +br = M.bd_brep(b)
  +ps = pfs_go(Ty.brep_fas(br), M.bd_pl(b), [])
  +want = Bool.pick(F64, sh, F64.sub(F64.mul(0.5f64, d1), t), F64.add(F64.mul(0.5f64, d1), t))
  +bot = pf_find(ps, p, sd, want)
  +w0 = pf_find(ps, p, w, F64.mul(0.5f64, bw))
  +w1 = pf_find(ps, p, w, F64.mul(F64.neg(0.5f64), bw))
  +x = M.lps_ext(pf_ls(bot), M.tl_of(br), M.tc_of(br), M.te_of(br), M.tv_of(br), M.bd_pl(b), p, ax_n(a), M.ext0())
  +len = F64.sub(V.v2_y(x), V.v2_x(x))
  +ok = Bool.and(Bool.and(pf_some(bot), Bool.and(pf_some(w0), pf_some(w1))), Bool.or(Bool.not(sh), Bool.and(near(V.v2_x(x), 0.0f64), near(len, l))))
  Vr{ok, " " ++ std ++ " d1=" ++ S.f_show(M.d_nom(d1)) ++ " face-d=" ++ n_s(d1) ++ " side=" ++ dir_s(sd) ++ ": b=" ++ S.f_show(bw) ++ Bool.pick(String, sh, " t1=", " t2=") ++ S.f_show(t) ++
    Bool.pick(String, pf_some(bot), " bottom-from-axis=" ++ n_s(want), " bottom=missing") ++
    Bool.pick(String, Bool.and(pf_some(w0), pf_some(w1)), " width=" ++ S.f_show(bw), " walls=missing") ++
    Bool.pick(String, sh, " length=" ++ n_s(len) ++ " want=" ++ S.f_show(bw) ++ "x" ++ S.f_show(t) ++ "x" ++ S.f_show(l), "")}

def v_kind(k: U64, +cs: List<&2, Cf>, +b: M.Body, +a: Ax, +rb: F64, +sz: String, +cls: String) -> Vr:
  match k:
    case 1u64: v_clear(cs, b, a, rb, cls)
    case 2u64: v_cbore(cs, b, a, rb, sz)
    case 3u64: v_csk(cs, b, a, rb, sz)
    case _: v_tap(cs, b, a, rb, sz, cls)

def ent_tag(+k: U64, +cls: String) -> String:
  Bool.pick(String, U64.is_eq(k, 1u64), M.hs_series(cls), Bool.pick(String, U64.is_eq(k, 4u64), M.hs_cls(cls), "medium"))

def st_s(+v: Vr) -> String:
  vr_s(v) ++ Bool.pick(String, vr_ok(v), " status=pass\n", " status=fail\n")

def ent_hole(+nd: U64, +i: Nat, +k: U64, +h: M.Hs, +a: Ax, +rb: F64, +b: M.Body) -> Vr:
  M.Hs{kk, +sz, +cls, x, y, r} = h
  +v = v_kind(k, cfs(b, a), b, a, rb, sz, cls)
  Vr{vr_ok(v), "std hole " ++ U64.show(nd) ++ "#" ++ Nat.show(Nat.add(i, 1n)) ++ " " ++ M.hs_kind(k) ++ " " ++ sz ++ " " ++ ent_tag(k, cls) ++
    " at=" ++ pt_s(ax_p(a)) ++ " n=" ++ dir_s(ax_n(a)) ++ ":" ++ st_s(v)}

def ent_go(k: U64, +nd: U64, +i: Nat, +h: M.Hs, +a: Ax, +rb: F64, +std: String, +g: List<&2, F64>, +b: M.Body) -> Vr:
  match k:
    case 10u64:
      +v = v_ring(b, a, std, g)
      Vr{vr_ok(v), "std ring-groove " ++ U64.show(nd) ++ " " ++ M.gv_name(std) ++ vr_s(v) ++ " (" ++ M.gv_name(std) ++ ")" ++ Bool.pick(String, vr_ok(v), " status=pass\n", " status=fail\n")}
    case 11u64:
      +v = v_key(b, a, std, g)
      Vr{vr_ok(v), "std keyway " ++ U64.show(nd) ++ " DIN 6885-1" ++ st_s(v)}
    case _: ent_hole(nd, i, k, h, a, rb, b)

def ent_vr(+en: Ent, +b: M.Body) -> Vr:
  Ent{+nd, +i, +k, +h, +a, +rb, +std, +g} = en
  ent_go(k, nd, i, h, a, rb, std, g, b)

type Tl is Data:
  Tl{ s: String, n: Nat, p: Nat }

def tl_go(es: List<&2, Ent>, +b: M.Body, +acc: Tl) -> Tl:
  match es:
    case []: acc
    case +e <> +t:
      Tl{+s, +n, +p} = acc
      +v = ent_vr(e, b)
      tl_go(t, b, Tl{s ++ vr_s(v), Nat.add(n, 1n), Bool.pick(Nat, vr_ok(v), Nat.add(p, 1n), p)})

def cites() -> String:
  "std data clear: " ++ SD.cite("clear") ++ "\nstd data tap: " ++ SD.cite("tap") ++ "\nstd data shcs: " ++ SD.cite("shcs") ++
    "\nstd data cbore: " ++ SD.cite("cbore") ++ "\nstd data cskh: " ++ SD.cite("cskh") ++ "\nstd data csk: " ++ SD.cite("csk") ++ "\nstd data hex: " ++ SD.cite("hex") ++
    "\nstd data ring_shaft: " ++ SD.cite("ring_shaft") ++ "\nstd data ring_bore: " ++ SD.cite("ring_bore") ++ "\nstd data key: " ++ SD.cite("key") ++ "\n"

def tl_out(+t: Tl, +nd: U64) -> String:
  Tl{+s, +n, +p} = t
  s ++ "std node " ++ U64.show(nd) ++ ": " ++ Nat.show(n) ++ " features, " ++ Nat.show(p) ++ " pass, " ++ Nat.show(Nat.sub(n, p)) ++
    " fail, 0 not-analyzed\n" ++ cites()

def ents_of(+p: M.Part, +n: U64, +cs: List<&2, M.CE>) -> List<&2, Ent>:
  M.Pt{+ps, +ns, ms, ts} = p
  walk(Nat.add(List.length(&2, M.Node, ns), 1n), ns, St{True{}, n, []}, cs, X.env_of(M.pvs_of(ps)))

def node_std(+p: M.Part, +n: U64, +old: List<&2, M.CE>) -> String:
  +cs = M.ev_for(p, [n], old)
  +r = M.ce_r(M.ce_find(cs, n))
  Bool.pick(String, M.nr_ok(r), tl_out(tl_go(ents_of(p, n, cs), M.nr_body(r), Tl{"", 0n, 0n}), n), "error: node failed; nothing checked\n")

def col_s(+a: SD.Fa, +i: Nat, +nm: String) -> String:
  +v = SD.fv(a, i)
  Bool.pick(String, F64.is_eq(v, v), " " ++ nm ++ "=" ++ S.f_show(v), "")

def rec_s(+m: String) -> String:
  +a = SD.fa(m)
  Bool.pick(String, SD.fa_ok(m),
    "std " ++ m ++ col_s(a, 1n, "pitch") ++ col_s(a, 2n, "clearance-fine") ++ col_s(a, 3n, "clearance-medium") ++ col_s(a, 4n, "clearance-coarse") ++
      col_s(a, 5n, "tap-drill") ++ col_s(a, 6n, "iso4762-dk") ++ col_s(a, 7n, "iso4762-k") ++ col_s(a, 8n, "counterbore-d") ++
      col_s(a, 9n, "counterbore-t") ++ col_s(a, 10n, "iso10642-dk") ++ col_s(a, 11n, "iso10642-k") ++ col_s(a, 12n, "countersink-d") ++
      col_s(a, 13n, "hex-af") ++ "\n" ++ cites(),
    "error invalid-input | std | why: std-size-unknown: " ++ m ++ " | fix: sizes with records: " ++ SD.sizes() ++ "\n")

def std_out(+p: M.Part, +arg: String, +old: List<&2, M.CE>) -> String:
  Bool.pick(String, String.is_empty(arg), "std sizes " ++ SD.sizes() ++ "\nstd ring-groove DIN 471 shaft d1: " ++ SD.row_keys("ring_shaft") ++
      "\nstd ring-groove DIN 472 bore d1: " ++ SD.row_keys("ring_bore") ++ "\nstd keyway DIN 6885-1 shaft d1 over-to: " ++ SD.row_keys("key") ++ "\n" ++ cites(),
    Bool.pick(String, String.starts_with(arg, "M"), rec_s(arg), node_std(p, S.u64_of(S.Sx_a{arg}), old)))

def tap_line(+en: Ent, +b: M.Body) -> String:
  Ent{+nd, +i, +k, +h, +a, +rb, std, g} = en
  M.Hs{kk, +sz, +cls, x, y, r} = h
  +m = cf_find(cfs(b, a), False{}, rb)
  +nm = cf_nm(cf_get(m))
  +sp = KT.tg_span(KT.tg_named(b, nm))
  Bool.pick(String, Bool.and(U64.is_eq(k, 4u64), cf_some(m)),
    KT.th_line(M.Th{nd, "h" ++ U64.show(nd) ++ "-" ++ Nat.show(Nat.add(i, 1n)), nm, sz, M.hs_cls(cls), V.v2_x(sp), V.v2_y(sp)}, b), "")

def taps_go(es: List<&2, Ent>, +b: M.Body) -> String:
  match es:
    case []: ""
    case +e <> +t: tap_line(e, b) ++ taps_go(t, b)

def taps_s(+p: M.Part, +n: U64, +old: List<&2, M.CE>) -> String:
  +cs = M.ev_for(p, [n], old)
  +r = M.ce_r(M.ce_find(cs, n))
  Bool.pick(String, M.nr_ok(r), taps_go(ents_of(p, n, cs), M.nr_body(r)), "")
