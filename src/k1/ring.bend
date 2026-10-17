import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c06/iv.bend as I

def march_ax(+a: U64, +b: U64) -> U64:
  U64.sub(3u64, U64.add(a, b))

def other_ax(+ax: U64, +m: U64) -> U64:
  U64.sub(3u64, U64.add(ax, m))

def pcomp(+p: V.Point, +ax: U64) -> F64:
  Bool.pick(F64, U64.is_eq(ax, 0u64), V.pt_x(p),
    Bool.pick(F64, U64.is_eq(ax, 1u64), V.pt_y(p), V.pt_z(p)))

type RC is Data:
  RC{ ax: U64, o: V.Point, r: F64 }

def rc_ax(+c: RC) -> U64:
  RC{ax, o, r} = c
  ax

def rc_o(+c: RC) -> V.Point:
  RC{ax, o, r} = c
  o

def rc_r(+c: RC) -> F64:
  RC{ax, o, r} = c
  r

def rc_cm(+c: RC, +m: U64) -> F64:
  pcomp(rc_o(c), m)

def rc_cw(+c: RC, +m: U64) -> F64:
  pcomp(rc_o(c), other_ax(rc_ax(c), m))

def rc_branch(+c: RC, +m: U64, +y: F64, +s: Bool) -> F64:
  +u = F64.sub(y, rc_cm(c, m))
  +q = F64.sub(F64.mul(rc_r(c), rc_r(c)), F64.mul(u, u))
  +r = F64.sqrt(Bool.pick(F64, F64.is_lt(q, 0.0f64), 0.0f64, q))
  F64.add(rc_cw(c, m), Bool.pick(F64, s, F64.neg(r), r))

def rc_dom_lo(+c: RC, +m: U64) -> F64:
  F64.sub(rc_cm(c, m), rc_r(c))

def rc_dom_hi(+c: RC, +m: U64) -> F64:
  F64.add(rc_cm(c, m), rc_r(c))

def rx_overlap(+a: RC, +b: RC, +m: U64) -> V.Vec2:
  +lo = Bool.pick(F64, F64.is_lt(rc_dom_lo(a, m), rc_dom_lo(b, m)), rc_dom_lo(b, m), rc_dom_lo(a, m))
  +hi = Bool.pick(F64, F64.is_lt(rc_dom_hi(a, m), rc_dom_hi(b, m)), rc_dom_hi(a, m), rc_dom_hi(b, m))
  V.V2{lo, hi}

def ifinite(+a: I.I) -> Bool:
  Bool.and(T.is_finite(I.i_lo(a)), T.is_finite(I.i_hi(a)))

def rx_branch_i(+c: RC, +m: U64, +y: I.I, +s: Bool) -> I.I:
  +u = I.isub(y, I.ipt(rc_cm(c, m)))
  +q = I.isub(I.isq(I.ipt(rc_r(c))), I.isq(u))
  +r = I.isqrt(q)
  I.iadd(I.ipt(rc_cw(c, m)), I.iscale(r, Bool.pick(F64, s, F64.neg(1.0f64), 1.0f64)))

def rx_deriv(+c: RC, +m: U64, +y: I.I, +s: Bool) -> I.I:
  +u = I.isub(y, I.ipt(rc_cm(c, m)))
  +q = I.isub(I.isq(I.ipt(rc_r(c))), I.isq(u))
  +sg = Bool.pick(F64, s, F64.neg(1.0f64), 1.0f64)
  I.idiv(I.iscale(u, F64.neg(sg)), I.isqrt(q))

def rx_deriv2(+c: RC, +m: U64, +y: I.I, +s: Bool) -> I.I:
  +u = I.isub(y, I.ipt(rc_cm(c, m)))
  +q = I.isub(I.isq(I.ipt(rc_r(c))), I.isq(u))
  +sg = Bool.pick(F64, s, F64.neg(1.0f64), 1.0f64)
  +s3 = I.imul(I.isqrt(q), q)
  I.idiv(I.iscale(I.isq(I.ipt(rc_r(c))), F64.neg(sg)), s3)

def rx_kappa(+a: RC, +b: RC, +m: U64, +y: I.I, +sa: Bool, +sb: Bool) -> I.I:
  +pa = rx_deriv(a, m, y, sa)
  +qa = rx_deriv(b, m, y, sb)
  +ppa = rx_deriv2(a, m, y, sa)
  +qqa = rx_deriv2(b, m, y, sb)
  +cr = I.isub(I.imul(pa, qqa), I.imul(qa, ppa))
  +n2 = I.iadd(I.isq(cr), I.iadd(I.isq(ppa), I.isq(qqa)))
  +d1 = I.iadd(I.ipt(1.0f64), I.iadd(I.isq(pa), I.isq(qa)))
  I.isqrt(I.idiv(n2, I.imul(d1, I.isq(d1))))

def rx_ii(+lo: F64, +hi: F64) -> I.I:
  I.I{lo, hi}

def rx_kmax(+a: RC, +b: RC, +m: U64, +y0: F64, +y1: F64, +sa: Bool, +sb: Bool) -> F64:
  +k = rx_kappa(a, b, m, rx_ii(y0, y1), sa, sb)
  Bool.pick(F64, Bool.and(ifinite(k), F64.is_le(0.0f64, I.i_hi(k))), I.i_hi(k),
    F64.div(1.0f64, 0.0f64))

def rx_chord(+p0: V.Point, +p1: V.Point) -> I.I:
  +dx = I.isub(I.ipt(V.pt_x(p1)), I.ipt(V.pt_x(p0)))
  +dy = I.isub(I.ipt(V.pt_y(p1)), I.ipt(V.pt_y(p0)))
  +dz = I.isub(I.ipt(V.pt_z(p1)), I.ipt(V.pt_z(p0)))
  I.isqrt(I.iadd(I.isq(dx), I.iadd(I.isq(dy), I.isq(dz))))

def rx_boxdiag(+a: RC, +b: RC, +m: U64, +y0: F64, +y1: F64, +sa: Bool, +sb: Bool) -> F64:
  +y = rx_ii(y0, y1)
  +xa = rx_branch_i(a, m, y, sa)
  +xb = rx_branch_i(b, m, y, sb)
  +wxa = I.i_hi(I.isub(xa, xa))
  +wxb = I.i_hi(I.isub(xb, xb))
  +wy = I.i_hi(I.isub(I.ipt(y1), I.ipt(y0)))
  +d2 = F64.add(F64.mul(wxa, wxa), F64.add(F64.mul(wxb, wxb), F64.mul(wy, wy)))
  I.up(F64.sqrt(d2))

def rx_cmax(+a: RC, +b: RC, +m: U64, +y0: F64, +y1: F64, +sa: Bool, +sb: Bool, +pad: F64) -> F64:
  +y = rx_ii(y0, y1)
  +xa = I.iwiden(rx_branch_i(a, m, y, sa), pad)
  +xb = I.iwiden(rx_branch_i(b, m, y, sb), pad)
  +yw = I.iwiden(y, pad)
  +mx = F64.max(F64.abs(I.i_lo(xa)), F64.abs(I.i_hi(xa)))
  +mm = F64.max(F64.abs(I.i_lo(xb)), F64.abs(I.i_hi(xb)))
  +my = F64.max(F64.abs(I.i_lo(yw)), F64.abs(I.i_hi(yw)))
  F64.max(mx, F64.max(mm, my))

