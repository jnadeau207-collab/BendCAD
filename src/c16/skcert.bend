import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c06/iv.bend as I
import ../k1/sf.bend as KS


type IB is Data:
  IB{ a: I.I, b: I.I, c: I.I, d: I.I }


type I3 is Data:
  I3{ x: I.I, y: I.I, z: I.I }


type Bx is Data:
  Bx{ lo: V.Point, hi: V.Point }


type Ck is Data:
  Ck{ ok: Bool, a: Nat, b: Nat }

type Pq is Data:
  Pq{ a: G.BezP, b: G.BezP, d: Nat }

def ib(+t: I.I) -> IB:
  +s = I.isub(I.ipt(1.0f64), t)
  IB{I.imul(I.imul(s, s), s), I.iscale(I.imul(I.imul(s, s), t), 3.0f64), I.iscale(I.imul(s, I.imul(t, t)), 3.0f64),
    I.imul(I.imul(t, t), t)}

def ibd(+t: I.I) -> IB:
  +s = I.isub(I.ipt(1.0f64), t)
  IB{I.iscale(I.imul(s, s), F64.neg(3.0f64)), I.iscale(I.isub(I.imul(s, s), I.iscale(I.imul(s, t), 2.0f64)), 3.0f64),
    I.iscale(I.isub(I.iscale(I.imul(s, t), 2.0f64), I.imul(t, t)), 3.0f64), I.iscale(I.imul(t, t), 3.0f64)}

def ip(+p: V.Point) -> I3:
  I3{I.ipt(V.pt_x(p)), I.ipt(V.pt_y(p)), I.ipt(V.pt_z(p))}

def i3_add(+a: I3, +b: I3) -> I3:
  I3{+ax, +ay, +az} = a
  I3{+bx, +by, +bz} = b
  I3{I.iadd(ax, bx), I.iadd(ay, by), I.iadd(az, bz)}

def i3_sc(+s: I.I, +a: I3) -> I3:
  I3{+ax, +ay, +az} = a
  I3{I.imul(s, ax), I.imul(s, ay), I.imul(s, az)}

def icmb(+w: IB, +a: I3, +b: I3, +c: I3, +d: I3) -> I3:
  IB{+wa, +wb, +wc, +wd} = w
  i3_add(i3_add(i3_sc(wa, a), i3_sc(wb, b)), i3_add(i3_sc(wc, c), i3_sc(wd, d)))

def irow(+w: IB, +a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> I3:
  icmb(w, ip(a), ip(b), ip(c), ip(d))

def isum(+p: G.BezP, +wu: IB, +wv: IB) -> I3:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32, +p33} = p
  icmb(wv, irow(wu, p00, p01, p02, p03), irow(wu, p10, p11, p12, p13), irow(wu, p20, p21, p22, p23),
    irow(wu, p30, p31, p32, p33))

def icross(+a: I3, +b: I3) -> I3:
  I3{+ax, +ay, +az} = a
  I3{+bx, +by, +bz} = b
  I3{I.isub(I.imul(ay, bz), I.imul(az, by)), I.isub(I.imul(az, bx), I.imul(ax, bz)), I.isub(I.imul(ax, by), I.imul(ay, bx))}

def idot_d(+a: I3, +d: V.Dir) -> I.I:
  I3{+ax, +ay, +az} = a
  I.iadd(I.iadd(I.imul(ax, I.ipt(V.dr_x(d))), I.imul(ay, I.ipt(V.dr_y(d)))), I.imul(az, I.ipt(V.dr_z(d))))

def inrm(+p: G.BezP, +u: I.I, +v: I.I) -> I3:
  icross(isum(p, ibd(u), ib(v)), isum(p, ib(u), ibd(v)))

def cell(+k: Nat, +n: Nat) -> I.I:
  I.I{F64.div(U64.to_f64(U64.from_nat(k)), U64.to_f64(U64.from_nat(n))), F64.div(U64.to_f64(U64.from_nat(Nat.add(k, 1n))), U64.to_f64(U64.from_nat(n)))}

