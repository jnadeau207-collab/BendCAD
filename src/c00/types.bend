import Base

type LenUnit is Data:
  U_mm{}
  U_cm{}
  U_m{}
  U_in{}

def unit_tag(u: LenUnit) -> U64:
  match u:
    case U_mm{}: 0u64
    case U_cm{}: 1u64
    case U_m{}: 2u64
    case U_in{}: 3u64

def unit_scale_mm(u: LenUnit) -> F64:
  match u:
    case U_mm{}: 1.0f64
    case U_cm{}: 10.0f64
    case U_m{}: 1000.0f64
    case U_in{}: 25.4f64

def to_mm(u: LenUnit, x: F64) -> F64:
  F64.mul(x, unit_scale_mm(u))

def is_finite(x: F64) -> Bool:
  (F64.class(x) < 2 : U32)

type Tol is Data:
  Tol{ lin: F64, ang: F64, par: F64, apx: F64, imp: F64 }

def mk_tol(lin: F64, ang: F64, par: F64, apx: F64, imp: F64) -> Tol:
  Tol{lin, ang, par, apx, imp}

def tol_pos(+x: F64) -> Bool:
  Bool.and(is_finite(x), F64.is_lt(0.0f64, x))

def tol_ok(t: Tol) -> Bool:
  Tol{lin, ang, par, apx, imp} = t
  Bool.and(tol_pos(lin),
    Bool.and(tol_pos(ang),
      Bool.and(tol_pos(par), Bool.and(tol_pos(apx), tol_pos(imp)))))

type Budget is Data:
  Budget{ fuel: U64, max_bytes: U64 }

def mk_budget(fuel: U64, max_bytes: U64) -> Budget:
  Budget{fuel, max_bytes}

type OpKind is Data:
  K_len{}
  K_isect{}
  K_unknown{ tag: U64 }

def op_tag(k: OpKind) -> U64:
  match k:
    case K_len{}: 1u64
    case K_isect{}: 2u64
    case K_unknown{tag}: 3u64

def op_xtra(k: OpKind) -> U64:
  match k:
    case K_len{}: 0u64
    case K_isect{}: 0u64
    case K_unknown{tag}: tag

type Request is Data:
  Request{ op: OpKind, unit: LenUnit, p0: F64, p1: F64, p2: F64, p3: F64,
    rev: U64, tol: Tol, budget: Budget, bytes: U64, cancelled: Bool }

def mk_request(op: OpKind, unit: LenUnit, p0: F64, p1: F64, p2: F64, p3: F64,
    rev: U64, tol: Tol, budget: Budget, bytes: U64, cancelled: Bool) -> Request:
  Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled}

type FailKind is Data:
  F_invalid{}
  F_unsupported{}
  F_uncertain{}
  F_nonconverged{}
  F_cancelled{}
  F_exhausted{}

def FailKind.show(f: FailKind) -> String:
  match f:
    case F_invalid{}: "invalid-input"
    case F_unsupported{}: "unsupported-op"
    case F_uncertain{}: "numerical-uncertainty"
    case F_nonconverged{}: "nonconvergence"
    case F_cancelled{}: "cancelled"
    case F_exhausted{}: "resource-exhausted"

type Success is Data:
  S_value{ value: F64 }
  S_empty{}

def mk_s_value(v: F64) -> Success:
  S_value{v}

def mk_s_empty() -> Success:
  S_empty{}

type Model is Data:
  Model{ rev: U64, count: U64, sum: U64 }

def mk_model(rev: U64, count: U64, sum: U64) -> Model:
  Model{rev, count, sum}

def model_seed() -> Model:
  Model{0u64, 0u64, 0u64}

def model_rev(m: Model) -> U64:
  Model{rev, count, sum} = m
  rev

def model_count(m: Model) -> U64:
  Model{rev, count, sum} = m
  count

def model_sum(m: Model) -> U64:
  Model{rev, count, sum} = m
  sum

def model_equal(a: Model, b: Model) -> Bool:
  Model{ra, ca, sa} = a
  Model{rb, cb, sb} = b
  Bool.and(U64.is_eq(ra, rb), Bool.and(U64.is_eq(ca, cb), U64.is_eq(sa, sb)))

type Candidate is Data:
  Cand{ value: F64, tag: U64 }

type Outcome is Data:
  Ok{ model: Model, status: Success, op: U64 }
  Incomplete{ op: U64, fuel_used: U64, model: Model }
  Failed{ kind: FailKind, model: Model, op: U64 }

def mk_ok(model: Model, status: Success, op: U64) -> Outcome:
  Ok{model, status, op}

def mk_incomplete(op: U64, fuel_used: U64, model: Model) -> Outcome:
  Incomplete{op, fuel_used, model}

def mk_failed(kind: FailKind, model: Model, op: U64) -> Outcome:
  Failed{kind, model, op}
