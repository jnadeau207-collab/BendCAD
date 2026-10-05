import os, re, subprocess, sys, time

here = os.path.dirname(os.path.abspath(__file__))
gen = os.path.join(here, "gen")
os.makedirs(gen, exist_ok=True)
src = os.path.relpath(os.path.join(here, "..", "..", "src"), gen).replace(os.sep, "/")

HEAD = f"""import Base
import {src}/c00/types.bend as T
import {src}/c05/arrange.bend as A
import {src}/c05/solve.bend as S

def fsum(xs: List<&2, F64>, +a: F64) -> F64:
  match xs:
    case Nil{{}}: a
    case h <> t: fsum(t, (a + h : F64))

def summ(s: S.Sol) -> String:
  match s:
    case S.Sv_ok{{ps, dof, red}}: "ok dof=" ++ Nat.show(dof) ++ " sum=" ++ F64.show(fsum(ps, 0.0f64))
    case S.Sv_conflict{{ids}}: "conflict"
    case S.Sv_err{{kind}}: "err " ++ T.FailKind.show(kind)

def rlen(xs: List<&2, A.Region>) -> Nat:
  match xs:
    case Nil{{}}: 0n
    case h <> t: 1n+rlen(t)

def asum(r: A.ARes) -> String:
  match r:
    case A.A_ok{{nv, ne, nc, regs, dang}}: "v=" ++ Nat.show(nv) ++ " e=" ++ Nat.show(ne) ++ " c=" ++ Nat.show(nc) ++ " r=" ++ Nat.show(rlen(regs))
    case A.A_err{{kind}}: "err " ++ T.FailKind.show(kind)

def tol() -> T.Tol:
  T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64)

def nf(i: Nat) -> F64:
  U64.to_f64(U64.from_nat(i))

def trues(n: Nat) -> List<&2, Bool>:
  match n:
    case 0n: []
    case 1n+m: True{{}} <> trues(m)

def nn() -> Nat:
  NN
"""

RECTS = """
def pts(n: Nat, +i: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m:
      +x = (nf(i) * 3.0f64 : F64)
      (x + 0.1f64 : F64) <> 0.05f64 <> (x + 2.2f64 : F64) <> 0.1f64 <> (x + 1.9f64 : F64) <> 1.1f64 <> (x - 0.1f64 : F64) <> 0.9f64 <> pts(m, 1n+i)

def cns(n: Nat, +i: Nat) -> List<&2, S.Cn>:
  match n:
    case 0n: []
    case 1n+m:
      +b = Nat.mul(8n, i)
      +d = U64.from_nat(b)
      +p0 = {S.Pt{b, Nat.add(b, 1n)} : S.Pt}
      +p1 = {S.Pt{Nat.add(b, 2n), Nat.add(b, 3n)} : S.Pt}
      +p2 = {S.Pt{Nat.add(b, 4n), Nat.add(b, 5n)} : S.Pt}
      +p3 = {S.Pt{Nat.add(b, 6n), Nat.add(b, 7n)} : S.Pt}
      S.K_fix{d, b, (nf(i) * 3.0f64 : F64)} <> S.K_fix{(d + 1u64 : U64), Nat.add(b, 1n), 0.0f64} <> S.K_horiz{(d + 2u64 : U64), p0, p1} <> S.K_vert{(d + 3u64 : U64), p1, p2} <> S.K_horiz{(d + 4u64 : U64), p2, p3} <> S.K_vert{(d + 5u64 : U64), p3, p0} <> S.K_hdist{(d + 6u64 : U64), p0, p1, 2.0f64} <> S.K_vdist{(d + 7u64 : U64), p1, p2, 1.0f64} <> cns(m, 1n+i)

def main() -> String:
  +n = nn()
  summ(S.solve(pts(n, 0n), trues(Nat.mul(8n, n)), cns(n, 0n), tol(), 100n))
"""

