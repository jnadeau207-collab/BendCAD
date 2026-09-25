# C00 laws: every claim closed by the proof beneath it. Bend rejects open
# laws ("1 TODO found" fails the check), so the unbounded general claims live
# as explicit numbered laws in docs/c00-contract.md; this file proves each
# pipeline arm's routing, attribution, and atomicity instance, plus three
# fully general laws (cancel_atomic, opid_excludes_*). Pins: F64 bit patterns
# from python struct; FNV goldens cross-checked in python (see contract doc).

import Base
import ../src/c00/types.bend as T
import ../src/c00/eval.bend as E

# --- Fixtures ---
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

# --- Boundary classifier + normalization ---
law finite_accepts:
  {Bool.and(T.is_finite(1.0f64), T.is_finite(0.0f64)) == True{} : Bool}

def finite_accepts():
  {==}

law finite_rejects:
  {Bool.or(T.is_finite(F64.nan()), T.is_finite(F64{9218868437227405312u64}))
    == False{} : Bool}

def finite_rejects():
  {==}

law unit_cm:
  {F64.bits(T.to_mm(T.U_cm{}, 2.0f64)) == 4626322717216342016u64 : U64}

def unit_cm():
  {==}

law unit_in:
  {F64.bits(T.to_mm(T.U_in{}, 1.0f64)) == 4627842682090579558u64 : U64}

def unit_in():
  {==}

law unit_m:
  {F64.bits(T.to_mm(T.U_m{}, 2.0f64)) == 4656510908468559872u64 : U64}

def unit_m():
  {==}

law taxonomy:
  {Bool.and(String.eq(T.FailKind.show(T.F_invalid{}), "invalid-input"),
    Bool.and(String.eq(T.FailKind.show(T.F_unsupported{}), "unsupported-op"),
    Bool.and(String.eq(T.FailKind.show(T.F_uncertain{}),
      "numerical-uncertainty"),
    Bool.and(String.eq(T.FailKind.show(T.F_nonconverged{}), "nonconvergence"),
    Bool.and(String.eq(T.FailKind.show(T.F_cancelled{}), "cancelled"),
      String.eq(T.FailKind.show(T.F_exhausted{}),
        "resource-exhausted")))))) == True{} : Bool}

def taxonomy():
  {==}

# --- Cancellation: general over every model and request ---
law cancel_atomic:
  for m: T.Model
  for r: T.Request
  {E.outcome_model(E.run(m, E.cancel_req(r))) == m : T.Model}

def cancel_atomic(m, r):
  match r:
    case T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cx}:
      {==}

law cancel_explicit:
  for r: T.Request
  {E.outcome_show(E.run(T.model_seed(), E.cancel_req(r))) == "cancelled"
    : String}

def cancel_explicit(r):
  match r:
    case T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cx}:
      {==}

# --- Fuel exhaustion: explicit incomplete, never trusted geometry ---
law fuel0_incomplete:
  {E.outcome_show(E.run(T.model_seed(), E.set_fuel(req_len_ok(), 0u64)))
    == "incomplete" : String}

def fuel0_incomplete():
  {==}

law fuel0_keeps_model:
  {E.outcome_model(E.run(T.model_seed(), E.set_fuel(req_len_ok(), 0u64)))
    == T.model_seed() : T.Model}

def fuel0_keeps_model():
  {==}

law fuel1_incomplete:
  {E.outcome_fuel_used(E.run(T.model_seed(), E.set_fuel(req_len_ok(), 1u64)))
    == 1u64 : U64}

def fuel1_incomplete():
  {==}

law fuel1_reports_invalid:
  {E.outcome_show(E.run(T.model_seed(), E.set_fuel(req_nan(), 1u64)))
    == "invalid-input" : String}

def fuel1_reports_invalid():
  {==}

# --- Byte budget ---
law bytes_exhausted:
  {E.outcome_show(E.run(T.model_seed(), E.set_bytes(req_len_ok(), 1000001u64)))
    == "resource-exhausted" : String}

def bytes_exhausted():
  {==}

law bytes_keeps_model:
  {E.outcome_model(E.run(T.model_seed(), E.set_bytes(req_len_ok(), 1000001u64)))
    == T.model_seed() : T.Model}

def bytes_keeps_model():
  {==}

# --- Nonfinite + malformed rejection, each with atomicity ---
law nan_rejected:
  {E.outcome_show(E.run(T.model_seed(), req_nan())) == "invalid-input"
    : String}

def nan_rejected():
  {==}

law nan_keeps_model:
  {E.outcome_model(E.run(T.model_seed(), req_nan())) == T.model_seed()
    : T.Model}

def nan_keeps_model():
  {==}

