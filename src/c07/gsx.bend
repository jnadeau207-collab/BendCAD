import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c06/iv.bend as I
import ../c06/sx.bend as S
import ./ivx.bend as X
import ./xs.bend as Q
import ./par.bend as PA
import ./ss.bend as SS
import ./isect.bend as Y

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

def fs(+x: F64) -> String:
  S.f_show(x)

def si(+a: I.I) -> String:
  "[" ++ fs(I.i_lo(a)) ++ ", " ++ fs(I.i_hi(a)) ++ "]"

def sp3(+p: List<&2, I.I>) -> String:
  si(X.vn(p, 0n)) ++ "x" ++ si(X.vn(p, 1n)) ++ "x" ++ si(X.vn(p, 2n))

def sp2(p: List<&2, I.I>) -> String:
  match p:
    case []: "-"
    case a <> t: "(" ++ si(a) ++ ", " ++ si(X.vn(t, 0n)) ++ ")"

def cls_k(+c: U64) -> String:
  Bool.pick(String, U64.is_eq(c, 0u64), "interior",
    Bool.pick(String, U64.is_eq(c, 16u64), "seam",
      Bool.pick(String, U64.is_eq(U64.and(c, 1u64), 1u64), "a-start ", "") ++
      Bool.pick(String, U64.is_eq(U64.and(c, 2u64), 2u64), "a-end ", "") ++
      Bool.pick(String, U64.is_eq(U64.and(c, 4u64), 4u64), "b-start ", "") ++
      Bool.pick(String, U64.is_eq(U64.and(c, 8u64), 8u64), "b-end ", "")))

def cls_s(+c: U64) -> String:
  Bool.pick(String, U64.is_eq(U64.and(c, 32u64), 32u64), "tangent ", "") ++ cls_k(U64.and(c, 31u64))

def hit_s(h: Q.Hit) -> String:
  match h:
    case Q.H_pt{s, t, p, cls}: "point s=" ++ si(s) ++ " t=" ++ si(t) ++ " at=" ++ sp3(p) ++ " class=" ++ cls_s(cls)
    case Q.H_ov{s, t}: "overlap s=" ++ si(s) ++ " t=" ++ si(t)
    case Q.H_un{s, t, p}: "unresolved s=" ++ si(s) ++ " t=" ++ si(t) ++ " near=" ++ sp3(p)
    case Q.H_no{w}: "error unsupported-op | intersect | why: " ++ w

def hit_k(h: Q.Hit) -> U64:
  match h:
    case Q.H_pt{s, t, p, c}: 0u64
    case Q.H_ov{s, t}: 1u64
    case Q.H_un{s, t, p}: 2u64
    case Q.H_no{w}: 3u64

def hx_str(h: Y.Hx) -> String:
  match h:
    case Y.Hx_c{w}: hit_s(w)
    case Y.Hx_uv{s, u, v, p, cls}: "point s=" ++ si(s) ++ " u=" ++ si(u) ++ " v=" ++ si(v) ++ " at=" ++ sp3(p) ++ " class=" ++ cls_s(cls)
    case Y.Hx_un3{s, u, v}: "unresolved s=" ++ si(s) ++ " u=" ++ si(u) ++ " v=" ++ si(v)

def hx_k(h: Y.Hx) -> U64:
  match h:
    case Y.Hx_c{w}: hit_k(w)
    case Y.Hx_uv{s, u, v, p, cls}: 0u64
    case Y.Hx_un3{s, u, v}: 2u64

def hxs_s(hs: List<&2, Y.Hx>) -> String:
  match hs:
    case []: ""
    case h <> t: hx_str(h) ++ "\n" ++ hxs_s(t)

def cnt(hs: List<&2, Y.Hx>, +k: U64) -> Nat:
  match hs:
    case []: 0n
    case h <> t:
      +me = Bool.pick(Nat, U64.is_eq(hx_k(h), k), 1n, 0n)
      Nat.add(me, cnt(t, k))

