import Base
import ../src/c00/types.bend as T
import ../src/c05/exact.bend as X
import ../src/c05/arrange.bend as A
import ../src/c05/solve.bend as S
import ../src/c05/par.bend as P

law sgn_neg_invol:
  for s: X.Sgn
  {X.sgn_neg(X.sgn_neg(s)) == s : X.Sgn}

def sgn_neg_invol(s):
  match s:
    case X.Sn{}: {==}
    case X.Sz{}: {==}
    case X.Sp{}: {==}
    case X.Su{}: {==}

law sgn_is_refl:
  for s: X.Sgn
  {X.sgn_is(s, s) == True{} : Bool}

def sgn_is_refl(s):
  match s:
    case X.Sn{}: {==}
    case X.Sz{}: {==}
    case X.Sp{}: {==}
    case X.Su{}: {==}

law sgn_neg_of_neg:
  for b: Bool
  {X.sgn_neg(X.sgn_of_neg(b)) == X.sgn_of_neg(Bool.not(b)) : X.Sgn}

def sgn_neg_of_neg(b):
  match b:
    case True{}: {==}
    case False{}: {==}

law ex_uncertain_dominates:
  for cs: List<&2, F64>
  {X.ex_sign(X.Ex{False{}, cs}) == X.Su{} : X.Sgn}

def ex_uncertain_dominates(cs):
  {==}

law ex_neg_keeps_ok:
  for ok: Bool
  for cs: List<&2, F64>
  {X.ex_ok(X.ex_neg(X.Ex{ok, cs})) == ok : Bool}

def ex_neg_keeps_ok(ok, cs):
  {==}

law ex_add_taints:
  for a: X.Ex
  for cs: List<&2, F64>
  {X.ex_ok(X.ex_add(a, X.Ex{False{}, cs})) == False{} : Bool}

def ex_add_taints(a, cs):
  {==}

law ex_mul_taints:
  for a: X.Ex
  for cs: List<&2, F64>
  {X.ex_ok(X.ex_mul(a, X.Ex{False{}, cs})) == False{} : Bool}

def ex_mul_taints(a, cs):
  {==}

law arrange_invalid_publishes_nothing:
  for segs: List<&2, A.Seg>
  for fuel: Nat
  {A.arrange_go(False{}, segs, fuel) == A.A_err{T.F_invalid{}} : A.ARes}

def arrange_invalid_publishes_nothing(segs, fuel):
  {==}

law arrange_budget_is_exhaustion:
  for segs: List<&2, A.Seg>
  {A.arrange_fuel(False{}, segs) == A.A_err{T.F_exhausted{}} : A.ARes}

def arrange_budget_is_exhaustion(segs):
  {==}

law ares_err_show:
  for k: T.FailKind
  {A.ares_show(A.A_err{k}) == "err " ++ T.FailKind.show(k) : String}

def ares_err_show(k):
  {==}

law solve_invalid_publishes_nothing:
  for cs: List<&2, S.Cn>
  for ps: List<&2, F64>
  for fr: List<&2, Bool>
  for np: Nat
  for tl: F64
  for ta: F64
  for fuel: Nat
  {S.run(False{}, cs, ps, fr, np, tl, ta, fuel) == S.Sv_err{T.F_invalid{}} : S.Sol}

def solve_invalid_publishes_nothing(cs, ps, fr, np, tl, ta, fuel):
  {==}

law lm_budget_returns_state:
  for d: Bool
  for cx: S.Cx
  for st: S.St
  {S.lm(0n, d, cx, st) == st : S.St}

def lm_budget_returns_state(d, cx, st):
  {==}

law lm_done_returns_state:
  for f: Nat
  for cx: S.Cx
  for st: S.St
  {S.lm(1n+f, True{}, cx, st) == st : S.St}

def lm_done_returns_state(f, cx, st):
  {==}

