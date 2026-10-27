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

def mv9(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64, +g: F64, +h: F64, +i: F64, +km: F64, us: List<&2, V.Dir>,
    acc: List<&2, V.Dir>) -> List<&2, V.Dir>:
  match us:
    case []: []
    case +u <> +ut:
      match acc:
        case []: []
        case +w <> +at:
          +x = S.dx(u)
          +y = S.dy(u)
          +z = S.dz(u)
          S.dr(F64.add(S.dx(w), F64.add(F64.add(F64.mul(F64.add(a, km), x), F64.mul(b, y)), F64.mul(c, z))),
            F64.add(S.dy(w), F64.add(F64.add(F64.mul(d, x), F64.mul(F64.add(e, km), y)), F64.mul(f, z))),
            F64.add(S.dz(w), F64.add(F64.add(F64.mul(g, x), F64.mul(h, y)), F64.mul(F64.add(i, km), z)))) <> mv9(a, b, c, d, e, f, g, h, i, km, ut, at)

def mvm(+km: F64, us: List<&2, V.Dir>, acc: List<&2, V.Dir>) -> List<&2, V.Dir>:
  match us:
    case []: []
    case +u <> +ut:
      match acc:
        case []: []
        case +w <> +at: S.dr(F64.add(S.dx(w), F64.mul(km, S.dx(u))), F64.add(S.dy(w), F64.mul(km, S.dy(u))), F64.add(S.dz(w), F64.mul(km, S.dz(u)))) <> mvm(km, ut, at)

def nb_mv(stiff: Bool, +k: M9, +ks: F64, +km: F64, +us: List<&2, V.Dir>, +acc: List<&2, V.Dir>) -> List<&2, V.Dir>:
  match stiff:
    case False{}: mvm(km, us, acc)
    case True{}:
      M9{+a, +b, +c, +d, +e, +f, +g, +h, +i} = k
      mv9(F64.mul(ks, a), F64.mul(ks, b), F64.mul(ks, c), F64.mul(ks, d), F64.mul(ks, e), F64.mul(ks, f), F64.mul(ks, g), F64.mul(ks, h),
        F64.mul(ks, i), km, us, acc)

def m9_sc(+s: F64, +x: M9) -> M9:
  M9{+a, +b, +c, +d, +e, +f, +g, +h, +i} = x
  M9{F64.mul(s, a), F64.mul(s, b), F64.mul(s, c), F64.mul(s, d), F64.mul(s, e), F64.mul(s, f), F64.mul(s, g), F64.mul(s, h), F64.mul(s, i)}

def brow_mv(row: List<&2, BE>, +x: B.Tb<&2, List<&2, V.Dir>>, +ks: F64, +ms: F64, +acc: List<&2, V.Dir>) -> List<&2, V.Dir>:
  match row:
    case []: acc
    case +be <> +t:
      BE{r, +c, +k, +m} = be
      brow_mv(t, x, ks, ms, nb_mv(Bool.not(F64.is_eq(ks, 0.0f64)), k, ks, F64.mul(ms, m), B.tb_get(List<&2, V.Dir>, x, c), acc))

def zcols(n: Nat) -> List<&2, V.Dir>:
  match n:
    case 0n: []
    case 1n+(+m): S.dr(0.0f64, 0.0f64, 0.0f64) <> zcols(m)

def brow_f(s: BV, row: List<&2, BE>) -> List<&2, V.Dir>:
  BV{+x, +ks, +ms} = s
  brow_mv(row, x, ks, ms, zcols(List.length(&2, V.Dir, B.tb_get(List<&2, V.Dir>, x, 0))))

def bspmv(+rows: List<&2, List<&2, BE>>, +ks: F64, +ms: F64, +xs: List<&2, List<&2, V.Dir>>) -> List<&2, List<&2, V.Dir>>:
  B.pmap_g(~List<&2, BE>, ~BV, ~List<&2, V.Dir>, ~brow_f, 64, BV{B.tb_of(List<&2, V.Dir>, xs, []), ks, ms}, rows)

def gu9(gs: List<&2, V.Dir>, us: List<&2, V.Dir>, +h: M9) -> M9:
  match gs:
    case []: h
    case +g <> +gt:
      match us:
        case []: h
        case +u <> +ut:
          gu9(gt, ut, m9_add(h, M9{F64.mul(S.dx(g), S.dx(u)), F64.mul(S.dx(g), S.dy(u)), F64.mul(S.dx(g), S.dz(u)), F64.mul(S.dy(g), S.dx(u)),
            F64.mul(S.dy(g), S.dy(u)), F64.mul(S.dy(g), S.dz(u)), F64.mul(S.dz(g), S.dx(u)), F64.mul(S.dz(g), S.dy(u)), F64.mul(S.dz(g), S.dz(u))}))

def sig9(+h: M9, +lam: F64, +mu: F64) -> M9:
  M9{+a, +b, +c, +d, +e, +f, +g, +hh, +i} = h
  +tr = F64.mul(lam, F64.add(F64.add(a, e), i))
  +sxy = F64.mul(mu, F64.add(b, d))
  +sxz = F64.mul(mu, F64.add(c, g))
  +syz = F64.mul(mu, F64.add(f, hh))
  M9{F64.add(tr, F64.mul(F64.mul(2.0f64, mu), a)), sxy, sxz, sxy, F64.add(tr, F64.mul(F64.mul(2.0f64, mu), e)), syz, sxz, syz,
    F64.add(tr, F64.mul(F64.mul(2.0f64, mu), i))}

def gsg(+ga: V.Dir, +s: M9, +gb: V.Dir) -> F64:
  S.dot(ga, m9_mv(s, gb))

def kg_row(+ga: V.Dir, gs: List<&2, V.Dir>, +s: M9, +w: F64, acc: List<&2, F64>) -> List<&2, F64>:
  match gs:
    case []: []
    case +g <> +gt:
      match acc:
        case []: []
        case +x <> +at: F64.add(x, F64.mul(w, gsg(ga, s, g))) <> kg_row(ga, gt, s, w, at)

def kg_rows(ga: List<&2, V.Dir>, +gs: List<&2, V.Dir>, +s: M9, +w: F64, +acc: List<&2, F64>) -> List<&2, F64>:
  match ga:
    case []: []
    case +g <> +gt: List.append(&2, F64, kg_row(g, gs, s, w, B.take_u(F64, acc, 10, False{})), kg_rows(gt, gs, s, w, B.drop_u(F64, acc, 10, False{})))

type PS is Data:
  PS{ u: B.Tb<&2, F64>, lam: F64, mu: F64, w2: F64, d: V.Dir }

def nodal(+u: B.Tb<&2, F64>, ns: List<&2, U32>) -> List<&2, V.Dir>:
  match ns:
    case []: []
    case +n <> +t:
      +k = U32.mul(n, 3)
      S.dr(B.tb_get(F64, u, k), B.tb_get(F64, u, U32.add(k, 1)), B.tb_get(F64, u, U32.add(k, 2))) <> nodal(u, t)

def kg_aff(qs: List<&2, List<&2, F64>>, +gl: List<&2, V.Dir>, +v: F64, +us: List<&2, V.Dir>, +lam: F64, +mu: F64, +acc: List<&2, F64>) -> List<&2, F64>:
  match qs:
    case []: acc
    case +q <> +t:
      +gs = grads(q, gl)
      kg_aff(t, gl, v, us, lam, mu, kg_rows(gs, gs, sig9(gu9(gs, us, m9z()), lam, mu), F64.mul(v, L.nth_f64(q, 4n)), acc))

def kg_cq(+g: QG, +us: List<&2, V.Dir>, +lam: F64, +mu: F64, +acc: List<&2, F64>) -> List<&2, F64>:
  QG{+gs, +w} = g
  kg_rows(gs, gs, sig9(gu9(gs, us, m9z()), lam, mu), w, acc)

def kg_cur(qs: List<&2, List<&2, F64>>, +ps: List<&2, V.Point>, +us: List<&2, V.Dir>, +lam: F64, +mu: F64, +acc: List<&2, F64>) -> List<&2, F64>:
  match qs:
    case []: acc
    case +q <> +t: kg_cur(t, ps, us, lam, mu, kg_cq(qg_of(ps, q), us, lam, mu, acc))

