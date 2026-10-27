import Base
import ../../src/c00/types.bend as T
import ../../src/c06/xp.bend as X
import ../../src/c06/model.bend as M
import ./LAWS.bend as Laws

def ord_ids(ns: List<&2, M.Node>, +cs: List<&2, M.CE>) -> {Laws.ce_ids(M.ce_ord(ns, cs)) == M.nd_ids(ns) : List<&2, U64>}:
  match ns:
    case []: {==}
    case n <> t:
      %ord_ids(t, cs) : {M.nd_id(n) <> Laws.ce_ids(M.ce_ord(t, cs)) == M.nd_id(n) <> _ : List<&2, U64>}
      {==}

def Laws.eval_one_entry_per_node(ns, e, old, all):
  ord_ids(ns, M.ev_lvls(M.ew_max(M.ews(ns, [])), 1n, M.ews(ns, []), e, old, [], all))

def Laws.duplicate_ids_evaluate_nothing(p, old):
  {==}

def Laws.failed_input_refused(o, hasb, b, b2, e, it, nd, key, old, ns):
  {==}

def Laws.build_error_not_masked(k, d, o, hasb, b, it, nd):
  {==}

def Laws.intent_mismatch_refused(r, f, it, nd):
  {==}

def Laws.cache_hit_reuses_entry(old, o, hasb, b, b2, e, it, nd, ns):
  {==}
