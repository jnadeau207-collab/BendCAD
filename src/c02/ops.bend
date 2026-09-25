# C02 operators: robust predicates with a fast bounded-error filter and an
# exact small-integer fallback. Every publishing op returns PRes/Xres/Tres:
# a certified sign/relation/class or a C00 FailKind (invalid = malformed
# input, uncertain = filter silent and exact domain inapplicable — never a
# guessed side). Contract: docs/c02-contract.md.
#
# Pipeline per predicate (first match wins): finite gate -> repeated-point
# exact zero -> F64 filter (floor + shortcut + error bound) -> exact
# small-integer kernel -> numerical-uncertainty. Zero signs come ONLY from
# exact paths (repeated points or the integer kernel); the filter certifies
# nonzero signs only. Summation/expansion orders below are the contract.

import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ./types.bend as P

# --- F64 3x3 core (shared by orient3d, incircle, insphere minors). ---
# Cofactor expansion along row 0, SAME parenthesization as C01 m3_det_raw.
def d3_raw(a: F64, b: F64, c: F64, +d: F64, +e: F64, +f: F64, +g: F64,
    +h: F64, +i: F64) -> F64:
  +t0 = F64.sub(F64.mul(e, i), F64.mul(f, h))
  +t1 = F64.sub(F64.mul(d, i), F64.mul(f, g))
  +t2 = F64.sub(F64.mul(d, h), F64.mul(e, g))
  F64.add(F64.sub(F64.mul(a, t0), F64.mul(b, t1)), F64.mul(c, t2))

# Positive/negative parts of one F64 value (exact comparisons; signed
# zeroes contribute 0 to both sides, matching their absolute value).
def fpos_go(+t: F64, pos: Bool) -> F64:
  match pos:
    case True{}: F64.abs(t)
    case False{}: 0.0f64

def fpos(+t: F64) -> F64:
  fpos_go(t, F64.is_lt(0.0f64, t))

def fneg_go(+t: F64, neg: Bool) -> F64:
  match neg:
    case True{}: F64.abs(t)
    case False{}: 0.0f64

def fneg(+t: F64) -> F64:
  fneg_go(t, F64.is_lt(t, 0.0f64))

# Positive/negative triple-product sums over the six SIGNED triples
# (+aei, +bfg, +cdh, -gec, -hfa, -idb), split by VALUE sign: det = P-N
# with P, N >= 0. Each triple is ((x*y)*z) with exact negation on the
# last three; the outer sums are pinned left folds. Splitting by
# cofactor position instead would be WRONG (a +cofactor triple can be
# negative); the value split is what makes P==0/N==0 decisive.
def d3_pos(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64,
    +g: F64, +h: F64, +i: F64) -> F64:
  +t1 = F64.mul(F64.mul(a, e), i)
  +t2 = F64.mul(F64.mul(b, f), g)
  +t3 = F64.mul(F64.mul(c, d), h)
  +t4 = F64.neg(F64.mul(F64.mul(g, e), c))
  +t5 = F64.neg(F64.mul(F64.mul(h, f), a))
  +t6 = F64.neg(F64.mul(F64.mul(i, d), b))
  F64.add(F64.add(F64.add(F64.add(F64.add(fpos(t1), fpos(t2)),
    fpos(t3)), fpos(t4)), fpos(t5)), fpos(t6))

def d3_neg(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64,
    +g: F64, +h: F64, +i: F64) -> F64:
  +u1 = F64.mul(F64.mul(a, e), i)
  +u2 = F64.mul(F64.mul(b, f), g)
  +u3 = F64.mul(F64.mul(c, d), h)
  +u4 = F64.neg(F64.mul(F64.mul(g, e), c))
  +u5 = F64.neg(F64.mul(F64.mul(h, f), a))
  +u6 = F64.neg(F64.mul(F64.mul(i, d), b))
  F64.add(F64.add(F64.add(F64.add(F64.add(fneg(u1), fneg(u2)),
    fneg(u3)), fneg(u4)), fneg(u5)), fneg(u6))

# --- Exact 3x3 core on sign-magnitude integers (same expansion). ---
def e3_raw(+a: P.SBal, +b: P.SBal, +c: P.SBal, +d: P.SBal, +e: P.SBal,
    +f: P.SBal, +g: P.SBal, +h: P.SBal, +i: P.SBal) -> P.SBal:
  +t0 = P.sb_sub(P.sb_mul(e, i), P.sb_mul(f, h))
  +t1 = P.sb_sub(P.sb_mul(d, i), P.sb_mul(f, g))
  +t2 = P.sb_sub(P.sb_mul(d, h), P.sb_mul(e, g))
  P.sb_add(P.sb_sub(P.sb_mul(a, t0), P.sb_mul(b, t1)), P.sb_mul(c, t2))

