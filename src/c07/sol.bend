import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c06/iv.bend as I
import ./ivx.bend as X
import ./rb.bend as R
import ./im.bend as M
import ./xs.bend as S
import ./mem.bend as Mm

type Fd is Data:
  Fd{ fc: Mm.Fc, g: List<&2, G.GVal>, bx: List<&2, I.I>, ok: Bool, sh: Nat }

type Ea is Data:
  Ea{ es: List<&2, Mm.Er>, ok: Bool }

type Rc is Data:
  Rc{ n: Nat, st: U64 }

type Ip is Data:
  Ip{ i: Nat, q: List<&2, I.I>, n: List<&2, I.I> }

type Fi is Data:
  Fi{ code: String, a: Nat, b: Nat }

def ea_es(a: Ea) -> List<&2, Mm.Er>:
  Ea{es, ok} = a
  es

def ea_ok(a: Ea) -> Bool:
  Ea{es, ok} = a
  ok

def ea_add(m: Maybe<&2, List<&2, Mm.Er>>, +acc: Ea) -> Ea:
  match m:
    case None{}: Ea{ea_es(acc), False{}}
    case Some{xs}: Ea{List.append(&2, Mm.Er, xs, ea_es(acc)), ea_ok(acc)}

def cv_ers(m: Maybe<&2, R.Cv>, +fwd: Bool) -> Maybe<&2, List<&2, Mm.Er>>:
  match m:
    case None{}: None{}
    case Some{c}: Some{[Mm.Er{c, fwd}]}

def ek_ers(k: Ty.EdgeKind, +fwd: Bool) -> Maybe<&2, List<&2, Mm.Er>>:
  match k:
    case Ty.EK_curve{c, d}: cv_ers(S.gv_cv(c, d), fwd)
    case Ty.EK_degenerate{}: Some{[]}

def ed_add(e: Ty.Edge, +fwd: Bool, +acc: Ea) -> Ea:
  Ty.Ed{g, v0, v1, k} = e
  ea_add(ek_ers(k, fwd), acc)

def ce_add(ce: Ty.Coedge, +x: Ty.Ix, +acc: Ea) -> Ea:
  Ty.Ce{g, eh, fwd, tr} = ce
  ed_add(Ty.tres_ed(Ty.ix_ed(x, eh)), fwd, acc)

def ces_go(hs: List<&2, Ty.HCoedge>, +x: Ty.Ix, +acc: Ea) -> Ea:
  match hs:
    case []: acc
    case h <> t: ces_go(t, x, ce_add(Ty.tres_ce(Ty.ix_ce(x, h)), x, acc))

def lp_add(l: Ty.Loop, +x: Ty.Ix, +acc: Ea) -> Ea:
  Ty.Lp{g, hs, k} = l
  ces_go(hs, x, acc)

def lps_go(hs: List<&2, Ty.HLoop>, +x: Ty.Ix, +acc: Ea) -> Ea:
  match hs:
    case []: acc
    case h <> t: lps_go(t, x, lp_add(Ty.tres_lp(Ty.ix_lp(x, h)), x, acc))

def pm(+r: I.I) -> I.I:
  I.ihull(I.ineg(r), r)

def ball(+c: List<&2, I.I>, +r: I.I) -> List<&2, I.I>:
  +w = pm(r)
  X.vadd(c, [w, w, w])

def eb_go(es: List<&2, Mm.Er>, +acc: List<&2, I.I>) -> List<&2, I.I>:
  match es:
    case []: acc
    case e <> t:
      +b = R.cv_hbox(Mm.er_c(e))
      eb_go(t, Bool.pick(List<&2, I.I>, Nat.is_eq(List.length(&2, I.I, acc), 0n), b, X.vhull(acc, b)))

def axial_box(+o: List<&2, I.I>, +a: List<&2, I.I>, +bx: List<&2, I.I>, +r: I.I, +h: I.I) -> List<&2, I.I>:
  ball(X.vadd(o, Mm.vs(I.idiv(h, X.vdot(a, a)), a)), r)

