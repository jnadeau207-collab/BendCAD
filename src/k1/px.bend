import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../base/par.bend as B
import ./sf.bend as S
import ../c03/bpi.bend as BI
import ./ef.bend as EF
import ./ss.bend as SS
import ./fb.bend as FB
import ./ls.bend as L
import ../c03/ops.bend as GO






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






type EP is Data:
  EP{ e: Nat, fo: Nat }






type EJ is Data:
  EJ{ e: Nat, fo: Nat, inp: Bool, r: EF.EHS }






type EX is Data:
  EX{ b: FB.KB, ob: FB.KB }






type IV is Data:
  IV{ lo: F64, hi: F64 }






type FV is Data:
  FV{ dd: IV, h: IV, rho: IV }






type VD is Data:
  VD{ e: Nat, k: Ty.EdgeKind, bx: FB.BB, q0: V.Point, q1: V.Point }






type VC is Data:
  VC{ v: Nat, p: V.Point, es: List<&2, Nat> }






type VX is Data:
  VX{ ob: FB.KB, ds: List<&2, VD> }






type WD is Data:
  WD{ ok: Bool, o: V.Point, n0: V.Dir, n1: V.Dir, a: V.Dir, polys: List<&2, List<&2, V.Point>> }






type PJ is Data:
  PJ{ fa: Nat, fb: Nat, x: SS.ICS, ph: List<&2, HX> }






type PC is Data:
  PC{ bxs: List<&2, FB.BB>, wds: List<&2, WD>, rhs: List<&2, V.Vec2>, hs: List<&2, HX>, ba: FB.KB, bb: FB.KB }

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

def same_tol(+p: V.Point) -> F64:
  F64.mul(1.4210854715202004e-14f64, F64.add(1.0f64, F64.max(F64.abs(S.px(p)), F64.max(F64.abs(S.py(p)), F64.abs(S.pz(p))))))

def psame(+a: V.Point, +b: V.Point, +e: F64) -> Bool:
  Bool.and(F64.is_le(F64.abs(F64.sub(S.px(a), S.px(b))), e),
    Bool.and(F64.is_le(F64.abs(F64.sub(S.py(a), S.py(b))), e), F64.is_le(F64.abs(F64.sub(S.pz(a), S.pz(b))), e)))

def find_go(ps: List<&2, V.Point>, +p: V.Point, +e: F64, +i: Nat, +n: Nat) -> Nat:
  match ps:
    case []: n
    case +h <> +t: Bool.pick(Nat, psame(h, p, e), i, find_go(t, p, e, Nat.add(i, 1n), n))

def gv_add(+g: GV, +p: V.Point) -> VI:
  +f = find_go(List.reverse(&2, V.Point, gv_ps(g)), p, same_tol(p), 0n, gv_n(g))
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

def surfs_of(fs: List<&2, Nat>, +b: FB.KB) -> List<&2, G.GVal>:
  match fs:
    case []: []
    case +h <> +t: FB.face_surf(b, h) <> surfs_of(t, b)

def cop_in(cop: Bool, +h: Nat, +b: FB.KB, +p: V.Point) -> Bool:
  match cop:
    case False{}: False{}
    case True{}: Bool.or(FB.pt_in_face(b, h, p), FB.bnd_near(b, h, p))

def on_cop(+h: Nat, +b: FB.KB, +g: G.GVal, +p: V.Point) -> Bool:
  cop_in(FB.coplanar(FB.face_surf(b, h), g), h, b, p)

def any_coplanar(fs: List<&2, Nat>, +b: FB.KB, +g: G.GVal, +p: V.Point) -> Bool:
  match fs:
    case []: False{}
    case +h <> +t: Bool.or(on_cop(h, b, g, p), any_coplanar(t, b, g, p))

def flush_of(atend: Bool, +b: FB.KB, +g: G.GVal, +p: V.Point) -> Bool:
  match atend:
    case False{}: False{}
    case True{}: any_coplanar(L.nat_range(FB.nfaces(b)), b, g, p)

def at_v(+p: V.Point, +q: V.Point) -> Bool:
  F64.is_le(S.dist(p, q), F64.mul(1.0e-9f64, F64.add(1.0f64, S.dlen(S.psub(q, S.pt(0.0f64, 0.0f64, 0.0f64))))))

def snap_t(+t0: F64, +lo: F64, +hi: F64, +ob: FB.KB, +fo: Nat, +b: FB.KB, +e: Nat) -> F64:
  +ed = FB.edge_at(b, e)
  +gs = FB.face_surf(ob, fo)
  +eps = F64.mul(1.0e-9f64, F64.sub(hi, lo))
  +p = EF.ev(EF.ek_curve(Ty.ed_kind(ed)), t0)
  +nlo = Bool.and(Bool.or(F64.is_le(F64.abs(F64.sub(t0, lo)), eps), at_v(p, FB.vpt(b, Ty.ed_v0(ed)))), GO.q_on_r(gs, FB.vpt(b, Ty.ed_v0(ed))))
  +nhi = Bool.and(Bool.or(F64.is_le(F64.abs(F64.sub(t0, hi)), eps), at_v(p, FB.vpt(b, Ty.ed_v1(ed)))), GO.q_on_r(gs, FB.vpt(b, Ty.ed_v1(ed))))
  Bool.pick(F64, nlo, lo, Bool.pick(F64, nhi, hi, t0))

def eh_keep(hs: List<&2, EF.EH>, +side: U64, +e: Nat, +fo: Nat, +ob: FB.KB, +b: FB.KB, +lo: F64, +hi: F64,
    +st: HS) -> HS:
  match hs:
    case []: st
    case +h <> +t:
      +ed = FB.edge_at(b, e)
      +tt = snap_t(EF.eh_t(h), lo, hi, ob, fo, b, e)
      +atend = Bool.or(F64.is_eq(tt, lo), F64.is_eq(tt, hi))
      +p = Bool.pick(V.Point, atend, FB.vpt(b, Bool.pick(Ty.HVertex, F64.is_eq(tt, lo), Ty.ed_v0(ed), Ty.ed_v1(ed))), EF.eh_p(h))
      +flush = flush_of(atend, b, FB.face_surf(ob, fo), p)
      +bn = FB.bnd_near(ob, fo, p)
      +inside = Bool.and(Bool.not(flush), Bool.or(FB.pt_in_face(ob, fo, p), bn))
      +r = gv_add(hs_g(st), p)
      +ok = Bool.and(hs_ok(st), Bool.or(Bool.not(inside), Bool.or(atend, EF.eh_ok(h))))
      +why = Bool.pick(U64, hs_ok(st), Bool.pick(U64, Bool.or(Bool.not(inside), Bool.or(atend, EF.eh_ok(h))), 0u64, why_hcert()), hs_why(st))
      +nst = Bool.pick(HS, inside,
        HS{HX{side, e, tt, p, vi_i(r), fo} <> hs_hs(st), vi_g(r), ok, why},
        HS{hs_hs(st), hs_g(st), ok, why})
      eh_keep(t, side, e, fo, ob, b, lo, hi, nst)

def pl_off(+s: S.SF, +p: V.Point) -> F64:
  F64.abs(S.dot(S.psub(p, S.sf_o(s)), S.sf_a(s)))

def in_plane(+k: Ty.EdgeKind, +s: S.SF) -> Bool:
  +c = EF.ek_curve(k)
  +lo = EF.ek_lo(k)
  +hi = EF.ek_hi(k)
  +d = F64.sub(hi, lo)
  +p0 = EF.ev(c, lo)
  +tol = F64.mul(1.0e-12f64, F64.add(1.0f64, S.dlen(S.psub(p0, S.sf_o(s)))))
  +m = F64.max(F64.max(pl_off(s, p0), pl_off(s, EF.ev(c, hi))), F64.max(pl_off(s, EF.ev(c, F64.add(lo, F64.mul(0.5f64, d)))),
    F64.max(pl_off(s, EF.ev(c, F64.add(lo, F64.mul(0.25f64, d)))), pl_off(s, EF.ev(c, F64.add(lo, F64.mul(0.75f64, d)))))))
  Bool.and(U64.is_eq(S.sf_kind(s), S.k_plane()), F64.is_le(m, tol))

def cy_off(+s: S.SF, +p: V.Point) -> F64:
  +a = S.sf_a(s)
  F64.abs(F64.sub(F64.div(S.dlen(S.cross(S.psub(p, S.sf_o(s)), a)), S.dlen(a)), S.sf_r(s)))

def on_cyl(+k: Ty.EdgeKind, +s: S.SF) -> Bool:
  +c = EF.ek_curve(k)
  +lo = EF.ek_lo(k)
  +hi = EF.ek_hi(k)
  +d = F64.sub(hi, lo)
  +p0 = EF.ev(c, lo)
  +tol = F64.mul(1.0e-12f64, F64.add(1.0f64, F64.add(S.sf_r(s), S.dlen(S.psub(p0, S.sf_o(s))))))
  +m = F64.max(F64.max(cy_off(s, p0), cy_off(s, EF.ev(c, hi))), F64.max(cy_off(s, EF.ev(c, F64.add(lo, F64.mul(0.5f64, d)))),
    F64.max(cy_off(s, EF.ev(c, F64.add(lo, F64.mul(0.25f64, d)))), cy_off(s, EF.ev(c, F64.add(lo, F64.mul(0.75f64, d)))))))
  Bool.and(U64.is_eq(S.sf_kind(s), S.k_cyl()), F64.is_le(m, tol))