def cone_v(n: Nat, +p: G.BezP, +ax: V.Dir, +u: I.I, +k: Nat, +m: Nat) -> Bool:
  match n:
    case 0n: True{}
    case 1n+(+j): Bool.and(F64.is_lt(0.0f64, I.i_lo(idot_d(inrm(p, u, cell(k, m)), ax))), cone_v(j, p, ax, u, Nat.add(k, 1n), m))

def cone_u(n: Nat, +p: G.BezP, +ax: V.Dir, +k: Nat, +m: Nat) -> Bool:
  match n:
    case 0n: True{}
    case 1n+(+j): Bool.and(cone_v(m, p, ax, cell(k, m), 0n, m), cone_u(j, p, ax, Nat.add(k, 1n), m))

def ctr_n(+p: G.BezP) -> V.Dir:
  KS.bp_nrm(p, 0.5f64, 0.5f64)

def pts16(+p: G.BezP) -> List<&2, V.Point>:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32, +p33} = p
  [p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23, p30, p31, p32, p33]

def dmax(ps: List<&2, V.Point>, +d: V.Dir, +m: F64) -> F64:
  match ps:
    case []: m
    case +q <> t: dmax(t, d, F64.max(m, KS.dot(d, KS.psub(q, V.Pt{0.0f64, 0.0f64, 0.0f64}))))

def dmin(ps: List<&2, V.Point>, +d: V.Dir, +m: F64) -> F64:
  match ps:
    case []: m
    case +q <> t: dmin(t, d, F64.min(m, KS.dot(d, KS.psub(q, V.Pt{0.0f64, 0.0f64, 0.0f64}))))

def inf() -> F64:
  F64.div(1.0f64, 0.0f64)

def sep_d(+a: List<&2, V.Point>, +b: List<&2, V.Point>, +d: V.Dir, +tol: F64) -> Bool:
  Bool.or(F64.is_lt(F64.add(dmax(a, d, F64.neg(inf())), tol), dmin(b, d, inf())),
    F64.is_lt(F64.add(dmax(b, d, F64.neg(inf())), tol), dmin(a, d, inf())))

def cen(ps: List<&2, V.Point>, +acc: V.Dir, +n: F64) -> V.Point:
  match ps:
    case []: KS.padd(V.Pt{0.0f64, 0.0f64, 0.0f64}, F64.div(1.0f64, F64.max(n, 1.0f64)), acc)
    case +q <> t: cen(t, KS.dadd(acc, 1.0f64, KS.psub(q, V.Pt{0.0f64, 0.0f64, 0.0f64})), F64.add(n, 1.0f64))

def perp(+d: V.Dir, +n: V.Dir) -> V.Dir:
  +q = KS.dadd(d, F64.neg(KS.dot(d, n)), n)
  Bool.pick(V.Dir, F64.is_lt(1.0e-9f64, KS.dlen(q)), KS.dunit(q), d)

def sep_pp(+a: G.BezP, +b: G.BezP, +tol: F64) -> Bool:
  +pa = pts16(a)
  +pb = pts16(b)
  +dc = KS.dunit(KS.psub(cen(pa, V.Dr{0.0f64, 0.0f64, 0.0f64}, 0.0f64), cen(pb, V.Dr{0.0f64, 0.0f64, 0.0f64}, 0.0f64)))
  +na = ctr_n(a)
  +nb = ctr_n(b)
  Bool.or(Bool.or(Bool.or(sep_d(pa, pb, dc, tol), sep_d(pa, pb, perp(dc, na), tol)), Bool.or(sep_d(pa, pb, perp(dc, nb), tol), sep_d(pa, pb, na, tol))),
    Bool.or(Bool.or(sep_d(pa, pb, nb, tol), sep_d(pa, pb, V.Dr{1.0f64, 0.0f64, 0.0f64}, tol)),
      Bool.or(sep_d(pa, pb, V.Dr{0.0f64, 1.0f64, 0.0f64}, tol), sep_d(pa, pb, V.Dr{0.0f64, 0.0f64, 1.0f64}, tol))))

def mid(+a: V.Point, +b: V.Point) -> V.Point:
  KS.padd(a, 0.5f64, KS.psub(b, a))

