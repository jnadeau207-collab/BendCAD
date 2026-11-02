import Base
import ../c04/types.bend as Ty
import ../c01/types.bend as V
import ../c06/iv.bend as I
import ../c06/model.bend as M
import ../c07/sol.bend as SO
import ../c07/im.bend as Im
import ../c07/mem.bend as Mm
import ../c07/rb.bend as R
import ../c07/ivx.bend as X
import ../c08/bool.bend as BO
import ./qaccel.bend as QA

type Bd is Data:
  Bd{ p: I.I, h: I.I }

type Cb is Data:
  Cb{ a: List<&2, I.I>, b: List<&2, I.I>, fs: List<&2, SO.Fd>, fl: F64, ra: I.I, rb: I.I }

def iabs(+a: I.I) -> I.I:
  I.I{+lo, +hi} = a
  Bool.pick(I.I, F64.is_le(0.0f64, lo), a,
    Bool.pick(I.I, F64.is_le(hi, 0.0f64), I.ineg(a), I.I{0.0f64, F64.max(F64.neg(lo), hi)}))

def pos(+a: I.I) -> I.I:
  I.I{+lo, +hi} = a
  I.I{F64.max(lo, 0.0f64), F64.max(hi, 0.0f64)}

def ax_h(+o: List<&2, I.I>, +a: List<&2, I.I>, +p: List<&2, I.I>) -> I.I:
  I.idiv(X.vdot(a, X.vsub(p, o)), I.isqrt(X.vdot(a, a)))

def ax_rho(+o: List<&2, I.I>, +a: List<&2, I.I>, +p: List<&2, I.I>) -> I.I:
  +m = X.vsub(p, o)
  I.isqrt(pos(I.isub(X.vdot(m, m), I.idiv(I.isq(X.vdot(a, m)), X.vdot(a, a)))))

def sdist(s: Im.Im, +p: List<&2, I.I>) -> F64:
  match s:
    case Im.M_pl{o, +n}: I.i_lo(iabs(I.idiv(X.vdot(n, X.vsub(p, o)), I.isqrt(X.vdot(n, n)))))
    case Im.M_sp{o, r}:
      +m = X.vsub(p, o)
      I.i_lo(iabs(I.isub(I.isqrt(X.vdot(m, m)), r)))
    case Im.M_cy{+o, +a, r}: I.i_lo(iabs(I.isub(ax_rho(o, a, p), r)))
    case Im.M_co{+o, +a, +k}:
      I.i_lo(iabs(I.idiv(I.isub(ax_rho(o, a, p), I.imul(iabs(k), iabs(ax_h(o, a, p)))), I.isqrt(I.iadd(I.ipt(1.0f64), I.isq(k))))))
    case Im.M_to{+o, +a, bigr, r}:
      I.i_lo(iabs(I.isub(I.isqrt(I.iadd(I.isq(I.isub(ax_rho(o, a, p), bigr)), I.isq(ax_h(o, a, p)))), r)))

def gap1(+a: I.I, +b: I.I) -> F64:
  F64.max(0.0f64, F64.max(F64.sub(I.i_lo(a), I.i_hi(b)), F64.sub(I.i_lo(b), I.i_hi(a))))

def box_gap(+a: List<&2, I.I>, +b: List<&2, I.I>) -> F64:
  +gx = gap1(X.vn(a, 0n), X.vn(b, 0n))
  +gy = gap1(X.vn(a, 1n), X.vn(b, 1n))
  +gz = gap1(X.vn(a, 2n), X.vn(b, 2n))
  I.i_lo(I.isqrt(I.iadd(I.iadd(I.isq(I.ipt(gx)), I.isq(I.ipt(gy))), I.isq(I.ipt(gz)))))

def fd_none() -> SO.Fd:
  SO.fd_mk(None{}, Ty.surf_zero(), True{}, SO.Ea{[], True{}}, 0n, 0n, 0.0f64)

def f0(fs: List<&2, SO.Fd>) -> SO.Fd:
  match fs:
    case []: fd_none()
    case +f <> t: f

def f1(fs: List<&2, SO.Fd>) -> SO.Fd:
  match fs:
    case []: fd_none()
    case f <> +t: f0(t)

def rr_all() -> I.I:
  I.I{0.0f64, V.dbl_max()}

def cb(+fa: SO.Fd, +fb: SO.Fd) -> Cb:
  Cb{SO.fd_bx(fa), SO.fd_bx(fb), [fa, fb], 0.0f64, rr_all(), rr_all()}

def vlen_hi(+v: List<&2, I.I>) -> F64:
  I.i_hi(I.isqrt(pos(X.vdot(v, v))))

def vlen_lo(+v: List<&2, I.I>) -> F64:
  I.i_lo(I.isqrt(pos(X.vdot(v, v))))

def slack(+so: List<&2, I.I>, +sa: List<&2, I.I>, +o: List<&2, I.I>, +a: List<&2, I.I>, +bx: List<&2, I.I>) -> F64:
  +sn = F64.div(vlen_hi(Im.cross(a, sa)), F64.mul(vlen_lo(a), vlen_lo(sa)))
  +e = F64.div(vlen_hi(Im.cross(X.vsub(so, o), a)), vlen_lo(a))
  F64.add(e, F64.mul(sn, F64.add(vlen_hi(X.vsub(bx, o)), vlen_hi(X.vsub(so, o)))))

def widen(+x: I.I, +e: F64) -> I.I:
  I.I{F64.sub(I.i_lo(x), e), F64.add(I.i_hi(x), e)}

def band(+p: I.I, +q: I.I, +h: I.I) -> List<&2, Bd>:
  +lo = F64.max(I.i_lo(p), I.i_lo(q))
  +hi = F64.min(I.i_hi(p), I.i_hi(q))
  Bool.pick(List<&2, Bd>, F64.is_le(lo, hi), [Bd{I.I{lo, hi}, h}], [])

def tor_bands(+hh: I.I, +bigr: I.I, +r: I.I, +e: F64, +p: I.I, +h: I.I) -> List<&2, Bd>:
  +q = I.isqrt(pos(I.isub(I.isq(r), I.isq(hh))))
  List.append(&2, Bd, band(widen(I.isub(bigr, q), e), p, h), band(widen(I.iadd(bigr, q), e), p, h))
def bands_go(s: Im.Im, +o: List<&2, I.I>, +a: List<&2, I.I>, +bx: List<&2, I.I>, +h: I.I, +p: I.I) -> List<&2, Bd>:
  match s:
    case Im.M_cy{+so, +sa, +r}: band(widen(r, slack(so, sa, o, a, bx)), p, h)
    case Im.M_pl{+op, +n}:
      +sn = F64.div(vlen_hi(Im.cross(a, n)), F64.mul(vlen_lo(a), vlen_lo(n)))
      [Bd{p, I.I{F64.max(I.i_lo(h), I.i_lo(widen(ax_h(o, a, op), F64.mul(sn, vlen_hi(X.vsub(bx, op)))))), F64.min(I.i_hi(h), I.i_hi(widen(ax_h(o, a, op), F64.mul(sn, vlen_hi(X.vsub(bx, op))))))}}]
    case Im.M_co{+so, +sa, +k}:
      +hh = widen(I.isub(h, ax_h(o, a, so)), slack(so, sa, o, a, bx))
      band(widen(I.imul(iabs(k), iabs(hh)), F64.mul(F64.add(1.0f64, I.i_hi(iabs(k))), slack(so, sa, o, a, bx))), p, h)
    case Im.M_to{+so, +sa, +bigr, +r}:
      +e = slack(so, sa, o, a, bx)
      tor_bands(widen(I.isub(h, ax_h(o, a, so)), e), bigr, r, F64.mul(2.0f64, e), p, h)
    case Im.M_sp{+so, +r}:
      +hh = widen(I.isub(h, ax_h(o, a, so)), slack(so, a, o, a, bx))
      band(widen(I.isqrt(pos(I.isub(I.isq(r), I.isq(hh)))), F64.mul(2.0f64, slack(so, a, o, a, bx))), p, h)

def bands(s: Im.Im, +o: List<&2, I.I>, +a: List<&2, I.I>, +bx: List<&2, I.I>) -> List<&2, Bd>:
  bands_go(s, o, a, bx, ax_h(o, a, bx), ax_rho(o, a, bx))

