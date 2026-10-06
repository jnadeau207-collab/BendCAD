import Base
import ../c00/types.bend as T
import ../c06/iv.bend as I
import ./ivx.bend as X
import ./lin.bend as L
import ./rb.bend as R
import ./im.bend as M
import ../base/ex.bend as E
import ./exc.bend as C

type Pb is Data:
  P_ci{ c: R.Cv, s: M.Im }
  P_h{ h: List<&2, I.I>, e: List<&2, E.Ex>, a: F64, b: F64 }
  P_cc{ a: R.Cv, b: R.Cv, i: Nat, j: Nat }
  P_c3{ a: R.Cv, b: R.Cv }
  P_ii{ s1: M.Im, s2: M.Im }

type Res is Data:
  R_pt{ x: List<&2, I.I> }
  R_pc{ x: List<&2, I.I>, k: Nat }
  R_un{ x: List<&2, I.I> }

def pb_n(p: Pb) -> Nat:
  match p:
    case P_ci{c, s}: 1n
    case P_h{h, e, a, b}: 1n
    case P_cc{a, b, i, j}: 2n
    case P_c3{a, b}: 2n
    case P_ii{s1, s2}: 3n

def pb_m(p: Pb) -> Nat:
  match p:
    case P_ci{c, s}: 1n
    case P_h{h, e, a, b}: 1n
    case P_cc{a, b, i, j}: 2n
    case P_c3{a, b}: 3n
    case P_ii{s1, s2}: 2n

def horner(es: List<&2, E.Ex>, +t: F64) -> C.He:
  match es:
    case []: C.He{E.ex_zero(), 0.0f64}
    case c <> u: C.he_step(c, horner(u, t), t)

def he_iv(h: C.He) -> I.I:
  C.He{e, err} = h
  I.iwiden(I.of_ex(e), err)

def tau(+a: F64, +b: F64, +t: I.I) -> I.I:
  I.idiv(I.isub(t, I.ipt(a)), I.isub(I.ipt(b), I.ipt(a)))

def h_val(h: List<&2, I.I>, e: List<&2, E.Ex>, +a: F64, +b: F64, +t: I.I) -> I.I:
  +lo = I.i_lo(t)
  +hi = I.i_hi(t)
  Bool.pick(I.I, F64.is_eq(lo, hi), he_iv(horner(e, lo)), R.hull(R.restr(h, tau(a, b, I.ipt(lo)), tau(a, b, I.ipt(hi)))))

