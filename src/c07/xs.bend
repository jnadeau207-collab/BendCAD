import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c06/iv.bend as I
import ../base/ex.bend as E
import ./ivx.bend as X
import ./rb.bend as R
import ./im.bend as M
import ./poly.bend as P
import ./eng.bend as N

type Hit is Data:
  H_pt{ s: I.I, t: I.I, p: List<&2, I.I>, cls: U64 }
  H_ov{ s: I.I, t: I.I }
  H_un{ s: I.I, t: I.I, p: List<&2, I.I> }
  H_no{ why: String }

type Pn is Data:
  Pn{ o: V.Point, n: List<&2, E.Ex>, ok: Bool }

def dom_i(d: G.Dom) -> I.I:
  G.Dom{lo, hi} = d
  I.I{lo, hi}

def dlo(d: G.Dom) -> F64:
  G.Dom{lo, hi} = d
  lo

def dhi(d: G.Dom) -> F64:
  G.Dom{lo, hi} = d
  hi

def gv_cv(g: G.GVal, +d: G.Dom) -> Maybe<&2, R.Cv>:
  match g:
    case G.GV_ln{l}:
      G.Ln{p, v} = l
      Some{R.cv_line(p, v, dlo(d), dhi(d))}
    case G.GV_cc{c}:
      G.Cc{o, u, v, r} = c
      Some{R.cv_circle(o, u, v, r, dlo(d), dhi(d))}
    case G.GV_bz{b}:
      G.Bz{p0, p1, p2, p3} = b
      Some{R.cv_bez([p0, p1, p2, p3], dlo(d), dhi(d))}
    case G.GV_rq{q}:
      G.Rq{p0, p1, p2, w0, w1, w2} = q
      Some{R.cv_rat([p0, p1, p2], [w0, w1, w2], dlo(d), dhi(d))}
    case _: None{}

def gv_xc(g: G.GVal) -> Maybe<&2, P.Xc>:
  match g:
    case G.GV_ln{l}:
      G.Ln{p, v} = l
      Some{P.xc_line(p, v)}
    case G.GV_cc{c}:
      G.Cc{o, u, v, r} = c
      Some{P.xc_circle(o, u, v, r)}
    case G.GV_bz{b}:
      G.Bz{p0, p1, p2, p3} = b
      Some{P.xc_bez(p0, p1, p2, p3)}
    case G.GV_rq{q}:
      G.Rq{p0, p1, p2, w0, w1, w2} = q
      Some{P.xc_rq(p0, p1, p2, w0, w1, w2)}
    case _: None{}

def gv_im(g: G.GVal) -> Maybe<&2, M.Im>:
  match g:
    case G.GV_pl{w}:
      G.Pl{o, u, v} = w
      Some{M.im_plane(o, u, v)}
    case G.GV_sp{w}:
      G.Sp{c, r} = w
      Some{M.im_sphere(c, r)}
    case G.GV_cy{w}:
      G.Cy{o, a, r} = w
      Some{M.im_cyl(o, a, r)}
    case G.GV_co{w}:
      G.Co{o, a, k} = w
      Some{M.im_cone(o, a, k)}
    case G.GV_to{w}:
      G.To{o, a, bigr, r} = w
      Some{M.im_torus(o, a, bigr, r)}
    case _: None{}

def gv_xs(g: G.GVal) -> Maybe<&2, P.Xs>:
  match g:
    case G.GV_pl{w}:
      G.Pl{o, u, v} = w
      Some{P.xs_plane(o, u, v)}
    case G.GV_sp{w}:
      G.Sp{c, +r} = w
      Some{P.X_sp{c, E.ex_mul(E.ex_of(r), E.ex_of(r))}}
    case G.GV_cy{w}:
      G.Cy{o, a, r} = w
      Some{P.X_cy{o, a, r}}
    case G.GV_co{w}:
      G.Co{o, a, k} = w
      Some{P.X_co{o, a, k}}
    case G.GV_to{w}:
      G.To{o, a, bigr, r} = w
      Some{P.X_to{o, a, bigr, r}}
    case _: None{}

def is_closed(g: G.GVal, +d: G.Dom) -> Bool:
  match g:
    case G.GV_cc{c}: Bool.and(F64.is_eq(dlo(d), F64.neg(1.0f64)), F64.is_eq(dhi(d), 1.0f64))
    case _: False{}

