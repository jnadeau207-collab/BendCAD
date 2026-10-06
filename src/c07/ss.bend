import Base
import ../c00/types.bend as T
import ../c06/iv.bend as I
import ../base/par.bend as B
import ./ivx.bend as X
import ./eng.bend as N

type Pc is Data:
  Pc{ x: List<&2, I.I>, k: Nat }

type Ep is Data:
  Ep{ k: Nat, c: F64, z: List<&2, I.I>, i: U32, s: U32 }

type Cm is Data:
  Cm{ lab: U32, ps: List<&2, U32> }

type Mt is Data:
  Mt{ es: List<&2, B.Ed>, open: List<&2, Ep> }

type Br is Data:
  Br{ closed: Bool, pts: List<&2, List<&2, I.I>>, ends: List<&2, Ep> }

type Ss is Data:
  Ss{ ok: Bool, brs: List<&2, Br>, un: List<&2, List<&2, I.I>> }

def pieces(rs: List<&2, N.Res>) -> List<&2, Pc>:
  match rs:
    case []: []
    case r <> +t:
      match r:
        case N.R_pc{x, k}: Pc{x, k} <> pieces(t)
        case _: pieces(t)

def unres(rs: List<&2, N.Res>) -> List<&2, List<&2, I.I>>:
  match rs:
    case []: []
    case r <> +t:
      match r:
        case N.R_un{x}: x <> unres(t)
        case _: unres(t)

def pref(n: Nat, +p: N.Pb, +x: List<&2, I.I>, +k: Nat) -> List<&2, I.I>:
  match n:
    case 0n: x
    case 1n+r:
      +z = X.vmeet(N.pkraw(p, x, N.pb_j(p, x), k, N.pb_m(p)), X.vdrop(x, k))
      pref(r, p, X.vins(k, z, X.vn(x, k)), k)

def at_face(+p: N.Pb, +x: List<&2, I.I>, +k: Nat, +c: F64) -> List<&2, I.I>:
  pref(10n, p, X.vset(x, k, I.ipt(c)), k)

def fp_eps(fs: List<&2, N.Fp>) -> List<&2, Ep>:
  match fs:
    case []: []
    case f <> t:
      N.Fp{x, +j, c} = f
      Ep{j, c, X.vdrop(x, j), 0, 0} <> fp_eps(t)

def fp_go(+p: N.Pb, +x: List<&2, I.I>) -> List<&2, Ep>:
  fp_eps(N.ff_pts(N.face_all(p, x)))

def tag(es: List<&2, Ep>, +i: U32, +s: U32) -> List<&2, Ep>:
  match es:
    case []: []
    case e <> t:
      Ep{k, c, z, a, b} = e
      Ep{k, c, z, i, s} <> tag(t, i, (s + 1 : U32))

def eps_of(pcs: List<&2, Pc>, +p: N.Pb, +i: U32) -> List<&2, Ep>:
  match pcs:
    case []: []
    case q <> t:
      Pc{+x, k} = q
      List.append(&2, Ep, tag(fp_go(p, x), i, 0), eps_of(t, p, (i + 1 : U32)))

def ep_k(e: Ep) -> Nat:
  Ep{k, c, z, i, s} = e
  k

def ep_c(e: Ep) -> F64:
  Ep{k, c, z, i, s} = e
  c

def ep_z(e: Ep) -> List<&2, I.I>:
  Ep{k, c, z, i, s} = e
  z

def ep_i(e: Ep) -> U32:
  Ep{k, c, z, i, s} = e
  i

def zcmp(xs: List<&2, I.I>, ys: List<&2, I.I>) -> B.Sgn:
  match xs:
    case []: B.Sz{}
    case +x <> t:
      match ys:
        case []: B.Sz{}
        case +y <> u:
          +a = X.imid(x)
          +b = X.imid(y)
          Bool.pick(B.Sgn, F64.is_lt(a, b), B.Sn{}, Bool.pick(B.Sgn, F64.is_lt(b, a), B.Sp{}, zcmp(t, u)))

def ep_cmp_go(+a: Ep, +b: Ep) -> B.Sgn:
  +ka = ep_k(a)
  +kb = ep_k(b)
  +ca = ep_c(a)
  +cb = ep_c(b)
  Bool.pick(B.Sgn, Nat.is_lt(ka, kb), B.Sn{},
    Bool.pick(B.Sgn, Nat.is_lt(kb, ka), B.Sp{},
      Bool.pick(B.Sgn, F64.is_lt(ca, cb), B.Sn{},
        Bool.pick(B.Sgn, F64.is_lt(cb, ca), B.Sp{}, zcmp(ep_z(a), ep_z(b))))))

def ep_cmp(a: Ep, b: Ep) -> B.Sgn:
  ep_cmp_go(a, b)

def so_xs(s: B.So<&2, Ep>) -> List<&2, Ep>:
  B.So{ok, xs} = s
  xs

def mt_es(m: Mt) -> List<&2, B.Ed>:
  Mt{es, open} = m
  es

def mt_open(m: Mt) -> List<&2, Ep>:
  Mt{es, open} = m
  open