def rx_seg_sl(+h: F64, +dl: F64, +cx: F64) -> V.Vec2:
  +rib = F64.add(F64.mul(h, dl), F64.mul(dl, dl))
  V.V2{F64.mul(cx, rib), rib}

def rx_jpad(+a: RC, +b: RC, +m: U64) -> F64:
  +rm = F64.max(rc_r(a), rc_r(b))
  +cm = F64.max(1.0f64, F64.max(F64.abs(rc_cm(a, m)), F64.abs(rc_cm(b, m))))
  +em = F64.mul(2.3e-16f64, cm)
  I.up(F64.mul(8.0f64, F64.sqrt(F64.mul(2.0f64, F64.mul(rm, em)))))

def rx_branch_j(+c: RC, +m: U64, +y: F64, +s: Bool, +isend: Bool) -> F64:
  match isend:
    case True{}: rc_cw(c, m)
    case False{}: rc_branch(c, m, y, s)

def rx_pt_j(+a: RC, +b: RC, +m: U64, +y: F64, +sa: Bool, +sb: Bool, +ia: Bool, +ib: Bool) -> V.Point:
  +wa = other_ax(rc_ax(a), m)
  +va = rx_branch_j(a, m, y, sa, ia)
  +vb = rx_branch_j(b, m, y, sb, ib)
  +x = Bool.pick(F64, U64.is_eq(m, 0u64), y, Bool.pick(F64, U64.is_eq(wa, 0u64), va, vb))
  +yy = Bool.pick(F64, U64.is_eq(m, 1u64), y, Bool.pick(F64, U64.is_eq(wa, 1u64), va, vb))
  +z = Bool.pick(F64, U64.is_eq(m, 2u64), y, Bool.pick(F64, U64.is_eq(wa, 2u64), va, vb))
  V.Pt{x, yy, z}

type RSEG is Data:
  RSEG{ a: V.Point, b: V.Point, slv: F64, sla: F64 }

def rseg_a(+r: RSEG) -> V.Point:
  RSEG{a, b, slv, sla} = r
  a

def rseg_b(+r: RSEG) -> V.Point:
  RSEG{a, b, slv, sla} = r
  b

def rseg_slv(+r: RSEG) -> F64:
  RSEG{a, b, slv, sla} = r
  slv

def rseg_sla(+r: RSEG) -> F64:
  RSEG{a, b, slv, sla} = r
  sla

type RSB is Data:
  RSB{ segs: List<&2, RSEG>, slv: F64, sla: F64, ok: Bool }

def rsb_segs(+r: RSB) -> List<&2, RSEG>:
  RSB{segs, slv, sla, ok} = r
  segs

def rsb_slv(+r: RSB) -> F64:
  RSB{segs, slv, sla, ok} = r
  slv

def rsb_sla(+r: RSB) -> F64:
  RSB{segs, slv, sla, ok} = r
  sla

def rsb_ok(+r: RSB) -> Bool:
  RSB{segs, slv, sla, ok} = r
  ok

def fmin2(+a: F64, +b: F64) -> F64:
  Bool.pick(F64, F64.is_lt(b, a), b, a)

def fmax2(+a: F64, +b: F64) -> F64:
  Bool.pick(F64, F64.is_lt(b, a), a, b)

type FS4 is Data:
  FS4{ a: F64, b: F64, c: F64, d: F64 }

def sort4(+a: F64, +b: F64, +c: F64, +d: F64) -> FS4:
  +l0 = fmin2(a, b)
  +h0 = fmax2(a, b)
  +l1 = fmin2(c, d)
  +h1 = fmax2(c, d)
  +l2 = fmin2(l0, l1)
  +h2 = fmax2(l0, l1)
  +l3 = fmin2(h0, h1)
  +h3 = fmax2(h0, h1)
  FS4{l2, fmin2(h2, l3), fmax2(h2, l3), h3}

type FSP is Data:
  FSP{ y: F64, dax: U64, dc: F64, hx: U64, hc: F64, r: F64, mt: Bool }

def rx_force_m(+dc: F64, +dax: U64, +hx: U64, +hc: F64, +r: F64) -> FSP:
  FSP{dc, dax, dc, hx, hc, r, True{}}

def rx_force_w(+c: RC, +m: U64, +dax: U64, +dc: F64, +hx: U64, +hc: F64, +r: F64,
    +plus: Bool) -> FSP:
  +dd = F64.sub(dc, rc_cw(c, m))
  +qq = F64.sub(F64.mul(rc_r(c), rc_r(c)), F64.mul(dd, dd))
  +rt = F64.sqrt(Bool.pick(F64, F64.is_lt(qq, 0.0f64), 0.0f64, qq))
  +y = F64.add(rc_cm(c, m), Bool.pick(F64, plus, rt, F64.neg(rt)))
  +valid = F64.is_le(0.0f64, qq)
  FSP{Bool.pick(F64, valid, y, F64.div(1.0f64, 0.0f64)), dax, dc, hx, hc, r, False{}}

def pt_eq3(+a: V.Point, +b: V.Point) -> Bool:
  Bool.and(F64.is_eq(V.pt_x(a), V.pt_x(b)),
    Bool.and(F64.is_eq(V.pt_y(a), V.pt_y(b)), F64.is_eq(V.pt_z(a), V.pt_z(b))))

type FCL is Data:
  FCL{ y: F64, adx: U64, adc: F64, ahx: U64, ahc: F64, ar: F64, ana: Bool, bdx: U64, bdc: F64,
    bhx: U64, bhc: F64, br: F64, bna: Bool }

def fcl_new(+e: FSP, +wab: Bool) -> FCL:
  FSP{y, dax, dc, hx, hc, r, mt} = e
  Bool.pick(FCL, wab, FCL{y, dax, dc, hx, hc, r, Bool.not(mt), 0u64, 0.0f64, 0u64, 0.0f64,
      0.0f64, False{}},
    FCL{y, 0u64, 0.0f64, 0u64, 0.0f64, 0.0f64, False{}, dax, dc, hx, hc, r, Bool.not(mt)})

def fcl_add(+c: FCL, +e: FSP, +wab: Bool) -> FCL:
  FCL{y, adx, adc, ahx, ahc, ar, ana, bdx, bdc, bhx, bhc, br, bna} = c
  FSP{ey, dax, dc, hx, hc, r, mt} = e
  +nv = Bool.pick(F64, mt, dc, y)
  Bool.pick(FCL, wab,
    FCL{nv, dax, dc, hx, hc, r, Bool.or(ana, Bool.not(mt)), bdx, bdc, bhx, bhc, br, bna},
    FCL{nv, adx, adc, ahx, ahc, ar, ana, dax, dc, hx, hc, r, Bool.or(bna, Bool.not(mt))})