def surf_box(s: M.Im, +bx: List<&2, I.I>) -> List<&2, I.I>:
  match s:
    case M.M_pl{o, n}: bx
    case M.M_sp{c, r}: ball(c, r)
    case M.M_cy{+o, +a, r}: axial_box(o, a, bx, r, X.vdot(a, X.vsub(bx, o)))
    case M.M_co{+o, +a, k}:
      +h = I.ihull(X.vdot(a, X.vsub(bx, o)), I.ipt(0.0f64))
      +rho = I.imul(k, I.idiv(I.ipt(X.imag(h)), I.isqrt(X.vdot(a, a))))
      axial_box(o, a, bx, rho, h)
    case M.M_to{o, a, bigr, r}: ball(o, I.iadd(bigr, r))

def fd_mk(m: Maybe<&2, M.Im>, +s: G.GVal, +same: Bool, +ea: Ea, +sh: Nat) -> Fd:
  match m:
    case None{}: Fd{Mm.Fc{M.M_pl{[], []}, same, ea_es(ea)}, [s], eb_go(ea_es(ea), []), False{}, sh}
    case Some{+im}:
      +es = ea_es(ea)
      Fd{Mm.Fc{im, same, es}, [s], surf_box(im, eb_go(es, [])), ea_ok(ea), sh}

def fd_of(f: Ty.Face, +x: Ty.Ix, +sh: Nat) -> Fd:
  Ty.Fa{g, +s, ls, same} = f
  fd_mk(S.gv_im(s), s, same, lps_go(ls, x, Ea{[], True{}}), sh)

def fhs_go(hs: List<&2, Ty.HFace>, +x: Ty.Ix, +sh: Nat) -> List<&2, Fd>:
  match hs:
    case []: []
    case h <> t: fd_of(Ty.tres_fa(Ty.ix_fa(x, h)), x, sh) <> fhs_go(t, x, sh)

def sh_fds(s: Ty.Shell, +x: Ty.Ix, +i: Nat) -> List<&2, Fd>:
  Ty.Sh{g, hs, k} = s
  fhs_go(hs, x, i)

def shs_go(ss: List<&2, Ty.Shell>, +x: Ty.Ix, +i: Nat) -> List<&2, Fd>:
  match ss:
    case []: []
    case s <> t: List.append(&2, Fd, sh_fds(s, x, i), shs_go(t, x, Nat.add(i, 1n)))

def fds_of(+b: Ty.Brep) -> List<&2, Fd>:
  shs_go(Ty.brep_shs(b), Ty.ix_of(b), 0n)

def fd_bx(f: Fd) -> List<&2, I.I>:
  Fd{fc, g, bx, ok, sh} = f
  bx

def fd_sh(f: Fd) -> Nat:
  Fd{fc, g, bx, ok, sh} = f
  sh

def fd_fc(f: Fd) -> Mm.Fc:
  Fd{fc, g, bx, ok, sh} = f
  fc

def fd_im(f: Fd) -> M.Im:
  Mm.fc_s(fd_fc(f))

def g1(xs: List<&2, G.GVal>) -> G.GVal:
  match xs:
    case []: Ty.surf_zero()
    case x <> t: x

def fd_g(f: Fd) -> G.GVal:
  Fd{fc, g, bx, ok, sh} = f
  g1(g)

def fd_ok(f: Fd) -> Bool:
  Fd{fc, g, bx, ok, sh} = f
  ok

def bbox(fs: List<&2, Fd>, +acc: List<&2, I.I>) -> List<&2, I.I>:
  match fs:
    case []: acc
    case f <> t:
      +b = fd_bx(f)
      bbox(t, Bool.pick(List<&2, I.I>, Nat.is_eq(List.length(&2, I.I, acc), 0n), b, X.vhull(acc, b)))

def rc_st(r: Rc) -> U64:
  Rc{n, st} = r
  st

def rc_n(r: Rc) -> Nat:
  Rc{n, st} = r
  n

def rc_put(r: Rc, +inc: Bool, +s: U64) -> Rc:
  Rc{+n, st} = r
  Rc{Bool.pick(Nat, inc, Nat.add(n, 1n), n), U64.max(st, s)}

