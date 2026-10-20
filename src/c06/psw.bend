import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../c04/types.bend as Ty
import ./prof.bend as F
import ./build.bend as BD
import ./revolve.bend as RV
import ./iv.bend as I

type RP is Data:
  RP{ turn: Bool, cx: F64, cy: F64, r: F64, ccw: Bool, ax: F64, ay: F64, px: F64, py: F64, w: F64, bx: F64, by: F64 }

type SN is Data:
  SN{ turn: Bool, cx: F64, cy: F64, rho: F64, nx: F64, ny: F64, sg: F64, px: F64, py: F64, w: F64 }

type PP is Data:
  PP{ line: Bool, ax: F64, ay: F64, px: F64, py: F64, w: F64, bx: F64, by: F64, cx: F64, cy: F64, r: F64, ccw: Bool }

type PR is Data:
  PR{ code: U64, sns: List<&2, SN>, run: F64, tl: I.I, tw: I.I }

def sgn(+x: F64) -> F64:
  Bool.pick(F64, F64.is_lt(0.0f64, x), 1.0f64, Bool.pick(F64, F64.is_lt(x, 0.0f64), F64.neg(1.0f64), 0.0f64))

def rp_turn(+p: RP) -> Bool:
  RP{turn, cx, cy, r, ccw, ax, ay, px, py, w, bx, by} = p
  turn

def hyp(+x: F64, +y: F64) -> F64:
  F64.sqrt(F64.add(F64.mul(x, x), F64.mul(y, y)))

def tsg(+ccw: Bool) -> F64:
  Bool.pick(F64, ccw, 1.0f64, F64.neg(1.0f64))

def rp_n0x(+p: RP) -> F64:
  RP{+turn, +cx, cy, +r, +ccw, +ax, +ay, px, py, w, +bx, +by} = p
  Bool.pick(F64, turn, F64.mul(tsg(ccw), F64.div(F64.sub(ax, cx), r)), F64.div(F64.sub(by, ay), hyp(F64.sub(bx, ax), F64.sub(by, ay))))

def rp_n0y(+p: RP) -> F64:
  RP{+turn, cx, +cy, +r, +ccw, +ax, +ay, px, py, w, +bx, +by} = p
  Bool.pick(F64, turn, F64.mul(tsg(ccw), F64.div(F64.sub(ay, cy), r)), F64.neg(F64.div(F64.sub(bx, ax), hyp(F64.sub(bx, ax), F64.sub(by, ay)))))

def rp_n1x(+p: RP) -> F64:
  RP{+turn, +cx, cy, +r, +ccw, +ax, +ay, px, py, w, +bx, +by} = p
  Bool.pick(F64, turn, F64.mul(tsg(ccw), F64.div(F64.sub(bx, cx), r)), F64.div(F64.sub(by, ay), hyp(F64.sub(bx, ax), F64.sub(by, ay))))

def rp_n1y(+p: RP) -> F64:
  RP{+turn, cx, +cy, +r, +ccw, +ax, +ay, px, py, w, +bx, +by} = p
  Bool.pick(F64, turn, F64.mul(tsg(ccw), F64.div(F64.sub(by, cy), r)), F64.neg(F64.div(F64.sub(bx, ax), hyp(F64.sub(bx, ax), F64.sub(by, ay)))))

def rp_ok(+p: RP) -> Bool:
  RP{+turn, cx, cy, +r, ccw, +ax, +ay, px, py, w, +bx, +by} = p
  Bool.pick(Bool, turn, F64.is_lt(0.0f64, r), Bool.not(Bool.and(F64.is_eq(ax, bx), F64.is_eq(ay, by))))

def run_len(+p: RP) -> F64:
  RP{turn, cx, cy, r, ccw, +ax, +ay, px, py, w, +bx, +by} = p
  hyp(F64.sub(bx, ax), F64.sub(by, ay))

def iv_of(+x: F64) -> I.I:
  I.ipt(x)

