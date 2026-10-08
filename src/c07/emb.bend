import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../base/par.bend as B
import ../base/ex.bend as E
import ../c06/iv.bend as I
import ./ivx.bend as X
import ./rb.bend as R
import ./im.bend as M
import ./poly.bend as P
import ./eng.bend as N
import ./xs.bend as S
import ./ss.bend as SS
import ./isect.bend as Y
import ./mem.bend as Mm
import ./sol.bend as SO

type Eg is Data:
  Eg{ g: List<&2, G.GVal>, d: G.Dom, a: Nat, b: Nat, pa: List<&2, I.I>, pb: List<&2, I.I>, c: R.Cv, bx: List<&2, I.I>, u: U64, so: Nat }

type Fg is Data:
  Fg{ fd: SO.Fd, es: List<&2, Nat>, vs: List<&2, Nat>, so: Nat }

type It is Data:
  It{ k: U64, i: Nat, bx: List<&2, I.I> }

type Pr is Data:
  Pr{ k: U64, a: Nat, b: Nat }

type Cx is Data:
  Cx{ te: B.Tb<&2, Eg>, tf: B.Tb<&2, Fg>, tef: B.Tb<&2, List<&2, Nat>>, tol: F64, ns: Nat,
    sfs: B.Tb<&2, List<&2, SO.Fd>> }

type Cr is Data:
  Cr{ sa: Bool, sb: Bool }

type Ef is Data:
  Ef{ e: Nat, f: Nat }

type Fs is Data:
  Fs{ xs: List<&2, SO.Fi> }

def cv0() -> R.Cv:
  R.Cv{R.Rb{[], [], [], []}, 0.0f64, 1.0f64}

def hv_i(h: Ty.HVertex) -> Nat:
  Ty.HV{i, g} = h
  i

def he_i(h: Ty.HEdge) -> Nat:
  Ty.HE{i, g} = h
  i

def vp(+tv: B.Tb<&2, Ty.Vertex>, +i: Nat) -> List<&2, I.I>:
  M.p3(Ty.vx_p(B.tb_get(Ty.Vertex, tv, U32.from_nat(i))))

def eg_c(m: Maybe<&2, R.Cv>, +g: G.GVal, +d: G.Dom, +a: Nat, +b: Nat, +pa: List<&2, I.I>, +pb: List<&2, I.I>) -> Eg:
  match m:
    case None{}: Eg{[g], d, a, b, pa, pb, cv0(), [], 2u64, 0n}
    case Some{+c}: Eg{[g], d, a, b, pa, pb, c, R.cv_hbox(c), 0u64, 0n}

def eg_k(k: Ty.EdgeKind, +a: Nat, +b: Nat, +tv: B.Tb<&2, Ty.Vertex>) -> Eg:
  match k:
    case Ty.EK_curve{+g, +d}: eg_c(S.gv_cv(g, d), g, d, a, b, vp(tv, a), vp(tv, b))
    case Ty.EK_degenerate{}: Eg{[], G.Dom{0.0f64, 1.0f64}, a, b, [], [], cv0(), [], 1u64, 0n}

def eg_of(e: Ty.Edge, +tv: B.Tb<&2, Ty.Vertex>) -> Eg:
  Ty.Ed{g, v0, v1, k} = e
  eg_k(k, hv_i(v0), hv_i(v1), tv)

def egs_go(es: List<&2, Ty.Edge>, +tv: B.Tb<&2, Ty.Vertex>) -> List<&2, Eg>:
  match es:
    case []: []
    case e <> t: eg_of(e, tv) <> egs_go(t, tv)

def eg_u(e: Eg) -> U64:
  Eg{g, d, a, b, pa, pb, c, bx, u, so} = e
  u

def eg_bx(e: Eg) -> List<&2, I.I>:
  Eg{g, d, a, b, pa, pb, c, bx, u, so} = e
  bx

def ce_ev(ce: Ty.Coedge, +x: Ty.Ix, +acc: Fg) -> Fg:
  Ty.Ce{g, +eh, fwd, tr} = ce
  Fg{fd, es, vs, so} = acc
  +e = Ty.tres_ed(Ty.ix_ed(x, eh))
  Fg{fd, he_i(eh) <> es, hv_i(Ty.ed_v0(e)) <> hv_i(Ty.ed_v1(e)) <> vs, so}

def ces_ev(hs: List<&2, Ty.HCoedge>, +x: Ty.Ix, +acc: Fg) -> Fg:
  match hs:
    case []: acc
    case h <> t: ces_ev(t, x, ce_ev(Ty.tres_ce(Ty.ix_ce(x, h)), x, acc))

def lp_ev(l: Ty.Loop, +x: Ty.Ix, +acc: Fg) -> Fg:
  Ty.Lp{g, hs, k} = l
  ces_ev(hs, x, acc)

def lps_ev(hs: List<&2, Ty.HLoop>, +x: Ty.Ix, +acc: Fg) -> Fg:
  match hs:
    case []: acc
    case h <> t: lps_ev(t, x, lp_ev(Ty.tres_lp(Ty.ix_lp(x, h)), x, acc))

def fg_of(f: Ty.Face, +x: Ty.Ix, +fd: SO.Fd, +so: Nat) -> Fg:
  Ty.Fa{g, s, ls, same} = f
  lps_ev(ls, x, Fg{fd, [], [], so})

def fhs_fg(hs: List<&2, Ty.HFace>, +x: Ty.Ix, +fds: List<&2, SO.Fd>, +so: Nat) -> List<&2, Fg>:
  match hs:
    case []: []
    case h <> t:
      match fds:
        case []: []
        case d <> r: fg_of(Ty.tres_fa(Ty.ix_fa(x, h)), x, d, so) <> fhs_fg(t, x, r, so)

def drop_fd(n: Nat, +xs: List<&2, SO.Fd>) -> List<&2, SO.Fd>:
  match n:
    case 0n: xs
    case 1n+m:
      match xs:
        case []: []
        case x <> t: drop_fd(m, t)

def nth_nat(xs: List<&2, Nat>, +i: Nat) -> Nat:
  match xs:
    case []: 0n
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: nth_nat(t, j)

def shs_fg(ss: List<&2, Ty.Shell>, +x: Ty.Ix, +fds: List<&2, SO.Fd>, +mp: List<&2, Nat>, +at: Nat) -> List<&2, Fg>:
  match ss:
    case []: []
    case s <> t:
      Ty.Sh{g, +hs, k} = s
      List.append(&2, Fg, fhs_fg(hs, x, fds, nth_nat(mp, at)),
        shs_fg(t, x, drop_fd(List.length(&2, Ty.HFace, hs), fds), mp, Nat.add(at, 1n)))

def fg_fd(f: Fg) -> SO.Fd:
  Fg{fd, es, vs, so} = f
  fd

def fg_es(f: Fg) -> List<&2, Nat>:
  Fg{fd, es, vs, so} = f
  es

def fg_vs(f: Fg) -> List<&2, Nat>:
  Fg{fd, es, vs, so} = f
  vs

def eg_so(e: Eg) -> Nat:
  Eg{g, d, a, b, pa, pb, c, bx, u, so} = e
  so

def fg_so(f: Fg) -> Nat:
  Fg{fd, es, vs, so} = f
  so

def it_lo(x: It) -> F64:
  It{k, i, bx} = x
  I.i_lo(X.vn(bx, 0n))

def it_hi(x: It) -> F64:
  It{k, i, bx} = x
  I.i_hi(X.vn(bx, 0n))

def it_cmp(a: It, b: It) -> B.Sgn:
  +la = it_lo(a)
  +lb = it_lo(b)
  B.sgn_pick(F64.is_lt(la, lb), F64.is_lt(lb, la))

def it_so(s: B.So<&2, It>) -> List<&2, It>:
  B.So{ok, xs} = s
  xs

def ed_its(es: List<&2, Eg>, +i: Nat) -> List<&2, It>:
  match es:
    case []: []
    case +e <> t:
      +rest = ed_its(t, Nat.add(i, 1n))
      Bool.pick(List<&2, It>, U64.is_eq(eg_u(e), 0u64), It{0u64, i, eg_bx(e)} <> rest, rest)

def fa_its(fs: List<&2, Fg>, +i: Nat) -> List<&2, It>:
  match fs:
    case []: []
    case +f <> t:
      +rest = fa_its(t, Nat.add(i, 1n))
      +d = fg_fd(f)
      Bool.pick(List<&2, It>, Bool.and(SO.fd_ok(d), Nat.is_eq(List.length(&2, I.I, SO.fd_bx(d)), 3n)), It{1u64, i, SO.fd_bx(d)} <> rest, rest)

def pr_of(+x: It, +y: It) -> List<&2, Pr>:
  It{+kx, +ix, bx} = x
  It{+ky, +iy, by} = y
  +k = U64.add(kx, ky)
  +a = Bool.pick(Nat, U64.is_lt(ky, kx), iy, ix)
  +b = Bool.pick(Nat, U64.is_lt(ky, kx), ix, iy)
  +a2 = Bool.pick(Nat, Bool.and(U64.is_eq(kx, ky), Nat.is_lt(iy, ix)), iy, a)
  +b2 = Bool.pick(Nat, Bool.and(U64.is_eq(kx, ky), Nat.is_lt(iy, ix)), ix, b)
  Bool.pick(List<&2, Pr>, X.vdisj(bx, by), [], [Pr{k, a2, b2}])

def stop_at(ys: List<&2, It>, +hi: F64) -> Bool:
  match ys:
    case []: True{}
    case y <> t: F64.is_lt(hi, it_lo(y))

def scan(ys: List<&2, It>, stop: Bool, +x: It, +hi: F64) -> List<&2, Pr>:
  match ys:
    case []: []
    case +y <> +t:
      match stop:
        case True{}: []
        case False{}: List.append(&2, Pr, pr_of(x, y), scan(t, stop_at(t, hi), x, hi))

def sweep(xs: List<&2, It>) -> List<&2, Pr>:
  match xs:
    case []: []
    case +x <> +t:
      +hi = it_hi(x)
      List.append(&2, Pr, scan(t, stop_at(t, hi), x, hi), sweep(t))

def wid(xs: List<&2, I.I>, +tol: F64) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t: I.iwiden(x, tol) <> wid(t, tol)

def within(+p: List<&2, I.I>, +v: List<&2, I.I>, +tol: F64) -> Bool:
  X.vsub_of(p, wid(v, tol))

