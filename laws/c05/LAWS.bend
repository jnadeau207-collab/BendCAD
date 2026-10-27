import Base
import ../../src/c00/types.bend as T
import ../../src/c05/exact.bend as X
import ../../src/c05/arrange.bend as A
import ../../src/c05/solve.bend as S
import ../../src/base/par.bend as P
import ../../src/base/ex.bend as E

def sol_ok(s: S.Sol) -> Bool:
  match s:
    case S.Sv_ok{ps, dof, red}: True{}
    case _: False{}

law sgn_neg_invol:
  for s: P.Sgn
  {P.sgn_neg(P.sgn_neg(s)) == s : P.Sgn}

law sgn_is_refl:
  for s: P.Sgn
  {P.sgn_is(s, s) == True{} : Bool}

law sgn_neg_of_neg:
  for b: Bool
  {P.sgn_neg(E.sgn_of_neg(b)) == E.sgn_of_neg(Bool.not(b)) : P.Sgn}

law ex_uncertain_dominates:
  for cs: List<&2, F64>
  {E.ex_sign(E.Ex{False{}, cs}) == P.Su{} : P.Sgn}

law ex_neg_keeps_ok:
  for ok: Bool
  for cs: List<&2, F64>
  {E.ex_ok(E.ex_neg(E.Ex{ok, cs})) == ok : Bool}

law ex_add_taints:
  for a: E.Ex
  for cs: List<&2, F64>
  {E.ex_ok(E.ex_add(a, E.Ex{False{}, cs})) == False{} : Bool}

law ex_mul_taints:
  for a: E.Ex
  for cs: List<&2, F64>
  {E.ex_ok(E.ex_mul(a, E.Ex{False{}, cs})) == False{} : Bool}

law arrange_invalid_publishes_nothing:
  for segs: List<&2, A.Seg>
  for fuel: Nat
  {A.arrange_go(False{}, segs, fuel) == A.A_err{T.F_invalid{}} : A.ARes}

law arrange_budget_is_exhaustion:
  for segs: List<&2, A.Seg>
  {A.arrange_fuel(False{}, segs) == A.A_err{T.F_exhausted{}} : A.ARes}

law ares_err_show:
  for k: T.FailKind
  {A.ares_show(A.A_err{k}) == "err " ++ T.FailKind.show(k) : String}

law solve_invalid_publishes_nothing:
  for cs: List<&2, S.Cn>
  for ps: List<&2, F64>
  for fr: List<&2, Bool>
  for np: Nat
  for tl: F64
  for ta: F64
  for fuel: Nat
  {S.run(False{}, cs, ps, fr, np, tl, ta, fuel) == S.Sv_err{T.F_invalid{}} : S.Sol}

law lm_budget_returns_state:
  for d: Bool
  for cx: S.Cx
  for st: S.St
  {S.lm(0n, d, cx, st) == st : S.St}

law lm_done_returns_state:
  for f: Nat
  for cx: S.Cx
  for st: S.St
  {S.lm(1n+f, True{}, cx, st) == st : S.St}

law no_conflict_without_stationarity:
  for ds: List<&2, S.Dr>
  for c: Bool
  {S.conflict_go(False{}, ds, c) == S.Sv_err{T.F_nonconverged{}} : S.Sol}

law conflict_names_violations:
  for ds: List<&2, S.Dr>
  for c: Bool
  {S.conflict_go(True{}, ds, c) == S.Sv_conflict{S.dedup(S.viol(ds)), c} : S.Sol}

law uncertified_conflict_is_estimated:
  for ids: List<&2, U64>
  {S.sol_show(S.Sv_conflict{ids, False{}}) == "unresolved [" ++ S.ids_show(ids) ++ "] status=estimated" : String}

law certified_conflict_is_conflict:
  for ids: List<&2, U64>
  {S.sol_show(S.Sv_conflict{ids, True{}}) == "conflict [" ++ S.ids_show(ids) ++ "]" : String}

law sol_err_show:
  for k: T.FailKind
  {S.sol_show(S.Sv_err{k}) == "err " ++ T.FailKind.show(k) : String}

