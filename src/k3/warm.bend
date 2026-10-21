import Base
import ../c01/types.bend as V
import ../k1/sf.bend as S
import ../k1/ls.bend as L
import ../base/par.bend as B

type KP is Data:
  KP{ k: U64, i: Nat }

def kp_k(+x: KP) -> U64:
  KP{+k, i} = x
  k

def kp_i(+x: KP) -> Nat:
  KP{k, +i} = x
  i

def kp_cmp2(+x: KP, +y: KP) -> B.Sgn:
  B.sgn_pick(U64.is_lt(kp_k(x), kp_k(y)), U64.is_lt(kp_k(y), kp_k(x)))

def kp_cmp(x: KP, y: KP) -> B.Sgn:
  kp_cmp2(x, y)

def so_kp(s: B.So<&2, KP>) -> List<&2, KP>:
  B.So{ok, +xs} = s
  xs

type GD is Data:
  GD{ ox: F64, oy: F64, oz: F64, cs: F64, nx: U64, ny: U64 }

def ci(+x: F64, +o: F64, +cs: F64) -> U64:
  F64.to_u64(F64.div(F64.sub(x, o), cs))

def key_at(+g: GD, +p: V.Point, +dx: U64, +dy: U64, +dz: U64) -> U64:
  GD{+ox, +oy, +oz, +cs, +nx, +ny} = g
  +ix = U64.sub(U64.add(ci(V.pt_x(p), ox, cs), dx), 1u64)
  +iy = U64.sub(U64.add(ci(V.pt_y(p), oy, cs), dy), 1u64)
  +iz = U64.sub(U64.add(ci(V.pt_z(p), oz, cs), dz), 1u64)
  U64.add(ix, U64.mul(nx, U64.add(iy, U64.mul(ny, iz))))

type BX is Data:
  BX{ x0: F64, x1: F64, y0: F64, y1: F64, z0: F64, z1: F64 }

def bx_go(ps: List<&2, V.Point>, +b: BX) -> BX:
  match ps:
    case []: b
    case +p <> +t:
      BX{+x0, +x1, +y0, +y1, +z0, +z1} = b
      bx_go(t, BX{F64.min(x0, V.pt_x(p)), F64.max(x1, V.pt_x(p)), F64.min(y0, V.pt_y(p)), F64.max(y1, V.pt_y(p)),
        F64.min(z0, V.pt_z(p)), F64.max(z1, V.pt_z(p))})

def gd_of(+b: BX, +cs: F64) -> GD:
  BX{+x0, +x1, +y0, +y1, +z0, x1z} = b
  GD{F64.sub(x0, cs), F64.sub(y0, cs), F64.sub(z0, cs), cs, F64.to_u64(F64.add(F64.div(F64.sub(x1, x0), cs), 4.0f64)),
    F64.to_u64(F64.add(F64.div(F64.sub(y1, y0), cs), 4.0f64))}

def kps(ps: List<&2, V.Point>, +g: GD, +i: Nat) -> List<&2, KP>:
  match ps:
    case []: []
    case +p <> +t: KP{key_at(g, p, 1u64, 1u64, 1u64), i} <> kps(t, g, Nat.add(i, 1n))

def lb(fuel: Nat, done: Bool, +t: B.Tb<&2, KP>, +lo: Nat, +hi: Nat, +key: U64) -> Nat:
  match fuel:
    case 0n: lo
    case 1n+f:
      match done:
        case True{}: lo
        case False{}:
          +mid = Nat.div(Nat.add(lo, hi), 2n)
          +less = U64.is_lt(kp_k(B.tb_get(KP, t, U32.from_nat(mid))), key)
          +lo2 = Bool.pick(Nat, less, Nat.add(mid, 1n), lo)
          +hi2 = Bool.pick(Nat, less, hi, mid)
          lb(f, Bool.not(Nat.is_lt(lo2, hi2)), t, lo2, hi2, key)

type BN is Data:
  BN{ i: Nat, d: F64 }

def bn_i(+b: BN) -> Nat:
  BN{+i, d} = b
  i

def bn_d(+b: BN) -> F64:
  BN{i, +d} = b
  d

def scan(fuel: Nat, done: Bool, +j: Nat, +n: Nat, +t: B.Tb<&2, KP>, +key: U64, +pc: B.Tb<&2, V.Point>, +p: V.Point, +best: BN) -> BN:
  match fuel:
    case 0n: best
    case 1n+f:
      match done:
        case True{}: best
        case False{}:
          +kp = B.tb_get(KP, t, U32.from_nat(j))
          +same = U64.is_eq(kp_k(kp), key)
          +d = S.dist(p, B.tb_get(V.Point, pc, U32.from_nat(kp_i(kp))))
          +b2 = Bool.pick(BN, Bool.and(same, F64.is_lt(d, bn_d(best))), BN{kp_i(kp), d}, best)
          +j2 = Nat.add(j, 1n)
          scan(f, Bool.or(Bool.not(same), Bool.not(Nat.is_lt(j2, n))), j2, n, t, key, pc, p, b2)

