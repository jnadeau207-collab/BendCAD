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

def bcmp_anti(a: Bool, b: Bool) -> {Bool.cmp(b, a) == Laws.flip(Bool.cmp(a, b)) : Cmp}:
  match a b:
    case False{} False{}:
      {==}
    case False{} True{}:
      {==}
    case True{} False{}:
      {==}
    case True{} True{}:
      {==}

def fin_flip(+a: Bool, +b: Bool, t: Cmp) -> {Word.cmp.fin(b, a, Laws.flip(t)) == Laws.flip(Word.cmp.fin(a, b, t)) : Cmp}:
  match t:
    case LT{}:
      {==}
    case EQ{}:
      bcmp_anti(a, b)
    case GT{}:
      {==}

def wcmp_anti(n: Nat, +a: Word(n), +b: Word(n)) -> {Word.cmp(n, b, a) == Laws.flip(Word.cmp(n, a, b)) : Cmp}:
  match n a b:
    case 0n WNil{} WNil{}:
      {==}
    case 1n+(+p) WCon{+x, +s} WCon{+y, +u}:
      %Equal.sym(Cmp, Word.cmp(p, u, s), Laws.flip(Word.cmp(p, s, u)), wcmp_anti(p, s, u)) : {Word.cmp.fin(y, x, _) == Laws.flip(Word.cmp.fin(x, y, Word.cmp(p, s, u))) : Cmp}
      fin_flip(x, y, Word.cmp(p, s, u))

def u64w(+xl: U32, +xh: U32, +yl: U32, +yh: U32) -> {U64.cmp(U64{yl, yh}, U64{xl, xh}) == Laws.flip(U64.cmp(U64{xl, xh}, U64{yl, yh})) : Cmp}:
  match xl xh yl yh:
    case U32{+a} U32{+b} U32{+c} U32{+d}:
      wcmp_anti(64n, Word.cat(32n, 32n, a, b), Word.cat(32n, 32n, c, d))

def u64_anti(+x: U64, +y: U64) -> {U64.cmp(y, x) == Laws.flip(U64.cmp(x, y)) : Cmp}:
  match x y:
    case U64{+xl, +xh} U64{+yl, +yh}:
      u64w(xl, xh, yl, yh)

def step_anti(c: Cmp, +r1: B.Sgn, +r2: B.Sgn, h: {r2 == B.sgn_neg(r1) : B.Sgn}) -> {Bool.pick(B.Sgn, Cmp.is_lt(Laws.flip(c)), B.Sn{}, Bool.pick(B.Sgn, Cmp.is_lt(c), B.Sp{}, r2)) == B.sgn_neg(Bool.pick(B.Sgn, Cmp.is_lt(c), B.Sn{}, Bool.pick(B.Sgn, Cmp.is_lt(Laws.flip(c)), B.Sp{}, r1))) : B.Sgn}:
  match c:
    case LT{}:
      {==}
    case EQ{}:
      h
    case GT{}:
      {==}

def Laws.key_order_antisymmetric(a, b):
  match a b:
    case Nil{} Nil{}:
      {==}
    case Nil{} y <> u:
      {==}
    case x <> t Nil{}:
      {==}
    case +x <> +t +y <> +u:
      %Equal.sym(Cmp, U64.cmp(y, x), Laws.flip(U64.cmp(x, y)), u64_anti(x, y)) : {Bool.pick(B.Sgn, Cmp.is_lt(_), B.Sn{}, Bool.pick(B.Sgn, U64.is_lt(x, y), B.Sp{}, Y.k_cmp(u, t))) == B.sgn_neg(Bool.pick(B.Sgn, U64.is_lt(x, y), B.Sn{}, Bool.pick(B.Sgn, Cmp.is_lt(_), B.Sp{}, Y.k_cmp(t, u)))) : B.Sgn}
      step_anti(U64.cmp(x, y), Y.k_cmp(t, u), Y.k_cmp(u, t), Laws.key_order_antisymmetric(t, u))
