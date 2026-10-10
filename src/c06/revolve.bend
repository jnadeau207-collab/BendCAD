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

# Partial revolution (90/180/270). Stations are exact quarter turns.
# 360 stays on rev_brep. An arc profile is code 24, not a stand-in.

def sec_mod4(+n: Nat) -> Nat:
  Nat.sub(n, Nat.mul(Nat.div(n, 4n), 4n))

def sec_cos(+m: Nat) -> F64:
  match m:
    case 0n: 1.0f64
    case 1n: 0.0f64
    case 2n: F64.neg(1.0f64)
    case _: 0.0f64

def sec_sin(+m: Nat) -> F64:
  match m:
    case 0n: 0.0f64
    case 1n: 1.0f64
    case 2n: 0.0f64
    case _: F64.neg(1.0f64)

def sec_bad(+c: U64) -> RR:
  RR{c, 0n, BD.Bt{Ty.brep_empty(), []}}

def sec_arc(ss: List<&2, F.Sg>) -> Bool:
  match ss:
    case []: False{}
    case s <> t:
      match s:
        case F.G_ar{cx, cy, r, ccw, ps}: True{}
        case F.G_ln{p}: sec_arc(t)

def sec_one(ls: List<&2, F.Lp>, hs: List<&2, Bool>) -> Bool:
  match ls:
    case []: False{}
    case l <> t:
      match t:
        case []:
          match hs:
            case []: False{}
            case h <> u:
              match u:
                case []: Bool.and(Bool.not(h), Bool.not(sec_arc(lp_sgs(l))))
                case _: False{}
        case _: False{}

def sec_lp0(ls: List<&2, F.Lp>) -> F.Lp:
  match ls:
    case []: F.K_circ{0.0f64, 0.0f64, 0.0f64}
    case l <> t: l

def pc_nth(ps: List<&2, F.Pc>, +i: Nat) -> F.Pc:
  match ps:
    case []: F.P_ln{0.0f64, 0.0f64, 0.0f64, 0.0f64}
    case p <> t:
      match i:
        case 0n: p
        case 1n+j: pc_nth(t, j)

def sec_r(+p: F.Pc) -> F64:
  F.pc_ax(p)

def sec_z(+p: F.Pc) -> F64:
  F.pc_ay(p)

def sec_pt(+ps: List<&2, F.Pc>, +n: Nat, +vi: Nat) -> V.Point:
  +s = Nat.div(vi, n)
  +i = Nat.sub(vi, Nat.mul(s, n))
  +p = pc_nth(ps, i)
  +m = sec_mod4(s)
  +r = sec_r(p)
  V.Pt{F64.mul(r, sec_cos(m)), F64.mul(r, sec_sin(m)), sec_z(p)}

def sec_vs_row(left: Nat, +ps: List<&2, F.Pc>, +n: Nat, +s: Nat, +i: Nat) -> List<&2, Ty.Vertex>:
  match left:
    case 0n: []
    case 1n+k:
      Ty.Vx{0u64, sec_pt(ps, n, Nat.add(Nat.mul(s, n), i))} <> sec_vs_row(k, ps, n, s, Nat.add(i, 1n))

def sec_vs_all(left: Nat, +ps: List<&2, F.Pc>, +n: Nat, +s: Nat) -> List<&2, Ty.Vertex>:
  match left:
    case 0n: []
    case 1n+k:
      List.append(&2, Ty.Vertex, sec_vs_row(n, ps, n, s, 0n), sec_vs_all(k, ps, n, Nat.add(s, 1n)))

def sec_vs(+ps: List<&2, F.Pc>, +n: Nat, +stations: Nat) -> List<&2, Ty.Vertex>:
  sec_vs_all(stations, ps, n, 0n)

def rq_gv(r: G.GRes) -> G.GVal:
  match r:
    case G.Gok{v}: v
    case G.Gerr{kind}: G.GV_f{0.0f64}

def sec_arc_gv(+ps: List<&2, F.Pc>, +n: Nat, +s: Nat, +i: Nat) -> G.GVal:
  +p = pc_nth(ps, i)
  +m = sec_mod4(s)
  +c = sec_cos(m)
  +sn = sec_sin(m)
  rq_gv(GO.rq_quarter(V.Pt{0.0f64, 0.0f64, sec_z(p)}, V.Dr{c, sn, 0.0f64}, V.Dr{F64.neg(sn), c, 0.0f64}, sec_r(p)))

