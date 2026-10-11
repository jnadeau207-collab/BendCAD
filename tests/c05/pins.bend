import Base

import ../../src/c00/types.bend as T

import ../../src/c05/exact.bend as X

import ../../src/c05/arrange.bend as A

import ../../src/c05/solve.bend as S

import ../../src/base/par.bend as P

import ../../src/base/ex.bend as E

def bits_eq(xs: List<&2, F64>, ys: List<&2, U64>) -> Bool:
  match xs:
    case Nil{}:
      match ys:
        case Nil{}: True{}
        case _: False{}
    case x <> xt:
      match ys:
        case Nil{}: False{}
        case y <> yt: Bool.and(U64.is_eq(F64.bits(x), y), bits_eq(xt, yt))

def ids_eq(xs: List<&2, U64>, ys: List<&2, U64>) -> Bool:
  match xs:
    case Nil{}:
      match ys:
        case Nil{}: True{}
        case _: False{}
    case x <> xt:
      match ys:
        case Nil{}: False{}
        case y <> yt: Bool.and(U64.is_eq(x, y), ids_eq(xt, yt))

def ok_bits(s: S.Sol, +dof: Nat, rs: List<&2, U64>, ys: List<&2, U64>) -> Bool:
  match s:
    case S.Sv_ok{ps, d, red}: Bool.and(Bool.and(Nat.is_eq(d, dof), ids_eq(red, rs)), bits_eq(ps, ys))
    case _: False{}

def sol_ok(s: S.Sol) -> Bool:
  match s:
    case S.Sv_ok{ps, dof, red}: True{}
    case _: False{}

def dof_red(s: S.Sol, +dof: Nat, rs: List<&2, U64>) -> Bool:
  match s:
    case S.Sv_ok{ps, d, red}: Bool.and(Nat.is_eq(d, dof), ids_eq(red, rs))
    case _: False{}

def ok_arrange_square__got() -> String:
  A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 4.0f64, 0.0f64}, A.Seg{2u64, 4.0f64, 0.0f64, 4.0f64, 4.0f64}, A.Seg{3u64, 4.0f64, 4.0f64, 0.0f64, 4.0f64}, A.Seg{4u64, 0.0f64, 4.0f64, 0.0f64, 0.0f64}], 100n))

def ok_arrange_square__want() -> String:
  "v=4 e=4 c=1 R { e1.0[1] e1.1[2] e2.1[3] e3.1[4] } D"

def ok_arrange_cross_dangles__got() -> String:
  A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 2.0f64, 2.0f64}, A.Seg{2u64, 0.0f64, 2.0f64, 2.0f64, 0.0f64}], 10n))

def ok_arrange_cross_dangles__want() -> String:
  "v=5 e=4 c=1 R D e1.0-x1.2 e2.0-x1.2 x1.2-e2.1 x1.2-e1.1"

def neg_arrange_degenerate__got() -> String:
  A.ares_show(A.arrange([A.Seg{1u64, 1.0f64, 1.0f64, 1.0f64, 1.0f64}], 10n))

def neg_arrange_degenerate__want() -> String:
  "err invalid-input"

def neg_arrange_budget__got() -> String:
  A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 1.0f64, 0.0f64}, A.Seg{2u64, 1.0f64, 0.0f64, 1.0f64, 1.0f64}], 1n))

def neg_arrange_budget__want() -> String:
  "err resource-exhausted"

def neg_arrange_underflow__got() -> String:
  A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, F64{2220274616293654528u64}, F64{2220274616293654528u64}}, A.Seg{2u64, 0.0f64, F64{2220274616293654528u64}, F64{2220274616293654528u64}, 0.0f64}], 10n))

def neg_arrange_underflow__want() -> String:
  "err numerical-uncertainty"

def neg_solve_bad_index__got() -> String:
  S.sol_show(S.solve([0.0f64, 0.0f64], [True{}, True{}], [S.K_fix{1u64, 2n, 0.0f64}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 10n))

def neg_solve_bad_index__want() -> String:
  "err invalid-input"

def neg_solve_budget_not_conflict__got() -> String:
  S.sol_show(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, True{}, True{}], [S.K_dist{5u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 20.0f64}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 0n))

def neg_solve_budget_not_conflict__want() -> String:
  "err nonconvergence"

def neg_solve_grounded_conflict__got() -> String:
  S.sol_show(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, False{}, False{}], [S.K_dist{5u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 20.0f64}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 1n))

def neg_solve_grounded_conflict__want() -> String:
  "conflict [5]"

def ok_solve_linear__got() -> Bool:
  ok_bits(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, True{}, True{}], [S.K_horiz{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}}, S.K_fix{2u64, 2n, 5.0f64}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 10n), 0n, [], [0u64, 0u64, 4617315517961601024u64, 4207248258336030720u64])

