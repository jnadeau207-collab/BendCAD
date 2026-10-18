import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c06/iv.bend as I
import ../c06/model.bend as M
import ../c06/build.bend as BD
import ../c06/sx.bend as S
import ../k1/sf.bend as KS
import ../k1/fb.bend as FB

type TR is Data:
  TR{ k: U64, ax: F64, ay: F64, bx: F64, by: F64, r: F64, t0: F64, t1: F64, z0: F64, z1: F64, ex: Bool }

type DI is Data:
  DI{ lo: F64, hi: F64 }

type TL is Data:
  TL{ ok: Bool, why: String, ts: List<&2, TR> }

type BX is Data:
  BX{ m: V.Mat3, tx: F64, ty: F64, tz: F64, b: Ty.Brep }

type TF is Data:
  TF{ code: U64, tr: TR }

type FP is Data:
  FP{ ps: List<&2, V.Point>, curved: Bool, ncs: Nat }

type MG is Data:
  MG{ a: List<&2, TR>, b: List<&2, TR>, ax: F64, ay: F64, bx: F64, by: F64, k: F64, l: F64 }

def inf() -> F64:
  F64.div(1.0f64, 0.0f64)

def di_min(+a: DI, +b: DI) -> DI:
  DI{+al, +ah} = a
  DI{+bl, +bh} = b
  DI{F64.min(al, bl), F64.min(ah, bh)}

def di_lo(+a: DI) -> F64:
  DI{+l, +h} = a
  l

def di_hi(+a: DI) -> F64:
  DI{+l, +h} = a
  h

def iv2(+x: F64, +y: F64) -> I.I:
  I.iadd(I.isq(I.ipt(x)), I.isq(I.ipt(y)))

def ilen(+x: F64, +y: F64) -> I.I:
  I.isqrt(iv2(x, y))

def iabs(+a: I.I) -> I.I:
  Bool.pick(I.I, F64.is_le(0.0f64, I.i_lo(a)), a, Bool.pick(I.I, F64.is_le(I.i_hi(a), 0.0f64), I.ineg(a),
    I.I{0.0f64, F64.max(F64.neg(I.i_lo(a)), I.i_hi(a))}))

def eps_of(+x: F64) -> F64:
  F64.mul(1.0e-12f64, F64.add(1.0f64, F64.abs(x)))

def di_of(+a: I.I, +e: F64) -> DI:
  DI{F64.max(0.0f64, F64.sub(I.i_lo(a), e)), F64.add(I.i_hi(a), e)}

def pp(+ax: F64, +ay: F64, +bx: F64, +by: F64, +e: F64) -> DI:
  di_of(ilen(F64.sub(bx, ax), F64.sub(by, ay)), e)

def tr_k(+t: TR) -> U64:
  TR{+k, +ax, +ay, +bx, +by, +r, +t0, +t1, +z0, +z1, +xe} = t
  k

def in_rng(+t: F64, +t0: F64, +t1: F64, +tol: F64) -> Bool:
  +full = F64.is_le(F64.sub(KS.two_pi(), 1.0e-9f64), F64.sub(t1, t0))
  +u = F64.add(t0, KS.wrap_to(F64.sub(t, t0), F64.neg(tol)))
  Bool.or(full, F64.is_le(u, F64.add(t1, tol)))

