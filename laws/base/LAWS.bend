import Base
import ../../src/base/par.bend as P
import ../../src/base/ex.bend as E

def smap(+tp: P.Tb<&2, U32>, ps: List<&2, U32>) -> List<&2, U32>:
  match ps:
    case []: []
    case p <> t: P.tb_get(U32, tp, p) <> smap(tp, t)

def hmap(+tp: P.Tb<&2, U32>, es: List<&2, P.Ed>) -> List<&2, P.HK>:
  match es:
    case []: []
    case e <> t: P.hk_of(tp, e) <> hmap(tp, t)

def oks(xs: List<&2, P.HK>) -> Bool:
  match xs:
    case []: True{}
    case h <> t: Bool.and(P.hk_ok(h), oks(t))

law split_rejoins:
  for -A: Data
  for +xs: List<&2, A>
  for +k: U32
  for z: Bool
  {List.append(&2, A, P.take_u(A, xs, k, z), P.drop_u(A, xs, k, z)) == xs : List<&2, A>}

law pmap_shortcut_is_map:
  for +tp: P.Tb<&2, U32>
  for +ps: List<&2, U32>
  {P.pmap(~U32, ~P.Tb<&2, U32>, ~U32, ~P.sc_step, tp, ps) == smap(tp, ps) : List<&2, U32>}

law pmap_hooks_is_map:
  for +tp: P.Tb<&2, U32>
  for +es: List<&2, P.Ed>
  {P.pmap(~P.Ed, ~P.Tb<&2, U32>, ~P.HK, ~P.hk_of, tp, es) == hmap(tp, es) : List<&2, P.HK>}

law table_read_after_write:
  for -A: Data
  for +tb: P.Tb<&2, A>
  for +i: U32
  for +x: A
  {P.tb_get(A, P.tb_set(A, tb, i, x), i) == x : A}

law hooks_kept_are_valid:
  for xs: List<&2, P.HK>
  {oks(P.hk_keep(xs)) == True{} : Bool}

law ex_neg_involution:
  for +e: E.Ex
  {E.ex_neg(E.ex_neg(e)) == e : E.Ex}

law ex_uncertain_dominates:
  for cs: List<&2, F64>
  {E.ex_sign(E.Ex{False{}, cs}) == P.Su{} : P.Sgn}

law ex_neg_keeps_ok:
  for ok: Bool
  for cs: List<&2, F64>
  {E.ex_ok(E.ex_neg(E.Ex{ok, cs})) == ok : Bool}

law ex_add_taints:
  for a: E.Ex
  for cs: List<&2, F64>
  {E.ex_ok(E.ex_add(a, E.Ex{False{}, cs})) == False{} : Bool}

law ex_mul_taints:
  for a: E.Ex
  for cs: List<&2, F64>
  {E.ex_ok(E.ex_mul(a, E.Ex{False{}, cs})) == False{} : Bool}

law sgn_neg_invol:
  for s: P.Sgn
  {P.sgn_neg(P.sgn_neg(s)) == s : P.Sgn}

law sgn_is_refl:
  for s: P.Sgn
  {P.sgn_is(s, s) == True{} : Bool}

law sgn_neg_of_neg:
  for b: Bool
  {P.sgn_neg(E.sgn_of_neg(b)) == E.sgn_of_neg(Bool.not(b)) : P.Sgn}