# --- Exact coordinate equality (total on finite values; -0.0 == +0.0).
# NOTE: callers let-bind each pteq result before combining. A nested
# Bool.or of 3+ pteq calls miscompiles on the native (C) lane at BEND_PIN
# (returns True; interp/JS correct) — see contract §10. ---
def pteq2(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> Bool:
  Bool.and(F64.is_eq(ax, bx), F64.is_eq(ay, by))

def pteq3(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64,
    +bz: F64) -> Bool:
  Bool.and(F64.is_eq(ax, bx),
    Bool.and(F64.is_eq(ay, by), F64.is_eq(az, bz)))

# --- orient2d: sign of det |ax-cx bx-cx; ay-cy by-cy|. ---
# Pos iff c is left of a->b (CCW triangle a,b,c).
def o2_exact_go(+ok: Bool, +xa: P.SInt, +xb: P.SInt, +xc: P.SInt,
    +ya: P.SInt, +yb: P.SInt, +yc: P.SInt) -> P.PRes:
  match ok:
    case True{}:
      +acx = P.sb_sub(P.sb_of_int(xa), P.sb_of_int(xc))
      +bcx = P.sb_sub(P.sb_of_int(xb), P.sb_of_int(xc))
      +acy = P.sb_sub(P.sb_of_int(ya), P.sb_of_int(yc))
      +bcy = P.sb_sub(P.sb_of_int(yb), P.sb_of_int(yc))
      +dl = P.sb_mul(acx, bcy)
      +dr = P.sb_mul(acy, bcx)
      P.pok(P.sb_sign(P.sb_sub(dl, dr)))
    case False{}:
      P.perr(T.F_uncertain{})

def o2_exact(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64) -> P.PRes:
  +xa = P.sint_of(ax, P.lim_o2())
  +xb = P.sint_of(bx, P.lim_o2())
  +xc = P.sint_of(cx, P.lim_o2())
  +ya = P.sint_of(ay, P.lim_o2())
  +yb = P.sint_of(by, P.lim_o2())
  +yc = P.sint_of(cy, P.lim_o2())
  +ok = Bool.and(P.si_ok(xa),
    Bool.and(P.si_ok(xb),
      Bool.and(P.si_ok(xc),
        Bool.and(P.si_ok(ya), Bool.and(P.si_ok(yb), P.si_ok(yc))))))
  o2_exact_go(ok, xa, xb, xc, ya, yb, yc)

def o2_bound(+det: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64,
    +cx: F64, +cy: F64, big: Bool) -> P.PRes:
  match big:
    case True{}: P.pok(P.sign_of_f(det))
    case False{}: o2_exact(ax, ay, bx, by, cx, cy)

def o2_short(+det: F64, +big: Bool, +ax: F64, +ay: F64, +bx: F64,
    +by: F64, +cx: F64, +cy: F64, opp: Bool) -> P.PRes:
  match opp:
    case True{}: P.pok(P.sign_of_f(det))
    case False{}: o2_bound(det, ax, ay, bx, by, cx, cy, big)

def o2_gate(+det: F64, +opp: Bool, +big: Bool, +ax: F64, +ay: F64,
    +bx: F64, +by: F64, +cx: F64, +cy: F64, gate: Bool) -> P.PRes:
  match gate:
    case True{}: o2_short(det, big, ax, ay, bx, by, cx, cy, opp)
    case False{}: o2_exact(ax, ay, bx, by, cx, cy)

def o2_run(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64) -> P.PRes:
  +acx = F64.sub(ax, cx)
  +bcx = F64.sub(bx, cx)
  +acy = F64.sub(ay, cy)
  +bcy = F64.sub(by, cy)
  +dl = F64.mul(acx, bcy)
  +dr = F64.mul(acy, bcx)
  +det = F64.sub(dl, dr)
  +detsum = F64.add(F64.abs(dl), F64.abs(dr))
  +gate = Bool.and(T.is_finite(det),
    Bool.and(T.is_finite(detsum), F64.is_le(P.detmin(), detsum)))
  +dlp = F64.is_lt(0.0f64, dl)
  +dln = F64.is_lt(dl, 0.0f64)
  +drp = F64.is_lt(0.0f64, dr)
  +drn = F64.is_lt(dr, 0.0f64)
  +opp = Bool.not(Bool.or(Bool.and(dlp, drp), Bool.and(dln, drn)))
  +big = F64.is_lt(F64.mul(P.k_o2(), detsum), F64.abs(det))
  o2_gate(det, opp, big, ax, ay, bx, by, cx, cy, gate)

def o2_rep(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64, rep: Bool) -> P.PRes:
  match rep:
    case True{}: P.pok(P.Sg_zero{})
    case False{}: o2_run(ax, ay, bx, by, cx, cy)

def o2_fin(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64, fin: Bool, rep: Bool) -> P.PRes:
  match fin:
    case True{}: o2_rep(ax, ay, bx, by, cx, cy, rep)
    case False{}: P.perr(T.F_invalid{})

def orient2d(+a: V.Vec2, +b: V.Vec2, +c: V.Vec2) -> P.PRes:
  V.V2{+ax, +ay} = a
  V.V2{+bx, +by} = b
  V.V2{+cx, +cy} = c
  +fin = Bool.and(T.is_finite(ax),
    Bool.and(T.is_finite(ay),
      Bool.and(T.is_finite(bx),
        Bool.and(T.is_finite(by),
          Bool.and(T.is_finite(cx), T.is_finite(cy))))))
  +r12 = pteq2(ax, ay, bx, by)
  +r23 = pteq2(bx, by, cx, cy)
  +r13 = pteq2(ax, ay, cx, cy)
  +rep = Bool.or(r12, Bool.or(r23, r13))
  o2_fin(ax, ay, bx, by, cx, cy, fin, rep)

# --- orient3d: sign of the 3x3 det of abcd translated by d. ---
# Pos iff d is above the oriented plane abc (right-handed tet abcd).
def o3_exact_go(+ok: Bool, +xa: P.SInt, +ya: P.SInt, +za: P.SInt,
    +xb: P.SInt, +yb: P.SInt, +zb: P.SInt, +xc: P.SInt, +yc: P.SInt,
    +zc: P.SInt, +xd: P.SInt, +yd: P.SInt, +zd: P.SInt) -> P.PRes:
  match ok:
    case True{}:
      +adx = P.sb_sub(P.sb_of_int(xa), P.sb_of_int(xd))
      +ady = P.sb_sub(P.sb_of_int(ya), P.sb_of_int(yd))
      +adz = P.sb_sub(P.sb_of_int(za), P.sb_of_int(zd))
      +bdx = P.sb_sub(P.sb_of_int(xb), P.sb_of_int(xd))
      +bdy = P.sb_sub(P.sb_of_int(yb), P.sb_of_int(yd))
      +bdz = P.sb_sub(P.sb_of_int(zb), P.sb_of_int(zd))
      +cdx = P.sb_sub(P.sb_of_int(xc), P.sb_of_int(xd))
      +cdy = P.sb_sub(P.sb_of_int(yc), P.sb_of_int(yd))
      +cdz = P.sb_sub(P.sb_of_int(zc), P.sb_of_int(zd))
      P.pok(P.sb_sign(e3_raw(adx, ady, adz, bdx, bdy, bdz, cdx, cdy,
        cdz)))
    case False{}:
      P.perr(T.F_uncertain{})

def o3_exact(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64,
    +bz: F64, +cx: F64, +cy: F64, +cz: F64, +dx: F64, +dy: F64,
    +dz: F64) -> P.PRes:
  +xa = P.sint_of(ax, P.lim_o3())
  +ya = P.sint_of(ay, P.lim_o3())
  +za = P.sint_of(az, P.lim_o3())
  +xb = P.sint_of(bx, P.lim_o3())
  +yb = P.sint_of(by, P.lim_o3())
  +zb = P.sint_of(bz, P.lim_o3())
  +xc = P.sint_of(cx, P.lim_o3())
  +yc = P.sint_of(cy, P.lim_o3())
  +zc = P.sint_of(cz, P.lim_o3())
  +xd = P.sint_of(dx, P.lim_o3())
  +yd = P.sint_of(dy, P.lim_o3())
  +zd = P.sint_of(dz, P.lim_o3())
  +ok = Bool.and(P.si_ok(xa),
    Bool.and(P.si_ok(ya),
      Bool.and(P.si_ok(za),
        Bool.and(P.si_ok(xb),
          Bool.and(P.si_ok(yb),
            Bool.and(P.si_ok(zb),
              Bool.and(P.si_ok(xc),
                Bool.and(P.si_ok(yc),
                  Bool.and(P.si_ok(zc),
                    Bool.and(P.si_ok(xd),
                      Bool.and(P.si_ok(yd),
                        P.si_ok(zd))))))))))))
  o3_exact_go(ok, xa, ya, za, xb, yb, zb, xc, yc, zc, xd, yd, zd)

def o3_bound(+det: F64, +ax: F64, +ay: F64, +az: F64, +bx: F64,
    +by: F64, +bz: F64, +cx: F64, +cy: F64, +cz: F64, +dx: F64,
    +dy: F64, +dz: F64, big: Bool) -> P.PRes:
  match big:
    case True{}: P.pok(P.sign_of_f(det))
    case False{}: o3_exact(ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy,
      dz)

def o3_short_n(+det: F64, +big: Bool, +ax: F64, +ay: F64, +az: F64,
    +bx: F64, +by: F64, +bz: F64, +cx: F64, +cy: F64, +cz: F64,
    +dx: F64, +dy: F64, +dz: F64, nzero: Bool) -> P.PRes:
  match nzero:
    case True{}: P.pok(P.Sg_pos{})
    case False{}: o3_bound(det, ax, ay, az, bx, by, bz, cx, cy, cz, dx,
      dy, dz, big)

def o3_short_p(+det: F64, +big: Bool, +ax: F64, +ay: F64, +az: F64,
    +bx: F64, +by: F64, +bz: F64, +cx: F64, +cy: F64, +cz: F64,
    +dx: F64, +dy: F64, +dz: F64, pzero: Bool,
    nzero: Bool) -> P.PRes:
  match pzero:
    case True{}: P.pok(P.Sg_neg{})
    case False{}: o3_short_n(det, big, ax, ay, az, bx, by, bz, cx, cy,
      cz, dx, dy, dz, nzero)

def o3_gate(+det: F64, +pzero: Bool, +nzero: Bool, +big: Bool,
    +ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64, +bz: F64,
    +cx: F64, +cy: F64, +cz: F64, +dx: F64, +dy: F64, +dz: F64,
    gate: Bool) -> P.PRes:
  match gate:
    case True{}: o3_short_p(det, big, ax, ay, az, bx, by, bz, cx, cy,
      cz, dx, dy, dz, pzero, nzero)
    case False{}: o3_exact(ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy,
      dz)

def o3_run(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64,
    +bz: F64, +cx: F64, +cy: F64, +cz: F64, +dx: F64, +dy: F64,
    +dz: F64) -> P.PRes:
  +adx = F64.sub(ax, dx)
  +ady = F64.sub(ay, dy)
  +adz = F64.sub(az, dz)
  +bdx = F64.sub(bx, dx)
  +bdy = F64.sub(by, dy)
  +bdz = F64.sub(bz, dz)
  +cdx = F64.sub(cx, dx)
  +cdy = F64.sub(cy, dy)
  +cdz = F64.sub(cz, dz)
  +det = d3_raw(adx, ady, adz, bdx, bdy, bdz, cdx, cdy, cdz)
  +pp = d3_pos(adx, ady, adz, bdx, bdy, bdz, cdx, cdy, cdz)
  +nn = d3_neg(adx, ady, adz, bdx, bdy, bdz, cdx, cdy, cdz)
  +detsum = F64.add(pp, nn)
  +gate = Bool.and(T.is_finite(det),
    Bool.and(T.is_finite(pp),
      Bool.and(T.is_finite(nn),
        Bool.and(T.is_finite(detsum),
          F64.is_le(P.detmin(), detsum)))))
  +pzero = F64.is_eq(pp, 0.0f64)
  +nzero = F64.is_eq(nn, 0.0f64)
  +big = F64.is_lt(F64.mul(P.k_o3(), detsum), F64.abs(det))
  o3_gate(det, pzero, nzero, big, ax, ay, az, bx, by, bz, cx, cy, cz,
    dx, dy, dz, gate)

def o3_rep(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64,
    +bz: F64, +cx: F64, +cy: F64, +cz: F64, +dx: F64, +dy: F64,
    +dz: F64, rep: Bool) -> P.PRes:
  match rep:
    case True{}: P.pok(P.Sg_zero{})
    case False{}: o3_run(ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy,
      dz)

def o3_fin(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64,
    +bz: F64, +cx: F64, +cy: F64, +cz: F64, +dx: F64, +dy: F64,
    +dz: F64, fin: Bool, rep: Bool) -> P.PRes:
  match fin:
    case True{}: o3_rep(ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy,
      dz, rep)
    case False{}: P.perr(T.F_invalid{})

def orient3d(+a: V.Point, +b: V.Point, +c: V.Point,
    +d: V.Point) -> P.PRes:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  V.Pt{+cx, +cy, +cz} = c
  V.Pt{+dx, +dy, +dz} = d
  +fin = Bool.and(T.is_finite(ax),
    Bool.and(T.is_finite(ay),
      Bool.and(T.is_finite(az),
        Bool.and(T.is_finite(bx),
          Bool.and(T.is_finite(by),
            Bool.and(T.is_finite(bz),
              Bool.and(T.is_finite(cx),
                Bool.and(T.is_finite(cy),
                  Bool.and(T.is_finite(cz),
                    Bool.and(T.is_finite(dx),
                      Bool.and(T.is_finite(dy),
                        T.is_finite(dz))))))))))))
  +r12 = pteq3(ax, ay, az, bx, by, bz)
  +r13 = pteq3(ax, ay, az, cx, cy, cz)
  +r14 = pteq3(ax, ay, az, dx, dy, dz)
  +r23 = pteq3(bx, by, bz, cx, cy, cz)
  +r24 = pteq3(bx, by, bz, dx, dy, dz)
  +r34 = pteq3(cx, cy, cz, dx, dy, dz)
  +rep = Bool.or(r12,
    Bool.or(r13, Bool.or(r14, Bool.or(r23, Bool.or(r24, r34)))))
  o3_fin(ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy, dz, fin, rep)

# --- incircle: sign of the translated 3x3 det with a square column. ---
# Rows are (dx, dy, dx*dx+dy*dy) off d. Pos iff d is strictly inside the
# circle through a, b, c when (a, b, c) is CCW; the raw determinant sign
# is returned without orientation canonicalization (contract §5).
def ic_sq(+dx: F64, +dy: F64) -> F64:
  F64.add(F64.mul(dx, dx), F64.mul(dy, dy))

def ic_exact_go(+ok: Bool, +xa: P.SInt, +ya: P.SInt, +xb: P.SInt,
    +yb: P.SInt, +xc: P.SInt, +yc: P.SInt, +xd: P.SInt,
    +yd: P.SInt) -> P.PRes:
  match ok:
    case True{}:
      +adx = P.sb_sub(P.sb_of_int(xa), P.sb_of_int(xd))
      +ady = P.sb_sub(P.sb_of_int(ya), P.sb_of_int(yd))
      +bdx = P.sb_sub(P.sb_of_int(xb), P.sb_of_int(xd))
      +bdy = P.sb_sub(P.sb_of_int(yb), P.sb_of_int(yd))
      +cdx = P.sb_sub(P.sb_of_int(xc), P.sb_of_int(xd))
      +cdy = P.sb_sub(P.sb_of_int(yc), P.sb_of_int(yd))
      +aq = P.sb_add(P.sb_mul(adx, adx), P.sb_mul(ady, ady))
      +bq = P.sb_add(P.sb_mul(bdx, bdx), P.sb_mul(bdy, bdy))
      +cq = P.sb_add(P.sb_mul(cdx, cdx), P.sb_mul(cdy, cdy))
      P.pok(P.sb_sign(e3_raw(adx, ady, aq, bdx, bdy, bq, cdx, cdy,
        cq)))
    case False{}:
      P.perr(T.F_uncertain{})

def ic_exact(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64, +dx: F64, +dy: F64) -> P.PRes:
  +xa = P.sint_of(ax, P.lim_ic())
  +ya = P.sint_of(ay, P.lim_ic())
  +xb = P.sint_of(bx, P.lim_ic())
  +yb = P.sint_of(by, P.lim_ic())
  +xc = P.sint_of(cx, P.lim_ic())
  +yc = P.sint_of(cy, P.lim_ic())
  +xd = P.sint_of(dx, P.lim_ic())
  +yd = P.sint_of(dy, P.lim_ic())
  +ok = Bool.and(P.si_ok(xa),
    Bool.and(P.si_ok(ya),
      Bool.and(P.si_ok(xb),
        Bool.and(P.si_ok(yb),
          Bool.and(P.si_ok(xc),
            Bool.and(P.si_ok(yc),
              Bool.and(P.si_ok(xd), P.si_ok(yd))))))))
  ic_exact_go(ok, xa, ya, xb, yb, xc, yc, xd, yd)

def ic_bound(+det: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64,
    +cx: F64, +cy: F64, +dx: F64, +dy: F64, big: Bool) -> P.PRes:
  match big:
    case True{}: P.pok(P.sign_of_f(det))
    case False{}: ic_exact(ax, ay, bx, by, cx, cy, dx, dy)

def ic_short_n(+det: F64, +big: Bool, +ax: F64, +ay: F64, +bx: F64,
    +by: F64, +cx: F64, +cy: F64, +dx: F64, +dy: F64,
    nzero: Bool) -> P.PRes:
  match nzero:
    case True{}: P.pok(P.Sg_pos{})
    case False{}: ic_bound(det, ax, ay, bx, by, cx, cy, dx, dy, big)

def ic_short_p(+det: F64, +big: Bool, +ax: F64, +ay: F64, +bx: F64,
    +by: F64, +cx: F64, +cy: F64, +dx: F64, +dy: F64, pzero: Bool,
    nzero: Bool) -> P.PRes:
  match pzero:
    case True{}: P.pok(P.Sg_neg{})
    case False{}: ic_short_n(det, big, ax, ay, bx, by, cx, cy, dx, dy,
      nzero)

def ic_gate(+det: F64, +pzero: Bool, +nzero: Bool, +big: Bool,
    +ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64,
    +dx: F64, +dy: F64, gate: Bool) -> P.PRes:
  match gate:
    case True{}: ic_short_p(det, big, ax, ay, bx, by, cx, cy, dx, dy,
      pzero, nzero)
    case False{}: ic_exact(ax, ay, bx, by, cx, cy, dx, dy)

def ic_run(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64, +dx: F64, +dy: F64) -> P.PRes:
  +adx = F64.sub(ax, dx)
  +ady = F64.sub(ay, dy)
  +bdx = F64.sub(bx, dx)
  +bdy = F64.sub(by, dy)
  +cdx = F64.sub(cx, dx)
  +cdy = F64.sub(cy, dy)
  +aq = ic_sq(adx, ady)
  +bq = ic_sq(bdx, bdy)
  +cq = ic_sq(cdx, cdy)
  +det = d3_raw(adx, ady, aq, bdx, bdy, bq, cdx, cdy, cq)
  +pp = d3_pos(adx, ady, aq, bdx, bdy, bq, cdx, cdy, cq)
  +nn = d3_neg(adx, ady, aq, bdx, bdy, bq, cdx, cdy, cq)
  +detsum = F64.add(pp, nn)
  +gate = Bool.and(T.is_finite(det),
    Bool.and(T.is_finite(pp),
      Bool.and(T.is_finite(nn),
        Bool.and(T.is_finite(detsum),
          F64.is_le(P.detmin(), detsum)))))
  +pzero = F64.is_eq(pp, 0.0f64)
  +nzero = F64.is_eq(nn, 0.0f64)
  +big = F64.is_lt(F64.mul(P.k_ic(), detsum), F64.abs(det))
  ic_gate(det, pzero, nzero, big, ax, ay, bx, by, cx, cy, dx, dy,
    gate)

def ic_rep(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64, +dx: F64, +dy: F64, rep: Bool) -> P.PRes:
  match rep:
    case True{}: P.pok(P.Sg_zero{})
    case False{}: ic_run(ax, ay, bx, by, cx, cy, dx, dy)

def ic_fin(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64, +dx: F64, +dy: F64, fin: Bool, rep: Bool) -> P.PRes:
  match fin:
    case True{}: ic_rep(ax, ay, bx, by, cx, cy, dx, dy, rep)
    case False{}: P.perr(T.F_invalid{})

def incircle(+a: V.Vec2, +b: V.Vec2, +c: V.Vec2,
    +d: V.Vec2) -> P.PRes:
  V.V2{+ax, +ay} = a
  V.V2{+bx, +by} = b
  V.V2{+cx, +cy} = c
  V.V2{+dx, +dy} = d
  +fin = Bool.and(T.is_finite(ax),
    Bool.and(T.is_finite(ay),
      Bool.and(T.is_finite(bx),
        Bool.and(T.is_finite(by),
          Bool.and(T.is_finite(cx),
            Bool.and(T.is_finite(cy),
              Bool.and(T.is_finite(dx), T.is_finite(dy))))))))
  +r12 = pteq2(ax, ay, bx, by)
  +r13 = pteq2(ax, ay, cx, cy)
  +r14 = pteq2(ax, ay, dx, dy)
  +r23 = pteq2(bx, by, cx, cy)
  +r24 = pteq2(bx, by, dx, dy)
  +r34 = pteq2(cx, cy, dx, dy)
  +rep = Bool.or(r12,
    Bool.or(r13, Bool.or(r14, Bool.or(r23, Bool.or(r24, r34)))))
  ic_fin(ax, ay, bx, by, cx, cy, dx, dy, fin, rep)

# --- insphere: sign of the translated 4x4 det with a square column. ---
# Rows are (dx, dy, dz, dx*dx+dy*dy+dz*dz) off e, Laplace along row 0:
# det = r0*m0 - r1*m1 + r2*m2 - r3*m3 (pinned left association). Pos iff
# e is strictly inside the sphere through a, b, c, d when tet (a,b,c,d)
# is positively oriented; the raw determinant sign is returned (contract
# §5). P/N are the row0-weighted minor triple sums, same association.
def is_sq(+dx: F64, +dy: F64, +dz: F64) -> F64:
  F64.add(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)), F64.mul(dz, dz))