def fsp_y(+e: FSP) -> F64:
  FSP{y, dax, dc, hx, hc, r, mt} = e
  y

def fcl_y(+c: FCL) -> F64:
  FCL{y, adx, adc, ahx, ahc, ar, ana, bdx, bdc, bhx, bhc, br, bna} = c
  y

def fcl_dummy() -> FCL:
  FCL{0.0f64, 0u64, 0.0f64, 0u64, 0.0f64, 0.0f64, False{}, 0u64, 0.0f64, 0u64, 0.0f64,
    0.0f64, False{}}

def fcl_fold_go(+cur: FCL, +has: Bool, +acc: List<&2, FCL>) -> List<&2, FCL>:
  Bool.pick(List<&2, FCL>, has, cur <> acc, acc)

def fcl_close_of(+t: List<&2, FSP>, +cur: FCL) -> Bool:
  match t:
    case []: False{}
    case +e2 <> +t2: F64.is_le(F64.abs(F64.sub(fsp_y(e2), fcl_y(cur))), 1.0e-12f64)

def fcl_lt_of(+bs: List<&2, FSP>, +ahead: FSP) -> Bool:
  match bs:
    case []: False{}
    case +b2 <> +u2: F64.is_lt(fsp_y(b2), fsp_y(ahead))

def fcl_lt_of2(+as: List<&2, FSP>, +bhead: FSP) -> Bool:
  match as:
    case []: False{}
    case +a2 <> +t2: F64.is_lt(fsp_y(bhead), fsp_y(a2))

def fcl_lt0(+as: List<&2, FSP>, +bs: List<&2, FSP>) -> Bool:
  match as:
    case []: False{}
    case +a <> +t:
      match bs:
        case []: False{}
        case +b <> +u: F64.is_lt(fsp_y(b), fsp_y(a))

def fcl_fold(+es: List<&2, FSP>, +ws: List<&2, Bool>, +cur: FCL, +has: Bool, +close: Bool,
    +acc: List<&2, FCL>) -> List<&2, FCL>:
  match es:
    case []: List.reverse(&2, FCL, fcl_fold_go(cur, has, acc))
    case +e <> +t:
      match ws:
        case []: List.reverse(&2, FCL, fcl_fold_go(cur, has, acc))
        case +w <> +u:
          match has:
            case False{}:
              +cn = fcl_new(e, w)
              fcl_fold(t, u, cn, True{}, fcl_close_of(t, cn), acc)
            case True{}:
              match close:
                case True{}:
                  +ca = fcl_add(cur, e, w)
                  fcl_fold(t, u, ca, True{}, fcl_close_of(t, ca), acc)
                case False{}:
                  +cn = fcl_new(e, w)
                  fcl_fold(t, u, cn, True{}, fcl_close_of(t, cn), cur <> acc)

type FSP2 is Data:
  FSP2{ es: List<&2, FSP>, ws: List<&2, Bool> }

def fsp2_es(+r: FSP2) -> List<&2, FSP>:
  FSP2{es, ws} = r
  es

def fsp2_ws(+r: FSP2) -> List<&2, Bool>:
  FSP2{es, ws} = r
  ws

def fcl_mg(+as: List<&2, FSP>, +bs: List<&2, FSP>, +lt: Bool, +es: List<&2, FSP>,
    +ws: List<&2, Bool>) -> FSP2:
  match as:
    case []:
      match bs:
        case []: FSP2{List.reverse(&2, FSP, es), List.reverse(&2, Bool, ws)}
        case +b <> +u: fcl_mg([], u, False{}, b <> es, False{} <> ws)
    case +a <> +t:
      match bs:
        case []: fcl_mg(t, [], False{}, a <> es, True{} <> ws)
        case +b <> +u:
          match lt:
            case True{}: fcl_mg(a <> t, u, fcl_lt_of(u, a), b <> es, False{} <> ws)
            case False{}: fcl_mg(t, b <> u, fcl_lt_of2(t, b), a <> es, True{} <> ws)

def fcl_merge(+as: List<&2, FSP>, +bs: List<&2, FSP>) -> List<&2, FCL>:
  +m = fcl_mg(as, bs, fcl_lt0(as, bs), [], [])
  fcl_fold(fsp2_es(m), fsp2_ws(m), fcl_dummy(), False{}, False{}, [])

def rx_wall_fc(+eqm: Bool, +c: RC, +m: U64, +dax: U64, +dc: F64, +hx: U64, +hc: F64,
    +r: F64) -> List<&2, FSP>:
  match eqm:
    case True{}: [rx_force_m(dc, dax, hx, hc, r)]
    case False{}:
      [rx_force_w(c, m, dax, dc, hx, hc, r, False{}),
        rx_force_w(c, m, dax, dc, hx, hc, r, True{})]

def rx_wall_forced(+c: RC, +m: U64, +dax: U64, +dc: F64, +hx: U64) -> List<&2, FSP>:
  rx_wall_fc(U64.is_eq(dax, m), c, m, dax, dc, hx, pcomp(rc_o(c), hx), rc_r(c))

def fcl_interior_go(+cs: List<&2, FCL>, +y0: F64, +y1: F64, +acc: List<&2, FCL>) -> List<&2, FCL>:
  match cs:
    case []: List.reverse(&2, FCL, acc)
    case +h <> +t:
      +y = fcl_y(h)
      +inn = Bool.and(F64.is_lt(y0, y), F64.is_lt(y, y1))
      fcl_interior_go(t, y0, y1, Bool.pick(List<&2, FCL>, inn, h <> acc, acc))

def pt_set(+p: V.Point, +ax: U64, +v: F64) -> V.Point:
  Bool.pick(V.Point, U64.is_eq(ax, 0u64), V.Pt{v, V.pt_y(p), V.pt_z(p)},
    Bool.pick(V.Point, U64.is_eq(ax, 1u64), V.Pt{V.pt_x(p), v, V.pt_z(p)},
      V.Pt{V.pt_x(p), V.pt_y(p), v}))

type RXV is Data:
  RXV{ p: V.Point, sd: F64 }

def rxv_p(+r: RXV) -> V.Point:
  RXV{p, sd} = r
  p

def rxv_sd(+r: RXV) -> F64:
  RXV{p, sd} = r
  sd

def rx_snap1(+p: V.Point, +dax: U64, +dc: F64, +hx: U64, +hc: F64, +r: F64,
    +jpad: F64) -> RXV:
  +d = pcomp(p, dax)
  +h = pcomp(p, hx)
  +th = F64.add(hc, Bool.pick(F64, F64.is_lt(h, hc), F64.neg(r), r))
  +md = F64.abs(F64.sub(d, dc))
  +mh = F64.abs(F64.sub(h, th))
  +nd = Bool.pick(F64, F64.is_le(md, jpad), dc, d)
  +nh = Bool.pick(F64, F64.is_le(mh, jpad), th, h)
  +mv = F64.max(Bool.pick(F64, F64.is_le(md, jpad), md, 0.0f64),
    Bool.pick(F64, F64.is_le(mh, jpad), mh, 0.0f64))
  RXV{pt_set(pt_set(p, dax, nd), hx, nh), mv}

