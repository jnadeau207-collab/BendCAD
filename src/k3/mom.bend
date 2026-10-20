import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c06/iv.bend as I
import ../k1/sf.bend as S
import ../k1/ef.bend as EF
import ../k1/fb.bend as FB
import ../k1/ls.bend as L
import ../k1/vi.bend as VI
import ../c06/model.bend as M
import ../c11/qmass.bend as QM

type MV is Data:
  MV{ v: F64, x: F64, y: F64, z: F64, xx: F64, yy: F64, zz: F64, xy: F64, yz: F64, zx: F64 }

type MP is Data:
  MP{ m: MV, e: MV }

def mv0() -> MV:
  MV{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}

def mv_axpy(+k: F64, +a: MV, +b: MV) -> MV:
  MV{+av, +ax, +ay, +az, +axx, +ayy, +azz, +axy, +ayz, +azx} = a
  MV{+bv, +bx, +by, +bz, +bxx, +byy, +bzz, +bxy, +byz, +bzx} = b
  MV{F64.add(bv, F64.mul(k, av)), F64.add(bx, F64.mul(k, ax)), F64.add(by, F64.mul(k, ay)), F64.add(bz, F64.mul(k, az)),
    F64.add(bxx, F64.mul(k, axx)), F64.add(byy, F64.mul(k, ayy)), F64.add(bzz, F64.mul(k, azz)),
    F64.add(bxy, F64.mul(k, axy)), F64.add(byz, F64.mul(k, ayz)), F64.add(bzx, F64.mul(k, azx))}

def mv_dev(+a: MV, +b: MV) -> MV:
  MV{+av, +ax, +ay, +az, +axx, +ayy, +azz, +axy, +ayz, +azx} = a
  MV{+bv, +bx, +by, +bz, +bxx, +byy, +bzz, +bxy, +byz, +bzx} = b
  MV{F64.abs(F64.sub(av, bv)), F64.abs(F64.sub(ax, bx)), F64.abs(F64.sub(ay, by)), F64.abs(F64.sub(az, bz)),
    F64.abs(F64.sub(axx, bxx)), F64.abs(F64.sub(ayy, byy)), F64.abs(F64.sub(azz, bzz)),
    F64.abs(F64.sub(axy, bxy)), F64.abs(F64.sub(ayz, byz)), F64.abs(F64.sub(azx, bzx))}

def mp_add(+a: MP, +b: MP) -> MP:
  MP{+am, +ae} = a
  MP{+bm, +be} = b
  MP{mv_axpy(1.0f64, am, bm), mv_axpy(1.0f64, ae, be)}

def mp0() -> MP:
  MP{mv0(), mv0()}

def mp_m(+a: MP) -> MV:
  MP{+m, +e} = a
  m

def mp_e(+a: MP) -> MV:
  MP{+m, +e} = a
  e

def mp_fma(+acc: MP, +f: F64, +k: MP) -> MP:
  MP{+am, +ae} = acc
  MP{+km, +ke} = k
  MP{mv_axpy(f, km, am), mv_axpy(F64.abs(f), ke, ae)}

def mp_gl(+a8: MP, +a4: MP) -> MP:
  MP{+m8, +e8} = a8
  MP{+m4, +e4} = a4
  MP{m8, mv_axpy(1.0f64, e8, mv_dev(m8, m4))}

def mp_scale(+sg: F64, +a: MP) -> MP:
  MP{+m, +e} = a
  MP{mv_axpy(sg, m, mv0()), e}

def sf1(ss: List<&2, S.SF>) -> S.SF:
  match ss:
    case []: S.sf_of(G.GV_f{0.0f64})
    case +h <> +t: h

def rho_hat(+s: S.SF, +u: F64) -> V.Dir:
  S.dadd(S.dscale(S.fcos(u), S.sf_e1(s)), S.fsin(u), S.sf_e2(s))