def iabs(+x: I.I) -> I.I:
  +lo = I.i_lo(x)
  +hi = I.i_hi(x)
  Bool.pick(I.I, F64.is_le(0.0f64, lo), x, Bool.pick(I.I, F64.is_le(hi, 0.0f64), I.I{F64.neg(hi), F64.neg(lo)}, I.I{0.0f64, F64.max(F64.neg(lo), hi)}))

def ang(+p: RP) -> I.I:
  RP{turn, +cx, +cy, r, ccw, +ax, +ay, px, py, w, +bx, +by} = p
  +ux = I.isub(iv_of(ax), iv_of(cx))
  +uy = I.isub(iv_of(ay), iv_of(cy))
  +vx = I.isub(iv_of(bx), iv_of(cx))
  +vy = I.isub(iv_of(by), iv_of(cy))
  I.atan2q(iabs(I.isub(I.imul(ux, vy), I.imul(uy, vx))), I.iadd(I.imul(ux, vx), I.imul(uy, vy)))

def sn_of(+p: RP) -> SN:
  RP{+turn, +cx, +cy, +r, +ccw, +ax, +ay, +px, +py, +w, bx, by} = p
  Bool.pick(SN, turn, SN{True{}, cx, cy, r, F64.div(F64.sub(ax, cx), r), F64.div(F64.sub(ay, cy), r), tsg(ccw), px, py, w},
    SN{False{}, ax, ay, 0.0f64, rp_n0x(p), rp_n0y(p), 1.0f64, 0.0f64, 0.0f64, 1.0f64})

def g1(+p: RP, +prev: RP) -> Bool:
  F64.is_le(hyp(F64.sub(rp_n0x(p), rp_n1x(prev)), F64.sub(rp_n0y(p), rp_n1y(prev))), 1.0e-9f64)

def rps_pcs(ps: List<&2, F.Pc>, +cx: F64, +cy: F64, +r: F64, +ccw: Bool) -> List<&2, RP>:
  match ps:
    case []: []
    case +p <> t:
      match p:
        case F.P_ar{+ax, +ay, +px, +py, +w, +bx, +by}: RP{True{}, cx, cy, r, ccw, ax, ay, px, py, w, bx, by} <> rps_pcs(t, cx, cy, r, ccw)
        case F.P_ln{+ax, +ay, +bx, +by}: RP{False{}, 0.0f64, 0.0f64, 0.0f64, True{}, ax, ay, ax, ay, 1.0f64, bx, by} <> rps_pcs(t, cx, cy, r, ccw)

def rps_of(ss: List<&2, F.Sg>) -> List<&2, RP>:
  match ss:
    case []: []
    case s <> t:
      match s:
        case F.G_ln{+p}: List.append(&2, RP, rps_pcs([p], 0.0f64, 0.0f64, 0.0f64, True{}), rps_of(t))
        case F.G_ar{+cx, +cy, +r, +ccw, ps}: List.append(&2, RP, rps_pcs(ps, cx, cy, r, ccw), rps_of(t))

def last_rp(ps: List<&2, RP>, +d: RP) -> RP:
  match ps:
    case []: d
    case +p <> t: last_rp(t, p)

def pr_code(+x: PR) -> U64:
  PR{code, sns, run, tl, tw} = x
  code

def pr_sns(+x: PR) -> List<&2, SN>:
  PR{code, sns, run, tl, tw} = x
  sns

def pr_run(+x: PR) -> F64:
  PR{code, sns, run, tl, tw} = x
  run

def pr_tl(+x: PR) -> I.I:
  PR{code, sns, run, tl, tw} = x
  tl

def pr_tw(+x: PR) -> I.I:
  PR{code, sns, run, tl, tw} = x
  tw

def rp_r(+p: RP) -> F64:
  RP{turn, cx, cy, r, ccw, ax, ay, px, py, w, bx, by} = p
  r

def rp_ccw(+p: RP) -> Bool:
  RP{turn, cx, cy, r, ccw, ax, ay, px, py, w, bx, by} = p
  ccw

