import Base
import ../base/par.bend as B

type Xp is Data:
  X_k{ v: F64 }
  X_p{ id: U64 }
  X_add{ a: Xp, b: Xp }
  X_sub{ a: Xp, b: Xp }
  X_mul{ a: Xp, b: Xp }
  X_div{ a: Xp, b: Xp }
  X_neg{ a: Xp }

type PV is Data:
  PV{ id: U64, v: F64 }

type Env is Data:
  Env{ t: B.Tb<&2, PV>, n: U32 }

def pv_id(p: PV) -> U64:
  PV{id, v} = p
  id

def pv_v(p: PV) -> F64:
  PV{id, v} = p
  v

def pv_cmp_go(+a: PV, +b: PV) -> B.Sgn:
  B.sgn_pick(U64.is_lt(pv_id(a), pv_id(b)), U64.is_lt(pv_id(b), pv_id(a)))

def pv_cmp(a: PV, b: PV) -> B.Sgn:
  pv_cmp_go(a, b)

def so_pv(s: B.So<&2, PV>) -> List<&2, PV>:
  B.So{ok, xs} = s
  xs

def pv_pad() -> PV:
  PV{18446744073709551615u64, F64.nan()}

def env_mk(+xs: List<&2, PV>) -> Env:
  Env{B.tb_of(PV, xs, pv_pad()), B.ulen(PV, xs)}

def env_of(+xs: List<&2, PV>) -> Env:
  env_mk(so_pv(B.msort(~PV, ~pv_cmp, xs)))

def et_min(t: B.Tr<&2, PV>) -> U64:
  match t:
    case B.TL{v}: pv_id(v)
    case B.TN{l, r}: et_min(l)

def ez_of(t: B.Tr<&2, PV>, +k: U64) -> Bool:
  match t:
    case B.TL{v}: False{}
    case B.TN{l, r}: U64.is_lt(k, et_min(r))

def ef_go(t: B.Tr<&2, PV>, +k: U64, +base: U32, +n: U32, z: Bool) -> U32:
  match t z:
    case B.TL{v} _: base
    case B.TN{+l, r} True{}: ef_go(l, k, base, U32.shr(n), ez_of(l, k))
    case B.TN{l, +r} False{}:
      +h = U32.shr(n)
      ef_go(r, k, (base + h : U32), h, ez_of(r, k))

def env_at(+e: Env, +k: U64) -> PV:
  Env{+t, +n} = e
  B.Tb{+m, +tr} = t
  B.tb_get(PV, t, U32.min(ef_go(tr, k, 0, m, ez_of(tr, k)), (n - 1 : U32)))

def env_has(+e: Env, +k: U64) -> Bool:
  Env{t, +n} = e
  Bool.and(U32.is_lt(0, n), U64.is_eq(pv_id(env_at(e, k)), k))

def env_get(+e: Env, +k: U64) -> F64:
  Bool.pick(F64, env_has(e, k), pv_v(env_at(e, k)), F64.nan())

def xp_ev(x: Xp, +e: Env) -> F64:
  match x:
    case X_k{v}: v
    case X_p{id}: env_get(e, id)
    case X_add{a, b}: F64.add(xp_ev(a, e), xp_ev(b, e))
    case X_sub{a, b}: F64.sub(xp_ev(a, e), xp_ev(b, e))
    case X_mul{a, b}: F64.mul(xp_ev(a, e), xp_ev(b, e))
    case X_div{a, b}: F64.div(xp_ev(a, e), xp_ev(b, e))
    case X_neg{a}: F64.neg(xp_ev(a, e))

def miss_pick(+a: U64, +b: U64) -> U64:
  Bool.pick(U64, U64.is_eq(a, 0u64), b, a)

def xp_miss(x: Xp, +e: Env) -> U64:
  match x:
    case X_k{v}: 0u64
    case X_p{+id}: Bool.pick(U64, env_has(e, id), 0u64, (id + 1u64 : U64))
    case X_add{a, b}: miss_pick(xp_miss(a, e), xp_miss(b, e))
    case X_sub{a, b}: miss_pick(xp_miss(a, e), xp_miss(b, e))
    case X_mul{a, b}: miss_pick(xp_miss(a, e), xp_miss(b, e))
    case X_div{a, b}: miss_pick(xp_miss(a, e), xp_miss(b, e))
    case X_neg{a}: xp_miss(a, e)

def xp_w(x: Xp, +e: Env, acc: List<&2, U64>) -> List<&2, U64>:
  match x:
    case X_k{v}: 1u64 <> F64.bits(v) <> acc
    case X_p{+id}: 2u64 <> id <> F64.bits(env_get(e, id)) <> acc
    case X_add{a, b}: 3u64 <> xp_w(a, e, xp_w(b, e, acc))
    case X_sub{a, b}: 4u64 <> xp_w(a, e, xp_w(b, e, acc))
    case X_mul{a, b}: 5u64 <> xp_w(a, e, xp_w(b, e, acc))
    case X_div{a, b}: 6u64 <> xp_w(a, e, xp_w(b, e, acc))
    case X_neg{a}: 7u64 <> xp_w(a, e, acc)
