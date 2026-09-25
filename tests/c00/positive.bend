# C00 positive tests: valid requests publish exactly once with pinned
# witnesses; empty intersection succeeds distinctly; op identity is
# deterministic over content and blind to execution inputs.
# Ends in selfcheck fails=N.

import Base
import ../../src/c00/types.bend as T
import ../../src/c00/eval.bend as E
import ./check.bend as C

def negzero_ok_go(o: T.Outcome, got: String, v: F64, m: T.Model,
    pre: T.Model) -> Bool:
  match o:
    case T.Ok{model, status, op}:
      Bool.and(String.eq(got, "ok-value"),
        Bool.and(F64.is_eq(v, 0.0f64),
          U64.is_eq(T.model_rev(m), (T.model_rev(pre) + 1u64 : U64))))
    case T.Incomplete{op, fuel_used, model}: False{}
    case T.Failed{kind, model, op}: False{}

def negzero_ok(+o: T.Outcome, pre: T.Model) -> Bool:
  negzero_ok_go(o, E.outcome_show(o), E.outcome_value(o),
    E.outcome_model(o), pre)

def report_negzero(tag: String, +o: T.Outcome, +pre: T.Model,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ C.verdict(negzero_ok(o, pre))
      ++ " [" ++ E.outcome_show(o) ++ "]")
    return C.bump(f, negzero_ok(o, pre))

def req_len_m() -> T.Request:
  C.len_req(T.U_m{}, 2.0f64, C.tol_good(), C.bud2(), 64u64, False{})

def req_len_m3() -> T.Request:
  C.len_req(T.U_m{}, 3.0f64, C.tol_good(), C.bud2(), 64u64, False{})

def req_len_cm() -> T.Request:
  C.len_req(T.U_cm{}, 2.0f64, C.tol_good(), C.bud2(), 64u64, False{})

def req_empty() -> T.Request:
  C.isect_req(T.U_mm{}, 0.0f64, 1.0f64, 5.0f64, 15.0f64, C.tol_good(),
    C.bud2(), 64u64, False{})

def main() -> IO(Unit):
  do IO<Unit>:
    f1 : U64 <- C.report_published("pos-len-m",
      E.run(T.model_seed(), req_len_m()), 4656510908468559872u64,
      T.model_seed(), 0u64)
    f2 : U64 <- C.report_published("pos-len-cm",
      E.run(T.model_seed(), C.len_req(T.U_cm{}, 2.0f64, C.tol_good(), C.bud2(),
        64u64, False{})),
      4626322717216342016u64, T.model_seed(), f1)
    f3 : U64 <- C.report_published("pos-len-inch",
      E.run(T.model_seed(), C.len_req(T.U_in{}, 1.0f64, C.tol_good(), C.bud2(),
        64u64, False{})),
      4627842682090579558u64, T.model_seed(), f2)
    f4 : U64 <- report_negzero("pos-len-negzero",
      E.run(T.model_seed(), C.len_req(T.U_mm{}, F64{9223372036854775808u64},
        C.tol_good(), C.bud2(), 64u64, False{})),
      T.model_seed(), f3)
    f5 : U64 <- C.report_published("pos-isect-overlap",
      E.run(T.model_seed(), C.isect_req(T.U_mm{}, 0.0f64, 10.0f64, 5.0f64,
        15.0f64, C.tol_good(), C.bud2(), 64u64, False{})),
      4617315517961601024u64, T.model_seed(), f4)
    f6 : U64 <- C.report_published("pos-isect-touch",
      E.run(T.model_seed(), C.isect_req(T.U_mm{}, 0.0f64, 5.0f64, 5.0f64,
        10.0f64, C.tol_good(), C.bud2(), 64u64, False{})),
      4617315517961601024u64, T.model_seed(), f5)
    f7 : U64 <- C.report_empty("pos-isect-empty",
      E.run(T.model_seed(), req_empty()), T.model_seed(), f6)
    f8 : U64 <- C.report_pure("pos-empty-attributed",
      U64.is_eq(E.outcome_op(E.run(T.model_seed(), req_empty())),
        E.op_id(req_empty())), f7)
    f9 : U64 <- C.report_pure("pos-opid-deterministic",
      U64.is_eq(E.op_id(req_len_m()), E.op_id(req_len_m())), f8)
    f10 : U64 <- C.report_pure("pos-opid-content-sensitive",
      Bool.not(U64.is_eq(E.op_id(req_len_m()), E.op_id(req_len_m3()))), f9)
    f11 : U64 <- C.report_pure("pos-opid-ignores-fuel",
      U64.is_eq(E.op_id(E.set_fuel(req_len_m(), 2u64)),
        E.op_id(E.set_fuel(req_len_m(), 9u64))), f10)
    f12 : U64 <- C.report_pure("pos-opid-ignores-cancel",
      U64.is_eq(E.op_id(E.cancel_req(req_len_m())), E.op_id(req_len_m())),
      f11)
    f13 : U64 <- C.report_pure("pos-opid-unit-sensitive",
      Bool.not(U64.is_eq(E.op_id(req_len_m()), E.op_id(req_len_cm()))), f12)
    IO.print("selfcheck fails=" ++ U64.show(f13))
