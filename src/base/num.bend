import Base

def chr_code(c: Char) -> U32:
  Chr{x} = c
  x

def f_rt(m: Maybe<&2, F64>, +v: F64) -> Bool:
  match m:
    case None{}: False{}
    case Some{w}: U64.is_eq(F64.bits(w), F64.bits(v))

def f_show_d(whole: Bool, +n: U64, +v: F64) -> String:
  match whole:
    case True{}: U64.show(n)
    case False{}:
      +s = F64.show(v)
      Bool.pick(String, f_rt(F64.read(s), v), s, "b:" ++ U64.show(F64.bits(v)))

def f_show(+v: F64) -> String:
  +n = F64.to_u64(v)
  f_show_d(U64.is_eq(F64.bits(U64.to_f64(n)), F64.bits(v)), n, v)

def pfx_b(s: String) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{h, t}:
      match t:
        case SNil{}: False{}
        case SCon{h2, u}: Bool.and(U32.is_eq(chr_code(h), 98), U32.is_eq(chr_code(h2), 58))

def drop2(s: String) -> String:
  match s:
    case SNil{}: SNil{}
    case SCon{h, t}:
      match t:
        case SNil{}: SNil{}
        case SCon{h2, u}: u

def bits_of(m: Maybe<&2, U64>) -> Maybe<&2, F64>:
  match m:
    case None{}: None{}
    case Some{b}: Some{F64{b}}

def is_dg(+c: U32) -> Bool:
  Bool.and(U32.is_le(48, c), U32.is_le(c, 57))

def dg_v(c: U32) -> U64:
  U32.to_u64(U32.sub(c, 48))

def is_ech(+c: U32) -> Bool:
  Bool.or(U32.is_eq(c, 101), U32.is_eq(c, 69))

def dp_ph(+ph: U64, +c: U32) -> U64:
  Bool.pick(U64, is_dg(c), Bool.pick(U64, U64.is_le(ph, 1u64), ph, Bool.pick(U64, U64.is_eq(ph, 9u64), 9u64, 4u64)),
    Bool.pick(U64, Bool.and(U64.is_eq(ph, 0u64), U32.is_eq(c, 46)), 1u64,
      Bool.pick(U64, Bool.and(U64.is_le(ph, 1u64), is_ech(c)), 2u64,
        Bool.pick(U64, Bool.and(U64.is_eq(ph, 2u64), Bool.or(U32.is_eq(c, 43), U32.is_eq(c, 45))), 3u64, 9u64))))

def sig(+ph: U64, +c: U32, +nd: U64) -> Bool:
  Bool.and(Bool.and(is_dg(c), U64.is_le(ph, 1u64)), Bool.or(U64.is_lt(0u64, nd), Bool.not(U32.is_eq(c, 48))))

def dp_mant(+ph: U64, +c: U32, +m: U64, +nd: U64) -> U64:
  Bool.pick(U64, Bool.and(sig(ph, c, nd), U64.is_lt(nd, 19u64)), U64.add(U64.mul(m, 10u64), dg_v(c)), m)

def dp_nd(+ph: U64, +c: U32, +nd: U64) -> U64:
  Bool.pick(U64, sig(ph, c, nd), U64.add(nd, 1u64), nd)

def dp_fk(+ph: U64, +c: U32, +nd: U64, +fk: U64) -> U64:
  Bool.pick(U64, Bool.and(Bool.and(is_dg(c), U64.is_eq(ph, 1u64)), U64.is_lt(nd, 19u64)), U64.add(fk, 1u64), fk)

def dp_es(+ph: U64, +c: U32, es: Bool) -> Bool:
  Bool.or(es, Bool.and(U64.is_eq(ph, 2u64), U32.is_eq(c, 45)))

def dp_e(+ph: U64, +c: U32, +e: U64) -> U64:
  Bool.pick(U64, Bool.and(Bool.and(is_dg(c), U64.is_le(2u64, ph)), U64.is_lt(e, 10000u64)), U64.add(U64.mul(e, 10u64), dg_v(c)), e)

def p10(n: Nat, +p: U64) -> F64:
  match n:
    case 0n: 1.0f64
    case 1n+k: Bool.pick(F64, U64.is_eq(p, 0u64), 1.0f64, F64.mul(10.0f64, p10(k, U64.sub(p, 1u64))))

def dp_syn(+ph: U64, sd: Bool) -> Bool:
  Bool.and(sd, Bool.or(U64.is_le(ph, 1u64), U64.is_eq(ph, 4u64)))

def dp_ok(+nd: U64, +m: U64, +pw: U64) -> Bool:
  Bool.and(U64.is_le(nd, 18u64), Bool.or(U64.is_eq(m, 0u64), Bool.and(U64.is_le(m, 9007199254740992u64), U64.is_le(pw, 22u64))))

def dp_val(+m: U64, +up: Bool, +pw: U64) -> F64:
  +mf = U64.to_f64(m)
  Bool.pick(F64, U64.is_eq(m, 0u64), 0.0f64, Bool.pick(F64, up, F64.mul(mf, p10(22n, pw)), F64.div(mf, p10(22n, pw))))

def dp_fin(+m: U64, +nd: U64, +fk: U64, +es: Bool, +e: U64, +ph: U64, sd: Bool, s0: String) -> Maybe<&2, F64>:
  +up = Bool.and(Bool.not(es), U64.is_le(fk, e))
  +pw = Bool.pick(U64, es, U64.add(e, fk), Bool.pick(U64, up, U64.sub(e, fk), U64.sub(fk, e)))
  Bool.pick(Maybe<&2, F64>, dp_syn(ph, sd), Bool.pick(Maybe<&2, F64>, dp_ok(nd, m, pw), Some{dp_val(m, up, pw)}, F64.read(s0)), None{})

def dp(s: String, +ph: U64, +m: U64, +nd: U64, +fk: U64, +es: Bool, +e: U64, sd: Bool, s0: String) -> Maybe<&2, F64>:
  match s:
    case SNil{}: dp_fin(m, nd, fk, es, e, ph, sd, s0)
    case SCon{h, t}:
      +c = chr_code(h)
      dp(t, dp_ph(ph, c), dp_mant(ph, c, m, nd), dp_nd(ph, c, nd), dp_fk(ph, c, nd, fk), dp_es(ph, c, es), dp_e(ph, c, e), Bool.or(sd, Bool.and(is_dg(c), U64.is_le(ph, 1u64))), s0)

def neg_m(m: Maybe<&2, F64>) -> Maybe<&2, F64>:
  match m:
    case None{}: None{}
    case Some{v}: Some{F64.neg(v)}

def is_minus(s: String) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{h, t}: U32.is_eq(chr_code(h), 45)

def tail_s(s: String) -> String:
  match s:
    case SNil{}: SNil{}
    case SCon{h, t}: t

def dec_pos(+s: String) -> Maybe<&2, F64>:
  dp(s, 0u64, 0u64, 0u64, 0u64, False{}, 0u64, False{}, s)

def dec(+s: String) -> Maybe<&2, F64>:
  Bool.pick(Maybe<&2, F64>, is_minus(s), neg_m(dec_pos(tail_s(s))), dec_pos(s))

def num(+s: String) -> Maybe<&2, F64>:
  Bool.pick(Maybe<&2, F64>, pfx_b(s), bits_of(U64.read(drop2(s))), dec(s))

def is_some(m: Maybe<&2, F64>) -> Bool:
  match m:
    case None{}: False{}
    case Some{v}: True{}

def some_v(m: Maybe<&2, F64>) -> F64:
  match m:
    case None{}: F64.nan()
    case Some{v}: v