def sec_bz(+a: V.Point, +b: V.Point) -> G.GVal:
  G.GV_bz{G.Bz{a, a, b, b}}

def sec_imod_go(w: Bool, +i: Nat, +n: Nat) -> Nat:
  match w:
    case True{}: 0n
    case False{}: Nat.add(i, 1n)

def sec_imod(+i: Nat, +n: Nat) -> Nat:
  sec_imod_go(Nat.is_eq(Nat.add(i, 1n), n), i, n)

def v_at(+s: Nat, +i: Nat, +n: Nat) -> Nat:
  Nat.add(Nat.mul(s, n), i)

def a_at(+s: Nat, +i: Nat, +n: Nat) -> Nat:
  Nat.add(Nat.mul(s, n), i)

def p_at(+s: Nat, +i: Nat, +n: Nat, +quads: Nat) -> Nat:
  Nat.add(Nat.mul(quads, n), Nat.add(Nat.mul(s, n), i))

def sec_ed(+v0: Nat, +v1: Nat, +g: G.GVal) -> Ty.Edge:
  Ty.Ed{0u64, BD.hv(v0), BD.hv(v1), Ty.EK_curve{g, G.Dom{0.0f64, 1.0f64}}}

def sec_arcs_row(left: Nat, +ps: List<&2, F.Pc>, +n: Nat, +s: Nat, +i: Nat) -> List<&2, Ty.Edge>:
  match left:
    case 0n: []
    case 1n+k:
      sec_ed(v_at(s, i, n), v_at(Nat.add(s, 1n), i, n), sec_arc_gv(ps, n, s, i)) <>
        sec_arcs_row(k, ps, n, s, Nat.add(i, 1n))

def sec_arcs_all(left: Nat, +ps: List<&2, F.Pc>, +n: Nat, +s: Nat) -> List<&2, Ty.Edge>:
  match left:
    case 0n: []
    case 1n+k:
      List.append(&2, Ty.Edge, sec_arcs_row(n, ps, n, s, 0n), sec_arcs_all(k, ps, n, Nat.add(s, 1n)))

def sec_prof_row(left: Nat, +ps: List<&2, F.Pc>, +n: Nat, +s: Nat, +i: Nat) -> List<&2, Ty.Edge>:
  match left:
    case 0n: []
    case 1n+k:
      +j = sec_imod(i, n)
      sec_ed(v_at(s, i, n), v_at(s, j, n), sec_bz(sec_pt(ps, n, v_at(s, i, n)), sec_pt(ps, n, v_at(s, j, n)))) <>
        sec_prof_row(k, ps, n, s, Nat.add(i, 1n))

def sec_prof_all(left: Nat, +ps: List<&2, F.Pc>, +n: Nat, +s: Nat) -> List<&2, Ty.Edge>:
  match left:
    case 0n: []
    case 1n+k:
      List.append(&2, Ty.Edge, sec_prof_row(n, ps, n, s, 0n), sec_prof_all(k, ps, n, Nat.add(s, 1n)))

def sec_es(+ps: List<&2, F.Pc>, +n: Nat, +quads: Nat) -> List<&2, Ty.Edge>:
  List.append(&2, Ty.Edge, sec_arcs_all(quads, ps, n, 0n), sec_prof_all(Nat.add(quads, 1n), ps, n, 0n))

def z2() -> V.Vec2:
  V.V2{0.0f64, 0.0f64}

def dot3(+px: F64, +py: F64, +pz: F64, +ox: F64, +oy: F64, +oz: F64, +ux: F64, +uy: F64, +uz: F64) -> F64:
  F64.add(F64.add(F64.mul(F64.sub(px, ox), ux), F64.mul(F64.sub(py, oy), uy)), F64.mul(F64.sub(pz, oz), uz))

def trim_uv(+p: V.Point, +o: V.Point, +u: V.Dir, +v: V.Dir) -> V.Vec2:
  V.Pt{+px, +py, +pz} = p
  V.Pt{+ox, +oy, +oz} = o
  V.Dr{+ux, +uy, +uz} = u
  V.Dr{+vx, +vy, +vz} = v
  V.V2{dot3(px, py, pz, ox, oy, oz, ux, uy, uz), dot3(px, py, pz, ox, oy, oz, vx, vy, vz)}