def pr_step(+p: RP, +prev: RP, +acc: PR) -> PR:
  PR{+code, +sns, +run, +tl, +tw} = acc
  +bad = Bool.pick(U64, rp_ok(p), Bool.pick(U64, g1(p, prev), 0u64, 27u64), 26u64)
  +tn = rp_turn(p)
  +a = ang(p)
  PR{Bool.pick(U64, U64.is_eq(code, 0u64), bad, code), sn_of(p) <> sns, Bool.pick(F64, tn, run, F64.add(run, run_len(p))),
    Bool.pick(I.I, tn, I.iadd(tl, I.imul(a, iv_of(rp_r(p)))), tl), Bool.pick(I.I, tn, Bool.pick(I.I, rp_ccw(p), I.iadd(tw, a), I.isub(tw, a)), tw)}

def pr_go(ps: List<&2, RP>, +prev: RP, +acc: PR) -> PR:
  match ps:
    case []: PR{pr_code(acc), List.reverse(&2, SN, pr_sns(acc)), pr_run(acc), pr_tl(acc), pr_tw(acc)}
    case +p <> t: pr_go(t, p, pr_step(p, prev, acc))

def rp0() -> RP:
  RP{False{}, 0.0f64, 0.0f64, 0.0f64, True{}, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 1.0f64, 0.0f64}

def one_turn(+tw: I.I) -> Bool:
  +tp = I.iscale(I.pi_i(), 2.0f64)
  Bool.and(F64.is_le(F64.abs(F64.sub(I.i_lo(tw), I.i_lo(tp))), 1.0e-6f64), F64.is_le(F64.abs(F64.sub(I.i_hi(tw), I.i_hi(tp))), 1.0e-6f64))

def pr_bad(+c: U64) -> PR:
  PR{c, [], 0.0f64, I.ipt(0.0f64), I.ipt(0.0f64)}

def path_of(+l: F.Lp) -> PR:
  +ps = rps_of(RV.lp_sgs(RV.as_path(l)))
  +r = pr_go(ps, last_rp(ps, rp0()), PR{0u64, [], 0.0f64, I.ipt(0.0f64), I.ipt(0.0f64)})
  Bool.pick(PR, Bool.and(U64.is_eq(pr_code(r), 0u64), Bool.not(one_turn(pr_tw(r)))), pr_bad(28u64), r)

def pps_pcs(ps: List<&2, F.Pc>, +cx: F64, +cy: F64, +r: F64, +ccw: Bool) -> List<&2, PP>:
  match ps:
    case []: []
    case +p <> t:
      match p:
        case F.P_ar{+ax, +ay, +px, +py, +w, +bx, +by}: PP{False{}, ax, ay, px, py, w, bx, by, cx, cy, r, ccw} <> pps_pcs(t, cx, cy, r, ccw)
        case F.P_ln{+ax, +ay, +bx, +by}: PP{True{}, ax, ay, ax, ay, 1.0f64, bx, by, cx, cy, r, ccw} <> pps_pcs(t, cx, cy, r, ccw)

def pps_of(ss: List<&2, F.Sg>) -> List<&2, PP>:
  match ss:
    case []: []
    case s <> t:
      match s:
        case F.G_ln{+p}: List.append(&2, PP, pps_pcs([p], 0.0f64, 0.0f64, 0.0f64, True{}), pps_of(t))
        case F.G_ar{+cx, +cy, +r, +ccw, ps}: List.append(&2, PP, pps_pcs(ps, cx, cy, r, ccw), pps_of(t))

def pp_ax(+p: PP) -> F64:
  PP{line, ax, ay, px, py, w, bx, by, cx, cy, r, ccw} = p
  ax

def pp_ay(+p: PP) -> F64:
  PP{line, ax, ay, px, py, w, bx, by, cx, cy, r, ccw} = p
  ay

def umin(ps: List<&2, PP>, +m: F64) -> F64:
  match ps:
    case []: m
    case +p <> t:
      PP{+line, +ax, ay, px, py, w, bx, by, +cx, cy, +r, ccw} = p
      umin(t, F64.min(m, Bool.pick(F64, line, ax, F64.min(ax, F64.sub(cx, r)))))