def ve_t(n: Nat, +c: G.GVal, +p: V.Point, +lo: F64, +hi: F64) -> F64:
  match n:
    case 0n: F64.mul(0.5f64, F64.add(lo, hi))
    case 1n+m:
      +a = F64.add(lo, F64.div(F64.sub(hi, lo), 3.0f64))
      +b = F64.sub(hi, F64.div(F64.sub(hi, lo), 3.0f64))
      +near = F64.is_lt(S.dist(EF.ev(c, a), p), S.dist(EF.ev(c, b), p))
      ve_t(m, c, p, Bool.pick(F64, near, lo, a), Bool.pick(F64, near, b, hi))

def ve_seed(n: Nat, +c: G.GVal, +p: V.Point, +lo: F64, +dt: F64, +k: F64, +best: F64, +bd: F64) -> F64:
  match n:
    case 0n: best
    case 1n+m:
      +t = F64.add(lo, F64.mul(k, dt))
      +d = S.dist(EF.ev(c, t), p)
      +b = F64.is_lt(d, bd)
      ve_seed(m, c, p, lo, dt, F64.add(k, 1.0f64), Bool.pick(F64, b, t, best), Bool.pick(F64, b, d, bd))

def ve_param(+k: Ty.EdgeKind, +p: V.Point) -> F64:
  +c = EF.ek_curve(k)
  +lo = EF.ek_lo(k)
  +hi = EF.ek_hi(k)
  +dt = F64.div(F64.sub(hi, lo), 64.0f64)
  +t0 = ve_seed(65n, c, p, lo, dt, 0.0f64, lo, F64.div(1.0f64, 0.0f64))
  ve_t(80n, c, p, F64.max(lo, F64.sub(t0, dt)), F64.min(hi, F64.add(t0, dt)))

def ve_tol(+p: V.Point) -> F64:
  F64.mul(1.0e-9f64, F64.add(1.0f64, S.dlen(S.psub(p, S.pt(0.0f64, 0.0f64, 0.0f64)))))

def v_on_k(+k: Ty.EdgeKind, +p: V.Point) -> Bool:
  F64.is_lt(S.dist(EF.ev(EF.ek_curve(k), ve_param(k, p)), p), ve_tol(p))

def on_if(c: Bool, +k: Ty.EdgeKind, +p: V.Point) -> Bool:
  match c:
    case False{}: False{}
    case True{}: v_on_k(k, p)

def v_near(vs: List<&2, Ty.Vertex>, done: Bool, +k: Ty.EdgeKind, +q: V.Point, +r: F64) -> Bool:
  match vs:
    case []: done
    case +v <> +t:
      match done:
        case True{}: True{}
        case False{}:
          +p = Ty.vx_p(v)
          v_near(t, on_if(F64.is_le(S.dist(p, q), r), k, p), k, q, r)

def on_edges(es: List<&2, Nat>, done: Bool, +ob: FB.KB, +p: V.Point) -> Bool:
  match es:
    case []: done
    case +e <> +t:
      match done:
        case True{}: True{}
        case False{}:
          +k = Ty.ed_kind(FB.edge_at(ob, e))
          on_edges(t, on_if(Bool.not(FB.bb_dis(FB.bb_pad(FB.ek_bb(k), ve_tol(p)), FB.bb_pt(p))), k, p), ob, p)

def on_far(c: Bool, +ob: FB.KB, +p: V.Point) -> Bool:
  match c:
    case False{}: False{}
    case True{}: on_edges(L.nat_range(FB.nedges(ob)), False{}, ob, p)

def end_on(+q: V.Point, +p: V.Point, +r: F64, +ob: FB.KB) -> Bool:
  on_far(F64.is_le(S.dist(p, q), r), ob, p)

def near_at_vertex(+k: Ty.EdgeKind, +nt: F64, +ob: FB.KB) -> Bool:
  +c = EF.ek_curve(k)
  +q = EF.ev(c, nt)
  +step = F64.div(F64.sub(EF.ek_hi(k), EF.ek_lo(k)), 96.0f64)
  +r = F64.add(F64.mul(2.0f64, S.dist(q, EF.ev(c, F64.add(nt, step)))), ve_tol(q))
  Bool.or(v_near(Ty.brep_vs(FB.kb_br(ob)), False{}, k, q, r), Bool.or(end_on(q, EF.ev(c, EF.ek_lo(k)), r, ob), end_on(q, EF.ev(c, EF.ek_hi(k)), r, ob)))

def near_bad(near: Bool, +k: Ty.EdgeKind, +nt: F64, +ob: FB.KB) -> Bool:
  match near:
    case False{}: False{}
    case True{}: Bool.not(near_at_vertex(k, nt, ob))

def near_on(near: Bool, +ob: FB.KB, +fo: Nat, +q: V.Point) -> Bool:
  match near:
    case False{}: False{}
    case True{}: Bool.not(FB.bb_dis(FB.bb_pad(FB.face_bb(ob, fo), ve_tol(q)), FB.bb_pt(q)))

def fb_one(sharp: Bool, +ob: FB.KB, +fi: Nat) -> FB.BB:
  match sharp:
    case True{}: FB.face_bb(ob, fi)
    case False{}: FB.bb_huge()

def fbs_of(n: Nat, +ob: FB.KB, +acc: List<&2, FB.BB>) -> List<&2, FB.BB>:
  match n:
    case 0n: acc
    case 1n+(+i):
      +k = S.sf_kind(S.sf_of(FB.face_surf(ob, i)))
      fbs_of(i, ob, fb_one(Bool.and(U64.is_le(S.k_plane(), k), U64.is_le(k, S.k_bp())), ob, i) <> acc)

def near_fs(bs: List<&2, FB.BB>, +eb: FB.BB, +i: Nat) -> List<&2, Nat>:
  match bs:
    case []: []
    case +h <> +t:
      +rest = near_fs(t, eb, Nat.add(i, 1n))
      Bool.pick(List<&2, Nat>, FB.bb_dis(h, eb), rest, i <> rest)

def bb_reach(+a: FB.BB) -> F64:
  FB.BB{+x0, +x1, +y0, +y1, +z0, +z1} = a
  F64.max(F64.max(F64.max(F64.abs(x0), F64.abs(x1)), F64.max(F64.abs(y0), F64.abs(y1))), F64.max(F64.abs(z0), F64.abs(z1)))

def edge_box(+b: FB.KB, +e: Nat) -> FB.BB:
  +ed = FB.edge_at(b, e)
  +bx = FB.bb_join(FB.ek_bb(Ty.ed_kind(ed)), FB.bb_join(FB.bb_pt(FB.vpt(b, Ty.ed_v0(ed))), FB.bb_pt(FB.vpt(b, Ty.ed_v1(ed)))))
  FB.bb_pad(bx, F64.mul(1.0e-6f64, F64.add(1.0f64, bb_reach(bx))))

def ep_fs(fs: List<&2, Nat>, +e: Nat, +acc: List<&2, EP>) -> List<&2, EP>:
  match fs:
    case []: acc
    case +h <> +t: EP{e, h} <> ep_fs(t, e, acc)

def ep_all(es: List<&2, Nat>, +b: FB.KB, +fbs: List<&2, FB.BB>) -> List<&2, EP>:
  match es:
    case []: []
    case +h <> +t: ep_fs(near_fs(fbs, edge_box(b, h), 0n), h, ep_all(t, b, fbs))

def iv_lo(+a: IV) -> F64:
  IV{+l, +h} = a
  l

def iv_hi(+a: IV) -> F64:
  IV{+l, +h} = a
  h

def iv_add(+a: IV, +b: IV) -> IV:
  IV{F64.add(iv_lo(a), iv_lo(b)), F64.add(iv_hi(a), iv_hi(b))}

def iv_sub(+a: IV, +b: IV) -> IV:
  IV{F64.sub(iv_lo(a), iv_hi(b)), F64.sub(iv_hi(a), iv_lo(b))}

def iv_scl(+k: F64, +a: IV) -> IV:
  +x = F64.mul(k, iv_lo(a))
  +y = F64.mul(k, iv_hi(a))
  IV{F64.min(x, y), F64.max(x, y)}

def iv_sq(+a: IV) -> IV:
  +x = F64.mul(iv_lo(a), iv_lo(a))
  +y = F64.mul(iv_hi(a), iv_hi(a))
  +z = Bool.and(F64.is_le(iv_lo(a), 0.0f64), F64.is_le(0.0f64, iv_hi(a)))
  IV{Bool.pick(F64, z, 0.0f64, F64.min(x, y)), F64.max(x, y)}

def iv_mag(+a: IV) -> F64:
  F64.max(F64.abs(iv_lo(a)), F64.abs(iv_hi(a)))

def iv_pos(+a: IV) -> IV:
  IV{F64.max(0.0f64, iv_lo(a)), F64.max(0.0f64, iv_hi(a))}

def iv_out(+a: IV, +t: F64) -> Bool:
  Bool.or(F64.is_lt(t, iv_lo(a)), F64.is_lt(iv_hi(a), F64.neg(t)))

def fv_dd(+v: FV) -> IV:
  FV{+dd, h, rho} = v
  dd

def fv_h(+v: FV) -> IV:
  FV{dd, +h, rho} = v
  h

def fv_rho(+v: FV) -> IV:
  FV{dd, h, +rho} = v
  rho

def fv_go(+dx: IV, +dy: IV, +dz: IV, +a: V.Dir) -> FV:
  +dd = iv_add(iv_sq(dx), iv_add(iv_sq(dy), iv_sq(dz)))
  +h = iv_add(iv_scl(S.dx(a), dx), iv_add(iv_scl(S.dy(a), dy), iv_scl(S.dz(a), dz)))
  FV{dd, h, iv_pos(iv_sub(dd, iv_sq(h)))}

