import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../c04/types.bend as Ty
import ../c06/iv.bend as I
import ../base/par.bend as B
import ../c07/ivx.bend as X
import ../c07/sol.bend as SO
import ../c07/im.bend as MM
import ../c07/xs.bend as S
import ./core.bend as KC
import ./ring.bend as RX

def axdir(+d: V.Dir) -> U64:
  +x = V.dr_x(d)
  +y = V.dr_y(d)
  +z = V.dr_z(d)
  Bool.pick(U64, Bool.and(F64.is_eq(x, 1.0f64), Bool.and(F64.is_eq(y, 0.0f64), F64.is_eq(z, 0.0f64))), 0u64,
    Bool.pick(U64, Bool.and(F64.is_eq(x, 0.0f64), Bool.and(F64.is_eq(y, 1.0f64), F64.is_eq(z, 0.0f64))), 1u64,
      Bool.pick(U64, Bool.and(F64.is_eq(x, 0.0f64), Bool.and(F64.is_eq(y, 0.0f64), F64.is_eq(z, 1.0f64))), 2u64,
        Bool.pick(U64, Bool.and(F64.is_eq(x, F64.neg(1.0f64)), Bool.and(F64.is_eq(y, 0.0f64), F64.is_eq(z, 0.0f64))), 3u64,
          Bool.pick(U64, Bool.and(F64.is_eq(x, 0.0f64), Bool.and(F64.is_eq(y, F64.neg(1.0f64)), F64.is_eq(z, 0.0f64))), 4u64,
            Bool.pick(U64, Bool.and(F64.is_eq(x, 0.0f64), Bool.and(F64.is_eq(y, 0.0f64), F64.is_eq(z, F64.neg(1.0f64)))), 5u64, 6u64))))))

def ax_of(+a: U64) -> U64:
  Bool.pick(U64, U64.is_le(a, 2u64), a, U64.sub(a, 3u64))

def is_ax(+d: V.Dir) -> Bool:
  U64.is_le(axdir(d), 5u64)

def crx(+u: V.Dir, +v: V.Dir) -> V.Dir:
  V.Dr{F64.sub(F64.mul(V.dr_y(u), V.dr_z(v)), F64.mul(V.dr_z(u), V.dr_y(v))),
    F64.sub(F64.mul(V.dr_z(u), V.dr_x(v)), F64.mul(V.dr_x(u), V.dr_z(v))),
    F64.sub(F64.mul(V.dr_x(u), V.dr_y(v)), F64.mul(V.dr_y(u), V.dr_x(v)))}

def planesk(+w: G.Plane3) -> U64:
  +n = crx(G.pl_u(w), G.pl_v(w))
  +a = axdir(n)
  Bool.pick(U64, U64.is_eq(a, 6u64), KC.sk_pgen(), U64.add(ax_of(a), 1u64))

def cylsk(+w: G.Cyl) -> U64:
  +a = axdir(G.cy_a(w))
  Bool.pick(U64, U64.is_eq(a, 6u64), KC.sk_cgen(), U64.add(ax_of(a), 4u64))

def surfkind(+s: G.GVal) -> U64:
  match s:
    case G.GV_pl{w}: planesk(w)
    case G.GV_cy{w}: cylsk(w)
    case G.GV_sp{w}: KC.sk_sphere()
    case G.GV_co{w}: KC.sk_cone()
    case G.GV_to{w}: KC.sk_torus()
    case _: KC.sk_other()

def plancon(+w: G.Plane3, +ax: U64) -> F64:
  +o = G.pl_o(w)
  Bool.pick(F64, U64.is_eq(ax, 0u64), V.pt_x(o),
    Bool.pick(F64, U64.is_eq(ax, 1u64), V.pt_y(o), V.pt_z(o)))

def cylcen(+w: G.Cyl, +ax: U64) -> V.Vec2:
  +o = G.cy_o(w)
  Bool.pick(V.Vec2, U64.is_eq(ax, 0u64), V.V2{V.pt_y(o), V.pt_z(o)},
    Bool.pick(V.Vec2, U64.is_eq(ax, 1u64), V.V2{V.pt_x(o), V.pt_z(o)}, V.V2{V.pt_x(o), V.pt_y(o)}))

def im_straddle(m: Maybe<&2, MM.Im>, +bx: List<&2, I.I>) -> Bool:
  match m:
    case None{}: True{}
    case Some{+im}:
      +v = MM.im_val(im, bx)
      Bool.and(F64.is_le(I.i_lo(v), 0.0f64), F64.is_le(0.0f64, I.i_hi(v)))

def unbox_gv(+b: List<&2, G.GVal>) -> G.GVal:
  match b:
    case s <> _: s
    case []: G.GV_f{0.0f64}

def box_gv(+g: G.GVal) -> List<&2, G.GVal>:
  [g]

def pair_straddle_ib(+ia: Maybe<&2, MM.Im>, +ba: List<&2, I.I>, +sb: List<&2, G.GVal>, +bb: List<&2, I.I>) -> Bool:
  +ib = S.gv_im(unbox_gv(sb))
  Bool.or(im_straddle(ib, ba), im_straddle(ia, bb))

