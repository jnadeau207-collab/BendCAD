import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c07/sol.bend as SO
import ../c06/iv.bend as I
import ./sf.bend as S
import ./ef.bend as EF
import ./fb.bend as FB
import ./px.bend as PX
import ./gw.bend as W
import ./ls.bend as L
import ./co.bend as CO
import ./surg.bend as K1

type BK is Data:
  BK{ t: F64, v: Nat }

type FR is Data:
  FR{ rgs: List<&2, W.RG>, pcs: List<&2, W.PC>, keep: List<&2, Bool>, ok: Bool, why: U64 }

type KC is Data:
  KC{ ks: List<&2, Bool>, ok: Bool, why: U64 }

type EM is Data:
  EM{ st: K1.AS, ok: Bool, why: U64 }

type EM2 is Data:
  EM2{ m: EM, cs: List<&2, Nat> }

type GR is Data:
  GR{ ok: Bool, why: U64, brep: Ty.Brep, st: K1.AS }

def key_sub(+sd: U64, +e: Nat, +j: Nat) -> Nat:
  Nat.mul(2n, Nat.add(Nat.mul(Nat.add(Nat.mul(U64.to_nat(sd), 100000n), e), 4096n), j))

def key_ch(+ci: Nat, +j: Nat) -> Nat:
  Nat.add(Nat.mul(2n, Nat.add(Nat.mul(ci, 100000n), j)), 1n)

def bk_t(+b: BK) -> F64:
  BK{t, v} = b
  t

def bk_v(+b: BK) -> Nat:
  BK{t, v} = b
  v

def edge_bks(hs: List<&2, PX.HX>, +sd: U64, +e: Nat) -> List<&2, PX.BP>:
  match hs:
    case []: []
    case +h <> +t:
      +rest = edge_bks(t, sd, e)
      +m = Bool.and(U64.is_eq(PX.hx_side(h), sd), Nat.is_eq(PX.hx_e(h), e))
      Bool.pick(List<&2, PX.BP>, m, PX.BP{PX.hx_t(h), PX.hx_v(h), PX.hx_p(h)} <> rest, rest)

def mk_bp(+t: F64, +v: Nat) -> PX.BP:
  PX.BP{t, v, S.pt(0.0f64, 0.0f64, 0.0f64)}

def sub_kind(+k: Ty.EdgeKind, +a: F64, +b: F64) -> Ty.EdgeKind:
  Ty.EK_curve{EF.ek_curve(k), G.Dom{a, b}}

def mk_er(+key: Nat, +va: Nat, +vb: Nat, +k: Ty.EdgeKind, +fwd: Bool) -> W.ER:
  W.ER{key, va, vb, k, fwd}

def mk_pc(+va: Nat, +vb: Nat, +poly: List<&2, V.Vec2>, +bnd: Bool, +ers: List<&2, W.ER>, +dv: F64) -> W.PC:
  W.PC{va, vb, poly, bnd, ers, dv}

def arc_rebuild(+c0: V.Point, +n: V.Dir, +pa: V.Point, +pb: V.Point, +pm: V.Point) -> List<&2, Ty.EdgeKind>:
  +r = S.dist(pa, c0)
  +u = S.dunit(S.psub(pa, c0))
  +v = S.cross(n, u)
  +cc = {G.Cc{c0, u, v, r} : G.Circle3}
  +ab = S.fatan2(S.dot(S.psub(pb, c0), v), S.dot(S.psub(pb, c0), u))
  +am = S.fatan2(S.dot(S.psub(pm, c0), v), S.dot(S.psub(pm, c0), u))
  +span = F64.add(S.ang_diff(0.0f64, am), S.ang_diff(am, ab))
  Bool.pick(List<&2, Ty.EdgeKind>, F64.is_lt(F64.abs(span), 2.9f64), [PX.rq_arc(cc, pa, pb, 0.0f64, span)], [])