def puv(+s: S.SF, +u: F64, +v: F64) -> V.Dir:
  +kd = S.sf_kind(s)
  +rh = rho_hat(s, u)
  +a = S.sf_a(s)
  +k = S.sf_r(s)
  +ph = F64.add(v, S.sf_t0(s))
  +rr = F64.add(k, F64.mul(S.sf_r2(s), S.fcos(ph)))
  Bool.pick(V.Dir, U64.is_eq(kd, S.k_plane()), S.cross(S.sf_e1(s), S.sf_e2(s)),
    Bool.pick(V.Dir, U64.is_eq(kd, S.k_cyl()), S.dscale(k, rh),
      Bool.pick(V.Dir, U64.is_eq(kd, S.k_cone()), S.dscale(F64.mul(k, v), S.dadd(rh, F64.neg(k), a)),
        Bool.pick(V.Dir, S.is_sph(s), S.psub(S.sf_at(s, u, v), S.sf_o(s)),
          S.dscale(F64.mul(rr, S.sf_r2(s)), S.dadd(S.dscale(S.fcos(ph), rh), S.fsin(ph), a))))))

def mv_at(+s: S.SF, +c: V.Point, +u: F64, +v: F64) -> MV:
  +p = S.psub(S.sf_at(s, u, v), c)
  +w = S.dot(p, puv(s, u, v))
  +x = S.dx(p)
  +y = S.dy(p)
  +z = S.dz(p)
  +wx = F64.mul(w, x)
  +wy = F64.mul(w, y)
  +wz = F64.mul(w, z)
  MV{w, wx, wy, wz, F64.mul(wx, x), F64.mul(wy, y), F64.mul(wz, z), F64.mul(wx, y), F64.mul(wy, z), F64.mul(wz, x)}

def inner_v(+sph: Bool, +r: F64, +f: F64) -> F64:
  Bool.pick(F64, sph, F64.mul(r, S.fsin(f)), f)

def inner_j(+sph: Bool, +r: F64, +f: F64) -> F64:
  Bool.pick(F64, sph, F64.mul(r, S.fcos(f)), 1.0f64)

def inner_q(qs: List<&2, VI.GQ>, +ss: List<&2, S.SF>, +c: V.Point, +u: F64, +sph: Bool, +m: F64, +hw: F64, +acc: MV) -> MV:
  match qs:
    case []: acc
    case +q <> +t:
      VI.GQ{+x, +w} = q
      +f = F64.add(m, F64.mul(hw, x))
      +r = S.sf_r(sf1(ss))
      inner_q(t, ss, c, u, sph, m, hw, mv_axpy(F64.mul(F64.mul(w, hw), inner_j(sph, r, f)), mv_at(sf1(ss), c, u, inner_v(sph, r, f)), acc))

def asin_r(+r: F64, +v: F64) -> F64:
  +q = F64.max(F64.neg(1.0f64), F64.min(1.0f64, F64.div(v, r)))
  S.fatan2(q, F64.sqrt(F64.max(0.0f64, F64.sub(1.0f64, F64.mul(q, q)))))

def inner_k(+ss: List<&2, S.SF>, +c: V.Point, +u: F64, +v: F64) -> MP:
  +sph = S.is_sph(sf1(ss))
  +top = Bool.pick(F64, sph, asin_r(S.sf_r(sf1(ss)), v), v)
  +m = F64.mul(0.5f64, top)
  +a8 = inner_q(VI.gl8(), ss, c, u, sph, m, m, mv0())
  +a4 = inner_q(VI.gl4(), ss, c, u, sph, m, m, mv0())
  MP{a8, mv_dev(a8, a4)}

def d_u(+s: S.SF, +x: V.Point, +d: V.Dir) -> F64:
  +q = S.psub(x, S.sf_o(s))
  +e1 = S.sf_e1(s)
  +e2 = S.sf_e2(s)
  +px = S.dot(q, e1)
  +py = S.dot(q, e2)
  Bool.pick(F64, U64.is_eq(S.sf_kind(s), S.k_plane()), S.dot(d, e1),
    F64.div(F64.sub(F64.mul(px, S.dot(d, e2)), F64.mul(py, S.dot(d, e1))), F64.add(F64.mul(px, px), F64.mul(py, py))))

def edge_pt(+ss: List<&2, S.SF>, +ks: List<&2, Ty.EdgeKind>, +tt: F64) -> List<&2, F64>:
  +g = EF.ek_curve(VI.ek1(ks))
  +p = EF.ev(g, tt)
  +uv = FB.uv_raw(sf1(ss), p)
  [V.v2_x(uv), V.v2_y(uv), d_u(sf1(ss), p, VI.cv_der(g, tt))]

