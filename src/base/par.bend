import Base

type Sgn is Data:
  Sn{}
  Sz{}
  Sp{}
  Su{}

def sgn_pick(n: Bool, p: Bool) -> Sgn:
  match n p:
    case True{} _: Sn{}
    case _ True{}: Sp{}
    case _ _: Sz{}

type Tr<a, -A: Kind(a)> is Kind(a):
  TL{ v: A }
  TN{ l: Tr<a, A>, r: Tr<a, A> }

type Tb<a, -A: Kind(a)> is Kind(a):
  Tb{ n: U32, t: Tr<a, A> }

type So<a, -A: Kind(a)> is Kind(a):
  So{ ok: Bool, xs: List<a, A> }

type Mg<a, -A: Kind(a)> is Kind(a):
  Mg{ ok: Bool, acc: List<a, A>, xs: List<a, A>, ys: List<a, A> }

type Dm is Data:
  Dm{ d: Nat, k: U32 }

def inf() -> U32:
  4294967295

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

def upick(c: Bool, +a: U32, +b: U32) -> U32:
  match c:
    case True{}: a
    case False{}: b

def u_le(+a: U32, +b: U32) -> Bool:
  Bool.not(U32.is_lt(b, a))

def u_cmp_go(+a: U32, +b: U32) -> Sgn:
  sgn_pick(U32.is_lt(a, b), U32.is_lt(b, a))

def u_cmp(a: U32, b: U32) -> Sgn:
  u_cmp_go(a, b)

def ulen_go(-A: Data, xs: List<&2, A>, +n: U32) -> U32:
  match xs:
    case Nil{}: n
    case h <> t: ulen_go(A, t, (n + 1 : U32))

def ulen(-A: Data, xs: List<&2, A>) -> U32:
  ulen_go(A, xs, 0)

def take_u(-A: Data, xs: List<&2, A>, +k: U32, z: Bool) -> List<&2, A>:
  match xs z:
    case _ True{}: []
    case Nil{} _: []
    case h <> t False{}: h <> take_u(A, t, (k - 1 : U32), U32.is_eq(k, 1))

def drop_u(-A: Data, xs: List<&2, A>, +k: U32, z: Bool) -> List<&2, A>:
  match xs z:
    case _ True{}: xs
    case Nil{} _: []
    case h <> t False{}: drop_u(A, t, (k - 1 : U32), U32.is_eq(k, 1))

def dm_go(fuel: Nat, done: Bool, +n: U32, +k: U32, +d: Nat) -> Dm:
  match fuel:
    case 0n: Dm{d, k}
    case 1n+f:
      match done:
        case True{}: Dm{d, k}
        case False{}: dm_go(f, u_le(n, U32.shl(k)), n, U32.shl(k), 1n+d)

def dims(+n: U32) -> Dm:
  dm_go(33n, u_le(n, 1), n, 1, 0n)

def tr_leaves(-A: Data, xs: List<&2, A>) -> List<&2, Tr<&2, A>>:
  match xs:
    case Nil{}: []
    case h <> t: TL{h} <> tr_leaves(A, t)

def tr_pairs(-A: Data, xs: List<&2, Tr<&2, A>>) -> List<&2, Tr<&2, A>>:
  match xs:
    case Nil{}: []
    case a <> Nil{}: [a]
    case a <> b <> t: TN{a, b} <> tr_pairs(A, t)

def tr_lift(-A: Data, d: Nat, xs: List<&2, Tr<&2, A>>, +z: A) -> Tr<&2, A>:
  match d:
    case 0n:
      match xs:
        case Nil{}: TL{z}
        case h <> t: h
    case 1n+e: tr_lift(A, e, tr_pairs(A, xs), z)

def rep_n(-A: Data, n: Nat, +x: A) -> List<&2, A>:
  match n:
    case 0n: []
    case 1n+m: x <> rep_n(A, m, x)

def tb_mk(-A: Data, dm: Dm, xs: List<&2, A>, +z: A, +n: U32) -> Tb<&2, A>:
  Dm{+d, +k} = dm
  +pad = U32.sub(k, n)
  Tb{k, tr_lift(A, d, tr_leaves(A, List.append(&2, A, xs, rep_n(A, U32.to_nat(pad), z))), z)}

def tb_of(-A: Data, +xs: List<&2, A>, +z: A) -> Tb<&2, A>:
  +n = ulen(A, xs)
  tb_mk(A, dims(n), xs, z, n)