law no_conflict_without_stationarity:
  for ds: List<&2, S.Dr>
  {S.conflict_go(False{}, ds) == S.Sv_err{T.F_nonconverged{}} : S.Sol}

def no_conflict_without_stationarity(ds):
  {==}

law conflict_names_violations:
  for ds: List<&2, S.Dr>
  {S.conflict_go(True{}, ds) == S.Sv_conflict{S.dedup(S.viol(ds))} : S.Sol}

def conflict_names_violations(ds):
  {==}

law sol_err_show:
  for k: T.FailKind
  {S.sol_show(S.Sv_err{k}) == "err " ++ T.FailKind.show(k) : String}

def sol_err_show(k):
  {==}

law gather_len:
  for n: Nat
  for i: U32
  for pm: P.Tb<&2, U32>
  for xt: P.Tb<&2, F64>
  {S.flen(S.gather(n, i, pm, xt)) == n : Nat}

def gather_len(n, i, pm, xt):
  match n:
    case 0n: {==}
    case 1n+m:
      %gather_len(m, (i + 1 : U32), pm, xt) : {1n+S.flen(S.gather(m, (i + 1 : U32), pm, xt)) == 1n+_ : Nat}
      {==}

law nat_eq_refl:
  for x: Nat
  {True{} == Nat.is_eq(x, x) : Bool}

def nat_eq_refl(x):
  match x:
    case 0n: {==}
    case 1n+p: nat_eq_refl(p)

law self_coincidence_invalid:
  for id: U64
  for x: Nat
  for y: Nat
  for np: Nat
  {S.cn_ok(S.K_coinc{id, S.Pt{x, y}, S.Pt{x, y}}, np) == False{} : Bool}

def self_coincidence_invalid(id, x, y, np):
  %nat_eq_refl(x) : {Bool.and(Bool.not(Bool.and(_, Nat.is_eq(y, y))),
    Bool.and(Bool.and(Nat.is_lt(x, np), Nat.is_lt(y, np)),
      Bool.and(Nat.is_lt(x, np), Nat.is_lt(y, np)))) == False{} : Bool}
  %nat_eq_refl(y) : {Bool.and(Bool.not(_),
    Bool.and(Bool.and(Nat.is_lt(x, np), Nat.is_lt(y, np)),
      Bool.and(Nat.is_lt(x, np), Nat.is_lt(y, np)))) == False{} : Bool}
  {==}

law pt_eq_refl:
  for p: S.Pt
  {True{} == S.pt_eq(p, p) : Bool}

def pt_eq_refl(p):
  match p:
    case S.Pt{x, y}:
      %nat_eq_refl(x) : {True{} == Bool.and(_, Nat.is_eq(y, y)) : Bool}
      nat_eq_refl(y)

law or_true_r:
  for x: Bool
  {True{} == Bool.or(x, True{}) : Bool}

def or_true_r(x):
  match x:
    case True{}: {==}
    case False{}: {==}

law self_pair_invalid:
  for +p: S.Pt
  for +np: Nat
  {S.two_ok(p, p, np) == False{} : Bool}

def self_pair_invalid(p, np):
  %pt_eq_refl(p) : {Bool.and(Bool.not(_), Bool.and(S.pt_ok(p, np), S.pt_ok(p, np))) == False{} : Bool}
  {==}

law same_line_invalid:
  for a: S.Pt
  for b: S.Pt
  for np: Nat
  {S.lines_ok(a, b, a, b, np) == False{} : Bool}

def same_line_invalid(a, b, np):
  %pt_eq_refl(a) : {Bool.and(Bool.not(Bool.or(Bool.and(_, S.pt_eq(b, b)),
    Bool.and(S.pt_eq(a, b), S.pt_eq(b, a)))),
    Bool.and(S.two_ok(a, b, np), S.two_ok(a, b, np))) == False{} : Bool}
  %pt_eq_refl(b) : {Bool.and(Bool.not(Bool.or(Bool.and(True{}, _),
    Bool.and(S.pt_eq(a, b), S.pt_eq(b, a)))),
    Bool.and(S.two_ok(a, b, np), S.two_ok(a, b, np))) == False{} : Bool}
  {==}

