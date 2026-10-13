import Base
import ../c01/types.bend as V
import ../c06/iv.bend as I
import ../c06/model.bend as M
import ../c07/ivx.bend as X
import ../c07/sol.bend as SO
import ../base/par.bend as B

type Ab is Data:
  Ab{ x0: F64, x1: F64, y0: F64, y1: F64, z0: F64, z1: F64 }

type Ak is Data:
  Ak{ k: U64, id: Nat }

type Bvh is Data:
  Bh_lf{ bx: Ab, ids: List<&2, Nat> }
  Bh_nd{ bx: Ab, a: Bvh, b: Bvh }

def ab_mk(+x0: F64, +x1: F64, +y0: F64, +y1: F64, +z0: F64, +z1: F64) -> Ab:
  Ab{x0, x1, y0, y1, z0, z1}

def ab_x0(+b: Ab) -> F64:
  Ab{x0, x1, y0, y1, z0, z1} = b
  x0

def ab_x1(+b: Ab) -> F64:
  Ab{x0, x1, y0, y1, z0, z1} = b
  x1

def ab_y0(+b: Ab) -> F64:
  Ab{x0, x1, y0, y1, z0, z1} = b
  y0

def ab_y1(+b: Ab) -> F64:
  Ab{x0, x1, y0, y1, z0, z1} = b
  y1

def ab_z0(+b: Ab) -> F64:
  Ab{x0, x1, y0, y1, z0, z1} = b
  z0

def ab_z1(+b: Ab) -> F64:
  Ab{x0, x1, y0, y1, z0, z1} = b
  z1

def ab_zero() -> Ab:
  Ab{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}

def ab_of3(+x: I.I, +y: I.I, +z: I.I) -> Ab:
  Ab{I.i_lo(x), I.i_hi(x), I.i_lo(y), I.i_hi(y), I.i_lo(z), I.i_hi(z)}

def ab_of_iv(+xs: List<&2, I.I>) -> Ab:
  ab_of3(X.vn(xs, 0n), X.vn(xs, 1n), X.vn(xs, 2n))

def ab_hull(+a: Ab, +b: Ab) -> Ab:
  Ab{F64.min(ab_x0(a), ab_x0(b)), F64.max(ab_x1(a), ab_x1(b)), F64.min(ab_y0(a), ab_y0(b)),
    F64.max(ab_y1(a), ab_y1(b)), F64.min(ab_z0(a), ab_z0(b)), F64.max(ab_z1(a), ab_z1(b))}

def ab_disjoint(+a: Ab, +b: Ab) -> Bool:
  Bool.or(F64.is_lt(ab_x1(a), ab_x0(b)),
    Bool.or(F64.is_lt(ab_x1(b), ab_x0(a)),
      Bool.or(F64.is_lt(ab_y1(a), ab_y0(b)),
        Bool.or(F64.is_lt(ab_y1(b), ab_y0(a)),
          Bool.or(F64.is_lt(ab_z1(a), ab_z0(b)), F64.is_lt(ab_z1(b), ab_z0(a)))))))

def ab_overlap(+a: Ab, +b: Ab) -> Bool:
  Bool.not(ab_disjoint(a, b))

def ab_cx(+b: Ab) -> F64:
  F64.add(F64.mul(0.5f64, ab_x0(b)), F64.mul(0.5f64, ab_x1(b)))

def ab_cy(+b: Ab) -> F64:
  F64.add(F64.mul(0.5f64, ab_y0(b)), F64.mul(0.5f64, ab_y1(b)))

def ab_cz(+b: Ab) -> F64:
  F64.add(F64.mul(0.5f64, ab_z0(b)), F64.mul(0.5f64, ab_z1(b)))

def ab_c(+b: Ab) -> V.Point:
  V.Pt{ab_cx(b), ab_cy(b), ab_cz(b)}

