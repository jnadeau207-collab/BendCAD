import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ./sf.bend as S
import ./ef.bend as EF
import ./fb.bend as FB
import ./px.bend as PX
import ./ls.bend as L

type CP is Data:
  CP{ fa: Nat, fb: Nat, so: Bool }

type EP is Data:
  EP{ ea: Nat, eb: Nat, n: V.Dir }

type CX is Data:
  CX{ hs: List<&2, PX.HX>, g: PX.GV, ok: Bool }

def cp_fa(+c: CP) -> Nat:
  CP{fa, fb, so} = c
  fa

def cp_fb(+c: CP) -> Nat:
  CP{fa, fb, so} = c
  fb

def cp_so(+c: CP) -> Bool:
  CP{fa, fb, so} = c
  so

def plane_n(+g: G.GVal) -> V.Dir:
  S.sf_a(S.sf_of(g))

def is_plane(+g: G.GVal) -> Bool:
  U64.is_eq(S.sf_kind(S.sf_of(g)), S.k_plane())

def coplanar(+ga: G.GVal, +gb: G.GVal) -> Bool:
  +sa = S.sf_of(ga)
  +sb = S.sf_of(gb)
  +na = S.sf_a(sa)
  +nb = S.sf_a(sb)
  +par = F64.is_eq(S.dlen(S.cross(na, nb)), 0.0f64)
  +on = F64.is_eq(S.dot(S.psub(S.sf_o(sb), S.sf_o(sa)), na), 0.0f64)
  Bool.and(Bool.and(is_plane(ga), is_plane(gb)), Bool.and(par, on))

def same_orient(+ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep, +fb: Nat) -> Bool:
  +na = plane_n(FB.face_surf(ba, fa))
  +nb = plane_n(FB.face_surf(bb, fb))
  +d = F64.is_lt(0.0f64, S.dot(na, nb))
  Bool.xor(d, Bool.xor(FB.face_same(ba, fa), FB.face_same(bb, fb)))

def cps_b(fbs: List<&2, Nat>, +ba: Ty.Brep, +fa: Nat, +bb: Ty.Brep) -> List<&2, CP>:
  match fbs:
    case []: []
    case +h <> +t:
      +rest = cps_b(t, ba, fa, bb)
      Bool.pick(List<&2, CP>, coplanar(FB.face_surf(ba, fa), FB.face_surf(bb, h)),
        CP{fa, h, same_orient(ba, fa, bb, h)} <> rest, rest)

def cps_a(fas: List<&2, Nat>, +ba: Ty.Brep, +bb: Ty.Brep) -> List<&2, CP>:
  match fas:
    case []: []
    case +h <> +t: List.append(&2, CP, cps_b(L.nat_range(FB.nfaces(bb)), ba, h, bb), cps_a(t, ba, bb))

def coin_pairs(+ba: Ty.Brep, +bb: Ty.Brep) -> List<&2, CP>:
  cps_a(L.nat_range(FB.nfaces(ba)), ba, bb)

def ep_ea(+e: EP) -> Nat:
  EP{ea, eb, n} = e
  ea

def ep_eb(+e: EP) -> Nat:
  EP{ea, eb, n} = e
  eb

def ep_n(+e: EP) -> V.Dir:
  EP{ea, eb, n} = e
  n

def ep_has(xs: List<&2, EP>, +a: Nat, +b: Nat) -> Bool:
  match xs:
    case []: False{}
    case +h <> +t: Bool.or(Bool.and(Nat.is_eq(ep_ea(h), a), Nat.is_eq(ep_eb(h), b)), ep_has(t, a, b))

def eps_eb(ebs: List<&2, Nat>, +ea: Nat, +n: V.Dir, +acc: List<&2, EP>) -> List<&2, EP>:
  match ebs:
    case []: acc
    case +h <> +t: eps_eb(t, ea, n, Bool.pick(List<&2, EP>, ep_has(acc, ea, h), acc, EP{ea, h, n} <> acc))

def eps_ea(eas: List<&2, Nat>, +ebs: List<&2, Nat>, +n: V.Dir, +acc: List<&2, EP>) -> List<&2, EP>:
  match eas:
    case []: acc
    case +h <> +t: eps_ea(t, ebs, n, eps_eb(ebs, h, n, acc))