CHAIN = """
def pts(n: Nat, +i: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m: (nf(i) + 0.1f64 : F64) <> 0.05f64 <> pts(m, 1n+i)

def cns(n: Nat, +i: Nat) -> List<&2, S.Cn>:
  match n:
    case 0n: []
    case 1n+m:
      +b = Nat.mul(2n, i)
      +d = U64.from_nat(b)
      +p = {S.Pt{b, Nat.add(b, 1n)} : S.Pt}
      +q = {S.Pt{Nat.add(b, 2n), Nat.add(b, 3n)} : S.Pt}
      S.K_hdist{(d + 10u64 : U64), p, q, 1.0f64} <> S.K_vdist{(d + 11u64 : U64), p, q, 0.0f64} <> cns(m, 1n+i)

def main() -> String:
  +n = nn()
  summ(S.solve(pts(1n+n, 0n), trues(Nat.mul(2n, 1n+n)), S.K_fix{1u64, 0n, 0.0f64} <> S.K_fix{2u64, 1n, 0.0f64} <> cns(n, 0n), tol(), 100n))
"""

GRID = """
def pts(n: Nat, +i: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m: (nf(i) * 0.01f64 : F64) <> 0.05f64 <> pts(m, 1n+i)

def rowc(n: Nat, +g: Nat, +i: Nat, +k: Nat) -> List<&2, S.Cn>:
  match n:
    case 0n: []
    case 1n+m:
      +b = Nat.mul(2n, i)
      +d = U64.from_nat(Nat.mul(4n, i))
      +p = {S.Pt{b, Nat.add(b, 1n)} : S.Pt}
      +q = {S.Pt{Nat.add(b, 2n), Nat.add(b, 3n)} : S.Pt}
      +bd = Nat.mul(2n, Nat.add(i, g))
      +r = {S.Pt{bd, Nat.add(bd, 1n)} : S.Pt}
      +h = Bool.pick(List<&2, S.Cn>, Nat.is_eq(Nat.add(k, 1n), g), [], [S.K_hdist{(d + 10u64 : U64), p, q, 1.0f64}, S.K_vdist{(d + 11u64 : U64), p, q, 0.0f64}])
      List.append(&2, S.Cn, h, S.K_hdist{(d + 12u64 : U64), p, r, 0.0f64} <> S.K_vdist{(d + 13u64 : U64), p, r, 1.0f64} <> rowc(m, g, 1n+i, Nat.mod(Nat.add(k, 1n), g)))

def main() -> String:
  +g = nn()
  +n2 = Nat.mul(g, g)
  summ(S.solve(pts(n2, 0n), trues(Nat.mul(2n, n2)), S.K_fix{1u64, 0n, 0.0f64} <> S.K_fix{2u64, 1n, 0.0f64} <> rowc(Nat.mul(g, Nat.sub(g, 1n)), g, 0n, 0n), tol(), 100n))
"""

TRUSS = """
def jit(+i: Nat) -> F64:
  (0.035f64 * (U64.to_f64(U64.from_nat(Nat.mod(Nat.mul(i, 7n), 5n))) - 2.0f64 : F64) : F64)

def pts(n: Nat, +g: Nat, +i: Nat) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m: (nf(Nat.mod(i, g)) + jit(i) : F64) <> (nf(Nat.div(i, g)) - jit(Nat.add(i, 3n)) : F64) <> pts(m, g, 1n+i)

def pt(+i: Nat) -> S.Pt:
  S.Pt{Nat.mul(2n, i), Nat.add(Nat.mul(2n, i), 1n)}

def edges(n: Nat, +g: Nat, +i: Nat) -> List<&2, S.Cn>:
  match n:
    case 0n: []
    case 1n+m:
      +c = Nat.mod(i, g)
      +r = Nat.div(i, g)
      +d = U64.from_nat(Nat.mul(4n, i))
      +rt = Nat.is_lt(Nat.add(c, 1n), g)
      +up = Nat.is_lt(Nat.add(r, 1n), g)
      +h = Bool.pick(List<&2, S.Cn>, rt, [S.K_dist{(d + 10u64 : U64), pt(i), pt(Nat.add(i, 1n)), 1.0f64}], [])
      +v = Bool.pick(List<&2, S.Cn>, up, [S.K_dist{(d + 11u64 : U64), pt(i), pt(Nat.add(i, g)), 1.0f64}], [])
      +x = Bool.pick(List<&2, S.Cn>, Bool.and(rt, up), [S.K_dist{(d + 12u64 : U64), pt(i), pt(Nat.add(i, Nat.add(g, 1n))), 1.4142135623730951f64}], [])
      List.append(&2, S.Cn, h, List.append(&2, S.Cn, v, List.append(&2, S.Cn, x, edges(m, g, 1n+i))))

def main() -> String:
  +g = nn()
  +n2 = Nat.mul(g, g)
  summ(S.solve(pts(n2, g, 0n), trues(Nat.mul(2n, n2)), S.K_fix{1u64, 0n, 0.0f64} <> S.K_fix{2u64, 1n, 0.0f64} <> S.K_fix{3u64, 3n, 0.0f64} <> edges(n2, g, 0n), tol(), 100n))
"""

