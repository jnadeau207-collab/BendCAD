import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/bsp.bend as Q
import ../c04/types.bend as Ty
import ../c06/build.bend as BD
import ../c06/iv.bend as I
import ../c09/feat.bend as F9
import ../k1/sf.bend as KS
import ./skcert.bend as SC








type Fr is Data:
  Fr{ o: V.Point, u: V.Dir, v: V.Dir, s: F64 }








type Sc is Data:
  Sc{ r2: List<&2, List<&2, V.Vec2>>, fr: Fr }








type Gr is Data:
  Gr{ pg: List<&2, List<&2, G.BezP>>, nu: Nat, nb: Nat }








type SkR is Data:
  SkR{ bt: BD.Bt, vol: I.I, ck: SC.Ck, ar: I.I }








type Vq is Data:
  Vq{ v: F64, a: F64 }

def pt(+x: F64, +y: F64, +z: F64) -> V.Point:
  V.Pt{x, y, z}

def nf(+n: Nat) -> F64:
  Q.nf(n)

def fr_o(+f: Fr) -> V.Point:
  Fr{+o, u, v, s} = f
  o

def fr_u(+f: Fr) -> V.Dir:
  Fr{o, +u, v, s} = f
  KS.dunit(u)

def fr_v(+f: Fr) -> V.Dir:
  Fr{o, +u, +v, s} = f
  +e1 = KS.dunit(u)
  KS.dunit(KS.dadd(v, F64.neg(KS.dot(v, e1)), e1))

def fr_s(+f: Fr) -> F64:
  Fr{o, u, v, +s} = f
  s

def fr_n(+f: Fr) -> V.Dir:
  KS.cross(fr_u(f), fr_v(f))

def place(+f: Fr, +q: V.Vec2) -> V.Point:
  KS.padd(KS.padd(fr_o(f), F64.mul(fr_s(f), V.v2_x(q)), fr_u(f)), F64.mul(fr_s(f), V.v2_y(q)), fr_v(f))

def place_run(+f: Fr, qs: List<&2, V.Vec2>) -> List<&2, V.Point>:
  match qs:
    case []: []
    case +q <> t: place(f, q) <> place_run(f, t)

def place_runs(+f: Fr, rs: List<&2, List<&2, V.Vec2>>) -> List<&2, List<&2, V.Point>>:
  match rs:
    case []: []
    case +r <> t: place_run(f, r) <> place_runs(f, t)

def yt_of(+t: F64, +x: F64) -> F64:
  +p = F64.add(F64.mul(0.2969f64, F64.sqrt(x)), F64.mul(x, F64.add(F64.neg(0.126f64), F64.mul(x, F64.add(F64.neg(0.3516f64),
    F64.mul(x, F64.add(0.2843f64, F64.mul(x, F64.neg(0.1015f64)))))))))
  F64.mul(F64.mul(5.0f64, t), p)

def yc_of(+m: F64, +p: F64, +x: F64) -> Vq:
  +fore = F64.is_lt(x, p)
  +d = Bool.pick(F64, fore, F64.mul(p, p), F64.mul(F64.sub(1.0f64, p), F64.sub(1.0f64, p)))
  +k = F64.div(m, Bool.pick(F64, F64.is_lt(0.0f64, d), d, 1.0f64))
  +yf = F64.mul(k, F64.sub(F64.mul(F64.mul(2.0f64, p), x), F64.mul(x, x)))
  +ya = F64.mul(k, F64.add(F64.sub(1.0f64, F64.mul(2.0f64, p)), F64.sub(F64.mul(F64.mul(2.0f64, p), x), F64.mul(x, x))))
  +dy = F64.mul(F64.mul(2.0f64, k), F64.sub(p, x))
  +on = Bool.and(F64.is_lt(0.0f64, m), F64.is_lt(0.0f64, p))
  Vq{Bool.pick(F64, on, Bool.pick(F64, fore, yf, ya), 0.0f64), Bool.pick(F64, on, dy, 0.0f64)}

def vq_v(+q: Vq) -> F64:
  Vq{+v, a} = q
  v

def vq_a(+q: Vq) -> F64:
  Vq{v, +a} = q
  a

def naca_pt(+m: F64, +p: F64, +t: F64, +c: F64, +x: F64, +up: Bool) -> V.Vec2:
  +yt = yt_of(t, x)
  +q = yc_of(m, p, x)
  +r = F64.sqrt(F64.add(1.0f64, F64.mul(vq_a(q), vq_a(q))))
  +sn = F64.div(vq_a(q), r)
  +cs = F64.div(1.0f64, r)
  +sg = Bool.pick(F64, up, 1.0f64, F64.neg(1.0f64))
  V.V2{F64.mul(c, F64.sub(x, F64.mul(sg, F64.mul(yt, sn)))), F64.mul(c, F64.add(vq_v(q), F64.mul(sg, F64.mul(yt, cs))))}

def xcos(+i: Nat, +k: Nat) -> F64:
  F64.mul(0.5f64, F64.sub(1.0f64, KS.fcos(F64.mul(KS.pi(), F64.div(nf(i), nf(k))))))

def upper_go(n: Nat, +m: F64, +p: F64, +t: F64, +c: F64, +k: Nat) -> List<&2, V.Vec2>:
  match n:
    case 0n: [naca_pt(m, p, t, c, 0.0f64, True{})]
    case 1n+(+j): naca_pt(m, p, t, c, xcos(n, k), True{}) <> upper_go(j, m, p, t, c, k)

def lower_go(n: Nat, +m: F64, +p: F64, +t: F64, +c: F64, +k: Nat, +i: Nat) -> List<&2, V.Vec2>:
  match n:
    case 0n: []
    case 1n+(+j): naca_pt(m, p, t, c, xcos(i, k), False{}) <> lower_go(j, m, p, t, c, k, Nat.add(i, 1n))

def naca_runs(+mm: U64, +pp: U64, +tt: U64, +c: F64, +k: Nat) -> List<&2, List<&2, V.Vec2>>:
  +m = F64.div(U64.to_f64(mm), 100.0f64)
  +p = F64.div(U64.to_f64(pp), 10.0f64)
  +t = F64.div(U64.to_f64(tt), 100.0f64)
  +up = upper_go(k, m, p, t, c, k)
  +lo = lower_go(k, m, p, t, c, k, 1n)
  +teu = naca_pt(m, p, t, c, 1.0f64, True{})
  +tel = naca_pt(m, p, t, c, 1.0f64, False{})
  [List.append(&2, V.Vec2, up, lo), [tel, teu]]

def cat_pts(rs: List<&2, List<&2, V.Point>>) -> List<&2, V.Point>:
  match rs:
    case []: []
    case +r <> t: List.append(&2, V.Point, r, cat_pts(t))

def sum_pts(ps: List<&2, V.Point>, +acc: V.Dir, +n: Nat) -> V.Point:
  match ps:
    case []: KS.padd(pt(0.0f64, 0.0f64, 0.0f64), F64.div(1.0f64, Bool.pick(F64, Nat.is_eq(n, 0n), 1.0f64, nf(n))), acc)
    case +p <> t: sum_pts(t, KS.dadd(acc, 1.0f64, KS.psub(p, pt(0.0f64, 0.0f64, 0.0f64))), Nat.add(n, 1n))

def sc_runs(+c: Sc) -> List<&2, List<&2, V.Point>>:
  Sc{+rs, +f} = c
  place_runs(f, rs)

def centroid(+c: Sc) -> V.Point:
  sum_pts(cat_pts(sc_runs(c)), V.Dr{0.0f64, 0.0f64, 0.0f64}, 0n)

def area_go(ps: List<&2, V.Point>, +o: V.Point, +n: V.Dir, +prev: V.Point, +acc: F64) -> F64:
  match ps:
    case []: acc
    case +p <> t: area_go(t, o, n, p, F64.add(acc, KS.dot(n, KS.cross(KS.psub(prev, o), KS.psub(p, o)))))

def lastp(ps: List<&2, V.Point>, +d: V.Point) -> V.Point:
  match ps:
    case []: d
    case +h <> t: lastp(t, h)

