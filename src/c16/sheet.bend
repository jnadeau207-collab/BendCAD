import Base
import ../c00/types.bend as T
import ../c06/xp.bend as X
import ../c06/prof.bend as F
import ../c06/iv.bend as I
import ../base/num.bend as N

type P2 is Data:
  P2{ x: X.Xp, y: X.Xp }
type Sg is Data:
  Sg_ln{ a: Nat, b: Nat }
  Sg_ar{ a: Nat, cx: X.Xp, cy: X.Xp, r: X.Xp, b: Nat, ccw: Bool }
type PR is Data:
  PR{ pts: List<&2, P2>, segs: List<&2, Sg> }
type FT is Data:
  FT_bend{ n: U64, r: X.Xp, deg: U64 }
  FT_hem{ n: U64, l: X.Xp }
type SC is Data:
  SC_ok{ l: X.Xp, w: X.Xp, t: X.Xp, feats: List<&2, FT> }
  SC_bad{}
type GR is Data:
  GR_ok{}
  GR_no{ why: String, fix: String }
type KP is Data:
  KP{ k: U64, rot: Bool }
type PK is Data:
  K0{}
  K1{}
  K2{}
  K3{}
  K4{}
  K5{}
  K6{}
  K7{}
  K8{}
  K9{}
  K10{}
  K11{}
type BN is Data:
  BN{ n: U64, r: F64, deg: U64 }
type HN is Data:
  HN{ n: U64, l: F64 }
type FR is Data:
  FR{ i: Nat, n: U64, deg: U64, r: F64, lo: F64, hi: F64 }
def xk(+v: F64) -> X.Xp:
  X.X_k{v}
def xa(+a: X.Xp, +b: X.Xp) -> X.Xp:
  X.X_add{a, b}
def xs(+a: X.Xp, +b: X.Xp) -> X.Xp:
  X.X_sub{a, b}
def xm(+a: X.Xp, +b: X.Xp) -> X.Xp:
  X.X_mul{a, b}
def xd(+a: X.Xp, +b: X.Xp) -> X.Xp:
  X.X_div{a, b}
def x0() -> X.Xp:
  xk(0.0f64)
def x1() -> X.Xp:
  xk(1.0f64)
def x2() -> X.Xp:
  xk(2.0f64)
def x4() -> X.Xp:
  xk(4.0f64)
def p2(+x: X.Xp, +y: X.Xp) -> P2:
  P2{x, y}
def sln(+a: Nat, +b: Nat) -> Sg:
  Sg_ln{a, b}
def sar(+a: Nat, +cx: X.Xp, +cy: X.Xp, +r: X.Xp, +b: Nat, +ccw: Bool) -> Sg:
  Sg_ar{a, cx, cy, r, b, ccw}
def pi() -> F64:
  F64{4614256656552045848u64}
def rt_min() -> F64:
  1.0f64
def pr_pts(+p: PR) -> List<&2, P2>:
  PR{+pts, +segs} = p
  pts
def pr_segs(+p: PR) -> List<&2, Sg>:
  PR{+pts, +segs} = p
  segs
def sc_l(+s: SC) -> X.Xp:
  match s:
    case SC_ok{+l, +w, +t, +feats}: l
    case SC_bad{}: x0()
def sc_w(+s: SC) -> X.Xp:
  match s:
    case SC_ok{+l, +w, +t, +feats}: w
    case SC_bad{}: x0()
def sc_t(+s: SC) -> X.Xp:
  match s:
    case SC_ok{+l, +w, +t, +feats}: t
    case SC_bad{}: x0()
def sc_feats(+s: SC) -> List<&2, FT>:
  match s:
    case SC_ok{+l, +w, +t, +feats}: feats
    case SC_bad{}: []
def sc_sc_ok(+s: SC) -> Bool:
  match s:
    case SC_ok{+l, +w, +t, +feats}: True{}
    case SC_bad{}: False{}
def sc_push(+s: SC, +f: FT) -> SC:
  match s:
    case SC_ok{+l, +w, +t, +feats}: SC_ok{l, w, t, List.append(&2, FT, feats, [f])}
    case SC_bad{}: SC_bad{}
def ft_n(+f: FT) -> U64:
  match f:
    case FT_bend{+n, +r, +deg}: n
    case FT_hem{+n, +l}: n
def ft_deg(+f: FT) -> U64:
  match f:
    case FT_bend{+n, +r, +deg}: deg
    case FT_hem{+n, +l}: 0u64
def ft_is_bend(+f: FT) -> Bool:
  match f:
    case FT_bend{+n, +r, +deg}: True{}
    case FT_hem{+n, +l}: False{}
def end_of(+n: U64) -> U64:
  match n:
    case 0u64: 0u64
    case 1u64: 0u64
    case 2u64: 1u64
    case 3u64: 1u64
    case _: 0u64
def dir_up(+n: U64) -> Bool:
  match n:
    case 0u64: True{}
    case 1u64: False{}
    case 2u64: True{}
    case 3u64: False{}
    case _: True{}
def fin1(+v: F64) -> Bool:
  Bool.and(T.is_finite(v), F64.is_lt(0.0f64, v))
def base_go(+ok: Bool, +nf: Nat) -> GR:
  match ok:
    case False{}: GR_no{"bend-base-not-admitted", "bend flat or single-bent sheet, hem once at most"}
    case True{}: GR_ok{}
def fin_go(+ok: Bool, +l: F64, +w: F64, +t: F64, +r: F64, +lh: F64) -> GR:
  match ok:
    case False{}: GR_no{"degenerate-feature", "give finite positive lengths for the blank, radius and hem"}
    case True{}: GR_ok{}
def ang_go(+ok: Bool, +deg: U64) -> GR:
  match ok:
    case False{}: GR_no{"bend-angle-not-certified", "bend 90 or 180 degrees"}
    case True{}: GR_ok{}
def edge_go(+ok: Bool, +n: U64) -> GR:
  match ok:
    case False{}: GR_no{"bend-edge-not-admitted", "bend or hem edge 0, 1, 2 or 3 on an unworked end"}
    case True{}: GR_ok{}
def rt_go(+ok: Bool, +r: F64, +t: F64) -> GR:
  match ok:
    case False{}: GR_no{"bend-radius-too-tight", "keep inner radius over the certified R/T bound"}
    case True{}: GR_ok{}