def ab_gap_lo(+v: F64, +lo: F64, +hi: F64) -> I.I:
  Bool.pick(I.I, F64.is_lt(v, lo), I.isub(I.ipt(lo), I.ipt(v)),
    Bool.pick(I.I, F64.is_lt(hi, v), I.isub(I.ipt(v), I.ipt(hi)), I.ipt(0.0f64)))

def ab_d2iv(+dx: I.I, +dy: I.I, +dz: I.I) -> I.I:
  I.iadd(I.isq(dx), I.iadd(I.isq(dy), I.isq(dz)))

def ab_lo(+p: V.Point, +b: Ab) -> F64:
  V.Pt{+x, +y, +z} = p
  F64.max(0.0f64,
    I.i_lo(I.isqrt(ab_d2iv(ab_gap_lo(x, ab_x0(b), ab_x1(b)), ab_gap_lo(y, ab_y0(b), ab_y1(b)),
      ab_gap_lo(z, ab_z0(b), ab_z1(b))))))

def ab_gg_lo(+a0: F64, +a1: F64, +b0: F64, +b1: F64) -> I.I:
  Bool.pick(I.I, F64.is_lt(b1, a0), I.isub(I.ipt(a0), I.ipt(b1)),
    Bool.pick(I.I, F64.is_lt(a1, b0), I.isub(I.ipt(b0), I.ipt(a1)), I.ipt(0.0f64)))

def ab_ab_lo(+a: Ab, +b: Ab) -> F64:
  F64.max(0.0f64,
    I.i_lo(I.isqrt(ab_d2iv(ab_gg_lo(ab_x0(a), ab_x1(a), ab_x0(b), ab_x1(b)),
      ab_gg_lo(ab_y0(a), ab_y1(a), ab_y0(b), ab_y1(b)),
      ab_gg_lo(ab_z0(a), ab_z1(a), ab_z0(b), ab_z1(b))))))

def ab_corner(+b: Ab, +i: Nat) -> V.Point:
  +x = Bool.pick(F64, Nat.is_eq(Nat.mod(i, 2n), 0n), ab_x0(b), ab_x1(b))
  +y = Bool.pick(F64, Nat.is_eq(Nat.mod(Nat.div(i, 2n), 2n), 0n), ab_y0(b), ab_y1(b))
  +z = Bool.pick(F64, Nat.is_eq(Nat.div(i, 4n), 0n), ab_z0(b), ab_z1(b))
  V.Pt{x, y, z}

def ab_wpt(+mi: List<&2, I.I>, +ti: List<&2, I.I>, +p: V.Point) -> V.Point:
  V.Pt{+x, +y, +z} = p
  +w = M.gp_go(mi, ti, x, y, z)
  V.Pt{I.imid(M.i_nth(w, 0n)), I.imid(M.i_nth(w, 1n)), I.imid(M.i_nth(w, 2n))}

def ab_corners(+b: Ab) -> List<&2, V.Point>:
  [ab_corner(b, 0n), ab_corner(b, 1n), ab_corner(b, 2n), ab_corner(b, 3n), ab_corner(b, 4n),
    ab_corner(b, 5n), ab_corner(b, 6n), ab_corner(b, 7n)]

def ab_wbox(+mi: List<&2, I.I>, +ti: List<&2, I.I>, +p: V.Point) -> Ab:
  V.Pt{+x, +y, +z} = p
  +w = M.gp_go(mi, ti, x, y, z)
  ab_of3(M.i_nth(w, 0n), M.i_nth(w, 1n), M.i_nth(w, 2n))

def ab_whull(ps: List<&2, V.Point>, +mi: List<&2, I.I>, +ti: List<&2, I.I>, +acc: Ab) -> Ab:
  match ps:
    case []: acc
    case p <> t: ab_whull(t, mi, ti, ab_hull(acc, ab_wbox(mi, ti, p)))

def ab_wseed(ps: List<&2, V.Point>, +mi: List<&2, I.I>, +ti: List<&2, I.I>) -> Ab:
  match ps:
    case []: ab_zero()
    case p <> t: ab_whull(t, mi, ti, ab_wbox(mi, ti, p))