def loop_area(+c: Sc, +n: V.Dir) -> F64:
  +ps = cat_pts(sc_runs(c))
  +o = centroid(c)
  area_go(ps, o, n, lastp(ps, o), 0.0f64)

def rev_pts(ps: List<&2, V.Point>) -> List<&2, V.Point>:
  List.reverse(&2, V.Point, ps)

def rev_runs(rs: List<&2, List<&2, V.Point>>, +acc: List<&2, List<&2, V.Point>>) -> List<&2, List<&2, V.Point>>:
  match rs:
    case []: acc
    case +r <> t: rev_runs(t, rev_pts(r) <> acc)

def rev2_runs(rs: List<&2, List<&2, V.Vec2>>, +acc: List<&2, List<&2, V.Vec2>>) -> List<&2, List<&2, V.Vec2>>:
  match rs:
    case []: acc
    case +r <> t: rev2_runs(t, List.reverse(&2, V.Vec2, r) <> acc)

def sc_rev(+c: Sc) -> Sc:
  Sc{+rs, +f} = c
  Sc{rev2_runs(rs, []), f}

def scs_rev(cs: List<&2, Sc>) -> List<&2, Sc>:
  match cs:
    case []: []
    case +c <> t: sc_rev(c) <> scs_rev(t)

def sc_first(cs: List<&2, Sc>) -> Sc:
  match cs:
    case []: Sc{[], Fr{pt(0.0f64, 0.0f64, 0.0f64), V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}, 1.0f64}}
    case +h <> t: h

def sc_last(cs: List<&2, Sc>, +d: Sc) -> Sc:
  match cs:
    case []: d
    case +h <> t: sc_last(t, h)

def sk_dir(+cs: List<&2, Sc>) -> V.Dir:
  +a = sc_first(cs)
  KS.psub(centroid(sc_last(cs, a)), centroid(a))

def sc_tl(cs: List<&2, Sc>) -> List<&2, Sc>:
  match cs:
    case []: []
    case +h <> t: t

def sc_pen(cs: List<&2, Sc>, +p: Sc, +q: Sc) -> Sc:
  match cs:
    case []: p
    case +h <> t: sc_pen(t, q, h)

def sk_d0(+cs: List<&2, Sc>) -> V.Dir:
  +a = sc_first(cs)
  KS.psub(centroid(sc_first(sc_tl(cs))), centroid(a))

def sk_d1(+cs: List<&2, Sc>) -> V.Dir:
  +a = sc_first(cs)
  +z = sc_last(cs, a)
  KS.psub(centroid(z), centroid(sc_pen(sc_tl(cs), a, a)))

def orient(+cs: List<&2, Sc>) -> List<&2, Sc>:
  +d = sk_d0(cs)
  +s = loop_area(sc_first(cs), KS.dunit(d))
  Bool.pick(List<&2, Sc>, F64.is_lt(s, 0.0f64), scs_rev(cs), cs)

def sc_fr(+c: Sc) -> Fr:
  Sc{rs, +f} = c
  f

def run_at(rs: List<&2, List<&2, V.Point>>, +r: Nat) -> List<&2, V.Point>:
  match rs:
    case []: []
    case +h <> t:
      match r:
        case 0n: h
        case 1n+j: run_at(t, j)

def runs_r(cs: List<&2, Sc>, +r: Nat) -> List<&2, List<&2, V.Point>>:
  match cs:
    case []: []
    case +c <> t: run_at(sc_runs(c), r) <> runs_r(t, r)

def avg_params(ps: List<&2, List<&2, V.Point>>, +acc: List<&2, F64>, +n: Nat) -> List<&2, F64>:
  match ps:
    case []: Q.fscale(acc, F64.div(1.0f64, Bool.pick(F64, Nat.is_eq(n, 0n), 1.0f64, nf(n))))
    case +p <> t: avg_params(t, Bool.pick(List<&2, F64>, Nat.is_eq(n, 0n), Q.params(p), Q.fadd(acc, Q.params(p))), Nat.add(n, 1n))

def set_ends(+cs: List<&2, Q.H4>, +a: Q.H4, +b: Q.H4) -> List<&2, Q.H4>:
  +n = List.length(&2, Q.H4, cs)
  List.append(&2, Q.H4, a <> Q.take_h(Nat.sub(n, 2n), Q.drop_h(1n, cs)), [b])

def first_p(ps: List<&2, V.Point>) -> V.Point:
  match ps:
    case []: pt(0.0f64, 0.0f64, 0.0f64)
    case +h <> t: h

def ictl(+p: Nat, +us: List<&2, F64>, +ks: List<&2, F64>, +ps: List<&2, V.Point>) -> List<&2, Q.H4>:
  set_ends(Q.bs_cs(Q.interp_k(p, us, ks, Q.pts_hs(ps))), Q.h_of(first_p(ps)), Q.h_of(lastp(ps, first_p(ps))))

def ictls(+p: Nat, +us: List<&2, F64>, +ks: List<&2, F64>, pss: List<&2, List<&2, V.Point>>) -> List<&2, List<&2, Q.H4>>:
  match pss:
    case []: []
    case +ps <> t: ictl(p, us, ks, ps) <> ictls(p, us, ks, t)

def col_of(rows: List<&2, List<&2, Q.H4>>, +i: Nat) -> List<&2, Q.H4>:
  match rows:
    case []: []
    case +r <> t: Q.hnth(r, i) <> col_of(t, i)

def cols_go(n: Nat, +rows: List<&2, List<&2, Q.H4>>, +i: Nat) -> List<&2, List<&2, Q.H4>>:
  match n:
    case 0n: []
    case 1n+(+m): col_of(rows, i) <> cols_go(m, rows, Nat.add(i, 1n))

def first_hs(xs: List<&2, List<&2, Q.H4>>) -> List<&2, Q.H4>:
  match xs:
    case []: []
    case +h <> t: h

def transpose(+rows: List<&2, List<&2, Q.H4>>) -> List<&2, List<&2, Q.H4>>:
  cols_go(List.length(&2, Q.H4, first_hs(rows)), rows, 0n)

def vfix(+pv: Nat, +vs: List<&2, F64>, +vk: List<&2, F64>, +col: List<&2, Q.H4>) -> List<&2, Q.H4>:
  +n = List.length(&2, Q.H4, col)
  set_ends(Q.bs_cs(Q.interp_k(pv, vs, vk, col)), Q.hnth(col, 0n), Q.hnth(col, Nat.sub(n, 1n)))

def vfixs(+pv: Nat, +vs: List<&2, F64>, +vk: List<&2, F64>, cols: List<&2, List<&2, Q.H4>>) -> List<&2, List<&2, Q.H4>>:
  match cols:
    case []: []
    case +c <> t: vfix(pv, vs, vk, c) <> vfixs(pv, vs, vk, t)

def snap_go(ss: List<&2, List<&2, Q.H4>>, +prev: Q.H4) -> List<&2, List<&2, Q.H4>>:
  match ss:
    case []: []
    case +s <> t:
      +n = {prev <> Q.drop_h(1n, s) : List<&2, Q.H4>}
      n <> snap_go(t, Q.hnth(s, 3n))

def snap(ss: List<&2, List<&2, Q.H4>>) -> List<&2, List<&2, Q.H4>>:
  match ss:
    case []: []
    case +s <> t: s <> snap_go(t, Q.hnth(s, 3n))

def pin_last(ss: List<&2, List<&2, Q.H4>>, +b: Q.H4) -> List<&2, List<&2, Q.H4>>:
  match ss:
    case []: []
    case +s <> +t:
      Bool.pick(List<&2, List<&2, Q.H4>>, Nat.is_eq(List.length(&2, List<&2, Q.H4>, t), 0n),
        [List.append(&2, Q.H4, Q.take_h(3n, s), [b])], s <> pin_last(t, b))

def pin(ss: List<&2, List<&2, Q.H4>>, +a: Q.H4, +b: Q.H4) -> List<&2, List<&2, Q.H4>>:
  match ss:
    case []: []
    case +s <> +t: pin_last((a <> Q.drop_h(1n, s)) <> t, b)