def rebuild_go(+c: G.GVal, +pa: V.Point, +pb: V.Point, +pm: V.Point) -> List<&2, Ty.EdgeKind>:
  match c:
    case G.GV_ln{w}: [PX.ln_kind(pa, pb)]
    case G.GV_cc{w}:
      G.Cc{+c0, +u, +v, +r} = w
      arc_rebuild(c0, S.dunit(S.cross(u, v)), pa, pb, pm)
    case G.GV_rq{w}:
      G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = w
      +m = S.padd(p0, 0.5f64, S.psub(p2, p0))
      +kk = F64.div(F64.mul(w1, w1), F64.sub(1.0f64, F64.mul(w1, w1)))
      +c0 = S.padd(m, kk, S.psub(m, p1))
      arc_rebuild(c0, S.dunit(S.cross(S.psub(p0, c0), S.psub(p1, c0))), pa, pb, pm)
    case _: []

def k1l(xs: List<&2, Ty.EdgeKind>) -> Ty.EdgeKind:
  match xs:
    case []: Ty.EK_degenerate{}
    case +h <> +t: h

def sub_kind_x(+k: Ty.EdgeKind, +a: F64, +b: F64, +pa: V.Point, +pb: V.Point) -> Ty.EdgeKind:
  +c = EF.ek_curve(k)
  +exact = Bool.and(PX.peq(EF.ev(c, a), pa), PX.peq(EF.ev(c, b), pb))
  +rb = rebuild_go(c, pa, pb, EF.ev(c, F64.mul(0.5f64, F64.add(a, b))))
  Bool.pick(Ty.EdgeKind, exact, sub_kind(k, a, b), k1l(rb))

def sub_pcs(bs: List<&2, PX.BP>, +s: S.SF, +k: Ty.EdgeKind, +sd: U64, +e: Nat, +j: Nat,
    +fw: Bool, +gv: PX.GV) -> List<&2, W.PC>:
  match bs:
    case []: []
    case +h <> +t:
      +h2 = PX.L_bp0(t, h)
      +rest = sub_pcs(t, s, k, sd, e, Nat.add(j, 1n), fw, gv)
      +sk = sub_kind_x(k, PX.bp_s(h), PX.bp_s(h2), PX.gv_pt(gv, PX.bp_v(h)), PX.gv_pt(gv, PX.bp_v(h2)))
      +er = mk_er(key_sub(sd, e, j), PX.bp_v(h), PX.bp_v(h2), sk, fw)
      +p0 = FB.uv_raw(s, EF.ev(EF.ek_curve(k), Bool.pick(F64, fw, PX.bp_s(h), PX.bp_s(h2))))
      +poly = FB.poly_of(s, k, Bool.pick(F64, fw, PX.bp_s(h), PX.bp_s(h2)), Bool.pick(F64, fw, PX.bp_s(h2), PX.bp_s(h)), p0)
      +pc = mk_pc(Bool.pick(Nat, fw, PX.bp_v(h), PX.bp_v(h2)), Bool.pick(Nat, fw, PX.bp_v(h2), PX.bp_v(h)), poly, True{}, [er], 0.0f64)
      Bool.pick(List<&2, W.PC>, Nat.is_eq(List.length(&2, PX.BP, t), 0n), [], pc <> rest)

def ce_pcs(+c: FB.CE, +b: Ty.Brep, +s: S.SF, +sd: U64, +vmap: List<&2, Nat>, +hs: List<&2, PX.HX>,
    +gv: PX.GV) -> List<&2, W.PC>:
  +e = FB.ce_e(c)
  +ed = FB.edge_at(b, e)
  +k = Ty.ed_kind(ed)
  +v0 = L.nth_n(vmap, Ty.hv_idx(Ty.ed_v0(ed)))
  +v1 = L.nth_n(vmap, Ty.hv_idx(Ty.ed_v1(ed)))
  +mid = PX.dedup_bp(PX.bp_sort(edge_bks(hs, sd, e)))
  +bs = List.append(&2, PX.BP, mk_bp(EF.ek_lo(k), v0) <> mid, [mk_bp(EF.ek_hi(k), v1)])
  +ps = sub_pcs(bs, s, k, sd, e, 0n, FB.ce_fw(c), gv)
  Bool.pick(List<&2, W.PC>, FB.ce_fw(c), ps, List.reverse(&2, W.PC, ps))

