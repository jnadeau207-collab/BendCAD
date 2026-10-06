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
  P_fix{ p: Pb, j: Nat, c: F64 }

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
    case P_fix{q, j, c}: Nat.sub(pb_n(q), 1n)

def pb_m(p: Pb) -> Nat:
  match p:
    case P_ci{c, s}: 1n
    case P_h{h, e, a, b}: 1n
    case P_cc{a, b, i, j}: 2n
    case P_c3{a, b}: 3n
    case P_ii{s1, s2}: 2n
    case P_fix{q, j, c}: pb_m(q)

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
    case P_fix{q, +j, +c}: pb_f(q, X.vins(j, x, I.ipt(c)))

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
    case P_fix{q, +j, +c}: X.mdrop_col(pb_j(q, X.vins(j, x, I.ipt(c))), j)

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

def pb_cls(+n: Nat, +m: Nat) -> U64:
  Bool.pick(U64, Nat.is_eq(m, n), 0u64, Bool.pick(U64, Nat.is_eq(Nat.add(m, 1n), n), 1u64, 2u64))

def code_qa(ex: Bool, +p: Pb, +x: List<&2, I.I>, +jx: List<&2, List<&2, I.I>>) -> U64:
  match ex:
    case True{}: 0u64
    case False{}: code_sq(p, x, jx, pb_n(p))

def code_q(+p: Pb, +x: List<&2, I.I>) -> U64:
  +jx = pb_j(p, x)
  code_qa(excl(pb_f(p, x), mvform(p, x, jx)), p, x, jx)

def code_qw(+p: Pb, +x: List<&2, I.I>, +w: U64) -> U64:
  +c = code_q(p, x)
  Bool.pick(U64, Bool.and(U64.is_eq(c, 9u64), U64.is_lt(w, 2u64)), 8u64, c)

def widest_go(xs: List<&2, I.I>, +i: Nat, +best: Nat, +bw: F64) -> Nat:
  match xs:
    case []: best
    case x <> t:
      +w = X.iwid(x)
      +take = F64.is_lt(bw, w)
      widest_go(t, Nat.add(i, 1n), Bool.pick(Nat, take, i, best), Bool.pick(F64, take, w, bw))

def widest(+xs: List<&2, I.I>) -> Nat:
  widest_go(xs, 0n, 0n, F64.neg(1.0f64))

def cut(+a: I.I, +i: Nat) -> F64:
  F64.add(I.i_lo(a), F64.mul(X.iwid(a), F64.add(0.515625f64, F64.mul(0.0078125f64, U64.to_f64(U64.from_nat(i))))))

def half_lo(+x: List<&2, I.I>, +i: Nat) -> List<&2, I.I>:
  +a = X.vn(x, i)
  X.vset(x, i, I.I{I.i_lo(a), cut(a, i)})

def half_hi(+x: List<&2, I.I>, +i: Nat) -> List<&2, I.I>:
  +a = X.vn(x, i)
  X.vset(x, i, I.I{cut(a, i), I.i_hi(a)})

def refine(n: Nat, +p: Pb, +x: List<&2, I.I>) -> List<&2, I.I>:
  match n:
    case 0n: x
    case 1n+m: refine(m, p, X.vmeet(kraw(p, x, pb_j(p, x), pb_n(p)), x))

def pt_box(+p: Pb, +x: List<&2, I.I>) -> List<&2, I.I>:
  refine(12n, p, x)

def bbq(d: Nat, +w: U64, c: U64, +p: Pb, +x: List<&2, I.I>) -> List<&2, Res>:
  match d:
    case 0n: Bool.pick(List<&2, Res>, U64.is_eq(c, 0u64), [], [R_un{x}])
    case 1n+(+e):
      match c:
        case 0u64: []
        case 1u64: [R_pt{pt_box(p, x)}]
        case 9u64:
          +i = widest(x)
          +lo = half_lo(x, i)
          +hi = half_hi(x, i)
          +h = U64.shr(U64.add(w, 1u64))
          List.append(&2, Res, bbq(e, h, code_qw(p, lo, h), p, lo), bbq(e, h, code_qw(p, hi, h), p, hi))
        case _: [R_un{x}]

def mk_fix(+p: Pb, +j: Nat, +c: F64) -> Pb:
  P_fix{p, j, c}

def face_res(+p: Pb, +x: List<&2, I.I>, +j: Nat, +c: F64) -> List<&2, Res>:
  +q = mk_fix(p, j, c)
  +z = X.vdrop(x, j)
  bbq(40n, 1024u64, code_qw(q, z, 1024u64), q, z)