def tr_go(-A: Data, t: Tr<&2, A>, +n: U32, +i: U32, z: Bool) -> A:
  match t z:
    case TL{+v} _: v
    case TN{l, r} True{}:
      +h = U32.shr(n)
      tr_go(A, l, h, i, U32.is_lt(i, U32.shr(h)))
    case TN{l, r} False{}:
      +h = U32.shr(n)
      +j = U32.sub(i, h)
      tr_go(A, r, h, j, U32.is_lt(j, U32.shr(h)))

def tb_get(-A: Data, tb: Tb<&2, A>, +i: U32) -> A:
  Tb{+n, t} = tb
  tr_go(A, t, n, i, U32.is_lt(i, U32.shr(n)))

def tr_set(-A: Data, t: Tr<&2, A>, +n: U32, +i: U32, +x: A, z: Bool) -> Tr<&2, A>:
  match t z:
    case TL{v} _: TL{x}
    case TN{l, r} True{}:
      +h = U32.shr(n)
      TN{tr_set(A, l, h, i, x, U32.is_lt(i, U32.shr(h))), r}
    case TN{l, r} False{}:
      +h = U32.shr(n)
      +j = U32.sub(i, h)
      TN{l, tr_set(A, r, h, j, x, U32.is_lt(j, U32.shr(h)))}

def tb_set(-A: Data, tb: Tb<&2, A>, +i: U32, +x: A) -> Tb<&2, A>:
  Tb{+n, t} = tb
  Tb{n, tr_set(A, t, n, i, x, U32.is_lt(i, U32.shr(n)))}

def tr_list(-A: Data, t: Tr<&2, A>, acc: List<&2, A>) -> List<&2, A>:
  match t:
    case TL{v}: v <> acc
    case TN{l, r}: tr_list(A, l, tr_list(A, r, acc))

def tb_list(-A: Data, tb: Tb<&2, A>) -> List<&2, A>:
  Tb{n, t} = tb
  tr_list(A, t, [])

def mg_step(-A: Data, c: Sgn, +ok: Bool, acc: List<&2, A>, x: A, xt: List<&2, A>,
    y: A, yt: List<&2, A>) -> Mg<&2, A>:
  match c:
    case Sp{}: Mg{ok, y <> acc, x <> xt, yt}
    case Su{}: Mg{False{}, x <> acc, xt, y <> yt}
    case _: Mg{ok, x <> acc, xt, y <> yt}

def mg_go(~A: Data, ~cmp: A -> A -> Sgn, fuel: Nat, st: Mg<&2, A>) -> Mg<&2, A>:
  match fuel:
    case 0n: st
    case 1n+f:
      Mg{ok, acc, xs, ys} = st
      match xs ys:
        case Nil{} _: Mg{ok, acc, [], ys}
        case _ Nil{}: Mg{ok, acc, xs, []}
        case +x <> xt +y <> yt:
          mg_go(~A, ~cmp, f, mg_step(A, cmp(x, y), ok, acc, x, xt, y, yt))

def mg_fin(-A: Data, st: Mg<&2, A>) -> So<&2, A>:
  Mg{ok, acc, xs, ys} = st
  So{ok, List.reverse.go(&2, A, acc, List.append(&2, A, xs, ys))}

def ms_join(~A: Data, ~cmp: A -> A -> Sgn, a: So<&2, A>, b: So<&2, A>, +n: U32) -> So<&2, A>:
  So{oa, xa} = a
  So{ob, xb} = b
  mg_fin(A, mg_go(~A, ~cmp, U32.to_nat(n), Mg{Bool.and(oa, ob), [], xa, xb}))

def ms(~A: Data, ~cmp: A -> A -> Sgn, d: Nat, small: Bool, +n: U32, +xs: List<&2, A>) -> So<&2, A>:
  match d:
    case 0n: So{False{}, xs}
    case 1n+(+e):
      match small:
        case True{}: So{True{}, xs}
        case False{}:
          +h = U32.shr(n)
          +m = U32.sub(n, h)
          a b = ms(~A, ~cmp, e, U32.is_lt(h, 2), h, take_u(A, xs, h, U32.is_eq(h, 0))) ms(~A, ~cmp, e, U32.is_lt(m, 2), m, drop_u(A, xs, h, U32.is_eq(h, 0)))
          ms_join(~A, ~cmp, a, b, n)

def msort(~A: Data, ~cmp: A -> A -> Sgn, +xs: List<&2, A>) -> So<&2, A>:
  +n = ulen(A, xs)
  ms(~A, ~cmp, 40n, U32.is_lt(n, 2), n, xs)

