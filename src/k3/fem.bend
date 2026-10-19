import Base
import ../base/par.bend as B
import ../c01/types.bend as V
import ../k1/sf.bend as S
import ../k1/ls.bend as L

type EL is Data:
  EL{ ns: List<&2, U32>, g: List<&2, V.Dir>, v: F64 }

type FM is Data:
  FM{ nn: U32, es: List<&2, EL>, perm: List<&2, U32>, segs: List<&2, U32>, lam: F64, mu: F64, rho: F64 }

def gq() -> List<&2, List<&2, F64>>:
  +a = {0.5854101966249685f64 : F64}
  +b = {0.1381966011250105f64 : F64}
  [[a, b, b, b], [b, a, b, b], [b, b, a, b], [b, b, b, a]]

def edges() -> List<&2, List<&2, Nat>>:
  [[0n, 1n], [1n, 2n], [2n, 0n], [0n, 3n], [1n, 3n], [2n, 3n]]

def nth_d(xs: List<&2, V.Dir>, +i: Nat) -> V.Dir:
  match xs:
    case []: S.dr(0.0f64, 0.0f64, 0.0f64)
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_d(t, j)

def scale(+k: F64, xs: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: []
    case +h <> +t: F64.mul(k, h) <> scale(k, t)

def gs_corner(+l: List<&2, F64>, gl: List<&2, V.Dir>, +i: Nat) -> List<&2, V.Dir>:
  match gl:
    case []: []
    case +h <> +t: S.dscale(F64.sub(F64.mul(4.0f64, L.nth_f64(l, i)), 1.0f64), h) <> gs_corner(l, t, Nat.add(i, 1n))

def gs_edge(+l: List<&2, F64>, +gl: List<&2, V.Dir>, es: List<&2, List<&2, Nat>>) -> List<&2, V.Dir>:
  match es:
    case []: []
    case +e <> +t:
      +a = L.nth_n(e, 0n)
      +b = L.nth_n(e, 1n)
      +ga = nth_d(gl, a)
      +gb = nth_d(gl, b)
      S.dscale(4.0f64, S.dadd(S.dscale(L.nth_f64(l, a), gb), L.nth_f64(l, b), ga)) <> gs_edge(l, gl, t)

def grads(+l: List<&2, F64>, +gl: List<&2, V.Dir>) -> List<&2, V.Dir>:
  List.append(&2, V.Dir, gs_corner(l, gl, 0n), gs_edge(l, gl, edges()))

def h_add(+g: V.Dir, +u: V.Dir, +h: List<&2, F64>) -> List<&2, F64>:
  +gx = S.dx(g)
  +gy = S.dy(g)
  +gz = S.dz(g)
  +ux = S.dx(u)
  +uy = S.dy(u)
  +uz = S.dz(u)
  [F64.add(L.nth_f64(h, 0n), F64.mul(gx, ux)), F64.add(L.nth_f64(h, 1n), F64.mul(gx, uy)), F64.add(L.nth_f64(h, 2n), F64.mul(gx, uz)),
    F64.add(L.nth_f64(h, 3n), F64.mul(gy, ux)), F64.add(L.nth_f64(h, 4n), F64.mul(gy, uy)), F64.add(L.nth_f64(h, 5n), F64.mul(gy, uz)),
    F64.add(L.nth_f64(h, 6n), F64.mul(gz, ux)), F64.add(L.nth_f64(h, 7n), F64.mul(gz, uy)), F64.add(L.nth_f64(h, 8n), F64.mul(gz, uz))]

def h_of(gs: List<&2, V.Dir>, us: List<&2, V.Dir>, +h: List<&2, F64>) -> List<&2, F64>:
  match gs:
    case []: h
    case +g <> +gt:
      match us:
        case []: h
        case +u <> +ut: h_of(gt, ut, h_add(g, u, h))

def sig_of(+h: List<&2, F64>, +lam: F64, +mu: F64) -> List<&2, F64>:
  +tr = F64.add(L.nth_f64(h, 0n), F64.add(L.nth_f64(h, 4n), L.nth_f64(h, 8n)))
  +lt = F64.mul(lam, tr)
  +xy = F64.mul(mu, F64.add(L.nth_f64(h, 1n), L.nth_f64(h, 3n)))
  +xz = F64.mul(mu, F64.add(L.nth_f64(h, 2n), L.nth_f64(h, 6n)))
  +yz = F64.mul(mu, F64.add(L.nth_f64(h, 5n), L.nth_f64(h, 7n)))
  [F64.add(lt, F64.mul(F64.mul(2.0f64, mu), L.nth_f64(h, 0n))), F64.add(lt, F64.mul(F64.mul(2.0f64, mu), L.nth_f64(h, 4n))),
    F64.add(lt, F64.mul(F64.mul(2.0f64, mu), L.nth_f64(h, 8n))), xy, xz, yz]

def sig_g(+s: List<&2, F64>, +g: V.Dir) -> V.Dir:
  +gx = S.dx(g)
  +gy = S.dy(g)
  +gz = S.dz(g)
  S.dr(F64.add(F64.mul(L.nth_f64(s, 0n), gx), F64.add(F64.mul(L.nth_f64(s, 3n), gy), F64.mul(L.nth_f64(s, 4n), gz))),
    F64.add(F64.mul(L.nth_f64(s, 3n), gx), F64.add(F64.mul(L.nth_f64(s, 1n), gy), F64.mul(L.nth_f64(s, 5n), gz))),
    F64.add(F64.mul(L.nth_f64(s, 4n), gx), F64.add(F64.mul(L.nth_f64(s, 5n), gy), F64.mul(L.nth_f64(s, 2n), gz))))

def f_add(gs: List<&2, V.Dir>, fs: List<&2, V.Dir>, +s: List<&2, F64>, +w: F64) -> List<&2, V.Dir>:
  match gs:
    case []: fs
    case +g <> +gt:
      match fs:
        case []: []
        case +f <> +ft: S.dadd(f, w, sig_g(s, g)) <> f_add(gt, ft, s, w)

def zeros3(n: Nat) -> List<&2, V.Dir>:
  match n:
    case 0n: []
    case 1n+m: S.dr(0.0f64, 0.0f64, 0.0f64) <> zeros3(m)

def k_q(qs: List<&2, List<&2, F64>>, +gl: List<&2, V.Dir>, +us: List<&2, V.Dir>, +w: F64, +lam: F64, +mu: F64,
    +fs: List<&2, V.Dir>) -> List<&2, V.Dir>:
  match qs:
    case []: fs
    case +q <> +t:
      +gs = grads(q, gl)
      +s = sig_of(h_of(gs, us, [0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64]), lam, mu)
      k_q(t, gl, us, w, lam, mu, f_add(gs, fs, s, w))

def mref() -> List<&2, List<&2, F64>>:
  [[6.0f64, 1.0f64, 1.0f64, 1.0f64, F64.neg(4.0f64), F64.neg(6.0f64), F64.neg(4.0f64), F64.neg(4.0f64), F64.neg(6.0f64), F64.neg(6.0f64)],
   [1.0f64, 6.0f64, 1.0f64, 1.0f64, F64.neg(4.0f64), F64.neg(4.0f64), F64.neg(6.0f64), F64.neg(6.0f64), F64.neg(4.0f64), F64.neg(6.0f64)],
   [1.0f64, 1.0f64, 6.0f64, 1.0f64, F64.neg(6.0f64), F64.neg(4.0f64), F64.neg(4.0f64), F64.neg(6.0f64), F64.neg(6.0f64), F64.neg(4.0f64)],
   [1.0f64, 1.0f64, 1.0f64, 6.0f64, F64.neg(6.0f64), F64.neg(6.0f64), F64.neg(6.0f64), F64.neg(4.0f64), F64.neg(4.0f64), F64.neg(4.0f64)],
   [F64.neg(4.0f64), F64.neg(4.0f64), F64.neg(6.0f64), F64.neg(6.0f64), 32.0f64, 16.0f64, 16.0f64, 16.0f64, 16.0f64, 8.0f64],
   [F64.neg(6.0f64), F64.neg(4.0f64), F64.neg(4.0f64), F64.neg(6.0f64), 16.0f64, 32.0f64, 16.0f64, 8.0f64, 16.0f64, 16.0f64],
   [F64.neg(4.0f64), F64.neg(6.0f64), F64.neg(4.0f64), F64.neg(6.0f64), 16.0f64, 16.0f64, 32.0f64, 16.0f64, 8.0f64, 16.0f64],
   [F64.neg(4.0f64), F64.neg(6.0f64), F64.neg(6.0f64), F64.neg(4.0f64), 16.0f64, 8.0f64, 16.0f64, 32.0f64, 16.0f64, 16.0f64],
   [F64.neg(6.0f64), F64.neg(4.0f64), F64.neg(6.0f64), F64.neg(4.0f64), 16.0f64, 16.0f64, 8.0f64, 16.0f64, 32.0f64, 16.0f64],
   [F64.neg(6.0f64), F64.neg(6.0f64), F64.neg(4.0f64), F64.neg(4.0f64), 8.0f64, 16.0f64, 16.0f64, 16.0f64, 16.0f64, 32.0f64]]

def row_dot(r: List<&2, F64>, us: List<&2, V.Dir>, +acc: V.Dir) -> V.Dir:
  match r:
    case []: acc
    case +c <> +rt:
      match us:
        case []: acc
        case +u <> +ut: row_dot(rt, ut, S.dadd(acc, c, u))

def m_rows(rs: List<&2, List<&2, F64>>, +us: List<&2, V.Dir>, +k: F64) -> List<&2, V.Dir>:
  match rs:
    case []: []
    case +r <> +t: S.dscale(k, row_dot(r, us, S.dr(0.0f64, 0.0f64, 0.0f64))) <> m_rows(t, us, k)

def gather(ns: List<&2, U32>, +x: B.Tb<&2, F64>) -> List<&2, V.Dir>:
  match ns:
    case []: []
    case +n <> +t:
      +i = U32.mul(n, 3)
      S.dr(B.tb_get(F64, x, i), B.tb_get(F64, x, U32.add(i, 1)), B.tb_get(F64, x, U32.add(i, 2))) <> gather(t, x)

def flat(ds: List<&2, V.Dir>) -> List<&2, F64>:
  match ds:
    case []: []
    case +d <> +t: S.dx(d) <> S.dy(d) <> S.dz(d) <> flat(t)

type OP is Data:
  OP{ mass: Bool, lam: F64, mu: F64, x: B.Tb<&2, F64> }

def op_mk(+mass: Bool, +lam: F64, +mu: F64, +x: B.Tb<&2, F64>) -> OP:
  OP{mass, lam, mu, x}

def el_go(+mass: Bool, +us: List<&2, V.Dir>, +gl: List<&2, V.Dir>, +v: F64, +lam: F64, +mu: F64) -> List<&2, V.Dir>:
  match mass:
    case True{}: m_rows(mref(), us, F64.div(v, 420.0f64))
    case False{}: k_q(gq(), gl, us, F64.mul(0.25f64, v), lam, mu, zeros3(10n))

def el_f(o: OP, e: EL) -> List<&2, F64>:
  OP{+mass, +lam, +mu, +x} = o
  EL{+ns, +gl, +v} = e
  flat(el_go(mass, gather(ns, x), gl, v, lam, mu))

def cat_all(xs: List<&2, List<&2, F64>>) -> List<&2, F64>:
  match xs:
    case []: []
    case +h <> +t: List.append(&2, F64, h, cat_all(t))

def seg_sum(ps: List<&2, U32>, ss: List<&2, U32>, +c: B.Tb<&2, F64>, +acc: F64, +out: List<&2, F64>) -> List<&2, F64>:
  match ps:
    case []: List.reverse(&2, F64, out)
    case +p <> +pt:
      match ss:
        case []: List.reverse(&2, F64, out)
        case +k <> +st:
          +a = F64.add(acc, B.tb_get(F64, c, p))
          +last = U32.is_eq(k, 1)
          seg_sum(pt, Bool.pick(List<&2, U32>, last, st, U32.sub(k, 1) <> st), c, Bool.pick(F64, last, 0.0f64, a),
            Bool.pick(List<&2, F64>, last, a <> out, out))

def apply_op(+fm: FM, +mass: Bool, +xs: List<&2, F64>) -> List<&2, F64>:
  FM{+nn, +es, +perm, +segs, +lam, +mu, +rho} = fm
  +o = op_mk(mass, lam, mu, B.tb_of(F64, xs, 0.0f64))
  +cs = cat_all(B.pmap(~EL, ~OP, ~List<&2, F64>, ~el_f, o, es))
  +ys = seg_sum(perm, segs, B.tb_of(F64, cs, 0.0f64), 0.0f64, [])
  Bool.pick(List<&2, F64>, mass, scale(rho, ys), ys)

def dq_go(gs: List<&2, V.Dir>, +w: F64, +lam: F64, +mu: F64) -> List<&2, V.Dir>:
  match gs:
    case []: []
    case +g <> +t:
      +gg = S.dot(g, g)
      +k = F64.add(lam, mu)
      S.dr(F64.mul(w, F64.add(F64.mul(k, F64.mul(S.dx(g), S.dx(g))), F64.mul(mu, gg))),
        F64.mul(w, F64.add(F64.mul(k, F64.mul(S.dy(g), S.dy(g))), F64.mul(mu, gg))),
        F64.mul(w, F64.add(F64.mul(k, F64.mul(S.dz(g), S.dz(g))), F64.mul(mu, gg)))) <> dq_go(t, w, lam, mu)

def dsum(as: List<&2, V.Dir>, bs: List<&2, V.Dir>) -> List<&2, V.Dir>:
  match as:
    case []: bs
    case +a <> +at:
      match bs:
        case []: []
        case +b <> +bt: S.dadd(a, 1.0f64, b) <> dsum(at, bt)

def dq(qs: List<&2, List<&2, F64>>, +gl: List<&2, V.Dir>, +w: F64, +lam: F64, +mu: F64, +acc: List<&2, V.Dir>) -> List<&2, V.Dir>:
  match qs:
    case []: acc
    case +q <> +t: dq(t, gl, w, lam, mu, dsum(dq_go(grads(q, gl), w, lam, mu), acc))

def el_d(o: OP, e: EL) -> List<&2, F64>:
  OP{+mass, +lam, +mu, +x} = o
  EL{+ns, +gl, +v} = e
  flat(dq(gq(), gl, F64.mul(0.25f64, v), lam, mu, zeros3(10n)))

def k_diag(+fm: FM) -> List<&2, F64>:
  FM{+nn, +es, +perm, +segs, +lam, +mu, +rho} = fm
  +o = op_mk(False{}, lam, mu, B.tb_of(F64, [0.0f64], 0.0f64))
  seg_sum(perm, segs, B.tb_of(F64, cat_all(B.pmap(~EL, ~OP, ~List<&2, F64>, ~el_d, o, es)), 0.0f64), 0.0f64, [])

type PI is Data:
  PI{ d: U32, i: U32 }

def pi_cmp(a: PI, b: PI) -> B.Sgn:
  PI{+ad, +ai} = a
  PI{+bd, +bi} = b
  B.sgn_pick(Bool.or(U32.is_lt(ad, bd), Bool.and(U32.is_eq(ad, bd), U32.is_lt(ai, bi))),
    Bool.or(U32.is_lt(bd, ad), Bool.and(U32.is_eq(ad, bd), U32.is_lt(bi, ai))))

def pis_n(ns: List<&2, U32>, +base: U32, +acc: List<&2, PI>) -> List<&2, PI>:
  match ns:
    case []: acc
    case +n <> +t:
      +d = U32.mul(n, 3)
      pis_n(t, U32.add(base, 3), PI{d, base} <> PI{U32.add(d, 1), U32.add(base, 1)} <> PI{U32.add(d, 2), U32.add(base, 2)} <> acc)

def pis_e(es: List<&2, EL>, +base: U32, +acc: List<&2, PI>) -> List<&2, PI>:
  match es:
    case []: acc
    case +e <> +t:
      EL{+ns, +gl, +v} = e
      pis_e(t, U32.add(base, 30), pis_n(ns, base, acc))

def so_xs(s: B.So<&2, PI>) -> List<&2, PI>:
  B.So{+ok, +xs} = s
  xs

def perm_of(ps: List<&2, PI>) -> List<&2, U32>:
  match ps:
    case []: []
    case +p <> +t:
      PI{+d, +i} = p
      i <> perm_of(t)

def runs(ps: List<&2, PI>, +cur: U32, +k: U32, +acc: List<&2, U32>) -> List<&2, U32>:
  match ps:
    case []: List.reverse(&2, U32, Bool.pick(List<&2, U32>, U32.is_eq(k, 0), acc, k <> acc))
    case +p <> +t:
      PI{+d, +i} = p
      +same = U32.is_eq(d, cur)
      runs(t, d, Bool.pick(U32, same, U32.add(k, 1), 1), Bool.pick(List<&2, U32>, Bool.or(same, U32.is_eq(k, 0)), acc, k <> acc))

def fm_of(+nn: U32, +es: List<&2, EL>, +e: F64, +nu: F64, +rho: F64) -> FM:
  +ps = so_xs(B.msort(~PI, ~pi_cmp, pis_e(es, 0, [])))
  +lam = F64.div(F64.mul(e, nu), F64.mul(F64.add(1.0f64, nu), F64.sub(1.0f64, F64.mul(2.0f64, nu))))
  +mu = F64.div(e, F64.mul(2.0f64, F64.add(1.0f64, nu)))
  FM{nn, es, perm_of(ps), runs(ps, 0, 0, []), lam, mu, rho}

def el_of(+ns: List<&2, U32>, +p: List<&2, V.Point>) -> EL:
  +p0 = L.nth_p(p, 0n)
  +d1 = S.psub(L.nth_p(p, 1n), p0)
  +d2 = S.psub(L.nth_p(p, 2n), p0)
  +d3 = S.psub(L.nth_p(p, 3n), p0)
  +det = S.dot(d1, S.cross(d2, d3))
  +g2 = S.dscale(F64.div(1.0f64, det), S.cross(d2, d3))
  +g3 = S.dscale(F64.div(1.0f64, det), S.cross(d3, d1))
  +g4 = S.dscale(F64.div(1.0f64, det), S.cross(d1, d2))
  +g1 = S.dscale(F64.neg(1.0f64), S.dadd(S.dadd(g2, 1.0f64, g3), 1.0f64, g4))
  EL{ns, [g1, g2, g3, g4], F64.div(F64.abs(det), 6.0f64)}

def dot_l(xs: List<&2, F64>, ys: List<&2, F64>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> +xt:
      match ys:
        case []: acc
        case +y <> +yt: dot_l(xt, yt, F64.add(acc, F64.mul(x, y)))

def axpy(+a: F64, xs: List<&2, F64>, ys: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: ys
    case +x <> +xt:
      match ys:
        case []: []
        case +y <> +yt: F64.add(y, F64.mul(a, x)) <> axpy(a, xt, yt)

def hadam(xs: List<&2, F64>, ys: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> +xt:
      match ys:
        case []: []
        case +y <> +yt: F64.mul(x, y) <> hadam(xt, yt)

def inv_d(+mask: List<&2, F64>, ds: List<&2, F64>) -> List<&2, F64>:
  match ds:
    case []: []
    case +d <> +t: F64.div(1.0f64, d) <> inv_d(mask, t)

def k_m(+fm: FM, +mask: List<&2, F64>, +x: List<&2, F64>) -> List<&2, F64>:
  hadam(mask, apply_op(fm, False{}, hadam(mask, x)))

def pcg(n: Nat, done: Bool, +fm: FM, +mask: List<&2, F64>, +pc: List<&2, F64>, +x: List<&2, F64>, +r: List<&2, F64>, +p: List<&2, F64>,
    +rz: F64, +tol: F64) -> List<&2, F64>:
  match n:
    case 0n: x
    case 1n+m:
     match done:
      case True{}: x
      case False{}:
        +q = k_m(fm, mask, p)
        +al = F64.div(rz, dot_l(p, q, 0.0f64))
        +x2 = axpy(al, p, x)
        +r2 = axpy(F64.neg(al), q, r)
        +z2 = hadam(pc, r2)
        +rz2 = dot_l(r2, z2, 0.0f64)
        pcg(m, F64.is_lt(F64.sqrt(dot_l(r2, r2, 0.0f64)), tol), fm, mask, pc, x2, r2, axpy(F64.div(rz2, rz), p, z2), rz2, tol)

def solve_from(+fm: FM, +mask: List<&2, F64>, +pc: List<&2, F64>, +b: List<&2, F64>, +x0: List<&2, F64>, +iters: Nat, +tol: F64) -> List<&2, F64>:
  +r = axpy(F64.neg(1.0f64), k_m(fm, mask, x0), hadam(mask, b))
  +z = hadam(pc, r)
  pcg(iters, False{}, fm, mask, pc, x0, r, z, dot_l(r, z, 0.0f64), tol)

def precond(+fm: FM, +mask: List<&2, F64>) -> List<&2, F64>:
  hadam(mask, inv_d(mask, k_diag(fm)))

def solve(+fm: FM, +mask: List<&2, F64>, +b: List<&2, F64>, +iters: Nat, +tol: F64) -> List<&2, F64>:
  solve_from(fm, mask, precond(fm, mask), b, scale(0.0f64, b), iters, tol)

def ncmp2(+a: Nat, +b: Nat) -> B.Sgn:
  B.sgn_pick(Nat.is_lt(a, b), Nat.is_lt(b, a))

def ncmp(a: Nat, b: Nat) -> B.Sgn:
  ncmp2(a, b)

def uniq(xs: List<&2, Nat>, +prev: Nat, +first: Bool) -> List<&2, Nat>:
  match xs:
    case []: []
    case +h <> +t:
      +r = uniq(t, h, False{})
      Bool.pick(List<&2, Nat>, Bool.and(Bool.not(first), Nat.is_eq(h, prev)), r, h <> r)

def bs(n: Nat, +tb: B.Tb<&2, Nat>, +k: Nat, +lo: Nat, +hi: Nat) -> Nat:
  match n:
    case 0n: lo
    case 1n+(+m):
      +mid = Nat.div(Nat.add(lo, hi), 2n)
      +v = B.tb_get(Nat, tb, U32.from_nat(mid))
      +eq = Nat.is_eq(v, k)
      +lt = Nat.is_lt(v, k)
      bs(m, tb, k, Bool.pick(Nat, eq, mid, Bool.pick(Nat, lt, Nat.add(mid, 1n), lo)), Bool.pick(Nat, eq, mid, Bool.pick(Nat, lt, hi, mid)))

type BX is Data:
  BX{ nx: Nat, ny: Nat, nz: Nat, hx: F64, hy: F64, hz: F64 }

def bx_mk(+nx: Nat, +ny: Nat, +nz: Nat, +hx: F64, +hy: F64, +hz: F64) -> BX:
  BX{nx, ny, nz, hx, hy, hz}

def vid(+b: BX, +i: Nat, +j: Nat, +k: Nat) -> Nat:
  BX{+nx, +ny, +nz, +hx, +hy, +hz} = b
  Nat.add(i, Nat.mul(Nat.add(nx, 1n), Nat.add(j, Nat.mul(Nat.add(ny, 1n), k))))

def vpos(+b: BX, +v: Nat) -> V.Point:
  BX{+nx, +ny, +nz, +hx, +hy, +hz} = b
  +i = Nat.mod(v, Nat.add(nx, 1n))
  +r = Nat.div(v, Nat.add(nx, 1n))
  +j = Nat.mod(r, Nat.add(ny, 1n))
  +k = Nat.div(r, Nat.add(ny, 1n))
  S.pt(F64.mul(hx, L.f64_of(i)), F64.mul(hy, L.f64_of(j)), F64.mul(hz, L.f64_of(k)))

def nv_of(+b: BX) -> Nat:
  BX{+nx, +ny, +nz, +hx, +hy, +hz} = b
  Nat.mul(Nat.add(nx, 1n), Nat.mul(Nat.add(ny, 1n), Nat.add(nz, 1n)))

def cell_tets(+b: BX, +i: Nat, +j: Nat, +k: Nat) -> List<&2, List<&2, Nat>>:
  +i1 = Nat.add(i, 1n)
  +j1 = Nat.add(j, 1n)
  +k1 = Nat.add(k, 1n)
  +c0 = vid(b, i, j, k)
  +c1 = vid(b, i1, j, k)
  +c2 = vid(b, i1, j1, k)
  +c3 = vid(b, i, j1, k)
  +c4 = vid(b, i, j, k1)
  +c5 = vid(b, i1, j, k1)
  +c6 = vid(b, i1, j1, k1)
  +c7 = vid(b, i, j1, k1)
  [[c0, c1, c2, c6], [c0, c2, c3, c6], [c0, c3, c7, c6], [c0, c7, c4, c6], [c0, c4, c5, c6], [c0, c5, c1, c6]]

def cells_i(+b: BX, ix: List<&2, Nat>, +j: Nat, +k: Nat) -> List<&2, List<&2, Nat>>:
  match ix:
    case []: []
    case +i <> +t: List.append(&2, List<&2, Nat>, cell_tets(b, i, j, k), cells_i(b, t, j, k))

def cells_j(+b: BX, js: List<&2, Nat>, +k: Nat, +ix: List<&2, Nat>) -> List<&2, List<&2, Nat>>:
  match js:
    case []: []
    case +j <> +t: List.append(&2, List<&2, Nat>, cells_i(b, ix, j, k), cells_j(b, t, k, ix))

def cells_k(+b: BX, ks: List<&2, Nat>, +js: List<&2, Nat>, +ix: List<&2, Nat>) -> List<&2, List<&2, Nat>>:
  match ks:
    case []: []
    case +k <> +t: List.append(&2, List<&2, Nat>, cells_j(b, js, k, ix), cells_k(b, t, js, ix))

def cells(+b: BX) -> List<&2, List<&2, Nat>>:
  BX{+nx, +ny, +nz, +hx, +hy, +hz} = b
  cells_k(b, L.nat_range(nz), L.nat_range(ny), L.nat_range(nx))

def ekey(+nv: Nat, +a: Nat, +c: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_lt(a, c), Nat.add(Nat.mul(a, nv), c), Nat.add(Nat.mul(c, nv), a))

def tet_keys(+nv: Nat, +t: List<&2, Nat>, es: List<&2, List<&2, Nat>>) -> List<&2, Nat>:
  match es:
    case []: []
    case +e <> +r: ekey(nv, L.nth_n(t, L.nth_n(e, 0n)), L.nth_n(t, L.nth_n(e, 1n))) <> tet_keys(nv, t, r)

def all_keys(ts: List<&2, List<&2, Nat>>, +nv: Nat) -> List<&2, Nat>:
  match ts:
    case []: []
    case +t <> +r: List.append(&2, Nat, tet_keys(nv, t, edges()), all_keys(r, nv))

def nso(s: B.So<&2, Nat>) -> List<&2, Nat>:
  B.So{+ok, +xs} = s
  xs

def mids(+nv: Nat, +tb: B.Tb<&2, Nat>, +ne: Nat, +t: List<&2, Nat>, es: List<&2, List<&2, Nat>>) -> List<&2, U32>:
  match es:
    case []: []
    case +e <> +r:
      U32.from_nat(Nat.add(nv, bs(40n, tb, ekey(nv, L.nth_n(t, L.nth_n(e, 0n)), L.nth_n(t, L.nth_n(e, 1n))), 0n, ne))) <> mids(nv, tb, ne, t, r)

def u32s(xs: List<&2, Nat>) -> List<&2, U32>:
  match xs:
    case []: []
    case +h <> +t: U32.from_nat(h) <> u32s(t)

def vposs(+b: BX, vs: List<&2, Nat>) -> List<&2, V.Point>:
  match vs:
    case []: []
    case +v <> +t: vpos(b, v) <> vposs(b, t)

def els_of(ts: List<&2, List<&2, Nat>>, +b: BX, +nv: Nat, +tb: B.Tb<&2, Nat>, +ne: Nat) -> List<&2, EL>:
  match ts:
    case []: []
    case +t <> +r:
      el_of(List.append(&2, U32, u32s(t), mids(nv, tb, ne, t, edges())), vposs(b, t)) <> els_of(r, b, nv, tb, ne)

def mid_pos(ks: List<&2, Nat>, +b: BX, +nv: Nat) -> List<&2, V.Point>:
  match ks:
    case []: []
    case +k <> +t:
      +p = vpos(b, Nat.div(k, nv))
      +q = vpos(b, Nat.mod(k, nv))
      S.padd(p, 0.5f64, S.psub(q, p)) <> mid_pos(t, b, nv)

type MH is Data:
  MH{ nn: U32, es: List<&2, EL>, xs: List<&2, V.Point> }

def box_mesh(+lx: F64, +ly: F64, +lz: F64, +nx: Nat, +ny: Nat, +nz: Nat) -> MH:
  +b = bx_mk(nx, ny, nz, F64.div(lx, L.f64_of(nx)), F64.div(ly, L.f64_of(ny)), F64.div(lz, L.f64_of(nz)))
  +nv = nv_of(b)
  +ts = cells(b)
  +ks = uniq(nso(B.msort(~Nat, ~ncmp, all_keys(ts, nv))), 0n, True{})
  +ne = List.length(&2, Nat, ks)
  +vs = vposs(b, L.nat_range(nv))
  MH{U32.from_nat(Nat.add(nv, ne)), els_of(ts, b, nv, B.tb_of(Nat, ks, 0n), ne), List.append(&2, V.Point, vs, mid_pos(ks, b, nv))}

def mget(rs: List<&2, List<&2, F64>>, +i: Nat, +j: Nat) -> F64:
  match rs:
    case []: 0.0f64
    case +r <> +t:
      match i:
        case 0n: L.nth_f64(r, j)
        case 1n+m: mget(t, m, j)

def set2(r: List<&2, F64>, +p: Nat, +q: Nat, +vp: F64, +vq: F64, +k: Nat) -> List<&2, F64>:
  match r:
    case []: []
    case +h <> +t: Bool.pick(F64, Nat.is_eq(k, p), vp, Bool.pick(F64, Nat.is_eq(k, q), vq, h)) <> set2(t, p, q, vp, vq, Nat.add(k, 1n))

def col_rot(rs: List<&2, List<&2, F64>>, +p: Nat, +q: Nat, +c: F64, +s: F64) -> List<&2, List<&2, F64>>:
  match rs:
    case []: []
    case +r <> +t:
      +a = L.nth_f64(r, p)
      +b = L.nth_f64(r, q)
      set2(r, p, q, F64.sub(F64.mul(c, a), F64.mul(s, b)), F64.add(F64.mul(s, a), F64.mul(c, b)), 0n) <> col_rot(t, p, q, c, s)

def lin2(xs: List<&2, F64>, ys: List<&2, F64>, +a: F64, +b: F64) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> +xt:
      match ys:
        case []: []
        case +y <> +yt: F64.add(F64.mul(a, x), F64.mul(b, y)) <> lin2(xt, yt, a, b)

def row_at(rs: List<&2, List<&2, F64>>, +i: Nat) -> List<&2, F64>:
  match rs:
    case []: []
    case +r <> +t:
      match i:
        case 0n: r
        case 1n+m: row_at(t, m)

def row_set(rs: List<&2, List<&2, F64>>, +p: Nat, +q: Nat, +rp: List<&2, F64>, +rq: List<&2, F64>, +k: Nat) -> List<&2, List<&2, F64>>:
  match rs:
    case []: []
    case +r <> +t: Bool.pick(List<&2, F64>, Nat.is_eq(k, p), rp, Bool.pick(List<&2, F64>, Nat.is_eq(k, q), rq, r)) <> row_set(t, p, q, rp, rq, Nat.add(k, 1n))

def row_rot(+rs: List<&2, List<&2, F64>>, +p: Nat, +q: Nat, +c: F64, +s: F64) -> List<&2, List<&2, F64>>:
  +a = row_at(rs, p)
  +b = row_at(rs, q)
  row_set(rs, p, q, lin2(a, b, c, F64.neg(s)), lin2(a, b, s, c), 0n)

type JA is Data:
  JA{ a: List<&2, List<&2, F64>>, v: List<&2, List<&2, F64>> }

def jrot(+j: JA, +p: Nat, +q: Nat) -> JA:
  JA{+a, +v} = j
  +apq = mget(a, p, q)
  +th = F64.div(F64.sub(mget(a, q, q), mget(a, p, p)), F64.mul(2.0f64, apq))
  +t = F64.div(Bool.pick(F64, F64.is_lt(th, 0.0f64), F64.neg(1.0f64), 1.0f64), F64.add(F64.abs(th), F64.sqrt(F64.add(F64.mul(th, th), 1.0f64))))
  +c = F64.div(1.0f64, F64.sqrt(F64.add(F64.mul(t, t), 1.0f64)))
  +s = F64.mul(t, c)
  +tiny = F64.is_le(F64.abs(apq), F64.mul(1.0e-300f64, 1.0f64))
  Bool.pick(JA, tiny, JA{a, v}, JA{row_rot(col_rot(a, p, q, c, s), p, q, c, s), col_rot(v, p, q, c, s)})

def jq(+p: Nat, qs: List<&2, Nat>) -> List<&2, List<&2, Nat>>:
  match qs:
    case []: []
    case +q <> +t: Bool.pick(List<&2, List<&2, Nat>>, Nat.is_lt(p, q), [p, q] <> jq(p, t), jq(p, t))

def jpairs(+n: Nat, ps: List<&2, Nat>) -> List<&2, List<&2, Nat>>:
  match ps:
    case []: []
    case +p <> +t: List.append(&2, List<&2, Nat>, jq(p, L.nat_range(n)), jpairs(n, t))

def jsweep(ps: List<&2, List<&2, Nat>>, +j: JA) -> JA:
  match ps:
    case []: j
    case +pq <> +t: jsweep(t, jrot(j, L.nth_n(pq, 0n), L.nth_n(pq, 1n)))

def jsweeps(n: Nat, +ps: List<&2, List<&2, Nat>>, +j: JA) -> JA:
  match n:
    case 0n: j
    case 1n+m: jsweeps(m, ps, jsweep(ps, j))

def ident_row(+n: Nat, +i: Nat, ks: List<&2, Nat>) -> List<&2, F64>:
  match ks:
    case []: []
    case +k <> +t: Bool.pick(F64, Nat.is_eq(k, i), 1.0f64, 0.0f64) <> ident_row(n, i, t)

def ident(+n: Nat, ix: List<&2, Nat>) -> List<&2, List<&2, F64>>:
  match ix:
    case []: []
    case +i <> +t: ident_row(n, i, L.nat_range(n)) <> ident(n, t)

def jacobi(+a: List<&2, List<&2, F64>>, +n: Nat) -> JA:
  +ps = jpairs(n, L.nat_range(n))
  jsweeps(12n, ps, JA{a, ident(n, L.nat_range(n))})

def m_m(+fm: FM, +mask: List<&2, F64>, +x: List<&2, F64>) -> List<&2, F64>:
  hadam(mask, apply_op(fm, True{}, hadam(mask, x)))

def proj(qs: List<&2, List<&2, F64>>, mqs: List<&2, List<&2, F64>>, +z: List<&2, F64>) -> List<&2, F64>:
  match qs:
    case []: z
    case +q <> +qt:
      match mqs:
        case []: z
        case +mq <> +mt: proj(qt, mt, axpy(F64.neg(dot_l(z, mq, 0.0f64)), q, z))

type QS is Data:
  QS{ q: List<&2, List<&2, F64>>, mq: List<&2, List<&2, F64>> }

def morth(ys: List<&2, List<&2, F64>>, +fm: FM, +mask: List<&2, F64>, +acc: QS) -> QS:
  match ys:
    case []: acc
    case +y <> +t:
      QS{+qs, +mqs} = acc
      +z = proj(qs, mqs, proj(qs, mqs, y))
      +mz = m_m(fm, mask, z)
      +k = F64.div(1.0f64, F64.sqrt(dot_l(z, mz, 0.0f64)))
      morth(t, fm, mask, QS{List.append(&2, List<&2, F64>, qs, [scale(k, z)]), List.append(&2, List<&2, F64>, mqs, [scale(k, mz)])})

def hd_f(xs: List<&2, F64>) -> F64:
  match xs:
    case []: 0.0f64
    case +h <> +t: h

def tl_f(xs: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: []
    case +h <> +t: t

def solves(xs: List<&2, List<&2, F64>>, +lam: List<&2, F64>, +fm: FM, +mask: List<&2, F64>, +pc: List<&2, F64>, +tol: F64) -> List<&2, List<&2, F64>>:
  match xs:
    case []: []
    case +x <> +t:
      +l = hd_f(lam)
      +x0 = scale(Bool.pick(F64, F64.is_lt(0.0f64, l), F64.div(1.0f64, l), 0.0f64), x)
      solve_from(fm, mask, pc, m_m(fm, mask, x), x0, 3000n, F64.mul(tol, F64.sqrt(dot_l(x, x, 0.0f64)))) <> solves(t, tl_f(lam), fm, mask, pc, tol)

def k_all(qs: List<&2, List<&2, F64>>, +fm: FM, +mask: List<&2, F64>) -> List<&2, List<&2, F64>>:
  match qs:
    case []: []
    case +q <> +t: k_m(fm, mask, q) <> k_all(t, fm, mask)

def comb_go(qs: List<&2, List<&2, F64>>, +col: List<&2, F64>, +acc: List<&2, F64>) -> List<&2, F64>:
  match qs:
    case []: acc
    case +q <> +t:
      match col:
        case []: acc
        case +c <> +ct: comb_go(t, ct, axpy(c, q, acc))

def colj(rs: List<&2, List<&2, F64>>, +j: Nat) -> List<&2, F64>:
  match rs:
    case []: []
    case +r <> +t: L.nth_f64(r, j) <> colj(t, j)

def hd_l(xs: List<&2, List<&2, F64>>) -> List<&2, F64>:
  match xs:
    case []: []
    case +h <> +t: h

def combs(+qs: List<&2, List<&2, F64>>, +v: List<&2, List<&2, F64>>, js: List<&2, Nat>) -> List<&2, List<&2, F64>>:
  match js:
    case []: []
    case +j <> +t: comb_go(qs, colj(v, j), scale(0.0f64, hd_l(qs))) <> combs(qs, v, t)

def diag_of(+a: List<&2, List<&2, F64>>, js: List<&2, Nat>) -> List<&2, F64>:
  match js:
    case []: []
    case +j <> +t: mget(a, j, j) <> diag_of(a, t)

type SI is Data:
  SI{ x: List<&2, List<&2, F64>>, lam: List<&2, F64> }

def gram_row(+x: List<&2, F64>, ys: List<&2, List<&2, F64>>) -> List<&2, F64>:
  match ys:
    case []: []
    case +y <> +t: dot_l(x, y, 0.0f64) <> gram_row(x, t)

def gram(xs: List<&2, List<&2, F64>>, +ys: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match xs:
    case []: []
    case +x <> +t: gram_row(x, ys) <> gram(t, ys)

def si_of(+qs: List<&2, List<&2, F64>>, +j: JA, +k: Nat) -> SI:
  JA{+a, +v} = j
  SI{combs(qs, v, L.nat_range(k)), diag_of(a, L.nat_range(k))}

def si_qs(+qm: QS, +fm: FM, +mask: List<&2, F64>, +k: Nat) -> SI:
  QS{+qs, +mqs} = qm
  si_of(qs, jacobi(gram(qs, k_all(qs, fm, mask)), k), k)

def sub_it(n: Nat, +fm: FM, +mask: List<&2, F64>, +k: Nat, +s: SI) -> SI:
  match n:
    case 0n: s
    case 1n+m:
      SI{+xs, +lam} = s
      sub_it(m, fm, mask, k, si_qs(morth(solves(xs, lam, fm, mask, precond(fm, mask), 1.0e-9f64), fm, mask, QS{[], []}), fm, mask, k))
