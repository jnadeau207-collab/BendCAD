import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../base/par.bend as B
import ./sf.bend as S
import ./ef.bend as EF
import ./ss.bend as SS
import ./fb.bend as FB
import ./ls.bend as L

type GV is Data:
  GV{ ps: List<&2, V.Point>, n: Nat }

type VI is Data:
  VI{ g: GV, i: Nat }

type VM is Data:
  VM{ g: GV, mp: List<&2, Nat> }

type HX is Data:
  HX{ side: U64, e: Nat, t: F64, p: V.Point, v: Nat, fo: Nat }

type HS is Data:
  HS{ hs: List<&2, HX>, g: GV, ok: Bool, why: U64 }

type SEG is Data:
  SEG{ va: Nat, vb: Nat, k: Ty.EdgeKind }

type CH is Data:
  CH{ fa: Nat, fb: Nat, segs: List<&2, SEG>, pts: List<&2, V.Point>, closed: Bool, dv: F64 }

type BP is Data:
  BP{ s: F64, v: Nat, p: V.Point }

type CR is Data:
  CR{ chs: List<&2, CH>, g: GV, ok: Bool, why: U64 }

type PP is Data:
  PP{ p: V.Point, v: Nat, brk: Bool }

type PV is Data:
  PV{ xs: List<&2, PP>, g: GV }

type HXG is Data:
  HXG{ hs: List<&2, HX>, g: GV }

type NB2 is Data:
  NB2{ i: Nat, d: F64 }

def gv_ps(+g: GV) -> List<&2, V.Point>:
  GV{ps, n} = g
  ps

def gv_n(+g: GV) -> Nat:
  GV{ps, n} = g
  n

def vi_g(+r: VI) -> GV:
  VI{g, i} = r
  g

def vi_i(+r: VI) -> Nat:
  VI{g, i} = r
  i

def peq(+a: V.Point, +b: V.Point) -> Bool:
  Bool.and(F64.is_eq(S.px(a), S.px(b)), Bool.and(F64.is_eq(S.py(a), S.py(b)), F64.is_eq(S.pz(a), S.pz(b))))

def find_go(ps: List<&2, V.Point>, +p: V.Point, +i: Nat, +n: Nat) -> Nat:
  match ps:
    case []: n
    case +h <> +t: Bool.pick(Nat, peq(h, p), i, find_go(t, p, Nat.add(i, 1n), n))

def gv_add(+g: GV, +p: V.Point) -> VI:
  +f = find_go(List.reverse(&2, V.Point, gv_ps(g)), p, 0n, gv_n(g))
  Bool.pick(VI, Nat.is_lt(f, gv_n(g)), VI{g, f}, VI{GV{p <> gv_ps(g), Nat.add(gv_n(g), 1n)}, gv_n(g)})

def gv_pt(+g: GV, +i: Nat) -> V.Point:
  L.nth_p(gv_ps(g), Nat.sub(Nat.sub(gv_n(g), 1n), i))

def vm_g(+r: VM) -> GV:
  VM{g, mp} = r
  g

def vm_mp(+r: VM) -> List<&2, Nat>:
  VM{g, mp} = r
  mp

def add_vs(vs: List<&2, Ty.Vertex>, +g: GV, +acc: List<&2, Nat>) -> VM:
  match vs:
    case []: VM{g, List.reverse(&2, Nat, acc)}
    case +h <> +t:
      +r = gv_add(g, Ty.vx_p(h))
      add_vs(t, vi_g(r), vi_i(r) <> acc)

def hx_side(+h: HX) -> U64:
  HX{side, e, t, p, v, fo} = h
  side

def hx_e(+h: HX) -> Nat:
  HX{side, e, t, p, v, fo} = h
  e

def hx_t(+h: HX) -> F64:
  HX{side, e, t, p, v, fo} = h
  t

def hx_p(+h: HX) -> V.Point:
  HX{side, e, t, p, v, fo} = h
  p

def hx_v(+h: HX) -> Nat:
  HX{side, e, t, p, v, fo} = h
  v

def hx_fo(+h: HX) -> Nat:
  HX{side, e, t, p, v, fo} = h
  fo

def hs_hs(+r: HS) -> List<&2, HX>:
  HS{hs, g, ok, why} = r
  hs

def hs_g(+r: HS) -> GV:
  HS{hs, g, ok, why} = r
  g

def hs_ok(+r: HS) -> Bool:
  HS{hs, g, ok, why} = r
  ok

def hs_why(+r: HS) -> U64:
  HS{hs, g, ok, why} = r
  why

def why_near() -> U64:
  81u64

def why_hcert() -> U64:
  82u64

def why_vtouch() -> U64:
  83u64

def why_seam() -> U64:
  84u64

def why_lexact() -> U64:
  85u64

def surfs_of(fs: List<&2, Nat>, +b: Ty.Brep) -> List<&2, G.GVal>:
  match fs:
    case []: []
    case +h <> +t: FB.face_surf(b, h) <> surfs_of(t, b)

