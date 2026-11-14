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
import ../c07/xs.bend as Q
import ../c03/types.bend as G

type Bd is Data:
  Bd{ p: I.I, h: I.I }

def iabs(+a: I.I) -> I.I:
  I.I{+lo, +hi} = a
  Bool.pick(I.I, F64.is_le(0.0f64, lo), a,
    Bool.pick(I.I, F64.is_le(hi, 0.0f64), I.ineg(a), I.I{0.0f64, F64.max(F64.neg(lo), hi)}))

def pos(+a: I.I) -> I.I:
  I.I{+lo, +hi} = a
  I.I{F64.max(lo, 0.0f64), F64.max(hi, 0.0f64)}

def ax_h(+o: List<&2, I.I>, +a: List<&2, I.I>, +p: List<&2, I.I>) -> I.I:
  I.idiv(X.vdot(a, X.vsub(p, o)), I.isqrt(X.vdot(a, a)))

def nsq(+v: List<&2, I.I>) -> I.I:
  I.iadd(I.iadd(I.isq(X.vn(v, 0n)), I.isq(X.vn(v, 1n))), I.isq(X.vn(v, 2n)))

def ax_rho(+o: List<&2, I.I>, +a: List<&2, I.I>, +p: List<&2, I.I>) -> I.I:
  I.idiv(I.isqrt(nsq(Im.cross(a, X.vsub(p, o)))), I.isqrt(nsq(a)))

def sdist(s: Im.Im, +p: List<&2, I.I>) -> F64:
  match s:
    case Im.M_pl{o, +n}: I.i_lo(iabs(I.idiv(X.vdot(n, X.vsub(p, o)), I.isqrt(X.vdot(n, n)))))
    case Im.M_sp{o, r}: I.i_lo(iabs(I.isub(I.isqrt(nsq(X.vsub(p, o))), r)))
    case Im.M_cy{+o, +a, r}: I.i_lo(iabs(I.isub(ax_rho(o, a, p), r)))
    case Im.M_co{+o, +a, +k}:
      I.i_lo(iabs(I.idiv(I.isub(ax_rho(o, a, p), I.imul(iabs(k), iabs(ax_h(o, a, p)))), I.isqrt(I.iadd(I.ipt(1.0f64), I.isq(k))))))
    case Im.M_to{+o, +a, bigr, r}:
      I.i_lo(iabs(I.isub(I.isqrt(I.iadd(I.isq(I.isub(ax_rho(o, a, p), bigr)), I.isq(ax_h(o, a, p)))), r)))
    case Im.M_no{}: 0.0f64

def gap1(+a: I.I, +b: I.I) -> F64:
  F64.max(0.0f64, F64.max(F64.sub(I.i_lo(a), I.i_hi(b)), F64.sub(I.i_lo(b), I.i_hi(a))))

def box_gap(+a: List<&2, I.I>, +b: List<&2, I.I>) -> F64:
  +gx = gap1(X.vn(a, 0n), X.vn(b, 0n))
  +gy = gap1(X.vn(a, 1n), X.vn(b, 1n))
  +gz = gap1(X.vn(a, 2n), X.vn(b, 2n))
  I.i_lo(I.isqrt(I.iadd(I.iadd(I.isq(I.ipt(gx)), I.isq(I.ipt(gy))), I.isq(I.ipt(gz)))))

def rr_all() -> I.I:
  I.I{0.0f64, V.dbl_max()}

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
    case Im.M_no{}: [Bd{p, h}]

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

def nrm_hi(+v: List<&2, I.I>) -> F64:
  I.i_hi(I.isqrt(pos(X.vdot(v, v))))

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

def ph_all(hs: List<&2, Ph>, +acc: F64) -> F64:
  match hs:
    case []: acc
    case +h <> +t:
      match h:
        case Ph_e{}: ph_all(t, acc)
        case Ph_n{+k, q, w, x, +cs}: ph_all(t, ph_all(cs, F64.min(acc, k)))

def ph_min(+h: Ph, +hi: F64) -> F64:
  ph_all([h], hi)

def mid1(+a: I.I) -> I.I:
  I.ipt(F64.mul(0.5f64, F64.add(I.i_lo(a), I.i_hi(a))))

def mid(+a: List<&2, I.I>) -> List<&2, I.I>:
  [mid1(X.vn(a, 0n)), mid1(X.vn(a, 1n)), mid1(X.vn(a, 2n))]

def on_pt(fin: Bool, +f: SO.Fd, +q: List<&2, I.I>) -> Bool:
  match fin:
    case False{}: False{}
    case True{}: U64.is_eq(Mm.member(SO.fd_fc(f), q, SO.fd_im(f)), 1u64)

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

def pc_rest(ps: List<&2, Pc>, +mx: Bool, +o: List<&2, I.I>, +a: List<&2, I.I>, +c: R.Cv, +acc: F64) -> F64:
  match ps:
    case []: acc
    case Pc{+t, d} <> +rest: pc_rest(rest, mx, o, a, c, F64.min(acc, I.i_lo(flip(mx, rmv(o, a, c, t)))))

def ebb_end(e: Es, +mx: Bool, +o: List<&2, I.I>, +a: List<&2, I.I>, +c: R.Cv) -> F64:
  match e:
    case Es{st, +lb}: pc_rest(st, mx, o, a, c, lb)

def ebb(fuel: Nat, e: Es, +mx: Bool, +o: List<&2, I.I>, +a: List<&2, I.I>, +c: R.Cv, +ub: F64, +tol: F64) -> F64:
  match fuel:
    case 0n: ebb_end(e, mx, o, a, c)
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

def es_rho(es: List<&2, Mm.Er>, +o: List<&2, I.I>, +a: List<&2, I.I>, +acc: I.I) -> I.I:
  match es:
    case []: acc
    case +e <> +t: es_rho(t, o, a, ihull(acc, alg_rho(o, a, Mm.er_c(e))))

def rr_go(par: Bool, +o: List<&2, I.I>, +a: List<&2, I.I>, +fp: SO.Fd, +op: List<&2, I.I>) -> I.I:
  match par:
    case False{}: rr_all()
    case True{}:
      +p0 = X.vadd(o, Mm.vs(I.idiv(X.vdot(a, X.vsub(op, o)), X.vdot(a, a)), a))
      +es = Mm.fc_es(SO.fd_fc(fp))
      +tol = F64.mul(1.0e-9f64, F64.add(1.0f64, diag(SO.fd_bx(fp))))
      +lo = pl_rmin(Bool.not(U64.is_eq(Mm.member(SO.fd_fc(fp), p0, SO.fd_im(fp)), 0u64)), es, o, a, tol)
      +hi = F64.neg(es_ext(es, True{}, o, a, tol, V.dbl_max()))
      I.I{lo, F64.max(lo, hi)}

def par_ax(+u: List<&2, I.I>, +a: List<&2, I.I>) -> Bool:
  F64.is_le(vlen_hi(Im.cross(a, u)), F64.mul(1.0e-12f64, F64.mul(vlen_lo(a), vlen_lo(u))))

def perp_ax(+u: List<&2, I.I>, +a: List<&2, I.I>) -> Bool:
  F64.is_le(I.i_hi(iabs(X.vdot(a, u))), F64.mul(1.0e-12f64, F64.mul(vlen_lo(a), vlen_lo(u))))

def mr_ext(ok: Bool, +o: List<&2, I.I>, +a: List<&2, I.I>, +f: SO.Fd) -> I.I:
  match ok:
    case False{}: rr_all()
    case True{}: es_rho(Mm.fc_es(SO.fd_fc(f)), o, a, I.I{V.dbl_max(), F64.neg(V.dbl_max())})