def size_go(+ok: Bool, +l: F64, +ro: F64) -> GR:
  match ok:
    case False{}: GR_no{"bend-consumes-face", "keep the blank longer than twice outer radius"}
    case True{}: GR_ok{}
def len_go(+ok: Bool, +lh: F64, +leg: F64) -> GR:
  match ok:
    case False{}: GR_no{"hem-consumes-face", "keep the hem shorter than its leg"}
    case True{}: GR_ok{}
def k_go(+ok: Bool, +klo: F64, +khi: F64) -> GR:
  match ok:
    case False{}: GR_no{"bad-k-zone", "give a K-factor zone with 0 < KLO <= KHI < 1"}
    case True{}: GR_ok{}
def gram_go(+ok: Bool, +isbase: Bool, +nf: Nat) -> GR:
  match ok:
    case True{}: GR_ok{}
    case False{}:
      match isbase:
        case True{}: GR_no{"bend-base-not-admitted", "bend flat or single-bent sheet, hem once at most"}
        case False{}: GR_no{"bend-edge-not-admitted", "bend opposite ends alike, hem the bent end once"}
def feats_len(fs: List<&2, FT>) -> Nat:
  match fs:
    case []: 0n
    case +f <> t: Nat.add(1n, feats_len(t))
def gr_ok(+g: GR) -> Bool:
  match g:
    case GR_ok{}: True{}
    case GR_no{+why, +fix}: False{}
def gr_why(+g: GR) -> String:
  match g:
    case GR_ok{}: ""
    case GR_no{+why, +fix}: why
def gr_fix(+g: GR) -> String:
  match g:
    case GR_ok{}: ""
    case GR_no{+why, +fix}: fix
def ang_ok(+deg: U64) -> Bool:
  match deg:
    case 90u64: True{}
    case 180u64: True{}
    case _: False{}
def edge_ok(+n: U64) -> Bool:
  U64.is_lt(n, 4u64)
def k_ok(+klo: F64, +khi: F64) -> Bool:
  Bool.and(Bool.and(T.is_finite(klo), T.is_finite(khi)),
    Bool.and(F64.is_lt(0.0f64, klo), Bool.and(F64.is_le(klo, khi), F64.is_lt(khi, 1.0f64))))
def rt_ok(+r: F64, +t: F64) -> Bool:
  Bool.and(fin1(t), Bool.and(fin1(r), F64.is_le(rt_min(), F64.div(r, t))))
def l1x(+l: X.Xp) -> X.Xp:
  xd(l, x2())
def rox(+r: X.Xp, +t: X.Xp) -> X.Xp:
  xa(r, t)
def f1x(+l: X.Xp, +r: X.Xp, +t: X.Xp) -> X.Xp:
  xs(l1x(l), rox(r, t))
def trx(+t: X.Xp, +r: X.Xp) -> X.Xp:
  xa(t, r)
def htx(+l: X.Xp, +t: X.Xp, +r: X.Xp) -> X.Xp:
  xa(trx(t, r), f1x(l, r, t))
def h2x(+t: X.Xp, +r: X.Xp) -> X.Xp:
  xm(x2(), trx(t, r))
def fux(+l: X.Xp, +r: X.Xp, +t: X.Xp) -> X.Xp:
  xd(xs(l, xm(x2(), rox(r, t))), x4())
def hfx(+l: X.Xp, +t: X.Xp, +r: X.Xp) -> X.Xp:
  xa(trx(t, r), fux(l, r, t))
def webx(+l: X.Xp, +r: X.Xp, +t: X.Xp) -> X.Xp:
  xs(l, xm(x2(), rox(r, t)))
def t2x(+t: X.Xp) -> X.Xp:
  xm(x2(), t)
