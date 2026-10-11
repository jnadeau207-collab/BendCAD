import Base
import ../../src/base/ex.bend as E
import ./F64.bend as L

def negl_inv(+cs: List<&2, F64>) -> {E.ex_negl(E.ex_negl(cs)) == cs : List<&2, F64>}:
  match cs:
    case []:
      {==}
    case +c <> t:
      %negl_inv(t) : {F64.neg(F64.neg(c)) <> E.ex_negl(E.ex_negl(t)) == c <> _ : List<&2, F64>}
      %L.neg_inv(c) : {F64.neg(F64.neg(c)) <> E.ex_negl(E.ex_negl(t)) == _ <> E.ex_negl(E.ex_negl(t)) : List<&2, F64>}
      {==}

def ex_neg_inv(+e: E.Ex) -> {E.ex_neg(E.ex_neg(e)) == e : E.Ex}:
  match e:
    case E.Ex{+ok, +cs}:
      %negl_inv(cs) : {E.ex_neg(E.ex_neg(E.Ex{ok, cs})) == E.Ex{ok, _} : E.Ex}
      {==}