def pt_seg(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> DI:
  +ex = F64.sub(bx, ax)
  +ey = F64.sub(by, ay)
  +dx = F64.sub(px, ax)
  +dy = F64.sub(py, ay)
  +l2 = F64.add(F64.mul(ex, ex), F64.mul(ey, ey))
  +t = F64.div(F64.add(F64.mul(dx, ex), F64.mul(dy, ey)), l2)
  +e = eps_of(F64.max(F64.max(F64.abs(px), F64.abs(py)), F64.max(F64.abs(ax), F64.abs(bx))))
  +ends = di_min(pp(px, py, ax, ay, e), pp(px, py, bx, by, e))
  +cr = I.isub(I.imul(I.ipt(ex), I.ipt(dy)), I.imul(I.ipt(ey), I.ipt(dx)))
  +line = di_of(I.idiv(iabs(cr), I.isqrt(iv2(ex, ey))), e)
  +maybe = Bool.and(F64.is_le(F64.neg(1.0e-9f64), t), F64.is_le(t, F64.add(1.0f64, 1.0e-9f64)))
  +sure = Bool.and(F64.is_lt(1.0e-9f64, t), F64.is_lt(t, F64.sub(1.0f64, 1.0e-9f64)))
  DI{Bool.pick(F64, maybe, F64.min(di_lo(line), di_lo(ends)), di_lo(ends)),
    Bool.pick(F64, sure, F64.min(di_hi(line), di_hi(ends)), di_hi(ends))}

def arc_end(+cx: F64, +cy: F64, +r: F64, +t: F64) -> V.Vec2:
  V.V2{F64.add(cx, F64.mul(r, KS.fcos(t))), F64.add(cy, F64.mul(r, KS.fsin(t)))}

def pt_arc(+px: F64, +py: F64, +cx: F64, +cy: F64, +r: F64, +t0: F64, +t1: F64) -> DI:
  +e = F64.mul(4.0f64, eps_of(F64.add(F64.add(F64.abs(cx), F64.abs(cy)), r)))
  +th = KS.fatan2(F64.sub(py, cy), F64.sub(px, cx))
  +circ = di_of(iabs(I.isub(ilen(F64.sub(px, cx), F64.sub(py, cy)), I.ipt(r))), e)
  +pa = arc_end(cx, cy, r, t0)
  +pb = arc_end(cx, cy, r, t1)
  +ends = di_min(pp(px, py, V.v2_x(pa), V.v2_y(pa), e), pp(px, py, V.v2_x(pb), V.v2_y(pb), e))
  +maybe = in_rng(th, t0, t1, 1.0e-9f64)
  +sure = in_rng(th, t0, t1, F64.neg(1.0e-9f64))
  DI{Bool.pick(F64, maybe, F64.min(di_lo(circ), di_lo(ends)), di_lo(ends)), Bool.pick(F64, sure, F64.min(di_hi(circ), di_hi(ends)), di_hi(ends))}

def orient(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64) -> F64:
  F64.sub(F64.mul(F64.sub(bx, ax), F64.sub(cy, ay)), F64.mul(F64.sub(by, ay), F64.sub(cx, ax)))

def cross_maybe(+a1x: F64, +a1y: F64, +b1x: F64, +b1y: F64, +a2x: F64, +a2y: F64, +b2x: F64, +b2y: F64, +tol: F64) -> Bool:
  +o1 = orient(a1x, a1y, b1x, b1y, a2x, a2y)
  +o2 = orient(a1x, a1y, b1x, b1y, b2x, b2y)
  +o3 = orient(a2x, a2y, b2x, b2y, a1x, a1y)
  +o4 = orient(a2x, a2y, b2x, b2y, b1x, b1y)
  Bool.and(F64.is_le(F64.mul(o1, o2), tol), F64.is_le(F64.mul(o3, o4), tol))

def cross_sure(+a1x: F64, +a1y: F64, +b1x: F64, +b1y: F64, +a2x: F64, +a2y: F64, +b2x: F64, +b2y: F64, +tol: F64) -> Bool:
  +o1 = orient(a1x, a1y, b1x, b1y, a2x, a2y)
  +o2 = orient(a1x, a1y, b1x, b1y, b2x, b2y)
  +o3 = orient(a2x, a2y, b2x, b2y, a1x, a1y)
  +o4 = orient(a2x, a2y, b2x, b2y, b1x, b1y)
  Bool.and(F64.is_lt(F64.mul(o1, o2), F64.neg(tol)), F64.is_lt(F64.mul(o3, o4), F64.neg(tol)))

def seg_seg(+t: TR, +u: TR) -> DI:
  TR{+k, +ax, +ay, +bx, +by, +r, +t0, +t1, +z0, +z1, +xe} = t
  TR{+k2, +cx, +cy, +dx, +dy, +r2, +s0, +s1, +w0, +w1, +ye} = u
  +tol = F64.mul(1.0e-12f64, F64.add(1.0f64, F64.mul(F64.add(F64.abs(ax), F64.abs(bx)), F64.add(F64.abs(cx), F64.abs(dx)))))
  +m = di_min(di_min(pt_seg(ax, ay, cx, cy, dx, dy), pt_seg(bx, by, cx, cy, dx, dy)),
    di_min(pt_seg(cx, cy, ax, ay, bx, by), pt_seg(dx, dy, ax, ay, bx, by)))
  DI{Bool.pick(F64, cross_maybe(ax, ay, bx, by, cx, cy, dx, dy, tol), 0.0f64, di_lo(m)),
    Bool.pick(F64, cross_sure(ax, ay, bx, by, cx, cy, dx, dy, tol), 0.0f64, di_hi(m))}

def root_t(+ax: F64, +ay: F64, +ex: F64, +ey: F64, +cx: F64, +cy: F64, +r: F64, +plus: Bool) -> F64:
  +fx = F64.sub(ax, cx)
  +fy = F64.sub(ay, cy)
  +qa = F64.add(F64.mul(ex, ex), F64.mul(ey, ey))
  +qb = F64.mul(2.0f64, F64.add(F64.mul(fx, ex), F64.mul(fy, ey)))
  +qc = F64.sub(F64.add(F64.mul(fx, fx), F64.mul(fy, fy)), F64.mul(r, r))
  +dd = F64.sub(F64.mul(qb, qb), F64.mul(4.0f64, F64.mul(qa, qc)))
  Bool.pick(F64, F64.is_lt(dd, 0.0f64), F64.nan(),
    F64.div(F64.add(F64.neg(qb), Bool.pick(F64, plus, F64.sqrt(dd), F64.neg(F64.sqrt(dd)))), F64.mul(2.0f64, qa)))

def hit_arc(+t: F64, +ax: F64, +ay: F64, +ex: F64, +ey: F64, +cx: F64, +cy: F64, +t0: F64, +t1: F64, +tol: F64) -> Bool:
  +px = F64.add(ax, F64.mul(t, ex))
  +py = F64.add(ay, F64.mul(t, ey))
  Bool.and(Bool.and(F64.is_le(F64.neg(tol), t), F64.is_le(t, F64.add(1.0f64, tol))), in_rng(KS.fatan2(F64.sub(py, cy), F64.sub(px, cx)), t0, t1, tol))

def seg_arc(+s: TR, +a: TR) -> DI:
  TR{+k, +ax, +ay, +bx, +by, +r0, +q0, +q1, +z0, +z1, +xe} = s
  TR{+k2, +cx, +cy, +dx, +dy, +r, +t0, +t1, +w0, +w1, +ye} = a
  +ex = F64.sub(bx, ax)
  +ey = F64.sub(by, ay)
  +pa = arc_end(cx, cy, r, t0)
  +pb = arc_end(cx, cy, r, t1)
  +ends = di_min(di_min(pt_arc(ax, ay, cx, cy, r, t0, t1), pt_arc(bx, by, cx, cy, r, t0, t1)),
    di_min(pt_seg(V.v2_x(pa), V.v2_y(pa), ax, ay, bx, by), pt_seg(V.v2_x(pb), V.v2_y(pb), ax, ay, bx, by)))
  +l2 = F64.add(F64.mul(ex, ex), F64.mul(ey, ey))
  +tf = F64.div(F64.add(F64.mul(F64.sub(cx, ax), ex), F64.mul(F64.sub(cy, ay), ey)), l2)
  +e = F64.mul(4.0f64, eps_of(F64.add(F64.add(F64.abs(cx), F64.abs(cy)), F64.add(r, F64.add(F64.abs(ax), F64.abs(bx))))))
  +cr = I.isub(I.imul(I.ipt(ex), I.ipt(F64.sub(cy, ay))), I.imul(I.ipt(ey), I.ipt(F64.sub(cx, ax))))
  +h = I.idiv(iabs(cr), I.isqrt(iv2(ex, ey)))
  +foot = di_of(iabs(I.isub(h, I.ipt(r))), e)
  +fin = hit_arc(tf, ax, ay, ex, ey, cx, cy, t0, t1, 1.0e-9f64)
  +fsure = Bool.and(hit_arc(tf, ax, ay, ex, ey, cx, cy, t0, t1, F64.neg(1.0e-9f64)), F64.is_le(0.0f64, I.i_lo(I.isub(h, I.ipt(r)))))
  +ta = root_t(ax, ay, ex, ey, cx, cy, r, True{})
  +tb = root_t(ax, ay, ex, ey, cx, cy, r, False{})
  +hits = Bool.or(hit_arc(ta, ax, ay, ex, ey, cx, cy, t0, t1, 1.0e-9f64), hit_arc(tb, ax, ay, ex, ey, cx, cy, t0, t1, 1.0e-9f64))
  +hsure = Bool.or(hit_arc(ta, ax, ay, ex, ey, cx, cy, t0, t1, F64.neg(1.0e-6f64)), hit_arc(tb, ax, ay, ex, ey, cx, cy, t0, t1, F64.neg(1.0e-6f64)))
  +lo1 = Bool.pick(F64, fin, F64.min(di_lo(foot), di_lo(ends)), di_lo(ends))
  +hi1 = Bool.pick(F64, fsure, F64.min(di_hi(foot), di_hi(ends)), di_hi(ends))
  DI{Bool.pick(F64, hits, 0.0f64, lo1), Bool.pick(F64, hsure, 0.0f64, hi1)}

def circ_hit(+c1x: F64, +c1y: F64, +r1: F64, +a0: F64, +a1: F64, +c2x: F64, +c2y: F64, +r2: F64, +b0: F64, +b1: F64,
    +tol: F64, +sgn: F64) -> Bool:
  +dx = F64.sub(c2x, c1x)
  +dy = F64.sub(c2y, c1y)
  +d = F64.sqrt(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)))
  +x = F64.div(F64.add(F64.mul(d, d), F64.sub(F64.mul(r1, r1), F64.mul(r2, r2))), F64.mul(2.0f64, d))
  +y2 = F64.sub(F64.mul(r1, r1), F64.mul(x, x))
  +y = F64.mul(sgn, F64.sqrt(F64.max(0.0f64, y2)))
  +px = F64.add(c1x, F64.div(F64.sub(F64.mul(x, dx), F64.mul(y, dy)), d))
  +py = F64.add(c1y, F64.div(F64.add(F64.mul(x, dy), F64.mul(y, dx)), d))
  Bool.and(F64.is_le(F64.neg(tol), y2), Bool.and(in_rng(KS.fatan2(F64.sub(py, c1y), F64.sub(px, c1x)), a0, a1, tol),
    in_rng(KS.fatan2(F64.sub(py, c2y), F64.sub(px, c2x)), b0, b1, tol)))

