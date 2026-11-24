import Base
import ../c01/types.bend as V
import ../base/par.bend as B
import ../c07/sol.bend as SO
import ../k1/sf.bend as S
import ../k1/ls.bend as L
import mesh.bend as K
import fem.bend as F
import warm.bend as W

type CL is Data:
  CL{ on: Bool, p: V.Point, d: V.Dir, r: F64, pl: Bool }

def org() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def perp(+c: CL, +x: V.Point) -> V.Dir:
  CL{on, +p, +d, r, pl} = c
  +v = S.psub(x, p)
  S.dadd(v, F64.neg(S.dot(v, d)), d)

def held(+c: CL, +x: V.Point) -> Bool:
  CL{+on, +p, +d, +r, +pl} = c
  +w = perp(c, x)
  Bool.and(on, Bool.pick(Bool, pl, F64.is_le(F64.abs(S.dot(S.psub(x, p), d)), r), F64.is_le(F64.sqrt(S.dot(w, w)), r)))

def cl_mask(ps: List<&2, V.Point>, +c: CL) -> List<&2, F64>:
  match ps:
    case []: []
    case +x <> +t:
      +m = Bool.pick(F64, held(c, x), 0.0f64, 1.0f64)
      m <> m <> m <> cl_mask(t, c)

def n_held(ps: List<&2, V.Point>, +c: CL, +n: Nat) -> Nat:
  match ps:
    case []: n
    case +x <> +t: n_held(t, c, Bool.pick(Nat, held(c, x), Nat.add(n, 1n), n))

def cl_on(+c: CL) -> Bool:
  CL{+on, p, d, r, pl} = c
  on

def xperp(ps: List<&2, V.Point>, +c: CL) -> List<&2, F64>:
  match ps:
    case []: []
    case +x <> +t:
      +w = perp(c, x)
      S.dx(w) <> S.dy(w) <> S.dz(w) <> xperp(t, c)

def rvec(n: Nat, +i: F64, +j: F64) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m): S.fsin(F64.add(F64.mul(0.7f64, F64.mul(j, i)), F64.mul(0.3f64, i))) <> rvec(m, i, F64.add(j, 1.0f64))

def starts(k: Nat, +n: Nat, +i: F64, +mask: List<&2, F64>) -> List<&2, List<&2, F64>>:
  match k:
    case 0n: []
    case 1n+(+m): F.hadam(mask, rvec(n, i, 1.0f64)) <> starts(m, n, F64.add(i, 1.0f64), mask)

def ext2(ps: List<&2, V.Point>, +p0: V.Point, +acc: F64) -> F64:
  match ps:
    case []: acc
    case +x <> +t:
      +v = S.psub(x, p0)
      ext2(t, p0, F64.max(acc, S.dot(v, v)))

def hd_p(ps: List<&2, V.Point>) -> V.Point:
  match ps:
    case []: org()
    case +x <> +t: x

def hzs(xs: List<&2, F64>, +sg: F64) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> +t: F64.div(F64.sqrt(F64.max(0.0f64, F64.sub(x, sg))), S.two_pi()) <> hzs(t, sg)

def last_f(xs: List<&2, F64>, +d: F64) -> F64:
  match xs:
    case []: d
    case +x <> +t: last_f(t, x)

def n_below(xs: List<&2, F64>, +t: F64, +n: Nat) -> Nat:
  match xs:
    case []: n
    case +x <> +r: n_below(r, t, Bool.pick(Nat, F64.is_le(x, t), Nat.add(n, 1n), n))

def drop_f(n: Nat, xs: List<&2, F64>) -> List<&2, F64>:
  match n:
    case 0n: xs
    case 1n+(+m):
      match xs:
        case []: []
        case +x <> +t: drop_f(m, t)

def take_f(n: Nat, xs: List<&2, F64>) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m):
      match xs:
        case []: []
        case +x <> +t: x <> take_f(m, t)

type WS is Data:
  WS{ on: Bool, ps: List<&2, V.Point>, x: List<&2, List<&2, F64>>, h: F64 }

type LV is Data:
  LV{ ok: Bool, nn: Nat, ne: Nat, nc: Nat, held: Nat, rig: Nat, it: Nat, hz: List<&2, F64>, w: WS, res: F64, orph: Nat }

def ws_none() -> WS:
  WS{False{}, [], [], 1.0f64}

def lv_w(+l: LV) -> WS:
  LV{ok, nn, ne, nc, nh, rig, it, hz, +w, res, orph} = l
  w

def x0_of(on: Bool, +ws: WS, +ps: List<&2, V.Point>, +kk: Nat, +n3: Nat, +mask: List<&2, F64>) -> List<&2, List<&2, F64>>:
  match on:
    case True{}:
      WS{o, +pc, +xc, +hc} = ws
      F.cmask(mask, W.prolong(pc, xc, ps, hc))
    case False{}: starts(kk, n3, 1.0f64, mask)

def ws_on(+ws: WS) -> Bool:
  WS{+on, ps, x, h} = ws
  on

def lv_si(+si: F.SI, +sg: F64, +k: Nat, +free: Bool, +ok: Bool, +nn: Nat, +ne: Nat, +nc: Nat, +nh: Nat, +ps: List<&2, V.Point>, +hl: F64, +orph: Nat) -> LV:
  F.SI{+x, +lam, +it, +res} = si
  +h = hzs(lam, sg)
  +nb = Bool.pick(Nat, free, n_below(h, F64.mul(1.0e-4f64, last_f(h, 0.0f64)), 0n), 0n)
  LV{Bool.and(ok, Nat.is_eq(orph, 0n)), nn, ne, nc, nh, Bool.pick(Nat, free, Nat.add(6n, nb), 0n), it, take_f(k, drop_f(nb, h)), WS{True{}, ps, x, hl}, res, orph}

def guard(+k: Nat) -> Nat:
  Nat.add(k, Nat.max(3n, Nat.div(k, 4n)))

