import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G

def q_display() -> U64:
  0u64

def q_manufacturing() -> U64:
  1u64

type Q is Data:
  Q{ chord: F64, angle: F64, max_tris: Nat, profile: U64 }

def q_mk(+chord: F64, +angle: F64, +max_tris: Nat, +profile: U64) -> Q:
  Q{chord, angle, max_tris, profile}

def q_chord(+q: Q) -> F64:
  Q{chord, angle, max_tris, profile} = q
  chord

def q_angle(+q: Q) -> F64:
  Q{chord, angle, max_tris, profile} = q
  angle

def q_max(+q: Q) -> Nat:
  Q{chord, angle, max_tris, profile} = q
  max_tris

def q_prof(+q: Q) -> U64:
  Q{chord, angle, max_tris, profile} = q
  profile

def q_default() -> Q:
  Q{1.0f64, 0.2f64, 10000000n, 0u64}

def q_preset(+p: U64) -> Q:
  match p:
    case 0u64: Q{2.0f64, 0.4f64, 10000000n, 0u64}
    case 1u64: Q{1.0f64, 0.2f64, 10000000n, 0u64}
    case 2u64: Q{0.25f64, 0.05f64, 10000000n, 0u64}
    case 3u64: Q{0.05f64, 0.01f64, 10000000n, 1u64}
    case _: Q{1.0f64, 0.2f64, 10000000n, 0u64}

def q_preset_max() -> U64:
  3u64

def q_ok(+q: Q) -> Bool:
  Bool.and(F64.is_lt(0.0f64, q_chord(q)),
    Bool.and(F64.is_lt(0.0f64, q_angle(q)), Nat.is_lt(0n, q_max(q))))

def q_prof_ok(+q: Q) -> Bool:
  Bool.or(U64.is_eq(q_prof(q), q_display()), U64.is_eq(q_prof(q), q_manufacturing()))

def nat_segs(+num: Nat, +den: Nat) -> Nat:
  match den:
    case 0n: 1n
    case 1n+d: Nat.add(Nat.div(num, den), 1n)

def segs_of(+x: F64) -> Nat:
  Nat.add(U64.to_nat(F64.to_u64(F64.min(x, 1.0e9f64))), 1n)

def segs_arc(+r: F64, +span: F64, +tol: F64) -> Nat:
  segs_of(F64.mul(span, F64.sqrt(F64.div(F64.abs(r), F64.mul(8.0f64, tol)))))

def segs_ang(+span: F64, +tol: F64) -> Nat:
  Nat.add(U64.to_nat(F64.to_u64(F64.div(span, tol))), 1n)

def nat_max(+a: Nat, +b: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_le(a, b), b, a)

def ulp8() -> F64:
  1.7763568394002505e-15f64

def widen(+x: F64) -> F64:
  F64.add(x, F64.mul(F64.abs(x), ulp8()))

def pt_dist(+a: V.Point, +b: V.Point) -> F64:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  F64.sqrt(F64.add(F64.add(F64.mul(F64.sub(bx, ax), F64.sub(bx, ax)), F64.mul(F64.sub(by, ay), F64.sub(by, ay))), F64.mul(F64.sub(bz, az), F64.sub(bz, az))))

def cc_full(+d: G.Dom) -> Bool:
  G.Dom{+lo, +hi} = d
  Bool.and(F64.is_eq(lo, F64.neg(1.0f64)), F64.is_eq(hi, 1.0f64))

def poly_h(cs: List<&2, F64>, +x: F64) -> F64:
  match cs:
    case []: 0.0f64
    case +c <> +t: F64.add(c, F64.mul(x, poly_h(t, x)))

def half_t(+x: F64) -> F64:
  F64.div(x, F64.add(1.0f64, F64.sqrt(F64.add(1.0f64, F64.mul(x, x)))))

