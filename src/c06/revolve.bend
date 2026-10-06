import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../c04/types.bend as Ty
import ../base/par.bend as B
import ../base/ex.bend as E
import ./prof.bend as F
import ./build.bend as BD

type RV is Data:
  RV{ l: F.Lp, k: Nat, hole: Bool, sh: Nat }

type VI is Data:
  VI{ x: F64, y: F64, b: Nat, n: Nat, jn: Bool }

type CN is Data:
  CN{ ok: Bool, ha: F64, k: F64 }

type SS is Data:
  SS{ ok: Bool, s: G.GVal, same: Bool, plane: Bool }

type RA is Data:
  RA{ vs: List<&2, Ty.Vertex>, es: List<&2, Ty.Edge>, fs: List<&2, BD.FS>, nv: Nat, ne: Nat }

type RR is Data:
  RR{ code: U64, lp: Nat, b: BD.Bt }

def q_seg(+cx: F64, +cy: F64, +r: F64, +a: V.Vec2, +b: V.Vec2) -> F.Sg:
  F.G_ar{cx, cy, r, True{}, [F.mk_ar(cx, cy, V.v2_x(a), V.v2_y(a), V.v2_x(b), V.v2_y(b))]}

def circ_path(+cx: F64, +cy: F64, +r: F64) -> F.Lp:
  +e = {V.V2{F64.add(cx, r), cy} : V.Vec2}
  +n = {V.V2{cx, F64.add(cy, r)} : V.Vec2}
  +w = {V.V2{F64.sub(cx, r), cy} : V.Vec2}
  +s = {V.V2{cx, F64.sub(cy, r)} : V.Vec2}
  F.K_path{[q_seg(cx, cy, r, e, n), q_seg(cx, cy, r, n, w), q_seg(cx, cy, r, w, s), q_seg(cx, cy, r, s, e)]}

def as_path(l: F.Lp) -> F.Lp:
  match l:
    case F.K_circ{cx, cy, r}: circ_path(cx, cy, r)
    case F.K_path{sgs}: F.K_path{sgs}

def pc_xmin(p: F.Pc) -> F64:
  match p:
    case F.P_ln{ax, ay, bx, by}: F64.min(ax, bx)
    case F.P_ar{ax, ay, px, py, w, bx, by}: F64.min(F64.min(ax, bx), px)

def pc_axis(p: F.Pc) -> Bool:
  match p:
    case F.P_ln{ax, ay, bx, by}: Bool.and(F64.is_eq(ax, 0.0f64), F64.is_eq(bx, 0.0f64))
    case F.P_ar{ax, ay, px, py, w, bx, by}: False{}

def pc_p1ok(p: F.Pc) -> Bool:
  match p:
    case F.P_ln{ax, ay, bx, by}: True{}
    case F.P_ar{ax, ay, px, py, w, bx, by}: F64.is_lt(0.0f64, px)

def pcs_ax_code(ps: List<&2, F.Pc>, +hole: Bool) -> U64:
  match ps:
    case []: 0u64
    case +p <> t:
      +neg = F64.is_lt(pc_xmin(p), 0.0f64)
      +touch = Bool.and(hole, F64.is_le(pc_xmin(p), 0.0f64))
      +bad = Bool.or(neg, Bool.or(touch, Bool.not(pc_p1ok(p))))
      Bool.pick(U64, bad, Bool.pick(U64, touch, 21u64, 20u64), pcs_ax_code(t, hole))

def pinch_go(ps: List<&2, F.Pc>, +prev_ax: Bool, +first_ax: Bool) -> U64:
  match ps:
    case []: 0u64
    case +p <> t:
      +on = F64.is_eq(F.pc_ax(p), 0.0f64)
      +ax = pc_axis(p)
      +bad = Bool.and(on, Bool.and(Bool.not(prev_ax), Bool.not(ax)))
      +both = Bool.and(prev_ax, ax)
      Bool.pick(U64, bad, 22u64, Bool.pick(U64, both, 23u64, pinch_go(t, ax, first_ax)))

