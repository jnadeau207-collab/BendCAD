import Base
import ../c01/types.bend as V
import ../c04/types.bend as Ty
import ../c06/model.bend as M
import ../c06/xp.bend as X
import ../c06/sx.bend as S
import ../k1/sf.bend as KS
import ./std.bend as SD
import ./thr.bend as KT
import ./mat.bend as KM
import ./kstd.bend as KSD
import ../c07/sol.bend as SO
import ../c11/qinterf.bend as QI

type Sw is Data:
  Sw{ ok: Bool, sz: String, l: F64 }

def sw_go(fuel: Nat, o: M.Op, +ns: List<&2, M.Node>, +e: X.Env) -> Sw:
  match fuel:
    case 0n: Sw{False{}, "", 0.0f64}
    case 1n+k:
      match o:
        case M.O_screw{std, +sz, +l, thr}: Sw{True{}, sz, X.xp_ev(l, e)}
        case M.O_move{+base, tx, ty, tz, q}: sw_go(k, M.nd_op(ns, base), ns, e)
        case M.O_rot{+base, ax, deg}: sw_go(k, M.nd_op(ns, base), ns, e)
        case _: Sw{False{}, "", 0.0f64}

def sw_ok(+s: Sw) -> Bool:
  Sw{+ok, sz, l} = s
  ok

def sw_sz(+s: Sw) -> String:
  Sw{ok, +sz, l} = s
  sz

def sw_l(+s: Sw) -> F64:
  Sw{ok, sz, +l} = s
  l

type It is Data:
  It{ ok: Bool, nd: U64, what: String, lo: F64, hi: F64, mod: Bool }

def it_none() -> It:
  It{False{}, 0u64, "", 0.0f64, 0.0f64, False{}}

def it_ok(+t: It) -> Bool:
  It{+ok, nd, what, lo, hi, mod} = t
  ok

def it_nd(+t: It) -> U64:
  It{ok, +nd, what, lo, hi, mod} = t
  nd

def it_what(+t: It) -> String:
  It{ok, nd, +what, lo, hi, mod} = t
  what

def it_lo(+t: It) -> F64:
  It{ok, nd, what, +lo, hi, mod} = t
  lo

def it_hi(+t: It) -> F64:
  It{ok, nd, what, lo, +hi, mod} = t
  hi

def it_mod(+t: It) -> Bool:
  It{ok, nd, what, lo, hi, +mod} = t
  mod

def ov(+lo: F64, +hi: F64, +l: F64) -> F64:
  F64.max(0.0f64, F64.sub(F64.min(hi, l), F64.max(lo, 0.0f64)))

def it_best(+a: It, +b: It, +l: F64) -> It:
  Bool.pick(It, Bool.and(it_ok(b), Bool.or(Bool.not(it_ok(a)), F64.is_lt(ov(it_lo(a), it_hi(a), l), ov(it_lo(b), it_hi(b), l)))), b, a)

def at_t(+p: V.Point, +o: V.Point, +d: V.Dir) -> F64:
  KS.dot(KS.psub(p, o), d)

def coax_w(+ow: V.Point, +aw: V.Dir, +o: V.Point, +d: V.Dir) -> Bool:
  Bool.and(F64.is_lt(KS.dlen(KS.cross(aw, d)), 1.0e-6f64), F64.is_lt(KS.dlen(KS.cross(KS.psub(o, ow), aw)), 1.0e-4f64))

def z_pt(+tg: KT.TG, +z: F64) -> V.Point:
  KS.padd(KT.tg_o(tg), F64.sub(z, KS.dot(KS.psub(KT.tg_o(tg), V.Pt{0.0f64, 0.0f64, 0.0f64}), KT.tg_ax(tg))), KT.tg_ax(tg))

def same_size(+a: String, +b: String) -> Bool:
  String.eq(KT.ds_name(KT.desig(a)), KT.ds_name(KT.desig(b)))