def edge_pairs(cs: List<&2, CP>, +ba: Ty.Brep, +bb: Ty.Brep, +acc: List<&2, EP>) -> List<&2, EP>:
  match cs:
    case []: acc
    case +h <> +t:
      +n = plane_n(FB.face_surf(ba, cp_fa(h)))
      edge_pairs(t, ba, bb, eps_ea(PX.face_es(ba, cp_fa(h)), PX.face_es(bb, cp_fb(h)), n, acc))

def ek1(xs: List<&2, Ty.EdgeKind>) -> Ty.EdgeKind:
  match xs:
    case []: Ty.EK_degenerate{}
    case +h <> +t: h

def extr_go(+c: G.GVal, +n: V.Dir) -> List<&2, G.GVal>:
  match c:
    case G.GV_ln{w}:
      G.Ln{+p, +d} = w
      [G.GV_pl{G.Pl{p, S.dunit(d), n}}]
    case G.GV_cc{w}:
      G.Cc{+c0, +u, +v, +r} = w
      [G.GV_cy{G.Cy{c0, n, r}}]
    case G.GV_rq{w}:
      G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = w
      +m = S.padd(p0, 0.5f64, S.psub(p2, p0))
      +kk = F64.div(F64.mul(w1, w1), F64.sub(1.0f64, F64.mul(w1, w1)))
      +c0 = S.padd(m, kk, S.psub(m, p1))
      [G.GV_cy{G.Cy{c0, n, S.dist(p0, c0)}}]
    case _: []

def extr_of(+k: List<&2, Ty.EdgeKind>, +n: V.Dir) -> List<&2, G.GVal>:
  extr_go(EF.ek_curve(ek1(k)), n)

def g1(xs: List<&2, G.GVal>) -> G.GVal:
  match xs:
    case []: G.GV_f{0.0f64}
    case +h <> +t: h

def rq_ang(+c0: V.Point, +n: V.Dir, +a: V.Dir, +q: V.Point) -> F64:
  +d = S.psub(q, c0)
  S.fatan2(S.dot(S.cross(a, d), n), S.dot(a, d))

def rq_bis(n: Nat, +g: G.GVal, +c0: V.Point, +nn: V.Dir, +a: V.Dir, +target: F64, +lo: F64, +hi: F64) -> F64:
  match n:
    case 0n: F64.mul(0.5f64, F64.add(lo, hi))
    case 1n+m:
      +mid = F64.mul(0.5f64, F64.add(lo, hi))
      +am = rq_ang(c0, nn, a, EF.ev(g, mid))
      +up = F64.is_lt(am, target)
      rq_bis(m, g, c0, nn, a, target, Bool.pick(F64, up, mid, lo), Bool.pick(F64, up, hi, mid))

def rq_t(+p0: V.Point, +p1: V.Point, +p2: V.Point, +w: F64, +p: V.Point) -> F64:
  +m = S.padd(p0, 0.5f64, S.psub(p2, p0))
  +kk = F64.div(F64.mul(w, w), F64.sub(1.0f64, F64.mul(w, w)))
  +c0 = S.padd(m, kk, S.psub(m, p1))
  +nn = S.dunit(S.cross(S.psub(p0, c0), S.psub(p1, c0)))
  +a = S.psub(p0, c0)
  +g = {G.GV_rq{G.Rq{p0, p1, p2, 1.0f64, w, 1.0f64}} : G.GVal}
  rq_bis(80n, g, c0, nn, a, rq_ang(c0, nn, a, p), 0.0f64, 1.0f64)

def ta_go(+c: G.GVal, +p: V.Point) -> F64:
  match c:
    case G.GV_ln{w}:
      G.Ln{+p0, +d} = w
      F64.div(S.dot(S.psub(p, p0), d), S.dot(d, d))
    case G.GV_cc{w}:
      G.Cc{+c0, +u, +v, +r} = w
      +q = S.psub(p, c0)
      +phi = S.fatan2(S.dot(q, v), S.dot(q, u))
      +h = F64.mul(0.25f64, phi)
      F64.div(S.fsin(h), S.fcos(h))
    case G.GV_rq{w}:
      G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = w
      rq_t(p0, p1, p2, w1, p)
    case _: F64.neg(1.0f64)

