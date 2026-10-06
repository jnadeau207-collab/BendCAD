import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c06/iv.bend as I
import ../base/ex.bend as E
import ./ivx.bend as X
import ./rb.bend as R
import ./im.bend as M
import ./bp.bend as Q
import ./nb.bend as NB
import ./poly.bend as P
import ./eng.bend as N
import ./xs.bend as S
import ./ss.bend as SS

type Hx is Data:
  Hx_c{ h: S.Hit }
  Hx_uv{ s: I.I, u: I.I, v: I.I, p: List<&2, I.I>, cls: U64 }
  Hx_un3{ s: I.I, u: I.I, v: I.I }

type Sr is Data:
  Sr{ ss: SS.Ss, kind: U64, coin: Bool }

def wrap(hs: List<&2, S.Hit>) -> List<&2, Hx>:
  match hs:
    case []: []
    case h <> t: Hx_c{h} <> wrap(t)

def ud(+k: F64) -> I.I:
  +d = F64.mul(5.960464477539063e-08f64, k)
  I.I{F64.neg(d), F64.add(1.0f64, d)}

def u01() -> I.I:
  I.I{0.0f64, 1.0f64}

def mk_cb(+c: R.Cv, +q: Q.Bq) -> N.Pb:
  N.P_cb{c, q}

def mk_ci(+c: R.Cv, +s: M.Im) -> N.Pb:
  N.P_ci{c, s}

def cb_res(rs: List<&2, N.Res>, +c: R.Cv, +q: Q.Bq) -> List<&2, Hx>:
  match rs:
    case []: []
    case r <> +t:
      match r:
        case N.R_pt{+x}:
          +tk = X.vn(x, 0n)
          Hx_uv{R.cv_par(c, tk), X.vn(x, 1n), X.vn(x, 2n), R.cv_box(c, tk), S.cls_of(tk, 1u64, 0.0f64, 1.0f64)} <> cb_res(t, c, q)
        case N.R_un{+x}: Hx_un3{R.cv_par(c, X.vn(x, 0n)), X.vn(x, 1n), X.vn(x, 2n)} <> cb_res(t, c, q)
        case _: cb_res(t, c, q)

def cb_one(+c: R.Cv, +q: Q.Bq, +d: Nat) -> List<&2, Hx>:
  cb_res(S.solve_r(d, mk_cb(c, q), [u01(), u01(), u01()]), c, q)

def ci_res(rs: List<&2, N.Res>, +c: R.Cv, +s: M.Im) -> List<&2, Hx>:
  match rs:
    case []: []
    case r <> +t:
      match r:
        case N.R_pt{+x}:
          +tk = X.vn(x, 0n)
          +p = R.cv_box(c, tk)
          +sd = S.side_ok(s, p)
          +rest = ci_res(t, c, s)
          Bool.pick(List<&2, Hx>, U64.is_eq(sd, 1u64), rest,
            Bool.pick(List<&2, Hx>, U64.is_eq(sd, 0u64), Hx_c{S.H_pt{R.cv_par(c, tk), X.iz(), p, S.cls_of(tk, 1u64, 0.0f64, 1.0f64)}} <> rest,
              Hx_c{S.H_un{R.cv_par(c, tk), X.iz(), p}} <> rest))
        case N.R_un{+x}: Hx_c{S.H_un{R.cv_par(c, X.vn(x, 0n)), X.iz(), R.cv_box(c, X.vn(x, 0n))}} <> ci_res(t, c, s)
        case _: ci_res(t, c, s)

def ci_one(+c: R.Cv, +s: M.Im, +d: Nat) -> List<&2, Hx>:
  ci_res(S.solve_r(d, mk_ci(c, s), [u01()]), c, s)

def spans_cb(cs: List<&2, R.Cv>, +q: Q.Bq, +d: Nat) -> List<&2, Hx>:
  match cs:
    case []: []
    case c <> t: List.append(&2, Hx, cb_one(c, q, d), spans_cb(t, q, d))

def spans_ci(cs: List<&2, R.Cv>, +s: M.Im, +d: Nat) -> List<&2, Hx>:
  match cs:
    case []: []
    case c <> t: List.append(&2, Hx, ci_one(c, s, d), spans_ci(t, s, d))

def hx_s(h: Hx) -> I.I:
  match h:
    case Hx_c{w}:
      match w:
        case S.H_pt{s, t, p, c}: s
        case S.H_un{s, t, p}: s
        case _: I.I{F64.nan(), F64.nan()}
    case Hx_uv{s, u, v, p, c}: s
    case Hx_un3{s, u, v}: s

def hx_pt(h: Hx) -> Bool:
  match h:
    case Hx_c{w}:
      match w:
        case S.H_pt{s, t, p, c}: True{}
        case _: False{}
    case Hx_uv{s, u, v, p, c}: True{}
    case _: False{}

def dup_of(hs: List<&2, Hx>, +s: I.I) -> Bool:
  match hs:
    case []: False{}
    case +h <> t: Bool.or(Bool.and(hx_pt(h), Bool.not(X.idisj(hx_s(h), s))), dup_of(t, s))

