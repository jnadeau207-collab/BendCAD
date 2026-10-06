import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c06/iv.bend as I
import ../c06/sx.bend as S
import ./ivx.bend as X
import ./xs.bend as Q

type Gq is Data:
  Q_cv{ g: G.GVal, d: G.Dom }
  Q_sf{ g: G.GVal }
  Q_bx{ b: List<&2, I.I> }
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
  Bool.pick(Gq, Bool.and(String.eq(h, "box"), Nat.is_eq(n, 6n)), Q_bx{[I.I{f(v, 0n), f(v, 1n)}, I.I{f(v, 2n), f(v, 3n)}, I.I{f(v, 4n), f(v, 5n)}]},
    Q_bad{"unknown-or-malformed-geometry " ++ h}))))))))))

def gq_of(+x: S.Sx) -> Gq:
  +xs = S.sx_xs(x)
  +v = nums(S.sx_drop(xs, 1n))
  Bool.pick(Gq, allfin(v), gq_go(S.sx_s(S.sx_nth(xs, 0n)), List.length(&2, F64, v), v), Q_bad{"nonfinite-or-missing-number"})

def fs(+x: F64) -> String:
  S.f_show(x)

def si(+a: I.I) -> String:
  "[" ++ fs(I.i_lo(a)) ++ ", " ++ fs(I.i_hi(a)) ++ "]"

def sp3(+p: List<&2, I.I>) -> String:
  si(X.vn(p, 0n)) ++ "x" ++ si(X.vn(p, 1n)) ++ "x" ++ si(X.vn(p, 2n))

def cls_s(+c: U64) -> String:
  Bool.pick(String, U64.is_eq(c, 0u64), "interior",
    Bool.pick(String, U64.is_eq(c, 16u64), "seam",
      Bool.pick(String, U64.is_eq(U64.and(c, 1u64), 1u64), "a-start ", "") ++
      Bool.pick(String, U64.is_eq(U64.and(c, 2u64), 2u64), "a-end ", "") ++
      Bool.pick(String, U64.is_eq(U64.and(c, 4u64), 4u64), "b-start ", "") ++
      Bool.pick(String, U64.is_eq(U64.and(c, 8u64), 8u64), "b-end ", "")))

def hit_s(h: Q.Hit) -> String:
  match h:
    case Q.H_pt{s, t, p, cls}: "point s=" ++ si(s) ++ " t=" ++ si(t) ++ " at=" ++ sp3(p) ++ " class=" ++ cls_s(cls)
    case Q.H_ov{s, t}: "overlap s=" ++ si(s) ++ " t=" ++ si(t)
    case Q.H_un{s, t, p}: "unresolved s=" ++ si(s) ++ " t=" ++ si(t) ++ " near=" ++ sp3(p)
    case Q.H_no{w}: "error unsupported-op | intersect | why: " ++ w

def hits_s(hs: List<&2, Q.Hit>) -> String:
  match hs:
    case []: ""
    case h <> t: hit_s(h) ++ "\n" ++ hits_s(t)

def hit_k(h: Q.Hit) -> U64:
  match h:
    case Q.H_pt{s, t, p, c}: 0u64
    case Q.H_ov{s, t}: 1u64
    case Q.H_un{s, t, p}: 2u64
    case Q.H_no{w}: 3u64

def cnt(hs: List<&2, Q.Hit>, +k: U64) -> Nat:
  match hs:
    case []: 0n
    case h <> t:
      +me = Bool.pick(Nat, U64.is_eq(hit_k(h), k), 1n, 0n)
      Nat.add(me, cnt(t, k))

def report(+hs: List<&2, Q.Hit>) -> String:
  hits_s(hs) ++ "summary points=" ++ Nat.show(cnt(hs, 0u64)) ++ " overlaps=" ++ Nat.show(cnt(hs, 1u64)) ++ " unresolved=" ++ Nat.show(cnt(hs, 2u64))

def depth() -> Nat:
  40n

def isect(a: Gq, +b: Gq) -> String:
  match a:
    case Q_cv{+ga, +da}:
      match b:
        case Q_cv{gb, db}: report(Q.inter_cc(ga, da, gb, db, depth()))
        case Q_sf{gb}: report(Q.inter_cs(ga, da, gb, depth()))
        case Q_bx{x}: "error invalid-input | intersect | why: second argument must be a curve or surface | fix: (line ...), (circle ...), (plane ...) ..."
        case Q_bad{w}: "error invalid-input | intersect | why: " ++ w ++ " | fix: see the geometry syntax"
    case Q_sf{ga}:
      match b:
        case Q_cv{gb, db}: report(Q.inter_cs(gb, db, ga, depth()))
        case _: "error unsupported-op | intersect | why: surface-surface needs a box | fix: add (box X0 X1 Y0 Y1 Z0 Z1)"
    case Q_bx{x}: "error invalid-input | intersect | why: first argument must be a curve or surface | fix: see the geometry syntax"
    case Q_bad{w}: "error invalid-input | intersect | why: " ++ w ++ " | fix: see the geometry syntax"

def ps_xs(r: S.PS) -> List<&2, S.Sx>:
  S.PS{ok, xs} = r
  xs

def Q_arg(xs: List<&2, String>, +i: Nat) -> String:
  match xs:
    case []: ""
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: Q_arg(t, j)

def Q_join(xs: List<&2, String>) -> String:
  match xs:
    case []: ""
    case +x <> t: Bool.pick(String, String.eq(x, "intersect"), "", x ++ " ") ++ Q_join(t)

def geom(+args: List<&2, String>) -> String:
  +xs = ps_xs(S.parse(Q_join(args)))
  Bool.pick(String, String.eq(Q_arg(args, 0n), "intersect"), isect(gq_of(S.sx_nth(xs, 0n)), gq_of(S.sx_nth(xs, 1n))),
    "error invalid-input | geom | why: unknown geometry command | fix: geom intersect A B [BOX]")