def ta_of(+k: List<&2, Ty.EdgeKind>, +p: V.Point) -> F64:
  ta_go(EF.ek_curve(ek1(k)), p)

def cx_hs(+c: CX) -> List<&2, PX.HX>:
  CX{hs, g, ok} = c
  hs

def cx_g(+c: CX) -> PX.GV:
  CX{hs, g, ok} = c
  g

def cx_ok(+c: CX) -> Bool:
  CX{hs, g, ok} = c
  ok

def hx_faces(fs: List<&2, Nat>, +side: U64, +e: Nat, +t: F64, +p: V.Point, +v: Nat,
    +acc: List<&2, PX.HX>) -> List<&2, PX.HX>:
  match fs:
    case []: acc
    case +h <> +r: hx_faces(r, side, e, t, p, v, PX.HX{side, e, t, p, v, h} <> acc)

def strict_in(+t: F64, +lo: F64, +hi: F64) -> Bool:
  Bool.and(F64.is_lt(lo, t), F64.is_lt(t, hi))

def one_hit(hs: List<&2, EF.EH>, +ka: List<&2, Ty.EdgeKind>, +ea: Nat, +eb: Nat, +ba: Ty.Brep,
    +bb: Ty.Brep, +lob: F64, +hib: F64, +c: CX) -> CX:
  match hs:
    case []: c
    case +h <> +t:
      +p = EF.eh_p(h)
      +tb = EF.eh_t(h)
      +ta = ta_of(ka, p)
      +kk = ek1(ka)
      +inb = strict_in(tb, lob, hib)
      +ina = strict_in(ta, EF.ek_lo(kk), EF.ek_hi(kk))
      +on = F64.is_lt(S.dist(EF.ev(EF.ek_curve(kk), ta), p), 1.0e-6f64)
      +keep = Bool.and(inb, Bool.and(ina, on))
      +r = PX.gv_add(cx_g(c), p)
      +v = PX.vi_i(r)
      +nhs = hx_faces(FB.edge_faces(ba, ea), 1u64, eb, tb, p, v,
        hx_faces(FB.edge_faces(bb, eb), 0u64, ea, ta, p, v, cx_hs(c)))
      one_hit(t, ka, ea, eb, ba, bb, lob, hib,
        Bool.pick(CX, keep, CX{nhs, PX.vi_g(r), Bool.and(cx_ok(c), EF.eh_ok(h))}, c))

def surfs(fs: List<&2, Nat>, +b: Ty.Brep) -> List<&2, G.GVal>:
  match fs:
    case []: []
    case +h <> +t: FB.face_surf(b, h) <> surfs(t, b)

def pair_x(+e: EP, +ba: Ty.Brep, +bb: Ty.Brep, +c: CX) -> CX:
  +ea = ep_ea(e)
  +eb = ep_eb(e)
  +ka = {[Ty.ed_kind(FB.edge_at(ba, ea))] : List<&2, Ty.EdgeKind>}
  +kb = {[Ty.ed_kind(FB.edge_at(bb, eb))] : List<&2, Ty.EdgeKind>}
  +ex = extr_of(ka, ep_n(e))
  +gs = List.append(&2, G.GVal, surfs(FB.edge_faces(ba, ea), ba), surfs(FB.edge_faces(bb, eb), bb))
  +r = EF.edge_hits(ek1(kb), S.sf_of(g1(ex)), gs)
  +ok = Bool.not(Nat.is_eq(List.length(&2, G.GVal, ex), 0n))
  Bool.pick(CX, ok, one_hit(EF.ehs_hs(r), ka, ea, eb, ba, bb, EF.ek_lo(ek1(kb)), EF.ek_hi(ek1(kb)), c),
    CX{cx_hs(c), cx_g(c), False{}})

def pairs_x(es: List<&2, EP>, +ba: Ty.Brep, +bb: Ty.Brep, +c: CX) -> CX:
  match es:
    case []: c
    case +h <> +t: pairs_x(t, ba, bb, pair_x(h, ba, bb, c))