def pt_hit(+lo: F64, +hi: F64, +m: U64, +self: Bool, +e0: F64, +acc: Rc) -> Rc:
  +origin = Bool.and(self, F64.is_le(hi, e0))
  +near = F64.is_le(lo, e0)
  +skip = Bool.or(origin, U64.is_eq(m, 0u64))
  Bool.pick(Rc, skip, acc,
    Bool.pick(Rc, U64.is_eq(m, 1u64), Bool.pick(Rc, near, rc_put(acc, False{}, 1u64), rc_put(acc, True{}, 0u64)), rc_put(acc, False{}, 2u64)))

def un_hit(+hi: F64, +m: U64, +self: Bool, +e0: F64, +acc: Rc) -> Rc:
  Bool.pick(Rc, Bool.or(Bool.and(self, F64.is_le(hi, e0)), U64.is_eq(m, 0u64)), acc, rc_put(acc, False{}, 2u64))

def hit_one(h: S.Hit, +fc: Mm.Fc, +im: M.Im, +self: Bool, +e0: F64, +acc: Rc) -> Rc:
  match h:
    case S.H_pt{+s, t, +pb, c}: pt_hit(I.i_lo(s), I.i_hi(s), Mm.member(fc, pb, im), self, e0, acc)
    case S.H_un{+s, t, +pb}: un_hit(I.i_hi(s), Mm.member(fc, pb, im), self, e0, acc)
    case _: rc_put(acc, False{}, 2u64)

def hits_go(hs: List<&2, S.Hit>, +fc: Mm.Fc, +im: M.Im, +self: Bool, +e0: F64, +acc: Rc) -> Rc:
  match hs:
    case []: acc
    case h <> t: hits_go(t, fc, im, self, e0, hit_one(h, fc, im, self, e0, acc))

def seg_box(+p: V.Point, +d: V.Dir, +tmax: F64) -> List<&2, I.I>:
  +a = M.p3(p)
  X.vhull(a, X.vadd(a, Mm.vs(I.ipt(tmax), M.d3(d))))

def face_code(+f: Fd, +sb: List<&2, I.I>) -> U64:
  Bool.pick(U64, X.vdisj(fd_bx(f), sb), 0u64, Bool.pick(U64, fd_ok(f), 1u64, 2u64))

def ray_face(k: U64, +f: Fd, +p: V.Point, +d: V.Dir, +tmax: F64, +self: Bool, +e0: F64, +acc: Rc) -> Rc:
  match k:
    case 0u64: acc
    case 1u64:
      +fc = fd_fc(f)
      hits_go(S.inter_cs(G.GV_ln{G.Ln{p, d}}, G.Dom{0.0f64, tmax}, fd_g(f), 40n), fc, Mm.fc_s(fc), self, e0, acc)
    case _: rc_put(acc, False{}, 2u64)

def ray(fs: List<&2, Fd>, stop: Bool, +p: V.Point, +d: V.Dir, +tmax: F64, +sb: List<&2, I.I>, +skip: Nat, +i: Nat, +e0: F64, +acc: Rc) -> Rc:
  match fs:
    case []: acc
    case +f <> t:
      match stop:
        case True{}: acc
        case False{}:
          +r = ray_face(face_code(f, sb), f, p, d, tmax, Nat.is_eq(i, skip), e0, acc)
          ray(t, U64.is_eq(rc_st(r), 2u64), p, d, tmax, sb, skip, Nat.add(i, 1n), e0, r)

def dr(+x: F64, +y: F64, +z: F64) -> V.Dir:
  V.Dr{x, y, z}

def dirs() -> List<&2, V.Dir>:
  [dr(0.5773502691896258f64, 0.6123724356957945f64, 0.5400617248673217f64),
    dr(F64.neg(0.7071067811865476f64), 0.31622776601683794f64, 0.6324555320336759f64),
    dr(0.2182178902359924f64, F64.neg(0.8728715609439696f64), 0.4364357804719848f64),
    dr(F64.neg(0.3354101966249685f64), F64.neg(0.4472135954999579f64), F64.neg(0.8291561975888499f64)),
    dr(0.8017837257372732f64, 0.2672612419124244f64, F64.neg(0.5345224838248488f64)),
    dr(F64.neg(0.1230914909793327f64), 0.9847319278346618f64, F64.neg(0.1230914909793327f64)),
    dr(0.4264014327112209f64, F64.neg(0.4264014327112209f64), F64.neg(0.7977240352174656f64))]

