import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c06/iv.bend as I
import ../c06/sx.bend as S
import ./ivx.bend as X
import ./isect.bend as Y
import ../c11/qsect.bend as QN

type Gq is Data:
  Q_cv{ g: G.GVal, d: G.Dom }
  Q_sf{ g: G.GVal }
  Q_bad{ why: String }

def nums(xs: List<&2, S.Sx>) -> List<&2, F64>:
  match xs:
    case []: []
    case x <> t: S.some_v(S.num(S.sx_s(x))) <> nums(t)

def allfin(xs: List<&2, F64>) -> Bool:
  match xs:
    case []: True{}
    case +x <> t: Bool.and(T.is_finite(x), allfin(t))

def f(xs: List<&2, F64>, +i: Nat) -> F64:
  X.fn_(xs, i)

def pt(+xs: List<&2, F64>, +i: Nat) -> V.Point:
  V.Pt{f(xs, i), f(xs, Nat.add(i, 1n)), f(xs, Nat.add(i, 2n))}

def dr(+xs: List<&2, F64>, +i: Nat) -> V.Dir:
  V.Dr{f(xs, i), f(xs, Nat.add(i, 1n)), f(xs, Nat.add(i, 2n))}

def dm(+xs: List<&2, F64>, +i: Nat) -> G.Dom:
  G.Dom{f(xs, i), f(xs, Nat.add(i, 1n))}

def bp_of(+v: List<&2, F64>) -> G.GVal:
  G.GV_bp{G.Bp{pt(v, 0n), pt(v, 3n), pt(v, 6n), pt(v, 9n), pt(v, 12n), pt(v, 15n), pt(v, 18n), pt(v, 21n),
    pt(v, 24n), pt(v, 27n), pt(v, 30n), pt(v, 33n), pt(v, 36n), pt(v, 39n), pt(v, 42n), pt(v, 45n)}}

def gq_go(+h: String, +n: Nat, +v: List<&2, F64>) -> Gq:
  Bool.pick(Gq, Bool.and(String.eq(h, "line"), Nat.is_eq(n, 8n)), Q_cv{G.GV_ln{G.Ln{pt(v, 0n), dr(v, 3n)}}, dm(v, 6n)},
  Bool.pick(Gq, Bool.and(String.eq(h, "circle"), Nat.is_eq(n, 12n)), Q_cv{G.GV_cc{G.Cc{pt(v, 0n), dr(v, 3n), dr(v, 6n), f(v, 9n)}}, dm(v, 10n)},
  Bool.pick(Gq, Bool.and(String.eq(h, "bezier"), Nat.is_eq(n, 14n)), Q_cv{G.GV_bz{G.Bz{pt(v, 0n), pt(v, 3n), pt(v, 6n), pt(v, 9n)}}, dm(v, 12n)},
  Bool.pick(Gq, Bool.and(String.eq(h, "conic"), Nat.is_eq(n, 14n)), Q_cv{G.GV_rq{G.Rq{pt(v, 0n), pt(v, 3n), pt(v, 6n), f(v, 9n), f(v, 10n), f(v, 11n)}}, dm(v, 12n)},
  Bool.pick(Gq, Bool.and(String.eq(h, "plane"), Nat.is_eq(n, 9n)), Q_sf{G.GV_pl{G.Pl{pt(v, 0n), dr(v, 3n), dr(v, 6n)}}},
  Bool.pick(Gq, Bool.and(String.eq(h, "sphere"), Nat.is_eq(n, 4n)), Q_sf{G.GV_sp{G.Sp{pt(v, 0n), f(v, 3n)}}},
  Bool.pick(Gq, Bool.and(String.eq(h, "cylinder"), Nat.is_eq(n, 7n)), Q_sf{G.GV_cy{G.Cy{pt(v, 0n), dr(v, 3n), f(v, 6n)}}},
  Bool.pick(Gq, Bool.and(String.eq(h, "cone"), Nat.is_eq(n, 7n)), Q_sf{G.GV_co{G.Co{pt(v, 0n), dr(v, 3n), f(v, 6n)}}},
  Bool.pick(Gq, Bool.and(String.eq(h, "torus"), Nat.is_eq(n, 8n)), Q_sf{G.GV_to{G.To{pt(v, 0n), dr(v, 3n), f(v, 6n), f(v, 7n)}}},
  Bool.pick(Gq, Bool.and(String.eq(h, "bezpatch"), Nat.is_eq(n, 48n)), Q_sf{bp_of(v)},
    Q_bad{"unknown-or-malformed-geometry " ++ h}))))))))))