def fv_of(+s: S.SF, +x: FB.BB) -> FV:
  FB.BB{+x0, +x1, +y0, +y1, +z0, +z1} = x
  +o = S.sf_o(s)
  fv_go(IV{F64.sub(x0, V.pt_x(o)), F64.sub(x1, V.pt_x(o))}, IV{F64.sub(y0, V.pt_y(o)), F64.sub(y1, V.pt_y(o))},
    IV{F64.sub(z0, V.pt_z(o)), F64.sub(z1, V.pt_z(o))}, S.sf_a(s))

def tor_q(+v: FV, +r: F64, +r2: F64) -> IV:
  +c = F64.sub(F64.mul(r, r), F64.mul(r2, r2))
  iv_add(fv_dd(v), IV{c, c})

def tor_far(+v: FV, +r: F64, +r2: F64, +t: F64) -> Bool:
  +q = tor_q(v, r, r2)
  +w = F64.mul(4.0f64, F64.mul(r, r))
  +mag = F64.add(1.0f64, F64.add(F64.mul(iv_mag(q), iv_mag(q)), F64.mul(w, iv_mag(fv_rho(v)))))
  iv_out(iv_sub(iv_sq(q), iv_scl(w, fv_rho(v))), F64.add(t, F64.mul(1.0e-9f64, mag)))

def quad_far(+f: IV, +v: FV, +r: F64, +t: F64) -> Bool:
  +mag = F64.add(1.0f64, F64.add(iv_mag(fv_dd(v)), F64.mul(F64.mul(r, r), F64.add(1.0f64, iv_mag(iv_sq(fv_h(v)))))))
  iv_out(f, F64.add(t, F64.mul(1.0e-9f64, mag)))

def far_k(+k: U64, +v: FV, +r: F64, +r2: F64, +t: F64) -> Bool:
  match k:
    case 1u64: quad_far(fv_h(v), v, r, t)
    case 2u64: quad_far(iv_sub(fv_rho(v), IV{F64.mul(r, r), F64.mul(r, r)}), v, r, t)
    case 3u64: quad_far(iv_sub(fv_rho(v), iv_scl(F64.mul(r, r), iv_sq(fv_h(v)))), v, r, t)
    case 4u64: quad_far(iv_sub(fv_dd(v), IV{F64.mul(r, r), F64.mul(r, r)}), v, r, t)
    case 5u64: tor_far(v, r, r2, t)
    case _: False{}

def far_f(+s: S.SF, +x: FB.BB) -> Bool:
  match s:
    case S.SF_bp{gw}: FB.bb_dis(FB.bb_pad(FB.cnet_bb(S.gbp(gw)), BI.bp_tol(S.gbp(gw))), x)
    case _: far_k(S.sf_kind(s), fv_of(s, x), S.sf_r(s), S.sf_r2(s), EF.near_tol(s))

def ej_far(far: Bool, +b: FB.KB, +e: Nat, +k: Ty.EdgeKind, +g: G.GVal) -> EF.EHS:
  match far:
    case True{}: EF.EHS{[], False{}, EF.ek_lo(k)}
    case False{}: EF.edge_hits(k, S.sf_of(g), g <> surfs_of(FB.edge_faces(b, e), b))

def ej_r(inp: Bool, +b: FB.KB, +e: Nat, +k: Ty.EdgeKind, +g: G.GVal) -> EF.EHS:
  match inp:
    case True{}: EF.EHS{[], False{}, 0.0f64}
    case False{}: ej_far(far_f(S.sf_of(g), edge_box(b, e)), b, e, k, g)

def ej_one(+b: FB.KB, +ob: FB.KB, +e: Nat, +fo: Nat) -> EJ:
  +k = Ty.ed_kind(FB.edge_at(b, e))
  +g = FB.face_surf(ob, fo)
  +inp = Bool.or(in_plane(k, S.sf_of(g)), on_cyl(k, S.sf_of(g)))
  EJ{e, fo, inp, ej_r(inp, b, e, k, g)}

def ej_job(c: EX, p: EP) -> EJ:
  EX{+b, +ob} = c
  EP{+e, +fo} = p
  ej_one(b, ob, e, fo)

def ej_hits(+inp: Bool, +r: EF.EHS, +side: U64, +e: Nat, +b: FB.KB, +ob: FB.KB, +fo: Nat, +st: HS) -> HS:
  match inp:
    case True{}: st
    case False{}:
      +k = Ty.ed_kind(FB.edge_at(b, e))
      +st2 = eh_keep(EF.ehs_hs(r), side, e, fo, ob, b, EF.ek_lo(k), EF.ek_hi(k), st)
      +near = near_on(EF.ehs_near(r), ob, fo, EF.ev(EF.ek_curve(k), EF.ehs_nt(r)))
      Bool.pick(HS, near_bad(near, k, EF.ehs_nt(r), ob), HS{hs_hs(st2), hs_g(st2), False{}, why_near()}, st2)

def ej_fold(js: List<&2, EJ>, +side: U64, +b: FB.KB, +ob: FB.KB, +st: HS) -> HS:
  match js:
    case []: st
    case +j <> +t:
      EJ{+e, +fo, +inp, +r} = j
      ej_fold(t, side, b, ob, ej_hits(inp, r, side, e, b, ob, fo, st))

def ef_edges(es: List<&2, Nat>, +side: U64, +b: FB.KB, +ob: FB.KB, +st: HS) -> HS:
  +ps = ep_all(es, b, fbs_of(FB.nfaces(ob), ob, []))
  ej_fold(B.pmap_g(~EP, ~EX, ~EJ, ~ej_job, 1, EX{b, ob}, ps), side, b, ob, st)

def ve_fos(fs: List<&2, Nat>, +side: U64, +e: Nat, +t: F64, +p: V.Point, +v: Nat, +acc: List<&2, HX>) -> List<&2, HX>:
  match fs:
    case []: acc
    case +h <> +t2: ve_fos(t2, side, e, t, p, v, HX{side, e, t, p, v, h} <> acc)

