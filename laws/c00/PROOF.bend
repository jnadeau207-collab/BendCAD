import Base
import ../../src/c00/types.bend as T
import ../../src/c00/eval.bend as E
import ./LAWS.bend as Laws

def km_len_fin(+m: T.Model, id: U64, v: F64, fin: Bool, tag: U64) -> {Laws.kept(m, E.ex_len_fin(m, id, v, fin, tag)) == m : T.Model}:
  match m:
    case T.Model{rev, count, sum}:
      match fin:
        case True{}:
          {==}
        case False{}:
          {==}

def km_len_neg(+m: T.Model, +r: T.Request, id: U64, neg: Bool) -> {Laws.kept(m, E.ex_len_neg(m, r, id, neg)) == m : T.Model}:
  match neg:
    case True{}:
      {==}
    case False{}:
      km_len_fin(m, id, E.len_value(r), E.len_fin(r), E.req_tag(r))

def km_mty(+m: T.Model, id: U64, lo: F64, hi: F64, empty: Bool, tag: U64) -> {Laws.kept(m, E.ex_isect_mty(m, id, lo, hi, empty, tag)) == m : T.Model}:
  match m:
    case T.Model{rev, count, sum}:
      match empty:
        case True{}:
          {==}
        case False{}:
          {==}

def km_isect_fin(+m: T.Model, id: U64, +a0: F64, +a1: F64, +b0: F64, +b1: F64, fin: Bool, tag: U64) -> {Laws.kept(m, E.ex_isect_fin(m, id, a0, a1, b0, b1, fin, tag)) == m : T.Model}:
  match fin:
    case True{}:
      km_mty(m, id, F64.max(a0, b0), F64.min(a1, b1), F64.is_lt(F64.min(a1, b1), F64.max(a0, b0)), tag)
    case False{}:
      {==}

def km_isect_ord(+m: T.Model, +r: T.Request, id: U64, bad: Bool) -> {Laws.kept(m, E.ex_isect_ord(m, r, id, bad)) == m : T.Model}:
  match bad:
    case True{}:
      {==}
    case False{}:
      km_isect_fin(m, id, E.isect_a0(r), E.isect_a1(r), E.isect_b0(r), E.isect_b1(r), E.isect_all_fin(r), E.req_tag(r))

def km_dispatch(+m: T.Model, +r: T.Request, id: U64, k: T.OpKind) -> {Laws.kept(m, E.st_dispatch(m, r, id, k)) == m : T.Model}:
  match k:
    case T.K_len{}:
      km_len_neg(m, r, id, E.len_neg(r))
    case T.K_isect{}:
      km_isect_ord(m, r, id, E.isect_bad_ord(r))
    case T.K_unknown{tag}:
      {==}

def km_fuel1(+m: T.Model, +r: T.Request, id: U64, one: Bool) -> {Laws.kept(m, E.st_fuel1_go(m, r, id, one)) == m : T.Model}:
  match one:
    case True{}:
      {==}
    case False{}:
      km_dispatch(m, r, id, E.req_op(r))

def km_boundary(+m: T.Model, +r: T.Request, id: U64, ok: Bool) -> {Laws.kept(m, E.st_boundary(m, r, id, ok)) == m : T.Model}:
  match ok:
    case True{}:
      km_fuel1(m, r, id, U64.is_eq(E.req_fuel(r), 1u64))
    case False{}:
      {==}

def km_fuel0(+m: T.Model, +r: T.Request, id: U64, zero: Bool) -> {Laws.kept(m, E.st_fuel0(m, r, id, zero)) == m : T.Model}:
  match zero:
    case True{}:
      {==}
    case False{}:
      km_boundary(m, r, id, E.req_boundary_ok(r))

def km_bytes(+m: T.Model, +r: T.Request, id: U64, over: Bool) -> {Laws.kept(m, E.st_bytes(m, r, id, over)) == m : T.Model}:
  match over:
    case True{}:
      {==}
    case False{}:
      km_fuel0(m, r, id, U64.is_eq(E.req_fuel(r), 0u64))

def km_cancel(+m: T.Model, +r: T.Request, id: U64, c: Bool) -> {Laws.kept(m, E.run_cancel(m, r, id, c)) == m : T.Model}:
  match c:
    case True{}:
      {==}
    case False{}:
      km_bytes(m, r, id, E.bytes_over(r))

def Laws.failure_keeps_model(m, r):
  km_cancel(m, r, E.op_id(r), E.req_cancelled(r))

def at_len_fin(m: T.Model, +id: U64, v: F64, fin: Bool, tag: U64) -> {E.outcome_op(E.ex_len_fin(m, id, v, fin, tag)) == id : U64}:
  match m:
    case T.Model{rev, count, sum}:
      match fin:
        case True{}:
          {==}
        case False{}:
          {==}