def bd_d(+x: Bd, +y: Bd) -> F64:
  Bd{+px, +hx} = x
  Bd{+py, +hy} = y
  I.i_lo(I.isqrt(I.iadd(I.isq(I.ipt(gap1(px, py))), I.isq(I.ipt(gap1(hx, hy))))))

def bd_one(+x: Bd, ys: List<&2, Bd>, +acc: F64) -> F64:
  match ys:
    case []: acc
    case +y <> +t: bd_one(x, t, F64.min(acc, bd_d(x, y)))

def bd_min(xs: List<&2, Bd>, +ys: List<&2, Bd>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> +t: bd_min(t, ys, bd_one(x, ys, acc))

def mer_ax(+o: List<&2, I.I>, +a: List<&2, I.I>, sa: Im.Im, sb: Im.Im, +ca: List<&2, I.I>, +cb: List<&2, I.I>) -> F64:
  F64.max(0.0f64, bd_min(bands(sa, o, a, ca), bands(sb, o, a, cb), V.dbl_max()))

def mer_b(sa: Im.Im, sb: Im.Im, +ca: List<&2, I.I>, +cb: List<&2, I.I>) -> F64:
  match sb:
    case Im.M_cy{+o, +a, r}: mer_ax(o, a, sa, sb, ca, cb)
    case Im.M_co{+o, +a, k}: mer_ax(o, a, sa, sb, ca, cb)
    case Im.M_to{+o, +a, bigr, r}: mer_ax(o, a, sa, sb, ca, cb)
    case _: 0.0f64

def mer_a(sa: Im.Im, sb: Im.Im, +ca: List<&2, I.I>, +cb: List<&2, I.I>) -> F64:
  match sa:
    case Im.M_cy{+o, +a, r}: mer_ax(o, a, sa, sb, ca, cb)
    case Im.M_co{+o, +a, k}: mer_ax(o, a, sa, sb, ca, cb)
    case Im.M_to{+o, +a, bigr, r}: mer_ax(o, a, sa, sb, ca, cb)
    case _: 0.0f64

def mer(+sa: Im.Im, +sb: Im.Im, +ca: List<&2, I.I>, +cb: List<&2, I.I>) -> F64:
  F64.max(mer_a(sa, sb, ca, cb), mer_b(sa, sb, ca, cb))

def isect(+x: I.I, +y: I.I) -> I.I:
  +lo = F64.max(I.i_lo(x), I.i_lo(y))
  +hi = F64.min(I.i_hi(x), I.i_hi(y))
  Bool.pick(I.I, F64.is_le(lo, hi), I.I{lo, hi}, x)

def tilt(+n: List<&2, I.I>, +a: List<&2, I.I>, +bx: List<&2, I.I>, +op: List<&2, I.I>) -> F64:
  +sn = F64.div(vlen_hi(Im.cross(a, n)), F64.mul(vlen_lo(a), vlen_lo(n)))
  F64.mul(sn, vlen_hi(X.vsub(bx, op)))

def mrect_go(s: Im.Im, +o: List<&2, I.I>, +a: List<&2, I.I>, +bx: List<&2, I.I>, +rr: I.I, +p: I.I, +h: I.I) -> Bd:
  match s:
    case Im.M_cy{+so, +sa, +r}: Bd{isect(isect(p, rr), widen(r, slack(so, sa, o, a, bx))), h}
    case Im.M_pl{+op, +n}: Bd{isect(p, rr), isect(h, widen(ax_h(o, a, op), tilt(n, a, bx, op)))}
    case _: Bd{isect(p, rr), h}

def mrect(s: Im.Im, +o: List<&2, I.I>, +a: List<&2, I.I>, +bx: List<&2, I.I>, +rr: I.I) -> Bd:
  mrect_go(s, o, a, bx, rr, ax_rho(o, a, bx), ax_h(o, a, bx))

type Mc is Data:
  Mc{ ok: Bool, rc: I.I, hc: I.I, r: I.I, e: F64 }

def mc_no() -> Mc:
  Mc{False{}, I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(0.0f64), 0.0f64}

def mcirc(s: Im.Im, +o: List<&2, I.I>, +a: List<&2, I.I>, +bx: List<&2, I.I>) -> Mc:
  match s:
    case Im.M_to{+so, +sa, +bigr, +r}: Mc{True{}, bigr, ax_h(o, a, so), r, F64.mul(2.0f64, slack(so, sa, o, a, bx))}
    case Im.M_sp{+so, +r}: Mc{True{}, I.ipt(0.0f64), ax_h(o, a, so), r, I.i_hi(ax_rho(o, a, so))}
    case _: mc_no()

def far1(+x: I.I, +y: I.I) -> F64:
  F64.max(F64.abs(F64.sub(I.i_hi(x), I.i_lo(y))), F64.abs(F64.sub(I.i_hi(y), I.i_lo(x))))

def dlo2(+x0: I.I, +y0: I.I, +x1: I.I, +y1: I.I) -> F64:
  I.i_lo(I.isqrt(I.iadd(I.isq(I.ipt(gap1(x0, x1))), I.isq(I.ipt(gap1(y0, y1))))))

def dhi2(+x0: I.I, +y0: I.I, +x1: I.I, +y1: I.I) -> F64:
  I.i_hi(I.isqrt(I.iadd(I.isq(I.ipt(far1(x0, x1))), I.isq(I.ipt(far1(y0, y1))))))

def circ_rect(+c: Mc, +q: Bd) -> F64:
  Mc{+ok, +rc, +hc, +r, +e} = c
  Bd{+p, +h} = q
  Bool.pick(F64, ok, F64.max(0.0f64, F64.sub(F64.max(F64.sub(dlo2(rc, hc, p, h), I.i_hi(r)), F64.sub(I.i_lo(r), dhi2(rc, hc, p, h))), e)), 0.0f64)

def circ_circ(+c: Mc, +d: Mc) -> F64:
  Mc{+ok1, +rc1, +hc1, +r1, +e1} = c
  Mc{+ok2, +rc2, +hc2, +r2, +e2} = d
  +lo = dlo2(rc1, hc1, rc2, hc2)
  +hi = dhi2(rc1, hc1, rc2, hc2)
  +sep = F64.sub(lo, F64.add(I.i_hi(r1), I.i_hi(r2)))
  +nest = F64.sub(I.i_lo(iabs(I.isub(r1, r2))), hi)
  Bool.pick(F64, Bool.and(ok1, ok2), F64.max(0.0f64, F64.sub(F64.max(sep, nest), F64.add(e1, e2))), 0.0f64)

def m2(+sa: Im.Im, +sb: Im.Im, +o: List<&2, I.I>, +a: List<&2, I.I>, +ca: List<&2, I.I>, +cb: List<&2, I.I>, +ra: I.I, +rb: I.I) -> F64:
  +qa = mrect(sa, o, a, ca, ra)
  +qb = mrect(sb, o, a, cb, rb)
  +ka = mcirc(sa, o, a, ca)
  +kb = mcirc(sb, o, a, cb)
  F64.max(F64.max(bd_d(qa, qb), circ_circ(ka, kb)), F64.max(circ_rect(ka, qb), circ_rect(kb, qa)))

def m2_of(s: Im.Im, +sa: Im.Im, +sb: Im.Im, +ca: List<&2, I.I>, +cb: List<&2, I.I>, +ra: I.I, +rb: I.I) -> F64:
  match s:
    case Im.M_cy{+o, +a, r}: m2(sa, sb, o, a, ca, cb, ra, rb)
    case Im.M_co{+o, +a, k}: m2(sa, sb, o, a, ca, cb, ra, rb)
    case Im.M_to{+o, +a, bigr, r}: m2(sa, sb, o, a, ca, cb, ra, rb)
    case _: 0.0f64

def mer2(+sa: Im.Im, +sb: Im.Im, +ca: List<&2, I.I>, +cb: List<&2, I.I>, +ra: I.I, +rb: I.I) -> F64:
  F64.max(m2_of(sa, sa, sb, ca, cb, ra, rb), m2_of(sb, sa, sb, ca, cb, ra, rb))

def pair_lb(+c: Cb) -> F64:
  Cb{+a, +b, +fs, +fl, +ra, +rb} = c
  +fa = f0(fs)
  +fb = f1(fs)
  F64.max(F64.max(F64.max(box_gap(a, b), fl), F64.max(mer(SO.fd_im(fa), SO.fd_im(fb), a, b), mer2(SO.fd_im(fa), SO.fd_im(fb), a, b, ra, rb))),
    F64.max(sdist(SO.fd_im(fb), a), sdist(SO.fd_im(fa), b)))

def diag(+a: List<&2, I.I>) -> F64:
  +dx = F64.sub(I.i_hi(X.vn(a, 0n)), I.i_lo(X.vn(a, 0n)))
  +dy = F64.sub(I.i_hi(X.vn(a, 1n)), I.i_lo(X.vn(a, 1n)))
  +dz = F64.sub(I.i_hi(X.vn(a, 2n)), I.i_lo(X.vn(a, 2n)))
  F64.sqrt(F64.add(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)), F64.mul(dz, dz)))

