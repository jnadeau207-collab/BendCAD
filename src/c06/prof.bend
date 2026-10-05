import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c02/types.bend as P
import ../c02/ops.bend as P2
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../c05/exact.bend as XE
import ../base/par.bend as B
import ../base/ex.bend as E
import ./xp.bend as X

type Seg is Data:
  S_line{ x: X.Xp, y: X.Xp }
  S_arc{ cx: X.Xp, cy: X.Xp, r: X.Xp, x: X.Xp, y: X.Xp, ccw: Bool }

type Loop is Data:
  L_path{ x: X.Xp, y: X.Xp, segs: List<&2, Seg> }
  L_circ{ cx: X.Xp, cy: X.Xp, r: X.Xp }

type Region is Data:
  Rg{ outer: Loop, holes: List<&2, Loop> }

type Pc is Data:
  P_ln{ ax: F64, ay: F64, bx: F64, by: F64 }
  P_ar{ ax: F64, ay: F64, px: F64, py: F64, w: F64, bx: F64, by: F64 }

type Sg is Data:
  G_ln{ p: Pc }
  G_ar{ cx: F64, cy: F64, r: F64, ccw: Bool, ps: List<&2, Pc> }

type Lp is Data:
  K_path{ sgs: List<&2, Sg> }
  K_circ{ cx: F64, cy: F64, r: F64 }

type Er is Data:
  Er{ code: U64, lp: Nat, sg: Nat }

type RS is Data:
  R_ln{ x: F64, y: F64 }
  R_ar{ cx: F64, cy: F64, r: F64, x: F64, y: F64, ccw: Bool }

type SR is Data:
  SR_ok{ sgs: List<&2, Sg> }
  SR_err{ e: Er }

type PR is Data:
  PR_ok{ ps: List<&2, Pc> }
  PR_err{ code: U64 }

type LR is Data:
  LR_ok{ l: Lp }
  LR_err{ e: Er }

type Shp is Data:
  Sh_seg{ ax: F64, ay: F64, bx: F64, by: F64 }
  Sh_tri{ ax: F64, ay: F64, px: F64, py: F64, bx: F64, by: F64 }
  Sh_cir{ cx: F64, cy: F64, r: F64 }

type It is Data:
  It{ lp: Nat, k: Nat, n: Nat, sh: Shp, x0: F64, x1: F64, y0: F64, y1: F64 }

type Pr is Data:
  Pr{ a: It, b: It }

type Bx is Data:
  Bx{ x0: F64, x1: F64, y0: F64, y1: F64 }

type CK is Data:
  CK_ok{ ls: List<&2, Lp>, par: List<&2, Nat> }
  CK_err{ e: Er }

type Rl is Data:
  K_free{}
  K_hole{ o: Nat }
  K_in{ c: Nat }
  K_root{}
  K_obst{ c: Nat }

type Cn is Data:
  Cn{ ch: Nat, pa: Nat, x0: F64 }

type EV is Data:
  EV_ok{ ls: List<&2, Lp> }
  EV_err{ e: Er }

def er(+c: U64, +l: Nat, +s: Nat) -> Er:
  Er{c, l, s}

def er_code(e: Er) -> U64:
  Er{code, lp, sg} = e
  code

def sgn_pos(s: B.Sgn) -> Bool:
  match s:
    case B.Sp{}: True{}
    case _: False{}

def sgn_neg(s: B.Sgn) -> Bool:
  match s:
    case B.Sn{}: True{}
    case _: False{}

def sgn_zero(s: B.Sgn) -> Bool:
  match s:
    case B.Sz{}: True{}
    case _: False{}

def ori(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64) -> B.Sgn:
  XE.orient2s(ax, ay, bx, by, cx, cy)

