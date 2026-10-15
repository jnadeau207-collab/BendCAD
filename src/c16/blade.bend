import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c06/xp.bend as X
import ../c06/build.bend as BD
import ../c06/iv.bend as I
import ../base/num.bend as N
import ../c09/feat.bend as F9

type GR is Data:
  GR_ok{}
  GR_no{ why: String, fix: String }
type NQ is Data:
  Q17{}
  Q33{}
  Q65{}
type NW is Data:
  N2{}
  N3{}
  N4{}
  N5{}
  N6{}
  N7{}
  N8{}
type Sg is Data:
  Sg_ln{ a: Nat, b: Nat }
type P2 is Data:
  P2{ x: F64, y: F64 }
type PR is Data:
  PR{ pts: List<&2, P2>, segs: List<&2, Sg> }
type IP is Data:
  IP{ x: I.I, y: I.I }
type YC is Data:
  YC{ yc: I.I, dyc: I.I }
type Sec is Data:
  Sec{ m: U64, p: U64, t: U64, c: F64, k: Nat }
type NA is Data:
  NA{ m: U64, p: U64, t: U64, c: X.Xp, n: U64 }
type Ub is Data:
  Ub{ e: Nat, fwd: Bool }
type BR is Data:
  BR{ i: Nat, m: U64, p: U64, t: U64, c: F64, z: I.I, area: I.I, cx: I.I, cy: I.I, tmax: I.I,
    cmax: I.I }
type BO is Data:
  BO_bd{ secs: List<&2, NA>, z: X.Xp, tw: U64, tp: U64 }
  BO_bad{}
type SecE is Data:
  SecE{ sec: Sec, chord: I.I, z: I.I, cos: I.I, sin: I.I, qx: I.I, qy: I.I }
def dg_go(+ok: Bool) -> GR:
  match ok:
    case False{}: GR_no{"naca-digits-not-admitted", "use M 0-9, P 0-9 with P nonzero when M is nonzero, T 06-24"}
    case True{}: GR_ok{}
def np_go(+ok: Bool) -> GR:
  match ok:
    case False{}: GR_no{"naca-points-not-admitted", "use 17, 33 or 65 points per surface"}
    case True{}: GR_ok{}
def ns_go(+ok: Bool) -> GR:
  match ok:
    case False{}: GR_no{"blade-sections-not-admitted", "stack 2 to 8 naca4 sections"}
    case True{}: GR_ok{}
def tw_go(+ok: Bool, +tw: U64) -> GR:
  match ok:
    case False{}: GR_no{"twist-not-admitted", "twist 0, 10, 20 or 30 degrees"}
    case True{}: GR_ok{}
def tp_go(+ok: Bool, +tp: U64) -> GR:
  match ok:
    case False{}: GR_no{"taper-not-admitted", "taper 50, 75 or 100 tip-chord percent"}
    case True{}: GR_ok{}
def rl_go(+ok: Bool) -> GR:
  match ok:
    case False{}: GR_no{"blade-stack-not-ruled", "stack admitted naca4 sections with equal points and chord"}
    case True{}: GR_ok{}
def bl_go(+ok: Bool) -> GR:
  match ok:
    case False{}: GR_no{"blade-needs-blade", "run blade on a blade node"}
    case True{}: GR_ok{}
def fin_go(+ok: Bool) -> GR:
  match ok:
    case False{}: GR_no{"degenerate-feature", "give finite positive chord and span"}
    case True{}: GR_ok{}
def dg_ok(+m: U64, +p: U64, +t: U64) -> Bool:
  Bool.and(U64.is_le(m, 9u64),
    Bool.and(U64.is_le(p, 9u64),
      Bool.and(U64.is_le(6u64, t),
        Bool.and(U64.is_le(t, 24u64), Bool.or(U64.is_eq(m, 0u64), U64.is_ne(p, 0u64))))))
def np_ok(+n: U64) -> Bool:
  match n:
    case 17u64: True{}
    case 33u64: True{}
    case 65u64: True{}
    case _: False{}
def nq_of(+n: U64) -> NQ:
  match n:
    case 17u64: Q17{}
    case 33u64: Q33{}
    case 65u64: Q65{}
    case _: Q17{}
def ring_k(+q: NQ) -> Nat:
  match q:
    case Q17{}: 17n
    case Q33{}: 33n
    case Q65{}: 65n
def tw_ok(+tw: U64) -> Bool:
  match tw:
    case 0u64: True{}
    case 10u64: True{}
    case 20u64: True{}
    case 30u64: True{}
    case _: False{}
def tp_ok(+tp: U64) -> Bool:
  match tp:
    case 50u64: True{}
    case 75u64: True{}
    case 100u64: True{}
    case _: False{}
def ns_ok(+n: Nat) -> Bool:
  Bool.and(Nat.is_le(2n, n), Nat.is_le(n, 8n))
def nw_n(+w: NW) -> Nat:
  match w:
    case N2{}: 2n
    case N3{}: 3n
    case N4{}: 4n
    case N5{}: 5n
    case N6{}: 6n
    case N7{}: 7n
    case N8{}: 8n