def half_l(+a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> G.Bez3:
  +ab = mid(a, b)
  +bc = mid(b, c)
  +cd = mid(c, d)
  +abc = mid(ab, bc)
  +bcd = mid(bc, cd)
  G.Bz{a, ab, abc, mid(abc, bcd)}

def half_r(+a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> G.Bez3:
  +ab = mid(a, b)
  +bc = mid(b, c)
  +cd = mid(c, d)
  +abc = mid(ab, bc)
  +bcd = mid(bc, cd)
  G.Bz{mid(abc, bcd), bcd, cd, d}

def bz0(+z: G.Bez3) -> V.Point:
  G.Bz{+a, b, c, d} = z
  a

def bz1(+z: G.Bez3) -> V.Point:
  G.Bz{a, +b, c, d} = z
  b

def bz2(+z: G.Bez3) -> V.Point:
  G.Bz{a, b, +c, d} = z
  c

def bz3(+z: G.Bez3) -> V.Point:
  G.Bz{a, b, c, +d} = z
  d

def rows4(+r0: G.Bez3, +r1: G.Bez3, +r2: G.Bez3, +r3: G.Bez3) -> G.BezP:
  G.Bp{bz0(r0), bz1(r0), bz2(r0), bz3(r0), bz0(r1), bz1(r1), bz2(r1), bz3(r1),
    bz0(r2), bz1(r2), bz2(r2), bz3(r2), bz0(r3), bz1(r3), bz2(r3), bz3(r3)}

def split_u(+p: G.BezP, +left: Bool) -> G.BezP:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32, +p33} = p
  Bool.pick(G.BezP, left,
    rows4(half_l(p00, p01, p02, p03), half_l(p10, p11, p12, p13), half_l(p20, p21, p22, p23), half_l(p30, p31, p32, p33)),
    rows4(half_r(p00, p01, p02, p03), half_r(p10, p11, p12, p13), half_r(p20, p21, p22, p23), half_r(p30, p31, p32, p33)))

def tr(+p: G.BezP) -> G.BezP:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32, +p33} = p
  G.Bp{p00, p10, p20, p30, p01, p11, p21, p31, p02, p12, p22, p32, p03, p13, p23, p33}

def ulen(+p: G.BezP) -> F64:
  G.Bp{+p00, p01, p02, +p03, p10, p11, p12, p13, p20, p21, p22, p23, +p30, p31, p32, +p33} = p
  F64.add(KS.dist(p00, p03), KS.dist(p30, p33))

def vlen(+p: G.BezP) -> F64:
  G.Bp{+p00, p01, p02, +p03, p10, p11, p12, p13, p20, p21, p22, p23, +p30, p31, p32, +p33} = p
  F64.add(KS.dist(p00, p30), KS.dist(p03, p33))

def halves(+p: G.BezP) -> List<&2, G.BezP>:
  Bool.pick(List<&2, G.BezP>, F64.is_le(vlen(p), ulen(p)), [split_u(p, True{}), split_u(p, False{})],
    [tr(split_u(tr(p), True{})), tr(split_u(tr(p), False{}))])

def quads(+p: G.BezP) -> List<&2, G.BezP>:
  +l = split_u(p, True{})
  +r = split_u(p, False{})
  [tr(split_u(tr(l), True{})), tr(split_u(tr(l), False{})), tr(split_u(tr(r), True{})), tr(split_u(tr(r), False{}))]

def pq_row(ys: List<&2, G.BezP>, +x: G.BezP, +d: Nat, +acc: List<&2, Pq>) -> List<&2, Pq>:
  match ys:
    case []: acc
    case +y <> t: pq_row(t, x, d, Pq{x, y, d} <> acc)

def pq_cross(xs: List<&2, G.BezP>, +ys: List<&2, G.BezP>, +d: Nat, +acc: List<&2, Pq>) -> List<&2, Pq>:
  match xs:
    case []: acc
    case +x <> t: pq_cross(t, ys, d, pq_row(ys, x, d, acc))

def wl_step(+q: Pq, +tol: F64, +rest: List<&2, Pq>) -> List<&2, Pq>:
  Pq{+a, +b, +d} = q
  Bool.pick(List<&2, Pq>, sep_pp(a, b, tol), rest, pq_cross(halves(a), halves(b), Nat.sub(d, 1n), rest))

