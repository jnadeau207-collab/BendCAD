import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../base/par.bend as B
import ./model.bend as M
import ./tess.bend as TS
import ./sx.bend as S
import ../c10/mesh.bend as M10
import ../k1/sf.bend as KS

type Vw is Data:
  Vw{ d: V.Dir, r: V.Dir, u: V.Dir }

def vw_front() -> Vw:
  Vw{V.Dr{0.0f64, F64.neg(1.0f64), 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}}

def vw_top() -> Vw:
  Vw{V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}}

def vw_left() -> Vw:
  Vw{V.Dr{F64.neg(1.0f64), 0.0f64, 0.0f64}, V.Dr{0.0f64, F64.neg(1.0f64), 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}}

def dp(+p: V.Point, +d: V.Dir) -> F64:
  F64.add(F64.add(F64.mul(V.pt_x(p), V.dr_x(d)), F64.mul(V.pt_y(p), V.dr_y(d))), F64.mul(V.pt_z(p), V.dr_z(d)))

def dd(+a: V.Dir, +b: V.Dir) -> F64:
  F64.add(F64.add(F64.mul(V.dr_x(a), V.dr_x(b)), F64.mul(V.dr_y(a), V.dr_y(b))), F64.mul(V.dr_z(a), V.dr_z(b)))

def vw_d(+v: Vw) -> V.Dir:
  Vw{+d, r, u} = v
  d

def prj(+v: Vw, +p: V.Point) -> V.Point:
  Vw{+d, +r, +u} = v
  V.Pt{dp(p, r), dp(p, u), dp(p, d)}

def prjs(ps: List<&2, V.Point>, +v: Vw) -> List<&2, V.Point>:
  match ps:
    case []: []
    case +p <> t: prj(v, p) <> prjs(t, v)

def wpts(ps: List<&2, V.Point>, +pl: M.Pl) -> List<&2, V.Point>:
  match ps:
    case []: []
    case +p <> t: TS.pl_pt(p, pl) <> wpts(t, pl)

type Bx is Data:
  Bx{ x0: F64, x1: F64, y0: F64, y1: F64 }

def bx0() -> Bx:
  Bx{1.0e300f64, F64.neg(1.0e300f64), 1.0e300f64, F64.neg(1.0e300f64)}

def bx_add(+b: Bx, +x: F64, +y: F64) -> Bx:
  Bx{+x0, +x1, +y0, +y1} = b
  Bx{F64.min(x0, x), F64.max(x1, x), F64.min(y0, y), F64.max(y1, y)}

def bx_ps(ps: List<&2, V.Point>, +acc: Bx) -> Bx:
  match ps:
    case []: acc
    case +p <> t: bx_ps(t, bx_add(acc, V.pt_x(p), V.pt_y(p)))

def bx_x0(+b: Bx) -> F64:
  Bx{+x0, x1, y0, y1} = b
  x0

def bx_x1(+b: Bx) -> F64:
  Bx{x0, +x1, y0, y1} = b
  x1

def bx_y0(+b: Bx) -> F64:
  Bx{x0, x1, +y0, y1} = b
  y0

def bx_y1(+b: Bx) -> F64:
  Bx{x0, x1, y0, +y1} = b
  y1

type Gd is Data:
  Gd{ x0: F64, y0: F64, cw: F64, ch: F64, n: Nat, cells: B.Tb<&2, List<&2, Nat>> }

def nf(+n: Nat) -> F64:
  U64.to_f64(U64.from_nat(n))

def fnat(+x: F64) -> Nat:
  U64.to_nat(F64.to_u64(F64.max(0.0f64, x)))

def cl_k(+k: Nat, +n: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_lt(k, n), k, Nat.sub(n, 1n))

def cl_i(+v: F64, +o: F64, +w: F64, +n: Nat) -> Nat:
  cl_k(fnat(F64.div(F64.sub(v, o), w)), n)

def pt2(+pt: B.Tb<&2, V.Point>, +i: Nat) -> V.Point:
  B.tb_get(V.Point, pt, U32.from_nat(i))

def keys_y(c: Nat, +iy: Nat, +ix0: Nat, +n: Nat, +t: Nat, +acc: List<&2, U64>) -> List<&2, U64>:
  match c:
    case 0n: acc
    case 1n+(+k): keys_y(k, iy, ix0, n, t, U64.add(U64.shln(U64.from_nat(Nat.add(Nat.add(ix0, k), Nat.mul(iy, n))), 32n), U64.from_nat(t)) <> acc)

def rg_add(+x: F64, +m: V.Vec2) -> V.Vec2:
  V.V2{F64.min(V.v2_x(m), x), F64.max(V.v2_y(m), x)}

def xat(+px: F64, +py: F64, +qx: F64, +qy: F64, +y: F64) -> F64:
  F64.add(px, F64.mul(F64.sub(y, py), F64.div(F64.sub(qx, px), F64.sub(qy, py))))

def er3(fl: Bool, +y0: F64, +y1: F64, +px: F64, +py: F64, +qx: F64, +qy: F64, +m: V.Vec2) -> V.Vec2:
  match fl:
    case True{}: rg_add(px, rg_add(qx, m))
    case False{}: rg_add(xat(px, py, qx, qy, y0), rg_add(xat(px, py, qx, qy, y1), m))

def er2(ov: Bool, +y0: F64, +y1: F64, +px: F64, +py: F64, +qx: F64, +qy: F64, +m: V.Vec2) -> V.Vec2:
  match ov:
    case False{}: m
    case True{}: er3(F64.is_lt(F64.abs(F64.sub(qy, py)), 1.0e-12f64), y0, y1, px, py, qx, qy, m)

def er1(+y0: F64, +y1: F64, +px: F64, +py: F64, +qx: F64, +qy: F64, +m: V.Vec2) -> V.Vec2:
  er2(F64.is_le(y0, y1), y0, y1, px, py, qx, qy, m)

def ed_rng(+p: V.Point, +q: V.Point, +ya: F64, +yb: F64, +m: V.Vec2) -> V.Vec2:
  er1(F64.max(ya, F64.min(V.pt_y(p), V.pt_y(q))), F64.min(yb, F64.max(V.pt_y(p), V.pt_y(q))), V.pt_x(p), V.pt_y(p), V.pt_x(q), V.pt_y(q), m)

def tri_rg(+a: V.Point, +b: V.Point, +c: V.Point, +ya: F64, +yb: F64) -> V.Vec2:
  ed_rng(a, b, ya, yb, ed_rng(b, c, ya, yb, ed_rng(c, a, ya, yb, V.V2{1.0e300f64, F64.neg(1.0e300f64)})))

def row_k2(+ix0: Nat, +ix1: Nat, +iy: Nat, +n: Nat, +t: Nat, +acc: List<&2, U64>) -> List<&2, U64>:
  keys_y(Nat.add(Nat.sub(ix1, ix0), 1n), iy, ix0, n, t, acc)

def row_q(em: Bool, +rg: V.Vec2, +iy: Nat, +x0: F64, +cw: F64, +n: Nat, +t: Nat, +acc: List<&2, U64>) -> List<&2, U64>:
  match em:
    case True{}: acc
    case False{}: row_k2(cl_i(F64.sub(V.v2_x(rg), 1.0e-9f64), x0, cw, n), cl_i(F64.add(V.v2_y(rg), 1.0e-9f64), x0, cw, n), iy, n, t, acc)

def row_one(+rg: V.Vec2, +iy: Nat, +x0: F64, +cw: F64, +n: Nat, +t: Nat, +acc: List<&2, U64>) -> List<&2, U64>:
  row_q(F64.is_lt(V.v2_y(rg), V.v2_x(rg)), rg, iy, x0, cw, n, t, acc)

def rows_go(k: Nat, +iy: Nat, +a: V.Point, +b: V.Point, +c: V.Point, +x0: F64, +y0: F64, +cw: F64, +ch: F64, +n: Nat, +t: Nat, +acc: List<&2, U64>) -> List<&2, U64>:
  match k:
    case 0n: acc
    case 1n+(+m):
      rows_go(m, Nat.add(iy, 1n), a, b, c, x0, y0, cw, ch, n, t,
        row_one(tri_rg(a, b, c, F64.sub(F64.add(y0, F64.mul(nf(iy), ch)), 1.0e-9f64), F64.add(F64.add(y0, F64.mul(nf(Nat.add(iy, 1n)), ch)), 1.0e-9f64)), iy, x0, cw, n, t, acc))

def tri_k5(+iy0: Nat, +iy1: Nat, +a: V.Point, +b: V.Point, +c: V.Point, +i: Nat, +x0: F64, +y0: F64, +cw: F64, +ch: F64, +n: Nat, +acc: List<&2, U64>) -> List<&2, U64>:
  rows_go(Nat.add(Nat.sub(iy1, iy0), 1n), iy0, a, b, c, x0, y0, cw, ch, n, i, acc)

def tri_k4(fr: Bool, +a: V.Point, +b: V.Point, +c: V.Point, +i: Nat, +x0: F64, +y0: F64, +cw: F64, +ch: F64, +n: Nat, +acc: List<&2, U64>) -> List<&2, U64>:
  match fr:
    case False{}: acc
    case True{}:
      tri_k5(cl_i(F64.min(V.pt_y(a), F64.min(V.pt_y(b), V.pt_y(c))), y0, ch, n), cl_i(F64.max(V.pt_y(a), F64.max(V.pt_y(b), V.pt_y(c))), y0, ch, n), a, b, c, i, x0, y0, cw, ch, n, acc)

def tar(+a: V.Point, +b: V.Point, +c: V.Point) -> F64:
  F64.sub(F64.mul(F64.sub(V.pt_x(b), V.pt_x(a)), F64.sub(V.pt_y(c), V.pt_y(a))), F64.mul(F64.sub(V.pt_y(b), V.pt_y(a)), F64.sub(V.pt_x(c), V.pt_x(a))))

def tri_fr2(+pos: Bool, +ar: F64) -> Bool:
  Bool.pick(Bool, pos, F64.is_lt(1.0e-14f64, ar), F64.is_lt(ar, F64.neg(1.0e-14f64)))

def tri_k3p(+a: V.Point, +b: V.Point, +c: V.Point, +i: Nat, +x0: F64, +y0: F64, +cw: F64, +ch: F64, +n: Nat, +pos: Bool, +acc: List<&2, U64>) -> List<&2, U64>:
  tri_k4(tri_fr2(pos, tar(a, b, c)), a, b, c, i, x0, y0, cw, ch, n, acc)

def tri_keys(+t: TS.Tri, +i: Nat, +pt: B.Tb<&2, V.Point>, +g: Gd, +pos: Bool, +acc: List<&2, U64>) -> List<&2, U64>:
  Gd{+x0, +y0, +cw, +ch, +n, cells} = g
  tri_k3p(pt2(pt, TS.ta(t)), pt2(pt, TS.tb(t)), pt2(pt, TS.tc(t)), i, x0, y0, cw, ch, n, pos, acc)

def tris_keys(ts: List<&2, TS.Tri>, +i: Nat, +pt: B.Tb<&2, V.Point>, +g: Gd, +pos: Bool, +acc: List<&2, U64>) -> List<&2, U64>:
  match ts:
    case []: acc
    case +t <> r: tris_keys(r, Nat.add(i, 1n), pt, g, pos, tri_keys(t, i, pt, g, pos, acc))

def u_lt2(+a: U64, +b: U64) -> B.Sgn:
  B.sgn_pick(U64.is_lt(a, b), U64.is_lt(b, a))

def u_lt(a: U64, b: U64) -> B.Sgn:
  u_lt2(a, b)

def so_u(s: B.So<&2, U64>) -> List<&2, U64>:
  B.So{ok, xs} = s
  xs