def eh_keep(hs: List<&2, EF.EH>, +side: U64, +e: Nat, +fo: Nat, +ob: Ty.Brep, +lo: F64, +hi: F64,
    +st: HS) -> HS:
  match hs:
    case []: st
    case +h <> +t:
      +p = EF.eh_p(h)
      +tt = EF.eh_t(h)
      +inside = Bool.and(FB.pt_in_face(ob, fo, p), Bool.not(FB.bnd_near(ob, fo, p)))
      +atend = Bool.or(F64.is_eq(tt, lo), F64.is_eq(tt, hi))
      +r = gv_add(hs_g(st), p)
      +ok = Bool.and(hs_ok(st), Bool.or(Bool.not(inside), Bool.and(EF.eh_ok(h), Bool.not(atend))))
      +why = Bool.pick(U64, hs_ok(st), Bool.pick(U64, Bool.not(inside), 0u64,
        Bool.pick(U64, atend, why_vtouch(), Bool.pick(U64, EF.eh_ok(h), 0u64, why_hcert()))), hs_why(st))
      +nst = Bool.pick(HS, inside,
        HS{HX{side, e, tt, p, vi_i(r), fo} <> hs_hs(st), vi_g(r), ok, why},
        HS{hs_hs(st), hs_g(st), ok, why})
      eh_keep(t, side, e, fo, ob, lo, hi, nst)

def ef_one(+side: U64, +e: Nat, +b: Ty.Brep, +ob: Ty.Brep, +fo: Nat, +st: HS) -> HS:
  +k = Ty.ed_kind(FB.edge_at(b, e))
  +g = FB.face_surf(ob, fo)
  +r = EF.edge_hits(k, S.sf_of(g), g <> surfs_of(FB.edge_faces(b, e), b))
  +st2 = eh_keep(EF.ehs_hs(r), side, e, fo, ob, EF.ek_lo(k), EF.ek_hi(k), st)
  Bool.pick(HS, EF.ehs_near(r), HS{hs_hs(st2), hs_g(st2), False{}, why_near()}, st2)

def ef_faces(fs: List<&2, Nat>, +side: U64, +e: Nat, +b: Ty.Brep, +ob: Ty.Brep, +st: HS) -> HS:
  match fs:
    case []: st
    case +h <> +t: ef_faces(t, side, e, b, ob, ef_one(side, e, b, ob, h, st))

def ef_edges(es: List<&2, Nat>, +side: U64, +b: Ty.Brep, +ob: Ty.Brep, +st: HS) -> HS:
  match es:
    case []: st
    case +h <> +t:
      ef_edges(t, side, b, ob, ef_faces(L.nat_range(FB.nfaces(ob)), side, h, b, ob, st))

def all_hits(+ba: Ty.Brep, +bb: Ty.Brep, +g: GV) -> HS:
  +s0 = ef_edges(L.nat_range(FB.nedges(ba)), 0u64, ba, bb, HS{[], g, True{}, 0u64})
  ef_edges(L.nat_range(FB.nedges(bb)), 1u64, bb, ba, s0)

def seg_va(+s: SEG) -> Nat:
  SEG{va, vb, k} = s
  va

def seg_vb(+s: SEG) -> Nat:
  SEG{va, vb, k} = s
  vb

def seg_k(+s: SEG) -> Ty.EdgeKind:
  SEG{va, vb, k} = s
  k

def ch_fa(+c: CH) -> Nat:
  CH{fa, fb, segs, pts, closed, dv} = c
  fa

def ch_fb(+c: CH) -> Nat:
  CH{fa, fb, segs, pts, closed, dv} = c
  fb

def ch_segs(+c: CH) -> List<&2, SEG>:
  CH{fa, fb, segs, pts, closed, dv} = c
  segs

def ch_pts(+c: CH) -> List<&2, V.Point>:
  CH{fa, fb, segs, pts, closed, dv} = c
  pts

def ch_closed(+c: CH) -> Bool:
  CH{fa, fb, segs, pts, closed, dv} = c
  closed

def bp_s(+b: BP) -> F64:
  BP{s, v, p} = b
  s

def bp_v(+b: BP) -> Nat:
  BP{s, v, p} = b
  v

def bp_p(+b: BP) -> V.Point:
  BP{s, v, p} = b
  p

def bp_cmp_go(+a: BP, +b: BP) -> B.Sgn:
  Bool.pick(B.Sgn, F64.is_lt(bp_s(a), bp_s(b)), B.Sn{},
    Bool.pick(B.Sgn, F64.is_lt(bp_s(b), bp_s(a)), B.Sp{}, B.Sz{}))

def bp_cmp(a: BP, b: BP) -> B.Sgn:
  bp_cmp_go(a, b)

def so_bp(+s: B.So<&2, BP>) -> List<&2, BP>:
  B.So{ok, xs} = s
  xs

def bp_sort(+xs: List<&2, BP>) -> List<&2, BP>:
  so_bp(B.msort(~BP, ~bp_cmp, xs))

def ln_kind(+a: V.Point, +b: V.Point) -> Ty.EdgeKind:
  +d = S.psub(b, a)
  Bool.pick(Ty.EdgeKind, peq(S.padd(a, 1.0f64, d), b),
    Ty.EK_curve{G.GV_ln{G.Ln{a, d}}, G.Dom{0.0f64, 1.0f64}},
    Ty.EK_curve{G.GV_bz{G.Bz{a, S.padd(a, F64.div(1.0f64, 3.0f64), d), S.padd(a, F64.div(2.0f64, 3.0f64), d), b}},
      G.Dom{0.0f64, 1.0f64}})