def th_it(+th: M.Thr, +b: M.Body, +o: V.Point, +d: V.Dir, +sz: String) -> It:
  +tg = KT.tg_named(b, KT.th_face(th))
  +pl = M.bd_pl(b)
  +z = KT.th_z(th)
  +t0 = at_t(M.pl_pt(z_pt(tg, V.v2_x(z)), pl), o, d)
  +t1 = at_t(M.pl_pt(z_pt(tg, V.v2_y(z)), pl), o, d)
  It{Bool.and(Bool.and(KT.tg_ok(tg), KT.tg_inner(tg)), Bool.and(same_size(KT.th_d(th), sz), coax_w(M.pl_pt(KT.tg_o(tg), pl), M.pl_dir(KT.tg_ax(tg), pl), o, d))),
    KT.th_node(th), KT.ds_name(KT.desig(KT.th_d(th))) ++ " " ++ KT.th_c(th) ++ " (thread " ++ KT.th_name(th) ++ ")", F64.min(t0, t1), F64.max(t0, t1), False{}}

def ths_it(ts: List<&2, M.Thr>, +n: U64, +b: M.Body, +o: V.Point, +d: V.Dir, +sz: String, +l: F64, +acc: It) -> It:
  match ts:
    case []: acc
    case +h <> t: ths_it(t, n, b, o, d, sz, l, Bool.pick(It, U64.is_eq(KT.th_node(h), n), it_best(acc, th_it(h, b, o, d, sz), l), acc))

def cyl_span(xs: List<&2, KSD.Cf>, +r: F64) -> V.Vec2:
  match xs:
    case []: V.V2{1.0e300f64, F64.neg(1.0e300f64)}
    case +h <> t:
      KSD.Cf{+c, +rr, o, nm, +lo, +hi} = h
      Bool.pick(V.Vec2, Bool.and(Bool.not(c), KSD.near(rr, r)), V.V2{lo, hi}, cyl_span(t, r))

def en_it(+en: KSD.Ent, +b: M.Body, +o: V.Point, +d: V.Dir, +sz: String) -> It:
  KSD.Ent{+nd, i, +k, +h, +a, +rb, std, g} = en
  M.Hs{kk, +hsz, +cls, x, y, r} = h
  +sp = cyl_span(KSD.cfs(b, KSD.Ax{o, M.dneg(d)}), rb)
  It{Bool.and(Bool.or(U64.is_eq(k, 4u64), U64.is_eq(k, 5u64)), Bool.and(same_size(hsz, sz), coax_w(KSD.ax_p(a), KSD.ax_n(a), o, d))),
    nd, KT.ds_name(KT.desig(hsz)) ++ " " ++ M.hs_cls(cls) ++ Bool.pick(String, U64.is_eq(k, 5u64), " (modelled tapped hole)", " (tapped hole)"),
    V.v2_x(sp), V.v2_y(sp), U64.is_eq(k, 5u64)}

def ens_it(es: List<&2, KSD.Ent>, +b: M.Body, +o: V.Point, +d: V.Dir, +sz: String, +l: F64, +acc: It) -> It:
  match es:
    case []: acc
    case +h <> t: ens_it(t, b, o, d, sz, l, it_best(acc, en_it(h, b, o, d, sz), l))

def has_pre(+s: String, +ps: List<&2, String>) -> Bool:
  match ps:
    case []: False{}
    case +h <> t: Bool.or(String.starts_with(s, h), has_pre(s, t))

def fam(+g: String) -> U64:
  Bool.pick(U64, has_pre(g, ["EN AW", "AW-", "1050", "2024", "5083", "5754", "6060", "6061", "6063", "6082", "7020", "7075", "AlMg", "AlSi", "AlCu", "AlZn"]), 2u64,
    Bool.pick(U64, has_pre(g, ["S235", "S275", "S355", "E295", "E335", "C15", "C22", "C35", "C45", "C60", "11SMn", "16MnCr5", "34CrNiMo6", "42CrMo4", "1.0", "1.1", "1.4", "1.5", "1.6", "1.7", "1.8", "AISI", "SAE", "304", "316", "1018", "1045", "4140"]), 1u64, 0u64))

def mat_g(m: Maybe<&2, M.Grade>) -> String:
  match m:
    case None{}: ""
    case Some{+g}:
      M.Gr{nd, +grade, rho, cte, e, nu} = g
      grade

type Ck is Data:
  Ck{ st: Nat, s: String }

def ck_st(+c: Ck) -> Nat:
  Ck{+st, s} = c
  st

def ck_s(+c: Ck) -> String:
  Ck{st, +s} = c
  s

def st_s(+k: Nat) -> String:
  Bool.pick(String, Nat.is_eq(k, 0n), "pass", Bool.pick(String, Nat.is_eq(k, 1n), "not-analyzed", "fail"))