def edge_q(qs: List<&2, VI.GQ>, +ss: List<&2, S.SF>, +c: V.Point, +ks: List<&2, Ty.EdgeKind>, +m: F64, +hw: F64, +acc: MP) -> MP:
  match qs:
    case []: acc
    case +q <> +t:
      VI.GQ{+x, +w} = q
      +e = edge_pt(ss, ks, F64.add(m, F64.mul(hw, x)))
      +f = F64.neg(F64.mul(F64.mul(w, hw), L.nth_f64(e, 2n)))
      edge_q(t, ss, c, ks, m, hw, mp_fma(acc, f, inner_k(ss, c, L.nth_f64(e, 0n), L.nth_f64(e, 1n))))

def edge_one(+ss: List<&2, S.SF>, +c: V.Point, +ks: List<&2, Ty.EdgeKind>, +m: F64, +hw: F64) -> MP:
  mp_gl(edge_q(VI.gl8(), ss, c, ks, m, hw, mp0()), edge_q(VI.gl4(), ss, c, ks, m, hw, mp0()))

def edge_sub(n: Nat, +ss: List<&2, S.SF>, +c: V.Point, +ks: List<&2, Ty.EdgeKind>, +lo: F64, +dt: F64, +j: F64, +acc: MP) -> MP:
  match n:
    case 0n: acc
    case 1n+r:
      +m = F64.add(lo, F64.mul(F64.add(j, 0.5f64), dt))
      edge_sub(r, ss, c, ks, lo, dt, F64.add(j, 1.0f64), mp_add(acc, edge_one(ss, c, ks, m, F64.mul(0.5f64, dt))))


def edge_mp(+ss: List<&2, S.SF>, +c: V.Point, +ks: List<&2, Ty.EdgeKind>, +fw: Bool) -> MP:
  +lo = EF.ek_lo(VI.ek1(ks))
  +n = Bool.pick(Nat, FB.is_line(VI.ek1(ks)), 1n, 8n)
  +dt = F64.div(F64.sub(EF.ek_hi(VI.ek1(ks)), lo), L.f64_of(n))
  mp_scale(Bool.pick(F64, fw, 1.0f64, F64.neg(1.0f64)), edge_sub(n, ss, c, ks, lo, dt, 0.0f64, mp0()))

def edge_or(+deg: Bool, +ss: List<&2, S.SF>, +c: V.Point, +ks: List<&2, Ty.EdgeKind>, +fw: Bool) -> MP:
  match deg:
    case True{}: mp0()
    case False{}: edge_mp(ss, c, ks, fw)

def ce_kind(+b: Ty.Brep, +h: FB.CE) -> List<&2, Ty.EdgeKind>:
  [Ty.ed_kind(FB.edge_at(b, FB.ce_e(h)))]

def ces_mp(cs: List<&2, FB.CE>, +b: Ty.Brep, +ss: List<&2, S.SF>, +c: V.Point, +acc: MP) -> MP:
  match cs:
    case []: acc
    case +h <> +t:
      +ks = ce_kind(b, h)
      ces_mp(t, b, ss, c, mp_add(acc, edge_or(U64.is_eq(VI.ks_tag(ks), 0u64), ss, c, ks, FB.ce_fw(h))))

def lps_mp(ls: List<&2, List<&2, FB.CE>>, +b: Ty.Brep, +ss: List<&2, S.SF>, +c: V.Point, +acc: MP) -> MP:
  match ls:
    case []: acc
    case +h <> +t: lps_mp(t, b, ss, c, ces_mp(h, b, ss, c, acc))

def pole_q(qs: List<&2, VI.GQ>, +ss: List<&2, S.SF>, +c: V.Point, +v: F64, +m: F64, +hw: F64, +acc: MP) -> MP:
  match qs:
    case []: acc
    case +q <> +t:
      VI.GQ{+x, +w} = q
      pole_q(t, ss, c, v, m, hw, mp_fma(acc, F64.mul(w, hw), inner_k(ss, c, F64.add(m, F64.mul(hw, x)), v)))

