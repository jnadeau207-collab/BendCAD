import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../c04/types.bend as Ty
import ../c06/iv.bend as I
import ../c06/prof.bend as F
import ../base/par.bend as B
import ../base/ex.bend as E
import ../c07/ivx.bend as X
import ../c07/sol.bend as SO
import ./core.bend as KC
import ./curve.bend as KU

def sgn_of(+s: B.Sgn) -> U64:
  match s:
    case B.Sp{}: 0u64
    case B.Sn{}: 1u64
    case B.Sz{}: 2u64
    case B.Su{}: 2u64

def ori_sign(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64) -> U64:
  sgn_of(F.ori(ax, ay, bx, by, cx, cy))

def pow_ex(+px: F64, +py: F64, +cx: F64, +cy: F64, +r: F64) -> E.Ex:
  E.ex_sub(E.ex_add(E.ex_mul(E.ex_dif(px, cx), E.ex_dif(px, cx)), E.ex_mul(E.ex_dif(py, cy), E.ex_dif(py, cy))),
    E.ex_mul(E.ex_of(r), E.ex_of(r)))

def pow_sign(+px: F64, +py: F64, +cx: F64, +cy: F64, +r: F64) -> U64:
  sgn_of(E.ex_sign(pow_ex(px, py, cx, cy, r)))

def disc_sign(+a: F64, +b: F64, +c: F64) -> U64:
  sgn_of(E.ex_sign(E.ex_sub(E.ex_mul(E.ex_of(b), E.ex_of(b)),
    E.ex_mul(E.ex_of(4.0f64), E.ex_mul(E.ex_of(a), E.ex_of(c))))))

def q_solve(+a: F64, +b: F64, +c: F64, +plus: Bool) -> F64:
  F64.div(Bool.pick(F64, plus, F64.add(F64.neg(b), F64.sqrt(F64.sub(F64.mul(b, b), F64.mul(4.0f64, F64.mul(a, c))))),
    F64.sub(F64.neg(b), F64.sqrt(F64.sub(F64.mul(b, b), F64.mul(4.0f64, F64.mul(a, c)))))), F64.mul(2.0f64, a))

def in_range(+t: F64, +lo: F64, +hi: F64) -> Bool:
  Bool.and(F64.is_le(lo, t), F64.is_le(t, hi))

type QG is Data:
  QG{ ln: Bool, ax: F64, ay: F64, bx: F64, by: F64, cx: F64, cy: F64, cr: F64, ccw: Bool,
    lab: U64, ref: Nat }

def qg_ln(+ax: F64, +ay: F64, +bx: F64, +by: F64, +lab: U64, +ref: Nat) -> QG:
  QG{True{}, ax, ay, bx, by, 0.0f64, 0.0f64, 0.0f64, True{}, lab, ref}

def qg_ar(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64, +cr: F64, +ccw: Bool,
    +lab: U64, +ref: Nat) -> QG:
  QG{False{}, ax, ay, bx, by, cx, cy, cr, ccw, lab, ref}

def qg_is_ln(+q: QG) -> Bool:
  QG{ln, ax, ay, bx, by, cx, cy, cr, ccw, lab, ref} = q
  ln

def qg_ax(+q: QG) -> F64:
  QG{ln, ax, ay, bx, by, cx, cy, cr, ccw, lab, ref} = q
  ax

def qg_ay(+q: QG) -> F64:
  QG{ln, ax, ay, bx, by, cx, cy, cr, ccw, lab, ref} = q
  ay

def qg_bx(+q: QG) -> F64:
  QG{ln, ax, ay, bx, by, cx, cy, cr, ccw, lab, ref} = q
  bx

def qg_by(+q: QG) -> F64:
  QG{ln, ax, ay, bx, by, cx, cy, cr, ccw, lab, ref} = q
  by

def qg_cx(+q: QG) -> F64:
  QG{ln, ax, ay, bx, by, cx, cy, cr, ccw, lab, ref} = q
  cx

def qg_cy(+q: QG) -> F64:
  QG{ln, ax, ay, bx, by, cx, cy, cr, ccw, lab, ref} = q
  cy

def qg_cr(+q: QG) -> F64:
  QG{ln, ax, ay, bx, by, cx, cy, cr, ccw, lab, ref} = q
  cr

def qg_ccw(+q: QG) -> Bool:
  QG{ln, ax, ay, bx, by, cx, cy, cr, ccw, lab, ref} = q
  ccw

def qg_lab(+q: QG) -> U64:
  QG{ln, ax, ay, bx, by, cx, cy, cr, ccw, lab, ref} = q
  lab

def qg_ref(+q: QG) -> Nat:
  QG{ln, ax, ay, bx, by, cx, cy, cr, ccw, lab, ref} = q
  ref

def qg_closed(+q: QG) -> Bool:
  Bool.and(Bool.not(qg_is_ln(q)),
    Bool.and(F64.is_eq(qg_ax(q), qg_bx(q)), F64.is_eq(qg_ay(q), qg_by(q))))

def qg_rev(+q: QG) -> QG:
  QG{+ln, +ax, +ay, +bx, +by, +cx, +cy, +cr, +ccw, +lab, +ref} = q
  Bool.pick(QG, ln, qg_ln(bx, by, ax, ay, lab, ref),
    qg_ar(bx, by, ax, ay, cx, cy, cr, Bool.not(ccw), lab, ref))

def lab_orig() -> U64:
  0u64

def lab_newln() -> U64:
  1u64

def lab_newar() -> U64:
  2u64

def lab_seg() -> U64:
  3u64

type QF is Data:
  QF{ outer: List<&2, QG>, holes: List<&2, List<&2, QG>> }

type QS is Data:
  QS{ ok: Bool, why: U64, wi: Nat, wj: Nat, frags: List<&2, QF> }

def qs_ok(+frags: List<&2, QF>) -> QS:
  QS{True{}, 0u64, 0n, 0n, frags}

def qs_fail(+why: U64, +wi: Nat, +wj: Nat) -> QS:
  QS{False{}, why, wi, wj, []}

def qs_is_ok(+q: QS) -> Bool:
  QS{ok, why, wi, wj, frags} = q
  ok

def qs_why(+q: QS) -> U64:
  QS{ok, why, wi, wj, frags} = q
  why

def qs_frags(+q: QS) -> List<&2, QF>:
  QS{ok, why, wi, wj, frags} = q
  frags

def qf_outer(+q: QF) -> List<&2, QG>:
  QF{outer, holes} = q
  outer

def qf_holes(+q: QF) -> List<&2, List<&2, QG>>:
  QF{outer, holes} = q
  holes

def pt_on_seg(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> U64:
  Bool.pick(U64, U64.is_eq(ori_sign(ax, ay, bx, by, px, py), 2u64),
    Bool.pick(U64,
      Bool.and(in_range(px, F64.min(ax, bx), F64.max(ax, bx)),
        in_range(py, F64.min(ay, by), F64.max(ay, by))), 2u64, 1u64),
    0u64)

def arc_wedge(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64,
    +ccw: Bool) -> U64:
  +o1 = ori_sign(cx, cy, ax, ay, px, py)
  +o2 = ori_sign(cx, cy, px, py, bx, by)
  +o3 = ori_sign(cx, cy, ax, ay, bx, by)
  +o4 = ori_sign(ax, ay, bx, by, px, py)
  +dw = Bool.pick(U64, ccw, Bool.pick(U64, Bool.or(U64.is_eq(o4, 1u64), U64.is_eq(o4, 2u64)),
      2u64, 1u64),
    Bool.pick(U64, Bool.or(U64.is_eq(o4, 0u64), U64.is_eq(o4, 2u64)), 2u64, 1u64))
  Bool.pick(U64, ccw,
    Bool.pick(U64, U64.is_eq(o3, 2u64), dw,
      Bool.pick(U64, U64.is_eq(o3, 0u64),
        Bool.pick(U64, Bool.and(Bool.or(U64.is_eq(o1, 0u64), U64.is_eq(o1, 2u64)),
          Bool.or(U64.is_eq(o2, 0u64), U64.is_eq(o2, 2u64))), 2u64, 1u64),
        Bool.pick(U64, Bool.or(Bool.or(U64.is_eq(o1, 0u64), U64.is_eq(o1, 2u64)),
          Bool.or(U64.is_eq(o2, 0u64), U64.is_eq(o2, 2u64))), 2u64, 1u64))),
    Bool.pick(U64, U64.is_eq(o3, 2u64), dw,
      Bool.pick(U64, U64.is_eq(o3, 1u64),
        Bool.pick(U64, Bool.and(Bool.or(U64.is_eq(o1, 1u64), U64.is_eq(o1, 2u64)),
          Bool.or(U64.is_eq(o2, 1u64), U64.is_eq(o2, 2u64))), 2u64, 1u64),
        Bool.pick(U64, Bool.or(Bool.or(U64.is_eq(o1, 1u64), U64.is_eq(o1, 2u64)),
          Bool.or(U64.is_eq(o2, 1u64), U64.is_eq(o2, 2u64))), 2u64, 1u64))))

def pt_on_arc(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64,
    +cr: F64, +ccw: Bool) -> U64:
  Bool.pick(U64, U64.is_eq(pow_sign(px, py, cx, cy, cr), 2u64),
    arc_wedge(px, py, ax, ay, bx, by, cx, cy, ccw), 0u64)

def qg_on(+q: QG, +px: F64, +py: F64) -> U64:
  Bool.pick(U64, qg_is_ln(q), pt_on_seg(px, py, qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q)),
    pt_on_arc(px, py, qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q), qg_cx(q), qg_cy(q), qg_cr(q), qg_ccw(q)))

def ray_ln_x(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> U64:
  +t = F64.div(F64.sub(py, ay), F64.sub(by, ay))
  +xi = F64.add(ax, F64.mul(t, F64.sub(bx, ax)))
  Bool.pick(U64, F64.is_lt(px, xi), 1u64, Bool.pick(U64, F64.is_eq(px, xi), 2u64, 0u64))

def ray_ln(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> U64:
  +strad = Bool.or(Bool.and(F64.is_lt(ay, py), F64.is_le(py, by)), Bool.and(F64.is_lt(by, py), F64.is_le(py, ay)))
  Bool.pick(U64, strad,
    Bool.pick(U64, U64.is_eq(ori_sign(ax, ay, bx, by, px, py), 2u64), 2u64, ray_ln_x(px, py, ax, ay, bx, by)),
    0u64)

def qg_mid_ln(+q: QG) -> V.Vec2:
  V.V2{F64.mul(0.5f64, F64.add(qg_ax(q), qg_bx(q))), F64.mul(0.5f64, F64.add(qg_ay(q), qg_by(q)))}

def qg_mid_ar_go(+dz: Bool, +q: QG, +dx: F64, +dy: F64, +l: F64) -> V.Vec2:
  match dz:
    case True{}:
      +axc = F64.sub(qg_ax(q), qg_cx(q))
      +ayc = F64.sub(qg_ay(q), qg_cy(q))
      Bool.pick(V.Vec2, qg_ccw(q), V.V2{F64.sub(qg_cx(q), ayc), F64.add(qg_cy(q), axc)},
        V.V2{F64.add(qg_cx(q), ayc), F64.sub(qg_cy(q), axc)})
    case False{}:
      V.V2{F64.add(qg_cx(q), F64.mul(qg_cr(q), F64.div(dx, l))),
        F64.add(qg_cy(q), F64.mul(qg_cr(q), F64.div(dy, l)))}

def qg_mid_ar(+q: QG) -> V.Vec2:
  +dx = F64.add(F64.sub(qg_ax(q), qg_cx(q)), F64.sub(qg_bx(q), qg_cx(q)))
  +dy = F64.add(F64.sub(qg_ay(q), qg_cy(q)), F64.sub(qg_by(q), qg_cy(q)))
  +l = F64.sqrt(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)))
  qg_mid_ar_go(F64.is_eq(l, 0.0f64), q, dx, dy, l)

def qg_mid(+q: QG) -> V.Vec2:
  Bool.pick(V.Vec2, qg_is_ln(q), qg_mid_ln(q), qg_mid_ar(q))

def qg_mid_major(+q: QG, +dx: F64, +dy: F64, +l: F64) -> V.Vec2:
  +cross = F64.sub(F64.mul(F64.sub(qg_ax(q), qg_cx(q)), F64.sub(qg_by(q), qg_cy(q))),
    F64.mul(F64.sub(qg_ay(q), qg_cy(q)), F64.sub(qg_bx(q), qg_cx(q))))
  +major = Bool.pick(Bool, qg_ccw(q), F64.is_lt(cross, 0.0f64), F64.is_lt(0.0f64, cross))
  +s = Bool.pick(F64, major, F64.neg(1.0f64), 1.0f64)
  V.V2{F64.add(qg_cx(q), F64.mul(F64.mul(s, qg_cr(q)), F64.div(dx, l))),
    F64.add(qg_cy(q), F64.mul(F64.mul(s, qg_cr(q)), F64.div(dy, l)))}