def last_ax(ps: List<&2, F.Pc>, +d: Bool) -> Bool:
  match ps:
    case []: d
    case +p <> t: last_ax(t, pc_axis(p))

def ax_code(+l: F.Lp, +hole: Bool) -> U64:
  +ps = F.lp_pcs(l)
  +c = pcs_ax_code(ps, hole)
  Bool.pick(U64, U64.is_eq(c, 0u64), pinch_go(ps, last_ax(ps, False{}), False{}), c)

def nf(+n: Nat) -> F64:
  U64.to_f64(U64.from_nat(n))

def vcount(+x: F64) -> Nat:
  Bool.pick(Nat, F64.is_lt(0.0f64, x), 2n, 1n)

def has_n(xs: List<&2, Nat>, +i: Nat) -> Bool:
  match xs:
    case []: False{}
    case x <> t: Bool.or(Nat.is_eq(x, i), has_n(t, i))

def vi_go(ps: List<&2, F.Pc>, +b: Nat, +js: List<&2, Nat>, +i: Nat) -> List<&2, VI>:
  match ps:
    case []: []
    case +p <> t:
      +x = F.pc_ax(p)
      VI{x, F.pc_ay(p), b, vcount(x), has_n(js, i)} <> vi_go(t, Nat.add(b, vcount(x)), js, Nat.add(i, 1n))

def vi_b(v: VI) -> Nat:
  VI{x, y, b, n, jn} = v
  b

def vi_x(v: VI) -> F64:
  VI{x, y, b, n, jn} = v
  x

def vi_y(v: VI) -> F64:
  VI{x, y, b, n, jn} = v
  y

def vi_off(v: VI) -> Bool:
  F64.is_lt(0.0f64, vi_x(v))

def vi_jn(v: VI) -> Bool:
  VI{x, y, b, n, jn} = v
  jn

def vi_circ(+v: VI) -> Bool:
  Bool.and(vi_off(v), vi_jn(v))

def vi_plus(+v: VI) -> Nat:
  vi_b(v)

def vi_minus(+v: VI) -> Nat:
  Bool.pick(Nat, vi_off(v), Nat.add(vi_b(v), 1n), vi_b(v))

def vi_pts(vs: List<&2, VI>) -> List<&2, Ty.Vertex>:
  match vs:
    case []: []
    case +v <> t:
      +x = vi_x(v)
      +y = vi_y(v)
      List.append(&2, Ty.Vertex, Bool.pick(List<&2, Ty.Vertex>, vi_off(v),
        [Ty.Vx{0u64, V.Pt{x, 0.0f64, y}}, Ty.Vx{0u64, V.Pt{F64.neg(x), 0.0f64, y}}],
        [Ty.Vx{0u64, V.Pt{0.0f64, 0.0f64, y}}]), vi_pts(t))

def vi_nth(vs: List<&2, VI>, +i: Nat) -> VI:
  match vs:
    case []: VI{0.0f64, 0.0f64, 0n, 0n, False{}}
    case v <> t:
      match i:
        case 0n: v
        case 1n+j: vi_nth(t, j)

def circ_es(vs: List<&2, VI>) -> List<&2, Ty.Edge>:
  match vs:
    case []: []
    case +v <> t:
      +x = vi_x(v)
      +c = {G.Cc{V.Pt{0.0f64, 0.0f64, vi_y(v)}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}, x} : G.Circle3}
      List.append(&2, Ty.Edge, Bool.pick(List<&2, Ty.Edge>, vi_circ(v),
        [Ty.Ed{0u64, BD.hv(vi_plus(v)), BD.hv(vi_minus(v)), Ty.EK_curve{G.GV_cc{c}, G.Dom{0.0f64, 1.0f64}}},
         Ty.Ed{0u64, BD.hv(vi_minus(v)), BD.hv(vi_plus(v)), Ty.EK_curve{G.GV_cc{c}, G.Dom{F64.neg(1.0f64), 0.0f64}}}], []),
        circ_es(t))

