import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c06/iv.bend as I
import ./ivx.bend as X
import ./rb.bend as R
import ./im.bend as M
import ./eng.bend as N
import ../k1/sf.bend as KS






type Er is Data:
  Er{ c: R.Cv, fwd: Bool }






type Sg is Data:
  Sg{ t0: F64, h0: F64, t1: F64, h1: F64 }






type Uv is Data:
  Uv_no{}
  Uv_cy{ sf: KS.SF, r: F64, segs: List<&2, Sg>, tol: F64 }
  Uv_bp{ sf: KS.SF, segs: List<&2, Sg>, s3: List<&2, S3>, tol: F64 }
  Uv_to{ sf: KS.SF, ur: F64, vr: F64, segs: List<&2, Sg>, s3: List<&2, S3>, tol: F64 }






type S3 is Data:
  S3{ a: V.Point, b: V.Point }






type Sb is Data:
  Sb{ gs: List<&2, Sg>, g3: List<&2, S3>, dev: F64 }






type Fc is Data:
  Fc{ s: M.Im, same: Bool, es: List<&2, Er>, uv: Uv }






type Ax is Data:
  Ax{ o: List<&2, I.I>, a: List<&2, I.I> }






type Lg is Data:
  L_seg{ cut: M.Im, q: List<&2, I.I>, r: List<&2, I.I> }
  L_mer{ cut: M.Im, ax: Ax, mq: List<&2, I.I>, h1: I.I, h2: I.I }
  L_tube{ cut: M.Im, ax: Ax, mq: List<&2, I.I>, cq: List<&2, I.I>, wq: List<&2, I.I>, wr: List<&2, I.I>, b: List<&2, I.I> }
  L_par{ cut: M.Im, ax: Ax, mq: List<&2, I.I>, mr: List<&2, I.I>, br: U64, rr: I.I }






type Cn is Data:
  Cn{ n: Nat, u: Bool }






type Lp is Data:
  Lp{ ls: List<&2, Lg>, d: List<&2, I.I>, ok: Bool }






type Sa is Data:
  Sa{ gs: List<&2, Sg>, dev: F64 }




type Cm is Data:
  Cm{ su: F64, cu: F64, sv: F64, cv: F64 }

