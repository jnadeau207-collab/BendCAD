import Base
import ../../src/c00/types.bend as T
import ../../src/c13/err.bend as E
import ../../src/c13/req.bend as R

def count_ids(ids: List<&2, U64>) -> Nat:
  match ids:
    case []: 0n
    case _ <> t: 1n+count_ids(t)

law code_in_range:
  for k: T.FailKind
  {Bool.and(U64.is_le(1u64, E.code(k)), U64.is_le(E.code(k), 6u64)) == True{} : Bool}

law exact_budget_ok:
  for ids: List<&2, U64>
  {R.over_ids(ids, count_ids(ids)) == False{} : Bool}

law one_over_refuses:
  for x: U64
  for ids: List<&2, U64>
  {R.over_ids(x <> ids, count_ids(ids)) == True{} : Bool}

law cancel_wins:
  for over: Bool
  {R.dec_of(True{}, over) == R.D_cancel{} : R.Dec}