def vx_faces(es: List<&2, Nat>, +ob: FB.KB, +vi: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match es:
    case []: acc
    case +h <> +t:
      +ed = FB.edge_at(ob, h)
      +inc = Bool.or(Nat.is_eq(Ty.hv_idx(Ty.ed_v0(ed)), vi), Nat.is_eq(Ty.hv_idx(Ty.ed_v1(ed)), vi))
      vx_faces(t, ob, vi, Bool.pick(List<&2, Nat>, inc, List.append(&2, Nat, FB.edge_faces(ob, h), acc), acc))

def ve_two(+go: Bool, +side: U64, +e: Nat, +k: Ty.EdgeKind, +b: FB.KB, +ob: FB.KB, +vi: Nat, +p: V.Point, +st: HS) -> HS:
  match go:
    case False{}: st
    case True{}:
      +t = ve_param(k, p)
      +on = F64.is_lt(S.dist(EF.ev(EF.ek_curve(k), t), p), ve_tol(p))
      +r = gv_add(hs_g(st), p)
      +fs = vx_faces(L.nat_range(FB.nedges(ob)), ob, vi, [])
      Bool.pick(HS, on, HS{ve_fos(fs, side, e, t, p, vi_i(r), hs_hs(st)), vi_g(r), hs_ok(st), hs_why(st)}, st)

def vd_job(+b: FB.KB, +e: Nat) -> VD:
  +ed = FB.edge_at(b, e)
  +k = Ty.ed_kind(ed)
  VD{e, k, FB.ek_bb(k), FB.vpt(b, Ty.ed_v0(ed)), FB.vpt(b, Ty.ed_v1(ed))}

def vd_x(b: FB.KB, e: Nat) -> VD:
  vd_job(b, e)

def vd_go(+d: VD, +p: V.Point, +tol: F64) -> Bool:
  VD{+e, +k, +bx, +q0, +q1} = d
  Bool.and(Bool.not(FB.bb_dis(FB.bb_pad(bx, tol), FB.bb_pt(p))),
    Bool.and(F64.is_lt(tol, S.dist(p, q0)), F64.is_lt(tol, S.dist(p, q1))))

def vd_e(+d: VD) -> Nat:
  VD{+e, k, bx, q0, q1} = d
  e

def vd_es(ds: List<&2, VD>, +p: V.Point, +tol: F64) -> List<&2, Nat>:
  match ds:
    case []: []
    case +d <> t:
      +rest = vd_es(t, p, tol)
      Bool.pick(List<&2, Nat>, vd_go(d, p, tol), vd_e(d) <> rest, rest)

def vc_job(+c: VX, +h: Nat) -> VC:
  VX{+ob, +ds} = c
  +p = Ty.vx_p(FB.kb_v(ob, h))
  VC{h, p, vd_es(ds, p, ve_tol(p))}

def vc_x(c: VX, h: Nat) -> VC:
  vc_job(c, h)

def ve_hit(es: List<&2, Nat>, +side: U64, +b: FB.KB, +ob: FB.KB, +vi: Nat, +p: V.Point, +st: HS) -> HS:
  match es:
    case []: st
    case +e <> +t: ve_hit(t, side, b, ob, vi, p, ve_two(True{}, side, e, Ty.ed_kind(FB.edge_at(b, e)), b, ob, vi, p, st))

def vc_fold(cs: List<&2, VC>, +side: U64, +b: FB.KB, +ob: FB.KB, +st: HS) -> HS:
  match cs:
    case []: st
    case +c <> +t:
      VC{+v, +p, +es} = c
      vc_fold(t, side, b, ob, ve_hit(es, side, b, ob, v, p, st))

def ve_verts(+vs: List<&2, Nat>, +side: U64, +b: FB.KB, +ob: FB.KB, +st: HS) -> HS:
  +ds = B.pmap_g(~Nat, ~FB.KB, ~VD, ~vd_x, 8, b, L.nat_range(FB.nedges(b)))
  vc_fold(B.pmap_g(~Nat, ~VX, ~VC, ~vc_x, 1, VX{ob, ds}, vs), side, b, ob, st)

def all_hits(+ba: FB.KB, +bb: FB.KB, +g: GV) -> HS:
  +s0 = ef_edges(L.nat_range(FB.nedges(ba)), 0u64, ba, bb, HS{[], g, True{}, 0u64})
  +s1 = ef_edges(L.nat_range(FB.nedges(bb)), 1u64, bb, ba, s0)
  +s2 = ve_verts(L.nat_range(FB.kb_nv(bb)), 0u64, ba, bb, s1)
  ve_verts(L.nat_range(FB.kb_nv(ba)), 1u64, bb, ba, s2)

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

def face_es(+b: FB.KB, +fi: Nat) -> List<&2, Nat>:
  flat_ces(FB.face_ce(b, fi))

def pair_hits(hs: List<&2, HX>, +esa: List<&2, Nat>, +fa: Nat, +esb: List<&2, Nat>, +fb: Nat)
    -> List<&2, HX>:
  match hs:
    case []: []
    case +h <> +t:
      +rest = pair_hits(t, esa, fa, esb, fb)
      Bool.pick(List<&2, HX>, Bool.or(is_hit_of(h, 0u64, esa, fb), is_hit_of(h, 1u64, esb, fa)), h <> rest, rest)

def no_face() -> Nat:
  4294967295n

def cop_bnd(+n: Bool, +b: FB.KB, +g: G.GVal, +p: V.Point) -> Bool:
  match n:
    case False{}: False{}
    case True{}: any_coplanar(L.nat_range(FB.nfaces(b)), b, g, p)

def run_side(+ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat, +p: V.Point) -> U64:
  +na = FB.bnd_near(ba, fa, p)
  +nb = FB.bnd_near(bb, fb, p)
  +ca = cop_bnd(na, ba, FB.face_surf(bb, fb), p)
  +cb = cop_bnd(nb, bb, FB.face_surf(ba, fa), p)
  +ia = Bool.or(FB.pt_in_face(ba, fa, p), Bool.and(na, Bool.not(ca)))
  +ib = Bool.or(FB.pt_in_face(bb, fb, p), Bool.and(nb, Bool.not(cb)))
  Bool.pick(U64, Bool.not(Bool.and(ia, ib)), 0u64,
    Bool.pick(U64, Bool.and(na, nb), 0u64, Bool.pick(U64, na, Bool.pick(U64, ca, 0u64, 2u64), Bool.pick(U64, nb, Bool.pick(U64, cb, 0u64, 3u64), 1u64))))

def ch_mask(+c: CH, +sd: U64) -> CH:
  CH{+fa, +fb, +ss, +ps, +cl, +dv} = c
  CH{Bool.pick(Nat, U64.is_eq(sd, 2u64), no_face(), fa), Bool.pick(Nat, U64.is_eq(sd, 3u64), no_face(), fb), ss, ps, cl, dv}

def chs_mask(cs: List<&2, CH>, +sd: U64) -> List<&2, CH>:
  match cs:
    case []: []
    case +h <> +t: ch_mask(h, sd) <> chs_mask(t, sd)

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

def line_spans(bs: List<&2, BP>, +p0: V.Point, +d: V.Dir, +ba: FB.KB, +fa: Nat, +bb: FB.KB,
    +fb: Nat, +r: CR) -> CR:
  match bs:
    case []: r
    case +h <> +t:
      +h2 = L_bp0(t, h)
      +more = Bool.not(Nat.is_eq(List.length(&2, BP, t), 0n))
      +mid = S.padd(p0, F64.mul(0.5f64, F64.add(bp_s(h), bp_s(h2))), d)
      +sd = run_side(ba, fa, bb, fb, mid)
      +keep = Bool.and(more, Bool.not(U64.is_eq(sd, 0u64)))
      line_spans(t, p0, d, ba, fa, bb, fb,
        Bool.pick(CR, keep, CR{ch_mask(mk_lnch(fa, fb, h, h2), sd) <> cr_chs(r), cr_g(r), cr_ok(r), cr_why(r)}, r))

def do_line(+c: SS.IC, +hs: List<&2, HX>, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat, +r: CR) -> CR:
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
      +ct = EF.cert_gs(gs, circ_at(cc1(ccl), phi))
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
    +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat, +r: CR) -> CR:
  match bs:
    case []: r
    case +h <> +t:
      +nx = L_bp0(t, first)
      +phib = Bool.pick(F64, Nat.is_eq(List.length(&2, BP, t), 0n), F64.add(bp_s(first), S.two_pi()), bp_s(nx))
      +mid = circ_at(cc1(ccl), F64.mul(0.5f64, F64.add(bp_s(h), phib)))
      +sd = run_side(ba, fa, bb, fb, mid)
      +keep = Bool.not(U64.is_eq(sd, 0u64))
      +ar = arc_chain(ccl, gs, h, phib, nx, cr_g(r), fa, fb)
      +r2 = Bool.pick(CR, keep,
        CR{List.append(&2, CH, chs_mask(cr_chs(ar), sd), cr_chs(r)), cr_g(ar), Bool.and(cr_ok(r), cr_ok(ar)),
          Bool.pick(U64, cr_ok(r), cr_why(ar), cr_why(r))}, r)
      circ_spans(t, first, ccl, gs, ba, fa, bb, fb, r2)

def mk_fullch(+fa: Nat, +fb: Nat, +v: Nat, +c: G.GVal, +p: V.Point) -> CH:
  CH{fa, fb, [SEG{v, v, Ty.EK_curve{c, G.Dom{F64.neg(1.0f64), 1.0f64}}}], [p, p], True{}, 0.0f64}

def do_circ_full(+cc: G.Circle3, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat, +r: CR) -> CR:
  +p = EF.ev(G.GV_cc{cc}, F64.neg(1.0f64))
  +vr = gv_add(cr_g(r), p)
  +sd = run_side(ba, fa, bb, fb, EF.ev(G.GV_cc{cc}, 0.0f64))
  Bool.pick(CR, Bool.not(U64.is_eq(sd, 0u64)), CR{ch_mask(mk_fullch(fa, fb, vi_i(vr), G.GV_cc{cc}, p), sd) <> cr_chs(r), vi_g(vr), cr_ok(r), cr_why(r)}, r)

def do_circ_go(+full: Bool, +ccl: List<&2, G.Circle3>, +gs: List<&2, G.GVal>, +bs: List<&2, BP>,
    +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat, +r: CR) -> CR:
  match full:
    case True{}: do_circ_full(cc1(ccl), ba, fa, bb, fb, r)
    case False{}: circ_spans(bs, L_bp0(bs, BP{0.0f64, 0n, S.pt(0.0f64, 0.0f64, 0.0f64)}), ccl, gs, ba, fa, bb, fb, r)

def cc_of(+g: G.GVal) -> G.Circle3:
  match g:
    case G.GV_cc{w}: w
    case _: G.Cc{S.pt(0.0f64, 0.0f64, 0.0f64), S.dr(1.0f64, 0.0f64, 0.0f64), S.dr(0.0f64, 1.0f64, 0.0f64), 1.0f64}

def do_circ(+c: SS.IC, +hs: List<&2, HX>, +g1: G.GVal, +g2: G.GVal, +ba: FB.KB, +fa: Nat,
    +bb: FB.KB, +fb: Nat, +r: CR) -> CR:
  +ccl = {[cc_of(SS.ic_curve(c))] : List<&2, G.Circle3>}
  +bs = dedup_bp(bp_sort(bps_circ(hs, cc1(ccl))))
  do_circ_go(Nat.is_eq(List.length(&2, BP, bs), 0n), ccl, [g1, g2], bs, ba, fa, bb, fb, r)

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

def seg_d(+a: V.Point, +b: V.Point, +p: V.Point) -> F64:
  +ab = S.psub(b, a)
  +l2 = S.dot(ab, ab)
  +t = F64.max(0.0f64, F64.min(1.0f64, F64.div(S.dot(S.psub(p, a), ab), F64.max(l2, 1.0e-300f64))))
  S.dist(p, S.padd(a, t, ab))

def near_sd(ps: List<&2, V.Point>, +p: V.Point, +prev: V.Point, +i: Nat, +best: Nat, +bd: F64) -> NB2:
  match ps:
    case []: NB2{best, bd}
    case +h <> +t:
      +d = seg_d(prev, h, p)
      near_sd(t, p, h, Nat.add(i, 1n), Bool.pick(Nat, F64.is_lt(d, bd), i, best), F64.min(d, bd))

def brk_at(xs: List<&2, PP>, +i: Nat) -> Bool:
  match xs:
    case []: False{}
    case +h <> t:
      match i:
        case 0n: pp_brk(h)
        case 1n+j: brk_at(t, j)

def ins_brk_c(hs: List<&2, HX>, +closed: Bool, +xs: List<&2, PP>) -> List<&2, PP>:
  match hs:
    case []: xs
    case +h <> +t:
      +ps = pps_pts(xs)
      +cl = Bool.pick(List<&2, V.Point>, closed, List.append(&2, V.Point, L_tail(ps), [L.nth_p(ps, 0n)]), L_tail(ps))
      +sd = near_sd(cl, hx_p(h), L.nth_p(ps, 0n), 0n, 0n, F64.div(1.0f64, 0.0f64))
      +i = nb2_i(sd)
      +sl = S.dist(L.nth_p(ps, i), L.nth_p(cl, i))
      +np = near_pt(xs, hx_p(h), 0n, 0n, F64.div(1.0f64, 0.0f64))
      +on = F64.is_le(nb2_d(sd), F64.add(F64.mul(0.25f64, sl), 1.0e-9f64))
      +same = Bool.or(F64.is_lt(nb2_d(np), 1.0e-9f64), Bool.and(Bool.not(closed), Bool.and(F64.is_lt(nb2_d(np), F64.mul(0.05f64, sl)), Bool.not(brk_at(xs, nb2_i(np))))))
      +bp = {PP{hx_p(h), hx_v(h), True{}} : PP}
      ins_brk_c(t, closed, Bool.pick(List<&2, PP>, same, set_at(xs, nb2_i(np), bp),
        Bool.pick(List<&2, PP>, on, ins_at(xs, i, bp), xs)))

