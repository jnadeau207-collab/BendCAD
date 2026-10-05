import Base
import ../src/c00/types.bend as T
import ../src/c01/types.bend as V
import ../src/c03/types.bend as G
import ../src/c06/surfx.bend as SX
import ../src/c06/xp.bend as X
import ../src/c06/prof.bend as F
import ../src/c06/iv.bend as I
import ../src/c06/model.bend as M
import ../src/c06/sx.bend as S
import ../src/c06/ear.bend as EA
import ../src/c06/zone.bend as Z

def ps_xs(r: S.PS) -> List<&2, S.Sx>:
  S.PS{ok, xs} = r
  xs

def part(+src: String) -> M.Part:
  S.part_of(ps_xs(S.parse(src)))

def ev(+src: String) -> List<&2, M.CE>:
  M.ev_part(part(src), [])

def r_s(r: M.NR) -> String:
  match r:
    case M.NR_ok{b, fx}: "ok " ++ M.fx_show(fx)
    case M.NR_err{k, d}:
      M.Dg{w, l, y, f} = d
      "err " ++ T.FailKind.show(k) ++ " " ++ y

def last_r(cs: List<&2, M.CE>, +d: M.NR) -> M.NR:
  match cs:
    case []: d
    case c <> t:
      M.CE{id, key, r} = c
      last_r(t, r)

def last_s(+src: String) -> String:
  r_s(last_r(ev(src), M.bad("-", "-", "empty", "-")))

def last_body(+src: String) -> M.Body:
  M.nr_body(last_r(ev(src), M.bad("-", "-", "empty", "-")))

def vol_has(+src: String, +v: F64) -> Bool:
  +m = M.body_ms(last_body(src))
  +i = M.ms_vol(m)
  Bool.and(F64.is_le(I.i_lo(i), v), F64.is_le(v, I.i_hi(i)))

def rr() -> String:
  "(path 5 0 (line 95 0) (arc 95 5 5 100 5 ccw) (line 100 55) (arc 95 55 5 95 60 ccw) (line 5 60) (arc 5 55 5 0 55 ccw) (line 0 5) (arc 5 5 5 5 0 ccw))"

def plate() -> String:
  "(param 1 W 100 100 100) (param 2 H 60 60 60) (param 3 T 8 8 8) (node 1 (box W H T) (intent create 6 0 1 0))"

def holes2() -> String:
  plate() ++ " (node 2 (holes 1 (face 1 0 top) through (hole 10 10 3) (hole (- W 10) 10 3)) (intent remove 2 2 1 2))"

def boss() -> String:
  holes2() ++ " (node 3 (pad 2 (face 1 0 top) 15 (region (circle (/ W 2) 30 12))) (intent add 2 1 1 2))"

def bore() -> String:
  boss() ++ " (node 4 (holes 3 (face 3 0 top) through (hole (/ W 2) 30 5)) (intent remove 1 2 1 3))"

def sq_ea(+w: F64) -> List<&2, EA.QP>:
  [EA.QP{0n, 0.0f64, 0.0f64}, EA.QP{1n, w, 0.0f64}, EA.QP{2n, w, w}, EA.QP{3n, 0.0f64, w}]

def hole_ea(+cx: F64, +cy: F64, +id: Nat) -> List<&2, EA.QP>:
  [EA.QP{id, F64.add(cx, 2.0f64), cy}, EA.QP{Nat.add(id, 1n), cx, F64.sub(cy, 2.0f64)},
    EA.QP{Nat.add(id, 2n), F64.sub(cx, 2.0f64), cy}, EA.QP{Nat.add(id, 3n), cx, F64.add(cy, 2.0f64)}]

def holes_ea(n: Nat, +i: Nat, +w: Nat) -> List<&2, List<&2, EA.QP>>:
  match n:
    case 0n: []
    case 1n+m:
      hole_ea(F64.add(10.0f64, F64.mul(10.0f64, U64.to_f64(U64.from_nat(Nat.mod(i, w))))),
        F64.add(10.0f64, F64.mul(10.0f64, U64.to_f64(U64.from_nat(Nat.div(i, w))))), Nat.add(4n, Nat.mul(4n, i))) <>
        holes_ea(m, Nat.add(i, 1n), w)

def keys_eq(a: List<&2, M.CE>, b: List<&2, M.CE>) -> List<&2, Bool>:
  match a:
    case []: []
    case x <> t:
      match b:
        case []: []
        case y <> u: M.keq(M.ce_key(x), M.ce_key(y)) <> keys_eq(t, u)

law ev_box:
  {String.eq(last_s(plate()), "ok material=create faces_created=6 faces_modified=0 solids=1 through_holes=0") == True{} : Bool}

def ev_box():
  {==}

law ev_holes:
  {String.eq(last_s(holes2()), "ok material=remove faces_created=2 faces_modified=2 solids=1 through_holes=2") == True{} : Bool}

def ev_holes():
  {==}

law ev_pad:
  {String.eq(last_s(boss()), "ok material=add faces_created=2 faces_modified=1 solids=1 through_holes=2") == True{} : Bool}

def ev_pad():
  {==}

law ev_bore:
  {String.eq(last_s(bore()), "ok material=remove faces_created=1 faces_modified=2 solids=1 through_holes=3") == True{} : Bool}

def ev_bore():
  {==}

law ev_intent_mismatch:
  {String.eq(last_s(plate() ++ " (node 2 (holes 1 (face 1 0 top) through (hole 10 10 3)) (intent remove 1 2 1 0))"),
    "err invalid-input declared material=remove faces_created=1 faces_modified=2 solids=1 through_holes=0 but measured material=remove faces_created=1 faces_modified=2 solids=1 through_holes=1") == True{} : Bool}