def is_exact_go(+ok: Bool, +xa: P.SInt, +ya: P.SInt, +za: P.SInt,
    +xb: P.SInt, +yb: P.SInt, +zb: P.SInt, +xc: P.SInt, +yc: P.SInt,
    +zc: P.SInt, +xd: P.SInt, +yd: P.SInt, +zd: P.SInt, +xe: P.SInt,
    +ye: P.SInt, +ze: P.SInt) -> P.PRes:
  match ok:
    case True{}:
      +adx = P.sb_sub(P.sb_of_int(xa), P.sb_of_int(xe))
      +ady = P.sb_sub(P.sb_of_int(ya), P.sb_of_int(ye))
      +adz = P.sb_sub(P.sb_of_int(za), P.sb_of_int(ze))
      +bdx = P.sb_sub(P.sb_of_int(xb), P.sb_of_int(xe))
      +bdy = P.sb_sub(P.sb_of_int(yb), P.sb_of_int(ye))
      +bdz = P.sb_sub(P.sb_of_int(zb), P.sb_of_int(ze))
      +cdx = P.sb_sub(P.sb_of_int(xc), P.sb_of_int(xe))
      +cdy = P.sb_sub(P.sb_of_int(yc), P.sb_of_int(ye))
      +cdz = P.sb_sub(P.sb_of_int(zc), P.sb_of_int(ze))
      +ddx = P.sb_sub(P.sb_of_int(xd), P.sb_of_int(xe))
      +ddy = P.sb_sub(P.sb_of_int(yd), P.sb_of_int(ye))
      +ddz = P.sb_sub(P.sb_of_int(zd), P.sb_of_int(ze))
      +aq = P.sb_add(P.sb_add(P.sb_mul(adx, adx), P.sb_mul(ady, ady)),
        P.sb_mul(adz, adz))
      +bq = P.sb_add(P.sb_add(P.sb_mul(bdx, bdx), P.sb_mul(bdy, bdy)),
        P.sb_mul(bdz, bdz))
      +cq = P.sb_add(P.sb_add(P.sb_mul(cdx, cdx), P.sb_mul(cdy, cdy)),
        P.sb_mul(cdz, cdz))
      +dq = P.sb_add(P.sb_add(P.sb_mul(ddx, ddx), P.sb_mul(ddy, ddy)),
        P.sb_mul(ddz, ddz))
      +m0 = e3_raw(bdy, bdz, bq, cdy, cdz, cq, ddy, ddz, dq)
      +m1 = e3_raw(bdx, bdz, bq, cdx, cdz, cq, ddx, ddz, dq)
      +m2 = e3_raw(bdx, bdy, bq, cdx, cdy, cq, ddx, ddy, dq)
      +m3 = e3_raw(bdx, bdy, bdz, cdx, cdy, cdz, ddx, ddy, ddz)
      +t0 = P.sb_mul(adx, m0)
      +t1 = P.sb_mul(ady, m1)
      +t2 = P.sb_mul(adz, m2)
      +t3 = P.sb_mul(aq, m3)
      P.pok(P.sb_sign(P.sb_sub(P.sb_add(P.sb_sub(t0, t1), t2), t3)))
    case False{}:
      P.perr(T.F_uncertain{})