def ms_cq(+g: QG, +nv: List<&2, F64>, +acc: List<&2, F64>) -> List<&2, F64>:
  QG{gs, +w} = g
  m_rows2(nv, nv, w, acc)

def ms_cur(qs: List<&2, List<&2, F64>>, +ps: List<&2, V.Point>, +acc: List<&2, F64>) -> List<&2, F64>:
  match qs:
    case []: acc
    case +q <> +t: ms_cur(t, ps, ms_cq(qg_of(ps, q), nvals(q), acc))

def perp9(+d: V.Dir) -> M9:
  +x = S.dx(d)
  +y = S.dy(d)
  +z = S.dz(d)
  M9{F64.sub(1.0f64, F64.mul(x, x)), F64.neg(F64.mul(x, y)), F64.neg(F64.mul(x, z)), F64.neg(F64.mul(y, x)), F64.sub(1.0f64, F64.mul(y, y)),
    F64.neg(F64.mul(y, z)), F64.neg(F64.mul(z, x)), F64.neg(F64.mul(z, y)), F64.sub(1.0f64, F64.mul(z, z))}

def eye9(+s: F64) -> M9:
  M9{s, 0.0f64, 0.0f64, 0.0f64, s, 0.0f64, 0.0f64, 0.0f64, s}

def pre9(ss: List<&2, F64>, ms: List<&2, F64>, +p: M9, +w2: F64) -> List<&2, M9>:
  match ss:
    case []: []
    case +s <> +st:
      match ms:
        case []: []
        case +m <> +mt: m9_add(eye9(s), m9_sc(F64.neg(F64.mul(w2, m)), p)) <> pre9(st, mt, p, w2)

def pre_eb(e: EL, +u: B.Tb<&2, F64>, +lam: F64, +mu: F64, +rho: F64) -> EB:
  match e:
    case EL{+ns, +gl, +v}: EB{m9s(0n), List.append(&2, F64, kg_aff(wq(), gl, v, nodal(u, ns), lam, mu, f0s(100n)), scale(rho, flat_rows(mref(), F64.div(v, 420.0f64))))}
    case EC{+ns, +ps}: EB{m9s(0n), List.append(&2, F64, kg_cur(wq(), ps, nodal(u, ns), lam, mu, f0s(100n)), scale(rho, ms_cur(wq(), ps, f0s(100n))))}

type PR is Data:
  PR{ u: B.Tb<&2, F64>, lam: F64, mu: F64, rho: F64, w2: F64, d: V.Dir }

def pre_bes(+b: EB, +ns: List<&2, U32>, +d: V.Dir, +w2: F64) -> List<&2, BE>:
  EB{k0, +sm} = b
  be_rows(ns, ns, pre9(B.take_u(F64, sm, 100, False{}), B.drop_u(F64, sm, 100, False{}), perp9(d), w2), f0s(100n), [])

def pre_go(+c: PR, +e: EL) -> List<&2, BE>:
  PR{+u, +lam, +mu, +rho, +w2, +d} = c
  pre_bes(pre_eb(e, u, lam, mu, rho), el_ns(e), d, w2)

def pre_f(c: PR, e: EL) -> List<&2, BE>:
  pre_go(c, e)

def rows_be(rs: List<&2, List<&2, BE>>) -> List<&2, BE>:
  match rs:
    case []: []
    case +r <> +t: List.append(&2, BE, r, rows_be(t))

def prestress(+fm: FM, +es: List<&2, EL>, +u: List<&2, F64>, +e: F64, +nu: F64, +w: F64, +d: V.Dir) -> FM:
  FM{+nn, +rows, +rho, +sg} = fm
  +lam = F64.div(F64.mul(e, nu), F64.mul(F64.add(1.0f64, nu), F64.sub(1.0f64, F64.mul(2.0f64, nu))))
  +mu = F64.div(e, F64.mul(2.0f64, F64.add(1.0f64, nu)))
  +extra = cat_be(B.pmap_g(~EL, ~PR, ~List<&2, BE>, ~pre_f, 16, PR{B.tb_of(F64, u, 0.0f64), lam, mu, rho, F64.mul(w, w), d}, es))
  +all = so_be(B.msort(~BE, ~be_cmp, List.append(&2, BE, rows_be(rows), extra)))
  FM{nn, merge_be(tl_be(all), MG{hd_be(all), [], []}), rho, sg}

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

def lin2(xs: List<&2, F64>, ys: List<&2, F64>, +a: F64, +b: F64) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> +xt:
      match ys:
        case []: []
        case +y <> +yt: F64.add(F64.mul(a, x), F64.mul(b, y)) <> lin2(xt, yt, a, b)

type JA is Data:
  JA{ a: List<&2, List<&2, F64>>, v: List<&2, List<&2, F64>> }

def off2(rs: List<&2, List<&2, F64>>, +i: Nat, +acc: F64) -> F64:
  match rs:
    case []: acc
    case +r <> +t: off2(t, Nat.add(i, 1n), F64.add(acc, F64.sub(dot_l(r, r, 0.0f64), F64.mul(L.nth_f64(r, i), L.nth_f64(r, i)))))

def all2(rs: List<&2, List<&2, F64>>, +acc: F64) -> F64:
  match rs:
    case []: acc
    case +r <> +t: all2(t, F64.add(acc, dot_l(r, r, 0.0f64)))

def ident_row(+n: Nat, +i: Nat, ks: List<&2, Nat>) -> List<&2, F64>:
  match ks:
    case []: []
    case +k <> +t: Bool.pick(F64, Nat.is_eq(k, i), 1.0f64, 0.0f64) <> ident_row(n, i, t)

def ident(+n: Nat, ix: List<&2, Nat>) -> List<&2, List<&2, F64>>:
  match ix:
    case []: []
    case +i <> +t: ident_row(n, i, L.nat_range(n)) <> ident(n, t)

type CS is Data:
  CS{ c: F64, s: F64 }

def cs_mk(+app: F64, +aqq: F64, +apq: F64) -> CS:
  +th = F64.div(F64.sub(aqq, app), F64.mul(2.0f64, apq))
  +t = F64.div(Bool.pick(F64, F64.is_lt(th, 0.0f64), F64.neg(1.0f64), 1.0f64), F64.add(F64.abs(th), F64.sqrt(F64.add(F64.mul(th, th), 1.0f64))))
  +c = F64.div(1.0f64, F64.sqrt(F64.add(F64.mul(t, t), 1.0f64)))
  Bool.pick(CS, F64.is_le(F64.abs(apq), 1.0e-300f64), CS{1.0f64, 0.0f64}, CS{c, F64.mul(t, c)})

def rj_cs(rs: List<&2, List<&2, F64>>, +k: Nat) -> List<&2, CS>:
  match rs:
    case []: []
    case +rp <> +t:
      match t:
        case []: []
        case +rq <> +t2:
          +q = Nat.add(k, 1n)
          cs_mk(L.nth_f64(rp, k), L.nth_f64(rq, q), L.nth_f64(rp, q)) <> rj_cs(t2, Nat.add(k, 2n))

def cs_c(+h: CS) -> F64:
  CS{+c, s} = h
  c

def cs_s(+h: CS) -> F64:
  CS{c, +s} = h
  s

def rot_row(cs: List<&2, CS>, r: List<&2, F64>) -> List<&2, F64>:
  match cs:
    case []: r
    case +h <> ct:
      match r:
        case []: []
        case +x <> +t:
          match t:
            case []: [x]
            case +y <> t2:
              +c = cs_c(h)
              +s = cs_s(h)
              F64.sub(F64.mul(c, x), F64.mul(s, y)) <> (F64.add(F64.mul(s, x), F64.mul(c, y)) <> rot_row(ct, t2))