law reversed_line_invalid:
  for +a: S.Pt
  for +b: S.Pt
  for +np: Nat
  {S.lines_ok(a, b, b, a, np) == False{} : Bool}

def reversed_line_invalid(a, b, np):
  %pt_eq_refl(a) : {Bool.and(Bool.not(Bool.or(Bool.and(S.pt_eq(a, b), S.pt_eq(b, a)),
    Bool.and(_, S.pt_eq(b, b)))),
    Bool.and(S.two_ok(a, b, np), S.two_ok(b, a, np))) == False{} : Bool}
  %pt_eq_refl(b) : {Bool.and(Bool.not(Bool.or(Bool.and(S.pt_eq(a, b), S.pt_eq(b, a)),
    Bool.and(True{}, _))),
    Bool.and(S.two_ok(a, b, np), S.two_ok(b, a, np))) == False{} : Bool}
  %or_true_r(Bool.and(S.pt_eq(a, b), S.pt_eq(b, a))) : {Bool.and(Bool.not(_),
    Bool.and(S.two_ok(a, b, np), S.two_ok(b, a, np))) == False{} : Bool}
  {==}

law par_self_invalid:
  for id: U64
  for a: S.Pt
  for b: S.Pt
  for np: Nat
  {S.cn_ok(S.K_par{id, a, b, a, b}, np) == False{} : Bool}

def par_self_invalid(id, a, b, np):
  same_line_invalid(a, b, np)

law perp_self_invalid:
  for id: U64
  for a: S.Pt
  for b: S.Pt
  for np: Nat
  {S.cn_ok(S.K_perp{id, a, b, b, a}, np) == False{} : Bool}

def perp_self_invalid(id, a, b, np):
  reversed_line_invalid(a, b, np)

law horiz_self_invalid:
  for id: U64
  for a: S.Pt
  for np: Nat
  {S.cn_ok(S.K_horiz{id, a, a}, np) == False{} : Bool}

def horiz_self_invalid(id, a, np):
  self_pair_invalid(a, np)

law dist_self_invalid:
  for id: U64
  for +a: S.Pt
  for d: F64
  for +np: Nat
  {S.cn_ok(S.K_dist{id, a, a, d}, np) == False{} : Bool}

def dist_self_invalid(id, a, d, np):
  %pt_eq_refl(a) : {Bool.and(Bool.and(Bool.not(_), Bool.and(S.pt_ok(a, np), S.pt_ok(a, np))),
    S.pos(d)) == False{} : Bool}
  {==}

law ok_arrange_square:
  {A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 4.0f64, 0.0f64}, A.Seg{2u64, 4.0f64, 0.0f64, 4.0f64, 4.0f64},
    A.Seg{3u64, 4.0f64, 4.0f64, 0.0f64, 4.0f64}, A.Seg{4u64, 0.0f64, 4.0f64, 0.0f64, 0.0f64}], 100n))
    == "v=4 e=4 c=1 R { e1.0[1] e1.1[2] e2.1[3] e3.1[4] } D" : String}

def ok_arrange_square():
  {==}

law ok_arrange_cross_dangles:
  {A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 2.0f64, 2.0f64},
    A.Seg{2u64, 0.0f64, 2.0f64, 2.0f64, 0.0f64}], 10n))
    == "v=5 e=4 c=1 R D e1.0-x1.2 e2.0-x1.2 x1.2-e2.1 x1.2-e1.1" : String}

def ok_arrange_cross_dangles():
  {==}

law neg_arrange_degenerate:
  {A.ares_show(A.arrange([A.Seg{1u64, 1.0f64, 1.0f64, 1.0f64, 1.0f64}], 10n))
    == "err invalid-input" : String}

def neg_arrange_degenerate():
  {==}