def bz_kind(+a: V.Point, +b: V.Point) -> Ty.EdgeKind:
  +d = S.psub(b, a)
  Ty.EK_curve{G.GV_bz{G.Bz{a, S.padd(a, F64.div(1.0f64, 3.0f64), d), S.padd(a, F64.div(2.0f64, 3.0f64), d), b}},
    G.Dom{0.0f64, 1.0f64}}

def is_hit_of(+h: HX, +side: U64, +es: List<&2, Nat>, +fo: Nat) -> Bool:
  Bool.and(U64.is_eq(hx_side(h), side), Bool.and(L.mem_n(es, hx_e(h)), Nat.is_eq(hx_fo(h), fo)))

def ces_es(cs: List<&2, FB.CE>) -> List<&2, Nat>:
  match cs:
    case []: []
    case +h <> +t: FB.ce_e(h) <> ces_es(t)

def flat_ces(ls: List<&2, List<&2, FB.CE>>) -> List<&2, Nat>:
  match ls:
    case []: []
    case +h <> +t: List.append(&2, Nat, ces_es(h), flat_ces(t))

def face_es(+b: Ty.Brep, +fi: Nat) -> List<&2, Nat>:
  flat_ces(FB.face_ce(b, fi))

def pair_hits(hs: List<&2, HX>, +esa: List<&2, Nat>, +fa: Nat, +esb: List<&2, Nat>, +fb: Nat)
    -> List<&2, HX>:
  match hs:
    case []: []
    case +h <> +t:
      +rest = pair_hits(t, esa, fa, esb, fb)
      Bool.pick(List<&2, HX>, Bool.or(is_hit_of(h, 0u64, esa, fb), is_hit_of(h, 1u64, esb, fa)), h <> rest, rest)

def in_both(+ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep, +fb: Nat, +p: V.Point) -> Bool:
  Bool.and(Bool.and(FB.pt_in_face(ba, fa, p), FB.pt_in_face(bb, fb, p)),
    Bool.not(Bool.or(FB.bnd_near(ba, fa, p), FB.bnd_near(bb, fb, p))))

def line_s(+p0: V.Point, +d: V.Dir, +p: V.Point) -> F64:
  F64.div(S.dot(S.psub(p, p0), d), S.dot(d, d))

def on_line(+p0: V.Point, +d: V.Dir, +p: V.Point) -> Bool:
  +q = S.padd(p0, line_s(p0, d, p), d)
  F64.is_lt(S.dist(q, p), 1.0e-7f64)

def bps_line(hs: List<&2, HX>, +p0: V.Point, +d: V.Dir) -> List<&2, BP>:
  match hs:
    case []: []
    case +h <> +t:
      +rest = bps_line(t, p0, d)
      Bool.pick(List<&2, BP>, on_line(p0, d, hx_p(h)), BP{line_s(p0, d, hx_p(h)), hx_v(h), hx_p(h)} <> rest, rest)

def L_bp0(xs: List<&2, BP>, +d: BP) -> BP:
  match xs:
    case []: d
    case +h <> +t: h

def dedup_bp(xs: List<&2, BP>) -> List<&2, BP>:
  match xs:
    case []: []
    case +h <> +t:
      +h2 = L_bp0(t, h)
      +dup = Bool.and(Bool.not(Nat.is_eq(List.length(&2, BP, t), 0n)), Nat.is_eq(bp_v(h), bp_v(h2)))
      +rest = dedup_bp(t)
      Bool.pick(List<&2, BP>, dup, rest, h <> rest)

def cr_chs(+r: CR) -> List<&2, CH>:
  CR{chs, g, ok, why} = r
  chs

def cr_g(+r: CR) -> GV:
  CR{chs, g, ok, why} = r
  g

def cr_ok(+r: CR) -> Bool:
  CR{chs, g, ok, why} = r
  ok

def cr_why(+r: CR) -> U64:
  CR{chs, g, ok, why} = r
  why

def cr_fail(+r: CR, +why: U64) -> CR:
  Bool.pick(CR, cr_ok(r), CR{cr_chs(r), cr_g(r), False{}, why}, r)

def mk_lnch(+fa: Nat, +fb: Nat, +h: BP, +h2: BP) -> CH:
  CH{fa, fb, [SEG{bp_v(h), bp_v(h2), ln_kind(bp_p(h), bp_p(h2))}], [bp_p(h), bp_p(h2)], False{}, 0.0f64}

def line_spans(bs: List<&2, BP>, +p0: V.Point, +d: V.Dir, +ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep,
    +fb: Nat, +r: CR) -> CR:
  match bs:
    case []: r
    case +h <> +t:
      +h2 = L_bp0(t, h)
      +more = Bool.not(Nat.is_eq(List.length(&2, BP, t), 0n))
      +mid = S.padd(p0, F64.mul(0.5f64, F64.add(bp_s(h), bp_s(h2))), d)
      +keep = Bool.and(more, in_both(ba, fa, bb, fb, mid))
      line_spans(t, p0, d, ba, fa, bb, fb,
        Bool.pick(CR, keep, CR{mk_lnch(fa, fb, h, h2) <> cr_chs(r), cr_g(r), cr_ok(r), cr_why(r)}, r))