def qg_mid_true_ar(+q: QG) -> V.Vec2:
  +dx = F64.add(F64.sub(qg_ax(q), qg_cx(q)), F64.sub(qg_bx(q), qg_cx(q)))
  +dy = F64.add(F64.sub(qg_ay(q), qg_cy(q)), F64.sub(qg_by(q), qg_cy(q)))
  +l = F64.sqrt(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)))
  Bool.pick(V.Vec2, F64.is_eq(l, 0.0f64), qg_mid_ar_go(True{}, q, dx, dy, l),
    qg_mid_major(q, dx, dy, l))

def qg_mid_true(+q: QG) -> V.Vec2:
  Bool.pick(V.Vec2, qg_is_ln(q), qg_mid_ln(q), qg_mid_true_ar(q))

def xnear(+a: F64, +b: F64) -> Bool:
  F64.is_le(KU.fabs(F64.sub(a, b)),
    F64.mul(0.000000001f64, F64.add(1.0f64, F64.add(KU.fabs(a), KU.fabs(b)))))

def ray_end(+x: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> Bool:
  Bool.or(Bool.and(xnear(x, ax), F64.is_eq(py, ay)), Bool.and(xnear(x, bx), F64.is_eq(py, by)))

def ray_ar_tan(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64,
    +cr: F64, +ccw: Bool, +my: F64) -> U64:
  +w = arc_wedge(cx, py, ax, ay, bx, by, cx, cy, ccw)
  +closed = Bool.and(F64.is_eq(ax, bx), F64.is_eq(ay, by))
  +ke = Bool.and(ray_end(cx, py, ax, ay, bx, by), Bool.and(Bool.not(closed), F64.is_lt(my, py)))
  Bool.pick(U64, U64.is_eq(w, 2u64),
    Bool.pick(U64, ke, Bool.pick(U64, F64.is_lt(px, cx), 1u64,
      Bool.pick(U64, F64.is_eq(px, cx), 2u64, 0u64)),
      Bool.pick(U64, F64.is_lt(px, cx), 0u64, Bool.pick(U64, F64.is_eq(px, cx), 2u64, 0u64))),
    0u64)

def ray_ar_two(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64,
    +cr: F64, +ccw: Bool, +my: F64, +sq: F64) -> U64:
  +x1 = F64.sub(cx, sq)
  +x2 = F64.add(cx, sq)
  +w1 = arc_wedge(x1, py, ax, ay, bx, by, cx, cy, ccw)
  +w2 = arc_wedge(x2, py, ax, ay, bx, by, cx, cy, ccw)
  +closed = Bool.and(F64.is_eq(ax, bx), F64.is_eq(ay, by))
  +ke = Bool.or(closed, F64.is_lt(my, py))
  +k1 = Bool.or(Bool.not(ray_end(x1, py, ax, ay, bx, by)), ke)
  +k2 = Bool.or(Bool.not(ray_end(x2, py, ax, ay, bx, by)), ke)
  +c1 = Bool.pick(U64, Bool.and(U64.is_eq(w1, 2u64), k1),
    Bool.pick(U64, F64.is_lt(px, x1), 1u64, Bool.pick(U64, F64.is_eq(px, x1), 2u64, 0u64)),
    0u64)
  +c2 = Bool.pick(U64, Bool.and(U64.is_eq(w2, 2u64), k2),
    Bool.pick(U64, F64.is_lt(px, x2), 1u64, Bool.pick(U64, F64.is_eq(px, x2), 2u64, 0u64)),
    0u64)
  Bool.pick(U64, Bool.or(U64.is_eq(c1, 2u64), U64.is_eq(c2, 2u64)), 2u64,
    Bool.pick(U64, U64.is_eq(c1, c2), 0u64, 1u64))

def ray_ar(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64,
    +cr: F64, +ccw: Bool, +my: F64) -> U64:
  +dy = F64.sub(py, cy)
  +dd = F64.sub(F64.mul(cr, cr), F64.mul(dy, dy))
  Bool.pick(U64, F64.is_lt(dd, 0.0f64), 0u64,
    Bool.pick(U64, F64.is_eq(dd, 0.0f64), ray_ar_tan(px, py, ax, ay, bx, by, cx, cy, cr, ccw, my),
      ray_ar_two(px, py, ax, ay, bx, by, cx, cy, cr, ccw, my, F64.sqrt(dd))))

def qg_ray(+q: QG, +px: F64, +py: F64) -> U64:
  Bool.pick(U64, qg_is_ln(q), ray_ln(px, py, qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q)),
    ray_ar(px, py, qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q), qg_cx(q), qg_cy(q), qg_cr(q),
      qg_ccw(q), V.v2_y(qg_mid(q))))

def pip_loop_go(ps: List<&2, QG>, +px: F64, +py: F64, +par: Bool) -> U64:
  match ps:
    case []: Bool.pick(U64, par, 1u64, 0u64)
    case +q <> t:
      +o = qg_on(q, px, py)
      +r = qg_ray(q, px, py)
      Bool.pick(U64, U64.is_eq(o, 2u64), 2u64,
        Bool.pick(U64, U64.is_eq(r, 2u64), 2u64,
          pip_loop_go(t, px, py, Bool.pick(Bool, U64.is_eq(r, 1u64), Bool.not(par), par))))

def pip_loop(ps: List<&2, QG>, +px: F64, +py: F64) -> U64:
  pip_loop_go(ps, px, py, False{})

def pip_holes_go(hs: List<&2, List<&2, QG>>, +px: F64, +py: F64, +inh: Bool) -> U64:
  match hs:
    case []: Bool.pick(U64, inh, 0u64, 1u64)
    case +h <> t:
      +r = pip_loop(h, px, py)
      Bool.pick(U64, U64.is_eq(r, 2u64), 2u64,
        pip_holes_go(t, px, py, Bool.or(inh, U64.is_eq(r, 1u64))))

def pip_frag(+f: QF, +px: F64, +py: F64) -> U64:
  +r = pip_loop(qf_outer(f), px, py)
  Bool.pick(U64, U64.is_eq(r, 2u64), 2u64,
    Bool.pick(U64, U64.is_eq(r, 0u64), 0u64, pip_holes_go(qf_holes(f), px, py, False{})))

def sh_piece_go(+closed: Bool, +q: QG) -> F64:
  match closed:
    case True{}:
      +a = F64.mul(3.141592653589793f64, F64.mul(qg_cr(q), qg_cr(q)))
      Bool.pick(F64, qg_ccw(q), a, F64.neg(a))
    case False{}:
      F64.sub(F64.mul(qg_ax(q), qg_by(q)), F64.mul(qg_bx(q), qg_ay(q)))

def sh_piece(+q: QG) -> F64:
  sh_piece_go(qg_closed(q), q)

def sh_area_go(ps: List<&2, QG>, +acc: F64) -> F64:
  match ps:
    case []: acc
    case +q <> t: sh_area_go(t, F64.add(acc, sh_piece(q)))

def sh_signed(ps: List<&2, QG>) -> F64:
  F64.mul(0.5f64, sh_area_go(ps, 0.0f64))