law neg_arrange_budget:
  {A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 1.0f64, 0.0f64},
    A.Seg{2u64, 1.0f64, 0.0f64, 1.0f64, 1.0f64}], 1n))
    == "err resource-exhausted" : String}

def neg_arrange_budget():
  {==}

law neg_arrange_underflow:
  {A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, F64{2220274616293654528u64}, F64{2220274616293654528u64}},
    A.Seg{2u64, 0.0f64, F64{2220274616293654528u64}, F64{2220274616293654528u64}, 0.0f64}], 10n))
    == "err numerical-uncertainty" : String}

def neg_arrange_underflow():
  {==}

law neg_solve_bad_index:
  {S.sol_show(S.solve([0.0f64, 0.0f64], [True{}, True{}], [S.K_fix{1u64, 2n, 0.0f64}],
    T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 10n))
    == "err invalid-input" : String}

def neg_solve_bad_index():
  {==}

law neg_solve_budget_not_conflict:
  {S.sol_show(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, True{}, True{}],
    [S.K_dist{5u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 20.0f64}],
    T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 0n))
    == "err nonconvergence" : String}

def neg_solve_budget_not_conflict():
  {==}

law neg_solve_grounded_conflict:
  {S.sol_show(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, False{}, False{}],
    [S.K_dist{5u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 20.0f64}],
    T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 1n))
    == "conflict [5]" : String}

def neg_solve_grounded_conflict():
  {==}

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

law ok_solve_linear:
  {ok_bits(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, True{}, True{}],
    [S.K_horiz{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}}, S.K_fix{2u64, 2n, 5.0f64}],
    T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 10n),
    0n, [], [0u64, 0u64, 4617315517961601024u64, 4169896036682170368u64]) == True{} : Bool}

def ok_solve_linear():
  {==}

law ok_solve_redundant_named:
  {ok_bits(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, True{}, True{}],
    [S.K_dist{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 10.0f64}, S.K_dist{2u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 10.0f64}],
    T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 100n),
    1n, [2u64], [0u64, 0u64, 4621363944573119361u64, 4616052692831493340u64]) == True{} : Bool}

def ok_solve_redundant_named():
  {==}

law ok_solve_tangent_circles:
  {ok_bits(S.solve([0.0f64, 0.0f64, 2.0f64, 9.0f64, 0.0f64, 3.0f64], [False{}, False{}, False{}, True{}, False{}, False{}],
    [S.K_tan_cc{1u64, S.Pt{0n, 1n}, 2n, S.Pt{3n, 4n}, 5n}],
    T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 100n),
    0n, [], [0u64, 0u64, 4611686018427387904u64, 4617315517961601024u64, 0u64, 4613937818241073152u64]) == True{} : Bool}

def ok_solve_tangent_circles():
  {==}

law neg_solve_conflict_named:
  {S.sol_show(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, True{}, True{}],
    [S.K_dist{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 5.0f64}, S.K_dist{2u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 6.0f64}],
    T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 100n))
    == "conflict [1,2]" : String}

def neg_solve_conflict_named():
  {==}

law ok_arrange_antenna_dangles:
  {A.ares_show(A.arrange([A.Seg{9u64, 2.0f64, 0.0f64, 2.0f64, 1.0f64},
    A.Seg{1u64, 0.0f64, 0.0f64, 4.0f64, 0.0f64}, A.Seg{2u64, 4.0f64, 0.0f64, 4.0f64, 4.0f64},
    A.Seg{3u64, 4.0f64, 4.0f64, 0.0f64, 4.0f64}, A.Seg{4u64, 0.0f64, 4.0f64, 0.0f64, 0.0f64}], 100n))
    == "v=6 e=6 c=1 R { e1.0[1] e9.0[1] e1.1[2] e2.1[3] e3.1[4] } D e9.0-e9.1" : String}

def ok_arrange_antenna_dangles():
  {==}