def pair_straddle(+sa: List<&2, G.GVal>, +ba: List<&2, I.I>, +sb: List<&2, G.GVal>, +bb: List<&2, I.I>) -> Bool:
  pair_straddle_ib(S.gv_im(unbox_gv(sa)), ba, sb, bb)

type KF is Data:
  KF{ fi: Nat, sk: U64, ax: U64, surf: List<&2, G.GVal> }

def nth_fa0(xs: List<&2, Ty.Face>, +i: Nat) -> Ty.Face:
  match xs:
    case []: Ty.fa_dflt()
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_fa0(t, j)

def nth_ce0(xs: List<&2, Ty.Coedge>, +i: Nat) -> Ty.Coedge:
  match xs:
    case []: Ty.ce_dflt()
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_ce0(t, j)

def nth_ed0(xs: List<&2, Ty.Edge>, +i: Nat) -> Ty.Edge:
  match xs:
    case []: Ty.ed_dflt()
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_ed0(t, j)

def nth_lp0(xs: List<&2, Ty.Loop>, +i: Nat) -> Ty.Loop:
  match xs:
    case []: Ty.lp_dflt()
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_lp0(t, j)

def nth_vx0(xs: List<&2, Ty.Vertex>, +i: Nat) -> Ty.Vertex:
  match xs:
    case []: Ty.vx_dflt()
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_vx0(t, j)

def kf_of(+b: Ty.Brep, +fi: Nat) -> KF:
  +fs = Ty.brep_fas(b)
  +f = nth_fa0(fs, fi)
  +s = Ty.fa_surf(f)
  +k = surfkind(s)
  KF{fi, k, KC.sk_axis(k), [s]}

def fd_at(fs: List<&2, SO.Fd>, +fi: Nat) -> SO.Fd:
  match fs:
    case []: SO.fd_dflt()
    case +h <> t: Bool.pick(SO.Fd, Nat.is_eq(SO.fd_fi(h), fi), h, fd_at(t, fi))

def kf_list_go(+b: Ty.Brep, +n: Nat, +at: Nat) -> List<&2, KF>:
  match n:
    case 0n: []
    case 1n+m: kf_of(b, at) <> kf_list_go(b, m, Nat.add(at, 1n))

def kf_list(+b: Ty.Brep) -> List<&2, KF>:
  kf_list_go(b, List.length(&2, Ty.Face, Ty.brep_fas(b)), 0n)

type KCv is Data:
  KCv{ kind: U64, lax: U64, lc0: F64, lc1: F64, ccs: List<&2, G.Circle3>, rxr: RX.RXR }

def kcv_norings() -> RX.RXR:
  RX.RXR{False{}, False{}, [], []}

def kcv_none() -> KCv:
  KCv{KC.ck_none(), 0u64, 0.0f64, 0.0f64, [], kcv_norings()}

def kcv_line(+ax: U64, +c0: F64, +c1: F64) -> KCv:
  KCv{KC.ck_line(), ax, c0, c1, [], kcv_norings()}

def kcv_circ(+cs: List<&2, G.Circle3>) -> KCv:
  KCv{KC.ck_circle(), 0u64, 0.0f64, 0.0f64, cs, kcv_norings()}

def kcv_ring(+r: RX.RXR) -> KCv:
  KCv{KC.ck_ring(), 0u64, 0.0f64, 0.0f64, [], r}

type KA is Data:
  KA{ fa: Nat, fb: Nat, ka: U64, kb: U64, rel: U64, perp: U64, dec: U64, cv: KCv }

def third_ax(+a: U64, +b: U64) -> U64:
  Bool.pick(U64, Bool.or(Bool.and(U64.is_eq(a, 0u64), U64.is_eq(b, 1u64)), Bool.and(U64.is_eq(a, 1u64), U64.is_eq(b, 0u64))), 2u64,
    Bool.pick(U64, Bool.or(Bool.and(U64.is_eq(a, 0u64), U64.is_eq(b, 2u64)), Bool.and(U64.is_eq(a, 2u64), U64.is_eq(b, 0u64))), 1u64, 0u64))

def lcoord(+axa: U64, +ca: F64, +axb: U64, +cb: F64, +want: U64) -> F64:
  Bool.pick(F64, U64.is_eq(want, axa), ca, cb)

def pp_pair(+fia: Nat, +ka: U64, +axa: U64, +pa: G.Plane3, +fib: Nat, +kb: U64, +axb: U64,
    +pb: G.Plane3) -> KA:
  +ca = plancon(pa, axa)
  +cb = plancon(pb, axb)
  +sameax = U64.is_eq(axa, axb)
  +samecon = Bool.and(sameax, F64.is_eq(ca, cb))
  +rel = Bool.pick(U64, samecon, KC.rel_coplanar(),
    Bool.pick(U64, sameax, KC.rel_parallel(), KC.rel_transverse()))
  +t = third_ax(axa, axb)
  +m = Bool.pick(U64, U64.is_eq(t, 0u64), 1u64, 0u64)
  +n = Bool.pick(U64, U64.is_eq(t, 0u64), 2u64, Bool.pick(U64, U64.is_eq(t, 1u64), 2u64, 1u64))
  +cv = Bool.pick(KCv, U64.is_eq(rel, KC.rel_transverse()),
    kcv_line(t, lcoord(axa, ca, axb, cb, m), lcoord(axa, ca, axb, cb, n)), kcv_none())
  KA{fia, fib, ka, kb, rel, KC.pp_perp(), KC.pk_dom(ka, kb, rel, KC.pp_perp()), cv}