def vline_seg(+c: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> U64:
  Bool.pick(U64, F64.is_eq(ax, bx),
    Bool.pick(U64, F64.is_eq(ax, c), 3u64, 0u64),
    Bool.pick(U64,
      Bool.or(Bool.and(F64.is_le(ax, c), F64.is_le(c, bx)), Bool.and(F64.is_le(bx, c), F64.is_le(c, ax))),
      Bool.pick(U64, Bool.or(F64.is_eq(c, ax), F64.is_eq(c, bx)), 1u64, 2u64), 0u64))

def vline_seg_y(+c: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> F64:
  F64.add(ay, F64.mul(F64.div(F64.sub(c, ax), F64.sub(bx, ax)), F64.sub(by, ay)))

def hline_seg(+c: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> U64:
  Bool.pick(U64, F64.is_eq(ay, by),
    Bool.pick(U64, F64.is_eq(ay, c), 3u64, 0u64),
    Bool.pick(U64,
      Bool.or(Bool.and(F64.is_le(ay, c), F64.is_le(c, by)), Bool.and(F64.is_le(by, c), F64.is_le(c, ay))),
      Bool.pick(U64, Bool.or(F64.is_eq(c, ay), F64.is_eq(c, by)), 1u64, 2u64), 0u64))

def hline_seg_x(+c: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> F64:
  F64.add(ax, F64.mul(F64.div(F64.sub(c, ay), F64.sub(by, ay)), F64.sub(bx, ax)))

def vline_arc(+c: F64, +cx: F64, +cy: F64, +cr: F64) -> U64:
  +dd = F64.sub(F64.mul(cr, cr), F64.mul(F64.sub(c, cx), F64.sub(c, cx)))
  Bool.pick(U64, F64.is_lt(dd, 0.0f64), 0u64,
    Bool.pick(U64, F64.is_eq(dd, 0.0f64), 1u64, 2u64))

def hline_arc(+c: F64, +cx: F64, +cy: F64, +cr: F64) -> U64:
  +dd = F64.sub(F64.mul(cr, cr), F64.mul(F64.sub(c, cy), F64.sub(c, cy)))
  Bool.pick(U64, F64.is_lt(dd, 0.0f64), 0u64,
    Bool.pick(U64, F64.is_eq(dd, 0.0f64), 1u64, 2u64))

def circ_seg_one(+t: F64) -> U64:
  Bool.pick(U64, Bool.and(F64.is_le(0.0f64, t), F64.is_le(t, 1.0f64)), 1u64, 0u64)

def circ_seg_two(+tm: F64, +td: F64) -> U64:
  +i1 = Bool.pick(U64, Bool.and(F64.is_le(0.0f64, F64.sub(tm, td)), F64.is_le(F64.sub(tm, td), 1.0f64)), 1u64, 0u64)
  +i2 = Bool.pick(U64, Bool.and(F64.is_le(0.0f64, F64.add(tm, td)), F64.is_le(F64.add(tm, td), 1.0f64)), 1u64, 0u64)
  Bool.pick(U64, Bool.and(U64.is_eq(i1, 1u64), U64.is_eq(i2, 1u64)), 2u64,
    Bool.pick(U64, Bool.or(U64.is_eq(i1, 1u64), U64.is_eq(i2, 1u64)), 1u64, 0u64))

def circ_seg_ds(+ds: U64, +a: F64, +b: F64, +c: F64) -> U64:
  Bool.pick(U64, U64.is_eq(ds, 1u64), 0u64,
    Bool.pick(U64, U64.is_eq(ds, 2u64), circ_seg_one(F64.div(F64.neg(b), F64.mul(2.0f64, a))),
      circ_seg_two(F64.div(F64.neg(b), F64.mul(2.0f64, a)),
        F64.div(F64.sqrt(F64.sub(F64.mul(b, b), F64.mul(4.0f64, F64.mul(a, c)))), F64.mul(2.0f64, a)))))

def circ_seg_n(+cx: F64, +cy: F64, +cr: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> U64:
  +dx = F64.sub(bx, ax)
  +dy = F64.sub(by, ay)
  +fx = F64.sub(ax, cx)
  +fy = F64.sub(ay, cy)
  +a = F64.add(F64.mul(dx, dx), F64.mul(dy, dy))
  +b = F64.mul(2.0f64, F64.add(F64.mul(fx, dx), F64.mul(fy, dy)))
  +cc = F64.sub(F64.add(F64.mul(fx, fx), F64.mul(fy, fy)), F64.mul(cr, cr))
  circ_seg_ds(disc_sign(a, b, cc), a, b, cc)

def circ_seg_t(+cx: F64, +cy: F64, +cr: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64, +plus: Bool) -> F64:
  +dx = F64.sub(bx, ax)
  +dy = F64.sub(by, ay)
  +fx = F64.sub(ax, cx)
  +fy = F64.sub(ay, cy)
  q_solve(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)),
    F64.mul(2.0f64, F64.add(F64.mul(fx, dx), F64.mul(fy, dy))),
    F64.sub(F64.add(F64.mul(fx, fx), F64.mul(fy, fy)), F64.mul(cr, cr)), plus)

def seg_pt(+ax: F64, +ay: F64, +bx: F64, +by: F64, +t: F64) -> V.Vec2:
  V.V2{F64.add(ax, F64.mul(t, F64.sub(bx, ax))), F64.add(ay, F64.mul(t, F64.sub(by, ay)))}

def seg_seg_touch(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64, +dx: F64, +dy: F64,
    +o1: U64, +o2: U64, +o3: U64, +o4: U64) -> U64:
  Bool.pick(U64, Bool.and(Bool.and(U64.is_eq(o1, 2u64), U64.is_eq(o2, 2u64)),
    Bool.and(U64.is_eq(o3, 2u64), U64.is_eq(o4, 2u64))), 3u64,
    Bool.pick(U64,
      Bool.or(Bool.and(U64.is_eq(o1, 2u64), U64.is_eq(pt_on_seg(cx, cy, ax, ay, bx, by), 2u64)),
        Bool.or(Bool.and(U64.is_eq(o2, 2u64), U64.is_eq(pt_on_seg(dx, dy, ax, ay, bx, by), 2u64)),
          Bool.or(Bool.and(U64.is_eq(o3, 2u64), U64.is_eq(pt_on_seg(ax, ay, cx, cy, dx, dy), 2u64)),
            Bool.and(U64.is_eq(o4, 2u64), U64.is_eq(pt_on_seg(bx, by, cx, cy, dx, dy), 2u64))))), 1u64, 0u64))

def seg_seg_n(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64, +dx: F64, +dy: F64) -> U64:
  +o1 = ori_sign(ax, ay, bx, by, cx, cy)
  +o2 = ori_sign(ax, ay, bx, by, dx, dy)
  +o3 = ori_sign(cx, cy, dx, dy, ax, ay)
  +o4 = ori_sign(cx, cy, dx, dy, bx, by)
  Bool.pick(U64, Bool.or(U64.is_eq(o1, 2u64), Bool.or(U64.is_eq(o2, 2u64),
    Bool.or(U64.is_eq(o3, 2u64), U64.is_eq(o4, 2u64)))),
    seg_seg_touch(ax, ay, bx, by, cx, cy, dx, dy, o1, o2, o3, o4),
    Bool.pick(U64, Bool.and(Bool.not(U64.is_eq(o1, o2)), Bool.not(U64.is_eq(o3, o4))), 2u64, 0u64))

def seg_seg_pt(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64, +dx: F64, +dy: F64) -> V.Vec2:
  +d = F64.sub(F64.mul(F64.sub(bx, ax), F64.sub(dy, cy)), F64.mul(F64.sub(by, ay), F64.sub(dx, cx)))
  +t = F64.div(F64.sub(F64.mul(F64.sub(cx, ax), F64.sub(dy, cy)), F64.mul(F64.sub(cy, ay), F64.sub(dx, cx))), d)
  seg_pt(ax, ay, bx, by, t)

type QC is Data:
  QC{ eps: F64, tab: List<&2, V.Vec2> }

type QR is Data:
  QR{ qs: QS, qc: QC }

def qc_eps(+q: QC) -> F64:
  QC{eps, tab} = q
  eps

def qc_tab(+q: QC) -> List<&2, V.Vec2>:
  QC{eps, tab} = q
  tab

def qr_qs(+q: QR) -> QS:
  QR{qs, qc} = q
  qs

def qr_qc(+q: QR) -> QC:
  QR{qs, qc} = q
  qc

def adopt_near(+px: F64, +py: F64, +eps: F64, +h: V.Vec2) -> Bool:
  Bool.and(F64.is_le(KU.fabs(F64.sub(px, V.v2_x(h))), eps),
    F64.is_le(KU.fabs(F64.sub(py, V.v2_y(h))), eps))

type QAF is Data:
  QAF{ v: V.Vec2, found: Bool, tab: List<&2, V.Vec2> }

def adopt_cons(+near: Bool, +h: V.Vec2, +r: QAF) -> QAF:
  QAF{+v, +found, +tab} = r
  QAF{Bool.pick(V.Vec2, near, h, v), Bool.or(near, found), h <> tab}

def adopt_find(+px: F64, +py: F64, +eps: F64, tab: List<&2, V.Vec2>) -> QAF:
  match tab:
    case []: QAF{V.V2{px, py}, False{}, []}
    case +h <> t:
      adopt_cons(adopt_near(px, py, eps, h), h, adopt_find(px, py, eps, t))

def adopt_qc_go(+found: Bool, +v: V.Vec2, +tab: List<&2, V.Vec2>, +eps: F64) -> QR2:
  match found:
    case True{}: QR2{v, QC{eps, tab}}
    case False{}: QR2{v, QC{eps, v <> tab}}

def adopt_qc(+r: QAF, +eps: F64) -> QR2:
  QAF{+v, +found, +tab} = r
  adopt_qc_go(found, v, tab, eps)

type QR2 is Data:
  QR2{ v: V.Vec2, qc: QC }

def adopt(+px: F64, +py: F64, +q: QC) -> QR2:
  QC{+eps, +tab} = q
  adopt_qc(adopt_find(px, py, eps, tab), eps)

def qr2_v(+q: QR2) -> V.Vec2:
  QR2{v, qc} = q
  v

def qr2_qc(+q: QR2) -> QC:
  QR2{v, qc} = q
  qc

def ln_side(+vert: Bool, +c: F64, +px: F64, +py: F64) -> U64:
  +v = Bool.pick(F64, vert, px, py)
  Bool.pick(U64, F64.is_lt(v, c), 0u64, Bool.pick(U64, F64.is_eq(v, c), 2u64, 1u64))

def ln_piece_on(+vert: Bool, +c: F64, +q: QG) -> Bool:
  Bool.pick(Bool, qg_is_ln(q),
    Bool.and(U64.is_eq(ln_side(vert, c, qg_ax(q), qg_ay(q)), 2u64),
      U64.is_eq(ln_side(vert, c, qg_bx(q), qg_by(q)), 2u64)),
    False{})

def ln_seg_x(+vert: Bool, +c: F64, +q: QG) -> V.Vec2:
  Bool.pick(V.Vec2, vert, V.V2{c, vline_seg_y(c, qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q))},
    V.V2{hline_seg_x(c, qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q)), c})

def ln_seg_hit(+vert: Bool, +c: F64, +q: QG) -> U64:
  Bool.pick(U64, vert, vline_seg(c, qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q)),
    hline_seg(c, qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q)))

def ln_arc_one(+vert: Bool, +c: F64, +q: QG, +s: F64) -> List<&2, V.Vec2>:
  +p = Bool.pick(V.Vec2, vert, V.V2{c, F64.add(qg_cy(q), s)}, V.V2{F64.add(qg_cx(q), s), c})
  Bool.pick(List<&2, V.Vec2>,
    U64.is_eq(arc_wedge(V.v2_x(p), V.v2_y(p), qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q),
      qg_cx(q), qg_cy(q), qg_ccw(q)), 2u64), [p], [])

def ln_arc_xs(+vert: Bool, +c: F64, +q: QG) -> List<&2, V.Vec2>:
  +dd = Bool.pick(F64, vert,
    F64.sub(F64.mul(qg_cr(q), qg_cr(q)), F64.mul(F64.sub(c, qg_cx(q)), F64.sub(c, qg_cx(q)))),
    F64.sub(F64.mul(qg_cr(q), qg_cr(q)), F64.mul(F64.sub(c, qg_cy(q)), F64.sub(c, qg_cy(q)))))
  Bool.pick(List<&2, V.Vec2>, F64.is_lt(dd, 0.0f64), [],
    Bool.pick(List<&2, V.Vec2>, F64.is_eq(dd, 0.0f64),
      ln_arc_one(vert, c, q, 0.0f64),
      List.append(&2, V.Vec2, ln_arc_one(vert, c, q, F64.sqrt(dd)), ln_arc_one(vert, c, q, F64.neg(F64.sqrt(dd))))))

def v2_eq(+a: V.Vec2, +b: V.Vec2) -> Bool:
  Bool.and(F64.is_eq(V.v2_x(a), V.v2_x(b)), F64.is_eq(V.v2_y(a), V.v2_y(b)))

def qg_interior_side(+vert: Bool, +c: F64, +q: QG) -> U64:
  +m = qg_mid(q)
  ln_side(vert, c, V.v2_x(m), V.v2_y(m))

def sub_ln(+q: QG, +mx: F64, +my: F64) -> List<&2, QG>:
  [qg_ln(qg_ax(q), qg_ay(q), mx, my, qg_lab(q), qg_ref(q)),
    qg_ln(mx, my, qg_bx(q), qg_by(q), qg_lab(q), qg_ref(q))]

def sub_ar(+q: QG, +mx: F64, +my: F64) -> List<&2, QG>:
  [qg_ar(qg_ax(q), qg_ay(q), mx, my, qg_cx(q), qg_cy(q), qg_cr(q), qg_ccw(q), qg_lab(q), qg_ref(q)),
    qg_ar(mx, my, qg_bx(q), qg_by(q), qg_cx(q), qg_cy(q), qg_cr(q), qg_ccw(q), qg_lab(q), qg_ref(q))]

def is_endpoint(+px: F64, +py: F64, +q: QG) -> Bool:
  Bool.or(Bool.and(F64.is_eq(px, qg_ax(q)), F64.is_eq(py, qg_ay(q))),
    Bool.and(F64.is_eq(px, qg_bx(q)), F64.is_eq(py, qg_by(q))))

type QR3 is Data:
  QR3{ ps: List<&2, QG>, xs: List<&2, V.Vec2>, qc: QC }

def qr3_ps(+q: QR3) -> List<&2, QG>:
  QR3{ps, xs, qc} = q
  ps

def qr3_xs(+q: QR3) -> List<&2, V.Vec2>:
  QR3{ps, xs, qc} = q
  xs

def qr3_qc(+q: QR3) -> QC:
  QR3{ps, xs, qc} = q
  qc

def split_ln_do(+q: QG, +x: V.Vec2, +qc: QC) -> QR3:
  +r = adopt(V.v2_x(x), V.v2_y(x), qc)
  +v = qr2_v(r)
  QR3{sub_ln(q, V.v2_x(v), V.v2_y(v)), [v], qr2_qc(r)}

def split_ln_h(+hit: U64, +q: QG, +x: V.Vec2, +qc: QC) -> QR3:
  match hit:
    case 2u64: split_ln_do(q, x, qc)
    case _: QR3{[q], [], qc}

def split_ln_at(+vert: Bool, +c: F64, +q: QG, +qc: QC) -> QR3:
  split_ln_h(ln_seg_hit(vert, c, q), q, ln_seg_x(vert, c, q), qc)

def arc_order(+q: QG, +x1: V.Vec2, +x2: V.Vec2) -> Bool:
  U64.is_eq(arc_wedge(V.v2_x(x1), V.v2_y(x1), qg_ax(q), qg_ay(q), V.v2_x(x2), V.v2_y(x2),
    qg_cx(q), qg_cy(q), qg_ccw(q)), 2u64)

def sub_ar_dedup(+q: QG, +f: V.Vec2) -> List<&2, QG>:
  Bool.pick(List<&2, QG>, v2_eq(V.V2{qg_ax(q), qg_ay(q)}, f), [],
    [qg_ar(qg_ax(q), qg_ay(q), V.v2_x(f), V.v2_y(f), qg_cx(q), qg_cy(q), qg_cr(q), qg_ccw(q),
      qg_lab(q), qg_ref(q))])

def sub_ar_mid(+q: QG, +f: V.Vec2, +s: V.Vec2) -> List<&2, QG>:
  Bool.pick(List<&2, QG>, v2_eq(f, s), [],
    [qg_ar(V.v2_x(f), V.v2_y(f), V.v2_x(s), V.v2_y(s), qg_cx(q), qg_cy(q), qg_cr(q), qg_ccw(q),
      qg_lab(q), qg_ref(q))])

def sub_ar_end(+q: QG, +s: V.Vec2) -> List<&2, QG>:
  Bool.pick(List<&2, QG>, v2_eq(s, V.V2{qg_bx(q), qg_by(q)}), [],
    [qg_ar(V.v2_x(s), V.v2_y(s), qg_bx(q), qg_by(q), qg_cx(q), qg_cy(q), qg_cr(q), qg_ccw(q),
      qg_lab(q), qg_ref(q))])

def sub_ar2(+q: QG, +f: V.Vec2, +s: V.Vec2) -> List<&2, QG>:
  List.append(&2, QG, sub_ar_dedup(q, f),
    List.append(&2, QG, sub_ar_mid(q, f, s), sub_ar_end(q, s)))