def do_line(+c: SS.IC, +hs: List<&2, HX>, +ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep, +fb: Nat, +r: CR) -> CR:
  +ln = SS.ln_of(SS.ic_curve(c))
  +p0 = G.ln_p(ln)
  +d = G.ln_d(ln)
  line_spans(dedup_bp(bp_sort(bps_line(hs, p0, d))), p0, d, ba, fa, bb, fb, r)

def circ_phi(+cc: G.Circle3, +p: V.Point) -> F64:
  +q = S.psub(p, G.cc_c(cc))
  S.fatan2(S.dot(q, G.cc_v(cc)), S.dot(q, G.cc_u(cc)))

def circ_at(+cc: G.Circle3, +phi: F64) -> V.Point:
  S.padd(S.padd(G.cc_c(cc), F64.mul(G.cc_r(cc), S.fcos(phi)), G.cc_u(cc)),
    F64.mul(G.cc_r(cc), S.fsin(phi)), G.cc_v(cc))

def on_circ(+cc: G.Circle3, +p: V.Point) -> Bool:
  F64.is_lt(FB.circ_dist(G.cc_c(cc), S.dunit(S.cross(G.cc_u(cc), G.cc_v(cc))), G.cc_r(cc), p), 1.0e-7f64)

def bps_circ(hs: List<&2, HX>, +cc: G.Circle3) -> List<&2, BP>:
  match hs:
    case []: []
    case +h <> +t:
      +rest = bps_circ(t, cc)
      Bool.pick(List<&2, BP>, on_circ(cc, hx_p(h)), BP{circ_phi(cc, hx_p(h)), hx_v(h), hx_p(h)} <> rest, rest)

def rq_arc(+cc: G.Circle3, +pa: V.Point, +pb: V.Point, +phia: F64, +phib: F64) -> Ty.EdgeKind:
  +h = F64.mul(0.5f64, F64.sub(phib, phia))
  +w = S.fcos(h)
  +pm = circ_at(cc, F64.mul(0.5f64, F64.add(phia, phib)))
  +c = S.padd(G.cc_c(cc), F64.div(G.cc_r(cc), w), S.dunit(S.psub(pm, G.cc_c(cc))))
  Ty.EK_curve{G.GV_rq{G.Rq{pa, c, pb, 1.0f64, w, 1.0f64}}, G.Dom{0.0f64, 1.0f64}}

def L_last_seg(xs: List<&2, SEG>) -> SEG:
  match xs:
    case []: SEG{0n, 0n, Ty.EK_degenerate{}}
    case +h <> +t: h

def nth_g(xs: List<&2, G.GVal>, +i: Nat) -> G.GVal:
  match xs:
    case []: G.GV_f{0.0f64}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_g(t, j)

def cc1(xs: List<&2, G.Circle3>) -> G.Circle3:
  match xs:
    case []: G.Cc{S.pt(0.0f64, 0.0f64, 0.0f64), S.dr(1.0f64, 0.0f64, 0.0f64), S.dr(0.0f64, 1.0f64, 0.0f64), 1.0f64}
    case +h <> +t: h

def arc_go(n: Nat, +ccl: List<&2, G.Circle3>, +gs: List<&2, G.GVal>, +pa: V.Point, +va: Nat, +phia: F64,
    +step: F64, +k: F64, +pb: V.Point, +vb: Nat, +g: GV, +segs: List<&2, SEG>,
    +pts: List<&2, V.Point>, +ok: Bool) -> CR:
  match n:
    case 0n: CR{[CH{0n, 0n, List.reverse(&2, SEG, segs), List.reverse(&2, V.Point, pts), False{}, 0.0f64}], g, ok, 0u64}
    case 1n+(+m):
      +phi = F64.add(phia, F64.mul(k, step))
      +last = Nat.is_eq(m, 0n)
      +ct = SS.cert_pt(nth_g(gs, 0n), nth_g(gs, 1n), circ_at(cc1(ccl), phi))
      +q = Bool.pick(V.Point, last, pb, EF.ct_p(ct))
      +r = gv_add(g, q)
      +vq = Bool.pick(Nat, last, vb, vi_i(r))
      +prevphi = F64.add(phia, F64.mul(F64.sub(k, 1.0f64), step))
      +prevp = L.last_p(List.reverse(&2, V.Point, pts), pa)
      +prevv = Bool.pick(Nat, Nat.is_eq(List.length(&2, SEG, segs), 0n), va, seg_vb(L_last_seg(segs)))
      arc_go(m, ccl, gs, pa, va, phia, step, F64.add(k, 1.0f64), pb, vb,
        Bool.pick(GV, last, g, vi_g(r)),
        SEG{prevv, vq, rq_arc(cc1(ccl), prevp, q, prevphi, phi)} <> segs, q <> pts,
        Bool.and(ok, Bool.or(last, EF.ct_ok(ct))))