def fabs(+x: F64) -> F64:
  Bool.pick(F64, F64.is_lt(x, 0.0f64), F64.neg(x), x)

def axframe(+ax: U64) -> G.Circle3:
  Bool.pick(G.Circle3, U64.is_eq(ax, 0u64),
    G.Cc{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 0.0f64},
    Bool.pick(G.Circle3, U64.is_eq(ax, 1u64),
      G.Cc{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 0.0f64},
      G.Cc{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}, 0.0f64}))

def circ_at(+fr: G.Circle3, +c: V.Point, +r: F64) -> G.Circle3:
  G.Cc{cc, u, v, rr} = fr
  G.Cc{c, u, v, r}

def cut_center(+ax: U64, +cen: V.Vec2, +c: F64) -> V.Point:
  Bool.pick(V.Point, U64.is_eq(ax, 0u64), V.Pt{c, V.v2_x(cen), V.v2_y(cen)},
    Bool.pick(V.Point, U64.is_eq(ax, 1u64), V.Pt{V.v2_x(cen), c, V.v2_y(cen)},
      V.Pt{V.v2_x(cen), V.v2_y(cen), c}))

def pc_perp(+pax: U64, +cax: U64) -> U64:
  Bool.pick(U64, U64.is_eq(pax, cax), KC.pp_perp(), KC.pp_parallel())

def iabs_lo(+a: I.I) -> F64:
  Bool.pick(F64, Bool.and(F64.is_le(I.i_lo(a), 0.0f64), F64.is_le(0.0f64, I.i_hi(a))), 0.0f64,
    F64.min(fabs(I.i_lo(a)), fabs(I.i_hi(a))))

def pc_pair(+fia: Nat, +ka: U64, +pax: U64, +pl: G.Plane3, +fib: Nat, +kb: U64, +cax: U64,
    +cy: G.Cyl) -> KA:
  +perp = pc_perp(pax, cax)
  +c = plancon(pl, pax)
  +cen = cylcen(cy, cax)
  +r = G.cy_r(cy)
  +o = G.cy_o(cy)
  +oc = Bool.pick(F64, U64.is_eq(pax, 0u64), V.pt_x(o),
    Bool.pick(F64, U64.is_eq(pax, 1u64), V.pt_y(o), V.pt_z(o)))
  +off = fabs(F64.sub(c, oc))
  +disj = F64.is_lt(r, iabs_lo(I.isub(I.ipt(c), I.ipt(oc))))
  +rel = Bool.pick(U64, U64.is_eq(perp, KC.pp_perp()), KC.rel_transverse(),
    Bool.pick(U64, disj, KC.rel_disjoint(),
      Bool.pick(U64, F64.is_eq(off, r), KC.rel_tangent(), KC.rel_transverse())))
  +cv = Bool.pick(KCv, Bool.and(U64.is_eq(rel, KC.rel_transverse()), U64.is_eq(perp, KC.pp_perp())),
    kcv_circ([circ_at(axframe(cax), cut_center(cax, cen, c), r)]), kcv_none())
  KA{fia, fib, ka, kb, rel, perp, KC.pk_dom(ka, kb, rel, perp), cv}

def zrange(+bx: List<&2, I.I>, +ax: U64) -> I.I:
  X.vn(bx, U64.to_nat(ax))

def interior_to(+z: F64, +r: I.I) -> Bool:
  Bool.and(F64.is_lt(I.i_lo(r), z), F64.is_lt(z, I.i_hi(r)))