def sub_ar_drop(+q: QG, +v: V.Vec2) -> List<&2, QG>:
  List.append(&2, QG, sub_ar_dedup(q, v), sub_ar_end(q, v))

def xs_dedup(+v1: V.Vec2, +v2: V.Vec2) -> List<&2, V.Vec2>:
  Bool.pick(List<&2, V.Vec2>, v2_eq(v1, v2), [v1], [v1, v2])

def split_ar_two(+q: QG, +x1: V.Vec2, +x2: V.Vec2, +qc: QC) -> QR3:
  +r1 = adopt(V.v2_x(x1), V.v2_y(x1), qc)
  +v1 = qr2_v(r1)
  +r2 = adopt(V.v2_x(x2), V.v2_y(x2), qr2_qc(r1))
  +v2 = qr2_v(r2)
  +f = Bool.pick(V.Vec2, arc_order(q, v1, v2), v1, v2)
  +s = Bool.pick(V.Vec2, arc_order(q, v1, v2), v2, v1)
  QR3{sub_ar2(q, f, s), xs_dedup(v1, v2), qr2_qc(r2)}

def split_ar_one_h(+isep: Bool, +q: QG, +v: V.Vec2, +qc: QC) -> QR3:
  match isep:
    case True{}: QR3{[q], [], qc}
    case False{}: QR3{sub_ar_drop(q, v), [v], qc}

def split_ar_one_do(+q: QG, +x: V.Vec2, +qc: QC) -> QR3:
  +r = adopt(V.v2_x(x), V.v2_y(x), qc)
  +v = qr2_v(r)
  split_ar_one_h(is_endpoint(V.v2_x(v), V.v2_y(v), q), q, v, qr2_qc(r))

def split_ar_by2(+xs: List<&2, V.Vec2>, +q: QG, +x: V.Vec2, +qc: QC) -> QR3:
  match xs:
    case []: split_ar_one_do(q, x, qc)
    case +y <> _: split_ar_two(q, x, y, qc)

def split_ar_by(+xs: List<&2, V.Vec2>, +q: QG, +qc: QC) -> QR3:
  match xs:
    case []: QR3{[q], [], qc}
    case +x <> t:
      split_ar_by2(t, q, x, qc)

def split_ar_at(+vert: Bool, +c: F64, +q: QG, +qc: QC) -> QR3:
  split_ar_by(ln_arc_xs(vert, c, q), q, qc)

def split_qg_h(+isln: Bool, +vert: Bool, +c: F64, +q: QG, +qc: QC) -> QR3:
  match isln:
    case True{}: split_ln_at(vert, c, q, qc)
    case False{}: split_ar_at(vert, c, q, qc)

def split_qg_at(+vert: Bool, +c: F64, +q: QG, +qc: QC) -> QR3:
  split_qg_h(qg_is_ln(q), vert, c, q, qc)

def insert_ln_go(ps: List<&2, QG>, +vert: Bool, +c: F64, +qc: QC, +acc: List<&2, QG>,
    +xs: List<&2, V.Vec2>) -> QR3:
  match ps:
    case []: QR3{List.reverse(&2, QG, acc), List.reverse(&2, V.Vec2, xs), qc}
    case +q <> t:
      +r = split_qg_at(vert, c, q, qc)
      insert_ln_go(t, vert, c, qr3_qc(r), List.append(&2, QG, List.reverse(&2, QG, qr3_ps(r)), acc),
        List.append(&2, V.Vec2, List.reverse(&2, V.Vec2, qr3_xs(r)), xs))

def insert_ln(ps: List<&2, QG>, +vert: Bool, +c: F64, +qc: QC) -> QR3:
  insert_ln_go(ps, vert, c, qc, [], [])

type QW is Data:
  QW{ neg: List<&2, QG>, pos: List<&2, QG>, xs: List<&2, V.Vec2>, ok: Bool, hasn: Bool, hasp: Bool }

def qw_init() -> QW:
  QW{[], [], [], True{}, False{}, False{}}

def qw_neg(+q: QW) -> List<&2, QG>:
  QW{neg, pos, xs, ok, hasn, hasp} = q
  neg

def qw_pos(+q: QW) -> List<&2, QG>:
  QW{neg, pos, xs, ok, hasn, hasp} = q
  pos

def qw_xs(+q: QW) -> List<&2, V.Vec2>:
  QW{neg, pos, xs, ok, hasn, hasp} = q
  xs

def qw_ok(+q: QW) -> Bool:
  QW{neg, pos, xs, ok, hasn, hasp} = q
  ok

def qw_hasn(+q: QW) -> Bool:
  QW{neg, pos, xs, ok, hasn, hasp} = q
  hasn

def qw_hasp(+q: QW) -> Bool:
  QW{neg, pos, xs, ok, hasn, hasp} = q
  hasp

def qw_ln_side(+vert: Bool, +c: F64, +q: QG) -> U64:
  +sa = ln_side(vert, c, qg_ax(q), qg_ay(q))
  +sb = ln_side(vert, c, qg_bx(q), qg_by(q))
  Bool.pick(U64, U64.is_eq(sa, sb), sa,
    Bool.pick(U64, U64.is_eq(sa, 2u64), sb,
      Bool.pick(U64, U64.is_eq(sb, 2u64), sa, 3u64)))

def qw_side(+vert: Bool, +c: F64, +q: QG) -> U64:
  Bool.pick(U64, qg_is_ln(q), qw_ln_side(vert, c, q), qg_interior_side(vert, c, q))

def qw_add_xs(+sb: U64, +q: QG, +xs: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  match sb:
    case 2u64: V.V2{qg_bx(q), qg_by(q)} <> xs
    case _: xs

def qw_add_neg(+q: QG, +sb: U64, +r: QW) -> QW:
  QW{+ng, +ps2, +xs, +ok, +hn, +hp} = r
  QW{q <> ng, ps2, qw_add_xs(sb, q, xs), ok, True{}, hp}

def qw_add_pos(+q: QG, +sb: U64, +r: QW) -> QW:
  QW{+ng, +ps2, +xs, +ok, +hn, +hp} = r
  QW{ng, q <> ps2, qw_add_xs(sb, q, xs), ok, hn, True{}}

def qw_add_both(+q: QG, +sb: U64, +r: QW) -> QW:
  QW{+ng, +ps2, +xs, +ok, +hn, +hp} = r
  QW{q <> ng, q <> ps2, qw_add_xs(sb, q, xs), ok, hn, hp}

def qw_add_bad(+q: QG, +sb: U64, +r: QW) -> QW:
  QW{+ng, +ps2, +xs, +ok, +hn, +hp} = r
  QW{ng, ps2, qw_add_xs(sb, q, xs), False{}, hn, hp}

def qw_combine(+s: U64, +q: QG, +sb: U64, +r: QW) -> QW:
  match s:
    case 0u64: qw_add_neg(q, sb, r)
    case 1u64: qw_add_pos(q, sb, r)
    case 2u64: qw_add_both(q, sb, r)
    case _: qw_add_bad(q, sb, r)

def qw_walk_go(ps: List<&2, QG>, +vert: Bool, +c: F64) -> QW:
  match ps:
    case []: qw_init()
    case +q <> t:
      qw_combine(qw_side(vert, c, q), q, ln_side(vert, c, qg_bx(q), qg_by(q)), qw_walk_go(t, vert, c))

def qw_walk(ps: List<&2, QG>, +vert: Bool, +c: F64) -> QW:
  qw_walk_go(ps, vert, c)

type VL is Data:
  VN{}
  VC{ h: V.Vec2, t: VL }

def vl_cons(+x: V.Vec2, +xs: VL) -> VL:
  VC{x, xs}

def vl_nil() -> VL:
  VN{}

def vl_of_list(xs: List<&2, V.Vec2>) -> VL:
  match xs:
    case []: VN{}
    case +h <> t: VC{h, vl_of_list(t)}

def cut_ord(+vert: Bool, +x: V.Vec2) -> F64:
  Bool.pick(F64, vert, V.v2_y(x), V.v2_x(x))

def cut_lt(+vert: Bool, +a: V.Vec2, +b: V.Vec2) -> Bool:
  F64.is_lt(cut_ord(vert, a), cut_ord(vert, b))

def cut_sort_ins(+vert: Bool, +x: V.Vec2, +xs: VL) -> VL:
  match xs:
    case VN{}: VC{x, VN{}}
    case VC{+h, +t}: Bool.pick(VL, cut_lt(vert, x, h), VC{x, xs}, VC{h, cut_sort_ins(vert, x, t)})

def cut_sort_go(+vert: Bool, +xs: VL, +acc: VL) -> VL:
  match xs:
    case VN{}: acc
    case VC{+h, +t}: cut_sort_go(vert, t, cut_sort_ins(vert, h, acc))

def cut_sort(+vert: Bool, +xs: VL) -> VL:
  cut_sort_go(vert, xs, VN{})

def cut_between(+vert: Bool, +a: V.Vec2, +b: V.Vec2, +x: V.Vec2) -> Bool:
  +oa = cut_ord(vert, a)
  +ob = cut_ord(vert, b)
  +ox = cut_ord(vert, x)
  Bool.and(Bool.or(Bool.and(F64.is_lt(oa, ox), F64.is_lt(ox, ob)), Bool.and(F64.is_lt(ob, ox), F64.is_lt(ox, oa))),
    Bool.not(v2_eq(x, a)))

type QCS is Data:
  QCS{ br: List<&2, QG>, na: V.Vec2 }

def qcs_br(+r: QCS) -> List<&2, QG>:
  QCS{br, na} = r
  br

def qcs_na(+r: QCS) -> V.Vec2:
  QCS{br, na} = r
  na

def cut_step_go(+btw: Bool, +a: V.Vec2, +b: V.Vec2, +h: V.Vec2, +cref: Nat) -> QCS:
  match btw:
    case True{}: QCS{[qg_ln(V.v2_x(a), V.v2_y(a), V.v2_x(h), V.v2_y(h), lab_newln(), cref)], h}
    case False{}: QCS{[], a}

def cut_step(+vert: Bool, +a: V.Vec2, +b: V.Vec2, +h: V.Vec2, +cref: Nat) -> QCS:
  cut_step_go(cut_between(vert, a, b, h), a, b, h, cref)

def cut_chain_go(+xs: VL, +vert: Bool, +a: V.Vec2, +b: V.Vec2, +cref: Nat,
    +acc: List<&2, QG>) -> List<&2, QG>:
  match xs:
    case VN{}: qg_ln(V.v2_x(a), V.v2_y(a), V.v2_x(b), V.v2_y(b), lab_newln(), cref) <> acc
    case VC{+h, +t}:
      +r = cut_step(vert, a, b, h, cref)
      cut_chain_go(t, vert, qcs_na(r), b, cref, List.append(&2, QG, qcs_br(r), acc))

def cut_chain(+vert: Bool, +a: V.Vec2, +b: V.Vec2, +xs: VL, +cref: Nat) -> List<&2, QG>:
  Bool.pick(List<&2, QG>, v2_eq(a, b), [], cut_chain_go(cut_sort(vert, xs), vert, a, b, cref, []))

def qg_a(+q: QG) -> V.Vec2:
  V.V2{qg_ax(q), qg_ay(q)}

def qg_b(+q: QG) -> V.Vec2:
  V.V2{qg_bx(q), qg_by(q)}

def gap_is_gap(+vert: Bool, +c: F64, +prev: V.Vec2, +q: QG) -> Bool:
  +a = qg_a(q)
  Bool.and(Bool.not(v2_eq(prev, a)),
    Bool.and(U64.is_eq(ln_side(vert, c, V.v2_x(prev), V.v2_y(prev)), 2u64),
      U64.is_eq(ln_side(vert, c, V.v2_x(a), V.v2_y(a)), 2u64)))

def gap_is_gap_pt(+vert: Bool, +c: F64, +prev: V.Vec2, +a: V.Vec2) -> Bool:
  Bool.and(Bool.not(v2_eq(prev, a)),
    Bool.and(U64.is_eq(ln_side(vert, c, V.v2_x(prev), V.v2_y(prev)), 2u64),
      U64.is_eq(ln_side(vert, c, V.v2_x(a), V.v2_y(a)), 2u64)))

def gap_fill_go(ps: List<&2, QG>, +vert: Bool, +c: F64, +xs: VL, +cref: Nat,
    +first: V.Vec2, +has: Bool, +acc: List<&2, QG>) -> List<&2, QG>:
  match ps:
    case []: List.reverse(&2, QG, acc)
    case +q <> t:
      +need = Bool.and(has, gap_is_gap(vert, c, first, q))
      +br = Bool.pick(List<&2, QG>, need, cut_chain(vert, first, V.V2{qg_ax(q), qg_ay(q)}, xs, cref), [])
      gap_fill_go(t, vert, c, xs, cref, V.V2{qg_bx(q), qg_by(q)}, True{},
        List.append(&2, QG, q <> List.reverse(&2, QG, br), acc))

def qg_last_go(ps: List<&2, QG>, +cur: QG) -> QG:
  match ps:
    case []: cur
    case +h <> t: qg_last_go(t, h)

def qg_last(ps: List<&2, QG>, +dflt: QG) -> QG:
  match ps:
    case []: dflt
    case +h <> t: qg_last_go(t, h)

def gap_wrap_last(+h: QG, +l: QG, +ps: List<&2, QG>, +vert: Bool, +c: F64, +xs: VL,
    +cref: Nat) -> List<&2, QG>:
  +a = qg_a(h)
  +b = qg_b(l)
  Bool.pick(List<&2, QG>, gap_is_gap_pt(vert, c, b, a),
    List.append(&2, QG, ps, cut_chain(vert, b, a, xs, cref)), ps)

def gap_wrap(+ps: List<&2, QG>, +vert: Bool, +c: F64, +xs: VL, +cref: Nat) -> List<&2, QG>:
  match ps:
    case []: []
    case +h <> t:
      gap_wrap_last(h, qg_last(t, h), ps, vert, c, xs, cref)

def gap_fill(ps: List<&2, QG>, +vert: Bool, +c: F64, +xs: List<&2, V.Vec2>, +cref: Nat) -> List<&2, QG>:
  +v = vl_of_list(xs)
  gap_wrap(gap_fill_go(ps, vert, c, v, cref, V.V2{0.0f64, 0.0f64}, False{}, []), vert, c, v, cref)

type QL is Data:
  QL{ neg: List<&2, QG>, pos: List<&2, QG>, split: Bool, ok: Bool }

def ql_neg(+q: QL) -> List<&2, QG>:
  QL{neg, pos, split, ok} = q
  neg

def ql_pos(+q: QL) -> List<&2, QG>:
  QL{neg, pos, split, ok} = q
  pos

def ql_split(+q: QL) -> Bool:
  QL{neg, pos, split, ok} = q
  split

def ql_ok(+q: QL) -> Bool:
  QL{neg, pos, split, ok} = q
  ok

type QR4 is Data:
  QR4{ ql: QL, qc: QC }

def loop_clip_ln(ps: List<&2, QG>, +vert: Bool, +c: F64, +cref: Nat, +qc: QC) -> QR4:
  +ins = insert_ln(ps, vert, c, qc)
  +w = qw_walk(qr3_ps(ins), vert, c)
  +sp = Bool.and(qw_hasn(w), qw_hasp(w))
  +xs = qr3_xs(ins)
  +neg = gap_fill(qw_neg(w), vert, c, xs, cref)
  +pos = gap_fill(qw_pos(w), vert, c, xs, cref)
  QR4{QL{neg, pos, sp, qw_ok(w)}, qr3_qc(ins)}

def qr4_ql(+q: QR4) -> QL:
  QR4{ql, qc} = q
  ql

def qr4_qc(+q: QR4) -> QC:
  QR4{ql, qc} = q
  qc

def samp_cands_cc(+q: QG) -> List<&2, V.Vec2>:
  [V.V2{qg_cx(q), qg_cy(q)}]

def samp_cands_go(+q: QG, +k1: F64, +k2: F64) -> List<&2, V.Vec2>:
  +m = qg_mid(q)
  +dx = F64.sub(qg_bx(q), qg_ax(q))
  +dy = F64.sub(qg_by(q), qg_ay(q))
  +l = F64.sqrt(F64.add(F64.mul(dx, dx), F64.mul(dy, dy)))
  +nx = F64.div(F64.neg(dy), l)
  +ny = F64.div(dx, l)
  +e1 = F64.mul(l, k1)
  +e2 = F64.mul(l, k2)
  [V.V2{F64.add(V.v2_x(m), F64.mul(e1, nx)), F64.add(V.v2_y(m), F64.mul(e1, ny))},
    V.V2{F64.sub(V.v2_x(m), F64.mul(e1, nx)), F64.sub(V.v2_y(m), F64.mul(e1, ny))},
    V.V2{F64.add(V.v2_x(m), F64.mul(e2, nx)), F64.add(V.v2_y(m), F64.mul(e2, ny))},
    V.V2{F64.sub(V.v2_x(m), F64.mul(e2, nx)), F64.sub(V.v2_y(m), F64.mul(e2, ny))}]

def samp_cands_pick(+closed: Bool, +q: QG, +k1: F64, +k2: F64) -> List<&2, V.Vec2>:
  match closed:
    case True{}: samp_cands_cc(q)
    case False{}: samp_cands_go(q, k1, k2)

def samp_cands(+q: QG, +k1: F64, +k2: F64) -> List<&2, V.Vec2>:
  samp_cands_pick(qg_closed(q), q, k1, k2)

def arc_minor(+q: QG) -> Bool:
  +s = ori_sign(qg_cx(q), qg_cy(q), qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q))
  Bool.pick(Bool, qg_ccw(q), U64.is_eq(s, 0u64), U64.is_eq(s, 1u64))