def off_before(vs: List<&2, VI>, +i: Nat) -> Nat:
  match vs:
    case []: 0n
    case +v <> t:
      match i:
        case 0n: 0n
        case 1n+j: Nat.add(Bool.pick(Nat, vi_circ(v), 1n, 0n), off_before(t, j))

def seam_rev(+p: F.Pc, +s: F64) -> Bool:
  match p:
    case F.P_ln{+ax, +ay, +bx, +by}:
      Bool.pick(Bool, F64.is_eq(ax, bx), F64.is_lt(by, ay),
        Bool.pick(Bool, F64.is_eq(ay, by), F64.is_lt(F64.mul(s, bx), F64.mul(s, ax)), False{}))
    case F.P_ar{ax, ay, px, py, w, bx, by}: False{}

def seam_kind(p: F.Pc, +s: F64) -> Ty.EdgeKind:
  match p:
    case F.P_ln{+ax, +ay, +bx, +by}:
      Bool.pick(Ty.EdgeKind, F64.is_eq(ax, bx),
        Ty.EK_curve{G.GV_ln{G.Ln{V.Pt{F64.mul(s, ax), 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}}},
          G.Dom{F64.min(ay, by), F64.max(ay, by)}},
        Bool.pick(Ty.EdgeKind, F64.is_eq(ay, by),
          Ty.EK_curve{G.GV_ln{G.Ln{V.Pt{0.0f64, 0.0f64, ay}, V.Dr{1.0f64, 0.0f64, 0.0f64}}},
            G.Dom{F64.min(F64.mul(s, ax), F64.mul(s, bx)), F64.max(F64.mul(s, ax), F64.mul(s, bx))}},
          Ty.EK_curve{G.GV_bz{G.Bz{V.Pt{F64.mul(s, ax), 0.0f64, ay}, V.Pt{F64.mul(s, ax), 0.0f64, ay},
            V.Pt{F64.mul(s, bx), 0.0f64, by}, V.Pt{F64.mul(s, bx), 0.0f64, by}}}, G.Dom{0.0f64, 1.0f64}}))
    case F.P_ar{ax, ay, px, py, w, bx, by}:
      Ty.EK_curve{G.GV_rq{G.Rq{V.Pt{F64.mul(s, ax), 0.0f64, ay}, V.Pt{F64.mul(s, px), 0.0f64, py},
        V.Pt{F64.mul(s, bx), 0.0f64, by}, 1.0f64, w, 1.0f64}}, G.Dom{0.0f64, 1.0f64}}

def seam_ed(+p: F.Pc, +s: F64, +va: Nat, +vb: Nat) -> Ty.Edge:
  +r = seam_rev(p, s)
  Ty.Ed{0u64, BD.hv(Bool.pick(Nat, r, vb, va)), BD.hv(Bool.pick(Nat, r, va, vb)), seam_kind(p, s)}

def seam_es(ps: List<&2, F.Pc>, +vs: List<&2, VI>, +i: Nat, +n: Nat) -> List<&2, Ty.Edge>:
  match ps:
    case []: []
    case +p <> t:
      +a = vi_nth(vs, i)
      +b = vi_nth(vs, BD.nxt(i, n))
      List.append(&2, Ty.Edge, Bool.pick(List<&2, Ty.Edge>, pc_axis(p), [],
        [seam_ed(p, 1.0f64, vi_plus(a), vi_plus(b)), seam_ed(p, F64.neg(1.0f64), vi_minus(a), vi_minus(b))]),
        seam_es(t, vs, Nat.add(i, 1n), n))

def nax_before(ps: List<&2, F.Pc>, +i: Nat) -> Nat:
  match ps:
    case []: 0n
    case +p <> t:
      match i:
        case 0n: 0n
        case 1n+j: Nat.add(Bool.pick(Nat, pc_axis(p), 0n, 1n), nax_before(t, j))

def tr2(+x: F64, +y: F64, +plane: Bool) -> V.Vec2:
  Bool.pick(V.Vec2, plane, V.V2{x, 0.0f64}, V.V2{x, y})