def cc_pair(+fia: Nat, +ka: U64, +cax: U64, +ca: G.Cyl, +fib: Nat, +kb: U64, +cbx: U64,
    +cb: G.Cyl, +ba: List<&2, I.I>, +bb: List<&2, I.I>, +fulla: Bool, +fullb: Bool) -> KA:
  +sameax = U64.is_eq(cax, cbx)
  +cena = cylcen(ca, cax)
  +cenb = cylcen(cb, cbx)
  +ra = G.cy_r(ca)
  +rb = G.cy_r(cb)
  +dx = F64.sub(V.v2_x(cena), V.v2_x(cenb))
  +dy = F64.sub(V.v2_y(cena), V.v2_y(cenb))
  +d2 = F64.add(F64.mul(dx, dx), F64.mul(dy, dy))
  +d2i = I.iadd(I.isq(I.isub(I.ipt(V.v2_x(cena)), I.ipt(V.v2_x(cenb)))),
    I.isq(I.isub(I.ipt(V.v2_y(cena)), I.ipt(V.v2_y(cenb)))))
  +sp2i = I.isq(I.iadd(I.ipt(ra), I.ipt(rb)))
  +sm2i = I.isq(I.isub(I.ipt(ra), I.ipt(rb)))
  +sameln = Bool.and(sameax, Bool.and(F64.is_eq(dx, 0.0f64), F64.is_eq(dy, 0.0f64)))
  +samer = F64.is_eq(ra, rb)
  +zare = zrange(ba, cax)
  +zbre = zrange(bb, cbx)
  +zlo = F64.max(I.i_lo(zare), I.i_lo(zbre))
  +zhi = F64.min(I.i_hi(zare), I.i_hi(zbre))
  +zov = F64.is_le(zlo, zhi)
  +full = Bool.and(fulla, fullb)
  +pdisj = F64.is_lt(I.i_hi(sp2i), I.i_lo(d2i))
  +pnest = F64.is_lt(I.i_hi(d2i), I.i_lo(sm2i))
  +ptan = Bool.or(F64.is_eq(d2, F64.mul(F64.add(ra, rb), F64.add(ra, rb))),
    F64.is_eq(d2, F64.mul(F64.sub(ra, rb), F64.sub(ra, rb))))
  +rel = Bool.pick(U64, Bool.and(sameln, samer),
    Bool.pick(U64, Bool.and(zov, full), KC.rel_cylcoin(),
      Bool.pick(U64, zov, KC.rel_cylpar(), KC.rel_coaxial())),
    Bool.pick(U64, sameln, KC.rel_coaxial(),
      Bool.pick(U64, sameax,
        Bool.pick(U64, pdisj, KC.rel_disjoint(),
          Bool.pick(U64, pnest, KC.rel_coaxial(),
            Bool.pick(U64, ptan, KC.rel_tangent(), KC.rel_cylpar()))),
        KC.rel_transverse())))
  +isc = U64.is_eq(rel, KC.rel_cylcoin())
  +cut1 = Bool.and(isc, Bool.or(interior_to(zlo, zare), interior_to(zlo, zbre)))
  +cut2 = Bool.and(Bool.and(isc, Bool.not(F64.is_eq(zlo, zhi))),
    Bool.or(interior_to(zhi, zare), interior_to(zhi, zbre)))
  +c1 = circ_at(axframe(cax), cut_center(cax, cena, zlo), ra)
  +c2 = circ_at(axframe(cax), cut_center(cax, cena, zhi), ra)
  +ist = U64.is_eq(rel, KC.rel_transverse())
  +rxr = RX.rx_rings(RX.RC{cax, G.cy_o(ca), ra}, RX.RC{cbx, G.cy_o(cb), rb},
    third_ax(cax, cbx), [])
  +rok = Bool.and(RX.rxr_oka(rxr), RX.rxr_okb(rxr))
  +cv = Bool.pick(KCv, isc,
    kcv_circ(Bool.pick(List<&2, G.Circle3>, cut1, c1 <> Bool.pick(List<&2, G.Circle3>, cut2, [c2], []),
      Bool.pick(List<&2, G.Circle3>, cut2, [c2], []))),
    Bool.pick(KCv, ist, kcv_ring(rxr), kcv_none()))
  +dec0 = KC.pk_dom(ka, kb, rel, KC.pp_perp())
  +dec = Bool.pick(U64, Bool.and(ist, Bool.not(rok)),
    KC.dec_pack(False{}, False{}, KC.ck_none(), KC.kr_nonconic()), dec0)
  KA{fia, fib, ka, kb, rel, KC.pp_perp(), dec, cv}

def cone_perp0_u(+pl: G.Plane3, +pax: U64, +qb: G.GVal) -> U64:
  match qb:
    case G.GV_co{w}:
      +a = axdir(G.co_a(w))
      Bool.pick(U64, U64.is_eq(a, 6u64), KC.pp_angled(),
        Bool.pick(U64, U64.is_eq(ax_of(a), pax), KC.pp_perp(), KC.pp_parallel()))
    case _: KC.pp_angled()

def cone_perp0(+pl: G.Plane3, +pax: U64, +qb: List<&2, G.GVal>) -> U64:
  match qb:
    case q <> _: cone_perp0_u(pl, pax, q)
    case []: KC.pp_angled()

def sph_tangent0_u(+pl: G.Plane3, +pax: U64, +qb: G.GVal) -> Bool:
  match qb:
    case G.GV_sp{w}:
      +c = plancon(pl, pax)
      +o = G.sp_c(w)
      +oc = Bool.pick(F64, U64.is_eq(pax, 0u64), V.pt_x(o),
        Bool.pick(F64, U64.is_eq(pax, 1u64), V.pt_y(o), V.pt_z(o)))
      F64.is_eq(fabs(F64.sub(c, oc)), G.sp_r(w))
    case _: False{}