def arc_diametral(+q: QG) -> Bool:
  Bool.and(xnear(F64.mul(0.5f64, F64.add(qg_ax(q), qg_bx(q))), qg_cx(q)),
    xnear(F64.mul(0.5f64, F64.add(qg_ay(q), qg_by(q))), qg_cy(q)))

def arc_halve(+q: QG, +mx: F64, +my: F64) -> List<&2, QG>:
  [qg_ar(qg_ax(q), qg_ay(q), mx, my, qg_cx(q), qg_cy(q), qg_cr(q), qg_ccw(q), qg_lab(q),
    qg_ref(q)),
    qg_ar(mx, my, qg_bx(q), qg_by(q), qg_cx(q), qg_cy(q), qg_cr(q), qg_ccw(q), qg_lab(q),
      qg_ref(q))]

def arc_split_mid(+use_mid: Bool, +q: QG) -> List<&2, QG>:
  match use_mid:
    case True{}:
      +m = qg_mid(q)
      arc_halve(q, V.v2_x(m), V.v2_y(m))
    case False{}:
      +m = qg_mid(q)
      arc_halve(q, F64.sub(F64.add(qg_cx(q), qg_cx(q)), V.v2_x(m)),
        F64.sub(F64.add(qg_cy(q), qg_cy(q)), V.v2_y(m)))

def arc_qpts(+ccw: Bool, +cx: F64, +cy: F64, +dx: F64, +dy: F64) -> V.Vec2:
  match ccw:
    case True{}: V.V2{F64.sub(cx, dy), F64.add(cy, dx)}
    case False{}: V.V2{F64.add(cx, dy), F64.sub(cy, dx)}

def arc_quarter(+q: QG) -> List<&2, QG>:
  +ax = qg_ax(q)
  +ay = qg_ay(q)
  +cx = qg_cx(q)
  +cy = qg_cy(q)
  +p1 = arc_qpts(qg_ccw(q), cx, cy, F64.sub(ax, cx), F64.sub(ay, cy))
  +p3 = arc_qpts(qg_ccw(q), cx, cy, F64.sub(cx, ax), F64.sub(cy, ay))
  +ox = F64.sub(F64.add(cx, cx), ax)
  +oy = F64.sub(F64.add(cy, cy), ay)
  [qg_ar(ax, ay, V.v2_x(p1), V.v2_y(p1), cx, cy, qg_cr(q), qg_ccw(q), qg_lab(q), qg_ref(q)),
    qg_ar(V.v2_x(p1), V.v2_y(p1), ox, oy, cx, cy, qg_cr(q), qg_ccw(q), qg_lab(q), qg_ref(q)),
    qg_ar(ox, oy, V.v2_x(p3), V.v2_y(p3), cx, cy, qg_cr(q), qg_ccw(q), qg_lab(q), qg_ref(q)),
    qg_ar(V.v2_x(p3), V.v2_y(p3), ax, ay, cx, cy, qg_cr(q), qg_ccw(q), qg_lab(q), qg_ref(q))]

def piece_split_ar2(+single: Bool, +q: QG) -> List<&2, QG>:
  match single:
    case True{}: [q]
    case False{}: arc_split_mid(Bool.or(arc_minor(q), arc_diametral(q)), q)

def piece_split_ar(+closed: Bool, +q: QG) -> List<&2, QG>:
  match closed:
    case True{}: arc_quarter(q)
    case False{}: piece_split_ar2(Bool.and(arc_minor(q), Bool.not(arc_diametral(q))), q)

def piece_split(+q: QG) -> List<&2, QG>:
  Bool.pick(List<&2, QG>, qg_is_ln(q), [q], piece_split_ar(qg_closed(q), q))

def pieces_split_go(ps: List<&2, QG>, +acc: List<&2, QG>) -> List<&2, QG>:
  match ps:
    case []: List.reverse(&2, QG, acc)
    case +h <> +t:
      pieces_split_go(t, List.append(&2, QG, List.reverse(&2, QG, piece_split(h)), acc))

def pieces_split(ps: List<&2, QG>) -> List<&2, QG>:
  pieces_split_go(ps, [])

type SV is Data:
  SV{ hit: Bool, v: V.Vec2 }

def sv_hit(+s: SV) -> Bool:
  SV{hit, v} = s
  hit

def sv_miss() -> SV:
  SV{False{}, V.V2{0.0f64, 0.0f64}}

def samp_verify_sv(cs: List<&2, V.Vec2>, +bnd: List<&2, QG>) -> SV:
  match cs:
    case []: sv_miss()
    case +h <> t:
      +r = samp_verify_sv(t, bnd)
      Bool.pick(SV, U64.is_eq(pip_loop(bnd, V.v2_x(h), V.v2_y(h)), 1u64), SV{True{}, h}, r)

def sv_pick(+s: SV, +r: SV) -> SV:
  Bool.pick(SV, sv_hit(s), s, r)

def samp_find_sv(ps: List<&2, QG>, +all: List<&2, QG>, +k1: F64, +k2: F64) -> SV:
  match ps:
    case []: sv_miss()
    case +q <> t:
      sv_pick(samp_verify_sv(samp_cands(q, k1, k2), all), samp_find_sv(t, all, k1, k2))

def sv_maybe(+s: SV) -> Maybe<&2, V.Vec2>:
  match s:
    case SV{hit, +v}: Bool.pick(Maybe<&2, V.Vec2>, hit, Some{v}, None{})

def samp_find(+ps: List<&2, QG>) -> Maybe<&2, V.Vec2>:
  sv_maybe(samp_find_sv(ps, ps, 0.000244140625f64, 0.00000095367431640625f64))

def v2_near(+a: V.Vec2, +b: V.Vec2) -> Bool:
  Bool.and(xnear(V.v2_x(a), V.v2_x(b)), xnear(V.v2_y(a), V.v2_y(b)))

def cc_xs_h(+conc: Bool, +none: Bool, +d: F64, +ca: F64, +h: F64, +x1: F64, +y1: F64,
    +x2: F64, +y2: F64) -> List<&2, V.Vec2>:
  match conc:
    case True{}: []
    case False{}:
      match none:
        case True{}: []
        case False{}:
          +ux = F64.div(F64.sub(x2, x1), d)
          +uy = F64.div(F64.sub(y2, y1), d)
          +mx = F64.add(x1, F64.mul(ca, ux))
          +my = F64.add(y1, F64.mul(ca, uy))
          [V.V2{F64.sub(mx, F64.mul(h, uy)), F64.add(my, F64.mul(h, ux))},
            V.V2{F64.add(mx, F64.mul(h, uy)), F64.sub(my, F64.mul(h, ux))}]

def cc_xs_go(+dz: Bool, +d2: F64, +x1: F64, +y1: F64, +r1: F64, +x2: F64, +y2: F64,
    +r2: F64) -> List<&2, V.Vec2>:
  match dz:
    case True{}: []
    case False{}:
      +d = F64.sqrt(d2)
      +tol = F64.mul(0.000000001f64, F64.add(r1, r2))
      +ca = F64.div(F64.sub(F64.add(F64.mul(r1, r1), d2), F64.mul(r2, r2)),
        F64.add(d, d))
      +h2 = F64.sub(F64.mul(r1, r1), F64.mul(ca, ca))
      cc_xs_h(F64.is_le(d, tol), F64.is_le(h2, 0.0f64), d, ca, F64.sqrt(h2), x1, y1, x2, y2)

