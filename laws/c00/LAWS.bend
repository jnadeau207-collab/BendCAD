import Base
import ../../src/c00/types.bend as T
import ../../src/c00/eval.bend as E

def kept(m: T.Model, o: T.Outcome) -> T.Model:
  match o:
    case T.Ok{model, status, op}: m
    case T.Incomplete{op, fuel_used, model}: model
    case T.Failed{kind, model, op}: model

law failure_keeps_model:
  for +m: T.Model
  for +r: T.Request
  {kept(m, E.run(m, r)) == m : T.Model}

law outcome_attributed:
  for m: T.Model
  for +r: T.Request
  {E.outcome_op(E.run(m, r)) == E.op_id(r) : U64}

law publish_bumps_rev:
  for +m: T.Model
  for id: U64
  for v: F64
  for tag: U64
  {T.model_rev(E.outcome_model(E.publish(m, id, v, tag))) == (T.model_rev(m) + 1u64 : U64) : U64}

law cancel_atomic:
  for m: T.Model
  for r: T.Request
  {E.outcome_model(E.run(m, E.cancel_req(r))) == m : T.Model}

law cancel_explicit:
  for r: T.Request
  {E.outcome_show(E.run(T.model_seed(), E.cancel_req(r))) == "cancelled" : String}

law opid_excludes_fuel:
  for r: T.Request
  for a: U64
  for b: U64
  {E.op_id(E.set_fuel(r, a)) == E.op_id(E.set_fuel(r, b)) : U64}

law opid_excludes_cancel:
  for r: T.Request
  {E.op_id(E.cancel_req(r)) == E.op_id(r) : U64}

law opid_excludes_bytes:
  for r: T.Request
  for a: U64
  for b: U64
  {E.op_id(E.set_bytes(r, a)) == E.op_id(E.set_bytes(r, b)) : U64}