def sph_tangent0(+pl: G.Plane3, +pax: U64, +qb: List<&2, G.GVal>) -> Bool:
  match qb:
    case q <> _: sph_tangent0_u(pl, pax, q)
    case []: False{}

def pq_pair(+fia: Nat, +ka: U64, +pax: U64, +pl: G.Plane3, +fib: Nat, +kb: U64, +qb: List<&2, G.GVal>,
    +ba: List<&2, I.I>, +bb: List<&2, I.I>, +cone: Bool, +pfirst: Bool) -> KA:
  +perp = Bool.pick(U64, cone, cone_perp0(pl, pax, qb), KC.pp_perp())
  +spdisj = Bool.not(pair_straddle([G.GV_pl{pl}], ba, qb, bb))
  +rel = Bool.pick(U64, spdisj, KC.rel_disjoint(), KC.rel_transverse())
  +rel2 = Bool.pick(U64, Bool.and(Bool.not(cone), sph_tangent0(pl, pax, qb)), KC.rel_tangent(), rel)
  +dec = KC.pk_dom(ka, kb, rel2, perp)
  Bool.pick(KA, pfirst, KA{fia, fib, ka, kb, rel2, perp, dec, kcv_none()},
    KA{fib, fia, kb, ka, rel2, perp, KC.pk_dom(kb, ka, rel2, perp), kcv_none()})

def gen_pair(+fia: Nat, +ka: U64, +sa: List<&2, G.GVal>, +ba: List<&2, I.I>, +fib: Nat, +kb: U64,
    +sb: List<&2, G.GVal>, +bb: List<&2, I.I>) -> KA:
  +rel = Bool.pick(U64, pair_straddle(sa, ba, sb, bb), KC.rel_transverse(), KC.rel_disjoint())
  KA{fia, fib, ka, kb, rel, KC.pp_perp(), KC.pk_dom(ka, kb, rel, KC.pp_perp()), kcv_none()}

def kind_is_cc(+k: Ty.EdgeKind) -> Bool:
  match k:
    case Ty.EK_curve{G.GV_cc{w}, d}: True{}
    case _: False{}

def edge_closed_cc(+b: Ty.Brep, +h: Ty.HCoedge) -> Bool:
  +ces = Ty.brep_ces(b)
  +es = Ty.brep_es(b)
  +ce = nth_ce0(ces, Ty.hc_idx(h))
  +e = nth_ed0(es, Ty.he_idx(Ty.ce_edge(ce)))
  Bool.and(Ty.hv_eq(Ty.ed_v0(e), Ty.ed_v1(e)), kind_is_cc(Ty.ed_kind(e)))

def loop_full(+b: Ty.Brep, hs: List<&2, Ty.HCoedge>) -> Bool:
  match hs:
    case []: False{}
    case h <> t: Bool.or(edge_closed_cc(b, h), loop_full(b, t))

def loops_full(+b: Ty.Brep, hs: List<&2, Ty.HLoop>) -> Bool:
  match hs:
    case []: False{}
    case h <> t: Bool.or(loop_full(b, Ty.lp_ces(nth_lp0(Ty.brep_lps(b), Ty.hlp_idx(h)))), loops_full(b, t))

def face_full(+b: Ty.Brep, +fi: Nat) -> Bool:
  loops_full(b, Ty.fa_loops(nth_fa0(Ty.brep_fas(b), fi)))

def ka_fa(+k: KA) -> Nat:
  KA{fa, fb, ka, kb, rel, perp, dec, cv} = k
  fa

def ka_fb(+k: KA) -> Nat:
  KA{fa, fb, ka, kb, rel, perp, dec, cv} = k
  fb

def ka_dec(+k: KA) -> U64:
  KA{fa, fb, ka, kb, rel, perp, dec, cv} = k
  dec

def ka_rel(+k: KA) -> U64:
  KA{fa, fb, ka, kb, rel, perp, dec, cv} = k
  rel

def ka_cv(+k: KA) -> KCv:
  KA{fa, fb, ka, kb, rel, perp, dec, cv} = k
  cv

def ka_ka(+k: KA) -> U64:
  KA{fa, fb, ka, kb, rel, perp, dec, cv} = k
  ka

def ka_kb(+k: KA) -> U64:
  KA{fa, fb, ka, kb, rel, perp, dec, cv} = k
  kb

def kcv_kind(+c: KCv) -> U64:
  KCv{kind, lax, lc0, lc1, ccs, rxr} = c
  kind

def kcv_lax(+c: KCv) -> U64:
  KCv{kind, lax, lc0, lc1, ccs, rxr} = c
  lax

def kcv_lc0(+c: KCv) -> F64:
  KCv{kind, lax, lc0, lc1, ccs, rxr} = c
  lc0

def kcv_lc1(+c: KCv) -> F64:
  KCv{kind, lax, lc0, lc1, ccs, rxr} = c
  lc1

def kcv_ccs(+c: KCv) -> List<&2, G.Circle3>:
  KCv{kind, lax, lc0, lc1, ccs, rxr} = c
  ccs