def dedupe(hs: List<&2, Hx>, +seen: List<&2, Hx>) -> List<&2, Hx>:
  match hs:
    case []: []
    case +h <> +t:
      +d = Bool.and(hx_pt(h), dup_of(seen, hx_s(h)))
      Bool.pick(List<&2, Hx>, d, dedupe(t, seen), h <> dedupe(t, h <> seen))

def mcv_list(m: Maybe<&2, R.Cv>) -> List<&2, R.Cv>:
  match m:
    case None{}: []
    case Some{c}: [c]

def m_im_go(m: Maybe<&2, M.Im>, +cs: List<&2, R.Cv>, +d: Nat) -> List<&2, Hx>:
  match m:
    case None{}: [Hx_c{S.H_no{"surface-kind-not-supported"}}]
    case Some{s}: spans_ci(cs, s, d)

def curve_spans(+g: G.GVal, +d: G.Dom) -> List<&2, R.Cv>:
  match g:
    case G.GV_nb{n}: NB.nb_spans(n)
    case _: mcv_list(S.gv_cv(g, d))

def is_nb(g: G.GVal) -> Bool:
  match g:
    case G.GV_nb{n}: True{}
    case _: False{}

def is_bp(g: G.GVal) -> Bool:
  match g:
    case G.GV_bp{b}: True{}
    case _: False{}

def bq_of_g(g: G.GVal) -> Q.Bq:
  match g:
    case G.GV_bp{b}: Q.bq_of(b)
    case _: Q.Bq{[], [], []}

def cs_route(k: U64, +g: G.GVal, +d: G.Dom, +s: G.GVal, +depth: Nat) -> List<&2, Hx>:
  match k:
    case 1u64: dedupe(spans_cb(curve_spans(g, d), bq_of_g(s), depth), [])
    case 2u64: dedupe(m_im_go(S.gv_im(s), curve_spans(g, d), depth), [])
    case _: wrap(S.inter_cs(g, d, s, depth))

def inter_cs(+g: G.GVal, +d: G.Dom, +s: G.GVal, +depth: Nat) -> List<&2, Hx>:
  cs_route(Bool.pick(U64, is_bp(s), 1u64, Bool.pick(U64, is_nb(g), 2u64, 0u64)), g, d, s, depth)

def nb_pts(g: G.GVal) -> List<&2, V.Point>:
  match g:
    case G.GV_nb{n}:
      G.Nb{ks, ps, ws} = n
      ps
    case _: []

def pn_scan(+p0: V.Point, +p1: V.Point, ps: List<&2, V.Point>) -> S.Pn:
  match ps:
    case []: S.pn_none()
    case p <> t: S.pn_pick(S.pn3(p0, p1, p), pn_scan(p0, p1, t))

def pn_pts(ps: List<&2, V.Point>) -> S.Pn:
  match ps:
    case []: S.pn_none()
    case a <> t:
      match t:
        case []: S.pn_none()
        case b <> u: pn_scan(a, b, u)

def pts_on(ps: List<&2, V.Point>, +pn: S.Pn) -> Bool:
  match ps:
    case []: True{}
    case p <> t: Bool.and(S.ez(S.edot(S.pn_n(pn), S.esub3(p, S.pn_o(pn)))), pts_on(t, pn))

def g_on(+g: G.GVal, +pn: S.Pn) -> Bool:
  Bool.pick(Bool, is_nb(g), pts_on(nb_pts(g), pn), S.on_go(S.gv_xc(g), Some{S.pn_xs(pn)}))

def g_plane(+g: G.GVal) -> S.Pn:
  Bool.pick(S.Pn, is_nb(g), pn_pts(nb_pts(g)), S.plane_of(g))

def cc_pair_go(cop: Bool, +ca: R.Cv, +cb: R.Cv, +k: Nat, +d: Nat) -> List<&2, S.Hit>:
  match cop:
    case True{}: S.cc_2d(ca, cb, k, d)
    case False{}: S.cc_3d(ca, cb, d)

def cc_pair(+ca: R.Cv, +cb: R.Cv, +cop: Bool, +k: Nat, +d: Nat) -> List<&2, S.Hit>:
  cc_pair_go(cop, ca, cb, k, d)

def cc_row(+ca: R.Cv, bs: List<&2, R.Cv>, +cop: Bool, +k: Nat, +d: Nat) -> List<&2, S.Hit>:
  match bs:
    case []: []
    case b <> t: List.append(&2, S.Hit, cc_pair(ca, b, cop, k, d), cc_row(ca, t, cop, k, d))

def cc_all(xs: List<&2, R.Cv>, +bs: List<&2, R.Cv>, +cop: Bool, +k: Nat, +d: Nat) -> List<&2, S.Hit>:
  match xs:
    case []: []
    case a <> t: List.append(&2, S.Hit, cc_row(a, bs, cop, k, d), cc_all(t, bs, cop, k, d))