def ring_m(+k: Nat) -> Nat:
  Nat.sub(Nat.mul(2n, k), 2n)
def ring_next(+m: Nat, +j: Nat) -> Nat:
  Nat.mod(Nat.add(j, 1n), m)
def ring_seg(+m: Nat, +j: Nat) -> Sg:
  Sg_ln{j, ring_next(m, j)}
def ring_segs_go(+m: Nat, left: Nat, +j: Nat) -> List<&2, Sg>:
  match left:
    case 0n: []
    case 1n+k: ring_seg(m, j) <> ring_segs_go(m, k, Nat.add(j, 1n))
def ring_segs(+m: Nat) -> List<&2, Sg>:
  ring_segs_go(m, m, 0n)
def sec_v(+m: Nat, +s: Nat, +j: Nat) -> Nat:
  Nat.add(Nat.mul(s, m), j)
def ring_ei(+m: Nat, +s: Nat, +j: Nat) -> Nat:
  Nat.add(Nat.mul(s, m), j)
def rule_ei(+n: Nat, +m: Nat, +s: Nat, +j: Nat) -> Nat:
  Nat.add(Nat.mul(n, m), Nat.add(Nat.mul(s, m), j))
def ub(+e: Nat, +fwd: Bool) -> Ub:
  Ub{e, fwd}
def ub_e(+u: Ub) -> Nat:
  Ub{+e, +fwd} = u
  e
def ub_fwd(+u: Ub) -> Bool:
  Ub{+e, +fwd} = u
  fwd
def wall_loop(+n: Nat, +m: Nat, +s: Nat, +j: Nat) -> List<&2, Ub>:
  +j1 = ring_next(m, j)
  [ub(ring_ei(m, s, j), True{}), ub(rule_ei(n, m, s, j1), True{}),
    ub(ring_ei(m, Nat.add(s, 1n), j), False{}), ub(rule_ei(n, m, s, j), False{})]
def cap_tip_go(+m: Nat, +s: Nat, left: Nat, +j: Nat) -> List<&2, Ub>:
  match left:
    case 0n: []
    case 1n+k: ub(ring_ei(m, s, j), True{}) <> cap_tip_go(m, s, k, Nat.add(j, 1n))
def cap_tip(+n: Nat, +m: Nat) -> List<&2, Ub>:
  cap_tip_go(m, Nat.sub(n, 1n), m, 0n)
def cap_root_go(+m: Nat, left: Nat, +j: Nat) -> List<&2, Ub>:
  match left:
    case 0n: []
    case 1n+k: ub(ring_ei(m, 0n, j), False{}) <> cap_root_go(m, k, Nat.sub(j, 1n))
def cap_root(+m: Nat) -> List<&2, Ub>:
  cap_root_go(m, m, Nat.sub(m, 1n))
def walls_flat_go(+n: Nat, +m: Nat, left: Nat, +w: Nat) -> List<&2, List<&2, Ub>>:
  match left:
    case 0n: []
    case 1n+k: wall_loop(n, m, Nat.div(w, m), Nat.mod(w, m)) <> walls_flat_go(n, m, k, Nat.add(w, 1n))
def walls_flat(+n: Nat, +m: Nat) -> List<&2, List<&2, Ub>>:
  walls_flat_go(n, m, Nat.mul(Nat.sub(n, 1n), m), 0n)
def edge_a(+n: Nat, +m: Nat, +e: Nat) -> Nat:
  +nm = Nat.mul(n, m)
  +r = Bool.pick(Nat, Nat.is_lt(e, nm), e, Nat.sub(e, nm))
  sec_v(m, Nat.div(r, m), Nat.mod(r, m))
def edge_b_go(+lt: Bool, +n: Nat, +m: Nat, +e: Nat) -> Nat:
  match lt:
    case True{}: sec_v(m, Nat.div(e, m), ring_next(m, Nat.mod(e, m)))
    case False{}:
      +r = Nat.sub(e, Nat.mul(n, m))
      sec_v(m, Nat.add(Nat.div(r, m), 1n), Nat.mod(r, m))
def edge_b(+n: Nat, +m: Nat, +e: Nat) -> Nat:
  edge_b_go(Nat.is_lt(e, Nat.mul(n, m)), n, m, e)
def blade_ne(+n: Nat, +m: Nat) -> Nat:
  Nat.add(Nat.mul(n, m), Nat.mul(Nat.sub(n, 1n), m))
def n2f(+n: Nat) -> F64:
  U64.to_f64(U64.from_nat(n))
def sec_m(+s: Sec) -> U64:
  Sec{+m, +p, +t, +c, +k} = s
  m
def sec_p(+s: Sec) -> U64:
  Sec{+m, +p, +t, +c, +k} = s
  p
def sec_t(+s: Sec) -> U64:
  Sec{+m, +p, +t, +c, +k} = s
  t
def sec_c(+s: Sec) -> F64:
  Sec{+m, +p, +t, +c, +k} = s
  c