def arc_n(+span: F64) -> Nat:
  Bool.pick(Nat, F64.is_le(span, 1.6f64), 1n,
    Bool.pick(Nat, F64.is_le(span, 3.2f64), 2n, Bool.pick(Nat, F64.is_le(span, 4.8f64), 3n, 4n)))

def L_ch0(xs: List<&2, CH>) -> CH:
  match xs:
    case []: CH{0n, 0n, [], [], False{}, 0.0f64}
    case +h <> +t: h

def arc_chain(+ccl: List<&2, G.Circle3>, +gs: List<&2, G.GVal>, +a: BP, +phib: F64, +b: BP, +g: GV,
    +fa: Nat, +fb: Nat) -> CR:
  +span = F64.sub(phib, bp_s(a))
  +n = arc_n(span)
  +r = arc_go(n, ccl, gs, bp_p(a), bp_v(a), bp_s(a), F64.div(span, L.f64_of(n)), 1.0f64,
    bp_p(b), bp_v(b), g, [], [bp_p(a)], True{})
  +c0 = L_ch0(cr_chs(r))
  CR{[CH{fa, fb, ch_segs(c0), ch_pts(c0), False{}, 0.0f64}], cr_g(r), cr_ok(r), Bool.pick(U64, cr_ok(r), 0u64, why_hcert())}

def circ_spans(bs: List<&2, BP>, +first: BP, +ccl: List<&2, G.Circle3>, +gs: List<&2, G.GVal>,
    +ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep, +fb: Nat, +r: CR) -> CR:
  match bs:
    case []: r
    case +h <> +t:
      +nx = L_bp0(t, first)
      +phib = Bool.pick(F64, Nat.is_eq(List.length(&2, BP, t), 0n), F64.add(bp_s(first), S.two_pi()), bp_s(nx))
      +mid = circ_at(cc1(ccl), F64.mul(0.5f64, F64.add(bp_s(h), phib)))
      +keep = in_both(ba, fa, bb, fb, mid)
      +ar = arc_chain(ccl, gs, h, phib, nx, cr_g(r), fa, fb)
      +r2 = Bool.pick(CR, keep,
        CR{List.append(&2, CH, cr_chs(ar), cr_chs(r)), cr_g(ar), Bool.and(cr_ok(r), cr_ok(ar)),
          Bool.pick(U64, cr_ok(r), cr_why(ar), cr_why(r))}, r)
      circ_spans(t, first, ccl, gs, ba, fa, bb, fb, r2)

def mk_fullch(+fa: Nat, +fb: Nat, +v: Nat, +c: G.GVal, +p: V.Point) -> CH:
  CH{fa, fb, [SEG{v, v, Ty.EK_curve{c, G.Dom{F64.neg(1.0f64), 1.0f64}}}], [p, p], True{}, 0.0f64}

def do_circ_full(+cc: G.Circle3, +ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep, +fb: Nat, +r: CR) -> CR:
  +p = EF.ev(G.GV_cc{cc}, F64.neg(1.0f64))
  +vr = gv_add(cr_g(r), p)
  +keep = in_both(ba, fa, bb, fb, EF.ev(G.GV_cc{cc}, 0.0f64))
  Bool.pick(CR, keep, CR{mk_fullch(fa, fb, vi_i(vr), G.GV_cc{cc}, p) <> cr_chs(r), vi_g(vr), cr_ok(r), cr_why(r)}, r)

def do_circ_go(+full: Bool, +ccl: List<&2, G.Circle3>, +gs: List<&2, G.GVal>, +bs: List<&2, BP>,
    +ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep, +fb: Nat, +r: CR) -> CR:
  match full:
    case True{}: do_circ_full(cc1(ccl), ba, fa, bb, fb, r)
    case False{}: circ_spans(bs, L_bp0(bs, BP{0.0f64, 0n, S.pt(0.0f64, 0.0f64, 0.0f64)}), ccl, gs, ba, fa, bb, fb, r)

def cc_of(+g: G.GVal) -> G.Circle3:
  match g:
    case G.GV_cc{w}: w
    case _: G.Cc{S.pt(0.0f64, 0.0f64, 0.0f64), S.dr(1.0f64, 0.0f64, 0.0f64), S.dr(0.0f64, 1.0f64, 0.0f64), 1.0f64}

def do_circ(+c: SS.IC, +hs: List<&2, HX>, +g1: G.GVal, +g2: G.GVal, +ba: Ty.Brep, +fa: Nat,
    +bb: Ty.Brep, +fb: Nat, +r: CR) -> CR:
  +ccl = {[cc_of(SS.ic_curve(c))] : List<&2, G.Circle3>}
  +bs = dedup_bp(bp_sort(bps_circ(hs, cc1(ccl))))
  do_circ_go(Nat.is_eq(List.length(&2, BP, bs), 0n), ccl, [g1, g2], bs, ba, fa, bb, fb, r)

def near_seg(ps: List<&2, V.Point>, +p: V.Point, +prev: V.Point, +i: Nat, +best: Nat, +bd: F64) -> Nat:
  match ps:
    case []: best
    case +h <> +t:
      +d = F64.add(S.dist(prev, p), S.dist(p, h))
      +sl = S.dist(prev, h)
      +ex = F64.sub(d, sl)
      near_seg(t, p, h, Nat.add(i, 1n), Bool.pick(Nat, F64.is_lt(ex, bd), i, best), F64.min(ex, bd))