def mr_pl(par: Bool, +perp: Bool, +o: List<&2, I.I>, +a: List<&2, I.I>, +f: SO.Fd, +op: List<&2, I.I>) -> I.I:
  match par:
    case True{}: rr_go(True{}, o, a, f, op)
    case False{}: mr_ext(perp, o, a, f)

def f_ne(+f: SO.Fd) -> Bool:
  Nat.is_lt(0n, List.length(&2, Mm.Er, Mm.fc_es(SO.fd_fc(f))))

def mr_rho(s: Im.Im, +o: List<&2, I.I>, +a: List<&2, I.I>, +f: SO.Fd) -> I.I:
  match s:
    case Im.M_pl{+op, +n}: mr_pl(Bool.and(f_ne(f), par_ax(n, a)), Bool.and(f_ne(f), perp_ax(n, a)), o, a, f, op)
    case Im.M_cy{so, +sa, r}: mr_ext(Bool.and(par_ax(sa, a), f_ne(f)), o, a, f)
    case _: rr_all()

def rr_ax(so: Im.Im, +f: SO.Fd) -> I.I:
  match so:
    case Im.M_cy{+o, +a, r}: mr_rho(SO.fd_im(f), o, a, f)
    case Im.M_co{+o, +a, k}: mr_rho(SO.fd_im(f), o, a, f)
    case Im.M_to{+o, +a, bigr, r}: mr_rho(SO.fd_im(f), o, a, f)
    case _: rr_all()

type En is Data:
  En_f{ f: SO.Fd }
  En_e{ c: R.Cv, s: Im.Im }
  En_v{}

type Cl is Data:
  Cl{ e: En, bx: List<&2, I.I>, t: I.I, st: U64, es: List<&2, Mm.Er> }

type Cb is Data:
  Cb{ a: Cl, b: Cl, ra: I.I, rb: I.I }

type El is Data:
  El{ cs: List<&2, Cl>, ok: Bool, bb: List<&2, I.I> }

type Wp is Data:
  Wp{ ok: Bool, p: List<&2, I.I>, s: F64 }

type Ei is Data:
  Ei{ n: Nat, t: I.I }

def cl_e(c: Cl) -> En:
  Cl{e, bx, t, st, es} = c
  e

def cl_bx(c: Cl) -> List<&2, I.I>:
  Cl{e, bx, t, st, es} = c
  bx

def cl_t(c: Cl) -> I.I:
  Cl{e, bx, t, st, es} = c
  t

def cl_st(c: Cl) -> U64:
  Cl{e, bx, t, st, es} = c
  st

def en_im(e: En) -> Im.Im:
  match e:
    case En_f{f}: SO.fd_im(f)
    case En_e{c, s}: s
    case En_v{}: Im.M_no{}

def unit_t() -> I.I:
  I.I{0.0f64, 1.0f64}

def i_any() -> I.I:
  I.I{F64.neg(V.dbl_max()), V.dbl_max()}

def rp(+a: List<&2, I.I>, +m: List<&2, I.I>) -> List<&2, I.I>:
  Im.cross(Im.cross(a, m), a)

def tor_k(far: Bool, +a: List<&2, I.I>, +m: List<&2, I.I>, +c: List<&2, I.I>, +rho: I.I, +bigr: I.I, +g: List<&2, I.I>) -> List<&2, I.I>:
  match far:
    case False{}: g
    case True{}: X.vadd(Mm.vs(I.isub(I.ipt(1.0f64), I.idiv(bigr, rho)), c), Mm.vs(X.vdot(a, m), a))

def tor_n(+o: List<&2, I.I>, +a: List<&2, I.I>, +p: List<&2, I.I>, +bigr: I.I, +r: I.I) -> List<&2, I.I>:
  +m = X.vsub(p, o)
  +c = rp(a, m)
  +rho = I.idiv(I.isqrt(nsq(c)), nsq(a))
  tor_k(F64.is_lt(0.0f64, I.i_lo(rho)), a, m, c, rho, bigr, Im.im_grad(Im.M_to{o, a, bigr, r}, p))

def tgrad(s: Im.Im, +p: List<&2, I.I>) -> List<&2, I.I>:
  match s:
    case Im.M_pl{o, +n}: n
    case Im.M_sp{+o, r}: X.vsub(p, o)
    case Im.M_cy{+o, +a, r}: rp(a, X.vsub(p, o))
    case Im.M_co{+o, +a, +k}: X.vsub(rp(a, X.vsub(p, o)), Mm.vs(I.imul(I.isq(k), X.vdot(a, X.vsub(p, o))), a))
    case Im.M_to{+o, +a, +bigr, +r}: tor_n(o, a, p, bigr, r)
    case Im.M_no{}: [Im.i_all(), Im.i_all(), Im.i_all()]

def inw(+f: SO.Fd, +p: List<&2, I.I>) -> List<&2, I.I>:
  Mm.neg_if(Bool.not(Mm.fc_same(SO.fd_fc(f))), tgrad(SO.fd_im(f), p))

def rad(+o: List<&2, I.I>, +a: List<&2, I.I>, +p: List<&2, I.I>) -> List<&2, I.I>:
  +m = X.vsub(p, o)
  X.vsub(m, Mm.vs(I.idiv(X.vdot(a, m), X.vdot(a, a)), a))

def sd_iv(s: Im.Im, +p: List<&2, I.I>) -> I.I:
  match s:
    case Im.M_pl{+o, +n}: I.idiv(X.vdot(n, X.vsub(p, o)), I.isqrt(X.vdot(n, n)))
    case Im.M_sp{+o, +r}: I.isub(I.isqrt(nsq(X.vsub(p, o))), r)
    case Im.M_cy{+o, +a, +r}: I.isub(ax_rho(o, a, p), r)
    case Im.M_co{+o, +a, +k}: I.idiv(I.isub(ax_rho(o, a, p), I.imul(iabs(k), iabs(ax_h(o, a, p)))), I.isqrt(I.iadd(I.ipt(1.0f64), I.isq(k))))
    case Im.M_to{+o, +a, +bigr, +r}: I.isub(I.isqrt(I.iadd(I.isq(I.isub(ax_rho(o, a, p), bigr)), I.isq(ax_h(o, a, p)))), r)
    case Im.M_no{}: Im.i_all()

def sd_grad(s: Im.Im, +p: List<&2, I.I>) -> List<&2, I.I>:
  match s:
    case Im.M_pl{o, +n}: SO.unit(n)
    case Im.M_sp{o, r}: SO.unit(X.vsub(p, o))
    case Im.M_cy{+o, +a, r}: SO.unit(rad(o, a, p))
    case Im.M_co{+o, +a, +k}: SO.unit(X.vsub(SO.unit(rad(o, a, p)), Mm.vs(iabs(k), SO.unit(a))))
    case Im.M_to{+o, +a, +bigr, r}:
      SO.unit(X.vadd(Mm.vs(I.isub(ax_rho(o, a, p), bigr), SO.unit(rad(o, a, p))), Mm.vs(ax_h(o, a, p), SO.unit(a))))
    case Im.M_no{}: [Im.i_all(), Im.i_all(), Im.i_all()]

def mv_w(+g: I.I, +d: F64) -> I.I:
  Bool.pick(I.I, F64.is_lt(d, V.dbl_max()), I.iwiden(g, d), i_any())

def mv_f(ok: Bool, +sa: Im.Im, +sb: Im.Im, +bx: List<&2, I.I>, +c: List<&2, I.I>) -> I.I:
  match ok:
    case False{}: i_any()
    case True{}:
      +g0 = Im.im_grad(sa, c)
      +dd = diag(bx)
      +eta = F64.div(F64.add(X.imag(Im.im_val(sa, c)), F64.mul(vlen_hi(X.vsub(Im.im_grad(sa, bx), g0)), dd)), vlen_lo(g0))
      mv_w(sd_iv(sb, c), F64.add(F64.mul(vlen_hi(Im.cross(sd_grad(sb, bx), SO.unit(g0))), dd), F64.mul(1.0000001f64, eta)))