def sec_k(+s: Sec) -> Nat:
  Sec{+m, +p, +t, +c, +k} = s
  k
def ip_x(+p: IP) -> I.I:
  IP{+x, +y} = p
  x
def ip_y(+p: IP) -> I.I:
  IP{+x, +y} = p
  y
def yc_v(+c: YC) -> I.I:
  YC{+yc, +dyc} = c
  yc
def dyc_v(+c: YC) -> I.I:
  YC{+yc, +dyc} = c
  dyc
def st_i_go(+lt: Bool, +j: Nat, +k: Nat) -> Nat:
  match lt:
    case True{}: Nat.sub(Nat.sub(k, 1n), j)
    case False{}: Nat.sub(j, Nat.sub(k, 1n))
def st_i(+j: Nat, +k: Nat) -> Nat:
  st_i_go(Nat.is_lt(j, k), j, k)
def st_up(+j: Nat, +k: Nat) -> Bool:
  Nat.is_lt(j, k)
def st_x(+i: Nat, +k: Nat) -> I.I:
  I.idiv(I.ipt(n2f(i)), I.ipt(n2f(Nat.sub(k, 1n))))
def m_I(+m: U64) -> I.I:
  I.idiv(I.ipt(U64.to_f64(m)), I.ipt(100.0f64))
def p_I(+p: U64) -> I.I:
  I.idiv(I.ipt(U64.to_f64(p)), I.ipt(10.0f64))
def t_I(+t: U64) -> I.I:
  I.idiv(I.ipt(U64.to_f64(t)), I.ipt(100.0f64))
def yt_I(+t: I.I, +x: I.I) -> I.I:
  +x2 = I.imul(x, x)
  +x3 = I.imul(x2, x)
  +x4 = I.imul(x3, x)
  +sq = I.isqrt(x)
  +y1 = I.imul(I.ipt(0.2969f64), sq)
  +y2 = I.imul(I.ipt(0.1260f64), x)
  +y3 = I.imul(I.ipt(0.3516f64), x2)
  +y4 = I.imul(I.ipt(0.2843f64), x3)
  +y5 = I.imul(I.ipt(0.1036f64), x4)
  I.imul(I.imul(I.ipt(5.0f64), t), I.isub(I.iadd(y1, y4), I.iadd(I.iadd(y2, y3), y5)))
def yc_lo(+m: I.I, +p: I.I, +x: I.I) -> I.I:
  +mpp = I.idiv(m, I.imul(p, p))
  I.imul(mpp, I.isub(I.imul(I.imul(I.ipt(2.0f64), p), x), I.imul(x, x)))
def yc_hi(+m: I.I, +p: I.I, +x: I.I) -> I.I:
  +q = I.isub(I.ipt(1.0f64), p)
  +mqq = I.idiv(m, I.imul(q, q))
  +c0 = I.isub(I.ipt(1.0f64), I.imul(I.ipt(2.0f64), p))
  I.imul(mqq, I.isub(I.iadd(c0, I.imul(I.imul(I.ipt(2.0f64), p), x)), I.imul(x, x)))
def dyc_lo(+m: I.I, +p: I.I, +x: I.I) -> I.I:
  +mpp = I.idiv(m, I.imul(p, p))
  I.imul(mpp, I.isub(I.imul(I.ipt(2.0f64), p), I.imul(I.ipt(2.0f64), x)))
def dyc_hi(+m: I.I, +p: I.I, +x: I.I) -> I.I:
  +q = I.isub(I.ipt(1.0f64), p)
  +mqq = I.idiv(m, I.imul(q, q))
  I.imul(mqq, I.isub(I.imul(I.ipt(2.0f64), p), I.imul(I.ipt(2.0f64), x)))
def camber_pick(+lt: Bool, +m: I.I, +p: I.I, +x: I.I) -> YC:
  match lt:
    case True{}: YC{yc_lo(m, p, x), dyc_lo(m, p, x)}
    case False{}: YC{yc_hi(m, p, x), dyc_hi(m, p, x)}
def camber_go(+m: I.I, +p: I.I, +x: I.I) -> YC:
  camber_pick(F64.is_lt(I.imid(x), I.imid(p)), m, p, x)
def camber_zm(+zm: Bool, +m: U64, +p: U64, +x: I.I) -> YC:
  match zm:
    case True{}: YC{I.ipt(0.0f64), I.ipt(0.0f64)}
    case False{}: camber_go(m_I(m), p_I(p), x)
def camber(+m: U64, +p: U64, +x: I.I) -> YC:
  camber_zm(U64.is_eq(m, 0u64), m, p, x)
def surf_ip_up(+up: Bool, +x: I.I, +yc: I.I, +qx: I.I, +qy: I.I) -> IP:
  match up:
    case True{}: IP{I.isub(x, qx), I.iadd(yc, qy)}
    case False{}: IP{I.iadd(x, qx), I.isub(yc, qy)}