PLATE = """
def sq(+id: U64, +x0: F64, +y0: F64, +x1: F64, +y1: F64, rest: List<&2, A.Seg>) -> List<&2, A.Seg>:
  A.Seg{id, x0, y0, x1, y0} <> A.Seg{(id + 1u64 : U64), x1, y0, x1, y1} <> A.Seg{(id + 2u64 : U64), x1, y1, x0, y1} <> A.Seg{(id + 3u64 : U64), x0, y1, x0, y0} <> rest

def row(j: Nat, +i: U64, +id: U64, acc: List<&2, A.Seg>) -> List<&2, A.Seg>:
  match j:
    case 0n: acc
    case 1n+(+m):
      +x0 = F64.fma(10.0f64, U64.to_f64(i), 5.0f64)
      +y0 = F64.fma(10.0f64, nf(m), 5.0f64)
      row(m, i, (id + 4u64 : U64), sq(id, x0, y0, (x0 + 5.0f64 : F64), (y0 + 5.0f64 : F64), acc))

def rows(k: Nat, +n: Nat, +id: U64, acc: List<&2, A.Seg>) -> List<&2, A.Seg>:
  match k:
    case 0n: acc
    case 1n+(+m): rows(m, n, (id + (4u64 * U64.from_nat(n) : U64) : U64), row(n, U64.from_nat(m), id, acc))

def main() -> String:
  +n = nn()
  +w = F64.fma(10.0f64, nf(n), 10.0f64)
  asum(A.arrange(sq(1u64, 0.0f64, 0.0f64, w, w, rows(n, n, 5u64, [])), 100000000n))
"""

NEST = """
def sq(+id: U64, +x0: F64, +y0: F64, +x1: F64, +y1: F64, rest: List<&2, A.Seg>) -> List<&2, A.Seg>:
  A.Seg{id, x0, y0, x1, y0} <> A.Seg{(id + 1u64 : U64), x1, y0, x1, y1} <> A.Seg{(id + 2u64 : U64), x1, y1, x0, y1} <> A.Seg{(id + 3u64 : U64), x0, y1, x0, y0} <> rest

def nest(k: Nat, +id: U64, acc: List<&2, A.Seg>) -> List<&2, A.Seg>:
  match k:
    case 0n: acc
    case 1n+(+m):
      +h = nf(1n+m)
      nest(m, (id + 4u64 : U64), sq(id, F64.neg(h), F64.neg(h), h, h, acc))

def main() -> String:
  asum(A.arrange(nest(nn(), 1u64, []), 100000000n))
"""

RANDOM = """
def nx(+s: U64) -> U64:
  ((s * 6364136223846793005u64 : U64) + 1442695040888963407u64 : U64)

def co(+s: U64) -> F64:
  U64.to_f64(U64.mod((s / 8589934592u64 : U64), 1000u64))

def segs(n: Nat, +s: U64, +id: U64) -> List<&2, A.Seg>:
  match n:
    case 0n: []
    case 1n+m:
      +a = nx(s)
      +b = nx(a)
      +c = nx(b)
      +d = nx(c)
      A.Seg{id, co(a), co(b), co(c), co(d)} <> segs(m, d, (id + 1u64 : U64))

def main() -> String:
  asum(A.arrange(segs(nn(), 12345u64, 1u64), 100000000n))
"""

HEAD4 = f"""import Base
import {src}/c00/types.bend as T
import {src}/c01/types.bend as V
import {src}/c03/types.bend as G
import {src}/c04/types.bend as Ty
import {src}/c04/ops.bend as Op

def nf(i: Nat) -> F64:
  U64.to_f64(U64.from_nat(i))

def nn() -> Nat:
  NN
"""