def umax(ps: List<&2, PP>, +m: F64) -> F64:
  match ps:
    case []: m
    case +p <> t:
      PP{+line, +ax, ay, px, py, w, bx, by, +cx, cy, +r, ccw} = p
      umax(t, F64.max(m, Bool.pick(F64, line, ax, F64.max(ax, F64.add(cx, r)))))

def sn_turn(+s: SN) -> Bool:
  SN{turn, cx, cy, rho, nx, ny, sg, px, py, w} = s
  turn

def sn_cx(+s: SN) -> F64:
  SN{turn, cx, cy, rho, nx, ny, sg, px, py, w} = s
  cx

def sn_cy(+s: SN) -> F64:
  SN{turn, cx, cy, rho, nx, ny, sg, px, py, w} = s
  cy

def sn_rho(+s: SN) -> F64:
  SN{turn, cx, cy, rho, nx, ny, sg, px, py, w} = s
  rho

def sn_nx(+s: SN) -> F64:
  SN{turn, cx, cy, rho, nx, ny, sg, px, py, w} = s
  nx

def sn_ny(+s: SN) -> F64:
  SN{turn, cx, cy, rho, nx, ny, sg, px, py, w} = s
  ny

def sn_sg(+s: SN) -> F64:
  SN{turn, cx, cy, rho, nx, ny, sg, px, py, w} = s
  sg

def clear_ok(ss: List<&2, SN>, +lo: F64, +hi: F64) -> Bool:
  match ss:
    case []: True{}
    case +s <> t:
      +ok = Bool.pick(Bool, F64.is_lt(0.0f64, sn_sg(s)), F64.is_lt(0.0f64, F64.add(sn_rho(s), lo)), F64.is_lt(0.0f64, F64.sub(sn_rho(s), hi)))
      Bool.and(Bool.or(Bool.not(sn_turn(s)), ok), clear_ok(t, lo, hi))

def vmap(+s: SN, +u: F64, +v: F64) -> V.Point:
  GO.pd_add_raw(V.Pt{sn_cx(s), sn_cy(s), v}, F64.add(sn_rho(s), F64.mul(sn_sg(s), u)), V.Dr{sn_nx(s), sn_ny(s), 0.0f64})

def row(ps: List<&2, PP>, +s: SN) -> List<&2, V.Point>:
  match ps:
    case []: []
    case +p <> t: vmap(s, pp_ax(p), pp_ay(p)) <> row(t, s)

def rows(ss: List<&2, SN>, +ps: List<&2, PP>) -> List<&2, List<&2, V.Point>>:
  match ss:
    case []: []
    case +s <> t: row(ps, s) <> rows(t, ps)

def rot_sn(xs: List<&2, SN>) -> List<&2, SN>:
  match xs:
    case []: []
    case +h <> +t: List.append(&2, SN, t, [h])

def rot_pt(xs: List<&2, V.Point>) -> List<&2, V.Point>:
  match xs:
    case []: []
    case +h <> +t: List.append(&2, V.Point, t, [h])

def rot_rw(xs: List<&2, List<&2, V.Point>>) -> List<&2, List<&2, V.Point>>:
  match xs:
    case []: []
    case +h <> +t: List.append(&2, List<&2, V.Point>, t, [h])

def vxr(ps: List<&2, V.Point>) -> List<&2, Ty.Vertex>:
  match ps:
    case []: []
    case +p <> t: Ty.Vx{0u64, p} <> vxr(t)

def vxs(rs: List<&2, List<&2, V.Point>>) -> List<&2, Ty.Vertex>:
  match rs:
    case []: []
    case +r <> t: List.append(&2, Ty.Vertex, vxr(r), vxs(t))

def bz(+a: V.Point, +b: V.Point) -> G.GVal:
  G.GV_bz{G.Bz{a, a, b, b}}