def near_f(+f: SO.Fd, +bx: List<&2, I.I>, +sb: Im.Im) -> I.I:
  +c = SO.snap(SO.proj(SO.fd_im(f), mid(bx)))
  isect(sd_iv(sb, bx), mv_f(Bool.and(X.vfin(c), X.vsub_of(c, bx)), SO.fd_im(f), sb, bx, c))

def near_e(+c: R.Cv, +bx: List<&2, I.I>, +t: I.I, +sb: Im.Im) -> I.I:
  +hw = F64.mul(0.5f64, F64.sub(I.i_hi(t), I.i_lo(t)))
  isect(sd_iv(sb, bx), I.iadd(sd_iv(sb, R.cv_box(c, I.ipt(I.imid(t)))), I.imul(X.vdot(sd_grad(sb, bx), R.cv_der(c, t)), I.I{F64.neg(hw), hw})))

def near_iv(e: En, +bx: List<&2, I.I>, +t: I.I, +sb: Im.Im) -> I.I:
  match e:
    case En_f{+f}: iabs(near_f(f, bx, sb))
    case En_e{+c, s}: iabs(near_e(c, bx, t, sb))
    case En_v{}: iabs(sd_iv(sb, bx))

def near_s(+sb: Im.Im, +e: En, +bx: List<&2, I.I>, +t: I.I) -> I.I:
  match sb:
    case Im.M_no{}: I.I{0.0f64, V.dbl_max()}
    case _: near_iv(e, bx, t, sb)

def bd_p(q: Bd) -> I.I:
  Bd{p, h} = q
  p

def del_iv(sa: Im.Im, +c: List<&2, I.I>, +bx: List<&2, I.I>) -> I.I:
  match sa:
    case Im.M_sp{+ca, +ra}:
      +dc = I.isqrt(pos(X.vdot(X.vsub(ca, c), X.vsub(ca, c))))
      isect(I.isqrt(nsq(X.vsub(bx, c))), I.I{I.i_lo(iabs(I.isub(dc, ra))), I.i_hi(I.iadd(dc, ra))})
    case _: I.isqrt(nsq(X.vsub(bx, c)))

def tor_d(+k: Mc, +q: Bd, +bigr: I.I) -> I.I:
  Mc{+ok, +rc, +hc, +r, +e} = k
  Bd{+p, +h} = q
  +z = I.ipt(0.0f64)
  +box = {I.I{dlo2(p, h, bigr, z), dhi2(p, h, bigr, z)} : I.I}
  +dc = {I.I{dlo2(rc, hc, bigr, z), dhi2(rc, hc, bigr, z)} : I.I}
  Bool.pick(I.I, ok, isect(box, I.I{F64.max(0.0f64, F64.sub(I.i_lo(iabs(I.isub(dc, r))), e)), F64.add(I.i_hi(I.iadd(dc, r)), e)}), box)

def tor_far(+sa: Im.Im, +o: List<&2, I.I>, +a: List<&2, I.I>, +bigr: I.I, +r: I.I, +bx: List<&2, I.I>, +ra: I.I) -> F64:
  +q = mrect(sa, o, a, bx, ra)
  +z = I.ipt(0.0f64)
  +dm = {I.I{dlo2(bd_p(q), ax_h(o, a, bx), I.ineg(bigr), z), dhi2(bd_p(q), ax_h(o, a, bx), I.ineg(bigr), z)} : I.I}
  F64.min(F64.add(I.i_lo(tor_d(mcirc(sa, o, a, bx), q, bigr)), I.i_lo(r)), I.i_lo(iabs(I.isub(dm, r))))

def far_lo(sb: Im.Im, +sa: Im.Im, +bx: List<&2, I.I>, +ra: I.I) -> F64:
  match sb:
    case Im.M_pl{o, n}: V.dbl_max()
    case Im.M_sp{+c, +r}: F64.add(I.i_lo(del_iv(sa, c, bx)), I.i_lo(r))
    case Im.M_cy{+o, +a, +r}: F64.add(I.i_lo(bd_p(mrect(sa, o, a, bx, ra))), I.i_lo(r))
    case Im.M_co{o, a, k}: 0.0f64
    case Im.M_to{+o, +a, +bigr, +r}: tor_far(sa, o, a, bigr, r, bx, ra)
    case Im.M_no{}: 0.0f64

def foot_m(nc: Bool, +tn: I.I, +sb: Im.Im, +sa: Im.Im, +bx: List<&2, I.I>, +ra: I.I) -> F64:
  match nc:
    case True{}: I.i_lo(tn)
    case False{}: far_lo(sb, sa, bx, ra)

def side_tn(+tn: I.I, +a: Cl, +sb: Im.Im, +gap: F64, +ra: I.I) -> F64:
  foot_m(F64.is_le(gap, I.i_hi(tn)), tn, sb, en_im(cl_e(a)), cl_bx(a), ra)

def side_lb(+a: Cl, +sb: Im.Im, +gap: F64, +ra: I.I) -> F64:
  side_tn(near_s(sb, cl_e(a), cl_bx(a), cl_t(a)), a, sb, gap, ra)



def off_r(+off: I.I, +g: F64) -> F64:
  Bool.pick(F64, F64.is_lt(I.i_hi(off), g), V.dbl_max(), F64.max(g, I.i_lo(off)))

def pl_off(+n: List<&2, I.I>, +o: List<&2, I.I>, +q: List<&2, I.I>) -> I.I:
  iabs(I.idiv(X.vdot(n, X.vsub(q, o)), I.isqrt(nsq(n))))

def ll_off(+oa: List<&2, I.I>, +aa: List<&2, I.I>, +ob: List<&2, I.I>, +ab: List<&2, I.I>) -> I.I:
  +c = Im.cross(aa, ab)
  Bool.pick(I.I, par_ax(ab, aa), I.idiv(I.isqrt(nsq(Im.cross(X.vsub(ob, oa), aa))), I.isqrt(nsq(aa))), pl_off(c, oa, ob))

def is_ln(+r: I.I) -> Bool:
  F64.is_le(I.i_hi(r), 0.0f64)

def pc_lb(+n: List<&2, I.I>, +o: List<&2, I.I>, +lo: List<&2, I.I>, +la: List<&2, I.I>, +r: I.I, +g: F64) -> F64:
  Bool.pick(F64, is_ln(r), off_r(Bool.pick(I.I, perp_ax(la, n), pl_off(n, o, lo), I.ipt(0.0f64)), g), 0.0f64)

def pl_pl(sa: Im.Im, +sb: Im.Im, +g: F64) -> F64:
  match sa:
    case Im.M_pl{+oa, +na}:
      match sb:
        case Im.M_pl{+ob, +nb}: off_r(Bool.pick(I.I, par_ax(nb, na), pl_off(na, oa, ob), I.ipt(0.0f64)), g)
        case Im.M_cy{+ob, +ab, +rb}: pc_lb(na, oa, ob, ab, rb, g)
        case _: 0.0f64
    case Im.M_cy{+oa, +aa, +ra}:
      match sb:
        case Im.M_pl{+ob, +nb}: pc_lb(nb, ob, oa, aa, ra, g)
        case Im.M_cy{+ob, +ab, +rb}: Bool.pick(F64, Bool.and(is_ln(ra), is_ln(rb)), off_r(ll_off(oa, aa, ob, ab), g), 0.0f64)
        case _: 0.0f64
    case _: 0.0f64

def pair_g(+a: Cl, +b: Cl, +ra: I.I, +rb: I.I, +sa: Im.Im, +sb: Im.Im, +g: F64) -> F64:
  F64.max(F64.max(F64.max(g, pl_pl(sa, sb, g)), F64.max(mer(sa, sb, cl_bx(a), cl_bx(b)), mer2(sa, sb, cl_bx(a), cl_bx(b), ra, rb))), F64.max(side_lb(a, sb, g, ra), side_lb(b, sa, g, rb)))