def loop_pcs(cs: List<&2, FB.CE>, +b: Ty.Brep, +s: S.SF, +sd: U64, +vmap: List<&2, Nat>,
    +hs: List<&2, PX.HX>, +gv: PX.GV) -> List<&2, W.PC>:
  match cs:
    case []: []
    case +h <> +t: List.append(&2, W.PC, ce_pcs(h, b, s, sd, vmap, hs, gv), loop_pcs(t, b, s, sd, vmap, hs, gv))

def loops_pcs(ls: List<&2, List<&2, FB.CE>>, +b: Ty.Brep, +s: S.SF, +sd: U64, +vmap: List<&2, Nat>,
    +hs: List<&2, PX.HX>, +gv: PX.GV) -> List<&2, W.PC>:
  match ls:
    case []: []
    case +h <> +t: List.append(&2, W.PC, loop_pcs(h, b, s, sd, vmap, hs, gv), loops_pcs(t, b, s, sd, vmap, hs, gv))

def neg_ers(xs: List<&2, W.ER>) -> List<&2, W.ER>:
  match xs:
    case []: []
    case +h <> +t: mk_er(W.er_key(h), W.er_va(h), W.er_vb(h), W.er_k(h), Bool.not(W.er_fwd(h))) <> neg_ers(t)

def rev_pc(+p: W.PC) -> W.PC:
  mk_pc(W.pc_vb(p), W.pc_va(p), W.rev_v2(W.pc_poly(p)), W.pc_bnd(p), List.reverse(&2, W.ER, neg_ers(W.pc_ers(p))), W.pc_dv(p))

def rev_all(xs: List<&2, W.PC>) -> List<&2, W.PC>:
  match xs:
    case []: []
    case +h <> +t: rev_pc(h) <> rev_all(t)

def pts_uv(ps: List<&2, V.Point>, +s: S.SF, +prev: V.Vec2, +first: Bool) -> List<&2, V.Vec2>:
  match ps:
    case []: []
    case +h <> +t:
      +q0 = FB.uv_raw(s, h)
      +q = Bool.pick(V.Vec2, first, q0, FB.unwrap(s, prev, q0))
      q <> pts_uv(t, s, q, False{})

def seg_ers(ss: List<&2, PX.SEG>, +ci: Nat, +j: Nat) -> List<&2, W.ER>:
  match ss:
    case []: []
    case +h <> +t: mk_er(key_ch(ci, j), PX.seg_va(h), PX.seg_vb(h), PX.seg_k(h), True{}) <> seg_ers(t, ci, Nat.add(j, 1n))

def circ_poly(+c: PX.CH, +s: S.SF) -> List<&2, V.Vec2>:
  +k = PX.seg_k(PX.L_last_seg(PX.ch_segs(c)))
  FB.poly_of(s, k, EF.ek_lo(k), EF.ek_hi(k), FB.uv_raw(s, EF.ev(EF.ek_curve(k), EF.ek_lo(k))))

def ch_pc(+c: PX.CH, +ci: Nat, +s: S.SF) -> W.PC:
  +ss = PX.ch_segs(c)
  +va = PX.seg_va(PX.L_last_seg(ss))
  +vb = PX.seg_vb(PX.L_last_seg(List.reverse(&2, PX.SEG, ss)))
  +poly = pts_uv(PX.ch_pts(c), s, V.V2{0.0f64, 0.0f64}, True{})
  +poly2 = Bool.pick(List<&2, V.Vec2>, Bool.and(PX.ch_closed(c), Nat.is_le(List.length(&2, V.Vec2, poly), 2n)),
    circ_poly(c, s), poly)
  mk_pc(va, vb, poly2, False{}, seg_ers(ss, ci, 0n), PX.ch_dv(c))

def chain_pcs(cs: List<&2, PX.CH>, +sd: U64, +fi: Nat, +s: S.SF, +ci: Nat) -> List<&2, W.PC>:
  match cs:
    case []: []
    case +h <> +t:
      +mine = Bool.pick(Bool, U64.is_eq(sd, 0u64), Nat.is_eq(PX.ch_fa(h), fi), Nat.is_eq(PX.ch_fb(h), fi))
      +rest = chain_pcs(t, sd, fi, s, Nat.add(ci, 1n))
      Bool.pick(List<&2, W.PC>, mine, ch_pc(h, ci, s) <> rest, rest)