def pole_one(+ss: List<&2, S.SF>, +c: V.Point, +v: F64, +m: F64, +hw: F64) -> MP:
  mp_gl(pole_q(VI.gl8(), ss, c, v, m, hw, mp0()), pole_q(VI.gl4(), ss, c, v, m, hw, mp0()))

def pole_sub(n: Nat, +ss: List<&2, S.SF>, +c: V.Point, +v: F64, +dt: F64, +j: F64, +acc: MP) -> MP:
  match n:
    case 0n: acc
    case 1n+r:
      +m = F64.mul(F64.add(j, 0.5f64), dt)
      pole_sub(r, ss, c, v, dt, F64.add(j, 1.0f64), mp_add(acc, pole_one(ss, c, v, m, F64.mul(0.5f64, dt))))

def pole_mp(+on: Bool, +sg: F64, +ss: List<&2, S.SF>, +c: V.Point, +v: F64) -> MP:
  match on:
    case False{}: mp0()
    case True{}: mp_scale(sg, pole_sub(8n, ss, c, v, F64.div(S.two_pi(), 8.0f64), 0.0f64, mp0()))

def face_mp(+b: Ty.Brep, +fi: Nat, +c: V.Point) -> MP:
  +s = FB.face_sf(b, fi)
  +sg = Bool.pick(F64, FB.face_same(b, fi), 1.0f64, F64.neg(1.0f64))
  +r = S.sf_r(s)
  +sph = S.is_sph(s)
  +np = Bool.and(sph, FB.pt_in_face(b, fi, S.padd(S.sf_o(s), r, S.sf_a(s))))
  +sp = Bool.and(sph, FB.pt_in_face(b, fi, S.padd(S.sf_o(s), F64.neg(r), S.sf_a(s))))
  +lp = lps_mp(FB.face_ce(b, fi), b, [s], c, mp0())
  mp_add(mp_add(lp, pole_mp(np, sg, [s], c, r)), pole_mp(sp, F64.neg(sg), [s], c, F64.neg(r)))

def faces_mp(fs: List<&2, Nat>, +b: Ty.Brep, +c: V.Point, +acc: MP) -> MP:
  match fs:
    case []: acc
    case +h <> +t: faces_mp(t, b, c, mp_add(acc, face_mp(b, h, c)))

type MR is Data:
  MR{ c: V.Point, m: MV, e: MV, slv: F64, rad: F64 }

def bb_all(fs: List<&2, Nat>, +b: Ty.Brep, +acc: FB.BB) -> FB.BB:
  match fs:
    case []: acc
    case +h <> +t: bb_all(t, b, FB.bb_join(acc, FB.face_bb(b, h)))

def bb_far(+x: FB.BB, +c: V.Point) -> F64:
  FB.BB{+x0, +x1, +y0, +y1, +z0, +z1} = x
  +dx = F64.max(F64.abs(F64.sub(x0, V.pt_x(c))), F64.abs(F64.sub(x1, V.pt_x(c))))
  +dy = F64.max(F64.abs(F64.sub(y0, V.pt_y(c))), F64.abs(F64.sub(y1, V.pt_y(c))))
  +dz = F64.max(F64.abs(F64.sub(z0, V.pt_z(c))), F64.abs(F64.sub(z1, V.pt_z(c))))
  F64.sqrt(F64.add(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)), F64.mul(dz, dz)))

def brep_mom(+b: Ty.Brep) -> MR:
  +c = VI.center_of(b)
  +fs = L.nat_range(FB.nfaces(b))
  +r = faces_mp(fs, b, c, mp0())
  +va = VI.faces_va(fs, b, c, VI.va0())
  MR{c, mp_m(r), mp_e(r), VI.va_slv(va), bb_far(bb_all(fs, b, FB.bb_empty()), c)}

def ivw(+x: F64, +e: F64) -> I.I:
  I.iwiden(I.ipt(x), F64.add(F64.add(e, F64.mul(F64.abs(x), 1.0e-12f64)), 1.0e-12f64))