def pair_lb(+c: Cb) -> F64:
  Cb{+a, +b, +ra, +rb} = c
  pair_g(a, b, ra, rb, en_im(cl_e(a)), en_im(cl_e(b)), box_gap(cl_bx(a), cl_bx(b)))

def crit(e: En, +bx: List<&2, I.I>, +t: I.I, +d: List<&2, I.I>) -> Bool:
  match e:
    case En_f{f}: Bool.not(X.vany0_not(Im.cross(d, tgrad(SO.fd_im(f), bx))))
    case En_e{c, s}: X.has0(X.vdot(d, R.cv_der(c, t)))
    case En_v{}: True{}

def crit_pair(+x: Cb) -> Bool:
  Cb{+a, +b, ra, rb} = x
  +d = X.vsub(cl_bx(b), cl_bx(a))
  Bool.and(crit(cl_e(a), cl_bx(a), cl_t(a), d), crit(cl_e(b), cl_bx(b), cl_t(b), d))

def fac(e: En, +bx: List<&2, I.I>, +d: List<&2, I.I>) -> Bool:
  match e:
    case En_f{+f}: Bool.not(F64.is_le(I.i_hi(X.vdot(inw(f, bx), d)), 0.0f64))
    case En_e{c, s}: True{}
    case En_v{}: True{}

def dir_ff(+fa: SO.Fd, +xa: List<&2, I.I>, +fb: SO.Fd, +xb: List<&2, I.I>) -> Bool:
  +na = inw(fa, xa)
  +nb = inw(fb, xb)
  Bool.and(Bool.not(X.vany0_not(Im.cross(na, nb))), Bool.not(F64.is_le(0.0f64, I.i_lo(X.vdot(na, nb)))))

def dir_ef(+c: R.Cv, +t: I.I, +f: SO.Fd, +xf: List<&2, I.I>) -> Bool:
  X.has0(X.vdot(R.cv_der(c, t), tgrad(SO.fd_im(f), xf)))

def dir_b(eb: En, +xb: List<&2, I.I>, +tb: I.I, +fa: SO.Fd, +xa: List<&2, I.I>) -> Bool:
  match eb:
    case En_f{+fb}: dir_ff(fa, xa, fb, xb)
    case En_e{+c, s}: dir_ef(c, tb, fa, xa)
    case En_v{}: True{}

def dir_e(eb: En, +xb: List<&2, I.I>, +c: R.Cv, +ta: I.I) -> Bool:
  match eb:
    case En_f{+fb}: dir_ef(c, ta, fb, xb)
    case En_e{c2, s}: True{}
    case En_v{}: True{}

def dir_ok(ea: En, +eb: En, +xa: List<&2, I.I>, +ta: I.I, +xb: List<&2, I.I>, +tb: I.I) -> Bool:
  match ea:
    case En_f{+fa}: dir_b(eb, xb, tb, fa, xa)
    case En_e{+c, s}: dir_e(eb, xb, c, ta)
    case En_v{}: True{}

def wall_ok(+x: Cb) -> Bool:
  Cb{+a, +b, ra, rb} = x
  Bool.and(Bool.and(fac(cl_e(a), cl_bx(a), X.vsub(cl_bx(b), cl_bx(a))), fac(cl_e(b), cl_bx(b), X.vsub(cl_bx(a), cl_bx(b)))),
    dir_ok(cl_e(a), cl_e(b), cl_bx(a), cl_t(a), cl_bx(b), cl_t(b)))

def lb_c(ok: Bool, +x: Cb) -> F64:
  match ok:
    case True{}: pair_lb(x)
    case False{}: V.dbl_max()

def same_iv(+a: I.I, +b: I.I) -> Bool:
  Bool.and(F64.is_eq(I.i_lo(a), I.i_lo(b)), F64.is_eq(I.i_hi(a), I.i_hi(b)))

def same_v(xs: List<&2, I.I>, ys: List<&2, I.I>) -> Bool:
  match xs:
    case []:
      match ys:
        case []: True{}
        case y <> u: False{}
    case +x <> +t:
      match ys:
        case []: False{}
        case +y <> +u: Bool.and(same_iv(x, y), same_v(t, u))

def self_r(sa: Im.Im, +sb: Im.Im) -> F64:
  match sa:
    case Im.M_sp{+c, +r}:
      match sb:
        case Im.M_sp{+c2, +r2}: Bool.pick(F64, Bool.and(same_v(c, c2), same_iv(r, r2)), I.i_lo(r), 0.0f64)
        case _: 0.0f64
    case Im.M_cy{+o, +a, +r}:
      match sb:
        case Im.M_cy{+o2, +a2, +r2}: Bool.pick(F64, Bool.and(Bool.and(same_v(o, o2), same_v(a, a2)), same_iv(r, r2)), I.i_lo(r), 0.0f64)
        case _: 0.0f64
    case Im.M_to{+o, +a, +bigr, +r}:
      match sb:
        case Im.M_to{+o2, +a2, +bigr2, +r2}:
          Bool.pick(F64, Bool.and(Bool.and(same_v(o, o2), same_v(a, a2)), Bool.and(same_iv(bigr, bigr2), same_iv(r, r2))),
            F64.min(I.i_lo(r), I.i_lo(I.isub(bigr, r))), 0.0f64)
        case _: 0.0f64
    case _: 0.0f64

def self_lb(+x: Cb) -> F64:
  Cb{+a, +b, ra, rb} = x
  F64.mul(2.0f64, self_r(en_im(cl_e(a)), en_im(cl_e(b))))

def co_s(+k: I.I) -> I.I:
  I.idiv(iabs(k), I.isqrt(I.iadd(I.ipt(1.0f64), I.isq(k))))

def co_pl(+a: List<&2, I.I>, +k: I.I, +n: List<&2, I.I>) -> F64:
  +c = iabs(I.idiv(X.vdot(a, n), I.isqrt(I.imul(nsq(a), nsq(n)))))
  Bool.pick(F64, X.idisj(X.iinfl(c, 1.0e-9f64), co_s(k)), V.dbl_max(), 0.0f64)

def co_same(+o: List<&2, I.I>, +a: List<&2, I.I>, +k: I.I, sb: Im.Im) -> F64:
  match sb:
    case Im.M_co{+o2, +a2, +k2}: Bool.pick(F64, Bool.and(Bool.and(same_v(o, o2), same_v(a, a2)), same_iv(k, k2)), V.dbl_max(), 0.0f64)
    case Im.M_pl{o2, +n}: co_pl(a, k, n)
    case _: 0.0f64

def nset(sa: Im.Im, +sb: Im.Im) -> F64:
  match sa:
    case Im.M_co{+o, +a, +k}: co_same(o, a, k, sb)
    case Im.M_pl{o, +n}:
      match sb:
        case Im.M_co{o2, +a2, +k2}: co_pl(a2, k2, n)
        case _: 0.0f64
    case _: 0.0f64

def nset_lb(+x: Cb) -> F64:
  Cb{+a, +b, ra, rb} = x
  nset(en_im(cl_e(a)), en_im(cl_e(b)))

def lb_w(ok: Bool, +x: Cb) -> F64:
  match ok:
    case True{}: F64.max(F64.max(lb_c(crit_pair(x), x), self_lb(x)), nset_lb(x))
    case False{}: V.dbl_max()

def lbk(w: Bool, +x: Cb) -> F64:
  match w:
    case True{}: lb_w(wall_ok(x), x)
    case False{}: lb_c(crit_pair(x), x)