def same_kc(+a: Ep, +b: Ep) -> Bool:
  Bool.and(Nat.is_eq(ep_k(a), ep_k(b)), F64.is_eq(ep_c(a), ep_c(b)))

def take_g(xs: List<&2, Ep>, +h: Ep) -> List<&2, Ep>:
  match xs:
    case []: []
    case +e <> t: Bool.pick(List<&2, Ep>, same_kc(h, e), e <> take_g(t, h), [])

def drop_g(xs: List<&2, Ep>, +h: Ep) -> List<&2, Ep>:
  match xs:
    case []: []
    case +e <> +t: Bool.pick(List<&2, Ep>, same_kc(h, e), drop_g(t, h), e <> t)

def has_ov(xs: List<&2, Ep>, +e: Ep) -> Bool:
  match xs:
    case []: False{}
    case +x <> t: Bool.or(Bool.not(X.vdisj(ep_z(x), ep_z(e))), has_ov(t, e))

def ep_dummy() -> Ep:
  Ep{0n, 0.0f64, [], 0, 0}

def first_ov(xs: List<&2, Ep>, +e: Ep) -> Ep:
  match xs:
    case []: ep_dummy()
    case +x <> t: Bool.pick(Ep, Bool.not(X.vdisj(ep_z(x), ep_z(e))), x, first_ov(t, e))

def rm_first_ov(xs: List<&2, Ep>, +e: Ep, +done: Bool) -> List<&2, Ep>:
  match xs:
    case []: []
    case +x <> t:
      +hit = Bool.and(Bool.not(done), Bool.not(X.vdisj(ep_z(x), ep_z(e))))
      +r = rm_first_ov(t, e, Bool.or(done, hit))
      Bool.pick(List<&2, Ep>, hit, r, x <> r)

def pair_go(n: Nat, +xs: List<&2, Ep>, +acc: Mt) -> Mt:
  match n:
    case 0n: acc
    case 1n+m:
      match xs:
        case []: acc
        case +e <> +t:
          +ov = has_ov(t, e)
          pair_go(m, Bool.pick(List<&2, Ep>, ov, rm_first_ov(t, e, False{}), t),
            Bool.pick(Mt, ov, Mt{B.Ed{ep_i(e), ep_i(first_ov(t, e))} <> mt_es(acc), mt_open(acc)}, Mt{mt_es(acc), e <> mt_open(acc)}))

def groups_go(n: Nat, +xs: List<&2, Ep>, +acc: Mt) -> Mt:
  match n:
    case 0n: acc
    case 1n+m:
      match xs:
        case []: acc
        case +e <> t:
          +g = take_g(xs, e)
          groups_go(m, drop_g(xs, e), pair_go(List.length(&2, Ep, g), g, acc))

def matches(+es: List<&2, Ep>) -> Mt:
  groups_go(List.length(&2, Ep, es), so_xs(B.msort(~Ep, ~ep_cmp, es)), Mt{[], []})

def lab_at(ls: List<&2, U32>, +i: U32) -> U32:
  match ls:
    case []: 0
    case l <> t: Bool.pick(U32, U32.is_eq(i, 0), l, lab_at(t, (i - 1 : U32)))

def cc_ps(c: B.CC) -> List<&2, U32>:
  B.CC{ok, ps} = c
  ps

def cc_ok(c: B.CC) -> Bool:
  B.CC{ok, ps} = c
  ok

def uniq_go(xs: List<&2, U32>, +prev: U32, +first: Bool) -> List<&2, U32>:
  match xs:
    case []: []
    case +x <> t:
      +r = uniq_go(t, x, False{})
      Bool.pick(List<&2, U32>, Bool.and(Bool.not(first), U32.is_eq(x, prev)), r, x <> r)

def u_cmp(a: U32, b: U32) -> B.Sgn:
  B.u_cmp(a, b)

def so_us(s: B.So<&2, U32>) -> List<&2, U32>:
  B.So{ok, xs} = s
  xs

def labels(+ls: List<&2, U32>) -> List<&2, U32>:
  uniq_go(so_us(B.msort(~U32, ~u_cmp, ls)), 0, True{})

def members(ls: List<&2, U32>, +lab: U32, +i: U32) -> List<&2, U32>:
  match ls:
    case []: []
    case +l <> t:
      +r = members(t, lab, (i + 1 : U32))
      Bool.pick(List<&2, U32>, U32.is_eq(l, lab), i <> r, r)

def comps(+lab_list: List<&2, U32>, us: List<&2, U32>) -> List<&2, Cm>:
  match us:
    case []: []
    case +u <> t: Cm{u, members(lab_list, u, 0)} <> comps(lab_list, t)

def nb_add(+tb: B.Tb<&2, List<&2, U32>>, +a: U32, +b: U32) -> B.Tb<&2, List<&2, U32>>:
  B.tb_set(List<&2, U32>, tb, a, b <> B.tb_get(List<&2, U32>, tb, a))