def pt_of(+q: List<&2, I.I>) -> V.Point:
  V.Pt{X.imid(X.vn(q, 0n)), X.imid(X.vn(q, 1n)), X.imid(X.vn(q, 2n))}

def dr_of(+q: List<&2, I.I>) -> V.Dir:
  V.Dr{X.imid(X.vn(q, 0n)), X.imid(X.vn(q, 1n)), X.imid(X.vn(q, 2n))}

def reach(+bb: List<&2, I.I>, +p: V.Point, +d: V.Dir) -> F64:
  +w = X.vsub(bb, M.p3(p))
  +far = I.isqrt(X.vdot(w, w))
  +dd = I.isqrt(X.vdot(M.d3(d), M.d3(d)))
  F64.add(I.i_hi(I.idiv(I.ipt(I.i_hi(far)), dd)), 1.0f64)

def shoot(+fs: List<&2, Fd>, +bb: List<&2, I.I>, +p: V.Point, +d: V.Dir, +skip: Nat, +ef: F64) -> Rc:
  +tmax = reach(bb, p, d)
  ray(fs, False{}, p, d, tmax, seg_box(p, d, tmax), skip, 0n, F64.mul(tmax, ef), Rc{0n, 0u64})

def odd(+n: Nat) -> Bool:
  Nat.is_eq(Nat.mod(n, 2n), 1n)

def none_skip() -> Nat:
  1000000000n

def cl_fin(st: U64, +n: Nat) -> U64:
  match st:
    case 0u64: Bool.pick(U64, odd(n), 1u64, 0u64)
    case 1u64: 3u64
    case _: 2u64

def cl_go(ds: List<&2, V.Dir>, +st: U64, +n: Nat, +fs: List<&2, Fd>, +bb: List<&2, I.I>, +p: V.Point) -> U64:
  match ds:
    case []: cl_fin(st, n)
    case d <> t:
      match st:
        case 0u64: cl_fin(st, n)
        case 1u64: cl_fin(st, n)
        case _:
          +r = shoot(fs, bb, p, d, none_skip(), 9.094947017729282e-13f64)
          cl_go(t, rc_st(r), rc_n(r), fs, bb, p)

def dist(+s: M.Im, +p: List<&2, I.I>) -> F64:
  +v = M.im_val(s, p)
  +g = M.im_grad(s, p)
  I.i_hi(I.idiv(I.ipt(X.imag(v)), I.isqrt(X.vdot(g, g))))

def wide(xs: List<&2, I.I>, +e: F64) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t: I.iwiden(x, e) <> wide(t, e)

def near_face(+f: Fd, +p: List<&2, I.I>, +eps: F64) -> Bool:
  Bool.and(fd_ok(f), Bool.and(Bool.not(X.vdisj(fd_bx(f), wide(p, eps))), F64.is_le(dist(fd_im(f), p), eps)))

def on_one(near: Bool, +f: Fd, +p: List<&2, I.I>) -> Bool:
  match near:
    case False{}: False{}
    case True{}: Bool.not(U64.is_eq(Mm.member(fd_fc(f), p, fd_im(f)), 0u64))

def on_bd(fs: List<&2, Fd>, +p: List<&2, I.I>, +eps: F64) -> Bool:
  match fs:
    case []: False{}
    case +f <> t: Bool.or(on_one(near_face(f, p, eps), f, p), on_bd(t, p, eps))

def eps_of(+bb: List<&2, I.I>) -> F64:
  F64.mul(F64.add(X.vwid(bb), 1.0f64), 9.094947017729282e-13f64)