def so_cat(-A: Data, a: So<&2, A>, b: So<&2, A>) -> So<&2, A>:
  So{oa, xa} = a
  So{ob, xb} = b
  So{Bool.and(oa, ob), List.append(&2, A, xa, xb)}

def pfm_seq(~A: Data, ~B: Data, ~f: A -> So<&2, B>, xs: List<&2, A>) -> So<&2, B>:
  match xs:
    case Nil{}: So{True{}, []}
    case h <> t: so_cat(B, f(h), pfm_seq(~A, ~B, ~f, t))

def pfm(~A: Data, ~B: Data, ~f: A -> So<&2, B>, d: Nat, small: Bool, +n: U32,
    +xs: List<&2, A>) -> So<&2, B>:
  match d:
    case 0n: pfm_seq(~A, ~B, ~f, xs)
    case 1n+(+e):
      match small:
        case True{}: pfm_seq(~A, ~B, ~f, xs)
        case False{}:
          +h = U32.shr(n)
          +m = U32.sub(n, h)
          a b = pfm(~A, ~B, ~f, e, U32.is_lt(h, 64), h, take_u(A, xs, h, U32.is_eq(h, 0))) pfm(~A, ~B, ~f, e, U32.is_lt(m, 64), m, drop_u(A, xs, h, U32.is_eq(h, 0)))
          so_cat(B, a, b)

def pflat(~A: Data, ~B: Data, ~f: A -> So<&2, B>, +xs: List<&2, A>) -> So<&2, B>:
  +n = ulen(A, xs)
  pfm(~A, ~B, ~f, 40n, U32.is_lt(n, 64), n, xs)

def pmc_seq(~A: Data, ~C: Data, ~B: Data, ~f: C -> A -> B, +c: C, xs: List<&2, A>) -> List<&2, B>:
  match xs:
    case Nil{}: []
    case h <> t: f(c, h) <> pmc_seq(~A, ~C, ~B, ~f, c, t)

def pmc(~A: Data, ~C: Data, ~B: Data, ~f: C -> A -> B, d: Nat, small: Bool, +g: U32, +n: U32,
    +c: C, +xs: List<&2, A>) -> List<&2, B>:
  match d:
    case 0n: pmc_seq(~A, ~C, ~B, ~f, c, xs)
    case 1n+(+e):
      match small:
        case True{}: pmc_seq(~A, ~C, ~B, ~f, c, xs)
        case False{}:
          +h = U32.shr(n)
          +m = U32.sub(n, h)
          a b = pmc(~A, ~C, ~B, ~f, e, U32.is_lt(h, g), g, h, c, take_u(A, xs, h, U32.is_eq(h, 0))) pmc(~A, ~C, ~B, ~f, e, U32.is_lt(m, g), g, m, c, drop_u(A, xs, h, U32.is_eq(h, 0)))
          List.append(&2, B, a, b)

def pmap_g(~A: Data, ~C: Data, ~B: Data, ~f: C -> A -> B, +g: U32, +c: C, +xs: List<&2, A>) -> List<&2, B>:
  +n = ulen(A, xs)
  pmc(~A, ~C, ~B, ~f, 40n, U32.is_lt(n, g), g, n, c, xs)

def pmap(~A: Data, ~C: Data, ~B: Data, ~f: C -> A -> B, +c: C, +xs: List<&2, A>) -> List<&2, B>:
  pmap_g(~A, ~C, ~B, ~f, 128, c, xs)

def iota_go(-A: Data, xs: List<&2, A>, +i: U32) -> List<&2, U32>:
  match xs:
    case Nil{}: []
    case h <> t: i <> iota_go(A, t, (i + 1 : U32))

def ands(xs: List<&2, Bool>) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(h, ands(t))

def upick_f(c: Bool, +a: F64, +b: F64) -> F64:
  match c:
    case True{}: a
    case False{}: b

def dm_pow(n: Nat) -> U32:
  match n:
    case 0n: 1
    case 1n+m: U32.shl(dm_pow(m))

type Ed is Data:
  Ed{ u: U32, v: U32 }

type HK is Data:
  HK{ ok: Bool, hi: U32, lo: U32 }

type CC is Data:
  CC{ ok: Bool, ps: List<&2, U32> }

def hk_ok(x: HK) -> Bool:
  HK{ok, hi, lo} = x
  ok

def hk_hi(x: HK) -> U32:
  HK{ok, hi, lo} = x
  hi

def hk_lo(x: HK) -> U32:
  HK{ok, hi, lo} = x
  lo