def faces_go(n: Nat, +p: Pb, +x: List<&2, I.I>, +j: Nat) -> List<&2, Res>:
  match n:
    case 0n: []
    case 1n+r:
      +xj = X.vn(x, j)
      List.append(&2, Res, face_res(p, x, j, I.i_lo(xj)), List.append(&2, Res, face_res(p, x, j, I.i_hi(xj)), faces_go(r, p, x, Nat.add(j, 1n))))

def faces(+p: Pb, +x: List<&2, I.I>) -> List<&2, Res>:
  faces_go(pb_n(p), p, x, 0n)

def n_pt(rs: List<&2, Res>) -> Nat:
  match rs:
    case []: 0n
    case r <> t:
      match r:
        case R_pt{x}: Nat.add(1n, n_pt(t))
        case _: n_pt(t)

def any_un(rs: List<&2, Res>) -> Bool:
  match rs:
    case []: False{}
    case r <> t:
      match r:
        case R_un{x}: True{}
        case _: any_un(t)

def mnorm_row(r: List<&2, I.I>) -> F64:
  match r:
    case []: 0.0f64
    case +x <> t: I.up(F64.add(X.imag(x), mnorm_row(t)))

def mnorm(ms: List<&2, List<&2, I.I>>) -> F64:
  match ms:
    case []: 0.0f64
    case r <> t: F64.max(mnorm_row(r), mnorm(t))

def reg_k(+jx: List<&2, List<&2, I.I>>, +k: Nat, +m: Nat) -> Bool:
  +jz = X.mdrop_col(jx, k)
  +ym = L.inv(X.mmid(jz))
  Bool.and(Bool.not(Nat.is_eq(List.length(&2, List<&2, F64>, ym), 0n)), F64.is_lt(mnorm(X.id_minus(X.fmm(ym, X.cols(m, jz, 0n)), 0n)), 1.0f64))

def reg_find(n: Nat, +jx: List<&2, List<&2, I.I>>, +k: Nat, +m: Nat) -> U64:
  match n:
    case 0n: 99u64
    case 1n+r: Bool.pick(U64, reg_k(jx, k, m), U64.from_nat(k), reg_find(r, jx, Nat.add(k, 1n), m))

def code_cv2(irr: Bool, +k: U64, +p: Pb, +x: List<&2, I.I>) -> U64:
  match irr:
    case True{}: 9u64
    case False{}:
      +fr = faces(p, x)
      +np = n_pt(fr)
      Bool.pick(U64, any_un(fr), 9u64, Bool.pick(U64, Nat.is_eq(np, 0n), 0u64, Bool.pick(U64, Nat.is_eq(np, 2n), U64.add(2u64, k), 9u64)))

def code_cv(+p: Pb, +x: List<&2, I.I>, +jx: List<&2, List<&2, I.I>>) -> U64:
  +k = reg_find(pb_n(p), jx, 0n, pb_m(p))
  code_cv2(U64.is_eq(k, 99u64), k, p, x)

def code_c(k: U64, +p: Pb, +x: List<&2, I.I>, +jx: List<&2, List<&2, I.I>>) -> U64:
  match k:
    case 0u64: code_sq(p, x, jx, pb_n(p))
    case 1u64: code_cv(p, x, jx)
    case _: 9u64

def code_b(nz: Bool, +p: Pb, +x: List<&2, I.I>, +jx: List<&2, List<&2, I.I>>) -> U64:
  match nz:
    case True{}: 8u64
    case False{}: code_c(pb_cls(pb_n(p), pb_m(p)), p, x, jx)

def code_a(ex: Bool, +p: Pb, +x: List<&2, I.I>, +jx: List<&2, List<&2, I.I>>, +fx: List<&2, I.I>, +tol: F64, +small: Bool) -> U64:
  match ex:
    case True{}: 0u64
    case False{}: code_b(Bool.and(small, noisy(fx, tol)), p, x, jx)

def code_of(+p: Pb, +x: List<&2, I.I>, +tol: F64, +small: Bool) -> U64:
  +jx = pb_j(p, x)
  +fx = pb_f(p, x)
  code_a(excl(fx, mvform(p, x, jx)), p, x, jx, fx, tol, small)

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
  Bool.pick(U64, Nat.is_eq(n, 1n), 4194304u64, Bool.pick(U64, Nat.is_eq(n, 2n), 67108864u64, Bool.pick(U64, Nat.is_eq(n, 3n), 1073741824u64, 17179869184u64)))

def solve(+d: Nat, +p: Pb, +x: List<&2, I.I>) -> List<&2, Res>:
  +w = budget(pb_n(p))
  +tol = fscale(p, x)
  bb(d, w, code_w(p, x, w, tol), tol, p, x)