def cl_pick(on: Bool, +fs: List<&2, Fd>, +bb: List<&2, I.I>, +p: V.Point) -> U64:
  match on:
    case True{}: 3u64
    case False{}: cl_go(dirs(), 2u64, 0n, fs, bb, p)

def classify_in(+fs: List<&2, Fd>, +bb: List<&2, I.I>, +p: V.Point) -> U64:
  cl_pick(on_bd(fs, M.p3(p), eps_of(bb)), fs, bb, p)

def classify(+fs: List<&2, Fd>, +p: V.Point) -> U64:
  classify_in(fs, bbox(fs, []), p)

def unit(+v: List<&2, I.I>) -> List<&2, I.I>:
  Mm.vs(I.idiv(I.ipt(1.0f64), I.isqrt(X.vdot(v, v))), v)

def proj(s: M.Im, +p: List<&2, I.I>) -> List<&2, I.I>:
  match s:
    case M.M_pl{+o, +n}: X.vsub(p, Mm.vs(I.idiv(X.vdot(X.vsub(p, o), n), X.vdot(n, n)), n))
    case M.M_sp{+c, r}: X.vadd(c, Mm.vs(r, unit(X.vsub(p, c))))
    case M.M_cy{+o, +a, r}:
      +m = X.vsub(p, o)
      +f = Mm.vs(I.idiv(X.vdot(a, m), X.vdot(a, a)), a)
      X.vadd(X.vadd(o, f), Mm.vs(r, unit(X.vsub(m, f))))
    case M.M_co{+o, +a, +k}:
      +m = X.vsub(p, o)
      +h = X.vdot(a, m)
      +ah = Mm.vs(Bool.pick(I.I, X.ineg_c(h), I.ipt(F64.neg(1.0f64)), I.ipt(1.0f64)), unit(a))
      +e = unit(X.vsub(m, Mm.vs(I.idiv(h, X.vdot(a, a)), a)))
      +g = unit(X.vadd(ah, Mm.vs(k, e)))
      X.vadd(o, Mm.vs(X.vdot(m, g), g))
    case M.M_to{+o, +a, +bigr, r}:
      +m = X.vsub(p, o)
      +c = X.vadd(o, Mm.vs(bigr, unit(X.vsub(m, Mm.vs(I.idiv(X.vdot(a, m), X.vdot(a, a)), a)))))
      X.vadd(c, Mm.vs(r, unit(X.vsub(p, c))))

def snap(+q: List<&2, I.I>) -> List<&2, I.I>:
  M.p3(pt_of(q))

def cand(+k: F64, +r: List<&2, I.I>, +w: List<&2, I.I>, +fc: Mm.Fc, +im: M.Im) -> Maybe<&2, List<&2, I.I>>:
  +q = snap(proj(im, snap(X.vadd(r, Mm.vs(I.ipt(k), w)))))
  Bool.pick(Maybe<&2, List<&2, I.I>>, Bool.and(X.vfin(q), U64.is_eq(Mm.member(fc, q, im), 1u64)), Some{q}, None{})

def ip_try(ks: List<&2, F64>, +m: Maybe<&2, List<&2, I.I>>, +r: List<&2, I.I>, +w: List<&2, I.I>, +fc: Mm.Fc, +im: M.Im) -> Maybe<&2, List<&2, I.I>>:
  match ks:
    case []: m
    case k <> t:
      match m:
        case Some{q}: Some{q}
        case None{}: ip_try(t, cand(k, r, w, fc, im), r, w, fc, im)

def scales(+l: F64) -> List<&2, F64>:
  [F64.mul(l, 0.0625f64), F64.mul(l, 0.00390625f64), F64.mul(l, 0.000244140625f64), F64.mul(l, 1.52587890625e-05f64)]

def ip_edge(+e: Mm.Er, +fc: Mm.Fc, +im: M.Im) -> Maybe<&2, List<&2, I.I>>:
  +c = Mm.er_c(e)
  +r = snap(R.cv_box(c, I.ipt(0.5f64)))
  +tl = Mm.neg_if(Mm.er_fwd(e), R.cv_der(c, I.ipt(0.5f64)))
  +nf = Mm.neg_if(Mm.fc_same(fc), M.im_grad(im, r))
  +w = unit(M.cross(nf, tl))
  +l = X.vwid(R.cv_hbox(c))
  Bool.pick(Maybe<&2, List<&2, I.I>>, X.vfin(w), ip_try(scales(l), None{}, r, w, fc, im), None{})