def surf_ip(+sec: Sec, +i: Nat, +up: Bool) -> IP:
  +x = st_x(i, sec_k(sec))
  +yt = yt_I(t_I(sec_t(sec)), x)
  +c = camber(sec_m(sec), sec_p(sec), x)
  +dd = dyc_v(c)
  +l = I.isqrt(I.iadd(I.ipt(1.0f64), I.imul(dd, dd)))
  surf_ip_up(up, x, yc_v(c), I.idiv(I.imul(yt, dd), l), I.idiv(yt, l))
def ring_ip_go(+up: Bool, +sec: Sec, +j: Nat) -> IP:
  match up:
    case True{}: surf_ip(sec, st_i(j, sec_k(sec)), True{})
    case False{}: surf_ip(sec, st_i(j, sec_k(sec)), False{})
def ring_ip(+sec: Sec, +j: Nat) -> IP:
  ring_ip_go(st_up(j, sec_k(sec)), sec, j)
def se_sec(+s: SecE) -> Sec:
  SecE{+sec, +chord, +z, +cos, +sin, +qx, +qy} = s
  sec
def se_chord(+s: SecE) -> I.I:
  SecE{+sec, +chord, +z, +cos, +sin, +qx, +qy} = s
  chord
def se_z(+s: SecE) -> I.I:
  SecE{+sec, +chord, +z, +cos, +sin, +qx, +qy} = s
  z
def se_cos(+s: SecE) -> I.I:
  SecE{+sec, +chord, +z, +cos, +sin, +qx, +qy} = s
  cos
def se_sin(+s: SecE) -> I.I:
  SecE{+sec, +chord, +z, +cos, +sin, +qx, +qy} = s
  sin
def se_qx(+s: SecE) -> I.I:
  SecE{+sec, +chord, +z, +cos, +sin, +qx, +qy} = s
  qx
def se_qy(+s: SecE) -> I.I:
  SecE{+sec, +chord, +z, +cos, +sin, +qx, +qy} = s
  qy
def se_dummy() -> SecE:
  SecE{Sec{0u64, 0u64, 6u64, 0.0f64, 0n}, I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(1.0f64), I.ipt(0.0f64),
    I.ipt(0.0f64), I.ipt(0.0f64)}
def se_at(secs: List<&2, SecE>, +s: Nat) -> SecE:
  match secs:
    case []: se_dummy()
    case +h <> t:
      match s:
        case 0n: h
        case 1n+k: se_at(t, k)
def ang_I(+tw: U64, +i: Nat, +n: Nat) -> I.I:
  I.imul(I.ipt(U64.to_f64(tw)), I.idiv(I.ipt(n2f(i)), I.ipt(n2f(Nat.sub(n, 1n)))))
def ang_f(+tw: U64, +i: Nat, +n: Nat) -> F64:
  I.imid(ang_I(tw, i, n))
def z_I(+zv: F64, +i: Nat, +n: Nat) -> I.I:
  I.imul(I.ipt(zv), I.idiv(I.ipt(n2f(i)), I.ipt(n2f(Nat.sub(n, 1n)))))
def scl_I(+tp: U64, +i: Nat, +n: Nat) -> I.I:
  +f = I.idiv(I.isub(I.ipt(U64.to_f64(tp)), I.ipt(100.0f64)), I.ipt(100.0f64))
  I.iadd(I.ipt(1.0f64), I.imul(f, I.idiv(I.ipt(n2f(i)), I.ipt(n2f(Nat.sub(n, 1n))))))
def li0(+xs: List<&2, I.I>) -> I.I:
  match xs:
    case []: I.ipt(1.0f64)
    case +h <> t: h
def li1(+xs: List<&2, I.I>) -> I.I:
  match xs:
    case []: I.ipt(0.0f64)
    case +h <> t: li0(t)
def csc_of(+tw: U64, +i: Nat, +n: Nat) -> List<&2, I.I>:
  I.sin_cos_deg(ang_f(tw, i, n))
def stk_Q(+sec: Sec, +chord: I.I) -> IP:
  +c = camber(sec_m(sec), sec_p(sec), I.ipt(0.25f64))
  IP{I.imul(I.ipt(0.25f64), chord), I.imul(yc_v(c), chord)}
def place_one(+sec: Sec, +zv: F64, +tw: U64, +tp: U64, +n: Nat, +i: Nat) -> SecE:
  +ch = I.imul(I.ipt(sec_c(sec)), scl_I(tp, i, n))
  +cs = csc_of(tw, i, n)
  +q = stk_Q(sec, ch)
  SecE{sec, ch, z_I(zv, i, n), li0(cs), li1(cs), ip_x(q), ip_y(q)}
def place_secs_go(secs: List<&2, Sec>, +zv: F64, +tw: U64, +tp: U64, +n: Nat, +i: Nat) -> List<&2, SecE>:
  match secs:
    case []: []
    case +s <> t: place_one(s, zv, tw, tp, n, i) <> place_secs_go(t, zv, tw, tp, n, Nat.add(i, 1n))
