import Base
import ../../src/c01/types.bend as V
import ../../src/k3/fem.bend as F
import ../../src/k3/mesh.bend as K

law transpose_keeps_rows:
  for +n: Nat
  for +cs: List<&2, List<&2, V.Dir>>
  {List.length(&2, List<&2, V.Dir>, F.tcol(n, cs)) == n : Nat}

law transpose_keeps_rows_f64:
  for +n: Nat
  for +cs: List<&2, List<&2, F64>>
  {List.length(&2, List<&2, F64>, F.tcolf(n, cs)) == n : Nat}

law pyramid_splits_into_two:
  for +q0: Nat
  for +q1: Nat
  for +q2: Nat
  for +q3: Nat
  for +p: Nat
  for +acc: List<&2, K.T4>
  {List.length(&2, K.T4, K.pyr(q0, q1, q2, q3, p, acc)) == 1n+(1n+List.length(&2, K.T4, acc)) : Nat}

law prism_splits_into_three:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  for +d: Nat
  for +e: Nat
  for +f: Nat
  for +acc: List<&2, K.T4>
  {List.length(&2, K.T4, K.prism(a, b, c, d, e, f, acc)) == 1n+(1n+(1n+List.length(&2, K.T4, acc))) : Nat}