HOLES = """
def cx(+c: Nat) -> F64:
  Bool.pick(F64, Bool.or(Nat.is_eq(c, 1n), Nat.is_eq(c, 2n)), 1.0f64, 0.0f64)

def cy(+c: Nat) -> F64:
  Bool.pick(F64, Nat.is_le(2n, c), 1.0f64, 0.0f64)

def vp(+h: Nat, +i: Nat) -> V.Point:
  +c = Nat.mod(i, 4n)
  +l = Nat.div(i, 4n)
  +w = F64.fma(3.0f64, nf(h), 1.0f64)
  +k = Nat.sub(l, 1n)
  +x0 = F64.fma(3.0f64, nf(Nat.mod(k, h)), 1.0f64)
  +y0 = F64.fma(3.0f64, nf(Nat.div(k, h)), 1.0f64)
  Bool.pick(V.Point, Nat.is_eq(l, 0n), V.Pt{(w * cx(c) : F64), (w * cy(c) : F64), 0.0f64}, V.Pt{(x0 + cx(c) : F64), (y0 + cy(c) : F64), 0.0f64})

def px(p: V.Point) -> F64:
  V.Pt{x, y, z} = p
  x

def py(p: V.Point) -> F64:
  V.Pt{x, y, z} = p
  y

def vxs(n: Nat, +h: Nat, +i: Nat, +b: Ty.Brep) -> Ty.Brep:
  match n:
    case 0n: b
    case 1n+m: vxs(m, h, 1n+i, Ty.tres_brep(Ty.vx_push(b, vp(h, i))))

def nxt(+i: Nat) -> Nat:
  Nat.add(Nat.mul(4n, Nat.div(i, 4n)), Nat.mod(1n+i, 4n))

def eds(n: Nat, +h: Nat, +nv: Nat, +e: Nat, +b: Ty.Brep) -> Ty.Brep:
  match n:
    case 0n: b
    case 1n+m:
      +a = vp(h, e)
      +z = vp(h, nxt(e))
      +g = Nat.add(nv, Nat.mul(2n, e))
      +b1 = Ty.tres_brep(Ty.ed_push(b, Ty.mk_hv(e, U64.from_nat(1n+e)), Ty.mk_hv(nxt(e), U64.from_nat(1n+nxt(e))),
        Ty.EK_curve{G.GV_ln{G.Ln{a, V.Dr{(px(z) - px(a) : F64), (py(z) - py(a) : F64), 0.0f64}}}, G.Dom{0.0f64, 1.0f64}}))
      +b2 = Ty.tres_brep(Ty.ce_push(b1, Ty.mk_he(e, U64.from_nat(1n+g)), Nat.is_lt(e, 4n),
        G.GV_ts{G.Ts{V.V2{px(a), py(a)}, V.V2{px(z), py(z)}}}))
      eds(m, h, nv, 1n+e, b2)

def hc(+nv: Nat, +e: Nat) -> Ty.HCoedge:
  Ty.mk_hc(e, U64.from_nat(Nat.add(Nat.add(nv, Nat.mul(2n, e)), 2n)))

def lps(n: Nat, +nv: Nat, +l: Nat, +g: Nat, +b: Ty.Brep) -> Ty.Brep:
  match n:
    case 0n: b
    case 1n+m:
      +e = Nat.mul(4n, l)
      +cs = Bool.pick(List<&2, Ty.HCoedge>, Nat.is_eq(l, 0n), [hc(nv, e), hc(nv, 1n+e), hc(nv, Nat.add(e, 2n)), hc(nv, Nat.add(e, 3n))],
        [hc(nv, Nat.add(e, 3n)), hc(nv, Nat.add(e, 2n)), hc(nv, 1n+e), hc(nv, e)])
      +k = Bool.pick(Ty.LoopKind, Nat.is_eq(l, 0n), Ty.LK_outer{}, Ty.LK_inner{})
      lps(m, nv, 1n+l, 1n+g, Ty.tres_brep(Ty.lp_push(b, cs, k)))

def hls(n: Nat, +l: Nat, +g: Nat) -> List<&2, Ty.HLoop>:
  match n:
    case 0n: []
    case 1n+m: Ty.mk_hlp(l, U64.from_nat(g)) <> hls(m, 1n+l, 1n+g)

def plate(+h: Nat) -> Ty.Brep:
  +nl = Nat.add(1n, Nat.mul(h, h))
  +nv = Nat.mul(4n, nl)
  +g0 = Nat.add(nv, Nat.mul(2n, nv))
  +b = lps(nl, nv, 0n, Nat.add(1n, g0), eds(nv, h, nv, 0n, vxs(nv, h, 0n, Ty.brep_empty())))
  +gf = Nat.add(g0, Nat.add(1n, nl))
  +b2 = Ty.tres_brep(Ty.fa_push(b, G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}}}, hls(nl, 0n, Nat.add(1n, g0)), True{}))
  +b3 = Ty.tres_brep(Ty.sh_push(b2, [Ty.mk_hfa(0n, U64.from_nat(gf))], Ty.SK_open{}))
  Ty.brep_set_top(b3, Ty.Cp{[], [Ty.mk_hsh(0n, U64.from_nat(Nat.add(1n, gf)))]})

def main() -> String:
  Ty.tres_show(Op.brep_checked(plate(nn()), Ty.P_open_shell{}, 100000000n))
"""