def th_req(+g: String, +d: F64, +eng: F64, +what: String, +nd: U64) -> Ck:
  +f = fam(g)
  +req = F64.mul(d, Bool.pick(F64, U64.is_eq(f, 2u64), 2.0f64, 1.0f64))
  +st = Bool.pick(Nat, U64.is_eq(f, 0u64), 1n, Bool.pick(Nat, F64.is_le(F64.sub(req, 1.0e-9f64), eng), 0n, 2n))
  Ck{st, "fasten thread into " ++ what ++ " node " ++ U64.show(nd) ++ ": engaged=" ++ KSD.n_s(eng) ++
    Bool.pick(String, U64.is_eq(f, 0u64),
      Bool.pick(String, String.is_empty(g), " required=unknown: no material is declared on node " ++ U64.show(nd),
        " required=unknown: " ++ g ++ " is not a steel or aluminium designation the rule covers") ++ " (the Nord-Lock rule covers steel, 1 x d, and aluminium, 2 x d)",
      " required=" ++ KSD.n_s(req) ++ Bool.pick(String, U64.is_eq(f, 2u64), " (2 x d in aluminium, ", " (1 x d in steel, ") ++ g ++ " by designation; Nord-Lock 2015)") ++
    " status=" ++ st_s(st) ++ "\n"}

def th_ck(+t: It, +ms: List<&2, M.Grade>, +d: F64, +l: F64, +sz: String) -> Ck:
  Bool.pick(Ck, Bool.not(it_ok(t)), Ck{2n, "fasten thread: no internal " ++ KT.ds_name(KT.desig(sz)) ++ " thread in the listed parts is coaxial with the screw status=fail\n"},
    Bool.pick(Ck, it_mod(t), Ck{1n, "fasten thread into " ++ it_what(t) ++ " node " ++ U64.show(it_nd(t)) ++ ": the span of a modelled tapped hole along the screw is not measured yet status=not-analyzed\n"},
      th_req(mat_g(KM.mat_find(ms, it_nd(t))), d, ov(it_lo(t), it_hi(t), l), it_what(t), it_nd(t))))

type Pl2 is Data:
  Pl2{ seat: Bool, cut: F64, below: F64 }

def pl_go(xs: List<&2, KSD.Pf>, +o: V.Point, +d: V.Dir, +l: F64, +h: F64, +acc: Pl2) -> Pl2:
  match xs:
    case []: acc
    case +x <> t:
      KSD.Pf{+po, +n, ls} = x
      Pl2{+seat, +cut, +below} = acc
      +par = F64.is_lt(KS.dlen(KS.cross(n, d)), 1.0e-6f64)
      +tz = at_t(po, o, d)
      pl_go(t, o, d, l, h, Pl2{Bool.or(seat, Bool.and(par, F64.is_lt(F64.abs(F64.sub(tz, l)), 1.0e-6f64))),
        Bool.pick(F64, Bool.and(par, Bool.and(F64.is_lt(F64.add(l, 1.0e-6f64), tz), F64.is_lt(tz, F64.sub(h, 1.0e-6f64)))), F64.max(cut, F64.sub(tz, l)), cut),
        Bool.pick(F64, Bool.and(par, F64.is_lt(tz, F64.sub(l, 1.0e-6f64))), F64.max(below, tz), below)})

def pl2_cut(+p: Pl2) -> F64:
  Pl2{seat, +cut, below} = p
  cut