def cut_of(+p: W.PC) -> W.PC:
  mk_pc(W.pc_va(p), W.pc_vb(p), W.pc_poly(p), False{}, W.pc_ers(p), W.pc_dv(p))

def poly_mid(+poly: List<&2, V.Vec2>) -> V.Vec2:
  +n = List.length(&2, V.Vec2, poly)
  +a = L.nth_v2(poly, 0n)
  +b = L.nth_v2(poly, 1n)
  Bool.pick(V.Vec2, Nat.is_le(n, 2n),
    V.V2{F64.mul(0.5f64, F64.add(V.v2_x(a), V.v2_x(b))), F64.mul(0.5f64, F64.add(V.v2_y(a), V.v2_y(b)))},
    L.nth_v2(poly, Nat.div(n, 2n)))

def inside_pcs(ps: List<&2, W.PC>, +s: S.SF, +b: Ty.Brep, +fi: Nat) -> List<&2, W.PC>:
  match ps:
    case []: []
    case +h <> +t:
      +q = poly_mid(W.pc_poly(h))
      +p3 = S.sf_at(s, V.v2_x(q), V.v2_y(q))
      +ins = Bool.and(FB.pip(s, FB.face_polys(b, fi), q), Bool.not(FB.bnd_near(b, fi, p3)))
      +rest = inside_pcs(t, s, b, fi)
      Bool.pick(List<&2, W.PC>, ins, cut_of(h) <> rest, rest)

def partner_pcs(cs: List<&2, CO.CP>, +sd: U64, +s: S.SF, +b: Ty.Brep, +fi: Nat, +ob: Ty.Brep,
    +vmo: List<&2, Nat>, +hs: List<&2, PX.HX>, +gv: PX.GV) -> List<&2, W.PC>:
  match cs:
    case []: []
    case +h <> +t:
      +pf = Bool.pick(Nat, U64.is_eq(sd, 0u64), CO.cp_fb(h), CO.cp_fa(h))
      +osd = Bool.pick(U64, U64.is_eq(sd, 0u64), 1u64, 0u64)
      +ps = loops_pcs(FB.face_ce(ob, pf), ob, s, osd, vmo, hs, gv)
      List.append(&2, W.PC, inside_pcs(ps, s, b, fi), partner_pcs(t, sd, s, b, fi, ob, vmo, hs, gv))

def face_pcs(+b: Ty.Brep, +fi: Nat, +sd: U64, +vmap: List<&2, Nat>, +hs: List<&2, PX.HX>,
    +chs: List<&2, PX.CH>, +cps: List<&2, CO.CP>, +ob: Ty.Brep, +vmo: List<&2, Nat>, +gv: PX.GV) -> List<&2, W.PC>:
  +s = S.sf_of(FB.face_surf(b, fi))
  +bp = loops_pcs(FB.face_ce(b, fi), b, s, sd, vmap, hs, gv)
  +bp2 = Bool.pick(List<&2, W.PC>, FB.face_same(b, fi), bp, rev_all(bp))
  +pp = partner_pcs(CO.partner_of(cps, sd, fi), sd, s, b, fi, ob, vmo, hs, gv)
  List.append(&2, W.PC, bp2, List.append(&2, W.PC, chain_pcs(chs, sd, fi, s, 0n), pp))

def fr_rgs(+r: FR) -> List<&2, W.RG>:
  FR{rgs, pcs, keep, ok, why} = r
  rgs

def fr_pcs(+r: FR) -> List<&2, W.PC>:
  FR{rgs, pcs, keep, ok, why} = r
  pcs

def fr_keep(+r: FR) -> List<&2, Bool>:
  FR{rgs, pcs, keep, ok, why} = r
  keep

def fr_ok(+r: FR) -> Bool:
  FR{rgs, pcs, keep, ok, why} = r
  ok

def fr_why(+r: FR) -> U64:
  FR{rgs, pcs, keep, ok, why} = r
  why