def trim_pl_go(pl: G.Plane3, +p: V.Point) -> V.Vec2:
  G.Pl{o, u, v} = pl
  trim_uv(p, o, u, v)

def trim_pl(+s: G.GVal, +p: V.Point) -> V.Vec2:
  match s:
    case G.GV_pl{pl}: trim_pl_go(pl, p)
    case _: z2()

def trim_of(plane: Bool, +s: G.GVal, +p: V.Point) -> V.Vec2:
  match plane:
    case False{}: z2()
    case True{}: trim_pl(s, p)

def us_e(+e: Nat, +fwd: Bool, +ta: V.Vec2, +tb: V.Vec2) -> BD.Use:
  BD.Us{e, fwd, ta, tb}

def sec_use(+e: Nat, +fwd: Bool, +v0: Nat, +v1: Nat, +plane: Bool, +s: G.GVal, +ps: List<&2, F.Pc>, +n: Nat) -> BD.Use:
  us_e(e, fwd, trim_of(plane, s, sec_pt(ps, n, v0)), trim_of(plane, s, sec_pt(ps, n, v1)))

def side_ss_p(+p: F.Pc) -> SS:
  match p:
    case F.P_ln{ax, ay, bx, by}: ss_line(ax, ay, bx, by)
    case F.P_ar{ax, ay, px, py, w, bx, by}: SS{False{}, G.GV_f{0.0f64}, True{}, False{}}

def pcs_ssok_t(ps: List<&2, F.Pc>) -> Bool:
  match ps:
    case []: True{}
    case p <> t: Bool.and(ss_ok(side_ss_p(p)), pcs_ssok_t(t))

def pcs_ssok(ps: List<&2, F.Pc>) -> Bool:
  pcs_ssok_t(ps)

def side_ss(+ps: List<&2, F.Pc>, +i: Nat) -> SS:
  side_ss_p(pc_nth(ps, i))

def cap_start() -> G.GVal:
  G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}}}

def cap_end(+s: Nat) -> G.GVal:
  +m = sec_mod4(s)
  G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{sec_cos(m), sec_sin(m), 0.0f64}}}

def nw_add(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64, +bz: F64, +nx: F64, +ny: F64, +nz: F64) -> List<&2, F64>:
  [F64.add(nx, F64.mul(F64.sub(ay, by), F64.add(az, bz))),
    F64.add(ny, F64.mul(F64.sub(az, bz), F64.add(ax, bx))),
    F64.add(nz, F64.mul(F64.sub(ax, bx), F64.add(ay, by)))]