def ab_world(+b: Ab, +p: M.Pl) -> Ab:
  ab_wseed(ab_corners(b), M.pl_mi(p), M.pl_ti(p))

def ab_q_go(le: Bool, +c: F64, +lo: F64, +w: F64) -> U64:
  match le:
    case True{}: 0u64
    case False{}: U64.min(1023u64, F64.to_u64(F64.max(0.0f64, F64.mul(F64.div(F64.sub(c, lo), w), 1024.0f64))))

def ab_q(+c: F64, +lo: F64, +w: F64) -> U64:
  ab_q_go(F64.is_le(w, 0.0f64), c, lo, w)

def ab_key(+b: Ab, +g: Ab) -> U64:
  +qx = ab_q(ab_cx(b), ab_x0(g), F64.sub(ab_x1(g), ab_x0(g)))
  +qy = ab_q(ab_cy(b), ab_y0(g), F64.sub(ab_y1(g), ab_y0(g)))
  +qz = ab_q(ab_cz(b), ab_z0(g), F64.sub(ab_z1(g), ab_z0(g)))
  U64.add(U64.add(U64.mul(qx, 1048576u64), U64.mul(qy, 1024u64)), qz)

def ak_lt(a: Ak, b: Ak) -> B.Sgn:
  Ak{+ka, +ia} = a
  Ak{+kb, +ib} = b
  Bool.pick(B.Sgn, U64.is_eq(ka, kb), B.sgn_pick(Nat.is_lt(ia, ib), Nat.is_lt(ib, ia)),
    B.sgn_pick(U64.is_lt(ka, kb), U64.is_lt(kb, ka)))

def ak_so(s: B.So<&2, Ak>) -> List<&2, Ak>:
  B.So{ok, xs} = s
  xs

def ak_dec(+bs: List<&2, Ab>, +g: Ab, +at: Nat) -> List<&2, Ak>:
  match bs:
    case []: []
    case b <> t: Ak{ab_key(b, g), at} <> ak_dec(t, g, Nat.add(at, 1n))

def ak_ids(xs: List<&2, Ak>) -> List<&2, Nat>:
  match xs:
    case []: []
    case Ak{k, id} <> t: id <> ak_ids(t)

def abs_hull_go(bs: List<&2, Ab>, +acc: Ab) -> Ab:
  match bs:
    case []: acc
    case b <> t: abs_hull_go(t, ab_hull(acc, b))

def abs_hull(+bs: List<&2, Ab>) -> Ab:
  match bs:
    case []: ab_zero()
    case b <> t: abs_hull_go(t, b)

def bvh_box(+t: Bvh) -> Ab:
  match t:
    case Bh_lf{+bx, ids}: bx
    case Bh_nd{+bx, a, b}: bx

def tb_box(+tb: B.Tb<&2, Ab>, +id: Nat) -> Ab:
  B.tb_get(Ab, tb, U32.from_nat(id))

def ids_hull(ids: List<&2, Nat>, +tb: B.Tb<&2, Ab>, +acc: Ab) -> Ab:
  match ids:
    case []: acc
    case i <> t: ids_hull(t, tb, ab_hull(acc, tb_box(tb, i)))

def bvh_nd(+a: Bvh, +b: Bvh) -> Bvh:
  Bh_nd{ab_hull(bvh_box(a), bvh_box(b)), a, b}

def ak_even(xs: List<&2, Ak>) -> List<&2, Ak>:
  match xs:
    case []: []
    case a <> t:
      match t:
        case []: [a]
        case b <> u: a <> ak_even(u)

def ak_odd(xs: List<&2, Ak>) -> List<&2, Ak>:
  match xs:
    case []: []
    case a <> t:
      match t:
        case []: []
        case b <> u: b <> ak_odd(u)

def ak_single(+a: Ak) -> List<&2, Ak>:
  [a]