def pp_p(+q: PP) -> V.Point:
  PP{p, v, brk} = q
  p

def pp_v(+q: PP) -> Nat:
  PP{p, v, brk} = q
  v

def pp_brk(+q: PP) -> Bool:
  PP{p, v, brk} = q
  brk

def ins_at(xs: List<&2, PP>, +i: Nat, +x: PP) -> List<&2, PP>:
  match xs:
    case []: [x]
    case +h <> +t:
      match i:
        case 0n: h <> (x <> t)
        case 1n+j: h <> ins_at(t, j, x)

def pps_pts(xs: List<&2, PP>) -> List<&2, V.Point>:
  match xs:
    case []: []
    case +h <> +t: pp_p(h) <> pps_pts(t)

def L_tail(xs: List<&2, V.Point>) -> List<&2, V.Point>:
  match xs:
    case []: []
    case +h <> +t: t

def near_ex(ps: List<&2, V.Point>, +p: V.Point, +prev: V.Point, +bd: F64) -> F64:
  match ps:
    case []: bd
    case +h <> +t:
      +ex = F64.sub(F64.add(S.dist(prev, p), S.dist(p, h)), S.dist(prev, h))
      near_ex(t, p, h, F64.min(ex, bd))

def near_pt(ps: List<&2, PP>, +p: V.Point, +i: Nat, +best: Nat, +bd: F64) -> NB2:
  match ps:
    case []: NB2{best, bd}
    case +h <> +t:
      +d = S.dist(pp_p(h), p)
      near_pt(t, p, Nat.add(i, 1n), Bool.pick(Nat, F64.is_lt(d, bd), i, best), F64.min(d, bd))

def nb2_i(+x: NB2) -> Nat:
  NB2{i, d} = x
  i

def nb2_d(+x: NB2) -> F64:
  NB2{i, d} = x
  d

def set_at(xs: List<&2, PP>, +i: Nat, +x: PP) -> List<&2, PP>:
  match xs:
    case []: []
    case +h <> +t:
      match i:
        case 0n: x <> t
        case 1n+j: h <> set_at(t, j, x)

def ins_brk(hs: List<&2, HX>, +xs: List<&2, PP>) -> List<&2, PP>:
  match hs:
    case []: xs
    case +h <> +t:
      +ps = pps_pts(xs)
      +cl = List.append(&2, V.Point, L_tail(ps), [L.nth_p(ps, 0n)])
      +i = near_seg(cl, hx_p(h), L.nth_p(ps, 0n), 0n, 0n, F64.div(1.0f64, 0.0f64))
      +ex = near_ex(cl, hx_p(h), L.nth_p(ps, 0n), F64.div(1.0f64, 0.0f64))
      +np = near_pt(xs, hx_p(h), 0n, 0n, F64.div(1.0f64, 0.0f64))
      +on = F64.is_lt(ex, 1.0e-6f64)
      +same = F64.is_lt(nb2_d(np), 1.0e-9f64)
      +bp = {PP{hx_p(h), hx_v(h), True{}} : PP}
      ins_brk(t, Bool.pick(List<&2, PP>, same, set_at(xs, nb2_i(np), bp),
        Bool.pick(List<&2, PP>, on, ins_at(xs, i, bp), xs)))

def pv_xs(+r: PV) -> List<&2, PP>:
  PV{xs, g} = r
  xs

def pv_g(+r: PV) -> GV:
  PV{xs, g} = r
  g

def reg_pts(ps: List<&2, V.Point>, +g: GV, +acc: List<&2, PP>) -> PV:
  match ps:
    case []: PV{List.reverse(&2, PP, acc), g}
    case +h <> +t:
      +r = gv_add(g, h)
      reg_pts(t, vi_g(r), PP{h, vi_i(r), False{}} <> acc)

def rot_to_brk(xs: List<&2, PP>, +pre: List<&2, PP>) -> List<&2, PP>:
  match xs:
    case []: List.reverse(&2, PP, pre)
    case +h <> +t:
      Bool.pick(List<&2, PP>, pp_brk(h), List.append(&2, PP, h <> t, List.reverse(&2, PP, pre)),
        rot_to_brk(t, h <> pre))

def L_pp0(xs: List<&2, PP>) -> PP:
  match xs:
    case []: PP{S.pt(0.0f64, 0.0f64, 0.0f64), 0n, False{}}
    case +h <> +t: h

def tan_at(+s1: S.SF, +s2: S.SF, +p: V.Point, +ch: V.Dir) -> V.Dir:
  +c = S.cross(S.sf_grad(s1, p), S.sf_grad(s2, p))
  +l = S.dlen(c)
  +g = F64.mul(S.dlen(S.sf_grad(s1, p)), S.dlen(S.sf_grad(s2, p)))
  +ok = F64.is_lt(F64.mul(1.0e-6f64, g), l)
  +t = S.dscale(F64.div(1.0f64, l), c)
  +t2 = Bool.pick(V.Dir, F64.is_lt(S.dot(t, ch), 0.0f64), S.dscale(F64.neg(1.0f64), t), t)
  Bool.pick(V.Dir, ok, t2, S.dunit(ch))