law ok_arrange_overlap_lineage:
  {A.ares_show(A.arrange([A.Seg{9u64, 1.0f64, 0.0f64, 3.0f64, 0.0f64},
    A.Seg{1u64, 0.0f64, 0.0f64, 4.0f64, 0.0f64}, A.Seg{2u64, 4.0f64, 0.0f64, 4.0f64, 4.0f64},
    A.Seg{3u64, 4.0f64, 4.0f64, 0.0f64, 4.0f64}, A.Seg{4u64, 0.0f64, 4.0f64, 0.0f64, 0.0f64}], 100n))
    == "v=6 e=6 c=1 R { e1.0[1] e9.0[1,9] e9.1[1] e1.1[2] e2.1[3] e3.1[4] } D" : String}

def ok_arrange_overlap_lineage():
  {==}

law ok_arrange_hole:
  {A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 10.0f64, 0.0f64}, A.Seg{2u64, 10.0f64, 0.0f64, 10.0f64, 10.0f64},
    A.Seg{3u64, 10.0f64, 10.0f64, 0.0f64, 10.0f64}, A.Seg{4u64, 0.0f64, 10.0f64, 0.0f64, 0.0f64},
    A.Seg{11u64, 2.0f64, 2.0f64, 8.0f64, 2.0f64}, A.Seg{12u64, 8.0f64, 2.0f64, 8.0f64, 8.0f64},
    A.Seg{13u64, 8.0f64, 8.0f64, 2.0f64, 8.0f64}, A.Seg{14u64, 2.0f64, 8.0f64, 2.0f64, 2.0f64}], 100n))
    == "v=8 e=8 c=2 R { e1.0[1] e1.1[2] e2.1[3] e3.1[4] | e11.0[14] e13.1[13] e12.1[12] e11.1[11] } { e11.0[11] e11.1[12] e12.1[13] e13.1[14] } D" : String}

def ok_arrange_hole():
  {==}

law ok_arrange_islands:
  {A.ares_show(A.arrange([A.Seg{1u64, 0.0f64, 0.0f64, 2.0f64, 0.0f64}, A.Seg{2u64, 2.0f64, 0.0f64, 2.0f64, 2.0f64},
    A.Seg{3u64, 2.0f64, 2.0f64, 0.0f64, 2.0f64}, A.Seg{4u64, 0.0f64, 2.0f64, 0.0f64, 0.0f64},
    A.Seg{11u64, 5.0f64, 0.0f64, 7.0f64, 0.0f64}, A.Seg{12u64, 7.0f64, 0.0f64, 7.0f64, 2.0f64},
    A.Seg{13u64, 7.0f64, 2.0f64, 5.0f64, 2.0f64}, A.Seg{14u64, 5.0f64, 2.0f64, 5.0f64, 0.0f64}], 100n))
    == "v=8 e=8 c=2 R { e1.0[1] e1.1[2] e2.1[3] e3.1[4] } { e11.0[11] e11.1[12] e12.1[13] e13.1[14] } D" : String}

def ok_arrange_islands():
  {==}

def sol_ok(s: S.Sol) -> Bool:
  match s:
    case S.Sv_ok{ps, dof, red}: True{}
    case _: False{}

law conflict_never_ok:
  for b: Bool
  for ds: List<&2, S.Dr>
  {sol_ok(S.conflict_go(b, ds)) == False{} : Bool}

def conflict_never_ok(b, ds):
  match b:
    case True{}: {==}
    case False{}: {==}

law ok_iff_solved:
  for s: Bool
  for +cx: S.Cx
  for ps: List<&2, F64>
  for +ds: List<&2, S.Dr>
  {sol_ok(S.classify_go(s, cx, ps, ds)) == s : Bool}

def ok_iff_solved(s, cx, ps, ds):
  match s:
    case True{}: {==}
    case False{}:
      conflict_never_ok(F64.is_le(S.jtr_nrm(ds),
        ((S.p2(26n) * F64.sqrt(S.fro2(ds)) : F64) * S.nrm(S.res_of(ds)) : F64)), ds)