PRISM = """
def pxy_of(+m: Nat, +i: Nat) -> V.Vec2:
  +r = Nat.sub(i, 3n)
  +t = Nat.sub(Nat.sub(m, 1n), Nat.div(r, 4n))
  +ph = Nat.mod(r, 4n)
  +x = Bool.pick(F64, Nat.is_le(ph, 1n), nf(Nat.add(Nat.mul(2n, t), 1n)), nf(Nat.mul(2n, t)))
  +y = Bool.pick(F64, Bool.or(Nat.is_eq(ph, 0n), Nat.is_eq(ph, 3n)), 2.0f64, 3.0f64)
  +w = nf(Nat.mul(2n, m))
  Bool.pick(V.Vec2, Nat.is_eq(i, 0n), V.V2{0.0f64, 0.0f64},
    Bool.pick(V.Vec2, Nat.is_eq(i, 1n), V.V2{w, 0.0f64},
      Bool.pick(V.Vec2, Nat.is_eq(i, 2n), V.V2{w, 2.0f64}, V.V2{x, y})))

def lift(q: V.Vec2, +z: F64) -> V.Point:
  V.V2{x, y} = q
  V.Pt{x, y, z}

def pz(+k: Nat, +i: Nat, +z: F64) -> V.Point:
  lift(pxy_of(k, i), z)

def pxy(p: V.Point) -> V.Vec2:
  V.Pt{x, y, z} = p
  V.V2{x, y}

def dif(+a: V.Point, +b: V.Point) -> V.Dir:
  V.Pt{ax, ay, az} = a
  V.Pt{bx, by, bz} = b
  V.Dr{(bx - ax : F64), (by - ay : F64), (bz - az : F64)}

def ln(+a: V.Point, +b: V.Point) -> Ty.EdgeKind:
  Ty.EK_curve{G.GV_ln{G.Ln{a, dif(a, b)}}, G.Dom{0.0f64, 1.0f64}}

def ts(+a: V.Vec2, +b: V.Vec2) -> G.GVal:
  G.GV_ts{G.Ts{a, b}}

def uv(+s: F64, +t: F64) -> V.Vec2:
  V.V2{s, t}

def nx(+n: Nat, +i: Nat) -> Nat:
  Nat.mod(1n+i, n)

def g(+x: Nat) -> U64:
  U64.from_nat(x)

def vxs(c: Nat, +k: Nat, +n: Nat, +i: Nat, +b: Ty.Brep) -> Ty.Brep:
  match c:
    case 0n: b
    case 1n+m:
      +p = Bool.pick(V.Point, Nat.is_lt(i, n), pz(k, i, 0.0f64), pz(k, Nat.sub(i, n), 1.0f64))
      vxs(m, k, n, 1n+i, Ty.tres_brep(Ty.vx_push(b, p)))

def hv(+i: Nat) -> Ty.HVertex:
  Ty.mk_hv(i, g(1n+i))

def eds(c: Nat, +k: Nat, +n: Nat, +e: Nat, +b: Ty.Brep) -> Ty.Brep:
  match c:
    case 0n: b
    case 1n+m:
      +grp = Nat.div(e, n)
      +i = Nat.mod(e, n)
      +j = nx(n, i)
      +a = Bool.pick(Nat, Nat.is_eq(grp, 1n), Nat.add(n, i), i)
      +z = Bool.pick(Nat, Nat.is_eq(grp, 0n), j, Bool.pick(Nat, Nat.is_eq(grp, 1n), Nat.add(n, j), Nat.add(n, i)))
      +pa = Bool.pick(V.Point, Nat.is_eq(grp, 1n), pz(k, i, 1.0f64), pz(k, i, 0.0f64))
      +pb = Bool.pick(V.Point, Nat.is_eq(grp, 0n), pz(k, j, 0.0f64), Bool.pick(V.Point, Nat.is_eq(grp, 1n), pz(k, j, 1.0f64), pz(k, i, 1.0f64)))
      eds(m, k, n, 1n+e, Ty.tres_brep(Ty.ed_push(b, hv(a), hv(z), ln(pa, pb))))

def he(+n: Nat, +e: Nat) -> Ty.HEdge:
  Ty.mk_he(e, g(Nat.add(Nat.mul(2n, n), 1n+e)))

def ce(+b: Ty.Brep, +h: Ty.HEdge, +f: Bool, +t: G.GVal) -> Ty.Brep:
  Ty.tres_brep(Ty.ce_push(b, h, f, t))

def dl1(d: V.Dir) -> F64:
  V.Dr{x, y, z} = d
  (F64.abs(x) + F64.abs(y) : F64)

def elen(+a: V.Point, +b: V.Point) -> F64:
  dl1(dif(a, b))

def dscale(d: V.Dir, +l: F64) -> V.Dir:
  V.Dr{x, y, z} = d
  V.Dr{(x / l : F64), (y / l : F64), 0.0f64}

def unit(+a: V.Point, +b: V.Point) -> V.Dir:
  dscale(dif(a, b), elen(a, b))

def sides(c: Nat, +k: Nat, +n: Nat, +i: Nat, +b: Ty.Brep) -> Ty.Brep:
  match c:
    case 0n: b
    case 1n+m:
      +j = nx(n, i)
      +l = elen(pz(k, i, 0.0f64), pz(k, j, 0.0f64))
      +b1 = ce(b, he(n, i), True{}, ts(uv(0.0f64, 0.0f64), uv(l, 0.0f64)))
      +b2 = ce(b1, he(n, Nat.add(Nat.mul(2n, n), j)), True{}, ts(uv(l, 0.0f64), uv(l, 1.0f64)))
      +b3 = ce(b2, he(n, Nat.add(n, i)), False{}, ts(uv(0.0f64, 1.0f64), uv(l, 1.0f64)))
      +b4 = ce(b3, he(n, Nat.add(Nat.mul(2n, n), i)), False{}, ts(uv(0.0f64, 0.0f64), uv(0.0f64, 1.0f64)))
      sides(m, k, n, 1n+i, b4)

def caps(c: Nat, +k: Nat, +n: Nat, +i: Nat, +top: Bool, +b: Ty.Brep) -> Ty.Brep:
  match c:
    case 0n: b
    case 1n+m:
      +e = Bool.pick(Nat, top, Nat.add(n, i), i)
      caps(m, k, n, 1n+i, top, ce(b, he(n, e), top, ts(pxy(pz(k, i, 0.0f64)), pxy(pz(k, nx(n, i), 0.0f64)))))

def hc(+n: Nat, +c: Nat) -> Ty.HCoedge:
  Ty.mk_hc(c, g(Nat.add(Nat.mul(5n, n), 1n+c)))

def side_lps(c: Nat, +n: Nat, +i: Nat, +b: Ty.Brep) -> Ty.Brep:
  match c:
    case 0n: b
    case 1n+m:
      +q = Nat.mul(4n, i)
      side_lps(m, n, 1n+i, Ty.tres_brep(Ty.lp_push(b, [hc(n, q), hc(n, 1n+q), hc(n, Nat.add(q, 2n)), hc(n, Nat.add(q, 3n))], Ty.LK_outer{})))

def top_hcs(c: Nat, +n: Nat, +i: Nat) -> List<&2, Ty.HCoedge>:
  match c:
    case 0n: []
    case 1n+m: hc(n, Nat.add(Nat.mul(4n, n), i)) <> top_hcs(m, n, 1n+i)

def bot_hcs(c: Nat, +n: Nat, +i: Nat) -> List<&2, Ty.HCoedge>:
  match c:
    case 0n: []
    case 1n+m: hc(n, Nat.add(Nat.mul(5n, n), Nat.sub(Nat.sub(n, 1n), i))) <> bot_hcs(m, n, 1n+i)

def pl(+o: V.Point, +u: V.Dir, +v: V.Dir) -> G.GVal:
  G.GV_pl{G.Pl{o, u, v}}

def zz() -> V.Dir:
  V.Dr{0.0f64, 0.0f64, 1.0f64}

def hl(+n: Nat, +l: Nat) -> Ty.HLoop:
  Ty.mk_hlp(l, g(Nat.add(Nat.mul(11n, n), 1n+l)))

def side_fas(c: Nat, +k: Nat, +n: Nat, +i: Nat, +b: Ty.Brep) -> Ty.Brep:
  match c:
    case 0n: b
    case 1n+m:
      +p = pz(k, i, 0.0f64)
      side_fas(m, k, n, 1n+i, Ty.tres_brep(Ty.fa_push(b, pl(p, unit(p, pz(k, nx(n, i), 0.0f64)), zz()), [hl(n, i)], True{})))

def hf(+n: Nat, +f: Nat) -> Ty.HFace:
  Ty.mk_hfa(f, g(Nat.add(Nat.mul(12n, n), Nat.add(3n, f))))

def hfs(c: Nat, +n: Nat, +f: Nat) -> List<&2, Ty.HFace>:
  match c:
    case 0n: []
    case 1n+m: hf(n, f) <> hfs(m, n, 1n+f)

def prism(+k: Nat) -> Ty.Brep:
  +n = Nat.add(Nat.mul(4n, k), 2n)
  +b0 = vxs(Nat.mul(2n, n), k, n, 0n, Ty.brep_empty())
  +b1 = eds(Nat.mul(3n, n), k, n, 0n, b0)
  +b2 = caps(n, k, n, 0n, False{}, caps(n, k, n, 0n, True{}, sides(n, k, n, 0n, b1)))
  +b3 = Ty.tres_brep(Ty.lp_push(side_lps(n, n, 0n, b2), top_hcs(n, n, 0n), Ty.LK_outer{}))
  +b4 = Ty.tres_brep(Ty.lp_push(b3, bot_hcs(n, n, 0n), Ty.LK_outer{}))
  +o = {V.Pt{0.0f64, 0.0f64, 0.0f64} : V.Point}
  +o1 = {V.Pt{0.0f64, 0.0f64, 1.0f64} : V.Point}
  +x = {V.Dr{1.0f64, 0.0f64, 0.0f64} : V.Dir}
  +y = {V.Dr{0.0f64, 1.0f64, 0.0f64} : V.Dir}
  +b5 = Ty.tres_brep(Ty.fa_push(side_fas(n, k, n, 0n, b4), pl(o1, x, y), [hl(n, n)], True{}))
  +b6 = Ty.tres_brep(Ty.fa_push(b5, pl(o, x, y), [hl(n, 1n+n)], False{}))
  +gs = Nat.add(Nat.mul(13n, n), 5n)
  +b7 = Ty.tres_brep(Ty.sh_push(b6, hfs(Nat.add(n, 2n), n, 0n), Ty.SK_outer{}))
  +b8 = Ty.tres_brep(Ty.so_push(b7, Ty.mk_hsh(0n, g(gs)), []))
  Ty.brep_set_top(b8, Ty.Cp{[Ty.mk_hso(0n, g(1n+gs))], []})

def main() -> String:
  Ty.tres_show(Op.brep_checked(prism(nn()), Ty.P_manifold_solid{}, 100000000n))
"""