def rx_snapc(+p: V.Point, +c: FCL, +jpad: F64) -> RXV:
  FCL{y, adx, adc, ahx, ahc, ar, ana, bdx, bdc, bhx, bhc, br, bna} = c
  +r1 = Bool.pick(RXV, ana, rx_snap1(p, adx, adc, ahx, ahc, ar, jpad), RXV{p, 0.0f64})
  Bool.pick(RXV, bna, rx_snap1(rxv_p(r1), bdx, bdc, bhx, bhc, br, jpad), r1)

def rx_snapm(+p: V.Point, +c: Maybe<&2, FCL>, +jpad: F64) -> RXV:
  match c:
    case None{}: RXV{p, 0.0f64}
    case Some{+v}: rx_snapc(p, v, jpad)

def rx_vspec(+a: RC, +b: RC, +m: U64, +y: F64, +sa: Bool, +sb: Bool, +ia: Bool, +ib: Bool,
    +sp: Maybe<&2, FCL>, +jpad: F64) -> RXV:
  rx_snapm(rx_pt_j(a, b, m, y, sa, sb, ia, ib), sp, jpad)

def rx_none() -> Maybe<&2, FCL>:
  None{}

def rx_emit_sl(+a: RC, +b: RC, +m: U64, +y0: F64, +y1: F64, +sa: Bool, +sb: Bool,
    +v0: RXV, +v1: RXV, +h: F64, +kap: F64, +fin: Bool, +jpad: F64) -> V.Vec2:
  +sdm = F64.max(rxv_sd(v0), rxv_sd(v1))
  +dl = F64.add(Bool.pick(F64, fin, F64.div(F64.mul(kap, F64.mul(h, h)), 8.0f64),
      F64.add(rx_boxdiag(a, b, m, y0, y1, sa, sb), jpad)), F64.add(jpad, sdm))
  +cx = rx_cmax(a, b, m, y0, y1, sa, sb, dl)
  +sl = rx_seg_sl(h, dl, cx)
  V.V2{I.up(V.v2_x(sl)), I.up(V.v2_y(sl))}

def rx_emit(+keep: Bool, +a: RC, +b: RC, +m: U64, +y0: F64, +y1: F64, +sa: Bool,
    +sb: Bool, +v0: RXV, +v1: RXV, +h: F64, +kap: F64, +fin: Bool, +jpad: F64,
    +acc: RSB) -> RSB:
  match keep:
    case True{}:
      +sl = rx_emit_sl(a, b, m, y0, y1, sa, sb, v0, v1, h, kap, fin, jpad)
      RSB{RSEG{rxv_p(v0), rxv_p(v1), V.v2_x(sl), V.v2_y(sl)} <> rsb_segs(acc),
        F64.add(rsb_slv(acc), V.v2_x(sl)), F64.add(rsb_sla(acc), V.v2_y(sl)), rsb_ok(acc)}
    case False{}:
      +sl = rx_emit_sl(a, b, m, y0, y1, sa, sb, v0, v1, h, kap, fin, jpad)
      RSB{rsb_segs(acc), F64.add(rsb_slv(acc), V.v2_x(sl)),
        F64.add(rsb_sla(acc), V.v2_y(sl)), rsb_ok(acc)}

type RXIN is Data:
  RXIN{ code: Nat, keep: Bool, v0: RXV, v1: RXV, h: F64, kap: F64, fin: Bool, ym: F64 }

def rx_bis_in(+a: RC, +b: RC, +m: U64, +y0: F64, +y1: F64, +sa: Bool, +sb: Bool, +ia0: Bool,
    +ib0: Bool, +ia1: Bool, +ib1: Bool, +s0: Maybe<&2, FCL>, +s1: Maybe<&2, FCL>, +hmax: F64,
    +jpad: F64, +eps: F64) -> RXIN:
  +v0 = rx_vspec(a, b, m, y0, sa, sb, ia0, ib0, s0, jpad)
  +v1 = rx_vspec(a, b, m, y1, sa, sb, ia1, ib1, s1, jpad)
  +h = I.i_hi(rx_chord(rxv_p(v0), rxv_p(v1)))
  +ym = F64.add(F64.mul(0.5f64, y0), F64.mul(0.5f64, y1))
  +stuck = Bool.or(F64.is_eq(ym, y0), F64.is_eq(ym, y1))
  +tiny = F64.is_le(h, F64.mul(hmax, 0.0625f64))
  +small = F64.is_le(h, hmax)
  +kap = rx_kmax(a, b, m, y0, y1, sa, sb)
  +fin = T.is_finite(kap)
  +emit = Bool.or(stuck, Bool.or(tiny, Bool.and(small, fin)))
  RXIN{Bool.pick(Nat, pt_eq3(rxv_p(v0), rxv_p(v1)), 0n, Bool.pick(Nat, emit, 1n, 3n)),
    F64.is_lt(eps, h), v0, v1, h, kap, fin, ym}

def rx_bis(+fuel: Nat, +a: RC, +b: RC, +m: U64, +y0: F64, +y1: F64, +sa: Bool, +sb: Bool,
    +ia0: Bool, +ib0: Bool, +ia1: Bool, +ib1: Bool, +s0: Maybe<&2, FCL>, +s1: Maybe<&2, FCL>,
    +hmax: F64, +jpad: F64, +eps: F64, +inp: RXIN, +acc: RSB) -> RSB:
  match fuel:
    case 0n:
      match inp:
        case RXIN{code, keep, v0, v1, h, kap, fin, ym}:
          match code:
            case 0n: acc
            case 1n: rx_emit(keep, a, b, m, y0, y1, sa, sb, v0, v1, h, kap, fin, jpad, acc)
            case _: RSB{rsb_segs(acc), rsb_slv(acc), rsb_sla(acc), False{}}
    case 1n+f:
      match inp:
        case RXIN{code, keep, v0, v1, h, kap, fin, ym}:
          match code:
            case 0n: acc
            case 1n: rx_emit(keep, a, b, m, y0, y1, sa, sb, v0, v1, h, kap, fin, jpad, acc)
            case _:
              +nn = rx_none()
              +r = rx_bis(f, a, b, m, ym, y1, sa, sb, False{}, False{}, ia1, ib1, nn, s1,
                hmax, jpad, eps,
                rx_bis_in(a, b, m, ym, y1, sa, sb, False{}, False{}, ia1, ib1, nn, s1,
                  hmax, jpad, eps), acc)
              rx_bis(f, a, b, m, y0, ym, sa, sb, ia0, ib0, False{}, False{}, s0, nn,
                hmax, jpad, eps,
                rx_bis_in(a, b, m, y0, ym, sa, sb, ia0, ib0, False{}, False{}, s0, nn, hmax,
                  jpad, eps), r)

