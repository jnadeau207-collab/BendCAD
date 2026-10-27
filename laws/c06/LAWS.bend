import Base
import ../../src/c00/types.bend as T
import ../../src/c06/xp.bend as X
import ../../src/c06/model.bend as M

def ce_ids(cs: List<&2, M.CE>) -> List<&2, U64>:
  match cs:
    case []: []
    case c <> t: M.ce_id(c) <> ce_ids(t)

def nr_failed(r: M.NR) -> Bool:
  match r:
    case M.NR_ok{b, fx}: False{}
    case M.NR_err{kind, d}: True{}

law eval_one_entry_per_node:
  for +ns: List<&2, M.Node>
  for +e: X.Env
  for +old: List<&2, M.CE>
  for +all: List<&2, M.Node>
  {ce_ids(M.ev_nodes(ns, e, old, all)) == M.nd_ids(ns) : List<&2, U64>}

law duplicate_ids_evaluate_nothing:
  for p: M.Part
  for old: List<&2, M.CE>
  {ce_ids(M.ev_go(False{}, p, old)) == [0u64] : List<&2, U64>}

law failed_input_refused:
  for o: M.Op
  for hasb: Bool
  for b: M.Body
  for b2: M.Body
  for e: X.Env
  for it: M.It
  for nd: U64
  for key: List<&2, U64>
  for old: List<&2, M.CE>
  for ns: List<&2, M.Node>
  {nr_failed(M.node_go(False{}, o, hasb, b, b2, e, it, nd, key, old, ns)) == True{} : Bool}

law build_error_not_masked:
  for k: T.FailKind
  for d: M.Dg
  for o: M.Op
  for hasb: Bool
  for b: M.Body
  for it: M.It
  for nd: U64
  {M.publish(M.NR_err{k, d}, o, hasb, b, it, nd) == M.NR_err{k, d} : M.NR}

law intent_mismatch_refused:
  for r: M.Body
  for f: M.Fx
  for it: M.It
  for nd: U64
  {nr_failed(M.gate_go(False{}, r, f, it, nd)) == True{} : Bool}

law cache_hit_reuses_entry:
  for +old: M.CE
  for o: M.Op
  for hasb: Bool
  for b: M.Body
  for b2: M.Body
  for e: X.Env
  for it: M.It
  for nd: U64
  for ns: List<&2, M.Node>
  {M.hit_go(True{}, old, o, hasb, b, b2, e, it, nd, ns) == M.ce_r(old) : M.NR}