def herm_kind(+s1: S.SF, +s2: S.SF, +a: V.Point, +b: V.Point) -> Ty.EdgeKind:
  +ch = S.psub(b, a)
  +l = S.dlen(ch)
  +ta = tan_at(s1, s2, a, ch)
  +tb = tan_at(s1, s2, b, ch)
  Ty.EK_curve{G.GV_bz{G.Bz{a, S.padd(a, F64.div(l, 3.0f64), ta), S.padd(b, F64.neg(F64.div(l, 3.0f64)), tb), b}},
    G.Dom{0.0f64, 1.0f64}}

def segs_of(xs: List<&2, PP>, +s1: S.SF, +s2: S.SF) -> List<&2, SEG>:
  match xs:
    case []: []
    case +h <> +t:
      +h2 = L_pp0(t)
      +rest = segs_of(t, s1, s2)
      Bool.pick(List<&2, SEG>, Nat.is_eq(List.length(&2, PP, t), 0n), [],
        SEG{pp_v(h), pp_v(h2), bz_kind(pp_p(h), pp_p(h2))} <> rest)

def mid_pp(+xs: List<&2, PP>) -> V.Point:
  +ps = pps_pts(xs)
  +n = List.length(&2, V.Point, ps)
  Bool.pick(V.Point, Nat.is_le(n, 2n),
    S.padd(L.nth_p(ps, 0n), 0.5f64, S.psub(L.nth_p(ps, 1n), L.nth_p(ps, 0n))), L.nth_p(ps, Nat.div(n, 2n)))

def poly_split(xs: List<&2, PP>, +cur: List<&2, PP>, +acc: List<&2, List<&2, PP>>)
    -> List<&2, List<&2, PP>>:
  match xs:
    case []: List.reverse(&2, List<&2, PP>, acc)
    case +h <> +t:
      +cut = Bool.and(pp_brk(h), Nat.is_lt(1n, List.length(&2, PP, cur)))
      poly_split(t, Bool.pick(List<&2, PP>, cut, [h], h <> cur),
        Bool.pick(List<&2, List<&2, PP>>, cut, List.reverse(&2, PP, h <> cur) <> acc, acc))

def bz_at(+k: Ty.EdgeKind, +t: F64) -> V.Point:
  EF.ev(EF.ek_curve(k), t)

def seg_dev(+s1: S.SF, +s2: S.SF, +k: Ty.EdgeKind) -> F64:
  +a = bz_at(k, 0.0f64)
  +b = bz_at(k, 1.0f64)
  +t = S.dunit(S.psub(b, a))
  +m1 = bz_at(k, 0.25f64)
  +m2 = bz_at(k, 0.5f64)
  +m3 = bz_at(k, 0.75f64)
  F64.max(S.dist(m1, S.newton2(8n, s1, s2, m1, t, m1)),
    F64.max(S.dist(m2, S.newton2(8n, s1, s2, m2, t, m2)), S.dist(m3, S.newton2(8n, s1, s2, m3, t, m3))))

def segs_dev(ss: List<&2, SEG>, +s1: S.SF, +s2: S.SF, +best: F64) -> F64:
  match ss:
    case []: best
    case +h <> +t: segs_dev(t, s1, s2, F64.max(best, seg_dev(s1, s2, seg_k(h))))

def run_dev(+ss: List<&2, SEG>, +ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep, +fb: Nat) -> F64:
  +s1 = S.sf_of(FB.face_surf(ba, fa))
  +s2 = S.sf_of(FB.face_surf(bb, fb))
  F64.add(F64.mul(2.0f64, segs_dev(ss, s1, s2, 0.0f64)), 1.0e-12f64)

def mk_pch(+fa: Nat, +fb: Nat, +h: List<&2, PP>, +closed: Bool, +ba: Ty.Brep, +bb: Ty.Brep) -> CH:
  +s1 = S.sf_of(FB.face_surf(ba, fa))
  +s2 = S.sf_of(FB.face_surf(bb, fb))
  +ss = segs_of(h, s1, s2)
  CH{fa, fb, ss, pps_pts(h), closed, run_dev(ss, ba, fa, bb, fb)}

def keep_runs(rs: List<&2, List<&2, PP>>, +ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep, +fb: Nat,
    +acc: List<&2, CH>) -> List<&2, CH>:
  match rs:
    case []: acc
    case +h <> +t:
      +keep = in_both(ba, fa, bb, fb, mid_pp(h))
      keep_runs(t, ba, fa, bb, fb, Bool.pick(List<&2, CH>, keep, mk_pch(fa, fb, h, False{}, ba, bb) <> acc, acc))

def has_brk(xs: List<&2, PP>) -> Bool:
  match xs:
    case []: False{}
    case +h <> +t: Bool.or(pp_brk(h), has_brk(t))