def ok_solve_linear__want() -> Bool:
  True{}

def ok_solve_redundant_named__got() -> Bool:
  ok_bits(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, True{}, True{}], [S.K_dist{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 10.0f64}, S.K_dist{2u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 10.0f64}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 100n), 1n, [2u64], [0u64, 0u64, 4621363944573119361u64, 4616052692831493341u64])

def ok_solve_redundant_named__want() -> Bool:
  True{}

def ok_solve_tangent_circles__got() -> Bool:
  ok_bits(S.solve([0.0f64, 0.0f64, 2.0f64, 9.0f64, 0.0f64, 3.0f64], [False{}, False{}, False{}, True{}, False{}, False{}], [S.K_tan_cc{1u64, S.Pt{0n, 1n}, 2n, S.Pt{3n, 4n}, 5n}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 100n), 0n, [], [0u64, 0u64, 4611686018427387904u64, 4617315517961601024u64, 0u64, 4613937818241073152u64])

def ok_solve_tangent_circles__want() -> Bool:
  True{}

def neg_solve_conflict_named__got() -> String:
  S.sol_show(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, True{}, True{}], [S.K_dist{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 5.0f64}, S.K_dist{2u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 6.0f64}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 100n))

def neg_solve_conflict_named__want() -> String:
  "conflict [1,2]"

def ok_arrange_antenna_dangles__got() -> String:
  A.ares_show(A.arrange([A.Seg{9u64, 2.0f64, 0.0f64, 2.0f64, 1.0f64}, A.Seg{1u64, 0.0f64, 0.0f64, 4.0f64, 0.0f64}, A.Seg{2u64, 4.0f64, 0.0f64, 4.0f64, 4.0f64}, A.Seg{3u64, 4.0f64, 4.0f64, 0.0f64, 4.0f64}, A.Seg{4u64, 0.0f64, 4.0f64, 0.0f64, 0.0f64}], 100n))

def ok_arrange_antenna_dangles__want() -> String:
  "v=6 e=6 c=1 R { e1.0[1] e9.0[1] e1.1[2] e2.1[3] e3.1[4] } D e9.0-e9.1"

def ok_arrange_overlap_lineage__got() -> String:
  A.ares_show(A.arrange([A.Seg{9u64, 1.0f64, 0.0f64, 3.0f64, 0.0f64}, A.Seg{1u64, 0.0f64, 0.0f64, 4.0f64, 0.0f64}, A.Seg{2u64, 4.0f64, 0.0f64, 4.0f64, 4.0f64}, A.Seg{3u64, 4.0f64, 4.0f64, 0.0f64, 4.0f64}, A.Seg{4u64, 0.0f64, 4.0f64, 0.0f64, 0.0f64}], 100n))

def ok_arrange_overlap_lineage__want() -> String:
  "v=6 e=6 c=1 R { e1.0[1] e9.0[1,9] e9.1[1] e1.1[2] e2.1[3] e3.1[4] } D"

def ok_arrange_hole__got() -> String:
  A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 10.0f64, 0.0f64}, A.Seg{2u64, 10.0f64, 0.0f64, 10.0f64, 10.0f64}, A.Seg{3u64, 10.0f64, 10.0f64, 0.0f64, 10.0f64}, A.Seg{4u64, 0.0f64, 10.0f64, 0.0f64, 0.0f64}, A.Seg{11u64, 2.0f64, 2.0f64, 8.0f64, 2.0f64}, A.Seg{12u64, 8.0f64, 2.0f64, 8.0f64, 8.0f64}, A.Seg{13u64, 8.0f64, 8.0f64, 2.0f64, 8.0f64}, A.Seg{14u64, 2.0f64, 8.0f64, 2.0f64, 2.0f64}], 100n))

def ok_arrange_hole__want() -> String:
  "v=8 e=8 c=2 R { e1.0[1] e1.1[2] e2.1[3] e3.1[4] | e11.0[14] e13.1[13] e12.1[12] e11.1[11] } { e11.0[11] e11.1[12] e12.1[13] e13.1[14] } D"

def ok_arrange_pinch__got() -> String:
  A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 4.0f64, 0.0f64}, A.Seg{2u64, 4.0f64, 0.0f64, 4.0f64, 4.0f64}, A.Seg{3u64, 4.0f64, 4.0f64, 0.0f64, 4.0f64}, A.Seg{4u64, 0.0f64, 4.0f64, 0.0f64, 0.0f64}, A.Seg{11u64, 2.0f64, 0.0f64, 3.0f64, 2.0f64}, A.Seg{12u64, 3.0f64, 2.0f64, 1.0f64, 2.0f64}, A.Seg{13u64, 1.0f64, 2.0f64, 2.0f64, 0.0f64}], 100n))