def is_exact(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64,
    +bz: F64, +cx: F64, +cy: F64, +cz: F64, +dx: F64, +dy: F64,
    +dz: F64, +ex: F64, +ey: F64, +ez: F64) -> P.PRes:
  +xa = P.sint_of(ax, P.lim_is())
  +ya = P.sint_of(ay, P.lim_is())
  +za = P.sint_of(az, P.lim_is())
  +xb = P.sint_of(bx, P.lim_is())
  +yb = P.sint_of(by, P.lim_is())
  +zb = P.sint_of(bz, P.lim_is())
  +xc = P.sint_of(cx, P.lim_is())
  +yc = P.sint_of(cy, P.lim_is())
  +zc = P.sint_of(cz, P.lim_is())
  +xd = P.sint_of(dx, P.lim_is())
  +yd = P.sint_of(dy, P.lim_is())
  +zd = P.sint_of(dz, P.lim_is())
  +xe = P.sint_of(ex, P.lim_is())
  +ye = P.sint_of(ey, P.lim_is())
  +ze = P.sint_of(ez, P.lim_is())
  +ok = Bool.and(P.si_ok(xa),
    Bool.and(P.si_ok(ya),
      Bool.and(P.si_ok(za),
        Bool.and(P.si_ok(xb),
          Bool.and(P.si_ok(yb),
            Bool.and(P.si_ok(zb),
              Bool.and(P.si_ok(xc),
                Bool.and(P.si_ok(yc),
                  Bool.and(P.si_ok(zc),
                    Bool.and(P.si_ok(xd),
                      Bool.and(P.si_ok(yd),
                        Bool.and(P.si_ok(zd),
                          Bool.and(P.si_ok(xe),
                            Bool.and(P.si_ok(ye),
                              P.si_ok(ze)))))))))))))))
  is_exact_go(ok, xa, ya, za, xb, yb, zb, xc, yc, zc, xd, yd, zd, xe,
    ye, ze)

