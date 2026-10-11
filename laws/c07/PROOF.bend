import Base
import ../../src/base/par.bend as B
import ../../src/c07/sym.bend as Y
import ../../src/base/ex.bend as E
import ../lib/Ex.bend as LE
import ./LAWS.bend as Laws

def wcmp_refl(n: Nat, +w: Word(n)) -> {EQ{} == Word.cmp(n, w, w) : Cmp}:
  match n w:
    case 0n WNil{}:
      {==}
    case 1n+p WCon{h, +t}:
      match h:
        case True{}:
          %wcmp_refl(p, t) : {EQ{} == Word.cmp.fin(True{}, True{}, _) : Cmp}
          {==}
        case False{}:
          %wcmp_refl(p, t) : {EQ{} == Word.cmp.fin(False{}, False{}, _) : Cmp}
          {==}

def lt_irrefl(+x: U64) -> {False{} == U64.is_lt(x, x) : Bool}:
  match x:
    case U64{lo, hi}:
      match lo hi:
        case U32{+a} U32{+b}:
          %wcmp_refl(64n, Word.cat(32n, 32n, a, b)) : {False{} == Cmp.is_lt(_) : Bool}
          {==}

def Laws.key_order_reflexive(a):
  match a:
    case []:
      {==}
    case +x <> +t:
      %lt_irrefl(x) : {Bool.pick(B.Sgn, _, B.Sn{}, Bool.pick(B.Sgn, _, B.Sp{}, Y.k_cmp(t, t))) == B.Sz{} : B.Sgn}
      Laws.key_order_reflexive(t)

def Laws.key_equal_reflexive(a):
  %Equal.sym(B.Sgn, Y.k_cmp(a, a), B.Sz{}, Laws.key_order_reflexive(a)) : {B.sgn_is(_, B.Sz{}) == True{} : Bool}
  {==}

def Laws.poly_neg_involution(p):
  match p:
    case []:
      {==}
    case x <> +t:
      match x:
        case Y.Mo{+c, +ks}:
          %Laws.poly_neg_involution(t) : {Y.Mo{E.ex_neg(E.ex_neg(c)), ks} <> Y.p_neg(Y.p_neg(t)) == Y.Mo{c, ks} <> _ : List<&2, Y.Mo>}
          %LE.ex_neg_inv(c) : {Y.Mo{E.ex_neg(E.ex_neg(c)), ks} <> Y.p_neg(Y.p_neg(t)) == Y.Mo{_, ks} <> Y.p_neg(Y.p_neg(t)) : List<&2, Y.Mo>}
          {==}

def Laws.ratfun_neg_involution(r):
  match r:
    case Y.Rf{+n, +d}:
      %Laws.poly_neg_involution(n) : {Y.rf_neg(Y.rf_neg(Y.Rf{n, d})) == Y.Rf{_, d} : Y.Rf}
      {==}