def pin_row(+ss: List<&2, List<&2, Q.H4>>, +r: List<&2, Q.H4>) -> List<&2, List<&2, Q.H4>>:
  pin(ss, Q.hnth(r, 0n), Q.hnth(r, Nat.sub(List.length(&2, Q.H4, r), 1n)))

def useg(+pu: Nat, +uk: List<&2, F64>, rows: List<&2, List<&2, Q.H4>>) -> List<&2, List<&2, List<&2, Q.H4>>>:
  match rows:
    case []: []
    case +r <> t: pin_row(snap(Q.bezs(Q.Bs{pu, uk, r})), r) <> useg(pu, uk, t)

def seg_at(ss: List<&2, List<&2, Q.H4>>, +a: Nat) -> List<&2, Q.H4>:
  match ss:
    case []: []
    case +h <> t:
      match a:
        case 0n: h
        case 1n+j: seg_at(t, j)

def grid_a(rs: List<&2, List<&2, List<&2, Q.H4>>>, +a: Nat) -> List<&2, List<&2, Q.H4>>:
  match rs:
    case []: []
    case +r <> t: seg_at(r, a) <> grid_a(t, a)

def h16(+r0: List<&2, Q.H4>, +r1: List<&2, Q.H4>, +r2: List<&2, Q.H4>, +r3: List<&2, Q.H4>) -> G.BezP:
  G.Bp{Q.h_pt(Q.hnth(r0, 0n)), Q.h_pt(Q.hnth(r0, 1n)), Q.h_pt(Q.hnth(r0, 2n)), Q.h_pt(Q.hnth(r0, 3n)),
    Q.h_pt(Q.hnth(r1, 0n)), Q.h_pt(Q.hnth(r1, 1n)), Q.h_pt(Q.hnth(r1, 2n)), Q.h_pt(Q.hnth(r1, 3n)),
    Q.h_pt(Q.hnth(r2, 0n)), Q.h_pt(Q.hnth(r2, 1n)), Q.h_pt(Q.hnth(r2, 2n)), Q.h_pt(Q.hnth(r2, 3n)),
    Q.h_pt(Q.hnth(r3, 0n)), Q.h_pt(Q.hnth(r3, 1n)), Q.h_pt(Q.hnth(r3, 2n)), Q.h_pt(Q.hnth(r3, 3n))}

def k_row(cs: List<&2, List<&2, List<&2, Q.H4>>>, +b: Nat, +k: Nat) -> List<&2, Q.H4>:
  match cs:
    case []: []
    case +c <> t: Q.hnth(seg_at(c, b), k) <> k_row(t, b, k)

def patch_b(+vc: List<&2, List<&2, List<&2, Q.H4>>>, +b: Nat) -> G.BezP:
  h16(k_row(vc, b, 0n), k_row(vc, b, 1n), k_row(vc, b, 2n), k_row(vc, b, 3n))

def patches_b(n: Nat, +vc: List<&2, List<&2, List<&2, Q.H4>>>, +b: Nat) -> List<&2, G.BezP>:
  match n:
    case 0n: []
    case 1n+(+m): patch_b(vc, b) <> patches_b(m, vc, Nat.add(b, 1n))

def vcols(+pv: Nat, +vk: List<&2, F64>, +g: List<&2, List<&2, Q.H4>>, +c: Nat) -> List<&2, List<&2, Q.H4>>:
  +cl = col_of(g, c)
  pin_row(snap(Q.bezs(Q.Bs{pv, vk, cl})), cl)

def col_a(+pv: Nat, +vk: List<&2, F64>, +nb: Nat, +g: List<&2, List<&2, Q.H4>>) -> List<&2, G.BezP>:
  patches_b(nb, [vcols(pv, vk, g, 0n), vcols(pv, vk, g, 1n), vcols(pv, vk, g, 2n), vcols(pv, vk, g, 3n)], 0n)

def run_cols(n: Nat, +pv: Nat, +vk: List<&2, F64>, +nb: Nat, +rs: List<&2, List<&2, List<&2, Q.H4>>>, +a: Nat) -> List<&2, List<&2, G.BezP>>:
  match n:
    case 0n: []
    case 1n+(+m): col_a(pv, vk, nb, grid_a(rs, a)) <> run_cols(m, pv, vk, nb, rs, Nat.add(a, 1n))

def first_seg(xs: List<&2, List<&2, List<&2, Q.H4>>>) -> List<&2, List<&2, Q.H4>>:
  match xs:
    case []: []
    case +h <> t: h

def first2(ps: List<&2, V.Vec2>) -> V.Vec2:
  match ps:
    case []: V.V2{0.0f64, 0.0f64}
    case +h <> t: h

def h2(+q: V.Vec2) -> Q.H4:
  Q.H4{V.v2_x(q), V.v2_y(q), 0.0f64, 1.0f64}

def h2s(qs: List<&2, V.Vec2>) -> List<&2, Q.H4>:
  match qs:
    case []: []
    case +q <> t: h2(q) <> h2s(t)

def last2(qs: List<&2, V.Vec2>, +d: V.Vec2) -> V.Vec2:
  match qs:
    case []: d
    case +h <> t: last2(t, h)

def place_h(+f: Fr, hs: List<&2, Q.H4>) -> List<&2, Q.H4>:
  match hs:
    case []: []
    case +h <> t: Q.h_of(place(f, V.V2{Q.hx(h), Q.hy(h)})) <> place_h(f, t)

def ictl2(+p: Nat, +us: List<&2, F64>, +ks: List<&2, F64>, +qs: List<&2, V.Vec2>, +f: Fr) -> List<&2, Q.H4>:
  +c = set_ends(Q.bs_cs(Q.interp_k(p, us, ks, h2s(qs))), h2(first2(qs)), h2(last2(qs, first2(qs))))
  place_h(f, c)

def run2_at(rs: List<&2, List<&2, V.Vec2>>, +r: Nat) -> List<&2, V.Vec2>:
  match rs:
    case []: []
    case +h <> t:
      match r:
        case 0n: h
        case 1n+j: run2_at(t, j)

def ictl2s(+p: Nat, +us: List<&2, F64>, +ks: List<&2, F64>, cs: List<&2, Sc>, +r: Nat) -> List<&2, List<&2, Q.H4>>:
  match cs:
    case []: []
    case +c <> t:
      Sc{+rs, +f} = c
      ictl2(p, us, ks, run2_at(rs, r), f) <> ictl2s(p, us, ks, t, r)

def run_grid(+cs: List<&2, Sc>, +r: Nat, +pv: Nat, +vs: List<&2, F64>, +vk: List<&2, F64>, +nb: Nat) -> List<&2, List<&2, G.BezP>>:
  +pss = runs_r(cs, r)
  +us = avg_params(pss, [], 0n)
  +pu = Q.deg_for(List.length(&2, F64, us))
  +uk = Q.knots_avg(us, pu)
  +rows = transpose(vfixs(pv, vs, vk, transpose(ictl2s(pu, us, uk, cs, r))))
  +segs = useg(pu, uk, rows)
  run_cols(List.length(&2, List<&2, Q.H4>, first_seg(segs)), pv, vk, nb, segs, 0n)

def runs_grid(n: Nat, +cs: List<&2, Sc>, +r: Nat, +pv: Nat, +vs: List<&2, F64>, +vk: List<&2, F64>, +nb: Nat) -> List<&2, List<&2, G.BezP>>:
  match n:
    case 0n: []
    case 1n+(+m): List.append(&2, List<&2, G.BezP>, run_grid(cs, r, pv, vs, vk, nb), runs_grid(m, cs, Nat.add(r, 1n), pv, vs, vk, nb))

def vdist_go(xa: List<&2, V.Point>, bs: List<&2, V.Point>, +acc: F64) -> F64:
  match xa:
    case []: acc
    case +a <> at:
      match bs:
        case []: acc
        case +b <> bt: vdist_go(at, bt, F64.add(acc, F64.sqrt(Q.pdist(a, b))))