def ok_arrange_pinch__want() -> String:
  "v=7 e=8 c=1 R { e1.0[1] e11.0[1] e1.1[2] e2.1[3] e3.1[4] | e12.1[12] e11.1[11] e11.0[13] } { e12.1[13] e11.0[11] e11.1[12] } D"

def ok_arrange_islands__got() -> String:
  A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 2.0f64, 0.0f64}, A.Seg{2u64, 2.0f64, 0.0f64, 2.0f64, 2.0f64}, A.Seg{3u64, 2.0f64, 2.0f64, 0.0f64, 2.0f64}, A.Seg{4u64, 0.0f64, 2.0f64, 0.0f64, 0.0f64}, A.Seg{11u64, 5.0f64, 0.0f64, 7.0f64, 0.0f64}, A.Seg{12u64, 7.0f64, 0.0f64, 7.0f64, 2.0f64}, A.Seg{13u64, 7.0f64, 2.0f64, 5.0f64, 2.0f64}, A.Seg{14u64, 5.0f64, 2.0f64, 5.0f64, 0.0f64}], 100n))

def ok_arrange_islands__want() -> String:
  "v=8 e=8 c=2 R { e1.0[1] e1.1[2] e2.1[3] e3.1[4] } { e11.0[11] e11.1[12] e12.1[13] e13.1[14] } D"

def neg_angle_is_directed__got() -> String:
  S.sol_show(S.solve([0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 5.0f64, F64.neg(10.0f64), 5.0f64], [False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}], [S.K_angle{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 1.0f64, 0.0f64}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 10n))

def neg_angle_is_directed__want() -> String:
  "conflict [1]"

def neg_angle90_is_directed__got() -> String:
  S.sol_show(S.solve([0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 5.0f64, 0.0f64, F64.neg(5.0f64)], [False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}], [S.K_angle{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 0.0f64, 1.0f64}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 10n))

def neg_angle90_is_directed__want() -> String:
  "conflict [1]"

def ok_parallel_is_undirected__got() -> Bool:
  ok_bits(S.solve([0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 5.0f64, F64.neg(10.0f64), 5.0f64], [False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}], [S.K_par{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, S.Pt{4n, 5n}, S.Pt{6n, 7n}}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 10n), 0n, [1u64], [0u64, 0u64, 4621819117588971520u64, 0u64, 0u64, 4617315517961601024u64, 13845191154443747328u64, 4617315517961601024u64])

def ok_parallel_is_undirected__want() -> Bool:
  True{}

def ok_angle_from_flipped_side__got() -> Bool:
  ok_bits(S.solve([0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 0.0f64, F64.neg(9.4f64), F64.neg(3.4f64)], [False{}, False{}, False{}, False{}, False{}, False{}, True{}, True{}], [S.K_angle{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 0.8660254037844387f64, 0.5f64}, S.K_dist{2u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 10.0f64}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 100n), 0n, [], [0u64, 0u64, 4621819117588971520u64, 0u64, 0u64, 0u64, 4621064907661979627u64, 4617315517961601023u64])

def ok_angle_from_flipped_side__want() -> Bool:
  True{}

def neg_axes_never_collapse__got() -> String:
  S.sol_show(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, True{}, True{}], [S.K_horiz{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}}, S.K_vert{2u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 30n))

def neg_axes_never_collapse__want() -> String:
  "conflict [1,2]"

def neg_coincidence_collapse_not_ok__got() -> Bool:
  sol_ok(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, True{}, True{}], [S.K_coinc{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}}, S.K_horiz{2u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 30n))

def neg_coincidence_collapse_not_ok__want() -> Bool:
  False{}