def is_bound(+det: F64, +ax: F64, +ay: F64, +az: F64, +bx: F64,
    +by: F64, +bz: F64, +cx: F64, +cy: F64, +cz: F64, +dx: F64,
    +dy: F64, +dz: F64, +ex: F64, +ey: F64, +ez: F64,
    big: Bool) -> P.PRes:
  match big:
    case True{}: P.pok(P.sign_of_f(det))
    case False{}: is_exact(ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy,
      dz, ex, ey, ez)

def is_short_n(+det: F64, +big: Bool, +ax: F64, +ay: F64, +az: F64,
    +bx: F64, +by: F64, +bz: F64, +cx: F64, +cy: F64, +cz: F64,
    +dx: F64, +dy: F64, +dz: F64, +ex: F64, +ey: F64, +ez: F64,
    nzero: Bool) -> P.PRes:
  match nzero:
    case True{}: P.pok(P.Sg_pos{})
    case False{}: is_bound(det, ax, ay, az, bx, by, bz, cx, cy, cz,
      dx, dy, dz, ex, ey, ez, big)

def is_short_p(+det: F64, +big: Bool, +ax: F64, +ay: F64, +az: F64,
    +bx: F64, +by: F64, +bz: F64, +cx: F64, +cy: F64, +cz: F64,
    +dx: F64, +dy: F64, +dz: F64, +ex: F64, +ey: F64, +ez: F64,
    pzero: Bool, nzero: Bool) -> P.PRes:
  match pzero:
    case True{}: P.pok(P.Sg_neg{})
    case False{}: is_short_n(det, big, ax, ay, az, bx, by, bz, cx,
      cy, cz, dx, dy, dz, ex, ey, ez, nzero)

def is_gate(+det: F64, +pzero: Bool, +nzero: Bool, +big: Bool,
    +ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64, +bz: F64,
    +cx: F64, +cy: F64, +cz: F64, +dx: F64, +dy: F64, +dz: F64,
    +ex: F64, +ey: F64, +ez: F64, gate: Bool) -> P.PRes:
  match gate:
    case True{}: is_short_p(det, big, ax, ay, az, bx, by, bz, cx, cy,
      cz, dx, dy, dz, ex, ey, ez, pzero, nzero)
    case False{}: is_exact(ax, ay, az, bx, by, bz, cx, cy, cz, dx,
      dy, dz, ex, ey, ez)

def is_run(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64,
    +bz: F64, +cx: F64, +cy: F64, +cz: F64, +dx: F64, +dy: F64,
    +dz: F64, +ex: F64, +ey: F64, +ez: F64) -> P.PRes:
  +adx = F64.sub(ax, ex)
  +ady = F64.sub(ay, ey)
  +adz = F64.sub(az, ez)
  +bdx = F64.sub(bx, ex)
  +bdy = F64.sub(by, ey)
  +bdz = F64.sub(bz, ez)
  +cdx = F64.sub(cx, ex)
  +cdy = F64.sub(cy, ey)
  +cdz = F64.sub(cz, ez)
  +ddx = F64.sub(dx, ex)
  +ddy = F64.sub(dy, ey)
  +ddz = F64.sub(dz, ez)
  +aq = is_sq(adx, ady, adz)
  +bq = is_sq(bdx, bdy, bdz)
  +cq = is_sq(cdx, cdy, cdz)
  +dq = is_sq(ddx, ddy, ddz)
  +m0 = d3_raw(bdy, bdz, bq, cdy, cdz, cq, ddy, ddz, dq)
  +m1 = d3_raw(bdx, bdz, bq, cdx, cdz, cq, ddx, ddz, dq)
  +m2 = d3_raw(bdx, bdy, bq, cdx, cdy, cq, ddx, ddy, dq)
  +m3 = d3_raw(bdx, bdy, bdz, cdx, cdy, cdz, ddx, ddy, ddz)
  +p0 = d3_pos(bdy, bdz, bq, cdy, cdz, cq, ddy, ddz, dq)
  +p1 = d3_pos(bdx, bdz, bq, cdx, cdz, cq, ddx, ddz, dq)
  +p2 = d3_pos(bdx, bdy, bq, cdx, cdy, cq, ddx, ddy, dq)
  +p3 = d3_pos(bdx, bdy, bdz, cdx, cdy, cdz, ddx, ddy, ddz)
  +n0 = d3_neg(bdy, bdz, bq, cdy, cdz, cq, ddy, ddz, dq)
  +n1 = d3_neg(bdx, bdz, bq, cdx, cdz, cq, ddx, ddz, dq)
  +n2 = d3_neg(bdx, bdy, bq, cdx, cdy, cq, ddx, ddy, dq)
  +n3 = d3_neg(bdx, bdy, bdz, cdx, cdy, cdz, ddx, ddy, ddz)
  +det = F64.sub(F64.add(F64.sub(F64.mul(adx, m0), F64.mul(ady, m1)),
    F64.mul(adz, m2)), F64.mul(aq, m3))
  +pp = F64.add(F64.add(F64.add(F64.mul(F64.abs(adx), p0),
    F64.mul(F64.abs(ady), p1)), F64.mul(F64.abs(adz), p2)),
    F64.mul(F64.abs(aq), p3))
  +nn = F64.add(F64.add(F64.add(F64.mul(F64.abs(adx), n0),
    F64.mul(F64.abs(ady), n1)), F64.mul(F64.abs(adz), n2)),
    F64.mul(F64.abs(aq), n3))
  +detsum = F64.add(pp, nn)
  +gate = Bool.and(T.is_finite(det),
    Bool.and(T.is_finite(pp),
      Bool.and(T.is_finite(nn),
        Bool.and(T.is_finite(detsum),
          F64.is_le(P.detmin(), detsum)))))
  +pzero = F64.is_eq(pp, 0.0f64)
  +nzero = F64.is_eq(nn, 0.0f64)
  +big = F64.is_lt(F64.mul(P.k_is(), detsum), F64.abs(det))
  is_gate(det, pzero, nzero, big, ax, ay, az, bx, by, bz, cx, cy, cz,
    dx, dy, dz, ex, ey, ez, gate)