def cl_d(+c: CL) -> V.Dir:
  CL{on, p, +d, r, pl} = c
  d

def sv_u(+sv: F.SV) -> List<&2, F64>:
  F.SV{+x, rz} = sv
  F.hd_l(x)

def pre_if(on: Bool, +fm: F.FM, +es: List<&2, F.EL>, +ps: List<&2, V.Point>, +mask: List<&2, F64>, +e: F64, +nu: F64, +c: CL, +w: F64) -> F.FM:
  match on:
    case True{}:
      +f = F.hadam(mask, F.scale(F64.mul(w, w), F.apply_op(fm, True{}, xperp(ps, c))))
      F.prestress(fm, es, sv_u(F.bsolve_tol(fm, mask, [f], 40000n, 1.0e-10f64)), e, nu, w, cl_d(c))
    case False{}: fm

def rb_node(+j: Nat, +d: V.Dir) -> List<&2, F64>:
  +x = S.dx(d)
  +y = S.dy(d)
  +z = S.dz(d)
  Bool.pick(List<&2, F64>, Nat.is_eq(j, 0n), [1.0f64, 0.0f64, 0.0f64], Bool.pick(List<&2, F64>, Nat.is_eq(j, 1n), [0.0f64, 1.0f64, 0.0f64],
    Bool.pick(List<&2, F64>, Nat.is_eq(j, 2n), [0.0f64, 0.0f64, 1.0f64], Bool.pick(List<&2, F64>, Nat.is_eq(j, 3n), [0.0f64, F64.neg(z), y],
      Bool.pick(List<&2, F64>, Nat.is_eq(j, 4n), [z, 0.0f64, F64.neg(x)], [F64.neg(y), x, 0.0f64])))))

def rb_col(ps: List<&2, V.Point>, +c0: V.Point, +j: Nat) -> List<&2, F64>:
  match ps:
    case []: []
    case +p <> +t: List.append(&2, F64, rb_node(j, S.psub(p, c0)), rb_col(t, c0, j))

def rigid(+ps: List<&2, V.Point>, +c0: V.Point) -> List<&2, List<&2, F64>>:
  [rb_col(ps, c0, 0n), rb_col(ps, c0, 1n), rb_col(ps, c0, 2n), rb_col(ps, c0, 3n), rb_col(ps, c0, 4n), rb_col(ps, c0, 5n)]

type UF is Data:
  UF{ p: B.Tb<&2, Nat>, r: Nat }

def uf_get(+p: B.Tb<&2, Nat>, +x: Nat) -> Nat:
  B.tb_get(Nat, p, U32.from_nat(x))

def uf_h(fuel: Nat, stop: Bool, +p: B.Tb<&2, Nat>, +x: Nat) -> UF:
  match fuel stop:
    case 0n _: UF{p, x}
    case 1n++j True{}: UF{p, x}
    case 1n++j False{}:
      +g = uf_get(p, uf_get(p, x))
      uf_h(j, Nat.is_eq(uf_get(p, g), g), B.tb_set(Nat, p, U32.from_nat(x), g), g)

def uf_find(+p: B.Tb<&2, Nat>, +n: Nat, +x: Nat) -> UF:
  uf_h(n, Nat.is_eq(uf_get(p, x), x), p, x)

def uf_link(+u: UF, +rb: Nat) -> B.Tb<&2, Nat>:
  UF{+p, +ra} = u
  Bool.pick(B.Tb<&2, Nat>, Nat.is_eq(ra, rb), p, B.tb_set(Nat, p, U32.from_nat(Nat.max(ra, rb)), Nat.min(ra, rb)))

def uf_u2(+u: UF, +a: Nat, +n: Nat) -> B.Tb<&2, Nat>:
  UF{+p, +rb} = u
  uf_link(uf_find(p, n, a), rb)

def uf_u(+p: B.Tb<&2, Nat>, +a: Nat, +b: Nat, +n: Nat) -> B.Tb<&2, Nat>:
  uf_u2(uf_find(p, n, b), a, n)

def uf_r(+u: UF) -> Nat:
  UF{p, +r} = u
  r

type TF is Data:
  TF{ a: Nat, b: Nat, c: Nat, t: Nat }

def tf_of(+x: Nat, +y: Nat, +z: Nat, +t: Nat) -> TF:
  +lo = Nat.min(Nat.min(x, y), z)
  +hi = Nat.max(Nat.max(x, y), z)
  TF{lo, Nat.sub(Nat.sub(Nat.add(Nat.add(x, y), z), lo), hi), hi, t}

def tf_cmp2(+x: TF, +y: TF) -> B.Sgn:
  TF{+a, +b, +c, t} = x
  TF{+d, +e, +f, u} = y
  K.lex(K.ncmp2(a, d), K.lex(K.ncmp2(b, e), K.ncmp2(c, f)))

def tf_cmp(x: TF, y: TF) -> B.Sgn:
  tf_cmp2(x, y)

def tf_t(+x: TF) -> Nat:
  TF{a, b, c, +t} = x
  t

def tf_eq(+x: TF, +y: TF) -> Bool:
  B.sgn_is(tf_cmp2(x, y), B.Sz{})

def tet_fs(+t: K.T10, +i: Nat, +acc: List<&2, TF>) -> List<&2, TF>:
  K.T10{+a, +b, +c, +d, e0, e1, e2, e3, e4, e5} = t
  tf_of(a, b, c, i) <> tf_of(a, b, d, i) <> tf_of(a, c, d, i) <> tf_of(b, c, d, i) <> acc

def tfs_go(ts: List<&2, K.T10>, +i: Nat, +acc: List<&2, TF>) -> List<&2, TF>:
  match ts:
    case []: acc
    case +t <> +r: tfs_go(r, Nat.add(i, 1n), tet_fs(t, i, acc))

def so_tf(s: B.So<&2, TF>) -> List<&2, TF>:
  B.So{ok, xs} = s
  xs