def merge1(rs: List<&2, I.I>, +cur: I.I, +open: Bool) -> List<&2, I.I>:
  match rs:
    case []: Bool.pick(List<&2, I.I>, open, [cur], [])
    case +r <> +t:
      Bool.pick(List<&2, I.I>, Bool.and(open, F64.is_le(I.i_lo(r), I.i_hi(cur))),
        merge1(t, I.ihull(cur, r), True{}),
        List.append(&2, I.I, Bool.pick(List<&2, I.I>, open, [cur], []), merge1(t, r, True{})))

def un1(rs: List<&2, N.Res>) -> List<&2, I.I>:
  match rs:
    case []: []
    case r <> +t:
      match r:
        case N.R_un{x}: X.vn(x, 0n) <> un1(t)
        case _: un1(t)

def pts_of(rs: List<&2, N.Res>) -> List<&2, List<&2, I.I>>:
  match rs:
    case []: []
    case r <> +t:
      match r:
        case N.R_pt{x}: x <> pts_of(t)
        case _: pts_of(t)

def dup_in(ks: List<&2, List<&2, I.I>>, +b: List<&2, I.I>) -> U64:
  match ks:
    case []: 0u64
    case +k <> t: Bool.pick(U64, X.vsub_of(k, b), 1u64, Bool.pick(U64, X.vdisj(k, b), dup_in(t, b), 2u64))

def rescue(+p: N.Pb, +u: List<&2, I.I>) -> List<&2, I.I>:
  N.refine(12n, p, X.vinfl(u, 1.0f64))

def rescued(+p: N.Pb, +u: List<&2, I.I>) -> Bool:
  +b = X.vinfl(u, 1.0f64)
  X.vin(N.kraw(p, b, N.pb_j(p, b), N.pb_n(p)), b)

def dom01() -> I.I:
  I.I{0.0f64, 1.0f64}

def side_ok(s: M.Im, +p: List<&2, I.I>) -> U64:
  +v = M.im_side(s, p)
  Bool.pick(U64, F64.is_le(0.0f64, I.i_lo(v)), 0u64, Bool.pick(U64, F64.is_lt(I.i_hi(v), 0.0f64), 1u64, 2u64))

def mk_ci(+c: R.Cv, +s: M.Im) -> N.Pb:
  N.P_ci{c, s}

def seam_go(hs: List<&2, Hit>, +first: Bool) -> List<&2, Hit>:
  match hs:
    case []: []
    case +h <> +t:
      match h:
        case H_pt{+s, +tt, +p, +cls}:
          Bool.pick(List<&2, Hit>, U64.is_eq(cls, 2u64), seam_go(t, first),
            Bool.pick(List<&2, Hit>, U64.is_eq(cls, 1u64), H_pt{s, tt, p, 16u64} <> seam_go(t, first), H_pt{s, tt, p, cls} <> seam_go(t, first)))
        case _: h <> seam_go(t, first)

def has_cls(hs: List<&2, Hit>, +c: U64) -> Bool:
  match hs:
    case []: False{}
    case h <> +t:
      match h:
        case H_pt{s, tt, p, cls}: Bool.or(U64.is_eq(cls, c), has_cls(t, c))
        case _: has_cls(t, c)

def seam(+hs: List<&2, Hit>, closed: Bool) -> List<&2, Hit>:
  Bool.pick(List<&2, Hit>, Bool.and(closed, Bool.and(has_cls(hs, 1u64), has_cls(hs, 2u64))), seam_go(hs, True{}), hs)

def exl(es: List<&2, E.Ex>) -> List<&2, I.I>:
  match es:
    case []: []
    case e <> t: I.of_ex(e) <> exl(t)

def bern(+es: List<&2, E.Ex>, +lo: F64, +hi: F64) -> List<&2, I.I>:
  R.p2b(R.tshift(exl(es), lo, hi))

def mk_h(+h: List<&2, I.I>, +e: List<&2, E.Ex>, +a: F64, +b: F64) -> N.Pb:
  N.P_h{h, e, a, b}

def on_go(m: Maybe<&2, P.Xc>, n: Maybe<&2, P.Xs>) -> Bool:
  match m:
    case None{}: False{}
    case Some{xc}:
      match n:
        case None{}: False{}
        case Some{xs}: P.on_surf(xc, xs)

def on_iv(+c: R.Cv, +s: M.Im, +lo: F64, +hi: F64) -> List<&2, Hit>:
  +p = R.cv_box(c, dom01())
  +sd = side_ok(s, p)
  Bool.pick(List<&2, Hit>, U64.is_eq(sd, 0u64), [H_ov{I.I{lo, hi}, X.iz()}],
    Bool.pick(List<&2, Hit>, U64.is_eq(sd, 1u64), [], [H_un{I.I{lo, hi}, X.iz(), p}]))