def line_cand(+c1x: F64, +c1y: F64, +r1: F64, +a0: F64, +a1: F64, +c2x: F64, +c2y: F64, +r2: F64, +b0: F64, +b1: F64,
    +s1: F64, +s2: F64, +e: F64) -> DI:
  +dx = F64.sub(c2x, c1x)
  +dy = F64.sub(c2y, c1y)
  +th = KS.fatan2(dy, dx)
  +t1 = Bool.pick(F64, F64.is_lt(0.0f64, s1), th, F64.add(th, KS.pi()))
  +t2 = Bool.pick(F64, F64.is_lt(0.0f64, s2), F64.add(th, KS.pi()), th)
  +d = ilen(dx, dy)
  +v = di_of(iabs(I.isub(I.isub(d, I.imul(I.ipt(s1), I.ipt(r1))), I.imul(I.ipt(s2), I.ipt(r2)))), e)
  +maybe = Bool.and(in_rng(t1, a0, a1, 1.0e-9f64), in_rng(t2, b0, b1, 1.0e-9f64))
  +sure = Bool.and(in_rng(t1, a0, a1, F64.neg(1.0e-9f64)), in_rng(t2, b0, b1, F64.neg(1.0e-9f64)))
  DI{Bool.pick(F64, maybe, di_lo(v), inf()), Bool.pick(F64, sure, di_hi(v), inf())}

def aa_ends(+cx: F64, +cy: F64, +r: F64, +t0: F64, +t1: F64, +ex: F64, +ey: F64, +q: F64, +s0: F64, +s1: F64) -> DI:
  +pa = arc_end(cx, cy, r, t0)
  +pb = arc_end(cx, cy, r, t1)
  +qa = arc_end(ex, ey, q, s0)
  +qb = arc_end(ex, ey, q, s1)
  di_min(di_min(pt_arc(V.v2_x(pa), V.v2_y(pa), ex, ey, q, s0, s1), pt_arc(V.v2_x(pb), V.v2_y(pb), ex, ey, q, s0, s1)),
    di_min(pt_arc(V.v2_x(qa), V.v2_y(qa), cx, cy, r, t0, t1), pt_arc(V.v2_x(qb), V.v2_y(qb), cx, cy, r, t0, t1)))

def aa_line(+cx: F64, +cy: F64, +r: F64, +t0: F64, +t1: F64, +ex: F64, +ey: F64, +q: F64, +s0: F64, +s1: F64, +e: F64) -> DI:
  di_min(di_min(line_cand(cx, cy, r, t0, t1, ex, ey, q, s0, s1, 1.0f64, 1.0f64, e), line_cand(cx, cy, r, t0, t1, ex, ey, q, s0, s1, 1.0f64, F64.neg(1.0f64), e)),
    line_cand(cx, cy, r, t0, t1, ex, ey, q, s0, s1, F64.neg(1.0f64), 1.0f64, e))