def kcv_rings(+c: KCv, +side: U64) -> List<&2, RX.RING>:
  KCv{kind, lax, lc0, lc1, ccs, rxr} = c
  Bool.pick(List<&2, RX.RING>, U64.is_eq(side, 0u64), RX.rxr_ra(rxr), RX.rxr_rb(rxr))

def kcv_rok(+c: KCv, +side: U64) -> Bool:
  KCv{kind, lax, lc0, lc1, ccs, rxr} = c
  Bool.pick(Bool, U64.is_eq(side, 0u64), RX.rxr_oka(rxr), RX.rxr_okb(rxr))

def kcv_rallok(+c: KCv) -> Bool:
  KCv{kind, lax, lc0, lc1, ccs, rxr} = c
  Bool.and(RX.rxr_oka(rxr), RX.rxr_okb(rxr))

def kf_fi(+k: KF) -> Nat:
  KF{fi, sk, ax, surf} = k
  fi

def kf_sk(+k: KF) -> U64:
  KF{fi, sk, ax, surf} = k
  sk

def kf_ax(+k: KF) -> U64:
  KF{fi, sk, ax, surf} = k
  ax

def kf_surf(+k: KF) -> List<&2, G.GVal>:
  KF{fi, sk, ax, surf} = k
  surf

def nth_kf(xs: List<&2, KF>, +i: Nat) -> KF:
  match xs:
    case []: KF{0n, 0u64, 3u64, [G.GV_f{0.0f64}]}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_kf(t, j)

def kaswap(+k: KA) -> KA:
  KA{+fa, +fb, +ka, +kb, +rel, +perp, +dec, +cv} = k
  KA{fb, fa, kb, ka, rel, perp, KC.pk_dom(kb, ka, rel, perp), cv}

def ka_quiet(+fia: Nat, +ka: U64, +fib: Nat, +kb: U64) -> KA:
  KA{fia, fib, ka, kb, KC.rel_disjoint(), KC.pp_perp(), KC.dec_none(), kcv_none()}

def ana_pp_pb_u(+pa: G.Plane3, +sb: G.GVal, +fa: KF, +fb: KF) -> KA:
  match sb:
    case G.GV_pl{+pb}: pp_pair(kf_fi(fa), kf_sk(fa), kf_ax(fa), pa, kf_fi(fb), kf_sk(fb), kf_ax(fb), pb)
    case _: ka_quiet(kf_fi(fa), kf_sk(fa), kf_fi(fb), kf_sk(fb))

def ana_pp_pb(+pa: G.Plane3, +sb: List<&2, G.GVal>, +fa: KF, +fb: KF) -> KA:
  match sb:
    case s <> _: ana_pp_pb_u(pa, s, fa, fb)
    case []: ka_quiet(kf_fi(fa), kf_sk(fa), kf_fi(fb), kf_sk(fb))

def ana_pp_pa_u(+sa: G.GVal, +sb: List<&2, G.GVal>, +fa: KF, +fb: KF) -> KA:
  match sa:
    case G.GV_pl{+pa}: ana_pp_pb(pa, sb, fa, fb)
    case _: ka_quiet(kf_fi(fa), kf_sk(fa), kf_fi(fb), kf_sk(fb))

def ana_pp_pa(+sa: List<&2, G.GVal>, +sb: List<&2, G.GVal>, +fa: KF, +fb: KF) -> KA:
  match sa:
    case s <> _: ana_pp_pa_u(s, sb, fa, fb)
    case []: ka_quiet(kf_fi(fa), kf_sk(fa), kf_fi(fb), kf_sk(fb))

def ana_pp(+fa: KF, +fb: KF) -> KA:
  ana_pp_pa(kf_surf(fa), kf_surf(fb), fa, fb)

def ana_pc_fc_u(+pa: G.Plane3, +sc: G.GVal, +fp: KF, +fc: KF, +fa: KF, +fb: KF) -> KA:
  match sc:
    case G.GV_cy{+cy}: pc_pair(kf_fi(fp), kf_sk(fp), kf_ax(fp), pa, kf_fi(fc), kf_sk(fc), kf_ax(fc), cy)
    case _: ka_quiet(kf_fi(fa), kf_sk(fa), kf_fi(fb), kf_sk(fb))

def ana_pc_fc(+pa: G.Plane3, +sc: List<&2, G.GVal>, +fp: KF, +fc: KF, +fa: KF, +fb: KF) -> KA:
  match sc:
    case s <> _: ana_pc_fc_u(pa, s, fp, fc, fa, fb)
    case []: ka_quiet(kf_fi(fa), kf_sk(fa), kf_fi(fb), kf_sk(fb))

def ana_pc_fp_u(+sp: G.GVal, +sc: List<&2, G.GVal>, +fp: KF, +fc: KF, +fa: KF, +fb: KF) -> KA:
  match sp:
    case G.GV_pl{+pa}: ana_pc_fc(pa, sc, fp, fc, fa, fb)
    case _: ka_quiet(kf_fi(fa), kf_sk(fa), kf_fi(fb), kf_sk(fb))