def ez(+e: E.Ex) -> Bool:
  P.is_z(E.ex_sign(e))

def sgn3(+e: E.Ex) -> U64:
  +g = E.ex_est(e)
  Bool.pick(U64, ez(e), 0u64, Bool.pick(U64, F64.is_lt(0.0f64, g), 1u64, 2u64))

def lin_pick(k: U64, +c: R.Cv, +ts: I.I, +lo: F64, +hi: F64) -> List<&2, Hit>:
  match k:
    case 0u64: [H_un{I.I{lo, hi}, X.iz(), R.cv_box(c, dom01())}]
    case 1u64: [H_ov{I.I{lo, hi}, X.iz()}]
    case 2u64: [H_pt{I.ipt(lo), X.iz(), R.cv_box(c, I.ipt(0.0f64)), 1u64}]
    case 3u64: [H_ov{I.I{lo, hi}, X.iz()}]
    case 4u64: [H_ov{I.I{lo, hi}, X.iz()}]
    case 5u64: [H_ov{I.I{lo, I.i_hi(ts)}, X.iz()}]
    case 6u64: [H_pt{I.ipt(hi), X.iz(), R.cv_box(c, I.ipt(1.0f64)), 2u64}]
    case 7u64: [H_ov{I.I{I.i_lo(ts), hi}, X.iz()}]
    case _: []

def lin_side(+c: R.Cv, +sp: List<&2, E.Ex>, +lo: F64, +hi: F64) -> List<&2, Hit>:
  +c0 = P.nth_e(sp, 0n)
  +c1 = P.nth_e(sp, 1n)
  +s0 = sgn3(E.ex_add(c0, E.ex_scale(c1, lo)))
  +s1 = sgn3(E.ex_add(c0, E.ex_scale(c1, hi)))
  +ts = I.ineg(I.idiv(I.of_ex(c0), I.of_ex(c1)))
  +k = U64.add(U64.mul(s0, 3u64), s1)
  lin_pick(k, c, ts, lo, hi)

def on_sel(k: U64, +c: R.Cv, +s: M.Im, +sp: List<&2, E.Ex>, +lo: F64, +hi: F64) -> List<&2, Hit>:
  match k:
    case 0u64: [H_ov{I.I{lo, hi}, X.iz()}]
    case 1u64: lin_side(c, sp, lo, hi)
    case _: on_iv(c, s, lo, hi)

def on_res(+c: R.Cv, +s: M.Im, +sp: List<&2, E.Ex>, +lo: F64, +hi: F64) -> List<&2, Hit>:
  +lin = Bool.and(P.pzero_all(P.pdrop2(sp)), Bool.not(Nat.is_eq(List.length(&2, E.Ex, sp), 0n)))
  on_sel(Bool.pick(U64, Nat.is_eq(List.length(&2, E.Ex, sp), 0n), 0u64, Bool.pick(U64, lin, 1u64, 2u64)), c, s, sp, lo, hi)

def ci_hit(+c: R.Cv, +s: M.Im, +k: List<&2, I.I>, +cls: U64, +lo: F64, +hi: F64) -> List<&2, Hit>:
  +tk = X.vn(k, 0n)
  +p = R.cv_box(c, N.tau(lo, hi, tk))
  +sd = side_ok(s, p)
  Bool.pick(List<&2, Hit>, U64.is_eq(sd, 1u64), [], Bool.pick(List<&2, Hit>, U64.is_eq(sd, 0u64), [H_pt{tk, X.iz(), p, cls}], [H_un{tk, X.iz(), p}]))

def ci_pts(ks: List<&2, List<&2, I.I>>, +c: R.Cv, +s: M.Im, +lo: F64, +hi: F64) -> List<&2, Hit>:
  match ks:
    case []: []
    case +k <> t: List.append(&2, Hit, ci_hit(c, s, k, 0u64, lo, hi), ci_pts(t, c, s, lo, hi))

def cls_of(+k: I.I, +bit: U64, +lo: F64, +hi: F64) -> U64:
  U64.add(Bool.pick(U64, F64.is_le(I.i_lo(k), lo), bit, 0u64), Bool.pick(U64, F64.is_le(hi, I.i_hi(k)), U64.mul(bit, 2u64), 0u64))