def near_any(vs: List<&2, List<&2, I.I>>, +p: List<&2, I.I>, +tol: F64) -> Bool:
  match vs:
    case []: False{}
    case v <> t: Bool.or(within(p, v, tol), near_any(t, p, tol))

def has(xs: List<&2, Nat>, +i: Nat) -> Bool:
  match xs:
    case []: False{}
    case x <> t: Bool.or(Nat.is_eq(x, i), has(t, i))

def sh_pt(+c: Bool, +p: List<&2, I.I>, +rest: List<&2, List<&2, I.I>>) -> List<&2, List<&2, I.I>>:
  Bool.pick(List<&2, List<&2, I.I>>, c, p <> rest, rest)

def fi1(+c: String, +a: Nat, +b: Nat) -> List<&2, SO.Fi>:
  [SO.Fi{c, a, b}]

# Shared tangent-sampling machinery (F5/F18, used by the ef and ee
# tangent tests): midpoint of an interval box, sample classification
# of a curve point against the other solid, two-sided combination
# (inside wins, then uncertain), and the multi-scale fold.
def bx_pt(+q: List<&2, I.I>) -> V.Point:
  V.Pt{X.imid(X.vn(q, 0n)), X.imid(X.vn(q, 1n)), X.imid(X.vn(q, 2n))}

def ef_mode_go(+c0: U64, +c1: U64) -> U64:
  Bool.pick(U64, Bool.or(U64.is_eq(c0, 1u64), U64.is_eq(c1, 1u64)), 1u64,
    Bool.pick(U64, Bool.or(U64.is_eq(c0, 2u64), U64.is_eq(c1, 2u64)), 2u64, 0u64))

def ef_clamp(+t: F64, +lo: F64, +hi: F64) -> F64:
  F64.min(hi, F64.max(lo, t))

def ef_smp(+ofds: List<&2, SO.Fd>, +bb: List<&2, I.I>, +c: R.Cv, +t: F64, +lo: F64, +hi: F64) -> U64:
  SO.classify_in(ofds, bb, bx_pt(R.cv_box(c, I.ipt(F64.div(F64.sub(t, lo), F64.sub(hi, lo))))))

def ef_tan_one(+ofds: List<&2, SO.Fd>, +bb: List<&2, I.I>, +c: R.Cv, +m: F64, +d: F64, +lo: F64, +hi: F64,
    +st: U64) -> U64:
  Bool.pick(U64, U64.is_eq(st, 1u64), 1u64,
    ef_mode_go(ef_mode_go(ef_smp(ofds, bb, c, ef_clamp(F64.sub(m, d), lo, hi), lo, hi),
      ef_smp(ofds, bb, c, ef_clamp(F64.add(m, d), lo, hi), lo, hi)), st))

def ef_tan_go(ds: List<&2, F64>, +ofds: List<&2, SO.Fd>, +bb: List<&2, I.I>, +c: R.Cv, +m: F64, +lo: F64,
    +hi: F64, +st: U64) -> U64:
  match ds:
    case []: st
    case d <> t: ef_tan_go(t, ofds, bb, c, m, lo, hi, ef_tan_one(ofds, bb, c, m, d, lo, hi, st))

# Cross-solid edge/edge tangent test (F18, kissing seams): a cross
# H_un hit is either a true crossing the solver could not certify
# or a tangent touch (certified points are transverse by
# construction, so tangency only ever reports H_un). Sample both
# curves on both sides of the hit against the opposite solid:
# strictly inside anywhere implies crossing; uncertain anywhere
# (with no inside) fails as uncertain; outside-or-on everywhere
# admits contact. Wide hit parameters fail as uncertain. Same-solid
# pairs keep the legacy uncertain verdict, and certified (H_pt)
# interior cross hits keep failing as crossings.
def ee_tan_code(+t: U64) -> String:
  Bool.pick(String, U64.is_eq(t, 1u64), "edge-crossing",
    Bool.pick(String, U64.is_eq(t, 2u64), "edge-crossing-uncertain", "contact-edge-edge"))

def ee_tan(+fda: List<&2, SO.Fd>, +bbA: List<&2, I.I>, +ca: R.Cv, +s: I.I, +loa: F64, +hia: F64,
    +fdb: List<&2, SO.Fd>, +bbB: List<&2, I.I>, +cb: R.Cv, +t: I.I, +lob: F64, +hib: F64) -> U64:
  +wa = F64.sub(hia, loa)
  +wb = F64.sub(hib, lob)
  +ok = Bool.and(Bool.and(F64.is_lt(loa, hia), F64.is_lt(lob, hib)),
    Bool.and(F64.is_lt(X.iwid(s), F64.div(wa, 1024.0f64)), F64.is_lt(X.iwid(t), F64.div(wb, 1024.0f64))))
  Bool.pick(U64, ok,
    ef_tan_go([F64.div(wb, 16.0f64), F64.div(wb, 64.0f64), F64.div(wb, 256.0f64), F64.div(wb, 1024.0f64)],
      fda, bbA, cb, X.imid(t), lob, hib,
      ef_tan_go([F64.div(wa, 16.0f64), F64.div(wa, 64.0f64), F64.div(wa, 256.0f64), F64.div(wa, 1024.0f64)],
        fdb, bbB, ca, X.imid(s), loa, hia, 0u64)),
    2u64)

def ee_un_go(near: Bool, +cross: Bool, +s: I.I, +t: I.I, +ca: R.Cv, +da: G.Dom, +cb: R.Cv, +db: G.Dom,
    +fda: List<&2, SO.Fd>, +bbA: List<&2, I.I>, +fdb: List<&2, SO.Fd>, +bbB: List<&2, I.I>, +a: Nat,
    +b: Nat) -> List<&2, SO.Fi>:
  match near:
    case True{}: []
    case False{}:
      match cross:
        case False{}: fi1("edge-crossing-uncertain", a, b)
        case True{}: fi1(ee_tan_code(ee_tan(fda, bbA, ca, s, S.dlo(da), S.dhi(da), fdb, bbB, cb, t,
          S.dlo(db), S.dhi(db))), a, b)

# Cross-solid edge/edge point hits at either edge's endpoints are contact
# (L9): cross pairs never share vertex indices, so the shared-index
# exclusion `sv` cannot fire for them. Certified interior-interior
# cross hits are transverse crossings and still fail; uncertain
# (H_un) cross hits take the tangent test above. See F5's edge/face
# discriminator for the sibling rule.
def ee_pt(+excl: Bool, +near_end: Bool, +cross: Bool, +a: Nat, +b: Nat) -> List<&2, SO.Fi>:
  Bool.pick(List<&2, SO.Fi>, excl, [],
    Bool.pick(List<&2, SO.Fi>, Bool.and(cross, near_end), fi1("contact-edge-edge", a, b),
      fi1("edge-crossing", a, b)))

def ee_hit(h: S.Hit, +sv: List<&2, List<&2, I.I>>, +sx: List<&2, List<&2, I.I>>, +tol: F64, +a: Nat,
    +b: Nat, +cross: Bool, +x: Eg, +y: Eg, +fda: List<&2, SO.Fd>, +bbA: List<&2, I.I>,
    +fdb: List<&2, SO.Fd>, +bbB: List<&2, I.I>) -> List<&2, SO.Fi>:
  match h:
    case S.H_pt{s, t, +p, c}: ee_pt(near_any(sv, p, tol), near_any(sx, p, tol), cross, a, b)
    case S.H_un{s, t, +p}:
      Eg{ga, da, aya, bya, pya, pyb, cya, byya, uya, soya} = x
      Eg{gyb, dyb, ayb, byb, pyb0, pyb1, cyb, byyb, uyb, soyb} = y
      ee_un_go(near_any(sv, p, tol), cross, s, t, cya, da, cyb, dyb, fda, bbA, fdb, bbB, a, b)
    case S.H_ov{s, t}: fi1(Bool.pick(String, cross, "contact-edge-edge", "edge-overlap"), a, b)
    case S.H_no{w}: fi1("edge-check-unsupported", a, b)

def first(xs: List<&2, SO.Fi>) -> List<&2, SO.Fi>:
  match xs:
    case []: []
    case x <> t: [x]

def ee_hits(hs: List<&2, S.Hit>, +sv: List<&2, List<&2, I.I>>, +sx: List<&2, List<&2, I.I>>, +tol: F64,
    +a: Nat, +b: Nat, +cross: Bool, +x: Eg, +y: Eg, +fda: List<&2, SO.Fd>, +bbA: List<&2, I.I>,
    +fdb: List<&2, SO.Fd>, +bbB: List<&2, I.I>) -> List<&2, SO.Fi>:
  match hs:
    case []: []
    case h <> t: List.append(&2, SO.Fi, ee_hit(h, sv, sx, tol, a, b, cross, x, y, fda, bbA, fdb, bbB),
      ee_hits(t, sv, sx, tol, a, b, cross, x, y, fda, bbA, fdb, bbB))

def eg_g(e: Eg) -> G.GVal:
  Eg{g, d, a, b, pa, pb, c, bx, u, so} = e
  SO.g1(g)

def eg_d(e: Eg) -> G.Dom:
  Eg{g, d, a, b, pa, pb, c, bx, u, so} = e
  d

def eg_a(e: Eg) -> Nat:
  Eg{g, d, a, b, pa, pb, c, bx, u, so} = e
  a

def eg_b(e: Eg) -> Nat:
  Eg{g, d, a, b, pa, pb, c, bx, u, so} = e
  b

def eg_pa(e: Eg) -> List<&2, I.I>:
  Eg{g, d, a, b, pa, pb, c, bx, u, so} = e
  pa

def eg_pb(e: Eg) -> List<&2, I.I>:
  Eg{g, d, a, b, pa, pb, c, bx, u, so} = e
  pb

def crs(+a0: Nat, +a1: Nat, +b0: Nat, +b1: Nat) -> List<&2, Cr>:
  +c00 = Bool.pick(List<&2, Cr>, Nat.is_eq(a0, b0), [Cr{False{}, False{}}], [])
  +c01 = Bool.pick(List<&2, Cr>, Nat.is_eq(a0, b1), [Cr{False{}, True{}}], [])
  +c10 = Bool.pick(List<&2, Cr>, Nat.is_eq(a1, b0), [Cr{True{}, False{}}], [])
  +c11 = Bool.pick(List<&2, Cr>, Nat.is_eq(a1, b1), [Cr{True{}, True{}}], [])
  List.append(&2, Cr, List.append(&2, Cr, c00, c01), List.append(&2, Cr, c10, c11))

