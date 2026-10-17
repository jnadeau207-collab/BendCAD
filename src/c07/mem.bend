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

def skip_seam(+c: R.Cv, +k: List<&2, I.I>) -> Bool:
  Bool.and(cv_closed(c), k_end1(k))

def roots_go(rs: List<&2, N.Res>, +c: R.Cv, +l: Lg, +self: Bool, +tau: F64, +acc: Cn) -> Cn:
  match rs:
    case []: acc
    case r <> +t:
      match r:
        case N.R_pt{+k}: roots_go(t, c, l, self, tau, Bool.pick(Cn, is_r(self, tau, k), acc, Bool.pick(Cn, skip_seam(c, k), acc, cn_add(acc, pred(l, R.cv_box(c, X.vn(k, 0n)))))))
        case N.R_un{+k}: roots_go(t, c, l, self, tau, Bool.pick(Cn, is_r(self, tau, k), acc, Bool.pick(Cn, skip_seam(c, k), acc, cn_add(acc, Bool.pick(U64, U64.is_eq(pred(l, R.cv_box(c, X.vn(k, 0n))), 0u64), 0u64, 2u64)))))
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

def edge_cn(fl: Bool, +c: R.Cv, +l: Lg, +self: Bool, +tau: F64, +acc: Cn) -> Cn:
  match fl:
    case True{}: Cn{cn_n(acc), True{}}
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

def legs_of(s: M.Im, +q: List<&2, I.I>, +rp: List<&2, I.I>, +rev: Bool, +nf: M.Im) -> Lp:
  match s:
    case M.M_pl{o, +n}:
      +d = X.vsub(rp, q)
      Lp{[L_seg{M.M_pl{q, M.cross(d, n)}, q, rp}], d, Bool.and(Bool.not(rev), nz(d))}
    case M.M_cy{o, a, r}: ax_legs(Ax{o, a}, q, rp, False{}, I.ipt(0.0f64), rev, nf)
    case M.M_co{o, a, k}: ax_legs(Ax{o, a}, q, rp, False{}, I.ipt(0.0f64), rev, nf)
    case M.M_sp{+c, r}: ax_legs(Ax{c, sph_axis(q, c)}, q, rp, False{}, I.ipt(0.0f64), rev, nf)
    case M.M_to{o, a, bigr, r}: ax_legs(Ax{o, a}, q, rp, True{}, bigr, rev, nf)

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

def try_r(+f: Fc, +q: List<&2, I.I>, +nf: M.Im, +i: Nat, +tau: F64, +rev: Bool) -> U64:
  Fc{s, +same, +es, uv} = f
  +e = er_at(es, i)
  +c = er_c(e)
  +rp = R.cv_box(c, I.ipt(tau))
  +lp = legs_of(s, q, rp, rev, nf)
  +nrm = neg_if(same, M.im_grad(nf, rp))
  +tl = neg_if(er_fwd(e), R.cv_der(c, I.ipt(tau)))
  try_go(lp_ok(lp), lp, es, i, tau, nrm, tl)

def tau_of(+j: Nat) -> F64:
  +k = Nat.mod(j, 3n)
  Bool.pick(F64, Nat.is_eq(k, 0n), 0.5f64, Bool.pick(F64, Nat.is_eq(k, 1n), 0.3125f64, 0.6875f64))

def mem_go(n: Nat, +st: U64, +f: Fc, +q: List<&2, I.I>, +nf: M.Im, +j: Nat) -> U64:
  match n:
    case 0n: st
    case 1n+m:
      match st:
        case 2u64: mem_go(m, try_r(f, q, nf, Nat.div(j, 6n), tau_of(Nat.div(j, 2n)), Nat.is_eq(Nat.mod(j, 2n), 1n)), f, q, nf, Nat.add(j, 1n))
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
  uv_fin(uv_scan(segs, t, h, 0n), uv_scan_d(segs, r, t, h, F64.div(1.0f64, 0.0f64)), tol)

def uv_member(u: Uv, +q: List<&2, I.I>) -> U64:
  match u:
    case Uv_no{}: 2u64
    case Uv_cy{+sf, +r, +segs, +tol}: uv_mem_w(KS.sf_uv(sf, q_mid(q)), r, segs, tol)

def member_k(+k: Bool, +f: Fc, +q: List<&2, I.I>, +nf: M.Im) -> U64:
  match k:
    case True{}: uv_member(fc_uv(f), q)
    case False{}: mem_go(Nat.mul(6n, List.length(&2, Er, fc_es(f))), 2u64, f, q, nf, 0n)

def member(+f: Fc, +q: List<&2, I.I>, +nf: M.Im) -> U64:
  member_k(uv_has(fc_uv(f)), f, q, nf)

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

type Sa is Data:
  Sa{ gs: List<&2, Sg>, dev: F64 }

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