def mv_iv(+t: MV, +e: MV, +slv: F64, +rad: F64) -> List<&2, I.I>:
  MV{+tv, +tx, +ty, +tz, +txx, +tyy, +tzz, +txy, +tyz, +tzx} = t
  MV{+ev, +ex, +ey, +ez, +exx, +eyy, +ezz, +exy, +eyz, +ezx} = e
  +s1 = F64.mul(slv, rad)
  +s2 = F64.mul(s1, rad)
  [ivw(F64.div(tv, 3.0f64), F64.add(F64.div(ev, 3.0f64), slv)),
    ivw(F64.div(tx, 4.0f64), F64.add(F64.div(ex, 4.0f64), s1)), ivw(F64.div(ty, 4.0f64), F64.add(F64.div(ey, 4.0f64), s1)),
    ivw(F64.div(tz, 4.0f64), F64.add(F64.div(ez, 4.0f64), s1)),
    ivw(F64.div(txx, 5.0f64), F64.add(F64.div(exx, 5.0f64), s2)), ivw(F64.div(tyy, 5.0f64), F64.add(F64.div(eyy, 5.0f64), s2)),
    ivw(F64.div(tzz, 5.0f64), F64.add(F64.div(ezz, 5.0f64), s2)), ivw(F64.div(txy, 5.0f64), F64.add(F64.div(exy, 5.0f64), s2)),
    ivw(F64.div(tyz, 5.0f64), F64.add(F64.div(eyz, 5.0f64), s2)), ivw(F64.div(tzx, 5.0f64), F64.add(F64.div(ezx, 5.0f64), s2))]

def cr_of(+ivs: List<&2, I.I>) -> List<&2, I.I>:
  +v = M.i_nth(ivs, 0n)
  [I.idiv(M.i_nth(ivs, 1n), v), I.idiv(M.i_nth(ivs, 2n), v), I.idiv(M.i_nth(ivs, 3n), v)]

def cl_of(+cr: List<&2, I.I>, +c: V.Point) -> List<&2, I.I>:
  [I.iadd(M.i_nth(cr, 0n), I.ipt(V.pt_x(c))), I.iadd(M.i_nth(cr, 1n), I.ipt(V.pt_y(c))), I.iadd(M.i_nth(cr, 2n), I.ipt(V.pt_z(c)))]

def il_of(+ivs: List<&2, I.I>) -> List<&2, I.I>:
  +sxx = M.i_nth(ivs, 4n)
  +syy = M.i_nth(ivs, 5n)
  +szz = M.i_nth(ivs, 6n)
  QM.i9_of(I.iadd(syy, szz), I.iadd(sxx, szz), I.iadd(sxx, syy), I.ineg(M.i_nth(ivs, 7n)), I.ineg(M.i_nth(ivs, 9n)),
    I.ineg(M.i_nth(ivs, 8n)))

def cen_s(+mi: List<&2, I.I>, +ti: List<&2, I.I>, +cl: List<&2, I.I>) -> String:
  QM.iv3_s(QM.cw_of(mi, ti, cl))

def ine_s(+mi: List<&2, I.I>, +il: List<&2, I.I>, +v: I.I, +cr: List<&2, I.I>) -> String:
  QM.iv6_s(QM.pk6(QM.rot_i(mi, QM.sh9(il, v, cr))))

def mom_line(+ivs: List<&2, I.I>, +c: V.Point, +pl: M.Pl) -> String:
  +cr = cr_of(ivs)
  +mi = M.pl_mi(pl)
  "moments volume=" ++ QM.iv_s(M.i_nth(ivs, 0n)) ++ " centroid " ++ cen_s(mi, M.pl_ti(pl), cl_of(cr, c)) ++ " inertia-centroid " ++
    ine_s(mi, il_of(ivs), M.i_nth(ivs, 0n), cr) ++ " status=certified method=divergence
"

def mom_of(+r: MR, +pl: M.Pl) -> String:
  MR{+c, +m, +e, +slv, +rad} = r
  mom_line(mv_iv(m, e, slv, rad), c, pl)

def mom_s(+b: M.Body) -> String:
  mom_of(brep_mom(M.bd_brep(b)), M.bd_pl(b))

def i3(+xs: List<&2, I.I>, +i: Nat) -> I.I:
  M.i_nth(xs, i)