def hp_go(xs: List<&2, I.I>, ys: List<&2, I.I>, zs: List<&2, I.I>, ws: List<&2, I.I>) -> List<&2, List<&2, I.I>>:
  match xs:
    case []: []
    case x <> xt:
      match ys:
        case []: []
        case y <> yt:
          match zs:
            case []: []
            case z <> zt:
              match ws:
                case []: []
                case w <> wt: [x, y, z, w] <> hp_go(xt, yt, zt, wt)

def hps(r: R.Rb) -> List<&2, List<&2, I.I>>:
  R.Rb{x, y, z, w} = r
  hp_go(x, y, z, w)

def rev_go(xs: List<&2, List<&2, I.I>>, +acc: List<&2, List<&2, I.I>>) -> List<&2, List<&2, I.I>>:
  match xs:
    case []: acc
    case x <> t: rev_go(t, x <> acc)

def ord(+e: Bool, +xs: List<&2, List<&2, I.I>>) -> List<&2, List<&2, I.I>>:
  Bool.pick(List<&2, List<&2, I.I>>, e, rev_go(xs, []), xs)

def same_iv(xs: List<&2, I.I>, ys: List<&2, I.I>) -> Bool:
  match xs:
    case []: True{}
    case +x <> xt:
      match ys:
        case []: True{}
        case +y <> yt: Bool.and(Bool.and(F64.is_eq(I.i_lo(x), I.i_lo(y)), F64.is_eq(I.i_hi(x), I.i_hi(y))), same_iv(xt, yt))

def pre_eq(xs: List<&2, List<&2, I.I>>, +p: List<&2, I.I>) -> Nat:
  match xs:
    case []: 0n
    case +x <> t: Bool.pick(Nat, same_iv(x, p), Nat.add(1n, pre_eq(t, p)), 0n)