def is_rep(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64,
    +bz: F64, +cx: F64, +cy: F64, +cz: F64, +dx: F64, +dy: F64,
    +dz: F64, +ex: F64, +ey: F64, +ez: F64, rep: Bool) -> P.PRes:
  match rep:
    case True{}: P.pok(P.Sg_zero{})
    case False{}: is_run(ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy,
      dz, ex, ey, ez)

def is_fin(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64,
    +bz: F64, +cx: F64, +cy: F64, +cz: F64, +dx: F64, +dy: F64,
    +dz: F64, +ex: F64, +ey: F64, +ez: F64, fin: Bool,
    rep: Bool) -> P.PRes:
  match fin:
    case True{}: is_rep(ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy,
      dz, ex, ey, ez, rep)
    case False{}: P.perr(T.F_invalid{})

def insphere(+a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point,
    +e: V.Point) -> P.PRes:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  V.Pt{+cx, +cy, +cz} = c
  V.Pt{+dx, +dy, +dz} = d
  V.Pt{+ex, +ey, +ez} = e
  +fin = Bool.and(T.is_finite(ax),
    Bool.and(T.is_finite(ay),
      Bool.and(T.is_finite(az),
        Bool.and(T.is_finite(bx),
          Bool.and(T.is_finite(by),
            Bool.and(T.is_finite(bz),
              Bool.and(T.is_finite(cx),
                Bool.and(T.is_finite(cy),
                  Bool.and(T.is_finite(cz),
                    Bool.and(T.is_finite(dx),
                      Bool.and(T.is_finite(dy),
                        Bool.and(T.is_finite(dz),
                          Bool.and(T.is_finite(ex),
                            Bool.and(T.is_finite(ey),
                              T.is_finite(ez)))))))))))))))
  +r12 = pteq3(ax, ay, az, bx, by, bz)
  +r13 = pteq3(ax, ay, az, cx, cy, cz)
  +r14 = pteq3(ax, ay, az, dx, dy, dz)
  +r15 = pteq3(ax, ay, az, ex, ey, ez)
  +r23 = pteq3(bx, by, bz, cx, cy, cz)
  +r24 = pteq3(bx, by, bz, dx, dy, dz)
  +r25 = pteq3(bx, by, bz, ex, ey, ez)
  +r34 = pteq3(cx, cy, cz, dx, dy, dz)
  +r35 = pteq3(cx, cy, cz, ex, ey, ez)
  +r45 = pteq3(dx, dy, dz, ex, ey, ez)
  +rep = Bool.or(r12,
    Bool.or(r13,
      Bool.or(r14,
        Bool.or(r15,
          Bool.or(r23,
            Bool.or(r24,
              Bool.or(r25,
                Bool.or(r34, Bool.or(r35, r45)))))))))
  is_fin(ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy, dz, ex, ey, ez,
    fin, rep)

# --- Segment-segment relation in 2D (exact comparisons throughout). ---
# o1..o4 are orient2d(a,b,c), (a,b,d), (c,d,a), (c,d,b). Zero signs are
# exact (exact paths only), and every comparison below (equality, bbox,
# 1D overlap) is exact on F64 values; the relation is therefore EXACT
# whenever the four orientations decide. First sub-failure in o1..o4
# order wins propagation. Degenerate point-segments are admitted:
# point-point equality is touch, point-on-segment is touch.
def seg_bbox(+ax: F64, +ay: F64, +bx: F64, +by: F64, +px: F64,
    +py: F64) -> Bool:
  +xok = Bool.and(F64.is_le(F64.min(ax, bx), px),
    F64.is_le(px, F64.max(ax, bx)))
  +yok = Bool.and(F64.is_le(F64.min(ay, by), py),
    F64.is_le(py, F64.max(ay, by)))
  Bool.and(xok, yok)

def seg_touch_go(on: Bool) -> P.Xres:
  match on:
    case True{}: P.xok(P.X_touch{})
    case False{}: P.xok(P.X_disjoint{})

def seg_coll_eq(eq: Bool) -> P.Xres:
  match eq:
    case True{}: P.xok(P.X_touch{})
    case False{}: P.xok(P.X_disjoint{})

def seg_coll_go(ov: Bool, eq: Bool) -> P.Xres:
  match ov:
    case True{}: P.xok(P.X_overlap{})
    case False{}: seg_coll_eq(eq)

# Collinear 1D overlap on the dominant axis of ab (exact endpoint
# comparisons; single-point contact is touch, positive length overlap).
def seg_coll(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64, +dx: F64, +dy: F64) -> P.Xres:
  +xdom = F64.is_le(F64.abs(F64.sub(ay, by)), F64.abs(F64.sub(ax,
    bx)))
  +ua = Bool.pick(F64, xdom, ax, ay)
  +ub = Bool.pick(F64, xdom, bx, by)
  +uc = Bool.pick(F64, xdom, cx, cy)
  +ud = Bool.pick(F64, xdom, dx, dy)
  +alo = F64.min(ua, ub)
  +ahi = F64.max(ua, ub)
  +clo = F64.min(uc, ud)
  +chi = F64.max(uc, ud)
  +maxlo = F64.max(alo, clo)
  +minhi = F64.min(ahi, chi)
  seg_coll_go(F64.is_lt(maxlo, minhi), F64.is_eq(maxlo, minhi))

def seg_ppeq_go(eq: Bool) -> P.Xres:
  match eq:
    case True{}: P.xok(P.X_touch{})
    case False{}: P.xok(P.X_disjoint{})