def ana_pc_fp(+sp: List<&2, G.GVal>, +sc: List<&2, G.GVal>, +fp: KF, +fc: KF, +fa: KF, +fb: KF) -> KA:
  match sp:
    case s <> _: ana_pc_fp_u(s, sc, fp, fc, fa, fb)
    case []: ka_quiet(kf_fi(fa), kf_sk(fa), kf_fi(fb), kf_sk(fb))

def ana_pc_go(+fp: KF, +fc: KF, +fa: KF, +fb: KF) -> KA:
  ana_pc_fp(kf_surf(fp), kf_surf(fc), fp, fc, fa, fb)

def ana_pc(+fa: KF, +fb: KF, +pfirst: Bool) -> KA:
  +r = ana_pc_go(Bool.pick(KF, pfirst, fa, fb), Bool.pick(KF, pfirst, fb, fa), fa, fb)
  Bool.pick(KA, pfirst, r, kaswap(r))

def ana_cc_fb_u(+cya: G.Cyl, +sb: G.GVal, +ba: Ty.Brep, +bb: Ty.Brep, +fa: KF, +fb: KF,
    +fda: SO.Fd, +fdb: SO.Fd) -> KA:
  match sb:
    case G.GV_cy{+cyb}:
      cc_pair(kf_fi(fa), kf_sk(fa), kf_ax(fa), cya, kf_fi(fb), kf_sk(fb), kf_ax(fb), cyb,
        SO.fd_bx(fda), SO.fd_bx(fdb), face_full(ba, kf_fi(fa)), face_full(bb, kf_fi(fb)))
    case _: gen_pair(kf_fi(fa), kf_sk(fa), kf_surf(fa), SO.fd_bx(fda), kf_fi(fb), kf_sk(fb), kf_surf(fb), SO.fd_bx(fdb))

def ana_cc_fb(+cya: G.Cyl, +sb: List<&2, G.GVal>, +ba: Ty.Brep, +bb: Ty.Brep, +fa: KF, +fb: KF,
    +fda: SO.Fd, +fdb: SO.Fd) -> KA:
  match sb:
    case s <> _: ana_cc_fb_u(cya, s, ba, bb, fa, fb, fda, fdb)
    case []: gen_pair(kf_fi(fa), kf_sk(fa), kf_surf(fa), SO.fd_bx(fda), kf_fi(fb), kf_sk(fb), kf_surf(fb), SO.fd_bx(fdb))

def ana_cc_fa_u(+sa: G.GVal, +sb: List<&2, G.GVal>, +ba: Ty.Brep, +bb: Ty.Brep, +fa: KF, +fb: KF,
    +fda: SO.Fd, +fdb: SO.Fd) -> KA:
  match sa:
    case G.GV_cy{+cya}: ana_cc_fb(cya, sb, ba, bb, fa, fb, fda, fdb)
    case _: gen_pair(kf_fi(fa), kf_sk(fa), kf_surf(fa), SO.fd_bx(fda), kf_fi(fb), kf_sk(fb), kf_surf(fb), SO.fd_bx(fdb))

def ana_cc_fa(+sa: List<&2, G.GVal>, +sb: List<&2, G.GVal>, +ba: Ty.Brep, +bb: Ty.Brep, +fa: KF, +fb: KF,
    +fda: SO.Fd, +fdb: SO.Fd) -> KA:
  match sa:
    case s <> _: ana_cc_fa_u(s, sb, ba, bb, fa, fb, fda, fdb)
    case []: gen_pair(kf_fi(fa), kf_sk(fa), kf_surf(fa), SO.fd_bx(fda), kf_fi(fb), kf_sk(fb), kf_surf(fb), SO.fd_bx(fdb))

def ana_cc(+ba: Ty.Brep, +bb: Ty.Brep, +fa: KF, +fb: KF, +fda: SO.Fd, +fdb: SO.Fd) -> KA:
  ana_cc_fa(kf_surf(fa), kf_surf(fb), ba, bb, fa, fb, fda, fdb)

def ana_pq_go_u(+sp: G.GVal, +fp: KF, +fq: KF, +bp: List<&2, I.I>, +bq: List<&2, I.I>, +cone: Bool,
    +pfirst: Bool, +fa: KF, +fb: KF, +fda: SO.Fd, +fdb: SO.Fd) -> KA:
  match sp:
    case G.GV_pl{+pa}:
      pq_pair(kf_fi(fp), kf_sk(fp), kf_ax(fp), pa, kf_fi(fq), kf_sk(fq), kf_surf(fq), bp, bq, cone, pfirst)
    case _: gen_pair(kf_fi(fa), kf_sk(fa), kf_surf(fa), SO.fd_bx(fda), kf_fi(fb), kf_sk(fb), kf_surf(fb), SO.fd_bx(fdb))