def vcum(cs: List<&2, Sc>, +prev: List<&2, V.Point>, +acc: F64) -> List<&2, F64>:
  match cs:
    case []: []
    case +c <> t:
      +ps = cat_pts(sc_runs(c))
      +a = F64.add(acc, vdist_go(prev, ps, 0.0f64))
      a <> vcum(t, ps, a)

def vparams(+cs: List<&2, Sc>) -> List<&2, F64>:
  +p0 = cat_pts(sc_runs(sc_first(cs)))
  +c = vcum(cs, p0, 0.0f64)
  Q.fscale(c, F64.div(1.0f64, Q.lastf(c, 1.0f64)))

def nruns(+cs: List<&2, Sc>) -> Nat:
  List.length(&2, List<&2, V.Point>, sc_runs(sc_first(cs)))

def grid(+cs: List<&2, Sc>) -> Gr:
  +vs = vparams(cs)
  +s = List.length(&2, Sc, cs)
  +pv = Q.deg_for(s)
  +vk = Q.knots_avg(vs, pv)
  +nb = Nat.sub(s, pv)
  +pg = runs_grid(nruns(cs), cs, 0n, pv, vs, vk, nb)
  Gr{pg, List.length(&2, List<&2, G.BezP>, pg), nb}

def gr_pg(+g: Gr) -> List<&2, List<&2, G.BezP>>:
  Gr{+pg, nu, nb} = g
  pg

def gr_nu(+g: Gr) -> Nat:
  Gr{pg, +nu, nb} = g
  nu

def gr_nb(+g: Gr) -> Nat:
  Gr{pg, nu, +nb} = g
  nb

def bp_zero() -> G.BezP:
  +z = pt(0.0f64, 0.0f64, 0.0f64)
  G.Bp{z, z, z, z, z, z, z, z, z, z, z, z, z, z, z, z}

def bnth(xs: List<&2, G.BezP>, +i: Nat) -> G.BezP:
  match xs:
    case []: bp_zero()
    case +h <> t:
      match i:
        case 0n: h
        case 1n+j: bnth(t, j)

def gnth(xs: List<&2, List<&2, G.BezP>>, +i: Nat) -> List<&2, G.BezP>:
  match xs:
    case []: []
    case +h <> t:
      match i:
        case 0n: h
        case 1n+j: gnth(t, j)

def pat(+g: Gr, +u: Nat, +b: Nat) -> G.BezP:
  bnth(gnth(gr_pg(g), u), b)

def bp_row(+w: G.BezP, +k: Nat) -> G.Bez3:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32, +p33} = w
  Bool.pick(G.Bez3, Nat.is_eq(k, 0n), G.Bz{p00, p01, p02, p03}, G.Bz{p30, p31, p32, p33})

def bp_col(+w: G.BezP) -> G.Bez3:
  G.Bp{+p00, p01, p02, p03, +p10, p11, p12, p13, +p20, p21, p22, p23, +p30, p31, p32, p33} = w
  G.Bz{p00, p10, p20, p30}

def bz_a(+b: G.Bez3) -> V.Point:
  G.Bz{+a, c, d, e} = b
  a

def vid(+g: Gr, +b: Nat, +u: Nat) -> Nat:
  Nat.add(Nat.mul(b, gr_nu(g)), Nat.mod(u, gr_nu(g)))

def vtx(+g: Gr, +b: Nat, +u0: Nat) -> V.Point:
  +u = Nat.mod(u0, gr_nu(g))
  Bool.pick(V.Point, Nat.is_eq(b, gr_nb(g)), bz_a(bp_row(pat(g, u, Nat.sub(b, 1n)), 3n)), bz_a(bp_row(pat(g, u, b), 0n)))

def vs_go(n: Nat, +g: Gr, +i: Nat) -> List<&2, Ty.Vertex>:
  match n:
    case 0n: []
    case 1n+(+m): Ty.Vx{0u64, vtx(g, Nat.div(i, gr_nu(g)), Nat.mod(i, gr_nu(g)))} <> vs_go(m, g, Nat.add(i, 1n))

def ed_of(+a: Nat, +b: Nat, +c: G.Bez3) -> Ty.Edge:
  Ty.Ed{0u64, BD.hv(a), BD.hv(b), Ty.EK_curve{G.GV_bz{c}, G.Dom{0.0f64, 1.0f64}}}

def ue_curve(+g: Gr, +b: Nat, +u: Nat) -> G.Bez3:
  Bool.pick(G.Bez3, Nat.is_eq(b, gr_nb(g)), bp_row(pat(g, u, Nat.sub(b, 1n)), 3n), bp_row(pat(g, u, b), 0n))

def ues_go(n: Nat, +g: Gr, +i: Nat) -> List<&2, Ty.Edge>:
  match n:
    case 0n: []
    case 1n+(+m):
      +b = Nat.div(i, gr_nu(g))
      +u = Nat.mod(i, gr_nu(g))
      ed_of(vid(g, b, u), vid(g, b, Nat.add(u, 1n)), ue_curve(g, b, u)) <> ues_go(m, g, Nat.add(i, 1n))

def ves_go(n: Nat, +g: Gr, +i: Nat) -> List<&2, Ty.Edge>:
  match n:
    case 0n: []
    case 1n+(+m):
      +b = Nat.div(i, gr_nu(g))
      +u = Nat.mod(i, gr_nu(g))
      ed_of(vid(g, b, u), vid(g, Nat.add(b, 1n), u), bp_col(pat(g, u, b))) <> ves_go(m, g, Nat.add(i, 1n))

def n_ue(+g: Gr) -> Nat:
  Nat.mul(Nat.add(gr_nb(g), 1n), gr_nu(g))

def ue_id(+g: Gr, +b: Nat, +u: Nat) -> Nat:
  Nat.add(Nat.mul(b, gr_nu(g)), Nat.mod(u, gr_nu(g)))

def ve_id(+g: Gr, +b: Nat, +u: Nat) -> Nat:
  Nat.add(n_ue(g), Nat.add(Nat.mul(b, gr_nu(g)), Nat.mod(u, gr_nu(g))))

def v2(+x: F64, +y: F64) -> V.Vec2:
  V.V2{x, y}

def pface(+g: Gr, +u: Nat, +b: Nat, +nd: U64, +fi: Nat) -> BD.FS:
  F9.face1(G.GV_bp{pat(g, u, b)},
    [BD.Us{ue_id(g, b, u), True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)},
      BD.Us{ve_id(g, b, Nat.add(u, 1n)), True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)},
      BD.Us{ue_id(g, Nat.add(b, 1n), u), False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)},
      BD.Us{ve_id(g, b, u), False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64)}], nd, fi)

def pfs_go(n: Nat, +g: Gr, +nd: U64, +i: Nat) -> List<&2, BD.FS>:
  match n:
    case 0n: []
    case 1n+(+m): pface(g, Nat.div(i, gr_nb(g)), Nat.mod(i, gr_nb(g)), nd, i) <> pfs_go(m, g, nd, Nat.add(i, 1n))

def puv(+o: V.Point, +e1: V.Dir, +e2: V.Dir, +p: V.Point) -> V.Vec2:
  +d = KS.psub(p, o)
  v2(KS.dot(d, e1), KS.dot(d, e2))

def cap_use(+g: Gr, +b: Nat, +u: Nat, +fw: Bool, +o: V.Point, +e1: V.Dir, +e2: V.Dir) -> BD.Use:
  BD.Us{ue_id(g, b, u), fw, puv(o, e1, e2, vtx(g, b, u)), puv(o, e1, e2, vtx(g, b, Nat.add(u, 1n)))}

def cap_fw(n: Nat, +g: Gr, +b: Nat, +u: Nat, +o: V.Point, +e1: V.Dir, +e2: V.Dir) -> List<&2, BD.Use>:
  match n:
    case 0n: []
    case 1n+(+m): cap_use(g, b, u, True{}, o, e1, e2) <> cap_fw(m, g, b, Nat.add(u, 1n), o, e1, e2)

