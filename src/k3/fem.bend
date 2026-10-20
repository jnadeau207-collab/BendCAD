import Base
import ../base/par.bend as B
import ../c01/types.bend as V
import ../k1/sf.bend as S
import ../k1/ls.bend as L

type EL is Data:
  EL{ ns: List<&2, U32>, g: List<&2, V.Dir>, v: F64 }
  EC{ ns: List<&2, U32>, ps: List<&2, V.Point> }

type FM is Data:
  FM{ nn: U32, rows: List<&2, List<&2, BE>>, rho: F64, sg: F64 }

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

def flat(ds: List<&2, V.Dir>) -> List<&2, F64>:
  match ds:
    case []: []
    case +d <> +t: S.dx(d) <> S.dy(d) <> S.dz(d) <> flat(t)

def wq() -> List<&2, List<&2, F64>>:
  +a = {0.3108859192633006f64 : F64}
  +b = {0.0673422422100982f64 : F64}
  +c = {0.0927352503108912f64 : F64}
  +d = {0.7217942490673264f64 : F64}
  +e = {0.4544962958743504f64 : F64}
  +f = {0.0455037041256496f64 : F64}
  +w1 = {0.1126879257180159f64 : F64}
  +w2 = {0.0734930431163619f64 : F64}
  +w3 = {0.0425460207770815f64 : F64}
  [[b, a, a, a, w1], [a, b, a, a, w1], [a, a, b, a, w1], [a, a, a, b, w1],
   [d, c, c, c, w2], [c, d, c, c, w2], [c, c, d, c, w2], [c, c, c, d, w2],
   [e, e, f, f, w3], [e, f, e, f, w3], [e, f, f, e, w3], [f, e, e, f, w3], [f, e, f, e, w3], [f, f, e, e, w3]]

def ref_gl() -> List<&2, V.Dir>:
  [S.dr(F64.neg(1.0f64), F64.neg(1.0f64), F64.neg(1.0f64)), S.dr(1.0f64, 0.0f64, 0.0f64), S.dr(0.0f64, 1.0f64, 0.0f64), S.dr(0.0f64, 0.0f64, 1.0f64)]

def pdir(+p: V.Point) -> V.Dir:
  S.dr(V.pt_x(p), V.pt_y(p), V.pt_z(p))

type J3 is Data:
  J3{ a: V.Dir, b: V.Dir, c: V.Dir }

def jac(ps: List<&2, V.Point>, rg: List<&2, V.Dir>, +j: J3) -> J3:
  match ps:
    case []: j
    case +p <> +pt:
      match rg:
        case []: j
        case +g <> +gt:
          J3{+a, +b, +c} = j
          +x = pdir(p)
          jac(pt, gt, J3{S.dadd(a, S.dx(g), x), S.dadd(b, S.dy(g), x), S.dadd(c, S.dz(g), x)})

def phys(rg: List<&2, V.Dir>, +bc: V.Dir, +ca: V.Dir, +ab: V.Dir, +id: F64) -> List<&2, V.Dir>:
  match rg:
    case []: []
    case +g <> +t: S.dscale(id, S.dadd(S.dadd(S.dscale(S.dx(g), bc), S.dy(g), ca), S.dz(g), ab)) <> phys(t, bc, ca, ab, id)

type QG is Data:
  QG{ gs: List<&2, V.Dir>, w: F64 }

def qg_go(+rg: List<&2, V.Dir>, +j: J3, +w: F64) -> QG:
  J3{+a, +b, +c} = j
  +bc = S.cross(b, c)
  +det = S.dot(a, bc)
  QG{phys(rg, bc, S.cross(c, a), S.cross(a, b), F64.div(1.0f64, det)), F64.mul(w, F64.div(F64.abs(det), 6.0f64))}

def qg_of(+ps: List<&2, V.Point>, +q: List<&2, F64>) -> QG:
  +rg = grads(q, ref_gl())
  +z = S.dr(0.0f64, 0.0f64, 0.0f64)
  qg_go(rg, jac(ps, rg, J3{z, z, z}), L.nth_f64(q, 4n))

def nvals(+l: List<&2, F64>) -> List<&2, F64>:
  +l1 = L.nth_f64(l, 0n)
  +l2 = L.nth_f64(l, 1n)
  +l3 = L.nth_f64(l, 2n)
  +l4 = L.nth_f64(l, 3n)
  [F64.mul(l1, F64.sub(F64.mul(2.0f64, l1), 1.0f64)), F64.mul(l2, F64.sub(F64.mul(2.0f64, l2), 1.0f64)),
   F64.mul(l3, F64.sub(F64.mul(2.0f64, l3), 1.0f64)), F64.mul(l4, F64.sub(F64.mul(2.0f64, l4), 1.0f64)),
   F64.mul(4.0f64, F64.mul(l1, l2)), F64.mul(4.0f64, F64.mul(l2, l3)), F64.mul(4.0f64, F64.mul(l3, l1)),
   F64.mul(4.0f64, F64.mul(l1, l4)), F64.mul(4.0f64, F64.mul(l2, l4)), F64.mul(4.0f64, F64.mul(l3, l4))]