WORK = {
    "sol-rects": (RECTS, lambda n: f"ok dof=0 sum={6 * n * n}", lambda n: 8 * n),
    "sol-chain": (CHAIN, lambda n: f"ok dof=0 sum={n * (n + 1) // 2}", lambda n: 2 * (n + 1)),
    "sol-grid": (GRID, lambda g: f"ok dof=0 sum={g * g * (g - 1)}", lambda g: 2 * g * g),
    "sol-truss": (TRUSS, lambda g: f"ok dof=0 sum={g * g * (g - 1)}", lambda g: 2 * g * g),
    "arr-plate": (PLATE, lambda n: f"v={4 * n * n + 4} e={4 * n * n + 4} c={n * n + 1} r={n * n + 1}", lambda n: 4 * n * n + 4),
    "arr-random": (RANDOM, None, lambda n: n),
    "arr-nest": (NEST, lambda n: f"v={4 * n} e={4 * n} c={n} r={n}", lambda n: 4 * n),
    "brep-holes": (HOLES, lambda h: "ok", lambda h: 4 * (h * h + 1)),
    "brep-prism": (PRISM, lambda k: "ok", lambda k: 4 * k + 4),
}
HEADS = {"brep-holes": HEAD4, "brep-prism": HEAD4}

PLAN = [("sol-rects", [10, 100, 1000, 3000]), ("sol-chain", [100, 1000, 5000]), ("sol-grid", [10, 20, 40]), ("sol-truss", [5, 10, 20, 40]),
        ("arr-plate", [10, 35, 50, 100]), ("arr-random", [100, 200, 400]), ("arr-nest", [250, 500, 1000, 2000]), ("brep-holes", [1, 3, 5, 10]), ("brep-prism", [1, 4, 9, 19])]