def f3(+xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: 0.0f64
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: f3(t, j)

def sec_px(+p: V.Point) -> F64:
  V.Pt{x, y, z} = p
  x

def sec_py(+p: V.Point) -> F64:
  V.Pt{x, y, z} = p
  y

def sec_pz(+p: V.Point) -> F64:
  V.Pt{x, y, z} = p
  z

def nw_go(ps: List<&2, V.Point>, +fx: F64, +fy: F64, +fz: F64, +px: F64, +py: F64, +pz: F64, +nx: F64, +ny: F64, +nz: F64, +first: Bool) -> List<&2, F64>:
  match ps:
    case []: nw_add(px, py, pz, fx, fy, fz, nx, ny, nz)
    case +p <> t:
      match first:
        case True{}:
          +x = sec_px(p)
          +y = sec_py(p)
          +z = sec_pz(p)
          nw_go(t, x, y, z, x, y, z, nx, ny, nz, False{})
        case False{}:
          +x = sec_px(p)
          +y = sec_py(p)
          +z = sec_pz(p)
          +a = nw_add(px, py, pz, x, y, z, nx, ny, nz)
          nw_go(t, fx, fy, fz, x, y, z, f3(a, 0n), f3(a, 1n), f3(a, 2n), False{})

def cross_uv(+ux: F64, +uy: F64, +uz: F64, +vx: F64, +vy: F64, +vz: F64) -> List<&2, F64>:
  [F64.sub(F64.mul(uy, vz), F64.mul(uz, vy)), F64.sub(F64.mul(uz, vx), F64.mul(ux, vz)),
    F64.sub(F64.mul(ux, vy), F64.mul(uy, vx))]

def cap_dirs(+u: V.Dir, +v: V.Dir, +n: List<&2, F64>) -> Bool:
  V.Dr{+ux, +uy, +uz} = u
  V.Dr{+vx, +vy, +vz} = v
  +c = cross_uv(ux, uy, uz, vx, vy, vz)
  F64.is_lt(0.0f64, F64.add(F64.add(F64.mul(f3(n, 0n), f3(c, 0n)), F64.mul(f3(n, 1n), f3(c, 1n))), F64.mul(f3(n, 2n), f3(c, 2n))))

def cap_pl(pl: G.Plane3, +n: List<&2, F64>) -> Bool:
  G.Pl{o, u, v} = pl
  cap_dirs(u, v, n)

def cap_dot(+s: G.GVal, +n: List<&2, F64>) -> Bool:
  match s:
    case G.GV_pl{pl}: cap_pl(pl, n)
    case _: True{}

def cap_same(+ps: List<&2, V.Point>, +s: G.GVal) -> Bool:
  cap_dot(s, nw_go(ps, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, True{}))

def pts_start_row(left: Nat, +ps: List<&2, F.Pc>, +n: Nat, +i: Nat) -> List<&2, V.Point>:
  match left:
    case 0n: []
    case 1n+k: sec_pt(ps, n, i) <> pts_start_row(k, ps, n, Nat.add(i, 1n))

def pts_start(+ps: List<&2, F.Pc>, +n: Nat) -> List<&2, V.Point>:
  pts_start_row(n, ps, n, 0n)

def pts_end_ord(+k: Nat, +n: Nat) -> Nat:
  match k:
    case 0n: 0n
    case 1n+j: Nat.sub(n, Nat.add(j, 1n))

def pts_end_row(left: Nat, +ps: List<&2, F.Pc>, +n: Nat, +s: Nat, +k: Nat) -> List<&2, V.Point>:
  match left:
    case 0n: []
    case 1n+j: sec_pt(ps, n, v_at(s, pts_end_ord(k, n), n)) <> pts_end_row(j, ps, n, s, Nat.add(k, 1n))

def pts_end(+ps: List<&2, F.Pc>, +n: Nat, +s: Nat) -> List<&2, V.Point>:
  pts_end_row(n, ps, n, s, 0n)

def side_loop(+s: Nat, +i: Nat, +n: Nat, +quads: Nat, +plane: Bool, +surf: G.GVal, +ps: List<&2, F.Pc>) -> List<&2, BD.Use>:
  +j = sec_imod(i, n)
  [sec_use(a_at(s, i, n), True{}, v_at(s, i, n), v_at(Nat.add(s, 1n), i, n), plane, surf, ps, n),
    sec_use(p_at(Nat.add(s, 1n), i, n, quads), True{}, v_at(Nat.add(s, 1n), i, n), v_at(Nat.add(s, 1n), j, n), plane, surf, ps, n),
    sec_use(a_at(s, j, n), False{}, v_at(s, j, n), v_at(Nat.add(s, 1n), j, n), plane, surf, ps, n),
    sec_use(p_at(s, i, n, quads), False{}, v_at(s, i, n), v_at(s, j, n), plane, surf, ps, n)]

def cap0_row(left: Nat, +k: Nat, +n: Nat, +quads: Nat, +surf: G.GVal, +ps: List<&2, F.Pc>) -> List<&2, BD.Use>:
  match left:
    case 0n: []
    case 1n+j:
      sec_use(p_at(0n, k, n, quads), True{}, v_at(0n, k, n), v_at(0n, sec_imod(k, n), n), True{}, surf, ps, n) <>
        cap0_row(j, Nat.add(k, 1n), n, quads, surf, ps)

def cap0_loop(+i: Nat, +n: Nat, +quads: Nat, +surf: G.GVal, +ps: List<&2, F.Pc>) -> List<&2, BD.Use>:
  cap0_row(i, Nat.sub(n, i), n, quads, surf, ps)

def cap1_row(left: Nat, +k: Nat, +n: Nat, +s: Nat, +quads: Nat, +surf: G.GVal, +ps: List<&2, F.Pc>) -> List<&2, BD.Use>:
  match left:
    case 0n: []
    case 1n+j:
      sec_use(p_at(s, k, n, quads), False{}, v_at(s, k, n), v_at(s, sec_imod(k, n), n), True{}, surf, ps, n) <>
        cap1_row(j, Nat.sub(k, 1n), n, s, quads, surf, ps)

def cap1_go(z: Bool, +i: Nat, +n: Nat, +s: Nat, +quads: Nat, +surf: G.GVal, +ps: List<&2, F.Pc>) -> List<&2, BD.Use>:
  match z:
    case True{}: []
    case False{}: cap1_row(i, Nat.sub(i, 1n), n, s, quads, surf, ps)

def cap1_loop(+i: Nat, +n: Nat, +s: Nat, +quads: Nat, +surf: G.GVal, +ps: List<&2, F.Pc>) -> List<&2, BD.Use>:
  cap1_go(Nat.is_eq(i, 0n), i, n, s, quads, surf, ps)

def sides_row(left: Nat, +ps: List<&2, F.Pc>, +n: Nat, +s: Nat, +i: Nat, +quads: Nat, +nd: U64, +fi: Nat) -> List<&2, BD.FS>:
  match left:
    case 0n: []
    case 1n+k:
      +ss = side_ss(ps, i)
      +surf = ss_s(ss)
      +pl = ss_plane(ss)
      BD.FS{0n, surf, ss_same(ss), [side_loop(s, i, n, quads, pl, surf, ps)], BD.Fn{nd, 0n, 2u64, fi, 0n}} <>
        sides_row(k, ps, n, s, Nat.add(i, 1n), quads, nd, Nat.add(fi, 1n))

def sides_all(left: Nat, +ps: List<&2, F.Pc>, +n: Nat, +s: Nat, +quads: Nat, +nd: U64, +fi: Nat) -> List<&2, BD.FS>:
  match left:
    case 0n: []
    case 1n+k:
      List.append(&2, BD.FS, sides_row(n, ps, n, s, 0n, quads, nd, fi), sides_all(k, ps, n, Nat.add(s, 1n), quads, nd, Nat.add(fi, n)))

def sec_fs(+ps: List<&2, F.Pc>, +n: Nat, +quads: Nat, +nd: U64) -> List<&2, BD.FS>:
  +s0 = cap_start()
  +s1 = cap_end(quads)
  +p0 = pts_start(ps, n)
  +p1 = pts_end(ps, n, quads)
  List.append(&2, BD.FS, sides_all(quads, ps, n, 0n, quads, nd, 0n),
    [BD.FS{0n, s0, cap_same(p0, s0), [cap0_loop(n, n, quads, s0, ps)], BD.Fn{nd, 0n, 0u64, 0n, 0n}},
      BD.FS{0n, s1, cap_same(p1, s1), [cap1_loop(n, n, quads, quads, s1, ps)], BD.Fn{nd, 0n, 1u64, 0n, 0n}}])

def sec_bt(+vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>, +fs: List<&2, BD.FS>) -> BD.Bt:
  +st = BD.fs_emit(fs, BD.St{0n, 0n, [], [], []}, 0n)
  +runs = BD.sol_runs(fs, 0n, 0n, [])
  +ns = List.length(&2, List<&2, Ty.HFace>, runs)
  BD.Bt{BD.st_br(st, vx_gen(vs, 0n), BD.ed_gen(es, 0n), BD.shs_of(runs, 0n), BD.sos_of(ns, 0n), Ty.Cp{BD.hsos_of(ns, 0n), []}),
    BD.fs_names(fs)}

def sec_build(ok: Bool, +ps: List<&2, F.Pc>, +n: Nat, +quads: Nat, +nd: U64) -> RR:
  match ok:
    case False{}: sec_bad(24u64)
    case True{}:
      +stations = Nat.add(quads, 1n)
      RR{0u64, 0n, sec_bt(sec_vs(ps, n, stations), sec_es(ps, n, quads), sec_fs(ps, n, quads, nd))}

def sec_go(ok: Bool, +ps: List<&2, F.Pc>, +n: Nat, +quads: Nat, +nd: U64) -> RR:
  match ok:
    case False{}: sec_bad(24u64)
    case True{}: sec_build(True{}, ps, n, quads, nd)

def sec_rr(+ls: List<&2, F.Lp>, +hs: List<&2, Bool>, +nd: U64, +quads: Nat) -> RR:
  +ok = Bool.and(sec_one(ls, hs), Bool.not(Nat.is_eq(quads, 0n)))
  +lp = sec_lp0(ls)
  +ps = F.lp_pcs(lp)
  +n = List.length(&2, F.Pc, ps)
  sec_go(Bool.and(ok, Bool.and(Bool.not(Nat.is_eq(n, 0n)), pcs_ssok(ps))), ps, n, quads, nd)