def nb_go(es: List<&2, B.Ed>, +tb: B.Tb<&2, List<&2, U32>>) -> B.Tb<&2, List<&2, U32>>:
  match es:
    case []: tb
    case e <> t:
      B.Ed{+u, +v} = e
      nb_go(t, nb_add(nb_add(tb, u, v), v, u))

def nb_of(+n: Nat, +es: List<&2, B.Ed>) -> B.Tb<&2, List<&2, U32>>:
  nb_go(es, B.tb_of(List<&2, U32>, B.rep_n(List<&2, U32>, n, []), []))

def u_nth(xs: List<&2, U32>, +i: Nat, +d: U32) -> U32:
  match xs:
    case []: d
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: u_nth(t, j, d)

def nxt(+ns: List<&2, U32>, +prev: U32) -> U32:
  +a = u_nth(ns, 0n, 4294967295)
  +b = u_nth(ns, 1n, 4294967295)
  Bool.pick(U32, U32.is_eq(a, prev), b, a)

def walk(n: Nat, +nb: B.Tb<&2, List<&2, U32>>, +cur: U32, +prev: U32, +start: U32, done: Bool) -> List<&2, U32>:
  match n:
    case 0n: []
    case 1n+m:
      match done:
        case True{}: []
        case False{}:
          +ns = B.tb_get(List<&2, U32>, nb, cur)
          +nx = nxt(ns, prev)
          cur <> walk(m, nb, nx, cur, start, Bool.or(U32.is_eq(nx, 4294967295), U32.is_eq(nx, start)))

def deg(+nb: B.Tb<&2, List<&2, U32>>, +i: U32) -> Nat:
  List.length(&2, U32, B.tb_get(List<&2, U32>, nb, i))

def start_of(ms: List<&2, U32>, +nb: B.Tb<&2, List<&2, U32>>, +d: U32) -> U32:
  match ms:
    case []: d
    case +m <> t: Bool.pick(U32, Nat.is_lt(deg(nb, m), 2n), m, start_of(t, nb, d))

def ep_full(e: Ep) -> List<&2, I.I>:
  Ep{k, c, z, i, s} = e
  X.vins(k, z, I.ipt(c))

def ep_nth(es: List<&2, Ep>, +i: Nat) -> Ep:
  match es:
    case []: ep_dummy()
    case e <> t:
      match i:
        case 0n: e
        case 1n+j: ep_nth(t, j)

def sample(+p: N.Pb, q: Pc) -> List<&2, I.I>:
  Pc{+x, +k} = q
  +es = fp_go(p, x)
  +a = X.vn(ep_full(ep_nth(es, 0n)), k)
  +b = X.vn(ep_full(ep_nth(es, 1n)), k)
  at_face(p, x, k, F64.add(F64.mul(0.5f64, X.imid(a)), F64.mul(0.5f64, X.imid(b))))

def samples(ixs: List<&2, U32>, +pt: B.Tb<&2, Pc>, +p: N.Pb) -> List<&2, List<&2, I.I>>:
  match ixs:
    case []: []
    case i <> t: sample(p, B.tb_get(Pc, pt, i)) <> samples(t, pt, p)

def ends_of(os: List<&2, Ep>, +ls: List<&2, U32>, +lab: U32) -> List<&2, Ep>:
  match os:
    case []: []
    case +e <> t:
      +r = ends_of(t, ls, lab)
      Bool.pick(List<&2, Ep>, U32.is_eq(lab_at(ls, ep_i(e)), lab), e <> r, r)

def br_of(c: Cm, +nb: B.Tb<&2, List<&2, U32>>, +pt: B.Tb<&2, Pc>, +p: N.Pb, +ls: List<&2, U32>, +os: List<&2, Ep>) -> Br:
  Cm{+lab, +ms} = c
  +n = List.length(&2, U32, ms)
  +st = start_of(ms, nb, u_nth(ms, 0n, 0))
  +ends = ends_of(os, ls, lab)
  Br{Nat.is_eq(List.length(&2, Ep, ends), 0n), samples(walk(n, nb, st, 4294967295, st, False{}), pt, p), ends}

def brs_of(cs: List<&2, Cm>, +nb: B.Tb<&2, List<&2, U32>>, +pt: B.Tb<&2, Pc>, +p: N.Pb, +ls: List<&2, U32>, +os: List<&2, Ep>) -> List<&2, Br>:
  match cs:
    case []: []
    case c <> t: br_of(c, nb, pt, p, ls, os) <> brs_of(t, nb, pt, p, ls, os)

def trace(+p: N.Pb, +d: Nat, +dom: List<&2, I.I>) -> Ss:
  +rs = N.solve(d, p, dom)
  +pcs = pieces(rs)
  +n = List.length(&2, Pc, pcs)
  +mt = matches(eps_of(pcs, p, 0))
  +es = mt_es(mt)
  +cc = B.components(U32.from_nat(n), es)
  +ls = cc_ps(cc)
  +nb = nb_of(n, es)
  +pt = B.tb_of(Pc, pcs, Pc{[], 0n})
  Ss{cc_ok(cc), brs_of(comps(ls, labels(ls)), nb, pt, p, ls, mt_open(mt)), unres(rs)}