def rq(+a: V.Point, +p: V.Point, +b: V.Point, +w: F64) -> G.GVal:
  G.GV_rq{G.Rq{a, p, b, 1.0f64, w, 1.0f64}}

def ctl(+s: SN, +u: F64, +v: F64) -> V.Point:
  SN{turn, +cx, +cy, +rho, nx, ny, +sg, +px, +py, w} = s
  +k = F64.div(F64.add(rho, F64.mul(sg, u)), rho)
  V.Pt{F64.add(cx, F64.mul(k, F64.sub(px, cx))), F64.add(cy, F64.mul(k, F64.sub(py, cy))), v}

def sn_w(+s: SN) -> F64:
  SN{turn, cx, cy, rho, nx, ny, sg, px, py, w} = s
  w

def a_g(+s0: SN, +a: V.Point, +b: V.Point, +u: F64, +v: F64) -> G.GVal:
  Bool.pick(G.GVal, sn_turn(s0), rq(a, ctl(s0, u, v), b, sn_w(s0)), bz(a, b))

def a_es(ps: List<&2, PP>, p0s: List<&2, V.Point>, p1s: List<&2, V.Point>, +s0: SN, +s1: SN, +v0: Nat, +n: Nat, +nv: Nat) -> List<&2, Ty.Edge>:
  match ps:
    case []: []
    case +p <> pt:
      match p0s:
        case []: []
        case +a <> at:
          match p1s:
            case []: []
            case +b <> bt:
              RV.sec_ed(v0, Nat.mod(Nat.add(v0, n), nv), a_g(s0, a, b, pp_ax(p), pp_ay(p))) <>
                a_es(pt, at, bt, s0, s1, Nat.add(v0, 1n), n, nv)

def a_all(ss: List<&2, SN>, s1s: List<&2, SN>, rs0: List<&2, List<&2, V.Point>>, rs1: List<&2, List<&2, V.Point>>, +ps: List<&2, PP>,
    +v0: Nat, +n: Nat, +nv: Nat) -> List<&2, Ty.Edge>:
  match ss:
    case []: []
    case +s <> st:
      match s1s:
        case []: []
        case +s1 <> s1t:
          match rs0:
            case []: []
            case +r0 <> r0t:
              match rs1:
                case []: []
                case +r1 <> r1t:
                  List.append(&2, Ty.Edge, a_es(ps, r0, r1, s, s1, v0, n, nv), a_all(st, s1t, r0t, r1t, ps, Nat.add(v0, n), n, nv))

def p_g(+p: PP, +s: SN) -> G.GVal:
  PP{+line, +ax, +ay, +px, +py, +w, +bx, +by, cx, cy, r, ccw} = p
  Bool.pick(G.GVal, line, bz(vmap(s, ax, ay), vmap(s, bx, by)), rq(vmap(s, ax, ay), vmap(s, px, py), vmap(s, bx, by), w))

def p_es(ps: List<&2, PP>, +s: SN, +v0: Nat, +i: Nat, +n: Nat) -> List<&2, Ty.Edge>:
  match ps:
    case []: []
    case +p <> t: RV.sec_ed(Nat.add(v0, i), Nat.add(v0, Nat.mod(Nat.add(i, 1n), n)), p_g(p, s)) <> p_es(t, s, v0, Nat.add(i, 1n), n)

def p_all(ss: List<&2, SN>, +ps: List<&2, PP>, +v0: Nat, +n: Nat) -> List<&2, Ty.Edge>:
  match ss:
    case []: []
    case +s <> t: List.append(&2, Ty.Edge, p_es(ps, s, v0, 0n, n), p_all(t, ps, Nat.add(v0, n), n))

def mv(+o: V.Point, +dx: F64, +dy: F64) -> V.Point:
  V.Pt{F64.add(V.pt_x(o), dx), F64.add(V.pt_y(o), dy), V.pt_z(o)}