law gather_len:
  for n: Nat
  for i: U32
  for pm: P.Tb<&2, U32>
  for xt: P.Tb<&2, F64>
  {S.flen(S.gather(n, i, pm, xt)) == n : Nat}

law nat_eq_refl:
  for x: Nat
  {True{} == Nat.is_eq(x, x) : Bool}

law self_coincidence_invalid:
  for id: U64
  for x: Nat
  for y: Nat
  for np: Nat
  {S.cn_ok(S.K_coinc{id, S.Pt{x, y}, S.Pt{x, y}}, np) == False{} : Bool}

law pt_eq_refl:
  for p: S.Pt
  {True{} == S.pt_eq(p, p) : Bool}

law or_true_r:
  for x: Bool
  {True{} == Bool.or(x, True{}) : Bool}

law self_pair_invalid:
  for +p: S.Pt
  for +np: Nat
  {S.two_ok(p, p, np) == False{} : Bool}

law same_line_invalid:
  for a: S.Pt
  for b: S.Pt
  for np: Nat
  {S.lines_ok(a, b, a, b, np) == False{} : Bool}

law reversed_line_invalid:
  for +a: S.Pt
  for +b: S.Pt
  for +np: Nat
  {S.lines_ok(a, b, b, a, np) == False{} : Bool}

law par_self_invalid:
  for id: U64
  for a: S.Pt
  for b: S.Pt
  for np: Nat
  {S.cn_ok(S.K_par{id, a, b, a, b}, np) == False{} : Bool}

law perp_self_invalid:
  for id: U64
  for a: S.Pt
  for b: S.Pt
  for np: Nat
  {S.cn_ok(S.K_perp{id, a, b, b, a}, np) == False{} : Bool}

law horiz_self_invalid:
  for id: U64
  for a: S.Pt
  for np: Nat
  {S.cn_ok(S.K_horiz{id, a, a}, np) == False{} : Bool}

law dist_self_invalid:
  for id: U64
  for +a: S.Pt
  for d: F64
  for +np: Nat
  {S.cn_ok(S.K_dist{id, a, a, d}, np) == False{} : Bool}

law conflict_never_ok:
  for b: Bool
  for ds: List<&2, S.Dr>
  for c: Bool
  {sol_ok(S.conflict_go(b, ds, c)) == False{} : Bool}

law ok_iff_solved:
  for s: Bool
  for +cx: S.Cx
  for ps: List<&2, F64>
  for +ds: List<&2, S.Dr>
  {sol_ok(S.classify_go(s, cx, ps, ds)) == s : Bool}

law classify_is_solved_at:
  for +cx: S.Cx
  for +ps: List<&2, F64>
  {S.classify(cx, ps) == S.classify_go(S.solved_at(cx, ps, S.rq_ds(S.rows_at(cx, ps))), cx, ps, S.rq_ds(S.rows_at(cx, ps))) : S.Sol}

law solved_needs_geometry:
  for +cx: S.Cx
  for +ps: List<&2, F64>
  for ds: List<&2, S.Dr>
  {S.solved_at(cx, ps, ds) == Bool.and(S.geo_ok(S.cx_cs(cx), S.ptb(ps), S.cx_tl(cx)),
    F64.is_le(S.maxabs(S.res_of(ds)), 1.0f64)) : Bool}

law geometry_veto:
  for +cx: S.Cx
  for ps: List<&2, F64>
  for ds: List<&2, S.Dr>
  for x: Bool
  {sol_ok(S.classify_go(Bool.and(False{}, x), cx, ps, ds)) == False{} : Bool}

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
  for ho: List<&2, F64>
  for +ps: List<&2, F64>
  {S.rq_ok(S.rows_at(S.Cx{cs, ps0, ft, np, nf, tl, ta, lo, hi, od, ho}, ps)) == Bool.and(S.rad_ok(cs, S.ptb(ps)), S.rows_ok(S.all_rows(cs, S.ptb(ps), ps0))) : Bool}