def aa_hit(+cx: F64, +cy: F64, +r: F64, +t0: F64, +t1: F64, +ex: F64, +ey: F64, +q: F64, +s0: F64, +s1: F64, +tol: F64) -> Bool:
  Bool.or(circ_hit(cx, cy, r, t0, t1, ex, ey, q, s0, s1, tol, 1.0f64), circ_hit(cx, cy, r, t0, t1, ex, ey, q, s0, s1, tol, F64.neg(1.0f64)))

def aa_gen(+m: DI, +hit: Bool, +hsure: Bool) -> DI:
  DI{Bool.pick(F64, hit, 0.0f64, di_lo(m)), Bool.pick(F64, hsure, 0.0f64, di_hi(m))}

def aa_same(+ends: DI, +dr: F64, +e: F64, +ov: Bool) -> DI:
  DI{F64.min(F64.max(0.0f64, F64.sub(dr, e)), di_lo(ends)), F64.min(di_hi(ends), Bool.pick(F64, ov, F64.add(dr, e), inf()))}

def arc_arc(+a: TR, +b: TR) -> DI:
  TR{+k, +cx, +cy, +dx0, +dy0, +r, +t0, +t1, +z0, +z1, +xe} = a
  TR{+k2, +ex, +ey, +fx0, +fy0, +q, +s0, +s1, +w0, +w1, +ye} = b
  +e = F64.mul(8.0f64, eps_of(F64.add(F64.add(F64.abs(cx), F64.abs(ex)), F64.add(F64.add(F64.abs(cy), F64.abs(ey)), F64.add(r, q)))))
  +ends = aa_ends(cx, cy, r, t0, t1, ex, ey, q, s0, s1)
  +same = Bool.and(F64.is_eq(cx, ex), F64.is_eq(cy, ey))
  +ov = Bool.or(in_rng(t0, s0, s1, F64.neg(1.0e-9f64)), in_rng(s0, t0, t1, F64.neg(1.0e-9f64)))
  Bool.pick(DI, same, aa_same(ends, F64.abs(F64.sub(r, q)), e, ov),
    aa_gen(di_min(ends, aa_line(cx, cy, r, t0, t1, ex, ey, q, s0, s1, e)), aa_hit(cx, cy, r, t0, t1, ex, ey, q, s0, s1, 1.0e-9f64),
      aa_hit(cx, cy, r, t0, t1, ex, ey, q, s0, s1, F64.neg(1.0e-6f64))))

def tr_z0(+t: TR) -> F64:
  TR{+k, +ax, +ay, +bx, +by, +r, +t0, +t1, +z0, +z1, +xe} = t
  z0

def tr_z1(+t: TR) -> F64:
  TR{+k, +ax, +ay, +bx, +by, +r, +t0, +t1, +z0, +z1, +xe} = t
  z1

def tr_dk(+code: U64, +a: TR, +b: TR) -> DI:
  match code:
    case 0u64: DI{inf(), inf()}
    case 1u64: seg_seg(a, b)
    case 2u64: seg_arc(a, b)
    case 3u64: seg_arc(b, a)
    case _: arc_arc(a, b)

def tr_ex(+t: TR) -> Bool:
  TR{+k, +ax, +ay, +bx, +by, +r, +t0, +t1, +z0, +z1, +xe} = t
  xe

def tr_d(+a: TR, +b: TR) -> DI:
  +zo = F64.is_lt(F64.add(F64.max(tr_z0(a), tr_z0(b)), 1.0e-9f64), F64.min(tr_z1(a), tr_z1(b)))
  +ka = tr_k(a)
  +kb = tr_k(b)
  +d = tr_dk(Bool.pick(U64, Bool.not(zo), 0u64, Bool.pick(U64, Bool.and(U64.is_eq(ka, 1u64), U64.is_eq(kb, 1u64)), 1u64,
    Bool.pick(U64, U64.is_eq(ka, 1u64), 2u64, Bool.pick(U64, U64.is_eq(kb, 1u64), 3u64, 4u64)))), a, b)
  DI{di_lo(d), Bool.pick(F64, Bool.and(tr_ex(a), tr_ex(b)), di_hi(d), inf())}

def tr_box(+t: TR) -> List<&2, F64>:
  TR{+k, +ax, +ay, +bx, +by, +r, +t0, +t1, +z0, +z1, +xe} = t
  Bool.pick(List<&2, F64>, U64.is_eq(k, 1u64), [F64.min(ax, bx), F64.max(ax, bx), F64.min(ay, by), F64.max(ay, by)],
    [F64.sub(ax, r), F64.add(ax, r), F64.sub(ay, r), F64.add(ay, r)])