def do_poly_go(+brk: Bool, +xs: List<&2, PP>, +ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep, +fb: Nat,
    +r: CR, +g: GV) -> CR:
  match brk:
    case True{}:
      +rot = rot_to_brk(xs, [])
      +cyc = List.append(&2, PP, rot, [L_pp0(rot)])
      CR{List.append(&2, CH, keep_runs(poly_split(cyc, [], []), ba, fa, bb, fb, []), cr_chs(r)), g,
        cr_ok(r), cr_why(r)}
    case False{}:
      +cyc = List.append(&2, PP, xs, [L_pp0(xs)])
      +keep = in_both(ba, fa, bb, fb, mid_pp(xs))
      Bool.pick(CR, keep, CR{mk_pch(fa, fb, cyc, True{}, ba, bb) <> cr_chs(r), g, cr_ok(r), cr_why(r)},
        CR{cr_chs(r), g, cr_ok(r), cr_why(r)})

def do_poly(+c: SS.IC, +hs: List<&2, HX>, +ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep, +fb: Nat, +r: CR) -> CR:
  +pv = reg_pts(SS.ic_pts(c), cr_g(r), [])
  +xs = ins_brk(hs, pv_xs(pv))
  do_poly_go(has_brk(xs), xs, ba, fa, bb, fb, r, pv_g(pv))

def do_ic(+k: U64, +c: SS.IC, +hs: List<&2, HX>, +g1: G.GVal, +g2: G.GVal, +ba: Ty.Brep, +fa: Nat,
    +bb: Ty.Brep, +fb: Nat, +r: CR) -> CR:
  match k:
    case 1u64: do_line(c, hs, ba, fa, bb, fb, r)
    case 2u64: do_circ(c, hs, g1, g2, ba, fa, bb, fb, r)
    case 3u64: do_poly(c, hs, ba, fa, bb, fb, r)
    case 4u64: r
    case 6u64: r
    case _: cr_fail(r, 86u64)

def ics_go(cs: List<&2, SS.IC>, +hs: List<&2, HX>, +g1: G.GVal, +g2: G.GVal, +ba: Ty.Brep,
    +fa: Nat, +bb: Ty.Brep, +fb: Nat, +r: CR) -> CR:
  match cs:
    case []: r
    case +h <> +t: ics_go(t, hs, g1, g2, ba, fa, bb, fb, do_ic(SS.ic_kind(h), h, hs, g1, g2, ba, fa, bb, fb, r))

def brk_pts(ps: List<&2, V.Point>, +g: GV, +acc: List<&2, HX>) -> HXG:
  match ps:
    case []: HXG{acc, g}
    case +h <> +t:
      +r = gv_add(g, h)
      brk_pts(t, vi_g(r), HX{2u64, 0n, 0.0f64, h, vi_i(r), 0n} <> acc)

def hxg_hs(+x: HXG) -> List<&2, HX>:
  HXG{hs, g} = x
  hs

def hxg_g(+x: HXG) -> GV:
  HXG{hs, g} = x
  g

def brk_hx(cs: List<&2, SS.IC>, +g: GV, +acc: List<&2, HX>) -> HXG:
  match cs:
    case []: HXG{acc, g}
    case +h <> +t:
      +r = brk_pts(Bool.pick(List<&2, V.Point>, U64.is_eq(SS.ic_kind(h), 6u64), SS.ic_pts(h), []), g, acc)
      brk_hx(t, hxg_g(r), hxg_hs(r))

def pair_go(+hs: List<&2, HX>, +ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep, +fb: Nat, +r: CR) -> CR:
  +g1 = FB.face_surf(ba, fa)
  +g2 = FB.face_surf(bb, fb)
  +x = SS.ssi(g1, g2)
  +ph = pair_hits(hs, face_es(ba, fa), fa, face_es(bb, fb), fb)
  +bk = brk_hx(SS.ics_ics(x), cr_g(r), ph)
  +r2 = ics_go(SS.ics_ics(x), hxg_hs(bk), g1, g2, ba, fa, bb, fb, CR{cr_chs(r), hxg_g(bk), cr_ok(r), cr_why(r)})
  Bool.pick(CR, U64.is_eq(SS.ics_why(x), 0u64), r2, cr_fail(r2, SS.ics_why(x)))

def pairs_b(fbs: List<&2, Nat>, +hs: List<&2, HX>, +ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep, +r: CR) -> CR:
  match fbs:
    case []: r
    case +h <> +t: pairs_b(t, hs, ba, fa, bb, pair_go(hs, ba, fa, bb, h, r))

def pairs_a(fas: List<&2, Nat>, +hs: List<&2, HX>, +ba: Ty.Brep, +bb: Ty.Brep, +r: CR) -> CR:
  match fas:
    case []: r
    case +h <> +t: pairs_a(t, hs, ba, bb, pairs_b(L.nat_range(FB.nfaces(bb)), hs, ba, h, bb, r))

def all_chains(+hs: List<&2, HX>, +ba: Ty.Brep, +bb: Ty.Brep, +g: GV) -> CR:
  pairs_a(L.nat_range(FB.nfaces(ba)), hs, ba, bb, CR{[], g, True{}, 0u64})

def L_pp0_p(xs: List<&2, V.Point>) -> V.Point:
  match xs:
    case []: S.pt(0.0f64, 0.0f64, 0.0f64)
    case +h <> +t: h

def ch_dv(+c: CH) -> F64:
  CH{fa, fb, segs, pts, closed, dv} = c
  dv