def vs(+s: I.I, xs: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t: I.imul(s, x) <> vs(s, t)

def sgn(+a: I.I) -> U64:
  Bool.pick(U64, X.ipos(a), 1u64, Bool.pick(U64, X.ineg_c(a), 2u64, 0u64))

def tri(+c: Bool, +o: Bool) -> U64:
  Bool.pick(U64, c, 1u64, Bool.pick(U64, o, 0u64, 2u64))

def both(+a: U64, +b: U64) -> U64:
  Bool.pick(U64, Bool.or(U64.is_eq(a, 0u64), U64.is_eq(b, 0u64)), 0u64, Bool.pick(U64, Bool.and(U64.is_eq(a, 1u64), U64.is_eq(b, 1u64)), 1u64, 2u64))

def ax_o(x: Ax) -> List<&2, I.I>:
  Ax{o, a} = x
  o

def ax_a(x: Ax) -> List<&2, I.I>:
  Ax{o, a} = x
  a

def radial(+x: Ax, +p: List<&2, I.I>) -> List<&2, I.I>:
  +a = ax_a(x)
  +m = X.vsub(p, ax_o(x))
  X.vsub(vs(X.vdot(a, a), m), vs(X.vdot(a, m), a))

def height(+x: Ax, +p: List<&2, I.I>) -> I.I:
  X.vdot(ax_a(x), X.vsub(p, ax_o(x)))

def arc_in(+mq: List<&2, I.I>, +mr: List<&2, I.I>, +mp: List<&2, I.I>, +a: List<&2, I.I>) -> U64:
  +c1 = sgn(X.vdot(M.cross(mq, mp), a))
  +c2 = sgn(X.vdot(M.cross(mp, mr), a))
  +c3 = sgn(X.vdot(M.cross(mq, mr), a))
  Bool.pick(U64, U64.is_eq(c3, 1u64),
    tri(Bool.and(U64.is_eq(c1, 1u64), U64.is_eq(c2, 1u64)), Bool.or(U64.is_eq(c1, 2u64), U64.is_eq(c2, 2u64))),
    Bool.pick(U64, U64.is_eq(c3, 2u64),
      tri(Bool.or(U64.is_eq(c1, 1u64), U64.is_eq(c2, 1u64)), Bool.and(U64.is_eq(c1, 2u64), U64.is_eq(c2, 2u64))),
      2u64))

def between(+h: I.I, +h1: I.I, +h2: I.I) -> U64:
  +lo = F64.min(I.i_lo(h1), I.i_lo(h2))
  +hi = F64.max(I.i_hi(h1), I.i_hi(h2))
  +inside = Bool.or(Bool.and(F64.is_lt(I.i_hi(h1), I.i_lo(h)), F64.is_lt(I.i_hi(h), I.i_lo(h2))),
    Bool.and(F64.is_lt(I.i_hi(h2), I.i_lo(h)), F64.is_lt(I.i_hi(h), I.i_lo(h1))))
  tri(inside, Bool.or(F64.is_lt(I.i_hi(h), lo), F64.is_lt(hi, I.i_lo(h))))

def side_ok(+x: Ax, +mq: List<&2, I.I>, +p: List<&2, I.I>) -> U64:
  +s = sgn(X.vdot(radial(x, p), mq))
  Bool.pick(U64, U64.is_eq(s, 1u64), 1u64, Bool.pick(U64, U64.is_eq(s, 2u64), 0u64, 2u64))

def sq(+v: List<&2, I.I>) -> I.I:
  X.vdot(v, v)

def lg_cut(l: Lg) -> M.Im:
  match l:
    case L_seg{c, q, r}: c
    case L_mer{c, x, m, a, b}: c
    case L_tube{c, x, m, cq, wq, wr, b}: c
    case L_par{c, x, mq, mr, br, rr}: c

def pred(l: Lg, +p: List<&2, I.I>) -> U64:
  match l:
    case L_seg{c, +q, +r}:
      +d = X.vsub(r, q)
      +s = I.idiv(X.vdot(X.vsub(p, q), d), sq(d))
      tri(Bool.and(X.ipos(s), F64.is_lt(I.i_hi(s), 1.0f64)), Bool.or(X.ineg_c(s), F64.is_lt(1.0f64, I.i_lo(s))))
    case L_mer{c, +x, +mq, h1, h2}: both(side_ok(x, mq, p), between(height(x, p), h1, h2))
    case L_tube{c, +x, +mq, +cq, wq, wr, b}: both(side_ok(x, mq, p), arc_in(wq, wr, X.vsub(p, cq), b))
    case L_par{c, +x, mq, mr, +br, +rr}:
      +rad = radial(x, p)
      +bs = sgn(I.isub(sq(rad), rr))
      both(arc_in(mq, mr, rad, ax_a(x)), Bool.pick(U64, U64.is_eq(br, 0u64), 1u64, tri(U64.is_eq(bs, br), Bool.and(Bool.not(U64.is_eq(bs, 0u64)), Bool.not(U64.is_eq(bs, br))))))

def mk_ci(+c: R.Cv, +s: M.Im) -> N.Pb:
  N.P_ci{c, s}

def cn_add(acc: Cn, +k: U64) -> Cn:
  Cn{+n, u} = acc
  Cn{Bool.pick(Nat, U64.is_eq(k, 1u64), Nat.add(n, 1n), n), Bool.or(u, U64.is_eq(k, 2u64))}

def is_r(+self: Bool, +tau: F64, +k: List<&2, I.I>) -> Bool:
  Bool.and(self, Bool.not(X.idisj(X.vn(k, 0n), I.ipt(tau))))

def cv_closed(+c: R.Cv) -> Bool:
  Bool.not(X.vdisj(R.cv_box(c, I.ipt(0.0f64)), R.cv_box(c, I.ipt(1.0f64))))

def k_end1(+k: List<&2, I.I>) -> Bool:
  +t = X.vn(k, 0n)
  Bool.and(F64.is_le(I.i_lo(t), 1.0f64), F64.is_le(1.0f64, I.i_hi(t)))

def k_end(+k: List<&2, I.I>) -> Bool:
  +t = X.vn(k, 0n)
  Bool.or(F64.is_le(I.i_lo(t), 0.0f64), F64.is_le(1.0f64, I.i_hi(t)))

def end_code(+e: Bool, +m: U64) -> U64:
  Bool.pick(U64, Bool.and(e, U64.is_eq(m, 1u64)), 2u64, m)

def skip_seam(+c: R.Cv, +k: List<&2, I.I>) -> Bool:
  Bool.and(cv_closed(c), k_end1(k))

def rt_add(skip: Bool, pt: Bool, +c: R.Cv, +l: Lg, +k: List<&2, I.I>, +acc: Cn) -> Cn:
  match skip:
    case True{}: acc
    case False{}:
      match pt:
        case True{}: cn_add(acc, end_code(k_end(k), pred(l, R.cv_box(c, X.vn(k, 0n)))))
        case False{}: cn_add(acc, Bool.pick(U64, U64.is_eq(pred(l, R.cv_box(c, X.vn(k, 0n))), 0u64), 0u64, 2u64))

def roots_go(rs: List<&2, N.Res>, +c: R.Cv, +l: Lg, +self: Bool, +tau: F64, +acc: Cn) -> Cn:
  match rs:
    case []: acc
    case r <> +t:
      match r:
        case N.R_pt{+k}: roots_go(t, c, l, self, tau, rt_add(Bool.or(is_r(self, tau, k), skip_seam(c, k)), True{}, c, l, k, acc))
        case N.R_un{+k}: roots_go(t, c, l, self, tau, rt_add(Bool.or(is_r(self, tau, k), skip_seam(c, k)), False{}, c, l, k, acc))
        case _: roots_go(t, c, l, self, tau, acc)

def flat_go(xs: List<&2, I.I>, ys: List<&2, I.I>, zs: List<&2, I.I>, ws: List<&2, I.I>, +o: List<&2, I.I>, +n: List<&2, I.I>) -> Bool:
  match xs:
    case []: True{}
    case x <> xt:
      match ys:
        case []: True{}
        case y <> yt:
          match zs:
            case []: True{}
            case z <> zt:
              match ws:
                case []: True{}
                case +w <> wt:
                  +f = X.vdot(n, X.vsub([x, y, z], vs(w, o)))
                  Bool.and(X.has0(f), flat_go(xt, yt, zt, wt, o, n))

def flat_rb(r: R.Rb, +o: List<&2, I.I>, +n: List<&2, I.I>) -> Bool:
  R.Rb{x, y, z, w} = r
  flat_go(x, y, z, w, o, n)

def flat(+c: R.Cv, s: M.Im) -> Bool:
  match s:
    case M.M_pl{+o, +n}: flat_rb(R.cv_rb(c), o, n)
    case _: False{}

def cn_n(c: Cn) -> Nat:
  Cn{n, u} = c
  n

def opp_side(l: Lg, +c: R.Cv) -> Bool:
  match l:
    case L_mer{k, +x, +mq, h1, h2}: U64.is_eq(sgn(X.vdot(radial(x, R.cv_box(c, I.I{0.0f64, 1.0f64})), mq)), 2u64)
    case L_tube{k, +x, +mq, cq, wq, wr, b}: U64.is_eq(sgn(X.vdot(radial(x, R.cv_box(c, I.I{0.0f64, 1.0f64})), mq)), 2u64)
    case _: False{}

def edge_cn(fl: Bool, +c: R.Cv, +l: Lg, +self: Bool, +tau: F64, +acc: Cn) -> Cn:
  match fl:
    case True{}: Bool.pick(Cn, opp_side(l, c), acc, Cn{cn_n(acc), True{}})
    case False{}: roots_go(N.solve_ew(40n, 4096u64, mk_ci(c, lg_cut(l)), [I.I{0.0f64, 1.0f64}]), c, l, self, tau, acc)

def count_go(es: List<&2, Er>, +l: Lg, +ri: Nat, +tau: F64, +i: Nat, +acc: Cn) -> Cn:
  match es:
    case []: acc
    case e <> t:
      Er{+c, f} = e
      count_go(t, l, ri, tau, Nat.add(i, 1n), edge_cn(flat(c, lg_cut(l)), c, l, Nat.is_eq(i, ri), tau, acc))

def er_at(es: List<&2, Er>, +i: Nat) -> Er:
  match es:
    case []: Er{R.Cv{R.Rb{[], [], [], []}, 0.0f64, 1.0f64}, True{}}
    case e <> t:
      match i:
        case 0n: e
        case 1n+j: er_at(t, j)

def er_c(e: Er) -> R.Cv:
  Er{c, f} = e
  c

def er_fwd(e: Er) -> Bool:
  Er{c, f} = e
  f

def neg_if(+b: Bool, +v: List<&2, I.I>) -> List<&2, I.I>:
  Bool.pick(List<&2, I.I>, b, v, vs(I.ipt(F64.neg(1.0f64)), v))

def arrive(+d: List<&2, I.I>, +nf: List<&2, I.I>, +tl: List<&2, I.I>) -> U64:
  +s = sgn(X.vdot(d, M.cross(nf, tl)))
  Bool.pick(U64, U64.is_eq(s, 2u64), 1u64, Bool.pick(U64, U64.is_eq(s, 1u64), 0u64, 2u64))

def parity(+n: Nat, +b: U64) -> U64:
  +odd = Nat.is_eq(Nat.mod(n, 2n), 1n)
  Bool.pick(U64, odd, Bool.pick(U64, U64.is_eq(b, 1u64), 0u64, 1u64), b)

def total(ls: List<&2, Lg>, +es: List<&2, Er>, +ri: Nat, +tau: F64, +acc: Cn) -> Cn:
  match ls:
    case []: acc
    case l <> t: total(t, es, ri, tau, count_go(es, l, ri, tau, 0n, acc))

def finish(+c: Cn, +arr: U64) -> U64:
  Cn{n, u} = c
  Bool.pick(U64, Bool.or(u, U64.is_eq(arr, 2u64)), 2u64, parity(n, arr))

def nz(+v: List<&2, I.I>) -> Bool:
  X.ipos(sq(v))

def leg1(tor: Bool, +o: List<&2, I.I>, +b: List<&2, I.I>, +x: Ax, +mq: List<&2, I.I>, +cq: List<&2, I.I>, +wq: List<&2, I.I>, +wr: List<&2, I.I>, +hq: I.I, +hr: I.I) -> Lg:
  match tor:
    case True{}: L_tube{M.M_pl{o, b}, x, mq, cq, wq, wr, b}
    case False{}: L_mer{M.M_pl{o, b}, x, mq, hq, hr}

def leg2(+rp: List<&2, I.I>, +a: List<&2, I.I>, +x: Ax, +mq: List<&2, I.I>, +mr: List<&2, I.I>, +br: U64, +rr: I.I) -> Lg:
  L_par{M.M_pl{rp, a}, x, mq, mr, br, rr}

def ax_fwd(+x: Ax, +q: List<&2, I.I>, +rp: List<&2, I.I>, +tor: Bool, +bigr: I.I) -> Lp:
  +a = ax_a(x)
  +o = ax_o(x)
  +aa = X.vdot(a, a)
  +mq = radial(x, q)
  +mr = radial(x, rp)
  +hq = height(x, q)
  +hr = height(x, rp)
  +nq = I.isqrt(sq(mq))
  +uq = vs(I.idiv(I.ipt(1.0f64), nq), mq)
  +cq = X.vadd(o, vs(bigr, uq))
  +rho = I.idiv(I.isqrt(sq(mr)), aa)
  +wr = X.vadd(vs(I.isub(rho, bigr), uq), vs(I.idiv(hr, aa), a))
  +rr = I.imul(I.isq(aa), I.isq(bigr))
  +b = M.cross(a, mq)
  +l1 = leg1(tor, o, b, x, mq, cq, X.vsub(q, cq), wr, hq, hr)
  +l2 = leg2(rp, a, x, mq, mr, Bool.pick(U64, tor, sgn(I.isub(sq(mr), rr)), 0u64), rr)
  +ok = Bool.and(Bool.and(nz(mq), nz(mr)), Bool.not(U64.is_eq(sgn(X.vdot(M.cross(mq, mr), a)), 0u64)))
  Lp{[l1, l2], M.cross(a, mr), ok}

def sph_axis(+q: List<&2, I.I>, +c: List<&2, I.I>) -> List<&2, I.I>:
  +w = X.vsub(q, c)
  +x = X.imag(X.vn(w, 0n))
  +y = X.imag(X.vn(w, 1n))
  +z = X.imag(X.vn(w, 2n))
  Bool.pick(List<&2, I.I>, Bool.and(F64.is_le(z, x), F64.is_le(z, y)), [I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(1.0f64)],
    Bool.pick(List<&2, I.I>, F64.is_le(y, x), [I.ipt(0.0f64), I.ipt(1.0f64), I.ipt(0.0f64)], [I.ipt(1.0f64), I.ipt(0.0f64), I.ipt(0.0f64)]))

def sph_ax_k(+q: List<&2, I.I>, +c: List<&2, I.I>, +k: Nat) -> List<&2, I.I>:
  match k:
    case 0n: sph_axis(q, c)
    case 1n: [I.ipt(1.0f64), I.ipt(0.0f64), I.ipt(0.0f64)]
    case 2n: [I.ipt(0.0f64), I.ipt(1.0f64), I.ipt(0.0f64)]
    case 3n: [I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(1.0f64)]
    case _: [I.ipt(1.0f64), I.ipt(1.0f64), I.ipt(1.0f64)]

def mer_dir(tor: Bool, +nr: List<&2, I.I>, +b: List<&2, I.I>, +wr: List<&2, I.I>, +a: List<&2, I.I>, +dh: I.I) -> List<&2, I.I>:
  match tor:
    case True{}: M.cross(b, wr)
    case False{}:
      +t = M.cross(nr, b)
      vs(Bool.pick(I.I, X.ipos(I.imul(X.vdot(t, a), dh)), I.ipt(1.0f64), I.ipt(F64.neg(1.0f64))), t)

def ax_rev(+x: Ax, +q: List<&2, I.I>, +rp: List<&2, I.I>, +tor: Bool, +bigr: I.I, +nf: M.Im) -> Lp:
  +a = ax_a(x)
  +o = ax_o(x)
  +aa = X.vdot(a, a)
  +mq = radial(x, q)
  +mr = radial(x, rp)
  +hq = height(x, q)
  +hr = height(x, rp)
  +ur = vs(I.idiv(I.ipt(1.0f64), I.isqrt(sq(mr))), mr)
  +cr = X.vadd(o, vs(bigr, ur))
  +rho = I.idiv(I.isqrt(sq(mq)), aa)
  +wq = X.vadd(vs(I.isub(rho, bigr), ur), vs(I.idiv(hq, aa), a))
  +wr = X.vsub(rp, cr)
  +rr = I.imul(I.isq(aa), I.isq(bigr))
  +b = M.cross(a, mr)
  +dh = I.isub(hr, hq)
  +l1 = leg2(q, a, x, mq, mr, Bool.pick(U64, tor, sgn(I.isub(sq(mq), rr)), 0u64), rr)
  +l2 = leg1(tor, o, b, x, mr, cr, wq, wr, hq, hr)
  +ok = Bool.and(Bool.and(nz(mq), nz(mr)), Bool.and(Bool.not(U64.is_eq(sgn(X.vdot(M.cross(mq, mr), a)), 0u64)), Bool.or(tor, Bool.not(U64.is_eq(sgn(dh), 0u64)))))
  Lp{[l1, l2], mer_dir(tor, M.im_grad(nf, rp), b, wr, a, dh), ok}

def ax_legs(+x: Ax, +q: List<&2, I.I>, +rp: List<&2, I.I>, +tor: Bool, +bigr: I.I, rev: Bool, +nf: M.Im) -> Lp:
  match rev:
    case False{}: ax_fwd(x, q, rp, tor, bigr)
    case True{}: ax_rev(x, q, rp, tor, bigr, nf)

def legs_of(s: M.Im, +q: List<&2, I.I>, +rp: List<&2, I.I>, +rev: Bool, +nf: M.Im, +k: Nat) -> Lp:
  match s:
    case M.M_pl{o, +n}:
      +d = X.vsub(rp, q)
      Lp{[L_seg{M.M_pl{q, M.cross(d, n)}, q, rp}], d, Bool.and(Bool.not(rev), nz(d))}
    case M.M_cy{o, a, r}: ax_legs(Ax{o, a}, q, rp, False{}, I.ipt(0.0f64), rev, nf)
    case M.M_co{o, a, k}: ax_legs(Ax{o, a}, q, rp, False{}, I.ipt(0.0f64), rev, nf)
    case M.M_sp{+c, r}: ax_legs(Ax{c, sph_ax_k(q, c, k)}, q, rp, False{}, I.ipt(0.0f64), rev, nf)
    case M.M_to{o, a, bigr, r}: ax_legs(Ax{o, a}, q, rp, True{}, bigr, rev, nf)
    case M.M_no{}: Lp{[], [], False{}}

def lp_ls(l: Lp) -> List<&2, Lg>:
  Lp{ls, d, ok} = l
  ls

def lp_d(l: Lp) -> List<&2, I.I>:
  Lp{ls, d, ok} = l
  d

def lp_ok(l: Lp) -> Bool:
  Lp{ls, d, ok} = l
  ok

def try_go(ok: Bool, +lp: Lp, +es: List<&2, Er>, +i: Nat, +tau: F64, +nrm: List<&2, I.I>, +tl: List<&2, I.I>) -> U64:
  match ok:
    case False{}: 2u64
    case True{}: finish(total(lp_ls(lp), es, i, tau, Cn{0n, False{}}), arrive(lp_d(lp), nrm, tl))

def try_r(+f: Fc, +q: List<&2, I.I>, +nf: M.Im, +i: Nat, +tau: F64, +rev: Bool, +k: Nat) -> U64:
  Fc{s, +same, +es, uv} = f
  +e = er_at(es, i)
  +c = er_c(e)
  +rp = R.cv_box(c, I.ipt(tau))
  +lp = legs_of(s, q, rp, rev, nf, k)
  +nrm = neg_if(same, M.im_grad(nf, rp))
  +tl = neg_if(er_fwd(e), R.cv_der(c, I.ipt(tau)))
  try_go(lp_ok(lp), lp, es, i, tau, nrm, tl)

def tau_of(+j: Nat) -> F64:
  +k = Nat.mod(j, 3n)
  Bool.pick(F64, Nat.is_eq(k, 0n), 0.5f64, Bool.pick(F64, Nat.is_eq(k, 1n), 0.3125f64, 0.6875f64))

def mem_go(n: Nat, +st: U64, +f: Fc, +q: List<&2, I.I>, +nf: M.Im, +j: Nat, +k: Nat) -> U64:
  match n:
    case 0n: st
    case 1n+m:
      match st:
        case 2u64: mem_go(m, try_r(f, q, nf, Nat.div(j, 6n), tau_of(Nat.div(j, 2n)), Nat.is_eq(Nat.mod(j, 2n), 1n), k), f, q, nf, Nat.add(j, 1n), k)
        case _: st

def fc_es(f: Fc) -> List<&2, Er>:
  Fc{s, same, es, uv} = f
  es

def fc_same(f: Fc) -> Bool:
  Fc{s, same, es, uv} = f
  same

def fc_s(f: Fc) -> M.Im:
  Fc{s, same, es, uv} = f
  s

def fc_uv(f: Fc) -> Uv:
  Fc{s, same, es, uv} = f
  uv

def uv_has(u: Uv) -> Bool:
  match u:
    case Uv_no{}: False{}
    case Uv_cy{sf, r, segs, tol}: True{}
    case Uv_bp{sf, segs, s3, tol}: True{}
    case Uv_to{sf, ur, vr, segs, s3, tol}: True{}

def two_pi() -> F64:
  6.283185307179586f64

def sg_h(+g: Sg, +t: F64) -> F64:
  Sg{+t0, +h0, +t1, +h1} = g
  F64.add(h0, F64.mul(F64.div(F64.sub(t, t0), F64.sub(t1, t0)), F64.sub(h1, h0)))

def sg_spans(+g: Sg, +t: F64) -> Bool:
  Sg{+t0, h0, +t1, h1} = g
  Bool.or(Bool.and(F64.is_le(t0, t), F64.is_lt(t, t1)), Bool.and(F64.is_le(t1, t), F64.is_lt(t, t0)))

def sg_cross1(+g: Sg, +t: F64, +h: F64) -> Nat:
  Bool.pick(Nat, Bool.and(sg_spans(g, t), F64.is_lt(h, sg_h(g, t))), 1n, 0n)

def sg_cross(+g: Sg, +t: F64, +h: F64) -> Nat:
  Nat.add(sg_cross1(g, F64.sub(t, two_pi()), h), Nat.add(sg_cross1(g, t, h), sg_cross1(g, F64.add(t, two_pi()), h)))

def sg_dist1(+g: Sg, +r: F64, +t: F64, +h: F64) -> F64:
  Sg{+t0, +h0, +t1, +h1} = g
  +ax = F64.mul(r, t0)
  +bx = F64.mul(r, t1)
  +px = F64.mul(r, t)
  +dx = F64.sub(bx, ax)
  +dy = F64.sub(h1, h0)
  +l2 = F64.add(F64.mul(dx, dx), F64.mul(dy, dy))
  +s = F64.max(0.0f64, F64.min(1.0f64, F64.div(F64.add(F64.mul(F64.sub(px, ax), dx), F64.mul(F64.sub(h, h0), dy)), F64.max(l2, 1.0e-300f64))))
  +ex = F64.sub(px, F64.add(ax, F64.mul(s, dx)))
  +ey = F64.sub(h, F64.add(h0, F64.mul(s, dy)))
  F64.sqrt(F64.add(F64.mul(ex, ex), F64.mul(ey, ey)))

def sg_dist(+g: Sg, +r: F64, +t: F64, +h: F64) -> F64:
  F64.min(sg_dist1(g, r, F64.sub(t, two_pi()), h), F64.min(sg_dist1(g, r, t, h), sg_dist1(g, r, F64.add(t, two_pi()), h)))

def uv_scan(gs: List<&2, Sg>, +t: F64, +h: F64, +n: Nat) -> Nat:
  match gs:
    case []: n
    case +g <> +rest: uv_scan(rest, t, h, Nat.add(n, sg_cross(g, t, h)))

def uv_fin(+n: Nat, +d: F64, +tol: F64) -> U64:
  Bool.pick(U64, F64.is_lt(d, tol), 2u64, Bool.pick(U64, Nat.is_eq(Nat.mod(n, 2n), 1n), 1u64, 0u64))

def uv_scan_d(gs: List<&2, Sg>, +r: F64, +t: F64, +h: F64, +d: F64) -> F64:
  match gs:
    case []: d
    case +g <> +rest: uv_scan_d(rest, r, t, h, F64.min(d, sg_dist(g, r, t, h)))

def q_mid(+q: List<&2, I.I>) -> V.Point:
  V.Pt{I.imid(X.vn(q, 0n)), I.imid(X.vn(q, 1n)), I.imid(X.vn(q, 2n))}

def uv_mem_w(+w: V.Vec2, +r: F64, +segs: List<&2, Sg>, +tol: F64) -> U64:
  +t = V.v2_x(w)
  +h = V.v2_y(w)
  uv_fin(uv_scan(segs, F64.add(t, F64.div(F64.mul(0.5f64, tol), r)), h, 0n), uv_scan_d(segs, r, t, h, F64.div(1.0f64, 0.0f64)), tol)

def np_cross(+g: Sg, +t: F64, +h: F64) -> Nat:
  sg_cross1(g, t, h)

def np_scan(gs: List<&2, Sg>, +t: F64, +h: F64, +n: Nat) -> Nat:
  match gs:
    case []: n
    case +g <> +rest: np_scan(rest, t, h, Nat.add(n, np_cross(g, t, h)))

def p3d(+a: V.Point, +b: V.Point) -> F64:
  +x = F64.sub(V.pt_x(a), V.pt_x(b))
  +y = F64.sub(V.pt_y(a), V.pt_y(b))
  +z = F64.sub(V.pt_z(a), V.pt_z(b))
  F64.sqrt(F64.add(F64.mul(x, x), F64.add(F64.mul(y, y), F64.mul(z, z))))

def p3lerp(+a: V.Point, +b: V.Point, +s: F64) -> V.Point:
  V.Pt{F64.add(V.pt_x(a), F64.mul(s, F64.sub(V.pt_x(b), V.pt_x(a)))), F64.add(V.pt_y(a), F64.mul(s, F64.sub(V.pt_y(b), V.pt_y(a)))),
    F64.add(V.pt_z(a), F64.mul(s, F64.sub(V.pt_z(b), V.pt_z(a))))}

def s3_dist(+g: S3, +p: V.Point) -> F64:
  S3{+a, +b} = g
  +dx = F64.sub(V.pt_x(b), V.pt_x(a))
  +dy = F64.sub(V.pt_y(b), V.pt_y(a))
  +dz = F64.sub(V.pt_z(b), V.pt_z(a))
  +l2 = F64.add(F64.mul(dx, dx), F64.add(F64.mul(dy, dy), F64.mul(dz, dz)))
  +w = F64.add(F64.mul(F64.sub(V.pt_x(p), V.pt_x(a)), dx), F64.add(F64.mul(F64.sub(V.pt_y(p), V.pt_y(a)), dy),
    F64.mul(F64.sub(V.pt_z(p), V.pt_z(a)), dz)))
  p3d(p, p3lerp(a, b, F64.max(0.0f64, F64.min(1.0f64, F64.div(w, F64.max(l2, 1.0e-300f64))))))

def s3_scan(gs: List<&2, S3>, +p: V.Point, +d: F64) -> F64:
  match gs:
    case []: d
    case +g <> +rest: s3_scan(rest, p, F64.min(d, s3_dist(g, p)))

def q_rad(+q: List<&2, I.I>) -> F64:
  +x = X.iwid(X.vn(q, 0n))
  +y = X.iwid(X.vn(q, 1n))
  +z = X.iwid(X.vn(q, 2n))
  F64.mul(0.5f64, F64.sqrt(F64.add(F64.mul(x, x), F64.add(F64.mul(y, y), F64.mul(z, z)))))

def bp_mem(+w: V.Vec2, +segs: List<&2, Sg>, +s3: List<&2, S3>, +p: V.Point, +tol: F64) -> U64:
  uv_fin(np_scan(segs, V.v2_x(w), V.v2_y(w), 0n), s3_scan(s3, p, F64.div(1.0f64, 0.0f64)), tol)

def tor_w(+sf: KS.SF, +ur: F64, +vr: F64, +p: V.Point) -> V.Vec2:
  +w = KS.sf_uv(sf, p)
  V.V2{KS.ang_diff(ur, V.v2_x(w)), KS.ang_diff(vr, V.v2_y(w))}

def tor_jit(+w: V.Vec2) -> V.Vec2:
  V.V2{F64.add(V.v2_x(w), 3.7194718385e-9f64), F64.add(V.v2_y(w), 2.2360679775e-9f64)}

def tor_jd(+sf: KS.SF) -> F64:
  F64.mul(1.0e-8f64, F64.add(1.0f64, F64.add(KS.sf_r(sf), KS.sf_r2(sf))))

def uv_member(u: Uv, +q: List<&2, I.I>) -> U64:
  match u:
    case Uv_no{}: 2u64
    case Uv_cy{+sf, +r, +segs, +tol}: uv_mem_w(KS.sf_uv(sf, q_mid(q)), r, segs, tol)
    case Uv_bp{+sf, +segs, +s3, +tol}: bp_mem(KS.sf_uv(sf, q_mid(q)), segs, s3, q_mid(q), F64.add(tol, q_rad(q)))
    case Uv_to{+sf, +ur, +vr, +segs, +s3, +tol}: bp_mem(tor_jit(tor_w(sf, ur, vr, q_mid(q))), segs, s3, q_mid(q), F64.add(F64.add(tol, q_rad(q)), tor_jd(sf)))

def is_sph_im(s: M.Im) -> Bool:
  match s:
    case M.M_sp{c, r}: True{}
    case _: False{}

def mem_ax(n: Nat, +st: U64, +f: Fc, +q: List<&2, I.I>, +nf: M.Im, +k: Nat) -> U64:
  match n:
    case 0n: st
    case 1n+m:
      match st:
        case 2u64: mem_ax(m, mem_go(Nat.mul(6n, List.length(&2, Er, fc_es(f))), 2u64, f, q, nf, 0n, k), f, q, nf, Nat.add(k, 1n))
        case _: st

def member_k(+k: Bool, +f: Fc, +q: List<&2, I.I>, +nf: M.Im) -> U64:
  match k:
    case True{}: uv_member(fc_uv(f), q)
    case False{}: mem_ax(Bool.pick(Nat, is_sph_im(fc_s(f)), 5n, 1n), 2u64, f, q, nf, 0n)

def nappe_neg(s: M.Im, +q: List<&2, I.I>) -> Bool:
  match s:
    case M.M_co{+o, +a, k}: X.ineg_c(X.vdot(a, X.vsub(q, o)))
    case _: False{}

def member_n(neg: Bool, +f: Fc, +q: List<&2, I.I>, +nf: M.Im) -> U64:
  match neg:
    case True{}: 0u64
    case False{}: member_k(uv_has(fc_uv(f)), f, q, nf)

def member(+f: Fc, +q: List<&2, I.I>, +nf: M.Im) -> U64:
  member_n(nappe_neg(fc_s(f), q), f, q, nf)

def lim_of(+a: Nat, +b: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_lt(a, b), a, b)

def member_lk(+k: Bool, +f: Fc, +q: List<&2, I.I>, +nf: M.Im, +lim: Nat) -> U64:
  match k:
    case True{}: uv_member(fc_uv(f), q)
    case False{}: mem_go(lim_of(lim, Nat.mul(6n, List.length(&2, Er, fc_es(f)))), 2u64, f, q, nf, 0n, 0n)

def member_ln(neg: Bool, +f: Fc, +q: List<&2, I.I>, +nf: M.Im, +lim: Nat) -> U64:
  match neg:
    case True{}: 0u64
    case False{}: member_lk(uv_has(fc_uv(f)), f, q, nf, lim)

def member_lim(+f: Fc, +q: List<&2, I.I>, +nf: M.Im, +lim: Nat) -> U64:
  member_ln(nappe_neg(fc_s(f), q), f, q, nf, lim)

def er_uv(+e: Er, +sf: KS.SF, +t: F64) -> V.Vec2:
  KS.sf_uv(sf, q_mid(R.cv_box(er_c(e), I.ipt(Bool.pick(F64, er_fwd(e), t, F64.sub(1.0f64, t))))))

def rb_line(r: R.Rb) -> Bool:
  R.Rb{x, y, z, w} = r
  Nat.is_le(List.length(&2, I.I, x), 2n)

def er_line(+e: Er) -> Bool:
  rb_line(R.cv_rb(er_c(e)))

def sg_mk(+a: V.Vec2, +b: V.Vec2) -> Sg:
  +t0 = V.v2_x(a)
  Sg{t0, V.v2_y(a), F64.add(t0, KS.ang_diff(t0, V.v2_x(b))), V.v2_y(b)}

def sg_dev(+g: Sg, +m: V.Vec2, +r: F64) -> F64:
  Sg{+t0, +h0, +t1, +h1} = g
  +tm = F64.add(t0, KS.ang_diff(t0, V.v2_x(m)))
  +dt = F64.mul(r, F64.sub(tm, F64.mul(0.5f64, F64.add(t0, t1))))
  +dh = F64.sub(V.v2_y(m), F64.mul(0.5f64, F64.add(h0, h1)))
  F64.sqrt(F64.add(F64.mul(dt, dt), F64.mul(dh, dh)))

def sa_gs(+x: Sa) -> List<&2, Sg>:
  Sa{gs, dev} = x
  gs

def sa_dev(+x: Sa) -> F64:
  Sa{gs, dev} = x
  dev

def er_samp(+n: Nat, +k: Nat, +e: Er, +sf: KS.SF, +r: F64, +prev: V.Vec2, +acc: Sa) -> Sa:
  match n:
    case 0n: acc
    case 1n+m:
      +nf = U64.to_f64(U64.from_nat(Nat.add(k, Nat.add(m, 1n))))
      +t = F64.div(U64.to_f64(U64.from_nat(Nat.add(k, 1n))), nf)
      +tm = F64.div(F64.add(U64.to_f64(U64.from_nat(k)), 0.5f64), nf)
      +cur = er_uv(e, sf, t)
      +g = sg_mk(prev, cur)
      +dv = sg_dev(g, er_uv(e, sf, tm), r)
      er_samp(m, Nat.add(k, 1n), e, sf, r, cur, Sa{g <> sa_gs(acc), F64.max(dv, sa_dev(acc))})

def ers_uv(es: List<&2, Er>, +sf: KS.SF, +r: F64, +acc: Sa) -> Sa:
  match es:
    case []: acc
    case +e <> +t:
      +n = Bool.pick(Nat, er_line(e), 1n, 32n)
      ers_uv(t, sf, r, er_samp(n, 0n, e, sf, r, er_uv(e, sf, 0.0f64), acc))

def uv_mk(+k: Bool, +sf: KS.SF, +es: List<&2, Er>, +slv: F64) -> Uv:
  match k:
    case False{}: Uv_no{}
    case True{}:
      +r = KS.sf_r(sf)
      +sa = ers_uv(es, sf, r, Sa{[], 0.0f64})
      Uv_cy{sf, r, sa_gs(sa), F64.add(F64.mul(4.0f64, F64.add(slv, sa_dev(sa))), F64.mul(1.0e-12f64, F64.add(r, 1.0f64)))}

def uv_of(+tolerant: Bool, +g: G.GVal, +es: List<&2, Er>, +slv: F64) -> Uv:
  +sf = KS.sf_of(g)
  uv_mk(Bool.and(tolerant, U64.is_eq(KS.sf_kind(sf), KS.k_cyl())), sf, es, slv)

def er_p3(+e: Er, +t: F64) -> V.Point:
  q_mid(R.cv_box(er_c(e), I.ipt(Bool.pick(F64, er_fwd(e), t, F64.sub(1.0f64, t)))))

def sb_gs(+b: Sb) -> List<&2, Sg>:
  Sb{gs, g3, dev} = b
  gs

def sb_g3(+b: Sb) -> List<&2, S3>:
  Sb{gs, g3, dev} = b
  g3

def sb_dev(+b: Sb) -> F64:
  Sb{gs, g3, dev} = b
  dev

def sf_mid(+sf: KS.SF, +a: V.Vec2, +b: V.Vec2) -> V.Point:
  KS.sf_at(sf, F64.mul(0.5f64, F64.add(V.v2_x(a), V.v2_x(b))), F64.mul(0.5f64, F64.add(V.v2_y(a), V.v2_y(b))))

def sg_uv(+a: V.Vec2, +b: V.Vec2) -> Sg:
  Sg{V.v2_x(a), V.v2_y(a), V.v2_x(b), V.v2_y(b)}

def bp_samp(+n: Nat, +k: Nat, +e: Er, +sf: KS.SF, +pp: V.Point, +pq: V.Vec2, +acc: Sb) -> Sb:
  match n:
    case 0n: acc
    case 1n+m:
      +nf = U64.to_f64(U64.from_nat(Nat.add(k, Nat.add(m, 1n))))
      +t = F64.div(U64.to_f64(U64.from_nat(Nat.add(k, 1n))), nf)
      +tm = F64.div(F64.add(U64.to_f64(U64.from_nat(k)), 0.5f64), nf)
      +cp = er_p3(e, t)
      +cq = KS.sf_uv(sf, cp)
      +mp = er_p3(e, tm)
      +dv = F64.max(p3d(mp, p3lerp(pp, cp, 0.5f64)), p3d(mp, sf_mid(sf, pq, cq)))
      bp_samp(m, Nat.add(k, 1n), e, sf, cp, cq,
        Sb{sg_uv(pq, cq) <> sb_gs(acc), S3{pp, cp} <> sb_g3(acc), F64.max(sb_dev(acc), dv)})

def bp_ers(es: List<&2, Er>, +sf: KS.SF, +acc: Sb) -> Sb:
  match es:
    case []: acc
    case +e <> +t:
      +p0 = er_p3(e, 0.0f64)
      bp_ers(t, sf, bp_samp(32n, 0n, e, sf, p0, KS.sf_uv(sf, p0), acc))

def sb_fin(+sf: KS.SF, +b: Sb, +slv: F64) -> Uv:
  Sb{+gs, +g3, +dev} = b
  Uv_bp{sf, gs, g3, F64.add(F64.mul(4.0f64, F64.add(slv, dev)), 1.0e-9f64)}

def uv_bp_of(+g: G.GVal, +es: List<&2, Er>, +slv: F64) -> Uv:
  +sf = KS.sf_of(g)
  sb_fin(sf, bp_ers(es, sf, Sb{[], [], 0.0f64}), slv)

def tor_samp(+n: Nat, +k: Nat, +e: Er, +sf: KS.SF, +ur: F64, +vr: F64, +pp: V.Point, +pq: V.Vec2, +acc: Sb) -> Sb:
  match n:
    case 0n: acc
    case 1n+m:
      +nf = U64.to_f64(U64.from_nat(Nat.add(k, Nat.add(m, 1n))))
      +t = F64.div(U64.to_f64(U64.from_nat(Nat.add(k, 1n))), nf)
      +tm = F64.div(F64.add(U64.to_f64(U64.from_nat(k)), 0.5f64), nf)
      +cp = er_p3(e, t)
      +cq = tor_w(sf, ur, vr, cp)
      +dv = p3d(er_p3(e, tm), p3lerp(pp, cp, 0.5f64))
      tor_samp(m, Nat.add(k, 1n), e, sf, ur, vr, cp, cq,
        Sb{sg_uv(pq, cq) <> sb_gs(acc), S3{pp, cp} <> sb_g3(acc), F64.max(sb_dev(acc), dv)})

def tor_ers(es: List<&2, Er>, +sf: KS.SF, +ur: F64, +vr: F64, +acc: Sb) -> Sb:
  match es:
    case []: acc
    case +e <> +t:
      +p0 = er_p3(e, 0.0f64)
      tor_ers(t, sf, ur, vr, tor_samp(Bool.pick(Nat, er_line(e), 1n, 32n), 0n, e, sf, ur, vr, p0, tor_w(sf, ur, vr, p0), acc))

def cm_go(es: List<&2, Er>, +sf: KS.SF, +acc: Cm) -> Cm:
  match es:
    case []: acc
    case +e <> +t:
      Cm{+su, +cu, +sv, +cv} = acc
      +w = KS.sf_uv(sf, er_p3(e, 0.5f64))
      cm_go(t, sf, Cm{F64.add(su, KS.fsin(V.v2_x(w))), F64.add(cu, KS.fcos(V.v2_x(w))), F64.add(sv, KS.fsin(V.v2_y(w))), F64.add(cv, KS.fcos(V.v2_y(w)))})

def uv_tor_go(+sf: KS.SF, +c: Cm, +es: List<&2, Er>, +slv: F64) -> Uv:
  Cm{+su, +cu, +sv, +cv} = c
  +ur = KS.fatan2(su, cu)
  +vr = KS.fatan2(sv, cv)
  +b = tor_ers(es, sf, ur, vr, Sb{[], [], 0.0f64})
  Uv_to{sf, ur, vr, sb_gs(b), sb_g3(b), F64.add(F64.mul(4.0f64, F64.add(slv, sb_dev(b))), 1.0e-9f64)}

def uv_tor_of(+g: G.GVal, +es: List<&2, Er>, +slv: F64) -> Uv:
  +sf = KS.sf_of(g)
  uv_tor_go(sf, cm_go(es, sf, Cm{0.0f64, 0.0f64, 0.0f64, 0.0f64}), es, slv)

def sg_vlo(gs: List<&2, Sg>, +m: F64) -> F64:
  match gs:
    case []: m
    case +g <> t:
      Sg{t0, +h0, t1, +h1} = g
      sg_vlo(t, F64.min(m, F64.min(h0, h1)))

def sg_vhi(gs: List<&2, Sg>, +m: F64) -> F64:
  match gs:
    case []: m
    case +g <> t:
      Sg{t0, +h0, t1, +h1} = g
      sg_vhi(t, F64.max(m, F64.max(h0, h1)))

def isin_rng(+a: F64, +b: F64) -> I.I:
  +k0 = KS.f_round(F64.div(F64.sub(a, 1.5707963267948966f64), 6.283185307179586f64))
  +top = F64.add(1.5707963267948966f64, F64.mul(6.283185307179586f64, k0))
  +top2 = F64.add(top, 6.283185307179586f64)
  +bot = F64.sub(top, 3.141592653589793f64)
  +bot2 = F64.add(bot, 6.283185307179586f64)
  +hasmax = Bool.or(Bool.and(F64.is_le(a, top), F64.is_le(top, b)), Bool.and(F64.is_le(a, top2), F64.is_le(top2, b)))
  +hasmin = Bool.or(Bool.and(F64.is_le(a, bot), F64.is_le(bot, b)), Bool.and(F64.is_le(a, bot2), F64.is_le(bot2, b)))
  +sa = KS.fsin(a)
  +sb = KS.fsin(b)
  I.I{Bool.pick(F64, hasmin, F64.neg(1.0f64), F64.min(sa, sb)), Bool.pick(F64, hasmax, 1.0f64, F64.max(sa, sb))}

def tor_h(u: Uv) -> List<&2, I.I>:
  match u:
    case Uv_to{+sf, ur, +vr, +segs, s3, +tol}:
      +r2 = KS.sf_r2(sf)
      +wid = F64.div(F64.add(tol, F64.mul(1.0e-9f64, F64.add(1.0f64, r2))), F64.max(r2, 1.0e-300f64))
      +a = F64.add(F64.add(vr, KS.sf_t0(sf)), F64.sub(sg_vlo(segs, F64.div(1.0f64, 0.0f64)), wid))
      +b = F64.add(F64.add(vr, KS.sf_t0(sf)), F64.add(sg_vhi(segs, F64.neg(F64.div(1.0f64, 0.0f64))), wid))
      Bool.pick(List<&2, I.I>, Bool.and(Nat.is_lt(0n, List.length(&2, Sg, segs)), F64.is_lt(F64.sub(b, a), 6.0f64)),
        [I.iscale(isin_rng(a, b), r2)], [])
    case _: []