law classify_is_solved_at:
  for +cx: S.Cx
  for +ps: List<&2, F64>
  {S.classify(cx, ps) == S.classify_go(S.solved_at(cx, ps, S.rq_ds(S.rows_at(cx, ps))), cx, ps, S.rq_ds(S.rows_at(cx, ps))) : S.Sol}

def classify_is_solved_at(cx, ps):
  {==}

law solved_needs_geometry:
  for +cx: S.Cx
  for +ps: List<&2, F64>
  for ds: List<&2, S.Dr>
  {S.solved_at(cx, ps, ds) == Bool.and(S.geo_ok(S.cx_cs(cx), S.ptb(ps), S.cx_tl(cx)),
    F64.is_le(S.maxabs(S.res_of(ds)), 1.0f64)) : Bool}

def solved_needs_geometry(cx, ps, ds):
  {==}

law geometry_veto:
  for +cx: S.Cx
  for ps: List<&2, F64>
  for ds: List<&2, S.Dr>
  for x: Bool
  {sol_ok(S.classify_go(Bool.and(False{}, x), cx, ps, ds)) == False{} : Bool}

def geometry_veto(cx, ps, ds, x):
  ok_iff_solved(False{}, cx, ps, ds)

law steps_keep_radii_positive:
  for +cs: List<&2, S.Cn>
  for +ps0: P.Tb<&2, F64>
  for ft: P.Tb<&2, Bool>
  for np: Nat
  for nf: Nat
  for tl: F64
  for ta: F64
  for lo: F64
  for hi: F64
  for od: S.Od
  for +ps: List<&2, F64>
  {S.rq_ok(S.rows_at(S.Cx{cs, ps0, ft, np, nf, tl, ta, lo, hi, od}, ps)) == Bool.and(S.rad_ok(cs, S.ptb(ps)), S.rows_ok(S.all_rows(cs, S.ptb(ps), ps0))) : Bool}

def steps_keep_radii_positive(cs, ps0, ft, np, nf, tl, ta, lo, hi, od, ps):
  {==}

law neg_angle_is_directed:
  {S.sol_show(S.solve([0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 5.0f64, F64.neg(10.0f64), 5.0f64],
    [False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}],
    [S.K_angle{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 1.0f64, 0.0f64}],
    T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 10n)) == "conflict [1]" : String}

def neg_angle_is_directed():
  {==}

law neg_angle90_is_directed:
  {S.sol_show(S.solve([0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 5.0f64, 0.0f64, F64.neg(5.0f64)],
    [False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}],
    [S.K_angle{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 0.0f64, 1.0f64}],
    T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 10n)) == "conflict [1]" : String}

def neg_angle90_is_directed():
  {==}

law ok_parallel_is_undirected:
  {ok_bits(S.solve([0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 5.0f64, F64.neg(10.0f64), 5.0f64],
    [False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}],
    [S.K_par{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, S.Pt{4n, 5n}, S.Pt{6n, 7n}}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 10n),
    0n, [1u64], [0u64, 0u64, 4621819117588971520u64, 0u64, 0u64, 4617315517961601024u64,
      13845191154443747328u64, 4617315517961601024u64]) == True{} : Bool}

def ok_parallel_is_undirected():
  {==}

law ok_angle_from_flipped_side:
  {ok_bits(S.solve([0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 0.0f64, F64.neg(9.4f64), F64.neg(3.4f64)],
    [False{}, False{}, False{}, False{}, False{}, False{}, True{}, True{}],
    [S.K_angle{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 0.8660254037844387f64, 0.5f64},
     S.K_dist{2u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 10.0f64}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 100n),
    0n, [], [0u64, 0u64, 4621819117588971520u64, 0u64, 0u64, 0u64,
      4621064907661979626u64, 4617315517961601023u64]) == True{} : Bool}

def ok_angle_from_flipped_side():
  {==}

law neg_axes_never_collapse:
  {S.sol_show(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, True{}, True{}],
    [S.K_horiz{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}}, S.K_vert{2u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 30n))
    == "conflict [1,2]" : String}