def rx_branch_go(+cs: List<&2, FCL>, +a: RC, +b: RC, +m: U64, +sa: Bool, +sb: Bool,
    +y0: F64, +s0: Maybe<&2, FCL>, +ia0: Bool, +ib0: Bool, +y1: F64, +ia1: Bool, +ib1: Bool,
    +hmax: F64, +jpad: F64, +eps: F64, +acc: RSB) -> RSB:
  match cs:
    case []:
      rx_bis(28n, a, b, m, y0, y1, sa, sb, ia0, ib0, ia1, ib1, s0, None{}, hmax, jpad, eps,
        rx_bis_in(a, b, m, y0, y1, sa, sb, ia0, ib0, ia1, ib1, s0, None{}, hmax, jpad,
          eps), acc)
    case +c <> +t:
      +yc = fcl_y(c)
      +r = rx_branch_go(t, a, b, m, sa, sb, yc, Some{c}, False{}, False{}, y1, ia1, ib1,
        hmax, jpad, eps, acc)
      rx_bis(28n, a, b, m, y0, yc, sa, sb, ia0, ib0, False{}, False{}, s0, Some{c}, hmax,
        jpad, eps, rx_bis_in(a, b, m, y0, yc, sa, sb, ia0, ib0, False{}, False{}, s0,
          Some{c}, hmax, jpad, eps), r)

def rx_slot(+ia: Bool, +ib: Bool, +sa: Bool, +sb: Bool, +bi: Nat) -> Nat:
  match ia ib:
    case True{} True{}: 0n
    case True{} False{}: Bool.pick(Nat, sb, 1n, 0n)
    case False{} True{}: Bool.pick(Nat, sa, 1n, 0n)
    case False{} False{}: Nat.add(2n, bi)

type RXBR is Data:
  RXBR{ segs: List<&2, RSEG>, sa: Bool, sb: Bool, j0: Nat, j1: Nat, slv: F64, sla: F64,
    ok: Bool }

def rx_nonempty(+ss: List<&2, RSEG>) -> Bool:
  match ss:
    case []: False{}
    case +_ <> +_: True{}

def rx_branch(+a: RC, +b: RC, +m: U64, +sa: Bool, +sb: Bool, +bi: Nat, +y0: F64, +y1: F64,
    +ia0: Bool, +ib0: Bool, +ia1: Bool, +ib1: Bool, +cs: List<&2, FCL>, +hmax: F64,
    +jpad: F64, +eps: F64) -> RXBR:
  +r = rx_branch_go(cs, a, b, m, sa, sb, y0, None{}, ia0, ib0, y1, ia1, ib1, hmax, jpad,
    eps, RSB{[], 0.0f64, 0.0f64, True{}})
  RXBR{rsb_segs(r), sa, sb, rx_slot(ia0, ib0, sa, sb, bi),
    Nat.add(8n, rx_slot(ia1, ib1, sa, sb, bi)), rsb_slv(r), rsb_sla(r),
    Bool.and(rsb_ok(r), rx_nonempty(rsb_segs(r)))}

def rxbr_segs(+r: RXBR) -> List<&2, RSEG>:
  RXBR{segs, sa, sb, j0, j1, slv, sla, ok} = r
  segs

def rxbr_sa(+r: RXBR) -> Bool:
  RXBR{segs, sa, sb, j0, j1, slv, sla, ok} = r
  sa

def rxbr_sb(+r: RXBR) -> Bool:
  RXBR{segs, sa, sb, j0, j1, slv, sla, ok} = r
  sb

def rxbr_j0(+r: RXBR) -> Nat:
  RXBR{segs, sa, sb, j0, j1, slv, sla, ok} = r
  j0

def rxbr_j1(+r: RXBR) -> Nat:
  RXBR{segs, sa, sb, j0, j1, slv, sla, ok} = r
  j1

def rxbr_slv(+r: RXBR) -> F64:
  RXBR{segs, sa, sb, j0, j1, slv, sla, ok} = r
  slv

def rxbr_sla(+r: RXBR) -> F64:
  RXBR{segs, sa, sb, j0, j1, slv, sla, ok} = r
  sla

def rxbr_ok(+r: RXBR) -> Bool:
  RXBR{segs, sa, sb, j0, j1, slv, sla, ok} = r
  ok

def rx_tag(+r: RXBR, +useA: Bool) -> Bool:
  Bool.pick(Bool, useA, rxbr_sa(r), rxbr_sb(r))

def rx_pair4_c(+is2: Bool, +t0: Bool, +t1: Bool, +t2: Bool, +t3: Bool) -> U64:
  match is2:
    case False{}: 255u64
    case True{}:
      +e01 = Bool.or(Bool.and(t0, t1), Bool.and(Bool.not(t0), Bool.not(t1)))
      +e02 = Bool.or(Bool.and(t0, t2), Bool.and(Bool.not(t0), Bool.not(t2)))
      +e12 = Bool.or(Bool.and(t1, t2), Bool.and(Bool.not(t1), Bool.not(t2)))
      +p0 = Bool.pick(U64, e01, 1u64, Bool.pick(U64, e02, 2u64, 3u64))
      +p1 = Bool.pick(U64, e01, 0u64, Bool.pick(U64, e12, 2u64, 3u64))
      +p2 = Bool.pick(U64, e02, 0u64, Bool.pick(U64, e12, 1u64, 3u64))
      +e03 = Bool.or(Bool.and(t0, t3), Bool.and(Bool.not(t0), Bool.not(t3)))
      +e13 = Bool.or(Bool.and(t1, t3), Bool.and(Bool.not(t1), Bool.not(t3)))
      +p3 = Bool.pick(U64, e03, 0u64, Bool.pick(U64, e13, 1u64, 2u64))
      U64.add(p0, U64.add(U64.mul(4u64, p1), U64.add(U64.mul(16u64, p2), U64.mul(64u64, p3))))

def rx_pair4(+t0: Bool, +t1: Bool, +t2: Bool, +t3: Bool) -> U64:
  +n = Nat.add(Bool.pick(Nat, t0, 1n, 0n), Nat.add(Bool.pick(Nat, t1, 1n, 0n),
    Nat.add(Bool.pick(Nat, t2, 1n, 0n), Bool.pick(Nat, t3, 1n, 0n))))
  rx_pair4_c(Nat.is_eq(n, 2n), t0, t1, t2, t3)

type RXE is Data:
  RXE{ bi: Nat, en: Nat }

def rxe_bi(+r: RXE) -> Nat:
  RXE{bi, en} = r
  bi

def rxe_en(+r: RXE) -> Nat:
  RXE{bi, en} = r
  en

type RXL is Data:
  RXL{ bi: Nat, fw: Bool }

type RXW is Data:
  RXW{ loops: List<&2, List<&2, RXL>>, ok: Bool }

def rxw_loops(+r: RXW) -> List<&2, List<&2, RXL>>:
  RXW{loops, ok} = r
  loops

def rxw_ok(+r: RXW) -> Bool:
  RXW{loops, ok} = r
  ok

