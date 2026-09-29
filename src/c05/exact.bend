import Base

type Sgn is Data:
  Sn{}
  Sz{}
  Sp{}
  Su{}

type Ex is Data:
  Ex{ ok: Bool, cs: List<&2, F64> }

type Tw is Data:
  Tw{ hi: F64, lo: F64 }

def tw_hi(t: Tw) -> F64:
  Tw{hi, lo} = t
  hi

def tw_lo(t: Tw) -> F64:
  Tw{hi, lo} = t
  lo

def sgn_show(s: Sgn) -> String:
  match s:
    case Sn{}: "neg"
    case Sz{}: "zero"
    case Sp{}: "pos"
    case Su{}: "uncertain"

def sgn_neg(s: Sgn) -> Sgn:
  match s:
    case Sn{}: Sp{}
    case Sz{}: Sz{}
    case Sp{}: Sn{}
    case Su{}: Su{}

def sgn_is(s: Sgn, w: Sgn) -> Bool:
  match s w:
    case Sn{} Sn{}: True{}
    case Sz{} Sz{}: True{}
    case Sp{} Sp{}: True{}
    case Su{} Su{}: True{}
    case _ _: False{}

def ex_ok(e: Ex) -> Bool:
  Ex{ok, cs} = e
  ok

def ex_cs(e: Ex) -> List<&2, F64>:
  Ex{ok, cs} = e
  cs

def fin(x: F64) -> Bool:
  (F64.class(x) < 2 : U32)

def ex_fin(cs: List<&2, F64>) -> Bool:
  match cs:
    case Nil{}: True{}
    case c <> t: Bool.and(fin(c), ex_fin(t))

def two_sum(+a: F64, +b: F64) -> Tw:
  +s = (a + b : F64)
  +bv = (s - a : F64)
  +av = (s - bv : F64)
  Tw{s, ((a - av : F64) + (b - bv : F64) : F64)}

def two_prod(+a: F64, +b: F64) -> Tw:
  +p = (a * b : F64)
  Tw{p, F64.fma(a, b, F64.neg(p))}

def lsb_go(+e: U64, +m: U64) -> U64:
  +lo = U64.and(m, (U64.not(m) + 1u64 : U64))
  (e + (63u64 - U32.to_u64(U64.clz(lo)) : U64) : U64)

def lsb_b(+x: F64) -> U64:
  +w = F64.bits(x)
  +e = U64.and(U64.shrn(w, 52n), 2047u64)
  +m = U64.and(w, 4503599627370495u64)
  +norm = Bool.not(U64.is_eq(e, 0u64))
  lsb_go(U64.max(e, 1u64), U64.or(m, U64.shln(Bool.to_u64(norm), 52n)))

def prod_exact_go(+a: F64, +b: F64, +p: F64, z: Bool) -> Bool:
  match z:
    case True{}:
      True{}
    case False{}:
      Bool.and(fin(p), U64.is_le(1076u64, (lsb_b(a) + lsb_b(b) : U64)))

def prod_exact(+a: F64, +b: F64, +p: F64) -> Bool:
  prod_exact_go(a, b, p, Bool.or(F64.is_eq(a, 0.0f64), F64.is_eq(b, 0.0f64)))

def keep_go(+x: F64, xs: List<&2, F64>, z: Bool) -> List<&2, F64>:
  match z:
    case True{}: xs
    case False{}: x <> xs

def keep(+x: F64, xs: List<&2, F64>) -> List<&2, F64>:
  keep_go(x, xs, F64.is_eq(x, 0.0f64))

def grow_go(cs: List<&2, F64>, +q: F64) -> List<&2, F64>:
  match cs:
    case Nil{}:
      keep(q, [])
    case c <> t:
      +r = two_sum(q, c)
      keep(tw_lo(r), grow_go(t, tw_hi(r)))

def ex_grow(e: Ex, +b: F64) -> Ex:
  Ex{ok, cs} = e
  +r = grow_go(cs, b)
  Ex{Bool.and(ok, Bool.and(fin(b), ex_fin(r))), r}

def ex_zero() -> Ex:
  Ex{True{}, []}

def ex_of(+x: F64) -> Ex:
  Ex{fin(x), keep(x, [])}

def ex_add_go(cs: List<&2, F64>, e: Ex) -> Ex:
  match cs:
    case Nil{}: e
    case c <> t: ex_add_go(t, ex_grow(e, c))

def ex_add(a: Ex, b: Ex) -> Ex:
  Ex{ok, cs} = b
  +r = ex_add_go(cs, a)
  Ex{Bool.and(ok, ex_ok(r)), ex_cs(r)}

def ex_negl(cs: List<&2, F64>) -> List<&2, F64>:
  match cs:
    case Nil{}: []
    case c <> t: F64.neg(c) <> ex_negl(t)

def ex_neg(e: Ex) -> Ex:
  Ex{ok, cs} = e
  Ex{ok, ex_negl(cs)}

def ex_sub(a: Ex, b: Ex) -> Ex:
  ex_add(a, ex_neg(b))

def ex_dif(+a: F64, +b: F64) -> Ex:
  ex_grow(ex_of(a), F64.neg(b))

def ex_scale_go(cs: List<&2, F64>, +b: F64, acc: Ex) -> Ex:
  match cs:
    case Nil{}: acc
    case +c <> t:
      +r = two_prod(c, b)
      +p = tw_hi(r)
      +ok = prod_exact(c, b, p)
      +a2 = ex_grow(ex_grow(acc, tw_lo(r)), p)
      ex_scale_go(t, b, Ex{Bool.and(ok, ex_ok(a2)), ex_cs(a2)})

def ex_scale(e: Ex, +b: F64) -> Ex:
  Ex{ok, cs} = e
  +r = ex_scale_go(cs, b, ex_zero())
  Ex{Bool.and(ok, Bool.and(fin(b), ex_ok(r))), ex_cs(r)}

def ex_mul_go(+a: Ex, cs: List<&2, F64>, acc: Ex) -> Ex:
  match cs:
    case Nil{}: acc
    case c <> t: ex_mul_go(a, t, ex_add(acc, ex_scale(a, c)))

def ex_mul(+a: Ex, b: Ex) -> Ex:
  Ex{ok, cs} = b
  +r = ex_mul_go(a, cs, ex_zero())
  Ex{Bool.and(ok, ex_ok(r)), ex_cs(r)}

def sgn_of_neg(n: Bool) -> Sgn:
  match n:
    case True{}: Sn{}
    case False{}: Sp{}

def last_sign(cs: List<&2, F64>, s: Sgn) -> Sgn:
  match cs:
    case Nil{}: s
    case c <> t: last_sign(t, sgn_of_neg(F64.is_lt(c, 0.0f64)))

def ex_sign(e: Ex) -> Sgn:
  Ex{ok, cs} = e
  match ok:
    case True{}: last_sign(cs, Sz{})
    case False{}: Su{}

def ex_cmp(a: Ex, b: Ex) -> Sgn:
  ex_sign(ex_sub(a, b))

def ex_approx(cs: List<&2, F64>) -> F64:
  match cs:
    case Nil{}: 0.0f64
    case c <> t: (c + ex_approx(t) : F64)

def ex_est(e: Ex) -> F64:
  ex_approx(ex_cs(e))

def orient2(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64) -> Ex:
  ex_sub(ex_mul(ex_dif(bx, ax), ex_dif(cy, ay)),
    ex_mul(ex_dif(by, ay), ex_dif(cx, ax)))