def keep_of(+op: U64, +sd: U64, +c: U64) -> Bool:
  +onk = Bool.and(U64.is_eq(sd, 0u64),
    Bool.pick(Bool, U64.is_eq(c, 4u64), Bool.not(U64.is_eq(op, 15u64)), U64.is_eq(op, 15u64)))
  Bool.pick(Bool, U64.is_le(4u64, c), onk,
    Bool.pick(Bool, U64.is_eq(op, 14u64), U64.is_eq(c, 0u64),
      Bool.pick(Bool, U64.is_eq(op, 16u64), U64.is_eq(c, 1u64),
        Bool.pick(Bool, U64.is_eq(sd, 0u64), U64.is_eq(c, 0u64), U64.is_eq(c, 1u64)))))

def kc_ks(+k: KC) -> List<&2, Bool>:
  KC{ks, ok, why} = k
  ks

def kc_ok(+k: KC) -> Bool:
  KC{ks, ok, why} = k
  ok

def kc_why(+k: KC) -> U64:
  KC{ks, ok, why} = k
  why

def classify_rgs(rs: List<&2, W.RG>, +s: S.SF, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>, +op: U64,
    +sd: U64, +pcp: List<&2, CO.CP>, +ob: Ty.Brep) -> KC:
  match rs:
    case []: KC{[], True{}, 0u64}
    case +h <> +t:
      +sp = W.sample_pt(s, h)
      +p = S.sf_at(s, V.v2_x(W.sp_q(sp)), V.v2_y(W.sp_q(sp)))
      +oc = CO.on_code(pcp, sd, ob, p)
      +c = Bool.pick(U64, U64.is_eq(oc, 0u64), SO.classify_in(fdo, bbo, p), oc)
      +rest = classify_rgs(t, s, fdo, bbo, op, sd, pcp, ob)
      +good = Bool.and(W.sp_ok(sp), Bool.or(U64.is_le(c, 1u64), U64.is_le(4u64, c)))
      KC{keep_of(op, sd, c) <> kc_ks(rest), Bool.and(good, kc_ok(rest)),
        Bool.pick(U64, good, kc_why(rest), Bool.pick(U64, W.sp_ok(sp), 92u64, 91u64))}

def face_run(+b: Ty.Brep, +fi: Nat, +sd: U64, +vmap: List<&2, Nat>, +hs: List<&2, PX.HX>,
    +chs: List<&2, PX.CH>, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>, +op: U64,
    +cps: List<&2, CO.CP>, +ob: Ty.Brep, +vmo: List<&2, Nat>, +gv: PX.GV) -> FR:
  +s = S.sf_of(FB.face_surf(b, fi))
  +pcs = face_pcs(b, fi, sd, vmap, hs, chs, cps, ob, vmo, gv)
  +cs = W.face_cycles(s, pcs)
  +rs = W.regions(s, W.cs_cys(cs))
  +kc = classify_rgs(W.rs_rgs(rs), s, fdo, bbo, op, sd, CO.partner_of(cps, sd, fi), ob)
  +ok = Bool.and(W.cs_ok(cs), Bool.and(W.rs_ok(rs), kc_ok(kc)))
  FR{W.rs_rgs(rs), pcs, kc_ks(kc), ok,
    Bool.pick(U64, W.cs_ok(cs), Bool.pick(U64, W.rs_ok(rs), kc_why(kc), 94u64), 93u64)}

def em_st(+m: EM) -> K1.AS:
  EM{st, ok, why} = m
  st

def em_ok(+m: EM) -> Bool:
  EM{st, ok, why} = m
  ok

def em_why(+m: EM) -> U64:
  EM{st, ok, why} = m
  why

def trim_of(+g: G.GVal, +s: S.SF, +pa: V.Point, +pb: V.Point) -> G.GVal:
  +ua = EF.pl_uv(g, pa)
  +ub = EF.pl_uv(g, pb)
  Bool.pick(G.GVal, U64.is_eq(S.sf_kind(s), S.k_plane()),
    G.GV_ts{G.Ts{V.V2{EF.uv_u(ua), EF.uv_v(ua)}, V.V2{EF.uv_u(ub), EF.uv_v(ub)}}},
    G.GV_ts{G.Ts{FB.uv_raw(s, pa), FB.uv_raw(s, pb)}})