def rx_inc_go(+brs: List<&2, RXBR>, +j: Nat, +bi: Nat, +acc: List<&2, RXE>) -> List<&2, RXE>:
  match brs:
    case []: List.reverse(&2, RXE, acc)
    case +h <> +t:
      +a0 = Nat.is_eq(rxbr_j0(h), j)
      +a1 = Nat.is_eq(rxbr_j1(h), j)
      +a2 = Bool.pick(List<&2, RXE>, a1, RXE{bi, 1n} <> acc, acc)
      rx_inc_go(t, j, Nat.add(bi, 1n), Bool.pick(List<&2, RXE>, a0, RXE{bi, 0n} <> a2, a2))

def rx_nth(+xs: List<&2, RXBR>, +i: Nat) -> RXBR:
  match xs:
    case []: RXBR{[], False{}, False{}, 0n, 0n, 0.0f64, 0.0f64, False{}}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: rx_nth(t, j)

def rx_visited(+vis: List<&2, Nat>, +bi: Nat) -> Bool:
  match vis:
    case []: False{}
    case +h <> +t: Bool.or(Nat.is_eq(h, bi), rx_visited(t, bi))

def rx_unvis_go(+brs: List<&2, RXBR>, +vis: List<&2, Nat>, +bi: Nat, +v: Bool) -> Nat:
  match brs:
    case []: 99n
    case +_ <> +t:
      match v:
        case True{}: rx_unvis_go(t, vis, Nat.add(bi, 1n), rx_visited(vis, Nat.add(bi, 1n)))
        case False{}: bi

def rx_unvis(+brs: List<&2, RXBR>, +vis: List<&2, Nat>) -> Nat:
  rx_unvis_go(brs, vis, 0n, rx_visited(vis, 0n))

def rx_pick4(+pk: U64, +a: RXE, +b: RXE, +c: RXE, +d: RXE) -> RXE:
  match pk:
    case 0u64: a
    case 1u64: b
    case 2u64: c
    case _: d

def rx_partner(+inc: List<&2, RXE>, +brs: List<&2, RXBR>, +useA: Bool, +bi: Nat,
    +en: Nat) -> RXE:
  match inc:
    case []: RXE{99n, 0n}
    case +a <> +t:
      match t:
        case []: RXE{99n, 0n}
        case +b <> +u:
          match u:
            case []:
              Bool.pick(RXE, Bool.and(Nat.is_eq(rxe_bi(a), bi), Nat.is_eq(rxe_en(a), en)),
                b, a)
            case +c <> +v:
              match v:
                case +d <> +w:
                  match w:
                    case []:
                      +t0 = rx_tag(rx_nth(brs, rxe_bi(a)), useA)
                      +t1 = rx_tag(rx_nth(brs, rxe_bi(b)), useA)
                      +t2 = rx_tag(rx_nth(brs, rxe_bi(c)), useA)
                      +t3 = rx_tag(rx_nth(brs, rxe_bi(d)), useA)
                      +pp = rx_pair4(t0, t1, t2, t3)
                      +k = Bool.pick(Nat, Bool.and(Nat.is_eq(rxe_bi(a), bi),
                          Nat.is_eq(rxe_en(a), en)), 0n,
                        Bool.pick(Nat, Bool.and(Nat.is_eq(rxe_bi(b), bi),
                          Nat.is_eq(rxe_en(b), en)), 1n,
                        Bool.pick(Nat, Bool.and(Nat.is_eq(rxe_bi(c), bi),
                          Nat.is_eq(rxe_en(c), en)), 2n, 3n)))
                      +pk = Bool.pick(U64, Nat.is_eq(k, 0n), U64.and(pp, 3u64),
                        Bool.pick(U64, Nat.is_eq(k, 1n), U64.and(U64.div(pp, 4u64), 3u64),
                        Bool.pick(U64, Nat.is_eq(k, 2n), U64.and(U64.div(pp, 16u64), 3u64),
                          U64.and(U64.div(pp, 64u64), 3u64))))
                      rx_pick4(pk, a, b, c, d)
                    case +_ <> +_: RXE{99n, 0n}
                case []: RXE{99n, 0n}

def rx_at(+brs: List<&2, RXBR>, +bi: Nat, +end: Nat) -> Nat:
  +r = rx_nth(brs, bi)
  Bool.pick(Nat, Nat.is_eq(end, 0n), rxbr_j0(r), rxbr_j1(r))

def rx_walk_pe(+brs: List<&2, RXBR>, +useA: Bool, +bi: Nat, +en: Nat) -> RXE:
  +arr = Bool.pick(Nat, Nat.is_eq(en, 0n), rx_at(brs, bi, 1n), rx_at(brs, bi, 0n))
  rx_partner(rx_inc_go(brs, arr, 0n, []), brs, useA, bi,
    Bool.pick(Nat, Nat.is_eq(en, 0n), 1n, 0n))

def rx_walk_code(+brs: List<&2, RXBR>, +useA: Bool, +bi: Nat, +en: Nat, +sbi: Nat,
    +sen: Nat, +vis: List<&2, Nat>) -> Nat:
  +pe = rx_walk_pe(brs, useA, bi, en)
  +nbi = rxe_bi(pe)
  +nen = rxe_en(pe)
  Bool.pick(Nat, Bool.and(Nat.is_eq(nbi, sbi), Nat.is_eq(nen, sen)),
    Bool.pick(Nat, Nat.is_eq(rx_unvis(brs, bi <> vis), 99n), 0n, 1n),
    Bool.pick(Nat, Nat.is_eq(nbi, 99n), 2n, 3n))

def rx_cur2(+bi: Nat, +en: Nat, +cur: List<&2, RXL>) -> List<&2, RXL>:
  RXL{bi, Nat.is_eq(en, 0n)} <> cur

def rx_loops2(+bi: Nat, +en: Nat, +cur: List<&2, RXL>,
    +loops: List<&2, List<&2, RXL>>) -> List<&2, List<&2, RXL>>:
  List.reverse(&2, RXL, rx_cur2(bi, en, cur)) <> loops

def rx_vis2(+bi: Nat, +vis: List<&2, Nat>) -> List<&2, Nat>:
  bi <> vis

def rx_walk_go(+fuel: Nat, +brs: List<&2, RXBR>, +useA: Bool, +bi: Nat, +en: Nat,
    +sbi: Nat, +sen: Nat, +vis: List<&2, Nat>, +cur: List<&2, RXL>,
    +loops: List<&2, List<&2, RXL>>, +code: Nat) -> RXW:
  match fuel:
    case 0n: RXW{loops, False{}}
    case 1n+f:
      match code:
        case 0n: RXW{rx_loops2(bi, en, cur, loops), True{}}
        case 1n:
          +vis2 = rx_vis2(bi, vis)
          +loops2 = rx_loops2(bi, en, cur, loops)
          +nx = rx_unvis(brs, vis2)
          rx_walk_go(f, brs, useA, nx, 0n, nx, 0n, vis2, [], loops2,
            rx_walk_code(brs, useA, nx, 0n, nx, 0n, vis2))
        case 2n: RXW{loops, False{}}
        case _:
          +vis2 = rx_vis2(bi, vis)
          +pe = rx_walk_pe(brs, useA, bi, en)
          rx_walk_go(f, brs, useA, rxe_bi(pe), rxe_en(pe), sbi, sen, vis2,
            rx_cur2(bi, en, cur), loops,
            rx_walk_code(brs, useA, rxe_bi(pe), rxe_en(pe), sbi, sen, vis2))