def at_len_neg(m: T.Model, +r: T.Request, +id: U64, neg: Bool) -> {E.outcome_op(E.ex_len_neg(m, r, id, neg)) == id : U64}:
  match neg:
    case True{}:
      {==}
    case False{}:
      at_len_fin(m, id, E.len_value(r), E.len_fin(r), E.req_tag(r))

def at_mty(m: T.Model, +id: U64, lo: F64, hi: F64, empty: Bool, tag: U64) -> {E.outcome_op(E.ex_isect_mty(m, id, lo, hi, empty, tag)) == id : U64}:
  match m:
    case T.Model{rev, count, sum}:
      match empty:
        case True{}:
          {==}
        case False{}:
          {==}

def at_isect_fin(m: T.Model, +id: U64, +a0: F64, +a1: F64, +b0: F64, +b1: F64, fin: Bool, tag: U64) -> {E.outcome_op(E.ex_isect_fin(m, id, a0, a1, b0, b1, fin, tag)) == id : U64}:
  match fin:
    case True{}:
      at_mty(m, id, F64.max(a0, b0), F64.min(a1, b1), F64.is_lt(F64.min(a1, b1), F64.max(a0, b0)), tag)
    case False{}:
      {==}

def at_isect_ord(m: T.Model, +r: T.Request, +id: U64, bad: Bool) -> {E.outcome_op(E.ex_isect_ord(m, r, id, bad)) == id : U64}:
  match bad:
    case True{}:
      {==}
    case False{}:
      at_isect_fin(m, id, E.isect_a0(r), E.isect_a1(r), E.isect_b0(r), E.isect_b1(r), E.isect_all_fin(r), E.req_tag(r))

def at_dispatch(m: T.Model, +r: T.Request, +id: U64, k: T.OpKind) -> {E.outcome_op(E.st_dispatch(m, r, id, k)) == id : U64}:
  match k:
    case T.K_len{}:
      at_len_neg(m, r, id, E.len_neg(r))
    case T.K_isect{}:
      at_isect_ord(m, r, id, E.isect_bad_ord(r))
    case T.K_unknown{tag}:
      {==}

def at_fuel1(m: T.Model, +r: T.Request, +id: U64, one: Bool) -> {E.outcome_op(E.st_fuel1_go(m, r, id, one)) == id : U64}:
  match one:
    case True{}:
      {==}
    case False{}:
      at_dispatch(m, r, id, E.req_op(r))

def at_boundary(m: T.Model, +r: T.Request, +id: U64, ok: Bool) -> {E.outcome_op(E.st_boundary(m, r, id, ok)) == id : U64}:
  match ok:
    case True{}:
      at_fuel1(m, r, id, U64.is_eq(E.req_fuel(r), 1u64))
    case False{}:
      {==}

def at_fuel0(m: T.Model, +r: T.Request, +id: U64, zero: Bool) -> {E.outcome_op(E.st_fuel0(m, r, id, zero)) == id : U64}:
  match zero:
    case True{}:
      {==}
    case False{}:
      at_boundary(m, r, id, E.req_boundary_ok(r))

def at_bytes(m: T.Model, +r: T.Request, +id: U64, over: Bool) -> {E.outcome_op(E.st_bytes(m, r, id, over)) == id : U64}:
  match over:
    case True{}:
      {==}
    case False{}:
      at_fuel0(m, r, id, U64.is_eq(E.req_fuel(r), 0u64))

def at_cancel(m: T.Model, +r: T.Request, +id: U64, c: Bool) -> {E.outcome_op(E.run_cancel(m, r, id, c)) == id : U64}:
  match c:
    case True{}:
      {==}
    case False{}:
      at_bytes(m, r, id, E.bytes_over(r))

def Laws.outcome_attributed(m, r):
  at_cancel(m, r, E.op_id(r), E.req_cancelled(r))

def Laws.publish_bumps_rev(m, id, v, tag):
  match m:
    case T.Model{rev, count, sum}:
      {==}

def Laws.cancel_atomic(m, r):
  match r:
    case T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cx}:
      {==}

def Laws.cancel_explicit(r):
  match r:
    case T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cx}:
      {==}

def Laws.opid_excludes_fuel(r, a, b):
  match r:
    case T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cx}:
      match budget:
        case T.Budget{fuel, max_bytes}:
          {==}

def Laws.opid_excludes_cancel(r):
  match r:
    case T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cx}:
      {==}

def Laws.opid_excludes_bytes(r, a, b):
  match r:
    case T.Request{op, unit, p0, p1, p2, p3, rev, tol, budget, bytes, cx}:
      {==}