def cc_nb(+ga: G.GVal, +da: G.Dom, +gb: G.GVal, +db: G.Dom, +d: Nat) -> List<&2, Hx>:
  +pn = S.pn_pick(g_plane(ga), g_plane(gb))
  +cop = Bool.and(S.pn_ok(pn), Bool.and(g_on(ga, pn), g_on(gb, pn)))
  dedupe(wrap(cc_all(curve_spans(ga, da), curve_spans(gb, db), cop, S.drop_k(S.pn_n(pn)), d)), [])

def cc_route(nb: Bool, +ga: G.GVal, +da: G.Dom, +gb: G.GVal, +db: G.Dom, +d: Nat) -> List<&2, Hx>:
  match nb:
    case True{}: cc_nb(ga, da, gb, db, d)
    case False{}: wrap(S.inter_cc(ga, da, gb, db, d))

def inter_cc(+ga: G.GVal, +da: G.Dom, +gb: G.GVal, +db: G.Dom, +d: Nat) -> List<&2, Hx>:
  cc_route(Bool.or(is_nb(ga), is_nb(gb)), ga, da, gb, db, d)

def bp_pts(g: G.GVal) -> List<&2, V.Point>:
  match g:
    case G.GV_bp{b}:
      G.Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23, p30, p31, p32, p33} = b
      [p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23, p30, p31, p32, p33]
    case _: []

def pts_eq(xs: List<&2, V.Point>, ys: List<&2, V.Point>) -> Bool:
  match xs:
    case []: True{}
    case x <> t:
      match ys:
        case []: False{}
        case y <> u: Bool.and(S.p_eq(x, y), pts_eq(t, u))

def bp_on_plane(+gb: G.GVal, +gp: G.GVal) -> Bool:
  match gp:
    case G.GV_pl{w}:
      G.Pl{o, u, v} = w
      pts_on(bp_pts(gb), S.Pn{o, S.ecr(S.edir(u), S.edir(v)), True{}})
    case _: False{}

def mk_bi(+q: Q.Bq, +s: M.Im) -> N.Pb:
  N.P_bi{q, s}

def mk_bb(+a: Q.Bq, +b: Q.Bq) -> N.Pb:
  N.P_bb{a, b}

def empty_ss() -> SS.Ss:
  SS.Ss{True{}, [], []}

def bi_go(+q: Q.Bq, m: Maybe<&2, M.Im>) -> SS.Ss:
  match m:
    case None{}: empty_ss()
    case Some{s}: SS.trace(mk_bi(q, s), 64n, [ud(1.0f64), ud(2.0f64)])

def ii_go(m1: Maybe<&2, M.Im>, m2: Maybe<&2, M.Im>, +bx: List<&2, I.I>) -> SS.Ss:
  match m1:
    case None{}: empty_ss()
    case Some{a}:
      match m2:
        case None{}: empty_ss()
        case Some{b}: SS.trace(S.mk_ii(a, b), 64n, bx)

def ss_route(k: U64, +g1: G.GVal, +g2: G.GVal, +bx: List<&2, I.I>) -> SS.Ss:
  match k:
    case 1u64: bi_go(bq_of_g(g1), S.gv_im(g2))
    case 2u64: bi_go(bq_of_g(g2), S.gv_im(g1))
    case 3u64: SS.trace(mk_bb(bq_of_g(g1), bq_of_g(g2)), 64n, [ud(1.0f64), ud(2.0f64), ud(3.0f64), ud(4.0f64)])
    case _: ii_go(S.gv_im(g1), S.gv_im(g2), bx)

def ss_kind(+g1: G.GVal, +g2: G.GVal) -> U64:
  Bool.pick(U64, is_bp(g1), Bool.pick(U64, is_bp(g2), 3u64, 1u64), Bool.pick(U64, is_bp(g2), 2u64, 0u64))

def coin_of(+k: U64, +g1: G.GVal, +g2: G.GVal) -> Bool:
  Bool.pick(Bool, U64.is_eq(k, 0u64), S.coincide(g1, g2),
    Bool.pick(Bool, U64.is_eq(k, 1u64), bp_on_plane(g1, g2),
      Bool.pick(Bool, U64.is_eq(k, 2u64), bp_on_plane(g2, g1), pts_eq(bp_pts(g1), bp_pts(g2)))))

def ss_sel(co: Bool, +k: U64, +g1: G.GVal, +g2: G.GVal, +bx: List<&2, I.I>) -> SS.Ss:
  match co:
    case True{}: empty_ss()
    case False{}: ss_route(k, g1, g2, bx)

def inter_ss(+g1: G.GVal, +g2: G.GVal, +bx: List<&2, I.I>) -> Sr:
  +k = ss_kind(g1, g2)
  +co = coin_of(k, g1, g2)
  Sr{ss_sel(co, k, g1, g2, bx), k, co}

def sample3(+k: U64, +g1: G.GVal, +g2: G.GVal, +x: List<&2, I.I>) -> List<&2, I.I>:
  Bool.pick(List<&2, I.I>, U64.is_eq(k, 0u64), x,
    Bool.pick(List<&2, I.I>, U64.is_eq(k, 2u64), Q.bq_box(bq_of_g(g2), X.vn(x, 0n), X.vn(x, 1n)), Q.bq_box(bq_of_g(g1), X.vn(x, 0n), X.vn(x, 1n))))