def ci_un(us: List<&2, I.I>, +c: R.Cv, +s: M.Im, +ks: List<&2, List<&2, I.I>>, +p: N.Pb, +lo: F64, +hi: F64) -> List<&2, Hit>:
  match us:
    case []: []
    case +u <> t:
      +ok = rescued(p, [u])
      +k = rescue(p, [u])
      +kt = X.vn(k, 0n)
      +out = Bool.or(F64.is_lt(I.i_hi(kt), lo), F64.is_lt(hi, I.i_lo(kt)))
      +dup = dup_in(ks, X.vinfl([u], 1.0f64))
      List.append(&2, Hit,
        Bool.pick(List<&2, Hit>, Bool.and(ok, U64.is_eq(dup, 1u64)), [],
          Bool.pick(List<&2, Hit>, Bool.and(ok, out), [],
            Bool.pick(List<&2, Hit>, Bool.and(ok, U64.is_eq(dup, 0u64)), ci_hit(c, s, k, cls_of(kt, 1u64, lo, hi), lo, hi),
              [H_un{u, X.iz(), R.cv_box(c, N.tau(lo, hi, u))}]))),
        ci_un(t, c, s, ks, p, lo, hi))

def ci_run(+c: R.Cv, +s: M.Im, +h: List<&2, I.I>, +e: List<&2, E.Ex>, +lo: F64, +hi: F64, +d: Nat) -> List<&2, Hit>:
  +p = mk_h(h, e, lo, hi)
  +rs = N.solve(d, p, [I.I{lo, hi}])
  +ks = pts_of(rs)
  List.append(&2, Hit, ci_pts(ks, c, s, lo, hi), ci_un(merge1(un1(rs), dom01(), False{}), c, s, ks, p, lo, hi))

def ci_pick(on: Bool, +c: R.Cv, +s: M.Im, +es: List<&2, E.Ex>, +sp: List<&2, E.Ex>, +lo: F64, +hi: F64, +d: Nat, +closed: Bool) -> List<&2, Hit>:
  match on:
    case True{}: on_res(c, s, sp, lo, hi)
    case False{}: seam(ci_run(c, s, bern(es, lo, hi), es, lo, hi, d), closed)

def ci_main(mc: Maybe<&2, R.Cv>, ms: Maybe<&2, M.Im>, +es: List<&2, E.Ex>, +sp: List<&2, E.Ex>, +d: Nat, +lo: F64, +hi: F64, +closed: Bool) -> List<&2, Hit>:
  match mc:
    case None{}: [H_no{"curve-kind-not-supported"}]
    case Some{+c}:
      match ms:
        case None{}: [H_no{"surface-kind-not-supported"}]
        case Some{+s}:
          ci_pick(P.pzero_all(es), c, s, es, sp, lo, hi, d, closed)

def comp_go(m: Maybe<&2, P.Xc>, n: Maybe<&2, P.Xs>) -> List<&2, E.Ex>:
  match m:
    case None{}: [E.ex_of(1.0f64)]
    case Some{xc}:
      match n:
        case None{}: [E.ex_of(1.0f64)]
        case Some{xs}: P.comp(xc, xs)

def side_go(m: Maybe<&2, P.Xc>, n: Maybe<&2, P.Xs>) -> List<&2, E.Ex>:
  match m:
    case None{}: []
    case Some{xc}:
      match n:
        case None{}: []
        case Some{xs}: P.side(xc, xs)

def inter_cs(+g: G.GVal, +d: G.Dom, +s: G.GVal, +depth: Nat) -> List<&2, Hit>:
  ci_main(gv_cv(g, d), gv_im(s), comp_go(gv_xc(g), gv_xs(s)), side_go(gv_xc(g), gv_xs(s)), depth, dlo(d), dhi(d), is_closed(g, d))

def inv_t_h(+h: I.I) -> I.I:
  I.idiv(h, I.iadd(I.ipt(1.0f64), I.isqrt(I.iadd(I.ipt(1.0f64), I.isq(h)))))

def inv_t_g(+g: I.I) -> I.I:
  +s = I.isqrt(I.iadd(I.isq(g), I.ipt(1.0f64)))
  Bool.pick(I.I, F64.is_lt(0.0f64, I.i_lo(g)), I.idiv(I.ipt(1.0f64), I.iadd(g, s)),
    Bool.pick(I.I, F64.is_lt(I.i_hi(g), 0.0f64), I.idiv(I.ipt(1.0f64), I.isub(g, s)), I.I{F64.neg(1.0f64), 1.0f64}))