def cy_go(xs: List<&2, KSD.Cf>, +lo: F64, +hi: F64, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> t:
      KSD.Cf{c, +r, o, nm, +clo, +chi} = x
      cy_go(t, lo, hi, Bool.pick(F64, Bool.and(F64.is_lt(clo, F64.sub(hi, 1.0e-6f64)), F64.is_lt(F64.add(lo, 1.0e-6f64), chi)), F64.min(acc, r), acc))

def pts_pl(ns: List<&2, U64>, +cs: List<&2, M.CE>, +acc: List<&2, KSD.Pf>) -> List<&2, KSD.Pf>:
  match ns:
    case []: acc
    case +n <> t:
      +b = M.nr_body(M.ce_r(M.ce_find(cs, n)))
      pts_pl(t, cs, KSD.pfa_go(Ty.brep_fas(M.bd_brep(b)), M.bd_pl(b), acc))

def pts_cy(ns: List<&2, U64>, +cs: List<&2, M.CE>, +o: V.Point, +d: V.Dir, +lo: F64, +hi: F64, +acc: F64) -> F64:
  match ns:
    case []: acc
    case +n <> t: pts_cy(t, cs, o, d, lo, hi, cy_go(KSD.cfs(M.nr_body(M.ce_r(M.ce_find(cs, n))), KSD.Ax{o, M.dneg(d)}), lo, hi, acc))

def cs12() -> List<&2, V.Vec2>:
  [V.V2{1.0f64, 0.0f64}, V.V2{0.8660254037844387f64, 0.5f64}, V.V2{0.5f64, 0.8660254037844387f64}, V.V2{0.0f64, 1.0f64},
   V.V2{F64.neg(0.5f64), 0.8660254037844387f64}, V.V2{F64.neg(0.8660254037844387f64), 0.5f64}, V.V2{F64.neg(1.0f64), 0.0f64}, V.V2{F64.neg(0.8660254037844387f64), F64.neg(0.5f64)},
   V.V2{F64.neg(0.5f64), F64.neg(0.8660254037844387f64)}, V.V2{0.0f64, F64.neg(1.0f64)}, V.V2{0.5f64, F64.neg(0.8660254037844387f64)}, V.V2{0.8660254037844387f64, F64.neg(0.5f64)}]

def ring(cs: List<&2, V.Vec2>, +c: V.Point, +e1: V.Dir, +e2: V.Dir, +r: F64, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match cs:
    case []: acc
    case +q <> t: ring(t, c, e1, e2, r, KS.padd(KS.padd(c, F64.mul(r, V.v2_x(q)), e1), F64.mul(r, V.v2_y(q)), e2) <> acc)

def ring_at(+o: V.Point, +d: V.Dir, +r: F64, +t: F64, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  ring(cs12(), KS.padd(o, t, d), KS.perp_of(d), KS.cross(d, KS.perp_of(d)), r, acc)

def rings(+o: V.Point, +d: V.Dir, +r: F64, +lo: F64, +hi: F64) -> List<&2, V.Point>:
  +w = F64.sub(hi, lo)
  ring_at(o, d, r, F64.add(lo, F64.mul(0.2f64, w)), ring_at(o, d, r, F64.add(lo, F64.mul(0.5f64, w)), ring_at(o, d, r, F64.add(lo, F64.mul(0.8f64, w)), [])))

def in_go(ps: List<&2, V.Point>, +fs: List<&2, SO.Fd>, +pl: M.Pl, +acc: Nat) -> Nat:
  match ps:
    case []: acc
    case +q <> t: in_go(t, fs, pl, Bool.pick(Nat, U64.is_eq(SO.classify(fs, QI.loc_pt(pl, V.pt_x(q), V.pt_y(q), V.pt_z(q))), 1u64), Nat.add(acc, 1n), acc))

def pts_in(ns: List<&2, U64>, +cs: List<&2, M.CE>, +ps: List<&2, V.Point>, +acc: Nat) -> Nat:
  match ns:
    case []: acc
    case +n <> t:
      +b = M.nr_body(M.ce_r(M.ce_find(cs, n)))
      pts_in(t, cs, ps, in_go(ps, SO.fds_of(M.bd_brep(b)), M.bd_pl(b), acc))

def hit_s(+n: Nat, +m: Nat) -> String:
  Bool.pick(String, Nat.is_eq(m, 0n), "", " interference-samples=" ++ Nat.show(n) ++ "/" ++ Nat.show(m))

def hd_ck(+p2: Pl2, +rmin: F64, +dk: F64, +k: F64, +l: F64, +hit: Nat) -> Ck:
  Pl2{+seat, +cut, +below} = p2
  +room = Bool.pick(F64, F64.is_lt(rmin, 1.0e299f64), F64.sub(rmin, F64.mul(0.5f64, dk)), 1.0e300f64)
  +inter = Bool.or(Bool.or(F64.is_lt(room, F64.neg(1.0e-9f64)), F64.is_lt(0.0f64, cut)), Nat.is_lt(0n, hit))
  +st = Bool.pick(Nat, Bool.and(seat, Bool.not(inter)), 0n, 2n)
  Ck{st, "fasten head dk=" ++ KSD.n_s(dk) ++ " k=" ++ KSD.n_s(k) ++ ":" ++
    Bool.pick(String, F64.is_lt(room, 1.0e299f64), " counterbore d=" ++ KSD.n_s(F64.mul(2.0f64, rmin)) ++ " radial-clearance=" ++ KSD.n_s(room), " no bore around the head (seated proud)") ++
    Bool.pick(String, seat, " seat-gap=0", Bool.pick(String, F64.is_lt(0.0f64, cut), " seat-gap=-" ++ KSD.n_s(cut) ++ " (the head cuts into the seat)",
      Bool.pick(String, F64.is_lt(F64.neg(1.0e299f64), below), " seat-gap=" ++ KSD.n_s(F64.sub(l, below)) ++ " (the head is clear of its seat, not tightened)", " seat=missing"))) ++
    hit_s(hit, 36n) ++ " status=" ++ st_s(st) ++ "\n"}

def sh_ck(+rmin: F64, +rc: F64, +lo: F64, +hi: F64, +hit: Nat, +m: Nat) -> Ck:
  +room = F64.sub(rmin, rc)
  +st = Bool.pick(Nat, Bool.or(F64.is_lt(room, F64.neg(1.0e-9f64)), Nat.is_lt(0n, hit)), 2n, 0n)
  Ck{st, "fasten shank d=" ++ KSD.n_s(F64.mul(2.0f64, rc)) ++ " clamp=[" ++ KSD.n_s(lo) ++ ", " ++ KSD.n_s(hi) ++ "]" ++
    Bool.pick(String, F64.is_lt(rmin, 1.0e299f64), " through d=" ++ KSD.n_s(F64.mul(2.0f64, rmin)) ++ " radial-clearance=" ++ KSD.n_s(room), " no bore along the clamp length") ++
    hit_s(hit, m) ++ " status=" ++ st_s(st) ++ "\n"}

def ck_add(+c: Ck, +acc: Ck) -> Ck:
  Ck{+st, +s} = c
  Ck{+ast, +ss} = acc
  Ck{Bool.pick(Nat, Nat.is_lt(ast, st), st, ast), ss ++ s}

def cnt_go(cs: List<&2, Ck>, +k: Nat, +acc: Nat) -> Nat:
  match cs:
    case []: acc
    case +c <> t: cnt_go(t, k, Bool.pick(Nat, Nat.is_eq(ck_st(c), k), Nat.add(acc, 1n), acc))

def ids_s(ns: List<&2, U64>) -> String:
  match ns:
    case []: ""
    case +n <> t: " " ++ U64.show(n) ++ ids_s(t)

def lst_hd(cs: List<&2, Ck>, +i: Nat) -> Ck:
  match cs:
    case []: Ck{0n, ""}
    case +c <> t:
      match i:
        case 0n: c
        case 1n+j: lst_hd(t, j)

def fz_out(+cks: List<&2, Ck>, +head: String, +s: U64) -> String:
  head ++ ck_s(ck_add(lst_hd(cks, 0n), ck_add(lst_hd(cks, 1n), lst_hd(cks, 2n)))) ++
    "fasten node " ++ U64.show(s) ++ ": 3 checks, " ++ Nat.show(cnt_go(cks, 0n, 0n)) ++ " pass, " ++ Nat.show(cnt_go(cks, 2n, 0n)) ++ " fail, " ++ Nat.show(cnt_go(cks, 1n, 0n)) ++ " not-analyzed\n" ++
    "verdict " ++ Bool.pick(String, Nat.is_lt(0n, cnt_go(cks, 2n, 0n)), "fail", Bool.pick(String, Nat.is_lt(0n, cnt_go(cks, 1n, 0n)), "not-analyzed", "pass"))

def fz_it(ns: List<&2, U64>, +p: M.Part, +cs: List<&2, M.CE>, +o: V.Point, +d: V.Dir, +sz: String, +l: F64, +acc: It) -> It:
  match ns:
    case []: acc
    case +n <> t:
      M.Pt{ps, nds, ms, +ts} = p
      +b = M.nr_body(M.ce_r(M.ce_find(cs, n)))
      fz_it(t, p, cs, o, d, sz, l, ens_it(KSD.ents_of(p, n, cs), b, o, d, sz, l, ths_it(ts, n, b, o, d, sz, l, acc)))

def fz_go(+p: M.Part, +cs: List<&2, M.CE>, +s: U64, +ns: List<&2, U64>, +sz: String, +l: F64) -> String:
  M.Pt{ps, nds, +ms, ts} = p
  +f = SD.fa(sz)
  +dk = SD.fv(f, 6n)
  +k = SD.fv(f, 7n)
  +rc = M.sc_rc(SD.fv(f, 0n), SD.fv(f, 1n))
  +pl = M.bd_pl(M.nr_body(M.ce_r(M.ce_find(cs, s))))
  +o = M.pl_pt(V.Pt{0.0f64, 0.0f64, 0.0f64}, pl)
  +d = M.pl_dir(V.Dr{0.0f64, 0.0f64, 1.0f64}, pl)
  +th = fz_it(ns, p, cs, o, d, sz, l, it_none())
  +te = Bool.pick(F64, it_ok(th), F64.max(0.0f64, F64.min(it_hi(th), l)), 0.0f64)
  +tb = Bool.pick(F64, it_ok(th), F64.max(0.0f64, F64.min(it_lo(th), l)), 0.0f64)
  +sp = List.append(&2, V.Point, rings(o, d, F64.mul(0.98f64, rc), te, l), Bool.pick(List<&2, V.Point>, F64.is_lt(0.1f64, tb), rings(o, d, F64.mul(0.98f64, rc), 0.0f64, tb), []))
  +p2 = pl_go(pts_pl(ns, cs, []), o, d, l, F64.add(l, k), Pl2{False{}, 0.0f64, F64.neg(1.0e300f64)})
  fz_out([hd_ck(p2, pts_cy(ns, cs, o, d, F64.add(l, F64.max(pl2_cut(p2), 0.0f64)), F64.add(l, k), 1.0e300f64), dk, k, l,
        pts_in(ns, cs, rings(o, d, F64.mul(0.49f64, dk), l, F64.add(l, k)), 0n)),
      sh_ck(pts_cy(ns, cs, o, d, te, l, 1.0e300f64), rc, te, l, pts_in(ns, cs, sp, 0n), List.length(&2, V.Point, sp)),
      th_ck(th, ms, SD.fv(f, 0n), l, sz)],
    "fasten screw " ++ U64.show(s) ++ " ISO 4762 " ++ sz ++ "x" ++ KSD.n_s(l) ++ " tip=(" ++ KSD.n_s(V.pt_x(o)) ++ "," ++ KSD.n_s(V.pt_y(o)) ++ "," ++ KSD.n_s(V.pt_z(o)) ++ ")" ++
      " along=" ++ KSD.dir_s(d) ++ " parts" ++ ids_s(ns) ++ "\n", s)

def tl_u(xs: List<&2, U64>) -> List<&2, U64>:
  match xs:
    case []: []
    case +h <> t: t

def ids_of(xs: List<&2, String>) -> List<&2, U64>:
  match xs:
    case []: []
    case +x <> t: S.u64_of(S.Sx_a{x}) <> ids_of(t)

def fz_sw2(ok: Bool, +w: Sw, +p: M.Part, +cs: List<&2, M.CE>, +s: U64, +ns: List<&2, U64>) -> String:
  match ok:
    case True{}: fz_go(p, cs, s, ns, sw_sz(w), sw_l(w))
    case False{}:
      "error invalid-input | fasten @ node " ++ U64.show(s) ++ " | why: fasten-not-a-screw: node " ++ U64.show(s) ++ " is not a (screw ...) part or a move or rotation of one | fix: give a screw node first, then the parts it passes through"

def fz_sw(+w: Sw, +p: M.Part, +cs: List<&2, M.CE>, +s: U64, +ns: List<&2, U64>) -> String:
  fz_sw2(sw_ok(w), w, p, cs, s, ns)

def fasten_out(+p: M.Part, +args: List<&2, String>, +old: List<&2, M.CE>) -> String:
  M.Pt{+ps, +ns, ms, ts} = p
  +ids = ids_of(args)
  +s = S.u64_of(S.Sx_a{S.arg_at(args, 0n)})
  +rest = tl_u(ids)
  fz_sw(sw_go(Nat.add(List.length(&2, M.Node, ns), 1n), M.nd_op(ns, s), ns, X.env_of(M.pvs_of(ps))), p, M.ev_for(p, ids, old), s, rest)