def place_secs(+secs: List<&2, Sec>, +zv: F64, +tw: U64, +tp: U64) -> List<&2, SecE>:
  place_secs_go(secs, zv, tw, tp, List.length(&2, Sec, secs), 0n)
def place_ip(+se: SecE, +j: Nat) -> IP:
  +p = ring_ip(se_sec(se), j)
  +sx = I.imul(ip_x(p), se_chord(se))
  +sy = I.imul(ip_y(p), se_chord(se))
  +dx = I.isub(sx, se_qx(se))
  +dy = I.isub(sy, se_qy(se))
  IP{I.iadd(I.isub(I.imul(dx, se_cos(se)), I.imul(dy, se_sin(se))), se_qx(se)),
    I.iadd(I.iadd(I.imul(dx, se_sin(se)), I.imul(dy, se_cos(se))), se_qy(se))}
def place_pt(+se: SecE, +j: Nat) -> V.Point:
  +p = place_ip(se, j)
  V.Pt{I.imid(ip_x(p)), I.imid(ip_y(p)), I.imid(se_z(se))}
def vpt(+ses: List<&2, SecE>, +m: Nat, +v: Nat) -> V.Point:
  place_pt(se_at(ses, Nat.div(v, m)), Nat.mod(v, m))
def blade_vs_go(+ses: List<&2, SecE>, +m: Nat, left: Nat, +v: Nat) -> List<&2, Ty.Vertex>:
  match left:
    case 0n: []
    case 1n+k: Ty.Vx{0u64, vpt(ses, m, v)} <> blade_vs_go(ses, m, k, Nat.add(v, 1n))
def blade_vs(+ses: List<&2, SecE>, +n: Nat, +m: Nat) -> List<&2, Ty.Vertex>:
  blade_vs_go(ses, m, Nat.mul(n, m), 0n)
def ed_bz(+ia: Nat, +ib: Nat, +pa: V.Point, +pb: V.Point) -> Ty.Edge:
  Ty.Ed{0u64, BD.hv(ia), BD.hv(ib),
    Ty.EK_curve{G.GV_bz{G.Bz{pa, pa, pb, pb}}, G.Dom{0.0f64, 1.0f64}}}
def blade_es_go(+ses: List<&2, SecE>, +n: Nat, +m: Nat, left: Nat, +e: Nat) -> List<&2, Ty.Edge>:
  match left:
    case 0n: []
    case 1n+k:
      +a = edge_a(n, m, e)
      +b = edge_b(n, m, e)
      ed_bz(a, b, vpt(ses, m, a), vpt(ses, m, b)) <> blade_es_go(ses, n, m, k, Nat.add(e, 1n))
def blade_es(+ses: List<&2, SecE>, +n: Nat, +m: Nat) -> List<&2, Ty.Edge>:
  blade_es_go(ses, n, m, blade_ne(n, m), 0n)
def v2(+x: F64, +y: F64) -> V.Vec2:
  V.V2{x, y}
def use_of(+u: Ub, +ta: V.Vec2, +tb: V.Vec2) -> BD.Use:
  BD.Us{ub_e(u), ub_fwd(u), ta, tb}
def wall_uses4(+a: Ub, +b: Ub, +c: Ub, +d: Ub) -> List<&2, BD.Use>:
  [use_of(a, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)), use_of(b, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
    use_of(c, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)), use_of(d, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))]
def wall_uses(+l: List<&2, Ub>) -> List<&2, BD.Use>:
  match l:
    case []: []
    case +a <> t1:
      match t1:
        case []: []
        case +b <> t2:
          match t2:
            case []: []
            case +c <> t3:
              match t3:
                case []: []
                case +d <> t4: wall_uses4(a, b, c, d)
def wall_face(+ses: List<&2, SecE>, +n: Nat, +m: Nat, +s: Nat, +j: Nat, +nd: U64, +w: Nat) -> BD.FS:
  +a = se_at(ses, s)
  +b = se_at(ses, Nat.add(s, 1n))
  +j1 = ring_next(m, j)
  F9.face1(G.GV_bp{F9.bp_of(place_pt(a, j), place_pt(a, j1), place_pt(b, j1), place_pt(b, j))},
    wall_uses(wall_loop(n, m, s, j)), nd, w)
def walls_fs_go(+ses: List<&2, SecE>, +n: Nat, +m: Nat, +nd: U64, left: Nat, +w: Nat) -> List<&2, BD.FS>:
  match left:
    case 0n: []
    case 1n+k:
      wall_face(ses, n, m, Nat.div(w, m), Nat.mod(w, m), nd, w) <>
        walls_fs_go(ses, n, m, nd, k, Nat.add(w, 1n))
def walls_fs(+ses: List<&2, SecE>, +n: Nat, +m: Nat, +nd: U64) -> List<&2, BD.FS>:
  walls_fs_go(ses, n, m, nd, Nat.mul(Nat.sub(n, 1n), m), 0n)
def cap_pt(+ses: List<&2, SecE>, +m: Nat, +s: Nat, +u: Ub) -> V.Point:
  place_pt(se_at(ses, s), Nat.mod(ub_e(u), m))
