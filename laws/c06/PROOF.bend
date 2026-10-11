import Base
import ../../src/c00/types.bend as T
import ../../src/c06/xp.bend as X
import ../../src/c06/model.bend as M
import ./LAWS.bend as Laws

def rev_ids(xs: List<&2, M.CE>, r: List<&2, M.CE>) -> {Laws.ce_ids(List.reverse.go(&2, M.CE, xs, r)) == List.reverse.go(&2, U64, Laws.ce_ids(xs), Laws.ce_ids(r)) : List<&2, U64>}:
  match xs:
    case []:
      {==}
    case h <> t:
      rev_ids(t, h <> r)

def ev_ids(ns: List<&2, M.Node>, +e: X.Env, +old: List<&2, M.CE>, +acc: List<&2, M.CE>, +all: List<&2, M.Node>) -> {Laws.ce_ids(M.ev_nodes(ns, e, old, acc, all)) == List.reverse.go(&2, U64, Laws.ce_ids(acc), M.nd_ids(ns)) : List<&2, U64>}:
  match ns:
    case []:
      rev_ids(acc, [])
    case n <> t:
      match n:
        case M.Nd{+nd, +o, +it}:
          +hasb = M.op_has_base(o)
          +hasb2 = M.op_has_b2(o)
          +bc = M.ce_find(acc, M.op_base(o))
          +bc2 = M.ce_find(acc, M.op_base2(o))
          +okb = Bool.and(Bool.or(Bool.not(hasb), Bool.and(M.ce_has(acc, M.op_base(o)), M.nr_ok(M.ce_r(bc)))),
            Bool.or(Bool.not(hasb2), Bool.and(M.ce_has(acc, M.op_base2(o)), M.nr_ok(M.ce_r(bc2)))))
          +key = List.append(&2, U64, M.op_w(o, e), List.append(&2, U64, M.it_w(it),
            List.append(&2, U64, Bool.pick(List<&2, U64>, hasb, M.ce_key(bc), []),
              Bool.pick(List<&2, U64>, hasb2, M.ce_key(bc2), []))))
          +r = M.node_go(okb, o, hasb, M.nr_body(M.ce_r(bc)), M.nr_body(M.ce_r(bc2)), e, it, nd, key, old, all)
          ev_ids(t, e, old, M.CE{nd, key, r} <> acc, all)

def Laws.eval_one_entry_per_node(ns, e, old, all):
  ev_ids(ns, e, old, [], all)

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