def rot_rows(cs: List<&2, CS>, rs: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match cs:
    case []: rs
    case +h <> ct:
      match rs:
        case []: []
        case +rp <> +t:
          match t:
            case []: [rp]
            case +rq <> t2:
              +c = cs_c(h)
              +s = cs_s(h)
              lin2(rp, rq, c, F64.neg(s)) <> (lin2(rp, rq, s, c) <> rot_rows(ct, t2))

def rot_f(cs: List<&2, CS>, r: List<&2, F64>) -> List<&2, F64>:
  rot_row(cs, r)

def gath_f(ps: List<&2, Nat>, +t: B.Tb<&2, F64>) -> List<&2, F64>:
  match ps:
    case []: []
    case +i <> +rest: B.tb_get(F64, t, U32.from_nat(i)) <> gath_f(rest, t)

def gath_row(ps: List<&2, Nat>, r: List<&2, F64>) -> List<&2, F64>:
  gath_f(ps, B.tb_of(F64, r, 0.0f64))

def gath_rows(ps: List<&2, Nat>, +t: B.Tb<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match ps:
    case []: []
    case +i <> +rest: B.tb_get(List<&2, F64>, t, U32.from_nat(i)) <> gath_rows(rest, t)

def gath_n(ps: List<&2, Nat>, +t: B.Tb<&2, Nat>) -> List<&2, Nat>:
  match ps:
    case []: []
    case +i <> +rest: B.tb_get(Nat, t, U32.from_nat(i)) <> gath_n(rest, t)

def rr_at(+i: Nat, +h: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_lt(Nat.add(i, 1n), h), Nat.mul(2n, Nat.add(i, 1n)), Nat.add(Nat.mul(2n, Nat.sub(Nat.sub(Nat.mul(2n, h), 2n), i)), 1n))

def rr_pos(+j: Nat, +h: Nat) -> Nat:
  +n = Nat.sub(Nat.mul(2n, h), 1n)
  +i = Nat.div(j, 2n)
  +odd = Nat.is_eq(Nat.mod(j, 2n), 1n)
  Bool.pick(Nat, Nat.is_eq(j, 0n), 0n,
    Bool.pick(Nat, odd, rr_at(Nat.mod(Nat.sub(Nat.mul(4n, h), Nat.add(4n, i)), n), h), rr_at(Nat.mod(Nat.add(i, Nat.sub(n, 2n)), n), h)))

def rr_perm(js: List<&2, Nat>, +h: Nat) -> List<&2, Nat>:
  match js:
    case []: []
    case +j <> +t: rr_pos(j, h) <> rr_perm(t, h)

type RJ is Data:
  RJ{ a: List<&2, List<&2, F64>>, v: List<&2, List<&2, F64>>, ix: List<&2, Nat> }

def rj_round(+ps: List<&2, Nat>, +r: RJ) -> RJ:
  RJ{+a, +v, +ix} = r
  +cs = rj_cs(a, 0n)
  +a2 = rot_rows(cs, B.pmap_g(~List<&2, F64>, ~List<&2, CS>, ~List<&2, F64>, ~rot_f, 1, cs, a))
  +v2 = B.pmap_g(~List<&2, F64>, ~List<&2, CS>, ~List<&2, F64>, ~rot_f, 1, cs, v)
  RJ{B.pmap_g(~List<&2, F64>, ~List<&2, Nat>, ~List<&2, F64>, ~gath_row, 1, ps, gath_rows(ps, B.tb_of(List<&2, F64>, a2, []))),
    B.pmap_g(~List<&2, F64>, ~List<&2, Nat>, ~List<&2, F64>, ~gath_row, 1, ps, v2), gath_n(ps, B.tb_of(Nat, ix, 0n))}

def rj_rounds(n: Nat, +ps: List<&2, Nat>, +r: RJ) -> RJ:
  match n:
    case 0n: r
    case 1n+(+m): rj_rounds(m, ps, rj_round(ps, r))

def rj_done(+r: RJ) -> Bool:
  RJ{+a, v, ix} = r
  F64.is_le(off2(a, 0n, 0.0f64), F64.mul(1.0e-30f64, all2(a, 0.0f64)))

def rj_sweeps(n: Nat, done: Bool, +m: Nat, +ps: List<&2, Nat>, +r: RJ) -> RJ:
  match n:
    case 0n: r
    case 1n+k:
      match done:
        case True{}: r
        case False{}:
          +r2 = rj_rounds(Nat.sub(m, 1n), ps, r)
          rj_sweeps(k, rj_done(r2), m, ps, r2)

def inv_go(ix: List<&2, Nat>, +j: Nat, +t: B.Tb<&2, Nat>) -> B.Tb<&2, Nat>:
  match ix:
    case []: t
    case +o <> +rest: inv_go(rest, Nat.add(j, 1n), B.tb_set(Nat, t, U32.from_nat(o), j))

def take_n(n: Nat, xs: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+(+m):
      match xs:
        case []: []
        case +x <> +t: x <> take_n(m, t)

def take_r(n: Nat, xs: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match n:
    case 0n: []
    case 1n+(+m):
      match xs:
        case []: []
        case +x <> +t: x <> take_r(m, t)

def rj_out(+r: RJ, +n: Nat, +m: Nat) -> JA:
  RJ{+a, +v, +ix} = r
  +back = take_n(n, gath_n(L.nat_range(m), inv_go(ix, 0n, B.tb_of(Nat, L.nat_range(m), 0n))))
  +a2 = gath_rows(back, B.tb_of(List<&2, F64>, a, []))
  JA{B.pmap_g(~List<&2, F64>, ~List<&2, Nat>, ~List<&2, F64>, ~gath_row, 1, back, a2),
    take_r(n, B.pmap_g(~List<&2, F64>, ~List<&2, Nat>, ~List<&2, F64>, ~gath_row, 1, back, v))}

def pad_row(+r: List<&2, F64>, +pad: Bool) -> List<&2, F64>:
  Bool.pick(List<&2, F64>, pad, List.append(&2, F64, r, [0.0f64]), r)

def pad_f(pad: Bool, r: List<&2, F64>) -> List<&2, F64>:
  pad_row(r, pad)

def jacobi(+a: List<&2, List<&2, F64>>, +n: Nat) -> JA:
  +pad = Nat.is_eq(Nat.mod(n, 2n), 1n)
  +m = Bool.pick(Nat, pad, Nat.add(n, 1n), n)
  +zero = ident_row(m, m, L.nat_range(m))
  +ap = List.append(&2, List<&2, F64>, B.pmap_g(~List<&2, F64>, ~Bool, ~List<&2, F64>, ~pad_f, 1, pad, a), Bool.pick(List<&2, List<&2, F64>>, pad, [zero], []))
  +ps = rr_perm(L.nat_range(m), Nat.div(m, 2n))
  rj_out(rj_sweeps(30n, Nat.is_lt(m, 2n), m, ps, RJ{ap, ident(m, L.nat_range(m)), L.nat_range(m)}), n, m)

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
  SI{ x: List<&2, List<&2, F64>>, lam: List<&2, F64>, it: Nat, res: F64 }

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

type GP is Data:
  GP{ x: List<&2, F64>, ys: List<&2, List<&2, F64>> }

def gps(xs: List<&2, List<&2, F64>>, ys: List<&2, List<&2, F64>>) -> List<&2, GP>:
  match xs:
    case []: []
    case +x <> +xt:
      match ys:
        case []: []
        case +y <> +yt: GP{x, y <> yt} <> gps(xt, yt)

def gp_rows(ps: List<&2, GP>) -> List<&2, List<&2, F64>>:
  match ps:
    case []: []
    case +p <> +t:
      GP{+x, +ys} = p
      gram_row(x, ys) <> gp_rows(t)

def full_rows(xs: List<&2, List<&2, F64>>, +ys: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match xs:
    case []: []
    case +x <> +t: gram_row(x, ys) <> full_rows(t, ys)

def hdf(cs: List<&2, List<&2, F64>>) -> List<&2, F64>:
  match cs:
    case []: []
    case +c <> +t:
      match c:
        case []: hdf(t)
        case +h <> +r: h <> hdf(t)

def tlf(cs: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match cs:
    case []: []
    case +c <> +t:
      match c:
        case []: [] <> tlf(t)
        case +h <> +r: r <> tlf(t)

def cuts(f: Nat, +xs: List<&2, F64>, +k: U32) -> List<&2, List<&2, F64>>:
  match f:
    case 0n: []
    case 1n+g: B.take_u(F64, xs, k, U32.is_eq(k, 0)) <> cuts(g, B.drop_u(F64, xs, k, U32.is_eq(k, 0)), k)

type GQ is Data:
  GQ{ xs: List<&2, List<&2, F64>>, ys: List<&2, List<&2, F64>> }

def cut_all(vs: List<&2, List<&2, F64>>, +p: Nat, +k: U32) -> List<&2, List<&2, List<&2, F64>>>:
  match vs:
    case []: []
    case +v <> +t: cuts(p, v, k) <> cut_all(t, p, k)

def hd3(cs: List<&2, List<&2, List<&2, F64>>>) -> List<&2, List<&2, F64>>:
  match cs:
    case []: []
    case +c <> +t:
      match c:
        case []: hd3(t)
        case +h <> +r: h <> hd3(t)

def tl3(cs: List<&2, List<&2, List<&2, F64>>>) -> List<&2, List<&2, List<&2, F64>>>:
  match cs:
    case []: []
    case +c <> +t:
      match c:
        case []: [] <> tl3(t)
        case +h <> +r: r <> tl3(t)

def tr3(n: Nat, +cs: List<&2, List<&2, List<&2, F64>>>) -> List<&2, List<&2, List<&2, F64>>>:
  match n:
    case 0n: []
    case 1n+(+m): hd3(cs) <> tr3(m, tl3(cs))

def gq_zip(xs: List<&2, List<&2, List<&2, F64>>>, ys: List<&2, List<&2, List<&2, F64>>>) -> List<&2, GQ>:
  match xs:
    case []: []
    case +x <> +xt:
      match ys:
        case []: []
        case +y <> +yt: GQ{x, y} <> gq_zip(xt, yt)

def parts() -> Nat:
  32n

def gq_of(+xs: List<&2, List<&2, F64>>, +ys: List<&2, List<&2, F64>>) -> List<&2, GQ>:
  +k = U32.add(U32.div(B.ulen(F64, hd_l(xs)), U32.from_nat(parts())), 1)
  gq_zip(tr3(parts(), cut_all(xs, parts(), k)), tr3(parts(), cut_all(ys, parts(), k)))

def gq_s(c: F64, q: GQ) -> List<&2, List<&2, F64>>:
  GQ{+xs, +ys} = q
  gp_rows(gps(xs, ys))

def gq_f(c: F64, q: GQ) -> List<&2, List<&2, F64>>:
  GQ{+xs, +ys} = q
  full_rows(xs, ys)

def add_l(xs: List<&2, F64>, ys: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> +t:
      match ys:
        case []: []
        case +y <> +u: F64.add(x, y) <> add_l(t, u)

def add_rows(xs: List<&2, List<&2, F64>>, ys: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match xs:
    case []: []
    case +x <> +t:
      match ys:
        case []: []
        case +y <> +u: add_l(x, y) <> add_rows(t, u)

def sum_go(ps: List<&2, List<&2, List<&2, F64>>>, +acc: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match ps:
    case []: acc
    case +p <> +t: sum_go(t, add_rows(acc, p))

def sum_parts(ps: List<&2, List<&2, List<&2, F64>>>) -> List<&2, List<&2, F64>>:
  match ps:
    case []: []
    case +p <> +t: sum_go(t, p)

def sym_go(us: List<&2, List<&2, F64>>, +prev: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match us:
    case []: []
    case +u <> +r: List.append(&2, F64, hdf(prev), u) <> sym_go(r, tlf(List.append(&2, List<&2, F64>, prev, [u])))

def pgram(+xs: List<&2, List<&2, F64>>, +ys: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  sum_parts(B.pmap_g(~GQ, ~F64, ~List<&2, List<&2, F64>>, ~gq_f, 1, 0.0f64, gq_of(xs, ys)))

def psgram(+xs: List<&2, List<&2, F64>>, +ys: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  sym_go(sum_parts(B.pmap_g(~GQ, ~F64, ~List<&2, List<&2, F64>>, ~gq_s, 1, 0.0f64, gq_of(xs, ys))), [])

def tcolf(n: Nat, +cs: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match n:
    case 0n: []
    case 1n+(+m): hdf(cs) <> tcolf(m, tlf(cs))

def rdot_f(cs: List<&2, List<&2, F64>>, row: List<&2, F64>) -> List<&2, F64>:
  gram_row(row, cs)

def rcomb(+qs: List<&2, List<&2, F64>>, +cs: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  +n = List.length(&2, F64, hd_l(qs))
  tcolf(List.length(&2, List<&2, F64>, cs), B.pmap_g(~List<&2, F64>, ~List<&2, List<&2, F64>>, ~List<&2, F64>, ~rdot_f, 256, cs, tcolf(n, qs)))

def ccols(+v: List<&2, List<&2, F64>>, js: List<&2, Nat>, ss: List<&2, F64>) -> List<&2, List<&2, F64>>:
  match js:
    case []: []
    case +j <> +t:
      match ss:
        case []: []
        case +s <> +st: scale(s, colj(v, j)) <> ccols(v, t, st)

def ones_l(n: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m): 1.0f64 <> ones_l(m)

def fmax(xs: List<&2, F64>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> +t: fmax(t, F64.max(acc, x))

type SV is Data:
  SV{ x: List<&2, List<&2, F64>>, rz: F64 }

def cut_g(-A: Data, f: Nat, +xs: List<&2, A>, +k: U32) -> List<&2, List<&2, A>>:
  match f:
    case 0n: []
    case 1n+g: B.take_u(A, xs, k, U32.is_eq(k, 0)) <> cut_g(A, g, B.drop_u(A, xs, k, U32.is_eq(k, 0)), k)

def nd_dot(us: List<&2, V.Dir>, vs: List<&2, V.Dir>, acc: List<&2, F64>) -> List<&2, F64>:
  match us:
    case []: []
    case +u <> +ut:
      match vs:
        case []: []
        case +v <> +vt:
          match acc:
            case []: []
            case +a <> +at: F64.add(a, S.dot(u, v)) <> nd_dot(ut, vt, at)

def nd_axpy(as: List<&2, F64>, us: List<&2, V.Dir>, vs: List<&2, V.Dir>) -> List<&2, V.Dir>:
  match as:
    case []: []
    case +a <> +at:
      match us:
        case []: []
        case +u <> +ut:
          match vs:
            case []: []
            case +v <> +vt: S.dadd(v, a, u) <> nd_axpy(at, ut, vt)

def dmul(+m: V.Dir, +u: V.Dir) -> V.Dir:
  S.dr(F64.mul(S.dx(m), S.dx(u)), F64.mul(S.dy(m), S.dy(u)), F64.mul(S.dz(m), S.dz(u)))

def nd_had(+m: V.Dir, us: List<&2, V.Dir>) -> List<&2, V.Dir>:
  match us:
    case []: []
    case +u <> +ut: dmul(m, u) <> nd_had(m, ut)

def zeros_f(n: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m): 0.0f64 <> zeros_f(m)

type NQ is Data:
  NQ{ q: List<&2, List<&2, V.Dir>>, d: List<&2, F64> }

type NC is Data:
  NC{ rows: List<&2, List<&2, BE>>, m: List<&2, V.Dir>, pc: List<&2, V.Dir>, x: List<&2, List<&2, V.Dir>>, r: List<&2, List<&2, V.Dir>>,
    p: List<&2, List<&2, V.Dir>>, q: List<&2, List<&2, V.Dir>>, d: List<&2, F64> }

type QX is Data:
  QX{ x: B.Tb<&2, List<&2, V.Dir>>, ks: F64, ms: F64, k: Nat }

def qx_mv(+c: QX, +w: List<&2, BE>) -> List<&2, V.Dir>:
  QX{+x, +ks, +ms, +k} = c
  brow_mv(w, x, ks, ms, zcols(k))

def qx_k(+c: QX) -> Nat:
  QX{x, ks, ms, +k} = c
  k

def nq_go(rows: List<&2, List<&2, BE>>, ms: List<&2, V.Dir>, ps: List<&2, List<&2, V.Dir>>, +c: QX, +qs: List<&2, List<&2, V.Dir>>,
    +d: List<&2, F64>) -> NQ:
  match rows:
    case []: NQ{List.reverse(&2, List<&2, V.Dir>, qs), d}
    case +w <> +wt:
      match ms:
        case []: NQ{List.reverse(&2, List<&2, V.Dir>, qs), d}
        case +m <> +mt:
          match ps:
            case []: NQ{List.reverse(&2, List<&2, V.Dir>, qs), d}
            case +p <> +pt:
              +q = nd_had(m, qx_mv(c, w))
              nq_go(wt, mt, pt, c, q <> qs, nd_dot(p, q, d))

def nc_q(+a: NQ, +rows: List<&2, List<&2, BE>>, +m: List<&2, V.Dir>, +pc: List<&2, V.Dir>, +x: List<&2, List<&2, V.Dir>>,
    +r: List<&2, List<&2, V.Dir>>, +p: List<&2, List<&2, V.Dir>>) -> NC:
  NQ{+q, +d} = a
  NC{rows, m, pc, x, r, p, q, d}

def ch_q2(+c: QX, +n: NC) -> NC:
  NC{+rows, +m, +pc, +x, +r, +p, q, d} = n
  nc_q(nq_go(rows, m, p, c, [], zeros_f(qx_k(c))), rows, m, pc, x, r, p)

def ch_q(c: QX, n: NC) -> NC:
  ch_q2(c, n)

type NR is Data:
  NR{ x: List<&2, List<&2, V.Dir>>, r: List<&2, List<&2, V.Dir>>, z: List<&2, List<&2, V.Dir>>, d: List<&2, F64> }

def nr_go(pcs: List<&2, V.Dir>, xs: List<&2, List<&2, V.Dir>>, rs: List<&2, List<&2, V.Dir>>, ps: List<&2, List<&2, V.Dir>>,
    qs: List<&2, List<&2, V.Dir>>, +al: List<&2, F64>, +na: List<&2, F64>, +acc: NR) -> NR:
  match pcs:
    case []: acc
    case +pc <> +pct:
      match xs:
        case []: acc
        case +x <> +xt:
          match rs:
            case []: acc
            case +r <> +rt:
              match ps:
                case []: acc
                case +p <> +pt:
                  match qs:
                    case []: acc
                    case +q <> +qt:
                      NR{+ax, +ar, +az, +ad} = acc
                      +r2 = nd_axpy(na, q, r)
                      +z2 = nd_had(pc, r2)
                      nr_go(pct, xt, rt, pt, qt, al, na, NR{nd_axpy(al, p, x) <> ax, r2 <> ar, z2 <> az, nd_dot(r2, z2, ad)})

def nr_rev(+a: NR) -> NR:
  NR{+x, +r, +z, +d} = a
  NR{List.reverse(&2, List<&2, V.Dir>, x), List.reverse(&2, List<&2, V.Dir>, r), List.reverse(&2, List<&2, V.Dir>, z), d}

def nc_r(+a: NR, +rows: List<&2, List<&2, BE>>, +m: List<&2, V.Dir>, +pc: List<&2, V.Dir>, +p: List<&2, List<&2, V.Dir>>) -> NC:
  NR{+x, +r, +z, +d} = a
  NC{rows, m, pc, x, r, p, z, d}

def ch_r2(+al: List<&2, F64>, +n: NC) -> NC:
  NC{+rows, +m, +pc, +x, +r, +p, +q, d} = n
  nc_r(nr_rev(nr_go(pc, x, r, p, q, al, negs(al), NR{[], [], [], zeros_f(List.length(&2, F64, al))})), rows, m, pc, p)

def ch_r(al: List<&2, F64>, n: NC) -> NC:
  ch_r2(al, n)

def np_go(zs: List<&2, List<&2, V.Dir>>, ps: List<&2, List<&2, V.Dir>>, +be: List<&2, F64>) -> List<&2, List<&2, V.Dir>>:
  match zs:
    case []: []
    case +z <> +zt:
      match ps:
        case []: []
        case +p <> +pt: nd_axpy(be, p, z) <> np_go(zt, pt, be)

def ch_p2(+be: List<&2, F64>, +n: NC) -> NC:
  NC{+rows, +m, +pc, +x, +r, +p, +q, d} = n
  NC{rows, m, pc, x, r, np_go(q, p, be), [], []}

def ch_p(be: List<&2, F64>, n: NC) -> NC:
  ch_p2(be, n)

def sum_d(cs: List<&2, NC>, +acc: List<&2, F64>) -> List<&2, F64>:
  match cs:
    case []: acc
    case +c <> +t:
      NC{rows, m, pc, x, r, p, q, +d} = c
      sum_d(t, add_l(acc, d))

def cat_p(cs: List<&2, NC>) -> List<&2, List<&2, V.Dir>>:
  match cs:
    case []: []
    case +c <> +t:
      NC{rows, m, pc, x, r, +p, q, d} = c
      List.append(&2, List<&2, V.Dir>, p, cat_p(t))

def cat_x(cs: List<&2, NC>) -> List<&2, List<&2, V.Dir>>:
  match cs:
    case []: []
    case +c <> +t:
      NC{rows, m, pc, +x, r, p, q, d} = c
      List.append(&2, List<&2, V.Dir>, x, cat_x(t))

type NS is Data:
  NS{ cs: List<&2, NC>, rz: List<&2, F64> }

def npcg(f: Nat, done: Bool, +ks: F64, +ms: F64, +k: Nat, +tol: F64, +s: NS) -> NS:
  match f:
    case 0n: s
    case 1n+g:
      match done:
        case True{}: s
        case False{}:
          NS{+cs, +rz} = s
          +c1 = B.pmap_g(~NC, ~QX, ~NC, ~ch_q, 1, QX{B.tb_of(List<&2, V.Dir>, cat_p(cs), []), ks, ms, k}, cs)
          +al = zdiv(rz, sum_d(c1, zeros_f(k)))
          +c2 = B.pmap_g(~NC, ~List<&2, F64>, ~NC, ~ch_r, 1, al, c1)
          +rz2 = sum_d(c2, zeros_f(k))
          npcg(g, F64.is_lt(fmax(rz2, 0.0f64), tol), ks, ms, k, tol, NS{B.pmap_g(~NC, ~List<&2, F64>, ~NC, ~ch_p, 1, zdiv(rz2, rz), c2), rz2})

def zr(rs: List<&2, List<&2, V.Dir>>) -> List<&2, List<&2, V.Dir>>:
  match rs:
    case []: []
    case +r <> +t: zcols(List.length(&2, V.Dir, r)) <> zr(t)

def nc_zip(rows: List<&2, List<&2, List<&2, BE>>>, ms: List<&2, List<&2, V.Dir>>, pcs: List<&2, List<&2, V.Dir>>, rs: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, NC>:
  match rows:
    case []: []
    case +w <> +wt:
      match ms:
        case []: []
        case +m <> +mt:
          match pcs:
            case []: []
            case +pc <> +pct:
              match rs:
                case []: []
                case +r <> +rt: NC{w, m, pc, zr(r), r, [], [], []} <> nc_zip(wt, mt, pct, rt)

def nz_go(pcs: List<&2, V.Dir>, rs: List<&2, List<&2, V.Dir>>, +acc: NR) -> NR:
  match pcs:
    case []: acc
    case +pc <> +pct:
      match rs:
        case []: acc
        case +r <> +rt:
          NR{ax, +ar, +az, +ad} = acc
          +z = nd_had(pc, r)
          nz_go(pct, rt, NR{[], ar, z <> az, nd_dot(r, z, ad)})

def nc_z(+a: NR, +rows: List<&2, List<&2, BE>>, +m: List<&2, V.Dir>, +pc: List<&2, V.Dir>, +x: List<&2, List<&2, V.Dir>>, +r: List<&2, List<&2, V.Dir>>) -> NC:
  NR{ax, ar, +z, +d} = a
  NC{rows, m, pc, x, r, z, [], d}

def ch_z2(+k: Nat, +n: NC) -> NC:
  NC{+rows, +m, +pc, +x, +r, p, q, d} = n
  nc_z(nr_rev(nz_go(pc, r, NR{[], [], [], zeros_f(k)})), rows, m, pc, x, r)

def ch_z(k: Nat, n: NC) -> NC:
  ch_z2(k, n)

def ns_x(+s: NS, +k: Nat) -> SV:
  NS{+cs, +rz} = s
  SV{B.pmap_g(~List<&2, V.Dir>, ~F64, ~List<&2, F64>, ~flat_f, 1, 0.0f64, tcol(k, cat_x(cs))), fmax(rz, 0.0f64)}

def nsolve(+fm: FM, +mask: List<&2, F64>, +pc: List<&2, F64>, +rs: List<&2, List<&2, F64>>, +n: Nat, +rtol: F64) -> SV:
  FM{+nn, +rows, +rho, +sg} = fm
  +k = List.length(&2, List<&2, F64>, rs)
  +nd = U32.to_nat(nn)
  +w = U32.add(U32.div(nn, U32.from_nat(parts())), 1)
  +nm = tcol(nd, B.pmap_g(~List<&2, F64>, ~F64, ~List<&2, V.Dir>, ~trip_f, 1, 0.0f64, rs))
  +c0 = B.pmap_g(~NC, ~Nat, ~NC, ~ch_z, 1, k, nc_zip(cut_g(List<&2, BE>, parts(), rows, w), cut_g(V.Dir, parts(), trip(mask), w), cut_g(V.Dir, parts(), trip(pc), w),
    cut_g(List<&2, V.Dir>, parts(), nm, w)))
  +rz0 = sum_d(c0, zeros_f(k))
  ns_x(npcg(n, False{}, 1.0f64, F64.mul(sg, rho), k, F64.mul(F64.mul(rtol, rtol), fmax(rz0, 0.0f64)), NS{c0, rz0}), k)

def sv_x(+s: SV) -> List<&2, List<&2, F64>>:
  SV{+x, rz} = s
  x

def bsolve_tol(+fm: FM, +mask: List<&2, F64>, +rs: List<&2, List<&2, F64>>, +n: Nat, +rtol: F64) -> SV:
  nsolve(fm, mask, precond(fm, mask), rs, n, rtol)

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

def cols_of(+c: List<&2, List<&2, F64>>, js: List<&2, Nat>) -> List<&2, List<&2, F64>>:
  match js:
    case []: []
    case +j <> +t: colj(c, j) <> cols_of(c, t)

def mones(n: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m): F64.neg(1.0f64) <> mones(m)

def take_l(n: Nat, xs: List<&2, F64>) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m):
      match xs:
        case []: []
        case +x <> +t: x <> take_l(m, t)

def rel_res(rs: List<&2, F64>, ms: List<&2, F64>, +lmax: F64, +acc: F64) -> F64:
  match rs:
    case []: acc
    case +r <> +rt:
      match ms:
        case []: acc
        case +m <> +mt: rel_res(rt, mt, lmax, F64.max(acc, F64.div(F64.sqrt(r), F64.max(F64.mul(lmax, F64.sqrt(m)), 1.0e-300f64))))

type CX is Data:
  CX{ rows: List<&2, List<&2, List<&2, BE>>>, ms: List<&2, List<&2, V.Dir>>, pcs: List<&2, List<&2, V.Dir>>, w: U32, rho: F64, sg: F64 }

def fm_nn(+fm: FM) -> U32:
  FM{+nn, rows, rho, sg} = fm
  nn

def cx_of(+fm: FM, +mask: List<&2, F64>, +pc: List<&2, F64>) -> CX:
  FM{+nn, +rows, +rho, +sg} = fm
  +w = U32.add(U32.div(nn, U32.from_nat(parts())), 1)
  CX{cut_g(List<&2, BE>, parts(), rows, w), cut_g(V.Dir, parts(), trip(mask), w), cut_g(V.Dir, parts(), trip(pc), w), w, rho, sg}

def cx_w(+c: CX) -> U32:
  CX{rows, ms, pcs, +w, rho, sg} = c
  w

def cx_ms(+c: CX) -> List<&2, List<&2, V.Dir>>:
  CX{rows, +ms, pcs, w, rho, sg} = c
  ms

def cb_in(+c: CX, +nn: Nat, +cols: List<&2, List<&2, F64>>) -> List<&2, List<&2, List<&2, V.Dir>>>:
  cut_g(List<&2, V.Dir>, parts(), tcol(nn, B.pmap_g(~List<&2, F64>, ~F64, ~List<&2, V.Dir>, ~trip_f, 1, 0.0f64, cols)), cx_w(c))

def cat3(cs: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, List<&2, V.Dir>>:
  match cs:
    case []: []
    case +c <> +t: List.append(&2, List<&2, V.Dir>, c, cat3(t))

def cb_out(+x: List<&2, List<&2, List<&2, V.Dir>>>, +m: Nat) -> List<&2, List<&2, F64>>:
  B.pmap_g(~List<&2, V.Dir>, ~F64, ~List<&2, F64>, ~flat_f, 1, 0.0f64, tcol(m, cat3(x)))

def row_w(xs: List<&2, List<&2, V.Dir>>) -> Nat:
  match xs:
    case []: 0n
    case +r <> t: List.length(&2, V.Dir, r)

def cb_w(cs: List<&2, List<&2, List<&2, V.Dir>>>) -> Nat:
  match cs:
    case []: 0n
    case +c <> +t: Nat.max(row_w(c), cb_w(t))

type P2 is Data:
  P2{ a: List<&2, List<&2, V.Dir>>, b: List<&2, List<&2, V.Dir>> }

def p2z(xs: List<&2, List<&2, List<&2, V.Dir>>>, ys: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, P2>:
  match xs:
    case []: []
    case +x <> +xt:
      match ys:
        case []: []
        case +y <> +yt: P2{x, y} <> p2z(xt, yt)

type MK is Data:
  MK{ m: List<&2, V.Dir>, x: List<&2, List<&2, V.Dir>> }

def mkz(ms: List<&2, List<&2, V.Dir>>, xs: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, MK>:
  match ms:
    case []: []
    case +m <> +mt:
      match xs:
        case []: []
        case +x <> +xt: MK{m, x} <> mkz(mt, xt)

def had_rows(ms: List<&2, V.Dir>, xs: List<&2, List<&2, V.Dir>>) -> List<&2, List<&2, V.Dir>>:
  match ms:
    case []: []
    case +m <> +mt:
      match xs:
        case []: []
        case +x <> +xt: nd_had(m, x) <> had_rows(mt, xt)

def mk_f(c: F64, k: MK) -> List<&2, List<&2, V.Dir>>:
  MK{+m, +x} = k
  had_rows(m, x)

def cb_mask(+c: CX, +x: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, List<&2, List<&2, V.Dir>>>:
  B.pmap_g(~MK, ~F64, ~List<&2, List<&2, V.Dir>>, ~mk_f, 1, 0.0f64, mkz(cx_ms(c), x))

type OR is Data:
  OR{ rows: List<&2, List<&2, BE>>, m: List<&2, V.Dir> }

def orz(rs: List<&2, List<&2, List<&2, BE>>>, ms: List<&2, List<&2, V.Dir>>) -> List<&2, OR>:
  match rs:
    case []: []
    case +r <> +rt:
      match ms:
        case []: []
        case +m <> +mt: OR{r, m} <> orz(rt, mt)

def op_rows(rows: List<&2, List<&2, BE>>, ms: List<&2, V.Dir>, +c: QX) -> List<&2, List<&2, V.Dir>>:
  match rows:
    case []: []
    case +w <> +wt:
      match ms:
        case []: []
        case +m <> +mt: nd_had(m, qx_mv(c, w)) <> op_rows(wt, mt, c)

def op_f(c: QX, o: OR) -> List<&2, List<&2, V.Dir>>:
  OR{+rows, +m} = o
  op_rows(rows, m, c)

def cx_or(+c: CX) -> List<&2, OR>:
  CX{+rows, +ms, pcs, w, rho, sg} = c
  orz(rows, ms)

def ks_of(+mass: Bool) -> F64:
  Bool.pick(F64, mass, 0.0f64, 1.0f64)

def cx_mm(+c: CX, +mass: Bool) -> F64:
  CX{rows, ms, pcs, w, +rho, +sg} = c
  Bool.pick(F64, mass, rho, F64.mul(sg, rho))

def cb_op(+c: CX, +mass: Bool, +x: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, List<&2, List<&2, V.Dir>>>:
  +tb = B.tb_of(List<&2, V.Dir>, cat3(cb_mask(c, x)), [])
  B.pmap_g(~OR, ~QX, ~List<&2, List<&2, V.Dir>>, ~op_f, 1, QX{tb, ks_of(mass), cx_mm(c, mass), cb_w(x)}, cx_or(c))

def dir_dots(+x: V.Dir, ys: List<&2, V.Dir>) -> List<&2, F64>:
  match ys:
    case []: []
    case +y <> +t: S.dot(x, y) <> dir_dots(x, t)

def gn_full(xs: List<&2, V.Dir>, +ys: List<&2, V.Dir>, acc: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match xs:
    case []: []
    case +x <> +xt:
      match acc:
        case []: []
        case +a <> +at: add_l(a, dir_dots(x, ys)) <> gn_full(xt, ys, at)

def gn_up(xs: List<&2, V.Dir>, ys: List<&2, V.Dir>, acc: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match xs:
    case []: []
    case +x <> +xt:
      match ys:
        case []: []
        case +y <> +yt:
          match acc:
            case []: []
            case +a <> +at: add_l(a, dir_dots(x, y <> yt)) <> gn_up(xt, yt, at)

def zrows_up(n: Nat) -> List<&2, List<&2, F64>>:
  match n:
    case 0n: []
    case 1n+(+m): zeros_f(n) <> zrows_up(m)

def zrows(n: Nat, +k: Nat) -> List<&2, List<&2, F64>>:
  match n:
    case 0n: []
    case 1n+(+m): zeros_f(k) <> zrows(m, k)

def gr_up(xs: List<&2, List<&2, V.Dir>>, ys: List<&2, List<&2, V.Dir>>, +acc: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match xs:
    case []: acc
    case +x <> +xt:
      match ys:
        case []: acc
        case +y <> +yt: gr_up(xt, yt, gn_up(x, y, acc))

def gr_full(xs: List<&2, List<&2, V.Dir>>, ys: List<&2, List<&2, V.Dir>>, +acc: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match xs:
    case []: acc
    case +x <> +xt:
      match ys:
        case []: acc
        case +y <> +yt: gr_full(xt, yt, gn_full(x, y, acc))

def gr_sel(sym: Bool, +a: List<&2, List<&2, V.Dir>>, +b: List<&2, List<&2, V.Dir>>, +m: Nat, +k: Nat) -> List<&2, List<&2, F64>>:
  match sym:
    case True{}: gr_up(a, b, zrows_up(m))
    case False{}: gr_full(a, b, zrows(m, k))

type GC is Data:
  GC{ sym: Bool, m: Nat, k: Nat }

def gr_f(c: GC, p: P2) -> List<&2, List<&2, F64>>:
  GC{+sym, +m, +k} = c
  P2{+a, +b} = p
  gr_sel(sym, a, b, m, k)

def cb_gram(+sym: Bool, +x: List<&2, List<&2, List<&2, V.Dir>>>, +y: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, List<&2, F64>>:
  +g = sum_parts(B.pmap_g(~P2, ~GC, ~List<&2, List<&2, F64>>, ~gr_f, 1, GC{sym, cb_w(x), cb_w(y)}, p2z(x, y)))
  Bool.pick(List<&2, List<&2, F64>>, sym, sym_go(g, []), g)

def lin_dir(xs: List<&2, V.Dir>, cs: List<&2, F64>, +acc: V.Dir) -> V.Dir:
  match xs:
    case []: acc
    case +x <> +xt:
      match cs:
        case []: acc
        case +c <> +ct: lin_dir(xt, ct, S.dadd(acc, c, x))

def comb_node(+xs: List<&2, V.Dir>, cs: List<&2, List<&2, F64>>) -> List<&2, V.Dir>:
  match cs:
    case []: []
    case +c <> +t: lin_dir(xs, c, S.dr(0.0f64, 0.0f64, 0.0f64)) <> comb_node(xs, t)

def comb_rows(xs: List<&2, List<&2, V.Dir>>, +cs: List<&2, List<&2, F64>>) -> List<&2, List<&2, V.Dir>>:
  match xs:
    case []: []
    case +x <> +t: comb_node(x, cs) <> comb_rows(t, cs)

def comb_f(cs: List<&2, List<&2, F64>>, x: List<&2, List<&2, V.Dir>>) -> List<&2, List<&2, V.Dir>>:
  comb_rows(x, cs)

def cb_comb(+x: List<&2, List<&2, List<&2, V.Dir>>>, +cs: List<&2, List<&2, F64>>) -> List<&2, List<&2, List<&2, V.Dir>>>:
  B.pmap_g(~List<&2, List<&2, V.Dir>>, ~List<&2, List<&2, F64>>, ~List<&2, List<&2, V.Dir>>, ~comb_f, 1, cs, x)

def ax_rows(+a: List<&2, F64>, xs: List<&2, List<&2, V.Dir>>, ys: List<&2, List<&2, V.Dir>>) -> List<&2, List<&2, V.Dir>>:
  match xs:
    case []: []
    case +x <> +xt:
      match ys:
        case []: []
        case +y <> +yt: nd_axpy(a, x, y) <> ax_rows(a, xt, yt)

def axr_f(a: List<&2, F64>, p: P2) -> List<&2, List<&2, V.Dir>>:
  P2{+x, +y} = p
  ax_rows(a, x, y)

def cb_axpy(+a: List<&2, F64>, +x: List<&2, List<&2, List<&2, V.Dir>>>, +y: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, List<&2, List<&2, V.Dir>>>:
  B.pmap_g(~P2, ~List<&2, F64>, ~List<&2, List<&2, V.Dir>>, ~axr_f, 1, a, p2z(x, y))

def dt_rows(xs: List<&2, List<&2, V.Dir>>, ys: List<&2, List<&2, V.Dir>>, +acc: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: acc
    case +x <> +xt:
      match ys:
        case []: acc
        case +y <> +yt: dt_rows(xt, yt, nd_dot(x, y, acc))

def dtr_f(k: Nat, p: P2) -> List<&2, F64>:
  P2{+x, +y} = p
  dt_rows(x, y, zeros_f(k))

def sum_l(xs: List<&2, List<&2, F64>>, +acc: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: acc
    case +x <> +t: sum_l(t, add_l(acc, x))

def cb_dots(+x: List<&2, List<&2, List<&2, V.Dir>>>, +y: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, F64>:
  +k = cb_w(x)
  sum_l(B.pmap_g(~P2, ~Nat, ~List<&2, F64>, ~dtr_f, 1, k, p2z(x, y)), zeros_f(k))

def cat_rows(xs: List<&2, List<&2, V.Dir>>, ys: List<&2, List<&2, V.Dir>>) -> List<&2, List<&2, V.Dir>>:
  match xs:
    case []: []
    case +x <> +xt:
      match ys:
        case []: []
        case +y <> +yt: List.append(&2, V.Dir, x, y) <> cat_rows(xt, yt)

def catr_f(c: F64, p: P2) -> List<&2, List<&2, V.Dir>>:
  P2{+x, +y} = p
  cat_rows(x, y)

def cb_cat(+x: List<&2, List<&2, List<&2, V.Dir>>>, +y: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, List<&2, List<&2, V.Dir>>>:
  B.pmap_g(~P2, ~F64, ~List<&2, List<&2, V.Dir>>, ~catr_f, 1, 0.0f64, p2z(x, y))

def drop_d(n: Nat, xs: List<&2, V.Dir>) -> List<&2, V.Dir>:
  match n:
    case 0n: xs
    case 1n+j:
      match xs:
        case []: []
        case +h <> +t: drop_d(j, t)

def dr_rows(+n: Nat, xs: List<&2, List<&2, V.Dir>>) -> List<&2, List<&2, V.Dir>>:
  match xs:
    case []: []
    case +x <> +t: drop_d(n, x) <> dr_rows(n, t)

def drr_f(n: Nat, x: List<&2, List<&2, V.Dir>>) -> List<&2, List<&2, V.Dir>>:
  dr_rows(n, x)

def cb_drop(+n: Nat, +x: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, List<&2, List<&2, V.Dir>>>:
  B.pmap_g(~List<&2, List<&2, V.Dir>>, ~Nat, ~List<&2, List<&2, V.Dir>>, ~drr_f, 1, n, x)

def cx_ncs(+c: CX, +rs: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, NC>:
  CX{+rows, +ms, +pcs, w, rho, sg} = c
  nc_zip(rows, ms, pcs, rs)

def xs_of(cs: List<&2, NC>) -> List<&2, List<&2, List<&2, V.Dir>>>:
  match cs:
    case []: []
    case +c <> +t:
      NC{rows, m, pc, +x, r, p, q, d} = c
      x <> xs_of(t)

def ns_cx(+s: NS) -> List<&2, List<&2, List<&2, V.Dir>>>:
  NS{+cs, rz} = s
  xs_of(cs)

def cb_solve(+c: CX, +rs: List<&2, List<&2, List<&2, V.Dir>>>, +n: Nat) -> List<&2, List<&2, List<&2, V.Dir>>>:
  +k = cb_w(rs)
  +c0 = B.pmap_g(~NC, ~Nat, ~NC, ~ch_z, 1, k, cx_ncs(c, rs))
  ns_cx(npcg(n, False{}, 1.0f64, cx_mm(c, False{}), k, 0.0f64, NS{c0, sum_d(c0, zeros_f(k))}))

type QB is Data:
  QB{ q: List<&2, List<&2, List<&2, V.Dir>>>, mq: List<&2, List<&2, List<&2, V.Dir>>> }

def qb_q(+q: QB) -> List<&2, List<&2, List<&2, V.Dir>>>:
  QB{+x, mq} = q
  x

def nmon_ja(j: JA, +qs: List<&2, List<&2, List<&2, V.Dir>>>, +mq: List<&2, List<&2, List<&2, V.Dir>>>, +m: Nat) -> QB:
  JA{+a, +v} = j
  +d = diag_of(a, L.nat_range(m))
  +js = keep_js(d, 0n, F64.mul(1.0e-13f64, fmax(d, 0.0f64)))
  +cs = ccols(v, js, inv_sq(js, d))
  QB{cb_comb(qs, cs), cb_comb(mq, cs)}

def nmon(+c: CX, +qs: List<&2, List<&2, List<&2, V.Dir>>>) -> QB:
  +mq = cb_op(c, True{}, qs)
  +m = cb_w(qs)
  nmon_ja(jacobi(cb_gram(True{}, qs, mq), m), qs, mq, m)

def nmon2(+c: CX, +qs: List<&2, List<&2, List<&2, V.Dir>>>) -> QB:
  nmon(c, qb_q(nmon(c, qs)))

def nproj(+xs: List<&2, List<&2, List<&2, V.Dir>>>, +mxs: List<&2, List<&2, List<&2, V.Dir>>>, +ys: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, List<&2, List<&2, V.Dir>>>:
  +m = cb_w(ys)
  cb_axpy(mones(m), cb_comb(xs, cols_of(cb_gram(False{}, mxs, ys), L.nat_range(m))), ys)

def next(+c: CX, +xs: List<&2, List<&2, List<&2, V.Dir>>>, +ys: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, List<&2, List<&2, V.Dir>>>:
  +mxs = cb_op(c, True{}, xs)
  cb_cat(xs, qb_q(nmon2(c, nproj(xs, mxs, nproj(xs, mxs, ys)))))

type NB is Data:
  NB{ x: List<&2, List<&2, List<&2, V.Dir>>>, kx: List<&2, List<&2, List<&2, V.Dir>>>, lam: List<&2, F64>, p: List<&2, List<&2, List<&2, V.Dir>>> }

def nlob_ja(j: JA, +qs: List<&2, List<&2, List<&2, V.Dir>>>, +kq: List<&2, List<&2, List<&2, V.Dir>>>, +m: Nat, +k: Nat, +nx: Nat) -> NB:
  JA{+a, +v} = j
  +sel = ix_take(k, so_ix(B.msort(~IX, ~ix_cmp, ixs(diag_of(a, L.nat_range(m)), 0n))))
  +js = ix_i(sel)
  +one = ones_l(k)
  +cs = ccols(v, js, one)
  NB{cb_comb(qs, cs), cb_comb(kq, cs), ix_v(sel), cb_comb(cb_drop(nx, qs), ccols(drop_l(nx, v), js, one))}

def nlob_rr(+c: CX, +qs: List<&2, List<&2, List<&2, V.Dir>>>, +k: Nat, +nx: Nat) -> NB:
  +kq = cb_op(c, False{}, qs)
  +m = cb_w(qs)
  nlob_ja(jacobi(cb_gram(True{}, qs, kq), m), qs, kq, m, k, nx)

def nb_res(+s: NB, +c: CX, +kw: Nat) -> F64:
  NB{+xs, +kxs, +lam, ps} = s
  +mxs = cb_op(c, True{}, xs)
  +rs = cb_axpy(negs(lam), mxs, kxs)
  rel_res(take_l(kw, cb_dots(rs, rs)), take_l(kw, cb_dots(mxs, mxs)), fmax(take_l(kw, lam), 0.0f64), 0.0f64)

type NL is Data:
  NL{ s: NB, it: Nat, res: F64 }

def nb_cat(+ws: List<&2, List<&2, List<&2, V.Dir>>>, +ps: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, List<&2, List<&2, V.Dir>>>:
  Bool.pick(List<&2, List<&2, List<&2, V.Dir>>>, Nat.is_eq(cb_w(ps), 0n), ws, cb_cat(ws, ps))

type DF is Data:
  DF{ on: Bool, q: QB }

def dfl_go(on: Bool, +q: QB, +y: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, List<&2, List<&2, V.Dir>>>:
  match on:
    case True{}:
      QB{+r, +mr} = q
      nproj(r, mr, y)
    case False{}: y

def dfl(+d: DF, +y: List<&2, List<&2, List<&2, V.Dir>>>) -> List<&2, List<&2, List<&2, V.Dir>>>:
  DF{+on, +q} = d
  dfl_go(on, q, y)

def df_of(on: Bool, +c: CX, +nn: Nat, +rb: List<&2, List<&2, F64>>) -> DF:
  match on:
    case True{}: DF{True{}, nmon(c, cb_in(c, nn, rb))}
    case False{}: DF{False{}, QB{[], []}}

def nlob_it(n: Nat, done: Bool, +c: CX, +d: DF, +k: Nat, +kw: Nat, +tol: F64, +it: Nat, +s: NB, +rr: F64) -> NL:
  match n:
    case 0n: NL{s, it, rr}
    case 1n+j:
      match done:
        case True{}: NL{s, it, rr}
        case False{}:
          NB{+xs, +kxs, +lam, +ps} = s
          +ws = dfl(d, cb_solve(c, cb_axpy(negs(lam), cb_op(c, True{}, xs), kxs), 30n))
          +s2 = nlob_rr(c, next(c, xs, nb_cat(ws, ps)), k, k)
          +r2 = nb_res(s2, c, kw)
          nlob_it(j, F64.is_lt(r2, tol), c, d, k, kw, tol, Nat.add(it, 1n), s2, r2)

def nb_np(+s: NB) -> NB:
  NB{+xs, +kxs, +lam, ps} = s
  NB{xs, kxs, lam, []}

def nl_si(+t: NL, +k: Nat) -> SI:
  NL{+s, +it, +rr} = t
  NB{+xs, kxs, +lam, ps} = s
  SI{cb_out(xs, k), lam, it, rr}

def lobpcg(n: Nat, +fm: FM, +mask: List<&2, F64>, +k: Nat, +kw: Nat, +tol: F64, +x0: List<&2, List<&2, F64>>, +rb: List<&2, List<&2, F64>>) -> SI:
  +c = cx_of(fm, mask, precond(fm, mask))
  +nn = U32.to_nat(fm_nn(fm))
  +d = df_of(Bool.not(Nat.is_eq(List.length(&2, List<&2, F64>, rb), 0n)), c, nn, rb)
  +s0 = nlob_rr(c, qb_q(nmon2(c, dfl(d, cb_in(c, nn, x0)))), k, k)
  +r0 = nb_res(s0, c, kw)
  nl_si(nlob_it(n, F64.is_lt(r0, tol), c, d, k, kw, tol, 0n, nb_np(s0), r0), k)