def seam_use(+p: F.Pc, +e: Nat, +s: F64, +along: Bool, +plane: Bool) -> BD.Use:
  +r = seam_rev(p, s)
  +ta = tr2(F64.mul(s, F.pc_ax(p)), F.pc_ay(p), plane)
  +tb = tr2(F64.mul(s, F.pc_bx(p)), F.pc_by(p), plane)
  BD.Us{e, Bool.xor(along, r), Bool.pick(V.Vec2, r, tb, ta), Bool.pick(V.Vec2, r, ta, tb)}

def seam_uses(ps: List<&2, F.Pc>, +j: Nat, +all: List<&2, F.Pc>, +sb: Nat, +side: Nat, +s: F64, +along: Bool,
    +plane: Bool) -> List<&2, BD.Use>:
  match ps:
    case []: []
    case +p <> t:
      seam_use(p, Nat.add(sb, Nat.add(Nat.mul(2n, nax_before(all, j)), side)), s, along, plane) <>
        seam_uses(t, Nat.add(j, 1n), all, sb, side, s, along, plane)

def circ_use(+v: VI, +e: Nat, +up: Bool, +along: Bool, +plane: Bool) -> List<&2, BD.Use>:
  +x = vi_x(v)
  +pp = tr2(x, vi_y(v), plane)
  +pm = tr2(F64.neg(x), vi_y(v), plane)
  Bool.pick(List<&2, BD.Use>, vi_off(v),
    [BD.Us{Nat.add(e, Bool.pick(Nat, up, 0n, 1n)), along, Bool.pick(V.Vec2, up, pp, pm), Bool.pick(V.Vec2, up, pm, pp)}], [])

def us_rev(xs: List<&2, BD.Use>, +acc: List<&2, BD.Use>) -> List<&2, BD.Use>:
  match xs:
    case []: acc
    case x <> t: us_rev(t, x <> acc)

def cands(+x: F64) -> List<&2, F64>:
  [x, E.f64_next_up(x), E.f64_next_down(x), E.f64_next_up(E.f64_next_up(x)), E.f64_next_down(E.f64_next_down(x)),
    E.f64_next_up(E.f64_next_up(E.f64_next_up(x))), E.f64_next_down(E.f64_next_down(E.f64_next_down(x)))]

def cone_ok(+ha: F64, +k: F64, +xa: F64, +ya: F64, +xb: F64, +yb: F64) -> Bool:
  +s = {G.GV_co{G.Co{V.Pt{0.0f64, 0.0f64, ha}, V.Dr{0.0f64, 0.0f64, 1.0f64}, k}} : G.GVal}
  Bool.and(F64.is_lt(0.0f64, k), Bool.and(GO.q_on_r(s, V.Pt{xa, 0.0f64, ya}), GO.q_on_r(s, V.Pt{xb, 0.0f64, yb})))

def cn_ok(c: CN) -> Bool:
  CN{ok, ha, k} = c
  ok

def cn_ks(ks: List<&2, F64>, +ha: F64, +xa: F64, +ya: F64, +xb: F64, +yb: F64, +best: CN) -> CN:
  match ks:
    case []: best
    case +k <> t:
      +ok = Bool.and(Bool.not(cn_ok(best)), cone_ok(ha, k, xa, ya, xb, yb))
      cn_ks(t, ha, xa, ya, xb, yb, Bool.pick(CN, ok, CN{True{}, ha, k}, best))

def cn_has(hs: List<&2, F64>, +ks: List<&2, F64>, +xa: F64, +ya: F64, +xb: F64, +yb: F64, +best: CN) -> CN:
  match hs:
    case []: best
    case +h <> t: cn_has(t, ks, xa, ya, xb, yb, cn_ks(ks, h, xa, ya, xb, yb, best))

def cone_find(+xa: F64, +ya: F64, +xb: F64, +yb: F64) -> CN:
  +k0 = F64.div(F64.abs(F64.sub(xb, xa)), F64.abs(F64.sub(yb, ya)))
  +h0 = F64.sub(ya, F64.div(F64.mul(xa, F64.sub(yb, ya)), F64.sub(xb, xa)))
  +hs = Bool.pick(List<&2, F64>, F64.is_eq(xa, 0.0f64), [ya], Bool.pick(List<&2, F64>, F64.is_eq(xb, 0.0f64), [yb], cands(h0)))
  cn_has(hs, cands(k0), xa, ya, xb, yb, CN{False{}, 0.0f64, 0.0f64})