def gr_fill(c: Nat, +acc: List<&2, List<&2, Nat>>) -> List<&2, List<&2, Nat>>:
  match c:
    case 0n: acc
    case 1n+(+k): gr_fill(k, [] <> acc)

def gr_go(fuel: Nat, ks: List<&2, U64>, +cell: Nat, +cur: List<&2, Nat>, +acc: List<&2, List<&2, Nat>>, +nc: Nat) -> List<&2, List<&2, Nat>>:
  match fuel:
    case 0n: acc
    case 1n+(+f):
      match ks:
        case []: gr_fill(Nat.sub(Nat.sub(nc, cell), 1n), cur <> acc)
        case +k <> +t:
          +same = Nat.is_eq(U64.to_nat(U64.shrn(k, 32n)), cell)
          gr_go(f, Bool.pick(List<&2, U64>, same, t, k <> t), Bool.pick(Nat, same, cell, Nat.add(cell, 1n)),
            Bool.pick(List<&2, Nat>, same, U64.to_nat(U64.and(k, 4294967295u64)) <> cur, []), Bool.pick(List<&2, List<&2, Nat>>, same, acc, cur <> acc), nc)

def gr_run(+ks: List<&2, U64>, +nc: Nat) -> List<&2, List<&2, Nat>>:
  gr_go(Nat.add(Nat.add(List.length(&2, U64, ks), nc), 2n), ks, 0n, [], [], nc)


def gn2(+k: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_lt(k, 8n), 8n, Bool.pick(Nat, Nat.is_lt(96n, k), 96n, k))

def gn(+t: Nat) -> Nat:
  gn2(fnat(F64.sqrt(nf(t))))

def grid_c(+ts: List<&2, TS.Tri>, +pt: B.Tb<&2, V.Point>, +x0: F64, +y0: F64, +cw: F64, +ch: F64, +n: Nat, +pos: Bool) -> Gd:
  Gd{x0, y0, cw, ch, n, B.tb_of(List<&2, Nat>, List.reverse(&2, List<&2, Nat>, gr_run(so_u(B.msort(~U64, ~u_lt, tris_keys(ts, 0n, pt, Gd{x0, y0, cw, ch, n, B.tb_of(List<&2, Nat>, [], [])}, pos, []))), Nat.mul(n, n))), [])}

def grid_n(+ts: List<&2, TS.Tri>, +pt: B.Tb<&2, V.Point>, +b: Bx, +n: Nat, +pos: Bool) -> Gd:
  grid_c(ts, pt, bx_x0(b), bx_y0(b), F64.div(F64.add(F64.sub(bx_x1(b), bx_x0(b)), 1.0e-9f64), nf(n)), F64.div(F64.add(F64.sub(bx_y1(b), bx_y0(b)), 1.0e-9f64), nf(n)), n, pos)

def grid_of(+ts: List<&2, TS.Tri>, +pt: B.Tb<&2, V.Point>, +b: Bx, +pos: Bool) -> Gd:
  grid_n(ts, pt, b, gn(List.length(&2, TS.Tri, ts)), pos)

type Oc is Data:
  Oc{ g: Gd, pt: B.Tb<&2, V.Point>, tt: B.Tb<&2, TS.Tri>, hx: B.Tb<&2, Bool>, sk: Bool, eps: F64, mg: F64 }

def oc_sk(+o: Oc) -> Oc:
  Oc{+g, +pt, +tt, +hx, sk, +eps, +mg} = o
  Oc{g, pt, tt, hx, True{}, eps, mg}

