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

def segs_len(+len: F64, +tol: F64) -> Nat:
  Nat.add(U64.to_nat(F64.to_u64(F64.div(len, tol))), 1n)

def segs_ang(+span: F64, +tol: F64) -> Nat:
  Nat.add(U64.to_nat(F64.to_u64(F64.div(span, tol))), 1n)

def nat_max(+a: Nat, +b: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_le(a, b), b, a)

def two_pi() -> F64:
  6.283185307179586f64

def ulp8() -> F64:
  1.7763568394002505e-15f64

def widen(+x: F64) -> F64:
  F64.add(x, F64.mul(F64.abs(x), ulp8()))

def pt_dist(+a: V.Point, +b: V.Point) -> F64:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  F64.sqrt(F64.add(F64.add(F64.mul(F64.sub(bx, ax), F64.sub(bx, ax)), F64.mul(F64.sub(by, ay), F64.sub(by, ay))), F64.mul(F64.sub(bz, az), F64.sub(bz, az))))

def ln_pt(+p: V.Point, +d: V.Dir, +t: F64) -> V.Point:
  V.Pt{+px, +py, +pz} = p
  V.Dr{+dx, +dy, +dz} = d
  V.Pt{F64.add(px, F64.mul(t, dx)), F64.add(py, F64.mul(t, dy)), F64.add(pz, F64.mul(t, dz))}

def ln_len(+l: G.Line3, +d: G.Dom) -> F64:
  G.Ln{+p, +v} = l
  G.Dom{+lo, +hi} = d
  widen(pt_dist(ln_pt(p, v, lo), ln_pt(p, v, hi)))

def cc_full(+d: G.Dom) -> Bool:
  G.Dom{+lo, +hi} = d
  Bool.and(F64.is_eq(lo, F64.neg(1.0f64)), F64.is_eq(hi, 1.0f64))

def cc_span(+d: G.Dom) -> F64:
  G.Dom{+lo, +hi} = d
  Bool.pick(F64, cc_full(d), two_pi(), F64.mul(4.0f64, F64.abs(F64.sub(hi, lo))))

def cc_len(+c: G.Circle3, +d: G.Dom) -> F64:
  G.Cc{+o, +u, +v, +r} = c
  widen(F64.mul(F64.abs(r), cc_span(d)))

def rq_len(+w: G.RQBez) -> F64:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = w
  widen(F64.add(pt_dist(p0, p1), pt_dist(p1, p2)))

def bz_len(+w: G.Bez3) -> F64:
  G.Bz{+p0, +p1, +p2, +p3} = w
  widen(F64.add(F64.add(pt_dist(p0, p1), pt_dist(p1, p2)), pt_dist(p2, p3)))

def edge_len(g: G.GVal, +d: G.Dom) -> F64:
  match g:
    case G.GV_ln{+l}: ln_len(l, d)
    case G.GV_cc{+c}: cc_len(c, d)
    case G.GV_rq{+w}: rq_len(w)
    case G.GV_bz{+w}: bz_len(w)
    case _: 0.0f64

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

def segs_edge(+g: G.GVal, +d: G.Dom, +q: Q) -> Nat:
  nat_max(segs_min(g, d), nat_max(segs_len(edge_len(g, d), q_chord(q)), segs_ang(edge_ang(g, d), q_angle(q))))

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