def cap_bw(n: Nat, +g: Gr, +b: Nat, +o: V.Point, +e1: V.Dir, +e2: V.Dir) -> List<&2, BD.Use>:
  match n:
    case 0n: []
    case 1n+(+m): cap_use(g, b, m, False{}, o, e1, e2) <> cap_bw(m, g, b, o, e1, e2)

def cap_pl(+f: Fr, +want: V.Dir) -> G.Plane3:
  +e1 = fr_u(f)
  +v = fr_v(f)
  +n = KS.cross(e1, v)
  G.Pl{fr_o(f), e1, Bool.pick(V.Dir, F64.is_lt(0.0f64, KS.dot(n, want)), v, KS.dscale(F64.neg(1.0f64), v))}

def pl_o(+p: G.Plane3) -> V.Point:
  G.Pl{+o, u, v} = p
  o

def pl_u(+p: G.Plane3) -> V.Dir:
  G.Pl{o, +u, v} = p
  u

def pl_v(+p: G.Plane3) -> V.Dir:
  G.Pl{o, u, +v} = p
  v

def caps(+g: Gr, +cs: List<&2, Sc>, +nd: U64, +fi: Nat) -> List<&2, BD.FS>:
  +pb = cap_pl(sc_fr(sc_first(cs)), KS.dscale(F64.neg(1.0f64), sk_d0(cs)))
  +pt_ = cap_pl(sc_fr(sc_last(cs, sc_first(cs))), sk_d1(cs))
  [F9.face1(G.GV_pl{pb}, cap_bw(gr_nu(g), g, 0n, pl_o(pb), pl_u(pb), pl_v(pb)), nd, fi),
    F9.face1(G.GV_pl{pt_}, cap_fw(gr_nu(g), g, gr_nb(g), 0n, pl_o(pt_), pl_u(pt_), pl_v(pt_)), nd, Nat.add(fi, 1n))]

def gl5() -> List<&2, V.Vec2>:
  [V.V2{0.5f64, 0.28444444444444444f64}, V.V2{0.23076534494715845f64, 0.23931433524968324f64},
    V.V2{0.7692346550528415f64, 0.23931433524968324f64}, V.V2{0.04691007703066802f64, 0.11846344252809454f64},
    V.V2{0.953089922969332f64, 0.11846344252809454f64}]

def gv_go(ns: List<&2, V.Vec2>, +w: G.BezP, +u: F64, +wu: F64, +acc: V.Vec2) -> V.Vec2:
  match ns:
    case []: acc
    case +h <> t:
      +v = V.v2_x(h)
      +f = KS.dot(KS.psub(KS.bp_at(w, u, v), pt(0.0f64, 0.0f64, 0.0f64)), KS.cross(KS.bp_su(w, u, v), KS.bp_sv(w, u, v)))
      +k = F64.mul(wu, V.v2_y(h))
      gv_go(t, w, u, wu, V.V2{F64.add(V.v2_x(acc), F64.mul(k, f)), F64.add(V.v2_y(acc), F64.abs(F64.mul(k, f)))})

def gu_go(ns: List<&2, V.Vec2>, +w: G.BezP, +acc: V.Vec2) -> V.Vec2:
  match ns:
    case []: acc
    case +h <> t: gu_go(t, w, gv_go(gl5(), w, V.v2_x(h), V.v2_y(h), acc))

def pvol(ps: List<&2, G.BezP>, +acc: V.Vec2) -> V.Vec2:
  match ps:
    case []: acc
    case +w <> t: pvol(t, gu_go(gl5(), w, acc))

def cat_bps(xs: List<&2, List<&2, G.BezP>>) -> List<&2, G.BezP>:
  match xs:
    case []: []
    case +h <> t: List.append(&2, G.BezP, h, cat_bps(t))

def gl3() -> List<&2, V.Vec2>:
  [V.V2{0.5f64, 0.4444444444444444f64}, V.V2{0.1127016653792583f64, 0.2777777777777778f64},
    V.V2{0.8872983346207417f64, 0.2777777777777778f64}]

def bz_pt(+b: G.Bez3, +t: F64) -> V.Point:
  G.Bz{+a, +c, +d, +e} = b
  +s = F64.sub(1.0f64, t)
  +o = pt(0.0f64, 0.0f64, 0.0f64)
  KS.padd(o, 1.0f64, KS.dadd(KS.dadd(KS.dscale(F64.mul(F64.mul(s, s), s), KS.psub(a, o)), F64.mul(3.0f64, F64.mul(F64.mul(s, s), t)), KS.psub(c, o)),
    1.0f64, KS.dadd(KS.dscale(F64.mul(3.0f64, F64.mul(s, F64.mul(t, t))), KS.psub(d, o)), F64.mul(F64.mul(t, t), t), KS.psub(e, o))))

def bz_d(+b: G.Bez3, +t: F64) -> V.Dir:
  G.Bz{+a, +c, +d, +e} = b
  +s = F64.sub(1.0f64, t)
  KS.dadd(KS.dadd(KS.dscale(F64.mul(3.0f64, F64.mul(s, s)), KS.psub(c, a)), F64.mul(6.0f64, F64.mul(s, t)), KS.psub(d, c)),
    F64.mul(3.0f64, F64.mul(t, t)), KS.psub(e, d))

def seg_area(ns: List<&2, V.Vec2>, +b: G.Bez3, +o: V.Point, +n: V.Dir, +acc: F64) -> F64:
  match ns:
    case []: acc
    case +h <> t:
      +p = bz_pt(b, V.v2_x(h))
      seg_area(t, b, o, n, F64.add(acc, F64.mul(V.v2_y(h), KS.dot(n, KS.cross(KS.psub(p, o), bz_d(b, V.v2_x(h)))))))

def row_area(n: Nat, +g: Gr, +b: Nat, +u: Nat, +o: V.Point, +nn: V.Dir, +acc: F64) -> F64:
  match n:
    case 0n: acc
    case 1n+(+m): row_area(m, g, b, Nat.add(u, 1n), o, nn, seg_area(gl3(), ue_curve(g, b, u), o, nn, acc))

def cap_vol(+g: Gr, +b: Nat, +f: Fr) -> V.Vec2:
  +n = fr_n(f)
  +o = fr_o(f)
  +a = F64.mul(0.5f64, row_area(gr_nu(g), g, b, 0n, o, n, 0.0f64))
  +h = KS.dot(KS.psub(o, pt(0.0f64, 0.0f64, 0.0f64)), n)
  V.V2{F64.mul(h, a), F64.abs(F64.mul(h, a))}

def sk_vol(+g: Gr, +cs: List<&2, Sc>) -> I.I:
  +pv = pvol(cat_bps(gr_pg(g)), V.V2{0.0f64, 0.0f64})
  +cb = cap_vol(g, 0n, sc_fr(sc_first(cs)))
  +ct = cap_vol(g, gr_nb(g), sc_fr(sc_last(cs, sc_first(cs))))
  +v = F64.div(F64.add(V.v2_x(pv), F64.sub(V.v2_x(ct), V.v2_x(cb))), 3.0f64)
  +e = F64.mul(1.0e-12f64, F64.add(F64.add(V.v2_y(pv), V.v2_y(cb)), F64.add(V.v2_y(ct), 1.0f64)))
  I.I{F64.sub(v, e), F64.add(v, e)}

def sk_bt(+g: Gr, +cs: List<&2, Sc>, +nd: U64) -> BD.Bt:
  +np = Nat.mul(gr_nu(g), gr_nb(g))
  F9.pack(vs_go(Nat.mul(Nat.add(gr_nb(g), 1n), gr_nu(g)), g, 0n),
    List.append(&2, Ty.Edge, ues_go(n_ue(g), g, 0n), ves_go(Nat.mul(gr_nb(g), gr_nu(g)), g, 0n)),
    List.append(&2, BD.FS, pfs_go(np, g, nd, 0n), caps(g, cs, nd, np)))

def lens(rs: List<&2, List<&2, V.Point>>) -> List<&2, Nat>:
  match rs:
    case []: []
    case +r <> t: List.length(&2, V.Point, r) <> lens(t)