type NS is Data:
  NS{ g: GD, t: B.Tb<&2, KP>, n: Nat, pc: B.Tb<&2, V.Point>, lg: Nat }

type O3 is Data:
  O3{ dx: U64, dy: U64, dz: U64 }

def offs() -> List<&2, O3>:
  [O3{0u64, 0u64, 0u64}, O3{1u64, 0u64, 0u64}, O3{2u64, 0u64, 0u64}, O3{0u64, 1u64, 0u64}, O3{1u64, 1u64, 0u64}, O3{2u64, 1u64, 0u64}, O3{0u64, 2u64, 0u64}, O3{1u64, 2u64, 0u64}, O3{2u64, 2u64, 0u64}, O3{0u64, 0u64, 1u64}, O3{1u64, 0u64, 1u64}, O3{2u64, 0u64, 1u64}, O3{0u64, 1u64, 1u64}, O3{1u64, 1u64, 1u64}, O3{2u64, 1u64, 1u64}, O3{0u64, 2u64, 1u64}, O3{1u64, 2u64, 1u64}, O3{2u64, 2u64, 1u64}, O3{0u64, 0u64, 2u64}, O3{1u64, 0u64, 2u64}, O3{2u64, 0u64, 2u64}, O3{0u64, 1u64, 2u64}, O3{1u64, 1u64, 2u64}, O3{2u64, 1u64, 2u64}, O3{0u64, 2u64, 2u64}, O3{1u64, 2u64, 2u64}, O3{2u64, 2u64, 2u64}]

def o_key(+g: GD, +p: V.Point, +o: O3) -> U64:
  O3{+dx, +dy, +dz} = o
  key_at(g, p, dx, dy, dz)

def near_go(os: List<&2, O3>, +s: NS, +p: V.Point, +best: BN) -> BN:
  match os:
    case []: best
    case +o <> +rest:
      NS{+g, +t, +n, +pc, +lg} = s
      +key = o_key(g, p, o)
      +j = lb(lg, Bool.not(Nat.is_lt(0n, n)), t, 0n, n, key)
      near_go(rest, s, p, scan(n, Bool.not(Nat.is_lt(j, n)), j, n, t, key, pc, p, best))

def near_f(s: NS, p: V.Point) -> Nat:
  bn_i(near_go(offs(), s, p, BN{0n, {1.0e300f64 : F64}}))

def log2n(f: Nat, done: Bool, +n: Nat, +acc: Nat) -> Nat:
  match f:
    case 0n: acc
    case 1n+g:
      match done:
        case True{}: acc
        case False{}: log2n(g, Nat.is_eq(Nat.div(n, 2n), 0n), Nat.div(n, 2n), Nat.add(acc, 1n))

def ns_of(+pc: List<&2, V.Point>, +cs: F64) -> NS:
  +big = {1.0e300f64 : F64}
  +g = gd_of(bx_go(pc, BX{big, F64.neg(big), big, F64.neg(big), big, F64.neg(big)}), cs)
  +xs = so_kp(B.msort(~KP, ~kp_cmp, kps(pc, g, 0n)))
  +n = List.length(&2, KP, xs)
  NS{g, B.tb_of(KP, xs, KP{0u64, 0n}), n, B.tb_of(V.Point, pc, S.pt(0.0f64, 0.0f64, 0.0f64)), Nat.add(log2n(64n, Nat.is_eq(n, 0n), n, 0n), 2n)}

def gat(js: List<&2, Nat>, +t: B.Tb<&2, F64>) -> List<&2, F64>:
  match js:
    case []: []
    case +j <> +rest:
      +b = Nat.mul(3n, j)
      B.tb_get(F64, t, U32.from_nat(b)) <> (B.tb_get(F64, t, U32.from_nat(Nat.add(b, 1n))) <> (B.tb_get(F64, t, U32.from_nat(Nat.add(b, 2n))) <> gat(rest, t)))

def gat_f(js: List<&2, Nat>, x: List<&2, F64>) -> List<&2, F64>:
  gat(js, B.tb_of(F64, x, 0.0f64))

def prolong(+pc: List<&2, V.Point>, +xs: List<&2, List<&2, F64>>, +pf: List<&2, V.Point>, +cs: F64) -> List<&2, List<&2, F64>>:
  +js = B.pmap_g(~V.Point, ~NS, ~Nat, ~near_f, 256, ns_of(pc, cs), pf)
  B.pmap_g(~List<&2, F64>, ~List<&2, Nat>, ~List<&2, F64>, ~gat_f, 1, js, xs)