def cap_pt1(+ses: List<&2, SecE>, +m: Nat, +s: Nat, +u: Ub) -> V.Point:
  place_pt(se_at(ses, s), ring_next(m, Nat.mod(ub_e(u), m)))
def cap_root_uses(+ses: List<&2, SecE>, +m: Nat, +l: List<&2, Ub>) -> List<&2, BD.Use>:
  match l:
    case []: []
    case +u <> t:
      use_of(u, F9.xny(cap_pt(ses, m, 0n, u)), F9.xny(cap_pt1(ses, m, 0n, u))) <>
        cap_root_uses(ses, m, t)
def cap_tip_uses_go(+ses: List<&2, SecE>, +s: Nat, +m: Nat, +l: List<&2, Ub>) -> List<&2, BD.Use>:
  match l:
    case []: []
    case +u <> t:
      use_of(u, F9.xy_of(cap_pt(ses, m, s, u)), F9.xy_of(cap_pt1(ses, m, s, u))) <>
        cap_tip_uses_go(ses, s, m, t)
def cap_tip_uses(+ses: List<&2, SecE>, +n: Nat, +m: Nat, +l: List<&2, Ub>) -> List<&2, BD.Use>:
  cap_tip_uses_go(ses, Nat.sub(n, 1n), m, l)
def last_se(+ses: List<&2, SecE>) -> SecE:
  match ses:
    case []: se_dummy()
    case +h <> t:
      match t:
        case []: h
        case +x <> y: last_se(t)
def blade_fs(+ses: List<&2, SecE>, +n: Nat, +m: Nat, +nd: U64, +z0: F64, +z1: F64) -> List<&2, BD.FS>:
  +nw = Nat.mul(Nat.sub(n, 1n), m)
  List.append(&2, BD.FS, walls_fs(ses, n, m, nd),
    [F9.face1(G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, z0}, F9.dx(), F9.dny()}}, cap_root_uses(ses, m, cap_root(m)),
      nd, nw),
      F9.face1(G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, z1}, F9.dx(), F9.dy()}}, cap_tip_uses(ses, n, m, cap_tip(n, m)),
        nd, Nat.add(nw, 1n))])
def blade_bt(+ses: List<&2, SecE>, +n: Nat, +m: Nat, +nd: U64, +z0: F64, +z1: F64) -> BD.Bt:
  F9.pack(blade_vs(ses, n, m), blade_es(ses, n, m), blade_fs(ses, n, m, nd, z0, z1))
def cross_I(+a: IP, +b: IP) -> I.I:
  I.isub(I.imul(ip_x(a), ip_y(b)), I.imul(ip_x(b), ip_y(a)))
def sho_go(+se: SecE, +m: Nat, left: Nat, +j: Nat, +acc: I.I) -> I.I:
  match left:
    case 0n: acc
    case 1n+t:
      sho_go(se, m, t, Nat.add(j, 1n), I.iadd(acc, cross_I(place_ip(se, j), place_ip(se, ring_next(m, j)))))
def sec_area(+se: SecE, +m: Nat) -> I.I:
  I.iscale(sho_go(se, m, m, 0n, I.ipt(0.0f64)), 0.5f64)
def cen_go(+se: SecE, +m: Nat, left: Nat, +j: Nat, +ax: I.I, +ay: I.I) -> IP:
  match left:
    case 0n: IP{ax, ay}
    case 1n+t:
      +a = place_ip(se, j)
      +b = place_ip(se, ring_next(m, j))
      +c = cross_I(a, b)
      cen_go(se, m, t, Nat.add(j, 1n), I.iadd(ax, I.imul(I.iadd(ip_x(a), ip_x(b)), c)),
        I.iadd(ay, I.imul(I.iadd(ip_y(a), ip_y(b)), c)))
def sec_cen(+se: SecE, +m: Nat, +area: I.I) -> IP:
  +n = cen_go(se, m, m, 0n, I.ipt(0.0f64), I.ipt(0.0f64))
  +d = I.imul(I.ipt(6.0f64), area)
  IP{I.idiv(ip_x(n), d), I.idiv(ip_y(n), d)}
def imax(+a: I.I, +b: I.I) -> I.I:
  I.I{F64.max(I.i_lo(a), I.i_lo(b)), F64.max(I.i_hi(a), I.i_hi(b))}
def iabs(+a: I.I) -> I.I:
  +lo = I.i_lo(a)
  +hi = I.i_hi(a)
  I.I{Bool.pick(F64, Bool.and(F64.is_le(lo, 0.0f64), F64.is_le(0.0f64, hi)), 0.0f64,
    F64.min(F64.abs(lo), F64.abs(hi))), F64.max(F64.abs(lo), F64.abs(hi))}
