# C00 negative tests: every failure path asserts its structured kind AND
# zero publication (accepted model unchanged). Ends in selfcheck fails=N.

import Base
import ../../src/c00/types.bend as T
import ../../src/c00/eval.bend as E
import ./check.bend as C

def tol_zero_lin() -> T.Tol:
  T.mk_tol(0.0f64, 0.0001f64, 0.00001f64, 0.01f64, 0.1f64)

def tol_inf_lin() -> T.Tol:
  T.mk_tol(F64{9218868437227405312u64}, 0.0001f64, 0.00001f64, 0.01f64, 0.1f64)

def req_ninf_slot() -> T.Request:
  T.mk_request(T.K_len{}, T.U_mm{}, 1.0f64, 0.0f64, 0.0f64,
    F64{18442240474082181120u64}, 7u64, C.tol_good(), C.bud2(), 64u64, False{})

def req_fuel0() -> T.Request:
  C.len_req(T.U_mm{}, 1.0f64, C.tol_good(), C.bud_fuel(0u64), 64u64, False{})

def req_fuel1() -> T.Request:
  C.len_req(T.U_mm{}, 1.0f64, C.tol_good(), C.bud_fuel(1u64), 64u64, False{})

def main() -> IO(Unit):
  do IO<Unit>:
    f1 : U64 <- C.report_failed("neg-length",
      E.run(T.model_seed(), C.len_req(T.U_mm{}, F64.neg(1.0f64), C.tol_good(),
        C.bud2(), 64u64, False{})),
      "invalid-input", T.model_seed(), 0u64)
    f2 : U64 <- C.report_failed("neg-bad-interval",
      E.run(T.model_seed(), C.isect_req(T.U_mm{}, 10.0f64, 0.0f64, 5.0f64,
        15.0f64, C.tol_good(), C.bud2(), 64u64, False{})),
      "invalid-input", T.model_seed(), f1)
    f3 : U64 <- C.report_failed("neg-zero-tol",
      E.run(T.model_seed(), C.len_req(T.U_mm{}, 1.0f64, tol_zero_lin(),
        C.bud2(), 64u64, False{})),
      "invalid-input", T.model_seed(), f2)
    f4 : U64 <- C.report_failed("neg-inf-tol",
      E.run(T.model_seed(), C.len_req(T.U_mm{}, 1.0f64, tol_inf_lin(),
        C.bud2(), 64u64, False{})),
      "invalid-input", T.model_seed(), f3)
    f5 : U64 <- C.report_failed("neg-nan-param",
      E.run(T.model_seed(), C.len_req(T.U_mm{}, F64.nan(), C.tol_good(),
        C.bud2(), 64u64, False{})),
      "invalid-input", T.model_seed(), f4)
    f6 : U64 <- C.report_failed("neg-inf-param",
      E.run(T.model_seed(), C.len_req(T.U_mm{}, F64{9218868437227405312u64},
        C.tol_good(), C.bud2(), 64u64, False{})),
      "invalid-input", T.model_seed(), f5)
    f7 : U64 <- C.report_failed("neg-ninf-unused-slot",
      E.run(T.model_seed(), req_ninf_slot()),
      "invalid-input", T.model_seed(), f6)
    f8 : U64 <- C.report_failed("neg-cancelled",
      E.run(T.model_seed(), C.len_req(T.U_mm{}, 1.0f64, C.tol_good(), C.bud2(),
        64u64, True{})),
      "cancelled", T.model_seed(), f7)
    f9 : U64 <- C.report_failed("neg-cancel-beats-malformed",
      E.run(T.model_seed(), C.len_req(T.U_mm{}, F64.nan(), C.tol_good(),
        C.bud2(), 64u64, True{})),
      "cancelled", T.model_seed(), f8)
    f10 : U64 <- C.report_incomplete("neg-fuel-zero",
      E.run(T.model_seed(), req_fuel0()), 0u64, E.op_id(req_fuel0()),
      T.model_seed(), f9)
    f11 : U64 <- C.report_incomplete("neg-fuel-one",
      E.run(T.model_seed(), req_fuel1()), 1u64, E.op_id(req_fuel1()),
      T.model_seed(), f10)
    f12 : U64 <- C.report_failed("neg-fuel-one-reports-invalid",
      E.run(T.model_seed(), C.len_req(T.U_mm{}, F64.nan(), C.tol_good(),
        C.bud_fuel(1u64), 64u64, False{})),
      "invalid-input", T.model_seed(), f11)
    f13 : U64 <- C.report_failed("neg-bytes-over",
      E.run(T.model_seed(), C.len_req(T.U_mm{}, 1.0f64, C.tol_good(), C.bud2(),
        1000001u64, False{})),
      "resource-exhausted", T.model_seed(), f12)
    f14 : U64 <- C.report_failed("neg-unsupported",
      E.run(T.model_seed(), C.unk_req(99u64, C.tol_good(), C.bud2(), 64u64,
        False{})),
      "unsupported-op", T.model_seed(), f13)
    f15 : U64 <- C.report_failed("neg-unsupported-zero-tag",
      E.run(T.model_seed(), C.unk_req(0u64, C.tol_good(), C.bud2(), 64u64,
        False{})),
      "unsupported-op", T.model_seed(), f14)
    f16 : U64 <- C.report_failed("neg-overflow-uncertain",
      E.run(T.model_seed(), C.len_req(T.U_m{}, F64{9218868437227405311u64},
        C.tol_good(), C.bud2(), 64u64, False{})),
      "numerical-uncertainty", T.model_seed(), f15)
    IO.print("selfcheck fails=" ++ U64.show(f16))
