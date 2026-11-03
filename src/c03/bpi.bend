import Base
import ../c01/types.bend as V
import ./types.bend as G
import ../c06/iv.bend as I

type IW is Data:
  IW{ a: I.I, b: I.I, c: I.I, d: I.I }

def pdist(+a: V.Point, +b: V.Point) -> F64:
  +x = F64.sub(V.pt_x(a), V.pt_x(b))
  +y = F64.sub(V.pt_y(a), V.pt_y(b))
  +z = F64.sub(V.pt_z(a), V.pt_z(b))
  F64.sqrt(F64.add(F64.mul(x, x), F64.add(F64.mul(y, y), F64.mul(z, z))))

def iw(+t: F64) -> IW:
  +x = I.ipt(t)
  +s = I.isub(I.ipt(1.0f64), x)
  IW{I.imul(I.imul(s, s), s), I.iscale(I.imul(I.imul(s, s), x), 3.0f64), I.iscale(I.imul(s, I.imul(x, x)), 3.0f64),
    I.imul(I.imul(x, x), x)}

def icmb(+w: IW, +a: I.I, +b: I.I, +c: I.I, +d: I.I) -> I.I:
  IW{+wa, +wb, +wc, +wd} = w
  I.iadd(I.iadd(I.iadd(I.imul(wa, a), I.imul(wb, b)), I.imul(wc, c)), I.imul(wd, d))

def crd(+p: V.Point, +k: U64) -> F64:
  Bool.pick(F64, U64.is_eq(k, 0u64), V.pt_x(p), Bool.pick(F64, U64.is_eq(k, 1u64), V.pt_y(p), V.pt_z(p)))

def irow(+w: IW, +k: U64, +a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> I.I:
  icmb(w, I.ipt(crd(a, k)), I.ipt(crd(b, k)), I.ipt(crd(c, k)), I.ipt(crd(d, k)))

def ibp_k(+w: G.BezP, +k: U64, +wu: IW, +wv: IW) -> I.I:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32, +p33} = w
  icmb(wv, irow(wu, k, p00, p01, p02, p03), irow(wu, k, p10, p11, p12, p13), irow(wu, k, p20, p21, p22, p23),
    irow(wu, k, p30, p31, p32, p33))

def bp_gap(+w: G.BezP, +p: V.Point, +u: F64, +v: F64) -> F64:
  +wu = iw(u)
  +wv = iw(v)
  +gx = I.isub(I.ipt(V.pt_x(p)), ibp_k(w, 0u64, wu, wv))
  +gy = I.isub(I.ipt(V.pt_y(p)), ibp_k(w, 1u64, wu, wv))
  +gz = I.isub(I.ipt(V.pt_z(p)), ibp_k(w, 2u64, wu, wv))
  I.i_hi(I.isqrt(I.iadd(I.iadd(I.isq(gx), I.isq(gy)), I.isq(gz))))

def bp_span(+w: G.BezP) -> F64:
  G.Bp{+p00, p01, p02, +p03, p10, p11, p12, p13, p20, p21, p22, p23, +p30, p31, p32, +p33} = w
  F64.max(pdist(p00, p33), pdist(p03, p30))

def bp_tol(+w: G.BezP) -> F64:
  F64.mul(1.0e-9f64, F64.add(1.0f64, bp_span(w)))