def th_go(+sec: Sec, +t: I.I, left: Nat, +i: Nat, +ay: I.I, +ac: I.I) -> IP:
  match left:
    case 0n: IP{ay, ac}
    case 1n+k:
      +x = st_x(i, sec_k(sec))
      +r = th_go(sec, t, k, Nat.add(i, 1n), imax(ay, yt_I(t, x)), imax(ac, iabs(yc_v(camber(sec_m(sec), sec_p(sec), x)))))
      r
def sec_th(+se: SecE) -> IP:
  +sec = se_sec(se)
  th_go(sec, t_I(sec_t(sec)), sec_k(sec), 0n, I.ipt(0.0f64), I.ipt(0.0f64))
def br_i(+r: BR) -> Nat:
  BR{+i, +m, +p, +t, +c, +z, +area, +cx, +cy, +tmax, +cmax} = r
  i
def sec_row(+i: Nat, +se: SecE, +m: Nat) -> BR:
  +a = sec_area(se, m)
  +c = sec_cen(se, m, a)
  +th = sec_th(se)
  BR{i, sec_m(se_sec(se)), sec_p(se_sec(se)), sec_t(se_sec(se)), sec_c(se_sec(se)), se_z(se), a,
    ip_x(c), ip_y(c), I.imul(se_chord(se), I.imul(I.ipt(2.0f64), ip_x(th))),
    I.imul(se_chord(se), ip_y(th))}
def blade_rows_go(ses: List<&2, SecE>, +m: Nat, +i: Nat) -> List<&2, BR>:
  match ses:
    case []: []
    case +h <> t: sec_row(i, h, m) <> blade_rows_go(t, m, Nat.add(i, 1n))
def blade_rows(+ses: List<&2, SecE>, +m: Nat) -> List<&2, BR>:
  blade_rows_go(ses, m, 0n)
def dev_of(+ses: List<&2, SecE>) -> I.I:
  match ses:
    case []: I.ipt(0.0f64)
    case +h <> t:
      +q = last_se(ses)
      +dx = I.isub(se_qx(q), se_qx(h))
      +dy = I.isub(se_qy(q), se_qy(h))
      I.isqrt(I.iadd(I.imul(dx, dx), I.imul(dy, dy)))
def avg_ip(+a: IP, +b: IP) -> IP:
  IP{I.iscale(I.iadd(ip_x(a), ip_x(b)), 0.5f64), I.iscale(I.iadd(ip_y(a), ip_y(b)), 0.5f64)}
def mid_go(+a: SecE, +b: SecE, +m: Nat, left: Nat, +j: Nat, +acc: I.I) -> I.I:
  match left:
    case 0n: acc
    case 1n+t:
      +j1 = ring_next(m, j)
      mid_go(a, b, m, t, Nat.add(j, 1n),
        I.iadd(acc, cross_I(avg_ip(place_ip(a, j), place_ip(b, j)), avg_ip(place_ip(a, j1), place_ip(b, j1)))))
def mid_area(+a: SecE, +b: SecE, +m: Nat) -> I.I:
  I.iscale(mid_go(a, b, m, m, 0n, I.ipt(0.0f64)), 0.5f64)
def seg_vol(+a: SecE, +b: SecE, +m: Nat, +h: I.I) -> I.I:
  +aa = sec_area(a, m)
  +ab = sec_area(b, m)
  +am = mid_area(a, b, m)
  I.imul(I.idiv(h, I.ipt(6.0f64)), I.iadd(aa, I.iadd(I.imul(I.ipt(4.0f64), am), ab)))
def vol_go(ses: List<&2, SecE>, +m: Nat, +hh: I.I, +acc: I.I) -> I.I:
  match ses:
    case []: acc
    case +h <> t:
      match t:
        case []: acc
        case +b <> u: vol_go(b <> u, m, hh, I.iadd(acc, seg_vol(h, b, m, hh)))
def blade_vol_I(+ses: List<&2, SecE>, +m: Nat, +zv: F64, +n: Nat) -> I.I:
  vol_go(ses, m, I.idiv(I.ipt(zv), I.ipt(n2f(Nat.sub(n, 1n)))), I.ipt(0.0f64))
def iv2(+a: I.I) -> String:
  "[" ++ N.f_show(I.i_lo(a)) ++ ", " ++ N.f_show(I.i_hi(a)) ++ "]"
def tz(+t: U64) -> String:
  Bool.pick(String, U64.is_lt(t, 10u64), "0" ++ U64.show(t), U64.show(t))
def row_s(+r: BR) -> String:
  BR{+i, +m, +p, +t, +c, +z, +area, +cx, +cy, +tmax, +cmax} = r
  "sec " ++ Nat.show(i) ++ " naca " ++ U64.show(m) ++ U64.show(p) ++ tz(t) ++ " chord " ++
    N.f_show(c) ++ " z " ++ iv2(z) ++ " certified area " ++ iv2(area) ++ " certified cx " ++ iv2(cx) ++
    " certified cy " ++ iv2(cy) ++ " certified tmax " ++ iv2(tmax) ++ " certified cmax " ++ iv2(cmax) ++
    " certified\n"
def rows_s(rs: List<&2, BR>) -> String:
  match rs:
    case []: ""
    case +r <> t: row_s(r) ++ rows_s(t)