def neg3(xs: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t: I.ineg(x) <> neg3(t)

def pb_f(p: Pb, +x: List<&2, I.I>) -> List<&2, I.I>:
  match p:
    case P_ci{c, s}: [M.im_val(s, R.cv_box(c, X.vn(x, 0n)))]
    case P_h{h, +e, +a, +b}: [h_val(h, e, a, b, X.vn(x, 0n))]
    case P_cc{a, b, +i, +j}:
      +d = X.vsub(R.cv_box(a, X.vn(x, 0n)), R.cv_box(b, X.vn(x, 1n)))
      [X.vn(d, i), X.vn(d, j)]
    case P_c3{a, b}: X.vsub(R.cv_box(a, X.vn(x, 0n)), R.cv_box(b, X.vn(x, 1n)))
    case P_ii{s1, s2}: [M.im_val(s1, x), M.im_val(s2, x)]

def pair_rows(xs: List<&2, I.I>, ys: List<&2, I.I>) -> List<&2, List<&2, I.I>>:
  match xs:
    case []: []
    case x <> t:
      match ys:
        case []: []
        case y <> u: [x, I.ineg(y)] <> pair_rows(t, u)

def L_row(rs: List<&2, List<&2, I.I>>, +i: Nat) -> List<&2, I.I>:
  match rs:
    case []: []
    case r <> t:
      match i:
        case 0n: r
        case 1n+j: L_row(t, j)

def pb_j(p: Pb, +x: List<&2, I.I>) -> List<&2, List<&2, I.I>>:
  match p:
    case P_ci{+c, s}:
      +t = X.vn(x, 0n)
      [[X.vdot(M.im_grad(s, R.cv_box(c, t)), R.cv_der(c, t))]]
    case P_h{+h, e, +a, +b}: [[I.idiv(R.hull(R.restr(R.hodo(h), tau(a, b, I.ipt(I.i_lo(X.vn(x, 0n)))), tau(a, b, I.ipt(I.i_hi(X.vn(x, 0n)))))), I.isub(I.ipt(b), I.ipt(a)))]]
    case P_cc{a, b, +i, +j}:
      +rows = pair_rows(R.cv_der(a, X.vn(x, 0n)), R.cv_der(b, X.vn(x, 1n)))
      [L_row(rows, i), L_row(rows, j)]
    case P_c3{a, b}: pair_rows(R.cv_der(a, X.vn(x, 0n)), R.cv_der(b, X.vn(x, 1n)))
    case P_ii{s1, s2}: [M.im_grad(s1, x), M.im_grad(s2, x)]

def excl(+f: List<&2, I.I>, +mvf: List<&2, I.I>) -> Bool:
  Bool.or(X.vany0_not(f), X.vany0_not(mvf))

def mvform(+p: Pb, +x: List<&2, I.I>, +jx: List<&2, List<&2, I.I>>) -> List<&2, I.I>:
  +y = X.vpts(X.vmid(x))
  X.vadd(pb_f(p, y), X.mv(jx, X.vsub(x, y)))

def kraw(+p: Pb, +x: List<&2, I.I>, +jx: List<&2, List<&2, I.I>>, +n: Nat) -> List<&2, I.I>:
  +y = X.vpts(X.vmid(x))
  +ym = L.inv(X.mmid(jx))
  +mk = X.id_minus(X.fmm(ym, X.cols(n, jx, 0n)), 0n)
  Bool.pick(List<&2, I.I>, Nat.is_eq(List.length(&2, List<&2, F64>, ym), 0n), x,
    X.vadd(X.vsub(y, X.fmv(ym, pb_f(p, y))), X.mv(mk, X.vsub(x, y))))

def pkraw(+p: Pb, +x: List<&2, I.I>, +jx: List<&2, List<&2, I.I>>, +k: Nat, +m: Nat) -> List<&2, I.I>:
  +z = X.vdrop(x, k)
  +yz = X.vpts(X.vmid(z))
  +yf = X.vins(k, yz, X.vn(x, k))
  +jz = X.mdrop_col(jx, k)
  +ym = L.inv(X.mmid(jz))
  +mk = X.id_minus(X.fmm(ym, X.cols(m, jz, 0n)), 0n)
  Bool.pick(List<&2, I.I>, Nat.is_eq(List.length(&2, List<&2, F64>, ym), 0n), z,
    X.vadd(X.vsub(yz, X.fmv(ym, pb_f(p, yf))), X.mv(mk, X.vsub(z, yz))))

def piece_k(n: Nat, +p: Pb, +x: List<&2, I.I>, +jx: List<&2, List<&2, I.I>>, +k: Nat, +m: Nat) -> U64:
  match n:
    case 0n: 9u64
    case 1n+r:
      Bool.pick(U64, X.vin(pkraw(p, x, jx, k, m), X.vdrop(x, k)), U64.add(2u64, U64.from_nat(k)), piece_k(r, p, x, jx, Nat.add(k, 1n), m))

def code_sq(+p: Pb, +x: List<&2, I.I>, +jx: List<&2, List<&2, I.I>>, +n: Nat) -> U64:
  +kx = kraw(p, x, jx, n)
  Bool.pick(U64, X.vdisj(kx, x), 0u64, Bool.pick(U64, X.vin(kx, x), 1u64, 9u64))

def rowmag(r: List<&2, I.I>) -> F64:
  match r:
    case []: 0.0f64
    case +x <> t: F64.max(X.imag(x), rowmag(t))

def noisy(fs: List<&2, I.I>, +tol: F64) -> Bool:
  match fs:
    case []: True{}
    case +f <> t: Bool.and(F64.is_le(X.imag(f), tol), noisy(t, tol))

def fscale(+p: Pb, +x: List<&2, I.I>) -> F64:
  +m = rowmag(pb_f(p, x))
  Bool.pick(F64, T.is_finite(m), F64.mul(9.094947017729282e-13f64, m), 0.0f64)

def code_of(+p: Pb, +x: List<&2, I.I>, +tol: F64, +small: Bool) -> U64:
  +n = pb_n(p)
  +m = pb_m(p)
  +jx = pb_j(p, x)
  +fx = pb_f(p, x)
  Bool.pick(U64, excl(fx, mvform(p, x, jx)), 0u64,
    Bool.pick(U64, Bool.and(small, noisy(fx, tol)), 8u64,
    Bool.pick(U64, Nat.is_eq(m, n), code_sq(p, x, jx, n),
      Bool.pick(U64, Nat.is_eq(Nat.add(m, 1n), n), piece_k(n, p, x, jx, 0n, m), 9u64))))

def widest_go(xs: List<&2, I.I>, +i: Nat, +best: Nat, +bw: F64) -> Nat:
  match xs:
    case []: best
    case x <> t:
      +w = X.iwid(x)
      +take = F64.is_lt(bw, w)
      widest_go(t, Nat.add(i, 1n), Bool.pick(Nat, take, i, best), Bool.pick(F64, take, w, bw))

def widest(+xs: List<&2, I.I>) -> Nat:
  widest_go(xs, 0n, 0n, F64.neg(1.0f64))

def half_lo(+x: List<&2, I.I>, +i: Nat) -> List<&2, I.I>:
  X.vset(x, i, X.ilo_half(X.vn(x, i)))

def half_hi(+x: List<&2, I.I>, +i: Nat) -> List<&2, I.I>:
  X.vset(x, i, X.ihi_half(X.vn(x, i)))

def refine(n: Nat, +p: Pb, +x: List<&2, I.I>) -> List<&2, I.I>:
  match n:
    case 0n: x
    case 1n+m: refine(m, p, X.vmeet(kraw(p, x, pb_j(p, x), pb_n(p)), x))

def pt_box(+p: Pb, +x: List<&2, I.I>) -> List<&2, I.I>:
  refine(12n, p, x)

def code_w(+p: Pb, +x: List<&2, I.I>, +w: U64, +tol: F64) -> U64:
  +c = code_of(p, x, tol, U64.is_lt(w, 16u64))
  Bool.pick(U64, Bool.and(U64.is_eq(c, 9u64), U64.is_lt(w, 2u64)), 8u64, c)

def bb(d: Nat, +w: U64, c: U64, +tol: F64, +p: Pb, +x: List<&2, I.I>) -> List<&2, Res>:
  match d:
    case 0n: Bool.pick(List<&2, Res>, U64.is_eq(c, 0u64), [], [R_un{x}])
    case 1n+(+e):
      match c:
        case 0u64: []
        case 1u64: [R_pt{pt_box(p, x)}]
        case 8u64: [R_un{x}]
        case 9u64:
          +i = widest(x)
          +lo = half_lo(x, i)
          +hi = half_hi(x, i)
          +h = U64.shr(U64.add(w, 1u64))
          l r = bb(e, h, code_w(p, lo, h, tol), tol, p, lo) bb(e, h, code_w(p, hi, h, tol), tol, p, hi)
          List.append(&2, Res, l, r)
        case _: [R_pc{x, U64.to_nat(U64.sub(c, 2u64))}]

def budget(+n: Nat) -> U64:
  Bool.pick(U64, Nat.is_eq(n, 1n), 65536u64, Bool.pick(U64, Nat.is_eq(n, 2n), 262144u64, 1048576u64))

def solve(+d: Nat, +p: Pb, +x: List<&2, I.I>) -> List<&2, Res>:
  +w = budget(pb_n(p))
  +tol = fscale(p, x)
  bb(d, w, code_w(p, x, w, tol), tol, p, x)