def inv_circ(+cs: I.I, +sn: I.I) -> I.I:
  Bool.pick(I.I, F64.is_lt(F64.neg(0.5f64), I.i_lo(cs)), inv_t_h(I.idiv(sn, I.iadd(I.ipt(1.0f64), cs))),
    inv_t_g(I.idiv(I.iadd(I.ipt(1.0f64), cs), sn)))

def circ_par(+p: List<&2, I.I>, c: V.Point, u: V.Dir, v: V.Dir, +r: F64) -> I.I:
  +m = X.vsub(p, M.p3(c))
  +uu = M.d3(u)
  +vv = M.d3(v)
  +den = I.imul(I.ipt(r), X.vdot(uu, uu))
  inv_circ(I.idiv(X.vdot(m, uu), den), I.idiv(X.vdot(m, vv), den))

def esub3(+a: V.Point, +b: V.Point) -> List<&2, E.Ex>:
  [E.ex_dif(P.ptx(a), P.ptx(b)), E.ex_dif(P.pty(a), P.pty(b)), E.ex_dif(P.ptz(a), P.ptz(b))]

def ecr(+a: List<&2, E.Ex>, +b: List<&2, E.Ex>) -> List<&2, E.Ex>:
  [E.ex_sub(E.ex_mul(P.nth_e(a, 1n), P.nth_e(b, 2n)), E.ex_mul(P.nth_e(a, 2n), P.nth_e(b, 1n))),
    E.ex_sub(E.ex_mul(P.nth_e(a, 2n), P.nth_e(b, 0n)), E.ex_mul(P.nth_e(a, 0n), P.nth_e(b, 2n))),
    E.ex_sub(E.ex_mul(P.nth_e(a, 0n), P.nth_e(b, 1n)), E.ex_mul(P.nth_e(a, 1n), P.nth_e(b, 0n)))]

def edir(+d: V.Dir) -> List<&2, E.Ex>:
  [E.ex_of(P.drx(d)), E.ex_of(P.dry(d)), E.ex_of(P.drz(d))]

def nz3(+n: List<&2, E.Ex>) -> Bool:
  Bool.not(P.pzero_all(n))

def pn_none() -> Pn:
  Pn{V.Pt{0.0f64, 0.0f64, 0.0f64}, [], False{}}

def pn_pick(+a: Pn, +b: Pn) -> Pn:
  Pn{o, n, ok} = a
  Bool.pick(Pn, ok, a, b)

def pn3(+p0: V.Point, +p1: V.Point, +p2: V.Point) -> Pn:
  +n = ecr(esub3(p1, p0), esub3(p2, p0))
  Bool.pick(Pn, nz3(n), Pn{p0, n, True{}}, pn_none())

def plane_of(g: G.GVal) -> Pn:
  match g:
    case G.GV_cc{c}:
      G.Cc{o, u, v, r} = c
      Pn{o, ecr(edir(u), edir(v)), True{}}
    case G.GV_bz{b}:
      G.Bz{+p0, +p1, +p2, +p3} = b
      pn_pick(pn3(p0, p1, p2), pn_pick(pn3(p0, p1, p3), pn3(p0, p2, p3)))
    case G.GV_rq{q}:
      G.Rq{p0, p1, p2, w0, w1, w2} = q
      pn3(p0, p1, p2)
    case _: pn_none()

def ln_pd(g: G.GVal) -> Pn:
  match g:
    case G.GV_ln{l}:
      G.Ln{p, d} = l
      Pn{p, edir(d), True{}}
    case _: pn_none()

def pn_ok(p: Pn) -> Bool:
  Pn{o, n, ok} = p
  ok

def pn_xs(p: Pn) -> P.Xs:
  Pn{o, n, ok} = p
  P.X_pl{o, n}

def pn_n(p: Pn) -> List<&2, E.Ex>:
  Pn{o, n, ok} = p
  n

def pn_o(p: Pn) -> V.Point:
  Pn{o, n, ok} = p
  o

def line_line_plane(+a: Pn, +b: Pn) -> Pn:
  +n = ecr(pn_n(a), pn_n(b))
  Bool.pick(Pn, nz3(n), Pn{pn_o(a), n, True{}}, pn_none())

def cc_plane(+ga: G.GVal, +gb: G.GVal) -> Pn:
  +la = ln_pd(ga)
  +lb = ln_pd(gb)
  Bool.pick(Pn, Bool.and(pn_ok(la), pn_ok(lb)), line_line_plane(la, lb), pn_pick(plane_of(ga), plane_of(gb)))