def crossings(+cps: List<&2, CP>, +ba: Ty.Brep, +bb: Ty.Brep, +g: PX.GV) -> CX:
  pairs_x(edge_pairs(cps, ba, bb, []), ba, bb, CX{[], g, True{}})

def partner_of(cs: List<&2, CP>, +sd: U64, +fi: Nat) -> List<&2, CP>:
  match cs:
    case []: []
    case +h <> +t:
      +rest = partner_of(t, sd, fi)
      +m = Bool.pick(Bool, U64.is_eq(sd, 0u64), Nat.is_eq(cp_fa(h), fi), Nat.is_eq(cp_fb(h), fi))
      Bool.pick(List<&2, CP>, m, h <> rest, rest)

def on_code(cs: List<&2, CP>, +sd: U64, +ob: Ty.Brep, +p: V.Point) -> U64:
  match cs:
    case []: 0u64
    case +h <> +t:
      +pf = Bool.pick(Nat, U64.is_eq(sd, 0u64), cp_fb(h), cp_fa(h))
      +inn = FB.pt_in_face(ob, pf, p)
      Bool.pick(U64, inn, Bool.pick(U64, cp_so(h), 4u64, 5u64), on_code(t, sd, ob, p))

def all_fo(fs: List<&2, Nat>, +side: U64, +e: Nat, +t: F64, +p: V.Point, +v: Nat, +acc: List<&2, PX.HX>) -> List<&2, PX.HX>:
  match fs:
    case []: acc
    case +h <> +r: all_fo(r, side, e, t, p, v, PX.HX{side, e, t, p, v, h} <> acc)

def tj_one(+side: U64, +ea: Nat, +ka: List<&2, Ty.EdgeKind>, +p: V.Point, +ob: Ty.Brep, +c: CX) -> CX:
  +kk = ek1(ka)
  +ta = ta_of(ka, p)
  +on = F64.is_lt(S.dist(EF.ev(EF.ek_curve(kk), ta), p), 1.0e-9f64)
  +inn = strict_in(ta, EF.ek_lo(kk), EF.ek_hi(kk))
  +notend = Bool.and(F64.is_lt(1.0e-9f64, S.dist(EF.ev(EF.ek_curve(kk), EF.ek_lo(kk)), p)),
    F64.is_lt(1.0e-9f64, S.dist(EF.ev(EF.ek_curve(kk), EF.ek_hi(kk)), p)))
  +r = PX.gv_add(cx_g(c), p)
  Bool.pick(CX, Bool.and(on, Bool.and(inn, notend)),
    CX{all_fo(L.nat_range(FB.nfaces(ob)), side, ea, ta, p, PX.vi_i(r), cx_hs(c)), PX.vi_g(r), cx_ok(c)}, c)

def tj_ends(+side: U64, +ea: Nat, +b: Ty.Brep, +ob: Ty.Brep, +eb: Nat, +c: CX) -> CX:
  +ka = {[Ty.ed_kind(FB.edge_at(b, ea))] : List<&2, Ty.EdgeKind>}
  +edb = FB.edge_at(ob, eb)
  +p0 = FB.vpt(ob, Ty.ed_v0(edb))
  +p1 = FB.vpt(ob, Ty.ed_v1(edb))
  tj_one(side, ea, ka, p1, ob, tj_one(side, ea, ka, p0, ob, c))

def tj_pairs(es: List<&2, EP>, +ba: Ty.Brep, +bb: Ty.Brep, +c: CX) -> CX:
  match es:
    case []: c
    case +h <> +t:
      +c1 = tj_ends(0u64, ep_ea(h), ba, bb, ep_eb(h), c)
      tj_pairs(t, ba, bb, tj_ends(1u64, ep_eb(h), bb, ba, ep_ea(h), c1))

def tjunctions(+cps: List<&2, CP>, +ba: Ty.Brep, +bb: Ty.Brep, +g: PX.GV) -> CX:
  tj_pairs(edge_pairs(cps, ba, bb, []), ba, bb, CX{[], g, True{}})