def wid(+a: List<&2, I.I>) -> F64:
  F64.max(F64.sub(I.i_hi(X.vn(a, 0n)), I.i_lo(X.vn(a, 0n))),
    F64.max(F64.sub(I.i_hi(X.vn(a, 1n)), I.i_lo(X.vn(a, 1n))), F64.sub(I.i_hi(X.vn(a, 2n)), I.i_lo(X.vn(a, 2n)))))

def axis_of(+a: List<&2, I.I>) -> Nat:
  +wx = F64.sub(I.i_hi(X.vn(a, 0n)), I.i_lo(X.vn(a, 0n)))
  +wy = F64.sub(I.i_hi(X.vn(a, 1n)), I.i_lo(X.vn(a, 1n)))
  +wz = F64.sub(I.i_hi(X.vn(a, 2n)), I.i_lo(X.vn(a, 2n)))
  Bool.pick(Nat, Bool.and(F64.is_le(wy, wx), F64.is_le(wz, wx)), 0n, Bool.pick(Nat, F64.is_le(wz, wy), 1n, 2n))

def half(+x: I.I, +up: Bool) -> I.I:
  I.I{+lo, +hi} = x
  +m = F64.mul(0.5f64, F64.add(lo, hi))
  Bool.pick(I.I, up, I.I{m, hi}, I.I{lo, m})

def cut(+a: List<&2, I.I>, +k: Nat, +up: Bool) -> List<&2, I.I>:
  [Bool.pick(I.I, Nat.is_eq(k, 0n), half(X.vn(a, 0n), up), X.vn(a, 0n)),
    Bool.pick(I.I, Nat.is_eq(k, 1n), half(X.vn(a, 1n), up), X.vn(a, 1n)),
    Bool.pick(I.I, Nat.is_eq(k, 2n), half(X.vn(a, 2n), up), X.vn(a, 2n))]

def mem_in(big: Bool, +b: List<&2, I.I>, +f: SO.Fd) -> Bool:
  match big:
    case True{}: True{}
    case False{}: Bool.not(U64.is_eq(Mm.member(SO.fd_fc(f), b, SO.fd_im(f)), 0u64))

def on_face_go(near: Bool, +b: List<&2, I.I>, +f: SO.Fd, +w0: F64) -> Bool:
  match near:
    case False{}: False{}
    case True{}: mem_in(F64.is_lt(w0, wid(b)), b, f)

def on_face(+b: List<&2, I.I>, +f: SO.Fd, +w0: F64) -> Bool:
  on_face_go(F64.is_le(sdist(SO.fd_im(f), b), 0.0f64), b, f, w0)

def kids(+c: Cb, +w0: F64) -> List<&2, Cb>:
  Cb{+a, +b, +fs, +fl, +ra, +rb} = c
  +sa = F64.is_le(wid(b), wid(a))
  +x = Bool.pick(List<&2, I.I>, sa, a, b)
  +f = Bool.pick(SO.Fd, sa, f0(fs), f1(fs))
  +k = axis_of(x)
  +lo = cut(x, k, False{})
  +hi = cut(x, k, True{})
  +cl = Bool.pick(Cb, sa, Cb{lo, b, fs, fl, ra, rb}, Cb{a, lo, fs, fl, ra, rb})
  +ch = Bool.pick(Cb, sa, Cb{hi, b, fs, fl, ra, rb}, Cb{a, hi, fs, fl, ra, rb})
  List.append(&2, Cb, Bool.pick(List<&2, Cb>, on_face(lo, f, w0), [cl], []), Bool.pick(List<&2, Cb>, on_face(hi, f, w0), [ch], []))

def wid2(+c: Cb) -> F64:
  Cb{+a, +b, fs, fl, ra, rb} = c
  F64.max(wid(a), wid(b))

def inw(+f: SO.Fd, +p: List<&2, I.I>) -> List<&2, I.I>:
  Mm.neg_if(Bool.not(Mm.fc_same(SO.fd_fc(f))), Im.im_grad(SO.fd_im(f), p))

def cmin() -> F64:
  0.8660254037844386f64

def nrm_lo(+v: List<&2, I.I>) -> F64:
  I.i_lo(I.isqrt(pos(X.vdot(v, v))))

def nrm_hi(+v: List<&2, I.I>) -> F64:
  I.i_hi(I.isqrt(pos(X.vdot(v, v))))

def can_face(+g: List<&2, I.I>, +d: List<&2, I.I>, +dl: F64) -> Bool:
  F64.is_le(F64.mul(cmin(), F64.mul(nrm_lo(g), dl)), I.i_hi(X.vdot(g, d)))

def anti(+c: Cb) -> Bool:
  Cb{+a, +b, +fs, fl, ra, rb} = c
  +fa = f0(fs)
  +fb = f1(fs)
  +dl = box_gap(a, b)
  Bool.and(can_face(inw(fa, a), X.vsub(b, a), dl), can_face(inw(fb, b), X.vsub(a, b), dl))

def anti_pt(+fa: SO.Fd, +p: List<&2, I.I>, +fb: SO.Fd, +q: List<&2, I.I>) -> Bool:
  +d = X.vsub(q, p)
  +dn = nrm_hi(d)
  +ga = inw(fa, p)
  +gb = inw(fb, q)
  Bool.and(F64.is_le(F64.mul(cmin(), F64.mul(nrm_hi(ga), dn)), I.i_lo(X.vdot(ga, d))),
    F64.is_le(F64.mul(cmin(), F64.mul(nrm_hi(gb), dn)), I.i_lo(X.vdot(gb, X.vsub(p, q)))))

type Ph is Data:
  Ph_e{}
  Ph_n{ k: F64, q: F64, w: F64, x: Cb, cs: List<&2, Ph> }

def quant(+k: F64, +eps: F64) -> F64:
  F64.mul(U64.to_f64(F64.to_u64(F64.div(F64.max(k, 0.0f64), eps))), eps)

def first(+ka: F64, +wa: F64, +kb: F64, +wb: F64) -> Bool:
  Bool.or(F64.is_lt(ka, kb), Bool.and(F64.is_eq(ka, kb), F64.is_le(wb, wa)))

def meld_n(le: Bool, +ka: F64, +qa: F64, +wa: F64, +xa: Cb, +ca: List<&2, Ph>, +kb: F64, +qb: F64, +wb: F64, +xb: Cb, +cb: List<&2, Ph>) -> Ph:
  match le:
    case True{}: Ph_n{ka, qa, wa, xa, Ph_n{kb, qb, wb, xb, cb} <> ca}
    case False{}: Ph_n{kb, qb, wb, xb, Ph_n{ka, qa, wa, xa, ca} <> cb}

def meld(a: Ph, +b: Ph) -> Ph:
  match a:
    case Ph_e{}: b
    case Ph_n{+ka, +qa, +wa, +xa, +ca}:
      match b:
        case Ph_e{}: Ph_n{ka, qa, wa, xa, ca}
        case Ph_n{+kb, +qb, +wb, +xb, +cb}: meld_n(first(qa, wa, qb, wb), ka, qa, wa, xa, ca, kb, qb, wb, xb, cb)

def pass1(hs: List<&2, Ph>, +pend: Ph, has: Bool, +acc: List<&2, Ph>) -> List<&2, Ph>:
  match hs:
    case []:
      match has:
        case True{}: pend <> acc
        case False{}: acc
    case +h <> +t:
      match has:
        case True{}: pass1(t, Ph_e{}, False{}, meld(pend, h) <> acc)
        case False{}: pass1(t, h, True{}, acc)