def ed_scan(fuel: Nat, dis: Bool, n: Nat, +t: I.I, rest: List<&2, Ei>, +c: R.Cv, +bx: List<&2, I.I>) -> Bool:
  match fuel:
    case 0n: True{}
    case 1n+(+f):
      match dis:
        case True{}:
          match rest:
            case []: False{}
            case Ei{+n2, +t2} <> +r2: ed_scan(f, X.vdisj(R.cv_box(c, t2), bx), n2, t2, r2, c, bx)
        case False{}:
          match n:
            case 0n: True{}
            case 1n+(+m):
              +lo = half(t, False{})
              ed_scan(f, X.vdisj(R.cv_box(c, lo), bx), m, lo, Ei{m, half(t, True{})} <> rest, c, bx)

def es_sub(es: List<&2, Mm.Er>, +bx: List<&2, I.I>) -> List<&2, Mm.Er>:
  match es:
    case []: []
    case +e <> +t:
      +r = es_sub(t, bx)
      Bool.pick(List<&2, Mm.Er>, ed_scan(64n, X.vdisj(R.cv_box(Mm.er_c(e), unit_t()), bx), 10n, unit_t(), [], Mm.er_c(e), bx), e <> r, r)

def rcurv(s: Im.Im, +bx: List<&2, I.I>) -> F64:
  match s:
    case Im.M_pl{o, n}: V.dbl_max()
    case Im.M_sp{o, r}: I.i_lo(r)
    case Im.M_cy{o, a, r}: I.i_lo(r)
    case Im.M_co{+o, +a, k}: I.i_lo(ax_rho(o, a, bx))
    case Im.M_to{o, a, +bigr, +r}: F64.min(I.i_lo(r), I.i_lo(I.isub(bigr, r)))
    case Im.M_no{}: 0.0f64

def st_mem(hit: Bool, +f: SO.Fd, +p: List<&2, I.I>) -> U64:
  match hit:
    case True{}: 2u64
    case False{}: Mm.member(SO.fd_fc(f), p, SO.fd_im(f))

def st_pt(fin: Bool, +f: SO.Fd, +p: List<&2, I.I>, +n: Nat) -> U64:
  match fin:
    case False{}: 2u64
    case True{}: st_mem(Nat.is_lt(0n, n), f, p)

def st_small(big: Bool, +f: SO.Fd, +bx: List<&2, I.I>, +n: Nat) -> U64:
  match big:
    case True{}: 2u64
    case False{}:
      +p = SO.snap(SO.proj(SO.fd_im(f), mid(bx)))
      st_pt(X.vfin(p), f, p, n)

def cl_rf(far: Bool, +f: SO.Fd, +bx: List<&2, I.I>, +t: I.I, +st: U64, +es: List<&2, Mm.Er>) -> Cl:
  match far:
    case True{}: Cl{En_f{f}, bx, t, 0u64, []}
    case False{}:
      match st:
        case 3u64:
          +es2 = es_sub(es, SO.wide(mid(bx), F64.mul(0.5f64, diag(bx))))
          Cl{En_f{f}, bx, t, st_small(F64.is_lt(F64.mul(0.5f64, rcurv(SO.fd_im(f), bx)), diag(bx)), f, bx, List.length(&2, Mm.Er, es2)), es2}
        case _: Cl{En_f{f}, bx, t, st, es}

def cl_rs(e: En, +bx: List<&2, I.I>, +t: I.I, +st: U64, +es: List<&2, Mm.Er>) -> Cl:
  match e:
    case En_f{+f}: cl_rf(F64.is_lt(0.0f64, sdist(SO.fd_im(f), bx)), f, bx, t, st, es)
    case En_e{+c, +s}: Cl{En_e{c, s}, bx, t, st, es}
    case En_v{}: Cl{En_v{}, bx, t, st, es}

def cl_res(+c: Cl) -> Cl:
  Cl{+e, +bx, +t, +st, +es} = c
  cl_rs(e, bx, t, st, es)

def cl_cut(e: En, +bx: List<&2, I.I>, +t: I.I, +st: U64, +es: List<&2, Mm.Er>, +up: Bool) -> Cl:
  match e:
    case En_f{+f}: Cl{En_f{f}, cut(bx, axis_of(bx), up), t, Bool.pick(U64, U64.is_eq(st, 1u64), 1u64, 3u64), es}
    case En_e{+c, +s}: Cl{En_e{c, s}, R.cv_box(c, half(t, up)), half(t, up), 1u64, []}
    case En_v{}: Cl{En_v{}, bx, t, 1u64, []}

def cl_half(+c: Cl, +up: Bool) -> Cl:
  Cl{+e, +bx, +t, +st, +es} = c
  cl_cut(e, bx, t, st, es, up)

def cb_w(+c: Cb) -> F64:
  Cb{+a, +b, ra, rb} = c
  F64.max(wid(cl_bx(a)), wid(cl_bx(b)))

def kids_of(leaf: Bool, sa: Bool, +a: Cl, +b: Cl, +ra: I.I, +rb: I.I) -> List<&2, Cb>:
  match leaf:
    case True{}: []
    case False{}:
      match sa:
        case True{}: [Cb{cl_half(a, False{}), b, ra, rb}, Cb{cl_half(a, True{}), b, ra, rb}]
        case False{}: [Cb{a, cl_half(b, False{}), ra, rb}, Cb{a, cl_half(b, True{}), ra, rb}]

def kids(+x: Cb) -> List<&2, Cb>:
  Cb{+a, +b, +ra, +rb} = x
  +wa = wid(cl_bx(a))
  +wb = wid(cl_bx(b))
  kids_of(F64.is_le(F64.max(wa, wb), 0.0f64), F64.is_le(wb, wa), a, b, ra, rb)

def push_k(keep: Bool, +k: F64, +x: Cb, +h: Ph, +eps: F64) -> Ph:
  match keep:
    case True{}: meld(Ph_n{k, quant(k, eps), cb_w(x), x, []}, h)
    case False{}: h

def push_m(lt: Bool, +k: F64, +x: Cb, +h: Ph, +eps: F64) -> Ph:
  match lt:
    case False{}: h
    case True{}:
      Cb{+a, +b, +ra, +rb} = x
      +a2 = cl_res(a)
      +b2 = cl_res(b)
      push_k(Bool.not(Bool.or(U64.is_eq(cl_st(a2), 0u64), U64.is_eq(cl_st(b2), 0u64))), k, Cb{a2, b2, ra, rb}, h, eps)

def push_all(xs: List<&2, Cb>, +h: Ph, +w: Bool, +k0: F64, +hi: F64, +eps: F64) -> Ph:
  match xs:
    case []: h
    case +x <> +t:
      +k = F64.max(k0, lbk(w, x))
      push_all(t, push_m(F64.is_lt(k, hi), k, x, h, eps), w, k0, hi, eps)

def stop_of(h: Ph, +hi: F64, +eps: F64) -> Bool:
  match h:
    case Ph_e{}: True{}
    case Ph_n{k, +q, w, x, cs}: F64.is_le(F64.sub(hi, F64.mul(2.0f64, eps)), q)

def wp_f(+f: SO.Fd, +c: List<&2, I.I>) -> Wp:
  +p = SO.snap(SO.proj(SO.fd_im(f), c))
  Wp{X.vfin(p), p, SO.dist(SO.fd_im(f), p)}

def wp_e(+q: List<&2, I.I>) -> Wp:
  Wp{True{}, SO.snap(q), X.vwid(q)}

def wp_of(e: En, +bx: List<&2, I.I>, +t: I.I, +c: List<&2, I.I>) -> Wp:
  match e:
    case En_f{+f}: wp_f(f, c)
    case En_e{cv, s}: wp_e(R.cv_box(cv, I.ipt(I.imid(t))))
    case En_v{}: Wp{True{}, bx, 0.0f64}

