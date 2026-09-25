# C00 test support: shared fixtures, pure verdicts, line reporting.
# Imported by neg.bend and positive.bend; no main here.

import Base
import ../../src/c00/types.bend as T
import ../../src/c00/eval.bend as E

# --- Fixtures ---
def tol_good() -> T.Tol:
  T.mk_tol(0.001f64, 0.0001f64, 0.00001f64, 0.01f64, 0.1f64)

def bud2() -> T.Budget:
  T.mk_budget(2u64, 1000000u64)

def bud_fuel(f: U64) -> T.Budget:
  T.mk_budget(f, 1000000u64)

def len_req(u: T.LenUnit, p0: F64, tol: T.Tol, b: T.Budget, n: U64,
    cx: Bool) -> T.Request:
  T.mk_request(T.K_len{}, u, p0, 0.0f64, 0.0f64, 0.0f64, 7u64, tol, b, n, cx)

def isect_req(u: T.LenUnit, a: F64, b: F64, c: F64, d: F64, tol: T.Tol,
    g: T.Budget, n: U64, cx: Bool) -> T.Request:
  T.mk_request(T.K_isect{}, u, a, b, c, d, 7u64, tol, g, n, cx)

def unk_req(tag: U64, tol: T.Tol, b: T.Budget, n: U64, cx: Bool) -> T.Request:
  T.mk_request(T.K_unknown{tag}, T.U_mm{}, 1.0f64, 0.0f64, 0.0f64, 0.0f64,
    7u64, tol, b, n, cx)

# --- Pure verdicts ---
def failed_as_go(o: T.Outcome, ok: Bool) -> Bool:
  match o:
    case T.Failed{kind, model, op}: ok
    case T.Ok{model, status, op}: False{}
    case T.Incomplete{op, fuel_used, model}: False{}

def failed_as(+o: T.Outcome, want: String, pre: T.Model) -> Bool:
  failed_as_go(o,
    Bool.and(String.eq(E.outcome_show(o), want),
      T.model_equal(E.outcome_model(o), pre)))

def incomplete_as_go(o: T.Outcome, ok: Bool) -> Bool:
  match o:
    case T.Incomplete{op, fuel_used, model}: ok
    case T.Ok{model, status, op}: False{}
    case T.Failed{kind, model, op}: False{}

def incomplete_as(+o: T.Outcome, want_used: U64, want_op: U64,
    pre: T.Model) -> Bool:
  incomplete_as_go(o,
    Bool.and(U64.is_eq(E.outcome_fuel_used(o), want_used),
      Bool.and(U64.is_eq(E.outcome_op(o), want_op),
        T.model_equal(E.outcome_model(o), pre))))

def published_as_go(o: T.Outcome, want_bits: U64, +pre: T.Model, got: String,
    vbits: U64, +m: T.Model) -> Bool:
  match o:
    case T.Ok{model, status, op}:
      Bool.and(String.eq(got, "ok-value"),
        Bool.and(U64.is_eq(vbits, want_bits),
          Bool.and(
            U64.is_eq(T.model_rev(m), (T.model_rev(pre) + 1u64 : U64)),
            U64.is_eq(T.model_count(m), (T.model_count(pre) + 1u64 : U64)))))
    case T.Incomplete{op, fuel_used, model}: False{}
    case T.Failed{kind, model, op}: False{}

def published_as(+o: T.Outcome, want_bits: U64, pre: T.Model) -> Bool:
  published_as_go(o, want_bits, pre, E.outcome_show(o),
    F64.bits(E.outcome_value(o)), E.outcome_model(o))

def empty_as_go(o: T.Outcome, got: String, m: T.Model, pre: T.Model) -> Bool:
  match o:
    case T.Ok{model, status, op}:
      Bool.and(String.eq(got, "ok-empty"), T.model_equal(m, pre))
    case T.Incomplete{op, fuel_used, model}: False{}
    case T.Failed{kind, model, op}: False{}

def empty_as(+o: T.Outcome, pre: T.Model) -> Bool:
  empty_as_go(o, E.outcome_show(o), E.outcome_model(o), pre)

# --- Reporting (one run per test; verdicts recomputed, pure) ---
def verdict(ok: Bool) -> String:
  match ok:
    case True{}: "PASS"
    case False{}: "FAIL"

def bump(f: U64, ok: Bool) -> U64:
  (f + Bool.to_u64(Bool.not(ok)) : U64)

def report_failed(tag: String, +o: T.Outcome, +want: String, +pre: T.Model,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(failed_as(o, want, pre))
      ++ " [" ++ E.outcome_show(o) ++ "]")
    return bump(f, failed_as(o, want, pre))

def report_incomplete(tag: String, +o: T.Outcome, +want_used: U64,
    +want_op: U64, +pre: T.Model, f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(incomplete_as(o, want_used, want_op, pre))
      ++ " [" ++ E.outcome_show(o) ++ "]")
    return bump(f, incomplete_as(o, want_used, want_op, pre))

def report_published(tag: String, +o: T.Outcome, +want_bits: U64,
    +pre: T.Model, f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(published_as(o, want_bits, pre))
      ++ " [" ++ E.outcome_show(o) ++ "]")
    return bump(f, published_as(o, want_bits, pre))

def report_empty(tag: String, +o: T.Outcome, +pre: T.Model,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(empty_as(o, pre))
      ++ " [" ++ E.outcome_show(o) ++ "]")
    return bump(f, empty_as(o, pre))

def report_pure(tag: String, +ok: Bool, f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(ok))
    return bump(f, ok)