def dot_ex(+vx: F64, +vy: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> E.Ex:
  E.ex_add(E.ex_mul(E.ex_dif(ax, vx), E.ex_dif(bx, vx)),
    E.ex_mul(E.ex_dif(ay, vy), E.ex_dif(by, vy)))

def d2_ex(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> E.Ex:
  E.ex_add(E.ex_mul(E.ex_dif(ax, bx), E.ex_dif(ax, bx)),
    E.ex_mul(E.ex_dif(ay, by), E.ex_dif(ay, by)))

def sq_ex(+r: F64) -> E.Ex:
  E.ex_mul(E.ex_of(r), E.ex_of(r))

def on_circ(+cx: F64, +cy: F64, +r: F64, +x: F64, +y: F64) -> Bool:
  GO.q_on_r(G.GV_cy{G.Cy{V.Pt{cx, cy, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, r}},
    V.Pt{x, y, 0.0f64})

def fsg(+a: F64, +b: F64) -> B.Sgn:
  B.sgn_pick(F64.is_lt(a, b), F64.is_lt(b, a))

def seg_miss(s: Seg, +e: X.Env) -> U64:
  match s:
    case S_line{x, y}: X.miss_pick(X.xp_miss(x, e), X.xp_miss(y, e))
    case S_arc{cx, cy, r, x, y, ccw}:
      X.miss_pick(X.xp_miss(cx, e), X.miss_pick(X.xp_miss(cy, e),
        X.miss_pick(X.xp_miss(r, e), X.miss_pick(X.xp_miss(x, e), X.xp_miss(y, e)))))

def segs_miss(ss: List<&2, Seg>, +e: X.Env) -> U64:
  match ss:
    case []: 0u64
    case s <> t: X.miss_pick(seg_miss(s, e), segs_miss(t, e))

def loop_miss(l: Loop, +e: X.Env) -> U64:
  match l:
    case L_path{x, y, segs}:
      X.miss_pick(X.xp_miss(x, e), X.miss_pick(X.xp_miss(y, e), segs_miss(segs, e)))
    case L_circ{cx, cy, r}:
      X.miss_pick(X.xp_miss(cx, e), X.miss_pick(X.xp_miss(cy, e), X.xp_miss(r, e)))

def rs_ev(s: Seg, +e: X.Env) -> RS:
  match s:
    case S_line{x, y}: R_ln{X.xp_ev(x, e), X.xp_ev(y, e)}
    case S_arc{cx, cy, r, x, y, ccw}:
      R_ar{X.xp_ev(cx, e), X.xp_ev(cy, e), X.xp_ev(r, e), X.xp_ev(x, e), X.xp_ev(y, e), ccw}

def rs_fin(+r: RS) -> Bool:
  match r:
    case R_ln{x, y}: Bool.and(T.is_finite(x), T.is_finite(y))
    case R_ar{cx, cy, r, x, y, ccw}:
      Bool.and(T.is_finite(cx), Bool.and(T.is_finite(cy),
        Bool.and(T.is_finite(r), Bool.and(T.is_finite(x), T.is_finite(y)))))

def rs_x(+r: RS) -> F64:
  match r:
    case R_ln{x, y}: x
    case R_ar{cx, cy, r, x, y, ccw}: x

def rs_y(+r: RS) -> F64:
  match r:
    case R_ln{x, y}: y
    case R_ar{cx, cy, r, x, y, ccw}: y

def pc_rev(p: Pc) -> Pc:
  match p:
    case P_ln{ax, ay, bx, by}: P_ln{bx, by, ax, ay}
    case P_ar{ax, ay, px, py, w, bx, by}: P_ar{bx, by, px, py, w, ax, ay}

def pcs_rev(ps: List<&2, Pc>, +acc: List<&2, Pc>) -> List<&2, Pc>:
  match ps:
    case []: acc
    case p <> t: pcs_rev(t, pc_rev(p) <> acc)

def ax_x(+cx: F64, +r: F64, +j: U64) -> F64:
  match j:
    case 0u64: F64.add(cx, r)
    case 2u64: F64.sub(cx, r)
    case _: cx

def ax_y(+cy: F64, +r: F64, +j: U64) -> F64:
  match j:
    case 1u64: F64.add(cy, r)
    case 3u64: F64.sub(cy, r)
    case _: cy

def first_ax(+ux: B.Sgn, +uy: B.Sgn) -> U64:
  +xp = sgn_pos(ux)
  +xn = sgn_neg(ux)
  +yp = sgn_pos(uy)
  +yn = sgn_neg(uy)
  Bool.pick(U64, Bool.and(xp, Bool.not(yn)), 1u64,
    Bool.pick(U64, Bool.and(Bool.not(xp), yp), 2u64,
      Bool.pick(U64, Bool.and(xn, Bool.not(yp)), 3u64, 0u64)))

def ax_cross_u(+j: U64, +ux: B.Sgn, +uy: B.Sgn) -> B.Sgn:
  match j:
    case 0u64: B.sgn_neg(uy)
    case 1u64: ux
    case 2u64: uy
    case _: B.sgn_neg(ux)

def ax_dot_u(+j: U64, +ux: B.Sgn, +uy: B.Sgn) -> B.Sgn:
  match j:
    case 0u64: ux
    case 1u64: uy
    case 2u64: B.sgn_neg(ux)
    case _: B.sgn_neg(uy)

def ax_cross_w(+j: U64, +wx: B.Sgn, +wy: B.Sgn) -> B.Sgn:
  match j:
    case 0u64: wy
    case 1u64: B.sgn_neg(wx)
    case 2u64: B.sgn_neg(wy)
    case _: wx

def half_of(+cr: B.Sgn, +dt: B.Sgn) -> U64:
  Bool.pick(U64, Bool.or(sgn_pos(cr), Bool.and(sgn_zero(cr), sgn_pos(dt))), 0u64, 1u64)

def ax_before(+j: U64, +ux: B.Sgn, +uy: B.Sgn, +wx: B.Sgn, +wy: B.Sgn, +hw: U64) -> Bool:
  +hd = half_of(ax_cross_u(j, ux, uy), ax_dot_u(j, ux, uy))
  +at0 = Bool.and(sgn_zero(ax_cross_u(j, ux, uy)), sgn_pos(ax_dot_u(j, ux, uy)))
  Bool.and(Bool.not(at0),
    Bool.pick(Bool, U64.is_eq(hd, hw), sgn_pos(ax_cross_w(j, wx, wy)), U64.is_lt(hd, hw)))

def splits_go(n: Nat, +j: U64, +ux: B.Sgn, +uy: B.Sgn, +wx: B.Sgn, +wy: B.Sgn, +hw: U64) -> List<&2, U64>:
  match n:
    case 0n: []
    case 1n+m:
      +rest = splits_go(m, U64.and((j + 1u64 : U64), 3u64), ux, uy, wx, wy, hw)
      Bool.pick(List<&2, U64>, ax_before(j, ux, uy, wx, wy, hw), j <> rest, [])

def p1_of(+cx: F64, +cy: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> V.Vec2:
  +ux = F64.sub(ax, cx)
  +uy = F64.sub(ay, cy)
  +vx = F64.sub(bx, cx)
  +vy = F64.sub(by, cy)
  +det = F64.sub(F64.mul(ux, vy), F64.mul(uy, vx))
  +uu = F64.add(F64.mul(ux, ux), F64.mul(uy, uy))
  +vv = F64.add(F64.mul(vx, vx), F64.mul(vy, vy))
  +px = F64.add(cx, F64.div(F64.sub(F64.mul(uu, vy), F64.mul(vv, uy)), det))
  +py = F64.add(cy, F64.div(F64.sub(F64.mul(ux, vv), F64.mul(vx, uu)), det))
  +ok = Bool.and(F64.is_lt(0.0f64, det), Bool.and(T.is_finite(px), T.is_finite(py)))
  Bool.pick(V.Vec2, ok, V.V2{px, py},
    V.V2{F64.mul(0.5f64, F64.add(ax, bx)), F64.mul(0.5f64, F64.add(ay, by))})

def w_of(+cx: F64, +cy: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> F64:
  +ux = F64.sub(ax, cx)
  +uy = F64.sub(ay, cy)
  +vx = F64.sub(bx, cx)
  +vy = F64.sub(by, cy)
  +uu = F64.add(F64.mul(ux, ux), F64.mul(uy, uy))
  +vv = F64.add(F64.mul(vx, vx), F64.mul(vy, vy))
  +c = F64.div(F64.add(F64.mul(ux, vx), F64.mul(uy, vy)), F64.sqrt(F64.mul(uu, vv)))
  +w = F64.sqrt(F64.mul(0.5f64, F64.add(1.0f64, c)))
  Bool.pick(F64, Bool.and(T.is_finite(w), F64.is_lt(0.0f64, w)), F64.min(w, 1.0f64), 1.0f64)

def mk_ar(+cx: F64, +cy: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> Pc:
  +p1 = p1_of(cx, cy, ax, ay, bx, by)
  P_ar{ax, ay, V.v2_x(p1), V.v2_y(p1), w_of(cx, cy, ax, ay, bx, by), bx, by}

def pr_cons(ok: Bool, p: Pc, rest: PR) -> PR:
  match ok:
    case False{}: PR_err{16u64}
    case True{}:
      match rest:
        case PR_ok{ps}: PR_ok{p <> ps}
        case PR_err{c}: PR_err{c}

def arc_pcs(js: List<&2, U64>, +cx: F64, +cy: F64, +r: F64, +ax: F64, +ay: F64,
    +bx: F64, +by: F64) -> PR:
  match js:
    case []: PR_ok{[mk_ar(cx, cy, ax, ay, bx, by)]}
    case +j <> t:
      +mx = ax_x(cx, r, j)
      +my = ax_y(cy, r, j)
      pr_cons(on_circ(cx, cy, r, mx, my), mk_ar(cx, cy, ax, ay, mx, my),
        arc_pcs(t, cx, cy, r, mx, my, bx, by))

def pr_same(same: Bool, js: List<&2, U64>, +cx: F64, +cy: F64, +r: F64, +ax: F64, +ay: F64,
    +bx: F64, +by: F64) -> PR:
  match same:
    case True{}: PR_err{6u64}
    case False{}: arc_pcs(js, cx, cy, r, ax, ay, bx, by)

def arc_ccw(+cx: F64, +cy: F64, +r: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> PR:
  +ux = fsg(ax, cx)
  +uy = fsg(ay, cy)
  +wx = fsg(bx, cx)
  +wy = fsg(by, cy)
  +cr = ori(cx, cy, ax, ay, bx, by)
  +dt = E.ex_sign(dot_ex(cx, cy, ax, ay, bx, by))
  +same = Bool.and(sgn_zero(cr), sgn_pos(dt))
  +hw = half_of(cr, dt)
  pr_same(same, splits_go(4n, first_ax(ux, uy), ux, uy, wx, wy, hw), cx, cy, r, ax, ay, bx, by)

def pr_rev(r: PR) -> PR:
  match r:
    case PR_ok{ps}: PR_ok{pcs_rev(ps, [])}
    case PR_err{c}: PR_err{c}

def arc_dir(ccw: Bool, +cx: F64, +cy: F64, +r: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> PR:
  match ccw:
    case True{}: arc_ccw(cx, cy, r, ax, ay, bx, by)
    case False{}: pr_rev(arc_ccw(cx, cy, r, bx, by, ax, ay))

def pr_gate(+c: U64, ccw: Bool, +cx: F64, +cy: F64, +r: F64, +ax: F64, +ay: F64, +bx: F64,
    +by: F64) -> PR:
  match c:
    case 0u64: arc_dir(ccw, cx, cy, r, ax, ay, bx, by)
    case _: PR_err{c}

def arc_gate(+cx: F64, +cy: F64, +r: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64, ccw: Bool) -> PR:
  +rpos = F64.is_lt(0.0f64, r)
  +same = Bool.and(F64.is_eq(ax, bx), F64.is_eq(ay, by))
  +c = Bool.pick(U64, Bool.not(rpos), 3u64,
    Bool.pick(U64, same, 2u64,
      Bool.pick(U64, Bool.not(on_circ(cx, cy, r, ax, ay)), 4u64,
        Bool.pick(U64, Bool.not(on_circ(cx, cy, r, bx, by)), 5u64, 0u64))))
  pr_gate(c, ccw, cx, cy, r, ax, ay, bx, by)

def sg_arc(r: PR, +cx: F64, +cy: F64, +rad: F64, ccw: Bool, +li: Nat, +si: Nat) -> SR:
  match r:
    case PR_ok{ps}: SR_ok{[G_ar{cx, cy, rad, ccw, ps}]}
    case PR_err{c}: SR_err{er(c, li, si)}

def sg_line(+ax: F64, +ay: F64, +bx: F64, +by: F64, +li: Nat, +si: Nat) -> SR:
  Bool.pick(SR, Bool.and(F64.is_eq(ax, bx), F64.is_eq(ay, by)), SR_err{er(2u64, li, si)},
    SR_ok{[G_ln{P_ln{ax, ay, bx, by}}]})

def sg_of(r: RS, +ax: F64, +ay: F64, +li: Nat, +si: Nat) -> SR:
  match r:
    case R_ln{x, y}: sg_line(ax, ay, x, y, li, si)
    case R_ar{+cx, +cy, +rad, x, y, +ccw}:
      sg_arc(arc_gate(cx, cy, rad, ax, ay, x, y, ccw), cx, cy, rad, ccw, li, si)

def sr_cat(a: SR, b: SR) -> SR:
  match a:
    case SR_err{e}: SR_err{e}
    case SR_ok{xs}:
      match b:
        case SR_err{e}: SR_err{e}
        case SR_ok{ys}: SR_ok{List.append(&2, Sg, xs, ys)}

def chain(rs: List<&2, RS>, +ax: F64, +ay: F64, +sx: F64, +sy: F64, +li: Nat, +si: Nat) -> SR:
  match rs:
    case []:
      Bool.pick(SR, Bool.and(F64.is_eq(ax, sx), F64.is_eq(ay, sy)), SR_ok{[]},
        SR_ok{[G_ln{P_ln{ax, ay, sx, sy}}]})
    case +r <> t:
      sr_cat(sg_of(r, ax, ay, li, si), chain(t, rs_x(r), rs_y(r), sx, sy, li, Nat.add(si, 1n)))

def rs_all_fin(rs: List<&2, RS>, +i: Nat) -> Nat:
  match rs:
    case []: 0n
    case r <> t: Bool.pick(Nat, rs_fin(r), rs_all_fin(t, Nat.add(i, 1n)), Nat.add(i, 1n))

def rs_list(ss: List<&2, Seg>, +e: X.Env) -> List<&2, RS>:
  match ss:
    case []: []
    case s <> t: rs_ev(s, e) <> rs_list(t, e)

def sg_npc(s: Sg) -> Nat:
  match s:
    case G_ln{p}: 1n
    case G_ar{cx, cy, r, ccw, ps}: List.length(&2, Pc, ps)

def sgs_npc(ss: List<&2, Sg>) -> Nat:
  match ss:
    case []: 0n
    case s <> t: Nat.add(sg_npc(s), sgs_npc(t))

def lr_count(+sgs: List<&2, Sg>, +li: Nat) -> LR:
  Bool.pick(LR, Nat.is_le(2n, sgs_npc(sgs)), LR_ok{K_path{sgs}}, LR_err{er(7u64, li, 0n)})

def lr_of_sr(r: SR, +li: Nat) -> LR:
  match r:
    case SR_err{e}: LR_err{e}
    case SR_ok{sgs}: lr_count(sgs, li)

def path_go(+fin: Nat, rs: List<&2, RS>, +sx: F64, +sy: F64, +li: Nat) -> LR:
  match fin:
    case 0n: lr_of_sr(chain(rs, sx, sy, sx, sy, li, 0n), li)
    case 1n+k: LR_err{er(1u64, li, k)}

def circ_go(+cx: F64, +cy: F64, +r: F64, +li: Nat) -> LR:
  +fin = Bool.and(T.is_finite(cx), Bool.and(T.is_finite(cy), T.is_finite(r)))
  Bool.pick(LR, Bool.not(fin), LR_err{er(1u64, li, 0n)},
    Bool.pick(LR, F64.is_lt(0.0f64, r), LR_ok{K_circ{cx, cy, r}}, LR_err{er(3u64, li, 0n)}))

def loop_go(l: Loop, +e: X.Env, +li: Nat) -> LR:
  match l:
    case L_path{x, y, segs}:
      +sx = X.xp_ev(x, e)
      +sy = X.xp_ev(y, e)
      +rs = rs_list(segs, e)
      +fin0 = Bool.and(T.is_finite(sx), T.is_finite(sy))
      path_go(Bool.pick(Nat, fin0, rs_all_fin(rs, 0n), 1n), rs, sx, sy, li)
    case L_circ{cx, cy, r}: circ_go(X.xp_ev(cx, e), X.xp_ev(cy, e), X.xp_ev(r, e), li)

def loop_ev_go(ok: Bool, +l: Loop, +e: X.Env, +li: Nat, +m: U64) -> LR:
  match ok:
    case True{}: loop_go(l, e, li)
    case False{}: LR_err{er(17u64, li, U64.to_nat((m - 1u64 : U64)))}

def loop_ev(+l: Loop, +e: X.Env, +li: Nat) -> LR:
  +m = loop_miss(l, e)
  loop_ev_go(U64.is_eq(m, 0u64), l, e, li, m)

def sg_pcs(s: Sg) -> List<&2, Pc>:
  match s:
    case G_ln{p}: [p]
    case G_ar{cx, cy, r, ccw, ps}: ps

def sgs_pcs(ss: List<&2, Sg>) -> List<&2, Pc>:
  match ss:
    case []: []
    case s <> t: List.append(&2, Pc, sg_pcs(s), sgs_pcs(t))

def lp_pcs(l: Lp) -> List<&2, Pc>:
  match l:
    case K_path{sgs}: sgs_pcs(sgs)
    case K_circ{cx, cy, r}: []

def pc_ax(p: Pc) -> F64:
  match p:
    case P_ln{ax, ay, bx, by}: ax
    case P_ar{ax, ay, px, py, w, bx, by}: ax

def pc_ay(p: Pc) -> F64:
  match p:
    case P_ln{ax, ay, bx, by}: ay
    case P_ar{ax, ay, px, py, w, bx, by}: ay

def pc_bx(p: Pc) -> F64:
  match p:
    case P_ln{ax, ay, bx, by}: bx
    case P_ar{ax, ay, px, py, w, bx, by}: bx

def pc_by(p: Pc) -> F64:
  match p:
    case P_ln{ax, ay, bx, by}: by
    case P_ar{ax, ay, px, py, w, bx, by}: by

def sg_rev(s: Sg) -> Sg:
  match s:
    case G_ln{p}: G_ln{pc_rev(p)}
    case G_ar{cx, cy, r, ccw, ps}: G_ar{cx, cy, r, Bool.not(ccw), pcs_rev(ps, [])}

def sgs_rev(ss: List<&2, Sg>, +acc: List<&2, Sg>) -> List<&2, Sg>:
  match ss:
    case []: acc
    case s <> t: sgs_rev(t, sg_rev(s) <> acc)

def lp_rev(l: Lp) -> Lp:
  match l:
    case K_path{sgs}: K_path{sgs_rev(sgs, [])}
    case K_circ{cx, cy, r}: K_circ{cx, cy, r}

def lo_up(+x: F64) -> F64:
  E.f64_next_up(x)

def lo_dn(+x: F64) -> F64:
  E.f64_next_down(x)

def mn3(+a: F64, +b: F64, +c: F64) -> F64:
  F64.min(a, F64.min(b, c))

def mx3(+a: F64, +b: F64, +c: F64) -> F64:
  F64.max(a, F64.max(b, c))

def it_of(+l: Nat, +k: Nat, +n: Nat, p: Pc) -> It:
  match p:
    case P_ln{+ax, +ay, +bx, +by}:
      It{l, k, n, Sh_seg{ax, ay, bx, by}, F64.min(ax, bx), F64.max(ax, bx), F64.min(ay, by),
        F64.max(ay, by)}
    case P_ar{+ax, +ay, +px, +py, w, +bx, +by}:
      It{l, k, n, Sh_tri{ax, ay, px, py, bx, by}, mn3(ax, px, bx), mx3(ax, px, bx),
        mn3(ay, py, by), mx3(ay, py, by)}

def its_go(ps: List<&2, Pc>, +l: Nat, +k: Nat, +n: Nat) -> List<&2, It>:
  match ps:
    case []: []
    case p <> t: it_of(l, k, n, p) <> its_go(t, l, Nat.add(k, 1n), n)

def lp_its(l: Lp, +li: Nat) -> List<&2, It>:
  match l:
    case K_path{+sgs}:
      +ps = sgs_pcs(sgs)
      its_go(ps, li, 0n, List.length(&2, Pc, ps))
    case K_circ{+cx, +cy, +r}:
      [It{li, 0n, 1n, Sh_cir{cx, cy, r}, lo_dn(F64.sub(cx, r)), lo_up(F64.add(cx, r)),
        lo_dn(F64.sub(cy, r)), lo_up(F64.add(cy, r))}]

def it_x0(i: It) -> F64:
  It{lp, k, n, sh, x0, x1, y0, y1} = i
  x0

def it_x1(i: It) -> F64:
  It{lp, k, n, sh, x0, x1, y0, y1} = i
  x1

def it_y0(i: It) -> F64:
  It{lp, k, n, sh, x0, x1, y0, y1} = i
  y0

def it_y1(i: It) -> F64:
  It{lp, k, n, sh, x0, x1, y0, y1} = i
  y1

def it_lp(i: It) -> Nat:
  It{lp, k, n, sh, x0, x1, y0, y1} = i
  lp

def it_k(i: It) -> Nat:
  It{lp, k, n, sh, x0, x1, y0, y1} = i
  k

def it_n(i: It) -> Nat:
  It{lp, k, n, sh, x0, x1, y0, y1} = i
  n

def it_sh(i: It) -> Shp:
  It{lp, k, n, sh, x0, x1, y0, y1} = i
  sh

def it_cmp_go(+a: It, +b: It) -> B.Sgn:
  fsg(it_x0(a), it_x0(b))

def it_cmp(a: It, b: It) -> B.Sgn:
  it_cmp_go(a, b)

def so_it(s: B.So<&2, It>) -> List<&2, It>:
  B.So{ok, xs} = s
  xs

def y_ov(+a: It, +b: It) -> Bool:
  Bool.and(F64.is_le(it_y0(a), it_y1(b)), F64.is_le(it_y0(b), it_y1(a)))

def adj(+a: It, +b: It) -> Bool:
  +same = Nat.is_eq(it_lp(a), it_lp(b))
  +n = it_n(a)
  +ka = it_k(a)
  +kb = it_k(b)
  +d1 = Bool.or(Nat.is_eq(Nat.add(ka, 1n), kb), Nat.is_eq(Nat.add(kb, 1n), ka))
  +wrap = Bool.or(Bool.and(Nat.is_eq(ka, 0n), Nat.is_eq(Nat.add(kb, 1n), n)),
    Bool.and(Nat.is_eq(kb, 0n), Nat.is_eq(Nat.add(ka, 1n), n)))
  Bool.and(same, Bool.or(Nat.is_eq(ka, kb), Bool.or(d1, wrap)))

def pk(c: Bool, +p: Pr, +rest: List<&2, Pr>) -> List<&2, Pr>:
  match c:
    case True{}: p <> rest
    case False{}: rest

def peek_le(xs: List<&2, It>, +x1: F64) -> Bool:
  match xs:
    case []: False{}
    case h <> t: F64.is_le(it_x0(h), x1)

def sw_scan(xs: List<&2, It>, +h: It, go: Bool) -> List<&2, Pr>:
  match xs go:
    case _ False{}: []
    case Nil{} True{}: []
    case Con{+y, +t} True{}:
      pk(Bool.and(y_ov(h, y), Bool.not(adj(h, y))), Pr{h, y}, sw_scan(t, h, peek_le(t, it_x1(h))))

def sw_go(xs: List<&2, It>) -> List<&2, Pr>:
  match xs:
    case []: []
    case +h <> +t: List.append(&2, Pr, sw_scan(t, h, peek_le(t, it_x1(h))), sw_go(t))

def sweep(+its: List<&2, It>) -> List<&2, Pr>:
  sw_go(so_it(B.msort(~It, ~it_cmp, its)))

def seg_cut(+ax: F64, +ay: F64, +bx: F64, +by: F64, +qx: F64, +qy: F64, +rx: F64,
    +ry: F64, +sx: F64, +sy: F64) -> Bool:
  +s1 = ori(ax, ay, bx, by, qx, qy)
  +s2 = ori(ax, ay, bx, by, rx, ry)
  +s3 = ori(ax, ay, bx, by, sx, sy)
  Bool.or(Bool.and(sgn_pos(s1), Bool.and(sgn_pos(s2), sgn_pos(s3))),
    Bool.and(sgn_neg(s1), Bool.and(sgn_neg(s2), sgn_neg(s3))))

def pts_opp(pts: List<&2, V.Vec2>, +ax: F64, +ay: F64, +bx: F64, +by: F64, +sc: B.Sgn) -> Bool:
  match pts:
    case []: True{}
    case p <> t:
      V.V2{+x, +y} = p
      +s = ori(ax, ay, bx, by, x, y)
      Bool.and(Bool.or(Bool.and(sgn_pos(sc), sgn_neg(s)), Bool.and(sgn_neg(sc), sgn_pos(s))),
        pts_opp(t, ax, ay, bx, by, sc))

def tri_edge_out(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64,
    pts: List<&2, V.Vec2>) -> Bool:
  +sc = ori(ax, ay, bx, by, cx, cy)
  Bool.and(Bool.not(sgn_zero(sc)), pts_opp(pts, ax, ay, bx, by, sc))

def pts_side(pts: List<&2, V.Vec2>, +ax: F64, +ay: F64, +bx: F64, +by: F64, +want: B.Sgn) -> Bool:
  match pts:
    case []: True{}
    case p <> t:
      V.V2{+x, +y} = p
      Bool.and(B.sgn_is(ori(ax, ay, bx, by, x, y), want), pts_side(t, ax, ay, bx, by, want))

def seg_sep(+ax: F64, +ay: F64, +bx: F64, +by: F64, +pts: List<&2, V.Vec2>) -> Bool:
  Bool.or(pts_side(pts, ax, ay, bx, by, B.Sp{}), pts_side(pts, ax, ay, bx, by, B.Sn{}))

def tri_sep(+ax: F64, +ay: F64, +px: F64, +py: F64, +bx: F64, +by: F64,
    +pts: List<&2, V.Vec2>) -> Bool:
  Bool.or(tri_edge_out(ax, ay, px, py, bx, by, pts),
    Bool.or(tri_edge_out(px, py, bx, by, ax, ay, pts), tri_edge_out(bx, by, ax, ay, px, py, pts)))

def sh_pts(s: Shp) -> List<&2, V.Vec2>:
  match s:
    case Sh_seg{ax, ay, bx, by}: [V.V2{ax, ay}, V.V2{bx, by}]
    case Sh_tri{ax, ay, px, py, bx, by}: [V.V2{ax, ay}, V.V2{px, py}, V.V2{bx, by}]
    case Sh_cir{cx, cy, r}: []

def sh_sep1(s: Shp, +pts: List<&2, V.Vec2>) -> Bool:
  match s:
    case Sh_seg{ax, ay, bx, by}: seg_sep(ax, ay, bx, by, pts)
    case Sh_tri{ax, ay, px, py, bx, by}: tri_sep(ax, ay, px, py, bx, by, pts)
    case Sh_cir{cx, cy, r}: False{}

def cvx_sep(+a: Shp, +b: Shp) -> Bool:
  Bool.or(sh_sep1(a, sh_pts(b)), sh_sep1(b, sh_pts(a)))

def seg_dist_gt(+cx: F64, +cy: F64, +r: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> Bool:
  +t = dot_ex(ax, ay, bx, by, cx, cy)
  +l = d2_ex(ax, ay, bx, by)
  +rr = sq_ex(r)
  +st = E.ex_sign(t)
  +sl = E.ex_sign(E.ex_sub(t, l))
  +cr = XE.orient2(ax, ay, bx, by, cx, cy)
  Bool.pick(Bool, Bool.not(sgn_pos(st)), sgn_pos(E.ex_cmp(d2_ex(cx, cy, ax, ay), rr)),
    Bool.pick(Bool, Bool.not(sgn_neg(sl)), sgn_pos(E.ex_cmp(d2_ex(cx, cy, bx, by), rr)),
      sgn_pos(E.ex_cmp(E.ex_mul(cr, cr), E.ex_mul(rr, l)))))

def in_disc(+cx: F64, +cy: F64, +r: F64, pts: List<&2, V.Vec2>) -> Bool:
  match pts:
    case []: True{}
    case p <> t:
      V.V2{+x, +y} = p
      Bool.and(sgn_neg(E.ex_cmp(d2_ex(cx, cy, x, y), sq_ex(r))), in_disc(cx, cy, r, t))

def tri_has(+ax: F64, +ay: F64, +px: F64, +py: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64) -> Bool:
  +o = ori(ax, ay, px, py, bx, by)
  +s1 = ori(ax, ay, px, py, cx, cy)
  +s2 = ori(px, py, bx, by, cx, cy)
  +s3 = ori(bx, by, ax, ay, cx, cy)
  +bad = Bool.or(Bool.and(sgn_pos(o), Bool.or(sgn_neg(s1), Bool.or(sgn_neg(s2), sgn_neg(s3)))),
    Bool.and(sgn_neg(o), Bool.or(sgn_pos(s1), Bool.or(sgn_pos(s2), sgn_pos(s3)))))
  Bool.not(bad)

def cir_out(+cx: F64, +cy: F64, +r: F64, s: Shp) -> Bool:
  match s:
    case Sh_seg{ax, ay, bx, by}: seg_dist_gt(cx, cy, r, ax, ay, bx, by)
    case Sh_tri{+ax, +ay, +px, +py, +bx, +by}:
      Bool.and(Bool.not(tri_has(ax, ay, px, py, bx, by, cx, cy)),
        Bool.and(seg_dist_gt(cx, cy, r, ax, ay, px, py),
          Bool.and(seg_dist_gt(cx, cy, r, px, py, bx, by), seg_dist_gt(cx, cy, r, bx, by, ax, ay))))
    case Sh_cir{qx, qy, q}: False{}

def cir_poly(+cx: F64, +cy: F64, +r: F64, +s: Shp) -> Bool:
  Bool.or(in_disc(cx, cy, r, sh_pts(s)), cir_out(cx, cy, r, s))

def cir_cir(+ax: F64, +ay: F64, +ra: F64, +bx: F64, +by: F64, +rb: F64) -> Bool:
  +d = d2_ex(ax, ay, bx, by)
  +sum = E.ex_add(E.ex_of(ra), E.ex_of(rb))
  +dif = E.ex_dif(ra, rb)
  Bool.or(sgn_pos(E.ex_cmp(d, E.ex_mul(sum, sum))), sgn_neg(E.ex_cmp(d, E.ex_mul(dif, dif))))

def pr_x(r: P.Xres) -> U64:
  match r:
    case P.Xok{x}:
      match x:
        case P.X_disjoint{}: 0u64
        case _: 9u64
    case P.Xerr{k}: 15u64

def seg_seg_ok(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64, +dx: F64,
    +dy: F64) -> U64:
  pr_x(P2.seg_seg(V.V2{ax, ay}, V.V2{bx, by}, V.V2{cx, cy}, V.V2{dx, dy}))

def code_of(c: Bool, +bad: U64) -> U64:
  Bool.pick(U64, c, 0u64, bad)

def sh_tag(s: Shp) -> U64:
  match s:
    case Sh_seg{ax, ay, bx, by}: 0u64
    case Sh_tri{ax, ay, px, py, bx, by}: 1u64
    case Sh_cir{cx, cy, r}: 2u64

def ss_code(a: Shp, b: Shp) -> U64:
  match a b:
    case Sh_seg{ax, ay, bx, by} Sh_seg{cx, cy, dx, dy}: seg_seg_ok(ax, ay, bx, by, cx, cy, dx, dy)
    case _ _: 15u64

def cp_code(a: Shp, +b: Shp, +bad: U64) -> U64:
  match a:
    case Sh_cir{cx, cy, r}: code_of(cir_poly(cx, cy, r, b), bad)
    case _: 15u64

def cc_code(a: Shp, b: Shp) -> U64:
  match a b:
    case Sh_cir{ax, ay, ra} Sh_cir{bx, by, rb}: code_of(cir_cir(ax, ay, ra, bx, by, rb), 9u64)
    case _ _: 15u64

def pair_tag(+t: U64, +a: Shp, +b: Shp) -> U64:
  match t:
    case 0u64: ss_code(a, b)
    case 8u64: cc_code(a, b)
    case 2u64: cp_code(b, a, 9u64)
    case 5u64: cp_code(b, a, 15u64)
    case 6u64: cp_code(a, b, 9u64)
    case 7u64: cp_code(a, b, 15u64)
    case _: code_of(cvx_sep(a, b), 15u64)

def pair_code(+a: Shp, +b: Shp) -> U64:
  pair_tag((U64.mul(sh_tag(a), 3u64) + sh_tag(b) : U64), a, b)

def pr_code(c: Unit, p: Pr) -> Er:
  Pr{+a, +b} = p
  er(pair_code(it_sh(a), it_sh(b)), it_lp(a), it_k(a))

def first_er(es: List<&2, Er>) -> Er:
  match es:
    case []: er(0u64, 0n, 0n)
    case +e <> t: Bool.pick(Er, U64.is_eq(er_code(e), 0u64), first_er(t), e)

def pairs_er(+prs: List<&2, Pr>) -> Er:
  first_er(B.pmap(~Pr, ~Unit, ~Er, ~pr_code, Unit{}, prs))

def ray1(+vx: F64, +vy: F64, +dx: F64, +dy: F64, +e1x: F64, +e1y: F64) -> Bool:
  Bool.and(sgn_zero(ori(vx, vy, e1x, e1y, dx, dy)),
    sgn_pos(E.ex_sign(dot_ex(vx, vy, e1x, e1y, dx, dy))))

def ray2(+vx: F64, +vy: F64, +dx: F64, +dy: F64, +e1x: F64, +e1y: F64, +e2x: F64, +e2y: F64) -> Bool:
  +s = ori(vx, vy, e1x, e1y, e2x, e2y)
  +o1 = ori(vx, vy, e1x, e1y, dx, dy)
  +o2 = ori(vx, vy, dx, dy, e2x, e2y)
  Bool.or(sgn_zero(s), Bool.and(Bool.or(sgn_zero(o1), B.sgn_is(o1, s)),
    Bool.or(sgn_zero(o2), B.sgn_is(o2, s))))

def ray_rest(t: List<&2, V.Vec2>, +vx: F64, +vy: F64, +dx: F64, +dy: F64, +e1x: F64, +e1y: F64) -> Bool:
  match t:
    case []: ray1(vx, vy, dx, dy, e1x, e1y)
    case +e2 <> u: ray2(vx, vy, dx, dy, e1x, e1y, V.v2_x(e2), V.v2_y(e2))

def ray_in(+vx: F64, +vy: F64, +dx: F64, +dy: F64, cone: List<&2, V.Vec2>) -> Bool:
  match cone:
    case []: False{}
    case +e1 <> t: ray_rest(t, vx, vy, dx, dy, V.v2_x(e1), V.v2_y(e1))

def rays_in(+vx: F64, +vy: F64, ds: List<&2, V.Vec2>, +cone: List<&2, V.Vec2>) -> Bool:
  match ds:
    case []: False{}
    case d <> t:
      V.V2{+dx, +dy} = d
      Bool.or(ray_in(vx, vy, dx, dy, cone), rays_in(vx, vy, t, cone))

def cone_hit(+vx: F64, +vy: F64, +a: List<&2, V.Vec2>, +b: List<&2, V.Vec2>) -> Bool:
  Bool.or(rays_in(vx, vy, a, b), rays_in(vx, vy, b, a))

def cone_end(p: Pc) -> List<&2, V.Vec2>:
  match p:
    case P_ln{ax, ay, bx, by}: [V.V2{ax, ay}]
    case P_ar{ax, ay, px, py, w, bx, by}: [V.V2{px, py}, V.V2{ax, ay}]

def cone_start(p: Pc) -> List<&2, V.Vec2>:
  match p:
    case P_ln{ax, ay, bx, by}: [V.V2{bx, by}]
    case P_ar{ax, ay, px, py, w, bx, by}: [V.V2{px, py}, V.V2{bx, by}]

def adj_ok(+x: Pc, +y: Pc) -> Bool:
  Bool.not(cone_hit(pc_bx(x), pc_by(x), cone_end(x), cone_start(y)))

def side_of(p: Pc, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> B.Sgn:
  match p:
    case P_ln{qx, qy, rx, ry}: B.Sz{}
    case P_ar{qx, qy, px, py, w, rx, ry}: ori(ax, ay, bx, by, px, py)

def two_ok(+x: Pc, +y: Pc) -> Bool:
  +ax = pc_ax(x)
  +ay = pc_ay(x)
  +bx = pc_bx(x)
  +by = pc_by(x)
  +sx = side_of(x, ax, ay, bx, by)
  +sy = side_of(y, ax, ay, bx, by)
  Bool.or(Bool.and(sgn_zero(sx), Bool.not(sgn_zero(sy))),
    Bool.or(Bool.and(sgn_zero(sy), Bool.not(sgn_zero(sx))),
      Bool.or(Bool.and(sgn_pos(sx), sgn_neg(sy)), Bool.and(sgn_neg(sx), sgn_pos(sy)))))

def adj_go(ps: List<&2, Pc>, +first: Pc, +li: Nat, +k: Nat) -> Er:
  match ps:
    case []: er(0u64, li, k)
    case +x <> t:
      match t:
        case []: Bool.pick(Er, adj_ok(x, first), er(0u64, li, k), er(10u64, li, k))
        case +y <> u:
          Bool.pick(Er, adj_ok(x, y), adj_go(y <> u, first, li, Nat.add(k, 1n)), er(10u64, li, k))

def pc_hd(ps: List<&2, Pc>) -> Pc:
  match ps:
    case []: P_ln{0.0f64, 0.0f64, 0.0f64, 0.0f64}
    case p <> t: p

def pc_tl(ps: List<&2, Pc>) -> List<&2, Pc>:
  match ps:
    case []: []
    case p <> t: t

def adj_er(+ps: List<&2, Pc>, +li: Nat) -> Er:
  Bool.pick(Er, Nat.is_eq(List.length(&2, Pc, ps), 2n),
    Bool.pick(Er, two_ok(pc_hd(ps), pc_hd(pc_tl(ps))), er(0u64, li, 0n), er(15u64, li, 0n)),
    adj_go(ps, pc_hd(ps), li, 0n))

def v_cmp_go(+a: V.Vec2, +b: V.Vec2) -> B.Sgn:
  V.V2{+ax, +ay} = a
  V.V2{+bx, +by} = b
  +sx = fsg(ax, bx)
  Bool.pick(B.Sgn, sgn_zero(sx), fsg(ay, by), sx)

def v_cmp(a: V.Vec2, b: V.Vec2) -> B.Sgn:
  v_cmp_go(a, b)

def so_v(s: B.So<&2, V.Vec2>) -> List<&2, V.Vec2>:
  B.So{ok, xs} = s
  xs

def v_dup(xs: List<&2, V.Vec2>, +prev: V.Vec2, first: Bool) -> Bool:
  match xs:
    case []: False{}
    case +h <> t: Bool.or(Bool.and(Bool.not(first), sgn_zero(v_cmp_go(h, prev))), v_dup(t, h, False{}))

def pcs_starts(ps: List<&2, Pc>) -> List<&2, V.Vec2>:
  match ps:
    case []: []
    case +p <> t: V.V2{pc_ax(p), pc_ay(p)} <> pcs_starts(t)

def dup_er(+ps: List<&2, Pc>, +li: Nat) -> Er:
  Bool.pick(Er, v_dup(so_v(B.msort(~V.Vec2, ~v_cmp, pcs_starts(ps))), V.V2{0.0f64, 0.0f64}, True{}),
    er(8u64, li, 0n), er(0u64, li, 0n))

def cr_ex(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> E.Ex:
  E.ex_sub(E.ex_scale(E.ex_of(ax), by), E.ex_scale(E.ex_of(ay), bx))

def area_go(ps: List<&2, Pc>, +lo: E.Ex, +hi: E.Ex) -> List<&2, E.Ex>:
  match ps:
    case []: [lo, hi]
    case p <> +t:
      match p:
        case P_ln{+ax, +ay, +bx, +by}:
          area_go(t, E.ex_add(lo, cr_ex(ax, ay, bx, by)), E.ex_add(hi, cr_ex(ax, ay, bx, by)))
        case P_ar{+ax, +ay, +px, +py, w, +bx, +by}:
          +c = cr_ex(ax, ay, bx, by)
          +tr = XE.orient2(ax, ay, px, py, bx, by)
          +neg = sgn_neg(E.ex_sign(tr))
          area_go(t, E.ex_add(E.ex_add(lo, c), Bool.pick(E.Ex, neg, tr, E.ex_zero())),
            E.ex_add(E.ex_add(hi, c), Bool.pick(E.Ex, neg, E.ex_zero(), tr)))

def ex_hd(xs: List<&2, E.Ex>) -> E.Ex:
  match xs:
    case []: E.ex_zero()
    case h <> t: h

def ex_tl(xs: List<&2, E.Ex>) -> List<&2, E.Ex>:
  match xs:
    case []: []
    case h <> t: t

def orient_code(l: Lp) -> U64:
  match l:
    case K_circ{cx, cy, r}: 1u64
    case K_path{sgs}:
      +lh = area_go(sgs_pcs(sgs), E.ex_zero(), E.ex_zero())
      +lo = E.ex_sign(ex_hd(lh))
      +hi = E.ex_sign(ex_hd(ex_tl(lh)))
      Bool.pick(U64, sgn_pos(lo), 1u64, Bool.pick(U64, sgn_neg(hi), 2u64, 0u64))

def lp_ccw(+l: Lp, +c: U64) -> Lp:
  Bool.pick(Lp, U64.is_eq(c, 2u64), lp_rev(l), l)

def pip_go(ps: List<&2, Pc>, +qx: F64, +qy: F64, +odd: Bool) -> Bool:
  match ps:
    case []: odd
    case +p <> t:
      +ax = pc_ax(p)
      +ay = pc_ay(p)
      +bx = pc_bx(p)
      +by = pc_by(p)
      +ua = F64.is_lt(qy, ay)
      +ub = F64.is_lt(qy, by)
      +cross = Bool.and(Bool.not(Bool.and(ua, ub)), Bool.or(ua, ub))
      +s = ori(ax, ay, bx, by, qx, qy)
      +right = Bool.pick(Bool, ub, sgn_pos(s), sgn_neg(s))
      pip_go(t, qx, qy, Bool.xor(odd, Bool.and(cross, right)))

def lp_has(l: Lp, +qx: F64, +qy: F64) -> Bool:
  match l:
    case K_circ{cx, cy, r}: sgn_neg(E.ex_cmp(d2_ex(cx, cy, qx, qy), sq_ex(r)))
    case K_path{sgs}: pip_go(sgs_pcs(sgs), qx, qy, False{})

def lp_v0(l: Lp) -> V.Vec2:
  match l:
    case K_circ{cx, cy, r}: V.V2{F64.sub(cx, r), cy}
    case K_path{sgs}:
      +p = pc_hd(sgs_pcs(sgs))
      V.V2{pc_ax(p), pc_ay(p)}

def lp_inside(+a: Lp, +b: Lp) -> Bool:
  +v = lp_v0(a)
  lp_has(b, V.v2_x(v), V.v2_y(v))

def it_bx(i: It) -> Bx:
  It{lp, k, n, sh, x0, x1, y0, y1} = i
  Bx{x0, x1, y0, y1}

def its_bx(xs: List<&2, It>, +acc: Bx) -> Bx:
  match xs:
    case []: acc
    case +i <> t:
      Bx{+x0, +x1, +y0, +y1} = acc
      its_bx(t, Bx{F64.min(x0, it_x0(i)), F64.max(x1, it_x1(i)), F64.min(y0, it_y0(i)),
        F64.max(y1, it_y1(i))})

def bx_list(xs: List<&2, It>) -> Bx:
  match xs:
    case []: Bx{0.0f64, 0.0f64, 0.0f64, 0.0f64}
    case +i <> t: its_bx(t, it_bx(i))

def lp_bx(+l: Lp) -> Bx:
  bx_list(lp_its(l, 0n))

def bx_in(a: Bx, b: Bx) -> Bool:
  Bx{+ax0, +ax1, +ay0, +ay1} = a
  Bx{+bx0, +bx1, +by0, +by1} = b
  Bool.and(F64.is_le(bx0, ax0), Bool.and(F64.is_le(ax1, bx1),
    Bool.and(F64.is_le(by0, ay0), F64.is_le(ay1, by1))))

def loop_er(+l: Lp, +li: Nat) -> Er:
  +ps = lp_pcs(l)
  +a = adj_er(ps, li)
  +d = dup_er(ps, li)
  Bool.pick(Er, U64.is_eq(er_code(d), 0u64), Bool.pick(Er, Nat.is_eq(List.length(&2, Pc, ps), 0n),
    er(0u64, li, 0n), a), d)

def lps_er(ls: List<&2, Lp>, +i: Nat) -> Er:
  match ls:
    case []: er(0u64, 0n, 0n)
    case +l <> t:
      +e = loop_er(l, i)
      Bool.pick(Er, U64.is_eq(er_code(e), 0u64), lps_er(t, Nat.add(i, 1n)), e)

def lps_its(ls: List<&2, Lp>, +i: Nat) -> List<&2, It>:
  match ls:
    case []: []
    case l <> t: List.append(&2, It, lp_its(l, i), lps_its(t, Nat.add(i, 1n)))

def lps_ori(ls: List<&2, Lp>, +i: Nat) -> Nat:
  match ls:
    case []: 0n
    case l <> t: Bool.pick(Nat, U64.is_eq(orient_code(l), 0u64), Nat.add(i, 1n), lps_ori(t, Nat.add(i, 1n)))

def lps_ccw(ls: List<&2, Lp>) -> List<&2, Lp>:
  match ls:
    case []: []
    case +l <> t: lp_ccw(l, orient_code(l)) <> lps_ccw(t)

def it_of_bx(b: Bx, +i: Nat) -> It:
  Bx{x0, x1, y0, y1} = b
  It{i, 0n, 0n, Sh_seg{0.0f64, 0.0f64, 0.0f64, 0.0f64}, x0, x1, y0, y1}

def lp_it(+l: Lp, +i: Nat) -> It:
  it_of_bx(lp_bx(l), i)

def lps_lits(ls: List<&2, Lp>, +i: Nat) -> List<&2, It>:
  match ls:
    case []: []
    case +l <> t: lp_it(l, i) <> lps_lits(t, Nat.add(i, 1n))

def lp_nth(ls: List<&2, Lp>, +i: Nat) -> Lp:
  match ls:
    case []: K_circ{0.0f64, 0.0f64, 1.0f64}
    case l <> t:
      match i:
        case 0n: l
        case 1n+j: lp_nth(t, j)

def cn_one(+tb: B.Tb<&2, Lp>, +a: It, +b: It, +acc: List<&2, Cn>) -> List<&2, Cn>:
  +la = B.tb_get(Lp, tb, U32.from_nat(it_lp(a)))
  +lb = B.tb_get(Lp, tb, U32.from_nat(it_lp(b)))
  +ab = Bool.and(bx_in(it_bx(a), it_bx(b)), lp_inside(la, lb))
  +ba = Bool.and(bx_in(it_bx(b), it_bx(a)), lp_inside(lb, la))
  +acc1 = Bool.pick(List<&2, Cn>, ab, Cn{it_lp(a), it_lp(b), it_x0(b)} <> acc, acc)
  Bool.pick(List<&2, Cn>, ba, Cn{it_lp(b), it_lp(a), it_x0(a)} <> acc1, acc1)

def cns_of(prs: List<&2, Pr>, +tb: B.Tb<&2, Lp>) -> List<&2, Cn>:
  match prs:
    case []: []
    case p <> t:
      Pr{+a, +b} = p
      cn_one(tb, a, b, cns_of(t, tb))

def cn_ch(c: Cn) -> Nat:
  Cn{ch, pa, x0} = c
  ch

def cn_pa(c: Cn) -> Nat:
  Cn{ch, pa, x0} = c
  pa

def cn_x0(c: Cn) -> F64:
  Cn{ch, pa, x0} = c
  x0

def cn_cmp_go(+a: Cn, +b: Cn) -> B.Sgn:
  +s = B.sgn_pick(Nat.is_lt(cn_ch(a), cn_ch(b)), Nat.is_lt(cn_ch(b), cn_ch(a)))
  Bool.pick(B.Sgn, sgn_zero(s), fsg(cn_x0(a), cn_x0(b)), s)

def cn_cmp(a: Cn, b: Cn) -> B.Sgn:
  cn_cmp_go(a, b)

def so_cn(s: B.So<&2, Cn>) -> List<&2, Cn>:
  B.So{ok, xs} = s
  xs

def cn_hd_ch(xs: List<&2, Cn>) -> Nat:
  match xs:
    case []: 0n
    case c <> t: Nat.add(cn_ch(c), 1n)

def par_go(f: Nat, +i: Nat, cs: List<&2, Cn>, +best: Nat) -> List<&2, Nat>:
  match f:
    case 0n: []
    case 1n+(+g):
      match cs:
        case []: best <> par_go(g, Nat.add(i, 1n), [], 0n)
        case +c <> +t:
          +hit = Nat.is_eq(cn_ch(c), i)
          List.append(&2, Nat, Bool.pick(List<&2, Nat>, hit, [], [best]),
            par_go(g, Bool.pick(Nat, hit, i, Nat.add(i, 1n)), Bool.pick(List<&2, Cn>, hit, t, c <> t),
              Bool.pick(Nat, hit, Nat.add(cn_pa(c), 1n), 0n)))

def parents(+ls: List<&2, Lp>) -> List<&2, Nat>:
  +n = List.length(&2, Lp, ls)
  +tb = B.tb_of(Lp, ls, K_circ{0.0f64, 0.0f64, 1.0f64})
  +cs = so_cn(B.msort(~Cn, ~cn_cmp, cns_of(sweep(lps_lits(ls, 0n)), tb)))
  par_go(Nat.add(n, List.length(&2, Cn, cs)), 0n, cs, 0n)

def ck_ori_go(bad: Nat, +ls: List<&2, Lp>) -> CK:
  match bad:
    case 0n:
      +cl = lps_ccw(ls)
      CK_ok{cl, parents(cl)}
    case 1n+i: CK_err{er(11u64, i, 0n)}

def ck_ori(+ls: List<&2, Lp>) -> CK:
  ck_ori_go(lps_ori(ls, 0n), ls)

def ck_g1(ok: Bool, +e: Er, +ls: List<&2, Lp>) -> CK:
  match ok:
    case False{}: CK_err{e}
    case True{}: ck_ori(ls)

def ck_pairs(+ls: List<&2, Lp>) -> CK:
  +e = pairs_er(sweep(lps_its(ls, 0n)))
  ck_g1(U64.is_eq(er_code(e), 0u64), e, ls)

def ck_g0(ok: Bool, +e: Er, +ls: List<&2, Lp>) -> CK:
  match ok:
    case False{}: CK_err{e}
    case True{}: ck_pairs(ls)

def ck_loops(+ls: List<&2, Lp>) -> CK:
  +e = lps_er(ls, 0n)
  ck_g0(U64.is_eq(er_code(e), 0u64), e, ls)

def rl_nth(rs: List<&2, Rl>, +i: Nat) -> Rl:
  match rs:
    case []: K_root{}
    case r <> t:
      match i:
        case 0n: r
        case 1n+j: rl_nth(t, j)

def rl_hole(r: Rl) -> Bool:
  match r:
    case K_hole{o}: True{}
    case _: False{}

def role_code(r: Rl, +p: Nat, +rs: List<&2, Rl>) -> U64:
  match r:
    case K_free{}:
      match p:
        case 0n: 0u64
        case 1n+q: Bool.pick(U64, rl_hole(rl_nth(rs, q)), 0u64, 14u64)
    case K_hole{o}:
      match p:
        case 0n: 12u64
        case 1n+(+q):
          Bool.pick(U64, Nat.is_eq(q, o), 0u64, Bool.pick(U64, rl_hole(rl_nth(rs, q)), 13u64, 12u64))
    case K_in{c}:
      match p:
        case 0n: 18u64
        case 1n+(+q):
          Bool.pick(U64, Bool.or(Nat.is_eq(q, c), rl_hole(rl_nth(rs, q))), 0u64, 18u64)
    case K_root{}:
      match p:
        case 0n: 0u64
        case 1n+q: 18u64
    case K_obst{c}:
      match p:
        case 0n: 19u64
        case 1n+q: Bool.pick(U64, Nat.is_eq(q, c), 0u64, 19u64)

def roles_er(rs: List<&2, Rl>, ps: List<&2, Nat>, +all: List<&2, Rl>, +i: Nat) -> Er:
  match rs:
    case []: er(0u64, 0n, 0n)
    case r <> t:
      match ps:
        case []: er(0u64, 0n, 0n)
        case p <> u:
          +c = role_code(r, p, all)
          Bool.pick(Er, U64.is_eq(c, 0u64), roles_er(t, u, all, Nat.add(i, 1n)), er(c, i, 0n))

def ck_roles(c: CK, +rs: List<&2, Rl>) -> CK:
  match c:
    case CK_err{e}: CK_err{e}
    case CK_ok{+ls, +ps}:
      +e = roles_er(rs, ps, rs, 0n)
      Bool.pick(CK, U64.is_eq(er_code(e), 0u64), CK_ok{ls, ps}, CK_err{e})

def check(+ls: List<&2, Lp>, +rs: List<&2, Rl>) -> CK:
  ck_roles(ck_loops(ls), rs)

def ev_cons(r: LR, rest: EV) -> EV:
  match r:
    case LR_err{e}: EV_err{e}
    case LR_ok{l}:
      match rest:
        case EV_err{e}: EV_err{e}
        case EV_ok{ls}: EV_ok{l <> ls}

def loops_ev(ls: List<&2, Loop>, +e: X.Env, +i: Nat) -> EV:
  match ls:
    case []: EV_ok{[]}
    case l <> t: ev_cons(loop_ev(l, e, i), loops_ev(t, e, Nat.add(i, 1n)))

def rg_loops(rs: List<&2, Region>) -> List<&2, Loop>:
  match rs:
    case []: []
    case r <> t:
      Rg{o, hs} = r
      o <> List.append(&2, Loop, hs, rg_loops(t))

def hole_rls(hs: List<&2, Loop>, +o: Nat) -> List<&2, Rl>:
  match hs:
    case []: []
    case h <> t: K_hole{o} <> hole_rls(t, o)

def rg_rls(rs: List<&2, Region>, +i: Nat, +outer: Rl) -> List<&2, Rl>:
  match rs:
    case []: []
    case r <> t:
      Rg{o, +hs} = r
      +n = List.length(&2, Loop, hs)
      List.append(&2, Rl, outer <> hole_rls(hs, i), rg_rls(t, Nat.add(i, Nat.add(n, 1n)), outer))

def ev_check(r: EV, +rs: List<&2, Rl>) -> CK:
  match r:
    case EV_err{e}: CK_err{e}
    case EV_ok{ls}: check(ls, rs)

def prof_check(+rs: List<&2, Region>, +e: X.Env) -> CK:
  ev_check(loops_ev(rg_loops(rs), e, 0n), rg_rls(rs, 0n, K_free{}))