def wp_c(+a: Cl, +c: List<&2, I.I>) -> Wp:
  wp_of(cl_e(a), cl_bx(a), cl_t(a), c)

def wp_p(w: Wp) -> List<&2, I.I>:
  Wp{ok, p, s} = w
  p

def on_e(e: En, +p: List<&2, I.I>) -> Bool:
  match e:
    case En_f{+f}: on_pt(True{}, f, p)
    case En_e{c, s}: True{}
    case En_v{}: True{}

def mem_gate(go: Bool, +a: Cl, +b: Cl, +p: List<&2, I.I>, +q: List<&2, I.I>, +d: F64) -> F64:
  match go:
    case False{}: V.dbl_max()
    case True{}: Bool.pick(F64, Bool.and(on_e(cl_e(a), p), on_e(cl_e(b), q)), d, V.dbl_max())

def on_tol(+sa: F64, +sb: F64, +d: F64) -> Bool:
  +e = F64.mul(1.0e-9f64, F64.add(1.0f64, d))
  Bool.and(F64.is_le(sa, e), F64.is_le(sb, e))

def wit_d(+a: Cl, +b: Cl, +pa: Wp, +pb: Wp, +hw: F64) -> F64:
  Wp{+oka, +p, +sa} = pa
  Wp{+okb, +q, +sb} = pb
  +d = F64.add(nrm_hi(X.vsub(q, p)), F64.add(sa, sb))
  mem_gate(Bool.and(Bool.and(Bool.and(oka, okb), on_tol(sa, sb, d)), F64.is_lt(d, hw)), a, b, p, q, d)

def wit1(+a: Cl, +b: Cl, +hw: F64) -> F64:
  +pa = wp_c(a, mid(cl_bx(a)))
  wit_d(a, b, pa, wp_c(b, wp_p(pa)), hw)

def sig(e: En, +p: List<&2, I.I>, +t: I.I, +d: List<&2, I.I>) -> F64:
  match e:
    case En_f{+f}:
      Bool.pick(F64, F64.is_lt(0.0f64, I.i_lo(X.vdot(inw(f, p), d))), F64.div(vlen_hi(Im.cross(d, inw(f, p))), F64.mul(vlen_lo(d), vlen_lo(inw(f, p)))), 2.0f64)
    case En_e{+c, s}: F64.div(X.imag(X.vdot(d, R.cv_der(c, I.ipt(I.imid(t))))), F64.mul(vlen_lo(d), vlen_lo(R.cv_der(c, I.ipt(I.imid(t))))))
    case En_v{}: 0.0f64

def wv_s(+sa: F64, +sb: F64, +a: Cl, +b: Cl, +p: List<&2, I.I>, +q: List<&2, I.I>, +ea: F64, +eb: F64, +n: F64, +okd: Bool, +hw: F64) -> F64:
  +l = F64.add(F64.mul(n, F64.add(1.0f64, F64.add(F64.add(F64.mul(sa, sa), F64.mul(sb, sb)), 4.5e-16f64))), F64.add(ea, eb))
  mem_gate(Bool.and(Bool.and(okd, on_tol(ea, eb, l)), Bool.and(F64.is_lt(l, hw), Bool.and(F64.is_le(sa, 1.0e-4f64), F64.is_le(sb, 1.0e-4f64)))), a, b, p, q, l)

def wv(+a: Cl, +b: Cl, +pa: Wp, +pb: Wp, +hw: F64) -> F64:
  Wp{+oka, +p, +ea} = pa
  Wp{+okb, +q, +eb} = pb
  +d = X.vsub(q, p)
  wv_s(sig(cl_e(a), p, cl_t(a), d), sig(cl_e(b), q, cl_t(b), X.vsub(p, q)), a, b, p, q, ea, eb, nrm_hi(d),
    Bool.and(Bool.and(oka, okb), F64.is_lt(0.0f64, vlen_lo(d))), hw)

def qroot(+a: F64, +b: F64, +c: F64, +far: Bool) -> F64:
  +dd = F64.sub(F64.mul(b, b), F64.mul(a, c))
  +s = F64.sqrt(F64.max(dd, 0.0f64))
  Bool.pick(F64, Bool.or(F64.is_lt(dd, 0.0f64), F64.is_le(F64.abs(a), 1.0e-300f64)), F64.neg(1.0f64),
    F64.div(F64.sub(Bool.pick(F64, far, s, F64.neg(s)), b), a))

def ray_s(+m: List<&2, I.I>, +n: List<&2, I.I>, +r: I.I, +far: Bool) -> F64:
  qroot(1.0f64, I.imid(X.vdot(n, m)), F64.sub(I.imid(X.vdot(m, m)), I.imid(I.isq(r))), far)

def ray_t(s: Im.Im, +p: List<&2, I.I>, +n: List<&2, I.I>, +far: Bool) -> F64:
  match s:
    case Im.M_pl{+o, +nb}: F64.div(I.imid(X.vdot(nb, X.vsub(o, p))), I.imid(X.vdot(nb, n)))
    case Im.M_sp{+c, +r}: ray_s(X.vsub(p, c), n, r, far)
    case Im.M_cy{+o, +a, +r}:
      +m = rad(o, a, p)
      +u = X.vsub(n, Mm.vs(I.idiv(X.vdot(a, n), X.vdot(a, a)), a))
      qroot(I.imid(X.vdot(u, u)), I.imid(X.vdot(u, m)), F64.sub(I.imid(X.vdot(m, m)), I.imid(I.isq(r))), far)
    case Im.M_to{+o, +a, +bigr, +r}: ray_s(X.vsub(p, X.vadd(o, Mm.vs(bigr, SO.unit(rad(o, a, p))))), n, r, far)
    case _: F64.neg(1.0f64)

def en_n(e: En, +p: List<&2, I.I>) -> List<&2, I.I>:
  match e:
    case En_f{+f}: SO.unit(inw(f, p))
    case En_e{c, s}: [Im.i_all(), Im.i_all(), Im.i_all()]
    case En_v{}: [Im.i_all(), Im.i_all(), Im.i_all()]

def wq_t(+b: Cl, +p: List<&2, I.I>, +n: List<&2, I.I>, +t: F64) -> Wp:
  Bool.pick(Wp, F64.is_lt(0.0f64, t), wp_c(b, X.vadd(p, Mm.vs(I.ipt(t), n))), Wp{False{}, p, 0.0f64})

def wray(+a: Cl, +b: Cl, +pa: Wp, +far: Bool, +hw: F64) -> F64:
  +p = wp_p(pa)
  +n = en_n(cl_e(a), p)
  wv(a, b, pa, wq_t(b, p, n, ray_t(en_im(cl_e(b)), p, n, far)), hw)

type Pp is Data:
  Pp{ p: List<&2, I.I>, t: F64 }

def pp_p(+x: Pp) -> List<&2, I.I>:
  Pp{+p, t} = x
  p

def pull_e(+c: R.Cv, +x: Pp, +q: List<&2, I.I>) -> Pp:
  Pp{+p, +t} = x
  +d = R.cv_der(c, I.ipt(t))
  +t2 = F64.max(0.0f64, F64.min(1.0f64, F64.add(t, F64.div(I.imid(X.vdot(X.vsub(q, p), d)), I.imid(X.vdot(d, d))))))
  Pp{R.cv_box(c, I.ipt(t2)), t2}

def pull(e: En, +bx: List<&2, I.I>, +x: Pp, +q: List<&2, I.I>) -> Pp:
  match e:
    case En_f{+f}: Pp{SO.snap(SO.proj(SO.fd_im(f), q)), 0.0f64}
    case En_e{+c, s}: pull_e(c, x, q)
    case En_v{}: Pp{bx, 0.0f64}