def adj_go(xs: List<&2, TF>, +pv: TF, +p: B.Tb<&2, Nat>, +n: Nat) -> B.Tb<&2, Nat>:
  match xs:
    case []: p
    case +x <> +r: adj_go(r, x, Bool.pick(B.Tb<&2, Nat>, tf_eq(x, pv), uf_u(p, tf_t(x), tf_t(pv), n), p), n)

def adj_uf(+xs: List<&2, TF>, +p: B.Tb<&2, Nat>, +n: Nat) -> B.Tb<&2, Nat>:
  match xs:
    case []: p
    case +x <> +r: adj_go(r, x, p, n)

def hb(+h: B.Tb<&2, Bool>, +i: Nat) -> Nat:
  Bool.pick(Nat, B.tb_get(Bool, h, U32.from_nat(i)), 1n, 0n)

def tet_hc(+t: K.T10, +h: B.Tb<&2, Bool>) -> Nat:
  K.T10{+a, +b, +c, +d, e0, e1, e2, e3, e4, e5} = t
  Nat.add(Nat.add(hb(h, a), hb(h, b)), Nat.add(hb(h, c), hb(h, d)))

def hn_go(ps: List<&2, V.Point>, +c: CL) -> List<&2, Bool>:
  match ps:
    case []: []
    case +x <> +t: held(c, x) <> hn_go(t, c)

def an_go(ts: List<&2, K.T10>, +i: Nat, +p: B.Tb<&2, Nat>, +ne: Nat, +h: B.Tb<&2, Bool>, +an: B.Tb<&2, Bool>) -> B.Tb<&2, Bool>:
  match ts:
    case []: an
    case +t <> +r:
      an_go(r, Nat.add(i, 1n), p, ne, h, Bool.pick(B.Tb<&2, Bool>, Nat.is_le(3n, tet_hc(t, h)), B.tb_set(Bool, an, U32.from_nat(uf_r(uf_find(p, ne, i))), True{}), an))