def ins_brk(hs: List<&2, HX>, +xs: List<&2, PP>) -> List<&2, PP>:
  ins_brk_c(hs, True{}, xs)

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
      reg_pts(t, vi_g(r), PP{gv_pt(vi_g(r), vi_i(r)), vi_i(r), False{}} <> acc)

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

def herm_alpha(+s1: S.SF, +s2: S.SF, +a: V.Point, +b: V.Point, +ta: V.Dir, +tb: V.Dir, +l: F64) -> F64:
  +mid = S.padd(a, 0.5f64, S.psub(b, a))
  +m = S.newton2(8n, s1, s2, mid, S.dunit(S.psub(b, a)), mid)
  +dt = S.dadd(ta, F64.neg(1.0f64), tb)
  +q = S.dot(dt, dt)
  +al = F64.div(F64.mul(8.0f64, S.dot(S.psub(m, mid), dt)), F64.mul(3.0f64, q))
  +ok = Bool.and(F64.is_lt(F64.mul(1.0e-12f64, F64.mul(l, l)), F64.mul(q, F64.mul(l, l))),
    Bool.and(F64.is_lt(F64.mul(0.2f64, l), al), F64.is_lt(al, F64.mul(0.6f64, l))))
  Bool.pick(F64, ok, al, F64.div(l, 3.0f64))

def herm_kind(+s1: S.SF, +s2: S.SF, +a: V.Point, +b: V.Point) -> Ty.EdgeKind:
  +ch = S.psub(b, a)
  +l = S.dlen(ch)
  +ta = tan_at(s1, s2, a, ch)
  +tb = tan_at(s1, s2, b, ch)
  +al = herm_alpha(s1, s2, a, b, ta, tb, l)
  Ty.EK_curve{G.GV_bz{G.Bz{a, S.padd(a, al, ta), S.padd(b, F64.neg(al), tb), b}},
    G.Dom{0.0f64, 1.0f64}}

def segs_of(xs: List<&2, PP>, +s1: S.SF, +s2: S.SF) -> List<&2, SEG>:
  match xs:
    case []: []
    case +h <> +t:
      +h2 = L_pp0(t)
      +rest = segs_of(t, s1, s2)
      Bool.pick(List<&2, SEG>, Nat.is_eq(List.length(&2, PP, t), 0n), [],
        SEG{pp_v(h), pp_v(h2), herm_kind(s1, s2, pp_p(h), pp_p(h2))} <> rest)

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
      +cut = Bool.and(pp_brk(h), Bool.or(Nat.is_lt(1n, List.length(&2, PP, cur)), Bool.and(Nat.is_eq(List.length(&2, PP, cur), 1n), Bool.not(Nat.is_eq(pp_v(h), pp_v(L_pp0(cur)))))))
      poly_split(t, Bool.pick(List<&2, PP>, cut, [h], h <> cur),
        Bool.pick(List<&2, List<&2, PP>>, cut, List.reverse(&2, PP, h <> cur) <> acc, acc))