def trim_ok(+g: G.GVal, +s: S.SF, +pa: V.Point, +pb: V.Point) -> Bool:
  Bool.or(Bool.not(U64.is_eq(S.sf_kind(s), S.k_plane())),
    Bool.and(EF.uv_ok(EF.pl_uv(g, pa)), EF.uv_ok(EF.pl_uv(g, pb))))

def mk_ed(+va: Nat, +vb: Nat, +e: W.ER) -> Ty.Edge:
  Ty.Ed{0u64, K1.hv(va), K1.hv(vb), W.er_k(e)}

def mk_ce(+ei: Nat, +fw: Bool, +gl: List<&2, G.GVal>, +s: S.SF, +pa: V.Point, +pb: V.Point) -> Ty.Coedge:
  Ty.Ce{0u64, K1.he(ei), fw, trim_of(PX.nth_g(gl, 0n), s, pa, pb)}

def emit_er(+m: EM, +e: W.ER, +gl: List<&2, G.GVal>, +s: S.SF, +gv: PX.GV) -> EM:
  +va = W.er_va(e)
  +vb = W.er_vb(e)
  +fw = W.er_fwd(e)
  +key = W.er_key(e)
  +r = K1.eemit(em_st(m), va, vb, 0u64, 0u64, key, mk_ed(va, vb, e))
  +pa = PX.gv_pt(gv, va)
  +pb = PX.gv_pt(gv, vb)
  +tok = trim_ok(PX.nth_g(gl, 0n), s, pa, pb)
  +st2 = K1.as_add_ce(K1.er_st(r), mk_ce(K1.er_idx(r), fw, gl, s, pa, pb))
  EM{st2, Bool.and(em_ok(m), tok), Bool.pick(U64, Bool.and(em_ok(m), Bool.not(tok)), 95u64, em_why(m))}

def emit_ers(xs: List<&2, W.ER>, +m: EM, +g: List<&2, G.GVal>, +s: S.SF, +gv: PX.GV, +acc: List<&2, Nat>) -> EM2:
  match xs:
    case []: EM2{m, List.reverse(&2, Nat, acc)}
    case +h <> +t:
      +ci = K1.as_nc(em_st(m))
      emit_ers(t, emit_er(m, h, g, s, gv), g, s, gv, ci <> acc)

def em2_m(+x: EM2) -> EM:
  EM2{m, cs} = x
  m

def em2_cs(+x: EM2) -> List<&2, Nat>:
  EM2{m, cs} = x
  cs

def he_ers(+pcs: List<&2, W.PC>, +h: W.HE, +rev: Bool) -> List<&2, W.ER>:
  +p = W.nth_pc(pcs, W.he_i(h))
  +f = Bool.xor(W.he_fw(h), rev)
  Bool.pick(List<&2, W.ER>, f, W.pc_ers(p), List.reverse(&2, W.ER, neg_ers(W.pc_ers(p))))

def cyc_ers(hs: List<&2, W.HE>, +pcs: List<&2, W.PC>, +rev: Bool) -> List<&2, W.ER>:
  match hs:
    case []: []
    case +h <> +t: List.append(&2, W.ER, he_ers(pcs, h, rev), cyc_ers(t, pcs, rev))

def hcs_of(xs: List<&2, Nat>) -> List<&2, Ty.HCoedge>:
  match xs:
    case []: []
    case +h <> +t: K1.hc(h) <> hcs_of(t)

def emit_cys(cs: List<&2, W.CY>, +pcs: List<&2, W.PC>, +rev: Bool, +m: EM, +g: List<&2, G.GVal>, +s: S.SF,
    +gv: PX.GV, +first: Bool, +acc: List<&2, Nat>) -> EM2:
  match cs:
    case []: EM2{m, List.reverse(&2, Nat, acc)}
    case +h <> +t:
      +hes = Bool.pick(List<&2, W.HE>, rev, List.reverse(&2, W.HE, W.cy_hes(h)), W.cy_hes(h))
      +r = emit_ers(cyc_ers(hes, pcs, rev), m, g, s, gv, [])
      +st = em_st(em2_m(r))
      +li = K1.as_nl(st)
      +st2 = K1.as_add_lp(st, Ty.Lp{0u64, hcs_of(em2_cs(r)), Bool.pick(Ty.LoopKind, first, Ty.LK_outer{}, Ty.LK_inner{})})
      emit_cys(t, pcs, rev, EM{st2, em_ok(em2_m(r)), em_why(em2_m(r))}, g, s, gv, False{}, li <> acc)