law inftol_rejected:
  {E.outcome_show(E.run(T.model_seed(), req_inftol())) == "invalid-input"
    : String}

def inftol_rejected():
  {==}

law neg_rejected:
  {E.outcome_show(E.run(T.model_seed(), req_neg())) == "invalid-input"
    : String}

def neg_rejected():
  {==}

law badord_rejected:
  {E.outcome_show(E.run(T.model_seed(), req_badord())) == "invalid-input"
    : String}

def badord_rejected():
  {==}

law unknown_unsupported:
  {E.outcome_show(E.run(T.model_seed(), req_unk())) == "unsupported-op"
    : String}

def unknown_unsupported():
  {==}

law unknown_keeps_model:
  {E.outcome_model(E.run(T.model_seed(), req_unk())) == T.model_seed()
    : T.Model}

def unknown_keeps_model():
  {==}

# --- Normalization overflow: uncertainty, never trusted geometry ---
law overflow_uncertain:
  {E.outcome_show(E.run(T.model_seed(), req_ovf()))
    == "numerical-uncertainty" : String}

def overflow_uncertain():
  {==}

law overflow_keeps_model:
  {E.outcome_model(E.run(T.model_seed(), req_ovf())) == T.model_seed()
    : T.Model}

def overflow_keeps_model():
  {==}

# --- Publication: once, with the exact witness and revision ---
law len_publishes:
  {E.outcome_show(E.run(T.model_seed(), req_len_ok())) == "ok-value" : String}

def len_publishes():
  {==}

law len_value_bits:
  {F64.bits(E.outcome_value(E.run(T.model_seed(), req_len_ok())))
    == 4656510908468559872u64 : U64}

def len_value_bits():
  {==}

law len_advances_rev:
  {T.model_rev(E.outcome_model(E.run(T.model_seed(), req_len_ok()))) == 1u64
    : U64}

def len_advances_rev():
  {==}

law len_advances_count:
  {T.model_count(E.outcome_model(E.run(T.model_seed(), req_len_ok()))) == 1u64
    : U64}

def len_advances_count():
  {==}

law len_checksum:
  {T.model_sum(E.outcome_model(E.run(T.model_seed(), req_len_ok())))
    == 1099231252310917555u64 : U64}

def len_checksum():
  {==}

# --- Empty intersection: success, distinctly, with the model unchanged ---
law empty_is_success:
  {E.outcome_show(E.run(T.model_seed(), req_isect_miss())) == "ok-empty"
    : String}

def empty_is_success():
  {==}

law empty_keeps_model:
  {E.outcome_model(E.run(T.model_seed(), req_isect_miss())) == T.model_seed()
    : T.Model}

def empty_keeps_model():
  {==}

law empty_attributed:
  {E.outcome_op(E.run(T.model_seed(), req_isect_miss()))
    == E.op_id(req_isect_miss()) : U64}

def empty_attributed():
  {==}

law isect_hit_value:
  {F64.bits(E.outcome_value(E.run(T.model_seed(), req_isect_hit())))
    == 4617315517961601024u64 : U64}

def isect_hit_value():
  {==}

law isect_hit_rev:
  {T.model_rev(E.outcome_model(E.run(T.model_seed(), req_isect_hit()))) == 1u64
    : U64}

def isect_hit_rev():
  {==}

# --- Op identity excludes execution inputs: general over every request ---
law opid_excludes_fuel:
  for r: T.Request
  for a: U64
  for b: U64
  {E.op_id(E.set_fuel(r, a)) == E.op_id(E.set_fuel(r, b)) : U64}

def opid_excludes_fuel(r, a, b):
  match r:
    case T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cx}:
      match budget:
        case T.Budget{fuel, max_bytes}:
          {==}

law opid_excludes_cancel:
  for r: T.Request
  {E.op_id(E.cancel_req(r)) == E.op_id(r) : U64}

def opid_excludes_cancel(r):
  match r:
    case T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cx}:
      {==}

law opid_excludes_bytes:
  for r: T.Request
  for a: U64
  for b: U64
  {E.op_id(E.set_bytes(r, a)) == E.op_id(E.set_bytes(r, b)) : U64}

def opid_excludes_bytes(r, a, b):
  match r:
    case T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cx}:
      {==}

# --- Attribution: every outcome carries its request's id ---
law failed_attributed:
  {E.outcome_op(E.run(T.model_seed(), req_nan())) == E.op_id(req_nan()) : U64}

def failed_attributed():
  {==}

law incomplete_attributed:
  {E.outcome_op(E.run(T.model_seed(), E.set_fuel(req_len_ok(), 0u64)))
    == E.op_id(req_len_ok()) : U64}

def incomplete_attributed():
  {==}