def nb_pts(xs: List<&2, S.Sx>) -> List<&2, V.Point>:
  match xs:
    case []: []
    case x <> t:
      +v = nums(S.sx_drop(S.sx_xs(x), 1n))
      pt(v, 0n) <> nb_pts(t)

def nb_ws(xs: List<&2, S.Sx>) -> List<&2, F64>:
  match xs:
    case []: []
    case x <> t: f(nums(S.sx_drop(S.sx_xs(x), 1n)), 3n) <> nb_ws(t)

def last_f(xs: List<&2, F64>, +d: F64) -> F64:
  match xs:
    case []: d
    case x <> t: last_f(t, x)

def nb_of(+xs: List<&2, S.Sx>) -> Gq:
  +ks = nums(S.sx_drop(S.sx_xs(S.sx_nth(xs, 1n)), 1n))
  +rest = S.sx_drop(xs, 2n)
  Q_cv{G.GV_nb{G.Nb{ks, nb_pts(rest), nb_ws(rest)}}, G.Dom{f(ks, 0n), last_f(ks, 0.0f64)}}

def gq_of(+x: S.Sx) -> Gq:
  +xs = S.sx_xs(x)
  +h = S.sx_s(S.sx_nth(xs, 0n))
  +v = nums(S.sx_drop(xs, 1n))
  Bool.pick(Gq, String.eq(h, "nurbs"), nb_of(xs), Bool.pick(Gq, allfin(v), gq_go(h, List.length(&2, F64, v), v), Q_bad{"nonfinite-or-missing-number"}))

def depth() -> Nat:
  40n

def box_of(+x: S.Sx) -> List<&2, I.I>:
  +xs = S.sx_xs(x)
  +v = nums(S.sx_drop(xs, 1n))
  Bool.pick(List<&2, I.I>, Bool.and(String.eq(S.sx_s(S.sx_nth(xs, 0n)), "box"), Bool.and(allfin(v), Nat.is_eq(List.length(&2, F64, v), 6n))),
    [I.I{f(v, 0n), f(v, 1n)}, I.I{f(v, 2n), f(v, 3n)}, I.I{f(v, 4n), f(v, 5n)}], [])

def ss_box(ok: Bool, +ga: G.GVal, +gb: G.GVal, +bx: List<&2, I.I>) -> String:
  match ok:
    case True{}: QN.sr_s(Y.inter_ss(ga, gb, bx), ga, gb)
    case False{}: "error invalid-input | intersect | why: surface-surface of planes and quadrics needs a box | fix: add (box X0 X1 Y0 Y1 Z0 Z1)"

def bad_s(+w: String) -> String:
  "error invalid-input | intersect | why: " ++ w ++ " | fix: see the geometry syntax"

def isect(+a: Gq, +b: Gq, +bx: List<&2, I.I>) -> String:
  match a:
    case Q_cv{+ga, +da}:
      match b:
        case Q_cv{gb, db}: QN.report(Y.inter_cc(ga, da, gb, db, depth()))
        case Q_sf{gb}: QN.report(Y.inter_cs(ga, da, gb, depth()))
        case Q_bad{w}: bad_s(w)
    case Q_sf{+ga}:
      match b:
        case Q_cv{gb, db}: QN.report(Y.inter_cs(gb, db, ga, depth()))
        case Q_sf{+gb}: ss_box(Bool.or(Nat.is_eq(List.length(&2, I.I, bx), 3n), Bool.or(Y.is_bp(ga), Y.is_bp(gb))), ga, gb, bx)
        case Q_bad{w}: bad_s(w)
    case Q_bad{w}: bad_s(w)

def Q_join(xs: List<&2, String>) -> String:
  match xs:
    case []: ""
    case +x <> t: Bool.pick(String, String.eq(x, "intersect"), "", x ++ " ") ++ Q_join(t)

def geom(+args: List<&2, String>) -> String:
  +xs = S.ps_xs(S.parse(Q_join(args)))
  Bool.pick(String, String.eq(S.arg_at(args, 0n), "intersect"), isect(gq_of(S.sx_nth(xs, 0n)), gq_of(S.sx_nth(xs, 1n)), box_of(S.sx_nth(xs, 2n))),
    "error invalid-input | geom | why: unknown geometry command | fix: geom intersect A B [BOX]")