def neg_negative_radius_not_ok__got() -> Bool:
  sol_ok(S.solve([0.0f64, 0.0f64, 10.0f64, 0.0f64, 4.0f64, 3.0f64, 3.0f64], [False{}, False{}, False{}, False{}, False{}, True{}, True{}], [S.K_tan_lc{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, S.Pt{4n, 5n}, 6n}, S.K_vdist{2u64, S.Pt{0n, 1n}, S.Pt{4n, 5n}, F64.neg(2.0f64)}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 30n))

def neg_negative_radius_not_ok__want() -> Bool:
  False{}

def neg_nonpositive_radius_start__got() -> String:
  S.sol_show(S.solve([0.0f64, 0.0f64, 3.0f64, 0.0f64, F64.neg(1.0f64)], [True{}, True{}, True{}, True{}, True{}], [S.K_on_circ{1u64, S.Pt{2n, 3n}, S.Pt{0n, 1n}, 4n}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 10n))

def neg_nonpositive_radius_start__want() -> String:
  "err invalid-input"

def ok_solve_zero_pivot__got() -> Bool:
  dof_red(S.solve([5.1787109375f64, 1.302734375f64, 10.19921875f64, 1.28515625f64, 1.8203125f64, 1.01953125f64, 1.5400390625f64, F64.neg(3.0869140625f64)], [False{}, False{}, True{}, True{}, True{}, True{}, True{}, True{}], [S.K_hdist{3u64, S.Pt{6n, 7n}, S.Pt{0n, 1n}, 3.6572265625f64}, S.K_perp{6u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, S.Pt{0n, 1n}, S.Pt{2n, 3n}}, S.K_dist{11u64, S.Pt{4n, 5n}, S.Pt{2n, 3n}, 8.720686658469603f64}, S.K_dist{12u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 4.318359375f64}, S.K_vert{25u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}}, S.K_dist{27u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 4.318359375f64}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 200n), 1n, [27u64])

def ok_solve_zero_pivot__want() -> Bool:
  True{}

def ok_solve_clusters_merge__got() -> Bool:
  dof_red(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64, 20.0f64, 0.0f64, 24.0f64, 2.0f64], [False{}, False{}, True{}, True{}, False{}, False{}, True{}, True{}], [S.K_dist{10u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 5.0f64}, S.K_dist{11u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 10.0f64}, S.K_dist{12u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 5.0f64}, S.K_dist{13u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 10.0f64}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 100n), 2n, [12u64, 13u64])

def ok_solve_clusters_merge__want() -> Bool:
  True{}

def neg_solve_conflict_localized__got() -> String:
  S.sol_show(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64, 20.0f64, 0.0f64, 24.0f64, 2.0f64], [False{}, False{}, True{}, True{}, False{}, False{}, True{}, True{}], [S.K_dist{20u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 10.0f64}, S.K_dist{21u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 5.0f64}, S.K_dist{22u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 6.0f64}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 100n))

def neg_solve_conflict_localized__want() -> String:
  "conflict [21,22]"

def ok_arrange_kiss__got() -> String:
  A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 2.0f64, 0.0f64}, A.Seg{2u64, 2.0f64, 0.0f64, 2.0f64, 2.0f64}, A.Seg{3u64, 2.0f64, 2.0f64, 0.0f64, 2.0f64}, A.Seg{4u64, 0.0f64, 2.0f64, 0.0f64, 0.0f64}, A.Seg{5u64, 2.0f64, 2.0f64, 4.0f64, 2.0f64}, A.Seg{6u64, 4.0f64, 2.0f64, 4.0f64, 4.0f64}, A.Seg{7u64, 4.0f64, 4.0f64, 2.0f64, 4.0f64}, A.Seg{8u64, 2.0f64, 4.0f64, 2.0f64, 2.0f64}], 100n))

def ok_arrange_kiss__want() -> String:
  "v=7 e=8 c=1 R { e1.0[1] e1.1[2] e2.1[3] e3.1[4] } { e2.1[5] e5.1[6] e6.1[7] e7.1[8] } D"

def ok_arrange_dup_segment__got() -> String:
  A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 2.0f64, 0.0f64}, A.Seg{2u64, 2.0f64, 0.0f64, 2.0f64, 2.0f64}, A.Seg{3u64, 2.0f64, 2.0f64, 0.0f64, 2.0f64}, A.Seg{4u64, 0.0f64, 2.0f64, 0.0f64, 0.0f64}, A.Seg{5u64, 0.0f64, 0.0f64, 2.0f64, 0.0f64}], 100n))

def ok_arrange_dup_segment__want() -> String:
  "v=4 e=4 c=1 R { e1.0[1,5] e1.1[2] e2.1[3] e3.1[4] } D"

def ok_arrange_three_petals__got() -> String:
  A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 4.0f64, 0.0f64}, A.Seg{2u64, 4.0f64, 0.0f64, 4.0f64, 1.0f64}, A.Seg{3u64, 4.0f64, 1.0f64, 0.0f64, 0.0f64}, A.Seg{4u64, 0.0f64, 0.0f64, F64.neg(1.0f64), 4.0f64}, A.Seg{5u64, F64.neg(1.0f64), 4.0f64, F64.neg(2.0f64), 4.0f64}, A.Seg{6u64, F64.neg(2.0f64), 4.0f64, 0.0f64, 0.0f64}, A.Seg{7u64, 0.0f64, 0.0f64, F64.neg(3.0f64), F64.neg(3.0f64)}, A.Seg{8u64, F64.neg(3.0f64), F64.neg(3.0f64), F64.neg(2.0f64), F64.neg(4.0f64)}, A.Seg{9u64, F64.neg(2.0f64), F64.neg(4.0f64), 0.0f64, 0.0f64}], 100n))

def ok_arrange_three_petals__want() -> String:
  "v=7 e=9 c=1 R { e7.1[8] e8.1[9] e1.0[7] } { e5.1[6] e1.0[4] e4.1[5] } { e1.0[1] e1.1[2] e2.1[3] } D"
