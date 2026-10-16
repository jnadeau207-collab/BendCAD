import Base
import ../../src/c00/types.bend as T
import ../../src/c13/err.bend as E
import ../../src/c13/req.bend as R
import ./LAWS.bend as Laws

def Laws.code_in_range(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def exact_go(ids: List<&2, U64>) -> {R.over_ids(ids, Laws.count_ids(ids)) == False{} : Bool}:
  match ids:
    case []: {==}
    case h <> t: exact_go(t)

def Laws.exact_budget_ok(ids):
  exact_go(ids)

def over_go(ids: List<&2, U64>, x: U64) -> {R.over_ids(x <> ids, Laws.count_ids(ids)) == True{} : Bool}:
  match ids:
    case []: {==}
    case h <> t: over_go(t, h)

def Laws.one_over_refuses(x, ids):
  over_go(ids, x)

def Laws.cancel_wins(over):
  {==}
