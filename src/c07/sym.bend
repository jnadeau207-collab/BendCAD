import Base
import ../base/par.bend as B
import ../base/ex.bend as E
import ../c06/xp.bend as X

type Mo is Data:
  Mo{ c: E.Ex, ks: List<&2, U64> }

type Rf is Data:
  Rf{ n: List<&2, Mo>, d: List<&2, Mo> }

def k_cmp(a: List<&2, U64>, b: List<&2, U64>) -> B.Sgn:
  match a:
    case []:
      match b:
        case []: B.Sz{}
        case y <> u: B.Sn{}
    case +x <> t:
      match b:
        case []: B.Sp{}
        case +y <> u: Bool.pick(B.Sgn, U64.is_lt(x, y), B.Sn{}, Bool.pick(B.Sgn, U64.is_lt(y, x), B.Sp{}, k_cmp(t, u)))

def k_eq(+a: List<&2, U64>, +b: List<&2, U64>) -> Bool:
  B.sgn_is(k_cmp(a, b), B.Sz{})

def mo_ks(m: Mo) -> List<&2, U64>:
  Mo{c, ks} = m
  ks

def mo_c(m: Mo) -> E.Ex:
  Mo{c, ks} = m
  c

def mo_cmp(a: Mo, b: Mo) -> B.Sgn:
  k_cmp(mo_ks(a), mo_ks(b))

def is_z(+e: E.Ex) -> Bool:
  B.sgn_is(E.ex_sign(e), B.Sz{})

def u_cmp_go(+a: U64, +b: U64) -> B.Sgn:
  B.sgn_pick(U64.is_lt(a, b), U64.is_lt(b, a))

def u_cmp(a: U64, b: U64) -> B.Sgn:
  u_cmp_go(a, b)

def so_u(s: B.So<&2, U64>) -> List<&2, U64>:
  B.So{ok, xs} = s
  xs

def k_merge(+xs: List<&2, U64>, +ys: List<&2, U64>) -> List<&2, U64>:
  so_u(B.msort(~U64, ~u_cmp, List.append(&2, U64, xs, ys)))

def keep(+m: Mo) -> List<&2, Mo>:
  Bool.pick(List<&2, Mo>, is_z(mo_c(m)), [], [m])

def comb(xs: List<&2, Mo>, +cur: Mo) -> List<&2, Mo>:
  match xs:
    case []: keep(cur)
    case +x <> t:
      +sm = k_eq(mo_ks(x), mo_ks(cur))
      +nc = Bool.pick(Mo, sm, Mo{E.ex_add(mo_c(cur), mo_c(x)), mo_ks(cur)}, x)
      List.append(&2, Mo, Bool.pick(List<&2, Mo>, sm, [], keep(cur)), comb(t, nc))

def so_mo(s: B.So<&2, Mo>) -> List<&2, Mo>:
  B.So{ok, xs} = s
  xs

def norm_go(xs: List<&2, Mo>) -> List<&2, Mo>:
  match xs:
    case []: []
    case x <> t: comb(t, x)

def norm(+xs: List<&2, Mo>) -> List<&2, Mo>:
  norm_go(so_mo(B.msort(~Mo, ~mo_cmp, xs)))

def p_add(+a: List<&2, Mo>, +b: List<&2, Mo>) -> List<&2, Mo>:
  norm(List.append(&2, Mo, a, b))

def p_neg(xs: List<&2, Mo>) -> List<&2, Mo>:
  match xs:
    case []: []
    case x <> t:
      Mo{c, ks} = x
      Mo{E.ex_neg(c), ks} <> p_neg(t)

def mo_mul(+m: Mo, ys: List<&2, Mo>) -> List<&2, Mo>:
  match ys:
    case []: []
    case y <> t:
      Mo{c, ks} = y
      Mo{E.ex_mul(mo_c(m), c), k_merge(mo_ks(m), ks)} <> mo_mul(m, t)

def mul_go(xs: List<&2, Mo>, +ys: List<&2, Mo>) -> List<&2, Mo>:
  match xs:
    case []: []
    case x <> t: List.append(&2, Mo, mo_mul(x, ys), mul_go(t, ys))

def p_mul(+a: List<&2, Mo>, +b: List<&2, Mo>) -> List<&2, Mo>:
  norm(mul_go(a, b))

def p_k(+v: F64) -> List<&2, Mo>:
  norm([Mo{E.ex_of(v), []}])

def rf_n(r: Rf) -> List<&2, Mo>:
  Rf{n, d} = r
  n

def rf_d(r: Rf) -> List<&2, Mo>:
  Rf{n, d} = r
  d

def rf_add(+a: Rf, +b: Rf) -> Rf:
  Rf{p_add(p_mul(rf_n(a), rf_d(b)), p_mul(rf_n(b), rf_d(a))), p_mul(rf_d(a), rf_d(b))}

def rf_neg(+a: Rf) -> Rf:
  Rf{p_neg(rf_n(a)), rf_d(a)}

def rf_mul(+a: Rf, +b: Rf) -> Rf:
  Rf{p_mul(rf_n(a), rf_n(b)), p_mul(rf_d(a), rf_d(b))}

def rf_div(+a: Rf, +b: Rf) -> Rf:
  Rf{p_mul(rf_n(a), rf_d(b)), p_mul(rf_d(a), rf_n(b))}

def rf_of(x: X.Xp) -> Rf:
  match x:
    case X.X_k{v}: Rf{p_k(v), p_k(1.0f64)}
    case X.X_p{id}: Rf{[Mo{E.ex_of(1.0f64), [id]}], p_k(1.0f64)}
    case X.X_add{a, b}: rf_add(rf_of(a), rf_of(b))
    case X.X_sub{a, b}: rf_add(rf_of(a), rf_neg(rf_of(b)))
    case X.X_mul{a, b}: rf_mul(rf_of(a), rf_of(b))
    case X.X_div{a, b}: rf_div(rf_of(a), rf_of(b))
    case X.X_neg{a}: rf_neg(rf_of(a))

def ok_all(xs: List<&2, Mo>) -> Bool:
  match xs:
    case []: True{}
    case x <> t: Bool.and(E.ex_ok(mo_c(x)), ok_all(t))

def is_zero(+x: X.Xp) -> Bool:
  +r = rf_of(x)
  +n = rf_n(r)
  Bool.and(Nat.is_eq(List.length(&2, Mo, n), 0n), Bool.and(ok_all(n), Bool.not(Nat.is_eq(List.length(&2, Mo, rf_d(r)), 0n))))

def same(+a: X.Xp, +b: X.Xp) -> Bool:
  is_zero(X.X_sub{a, b})