def wsl(cmd):
    if os.name == "nt":
        return subprocess.run(["wsl.exe", "-e", "bash", "-lc", cmd], capture_output=True, text=True)
    return subprocess.run(["bash", "-lc", cmd], capture_output=True, text=True)


def wpath(p):
    if os.name != "nt":
        return p
    d, rest = os.path.splitdrive(os.path.abspath(p))
    return "/mnt/" + d[0].lower() + rest.replace("\\", "/")


def run(kind, n):
    body, want, size = WORK[kind]
    f = os.path.join(gen, f"{kind}-{n}.bend")
    open(f, "w", newline="\n").write(HEADS.get(kind, HEAD).replace("NN", f"{n}n") + body)
    exe = f"/tmp/bendcad-bench-{kind}-{n}"
    bend = os.environ.get("BEND", "bend")
    r = wsl(f'export PATH=$HOME/.bend/bin:$PATH; (ulimit -v 8000000; {bend} "{wpath(f)}" -o {exe}) && /usr/bin/time -f "TIME %e %U %M" {exe}')
    if r.returncode:
        sys.exit(f"{kind} {n} failed:\n{r.stdout}{r.stderr}")
    out = r.stdout.strip().strip('"')
    real, user, rss = re.search(r"TIME (\S+) (\S+) (\S+)", r.stderr).groups()
    m = re.fullmatch(r"v=(\d+) e=(\d+) c=(\d+) r=(\d+)", out)
    ok = out == want(n) if want else bool(m) and int(m[4]) == int(m[2]) - int(m[1]) + int(m[3])
    return size(n), out, float(real), float(user), int(rss), ok


rows_ = []
pick = dict((a.split("=")[0], [int(v) for v in a.split("=")[1].split(",")] if "=" in a else None) for a in sys.argv[1:])
for kind, ns in [(k, pick.get(k) or v) for k, v in PLAN if not pick or k in pick]:
    for n in ns:
        sz, out, real, user, rss, ok = run(kind, n)
        rows_.append((kind, n, sz, out, real, user, rss, ok))
        print(f"{kind:11} n={n:<5} size={sz:<6} {real:7.2f}s real {user:7.2f}s user x{user / max(real, 1e-3):4.2f} {rss // 1024:5d}MB {'PASS' if ok else 'FAIL'} {out}", flush=True)

bad = [r for r in rows_ if not r[7]]
print(f"bench: {len(rows_)} runs, failures={len(bad)}")
sys.exit(1 if bad else 0)
