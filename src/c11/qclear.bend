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
  Cb{ a: List<&2, I.I>, b: List<&2, I.I>, fs: List<&2, SO.Fd>, fl: F64 }

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

def cb(+fa: SO.Fd, +fb: SO.Fd) -> Cb:
  Cb{SO.fd_bx(fa), SO.fd_bx(fb), [fa, fb], 0.0f64}

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

def mer(sa: Im.Im, sb: Im.Im, +ca: List<&2, I.I>, +cb: List<&2, I.I>) -> F64:
  match sa:
    case Im.M_cy{+o, +a, r}: mer_ax(o, a, sa, sb, ca, cb)
    case Im.M_co{+o, +a, k}: mer_ax(o, a, sa, sb, ca, cb)
    case Im.M_to{+o, +a, bigr, r}: mer_ax(o, a, sa, sb, ca, cb)
    case _: mer_b(sa, sb, ca, cb)

def pair_lb(+c: Cb) -> F64:
  Cb{+a, +b, +fs, +fl} = c
  +fa = f0(fs)
  +fb = f1(fs)
  F64.max(F64.max(F64.max(box_gap(a, b), fl), mer(SO.fd_im(fa), SO.fd_im(fb), a, b)),
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
  Cb{+a, +b, +fs, +fl} = c
  +sa = F64.is_le(wid(b), wid(a))
  +x = Bool.pick(List<&2, I.I>, sa, a, b)
  +f = Bool.pick(SO.Fd, sa, f0(fs), f1(fs))
  +k = axis_of(x)
  +lo = cut(x, k, False{})
  +hi = cut(x, k, True{})
  +cl = Bool.pick(Cb, sa, Cb{lo, b, fs, fl}, Cb{a, lo, fs, fl})
  +ch = Bool.pick(Cb, sa, Cb{hi, b, fs, fl}, Cb{a, hi, fs, fl})
  List.append(&2, Cb, Bool.pick(List<&2, Cb>, on_face(lo, f, w0), [cl], []), Bool.pick(List<&2, Cb>, on_face(hi, f, w0), [ch], []))

def wid2(+c: Cb) -> F64:
  Cb{+a, +b, fs, fl} = c
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
  Cb{+a, +b, +fs, fl} = c
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
  Cb{+a, +b, +fs, fl} = x
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

def with_fl(+x: Cb) -> Cb:
  Cb{+a, +b, +fs, fl} = x
  +fa = f0(fs)
  +fb = f1(fs)
  Cb{a, b, fs, fl_of(SO.fd_im(fa), SO.fd_im(fb), fa, fb)}

def root_k(near: Bool, +w: Bool, +k: F64, +x: Cb, +h: Ph, +hi: F64, +eps: F64) -> Ph:
  match near:
    case False{}: h
    case True{}:
      +y = with_fl(x)
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

def best_lo(+cs: List<&2, Cb>, +w: Bool, +hi: F64) -> I.I:
  +sc = F64.add(1.0f64, hi)
  +eps = F64.mul(1.0e-6f64, sc)
  +h = root_all(cs, Ph_e{}, w, hi, eps)
  search(99841n, stop_of(h, hi, eps, eps), h, w, hi, eps, eps)

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

def cert_go(ok: Bool, +fas: List<&2, SO.Fd>, +fbs: List<&2, SO.Fd>, +lo0: F64, +hi: F64) -> I.I:
  match ok:
    case False{}: I.I{lo0, hi}
    case True{}:
      +r = best_lo(cross(fas, fbs, []), False{}, hi)
      I.I{F64.max(lo0, I.i_lo(r)), I.i_hi(r)}

def cert_lo(+a: M.Body, +b: M.Body, +lo0: F64, +hi: F64) -> I.I:
  +fas = world_fds(a)
  +fbs = world_fds(b)
  cert_go(Bool.and(QA.fd_allok(fas), QA.fd_allok(fbs)), fas, fbs, lo0, hi)

def wall_lo(+cs: List<&2, Cb>, +hi: F64) -> I.I:
  best_lo(cs, True{}, hi)