def hd(xs: List<&2, List<&2, I.I>>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t: x

def drop_n(n: Nat, +xs: List<&2, List<&2, I.I>>) -> List<&2, List<&2, I.I>>:
  match n:
    case 0n: xs
    case 1n+m:
      match xs:
        case []: []
        case x <> t: drop_n(m, t)

def cart(+h: List<&2, I.I>) -> List<&2, I.I>:
  +w = X.vn(h, 3n)
  [I.idiv(X.vn(h, 0n), w), I.idiv(X.vn(h, 1n), w), I.idiv(X.vn(h, 2n), w)]

def wpos(xs: List<&2, List<&2, I.I>>) -> Bool:
  match xs:
    case []: True{}
    case +x <> t: Bool.and(X.ipos(X.vn(x, 3n)), wpos(t))

def uvs(xs: List<&2, List<&2, I.I>>, +e: List<&2, I.I>) -> List<&2, List<&2, I.I>>:
  match xs:
    case []: []
    case +x <> t: SO.unit(X.vsub(cart(x), e)) <> uvs(t, e)

def net(+c: R.Cv, +e: Bool, +dl: F64) -> List<&2, List<&2, I.I>>:
  +full = ord(e, hps(R.cv_rb(c)))
  +k = pre_eq(full, hd(full))
  +qs = ord(e, hps(R.rb_restr(R.cv_rb(c), Bool.pick(F64, e, F64.sub(1.0f64, dl), 0.0f64), Bool.pick(F64, e, 1.0f64, dl))))
  Bool.pick(List<&2, List<&2, I.I>>, wpos(qs), uvs(drop_n(k, qs), cart(hd(qs))), [])

def vsum(xs: List<&2, List<&2, I.I>>, +acc: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: acc
    case x <> t: vsum(t, X.vadd(acc, x))

def mn(xs: List<&2, List<&2, I.I>>, +n: List<&2, I.I>, +sg: F64, +acc: F64) -> F64:
  match xs:
    case []: acc
    case x <> t: mn(t, n, sg, F64.min(acc, I.i_lo(I.iscale(X.vdot(n, x), sg))))

def z3() -> List<&2, I.I>:
  [I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(0.0f64)]

def margin(+ua: List<&2, List<&2, I.I>>, +ub: List<&2, List<&2, I.I>>) -> F64:
  +n = X.vsub(SO.snap(SO.unit(SO.snap(vsum(ua, z3())))), SO.snap(SO.unit(SO.snap(vsum(ub, z3())))))
  Bool.pick(F64, Bool.or(Nat.is_eq(List.length(&2, List<&2, I.I>, ua), 0n), Nat.is_eq(List.length(&2, List<&2, I.I>, ub), 0n)), 0.0f64,
    F64.min(mn(ua, n, 1.0f64, 1.0f64), mn(ub, n, F64.neg(1.0f64), 1.0f64)))

def cone_ok(+ca: R.Cv, +cb: R.Cv, c: Cr, +dl: F64, +tol: F64) -> Bool:
  Cr{+sa, +sb} = c
  +m = margin(net(ca, sa, dl), net(cb, sb, dl))
  +g = X.vsub(R.cv_box(ca, I.ipt(Bool.pick(F64, sa, 1.0f64, 0.0f64))), R.cv_box(cb, I.ipt(Bool.pick(F64, sb, 1.0f64, 0.0f64))))
  +gap = I.i_hi(I.isqrt(X.vdot(g, g)))
  Bool.and(F64.is_lt(0.0f64, m), F64.is_le(F64.div(gap, m), tol))

def all_ok(cs: List<&2, Cr>, +ca: R.Cv, +cb: R.Cv, +dl: F64, +tol: F64) -> Bool:
  match cs:
    case []: True{}
    case c <> t: Bool.and(cone_ok(ca, cb, c, dl, tol), all_ok(t, ca, cb, dl, tol))

def pick_dl(ds: List<&2, F64>, +cs: List<&2, Cr>, +ca: R.Cv, +cb: R.Cv, +tol: F64) -> F64:
  match ds:
    case []: 6.103515625e-05f64
    case +d <> t: Bool.pick(F64, all_ok(cs, ca, cb, d, tol), d, pick_dl(t, cs, ca, cb, tol))

def piece(+i: Nat, +dl: F64) -> I.I:
  Bool.pick(I.I, Nat.is_eq(i, 0n), I.I{0.0f64, dl}, Bool.pick(I.I, Nat.is_eq(i, 1n), I.I{dl, F64.sub(1.0f64, dl)}, I.I{F64.sub(1.0f64, dl), 1.0f64}))

def end_ix(+e: Bool) -> Nat:
  Bool.pick(Nat, e, 2n, 0n)

def cut(cs: List<&2, Cr>, +ca: R.Cv, +cb: R.Cv, +dl: F64, +tol: F64, +i: Nat, +j: Nat) -> Bool:
  match cs:
    case []: False{}
    case +c <> t:
      Cr{+sa, +sb} = c
      Bool.or(Bool.and(Bool.and(Nat.is_eq(end_ix(sa), i), Nat.is_eq(end_ix(sb), j)), cone_ok(ca, cb, c, dl, tol)), cut(t, ca, cb, dl, tol, i, j))

def cells(n: Nat, +cs: List<&2, Cr>, +ca: R.Cv, +cb: R.Cv, +dl: F64, +tol: F64) -> List<&2, List<&2, I.I>>:
  match n:
    case 0n: []
    case 1n+(+m):
      +i = Nat.div(m, 3n)
      +j = Nat.mod(m, 3n)
      +rest = cells(m, cs, ca, cb, dl, tol)
      Bool.pick(List<&2, List<&2, I.I>>, cut(cs, ca, cb, dl, tol, i, j), rest, [piece(i, dl), piece(j, dl)] <> rest)

def bb_cells(bs: List<&2, List<&2, I.I>>, +ga: G.GVal, +gb: G.GVal, +ca: R.Cv, +cb: R.Cv) -> List<&2, S.Hit>:
  match bs:
    case []: []
    case +b <> t: List.append(&2, S.Hit, S.cc_bb(ga, gb, ca, cb, 40n, b), bb_cells(t, ga, gb, ca, cb))

def cells_of(+cs: List<&2, Cr>, +ca: R.Cv, +cb: R.Cv, +tol: F64) -> List<&2, List<&2, I.I>>:
  Bool.pick(List<&2, List<&2, I.I>>, Nat.is_eq(List.length(&2, Cr, cs), 0n), [[I.I{0.0f64, 1.0f64}, I.I{0.0f64, 1.0f64}]],
    cells(9n, cs, ca, cb, pick_dl([0.125f64, 0.015625f64, 0.0009765625f64, 6.103515625e-05f64], cs, ca, cb, tol), tol))

def eg_c_of(e: Eg) -> R.Cv:
  Eg{g, d, a, b, pa, pb, c, bx, u, so} = e
  c

def ee_sel(ex: Bool, +x: Eg, +y: Eg, +cs: List<&2, Cr>, +tol: F64) -> List<&2, S.Hit>:
  match ex:
    case True{}: S.inter_cc(eg_g(x), eg_d(x), eg_g(y), eg_d(y), 40n)
    case False{}:
      +ca = eg_c_of(x)
      +cb = eg_c_of(y)
      bb_cells(cells_of(cs, ca, cb, tol), eg_g(x), eg_g(y), ca, cb)

def ee(+x: Eg, +y: Eg, +ia: Nat, +ib: Nat, +tol: F64, +cross: Bool,
    +sfs: B.Tb<&2, List<&2, SO.Fd>>) -> List<&2, SO.Fi>:
  +a0 = eg_a(x)
  +a1 = eg_b(x)
  +b0 = eg_a(y)
  +b1 = eg_b(y)
  +s0 = Bool.or(Nat.is_eq(a0, b0), Nat.is_eq(a0, b1))
  +s1 = Bool.or(Nat.is_eq(a1, b0), Nat.is_eq(a1, b1))
  +sv = sh_pt(s0, eg_pa(x), sh_pt(s1, eg_pb(x), []))
  +sx = Bool.pick(List<&2, List<&2, I.I>>, cross, [eg_pa(x), eg_pb(x), eg_pa(y), eg_pb(y)], [])
  +fda = B.tb_get(List<&2, SO.Fd>, sfs, U32.from_nat(eg_so(x)))
  +fdb = B.tb_get(List<&2, SO.Fd>, sfs, U32.from_nat(eg_so(y)))
  +bbA = SO.bbox(fda, [])
  +bbB = SO.bbox(fdb, [])
  first(ee_hits(ee_sel(S.cc_exact(eg_g(x), eg_g(y)), x, y, crs(a0, a1, b0, b1), tol), sv, sx, tol, ia, ib,
    cross, x, y, fda, bbA, fdb, bbB))

def m_code(+m: U64, +bad: String, +a: Nat, +b: Nat) -> List<&2, SO.Fi>:
  Bool.pick(List<&2, SO.Fi>, U64.is_eq(m, 0u64), [], fi1(Bool.pick(String, U64.is_eq(m, 1u64), bad, "edge-face-uncertain"), a, b))

# Cross coplanar-overlap verdict (contact.face): a cross edge overlapping
# its face's surface is contact-or-disjoint, never a piercing (it lies in
# the surface), so a trim-boundary membership (2) maps to the contact code
# rather than failing. Same-solid pairs keep the strict verdict, so C07
# single-solid behavior is unchanged.
def m_code_x(+m: U64, +bad: String, +a: Nat, +b: Nat) -> List<&2, SO.Fi>:
  Bool.pick(List<&2, SO.Fi>, U64.is_eq(m, 0u64), [], fi1(bad, a, b))

def ef_ov(+m: U64, +badx: String, +bad: String, +cross: Bool, +a: Nat, +b: Nat) -> List<&2, SO.Fi>:
  match cross:
    case True{}: m_code_x(m, badx, a, b)
    case False{}: m_code(m, bad, a, b)

def ef_pt(near: Bool, +fd: SO.Fd, +p: List<&2, I.I>, +bad1: String, +bad2: String, +a: Nat, +b: Nat) -> List<&2, SO.Fi>:
  match near:
    case True{}: []
    case False{}:
      +m = Mm.member(SO.fd_fc(fd), p, SO.fd_im(fd))
      Bool.pick(List<&2, SO.Fi>, U64.is_eq(m, 0u64), [],
        fi1(Bool.pick(String, U64.is_eq(m, 1u64), bad1, bad2), a, b))

def ov_pt(+c: R.Cv, +s: I.I, +lo: F64, +hi: F64) -> List<&2, I.I>:
  R.cv_box(c, I.ipt(X.imid(I.idiv(I.isub(I.ipt(X.imid(s)), I.ipt(lo)), I.isub(I.ipt(hi), I.ipt(lo))))))

# Cross-solid edge/face piercing discriminator (F5): a transverse
# piercing reports the same H_pt as a tangent touch. Classify the edge's
# endpoints against the other solid: strictly inside either end implies
# piercing (keep the failing code); outside-or-on both ends admits
# contact; uncertain endpoint classification fails as uncertain.
# Modes: 0 contact, 1 piercing, 2 endpoint-uncertain. Same-solid pairs
# keep the old codes (mode ignored). See `ee_pt` for the sibling rule.
# Soundness (F5c): the mode only downgrades trim-boundary hits (m=2).
# A hit strictly inside the trim (m=1) always fails: an edge can pierce
# a face and exit elsewhere with both ends outside (rod through a box),
# so endpoint classification must never silence an interior hit. Only
# the H_ov arm (edge lying in the surface, which cannot pierce) maps
# m=1 through the mode.
def ef_end(+ofds: List<&2, SO.Fd>, +bb: List<&2, I.I>, +q: List<&2, I.I>) -> U64:
  SO.classify_in(ofds, bb, bx_pt(q))

def ef_mode(+ofds: List<&2, SO.Fd>, +pa0: List<&2, I.I>, +pa1: List<&2, I.I>, +cross: Bool) -> U64:
  match cross:
    case False{}: 0u64
    case True{}:
      +bb = SO.bbox(ofds, [])
      ef_mode_go(ef_end(ofds, bb, pa0), ef_end(ofds, bb, pa1))

def ef_bad2(+mode: U64) -> String:
  Bool.pick(String, U64.is_eq(mode, 1u64), "edge-face-penetration",
    Bool.pick(String, U64.is_eq(mode, 2u64), "edge-face-uncertain", "contact-edge-face"))

def ef_bad(+cross: Bool, +mode: U64, +base: String) -> String:
  match cross:
    case False{}: base
    case True{}: ef_bad2(mode)

# Cross-solid tangent-vs-piercing test (F5/F18): a cross H_pt hit
# strictly inside the trim (m=1) with no endpoint strictly inside is
# either a transverse piercing (rod through a box: both ends outside)
# or a tangent touch (sphere seam kissing a plane). Endpoints cannot
# tell them apart, so sample the edge on both sides of the hit at
# several scales and classify against the other solid: strictly
# inside at any sample implies piercing; uncertain anywhere (with no
# inside) fails as uncertain; outside-or-on everywhere admits
# contact. The hit parameter must be well localized, else uncertain:
# sampling around a wide hit box cannot bracket the true hit.
# Residual risk: a piercing whose inside segment is shorter than the
# finest scale (2^-10 of the edge domain) reads as contact; such a
# crossing always involves face area too, which the ff/ee pairs
# still catch.
def ef_tan(+ofds: List<&2, SO.Fd>, +bb: List<&2, I.I>, +c: R.Cv, +s: I.I, +lo: F64, +hi: F64) -> U64:
  +w = F64.sub(hi, lo)
  Bool.pick(U64, Bool.or(F64.is_le(hi, lo), F64.is_le(F64.div(w, 1024.0f64), X.iwid(s))), 2u64,
    ef_tan_go([F64.div(w, 16.0f64), F64.div(w, 64.0f64), F64.div(w, 256.0f64), F64.div(w, 1024.0f64)],
      ofds, bb, c, X.imid(s), lo, hi, 0u64))

def ef_tan_code(+t: U64) -> String:
  Bool.pick(String, U64.is_eq(t, 1u64), "edge-face-penetration",
    Bool.pick(String, U64.is_eq(t, 2u64), "edge-face-uncertain", "contact-edge-face"))

# Kissing-interior exception (F18): an edge endpoint ON the face with
# the other endpoint strictly inside is a touch from inside (a
# contained solid kissing the container wall), not a piercing — but
# only when the hit sits at the on-face endpoint. A middle hit with
# an endpoint inside is a true entry and still fails, as does any
# inside/outside endpoint pair (the edge crosses the surface).
def ef_m1_in(+ofds: List<&2, SO.Fd>, +bb: List<&2, I.I>, +pa0: List<&2, I.I>, +pa1: List<&2, I.I>,
    +p: List<&2, I.I>, +tol: F64, +a: Nat, +b: Nat) -> List<&2, SO.Fi>:
  +c0 = ef_end(ofds, bb, pa0)
  +c1 = ef_end(ofds, bb, pa1)
  +kiss = Bool.or(
    Bool.and(Bool.and(U64.is_eq(c0, 1u64), U64.is_eq(c1, 3u64)), near_any([pa1], p, tol)),
    Bool.and(Bool.and(U64.is_eq(c0, 3u64), U64.is_eq(c1, 1u64)), near_any([pa0], p, tol)))
  Bool.pick(List<&2, SO.Fi>, kiss, fi1("contact-edge-face", a, b), fi1("edge-face-penetration", a, b))

def ef_m1(+cross: Bool, +mode: U64, +ofds: List<&2, SO.Fd>, +bb: List<&2, I.I>, +c: R.Cv, +s: I.I, +lo: F64,
    +hi: F64, +pa0: List<&2, I.I>, +pa1: List<&2, I.I>, +p: List<&2, I.I>, +tol: F64, +a: Nat,
    +b: Nat) -> List<&2, SO.Fi>:
  match cross:
    case False{}: fi1("edge-face-penetration", a, b)
    case True{}:
      match mode:
        case 1u64: ef_m1_in(ofds, bb, pa0, pa1, p, tol, a, b)
        case _: fi1(ef_tan_code(ef_tan(ofds, bb, c, s, lo, hi)), a, b)

def ef_pt_x(near: Bool, +fd: SO.Fd, +p: List<&2, I.I>, +ofds: List<&2, SO.Fd>, +bb: List<&2, I.I>, +c: R.Cv,
    +s: I.I, +lo: F64, +hi: F64, +cross: Bool, +mode: U64, +pa0: List<&2, I.I>, +pa1: List<&2, I.I>,
    +tol: F64, +a: Nat, +b: Nat) -> List<&2, SO.Fi>:
  match near:
    case True{}: []
    case False{}:
      +m = Mm.member(SO.fd_fc(fd), p, SO.fd_im(fd))
      Bool.pick(List<&2, SO.Fi>, U64.is_eq(m, 0u64), [],
        Bool.pick(List<&2, SO.Fi>, U64.is_eq(m, 1u64), ef_m1(cross, mode, ofds, bb, c, s, lo, hi, pa0, pa1, p,
          tol, a, b),
          fi1(Bool.pick(String, cross, ef_bad2(mode), "edge-face-uncertain"), a, b)))

def ef_hit(h: S.Hit, +fd: SO.Fd, +c: R.Cv, +lo: F64, +hi: F64, +sv: List<&2, List<&2, I.I>>, +tol: F64, +a: Nat, +b: Nat, +cross: Bool, +mode: U64, +ofds: List<&2, SO.Fd>,
    +bb: List<&2, I.I>, +pa0: List<&2, I.I>, +pa1: List<&2, I.I>) -> List<&2, SO.Fi>:
  match h:
    case S.H_pt{s, t, +p, k}: ef_pt_x(near_any(sv, p, tol), fd, p, ofds, bb, c, s, lo, hi, cross, mode, pa0, pa1,
      tol, a, b)
    case S.H_un{s, t, +p}: ef_pt(near_any(sv, p, tol), fd, p, "edge-face-uncertain",
      Bool.pick(String, cross, ef_bad2(mode), "edge-face-uncertain"), a, b)
    case S.H_ov{+s, t}: ef_ov(Mm.member(SO.fd_fc(fd), ov_pt(c, s, lo, hi), SO.fd_im(fd)),
      ef_bad(cross, mode, "edge-face-overlap"), "edge-face-overlap", cross, a, b)
    case S.H_no{w}: fi1("edge-face-unsupported", a, b)

def ef_hits(hs: List<&2, S.Hit>, +fd: SO.Fd, +c: R.Cv, +lo: F64, +hi: F64, +sv: List<&2, List<&2, I.I>>, +tol: F64, +a: Nat, +b: Nat, +cross: Bool, +mode: U64, +ofds: List<&2, SO.Fd>,
    +bb: List<&2, I.I>, +pa0: List<&2, I.I>, +pa1: List<&2, I.I>) -> List<&2, SO.Fi>:
  match hs:
    case []: []
    case h <> t: List.append(&2, SO.Fi, ef_hit(h, fd, c, lo, hi, sv, tol, a, b, cross, mode, ofds, bb, pa0, pa1),
      ef_hits(t, fd, c, lo, hi, sv, tol, a, b, cross, mode, ofds, bb, pa0, pa1))

def mid_ov(+fd: SO.Fd, +c: R.Cv, +a: Nat, +b: Nat, +cross: Bool, +mode: U64) -> List<&2, SO.Fi>:
  ef_ov(Mm.member(SO.fd_fc(fd), R.cv_box(c, I.ipt(0.5f64)), SO.fd_im(fd)),
    ef_bad(cross, mode, "edge-face-overlap"), "edge-face-overlap", cross, a, b)

def any_co(fs: List<&2, Nat>, +tf: B.Tb<&2, Fg>, +g: G.GVal) -> Bool:
  match fs:
    case []: False{}
    case h <> t: Bool.or(S.coincide(SO.fd_g(fg_fd(B.tb_get(Fg, tf, U32.from_nat(h)))), g), any_co(t, tf, g))

def ef_cs(on: Bool, +x: Eg, +fd: SO.Fd, +vs: List<&2, Nat>, +ie: Nat, +jf: Nat, +tol: F64, +cross: Bool,
    +ofds: List<&2, SO.Fd>) -> List<&2, SO.Fi>:
  match on:
    case True{}: mid_ov(fd, eg_c_of(x), ie, jf, cross, ef_mode(ofds, eg_pa(x), eg_pb(x), cross))
    case False{}:
      Eg{g, +d, +a0, +a1, +pa0, +pa1, +c, bx, u, so} = x
      +sv = sh_pt(has(vs, a0), pa0, sh_pt(has(vs, a1), pa1, []))
      +bb = SO.bbox(ofds, [])
      first(ef_hits(S.inter_cs(SO.g1(g), d, SO.fd_g(fd), 40n), fd, c, S.dlo(d), S.dhi(d), sv, tol, ie, jf, cross,
        ef_mode(ofds, pa0, pa1, cross), ofds, bb, pa0, pa1))

def ef_go(own: Bool, +x: Eg, +f: Fg, +fe: List<&2, Nat>, +tf: B.Tb<&2, Fg>, +ie: Nat, +jf: Nat, +tol: F64,
    +cross: Bool, +ofds: List<&2, SO.Fd>) -> List<&2, SO.Fi>:
  match own:
    case True{}: []
    case False{}:
      +fd = fg_fd(f)
      ef_cs(any_co(fe, tf, SO.fd_g(fd)), x, fd, fg_vs(f), ie, jf, tol, cross, ofds)

def ef(+x: Eg, +f: Fg, +fe: List<&2, Nat>, +tf: B.Tb<&2, Fg>, +ie: Nat, +jf: Nat, +tol: F64, +cross: Bool,
    +ofds: List<&2, SO.Fd>) -> List<&2, SO.Fi>:
  ef_go(has(fg_es(f), ie), x, f, fe, tf, ie, jf, tol, cross, ofds)

def pl_n(g: G.GVal) -> List<&2, E.Ex>:
  match g:
    case G.GV_pl{w}:
      G.Pl{o, u, v} = w
      S.ecr(S.edir(u), S.edir(v))
    case _: []

def ax_of(g: G.GVal) -> List<&2, E.Ex>:
  match g:
    case G.GV_cy{w}:
      G.Cy{o, a, r} = w
      S.edir(a)
    case _: []

def is_pl(g: G.GVal) -> Bool:
  match g:
    case G.GV_pl{w}: True{}
    case _: False{}

def is_cy(g: G.GVal) -> Bool:
  match g:
    case G.GV_cy{w}: True{}
    case _: False{}

def ruled_pair(+a: G.GVal, +b: G.GVal) -> Bool:
  +pa = is_pl(a)
  +pb = is_pl(b)
  +ca = is_cy(a)
  +cb = is_cy(b)
  +pp = Bool.and(pa, pb)
  +pc = Bool.and(Bool.and(pa, cb), S.ez(S.edot(pl_n(a), ax_of(b))))
  +cp = Bool.and(Bool.and(ca, pb), S.ez(S.edot(pl_n(b), ax_of(a))))
  +cc = Bool.and(Bool.and(ca, cb), P.pzero_all(S.ecr(ax_of(a), ax_of(b))))
  Bool.or(Bool.or(pp, pc), Bool.or(cp, cc))

def rev_ax(g: G.GVal) -> List<&2, E.Ex>:
  match g:
    case G.GV_cy{w}:
      G.Cy{o, a, r} = w
      S.edir(a)
    case G.GV_co{w}:
      G.Co{o, a, k} = w
      S.edir(a)
    case G.GV_to{w}:
      G.To{o, a, bigr, r} = w
      S.edir(a)
    case _: []

def is_sp(g: G.GVal) -> Bool:
  match g:
    case G.GV_sp{w}: True{}
    case _: False{}

def circ_one(+p: G.GVal, +q: G.GVal) -> Bool:
  +ax = rev_ax(q)
  Bool.and(is_pl(p), Bool.or(is_sp(q), Bool.and(Nat.is_eq(List.length(&2, E.Ex, ax), 3n), P.pzero_all(S.ecr(pl_n(p), ax)))))

def ff_code(+a: G.GVal, +b: G.GVal) -> U64:
  Bool.pick(U64, S.coincide(a, b), 1u64, Bool.pick(U64, ruled_pair(a, b), 0u64,
    Bool.pick(U64, circ_one(a, b), 3u64, Bool.pick(U64, circ_one(b, a), 4u64, 2u64))))

def ov_one(m: Maybe<&2, List<&2, I.I>>, +g: SO.Fd) -> U64:
  match m:
    case None{}: 2u64
    case Some{+q}: Mm.member(SO.fd_fc(g), q, SO.fd_im(g))

def ov_code(+m: U64) -> U64:
  Bool.pick(U64, U64.is_eq(m, 0u64), 0u64, Bool.pick(U64, U64.is_eq(m, 1u64), 1u64, 2u64))

def ff_ov(+fa: SO.Fd, +fb: SO.Fd, +ia: Nat, +ib: Nat) -> List<&2, SO.Fi>:
  +x = ov_code(ov_one(SO.interior(fa), fb))
  +y = ov_code(ov_one(SO.interior(fb), fa))
  +w = U64.max(x, y)
  Bool.pick(List<&2, SO.Fi>, U64.is_eq(w, 0u64), [], fi1(Bool.pick(String, U64.is_eq(w, 1u64), "face-overlap", "face-overlap-uncertain"), ia, ib))

def ff_ov_x(+fa: SO.Fd, +fb: SO.Fd, +ia: Nat, +ib: Nat, +cross: Bool) -> List<&2, SO.Fi>:
  match cross:
    case False{}: ff_ov(fa, fb, ia, ib)
    case True{}:
      +x = ov_code(ov_one(SO.interior(fa), fb))
      +y = ov_code(ov_one(SO.interior(fb), fa))
      +w = U64.max(x, y)
      # Stated backstop (F5): coplanar overlap, certain or
      # trim-boundary-landing, is contact at the pair level. A genuine
      # volume overlap behind it mixes one solid's classify samples
      # strictly inside/outside, which the classify stage reports as
      # boundaries-cross-or-overlap. Residual: an overlap hiding from
      # every vertex and face-interior sample slips through (L10).
      # Same-solid pairs keep the strict verdicts.
      Bool.pick(List<&2, SO.Fi>, U64.is_eq(w, 0u64), [], fi1("contact-face-face", ia, ib))

def all_cvs(es: List<&2, Nat>, +te: B.Tb<&2, Eg>) -> List<&2, Eg>:
  match es:
    case []: []
    case e <> t: B.tb_get(Eg, te, U32.from_nat(e)) <> all_cvs(t, te)

def rad(+p: List<&2, I.I>, +tol: F64) -> F64:
  F64.add(F64.mul(4.0f64, X.vwid(p)), F64.mul(tol, 1024.0f64))

def nr_code(+b: List<&2, I.I>, +tb: List<&2, I.I>) -> U64:
  +fin = X.vfin(b)
  Bool.pick(U64, Bool.and(fin, X.vdisj(b, tb)), 0u64, Bool.pick(U64, Bool.and(fin, X.vsub_of(b, tb)), 1u64, 2u64))

def near_go(d: Nat, +k: U64, +c: R.Cv, +lo: F64, +hi: F64, +tb: List<&2, I.I>) -> Bool:
  match d:
    case 0n: U64.is_eq(k, 1u64)
    case 1n+(+e):
      match k:
        case 0u64: False{}
        case 1u64: True{}
        case _:
          +m = F64.mul(0.5f64, F64.add(lo, hi))
          Bool.or(near_go(e, nr_code(R.cv_box(c, I.I{lo, m}), tb), c, lo, m, tb), near_go(e, nr_code(R.cv_box(c, I.I{m, hi}), tb), c, m, hi, tb))

def near_one(far: Bool, +c: R.Cv, +tb: List<&2, I.I>) -> Bool:
  match far:
    case True{}: False{}
    case False{}: near_go(30n, nr_code(R.cv_box(c, I.I{0.0f64, 1.0f64}), tb), c, 0.0f64, 1.0f64, tb)

def near_cv(cs: List<&2, Eg>, +p: List<&2, I.I>, +tol: F64) -> Bool:
  match cs:
    case []: False{}
    case +e <> t:
      +tb = wid(p, rad(p, tol))
      +bx = eg_bx(e)
      Bool.or(near_one(Bool.or(Bool.not(Nat.is_eq(List.length(&2, I.I, bx), 3n)), X.vdisj(bx, tb)), eg_c_of(e), tb), near_cv(t, p, tol))

def hull_go(es: List<&2, Eg>, +acc: List<&2, I.I>) -> List<&2, I.I>:
  match es:
    case []: acc
    case +e <> t: hull_go(t, X.vhull(acc, eg_bx(e)))

def edge_hull(es: List<&2, Eg>) -> List<&2, I.I>:
  match es:
    case []: []
    case +e <> t: hull_go(t, eg_bx(e))

def flat_im(s: M.Im) -> Bool:
  match s:
    case M.M_pl{o, n}: True{}
    case M.M_cy{o, a, r}: True{}
    case _: False{}

def off_go(flat: Bool, es: List<&2, Eg>, +p: List<&2, I.I>) -> Bool:
  match flat:
    case False{}: False{}
    case True{}: X.vdisj(p, edge_hull(es))

def off_face(+f: SO.Fd, es: List<&2, Eg>, +p: List<&2, I.I>) -> Bool:
  off_go(flat_im(SO.fd_im(f)), es, p)

def m_off(far: Bool, +f: SO.Fd, +p: List<&2, I.I>) -> U64:
  match far:
    case True{}: 0u64
    case False{}: Mm.member(SO.fd_fc(f), p, SO.fd_im(f))

def m1n(nr: Bool, +f: SO.Fd, +es: List<&2, Eg>, +p: List<&2, I.I>) -> U64:
  match nr:
    case True{}: 3u64
    case False{}: m_off(off_face(f, es, p), f, p)

def m2(+fa: SO.Fd, +fb: SO.Fd, +csa: List<&2, Eg>, +csb: List<&2, Eg>, +p: List<&2, I.I>, +tol: F64) -> U64:
  U64.add(U64.mul(m1n(near_cv(csa, p, tol), fa, csa, p), 4u64), m1n(near_cv(csb, p, tol), fb, csb, p))

def bd_or_in(+m: U64) -> Bool:
  Bool.or(U64.is_eq(m, 1u64), U64.is_eq(m, 3u64))

def smp_rank(+m: U64) -> U64:
  +ma = U64.div(m, 4u64)
  +mb = U64.mod(m, 4u64)
  Bool.pick(U64, Bool.and(U64.is_eq(ma, 1u64), U64.is_eq(mb, 1u64)), 11u64,
    Bool.pick(U64, Bool.or(U64.is_eq(ma, 0u64), U64.is_eq(mb, 0u64)), 10u64,
      Bool.pick(U64, Bool.and(bd_or_in(ma), bd_or_in(mb)), 0u64, 2u64)))

def st_worse(+a: U64, +b: U64) -> U64:
  Bool.pick(U64, Bool.or(U64.is_eq(a, 11u64), U64.is_eq(b, 11u64)), 11u64,
    Bool.pick(U64, Bool.or(U64.is_eq(a, 2u64), U64.is_eq(b, 2u64)), 2u64,
      Bool.pick(U64, Bool.or(U64.is_eq(a, 10u64), U64.is_eq(b, 10u64)), 10u64, 0u64)))

def smp_st(+m: U64, +st: U64) -> U64:
  st_worse(smp_rank(m), st)

def smp_fin(+st: U64) -> U64:
  Bool.pick(U64, U64.is_eq(st, 10u64), 0u64, Bool.pick(U64, U64.is_eq(st, 11u64), 1u64, st))

def smp_go(ps: List<&2, List<&2, I.I>>, done: Bool, +st: U64, +fa: SO.Fd, +fb: SO.Fd, +csa: List<&2, Eg>, +csb: List<&2, Eg>, +tol: F64) -> U64:
  match ps:
    case []: smp_fin(st)
    case +p <> t:
      match done:
        case True{}: smp_fin(st)
        case False{}:
          +s2 = smp_st(m2(fa, fb, csa, csb, p, tol), st)
          smp_go(t, U64.is_eq(s2, 11u64), s2, fa, fb, csa, csb, tol)

def es_share(xs: List<&2, Nat>, +ys: List<&2, Nat>) -> Bool:
  match xs:
    case []: False{}
    case h <> t: Bool.or(has(ys, h), es_share(t, ys))

def br_fi(b: SS.Br, +fa: SO.Fd, +fb: SO.Fd, +csa: List<&2, Eg>, +csb: List<&2, Eg>, +tol: F64, +ia: Nat, +ib: Nat,
    +adj: Bool) -> List<&2, SO.Fi>:
  SS.Br{closed, pts, ends} = b
  match closed:
    case False{}: []
    case True{}:
      +r = smp_go(pts, False{}, 0u64, fa, fb, csa, csb, tol)
      # Adjacent faces share an edge by construction, so a certified
      # branch with no trim-interior sample is the shared edge landing
      # on trim boundaries (membership conflates boundary with
      # uncertain), not a defect. Penetration (a trim-interior sample)
      # still fails for adjacent pairs, and non-adjacent pairs keep
      # the strict verdict. Residual: a real crossing hugging a trim
      # boundary within tolerance on an adjacent pair is forgiven.
      Bool.pick(List<&2, SO.Fi>, U64.is_eq(r, 0u64), [],
        Bool.pick(List<&2, SO.Fi>, U64.is_eq(r, 1u64), fi1("face-penetration", ia, ib),
          Bool.pick(List<&2, SO.Fi>, adj, [], fi1("face-face-uncertain", ia, ib))))

def brs_fi(bs: List<&2, SS.Br>, +fa: SO.Fd, +fb: SO.Fd, +csa: List<&2, Eg>, +csb: List<&2, Eg>, +tol: F64, +ia: Nat,
    +ib: Nat, +adj: Bool) -> List<&2, SO.Fi>:
  match bs:
    case []: []
    case b <> t: List.append(&2, SO.Fi, br_fi(b, fa, fb, csa, csb, tol, ia, ib, adj),
      brs_fi(t, fa, fb, csa, csb, tol, ia, ib, adj))

def un_one(b: List<&2, I.I>, +ia: Nat, +ib: Nat) -> List<&2, SO.Fi>:
  Bool.pick(List<&2, SO.Fi>, X.vfin(b), fi1("face-face-uncertain", ia, ib), fi1("face-face-uncertain", ia, ib))

def un_fi(us: List<&2, List<&2, I.I>>, +ia: Nat, +ib: Nat) -> List<&2, SO.Fi>:
  match us:
    case []: []
    case u <> t: List.append(&2, SO.Fi, un_one(u, ia, ib), un_fi(t, ia, ib))

def un_widen(+u: List<&2, I.I>, +tol: F64) -> List<&2, I.I>:
  match u:
    case []: []
    case +x <> t: I.iwiden(x, tol) <> un_widen(t, tol)

def un_seg_go(ts: List<&2, F64>, +a: F64, +u: List<&2, I.I>, +c: R.Cv) -> Bool:
  match ts:
    case []: False{}
    case +b <> rest2: Bool.or(Bool.not(X.vdisj(u, R.cv_box(c, I.I{a, b}))), un_seg_go(rest2, b, u, c))

def un_seg(ts: List<&2, F64>, +u: List<&2, I.I>, +c: R.Cv) -> Bool:
  match ts:
    case []: False{}
    case +a <> rest: un_seg_go(rest, a, u, c)

def un_near(+u: List<&2, I.I>, cs: List<&2, R.Cv>, +tol: F64) -> Bool:
  match cs:
    case []: False{}
    case +c <> t:
      Bool.or(un_seg([0.0f64, 0.125f64, 0.25f64, 0.375f64, 0.5f64, 0.625f64, 0.75f64, 0.875f64, 1.0f64],
        un_widen(u, tol), c), un_near(u, t, tol))

def sh_cvs(xs: List<&2, Nat>, +ys: List<&2, Nat>, +te: B.Tb<&2, Eg>) -> List<&2, R.Cv>:
  match xs:
    case []: []
    case +h <> t:
      List.append(&2, R.Cv, Bool.pick(List<&2, R.Cv>, has(ys, h),
        [eg_c_of(B.tb_get(Eg, te, U32.from_nat(h)))], []), sh_cvs(t, ys, te))

def un_one_a(+u: List<&2, I.I>, +cvs: List<&2, R.Cv>, +tol: F64, +ia: Nat, +ib: Nat, +adj: Bool) -> List<&2, SO.Fi>:
  Bool.pick(List<&2, SO.Fi>, Bool.and(adj, un_near(u, cvs, tol)), [], fi1("face-face-uncertain", ia, ib))

def un_fi_a(us: List<&2, List<&2, I.I>>, +cvs: List<&2, R.Cv>, +tol: F64, +ia: Nat, +ib: Nat,
    +adj: Bool) -> List<&2, SO.Fi>:
  match us:
    case []: []
    case u <> t: List.append(&2, SO.Fi, un_one_a(u, cvs, tol, ia, ib, adj), un_fi_a(t, cvs, tol, ia, ib, adj))

def ss_fi(r: Y.Sr, +fa: SO.Fd, +fb: SO.Fd, +csa: List<&2, Eg>, +csb: List<&2, Eg>, +tol: F64, +ia: Nat, +ib: Nat,
    +adj: Bool, +shc: List<&2, R.Cv>) -> List<&2, SO.Fi>:
  Y.Sr{ss, k, co} = r
  SS.Ss{ok, brs, un} = ss
  # Adjacent same-solid faces: uncertain tracer boxes hugging a shared
  # edge are the boundary-hugging shared intersection the subdivision
  # cannot resolve, not a defect; boxes away from every shared edge
  # still fail. Residual: a real crossing within tolerance of a
  # shared edge on an adjacent pair is forgiven.
  # Bicubic-involved traces (k != 0) report branches and boxes in
  # tracer coordinates the trim-membership tests cannot examine, so a
  # strict verdict is impossible; adjacent pairs are forgiven (their
  # shared edge explains the intersection) while non-adjacent pairs
  # keep failing closed. Mapping tracer coordinates back to world
  # coordinates would let these pairs take the strict path (C11).
  Bool.pick(List<&2, SO.Fi>, U64.is_eq(k, 0u64),
    Bool.pick(List<&2, SO.Fi>, ok,
      first(List.append(&2, SO.Fi, brs_fi(brs, fa, fb, csa, csb, tol, ia, ib, adj),
        un_fi_a(un, shc, tol, ia, ib, adj))),
      fi1("face-face-uncertain", ia, ib)),
    Bool.pick(List<&2, SO.Fi>, adj, [], fi1("face-face-uncertain", ia, ib)))

# Exact cross-solid sphere/sphere tangent predicate (F5/F18): the
# subdivision tracer degenerates on tangent spheres (singular
# Jacobian, unresolvable micro-boxes), so decide tangency exactly
# from center distance vs radii with intervals. External band
# (d^2 overlaps (r1+r2)^2) and internal band (d^2 overlaps
# (r1-r2)^2) with the tangent point on both trims is contact;
# certified disjoint/nested skips the tracer; the certified overlap
# band falls through to the tracer (non-degenerate circle, decided
# by sampling). Same-solid pairs always fall through: tangent
# shells in one solid are pinched and must fail. A micro-overlap
# inside the tangency band reads as contact (below resolution).
def ff_iv_overlap(+a: I.I, +b: I.I) -> Bool:
  Bool.not(Bool.or(F64.is_lt(I.i_hi(a), I.i_lo(b)), F64.is_lt(I.i_hi(b), I.i_lo(a))))

def ff_sph_mem(+t: List<&2, I.I>, +fa: SO.Fd, +fb: SO.Fd, +ia: Nat, +ib: Nat) -> Maybe<&2, List<&2, SO.Fi>>:
  +m1 = Mm.member(SO.fd_fc(fa), t, SO.fd_im(fa))
  +m2 = Mm.member(SO.fd_fc(fb), t, SO.fd_im(fb))
  Bool.pick(Maybe<&2, List<&2, SO.Fi>>, Bool.or(U64.is_eq(m1, 0u64), U64.is_eq(m2, 0u64)),
    Some{[]}, Some{fi1("contact-face-face", ia, ib)})

def ff_sph_tan(+c1: List<&2, I.I>, +r1: I.I, +c2: List<&2, I.I>, +r2: I.I, +fa: SO.Fd, +fb: SO.Fd, +ia: Nat,
    +ib: Nat) -> Maybe<&2, List<&2, SO.Fi>>:
  +u = X.vsub(c2, c1)
  +n = I.isqrt(X.vdot(u, u))
  Bool.pick(Maybe<&2, List<&2, SO.Fi>>, F64.is_le(I.i_lo(n), 0.0f64), None{},
    ff_sph_mem(X.vadd(c1, Mm.vs(I.idiv(r1, n), u)), fa, fb, ia, ib))

def ff_sph_ss(+c1: List<&2, I.I>, +r1: I.I, +c2: List<&2, I.I>, +r2: I.I, +fa: SO.Fd, +fb: SO.Fd, +ia: Nat,
    +ib: Nat) -> Maybe<&2, List<&2, SO.Fi>>:
  +d2 = X.vdot(X.vsub(c2, c1), X.vsub(c2, c1))
  +rss = I.isq(I.iadd(r1, r2))
  +rdd = I.isq(I.isub(r1, r2))
  Bool.pick(Maybe<&2, List<&2, SO.Fi>>, Bool.or(ff_iv_overlap(d2, rss), ff_iv_overlap(d2, rdd)),
    ff_sph_tan(c1, r1, c2, r2, fa, fb, ia, ib),
    Bool.pick(Maybe<&2, List<&2, SO.Fi>>, Bool.or(F64.is_lt(I.i_hi(d2), I.i_lo(rdd)),
      F64.is_lt(I.i_hi(rss), I.i_lo(d2))), Some{[]}, None{}))

def ff_sph_go(a: M.Im, b: M.Im, +fa: SO.Fd, +fb: SO.Fd, +ia: Nat, +ib: Nat) -> Maybe<&2, List<&2, SO.Fi>>:
  match a:
    case M.M_sp{+c1, +r1}:
      match b:
        case M.M_sp{+c2, +r2}: ff_sph_ss(c1, r1, c2, r2, fa, fb, ia, ib)
        case _: None{}
    case _: None{}

def ff_sph(+cross: Bool, +fa: SO.Fd, +fb: SO.Fd, +ia: Nat, +ib: Nat) -> Maybe<&2, List<&2, SO.Fi>>:
  match cross:
    case False{}: None{}
    case True{}: ff_sph_go(SO.fd_im(fa), SO.fd_im(fb), fa, fb, ia, ib)

def pad(+b: List<&2, I.I>) -> List<&2, I.I>:
  wid(b, F64.mul(F64.add(X.vwid(b), 1.0f64), 0.0009765625f64))

def ff_or_tr(m: Maybe<&2, List<&2, SO.Fi>>, +fa: SO.Fd, +fb: SO.Fd, +x: Fg, +y: Fg, +te: B.Tb<&2, Eg>,
    +tol: F64, +ia: Nat, +ib: Nat) -> List<&2, SO.Fi>:
  match m:
    case Some{+v}: v
    case None{}:
      +r = Y.inter_ss(SO.fd_g(fa), SO.fd_g(fb), pad(X.vmeet(SO.fd_bx(fa), SO.fd_bx(fb))))
      +csa = all_cvs(fg_es(x), te)
      +csb = all_cvs(fg_es(y), te)
      +exa = fg_es(x)
      +exb = fg_es(y)
      ss_fi(r, fa, fb, csa, csb, tol, ia, ib, es_share(exa, exb), sh_cvs(exa, exb, te))

def frame(+n: List<&2, I.I>) -> List<&2, List<&2, I.I>>:
  +m = SO.snap(n)
  +x = X.imag(X.vn(m, 0n))
  +y = X.imag(X.vn(m, 1n))
  +z = X.imag(X.vn(m, 2n))
  +e = Bool.pick(List<&2, I.I>, Bool.and(F64.is_le(x, y), F64.is_le(x, z)), [I.ipt(1.0f64), I.ipt(0.0f64), I.ipt(0.0f64)],
    Bool.pick(List<&2, I.I>, F64.is_le(y, z), [I.ipt(0.0f64), I.ipt(1.0f64), I.ipt(0.0f64)], [I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(1.0f64)]))
  +u = SO.unit(M.cross(n, e))
  [u, SO.unit(M.cross(SO.unit(n), u))]

def trig() -> List<&2, List<&2, F64>>:
  [[1.0f64, 0.0f64], [0.7071067811865476f64, 0.7071067811865476f64], [0.0f64, 1.0f64], [F64.neg(0.7071067811865476f64), 0.7071067811865476f64],
    [F64.neg(1.0f64), 0.0f64], [F64.neg(0.7071067811865476f64), F64.neg(0.7071067811865476f64)], [0.0f64, F64.neg(1.0f64)], [0.7071067811865476f64, F64.neg(0.7071067811865476f64)]]

def cpts(ts: List<&2, List<&2, F64>>, +c: List<&2, I.I>, +r: I.I, +u: List<&2, I.I>, +v: List<&2, I.I>) -> List<&2, List<&2, I.I>>:
  match ts:
    case []: []
    case +t <> rest:
      +cs = I.iwiden(I.ipt(X.fn_(t, 0n)), 2.220446049250313e-16f64)
      +sn = I.iwiden(I.ipt(X.fn_(t, 1n)), 2.220446049250313e-16f64)
      X.vadd(c, Mm.vs(r, X.vadd(Mm.vs(cs, u), Mm.vs(sn, v)))) <> cpts(rest, c, r, u, v)

def circ_pts(+c: List<&2, I.I>, +r: I.I, +n: List<&2, I.I>) -> List<&2, List<&2, I.I>>:
  +f = frame(n)
  cpts(trig(), c, r, hd(f), hd(drop_n(1n, f)))

def axial(+o: List<&2, I.I>, +a: List<&2, I.I>, +op: List<&2, I.I>) -> List<&2, I.I>:
  +u = SO.unit(a)
  X.vadd(o, Mm.vs(X.vdot(u, X.vsub(op, o)), u))

def hgt(+o: List<&2, I.I>, +a: List<&2, I.I>, +op: List<&2, I.I>) -> I.I:
  X.vdot(SO.unit(a), X.vsub(op, o))

def root0(+w: I.I) -> I.I:
  I.isqrt(X.iof(F64.max(I.i_lo(w), 0.0f64), F64.max(I.i_hi(w), 0.0f64)))

def circs(+op: List<&2, I.I>, +n: List<&2, I.I>, s: M.Im) -> List<&2, List<&2, I.I>>:
  match s:
    case M.M_cy{+o, +a, r}: circ_pts(axial(o, a, op), r, n)
    case M.M_co{+o, +a, +k}:
      +h = hgt(o, a, op)
      Bool.pick(List<&2, List<&2, I.I>>, X.ineg_c(h), [], circ_pts(axial(o, a, op), I.imul(k, h), n))
    case M.M_sp{+c, +r}:
      +nu = SO.unit(n)
      +d = X.vdot(nu, X.vsub(c, op))
      +w = I.isub(I.isq(r), I.isq(d))
      Bool.pick(List<&2, List<&2, I.I>>, X.ineg_c(w), [], circ_pts(X.vsub(c, Mm.vs(d, nu)), root0(w), n))
    case M.M_to{+o, +a, +bigr, +r}:
      +h = hgt(o, a, op)
      +w = I.isub(I.isq(r), I.isq(h))
      +c = axial(o, a, op)
      +q = root0(w)
      Bool.pick(List<&2, List<&2, I.I>>, X.ineg_c(w), [], List.append(&2, List<&2, I.I>, circ_pts(c, I.iadd(bigr, q), n), circ_pts(c, I.isub(bigr, q), n)))
    case _: []

def pl_on(s: M.Im) -> List<&2, I.I>:
  match s:
    case M.M_pl{o, n}: o
    case _: []

def pl_nv(s: M.Im) -> List<&2, I.I>:
  match s:
    case M.M_pl{o, n}: n
    case _: []

def circ_fi(+pl: SO.Fd, +ot: SO.Fd, +fa: SO.Fd, +fb: SO.Fd, +csa: List<&2, Eg>, +csb: List<&2, Eg>, +tol: F64, +ia: Nat, +ib: Nat) -> List<&2, SO.Fi>:
  +pi = SO.fd_im(pl)
  +ps = circs(pl_on(pi), pl_nv(pi), SO.fd_im(ot))
  +r = smp_go(ps, False{}, 0u64, fa, fb, csa, csb, tol)
  Bool.pick(List<&2, SO.Fi>, U64.is_eq(r, 0u64), [], fi1(Bool.pick(String, U64.is_eq(r, 1u64), "face-penetration", "face-face-uncertain"), ia, ib))

def ff_go(k: U64, +x: Fg, +y: Fg, +te: B.Tb<&2, Eg>, +ia: Nat, +ib: Nat, +tol: F64, +cross: Bool) -> List<&2, SO.Fi>:
  match k:
    case 0u64: []
    case 1u64: ff_ov_x(fg_fd(x), fg_fd(y), ia, ib, cross)
    case 3u64:
      +fa = fg_fd(x)
      +fb = fg_fd(y)
      circ_fi(fa, fb, fa, fb, all_cvs(fg_es(x), te), all_cvs(fg_es(y), te), tol, ia, ib)
    case 4u64:
      +fa = fg_fd(x)
      +fb = fg_fd(y)
      circ_fi(fb, fa, fa, fb, all_cvs(fg_es(x), te), all_cvs(fg_es(y), te), tol, ia, ib)
    case _:
      +fa = fg_fd(x)
      +fb = fg_fd(y)
      ff_or_tr(ff_sph(cross, fa, fb, ia, ib), fa, fb, x, y, te, tol, ia, ib)

def ff(+x: Fg, +y: Fg, +te: B.Tb<&2, Eg>, +ia: Nat, +ib: Nat, +tol: F64, +cross: Bool) -> List<&2, SO.Fi>:
  ff_go(ff_code(SO.fd_g(fg_fd(x)), SO.fd_g(fg_fd(y))), x, y, te, ia, ib, tol, cross)

def chk_ee(+a: Nat, +b: Nat, +te: B.Tb<&2, Eg>, +tol: F64, +sfs: B.Tb<&2, List<&2, SO.Fd>>) -> Fs:
  +x = B.tb_get(Eg, te, U32.from_nat(a))
  +y = B.tb_get(Eg, te, U32.from_nat(b))
  Fs{ee(x, y, a, b, tol, Bool.not(Nat.is_eq(eg_so(x), eg_so(y))), sfs)}

def chk_ef(+a: Nat, +b: Nat, +te: B.Tb<&2, Eg>, +tf: B.Tb<&2, Fg>, +tef: B.Tb<&2, List<&2, Nat>>, +tol: F64,
    +sfs: B.Tb<&2, List<&2, SO.Fd>>) -> Fs:
  +x = B.tb_get(Eg, te, U32.from_nat(a))
  +f = B.tb_get(Fg, tf, U32.from_nat(b))
  Fs{ef(x, f, B.tb_get(List<&2, Nat>, tef, U32.from_nat(a)), tf, a, b, tol,
    Bool.not(Nat.is_eq(eg_so(x), fg_so(f))), B.tb_get(List<&2, SO.Fd>, sfs, U32.from_nat(fg_so(f))))}

def chk_ff(+a: Nat, +b: Nat, +tf: B.Tb<&2, Fg>, +te: B.Tb<&2, Eg>, +tol: F64) -> Fs:
  +x = B.tb_get(Fg, tf, U32.from_nat(a))
  +y = B.tb_get(Fg, tf, U32.from_nat(b))
  Fs{ff(x, y, te, a, b, tol, Bool.not(Nat.is_eq(fg_so(x), fg_so(y))))}

def chk_k(k: U64, +a: Nat, +b: Nat, +te: B.Tb<&2, Eg>, +tf: B.Tb<&2, Fg>, +tef: B.Tb<&2, List<&2, Nat>>, +tol: F64,
    +sfs: B.Tb<&2, List<&2, SO.Fd>>) -> Fs:
  match k:
    case 0u64: chk_ee(a, b, te, tol, sfs)
    case 1u64: chk_ef(a, b, te, tf, tef, tol, sfs)
    case _: chk_ff(a, b, tf, te, tol)

def chk(c: Cx, p: Pr) -> Fs:
  Cx{te, tf, tef, tol, ns, sfs} = c
  Pr{k, a, b} = p
  chk_k(k, a, b, te, tf, tef, tol, sfs)

def fs_cat(xs: List<&2, Fs>) -> List<&2, SO.Fi>:
  match xs:
    case []: []
    case x <> t:
      Fs{f} = x
      List.append(&2, SO.Fi, f, fs_cat(t))

def un_es(es: List<&2, Eg>, +i: Nat) -> List<&2, SO.Fi>:
  match es:
    case []: []
    case +e <> t:
      +rest = un_es(t, Nat.add(i, 1n))
      Bool.pick(List<&2, SO.Fi>, U64.is_eq(eg_u(e), 2u64), SO.Fi{"edge-check-unsupported", i, i} <> rest, rest)

def un_fs(fs: List<&2, Fg>, +i: Nat) -> List<&2, SO.Fi>:
  match fs:
    case []: []
    case +f <> t:
      +rest = un_fs(t, Nat.add(i, 1n))
      +d = fg_fd(f)
      Bool.pick(List<&2, SO.Fi>, Bool.and(SO.fd_ok(d), Nat.is_eq(List.length(&2, I.I, SO.fd_bx(d)), 3n)), rest, SO.Fi{"face-check-unsupported", i, i} <> rest)

def tol_of(+bb: List<&2, I.I>) -> F64:
  F64.mul(F64.add(X.vwid(bb), 1.0f64), 9.313225746154785e-10f64)

def eg_dflt(+ns: Nat) -> Eg:
  Eg{[], G.Dom{0.0f64, 1.0f64}, 0n, 0n, [], [], cv0(), [], 1u64, ns}

def fd_dflt() -> SO.Fd:
  SO.fd_dflt()

def fg_dflt(+ns: Nat) -> Fg:
  Fg{fd_dflt(), [], [], ns}

def es_ef(es: List<&2, Nat>, +f: Nat, +acc: List<&2, Ef>) -> List<&2, Ef>:
  match es:
    case []: acc
    case e <> t: es_ef(t, f, Ef{e, f} <> acc)

def fg_efs(fs: List<&2, Fg>, +i: Nat, +acc: List<&2, Ef>) -> List<&2, Ef>:
  match fs:
    case []: acc
    case +f <> t: fg_efs(t, Nat.add(i, 1n), es_ef(fg_es(f), i, acc))

def ef_add(xs: List<&2, Ef>, +tb: B.Tb<&2, List<&2, Nat>>) -> B.Tb<&2, List<&2, Nat>>:
  match xs:
    case []: tb
    case x <> t:
      Ef{+e, f} = x
      +k = U32.from_nat(e)
      ef_add(t, B.tb_set(List<&2, Nat>, tb, k, f <> B.tb_get(List<&2, Nat>, tb, k)))

def tef_of(+n: Nat, +fgs: List<&2, Fg>) -> B.Tb<&2, List<&2, Nat>>:
  ef_add(fg_efs(fgs, 0n, []), B.tb_of(List<&2, Nat>, B.rep_n(List<&2, Nat>, n, []), []))

def eg_tag(e: Eg, +so: Nat) -> Eg:
  Eg{g, d, a, b, pa, pb, c, bx, u, s} = e
  Eg{g, d, a, b, pa, pb, c, bx, u, so}

def eg_so_of(fs: List<&2, Nat>, +tf: B.Tb<&2, Fg>, +nso: Nat) -> Nat:
  match fs:
    case []: nso
    case f <> t: fg_so(B.tb_get(Fg, tf, U32.from_nat(f)))

def egs_tag(es: List<&2, Eg>, +tef: B.Tb<&2, List<&2, Nat>>, +tf: B.Tb<&2, Fg>, +nso: Nat, +at: Nat) -> List<&2, Eg>:
  match es:
    case []: []
    case e <> t:
      eg_tag(e, eg_so_of(B.tb_get(List<&2, Nat>, tef, U32.from_nat(at)), tf, nso)) <>
        egs_tag(t, tef, tf, nso, Nat.add(at, 1n))

# Per-solid face-descriptor rows for the F5 piercing discriminator: row
# `so` holds the Fds of solid `so` (row `nso` is the empty default).
def fds_of_so(fs: List<&2, Fg>, +so: Nat) -> List<&2, SO.Fd>:
  match fs:
    case []: []
    case +f <> t:
      +rest = fds_of_so(t, so)
      Bool.pick(List<&2, SO.Fd>, Nat.is_eq(fg_so(f), so), fg_fd(f) <> rest, rest)

def sfs_go(+fgs: List<&2, Fg>, rem: Nat, +at: Nat) -> List<&2, List<&2, SO.Fd>>:
  match rem:
    case 0n: []
    case 1n+m: fds_of_so(fgs, at) <> sfs_go(fgs, m, Nat.add(at, 1n))

def sfs_of(+fgs: List<&2, Fg>, +nso: Nat) -> B.Tb<&2, List<&2, SO.Fd>>:
  B.tb_of(List<&2, SO.Fd>, sfs_go(fgs, Nat.add(nso, 1n), 0n), [])

def mk_cx(+egs: List<&2, Eg>, +fgs: List<&2, Fg>, +tol: F64, +nso: Nat) -> Cx:
  +tf = B.tb_of(Fg, fgs, fg_dflt(nso))
  +tef = tef_of(List.length(&2, Eg, egs), fgs)
  Cx{B.tb_of(Eg, egs_tag(egs, tef, tf, nso, 0n), eg_dflt(nso)), tf, tef, tol, nso, sfs_of(fgs, nso)}

def its_of(+egs: List<&2, Eg>, +fgs: List<&2, Fg>) -> List<&2, It>:
  it_so(B.msort(~It, ~it_cmp, List.append(&2, It, ed_its(egs, 0n), fa_its(fgs, 0n))))

def run_prs(+cx: Cx, +prs: List<&2, Pr>) -> List<&2, SO.Fi>:
  fs_cat(B.pmap_g(~Pr, ~Cx, ~Fs, ~chk, 2, cx, prs))

def emb_go(+egs: List<&2, Eg>, +fgs: List<&2, Fg>, +tol: F64, +nso: Nat) -> List<&2, SO.Fi>:
  List.append(&2, SO.Fi, List.append(&2, SO.Fi, un_es(egs, 0n), un_fs(fgs, 0n)),
    run_prs(mk_cx(egs, fgs, tol, nso), sweep(its_of(egs, fgs))))

def emb_fi(+b: Ty.Brep, +fds: List<&2, SO.Fd>) -> List<&2, SO.Fi>:
  +x = Ty.ix_of(b)
  emb_go(egs_go(Ty.brep_es(b), Ty.ix_tv(x)), shs_fg(Ty.brep_shs(b), x, fds, Ty.shmap_of(b), 0n),
    tol_of(SO.bbox(fds, [])), List.length(&2, Ty.Solid, Ty.brep_sos(b)))