def ip_es(es: List<&2, Mm.Er>, +m: Maybe<&2, List<&2, I.I>>, +fc: Mm.Fc, +im: M.Im) -> Maybe<&2, List<&2, I.I>>:
  match es:
    case []: m
    case e <> t:
      match m:
        case Some{q}: Some{q}
        case None{}: ip_es(t, ip_edge(e, fc, im), fc, im)

def ip_ok(ok: Bool, +fc: Mm.Fc, +im: M.Im) -> Maybe<&2, List<&2, I.I>>:
  match ok:
    case True{}: ip_es(Mm.fc_es(fc), None{}, fc, im)
    case False{}: None{}

def interior(+f: Fd) -> Maybe<&2, List<&2, I.I>>:
  +fc = fd_fc(f)
  ip_ok(fd_ok(f), fc, fd_im(f))

def ip_mk(m: Maybe<&2, List<&2, I.I>>, +i: Nat, +f: Fd) -> Maybe<&2, Ip>:
  match m:
    case None{}: None{}
    case Some{+q}: Some{Ip{i, q, Mm.neg_if(Mm.fc_same(fd_fc(f)), M.im_grad(fd_im(f), q))}}

def ip_sel(ok: Bool, +f: Fd, +i: Nat) -> Maybe<&2, Ip>:
  match ok:
    case True{}: ip_mk(interior(f), i, f)
    case False{}: None{}

def ip_find(fs: List<&2, Fd>, +m: Maybe<&2, Ip>, +s: Nat, +i: Nat) -> Maybe<&2, Ip>:
  match fs:
    case []: m
    case +f <> t:
      match m:
        case Some{x}: Some{x}
        case None{}: ip_find(t, ip_sel(Nat.is_eq(fd_sh(f), s), f, i), s, Nat.add(i, 1n))

def off_dir(+n: List<&2, I.I>, +g: V.Dir) -> List<&2, I.I>:
  X.vadd(unit(n), Mm.vs(I.ipt(0.25f64), M.d3(g)))

def or_shot(ok: Bool, +fs: List<&2, Fd>, +bb: List<&2, I.I>, +p: V.Point, +d: V.Dir, +i: Nat) -> Rc:
  match ok:
    case True{}: shoot(fs, bb, p, d, i, 9.313225746154785e-10f64)
    case False{}: Rc{0n, 2u64}

def or_fin(st: U64, +n: Nat) -> U64:
  match st:
    case 0u64: Bool.pick(U64, odd(n), 0u64, 1u64)
    case _: 2u64

def or_go(ds: List<&2, V.Dir>, +st: U64, +n: Nat, +fs: List<&2, Fd>, +bb: List<&2, I.I>, +ip: Ip) -> U64:
  match ds:
    case []: or_fin(st, n)
    case g <> t:
      match st:
        case 0u64: or_fin(st, n)
        case _:
          Ip{+i, +q, +nv} = ip
          +d = dr_of(off_dir(nv, g))
          +ok = X.ipos(X.vdot(M.d3(d), nv))
          +r = or_shot(ok, fs, bb, pt_of(q), d, i)
          or_go(t, rc_st(r), rc_n(r), fs, bb, Ip{i, q, nv})

def orient_of(m: Maybe<&2, Ip>, +fs: List<&2, Fd>, +bb: List<&2, I.I>) -> U64:
  match m:
    case None{}: 2u64
    case Some{ip}: or_go(dirs(), 2u64, 0n, fs, bb, ip)

def orient(+fs: List<&2, Fd>, +bb: List<&2, I.I>, +s: Nat) -> U64:
  orient_of(ip_find(fs, None{}, s, 0n), fs, bb)

