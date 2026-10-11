import Base
import ../../src/base/par.bend as B
import ../../src/c07/sym.bend as Y

law key_order_reflexive:
  for +a: List<&2, U64>
  {Y.k_cmp(a, a) == B.Sz{} : B.Sgn}

law key_equal_reflexive:
  for +a: List<&2, U64>
  {Y.k_eq(a, a) == True{} : Bool}

law poly_neg_involution:
  for +p: List<&2, Y.Mo>
  {Y.p_neg(Y.p_neg(p)) == p : List<&2, Y.Mo>}

law ratfun_neg_involution:
  for +r: Y.Rf
  {Y.rf_neg(Y.rf_neg(r)) == r : Y.Rf}