def fold(xs: List<&2, Ph>, +h: Ph) -> Ph:
  match xs:
    case []: h
    case +x <> +t: fold(t, meld(x, h))

def pairs(+hs: List<&2, Ph>) -> Ph:
  fold(pass1(hs, Ph_e{}, False{}, []), Ph_e{})

def lbk(w: Bool, +h: Cb) -> F64:
  match w:
    case True{}: Bool.pick(F64, anti(h), pair_lb(h), V.dbl_max())
    case False{}: pair_lb(h)

def push_k(keep: Bool, +k: F64, +x: Cb, +h: Ph, +eps: F64) -> Ph:
  match keep:
    case True{}: meld(Ph_n{k, quant(k, eps), wid2(x), x, []}, h)
    case False{}: h

def push_all(xs: List<&2, Cb>, +h: Ph, +w: Bool, +hi: F64, +eps: F64) -> Ph:
  match xs:
    case []: h
    case +x <> +t:
      +k = lbk(w, x)
      push_all(t, push_k(F64.is_lt(k, hi), k, x, h, eps), w, hi, eps)

def ph_all(hs: List<&2, Ph>, +acc: F64) -> F64:
  match hs:
    case []: acc
    case +h <> +t:
      match h:
        case Ph_e{}: ph_all(t, acc)
        case Ph_n{+k, q, w, x, +cs}: ph_all(t, ph_all(cs, F64.min(acc, k)))

def ph_min(+h: Ph, +hi: F64) -> F64:
  ph_all([h], hi)

def stop_of(h: Ph, +hi: F64, +eps: F64, +minw: F64) -> Bool:
  match h:
    case Ph_e{}: True{}
    case Ph_n{k, +q, +w, x, cs}: Bool.or(F64.is_le(F64.sub(hi, F64.mul(2.0f64, eps)), q), F64.is_le(w, minw))

def mid1(+a: I.I) -> I.I:
  I.ipt(F64.mul(0.5f64, F64.add(I.i_lo(a), I.i_hi(a))))

def mid(+a: List<&2, I.I>) -> List<&2, I.I>:
  [mid1(X.vn(a, 0n)), mid1(X.vn(a, 1n)), mid1(X.vn(a, 2n))]

def on_pt(fin: Bool, +f: SO.Fd, +q: List<&2, I.I>) -> Bool:
  match fin:
    case False{}: False{}
    case True{}: U64.is_eq(Mm.member(SO.fd_fc(f), q, SO.fd_im(f)), 1u64)

def wit_d(ok: Bool, +fa: SO.Fd, +p: List<&2, I.I>, +fb: SO.Fd, +q: List<&2, I.I>) -> F64:
  match ok:
    case False{}: V.dbl_max()
    case True{}: F64.add(nrm_hi(X.vsub(q, p)), F64.add(SO.dist(SO.fd_im(fa), p), SO.dist(SO.fd_im(fb), q)))

def wit_q(okp: Bool, +w: Bool, +fa: SO.Fd, +p: List<&2, I.I>, +fb: SO.Fd) -> F64:
  match okp:
    case False{}: V.dbl_max()
    case True{}:
      +q = SO.snap(SO.proj(SO.fd_im(fb), p))
      +ok = on_pt(X.vfin(q), fb, q)
      wit_d(Bool.and(ok, Bool.or(Bool.not(w), anti_pt(fa, p, fb, q))), fa, p, fb, q)

def wit1(+w: Bool, +fa: SO.Fd, +c: List<&2, I.I>, +fb: SO.Fd) -> F64:
  +p = SO.snap(SO.proj(SO.fd_im(fa), c))
  wit_q(on_pt(X.vfin(p), fa, p), w, fa, p, fb)

def wit(+w: Bool, +x: Cb) -> F64:
  Cb{+a, +b, +fs, fl, ra, rb} = x
  +fa = f0(fs)
  +fb = f1(fs)
  F64.min(wit1(w, fa, mid(a), fb), wit1(w, fb, mid(b), fa))