def seg_ppeq(+ax: F64, +ay: F64, +cx: F64, +cy: F64) -> P.Xres:
  seg_ppeq_go(pteq2(ax, ay, cx, cy))

def seg_abpt(+cdpt: Bool, +on3: Bool, +ax: F64, +ay: F64, +cx: F64,
    +cy: F64) -> P.Xres:
  match cdpt:
    case True{}: seg_ppeq(ax, ay, cx, cy)
    case False{}: seg_touch_go(on3)

def seg_coll1(+coll: Bool, +on_any: Bool, +ax: F64, +ay: F64,
    +bx: F64, +by: F64, +cx: F64, +cy: F64, +dx: F64,
    +dy: F64) -> P.Xres:
  match coll:
    case True{}: seg_coll(ax, ay, bx, by, cx, cy, dx, dy)
    case False{}: seg_touch_go(on_any)

def seg_pt2(+cdpt: Bool, +coll: Bool, +on1: Bool, +on_any: Bool,
    +ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64,
    +dx: F64, +dy: F64) -> P.Xres:
  match cdpt:
    case True{}: seg_touch_go(on1)
    case False{}: seg_coll1(coll, on_any, ax, ay, bx, by, cx, cy, dx,
      dy)

def seg_pt1(+abpt: Bool, +cdpt: Bool, +coll: Bool, +on1: Bool,
    +on3: Bool, +on_any: Bool, +ax: F64, +ay: F64, +bx: F64,
    +by: F64, +cx: F64, +cy: F64, +dx: F64, +dy: F64) -> P.Xres:
  match abpt:
    case True{}: seg_abpt(cdpt, on3, ax, ay, cx, cy)
    case False{}: seg_pt2(cdpt, coll, on1, on_any, ax, ay, bx, by, cx,
      cy, dx, dy)

def seg_case(+proper: Bool, +abpt: Bool, +cdpt: Bool, +coll: Bool,
    +on1: Bool, +on3: Bool, +on_any: Bool, +ax: F64, +ay: F64,
    +bx: F64, +by: F64, +cx: F64, +cy: F64, +dx: F64,
    +dy: F64) -> P.Xres:
  match proper:
    case True{}: P.xok(P.X_proper{})
    case False{}: seg_pt1(abpt, cdpt, coll, on1, on3, on_any, ax, ay,
      bx, by, cx, cy, dx, dy)

def seg_signs(+s1: P.Sign, +s2: P.Sign, +s3: P.Sign, +s4: P.Sign,
    +ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64,
    +dx: F64, +dy: F64) -> P.Xres:
  +n1 = P.sign_is_neg(s1)
  +p1 = P.sign_is_pos(s1)
  +z1 = P.sign_is_zero(s1)
  +n2 = P.sign_is_neg(s2)
  +p2 = P.sign_is_pos(s2)
  +z2 = P.sign_is_zero(s2)
  +n3 = P.sign_is_neg(s3)
  +p3 = P.sign_is_pos(s3)
  +z3 = P.sign_is_zero(s3)
  +n4 = P.sign_is_neg(s4)
  +p4 = P.sign_is_pos(s4)
  +z4 = P.sign_is_zero(s4)
  +o12 = Bool.or(Bool.and(n1, p2), Bool.and(p1, n2))
  +o34 = Bool.or(Bool.and(n3, p4), Bool.and(p3, n4))
  +proper = Bool.and(o12, o34)
  +coll = Bool.and(z1, z2)
  +abpt = pteq2(ax, ay, bx, by)
  +cdpt = pteq2(cx, cy, dx, dy)
  +on1 = Bool.and(z1, seg_bbox(ax, ay, bx, by, cx, cy))
  +on2 = Bool.and(z2, seg_bbox(ax, ay, bx, by, dx, dy))
  +on3 = Bool.and(z3, seg_bbox(cx, cy, dx, dy, ax, ay))
  +on4 = Bool.and(z4, seg_bbox(cx, cy, dx, dy, bx, by))
  +on_any = Bool.or(on1, Bool.or(on2, Bool.or(on3, on4)))
  seg_case(proper, abpt, cdpt, coll, on1, on3, on_any, ax, ay, bx,
    by, cx, cy, dx, dy)

def seg_prop4(+q4: Bool, +k4: T.FailKind, +s1: P.Sign, +s2: P.Sign,
    +s3: P.Sign, +s4: P.Sign, +ax: F64, +ay: F64, +bx: F64,
    +by: F64, +cx: F64, +cy: F64, +dx: F64, +dy: F64) -> P.Xres:
  match q4:
    case True{}: seg_signs(s1, s2, s3, s4, ax, ay, bx, by, cx, cy, dx,
      dy)
    case False{}: P.xerr(k4)

def seg_prop3(+q3: Bool, +k3: T.FailKind, +q4: Bool, +k4: T.FailKind,
    +s1: P.Sign, +s2: P.Sign, +s3: P.Sign, +s4: P.Sign, +ax: F64,
    +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64, +dx: F64,
    +dy: F64) -> P.Xres:
  match q3:
    case True{}: seg_prop4(q4, k4, s1, s2, s3, s4, ax, ay, bx, by, cx,
      cy, dx, dy)
    case False{}: P.xerr(k3)

def seg_prop2(+q2: Bool, +k2: T.FailKind, +q3: Bool, +k3: T.FailKind,
    +q4: Bool, +k4: T.FailKind, +s1: P.Sign, +s2: P.Sign,
    +s3: P.Sign, +s4: P.Sign, +ax: F64, +ay: F64, +bx: F64,
    +by: F64, +cx: F64, +cy: F64, +dx: F64, +dy: F64) -> P.Xres:
  match q2:
    case True{}: seg_prop3(q3, k3, q4, k4, s1, s2, s3, s4, ax, ay, bx,
      by, cx, cy, dx, dy)
    case False{}: P.xerr(k2)

def seg_prop(+q1: Bool, +k1: T.FailKind, +q2: Bool, +k2: T.FailKind,
    +q3: Bool, +k3: T.FailKind, +q4: Bool, +k4: T.FailKind,
    +s1: P.Sign, +s2: P.Sign, +s3: P.Sign, +s4: P.Sign, +ax: F64,
    +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64, +dx: F64,
    +dy: F64) -> P.Xres:
  match q1:
    case True{}: seg_prop2(q2, k2, q3, k3, q4, k4, s1, s2, s3, s4, ax,
      ay, bx, by, cx, cy, dx, dy)
    case False{}: P.xerr(k1)

def seg_run(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64, +dx: F64, +dy: F64) -> P.Xres:
  +o1 = orient2d(V.V2{ax, ay}, V.V2{bx, by}, V.V2{cx, cy})
  +o2 = orient2d(V.V2{ax, ay}, V.V2{bx, by}, V.V2{dx, dy})
  +o3 = orient2d(V.V2{cx, cy}, V.V2{dx, dy}, V.V2{ax, ay})
  +o4 = orient2d(V.V2{cx, cy}, V.V2{dx, dy}, V.V2{bx, by})
  +q1 = P.pres_ok(o1)
  +k1 = P.pres_kind(o1)
  +s1 = P.pres_sign(o1)
  +q2 = P.pres_ok(o2)
  +k2 = P.pres_kind(o2)
  +s2 = P.pres_sign(o2)
  +q3 = P.pres_ok(o3)
  +k3 = P.pres_kind(o3)
  +s3 = P.pres_sign(o3)
  +q4 = P.pres_ok(o4)
  +k4 = P.pres_kind(o4)
  +s4 = P.pres_sign(o4)
  seg_prop(q1, k1, q2, k2, q3, k3, q4, k4, s1, s2, s3, s4, ax, ay, bx,
    by, cx, cy, dx, dy)