def atan1(+x: F64) -> F64:
  +y = half_t(half_t(x))
  +y2 = F64.mul(y, y)
  F64.mul(4.0f64, F64.mul(y, poly_h([1.0f64, F64.neg(0.3333333333333333f64), 0.2f64, F64.neg(0.14285714285714285f64), 0.1111111111111111f64,
    F64.neg(0.09090909090909091f64), 0.07692307692307693f64, F64.neg(0.06666666666666667f64), 0.058823529411764705f64,
    F64.neg(0.05263157894736842f64), 0.047619047619047616f64], y2)))

def tan1(+y: F64) -> F64:
  +y2 = F64.mul(y, y)
  +sn = F64.mul(y, poly_h([1.0f64, F64.neg(0.16666666666666666f64), 0.008333333333333333f64, F64.neg(0.0001984126984126984f64),
    2.7557319223985893e-6f64, F64.neg(2.505210838544172e-8f64), 1.6059043836821613e-10f64, F64.neg(7.647163731819816e-13f64),
    2.8114572543455206e-15f64, F64.neg(8.22063524662433e-18f64), 1.9572941063391263e-20f64], y2))
  +cs = poly_h([1.0f64, F64.neg(0.5f64), 0.041666666666666664f64, F64.neg(0.001388888888888889f64), 2.48015873015873e-5f64,
    F64.neg(2.755731922398589e-7f64), 2.08767569878681e-9f64, F64.neg(1.1470745597729725e-11f64), 4.779477332387385e-14f64,
    F64.neg(1.5619206968586225e-16f64), 4.110317623312165e-19f64], y2)
  F64.div(sn, cs)

def cc_par(+lo: F64, +hi: F64, +f: F64) -> F64:
  +a = atan1(lo)
  F64.max(F64.min(lo, hi), F64.min(F64.max(lo, hi), tan1(F64.add(a, F64.mul(f, F64.sub(atan1(hi), a))))))

def cc_span(+d: G.Dom) -> F64:
  G.Dom{+lo, +hi} = d
  F64.mul(4.0f64, F64.abs(F64.sub(atan1(hi), atan1(lo))))

def rq_len(+w: G.RQBez) -> F64:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = w
  widen(F64.add(pt_dist(p0, p1), pt_dist(p1, p2)))

def edge_ang(g: G.GVal, +d: G.Dom) -> F64:
  match g:
    case G.GV_ln{l}: 0.0f64
    case G.GV_cc{c}: cc_span(d)
    case _: 0.0f64

def edge_closed(g: G.GVal, +d: G.Dom) -> Bool:
  match g:
    case G.GV_cc{c}: cc_full(d)
    case _: False{}

def segs_min(g: G.GVal, +d: G.Dom) -> Nat:
  Bool.pick(Nat, edge_closed(g, d), 3n, 1n)

def pt_dd(+a: V.Point, +b: V.Point, +c: V.Point) -> F64:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  V.Pt{+cx, +cy, +cz} = c
  pt_dist(V.Pt{F64.add(ax, F64.sub(cx, bx)), F64.add(ay, F64.sub(cy, by)), F64.add(az, F64.sub(cz, bz))}, b)

def rq_rad(+w: G.RQBez) -> F64:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = w
  +s2 = F64.sub(1.0f64, F64.mul(w1, w1))
  Bool.pick(F64, F64.is_le(s2, 1.0e-12f64), 1.0e300f64, F64.div(pt_dist(p0, p2), F64.mul(2.0f64, F64.sqrt(s2))))

def rq_spd(+w: G.RQBez) -> F64:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = w
  F64.div(1.0f64, F64.max(F64.abs(w1), 0.25f64))

def rq_turn(+w: G.RQBez) -> F64:
  F64.mul(rq_spd(w), F64.div(rq_len(w), rq_rad(w)))