def rx_walk(+brs: List<&2, RXBR>, +useA: Bool) -> RXW:
  match brs:
    case []: RXW{[], True{}}
    case +_ <> +_:
      rx_walk_go(20n, brs, useA, 0n, 0n, 0n, 0n, [], [], [],
        rx_walk_code(brs, useA, 0n, 0n, 0n, 0n, []))

def rxl_bi(+r: RXL) -> Nat:
  RXL{bi, fw} = r
  bi

def rxl_fw(+r: RXL) -> Bool:
  RXL{bi, fw} = r
  fw

def rx_jout(+brs: List<&2, RXBR>, +e: RXL) -> Nat:
  +r = rx_nth(brs, rxl_bi(e))
  Bool.pick(Nat, rxl_fw(e), rxbr_j1(r), rxbr_j0(r))

def rx_jin(+brs: List<&2, RXBR>, +e: RXL) -> Nat:
  +r = rx_nth(brs, rxl_bi(e))
  Bool.pick(Nat, rxl_fw(e), rxbr_j0(r), rxbr_j1(r))

def rx_loop_ok_go(+brs: List<&2, RXBR>, +es: List<&2, RXL>, +first: Nat) -> Bool:
  match es:
    case []: False{}
    case +h <> +t:
      match t:
        case []: Nat.is_eq(rx_jout(brs, h), first)
        case +n <> +u:
          Bool.and(Nat.is_eq(rx_jout(brs, h), rx_jin(brs, n)), rx_loop_ok_go(brs, t, first))

def rx_loop_ok(+brs: List<&2, RXBR>, +es: List<&2, RXL>) -> Bool:
  match es:
    case []: False{}
    case +h <> +t: rx_loop_ok_go(brs, es, rx_jin(brs, h))

def rx_cov_l(+es: List<&2, RXL>, +bi: Nat, +n: Nat) -> Nat:
  match es:
    case []: n
    case +h <> +t:
      rx_cov_l(t, bi, Nat.add(n, Bool.pick(Nat, Nat.is_eq(rxl_bi(h), bi), 1n, 0n)))

def rx_cov_go(+ls: List<&2, List<&2, RXL>>, +bi: Nat, +n: Nat) -> Nat:
  match ls:
    case []: n
    case +h <> +t: rx_cov_go(t, bi, rx_cov_l(h, bi, n))

def rx_all_closed(+brs: List<&2, RXBR>, +ls: List<&2, List<&2, RXL>>) -> Bool:
  match ls:
    case []: True{}
    case +h <> +t: Bool.and(rx_loop_ok(brs, h), rx_all_closed(brs, t))

def rx_verify_go(+fuel: Nat, +brs: List<&2, RXBR>, +ls: List<&2, List<&2, RXL>>,
    +bi: Nat) -> Bool:
  match fuel:
    case 0n: rx_all_closed(brs, ls)
    case 1n+f:
      Bool.and(Nat.is_eq(rx_cov_go(ls, bi, 0n), 1n),
        rx_verify_go(f, brs, ls, Nat.add(bi, 1n)))

def rx_verify(+brs: List<&2, RXBR>, +ls: List<&2, List<&2, RXL>>) -> Bool:
  rx_verify_go(List.length(&2, RXBR, brs), brs, ls, 0n)

def rx_walk_v(+brs: List<&2, RXBR>, +useA: Bool) -> RXW:
  +w = rx_walk(brs, useA)
  RXW{rxw_loops(w), Bool.and(rxw_ok(w), rx_verify(brs, rxw_loops(w)))}

type RING is Data:
  RING{ vs: List<&2, V.Point>, slv: F64, sla: F64 }

def ring_vs(+r: RING) -> List<&2, V.Point>:
  RING{vs, slv, sla} = r
  vs

def ring_slv(+r: RING) -> F64:
  RING{vs, slv, sla} = r
  slv

def ring_sla(+r: RING) -> F64:
  RING{vs, slv, sla} = r
  sla

def rx_zrange_go(+ps: List<&2, V.Point>, +ax: U64, +lo: F64, +hi: F64) -> V.Vec2:
  match ps:
    case []: V.V2{lo, hi}
    case +h <> +t:
      +c = pcomp(h, ax)
      rx_zrange_go(t, ax, Bool.pick(F64, F64.is_lt(c, lo), c, lo),
        Bool.pick(F64, F64.is_lt(hi, c), c, hi))

def rx_zrange(+vs: List<&2, V.Point>, +ax: U64) -> V.Vec2:
  match vs:
    case []: V.V2{0.0f64, 0.0f64}
    case +h <> +t: rx_zrange_go(t, ax, pcomp(h, ax), pcomp(h, ax))