type M9 is Data:
  M9{ a: F64, b: F64, c: F64, d: F64, e: F64, f: F64, g: F64, h: F64, i: F64 }

type BE is Data:
  BE{ r: U32, c: U32, k: M9, m: F64 }

def m9z() -> M9:
  M9{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}

def m9_add(+x: M9, +y: M9) -> M9:
  M9{+a, +b, +c, +d, +e, +f, +g, +h, +i} = x
  M9{+a2, +b2, +c2, +d2, +e2, +f2, +g2, +h2, +i2} = y
  M9{F64.add(a, a2), F64.add(b, b2), F64.add(c, c2), F64.add(d, d2), F64.add(e, e2), F64.add(f, f2), F64.add(g, g2), F64.add(h, h2), F64.add(i, i2)}

def kab(+ga: V.Dir, +gb: V.Dir, +w: F64, +lam: F64, +mu: F64) -> M9:
  +ax = S.dx(ga)
  +ay = S.dy(ga)
  +az = S.dz(ga)
  +bx = S.dx(gb)
  +by = S.dy(gb)
  +bz = S.dz(gb)
  +d = F64.mul(mu, F64.add(F64.add(F64.mul(ax, bx), F64.mul(ay, by)), F64.mul(az, bz)))
  M9{F64.mul(w, F64.add(F64.add(F64.mul(lam, F64.mul(ax, bx)), F64.mul(mu, F64.mul(ax, bx))), d)),
    F64.mul(w, F64.add(F64.mul(lam, F64.mul(ax, by)), F64.mul(mu, F64.mul(ay, bx)))),
    F64.mul(w, F64.add(F64.mul(lam, F64.mul(ax, bz)), F64.mul(mu, F64.mul(az, bx)))),
    F64.mul(w, F64.add(F64.mul(lam, F64.mul(ay, bx)), F64.mul(mu, F64.mul(ax, by)))),
    F64.mul(w, F64.add(F64.add(F64.mul(lam, F64.mul(ay, by)), F64.mul(mu, F64.mul(ay, by))), d)),
    F64.mul(w, F64.add(F64.mul(lam, F64.mul(ay, bz)), F64.mul(mu, F64.mul(az, by)))),
    F64.mul(w, F64.add(F64.mul(lam, F64.mul(az, bx)), F64.mul(mu, F64.mul(ax, bz)))),
    F64.mul(w, F64.add(F64.mul(lam, F64.mul(az, by)), F64.mul(mu, F64.mul(ay, bz)))),
    F64.mul(w, F64.add(F64.add(F64.mul(lam, F64.mul(az, bz)), F64.mul(mu, F64.mul(az, bz))), d))}

def k_row(+ga: V.Dir, gs: List<&2, V.Dir>, +w: F64, +lam: F64, +mu: F64, ks: List<&2, M9>) -> List<&2, M9>:
  match gs:
    case []: []
    case +g <> +gt:
      match ks:
        case []: []
        case +k <> +kt: m9_add(k, kab(ga, g, w, lam, mu)) <> k_row(ga, gt, w, lam, mu, kt)

def k_rows(ga: List<&2, V.Dir>, +gs: List<&2, V.Dir>, +w: F64, +lam: F64, +mu: F64, +ks: List<&2, M9>) -> List<&2, M9>:
  match ga:
    case []: []
    case +g <> +gt: List.append(&2, M9, k_row(g, gs, w, lam, mu, B.take_u(M9, ks, 10, False{})), k_rows(gt, gs, w, lam, mu, B.drop_u(M9, ks, 10, False{})))

def m_row(+na: F64, ns: List<&2, F64>, +w: F64, ms: List<&2, F64>) -> List<&2, F64>:
  match ns:
    case []: []
    case +n <> +nt:
      match ms:
        case []: []
        case +m <> +mt: F64.add(m, F64.mul(w, F64.mul(na, n))) <> m_row(na, nt, w, mt)

def m_rows2(na: List<&2, F64>, +ns: List<&2, F64>, +w: F64, +ms: List<&2, F64>) -> List<&2, F64>:
  match na:
    case []: []
    case +a <> +at: List.append(&2, F64, m_row(a, ns, w, B.take_u(F64, ms, 10, False{})), m_rows2(at, ns, w, B.drop_u(F64, ms, 10, False{})))

def m9s(n: Nat) -> List<&2, M9>:
  match n:
    case 0n: []
    case 1n+m: m9z() <> m9s(m)