def bvh_of(+fuel: Nat, +ks: List<&2, Ak>, +tb: B.Tb<&2, Ab>) -> Bvh:
  match fuel:
    case 0n: Bh_lf{ids_hull(ak_ids(ks), tb, ab_zero()), ak_ids(ks)}
    case 1n+(+g):
      match ks:
        case []: Bh_lf{ab_zero(), []}
        case +a <> t:
          match t:
            case []: Bh_lf{ids_hull(ak_ids(ak_single(a)), tb, ab_zero()), ak_ids(ak_single(a))}
            case b <> +u: bvh_nd(bvh_of(g, a <> ak_even(u), tb), bvh_of(g, b <> ak_odd(u), tb))

def bvh_build(+bs: List<&2, Ab>) -> Bvh:
  bvh_of(Nat.add(List.length(&2, Ab, bs), 1n), ak_so(B.msort(~Ak, ~ak_lt, ak_dec(bs, abs_hull(bs), 0n))),
    B.tb_of(Ab, bs, ab_zero()))

def hit_ids(ids: List<&2, Nat>, +q: Ab, +tb: B.Tb<&2, Ab>, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match ids:
    case []: acc
    case +i <> t: hit_ids(t, q, tb, Bool.pick(List<&2, Nat>, ab_overlap(tb_box(tb, i), q), i <> acc, acc))

def bvh_hit(+t: Bvh, +q: Ab, +tb: B.Tb<&2, Ab>, +acc: List<&2, Nat>, skip: Bool) -> List<&2, Nat>:
  match t:
    case Bh_lf{bx, ids}:
      match skip:
        case True{}: acc
        case False{}: hit_ids(ids, q, tb, acc)
    case Bh_nd{bx, +a, +b}:
      match skip:
        case True{}: acc
        case False{}:
          bvh_hit(a, q, tb, bvh_hit(b, q, tb, acc, ab_disjoint(bvh_box(b), q)), ab_disjoint(bvh_box(a), q))

def bvh_has(+t: Bvh, +q: Ab, +tb: B.Tb<&2, Ab>) -> Bool:
  Bool.not(Nat.is_eq(List.length(&2, Nat, bvh_hit(t, q, tb, [], ab_disjoint(bvh_box(t), q))), 0n))

def n_cmp_go(+a: Nat, +b: Nat) -> B.Sgn:
  B.sgn_pick(Nat.is_lt(a, b), Nat.is_lt(b, a))

def n_cmp(a: Nat, b: Nat) -> B.Sgn:
  n_cmp_go(a, b)

def n_so(s: B.So<&2, Nat>) -> List<&2, Nat>:
  B.So{ok, xs} = s
  xs

def n_sort(+xs: List<&2, Nat>) -> List<&2, Nat>:
  n_so(B.msort(~Nat, ~n_cmp, xs))

def n_dedup_cons(dup: Bool, +x: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match dup:
    case True{}: acc
    case False{}: x <> acc

def n_dedup_go(xs: List<&2, Nat>, +prev: Nat, +first: Bool, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case []: acc
    case +x <> t: n_dedup_go(t, x, False{}, n_dedup_cons(Bool.and(Bool.not(first), Nat.is_eq(x, prev)), x, acc))

def n_dedup(+xs: List<&2, Nat>) -> List<&2, Nat>:
  n_dedup_go(n_sort(xs), 0n, True{}, [])

def n_mem(+x: Nat, ys: List<&2, Nat>) -> Bool:
  match ys:
    case []: False{}
    case y <> u: Bool.pick(Bool, Nat.is_eq(x, y), True{}, n_mem(x, u))

def n_share(xs: List<&2, Nat>, +ys: List<&2, Nat>) -> Bool:
  match xs:
    case []: False{}
    case x <> t: Bool.pick(Bool, n_mem(x, ys), True{}, n_share(t, ys))

def fd_allok(+fs: List<&2, SO.Fd>) -> Bool:
  match fs:
    case []: True{}
    case f <> t: Bool.and(SO.fd_ok(f), fd_allok(t))