def ana_pq_go(+sp: List<&2, G.GVal>, +fp: KF, +fq: KF, +bp: List<&2, I.I>, +bq: List<&2, I.I>, +cone: Bool,
    +pfirst: Bool, +fa: KF, +fb: KF, +fda: SO.Fd, +fdb: SO.Fd) -> KA:
  match sp:
    case s <> _: ana_pq_go_u(s, fp, fq, bp, bq, cone, pfirst, fa, fb, fda, fdb)
    case []: gen_pair(kf_fi(fa), kf_sk(fa), kf_surf(fa), SO.fd_bx(fda), kf_fi(fb), kf_sk(fb), kf_surf(fb), SO.fd_bx(fdb))

def ana_pq(+fa: KF, +fb: KF, +fda: SO.Fd, +fdb: SO.Fd, +pfirst: Bool, +cone: Bool) -> KA:
  ana_pq_go(kf_surf(Bool.pick(KF, pfirst, fa, fb)), Bool.pick(KF, pfirst, fa, fb),
    Bool.pick(KF, pfirst, fb, fa), Bool.pick(List<&2, I.I>, pfirst, SO.fd_bx(fda), SO.fd_bx(fdb)),
    Bool.pick(List<&2, I.I>, pfirst, SO.fd_bx(fdb), SO.fd_bx(fda)), cone, pfirst, fa, fb, fda, fdb)

def ana_kind(+ska: U64, +skb: U64) -> U64:
  KC.pk_kind(ska, skb)

def ana_go(+ba: Ty.Brep, +bb: Ty.Brep, +fa: KF, +fb: KF, +fda: SO.Fd, +fdb: SO.Fd, +kk: U64) -> KA:
  +ska = kf_sk(fa)
  +skb = kf_sk(fb)
  Bool.pick(KA, U64.is_eq(kk, 1u64), ana_pp(fa, fb),
    Bool.pick(KA, U64.is_eq(kk, 2u64), ana_pc(fa, fb, True{}),
      Bool.pick(KA, U64.is_eq(kk, 3u64), ana_pc(fa, fb, False{}),
        Bool.pick(KA, U64.is_eq(kk, 4u64), ana_cc(ba, bb, fa, fb, fda, fdb),
          Bool.pick(KA, U64.is_eq(kk, 5u64),
            ana_pq(fa, fb, fda, fdb, KC.sk_is_plane(ska), KC.pk_cone_side(ska, skb)),
            gen_pair(kf_fi(fa), ska, kf_surf(fa), SO.fd_bx(fda), kf_fi(fb), skb, kf_surf(fb), SO.fd_bx(fdb)))))))

def ana_keep(+k: KA) -> Maybe<&2, KA>:
  Bool.pick(Maybe<&2, KA>, U64.is_eq(ka_dec(k), KC.dec_none()), None{}, Some{k})

def ana_keep2(+k: KA, +pp: Bool, +disj: Bool) -> Maybe<&2, KA>:
  +copd = Bool.and(Bool.and(pp, disj), U64.is_eq(ka_rel(k), KC.rel_coplanar()))
  Bool.pick(Maybe<&2, KA>, copd, None{}, ana_keep(k))

def anapair(+ba: Ty.Brep, +bb: Ty.Brep, +fa: KF, +fb: KF, +fda: SO.Fd, +fdb: SO.Fd) -> Maybe<&2, KA>:
  +kk = ana_kind(kf_sk(fa), kf_sk(fb))
  +pp = U64.is_eq(kk, 1u64)
  +vdisj = X.vdisj(SO.fd_bx(fda), SO.fd_bx(fdb))
  +disj = Bool.and(Bool.not(pp), vdisj)
  Bool.pick(Maybe<&2, KA>, disj, None{},
    ana_keep2(ana_go(ba, bb, fa, fb, fda, fdb, kk), pp, vdisj))

def ana_cons(m: Maybe<&2, KA>, +rest: List<&2, KA>) -> List<&2, KA>:
  match m:
    case None{}: rest
    case Some{+k}: k <> rest

def ana_row_go(+ba: Ty.Brep, +bb: Ty.Brep, +fa: KF, +fda: SO.Fd, +kfb: List<&2, KF>,
    +fdbs: List<&2, SO.Fd>) -> List<&2, KA>:
  match kfb:
    case []: []
    case +fb <> t:
      ana_cons(anapair(ba, bb, fa, fb, fda, fd_at(fdbs, kf_fi(fb))),
        ana_row_go(ba, bb, fa, fda, t, fdbs))

def ana_all_go(+ba: Ty.Brep, +bb: Ty.Brep, +kfa: List<&2, KF>, +fdas: List<&2, SO.Fd>,
    +kfb: List<&2, KF>, +fdbs: List<&2, SO.Fd>) -> List<&2, KA>:
  match kfa:
    case []: []
    case +fa <> t:
      List.append(&2, KA, ana_row_go(ba, bb, fa, fd_at(fdas, kf_fi(fa)), kfb, fdbs),
        ana_all_go(ba, bb, t, fdas, kfb, fdbs))

def analist(+ba: Ty.Brep, +bb: Ty.Brep, +fdas: List<&2, SO.Fd>, +fdbs: List<&2, SO.Fd>) -> List<&2, KA>:
  ana_all_go(ba, bb, kf_list(ba), fdas, kf_list(bb), fdbs)