def nrange(n: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n: acc
    case 1n++j: nrange(j, j <> acc)

type LQ is Data:
  LQ{ r: Nat, cs: List<&2, Nat> }

def lt_cmp2(+x: LQ, +y: LQ) -> B.Sgn:
  LQ{+a, cs} = x
  LQ{+b, ds} = y
  K.ncmp2(a, b)

def lt_cmp(x: LQ, y: LQ) -> B.Sgn:
  lt_cmp2(x, y)

def so_lt(s: B.So<&2, LQ>) -> List<&2, LQ>:
  B.So{ok, xs} = s
  xs

def tet_cs(+t: K.T10) -> List<&2, Nat>:
  K.T10{+a, +b, +c, +d, e0, e1, e2, e3, e4, e5} = t
  [a, b, c, d]

def loose_go(ts: List<&2, K.T10>, +i: Nat, +p: B.Tb<&2, Nat>, +ne: Nat, +an: B.Tb<&2, Bool>, +acc: List<&2, LQ>) -> List<&2, LQ>:
  match ts:
    case []: acc
    case +t <> +r:
      +rt = uf_r(uf_find(p, ne, i))
      loose_go(r, Nat.add(i, 1n), p, ne, an, Bool.pick(List<&2, LQ>, B.tb_get(Bool, an, U32.from_nat(rt)), acc, LQ{rt, tet_cs(t)} <> acc))

type GP is Data:
  GP{ cs: List<&2, Nat>, n: Nat }

def gp_go(xs: List<&2, LQ>, +r: Nat, +cs: List<&2, Nat>, +n: Nat, +acc: List<&2, GP>) -> List<&2, GP>:
  match xs:
    case []: GP{cs, n} <> acc
    case +x <> +t:
      LQ{+r2, +c2} = x
      Bool.pick(List<&2, GP>, Nat.is_eq(r2, r), gp_go(t, r, List.append(&2, Nat, c2, cs), Nat.add(n, 1n), acc), gp_go(t, r2, c2, 1n, GP{cs, n} <> acc))

def groups(+xs: List<&2, LQ>) -> List<&2, GP>:
  match xs:
    case []: []
    case +x <> +t:
      LQ{+r, +cs} = x
      gp_go(t, r, cs, 1n, [])

def set_all(cs: List<&2, Nat>, +a: B.Tb<&2, Bool>) -> B.Tb<&2, Bool>:
  match cs:
    case []: a
    case +c <> +t: set_all(t, B.tb_set(Bool, a, U32.from_nat(c), True{}))

def na_go(ts: List<&2, K.T10>, +i: Nat, +p: B.Tb<&2, Nat>, +ne: Nat, +an: B.Tb<&2, Bool>, +a: B.Tb<&2, Bool>) -> B.Tb<&2, Bool>:
  match ts:
    case []: a
    case +t <> +r:
      na_go(r, Nat.add(i, 1n), p, ne, an, Bool.pick(B.Tb<&2, Bool>, B.tb_get(Bool, an, U32.from_nat(uf_r(uf_find(p, ne, i)))), set_all(tet_cs(t), a), a))

def a_pts(cs: List<&2, Nat>, +a: B.Tb<&2, Bool>, +pt: B.Tb<&2, V.Point>) -> List<&2, V.Point>:
  match cs:
    case []: []
    case +c <> +t:
      Bool.pick(List<&2, V.Point>, B.tb_get(Bool, a, U32.from_nat(c)), B.tb_get(V.Point, pt, U32.from_nat(c)) <> a_pts(t, a, pt), a_pts(t, a, pt))

def far_go(ps: List<&2, V.Point>, +p0: V.Point, +best: V.Point, +bd: F64) -> V.Point:
  match ps:
    case []: best
    case +q <> +t:
      +d = K.dlen(S.psub(q, p0))
      Bool.pick(V.Point, F64.is_lt(bd, d), far_go(t, p0, q, d), far_go(t, p0, best, bd))

def off_go(ps: List<&2, V.Point>, +p0: V.Point, +u: V.Dir, +tol: F64) -> Bool:
  match ps:
    case []: False{}
    case +q <> +t: Bool.or(F64.is_lt(tol, K.dlen(K.cross(u, S.psub(q, p0)))), off_go(t, p0, u, tol))

def ncol(+ps: List<&2, V.Point>) -> Bool:
  match ps:
    case []: False{}
    case +p0 <> +t:
      +p1 = far_go(t, p0, p0, 0.0f64)
      +u = S.psub(p1, p0)
      +l = K.dlen(u)
      Bool.and(F64.is_lt(0.0f64, l), off_go(t, p0, u, F64.mul(1.0e-6f64, F64.mul(l, l))))

type RD is Data:
  RD{ gs: List<&2, GP>, a: B.Tb<&2, Bool> }

def rd_go(gs: List<&2, GP>, +pt: B.Tb<&2, V.Point>, +acc: RD) -> RD:
  match gs:
    case []: acc
    case +g <> +t:
      GP{+cs, +n} = g
      RD{+left, +a} = acc
      Bool.pick(RD, ncol(a_pts(cs, a, pt)), rd_go(t, pt, RD{left, set_all(cs, a)}), rd_go(t, pt, RD{GP{cs, n} <> left, a}))

def rd_n(k: Nat, +r: RD, +pt: B.Tb<&2, V.Point>) -> RD:
  match k:
    case 0n: r
    case 1n+m:
      RD{+gs, +a} = r
      rd_n(m, rd_go(gs, pt, RD{[], a}), pt)

def gp_sum(gs: List<&2, GP>, +acc: Nat) -> Nat:
  match gs:
    case []: acc
    case +g <> +t:
      GP{cs, +n} = g
      gp_sum(t, Nat.add(acc, n))

def rd_left(+r: RD) -> Nat:
  RD{+gs, a} = r
  gp_sum(gs, 0n)

def n_orph(+ts: List<&2, K.T10>, +ps: List<&2, V.Point>, +n: Nat, +c: CL) -> Nat:
  +ne = List.length(&2, K.T10, ts)
  +p = adj_uf(so_tf(B.msort(~TF, ~tf_cmp, tfs_go(ts, 0n, []))), B.tb_of(Nat, nrange(ne, []), 0n), ne)
  +h = B.tb_of(Bool, hn_go(ps, c), False{})
  +an = an_go(ts, 0n, p, ne, h, B.tb_of(Bool, B.rep_n(Bool, ne, False{}), False{}))
  +gs = groups(so_lt(B.msort(~LQ, ~lt_cmp, loose_go(ts, 0n, p, ne, an, []))))
  rd_left(rd_n(8n, RD{gs, na_go(ts, 0n, p, ne, an, h)}, B.tb_of(V.Point, ps, org())))

def orph_of(free: Bool, +ts: List<&2, K.T10>, +ps: List<&2, V.Point>, +n: Nat, +c: CL) -> Nat:
  match free:
    case True{}: 0n
    case False{}: n_orph(ts, ps, n, c)

def lv_go(+tm: K.TM, +ok: Bool, +e: F64, +nu: F64, +rho: F64, +c: CL, +k: Nat, +w: F64, +ws: WS, +hl: F64) -> LV:
  K.TM{+ts, +ps, +nn, +nb, +nf, +dv, nl} = tm
  +es = K.fe_els(ts, B.tb_of(V.Point, ps, org()), 1.0e-12f64)
  +free = Bool.not(cl_on(c))
  +sg = Bool.pick(F64, free, F64.div(F64.mul(0.1f64, F64.div(e, rho)), F64.max(ext2(ps, hd_p(ps), 0.0f64), 1.0e-300f64)), 0.0f64)
  +kw = k
  +kk = guard(kw)
  +mask = cl_mask(ps, c)
  +n3 = Nat.mul(nn, 3n)
  +fm = F.fm_sig(pre_if(F64.is_lt(0.0f64, w), F.fm_of(U32.from_nat(nn), es, e, nu, rho), es, ps, mask, e, nu, c, w), sg)
  +orph = orph_of(free, ts, ps, nn, c)
  lv_si(F.lobpcg(100n, fm, mask, kk, kw, 1.0e-6f64, x0_of(ws_on(ws), ws, ps, kk, n3, mask), Bool.pick(List<&2, List<&2, F64>>, free, rigid(ps, hd_p(ps)), [])), sg, k, free, ok, nn, List.length(&2, K.T10, ts), K.n_ec(es, 0n),
    n_held(ps, c, 0n), ps, hl, orph)

def lv_ok_go(+tm: K.TM, ok: Bool, +e: F64, +nu: F64, +rho: F64, +c: CL, +k: Nat, +w: F64, +ws: WS, +hl: F64) -> LV:
  match ok:
    case True{}: lv_go(tm, True{}, e, nu, rho, c, k, w, ws, hl)
    case False{}: LV{False{}, 0n, 0n, 0n, 0n, 0n, 0n, [], ws_none(), F64.nan(), 0n}

def lv_tr(+t: K.TR, +e: F64, +nu: F64, +rho: F64, +c: CL, +k: Nat, +w: F64, +ws: WS, +hl: F64) -> LV:
  K.TR{+ok, +tm, tw} = t
  lv_ok_go(tm, ok, e, nu, rho, c, k, w, ws, hl)

def lv_modes(+fs: List<&2, SO.Fd>, +h: F64, +e: F64, +nu: F64, +rho: F64, +c: CL, +k: Nat, +w: F64, +ws: WS) -> LV:
  lv_tr(K.tm_of(fs, h), e, nu, rho, c, k, w, ws, h)

type EB is Data:
  EB{ v: F64, est: F64, bd: F64, mono: Bool }

def est3(+a: F64, +b: F64, +c: F64) -> EB:
  +q = F64.div(F64.sub(a, b), F64.sub(b, c))
  +mono = Bool.and(F64.is_lt(1.05f64, q), F64.is_eq(q, q))
  +est = Bool.pick(F64, mono, F64.add(c, F64.div(F64.sub(c, b), F64.sub(q, 1.0f64))), c)
  +bd = Bool.pick(F64, mono, F64.max(F64.abs(F64.sub(c, b)), F64.abs(F64.sub(est, c))),
    F64.mul(2.0f64, F64.max(F64.abs(F64.sub(a, b)), F64.abs(F64.sub(b, c)))))
  EB{c, est, bd, mono}

def eb_s(+x: EB) -> String:
  EB{+v, +est, +bd, +mono} = x
  " est=" ++ F64.show(est) ++ " bound=" ++ F64.show(bd) ++ " status=" ++ Bool.pick(String, mono, "estimated", "estimated-nonmonotone")

def mode_lines(as: List<&2, F64>, bs: List<&2, F64>, cs: List<&2, F64>, +i: Nat) -> String:
  match as:
    case []: ""
    case +a <> +at:
      match bs:
        case []: ""
        case +b <> +bt:
          match cs:
            case []: ""
            case +c <> +ct:
              "mode " ++ Nat.show(i) ++ " hz=[" ++ F64.show(a) ++ ", " ++ F64.show(b) ++ ", " ++ F64.show(c) ++ "]" ++ eb_s(est3(a, b, c)) ++ "\n" ++
                mode_lines(at, bt, ct, Nat.add(i, 1n))

def lv_hz(+l: LV) -> List<&2, F64>:
  LV{ok, nn, ne, nc, nh, rig, it, +hz, w, res, orph} = l
  hz

def lv_ok(+l: LV) -> Bool:
  LV{+ok, nn, ne, nc, nh, rig, it, hz, w, res, orph} = l
  ok

def lv_orph(+l: LV) -> Nat:
  LV{ok, nn, ne, nc, nh, rig, it, hz, w, res, +orph} = l
  orph

def lv_s(+l: LV, +h: F64) -> String:
  LV{ok, +nn, +ne, +nc, +nh, +rig, +it, hz, w, +res, orph} = l
  "level h=" ++ F64.show(h) ++ " nodes=" ++ Nat.show(nn) ++ " tets=" ++ Nat.show(ne) ++ " curved=" ++ Nat.show(nc) ++ " held=" ++ Nat.show(nh) ++
    " rigid=" ++ Nat.show(rig) ++ " iters=" ++ Nat.show(it) ++ " residual=" ++ F64.show(res) ++ "\n"

def cbrt2() -> F64:
  1.2599210498948732f64

def tr_w(+t: K.TR) -> U64:
  K.TR{ok, tm, +w} = t
  w

def w_kind(+k: U64) -> String:
  Bool.pick(String, U64.is_eq(k, 1u64), "met it where membership in the face is uncertain",
    Bool.pick(String, U64.is_eq(k, 2u64), "overlaps it",
      Bool.pick(String, U64.is_eq(k, 3u64), "meets it at an uncertain point", "cannot be intersected with its surface kind")))

def w_face(+c: U64) -> String:
  Bool.pick(String, U64.is_eq(U64.mod(c, 8u64), 5u64), " found no crossing although its ends differ in sign",
    " to face position " ++ U64.show(U64.sub(U64.div(c, 8u64), 1u64)) ++ " (SO.fds_of order) " ++ w_kind(U64.mod(c, 8u64)))

def w_s(+w: U64) -> String:
  +wh = U64.mod(w, 4u64)
  Bool.pick(String, U64.is_eq(wh, 3u64), "an edge cut between lattice points", "a lattice-" ++ Bool.pick(String, U64.is_eq(wh, 1u64), "A", "B") ++ " ray") ++
    w_face(U64.div(w, 4u64))


def mesh_ref(+h: F64, +w: U64) -> String:
  "refused mesh-uncertified | modes | why: the level h=" ++ F64.show(h) ++ " mesh: " ++ w_s(w) ++ " | fix: change H slightly; if every H fails on the same face, that face's geometry is outside the certified mesher\n"

def isl_ref(+h: F64, +n: Nat) -> String:
  "refused mesh-island | modes | why: the level h=" ++ F64.show(h) ++ " mesh has " ++ Nat.show(n) ++
    " tetrahedra in pieces that share fewer than three non-collinear corners with the clamped body, so they move without strain and the lattice cut a feature thinner than h | fix: lower H\n"

def bad_lv(+a: LV, +b: LV, +c: LV, +h: F64) -> String:
  +h1 = F64.div(h, cbrt2())
  +h2 = F64.div(h1, cbrt2())
  +na = lv_orph(a)
  +nb = lv_orph(b)
  Bool.pick(String, Nat.is_lt(0n, na), isl_ref(h, na), Bool.pick(String, Nat.is_lt(0n, nb), isl_ref(h1, nb),
    Bool.pick(String, Nat.is_lt(0n, lv_orph(c)), isl_ref(h2, lv_orph(c)), mesh_ref(h2, 0u64))))

def modes3(+a: LV, +b: LV, +c: LV, +h: F64, +w: F64) -> String:
  +h1 = F64.div(h, cbrt2())
  +h2 = F64.div(h1, cbrt2())
  Bool.pick(String, Bool.and(lv_ok(a), Bool.and(lv_ok(b), lv_ok(c))),
    lv_s(a, h) ++ lv_s(b, h1) ++ lv_s(c, h2) ++ mode_lines(lv_hz(a), lv_hz(b), lv_hz(c), 1n) ++
      "method=T10 isosurface-stuffing mesh, block LOBPCG; bound from three levels h, h/2^(1/3), h/2^(2/3)" ++
        Bool.pick(String, F64.is_lt(0.0f64, w), "; prestressed at rpm=" ++ F64.show(F64.div(F64.mul(w, 60.0f64), 6.283185307179586f64)) ++
          " (stress stiffening from the linear centrifugal state and spin softening)", "") ++ "\n",
    bad_lv(a, b, c, h))

def tr_ok(+t: K.TR) -> Bool:
  K.TR{+ok, tm, w} = t
  ok

def bad_w(+oa: Bool, +ob: Bool, +ta: K.TR, +tb: K.TR, +tc: K.TR) -> U64:
  Bool.pick(U64, Bool.not(oa), tr_w(ta), Bool.pick(U64, Bool.not(ob), tr_w(tb), tr_w(tc)))

def bad_h(+oa: Bool, +ob: Bool, +h: F64) -> F64:
  Bool.pick(F64, Bool.not(oa), h, Bool.pick(F64, Bool.not(ob), F64.div(h, cbrt2()), F64.div(F64.div(h, cbrt2()), cbrt2())))

def modes_t(+ta: K.TR, +tb: K.TR, +tc: K.TR, +h: F64, +e: F64, +nu: F64, +rho: F64, +c: CL, +k: Nat, +w: F64, +oa: Bool, +ob: Bool, ok: Bool) -> String:
  match ok:
    case True{}:
      +a = lv_tr(ta, e, nu, rho, c, k, w, ws_none(), h)
      +b = lv_tr(tb, e, nu, rho, c, k, w, lv_w(a), F64.div(h, cbrt2()))
      modes3(a, b, lv_tr(tc, e, nu, rho, c, k, w, lv_w(b), F64.div(F64.div(h, cbrt2()), cbrt2())), h, w)
    case False{}: mesh_ref(bad_h(oa, ob, h), bad_w(oa, ob, ta, tb, tc))

def modes_s(+fs: List<&2, SO.Fd>, +h: F64, +e: F64, +nu: F64, +rho: F64, +c: CL, +k: Nat, +w: F64) -> String:
  +ta = K.tm_of(fs, h)
  +tb = K.tm_of(fs, F64.div(h, cbrt2()))
  +tc = K.tm_of(fs, F64.div(F64.div(h, cbrt2()), cbrt2()))
  +oa = tr_ok(ta)
  +ob = tr_ok(tb)
  modes_t(ta, tb, tc, h, e, nu, rho, c, k, w, oa, ob, Bool.and(oa, Bool.and(ob, tr_ok(tc))))

type VC is Data:
  VC{ u: B.Tb<&2, F64>, lam: F64, mu: F64 }

def ud(+u: B.Tb<&2, F64>, +n: U32) -> V.Dir:
  +k = U32.mul(n, 3)
  S.dr(B.tb_get(F64, u, k), B.tb_get(F64, u, U32.add(k, 1)), B.tb_get(F64, u, U32.add(k, 2)))

def uds(ns: List<&2, U32>, +u: B.Tb<&2, F64>) -> List<&2, V.Dir>:
  match ns:
    case []: []
    case +n <> +t: ud(u, n) <> uds(t, u)

def gu(gs: List<&2, V.Dir>, us: List<&2, V.Dir>, +h: F.M9) -> F.M9:
  match gs:
    case []: h
    case +g <> +gt:
      match us:
        case []: h
        case +u <> +ut:
          +gx = S.dx(g)
          +gy = S.dy(g)
          +gz = S.dz(g)
          +ux = S.dx(u)
          +uy = S.dy(u)
          +uz = S.dz(u)
          gu(gt, ut, F.m9_add(h, F.M9{F64.mul(gx, ux), F64.mul(gx, uy), F64.mul(gx, uz), F64.mul(gy, ux), F64.mul(gy, uy), F64.mul(gy, uz),
            F64.mul(gz, ux), F64.mul(gz, uy), F64.mul(gz, uz)}))

def sq(+x: F64) -> F64:
  F64.mul(x, x)

def vm_of(+h: F.M9, +lam: F64, +mu: F64) -> F64:
  F.M9{+a, +b, +c, +d, +e, +f, +g, +hh, +i} = h
  +tr = F64.mul(lam, F64.add(F64.add(a, e), i))
  +m2 = F64.mul(2.0f64, mu)
  +sx = F64.add(tr, F64.mul(m2, a))
  +sy = F64.add(tr, F64.mul(m2, e))
  +sz = F64.add(tr, F64.mul(m2, i))
  +txy = F64.mul(mu, F64.add(b, d))
  +txz = F64.mul(mu, F64.add(c, g))
  +tyz = F64.mul(mu, F64.add(f, hh))
  F64.sqrt(F64.add(F64.mul(0.5f64, F64.add(F64.add(sq(F64.sub(sx, sy)), sq(F64.sub(sy, sz))), sq(F64.sub(sz, sx)))),
    F64.mul(3.0f64, F64.add(F64.add(sq(txy), sq(txz)), sq(tyz)))))

def vm_aff(qs: List<&2, List<&2, F64>>, +gl: List<&2, V.Dir>, +us: List<&2, V.Dir>, +lam: F64, +mu: F64, +acc: F64) -> F64:
  match qs:
    case []: acc
    case +q <> +t: vm_aff(t, gl, us, lam, mu, F64.max(acc, vm_of(gu(F.grads(q, gl), us, F.m9z()), lam, mu)))

def vm_qg(+g: F.QG, +us: List<&2, V.Dir>, +lam: F64, +mu: F64) -> F64:
  F.QG{+gs, w} = g
  vm_of(gu(gs, us, F.m9z()), lam, mu)

def vm_cur(qs: List<&2, List<&2, F64>>, +ps: List<&2, V.Point>, +us: List<&2, V.Dir>, +lam: F64, +mu: F64, +acc: F64) -> F64:
  match qs:
    case []: acc
    case +q <> +t: vm_cur(t, ps, us, lam, mu, F64.max(acc, vm_qg(F.qg_of(ps, q), us, lam, mu)))

def el_vm_go(+c: VC, e: F.EL) -> F64:
  VC{+u, +lam, +mu} = c
  match e:
    case F.EL{+ns, +gl, +v}: vm_aff(F.gq(), gl, uds(ns, u), lam, mu, 0.0f64)
    case F.EC{+ns, +ps}: vm_cur(F.wq(), ps, uds(ns, u), lam, mu, 0.0f64)

def el_vm(c: VC, e: F.EL) -> F64:
  el_vm_go(c, e)

def fmax(xs: List<&2, F64>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> +t: fmax(t, F64.max(acc, x))

type GR is Data:
  GR{ rmax: F64, tip: F64, gmax: F64 }

def grow(ps: List<&2, V.Point>, +i: U32, +u: B.Tb<&2, F64>, +c: CL, +g: GR) -> GR:
  match ps:
    case []: g
    case +x <> +t:
      GR{+rm, +tp, +gm} = g
      +w = perp(c, x)
      +r = F64.sqrt(S.dot(w, w))
      +gr = Bool.pick(F64, F64.is_lt(0.0f64, r), F64.div(S.dot(w, ud(u, i)), r), 0.0f64)
      +up = F64.is_lt(rm, r)
      grow(t, U32.add(i, 1), u, c, GR{Bool.pick(F64, up, r, rm), Bool.pick(F64, up, gr, tp), F64.max(gm, gr)})

type SP is Data:
  SP{ ok: Bool, nn: Nat, ne: Nat, nh: Nat, rz: F64, rmax: F64, tip: F64, gmax: F64, vm: F64, wk: F64 }

def hd_l(xs: List<&2, List<&2, F64>>) -> List<&2, F64>:
  match xs:
    case []: []
    case +h <> +t: h

def sp_gr(+g: GR, +ok: Bool, +nn: Nat, +ne: Nat, +nh: Nat, +rz: F64, +vm: F64, +wk: F64) -> SP:
  GR{+rm, +tp, +gm} = g
  SP{ok, nn, ne, nh, rz, rm, tp, gm, vm, wk}

def sp_sv(+sv: F.SV, +f: List<&2, F64>, +ps: List<&2, V.Point>, +es: List<&2, F.EL>, +lam: F64, +mu: F64, +c: CL, +ok: Bool, +nn: Nat, +ne: Nat) -> SP:
  F.SV{+x, +rz} = sv
  +u = B.tb_of(F64, hd_l(x), 0.0f64)
  sp_gr(grow(ps, 0, u, c, GR{0.0f64, 0.0f64, 0.0f64}), ok, nn, ne, n_held(ps, c, 0n), rz,
    fmax(B.pmap_g(~F.EL, ~VC, ~F64, ~el_vm, 64, VC{u, lam, mu}, es), 0.0f64), F.dot_l(f, hd_l(x), 0.0f64))

def lame(+e: F64, +nu: F64) -> F64:
  F64.div(F64.mul(e, nu), F64.mul(F64.add(1.0f64, nu), F64.sub(1.0f64, F64.mul(2.0f64, nu))))

def shear(+e: F64, +nu: F64) -> F64:
  F64.div(e, F64.mul(2.0f64, F64.add(1.0f64, nu)))

def rig_n(ps: List<&2, V.Point>, +p0: V.Point, +k: Nat) -> List<&2, F64>:
  match ps:
    case []: []
    case +x <> +t:
      +r = S.psub(x, p0)
      +v = Bool.pick(V.Dir, Nat.is_eq(k, 0n), S.dr(1.0f64, 0.0f64, 0.0f64), Bool.pick(V.Dir, Nat.is_eq(k, 1n), S.dr(0.0f64, 1.0f64, 0.0f64),
        Bool.pick(V.Dir, Nat.is_eq(k, 2n), S.dr(0.0f64, 0.0f64, 1.0f64), Bool.pick(V.Dir, Nat.is_eq(k, 3n), S.cross(S.dr(1.0f64, 0.0f64, 0.0f64), r),
          Bool.pick(V.Dir, Nat.is_eq(k, 4n), S.cross(S.dr(0.0f64, 1.0f64, 0.0f64), r), S.cross(S.dr(0.0f64, 0.0f64, 1.0f64), r))))))
      S.dx(v) <> S.dy(v) <> S.dz(v) <> rig_n(t, p0, k)

def rigs(+ps: List<&2, V.Point>, +p0: V.Point) -> List<&2, List<&2, F64>>:
  [rig_n(ps, p0, 0n), rig_n(ps, p0, 1n), rig_n(ps, p0, 2n), rig_n(ps, p0, 3n), rig_n(ps, p0, 4n), rig_n(ps, p0, 5n)]

def coef(+v: List<&2, List<&2, F64>>, +d: List<&2, F64>, +b: List<&2, F64>, js: List<&2, Nat>, +acc: List<&2, F64>) -> List<&2, F64>:
  match js:
    case []: acc
    case +j <> +t:
      +vj = F.colj(v, j)
      coef(v, d, b, t, F.axpy(F64.div(F.dot_l(vj, b, 0.0f64), L.nth_f64(d, j)), vj, acc))

def acc_ja(j: F.JA, +b: List<&2, F64>) -> List<&2, F64>:
  F.JA{+a, +v} = j
  coef(v, F.diag_of(a, L.nat_range(6n)), b, L.nat_range(6n), [0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64])

def relieved(+fm: F.FM, +ps: List<&2, V.Point>, +f: List<&2, F64>, +p0: V.Point) -> List<&2, F64>:
  +r = rigs(ps, p0)
  +one = F.ones_l(Nat.mul(3n, List.length(&2, V.Point, ps)))
  +mr = F.blk_op(fm, one, True{}, r)
  F.axpy(F64.neg(1.0f64), F.hd_l(F.rcomb(mr, [acc_ja(F.jacobi(F.pgram(r, mr), 6n), F.gram_row(f, r))])), f)

def cl_p(+c: CL) -> V.Point:
  CL{on, +p, d, r, pl} = c
  p

def sp_free(on: Bool, +f: List<&2, F64>, +fm: F.FM, +ps: List<&2, V.Point>, +c: CL) -> List<&2, F64>:
  match on:
    case True{}: f
    case False{}: relieved(fm, ps, f, cl_p(c))

def sp_bal(ok: Bool, +f: List<&2, F64>, +fm: F.FM, +mask: List<&2, F64>, +ps: List<&2, V.Point>, +es: List<&2, F.EL>, +lam: F64, +mu: F64, +c: CL,
    +nn: Nat, +ne: Nat) -> SP:
  match ok:
    case True{}: sp_sv(F.bsolve_tol(fm, mask, [f], 40000n, 1.0e-10f64), f, ps, es, lam, mu, c, True{}, nn, ne)
    case False{}: SP{False{}, nn, ne, 0n, F64.nan(), 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}

def sp_rel(+bal: Bool, +f: List<&2, F64>, +fm: F.FM, +mask: List<&2, F64>, +ps: List<&2, V.Point>, +es: List<&2, F.EL>, +lam: F64, +mu: F64,
    +c: CL, +nn: Nat, +ne: Nat) -> SP:
  sp_bal(Bool.or(cl_on(c), bal), f, fm, mask, ps, es, lam, mu, c, nn, ne)

def sp_ok2(+ok: Bool, +s: SP) -> SP:
  SP{+o2, +nn, +ne, +nh, +rz, +rm, +tp, +gm, +vm, +wk} = s
  SP{Bool.and(ok, o2), nn, ne, nh, rz, rm, tp, gm, vm, wk}

def sp_go(+tm: K.TM, +ok: Bool, +e: F64, +nu: F64, +rho: F64, +c: CL, +w: F64, +bal: Bool) -> SP:
  K.TM{+ts, +ps, +nn, +nb, +nf, +dv, nl} = tm
  +es = K.fe_els(ts, B.tb_of(V.Point, ps, org()), 1.0e-12f64)
  +mask = cl_mask(ps, c)
  +fm = F.fm_of(U32.from_nat(nn), es, e, nu, rho)
  +f = F.hadam(mask, F.scale(F64.mul(w, w), F.apply_op(fm, True{}, xperp(ps, c))))
  sp_ok2(ok, sp_rel(bal, sp_free(cl_on(c), f, fm, ps, c), fm, mask, ps, es, lame(e, nu), shear(e, nu), c, nn, List.length(&2, K.T10, ts)))

def sp_tr(+t: K.TR, +e: F64, +nu: F64, +rho: F64, +c: CL, +w: F64, +bal: Bool) -> SP:
  K.TR{+ok, +tm, tw} = t
  sp_go(tm, ok, e, nu, rho, c, w, bal)

def sp_lv(+fs: List<&2, SO.Fd>, +h: F64, +e: F64, +nu: F64, +rho: F64, +c: CL, +w: F64, +bal: Bool) -> SP:
  sp_tr(K.tm_of(fs, h), e, nu, rho, c, w, bal)

def sp_ok(+s: SP) -> Bool:
  SP{+ok, nn, ne, nh, rz, rm, tp, gm, vm, wk} = s
  ok

def sp_tip(+s: SP) -> F64:
  SP{ok, nn, ne, nh, rz, rm, +tp, gm, vm, wk} = s
  tp

def sp_gm(+s: SP) -> F64:
  SP{ok, nn, ne, nh, rz, rm, tp, +gm, vm, wk} = s
  gm

def sp_vm(+s: SP) -> F64:
  SP{ok, nn, ne, nh, rz, rm, tp, gm, +vm, wk} = s
  vm

def sp_wk(+s: SP) -> F64:
  SP{ok, nn, ne, nh, rz, rm, tp, gm, vm, +wk} = s
  wk

def sp_s(+s: SP, +h: F64) -> String:
  SP{ok, +nn, +ne, +nh, +rz, +rm, +tp, +gm, +vm, wk} = s
  "level h=" ++ F64.show(h) ++ " nodes=" ++ Nat.show(nn) ++ " tets=" ++ Nat.show(ne) ++ " held=" ++ Nat.show(nh) ++ " rmax=" ++ F64.show(rm) ++
    " tip=" ++ F64.show(tp) ++ " growth_max=" ++ F64.show(gm) ++ " vm_max=" ++ F64.show(vm) ++ " pcg_rz=" ++ F64.show(rz) ++ "\n"

def q_line(+name: String, +a: F64, +b: F64, +c: F64) -> String:
  name ++ " [" ++ F64.show(a) ++ ", " ++ F64.show(b) ++ ", " ++ F64.show(c) ++ "]" ++ eb_s(est3(a, b, c)) ++ "\n"

def spin3(+a: SP, +b: SP, +c: SP, +h: F64) -> String:
  +h1 = F64.div(h, cbrt2())
  +h2 = F64.div(h1, cbrt2())
  Bool.pick(String, Bool.and(sp_ok(a), Bool.and(sp_ok(b), sp_ok(c))),
    sp_s(a, h) ++ sp_s(b, h1) ++ sp_s(c, h2) ++ q_line("tip_growth_mm", sp_tip(a), sp_tip(b), sp_tip(c)) ++
      q_line("max_growth_mm", sp_gm(a), sp_gm(b), sp_gm(c)) ++ q_line("max_von_mises_mpa", sp_vm(a), sp_vm(b), sp_vm(c)) ++
      q_line("work_nmm", sp_wk(a), sp_wk(b), sp_wk(c)) ++
      "method=T10 isosurface-stuffing mesh, clamped nodes within R of the axis, consistent centrifugal load, PCG; bound from three levels\n",
    "refused spin-unsupported | spin | why: the mesh did not certify, or R = 0 on a part that is not balanced about the axis (certified centroid off it or products of inertia about it) | fix: give a clamp radius R > 0 about the axis, or change H slightly\n")

def spin_s(+fs: List<&2, SO.Fd>, +h: F64, +e: F64, +nu: F64, +rho: F64, +c: CL, +w: F64, +bal: Bool) -> String:
  +h1 = F64.div(h, cbrt2())
  +h2 = F64.div(h1, cbrt2())
  spin3(sp_lv(fs, h, e, nu, rho, c, w, bal), sp_lv(fs, h1, e, nu, rho, c, w, bal), sp_lv(fs, h2, e, nu, rho, c, w, bal), h)