def seg_fin(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64, +dx: F64, +dy: F64, fin: Bool) -> P.Xres:
  match fin:
    case True{}: seg_run(ax, ay, bx, by, cx, cy, dx, dy)
    case False{}: P.xerr(T.F_invalid{})

def seg_seg(+a: V.Vec2, +b: V.Vec2, +c: V.Vec2,
    +d: V.Vec2) -> P.Xres:
  V.V2{+ax, +ay} = a
  V.V2{+bx, +by} = b
  V.V2{+cx, +cy} = c
  V.V2{+dx, +dy} = d
  +fin = Bool.and(T.is_finite(ax),
    Bool.and(T.is_finite(ay),
      Bool.and(T.is_finite(bx),
        Bool.and(T.is_finite(by),
          Bool.and(T.is_finite(cx),
            Bool.and(T.is_finite(cy),
              Bool.and(T.is_finite(dx), T.is_finite(dy))))))))
  seg_fin(ax, ay, bx, by, cx, cy, dx, dy, fin)

# --- Point-in-triangle classification (exact on decided signs). ---
# o0 = orient2d(a,b,c) must be nonzero (degenerate triangle is
# invalid-input); o1..o3 = orient2d(a,b,p),(b,c,p),(c,a,p). With o0
# positive, p is inside iff no edge sign is neg, on the boundary iff
# inside-sided with a zero (a zero with the other signs inside-sided
# forces p onto that edge segment — no bbox needed), else outside;
# mirrored for o0 negative. First sub-failure wins propagation.
def tri_inb(anyz: Bool) -> P.Tres:
  match anyz:
    case True{}: P.tok(P.T_bound{})
    case False{}: P.tok(P.T_in{})

def tri_decide(bad: Bool, anyz: Bool) -> P.Tres:
  match bad:
    case True{}: P.tok(P.T_out{})
    case False{}: tri_inb(anyz)

def tri_signs(+s1: P.Sign, +s2: P.Sign, +s3: P.Sign,
    +o0neg: Bool) -> P.Tres:
  +n1 = P.sign_is_neg(s1)
  +p1 = P.sign_is_pos(s1)
  +z1 = P.sign_is_zero(s1)
  +n2 = P.sign_is_neg(s2)
  +p2 = P.sign_is_pos(s2)
  +z2 = P.sign_is_zero(s2)
  +n3 = P.sign_is_neg(s3)
  +p3 = P.sign_is_pos(s3)
  +z3 = P.sign_is_zero(s3)
  +pp = Bool.or(p1, Bool.or(p2, p3))
  +nn = Bool.or(n1, Bool.or(n2, n3))
  +bad = Bool.or(Bool.and(o0neg, pp), Bool.and(Bool.not(o0neg), nn))
  +anyz = Bool.or(z1, Bool.or(z2, z3))
  tri_decide(bad, anyz)

def tri_prop3(+q3: Bool, +k3: T.FailKind, +s1: P.Sign, +s2: P.Sign,
    +s3: P.Sign, +o0neg: Bool) -> P.Tres:
  match q3:
    case True{}: tri_signs(s1, s2, s3, o0neg)
    case False{}: P.terr(k3)

def tri_prop2(+q2: Bool, +k2: T.FailKind, +q3: Bool, +k3: T.FailKind,
    +s1: P.Sign, +s2: P.Sign, +s3: P.Sign, +o0neg: Bool) -> P.Tres:
  match q2:
    case True{}: tri_prop3(q3, k3, s1, s2, s3, o0neg)
    case False{}: P.terr(k2)

def tri_prop(+q1: Bool, +k1: T.FailKind, +q2: Bool, +k2: T.FailKind,
    +q3: Bool, +k3: T.FailKind, +s1: P.Sign, +s2: P.Sign,
    +s3: P.Sign, +o0neg: Bool) -> P.Tres:
  match q1:
    case True{}: tri_prop2(q2, k2, q3, k3, s1, s2, s3, o0neg)
    case False{}: P.terr(k1)

def tri_edges(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64,
    +by: F64, +cx: F64, +cy: F64, +o0neg: Bool) -> P.Tres:
  +o1 = orient2d(V.V2{ax, ay}, V.V2{bx, by}, V.V2{px, py})
  +o2 = orient2d(V.V2{bx, by}, V.V2{cx, cy}, V.V2{px, py})
  +o3 = orient2d(V.V2{cx, cy}, V.V2{ax, ay}, V.V2{px, py})
  +q1 = P.pres_ok(o1)
  +k1 = P.pres_kind(o1)
  +s1 = P.pres_sign(o1)
  +q2 = P.pres_ok(o2)
  +k2 = P.pres_kind(o2)
  +s2 = P.pres_sign(o2)
  +q3 = P.pres_ok(o3)
  +k3 = P.pres_kind(o3)
  +s3 = P.pres_sign(o3)
  tri_prop(q1, k1, q2, k2, q3, k3, s1, s2, s3, o0neg)

def tri_o0_sign(+s0: P.Sign, +px: F64, +py: F64, +ax: F64,
    +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64) -> P.Tres:
  match s0:
    case P.Sg_zero{}: P.terr(T.F_invalid{})
    case P.Sg_neg{}: tri_edges(px, py, ax, ay, bx, by, cx, cy, True{})
    case P.Sg_pos{}: tri_edges(px, py, ax, ay, bx, by, cx, cy,
      False{})

def tri_o0_go(+q0: Bool, +k0: T.FailKind, +s0: P.Sign, +px: F64,
    +py: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64) -> P.Tres:
  match q0:
    case True{}: tri_o0_sign(s0, px, py, ax, ay, bx, by, cx, cy)
    case False{}: P.terr(k0)

def tri_o0(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64,
    +by: F64, +cx: F64, +cy: F64) -> P.Tres:
  +o0 = orient2d(V.V2{ax, ay}, V.V2{bx, by}, V.V2{cx, cy})
  +q0 = P.pres_ok(o0)
  +k0 = P.pres_kind(o0)
  +s0 = P.pres_sign(o0)
  tri_o0_go(q0, k0, s0, px, py, ax, ay, bx, by, cx, cy)

def tri_fin(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64,
    +by: F64, +cx: F64, +cy: F64, fin: Bool) -> P.Tres:
  match fin:
    case True{}: tri_o0(px, py, ax, ay, bx, by, cx, cy)
    case False{}: P.terr(T.F_invalid{})

def tri_class(+p: V.Vec2, +a: V.Vec2, +b: V.Vec2,
    +c: V.Vec2) -> P.Tres:
  V.V2{+px, +py} = p
  V.V2{+ax, +ay} = a
  V.V2{+bx, +by} = b
  V.V2{+cx, +cy} = c
  +fin = Bool.and(T.is_finite(px),
    Bool.and(T.is_finite(py),
      Bool.and(T.is_finite(ax),
        Bool.and(T.is_finite(ay),
          Bool.and(T.is_finite(bx),
            Bool.and(T.is_finite(by),
              Bool.and(T.is_finite(cx), T.is_finite(cy))))))))
  tri_fin(px, py, ax, ay, bx, by, cx, cy, fin)