def ev_intent_mismatch():
  {==}

law ev_pocket_blind:
  {String.eq(last_s(plate() ++ " (node 2 (pocket 1 (face 1 0 top) 3 (region (circle 50 30 10))) (intent remove 2 1 1 0))"),
    "ok material=remove faces_created=2 faces_modified=1 solids=1 through_holes=0") == True{} : Bool}

def ev_pocket_blind():
  {==}

law ev_pocket_too_deep:
  {String.eq(last_s(plate() ++ " (node 2 (pocket 1 (face 1 0 top) 8 (region (circle 50 30 10))) (intent remove any any 1 0))"),
    "err invalid-input depth-reaches-opposite-face") == True{} : Bool}

def ev_pocket_too_deep():
  {==}

law ev_foot_outside:
  {String.eq(last_s(plate() ++ " (node 2 (holes 1 (face 1 0 top) through (hole 99 30 3)) (intent remove any any 1 any))"),
    "err invalid-input curves-cross-or-touch") == True{} : Bool}

def ev_foot_outside():
  {==}

law ev_foot_on_feature:
  {String.eq(last_s(holes2() ++ " (node 3 (pad 2 (face 1 0 top) 5 (region (circle 10 10 6))) (intent add any any 1 any))"),
    "err invalid-input footprint-contains-or-meets-existing-feature") == True{} : Bool}

def ev_foot_on_feature():
  {==}

law ev_face_missing:
  {String.eq(last_s(plate() ++ " (node 2 (holes 1 (face 9 0 top) through (hole 50 30 3)) (intent remove any any 1 any))"),
    "err invalid-input face-not-found") == True{} : Bool}

def ev_face_missing():
  {==}

law ev_dup_ids:
  {String.eq(last_s(plate() ++ " (node 1 (box 5 5 5) (intent create 6 0 1 0))"),
    "err invalid-input duplicate-node-or-parameter-id") == True{} : Bool}

def ev_dup_ids():
  {==}

law ev_move_same:
  {String.eq(last_s(plate() ++ " (node 2 (move 1 10 0 0 1) (intent same 0 0 1 0))"),
    "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0") == True{} : Bool}

def ev_move_same():
  {==}

law ev_two_solids:
  {String.eq(last_s("(node 1 (prism 0 5 (region (circle 0 0 2)) (region (circle 10 0 2))) (intent create 6 0 2 0))"),
    "ok material=create faces_created=6 faces_modified=0 solids=2 through_holes=0") == True{} : Bool}

def ev_two_solids():
  {==}

law ev_sphere:
  {String.eq(last_s("(node 1 (sphere 10) (intent create 2 0 1 0))"),
    "ok material=create faces_created=2 faces_modified=0 solids=1 through_holes=0") == True{} : Bool}

def ev_sphere():
  {==}

law ev_cone:
  {String.eq(last_s("(node 1 (cone 10 20) (intent create 4 0 1 0))"),
    "ok material=create faces_created=4 faces_modified=0 solids=1 through_holes=0") == True{} : Bool}

def ev_cone():
  {==}

law ev_torus:
  {String.eq(last_s("(node 1 (torus 30 10) (intent create 8 0 1 1))"),
    "ok material=create faces_created=8 faces_modified=0 solids=1 through_holes=1") == True{} : Bool}

def ev_torus():
  {==}

law ev_cavity:
  {String.eq(last_s("(node 1 (revolve (region (path 0 0 (line 40 0) (line 40 30) (line 0 30)) (circle 20 15 5))) (intent create 14 0 1 1))"),
    "ok material=create faces_created=14 faces_modified=0 solids=1 through_holes=1") == True{} : Bool}

def ev_cavity():
  {==}

law ev_feature_on_revolve:
  {String.eq(last_s("(node 1 (sphere 10) (intent create 2 0 1 0)) (node 2 (holes 1 (face 1 0 top) through (hole 0 0 1)) (intent remove any any 1 any))"),
    "err unsupported-op features-need-an-extruded-body") == True{} : Bool}

def ev_feature_on_revolve():
  {==}

law ms_box_vol:
  {vol_has(plate(), 48000.0f64) == True{} : Bool}

def ms_box_vol():
  {==}

law ms_holes_vol:
  {vol_has(holes2(), 47547.61065788307f64) == True{} : Bool}

def ms_holes_vol():
  {==}

law ms_sphere_vol:
  {vol_has("(node 1 (sphere 10) (intent create 2 0 1 0))", 4188.790204786391f64) == True{} : Bool}

def ms_sphere_vol():
  {==}

law ms_torus_vol:
  {vol_has("(node 1 (torus 30 10) (intent create 8 0 1 1))", 59217.62640653615f64) == True{} : Bool}

def ms_torus_vol():
  {==}

law ms_rounded_vol:
  {vol_has("(node 1 (prism 0 6 (region " ++ rr() ++ ")) (intent create 10 0 1 0))", 35871.23889803847f64) == True{} : Bool}

def ms_rounded_vol():
  {==}

law cache_partial:
  {keys_eq(ev(bore()), ev(holes2() ++ " (node 3 (pad 2 (face 1 0 top) 15 (region (circle (/ W 2) 30 12))) (intent add 2 1 1 2)) (node 4 (holes 3 (face 3 0 top) through (hole (/ W 2) 30 6)) (intent remove 1 2 1 3))"))
    == [True{}, True{}, True{}, False{}] : List<&2, Bool>}

def cache_partial():
  {==}

law ear_holes16:
  {List.length(&2, EA.Tri, EA.tri_poly(sq_ea(100.0f64), holes_ea(16n, 0n, 4n))) == 98n : Nat}

def ear_holes16():
  {==}
