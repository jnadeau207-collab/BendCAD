import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../c04/types.bend as Ty
import ../base/par.bend as B
import ../base/ex.bend as E
import ../c06/iv.bend as I
import ../c07/sol.bend as SO
import ../c07/ivx.bend as X
import ./core.bend as KC
import ./curve.bend as KU
import ./clip.bend as QC
import ./ring.bend as RX

def hv(+i: Nat) -> Ty.HVertex:
  Ty.HV{i, U64.from_nat(Nat.add(i, 1n))}

def he(+i: Nat) -> Ty.HEdge:
  Ty.HE{i, U64.from_nat(Nat.add(i, 1n))}

def hc(+i: Nat) -> Ty.HCoedge:
  Ty.HC{i, U64.from_nat(Nat.add(i, 1n))}

def hlp(+i: Nat) -> Ty.HLoop:
  Ty.HL{i, U64.from_nat(Nat.add(i, 1n))}

def hfa(+i: Nat) -> Ty.HFace:
  Ty.HF{i, U64.from_nat(Nat.add(i, 1n))}

def hsh(+i: Nat) -> Ty.HShell:
  Ty.HS{i, U64.from_nat(Nat.add(i, 1n))}

def hso(+i: Nat) -> Ty.HSolid:
  Ty.HSo{i, U64.from_nat(Nat.add(i, 1n))}

def pcomp(+p: V.Point, +ax: U64) -> F64:
  Bool.pick(F64, U64.is_eq(ax, 0u64), V.pt_x(p),
    Bool.pick(F64, U64.is_eq(ax, 1u64), V.pt_y(p), V.pt_z(p)))

def pt_set(+p: V.Point, +ax: U64, +v: F64) -> V.Point:
  Bool.pick(V.Point, U64.is_eq(ax, 0u64), V.Pt{v, V.pt_y(p), V.pt_z(p)},
    Bool.pick(V.Point, U64.is_eq(ax, 1u64), V.Pt{V.pt_x(p), v, V.pt_z(p)},
      V.Pt{V.pt_x(p), V.pt_y(p), v}))

def pt_eq3(+a: V.Point, +b: V.Point) -> Bool:
  Bool.and(F64.is_eq(V.pt_x(a), V.pt_x(b)),
    Bool.and(F64.is_eq(V.pt_y(a), V.pt_y(b)), F64.is_eq(V.pt_z(a), V.pt_z(b))))

type FR is Data:
  FR{ kind: U64, ax: U64, c: F64, o: V.Point, r: F64 }

def fr_kind(+f: FR) -> U64:
  FR{kind, ax, c, o, r} = f
  kind

def fr_ax(+f: FR) -> U64:
  FR{kind, ax, c, o, r} = f
  ax

def fr_c(+f: FR) -> F64:
  FR{kind, ax, c, o, r} = f
  c

def fr_o(+f: FR) -> V.Point:
  FR{kind, ax, c, o, r} = f
  o

def fr_r(+f: FR) -> F64:
  FR{kind, ax, c, o, r} = f
  r

def fr_of(+s: G.GVal, +k: U64) -> FR:
  match s:
    case G.GV_pl{+w}: FR{0u64, KC.sk_axis(k), KU.plancon(w, KC.sk_axis(k)), G.pl_o(w), 0.0f64}
    case G.GV_cy{+w}: FR{1u64, KC.sk_axis(k), 0.0f64, G.cy_o(w), G.cy_r(w)}
    case _: FR{7u64, 3u64, 0.0f64, V.Pt{0.0f64, 0.0f64, 0.0f64}, 0.0f64}

def fr_valid(+f: FR) -> Bool:
  U64.is_le(fr_kind(f), 1u64)

def fr_cyl(+f: FR) -> Bool:
  U64.is_eq(fr_kind(f), 1u64)

def run0_ax(+ax: U64) -> U64:
  Bool.pick(U64, U64.is_eq(ax, 0u64), 1u64, 0u64)

def run1_ax(+ax: U64) -> U64:
  Bool.pick(U64, U64.is_eq(ax, 2u64), 1u64, 2u64)

def proj_pl(+f: FR, +p: V.Point) -> V.Vec2:
  V.V2{pcomp(p, run0_ax(fr_ax(f))), pcomp(p, run1_ax(fr_ax(f)))}

def unproj_pl(+f: FR, +u: F64, +v: F64) -> V.Point:
  +ax = fr_ax(f)
  +c = fr_c(f)
  Bool.pick(V.Point, U64.is_eq(ax, 0u64), V.Pt{c, u, v},
    Bool.pick(V.Point, U64.is_eq(ax, 1u64), V.Pt{u, c, v}, V.Pt{u, v, c}))

def sheet_h_ax(+ax: U64) -> U64:
  Bool.pick(U64, U64.is_eq(ax, 0u64), 1u64, 0u64)

def sheet_d_ax(+ax: U64) -> U64:
  Bool.pick(U64, U64.is_eq(ax, 2u64), 1u64, 2u64)

def sheet_hw(+f: FR, +p: V.Point) -> V.Vec2:
  V.V2{pcomp(p, sheet_h_ax(fr_ax(f))), pcomp(p, fr_ax(f))}

def sheet_sx(+f: FR, +p: V.Point) -> Bool:
  F64.is_le(pcomp(fr_o(f), sheet_d_ax(fr_ax(f))), pcomp(p, sheet_d_ax(fr_ax(f))))

def sheet_unproj(+f: FR, +sx: Bool, +h: F64, +w: F64) -> V.Point:
  +ax = fr_ax(f)
  +o = fr_o(f)
  +r = fr_r(f)
  +hc = pcomp(o, sheet_h_ax(ax))
  +dc = pcomp(o, sheet_d_ax(ax))
  +dh = F64.sub(h, hc)
  +dd = F64.sub(F64.mul(r, r), F64.mul(dh, dh))
  +s = F64.sqrt(F64.max(dd, 0.0f64))
  +d = Bool.pick(F64, sx, F64.add(dc, s), F64.sub(dc, s))
  Bool.pick(V.Point, U64.is_eq(ax, 0u64), V.Pt{w, h, d},
    Bool.pick(V.Point, U64.is_eq(ax, 1u64), V.Pt{h, w, d}, V.Pt{h, d, w}))

type PR is Data:
  PR{ ok: Bool, v: V.Point }

def snap_cy_try(+s: G.GVal, ps: List<&2, V.Point>) -> PR:
  match ps:
    case []: PR{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case +h <> t:
      Bool.pick(PR, GO.q_on_r(s, h), PR{True{}, h}, snap_cy_try(s, t))

def snap_cy(+s: G.GVal, +p: V.Point, +ax: U64) -> PR:
  +ha = sheet_h_ax(ax)
  +da = sheet_d_ax(ax)
  +h = pcomp(p, ha)
  +d = pcomp(p, da)
  +hu = E.f64_next_up(h)
  +hd = E.f64_next_down(h)
  +du = E.f64_next_up(d)
  +dd = E.f64_next_down(d)
  snap_cy_try(s, [p, pt_set(p, ha, hu), pt_set(p, ha, hd), pt_set(p, da, du), pt_set(p, da, dd),
    pt_set(pt_set(p, ha, hu), da, du), pt_set(pt_set(p, ha, hu), da, dd),
    pt_set(pt_set(p, ha, hd), da, du), pt_set(pt_set(p, ha, hd), da, dd)])

type CUT is Data:
  CUT{ vert: Bool, c: F64, ci: Nat, ring: Bool }

def cut_vert(+c: CUT) -> Bool:
  CUT{vert, cc, ci, ring} = c
  vert

def cut_c(+c: CUT) -> F64:
  CUT{vert, cc, ci, ring} = c
  cc

def cut_ci(+c: CUT) -> Nat:
  CUT{vert, cc, ci, ring} = c
  ci

def cut_ring(+c: CUT) -> Bool:
  CUT{vert, cc, ci, ring} = c
  ring

type RG is Data:
  RG{ ci: Nat, cc: G.Circle3 }

type CU2 is Data:
  CU2{ ok: Bool, vert: Bool, c: F64 }

def lax_m(+lax: U64) -> U64:
  Bool.pick(U64, U64.is_eq(lax, 0u64), 1u64, 0u64)

def lax_n(+lax: U64) -> U64:
  Bool.pick(U64, U64.is_eq(lax, 0u64), 2u64, Bool.pick(U64, U64.is_eq(lax, 1u64), 2u64, 1u64))

def cut_line_uv(+lax: U64, +lc0: F64, +lc1: F64, +frax: U64) -> CU2:
  +r0 = run0_ax(frax)
  +r1 = run1_ax(frax)
  +m = lax_m(lax)
  Bool.pick(CU2, U64.is_eq(lax, r0), CU2{True{}, False{}, Bool.pick(F64, U64.is_eq(r1, m), lc0, lc1)},
    Bool.pick(CU2, U64.is_eq(lax, r1), CU2{True{}, True{}, Bool.pick(F64, U64.is_eq(r0, m), lc0, lc1)},
      CU2{False{}, False{}, 0.0f64}))

type FC is Data:
  FC{ cuts: List<&2, CUT>, rings: List<&2, RG>, prings: List<&2, RX.RING>, cop: Bool, ok: Bool, why: U64 }

def fc_cuts(+f: FC) -> List<&2, CUT>:
  FC{cuts, rings, prings, cop, ok, why} = f
  cuts

def fc_rings(+f: FC) -> List<&2, RG>:
  FC{cuts, rings, prings, cop, ok, why} = f
  rings

def fc_cop(+f: FC) -> Bool:
  FC{cuts, rings, prings, cop, ok, why} = f
  cop

def fc_ok(+f: FC) -> Bool:
  FC{cuts, rings, prings, cop, ok, why} = f
  ok

def fc_why(+f: FC) -> U64:
  FC{cuts, rings, prings, cop, ok, why} = f
  why

def fc_prings(+f: FC) -> List<&2, RX.RING>:
  FC{cuts, rings, prings, cop, ok, why} = f
  prings

def ka_face_ring_go(cs: List<&2, G.Circle3>, +frax: U64, +ci: Nat, +acc: List<&2, CUT>,
    +racc: List<&2, RG>) -> FC:
  match cs:
    case []: FC{acc, racc, [], False{}, True{}, 0u64}
    case +h <> +t:
      +axok = U64.is_eq(KU.ax_of(KU.axdir(KU.crx(G.cc_u(h), G.cc_v(h)))), frax)
      +w = pcomp(G.cc_c(h), frax)
      Bool.pick(FC, axok, ka_face_ring_go(t, frax, Nat.add(ci, 1n), CUT{False{}, w, ci, True{}} <> acc,
          RG{ci, h} <> racc),
        FC{[], [], [], False{}, False{}, 22u64})

def ka_face_ring(+cs: List<&2, G.Circle3>, +frax: U64, +ci: Nat) -> FC:
  ka_face_ring_go(cs, frax, ci, [], [])

def ka_face_ln2(+u: CU2, +ci: Nat) -> FC:
  match u:
    case CU2{+ok, +vert, +c}: Bool.pick(FC, ok, FC{[CUT{vert, c, ci, False{}}], [], [], False{}, True{},
        0u64}, FC{[], [], [], False{}, False{}, 18u64})

def ka_face_ln(+k: KU.KA, +frax: U64, +ci: Nat) -> FC:
  +cv = KU.ka_cv(k)
  ka_face_ln2(cut_line_uv(KU.kcv_lax(cv), KU.kcv_lc0(cv), KU.kcv_lc1(cv), frax), ci)

def ka_face_cc(+k: KU.KA, +frax: U64, +cyl: Bool, +ci: Nat) -> FC:
  ka_face_ring(KU.kcv_ccs(KU.ka_cv(k)), frax, ci)

def ka_face_pr(+k: KU.KA, +side: U64, +cyl: Bool) -> FC:
  +cv = KU.ka_cv(k)
  Bool.pick(FC, Bool.and(cyl, KU.kcv_rok(cv, side)),
    FC{[], [], KU.kcv_rings(cv, side), False{}, True{}, 0u64},
    FC{[], [], [], False{}, False{}, KC.kr_nonconic()})

def ka_face_cv(+curve: U64, +k: KU.KA, +frax: U64, +cyl: Bool, +side: U64,
    +ci: Nat) -> FC:
  match curve:
    case 0u64: FC{[], [], [], False{}, True{}, 0u64}
    case 1u64: ka_face_ln(k, frax, ci)
    case 2u64: ka_face_cc(k, frax, cyl, ci)
    case 4u64: ka_face_pr(k, side, cyl)
    case _: FC{[], [], [], True{}, True{}, 0u64}

def ka_face_dc(+ok: Bool, +curve: U64, +refuse: U64, +k: KU.KA, +frax: U64, +cyl: Bool,
    +side: U64, +ci: Nat) -> FC:
  match ok:
    case False{}: FC{[], [], [], False{}, False{}, refuse}
    case True{}: ka_face_cv(curve, k, frax, cyl, side, ci)

def ka_face_nosp(+dok: Bool, +refuse: U64) -> FC:
  match dok:
    case True{}: FC{[], [], [], False{}, True{}, 0u64}
    case False{}: FC{[], [], [], False{}, False{}, refuse}

def ka_face_sp(+split: Bool, +dec: U64, +k: KU.KA, +frax: U64, +cyl: Bool, +side: U64,
    +ci: Nat) -> FC:
  match split:
    case False{}: ka_face_nosp(KC.dec_ok(dec), KC.dec_refuse(dec))
    case True{}: ka_face_dc(KC.dec_ok(dec), KC.dec_curve(dec), KC.dec_refuse(dec), k, frax, cyl,
      side, ci)

def ka_face_go(+mine: Bool, +split: Bool, +dec: U64, +k: KU.KA, +frax: U64, +cyl: Bool,
    +side: U64, +ci: Nat) -> FC:
  match mine:
    case False{}: FC{[], [], [], False{}, True{}, 0u64}
    case True{}: ka_face_sp(split, dec, k, frax, cyl, side, ci)

def ka_face_cuts(+k: KU.KA, +fi: Nat, +side: U64, +frax: U64, +cyl: Bool, +ci: Nat) -> FC:
  +dec = KU.ka_dec(k)
  +fa = KU.ka_fa(k)
  +fb = KU.ka_fb(k)
  +mine = Bool.pick(Bool, U64.is_eq(side, 0u64), Nat.is_eq(fa, fi), Nat.is_eq(fb, fi))
  +split = Bool.pick(Bool, U64.is_eq(side, 0u64), KC.dec_splitA(dec), KC.dec_splitB(dec))
  ka_face_go(mine, split, dec, k, frax, cyl, side, ci)

def face_cuts_go(ks: List<&2, KU.KA>, +fi: Nat, +side: U64, +frax: U64, +cyl: Bool, +ci: Nat,
    +acc: List<&2, CUT>, +racc: List<&2, RG>, +pracc: List<&2, RX.RING>, +cop: Bool, +ok: Bool,
    +why: U64) -> FC:
  match ks:
    case []: FC{acc, racc, pracc, cop, ok, why}
    case +h <> +t:
      +r = ka_face_cuts(h, fi, side, frax, cyl, ci)
      face_cuts_go(t, fi, side, frax, cyl, Nat.add(ci, List.length(&2, CUT, fc_cuts(r))),
        List.append(&2, CUT, fc_cuts(r), acc), List.append(&2, RG, fc_rings(r), racc),
        List.append(&2, RX.RING, fc_prings(r), pracc),
        Bool.or(cop, fc_cop(r)), Bool.and(ok, fc_ok(r)), Bool.pick(U64, ok, fc_why(r), why))

def face_cuts(+ks: List<&2, KU.KA>, +fi: Nat, +side: U64, +frax: U64, +cyl: Bool, +ci: Nat) -> FC:
  face_cuts_go(ks, fi, side, frax, cyl, ci, [], [], [], False{}, True{}, 0u64)

type RA is Data:
  RA{ isln: Bool, cx: F64, cy: F64, cr: F64, ccw: Bool }

def rq_arc_w(+wo: Bool, +ax: F64, +ay: F64, +px: F64, +py: F64, +bx: F64, +by: F64, +w1: F64,
    +mx: F64, +my: F64, +dx: F64, +dy: F64, +d: F64) -> RA:
  match wo:
    case True{}: RA{True{}, 0.0f64, 0.0f64, 0.0f64, True{}}
    case False{}:
      +hx = F64.sub(ax, mx)
      +hy = F64.sub(ay, my)
      +h2 = F64.add(F64.mul(hx, hx), F64.mul(hy, hy))
      +s = F64.neg(F64.div(F64.mul(w1, d), F64.add(1.0f64, w1)))
      +lam = F64.div(F64.sub(F64.mul(s, s), h2), F64.add(s, s))
      +r = F64.sqrt(F64.add(h2, F64.mul(lam, lam)))
      +ux = F64.div(dx, d)
      +uy = F64.div(dy, d)
      +ox = F64.add(mx, F64.mul(lam, ux))
      +oy = F64.add(my, F64.mul(lam, uy))
      +o = QC.ori_sign(ax, ay, bx, by, px, py)
      +neg = F64.is_lt(w1, 0.0f64)
      +ccw = Bool.pick(Bool, neg, U64.is_eq(o, 0u64), U64.is_eq(o, 1u64))
      RA{False{}, ox, oy, r, ccw}

def rq_arc_go(+dz: Bool, +wo: Bool, +ax: F64, +ay: F64, +px: F64, +py: F64, +bx: F64, +by: F64,
    +w1: F64, +mx: F64, +my: F64, +dx: F64, +dy: F64, +d: F64) -> RA:
  match dz:
    case True{}: RA{True{}, 0.0f64, 0.0f64, 0.0f64, True{}}
    case False{}: rq_arc_w(wo, ax, ay, px, py, bx, by, w1, mx, my, dx, dy, d)

def rq_arc(+ax: F64, +ay: F64, +px: F64, +py: F64, +bx: F64, +by: F64, +w1: F64) -> RA:
  +mx = F64.mul(0.5f64, F64.add(ax, bx))
  +my = F64.mul(0.5f64, F64.add(ay, by))
  +dx = F64.sub(mx, px)
  +dy = F64.sub(my, py)
  +d = F64.sqrt(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)))
  rq_arc_go(F64.is_eq(d, 0.0f64), F64.is_eq(w1, 1.0f64), ax, ay, px, py, bx, by, w1, mx, my, dx, dy, d)

type EP is Data:
  EP{ a: V.Point, b: V.Point, ei: Nat, fwd: Bool }

def ep_a(+e: EP) -> V.Point:
  EP{a, b, ei, fwd} = e
  a

def ep_b(+e: EP) -> V.Point:
  EP{a, b, ei, fwd} = e
  b

def ep_ei(+e: EP) -> Nat:
  EP{a, b, ei, fwd} = e
  ei

def ep_fwd(+e: EP) -> Bool:
  EP{a, b, ei, fwd} = e
  fwd

def ce_ep(+b: Ty.Brep, +h: Ty.HCoedge) -> EP:
  +ces = Ty.brep_ces(b)
  +es = Ty.brep_es(b)
  +vs = Ty.brep_vs(b)
  +ce = KU.nth_ce0(ces, Ty.hc_idx(h))
  +ed = KU.nth_ed0(es, Ty.he_idx(Ty.ce_edge(ce)))
  +f = Ty.ce_fwd(ce)
  +p0 = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v0(ed))))
  +p1 = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v1(ed))))
  EP{Bool.pick(V.Point, f, p0, p1), Bool.pick(V.Point, f, p1, p0), Ty.he_idx(Ty.ce_edge(ce)), f}

def ln_piece(+a: V.Vec2, +b: V.Vec2, +ei: Nat) -> QC.QG:
  QC.qg_ln(V.v2_x(a), V.v2_y(a), V.v2_x(b), V.v2_y(b), QC.lab_orig(), ei)

type WP is Data:
  WP{ p: V.Point, w: F64 }

def wp_p(+q: WP) -> V.Point:
  WP{p, w} = q
  p

def wp_w(+q: WP) -> F64:
  WP{p, w} = q
  w

def hmid(+a: V.Point, +wa: F64, +b: V.Point, +wb: F64, +s: F64, +t: F64) -> WP:
  +w = F64.add(F64.mul(s, wa), F64.mul(t, wb))
  +x = F64.div(F64.add(F64.mul(s, F64.mul(wa, V.pt_x(a))), F64.mul(t, F64.mul(wb, V.pt_x(b)))), w)
  +y = F64.div(F64.add(F64.mul(s, F64.mul(wa, V.pt_y(a))), F64.mul(t, F64.mul(wb, V.pt_y(b)))), w)
  +z = F64.div(F64.add(F64.mul(s, F64.mul(wa, V.pt_z(a))), F64.mul(t, F64.mul(wb, V.pt_z(b)))), w)
  WP{V.Pt{x, y, z}, w}

type RQS is Data:
  RQS{ l: G.RQBez, r: G.RQBez }

def rqs_l(+q: RQS) -> G.RQBez:
  RQS{l, r} = q
  l

def rqs_r(+q: RQS) -> G.RQBez:
  RQS{l, r} = q
  r

def rq_split_t(+q: G.RQBez, +t: F64) -> RQS:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = q
  +s = F64.sub(1.0f64, t)
  +m01 = hmid(p0, w0, p1, w1, s, t)
  +m12 = hmid(p1, w1, p2, w2, s, t)
  +m = hmid(wp_p(m01), wp_w(m01), wp_p(m12), wp_w(m12), s, t)
  RQS{G.Rq{p0, wp_p(m01), wp_p(m), w0, wp_w(m01), wp_w(m)},
    G.Rq{wp_p(m), wp_p(m12), p2, wp_w(m), wp_w(m12), w2}}

type RQ3 is Data:
  RQ3{ a: G.RQBez, b: G.RQBez, c: G.RQBez }

def rq3_a(r: RQ3) -> G.RQBez:
  RQ3{a, b, c} = r
  a

def rq3_b(r: RQ3) -> G.RQBez:
  RQ3{a, b, c} = r
  b

def rq3_c(r: RQ3) -> G.RQBez:
  RQ3{a, b, c} = r
  c

def rq_cas2(+q: G.RQBez, +t1: F64, +t2: F64) -> RQ3:
  +r = rq_split_t(q, t2)
  +rl = rq_split_t(rqs_l(r), F64.div(t1, t2))
  RQ3{rqs_l(rl), rqs_r(rl), rqs_r(r)}

type ABC is Data:
  ABC{ a: F64, b: F64, c: F64 }

def rq_dabc(+q: G.RQBez, +dc: F64, +dax: U64) -> ABC:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = q
  +d0 = F64.sub(pcomp(p0, dax), dc)
  +d1 = F64.sub(pcomp(p1, dax), dc)
  +d2 = F64.sub(pcomp(p2, dax), dc)
  +a = F64.add(F64.sub(d0, F64.mul(F64.mul(2.0f64, w1), d1)), d2)
  +bb = F64.add(F64.mul(F64.neg(2.0f64), d0), F64.mul(F64.mul(2.0f64, w1), d1))
  ABC{a, bb, d0}

def rq_t_inner(+t: F64) -> Bool:
  Bool.and(F64.is_lt(0.0f64, t), F64.is_lt(t, 1.0f64))

def rq_t_add(+t: F64, +acc: List<&2, F64>) -> List<&2, F64>:
  Bool.pick(List<&2, F64>, rq_t_inner(t), t <> acc, acc)

def rq_d_roots_go(+ds: U64, +a: F64, +b: F64, +c: F64, +acc: List<&2, F64>) -> List<&2, F64>:
  match ds:
    case 0u64: rq_t_add(QC.q_solve(a, b, c, True{}), rq_t_add(QC.q_solve(a, b, c, False{}), acc))
    case 2u64: rq_t_add(QC.q_solve(a, b, c, True{}), acc)
    case _: acc

def rq_d_roots(+e: ABC, +acc: List<&2, F64>) -> List<&2, F64>:
  ABC{+a, +b, +c} = e
  rq_d_roots_go(QC.disc_sign(a, b, c), a, b, c, acc)

def eqb(+a: Bool, +b: Bool) -> Bool:
  Bool.or(Bool.and(a, b), Bool.and(Bool.not(a), Bool.not(b)))

type LQ2 is Data:
  LQ2{ ps: List<&2, QC.QG>, ok: Bool }

def lq2_ps(+q: LQ2) -> List<&2, QC.QG>:
  LQ2{ps, ok} = q
  ps

def lq2_ok(+q: LQ2) -> Bool:
  LQ2{ps, ok} = q
  ok

def spine_touch(+f: FR, +p: V.Point, +q: V.Point) -> Bool:
  +dax = sheet_d_ax(fr_ax(f))
  +dc = pcomp(fr_o(f), dax)
  Bool.or(F64.is_eq(pcomp(p, dax), dc), F64.is_eq(pcomp(q, dax), dc))

def sheet_same(+f: FR, +p: V.Point, +q: V.Point) -> Bool:
  Bool.or(eqb(sheet_sx(f, p), sheet_sx(f, q)), spine_touch(f, p, q))

def pt_emit1(+a: V.Point, +b: V.Point, +f: FR, +sx: Bool, +ei: Nat, +acc: List<&2, QC.QG>,
    +ok: Bool) -> LQ2:
  +pa = sheet_hw(f, a)
  +pb = sheet_hw(f, b)
  Bool.pick(LQ2, sheet_same(f, a, b), LQ2{ln_piece(pa, pb, ei) <> acc, ok},
    LQ2{acc, False{}})

def rq_cyl_piece(+isln: Bool, +want: Bool, +same: Bool, +a: V.Vec2, +b: V.Vec2, +cx: F64,
    +cy: F64, +cr: F64, +ccw: Bool, +ei: Nat, +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  match same:
    case True{}:
      Bool.pick(LQ2, isln, LQ2{ln_piece(a, b, ei) <> acc, ok},
        LQ2{QC.qg_ar(V.v2_x(a), V.v2_y(a), V.v2_x(b), V.v2_y(b), cx, cy, cr, ccw, QC.lab_orig(),
          ei) <> acc, ok})
    case False{}: LQ2{acc, False{}}

def rq_cyl_ra(+r: RA, +a: V.Vec2, +b: V.Vec2, +p0: V.Point, +p2: V.Point, +f: FR, +sx: Bool,
    +ei: Nat, +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  match r:
    case RA{+isln, +cx, +cy, +cr, +ccw}:
      +s0 = sheet_sx(f, p0)
      +s1 = sheet_sx(f, p2)
      +want = Bool.and(eqb(s0, sx), eqb(s1, sx))
      rq_cyl_piece(isln, want, sheet_same(f, p0, p2), a, b, cx, cy, cr, ccw, ei, acc, ok)

def rq_cyl_sub(+q: G.RQBez, +f: FR, +sx: Bool, +ei: Nat, +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = q
  +a = sheet_hw(f, p0)
  +c = sheet_hw(f, p1)
  +b = sheet_hw(f, p2)
  rq_cyl_ra(rq_arc(V.v2_x(a), V.v2_y(a), V.v2_x(c), V.v2_y(c), V.v2_x(b), V.v2_y(b), w1), a, b,
    p0, p2, f, sx, ei, acc, ok)

def rq_snap_p0(+q: G.RQBez, +dax: U64, +dc: F64) -> G.RQBez:
  G.Rq{pt_set(G.rq_p0(q), dax, dc), G.rq_p1(q), G.rq_p2(q), G.rq_w0(q), G.rq_w1(q), G.rq_w2(q)}

def rq_snap_p2(+q: G.RQBez, +dax: U64, +dc: F64) -> G.RQBez:
  G.Rq{G.rq_p0(q), G.rq_p1(q), pt_set(G.rq_p2(q), dax, dc), G.rq_w0(q), G.rq_w1(q), G.rq_w2(q)}

def rq_cyl_1t(+q: G.RQBez, +t1: F64, +f: FR, +sx: Bool, +ei: Nat, +acc: List<&2, QC.QG>,
    +ok: Bool) -> LQ2:
  +r = rq_split_t(q, t1)
  +dax = sheet_d_ax(fr_ax(f))
  +dc = pcomp(fr_o(f), dax)
  +l = rq_cyl_sub(rq_snap_p2(rqs_l(r), dax, dc), f, sx, ei, acc, ok)
  rq_cyl_sub(rq_snap_p0(rqs_r(r), dax, dc), f, sx, ei, lq2_ps(l), lq2_ok(l))

def rq_cyl_2t(+q: G.RQBez, +t1: F64, +t2: F64, +f: FR, +sx: Bool, +ei: Nat, +acc: List<&2, QC.QG>,
    +ok: Bool) -> LQ2:
  +r = rq_cas2(q, t1, t2)
  +dax = sheet_d_ax(fr_ax(f))
  +dc = pcomp(fr_o(f), dax)
  +l1 = rq_cyl_sub(rq_snap_p2(rq3_a(r), dax, dc), f, sx, ei, acc, ok)
  +l2 = rq_cyl_sub(rq_snap_p0(rq_snap_p2(rq3_b(r), dax, dc), dax, dc), f, sx, ei, lq2_ps(l1),
    lq2_ok(l1))
  rq_cyl_sub(rq_snap_p0(rq3_c(r), dax, dc), f, sx, ei, lq2_ps(l2), lq2_ok(l2))

def rq_cyl_tl(+t1: F64, ts: List<&2, F64>, +q: G.RQBez, +f: FR, +sx: Bool, +ei: Nat,
    +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  match ts:
    case []: rq_cyl_1t(q, t1, f, sx, ei, acc, ok)
    case +t2 <> +t: rq_cyl_2t(q, t1, t2, f, sx, ei, acc, ok)

def rq_cyl_ts(+q: G.RQBez, ts: List<&2, F64>, +f: FR, +sx: Bool, +ei: Nat, +acc: List<&2, QC.QG>,
    +ok: Bool) -> LQ2:
  match ts:
    case []: rq_cyl_sub(q, f, sx, ei, acc, ok)
    case +t1 <> t: rq_cyl_tl(t1, t, q, f, sx, ei, acc, ok)

def rq_t_ins(+x: F64, +ys: List<&2, F64>) -> List<&2, F64>:
  match ys:
    case []: [x]
    case +h <> +t: Bool.pick(List<&2, F64>, F64.is_lt(x, h), x <> ys, h <> rq_t_ins(x, t))

def rq_ts_sort(ts: List<&2, F64>, +acc: List<&2, F64>) -> List<&2, F64>:
  match ts:
    case []: acc
    case +h <> t: rq_t_ins(h, rq_ts_sort(t, acc))

def rq_cyl_emit(+q: G.RQBez, +f: FR, +sx: Bool, +ei: Nat, +acc: List<&2, QC.QG>,
    +ok: Bool) -> LQ2:
  rq_cyl_ts(q, rq_ts_sort(rq_d_roots(rq_dabc(q, pcomp(fr_o(f), sheet_d_ax(fr_ax(f))),
    sheet_d_ax(fr_ax(f))), []), []), f, sx, ei, acc, ok)

def ln_cyl_emit(+a: V.Point, +b: V.Point, +f: FR, +sx: Bool, +ei: Nat, +acc: List<&2, QC.QG>,
    +ok: Bool) -> LQ2:
  pt_emit1(a, b, f, sx, ei, acc, ok)

def dcomp(+d: V.Dir, +ax: U64) -> F64:
  Bool.pick(F64, U64.is_eq(ax, 0u64), V.dr_x(d),
    Bool.pick(F64, U64.is_eq(ax, 1u64), V.dr_y(d), V.dr_z(d)))

def dir_run(+f: FR, +d: V.Dir) -> V.Vec2:
  +ax = fr_ax(f)
  V.V2{dcomp(d, run0_ax(ax)), dcomp(d, run1_ax(ax))}

def cc_pl_half_go(+m: V.Point, +cc: G.Circle3, +v: V.Point, +f: FR, +fwd: Bool, +ei: Nat,
    +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  +c = proj_pl(f, G.cc_c(cc))
  +a = proj_pl(f, v)
  +b = proj_pl(f, m)
  +u = dir_run(f, G.cc_u(cc))
  +w = dir_run(f, G.cc_v(cc))
  +s = QC.ori_sign(0.0f64, 0.0f64, V.v2_x(u), V.v2_y(u), V.v2_x(w), V.v2_y(w))
  +ccw = eqb(fwd, U64.is_eq(s, 0u64))
  +cr = G.cc_r(cc)
  +lab = QC.lab_orig()
  LQ2{QC.qg_ar(V.v2_x(a), V.v2_y(a), V.v2_x(b), V.v2_y(b), V.v2_x(c), V.v2_y(c), cr, ccw, lab, ei) <>
    QC.qg_ar(V.v2_x(b), V.v2_y(b), V.v2_x(a), V.v2_y(a), V.v2_x(c), V.v2_y(c), cr, ccw, lab, ei) <>
    acc, ok}

def cc_pl_half(+cc: G.Circle3, +v: V.Point, +f: FR, +fwd: Bool, +ei: Nat, +acc: List<&2, QC.QG>,
    +ok: Bool) -> LQ2:
  +r = GO.circ_eval(cc, 0.0f64)
  Bool.pick(LQ2, G.gres_ok(r), cc_pl_half_go(G.gres_p(r), cc, v, f, fwd, ei, acc, ok),
    LQ2{acc, False{}})

def cc_pt(+c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64, +a: F64, +b: F64) -> V.Point:
  V.Pt{F64.add(V.pt_x(c), F64.mul(r, F64.add(F64.mul(a, V.dr_x(u)), F64.mul(b, V.dr_x(v))))),
    F64.add(V.pt_y(c), F64.mul(r, F64.add(F64.mul(a, V.dr_y(u)), F64.mul(b, V.dr_y(v))))),
    F64.add(V.pt_z(c), F64.mul(r, F64.add(F64.mul(a, V.dr_z(u)), F64.mul(b, V.dr_z(v)))))}

type CX4 is Data:
  CX4{ ok: Bool, x1: V.Point, x2: V.Point, mu: V.Point, ml: V.Point, c: V.Point, r: F64 }

def cx4_ok(+p: CX4) -> Bool:
  CX4{ok, x1, x2, mu, ml, c, r} = p
  ok

def cx4_x1(+p: CX4) -> V.Point:
  CX4{ok, x1, x2, mu, ml, c, r} = p
  x1

def cx4_x2(+p: CX4) -> V.Point:
  CX4{ok, x1, x2, mu, ml, c, r} = p
  x2

def cx4_mu(+p: CX4) -> V.Point:
  CX4{ok, x1, x2, mu, ml, c, r} = p
  mu

def cx4_ml(+p: CX4) -> V.Point:
  CX4{ok, x1, x2, mu, ml, c, r} = p
  ml

def cx4_c(+p: CX4) -> V.Point:
  CX4{ok, x1, x2, mu, ml, c, r} = p
  c

def cx4_r(+p: CX4) -> F64:
  CX4{ok, x1, x2, mu, ml, c, r} = p
  r

def cc_cyl_pts_go(+c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64, +s: F64, +t: F64, +k: F64,
    +h: F64) -> CX4:
  +a1 = F64.add(F64.mul(k, s), F64.mul(h, t))
  +b1 = F64.sub(F64.mul(k, t), F64.mul(h, s))
  +a2 = F64.sub(F64.mul(k, s), F64.mul(h, t))
  +b2 = F64.add(F64.mul(k, t), F64.mul(h, s))
  CX4{True{}, cc_pt(c, u, v, r, a1, b1), cc_pt(c, u, v, r, a2, b2),
    cc_pt(c, u, v, r, s, t), cc_pt(c, u, v, r, F64.neg(s), F64.neg(t)), c, r}

def cc_cyl_pts(+cc: G.Circle3, +f: FR) -> CX4:
  +c = G.cc_c(cc)
  +u = G.cc_u(cc)
  +v = G.cc_v(cc)
  +r = G.cc_r(cc)
  +dax = sheet_d_ax(fr_ax(f))
  +s = dcomp(u, dax)
  +t = dcomp(v, dax)
  +cd = pcomp(fr_o(f), dax)
  +k = F64.div(F64.sub(cd, pcomp(c, dax)), r)
  +h2 = F64.sub(1.0f64, F64.mul(k, k))
  Bool.pick(CX4, F64.is_lt(h2, 0.0f64), CX4{False{}, c, c, c, c, c, r},
    cc_cyl_pts_go(c, u, v, r, s, t, k, F64.sqrt(h2)))

def cc_cyl_q(+p: CX4, +f: FR, +sx: Bool, +ei: Nat, +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  +mu = cx4_mu(p)
  +ml = cx4_ml(p)
  +x1 = cx4_x1(p)
  +x2 = cx4_x2(p)
  +okq = Bool.and(Bool.and(sheet_sx(f, mu), Bool.not(sheet_sx(f, ml))), ok)
  Bool.pick(LQ2, sx, LQ2{ln_piece(sheet_hw(f, x1), sheet_hw(f, x2), ei) <> acc, okq},
    LQ2{ln_piece(sheet_hw(f, x2), sheet_hw(f, x1), ei) <> acc, okq})

def cc_cyl_ck(+pok: Bool, +p: CX4, +f: FR, +sx: Bool, +ei: Nat, +acc: List<&2, QC.QG>,
    +ok: Bool) -> LQ2:
  match pok:
    case False{}: LQ2{acc, False{}}
    case True{}: cc_cyl_q(p, f, sx, ei, acc, ok)

def cc_cyl_emit(+cc: G.Circle3, +f: FR, +sx: Bool, +ei: Nat, +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  +p = cc_cyl_pts(cc, f)
  cc_cyl_ck(cx4_ok(p), p, f, sx, ei, acc, ok)

def gv_tag(+g: G.GVal) -> U64:
  match g:
    case G.GV_ln{+w}: 0u64
    case G.GV_bz{+w}: 1u64
    case G.GV_rq{+w}: 2u64
    case G.GV_cc{+w}: 3u64
    case _: 9u64

def gv_rq_of(+g: G.GVal) -> G.RQBez:
  match g:
    case G.GV_rq{+w}: w
    case _: G.Rq{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64},
      V.Pt{0.0f64, 0.0f64, 0.0f64}, 1.0f64, 1.0f64, 1.0f64}

def gv_cc_of(+g: G.GVal) -> G.Circle3:
  match g:
    case G.GV_cc{+w}: w
    case _: G.Cc{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 1.0f64, 0.0f64}, 1.0f64}

def ce_qg_ln_go(+cyl: Bool, +e: EP, +fr: FR, +sx: Bool, +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  match cyl:
    case False{}: LQ2{ln_piece(proj_pl(fr, ep_a(e)), proj_pl(fr, ep_b(e)), ep_ei(e)) <> acc, ok}
    case True{}: ln_cyl_emit(ep_a(e), ep_b(e), fr, sx, ep_ei(e), acc, ok)

def ce_qg_ln(+e: EP, +fr: FR, +sx: Bool, +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  ce_qg_ln_go(fr_cyl(fr), e, fr, sx, acc, ok)

def ce_qg_ra(+r: RA, +a: V.Vec2, +b: V.Vec2, +e: EP, +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  match r:
    case RA{+isln, +cx, +cy, +cr, +ccw}:
      Bool.pick(LQ2, isln, LQ2{ln_piece(a, b, ep_ei(e)) <> acc, ok},
        LQ2{QC.qg_ar(V.v2_x(a), V.v2_y(a), V.v2_x(b), V.v2_y(b), cx, cy, cr, ccw, QC.lab_orig(),
          ep_ei(e)) <> acc, ok})

def ce_qg_rq_pl(+q: G.RQBez, +e: EP, +fr: FR, +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = q
  +a = proj_pl(fr, p0)
  +c = proj_pl(fr, p1)
  +b = proj_pl(fr, p2)
  ce_qg_ra(rq_arc(V.v2_x(a), V.v2_y(a), V.v2_x(c), V.v2_y(c), V.v2_x(b), V.v2_y(b), w1), a, b, e,
    acc, ok)

def rq_cyl_valid(+v: Bool, +q: G.RQBez, +e: EP, +fr: FR, +sx: Bool,
    +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  match v:
    case False{}: LQ2{acc, False{}}
    case True{}: rq_cyl_emit(q, fr, sx, ep_ei(e), acc, ok)

def ce_qg_rq_go(+cyl: Bool, +q: G.RQBez, +e: EP, +fr: FR, +sx: Bool,
    +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  match cyl:
    case False{}: ce_qg_rq_pl(q, e, fr, acc, ok)
    case True{}: rq_cyl_valid(G.rq_valid(q), q, e, fr, sx, acc, ok)

def ce_qg_rq(+q: G.RQBez, +e: EP, +fr: FR, +sx: Bool, +acc: List<&2, QC.QG>,
    +ok: Bool) -> LQ2:
  ce_qg_rq_go(fr_cyl(fr), q, e, fr, sx, acc, ok)

def ce_qg_cc_go(+cyl: Bool, +cc: G.Circle3, +e: EP, +fr: FR, +sx: Bool, +acc: List<&2, QC.QG>,
    +ok: Bool) -> LQ2:
  match cyl:
    case False{}: cc_pl_half(cc, ep_a(e), fr, ep_fwd(e), ep_ei(e), acc, ok)
    case True{}: cc_cyl_emit(cc, fr, sx, ep_ei(e), acc, ok)

def ce_qg_cc(+cc: G.Circle3, +e: EP, +fr: FR, +sx: Bool, +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  ce_qg_cc_go(fr_cyl(fr), cc, e, fr, sx, acc, ok)

def ce_qg_tag(+tag: U64, +cv: G.GVal, +e: EP, +fr: FR, +sx: Bool,
    +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  match tag:
    case 0u64: ce_qg_ln(e, fr, sx, acc, ok)
    case 1u64: ce_qg_ln(e, fr, sx, acc, ok)
    case 2u64: ce_qg_rq(gv_rq_of(cv), e, fr, sx, acc, ok)
    case 3u64: ce_qg_cc(gv_cc_of(cv), e, fr, sx, acc, ok)
    case _: LQ2{acc, False{}}

def ce_qg_cv(+cv: G.GVal, +e: EP, +fr: FR, +sx: Bool, +acc: List<&2, QC.QG>,
    +ok: Bool) -> LQ2:
  ce_qg_tag(gv_tag(cv), cv, e, fr, sx, acc, ok)

def ce_qg_kind(+tag: U64, +e: EP, +ed: Ty.Edge, +fr: FR, +sx: Bool,
    +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  match tag:
    case 1u64: LQ2{acc, False{}}
    case _: ce_qg_cv(Ty.ekind_curve(Ty.ed_kind(ed)), e, fr, sx, acc, ok)

def ce_qg(+b: Ty.Brep, +h: Ty.HCoedge, +fr: FR, +sx: Bool, +acc: List<&2, QC.QG>,
    +ok: Bool) -> LQ2:
  +e = ce_ep(b, h)
  +ed = KU.nth_ed0(Ty.brep_es(b), ep_ei(e))
  ce_qg_kind(Ty.ekind_tag(Ty.ed_kind(ed)), e, ed, fr, sx, acc, ok)

def loop_qg_go(hs: List<&2, Ty.HCoedge>, +b: Ty.Brep, +fr: FR, +sx: Bool,
    +acc: List<&2, QC.QG>, +ok: Bool) -> LQ2:
  match hs:
    case []: LQ2{acc, ok}
    case +h <> t:
      +l = ce_qg(b, h, fr, sx, acc, ok)
      loop_qg_go(t, b, fr, sx, lq2_ps(l), lq2_ok(l))

type LQ is Data:
  LQ{ outer: List<&2, QC.QG>, holes: List<&2, List<&2, QC.QG>>, ok: Bool }

def lq_outer(+q: LQ) -> List<&2, QC.QG>:
  LQ{outer, holes, ok} = q
  outer

def lq_holes(+q: LQ) -> List<&2, List<&2, QC.QG>>:
  LQ{outer, holes, ok} = q
  holes

def lq_ok(+q: LQ) -> Bool:
  LQ{outer, holes, ok} = q
  ok

def face_qg_go(hs: List<&2, Ty.HLoop>, +b: Ty.Brep, +fr: FR, +sx: Bool,
    +outer: List<&2, QC.QG>, +holes: List<&2, List<&2, QC.QG>>, +ok: Bool, +has: Bool) -> LQ:
  match hs:
    case []: LQ{outer, holes, Bool.and(ok, has)}
    case +h <> +t:
      +lp = KU.nth_lp0(Ty.brep_lps(b), Ty.hlp_idx(h))
      +l = loop_qg_go(Ty.lp_ces(lp), b, fr, sx, [], True{})
      +ps = List.reverse(&2, QC.QG, lq2_ps(l))
      +isout = U64.is_eq(Ty.lkind_tag(Ty.lp_kind(lp)), 0u64)
      face_qg_go(t, b, fr, sx, Bool.pick(List<&2, QC.QG>, isout, ps, outer),
        Bool.pick(List<&2, List<&2, QC.QG>>, isout, holes, ps <> holes),
        Bool.and(ok, lq2_ok(l)), Bool.or(has, isout))

def face_qg(+b: Ty.Brep, +fi: Nat, +fr: FR, +sx: Bool) -> LQ:
  +fa = KU.nth_fa0(Ty.brep_fas(b), fi)
  face_qg_go(Ty.fa_loops(fa), b, fr, sx, [], [], True{}, False{})

type QLO is Data:
  QLO{ neg: List<&2, QC.QG>, pos: List<&2, QC.QG>, qc: QC.QC, ok: Bool }

def qlo_neg(+q: QLO) -> List<&2, QC.QG>:
  QLO{neg, pos, qc, ok} = q
  neg

def qlo_pos(+q: QLO) -> List<&2, QC.QG>:
  QLO{neg, pos, qc, ok} = q
  pos

def qlo_qc(+q: QLO) -> QC.QC:
  QLO{neg, pos, qc, ok} = q
  qc

def qlo_ok(+q: QLO) -> Bool:
  QLO{neg, pos, qc, ok} = q
  ok

def clip_one(ps: List<&2, QC.QG>, +cut: CUT, +qc: QC.QC) -> QLO:
  +r = QC.loop_clip_ln(ps, cut_vert(cut), cut_c(cut), cut_ci(cut), qc)
  +ql = QC.qr4_ql(r)
  QLO{QC.ql_neg(ql), QC.ql_pos(ql), QC.qr4_qc(r), QC.ql_ok(ql)}

def ql_push(+ps: List<&2, QC.QG>, +acc: List<&2, List<&2, QC.QG>>) -> List<&2, List<&2, QC.QG>>:
  match ps:
    case []: acc
    case +h <> t: (h <> t) <> acc

def ql_push2(+neg: List<&2, QC.QG>, +pos: List<&2, QC.QG>,
    +acc: List<&2, List<&2, QC.QG>>) -> List<&2, List<&2, QC.QG>>:
  ql_push(neg, ql_push(pos, acc))

type QLA is Data:
  QLA{ ls: List<&2, List<&2, QC.QG>>, qc: QC.QC, ok: Bool }

def qla_ls(+q: QLA) -> List<&2, List<&2, QC.QG>>:
  QLA{ls, qc, ok} = q
  ls

def qla_qc(+q: QLA) -> QC.QC:
  QLA{ls, qc, ok} = q
  qc

def qla_ok(+q: QLA) -> Bool:
  QLA{ls, qc, ok} = q
  ok

def clip_loops_go(ls: List<&2, List<&2, QC.QG>>, +cut: CUT, qc: QC.QC, +acc: List<&2, List<&2, QC.QG>>,
    +ok: Bool) -> QLA:
  match ls:
    case []: QLA{acc, qc, ok}
    case +h <> t:
      +r = clip_one(h, cut, qc)
      clip_loops_go(t, cut, qlo_qc(r), ql_push2(qlo_neg(r), qlo_pos(r), acc),
        Bool.and(ok, qlo_ok(r)))

def clip_loops(+ls: List<&2, List<&2, QC.QG>>, +cut: CUT, +qc: QC.QC) -> QLA:
  clip_loops_go(ls, cut, qc, [], True{})

type QLS is Data:
  QLS{ outs: List<&2, List<&2, QC.QG>>, holes: List<&2, List<&2, QC.QG>>, ok: Bool, why: U64 }

def qls_outs(+q: QLS) -> List<&2, List<&2, QC.QG>>:
  QLS{outs, holes, ok, why} = q
  outs

def qls_holes(+q: QLS) -> List<&2, List<&2, QC.QG>>:
  QLS{outs, holes, ok, why} = q
  holes

def qls_ok(+q: QLS) -> Bool:
  QLS{outs, holes, ok, why} = q
  ok

def qls_why(+q: QLS) -> U64:
  QLS{outs, holes, ok, why} = q
  why

def clip_cuts_go(cs: List<&2, CUT>, +outs: List<&2, List<&2, QC.QG>>,
    +holes: List<&2, List<&2, QC.QG>>, qc: QC.QC, +ok: Bool, +why: U64) -> QLS:
  match cs:
    case []: QLS{outs, holes, ok, why}
    case +h <> t:
      +ro = clip_loops(outs, h, qc)
      +rh = clip_loops(holes, h, qla_qc(ro))
      +ok2 = Bool.and(ok, Bool.and(qla_ok(ro), qla_ok(rh)))
      clip_cuts_go(t, qla_ls(ro), qla_ls(rh), qla_qc(rh), ok2, Bool.pick(U64, ok2, why, 10u64))

def clip_cuts(+cs: List<&2, CUT>, +outs: List<&2, List<&2, QC.QG>>, +holes: List<&2, List<&2, QC.QG>>,
    +qc: QC.QC) -> QLS:
  clip_cuts_go(cs, outs, holes, qc, True{}, 0u64)

def hole_xy(ps: List<&2, QC.QG>) -> V.Vec2:
  match ps:
    case []: V.V2{0.0f64, 0.0f64}
    case +q <> +t: QC.qg_mid(q)

def hole_idx_go(os: List<&2, List<&2, QC.QG>>, +hx: F64, +hy: F64, +at: Nat) -> Nat:
  match os:
    case []: at
    case +o <> +t:
      Bool.pick(Nat, U64.is_eq(QC.pip_loop(o, hx, hy), 1u64), at,
        hole_idx_go(t, hx, hy, Nat.add(at, 1n)))

type QFB is Data:
  QFB{ o: List<&2, QC.QG>, hs: List<&2, List<&2, QC.QG>> }

def qfb_o(+q: QFB) -> List<&2, QC.QG>:
  QFB{o, hs} = q
  o

def qfb_hs(+q: QFB) -> List<&2, List<&2, QC.QG>>:
  QFB{o, hs} = q
  hs

def qfb_init(os: List<&2, List<&2, QC.QG>>, +acc: List<&2, QFB>) -> List<&2, QFB>:
  match os:
    case []: acc
    case +o <> t: qfb_init(t, QFB{o, []} <> acc)

def qfb_add(qs: List<&2, QFB>, +h: List<&2, QC.QG>, +idx: Nat) -> List<&2, QFB>:
  match qs:
    case []: []
    case +q <> +t:
      Bool.pick(List<&2, QFB>, Nat.is_eq(idx, 0n), QFB{qfb_o(q), h <> qfb_hs(q)} <> t,
        q <> qfb_add(t, h, Nat.sub(idx, 1n)))

def qfb_holes_go(hs: List<&2, List<&2, QC.QG>>, +qs: List<&2, QFB>, +outs: List<&2, List<&2, QC.QG>>,
    +len: Nat) -> List<&2, QFB>:
  match hs:
    case []: qs
    case +h <> +t:
      +xy = hole_xy(h)
      +idx = hole_idx_go(outs, V.v2_x(xy), V.v2_y(xy), 0n)
      qfb_holes_go(t, Bool.pick(List<&2, QFB>, Nat.is_lt(idx, len), qfb_add(qs, h, idx), qs), outs,
        len)

def qfbs_to_qf(qs: List<&2, QFB>, +acc: List<&2, QC.QF>) -> List<&2, QC.QF>:
  match qs:
    case []: acc
    case +q <> t: qfbs_to_qf(t, QC.QF{qfb_o(q), qfb_hs(q)} <> acc)

def qf_assemble(+outs: List<&2, List<&2, QC.QG>>, +holes: List<&2, List<&2, QC.QG>>) -> List<&2, QC.QF>:
  +qs = qfb_init(outs, [])
  qfbs_to_qf(qfb_holes_go(holes, qs, outs, List.length(&2, List<&2, QC.QG>, outs)), [])

def nth_qg(xs: List<&2, QC.QG>, +i: Nat) -> QC.QG:
  match xs:
    case []: QC.qg_ln(0.0f64, 0.0f64, 0.0f64, 0.0f64, QC.lab_orig(), 0n)
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_qg(t, j)

def qf_hs_flat(hs: List<&2, List<&2, QC.QG>>) -> List<&2, QC.QG>:
  match hs:
    case []: []
    case +h <> t: List.append(&2, QC.QG, h, qf_hs_flat(t))

def qf_all(+o: List<&2, QC.QG>, +hs: List<&2, List<&2, QC.QG>>) -> List<&2, QC.QG>:
  List.append(&2, QC.QG, o, qf_hs_flat(hs))

def frag_aux2(+m0: V.Vec2, +m1: V.Vec2, +all: List<&2, QC.QG>) -> List<&2, V.Vec2>:
  +v0 = U64.is_eq(QC.pip_loop(all, V.v2_x(m0), V.v2_y(m0)), 1u64)
  +v1 = U64.is_eq(QC.pip_loop(all, V.v2_x(m1), V.v2_y(m1)), 1u64)
  Bool.pick(List<&2, V.Vec2>, v0, m0 <> Bool.pick(List<&2, V.Vec2>, v1, [m1], []),
    Bool.pick(List<&2, V.Vec2>, v1, [m1], []))

def frag_aux(+ps: List<&2, QC.QG>, +all: List<&2, QC.QG>) -> List<&2, V.Vec2>:
  frag_aux2(QC.qg_mid(nth_qg(ps, 0n)), QC.qg_mid(QC.qg_last(ps, nth_qg(ps, 0n))), all)

def frag_cls(+c: U64) -> U64:
  Bool.pick(U64, U64.is_eq(c, 0u64), KC.cls_out(),
    Bool.pick(U64, U64.is_eq(c, 1u64), KC.cls_in(), KC.cls_unc()))

def pt_cls(+p: V.Point, +fds: List<&2, SO.Fd>, +bb: List<&2, I.I>) -> U64:
  frag_cls(SO.classify_in(fds, bb, p))

def pr_ok(+r: PR) -> Bool:
  PR{ok, v} = r
  ok

def pr_v(+r: PR) -> V.Point:
  PR{ok, v} = r
  v

type PU is Data:
  PU{ ok: Bool, p: V.Point }

def pu_ok(+u: PU) -> Bool:
  PU{ok, p} = u
  ok

def pu_p(+u: PU) -> V.Point:
  PU{ok, p} = u
  p

def frag_unproj_cy(+p: V.Point, +surf: List<&2, G.GVal>, +ax: U64) -> PU:
  +r = snap_cy(KU.unbox_gv(surf), p, ax)
  PU{pr_ok(r), pr_v(r)}

def frag_unproj_go(+cyl: Bool, +v: V.Vec2, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>) -> PU:
  match cyl:
    case False{}: PU{True{}, unproj_pl(fr, V.v2_x(v), V.v2_y(v))}
    case True{}: frag_unproj_cy(sheet_unproj(fr, sx, V.v2_x(v), V.v2_y(v)), surf, fr_ax(fr))

def frag_unproj(+v: V.Vec2, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>) -> PU:
  frag_unproj_go(fr_cyl(fr), v, fr, sx, surf)

type BB2 is Data:
  BB2{ x0: F64, y0: F64, x1: F64, y1: F64 }

def qg_bbox_go(ps: List<&2, QC.QG>, +x0: F64, +y0: F64, +x1: F64, +y1: F64) -> BB2:
  match ps:
    case []: BB2{x0, y0, x1, y1}
    case +q <> t:
      qg_bbox_go(t, F64.min(x0, F64.min(QC.qg_ax(q), QC.qg_bx(q))),
        F64.min(y0, F64.min(QC.qg_ay(q), QC.qg_by(q))),
        F64.max(x1, F64.max(QC.qg_ax(q), QC.qg_bx(q))),
        F64.max(y1, F64.max(QC.qg_ay(q), QC.qg_by(q))))

def qg_bbox(+ps: List<&2, QC.QG>) -> BB2:
  qg_bbox_go(ps, 1.0e300f64, 1.0e300f64, F64.neg(1.0e300f64), F64.neg(1.0e300f64))

def bb_tiny(+b: BB2) -> F64:
  BB2{+x0, +y0, +x1, +y1} = b
  F64.mul(1.0e-24f64, F64.max(F64.mul(F64.sub(x1, x0), F64.sub(y1, y0)), 1.0e-300f64))

def frag_aux_cls_go(vs: List<&2, V.Vec2>, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +fds: List<&2, SO.Fd>,
    +bb: List<&2, I.I>, +acc: List<&2, U64>) -> List<&2, U64>:
  match vs:
    case []: acc
    case +h <> t:
      +u = frag_unproj(h, fr, sx, surf)
      frag_aux_cls_go(t, fr, sx, surf, fds, bb,
        Bool.pick(U64, pu_ok(u), pt_cls(pu_p(u), fds, bb), KC.cls_unc()) <> acc)

def frag_aux_cls(vs: List<&2, V.Vec2>, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +fds: List<&2, SO.Fd>,
    +bb: List<&2, I.I>) -> List<&2, U64>:
  frag_aux_cls_go(vs, fr, sx, surf, fds, bb, [])

def frag_keep_l2(+c0: U64, +c1: U64, cs: List<&2, U64>, +op: U64, +side: U64) -> U64:
  match cs:
    case []: KC.kfrag(op, side, c0, c1, KC.cls_unc())
    case +c2 <> +t: KC.kfrag(op, side, c0, c1, c2)

def frag_keep_ls(+c0: U64, cs: List<&2, U64>, +op: U64, +side: U64) -> U64:
  match cs:
    case []: KC.kfrag(op, side, c0, KC.cls_unc(), KC.cls_unc())
    case +c1 <> t: frag_keep_l2(c0, c1, t, op, side)

def frag_keep_none(+o: List<&2, QC.QG>, +tiny: F64) -> U64:
  Bool.pick(U64, F64.is_le(KU.fabs(QC.sh_signed(o)), tiny), 0u64, 2u64)

def frag_keep_some(+v: V.Vec2, +o: List<&2, QC.QG>, +all: List<&2, QC.QG>, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +bb: List<&2, I.I>) -> U64:
  +u = frag_unproj(v, fr, sx, surf)
  +c0 = Bool.pick(U64, pu_ok(u), pt_cls(pu_p(u), fds, bb), KC.cls_unc())
  frag_keep_ls(c0, frag_aux_cls(frag_aux(o, all), fr, sx, surf, fds, bb), op, side)

def frag_keep_m(+m: Maybe<&2, V.Vec2>, +o: List<&2, QC.QG>, +all: List<&2, QC.QG>, +fr: FR,
    +sx: Bool, +surf: List<&2, G.GVal>, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +bb: List<&2, I.I>,
    +tiny: F64) -> U64:
  match m:
    case None{}: frag_keep_none(o, tiny)
    case Some{+v}: frag_keep_some(v, o, all, fr, sx, surf, op, side, fds, bb)

def coprule_keep(+op: U64, +side: U64, +same: Bool) -> U64:
  Bool.pick(U64, U64.is_eq(op, 15u64),
    Bool.pick(U64, Bool.and(U64.is_eq(side, 0u64), Bool.not(same)), 1u64, 0u64),
    Bool.pick(U64, Bool.and(same, U64.is_eq(side, 0u64)), 1u64, 0u64))

def segx_opp(+a: U64, +b: U64) -> Bool:
  Bool.or(Bool.and(U64.is_eq(a, 0u64), U64.is_eq(b, 1u64)),
    Bool.and(U64.is_eq(a, 1u64), U64.is_eq(b, 0u64)))

def segx_pp_ln(+ll: Bool, +a: QC.QG, +p: QC.QG) -> Bool:
  match ll:
    case False{}: False{}
    case True{}:
      +o1 = QC.ori_sign(QC.qg_ax(a), QC.qg_ay(a), QC.qg_bx(a), QC.qg_by(a), QC.qg_ax(p),
        QC.qg_ay(p))
      +o2 = QC.ori_sign(QC.qg_ax(a), QC.qg_ay(a), QC.qg_bx(a), QC.qg_by(a), QC.qg_bx(p),
        QC.qg_by(p))
      +o3 = QC.ori_sign(QC.qg_ax(p), QC.qg_ay(p), QC.qg_bx(p), QC.qg_by(p), QC.qg_ax(a),
        QC.qg_ay(a))
      +o4 = QC.ori_sign(QC.qg_ax(p), QC.qg_ay(p), QC.qg_bx(p), QC.qg_by(p), QC.qg_bx(a),
        QC.qg_by(a))
      Bool.and(segx_opp(o1, o2), segx_opp(o3, o4))

def segx_pp(+a: QC.QG, +p: QC.QG) -> Bool:
  segx_pp_ln(Bool.and(QC.qg_is_ln(a), QC.qg_is_ln(p)), a, p)

def segx_row(+a: QC.QG, ps: List<&2, QC.QG>) -> Bool:
  match ps:
    case []: False{}
    case +p <> q: Bool.or(segx_pp(a, p), segx_row(a, q))

def segx_go(as: List<&2, QC.QG>, +po: List<&2, QC.QG>) -> Bool:
  match as:
    case []: False{}
    case +a <> t: Bool.or(segx_row(a, po), segx_go(t, po))

def ponest_go(ps: List<&2, QC.QG>, +f: QC.QF) -> Bool:
  match ps:
    case []: False{}
    case +p <> t:
      +ra = QC.pip_frag(f, QC.qg_ax(p), QC.qg_ay(p))
      +rb = QC.pip_frag(f, QC.qg_bx(p), QC.qg_by(p))
      Bool.or(Bool.or(U64.is_eq(ra, 1u64), U64.is_eq(rb, 1u64)), ponest_go(t, f))

def findout_go(ss: List<&2, QC.QG>, +po: List<&2, QC.QG>) -> Maybe<&2, V.Vec2>:
  match ss:
    case []: None{}
    case +s <> t:
      +ra = QC.pip_loop(po, QC.qg_ax(s), QC.qg_ay(s))
      +rb = QC.pip_loop(po, QC.qg_bx(s), QC.qg_by(s))
      +r = findout_go(t, po)
      Bool.pick(Maybe<&2, V.Vec2>, U64.is_eq(ra, 0u64), Some{V.V2{QC.qg_ax(s), QC.qg_ay(s)}},
        Bool.pick(Maybe<&2, V.Vec2>, U64.is_eq(rb, 0u64), Some{V.V2{QC.qg_bx(s), QC.qg_by(s)}},
          r))

def findin_go(ss: List<&2, QC.QG>, +po: List<&2, QC.QG>) -> Bool:
  match ss:
    case []: False{}
    case +s <> t:
      +ra = QC.pip_loop(po, QC.qg_ax(s), QC.qg_ay(s))
      +rb = QC.pip_loop(po, QC.qg_bx(s), QC.qg_by(s))
      Bool.or(Bool.or(U64.is_eq(ra, 1u64), U64.is_eq(rb, 1u64)), findin_go(t, po))

def frag_keep_po7(+iw: Bool, +o: List<&2, QC.QG>, +tiny: F64, +op: U64, +side: U64,
    +same: Bool) -> U64:
  match iw:
    case True{}: coprule_keep(op, side, same)
    case False{}: frag_keep_none(o, tiny)

def frag_keep_po6(+w: Maybe<&2, V.Vec2>, +o: List<&2, QC.QG>, +all: List<&2, QC.QG>, +fr: FR,
    +sx: Bool, +surf: List<&2, G.GVal>, +op: U64, +side: U64, +fds: List<&2, SO.Fd>,
    +bb: List<&2, I.I>, +tiny: F64, +po: List<&2, QC.QG>, +same: Bool) -> U64:
  match w:
    case None{}: frag_keep_po7(findin_go(o, po), o, tiny, op, side, same)
    case Some{+u}: frag_keep_some(u, o, all, fr, sx, surf, op, side, fds, bb)

def frag_keep_po5(+o: List<&2, QC.QG>, +all: List<&2, QC.QG>, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +bb: List<&2, I.I>,
    +tiny: F64, +po: List<&2, QC.QG>, +same: Bool) -> U64:
  frag_keep_po6(findout_go(all, po), o, all, fr, sx, surf, op, side, fds, bb, tiny, po, same)

def frag_keep_po4(+ci: U64, +v: V.Vec2, +o: List<&2, QC.QG>, +all: List<&2, QC.QG>, +fr: FR,
    +sx: Bool, +surf: List<&2, G.GVal>, +op: U64, +side: U64, +same: Bool, +fds: List<&2, SO.Fd>,
    +bb: List<&2, I.I>, +tiny: F64, +po: List<&2, QC.QG>) -> U64:
  match ci:
    case 0u64: frag_keep_some(v, o, all, fr, sx, surf, op, side, fds, bb)
    case 1u64: coprule_keep(op, side, same)
    case _: frag_keep_po5(o, all, fr, sx, surf, op, side, fds, bb, tiny, po, same)

def frag_keep_pob(+bad: Bool, +v: V.Vec2, +o: List<&2, QC.QG>, +all: List<&2, QC.QG>, +fr: FR,
    +sx: Bool, +surf: List<&2, G.GVal>, +op: U64, +side: U64, +same: Bool, +fds: List<&2, SO.Fd>,
    +bb: List<&2, I.I>, +tiny: F64, +po: List<&2, QC.QG>) -> U64:
  match bad:
    case True{}: 3u64
    case False{}:
      frag_keep_po4(QC.pip_loop(po, V.v2_x(v), V.v2_y(v)), v, o, all, fr, sx, surf, op,
        side, same, fds, bb, tiny, po)

def frag_keep_po(+m: Maybe<&2, V.Vec2>, +o: List<&2, QC.QG>, +all: List<&2, QC.QG>,
    +f: QC.QF, +po: List<&2, QC.QG>, +op: U64, +side: U64, +same: Bool, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +fds: List<&2, SO.Fd>, +bb: List<&2, I.I>, +tiny: F64) -> U64:
  match m:
    case None{}: frag_keep_none(o, tiny)
    case Some{+v}:
      +bad = Bool.or(QC.arcx_go(all, po), Bool.or(segx_go(all, po), ponest_go(po, f)))
      frag_keep_pob(bad, v, o, all, fr, sx, surf, op, side, same, fds, bb, tiny, po)

def frag_keep_pm(+hasm: Bool, +m: Maybe<&2, V.Vec2>, +o: List<&2, QC.QG>, +all: List<&2, QC.QG>,
    +f: QC.QF, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +bb: List<&2, I.I>, +tiny: F64, +po: List<&2, QC.QG>,
    +same: Bool) -> U64:
  match hasm:
    case False{}: frag_keep_m(m, o, all, fr, sx, surf, op, side, fds, bb, tiny)
    case True{}: frag_keep_po(m, o, all, f, po, op, side, same, fr, sx, surf, fds, bb, tiny)

def frag_keep(+f: QC.QF, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +bb: List<&2, I.I>, +tiny: F64, +po: List<&2, QC.QG>, +same: Bool,
    +hasm: Bool) -> U64:
  +o = QC.qf_outer(f)
  +hs = QC.qf_holes(f)
  +all = qf_all(o, hs)
  +m = QC.samp_find(all)
  frag_keep_pm(hasm, m, o, all, f, fr, sx, surf, op, side, fds, bb, tiny, po, same)

def cop_partner_go(ks: List<&2, KU.KA>, +fi: Nat, +side: U64, +acc: Nat) -> Nat:
  match ks:
    case []: acc
    case +h <> +t:
      +dec = KU.ka_dec(h)
      +mine = Bool.pick(Bool, U64.is_eq(side, 0u64), Nat.is_eq(KU.ka_fa(h), fi),
        Nat.is_eq(KU.ka_fb(h), fi))
      +segs = U64.is_eq(KC.dec_curve(dec), KC.ck_segs())
      cop_partner_go(t, fi, side, Bool.pick(Nat, Bool.and(mine, segs),
        Bool.pick(Nat, U64.is_eq(side, 0u64), KU.ka_fb(h), KU.ka_fa(h)), acc))

def cop_partner(+ks: List<&2, KU.KA>, +fi: Nat, +side: U64, +nf: Nat) -> Nat:
  cop_partner_go(ks, fi, side, nf)

def dir_eq3(+a: V.Dir, +b: V.Dir) -> Bool:
  Bool.and(F64.is_eq(V.dr_x(a), V.dr_x(b)),
    Bool.and(F64.is_eq(V.dr_y(a), V.dr_y(b)), F64.is_eq(V.dr_z(a), V.dr_z(b))))

def face_normal(+w: G.Plane3, +same: Bool) -> V.Dir:
  +n = KU.crx(G.pl_u(w), G.pl_v(w))
  Bool.pick(V.Dir, same, n, V.Dr{F64.neg(V.dr_x(n)), F64.neg(V.dr_y(n)), F64.neg(V.dr_z(n))})

def bb2_eq(+a: BB2, +b: BB2) -> Bool:
  BB2{+ax0, +ay0, +ax1, +ay1} = a
  BB2{+bx0, +by0, +bx1, +by1} = b
  Bool.and(F64.is_eq(ax0, bx0),
    Bool.and(F64.is_eq(ay0, by0), Bool.and(F64.is_eq(ax1, bx1), F64.is_eq(ay1, by1))))

def pip_inon(+ps: List<&2, QC.QG>, +x: F64, +y: F64) -> Bool:
  +r = QC.pip_loop(ps, x, y)
  Bool.or(U64.is_eq(r, 1u64), U64.is_eq(r, 2u64))

def cop_verts_in_go(ps: List<&2, QC.QG>, +o: List<&2, QC.QG>, +ok: Bool) -> Bool:
  match ps:
    case []: ok
    case +q <> +t:
      cop_verts_in_go(t, o, Bool.and(ok, Bool.and(pip_inon(o, QC.qg_ax(q), QC.qg_ay(q)),
        pip_inon(o, QC.qg_bx(q), QC.qg_by(q)))))

def cop_verts_in(+ps: List<&2, QC.QG>, +o: List<&2, QC.QG>) -> Bool:
  cop_verts_in_go(ps, o, True{})

def cop_ep_touch(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64, +dx: F64,
    +dy: F64) -> Bool:
  Bool.or(Bool.and(F64.is_eq(ax, cx), F64.is_eq(ay, cy)),
    Bool.or(Bool.and(F64.is_eq(ax, dx), F64.is_eq(ay, dy)),
      Bool.or(Bool.and(F64.is_eq(bx, cx), F64.is_eq(by, cy)),
        Bool.and(F64.is_eq(bx, dx), F64.is_eq(by, dy)))))

def cop_seg_ln(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64, +dx: F64,
    +dy: F64) -> Bool:
  +n = QC.seg_seg_n(ax, ay, bx, by, cx, cy, dx, dy)
  Bool.pick(Bool, U64.is_eq(n, 0u64), True{},
    Bool.pick(Bool, U64.is_eq(n, 1u64), cop_ep_touch(ax, ay, bx, by, cx, cy, dx, dy), False{}))

def cop_seg_ok(+a: QC.QG, +b: QC.QG) -> Bool:
  +ln = Bool.and(QC.qg_is_ln(a), QC.qg_is_ln(b))
  Bool.pick(Bool, ln, cop_seg_ln(QC.qg_ax(a), QC.qg_ay(a), QC.qg_bx(a), QC.qg_by(a), QC.qg_ax(b),
    QC.qg_ay(b), QC.qg_bx(b), QC.qg_by(b)), False{})

def cop_cross_row(qs: List<&2, QC.QG>, +p: QC.QG, +ok: Bool) -> Bool:
  match qs:
    case []: ok
    case +q <> +t: cop_cross_row(t, p, Bool.and(ok, cop_seg_ok(p, q)))

def cop_cross_go(ps: List<&2, QC.QG>, +qs: List<&2, QC.QG>, +ok: Bool) -> Bool:
  match ps:
    case []: ok
    case +p <> +t: cop_cross_go(t, qs, Bool.and(ok, cop_cross_row(qs, p, True{})))

def cop_cross(+ps: List<&2, QC.QG>, +qs: List<&2, QC.QG>) -> Bool:
  cop_cross_go(ps, qs, True{})

def cop_full(+oa: List<&2, QC.QG>, +ob: List<&2, QC.QG>) -> Bool:
  Bool.and(bb2_eq(qg_bbox(oa), qg_bbox(ob)),
    Bool.and(cop_verts_in(oa, ob), Bool.and(cop_verts_in(ob, oa), cop_cross(oa, ob))))

type CDP is Data:
  CDP{ ka: Bool, kb: Bool, ok: Bool }

def cop_decide(+op: U64, +ainB: Bool, +binA: Bool, +sameside: Bool) -> CDP:
  +touch = Bool.and(Bool.not(ainB), Bool.not(binA))
  Bool.pick(CDP, U64.is_eq(op, 14u64),
    Bool.pick(CDP, touch, CDP{False{}, False{}, False{}},
      Bool.pick(CDP, sameside, CDP{True{}, False{}, True{}}, CDP{False{}, False{}, True{}})),
    Bool.pick(CDP, U64.is_eq(op, 15u64), CDP{Bool.not(ainB), False{}, True{}},
      CDP{ainB, binA, True{}}))

def cop_off_pt(+p: V.Point, +n: V.Dir, +delta: F64) -> V.Point:
  V.Pt{F64.sub(V.pt_x(p), F64.mul(V.dr_x(n), delta)),
    F64.sub(V.pt_y(p), F64.mul(V.dr_y(n), delta)),
    F64.sub(V.pt_z(p), F64.mul(V.dr_z(n), delta))}

type CB is Data:
  CB{ inn: Bool, ok: Bool }

def cb_inn(+c: CB) -> Bool:
  CB{inn, ok} = c
  inn

def cb_ok(+c: CB) -> Bool:
  CB{inn, ok} = c
  ok

def cop_in_go(+c: U64) -> CB:
  match c:
    case 0u64: CB{False{}, True{}}
    case 1u64: CB{True{}, True{}}
    case _: CB{False{}, False{}}

def cop_probe(+p: V.Point, +n: V.Dir, +delta: F64, +fds: List<&2, SO.Fd>, +bb: List<&2, I.I>) -> CB:
  cop_in_go(SO.classify_in(fds, bb, cop_off_pt(p, n, delta)))

type EK is Data:
  EK{ va: Nat, vb: Nat, kind: U64, side: U64, id: Nat, idx: Nat }

type AS is Data:
  AS{ vs: List<&2, Ty.Vertex>, es: List<&2, Ty.Edge>, ces: List<&2, Ty.Coedge>,
    lps: List<&2, Ty.Loop>, fas: List<&2, Ty.Face>, eks: List<&2, EK>, nv: Nat, ne: Nat,
    nc: Nat, nl: Nat, nf: Nat, ms: List<&2, V.Point>, nm: Nat }

def as_vs(+a: AS) -> List<&2, Ty.Vertex>:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  vs

def as_es(+a: AS) -> List<&2, Ty.Edge>:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  es

def as_ces(+a: AS) -> List<&2, Ty.Coedge>:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  ces

def as_lps(+a: AS) -> List<&2, Ty.Loop>:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  lps

def as_fas(+a: AS) -> List<&2, Ty.Face>:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  fas

def as_eks(+a: AS) -> List<&2, EK>:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  eks

def as_nv(+a: AS) -> Nat:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  nv

def as_ne(+a: AS) -> Nat:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  ne

def as_nc(+a: AS) -> Nat:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  nc

def as_nl(+a: AS) -> Nat:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  nl

def as_nf(+a: AS) -> Nat:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  nf

def as_empty() -> AS:
  AS{[], [], [], [], [], [], 0n, 0n, 0n, 0n, 0n, [], 0n}

def as_ms(+a: AS) -> List<&2, V.Point>:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  ms

def as_nm(+a: AS) -> Nat:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  nm

def as_add_m(+a: AS, +p: V.Point) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = a
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, p <> ms, Nat.add(nm, 1n)}

def gen1(+i: Nat) -> U64:
  U64.from_nat(Nat.add(i, 1n))

def as_add_v(+a: AS, +p: V.Point) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = a
  AS{Ty.Vx{gen1(nv), p} <> vs, es, ces, lps, fas, eks, Nat.add(nv, 1n), ne, nc, nl, nf, ms, nm}

def as_add_e(+a: AS, +ed: Ty.Edge, +ek: EK) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = a
  Ty.Ed{+g, +v0, +v1, +k} = ed
  AS{vs, Ty.Ed{gen1(ne), v0, v1, k} <> es, ces, lps, fas, ek <> eks, nv, Nat.add(ne, 1n), nc, nl,
    nf, ms, nm}

def as_add_ek(+a: AS, +ek: EK) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = a
  AS{vs, es, ces, lps, fas, ek <> eks, nv, ne, nc, nl, nf, ms, nm}

def as_add_ce(+a: AS, +ce: Ty.Coedge) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = a
  Ty.Ce{+g, +e, +fwd, +trim} = ce
  AS{vs, es, Ty.Ce{gen1(nc), e, fwd, trim} <> ces, lps, fas, eks, nv, ne, Nat.add(nc, 1n), nl,
    nf, ms, nm}

def as_add_lp(+a: AS, +lp: Ty.Loop) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = a
  Ty.Lp{+g, +ces2, +kind} = lp
  AS{vs, es, ces, Ty.Lp{gen1(nl), ces2, kind} <> lps, fas, eks, nv, ne, nc, Nat.add(nl, 1n), nf, ms, nm}

def as_add_fa(+a: AS, +fa: Ty.Face) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = a
  Ty.Fa{+g, +surf, +loops, +same, +slv, +sla} = fa
  AS{vs, es, ces, lps, Ty.Fa{gen1(nf), surf, loops, same, slv, sla} <> fas, eks, nv, ne, nc, nl,
    Nat.add(nf, 1n), ms, nm}

type VR2 is Data:
  VR2{ idx: Nat, st: AS }

def vfind_go(vs: List<&2, Ty.Vertex>, +p: V.Point, +at: Nat) -> Nat:
  match vs:
    case []: at
    case +h <> +t: Bool.pick(Nat, pt_eq3(Ty.vx_p(h), p), at, vfind_go(t, p, Nat.add(at, 1n)))

def vbox_in(+a: V.Point, +b: V.Point, +eps: F64) -> Bool:
  Bool.and(F64.is_le(KU.fabs(F64.sub(V.pt_x(a), V.pt_x(b))), eps),
    Bool.and(F64.is_le(KU.fabs(F64.sub(V.pt_y(a), V.pt_y(b))), eps),
      F64.is_le(KU.fabs(F64.sub(V.pt_z(a), V.pt_z(b))), eps)))

def veps_go(vs: List<&2, Ty.Vertex>, +p: V.Point, +eps: F64, +at: Nat) -> Nat:
  match vs:
    case []: at
    case +h <> +t: Bool.pick(Nat, vbox_in(Ty.vx_p(h), p, eps), at,
      veps_go(t, p, eps, Nat.add(at, 1n)))

def vadopt_eps(+j: Nat, +st: AS, +p: V.Point, +n: Nat) -> VR2:
  Bool.pick(VR2, Nat.is_lt(j, n), VR2{Nat.sub(Nat.sub(n, 1n), j), st},
    VR2{n, as_add_v(st, p)})

def vadopt_go(+found: Bool, +st: AS, +p: V.Point, +eps: F64, +n: Nat, +i: Nat) -> VR2:
  match found:
    case True{}: VR2{Nat.sub(Nat.sub(n, 1n), i), st}
    case False{}: vadopt_eps(veps_go(as_vs(st), p, eps, 0n), st, p, n)

def vadopt(+st: AS, +p: V.Point, +eps: F64) -> VR2:
  +n = as_nv(st)
  +i = vfind_go(as_vs(st), p, 0n)
  vadopt_go(Nat.is_lt(i, n), st, p, eps, n, i)

def mfind_go(ps: List<&2, V.Point>, +p: V.Point, +i: Nat) -> Nat:
  match ps:
    case []: i
    case +h <> +t:
      Bool.pick(Nat, pt_eq3(h, p), i, mfind_go(t, p, Nat.add(i, 1n)))

def meps_go(ps: List<&2, V.Point>, +p: V.Point, +eps: F64, +i: Nat) -> Nat:
  match ps:
    case []: i
    case +h <> +t:
      Bool.pick(Nat, vbox_in(h, p, eps), i, meps_go(t, p, eps, Nat.add(i, 1n)))

def maddopt_m(+found: Bool, +st: AS, +p: V.Point, +e: Nat) -> VR2:
  match found:
    case True{}: VR2{e, st}
    case False{}: VR2{as_nm(st), as_add_m(st, p)}

def maddopt_e(+found: Bool, +st: AS, +p: V.Point, +eps: F64, +m: Nat) -> VR2:
  match found:
    case True{}: VR2{m, st}
    case False{}:
      +e = meps_go(as_ms(st), p, eps, 0n)
      +n = as_nm(st)
      maddopt_m(Nat.is_lt(e, n), st, p, Nat.sub(Nat.sub(n, 1n), e))

def maddopt(+st: AS, +p: V.Point, +eps: F64) -> VR2:
  +m = mfind_go(as_ms(st), p, 0n)
  +n = as_nm(st)
  maddopt_e(Nat.is_lt(m, n), st, p, eps, Nat.sub(Nat.sub(n, 1n), m))

def ek_match(+e: EK, +va: Nat, +vb: Nat, +kind: U64, +side: U64, +id: Nat) -> Bool:
  EK{+a, +b, +k, +s, +i, +x} = e
  Bool.and(Bool.or(Bool.and(Nat.is_eq(a, va), Nat.is_eq(b, vb)),
      Bool.and(Nat.is_eq(a, vb), Nat.is_eq(b, va))),
    Bool.and(U64.is_eq(k, kind), Bool.and(U64.is_eq(s, side), Nat.is_eq(i, id))))

def ek_idx(+e: EK) -> Nat:
  EK{+a, +b, +k, +s, +i, +x} = e
  x

def efind_go(es: List<&2, EK>, +va: Nat, +vb: Nat, +kind: U64, +side: U64, +id: Nat,
    +dflt: Nat) -> Nat:
  match es:
    case []: dflt
    case +h <> +t: Bool.pick(Nat, ek_match(h, va, vb, kind, side, id), ek_idx(h),
      efind_go(t, va, vb, kind, side, id, dflt))

type ER is Data:
  ER{ idx: Nat, st: AS }

def eemit_go(+found: Bool, +f: Nat, +st: AS, +va: Nat, +vb: Nat, +kind: U64, +side: U64,
    +id: Nat, +ed: Ty.Edge) -> ER:
  match found:
    case True{}: ER{f, st}
    case False{}: ER{as_ne(st), as_add_e(st, ed, EK{va, vb, kind, side, id, as_ne(st)})}

def eemit(+st: AS, +va: Nat, +vb: Nat, +kind: U64, +side: U64, +id: Nat, +ed: Ty.Edge) -> ER:
  +n = as_ne(st)
  +f = efind_go(as_eks(st), va, vb, kind, side, id, n)
  eemit_go(Nat.is_lt(f, n), f, st, va, vb, kind, side, id, ed)

def ealias(+st: AS, +va: Nat, +vb: Nat, +kind: U64, +side: U64, +id: Nat, +idx: Nat) -> AS:
  as_add_ek(st, EK{va, vb, kind, side, id, idx})

def ekind_rq(+a: V.Point, +c: V.Point, +b: V.Point, +w: F64) -> Ty.EdgeKind:
  Ty.EK_curve{G.GV_rq{G.Rq{a, c, b, 1.0f64, w, 1.0f64}}, G.Dom{0.0f64, 1.0f64}}

def vr_idx(+r: VR2) -> Nat:
  VR2{idx, st} = r
  idx

def vr_st(+r: VR2) -> AS:
  VR2{idx, st} = r
  st

def er_idx(+r: ER) -> Nat:
  ER{idx, st} = r
  idx

def er_st(+r: ER) -> AS:
  ER{idx, st} = r
  st

def nth_vs(xs: List<&2, Ty.Vertex>, +i: Nat) -> Ty.Vertex:
  match xs:
    case []: Ty.Vx{0u64, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_vs(t, j)

def pt_of(+st: AS, +i: Nat) -> V.Point:
  Ty.vx_p(nth_vs(as_vs(st), Nat.sub(Nat.sub(as_nv(st), 1n), i)))

def nth_ms(xs: List<&2, V.Point>, +i: Nat) -> V.Point:
  match xs:
    case []: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_ms(t, j)

def pt_mid(+st: AS, +i: Nat) -> V.Point:
  nth_ms(as_ms(st), Nat.sub(Nat.sub(as_nm(st), 1n), i))

def dir_ax(+ax: U64) -> V.Dir:
  Bool.pick(V.Dir, U64.is_eq(ax, 0u64), V.Dr{1.0f64, 0.0f64, 0.0f64},
    Bool.pick(V.Dir, U64.is_eq(ax, 1u64), V.Dr{0.0f64, 1.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 1.0f64}))

def gv_pl_of(+g: G.GVal) -> G.Plane3:
  match g:
    case G.GV_pl{+w}: w
    case _: G.Pl{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 1.0f64, 0.0f64}}

def gv_cy_of(+g: G.GVal) -> G.Cyl:
  match g:
    case G.GV_cy{+w}: w
    case _: G.Cy{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 0.0f64}

def face_n_u(+surf: G.GVal, +same: Bool, +fr: FR) -> V.Dir:
  Bool.pick(V.Dir, fr_cyl(fr), dir_ax(fr_ax(fr)),
    face_normal(gv_pl_of(surf), same))

def face_n(+surf: List<&2, G.GVal>, +same: Bool, +fr: FR) -> V.Dir:
  match surf:
    case s <> _: face_n_u(s, same, fr)
    case []: dir_ax(fr_ax(fr))

type ASE is Data:
  ASE{ st: AS, ok: Bool, why: U64 }

def ase_st(+a: ASE) -> AS:
  ASE{st, ok, why} = a
  st

def ase_ok(+a: ASE) -> Bool:
  ASE{st, ok, why} = a
  ok

def ase_why(+a: ASE) -> U64:
  ASE{st, ok, why} = a
  why

type PUP is Data:
  PUP{ oka: Bool, okb: Bool, pa: V.Point, pb: V.Point }

def pup_oka(+u: PUP) -> Bool:
  PUP{oka, okb, pa, pb} = u
  oka

def pup_okb(+u: PUP) -> Bool:
  PUP{oka, okb, pa, pb} = u
  okb

def pup_pa(+u: PUP) -> V.Point:
  PUP{oka, okb, pa, pb} = u
  pa

def pup_pb(+u: PUP) -> V.Point:
  PUP{oka, okb, pa, pb} = u
  pb

def emit_unproj(+q: QC.QG, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>) -> PUP:
  +ua = frag_unproj(V.V2{QC.qg_ax(q), QC.qg_ay(q)}, fr, sx, surf)
  +ub = frag_unproj(V.V2{QC.qg_bx(q), QC.qg_by(q)}, fr, sx, surf)
  PUP{pu_ok(ua), pu_ok(ub), pu_p(ua), pu_p(ub)}

type PEA is Data:
  PEA{ va: Nat, vb: Nat, st: AS }

def pea_va(+r: PEA) -> Nat:
  PEA{va, vb, st} = r
  va

def pea_vb(+r: PEA) -> Nat:
  PEA{va, vb, st} = r
  vb

def pea_st(+r: PEA) -> AS:
  PEA{va, vb, st} = r
  st

def emit_adopt(+pa: V.Point, +pb: V.Point, +st: AS, +eps: F64) -> PEA:
  +ra = vadopt(st, pa, eps)
  +rb = vadopt(vr_st(ra), pb, eps)
  PEA{vr_idx(ra), vr_idx(rb), vr_st(rb)}

type EFU is Data:
  EFU{ full: Bool, oa: Nat, ob: Nat, st: AS }

def efu_full(+r: EFU) -> Bool:
  EFU{full, oa, ob, st} = r
  full

def efu_oa(+r: EFU) -> Nat:
  EFU{full, oa, ob, st} = r
  oa

def efu_ob(+r: EFU) -> Nat:
  EFU{full, oa, ob, st} = r
  ob

def efu_st(+r: EFU) -> AS:
  EFU{full, oa, ob, st} = r
  st

def emit_full(+ed: Ty.Edge, +b: Ty.Brep, +st: AS, +eps: F64, +va: Nat, +vb: Nat) -> EFU:
  +vs = Ty.brep_vs(b)
  +p0 = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v0(ed))))
  +p1 = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v1(ed))))
  +ra = vadopt(st, p0, eps)
  +rb = vadopt(vr_st(ra), p1, eps)
  +oa = vr_idx(ra)
  +ob = vr_idx(rb)
  +full = Bool.or(Bool.and(Nat.is_eq(va, oa), Nat.is_eq(vb, ob)),
    Bool.and(Nat.is_eq(va, ob), Nat.is_eq(vb, oa)))
  EFU{full, oa, ob, vr_st(rb)}

type PE is Data:
  PE{ eis: List<&2, Nat>, svs: List<&2, Nat>, st: AS, ok: Bool, why: U64 }

def emit_degen_cv(+ctag: U64, +kind: Ty.EdgeKind, +va: Nat, +ei: Nat, +side: U64, +st: AS) -> PE:
  match ctag:
    case 3u64:
      +r = eemit(st, va, va, 5u64, side, ei, Ty.Ed{0u64, hv(va), hv(va), kind})
      PE{[er_idx(r)], [va], er_st(r), True{}, 0u64}
    case _: PE{[], [], st, True{}, 0u64}

def emit_degen_cc(+tag: U64, +kind: Ty.EdgeKind, +va: Nat, +ei: Nat, +side: U64, +st: AS) -> PE:
  match tag:
    case 1u64: PE{[], [], st, True{}, 0u64}
    case _: emit_degen_cv(gv_tag(Ty.ekind_curve(kind)), kind, va, ei, side, st)

def emit_degen_og(+q: QC.QG, +side: U64, +ba: Ty.Brep, +bb: Ty.Brep, +va: Nat, +st: AS) -> PE:
  +b = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), ba, bb)
  +ed = KU.nth_ed0(Ty.brep_es(b), QC.qg_ref(q))
  emit_degen_cc(Ty.ekind_tag(Ty.ed_kind(ed)), Ty.ed_kind(ed), va, QC.qg_ref(q), side, st)

def emit_piece_degen(+q: QC.QG, +side: U64, +ba: Ty.Brep, +bb: Ty.Brep, +va: Nat, +st: AS) -> PE:
  +lab = U64.is_eq(QC.qg_lab(q), QC.lab_orig())
  Bool.pick(PE, lab, emit_degen_og(q, side, ba, bb, va, st), PE{[], [], st, True{}, 0u64})

def ctrl_c(+a: F64, +m: F64, +b: F64) -> F64:
  F64.sub(F64.add(m, m), F64.mul(0.5f64, F64.add(a, b)))

def fit_ctrl(+a: V.Point, +m: V.Point, +b: V.Point) -> V.Point:
  V.Pt{ctrl_c(V.pt_x(a), V.pt_x(m), V.pt_x(b)), ctrl_c(V.pt_y(a), V.pt_y(m), V.pt_y(b)),
    ctrl_c(V.pt_z(a), V.pt_z(m), V.pt_z(b))}

def rq_hs(+pa: V.Point, +pm: V.Point, +pb: V.Point) -> V.Vec2:
  +h = F64.mul(0.5f64, GO.d3_norm_raw(GO.pp_sub_raw(pb, pa)))
  +cm = GO.plerp_raw(pa, pb, 0.5f64, 0.5f64)
  V.V2{h, GO.d3_norm_raw(GO.pp_sub_raw(pm, cm))}

def rq_circ_w(+h: F64, +s: F64) -> F64:
  +r = F64.div(F64.add(F64.mul(h, h), F64.mul(s, s)), F64.add(s, s))
  +d2 = F64.sub(F64.mul(r, r), F64.mul(h, h))
  F64.div(F64.sqrt(Bool.pick(F64, F64.is_lt(d2, 0.0f64), 0.0f64, d2)), r)

def rq_ctrl(+pa: V.Point, +pm: V.Point, +pb: V.Point, +w: F64) -> V.Point:
  +cm = GO.plerp_raw(pa, pb, 0.5f64, 0.5f64)
  GO.pd_add_raw(pm, F64.div(1.0f64, w), GO.pp_sub_raw(pm, cm))

def emit_refit_er(+va: Nat, +vb: Nat, +vm: Nat, +pa: V.Point, +pm: V.Point, +pb: V.Point,
    +w: F64, +st: AS) -> ER:
  +c = rq_ctrl(pa, pm, pb, w)
  +k = ekind_rq(pa, c, pb, w)
  eemit(st, va, vb, 6u64, 2u64, vm, Ty.Ed{0u64, hv(va), hv(vb), k})

def emit_refit_ww(+va: Nat, +vb: Nat, +vm: Nat, +pa: V.Point, +pm: V.Point,
    +pb: V.Point, +w: F64, +st: AS) -> PE:
  +er = emit_refit_er(va, vb, vm, pa, pm, pb, w, st)
  PE{[er_idx(er)], [va], er_st(er), True{}, 0u64}

def emit_refit_ln(+ln: Bool, +va: Nat, +vb: Nat, +vm: Nat, +pa: V.Point, +pm: V.Point,
    +pb: V.Point, +hs: V.Vec2, +st: AS) -> PE:
  match ln:
    case True{}:
      +c = fit_ctrl(pa, pm, pb)
      +er = eemit(st, va, vb, 6u64, 2u64, vm, Ty.Ed{0u64, hv(va), hv(vb), ekind_rq(pa, c, pb, 1.0f64)})
      PE{[er_idx(er)], [va], er_st(er), True{}, 0u64}
    case False{}:
      +w = rq_circ_w(V.v2_x(hs), V.v2_y(hs))
      Bool.pick(PE, F64.is_eq(w, 0.0f64), PE{[], [], st, False{}, 46u64},
        emit_refit_ww(va, vb, vm, pa, pm, pb, w, st))

def emit_refit_degen(+dg: Bool, +va: Nat, +vb: Nat, +vm: Nat, +pa: V.Point, +pm: V.Point,
    +pb: V.Point, +hs: V.Vec2, +eps: F64, +st: AS) -> PE:
  match dg:
    case True{}: PE{[], [], st, False{}, 46u64}
    case False{}:
      emit_refit_ln(F64.is_le(V.v2_y(hs), F64.mul(eps, V.v2_x(hs))), va, vb, vm, pa, pm,
        pb, hs, st)

def emit_refit_um(+okm: Bool, +pm0: V.Point, +va: Nat, +vb: Nat, +st: AS, +side: U64,
    +eps: F64) -> PE:
  match okm:
    case False{}: PE{[], [], st, False{}, 15u64}
    case True{}:
      +rm = maddopt(st, pm0, eps)
      +vm = vr_idx(rm)
      +st1 = vr_st(rm)
      +pa = pt_of(st1, va)
      +pm = pt_mid(st1, vm)
      +pb = pt_of(st1, vb)
      +hs = rq_hs(pa, pm, pb)
      emit_refit_degen(F64.is_eq(V.v2_x(hs), 0.0f64), va, vb, vm, pa, pm, pb, hs, eps, st1)

def emit_refit_path(+va: Nat, +vb: Nat, +st: AS, +q: QC.QG, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +side: U64, +eps: F64) -> PE:
  +um = frag_unproj(QC.qg_mid(q), fr, sx, surf)
  emit_refit_um(pu_ok(um), pu_p(um), va, vb, st, side, eps)

def emit_piece_ogc(+full: Bool, +oa: Nat, +ob: Nat, +st: AS, +va: Nat, +vb: Nat, +q: QC.QG,
    +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64, +ed: Ty.Edge, +eps: F64) -> PE:
  match full:
    case True{}:
      +k = Ty.ed_kind(ed)
      +ee = eemit(st, va, vb, 5u64, side, QC.qg_ref(q), Ty.Ed{0u64, hv(oa), hv(ob), k})
      PE{[er_idx(ee)], [va], er_st(ee), True{}, 0u64}
    case False{}: emit_refit_path(va, vb, st, q, fr, sx, surf, side, eps)

def emit_piece_og5(+st: AS, +va: Nat, +vb: Nat, +q: QC.QG, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +side: U64, +ba: Ty.Brep, +bb: Ty.Brep, +ed: Ty.Edge,
    +eps: F64) -> PE:
  +b = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), ba, bb)
  +fu = emit_full(ed, b, st, eps, va, vb)
  emit_piece_ogc(efu_full(fu), efu_oa(fu), efu_ob(fu), efu_st(fu), va, vb, q, fr, sx, surf,
    side, ed, eps)

def ekind_ln(+a: V.Point, +d: V.Dir) -> Ty.EdgeKind:
  Ty.EK_curve{G.GV_ln{G.Ln{a, d}}, G.Dom{0.0f64, 1.0f64}}

def cc_mk(+c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64) -> G.Circle3:
  G.Cc{c, u, v, r}

def ekind_cc(+c: G.Circle3) -> Ty.EdgeKind:
  Ty.EK_curve{G.GV_cc{c}, G.Dom{F64.neg(1.0f64), 1.0f64}}

def cc_vert_pt(+c: G.Circle3) -> V.Point:
  GO.pd_add_raw(G.cc_c(c), F64.neg(G.cc_r(c)), G.cc_u(c))

def cc_edge(+st: AS, +v: Nat, +c: G.Circle3, +kind: U64, +side: U64, +id: Nat) -> ER:
  eemit(st, v, v, kind, side, id, Ty.Ed{0u64, hv(v), hv(v), ekind_cc(c)})

def emit_ln_er(+va: Nat, +vb: Nat, +pa: V.Point, +pb: V.Point, +st: AS) -> ER:
  +k = ekind_ln(pa, GO.pp_sub_raw(pb, pa))
  eemit(st, va, vb, 7u64, 2u64, 0n,
    Ty.Ed{0u64, hv(va), hv(vb), k})

def emit_ln_go(+va: Nat, +vb: Nat, +st: AS) -> PE:
  +pa = pt_of(st, va)
  +pb = pt_of(st, vb)
  +er = emit_ln_er(va, vb, pa, pb, st)
  PE{[er_idx(er)], [va], er_st(er), True{}, 0u64}

def emit_piece_go(+va: Nat, +vb: Nat, +st: AS, +q: QC.QG, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +side: U64, +ba: Ty.Brep, +bb: Ty.Brep, +ed: Ty.Edge, +isog: Bool,
    +eps: F64) -> PE:
  match isog:
    case True{}:
      +tag = gv_tag(Ty.ekind_curve(Ty.ed_kind(ed)))
      +flat = Bool.not(fr_cyl(fr))
      Bool.pick(PE, Bool.and(U64.is_eq(tag, 0u64), flat), emit_ln_go(va, vb, st),
        Bool.pick(PE, U64.is_eq(tag, 0u64), emit_refit_path(va, vb, st, q, fr, sx, surf,
          side, eps),
          emit_piece_og5(st, va, vb, q, fr, sx, surf, side, ba, bb, ed, eps)))
    case False{}:
      Bool.pick(PE, Bool.and(Bool.not(fr_cyl(fr)), QC.qg_is_ln(q)), emit_ln_go(va, vb, st),
        emit_refit_path(va, vb, st, q, fr, sx, surf, side, eps))

def emit_piece_ad(+va: Nat, +vb: Nat, +st: AS, +q: QC.QG, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +side: U64, +ba: Ty.Brep, +bb: Ty.Brep, +ed: Ty.Edge, +isog: Bool,
    +eps: F64) -> PE:
  Bool.pick(PE, Nat.is_eq(va, vb), emit_piece_degen(q, side, ba, bb, va, st),
    emit_piece_go(va, vb, st, q, fr, sx, surf, side, ba, bb, ed, isog, eps))

def emit_piece_pre_go(+lab: Bool, +pa: V.Point, +pb: V.Point, +q: QC.QG, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +side: U64, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64) -> PE:
  match lab:
    case True{}:
      +b = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), ba, bb)
      +ed = KU.nth_ed0(Ty.brep_es(b), QC.qg_ref(q))
      +vs = Ty.brep_vs(b)
      +p0 = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v0(ed))))
      +p1 = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v1(ed))))
      +r0 = vadopt(st, p0, eps)
      +r1 = vadopt(vr_st(r0), p1, eps)
      +ad = emit_adopt(pa, pb, vr_st(r1), eps)
      emit_piece_ad(pea_va(ad), pea_vb(ad), pea_st(ad), q, fr, sx, surf, side, ba, bb, ed,
        True{}, eps)
    case False{}:
      +ad = emit_adopt(pa, pb, st, eps)
      emit_piece_ad(pea_va(ad), pea_vb(ad), pea_st(ad), q, fr, sx, surf, side, ba, bb,
        Ty.Ed{0u64, hv(0n), hv(0n), Ty.EK_degenerate{}}, False{}, eps)

def emit_piece_pre(+pa: V.Point, +pb: V.Point, +q: QC.QG, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +side: U64, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64) -> PE:
  emit_piece_pre_go(U64.is_eq(QC.qg_lab(q), QC.lab_orig()), pa, pb, q, fr, sx, surf, side,
    ba, bb, st, eps)

def emit_piece_ub(+okb: Bool, +pa: V.Point, +pb: V.Point, +q: QC.QG, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +side: U64, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64) -> PE:
  match okb:
    case False{}: PE{[], [], st, False{}, 14u64}
    case True{}: emit_piece_pre(pa, pb, q, fr, sx, surf, side, ba, bb, st, eps)

def emit_piece_up(+oka: Bool, +okb: Bool, +pa: V.Point, +pb: V.Point, +q: QC.QG, +fr: FR,
    +sx: Bool, +surf: List<&2, G.GVal>, +side: U64, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS,
    +eps: F64) -> PE:
  match oka:
    case False{}: PE{[], [], st, False{}, 14u64}
    case True{}: emit_piece_ub(okb, pa, pb, q, fr, sx, surf, side, ba, bb, st, eps)

def emit_piece(+q: QC.QG, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64, +ba: Ty.Brep,
    +bb: Ty.Brep, +st: AS, +eps: F64) -> PE:
  +up = emit_unproj(q, fr, sx, surf)
  emit_piece_up(pup_oka(up), pup_okb(up), pup_pa(up), pup_pb(up), q, fr, sx, surf, side, ba,
    bb, st, eps)

def pe_eis(+r: PE) -> List<&2, Nat>:
  PE{eis, svs, st, ok, why} = r
  eis

def pe_svs(+r: PE) -> List<&2, Nat>:
  PE{eis, svs, st, ok, why} = r
  svs

def pe_st(+r: PE) -> AS:
  PE{eis, svs, st, ok, why} = r
  st

def pe_ok(+r: PE) -> Bool:
  PE{eis, svs, st, ok, why} = r
  ok

def pe_why(+r: PE) -> U64:
  PE{eis, svs, st, ok, why} = r
  why

def tb_c(+a: F64, +m: F64, +b: F64) -> F64:
  F64.div(F64.sub(F64.sub(F64.mul(8.0f64, m), a), b), 6.0f64)

def tb_b1(+a: V.Vec2, +m: V.Vec2, +b: V.Vec2) -> V.Vec2:
  V.V2{tb_c(V.v2_x(a), V.v2_x(m), V.v2_x(b)), tb_c(V.v2_y(a), V.v2_y(m), V.v2_y(b))}

def trim_tb(+a: V.Vec2, +m: V.Vec2, +b: V.Vec2) -> G.GVal:
  +b1 = tb_b1(a, m, b)
  G.GV_tb{G.Tb{a, b1, b1, b}}

def piece_trim_go(+isln: Bool, +a: V.Vec2, +m: V.Vec2, +b: V.Vec2) -> G.GVal:
  match isln:
    case True{}: G.GV_ts{G.Ts{a, b}}
    case False{}: trim_tb(a, m, b)

def piece_trim(+q: QC.QG, +sva: Nat, +eva: Nat) -> G.GVal:
  +a = QC.qg_a(q)
  +b = QC.qg_b(q)
  +m = QC.qg_mid_true(q)
  +ln = QC.qg_is_ln(q)
  Bool.pick(G.GVal, Nat.is_eq(sva, eva), piece_trim_go(ln, a, m, b),
    piece_trim_go(ln, b, m, a))

type LP3 is Data:
  LP3{ ei: Nat, sv: Nat, q: QC.QG }

def lp3_ei(+r: LP3) -> Nat:
  LP3{ei, sv, q} = r
  ei

def lp3_sv(+r: LP3) -> Nat:
  LP3{ei, sv, q} = r
  sv

def lp3_q(+r: LP3) -> QC.QG:
  LP3{ei, sv, q} = r
  q

def lp3_push(es: List<&2, Nat>, ss: List<&2, Nat>, +q: QC.QG, +acc: List<&2, LP3>) -> List<&2, LP3>:
  match es:
    case []: acc
    case +e <> +et:
      match ss:
        case []: acc
        case +s <> +st: LP3{e, s, q} <> acc

type LE is Data:
  LE{ ps: List<&2, LP3>, st: AS, ok: Bool, why: U64 }

def le_ps(+r: LE) -> List<&2, LP3>:
  LE{ps, st, ok, why} = r
  ps

def le_st(+r: LE) -> AS:
  LE{ps, st, ok, why} = r
  st

def le_ok(+r: LE) -> Bool:
  LE{ps, st, ok, why} = r
  ok

def le_why(+r: LE) -> U64:
  LE{ps, st, ok, why} = r
  why

def emit_pieces_go(ps: List<&2, QC.QG>, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64,
    +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64, +acc: List<&2, LP3>, +ok: Bool,
    +why: U64) -> LE:
  match ps:
    case []: LE{List.reverse(&2, LP3, acc), st, ok, why}
    case +h <> +t:
      +r = emit_piece(h, fr, sx, surf, side, ba, bb, st, eps)
      emit_pieces_go(t, fr, sx, surf, side, ba, bb, pe_st(r), eps,
        lp3_push(pe_eis(r), pe_svs(r), h, acc), Bool.and(ok, pe_ok(r)),
        Bool.pick(U64, ok, pe_why(r), why))

def emit_pieces(ps: List<&2, QC.QG>, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64,
    +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64) -> LE:
  emit_pieces_go(ps, fr, sx, surf, side, ba, bb, st, eps, [], True{}, 0u64)

type LC is Data:
  LC{ st: AS, hcs: List<&2, Ty.HCoedge>, ok: Bool }

def lc_st(+r: LC) -> AS:
  LC{st, hcs, ok} = r
  st

def lc_hcs(+r: LC) -> List<&2, Ty.HCoedge>:
  LC{st, hcs, ok} = r
  hcs

def lc_ok(+r: LC) -> Bool:
  LC{st, hcs, ok} = r
  ok

def loop_ces_go(ps: List<&2, LP3>, +st: AS, +cur: Nat, +start: Nat, +started: Bool,
    +hcs: List<&2, Ty.HCoedge>, +ok: Bool) -> LC:
  match ps:
    case []:
      LC{st, List.reverse(&2, Ty.HCoedge, hcs),
        Bool.and(ok, Bool.and(started, Nat.is_eq(cur, start)))}
    case +h <> +t:
      +c0 = Bool.pick(Nat, started, cur, lp3_sv(h))
      +s0 = Bool.pick(Nat, started, start, lp3_sv(h))
      +ed = KU.nth_ed0(as_es(st), Nat.sub(Nat.sub(as_ne(st), 1n), lp3_ei(h)))
      +eva = Ty.hv_idx(Ty.ed_v0(ed))
      +evb = Ty.hv_idx(Ty.ed_v1(ed))
      +fw = Nat.is_eq(eva, c0)
      +bk = Nat.is_eq(evb, c0)
      +trim = piece_trim(lp3_q(h), lp3_sv(h), eva)
      +ci = as_nc(st)
      +st1 = as_add_ce(st, Ty.Ce{0u64, he(lp3_ei(h)), fw, trim})
      loop_ces_go(t, st1, Bool.pick(Nat, fw, evb, eva), s0, True{}, hc(ci) <> hcs,
        Bool.and(ok, Bool.or(fw, bk)))

def loop_ces(ps: List<&2, LP3>, +st: AS) -> LC:
  loop_ces_go(ps, st, 0n, 0n, False{}, [], True{})

type LOP is Data:
  LOP{ st: AS, hl: Ty.HLoop, ok: Bool, why: U64 }

def lop_st(+r: LOP) -> AS:
  LOP{st, hl, ok, why} = r
  st

def lop_hl(+r: LOP) -> Ty.HLoop:
  LOP{st, hl, ok, why} = r
  hl

def lop_ok(+r: LOP) -> Bool:
  LOP{st, hl, ok, why} = r
  ok

def lop_why(+r: LOP) -> U64:
  LOP{st, hl, ok, why} = r
  why

def emit_loop_lc(+lc: LC, +pok: Bool, +pwhy: U64, +kind: Ty.LoopKind, +nps: Nat) -> LOP:
  +ok = Bool.and(pok, lc_ok(lc))
  +li = as_nl(lc_st(lc))
  +st1 = as_add_lp(lc_st(lc), Ty.Lp{0u64, lc_hcs(lc), kind})
  LOP{st1, hlp(li), ok, Bool.pick(U64, ok, 0u64, Bool.pick(U64, pok, 35u64, pwhy))}

def halves_closed2(+a: QC.QG, +b: QC.QG) -> Bool:
  Bool.and(Bool.not(QC.qg_is_ln(a)), Bool.and(Bool.not(QC.qg_is_ln(b)),
    Bool.and(U64.is_eq(QC.qg_lab(a), QC.lab_newar()), Bool.and(U64.is_eq(QC.qg_lab(b), QC.lab_newar()),
      Bool.and(Nat.is_eq(QC.qg_ref(a), QC.qg_ref(b)),
        Bool.and(F64.is_eq(QC.qg_cx(a), QC.qg_cx(b)), Bool.and(F64.is_eq(QC.qg_cy(a), QC.qg_cy(b)),
          Bool.and(F64.is_eq(QC.qg_cr(a), QC.qg_cr(b)),
            Bool.and(F64.is_eq(QC.qg_ax(a), QC.qg_bx(b)), Bool.and(F64.is_eq(QC.qg_ay(a), QC.qg_by(b)),
              Bool.and(F64.is_eq(QC.qg_bx(a), QC.qg_ax(b)), F64.is_eq(QC.qg_by(a), QC.qg_ay(b)))))))))))))

def emit_loop_closed2(+h1: QC.QG, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>,
    +side: U64, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64, +kind: Ty.LoopKind) -> LOP:
  match sx:
    case True{}: LOP{st, hlp(as_nl(st)), False{}, 35u64}
    case False{}:
      +cc = cc_mk(unproj_pl(fr, QC.qg_cx(h1), QC.qg_cy(h1)), dir_ax(run0_ax(fr_ax(fr))),
        dir_ax(run1_ax(fr_ax(fr))), QC.qg_cr(h1))
      +rv = vadopt(st, cc_vert_pt(cc), eps)
      +er = cc_edge(vr_st(rv), vr_idx(rv), cc, 8u64, 2u64, 0n)
      +fw = QC.qg_ccw(h1)
      +uvx = F64.sub(QC.qg_cx(h1), QC.qg_cr(h1))
      +uvy = QC.qg_cy(h1)
      +ci = as_nc(er_st(er))
      +st1 = as_add_ce(er_st(er),
        Ty.Ce{0u64, he(er_idx(er)), fw, G.GV_ts{G.Ts{V.V2{uvx, uvy}, V.V2{uvx, uvy}}}})
      +li = as_nl(st1)
      LOP{as_add_lp(st1, Ty.Lp{0u64, [hc(ci)], kind}), hlp(li), True{}, 0u64}

def halves_closed_orig(+a: QC.QG, +b: QC.QG) -> Bool:
  Bool.and(Bool.not(QC.qg_is_ln(a)), Bool.and(Bool.not(QC.qg_is_ln(b)),
    Bool.and(U64.is_eq(QC.qg_lab(a), QC.lab_orig()),
      Bool.and(U64.is_eq(QC.qg_lab(b), QC.lab_orig()),
        Bool.and(Nat.is_eq(QC.qg_ref(a), QC.qg_ref(b)),
          Bool.and(F64.is_eq(QC.qg_cx(a), QC.qg_cx(b)),
            Bool.and(F64.is_eq(QC.qg_cy(a), QC.qg_cy(b)),
              Bool.and(F64.is_eq(QC.qg_cr(a), QC.qg_cr(b)),
                Bool.and(F64.is_eq(QC.qg_ax(a), QC.qg_bx(b)),
                  Bool.and(F64.is_eq(QC.qg_ay(a), QC.qg_by(b)),
                    Bool.and(F64.is_eq(QC.qg_bx(a), QC.qg_ax(b)),
                      F64.is_eq(QC.qg_by(a), QC.qg_ay(b)))))))))))))

def emit_loop_closed_og(+isc: Bool, +h1: QC.QG, +ed: Ty.Edge, +v3: V.Point, +st: AS,
    +side: U64, +ref: Nat, +eps: F64, +kind: Ty.LoopKind) -> LOP:
  match isc:
    case False{}: LOP{st, hlp(as_nl(st)), False{}, 46u64}
    case True{}:
      +rv = vadopt(st, v3, eps)
      +vr = vr_idx(rv)
      +er = eemit(vr_st(rv), vr, vr, 5u64, side, ref,
        Ty.Ed{0u64, hv(vr), hv(vr), Ty.ed_kind(ed)})
      +fw = QC.qg_ccw(h1)
      +uvx = F64.sub(QC.qg_cx(h1), QC.qg_cr(h1))
      +uvy = QC.qg_cy(h1)
      +ci = as_nc(er_st(er))
      +st1 = as_add_ce(er_st(er),
        Ty.Ce{0u64, he(er_idx(er)), fw, G.GV_ts{G.Ts{V.V2{uvx, uvy}, V.V2{uvx, uvy}}}})
      +li = as_nl(st1)
      LOP{as_add_lp(st1, Ty.Lp{0u64, [hc(ci)], kind}), hlp(li), True{}, 0u64}

def emit_loop_closed_orig(+h1: QC.QG, +side: U64, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS,
    +eps: F64, +kind: Ty.LoopKind) -> LOP:
  +b = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), ba, bb)
  +ref = QC.qg_ref(h1)
  +ed = KU.nth_ed0(Ty.brep_es(b), ref)
  +v3 = Ty.vx_p(KU.nth_vx0(Ty.brep_vs(b), Ty.hv_idx(Ty.ed_v0(ed))))
  emit_loop_closed_og(U64.is_eq(gv_tag(Ty.ekind_curve(Ty.ed_kind(ed))), 3u64), h1, ed,
    v3, st, side, ref, eps, kind)

def emit_loop_open(ps: List<&2, QC.QG>, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64,
    +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64, +kind: Ty.LoopKind) -> LOP:
  +le = emit_pieces(QC.pieces_split(ps), fr, sx, surf, side, ba, bb, st, eps)
  +lc = loop_ces(le_ps(le), le_st(le))
  emit_loop_lc(lc, le_ok(le), le_why(le), kind, List.length(&2, LP3, le_ps(le)))

def halves_have_arc(+a: QC.QG, +b: QC.QG) -> Bool:
  Bool.or(Bool.not(QC.qg_is_ln(a)), Bool.not(QC.qg_is_ln(b)))

def halves_meet(+a: QC.QG, +b: QC.QG) -> Bool:
  Bool.and(F64.is_eq(QC.qg_bx(a), QC.qg_ax(b)), Bool.and(F64.is_eq(QC.qg_by(a), QC.qg_ay(b)),
    Bool.and(F64.is_eq(QC.qg_bx(b), QC.qg_ax(a)), F64.is_eq(QC.qg_by(b), QC.qg_ay(a)))))

def emit_loop_tt(+h1: QC.QG, +h2: QC.QG, t2: List<&2, QC.QG>, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +side: U64, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64,
    +kind: Ty.LoopKind) -> LOP:
  match t2:
    case []:
      Bool.pick(LOP, halves_closed2(h1, h2),
        emit_loop_closed2(h1, fr, sx, surf, side, ba, bb, st, eps, kind),
        Bool.pick(LOP, halves_closed_orig(h1, h2),
          emit_loop_closed_orig(h1, side, ba, bb, st, eps, kind),
          Bool.pick(LOP, halves_meet(h1, h2),
            emit_loop_open(h1 <> h2 <> [], fr, sx, surf, side, ba, bb, st, eps, kind),
            Bool.pick(LOP, halves_have_arc(h1, h2), LOP{st, hlp(as_nl(st)), False{}, 46u64},
              emit_loop_open(h1 <> h2 <> [], fr, sx, surf, side, ba, bb, st, eps, kind)))))
    case +h <> t: emit_loop_open(h1 <> h2 <> h <> t, fr, sx, surf, side, ba, bb, st, eps, kind)

def emit_loop_tl(+h1: QC.QG, t: List<&2, QC.QG>, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>,
    +side: U64, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64, +kind: Ty.LoopKind) -> LOP:
  match t:
    case []: emit_loop_open(h1 <> [], fr, sx, surf, side, ba, bb, st, eps, kind)
    case +h2 <> t2: emit_loop_tt(h1, h2, t2, fr, sx, surf, side, ba, bb, st, eps, kind)

def emit_loop(ps: List<&2, QC.QG>, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64,
    +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64, +kind: Ty.LoopKind) -> LOP:
  match ps:
    case []: emit_loop_open([], fr, sx, surf, side, ba, bb, st, eps, kind)
    case +h1 <> t: emit_loop_tl(h1, t, fr, sx, surf, side, ba, bb, st, eps, kind)

type LF is Data:
  LF{ st: AS, loops: List<&2, Ty.HLoop>, ok: Bool, why: U64 }

def lf_st(+r: LF) -> AS:
  LF{st, loops, ok, why} = r
  st

def lf_loops(+r: LF) -> List<&2, Ty.HLoop>:
  LF{st, loops, ok, why} = r
  loops

def lf_ok(+r: LF) -> Bool:
  LF{st, loops, ok, why} = r
  ok

def lf_why(+r: LF) -> U64:
  LF{st, loops, ok, why} = r
  why

def emit_qf_hs(hs: List<&2, List<&2, QC.QG>>, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64,
    +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64, +hls: List<&2, Ty.HLoop>, +ok: Bool,
    +why: U64) -> LF:
  match hs:
    case []: LF{st, hls, ok, why}
    case +h <> +t:
      +r = emit_loop(h, fr, sx, surf, side, ba, bb, st, eps, Ty.LK_inner{})
      emit_qf_hs(t, fr, sx, surf, side, ba, bb, lop_st(r), eps, lop_hl(r) <> hls,
        Bool.and(ok, lop_ok(r)), Bool.pick(U64, ok, lop_why(r), why))

def emit_qf(+f: QC.QF, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64, +ba: Ty.Brep,
    +bb: Ty.Brep, +st: AS, +eps: F64) -> LF:
  +ro = emit_loop(QC.qf_outer(f), fr, sx, surf, side, ba, bb, st, eps, Ty.LK_outer{})
  emit_qf_hs(QC.qf_holes(f), fr, sx, surf, side, ba, bb, lop_st(ro), eps, [lop_hl(ro)],
    lop_ok(ro), lop_why(ro))

def canon_o(+ax: U64, +c: F64) -> V.Point:
  Bool.pick(V.Point, U64.is_eq(ax, 0u64), V.Pt{c, 0.0f64, 0.0f64},
    Bool.pick(V.Point, U64.is_eq(ax, 1u64), V.Pt{0.0f64, c, 0.0f64}, V.Pt{0.0f64, 0.0f64, c}))

def canon_u(+ax: U64) -> V.Dir:
  Bool.pick(V.Dir, U64.is_eq(ax, 0u64), V.Dr{0.0f64, 1.0f64, 0.0f64},
    Bool.pick(V.Dir, U64.is_eq(ax, 1u64), V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{1.0f64, 0.0f64, 0.0f64}))

def canon_v(+ax: U64) -> V.Dir:
  Bool.pick(V.Dir, U64.is_eq(ax, 2u64), V.Dr{0.0f64, 1.0f64, 0.0f64},
    V.Dr{0.0f64, 0.0f64, 1.0f64})

def canon_n(+ax: U64) -> V.Dir:
  Bool.pick(V.Dir, U64.is_eq(ax, 0u64), V.Dr{1.0f64, 0.0f64, 0.0f64},
    Bool.pick(V.Dir, U64.is_eq(ax, 1u64), V.Dr{0.0f64, F64.neg(1.0f64), 0.0f64},
      V.Dr{0.0f64, 0.0f64, 1.0f64}))

type CS is Data:
  CS{ surf: List<&2, G.GVal>, same: Bool }

def cs_surf(+r: CS) -> List<&2, G.GVal>:
  CS{surf, same} = r
  surf

def cs_same(+r: CS) -> Bool:
  CS{surf, same} = r
  same

def canon_pl(+w: G.Plane3, +same: Bool, +ax: U64, +c: F64) -> CS:
  CS{[G.GV_pl{G.Pl{canon_o(ax, c), canon_u(ax), canon_v(ax)}}],
    dir_eq3(face_normal(w, same), canon_n(ax))}

def canon_face_u(+surf: G.GVal, +same: Bool, +fr: FR) -> CS:
  Bool.pick(CS, fr_cyl(fr), CS{[surf], same},
    canon_pl(gv_pl_of(surf), same, fr_ax(fr), fr_c(fr)))

def canon_face(+surf: List<&2, G.GVal>, +same: Bool, +fr: FR) -> CS:
  match surf:
    case s <> _: canon_face_u(s, same, fr)
    case []: CS{[], same}

def rg_ci(+r: RG) -> Nat:
  RG{ci, cc} = r
  ci

def rg_cc(+r: RG) -> G.Circle3:
  RG{ci, cc} = r
  cc

def ring_halves(+cx: F64, +cy: F64, +cr: F64, +ci: Nat, +flip: Bool) -> List<&2, QC.QG>:
  +vx = F64.add(cx, cr)
  +mx = F64.sub(cx, cr)
  Bool.pick(List<&2, QC.QG>, flip,
    [QC.qg_ar(vx, cy, mx, cy, cx, cy, cr, False{}, QC.lab_newar(), ci),
      QC.qg_ar(mx, cy, vx, cy, cx, cy, cr, False{}, QC.lab_newar(), ci)],
    [QC.qg_ar(vx, cy, mx, cy, cx, cy, cr, True{}, QC.lab_newar(), ci),
      QC.qg_ar(mx, cy, vx, cy, cx, cy, cr, True{}, QC.lab_newar(), ci)])

def pw2(+px: F64, +py: F64, +cx: F64, +cy: F64) -> F64:
  F64.add(F64.mul(F64.sub(px, cx), F64.sub(px, cx)), F64.mul(F64.sub(py, cy), F64.sub(py, cy)))

def side_cc(+px: F64, +py: F64, +cx: F64, +cy: F64, +cr: F64) -> U64:
  +d = pw2(px, py, cx, cy)
  +r2 = F64.mul(cr, cr)
  Bool.pick(U64, F64.is_eq(d, r2), 2u64, Bool.pick(U64, F64.is_lt(d, r2), 1u64, 0u64))

def qg_is_cc(+q: QC.QG, +cx: F64, +cy: F64, +cr: F64) -> Bool:
  Bool.and(Bool.not(QC.qg_is_ln(q)), Bool.and(F64.is_eq(QC.qg_cx(q), cx),
    Bool.and(F64.is_eq(QC.qg_cy(q), cy), F64.is_eq(QC.qg_cr(q), cr))))

def loop_is_cc_go(ps: List<&2, QC.QG>, +cx: F64, +cy: F64, +cr: F64, +ok: Bool) -> Bool:
  match ps:
    case []: ok
    case +h <> +t: loop_is_cc_go(t, cx, cy, cr, Bool.and(ok, qg_is_cc(h, cx, cy, cr)))

def loop_is_cc(ps: List<&2, QC.QG>, +cx: F64, +cy: F64, +cr: F64) -> Bool:
  match ps:
    case []: False{}
    case +h <> +t: loop_is_cc_go(t, cx, cy, cr, qg_is_cc(h, cx, cy, cr))

def qg_cross_cc_ln(+q: QC.QG, +cx: F64, +cy: F64, +cr: F64) -> Bool:
  Bool.not(U64.is_eq(QC.circ_seg_n(cx, cy, cr, QC.qg_ax(q), QC.qg_ay(q), QC.qg_bx(q),
    QC.qg_by(q)), 0u64))

def qg_cross_cc_ar(+q: QC.QG, +cx: F64, +cy: F64, +cr: F64) -> Bool:
  +sa = side_cc(QC.qg_ax(q), QC.qg_ay(q), cx, cy, cr)
  +sb = side_cc(QC.qg_bx(q), QC.qg_by(q), cx, cy, cr)
  +m = QC.qg_mid(q)
  +sm = side_cc(V.v2_x(m), V.v2_y(m), cx, cy, cr)
  +mix = Bool.or(Bool.or(Bool.and(U64.is_eq(sa, 0u64), U64.is_eq(sb, 1u64)),
      Bool.and(U64.is_eq(sa, 1u64), U64.is_eq(sb, 0u64))), Bool.or(U64.is_eq(sa, 2u64),
      Bool.or(U64.is_eq(sb, 2u64), U64.is_eq(sm, 2u64))))
  +mixm = Bool.or(mix, Bool.or(Bool.and(U64.is_eq(sm, 0u64), Bool.or(U64.is_eq(sa, 1u64),
      U64.is_eq(sb, 1u64))), Bool.and(U64.is_eq(sm, 1u64), Bool.or(U64.is_eq(sa, 0u64),
      U64.is_eq(sb, 0u64)))))
  +dd = pw2(QC.qg_cx(q), QC.qg_cy(q), cx, cy)
  +rr = F64.add(cr, QC.qg_cr(q))
  +dr = KU.fabs(F64.sub(cr, QC.qg_cr(q)))
  +e = F64.mul(0.000000001f64, F64.add(1.0f64, dd))
  +touch = Bool.and(F64.is_le(F64.sub(F64.mul(dr, dr), e), dd),
    F64.is_le(dd, F64.add(F64.mul(rr, rr), e)))
  Bool.or(mixm, touch)

def qg_cross_cc(+q: QC.QG, +cx: F64, +cy: F64, +cr: F64) -> Bool:
  Bool.pick(Bool, QC.qg_is_ln(q), qg_cross_cc_ln(q, cx, cy, cr),
    qg_cross_cc_ar(q, cx, cy, cr))

def loop_cross_cc_go(ps: List<&2, QC.QG>, +cx: F64, +cy: F64, +cr: F64, +hit: Bool) -> Bool:
  match ps:
    case []: hit
    case +h <> +t: loop_cross_cc_go(t, cx, cy, cr, Bool.or(hit, qg_cross_cc(h, cx, cy, cr)))

def loop_cross_cc(ps: List<&2, QC.QG>, +cx: F64, +cy: F64, +cr: F64) -> Bool:
  loop_cross_cc_go(ps, cx, cy, cr, False{})

def loop_side_all_go(ps: List<&2, QC.QG>, +cx: F64, +cy: F64, +cr: F64, +want: U64,
    +ok: Bool) -> Bool:
  match ps:
    case []: ok
    case +h <> +t:
      +oa = U64.is_eq(side_cc(QC.qg_ax(h), QC.qg_ay(h), cx, cy, cr), want)
      +ob = U64.is_eq(side_cc(QC.qg_bx(h), QC.qg_by(h), cx, cy, cr), want)
      loop_side_all_go(t, cx, cy, cr, want, Bool.and(ok, Bool.and(oa, ob)))

def loop_side_all(ps: List<&2, QC.QG>, +cx: F64, +cy: F64, +cr: F64, +want: U64) -> Bool:
  match ps:
    case []: False{}
    case +h <> +t:
      +oa = U64.is_eq(side_cc(QC.qg_ax(h), QC.qg_ay(h), cx, cy, cr), want)
      +ob = U64.is_eq(side_cc(QC.qg_bx(h), QC.qg_by(h), cx, cy, cr), want)
      loop_side_all_go(t, cx, cy, cr, want, Bool.and(oa, ob))

type HRC is Data:
  HRC{ out: List<&2, List<&2, QC.QG>>, inn: List<&2, List<&2, QC.QG>>, code: U64 }

def hrc_out(+r: HRC) -> List<&2, List<&2, QC.QG>>:
  HRC{out, inn, code} = r
  out

def hrc_inn(+r: HRC) -> List<&2, List<&2, QC.QG>>:
  HRC{out, inn, code} = r
  inn

def hrc_code(+r: HRC) -> U64:
  HRC{out, inn, code} = r
  code

def hole_vs_cc(+h: List<&2, QC.QG>, +cx: F64, +cy: F64, +cr: F64) -> U64:
  +cross = loop_cross_cc(h, cx, cy, cr)
  +coin = loop_is_cc(h, cx, cy, cr)
  +pip = QC.pip_loop(h, cx, cy)
  +ain = loop_side_all(h, cx, cy, cr, 1u64)
  +aout = loop_side_all(h, cx, cy, cr, 0u64)
  Bool.pick(U64, cross, 3u64, Bool.pick(U64, coin, 2u64,
    Bool.pick(U64, U64.is_eq(pip, 1u64),
      Bool.pick(U64, ain, 1u64, Bool.pick(U64, aout, 2u64, 3u64)),
      Bool.pick(U64, U64.is_eq(pip, 0u64),
        Bool.pick(U64, ain, 1u64, Bool.pick(U64, aout, 0u64, 3u64)),
        Bool.pick(U64, ain, 1u64, 3u64)))))

def holes_vs_cc_go(hs: List<&2, List<&2, QC.QG>>, +cx: F64, +cy: F64, +cr: F64,
    +out: List<&2, List<&2, QC.QG>>, +inn: List<&2, List<&2, QC.QG>>, +code: U64) -> HRC:
  match hs:
    case []: HRC{out, inn, code}
    case +h <> +t:
      +c = hole_vs_cc(h, cx, cy, cr)
      +code2 = Bool.pick(U64, U64.is_eq(c, 3u64), 3u64,
        Bool.pick(U64, U64.is_eq(code, 3u64), 3u64,
          Bool.pick(U64, Bool.or(U64.is_eq(c, 2u64), U64.is_eq(code, 2u64)), 2u64, 0u64)))
      holes_vs_cc_go(t, cx, cy, cr,
        Bool.pick(List<&2, List<&2, QC.QG>>, U64.is_eq(c, 0u64), h <> out, out),
        Bool.pick(List<&2, List<&2, QC.QG>>, U64.is_eq(c, 1u64), h <> inn, inn), code2)

def holes_vs_cc(hs: List<&2, List<&2, QC.QG>>, +cx: F64, +cy: F64, +cr: F64) -> HRC:
  holes_vs_cc_go(hs, cx, cy, cr, [], [], 0u64)

type RLS is Data:
  RLS{ ok: Bool, why: U64, qfs: List<&2, QC.QF> }

def rls_ok(+r: RLS) -> Bool:
  RLS{ok, why, qfs} = r
  ok

def rls_why(+r: RLS) -> U64:
  RLS{ok, why, qfs} = r
  why

def rls_qfs(+r: RLS) -> List<&2, QC.QF>:
  RLS{ok, why, qfs} = r
  qfs

def ring_split_fin(+f: QC.QF, +o: List<&2, QC.QG>, +hout: List<&2, List<&2, QC.QG>>,
    +hinn: List<&2, List<&2, QC.QG>>, +bad: Bool, +void: Bool, +oalg: U64, +sgn: F64,
    +cx: F64, +cy: F64, +cr: F64, +ci: Nat) -> RLS:
  Bool.pick(RLS, bad, RLS{False{}, 33u64, []},
    Bool.pick(RLS, Bool.or(void, U64.is_eq(oalg, 0u64)), RLS{True{}, 0u64, [f]},
      Bool.pick(RLS, U64.is_eq(oalg, 1u64),
        RLS{True{}, 0u64,
          [QC.QF{o, ring_halves(cx, cy, cr, ci, F64.is_lt(0.0f64, sgn)) <> hout},
            QC.QF{ring_halves(cx, cy, cr, ci, F64.is_lt(sgn, 0.0f64)), hinn}]},
        RLS{False{}, 33u64, []})))

def ring_split_oalg_co(+co: U64, +oin: Bool, +oout: Bool) -> U64:
  match co:
    case 1u64:
      match oin:
        case True{}: 0u64
        case False{}:
          match oout:
            case True{}: 1u64
            case False{}: 3u64
    case 0u64: 0u64
    case _:
      match oin:
        case True{}: 0u64
        case False{}: 3u64

def ring_split_oalg(+ccoin: Bool, +co: U64, +oin: Bool, +oout: Bool) -> U64:
  match ccoin:
    case True{}: 0u64
    case False{}: ring_split_oalg_co(co, oin, oout)

def ring_split_go(+f: QC.QF, +o: List<&2, QC.QG>, +hout: List<&2, List<&2, QC.QG>>,
    +hinn: List<&2, List<&2, QC.QG>>, +hcode: U64, +co: U64, +oin: Bool, +oout: Bool,
    +ccoin: Bool, +ccross: Bool, +sgn: F64, +cx: F64, +cy: F64, +cr: F64, +ci: Nat) -> RLS:
  +bad = Bool.or(U64.is_eq(hcode, 3u64), Bool.and(ccross, Bool.not(ccoin)))
  +void = U64.is_eq(hcode, 2u64)
  ring_split_fin(f, o, hout, hinn, bad, void, ring_split_oalg(ccoin, co, oin, oout), sgn,
    cx, cy, cr, ci)

def venn_frag_side(+m: Maybe<&2, V.Vec2>, +cx: F64, +cy: F64, +cr: F64) -> U64:
  match m:
    case None{}: 2u64
    case Some{+v}: QC.pow_sign(V.v2_x(v), V.v2_y(v), cx, cy, cr)

def venn_hole_in(+m: Maybe<&2, V.Vec2>, +o: List<&2, QC.QG>) -> Bool:
  match m:
    case None{}: False{}
    case Some{+v}: U64.is_eq(QC.pip_loop(o, V.v2_x(v), V.v2_y(v)), 1u64)

def venn_att_hole(+h: List<&2, QC.QG>, +o: List<&2, QC.QG>, +fs: U64, +side: U64,
    +cx: F64, +cy: F64, +cr: F64) -> Bool:
  Bool.and(U64.is_eq(fs, side), venn_hole_in(QC.samp_find(h), o))

def venn_att_qf_go(hs: List<&2, List<&2, QC.QG>>, +o: List<&2, QC.QG>,
    +qh: List<&2, List<&2, QC.QG>>, +fs: U64, +side: U64, +cx: F64, +cy: F64, +cr: F64,
    +acc: List<&2, List<&2, QC.QG>>) -> QC.QF:
  match hs:
    case []: QC.QF{o, List.append(&2, List<&2, QC.QG>, qh, acc)}
    case +h <> +t:
      venn_att_qf_go(t, o, qh, fs, side, cx, cy, cr,
        Bool.pick(List<&2, List<&2, QC.QG>>, venn_att_hole(h, o, fs, side, cx, cy, cr),
          h <> acc, acc))

def venn_att_qf(+qf: QC.QF, +hs: List<&2, List<&2, QC.QG>>, +side: U64, +cx: F64, +cy: F64,
    +cr: F64) -> QC.QF:
  +o = QC.qf_outer(qf)
  venn_att_qf_go(hs, o, QC.qf_holes(qf), venn_frag_side(QC.samp_find(o), cx, cy, cr), side,
    cx, cy, cr, [])

def venn_attach_go(qfs: List<&2, QC.QF>, +hs: List<&2, List<&2, QC.QG>>, +side: U64,
    +cx: F64, +cy: F64, +cr: F64, +acc: List<&2, QC.QF>) -> List<&2, QC.QF>:
  match qfs:
    case []: List.reverse(&2, QC.QF, acc)
    case +h <> +t: venn_attach_go(t, hs, side, cx, cy, cr, venn_att_qf(h, hs, side, cx, cy, cr) <> acc)

def venn_attach(+qfs: List<&2, QC.QF>, +hout: List<&2, List<&2, QC.QG>>,
    +hinn: List<&2, List<&2, QC.QG>>, +cx: F64, +cy: F64, +cr: F64) -> List<&2, QC.QF>:
  venn_attach_go(venn_attach_go(qfs, hout, 0u64, cx, cy, cr, []), hinn, 1u64, cx, cy, cr, [])

def ring_split_vn99(+is99: Bool, +f: QC.QF, +o: List<&2, QC.QG>,
    +hout: List<&2, List<&2, QC.QG>>, +hinn: List<&2, List<&2, QC.QG>>, +oalg: U64,
    +sgn: F64, +cx: F64, +cy: F64, +cr: F64, +ci: Nat) -> RLS:
  match is99:
    case True{}: ring_split_fin(f, o, hout, hinn, False{}, False{}, oalg, sgn, cx, cy, cr, ci)
    case False{}: RLS{False{}, 33u64, []}

def ring_split_vnok(+ok: Bool, +why: U64, +qfs: List<&2, QC.QF>, +f: QC.QF,
    +o: List<&2, QC.QG>, +hout: List<&2, List<&2, QC.QG>>, +hinn: List<&2, List<&2, QC.QG>>,
    +oalg: U64, +sgn: F64, +cx: F64, +cy: F64, +cr: F64, +ci: Nat) -> RLS:
  match ok:
    case True{}: RLS{True{}, 0u64, venn_attach(qfs, hout, hinn, cx, cy, cr)}
    case False{}: ring_split_vn99(U64.is_eq(why, 99u64), f, o, hout, hinn, oalg, sgn, cx, cy,
      cr, ci)

def ring_split_venn(+vn: QC.QS, +f: QC.QF, +o: List<&2, QC.QG>,
    +hout: List<&2, List<&2, QC.QG>>, +hinn: List<&2, List<&2, QC.QG>>, +oalg: U64,
    +sgn: F64, +cx: F64, +cy: F64, +cr: F64, +ci: Nat) -> RLS:
  ring_split_vnok(QC.qs_is_ok(vn), QC.qs_why(vn), QC.qs_frags(vn), f, o, hout, hinn, oalg,
    sgn, cx, cy, cr, ci)

def ring_split_docross(+docross: Bool, +f: QC.QF, +o: List<&2, QC.QG>,
    +hout: List<&2, List<&2, QC.QG>>, +hinn: List<&2, List<&2, QC.QG>>, +hcode: U64,
    +co: U64, +oin: Bool, +oout: Bool, +ccoin: Bool, +ccross: Bool, +sgn: F64, +cx: F64,
    +cy: F64, +cr: F64, +ci: Nat) -> RLS:
  match docross:
    case False{}:
      ring_split_go(f, o, hout, hinn, hcode, co, oin, oout, ccoin, ccross, sgn, cx, cy, cr, ci)
    case True{}:
      ring_split_venn(QC.venn_split(o, cx, cy, cr, ci), f, o, hout, hinn,
        ring_split_oalg(ccoin, co, oin, oout), sgn, cx, cy, cr, ci)

def ring_split_qf(+f: QC.QF, +cx: F64, +cy: F64, +cr: F64, +ci: Nat) -> RLS:
  +o = QC.qf_outer(f)
  +hs = QC.qf_holes(f)
  +co = QC.pip_loop(o, cx, cy)
  +oin = loop_side_all(o, cx, cy, cr, 1u64)
  +oout = loop_side_all(o, cx, cy, cr, 0u64)
  +ccoin = loop_is_cc(o, cx, cy, cr)
  +ccross = loop_cross_cc(o, cx, cy, cr)
  +hr = holes_vs_cc(hs, cx, cy, cr)
  +hcode = hrc_code(hr)
  +sgn = QC.sh_signed(o)
  +docross = Bool.and(ccross, Bool.and(Bool.not(ccoin), U64.is_eq(hcode, 0u64)))
  ring_split_docross(docross, f, o, hrc_out(hr), hrc_inn(hr), hcode, co, oin, oout, ccoin,
    ccross, sgn, cx, cy, cr, ci)

def rings_qf_go(qfs: List<&2, QC.QF>, +cx: F64, +cy: F64, +cr: F64, +ci: Nat,
    +acc: List<&2, QC.QF>, +ok: Bool, +why: U64) -> RLS:
  match qfs:
    case []: RLS{ok, why, acc}
    case +h <> +t:
      +r = ring_split_qf(h, cx, cy, cr, ci)
      rings_qf_go(t, cx, cy, cr, ci, List.append(&2, QC.QF, acc, rls_qfs(r)),
        Bool.and(ok, rls_ok(r)), Bool.pick(U64, ok, rls_why(r), why))

def rings_split(+onpl: Bool, +qfs: List<&2, QC.QF>, +cx: F64, +cy: F64, +cr: F64,
    +ci: Nat) -> RLS:
  match onpl:
    case False{}: RLS{False{}, 34u64, []}
    case True{}: rings_qf_go(qfs, cx, cy, cr, ci, [], True{}, 0u64)

def rings_go(rs: List<&2, RG>, +fr: FR, +qfs: List<&2, QC.QF>, +ok: Bool, +why: U64) -> RLS:
  match rs:
    case []: RLS{ok, why, qfs}
    case +h <> +t:
      +cc = rg_cc(h)
      +c3 = G.cc_c(cc)
      +ax = fr_ax(fr)
      +c2 = proj_pl(fr, c3)
      +r = rings_split(F64.is_eq(pcomp(c3, ax), fr_c(fr)), qfs, V.v2_x(c2), V.v2_y(c2),
        G.cc_r(cc), rg_ci(h))
      rings_go(t, fr, rls_qfs(r), Bool.and(ok, rls_ok(r)), Bool.pick(U64, ok, rls_why(r),
        why))

def rings_apply(+rs: List<&2, RG>, +fr: FR, +qfs: List<&2, QC.QF>) -> RLS:
  rings_go(rs, fr, qfs, True{}, 0u64)

def cdp_ka(+r: CDP) -> Bool:
  CDP{ka, kb, ok} = r
  ka

def cdp_kb(+r: CDP) -> Bool:
  CDP{ka, kb, ok} = r
  kb

def cuts_noring_go(cs: List<&2, CUT>, +acc: List<&2, CUT>) -> List<&2, CUT>:
  match cs:
    case []: List.reverse(&2, CUT, acc)
    case +h <> +t: cuts_noring_go(t, Bool.pick(List<&2, CUT>, cut_ring(h), acc, h <> acc))

def cuts_noring(cs: List<&2, CUT>) -> List<&2, CUT>:
  cuts_noring_go(cs, [])

def qg_eq(+a: QC.QG, +b: QC.QG) -> Bool:
  Bool.and(eqb(QC.qg_is_ln(a), QC.qg_is_ln(b)),
    Bool.and(F64.is_eq(QC.qg_ax(a), QC.qg_ax(b)),
      Bool.and(F64.is_eq(QC.qg_ay(a), QC.qg_ay(b)),
        Bool.and(F64.is_eq(QC.qg_bx(a), QC.qg_bx(b)),
          Bool.and(F64.is_eq(QC.qg_by(a), QC.qg_by(b)),
            Bool.and(F64.is_eq(QC.qg_cx(a), QC.qg_cx(b)),
              Bool.and(F64.is_eq(QC.qg_cy(a), QC.qg_cy(b)),
                Bool.and(F64.is_eq(QC.qg_cr(a), QC.qg_cr(b)),
                  Bool.and(eqb(QC.qg_ccw(a), QC.qg_ccw(b)),
                    Bool.and(U64.is_eq(QC.qg_lab(a), QC.qg_lab(b)),
                      Nat.is_eq(QC.qg_ref(a), QC.qg_ref(b))))))))))))

def qg_mem(+q: QC.QG, ps: List<&2, QC.QG>) -> Bool:
  match ps:
    case []: False{}
    case +h <> +t: Bool.or(qg_eq(q, h), qg_mem(q, t))

def qgs_sub_go(ps: List<&2, QC.QG>, +qs: List<&2, QC.QG>, +ok: Bool) -> Bool:
  match ps:
    case []: ok
    case +h <> +t: qgs_sub_go(t, qs, Bool.and(ok, qg_mem(h, qs)))

def qgs_sub(ps: List<&2, QC.QG>, +qs: List<&2, QC.QG>) -> Bool:
  qgs_sub_go(ps, qs, True{})

def qfs_flat_go(fs: List<&2, QC.QF>, +acc: List<&2, QC.QG>) -> List<&2, QC.QG>:
  match fs:
    case []: acc
    case +h <> +t:
      qfs_flat_go(t, List.append(&2, QC.QG, acc, qf_all(QC.qf_outer(h), QC.qf_holes(h))))

def face_eq(+kept: List<&2, QC.QF>, +o: List<&2, QC.QG>,
    +hs: List<&2, List<&2, QC.QG>>) -> Bool:
  +inp = qf_all(o, hs)
  +kep = qfs_flat_go(kept, [])
  Bool.and(Nat.is_eq(List.length(&2, QC.QG, kep), List.length(&2, QC.QG, inp)),
    qgs_sub(kep, inp))

def qgl_empty(ls: List<&2, List<&2, QC.QG>>) -> Bool:
  match ls:
    case []: True{}
    case +h <> +t: False{}

def unbox_ek(+b: List<&2, Ty.EdgeKind>) -> Ty.EdgeKind:
  match b:
    case e <> _: e
    case []: Ty.EK_degenerate{}

def box_ek(+e: Ty.EdgeKind) -> List<&2, Ty.EdgeKind>:
  [e]

def carry_ce_go(hs: List<&2, Ty.HCoedge>, +b: Ty.Brep, +side: U64, +st: AS, +eps: F64,
    +acc: List<&2, Ty.HCoedge>, +flip: Bool) -> LC:
  match hs:
    case []:
      LC{st, Bool.pick(List<&2, Ty.HCoedge>, flip, acc, List.reverse(&2, Ty.HCoedge, acc)), True{}}
    case +h <> +t:
      +ce = KU.nth_ce0(Ty.brep_ces(b), Ty.hc_idx(h))
      +ei = Ty.he_idx(Ty.ce_edge(ce))
      +fw = Bool.pick(Bool, flip, Bool.not(Ty.ce_fwd(ce)), Ty.ce_fwd(ce))
      +tm = KU.box_gv(Ty.ce_trim(ce))
      +ed = KU.nth_ed0(Ty.brep_es(b), ei)
      +v0 = Ty.hv_idx(Ty.ed_v0(ed))
      +v1 = Ty.hv_idx(Ty.ed_v1(ed))
      +kbox = box_ek(Ty.ed_kind(ed))
      +vs = Ty.brep_vs(b)
      +p0 = Ty.vx_p(KU.nth_vx0(vs, v0))
      +p1 = Ty.vx_p(KU.nth_vx0(vs, v1))
      +r0 = vadopt(st, p0, eps)
      +r1 = vadopt(vr_st(r0), p1, eps)
      +oa = vr_idx(r0)
      +ob = vr_idx(r1)
      +ee = eemit(vr_st(r1), oa, ob, 5u64, side, ei, Ty.Ed{0u64, hv(oa), hv(ob), unbox_ek(kbox)})
      +ci = as_nc(er_st(ee))
      +st1 = as_add_ce(er_st(ee), Ty.Ce{0u64, he(er_idx(ee)), fw, KU.unbox_gv(tm)})
      carry_ce_go(t, b, side, st1, eps, hc(ci) <> acc, flip)

def carry_lp_go(hs: List<&2, Ty.HLoop>, +b: Ty.Brep, +side: U64, +st: AS, +eps: F64,
    +acc: List<&2, Ty.HLoop>, +flip: Bool) -> LF:
  match hs:
    case []: LF{st, List.reverse(&2, Ty.HLoop, acc), True{}, 0u64}
    case +h <> +t:
      +lp = KU.nth_lp0(Ty.brep_lps(b), Ty.hlp_idx(h))
      +r = carry_ce_go(Ty.lp_ces(lp), b, side, st, eps, [], flip)
      +li = as_nl(lc_st(r))
      +st1 = as_add_lp(lc_st(r), Ty.Lp{0u64, lc_hcs(r), Ty.lp_kind(lp)})
      carry_lp_go(t, b, side, st1, eps, hlp(li) <> acc, flip)

def carry_face(+b: Ty.Brep, +fi: Nat, +side: U64, +st: AS, +eps: F64, +flip: Bool) -> ASE:
  +fa = KU.nth_fa0(Ty.brep_fas(b), fi)
  +r = carry_lp_go(Ty.fa_loops(fa), b, side, st, eps, [], flip)
  +sf = Ty.fa_surf(fa)
  +lp2 = lf_loops(r)
  +sm = Bool.pick(Bool, flip, Bool.not(Ty.fa_same(fa)), Ty.fa_same(fa))
  ASE{as_add_fa(lf_st(r), Ty.Fa{0u64, sf, lp2, sm, 0.0f64, 0.0f64}), True{}, 0u64}

def qgs_rev_go(ps: List<&2, QC.QG>, +acc: List<&2, QC.QG>) -> List<&2, QC.QG>:
  match ps:
    case []: acc
    case +h <> +t: qgs_rev_go(t, QC.qg_rev(h) <> acc)

def qgs_rev(ps: List<&2, QC.QG>) -> List<&2, QC.QG>:
  qgs_rev_go(ps, [])

def qf_hs_rev_go(hs: List<&2, List<&2, QC.QG>>,
    +acc: List<&2, List<&2, QC.QG>>) -> List<&2, List<&2, QC.QG>>:
  match hs:
    case []: acc
    case +h <> +t: qf_hs_rev_go(t, qgs_rev(h) <> acc)

def qf_flip(+f: QC.QF) -> QC.QF:
  QC.QF{qgs_rev(QC.qf_outer(f)), qf_hs_rev_go(QC.qf_holes(f), [])}

def qgs_hasarc(ps: List<&2, QC.QG>) -> Bool:
  match ps:
    case []: False{}
    case +h <> +t: Bool.or(Bool.not(QC.qg_is_ln(h)), qgs_hasarc(t))

def arc_mid_m(+ox: F64, +oy: F64, +r: F64, +sgn: F64, +vx: F64, +vy: F64, +vl: F64) -> V.Vec2:
  V.V2{F64.add(ox, F64.mul(F64.mul(sgn, r), F64.div(vx, vl))),
    F64.add(oy, F64.mul(F64.mul(sgn, r), F64.div(vy, vl)))}

def arc_mid_dia(+q: QC.QG, +ox: F64, +oy: F64, +r: F64, +ccw: Bool) -> V.Vec2:
  +px = F64.neg(F64.sub(QC.qg_by(q), QC.qg_ay(q)))
  +py = F64.sub(QC.qg_bx(q), QC.qg_ax(q))
  +pl = F64.sqrt(F64.add(F64.mul(px, px), F64.mul(py, py)))
  arc_mid_m(ox, oy, r, Bool.pick(F64, ccw, F64.neg(1.0f64), 1.0f64), px, py, pl)

def arc_mid_bis(+q: QC.QG, +ox: F64, +oy: F64, +r: F64, +ccw: Bool, +d1x: F64, +d1y: F64,
    +d2x: F64, +d2y: F64, +crs: F64) -> V.Vec2:
  +bx = F64.add(d1x, d2x)
  +by = F64.add(d1y, d2y)
  +bl = F64.sqrt(F64.add(F64.mul(bx, bx), F64.mul(by, by)))
  +minor = Bool.pick(Bool, ccw, F64.is_lt(0.0f64, crs), F64.is_lt(crs, 0.0f64))
  Bool.pick(V.Vec2, F64.is_eq(bl, 0.0f64), V.V2{QC.qg_ax(q), QC.qg_ay(q)},
    arc_mid_m(ox, oy, r, Bool.pick(F64, minor, 1.0f64, F64.neg(1.0f64)), bx, by, bl))

def arc_mid(+q: QC.QG) -> V.Vec2:
  +ox = QC.qg_cx(q)
  +oy = QC.qg_cy(q)
  +r = QC.qg_cr(q)
  +d1x = F64.sub(QC.qg_ax(q), ox)
  +d1y = F64.sub(QC.qg_ay(q), oy)
  +d2x = F64.sub(QC.qg_bx(q), ox)
  +d2y = F64.sub(QC.qg_by(q), oy)
  +crs = F64.sub(F64.mul(d1x, d2y), F64.mul(d1y, d2x))
  +dot = F64.add(F64.mul(d1x, d2x), F64.mul(d1y, d2y))
  +diam = Bool.and(QC.xnear(crs, 0.0f64), F64.is_lt(dot, 0.0f64))
  Bool.pick(V.Vec2, diam, arc_mid_dia(q, ox, oy, r, QC.qg_ccw(q)),
    arc_mid_bis(q, ox, oy, r, QC.qg_ccw(q), d1x, d1y, d2x, d2y, crs))

def loop_s_ver(+rin: U64, +rout: U64, +s: F64, +rest: F64) -> F64:
  Bool.pick(F64, Bool.and(U64.is_eq(rin, 1u64), U64.is_eq(rout, 0u64)), s,
    Bool.pick(F64, Bool.and(U64.is_eq(rin, 0u64), U64.is_eq(rout, 1u64)), F64.neg(s), rest))

def loop_s_arc(+q: QC.QG, +all: List<&2, QC.QG>, +rest: F64) -> F64:
  +mm = arc_mid(q)
  +ox = QC.qg_cx(q)
  +oy = QC.qg_cy(q)
  +mx = V.v2_x(mm)
  +my = V.v2_y(mm)
  +qx = F64.add(mx, F64.mul(0.01f64, F64.sub(ox, mx)))
  +qy = F64.add(my, F64.mul(0.01f64, F64.sub(oy, my)))
  +zx = F64.sub(mx, F64.mul(0.01f64, F64.sub(ox, mx)))
  +zy = F64.sub(my, F64.mul(0.01f64, F64.sub(oy, my)))
  +s = F64.sub(F64.mul(F64.sub(QC.qg_bx(q), QC.qg_ax(q)), F64.sub(oy, my)),
    F64.mul(F64.sub(QC.qg_by(q), QC.qg_ay(q)), F64.sub(ox, mx)))
  loop_s_ver(QC.pip_loop(all, qx, qy), QC.pip_loop(all, zx, zy), s, rest)

def loop_s_scan(ps: List<&2, QC.QG>, +all: List<&2, QC.QG>) -> F64:
  match ps:
    case []: 0.0f64
    case +h <> +t:
      Bool.pick(F64, QC.qg_is_ln(h), loop_s_scan(t, all), loop_s_arc(h, all, loop_s_scan(t, all)))

def loop_keep_arc(+ps: List<&2, QC.QG>, +want: Bool) -> Bool:
  +s = loop_s_scan(ps, ps)
  Bool.pick(Bool, want, Bool.not(F64.is_lt(s, 0.0f64)), Bool.not(F64.is_lt(0.0f64, s)))

def loop_keep_open(+ps: List<&2, QC.QG>, +want: Bool) -> Bool:
  Bool.pick(Bool, qgs_hasarc(ps), loop_keep_arc(ps, want),
    Bool.pick(Bool, want, Bool.not(F64.is_lt(QC.sh_signed(ps), 0.0f64)),
      Bool.not(F64.is_lt(0.0f64, QC.sh_signed(ps)))))

def loop_keep(+ps: List<&2, QC.QG>, +want: Bool) -> Bool:
  match ps:
    case []: True{}
    case +h <> +t:
      match t:
        case []: Bool.pick(Bool, QC.qg_closed(h), True{}, loop_keep_open(h <> [], want))
        case +x <> +xs: loop_keep_open(h <> x <> xs, want)

def qf_norm_hs_go(hs: List<&2, List<&2, QC.QG>>, +want: Bool,
    +acc: List<&2, List<&2, QC.QG>>) -> List<&2, List<&2, QC.QG>>:
  match hs:
    case []: List.reverse(&2, List<&2, QC.QG>, acc)
    case +h <> +t:
      qf_norm_hs_go(t, want,
        Bool.pick(List<&2, QC.QG>, loop_keep(h, Bool.not(want)), h, qgs_rev(h)) <> acc)

def qf_norm(+f: QC.QF, +want: Bool) -> QC.QF:
  +o = QC.qf_outer(f)
  QC.QF{Bool.pick(List<&2, QC.QG>, loop_keep(o, want), o, qgs_rev(o)),
    qf_norm_hs_go(QC.qf_holes(f), want, [])}

def face_qfs_cmb(+keep: U64, +f: QC.QF, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64,
    +ba: Ty.Brep, +bb: Ty.Brep, +eps: F64, +cs: CS, +r: ASE, +op: U64) -> ASE:
  match keep:
    case 0u64: r
    case 1u64:
      +fl = KC.kflip(op, side)
      +f1 = qf_norm(f, cs_same(cs))
      +f2 = Bool.pick(QC.QF, fl, qf_flip(f1), f1)
      +e = emit_qf(f2, fr, sx, surf, side, ba, bb, ase_st(r), eps)
      +sf = KU.unbox_gv(cs_surf(cs))
      +lp2 = lf_loops(e)
      +sm = Bool.pick(Bool, fl, Bool.not(cs_same(cs)), cs_same(cs))
      +st1 = as_add_fa(lf_st(e), Ty.Fa{0u64, sf, lp2, sm, 0.0f64, 0.0f64})
      ASE{st1, Bool.and(ase_ok(r), lf_ok(e)),
        Bool.pick(U64, ase_ok(r), lf_why(e), ase_why(r))}
    case 3u64: ASE{ase_st(r), False{}, Bool.pick(U64, ase_ok(r), 45u64, ase_why(r))}
    case _: ASE{ase_st(r), False{}, Bool.pick(U64, ase_ok(r), 38u64, ase_why(r))}

def face_qfs_go(fs: List<&2, QC.QF>, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS,
    +eps: F64, +cs: CS, +po: List<&2, QC.QG>, +same: Bool, +hasm: Bool) -> ASE:
  match fs:
    case []: ASE{st, True{}, 0u64}
    case +h <> +t:
      +tiny = bb_tiny(qg_bbox(QC.qf_outer(h)))
      +keep = frag_keep(h, fr, sx, surf, op, side, fds, fbb, tiny, po, same, hasm)
      +r = face_qfs_go(t, fr, sx, surf, op, side, fds, fbb, ba, bb, st, eps, cs, po, same, hasm)
      face_qfs_cmb(keep, h, fr, sx, surf, side, ba, bb, eps, cs, r, op)

def cop_run_d(+oka: Bool, +okb: Bool, +ka: Bool, +b: Ty.Brep, +fi: Nat, +side: U64,
    +st: AS, +eps: F64, +op: U64) -> ASE:
  match oka:
    case False{}: ASE{st, False{}, 38u64}
    case True{}:
      match okb:
        case False{}: ASE{st, False{}, 38u64}
        case True{}:
          Bool.pick(ASE, ka, carry_face(b, fi, side, st, eps, KC.kflip(op, side)),
            ASE{st, True{}, 0u64})

def cop_run_u(+oku: Bool, +okw: Bool, +pa: V.Point, +pp: V.Point, +b: Ty.Brep, +ob: Ty.Brep,
    +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>,
    +st: AS, +eps: F64, +pj: Nat) -> ASE:
  match oku:
    case False{}: ASE{st, False{}, 38u64}
    case True{}:
      match okw:
        case False{}: ASE{st, False{}, 38u64}
        case True{}:
          +n = face_n(surf, same, fr)
          +pfa = KU.nth_fa0(Ty.brep_fas(ob), pj)
          +pn = face_n([Ty.fa_surf(pfa)], Ty.fa_same(pfa), fr)
          +ca = cop_probe(pa, n, 0.0001f64, fdo, bbo)
          +cb = cop_probe(pp, pn, 0.0001f64, fds, fbb)
          +ca2 = cop_probe(pa, n, 0.0000001f64, fdo, bbo)
          +cb2 = cop_probe(pp, pn, 0.0000001f64, fds, fbb)
          +oka = Bool.and(cb_ok(ca), Bool.and(cb_ok(ca2), eqb(cb_inn(ca), cb_inn(ca2))))
          +okb = Bool.and(cb_ok(cb), Bool.and(cb_ok(cb2), eqb(cb_inn(cb), cb_inn(cb2))))
          +dp = cop_decide(op, cb_inn(ca), cb_inn(cb), dir_eq3(n, pn))
          cop_run_d(oka, okb, cdp_ka(dp), b, fi, side, st, eps, op)

def cop_run_n(+pm: Maybe<&2, V.Vec2>, +v: V.Vec2, +b: Ty.Brep, +ob: Ty.Brep, +fi: Nat,
    +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +op: U64, +side: U64, +fds: List<&2, SO.Fd>,
    +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>, +st: AS, +eps: F64,
    +pj: Nat) -> ASE:
  match pm:
    case None{}: ASE{st, False{}, 38u64}
    case Some{+pv}:
      +u = frag_unproj(v, fr, False{}, surf)
      +w = frag_unproj(pv, fr, False{}, surf)
      cop_run_u(pu_ok(u), pu_ok(w), pu_p(u), pu_p(w), b, ob, fi, fr, surf, same, op, side,
        fds, fbb, fdo, bbo, st, eps, pj)

def cop_run_m(+m: Maybe<&2, V.Vec2>, +pm: Maybe<&2, V.Vec2>, +b: Ty.Brep, +ob: Ty.Brep,
    +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>,
    +st: AS, +eps: F64, +pj: Nat) -> ASE:
  match m:
    case None{}: ASE{st, False{}, 38u64}
    case Some{+v}:
      cop_run_n(pm, v, b, ob, fi, fr, surf, same, op, side, fds, fbb, fdo, bbo, st, eps, pj)

def cop_run_f(+full: Bool, +o: List<&2, QC.QG>, +po: List<&2, QC.QG>, +b: Ty.Brep,
    +ob: Ty.Brep, +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>,
    +st: AS, +eps: F64, +pj: Nat) -> ASE:
  match full:
    case False{}: ASE{st, False{}, 28u64}
    case True{}:
      +m = QC.samp_find(o)
      +pm = QC.samp_find(po)
      cop_run_m(m, pm, b, ob, fi, fr, surf, same, op, side, fds, fbb, fdo, bbo, st, eps, pj)

def cop_run_h(+ok: Bool, +o: List<&2, QC.QG>, +po: List<&2, QC.QG>, +b: Ty.Brep,
    +ob: Ty.Brep, +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>,
    +st: AS, +eps: F64, +pj: Nat) -> ASE:
  match ok:
    case False{}: ASE{st, False{}, 37u64}
    case True{}:
      +full = cop_full(o, po)
      cop_run_f(full, o, po, b, ob, fi, fr, surf, same, op, side, fds, fbb, fdo, bbo, st,
        eps, pj)

def cop_run_q(+lok: Bool, +pok: Bool, +o: List<&2, QC.QG>, +hs: List<&2, List<&2, QC.QG>>,
    +po: List<&2, QC.QG>, +ph: List<&2, List<&2, QC.QG>>, +b: Ty.Brep, +ob: Ty.Brep,
    +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>,
    +st: AS, +eps: F64, +pj: Nat) -> ASE:
  +ok = Bool.and(Bool.and(lok, pok), Bool.and(qgl_empty(hs), qgl_empty(ph)))
  cop_run_h(ok, o, po, b, ob, fi, fr, surf, same, op, side, fds, fbb, fdo, bbo, st, eps, pj)

def cop_run(+b: Ty.Brep, +ob: Ty.Brep, +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool,
    +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>,
    +bbo: List<&2, I.I>, +st: AS, +eps: F64, +pj: Nat) -> ASE:
  +lq = face_qg(b, fi, fr, False{})
  +oq = face_qg(ob, pj, fr, False{})
  cop_run_q(lq_ok(lq), lq_ok(oq), lq_outer(lq), lq_holes(lq), lq_outer(oq), lq_holes(oq),
    b, ob, fi, fr, surf, same, op, side, fds, fbb, fdo, bbo, st, eps, pj)

def face_pl_ring(+rok: Bool, +rwhy: U64, +qfs: List<&2, QC.QF>, +fr: FR, +surf: List<&2, G.GVal>,
    +same: Bool, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>,
    +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64, +po: List<&2, QC.QG>, +sm: Bool,
    +hasm: Bool) -> ASE:
  match rok:
    case False{}: ASE{st, False{}, rwhy}
    case True{}: face_qfs_go(qfs, fr, False{}, surf, op, side, fds, fbb, ba, bb, st, eps,
      canon_face(surf, same, fr), po, sm, hasm)

def face_pl_clip(+cok: Bool, +cwhy: U64, +outs: List<&2, List<&2, QC.QG>>,
    +holes: List<&2, List<&2, QC.QG>>, +rings: List<&2, RG>, +fr: FR, +surf: List<&2, G.GVal>,
    +same: Bool, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>,
    +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64, +po: List<&2, QC.QG>, +sm: Bool,
    +hasm: Bool) -> ASE:
  match cok:
    case False{}: ASE{st, False{}, cwhy}
    case True{}:
      +rl = rings_apply(rings, fr, qf_assemble(outs, holes))
      face_pl_ring(rls_ok(rl), rls_why(rl), rls_qfs(rl), fr, surf, same, op, side, fds, fbb,
        ba, bb, st, eps, po, sm, hasm)

def cut_line_eq(+a: CUT, +v: Bool, +c: F64) -> Bool:
  Bool.and(eqb(cut_vert(a), v), F64.is_eq(cut_c(a), c))

def cut_line_mem(cs: List<&2, CUT>, +v: Bool, +c: F64) -> Bool:
  match cs:
    case []: False{}
    case +h <> t: Bool.or(cut_line_eq(h, v, c), cut_line_mem(t, v, c))

def bb_edge_v(+bb: BB2, +c: F64) -> Bool:
  BB2{+x0, +y0, +x1, +y1} = bb
  Bool.or(F64.is_eq(c, x0), F64.is_eq(c, x1))

def bb_edge_h(+bb: BB2, +c: F64) -> Bool:
  BB2{+x0, +y0, +x1, +y1} = bb
  Bool.or(F64.is_eq(c, y0), F64.is_eq(c, y1))

def mate_cut_add(+s: QC.QG, +pj: Nat, +bb: BB2, +acc: List<&2, CUT>) -> List<&2, CUT>:
  +ln = QC.qg_is_ln(s)
  +ax = QC.qg_ax(s)
  +ay = QC.qg_ay(s)
  +bx = QC.qg_bx(s)
  +by = QC.qg_by(s)
  +vert = Bool.and(ln, F64.is_eq(ax, bx))
  +horz = Bool.and(ln, Bool.and(Bool.not(F64.is_eq(ax, bx)), F64.is_eq(ay, by)))
  +c = Bool.pick(F64, vert, ax, ay)
  +isline = Bool.or(vert, horz)
  +dup = cut_line_mem(acc, vert, c)
  +edge = Bool.pick(Bool, vert, bb_edge_v(bb, c), bb_edge_h(bb, c))
  Bool.pick(List<&2, CUT>, Bool.and(isline, Bool.and(Bool.not(dup), Bool.not(edge))),
    CUT{vert, c, pj, False{}} <> acc, acc)

def mate_cuts_go(ss: List<&2, QC.QG>, +pj: Nat, +bb: BB2, +acc: List<&2, CUT>) -> List<&2, CUT>:
  match ss:
    case []: acc
    case +s <> t: mate_cuts_go(t, pj, bb, mate_cut_add(s, pj, bb, acc))

def mate_cuts(+po: List<&2, QC.QG>, +pj: Nat, +cuts: List<&2, CUT>, +o: List<&2, QC.QG>) -> List<&2, CUT>:
  mate_cuts_go(po, pj, qg_bbox(o), cuts)

def nat_max(+a: Nat, +b: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_lt(a, b), b, a)

def maxci_cuts_go(cs: List<&2, CUT>, +m: Nat) -> Nat:
  match cs:
    case []: m
    case +h <> t: maxci_cuts_go(t, nat_max(m, cut_ci(h)))

def maxci_go(rs: List<&2, RG>, +m: Nat) -> Nat:
  match rs:
    case []: m
    case +h <> +t: maxci_go(t, nat_max(m, rg_ci(h)))

def maxci(+cuts: List<&2, CUT>, +rings: List<&2, RG>) -> Nat:
  Nat.add(maxci_go(rings, maxci_cuts_go(cuts, 0n)), 1n)

def mk_cc(+c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64) -> G.Circle3:
  G.Cc{c, u, v, r}

def mate_ring_mem(rs: List<&2, QC.QG>, +cx: F64, +cy: F64, +cr: F64) -> Bool:
  match rs:
    case []: False{}
    case +h <> +t:
      Bool.or(Bool.and(F64.is_eq(QC.qg_cx(h), cx),
        Bool.and(F64.is_eq(QC.qg_cy(h), cy), F64.is_eq(QC.qg_cr(h), cr))),
        mate_ring_mem(t, cx, cy, cr))

def mate_ring_hit2(+p: V.Vec2, +r: F64, +cx: F64, +cy: F64, +cr: F64) -> Bool:
  V.V2{+px, +py} = p
  Bool.and(F64.is_eq(px, cx), Bool.and(F64.is_eq(py, cy), F64.is_eq(r, cr)))

def mate_ring_hit(rs: List<&2, RG>, +fr: FR, +cx: F64, +cy: F64, +cr: F64) -> Bool:
  match rs:
    case []: False{}
    case +h <> +t:
      +cc = rg_cc(h)
      Bool.or(mate_ring_hit2(proj_pl(fr, G.cc_c(cc)), G.cc_r(cc), cx, cy, cr),
        mate_ring_hit(t, fr, cx, cy, cr))

def mate_rings_go(ps: List<&2, QC.QG>, +fr: FR, +ax: U64, +ci: Nat, +seen: List<&2, QC.QG>,
    +ex: List<&2, RG>, +acc: List<&2, RG>) -> List<&2, RG>:
  match ps:
    case []: List.reverse(&2, RG, acc)
    case +h <> +t:
      +cx = QC.qg_cx(h)
      +cy = QC.qg_cy(h)
      +cr = QC.qg_cr(h)
      +isarc = Bool.not(QC.qg_is_ln(h))
      +dup = mate_ring_mem(seen, cx, cy, cr)
      +hit = mate_ring_hit(ex, fr, cx, cy, cr)
      +add = Bool.and(isarc, Bool.and(Bool.not(dup), Bool.not(hit)))
      +cc = mk_cc(unproj_pl(fr, cx, cy), canon_u(ax), canon_v(ax), cr)
      mate_rings_go(t, fr, ax, Bool.pick(Nat, add, Nat.add(ci, 1n), ci),
        Bool.pick(List<&2, QC.QG>, add, h <> seen, seen), ex,
        Bool.pick(List<&2, RG>, add, RG{ci, cc} <> acc, acc))

def mate_rings(+po: List<&2, QC.QG>, +fr: FR, +ci: Nat, +ex: List<&2, RG>) -> List<&2, RG>:
  mate_rings_go(po, fr, fr_ax(fr), ci, [], ex, [])

def cop_contained(+o: List<&2, QC.QG>, +po: List<&2, QC.QG>) -> Bool:
  +a = cop_verts_in(o, po)
  +b = cop_verts_in(po, o)
  Bool.and(Bool.or(Bool.and(a, Bool.not(b)), Bool.and(b, Bool.not(a))),
    Bool.not(cop_cross(o, po)))

def face_pl_mx(+has: Bool, +pj: Nat, +cuts: List<&2, CUT>, +rings: List<&2, RG>,
    +o: List<&2, QC.QG>, +hs: List<&2, List<&2, QC.QG>>, +b: Ty.Brep, +ob: Ty.Brep,
    +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS,
    +eps: F64) -> ASE:
  match has:
    case False{}: ASE{st, False{}, 37u64}
    case True{}:
      +oq = face_qg(ob, pj, fr, False{})
      +po = lq_outer(oq)
      +mfa = KU.nth_fa0(Ty.brep_fas(ob), pj)
      +sm = dir_eq3(face_n(surf, same, fr), face_n([Ty.fa_surf(mfa)], Ty.fa_same(mfa), fr))
      +mc = mate_cuts(po, pj, cuts, o)
      +mr = mate_rings(po, fr, maxci(mc, rings), rings)
      +ls = clip_cuts(cuts_noring(mc), [o], hs, QC.QC{eps, []})
      face_pl_clip(qls_ok(ls), qls_why(ls), qls_outs(ls), qls_holes(ls),
        List.append(&2, RG, rings, mr), fr, surf,
        same, op, side, fds, fbb, ba, bb, st, eps, po, sm, True{})

def face_pl_pair(+h1: QC.QG, +h2: QC.QG, +hs: List<&2, List<&2, QC.QG>>) -> Bool:
  Bool.and(halves_meet(h1, h2), Bool.and(halves_have_arc(h1, h2), qgl_empty(hs)))

def face_pl_carry(+empty: Bool, +o: List<&2, QC.QG>, +hs: List<&2, List<&2, QC.QG>>) -> Bool:
  match empty:
    case False{}: False{}
    case True{}:
      match o:
        case []: False{}
        case +h1 <> t:
          match t:
            case []: Bool.and(QC.qg_closed(h1), qgl_empty(hs))
            case +h2 <> u:
              match u:
                case []: face_pl_pair(h1, h2, hs)
                case _ <> _: False{}

def face_carry_kp(+kp: Bool, +b: Ty.Brep, +fi: Nat, +side: U64, +st: AS, +eps: F64,
    +op: U64) -> ASE:
  match kp:
    case False{}: ASE{st, True{}, 0u64}
    case True{}: carry_face(b, fi, side, st, eps, KC.kflip(op, side))

def face_carry_keep(+o: List<&2, QC.QG>, +hs: List<&2, List<&2, QC.QG>>, +fr: FR,
    +surf: List<&2, G.GVal>, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>,
    +b: Ty.Brep, +fi: Nat, +st: AS, +eps: F64) -> ASE:
  +keep = frag_keep(QC.QF{o, hs}, fr, False{}, surf, op, side, fds, fbb, bb_tiny(qg_bbox(o)),
    [], False{}, False{})
  face_carry_kp(U64.is_eq(keep, 1u64), b, fi, side, st, eps, op)

def face_pl_nc(+carry: Bool, +cuts: List<&2, CUT>, +rings: List<&2, RG>,
    +o: List<&2, QC.QG>, +hs: List<&2, List<&2, QC.QG>>, +b: Ty.Brep, +fi: Nat, +fr: FR,
    +surf: List<&2, G.GVal>, +same: Bool, +op: U64, +side: U64, +fds: List<&2, SO.Fd>,
    +fbb: List<&2, I.I>, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64) -> ASE:
  match carry:
    case True{}: face_carry_keep(o, hs, fr, surf, op, side, fds, fbb, b, fi, st, eps)
    case False{}:
      +ls = clip_cuts(cuts_noring(cuts), [o], hs, QC.QC{eps, []})
      face_pl_clip(qls_ok(ls), qls_why(ls), qls_outs(ls), qls_holes(ls), rings, fr, surf, same,
        op, side, fds, fbb, ba, bb, st, eps, [], False{}, False{})

def face_pl_pure2(+full: Bool, +ctnd: Bool, +o: List<&2, QC.QG>,
    +hs: List<&2, List<&2, QC.QG>>, +b: Ty.Brep, +ob: Ty.Brep, +fi: Nat, +fr: FR,
    +surf: List<&2, G.GVal>, +same: Bool, +op: U64, +side: U64, +fds: List<&2, SO.Fd>,
    +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>, +st: AS, +eps: F64,
    +pj: Nat) -> ASE:
  match full:
    case True{}: cop_run(b, ob, fi, fr, surf, same, op, side, fds, fbb, fdo, bbo, st, eps, pj)
    case False{}:
      match ctnd:
        case True{}: face_carry_keep(o, hs, fr, surf, op, side, fds, fbb, b, fi, st, eps)
        case False{}: ASE{st, False{}, 28u64}

def face_pl_pure_mr(+mr: List<&2, RG>, +o: List<&2, QC.QG>, +po: List<&2, QC.QG>,
    +hs: List<&2, List<&2, QC.QG>>, +cuts: List<&2, CUT>, +rings: List<&2, RG>,
    +b: Ty.Brep, +ob: Ty.Brep, +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool,
    +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>,
    +bbo: List<&2, I.I>, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64, +pj: Nat) -> ASE:
  match mr:
    case []:
      face_pl_pure2(cop_full(o, po), cop_contained(o, po), o, hs, b, ob, fi, fr, surf, same,
        op, side, fds, fbb, fdo, bbo, st, eps, pj)
    case _ <> _:
      face_pl_mx(True{}, pj, cuts, rings, o, hs, b, ob, fi, fr, surf, same, op, side, fds,
        fbb, ba, bb, st, eps)

def face_pl_pure(+has: Bool, +pj: Nat, +cuts: List<&2, CUT>, +rings: List<&2, RG>,
    +o: List<&2, QC.QG>, +hs: List<&2, List<&2, QC.QG>>, +b: Ty.Brep, +ob: Ty.Brep,
    +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>,
    +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64) -> ASE:
  match has:
    case False{}: ASE{st, False{}, 37u64}
    case True{}:
      +po = lq_outer(face_qg(ob, pj, fr, False{}))
      face_pl_pure_mr(mate_rings(po, fr, maxci(cuts, rings), rings), o, po, hs, cuts, rings, b, ob,
        fi, fr, surf, same, op, side, fds, fbb, fdo, bbo, ba, bb, st, eps, pj)

def face_pl_cx(+pure: Bool, +has: Bool, +pj: Nat, +cuts: List<&2, CUT>, +rings: List<&2, RG>,
    +o: List<&2, QC.QG>, +hs: List<&2, List<&2, QC.QG>>, +b: Ty.Brep, +ob: Ty.Brep,
    +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +ks: List<&2, KU.KA>,
    +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>,
    +bbo: List<&2, I.I>, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64) -> ASE:
  match pure:
    case True{}:
      face_pl_pure(has, pj, cuts, rings, o, hs, b, ob, fi, fr, surf, same, op, side, fds,
        fbb, fdo, bbo, ba, bb, st, eps)
    case False{}:
      face_pl_mx(has, pj, cuts, rings, o, hs, b, ob, fi, fr, surf, same, op, side, fds, fbb,
        ba, bb, st, eps)

def face_pl_cop(+fok: Bool, +fwhy: U64, +cop: Bool, +cuts: List<&2, CUT>,
    +rings: List<&2, RG>, +o: List<&2, QC.QG>, +hs: List<&2, List<&2, QC.QG>>, +b: Ty.Brep,
    +ob: Ty.Brep, +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +ks: List<&2, KU.KA>,
    +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>,
    +bbo: List<&2, I.I>, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64) -> ASE:
  match fok:
    case False{}: ASE{st, False{}, fwhy}
    case True{}:
      match cop:
        case True{}:
          +nc = Nat.add(List.length(&2, CUT, cuts), List.length(&2, RG, rings))
          +pj = cop_partner(ks, fi, side, List.length(&2, Ty.Face, Ty.brep_fas(ob)))
          +has = Nat.is_lt(pj, List.length(&2, Ty.Face, Ty.brep_fas(ob)))
          face_pl_cx(Nat.is_eq(nc, 0n), has, pj, cuts, rings, o, hs, b, ob, fi, fr, surf,
            same, ks, op, side, fds, fbb, fdo, bbo, ba, bb, st, eps)
        case False{}:
          +nc = Nat.add(List.length(&2, CUT, cuts), List.length(&2, RG, rings))
          face_pl_nc(face_pl_carry(Nat.is_eq(nc, 0n), o, hs), cuts, rings, o, hs, b, fi, fr,
            surf, same, op, side, fds, fbb, ba, bb, st, eps)

def face_pl_fc(+lok: Bool, +fok: Bool, +fwhy: U64, +cop: Bool, +cuts: List<&2, CUT>,
    +rings: List<&2, RG>, +o: List<&2, QC.QG>, +hs: List<&2, List<&2, QC.QG>>, +b: Ty.Brep,
    +ob: Ty.Brep, +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +ks: List<&2, KU.KA>,
    +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>,
    +bbo: List<&2, I.I>, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64) -> ASE:
  match lok:
    case False{}: ASE{st, False{}, 36u64}
    case True{}:
      face_pl_cop(fok, fwhy, cop, cuts, rings, o, hs, b, ob, fi, fr, surf, same, ks, op,
        side, fds, fbb, fdo, bbo, ba, bb, st, eps)

def cut_hits_bb(+c: CUT, +bb: BB2) -> Bool:
  BB2{+x0, +y0, +x1, +y1} = bb
  Bool.pick(Bool, cut_vert(c),
    Bool.and(F64.is_le(x0, cut_c(c)), F64.is_le(cut_c(c), x1)),
    Bool.and(F64.is_le(y0, cut_c(c)), F64.is_le(cut_c(c), y1)))

def cuts_hit_go(cs: List<&2, CUT>, +bb: BB2, +acc: List<&2, CUT>) -> List<&2, CUT>:
  match cs:
    case []: List.reverse(&2, CUT, acc)
    case +h <> t:
      cuts_hit_go(t, bb, Bool.pick(List<&2, CUT>, cut_hits_bb(h, bb), h <> acc, acc))

def cuts_hit(cs: List<&2, CUT>, +bb: BB2) -> List<&2, CUT>:
  cuts_hit_go(cs, bb, [])

def face_pl(+b: Ty.Brep, +ob: Ty.Brep, +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool,
    +ks: List<&2, KU.KA>, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>,
    +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS,
    +eps: F64) -> ASE:
  +lq = face_qg(b, fi, fr, False{})
  +fc = face_cuts(ks, fi, side, fr_ax(fr), False{}, 0n)
  face_pl_fc(lq_ok(lq), fc_ok(fc), fc_why(fc), fc_cop(fc), cuts_hit(fc_cuts(fc), qg_bbox(lq_outer(lq))),
    fc_rings(fc), lq_outer(lq), lq_holes(lq), b, ob, fi, fr, surf, same, ks, op, side, fds, fbb,
    fdo, bbo, ba, bb, st, eps)

type RIM is Data:
  RIM{ ok: Bool, cc: G.Circle3, ei: Nat, tm: List<&2, G.GVal>, lk: Ty.LoopKind, vp: V.Point }

def rim_ok(+r: RIM) -> Bool:
  RIM{ok, cc, ei, tm, lk, vp} = r
  ok

def rim_cc(+r: RIM) -> G.Circle3:
  RIM{ok, cc, ei, tm, lk, vp} = r
  cc

def rim_ei(+r: RIM) -> Nat:
  RIM{ok, cc, ei, tm, lk, vp} = r
  ei

def rim_tm(+r: RIM) -> List<&2, G.GVal>:
  RIM{ok, cc, ei, tm, lk, vp} = r
  tm

def tm_head(t: List<&2, G.GVal>, +dflt: G.GVal) -> G.GVal:
  match t:
    case []: dflt
    case +h <> +t2: tm_head(t2, h)

def rim_lk(+r: RIM) -> Ty.LoopKind:
  RIM{ok, cc, ei, tm, lk, vp} = r
  lk

def rim_vp(+r: RIM) -> V.Point:
  RIM{ok, cc, ei, tm, lk, vp} = r
  vp

def loop_by_kind_go(hs: List<&2, Ty.HLoop>, +b: Ty.Brep, +want: U64) -> Ty.Loop:
  match hs:
    case []: Ty.lp_dflt()
    case +h <> +t:
      +lp = KU.nth_lp0(Ty.brep_lps(b), Ty.hlp_idx(h))
      Bool.pick(Ty.Loop, U64.is_eq(Ty.lkind_tag(Ty.lp_kind(lp)), want), lp,
        loop_by_kind_go(t, b, want))

def loop_kind_count_go(hs: List<&2, Ty.HLoop>, +b: Ty.Brep, +want: U64, +acc: Nat) -> Nat:
  match hs:
    case []: acc
    case +h <> +t:
      +lp = KU.nth_lp0(Ty.brep_lps(b), Ty.hlp_idx(h))
      loop_kind_count_go(t, b, want,
        Bool.pick(Nat, U64.is_eq(Ty.lkind_tag(Ty.lp_kind(lp)), want), Nat.add(acc, 1n), acc))

def rim_drop(t2: List<&2, Ty.HCoedge>, +h: Ty.HCoedge) -> Ty.HCoedge:
  match t2:
    case []: h
    case +x <> +t3: rim_drop(t3, h)

def rim_head(cs: List<&2, Ty.HCoedge>) -> Ty.HCoedge:
  match cs:
    case []: hc(0n)
    case +h <> +t: rim_drop(t, h)

def wall_rim(+b: Ty.Brep, +fi: Nat, +outer: Bool) -> RIM:
  +fa = KU.nth_fa0(Ty.brep_fas(b), fi)
  +lp = loop_by_kind_go(Ty.fa_loops(fa), b, Bool.pick(U64, outer, 0u64, 1u64))
  +n = List.length(&2, Ty.HCoedge, Ty.lp_ces(lp))
  +h0 = rim_head(Ty.lp_ces(lp))
  +ce = KU.nth_ce0(Ty.brep_ces(b), Ty.hc_idx(h0))
  +ed = KU.nth_ed0(Ty.brep_es(b), Ty.he_idx(Ty.ce_edge(ce)))
  +closed = Nat.is_eq(Ty.hv_idx(Ty.ed_v0(ed)), Ty.hv_idx(Ty.ed_v1(ed)))
  +iscircle = U64.is_eq(gv_tag(Ty.ekind_curve(Ty.ed_kind(ed))), 3u64)
  +vp = Ty.vx_p(KU.nth_vx0(Ty.brep_vs(b), Ty.hv_idx(Ty.ed_v0(ed))))
  RIM{Bool.and(Nat.is_eq(n, 1n), Bool.and(closed, iscircle)),
    gv_cc_of(Ty.ekind_curve(Ty.ed_kind(ed))), Ty.he_idx(Ty.ce_edge(ce)), [Ty.ce_trim(ce)],
    Ty.lp_kind(lp), vp}

def pt_with_ax(+o: V.Point, +ax: U64, +c: F64) -> V.Point:
  match ax:
    case 0u64: V.Pt{c, V.pt_y(o), V.pt_z(o)}
    case 1u64: V.Pt{V.pt_x(o), c, V.pt_z(o)}
    case _: V.Pt{V.pt_x(o), V.pt_y(o), c}

def band_qf(+fr: FR, +r: F64, +zlo: F64, +zhi: F64) -> QC.QF:
  +hc = pcomp(fr_o(fr), sheet_h_ax(fr_ax(fr)))
  +x0 = F64.sub(hc, r)
  +x1 = F64.add(hc, r)
  QC.QF{[QC.qg_ln(x0, zlo, x1, zlo, QC.lab_newln(), 0n),
    QC.qg_ln(x1, zlo, x1, zhi, QC.lab_newln(), 0n),
    QC.qg_ln(x1, zhi, x0, zhi, QC.lab_newln(), 0n),
    QC.qg_ln(x0, zhi, x0, zlo, QC.lab_newln(), 0n)], []}

def band_trim_new(+fr: FR, +ax: U64, +r: F64, +c: F64) -> G.GVal:
  +hx = F64.sub(pcomp(fr_o(fr), sheet_h_ax(ax)), r)
  G.GV_ts{G.Ts{V.V2{hx, c}, V.V2{hx, c}}}

type TC is Data:
  TC{ pts: List<&2, V.Vec2>, ok: Bool, why: U64 }

def tc_pts(+r: TC) -> List<&2, V.Vec2>:
  TC{pts, ok, why} = r
  pts

def tc_ok(+r: TC) -> Bool:
  TC{pts, ok, why} = r
  ok

def tc_why(+r: TC) -> U64:
  TC{pts, ok, why} = r
  why

def tcut_xs_tt(+a: V.Vec2, +b: V.Vec2, +more: List<&2, V.Vec2>, +acc: List<&2, V.Vec2>,
    +ok: Bool, +why: U64) -> TC:
  match more:
    case []: TC{a <> b <> acc, ok, why}
    case +c <> +d: TC{acc, False{}, KC.kr_thetacut()}

def tcut_xs_tl(+a: V.Vec2, +rest: List<&2, V.Vec2>, +acc: List<&2, V.Vec2>, +ok: Bool,
    +why: U64) -> TC:
  match rest:
    case []: TC{acc, False{}, KC.kr_thetacut()}
    case +b <> +more: tcut_xs_tt(a, b, more, acc, ok, why)

def tcut_xs(xs: List<&2, V.Vec2>, +acc: List<&2, V.Vec2>, +ok: Bool, +why: U64) -> TC:
  match xs:
    case []: TC{acc, False{}, KC.kr_thetacut()}
    case +a <> +rest: tcut_xs_tl(a, rest, acc, ok, why)

def tcut_cov(+full: Bool, +hc: F64, +dc: F64, +r: F64, +phc: F64, +pdc: F64, +pr: F64,
    +acc: List<&2, V.Vec2>, +ok: Bool, +why: U64) -> TC:
  match full:
    case False{}: TC{acc, False{}, KC.kr_thetacut()}
    case True{}: tcut_xs(QC.cc_xs(hc, dc, r, phc, pdc, pr), acc, ok, why)

def tcut_rims(+rok: Bool, +z0: F64, +z1: F64, +pz0: F64, +pz1: F64, +hc: F64, +dc: F64,
    +r: F64, +phc: F64, +pdc: F64, +pr: F64, +acc: List<&2, V.Vec2>, +ok: Bool,
    +why: U64) -> TC:
  match rok:
    case False{}: TC{acc, False{}, KC.kr_thetacut()}
    case True{}:
      tcut_cov(Bool.and(F64.is_le(F64.max(z0, pz0), z0), F64.is_le(z1, F64.min(z1, pz1))),
        hc, dc, r, phc, pdc, pr, acc, ok, why)

def tcut_cy(+ps: G.GVal, +pfr: FR, +fr: FR, +ob: Ty.Brep, +pfi: Nat, +z0: F64, +z1: F64,
    +acc: List<&2, V.Vec2>, +ok: Bool, +why: U64) -> TC:
  match ps:
    case G.GV_cy{+cy}:
      +ax = fr_ax(fr)
      +rlo = wall_rim(ob, pfi, True{})
      +rhi = wall_rim(ob, pfi, False{})
      tcut_rims(Bool.and(Bool.and(fr_cyl(pfr), U64.is_eq(fr_ax(pfr), ax)),
          Bool.and(rim_ok(rlo), rim_ok(rhi))), z0, z1,
        pcomp(G.cc_c(rim_cc(rlo)), ax), pcomp(G.cc_c(rim_cc(rhi)), ax),
        pcomp(fr_o(fr), sheet_h_ax(ax)), pcomp(fr_o(fr), sheet_d_ax(ax)), fr_r(fr),
        pcomp(G.cy_o(cy), sheet_h_ax(ax)), pcomp(G.cy_o(cy), sheet_d_ax(ax)), G.cy_r(cy),
        acc, ok, why)
    case _: TC{acc, False{}, KC.kr_thetacut()}

def tcut_use(+mine: Bool, +split: Bool, +k: KU.KA, +fi: Nat, +side: U64, +ob: Ty.Brep,
    +fr: FR, +z0: F64, +z1: F64, +acc: List<&2, V.Vec2>, +ok: Bool, +why: U64) -> TC:
  match mine:
    case False{}: TC{acc, ok, why}
    case True{}:
      match split:
        case False{}: TC{acc, ok, why}
        case True{}:
          +pfi = Bool.pick(Nat, U64.is_eq(side, 0u64), KU.ka_fb(k), KU.ka_fa(k))
          +ps = Ty.fa_surf(KU.nth_fa0(Ty.brep_fas(ob), pfi))
          tcut_cy(ps, fr_of(ps, KU.surfkind(ps)), fr, ob, pfi, z0, z1, acc, ok, why)

def tcut_one(+k: KU.KA, +fi: Nat, +side: U64, +ob: Ty.Brep, +fr: FR, +z0: F64, +z1: F64,
    +acc: List<&2, V.Vec2>, +ok: Bool, +why: U64) -> TC:
  +dec = KU.ka_dec(k)
  +par = U64.is_eq(KU.ka_rel(k), KC.rel_cylpar())
  +mine = Bool.pick(Bool, U64.is_eq(side, 0u64), Nat.is_eq(KU.ka_fa(k), fi),
    Nat.is_eq(KU.ka_fb(k), fi))
  +split = Bool.pick(Bool, U64.is_eq(side, 0u64), KC.dec_splitA(dec), KC.dec_splitB(dec))
  Bool.pick(TC, Bool.and(par, KC.dec_ok(dec)),
    tcut_use(mine, split, k, fi, side, ob, fr, z0, z1, acc, ok, why), TC{acc, ok, why})

def tcut_go(ks: List<&2, KU.KA>, +fi: Nat, +side: U64, +ob: Ty.Brep, +fr: FR, +z0: F64,
    +z1: F64, +acc: List<&2, V.Vec2>, +ok: Bool, +why: U64) -> TC:
  match ks:
    case []: TC{acc, ok, why}
    case +h <> +t:
      +r = tcut_one(h, fi, side, ob, fr, z0, z1, acc, ok, why)
      tcut_go(t, fi, side, ob, fr, z0, z1, tc_pts(r), Bool.and(ok, tc_ok(r)),
        Bool.pick(U64, ok, tc_why(r), why))

def tcut_for(+ks: List<&2, KU.KA>, +fi: Nat, +side: U64, +ob: Ty.Brep, +fr: FR, +z0: F64,
    +z1: F64) -> TC:
  tcut_go(ks, fi, side, ob, fr, z0, z1, [], True{}, 0u64)

def wall_dvec(+pa: V.Point, +pb: V.Point, +c: V.Point) -> V.Dir:
  GO.dd_add_raw(GO.pp_sub_raw(pa, c), GO.pp_sub_raw(pb, c))

def wall_bis(+pa: V.Point, +pb: V.Point, +c: V.Point, +r: F64) -> V.Point:
  +d = wall_dvec(pa, pb, c)
  GO.pd_add_raw(c, F64.div(r, GO.d3_norm_raw(d)), d)

def wall_diam(+pa: V.Point, +pb: V.Point, +c: V.Point) -> Bool:
  QC.xnear(GO.d3_norm_raw(wall_dvec(pa, pb, c)), 0.0f64)

def wall_rim_1(+st: AS, +va: Nat, +vb: Nat, +m: V.Point, +side: U64, +eps: F64) -> PE:
  emit_refit_um(True{}, m, va, vb, st, side, eps)

def strip_rim_d(+diam: Bool, +st: AS, +va: Nat, +vb: Nat, +pa: V.Point, +pb: V.Point,
    +hh: V.Point, +c: V.Point, +r: F64, +side: U64, +eps: F64) -> PE:
  match diam:
    case False{}: wall_rim_1(st, va, vb, wall_bis(pa, pb, c, r), side, eps)
    case True{}:
      +rh = vadopt(st, hh, eps)
      +vh = vr_idx(rh)
      +st0 = vr_st(rh)
      +p0 = pt_of(st0, va)
      +ph = pt_of(st0, vh)
      +p1 = pt_of(st0, vb)
      +e1 = wall_rim_1(st0, va, vh, wall_bis(p0, ph, c, r), side, eps)
      +e2 = wall_rim_1(pe_st(e1), vh, vb, wall_bis(ph, p1, c, r), side, eps)
      PE{List.append(&2, Nat, pe_eis(e1), pe_eis(e2)),
        List.append(&2, Nat, pe_svs(e1), pe_svs(e2)), pe_st(e2),
        Bool.and(pe_ok(e1), pe_ok(e2)), Bool.pick(U64, pe_ok(e1), pe_why(e2), pe_why(e1))}

def strip_rim_f(+fused: Bool, +va: Nat, +vb: Nat, +st: AS, +pa: V.Point, +pb: V.Point,
    +hh: V.Point, +c: V.Point, +r: F64, +side: U64, +eps: F64) -> PE:
  match fused:
    case True{}: PE{[], [], st, False{}, 46u64}
    case False{}: strip_rim_d(wall_diam(pa, pb, c), st, va, vb, pa, pb, hh, c, r, side, eps)

def strip_rim(+st: AS, +pa: V.Point, +pb: V.Point, +hh: V.Point, +c: V.Point, +r: F64,
    +side: U64, +eps: F64) -> PE:
  +ad = emit_adopt(pa, pb, st, eps)
  +va = pea_va(ad)
  +vb = pea_vb(ad)
  strip_rim_f(Nat.is_eq(va, vb), va, vb, pea_st(ad), pa, pb, hh, c, r, side, eps)

def strip_vert_f(+fused: Bool, +va: Nat, +vb: Nat, +st: AS) -> PE:
  match fused:
    case True{}: PE{[], [], st, False{}, 46u64}
    case False{}: emit_ln_go(va, vb, st)

def strip_vert(+st: AS, +pa: V.Point, +pb: V.Point, +eps: F64) -> PE:
  +ad = emit_adopt(pa, pb, st, eps)
  +va = pea_va(ad)
  +vb = pea_vb(ad)
  strip_vert_f(Nat.is_eq(va, vb), va, vb, pea_st(ad))

def strip_hz(+okm: Bool, +hh: V.Point, +pa: V.Point, +pb: V.Point, +q: QC.QG, +fr: FR,
    +side: U64, +st: AS, +eps: F64) -> PE:
  match okm:
    case False{}: PE{[], [], st, False{}, 15u64}
    case True{}:
      strip_rim(st, pa, pb, hh, pt_with_ax(fr_o(fr), fr_ax(fr), QC.qg_ay(q)), fr_r(fr),
        side, eps)

def strip_pc_h(+horz: Bool, +pa: V.Point, +pb: V.Point, +q: QC.QG, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +side: U64, +st: AS, +eps: F64) -> PE:
  match horz:
    case False{}: PE{[], [], st, False{}, 38u64}
    case True{}:
      +um = frag_unproj(QC.qg_mid(q), fr, sx, surf)
      strip_hz(pu_ok(um), pu_p(um), pa, pb, q, fr, side, st, eps)

def strip_pc_v(+vert: Bool, +horz: Bool, +pa: V.Point, +pb: V.Point, +q: QC.QG, +fr: FR,
    +sx: Bool, +surf: List<&2, G.GVal>, +side: U64, +st: AS, +eps: F64) -> PE:
  match vert:
    case True{}: strip_vert(st, pa, pb, eps)
    case False{}: strip_pc_h(horz, pa, pb, q, fr, sx, surf, side, st, eps)

def strip_pc(+ln: Bool, +vert: Bool, +horz: Bool, +pa: V.Point, +pb: V.Point, +q: QC.QG,
    +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64, +st: AS, +eps: F64) -> PE:
  match ln:
    case False{}: PE{[], [], st, False{}, 38u64}
    case True{}: strip_pc_v(vert, horz, pa, pb, q, fr, sx, surf, side, st, eps)

def strip_piece_ub(+okb: Bool, +pa: V.Point, +pb: V.Point, +q: QC.QG, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +side: U64, +st: AS, +eps: F64) -> PE:
  match okb:
    case False{}: PE{[], [], st, False{}, 14u64}
    case True{}:
      strip_pc(QC.qg_is_ln(q), F64.is_eq(QC.qg_ax(q), QC.qg_bx(q)),
        F64.is_eq(QC.qg_ay(q), QC.qg_by(q)), pa, pb, q, fr, sx, surf, side, st, eps)

def strip_piece_up(+oka: Bool, +okb: Bool, +pa: V.Point, +pb: V.Point, +q: QC.QG, +fr: FR,
    +sx: Bool, +surf: List<&2, G.GVal>, +side: U64, +st: AS, +eps: F64) -> PE:
  match oka:
    case False{}: PE{[], [], st, False{}, 14u64}
    case True{}: strip_piece_ub(okb, pa, pb, q, fr, sx, surf, side, st, eps)

def strip_piece(+q: QC.QG, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64, +st: AS,
    +eps: F64) -> PE:
  +up = emit_unproj(q, fr, sx, surf)
  strip_piece_up(pup_oka(up), pup_okb(up), pup_pa(up), pup_pb(up), q, fr, sx, surf, side,
    st, eps)

def strip_go(ps: List<&2, QC.QG>, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64,
    +st: AS, +eps: F64, +acc: List<&2, LP3>, +ok: Bool, +why: U64) -> LE:
  match ps:
    case []: LE{List.reverse(&2, LP3, acc), st, ok, why}
    case +h <> +t:
      +r = strip_piece(h, fr, sx, surf, side, st, eps)
      strip_go(t, fr, sx, surf, side, pe_st(r), eps, lp3_push(pe_eis(r), pe_svs(r), h, acc),
        Bool.and(ok, pe_ok(r)), Bool.pick(U64, ok, pe_why(r), why))

def strip_loop(ps: List<&2, QC.QG>, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64,
    +st: AS, +eps: F64) -> LOP:
  +le = strip_go(ps, fr, sx, surf, side, st, eps, [], True{}, 0u64)
  +lc = loop_ces(le_ps(le), le_st(le))
  emit_loop_lc(lc, le_ok(le), le_why(le), Ty.LK_outer{}, List.length(&2, LP3, le_ps(le)))

def strip_qf_hs(hs: List<&2, List<&2, QC.QG>>, +st: AS, +hls: List<&2, Ty.HLoop>, +ok: Bool,
    +why: U64) -> LF:
  match hs:
    case []: LF{st, hls, ok, why}
    case +h <> +t: strip_qf_hs(t, st, hls, False{}, Bool.pick(U64, ok, 38u64, why))

def strip_qf(+f: QC.QF, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +side: U64, +st: AS,
    +eps: F64) -> LF:
  +ro = strip_loop(QC.qf_outer(f), fr, sx, surf, side, st, eps)
  strip_qf_hs(QC.qf_holes(f), lop_st(ro), [lop_hl(ro)], lop_ok(ro), lop_why(ro))

def strip_qfs_cmb(+keep: U64, +f: QC.QF, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>,
    +side: U64, +eps: F64, +cs: CS, +r: ASE, +op: U64) -> ASE:
  match keep:
    case 0u64: r
    case 1u64:
      +fl = KC.kflip(op, side)
      +rv = Bool.pick(Bool, fl, Bool.not(sx), sx)
      +f2 = Bool.pick(QC.QF, rv, qf_flip(f), f)
      +e = strip_qf(f2, fr, sx, surf, side, ase_st(r), eps)
      +sm = Bool.pick(Bool, fl, Bool.not(cs_same(cs)), cs_same(cs))
      +st1 = as_add_fa(lf_st(e), Ty.Fa{0u64, KU.unbox_gv(cs_surf(cs)), lf_loops(e), sm, 0.0f64, 0.0f64})
      ASE{st1, Bool.and(ase_ok(r), lf_ok(e)),
        Bool.pick(U64, ase_ok(r), lf_why(e), ase_why(r))}
    case 3u64: ASE{ase_st(r), False{}, Bool.pick(U64, ase_ok(r), 45u64, ase_why(r))}
    case _: ASE{ase_st(r), False{}, Bool.pick(U64, ase_ok(r), 38u64, ase_why(r))}

def strip_qfs_go(fs: List<&2, QC.QF>, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>, +op: U64,
    +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +st: AS, +eps: F64, +cs: CS,
    +same: Bool) -> ASE:
  match fs:
    case []: ASE{st, True{}, 0u64}
    case +h <> +t:
      +tiny = bb_tiny(qg_bbox(QC.qf_outer(h)))
      +keep = frag_keep(h, fr, sx, surf, op, side, fds, fbb, tiny, [], same, False{})
      +r = strip_qfs_go(t, fr, sx, surf, op, side, fds, fbb, st, eps, cs, same)
      strip_qfs_cmb(keep, h, fr, sx, surf, side, eps, cs, r, op)

def tcut_sheet_go(ps: List<&2, V.Vec2>, +hc: F64, +r: F64, +dc: F64, +sx: Bool, +ci: Nat,
    +acc: List<&2, CUT>) -> List<&2, CUT>:
  match ps:
    case []: List.reverse(&2, CUT, acc)
    case +h <> +t:
      +px = V.v2_x(h)
      +py = V.v2_y(h)
      +ge = F64.is_le(dc, py)
      +on = Bool.or(Bool.pick(Bool, sx, ge, Bool.not(ge)), QC.xnear(py, dc))
      +inside = Bool.and(F64.is_lt(F64.sub(hc, r), px), F64.is_lt(px, F64.add(hc, r)))
      tcut_sheet_go(t, hc, r, dc, sx, Nat.add(ci, 1n),
        Bool.pick(List<&2, CUT>, Bool.and(on, inside), CUT{True{}, px, ci, False{}} <> acc,
          acc))

def tcut_sheet(ps: List<&2, V.Vec2>, +hc: F64, +r: F64, +dc: F64, +sx: Bool) -> List<&2, CUT>:
  tcut_sheet_go(ps, hc, r, dc, sx, 0n, [])

def band_sheet_1(+cok: Bool, +cwhy: U64, +outs: List<&2, List<&2, QC.QG>>,
    +holes: List<&2, List<&2, QC.QG>>, +fr: FR, +sx: Bool, +surf: List<&2, G.GVal>,
    +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +st: AS, +eps: F64,
    +cs: CS, +same: Bool) -> ASE:
  match cok:
    case False{}: ASE{st, False{}, cwhy}
    case True{}:
      strip_qfs_go(qf_assemble(outs, holes), fr, sx, surf, op, side, fds, fbb, st, eps, cs,
        same)

def band_sheet(+st: AS, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +r: F64, +a: F64, +b: F64,
    +cuts: List<&2, V.Vec2>, +eps: F64) -> ASE:
  +ax = fr_ax(fr)
  +hc = pcomp(fr_o(fr), sheet_h_ax(ax))
  +dc = pcomp(fr_o(fr), sheet_d_ax(ax))
  +o = QC.qf_outer(band_qf(fr, r, a, b))
  +ls0 = clip_cuts(tcut_sheet(cuts, hc, r, dc, False{}), [o], [], QC.QC{eps, []})
  +r0 = band_sheet_1(qls_ok(ls0), qls_why(ls0), qls_outs(ls0), qls_holes(ls0), fr, False{},
    surf, op, side, fds, fbb, st, eps, CS{surf, same}, same)
  +ls1 = clip_cuts(tcut_sheet(cuts, hc, r, dc, True{}), [o], [], QC.QC{eps, []})
  +r1 = band_sheet_1(qls_ok(ls1), qls_why(ls1), qls_outs(ls1), qls_holes(ls1), fr, True{},
    surf, op, side, fds, fbb, ase_st(r0), eps, CS{surf, same}, same)
  ASE{ase_st(r1), Bool.and(ase_ok(r0), ase_ok(r1)),
    Bool.pick(U64, ase_ok(r0), ase_why(r1), ase_why(r0))}

def erim_adopt(+found: Bool, +f: Nat, +st: AS, +v: Nat, +cc: G.Circle3, +side: U64,
    +ei: Nat) -> ER:
  match found:
    case True{}: ER{f, ealias(st, v, v, 5u64, side, ei, f)}
    case False{}:
      +er = eemit(st, v, v, 5u64, side, ei, Ty.Ed{0u64, hv(v), hv(v), ekind_cc(cc)})
      ER{er_idx(er), ealias(er_st(er), v, v, 8u64, 2u64, 0n, er_idx(er))}

def erim_fuse(+st: AS, +v: Nat, +cc: G.Circle3, +side: U64, +ei: Nat) -> ER:
  +n = as_ne(st)
  +f = efind_go(as_eks(st), v, v, 8u64, 2u64, 0n, n)
  erim_adopt(Nat.is_lt(f, n), f, st, v, cc, side, ei)

def rim_edge_go(+orig: Bool, +st: AS, +v: Nat, +cc: G.Circle3, +side: U64, +ei: Nat) -> ER:
  match orig:
    case True{}: erim_fuse(st, v, cc, side, ei)
    case False{}: cc_edge(st, v, cc, 8u64, 2u64, 0n)

def cc_pos_ax(+cc: G.Circle3, +ax: U64) -> Bool:
  F64.is_eq(dcomp(GO.dd_cross_raw(G.cc_u(cc), G.cc_v(cc)), ax), 1.0f64)

def band_rim_edge(+st: AS, +cc: G.Circle3, +vp: V.Point, +side: U64, +eps: F64,
    +rim: RIM, +is_orig: Bool) -> ER:
  +rv = vadopt(st, vp, eps)
  rim_edge_go(is_orig, vr_st(rv), vr_idx(rv), cc, side, rim_ei(rim))

type RVS is Data:
  RVS{ st: AS, vis: List<&2, Nat> }

def rvs_st(+r: RVS) -> AS:
  RVS{st, vis} = r
  st

def rvs_vis(+r: RVS) -> List<&2, Nat>:
  RVS{st, vis} = r
  vis

def ring_vs_go(+ps: List<&2, V.Point>, +st: AS, +eps: F64, +acc: List<&2, Nat>, +prev: Nat,
    +first: Bool) -> RVS:
  match ps:
    case []: RVS{st, List.reverse(&2, Nat, acc)}
    case +h <> +t:
      +rv = vadopt(st, h, eps)
      +ni = vr_idx(rv)
      +same = Bool.and(Bool.not(first), Nat.is_eq(ni, prev))
      ring_vs_go(t, vr_st(rv), eps, Bool.pick(List<&2, Nat>, same, acc, ni <> acc), ni,
        False{})

def trim_ln() -> G.GVal:
  G.GV_ts{G.Ts{V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64}}}

def ring_ces_go(+vis: List<&2, Nat>, +ps: List<&2, V.Point>, +st: AS, +cur: Nat, +start: Nat,
    +started: Bool, +hcs: List<&2, Ty.HCoedge>, +ok: Bool, +side: U64, +eps: F64) -> LC:
  match vis:
    case []:
      LC{st, List.reverse(&2, Ty.HCoedge, hcs),
        Bool.and(ok, Bool.and(started, Nat.is_eq(cur, start)))}
    case +vi <> +vt:
      match vt:
        case []:
          LC{st, List.reverse(&2, Ty.HCoedge, hcs),
            Bool.and(ok, Bool.and(started, Nat.is_eq(cur, start)))}
        case +vj <> +vtt:
          match ps:
            case []: LC{st, List.reverse(&2, Ty.HCoedge, hcs), False{}}
            case +pi <> +pt:
              match pt:
                case []: LC{st, List.reverse(&2, Ty.HCoedge, hcs), False{}}
                case +pj <> +ptt:
                  +c0 = Bool.pick(Nat, started, cur, vi)
                  +s0 = Bool.pick(Nat, started, start, vi)
                  +er = emit_ln_er(vi, vj, pi, pj, st)
                  +ne1 = as_ne(er_st(er))
                  +ed = KU.nth_ed0(as_es(er_st(er)), Nat.sub(Nat.sub(ne1, 1n), er_idx(er)))
                  +eva = Ty.hv_idx(Ty.ed_v0(ed))
                  +evb = Ty.hv_idx(Ty.ed_v1(ed))
                  +fw = Nat.is_eq(eva, c0)
                  +bk = Nat.is_eq(evb, c0)
                  +ci = as_nc(er_st(er))
                  +st1 = as_add_ce(er_st(er), Ty.Ce{0u64, he(er_idx(er)), fw, trim_ln()})
                  ring_ces_go(vt, pt, st1, Bool.pick(Nat, fw, evb, eva), s0, True{},
                    hc(ci) <> hcs, Bool.and(ok, Bool.or(fw, bk)), side, eps)

type RH1 is Data:
  RH1{ st: AS, hl: Ty.HLoop, ok: Bool, why: U64 }

def rh1_st(+r: RH1) -> AS:
  RH1{st, hl, ok, why} = r
  st

def rh1_hl(+r: RH1) -> Ty.HLoop:
  RH1{st, hl, ok, why} = r
  hl

def rh1_ok(+r: RH1) -> Bool:
  RH1{st, hl, ok, why} = r
  ok

def rh1_why(+r: RH1) -> U64:
  RH1{st, hl, ok, why} = r
  why

def isl_rad(+w0: V.Point, +o: V.Point, +ax: V.Dir) -> V.Dir:
  +m = GO.pp_sub_raw(w0, o)
  GO.dd_sub_raw(m, GO.dd_scale_raw(GO.dd_dot_raw(m, ax), ax))

def isl_zmi_go(+vs: List<&2, V.Point>, +ax: U64, +i: Nat, +bi: Nat, +bz: F64) -> Nat:
  match vs:
    case []: bi
    case +h <> +t:
      +z = pcomp(h, ax)
      +better = F64.is_lt(z, bz)
      isl_zmi_go(t, ax, Nat.add(i, 1n), Bool.pick(Nat, better, i, bi),
        Bool.pick(F64, better, z, bz))

def isl_nth(+vs: List<&2, V.Point>, +i: Nat, +dflt: V.Point) -> V.Point:
  match vs:
    case []: dflt
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+m: isl_nth(t, m, dflt)

def isl_sense(+vs: List<&2, V.Point>, +fr: FR, +sm0: Bool, +outer: Bool) -> Nat:
  match vs:
    case []: 2n
    case +h <> +t:
      +ax = fr_ax(fr)
      +n = List.length(&2, V.Point, vs)
      +iz = isl_zmi_go(t, ax, 1n, 0n, pcomp(h, ax))
      +ps = isl_nth(vs, iz, h)
      +tan = GO.pp_sub_raw(isl_nth(vs, Nat.mod(Nat.add(iz, 1n), n), h),
        isl_nth(vs, Nat.mod(Nat.add(iz, Nat.sub(n, 1n)), n), h))
      +rad = isl_rad(ps, fr_o(fr), dir_ax(ax))
      +q = GO.dd_dot_raw(GO.dd_cross_raw(tan,
        Bool.pick(V.Dir, sm0, rad, GO.dd_scale_raw(F64.neg(1.0f64), rad))), dir_ax(ax))
      Bool.pick(Nat, F64.is_eq(q, 0.0f64), 2n,
        Bool.pick(Nat, outer, Bool.pick(Nat, F64.is_lt(q, 0.0f64), 0n, 1n),
          Bool.pick(Nat, F64.is_lt(0.0f64, q), 0n, 1n)))

def ring_rps(+rvis: List<&2, Nat>, +st: AS) -> List<&2, V.Point>:
  match rvis:
    case []: []
    case +h <> +t: pt_of(st, h) <> ring_rps(t, st)

def ring_att_run(+vs: List<&2, V.Point>, +st: AS, +side: U64, +eps: F64, +outer: Bool,
    +rev: Bool) -> RH1:
  +rv = ring_vs_go(vs, st, eps, [], 0n, True{})
  +st0 = rvs_st(rv)
  +vis = rvs_vis(rv)
  +wvis = Bool.pick(List<&2, Nat>, rev, List.reverse(&2, Nat, vis), vis)
  +wps = ring_rps(wvis, st0)
  +lc = ring_ces_go(wvis, wps, st0, 0n, 0n, False{}, [], True{}, side, eps)
  +li = as_nl(lc_st(lc))
  +lk = Bool.pick(Ty.LoopKind, outer, Ty.LK_outer{}, Ty.LK_inner{})
  +st1 = as_add_lp(lc_st(lc), Ty.Lp{0u64, lc_hcs(lc), lk})
  RH1{st1, hlp(li), lc_ok(lc), Bool.pick(U64, lc_ok(lc), 0u64, KC.kr_offdomain())}

def ring_att_go(+code: Nat, +vs: List<&2, V.Point>, +st: AS, +side: U64, +eps: F64,
    +outer: Bool) -> RH1:
  match code:
    case 0n: ring_att_run(vs, st, side, eps, outer, False{})
    case 1n: ring_att_run(vs, st, side, eps, outer, True{})
    case _: RH1{st, hlp(as_nl(st)), False{}, KC.kr_degenerate()}

def ring_attach(+h: RX.RING, +st: AS, +side: U64, +eps: F64, +outer: Bool, +fr: FR,
    +sm0: Bool) -> RH1:
  +vs = RX.ring_vs(h)
  ring_att_go(isl_sense(vs, fr, sm0, outer), vs, st, side, eps, outer)

def ring_action(+rs: List<&2, RX.RING>, +ax: U64, +a: F64, +b: F64) -> Nat:
  match rs:
    case []: 0n
    case +h <> +t:
      +zr = RX.rx_zrange(RX.ring_vs(h), ax)
      +zlo = V.v2_x(zr)
      +zhi = V.v2_y(zr)
      +inside = Bool.and(F64.is_le(a, zlo), F64.is_le(zhi, b))
      +outside = Bool.or(F64.is_lt(zhi, a), F64.is_lt(b, zlo))
      Bool.pick(Nat, inside, 1n, Bool.pick(Nat, outside, 0n, 2n))

type RHH is Data:
  RHH{ st: AS, hls: List<&2, Ty.HLoop>, slv: F64, sla: F64, ok: Bool, why: U64 }

def rhh_st(+r: RHH) -> AS:
  RHH{st, hls, slv, sla, ok, why} = r
  st

def rhh_hls(+r: RHH) -> List<&2, Ty.HLoop>:
  RHH{st, hls, slv, sla, ok, why} = r
  hls

def rhh_slv(+r: RHH) -> F64:
  RHH{st, hls, slv, sla, ok, why} = r
  slv

def rhh_sla(+r: RHH) -> F64:
  RHH{st, hls, slv, sla, ok, why} = r
  sla

def rhh_ok(+r: RHH) -> Bool:
  RHH{st, hls, slv, sla, ok, why} = r
  ok

def rhh_why(+r: RHH) -> U64:
  RHH{st, hls, slv, sla, ok, why} = r
  why

def ring_holes_go(+prs: List<&2, RX.RING>, +code: Nat, +ax: U64, +a: F64, +b: F64, +st: AS,
    +side: U64, +eps: F64, +hacc: List<&2, Ty.HLoop>, +vsv: F64, +vsa: F64, +ok: Bool,
    +why: U64, +fr: FR, +sm0: Bool) -> RHH:
  match prs:
    case []: RHH{st, hacc, vsv, vsa, ok, why}
    case +h <> +t:
      match code:
        case 0n:
          ring_holes_go(t, ring_action(t, ax, a, b), ax, a, b, st, side, eps, hacc, vsv, vsa,
            ok, why, fr, sm0)
        case 1n:
          +ra = ring_attach(h, st, side, eps, False{}, fr, sm0)
          +nw = Bool.pick(U64, ok, Bool.pick(U64, rh1_ok(ra), why, rh1_why(ra)), why)
          ring_holes_go(t, ring_action(t, ax, a, b), ax, a, b, rh1_st(ra), side, eps,
            rh1_hl(ra) <> hacc, F64.add(vsv, RX.ring_slv(h)), F64.add(vsa, RX.ring_sla(h)),
            Bool.and(ok, rh1_ok(ra)), nw, fr, sm0)
        case _: RHH{st, hacc, vsv, vsa, False{}, KC.kr_offdomain()}

def band_face_fin(+hok: Bool, +hwhy: U64, +st: AS, +li0: Nat, +li1: Nat,
    +hls: List<&2, Ty.HLoop>, +surf: List<&2, G.GVal>, +sm0: Bool, +hsv: F64,
    +hsa: F64) -> ASE:
  match hok:
    case False{}: ASE{st, False{}, hwhy}
    case True{}:
      +loops = List.append(&2, Ty.HLoop, [hlp(li0), hlp(li1)], hls)
      ASE{as_add_fa(st, Ty.Fa{0u64, KU.unbox_gv(surf), loops, sm0, hsv, hsa}), True{}, 0u64}

def isl_strict(+h: RX.RING, +ax: U64, +a: F64, +b: F64) -> Bool:
  +zr = RX.rx_zrange(RX.ring_vs(h), ax)
  Bool.and(F64.is_lt(a, V.v2_x(zr)), F64.is_lt(V.v2_y(zr), b))

def isl_rimkeep(+fr: FR, +a: F64, +b: F64, +mlo: F64, +mhi: F64, +rc: Nat,
    +surf: List<&2, G.GVal>, +op: U64, +side: U64, +fds: List<&2, SO.Fd>,
    +fbb: List<&2, I.I>) -> U64:
  +o = fr_o(fr)
  +hc = pcomp(o, sheet_h_ax(fr_ax(fr)))
  +z = Bool.pick(F64, Nat.is_eq(rc, 0n), F64.mul(0.5f64, F64.add(a, mlo)),
    F64.mul(0.5f64, F64.add(mhi, b)))
  +u = frag_unproj(V.V2{hc, z}, fr, True{}, surf)
  +c0 = Bool.pick(U64, pu_ok(u), pt_cls(pu_p(u), fds, fbb), KC.cls_unc())
  frag_keep_ls(c0, [], op, side)

def isl_face(+h: RX.RING, +st: AS, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool,
    +flip: Bool, +side: U64, +eps: F64) -> ASE:
  +sm0 = KC.band_sm(flip, same)
  +ra = ring_attach(h, st, side, eps, True{}, fr, sm0)
  Bool.pick(ASE, rh1_ok(ra),
    ASE{as_add_fa(rh1_st(ra),
      Ty.Fa{0u64, KU.unbox_gv(surf), [rh1_hl(ra)], sm0, RX.ring_slv(h), RX.ring_sla(h)}),
      True{}, 0u64},
    ASE{rh1_st(ra), False{}, rh1_why(ra)})

def isl_go(+prs: List<&2, RX.RING>, +code: Nat, +fr: FR, +surf: List<&2, G.GVal>,
    +same: Bool, +flip: Bool, +side: U64, +ax: U64, +a: F64, +b: F64, +st: AS, +eps: F64,
    +rk: U64) -> ASE:
  match prs:
    case []: ASE{st, True{}, 0u64}
    case +h <> +t:
      match code:
        case 0n:
          isl_go(t, ring_action(t, ax, a, b), fr, surf, same, flip, side, ax, a, b, st,
            eps, rk)
        case 1n:
          match rk:
            case 0u64:
              Bool.pick(ASE, isl_strict(h, ax, a, b),
                Bool.pick(ASE, ase_ok(isl_face(h, st, fr, surf, same, flip, side, eps)),
                  isl_go(t, ring_action(t, ax, a, b), fr, surf, same, flip, side, ax, a, b,
                    ase_st(isl_face(h, st, fr, surf, same, flip, side, eps)), eps, rk),
                  isl_face(h, st, fr, surf, same, flip, side, eps)),
                ASE{st, False{}, KC.kr_offdomain()})
            case 1u64:
              isl_go(t, ring_action(t, ax, a, b), fr, surf, same, flip, side, ax, a, b, st,
                eps, rk)
            case 3u64: ASE{st, False{}, 45u64}
            case _: ASE{st, False{}, 38u64}
        case _: ASE{st, False{}, KC.kr_offdomain()}

def isl_out(+h: RX.RING, +ax: U64, +a: F64, +b: F64) -> Bool:
  +zr = RX.rx_zrange(RX.ring_vs(h), ax)
  Bool.or(F64.is_lt(V.v2_y(zr), a), F64.is_lt(b, V.v2_x(zr)))

def isl_minlo_go(+prs: List<&2, RX.RING>, +ax: U64, +a: F64, +b: F64, +acc: F64) -> F64:
  match prs:
    case []: acc
    case +h <> +t:
      isl_minlo_go(t, ax, a, b,
        Bool.pick(F64, isl_out(h, ax, a, b), acc,
          F64.min(acc, V.v2_x(RX.rx_zrange(RX.ring_vs(h), ax)))))

def isl_maxhi_go(+prs: List<&2, RX.RING>, +ax: U64, +a: F64, +b: F64, +acc: F64) -> F64:
  match prs:
    case []: acc
    case +h <> +t:
      isl_maxhi_go(t, ax, a, b,
        Bool.pick(F64, isl_out(h, ax, a, b), acc,
          F64.max(acc, V.v2_y(RX.rx_zrange(RX.ring_vs(h), ax)))))

def isl_rimcode(+prs: List<&2, RX.RING>, +ax: U64, +a: F64, +b: F64) -> Nat:
  Bool.pick(Nat, F64.is_lt(a, isl_minlo_go(prs, ax, a, b, b)), 0n,
    Bool.pick(Nat, F64.is_lt(isl_maxhi_go(prs, ax, a, b, a), b), 1n, 2n))

def band_face(+st: AS, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +flip: Bool, +side: U64,
    +ax: U64, +r: F64, +a: F64, +b: F64, +rim_lo: RIM, +rim_hi: RIM, +eps: F64,
    +prs: List<&2, RX.RING>, +rk: U64) -> ASE:
  +z0 = pcomp(G.cc_c(rim_cc(rim_lo)), ax)
  +z1 = pcomp(G.cc_c(rim_cc(rim_hi)), ax)
  +lo_orig = F64.is_eq(a, z0)
  +hi_orig = F64.is_eq(b, z1)
  +tmlo0 = rim_tm(rim_lo)
  +tmhi0 = rim_tm(rim_hi)
  +lk0 = rim_lk(rim_lo)
  +lk1 = rim_lk(rim_hi)
  +cc0 = Bool.pick(G.Circle3, lo_orig, rim_cc(rim_lo),
    cc_mk(pt_with_ax(fr_o(fr), ax, a), dir_ax(run0_ax(ax)), dir_ax(run1_ax(ax)), r))
  +cc1 = Bool.pick(G.Circle3, hi_orig, rim_cc(rim_hi),
    cc_mk(pt_with_ax(fr_o(fr), ax, b), dir_ax(run0_ax(ax)), dir_ax(run1_ax(ax)), r))
  +er0 = band_rim_edge(st, cc0, Bool.pick(V.Point, lo_orig, rim_vp(rim_lo), cc_vert_pt(cc0)),
    side, eps, rim_lo, lo_orig)
  +er1 = band_rim_edge(er_st(er0), cc1,
    Bool.pick(V.Point, hi_orig, rim_vp(rim_hi), cc_vert_pt(cc1)), side, eps, rim_hi, hi_orig)
  +sm0 = KC.band_sm(flip, same)
  +fw0 = KC.band_fw_lo(sm0, cc_pos_ax(cc0, ax))
  +fw1 = KC.band_fw_hi(sm0, cc_pos_ax(cc1, ax))
  +tm0 = Bool.pick(G.GVal, lo_orig, tm_head(tmlo0, band_trim_new(fr, ax, r, a)),
    band_trim_new(fr, ax, r, a))
  +tm1 = Bool.pick(G.GVal, hi_orig, tm_head(tmhi0, band_trim_new(fr, ax, r, b)),
    band_trim_new(fr, ax, r, b))
  +st1 = er_st(er1)
  +ci0 = as_nc(st1)
  +st2 = as_add_ce(st1, Ty.Ce{0u64, he(er_idx(er0)), fw0, tm0})
  +ci1 = as_nc(st2)
  +st3 = as_add_ce(st2, Ty.Ce{0u64, he(er_idx(er1)), fw1, tm1})
  +li0 = as_nl(st3)
  +st4 = as_add_lp(st3, Ty.Lp{0u64, [hc(ci0)], lk0})
  +li1 = as_nl(st4)
  +st5 = as_add_lp(st4, Ty.Lp{0u64, [hc(ci1)], lk1})
  +rh = ring_holes_go(prs, ring_action(prs, ax, a, b), ax, a, b, st5, side, eps, [], 0.0f64,
    0.0f64, True{}, 0u64, fr, sm0)
  +fin = band_face_fin(rhh_ok(rh), rhh_why(rh), rhh_st(rh), li0, li1, rhh_hls(rh), surf, sm0,
    rhh_slv(rh), rhh_sla(rh))
  Bool.pick(ASE, ase_ok(fin),
    isl_go(prs, ring_action(prs, ax, a, b), fr, surf, same, flip, side, ax, a, b,
      ase_st(fin), eps, rk),
    fin)

def band_abort(t: List<&2, F64>, +r: ASE) -> ASE:
  match t:
    case []: r
    case +h <> +t2: band_abort(t2, r)

def band_go2f(t: List<&2, F64>, +a: F64, +st: AS, +fr: FR, +surf: List<&2, G.GVal>,
    +same: Bool, +flip: Bool, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>,
    +ax: U64, +r: F64, +rim_lo: RIM, +rim_hi: RIM, +eps: F64,
    +prs: List<&2, RX.RING>) -> ASE:
  match t:
    case []: ASE{st, True{}, 0u64}
    case +b <> +rest:
      +qf = band_qf(fr, r, a, b)
      +keep = frag_keep(qf, fr, True{}, surf, op, side, fds, fbb,
        bb_tiny(qg_bbox(QC.qf_outer(qf))), [], same, False{})
      Bool.pick(ASE, U64.is_eq(keep, 0u64),
        band_go2f(rest, b, st, fr, surf, same, flip, op, side, fds, fbb, ax, r, rim_lo,
          rim_hi, eps, prs),
        Bool.pick(ASE, U64.is_eq(keep, 1u64),
          band_go2f(rest, b, ase_st(band_face(st, fr, surf, same, flip, side, ax, r, a, b,
            rim_lo, rim_hi, eps, prs, keep)), fr, surf, same, flip, op, side, fds, fbb,
            ax, r, rim_lo, rim_hi, eps, prs),
          Bool.pick(ASE, U64.is_eq(keep, 3u64), band_abort(rest, ASE{st, False{}, 45u64}),
            band_abort(rest, ASE{st, False{}, 38u64}))))

def band_go2t(t: List<&2, F64>, +a: F64, +st: AS, +fr: FR, +surf: List<&2, G.GVal>,
    +same: Bool, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +r: F64,
    +cuts: List<&2, V.Vec2>, +eps: F64) -> ASE:
  match t:
    case []: ASE{st, True{}, 0u64}
    case +b <> +rest:
      +r0 = band_sheet(st, fr, surf, same, op, side, fds, fbb, r, a, b, cuts, eps)
      +r1 = band_go2t(rest, b, ase_st(r0), fr, surf, same, op, side, fds, fbb, r, cuts, eps)
      ASE{ase_st(r1), Bool.and(ase_ok(r0), ase_ok(r1)),
        Bool.pick(U64, ase_ok(r0), ase_why(r1), ase_why(r0))}

def band_go2fr(t: List<&2, F64>, +a: F64, +st: AS, +fr: FR, +surf: List<&2, G.GVal>,
    +same: Bool, +flip: Bool, +op: U64, +side: U64, +fds: List<&2, SO.Fd>,
    +fbb: List<&2, I.I>, +ax: U64, +r: F64, +rim_lo: RIM, +rim_hi: RIM, +eps: F64,
    +prs: List<&2, RX.RING>) -> ASE:
  match t:
    case []: ASE{st, True{}, 0u64}
    case +b <> +rest:
      +rc = isl_rimcode(prs, ax, a, b)
      +mlo = isl_minlo_go(prs, ax, a, b, b)
      +mhi = isl_maxhi_go(prs, ax, a, b, a)
      +noring = Bool.and(F64.is_eq(mlo, b), F64.is_eq(mhi, a))
      +qf = band_qf(fr, r, a, b)
      +kpl = frag_keep(qf, fr, True{}, surf, op, side, fds, fbb,
        bb_tiny(qg_bbox(QC.qf_outer(qf))), [], same, False{})
      +krm = isl_rimkeep(fr, a, b, mlo, mhi, rc, surf, op, side, fds, fbb)
      +keep = Bool.pick(U64, noring, kpl, krm)
      +k0 = U64.is_eq(keep, 0u64)
      +k1 = U64.is_eq(keep, 1u64)
      +ig = isl_go(prs, ring_action(prs, ax, a, b), fr, surf, same, flip, side, ax, a, b,
        st, eps, keep)
      +bf = band_face(st, fr, surf, same, flip, side, ax, r, a, b, rim_lo, rim_hi, eps,
        prs, keep)
      +st1 = Bool.pick(AS, k0, ase_st(ig), ase_st(bf))
      +igfail = Bool.and(k0, Bool.not(ase_ok(ig)))
      +badkeep = Bool.and(Bool.not(k0), Bool.not(k1))
      +fatal = Bool.or(Nat.is_eq(rc, 2n), Bool.or(igfail, badkeep))
      +why = Bool.pick(U64, Nat.is_eq(rc, 2n), KC.kr_offdomain(),
        Bool.pick(U64, igfail, ase_why(ig),
          Bool.pick(U64, U64.is_eq(keep, 3u64), 45u64, 38u64)))
      Bool.pick(ASE, fatal, band_abort(rest, ASE{st, False{}, why}),
        band_go2fr(rest, b, st1, fr, surf, same, flip, op, side, fds, fbb, ax, r, rim_lo,
          rim_hi, eps, prs))

def band_go2fr_dj(+empty: Bool, t: List<&2, F64>, +a: F64, +st: AS, +fr: FR,
    +surf: List<&2, G.GVal>, +same: Bool, +flip: Bool, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +ax: U64, +r: F64, +rim_lo: RIM,
    +rim_hi: RIM, +eps: F64, +prs: List<&2, RX.RING>) -> ASE:
  match empty:
    case True{}:
      band_go2f(t, a, st, fr, surf, same, flip, op, side, fds, fbb, ax, r, rim_lo, rim_hi,
        eps, prs)
    case False{}:
      band_go2fr(t, a, st, fr, surf, same, flip, op, side, fds, fbb, ax, r, rim_lo, rim_hi,
        eps, prs)

def band_go2(+t: List<&2, F64>, +a: F64, +st: AS, +fr: FR, +surf: List<&2, G.GVal>,
    +same: Bool, +flip: Bool, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>,
    +ax: U64, +r: F64, +rim_lo: RIM, +rim_hi: RIM, +eps: F64,
    +cuts: List<&2, V.Vec2>, +prs: List<&2, RX.RING>) -> ASE:
  +hascuts = Bool.not(Nat.is_eq(List.length(&2, V.Vec2, cuts), 0n))
  +hasrings = Bool.not(Nat.is_eq(List.length(&2, RX.RING, prs), 0n))
  Bool.pick(ASE, Bool.and(hascuts, hasrings),
    band_abort(t, ASE{st, False{}, KC.kr_nonconic()}),
    Bool.pick(ASE, hascuts,
      band_go2t(t, a, st, fr, surf, same, op, side, fds, fbb, r, cuts, eps),
      band_go2fr_dj(Nat.is_eq(List.length(&2, RX.RING, prs), 0n), t, a, st, fr, surf,
        same, flip, op, side, fds, fbb, ax, r, rim_lo, rim_hi, eps, prs)))

def band_go2head(hs: List<&2, F64>, +st: AS, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool,
    +flip: Bool, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +ax: U64,
    +r: F64, +rim_lo: RIM, +rim_hi: RIM, +eps: F64, +cuts: List<&2, V.Vec2>,
    +prs: List<&2, RX.RING>) -> ASE:
  match hs:
    case []: ASE{st, True{}, 0u64}
    case +a <> +t:
      band_go2(t, a, st, fr, surf, same, flip, op, side, fds, fbb, ax, r, rim_lo, rim_hi,
        eps, cuts, prs)

type RH is Data:
  RH{ ok: Bool, hs: List<&2, F64> }

def rh_ok(+r: RH) -> Bool:
  RH{ok, hs} = r
  ok

def rh_hs(+r: RH) -> List<&2, F64>:
  RH{ok, hs} = r
  hs

def rg_heights_go(rs: List<&2, RG>, +ax: U64, +o: V.Point, +z0: F64, +z1: F64, +eps2: F64,
    +acc: List<&2, F64>) -> RH:
  match rs:
    case []: RH{True{}, acc}
    case +h <> +t:
      +cc = rg_cc(h)
      +c = pcomp(G.cc_c(cc), ax)
      +dx = F64.sub(pcomp(G.cc_c(cc), run0_ax(ax)), pcomp(o, run0_ax(ax)))
      +dy = F64.sub(pcomp(G.cc_c(cc), run1_ax(ax)), pcomp(o, run1_ax(ax)))
      +d2 = F64.add(F64.mul(dx, dx), F64.mul(dy, dy))
      +concen = F64.is_le(d2, eps2)
      +inside = Bool.and(F64.is_lt(z0, c), F64.is_lt(c, z1))
      +rest = rg_heights_go(t, ax, o, z0, z1, eps2,
        Bool.pick(List<&2, F64>, inside, c <> acc, acc))
      RH{Bool.and(concen, rh_ok(rest)), rh_hs(rest)}

def face_cyl_rhgo(hs0: List<&2, F64>, +b: Ty.Brep, +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>,
    +same: Bool, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +st: AS,
    +eps: F64, +ax: U64, +z0: F64, +z1: F64, +rlo: RIM, +rhi: RIM,
    +cuts: List<&2, V.Vec2>, +prs: List<&2, RX.RING>) -> ASE:
  +hs = List.append(&2, F64, [z0], List.append(&2, F64, rq_ts_sort(hs0, []), [z1]))
  band_go2head(hs, st, fr, surf, same, KC.kflip(op, side), op, side, fds, fbb, ax, fr_r(fr),
    rlo, rhi, eps, cuts, prs)

def face_cyl_rimok(rs: List<&2, RG>, +prs: List<&2, RX.RING>, +b: Ty.Brep, +fi: Nat, +fr: FR,
    +surf: List<&2, G.GVal>, +same: Bool, +op: U64, +side: U64, +fds: List<&2, SO.Fd>,
    +fbb: List<&2, I.I>, +st: AS, +eps: F64, +ax: U64, +rlo: RIM, +rhi: RIM,
    +cuts: List<&2, V.Vec2>) -> ASE:
  +z0 = pcomp(G.cc_c(rim_cc(rlo)), ax)
  +z1 = pcomp(G.cc_c(rim_cc(rhi)), ax)
  +rh = rg_heights_go(rs, ax, fr_o(fr), z0, z1, F64.mul(eps, eps), [])
  Bool.pick(ASE, rh_ok(rh), face_cyl_rhgo(rh_hs(rh), b, fi, fr, surf, same, op, side, fds,
    fbb, st, eps, ax, z0, z1, rlo, rhi, cuts, prs), ASE{st, False{}, 49u64})

def face_cyl_run(rs: List<&2, RG>, +prs: List<&2, RX.RING>, +b: Ty.Brep, +fi: Nat, +fr: FR,
    +surf: List<&2, G.GVal>, +same: Bool, +ks: List<&2, KU.KA>, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +ob: Ty.Brep, +st: AS, +eps: F64) -> ASE:
  +ax = fr_ax(fr)
  +rlo = wall_rim(b, fi, True{})
  +rhi = wall_rim(b, fi, False{})
  +ok = Bool.and(rim_ok(rlo), rim_ok(rhi))
  +tc = tcut_for(ks, fi, side, ob, fr, pcomp(G.cc_c(rim_cc(rlo)), ax),
    pcomp(G.cc_c(rim_cc(rhi)), ax))
  Bool.pick(ASE, ok,
    Bool.pick(ASE, tc_ok(tc),
      face_cyl_rimok(rs, prs, b, fi, fr, surf, same, op, side, fds, fbb, st, eps, ax, rlo,
        rhi, tc_pts(tc)),
      ASE{st, False{}, tc_why(tc)}),
    ASE{st, False{}, 48u64})

def face_cyl_bands(+lok: Bool, +fok: Bool, +fwhy: U64, rs: List<&2, RG>,
    +prs: List<&2, RX.RING>, +b: Ty.Brep, +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>,
    +same: Bool, +ks: List<&2, KU.KA>, +op: U64, +side: U64, +fds: List<&2, SO.Fd>,
    +fbb: List<&2, I.I>, +ob: Ty.Brep, +st: AS, +eps: F64) -> ASE:
  match lok:
    case False{}: ASE{st, False{}, 36u64}
    case True{}:
      match fok:
        case False{}: ASE{st, False{}, fwhy}
        case True{}:
          face_cyl_run(rs, prs, b, fi, fr, surf, same, ks, op, side, fds, fbb, ob, st, eps)

def face_cyl(+b: Ty.Brep, +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool,
    +ks: List<&2, KU.KA>, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>,
    +ob: Ty.Brep, +st: AS, +eps: F64) -> ASE:
  +lq = face_qg(b, fi, fr, True{})
  +fc = face_cuts(ks, fi, side, fr_ax(fr), True{}, 0n)
  +nl = List.length(&2, CUT, cuts_noring(fc_cuts(fc)))
  +noln = Nat.is_eq(nl, 0n)
  Bool.pick(ASE, noln,
    face_cyl_bands(lq_ok(lq), fc_ok(fc), fc_why(fc), fc_rings(fc), fc_prings(fc), b, fi, fr,
      surf, same, ks, op, side, fds, fbb, ob, st, eps),
    ASE{st, False{}, 47u64})

def side_face(+valid: Bool, +cyl: Bool, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool, +b: Ty.Brep,
    +ob: Ty.Brep, +fi: Nat, +ks: List<&2, KU.KA>, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>,
    +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +eps: F64) -> ASE:
  match valid:
    case False{}: ASE{st, False{}, 29u64}
    case True{}:
      match cyl:
        case True{}: face_cyl(b, fi, fr, surf, same, ks, op, side, fds, fbb, ob, st, eps)
        case False{}:
          face_pl(b, ob, fi, fr, surf, same, ks, op, side, fds, fbb, fdo, bbo, ba, bb, st,
            eps)

def side_go(fs: List<&2, Ty.Face>, +b: Ty.Brep, +ob: Ty.Brep, +fi: Nat,
    +ks: List<&2, KU.KA>, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>,
    +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>, +ba: Ty.Brep, +bb: Ty.Brep, +st: AS,
    +eps: F64) -> ASE:
  match fs:
    case []: ASE{st, True{}, 0u64}
    case +h <> +t:
      +surf = Ty.fa_surf(h)
      +same = Ty.fa_same(h)
      +fr = fr_of(surf, KU.surfkind(surf))
      +r = side_face(fr_valid(fr), fr_cyl(fr), fr, [surf], same, b, ob, fi, ks, op, side,
        fds, fbb, fdo, bbo, ba, bb, st, eps)
      +rr = side_go(t, b, ob, Nat.add(fi, 1n), ks, op, side, fds, fbb, fdo, bbo, ba, bb,
        ase_st(r), eps)
      ASE{ase_st(rr), Bool.and(ase_ok(r), ase_ok(rr)),
        Bool.pick(U64, ase_ok(r), ase_why(rr), ase_why(r))}

def preadopt_go(vs: List<&2, Ty.Vertex>, +st: AS, +eps: F64) -> AS:
  match vs:
    case []: st
    case +h <> +t: preadopt_go(t, vr_st(vadopt(st, Ty.vx_p(h), eps)), eps)

def preadopt(+ba: Ty.Brep, +bb: Ty.Brep, +eps: F64) -> AS:
  preadopt_go(Ty.brep_vs(bb), preadopt_go(Ty.brep_vs(ba), as_empty(), eps), eps)

def loop_eis_go(cs: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>,
    +acc: List<&2, Nat>) -> List<&2, Nat>:
  match cs:
    case []: acc
    case +h <> +t:
      loop_eis_go(t, ces, Ty.he_idx(Ty.ce_edge(KU.nth_ce0(ces, Ty.hc_idx(h)))) <> acc)

def loop_eis(cs: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>) -> List<&2, Nat>:
  loop_eis_go(cs, ces, [])

def face_eis_go(ls: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +acc: List<&2, Nat>) -> List<&2, Nat>:
  match ls:
    case []: acc
    case +h <> +t:
      face_eis_go(t, lps, ces,
        List.append(&2, Nat, acc, loop_eis(Ty.lp_ces(KU.nth_lp0(lps, Ty.hlp_idx(h))), ces)))

def face_eis(+ls: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>,
    +ces: List<&2, Ty.Coedge>) -> List<&2, Nat>:
  face_eis_go(ls, lps, ces, [])

def faces_eis(fs: List<&2, Ty.Face>, +lps: List<&2, Ty.Loop>,
    +ces: List<&2, Ty.Coedge>) -> List<&2, List<&2, Nat>>:
  match fs:
    case []: []
    case +h <> +t: face_eis(Ty.fa_loops(h), lps, ces) <> faces_eis(t, lps, ces)

def nat_mem(+x: Nat, xs: List<&2, Nat>) -> Bool:
  match xs:
    case []: False{}
    case +h <> +t: Bool.or(Nat.is_eq(x, h), nat_mem(x, t))

def efaces_go(fs: List<&2, List<&2, Nat>>, +e: Nat, +i: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match fs:
    case []: acc
    case +h <> +t: efaces_go(t, e, Nat.add(i, 1n),
      Bool.pick(List<&2, Nat>, nat_mem(e, h), i <> acc, acc))

def efaces(+fs: List<&2, List<&2, Nat>>, +e: Nat) -> List<&2, Nat>:
  efaces_go(fs, e, 0n, [])

def nat_nth(xs: List<&2, Nat>, +i: Nat) -> Nat:
  match xs:
    case []: 0n
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nat_nth(t, j)

def ufind_f(fuel: Nat, +p: List<&2, Nat>, +x: Nat) -> Nat:
  match fuel:
    case 0n: x
    case 1n++j:
      +r = nat_nth(p, x)
      Bool.pick(Nat, Nat.is_eq(r, x), x, ufind_f(j, p, r))

def uset_go(xs: List<&2, Nat>, +at: Nat, +i: Nat, +v: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case []: List.reverse(&2, Nat, acc)
    case +h <> +t: uset_go(t, Nat.add(at, 1n), i, v,
      Bool.pick(Nat, Nat.is_eq(at, i), v, h) <> acc)

def uset(xs: List<&2, Nat>, +i: Nat, +v: Nat) -> List<&2, Nat>:
  uset_go(xs, 0n, i, v, [])

def uunion(+p: List<&2, Nat>, +a: Nat, +b: Nat, +n: Nat) -> List<&2, Nat>:
  +ra = ufind_f(n, p, a)
  +rb = ufind_f(n, p, b)
  Bool.pick(List<&2, Nat>, Nat.is_eq(ra, rb), p, uset(p, ra, rb))

def ul_go(fs: List<&2, Nat>, +fst: Nat, +p: List<&2, Nat>, +n: Nat) -> List<&2, Nat>:
  match fs:
    case []: p
    case +h <> +t: ul_go(t, fst, uunion(p, fst, h, n), n)

def ul_go2(fs: List<&2, Nat>, +p: List<&2, Nat>, +n: Nat) -> List<&2, Nat>:
  match fs:
    case []: p
    case +f <> +t: ul_go(t, f, p, n)

def erange(n: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n: acc
    case 1n++j: erange(j, j <> acc)

def comps_go(es: List<&2, Nat>, +fe: List<&2, List<&2, Nat>>, +p: List<&2, Nat>,
    +n: Nat) -> List<&2, Nat>:
  match es:
    case []: p
    case +e <> +t: comps_go(t, fe, ul_go2(efaces(fe, e), p, n), n)

def comps_of(+st: AS) -> List<&2, Nat>:
  +fas = as_fas(st)
  +fe = faces_eis(fas, as_lps(st), as_ces(st))
  +n = as_nf(st)
  comps_go(erange(as_ne(st), []), fe, erange(n, []), n)

type GRP is Data:
  GRP{ r: Nat, fs: List<&2, Nat> }

def grp_r(+r: GRP) -> Nat:
  GRP{r, fs} = r
  r

def grp_fs(+r: GRP) -> List<&2, Nat>:
  GRP{r, fs} = r
  fs

def gadd(g: List<&2, GRP>, +r: Nat, +f: Nat) -> List<&2, GRP>:
  match g:
    case []: [GRP{r, [f]}]
    case +h <> +t:
      Bool.pick(List<&2, GRP>, Nat.is_eq(grp_r(h), r), GRP{r, f <> grp_fs(h)} <> t,
        h <> gadd(t, r, f))

def groups_go(fs: List<&2, Nat>, +p: List<&2, Nat>, +n: Nat,
    +acc: List<&2, GRP>) -> List<&2, GRP>:
  match fs:
    case []: acc
    case +e <> +t: groups_go(t, p, n, gadd(acc, ufind_f(n, p, e), e))

def hfas_of(fs: List<&2, Nat>, +acc: List<&2, Ty.HFace>) -> List<&2, Ty.HFace>:
  match fs:
    case []: List.reverse(&2, Ty.HFace, acc)
    case +h <> +t: hfas_of(t, hfa(h) <> acc)

def hsos_of(n: Nat, +acc: List<&2, Ty.HSolid>) -> List<&2, Ty.HSolid>:
  match n:
    case 0n: acc
    case 1n++j: hsos_of(j, hso(j) <> acc)

def hshs_of(n: Nat, +acc: List<&2, Ty.HShell>) -> List<&2, Ty.HShell>:
  match n:
    case 0n: acc
    case 1n++j: hshs_of(j, hsh(j) <> acc)

def tmpsos(n: Nat, +acc: List<&2, Ty.Solid>) -> List<&2, Ty.Solid>:
  match n:
    case 0n: acc
    case 1n++j:
      +hs = hsh(j)
      tmpsos(j, Ty.So{0u64, hs, []} <> acc)

def k1temp(+vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>,
    +lps: List<&2, Ty.Loop>, +fas: List<&2, Ty.Face>, +shs: List<&2, Ty.Shell>,
    +sos: List<&2, Ty.Solid>, +hsos: List<&2, Ty.HSolid>,
    +hshs: List<&2, Ty.HShell>) -> Ty.Brep:
  Ty.Br{vs, es, ces, lps, fas, shs, sos, Ty.Cp{hsos, hshs}, 0u64}

def comp_sample_ce(cs: List<&2, Ty.HCoedge>, +st: AS) -> V.Point:
  match cs:
    case []: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case +h <> +t:
      +ce = KU.nth_ce0(as_ces(st), Ty.hc_idx(h))
      +ed = KU.nth_ed0(as_es(st), Ty.he_idx(Ty.ce_edge(ce)))
      Ty.vx_p(KU.nth_vx0(as_vs(st), Ty.hv_idx(Ty.ed_v0(ed))))

def comp_sample_lp(ls: List<&2, Ty.HLoop>, +st: AS) -> V.Point:
  match ls:
    case []: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case +h <> +t:
      +lp = KU.nth_lp0(as_lps(st), Ty.hlp_idx(h))
      comp_sample_ce(Ty.lp_ces(lp), st)

def comp_sample(+faces: List<&2, Nat>, +st: AS) -> V.Point:
  match faces:
    case []: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case +f <> +t:
      +fa = KU.nth_fa0(as_fas(st), f)
      comp_sample_lp(Ty.fa_loops(fa), st)

def comp_fds_go(fs: List<&2, SO.Fd>, +inc: List<&2, Nat>, +acc: List<&2, SO.Fd>) -> List<&2, SO.Fd>:
  match fs:
    case []: acc
    case +h <> +t: comp_fds_go(t, inc,
      Bool.pick(List<&2, SO.Fd>, nat_mem(SO.fd_fi(h), inc), h <> acc, acc))

def comp_fds(+fs: List<&2, SO.Fd>, +inc: List<&2, Nat>) -> List<&2, SO.Fd>:
  comp_fds_go(fs, inc, [])

def cav_find_step(+skip: Bool, +pt: V.Point, +fds: List<&2, SO.Fd>, +h: GRP, +gi: Nat,
    +acc: Nat, +nf: Nat) -> Nat:
  match skip:
    case True{}: acc
    case False{}:
      +of = comp_fds(fds, grp_fs(h))
      +c = SO.classify_in(of, SO.bbox(of, []), pt)
      Bool.pick(Nat, Bool.and(U64.is_eq(c, 1u64), Nat.is_eq(acc, nf)), gi, acc)

def cav_find_go(gs: List<&2, GRP>, +pt: V.Point, +fds: List<&2, SO.Fd>, +own: Nat, +gi: Nat,
    +acc: Nat, +nf: Nat) -> Nat:
  match gs:
    case []: acc
    case +h <> +t:
      cav_find_go(t, pt, fds, own, Nat.add(gi, 1n),
        cav_find_step(Nat.is_eq(grp_r(h), own), pt, fds, h, gi, acc, nf), nf)

def cav_find(+gs: List<&2, GRP>, +pt: V.Point, +fds: List<&2, SO.Fd>, +own: Nat,
    +nf: Nat) -> Nat:
  cav_find_go(gs, pt, fds, own, 0n, nf, nf)

def sk_of(+o: Bool) -> Ty.ShellKind:
  Bool.pick(Ty.ShellKind, o, Ty.SK_outer{}, Ty.SK_inner{})

def shells_go(gs: List<&2, GRP>, +conts: List<&2, Nat>, +nf: Nat, +acc: List<&2, Ty.Shell>, +gi: Nat) -> List<&2, Ty.Shell>:
  match gs:
    case []: List.reverse(&2, Ty.Shell, acc)
    case +h <> +t:
      +fh = hfas_of(grp_fs(h), [])
      +sk = sk_of(Nat.is_eq(nat_nth(conts, gi), nf))
      shells_go(t, conts, nf, Ty.Sh{gen1(gi), fh, sk} <> acc, Nat.add(gi, 1n))

def shells_of(gs: List<&2, GRP>) -> List<&2, Ty.Shell>:
  shells_go(gs, [], 0n, [], 0n)

def cont_ok_go(cs: List<&2, Nat>, +full: List<&2, Nat>, +nf: Nat, +ok: Bool) -> Bool:
  match cs:
    case []: ok
    case +h <> +t: cont_ok_go(t, full, nf,
      Bool.and(ok, Bool.or(Nat.is_eq(h, nf), Nat.is_eq(nat_nth(full, h), nf))))

def cont_ok(+cs: List<&2, Nat>, +nf: Nat) -> Bool:
  cont_ok_go(cs, cs, nf, True{})

def conts_go(gs: List<&2, GRP>, +all: List<&2, GRP>, +st: AS, +fds: List<&2, SO.Fd>,
    +nf: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match gs:
    case []: List.reverse(&2, Nat, acc)
    case +h <> +t:
      +pt = comp_sample(grp_fs(h), st)
      conts_go(t, all, st, fds, nf, cav_find(all, pt, fds, grp_r(h), nf) <> acc)

def conts_of(+gs: List<&2, GRP>, +st: AS, +fds: List<&2, SO.Fd>, +nf: Nat) -> List<&2, Nat>:
  conts_go(gs, gs, st, fds, nf, [])

def cavs_go(cs: List<&2, Nat>, +i: Nat, +gi: Nat, +acc: List<&2, Ty.HShell>) -> List<&2, Ty.HShell>:
  match cs:
    case []: acc
    case +h <> +t: cavs_go(t, i, Nat.add(gi, 1n),
      Bool.pick(List<&2, Ty.HShell>, Nat.is_eq(h, i), hsh(gi) <> acc, acc))

def solids_go(gs: List<&2, GRP>, +conts: List<&2, Nat>, +gi: Nat, +nf: Nat,
    +acc: List<&2, Ty.Solid>, +si: Nat) -> List<&2, Ty.Solid>:
  match gs:
    case []: List.reverse(&2, Ty.Solid, acc)
    case +h <> +t:
      +c = nat_nth(conts, gi)
      +cv = cavs_go(conts, gi, 0n, [])
      +hs = hsh(gi)
      +keep = Nat.is_eq(c, nf)
      solids_go(t, conts, Nat.add(gi, 1n), nf,
        Bool.pick(List<&2, Ty.Solid>, keep, Ty.So{gen1(si), hs, cv} <> acc, acc),
        Bool.pick(Nat, keep, Nat.add(si, 1n), si))

type KAB is Data:
  KAB{ ok: Bool, why: U64, brep: Ty.Brep }

def kab_ok(+r: KAB) -> Bool:
  KAB{ok, why, brep} = r
  ok

def kab_why(+r: KAB) -> U64:
  KAB{ok, why, brep} = r
  why

def kab_brep(+r: KAB) -> Ty.Brep:
  KAB{ok, why, brep} = r
  brep

def k1asm_sos(+none: Bool, +sos: List<&2, Ty.Solid>, +vs: List<&2, Ty.Vertex>,
    +es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>, +lps: List<&2, Ty.Loop>,
    +fas: List<&2, Ty.Face>, +shs: List<&2, Ty.Shell>, +ns: Nat, +no: Nat) -> KAB:
  match none:
    case True{}: KAB{False{}, 40u64, k1temp(vs, es, ces, lps, fas, shs, sos, [], [])}
    case False{}:
      KAB{True{}, 0u64, k1temp(vs, es, ces, lps, fas, shs, sos, hsos_of(no, []), [])}

def k1asm_fin(+cok: Bool, +cntok: Bool, +conts: List<&2, Nat>, +gs: List<&2, GRP>,
    +vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>,
    +lps: List<&2, Ty.Loop>, +fas: List<&2, Ty.Face>, +shs: List<&2, Ty.Shell>, +ns: Nat,
    +st: AS) -> KAB:
  match cok:
    case False{}: KAB{False{}, 31u64, k1temp(vs, es, ces, lps, fas, shs, [], [], [])}
    case True{}:
      match cntok:
        case False{}: KAB{False{}, 44u64, k1temp(vs, es, ces, lps, fas, shs, [], [], [])}
        case True{}:
          +sos = solids_go(gs, conts, 0n, as_nf(st), [], 0n)
          +no = List.length(&2, Ty.Solid, sos)
          +shk = shells_go(gs, conts, as_nf(st), [], 0n)
          k1asm_sos(Nat.is_eq(no, 0n), sos, vs, es, ces, lps, fas, shk, ns, no)

def k1asm_nf(+empty: Bool, +st: AS) -> KAB:
  match empty:
    case True{}: KAB{False{}, 40u64, k1temp([], [], [], [], [], [], [], [], [])}
    case False{}:
      +p = comps_of(st)
      +n = as_nf(st)
      +gs = groups_go(erange(n, []), p, n, [])
      +shs = shells_of(gs)
      +ns = List.length(&2, Ty.Shell, shs)
      +sos0 = tmpsos(ns, [])
      +vs = as_vs(st)
      +es = as_es(st)
      +ces = as_ces(st)
      +lps = as_lps(st)
      +fas = as_fas(st)
      +hsos = hsos_of(ns, [])
      +hshs = hshs_of(ns, [])
      +fds = SO.fds_of(k1temp(vs, es, ces, lps, fas, shs, sos0, hsos, hshs))
      +conts = conts_of(gs, st, fds, n)
      +cntok = Bool.and(Nat.is_eq(as_nv(st), List.length(&2, Ty.Vertex, vs)),
        Bool.and(Nat.is_eq(as_ne(st), List.length(&2, Ty.Edge, es)),
          Bool.and(Nat.is_eq(as_nc(st), List.length(&2, Ty.Coedge, ces)),
            Bool.and(Nat.is_eq(as_nl(st), List.length(&2, Ty.Loop, lps)),
              Nat.is_eq(as_nf(st), List.length(&2, Ty.Face, fas))))))
      k1asm_fin(cont_ok(conts, n), cntok, conts, gs, vs, es, ces, lps, fas, shs, ns, st)

def as_rev(+a: AS) -> AS:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  AS{List.reverse(&2, Ty.Vertex, vs), List.reverse(&2, Ty.Edge, es),
    List.reverse(&2, Ty.Coedge, ces), List.reverse(&2, Ty.Loop, lps),
    List.reverse(&2, Ty.Face, fas), List.reverse(&2, EK, eks), nv, ne, nc, nl, nf, ms, nm}

type VS2 is Data:
  VS2{ vs: List<&2, Ty.Vertex>, mp: List<&2, Nat> }

def vzeros(n: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n: acc
    case 1n++j: vzeros(j, 0n <> acc)

def vmark_go(es: List<&2, Ty.Edge>, +used: List<&2, Nat>) -> List<&2, Nat>:
  match es:
    case []: used
    case +h <> +t:
      vmark_go(t, uset(uset(used, Ty.hv_idx(Ty.ed_v0(h)), 1n), Ty.hv_idx(Ty.ed_v1(h)), 1n))

def vprune_go(fs: List<&2, Nat>, vs: List<&2, Ty.Vertex>, +new: Nat,
    +vcc: List<&2, Ty.Vertex>, +mcc: List<&2, Nat>) -> VS2:
  match fs vs:
    case +f <> +u +h <> +t:
      +used = Nat.is_eq(f, 1n)
      vprune_go(u, t, Bool.pick(Nat, used, Nat.add(new, 1n), new),
        Bool.pick(List<&2, Ty.Vertex>, used, Ty.Vx{gen1(new), Ty.vx_p(h)} <> vcc, vcc),
        Bool.pick(List<&2, Nat>, used, new <> mcc, 0n <> mcc))
    case _ _: VS2{List.reverse(&2, Ty.Vertex, vcc), List.reverse(&2, Nat, mcc)}

def ereidx_go(es: List<&2, Ty.Edge>, +mp: List<&2, Nat>, +acc: List<&2, Ty.Edge>) -> List<&2, Ty.Edge>:
  match es:
    case []: List.reverse(&2, Ty.Edge, acc)
    case +h <> +t:
      Ty.Ed{+g, +v0, +v1, +k} = h
      ereidx_go(t, mp, Ty.Ed{g, hv(nat_nth(mp, Ty.hv_idx(v0))), hv(nat_nth(mp, Ty.hv_idx(v1))),
        k} <> acc)

def vs2_vs(+r: VS2) -> List<&2, Ty.Vertex>:
  VS2{vs, mp} = r
  vs

def vs2_mp(+r: VS2) -> List<&2, Nat>:
  VS2{vs, mp} = r
  mp

def k1prune(+st: AS) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = st
  +used = vmark_go(es, vzeros(nv, []))
  +pr = vprune_go(used, vs, 0n, [], [])
  +vs2 = vs2_vs(pr)
  +mp = vs2_mp(pr)
  AS{vs2, ereidx_go(es, mp, []), ces, lps, fas, eks, List.length(&2, Ty.Vertex, vs2), ne, nc,
    nl, nf, ms, nm}

def k1assemble(+st: AS) -> KAB:
  +n = as_nf(st)
  k1asm_nf(Nat.is_eq(n, 0n), k1prune(as_rev(st)))

def k1ed_gen(+e: Ty.Edge) -> U64:
  Ty.Ed{+g, +a, +b, +k} = e
  g

def k1hs_idx(+h: Ty.HShell) -> Nat:
  Ty.HS{+i, +g} = h
  i

def k1hs_gen(+h: Ty.HShell) -> U64:
  Ty.HS{+i, +g} = h
  g

def k1hcs_go(cs: List<&2, Ty.HCoedge>, +nc: Nat, +ok: Bool) -> Bool:
  match cs:
    case []: ok
    case +h <> +t: k1hcs_go(t, nc, Bool.and(ok, Nat.is_lt(Ty.hc_idx(h), nc)))

def k1hcs(cs: List<&2, Ty.HCoedge>, +nc: Nat) -> Bool:
  k1hcs_go(cs, nc, True{})

def k1hls_go(ls: List<&2, Ty.HLoop>, +nl: Nat, +ok: Bool) -> Bool:
  match ls:
    case []: ok
    case +h <> +t: k1hls_go(t, nl, Bool.and(ok, Nat.is_lt(Ty.hlp_idx(h), nl)))

def k1hls(ls: List<&2, Ty.HLoop>, +nl: Nat) -> Bool:
  k1hls_go(ls, nl, True{})

def k1hfs_go(fs: List<&2, Ty.HFace>, +nf: Nat, +ok: Bool) -> Bool:
  match fs:
    case []: ok
    case +h <> +t: k1hfs_go(t, nf, Bool.and(ok, Nat.is_lt(Ty.hfa_idx(h), nf)))

def k1hfs(fs: List<&2, Ty.HFace>, +nf: Nat) -> Bool:
  k1hfs_go(fs, nf, True{})

def k1hss_go(ss: List<&2, Ty.HShell>, +nsh: Nat, +ok: Bool) -> Bool:
  match ss:
    case []: ok
    case +h <> +t: k1hss_go(t, nsh, Bool.and(ok, Nat.is_lt(k1hs_idx(h), nsh)))

def k1hss(ss: List<&2, Ty.HShell>, +nsh: Nat) -> Bool:
  k1hss_go(ss, nsh, True{})

def k1hso_go(ss: List<&2, Ty.HSolid>, +nso: Nat, +ok: Bool) -> Bool:
  match ss:
    case []: ok
    case +h <> +t: k1hso_go(t, nso, Bool.and(ok, Nat.is_lt(Ty.hso_idx(h), nso)))

def k1hso(ss: List<&2, Ty.HSolid>, +nso: Nat) -> Bool:
  k1hso_go(ss, nso, True{})

def k1top(+top: Ty.Compound, +nso: Nat, +nsh: Nat) -> Bool:
  Bool.and(k1hso(Ty.cp_solids(top), nso), k1hss(Ty.cp_shells(top), nsh))

def k1vs_go(vs: List<&2, Ty.Vertex>, +i: Nat, +ok: Bool) -> Bool:
  match vs:
    case []: ok
    case +h <> +t: k1vs_go(t, Nat.add(i, 1n), Bool.and(ok, U64.is_eq(Ty.vx_gen(h), gen1(i))))

def k1es_go(es: List<&2, Ty.Edge>, +i: Nat, +nv: Nat, +ok: Bool) -> Bool:
  match es:
    case []: ok
    case +h <> +t:
      +e0 = Ty.hv_idx(Ty.ed_v0(h))
      +e1 = Ty.hv_idx(Ty.ed_v1(h))
      k1es_go(t, Nat.add(i, 1n), nv,
        Bool.and(ok, Bool.and(Nat.is_lt(e0, nv),
          Bool.and(Nat.is_lt(e1, nv), U64.is_eq(k1ed_gen(h), gen1(i))))))

def k1ces_go(cs: List<&2, Ty.Coedge>, +i: Nat, +ne: Nat, +ok: Bool) -> Bool:
  match cs:
    case []: ok
    case +h <> +t:
      k1ces_go(t, Nat.add(i, 1n), ne,
        Bool.and(ok, Bool.and(Nat.is_lt(Ty.he_idx(Ty.ce_edge(h)), ne),
          U64.is_eq(Ty.ce_gen(h), gen1(i)))))

def k1lps_go(ls: List<&2, Ty.Loop>, +i: Nat, +nc: Nat, +ok: Bool) -> Bool:
  match ls:
    case []: ok
    case +h <> +t:
      k1lps_go(t, Nat.add(i, 1n), nc,
        Bool.and(ok, Bool.and(k1hcs(Ty.lp_ces(h), nc), U64.is_eq(Ty.lp_gen(h), gen1(i)))))

def k1fas_go(fs: List<&2, Ty.Face>, +i: Nat, +nl: Nat, +ok: Bool) -> Bool:
  match fs:
    case []: ok
    case +h <> +t:
      k1fas_go(t, Nat.add(i, 1n), nl,
        Bool.and(ok, Bool.and(k1hls(Ty.fa_loops(h), nl), U64.is_eq(Ty.fa_gen(h), gen1(i)))))

def k1shs_go(ss: List<&2, Ty.Shell>, +i: Nat, +nf: Nat, +ok: Bool) -> Bool:
  match ss:
    case []: ok
    case +h <> +t:
      k1shs_go(t, Nat.add(i, 1n), nf,
        Bool.and(ok, Bool.and(k1hfs(Ty.sh_faces(h), nf), U64.is_eq(Ty.sh_gen(h), gen1(i)))))

def k1sos_go(ss: List<&2, Ty.Solid>, +i: Nat, +nsh: Nat, +ok: Bool) -> Bool:
  match ss:
    case []: ok
    case +h <> +t:
      k1sos_go(t, Nat.add(i, 1n), nsh,
        Bool.and(ok, Bool.and(Nat.is_lt(k1hs_idx(Ty.so_outer(h)), nsh),
          Bool.and(k1hss(Ty.so_cavities(h), nsh), U64.is_eq(Ty.so_gen(h), gen1(i))))))

def zeros(n: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n: acc
    case 1n++j: zeros(j, 0n <> acc)

def uinc_go(xs: List<&2, Nat>, +at: Nat, +i: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case []: List.reverse(&2, Nat, acc)
    case +h <> +t: uinc_go(t, Nat.add(at, 1n), i,
      Bool.pick(Nat, Nat.is_eq(at, i), Nat.add(h, 1n), h) <> acc)

def uinc(xs: List<&2, Nat>, +i: Nat) -> List<&2, Nat>:
  uinc_go(xs, 0n, i, [])

def k1use_go(cs: List<&2, Ty.Coedge>, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match cs:
    case []: acc
    case +h <> +t: k1use_go(t, uinc(acc, Ty.he_idx(Ty.ce_edge(h))))

def k1use_all(xs: List<&2, Nat>, +ok: Bool) -> Bool:
  match xs:
    case []: ok
    case +h <> +t: k1use_all(t, Bool.and(ok, Nat.is_eq(h, 2n)))

def k1use(+ces: List<&2, Ty.Coedge>, +ne: Nat) -> Bool:
  k1use_all(k1use_go(ces, zeros(ne, [])), True{})

def k1slv_ok(+h: Ty.Face) -> Bool:
  Bool.and(T.is_finite(Ty.fa_slv(h)), Bool.and(T.is_finite(Ty.fa_sla(h)),
    Bool.and(F64.is_le(0.0f64, Ty.fa_slv(h)), F64.is_le(0.0f64, Ty.fa_sla(h)))))

def k1slv_go(fs: List<&2, Ty.Face>, +ok: Bool) -> Bool:
  match fs:
    case []: ok
    case +h <> +t: k1slv_go(t, Bool.and(ok, k1slv_ok(h)))

type KCT is Data:
  KCT{ ok: Bool, why: U64 }

def kct_ok(+r: KCT) -> Bool:
  KCT{ok, why} = r
  ok

def kct_why(+r: KCT) -> U64:
  KCT{ok, why} = r
  why

def k1cert(+b: Ty.Brep) -> KCT:
  +vs = Ty.brep_vs(b)
  +es = Ty.brep_es(b)
  +ces = Ty.brep_ces(b)
  +lps = Ty.brep_lps(b)
  +fas = Ty.brep_fas(b)
  +shs = Ty.brep_shs(b)
  +sos = Ty.brep_sos(b)
  +nv = List.length(&2, Ty.Vertex, vs)
  +ne = List.length(&2, Ty.Edge, es)
  +nc = List.length(&2, Ty.Coedge, ces)
  +nl = List.length(&2, Ty.Loop, lps)
  +nf = List.length(&2, Ty.Face, fas)
  +nsh = List.length(&2, Ty.Shell, shs)
  +nso = List.length(&2, Ty.Solid, sos)
  +idx = Bool.and(k1vs_go(vs, 0n, True{}),
    Bool.and(k1es_go(es, 0n, nv, True{}),
      Bool.and(k1ces_go(ces, 0n, ne, True{}),
        Bool.and(k1lps_go(lps, 0n, nc, True{}),
          Bool.and(k1fas_go(fas, 0n, nl, True{}),
            Bool.and(k1shs_go(shs, 0n, nf, True{}),
              Bool.and(k1sos_go(sos, 0n, nsh, True{}),
                k1top(Ty.brep_top(b), nso, nsh))))))))
  +use = k1use(ces, ne)
  +slv = k1slv_go(fas, True{})
  KCT{Bool.and(idx, Bool.and(use, slv)),
    Bool.pick(U64, idx, Bool.pick(U64, use, Bool.pick(U64, slv, 0u64, 43u64), 42u64), 41u64)}

type KR is Data:
  KR{ ok: Bool, why: U64, brep: Ty.Brep, nv: Nat, ne: Nat, nf: Nat, nc: Nat }

def kr_ok(+r: KR) -> Bool:
  KR{ok, why, brep, nv, ne, nf, nc} = r
  ok

def kr_why(+r: KR) -> U64:
  KR{ok, why, brep, nv, ne, nf, nc} = r
  why

def kr_brep(+r: KR) -> Ty.Brep:
  KR{ok, why, brep, nv, ne, nf, nc} = r
  brep

def kr_nv(+r: KR) -> Nat:
  KR{ok, why, brep, nv, ne, nf, nc} = r
  nv

def kr_ne(+r: KR) -> Nat:
  KR{ok, why, brep, nv, ne, nf, nc} = r
  ne

def kr_nf(+r: KR) -> Nat:
  KR{ok, why, brep, nv, ne, nf, nc} = r
  nf

def kr_nc(+r: KR) -> Nat:
  KR{ok, why, brep, nv, ne, nf, nc} = r
  nc

type K1N is Data:
  K1N{ x: I.I, y: I.I, z: I.I, ok: Bool }

def k1n_x(+n: K1N) -> I.I:
  K1N{x, y, z, ok} = n
  x

def k1n_y(+n: K1N) -> I.I:
  K1N{x, y, z, ok} = n
  y

def k1n_z(+n: K1N) -> I.I:
  K1N{x, y, z, ok} = n
  z

def k1n_ok(+n: K1N) -> Bool:
  K1N{x, y, z, ok} = n
  ok

type K1M is Data:
  K1M{ vol: I.I, ar: I.I, ok: Bool }

def k1m_vol(+m: K1M) -> I.I:
  K1M{vol, ar, ok} = m
  vol

def k1m_ar(+m: K1M) -> I.I:
  K1M{vol, ar, ok} = m
  ar

def k1m_ok(+m: K1M) -> Bool:
  K1M{vol, ar, ok} = m
  ok

def k1tol(+v: F64) -> F64:
  F64.add(F64.mul(F64.abs(v), 1.8e-15f64), 5.0e-13f64)

def k1w(+v: F64) -> I.I:
  +m = F64.add(F64.mul(F64.abs(v), 3.6e-15f64), 1.0e-12f64)
  I.I{F64.sub(v, m), F64.add(v, m)}

def k1iabs(+a: I.I) -> I.I:
  Bool.pick(I.I, F64.is_lt(I.i_hi(a), 0.0f64), I.ineg(a),
    Bool.pick(I.I, F64.is_lt(I.i_lo(a), 0.0f64),
      I.I{0.0f64, F64.max(F64.abs(I.i_lo(a)), F64.abs(I.i_hi(a)))}, a))

def kasin_adm(+y: I.I) -> Bool:
  Bool.and(F64.is_lt(0.0f64, I.i_lo(y)),
    Bool.and(F64.is_le(I.i_lo(y), 1.0f64), F64.is_le(I.i_hi(y), F64.add(1.0f64, 1.0e-12f64))))

def kasin(+y: I.I) -> I.I:
  I.atan2q(y, I.isqrt(I.isub(I.ipt(1.0f64), I.isq(y))))

def k1drop(+p: V.Point, +ax: U64) -> V.Vec2:
  Bool.pick(V.Vec2, U64.is_eq(ax, 0u64), V.V2{V.pt_y(p), V.pt_z(p)},
    Bool.pick(V.Vec2, U64.is_eq(ax, 1u64), V.V2{V.pt_x(p), V.pt_z(p)},
      V.V2{V.pt_x(p), V.pt_y(p)}))

def k1axc(+p: V.Point, +ax: U64) -> F64:
  Bool.pick(F64, U64.is_eq(ax, 0u64), V.pt_x(p),
    Bool.pick(F64, U64.is_eq(ax, 1u64), V.pt_y(p), V.pt_z(p)))

def k1onc(+p: V.Vec2, +c: V.Vec2, +r: F64) -> Bool:
  +dx = F64.sub(V.v2_x(p), V.v2_x(c))
  +dy = F64.sub(V.v2_y(p), V.v2_y(c))
  +d = F64.sqrt(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)))
  F64.is_le(F64.abs(F64.sub(d, r)), k1tol(r))

def k1chord(+a: V.Vec2, +b: V.Vec2) -> I.I:
  +dx = I.isub(k1w(V.v2_x(a)), k1w(V.v2_x(b)))
  +dy = I.isub(k1w(V.v2_y(a)), k1w(V.v2_y(b)))
  I.isqrt(I.iadd(I.isq(dx), I.isq(dy)))

def k1trim_ok(+t: G.GVal) -> Bool:
  match t:
    case G.GV_tb{+w}:
      Bool.and(F64.is_eq(V.v2_x(G.tb_b1(w)), V.v2_x(G.tb_b2(w))),
        F64.is_eq(V.v2_y(G.tb_b1(w)), V.v2_y(G.tb_b2(w))))
    case _: False{}

def k1trim_mid(+t: G.GVal) -> V.Vec2:
  match t:
    case G.GV_tb{+w}:
      +a = G.tb_b0(w)
      +c = G.tb_b1(w)
      +b = G.tb_b3(w)
      V.V2{F64.div(F64.add(V.v2_x(a), F64.add(F64.mul(6.0f64, V.v2_x(c)), V.v2_x(b))), 8.0f64),
        F64.div(F64.add(V.v2_y(a), F64.add(F64.mul(6.0f64, V.v2_y(c)), V.v2_y(b))), 8.0f64)}
    case _: V.V2{0.0f64, 0.0f64}

def k1pteq(+a: V.Point, +b: V.Point) -> Bool:
  Bool.and(F64.is_eq(V.pt_x(a), V.pt_x(b)),
    Bool.and(F64.is_eq(V.pt_y(a), V.pt_y(b)), F64.is_eq(V.pt_z(a), V.pt_z(b))))

def k1d2(+a: V.Vec2, +b: V.Vec2) -> F64:
  +dx = F64.sub(V.v2_x(a), V.v2_x(b))
  +dy = F64.sub(V.v2_y(a), V.v2_y(b))
  F64.sqrt(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)))

def k1d3(+a: V.Point, +b: V.Point) -> F64:
  +dx = F64.sub(V.pt_x(a), V.pt_x(b))
  +dy = F64.sub(V.pt_y(a), V.pt_y(b))
  +dz = F64.sub(V.pt_z(a), V.pt_z(b))
  F64.sqrt(F64.add(F64.mul(dx, dx), F64.add(F64.mul(dy, dy), F64.mul(dz, dz))))

def k1line_nw(+pa: V.Point, +pb: V.Point) -> K1N:
  +ax = k1w(V.pt_x(pa))
  +ay = k1w(V.pt_y(pa))
  +az = k1w(V.pt_z(pa))
  +bx = k1w(V.pt_x(pb))
  +by = k1w(V.pt_y(pb))
  +bz = k1w(V.pt_z(pb))
  K1N{I.isub(I.imul(ay, bz), I.imul(az, by)), I.isub(I.imul(az, bx), I.imul(ax, bz)),
    I.isub(I.imul(ax, by), I.imul(ay, bx)), True{}}

def k1line_nw_w(+pa: V.Point, +pb: V.Point, +w: F64) -> K1N:
  +ax = k1w(V.pt_x(pa))
  +ay = k1w(V.pt_y(pa))
  +az = k1w(V.pt_z(pa))
  +bx = k1w(V.pt_x(pb))
  +by = k1w(V.pt_y(pb))
  +bz = k1w(V.pt_z(pb))
  K1N{I.iwiden(I.isub(I.imul(ay, bz), I.imul(az, by)), w),
    I.iwiden(I.isub(I.imul(az, bx), I.imul(ax, bz)), w),
    I.iwiden(I.isub(I.imul(ax, by), I.imul(ay, bx)), w), True{}}

def k1arc_open(+pa: V.Point, +pb: V.Point, +c3: V.Point, +ccu: V.Dir, +ccv: V.Dir, +r: F64,
    +tm: G.GVal, +fa: U64) -> K1N:
  +a = k1drop(pa, fa)
  +b = k1drop(pb, fa)
  +c = k1drop(c3, fa)
  +m = k1trim_mid(tm)
  +tok = k1trim_ok(tm)
  +ona = k1onc(a, c, r)
  +onb = k1onc(b, c, r)
  +onm = k1onc(m, c, r)
  +dma = Bool.not(Bool.and(F64.is_eq(V.v2_x(m), V.v2_x(a)), F64.is_eq(V.v2_y(m), V.v2_y(a))))
  +dmb = Bool.not(Bool.and(F64.is_eq(V.v2_x(m), V.v2_x(b)), F64.is_eq(V.v2_y(m), V.v2_y(b))))
  +cc = k1axc(c3, fa)
  +tol2 = k1tol(cc)
  +cxa = F64.is_le(F64.abs(F64.sub(k1axc(pa, fa), cc)), tol2)
  +cxb = F64.is_le(F64.abs(F64.sub(k1axc(pb, fa), cc)), tol2)
  +y1 = I.idiv(k1chord(a, m), I.iscale(k1w(r), 2.0f64))
  +y2 = I.idiv(k1chord(m, b), I.iscale(k1w(r), 2.0f64))
  +a1 = kasin_adm(y1)
  +a2 = kasin_adm(y2)
  +dth = I.iadd(I.iscale(kasin(y1), 2.0f64), I.iscale(kasin(y2), 2.0f64))
  +cross = F64.sub(F64.mul(F64.sub(V.v2_x(a), V.v2_x(c)), F64.sub(V.v2_y(m), V.v2_y(c))),
    F64.mul(F64.sub(V.v2_y(a), V.v2_y(c)), F64.sub(V.v2_x(m), V.v2_x(c))))
  +zn = Bool.not(F64.is_eq(cross, 0.0f64))
  +s2 = Bool.pick(F64, F64.is_lt(0.0f64, cross), 1.0f64, F64.neg(1.0f64))
  +st = Bool.pick(F64, U64.is_eq(fa, 1u64), F64.neg(s2), s2)
  +ca = KU.crx(ccu, ccv)
  +dax = Bool.pick(F64, U64.is_eq(fa, 0u64), V.dr_x(ca),
    Bool.pick(F64, U64.is_eq(fa, 1u64), V.dr_y(ca), V.dr_z(ca)))
  +par = F64.is_le(F64.sub(1.0f64, 1.0e-9f64), F64.abs(dax))
  +n1 = F64.add(F64.add(F64.mul(V.dr_x(ca), V.dr_x(ca)), F64.mul(V.dr_y(ca), V.dr_y(ca))),
    F64.mul(V.dr_z(ca), V.dr_z(ca)))
  +ort = F64.is_le(F64.abs(F64.sub(n1, 1.0f64)), 1.0e-9f64)
  +sx = Bool.pick(F64, F64.is_lt(dax, 0.0f64), F64.neg(1.0f64), 1.0f64)
  +sg = F64.mul(st, sx)
  +dths = Bool.pick(I.I, F64.is_lt(0.0f64, sg), dth, I.ineg(dth))
  +ok = Bool.and(tok, Bool.and(ona, Bool.and(onb, Bool.and(onm, Bool.and(dma, Bool.and(dmb,
    Bool.and(cxa, Bool.and(cxb, Bool.and(a1, Bool.and(a2, Bool.and(zn, Bool.and(par, ort))))))))))))
  +cx = k1w(V.pt_x(c3))
  +cy = k1w(V.pt_y(c3))
  +cz = k1w(V.pt_z(c3))
  +ex = I.isub(k1w(V.pt_x(pb)), k1w(V.pt_x(pa)))
  +ey = I.isub(k1w(V.pt_y(pb)), k1w(V.pt_y(pa)))
  +ez = I.isub(k1w(V.pt_z(pb)), k1w(V.pt_z(pa)))
  +ax3 = k1w(V.dr_x(ca))
  +ay3 = k1w(V.dr_y(ca))
  +az3 = k1w(V.dr_z(ca))
  +rr = I.imul(I.isq(k1w(r)), dths)
  K1N{I.iadd(I.isub(I.imul(cy, ez), I.imul(cz, ey)), I.imul(rr, ax3)),
    I.iadd(I.isub(I.imul(cz, ex), I.imul(cx, ez)), I.imul(rr, ay3)),
    I.iadd(I.isub(I.imul(cx, ey), I.imul(cy, ex)), I.imul(rr, az3)), ok}

def k1arc_closed(+c3: V.Point, +ccu: V.Dir, +ccv: V.Dir, +r: F64, +fa: U64, +fc: F64,
    +sc: F64, +sok: Bool) -> K1N:
  +ca = KU.crx(ccu, ccv)
  +dax = Bool.pick(F64, U64.is_eq(fa, 0u64), V.dr_x(ca),
    Bool.pick(F64, U64.is_eq(fa, 1u64), V.dr_y(ca), V.dr_z(ca)))
  +par = F64.is_le(F64.sub(1.0f64, 1.0e-9f64), F64.abs(dax))
  +n1 = F64.add(F64.add(F64.mul(V.dr_x(ca), V.dr_x(ca)), F64.mul(V.dr_y(ca), V.dr_y(ca))),
    F64.mul(V.dr_z(ca), V.dr_z(ca)))
  +ort = F64.is_le(F64.abs(F64.sub(n1, 1.0f64)), 1.0e-9f64)
  +onc = F64.is_le(F64.abs(F64.sub(k1axc(c3, fa), fc)), k1tol(fc))
  +sx = Bool.pick(F64, F64.is_lt(dax, 0.0f64), F64.neg(1.0f64), 1.0f64)
  +ok = Bool.and(sok, Bool.and(par, Bool.and(ort, onc)))
  +t = I.imul(I.ipt(F64.mul(sc, sx)), I.imul(I.iscale(I.pi_i(), 2.0f64), I.isq(k1w(r))))
  K1N{I.imul(t, k1w(V.dr_x(ca))), I.imul(t, k1w(V.dr_y(ca))), I.imul(t, k1w(V.dr_z(ca))), ok}

def k1rq_open(+pa: V.Point, +pb: V.Point, +rq: G.RQBez, +fa: U64, +f: Bool) -> K1N:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = rq
  +w1ok = Bool.and(F64.is_eq(w0, 1.0f64), F64.is_eq(w2, 1.0f64))
  +eok = Bool.pick(Bool, f, Bool.and(k1pteq(p0, pa), k1pteq(p2, pb)),
    Bool.and(k1pteq(p0, pb), k1pteq(p2, pa)))
  +a = k1drop(pa, fa)
  +b = k1drop(pb, fa)
  +c2 = k1drop(p1, fa)
  +den = F64.add(2.0f64, F64.mul(2.0f64, w1))
  +mmx = F64.div(F64.add(V.v2_x(a), F64.add(F64.mul(F64.mul(2.0f64, w1), V.v2_x(c2)), V.v2_x(b))), den)
  +mmy = F64.div(F64.add(V.v2_y(a), F64.add(F64.mul(F64.mul(2.0f64, w1), V.v2_y(c2)), V.v2_y(b))), den)
  +midx = F64.mul(0.5f64, F64.add(V.v2_x(a), V.v2_x(b)))
  +midy = F64.mul(0.5f64, F64.add(V.v2_y(a), V.v2_y(b)))
  +h = F64.mul(0.5f64, k1d2(a, b))
  +sdx = F64.sub(mmx, midx)
  +sdy = F64.sub(mmy, midy)
  +s = F64.sqrt(F64.add(F64.mul(sdx, sdx), F64.mul(sdy, sdy)))
  +dma = Bool.not(Bool.and(F64.is_eq(mmx, V.v2_x(a)), F64.is_eq(mmy, V.v2_y(a))))
  +dmb = Bool.not(Bool.and(F64.is_eq(mmx, V.v2_x(b)), F64.is_eq(mmy, V.v2_y(b))))
  +axp = k1axc(pa, fa)
  +cxa = F64.is_le(F64.abs(F64.sub(k1axc(pb, fa), axp)), k1tol(axp))
  +cxc = F64.is_le(F64.abs(F64.sub(k1axc(p1, fa), axp)), k1tol(axp))
  +m3x = F64.mul(0.5f64, F64.add(V.pt_x(pa), V.pt_x(pb)))
  +m3y = F64.mul(0.5f64, F64.add(V.pt_y(pa), V.pt_y(pb)))
  +m3z = F64.mul(0.5f64, F64.add(V.pt_z(pa), V.pt_z(pb)))
  +chx = F64.sub(V.pt_x(pb), V.pt_x(pa))
  +chy = F64.sub(V.pt_y(pb), V.pt_y(pa))
  +chz = F64.sub(V.pt_z(pb), V.pt_z(pa))
  +cmx = F64.sub(V.pt_x(p1), m3x)
  +cmy = F64.sub(V.pt_y(p1), m3y)
  +cmz = F64.sub(V.pt_z(p1), m3z)
  +crx = F64.sub(F64.mul(cmy, chz), F64.mul(cmz, chy))
  +cry = F64.sub(F64.mul(cmz, chx), F64.mul(cmx, chz))
  +crz = F64.sub(F64.mul(cmx, chy), F64.mul(cmy, chx))
  +cax = Bool.pick(F64, U64.is_eq(fa, 0u64), crx,
    Bool.pick(F64, U64.is_eq(fa, 1u64), cry, crz))
  +dqmx = F64.sub(V.pt_x(p1), m3x)
  +dqmy = F64.sub(V.pt_y(p1), m3y)
  +dqmz = F64.sub(V.pt_z(p1), m3z)
  +dqm = F64.sqrt(F64.add(F64.mul(dqmx, dqmx),
    F64.add(F64.mul(dqmy, dqmy), F64.mul(dqmz, dqmz))))
  +chl = k1d3(pa, pb)
  +tolx = k1tol(F64.add(F64.mul(dqm, chl), 1.0f64))
  +ln = F64.is_le(F64.abs(cax), tolx)
  +wpos = Bool.not(F64.is_lt(w1, 0.0f64))
  +r = F64.div(F64.add(F64.mul(h, h), F64.mul(s, s)), F64.add(s, s))
  +ident = F64.add(F64.mul(F64.div(h, r), F64.div(h, r)), F64.mul(w1, w1))
  +idok = F64.is_le(F64.abs(F64.sub(ident, 1.0f64)), 1.0e-14f64)
  +sok = F64.is_le(F64.mul(5.0e-10f64, F64.add(h, s)), s)
  +hpos = F64.is_lt(0.0f64, h)
  +major = F64.is_lt(h, s)
  +rw = I.iwiden(k1w(r), F64.mul(r, 1.0e-14f64))
  +y = I.idiv(k1w(h), rw)
  +adm = kasin_adm(y)
  +m0 = I.iscale(kasin(y), 2.0f64)
  +dth = Bool.pick(I.I, major, I.isub(I.iscale(I.pi_i(), 2.0f64), m0), m0)
  +sc3 = Bool.pick(F64, F64.is_lt(0.0f64, cax), 1.0f64, F64.neg(1.0f64))
  +sgn = Bool.pick(F64, major, F64.neg(sc3), sc3)
  +dths = Bool.pick(I.I, F64.is_lt(0.0f64, sgn), dth, I.ineg(dth))
  +sgeo = F64.neg(sc3)
  +chord3 = I.isqrt(I.iadd(I.isq(I.isub(k1w(V.pt_x(pb)), k1w(V.pt_x(pa)))),
    I.iadd(I.isq(I.isub(k1w(V.pt_y(pb)), k1w(V.pt_y(pa)))),
      I.isq(I.isub(k1w(V.pt_z(pb)), k1w(V.pt_z(pa)))))))
  +t2 = I.imul(I.ipt(sgeo), I.imul(I.imul(rw, k1w(F64.abs(w1))), chord3))
  +t3 = I.imul(I.isq(rw), dths)
  +t23 = I.iadd(t2, t3)
  +mx = k1w(m3x)
  +my = k1w(m3y)
  +mz = k1w(m3z)
  +ex = I.isub(k1w(V.pt_x(pb)), k1w(V.pt_x(pa)))
  +ey = I.isub(k1w(V.pt_y(pb)), k1w(V.pt_y(pa)))
  +ez = I.isub(k1w(V.pt_z(pb)), k1w(V.pt_z(pa)))
  +tx = I.iadd(I.isub(I.imul(my, ez), I.imul(mz, ey)),
    Bool.pick(I.I, U64.is_eq(fa, 0u64), t23, I.ipt(0.0f64)))
  +ty = I.iadd(I.isub(I.imul(mz, ex), I.imul(mx, ez)),
    Bool.pick(I.I, U64.is_eq(fa, 1u64), t23, I.ipt(0.0f64)))
  +tz = I.iadd(I.isub(I.imul(mx, ey), I.imul(my, ex)),
    Bool.pick(I.I, U64.is_eq(fa, 2u64), t23, I.ipt(0.0f64)))
  +dot = F64.add(F64.mul(F64.sub(V.v2_x(c2), midx), sdx),
    F64.mul(F64.sub(V.v2_y(c2), midy), sdy))
  +agree = Bool.pick(Bool, major, F64.is_lt(dot, 0.0f64), F64.is_lt(0.0f64, dot))
  +fin = Bool.and(T.is_finite(V.pt_x(p1)),
    Bool.and(T.is_finite(V.pt_y(p1)),
      Bool.and(T.is_finite(V.pt_z(p1)),
        Bool.and(T.is_finite(mmx), T.is_finite(mmy)))))
  +ok = Bool.and(w1ok, Bool.and(eok, Bool.and(dma, Bool.and(dmb,
    Bool.and(cxa, Bool.and(cxc, Bool.and(idok, Bool.and(sok, Bool.and(hpos,
      Bool.and(adm, Bool.and(agree, fin)))))))))))
  +wfin = T.is_finite(w1)
  +lnok = Bool.and(w1ok, Bool.and(eok, Bool.and(cxa, Bool.and(cxc,
    Bool.and(fin, Bool.and(hpos, wfin))))))
  +sb = F64.div(F64.add(tolx, F64.mul(k1tol(axp), F64.mul(chl, 4.0f64))), F64.add(chl, 1.0e-300f64))
  +lw = F64.mul(2.0f64, F64.mul(h, sb))
  Bool.pick(K1N, ln, Bool.pick(K1N, Bool.and(wpos, lnok), k1line_nw_w(pa, pb, lw),
    K1N{I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(0.0f64), False{}}), K1N{tx, ty, tz, ok})

def k1nw_go(cs: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, +fa: U64, +fc: F64, +sc: F64, +sok: Bool, +nx: I.I, +ny: I.I,
    +nz: I.I, +ok: Bool) -> K1N:
  match cs:
    case []: K1N{nx, ny, nz, ok}
    case +h <> +t:
      +ce = KU.nth_ce0(ces, Ty.hc_idx(h))
      +ed = KU.nth_ed0(es, Ty.he_idx(Ty.ce_edge(ce)))
      +f = Ty.ce_fwd(ce)
      +tag = gv_tag(Ty.ekind_curve(Ty.ed_kind(ed)))
      +ia = Bool.pick(Nat, f, Ty.hv_idx(Ty.ed_v0(ed)), Ty.hv_idx(Ty.ed_v1(ed)))
      +ib = Bool.pick(Nat, f, Ty.hv_idx(Ty.ed_v1(ed)), Ty.hv_idx(Ty.ed_v0(ed)))
      +pa = Ty.vx_p(KU.nth_vx0(vs, ia))
      +pb = Ty.vx_p(KU.nth_vx0(vs, ib))
      +cc = gv_cc_of(Ty.ekind_curve(Ty.ed_kind(ed)))
      +rq = gv_rq_of(Ty.ekind_curve(Ty.ed_kind(ed)))
      +closed = Bool.and(F64.is_eq(V.pt_x(pa), V.pt_x(pb)),
        Bool.and(F64.is_eq(V.pt_y(pa), V.pt_y(pb)), F64.is_eq(V.pt_z(pa), V.pt_z(pb))))
      +nw = Bool.pick(K1N, U64.is_eq(tag, 0u64), k1line_nw(pa, pb),
        Bool.pick(K1N, U64.is_eq(tag, 3u64),
          Bool.pick(K1N, closed,
            k1arc_closed(G.cc_c(cc), G.cc_u(cc), G.cc_v(cc), G.cc_r(cc), fa, fc, sc, sok),
            k1arc_open(pa, pb, G.cc_c(cc), G.cc_u(cc), G.cc_v(cc), G.cc_r(cc), Ty.ce_trim(ce),
              fa)),
          Bool.pick(K1N, U64.is_eq(tag, 2u64),
            k1rq_open(pa, pb, rq, fa, f),
            K1N{I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(0.0f64), False{}})))
      k1nw_go(t, ces, es, vs, fa, fc, sc, sok, I.iadd(nx, k1n_x(nw)), I.iadd(ny, k1n_y(nw)),
        I.iadd(nz, k1n_z(nw)), Bool.and(ok, k1n_ok(nw)))


def k1lp_p0(cs: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>) -> V.Point:
  match cs:
    case []: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case +h <> +t:
      +ce = KU.nth_ce0(ces, Ty.hc_idx(h))
      +ed = KU.nth_ed0(es, Ty.he_idx(Ty.ce_edge(ce)))
      Ty.vx_p(KU.nth_vx0(vs, Bool.pick(Nat, Ty.ce_fwd(ce), Ty.hv_idx(Ty.ed_v0(ed)), Ty.hv_idx(Ty.ed_v1(ed)))))

type K1F is Data:
  K1F{ nx: I.I, ny: I.I, nz: I.I, vol: I.I, ok: Bool }

def k1f_nx(+n: K1F) -> I.I:
  K1F{nx, ny, nz, vol, ok} = n
  nx

def k1f_ny(+n: K1F) -> I.I:
  K1F{nx, ny, nz, vol, ok} = n
  ny

def k1f_nz(+n: K1F) -> I.I:
  K1F{nx, ny, nz, vol, ok} = n
  nz

def k1f_vol(+n: K1F) -> I.I:
  K1F{nx, ny, nz, vol, ok} = n
  vol

def k1f_ok(+n: K1F) -> Bool:
  K1F{nx, ny, nz, vol, ok} = n
  ok

def k1face_go(ls: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, +fa: U64, +fc: F64, +so: F64, +nx: I.I,
    +ny: I.I, +nz: I.I, +vol: I.I, +ok: Bool) -> K1F:
  match ls:
    case []: K1F{nx, ny, nz, vol, ok}
    case +h <> +t:
      +lp = KU.nth_lp0(lps, Ty.hlp_idx(h))
      +cs = Ty.lp_ces(lp)
      +kt = Ty.lkind_tag(Ty.lp_kind(lp))
      +sok = Bool.or(U64.is_eq(kt, 0u64), U64.is_eq(kt, 1u64))
      +sk = Bool.pick(F64, U64.is_eq(kt, 0u64), 1.0f64, F64.neg(1.0f64))
      +nw = k1nw_go(cs, ces, es, vs, fa, fc, F64.mul(sk, so), sok, I.ipt(0.0f64),
        I.ipt(0.0f64), I.ipt(0.0f64), True{})
      +p0 = k1lp_p0(cs, ces, es, vs)
      +vd = I.iadd(I.iadd(I.imul(k1n_x(nw), k1w(V.pt_x(p0))), I.imul(k1n_y(nw), k1w(V.pt_y(p0)))),
        I.imul(k1n_z(nw), k1w(V.pt_z(p0))))
      k1face_go(t, lps, ces, es, vs, fa, fc, so, I.iadd(nx, k1n_x(nw)), I.iadd(ny, k1n_y(nw)),
        I.iadd(nz, k1n_z(nw)), I.iadd(vol, I.idiv(vd, I.ipt(6.0f64))), Bool.and(ok, k1n_ok(nw)))

type K1R is Data:
  K1R{ ma: F64, lo: F64, hi: F64 }

def k1r_ma(+n: K1R) -> F64:
  K1R{ma, lo, hi} = n
  ma

def k1r_lo(+n: K1R) -> F64:
  K1R{ma, lo, hi} = n
  lo

def k1r_hi(+n: K1R) -> F64:
  K1R{ma, lo, hi} = n
  hi

def k1range_go(cs: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, +fa: U64, +ma: F64, +lo: F64, +hi: F64) -> K1R:
  match cs:
    case []: K1R{ma, lo, hi}
    case +h <> +t:
      +ce = KU.nth_ce0(ces, Ty.hc_idx(h))
      +ed = KU.nth_ed0(es, Ty.he_idx(Ty.ce_edge(ce)))
      +pa = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v0(ed))))
      +pb = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v1(ed))))
      +za = k1axc(pa, fa)
      +zb = k1axc(pb, fa)
      +m1 = F64.max(F64.abs(V.pt_x(pa)), F64.max(F64.abs(V.pt_y(pa)), F64.abs(V.pt_z(pa))))
      +m2 = F64.max(F64.abs(V.pt_x(pb)), F64.max(F64.abs(V.pt_y(pb)), F64.abs(V.pt_z(pb))))
      k1range_go(t, ces, es, vs, fa, F64.max(ma, F64.max(m1, m2)), F64.min(lo, F64.min(za, zb)),
        F64.max(hi, F64.max(za, zb)))

def k1range_fl(ls: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, +fa: U64, +ma: F64, +lo: F64,
    +hi: F64) -> K1R:
  match ls:
    case []: K1R{ma, lo, hi}
    case +h <> +t:
      +r = k1range_go(Ty.lp_ces(KU.nth_lp0(lps, Ty.hlp_idx(h))), ces, es, vs, fa, ma, lo, hi)
      k1range_fl(t, lps, ces, es, vs, fa, k1r_ma(r), k1r_lo(r), k1r_hi(r))

def k1range_face(ls: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, +fa: U64) -> K1R:
  k1range_fl(ls, lps, ces, es, vs, fa, 0.0f64, 1.0e300f64, F64.neg(1.0e300f64))

type K1D is Data:
  K1D{ dth: I.I, cl: Bool, ok: Bool, fx: I.I }

def k1d_dth(+n: K1D) -> I.I:
  K1D{dth, cl, ok, fx} = n
  dth

def k1d_cl(+n: K1D) -> Bool:
  K1D{dth, cl, ok, fx} = n
  cl

def k1d_ok(+n: K1D) -> Bool:
  K1D{dth, cl, ok, fx} = n
  ok

def k1d_fx(+n: K1D) -> I.I:
  K1D{dth, cl, ok, fx} = n
  fx

def k1wrim(+pa: V.Point, +pb: V.Point, +c3: V.Point, +ccu: V.Dir, +ccv: V.Dir, +re: F64,
    +tm: G.GVal, +fa: U64, +wr: F64, +lo: F64, +hi: F64, +so: F64) -> K1D:
  +closed = Bool.and(F64.is_eq(V.pt_x(pa), V.pt_x(pb)),
    Bool.and(F64.is_eq(V.pt_y(pa), V.pt_y(pb)), F64.is_eq(V.pt_z(pa), V.pt_z(pb))))
  +ca = KU.crx(ccu, ccv)
  +dax = Bool.pick(F64, U64.is_eq(fa, 0u64), V.dr_x(ca),
    Bool.pick(F64, U64.is_eq(fa, 1u64), V.dr_y(ca), V.dr_z(ca)))
  +par = F64.is_le(F64.sub(1.0f64, 1.0e-9f64), F64.abs(dax))
  +req = F64.is_le(F64.abs(F64.sub(re, wr)), k1tol(wr))
  +reg = F64.is_lt(0.0f64, re)
  +onc = F64.is_le(F64.abs(F64.sub(k1axc(c3, fa), k1axc(pa, fa))), k1tol(k1axc(pa, fa)))
  +shz = F64.is_le(F64.abs(F64.sub(k1axc(pa, fa), k1axc(pb, fa))), k1tol(k1axc(pa, fa)))
  +cnz = F64.is_le(F64.abs(F64.sub(k1axc(c3, fa), k1axc(pa, fa))), k1tol(k1axc(pa, fa)))
  +dx = I.isub(k1w(V.pt_x(pa)), k1w(V.pt_x(pb)))
  +dy = I.isub(k1w(V.pt_y(pa)), k1w(V.pt_y(pb)))
  +dz = I.isub(k1w(V.pt_z(pa)), k1w(V.pt_z(pb)))
  +ch = I.isqrt(I.iadd(I.isq(dx), I.iadd(I.isq(dy), I.isq(dz))))
  +y = I.idiv(ch, I.iscale(k1w(re), 2.0f64))
  +adm = kasin_adm(y)
  +tok = k1trim_ok(tm)
  +a2 = k1drop(pa, fa)
  +b2 = k1drop(pb, fa)
  +c2 = k1drop(c3, fa)
  +m = k1trim_mid(tm)
  +ona2 = k1onc(a2, c2, re)
  +onb2 = k1onc(b2, c2, re)
  +onm = k1onc(m, c2, re)
  +dma = Bool.not(Bool.and(F64.is_eq(V.v2_x(m), V.v2_x(a2)), F64.is_eq(V.v2_y(m), V.v2_y(a2))))
  +dmb = Bool.not(Bool.and(F64.is_eq(V.v2_x(m), V.v2_x(b2)), F64.is_eq(V.v2_y(m), V.v2_y(b2))))
  +mid2x = F64.mul(0.5f64, F64.add(V.v2_x(a2), V.v2_x(b2)))
  +mid2y = F64.mul(0.5f64, F64.add(V.v2_y(a2), V.v2_y(b2)))
  +h2 = F64.mul(0.5f64, k1d2(a2, b2))
  +s2dx = F64.sub(V.v2_x(m), mid2x)
  +s2dy = F64.sub(V.v2_y(m), mid2y)
  +s2 = F64.sqrt(F64.add(F64.mul(s2dx, s2dx), F64.mul(s2dy, s2dy)))
  +sok2 = F64.is_le(F64.mul(5.0e-10f64, F64.add(h2, s2)), s2)
  +ex = F64.sub(V.v2_x(b2), V.v2_x(a2))
  +ey = F64.sub(V.v2_y(b2), V.v2_y(a2))
  +sm = F64.sub(F64.mul(ex, F64.sub(V.v2_y(m), mid2y)),
    F64.mul(ey, F64.sub(V.v2_x(m), mid2x)))
  +smc = F64.sub(F64.mul(ex, F64.sub(V.v2_y(c2), mid2y)),
    F64.mul(ey, F64.sub(V.v2_x(c2), mid2x)))
  +major = Bool.and(sok2, F64.is_lt(0.0f64, F64.mul(sm, smc)))
  +m0 = I.iscale(kasin(y), 2.0f64)
  +dtho = Bool.pick(I.I, major, I.isub(I.iscale(I.pi_i(), 2.0f64), m0), m0)
  +mid = F64.mul(0.5f64, F64.add(lo, hi))
  +ssw = Bool.pick(F64, F64.is_lt(mid, k1axc(pa, fa)), F64.neg(so), so)
  +cu = Bool.pick(F64, U64.is_eq(fa, 0u64), V.pt_y(c3),
    Bool.pick(F64, U64.is_eq(fa, 1u64), V.pt_z(c3), V.pt_x(c3)))
  +cv = Bool.pick(F64, U64.is_eq(fa, 0u64), V.pt_z(c3),
    Bool.pick(F64, U64.is_eq(fa, 1u64), V.pt_x(c3), V.pt_y(c3)))
  +pu0 = Bool.pick(F64, U64.is_eq(fa, 0u64), V.pt_y(pa),
    Bool.pick(F64, U64.is_eq(fa, 1u64), V.pt_z(pa), V.pt_x(pa)))
  +pv0 = Bool.pick(F64, U64.is_eq(fa, 0u64), V.pt_z(pa),
    Bool.pick(F64, U64.is_eq(fa, 1u64), V.pt_x(pa), V.pt_y(pa)))
  +pu1 = Bool.pick(F64, U64.is_eq(fa, 0u64), V.pt_y(pb),
    Bool.pick(F64, U64.is_eq(fa, 1u64), V.pt_z(pb), V.pt_x(pb)))
  +pv1 = Bool.pick(F64, U64.is_eq(fa, 0u64), V.pt_z(pb),
    Bool.pick(F64, U64.is_eq(fa, 1u64), V.pt_x(pb), V.pt_y(pb)))
  +rw = k1w(re)
  +ds = I.isub(I.idiv(I.isub(k1w(pv1), k1w(cv)), rw), I.idiv(I.isub(k1w(pv0), k1w(cv)), rw))
  +dc = I.isub(I.idiv(I.isub(k1w(pu1), k1w(cu)), rw), I.idiv(I.isub(k1w(pu0), k1w(cu)), rw))
  +dsr = Bool.pick(I.I, F64.is_lt(0.0f64, ssw), ds, I.ineg(ds))
  +dcr = Bool.pick(I.I, F64.is_lt(0.0f64, ssw), dc, I.ineg(dc))
  +fx = I.isub(I.imul(k1w(cu), dsr), I.imul(k1w(cv), dcr))
  Bool.pick(K1D, closed,
    K1D{I.iscale(I.pi_i(), 2.0f64), True{}, Bool.and(par, Bool.and(req, onc)), I.ipt(0.0f64)},
    K1D{dtho, False{},
      Bool.and(par, Bool.and(req, Bool.and(reg, Bool.and(shz, Bool.and(cnz, Bool.and(adm,
        Bool.and(tok, Bool.and(ona2, Bool.and(onb2, Bool.and(onm, Bool.and(dma, dmb))))))))))),
      fx})

def k1onxy(+mx: F64, +my: F64, +cx: F64, +cy: F64, +r: F64) -> Bool:
  +dx = F64.sub(mx, cx)
  +dy = F64.sub(my, cy)
  +d = F64.sqrt(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)))
  F64.is_le(F64.abs(F64.sub(d, r)), k1tol(r))

def k1oncc(+p: V.Vec2, +cx: F64, +cy: F64, +r: F64) -> Bool:
  +dx = F64.sub(V.v2_x(p), cx)
  +dy = F64.sub(V.v2_y(p), cy)
  +d = F64.sqrt(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)))
  F64.is_le(F64.abs(F64.sub(d, r)), k1tol(r))

def k1rqwrim(+pa: V.Point, +pb: V.Point, +rq: G.RQBez, +f: Bool, +fa: U64,
    +wr: F64, +lo: F64, +hi: F64, +so: F64) -> K1D:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = rq
  +w1ok = Bool.and(F64.is_eq(w0, 1.0f64), F64.is_eq(w2, 1.0f64))
  +eok = Bool.pick(Bool, f, Bool.and(k1pteq(p0, pa), k1pteq(p2, pb)),
    Bool.and(k1pteq(p0, pb), k1pteq(p2, pa)))
  +a = k1drop(pa, fa)
  +b = k1drop(pb, fa)
  +c2 = k1drop(p1, fa)
  +den = F64.add(2.0f64, F64.mul(2.0f64, w1))
  +mmx = F64.div(F64.add(V.v2_x(a), F64.add(F64.mul(F64.mul(2.0f64, w1), V.v2_x(c2)), V.v2_x(b))), den)
  +mmy = F64.div(F64.add(V.v2_y(a), F64.add(F64.mul(F64.mul(2.0f64, w1), V.v2_y(c2)), V.v2_y(b))), den)
  +midx = F64.mul(0.5f64, F64.add(V.v2_x(a), V.v2_x(b)))
  +midy = F64.mul(0.5f64, F64.add(V.v2_y(a), V.v2_y(b)))
  +h = F64.mul(0.5f64, k1d2(a, b))
  +sdx = F64.sub(mmx, midx)
  +sdy = F64.sub(mmy, midy)
  +s = F64.sqrt(F64.add(F64.mul(sdx, sdx), F64.mul(sdy, sdy)))
  +dma = Bool.not(Bool.and(F64.is_eq(mmx, V.v2_x(a)), F64.is_eq(mmy, V.v2_y(a))))
  +dmb = Bool.not(Bool.and(F64.is_eq(mmx, V.v2_x(b)), F64.is_eq(mmy, V.v2_y(b))))
  +axp = k1axc(pa, fa)
  +axb = F64.is_le(F64.abs(F64.sub(k1axc(pb, fa), axp)), k1tol(axp))
  +axq = F64.is_le(F64.abs(F64.sub(k1axc(p1, fa), axp)), k1tol(axp))
  +r = F64.div(F64.add(F64.mul(h, h), F64.mul(s, s)), F64.add(s, s))
  +ident = F64.add(F64.mul(F64.div(h, r), F64.div(h, r)), F64.mul(w1, w1))
  +idok = F64.is_le(F64.abs(F64.sub(ident, 1.0f64)), 1.0e-14f64)
  +sok = F64.is_le(F64.mul(5.0e-10f64, F64.add(h, s)), s)
  +hpos = F64.is_lt(0.0f64, h)
  +major = F64.is_lt(h, s)
  +rw = I.iwiden(k1w(r), F64.mul(r, 1.0e-14f64))
  +y = I.idiv(k1w(h), rw)
  +adm = kasin_adm(y)
  +m0 = I.iscale(kasin(y), 2.0f64)
  +dth = Bool.pick(I.I, major, I.isub(I.iscale(I.pi_i(), 2.0f64), m0), m0)
  +req = F64.is_le(F64.abs(F64.sub(r, wr)), k1tol(wr))
  +reg = F64.is_lt(0.0f64, r)
  +nx = F64.div(sdx, s)
  +ny = F64.div(sdy, s)
  +t = F64.sub(r, s)
  +ccx = Bool.pick(F64, major, F64.add(midx, F64.mul(t, nx)), F64.sub(midx, F64.mul(t, nx)))
  +ccy = Bool.pick(F64, major, F64.add(midy, F64.mul(t, ny)), F64.sub(midy, F64.mul(t, ny)))
  +ona = k1oncc(a, ccx, ccy, r)
  +onb = k1oncc(b, ccx, ccy, r)
  +onm = k1onxy(mmx, mmy, ccx, ccy, r)
  +swap = U64.is_eq(fa, 1u64)
  +cu = Bool.pick(F64, swap, ccy, ccx)
  +cv = Bool.pick(F64, swap, ccx, ccy)
  +midax = F64.mul(0.5f64, F64.add(lo, hi))
  +ssw = Bool.pick(F64, F64.is_lt(midax, axp), F64.neg(so), so)
  +pu0 = Bool.pick(F64, U64.is_eq(fa, 0u64), V.pt_y(pa),
    Bool.pick(F64, U64.is_eq(fa, 1u64), V.pt_z(pa), V.pt_x(pa)))
  +pv0 = Bool.pick(F64, U64.is_eq(fa, 0u64), V.pt_z(pa),
    Bool.pick(F64, U64.is_eq(fa, 1u64), V.pt_x(pa), V.pt_y(pa)))
  +pu1 = Bool.pick(F64, U64.is_eq(fa, 0u64), V.pt_y(pb),
    Bool.pick(F64, U64.is_eq(fa, 1u64), V.pt_z(pb), V.pt_x(pb)))
  +pv1 = Bool.pick(F64, U64.is_eq(fa, 0u64), V.pt_z(pb),
    Bool.pick(F64, U64.is_eq(fa, 1u64), V.pt_x(pb), V.pt_y(pb)))
  +ds = I.isub(I.idiv(I.isub(k1w(pv1), k1w(cv)), rw), I.idiv(I.isub(k1w(pv0), k1w(cv)), rw))
  +dc = I.isub(I.idiv(I.isub(k1w(pu1), k1w(cu)), rw), I.idiv(I.isub(k1w(pu0), k1w(cu)), rw))
  +dsr = Bool.pick(I.I, F64.is_lt(0.0f64, ssw), ds, I.ineg(ds))
  +dcr = Bool.pick(I.I, F64.is_lt(0.0f64, ssw), dc, I.ineg(dc))
  +fx = I.isub(I.imul(k1w(cu), dsr), I.imul(k1w(cv), dcr))
  +dot = F64.add(F64.mul(F64.sub(V.v2_x(c2), midx), sdx),
    F64.mul(F64.sub(V.v2_y(c2), midy), sdy))
  +agree = Bool.pick(Bool, major, F64.is_lt(dot, 0.0f64), F64.is_lt(0.0f64, dot))
  +fin = Bool.and(T.is_finite(V.pt_x(p1)),
    Bool.and(T.is_finite(V.pt_y(p1)),
      Bool.and(T.is_finite(V.pt_z(p1)),
        Bool.and(T.is_finite(mmx), T.is_finite(mmy)))))
  +ok = Bool.and(w1ok, Bool.and(eok, Bool.and(dma, Bool.and(dmb,
    Bool.and(axb, Bool.and(axq, Bool.and(idok, Bool.and(sok, Bool.and(hpos,
      Bool.and(adm, Bool.and(req, Bool.and(reg, Bool.and(ona, Bool.and(onb,
        Bool.and(onm, Bool.and(agree, fin))))))))))))))))
  K1D{dth, False{}, ok, fx}

def k1wall_axok(+pa: V.Point, +pb: V.Point, +fa: U64) -> Bool:
  Bool.pick(Bool, U64.is_eq(fa, 0u64),
    Bool.and(F64.is_le(F64.abs(F64.sub(V.pt_y(pa), V.pt_y(pb))), k1tol(V.pt_y(pa))),
      F64.is_le(F64.abs(F64.sub(V.pt_z(pa), V.pt_z(pb))), k1tol(V.pt_z(pa)))),
    Bool.pick(Bool, U64.is_eq(fa, 1u64),
      Bool.and(F64.is_le(F64.abs(F64.sub(V.pt_x(pa), V.pt_x(pb))), k1tol(V.pt_x(pa))),
        F64.is_le(F64.abs(F64.sub(V.pt_z(pa), V.pt_z(pb))), k1tol(V.pt_z(pa)))),
      Bool.and(F64.is_le(F64.abs(F64.sub(V.pt_x(pa), V.pt_x(pb))), k1tol(V.pt_x(pa))),
        F64.is_le(F64.abs(F64.sub(V.pt_y(pa), V.pt_y(pb))), k1tol(V.pt_y(pa))))))

type K1W is Data:
  K1W{ dth: I.I, narc: Nat, nln: Nat, ncl: Nat, nce: Nat, ok: Bool, fx: I.I, sh: I.I }

def k1w_dth(+n: K1W) -> I.I:
  K1W{dth, narc, nln, ncl, nce, ok, fx, sh} = n
  dth

def k1w_narc(+n: K1W) -> Nat:
  K1W{dth, narc, nln, ncl, nce, ok, fx, sh} = n
  narc

def k1w_nln(+n: K1W) -> Nat:
  K1W{dth, narc, nln, ncl, nce, ok, fx, sh} = n
  nln

def k1w_ncl(+n: K1W) -> Nat:
  K1W{dth, narc, nln, ncl, nce, ok, fx, sh} = n
  ncl

def k1w_nce(+n: K1W) -> Nat:
  K1W{dth, narc, nln, ncl, nce, ok, fx, sh} = n
  nce

def k1w_ok(+n: K1W) -> Bool:
  K1W{dth, narc, nln, ncl, nce, ok, fx, sh} = n
  ok

def k1w_fx(+n: K1W) -> I.I:
  K1W{dth, narc, nln, ncl, nce, ok, fx, sh} = n
  fx

def k1w_sh(+n: K1W) -> I.I:
  K1W{dth, narc, nln, ncl, nce, ok, fx, sh} = n
  sh

def wtheta(+u: F64, +v: F64) -> I.I:
  +a0 = I.atan2q(k1w(F64.abs(v)), k1w(F64.abs(u)))
  +nu = F64.is_lt(u, 0.0f64)
  +nv = F64.is_lt(v, 0.0f64)
  Bool.pick(I.I, nu,
    Bool.pick(I.I, nv, I.isub(a0, I.pi_i()), I.isub(I.pi_i(), a0)),
    Bool.pick(I.I, nv, I.ineg(a0), a0))

def wdth(+tha: I.I, +thb: I.I) -> I.I:
  +d = I.isub(thb, tha)
  +k = Bool.pick(F64, F64.is_lt(I.i_hi(d), F64.neg(3.141592653589793f64)), 1.0f64,
    Bool.pick(F64, F64.is_lt(3.141592653589793f64, I.i_lo(d)), F64.neg(1.0f64), 0.0f64))
  I.iadd(d, I.iscale(I.pi_i(), k))

def wsh_ok(+tha: I.I, +thb: I.I) -> Bool:
  +w = wdth(tha, thb)
  F64.is_le(F64.abs(F64.mul(0.5f64, F64.add(I.i_lo(w), I.i_hi(w)))), 1.0f64)

def wsh(+tha: I.I, +thb: I.I, +za: F64, +zb: F64) -> I.I:
  +w = wdth(tha, thb)
  I.imul(I.iadd(tha, I.iscale(w, 0.5f64)), I.isub(k1w(zb), k1w(za)))

def lk_is_inner(+k: Ty.LoopKind) -> Bool:
  match k:
    case Ty.LK_inner{}: True{}
    case _: False{}

def k1wloop_go(cs: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, +fa: U64, +wr: F64, +lo: F64, +hi: F64, +so: F64, +dth: I.I,
    +narc: Nat, +nln: Nat, +ncl: Nat, +nce: Nat, +ok: Bool, +fx: I.I, +cu: F64, +cv: F64,
    +sh: I.I, +ishole: Bool) -> K1W:
  match cs:
    case []: K1W{dth, narc, nln, ncl, nce, ok, fx, sh}
    case +h <> +t:
      +ce = KU.nth_ce0(ces, Ty.hc_idx(h))
      +ed = KU.nth_ed0(es, Ty.he_idx(Ty.ce_edge(ce)))
      +f = Ty.ce_fwd(ce)
      +tag = gv_tag(Ty.ekind_curve(Ty.ed_kind(ed)))
      +ia = Bool.pick(Nat, f, Ty.hv_idx(Ty.ed_v0(ed)), Ty.hv_idx(Ty.ed_v1(ed)))
      +ib = Bool.pick(Nat, f, Ty.hv_idx(Ty.ed_v1(ed)), Ty.hv_idx(Ty.ed_v0(ed)))
      +pa = Ty.vx_p(KU.nth_vx0(vs, ia))
      +pb = Ty.vx_p(KU.nth_vx0(vs, ib))
      +cc = gv_cc_of(Ty.ekind_curve(Ty.ed_kind(ed)))
      +rq = gv_rq_of(Ty.ekind_curve(Ty.ed_kind(ed)))
      +tm = Ty.ce_trim(ce)
      +is0 = U64.is_eq(tag, 0u64)
      +is2 = U64.is_eq(tag, 2u64)
      +is3 = U64.is_eq(tag, 3u64)
      +isa = Bool.or(is2, is3)
      +kd = Bool.pick(K1D, is2, k1rqwrim(pa, pb, rq, f, fa, wr, lo, hi, so),
        k1wrim(pa, pb, G.cc_c(cc), G.cc_u(cc), G.cc_v(cc), G.cc_r(cc), tm, fa, wr, lo, hi, so))
      +axok = k1wall_axok(pa, pb, fa)
      +tha = wtheta(F64.sub(pcomp(pa, run0_ax(fa)), cu), F64.sub(pcomp(pa, run1_ax(fa)), cv))
      +thb = wtheta(F64.sub(pcomp(pb, run0_ax(fa)), cu), F64.sub(pcomp(pb, run1_ax(fa)), cv))
      +chok = wsh_ok(tha, thb)
      +nsh = I.iadd(sh, wsh(tha, thb, k1axc(pa, fa), k1axc(pb, fa)))
      +lnok = Bool.pick(Bool, ishole, chok, axok)
      +first = Nat.is_eq(narc, 0n)
      +ndth = Bool.pick(I.I, first, k1d_dth(kd), I.ihull(dth, k1d_dth(kd)))
      +nfx = Bool.pick(I.I, first, k1d_fx(kd), I.ihull(fx, k1d_fx(kd)))
      k1wloop_go(t, ces, es, vs, fa, wr, lo, hi, so, Bool.pick(I.I, isa, ndth, dth),
        Bool.pick(Nat, isa, Nat.add(narc, 1n), narc),
        Bool.pick(Nat, is0, Nat.add(nln, 1n), nln),
        Bool.pick(Nat, Bool.and(is3, k1d_cl(kd)), Nat.add(ncl, 1n), ncl), Nat.add(nce, 1n),
        Bool.and(ok, Bool.pick(Bool, is0, lnok, Bool.pick(Bool, isa, k1d_ok(kd), False{}))),
        Bool.pick(I.I, isa, nfx, fx), cu, cv, Bool.pick(I.I, is0, nsh, sh), ishole)

def k1wloop(+h: Ty.HLoop, +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, +fa: U64, +wr: F64, +lo: F64,
    +hi: F64, +so: F64, +cu: F64, +cv: F64) -> K1W:
  +ishole = lk_is_inner(Ty.lp_kind(KU.nth_lp0(lps, Ty.hlp_idx(h))))
  k1wloop_go(Ty.lp_ces(KU.nth_lp0(lps, Ty.hlp_idx(h))), ces, es, vs, fa, wr, lo, hi, so,
    I.ipt(0.0f64), 0n, 0n, 0n, 0n, True{}, I.ipt(0.0f64), cu, cv, I.ipt(0.0f64), ishole)

def k1wall_fin(+shape: Bool, +wok: Bool, +wr: F64, +dth: I.I, +fx: I.I, +lo: F64, +hi: F64,
    +so: F64) -> K1M:
  +h = I.isub(k1w(hi), k1w(lo))
  +ar = k1iabs(I.imul(I.imul(k1w(wr), dth), h))
  +vol = I.imul(I.ipt(so),
    I.idiv(I.imul(I.imul(k1w(wr), h), I.iadd(I.imul(k1w(wr), dth), fx)), I.ipt(3.0f64)))
  K1M{vol, ar, Bool.and(shape, wok)}

type K1H is Data:
  K1H{ sh: I.I, ok: Bool }

def k1h_sh(+n: K1H) -> I.I:
  K1H{sh, ok} = n
  sh

def k1h_ok(+n: K1H) -> Bool:
  K1H{sh, ok} = n
  ok

def k1wall_holes_go(ls: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, +fa: U64, +wr: F64, +lo: F64,
    +hi: F64, +so: F64, +cu: F64, +cv: F64, +sh: I.I, +ok: Bool) -> K1H:
  match ls:
    case []: K1H{sh, ok}
    case +h <> +t:
      +w = k1wloop(h, lps, ces, es, vs, fa, wr, lo, hi, so, cu, cv)
      +inner = lk_is_inner(Ty.lp_kind(KU.nth_lp0(lps, Ty.hlp_idx(h))))
      +pure = Bool.and(Nat.is_eq(k1w_narc(w), 0n),
        Bool.not(Nat.is_eq(k1w_nln(w), 0n)))
      k1wall_holes_go(t, lps, ces, es, vs, fa, wr, lo, hi, so, cu, cv,
        I.iadd(sh, k1w_sh(w)), Bool.and(ok, Bool.and(inner, Bool.and(pure, k1w_ok(w)))))

def k1wall_face(ls: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, +fa: U64, +wr: F64, +lo: F64,
    +hi: F64, +so: F64, +cu: F64, +cv: F64) -> K1M:
  match ls:
    case []: K1M{I.ipt(0.0f64), I.ipt(0.0f64), False{}}
    case +h1 <> t:
      match t:
        case []:
          +w = k1wloop(h1, lps, ces, es, vs, fa, wr, lo, hi, so, cu, cv)
          +single = Bool.and(Nat.is_eq(k1w_ncl(w), 1n), Nat.is_eq(k1w_nce(w), 1n))
          +open = Bool.and(Nat.is_eq(k1w_ncl(w), 0n), Bool.not(Nat.is_eq(k1w_narc(w), 0n)))
          k1wall_fin(Bool.or(single, open), k1w_ok(w), wr, k1w_dth(w), k1w_fx(w), lo, hi, so)
        case +h2 <> u:
          match u:
            case []:
              +w1 = k1wloop(h1, lps, ces, es, vs, fa, wr, lo, hi, so, cu, cv)
              +w2 = k1wloop(h2, lps, ces, es, vs, fa, wr, lo, hi, so, cu, cv)
              +s1 = Bool.and(Nat.is_eq(k1w_ncl(w1), 1n), Nat.is_eq(k1w_nce(w1), 1n))
              +s2 = Bool.and(Nat.is_eq(k1w_ncl(w2), 1n), Nat.is_eq(k1w_nce(w2), 1n))
              k1wall_fin(Bool.and(s1, s2), Bool.and(k1w_ok(w1), k1w_ok(w2)), wr,
                I.ihull(k1w_dth(w1), k1w_dth(w2)), I.ihull(k1w_fx(w1), k1w_fx(w2)), lo, hi, so)
            case +_ <> +_:
              +w1 = k1wloop(h1, lps, ces, es, vs, fa, wr, lo, hi, so, cu, cv)
              +w2 = k1wloop(h2, lps, ces, es, vs, fa, wr, lo, hi, so, cu, cv)
              +s1 = Bool.and(Nat.is_eq(k1w_ncl(w1), 1n), Nat.is_eq(k1w_nce(w1), 1n))
              +s2 = Bool.and(Nat.is_eq(k1w_ncl(w2), 1n), Nat.is_eq(k1w_nce(w2), 1n))
              +base = k1wall_fin(Bool.and(s1, s2), Bool.and(k1w_ok(w1), k1w_ok(w2)), wr,
                I.ihull(k1w_dth(w1), k1w_dth(w2)), I.ihull(k1w_fx(w1), k1w_fx(w2)), lo, hi, so)
              +hh = k1wall_holes_go(u, lps, ces, es, vs, fa, wr, lo, hi, so, cu, cv,
                I.ipt(0.0f64), True{})
              +ha = k1iabs(k1h_sh(hh))
              +hvol = I.imul(I.ipt(so),
                I.idiv(I.imul(I.imul(k1w(wr), k1w(wr)), ha), I.ipt(3.0f64)))
              +har = I.imul(k1w(wr), ha)
              K1M{I.isub(k1m_vol(base), hvol), I.isub(k1m_ar(base), har),
                Bool.and(k1m_ok(base), k1h_ok(hh))}

def k1fa_plane(+h: Ty.Face, +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>) -> K1M:
  +sk = KU.surfkind(Ty.fa_surf(h))
  +ax = U64.sub(sk, 1u64)
  +rg = k1range_face(Ty.fa_loops(h), lps, ces, es, vs, ax)
  +scok = F64.is_le(k1r_ma(rg), 1024.0f64)
  +has = Bool.not(Nat.is_eq(List.length(&2, Ty.HLoop, Ty.fa_loops(h)), 0n))
  +w = gv_pl_of(Ty.fa_surf(h))
  +fc = KU.plancon(w, ax)
  +sn = KU.crx(G.pl_u(w), G.pl_v(w))
  +dot = Bool.pick(F64, U64.is_eq(ax, 0u64), V.dr_x(sn),
    Bool.pick(F64, U64.is_eq(ax, 1u64), V.dr_y(sn), V.dr_z(sn)))
  +ss = Bool.pick(F64, F64.is_lt(dot, 0.0f64), F64.neg(1.0f64), 1.0f64)
  +so = Bool.pick(F64, Ty.fa_same(h), ss, F64.neg(ss))
  +kf = k1face_go(Ty.fa_loops(h), lps, ces, es, vs, ax, fc, so, I.ipt(0.0f64), I.ipt(0.0f64),
    I.ipt(0.0f64), I.ipt(0.0f64), True{})
  +sd = Bool.pick(I.I, U64.is_eq(ax, 0u64), k1f_nx(kf),
    Bool.pick(I.I, U64.is_eq(ax, 1u64), k1f_ny(kf), k1f_nz(kf)))
  K1M{k1f_vol(kf), I.idiv(k1iabs(sd), I.ipt(2.0f64)), Bool.and(scok, Bool.and(has, k1f_ok(kf)))}

def k1fa_wall(+h: Ty.Face, +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>) -> K1M:
  +sk = KU.surfkind(Ty.fa_surf(h))
  +ax = U64.sub(sk, 4u64)
  +rg = k1range_face(Ty.fa_loops(h), lps, ces, es, vs, ax)
  +scok = F64.is_le(k1r_ma(rg), 1024.0f64)
  +cy = gv_cy_of(Ty.fa_surf(h))
  +wr = G.cy_r(cy)
  +co = G.cy_o(cy)
  +so = Bool.pick(F64, Ty.fa_same(h), 1.0f64, F64.neg(1.0f64))
  +wm = k1wall_face(Ty.fa_loops(h), lps, ces, es, vs, ax, wr, k1r_lo(rg), k1r_hi(rg), so,
    pcomp(co, run0_ax(ax)), pcomp(co, run1_ax(ax)))
  K1M{k1m_vol(wm), k1m_ar(wm), Bool.and(scok, k1m_ok(wm))}

def k1fa_go(fs: List<&2, Ty.Face>, +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, +vol: I.I, +ar: I.I, +ok: Bool) -> K1M:
  match fs:
    case []: K1M{vol, ar, ok}
    case +h <> +t:
      +sk = KU.surfkind(Ty.fa_surf(h))
      +m = Bool.pick(K1M, Bool.and(U64.is_le(1u64, sk), U64.is_le(sk, 3u64)),
        k1fa_plane(h, lps, ces, es, vs),
        Bool.pick(K1M, Bool.and(U64.is_le(4u64, sk), U64.is_le(sk, 6u64)),
          k1fa_wall(h, lps, ces, es, vs), K1M{I.ipt(0.0f64), I.ipt(0.0f64), False{}}))
      +wv = I.iwiden(k1m_vol(m), Ty.fa_slv(h))
      +wa = I.iwiden(k1m_ar(m), Ty.fa_sla(h))
      k1fa_go(t, lps, ces, es, vs, I.iadd(vol, wv), I.iadd(ar, wa),
        Bool.and(ok, k1m_ok(m)))

def k1tight(+b: Ty.Brep) -> K1M:
  k1fa_go(Ty.brep_fas(b), Ty.brep_lps(b), Ty.brep_ces(b), Ty.brep_es(b), Ty.brep_vs(b),
    I.ipt(0.0f64), I.ipt(0.0f64), True{})


def k1run_e(+okt: Bool, +whyt: U64, +brep: Ty.Brep) -> KR:
  match okt:
    case False{}: KR{False{}, whyt, brep, 0n, 0n, 0n, 0n}
    case True{}:
      KR{True{}, 0u64, brep, List.length(&2, Ty.Vertex, Ty.brep_vs(brep)),
        List.length(&2, Ty.Edge, Ty.brep_es(brep)),
        List.length(&2, Ty.Face, Ty.brep_fas(brep)),
        List.length(&2, Ty.Solid, Ty.brep_sos(brep))}

def k1run_d(+okc: Bool, +whyc: U64, +brep: Ty.Brep) -> KR:
  match okc:
    case False{}: KR{False{}, whyc, brep, 0n, 0n, 0n, 0n}
    case True{}:
      +ct = k1cert(brep)
      k1run_e(kct_ok(ct), kct_why(ct), brep)

def k1run_c(+okb: Bool, +whyb: U64, +st: AS, +ba: Ty.Brep) -> KR:
  match okb:
    case False{}: KR{False{}, whyb, ba, 0n, 0n, 0n, 0n}
    case True{}:
      +asb = k1assemble(st)
      k1run_d(kab_ok(asb), kab_why(asb), kab_brep(asb))

def k1run_b(+oka: Bool, +whya: U64, +sta: AS, +op: U64, +ba: Ty.Brep, +bb: Ty.Brep,
    +ks: List<&2, KU.KA>, +fdas: List<&2, SO.Fd>, +bba: List<&2, I.I>, +fdbs: List<&2, SO.Fd>,
    +bbb: List<&2, I.I>, +eps: F64) -> KR:
  match oka:
    case False{}: KR{False{}, whya, ba, 0n, 0n, 0n, 0n}
    case True{}:
      +rb = side_go(Ty.brep_fas(bb), bb, ba, 0n, ks, op, 1u64, fdas, bba, fdbs, bbb, ba, bb,
        sta, eps)
      k1run_c(ase_ok(rb), ase_why(rb), ase_st(rb), ba)

def k1run_s(+multi: Bool, +op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> KR:
  match multi:
    case True{}: KR{False{}, 50u64, ba, 0n, 0n, 0n, 0n}
    case False{}:
      +fdas = SO.fds_of(ba)
      +fdbs = SO.fds_of(bb)
      +bba = SO.bbox(fdas, [])
      +bbb = SO.bbox(fdbs, [])
      +ks = KU.analist(ba, bb, fdas, fdbs)
      +st0 = preadopt(ba, bb, 0.000000001f64)
      +ra = side_go(Ty.brep_fas(ba), ba, bb, 0n, ks, op, 0u64, fdbs, bbb, fdas, bba, ba, bb,
        st0, 0.000000001f64)
      k1run_b(ase_ok(ra), ase_why(ra), ase_st(ra), op, ba, bb, ks, fdas, bba, fdbs, bbb,
        0.000000001f64)

def k1run(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> KR:
  k1run_s(Bool.or(Bool.not(Nat.is_eq(List.length(&2, Ty.Solid, Ty.brep_sos(ba)), 1n)),
    Bool.not(Nat.is_eq(List.length(&2, Ty.Solid, Ty.brep_sos(bb)), 1n))), op, ba, bb)

def dbg_face(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep, +side: U64, +fi: Nat) -> String:
  +fdas = SO.fds_of(ba)
  +fdbs = SO.fds_of(bb)
  +bba = SO.bbox(fdas, [])
  +bbb = SO.bbox(fdbs, [])
  +ks = KU.analist(ba, bb, fdas, fdbs)
  +st0 = preadopt(ba, bb, 0.000000001f64)
  +b = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), ba, bb)
  +ob = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), bb, ba)
  +h = KU.nth_fa0(Ty.brep_fas(b), fi)
  +surf = Ty.fa_surf(h)
  +same = Ty.fa_same(h)
  +fr = fr_of(surf, KU.surfkind(surf))
  +fds = Bool.pick(List<&2, SO.Fd>, U64.is_eq(side, 0u64), fdbs, fdas)
  +fbb = Bool.pick(List<&2, I.I>, U64.is_eq(side, 0u64), bbb, bba)
  +fdo = Bool.pick(List<&2, SO.Fd>, U64.is_eq(side, 0u64), fdas, fdbs)
  +bbo = Bool.pick(List<&2, I.I>, U64.is_eq(side, 0u64), bba, bbb)
  +r = side_face(fr_valid(fr), fr_cyl(fr), fr, [surf], same, b, ob, fi, ks, op, side,
    fds, fbb, fdo, bbo, ba, bb, st0, 0.000000001f64)
  "s" ++ U64.show(side) ++ "f" ++ Nat.show(fi) ++ " sk" ++ U64.show(KU.surfkind(surf)) ++
    " ax" ++ U64.show(fr_ax(fr)) ++ " sm" ++ Bool.pick(String, same, "1", "0") ++
    " nf" ++ Nat.show(Nat.sub(as_nf(ase_st(r)), as_nf(st0))) ++
    " nl" ++ Nat.show(Nat.sub(as_nl(ase_st(r)), as_nl(st0))) ++
    " nc" ++ Nat.show(Nat.sub(as_nc(ase_st(r)), as_nc(st0))) ++
    Bool.pick(String, ase_ok(r), ":ok", ":no" ++ U64.show(ase_why(r)))

def dbg_cuts_go(cs: List<&2, CUT>, +acc: String) -> String:
  match cs:
    case []: acc
    case +h <> +t:
      dbg_cuts_go(t, acc ++ " [" ++ Bool.pick(String, cut_vert(h), "v", "h") ++
        F64.show(cut_c(h)) ++ Bool.pick(String, cut_ring(h), "r", "") ++ "]")

def dbg_rings_go(rs: List<&2, RG>, +fr: FR, +acc: String) -> String:
  match rs:
    case []: acc
    case +h <> +t:
      +c2 = proj_pl(fr, G.cc_c(rg_cc(h)))
      dbg_rings_go(t, fr, acc ++ " (" ++ F64.show(V.v2_x(c2)) ++ "," ++
        F64.show(V.v2_y(c2)) ++ " r" ++ F64.show(G.cc_r(rg_cc(h))) ++ ")")

def dbg_cuts(+ba: Ty.Brep, +bb: Ty.Brep, +side: U64, +fi: Nat) -> String:
  +fdas = SO.fds_of(ba)
  +fdbs = SO.fds_of(bb)
  +ks = KU.analist(ba, bb, fdas, fdbs)
  +b = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), ba, bb)
  +h = KU.nth_fa0(Ty.brep_fas(b), fi)
  +surf = Ty.fa_surf(h)
  +fr = fr_of(surf, KU.surfkind(surf))
  +fc = face_cuts(ks, fi, side, fr_ax(fr), fr_cyl(fr), 0n)
  "s" ++ U64.show(side) ++ "f" ++ Nat.show(fi) ++ " n" ++
    Nat.show(List.length(&2, CUT, fc_cuts(fc))) ++ dbg_cuts_go(fc_cuts(fc), "") ++ " nr" ++
    Nat.show(List.length(&2, RG, fc_rings(fc))) ++ dbg_rings_go(fc_rings(fc), fr, "") ++
    " cop" ++ Bool.pick(String, fc_cop(fc), "1", "0") ++ Bool.pick(String, fc_ok(fc), ":ok",
      ":no" ++ U64.show(fc_why(fc)))

def dbg_cyl(+ba: Ty.Brep, +bb: Ty.Brep, +side: U64, +fi: Nat) -> String:
  +fdas = SO.fds_of(ba)
  +fdbs = SO.fds_of(bb)
  +ks = KU.analist(ba, bb, fdas, fdbs)
  +b = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), ba, bb)
  +h = KU.nth_fa0(Ty.brep_fas(b), fi)
  +surf = Ty.fa_surf(h)
  +fr = fr_of(surf, KU.surfkind(surf))
  +lq = face_qg(b, fi, fr, True{})
  +fc = face_cuts(ks, fi, side, fr_ax(fr), True{}, 0n)
  +ls = clip_cuts(cuts_noring(fc_cuts(fc)), [lq_outer(lq)], lq_holes(lq), QC.QC{0.000000001f64, []})
  +qfs = qf_assemble(qls_outs(ls), qls_holes(ls))
  "lok" ++ Bool.pick(String, lq_ok(lq), "1", "0") ++ " o" ++
    Nat.show(List.length(&2, QC.QG, lq_outer(lq))) ++ " hs" ++
    Nat.show(List.length(&2, List<&2, QC.QG>, lq_holes(lq))) ++ " fok" ++
    Bool.pick(String, fc_ok(fc), "1", "0") ++ " nc" ++
    Nat.show(List.length(&2, CUT, fc_cuts(fc))) ++ " nr" ++
    Nat.show(List.length(&2, RG, fc_rings(fc))) ++ " cok" ++
    Bool.pick(String, qls_ok(ls), "1", "0") ++ " no" ++
    Nat.show(List.length(&2, List<&2, QC.QG>, qls_outs(ls))) ++ " eq" ++
    Bool.pick(String, face_eq(qfs, lq_outer(lq), lq_holes(lq)), "1", "0")

def dbg_lp_go(cs: List<&2, Ty.HCoedge>, +b: Ty.Brep, +acc: String) -> String:
  match cs:
    case []: acc
    case +h <> +t:
      +ce = KU.nth_ce0(Ty.brep_ces(b), Ty.hc_idx(h))
      +ed = KU.nth_ed0(Ty.brep_es(b), Ty.he_idx(Ty.ce_edge(ce)))
      +dm = Ty.ekind_dom(Ty.ed_kind(ed))
      dbg_lp_go(t, b, acc ++ " ce" ++ Bool.pick(String, Ty.ce_fwd(ce), "T", "F") ++ "e" ++
        Nat.show(Ty.he_idx(Ty.ce_edge(ce))) ++ "v" ++ Nat.show(Ty.hv_idx(Ty.ed_v0(ed))) ++
        Nat.show(Ty.hv_idx(Ty.ed_v1(ed))) ++ "k" ++ U64.show(Ty.ekind_tag(Ty.ed_kind(ed))) ++
        "d" ++ F64.show(G.dom_lo(dm)) ++ "," ++ F64.show(G.dom_hi(dm)))

def dbg_lp_go2(ls: List<&2, Ty.HLoop>, +b: Ty.Brep, +acc: String) -> String:
  match ls:
    case []: acc
    case +h <> +t:
      +lp = KU.nth_lp0(Ty.brep_lps(b), Ty.hlp_idx(h))
      dbg_lp_go2(t, b, acc ++ " L" ++ U64.show(Ty.lkind_tag(Ty.lp_kind(lp))) ++
        dbg_lp_go(Ty.lp_ces(lp), b, ""))

def dbg_rim(+ba: Ty.Brep, +bb: Ty.Brep, +side: U64, +fi: Nat) -> String:
  +b = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), ba, bb)
  +fa = KU.nth_fa0(Ty.brep_fas(b), fi)
  "f" ++ Nat.show(fi) ++ " sm" ++ Bool.pick(String, Ty.fa_same(fa), "1", "0") ++
    dbg_lp_go2(Ty.fa_loops(fa), b, "")

def dbg_side_go(fs: List<&2, Ty.Face>, +op: U64, +ba: Ty.Brep, +bb: Ty.Brep, +side: U64,
    +fi: Nat, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      dbg_side_go(t, op, ba, bb, side, Nat.add(fi, 1n),
        acc ++ " " ++ dbg_face(op, ba, bb, side, fi))

def dbg_side(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep, +side: U64) -> String:
  +b = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), ba, bb)
  dbg_side_go(Ty.brep_fas(b), op, ba, bb, side, 0n, "")

def dbg_pt(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

def dbg_ed_rq2(+q: G.RQBez) -> String:
  match q:
    case G.Rq{+p0, +p1, +p2, +w0, +w1, +w2}: " c" ++ dbg_pt(p1) ++ " w" ++ F64.show(w1)

def dbg_ed_go(cs: List<&2, Nat>, +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, +at: Nat,
    +acc: String) -> String:
  match cs:
    case []: acc
    case +h <> +t:
      +e = KU.nth_ed0(es, at)
      +pa = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v0(e))))
      +pb = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v1(e))))
      +g = Ty.ekind_curve(Ty.ed_kind(e))
      dbg_ed_go(t, es, vs, Nat.add(at, 1n), acc ++ " e" ++ Nat.show(at) ++ "=" ++
        Nat.show(h) ++ " " ++ dbg_pt(pa) ++ "-" ++ dbg_pt(pb) ++ " t" ++
        U64.show(gv_tag(g)) ++
        Bool.pick(String, U64.is_eq(gv_tag(g), 2u64), dbg_ed_rq2(gv_rq_of(g)), ""))

def dbg_edges(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +fdas = SO.fds_of(ba)
  +fdbs = SO.fds_of(bb)
  +bba = SO.bbox(fdas, [])
  +bbb = SO.bbox(fdbs, [])
  +ks = KU.analist(ba, bb, fdas, fdbs)
  +st0 = preadopt(ba, bb, 0.000000001f64)
  +ra = side_go(Ty.brep_fas(ba), ba, bb, 0n, ks, op, 0u64, fdbs, bbb, fdas, bba, ba, bb,
    st0, 0.000000001f64)
  +rb = side_go(Ty.brep_fas(bb), bb, ba, 0n, ks, op, 1u64, fdas, bba, fdbs, bbb, ba, bb,
    ase_st(ra), 0.000000001f64)
  +asb = k1assemble(ase_st(rb))
  +b = kab_brep(asb)
  +ces = Ty.brep_ces(b)
  +es = Ty.brep_es(b)
  +vs = Ty.brep_vs(b)
  +ne = List.length(&2, Ty.Edge, es)
  dbg_ed_go(k1use_go(ces, zeros(ne, [])), es, vs, 0n, "edges:")

def dbg_use_go(cs: List<&2, Nat>, +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, +at: Nat,
    +acc: String) -> String:
  match cs:
    case []: acc
    case +h <> +t:
      +e = KU.nth_ed0(es, at)
      +pa = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v0(e))))
      +pb = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v1(e))))
      dbg_use_go(t, es, vs, Nat.add(at, 1n),
        Bool.pick(String, Nat.is_eq(h, 2n), acc,
          acc ++ " e" ++ Nat.show(at) ++ "=" ++ Nat.show(h) ++ " " ++ dbg_pt(pa) ++ "-" ++
          dbg_pt(pb)))

def dbg_grps_go(gs: List<&2, GRP>, +acc: String) -> String:
  match gs:
    case []: acc
    case +h <> +t:
      dbg_grps_go(t, acc ++ " [" ++ Nat.show(grp_r(h)) ++ ":" ++
        Nat.show(List.length(&2, Nat, grp_fs(h))) ++ "]")

def dbg_nats_go(xs: List<&2, Nat>, +acc: String) -> String:
  match xs:
    case []: acc
    case +h <> +t: dbg_nats_go(t, acc ++ " " ++ Nat.show(h))

def dbg_fes_go(fs: List<&2, List<&2, Nat>>, +i: Nat, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      dbg_fes_go(t, Nat.add(i, 1n), acc ++ " f" ++ Nat.show(i) ++ ":[" ++ dbg_nats_go(h, "") ++ "]")

def dbg_comps(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +fdas = SO.fds_of(ba)
  +fdbs = SO.fds_of(bb)
  +bba = SO.bbox(fdas, [])
  +bbb = SO.bbox(fdbs, [])
  +ks = KU.analist(ba, bb, fdas, fdbs)
  +st0 = preadopt(ba, bb, 0.000000001f64)
  +ra = side_go(Ty.brep_fas(ba), ba, bb, 0n, ks, op, 0u64, fdbs, bbb, fdas, bba, ba, bb,
    st0, 0.000000001f64)
  +rb = side_go(Ty.brep_fas(bb), bb, ba, 0n, ks, op, 1u64, fdas, bba, fdbs, bbb, ba, bb,
    ase_st(ra), 0.000000001f64)
  +st = as_rev(ase_st(rb))
  +fe = faces_eis(as_fas(st), as_lps(st), as_ces(st))
  +p = comps_of(st)
  "p:[" ++ dbg_nats_go(p, "") ++ "]" ++ dbg_fes_go(fe, 0n, "")

def dbg_vs_go(vs: List<&2, Ty.Vertex>, +i: Nat, +acc: String) -> String:
  match vs:
    case []: acc
    case +h <> +t:
      dbg_vs_go(t, Nat.add(i, 1n), acc ++ " " ++ Nat.show(i) ++ "=" ++ dbg_pt(Ty.vx_p(h)))

def dbg_es_go(es: List<&2, Ty.Edge>, +i: Nat, +acc: String) -> String:
  match es:
    case []: acc
    case +h <> +t:
      dbg_es_go(t, Nat.add(i, 1n), acc ++ " " ++ Nat.show(i) ++ "=" ++
        Nat.show(Ty.hv_idx(Ty.ed_v0(h))) ++ "-" ++ Nat.show(Ty.hv_idx(Ty.ed_v1(h))))

def dbg_topo(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +fdas = SO.fds_of(ba)
  +fdbs = SO.fds_of(bb)
  +bba = SO.bbox(fdas, [])
  +bbb = SO.bbox(fdbs, [])
  +ks = KU.analist(ba, bb, fdas, fdbs)
  +st0 = preadopt(ba, bb, 0.000000001f64)
  +ra = side_go(Ty.brep_fas(ba), ba, bb, 0n, ks, op, 0u64, fdbs, bbb, fdas, bba, ba, bb,
    st0, 0.000000001f64)
  +rb = side_go(Ty.brep_fas(bb), bb, ba, 0n, ks, op, 1u64, fdas, bba, fdbs, bbb, ba, bb,
    ase_st(ra), 0.000000001f64)
  +asb = k1assemble(ase_st(rb))
  +b = kab_brep(asb)
  "vs:" ++ dbg_vs_go(Ty.brep_vs(b), 0n, "") ++ " es:" ++
    dbg_es_go(Ty.brep_es(b), 0n, "")

def dbg_grps(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +fdas = SO.fds_of(ba)
  +fdbs = SO.fds_of(bb)
  +bba = SO.bbox(fdas, [])
  +bbb = SO.bbox(fdbs, [])
  +ks = KU.analist(ba, bb, fdas, fdbs)
  +st0 = preadopt(ba, bb, 0.000000001f64)
  +ra = side_go(Ty.brep_fas(ba), ba, bb, 0n, ks, op, 0u64, fdbs, bbb, fdas, bba, ba, bb,
    st0, 0.000000001f64)
  +rb = side_go(Ty.brep_fas(bb), bb, ba, 0n, ks, op, 1u64, fdas, bba, fdbs, bbb, ba, bb,
    ase_st(ra), 0.000000001f64)
  +st = as_rev(ase_st(rb))
  +p = comps_of(st)
  +n = as_nf(st)
  +gs = groups_go(erange(n, []), p, n, [])
  "ng=" ++ Nat.show(List.length(&2, GRP, gs)) ++ dbg_grps_go(gs, "") ++ " ne=" ++
    Nat.show(as_ne(st)) ++ " nf=" ++ Nat.show(n)

def dbg_use(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +fdas = SO.fds_of(ba)
  +fdbs = SO.fds_of(bb)
  +bba = SO.bbox(fdas, [])
  +bbb = SO.bbox(fdbs, [])
  +ks = KU.analist(ba, bb, fdas, fdbs)
  +st0 = preadopt(ba, bb, 0.000000001f64)
  +ra = side_go(Ty.brep_fas(ba), ba, bb, 0n, ks, op, 0u64, fdbs, bbb, fdas, bba, ba, bb,
    st0, 0.000000001f64)
  +rb = side_go(Ty.brep_fas(bb), bb, ba, 0n, ks, op, 1u64, fdas, bba, fdbs, bbb, ba, bb,
    ase_st(ra), 0.000000001f64)
  +asb = k1assemble(ase_st(rb))
  +b = kab_brep(asb)
  +ces = Ty.brep_ces(b)
  +es = Ty.brep_es(b)
  +vs = Ty.brep_vs(b)
  +ne = List.length(&2, Ty.Edge, es)
  "ra" ++ Bool.pick(String, ase_ok(ra), "ok", "no" ++ U64.show(ase_why(ra))) ++ " rb" ++
    Bool.pick(String, ase_ok(rb), "ok", "no" ++ U64.show(ase_why(rb))) ++ " kab" ++
    Bool.pick(String, kab_ok(asb), "ok", "no" ++ U64.show(kab_why(asb))) ++ " nv" ++
    Nat.show(List.length(&2, Ty.Vertex, Ty.brep_vs(b))) ++ " ne" ++ Nat.show(ne) ++ " nc" ++
    Nat.show(List.length(&2, Ty.Coedge, ces)) ++ " nf" ++
    Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(b))) ++
    dbg_use_go(k1use_go(ces, zeros(ne, [])), es, vs, 0n, " bad:")

def dbg_qg_go(ps: List<&2, QC.QG>, +acc: String) -> String:
  match ps:
    case []: acc
    case +h <> +t:
      dbg_qg_go(t, acc ++ " (" ++ F64.show(QC.qg_ax(h)) ++ "," ++ F64.show(QC.qg_ay(h)) ++
        ")->(" ++ F64.show(QC.qg_bx(h)) ++ "," ++ F64.show(QC.qg_by(h)) ++ ")" ++
        Bool.pick(String, QC.qg_is_ln(h), "", "A"))

def dbg_keep_sm(+m: Maybe<&2, V.Vec2>, +o: List<&2, QC.QG>, +fr: FR, +sx: Bool,
    +surf: List<&2, G.GVal>, +op: U64, +side: U64, +fds: List<&2, SO.Fd>,
    +bb: List<&2, I.I>, +tiny: F64) -> String:
  match m:
    case None{}:
      "none sgn" ++ F64.show(QC.sh_signed(o)) ++ " n" ++
        Nat.show(List.length(&2, QC.QG, o)) ++ dbg_qg_go(o, "")
    case Some{+v}:
      +u = frag_unproj(v, fr, sx, surf)
      +p = Bool.pick(V.Point, pu_ok(u), pu_p(u), V.Pt{0.0f64, 0.0f64, 0.0f64})
      "v" ++ F64.show(V.v2_x(v)) ++ "," ++ F64.show(V.v2_y(v)) ++ " p" ++ dbg_pt(p) ++
        " c" ++ U64.show(Bool.pick(U64, pu_ok(u), pt_cls(p, fds, bb), 9u64))

def dbg_keep(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep, +side: U64, +fi: Nat) -> String:
  +fdas = SO.fds_of(ba)
  +fdbs = SO.fds_of(bb)
  +bba = SO.bbox(fdas, [])
  +bbb = SO.bbox(fdbs, [])
  +b = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), ba, bb)
  +h = KU.nth_fa0(Ty.brep_fas(b), fi)
  +surf = Ty.fa_surf(h)
  +fr = fr_of(surf, KU.surfkind(surf))
  +fds = Bool.pick(List<&2, SO.Fd>, U64.is_eq(side, 0u64), fdbs, fdas)
  +fbb = Bool.pick(List<&2, I.I>, U64.is_eq(side, 0u64), bbb, bba)
  +lq = face_qg(b, fi, fr, False{})
  +o = lq_outer(lq)
  dbg_keep_sm(QC.samp_find(o), o, fr, False{}, [surf], op, side, fds, fbb,
    bb_tiny(qg_bbox(o)))

def dbg_arc_go(ps: List<&2, QC.QG>, +acc: String) -> String:
  match ps:
    case []: acc
    case +h <> +t:
      dbg_arc_go(t, acc ++ " c" ++ F64.show(QC.qg_cx(h)) ++ "," ++
        F64.show(QC.qg_cy(h)) ++ " r" ++ F64.show(QC.qg_cr(h)) ++
        Bool.pick(String, QC.qg_ccw(h), "w1", "w0"))

def dbg_pip(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep, +side: U64, +fi: Nat) -> String:
  +b = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), ba, bb)
  +h = KU.nth_fa0(Ty.brep_fas(b), fi)
  +surf = Ty.fa_surf(h)
  +fr = fr_of(surf, KU.surfkind(surf))
  +o = lq_outer(face_qg(b, fi, fr, False{}))
  "p55:" ++ U64.show(QC.pip_loop(o, 5.0f64, 5.0f64)) ++ " p699:" ++
    U64.show(QC.pip_loop(o, 6.999f64, 5.0f64)) ++ " p701:" ++
    U64.show(QC.pip_loop(o, 7.001f64, 5.0f64)) ++ dbg_arc_go(o, "")

def dbg_frags_go(fs: List<&2, QC.QF>, +fr: FR, +surf: List<&2, G.GVal>, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +po: List<&2, QC.QG>, +same: Bool, +hasm: Bool,
    +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      +o = QC.qf_outer(h)
      +tiny = bb_tiny(qg_bbox(o))
      +keep = frag_keep(h, fr, False{}, surf, op, side, fds, fbb, tiny, po, same, hasm)
      dbg_frags_go(t, fr, surf, op, side, fds, fbb, po, same, hasm,
        acc ++ " {n=" ++ Nat.show(List.length(&2, QC.QG, o)) ++ " area=" ++
        F64.show(QC.sh_signed(o)) ++ " keep=" ++ U64.show(keep) ++ dbg_qg_go(o, "") ++ "}")

def dbg_frags_cop(+o: List<&2, QC.QG>, +hs: List<&2, List<&2, QC.QG>>, +cuts: List<&2, CUT>,
    +b: Ty.Brep, +ob: Ty.Brep, +fi: Nat, +fr: FR, +surf: List<&2, G.GVal>, +same: Bool,
    +ks: List<&2, KU.KA>, +op: U64, +side: U64, +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>,
    +eps: F64) -> String:
  +pj = cop_partner(ks, fi, side, List.length(&2, Ty.Face, Ty.brep_fas(ob)))
  +oq = face_qg(ob, pj, fr, False{})
  +po = lq_outer(oq)
  +mfa = KU.nth_fa0(Ty.brep_fas(ob), pj)
  +sm = dir_eq3(face_n(surf, same, fr), face_n([Ty.fa_surf(mfa)], Ty.fa_same(mfa), fr))
  +mc = mate_cuts(po, pj, cuts, o)
  +ls = clip_cuts(cuts_noring(mc), [o], hs, QC.QC{eps, []})
  +qfs = qf_assemble(qls_outs(ls), qls_holes(ls))
  "pj=" ++ Nat.show(pj) ++ " nq=" ++ Nat.show(List.length(&2, QC.QF, qfs)) ++
    dbg_frags_go(qfs, fr, surf, op, side, fds, fbb, po, sm, True{}, "")

def dbg_frags_plain(+o: List<&2, QC.QG>, +hs: List<&2, List<&2, QC.QG>>,
    +cuts: List<&2, CUT>, +fr: FR, +surf: List<&2, G.GVal>, +op: U64, +side: U64,
    +fds: List<&2, SO.Fd>, +fbb: List<&2, I.I>, +eps: F64) -> String:
  +ls = clip_cuts(cuts_noring(cuts), [o], hs, QC.QC{eps, []})
  +qfs = qf_assemble(qls_outs(ls), qls_holes(ls))
  "nq=" ++ Nat.show(List.length(&2, QC.QF, qfs)) ++
    dbg_frags_go(qfs, fr, surf, op, side, fds, fbb, [], False{}, False{}, "")

def dbg_frags(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep, +side: U64, +fi: Nat) -> String:
  +fdas = SO.fds_of(ba)
  +fdbs = SO.fds_of(bb)
  +bba = SO.bbox(fdas, [])
  +bbb = SO.bbox(fdbs, [])
  +ks = KU.analist(ba, bb, fdas, fdbs)
  +b = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), ba, bb)
  +ob = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), bb, ba)
  +h = KU.nth_fa0(Ty.brep_fas(b), fi)
  +surf = Ty.fa_surf(h)
  +same = Ty.fa_same(h)
  +fr = fr_of(surf, KU.surfkind(surf))
  +fds = Bool.pick(List<&2, SO.Fd>, U64.is_eq(side, 0u64), fdbs, fdas)
  +fbb = Bool.pick(List<&2, I.I>, U64.is_eq(side, 0u64), bbb, bba)
  +lq = face_qg(b, fi, fr, False{})
  +fc = face_cuts(ks, fi, side, fr_ax(fr), False{}, 0n)
  +cop = fc_cop(fc)
  +plain = dbg_frags_plain(lq_outer(lq), lq_holes(lq), fc_cuts(fc), fr, [surf], op, side,
    fds, fbb, 0.000000001f64)
  +cx = dbg_frags_cop(lq_outer(lq), lq_holes(lq), fc_cuts(fc), b, ob, fi, fr, [surf],
    same, ks, op, side, fds, fbb, 0.000000001f64)
  "s" ++ U64.show(side) ++ "f" ++ Nat.show(fi) ++ " cop" ++
    Bool.pick(String, cop, "1", "0") ++ " " ++ Bool.pick(String, cop, cx, plain)

def dbg_rls_go(fs: List<&2, QC.QF>, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      dbg_rls_go(t, acc ++ " qf[no" ++ Nat.show(List.length(&2, QC.QG, QC.qf_outer(h))) ++
        " nh" ++ Nat.show(List.length(&2, List<&2, QC.QG>, QC.qf_holes(h))) ++
        dbg_qg_go(QC.qf_outer(h), "") ++ "]")

def dbg_pc_show(+h: QC.QG) -> String:
  " (" ++ F64.show(QC.qg_ax(h)) ++ "," ++ F64.show(QC.qg_ay(h)) ++ ")->(" ++
    F64.show(QC.qg_bx(h)) ++ "," ++ F64.show(QC.qg_by(h)) ++ ")c(" ++
    F64.show(QC.qg_cx(h)) ++ "," ++ F64.show(QC.qg_cy(h)) ++ ")r" ++
    F64.show(QC.qg_cr(h)) ++ Bool.pick(String, QC.qg_ccw(h), "w", "v") ++ "l" ++
    U64.show(QC.qg_lab(h)) ++ "r" ++ Nat.show(QC.qg_ref(h)) ++ "m(" ++
    F64.show(V.v2_x(QC.qg_mid(h))) ++ "," ++ F64.show(V.v2_y(QC.qg_mid(h))) ++ ")"

def dbg_rf_mid(+okm: Bool, +pm0: V.Point, +va: Nat, +vb: Nat, +st: AS) -> String:
  match okm:
    case False{}: " midfail"
    case True{}:
      +rm = maddopt(st, pm0, 0.000000001f64)
      +vm = vr_idx(rm)
      +st1 = vr_st(rm)
      +pa = pt_of(st1, va)
      +pm = pt_mid(st1, vm)
      +pb = pt_of(st1, vb)
      +hs = rq_hs(pa, pm, pb)
      +h = V.v2_x(hs)
      +s = V.v2_y(hs)
      " h" ++ F64.show(h) ++ " s" ++ F64.show(s) ++ " w" ++
        F64.show(rq_circ_w(h, s)) ++ " pm(" ++ F64.show(V.pt_x(pm)) ++ "," ++
        F64.show(V.pt_y(pm)) ++ ")"

def dbg_rf_go(ps: List<&2, QC.QG>, +fr: FR, +surf: List<&2, G.GVal>, +st: AS,
    +acc: String) -> String:
  match ps:
    case []: acc
    case +h <> +t:
      +up = emit_unproj(h, fr, False{}, surf)
      +ad = emit_adopt(pup_pa(up), pup_pb(up), st, 0.000000001f64)
      +um = frag_unproj(QC.qg_mid(h), fr, False{}, surf)
      dbg_rf_go(t, fr, surf, pea_st(ad), acc ++
        Bool.pick(String, pup_oka(up), "", " NOA") ++
        Bool.pick(String, pup_okb(up), "", " NOB") ++
        Bool.pick(String, Nat.is_eq(pea_va(ad), pea_vb(ad)), " FUSED",
          dbg_rf_mid(pu_ok(um), pu_p(um), pea_va(ad), pea_vb(ad), pea_st(ad))) ++ ";")

def dbg_pcs_go(ps: List<&2, QC.QG>, +fr: FR, +surf: List<&2, G.GVal>, +side: U64,
    +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +acc: String) -> String:
  match ps:
    case []: acc
    case +h <> +t:
      +r = emit_piece(h, fr, False{}, surf, side, ba, bb, st, 0.000000001f64)
      dbg_pcs_go(t, fr, surf, side, ba, bb, pe_st(r), acc ++
        Bool.pick(String, pe_ok(r), " p:ok", " p:no" ++ U64.show(pe_why(r))) ++
        dbg_pc_show(h))

def dbg_emit_go(fs: List<&2, QC.QF>, +fr: FR, +surf: List<&2, G.GVal>, +side: U64,
    +ba: Ty.Brep, +bb: Ty.Brep, +st: AS, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      +r = emit_qf(h, fr, False{}, surf, side, ba, bb, st, 0.000000001f64)
      dbg_emit_go(t, fr, surf, side, ba, bb, lf_st(r), acc ++
        Bool.pick(String, lf_ok(r), " e:ok", " e:no" ++ U64.show(lf_why(r))) ++
        dbg_pcs_go(QC.pieces_split(QC.qf_outer(h)), fr, surf, side, ba, bb,
          AS{[], [], [], [], [], [], 0n, 0n, 0n, 0n, 0n, [], 0n}, "") ++
        dbg_rf_go(QC.pieces_split(QC.qf_outer(h)), fr, surf,
          AS{[], [], [], [], [], [], 0n, 0n, 0n, 0n, 0n, [], 0n}, " RF:"))

def dbg_rls_mc(+cop: Bool, +po: List<&2, QC.QG>, +pj: Nat, +cuts: List<&2, CUT>,
    +o: List<&2, QC.QG>) -> List<&2, CUT>:
  match cop:
    case True{}: mate_cuts(po, pj, cuts, o)
    case False{}: cuts

def dbg_rls(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep, +side: U64, +fi: Nat) -> String:
  +fdas = SO.fds_of(ba)
  +fdbs = SO.fds_of(bb)
  +ks = KU.analist(ba, bb, fdas, fdbs)
  +b = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), ba, bb)
  +h = KU.nth_fa0(Ty.brep_fas(b), fi)
  +surf = Ty.fa_surf(h)
  +fr = fr_of(surf, KU.surfkind(surf))
  +lq = face_qg(b, fi, fr, False{})
  +fc = face_cuts(ks, fi, side, fr_ax(fr), False{}, 0n)
  +ob = Bool.pick(Ty.Brep, U64.is_eq(side, 0u64), bb, ba)
  +pj = cop_partner(ks, fi, side, List.length(&2, Ty.Face, Ty.brep_fas(ob)))
  +po = lq_outer(face_qg(ob, pj, fr, False{}))
  +mc = dbg_rls_mc(fc_cop(fc), po, pj, fc_cuts(fc), lq_outer(lq))
  +ls = clip_cuts(cuts_noring(mc), [lq_outer(lq)], lq_holes(lq),
    QC.QC{0.000000001f64, []})
  +rl = rings_apply(fc_rings(fc), fr, qf_assemble(qls_outs(ls), qls_holes(ls)))
  +o = lq_outer(lq)
  "s" ++ U64.show(side) ++ "f" ++ Nat.show(fi) ++
    Bool.pick(String, rls_ok(rl), ":ok", ":no" ++ U64.show(rls_why(rl))) ++
    " o:" ++ dbg_qg_go(o, "") ++ dbg_rls_go(rls_qfs(rl), "") ++
    dbg_emit_go(rls_qfs(rl), fr, [surf], side, ba, bb,
      AS{[], [], [], [], [], [], 0n, 0n, 0n, 0n, 0n, [], 0n}, "")

def dbg_ka_go(ks: List<&2, KU.KA>, +acc: String) -> String:
  match ks:
    case []: acc
    case +h <> +t:
      dbg_ka_go(t, acc ++ " [" ++ Nat.show(KU.ka_fa(h)) ++ "," ++ Nat.show(KU.ka_fb(h)) ++
        " r" ++ U64.show(KU.ka_rel(h)) ++ " d" ++ U64.show(KU.ka_dec(h)) ++ "]")

def dbg_ka(+ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +fdas = SO.fds_of(ba)
  +fdbs = SO.fds_of(bb)
  dbg_ka_go(KU.analist(ba, bb, fdas, fdbs), "kas" ++ Nat.show(List.length(&2, KU.KA, KU.analist(ba, bb, fdas, fdbs))) ++ ":")