def hls_of(xs: List<&2, Nat>) -> List<&2, Ty.HLoop>:
  match xs:
    case []: []
    case +h <> +t: K1.hlp(h) <> hls_of(t)

def mk_fa(+g: List<&2, G.GVal>, +ls: List<&2, Ty.HLoop>, +so: Bool, +dv: F64) -> Ty.Face:
  Ty.Fa{0u64, PX.nth_g(g, 0n), ls, so, dv, 0.0f64}

def hes_dv(hs: List<&2, W.HE>, +pcs: List<&2, W.PC>, +best: F64) -> F64:
  match hs:
    case []: best
    case +h <> +t: hes_dv(t, pcs, F64.max(best, W.pc_dv(W.nth_pc(pcs, W.he_i(h)))))

def cys_dv(cs: List<&2, W.CY>, +pcs: List<&2, W.PC>, +best: F64) -> F64:
  match cs:
    case []: best
    case +h <> +t: cys_dv(t, pcs, hes_dv(W.cy_hes(h), pcs, best))

def emit_rg(+r: W.RG, +pcs: List<&2, W.PC>, +same: Bool, +flip: Bool, +g: List<&2, G.GVal>, +s: S.SF,
    +gv: PX.GV, +m: EM) -> EM:
  +so = Bool.xor(same, flip)
  +dv = cys_dv(W.rg_cys(r), pcs, 0.0f64)
  +x = emit_cys(W.rg_cys(r), pcs, Bool.not(so), m, g, s, gv, True{}, [])
  +st = em_st(em2_m(x))
  EM{K1.as_add_fa(st, mk_fa(g, hls_of(em2_cs(x)), so, dv)), em_ok(em2_m(x)), em_why(em2_m(x))}

def L_b0(xs: List<&2, Bool>) -> Bool:
  match xs:
    case []: False{}
    case +h <> +t: h

def L_btail(xs: List<&2, Bool>) -> List<&2, Bool>:
  match xs:
    case []: []
    case +h <> +t: t

def emit_face(rs: List<&2, W.RG>, +ks: List<&2, Bool>, +pcs: List<&2, W.PC>, +same: Bool, +flip: Bool,
    +g: List<&2, G.GVal>, +s: S.SF, +gv: PX.GV, +m: EM) -> EM:
  match rs:
    case []: m
    case +h <> +t:
      +k = L_b0(ks)
      +m2 = emit_rg(h, pcs, same, flip, g, s, gv, m)
      emit_face(t, L_btail(ks), pcs, same, flip, g, s, gv, Bool.pick(EM, k, m2, m))

def side_go(fs: List<&2, Nat>, +b: Ty.Brep, +sd: U64, +vmap: List<&2, Nat>, +hs: List<&2, PX.HX>,
    +chs: List<&2, PX.CH>, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>, +op: U64, +gv: PX.GV, +m: EM,
    +cps: List<&2, CO.CP>, +ob: Ty.Brep, +vmo: List<&2, Nat>) -> EM:
  match fs:
    case []: m
    case +h <> +t:
      +fr = face_run(b, h, sd, vmap, hs, chs, fdo, bbo, op, cps, ob, vmo, gv)
      +g = {[FB.face_surf(b, h)] : List<&2, G.GVal>}
      +flip = Bool.and(U64.is_eq(op, 15u64), U64.is_eq(sd, 1u64))
      +m2 = emit_face(fr_rgs(fr), fr_keep(fr), fr_pcs(fr), FB.face_same(b, h), flip, g, S.sf_of(PX.nth_g(g, 0n)), gv, m)
      +m3 = Bool.pick(EM, fr_ok(fr), m2, EM{em_st(m2), False{}, Bool.pick(U64, em_ok(m), fr_why(fr), em_why(m))})
      side_go(t, b, sd, vmap, hs, chs, fdo, bbo, op, gv, m3, cps, ob, vmo)

def add_vs_go(ps: List<&2, V.Point>, +st: K1.AS) -> K1.AS:
  match ps:
    case []: st
    case +h <> +t: add_vs_go(t, K1.as_add_v(st, h))