def report(+hs: List<&2, Y.Hx>) -> String:
  hxs_s(hs) ++ "summary points=" ++ Nat.show(cnt(hs, 0u64)) ++ " overlaps=" ++ Nat.show(cnt(hs, 1u64)) ++ " unresolved=" ++ Nat.show(cnt(hs, 2u64))

def depth() -> Nat:
  40n

def coord_name(+kind: U64, +k: Nat) -> String:
  Bool.pick(String, U64.is_eq(kind, 0u64), Bool.pick(String, Nat.is_eq(k, 0n), "x", Bool.pick(String, Nat.is_eq(k, 1n), "y", "z")),
    Bool.pick(String, U64.is_eq(kind, 3u64), Bool.pick(String, Nat.is_eq(k, 0n), "u1", Bool.pick(String, Nat.is_eq(k, 1n), "v1", Bool.pick(String, Nat.is_eq(k, 2n), "u2", "v2"))),
      Bool.pick(String, Nat.is_eq(k, 0n), "u", "v")))

def ep_s(e: SS.Ep, +kind: U64) -> String:
  SS.Ep{k, c, z, i, s} = e
  "  end at " ++ coord_name(kind, k) ++ "=" ++ fs(c) ++ "\n"

def eps_s(es: List<&2, SS.Ep>, +kind: U64) -> String:
  match es:
    case []: ""
    case e <> t: ep_s(e, kind) ++ eps_s(t, kind)