def both_on(+pn: Pn, +xa: Maybe<&2, P.Xc>, +xb: Maybe<&2, P.Xc>) -> Bool:
  Bool.and(pn_ok(pn), Bool.and(on_go(xa, Some{pn_xs(pn)}), on_go(xb, Some{pn_xs(pn)})))

def eabs(+e: E.Ex) -> F64:
  F64.abs(E.ex_est(e))

def drop_k(+n: List<&2, E.Ex>) -> Nat:
  +a = eabs(P.nth_e(n, 0n))
  +b = eabs(P.nth_e(n, 1n))
  +c = eabs(P.nth_e(n, 2n))
  Bool.pick(Nat, Bool.and(F64.is_le(b, a), F64.is_le(c, a)), 0n, Bool.pick(Nat, F64.is_le(c, b), 1n, 2n))

def cc_res(rs: List<&2, N.Res>, +a: R.Cv, +b: R.Cv) -> List<&2, Hit>:
  match rs:
    case []: []
    case r <> +t:
      match r:
        case N.R_pt{+x}:
          +ks = X.vn(x, 0n)
          +kt = X.vn(x, 1n)
          H_pt{R.cv_par(a, ks), R.cv_par(b, kt), R.cv_box(a, ks), U64.add(cls_of(ks, 1u64, 0.0f64, 1.0f64), cls_of(kt, 4u64, 0.0f64, 1.0f64))} <> cc_res(t, a, b)
        case N.R_un{+x}: H_un{R.cv_par(a, X.vn(x, 0n)), R.cv_par(b, X.vn(x, 1n)), R.cv_box(a, X.vn(x, 0n))} <> cc_res(t, a, b)
        case N.R_pc{x, k}: cc_res(t, a, b)

def mk_cc(+a: R.Cv, +b: R.Cv, +i: Nat, +j: Nat) -> N.Pb:
  N.P_cc{a, b, i, j}

def mk_c3(+a: R.Cv, +b: R.Cv) -> N.Pb:
  N.P_c3{a, b}

def solve_r(+d: Nat, +p: N.Pb, +x: List<&2, I.I>) -> List<&2, N.Res>:
  N.solve_e(d, p, x)

def i_other(+k: Nat) -> List<&2, Nat>:
  Bool.pick(List<&2, Nat>, Nat.is_eq(k, 0n), [1n, 2n], Bool.pick(List<&2, Nat>, Nat.is_eq(k, 1n), [0n, 2n], [0n, 1n]))

def nn(xs: List<&2, Nat>, +i: Nat) -> Nat:
  match xs:
    case []: 0n
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: nn(t, j)

def cc_2d(+a: R.Cv, +b: R.Cv, +k: Nat, +d: Nat) -> List<&2, Hit>:
  +o = i_other(k)
  cc_res(solve_r(d, mk_cc(a, b, nn(o, 0n), nn(o, 1n)), [dom01(), dom01()]), a, b)

def cc_3d(+a: R.Cv, +b: R.Cv, +d: Nat) -> List<&2, Hit>:
  cc_res(N.solve(d, mk_c3(a, b), [dom01(), dom01()]), a, b)

def edot(+a: List<&2, E.Ex>, +b: List<&2, E.Ex>) -> E.Ex:
  E.ex_add(E.ex_add(E.ex_mul(P.nth_e(a, 0n), P.nth_e(b, 0n)), E.ex_mul(P.nth_e(a, 1n), P.nth_e(b, 1n))), E.ex_mul(P.nth_e(a, 2n), P.nth_e(b, 2n)))