def gr_ok(+r: GR) -> Bool:
  GR{ok, why, brep, st} = r
  ok

def gr_why(+r: GR) -> U64:
  GR{ok, why, brep, st} = r
  why

def gr_brep(+r: GR) -> Ty.Brep:
  GR{ok, why, brep, st} = r
  brep

def run_emit(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep, +vma: List<&2, Nat>, +vmb: List<&2, Nat>,
    +hs: List<&2, PX.HX>, +chs: List<&2, PX.CH>, +gv: PX.GV, +cps: List<&2, CO.CP>) -> EM:
  +fda = SO.fds_of(ba)
  +fdb = SO.fds_of(bb)
  +bba = SO.bbox(fda, [])
  +bbb = SO.bbox(fdb, [])
  +st0 = add_vs_go(List.reverse(&2, V.Point, PX.gv_ps(gv)), K1.as_empty())
  +m1 = side_go(L.nat_range(FB.nfaces(ba)), ba, 0u64, vma, hs, chs, fdb, bbb, op, gv, EM{st0, True{}, 0u64}, cps, bb, vmb)
  side_go(L.nat_range(FB.nfaces(bb)), bb, 1u64, vmb, hs, chs, fda, bba, op, gv, m1, cps, ba, vma)

def finish_go(+ok: Bool, +m: EM, +ba: Ty.Brep) -> K1.KR:
  match ok:
    case False{}: K1.KR{False{}, em_why(m), ba, 0n, 0n, 0n, 0n}
    case True{}:
      +asb = K1.k1assemble(em_st(m))
      K1.k1run_d(K1.kab_ok(asb), K1.kab_why(asb), K1.kab_brep(asb))

def finish(+m: EM, +ba: Ty.Brep) -> K1.KR:
  finish_go(em_ok(m), m, ba)

def gbrun_go(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> K1.KR:
  +va = PX.add_vs(Ty.brep_vs(ba), PX.GV{[], 0n}, [])
  +vb = PX.add_vs(Ty.brep_vs(bb), PX.vm_g(va), [])
  +hs = PX.all_hits(ba, bb, PX.vm_g(vb))
  +cps = CO.coin_pairs(ba, bb)
  +cx0 = CO.crossings(cps, ba, bb, PX.hs_g(hs))
  +tj = CO.tjunctions(cps, ba, bb, CO.cx_g(cx0))
  +cx = {CO.CX{List.append(&2, PX.HX, CO.cx_hs(cx0), CO.cx_hs(tj)), CO.cx_g(tj), Bool.and(CO.cx_ok(cx0), CO.cx_ok(tj))} : CO.CX}
  +hs2 = List.append(&2, PX.HX, PX.hs_hs(hs), CO.cx_hs(cx))
  +cr = PX.all_chains(hs2, ba, bb, CO.cx_g(cx))
  +ok = Bool.and(Bool.and(PX.hs_ok(hs), CO.cx_ok(cx)), PX.cr_ok(cr))
  +why = Bool.pick(U64, PX.hs_ok(hs), Bool.pick(U64, CO.cx_ok(cx), PX.cr_why(cr), 97u64), PX.hs_why(hs))
  +m = run_emit(op, ba, bb, PX.vm_mp(va), PX.vm_mp(vb), hs2, PX.cr_chs(cr), PX.cr_g(cr), cps)
  finish(Bool.pick(EM, ok, m, EM{em_st(m), False{}, why}), ba)

def fas_sup(fs: List<&2, Ty.Face>, +ok: Bool) -> Bool:
  match fs:
    case []: ok
    case +h <> +t: fas_sup(t, Bool.and(ok, S.sf_ok(S.sf_of(Ty.fa_surf(h)))))

def gbrun_s(+sup: Bool, +op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> K1.KR:
  match sup:
    case False{}: K1.KR{False{}, 2u64, ba, 0n, 0n, 0n, 0n}
    case True{}: gbrun_go(op, ba, bb)

def gbrun(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> K1.KR:
  gbrun_s(Bool.and(fas_sup(Ty.brep_fas(ba), True{}), fas_sup(Ty.brep_fas(bb), True{})), op, ba, bb)