def sh90up(+l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> PR:
  +l1 = l1x(l)
  +ro = rox(r, t)
  +ht = htx(l, t, r)
  +tr = trx(t, r)
  +lr = xa(l1, ro)
  +li = xa(l1, r)
  PR{[p2(x0(), x0()), p2(l1, x0()), p2(lr, tr), p2(lr, ht), p2(li, ht), p2(li, tr), p2(l1, t), p2(x0(), t)],
    [sln(0n, 1n), sar(1n, l1, tr, ro, 2n, True{}), sln(2n, 3n), sln(3n, 4n), sln(4n, 5n),
      sar(5n, l1, tr, r, 6n, False{}), sln(6n, 7n)]}
def sh90dn(+l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> PR:
  +l1 = l1x(l)
  +ro = rox(r, t)
  +ht = htx(l, t, r)
  +hm = xs(ht, t)
  +hc = xs(hm, r)
  +lr = xa(l1, ro)
  +li = xa(l1, r)
  PR{[p2(x0(), hm), p2(l1, hm), p2(li, hc), p2(li, x0()), p2(lr, x0()), p2(lr, hc), p2(l1, ht), p2(x0(), ht)],
    [sln(0n, 1n), sar(1n, l1, hc, r, 2n, False{}), sln(2n, 3n), sln(3n, 4n), sln(4n, 5n),
      sar(5n, l1, hc, ro, 6n, True{}), sln(6n, 7n)]}
def sh180up(+l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> PR:
  +l1 = l1x(l)
  +ro = rox(r, t)
  +tr = trx(t, r)
  +h2 = h2x(t, r)
  +t2r = xa(t, xm(x2(), r))
  PR{[p2(x0(), x0()), p2(l1, x0()), p2(l1, h2), p2(ro, h2), p2(ro, t2r), p2(l1, t2r), p2(l1, t),
      p2(x0(), t)],
    [sln(0n, 1n), sar(1n, l1, tr, ro, 2n, True{}), sln(2n, 3n), sln(3n, 4n), sln(4n, 5n),
      sar(5n, l1, tr, r, 6n, False{}), sln(6n, 7n)]}
def sh180dn(+l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> PR:
  +l1 = l1x(l)
  +ro = rox(r, t)
  +tr = trx(t, r)
  +h2 = h2x(t, r)
  +hm = xs(h2, t)
  PR{[p2(x0(), hm), p2(l1, hm), p2(l1, t), p2(ro, t), p2(ro, x0()), p2(l1, x0()), p2(l1, h2),
      p2(x0(), h2)],
    [sln(0n, 1n), sar(1n, l1, tr, r, 2n, False{}), sln(2n, 3n), sln(3n, 4n), sln(4n, 5n),
      sar(5n, l1, tr, ro, 6n, True{}), sln(6n, 7n)]}
def shUup(+l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> PR:
  +ro = rox(r, t)
  +tr = trx(t, r)
  +hf = hfx(l, t, r)
  +ltr = xs(l, tr)
  +lt = xs(l, t)
  PR{[p2(x0(), hf), p2(x0(), tr), p2(tr, x0()), p2(ltr, x0()), p2(l, tr), p2(l, hf), p2(lt, hf),
      p2(lt, tr), p2(ltr, t), p2(tr, t), p2(t, tr), p2(t, hf)],
    [sln(0n, 1n), sar(1n, tr, tr, ro, 2n, True{}), sln(2n, 3n), sar(3n, ltr, tr, ro, 4n, True{}),
      sln(4n, 5n), sln(5n, 6n), sln(6n, 7n), sar(7n, ltr, tr, r, 8n, False{}), sln(8n, 9n),
      sar(9n, tr, tr, r, 10n, False{}), sln(10n, 11n)]}
def shUdn(+l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> PR:
  +ro = rox(r, t)
  +tr = trx(t, r)
  +hf = hfx(l, t, r)
  +hm = xs(hf, t)
  +hc = xs(hm, r)
  +ltr = xs(l, tr)
  +lt = xs(l, t)
  PR{[p2(t, x0()), p2(t, hc), p2(tr, hm), p2(ltr, hm), p2(lt, hc), p2(lt, x0()), p2(l, x0()),
      p2(l, hc), p2(ltr, hf), p2(tr, hf), p2(x0(), hc), p2(x0(), x0())],
    [sln(0n, 1n), sar(1n, tr, hc, r, 2n, False{}), sln(2n, 3n), sar(3n, ltr, hc, r, 4n, False{}),
      sln(4n, 5n), sln(5n, 6n), sln(6n, 7n), sar(7n, ltr, hc, ro, 8n, True{}), sln(8n, 9n),
      sar(9n, tr, hc, ro, 10n, True{}), sln(10n, 11n)]}
def shHemT(+l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> PR:
  +t2 = t2x(t)
  +lhx = xs(l, lh)
  PR{[p2(x0(), x0()), p2(l, x0()), p2(l, t2), p2(lhx, t2), p2(lhx, t), p2(x0(), t)],
    [sln(0n, 1n), sln(1n, 2n), sln(2n, 3n), sln(3n, 4n), sln(4n, 5n)]}
def shHemB(+l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> PR:
  +t2 = t2x(t)
  +lhx = xs(l, lh)
  PR{[p2(x0(), t), p2(lhx, t), p2(lhx, x0()), p2(l, x0()), p2(l, t2), p2(x0(), t2)],
    [sln(0n, 1n), sln(1n, 2n), sln(2n, 3n), sln(3n, 4n), sln(4n, 5n)]}
def shTipU(+l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> PR:
  +l1 = l1x(l)
  +ro = rox(r, t)
  +tr = trx(t, r)
  +ht = htx(l, t, r)
  +hl = xs(ht, lh)
  +lr = xa(l1, ro)
  +li = xa(l1, r)
  +rt = xa(lr, t)
  PR{[p2(x0(), x0()), p2(l1, x0()), p2(lr, tr), p2(lr, hl), p2(rt, hl), p2(rt, ht), p2(li, ht),
      p2(li, tr), p2(l1, t), p2(x0(), t)],
    [sln(0n, 1n), sar(1n, l1, tr, ro, 2n, True{}), sln(2n, 3n), sln(3n, 4n), sln(4n, 5n),
      sln(5n, 6n), sln(6n, 7n), sar(7n, l1, tr, r, 8n, False{}), sln(8n, 9n)]}
def shTipD(+l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> PR:
  +l1 = l1x(l)
  +ro = rox(r, t)
  +tr = trx(t, r)
  +ht = htx(l, t, r)
  +hm = xs(ht, t)
  +hc = xs(hm, r)
  +lr = xa(l1, ro)
  +li = xa(l1, r)
  +rt = xa(lr, t)
  PR{[p2(x0(), hm), p2(l1, hm), p2(li, hc), p2(li, x0()), p2(rt, x0()), p2(rt, lh), p2(lr, lh),
      p2(lr, hc), p2(l1, ht), p2(x0(), ht)],
    [sln(0n, 1n), sar(1n, l1, hc, r, 2n, False{}), sln(2n, 3n), sln(3n, 4n), sln(4n, 5n),
      sln(5n, 6n), sln(6n, 7n), sar(7n, l1, hc, ro, 8n, True{}), sln(8n, 9n)]}
def shTipUR(+l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> PR:
  +ro = rox(r, t)
  +tr = trx(t, r)
  +hf = hfx(l, t, r)
  +hl = xs(hf, lh)
  +ltr = xs(l, tr)
  +lt = xs(l, t)
  +ltt = xa(l, t)
  PR{[p2(x0(), hf), p2(x0(), tr), p2(tr, x0()), p2(ltr, x0()), p2(l, tr), p2(l, hl), p2(ltt, hl),
      p2(ltt, hf), p2(lt, hf), p2(lt, tr), p2(ltr, t), p2(tr, t), p2(t, tr), p2(t, hf)],
    [sln(0n, 1n), sar(1n, tr, tr, ro, 2n, True{}), sln(2n, 3n), sar(3n, ltr, tr, ro, 4n, True{}),
      sln(4n, 5n), sln(5n, 6n), sln(6n, 7n), sln(7n, 8n), sln(8n, 9n),
      sar(9n, ltr, tr, r, 10n, False{}), sln(10n, 11n), sar(11n, tr, tr, r, 12n, False{}), sln(12n, 13n)]}
def shTipUL(+l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> PR:
  +ro = rox(r, t)
  +tr = trx(t, r)
  +hf = hfx(l, t, r)
  +hl = xs(hf, lh)
  +lr = xs(l, r)
  +ttr = xa(t2x(t), r)
  +tt = t2x(t)
  +ltt = xa(l, t)
  PR{[p2(l, hf), p2(l, tr), p2(lr, t), p2(ttr, t), p2(tt, tr), p2(tt, hf), p2(x0(), hf),
      p2(x0(), hl), p2(t, hl), p2(t, tr), p2(ttr, x0()), p2(lr, x0()), p2(ltt, tr), p2(ltt, hf)],
    [sln(0n, 1n), sar(1n, lr, tr, r, 2n, False{}), sln(2n, 3n), sar(3n, ttr, tr, r, 4n, False{}),
      sln(4n, 5n), sln(5n, 6n), sln(6n, 7n), sln(7n, 8n), sln(8n, 9n),
      sar(9n, ttr, tr, ro, 10n, True{}), sln(10n, 11n), sar(11n, lr, tr, ro, 12n, True{}), sln(12n, 13n)]}
def sh_prof(+p: PK, +l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> PR:
  match p:
    case K0{}: sh90up(l, t, r, lh)
    case K1{}: sh90dn(l, t, r, lh)
    case K2{}: sh180up(l, t, r, lh)
    case K3{}: sh180dn(l, t, r, lh)
    case K4{}: shUup(l, t, r, lh)
    case K5{}: shUdn(l, t, r, lh)
    case K6{}: shHemT(l, t, r, lh)
    case K7{}: shHemB(l, t, r, lh)
    case K8{}: shTipU(l, t, r, lh)
    case K9{}: shTipD(l, t, r, lh)
    case K10{}: shTipUR(l, t, r, lh)
    case K11{}: shTipUL(l, t, r, lh)
def pk_of_k(+k: U64) -> PK:
  match k:
    case 0u64: K0{}
    case 1u64: K1{}
    case 2u64: K2{}
    case 3u64: K3{}
    case 4u64: K4{}
    case 5u64: K5{}
    case 6u64: K6{}
    case 7u64: K7{}
    case 8u64: K8{}
    case 9u64: K9{}
    case 10u64: K10{}
    case 11u64: K11{}
    case _: K0{}
def prof_w(+k: U64, +l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> X.Xp:
  match k:
    case 0u64: xa(l1x(l), rox(r, t))
    case 1u64: xa(l1x(l), rox(r, t))
    case 2u64: xa(l1x(l), rox(r, t))
    case 3u64: xa(l1x(l), rox(r, t))
    case 4u64: l
    case 5u64: l
    case 6u64: l
    case 7u64: l
    case 8u64: xa(xa(l1x(l), rox(r, t)), t)
    case 9u64: xa(xa(l1x(l), rox(r, t)), t)
    case 10u64: xa(l, t)
    case 11u64: xa(l, t)
    case _: l
def prof_h(+k: U64, +l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> X.Xp:
  match k:
    case 0u64: htx(l, t, r)
    case 1u64: htx(l, t, r)
    case 2u64: h2x(t, r)
    case 3u64: h2x(t, r)
    case 4u64: hfx(l, t, r)
    case 5u64: hfx(l, t, r)
    case 6u64: t2x(t)
    case 7u64: t2x(t)
    case 8u64: htx(l, t, r)
    case 9u64: htx(l, t, r)
    case 10u64: hfx(l, t, r)
    case 11u64: hfx(l, t, r)
    case _: htx(l, t, r)
def pts_rot_go(+p: P2, +mx: X.Xp, +my: X.Xp) -> P2:
  P2{+x, +y} = p
  p2(xs(mx, x), xs(my, y))
def pts_rot(ps: List<&2, P2>, +mx: X.Xp, +my: X.Xp) -> List<&2, P2>:
  match ps:
    case []: []
    case +p <> t: pts_rot_go(p, mx, my) <> pts_rot(t, mx, my)
def sg_rot(+s: Sg, +mx: X.Xp, +my: X.Xp) -> Sg:
  match s:
    case Sg_ln{+a, +b}: sln(a, b)
    case Sg_ar{+a, +cx, +cy, +r, +b, +ccw}: sar(a, xs(mx, cx), xs(my, cy), r, b, ccw)
def segs_rot(ss: List<&2, Sg>, +mx: X.Xp, +my: X.Xp) -> List<&2, Sg>:
  match ss:
    case []: []
    case +s <> t: sg_rot(s, mx, my) <> segs_rot(t, mx, my)
def rot180(+p: PR, +mx: X.Xp, +my: X.Xp) -> PR:
  PR{+pts, +segs} = p
  PR{pts_rot(pts, mx, my), segs_rot(segs, mx, my)}
def p2x(+p: P2) -> X.Xp:
  P2{+x, +y} = p
  x
def p2y(+p: P2) -> X.Xp:
  P2{+x, +y} = p
  y
def pts_nth(ps: List<&2, P2>, +i: Nat) -> P2:
  match ps:
    case []: p2(x0(), x0())
    case +p <> t:
      match i:
        case 0n: p
        case 1n+j: pts_nth(t, j)
def sg_x(+s: Sg, +pts: List<&2, P2>) -> F.Seg:
  match s:
    case Sg_ln{+a, +b}: F.S_line{p2x(pts_nth(pts, b)), p2y(pts_nth(pts, b))}
    case Sg_ar{+a, +cx, +cy, +r, +b, +ccw}: F.S_arc{cx, cy, r, p2x(pts_nth(pts, b)), p2y(pts_nth(pts, b)), ccw}
def segs_go(ss: List<&2, Sg>, +pts: List<&2, P2>) -> List<&2, F.Seg>:
  match ss:
    case []: []
    case +s <> t: sg_x(s, pts) <> segs_go(t, pts)
def to_region(+p: PR) -> F.Region:
  PR{+pts, +segs} = p
  +s0 = pts_nth(pts, 0n)
  F.Rg{F.L_path{p2x(s0), p2y(s0), segs_go(segs, pts)}, []}
def beq(+a: Bool, +b: Bool) -> Bool:
  match a:
    case True{}: b
    case False{}: Bool.not(b)
def kp_k(+k: KP) -> U64:
  KP{+kk, +rot} = k
  kk
def kp_rot(+k: KP) -> Bool:
  KP{+kk, +rot} = k
  rot
def bend_k90(+n: U64) -> KP:
  match n:
    case 0u64: KP{0u64, False{}}
    case 1u64: KP{1u64, False{}}
    case 2u64: KP{1u64, True{}}
    case 3u64: KP{0u64, True{}}
    case _: KP{0u64, False{}}
def bend_k180(+n: U64) -> KP:
  match n:
    case 0u64: KP{2u64, False{}}
    case 1u64: KP{3u64, False{}}
    case 2u64: KP{3u64, True{}}
    case 3u64: KP{2u64, True{}}
    case _: KP{2u64, False{}}
def bend_k1(+n: U64, +deg: U64) -> KP:
  match deg:
    case 90u64: bend_k90(n)
    case 180u64: bend_k180(n)
    case _: KP{0u64, False{}}
def hem_k1(+n: U64) -> KP:
  match n:
    case 0u64: KP{6u64, False{}}
    case 1u64: KP{7u64, False{}}
    case 2u64: KP{7u64, True{}}
    case 3u64: KP{6u64, True{}}
    case _: KP{6u64, False{}}
def prof_one(+f: FT) -> KP:
  match f:
    case FT_bend{+n, +r, +deg}: bend_k1(n, deg)
    case FT_hem{+n, +l}: hem_k1(n)
def u_shape_go(+ok: Bool, +up: Bool) -> KP:
  match ok:
    case False{}: KP{4u64, False{}}
    case True{}:
      match up:
        case True{}: KP{4u64, False{}}
        case False{}: KP{4u64, True{}}
def u_shape(+n0: U64, +n1: U64, +d0: U64, +d1: U64) -> KP:
  u_shape_go(Bool.and(Bool.and(U64.is_eq(d0, 90u64), U64.is_eq(d1, 90u64)),
    Bool.and(Bool.not(U64.is_eq(end_of(n0), end_of(n1))), beq(dir_up(n0), dir_up(n1)))), dir_up(n0))
def tip_up_end(+up: Bool, +e: U64) -> KP:
  match up:
    case True{}:
      match e:
        case 0u64: KP{8u64, False{}}
        case _: KP{8u64, True{}}
    case False{}:
      match e:
        case 0u64: KP{9u64, False{}}
        case _: KP{9u64, True{}}
def tip_shape_go(+ok: Bool, +up: Bool, +e: U64) -> KP:
  match ok:
    case False{}: KP{8u64, False{}}
    case True{}: tip_up_end(up, e)
def tip_shape(+n0: U64, +n1: U64, +d0: U64) -> KP:
  tip_shape_go(Bool.and(U64.is_eq(d0, 90u64), U64.is_eq(end_of(n0), end_of(n1))), dir_up(n0), end_of(n0))
def prof_two(+f: FT, +g: FT) -> KP:
  match f:
    case FT_bend{+n0, +r0, +d0}:
      match g:
        case FT_bend{+n1, +r1, +d1}: u_shape(n0, n1, d0, d1)
        case FT_hem{+n1, +l1}: tip_shape(n0, n1, d0)
    case FT_hem{+n0, +l0}: KP{4u64, False{}}
def tipu_pick(+up: Bool, +e: U64) -> KP:
  match up:
    case True{}:
      match e:
        case 0u64: KP{10u64, False{}}
        case _: KP{11u64, False{}}
    case False{}:
      match e:
        case 0u64: KP{11u64, True{}}
        case _: KP{10u64, True{}}
def tipu_shape_go(+ok: Bool, +up: Bool, +e: U64) -> KP:
  match ok:
    case False{}: KP{10u64, False{}}
    case True{}: tipu_pick(up, e)
def tipu_shape(+n0: U64, +n1: U64, +d0: U64, +d1: U64, +nh: U64) -> KP:
  tipu_shape_go(Bool.and(Bool.and(U64.is_eq(d0, 90u64), U64.is_eq(d1, 90u64)),
    Bool.and(Bool.not(U64.is_eq(end_of(n0), end_of(n1))), beq(dir_up(n0), dir_up(n1)))), dir_up(n0), end_of(nh))
def prof_three(+f: FT, +g: FT, +h: FT) -> KP:
  match f:
    case FT_bend{+n0, +r0, +d0}:
      match g:
        case FT_bend{+n1, +r1, +d1}:
          match h:
            case FT_bend{+n2, +r2, +d2}: KP{10u64, False{}}
            case FT_hem{+nh, +lh}: tipu_shape(n0, n1, d0, d1, nh)
        case FT_hem{+n1, +l1}: KP{10u64, False{}}
    case FT_hem{+n0, +l0}: KP{10u64, False{}}
def prof_r3(+f: FT, +g: FT, +h: FT, +v: List<&2, FT>) -> KP:
  match v:
    case []: prof_three(f, g, h)
    case _ <> _: KP{4u64, False{}}
def prof_r2(+f: FT, +g: FT, +u: List<&2, FT>) -> KP:
  match u:
    case []: prof_two(f, g)
    case +h <> v: prof_r3(f, g, h, v)
def prof_r1(+f: FT, +t: List<&2, FT>) -> KP:
  match t:
    case []: prof_one(f)
    case +g <> u: prof_r2(f, g, u)
def prof_of(fs: List<&2, FT>) -> KP:
  match fs:
    case []: KP{254u64, False{}}
    case +f <> t: prof_r1(f, t)
def sc_prof(+s: SC) -> KP:
  match s:
    case SC_ok{+l, +w, +t, +feats}: prof_of(feats)
    case SC_bad{}: KP{255u64, False{}}
def u_full(+n0: U64, +n1: U64, +d0: U64, +d1: U64, +r0: X.Xp, +r1: X.Xp, +e: X.Env) -> Bool:
  Bool.and(Bool.and(U64.is_eq(d0, 90u64), U64.is_eq(d1, 90u64)),
    Bool.and(Bool.not(U64.is_eq(end_of(n0), end_of(n1))),
      Bool.and(beq(dir_up(n0), dir_up(n1)),
        U64.is_eq(F64.bits(X.xp_ev(r0, e)), F64.bits(X.xp_ev(r1, e))))))
def ref_two(+f: FT, +g: FT, +e: X.Env) -> Bool:
  match f:
    case FT_bend{+n0, +r0, +d0}:
      match g:
        case FT_bend{+n1, +r1, +d1}: Bool.not(u_full(n0, n1, d0, d1, r0, r1, e))
        case FT_hem{+n1, +l1}: Bool.not(Bool.and(U64.is_eq(d0, 90u64), U64.is_eq(end_of(n0), end_of(n1))))
    case FT_hem{+n0, +l0}: True{}
def ref_three(+f: FT, +g: FT, +h: FT, +e: X.Env) -> Bool:
  match f:
    case FT_bend{+n0, +r0, +d0}:
      match g:
        case FT_bend{+n1, +r1, +d1}:
          match h:
            case FT_bend{+n2, +r2, +d2}: True{}
            case FT_hem{+nh, +lh}: Bool.not(u_full(n0, n1, d0, d1, r0, r1, e))
        case FT_hem{+n1, +l1}: True{}
    case FT_hem{+n0, +l0}: True{}
def ref_r3(+f: FT, +g: FT, +h: FT, +v: List<&2, FT>, +e: X.Env) -> Bool:
  match v:
    case []: ref_three(f, g, h, e)
    case _ <> _: True{}
def ref_r2(+f: FT, +g: FT, +u: List<&2, FT>, +e: X.Env) -> Bool:
  match u:
    case []: ref_two(f, g, e)
    case +h <> v: ref_r3(f, g, h, v, e)
def ref_r1(+f: FT, +t: List<&2, FT>, +e: X.Env) -> Bool:
  match t:
    case []: False{}
    case +g <> u: ref_r2(f, g, u, e)
def ref_fs(fs: List<&2, FT>, +e: X.Env) -> Bool:
  match fs:
    case []: False{}
    case +f <> t: ref_r1(f, t, e)
def sc_refused(+s: SC, +e: X.Env) -> Bool:
  match s:
    case SC_ok{+l, +w, +t, +feats}: ref_fs(feats, e)
    case SC_bad{}: True{}
def base_r1(+h1: FT, +t1: List<&2, FT>) -> Bool:
  match t1:
    case []: False{}
    case +h2 <> _: Bool.and(Bool.not(ft_is_bend(h1)), ft_is_bend(h2))
def base_of(fs: List<&2, FT>) -> Bool:
  match fs:
    case []: False{}
    case +h1 <> t1: base_r1(h1, t1)
def sc_is_base(+s: SC) -> Bool:
  match s:
    case SC_ok{+l, +w, +t, +feats}: base_of(feats)
    case SC_bad{}: True{}
def ft_r_ev(+f: FT, +e: X.Env) -> F64:
  match f:
    case FT_bend{+n, +r, +deg}: X.xp_ev(r, e)
    case FT_hem{+n, +l}: 0.0f64
def ft_l_ev(+f: FT, +e: X.Env) -> F64:
  match f:
    case FT_bend{+n, +r, +deg}: 0.0f64
    case FT_hem{+n, +l}: X.xp_ev(l, e)
def ft_r_xp(+f: FT) -> X.Xp:
  match f:
    case FT_bend{+n, +r, +deg}: r
    case FT_hem{+n, +l}: x0()
def ft_l_xp(+f: FT) -> X.Xp:
  match f:
    case FT_bend{+n, +r, +deg}: x0()
    case FT_hem{+n, +l}: l
def angs_ok(fs: List<&2, FT>) -> Bool:
  match fs:
    case []: True{}
    case +f <> t: Bool.and(Bool.pick(Bool, ft_is_bend(f), ang_ok(ft_deg(f)), True{}), angs_ok(t))
def edges_ok(fs: List<&2, FT>) -> Bool:
  match fs:
    case []: True{}
    case +f <> t: Bool.and(edge_ok(ft_n(f)), edges_ok(t))
def rts_ok(fs: List<&2, FT>, +e: X.Env, +th: F64) -> Bool:
  match fs:
    case []: True{}
    case +f <> t: Bool.and(Bool.pick(Bool, ft_is_bend(f), rt_ok(ft_r_ev(f, e), th), True{}), rts_ok(t, e, th))
def has_bend(fs: List<&2, FT>) -> Bool:
  match fs:
    case []: False{}
    case +f <> t: Bool.or(ft_is_bend(f), has_bend(t))
def has_hem(fs: List<&2, FT>) -> Bool:
  match fs:
    case []: False{}
    case +f <> t: Bool.or(Bool.not(ft_is_bend(f)), has_hem(t))
def first_r(fs: List<&2, FT>, +e: X.Env) -> F64:
  match fs:
    case []: 0.0f64
    case +f <> t: Bool.pick(F64, ft_is_bend(f), ft_r_ev(f, e), first_r(t, e))
def first_lh(fs: List<&2, FT>, +e: X.Env) -> F64:
  match fs:
    case []: 0.0f64
    case +f <> t: Bool.pick(F64, ft_is_bend(f), first_lh(t, e), ft_l_ev(f, e))
def first_rx(fs: List<&2, FT>) -> X.Xp:
  match fs:
    case []: x0()
    case +f <> t: Bool.pick(X.Xp, ft_is_bend(f), ft_r_xp(f), first_rx(t))
def first_lhx(fs: List<&2, FT>) -> X.Xp:
  match fs:
    case []: x0()
    case +f <> t: Bool.pick(X.Xp, ft_is_bend(f), first_lhx(t), ft_l_xp(f))
def first_deg(fs: List<&2, FT>) -> U64:
  match fs:
    case []: 90u64
    case +f <> t: Bool.pick(U64, ft_is_bend(f), ft_deg(f), first_deg(t))
def first_n(fs: List<&2, FT>) -> U64:
  match fs:
    case []: 0u64
    case +f <> t: ft_n(f)
def l1f(+l: F64) -> F64:
  F64.div(l, 2.0f64)
def rof(+r: F64, +t: F64) -> F64:
  F64.add(r, t)
def f1f(+l: F64, +t: F64, +r: F64) -> F64:
  F64.sub(l1f(l), rof(r, t))
def fuf(+l: F64, +t: F64, +r: F64) -> F64:
  F64.div(F64.sub(l, F64.mul(2.0f64, rof(r, t))), 4.0f64)
def size_need(+k: U64) -> Bool:
  Bool.or(U64.is_lt(k, 6u64), Bool.and(U64.is_le(8u64, k), U64.is_le(k, 11u64)))
def size_ok_go(+need: Bool, +l: F64, +t: F64, +r: F64) -> Bool:
  match need:
    case False{}: True{}
    case True{}: F64.is_lt(F64.mul(2.0f64, rof(r, t)), l)
def size_ok(+k: U64, +l: F64, +t: F64, +r: F64) -> Bool:
  size_ok_go(size_need(k), l, t, r)
def len_need(+k: U64, +haslh: Bool) -> Bool:
  Bool.and(haslh, Bool.and(U64.is_le(6u64, k), U64.is_le(k, 11u64)))
def leg_of(+k: U64, +l: F64, +t: F64, +r: F64, +lh: F64) -> F64:
  match k:
    case 6u64: l
    case 7u64: l
    case 8u64: f1f(l, t, r)
    case 9u64: f1f(l, t, r)
    case 10u64: fuf(l, t, r)
    case 11u64: fuf(l, t, r)
    case _: lh
def len_ok_go(+need: Bool, +k: U64, +l: F64, +t: F64, +r: F64, +lh: F64) -> Bool:
  match need:
    case False{}: True{}
    case True{}: F64.is_lt(lh, leg_of(k, l, t, r, lh))
def len_ok(+k: U64, +l: F64, +t: F64, +r: F64, +lh: F64, +haslh: Bool) -> Bool:
  len_ok_go(len_need(k, haslh), k, l, t, r, lh)
def fin_all(+l: F64, +w: F64, +t: F64, +r0: F64, +lh0: F64, +hb: Bool, +hh: Bool) -> Bool:
  Bool.and(Bool.and(fin1(l), Bool.and(fin1(w), fin1(t))),
    Bool.and(Bool.or(Bool.not(hb), fin1(r0)), Bool.or(Bool.not(hh), fin1(lh0))))
def ck_pick(+g: GR, +n: GR) -> GR:
  match g:
    case GR_ok{}: n
    case GR_no{+why, +fix}: g
def ck_chain(+s: SC, +e: X.Env, +l: F64, +w: F64, +t: F64) -> GR:
  +fs = sc_feats(s)
  +kk = kp_k(sc_prof(s))
  +r0 = first_r(fs, e)
  +lh0 = first_lh(fs, e)
  +hb = has_bend(fs)
  +hh = has_hem(fs)
  ck_pick(base_go(sc_sc_ok(s), feats_len(fs)),
    ck_pick(fin_go(fin_all(l, w, t, r0, lh0, hb, hh), l, w, t, r0, lh0),
    ck_pick(ang_go(angs_ok(fs), first_deg(fs)),
      ck_pick(edge_go(edges_ok(fs), first_n(fs)),
        ck_pick(gram_go(Bool.not(sc_refused(s, e)), sc_is_base(s), feats_len(fs)),
          ck_pick(rt_go(rts_ok(fs, e, t), r0, t),
            ck_pick(size_go(size_ok(kk, l, t, r0), l, rof(r0, t)),
              len_go(len_ok(kk, l, t, r0, lh0, hh), lh0, leg_of(kk, l, t, r0, lh0)))))))))
def vol_arc(+l: F64, +t: F64, +r: F64, +w: F64, +half: Bool) -> F64:
  +l1 = l1f(l)
  +ro = rof(r, t)
  +f1 = F64.sub(l1, ro)
  +q = Bool.pick(F64, half, F64.div(pi(), 2.0f64), F64.div(pi(), 4.0f64))
  +d = F64.sub(F64.mul(ro, ro), F64.mul(r, r))
  +an = F64.mul(q, d)
  +a = F64.add(F64.mul(l1, t), F64.add(F64.mul(f1, t), an))
  F64.mul(a, w)
def vol_u(+l: F64, +t: F64, +r: F64, +w: F64) -> F64:
  +ro = rof(r, t)
  +fu = fuf(l, t, r)
  +t1 = F64.sub(fu, F64.add(t, r))
  +leg = F64.mul(F64.mul(2.0f64, t), t1)
  +tt = F64.mul(t, F64.add(F64.mul(2.0f64, r), t))
  +an = F64.mul(F64.div(pi(), 2.0f64), tt)
  +a = F64.add(F64.mul(l, t), F64.add(leg, an))
  F64.mul(a, w)
def vol_hemf(+l: F64, +t: F64, +w: F64, +lh: F64) -> F64:
  F64.mul(F64.add(F64.mul(l, t), F64.mul(lh, t)), w)
def sh_vol(+k: U64, +l: F64, +t: F64, +r: F64, +w: F64, +lh: F64) -> F64:
  match k:
    case 0u64: vol_arc(l, t, r, w, False{})
    case 1u64: vol_arc(l, t, r, w, False{})
    case 2u64: vol_arc(l, t, r, w, True{})
    case 3u64: vol_arc(l, t, r, w, True{})
    case 4u64: vol_u(l, t, r, w)
    case 5u64: vol_u(l, t, r, w)
    case 6u64: vol_hemf(l, t, w, lh)
    case 7u64: vol_hemf(l, t, w, lh)
    case 8u64: F64.add(vol_arc(l, t, r, w, False{}), F64.mul(F64.mul(lh, t), w))
    case 9u64: F64.add(vol_arc(l, t, r, w, False{}), F64.mul(F64.mul(lh, t), w))
    case 10u64: F64.add(vol_u(l, t, r, w), F64.mul(F64.mul(lh, t), w))
    case 11u64: F64.add(vol_u(l, t, r, w), F64.mul(F64.mul(lh, t), w))
    case 254u64: F64.mul(F64.mul(l, t), w)
    case _: 0.0f64
def legs_k(+k: U64, +l: X.Xp, +t: X.Xp, +r: X.Xp, +lh: X.Xp) -> List<&2, X.Xp>:
  match k:
    case 0u64: [l1x(l), f1x(l, r, t)]
    case 1u64: [l1x(l), f1x(l, r, t)]
    case 2u64: [l1x(l), f1x(l, r, t)]
    case 3u64: [l1x(l), f1x(l, r, t)]
    case 4u64: [fux(l, r, t), webx(l, r, t), fux(l, r, t)]
    case 5u64: [fux(l, r, t), webx(l, r, t), fux(l, r, t)]
    case 6u64: [l, t, lh]
    case 7u64: [l, t, lh]
    case 8u64: [l1x(l), xs(f1x(l, r, t), lh), t, lh, lh]
    case 9u64: [l1x(l), xs(f1x(l, r, t), lh), t, lh, lh]
    case 10u64: [xs(fux(l, r, t), lh), t, lh, lh, webx(l, r, t), fux(l, r, t)]
    case 11u64: [xs(fux(l, r, t), lh), t, lh, lh, webx(l, r, t), fux(l, r, t)]
    case _: [l]
def flat_legs(+s: SC) -> List<&2, X.Xp>:
  match s:
    case SC_ok{+l, +w, +t, +feats}: legs_k(kp_k(prof_of(feats)), l, t, first_rx(feats), first_lhx(feats))
    case SC_bad{}: []
def bns_one(+b: Bool, +n: U64, +r: F64, +deg: U64, +rest: List<&2, BN>) -> List<&2, BN>:
  match b:
    case True{}: BN{n, r, deg} <> rest
    case False{}: rest
def bns_of(fs: List<&2, FT>, +e: X.Env) -> List<&2, BN>:
  match fs:
    case []: []
    case +f <> t: bns_one(ft_is_bend(f), ft_n(f), ft_r_ev(f, e), ft_deg(f), bns_of(t, e))
def hns_one(+b: Bool, +n: U64, +l: F64, +rest: List<&2, HN>) -> List<&2, HN>:
  match b:
    case True{}: rest
    case False{}: HN{n, l} <> rest
def hns_of(fs: List<&2, FT>, +e: X.Env) -> List<&2, HN>:
  match fs:
    case []: []
    case +f <> t: hns_one(ft_is_bend(f), ft_n(f), ft_l_ev(f, e), hns_of(t, e))
def allow_i(+deg: U64, +r: F64, +t: F64, +klo: F64, +khi: F64) -> I.I:
  +kk = {I.I{klo, khi} : I.I}
  +rt = I.iadd(I.ipt(r), I.imul(kk, I.ipt(t)))
  +c = I.imul(I.ipt(2.0f64), I.pi_i())
  +f = Bool.pick(F64, U64.is_eq(deg, 180u64), 0.5f64, 0.25f64)
  I.imul(I.ipt(f), I.imul(c, rt))
def flat_row(+i: Nat, +b: BN, +t: F64, +klo: F64, +khi: F64) -> FR:
  BN{+n, +r, +deg} = b
  +a = allow_i(deg, r, t, klo, khi)
  FR{i, n, deg, r, I.i_lo(a), I.i_hi(a)}
def rows_go(bs: List<&2, BN>, +th: F64, +klo: F64, +khi: F64, +i: Nat) -> List<&2, FR>:
  match bs:
    case []: []
    case +b <> t: flat_row(i, b, th, klo, khi) <> rows_go(t, th, klo, khi, Nat.add(i, 1n))
def flat_rows(+bs: List<&2, BN>, +th: F64, +klo: F64, +khi: F64) -> List<&2, FR>:
  rows_go(bs, th, klo, khi, 0n)
def fr_i(+f: FR) -> Nat:
  FR{+i, +n, +deg, +r, +lo, +hi} = f
  i
def fr_n(+f: FR) -> U64:
  FR{+i, +n, +deg, +r, +lo, +hi} = f
  n
def fr_deg(+f: FR) -> U64:
  FR{+i, +n, +deg, +r, +lo, +hi} = f
  deg
def fr_r(+f: FR) -> F64:
  FR{+i, +n, +deg, +r, +lo, +hi} = f
  r
def fr_lo(+f: FR) -> F64:
  FR{+i, +n, +deg, +r, +lo, +hi} = f
  lo
def fr_hi(+f: FR) -> F64:
  FR{+i, +n, +deg, +r, +lo, +hi} = f
  hi
def hn_n(+h: HN) -> U64:
  HN{+n, +l} = h
  n
def hn_l(+h: HN) -> F64:
  HN{+n, +l} = h
  l
def row_s(+f: FR) -> String:
  FR{+i, +n, +deg, +r, +lo, +hi} = f
  "bend " ++ Nat.show(i) ++ " edge " ++ U64.show(n) ++ " deg " ++ U64.show(deg) ++ " r " ++
    N.f_show(r) ++ " allowance [" ++ N.f_show(lo) ++ ", " ++ N.f_show(hi) ++ "] certified\n"
def rows_s(rs: List<&2, FR>) -> String:
  match rs:
    case []: ""
    case +f <> t: row_s(f) ++ rows_s(t)
def hns_s(hs: List<&2, HN>, +i: Nat) -> String:
  match hs:
    case []: ""
    case +h <> t:
      HN{+n, +l} = h
      "hem " ++ Nat.show(i) ++ " edge " ++ U64.show(n) ++ " len " ++ N.f_show(l) ++ "\n" ++ hns_s(t, Nat.add(i, 1n))
def legs_s_go(ls: List<&2, X.Xp>, +e: X.Env, +first: Bool) -> String:
  match ls:
    case []: ""
    case +h <> t:
      Bool.pick(String, first, "", ", ") ++ N.f_show(X.xp_ev(h, e)) ++ legs_s_go(t, e, False{})
def legs_s(+ls: List<&2, X.Xp>, +e: X.Env) -> String:
  legs_s_go(ls, e, True{})
def dev_legs(ls: List<&2, X.Xp>, +e: X.Env, +acc: I.I) -> I.I:
  match ls:
    case []: acc
    case +h <> t: dev_legs(t, e, I.iadd(acc, I.ipt(X.xp_ev(h, e))))
def dev_rows(rs: List<&2, FR>, +acc: I.I) -> I.I:
  match rs:
    case []: acc
    case +f <> t:
      FR{+i, +n, +deg, +r, +lo, +hi} = f
      dev_rows(t, I.iadd(acc, I.I{lo, hi}))
def flat_rep(+n: U64, +s: SC, +e: X.Env, +klo: F64, +khi: F64) -> String:
  +fs = sc_feats(s)
  +bns = bns_of(fs, e)
  +hns = hns_of(fs, e)
  +t = X.xp_ev(sc_t(s), e)
  +rows = flat_rows(bns, t, klo, khi)
  +legs = flat_legs(s)
  +dv = dev_rows(rows, dev_legs(legs, e, I.ipt(0.0f64)))
  "flat node " ++ U64.show(n) ++ " bends " ++ Nat.show(List.length(&2, BN, bns)) ++ " hems " ++
    Nat.show(List.length(&2, HN, hns)) ++ "\n" ++ rows_s(rows) ++ hns_s(hns, 0n) ++ "legs [" ++
    legs_s(legs, e) ++ "]\n" ++ "developed [" ++ N.f_show(I.i_lo(dv)) ++ ", " ++ N.f_show(I.i_hi(dv)) ++
    "] certified\n" ++ "blank " ++ N.f_show(X.xp_ev(sc_l(s), e)) ++ " " ++ N.f_show(X.xp_ev(sc_w(s), e)) ++ "\n"
