import Base

import ../../src/c00/types.bend as T

import ../../src/c00/eval.bend as E

def tol_good() -> T.Tol:
  T.mk_tol(0.001f64, 0.0001f64, 0.00001f64, 0.01f64, 0.1f64)

def bud2() -> T.Budget:
  T.mk_budget(2u64, 1000000u64)

def req_len_ok() -> T.Request:
  T.mk_request(T.K_len{}, T.U_m{}, 2.0f64, 0.0f64, 0.0f64, 0.0f64, 7u64,
    tol_good(), bud2(), 64u64, False{})

def req_isect_hit() -> T.Request:
  T.mk_request(T.K_isect{}, T.U_mm{}, 0.0f64, 10.0f64, 5.0f64, 15.0f64, 7u64,
    tol_good(), bud2(), 64u64, False{})

def req_isect_miss() -> T.Request:
  T.mk_request(T.K_isect{}, T.U_mm{}, 0.0f64, 1.0f64, 5.0f64, 15.0f64, 7u64,
    tol_good(), bud2(), 64u64, False{})

def req_nan() -> T.Request:
  T.mk_request(T.K_len{}, T.U_mm{}, F64.nan(), 0.0f64, 0.0f64, 0.0f64, 7u64,
    tol_good(), bud2(), 64u64, False{})

def req_inftol() -> T.Request:
  T.mk_request(T.K_len{}, T.U_mm{}, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 7u64,
    T.mk_tol(F64{9218868437227405312u64}, 0.0001f64, 0.00001f64, 0.01f64,
      0.1f64), bud2(), 64u64, False{})

def req_neg() -> T.Request:
  T.mk_request(T.K_len{}, T.U_mm{}, F64.neg(1.0f64), 0.0f64, 0.0f64, 0.0f64,
    7u64, tol_good(), bud2(), 64u64, False{})

def req_ovf() -> T.Request:
  T.mk_request(T.K_len{}, T.U_m{}, F64{9218868437227405311u64}, 0.0f64,
    0.0f64, 0.0f64, 7u64, tol_good(), bud2(), 64u64, False{})

def req_unk() -> T.Request:
  T.mk_request(T.K_unknown{99u64}, T.U_mm{}, 1.0f64, 0.0f64, 0.0f64, 0.0f64,
    7u64, tol_good(), bud2(), 64u64, False{})

def req_badord() -> T.Request:
  T.mk_request(T.K_isect{}, T.U_mm{}, 10.0f64, 0.0f64, 5.0f64, 15.0f64, 7u64,
    tol_good(), bud2(), 64u64, False{})

def finite_accepts__got() -> Bool:
  Bool.and(T.is_finite(1.0f64), T.is_finite(0.0f64))

def finite_accepts__want() -> Bool:
  True{}

def finite_rejects__got() -> Bool:
  Bool.or(T.is_finite(F64.nan()), T.is_finite(F64{9218868437227405312u64}))

def finite_rejects__want() -> Bool:
  False{}

def unit_cm__got() -> U64:
  F64.bits(T.to_mm(T.U_cm{}, 2.0f64))

def unit_cm__want() -> U64:
  4626322717216342016u64

def unit_in__got() -> U64:
  F64.bits(T.to_mm(T.U_in{}, 1.0f64))

def unit_in__want() -> U64:
  4627842682090579558u64

def unit_m__got() -> U64:
  F64.bits(T.to_mm(T.U_m{}, 2.0f64))

def unit_m__want() -> U64:
  4656510908468559872u64

def taxonomy__got() -> Bool:
  Bool.and(String.eq(T.FailKind.show(T.F_invalid{}), "invalid-input"), Bool.and(String.eq(T.FailKind.show(T.F_unsupported{}), "unsupported-op"), Bool.and(String.eq(T.FailKind.show(T.F_uncertain{}), "numerical-uncertainty"), Bool.and(String.eq(T.FailKind.show(T.F_nonconverged{}), "nonconvergence"), Bool.and(String.eq(T.FailKind.show(T.F_cancelled{}), "cancelled"), String.eq(T.FailKind.show(T.F_exhausted{}), "resource-exhausted"))))))

def taxonomy__want() -> Bool:
  True{}

def fuel0_incomplete__got() -> String:
  E.outcome_show(E.run(T.model_seed(), E.set_fuel(req_len_ok(), 0u64)))

def fuel0_incomplete__want() -> String:
  "incomplete"

def fuel0_keeps_model__got() -> T.Model:
  E.outcome_model(E.run(T.model_seed(), E.set_fuel(req_len_ok(), 0u64)))

def fuel0_keeps_model__want() -> T.Model:
  T.model_seed()

def fuel1_incomplete__got() -> U64:
  E.outcome_fuel_used(E.run(T.model_seed(), E.set_fuel(req_len_ok(), 1u64)))