def nats_eq(xs: List<&2, Nat>, ys: List<&2, Nat>) -> Bool:
  match xs:
    case []:
      match ys:
        case []: True{}
        case _: False{}
    case +x <> xt:
      match ys:
        case []: False{}
        case +y <> yt: Bool.and(Nat.is_eq(x, y), nats_eq(xt, yt))

def all2(xs: List<&2, Nat>) -> Bool:
  match xs:
    case []: True{}
    case +x <> t: Bool.and(Nat.is_le(2n, x), all2(t))

def same_go(cs: List<&2, Sc>, +ls: List<&2, Nat>) -> Bool:
  match cs:
    case []: True{}
    case +c <> t: Bool.and(nats_eq(lens(sc_runs(c)), ls), same_go(t, ls))

def sz_go(ps: List<&2, V.Point>, +m: F64) -> F64:
  match ps:
    case []: m
    case +p <> t: sz_go(t, F64.max(m, F64.max(F64.abs(V.pt_x(p)), F64.max(F64.abs(V.pt_y(p)), F64.abs(V.pt_z(p))))))

def sc_size(+c: Sc) -> F64:
  sz_go(cat_pts(sc_runs(c)), 0.0f64)

def first_or(ps: List<&2, V.Point>, +d: V.Point) -> V.Point:
  match ps:
    case []: d
    case +h <> t: h

def first_run(rs: List<&2, List<&2, V.Point>>) -> List<&2, V.Point>:
  match rs:
    case []: []
    case +h <> t: h

def gap_go(rs: List<&2, List<&2, V.Point>>, +p0: V.Point, +m: F64) -> F64:
  match rs:
    case []: m
    case +r <> +t: gap_go(t, p0, F64.max(m, Q.pdist(lastp(r, p0), first_or(first_run(t), p0))))

def sc_gap(+c: Sc) -> F64:
  +rs = sc_runs(c)
  gap_go(rs, first_or(first_run(rs), pt(0.0f64, 0.0f64, 0.0f64)), 0.0f64)

def scs_gap(cs: List<&2, Sc>, +m: F64) -> F64:
  match cs:
    case []: m
    case +c <> t: scs_gap(t, F64.max(m, sc_gap(c)))

def sk_ok(+cs: List<&2, Sc>) -> Bool:
  +ls = lens(sc_runs(sc_first(cs)))
  Bool.and(Bool.and(Bool.and(Nat.is_le(2n, List.length(&2, Sc, cs)), Nat.is_le(1n, List.length(&2, Nat, ls))),
    Bool.and(all2(ls), same_go(cs, ls))), F64.is_le(scs_gap(cs, 0.0f64), F64.mul(1.0e-9f64, F64.add(1.0f64, sc_size(sc_first(cs))))))

def fas_tol(fs: List<&2, Ty.Face>, +tol: F64) -> List<&2, Ty.Face>:
  match fs:
    case []: []
    case Ty.Fa{g, s, ls, same, slv, sla} <> t: Ty.Fa{g, s, ls, same, tol, sla} <> fas_tol(t, tol)

def br_tol(+b: Ty.Brep, +tol: F64) -> Ty.Brep:
  Ty.Br{Ty.brep_vs(b), Ty.brep_es(b), Ty.brep_ces(b), Ty.brep_lps(b), fas_tol(Ty.brep_fas(b), tol), Ty.brep_shs(b),
    Ty.brep_sos(b), Ty.brep_top(b), Ty.brep_stamp(b)}

def vs_scale(vs: List<&2, Ty.Vertex>, +m: F64) -> F64:
  match vs:
    case []: m
    case +v <> t:
      +p = Ty.vx_p(v)
      vs_scale(t, F64.max(m, F64.max(F64.abs(V.pt_x(p)), F64.max(F64.abs(V.pt_y(p)), F64.abs(V.pt_z(p))))))

def bt_tol(bt: BD.Bt) -> BD.Bt:
  BD.Bt{+b, +fns} = bt
  BD.Bt{br_tol(b, F64.mul(1.0e-9f64, F64.add(1.0f64, vs_scale(Ty.brep_vs(b), 0.0f64)))), fns}

def corners(+p: G.BezP) -> List<&2, V.Point>:
  G.Bp{+p00, p01, p02, +p03, p10, p11, p12, p13, p20, p21, p22, p23, +p30, p31, p32, +p33} = p
  [p00, p03, p30, p33]

def pt_eq(+a: V.Point, +b: V.Point) -> Bool:
  Bool.and(F64.is_eq(V.pt_x(a), V.pt_x(b)), Bool.and(F64.is_eq(V.pt_y(a), V.pt_y(b)), F64.is_eq(V.pt_z(a), V.pt_z(b))))

def any_eq(ys: List<&2, V.Point>, +x: V.Point) -> Bool:
  match ys:
    case []: False{}
    case +y <> t: Bool.or(F64.is_le(Q.pdist(x, y), F64.mul(1.0e-12f64, F64.add(1.0f64, KS.dlen(KS.psub(x, pt(0.0f64, 0.0f64, 0.0f64)))))), any_eq(t, x))

def shared_go(xs: List<&2, V.Point>, +ys: List<&2, V.Point>) -> List<&2, V.Point>:
  match xs:
    case []: []
    case +x <> t:
      +rest = shared_go(t, ys)
      Bool.pick(List<&2, V.Point>, any_eq(ys, x), x <> rest, rest)

def pts_box(+ps: List<&2, V.Point>) -> List<&2, F64>:
  [SC.dmin(ps, V.Dr{1.0f64, 0.0f64, 0.0f64}, SC.inf()), SC.dmax(ps, V.Dr{1.0f64, 0.0f64, 0.0f64}, F64.neg(SC.inf())),
    SC.dmin(ps, V.Dr{0.0f64, 1.0f64, 0.0f64}, SC.inf()), SC.dmax(ps, V.Dr{0.0f64, 1.0f64, 0.0f64}, F64.neg(SC.inf())),
    SC.dmin(ps, V.Dr{0.0f64, 0.0f64, 1.0f64}, SC.inf()), SC.dmax(ps, V.Dr{0.0f64, 0.0f64, 1.0f64}, F64.neg(SC.inf()))]

def box_of(+p: G.BezP) -> List<&2, F64>:
  pts_box(SC.pts16(p))

def box_dis(+a: List<&2, F64>, +b: List<&2, F64>, +tol: F64) -> Bool:
  Bool.or(Bool.or(F64.is_lt(F64.add(Q.fnth(a, 1n), tol), Q.fnth(b, 0n)), F64.is_lt(F64.add(Q.fnth(b, 1n), tol), Q.fnth(a, 0n))),
    Bool.or(Bool.or(F64.is_lt(F64.add(Q.fnth(a, 3n), tol), Q.fnth(b, 2n)), F64.is_lt(F64.add(Q.fnth(b, 3n), tol), Q.fnth(a, 2n))),
      Bool.or(F64.is_lt(F64.add(Q.fnth(a, 5n), tol), Q.fnth(b, 4n)), F64.is_lt(F64.add(Q.fnth(b, 5n), tol), Q.fnth(a, 4n)))))

def side_ok(ps: List<&2, V.Point>, +o: V.Point, +m: V.Dir, +tol: F64, +sg: F64) -> Bool:
  match ps:
    case []: True{}
    case +q <> t: Bool.and(F64.is_le(F64.neg(tol), F64.mul(sg, KS.dot(m, KS.psub(q, o)))), side_ok(t, o, m, tol, sg))

def wedge(+a: G.BezP, +b: G.BezP, +o: V.Point, +tol: F64) -> Bool:
  +m = KS.dunit(KS.dadd(SC.ctr_n(a), F64.neg(1.0f64), SC.ctr_n(b)))
  Bool.and(F64.is_lt(1.0e-6f64, KS.dlen(KS.dadd(SC.ctr_n(a), F64.neg(1.0f64), SC.ctr_n(b)))),
    Bool.and(side_ok(SC.pts16(a), o, m, tol, 1.0f64), side_ok(SC.pts16(b), o, m, tol, F64.neg(1.0f64))))