def poly_split_o(xs: List<&2, PP>, +cur: List<&2, PP>, +acc: List<&2, List<&2, PP>>)
    -> List<&2, List<&2, PP>>:
  match xs:
    case []: List.reverse(&2, List<&2, PP>, acc)
    case +h <> +t:
      +cut = Bool.and(pp_brk(h), Nat.is_lt(0n, List.length(&2, PP, cur)))
      poly_split_o(t, Bool.pick(List<&2, PP>, cut, [h], h <> cur),
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

def run_dev(+ss: List<&2, SEG>, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat) -> F64:
  +s1 = S.sf_of(FB.face_surf(ba, fa))
  +s2 = S.sf_of(FB.face_surf(bb, fb))
  F64.add(F64.mul(2.0f64, segs_dev(ss, s1, s2, 0.0f64)), 1.0e-12f64)

def dec_eps(+p: V.Point) -> F64:
  F64.mul(1.0e-6f64, F64.add(1.0f64, F64.max(F64.abs(S.px(p)), F64.max(F64.abs(S.py(p)), F64.abs(S.pz(p))))))

def dec_go(xs: List<&2, PP>, +s1: S.SF, +s2: S.SF, +cap: F64, +a: PP, +last: PP, +n: Nat, +out: List<&2, PP>) -> List<&2, PP>:
  match xs:
    case []: List.reverse(&2, PP, last <> out)
    case +q <> t:
      +fit = F64.is_le(seg_dev(s1, s2, herm_kind(s1, s2, pp_p(a), pp_p(q))), F64.min(cap, dec_eps(pp_p(a))))
      +ok = Bool.and(Bool.not(pp_brk(last)), Bool.and(Nat.is_lt(n, 96n), fit))
      dec_go(t, s1, s2, cap, Bool.pick(PP, ok, a, last), q, Bool.pick(Nat, ok, Nat.add(n, 1n), 1n),
        Bool.pick(List<&2, PP>, ok, out, last <> out))

def dec_c(xs: List<&2, PP>, +s1: S.SF, +s2: S.SF, +cap: F64) -> List<&2, PP>:
  match xs:
    case []: []
    case +x0 <> t:
      match t:
        case []: [x0]
        case +x1 <> t2: dec_go(t2, s1, s2, cap, x0, x1, 1n, [x0])

def dec_pp(+xs: List<&2, PP>, +s1: S.SF, +s2: S.SF) -> List<&2, PP>:
  dec_c(xs, s1, s2, segs_dev(segs_of(xs, s1, s2), s1, s2, 0.0f64))

def dec_if(bp: Bool, +h: List<&2, PP>, +s1: S.SF, +s2: S.SF) -> List<&2, PP>:
  match bp:
    case True{}: dec_pp(h, s1, s2)
    case False{}: h

def mk_pch(+fa: Nat, +fb: Nat, +h0: List<&2, PP>, +closed: Bool, +ba: FB.KB, +bb: FB.KB) -> CH:
  +s1 = S.sf_of(FB.face_surf(ba, fa))
  +s2 = S.sf_of(FB.face_surf(bb, fb))
  +h = dec_if(Bool.or(S.is_bp(s1), S.is_bp(s2)), h0, s1, s2)
  +ss = segs_of(h, s1, s2)
  CH{fa, fb, ss, pps_pts(h), closed, run_dev(ss, ba, fa, bb, fb)}

def run_keep(out: Bool, +sd: U64, +fa: Nat, +fb: Nat, +h: List<&2, PP>, +closed: Bool, +ba: FB.KB, +bb: FB.KB,
    +acc: List<&2, CH>) -> List<&2, CH>:
  match out:
    case True{}: acc
    case False{}: ch_mask(mk_pch(fa, fb, h, closed, ba, bb), sd) <> acc

def keep_runs(rs: List<&2, List<&2, PP>>, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat,
    +acc: List<&2, CH>) -> List<&2, CH>:
  match rs:
    case []: acc
    case +h <> +t:
      +sd = run_side(ba, fa, bb, fb, mid_pp(h))
      keep_runs(t, ba, fa, bb, fb, run_keep(U64.is_eq(sd, 0u64), sd, fa, fb, h, False{}, ba, bb, acc))

def has_brk(xs: List<&2, PP>) -> Bool:
  match xs:
    case []: False{}
    case +h <> +t: Bool.or(pp_brk(h), has_brk(t))

def do_poly_go(+brk: Bool, +xs: List<&2, PP>, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat,
    +r: CR, +g: GV) -> CR:
  match brk:
    case True{}:
      +rot = rot_to_brk(xs, [])
      +cyc = List.append(&2, PP, rot, [L_pp0(rot)])
      CR{List.append(&2, CH, keep_runs(poly_split(cyc, [], []), ba, fa, bb, fb, []), cr_chs(r)), g,
        cr_ok(r), cr_why(r)}
    case False{}:
      +cyc = List.append(&2, PP, xs, [L_pp0(xs)])
      +sd = run_side(ba, fa, bb, fb, mid_pp(xs))
      CR{run_keep(U64.is_eq(sd, 0u64), sd, fa, fb, cyc, True{}, ba, bb, cr_chs(r)), g, cr_ok(r), cr_why(r)}

def do_open(+xs: List<&2, PP>, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat, +r: CR, +g: GV) -> CR:
  CR{List.append(&2, CH, keep_runs(poly_split_o(xs, [], []), ba, fa, bb, fb, []), cr_chs(r)), g, cr_ok(r), cr_why(r)}

def do_poly_c(cl: Bool, +xs: List<&2, PP>, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat, +r: CR, +g: GV) -> CR:
  match cl:
    case True{}: do_poly_go(has_brk(xs), xs, ba, fa, bb, fb, r, g)
    case False{}: do_open(xs, ba, fa, bb, fb, r, g)

def do_poly(+c: SS.IC, +hs: List<&2, HX>, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat, +r: CR) -> CR:
  +pv = reg_pts(SS.ic_pts(c), cr_g(r), [])
  +xs = ins_brk_c(hs, SS.ic_closed(c), pv_xs(pv))
  do_poly_c(SS.ic_closed(c), xs, ba, fa, bb, fb, r, pv_g(pv))

def do_ic(+k: U64, +c: SS.IC, +hs: List<&2, HX>, +g1: G.GVal, +g2: G.GVal, +ba: FB.KB, +fa: Nat,
    +bb: FB.KB, +fb: Nat, +r: CR) -> CR:
  match k:
    case 1u64: do_line(c, hs, ba, fa, bb, fb, r)
    case 2u64: do_circ(c, hs, g1, g2, ba, fa, bb, fb, r)
    case 3u64: do_poly(c, hs, ba, fa, bb, fb, r)
    case 4u64: r
    case 6u64: r
    case _: cr_fail(r, 86u64)

def ics_go(cs: List<&2, SS.IC>, +hs: List<&2, HX>, +g1: G.GVal, +g2: G.GVal, +ba: FB.KB,
    +fa: Nat, +bb: FB.KB, +fb: Nat, +r: CR) -> CR:
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

def ax_d(+s: S.SF, +p: V.Point) -> F64:
  +d = S.psub(p, S.sf_o(s))
  S.dlen(Bool.pick(V.Dir, S.is_sph(s), d, S.dadd(d, F64.neg(S.dot(d, S.sf_a(s))), S.sf_a(s))))

def bb_far(+s: S.SF, +x: FB.BB) -> F64:
  FB.BB{+x0, +x1, +y0, +y1, +z0, +z1} = x
  F64.max(F64.max(F64.max(ax_d(s, S.pt(x0, y0, z0)), ax_d(s, S.pt(x1, y0, z0))), F64.max(ax_d(s, S.pt(x0, y1, z0)), ax_d(s, S.pt(x1, y1, z0)))),
    F64.max(F64.max(ax_d(s, S.pt(x0, y0, z1)), ax_d(s, S.pt(x1, y0, z1))), F64.max(ax_d(s, S.pt(x0, y1, z1)), ax_d(s, S.pt(x1, y1, z1)))))

def bb_near(+s: S.SF, +x: FB.BB) -> F64:
  FB.BB{+x0, +x1, +y0, +y1, +z0, +z1} = x
  +c = S.pt(F64.mul(0.5f64, F64.add(x0, x1)), F64.mul(0.5f64, F64.add(y0, y1)), F64.mul(0.5f64, F64.add(z0, z1)))
  F64.sub(ax_d(s, c), F64.mul(0.5f64, S.dist(S.pt(x0, y0, z0), S.pt(x1, y1, z1))))

def q_sep(+x: FB.BB, +s: S.SF) -> Bool:
  +r = S.sf_r(s)
  +q = Bool.or(U64.is_eq(S.sf_kind(s), S.k_cyl()), S.is_sph(s))
  +e = F64.mul(1.0e-9f64, F64.add(1.0f64, r))
  Bool.and(q, Bool.or(F64.is_lt(bb_far(s, x), F64.sub(r, e)), F64.is_lt(F64.add(r, e), bb_near(s, x))))

def rho_u(+s: S.SF, +u: F64) -> V.Dir:
  S.dadd(S.dscale(S.fcos(u), S.sf_e1(s)), S.fsin(u), S.sf_e2(s))

def u_rng(ps: List<&2, V.Vec2>, +acc: V.Vec2) -> V.Vec2:
  match ps:
    case []: acc
    case +q <> +t: u_rng(t, V.V2{F64.min(V.v2_x(acc), V.v2_x(q)), F64.max(V.v2_y(acc), V.v2_x(q))})

def u_rngs(ls: List<&2, List<&2, V.Vec2>>, +acc: V.Vec2) -> V.Vec2:
  match ls:
    case []: acc
    case +h <> +t: u_rngs(t, u_rng(h, acc))

def v_rng(ps: List<&2, V.Vec2>, +acc: V.Vec2) -> V.Vec2:
  match ps:
    case []: acc
    case +q <> +t: v_rng(t, V.V2{F64.min(V.v2_x(acc), V.v2_y(q)), F64.max(V.v2_y(acc), V.v2_y(q))})

def v_rngs(ls: List<&2, List<&2, V.Vec2>>, +acc: V.Vec2) -> V.Vec2:
  match ls:
    case []: acc
    case +h <> +t: v_rngs(t, v_rng(h, acc))

def tor_rho(+s: S.SF, +vr: V.Vec2) -> V.Vec2:
  +a = F64.add(V.v2_x(vr), S.sf_t0(s))
  +b = F64.add(V.v2_y(vr), S.sf_t0(s))
  +ch = F64.sub(S.fcos(F64.mul(0.5f64, F64.sub(b, a))), 1.0e-12f64)
  +cm = S.fcos(F64.mul(0.5f64, F64.add(a, b)))
  +ca = S.fcos(a)
  +cb = S.fcos(b)
  +full = Bool.or(F64.is_lt(b, a), F64.is_lt(S.pi(), F64.sub(b, a)))
  +cmax = Bool.pick(F64, Bool.or(full, F64.is_le(ch, cm)), 1.0f64, F64.max(ca, cb))
  +cmin = Bool.pick(F64, Bool.or(full, F64.is_le(ch, F64.neg(cm))), F64.neg(1.0f64), F64.min(ca, cb))
  V.V2{F64.add(S.sf_r(s), F64.mul(S.sf_r2(s), cmin)), F64.add(S.sf_r(s), F64.mul(S.sf_r2(s), cmax))}

def inward(+n: V.Dir, +m: V.Dir) -> V.Dir:
  Bool.pick(V.Dir, F64.is_lt(0.0f64, S.dot(n, m)), n, S.dscale(F64.neg(1.0f64), n))

def sub_poly(+s: S.SF, +o: V.Point, +ua: F64, +ub: F64, +ri: F64, +ro: F64) -> List<&2, V.Point>:
  +h = F64.mul(0.5f64, F64.sub(ub, ua))
  +rq = F64.mul(ro, F64.add(1.0f64, 1.0e-9f64))
  +rin = F64.mul(F64.max(ri, 0.0f64), F64.sub(1.0f64, 1.0e-9f64))
  [S.padd(o, rin, rho_u(s, ua)), S.padd(o, rq, rho_u(s, ua)), S.padd(o, F64.div(rq, S.fcos(h)), rho_u(s, F64.add(ua, h))),
    S.padd(o, rq, rho_u(s, ub)), S.padd(o, rin, rho_u(s, ub))]

def sect_polys(n: Nat, +s: S.SF, +o: V.Point, +u0: F64, +du: F64, +k: F64, +ri: F64, +ro: F64) -> List<&2, List<&2, V.Point>>:
  match n:
    case 0n: []
    case 1n+(+m):
      +ua = F64.add(u0, F64.mul(k, du))
      sub_poly(s, o, ua, F64.add(ua, du), ri, ro) <> sect_polys(m, s, o, u0, du, F64.add(k, 1.0f64), ri, ro)

def rho_tor(tor: Bool, +s: S.SF, +b: FB.KB, +fi: Nat) -> V.Vec2:
  match tor:
    case True{}:
      +big = {1.0e300f64 : F64}
      tor_rho(s, v_rngs(FB.face_polys(b, fi), V.V2{big, F64.neg(big)}))
    case False{}: V.V2{S.sf_r(s), S.sf_r(s)}

def wd_go(ok: Bool, +s: S.SF, +b: FB.KB, +fi: Nat) -> WD:
  match ok:
    case False{}: WD{False{}, S.pt(0.0f64, 0.0f64, 0.0f64), S.dr(0.0f64, 0.0f64, 1.0f64), S.dr(0.0f64, 0.0f64, 1.0f64), S.dr(0.0f64, 0.0f64, 1.0f64), []}
    case True{}:
      +big = {1.0e300f64 : F64}
      +ur = u_rngs(FB.face_polys(b, fi), V.V2{big, F64.neg(big)})
      +u0 = V.v2_x(ur)
      +u1 = V.v2_y(ur)
      +a = S.sf_a(s)
      +m = rho_u(s, F64.mul(0.5f64, F64.add(u0, u1)))
      +ok = F64.is_lt(F64.sub(u1, u0), F64.sub(3.141592653589793f64, 1.0e-3f64))
      +rho = rho_tor(S.is_tor(s), s, b, fi)
      +ro = V.v2_y(rho)
      +ri = V.v2_x(rho)
      WD{ok, S.sf_o(s), inward(S.cross(a, rho_u(s, u0)), m), inward(S.cross(a, rho_u(s, u1)), m), a,
        sect_polys(8n, s, S.sf_o(s), u0, F64.div(F64.sub(u1, u0), 8.0f64), 0.0f64, ri, ro)}

def wd_of(+b: FB.KB, +fi: Nat) -> WD:
  +s = FB.face_sf(b, fi)
  wd_go(Bool.or(U64.is_eq(S.sf_kind(s), S.k_cyl()), S.is_tor(s)), s, b, fi)

def all_out(+n: V.Dir, +o: V.Point, +x: FB.BB, +e: F64) -> Bool:
  FB.BB{+x0, +x1, +y0, +y1, +z0, +z1} = x
  +f = F64.neg(e)
  Bool.and(Bool.and(Bool.and(F64.is_lt(S.dot(n, S.psub(S.pt(x0, y0, z0), o)), f), F64.is_lt(S.dot(n, S.psub(S.pt(x1, y0, z0), o)), f)),
    Bool.and(F64.is_lt(S.dot(n, S.psub(S.pt(x0, y1, z0), o)), f), F64.is_lt(S.dot(n, S.psub(S.pt(x1, y1, z0), o)), f))),
    Bool.and(Bool.and(F64.is_lt(S.dot(n, S.psub(S.pt(x0, y0, z1), o)), f), F64.is_lt(S.dot(n, S.psub(S.pt(x1, y0, z1), o)), f)),
      Bool.and(F64.is_lt(S.dot(n, S.psub(S.pt(x0, y1, z1), o)), f), F64.is_lt(S.dot(n, S.psub(S.pt(x1, y1, z1), o)), f))))

def w_sep(+x: FB.BB, +w: WD) -> Bool:
  WD{+ok, +o, +n0, +n1, a, polys} = w
  +e = F64.mul(1.0e-9f64, F64.add(1.0f64, S.dist(o, S.pt(0.0f64, 0.0f64, 0.0f64))))
  Bool.and(ok, Bool.or(all_out(n0, o, x, e), all_out(n1, o, x, e)))

def proj_rng(ps: List<&2, V.Point>, +n: V.Dir, +lo: F64, +hi: F64) -> V.Vec2:
  match ps:
    case []: V.V2{lo, hi}
    case +p <> +t:
      +d = S.dot(n, S.psub(p, S.pt(0.0f64, 0.0f64, 0.0f64)))
      proj_rng(t, n, F64.min(lo, d), F64.max(hi, d))

def gap(+a: V.Vec2, +b: V.Vec2, +e: F64) -> Bool:
  Bool.or(F64.is_lt(F64.add(V.v2_y(a), e), V.v2_x(b)), F64.is_lt(F64.add(V.v2_y(b), e), V.v2_x(a)))

def L_hd_pt(xs: List<&2, V.Point>, +d: V.Point) -> V.Point:
  match xs:
    case []: d
    case +h <> +t: h

def axes_sep(es: List<&2, V.Point>, +first: V.Point, +ax: V.Dir, +pa: List<&2, V.Point>, +pb: List<&2, V.Point>, +e: F64) -> Bool:
  match es:
    case []: False{}
    case +p <> +t:
      +q = Bool.pick(V.Point, Nat.is_eq(List.length(&2, V.Point, t), 0n), first, L_hd_pt(t, first))
      +n = S.cross(ax, S.psub(q, p))
      +big = {1.0e300f64 : F64}
      Bool.or(gap(proj_rng(pa, n, big, F64.neg(big)), proj_rng(pb, n, big, F64.neg(big)), F64.mul(e, F64.add(1.0f64, S.dlen(n)))),
        axes_sep(t, first, ax, pa, pb, e))

def par_ax(+a: V.Dir, +b: V.Dir) -> Bool:
  F64.is_lt(F64.sub(1.0f64, F64.abs(S.dot(a, b))), 1.0e-12f64)

def poly_sep(+pa: List<&2, V.Point>, +pb: List<&2, V.Point>, +ax: V.Dir, +o: V.Point, +e: F64) -> Bool:
  Bool.or(axes_sep(pa, L_hd_pt(pa, o), ax, pa, pb, e), axes_sep(pb, L_hd_pt(pb, o), ax, pa, pb, e))

def all_b(qs: List<&2, List<&2, V.Point>>, +pa: List<&2, V.Point>, +ax: V.Dir, +o: V.Point, +e: F64) -> Bool:
  match qs:
    case []: True{}
    case +q <> +t: Bool.and(poly_sep(pa, q, ax, o, e), all_b(t, pa, ax, o, e))

def all_ab(ps: List<&2, List<&2, V.Point>>, +qs: List<&2, List<&2, V.Point>>, +ax: V.Dir, +o: V.Point, +e: F64) -> Bool:
  match ps:
    case []: True{}
    case +p <> +t: Bool.and(all_b(qs, p, ax, o, e), all_ab(t, qs, ax, o, e))

def far_ps(ps: List<&2, V.Point>, +s: S.SF, +acc: F64) -> F64:
  match ps:
    case []: acc
    case +p <> +t: far_ps(t, s, F64.max(acc, ax_d(s, p)))

def far_pss(ls: List<&2, List<&2, V.Point>>, +s: S.SF, +acc: F64) -> F64:
  match ls:
    case []: acc
    case +h <> +t: far_pss(t, s, far_ps(h, s, acc))

def perp_d(+s: S.SF, +p: V.Point) -> V.Dir:
  +a = S.dunit(S.sf_a(s))
  +d = S.psub(p, S.sf_o(s))
  S.dadd(d, F64.neg(S.dot(d, a)), a)

def seg_d0(+a: V.Dir, +b: V.Dir) -> F64:
  +ab = S.dadd(b, F64.neg(1.0f64), a)
  +t = F64.max(0.0f64, F64.min(1.0f64, F64.div(F64.neg(S.dot(a, ab)), F64.max(S.dot(ab, ab), 1.0e-300f64))))
  S.dlen(S.dadd(a, t, ab))

def pn_fin(+best: F64, +pos: Bool, +neg: Bool) -> F64:
  Bool.pick(F64, Bool.and(pos, neg), best, 0.0f64)

def pn_go(ps: List<&2, V.Point>, +s: S.SF, +first: V.Dir, +prev: V.Dir, +best: F64, +pos: Bool, +neg: Bool) -> F64:
  match ps:
    case []:
      +c = S.dot(S.cross(prev, first), S.sf_a(s))
      pn_fin(F64.min(best, seg_d0(prev, first)), Bool.or(pos, F64.is_lt(0.0f64, c)), Bool.or(neg, F64.is_lt(c, 0.0f64)))
    case +p <> +t:
      +q = perp_d(s, p)
      +c = S.dot(S.cross(prev, q), S.sf_a(s))
      pn_go(t, s, first, q, F64.min(best, seg_d0(prev, q)), Bool.or(pos, F64.is_lt(0.0f64, c)), Bool.or(neg, F64.is_lt(c, 0.0f64)))

def poly_near(ps: List<&2, V.Point>, +s: S.SF) -> F64:
  match ps:
    case []: 0.0f64
    case +h <> +t:
      +q0 = perp_d(s, h)
      pn_go(t, s, q0, q0, F64.div(1.0f64, 0.0f64), False{}, False{})

def near_pss(ls: List<&2, List<&2, V.Point>>, +s: S.SF, +acc: F64) -> F64:
  match ls:
    case []: acc
    case +h <> +t: near_pss(t, s, F64.min(acc, poly_near(h, s)))

def q_sep_w(+s: S.SF, +w: WD) -> Bool:
  WD{+ok, o, n0, n1, +a, +ps} = w
  +r = S.sf_r(s)
  +e = F64.mul(1.0e-9f64, F64.add(1.0f64, r))
  +inner = F64.is_lt(far_pss(ps, s, 0.0f64), F64.sub(r, e))
  +outer = F64.is_lt(F64.add(r, e), near_pss(ps, s, F64.div(1.0f64, 0.0f64)))
  Bool.and(Bool.and(ok, U64.is_eq(S.sf_kind(s), S.k_cyl())), Bool.and(par_ax(S.sf_a(s), a), Bool.or(inner, outer)))

def sat_sep(+wa: WD, +wb: WD) -> Bool:
  WD{+oka, +oa, n0a, n1a, +aa, +pa} = wa
  WD{+okb, +ob, n0b, n1b, +ab, +pb} = wb
  +e = F64.mul(1.0e-9f64, F64.add(1.0f64, F64.add(S.dist(oa, S.pt(0.0f64, 0.0f64, 0.0f64)), S.dist(ob, S.pt(0.0f64, 0.0f64, 0.0f64)))))
  Bool.and(Bool.and(Bool.and(oka, okb), par_ax(aa, ab)), all_ab(pa, pb, aa, oa, e))

def faces_wd(fs: List<&2, Nat>, +b: FB.KB) -> List<&2, WD>:
  match fs:
    case []: []
    case +h <> +t: wd_of(b, h) <> faces_wd(t, b)

def rho_go(tor: Bool, +b: FB.KB, +fi: Nat) -> V.Vec2:
  match tor:
    case False{}: V.V2{0.0f64, F64.neg(1.0f64)}
    case True{}:
      +big = {1.0e300f64 : F64}
      tor_rho(FB.face_sf(b, fi), v_rngs(FB.face_polys(b, fi), V.V2{big, F64.neg(big)}))

def rho_of(+b: FB.KB, +fi: Nat) -> V.Vec2:
  rho_go(S.is_tor(FB.face_sf(b, fi)), b, fi)

def faces_rho(fs: List<&2, Nat>, +b: FB.KB) -> List<&2, V.Vec2>:
  match fs:
    case []: []
    case +h <> +t: rho_of(b, h) <> faces_rho(t, b)

def t_sep(+x: FB.BB, +rho: V.Vec2, +s: S.SF) -> Bool:
  +e = F64.mul(1.0e-9f64, F64.add(1.0f64, F64.abs(V.v2_y(rho))))
  Bool.and(S.is_tor(s), Bool.or(F64.is_lt(F64.add(bb_far(s, x), e), V.v2_x(rho)), F64.is_lt(F64.add(V.v2_y(rho), e), bb_near(s, x))))

def skip_q(+bxa: FB.BB, +x: FB.BB, +wa: WD, +w: WD, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +h: Nat) -> Bool:
  Bool.or(Bool.or(FB.bb_dis(bxa, x), Bool.or(q_sep(bxa, FB.face_sf(bb, h)), q_sep(x, FB.face_sf(ba, fa)))),
    Bool.or(Bool.or(Bool.or(w_sep(bxa, w), w_sep(x, wa)), sat_sep(wa, w)), Bool.or(q_sep_w(FB.face_sf(ba, fa), w), q_sep_w(FB.face_sf(bb, h), wa))))

def skip_t(+bxa: FB.BB, +x: FB.BB, +rha: V.Vec2, +rh: V.Vec2, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +h: Nat) -> Bool:
  Bool.or(t_sep(x, rha, FB.face_sf(ba, fa)), t_sep(bxa, rh, FB.face_sf(bb, h)))

def faces_bb(fs: List<&2, Nat>, +b: FB.KB) -> List<&2, FB.BB>:
  match fs:
    case []: []
    case +h <> +t: FB.face_bb(b, h) <> faces_bb(t, b)

def bx_pad1(+lo: F64, +hi: F64) -> V.Vec2:
  +w = F64.add(F64.mul(0.05f64, F64.sub(hi, lo)), F64.mul(1.0e-6f64, F64.add(1.0f64, F64.max(F64.abs(lo), F64.abs(hi)))))
  V.V2{F64.sub(lo, w), F64.add(hi, w)}

def pj_box(+a: FB.BB, +b: FB.BB) -> SS.BX:
  FB.BB{+ax0, +ax1, +ay0, +ay1, +az0, +az1} = a
  FB.BB{+bx0, +bx1, +by0, +by1, +bz0, +bz1} = b
  +x = bx_pad1(F64.max(ax0, bx0), F64.min(ax1, bx1))
  +y = bx_pad1(F64.max(ay0, by0), F64.min(ay1, by1))
  +z = bx_pad1(F64.max(az0, bz0), F64.min(az1, bz1))
  SS.BX{V.v2_x(x), V.v2_y(x), V.v2_x(y), V.v2_y(y), V.v2_x(z), V.v2_y(z)}

def pj_mk(+hs: List<&2, HX>, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat) -> PJ:
  PJ{fa, fb, SS.ssi_b(FB.face_surf(ba, fa), FB.face_surf(bb, fb), pj_box(FB.face_bb(ba, fa), FB.face_bb(bb, fb))), pair_hits(hs, face_es(ba, fa), fa, face_es(bb, fb), fb)}

def pj_if(skip: Bool, +hs: List<&2, HX>, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat, +rest: List<&2, PJ>) -> List<&2, PJ>:
  match skip:
    case True{}: rest
    case False{}: pj_mk(hs, ba, fa, bb, fb) <> rest

def pj_b(fbs: List<&2, Nat>, +bxs: List<&2, FB.BB>, +wds: List<&2, WD>, +rhs: List<&2, V.Vec2>, +bxa: FB.BB, +wa: WD, +rha: V.Vec2, +hs: List<&2, HX>, +ba: FB.KB, +fa: Nat, +bb: FB.KB) -> List<&2, PJ>:
  match fbs:
    case []: []
    case +h <> +t:
      match bxs:
        case []: []
        case +x <> +xt:
          match wds:
            case []: []
            case +w <> +wt:
              match rhs:
                case []: []
                case +rh <> +rt:
                  +skip = Bool.or(skip_q(bxa, x, wa, w, ba, fa, bb, h), skip_t(bxa, x, rha, rh, ba, fa, bb, h))
                  pj_if(skip, hs, ba, fa, bb, h, pj_b(t, xt, wt, rt, bxa, wa, rha, hs, ba, fa, bb))

def pj_one(+c: PC, +fa: Nat) -> List<&2, PJ>:
  PC{+bxs, +wds, +rhs, +hs, +ba, +bb} = c
  pj_b(L.nat_range(FB.nfaces(bb)), bxs, wds, rhs, FB.face_bb(ba, fa), wd_of(ba, fa), rho_of(ba, fa), hs, ba, fa, bb)

def pj_job(c: PC, fa: Nat) -> List<&2, PJ>:
  pj_one(c, fa)

def pj_apply(+x: SS.ICS, +ph: List<&2, HX>, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat, +r: CR) -> CR:
  +g1 = FB.face_surf(ba, fa)
  +g2 = FB.face_surf(bb, fb)
  +bk = brk_hx(SS.ics_ics(x), cr_g(r), ph)
  +r2 = ics_go(SS.ics_ics(x), hxg_hs(bk), g1, g2, ba, fa, bb, fb, CR{cr_chs(r), hxg_g(bk), cr_ok(r), cr_why(r)})
  Bool.pick(CR, U64.is_eq(SS.ics_why(x), 0u64), r2, cr_fail(r2, SS.ics_why(x)))

def pj_fold(js: List<&2, PJ>, +ba: FB.KB, +bb: FB.KB, +r: CR) -> CR:
  match js:
    case []: r
    case +j <> +t:
      PJ{+fa, +fb, +x, +ph} = j
      pj_fold(t, ba, bb, pj_apply(x, ph, ba, fa, bb, fb, r))

def segs_same(xs: List<&2, SEG>, ys: List<&2, SEG>) -> Bool:
  match xs:
    case []:
      match ys:
        case []: True{}
        case +h <> +t: False{}
    case +x <> +xt:
      match ys:
        case []: False{}
        case +y <> +yt: Bool.and(Bool.and(Nat.is_eq(seg_va(x), seg_va(y)), Nat.is_eq(seg_vb(x), seg_vb(y))), segs_same(xt, yt))

def ch_same(+a: CH, +b: CH) -> Bool:
  Bool.and(Bool.and(Nat.is_eq(ch_fa(a), ch_fa(b)), Nat.is_eq(ch_fb(a), ch_fb(b))), segs_same(ch_segs(a), ch_segs(b)))

def ch_in(cs: List<&2, CH>, +c: CH) -> Bool:
  match cs:
    case []: False{}
    case +h <> +t: Bool.or(ch_same(h, c), ch_in(t, c))

def chs_uniq(cs: List<&2, CH>, +acc: List<&2, CH>) -> List<&2, CH>:
  match cs:
    case []: List.reverse(&2, CH, acc)
    case +h <> +t: chs_uniq(t, Bool.pick(List<&2, CH>, ch_in(acc, h), acc, h <> acc))

def all_chains(+hs: List<&2, HX>, +ba: FB.KB, +bb: FB.KB, +g: GV) -> CR:
  +c = {PC{faces_bb(L.nat_range(FB.nfaces(bb)), bb), faces_wd(L.nat_range(FB.nfaces(bb)), bb), faces_rho(L.nat_range(FB.nfaces(bb)), bb), hs, ba, bb} : PC}
  +js = List.concat(&2, PJ, B.pmap_g(~Nat, ~PC, ~List<&2, PJ>, ~pj_job, 1, c, L.nat_range(FB.nfaces(ba))))
  +r = pj_fold(js, ba, bb, CR{[], g, True{}, 0u64})
  CR{chs_uniq(cr_chs(r), []), cr_g(r), cr_ok(r), cr_why(r)}

def L_pp0_p(xs: List<&2, V.Point>) -> V.Point:
  match xs:
    case []: S.pt(0.0f64, 0.0f64, 0.0f64)
    case +h <> +t: h

def ch_dv(+c: CH) -> F64:
  CH{fa, fb, segs, pts, closed, dv} = c
  dv

def pe_two(+go: Bool, +side: U64, +e: Nat, +k: Ty.EdgeKind, +v: Nat, +p: V.Point, +fo: Nat, +acc: List<&2, HX>) -> List<&2, HX>:
  match go:
    case False{}: acc
    case True{}:
      +t = ve_param(k, p)
      Bool.pick(List<&2, HX>, F64.is_lt(S.dist(EF.ev(EF.ek_curve(k), t), p), ve_tol(p)), HX{side, e, t, p, v, fo} <> acc, acc)

def pe_one(+side: U64, +e: Nat, +b: FB.KB, +v: Nat, +p: V.Point, +fo: Nat, +acc: List<&2, HX>) -> List<&2, HX>:
  +ed = FB.edge_at(b, e)
  +k = Ty.ed_kind(ed)
  +tol = ve_tol(p)
  +far = Bool.and(F64.is_lt(tol, S.dist(p, FB.vpt(b, Ty.ed_v0(ed)))), F64.is_lt(tol, S.dist(p, FB.vpt(b, Ty.ed_v1(ed)))))
  +inb = Bool.not(FB.bb_dis(FB.bb_pad(FB.ek_bb(k), tol), FB.bb_pt(p)))
  pe_two(Bool.and(far, inb), side, e, k, v, p, fo, acc)

def pe_edges(es: List<&2, Nat>, +side: U64, +b: FB.KB, +v: Nat, +p: V.Point, +fo: Nat, +acc: List<&2, HX>) -> List<&2, HX>:
  match es:
    case []: acc
    case +h <> +t: pe_edges(t, side, b, v, p, fo, pe_one(side, h, b, v, p, fo, acc))

def pv_hits(vs: List<&2, Nat>, +side: U64, +b: FB.KB, +g: GV, +fo: Nat, +acc: List<&2, HX>) -> List<&2, HX>:
  match vs:
    case []: acc
    case +h <> +t: pv_hits(t, side, b, g, fo, pe_edges(L.nat_range(FB.nedges(b)), side, b, h, gv_pt(g, h), fo, acc))

def seg_vbs(ss: List<&2, SEG>) -> List<&2, Nat>:
  match ss:
    case []: []
    case +h <> +t: seg_vb(h) <> seg_vbs(t)

def all_vs(ss: List<&2, SEG>) -> List<&2, Nat>:
  match ss:
    case []: []
    case +h <> +t: seg_va(h) <> seg_vbs(h <> t)

def chain_hits(cs: List<&2, CH>, +ba: FB.KB, +bb: FB.KB, +g: GV, +acc: List<&2, HX>) -> List<&2, HX>:
  match cs:
    case []: acc
    case +h <> +t:
      +vs = all_vs(ch_segs(h))
      +a1 = Bool.pick(List<&2, HX>, Nat.is_eq(ch_fa(h), no_face()), pv_hits(vs, 0u64, ba, g, ch_fb(h), acc), acc)
      +a2 = Bool.pick(List<&2, HX>, Nat.is_eq(ch_fb(h), no_face()), pv_hits(vs, 1u64, bb, g, ch_fa(h), a1), a1)
      chain_hits(t, ba, bb, g, a2)
