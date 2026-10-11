import Base
import ../../src/c00/types.bend as T
import ../../src/c05/exact.bend as X
import ../../src/c05/arrange.bend as A
import ../../src/c05/solve.bend as S
import ../../src/base/par.bend as P
import ../../src/base/ex.bend as E
import ./LAWS.bend as Laws

def Laws.sgn_neg_invol(s):
  match s:
    case P.Sn{}: {==}
    case P.Sz{}: {==}
    case P.Sp{}: {==}
    case P.Su{}: {==}

def Laws.sgn_is_refl(s):
  match s:
    case P.Sn{}: {==}
    case P.Sz{}: {==}
    case P.Sp{}: {==}
    case P.Su{}: {==}

def Laws.sgn_neg_of_neg(b):
  match b:
    case True{}: {==}
    case False{}: {==}

def Laws.ex_uncertain_dominates(cs):
  {==}

def Laws.ex_neg_keeps_ok(ok, cs):
  {==}

def Laws.ex_add_taints(a, cs):
  {==}

def Laws.ex_mul_taints(a, cs):
  {==}

def Laws.arrange_invalid_publishes_nothing(segs, fuel):
  {==}

def Laws.arrange_budget_is_exhaustion(segs):
  {==}

def Laws.ares_err_show(k):
  {==}

def Laws.solve_invalid_publishes_nothing(cs, ps, fr, np, tl, ta, fuel):
  {==}

def Laws.lm_budget_returns_state(d, cx, st):
  {==}

def Laws.lm_done_returns_state(f, cx, st):
  {==}

def Laws.no_conflict_without_stationarity(ds):
  {==}

def Laws.conflict_names_violations(ds):
  {==}

def Laws.sol_err_show(k):
  {==}

def Laws.gather_len(n, i, pm, xt):
  match n:
    case 0n: {==}
    case 1n+m:
      %Laws.gather_len(m, (i + 1 : U32), pm, xt) : {1n+S.flen(S.gather(m, (i + 1 : U32), pm, xt)) == 1n+_ : Nat}
      {==}

def Laws.nat_eq_refl(x):
  match x:
    case 0n: {==}
    case 1n+p: Laws.nat_eq_refl(p)

def Laws.self_coincidence_invalid(id, x, y, np):
  %Laws.nat_eq_refl(x) : {Bool.and(Bool.not(Bool.and(_, Nat.is_eq(y, y))),
    Bool.and(Bool.and(Nat.is_lt(x, np), Nat.is_lt(y, np)),
      Bool.and(Nat.is_lt(x, np), Nat.is_lt(y, np)))) == False{} : Bool}
  %Laws.nat_eq_refl(y) : {Bool.and(Bool.not(_),
    Bool.and(Bool.and(Nat.is_lt(x, np), Nat.is_lt(y, np)),
      Bool.and(Nat.is_lt(x, np), Nat.is_lt(y, np)))) == False{} : Bool}
  {==}

def Laws.pt_eq_refl(p):
  match p:
    case S.Pt{x, y}:
      %Laws.nat_eq_refl(x) : {True{} == Bool.and(_, Nat.is_eq(y, y)) : Bool}
      Laws.nat_eq_refl(y)

def Laws.or_true_r(x):
  match x:
    case True{}: {==}
    case False{}: {==}

def Laws.self_pair_invalid(p, np):
  %Laws.pt_eq_refl(p) : {Bool.and(Bool.not(_), Bool.and(S.pt_ok(p, np), S.pt_ok(p, np))) == False{} : Bool}
  {==}

def Laws.same_line_invalid(a, b, np):
  %Laws.pt_eq_refl(a) : {Bool.and(Bool.not(Bool.or(Bool.and(_, S.pt_eq(b, b)),
    Bool.and(S.pt_eq(a, b), S.pt_eq(b, a)))),
    Bool.and(S.two_ok(a, b, np), S.two_ok(a, b, np))) == False{} : Bool}
  %Laws.pt_eq_refl(b) : {Bool.and(Bool.not(Bool.or(Bool.and(True{}, _),
    Bool.and(S.pt_eq(a, b), S.pt_eq(b, a)))),
    Bool.and(S.two_ok(a, b, np), S.two_ok(a, b, np))) == False{} : Bool}
  {==}

def Laws.reversed_line_invalid(a, b, np):
  %Laws.pt_eq_refl(a) : {Bool.and(Bool.not(Bool.or(Bool.and(S.pt_eq(a, b), S.pt_eq(b, a)),
    Bool.and(_, S.pt_eq(b, b)))),
    Bool.and(S.two_ok(a, b, np), S.two_ok(b, a, np))) == False{} : Bool}
  %Laws.pt_eq_refl(b) : {Bool.and(Bool.not(Bool.or(Bool.and(S.pt_eq(a, b), S.pt_eq(b, a)),
    Bool.and(True{}, _))),
    Bool.and(S.two_ok(a, b, np), S.two_ok(b, a, np))) == False{} : Bool}
  %Laws.or_true_r(Bool.and(S.pt_eq(a, b), S.pt_eq(b, a))) : {Bool.and(Bool.not(_),
    Bool.and(S.two_ok(a, b, np), S.two_ok(b, a, np))) == False{} : Bool}
  {==}

def Laws.par_self_invalid(id, a, b, np):
  Laws.same_line_invalid(a, b, np)

def Laws.perp_self_invalid(id, a, b, np):
  Laws.reversed_line_invalid(a, b, np)

def Laws.horiz_self_invalid(id, a, np):
  Laws.self_pair_invalid(a, np)

def Laws.dist_self_invalid(id, a, d, np):
  %Laws.pt_eq_refl(a) : {Bool.and(Bool.and(Bool.not(_), Bool.and(S.pt_ok(a, np), S.pt_ok(a, np))),
    S.pos(d)) == False{} : Bool}
  {==}

def Laws.conflict_never_ok(b, ds):
  match b:
    case True{}: {==}
    case False{}: {==}

def Laws.ok_iff_solved(s, cx, ps, ds):
  match s:
    case True{}: {==}
    case False{}:
      Laws.conflict_never_ok(F64.is_le(S.jtr_nrm(ds),
        ((S.p2(26n) * F64.sqrt(S.fro2(ds)) : F64) * S.nrm(S.res_of(ds)) : F64)), ds)

def Laws.classify_is_solved_at(cx, ps):
  {==}

def Laws.solved_needs_geometry(cx, ps, ds):
  {==}

def Laws.geometry_veto(cx, ps, ds, x):
  Laws.ok_iff_solved(False{}, cx, ps, ds)

def Laws.steps_keep_radii_positive(cs, ps0, ft, np, nf, tl, ta, lo, hi, od, ps):
  {==}