def f4(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: 0.0f64
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: f4(t, j)

def box_gap(+p: List<&2, F64>, +q: List<&2, F64>) -> F64:
  +gx = F64.max(0.0f64, F64.max(F64.sub(f4(q, 0n), f4(p, 1n)), F64.sub(f4(p, 0n), f4(q, 1n))))
  +gy = F64.max(0.0f64, F64.max(F64.sub(f4(q, 2n), f4(p, 3n)), F64.sub(f4(p, 2n), f4(q, 3n))))
  F64.mul(F64.sqrt(F64.add(F64.mul(gx, gx), F64.mul(gy, gy))), F64.sub(1.0f64, 1.0e-9f64))

def d_pair(+far: Bool, +a: TR, +h: TR, +acc: DI) -> DI:
  match far:
    case True{}: acc
    case False{}: di_min(acc, tr_d(a, h))

def d_one(+a: TR, +ba: List<&2, F64>, bs: List<&2, TR>, +acc: DI) -> DI:
  match bs:
    case []: acc
    case +h <> +t: d_one(a, ba, t, d_pair(F64.is_lt(di_hi(acc), box_gap(ba, tr_box(h))), a, h, acc))

def d_all(as: List<&2, TR>, +bs: List<&2, TR>, +acc: DI) -> DI:
  match as:
    case []: acc
    case +h <> +t: d_all(t, bs, d_one(h, tr_box(h), bs, acc))

def wpt(+m: V.Mat3, +tx: F64, +ty: F64, +tz: F64, +p: V.Point) -> V.Point:
  V.M3{+a, +b, +c, +e, +f, +g, +h, +i, +j} = m
  +x = V.pt_x(p)
  +y = V.pt_y(p)
  +z = V.pt_z(p)
  V.Pt{F64.add(F64.add(F64.add(F64.mul(a, x), F64.mul(b, y)), F64.mul(c, z)), tx),
    F64.add(F64.add(F64.add(F64.mul(e, x), F64.mul(f, y)), F64.mul(g, z)), ty),
    F64.add(F64.add(F64.add(F64.mul(h, x), F64.mul(i, y)), F64.mul(j, z)), tz)}

def wdr(+m: V.Mat3, +d: V.Dir) -> V.Dir:
  V.M3{+a, +b, +c, +e, +f, +g, +h, +i, +j} = m
  V.Dr{F64.add(F64.add(F64.mul(a, V.dr_x(d)), F64.mul(b, V.dr_y(d))), F64.mul(c, V.dr_z(d))),
    F64.add(F64.add(F64.mul(e, V.dr_x(d)), F64.mul(f, V.dr_y(d))), F64.mul(g, V.dr_z(d))),
    F64.add(F64.add(F64.mul(h, V.dr_x(d)), F64.mul(i, V.dr_y(d))), F64.mul(j, V.dr_z(d)))}

def bx_of(+b: M.Body) -> BX:
  +pl = M.bd_pl(b)
  BX{M.pl_m(pl), M.pl_tx(pl), M.pl_ty(pl), M.pl_tz(pl), M.bd_brep(b)}

def bx_pt(+x: BX, +p: V.Point) -> V.Point:
  BX{+m, +tx, +ty, +tz, +b} = x
  wpt(m, tx, ty, tz, p)

def bx_dr(+x: BX, +d: V.Dir) -> V.Dir:
  BX{+m, +tx, +ty, +tz, +b} = x
  wdr(m, d)

def bx_b(+x: BX) -> Ty.Brep:
  BX{+m, +tx, +ty, +tz, +b} = x
  b

def zr(ps: List<&2, V.Point>, +acc: V.Vec2) -> V.Vec2:
  match ps:
    case []: acc
    case +h <> +t: zr(t, V.V2{F64.min(V.v2_x(acc), V.pt_z(h)), F64.max(V.v2_y(acc), V.pt_z(h))})

def sr(ps: List<&2, V.Point>, +hx: F64, +hy: F64, +acc: V.Vec2) -> V.Vec2:
  match ps:
    case []: acc
    case +h <> +t:
      +v = F64.add(F64.mul(V.pt_x(h), hx), F64.mul(V.pt_y(h), hy))
      sr(t, hx, hy, V.V2{F64.min(V.v2_x(acc), v), F64.max(V.v2_y(acc), v)})

def big() -> V.Vec2:
  V.V2{inf(), F64.neg(inf())}

def bb_pts(+bb: FB.BB, +x: BX, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  FB.BB{+x0, +x1, +y0, +y1, +z0, +z1} = bb
  bx_pt(x, V.Pt{x0, y0, z0}) <> bx_pt(x, V.Pt{x1, y0, z0}) <> bx_pt(x, V.Pt{x0, y1, z0}) <> bx_pt(x, V.Pt{x1, y1, z0}) <>
    bx_pt(x, V.Pt{x0, y0, z1}) <> bx_pt(x, V.Pt{x1, y0, z1}) <> bx_pt(x, V.Pt{x0, y1, z1}) <> bx_pt(x, V.Pt{x1, y1, z1}) <> acc

def fp_ce(cs: List<&2, FB.CE>, +x: BX, +acc: FP) -> FP:
  match cs:
    case []: acc
    case +h <> +t:
      FP{+ps, +cv, +n} = acc
      +b = bx_b(x)
      +k = Ty.ed_kind(FB.edge_at(b, FB.ce_e(h)))
      +ln = FB.is_line(k)
      +ed = FB.edge_at(b, FB.ce_e(h))
      +nps = Bool.pick(List<&2, V.Point>, ln, bx_pt(x, FB.vpt(b, Ty.ed_v0(ed))) <> bx_pt(x, FB.vpt(b, Ty.ed_v1(ed))) <> ps, bb_pts(FB.ek_bb(k), x, ps))
      fp_ce(t, x, FP{nps, Bool.or(cv, Bool.not(ln)), Nat.add(n, 1n)})

def fp_ls(ls: List<&2, List<&2, FB.CE>>, +x: BX, +acc: FP) -> FP:
  match ls:
    case []: acc
    case +h <> +t: fp_ls(t, x, fp_ce(h, x, acc))

def ang_rng(ps: List<&2, V.Point>, +cx: F64, +cy: F64, +ref: F64, +acc: V.Vec2) -> V.Vec2:
  match ps:
    case []: acc
    case +h <> +t:
      +a = F64.add(ref, KS.wrap_to(F64.sub(KS.fatan2(F64.sub(V.pt_y(h), cy), F64.sub(V.pt_x(h), cx)), ref), F64.neg(KS.pi())))
      ang_rng(t, cx, cy, ref, V.V2{F64.min(V.v2_x(acc), a), F64.max(V.v2_y(acc), a)})

def xr_of(ps: List<&2, V.Point>, +acc: V.Vec2) -> V.Vec2:
  match ps:
    case []: acc
    case +h <> +t: xr_of(t, V.V2{F64.min(V.v2_x(acc), V.pt_x(h)), F64.max(V.v2_y(acc), V.pt_x(h))})

def yr_of(ps: List<&2, V.Point>, +acc: V.Vec2) -> V.Vec2:
  match ps:
    case []: acc
    case +h <> +t: yr_of(t, V.V2{F64.min(V.v2_x(acc), V.pt_y(h)), F64.max(V.v2_y(acc), V.pt_y(h))})

def in_xy(+ps: List<&2, V.Point>, +cx: F64, +cy: F64) -> Bool:
  +xr = xr_of(ps, big())
  +yr = yr_of(ps, big())
  Bool.and(Bool.and(F64.is_le(V.v2_x(xr), cx), F64.is_le(cx, V.v2_y(xr))), Bool.and(F64.is_le(V.v2_x(yr), cy), F64.is_le(cy, V.v2_y(yr))))

def tr0() -> TR:
  TR{0u64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, False{}}

def fp_ps(+f: FP) -> List<&2, V.Point>:
  FP{+ps, +cv, +n} = f
  ps

def fp_cv(+f: FP) -> Bool:
  FP{+ps, +cv, +n} = f
  cv

def fp_n(+f: FP) -> Nat:
  FP{+ps, +cv, +n} = f
  n

def L_p0(ps: List<&2, V.Point>) -> V.Point:
  match ps:
    case []: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case +h <> +t: h

def pl_trace(+x: BX, +fi: Nat, +o: V.Point, +n: V.Dir) -> TF:
  +nw = bx_dr(x, n)
  +l = F64.sqrt(F64.add(F64.mul(V.dr_x(nw), V.dr_x(nw)), F64.mul(V.dr_y(nw), V.dr_y(nw))))
  +az = F64.abs(V.dr_z(nw))
  +vert = F64.is_le(az, F64.mul(1.0e-12f64, F64.add(l, az)))
  +horz = F64.is_le(l, F64.mul(1.0e-12f64, F64.add(l, az)))
  +nx = F64.div(V.dr_x(nw), l)
  +ny = F64.div(V.dr_y(nw), l)
  +hx = F64.neg(ny)
  +hy = nx
  +ow = bx_pt(x, o)
  +c = F64.add(F64.mul(V.pt_x(ow), nx), F64.mul(V.pt_y(ow), ny))
  +f = fp_ls(FB.face_ce(bx_b(x), fi), x, FP{[], False{}, 0n})
  +sv = sr(fp_ps(f), hx, hy, big())
  +z = zr(fp_ps(f), big())
  Bool.pick(TF, horz, TF{0u64, tr0()}, Bool.pick(TF, Bool.not(vert), TF{2u64, tr0()},
    TF{1u64, TR{1u64, F64.add(F64.mul(c, nx), F64.mul(V.v2_x(sv), hx)), F64.add(F64.mul(c, ny), F64.mul(V.v2_x(sv), hy)),
      F64.add(F64.mul(c, nx), F64.mul(V.v2_y(sv), hx)), F64.add(F64.mul(c, ny), F64.mul(V.v2_y(sv), hy)), 0.0f64, 0.0f64, 0.0f64,
      V.v2_x(z), V.v2_y(z), Bool.not(fp_cv(f))}}))

def any_wrap(ls: List<&2, List<&2, FB.CE>>, +sf: KS.SF, +b: Ty.Brep) -> Bool:
  match ls:
    case []: False{}
    case +h <> +t: Bool.or(F64.is_lt(KS.pi(), F64.abs(FB.lp_turn(h, sf, b, 0.0f64))), any_wrap(t, sf, b))

def cy_trace(+x: BX, +fi: Nat, +o: V.Point, +a: V.Dir, +r: F64) -> TF:
  +aw = bx_dr(x, a)
  +vert = F64.is_le(F64.add(F64.abs(V.dr_x(aw)), F64.abs(V.dr_y(aw))), F64.mul(1.0e-12f64, F64.abs(V.dr_z(aw))))
  +cw = bx_pt(x, o)
  +cx = V.pt_x(cw)
  +cy = V.pt_y(cw)
  +ls = FB.face_ce(bx_b(x), fi)
  +f = fp_ls(ls, x, FP{[], False{}, 0n})
  +ps = fp_ps(f)
  +wraps = any_wrap(ls, FB.face_sf(bx_b(x), fi), bx_b(x))
  +ref = KS.fatan2(F64.sub(V.pt_y(L_p0(ps)), cy), F64.sub(V.pt_x(L_p0(ps)), cx))
  +ar = ang_rng(ps, cx, cy, ref, big())
  +full = Bool.or(Bool.or(wraps, in_xy(ps, cx, cy)), F64.is_le(KS.pi(), F64.sub(V.v2_y(ar), V.v2_x(ar))))
  +z = zr(ps, big())
  +nl = List.length(&2, List<&2, FB.CE>, ls)
  +ex = Bool.or(Bool.and(Nat.is_eq(nl, 2n), wraps), Bool.and(Nat.is_eq(nl, 1n), Nat.is_eq(fp_n(f), 4n)))
  Bool.pick(TF, Bool.not(vert), TF{2u64, tr0()},
    TF{1u64, TR{2u64, cx, cy, 0.0f64, 0.0f64, r, Bool.pick(F64, full, 0.0f64, V.v2_x(ar)),
      Bool.pick(F64, full, KS.two_pi(), V.v2_y(ar)), V.v2_x(z), V.v2_y(z), ex}})

def face_trace(g: G.GVal, +x: BX, +fi: Nat) -> TF:
  match g:
    case G.GV_pl{w}:
      G.Pl{+o, +u, +v} = w
      pl_trace(x, fi, o, KS.cross(u, v))
    case G.GV_cy{w}:
      G.Cy{+o, +a, +r} = w
      cy_trace(x, fi, o, a, r)
    case _: TF{3u64, tr0()}

def s_mem(xs: List<&2, String>, +s: String) -> Bool:
  match xs:
    case []: False{}
    case +h <> +t: Bool.or(String.eq(h, s), s_mem(t, s))

def tl_add(+use: Bool, +tf: TF, +nm: String, +acc: TL) -> TL:
  TF{+code, +tr} = tf
  TL{+ok, +why, +ts} = acc
  Bool.pick(TL, Bool.not(use), TL{ok, why, ts},
    Bool.pick(TL, U64.is_eq(code, 1u64), TL{ok, why, tr <> ts},
      Bool.pick(TL, U64.is_eq(code, 2u64), TL{False{}, Bool.pick(String, ok, "gap-axes-not-parallel: face " ++ nm ++ " is not parallel to z", why), ts},
        Bool.pick(TL, U64.is_eq(code, 3u64), TL{False{}, Bool.pick(String, ok, "gap-faces-not-extruded: face " ++ nm, why), ts}, TL{ok, why, ts}))))

def traces_go(fs: List<&2, BD.Fn>, +x: BX, +sel: List<&2, String>, +fi: Nat, +acc: TL) -> TL:
  match fs:
    case []: acc
    case +f <> +t:
      TL{+ok, +why, +ts} = acc
      +nm = BD.fn_name(f)
      +use = Bool.or(Nat.is_eq(List.length(&2, String, sel), 0n), s_mem(sel, nm))
      +tf = face_trace(FB.face_surf(bx_b(x), fi), x, fi)
      traces_go(t, x, sel, Nat.add(fi, 1n), tl_add(use, tf, nm, TL{ok, why, ts}))

def traces(+b: M.Body, +sel: List<&2, String>) -> TL:
  traces_go(M.bd_fns(b), bx_of(b), sel, 0n, TL{True{}, "", []})

def tl_ok(+t: TL) -> Bool:
  TL{+ok, +why, +ts} = t
  ok

def tl_why(+t: TL) -> String:
  TL{+ok, +why, +ts} = t
  why

def tl_ts(+t: TL) -> List<&2, TR>:
  TL{+ok, +why, +ts} = t
  ts

def verdict(+d: DI) -> String:
  Bool.pick(String, F64.is_lt(0.0f64, di_lo(d)), "verdict=clearance status=certified",
    Bool.pick(String, F64.is_le(di_hi(d), 0.0f64), "verdict=interference status=certified", "verdict=contact status=uncertain"))

def gap_s(+na: String, +nb: String, +ta: TL, +tb: TL) -> String:
  +d = d_all(tl_ts(ta), tl_ts(tb), DI{inf(), inf()})
  Bool.pick(String, Bool.not(tl_ok(ta)), "error invalid-input | asm gap | why: " ++ tl_why(ta) ++ " on " ++ na ++ " | fix: gap measures parts extruded along z",
    Bool.pick(String, Bool.not(tl_ok(tb)), "error invalid-input | asm gap | why: " ++ tl_why(tb) ++ " on " ++ nb ++ " | fix: gap measures parts extruded along z; name the faces to measure against",
      "gap " ++ na ++ " " ++ nb ++ " gap=[" ++ S.f_show(di_lo(d)) ++ ", " ++ S.f_show(di_hi(d)) ++ "] traces=" ++
        Nat.show(List.length(&2, TR, tl_ts(ta))) ++ "/" ++ Nat.show(List.length(&2, TR, tl_ts(tb))) ++ " " ++ verdict(d)))

def rot_tr(+t: TR, +cx: F64, +cy: F64, +c: F64, +s: F64, +th: F64) -> TR:
  TR{+k, +ax, +ay, +bx, +by, +r, +t0, +t1, +z0, +z1, +xe} = t
  +ux = F64.sub(ax, cx)
  +uy = F64.sub(ay, cy)
  +vx = F64.sub(bx, cx)
  +vy = F64.sub(by, cy)
  +full = F64.is_le(F64.sub(KS.two_pi(), 1.0e-9f64), F64.sub(t1, t0))
  TR{k, F64.add(cx, F64.sub(F64.mul(c, ux), F64.mul(s, uy))), F64.add(cy, F64.add(F64.mul(s, ux), F64.mul(c, uy))),
    F64.add(cx, F64.sub(F64.mul(c, vx), F64.mul(s, vy))), F64.add(cy, F64.add(F64.mul(s, vx), F64.mul(c, vy))), r,
    Bool.pick(F64, full, t0, F64.add(t0, th)), Bool.pick(F64, full, t1, F64.add(t1, th)), z0, z1, xe}

def rot_all(ts: List<&2, TR>, +cx: F64, +cy: F64, +th: F64) -> List<&2, TR>:
  match ts:
    case []: []
    case +h <> +t: rot_tr(h, cx, cy, KS.fcos(th), KS.fsin(th), th) <> rot_all(t, cx, cy, th)

def tr_reach(+t: TR, +cx: F64, +cy: F64) -> F64:
  TR{+k, +ax, +ay, +bx, +by, +r, +t0, +t1, +z0, +z1, +xe} = t
  +da = F64.sqrt(F64.add(F64.mul(F64.sub(ax, cx), F64.sub(ax, cx)), F64.mul(F64.sub(ay, cy), F64.sub(ay, cy))))
  +db = F64.sqrt(F64.add(F64.mul(F64.sub(bx, cx), F64.sub(bx, cx)), F64.mul(F64.sub(by, cy), F64.sub(by, cy))))
  +full = F64.is_le(F64.sub(KS.two_pi(), 1.0e-9f64), F64.sub(t1, t0))
  +sym = Bool.and(full, F64.is_le(da, F64.mul(1.0e-12f64, F64.add(1.0f64, r))))
  Bool.pick(F64, U64.is_eq(k, 1u64), F64.max(da, db), Bool.pick(F64, sym, 0.0f64, F64.add(da, r)))

def reach(ts: List<&2, TR>, +cx: F64, +cy: F64, +acc: F64) -> F64:
  match ts:
    case []: acc
    case +h <> +t: reach(t, cx, cy, F64.max(acc, tr_reach(h, cx, cy)))

def mg_at(+g: MG, +th: F64) -> DI:
  MG{+a, +b, +ax, +ay, +bx, +by, +k, +l} = g
  d_all(rot_all(a, ax, ay, th), rot_all(b, bx, by, F64.neg(F64.mul(k, th))), DI{inf(), inf()})

def mg_l(+g: MG) -> F64:
  MG{+a, +b, +ax, +ay, +bx, +by, +k, +l} = g
  l

def lb_of(+l: F64, +t0: F64, +t1: F64, +d0: DI, +d1: DI) -> F64:
  F64.sub(F64.min(di_lo(d0), di_lo(d1)), F64.mul(0.5f64, F64.mul(l, F64.sub(t1, t0))))

def lo_with(+best: DI, +lb: F64) -> DI:
  DI{F64.min(di_lo(best), lb), di_hi(best)}

def hi_with(+best: DI, +dm: DI) -> DI:
  DI{di_lo(best), F64.min(di_hi(best), di_hi(dm))}

def close_enough(+best: DI, +lb: F64) -> Bool:
  F64.is_le(F64.sub(di_hi(best), lb), F64.mul(1.0e-6f64, F64.add(1.0f64, F64.abs(di_hi(best)))))

def bb_go(n: Nat, done: Bool, +g: MG, +t0: F64, +t1: F64, +d0: DI, +d1: DI, +best: DI) -> DI:
  match n:
    case 0n: lo_with(best, lb_of(mg_l(g), t0, t1, d0, d1))
    case 1n+(+m):
      match done:
        case True{}: lo_with(best, lb_of(mg_l(g), t0, t1, d0, d1))
        case False{}:
          +tm = F64.mul(0.5f64, F64.add(t0, t1))
          +dm = mg_at(g, tm)
          +b2 = hi_with(best, dm)
          +bl = bb_go(m, close_enough(b2, lb_of(mg_l(g), t0, tm, d0, dm)), g, t0, tm, d0, dm, b2)
          bb_go(m, close_enough(bl, lb_of(mg_l(g), tm, t1, dm, d1)), g, tm, t1, dm, d1, bl)

def seed_one(+depth: Nat, +g: MG, +t0: F64, +t1: F64, +prev: DI, +d1: DI, +best: DI) -> DI:
  +b2 = hi_with(hi_with(best, prev), d1)
  bb_go(depth, close_enough(b2, lb_of(mg_l(g), t0, t1, prev, d1)), g, t0, t1, prev, d1, b2)

def bb_seed(n: Nat, +g: MG, +k: F64, +step: F64, +prev: DI, +depth: Nat, +best: DI) -> DI:
  match n:
    case 0n: best
    case 1n+m:
      +t0 = F64.mul(k, step)
      +t1 = F64.add(t0, step)
      +d1 = mg_at(g, t1)
      bb_seed(m, g, F64.add(k, 1.0f64), step, d1, depth, seed_one(depth, g, t0, t1, prev, d1, best))

def mg_of(+ta: List<&2, TR>, +tb: List<&2, TR>, +k: F64, +pa: V.Point, +pb: V.Point) -> MG:
  +ax = V.pt_x(pa)
  +ay = V.pt_y(pa)
  +bx = V.pt_x(pb)
  +by = V.pt_y(pb)
  MG{ta, tb, ax, ay, bx, by, k, F64.add(reach(ta, ax, ay, 0.0f64), F64.mul(k, reach(tb, bx, by, 0.0f64)))}

def mesh_d(+g: MG, +za: F64) -> DI:
  +step = F64.div(F64.div(KS.two_pi(), za), 32.0f64)
  bb_seed(32n, g, 0.0f64, step, mg_at(g, 0.0f64), 12n, DI{inf(), inf()})

def mesh_line(+na: String, +nb: String, +d: DI, +g: MG) -> String:
  MG{+a, +b, +ax, +ay, +bx, +by, +k, +l} = g
  +lo = F64.max(0.0f64, di_lo(d))
  "mesh " ++ na ++ " " ++ nb ++ " gap=[" ++ S.f_show(lo) ++ ", " ++ S.f_show(di_hi(d)) ++ "] over=pitch ratio=" ++ S.f_show(k) ++
    " lipschitz=" ++ S.f_show(l) ++ " " ++ verdict(DI{lo, di_hi(d)})

def mesh_ok(+na: String, +nb: String, +g: MG, +za: F64) -> String:
  mesh_line(na, nb, mesh_d(g, za), g)

def mesh_k(+code: U64, +na: String, +nb: String, +ta: TL, +tb: TL, +za: F64, +zb: F64, +pa: V.Point, +pb: V.Point) -> String:
  match code:
    case 1u64: "error invalid-input | asm mesh | why: " ++ tl_why(ta) ++ " on " ++ na ++ " | fix: mesh measures gears extruded along z"
    case 2u64: "error invalid-input | asm mesh | why: " ++ tl_why(tb) ++ " on " ++ nb ++ " | fix: mesh measures gears extruded along z"
    case 3u64: "error invalid-input | asm mesh | why: bad-tooth-count | fix: asm mesh INST TEETH INST TEETH (assembly ...)"
    case _: mesh_ok(na, nb, mg_of(tl_ts(ta), tl_ts(tb), F64.div(za, zb), pa, pb), za)

def mesh_s(+na: String, +nb: String, +ta: TL, +tb: TL, +za: F64, +zb: F64, +pa: V.Point, +pb: V.Point) -> String:
  +bad = Bool.or(Bool.not(F64.is_lt(0.0f64, za)), Bool.not(F64.is_lt(0.0f64, zb)))
  mesh_k(Bool.pick(U64, Bool.not(tl_ok(ta)), 1u64, Bool.pick(U64, Bool.not(tl_ok(tb)), 2u64, Bool.pick(U64, bad, 3u64, 0u64))),
    na, nb, ta, tb, za, zb, pa, pb)