def f0s(n: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m: 0.0f64 <> f0s(m)

type EB is Data:
  EB{ k: List<&2, M9>, m: List<&2, F64> }

def aff_k(qs: List<&2, List<&2, F64>>, +gl: List<&2, V.Dir>, +w: F64, +lam: F64, +mu: F64, +ks: List<&2, M9>) -> List<&2, M9>:
  match qs:
    case []: ks
    case +q <> +t:
      +gs = grads(q, gl)
      aff_k(t, gl, w, lam, mu, k_rows(gs, gs, w, lam, mu, ks))

def flat_rows(rs: List<&2, List<&2, F64>>, +k: F64) -> List<&2, F64>:
  match rs:
    case []: []
    case +r <> +t: List.append(&2, F64, scale(k, r), flat_rows(t, k))

def eb_q(+g: QG, +nv: List<&2, F64>, +lam: F64, +mu: F64, +acc: EB) -> EB:
  QG{+gs, +w} = g
  EB{+ks, +ms} = acc
  EB{k_rows(gs, gs, w, lam, mu, ks), m_rows2(nv, nv, w, ms)}

def cur_eb(qs: List<&2, List<&2, F64>>, +ps: List<&2, V.Point>, +lam: F64, +mu: F64, +acc: EB) -> EB:
  match qs:
    case []: acc
    case +q <> +t: cur_eb(t, ps, lam, mu, eb_q(qg_of(ps, q), nvals(q), lam, mu, acc))

def el_ns(e: EL) -> List<&2, U32>:
  match e:
    case EL{+ns, +gl, +v}: ns
    case EC{+ns, +ps}: ns

def el_eb(e: EL, +lam: F64, +mu: F64) -> EB:
  match e:
    case EL{+ns, +gl, +v}: EB{aff_k(gq(), gl, F64.mul(0.25f64, v), lam, mu, m9s(100n)), flat_rows(mref(), F64.div(v, 420.0f64))}
    case EC{+ns, +ps}: cur_eb(wq(), ps, lam, mu, EB{m9s(100n), f0s(100n)})

def be_col(+r: U32, cs: List<&2, U32>, ks: List<&2, M9>, ms: List<&2, F64>, +acc: List<&2, BE>) -> List<&2, BE>:
  match cs:
    case []: acc
    case +c <> +ct:
      match ks:
        case []: acc
        case +k <> +kt:
          match ms:
            case []: acc
            case +m <> +mt: be_col(r, ct, kt, mt, BE{r, c, k, m} <> acc)

def be_rows(rs: List<&2, U32>, +cs: List<&2, U32>, +ks: List<&2, M9>, +ms: List<&2, F64>, +acc: List<&2, BE>) -> List<&2, BE>:
  match rs:
    case []: acc
    case +r <> +rt: be_rows(rt, cs, B.drop_u(M9, ks, 10, False{}), B.drop_u(F64, ms, 10, False{}), be_col(r, cs, B.take_u(M9, ks, 10, False{}), B.take_u(F64, ms, 10, False{}), acc))

type LM is Data:
  LM{ lam: F64, mu: F64 }

def eb_bes(+b: EB, +ns: List<&2, U32>) -> List<&2, BE>:
  EB{+ks, +ms} = b
  be_rows(ns, ns, ks, ms, [])

def el_bes_go(+c: LM, +e: EL) -> List<&2, BE>:
  LM{+lam, +mu} = c
  eb_bes(el_eb(e, lam, mu), el_ns(e))

def el_bes(c: LM, e: EL) -> List<&2, BE>:
  el_bes_go(c, e)

def be_cmp2(+x: BE, +y: BE) -> B.Sgn:
  BE{+r, +c, k, m} = x
  BE{+r2, +c2, k2, m2} = y
  B.sgn_pick(Bool.or(U32.is_lt(r, r2), Bool.and(U32.is_eq(r, r2), U32.is_lt(c, c2))), Bool.or(U32.is_lt(r2, r), Bool.and(U32.is_eq(r, r2), U32.is_lt(c2, c))))

def be_cmp(x: BE, y: BE) -> B.Sgn:
  be_cmp2(x, y)

def so_be(s: B.So<&2, BE>) -> List<&2, BE>:
  B.So{+ok, +xs} = s
  xs

def be_same(+x: BE, +y: BE) -> Bool:
  BE{+r, +c, k, m} = x
  BE{+r2, +c2, k2, m2} = y
  Bool.and(U32.is_eq(r, r2), U32.is_eq(c, c2))

def be_add(+x: BE, +y: BE) -> BE:
  BE{+r, +c, +k, +m} = x
  BE{r2, c2, +k2, +m2} = y
  BE{r, c, m9_add(k, k2), F64.add(m, m2)}

def be_r(+x: BE) -> U32:
  BE{+r, c, k, m} = x
  r

type MG is Data:
  MG{ cur: BE, out: List<&2, BE>, rows: List<&2, List<&2, BE>> }

def mg_new(nrow: Bool, +x: BE, +cur: BE, +out: List<&2, BE>, +rows: List<&2, List<&2, BE>>) -> MG:
  match nrow:
    case True{}: MG{x, cur <> out, rows}
    case False{}: MG{x, [], List.reverse(&2, BE, cur <> out) <> rows}

def mg_pick(same: Bool, +nrow: Bool, +x: BE, +cur: BE, +out: List<&2, BE>, +rows: List<&2, List<&2, BE>>) -> MG:
  match same:
    case True{}: MG{be_add(cur, x), out, rows}
    case False{}: mg_new(nrow, x, cur, out, rows)

def mg_step(+x: BE, +g: MG) -> MG:
  MG{+cur, +out, +rows} = g
  mg_pick(be_same(x, cur), U32.is_eq(be_r(x), be_r(cur)), x, cur, out, rows)

def mg_fin(+g: MG) -> List<&2, List<&2, BE>>:
  MG{+cur, +out, +rows} = g
  List.reverse(&2, List<&2, BE>, List.reverse(&2, BE, cur <> out) <> rows)

def merge_be(xs: List<&2, BE>, +g: MG) -> List<&2, List<&2, BE>>:
  match xs:
    case []: mg_fin(g)
    case +x <> +t: merge_be(t, mg_step(x, g))

def cat_be(xs: List<&2, List<&2, BE>>) -> List<&2, BE>:
  match xs:
    case []: []
    case +h <> +t: List.append(&2, BE, h, cat_be(t))

def hd_be(xs: List<&2, BE>) -> BE:
  match xs:
    case []: BE{0, 0, m9z(), 0.0f64}
    case +x <> +t: x

def tl_be(xs: List<&2, BE>) -> List<&2, BE>:
  match xs:
    case []: []
    case +x <> +t: t

def assemble(+es: List<&2, EL>, +lam: F64, +mu: F64) -> List<&2, List<&2, BE>>:
  +all = so_be(B.msort(~BE, ~be_cmp, cat_be(B.pmap_g(~EL, ~LM, ~List<&2, BE>, ~el_bes, 16, LM{lam, mu}, es))))
  merge_be(tl_be(all), MG{hd_be(all), [], []})

type SX is Data:
  SX{ x: B.Tb<&2, V.Dir>, ks: F64, ms: F64 }

def m9_mv(+k: M9, +u: V.Dir) -> V.Dir:
  M9{+a, +b, +c, +d, +e, +f, +g, +h, +i} = k
  +x = S.dx(u)
  +y = S.dy(u)
  +z = S.dz(u)
  S.dr(F64.add(F64.add(F64.mul(a, x), F64.mul(b, y)), F64.mul(c, z)), F64.add(F64.add(F64.mul(d, x), F64.mul(e, y)), F64.mul(f, z)),
    F64.add(F64.add(F64.mul(g, x), F64.mul(h, y)), F64.mul(i, z)))

def row_mv(row: List<&2, BE>, +x: B.Tb<&2, V.Dir>, +ks: F64, +ms: F64, +acc: V.Dir) -> V.Dir:
  match row:
    case []: acc
    case +be <> +t:
      BE{r, +c, +k, +m} = be
      +u = B.tb_get(V.Dir, x, c)
      row_mv(t, x, ks, ms, S.dadd(S.dadd(acc, ks, m9_mv(k, u)), F64.mul(ms, m), u))

def row_f(s: SX, row: List<&2, BE>) -> V.Dir:
  SX{+x, +ks, +ms} = s
  row_mv(row, x, ks, ms, S.dr(0.0f64, 0.0f64, 0.0f64))

def trip(xs: List<&2, F64>) -> List<&2, V.Dir>:
  match xs:
    case []: []
    case +a <> +t1:
      match t1:
        case []: []
        case +b <> +t2:
          match t2:
            case []: []
            case +c <> +t3: S.dr(a, b, c) <> trip(t3)

def spmv(+rows: List<&2, List<&2, BE>>, +ks: F64, +ms: F64, +xs: List<&2, F64>) -> List<&2, F64>:
  flat(B.pmap_g(~List<&2, BE>, ~SX, ~V.Dir, ~row_f, 64, SX{B.tb_of(V.Dir, trip(xs), S.dr(0.0f64, 0.0f64, 0.0f64)), ks, ms}, rows))

def row_dg(row: List<&2, BE>, +ks: F64, +ms: F64) -> V.Dir:
  match row:
    case []: S.dr(0.0f64, 0.0f64, 0.0f64)
    case +be <> +t:
      BE{+rr, +c, +k, +m} = be
      M9{+a, b, c2, d, +e, f, g, h, +i} = k
      Bool.pick(V.Dir, U32.is_eq(c, rr), S.dr(F64.add(F64.mul(ks, a), F64.mul(ms, m)), F64.add(F64.mul(ks, e), F64.mul(ms, m)), F64.add(F64.mul(ks, i), F64.mul(ms, m))),
        row_dg(t, ks, ms))

def diag_rows(rs: List<&2, List<&2, BE>>, +ks: F64, +ms: F64) -> List<&2, V.Dir>:
  match rs:
    case []: []
    case +r <> +t: row_dg(r, ks, ms) <> diag_rows(t, ks, ms)

type BV is Data:
  BV{ x: B.Tb<&2, List<&2, V.Dir>>, ks: F64, ms: F64 }

def mv_cols(+k: M9, +km: F64, us: List<&2, V.Dir>, acc: List<&2, V.Dir>) -> List<&2, V.Dir>:
  match us:
    case []: []
    case +u <> +ut:
      match acc:
        case []: []
        case +a <> +at: S.dadd(S.dadd(a, 1.0f64, m9_mv(k, u)), km, u) <> mv_cols(k, km, ut, at)

def m9_sc(+s: F64, +x: M9) -> M9:
  M9{+a, +b, +c, +d, +e, +f, +g, +h, +i} = x
  M9{F64.mul(s, a), F64.mul(s, b), F64.mul(s, c), F64.mul(s, d), F64.mul(s, e), F64.mul(s, f), F64.mul(s, g), F64.mul(s, h), F64.mul(s, i)}

def brow_mv(row: List<&2, BE>, +x: B.Tb<&2, List<&2, V.Dir>>, +ks: F64, +ms: F64, +acc: List<&2, V.Dir>) -> List<&2, V.Dir>:
  match row:
    case []: acc
    case +be <> +t:
      BE{r, +c, +k, +m} = be
      brow_mv(t, x, ks, ms, mv_cols(m9_sc(ks, k), F64.mul(ms, m), B.tb_get(List<&2, V.Dir>, x, c), acc))

def zcols(n: Nat) -> List<&2, V.Dir>:
  match n:
    case 0n: []
    case 1n+(+m): S.dr(0.0f64, 0.0f64, 0.0f64) <> zcols(m)

def brow_f(s: BV, row: List<&2, BE>) -> List<&2, V.Dir>:
  BV{+x, +ks, +ms} = s
  brow_mv(row, x, ks, ms, zcols(List.length(&2, V.Dir, B.tb_get(List<&2, V.Dir>, x, 0))))

def bspmv(+rows: List<&2, List<&2, BE>>, +ks: F64, +ms: F64, +xs: List<&2, List<&2, V.Dir>>) -> List<&2, List<&2, V.Dir>>:
  B.pmap_g(~List<&2, BE>, ~BV, ~List<&2, V.Dir>, ~brow_f, 64, BV{B.tb_of(List<&2, V.Dir>, xs, []), ks, ms}, rows)

def apply_op(+fm: FM, +mass: Bool, +xs: List<&2, F64>) -> List<&2, F64>:
  FM{+nn, +rows, +rho, +sg} = fm
  Bool.pick(List<&2, F64>, mass, spmv(rows, 0.0f64, rho, xs), spmv(rows, 1.0f64, F64.mul(sg, rho), xs))
def k_diag(+fm: FM) -> List<&2, F64>:
  FM{+nn, +rows, +rho, +sg} = fm
  flat(diag_rows(rows, 1.0f64, F64.mul(sg, rho)))
def fm_of(+nn: U32, +es: List<&2, EL>, +e: F64, +nu: F64, +rho: F64) -> FM:
  +lam = F64.div(F64.mul(e, nu), F64.mul(F64.add(1.0f64, nu), F64.sub(1.0f64, F64.mul(2.0f64, nu))))
  +mu = F64.div(e, F64.mul(2.0f64, F64.add(1.0f64, nu)))
  FM{nn, assemble(es, lam, mu), rho, 0.0f64}

def fm_sig(+fm: FM, +sg: F64) -> FM:
  FM{+nn, +rows, +rho, s0} = fm
  FM{nn, rows, rho, sg}

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

def precond(+fm: FM, +mask: List<&2, F64>) -> List<&2, F64>:
  hadam(mask, inv_d(mask, k_diag(fm)))

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
    case +q <> +t:
      +rest = jq(p, t)
      Bool.pick(List<&2, List<&2, Nat>>, Nat.is_lt(p, q), [p, q] <> rest, rest)

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

type QS is Data:
  QS{ q: List<&2, List<&2, F64>>, mq: List<&2, List<&2, F64>> }

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

type IX is Data:
  IX{ v: F64, i: Nat }

def ix_cmp(a: IX, b: IX) -> B.Sgn:
  IX{+av, ai} = a
  IX{+bv, bi} = b
  Bool.pick(B.Sgn, F64.is_lt(av, bv), B.Sn{}, Bool.pick(B.Sgn, F64.is_lt(bv, av), B.Sp{}, B.Sz{}))

def ixs(vs: List<&2, F64>, +i: Nat) -> List<&2, IX>:
  match vs:
    case []: []
    case +v <> +t: IX{v, i} <> ixs(t, Nat.add(i, 1n))

def so_ix(s: B.So<&2, IX>) -> List<&2, IX>:
  B.So{ok, xs} = s
  xs

def ix_take(k: Nat, xs: List<&2, IX>) -> List<&2, IX>:
  match k:
    case 0n: []
    case 1n+j:
      match xs:
        case []: []
        case +h <> +t: h <> ix_take(j, t)

def ix_i(xs: List<&2, IX>) -> List<&2, Nat>:
  match xs:
    case []: []
    case +h <> +t:
      IX{v, +i} = h
      i <> ix_i(t)

def ix_v(xs: List<&2, IX>) -> List<&2, F64>:
  match xs:
    case []: []
    case +h <> +t:
      IX{+v, i} = h
      v <> ix_v(t)

def drop_l(n: Nat, xs: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match n:
    case 0n: xs
    case 1n+j:
      match xs:
        case []: []
        case +h <> +t: drop_l(j, t)

def hds(cs: List<&2, List<&2, V.Dir>>) -> List<&2, V.Dir>:
  match cs:
    case []: []
    case +c <> +t:
      match c:
        case []: hds(t)
        case +h <> +r: h <> hds(t)

def tls(cs: List<&2, List<&2, V.Dir>>) -> List<&2, List<&2, V.Dir>>:
  match cs:
    case []: []
    case +c <> +t:
      match c:
        case []: [] <> tls(t)
        case +h <> +r: r <> tls(t)

def tcol(n: Nat, +cs: List<&2, List<&2, V.Dir>>) -> List<&2, List<&2, V.Dir>>:
  match n:
    case 0n: []
    case 1n+(+m): hds(cs) <> tcol(m, tls(cs))

def trip_f(c: F64, xs: List<&2, F64>) -> List<&2, V.Dir>:
  trip(xs)

def flat_f(c: F64, xs: List<&2, V.Dir>) -> List<&2, F64>:
  flat(xs)

def had_f(m: List<&2, F64>, xs: List<&2, F64>) -> List<&2, F64>:
  hadam(m, xs)

def cmask(+mask: List<&2, F64>, +qs: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  B.pmap_g(~List<&2, F64>, ~List<&2, F64>, ~List<&2, F64>, ~had_f, 1, mask, qs)

def blk_op(+fm: FM, +mask: List<&2, F64>, +mass: Bool, +qs: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  FM{+nn, +rows, +rho, +sg} = fm
  +k = List.length(&2, List<&2, F64>, qs)
  +nm = tcol(U32.to_nat(nn), B.pmap_g(~List<&2, F64>, ~F64, ~List<&2, V.Dir>, ~trip_f, 1, 0.0f64, cmask(mask, qs)))
  +ys = bspmv(rows, Bool.pick(F64, mass, 0.0f64, 1.0f64), Bool.pick(F64, mass, rho, F64.mul(sg, rho)), nm)
  cmask(mask, B.pmap_g(~List<&2, V.Dir>, ~F64, ~List<&2, F64>, ~flat_f, 1, 0.0f64, tcol(k, ys)))

type C2 is Data:
  C2{ p: List<&2, F64>, q: List<&2, F64> }

type C3 is Data:
  C3{ a: F64, p: List<&2, F64>, x: List<&2, F64> }

def zip2(ps: List<&2, List<&2, F64>>, qs: List<&2, List<&2, F64>>) -> List<&2, C2>:
  match ps:
    case []: []
    case +p <> +pt:
      match qs:
        case []: []
        case +q <> +qt: C2{p, q} <> zip2(pt, qt)

def zip3(as: List<&2, F64>, ps: List<&2, List<&2, F64>>, xs: List<&2, List<&2, F64>>) -> List<&2, C3>:
  match as:
    case []: []
    case +a <> +at:
      match ps:
        case []: []
        case +p <> +pt:
          match xs:
            case []: []
            case +x <> +xt: C3{a, p, x} <> zip3(at, pt, xt)

def dot_f(c: F64, z: C2) -> F64:
  C2{+p, +q} = z
  dot_l(p, q, 0.0f64)

def ax_f(c: F64, z: C3) -> List<&2, F64>:
  C3{+a, +p, +x} = z
  axpy(a, p, x)

def cdots(+ps: List<&2, List<&2, F64>>, +qs: List<&2, List<&2, F64>>) -> List<&2, F64>:
  B.pmap_g(~C2, ~F64, ~F64, ~dot_f, 1, 0.0f64, zip2(ps, qs))

def caxpy(+as: List<&2, F64>, +ps: List<&2, List<&2, F64>>, +xs: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  B.pmap_g(~C3, ~F64, ~List<&2, F64>, ~ax_f, 1, 0.0f64, zip3(as, ps, xs))

def sdiv(+a: F64, +b: F64) -> F64:
  Bool.pick(F64, F64.is_eq(b, 0.0f64), 0.0f64, F64.div(a, b))

def zdiv(as: List<&2, F64>, bs: List<&2, F64>) -> List<&2, F64>:
  match as:
    case []: []
    case +a <> +at:
      match bs:
        case []: []
        case +b <> +bt: sdiv(a, b) <> zdiv(at, bt)

def negs(xs: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> +t: F64.neg(x) <> negs(t)

type PC is Data:
  PC{ x: List<&2, List<&2, F64>>, r: List<&2, List<&2, F64>>, p: List<&2, List<&2, F64>>, rz: List<&2, F64> }

def bpcg_st(+fm: FM, +mask: List<&2, F64>, +pc: List<&2, F64>, +s: PC) -> PC:
  PC{+x, +r, +p, +rz} = s
  +q = blk_op(fm, mask, False{}, p)
  +al = zdiv(rz, cdots(p, q))
  +r2 = caxpy(negs(al), q, r)
  +z2 = cmask(pc, r2)
  +rz2 = cdots(r2, z2)
  PC{caxpy(al, p, x), r2, caxpy(zdiv(rz2, rz), p, z2), rz2}

def bpcg(n: Nat, +fm: FM, +mask: List<&2, F64>, +pc: List<&2, F64>, +s: PC) -> List<&2, List<&2, F64>>:
  match n:
    case 0n:
      PC{+x, r, p, rz} = s
      x
    case 1n+(+m): bpcg(m, fm, mask, pc, bpcg_st(fm, mask, pc, s))

def zero_f(c: F64, xs: List<&2, F64>) -> List<&2, F64>:
  scale(0.0f64, xs)

def bsolve(+fm: FM, +mask: List<&2, F64>, +pc: List<&2, F64>, +rs: List<&2, List<&2, F64>>, +n: Nat) -> List<&2, List<&2, F64>>:
  +z = cmask(pc, rs)
  bpcg(n, fm, mask, pc, PC{B.pmap_g(~List<&2, F64>, ~F64, ~List<&2, F64>, ~zero_f, 1, 0.0f64, rs), rs, z, cdots(rs, z)})

def gram_f(ys: List<&2, List<&2, F64>>, x: List<&2, F64>) -> List<&2, F64>:
  gram_row(x, ys)

def pgram(+xs: List<&2, List<&2, F64>>, +ys: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  B.pmap_g(~List<&2, F64>, ~List<&2, List<&2, F64>>, ~List<&2, F64>, ~gram_f, 1, ys, xs)

type CB is Data:
  CB{ qs: List<&2, List<&2, F64>>, z: List<&2, F64> }

type CJ is Data:
  CJ{ col: List<&2, F64>, s: F64 }

def comb_f(c: CB, j: CJ) -> List<&2, F64>:
  CB{+qs, +z} = c
  CJ{+col, +s} = j
  scale(s, comb_go(qs, col, z))

def cjs(+v: List<&2, List<&2, F64>>, js: List<&2, Nat>, ss: List<&2, F64>) -> List<&2, CJ>:
  match js:
    case []: []
    case +j <> +t:
      match ss:
        case []: []
        case +s <> +st: CJ{colj(v, j), s} <> cjs(v, t, st)

def pcombs(+qs: List<&2, List<&2, F64>>, +v: List<&2, List<&2, F64>>, +js: List<&2, Nat>, +ss: List<&2, F64>) -> List<&2, List<&2, F64>>:
  B.pmap_g(~CJ, ~CB, ~List<&2, F64>, ~comb_f, 1, CB{qs, scale(0.0f64, hd_l(qs))}, cjs(v, js, ss))

def ones_l(n: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m): 1.0f64 <> ones_l(m)

def fmax(xs: List<&2, F64>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> +t: fmax(t, F64.max(acc, x))

def pc_rz(+s: PC) -> List<&2, F64>:
  PC{x, r, p, +rz} = s
  rz


def bpcg_tol(n: Nat, done: Bool, +fm: FM, +mask: List<&2, F64>, +pc: List<&2, F64>, +tol: F64, +s: PC) -> PC:
  match n:
    case 0n: s
    case 1n+(+m):
      match done:
        case True{}: s
        case False{}:
          +s2 = bpcg_st(fm, mask, pc, s)
          bpcg_tol(m, F64.is_lt(fmax(pc_rz(s2), 0.0f64), tol), fm, mask, pc, tol, s2)

type SV is Data:
  SV{ x: List<&2, List<&2, F64>>, rz: F64 }

def sv_of(+s: PC) -> SV:
  PC{+x, r, p, +rz} = s
  SV{x, fmax(rz, 0.0f64)}

def bsolve_tol(+fm: FM, +mask: List<&2, F64>, +rs: List<&2, List<&2, F64>>, +n: Nat, +rtol: F64) -> SV:
  +pc = precond(fm, mask)
  +z = cmask(pc, rs)
  +rz0 = cdots(rs, z)
  +s = bpcg_tol(n, False{}, fm, mask, pc, F64.mul(F64.mul(rtol, rtol), fmax(rz0, 0.0f64)), PC{B.pmap_g(~List<&2, F64>, ~F64, ~List<&2, F64>, ~zero_f, 1, 0.0f64, rs), rs, z, rz0})
  sv_of(s)

def keep_js(xs: List<&2, F64>, +i: Nat, +tol: F64) -> List<&2, Nat>:
  match xs:
    case []: []
    case +x <> +t:
      +rest = keep_js(t, Nat.add(i, 1n), tol)
      Bool.pick(List<&2, Nat>, F64.is_lt(tol, x), i <> rest, rest)

def inv_sq(js: List<&2, Nat>, +d: List<&2, F64>) -> List<&2, F64>:
  match js:
    case []: []
    case +j <> +t: F64.div(1.0f64, F64.sqrt(L.nth_f64(d, j))) <> inv_sq(t, d)

def mon_ja(j: JA, +qs: List<&2, List<&2, F64>>, +mq: List<&2, List<&2, F64>>, +m: Nat) -> QS:
  JA{+a, +v} = j
  +d = diag_of(a, L.nat_range(m))
  +js = keep_js(d, 0n, F64.mul(1.0e-13f64, fmax(d, 0.0f64)))
  +ss = inv_sq(js, d)
  QS{pcombs(qs, v, js, ss), pcombs(mq, v, js, ss)}

def mon(+fm: FM, +mask: List<&2, F64>, +qs: List<&2, List<&2, F64>>) -> QS:
  +mq = blk_op(fm, mask, True{}, qs)
  +m = List.length(&2, List<&2, F64>, qs)
  mon_ja(jacobi(pgram(qs, mq), m), qs, mq, m)

def qs_q(+q: QS) -> List<&2, List<&2, F64>>:
  QS{+qs, mq} = q
  qs

def mon2(+fm: FM, +mask: List<&2, F64>, +qs: List<&2, List<&2, F64>>) -> QS:
  mon(fm, mask, qs_q(mon(fm, mask, qs)))

type PX is Data:
  PX{ xs: List<&2, List<&2, F64>>, c: List<&2, List<&2, F64>> }

type YJ is Data:
  YJ{ y: List<&2, F64>, j: Nat }

def yjs(ys: List<&2, List<&2, F64>>, +j: Nat) -> List<&2, YJ>:
  match ys:
    case []: []
    case +y <> +t: YJ{y, j} <> yjs(t, Nat.add(j, 1n))

def orth_f(c: PX, yj: YJ) -> List<&2, F64>:
  PX{+xs, +cm} = c
  YJ{+y, +j} = yj
  comb_go(xs, negs(colj(cm, j)), y)

def proj_x(+xs: List<&2, List<&2, F64>>, +mxs: List<&2, List<&2, F64>>, +ys: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  B.pmap_g(~YJ, ~PX, ~List<&2, F64>, ~orth_f, 1, PX{xs, pgram(mxs, ys)}, yjs(ys, 0n))

def ext(+fm: FM, +mask: List<&2, F64>, +xs: List<&2, List<&2, F64>>, +ys: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  +mxs = blk_op(fm, mask, True{}, xs)
  List.append(&2, List<&2, F64>, xs, qs_q(mon2(fm, mask, proj_x(xs, mxs, proj_x(xs, mxs, ys)))))

def bresid(+xs: List<&2, List<&2, F64>>, +kxs: List<&2, List<&2, F64>>, +lam: List<&2, F64>, +fm: FM, +mask: List<&2, F64>,
    +pc: List<&2, F64>) -> List<&2, List<&2, F64>>:
  bsolve(fm, mask, pc, caxpy(negs(lam), blk_op(fm, mask, True{}, xs), kxs), 30n)

type LB is Data:
  LB{ x: List<&2, List<&2, F64>>, kx: List<&2, List<&2, F64>>, lam: List<&2, F64>, p: List<&2, List<&2, F64>> }

def lb_np(+s: LB) -> LB:
  LB{+xs, +kxs, +lam, ps} = s
  LB{xs, kxs, lam, []}

def lb_si(+s: LB) -> SI:
  LB{+xs, kxs, +lam, ps} = s
  SI{xs, lam}

def lob_ja(j: JA, +qs: List<&2, List<&2, F64>>, +kq: List<&2, List<&2, F64>>, +m: Nat, +k: Nat, +nx: Nat) -> LB:
  JA{+a, +v} = j
  +sel = ix_take(k, so_ix(B.msort(~IX, ~ix_cmp, ixs(diag_of(a, L.nat_range(m)), 0n))))
  +js = ix_i(sel)
  +one = ones_l(k)
  LB{pcombs(qs, v, js, one), pcombs(kq, v, js, one), ix_v(sel), pcombs(drop_l(nx, qs), drop_l(nx, v), js, one)}

def lob_rr(+qs: List<&2, List<&2, F64>>, +fm: FM, +mask: List<&2, F64>, +k: Nat, +nx: Nat) -> LB:
  +kq = blk_op(fm, mask, False{}, qs)
  +m = List.length(&2, List<&2, F64>, qs)
  lob_ja(jacobi(pgram(qs, kq), m), qs, kq, m, k, nx)

def lob_it(n: Nat, +fm: FM, +mask: List<&2, F64>, +pc: List<&2, F64>, +k: Nat, +s: LB) -> LB:
  match n:
    case 0n: s
    case 1n+j:
      LB{+xs, +kxs, +lam, +ps} = s
      +ws = bresid(xs, kxs, lam, fm, mask, pc)
      lob_it(j, fm, mask, pc, k, lob_rr(ext(fm, mask, xs, List.append(&2, List<&2, F64>, ws, ps)), fm, mask, k, k))

def lobpcg(n: Nat, +fm: FM, +mask: List<&2, F64>, +k: Nat, +x0: List<&2, List<&2, F64>>) -> SI:
  +pc = precond(fm, mask)
  +s0 = lob_rr(qs_q(mon2(fm, mask, x0)), fm, mask, k, k)
  lb_si(lob_it(n, fm, mask, pc, k, lb_np(s0)))