def adj_ok(+a: G.BezP, +b: G.BezP, +o: V.Point, +tol: F64) -> Bool:
  +ax = KS.dunit(KS.dadd(SC.ctr_n(a), 1.0f64, SC.ctr_n(b)))
  Bool.or(Bool.and(SC.cone1(a, ax), SC.cone1(b, ax)), wedge(a, b, o, tol))

def first_pt(ps: List<&2, V.Point>) -> V.Point:
  match ps:
    case []: pt(0.0f64, 0.0f64, 0.0f64)
    case +h <> t: h

def colv(+a: G.BezP, +sh: List<&2, V.Point>) -> Bool:
  G.Bp{+p00, p01, p02, +p03, p10, p11, p12, p13, p20, p21, p22, p23, +p30, p31, p32, +p33} = a
  Bool.or(Bool.and(any_eq(sh, p00), any_eq(sh, p30)), Bool.and(any_eq(sh, p03), any_eq(sh, p33)))

def hv(+p: G.BezP, +vdir: Bool) -> List<&2, G.BezP>:
  Bool.pick(List<&2, G.BezP>, vdir, [SC.tr(SC.split_u(SC.tr(p), True{})), SC.tr(SC.split_u(SC.tr(p), False{}))],
    [SC.split_u(p, True{}), SC.split_u(p, False{})])

def bnth2(xs: List<&2, G.BezP>, +i: Nat) -> G.BezP:
  match xs:
    case []: bp_zero()
    case +h <> t:
      match i:
        case 0n: h
        case 1n+j: bnth2(t, j)

def pr_kind(+a: G.BezP, +b: G.BezP, +tol: F64) -> U64:
  +sh = shared_go(corners(a), corners(b))
  Bool.pick(U64, box_dis(box_of(a), box_of(b), tol), 0u64,
    Bool.pick(U64, Nat.is_eq(List.length(&2, V.Point, sh), 0n), 1u64, Bool.pick(U64, adj_ok(a, b, first_pt(sh), tol), 0u64, 2u64)))

def pr_k2(+xa: List<&2, G.BezP>, +xb: List<&2, G.BezP>, +i: Nat, +j: Nat, +tol: F64) -> U64:
  pr_kind(bnth2(xa, i), bnth2(xb, j), tol)

def leaf_ok(+a: G.BezP, +b: G.BezP) -> Bool:
  Bool.and(Bool.and(SC.cone1(a, SC.ctr_n(a)), SC.cone1(b, SC.ctr_n(b))), F64.is_lt(F64.neg(0.9f64), KS.dot(SC.ctr_n(a), SC.ctr_n(b))))

def pt_ok(+a: G.BezP, +b: G.BezP, +tol: F64) -> Bool:
  Bool.or(box_dis(box_of(a), box_of(b), tol), Bool.or(SC.sep_pp(a, b, tol), leaf_ok(a, b)))

def pr_rec(n: Nat, +k: U64, +a: G.BezP, +b: G.BezP, +tol: F64) -> Bool:
  match n:
    case 0n: Bool.or(U64.is_eq(k, 0u64), Bool.and(U64.is_eq(k, 2u64), leaf_ok(a, b)))
    case 1n+(+m):
      match k:
        case 0u64: True{}
        case 1u64: SC.sep_rec(a, b, 4n, tol)
        case _:
          +vd = colv(a, shared_go(corners(a), corners(b)))
          +xa = hv(a, vd)
          +xb = hv(b, vd)
          Bool.and(Bool.and(pr_rec(m, pr_k2(xa, xb, 0n, 0n, tol), bnth2(xa, 0n), bnth2(xb, 0n), tol),
            pr_rec(m, pr_k2(xa, xb, 1n, 1n, tol), bnth2(xa, 1n), bnth2(xb, 1n), tol)),
            Bool.and(pt_ok(bnth2(xa, 0n), bnth2(xb, 1n), tol), pt_ok(bnth2(xa, 1n), bnth2(xb, 0n), tol)))

def pair_ok(+a: G.BezP, +b: G.BezP, +tol: F64) -> Bool:
  +sh = shared_go(corners(a), corners(b))
  Bool.or(box_dis(box_of(a), box_of(b), tol),
    Bool.pick(Bool, Nat.is_eq(List.length(&2, V.Point, sh), 0n), SC.sep_rec(a, b, 6n, tol), pr_rec(6n, 2u64, a, b, tol)))

def pairs_j(ps: List<&2, G.BezP>, +a: G.BezP, +i: Nat, +j: Nat, +tol: F64) -> SC.Ck:
  match ps:
    case []: SC.Ck{True{}, 0n, 0n}
    case +b <> t: Bool.pick(SC.Ck, pair_ok(a, b, tol), pairs_j(t, a, i, Nat.add(j, 1n), tol), SC.Ck{False{}, i, j})

def ck_ok(+c: SC.Ck) -> Bool:
  SC.Ck{+ok, a, b} = c
  ok

def pairs_i(ps: List<&2, G.BezP>, +i: Nat, +tol: F64) -> SC.Ck:
  match ps:
    case []: SC.Ck{True{}, 0n, 0n}
    case +a <> +t:
      +r = pairs_j(t, a, i, Nat.add(i, 1n), tol)
      Bool.pick(SC.Ck, ck_ok(r), pairs_i(t, Nat.add(i, 1n), tol), r)

def regs(ps: List<&2, G.BezP>, +i: Nat) -> SC.Ck:
  match ps:
    case []: SC.Ck{True{}, 0n, 0n}
    case +p <> t: Bool.pick(SC.Ck, SC.cone_ok(p, SC.ctr_n(p)), regs(t, Nat.add(i, 1n)), SC.Ck{False{}, i, i})

def bz_pts(+b: G.Bez3) -> List<&2, V.Point>:
  G.Bz{+a, +c, +d, +e} = b
  [a, c, d, e]

def cap_pts(n: Nat, +g: Gr, +b: Nat, +u: Nat) -> List<&2, V.Point>:
  match n:
    case 0n: []
    case 1n+(+m): List.append(&2, V.Point, bz_pts(ue_curve(g, b, u)), cap_pts(m, g, b, Nat.add(u, 1n)))

def cap_box(+g: Gr, +b: Nat) -> List<&2, F64>:
  pts_box(cap_pts(gr_nu(g), g, b, 0n))

def cq_pass(+p: G.BezP, +o: V.Point, +m: V.Dir, +tol: F64, +cb: List<&2, F64>) -> Bool:
  Bool.or(side_ok(SC.pts16(p), o, m, tol, 1.0f64), box_dis(box_of(p), cb, tol))

def cq_p(+q: SC.Pq) -> G.BezP:
  SC.Pq{+a, +b, +d} = q
  a

def cq_d(+q: SC.Pq) -> Nat:
  SC.Pq{+a, +b, +d} = q
  d

def cq_kids(xs: List<&2, G.BezP>, +d: Nat, +acc: List<&2, SC.Pq>) -> List<&2, SC.Pq>:
  match xs:
    case []: acc
    case +x <> t: cq_kids(t, d, SC.Pq{x, x, d} <> acc)

def cq_split(ok: Bool, +q: SC.Pq, +rest: List<&2, SC.Pq>) -> List<&2, SC.Pq>:
  match ok:
    case True{}: rest
    case False{}: cq_kids(SC.quads(cq_p(q)), Nat.sub(cq_d(q), 1n), rest)

def cq_bad(+q: SC.Pq, +o: V.Point, +m: V.Dir, +tol: F64, +cb: List<&2, F64>) -> Bool:
  Bool.and(Nat.is_eq(cq_d(q), 0n), Bool.not(cq_pass(cq_p(q), o, m, tol, cb)))

def cq_go(bad: Bool, +q: SC.Pq, +o: V.Point, +m: V.Dir, +tol: F64, +cb: List<&2, F64>, +t: List<&2, SC.Pq>) -> List<&2, SC.Pq>:
  match bad:
    case True{}: []
    case False{}: cq_split(cq_pass(cq_p(q), o, m, tol, cb), q, t)