def or_all(n: Nat, +fs: List<&2, Fd>, +bb: List<&2, I.I>, +s: Nat) -> List<&2, Fi>:
  match n:
    case 0n: []
    case 1n+m:
      +r = orient(fs, bb, s)
      +rest = or_all(m, fs, bb, Nat.add(s, 1n))
      Bool.pick(List<&2, Fi>, U64.is_eq(r, 1u64), rest, Fi{Bool.pick(String, U64.is_eq(r, 0u64), "inverted-shell", "orientation-uncertain"), s, 0n} <> rest)

def of_sh(fs: List<&2, Fd>, +s: Nat) -> List<&2, Fd>:
  match fs:
    case []: []
    case +f <> +t: Bool.pick(List<&2, Fd>, Nat.is_eq(fd_sh(f), s), f <> of_sh(t, s), of_sh(t, s))

def hs_idx(h: Ty.HShell) -> Nat:
  Ty.HS{i, g} = h
  i

def ip_q(m: Maybe<&2, Ip>) -> Maybe<&2, List<&2, I.I>>:
  match m:
    case None{}: None{}
    case Some{x}:
      Ip{i, q, n} = x
      Some{q}

def nest_one(m: Maybe<&2, List<&2, I.I>>, +fs: List<&2, Fd>, +bb: List<&2, I.I>, +s: Nat, +want: U64) -> U64:
  match m:
    case None{}: 2u64
    case Some{q}:
      +r = classify_in(fs, bb, pt_of(q))
      Bool.pick(U64, U64.is_eq(r, want), 1u64, Bool.pick(U64, Bool.or(U64.is_eq(r, 0u64), U64.is_eq(r, 1u64)), 0u64, 2u64))

def nest_fi(+r: U64, +bad: String, +a: Nat, +b: Nat) -> List<&2, Fi>:
  Bool.pick(List<&2, Fi>, U64.is_eq(r, 1u64), [], [Fi{Bool.pick(String, U64.is_eq(r, 0u64), bad, "nesting-uncertain"), a, b}])

def cav_vs(cs: List<&2, Ty.HShell>, +fs: List<&2, Fd>, +c: Nat) -> List<&2, Fi>:
  match cs:
    case []: []
    case h <> t:
      +d = hs_idx(h)
      +rest = cav_vs(t, fs, c)
      +sub = of_sh(fs, d)
      +q = ip_q(ip_find(fs, None{}, c, 0n))
      Bool.pick(List<&2, Fi>, Nat.is_eq(d, c), rest, List.append(&2, Fi, nest_fi(nest_one(q, sub, bbox(sub, []), d, 0u64), "cavities-nested", c, d), rest))

def cav_go(cs: List<&2, Ty.HShell>, +all: List<&2, Ty.HShell>, +fs: List<&2, Fd>, +o: Nat) -> List<&2, Fi>:
  match cs:
    case []: []
    case h <> t:
      +c = hs_idx(h)
      +out = of_sh(fs, o)
      +q = ip_q(ip_find(fs, None{}, c, 0n))
      List.append(&2, Fi, nest_fi(nest_one(q, out, bbox(out, []), o, 1u64), "cavity-outside", c, o),
        List.append(&2, Fi, cav_vs(all, fs, c), cav_go(t, all, fs, o)))

def so_nest(s: Ty.Solid, +fs: List<&2, Fd>) -> List<&2, Fi>:
  Ty.So{g, o, +cs} = s
  cav_go(cs, cs, fs, hs_idx(o))

def sos_nest(ss: List<&2, Ty.Solid>, +fs: List<&2, Fd>) -> List<&2, Fi>:
  match ss:
    case []: []
    case s <> t: List.append(&2, Fi, so_nest(s, fs), sos_nest(t, fs))

def solid_fi(+b: Ty.Brep, +fs: List<&2, Fd>) -> List<&2, Fi>:
  +bb = bbox(fs, [])
  List.append(&2, Fi, or_all(List.length(&2, Ty.Shell, Ty.brep_shs(b)), fs, bb, 0n), sos_nest(Ty.brep_sos(b), fs))

def fd_dflt() -> Fd:
  Fd{Mm.Fc{M.M_pl{[], []}, True{}, []}, [], [], False{}, 0n}