def rq_segs(+w: G.RQBez, +q: Q) -> Nat:
  +r = rq_rad(w)
  +l = rq_len(w)
  nat_max(segs_of(F64.mul(rq_spd(w), F64.div(l, F64.sqrt(F64.mul(8.0f64, F64.mul(r, q_chord(q))))))),
    segs_of(F64.div(rq_turn(w), q_angle(q))))

def bz_segs(+w: G.Bez3, +q: Q) -> Nat:
  G.Bz{+p0, +p1, +p2, +p3} = w
  +m = F64.max(pt_dd(p0, p1, p2), pt_dd(p1, p2, p3))
  segs_of(F64.sqrt(F64.div(F64.mul(0.75f64, m), q_chord(q))))

def segs_chord(g: G.GVal, +d: G.Dom, +q: Q) -> Nat:
  match g:
    case G.GV_cc{+c}: segs_arc(G.cc_r(c), cc_span(d), q_chord(q))
    case G.GV_rq{+w}: rq_segs(w, q)
    case G.GV_bz{+w}: bz_segs(w, q)
    case _: 1n

def even_up(+n: Nat) -> Nat:
  Nat.mul(2n, Nat.div(Nat.add(n, 1n), 2n))

def segs_edge(+g: G.GVal, +d: G.Dom, +q: Q) -> Nat:
  +n = nat_max(segs_min(g, d), nat_max(segs_chord(g, d, q), segs_ang(edge_ang(g, d), q_angle(q))))
  Bool.pick(Nat, edge_closed(g, d), even_up(n), n)

def budget_ok(+est: Nat, +mx: Nat) -> Bool:
  Nat.is_le(est, mx)

def tri_est_strip(+n: Nat) -> Nat:
  Nat.mul(2n, n)

def tri_est_fan(+n: Nat) -> Nat:
  n

def tri_est_add(+a: Nat, +b: Nat) -> Nat:
  Nat.add(a, b)

type Tres is Data:
  Tres{ ok: Bool, why: String, obj: String, nverts: Nat, ntris: Nat, est: Nat, chord: F64, ang: F64,
    nsamp: Nat }

def tres_fail(+why: String) -> Tres:
  Tres{False{}, why, "", 0n, 0n, 0n, 0.0f64, 0.0f64, 0n}

def tres_fail_est(+why: String, +est: Nat) -> Tres:
  Tres{False{}, why, "", 0n, 0n, est, 0.0f64, 0.0f64, 0n}

def tres_ok(+obj: String, +nv: Nat, +nt: Nat, +est: Nat, +chord: F64, +ang: F64, +nsamp: Nat) -> Tres:
  Tres{True{}, "", obj, nv, nt, est, chord, ang, nsamp}

def tres_obj(+r: Tres) -> String:
  Tres{ok, why, obj, nv, nt, est, chord, ang, nsamp} = r
  obj

def tres_ok_of(+r: Tres) -> Bool:
  Tres{ok, why, obj, nv, nt, est, chord, ang, nsamp} = r
  ok

def tres_why(+r: Tres) -> String:
  Tres{ok, why, obj, nv, nt, est, chord, ang, nsamp} = r
  why

def tres_nv(+r: Tres) -> Nat:
  Tres{ok, why, obj, nv, nt, est, chord, ang, nsamp} = r
  nv

def tres_nt(+r: Tres) -> Nat:
  Tres{ok, why, obj, nv, nt, est, chord, ang, nsamp} = r
  nt

def tres_est(+r: Tres) -> Nat:
  Tres{ok, why, obj, nv, nt, est, chord, ang, nsamp} = r
  est

def tres_chord(+r: Tres) -> F64:
  Tres{ok, why, obj, nv, nt, est, chord, ang, nsamp} = r
  chord

def tres_ang(+r: Tres) -> F64:
  Tres{ok, why, obj, nv, nt, est, chord, ang, nsamp} = r
  ang

def tres_nsamp(+r: Tres) -> Nat:
  Tres{ok, why, obj, nv, nt, est, chord, ang, nsamp} = r
  nsamp