def wl_bad(+q: Pq, +tol: F64) -> Bool:
  Pq{+a, +b, +d} = q
  Bool.and(Nat.is_eq(d, 0n), Bool.not(sep_pp(a, b, tol)))

def wl_go(bad: Bool, +q: Pq, +tol: F64, +t: List<&2, Pq>) -> List<&2, Pq>:
  match bad:
    case True{}: []
    case False{}: wl_step(q, tol, t)

def sep_wl(n: Nat, +ws: List<&2, Pq>, +tol: F64) -> Bool:
  match n:
    case 0n: False{}
    case 1n+(+m):
      match ws:
        case []: True{}
        case +q <> t: Bool.and(Bool.not(wl_bad(q, tol)), sep_wl(m, wl_go(wl_bad(q, tol), q, tol, t), tol))

def sep_rec(+a: G.BezP, +b: G.BezP, +depth: Nat, +tol: F64) -> Bool:
  sep_wl(4000n, [Pq{a, b, depth}], tol)

def dsub(+a: V.Point, +b: V.Point) -> V.Dir:
  KS.dscale(3.0f64, KS.psub(a, b))

def du_vecs(+p: G.BezP) -> List<&2, V.Dir>:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32, +p33} = p
  [dsub(p01, p00), dsub(p02, p01), dsub(p03, p02), dsub(p11, p10), dsub(p12, p11), dsub(p13, p12),
    dsub(p21, p20), dsub(p22, p21), dsub(p23, p22), dsub(p31, p30), dsub(p32, p31), dsub(p33, p32)]

def dv_vecs(+p: G.BezP) -> List<&2, V.Dir>:
  du_vecs(tr(p))

def cmin_b(bs: List<&2, V.Dir>, +a: V.Dir, +ax: V.Dir, +m: F64) -> F64:
  match bs:
    case []: m
    case +b <> t: cmin_b(t, a, ax, F64.min(m, KS.dot(KS.cross(a, b), ax)))

def cmin(xs: List<&2, V.Dir>, +bs: List<&2, V.Dir>, +ax: V.Dir, +m: F64) -> F64:
  match xs:
    case []: m
    case +a <> t: cmin(t, bs, ax, cmin_b(bs, a, ax, m))

def mag2(xs: List<&2, V.Dir>, +m: F64) -> F64:
  match xs:
    case []: m
    case +a <> t: mag2(t, F64.max(m, KS.dlen(a)))

def cone1(+p: G.BezP, +ax: V.Dir) -> Bool:
  +a = du_vecs(p)
  +b = dv_vecs(p)
  +eps = F64.mul(1.0e-12f64, F64.mul(mag2(a, 0.0f64), mag2(b, 0.0f64)))
  F64.is_lt(eps, cmin(a, b, ax, inf()))

def cone_kids(xs: List<&2, G.BezP>, +d: Nat, +acc: List<&2, Pq>) -> List<&2, Pq>:
  match xs:
    case []: acc
    case +x <> t: cone_kids(t, d, Pq{x, x, d} <> acc)

def cone_good(+q: Pq, +ax: V.Dir) -> Bool:
  Pq{+a, b, +d} = q
  Bool.or(cone1(a, ax), Nat.is_lt(0n, d))

def cone_next(+q: Pq, +ax: V.Dir, +t: List<&2, Pq>) -> List<&2, Pq>:
  Pq{+a, b, +d} = q
  Bool.pick(List<&2, Pq>, cone1(a, ax), t, cone_kids(quads(a), Nat.sub(d, 1n), t))

def cone_wl(n: Nat, +ws: List<&2, Pq>, +ax: V.Dir) -> Bool:
  match n:
    case 0n: False{}
    case 1n+(+m):
      match ws:
        case []: True{}
        case +q <> t: Bool.and(cone_good(q, ax), cone_wl(m, cone_next(q, ax, t), ax))

def cone_ok(+p: G.BezP, +ax: V.Dir) -> Bool:
  cone_wl(400n, [Pq{p, p, 3n}], ax)