def ladd(xs: List<&2, I.I>, ys: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: ys
    case +x <> +xt:
      match ys:
        case []: x <> xt
        case +y <> +yt: I.iadd(x, y) <> ladd(xt, yt)

def lsc(+s: I.I, xs: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case +x <> +t: I.imul(s, x) <> lsc(s, t)

def conv(xs: List<&2, I.I>, +ys: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case +x <> +t: ladd(lsc(x, ys), I.ipt(0.0f64) <> conv(t, ys))

def brow(n: Nat, +nn: F64, +k: F64, +c: F64) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m): c <> brow(m, nn, F64.add(k, 1.0f64), F64.div(F64.mul(c, F64.sub(nn, k)), F64.add(k, 1.0f64)))

def row(+len: Nat) -> List<&2, F64>:
  brow(len, U64.to_f64(U64.from_nat(Nat.sub(len, 1n))), 0.0f64, 1.0f64)

def bup(xs: List<&2, I.I>, cs: List<&2, F64>) -> List<&2, I.I>:
  match xs:
    case []: []
    case +x <> +t:
      match cs:
        case []: []
        case +c <> +u: I.imul(x, I.ipt(c)) <> bup(t, u)

def bdn(xs: List<&2, I.I>, cs: List<&2, F64>) -> List<&2, I.I>:
  match xs:
    case []: []
    case +x <> +t:
      match cs:
        case []: []
        case +c <> +u: I.idiv(x, I.ipt(c)) <> bdn(t, u)

def bprod(+xs: List<&2, I.I>, +ys: List<&2, I.I>) -> List<&2, I.I>:
  +m = List.length(&2, I.I, xs)
  +n = List.length(&2, I.I, ys)
  bdn(conv(bup(xs, row(m)), bup(ys, row(n))), row(Nat.sub(Nat.add(m, n), 1n)))

def lmag(xs: List<&2, I.I>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> +t: lmag(t, F64.max(acc, I.i_hi(iabs(x))))

def lwmin(xs: List<&2, I.I>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> +t: lwmin(t, F64.min(acc, I.i_lo(x)))

def alg_go(+hx: List<&2, I.I>, +hy: List<&2, I.I>, +hz: List<&2, I.I>, +w: List<&2, I.I>, +a: List<&2, I.I>, +r2: I.I) -> I.I:
  +aa = X.vdot(a, a)
  +s = ladd(ladd(bprod(hx, hx), bprod(hy, hy)), bprod(hz, hz))
  +l = ladd(ladd(lsc(X.vn(a, 0n), hx), lsc(X.vn(a, 1n), hy)), lsc(X.vn(a, 2n), hz))
  +f = ladd(ladd(lsc(aa, s), lsc(I.ipt(F64.neg(1.0f64)), bprod(l, l))), lsc(I.ineg(I.imul(r2, aa)), bprod(w, w)))
  +wm = lwmin(w, V.dbl_max())
  +d = I.i_hi(I.idiv(I.ipt(lmag(f, 0.0f64)), I.imul(aa, I.isq(I.ipt(wm)))))
  Bool.pick(I.I, F64.is_lt(0.0f64, wm), I.I{F64.max(0.0f64, I.i_lo(I.isub(r2, I.ipt(d)))), I.i_hi(I.iadd(r2, I.ipt(d)))}, I.I{0.0f64, V.dbl_max()})

def alg_pc(+o: List<&2, I.I>, +a: List<&2, I.I>, +rb: R.Rb, +rm: F64, +t: I.I) -> I.I:
  R.Rb{+x, +y, +z, +w} = rb
  +ws = R.rs(w, t)
  +q = alg_go(ladd(R.rs(x, t), lsc(I.ineg(X.vn(o, 0n)), ws)), ladd(R.rs(y, t), lsc(I.ineg(X.vn(o, 1n)), ws)), ladd(R.rs(z, t), lsc(I.ineg(X.vn(o, 2n)), ws)), ws, a, I.isq(I.ipt(rm)))
  I.I{I.i_lo(I.isqrt(I.I{I.i_lo(q), I.i_lo(q)})), I.i_hi(I.isqrt(I.I{I.i_hi(q), I.i_hi(q)}))}

def ihull(+p: I.I, +q: I.I) -> I.I:
  I.I{F64.min(I.i_lo(p), I.i_lo(q)), F64.max(I.i_hi(p), I.i_hi(q))}

def alg_rb(+o: List<&2, I.I>, +a: List<&2, I.I>, +rb: R.Rb, +rm: F64) -> I.I:
  ihull(ihull(alg_pc(o, a, rb, rm, I.I{0.0f64, 0.25f64}), alg_pc(o, a, rb, rm, I.I{0.25f64, 0.5f64})),
    ihull(alg_pc(o, a, rb, rm, I.I{0.5f64, 0.75f64}), alg_pc(o, a, rb, rm, I.I{0.75f64, 1.0f64})))

def alg_rho(+o: List<&2, I.I>, +a: List<&2, I.I>, +c: R.Cv) -> I.I:
  alg_rb(o, a, R.cv_rb(c), I.imid(ax_rho(o, a, R.cv_box(c, I.ipt(0.5f64)))))

type Pc is Data:
  Pc{ t: I.I, d: Nat }

def rmv(+o: List<&2, I.I>, +a: List<&2, I.I>, +c: R.Cv, +t: I.I) -> I.I:
  +rm = ax_rho(o, a, R.cv_box(c, mid1(t)))
  +bx = R.cv_box(c, t)
  +rb = ax_rho(o, a, bx)
  +m = X.vsub(bx, o)
  +d = R.cv_der(c, t)
  +n = I.isub(X.vdot(m, d), I.idiv(I.imul(X.vdot(a, m), X.vdot(a, d)), X.vdot(a, a)))
  +rl = I.i_lo(rb)
  +e = Bool.pick(F64, F64.is_lt(0.0f64, rl), F64.mul(F64.div(I.i_hi(iabs(n)), rl), F64.mul(0.5f64, F64.sub(I.i_hi(t), I.i_lo(t)))), V.dbl_max())
  I.I{F64.max(F64.sub(I.i_lo(rm), e), rl), F64.min(F64.add(I.i_hi(rm), e), I.i_hi(rb))}

def flip(mx: Bool, +v: I.I) -> I.I:
  match mx:
    case True{}: I.I{F64.neg(I.i_hi(v)), F64.neg(I.i_lo(v))}
    case False{}: v

type Es is Data:
  Es{ st: List<&2, Pc>, lb: F64 }

def ebb_step(leaf: Bool, +t: I.I, +d: Nat, +rest: List<&2, Pc>, +lb: F64, +vl: F64) -> Es:
  match leaf:
    case True{}: Es{rest, F64.min(lb, vl)}
    case False{}:
      +h = mid1(t)
      Es{Pc{I.I{I.i_lo(t), I.i_hi(h)}, Nat.sub(d, 1n)} <> Pc{I.I{I.i_lo(h), I.i_hi(t)}, Nat.sub(d, 1n)} <> rest, lb}

def ebb(fuel: Nat, e: Es, +mx: Bool, +o: List<&2, I.I>, +a: List<&2, I.I>, +c: R.Cv, +ub: F64, +tol: F64) -> F64:
  match fuel:
    case 0n: F64.neg(V.dbl_max())
    case 1n+(+f):
      match e:
        case Es{st, +lb}:
          match st:
            case []: lb
            case Pc{+t, +d} <> +rest:
              +v = flip(mx, rmv(o, a, c, t))
              +ub2 = F64.min(ub, I.i_hi(flip(mx, ax_rho(o, a, R.cv_box(c, mid1(t))))))
              ebb(f, ebb_step(Bool.or(F64.is_le(F64.sub(ub2, tol), I.i_lo(v)), Nat.is_eq(d, 0n)), t, d, rest, lb, I.i_lo(v)), mx, o, a, c, ub2, tol)

def e_ext(tight: Bool, +q: I.I, +mx: Bool, +o: List<&2, I.I>, +a: List<&2, I.I>, +c: R.Cv, +tol: F64) -> F64:
  match tight:
    case True{}: I.i_lo(flip(mx, q))
    case False{}: ebb(256n, Es{[Pc{I.I{0.0f64, 1.0f64}, 24n}], V.dbl_max()}, mx, o, a, c, V.dbl_max(), tol)

def e_one(+mx: Bool, +o: List<&2, I.I>, +a: List<&2, I.I>, +c: R.Cv, +tol: F64) -> F64:
  +q = alg_rho(o, a, c)
  e_ext(F64.is_le(F64.sub(I.i_hi(q), I.i_lo(q)), tol), q, mx, o, a, c, tol)

def es_ext(es: List<&2, Mm.Er>, +mx: Bool, +o: List<&2, I.I>, +a: List<&2, I.I>, +tol: F64, +acc: F64) -> F64:
  match es:
    case []: acc
    case +e <> +t: es_ext(t, mx, o, a, tol, F64.min(acc, e_one(mx, o, a, Mm.er_c(e), tol)))

def pl_rmin(ins: Bool, +es: List<&2, Mm.Er>, +o: List<&2, I.I>, +a: List<&2, I.I>, +tol: F64) -> F64:
  match ins:
    case True{}: 0.0f64
    case False{}: F64.max(0.0f64, es_ext(es, False{}, o, a, tol, V.dbl_max()))

def fl_go(par: Bool, +o: List<&2, I.I>, +a: List<&2, I.I>, +r: I.I, +cbx: List<&2, I.I>, +fp: SO.Fd, +op: List<&2, I.I>, +k: F64) -> F64:
  match par:
    case False{}: 0.0f64
    case True{}:
      +es = Mm.fc_es(SO.fd_fc(fp))
      +tol = F64.mul(1.0e-9f64, F64.add(1.0f64, diag(SO.fd_bx(fp))))
      +p0 = X.vadd(o, Mm.vs(I.idiv(X.vdot(a, X.vsub(op, o)), X.vdot(a, a)), a))
      +ins = Bool.not(U64.is_eq(Mm.member(SO.fd_fc(fp), p0, SO.fd_im(fp)), 0u64))
      +lo = pl_rmin(ins, es, o, a, tol)
      +hi = F64.neg(es_ext(es, True{}, o, a, tol, V.dbl_max()))
      +g = I.i_lo(I.isqrt(I.iadd(I.isq(I.ipt(gap1(I.I{I.i_lo(r), I.i_hi(r)}, I.I{lo, F64.max(lo, hi)}))), I.isq(I.ipt(gap1(ax_h(o, a, cbx), ax_h(o, a, op)))))))
      F64.max(0.0f64, F64.sub(g, k))

def fl_cp(+o: List<&2, I.I>, +a: List<&2, I.I>, +r: I.I, +cbx: List<&2, I.I>, +fp: SO.Fd, +op: List<&2, I.I>, +n: List<&2, I.I>) -> F64:
  +sn = F64.div(I.i_hi(I.isqrt(pos(X.vdot(Im.cross(a, n), Im.cross(a, n))))), F64.mul(I.i_lo(I.isqrt(pos(X.vdot(a, a)))), I.i_lo(I.isqrt(pos(X.vdot(n, n))))))
  +k = F64.mul(sn, I.i_hi(I.isqrt(pos(X.vdot(X.vsub(cbx, op), X.vsub(cbx, op))))))
  fl_go(Bool.and(F64.is_le(sn, 1.0e-12f64), Nat.is_lt(0n, List.length(&2, Mm.Er, Mm.fc_es(SO.fd_fc(fp))))), o, a, r, cbx, fp, op, k)

def fl_of(sa: Im.Im, sb: Im.Im, +fa: SO.Fd, +fb: SO.Fd) -> F64:
  match sa:
    case Im.M_cy{+o, +a, +r}:
      match sb:
        case Im.M_pl{+op, +n}: fl_cp(o, a, r, SO.fd_bx(fa), fb, op, n)
        case _: 0.0f64
    case Im.M_pl{+op, +n}:
      match sb:
        case Im.M_cy{+o, +a, +r}: fl_cp(o, a, r, SO.fd_bx(fb), fa, op, n)
        case _: 0.0f64
    case _: 0.0f64

def rr_go(par: Bool, +o: List<&2, I.I>, +a: List<&2, I.I>, +fp: SO.Fd, +op: List<&2, I.I>) -> I.I:
  match par:
    case False{}: rr_all()
    case True{}:
      +es = Mm.fc_es(SO.fd_fc(fp))
      +tol = F64.mul(1.0e-9f64, F64.add(1.0f64, diag(SO.fd_bx(fp))))
      +p0 = X.vadd(o, Mm.vs(I.idiv(X.vdot(a, X.vsub(op, o)), X.vdot(a, a)), a))
      +ins = Bool.not(U64.is_eq(Mm.member(SO.fd_fc(fp), p0, SO.fd_im(fp)), 0u64))
      +lo = pl_rmin(ins, es, o, a, tol)
      +hi = F64.neg(es_ext(es, True{}, o, a, tol, V.dbl_max()))
      I.I{lo, F64.max(lo, hi)}

def rr_ax(+o: List<&2, I.I>, +a: List<&2, I.I>, +fp: SO.Fd, +op: List<&2, I.I>, +n: List<&2, I.I>) -> I.I:
  +sn = F64.div(vlen_hi(Im.cross(a, n)), F64.mul(vlen_lo(a), vlen_lo(n)))
  rr_go(Bool.and(F64.is_le(sn, 1.0e-12f64), Nat.is_lt(0n, List.length(&2, Mm.Er, Mm.fc_es(SO.fd_fc(fp))))), o, a, fp, op)

def rr_oth(so: Im.Im, +fp: SO.Fd, +op: List<&2, I.I>, +n: List<&2, I.I>) -> I.I:
  match so:
    case Im.M_cy{+o, +a, r}: rr_ax(o, a, fp, op, n)
    case Im.M_co{+o, +a, k}: rr_ax(o, a, fp, op, n)
    case Im.M_to{+o, +a, bigr, r}: rr_ax(o, a, fp, op, n)
    case _: rr_all()

def rr_pair(ss: Im.Im, so: Im.Im, +fp: SO.Fd) -> I.I:
  match ss:
    case Im.M_pl{+op, +n}: rr_oth(so, fp, op, n)
    case _: rr_all()

type U2 is Data:
  U2{ x: F64, y: F64 }

type Ar is Data:
  Ar{ cr: F64, ch: F64, r: F64, ua: U2, ub: U2, s: F64 }

type Ft is Data:
  Ft_no{}
  Ft_r{ p: I.I, h: I.I, e: F64 }
  Ft_a{ ar: Ar, e: F64 }

def u2_x(+u: U2) -> F64:
  U2{+x, y} = u
  x

def u2_y(+u: U2) -> F64:
  U2{x, +y} = u
  y

def u2_len(+x: F64, +y: F64) -> F64:
  F64.sqrt(F64.add(F64.mul(x, x), F64.mul(y, y)))

def u2_unit(+x: F64, +y: F64) -> U2:
  +l = u2_len(x, y)
  U2{F64.div(x, l), F64.div(y, l)}

def u2_cross(+a: U2, +b: U2) -> F64:
  F64.sub(F64.mul(u2_x(a), u2_y(b)), F64.mul(u2_y(a), u2_x(b)))

def u2_dot(+a: U2, +b: U2) -> F64:
  F64.add(F64.mul(u2_x(a), u2_x(b)), F64.mul(u2_y(a), u2_y(b)))

def ar_minor(+s: F64, +a: U2, +b: U2) -> Bool:
  +c = F64.mul(s, u2_cross(a, b))
  Bool.or(F64.is_lt(1.0e-12f64, c), Bool.and(F64.is_le(F64.abs(c), 1.0e-12f64), F64.is_lt(0.0f64, u2_dot(a, b))))

def ar_mid(+s: F64, +a: U2, +b: U2) -> U2:
  +sx = F64.add(u2_x(a), u2_x(b))
  +sy = F64.add(u2_y(a), u2_y(b))
  +l = u2_len(sx, sy)
  +sm = Bool.pick(F64, ar_minor(s, a, b), 1.0f64, F64.neg(1.0f64))
  Bool.pick(U2, F64.is_lt(1.0e-9f64, l), U2{F64.mul(sm, F64.div(sx, l)), F64.mul(sm, F64.div(sy, l))},
    U2{F64.mul(F64.neg(s), u2_y(a)), F64.mul(s, u2_x(a))})

def ar_pad(+cr: F64, +ch: F64, +r: F64) -> F64:
  F64.mul(1.0e-12f64, F64.add(1.0f64, F64.add(F64.abs(cr), F64.add(F64.abs(ch), r))))

def ar_rect(+cr: F64, +ch: F64, +r: F64, +s: F64, +a: U2, +b: U2) -> Bd:
  +pd = ar_pad(cr, ch, r)
  +x0 = F64.add(cr, F64.mul(r, u2_x(a)))
  +y0 = F64.add(ch, F64.mul(r, u2_y(a)))
  +x1 = F64.add(cr, F64.mul(r, u2_x(b)))
  +y1 = F64.add(ch, F64.mul(r, u2_y(b)))
  +hc = F64.mul(0.5f64, u2_len(F64.sub(x1, x0), F64.sub(y1, y0)))
  +sg = F64.add(F64.sub(r, F64.sqrt(F64.max(0.0f64, F64.sub(F64.mul(r, r), F64.mul(hc, hc))))), pd)
  +w = F64.add(r, pd)
  Bool.pick(Bd, ar_minor(s, a, b),
    Bd{I.I{F64.sub(F64.min(x0, x1), sg), F64.add(F64.max(x0, x1), sg)}, I.I{F64.sub(F64.min(y0, y1), sg), F64.add(F64.max(y0, y1), sg)}},
    Bd{I.I{F64.sub(cr, w), F64.add(cr, w)}, I.I{F64.sub(ch, w), F64.add(ch, w)}})

def ar_lb(+cr: F64, +ch: F64, +r: F64, +s: F64, +a: U2, +b: U2, +q: Bd) -> F64:
  bd_d(ar_rect(cr, ch, r, s, a, b), q)

def arc_rect_go(d: Nat, stop: Bool, +lb: F64, +cr: F64, +ch: F64, +r: F64, +s: F64, +a: U2, +b: U2, +q: Bd, +cut: F64) -> F64:
  match d stop:
    case 0n _: lb
    case 1n++e True{}: lb
    case 1n++e False{}:
      +m = ar_mid(s, a, b)
      +l1 = ar_lb(cr, ch, r, s, a, m, q)
      +l2 = ar_lb(cr, ch, r, s, m, b, q)
      F64.min(arc_rect_go(e, F64.is_le(cut, l1), l1, cr, ch, r, s, a, m, q, cut), arc_rect_go(e, F64.is_le(cut, l2), l2, cr, ch, r, s, m, b, q, cut))

def arc_rect(+x: Ar, +q: Bd, +cut: F64) -> F64:
  Ar{+cr, +ch, +r, +a, +b, +s} = x
  +l = ar_lb(cr, ch, r, s, a, b, q)
  arc_rect_go(28n, F64.is_le(cut, l), l, cr, ch, r, s, a, b, q, cut)

def aa_lb(+x: Ar, +y: Ar) -> F64:
  Ar{+cr, +ch, +r, +a, +b, +s} = x
  Ar{+cr2, +ch2, +r2, +a2, +b2, +s2} = y
  bd_d(ar_rect(cr, ch, r, s, a, b), ar_rect(cr2, ch2, r2, s2, a2, b2))

def ar_lo(+x: Ar) -> Ar:
  Ar{+cr, +ch, +r, +a, +b, +s} = x
  Ar{cr, ch, r, a, ar_mid(s, a, b), s}

def ar_hi(+x: Ar) -> Ar:
  Ar{+cr, +ch, +r, +a, +b, +s} = x
  Ar{cr, ch, r, ar_mid(s, a, b), b, s}

def arc_arc_go(d: Nat, stop: Bool, +lb: F64, +x: Ar, +y: Ar, +cut: F64) -> F64:
  match d stop:
    case 0n _: lb
    case 1n++e True{}: lb
    case 1n++e False{}:
      +l1 = aa_lb(ar_lo(x), ar_lo(y))
      +l2 = aa_lb(ar_lo(x), ar_hi(y))
      +l3 = aa_lb(ar_hi(x), ar_lo(y))
      +l4 = aa_lb(ar_hi(x), ar_hi(y))
      F64.min(F64.min(arc_arc_go(e, F64.is_le(cut, l1), l1, ar_lo(x), ar_lo(y), cut), arc_arc_go(e, F64.is_le(cut, l2), l2, ar_lo(x), ar_hi(y), cut)),
        F64.min(arc_arc_go(e, F64.is_le(cut, l3), l3, ar_hi(x), ar_lo(y), cut), arc_arc_go(e, F64.is_le(cut, l4), l4, ar_hi(x), ar_hi(y), cut)))

def arc_arc(+x: Ar, +y: Ar, +cut: F64) -> F64:
  +l = aa_lb(x, y)
  arc_arc_go(14n, F64.is_le(cut, l), l, x, y, cut)

def ft_lb(+f: Ft, +g: Ft, +cut: F64) -> F64:
  match f:
    case Ft_no{}: 0.0f64
    case Ft_r{+p, +h, +e}:
      match g:
        case Ft_no{}: 0.0f64
        case Ft_r{+p2, +h2, +e2}: F64.max(0.0f64, F64.sub(bd_d(Bd{p, h}, Bd{p2, h2}), F64.add(e, e2)))
        case Ft_a{+y, +e2}: F64.max(0.0f64, F64.sub(arc_rect(y, Bd{p, h}, cut), F64.add(e, e2)))
    case Ft_a{+x, +e}:
      match g:
        case Ft_no{}: 0.0f64
        case Ft_r{+p2, +h2, +e2}: F64.max(0.0f64, F64.sub(arc_rect(x, Bd{p2, h2}, cut), F64.add(e, e2)))
        case Ft_a{+y, +e2}: F64.max(0.0f64, F64.sub(arc_arc(x, y, cut), F64.add(e, e2)))

type Mp is Data:
  Mp{ ok: Bool, x: F64, y: F64 }

def wtol(+cr: F64, +ch: F64, +r: F64) -> F64:
  F64.mul(1.0e-9f64, F64.add(1.0f64, F64.add(F64.abs(cr), F64.add(F64.abs(ch), r))))

def ep_of(+o: List<&2, I.I>, +a: List<&2, I.I>, +c: R.Cv, +tl: F64) -> Mp:
  +p = alg_rho(o, a, c)
  +h = ax_h(o, a, R.cv_hbox(c))
  Mp{Bool.and(F64.is_le(F64.sub(I.i_hi(p), I.i_lo(p)), tl), F64.is_le(F64.sub(I.i_hi(h), I.i_lo(h)), tl)),
    I.imid(p), I.imid(h)}

type Ac is Data:
  Ac{ ok: Bool, n: Nat, a: U2, b: U2 }

def ac_put(+st: Ac, +u: U2) -> Ac:
  Ac{+ok, +n, +a, +b} = st
  +same_a = F64.is_lt(u2_len(F64.sub(u2_x(u), u2_x(a)), F64.sub(u2_y(u), u2_y(a))), 1.0e-6f64)
  +same_b = F64.is_lt(u2_len(F64.sub(u2_x(u), u2_x(b)), F64.sub(u2_y(u), u2_y(b))), 1.0e-6f64)
  Bool.pick(Ac, Nat.is_eq(n, 0n), Ac{ok, 1n, u, u},
    Bool.pick(Ac, Bool.or(same_a, Bool.and(Nat.is_eq(n, 2n), same_b)), Ac{ok, n, a, b},
      Bool.pick(Ac, Nat.is_eq(n, 1n), Ac{ok, 2n, a, u}, Ac{False{}, n, a, b})))

def ac_bad(+gen: Bool, +st: Ac) -> Ac:
  Ac{+ok, +n, +a, +b} = st
  Ac{Bool.and(ok, gen), n, a, b}

def ac_edge(+m: Mp, +gen: Bool, +st: Ac, +cr: F64, +ch: F64) -> Ac:
  Mp{+ok, +x, +y} = m
  Bool.pick(Ac, ok, ac_put(st, u2_unit(F64.sub(x, cr), F64.sub(y, ch))), ac_bad(gen, st))

def pl_go(xs: List<&2, I.I>, ys: List<&2, I.I>, zs: List<&2, I.I>, ws: List<&2, I.I>, +n: List<&2, I.I>, +no: I.I, +tl: F64) -> Bool:
  match xs ys zs ws:
    case +x <> +xt +y <> +yt +z <> +zt +w <> +wt:
      +v = I.isub(X.vdot(n, [x, y, z]), I.imul(w, no))
      Bool.and(F64.is_le(I.i_hi(iabs(v)), F64.mul(tl, I.i_lo(iabs(w)))), pl_go(xt, yt, zt, wt, n, no, tl))
    case _ _ _ _: True{}

def gen_rb(+rb: R.Rb, +n: List<&2, I.I>, +no: I.I, +tl: F64) -> Bool:
  R.Rb{+xs, +ys, +zs, +ws} = rb
  pl_go(xs, ys, zs, ws, n, no, tl)

def is_gen(+o: List<&2, I.I>, +a: List<&2, I.I>, +c: R.Cv, +tl: F64) -> Bool:
  +n = Im.cross(a, X.vsub(R.cv_box(c, I.ipt(0.5f64)), o))
  +nl = I.i_lo(I.isqrt(pos(X.vdot(n, n))))
  Bool.and(F64.is_lt(tl, nl), gen_rb(R.cv_rb(c), n, X.vdot(n, o), F64.mul(tl, nl)))

def ac_go(es: List<&2, Mm.Er>, +o: List<&2, I.I>, +a: List<&2, I.I>, +cr: F64, +ch: F64, +tl: F64, +st: Ac) -> Ac:
  match es:
    case []: st
    case +e <> +t:
      +c = Mm.er_c(e)
      ac_go(t, o, a, cr, ch, tl, ac_edge(ep_of(o, a, c, tl), is_gen(o, a, c, tl), st, cr, ch))

def p3_of(+o: List<&2, I.I>, +a: List<&2, I.I>, +er: List<&2, I.I>, +rho: F64, +h: F64) -> List<&2, I.I>:
  +au = Mm.vs(I.idiv(I.ipt(1.0f64), I.isqrt(X.vdot(a, a))), a)
  X.vadd(o, X.vadd(Mm.vs(I.ipt(h), au), Mm.vs(I.ipt(rho), er)))

def er_of(+o: List<&2, I.I>, +a: List<&2, I.I>, +q: List<&2, I.I>) -> List<&2, I.I>:
  +m = X.vsub(q, o)
  +rv = X.vsub(m, Mm.vs(I.idiv(X.vdot(a, m), X.vdot(a, a)), a))
  Mm.vs(I.idiv(I.ipt(1.0f64), I.isqrt(X.vdot(rv, rv))), rv)

def in_face(+f: SO.Fd, +p: List<&2, I.I>) -> Bool:
  U64.is_eq(Mm.member(SO.fd_fc(f), SO.snap(SO.proj(SO.fd_im(f), p)), SO.fd_im(f)), 1u64)

def ar_pick(sp: Bool, sn: Bool, +ok: Bool, +cr: F64, +ch: F64, +r: F64, +a: U2, +b: U2, +e: F64) -> Ft:
  match sp:
    case True{}: Bool.pick(Ft, Bool.and(ok, Bool.not(sn)), Ft_a{Ar{cr, ch, r, a, b, 1.0f64}, e}, Ft_no{})
    case False{}: Bool.pick(Ft, Bool.and(ok, sn), Ft_a{Ar{cr, ch, r, a, b, F64.neg(1.0f64)}, e}, Ft_no{})

def ar_fin(+st: Ac, +o: List<&2, I.I>, +a0: List<&2, I.I>, +f: SO.Fd, +er: List<&2, I.I>, +cr: F64, +ch: F64, +r: F64, +e: F64) -> Ft:
  Ac{+ok, +n, +a, +b} = st
  +mp = ar_mid(1.0f64, a, b)
  +mn = ar_mid(F64.neg(1.0f64), a, b)
  +qp = p3_of(o, a0, er, F64.add(cr, F64.mul(r, u2_x(mp))), F64.add(ch, F64.mul(r, u2_y(mp))))
  +qn = p3_of(o, a0, er, F64.add(cr, F64.mul(r, u2_x(mn))), F64.add(ch, F64.mul(r, u2_y(mn))))
  ar_pick(in_face(f, qp), in_face(f, qn), Bool.and(ok, Nat.is_eq(n, 2n)), cr, ch, r, a, b, e)

def ar_of(m: Maybe<&2, List<&2, I.I>>, +o: List<&2, I.I>, +a: List<&2, I.I>, +f: SO.Fd, +cr: F64, +ch: F64, +r: F64, +e: F64) -> Ft:
  match m:
    case None{}: Ft_no{}
    case Some{+q}:
      +z = {U2{1.0f64, 0.0f64} : U2}
      ar_fin(ac_go(Mm.fc_es(SO.fd_fc(f)), o, a, cr, ch, wtol(cr, ch, r), Ac{True{}, 0n, z, z}), o, a, f, er_of(o, a, q), cr, ch, r, e)

def iw(+x: I.I) -> F64:
  F64.sub(I.i_hi(x), I.i_lo(x))

def ft_of(s: Im.Im, +o: List<&2, I.I>, +a: List<&2, I.I>, +f: SO.Fd, +rr: I.I) -> Ft:
  match s:
    case Im.M_cy{+so, +sa, +r}:
      +bx = SO.fd_bx(f)
      +e = slack(so, sa, o, a, bx)
      Ft_r{r, ax_h(o, a, bx), e}
    case Im.M_pl{+op, +n}:
      +bx = SO.fd_bx(f)
      Bool.pick(Ft, F64.is_lt(I.i_hi(rr), V.dbl_max()), Ft_r{rr, ax_h(o, a, op), tilt(n, a, bx, op)}, Ft_no{})
    case Im.M_to{+so, +sa, +bigr, +r}:
      +bx = SO.fd_bx(f)
      +hc = ax_h(o, a, so)
      +e = F64.add(F64.mul(2.0f64, slack(so, sa, o, a, bx)), F64.add(iw(bigr), F64.add(iw(hc), iw(r))))
      ar_of(SO.interior(f), o, a, f, I.imid(bigr), I.imid(hc), I.imid(r), e)
    case Im.M_sp{+so, +r}:
      +hc = ax_h(o, a, so)
      +e = F64.add(I.i_hi(ax_rho(o, a, so)), F64.add(iw(hc), iw(r)))
      ar_of(SO.interior(f), o, a, f, 0.0f64, I.imid(hc), I.imid(r), e)
    case _: Ft_no{}

def fl2_ax(+o: List<&2, I.I>, +a: List<&2, I.I>, +fa: SO.Fd, +fb: SO.Fd, +ra: I.I, +rb: I.I, +cut: F64) -> F64:
  ft_lb(ft_of(SO.fd_im(fa), o, a, fa, ra), ft_of(SO.fd_im(fb), o, a, fb, rb), cut)

def fl2_s(s: Im.Im, +fa: SO.Fd, +fb: SO.Fd, +ra: I.I, +rb: I.I, +cut: F64) -> F64:
  match s:
    case Im.M_cy{+o, +a, r}: fl2_ax(o, a, fa, fb, ra, rb, cut)
    case Im.M_co{+o, +a, k}: fl2_ax(o, a, fa, fb, ra, rb, cut)
    case Im.M_to{+o, +a, bigr, r}: fl2_ax(o, a, fa, fb, ra, rb, cut)
    case _: 0.0f64

def fl2(+fa: SO.Fd, +fb: SO.Fd, +ra: I.I, +rb: I.I, +cut: F64) -> F64:
  F64.max(fl2_s(SO.fd_im(fa), fa, fb, ra, rb, cut), fl2_s(SO.fd_im(fb), fa, fb, ra, rb, cut))

def with_fl(+x: Cb, +cut: F64) -> Cb:
  Cb{+a, +b, +fs, fl, ra, rb} = x
  +fa = f0(fs)
  +fb = f1(fs)
  +qa = rr_pair(SO.fd_im(fa), SO.fd_im(fb), fa)
  +qb = rr_pair(SO.fd_im(fb), SO.fd_im(fa), fb)
  Cb{a, b, fs, F64.max(fl_of(SO.fd_im(fa), SO.fd_im(fb), fa, fb), fl2(fa, fb, qa, qb, cut)), qa, qb}

def root_k(near: Bool, +w: Bool, +k: F64, +x: Cb, +h: Ph, +hi: F64, +eps: F64) -> Ph:
  match near:
    case False{}: h
    case True{}:
      +y = with_fl(x, hi)
      +k2 = F64.max(k, lbk(w, y))
      push_k(F64.is_lt(k2, hi), k2, y, h, eps)

def root_all(xs: List<&2, Cb>, +h: Ph, +w: Bool, +hi: F64, +eps: F64) -> Ph:
  match xs:
    case []: h
    case +x <> +t:
      +k = lbk(w, x)
      root_all(t, root_k(F64.is_lt(k, hi), w, k, x, h, hi, eps), w, hi, eps)

def wit_if(go: Bool, +w: Bool, +x: Cb) -> F64:
  match go:
    case True{}: wit(w, x)
    case False{}: V.dbl_max()

def search(fuel: Nat, stop: Bool, h: Ph, +w: Bool, +hi: F64, +eps: F64, +minw: F64) -> I.I:
  match fuel:
    case 0n: I.I{ph_min(h, hi), hi}
    case 1n+(+f):
      match stop:
        case True{}: I.I{ph_min(h, hi), hi}
        case False{}:
          match h:
            case Ph_e{}: I.I{hi, hi}
            case Ph_n{k, q, bw, +x, +cs}:
              +hw = F64.min(hi, wit_if(Bool.or(Nat.is_lt(99776n, f), Nat.is_eq(Nat.mod(f, 256n), 0n)), w, x))
              +h2 = push_all(kids(x, F64.mul(0.5f64, hw)), pairs(cs), w, hw, eps)
              search(f, stop_of(h2, hw, eps, minw), h2, w, hw, eps, minw)

def best_lo_t(+cs: List<&2, Cb>, +w: Bool, +hi: F64, +tol: F64) -> I.I:
  +sc = F64.add(1.0f64, hi)
  +eps = F64.max(F64.mul(1.0e-6f64, sc), tol)
  +h = root_all(cs, Ph_e{}, w, hi, eps)
  search(99841n, stop_of(h, hi, eps, eps), h, w, hi, eps, eps)

def best_lo(+cs: List<&2, Cb>, +w: Bool, +hi: F64) -> I.I:
  best_lo_t(cs, w, hi, 0.0f64)

def cross_b(fbs: List<&2, SO.Fd>, +fa: SO.Fd, +acc: List<&2, Cb>) -> List<&2, Cb>:
  match fbs:
    case []: acc
    case +fb <> +t: cross_b(t, fa, cb(fa, fb) <> acc)

def cross(fas: List<&2, SO.Fd>, +fbs: List<&2, SO.Fd>, +acc: List<&2, Cb>) -> List<&2, Cb>:
  match fas:
    case []: acc
    case +fa <> +t: cross(t, fbs, cross_b(fbs, fa, acc))

def world_fds(+b: M.Body) -> List<&2, SO.Fd>:
  +pl = M.bd_pl(b)
  SO.fds_of(BO.xf_brep(M.pl_m(pl), M.pl_tx(pl), M.pl_ty(pl), M.pl_tz(pl), M.bd_brep(b)))

def cert_go(ok: Bool, +fas: List<&2, SO.Fd>, +fbs: List<&2, SO.Fd>, +lo0: F64, +hi: F64, +tol: F64) -> I.I:
  match ok:
    case False{}: I.I{lo0, hi}
    case True{}:
      +r = best_lo_t(cross(fas, fbs, []), False{}, hi, tol)
      I.I{F64.max(lo0, I.i_lo(r)), I.i_hi(r)}

def cert_lo_t(+a: M.Body, +b: M.Body, +lo0: F64, +hi: F64, +tol: F64) -> I.I:
  +fas = world_fds(a)
  +fbs = world_fds(b)
  cert_go(Bool.and(QA.fd_allok(fas), QA.fd_allok(fbs)), fas, fbs, lo0, hi, tol)

def cert_lo(+a: M.Body, +b: M.Body, +lo0: F64, +hi: F64) -> I.I:
  cert_lo_t(a, b, lo0, hi, 0.0f64)

def wall_lo(+cs: List<&2, Cb>, +hi: F64) -> I.I:
  best_lo(cs, True{}, hi)