def R_scale(+s: I.I, xs: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t: I.imul(s, x) <> R_scale(s, t)

def lpar(+p: V.Point, +d: V.Dir, +q: V.Point, +e: V.Dir, +t: F64) -> I.I:
  +dd = M.d3(d)
  +pt = X.vadd(M.p3(q), R_scale(I.ipt(t), M.d3(e)))
  I.idiv(X.vdot(X.vsub(pt, M.p3(p)), dd), X.vdot(dd, dd))

def ll_ov(+p: V.Point, +d: V.Dir, +da: G.Dom, +q: V.Point, +e: V.Dir, +db: G.Dom) -> List<&2, Hit>:
  +sr = I.ihull(lpar(p, d, q, e, dlo(db)), lpar(p, d, q, e, dhi(db)))
  +dom = dom_i(da)
  +ov = X.imeet(sr, dom)
  +tr = I.ihull(lpar(q, e, p, d, I.i_lo(ov)), lpar(q, e, p, d, I.i_hi(ov)))
  Bool.pick(List<&2, Hit>, X.idisj(sr, dom), [], [H_ov{ov, X.imeet(tr, dom_i(db))}])

def ll_pick(k: U64, +p: V.Point, +d: V.Dir, +da: G.Dom, +q: V.Point, +e: V.Dir, +db: G.Dom, +ca: R.Cv, +cb: R.Cv, +n: List<&2, E.Ex>, +depth: Nat) -> List<&2, Hit>:
  match k:
    case 1u64: ll_ov(p, d, da, q, e, db)
    case 2u64: cc_2d(ca, cb, drop_k(n), depth)
    case _: []

def ll_go(+p: V.Point, +d: V.Dir, +da: G.Dom, +q: V.Point, +e: V.Dir, +db: G.Dom, +ca: R.Cv, +cb: R.Cv, +depth: Nat) -> List<&2, Hit>:
  +n = ecr(edir(d), edir(e))
  +w = esub3(q, p)
  +par = P.pzero_all(n)
  +col = P.pzero_all(ecr(w, edir(d)))
  +cop = ez(edot(w, n))
  ll_pick(Bool.pick(U64, par, Bool.pick(U64, col, 1u64, 0u64), Bool.pick(U64, cop, 2u64, 0u64)), p, d, da, q, e, db, ca, cb, n, depth)

def true_circle(+u: V.Dir, +v: V.Dir) -> Bool:
  +eu = edir(u)
  +ev = edir(v)
  Bool.and(ez(edot(eu, ev)), ez(E.ex_sub(edot(eu, eu), edot(ev, ev))))

def cc_same(+c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64, +xb: Maybe<&2, P.Xc>) -> Bool:
  +rr = E.ex_mul(E.ex_mul(E.ex_of(r), E.ex_of(r)), edot(edir(u), edir(u)))
  Bool.and(true_circle(u, v), Bool.and(on_go(xb, Some{P.X_pl{c, ecr(edir(u), edir(v))}}), on_go(xb, Some{P.X_sp{c, rr}})))

def circ_ov(+ca: R.Cv, +cb: R.Cv, +c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64, +da: G.Dom, +db: G.Dom) -> List<&2, Hit>:
  +s0 = circ_par(R.cv_box(cb, I.ipt(0.0f64)), c, u, v, r)
  +s1 = circ_par(R.cv_box(cb, I.ipt(1.0f64)), c, u, v, r)
  +dom = dom_i(da)
  +inside = Bool.and(X.isub_of(s0, dom), Bool.and(X.isub_of(s1, dom), F64.is_lt(I.i_hi(s0), I.i_lo(s1))))
  Bool.pick(List<&2, Hit>, inside, [H_ov{I.ihull(s0, s1), dom_i(db)}], [H_ov{dom, dom_i(db)}])

def same_circ(ga: G.GVal, +xb: Maybe<&2, P.Xc>) -> Bool:
  match ga:
    case G.GV_cc{w}:
      G.Cc{c, u, v, r} = w
      cc_same(c, u, v, r, xb)
    case _: False{}

def circ_ov_g(ga: G.GVal, +ca: R.Cv, +cb: R.Cv, +da: G.Dom, +db: G.Dom) -> List<&2, Hit>:
  match ga:
    case G.GV_cc{w}:
      G.Cc{c, u, v, r} = w
      circ_ov(ca, cb, c, u, v, r, da, db)
    case _: []

def gen_pick(k: U64, +ga: G.GVal, +ca: R.Cv, +cb: R.Cv, +da: G.Dom, +db: G.Dom, +pn: Pn, +depth: Nat) -> List<&2, Hit>:
  match k:
    case 1u64: circ_ov_g(ga, ca, cb, da, db)
    case 2u64: cc_2d(ca, cb, drop_k(pn_n(pn)), depth)
    case _: cc_3d(ca, cb, depth)

def gen_cc(+ga: G.GVal, +gb: G.GVal, +ca: R.Cv, +cb: R.Cv, +da: G.Dom, +db: G.Dom, +depth: Nat) -> List<&2, Hit>:
  +xa = gv_xc(ga)
  +xb = gv_xc(gb)
  +pn = cc_plane(ga, gb)
  gen_pick(Bool.pick(U64, same_circ(ga, xb), 1u64, Bool.pick(U64, both_on(pn, xa, xb), 2u64, 3u64)), ga, ca, cb, da, db, pn, depth)

def lines_go(ga: G.GVal, gb: G.GVal, +da: G.Dom, +db: G.Dom, +ca: R.Cv, +cb: R.Cv, +depth: Nat) -> List<&2, Hit>:
  match ga:
    case G.GV_ln{la}:
      G.Ln{p, d} = la
      match gb:
        case G.GV_ln{lb}:
          G.Ln{q, e} = lb
          ll_go(p, d, da, q, e, db, ca, cb, depth)
        case _: []
    case _: []

def is_line(g: G.GVal) -> Bool:
  match g:
    case G.GV_ln{l}: True{}
    case _: False{}

def cc_pick(ll: Bool, +ga: G.GVal, +gb: G.GVal, +da: G.Dom, +db: G.Dom, +ca: R.Cv, +cb: R.Cv, +depth: Nat) -> List<&2, Hit>:
  match ll:
    case True{}: lines_go(ga, gb, da, db, ca, cb, depth)
    case False{}: gen_cc(ga, gb, ca, cb, da, db, depth)

def cc_main(+ga: G.GVal, +gb: G.GVal, +da: G.Dom, +db: G.Dom, ma: Maybe<&2, R.Cv>, mb: Maybe<&2, R.Cv>, +depth: Nat) -> List<&2, Hit>:
  match ma:
    case None{}: [H_no{"curve-kind-not-supported"}]
    case Some{+ca}:
      match mb:
        case None{}: [H_no{"curve-kind-not-supported"}]
        case Some{+cb}:
          cc_pick(Bool.and(is_line(ga), is_line(gb)), ga, gb, da, db, ca, cb, depth)

def inter_cc(+ga: G.GVal, +da: G.Dom, +gb: G.GVal, +db: G.Dom, +depth: Nat) -> List<&2, Hit>:
  cc_main(ga, gb, da, db, gv_cv(ga, da), gv_cv(gb, db), depth)

def mk_ii(+a: M.Im, +b: M.Im) -> N.Pb:
  N.P_ii{a, b}

def p_eq(+a: V.Point, +b: V.Point) -> Bool:
  Bool.and(F64.is_eq(P.ptx(a), P.ptx(b)), Bool.and(F64.is_eq(P.pty(a), P.pty(b)), F64.is_eq(P.ptz(a), P.ptz(b))))

def par_dirs(+a: V.Dir, +b: V.Dir) -> Bool:
  P.pzero_all(ecr(edir(a), edir(b)))

def on_axis(+o: V.Point, +a: V.Dir, +q: V.Point) -> Bool:
  P.pzero_all(ecr(esub3(q, o), edir(a)))

def same_dir(+a: V.Dir, +b: V.Dir) -> Bool:
  Bool.and(par_dirs(a, b), F64.is_lt(0.0f64, E.ex_est(edot(edir(a), edir(b)))))

def coincide(g1: G.GVal, +g2: G.GVal) -> Bool:
  match g1:
    case G.GV_pl{w1}:
      G.Pl{o1, u1, v1} = w1
      match g2:
        case G.GV_pl{w2}:
          G.Pl{+o2, u2, v2} = w2
          +n1 = ecr(edir(u1), edir(v1))
          Bool.and(P.pzero_all(ecr(n1, ecr(edir(u2), edir(v2)))), ez(edot(n1, esub3(o2, o1))))
        case _: False{}
    case G.GV_sp{w1}:
      G.Sp{c1, r1} = w1
      match g2:
        case G.GV_sp{w2}:
          G.Sp{c2, r2} = w2
          Bool.and(p_eq(c1, c2), F64.is_eq(r1, r2))
        case _: False{}
    case G.GV_cy{w1}:
      G.Cy{+o1, +a1, r1} = w1
      match g2:
        case G.GV_cy{w2}:
          G.Cy{o2, a2, r2} = w2
          Bool.and(par_dirs(a1, a2), Bool.and(on_axis(o1, a1, o2), F64.is_eq(r1, r2)))
        case _: False{}
    case G.GV_co{w1}:
      G.Co{o1, a1, k1} = w1
      match g2:
        case G.GV_co{w2}:
          G.Co{o2, a2, k2} = w2
          Bool.and(p_eq(o1, o2), Bool.and(same_dir(a1, a2), F64.is_eq(k1, k2)))
        case _: False{}
    case G.GV_to{w1}:
      G.To{o1, a1, b1, r1} = w1
      match g2:
        case G.GV_to{w2}:
          G.To{o2, a2, b2, r2} = w2
          Bool.and(p_eq(o1, o2), Bool.and(par_dirs(a1, a2), Bool.and(F64.is_eq(b1, b2), F64.is_eq(r1, r2))))
        case _: False{}
    case _: False{}