def ss_cone(c: CN, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> SS:
  CN{ok, +ha, +k} = c
  +ym = F64.mul(0.5f64, F64.add(ay, by))
  +sg = Bool.pick(F64, F64.is_lt(ha, ym), 1.0f64, F64.neg(1.0f64))
  +d = F64.add(F64.sub(by, ay), F64.mul(F64.mul(F64.sub(bx, ax), k), sg))
  SS{ok, G.GV_co{G.Co{V.Pt{0.0f64, 0.0f64, ha}, V.Dr{0.0f64, 0.0f64, sg}, k}}, F64.is_lt(0.0f64, d), False{}}

def ss_line(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> SS:
  Bool.pick(SS, F64.is_eq(ax, bx),
    SS{True{}, G.GV_cy{G.Cy{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, ax}}, F64.is_lt(ay, by), False{}},
    Bool.pick(SS, F64.is_eq(ay, by),
      SS{True{}, G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, ay}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}}},
        F64.is_lt(bx, ax), True{}},
      ss_cone(cone_find(ax, ay, bx, by), ax, ay, bx, by)))

def ss_of(s: F.Sg) -> SS:
  match s:
    case F.G_ln{p}:
      match p:
        case F.P_ln{ax, ay, bx, by}: ss_line(ax, ay, bx, by)
        case F.P_ar{ax, ay, px, py, w, bx, by}: SS{False{}, G.GV_f{0.0f64}, True{}, False{}}
    case F.G_ar{+cx, +cy, +r, +ccw, ps}:
      Bool.pick(SS, F64.is_eq(cx, 0.0f64), SS{True{}, G.GV_sp{G.Sp{V.Pt{0.0f64, 0.0f64, cy}, r}}, ccw, False{}},
        SS{F64.is_lt(0.0f64, cx), G.GV_to{G.To{V.Pt{0.0f64, 0.0f64, cy}, V.Dr{0.0f64, 0.0f64, 1.0f64}, cx, r}}, ccw, False{}})

def ss_s(x: SS) -> G.GVal:
  SS{ok, s, same, plane} = x
  s

def ss_same(x: SS) -> Bool:
  SS{ok, s, same, plane} = x
  same

def ss_plane(x: SS) -> Bool:
  SS{ok, s, same, plane} = x
  plane

def ss_ok(x: SS) -> Bool:
  SS{ok, s, same, plane} = x
  ok

def sg_axis(s: F.Sg) -> Bool:
  match s:
    case F.G_ln{p}: pc_axis(p)
    case F.G_ar{cx, cy, r, ccw, ps}: False{}

def seg_fs(+s: F.Sg, +p0: Nat, +all: List<&2, F.Pc>, +vs: List<&2, VI>, +n: Nat, +cb: Nat, +sb: Nat, +sh: Nat,
    +nd: U64, +lk: Nat, +si: Nat) -> List<&2, BD.FS>:
  +ps = F.sg_pcs(s)
  +k = List.length(&2, F.Pc, ps)
  +a = vi_nth(vs, p0)
  +b = vi_nth(vs, BD.nxt(Nat.sub(Nat.add(p0, k), 1n), n))
  +ia = Nat.add(cb, Nat.mul(2n, off_before(vs, p0)))
  +ib = Nat.add(cb, Nat.mul(2n, off_before(vs, BD.nxt(Nat.sub(Nat.add(p0, k), 1n), n))))
  +x = ss_of(s)
  +pl = ss_plane(x)
  +up = List.append(&2, BD.Use, circ_use(a, ia, True{}, True{}, pl), List.append(&2, BD.Use,
    seam_uses(ps, p0, all, sb, 1n, F64.neg(1.0f64), True{}, pl), List.append(&2, BD.Use, circ_use(b, ib, True{}, False{}, pl),
      us_rev(seam_uses(ps, p0, all, sb, 0n, 1.0f64, False{}, pl), []))))
  +lo = List.append(&2, BD.Use, circ_use(a, ia, False{}, True{}, pl), List.append(&2, BD.Use,
    seam_uses(ps, p0, all, sb, 0n, 1.0f64, True{}, pl), List.append(&2, BD.Use, circ_use(b, ib, False{}, False{}, pl),
      us_rev(seam_uses(ps, p0, all, sb, 1n, F64.neg(1.0f64), False{}, pl), []))))
  Bool.pick(List<&2, BD.FS>, sg_axis(s), [],
    [BD.FS{sh, ss_s(x), ss_same(x), [up], BD.Fn{nd, lk, 3u64, si, 0n}},
     BD.FS{sh, ss_s(x), ss_same(x), [lo], BD.Fn{nd, lk, 3u64, si, 1n}}])