def cc_xs(+x1: F64, +y1: F64, +r1: F64, +x2: F64, +y2: F64, +r2: F64) -> List<&2, V.Vec2>:
  +dx = F64.sub(x2, x1)
  +dy = F64.sub(y2, y1)
  +d2 = F64.add(F64.mul(dx, dx), F64.mul(dy, dy))
  cc_xs_go(F64.is_eq(d2, 0.0f64), d2, x1, y1, r1, x2, y2, r2)

def venn_xs_ln_t(+q: QG, +cx: F64, +cy: F64, +cr: F64, +t: F64,
    +acc: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  +keep = Bool.and(Bool.not(xnear(t, 0.0f64)), Bool.not(xnear(t, 1.0f64)))
  +hit = Bool.and(in_range(t, 0.0f64, 1.0f64), keep)
  Bool.pick(List<&2, V.Vec2>, hit, seg_pt(qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q), t) <> acc,
    acc)

def venn_xs_ln_go(+n: U64, +q: QG, +cx: F64, +cy: F64, +cr: F64) -> List<&2, V.Vec2>:
  match n:
    case 2u64:
      venn_xs_ln_t(q, cx, cy, cr, circ_seg_t(cx, cy, cr, qg_ax(q), qg_ay(q), qg_bx(q),
        qg_by(q), False{}),
        venn_xs_ln_t(q, cx, cy, cr, circ_seg_t(cx, cy, cr, qg_ax(q), qg_ay(q), qg_bx(q),
          qg_by(q), True{}), []))
    case _: []

def venn_xs_ln_dg(+dg: Bool, +q: QG, +cx: F64, +cy: F64, +cr: F64) -> List<&2, V.Vec2>:
  match dg:
    case True{}: []
    case False{}:
      venn_xs_ln_go(circ_seg_n(cx, cy, cr, qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q)), q, cx,
        cy, cr)

def venn_xs_ln(+q: QG, +cx: F64, +cy: F64, +cr: F64) -> List<&2, V.Vec2>:
  venn_xs_ln_dg(Bool.and(F64.is_eq(qg_ax(q), qg_bx(q)), F64.is_eq(qg_ay(q), qg_by(q))), q,
    cx, cy, cr)

def venn_xs_ar_go(ps: List<&2, V.Vec2>, +q: QG) -> List<&2, V.Vec2>:
  match ps:
    case []: []
    case +h <> +t:
      +w = arc_wedge(V.v2_x(h), V.v2_y(h), qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q),
        qg_cx(q), qg_cy(q), qg_ccw(q))
      +ep = Bool.or(v2_near(h, V.V2{qg_ax(q), qg_ay(q)}), v2_near(h, V.V2{qg_bx(q), qg_by(q)}))
      Bool.pick(List<&2, V.Vec2>, Bool.and(U64.is_eq(w, 2u64), Bool.not(ep)), h <> venn_xs_ar_go(t, q),
        venn_xs_ar_go(t, q))

def venn_xs_ar(+q: QG, +cx: F64, +cy: F64, +cr: F64) -> List<&2, V.Vec2>:
  venn_xs_ar_go(cc_xs(qg_cx(q), qg_cy(q), qg_cr(q), cx, cy, cr), q)

def venn_xs(+q: QG, +cx: F64, +cy: F64, +cr: F64) -> List<&2, V.Vec2>:
  Bool.pick(List<&2, V.Vec2>, qg_is_ln(q), venn_xs_ln(q, cx, cy, cr),
    venn_xs_ar(q, cx, cy, cr))

def venn_sub_ln2(+q: QG, +x1: V.Vec2, +x2: V.Vec2) -> List<&2, QG>:
  [qg_ln(qg_ax(q), qg_ay(q), V.v2_x(x1), V.v2_y(x1), qg_lab(q), qg_ref(q)),
    qg_ln(V.v2_x(x1), V.v2_y(x1), V.v2_x(x2), V.v2_y(x2), qg_lab(q), qg_ref(q)),
    qg_ln(V.v2_x(x2), V.v2_y(x2), qg_bx(q), qg_by(q), qg_lab(q), qg_ref(q))]

def venn_sub_ln_t(t: List<&2, V.Vec2>, +q: QG, +x: V.Vec2) -> List<&2, QG>:
  match t:
    case []:
      [qg_ln(qg_ax(q), qg_ay(q), V.v2_x(x), V.v2_y(x), qg_lab(q), qg_ref(q)),
        qg_ln(V.v2_x(x), V.v2_y(x), qg_bx(q), qg_by(q), qg_lab(q), qg_ref(q))]
    case +x2 <> +t2: venn_sub_ln2(q, x, x2)

def venn_sub_ln(+q: QG, +xs: List<&2, V.Vec2>) -> List<&2, QG>:
  match xs:
    case []: [q]
    case +x <> +t: venn_sub_ln_t(t, q, x)

def venn_sub_ar_ord(+q: QG, +x1: V.Vec2, +x2: V.Vec2) -> Bool:
  U64.is_eq(arc_wedge(V.v2_x(x1), V.v2_y(x1), qg_ax(q), qg_ay(q), V.v2_x(x2), V.v2_y(x2),
    qg_cx(q), qg_cy(q), qg_ccw(q)), 2u64)

def venn_sub_ar2(+q: QG, +x1: V.Vec2, +x2: V.Vec2) -> List<&2, QG>:
  Bool.pick(List<&2, QG>, venn_sub_ar_ord(q, x1, x2),
    [qg_ar(qg_ax(q), qg_ay(q), V.v2_x(x1), V.v2_y(x1), qg_cx(q), qg_cy(q), qg_cr(q),
      qg_ccw(q), qg_lab(q), qg_ref(q)),
      qg_ar(V.v2_x(x1), V.v2_y(x1), V.v2_x(x2), V.v2_y(x2), qg_cx(q), qg_cy(q), qg_cr(q),
        qg_ccw(q), qg_lab(q), qg_ref(q)),
      qg_ar(V.v2_x(x2), V.v2_y(x2), qg_bx(q), qg_by(q), qg_cx(q), qg_cy(q), qg_cr(q),
        qg_ccw(q), qg_lab(q), qg_ref(q))],
    [qg_ar(qg_ax(q), qg_ay(q), V.v2_x(x2), V.v2_y(x2), qg_cx(q), qg_cy(q), qg_cr(q),
      qg_ccw(q), qg_lab(q), qg_ref(q)),
      qg_ar(V.v2_x(x2), V.v2_y(x2), V.v2_x(x1), V.v2_y(x1), qg_cx(q), qg_cy(q), qg_cr(q),
        qg_ccw(q), qg_lab(q), qg_ref(q)),
      qg_ar(V.v2_x(x1), V.v2_y(x1), qg_bx(q), qg_by(q), qg_cx(q), qg_cy(q), qg_cr(q),
        qg_ccw(q), qg_lab(q), qg_ref(q))])

def venn_sub_ar_t(t: List<&2, V.Vec2>, +q: QG, +x: V.Vec2) -> List<&2, QG>:
  match t:
    case []:
      [qg_ar(qg_ax(q), qg_ay(q), V.v2_x(x), V.v2_y(x), qg_cx(q), qg_cy(q), qg_cr(q),
        qg_ccw(q), qg_lab(q), qg_ref(q)),
        qg_ar(V.v2_x(x), V.v2_y(x), qg_bx(q), qg_by(q), qg_cx(q), qg_cy(q), qg_cr(q),
          qg_ccw(q), qg_lab(q), qg_ref(q))]
    case +x2 <> +t2: venn_sub_ar2(q, x, x2)

def venn_sub_ar(+q: QG, +xs: List<&2, V.Vec2>) -> List<&2, QG>:
  match xs:
    case []: [q]
    case +x <> +t: venn_sub_ar_t(t, q, x)

def venn_sub(+q: QG, +cx: F64, +cy: F64, +cr: F64) -> List<&2, QG>:
  +xs = venn_xs(q, cx, cy, cr)
  Bool.pick(List<&2, QG>, qg_is_ln(q), venn_sub_ln(q, xs), venn_sub_ar(q, xs))

def venn_subs_go(ps: List<&2, QG>, +cx: F64, +cy: F64, +cr: F64,
    +acc: List<&2, QG>) -> List<&2, QG>:
  match ps:
    case []: List.reverse(&2, QG, acc)
    case +h <> +t:
      venn_subs_go(t, cx, cy, cr, List.append(&2, QG, List.reverse(&2, QG, venn_sub(h, cx, cy, cr)), acc))

def venn_subs(ps: List<&2, QG>, +cx: F64, +cy: F64, +cr: F64) -> List<&2, QG>:
  venn_subs_go(ps, cx, cy, cr, [])

type VS is Data:
  VS{ q: QG, s: U64 }

def vs_q(+v: VS) -> QG:
  VS{q, s} = v
  q

def vs_s(+v: VS) -> U64:
  VS{q, s} = v
  s

type VCL is Data:
  VCL{ vs: List<&2, VS>, bad: Bool }

def vcl_vs(+v: VCL) -> List<&2, VS>:
  VCL{vs, bad} = v
  vs

def vcl_bad(+v: VCL) -> Bool:
  VCL{vs, bad} = v
  bad

def venn_cl_go(ps: List<&2, QG>, +cx: F64, +cy: F64, +cr: F64, +acc: List<&2, VS>,
    +bad: Bool) -> VCL:
  match ps:
    case []: VCL{List.reverse(&2, VS, acc), bad}
    case +h <> +t:
      +m = qg_mid(h)
      +s = pow_sign(V.v2_x(m), V.v2_y(m), cx, cy, cr)
      venn_cl_go(t, cx, cy, cr, VS{h, s} <> acc, Bool.or(bad, U64.is_eq(s, 2u64)))

def venn_cl(ps: List<&2, QG>, +cx: F64, +cy: F64, +cr: F64) -> VCL:
  venn_cl_go(ps, cx, cy, cr, [], False{})