def pp_wp(e: En, +x: Pp) -> Wp:
  match e:
    case En_f{+f}: Wp{X.vfin(pp_p(x)), pp_p(x), SO.dist(SO.fd_im(f), pp_p(x))}
    case En_e{c, s}: Wp{X.vfin(pp_p(x)), pp_p(x), X.vwid(pp_p(x))}
    case En_v{}: Wp{X.vfin(pp_p(x)), pp_p(x), X.vwid(pp_p(x))}

type Pq is Data:
  Pq{ a: Pp, b: Pp }

def pp_go(n: Nat, +a: Cl, +b: Cl, +xa: Pp, +xb: Pp) -> Pq:
  match n:
    case 0n: Pq{xa, xb}
    case 1n+(+m):
      +ya = pull(cl_e(a), cl_bx(a), xa, pp_p(xb))
      pp_go(m, a, b, ya, pull(cl_e(b), cl_bx(b), xb, pp_p(ya)))

def pp_init(e: En, +bx: List<&2, I.I>, +t: I.I) -> Pp:
  match e:
    case En_f{+f}: Pp{SO.snap(SO.proj(SO.fd_im(f), mid(bx))), 0.0f64}
    case En_e{+c, s}: Pp{R.cv_box(c, I.ipt(I.imid(t))), I.imid(t)}
    case En_v{}: Pp{bx, 0.0f64}

def pong_d(w: Bool, +a: Cl, +b: Cl, +xa: Pp, +xb: Pp, +hw: F64) -> F64:
  match w:
    case True{}: wv(a, b, pp_wp(cl_e(a), xa), pp_wp(cl_e(b), xb), hw)
    case False{}: wit_d(a, b, pp_wp(cl_e(a), xa), pp_wp(cl_e(b), xb), hw)

def pong_q(w: Bool, +a: Cl, +b: Cl, +q: Pq, +hw: F64) -> F64:
  Pq{+ya, +yb} = q
  pong_d(w, a, b, ya, yb, hw)

def pong(w: Bool, +a: Cl, +b: Cl, +hw: F64) -> F64:
  +xa = pp_init(cl_e(a), cl_bx(a), cl_t(a))
  pong_q(w, a, b, pp_go(12n, a, b, xa, pull(cl_e(b), cl_bx(b), pp_init(cl_e(b), cl_bx(b), cl_t(b)), pp_p(xa))), hw)

def wit_w(+a: Cl, +b: Cl, +hw: F64) -> F64:
  +pa = wp_c(a, mid(cl_bx(a)))
  +pb = wp_c(b, mid(cl_bx(b)))
  +h1 = F64.min(hw, wv(a, b, pa, pb, hw))
  +h2 = F64.min(h1, wray(a, b, pa, False{}, h1))
  +h3 = F64.min(h2, wray(a, b, pa, True{}, h2))
  +h4 = F64.min(h3, wray(b, a, pb, False{}, h3))
  +h5 = F64.min(h4, wray(b, a, pb, True{}, h4))
  F64.min(h5, pong(True{}, a, b, h5))

def wit_ab(w: Bool, +a: Cl, +b: Cl, +hw: F64) -> F64:
  match w:
    case True{}: wit_w(a, b, hw)
    case False{}:
      +h1 = F64.min(hw, wit1(a, b, hw))
      +h2 = F64.min(h1, wit1(b, a, h1))
      F64.min(h2, pong(False{}, a, b, h2))

def wit(+w: Bool, +x: Cb, +hw: F64) -> F64:
  Cb{+a, +b, ra, rb} = x
  wit_ab(w, a, b, hw)

def wit_if(go: Bool, +w: Bool, +x: Cb, +hw: F64) -> F64:
  match go:
    case True{}: wit(w, x, hw)
    case False{}: V.dbl_max()

def step(leaf: Bool, +k: F64, +x: Cb, +cs: List<&2, Ph>, +w: Bool, +hw: F64, +eps: F64) -> Ph:
  match leaf:
    case True{}: pairs(cs)
    case False{}: push_all(kids(x), pairs(cs), w, k, hw, eps)

def lf_of(leaf: Bool, +lf: F64, +k: F64, +hw: F64, +eps: F64) -> F64:
  match leaf:
    case False{}: lf
    case True{}: Bool.pick(F64, F64.is_lt(k, F64.sub(hw, F64.mul(2.0f64, eps))), F64.min(lf, k), lf)

def eps_of(+hi: F64, +tol: F64) -> F64:
  F64.max(F64.mul(1.0e-6f64, F64.add(1.0f64, hi)), tol)

def search(fuel: Nat, stop: Bool, h: Ph, +w: Bool, +hi: F64, +tol: F64, +lf: F64) -> I.I:
  match fuel:
    case 0n: I.I{F64.min(lf, ph_min(h, hi)), hi}
    case 1n+(+f):
      match stop:
        case True{}: I.I{F64.min(lf, ph_min(h, hi)), hi}
        case False{}:
          match h:
            case Ph_e{}: I.I{F64.min(lf, hi), hi}
            case Ph_n{+k, q, +bw, +x, +cs}:
              +leaf = F64.is_le(bw, eps_of(hi, tol))
              +hw = F64.min(hi, wit_if(Bool.or(leaf, Nat.is_eq(Nat.mod(f, 8n), 0n)), w, x, hi))
              +eps = eps_of(hw, tol)
              +h2 = step(leaf, k, x, cs, w, hw, eps)
              search(f, stop_of(h2, hw, eps), h2, w, hw, tol, lf_of(leaf, lf, k, hw, eps))

def wit_ph(hs: List<&2, Ph>, +w: Bool, +acc: F64) -> F64:
  match hs:
    case []: acc
    case +h <> +t:
      match h:
        case Ph_e{}: wit_ph(t, w, acc)
        case Ph_n{k, q, bw, +x, +cs}: wit_ph(t, w, wit_ph(cs, w, F64.min(acc, wit(w, x, acc))))

def best_go(+h: Ph, +w: Bool, +hi: F64, +tol: F64) -> I.I:
  search(99841n, stop_of(h, hi, eps_of(hi, tol)), h, w, hi, tol, V.dbl_max())

def best_lo(+h: Ph, +w: Bool, +hi: F64, +tol: F64) -> I.I:
  best_go(h, w, F64.min(hi, wit_ph([h], w, hi)), tol)

def rr_f(e: En, +so: Im.Im) -> I.I:
  match e:
    case En_f{+f}: rr_ax(so, f)
    case En_e{c, s}: rr_all()
    case En_v{}: rr_all()

def root_k(lt: Bool, +w: Bool, +k0: F64, +a: Cl, +b: Cl, +h: Ph, +hi: F64, +eps: F64) -> Ph:
  match lt:
    case False{}: h
    case True{}:
      +x = {Cb{a, b, rr_f(cl_e(a), en_im(cl_e(b))), rr_f(cl_e(b), en_im(cl_e(a)))} : Cb}
      +k = F64.max(k0, lbk(w, x))
      push_m(F64.is_lt(k, hi), k, x, h, eps)

def root_1(near: Bool, +w: Bool, +a: Cl, +b: Cl, +h: Ph, +hi: F64, +eps: F64) -> Ph:
  match near:
    case False{}: h
    case True{}:
      +k = lbk(w, Cb{a, b, rr_all(), rr_all()})
      root_k(F64.is_lt(k, hi), w, k, a, b, h, hi, eps)

def root_b(bs: List<&2, Cl>, +a: Cl, +h: Ph, +hi: F64, +eps: F64) -> Ph:
  match bs:
    case []: h
    case +b <> +t: root_b(t, a, root_1(F64.is_lt(box_gap(cl_bx(a), cl_bx(b)), hi), False{}, a, b, h, hi, eps), hi, eps)

def root_a(xs: List<&2, Cl>, +bs: List<&2, Cl>, +h: Ph, +hi: F64, +eps: F64) -> Ph:
  match xs:
    case []: h
    case +a <> +t: root_a(t, bs, root_b(bs, a, h, hi, eps), hi, eps)