def cq_wl(n: Nat, +ws: List<&2, SC.Pq>, +o: V.Point, +m: V.Dir, +tol: F64, +cb: List<&2, F64>) -> Bool:
  match n:
    case 0n: False{}
    case 1n+(+k):
      match ws:
        case []: True{}
        case +q <> t: Bool.and(Bool.not(cq_bad(q, o, m, tol, cb)), cq_wl(k, cq_go(cq_bad(q, o, m, tol, cb), q, o, m, tol, cb, t), o, m, tol, cb))

def cap_side(ps: List<&2, G.BezP>, +o: V.Point, +m: V.Dir, +tol: F64, +cb: List<&2, F64>, +i: Nat) -> SC.Ck:
  match ps:
    case []: SC.Ck{True{}, 0n, 0n}
    case +p <> t: Bool.pick(SC.Ck, cq_wl(20000n, [SC.Pq{p, p, 5n}], o, m, tol, cb),
      cap_side(t, o, m, tol, cb, Nat.add(i, 1n)), SC.Ck{False{}, i, 100000n})

def ck_then(+a: SC.Ck, +b: SC.Ck) -> SC.Ck:
  Bool.pick(SC.Ck, ck_ok(a), b, a)

def toward(+n: V.Dir, +d: V.Dir) -> V.Dir:
  Bool.pick(V.Dir, F64.is_lt(KS.dot(n, d), 0.0f64), KS.dscale(F64.neg(1.0f64), n), n)

def sk_cert(+g: Gr, +cs: List<&2, Sc>) -> SC.Ck:
  +ps = cat_bps(gr_pg(g))
  +tol = F64.mul(1.0e-9f64, F64.add(1.0f64, KS.dlen(KS.psub(centroid(sc_first(cs)), pt(0.0f64, 0.0f64, 0.0f64)))))
  +f0 = sc_fr(sc_first(cs))
  +f1 = sc_fr(sc_last(cs, sc_first(cs)))
  +n0 = toward(fr_n(f0), KS.dunit(sk_d0(cs)))
  +n1 = toward(fr_n(f1), KS.dunit(sk_d1(cs)))
  ck_then(regs(ps, 0n), ck_then(cap_side(ps, fr_o(f0), n0, F64.mul(1.0e3f64, tol), cap_box(g, 0n), 0n),
    ck_then(cap_side(ps, fr_o(f1), KS.dscale(F64.neg(1.0f64), n1), F64.mul(1.0e3f64, tol), cap_box(g, gr_nb(g)), 0n), pairs_i(ps, 0n, tol))))

def ga_v(ns: List<&2, V.Vec2>, +w: G.BezP, +u: F64, +wu: F64, +v0: F64, +dv: F64, +acc: F64) -> F64:
  match ns:
    case []: acc
    case +h <> t:
      +v = F64.add(v0, F64.mul(dv, V.v2_x(h)))
      +n = KS.cross(KS.bp_su(w, u, v), KS.bp_sv(w, u, v))
      ga_v(t, w, u, wu, v0, dv, F64.add(acc, F64.mul(F64.mul(wu, F64.mul(dv, V.v2_y(h))), KS.dlen(n))))

def ga_u(ns: List<&2, V.Vec2>, +w: G.BezP, +u0: F64, +du: F64, +v0: F64, +dv: F64, +acc: F64) -> F64:
  match ns:
    case []: acc
    case +h <> t: ga_u(t, w, u0, du, v0, dv, ga_v(gl5(), w, F64.add(u0, F64.mul(du, V.v2_x(h))), F64.mul(du, V.v2_y(h)), v0, dv, acc))

def p_area1(+w: G.BezP) -> F64:
  ga_u(gl5(), w, 0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64)

def p_area4(+w: G.BezP) -> F64:
  F64.add(F64.add(ga_u(gl5(), w, 0.0f64, 0.5f64, 0.0f64, 0.5f64, 0.0f64), ga_u(gl5(), w, 0.5f64, 0.5f64, 0.0f64, 0.5f64, 0.0f64)),
    F64.add(ga_u(gl5(), w, 0.0f64, 0.5f64, 0.5f64, 0.5f64, 0.0f64), ga_u(gl5(), w, 0.5f64, 0.5f64, 0.5f64, 0.5f64, 0.0f64)))

def pareas(ps: List<&2, G.BezP>, +acc: V.Vec2) -> V.Vec2:
  match ps:
    case []: acc
    case +w <> t:
      +a4 = p_area4(w)
      pareas(t, V.V2{F64.add(V.v2_x(acc), a4), F64.add(V.v2_y(acc), F64.add(F64.abs(F64.sub(a4, p_area1(w))), F64.mul(1.0e-12f64, a4)))})

def cap_area(+g: Gr, +b: Nat, +f: Fr) -> F64:
  F64.abs(F64.mul(0.5f64, row_area(gr_nu(g), g, b, 0n, fr_o(f), fr_n(f), 0.0f64)))

def sk_area(+g: Gr, +cs: List<&2, Sc>) -> I.I:
  +pa = pareas(cat_bps(gr_pg(g)), V.V2{0.0f64, 0.0f64})
  +c = F64.add(cap_area(g, 0n, sc_fr(sc_first(cs))), cap_area(g, gr_nb(g), sc_fr(sc_last(cs, sc_first(cs)))))
  +a = F64.add(V.v2_x(pa), c)
  +e = F64.add(V.v2_y(pa), F64.mul(1.0e-12f64, F64.add(c, 1.0f64)))
  I.I{F64.sub(a, e), F64.add(a, e)}

def set_last(ps: List<&2, V.Point>, +q: V.Point) -> List<&2, V.Point>:
  match ps:
    case []: []
    case +h <> t:
      match t:
        case []: [q]
        case +x <> y: h <> set_last(x <> y, q)

def chain_go(rs: List<&2, List<&2, V.Point>>, +p0: V.Point) -> List<&2, List<&2, V.Point>>:
  match rs:
    case []: []
    case +r <> +t: set_last(r, first_or(first_run(t), p0)) <> chain_go(t, p0)

def first_run2(rs: List<&2, List<&2, V.Vec2>>) -> List<&2, V.Vec2>:
  match rs:
    case []: []
    case +h <> t: h

def set_last2(ps: List<&2, V.Vec2>, +q: V.Vec2) -> List<&2, V.Vec2>:
  match ps:
    case []: []
    case +h <> t:
      match t:
        case []: [q]
        case +x <> y: h <> set_last2(x <> y, q)

def chain2(rs: List<&2, List<&2, V.Vec2>>, +p0: V.Vec2) -> List<&2, List<&2, V.Vec2>>:
  match rs:
    case []: []
    case +r <> +t: set_last2(r, Bool.pick(V.Vec2, Nat.is_eq(List.length(&2, List<&2, V.Vec2>, t), 0n), p0, first2(first_run2(t))))
      <> chain2(t, p0)

def sc_chain(+c: Sc) -> Sc:
  Sc{+rs, +f} = c
  Sc{chain2(rs, first2(first_run2(rs))), f}

def scs_chain(cs: List<&2, Sc>) -> List<&2, Sc>:
  match cs:
    case []: []
    case +c <> t: sc_chain(c) <> scs_chain(t)

def sk_run(+cs0: List<&2, Sc>, +nd: U64) -> SkR:
  +cs = orient(scs_chain(cs0))
  +g = grid(cs)
  SkR{bt_tol(sk_bt(g, cs, nd)), sk_vol(g, cs), sk_cert(g, cs), sk_area(g, cs)}

def skr_bt(r: SkR) -> BD.Bt:
  SkR{bt, vol, ck, ar} = r
  bt

def skr_vol(+r: SkR) -> I.I:
  SkR{bt, +vol, ck, ar} = r
  vol

def skr_ck(+r: SkR) -> SC.Ck:
  SkR{bt, vol, +ck, ar} = r
  ck

def skr_ar(+r: SkR) -> I.I:
  SkR{bt, vol, ck, +ar} = r
  ar