def dot3(+a: List<&2, I.I>, +b: List<&2, I.I>) -> I.I:
  I.iadd(I.iadd(I.imul(i3(a, 0n), i3(b, 0n)), I.imul(i3(a, 1n), i3(b, 1n))), I.imul(i3(a, 2n), i3(b, 2n)))

def sc3(+k: I.I, +a: List<&2, I.I>) -> List<&2, I.I>:
  [I.imul(k, i3(a, 0n)), I.imul(k, i3(a, 1n)), I.imul(k, i3(a, 2n))]

def sub3(+a: List<&2, I.I>, +b: List<&2, I.I>) -> List<&2, I.I>:
  [I.isub(i3(a, 0n), i3(b, 0n)), I.isub(i3(a, 1n), i3(b, 1n)), I.isub(i3(a, 2n), i3(b, 2n))]

def mat3(+m: List<&2, I.I>, +v: List<&2, I.I>) -> List<&2, I.I>:
  [dot3([i3(m, 0n), i3(m, 1n), i3(m, 2n)], v), dot3([i3(m, 3n), i3(m, 4n), i3(m, 5n)], v), dot3([i3(m, 6n), i3(m, 7n), i3(m, 8n)], v)]

def root_nn(+x: I.I) -> I.I:
  I.isqrt(I.I{F64.max(0.0f64, I.i_lo(x)), F64.max(0.0f64, I.i_hi(x))})

def bal_verdict(+u: I.I, +up: I.I) -> String:
  Bool.pick(String, F64.is_lt(I.i_hi(u), I.i_lo(up)), "within status=certified",
    Bool.pick(String, F64.is_lt(I.i_hi(up), I.i_lo(u)), "exceeds status=certified", "undecided status=estimated"))

def bal_go(+ivs: List<&2, I.I>, +c: V.Point, +pl: M.Pl, +rho: F64, +p: List<&2, I.I>, +d: List<&2, I.I>, +w: F64, +g: F64) -> String:
  +cr = cr_of(ivs)
  +mi = M.pl_mi(pl)
  +v = i3(ivs, 0n)
  +cw = QM.cw_of(mi, M.pl_ti(pl), cl_of(cr, c))
  +iw = QM.rot_i(mi, QM.sh9(il_of(ivs), v, cr))
  +kg = I.iscale(v, F64.mul(rho, 1.0e-9f64))
  +r = sub3(cw, p)
  +perp = sub3(r, sc3(dot3(r, d), d))
  +e = root_nn(dot3(perp, perp))
  +u = I.iscale(I.imul(kg, e), 1000.0f64)
  +up = I.iscale(kg, F64.div(F64.mul(1000.0f64, g), w))
  +id = mat3(iw, d)
  +ddi = dot3(d, id)
  +pv = sub3(id, sc3(ddi, d))
  +pr = I.iscale(root_nn(dot3(pv, pv)), F64.mul(rho, 1.0e-9f64))
  "balance mass=" ++ QM.iv_s(kg) ++ " kg offset=" ++ QM.iv_s(e) ++ " mm residual=" ++ QM.iv_s(u) ++ " g.mm permissible=" ++
    QM.iv_s(up) ++ " g.mm grade=G" ++ F64.show(g) ++ " omega=" ++ F64.show(w) ++ " rad/s products=" ++ QM.iv_s(pr) ++
    " kg.mm2 " ++ bal_verdict(u, up) ++ " method=divergence
"

def bal_r(r: MR, +pl: M.Pl, +rho: F64, +p: List<&2, I.I>, +d: List<&2, I.I>, +w: F64, +g: F64) -> String:
  MR{+c, +m, +e, +slv, +rad} = r
  bal_go(mv_iv(m, e, slv, rad), c, pl, rho, p, d, w, g)

def bal_s(+b: M.Body, +rho: F64, +p: List<&2, I.I>, +d: List<&2, I.I>, +rpm: F64, +g: F64) -> String:
  bal_r(brep_mom(M.bd_brep(b)), M.bd_pl(b), rho, p, d, F64.div(F64.mul(rpm, 6.283185307179586f64), 60.0f64), g)