def fuel1_incomplete__want() -> U64:
  1u64

def fuel1_reports_invalid__got() -> String:
  E.outcome_show(E.run(T.model_seed(), E.set_fuel(req_nan(), 1u64)))

def fuel1_reports_invalid__want() -> String:
  "invalid-input"

def bytes_exhausted__got() -> String:
  E.outcome_show(E.run(T.model_seed(), E.set_bytes(req_len_ok(), 1000001u64)))

def bytes_exhausted__want() -> String:
  "resource-exhausted"

def bytes_keeps_model__got() -> T.Model:
  E.outcome_model(E.run(T.model_seed(), E.set_bytes(req_len_ok(), 1000001u64)))

def bytes_keeps_model__want() -> T.Model:
  T.model_seed()

def nan_rejected__got() -> String:
  E.outcome_show(E.run(T.model_seed(), req_nan()))

def nan_rejected__want() -> String:
  "invalid-input"

def nan_keeps_model__got() -> T.Model:
  E.outcome_model(E.run(T.model_seed(), req_nan()))

def nan_keeps_model__want() -> T.Model:
  T.model_seed()

def inftol_rejected__got() -> String:
  E.outcome_show(E.run(T.model_seed(), req_inftol()))

def inftol_rejected__want() -> String:
  "invalid-input"

def neg_rejected__got() -> String:
  E.outcome_show(E.run(T.model_seed(), req_neg()))

def neg_rejected__want() -> String:
  "invalid-input"

def badord_rejected__got() -> String:
  E.outcome_show(E.run(T.model_seed(), req_badord()))

def badord_rejected__want() -> String:
  "invalid-input"

def unknown_unsupported__got() -> String:
  E.outcome_show(E.run(T.model_seed(), req_unk()))

def unknown_unsupported__want() -> String:
  "unsupported-op"

def unknown_keeps_model__got() -> T.Model:
  E.outcome_model(E.run(T.model_seed(), req_unk()))

def unknown_keeps_model__want() -> T.Model:
  T.model_seed()

def overflow_uncertain__got() -> String:
  E.outcome_show(E.run(T.model_seed(), req_ovf()))

def overflow_uncertain__want() -> String:
  "numerical-uncertainty"

def overflow_keeps_model__got() -> T.Model:
  E.outcome_model(E.run(T.model_seed(), req_ovf()))

def overflow_keeps_model__want() -> T.Model:
  T.model_seed()

def len_publishes__got() -> String:
  E.outcome_show(E.run(T.model_seed(), req_len_ok()))

def len_publishes__want() -> String:
  "ok-value"

def len_value_bits__got() -> U64:
  F64.bits(E.outcome_value(E.run(T.model_seed(), req_len_ok())))

def len_value_bits__want() -> U64:
  4656510908468559872u64

def len_advances_rev__got() -> U64:
  T.model_rev(E.outcome_model(E.run(T.model_seed(), req_len_ok())))

def len_advances_rev__want() -> U64:
  1u64

def len_advances_count__got() -> U64:
  T.model_count(E.outcome_model(E.run(T.model_seed(), req_len_ok())))

def len_advances_count__want() -> U64:
  1u64

def len_checksum__got() -> U64:
  T.model_sum(E.outcome_model(E.run(T.model_seed(), req_len_ok())))

def len_checksum__want() -> U64:
  1099231252310917555u64

def empty_is_success__got() -> String:
  E.outcome_show(E.run(T.model_seed(), req_isect_miss()))

def empty_is_success__want() -> String:
  "ok-empty"

def empty_keeps_model__got() -> T.Model:
  E.outcome_model(E.run(T.model_seed(), req_isect_miss()))

def empty_keeps_model__want() -> T.Model:
  T.model_seed()

def empty_attributed__got() -> U64:
  E.outcome_op(E.run(T.model_seed(), req_isect_miss()))

def empty_attributed__want() -> U64:
  E.op_id(req_isect_miss())

def isect_hit_value__got() -> U64:
  F64.bits(E.outcome_value(E.run(T.model_seed(), req_isect_hit())))

def isect_hit_value__want() -> U64:
  4617315517961601024u64

def isect_hit_rev__got() -> U64:
  T.model_rev(E.outcome_model(E.run(T.model_seed(), req_isect_hit())))

def isect_hit_rev__want() -> U64:
  1u64

def failed_attributed__got() -> U64:
  E.outcome_op(E.run(T.model_seed(), req_nan()))

def failed_attributed__want() -> U64:
  E.op_id(req_nan())

def incomplete_attributed__got() -> U64:
  E.outcome_op(E.run(T.model_seed(), E.set_fuel(req_len_ok(), 0u64)))

def incomplete_attributed__want() -> U64:
  E.op_id(req_len_ok())
