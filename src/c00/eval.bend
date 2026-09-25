# C00 evaluator: input boundary, fuel threading, op identity, atomic publish.
# No @unsafe anywhere: fuel exhaustion yields Incomplete, never trusted geometry.
# Defs precede uses (Bend has no forward references), so the pipeline reads
# leaf-first; entry point `run` is near the end.

import Base
import ./types.bend as T

# Deterministic op identity: FNV-1a over CONTENT words (op, unit, params,
# input revision, tolerances). Fuel/bytes/cancellation are execution, not
# content, and are excluded — re-running with more fuel yields the same id
# (legacy operation-hash.ts `excludedKeys`). Identity, not a crypto commitment.
def mix(h: U64, x: U64) -> U64:
  ((h .^. x : U64) * 1099511628211u64 : U64)

def fnv_off() -> U64:
  14695981039346656037u64

def op_version() -> U64:
  2048u64

def op_id_of(+op: T.OpKind, u: T.LenUnit, p0: F64, p1: F64, p2: F64,
    p3: F64, rev: U64, t: T.Tol) -> U64:
  T.Tol{lin, ang, par, apx, imp} = t
  h0 = mix(fnv_off(), op_version())
  h1 = mix(h0, T.op_tag(op))
  h2 = mix(h1, T.op_xtra(op))
  h3 = mix(h2, T.unit_tag(u))
  h4 = mix(h3, F64.bits(p0))
  h5 = mix(h4, F64.bits(p1))
  h6 = mix(h5, F64.bits(p2))
  h7 = mix(h6, F64.bits(p3))
  h8 = mix(h7, rev)
  h9 = mix(h8, F64.bits(lin))
  h10 = mix(h9, F64.bits(ang))
  h11 = mix(h10, F64.bits(par))
  h12 = mix(h11, F64.bits(apx))
  mix(h12, F64.bits(imp))

def op_id(r: T.Request) -> U64:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  op_id_of(op, unit, p0, p1, p2, p3, rev, tol)

# Request re-binders for laws/tests: each changes one execution input.
def cancel_req(r: T.Request) -> T.Request:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  T.mk_request(op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, True{})

def set_fuel(r: T.Request, f: U64) -> T.Request:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  T.Budget{fuel, max_bytes} = budget
  T.mk_request(op, unit, p0, p1, p2, p3, rev, tol, T.mk_budget(f, max_bytes),
    bytes, cancelled)

def set_bytes(r: T.Request, b: U64) -> T.Request:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  T.mk_request(op, unit, p0, p1, p2, p3, rev, tol, budget, b, cancelled)

# Boundary getters: each projects one verdict; stages match on it via _go
# (Bend matches params/fields only, never computed values).
def req_cancelled(r: T.Request) -> Bool:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  cancelled

def bytes_over(r: T.Request) -> Bool:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  T.Budget{fuel, max_bytes} = budget
  (max_bytes < bytes : U64)

def req_fuel(r: T.Request) -> U64:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  T.Budget{fuel, max_bytes} = budget
  fuel

def req_tol_ok(r: T.Request) -> Bool:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  T.tol_ok(tol)

def req_params_finite(r: T.Request) -> Bool:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  Bool.and(T.is_finite(p0),
    Bool.and(T.is_finite(p1),
      Bool.and(T.is_finite(p2), T.is_finite(p3))))

def req_boundary_ok(+r: T.Request) -> Bool:
  Bool.and(req_tol_ok(r), req_params_finite(r))

def req_op(r: T.Request) -> T.OpKind:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  op

def req_tag(r: T.Request) -> U64:
  T.op_tag(req_op(r))

# K_len witnesses: p0 as a normalized mm length. Normalization can overflow
# to +Inf (finite × finite); the candidate is re-validated downstream.
def len_value(r: T.Request) -> F64:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  T.to_mm(unit, p0)

def len_neg(r: T.Request) -> Bool:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  F64.is_lt(p0, 0.0f64)

def len_fin(r: T.Request) -> Bool:
  T.is_finite(len_value(r))

