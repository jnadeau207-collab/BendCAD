import Base
import ../c06/sx.bend as S

type SG is Data:
  SG{ len: F64, od: F64, id: F64, e: F64, nu: F64, rho: F64 }

type PT is Data:
  PT{ kw: F64, kt: F64, m: F64, jd: F64 }

type E4 is Data:
  E4{ k: List<&2, List<&2, F64>>, m: List<&2, List<&2, F64>> }

type WR is Data:
  WR{ d: F64, u1: F64, u2: F64, u3: F64 }

type FR is Data:
  FR{ neg: Nat, w1: WR, w2: WR, w3: WR }

def pi() -> F64:
  3.141592653589793f64

def sq(+x: F64) -> F64:
  F64.mul(x, x)

def area(+od: F64, +id: F64) -> F64:
  F64.mul(F64.div(pi(), 4.0f64), F64.sub(sq(od), sq(id)))

def inert(+od: F64, +id: F64) -> F64:
  F64.mul(F64.div(pi(), 64.0f64), F64.sub(sq(sq(od)), sq(sq(id))))

def kappa(+od: F64, +id: F64, +nu: F64) -> F64:
  +m = F64.div(id, od)
  +m2 = sq(m)
  +a = sq(F64.add(1.0f64, m2))
  F64.div(F64.mul(F64.mul(6.0f64, F64.add(1.0f64, nu)), a),
    F64.add(F64.mul(F64.add(7.0f64, F64.mul(6.0f64, nu)), a), F64.mul(F64.add(20.0f64, F64.mul(12.0f64, nu)), m2)))

def sym4(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64, +g: F64, +h: F64, +i: F64, +j: F64) -> List<&2, List<&2, F64>>:
  [[a, b, c, d], [b, e, f, g], [c, f, h, i], [d, g, i, j]]