def cr2(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> F64:
  F64.sub(F64.mul(ax, by), F64.mul(ay, bx))

def cov5(+la: F64, +lb: F64, +lc: F64, +za: F64, +zb: F64, +zc: F64, +qz: F64, +eps: F64) -> Bool:
  Bool.and(Bool.and(F64.is_lt(1.0e-7f64, la), Bool.and(F64.is_lt(1.0e-7f64, lb), F64.is_lt(1.0e-7f64, lc))),
    F64.is_lt(F64.add(qz, eps), F64.add(F64.add(F64.mul(la, za), F64.mul(lb, zb)), F64.mul(lc, zc))))

def cov4(+la: F64, +lb: F64, +za: F64, +zb: F64, +zc: F64, +qz: F64, +eps: F64) -> Bool:
  cov5(la, lb, F64.sub(F64.sub(1.0f64, la), lb), za, zb, zc, qz, eps)

def lam(+b: V.Point, +c: V.Point, +q: V.Point, +ar: F64) -> F64:
  F64.div(cr2(F64.sub(V.pt_x(b), V.pt_x(q)), F64.sub(V.pt_y(b), V.pt_y(q)), F64.sub(V.pt_x(c), V.pt_x(q)), F64.sub(V.pt_y(c), V.pt_y(q))), ar)

def d2(+a: V.Point, +b: V.Point) -> F64:
  F64.sqrt(F64.add(F64.mul(F64.sub(V.pt_x(b), V.pt_x(a)), F64.sub(V.pt_x(b), V.pt_x(a))), F64.mul(F64.sub(V.pt_y(b), V.pt_y(a)), F64.sub(V.pt_y(b), V.pt_y(a)))))

def cov_m2(+aa: F64, +la: F64, +lb: F64, +ha: F64, +hb: F64, +hc: F64, +m: F64) -> Bool:
  Bool.and(F64.is_lt(m, F64.div(F64.mul(la, aa), ha)), Bool.and(F64.is_lt(m, F64.div(F64.mul(lb, aa), hb)), F64.is_lt(m, F64.div(F64.mul(F64.sub(F64.sub(1.0f64, la), lb), aa), hc))))

def cov_mg(on: Bool, +ar: F64, +a: V.Point, +b: V.Point, +c: V.Point, +q: V.Point, +m: F64) -> Bool:
  match on:
    case False{}: True{}
    case True{}: cov_m2(F64.abs(ar), lam(b, c, q, ar), lam(c, a, q, ar), d2(b, c), d2(c, a), d2(a, b), m)

def cov3(+ar: F64, +a: V.Point, +b: V.Point, +c: V.Point, +q: V.Point, +eps: F64, +m: F64) -> Bool:
  Bool.and(Bool.and(F64.is_lt(1.0e-14f64, F64.abs(ar)), cov4(lam(b, c, q, ar), lam(c, a, q, ar), V.pt_z(a), V.pt_z(b), V.pt_z(c), V.pt_z(q), eps)),
    cov_mg(F64.is_lt(0.0f64, m), ar, a, b, c, q, m))

def covers(+a: V.Point, +b: V.Point, +c: V.Point, +q: V.Point, +eps: F64, +m: F64) -> Bool:
  cov3(cr2(F64.sub(V.pt_x(b), V.pt_x(a)), F64.sub(V.pt_y(b), V.pt_y(a)), F64.sub(V.pt_x(c), V.pt_x(a)), F64.sub(V.pt_y(c), V.pt_y(a))), a, b, c, q, eps, m)

def cov_q(sk: Bool, +hx: B.Tb<&2, Bool>, +ti: Nat) -> Bool:
  match sk:
    case True{}: B.tb_get(Bool, hx, U32.from_nat(ti))
    case False{}: False{}

def cov_t(+o: Oc, +ti: Nat, +q: V.Point) -> Bool:
  Oc{g, +pt, +tt, +hx, +sk, +eps, +mg} = o
  +t = B.tb_get(TS.Tri, tt, U32.from_nat(ti))
  Bool.and(Bool.not(cov_q(sk, hx, ti)), covers(pt2(pt, TS.ta(t)), pt2(pt, TS.tb(t)), pt2(pt, TS.tc(t)), q, eps, mg))

def cov_l(xs: List<&2, Nat>, +o: Oc, +q: V.Point) -> Bool:
  match xs:
    case []: False{}
    case +i <> t: Bool.or(cov_t(o, i, q), cov_l(t, o, q))

def hid(+o: Oc, +q: V.Point) -> Bool:
  Oc{+g, pt, tt, hx, sk, eps, mg} = o
  Gd{+x0, +y0, +cw, +ch, +n, +cells} = g
  cov_l(B.tb_get(List<&2, Nat>, cells, U32.from_nat(Nat.add(cl_i(V.pt_x(q), x0, cw, n), Nat.mul(cl_i(V.pt_y(q), y0, ch, n), n)))), o, q)

type Sg is Data:
  Sg{ ax: F64, ay: F64, bx: F64, by: F64, h: Bool }

def mid(+a: V.Point, +b: V.Point, +f: F64) -> V.Point:
  V.Pt{F64.add(V.pt_x(a), F64.mul(f, F64.sub(V.pt_x(b), V.pt_x(a)))), F64.add(V.pt_y(a), F64.mul(f, F64.sub(V.pt_y(b), V.pt_y(a)))),
    F64.add(V.pt_z(a), F64.mul(f, F64.sub(V.pt_z(b), V.pt_z(a))))}

def sg_mk(+a: V.Point, +b: V.Point, +h: Bool) -> Sg:
  Sg{V.pt_x(a), V.pt_y(a), V.pt_x(b), V.pt_y(b), h}

def sub_one(+p0: V.Point, +p1: V.Point, +o: Oc) -> Sg:
  sg_mk(p0, p1, hid(o, mid(p0, p1, 0.5f64)))

def sub_go(c: Nat, +n: Nat, +o: Oc, +a: V.Point, +b: V.Point, +acc: List<&2, Sg>) -> List<&2, Sg>:
  match c:
    case 0n: acc
    case 1n+(+k): sub_go(k, n, o, a, b, sub_one(mid(a, b, F64.div(nf(k), nf(n))), mid(a, b, F64.div(nf(Nat.add(k, 1n)), nf(n))), o) <> acc)

def seg_pick(agree: Bool, +o: Oc, +a: V.Point, +b: V.Point, +hm: Bool, +acc: List<&2, Sg>) -> List<&2, Sg>:
  match agree:
    case True{}: sg_mk(a, b, hm) <> acc
    case False{}: sub_go(8n, 8n, o, a, b, acc)

def seg_v3(+ha: Bool, +hm: Bool, +hb: Bool, +o: Oc, +a: V.Point, +b: V.Point, +acc: List<&2, Sg>) -> List<&2, Sg>:
  seg_pick(Bool.and(Bool.not(Bool.xor(ha, hm)), Bool.not(Bool.xor(hm, hb))), o, a, b, hm, acc)

def seg_vis(+o: Oc, +a: V.Point, +b: V.Point, +acc: List<&2, Sg>) -> List<&2, Sg>:
  seg_v3(hid(o, a), hid(o, mid(a, b, 0.5f64)), hid(o, b), o, a, b, acc)

def pl_segs(ps: List<&2, V.Point>, +o: Oc, +acc: List<&2, Sg>) -> List<&2, Sg>:
  match ps:
    case []: acc
    case +a <> t:
      match t:
        case []: acc
        case +b <> u: pl_segs(b <> u, o, seg_vis(o, a, b, acc))

def ln_hk(+a: V.Point, +b: V.Point, +n: Nat, +k: Nat, +o: Oc) -> Bool:
  hid(o, mid(a, b, F64.div(F64.add(nf(k), 0.5f64), nf(n))))

def ln_emit(+a: V.Point, +b: V.Point, +n: Nat, +s0: Nat, +s1: Nat, +h: Bool, +acc: List<&2, Sg>) -> List<&2, Sg>:
  sg_mk(mid(a, b, F64.div(nf(s0), nf(n))), mid(a, b, F64.div(nf(s1), nf(n))), h) <> acc

def ln_pk(sw: Bool, +a: V.Point, +b: V.Point, +n: Nat, +s0: Nat, +s1: Nat, +h: Bool, +acc: List<&2, Sg>) -> List<&2, Sg>:
  match sw:
    case True{}: ln_emit(a, b, n, s0, s1, h, acc)
    case False{}: acc

def ln_go(c: Nat, +i: Nat, +n: Nat, +a: V.Point, +b: V.Point, +o: Oc, +s0: Nat, +h0: Bool, +acc: List<&2, Sg>) -> List<&2, Sg>:
  match c:
    case 0n: ln_emit(a, b, n, s0, n, h0, acc)
    case 1n+(+k):
      +hk = ln_hk(a, b, n, i, o)
      ln_go(k, Nat.add(i, 1n), n, a, b, o, Bool.pick(Nat, Bool.xor(hk, h0), i, s0), hk, ln_pk(Bool.xor(hk, h0), a, b, n, s0, i, h0, acc))

def ln_s2(+n: Nat, +a: V.Point, +b: V.Point, +o: Oc, +acc: List<&2, Sg>) -> List<&2, Sg>:
  ln_go(Nat.sub(n, 1n), 1n, n, a, b, o, 0n, ln_hk(a, b, n, 0n, o), acc)

def ln_seg(+a: V.Point, +b: V.Point, +o: Oc, +acc: List<&2, Sg>) -> List<&2, Sg>:
  ln_s2(Nat.add(fnat(F64.div(KS.dlen(KS.psub(b, a)), 0.1f64)), 1n), a, b, o, acc)

def ln_w(+v: Vw, +p: V.Point, +q: V.Point, +o: Oc, +acc: List<&2, Sg>) -> List<&2, Sg>:
  ln_seg(prj(v, p), prj(v, q), o, acc)

def arc_pt(+c: V.Point, +r: F64, +t: F64) -> V.Point:
  V.Pt{F64.add(V.pt_x(c), F64.mul(r, KS.fcos(t))), F64.add(V.pt_y(c), F64.mul(r, KS.fsin(t))), V.pt_z(c)}

def arc_go(c: Nat, +i: Nat, +p: V.Point, +r: F64, +t0: F64, +dt: F64, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match c:
    case 0n: acc
    case 1n+(+k): arc_go(k, Nat.add(i, 1n), p, r, t0, dt, arc_pt(p, r, F64.add(t0, F64.mul(nf(i), dt))) <> acc)

def arc_m(+p: V.Point, +r: F64, +t0: F64, +sp: F64, +m: Nat, +o: Oc, +acc: List<&2, Sg>) -> List<&2, Sg>:
  pl_segs(arc_go(Nat.add(m, 1n), 0n, p, r, t0, F64.div(sp, nf(m)), []), o, acc)

def arc(+p: V.Point, +r: F64, +t0: F64, +sp: F64, +o: Oc, +acc: List<&2, Sg>) -> List<&2, Sg>:
  arc_m(p, r, t0, sp, Nat.add(fnat(F64.mul(sp, F64.sqrt(F64.mul(r, 12.5f64)))), 8n), o, acc)

type Hr is Data:
  Hr{ o: V.Point, a: V.Dir, c: F64, r0: F64, r1: F64, z0: F64, z1: F64, e: Nat }

type Th is Data:
  Th{ o: V.Point, a: V.Dir, rc: F64, rr: F64, z0: F64, z1: F64 }

type Tl is Data:
  Tl{ m: List<&2, Sg>, n: List<&2, Sg> }

type Hz is Data:
  Hz{ tt: B.Tb<&2, TS.Tri>, wt: B.Tb<&2, V.Point>, pl: M.Pl }

def zr_m(+z: F64, +m: V.Vec2) -> V.Vec2:
  V.V2{F64.min(V.v2_x(m), z), F64.max(V.v2_y(m), z)}

def zr3(+p: V.Point, +o: V.Point, +a: V.Dir, +m: V.Vec2) -> V.Vec2:
  zr_m(KS.dot(KS.psub(p, o), a), m)

def zr_t(+t: TS.Tri, +wt: B.Tb<&2, V.Point>, +o: V.Point, +a: V.Dir, +m: V.Vec2) -> V.Vec2:
  zr3(pt2(wt, TS.tc(t)), o, a, zr3(pt2(wt, TS.tb(t)), o, a, zr3(pt2(wt, TS.ta(t)), o, a, m)))

def zr_go(c: Nat, +i: Nat, +tt: B.Tb<&2, TS.Tri>, +wt: B.Tb<&2, V.Point>, +o: V.Point, +a: V.Dir, +m: V.Vec2) -> V.Vec2:
  match c:
    case 0n: m
    case 1n+(+k): zr_go(k, Nat.add(i, 1n), tt, wt, o, a, zr_t(B.tb_get(TS.Tri, tt, U32.from_nat(i)), wt, o, a, m))

def ek_of(+dr: F64, +same: Bool, +dz: F64) -> Nat:
  Bool.pick(Nat, F64.is_lt(F64.abs(dr), 1.0e-15f64), Bool.pick(Nat, Bool.not(Bool.xor(same, F64.is_lt(0.0f64, dz))), 2n, 1n), 0n)

def hr_mk3(+o: V.Point, +a: V.Dir, +c: F64, +r0: F64, +r1: F64, +zr: V.Vec2, +e: Nat) -> Hr:
  Hr{o, a, c, F64.min(r0, r1), F64.max(r0, r1), V.v2_x(zr), V.v2_y(zr), e}

def hr_mk2(+w: G.Helicoid, +same: Bool, +ow: V.Point, +aw: V.Dir, +st: Nat, +n: Nat, +tt: B.Tb<&2, TS.Tri>, +wt: B.Tb<&2, V.Point>) -> Hr:
  G.Hx{o, u, v, a, +c, +r0, z0, +dr, +dz} = w
  hr_mk3(ow, aw, c, r0, F64.add(r0, dr), zr_go(n, st, tt, wt, ow, aw, V.V2{1.0e300f64, F64.neg(1.0e300f64)}), ek_of(dr, same, dz))

def hr_mk1(+w: G.Helicoid, +same: Bool, +pl: M.Pl, +st: Nat, +n: Nat, +tt: B.Tb<&2, TS.Tri>, +wt: B.Tb<&2, V.Point>) -> Hr:
  G.Hx{+o, u, v, +a, c, r0, z0, dr, dz} = w
  hr_mk2(w, same, TS.pl_pt(o, pl), M.pl_dir(a, pl), st, n, tt, wt)

def hr_sf(s: G.GVal, +same: Bool, +st: Nat, +n: Nat, +z: Hz, +acc: List<&2, Hr>) -> List<&2, Hr>:
  match s:
    case G.GV_hx{+w}:
      Hz{+tt, +wt, +pl} = z
      hr_mk1(w, same, pl, st, n, tt, wt) <> acc
    case _: acc

def hr_fa(+f: Ty.Face, +st: Nat, +n: Nat, +z: Hz, +acc: List<&2, Hr>) -> List<&2, Hr>:
  Ty.Fa{g, +s, ls, +same, slv, sla} = f
  hr_sf(s, same, st, n, z, acc)

def hr_walk(fs: List<&2, Ty.Face>, ns: List<&2, Nat>, +st: Nat, +z: Hz, +acc: List<&2, Hr>) -> List<&2, Hr>:
  match fs:
    case []: acc
    case +f <> t:
      match ns:
        case []: acc
        case +n <> u: hr_walk(t, u, Nat.add(st, n), z, hr_fa(f, st, n, z, acc))

def sf_hx(s: G.GVal) -> Bool:
  match s:
    case G.GV_hx{w}: True{}
    case _: False{}

def fa_hx(+f: Ty.Face) -> Bool:
  Ty.Fa{g, +s, ls, same, slv, sla} = f
  sf_hx(s)

def rep_b(c: Nat, +b: Bool, +acc: List<&2, Bool>) -> List<&2, Bool>:
  match c:
    case 0n: acc
    case 1n+(+k): rep_b(k, b, b <> acc)

def fhx_go(fs: List<&2, Ty.Face>, ns: List<&2, Nat>, +acc: List<&2, Bool>) -> List<&2, Bool>:
  match fs:
    case []: List.reverse(&2, Bool, acc)
    case +f <> t:
      match ns:
        case []: List.reverse(&2, Bool, acc)
        case +n <> u: fhx_go(t, u, rep_b(n, fa_hx(f), acc))

def fl_c(+a: F64, +b: F64, +nx: B.Sgn) -> B.Sgn:
  Bool.pick(B.Sgn, F64.is_lt(a, b), B.Sn{}, Bool.pick(B.Sgn, F64.is_lt(b, a), B.Sp{}, nx))

def hk_c(+oa: V.Point, +aa: V.Dir, +ca: F64, +ob: V.Point, +ab: V.Dir, +cb: F64) -> B.Sgn:
  fl_c(V.pt_x(oa), V.pt_x(ob), fl_c(V.pt_y(oa), V.pt_y(ob), fl_c(V.pt_z(oa), V.pt_z(ob),
    fl_c(V.dr_x(aa), V.dr_x(ab), fl_c(V.dr_y(aa), V.dr_y(ab), fl_c(V.dr_z(aa), V.dr_z(ab), fl_c(ca, cb, B.Sz{})))))))

def hr_cmp(a: Hr, b: Hr) -> B.Sgn:
  Hr{oa, aa, ca, ra, sa, za, wa, ea} = a
  Hr{ob, ab, cb, rb, sb, zb, wb, eb} = b
  hk_c(oa, aa, ca, ob, ab, cb)

def so_hr(s: B.So<&2, Hr>) -> List<&2, Hr>:
  B.So{ok, xs} = s
  xs

def sgn_z(s: B.Sgn) -> Bool:
  match s:
    case B.Sz{}: True{}
    case _: False{}

def n_max(+a: Nat, +b: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_lt(a, b), b, a)

def hr_join(+a: Hr, +b: Hr) -> Hr:
  Hr{+o, +ax, +c, +r0, +r1, +z0, +z1, +e} = a
  Hr{o2, a2, c2, +s0, +s1, +w0, +w1, +f} = b
  Hr{o, ax, c, F64.min(r0, s0), F64.max(r1, s1), F64.min(z0, w0), F64.max(z1, w1), n_max(e, f)}

def hr_grp(xs: List<&2, Hr>, +cur: Hr, +acc: List<&2, Hr>) -> List<&2, Hr>:
  match xs:
    case []: cur <> acc
    case +h <> t:
      +same = sgn_z(hr_cmp(cur, h))
      hr_grp(t, Bool.pick(Hr, same, hr_join(cur, h), h), Bool.pick(List<&2, Hr>, same, acc, cur <> acc))

def hr_groups(xs: List<&2, Hr>) -> List<&2, Hr>:
  match xs:
    case []: []
    case +h <> t: hr_grp(t, h, [])

def hr_ok(+h: Hr) -> Bool:
  Hr{o, a, c, +r0, +r1, z0, z1, +e} = h
  Bool.and(Nat.is_lt(0n, e), F64.is_lt(1.0e-9f64, F64.sub(r1, r0)))

def hrs_ok(xs: List<&2, Hr>) -> Bool:
  match xs:
    case []: True{}
    case +h <> t: Bool.and(hr_ok(h), hrs_ok(t))

def hr_th(+h: Hr) -> Th:
  Hr{+o, +a, c, +r0, +r1, +z0, +z1, +e} = h
  Th{o, a, Bool.pick(F64, Nat.is_eq(e, 2n), r1, r0), Bool.pick(F64, Nat.is_eq(e, 2n), r0, r1), z0, z1}

def hrs_th(xs: List<&2, Hr>) -> List<&2, Th>:
  match xs:
    case []: []
    case +h <> t: hr_th(h) <> hrs_th(t)

def th_a(+t: Th) -> V.Dir:
  Th{o, +a, rc, rr, z0, z1} = t
  a

def th_rc(+t: Th) -> F64:
  Th{o, a, +rc, rr, z0, z1} = t
  rc

def th_rr(+t: Th) -> F64:
  Th{o, a, rc, +rr, z0, z1} = t
  rr

def tp(+o: V.Point, +a: V.Dir, +z: F64, +w: V.Dir, +s: F64) -> V.Point:
  KS.padd(KS.padd(o, z, a), s, w)

def gen2(+t: Th, +w: V.Dir, +r: F64, +v: Vw, +o: Oc, +acc: List<&2, Sg>) -> List<&2, Sg>:
  Th{+p, +a, rc, rr, +z0, +z1} = t
  ln_w(v, tp(p, a, z0, w, r), tp(p, a, z1, w, r), o, ln_w(v, tp(p, a, z0, w, F64.neg(r)), tp(p, a, z1, w, F64.neg(r)), o, acc))

def lim2(+t: Th, +w: V.Dir, +r: F64, +v: Vw, +o: Oc, +acc: List<&2, Sg>) -> List<&2, Sg>:
  Th{+p, +a, rc, rr, +z0, +z1} = t
  ln_w(v, tp(p, a, z0, w, F64.neg(r)), tp(p, a, z0, w, r), o, ln_w(v, tp(p, a, z1, w, F64.neg(r)), tp(p, a, z1, w, r), o, acc))

def lim_q(sd: Bool, +t: Th, +w: V.Dir, +r: F64, +v: Vw, +o: Oc, +acc: List<&2, Sg>) -> List<&2, Sg>:
  match sd:
    case True{}: lim2(t, w, r, v, o, acc)
    case False{}: acc

def th_side(+sd: Bool, +t: Th, +w: V.Dir, +v: Vw, +o: Oc, +acc: Tl) -> Tl:
  Tl{+m, +n} = acc
  Tl{lim_q(sd, t, w, F64.max(th_rc(t), th_rr(t)), v, o, gen2(t, w, th_rc(t), v, o, m)), gen2(t, w, th_rr(t), v, o, n)}

def th_e2(+c: V.Point, +rc: F64, +rr: F64, +o: Oc, +acc: Tl) -> Tl:
  Tl{+m, +n} = acc
  Tl{arc(c, rc, 0.0f64, KS.two_pi(), o, m), arc(c, rr, KS.half_pi(), F64.mul(3.0f64, KS.half_pi()), o, n)}

def th_cen(+t: Th, +d: V.Dir) -> V.Point:
  Th{+p, +a, rc, rr, +z0, +z1} = t
  KS.padd(p, Bool.pick(F64, F64.is_lt(0.0f64, dd(a, d)), z1, z0), a)

def th_end(+t: Th, +v: Vw, +o: Oc, +acc: Tl) -> Tl:
  th_e2(prj(v, th_cen(t, vw_d(v))), th_rc(t), th_rr(t), o, acc)

def th_v2(en: Bool, +sd: Bool, +t: Th, +v: Vw, +o: Oc, +acc: Tl) -> Tl:
  match en:
    case True{}: th_end(t, v, o, acc)
    case False{}: th_side(sd, t, KS.dunit(KS.cross(th_a(t), vw_d(v))), v, o, acc)

def th_v1(+ad: F64, +t: Th, +v: Vw, +o: Oc, +acc: Tl) -> Tl:
  th_v2(F64.is_lt(0.999999999f64, ad), F64.is_lt(ad, 1.0e-9f64), t, v, o, acc)

def th_view(+t: Th, +v: Vw, +o: Oc, +acc: Tl) -> Tl:
  th_v1(F64.abs(dd(th_a(t), vw_d(v))), t, v, o, acc)

def ths_view(ts: List<&2, Th>, +v: Vw, +o: Oc, +acc: Tl) -> Tl:
  match ts:
    case []: acc
    case +t <> r: ths_view(r, v, o, th_view(t, v, o, acc))

def sh_skip(+w: G.SpiralHelix, +d: V.Dir, +pl: M.Pl) -> Bool:
  G.Sh{o, u, v, +a, r0, kr, z0, +kz} = w
  Bool.or(F64.is_lt(1.0e-12f64, F64.abs(kz)), F64.is_lt(0.999999999f64, F64.abs(dd(M.pl_dir(a, pl), d))))

def cv_skip(c: G.GVal, +d: V.Dir, +pl: M.Pl) -> Bool:
  match c:
    case G.GV_sh{+w}: sh_skip(w, d, pl)
    case _: False{}

def ek_skip(k: Ty.EdgeKind, +d: V.Dir, +pl: M.Pl) -> Bool:
  match k:
    case Ty.EK_curve{+c, dm}: cv_skip(c, d, pl)
    case _: False{}

def ek_deg(k: Ty.EdgeKind) -> Bool:
  match k:
    case Ty.EK_degenerate{}: True{}
    case _: False{}

def ed_poly(+e: Ty.Edge, +s: List<&2, V.Point>, +tv: B.Tb<&2, V.Point>, +d: V.Dir, +pl: M.Pl) -> List<&2, V.Point>:
  Ty.Ed{g, +v0, +v1, +k} = e
  Bool.pick(List<&2, V.Point>, Bool.or(ek_deg(k), ek_skip(k, d, pl)), [], B.tb_get(V.Point, tv, U32.from_nat(Ty.hv_idx(v0))) <> List.append(&2, V.Point, s, [B.tb_get(V.Point, tv, U32.from_nat(Ty.hv_idx(v1)))]))

def sm_ces(cs: List<&2, Ty.HCoedge>, +ct: B.Tb<&2, Ty.Coedge>, +f: Nat, +acc: List<&2, U64>) -> List<&2, U64>:
  match cs:
    case []: acc
    case +h <> t: sm_ces(t, ct, f, U64.add(U64.shln(U64.from_nat(Ty.he_idx(Ty.ce_edge(B.tb_get(Ty.Coedge, ct, U32.from_nat(Ty.hc_idx(h)))))), 32n), U64.from_nat(f)) <> acc)

def sm_lps(ls: List<&2, Ty.HLoop>, +lt: B.Tb<&2, Ty.Loop>, +ct: B.Tb<&2, Ty.Coedge>, +f: Nat, +acc: List<&2, U64>) -> List<&2, U64>:
  match ls:
    case []: acc
    case +h <> t: sm_lps(t, lt, ct, f, sm_ces(Ty.lp_ces(B.tb_get(Ty.Loop, lt, U32.from_nat(Ty.hlp_idx(h)))), ct, f, acc))

def sm_fas(fs: List<&2, Ty.Face>, +lt: B.Tb<&2, Ty.Loop>, +ct: B.Tb<&2, Ty.Coedge>, +f: Nat, +acc: List<&2, U64>) -> List<&2, U64>:
  match fs:
    case []: acc
    case +x <> t: sm_fas(t, lt, ct, Nat.add(f, 1n), sm_lps(Ty.fa_loops(x), lt, ct, f, acc))

def sm_is(xs: List<&2, Nat>, +i: Nat) -> Bool:
  match xs:
    case []: False{}
    case +h <> t: Nat.is_eq(h, i)

def sm_uq(fuel: Nat, xs: List<&2, Nat>, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match fuel:
    case 0n: acc
    case 1n+(+k):
      match xs:
        case []: acc
        case +h <> t: sm_uq(k, t, Bool.pick(List<&2, Nat>, sm_is(acc, h), acc, h <> acc))

def sm_of3(+ds: List<&2, Nat>) -> List<&2, Nat>:
  List.reverse(&2, Nat, sm_uq(Nat.add(List.length(&2, Nat, ds), 1n), List.reverse(&2, Nat, ds), []))

type Ec is Data:
  Ec{ et: B.Tb<&2, Ty.Edge>, ft: B.Tb<&2, Ty.Face>, vt: B.Tb<&2, V.Point> }

type Ecl is Data:
  Ecl{ sk: List<&2, Nat>, tn: List<&2, Nat>, fp: List<&2, U64> }

def f_eq(+x: F64, +y: F64) -> Bool:
  F64.is_le(F64.abs(F64.sub(x, y)), F64.mul(1.0e-9f64, F64.add(1.0f64, F64.abs(x))))

def an_k(+k: U64) -> Bool:
  Bool.and(U64.is_le(1u64, k), U64.is_le(k, 5u64))

def ec_same(+a: KS.SF, +b: KS.SF) -> Bool:
  Bool.and(U64.is_eq(KS.sf_kind(a), KS.sf_kind(b)), Bool.and(f_eq(KS.sf_r(a), KS.sf_r(b)), f_eq(KS.sf_r2(a), KS.sf_r2(b))))

def ec_smooth(+a: KS.SF, +b: KS.SF, +p: V.Point) -> Bool:
  F64.is_lt(0.999999999f64, F64.abs(KS.dot(KS.sf_normal(a, p), KS.sf_normal(b, p))))

def ec_c4(an: Bool, +a: KS.SF, +b: KS.SF, +p: V.Point) -> Nat:
  match an:
    case False{}: 0n
    case True{}: Bool.pick(Nat, ec_smooth(a, b, p), Bool.pick(Nat, ec_same(a, b), 1n, 2n), 0n)

def ec_c3(+a: KS.SF, +b: KS.SF, +p: V.Point) -> Nat:
  ec_c4(Bool.and(an_k(KS.sf_kind(a)), an_k(KS.sf_kind(b))), a, b, p)

def fsf(+ft: B.Tb<&2, Ty.Face>, +f: Nat) -> KS.SF:
  KS.sf_of(Ty.fa_surf(B.tb_get(Ty.Face, ft, U32.from_nat(f))))

def ec_cls(+e: Nat, +fa: Nat, +fb: Nat, +c: Ec) -> Nat:
  Ec{+et, +ft, +vt} = c
  Bool.pick(Nat, Nat.is_eq(fa, fb), 1n, ec_c3(fsf(ft, fa), fsf(ft, fb), B.tb_get(V.Point, vt, U32.from_nat(Ty.hv_idx(Ty.ed_v0(B.tb_get(Ty.Edge, et, U32.from_nat(e))))))))

def fkey(+a: Nat, +b: Nat) -> U64:
  U64.add(U64.shln(U64.from_nat(a), 32n), U64.from_nat(b))

def ec_add(+k: Nat, +e: Nat, +fa: Nat, +fb: Nat, +acc: Ecl) -> Ecl:
  Ecl{+sk, +tn, +fp} = acc
  Ecl{Bool.pick(List<&2, Nat>, Nat.is_eq(k, 1n), e <> sk, sk), Bool.pick(List<&2, Nat>, Nat.is_eq(k, 2n), e <> tn, tn),
    Bool.pick(List<&2, U64>, Bool.and(Nat.is_lt(0n, k), Bool.not(Nat.is_eq(fa, fb))), fkey(fa, fb) <> fkey(fb, fa) <> fp, fp)}

def k_hi(+a: U64) -> Nat:
  U64.to_nat(U64.shrn(a, 32n))

def k_lo(+a: U64) -> Nat:
  U64.to_nat(U64.and(a, 4294967295u64))

def ec_q(same: Bool, +a: U64, +b: U64, +c: Ec, +acc: Ecl) -> Ecl:
  match same:
    case False{}: acc
    case True{}: ec_add(ec_cls(k_hi(a), k_lo(a), k_lo(b), c), k_hi(a), k_lo(a), k_lo(b), acc)

def ec_go(fuel: Nat, xs: List<&2, U64>, +c: Ec, +acc: Ecl) -> Ecl:
  match fuel:
    case 0n: acc
    case 1n+(+k):
      match xs:
        case []: acc
        case +a <> +t:
          match t:
            case []: acc
            case +b <> +u:
              +same = Nat.is_eq(k_hi(a), k_hi(b))
              ec_go(k, Bool.pick(List<&2, U64>, same, u, b <> u), c, ec_q(same, a, b, c, acc))

def ecl_fin(+r: Ecl) -> Ecl:
  Ecl{+sk, +tn, +fp} = r
  Ecl{sm_of3(sk), sm_of3(tn), fp}

def ecl_ks(+ks: List<&2, U64>, +c: Ec) -> Ecl:
  ecl_fin(ec_go(Nat.add(List.length(&2, U64, ks), 1n), ks, c, Ecl{[], [], []}))

def ecl_of(+br: Ty.Brep) -> Ecl:
  ecl_ks(so_u(B.msort(~U64, ~u_lt, sm_fas(Ty.brep_fas(br), B.tb_of(Ty.Loop, Ty.brep_lps(br), Ty.lp_dflt()), B.tb_of(Ty.Coedge, Ty.brep_ces(br), Ty.ce_dflt()), 0n, []))),
    Ec{B.tb_of(Ty.Edge, Ty.brep_es(br), Ty.ed_dflt()), B.tb_of(Ty.Face, Ty.brep_fas(br), Ty.fa_dflt()), B.tb_of(V.Point, TS.vx_pts(Ty.brep_vs(br)), V.Pt{0.0f64, 0.0f64, 0.0f64})})

def ecl_sk(+r: Ecl) -> List<&2, Nat>:
  Ecl{+sk, tn, fp} = r
  sk

def ecl_tn(+r: Ecl) -> List<&2, Nat>:
  Ecl{sk, +tn, fp} = r
  tn

def ecl_fp(+r: Ecl) -> List<&2, U64>:
  Ecl{sk, tn, +fp} = r
  fp

def fj_of(+fp: List<&2, U64>, +nf: Nat) -> B.Tb<&2, List<&2, Nat>>:
  B.tb_of(List<&2, Nat>, List.reverse(&2, List<&2, Nat>, gr_run(so_u(B.msort(~U64, ~u_lt, fp)), nf)), [])

def nat_in(xs: List<&2, Nat>, +b: Nat) -> Bool:
  match xs:
    case []: False{}
    case +h <> t: Bool.or(Nat.is_eq(h, b), nat_in(t, b))

def f_join(+fj: B.Tb<&2, List<&2, Nat>>, +a: Nat, +b: Nat) -> Bool:
  Bool.or(Nat.is_eq(a, b), nat_in(B.tb_get(List<&2, Nat>, fj, U32.from_nat(a)), b))

def sm_pop(xs: List<&2, Nat>, +i: Nat) -> List<&2, Nat>:
  match xs:
    case []: []
    case +h <> +t: Bool.pick(List<&2, Nat>, Nat.is_eq(h, i), t, h <> t)

def vo_k(k: Bool, +g: Sg, +acc: List<&2, Sg>) -> List<&2, Sg>:
  match k:
    case True{}: g <> acc
    case False{}: acc

def sg_vo(gs: List<&2, Sg>, +acc: List<&2, Sg>) -> List<&2, Sg>:
  match gs:
    case []: acc
    case +g <> t:
      Sg{ax, ay, bx, by, +h} = g
      sg_vo(t, vo_k(Bool.not(h), g, acc))

def tl_m(+t: Tl) -> List<&2, Sg>:
  Tl{+m, n} = t
  m

def tl_n(+t: Tl) -> List<&2, Sg>:
  Tl{m, +n} = t
  n

def ed_th(th: Bool, +gs: List<&2, Sg>, +acc: Tl) -> Tl:
  match th:
    case True{}: Tl{tl_m(acc), sg_vo(gs, tl_n(acc))}
    case False{}: Tl{List.append(&2, Sg, gs, tl_m(acc)), tl_n(acc)}

def ed_add(sk: Bool, +th: Bool, +e: Ty.Edge, +s: List<&2, V.Point>, +tv: B.Tb<&2, V.Point>, +v: Vw, +pl: M.Pl, +o: Oc, +acc: Tl) -> Tl:
  match sk:
    case True{}: acc
    case False{}: ed_th(th, pl_segs(prjs(wpts(ed_poly(e, s, tv, vw_d(v), pl), pl), v), o, []), acc)

def eds_segs(es: List<&2, Ty.Edge>, ss: List<&2, List<&2, V.Point>>, +i: Nat, +sm: List<&2, Nat>, +tn: List<&2, Nat>, +tv: B.Tb<&2, V.Point>, +v: Vw, +pl: M.Pl, +o: Oc, +acc: Tl) -> Tl:
  match es:
    case []: acc
    case +e <> t:
      match ss:
        case []: acc
        case +s <> u: eds_segs(t, u, Nat.add(i, 1n), sm_pop(sm, i), sm_pop(tn, i), tv, v, pl, o, ed_add(sm_is(sm, i), sm_is(tn, i), e, s, tv, v, pl, o, acc))

type Ei is Data:
  Ei{ e: Ty.Edge, s: List<&2, V.Point>, a: Bool, b: Bool }

type Ectx is Data:
  Ectx{ tv: B.Tb<&2, V.Point>, v: Vw, pl: M.Pl, o: Oc }

def ei_list(es: List<&2, Ty.Edge>, ss: List<&2, List<&2, V.Point>>, +i: Nat, +sm: List<&2, Nat>, +tn: List<&2, Nat>) -> List<&2, Ei>:
  match es:
    case []: []
    case +e <> t:
      match ss:
        case []: []
        case +s <> u: Ei{e, s, sm_is(sm, i), sm_is(tn, i)} <> ei_list(t, u, Nat.add(i, 1n), sm_pop(sm, i), sm_pop(tn, i))

def ei_one2(+c: Ectx, +x: Ei) -> Tl:
  Ectx{+tv, +v, +pl, +o} = c
  Ei{+e, +s, +a, +b} = x
  ed_add(a, b, e, s, tv, v, pl, o, Tl{[], []})

def ei_one(c: Ectx, x: Ei) -> Tl:
  ei_one2(c, x)

def tl_cat(xs: List<&2, Tl>, +acc: Tl) -> Tl:
  match xs:
    case []: acc
    case +t <> u: tl_cat(u, Tl{List.append(&2, Sg, tl_m(t), tl_m(acc)), List.append(&2, Sg, tl_n(t), tl_n(acc))})

def eds_par(es: List<&2, Ty.Edge>, ss: List<&2, List<&2, V.Point>>, +sm: List<&2, Nat>, +tn: List<&2, Nat>, +tv: B.Tb<&2, V.Point>, +v: Vw, +pl: M.Pl, +o: Oc, +acc: Tl) -> Tl:
  tl_cat(B.pmap_g(~Ei, ~Ectx, ~Tl, ~ei_one, 8, Ectx{tv, v, pl, o}, ei_list(es, ss, 0n, sm, tn)), acc)

type Ek is Data:
  Ek{ k: U64, t: Nat }

def ek_cmp(a: Ek, b: Ek) -> B.Sgn:
  Ek{ka, ta} = a
  Ek{kb, tb} = b
  u_lt2(ka, kb)

def ekey(+i: Nat, +j: Nat) -> U64:
  Bool.pick(U64, Nat.is_lt(i, j), U64.add(U64.shln(U64.from_nat(i), 32n), U64.from_nat(j)), U64.add(U64.shln(U64.from_nat(j), 32n), U64.from_nat(i)))

def tri_eks(+t: TS.Tri, +i: Nat, +acc: List<&2, Ek>) -> List<&2, Ek>:
  Ek{ekey(TS.ta(t), TS.tb(t)), i} <> Ek{ekey(TS.tb(t), TS.tc(t)), i} <> Ek{ekey(TS.tc(t), TS.ta(t)), i} <> acc

def tris_eks(ts: List<&2, TS.Tri>, +i: Nat, +acc: List<&2, Ek>) -> List<&2, Ek>:
  match ts:
    case []: acc
    case +t <> r: tris_eks(r, Nat.add(i, 1n), tri_eks(t, i, acc))

def so_ek(s: B.So<&2, Ek>) -> List<&2, Ek>:
  B.So{ok, xs} = s
  xs

def rep_n(c: Nat, +f: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match c:
    case 0n: acc
    case 1n+(+k): rep_n(k, f, f <> acc)

def fid_go(ns: List<&2, Nat>, +f: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match ns:
    case []: List.reverse(&2, Nat, acc)
    case +n <> t: fid_go(t, Nat.add(f, 1n), rep_n(n, f, acc))

type Sx is Data:
  Sx{ wt: B.Tb<&2, V.Point>, tt: B.Tb<&2, TS.Tri>, ft: B.Tb<&2, Nat>, hx: B.Tb<&2, Bool>, th: List<&2, Th>, bc: List<&2, V.Point>, pos: Bool, sm: Ecl, fj: B.Tb<&2, List<&2, Nat>> }

def tnorm3(+a: V.Point, +b: V.Point, +c: V.Point) -> V.Dir:
  KS.cross(KS.psub(b, a), KS.psub(c, a))

def tnorm_t(+t: TS.Tri, +wt: B.Tb<&2, V.Point>) -> V.Dir:
  tnorm3(pt2(wt, TS.ta(t)), pt2(wt, TS.tb(t)), pt2(wt, TS.tc(t)))

def tnorm(+x: Sx, +ti: Nat) -> V.Dir:
  Sx{+wt, +tt, ft, hx, th, bc, pos, sm, fj} = x
  tnorm_t(B.tb_get(TS.Tri, tt, U32.from_nat(ti)), wt)

def silh(+x: Sx, +t1: Nat, +t2: Nat, +d: V.Dir) -> Bool:
  Sx{wt, tt, +ft, +hx, th, bc, pos, sm, +fj} = x
  Bool.and(Bool.and(Bool.not(B.tb_get(Bool, hx, U32.from_nat(t1))), f_join(fj, B.tb_get(Nat, ft, U32.from_nat(t1)), B.tb_get(Nat, ft, U32.from_nat(t2)))),
    Bool.xor(F64.is_lt(0.0f64, dd(tnorm(x, t1), d)), F64.is_lt(0.0f64, dd(tnorm(x, t2), d))))

def sil_add(on: Bool, +ka: U64, +pt: B.Tb<&2, V.Point>, +o: Oc, +acc: List<&2, Sg>) -> List<&2, Sg>:
  match on:
    case True{}: seg_vis(o, pt2(pt, U64.to_nat(U64.shrn(ka, 32n))), pt2(pt, U64.to_nat(U64.and(ka, 4294967295u64))), acc)
    case False{}: acc

def sil_ok(same: Bool, +x: Sx, +ta: Nat, +tb: Nat, +d: V.Dir) -> Bool:
  match same:
    case True{}: silh(x, ta, tb, d)
    case False{}: False{}

def ek_k(+e: Ek) -> U64:
  Ek{+k, t} = e
  k

def ek_t(+e: Ek) -> Nat:
  Ek{k, +t} = e
  t

def sil_go(fuel: Nat, ks: List<&2, Ek>, +x: Sx, +v: Vw, +pt: B.Tb<&2, V.Point>, +o: Oc, +acc: List<&2, Sg>) -> List<&2, Sg>:
  match fuel:
    case 0n: acc
    case 1n+(+f):
      match ks:
        case []: acc
        case +a <> +t:
          match t:
            case []: acc
            case +b <> +u:
              +same = U64.is_eq(ek_k(a), ek_k(b))
              sil_go(f, Bool.pick(List<&2, Ek>, same, u, b <> u), x, v, pt, o, sil_add(sil_ok(same, x, ek_t(a), ek_t(b), vw_d(v)), ek_k(a), pt, o, acc))

type Dv is Data:
  Dv{ v: Vw, ox: F64, oy: F64, nm: String, sx: F64, sy: F64 }

def f3(+x: F64) -> String:
  S.f_show(F64.div(KS.f_round(F64.mul(x, 1000.0f64)), 1000.0f64))

def f6(+x: F64) -> String:
  S.f_show(F64.div(KS.f_round(F64.mul(x, 1000000.0f64)), 1000000.0f64))

def dx_line(+l: String, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> String:
  "0\nLINE\n8\n" ++ l ++ "\n10\n" ++ f6(ax) ++ "\n20\n" ++ f6(ay) ++ "\n30\n0.0\n11\n" ++ f6(bx) ++ "\n21\n" ++ f6(by) ++ "\n31\n0.0\n"

def dx_text(+x: F64, +y: F64, +h: F64, +s: String) -> String:
  "0\nTEXT\n8\nTEXT\n10\n" ++ f6(x) ++ "\n20\n" ++ f6(y) ++ "\n30\n0.0\n40\n" ++ f6(h) ++ "\n1\n" ++ s ++ "\n"

def sg_dx(+g: Sg, +ox: F64, +oy: F64, +lv: String) -> String:
  Sg{+ax, +ay, +bx, +by, +h} = g
  dx_line(Bool.pick(String, h, "HIDDEN", lv), F64.add(ax, ox), F64.add(ay, oy), F64.add(bx, ox), F64.add(by, oy))

def sgs_dx(gs: List<&2, Sg>, +ox: F64, +oy: F64, +lv: String) -> String:
  match gs:
    case []: ""
    case +g <> t: sg_dx(g, ox, oy, lv) ++ sgs_dx(t, ox, oy, lv)

def sg_h(gs: List<&2, Sg>, +acc: Nat) -> Nat:
  match gs:
    case []: acc
    case +g <> t:
      Sg{ax, ay, bx, by, +h} = g
      sg_h(t, Bool.pick(Nat, h, Nat.add(acc, 1n), acc))

type Iv is Data:
  Iv{ t0: F64, t1: F64, ax: F64, ay: F64, bx: F64, by: F64 }

type Cs is Data:
  Cs{ qx: F64, qy: F64, of: F64, h: Nat, iv: Iv }

type St is Data:
  St{ hs: List<&2, Iv>, vs: List<&2, Iv>, acc: List<&2, Iv> }

def iv_t0(+i: Iv) -> F64:
  Iv{+t0, t1, ax, ay, bx, by} = i
  t0

def iv_t1(+i: Iv) -> F64:
  Iv{t0, +t1, ax, ay, bx, by} = i
  t1

def iv_lo(+h: Iv, +v: Iv) -> Iv:
  Iv{+t0, t1, +ax, +ay, bx, by} = h
  Iv{+s0, s1, +cx, +cy, dx, dy} = v
  Iv{t0, s0, ax, ay, cx, cy}

def iv_hi(+h: Iv, +v: Iv) -> Iv:
  Iv{t0, +t1, ax, ay, +bx, +by} = h
  Iv{s0, +s1, cx, cy, +dx, +dy} = v
  Iv{s1, t1, dx, dy, bx, by}

def iv_ext(+a: Iv, +b: Iv) -> Iv:
  Iv{+t0, t1, +ax, +ay, bx, by} = a
  Iv{s0, +s1, cx, cy, +dx, +dy} = b
  Iv{t0, s1, ax, ay, dx, dy}

def iv_join(+a: Iv, +b: Iv) -> Iv:
  Bool.pick(Iv, F64.is_lt(iv_t1(a), iv_t1(b)), iv_ext(a, b), a)

def iv_mg(xs: List<&2, Iv>, +cur: Iv, +acc: List<&2, Iv>) -> List<&2, Iv>:
  match xs:
    case []: List.reverse(&2, Iv, cur <> acc)
    case +h <> t:
      +j = F64.is_lt(iv_t0(h), F64.add(iv_t1(cur), 1.0e-9f64))
      iv_mg(t, Bool.pick(Iv, j, iv_join(cur, h), h), Bool.pick(List<&2, Iv>, j, acc, cur <> acc))

def iv_merge(xs: List<&2, Iv>) -> List<&2, Iv>:
  match xs:
    case []: []
    case +h <> t: iv_mg(t, h, [])

def iv_st3(+bf: Bool, +af: Bool, +rr: Bool, +lp: Bool, +h: Iv, +ht: List<&2, Iv>, +v: Iv, +vt: List<&2, Iv>, +acc: List<&2, Iv>) -> St:
  St{Bool.pick(List<&2, Iv>, bf, h <> ht, Bool.pick(List<&2, Iv>, Bool.or(af, Bool.not(rr)), ht, iv_hi(h, v) <> ht)),
    Bool.pick(List<&2, Iv>, Bool.or(bf, Bool.and(Bool.not(af), rr)), vt, v <> vt),
    Bool.pick(List<&2, Iv>, bf, acc, Bool.pick(List<&2, Iv>, af, h <> acc, Bool.pick(List<&2, Iv>, lp, iv_lo(h, v) <> acc, acc)))}

def iv_stp(+h: Iv, +ht: List<&2, Iv>, +v: Iv, +vt: List<&2, Iv>, +acc: List<&2, Iv>) -> St:
  iv_st3(F64.is_lt(iv_t1(v), F64.add(iv_t0(h), 1.0e-9f64)), F64.is_lt(F64.sub(iv_t1(h), 1.0e-9f64), iv_t0(v)),
    F64.is_lt(iv_t1(v), F64.sub(iv_t1(h), 1.0e-9f64)), F64.is_lt(F64.add(iv_t0(h), 1.0e-9f64), iv_t0(v)), h, ht, v, vt, acc)

def st_acc(+st: St) -> List<&2, Iv>:
  St{hs, vs, +acc} = st
  acc

def iv_sub(f: Nat, st: St) -> List<&2, Iv>:
  match f:
    case 0n: st_acc(st)
    case 1n+(+k):
      St{hs, vs, +acc} = st
      match hs:
        case []: acc
        case +h <> ht:
          match vs:
            case []: List.append(&2, Iv, List.reverse(&2, Iv, h <> ht), acc)
            case +v <> vt: iv_sub(k, iv_stp(h, ht, v, vt, acc))

def sg_keep(k: Bool, +g: Sg, +acc: List<&2, Sg>) -> List<&2, Sg>:
  match k:
    case True{}: g <> acc
    case False{}: acc

def ivs_sg(xs: List<&2, Iv>, +h: Bool, +acc: List<&2, Sg>) -> List<&2, Sg>:
  match xs:
    case []: acc
    case +i <> t:
      Iv{+t0, +t1, +ax, +ay, +bx, +by} = i
      ivs_sg(t, h, sg_keep(F64.is_lt(1.0e-5f64, F64.sub(t1, t0)), Sg{ax, ay, bx, by, h}, acc))

def iv_mrg(fuel: Nat, a: List<&2, Iv>, b: List<&2, Iv>, +acc: List<&2, Iv>) -> List<&2, Iv>:
  match fuel:
    case 0n: acc
    case 1n+(+k):
      match a:
        case []: List.append(&2, Iv, List.reverse(&2, Iv, b), acc)
        case +x <> +at:
          match b:
            case []: List.append(&2, Iv, List.reverse(&2, Iv, x <> at), acc)
            case +y <> +bt:
              +lt = F64.is_le(iv_t0(x), iv_t0(y))
              iv_mrg(k, Bool.pick(List<&2, Iv>, lt, at, x <> at), Bool.pick(List<&2, Iv>, lt, y <> bt, bt), Bool.pick(Iv, lt, x, y) <> acc)

def iv_union(+a: List<&2, Iv>, +b: List<&2, Iv>) -> List<&2, Iv>:
  iv_merge(List.reverse(&2, Iv, iv_mrg(Nat.add(Nat.add(List.length(&2, Iv, a), List.length(&2, Iv, b)), 1n), a, b, [])))

def iv_minus(+a: List<&2, Iv>, +b: List<&2, Iv>) -> List<&2, Iv>:
  List.reverse(&2, Iv, iv_sub(Nat.add(Nat.add(List.length(&2, Iv, a), List.length(&2, Iv, b)), 1n), St{a, b, []}))

def grp_o3(+mv: List<&2, Iv>, +mt: List<&2, Iv>, +mh: List<&2, Iv>, +acc: Tl) -> Tl:
  Tl{ivs_sg(mv, False{}, ivs_sg(iv_minus(mh, iv_union(mv, mt)), True{}, tl_m(acc))), ivs_sg(mt, False{}, tl_n(acc))}

def grp_o2(+mv: List<&2, Iv>, +mt: List<&2, Iv>, +mh: List<&2, Iv>, +acc: Tl) -> Tl:
  grp_o3(mv, iv_minus(mt, mv), mh, acc)

def grp_out(+vs: List<&2, Iv>, +ts: List<&2, Iv>, +hs: List<&2, Iv>, +acc: Tl) -> Tl:
  grp_o2(iv_merge(List.reverse(&2, Iv, vs)), iv_merge(List.reverse(&2, Iv, ts)), iv_merge(List.reverse(&2, Iv, hs)), acc)

def grp_fl(same: Bool, +vs: List<&2, Iv>, +ts: List<&2, Iv>, +hs: List<&2, Iv>, +acc: Tl) -> Tl:
  match same:
    case True{}: acc
    case False{}: grp_out(vs, ts, hs, acc)

def cs_h(+c: Cs) -> Nat:
  Cs{qx, qy, of, +h, iv} = c
  h

def cs_iv(+c: Cs) -> Iv:
  Cs{qx, qy, of, h, +iv} = c
  iv

def cs_same(+a: Cs, +b: Cs) -> Bool:
  Cs{+qx, +qy, +of, h, iv} = a
  Cs{+rx, +ry, +og, g, jv} = b
  Bool.and(Bool.and(Bool.not(Bool.or(F64.is_lt(qx, rx), F64.is_lt(rx, qx))), Bool.not(Bool.or(F64.is_lt(qy, ry), F64.is_lt(ry, qy)))),
    Bool.not(Bool.or(F64.is_lt(of, og), F64.is_lt(og, of))))

def add_k(+w: Nat, +k: Nat, +i: Iv, +xs: List<&2, Iv>) -> List<&2, Iv>:
  Bool.pick(List<&2, Iv>, Nat.is_eq(w, k), i <> xs, xs)

def cs_walk(xs: List<&2, Cs>, +k: Cs, +vs: List<&2, Iv>, +ts: List<&2, Iv>, +hs: List<&2, Iv>, +acc: Tl) -> Tl:
  match xs:
    case []: grp_out(vs, ts, hs, acc)
    case +c <> t:
      +same = cs_same(k, c)
      cs_walk(t, c, add_k(0n, cs_h(c), cs_iv(c), Bool.pick(List<&2, Iv>, same, vs, [])), add_k(1n, cs_h(c), cs_iv(c), Bool.pick(List<&2, Iv>, same, ts, [])),
        add_k(2n, cs_h(c), cs_iv(c), Bool.pick(List<&2, Iv>, same, hs, [])), grp_fl(same, vs, ts, hs, acc))

def cs_cmp(a: Cs, b: Cs) -> B.Sgn:
  Cs{+qx, +qy, +of, h, +iv} = a
  Cs{+rx, +ry, +og, g, +jv} = b
  fl_c(qx, rx, fl_c(qy, ry, fl_c(of, og, fl_c(iv_t0(iv), iv_t0(jv), B.Sz{}))))

def so_cs(s: B.So<&2, Cs>) -> List<&2, Cs>:
  B.So{ok, xs} = s
  xs

def qz(+x: F64, +k: F64) -> F64:
  F64.div(KS.f_round(F64.mul(x, k)), k)

def cs_f(+ux: F64, +uy: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64, +h: Nat) -> Cs:
  Cs{qz(ux, 1.0e7f64), qz(uy, 1.0e7f64), qz(F64.sub(F64.mul(ux, ay), F64.mul(uy, ax)), 1.0e6f64), h,
    Iv{F64.add(F64.mul(ux, ax), F64.mul(uy, ay)), F64.add(F64.mul(ux, bx), F64.mul(uy, by)), ax, ay, bx, by}}

def cs_l(+l: F64, +dx: F64, +dy: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64, +h: Nat) -> Cs:
  cs_f(F64.div(dx, l), F64.div(dy, l), ax, ay, bx, by, h)

def cs_d(+ax: F64, +ay: F64, +bx: F64, +by: F64, +h: Nat) -> Cs:
  cs_l(F64.sqrt(F64.add(F64.mul(F64.sub(bx, ax), F64.sub(bx, ax)), F64.mul(F64.sub(by, ay), F64.sub(by, ay)))), F64.sub(bx, ax), F64.sub(by, ay), ax, ay, bx, by, h)

def cs_o(sw: Bool, +ax: F64, +ay: F64, +bx: F64, +by: F64, +h: Nat) -> Cs:
  match sw:
    case True{}: cs_d(bx, by, ax, ay, h)
    case False{}: cs_d(ax, ay, bx, by, h)

def cs_sw(+dx: F64, +dy: F64) -> Bool:
  Bool.or(F64.is_lt(dx, F64.neg(1.0e-12f64)), Bool.and(F64.is_lt(F64.abs(dx), 1.0e-12f64), F64.is_lt(dy, 0.0f64)))

def sg_len(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> F64:
  F64.add(F64.abs(F64.sub(bx, ax)), F64.abs(F64.sub(by, ay)))

def cs_add(dg: Bool, +ax: F64, +ay: F64, +bx: F64, +by: F64, +h: Nat, +acc: List<&2, Cs>) -> List<&2, Cs>:
  match dg:
    case True{}: acc
    case False{}: cs_o(cs_sw(F64.sub(bx, ax), F64.sub(by, ay)), ax, ay, bx, by, h) <> acc

def cs_all(gs: List<&2, Sg>, +th: Bool, +acc: List<&2, Cs>) -> List<&2, Cs>:
  match gs:
    case []: acc
    case +g <> t:
      Sg{+ax, +ay, +bx, +by, +h} = g
      cs_all(t, th, cs_add(F64.is_lt(sg_len(ax, ay, bx, by), 1.0e-5f64), ax, ay, bx, by, Bool.pick(Nat, h, 2n, Bool.pick(Nat, th, 1n, 0n)), acc))

def sg_m2(xs: List<&2, Cs>) -> Tl:
  match xs:
    case []: Tl{[], []}
    case +c <> t: cs_walk(t, c, add_k(0n, cs_h(c), cs_iv(c), []), add_k(1n, cs_h(c), cs_iv(c), []), add_k(2n, cs_h(c), cs_iv(c), []), Tl{[], []})

def sg_merge(+gs: List<&2, Sg>, +tn: List<&2, Sg>) -> Tl:
  sg_m2(so_cs(B.msort(~Cs, ~cs_cmp, cs_all(gs, False{}, cs_all(tn, True{}, [])))))

def dims_h2(+x0: F64, +x1: F64, +y0: F64, +yd: F64, +w: F64) -> String:
  dx_line("DIM", x0, F64.sub(y0, 1.0f64), x0, F64.sub(yd, 1.5f64)) ++ dx_line("DIM", x1, F64.sub(y0, 1.0f64), x1, F64.sub(yd, 1.5f64)) ++
    dx_line("DIM", x0, yd, x1, yd) ++ dx_text(F64.mul(0.5f64, F64.add(x0, x1)), F64.add(yd, 0.8f64), 2.5f64, f3(w))

def dims_v2(+x0: F64, +y0: F64, +y1: F64, +xd: F64, +h: F64) -> String:
  dx_line("DIM", F64.sub(x0, 1.0f64), y0, F64.sub(xd, 1.5f64), y0) ++ dx_line("DIM", F64.sub(x0, 1.0f64), y1, F64.sub(xd, 1.5f64), y1) ++
    dx_line("DIM", xd, y0, xd, y1) ++ dx_text(F64.sub(xd, 10.0f64), F64.mul(0.5f64, F64.add(y0, y1)), 2.5f64, f3(h))

def dims4(+x0: F64, +x1: F64, +y0: F64, +y1: F64, +w: F64, +h: F64) -> String:
  dims_h2(x0, x1, y0, F64.sub(y0, 6.0f64), w) ++ dims_v2(x0, y0, y1, F64.sub(x0, 6.0f64), h)

def dims(+b: Bx, +ox: F64, +oy: F64, +w: F64, +h: F64) -> String:
  dims4(F64.add(bx_x0(b), ox), F64.add(bx_x1(b), ox), F64.add(bx_y0(b), oy), F64.add(bx_y1(b), oy), w, h)

type Vr is Data:
  Vr{ s: String, nv: Nat, nh: Nat }

def sx_tt(+x: Sx) -> B.Tb<&2, TS.Tri>:
  Sx{wt, +tt, ft, hx, th, bc, pos, sm, fj} = x
  tt

def sx_hx(+x: Sx) -> B.Tb<&2, Bool>:
  Sx{wt, tt, ft, +hx, th, bc, pos, sm, fj} = x
  hx

def sx_th(+x: Sx) -> List<&2, Th>:
  Sx{wt, tt, ft, hx, +th, bc, pos, sm, fj} = x
  th

def sx_bc(+x: Sx) -> List<&2, V.Point>:
  Sx{wt, tt, ft, hx, th, +bc, pos, sm, fj} = x
  bc

def sx_pos(+x: Sx) -> Bool:
  Sx{wt, tt, ft, hx, th, bc, +pos, sm, fj} = x
  pos

def sx_sm(+x: Sx) -> List<&2, Nat>:
  Sx{wt, tt, ft, hx, th, bc, pos, +sm, fj} = x
  ecl_sk(sm)

def sx_tn(+x: Sx) -> List<&2, Nat>:
  Sx{wt, tt, ft, hx, th, bc, pos, +sm, fj} = x
  ecl_tn(sm)

type Vq is Data:
  Vq{ v: Vw, nm: String, ox: F64, oy: F64, w: F64, h: F64 }

def view_f3(+gs: List<&2, Sg>, +tn: List<&2, Sg>, +b: Bx, +q: Vq, +sx: F64, +sy: F64, +nh: Nat) -> Vr:
  Vq{v, +nm, +ox, +oy, +w, +h} = q
  Vr{sgs_dx(gs, sx, sy, "VISIBLE") ++ sgs_dx(tn, sx, sy, "THIN") ++ dims(b, sx, sy, w, h) ++ dx_text(ox, F64.sub(oy, 14.0f64), 3.5f64, nm),
    Nat.sub(Nat.add(List.length(&2, Sg, gs), List.length(&2, Sg, tn)), nh), nh}

def vq_ox(+q: Vq) -> F64:
  Vq{v, nm, +ox, oy, w, h} = q
  ox

def vq_oy(+q: Vq) -> F64:
  Vq{v, nm, ox, +oy, w, h} = q
  oy

def vq_v(+q: Vq) -> Vw:
  Vq{+v, nm, ox, oy, w, h} = q
  v

def view_m(+gs: List<&2, Sg>, +tn: List<&2, Sg>, +b: Bx, +q: Vq) -> Vr:
  view_f3(gs, tn, b, q, F64.sub(vq_ox(q), bx_x0(b)), F64.sub(vq_oy(q), bx_y0(b)), sg_h(gs, sg_h(tn, 0n)))

def view_mt(+t: Tl, +b: Bx, +q: Vq) -> Vr:
  view_m(tl_m(t), tl_n(t), b, q)

def view_fin(+gs: List<&2, Sg>, +tn: List<&2, Sg>, +b: Bx, +q: Vq) -> Vr:
  view_mt(sg_merge(gs, tn), b, q)

def view_g5(+el: Tl, +o: Oc, +pt: B.Tb<&2, V.Point>, +q: Vq, +x: Sx, +ks: List<&2, Ek>) -> Vr:
  Tl{+em, +en} = el
  view_fin(sil_go(Nat.add(List.length(&2, Ek, ks), 1n), ks, x, vq_v(q), pt, o, em), en, bx_ps(prjs(sx_bc(x), vq_v(q)), bx0()), q)

def view_g4(+tl: Tl, +o: Oc, +pt: B.Tb<&2, V.Point>, +b: Bx, +q: Vq, +m: TS.Mp, +x: Sx, +ks: List<&2, Ek>, +tv: B.Tb<&2, V.Point>, +pl: M.Pl) -> Vr:
  view_g5(eds_par(TS.mp_es(m), TS.mp_ss(m), sx_sm(x), sx_tn(x), tv, vq_v(q), pl, o, tl), o, pt, q, x, ks)

def view_g3(+o: Oc, +pt: B.Tb<&2, V.Point>, +b: Bx, +q: Vq, +m: TS.Mp, +x: Sx, +ks: List<&2, Ek>, +tv: B.Tb<&2, V.Point>, +pl: M.Pl) -> Vr:
  view_g4(ths_view(sx_th(x), vq_v(q), oc_sk(o), Tl{[], []}), o, pt, b, q, m, x, ks, tv, pl)

def view_g2(+pt: B.Tb<&2, V.Point>, +b: Bx, +q: Vq, +m: TS.Mp, +x: Sx, +ks: List<&2, Ek>, +tv: B.Tb<&2, V.Point>, +pl: M.Pl, +eps: F64) -> Vr:
  view_g3(Oc{grid_of(TS.mp_ts(m), pt, b, sx_pos(x)), pt, sx_tt(x), sx_hx(x), False{}, eps, 0.0f64}, pt, b, q, m, x, ks, tv, pl)

def view_g1(+pp: List<&2, V.Point>, +q: Vq, +m: TS.Mp, +x: Sx, +ks: List<&2, Ek>, +tv: B.Tb<&2, V.Point>, +pl: M.Pl, +eps: F64) -> Vr:
  view_g2(B.tb_of(V.Point, pp, V.Pt{0.0f64, 0.0f64, 0.0f64}), bx_ps(pp, bx0()), q, m, x, ks, tv, pl, eps)

def view_go(+q: Vq, +m: TS.Mp, +wp: List<&2, V.Point>, +x: Sx, +ks: List<&2, Ek>, +tv: B.Tb<&2, V.Point>, +pl: M.Pl, +eps: F64) -> Vr:
  view_g1(prjs(wp, vq_v(q)), q, m, x, ks, tv, pl, eps)

def dx_head() -> String:
  "0\nSECTION\n2\nHEADER\n9\n$ACADVER\n1\nAC1009\n0\nENDSEC\n0\nSECTION\n2\nTABLES\n0\nTABLE\n2\nLTYPE\n70\n2\n" ++
  "0\nLTYPE\n2\nCONTINUOUS\n70\n0\n3\nSolid line\n72\n65\n73\n0\n40\n0.0\n" ++
  "0\nLTYPE\n2\nHIDDEN\n70\n0\n3\nHidden __ __ __\n72\n65\n73\n2\n40\n4.5\n49\n3.0\n49\n-1.5\n0\nENDTAB\n" ++
  "0\nTABLE\n2\nLAYER\n70\n5\n0\nLAYER\n2\nVISIBLE\n70\n0\n62\n7\n6\nCONTINUOUS\n0\nLAYER\n2\nHIDDEN\n70\n0\n62\n8\n6\nHIDDEN\n" ++
  "0\nLAYER\n2\nTHIN\n70\n0\n62\n4\n6\nCONTINUOUS\n0\nLAYER\n2\nDIM\n70\n0\n62\n3\n6\nCONTINUOUS\n0\nLAYER\n2\nTEXT\n70\n0\n62\n7\n6\nCONTINUOUS\n0\nENDTAB\n0\nENDSEC\n0\nSECTION\n2\nENTITIES\n"

def dx_tail() -> String:
  "0\nENDSEC\n0\nEOF\n"

type Dw is Data:
  Dw{ ok: Bool, s: String, why: String, nv: Nat, nh: Nat, nt: Nat }

def dw_ok(+d: Dw) -> Bool:
  Dw{+ok, s, why, nv, nh, nt} = d
  ok

def dw_s(+d: Dw) -> String:
  Dw{ok, +s, why, nv, nh, nt} = d
  s

def dw_why(+d: Dw) -> String:
  Dw{ok, s, +why, nv, nh, nt} = d
  why

def dw_nv(+d: Dw) -> Nat:
  Dw{ok, s, why, +nv, nh, nt} = d
  nv

def dw_nh(+d: Dw) -> Nat:
  Dw{ok, s, why, nv, +nh, nt} = d
  nh

def dw_nt(+d: Dw) -> Nat:
  Dw{ok, s, why, nv, nh, +nt} = d
  nt

def vr_s(+r: Vr) -> String:
  Vr{+s, nv, nh} = r
  s

def vr_nv(+r: Vr) -> Nat:
  Vr{s, +nv, nh} = r
  nv

def vr_nh(+r: Vr) -> Nat:
  Vr{s, nv, +nh} = r
  nh

def th_note(nt: Nat, +x: F64, +y: F64) -> String:
  match nt:
    case 0n: ""
    case _: dx_text(x, y, 2.5f64, "threads drawn conventionally (ISO 6410-1): crest solid (VISIBLE), root thin (THIN), end views crest circle and 3/4 root arc")

def title(+nd: U64, +x: F64, +y: F64, +nt: Nat) -> String:
  dx_text(x, y, 3.5f64, "BendCAD drawing  node " ++ U64.show(nd) ++ "  units mm") ++
  dx_text(x, F64.sub(y, 5.0f64), 2.5f64, "ISO first-angle projection: FRONT, TOP below it, LEFT to its right") ++
  dx_text(x, F64.sub(y, 9.0f64), 2.5f64, "visible edges and silhouettes solid (VISIBLE), tangent edges between different surfaces thin (THIN), hidden dashed (HIDDEN), seams not drawn, overall sizes from the certified box (DIM)") ++
  th_note(nt, x, F64.sub(y, 13.0f64))

type Ex is Data:
  Ex{ wx: F64, wy: F64, wz: F64 }

def ms_ex(+ms: M.Ms) -> Ex:
  Ex{F64.sub(M.ms_x1(ms), M.ms_x0(ms)), F64.sub(M.ms_y1(ms), M.ms_y0(ms)), F64.sub(M.ms_z1(ms), M.ms_z0(ms))}

def draw4(+fr: Vr, +tq: Vr, +lf: Vr, +tl: String, +nt: Nat) -> Dw:
  Dw{True{}, dx_head() ++ vr_s(fr) ++ vr_s(tq) ++ vr_s(lf) ++ tl ++ dx_tail(), "",
    Nat.add(vr_nv(fr), Nat.add(vr_nv(tq), vr_nv(lf))), Nat.add(vr_nh(fr), Nat.add(vr_nh(tq), vr_nh(lf))), nt}

type Vp is Data:
  Vp{ a: Vr, b: Vr }

def vp_a(+p: Vp) -> Vr:
  Vp{+a, b} = p
  a

def vp_b(+p: Vp) -> Vr:
  Vp{a, +b} = p
  b

def views2(+qa: Vq, +qb: Vq, +m: TS.Mp, +wp: List<&2, V.Point>, +x: Sx, +ks: List<&2, Ek>, +tv: B.Tb<&2, V.Point>, +pl: M.Pl, +eps: F64) -> Vp:
  ra rb = view_go(qa, m, wp, x, ks, tv, pl, eps) view_go(qb, m, wp, x, ks, tv, pl, eps)
  Vp{ra, rb}

def draw3p(+fr: Vr, +tl: Vp, +wx: F64, +wy: F64, +g: F64, +x: Sx, +nd: U64) -> Dw:
  draw4(fr, vp_a(tl), vp_b(tl), title(nd, F64.add(wx, g), F64.sub(wy, 4.0f64), List.length(&2, Th, sx_th(x))), List.length(&2, Th, sx_th(x)))

def draw3g(+wx: F64, +wy: F64, +wz: F64, +g: F64, +m: TS.Mp, +wp: List<&2, V.Point>, +x: Sx, +ks: List<&2, Ek>, +tv: B.Tb<&2, V.Point>, +pl: M.Pl, +eps: F64, +nd: U64) -> Dw:
  fr tl = view_go(Vq{vw_front(), "FRONT", 0.0f64, F64.add(wy, g), wx, wz}, m, wp, x, ks, tv, pl, eps) views2(Vq{vw_top(), "TOP", 0.0f64, 0.0f64, wx, wy}, Vq{vw_left(), "LEFT", F64.add(wx, g), F64.add(wy, g), wy, wz}, m, wp, x, ks, tv, pl, eps)
  draw3p(fr, tl, wx, wy, g, x, nd)

def draw3(+ex: Ex, +m: TS.Mp, +wp: List<&2, V.Point>, +x: Sx, +ks: List<&2, Ek>, +tv: B.Tb<&2, V.Point>, +pl: M.Pl, +eps: F64, +nd: U64) -> Dw:
  Ex{+wx, +wy, +wz} = ex
  draw3g(wx, wy, wz, F64.add(20.0f64, F64.mul(0.15f64, F64.max(wx, F64.max(wy, wz)))), m, wp, x, ks, tv, pl, eps, nd)

def draw_w5(ok: Bool, +b: M.Body, +m: TS.Mp, +q: M10.Q, +nd: U64, +pl: M.Pl, +wp: List<&2, V.Point>, +x: Sx) -> Dw:
  match ok:
    case False{}: Dw{False{}, "", "drawing-thread-unrecognised: a group of helicoid faces has no root and crest radius pair, so its conventional thread lines cannot be drawn", 0n, 0n, 0n}
    case True{}:
      draw3(ms_ex(M.body_ms(b)), m, wp, x, so_ek(B.msort(~Ek, ~ek_cmp, tris_eks(TS.mp_ts(m), 0n, []))),
        B.tb_of(V.Point, TS.vx_pts(Ty.brep_vs(M.bd_brep(b))), V.Pt{0.0f64, 0.0f64, 0.0f64}), pl, F64.add(F64.mul(2.0f64, M10.q_chord(q)), 1.0e-6f64), nd)

def bx8(+x0: F64, +x1: F64, +y0: F64, +y1: F64, +z0: F64, +z1: F64) -> List<&2, V.Point>:
  [V.Pt{x0, y0, z0}, V.Pt{x1, y0, z0}, V.Pt{x0, y1, z0}, V.Pt{x1, y1, z0}, V.Pt{x0, y0, z1}, V.Pt{x1, y0, z1}, V.Pt{x0, y1, z1}, V.Pt{x1, y1, z1}]

def ms_bc(+ms: M.Ms) -> List<&2, V.Point>:
  bx8(M.ms_x0(ms), M.ms_x1(ms), M.ms_y0(ms), M.ms_y1(ms), M.ms_z0(ms), M.ms_z1(ms))

def vol_t(+t: TS.Tri, +wt: B.Tb<&2, V.Point>, +o: V.Point) -> F64:
  KS.dot(KS.psub(pt2(wt, TS.ta(t)), o), KS.cross(KS.psub(pt2(wt, TS.tb(t)), o), KS.psub(pt2(wt, TS.tc(t)), o)))

def vol_go(ts: List<&2, TS.Tri>, +wt: B.Tb<&2, V.Point>, +o: V.Point, +acc: F64) -> F64:
  match ts:
    case []: acc
    case +t <> r: vol_go(r, wt, o, F64.add(acc, vol_t(t, wt, o)))

def draw_w4r(+b: M.Body, +m: TS.Mp, +q: M10.Q, +nd: U64, +pl: M.Pl, +wp: List<&2, V.Point>, +wt: B.Tb<&2, V.Point>, +tt: B.Tb<&2, TS.Tri>, +hs: List<&2, Hr>, +r: Ecl) -> Dw:
  draw_w5(hrs_ok(hs), b, m, q, nd, pl, wp, Sx{wt, tt, B.tb_of(Nat, fid_go(TS.mp_ns(m), 0n, []), 0n), B.tb_of(Bool, fhx_go(Ty.brep_fas(M.bd_brep(b)), TS.mp_ns(m), []), False{}), hrs_th(hs), ms_bc(M.body_ms(b)), F64.is_lt(0.0f64, vol_go(TS.mp_ts(m), wt, pt2(wt, 0n), 0.0f64)), r, fj_of(ecl_fp(r), List.length(&2, Ty.Face, Ty.brep_fas(M.bd_brep(b))))})

def draw_w4(+b: M.Body, +m: TS.Mp, +q: M10.Q, +nd: U64, +pl: M.Pl, +wp: List<&2, V.Point>, +wt: B.Tb<&2, V.Point>, +tt: B.Tb<&2, TS.Tri>, +hs: List<&2, Hr>) -> Dw:
  draw_w4r(b, m, q, nd, pl, wp, wt, tt, hs, ecl_of(M.bd_brep(b)))

def draw_w3(+b: M.Body, +m: TS.Mp, +q: M10.Q, +nd: U64, +pl: M.Pl, +wp: List<&2, V.Point>, +wt: B.Tb<&2, V.Point>, +tt: B.Tb<&2, TS.Tri>) -> Dw:
  draw_w4(b, m, q, nd, pl, wp, wt, tt, hr_groups(so_hr(B.msort(~Hr, ~hr_cmp, hr_walk(Ty.brep_fas(M.bd_brep(b)), TS.mp_ns(m), 0n, Hz{tt, wt, pl}, [])))))

def draw_w2(+b: M.Body, +m: TS.Mp, +q: M10.Q, +nd: U64, +pl: M.Pl, +wp: List<&2, V.Point>) -> Dw:
  draw_w3(b, m, q, nd, pl, wp, B.tb_of(V.Point, wp, V.Pt{0.0f64, 0.0f64, 0.0f64}), B.tb_of(TS.Tri, TS.mp_ts(m), TS.Tri{0n, 0n, 0n}))

def draw_w(+b: M.Body, +m: TS.Mp, +q: M10.Q, +nd: U64, +pl: M.Pl) -> Dw:
  draw_w2(b, m, q, nd, pl, wpts(TS.mp_ps(m), pl))

def draw_m(ok: Bool, +b: M.Body, +m: TS.Mp, +q: M10.Q, +nd: U64) -> Dw:
  match ok:
    case False{}: Dw{False{}, "", "drawing-mesh-not-closed: the part's mesh did not close, so hidden lines cannot be certain", 0n, 0n, 0n}
    case True{}: draw_w(b, m, q, nd, M.bd_pl(b))

def draw_b2(+b: M.Body, +m: TS.Mp, +q: M10.Q, +nd: U64) -> Dw:
  draw_m(TS.mp_ok(m), b, m, q, nd)

def draw_body(+b: M.Body, +nd: U64) -> Dw:
  draw_b2(b, TS.mesh_of(b, M10.q_mk(0.05f64, 0.05f64, 10000000n, 0u64)), M10.q_mk(0.05f64, 0.05f64, 10000000n, 0u64), nd)