def drop2(xs: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case a <> t:
      match t:
        case []: []
        case b <> u: u

def par_a(+kind: U64, +ga: G.GVal, +x: List<&2, I.I>, +p: List<&2, I.I>) -> List<&2, I.I>:
  Bool.pick(List<&2, I.I>, Bool.or(U64.is_eq(kind, 1u64), U64.is_eq(kind, 3u64)), x, PA.sf_par(ga, p))

def par_b(+kind: U64, +gb: G.GVal, +x: List<&2, I.I>, +p: List<&2, I.I>) -> List<&2, I.I>:
  Bool.pick(List<&2, I.I>, U64.is_eq(kind, 2u64), x, Bool.pick(List<&2, I.I>, U64.is_eq(kind, 3u64), drop2(x), PA.sf_par(gb, p)))

def pts_s(ps: List<&2, List<&2, I.I>>, +kind: U64, +ga: G.GVal, +gb: G.GVal) -> String:
  match ps:
    case []: ""
    case +x <> t:
      +p = Y.sample3(kind, ga, gb, x)
      "  p " ++ sp3(p) ++ " a=" ++ sp2(par_a(kind, ga, x, p)) ++ " b=" ++ sp2(par_b(kind, gb, x, p)) ++ "\n" ++ pts_s(t, kind, ga, gb)

def br_s(b: SS.Br, +kind: U64, +ga: G.GVal, +gb: G.GVal) -> String:
  SS.Br{closed, +pts, ends} = b
  "curve " ++ Bool.pick(String, closed, "closed", "open") ++ " samples=" ++ Nat.show(List.length(&2, List<&2, I.I>, pts)) ++ "\n" ++ pts_s(pts, kind, ga, gb) ++ eps_s(ends, kind)

def brs_s(bs: List<&2, SS.Br>, +kind: U64, +ga: G.GVal, +gb: G.GVal) -> String:
  match bs:
    case []: ""
    case b <> t: br_s(b, kind, ga, gb) ++ brs_s(t, kind, ga, gb)

def uns_go(n: Nat, us: List<&2, List<&2, I.I>>) -> String:
  match n:
    case 0n: ""
    case 1n+m:
      match us:
        case []: ""
        case u <> t: "unresolved box " ++ sp3(u) ++ "\n" ++ uns_go(m, t)

def hull_all(us: List<&2, List<&2, I.I>>, +acc: List<&2, I.I>) -> List<&2, I.I>:
  match us:
    case []: acc
    case u <> t: hull_all(t, X.vhull(acc, u))

def first_box(us: List<&2, List<&2, I.I>>) -> List<&2, I.I>:
  match us:
    case []: []
    case u <> t: u

def uns_s(+us: List<&2, List<&2, I.I>>) -> String:
  +n = List.length(&2, List<&2, I.I>, us)
  uns_go(32n, us) ++ Bool.pick(String, Nat.is_lt(32n, n), "unresolved more=" ++ Nat.show(Nat.sub(n, 32n)) ++ " hull=" ++ sp3(hull_all(us, first_box(us))) ++ "\n", "")

def ss_body(s: SS.Ss, +kind: U64, +ga: G.GVal, +gb: G.GVal) -> String:
  SS.Ss{ok, +brs, +un} = s
  brs_s(brs, kind, ga, gb) ++ uns_s(un) ++ "summary curves=" ++ Nat.show(List.length(&2, SS.Br, brs)) ++ " unresolved=" ++ Nat.show(List.length(&2, List<&2, I.I>, un))

def sr_go(coin: Bool, s: SS.Ss, +kind: U64, +ga: G.GVal, +gb: G.GVal) -> String:
  match coin:
    case True{}: "overlap surfaces coincide\nsummary curves=0 unresolved=0 coincident=1"
    case False{}: ss_body(s, kind, ga, gb)

def sr_s(r: Y.Sr, +ga: G.GVal, +gb: G.GVal) -> String:
  Y.Sr{ss, kind, coin} = r
  sr_go(coin, ss, kind, ga, gb)

def box_of(+x: S.Sx) -> List<&2, I.I>:
  +xs = S.sx_xs(x)
  +v = nums(S.sx_drop(xs, 1n))
  Bool.pick(List<&2, I.I>, Bool.and(String.eq(S.sx_s(S.sx_nth(xs, 0n)), "box"), Bool.and(allfin(v), Nat.is_eq(List.length(&2, F64, v), 6n))),
    [I.I{f(v, 0n), f(v, 1n)}, I.I{f(v, 2n), f(v, 3n)}, I.I{f(v, 4n), f(v, 5n)}], [])

def ss_box(ok: Bool, +ga: G.GVal, +gb: G.GVal, +bx: List<&2, I.I>) -> String:
  match ok:
    case True{}: sr_s(Y.inter_ss(ga, gb, bx), ga, gb)
    case False{}: "error invalid-input | intersect | why: surface-surface of planes and quadrics needs a box | fix: add (box X0 X1 Y0 Y1 Z0 Z1)"

def bad_s(+w: String) -> String:
  "error invalid-input | intersect | why: " ++ w ++ " | fix: see the geometry syntax"

def isect(+a: Gq, +b: Gq, +bx: List<&2, I.I>) -> String:
  match a:
    case Q_cv{+ga, +da}:
      match b:
        case Q_cv{gb, db}: report(Y.inter_cc(ga, da, gb, db, depth()))
        case Q_sf{gb}: report(Y.inter_cs(ga, da, gb, depth()))
        case Q_bad{w}: bad_s(w)
    case Q_sf{+ga}:
      match b:
        case Q_cv{gb, db}: report(Y.inter_cs(gb, db, ga, depth()))
        case Q_sf{+gb}: ss_box(Bool.or(Nat.is_eq(List.length(&2, I.I, bx), 3n), Bool.or(Y.is_bp(ga), Y.is_bp(gb))), ga, gb, bx)
        case Q_bad{w}: bad_s(w)
    case Q_bad{w}: bad_s(w)

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
  Bool.pick(String, String.eq(Q_arg(args, 0n), "intersect"), isect(gq_of(S.sx_nth(xs, 0n)), gq_of(S.sx_nth(xs, 1n)), box_of(S.sx_nth(xs, 2n))),
    "error invalid-input | geom | why: unknown geometry command | fix: geom intersect A B [BOX]")