def shift(+g: G.GVal, +dx: F64, +dy: F64) -> G.GVal:
  match g:
    case G.GV_pl{w}:
      G.Pl{+o, +u, +v} = w
      G.GV_pl{G.Pl{mv(o, dx, dy), u, v}}
    case G.GV_cy{w}:
      G.Cy{+o, +a, +r} = w
      G.GV_cy{G.Cy{mv(o, dx, dy), a, r}}
    case G.GV_co{w}:
      G.Co{+o, +a, +k} = w
      G.GV_co{G.Co{mv(o, dx, dy), a, k}}
    case G.GV_sp{w}:
      G.Sp{+o, +r} = w
      G.GV_sp{G.Sp{mv(o, dx, dy), r}}
    case G.GV_to{w}:
      G.To{+o, +a, +bigr, +r} = w
      G.GV_to{G.To{mv(o, dx, dy), a, bigr, r}}
    case _: g

def flip(+x: RV.SS, +f: Bool) -> RV.SS:
  RV.SS{RV.ss_ok(x), RV.ss_s(x), Bool.xor(f, RV.ss_same(x)), RV.ss_plane(x)}

def turn_ss(+p: PP, +rho: F64, +sg: F64) -> RV.SS:
  PP{+line, +ax, +ay, px, py, w, +bx, +by, +cx, +cy, +r, +ccw} = p
  Bool.pick(RV.SS, line, flip(RV.ss_line(F64.add(rho, F64.mul(sg, ax)), ay, F64.add(rho, F64.mul(sg, bx)), by), F64.is_lt(sg, 0.0f64)),
    RV.ss_of(F.G_ar{F64.add(rho, F64.mul(sg, cx)), cy, r, ccw, []}))

def e2_of(+du: F64, +dv: F64, +nx: F64, +ny: F64) -> V.Dir:
  +l = F64.sqrt(F64.add(F64.mul(du, du), F64.mul(dv, dv)))
  Bool.pick(V.Dir, F64.is_eq(du, 0.0f64), V.Dr{0.0f64, 0.0f64, sgn(dv)},
    Bool.pick(V.Dir, F64.is_eq(dv, 0.0f64), V.Dr{F64.mul(sgn(du), nx), F64.mul(sgn(du), ny), 0.0f64},
      V.Dr{F64.div(F64.mul(du, nx), l), F64.div(F64.mul(du, ny), l), F64.div(dv, l)}))

def run_ss(+p: PP, +s: SN, +a: V.Point) -> RV.SS:
  PP{+line, +ax, +ay, px, py, w, +bx, +by, +cx, +cy, +r, +ccw} = p
  +t = {V.Dr{F64.neg(sn_ny(s)), sn_nx(s), 0.0f64} : V.Dir}
  Bool.pick(RV.SS, line, RV.SS{True{}, G.GV_pl{G.Pl{a, t, e2_of(F64.sub(bx, ax), F64.sub(by, ay), sn_nx(s), sn_ny(s))}}, True{}, True{}},
    RV.SS{F64.is_lt(0.0f64, r), G.GV_cy{G.Cy{vmap(s, cx, cy), t, r}}, ccw, False{}})

def side_ss(+p: PP, +s: SN, +a: V.Point) -> RV.SS:
  +x = turn_ss(p, sn_rho(s), sn_sg(s))
  Bool.pick(RV.SS, sn_turn(s), RV.SS{RV.ss_ok(x), shift(RV.ss_s(x), sn_cx(s), sn_cy(s)), RV.ss_same(x), RV.ss_plane(x)},
    run_ss(p, s, a))

def us(+e: Nat, +fwd: Bool, +pl: Bool, +g: G.GVal, +a: V.Point, +b: V.Point) -> BD.Use:
  BD.Us{e, fwd, RV.trim_of(pl, g, a), RV.trim_of(pl, g, b)}