def neg_axes_never_collapse():
  {==}

law neg_coincidence_collapse_not_ok:
  {sol_ok(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64], [False{}, False{}, True{}, True{}],
    [S.K_coinc{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}}, S.K_horiz{2u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 30n))
    == False{} : Bool}

def neg_coincidence_collapse_not_ok():
  {==}

law neg_negative_radius_not_ok:
  {sol_ok(S.solve([0.0f64, 0.0f64, 10.0f64, 0.0f64, 4.0f64, 3.0f64, 3.0f64],
    [False{}, False{}, False{}, False{}, False{}, True{}, True{}],
    [S.K_tan_lc{1u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, S.Pt{4n, 5n}, 6n},
     S.K_vdist{2u64, S.Pt{0n, 1n}, S.Pt{4n, 5n}, F64.neg(2.0f64)}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 30n)) == False{} : Bool}

def neg_negative_radius_not_ok():
  {==}

law neg_nonpositive_radius_start:
  {S.sol_show(S.solve([0.0f64, 0.0f64, 3.0f64, 0.0f64, F64.neg(1.0f64)], [True{}, True{}, True{}, True{}, True{}],
    [S.K_on_circ{1u64, S.Pt{2n, 3n}, S.Pt{0n, 1n}, 4n}], T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 10n)) == "err invalid-input" : String}

def neg_nonpositive_radius_start():
  {==}

def dof_red(s: S.Sol, +dof: Nat, rs: List<&2, U64>) -> Bool:
  match s:
    case S.Sv_ok{ps, d, red}: Bool.and(Nat.is_eq(d, dof), ids_eq(red, rs))
    case _: False{}

law ok_solve_zero_pivot:
  {dof_red(S.solve([5.1787109375f64, 1.302734375f64, 10.19921875f64, 1.28515625f64, 1.8203125f64, 1.01953125f64, 1.5400390625f64, F64.neg(3.0869140625f64)], [False{}, False{}, True{}, True{}, True{}, True{}, True{}, True{}], [S.K_hdist{3u64, S.Pt{6n, 7n}, S.Pt{0n, 1n}, 3.6572265625f64}, S.K_perp{6u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, S.Pt{0n, 1n}, S.Pt{2n, 3n}}, S.K_dist{11u64, S.Pt{4n, 5n}, S.Pt{2n, 3n}, 8.720686658469603f64}, S.K_dist{12u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 4.318359375f64}, S.K_vert{25u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}}, S.K_dist{27u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 4.318359375f64}],
    T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 200n), 1n, [27u64]) == True{} : Bool}

def ok_solve_zero_pivot():
  {==}

law ok_solve_clusters_merge:
  {dof_red(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64, 20.0f64, 0.0f64, 24.0f64, 2.0f64],
    [False{}, False{}, True{}, True{}, False{}, False{}, True{}, True{}],
    [S.K_dist{10u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 5.0f64}, S.K_dist{11u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 10.0f64},
     S.K_dist{12u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 5.0f64}, S.K_dist{13u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 10.0f64}],
    T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 100n), 2n, [12u64, 13u64]) == True{} : Bool}

def ok_solve_clusters_merge():
  {==}

law neg_solve_conflict_localized:
  {S.sol_show(S.solve([0.0f64, 0.0f64, 7.0f64, 3.0f64, 20.0f64, 0.0f64, 24.0f64, 2.0f64],
    [False{}, False{}, True{}, True{}, False{}, False{}, True{}, True{}],
    [S.K_dist{20u64, S.Pt{0n, 1n}, S.Pt{2n, 3n}, 10.0f64}, S.K_dist{21u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 5.0f64},
     S.K_dist{22u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 6.0f64}],
    T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 100n))
    == "conflict [21,22]" : String}

def neg_solve_conflict_localized():
  {==}