def hk_of_go(+tp: Tb<&2, U32>, e: Ed) -> HK:
  Ed{u, v} = e
  +pu = tb_get(U32, tp, u)
  +pv = tb_get(U32, tp, v)
  HK{Bool.not(U32.is_eq(pu, pv)), U32.max(pu, pv), U32.min(pu, pv)}

def hk_of(tp: Tb<&2, U32>, e: Ed) -> HK:
  hk_of_go(tp, e)

def hk_keep_go(c: Bool, +h: HK, rest: List<&2, HK>) -> List<&2, HK>:
  match c:
    case True{}: h <> rest
    case False{}: rest

def hk_keep(xs: List<&2, HK>) -> List<&2, HK>:
  match xs:
    case Nil{}: []
    case +h <> t: hk_keep_go(hk_ok(h), h, hk_keep(t))

def lex_u(c: Sgn, +a: U32, +b: U32) -> Sgn:
  match c:
    case Sz{}: u_cmp(a, b)
    case _: c

def hk_cmp_go(+a: HK, +b: HK) -> Sgn:
  lex_u(u_cmp(hk_hi(a), hk_hi(b)), hk_lo(a), hk_lo(b))

def hk_cmp(a: HK, b: HK) -> Sgn:
  hk_cmp_go(a, b)

def hk_dedup(xs: List<&2, HK>, +prev: U32, first: Bool) -> List<&2, HK>:
  match xs:
    case Nil{}: []
    case +h <> t:
      hk_keep_go(Bool.or(first, Bool.not(U32.is_eq(hk_hi(h), prev))), h,
        hk_dedup(t, hk_hi(h), False{}))

def hk_peek(xs: List<&2, HK>, +i: U32) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t: U32.is_eq(hk_hi(h), i)

def hk_tail(xs: List<&2, HK>) -> List<&2, HK>:
  match xs:
    case Nil{}: []
    case h <> t: t

def hk_head_lo(xs: List<&2, HK>, +d: U32) -> U32:
  match xs:
    case Nil{}: d
    case h <> t: hk_lo(h)

def apply_go(ps: List<&2, U32>, +i: U32, +hs: List<&2, HK>, hit: Bool) -> List<&2, U32>:
  match ps:
    case Nil{}: []
    case p <> t:
      match hit:
        case True{}:
          +j = (i + 1 : U32)
          +rest = hk_tail(hs)
          hk_head_lo(hs, p) <> apply_go(t, j, rest, hk_peek(rest, j))
        case False{}:
          +j = (i + 1 : U32)
          p <> apply_go(t, j, hs, hk_peek(hs, j))

def sc_step(tp: Tb<&2, U32>, p: U32) -> U32:
  tb_get(U32, tp, p)

def shortcut(r: Nat, +ps: List<&2, U32>) -> List<&2, U32>:
  match r:
    case 0n: ps
    case 1n+q: shortcut(q, pmap(~U32, ~Tb<&2, U32>, ~U32, ~sc_step, tb_of(U32, ps, 0), ps))

def hk_fin(s: So<&2, HK>) -> List<&2, HK>:
  So{ok, xs} = s
  hk_dedup(xs, 0, True{})

def hooks(+es: List<&2, Ed>, +ps: List<&2, U32>) -> List<&2, HK>:
  hk_fin(msort(~HK, ~hk_cmp, hk_keep(pmap(~Ed, ~Tb<&2, U32>, ~HK, ~hk_of, tb_of(U32, ps, 0), es))))

def is_nil_hk(xs: List<&2, HK>) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: False{}

def cc_go(fuel: Nat, done: Bool, +r: Nat, +es: List<&2, Ed>, +ps: List<&2, U32>) -> CC:
  match fuel:
    case 0n: CC{done, ps}
    case 1n+f:
      match done:
        case True{}: CC{True{}, ps}
        case False{}:
          +hk = hooks(es, ps)
          cc_go(f, is_nil_hk(hk), r, es, shortcut(r, apply_go(ps, 0, hk, hk_peek(hk, 0))))

def dm_d(x: Dm) -> Nat:
  Dm{d, k} = x
  d

def rounds_of(+n: U32) -> Nat:
  1n+dm_d(dims(n))

def iota_n(n: Nat, +i: U32) -> List<&2, U32>:
  match n:
    case 0n: []
    case 1n+m: i <> iota_n(m, (i + 1 : U32))

def components(+nv: U32, +es: List<&2, Ed>) -> CC:
  cc_go(64n, False{}, rounds_of(nv), es, iota_n(U32.to_nat(nv), 0))