def fs_one(+x: RV.SS, +a0: V.Point, +b0: V.Point, +a1: V.Point, +b1: V.Point, +ea: Nat, +eb: Nat, +pa: Nat, +pb: Nat, +nd: U64) -> BD.FS:
  +g = RV.ss_s(x)
  +pl = RV.ss_plane(x)
  BD.FS{0n, g, RV.ss_same(x), [[us(ea, True{}, pl, g, a0, a1), us(pb, True{}, pl, g, a1, b1), us(eb, False{}, pl, g, b0, b1),
    us(pa, False{}, pl, g, a0, b0)]], BD.Fn{nd, 0n, 2u64, ea, 0n}}

def f_es(ps: List<&2, PP>, p0s: List<&2, V.Point>, q0s: List<&2, V.Point>, p1s: List<&2, V.Point>, q1s: List<&2, V.Point>,
    +s: SN, +si: Nat, +i: Nat, +n: Nat, +nst: Nat, +nd: U64) -> List<&2, BD.FS>:
  match ps:
    case []: []
    case +p <> pt:
      match p0s:
        case []: []
        case +a0 <> at:
          match q0s:
            case []: []
            case +b0 <> bt:
              match p1s:
                case []: []
                case +a1 <> ct:
                  match q1s:
                    case []: []
                    case +b1 <> dt:
                      +ea = Nat.add(Nat.mul(si, n), i)
                      +np = Nat.mul(nst, n)
                      fs_one(side_ss(p, s, a0), a0, b0, a1, b1, ea, Nat.add(Nat.mul(si, n), Nat.mod(Nat.add(i, 1n), n)),
                        Nat.add(np, ea), Nat.add(np, Nat.add(Nat.mul(Nat.mod(Nat.add(si, 1n), nst), n), i)), nd) <>
                        f_es(pt, at, bt, ct, dt, s, si, Nat.add(i, 1n), n, nst, nd)

def f_all(ss: List<&2, SN>, rs0: List<&2, List<&2, V.Point>>, rs1: List<&2, List<&2, V.Point>>, +ps: List<&2, PP>,
    +si: Nat, +n: Nat, +nst: Nat, +nd: U64) -> List<&2, BD.FS>:
  match ss:
    case []: []
    case +s <> st:
      match rs0:
        case []: []
        case +r0 <> r0t:
          match rs1:
            case []: []
            case +r1 <> r1t:
              List.append(&2, BD.FS, f_es(ps, r0, rot_pt(r0), r1, rot_pt(r1), s, si, 0n, n, nst, nd),
                f_all(st, r0t, r1t, ps, Nat.add(si, 1n), n, nst, nd))

def g_real(g: G.GVal) -> Bool:
  match g:
    case G.GV_f{x}: False{}
    case _: True{}

def fs_ok(fs: List<&2, BD.FS>) -> Bool:
  match fs:
    case []: True{}
    case f <> t:
      BD.FS{sh, g, same, lps, fn} = f
      Bool.and(g_real(g), fs_ok(t))

def build(+pr: PR, +prof: F.Lp, +nd: U64) -> RV.RR:
  +sns = pr_sns(pr)
  +ps = pps_of(RV.lp_sgs(RV.as_path(prof)))
  +n = List.length(&2, PP, ps)
  +nst = List.length(&2, SN, sns)
  +rs = rows(sns, ps)
  +rs1 = rot_rw(rs)
  +es = List.append(&2, Ty.Edge, a_all(sns, rot_sn(sns), rs, rs1, ps, 0n, n, Nat.mul(nst, n)), p_all(sns, ps, 0n, n))
  +fs = f_all(sns, rs, rs1, ps, 0n, n, nst, nd)
  +ok = Bool.and(clear_ok(sns, umin(ps, 1.0e300f64), umax(ps, F64.neg(1.0e300f64))), fs_ok(fs))
  Bool.pick(RV.RR, ok, RV.RR{0u64, 0n, RV.sec_bt(vxs(rs), es, fs)}, RV.sec_bad(25u64))

def sweep(+pr: PR, +prof: F.Lp, +nd: U64) -> RV.RR:
  Bool.pick(RV.RR, U64.is_eq(pr_code(pr), 0u64), build(pr, prof, nd), RV.sec_bad(pr_code(pr)))