def angs_go(+tw: U64, +n: Nat, left: Nat, +i: Nat, +acc: String) -> String:
  match left:
    case 0n: acc
    case 1n+k: angs_go(tw, n, k, Nat.add(i, 1n), acc ++ N.f_show(ang_f(tw, i, n)) ++ " ")
def angs_s(+tw: U64, +n: Nat) -> String:
  angs_go(tw, n, n, 0n, "")
def sec_of(+na: NA, +e: X.Env) -> Sec:
  NA{+m, +p, +t, +c, +n} = na
  Sec{m, p, t, X.xp_ev(c, e), ring_k(nq_of(n))}
def secs_of(nas: List<&2, NA>, +e: X.Env) -> List<&2, Sec>:
  match nas:
    case []: []
    case +h <> t: sec_of(h, e) <> secs_of(t, e)
def se_at_sec(+ss: List<&2, Sec>) -> Sec:
  match ss:
    case []: Sec{0u64, 0u64, 6u64, 1.0f64, 17n}
    case +h <> t: h
def na_n(+na: NA) -> U64:
  NA{+m, +p, +t, +c, +n} = na
  n
def nas_np_ok(nas: List<&2, NA>) -> Bool:
  match nas:
    case []: True{}
    case +h <> t: Bool.and(np_ok(na_n(h)), nas_np_ok(t))
def secs_dg_ok(ss: List<&2, Sec>) -> Bool:
  match ss:
    case []: True{}
    case +h <> t: Bool.and(dg_ok(sec_m(h), sec_p(h), sec_t(h)), secs_dg_ok(t))
def secs_fin_ok(ss: List<&2, Sec>) -> Bool:
  match ss:
    case []: True{}
    case +h <> t: Bool.and(Bool.and(T.is_finite(sec_c(h)), F64.is_lt(0.0f64, sec_c(h))), secs_fin_ok(t))
def sec_adm(+s: Sec) -> Bool:
  Bool.and(dg_ok(sec_m(s), sec_p(s), sec_t(s)),
    Bool.and(T.is_finite(sec_c(s)), F64.is_lt(0.0f64, sec_c(s))))
def secs_adm(ss: List<&2, Sec>) -> Bool:
  match ss:
    case []: True{}
    case +h <> t: Bool.and(sec_adm(h), secs_adm(t))
def ruled_go(ss: List<&2, Sec>, +k: Nat, +c: F64) -> Bool:
  match ss:
    case []: True{}
    case +h <> t:
      Bool.and(Bool.and(Nat.is_eq(sec_k(h), k), F64.is_eq(sec_c(h), c)), ruled_go(t, k, c))
def ruled_ok(+ss: List<&2, Sec>) -> Bool:
  match ss:
    case []: False{}
    case +h <> t: ruled_go(t, sec_k(h), sec_c(h))
def rep_ok(+ss: List<&2, Sec>, +zv: F64, +tw: U64, +tp: U64) -> Bool:
  Bool.and(ns_ok(List.length(&2, Sec, ss)),
    Bool.and(tw_ok(tw),
      Bool.and(tp_ok(tp),
        Bool.and(Bool.and(T.is_finite(zv), F64.is_lt(0.0f64, zv)),
          Bool.and(secs_adm(ss), ruled_ok(ss))))))
def bl_gr(+g: GR) -> String:
  match g:
    case GR_ok{}: ""
    case GR_no{+why, +fix}: "error invalid-input | blade | why: " ++ why ++ " | fix: " ++ fix
def blade_rep_go(+id: U64, +ss: List<&2, Sec>, +zv: F64, +tw: U64, +tp: U64) -> String:
  +n = List.length(&2, Sec, ss)
  +ses = place_secs(ss, zv, tw, tp)
  +m = ring_m(sec_k(se_at_sec(ss)))
  "blade node " ++ U64.show(id) ++ " sections " ++ Nat.show(n) ++ " span " ++ N.f_show(zv) ++
    " twist " ++ U64.show(tw) ++ " taper " ++ U64.show(tp) ++ "\n" ++ rows_s(blade_rows(ses, m)) ++
    "deviation " ++ iv2(dev_of(ses)) ++ " certified\ntwist-schedule " ++ angs_s(tw, n) ++ "\n"
def blade_rep_str(+id: U64, +nas: List<&2, NA>, +z: X.Xp, +tw: U64, +tp: U64, +e: X.Env) -> String:
  +zv = X.xp_ev(z, e)
  +ss = secs_of(nas, e)
  Bool.pick(String, rep_ok(ss, zv, tw, tp), blade_rep_go(id, ss, zv, tw, tp),
    "error: node " ++ U64.show(id) ++ "; nothing bladed")
def blade_rep(+id: U64, +b: BO, +e: X.Env) -> String:
  match b:
    case BO_bd{+secs, +z, +tw, +tp}: blade_rep_str(id, secs, z, tw, tp, e)
    case BO_bad{}: bl_gr(bl_go(False{}))