def pd(+a: V.Point, +b: V.Point) -> F64:
  +x = F64.sub(V.pt_x(a), V.pt_x(b))
  +y = F64.sub(V.pt_y(a), V.pt_y(b))
  +z = F64.sub(V.pt_z(a), V.pt_z(b))
  F64.sqrt(F64.add(F64.mul(x, x), F64.add(F64.mul(y, y), F64.mul(z, z))))

def pl(+a: V.Point, +b: V.Point, +k: F64) -> V.Point:
  V.Pt{F64.add(V.pt_x(a), F64.mul(k, F64.sub(V.pt_x(b), V.pt_x(a)))), F64.add(V.pt_y(a), F64.mul(k, F64.sub(V.pt_y(b), V.pt_y(a)))),
    F64.add(V.pt_z(a), F64.mul(k, F64.sub(V.pt_z(b), V.pt_z(a))))}

def rq_c(ok: Bool, +p0: V.Point, +p1: V.Point, +p2: V.Point, +c: V.Point, +w: F64) -> Im.Im:
  match ok:
    case False{}: Im.M_no{}
    case True{}:
      +r = pd(p0, c)
      +e = F64.mul(1.0e-9f64, F64.add(1.0f64, r))
      +n = Im.cross(X.vsub(Im.p3(p0), Im.p3(p1)), X.vsub(Im.p3(p2), Im.p3(p1)))
      Bool.pick(Im.Im, Bool.and(F64.is_le(F64.abs(F64.sub(pd(p2, c), r)), e), F64.is_le(F64.abs(F64.sub(F64.mul(w, pd(p1, c)), r)), e)),
        Im.M_to{Im.p3(c), n, I.I{F64.sub(r, e), F64.add(r, e)}, I.ipt(0.0f64)}, Im.M_no{})

def rq_im(+p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64, +w1: F64, +w2: F64) -> Im.Im:
  +w = F64.div(w1, F64.sqrt(F64.mul(w0, w2)))
  +m = pl(p0, p2, 0.5f64)
  +k = F64.div(F64.mul(w, w), F64.sub(1.0f64, F64.mul(w, w)))
  rq_c(Bool.and(F64.is_eq(w0, w2), Bool.and(F64.is_lt(0.0f64, w), F64.is_lt(w, 1.0f64))), p0, p1, p2, pl(m, p1, F64.neg(k)), w)

def ed_im(g: G.GVal) -> Im.Im:
  match g:
    case G.GV_rq{q}:
      G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = q
      rq_im(p0, p1, p2, w0, w1, w2)
    case G.GV_ln{l}:
      G.Ln{p, d} = l
      Im.M_cy{Im.p3(p), Im.d3(d), I.ipt(0.0f64)}
    case G.GV_cc{c}:
      G.Cc{o, u, v, +r} = c
      Im.M_to{Im.p3(o), Im.cross(Im.d3(u), Im.d3(v)), I.ipt(r), I.ipt(0.0f64)}
    case _: Im.M_no{}

def cull(cs: List<&2, Cl>, +bb: List<&2, I.I>, +hi: F64) -> List<&2, Cl>:
  match cs:
    case []: []
    case +c <> +t:
      +r = cull(t, bb, hi)
      Bool.pick(List<&2, Cl>, F64.is_lt(box_gap(cl_bx(c), bb), hi), c <> r, r)

def en_fs(fs: List<&2, SO.Fd>) -> List<&2, Cl>:
  match fs:
    case []: []
    case +f <> +t: Cl{En_f{f}, SO.fd_bx(f), unit_t(), 3u64, Mm.fc_es(SO.fd_fc(f))} <> en_fs(t)

def en_vs(vs: List<&2, Ty.Vertex>, +acc: List<&2, Cl>) -> List<&2, Cl>:
  match vs:
    case []: acc
    case v <> t: en_vs(t, Cl{En_v{}, Im.p3(Ty.vx_p(v)), unit_t(), 1u64, []} <> acc)

def el_cv(m: Maybe<&2, R.Cv>, +s: Im.Im, +cs: List<&2, Cl>, +ok: Bool, +bb: List<&2, I.I>) -> El:
  match m:
    case None{}: El{cs, False{}, bb}
    case Some{+c}: El{Cl{En_e{c, s}, R.cv_box(c, unit_t()), unit_t(), 1u64, []} <> cs, ok, bb}

def el_k(k: Ty.EdgeKind, +cs: List<&2, Cl>, +ok: Bool, +bb: List<&2, I.I>) -> El:
  match k:
    case Ty.EK_degenerate{}: El{cs, ok, bb}
    case Ty.EK_curve{+g, +d}: el_cv(Q.gv_cv(g, d), ed_im(g), cs, ok, bb)

def el_es(es: List<&2, Ty.Edge>, +acc: El) -> El:
  match es:
    case []: acc
    case e <> t:
      Ty.Ed{g, h0, h1, k} = e
      El{+cs, +ok, +bb} = acc
      el_es(t, el_k(k, cs, ok, bb))

def el_cs(x: El) -> List<&2, Cl>:
  El{cs, ok, bb} = x
  cs

def el_ok(x: El) -> Bool:
  El{cs, ok, bb} = x
  ok

def el_bb(x: El) -> List<&2, I.I>:
  El{cs, ok, bb} = x
  bb

def ents_w(+wb: Ty.Brep, +fs: List<&2, SO.Fd>) -> El:
  el_es(Ty.brep_es(wb), El{en_vs(Ty.brep_vs(wb), en_fs(fs)), QA.fd_allok(fs), SO.bbox(fs, [])})

def ents_b(+wb: Ty.Brep) -> El:
  ents_w(wb, SO.fds_of(wb))

def ents(+b: M.Body) -> El:
  +pl = M.bd_pl(b)
  ents_b(BO.xf_brep(M.pl_m(pl), M.pl_tx(pl), M.pl_ty(pl), M.pl_tz(pl), M.bd_brep(b)))

def cert_go(ok: Bool, +ea: El, +eb: El, +lo0: F64, +hi: F64, +tol: F64) -> I.I:
  match ok:
    case False{}: I.I{lo0, hi}
    case True{}:
      +r = best_lo(root_a(cull(el_cs(ea), el_bb(eb), hi), cull(el_cs(eb), el_bb(ea), hi), Ph_e{}, hi, eps_of(hi, tol)), False{}, hi, tol)
      I.I{F64.max(lo0, I.i_lo(r)), I.i_hi(r)}

def cert_ee(+ea: El, +eb: El, +lo0: F64, +hi: F64, +tol: F64) -> I.I:
  cert_go(Bool.and(el_ok(ea), el_ok(eb)), ea, eb, lo0, hi, tol)

def cert_lo_t(+a: M.Body, +b: M.Body, +lo0: F64, +hi: F64, +tol: F64) -> I.I:
  cert_ee(ents(a), ents(b), lo0, hi, tol)

def wroot_b(bs: List<&2, Cl>, +a: Cl, +h: Ph, +hi: F64, +eps: F64) -> Ph:
  match bs:
    case []: h
    case +b <> +t: wroot_b(t, a, root_1(True{}, True{}, a, b, h, hi, eps), hi, eps)

def wroot_a(xs: List<&2, Cl>, +h: Ph, +hi: F64, +eps: F64) -> Ph:
  match xs:
    case []: h
    case +a <> +t: wroot_a(t, wroot_b(a <> t, a, h, hi, eps), hi, eps)

def wall_iv(+fs: List<&2, SO.Fd>, +cap: F64) -> I.I:
  best_lo(wroot_a(en_fs(fs), Ph_e{}, cap, eps_of(cap, 0.0f64)), True{}, cap, 0.0f64)