def sclr(+s: F64, xs: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> t: F64.mul(s, x) <> sclr(s, t)

def scl(+s: F64, rs: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match rs:
    case []: []
    case r <> t: sclr(s, r) <> scl(s, t)

def addr(xs: List<&2, F64>, ys: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> xt:
      match ys:
        case []: []
        case +y <> yt: F64.add(x, y) <> addr(xt, yt)

def addm(xs: List<&2, List<&2, F64>>, ys: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match xs:
    case []: []
    case x <> xt:
      match ys:
        case []: []
        case y <> yt: addr(x, y) <> addm(xt, yt)

def p2(+a: F64, +b: F64, +c: F64, +ph: F64) -> F64:
  F64.add(a, F64.add(F64.mul(b, ph), F64.mul(c, sq(ph))))

def elem(s: SG, +le: F64) -> E4:
  SG{+l0, +od, +id, +e, +nu, +rho} = s
  +a = area(od, id)
  +ii = inert(od, id)
  +g = F64.div(e, F64.mul(2.0f64, F64.add(1.0f64, nu)))
  +ph = F64.div(F64.mul(12.0f64, F64.mul(e, ii)), F64.mul(F64.mul(kappa(od, id, nu), F64.mul(g, a)), sq(le)))
  +l = le
  +l2 = sq(le)
  +kf = F64.div(F64.mul(e, ii), F64.mul(F64.add(1.0f64, ph), F64.mul(l2, l)))
  +k = scl(kf, sym4(12.0f64, F64.mul(6.0f64, l), F64.neg(12.0f64), F64.mul(6.0f64, l), F64.mul(F64.add(4.0f64, ph), l2),
    F64.neg(F64.mul(6.0f64, l)), F64.mul(F64.sub(2.0f64, ph), l2), 12.0f64, F64.neg(F64.mul(6.0f64, l)), F64.mul(F64.add(4.0f64, ph), l2)))
  +q = sq(F64.add(1.0f64, ph))
  +t1 = p2(F64.div(13.0f64, 35.0f64), F64.div(7.0f64, 10.0f64), F64.div(1.0f64, 3.0f64), ph)
  +t2 = F64.mul(l, p2(F64.div(11.0f64, 210.0f64), F64.div(11.0f64, 120.0f64), F64.div(1.0f64, 24.0f64), ph))
  +t3 = p2(F64.div(9.0f64, 70.0f64), F64.div(3.0f64, 10.0f64), F64.div(1.0f64, 6.0f64), ph)
  +t4 = F64.mul(l, p2(F64.div(13.0f64, 420.0f64), F64.div(3.0f64, 40.0f64), F64.div(1.0f64, 24.0f64), ph))
  +t5 = F64.mul(l2, p2(F64.div(1.0f64, 105.0f64), F64.div(1.0f64, 60.0f64), F64.div(1.0f64, 120.0f64), ph))
  +t6 = F64.mul(l2, p2(F64.div(1.0f64, 140.0f64), F64.div(1.0f64, 60.0f64), F64.div(1.0f64, 120.0f64), ph))
  +mt = scl(F64.div(F64.mul(rho, F64.mul(a, l)), q), sym4(t1, t2, t3, F64.neg(t4), t5, t4, F64.neg(t6), t1, F64.neg(t2), t5))
  +r1 = F64.div(6.0f64, 5.0f64)
  +r2 = F64.mul(l, F64.sub(F64.div(1.0f64, 10.0f64), F64.div(ph, 2.0f64)))
  +r3 = F64.mul(l2, p2(F64.div(2.0f64, 15.0f64), F64.div(1.0f64, 6.0f64), F64.div(1.0f64, 3.0f64), ph))
  +r4 = F64.mul(l2, p2(F64.neg(F64.div(1.0f64, 30.0f64)), F64.neg(F64.div(1.0f64, 6.0f64)), F64.div(1.0f64, 6.0f64), ph))
  +mr = scl(F64.div(F64.mul(rho, ii), F64.mul(q, l)), sym4(r1, r2, F64.neg(r1), r2, r3, F64.neg(r2), r4, r1, F64.neg(r2), r3))
  E4{k, addm(mt, mr)}

def z4() -> List<&2, List<&2, F64>>:
  [[0.0f64, 0.0f64, 0.0f64, 0.0f64], [0.0f64, 0.0f64, 0.0f64, 0.0f64], [0.0f64, 0.0f64, 0.0f64, 0.0f64], [0.0f64, 0.0f64, 0.0f64, 0.0f64]]

def at(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: 0.0f64
    case +x <> t:
      match i:
        case 0n: x
        case 1n+j: at(t, j)

def rw(rs: List<&2, List<&2, F64>>, +i: Nat) -> List<&2, F64>:
  match rs:
    case []: []
    case r <> t:
      match i:
        case 0n: r
        case 1n+j: rw(t, j)

def a_of(+lam: F64, +e: E4) -> List<&2, List<&2, F64>>:
  E4{+k, +m} = e
  addm(k, scl(F64.neg(lam), m))

def pt_dw(+lam: F64, +p: PT) -> F64:
  PT{+kw, +kt, +m, +jd} = p
  F64.sub(kw, F64.mul(lam, m))

def pt_dt(+lam: F64, +p: PT) -> F64:
  PT{+kw, +kt, +m, +jd} = p
  F64.sub(kt, F64.mul(lam, jd))

def rows2(+pv: List<&2, List<&2, F64>>, +nx: List<&2, List<&2, F64>>, +dw: F64, +dt: F64) -> List<&2, List<&2, F64>>:
  +p2r = rw(pv, 2n)
  +p3r = rw(pv, 3n)
  +n0 = rw(nx, 0n)
  +n1 = rw(nx, 1n)
  [[F64.add(F64.add(at(p2r, 2n), at(n0, 0n)), dw), F64.add(at(p2r, 3n), at(n0, 1n)), at(n0, 2n), at(n0, 3n)],
    [F64.add(F64.add(at(p3r, 3n), at(n1, 1n)), dt), at(n1, 2n), at(n1, 3n), 0.0f64]]

def bands(+lam: F64, ps: List<&2, PT>, es: List<&2, E4>, +pv: List<&2, List<&2, F64>>) -> List<&2, List<&2, F64>>:
  match ps:
    case []: []
    case +p <> pt:
      match es:
        case []: rows2(pv, z4(), pt_dw(lam, p), pt_dt(lam, p))
        case +e <> et:
          +nx = a_of(lam, e)
          List.append(&2, List<&2, F64>, rows2(pv, nx, pt_dw(lam, p), pt_dt(lam, p)), bands(lam, pt, et, nx))

def wr0() -> WR:
  WR{1.0f64, 0.0f64, 0.0f64, 0.0f64}

def wd(+w: WR) -> F64:
  WR{d, u1, u2, u3} = w
  d

def wu(+w: WR, +i: Nat) -> F64:
  WR{d, +u1, +u2, +u3} = w
  Bool.pick(F64, Nat.is_eq(i, 1n), u1, Bool.pick(F64, Nat.is_eq(i, 2n), u2, Bool.pick(F64, Nat.is_eq(i, 3n), u3, 0.0f64)))

def cterm(+w: WR, +dl: Nat, +t: Nat) -> F64:
  F64.mul(F64.mul(wu(w, dl), wd(w)), wu(w, Nat.add(dl, t)))

def s_of(+r: List<&2, F64>, +t: Nat, +w1: WR, +w2: WR, +w3: WR) -> F64:
  F64.sub(F64.sub(F64.sub(at(r, t), cterm(w1, 1n, t)), cterm(w2, 2n, t)), cterm(w3, 3n, t))

def mk_wr(+d: F64, +a: F64, +b: F64, +c: F64) -> WR:
  WR{d, a, b, c}

def mk_fr(+n: Nat, +a: WR, +b: WR, +c: WR) -> FR:
  FR{n, a, b, c}

def piv(+d0: F64) -> F64:
  Bool.pick(F64, F64.is_eq(d0, 0.0f64), 1.0e-300f64, d0)

def step_d(+d: F64, +neg: Nat, +r: List<&2, F64>, +w1: WR, +w2: WR, +w3: WR) -> FR:
  mk_fr(Bool.pick(Nat, F64.is_lt(d, 0.0f64), Nat.add(neg, 1n), neg),
    mk_wr(d, F64.div(s_of(r, 1n, w1, w2, w3), d), F64.div(s_of(r, 2n, w1, w2, w3), d), F64.div(s_of(r, 3n, w1, w2, w3), d)), w1, w2)

def step(+fr: FR, +r: List<&2, F64>) -> FR:
  FR{+neg, +w1, +w2, +w3} = fr
  step_d(piv(s_of(r, 0n, w1, w2, w3)), neg, r, w1, w2, w3)

def count(rs: List<&2, List<&2, F64>>, +fr: FR) -> Nat:
  match rs:
    case []:
      FR{n, a, b, c} = fr
      n
    case +r <> t: count(t, step(fr, r))

def below(+lam: F64, +es: List<&2, E4>, +ps: List<&2, PT>) -> Nat:
  count(bands(lam, ps, es, z4()), FR{0n, wr0(), wr0(), wr0()})

def up_hi(n: Nat, +k: Nat, +hi: F64, +es: List<&2, E4>, +ps: List<&2, PT>) -> F64:
  match n:
    case 0n: hi
    case 1n+j: Bool.pick(F64, Nat.is_lt(k, below(hi, es, ps)), hi, up_hi(j, k, F64.mul(hi, 4.0f64), es, ps))

def bis(n: Nat, +k: Nat, +lo: F64, +hi: F64, +es: List<&2, E4>, +ps: List<&2, PT>) -> F64:
  match n:
    case 0n: F64.mul(0.5f64, F64.add(lo, hi))
    case 1n+j:
      +mid = F64.mul(0.5f64, F64.add(lo, hi))
      +lt = Nat.is_lt(k, below(mid, es, ps))
      bis(j, k, Bool.pick(F64, lt, lo, mid), Bool.pick(F64, lt, mid, hi), es, ps)

def eig(+k: Nat, +es: List<&2, E4>, +ps: List<&2, PT>) -> F64:
  bis(200n, k, 0.0f64, up_hi(200n, k, 1.0f64, es, ps), es, ps)

type AT is Data:
  AT{ x: F64, p: PT }

type RB is Data:
  RB{ ok: Bool, why: String, segs: List<&2, SG>, ats: List<&2, AT>, n: Nat, k: Nat }

def pt0() -> PT:
  PT{0.0f64, 0.0f64, 0.0f64, 0.0f64}

def pt_add(+a: PT, +b: PT) -> PT:
  PT{+a1, +a2, +a3, +a4} = a
  PT{+b1, +b2, +b3, +b4} = b
  PT{F64.add(a1, b1), F64.add(a2, b2), F64.add(a3, b3), F64.add(a4, b4)}

def near(+a: F64, +b: F64) -> Bool:
  F64.is_le(F64.abs(F64.sub(a, b)), F64.mul(1.0e-9f64, F64.add(1.0f64, F64.abs(b))))

def pt_at(ats: List<&2, AT>, +x: F64, +acc: PT) -> PT:
  match ats:
    case []: acc
    case +h <> t:
      AT{+ax, +ap} = h
      pt_at(t, x, Bool.pick(PT, near(ax, x), pt_add(acc, ap), acc))

def rep_e(n: Nat, +e: E4) -> List<&2, E4>:
  match n:
    case 0n: []
    case 1n+m: e <> rep_e(m, e)

def rep_p(n: Nat) -> List<&2, PT>:
  match n:
    case 0n: []
    case 1n+m: pt0() <> rep_p(m)

def sg_len(+s: SG) -> F64:
  SG{l, od, id, e, nu, rho} = s
  l

def es_of(ss: List<&2, SG>, +n: Nat) -> List<&2, E4>:
  match ss:
    case []: []
    case +s <> t: List.append(&2, E4, rep_e(n, elem(s, F64.div(sg_len(s), U64.to_f64(U64.from_nat(n))))), es_of(t, n))

def ps_of(ss: List<&2, SG>, +n: Nat, +x: F64, +ats: List<&2, AT>) -> List<&2, PT>:
  match ss:
    case []: []
    case +s <> t:
      +x1 = F64.add(x, sg_len(s))
      List.append(&2, PT, rep_p(Nat.sub(n, 1n)), pt_at(ats, x1, pt0()) <> ps_of(t, n, x1, ats))

def bnds(ss: List<&2, SG>, +x: F64) -> List<&2, F64>:
  match ss:
    case []: []
    case +s <> t:
      +x1 = F64.add(x, sg_len(s))
      x1 <> bnds(t, x1)

def on_any(xs: List<&2, F64>, +x: F64) -> Bool:
  match xs:
    case []: False{}
    case +h <> t: Bool.or(near(x, h), on_any(t, x))

def ats_ok(ats: List<&2, AT>, +xs: List<&2, F64>) -> Bool:
  match ats:
    case []: True{}
    case +h <> t:
      AT{+ax, ap} = h
      Bool.and(on_any(xs, ax), ats_ok(t, xs))

def eigs(+es: List<&2, E4>, +ps: List<&2, PT>, k: Nat, +i: Nat) -> List<&2, F64>:
  match k:
    case 0n: []
    case 1n+j: F64.mul(F64.sqrt(eig(i, es, ps)), F64.div(60.0f64, F64.mul(2.0f64, pi()))) <> eigs(es, ps, j, Nat.add(i, 1n))

def speeds(+ss: List<&2, SG>, +ats: List<&2, AT>, +n: Nat, +k: Nat) -> List<&2, F64>:
  eigs(es_of(ss, n), pt_at(ats, 0.0f64, pt0()) <> ps_of(ss, n, 0.0f64, ats), k, 0n)

def f_or(m: Maybe<&2, F64>) -> F64:
  match m:
    case None{}: F64.nan()
    case Some{v}: v

def num(+x: S.Sx, +i: Nat) -> F64:
  f_or(S.dec(S.sx_s(S.sx_nth(S.sx_xs(x), i))))

def fin(+x: F64) -> Bool:
  Bool.and(F64.is_eq(x, x), F64.is_lt(F64.abs(x), 1.0e300f64))

def nat_of(+x: F64) -> Nat:
  U64.to_nat(F64.to_u64(F64.max(0.0f64, x)))

def rb_add(+r: RB, +x: S.Sx) -> RB:
  RB{+ok, +why, +ss, +ats, +n, +k} = r
  +a = num(x, 1n)
  +b = num(x, 2n)
  +c = num(x, 3n)
  +d = num(x, 4n)
  +e = num(x, 5n)
  +f = num(x, 6n)
  +sg = Bool.and(Bool.and(Bool.and(fin(a), F64.is_lt(0.0f64, a)), Bool.and(F64.is_lt(c, b), F64.is_le(0.0f64, c))),
    Bool.and(Bool.and(F64.is_lt(0.0f64, d), Bool.and(F64.is_le(0.0f64, e), F64.is_lt(e, 0.5f64))), F64.is_lt(0.0f64, f)))
  +pt3 = Bool.and(Bool.and(fin(a), fin(b)), Bool.and(fin(c), Bool.and(F64.is_le(0.0f64, b), F64.is_le(0.0f64, c))))
  Bool.pick(RB, S.head_is(x, "seg"), RB{Bool.and(ok, sg), why, List.append(&2, SG, ss, [SG{a, b, c, d, e, F64.mul(f, 1.0e-12f64)}]), ats, n, k},
    Bool.pick(RB, S.head_is(x, "disc"), RB{Bool.and(ok, pt3), why, ss, AT{a, PT{0.0f64, 0.0f64, F64.mul(b, 1.0e-3f64), F64.mul(c, 1.0e-3f64)}} <> ats, n, k},
      Bool.pick(RB, S.head_is(x, "brg"), RB{Bool.and(ok, pt3), why, ss, AT{a, PT{b, c, 0.0f64, 0.0f64}} <> ats, n, k},
        Bool.pick(RB, S.head_is(x, "n"), RB{Bool.and(ok, Bool.and(fin(a), F64.is_le(1.0f64, a))), why, ss, ats, nat_of(a), k},
          Bool.pick(RB, S.head_is(x, "modes"), RB{Bool.and(ok, Bool.and(F64.is_le(1.0f64, a), F64.is_le(a, 6.0f64))), why, ss, ats, n, nat_of(a)},
            RB{False{}, why, ss, ats, n, k})))))

def rb_walk(xs: List<&2, S.Sx>, +r: RB) -> RB:
  match xs:
    case []: r
    case +x <> t: rb_walk(t, rb_add(r, x))

def rb_fin(r: RB) -> RB:
  RB{+rok, why, +ss, +ats, +n, +k} = r
  RB{Bool.and(Bool.and(rok, Bool.not(Nat.is_eq(List.length(&2, SG, ss), 0n))), ats_ok(ats, 0.0f64 <> bnds(ss, 0.0f64))), "", ss, ats, n, k}

def rb_ps(p: S.PS) -> RB:
  S.PS{+ok, +xs} = p
  +top = S.sx_nth(xs, 0n)
  rb_fin(rb_walk(S.sx_drop(S.sx_xs(top), 1n), RB{Bool.and(ok, S.head_is(top, "rotor")), "", [], [], 8n, 2n}))

def rb_of(+spec: String) -> RB:
  rb_ps(S.parse(spec))

def f6(+x: F64) -> String:
  F64.show(x)

def ratio(+d1: F64, +d2: F64) -> F64:
  +q = F64.div(d1, d2)
  Bool.pick(F64, Bool.and(F64.is_lt(2.0f64, q), F64.is_eq(q, q)), F64.min(256.0f64, q), 2.0f64)

def line(+i: Nat, +n: Nat, +a: F64, +b: F64, +c: F64) -> String:
  +q = ratio(F64.sub(a, b), F64.sub(b, c))
  +r = F64.add(c, F64.div(F64.sub(c, b), F64.sub(q, 1.0f64)))
  +w = F64.abs(F64.sub(c, b))
  "critical " ++ Nat.show(i) ++ " rpm=[" ++ f6(F64.sub(r, w)) ++ ", " ++ f6(F64.add(r, w)) ++ "] extrapolated=" ++ f6(r) ++
    " ratio=" ++ f6(q) ++ " n" ++ Nat.show(n) ++ "=" ++ f6(a) ++ " n" ++ Nat.show(Nat.mul(2n, n)) ++ "=" ++ f6(b) ++
    " n" ++ Nat.show(Nat.mul(4n, n)) ++ "=" ++ f6(c) ++ " status=estimated method=timoshenko-fe-sturm bound=refinement
"

def lines(as: List<&2, F64>, bs: List<&2, F64>, cs: List<&2, F64>, +n: Nat, +i: Nat) -> String:
  match as:
    case []: ""
    case +a <> at:
      match bs:
        case []: ""
        case +b <> bt:
          match cs:
            case []: ""
            case +c <> ct: line(i, n, a, b, c) ++ lines(at, bt, ct, n, Nat.add(i, 1n))

def rotor_go(r: RB) -> String:
  RB{+ok, why, +ss, +ats, +n, +k} = r
  Bool.pick(String, ok, "rotor elements " ++ Nat.show(Nat.mul(n, List.length(&2, SG, ss))) ++ "/" ++ Nat.show(Nat.mul(Nat.mul(4n, n), List.length(&2, SG, ss))) ++ "
" ++
    lines(speeds(ss, ats, n, k), speeds(ss, ats, Nat.mul(2n, n), k), speeds(ss, ats, Nat.mul(4n, n), k), Nat.mul(n, List.length(&2, SG, ss)), 1n),
    "error invalid-input | rotor | why: needs (rotor (seg L OD ID E NU RHO) ... (disc X M JD) (brg X KW KT) (n N) (modes K)) with discs and bearings at segment ends, OD > ID >= 0, 0 <= NU < 0.5 | fix: correct the spec")

def rotor_s(+spec: String) -> String:
  rotor_go(rb_of(spec))