def rx_chain_go(+ss: List<&2, RSEG>, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match ss:
    case []: List.reverse(&2, V.Point, acc)
    case +h <> +t: rx_chain_go(t, rseg_a(h) <> acc)

def rx_chain_last(+ss: List<&2, RSEG>) -> V.Point:
  match ss:
    case []: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case +h <> +t:
      match t:
        case []: rseg_b(h)
        case +_ <> +_: rx_chain_last(t)

def rx_chain(+ss: List<&2, RSEG>) -> List<&2, V.Point>:
  match ss:
    case []: []
    case +_ <> +_: List.append(&2, V.Point, rx_chain_go(ss, []), [rx_chain_last(ss)])

def rx_rev_go(+ss: List<&2, RSEG>, +acc: List<&2, RSEG>) -> List<&2, RSEG>:
  match ss:
    case []: acc
    case +h <> +t:
      rx_rev_go(t, RSEG{rseg_b(h), rseg_a(h), rseg_slv(h), rseg_sla(h)} <> acc)

def rx_loop_pts_go(+brs: List<&2, RXBR>, +es: List<&2, RXL>, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match es:
    case []: acc
    case +h <> +t:
      +ss = rxbr_segs(rx_nth(brs, rxl_bi(h)))
      +ch = rx_chain(Bool.pick(List<&2, RSEG>, rxl_fw(h), ss, rx_rev_go(ss, [])))
      rx_loop_pts_go(brs, t, List.append(&2, V.Point, acc, ch))

def rx_dedup_eq(+t: List<&2, V.Point>, +a: V.Point) -> Bool:
  match t:
    case []: False{}
    case +h2 <> +t2: pt_eq3(a, h2)

def rx_dedup_go(+ps: List<&2, V.Point>, +acc: List<&2, V.Point>, +eq: Bool) -> List<&2, V.Point>:
  match ps:
    case []: List.reverse(&2, V.Point, acc)
    case +h <> +t:
      match acc:
        case []: rx_dedup_go(t, h <> acc, rx_dedup_eq(t, h))
        case +a <> +u:
          match eq:
            case True{}: rx_dedup_go(t, acc, rx_dedup_eq(t, a))
            case False{}: rx_dedup_go(t, h <> acc, rx_dedup_eq(t, h))

def rx_dedup(+ps: List<&2, V.Point>) -> List<&2, V.Point>:
  match ps:
    case []: []
    case +h <> +t: rx_dedup_go(t, [h], rx_dedup_eq(t, h))

def rx_loop_sl_go(+brs: List<&2, RXBR>, +es: List<&2, RXL>, +sv: F64, +sa: F64) -> V.Vec2:
  match es:
    case []: V.V2{I.up(sv), I.up(sa)}
    case +h <> +t:
      +r = rx_nth(brs, rxl_bi(h))
      rx_loop_sl_go(brs, t, F64.add(sv, rxbr_slv(r)), F64.add(sa, rxbr_sla(r)))

def rx_expand(+brs: List<&2, RXBR>, +es: List<&2, RXL>) -> RING:
  +vs = rx_dedup(rx_loop_pts_go(brs, es, []))
  +sl = rx_loop_sl_go(brs, es, 0.0f64, 0.0f64)
  RING{vs, V.v2_x(sl), V.v2_y(sl)}

def rx_expand_all_go(+brs: List<&2, RXBR>, +ls: List<&2, List<&2, RXL>>,
    +acc: List<&2, RING>) -> List<&2, RING>:
  match ls:
    case []: List.reverse(&2, RING, acc)
    case +h <> +t: rx_expand_all_go(brs, t, rx_expand(brs, h) <> acc)

def rx_last_pt(+ps: List<&2, V.Point>, +dflt: V.Point) -> V.Point:
  match ps:
    case []: dflt
    case +h <> +t: rx_last_pt(t, h)

def rx_closed(+vs: List<&2, V.Point>) -> Bool:
  match vs:
    case []: False{}
    case +h <> +t: pt_eq3(h, rx_last_pt(t, h))

def rx_all_vclosed_go(+rs: List<&2, RING>) -> Bool:
  match rs:
    case []: True{}
    case +h <> +t: Bool.and(rx_closed(ring_vs(h)), rx_all_vclosed_go(t))

def rx_rings_for(+brs: List<&2, RXBR>, +useA: Bool) -> RXW:
  rx_walk_v(brs, useA)

type RXR is Data:
  RXR{ oka: Bool, okb: Bool, ra: List<&2, RING>, rb: List<&2, RING> }

def rxr_oka(+r: RXR) -> Bool:
  RXR{oka, okb, ra, rb} = r
  oka

def rxr_okb(+r: RXR) -> Bool:
  RXR{oka, okb, ra, rb} = r
  okb

def rxr_ra(+r: RXR) -> List<&2, RING>:
  RXR{oka, okb, ra, rb} = r
  ra

def rxr_rb(+r: RXR) -> List<&2, RING>:
  RXR{oka, okb, ra, rb} = r
  rb

def rx_brs_ok_go(+brs: List<&2, RXBR>) -> Bool:
  match brs:
    case []: True{}
    case +h <> +t: Bool.and(rxbr_ok(h), rx_brs_ok_go(t))

def rx_mkbrs(+a: RC, +b: RC, +m: U64, +y0: F64, +y1: F64, +ia0: Bool, +ib0: Bool,
    +ia1: Bool, +ib1: Bool, +cs: List<&2, FCL>, +hmax: F64, +jpad: F64,
    +eps: F64) -> List<&2, RXBR>:
  Bool.pick(List<&2, RXBR>, F64.is_lt(y1, y0), [],
    [rx_branch(a, b, m, True{}, True{}, 0n, y0, y1, ia0, ib0, ia1, ib1, cs, hmax, jpad,
      eps),
      rx_branch(a, b, m, True{}, False{}, 1n, y0, y1, ia0, ib0, ia1, ib1, cs, hmax, jpad,
      eps),
      rx_branch(a, b, m, False{}, True{}, 2n, y0, y1, ia0, ib0, ia1, ib1, cs, hmax, jpad,
      eps),
      rx_branch(a, b, m, False{}, False{}, 3n, y0, y1, ia0, ib0, ia1, ib1, cs, hmax, jpad,
      eps)])

def rx_brs(+a: RC, +b: RC, +m: U64, +cs: List<&2, FCL>) -> List<&2, RXBR>:
  +ov = rx_overlap(a, b, m)
  +y0 = V.v2_x(ov)
  +y1 = V.v2_y(ov)
  +jpad = rx_jpad(a, b, m)
  +hmax = F64.mul(0.125f64, F64.max(rc_r(a), rc_r(b)))
  rx_mkbrs(a, b, m, y0, y1, F64.is_eq(y0, rc_dom_lo(a, m)),
    F64.is_eq(y0, rc_dom_lo(b, m)), F64.is_eq(y1, rc_dom_hi(a, m)),
    F64.is_eq(y1, rc_dom_hi(b, m)), cs, hmax, jpad, F64.mul(hmax, 1.0e-9f64))

def rx_rings(+a: RC, +b: RC, +m: U64, +cs: List<&2, FCL>) -> RXR:
  +brs = rx_brs(a, b, m, cs)
  +wA = rx_walk_v(brs, True{})
  +ra = rx_expand_all_go(brs, rxw_loops(wA), [])
  +fok = rx_brs_ok_go(brs)
  +oka = Bool.and(rxw_ok(wA), Bool.and(fok, rx_all_vclosed_go(ra)))
  RXR{oka, oka, ra, ra}

def rx_dbg(+a: RC, +b: RC, +m: U64, +cs: List<&2, FCL>, +useA: Bool) -> String:
  +r = rx_rings(a, b, m, cs)
  +w = rx_walk_v(rx_brs(a, b, m, cs), useA)
  Bool.pick(String, Bool.pick(Bool, useA, rxr_oka(r), rxr_okb(r)), "1", "0") ++ "/" ++
    Nat.show(List.length(&2, List<&2, RXL>, rxw_loops(w))) ++ "/" ++
    Nat.show(List.length(&2, RING, Bool.pick(List<&2, RING>, useA, rxr_ra(r), rxr_rb(r))))

def rx_pt(+a: RC, +b: RC, +m: U64, +y: F64, +sa: Bool, +sb: Bool) -> V.Point:
  +wa = other_ax(rc_ax(a), m)
  +va = rc_branch(a, m, y, sa)
  +vb = rc_branch(b, m, y, sb)
  +x = Bool.pick(F64, U64.is_eq(m, 0u64), y, Bool.pick(F64, U64.is_eq(wa, 0u64), va, vb))
  +yy = Bool.pick(F64, U64.is_eq(m, 1u64), y, Bool.pick(F64, U64.is_eq(wa, 1u64), va, vb))
  +z = Bool.pick(F64, U64.is_eq(m, 2u64), y, Bool.pick(F64, U64.is_eq(wa, 2u64), va, vb))
  V.Pt{x, yy, z}