def sgs_fs(ss: List<&2, F.Sg>, +p0: Nat, +all: List<&2, F.Pc>, +vs: List<&2, VI>, +n: Nat, +cb: Nat, +sb: Nat, +sh: Nat,
    +nd: U64, +lk: Nat, +si: Nat) -> List<&2, BD.FS>:
  match ss:
    case []: []
    case +s <> t:
      List.append(&2, BD.FS, seg_fs(s, p0, all, vs, n, cb, sb, sh, nd, lk, si),
        sgs_fs(t, Nat.add(p0, F.sg_npc(s)), all, vs, n, cb, sb, sh, nd, lk, Nat.add(si, 1n)))

def sgs_ssok(ss: List<&2, F.Sg>) -> Bool:
  match ss:
    case []: True{}
    case +s <> t: Bool.and(Bool.or(sg_axis(s), ss_ok(ss_of(s))), sgs_ssok(t))

def lp_sgs(l: F.Lp) -> List<&2, F.Sg>:
  match l:
    case F.K_path{sgs}: sgs
    case F.K_circ{cx, cy, r}: []

def ra_add(a: RA, +l: F.Lp, +li: Nat, +nd: U64) -> RA:
  RA{+vs0, +es0, +fs0, +nv, +ne} = a
  +ps = F.lp_pcs(l)
  +n = List.length(&2, F.Pc, ps)
  +vis = vi_go(ps, nv, BD.sg_starts(lp_sgs(l), 0n), 0n)
  +vx = vi_pts(vis)
  +ce = circ_es(vis)
  +se = seam_es(ps, vis, 0n, n)
  +cb = ne
  +sb = Nat.add(ne, List.length(&2, Ty.Edge, ce))
  +fs = sgs_fs(lp_sgs(l), 0n, ps, vis, n, cb, sb, li, nd, li, 0n)
  RA{List.append(&2, Ty.Vertex, vs0, vx), List.append(&2, Ty.Edge, es0, List.append(&2, Ty.Edge, ce, se)),
    List.append(&2, BD.FS, fs0, fs), Nat.add(nv, List.length(&2, Ty.Vertex, vx)),
    Nat.add(ne, Nat.add(List.length(&2, Ty.Edge, ce), List.length(&2, Ty.Edge, se)))}

def ras_go(ls: List<&2, F.Lp>, +i: Nat, +nd: U64, +a: RA) -> RA:
  match ls:
    case []: a
    case l <> t: ras_go(t, Nat.add(i, 1n), nd, ra_add(a, l, i, nd))

def vx_gen(vs: List<&2, Ty.Vertex>, +i: Nat) -> List<&2, Ty.Vertex>:
  match vs:
    case []: []
    case v <> t:
      Ty.Vx{g, p} = v
      Ty.Vx{U64.from_nat(Nat.add(i, 1n)), p} <> vx_gen(t, Nat.add(i, 1n))

def holes_of(ps: List<&2, Nat>, rs: List<&2, Bool>, +o: Nat, +i: Nat) -> List<&2, Ty.HShell>:
  match ps:
    case []: []
    case +p <> pt:
      match rs:
        case []: []
        case +h <> rt:
          +rest = holes_of(pt, rt, o, Nat.add(i, 1n))
          Bool.pick(List<&2, Ty.HShell>, Bool.and(h, Nat.is_eq(p, Nat.add(o, 1n))),
            Ty.HS{i, U64.from_nat(Nat.add(i, 1n))} <> rest, rest)