def venn_cx_go(vs: List<&2, VS>, +acc: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  match vs:
    case []: List.reverse(&2, V.Vec2, acc)
    case +h <> +t: venn_cx_go(t, V.V2{qg_ax(vs_q(h)), qg_ay(vs_q(h))} <> acc)

def venn_cx(vs: List<&2, VS>) -> List<&2, V.Vec2>:
  venn_cx_go(vs, [])

def venn_dup_h(+h: V.Vec2, xs: List<&2, V.Vec2>) -> Bool:
  match xs:
    case []: False{}
    case +k <> +t: Bool.or(v2_near(h, k), venn_dup_h(h, t))

def venn_dup_go(xs: List<&2, V.Vec2>, +dup: Bool) -> Bool:
  match xs:
    case []: dup
    case +h <> +t: venn_dup_go(t, Bool.or(dup, venn_dup_h(h, t)))

def venn_dup(xs: List<&2, V.Vec2>) -> Bool:
  venn_dup_go(xs, False{})

def venn_chain_go(vs: List<&2, VS>, +side: U64, +cur: List<&2, QG>,
    +acc: List<&2, List<&2, QG>>) -> List<&2, List<&2, QG>>:
  match vs:
    case []: List.reverse(&2, List<&2, QG>, List.reverse(&2, QG, cur) <> acc)
    case +h <> +t:
      match h:
        case VS{q, s}:
          match s:
            case 0u64:
              match side:
                case 0u64: venn_chain_go(t, side, q <> cur, acc)
                case _: venn_chain_go(t, s, [q], List.reverse(&2, QG, cur) <> acc)
            case 1u64:
              match side:
                case 1u64: venn_chain_go(t, side, q <> cur, acc)
                case _: venn_chain_go(t, s, [q], List.reverse(&2, QG, cur) <> acc)
            case _: venn_chain_go(t, s, [q], List.reverse(&2, QG, cur) <> acc)

def venn_rot_go(vs: List<&2, VS>, +s0: U64, +acc: List<&2, VS>) -> List<&2, VS>:
  match vs:
    case []: List.reverse(&2, VS, acc)
    case +h <> +t:
      match h:
        case VS{q, s}:
          match s:
            case 0u64:
              match s0:
                case 0u64: venn_rot_go(t, s0, h <> acc)
                case _: List.append(&2, VS, h <> t, List.reverse(&2, VS, acc))
            case 1u64:
              match s0:
                case 1u64: venn_rot_go(t, s0, h <> acc)
                case _: List.append(&2, VS, h <> t, List.reverse(&2, VS, acc))
            case _: List.append(&2, VS, h <> t, List.reverse(&2, VS, acc))

def venn_rot_hd(+h: VS, t: List<&2, VS>) -> List<&2, VS>:
  venn_rot_go(t, vs_s(h), [h])

def venn_rot(vs: List<&2, VS>) -> List<&2, VS>:
  match vs:
    case []: []
    case +h <> +t: venn_rot_hd(h, t)

def venn_chains_go(vs: List<&2, VS>) -> List<&2, List<&2, QG>>:
  match vs:
    case []: []
    case +h <> +t: venn_chain_go(t, vs_s(h), [vs_q(h)], [])

def venn_chains(vs: List<&2, VS>) -> List<&2, List<&2, QG>>:
  venn_chains_go(venn_rot(vs))

def venn_side_of(ch: List<&2, QG>, +cx: F64, +cy: F64, +cr: F64) -> U64:
  match ch:
    case []: 2u64
    case +h <> +t:
      +m = qg_mid(h)
      pow_sign(V.v2_x(m), V.v2_y(m), cx, cy, cr)

def venn_chside(chs: List<&2, List<&2, QG>>, +cx: F64, +cy: F64, +cr: F64,
    +acc: List<&2, U64>) -> List<&2, U64>:
  match chs:
    case []: List.reverse(&2, U64, acc)
    case +h <> +t: venn_chside(t, cx, cy, cr, venn_side_of(h, cx, cy, cr) <> acc)

def venn_st(ch: List<&2, QG>) -> V.Vec2:
  match ch:
    case []: V.V2{0.0f64, 0.0f64}
    case +h <> +t: qg_a(h)

def venn_en(ch: List<&2, QG>) -> V.Vec2:
  match ch:
    case []: V.V2{0.0f64, 0.0f64}
    case +h <> +t: qg_b(qg_last(h <> t, h))

def venn_mids_d(+dia: Bool, +ux: F64, +uy: F64, +px: F64, +py: F64, +cx: F64, +cy: F64,
    +cr: F64) -> List<&2, V.Vec2>:
  match dia:
    case True{}:
      [V.V2{F64.sub(cx, F64.mul(cr, py)), F64.add(cy, F64.mul(cr, px))},
        V.V2{F64.add(cx, F64.mul(cr, py)), F64.sub(cy, F64.mul(cr, px))}]
    case False{}:
      +n = F64.sqrt(F64.add(F64.mul(ux, ux), F64.mul(uy, uy)))
      +vx = F64.div(ux, n)
      +vy = F64.div(uy, n)
      [V.V2{F64.add(cx, F64.mul(cr, vx)), F64.add(cy, F64.mul(cr, vy))},
        V.V2{F64.sub(cx, F64.mul(cr, vx)), F64.sub(cy, F64.mul(cr, vy))}]

def venn_mids(+e: V.Vec2, +s: V.Vec2, +cx: F64, +cy: F64, +cr: F64) -> List<&2, V.Vec2>:
  +e1x = F64.sub(V.v2_x(e), cx)
  +e1y = F64.sub(V.v2_y(e), cy)
  +s1x = F64.sub(V.v2_x(s), cx)
  +s1y = F64.sub(V.v2_y(s), cy)
  +n1 = F64.sqrt(F64.add(F64.mul(e1x, e1x), F64.mul(e1y, e1y)))
  +n2 = F64.sqrt(F64.add(F64.mul(s1x, s1x), F64.mul(s1y, s1y)))
  +ux = F64.add(F64.div(e1x, n1), F64.div(s1x, n2))
  +uy = F64.add(F64.div(e1y, n1), F64.div(s1y, n2))
  venn_mids_d(F64.is_le(F64.add(F64.mul(ux, ux), F64.mul(uy, uy)),
    0.000000000000000001f64), ux, uy, F64.div(e1x, n1), F64.div(e1y, n1), cx, cy, cr)

def venn_pick2b(+p2: Bool, +m2: V.Vec2) -> Maybe<&2, V.Vec2>:
  match p2:
    case True{}: Some{m2}
    case False{}: None{}

def venn_pick2(+p1: Bool, +m1: V.Vec2, +m2: V.Vec2, +o: List<&2, QG>) -> Maybe<&2, V.Vec2>:
  match p1:
    case True{}: Some{m1}
    case False{}: venn_pick2b(U64.is_eq(pip_loop(o, V.v2_x(m2), V.v2_y(m2)), 1u64), m2)

def venn_pick(+m1: V.Vec2, +m2: V.Vec2, +o: List<&2, QG>) -> Maybe<&2, V.Vec2>:
  venn_pick2(U64.is_eq(pip_loop(o, V.v2_x(m1), V.v2_y(m1)), 1u64), m1, m2, o)

def venn_span_m(+m: Maybe<&2, V.Vec2>, +e: V.Vec2, +s: V.Vec2, +cx: F64, +cy: F64,
    +cr: F64, +ci: Nat) -> Maybe<&2, QG>:
  match m:
    case None{}: None{}
    case Some{+v}:
      +ccw = U64.is_eq(arc_wedge(V.v2_x(v), V.v2_y(v), V.v2_x(e), V.v2_y(e), V.v2_x(s),
        V.v2_y(s), cx, cy, True{}), 2u64)
      Some{qg_ar(V.v2_x(e), V.v2_y(e), V.v2_x(s), V.v2_y(s), cx, cy, cr, ccw, lab_newar(), ci)}

def venn_span_mt(t: List<&2, V.Vec2>, +m1: V.Vec2, +e: V.Vec2, +s: V.Vec2,
    +o: List<&2, QG>, +cx: F64, +cy: F64, +cr: F64, +ci: Nat) -> Maybe<&2, QG>:
  match t:
    case []: None{}
    case +m2 <> +t2: venn_span_m(venn_pick(m1, m2, o), e, s, cx, cy, cr, ci)

def venn_span_ms(ms: List<&2, V.Vec2>, +e: V.Vec2, +s: V.Vec2, +o: List<&2, QG>,
    +cx: F64, +cy: F64, +cr: F64, +ci: Nat) -> Maybe<&2, QG>:
  match ms:
    case []: None{}
    case +m1 <> +t: venn_span_mt(t, m1, e, s, o, cx, cy, cr, ci)

def venn_span(+ch: List<&2, QG>, +o: List<&2, QG>, +cx: F64, +cy: F64, +cr: F64,
    +ci: Nat) -> Maybe<&2, QG>:
  +e = venn_en(ch)
  +s = venn_st(ch)
  venn_span_ms(venn_mids(e, s, cx, cy, cr), e, s, o, cx, cy, cr, ci)

def venn_clear_go(xs: List<&2, V.Vec2>, +a: V.Vec2, +b: V.Vec2, +cx: F64, +cy: F64,
    +ccw: Bool, +ok: Bool) -> Bool:
  match xs:
    case []: ok
    case +h <> +t:
      +w = arc_wedge(V.v2_x(h), V.v2_y(h), V.v2_x(a), V.v2_y(a), V.v2_x(b), V.v2_y(b),
        cx, cy, ccw)
      +ep = Bool.or(v2_near(h, a), v2_near(h, b))
      venn_clear_go(t, a, b, cx, cy, ccw, Bool.and(ok, Bool.or(Bool.not(U64.is_eq(w, 2u64)), ep)))

def venn_clear(xs: List<&2, V.Vec2>, +arc: QG) -> Bool:
  venn_clear_go(xs, V.V2{qg_ax(arc), qg_ay(arc)}, V.V2{qg_bx(arc), qg_by(arc)}, qg_cx(arc),
    qg_cy(arc), qg_ccw(arc), True{})

def venn_jxs_go(chs: List<&2, List<&2, QG>>, +acc: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  match chs:
    case []: List.reverse(&2, V.Vec2, acc)
    case +h <> +t: venn_jxs_go(t, venn_st(h) <> acc)

def venn_jxs(chs: List<&2, List<&2, QG>>) -> List<&2, V.Vec2>:
  venn_jxs_go(chs, [])

def venn_tan_go(+ln: Bool, +q: QG, +s: V.Vec2) -> V.Vec2:
  match ln:
    case True{}: V.V2{F64.sub(qg_bx(q), qg_ax(q)), F64.sub(qg_by(q), qg_ay(q))}
    case False{}:
      +dx = F64.sub(V.v2_x(s), qg_cx(q))
      +dy = F64.sub(V.v2_y(s), qg_cy(q))
      Bool.pick(V.Vec2, qg_ccw(q), V.V2{F64.neg(dy), dx}, V.V2{dy, F64.neg(dx)})

def venn_tan(+q: QG, +s: V.Vec2) -> V.Vec2:
  venn_tan_go(qg_is_ln(q), q, s)

def venn_rev_go(ps: List<&2, QG>, +acc: List<&2, QG>) -> List<&2, QG>:
  match ps:
    case []: acc
    case +h <> +t: venn_rev_go(t, qg_rev(h) <> acc)

def venn_rev(ps: List<&2, QG>) -> List<&2, QG>:
  venn_rev_go(ps, [])

def venn_ch_head(ch: List<&2, QG>) -> QG:
  match ch:
    case []: qg_ln(0.0f64, 0.0f64, 0.0f64, 0.0f64, lab_orig(), 0n)
    case +h <> +t: h

def venn_orient_b(+ok: Bool, +loop: List<&2, QG>) -> List<&2, QG>:
  match ok:
    case True{}: loop
    case False{}: venn_rev(loop)

def venn_orient_a(+o: U64, +loop: List<&2, QG>, +s: V.Vec2, +arc: QG, +rx: F64,
    +ry: F64) -> List<&2, QG>:
  match o:
    case 0u64: loop
    case 1u64: venn_rev(loop)
    case _:
      +t = venn_tan(arc, s)
      venn_orient_b(U64.is_eq(ori_sign(V.v2_x(s), V.v2_y(s), F64.add(V.v2_x(s), V.v2_x(t)),
        F64.add(V.v2_y(s), V.v2_y(t)), F64.add(V.v2_x(s), rx), F64.add(V.v2_y(s), ry)), 0u64),
        loop)

def venn_orient(+ch: List<&2, QG>, +arc: QG, +side: U64, +cx: F64, +cy: F64) -> List<&2, QG>:
  +loop = List.append(&2, QG, ch, [arc])
  +s = venn_st(ch)
  +rx = F64.sub(V.v2_x(s), cx)
  +ry = F64.sub(V.v2_y(s), cy)
  +rr = Bool.pick(V.Vec2, U64.is_eq(side, 0u64), V.V2{rx, ry}, V.V2{F64.neg(rx), F64.neg(ry)})
  +t = venn_tan(venn_ch_head(ch), s)
  venn_orient_a(ori_sign(V.v2_x(s), V.v2_y(s), F64.add(V.v2_x(s), V.v2_x(t)),
    F64.add(V.v2_y(s), V.v2_y(t)), F64.add(V.v2_x(s), V.v2_x(rr)), F64.add(V.v2_y(s), V.v2_y(rr))),
    loop, s, arc, V.v2_x(rr), V.v2_y(rr))

type VLS is Data:
  VLS{ ok: Bool, qfs: List<&2, QF> }

def vls_ok(+v: VLS) -> Bool:
  VLS{ok, qfs} = v
  ok

def vls_qfs(+v: VLS) -> List<&2, QF>:
  VLS{ok, qfs} = v
  qfs

def venn_loop_cl(+clr: Bool, +ch: List<&2, QG>, +arc: QG, +side: U64, +cx: F64,
    +cy: F64) -> QF:
  match clr:
    case True{}: QF{venn_orient(ch, arc, side, cx, cy), []}
    case False{}: QF{[], []}

def venn_spans_go(chs: List<&2, List<&2, QG>>, +o: List<&2, QG>, +cx: F64, +cy: F64,
    +cr: F64, +ci: Nat, +acc: List<&2, Maybe<&2, QG>>) -> List<&2, Maybe<&2, QG>>:
  match chs:
    case []: List.reverse(&2, Maybe<&2, QG>, acc)
    case +h <> +t: venn_spans_go(t, o, cx, cy, cr, ci, venn_span(h, o, cx, cy, cr, ci) <> acc)

def venn_spans(chs: List<&2, List<&2, QG>>, +o: List<&2, QG>, +cx: F64, +cy: F64,
    +cr: F64, +ci: Nat) -> List<&2, Maybe<&2, QG>>:
  venn_spans_go(chs, o, cx, cy, cr, ci, [])

type VQ is Data:
  VQ{ ok: Bool, qf: QF }

def venn_mkqf(+sp: Maybe<&2, QG>, +h: List<&2, QG>, +s: U64, +cx: F64, +cy: F64,
    +jxs: List<&2, V.Vec2>) -> VQ:
  match sp:
    case None{}: VQ{False{}, QF{[], []}}
    case Some{+a}:
      +clr = venn_clear(jxs, a)
      VQ{clr, venn_loop_cl(clr, h, a, s, cx, cy)}

def venn_vq_ok(+r: VQ) -> Bool:
  VQ{ok, qf} = r
  ok

def venn_vq_qf(+r: VQ) -> QF:
  VQ{ok, qf} = r
  qf

def venn_loops_go(chs: List<&2, List<&2, QG>>, +ss: List<&2, U64>,
    +sps: List<&2, Maybe<&2, QG>>, +cx: F64, +cy: F64, +jxs: List<&2, V.Vec2>,
    +acc: List<&2, QF>, +ok: Bool) -> VLS:
  match chs:
    case []: VLS{ok, List.reverse(&2, QF, acc)}
    case +h <> +t:
      match ss:
        case []: VLS{False{}, []}
        case +s <> +ts:
          match sps:
            case []: VLS{False{}, []}
            case +sp <> +tps:
              +r = venn_mkqf(sp, h, s, cx, cy, jxs)
              venn_loops_go(t, ts, tps, cx, cy, jxs, venn_vq_qf(r) <> acc,
                Bool.and(ok, venn_vq_ok(r)))

def venn_loops(+chs: List<&2, List<&2, QG>>, +ss: List<&2, U64>, +o: List<&2, QG>,
    +cx: F64, +cy: F64, +cr: F64, +ci: Nat) -> VLS:
  venn_loops_go(chs, ss, venn_spans(chs, o, cx, cy, cr, ci), cx, cy, venn_jxs(chs), [], True{})

def venn_dia_at(+q: QG, +px: F64, +py: F64) -> Bool:
  Bool.and(U64.is_eq(arc_wedge(px, py, qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q), qg_cx(q),
      qg_cy(q), qg_ccw(q)), 2u64),
    Bool.and(Bool.not(Bool.and(xnear(px, qg_ax(q)), xnear(py, qg_ay(q)))),
      Bool.not(Bool.and(xnear(px, qg_bx(q)), xnear(py, qg_by(q))))))

def venn_dia_1(+q: QG, +px: F64, +py: F64) -> List<&2, QG>:
  Bool.pick(List<&2, QG>, venn_dia_at(q, px, py),
    [qg_ar(qg_ax(q), qg_ay(q), px, py, qg_cx(q), qg_cy(q), qg_cr(q), qg_ccw(q), qg_lab(q),
      qg_ref(q)),
     qg_ar(px, py, qg_bx(q), qg_by(q), qg_cx(q), qg_cy(q), qg_cr(q), qg_ccw(q), qg_lab(q),
      qg_ref(q))],
    [q])

def venn_dia_on(+q: QG, +cx: F64, +cy: F64, +cr: F64, +px: F64, +py: F64) -> List<&2, QG>:
  Bool.pick(List<&2, QG>,
    Bool.and(Bool.not(qg_is_ln(q)),
      Bool.and(F64.is_eq(qg_cx(q), cx),
        Bool.and(F64.is_eq(qg_cy(q), cy), F64.is_eq(qg_cr(q), cr)))),
    venn_dia_1(q, px, py), [q])

def venn_dia_ps(ps: List<&2, QG>, +cx: F64, +cy: F64, +cr: F64, +px: F64, +py: F64,
    +acc: List<&2, QG>) -> List<&2, QG>:
  match ps:
    case []: List.reverse(&2, QG, acc)
    case +h <> +t:
      venn_dia_ps(t, cx, cy, cr, px, py,
        List.append(&2, QG, List.reverse(&2, QG, venn_dia_on(h, cx, cy, cr, px, py)), acc))

def venn_dia_loop(ps: List<&2, QG>, +cx: F64, +cy: F64, +cr: F64) -> List<&2, QG>:
  venn_dia_ps(venn_dia_ps(ps, cx, cy, cr, F64.add(cx, cr), cy, []), cx, cy, cr,
    F64.sub(cx, cr), cy, [])

def venn_dsq_hs(hs: List<&2, List<&2, QG>>, +cx: F64, +cy: F64, +cr: F64,
    +acc: List<&2, List<&2, QG>>) -> List<&2, List<&2, QG>>:
  match hs:
    case []: List.reverse(&2, List<&2, QG>, acc)
    case +h <> +t: venn_dsq_hs(t, cx, cy, cr, venn_dia_loop(h, cx, cy, cr) <> acc)

def venn_dsq_f(+f: QF, +cx: F64, +cy: F64, +cr: F64) -> QF:
  QF{venn_dia_loop(qf_outer(f), cx, cy, cr), venn_dsq_hs(qf_holes(f), cx, cy, cr, [])}

def venn_dsq_go(fs: List<&2, QF>, +cx: F64, +cy: F64, +cr: F64, +acc: List<&2, QF>) -> List<&2, QF>:
  match fs:
    case []: List.reverse(&2, QF, acc)
    case +h <> +t: venn_dsq_go(t, cx, cy, cr, venn_dsq_f(h, cx, cy, cr) <> acc)

def venn_dsq(fs: List<&2, QF>, +cx: F64, +cy: F64, +cr: F64) -> List<&2, QF>:
  venn_dsq_go(fs, cx, cy, cr, [])

def venn_split_ok2(+ok: Bool, +qfs: List<&2, QF>, +cx: F64, +cy: F64, +cr: F64) -> QS:
  match ok:
    case True{}: qs_ok(venn_dsq(qfs, cx, cy, cr))
    case False{}: qs_fail(33u64, 0n, 0n)

def venn_split_ok(+r: VLS, +cx: F64, +cy: F64, +cr: F64) -> QS:
  match r:
    case VLS{ok, qfs}: venn_split_ok2(ok, qfs, cx, cy, cr)

def venn_split_odd(+odd: Bool, +chs: List<&2, List<&2, QG>>, +ss: List<&2, U64>,
    +o: List<&2, QG>, +cx: F64, +cy: F64, +cr: F64, +ci: Nat) -> QS:
  match odd:
    case True{}: qs_fail(33u64, 0n, 0n)
    case False{}: venn_split_ok(venn_loops(chs, ss, o, cx, cy, cr, ci), cx, cy, cr)

def venn_split_n(+n: Nat, +chs: List<&2, List<&2, QG>>, +ss: List<&2, U64>,
    +o: List<&2, QG>, +cx: F64, +cy: F64, +cr: F64, +ci: Nat) -> QS:
  match n:
    case 0n: qs_fail(99u64, 0n, 0n)
    case 1n: qs_fail(99u64, 0n, 0n)
    case _: venn_split_odd(Nat.is_eq(Nat.mod(n, 2n), 1n), chs, ss, o, cx, cy, cr, ci)

def venn_split_d2(+dup: Bool, +vs: List<&2, VS>, +o: List<&2, QG>, +cx: F64, +cy: F64,
    +cr: F64, +ci: Nat) -> QS:
  match dup:
    case True{}: qs_fail(33u64, 0n, 0n)
    case False{}:
      +chs = venn_chains(vs)
      venn_split_n(List.length(&2, List<&2, QG>, chs), chs, venn_chside(chs, cx, cy, cr, []),
        o, cx, cy, cr, ci)

def venn_split_d(+bad: Bool, +dup: Bool, +vs: List<&2, VS>, +o: List<&2, QG>, +cx: F64,
    +cy: F64, +cr: F64, +ci: Nat) -> QS:
  match bad:
    case True{}: qs_fail(33u64, 0n, 0n)
    case False{}: venn_split_d2(dup, vs, o, cx, cy, cr, ci)

def venn_split(+o: List<&2, QG>, +cx: F64, +cy: F64, +cr: F64, +ci: Nat) -> QS:
  +cl = venn_cl(venn_subs(o, cx, cy, cr), cx, cy, cr)
  venn_split_d(vcl_bad(cl), venn_dup(venn_cx(vcl_vs(cl))), vcl_vs(cl), o, cx, cy, cr, ci)

def venn_xs_ln_lot(+q: QG, +cx: F64, +cy: F64, +cr: F64, +t: F64,
    +acc: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  Bool.pick(List<&2, V.Vec2>,
    in_range(t, F64.neg(0.000000001f64), F64.add(1.0f64, 0.000000001f64)),
    seg_pt(qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q), t) <> acc, acc)

def venn_xs_ln_lo2(+n: U64, +q: QG, +cx: F64, +cy: F64, +cr: F64) -> List<&2, V.Vec2>:
  match n:
    case 2u64:
      venn_xs_ln_lot(q, cx, cy, cr, circ_seg_t(cx, cy, cr, qg_ax(q), qg_ay(q), qg_bx(q),
        qg_by(q), False{}),
        venn_xs_ln_lot(q, cx, cy, cr, circ_seg_t(cx, cy, cr, qg_ax(q), qg_ay(q), qg_bx(q),
          qg_by(q), True{}), []))
    case _: []

def venn_xs_ln_lo_dg(+dg: Bool, +q: QG, +cx: F64, +cy: F64, +cr: F64) -> List<&2, V.Vec2>:
  match dg:
    case True{}: []
    case False{}:
      venn_xs_ln_lo2(circ_seg_n(cx, cy, cr, qg_ax(q), qg_ay(q), qg_bx(q), qg_by(q)), q, cx,
        cy, cr)

def venn_xs_ln_loose(+q: QG, +cx: F64, +cy: F64, +cr: F64) -> List<&2, V.Vec2>:
  venn_xs_ln_lo_dg(Bool.and(F64.is_eq(qg_ax(q), qg_bx(q)), F64.is_eq(qg_ay(q), qg_by(q))),
    q, cx, cy, cr)

def seg_has(+px: F64, +py: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> Bool:
  +dx = F64.sub(bx, ax)
  +dy = F64.sub(by, ay)
  +l2 = F64.add(F64.mul(dx, dx), F64.mul(dy, dy))
  +t = F64.div(F64.add(F64.mul(F64.sub(px, ax), dx), F64.mul(F64.sub(py, ay), dy)), l2)
  +cx = F64.sub(F64.add(ax, F64.mul(t, dx)), px)
  +cy = F64.sub(F64.add(ay, F64.mul(t, dy)), py)
  +tol = F64.mul(0.000000001f64, F64.add(1.0f64, l2))
  Bool.and(F64.is_le(F64.add(F64.mul(cx, cx), F64.mul(cy, cy)), F64.mul(tol, tol)),
    Bool.and(F64.is_le(F64.neg(tol), t), F64.is_le(t, F64.add(1.0f64, tol))))

def arcx_on_p(+x: V.Vec2, +p: QG) -> Bool:
  Bool.pick(Bool, qg_is_ln(p), seg_has(V.v2_x(x), V.v2_y(x), qg_ax(p), qg_ay(p), qg_bx(p),
    qg_by(p)),
    U64.is_eq(arc_wedge(V.v2_x(x), V.v2_y(x), qg_ax(p), qg_ay(p), qg_bx(p), qg_by(p),
      qg_cx(p), qg_cy(p), qg_ccw(p)), 2u64))

def arcx_xs_go(xs: List<&2, V.Vec2>, +p: QG, +hit: Bool) -> Bool:
  match xs:
    case []: hit
    case +h <> +t: arcx_xs_go(t, p, Bool.or(hit, arcx_on_p(h, p)))

def arcx_xs(+xs: List<&2, V.Vec2>, +p: QG) -> Bool:
  arcx_xs_go(xs, p, False{})

def arcx_pp_la(+la: Bool, +lp: Bool, +a: QG, +p: QG) -> Bool:
  match la:
    case True{}:
      match lp:
        case True{}: False{}
        case False{}: arcx_xs(venn_xs_ln(a, qg_cx(p), qg_cy(p), qg_cr(p)), p)
    case False{}:
      match lp:
        case True{}:
          arcx_xs(venn_xs_ar_go(venn_xs_ln_loose(p, qg_cx(a), qg_cy(a), qg_cr(a)), a), p)
        case False{}:
          arcx_xs(venn_xs_ar_go(cc_xs(qg_cx(a), qg_cy(a), qg_cr(a), qg_cx(p), qg_cy(p),
            qg_cr(p)), a), p)

def arcx_pp(+a: QG, +p: QG) -> Bool:
  arcx_pp_la(qg_is_ln(a), qg_is_ln(p), a, p)

def arcx_row(+a: QG, ps: List<&2, QG>) -> Bool:
  match ps:
    case []: False{}
    case +p <> q: Bool.or(arcx_pp(a, p), arcx_row(a, q))

def arcx_go(as: List<&2, QG>, +po: List<&2, QG>) -> Bool:
  match as:
    case []: False{}
    case +a <> t: Bool.or(arcx_row(a, po), arcx_go(t, po))