# K_isect witnesses: both intervals normalized to mm.
def isect_a0(r: T.Request) -> F64:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  T.to_mm(unit, p0)

def isect_a1(r: T.Request) -> F64:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  T.to_mm(unit, p1)

def isect_b0(r: T.Request) -> F64:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  T.to_mm(unit, p2)

def isect_b1(r: T.Request) -> F64:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  T.to_mm(unit, p3)

def isect_bad_ord(r: T.Request) -> Bool:
  T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cancelled} = r
  Bool.or(F64.is_lt(p1, p0), F64.is_lt(p3, p2))

def isect_all_fin(+r: T.Request) -> Bool:
  Bool.and(T.is_finite(isect_a0(r)),
    Bool.and(T.is_finite(isect_a1(r)),
      Bool.and(T.is_finite(isect_b0(r)), T.is_finite(isect_b1(r)))))

# Atomic publication: the candidate never escapes. Success builds the next
# model revision (rev+1, count+1, folded checksum) in one pure step; every
# other arm returns the input model untouched.
def publish(m: T.Model, id: U64, +v: F64, tag: U64) -> T.Outcome:
  T.Model{rev, count, sum} = m
  T.mk_ok(T.mk_model((rev + 1u64 : U64), (count + 1u64 : U64),
    mix(mix(sum, F64.bits(v)), tag)), T.mk_s_value(v), id)

# K_isect: overlap of [p0,p1] and [p2,p3] in `unit`. Malformed intervals
# (lo > hi) are invalid input. Normalization overflow is uncertainty. A
# disjoint pair is S_empty SUCCESS with the model unchanged; otherwise the
# published witness is the overlap's lower bound.
def ex_isect_mty(m: T.Model, id: U64, lo: F64, hi: F64, empty: Bool,
    tag: U64) -> T.Outcome:
  match empty:
    case True{}:
      T.mk_ok(m, T.mk_s_empty(), id)
    case False{}:
      publish(m, id, lo, tag)

def ex_isect_fin(m: T.Model, id: U64, +a0: F64, +a1: F64, +b0: F64, +b1: F64,
    fin: Bool, tag: U64) -> T.Outcome:
  match fin:
    case True{}:
      ex_isect_mty(m, id, F64.max(a0, b0), F64.min(a1, b1),
        F64.is_lt(F64.min(a1, b1), F64.max(a0, b0)), tag)
    case False{}:
      T.mk_failed(T.F_uncertain{}, m, id)

def ex_isect_ord(m: T.Model, +r: T.Request, id: U64, bad: Bool) -> T.Outcome:
  match bad:
    case True{}:
      T.mk_failed(T.F_invalid{}, m, id)
    case False{}:
      ex_isect_fin(m, id, isect_a0(r), isect_a1(r), isect_b0(r), isect_b1(r),
        isect_all_fin(r), req_tag(r))

def ex_isect(m: T.Model, +r: T.Request, id: U64) -> T.Outcome:
  ex_isect_ord(m, r, id, isect_bad_ord(r))

# K_len: transport one length through the boundary. p0 must be a finite
# non-negative length in `unit` (-0.0 counts as zero); the published witness
# is its mm value. Overflow fails as numerical uncertainty, never as trusted
# geometry.
def ex_len_fin(m: T.Model, id: U64, +v: F64, fin: Bool,
    tag: U64) -> T.Outcome:
  match fin:
    case True{}:
      publish(m, id, v, tag)
    case False{}:
      T.mk_failed(T.F_uncertain{}, m, id)

def ex_len_neg(m: T.Model, +r: T.Request, id: U64, neg: Bool) -> T.Outcome:
  match neg:
    case True{}:
      T.mk_failed(T.F_invalid{}, m, id)
    case False{}:
      ex_len_fin(m, id, len_value(r), len_fin(r), req_tag(r))

def ex_len(m: T.Model, +r: T.Request, id: U64) -> T.Outcome:
  ex_len_neg(m, r, id, len_neg(r))