def sos_go(rs: List<&2, Bool>, +ps: List<&2, Nat>, +rs_all: List<&2, Bool>, +i: Nat, +k: Nat) -> List<&2, Ty.Solid>:
  match rs:
    case []: []
    case +h <> t:
      +rest = sos_go(t, ps, rs_all, Nat.add(i, 1n), Bool.pick(Nat, h, k, Nat.add(k, 1n)))
      Bool.pick(List<&2, Ty.Solid>, h, rest,
        Ty.So{U64.from_nat(Nat.add(k, 1n)), Ty.HS{i, U64.from_nat(Nat.add(i, 1n))}, holes_of(ps, rs_all, i, 0n)} <> rest)

def shs_go(rs: List<&2, List<&2, Ty.HFace>>, hs: List<&2, Bool>, +i: Nat) -> List<&2, Ty.Shell>:
  match rs:
    case []: []
    case r <> t:
      match hs:
        case []: []
        case +h <> u:
          Ty.Sh{U64.from_nat(Nat.add(i, 1n)), r, Bool.pick(Ty.ShellKind, h, Ty.SK_inner{}, Ty.SK_outer{})} <> shs_go(t, u, Nat.add(i, 1n))

def n_sol(rs: List<&2, Bool>) -> Nat:
  match rs:
    case []: 0n
    case +h <> t: Nat.add(Bool.pick(Nat, h, 0n, 1n), n_sol(t))

def ra_vs(a: RA) -> List<&2, Ty.Vertex>:
  RA{vs, es, fs, nv, ne} = a
  vs

def ra_es(a: RA) -> List<&2, Ty.Edge>:
  RA{vs, es, fs, nv, ne} = a
  es

def ra_fs(a: RA) -> List<&2, BD.FS>:
  RA{vs, es, fs, nv, ne} = a
  fs

def rev_brep(+ls: List<&2, F.Lp>, +ps: List<&2, Nat>, +hs: List<&2, Bool>, +nd: U64) -> BD.Bt:
  +a = ras_go(ls, 0n, nd, RA{[], [], [], 0n, 0n})
  +vs = ra_vs(a)
  +es = ra_es(a)
  +fs = ra_fs(a)
  +st = BD.fs_emit(fs, BD.St{0n, 0n, [], [], []}, 0n)
  +runs = BD.sol_runs(fs, 0n, 0n, [])
  +sos = sos_go(hs, ps, hs, 0n, 0n)
  +ns = n_sol(hs)
  BD.Bt{BD.st_br(st, vx_gen(vs, 0n), BD.ed_gen(es, 0n), shs_go(runs, hs, 0n), sos, Ty.Cp{BD.hsos_of(ns, 0n), []}),
    BD.fs_names(fs)}

def lps_prep(ls: List<&2, F.Lp>, hs: List<&2, Bool>) -> List<&2, F.Lp>:
  match ls:
    case []: []
    case l <> t:
      match hs:
        case []: []
        case +h <> u:
          +p = as_path(l)
          Bool.pick(F.Lp, h, F.lp_rev(p), p) <> lps_prep(t, u)

def ax_codes(ls: List<&2, F.Lp>, hs: List<&2, Bool>, +i: Nat) -> F.Er:
  match ls:
    case []: F.er(0u64, 0n, 0n)
    case +l <> t:
      match hs:
        case []: F.er(0u64, 0n, 0n)
        case +h <> u:
          +c = ax_code(l, h)
          +c2 = Bool.pick(U64, U64.is_eq(c, 0u64), Bool.pick(U64, sgs_ssok(lp_sgs(l)), 0u64, 24u64), c)
          Bool.pick(F.Er, U64.is_eq(c2, 0u64), ax_codes(t, u, Nat.add(i, 1n)), F.er(c2, i, 0n))