def st_dispatch(m: T.Model, +r: T.Request, id: U64, k: T.OpKind) -> T.Outcome:
  match k:
    case T.K_len{}:
      ex_len(m, r, id)
    case T.K_isect{}:
      ex_isect(m, r, id)
    case T.K_unknown{tag}:
      T.mk_failed(T.F_unsupported{}, m, id)

def st_fuel1_go(m: T.Model, +r: T.Request, id: U64, one: Bool) -> T.Outcome:
  match one:
    case True{}:
      T.mk_incomplete(id, 1u64, m)
    case False{}:
      st_dispatch(m, r, id, req_op(r))

def st_fuel1(m: T.Model, +r: T.Request, id: U64, fuel: U64) -> T.Outcome:
  st_fuel1_go(m, r, id, U64.is_eq(fuel, 1u64))

def st_boundary(m: T.Model, +r: T.Request, id: U64, ok: Bool) -> T.Outcome:
  match ok:
    case True{}:
      st_fuel1(m, r, id, req_fuel(r))
    case False{}:
      T.mk_failed(T.F_invalid{}, m, id)

def st_fuel0(m: T.Model, +r: T.Request, id: U64, fuel: U64) -> T.Outcome:
  match fuel:
    case 0u64:
      T.mk_incomplete(id, 0u64, m)
    case _:
      st_boundary(m, r, id, req_boundary_ok(r))

def st_bytes(m: T.Model, +r: T.Request, id: U64, over: Bool) -> T.Outcome:
  match over:
    case True{}:
      T.mk_failed(T.F_exhausted{}, m, id)
    case False{}:
      st_fuel0(m, r, id, req_fuel(r))

def run_cancel(m: T.Model, +r: T.Request, id: U64,
    cancelled: Bool) -> T.Outcome:
  match cancelled:
    case True{}:
      T.mk_failed(T.F_cancelled{}, m, id)
    case False{}:
      st_bytes(m, r, id, bytes_over(r))

# Pipeline entry, total order (first match wins): cancellation → byte budget
# → fuel floor → content validation → fuel for the op → dispatch → candidate
# validation → publish. Fuel 0 starves the boundary (nothing inspected,
# nothing published); fuel 1 pays for the boundary and reports what it
# learned (invalid input is reported, never masked as incomplete); fuel ≥ 2
# runs the op.
def run(+m: T.Model, +r: T.Request) -> T.Outcome:
  run_cancel(m, r, op_id(r), req_cancelled(r))

# Outcome projectors for laws/tests. `outcome_value` is meaningful only for
# ok-value and `outcome_fuel_used` only for incomplete; both return a
# documented zero elsewhere so they stay total.
def status_show(s: T.Success) -> String:
  match s:
    case T.S_value{value}: "ok-value"
    case T.S_empty{}: "ok-empty"

def outcome_show(o: T.Outcome) -> String:
  match o:
    case T.Ok{model, status, op}: status_show(status)
    case T.Incomplete{op, fuel_used, model}: "incomplete"
    case T.Failed{kind, model, op}: T.FailKind.show(kind)

def outcome_model(o: T.Outcome) -> T.Model:
  match o:
    case T.Ok{model, status, op}: model
    case T.Incomplete{op, fuel_used, model}: model
    case T.Failed{kind, model, op}: model

def outcome_op(o: T.Outcome) -> U64:
  match o:
    case T.Ok{model, status, op}: op
    case T.Incomplete{op, fuel_used, model}: op
    case T.Failed{kind, model, op}: op

def status_value(s: T.Success) -> F64:
  match s:
    case T.S_value{value}: value
    case T.S_empty{}: 0.0f64

def outcome_value(o: T.Outcome) -> F64:
  match o:
    case T.Ok{model, status, op}: status_value(status)
    case T.Incomplete{op, fuel_used, model}: 0.0f64
    case T.Failed{kind, model, op}: 0.0f64

def outcome_fuel_used(o: T.Outcome) -> U64:
  match o:
    case T.Ok{model, status, op}: 0u64
    case T.Incomplete{op, fuel_used, model}: fuel_used
    case T.Failed{kind, model, op}: 0u64
