import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as G3
import ../c06/iv.bend as I
import ./ivx.bend as X
import ./rb.bend as R

def alpha(+u: I.I, +lo: F64, +hi: F64) -> I.I:
  Bool.pick(I.I, F64.is_eq(lo, hi), I.ipt(0.0f64), I.idiv(I.isub(u, I.ipt(lo)), I.isub(I.ipt(hi), I.ipt(lo))))

def lvl_go(cs: List<&2, I.I>, +kw: List<&2, F64>, +u: I.I, +r: Nat, +m: Nat) -> List<&2, I.I>:
  match cs:
    case []: []
    case +c <> +t:
      match t:
        case []: []
        case +d <> v:
          +a = alpha(u, X.fn_(kw, Nat.add(Nat.sub(r, 1n), m)), X.fn_(kw, Nat.add(3n, m)))
          I.iadd(I.imul(I.isub(I.ipt(1.0f64), a), c), I.imul(a, d)) <> lvl_go(t, kw, u, r, Nat.add(m, 1n))

def blos(us: List<&2, I.I>, +cs: List<&2, I.I>, +kw: List<&2, F64>, +r: Nat) -> I.I:
  match us:
    case []: X.vn(cs, 0n)
    case u <> t: blos(t, lvl_go(cs, kw, u, r, 0n), kw, Nat.add(r, 1n))

def bz_ctrl(+cs: List<&2, I.I>, +kw: List<&2, F64>) -> List<&2, I.I>:
  +a = I.ipt(X.fn_(kw, 2n))
  +b = I.ipt(X.fn_(kw, 3n))
  [blos([a, a, a], cs, kw, 1n), blos([a, a, b], cs, kw, 1n), blos([a, b, b], cs, kw, 1n), blos([b, b, b], cs, kw, 1n)]

def take_f(n: Nat, xs: List<&2, F64>) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m:
      match xs:
        case []: []
        case x <> t: x <> take_f(m, t)

def take_p(n: Nat, xs: List<&2, V.Point>) -> List<&2, V.Point>:
  match n:
    case 0n: []
    case 1n+m:
      match xs:
        case []: []
        case x <> t: x <> take_p(m, t)

def span_cv(+kw: List<&2, F64>, +ps: List<&2, V.Point>, +ws: List<&2, F64>) -> R.Cv:
  +wi = X.vpts(ws)
  R.Cv{R.Rb{bz_ctrl(R.wmul(R.pts_x(ps), wi), kw), bz_ctrl(R.wmul(R.pts_y(ps), wi), kw), bz_ctrl(R.wmul(R.pts_z(ps), wi), kw), bz_ctrl(wi, kw)},
    X.fn_(kw, 2n), X.fn_(kw, 3n)}

def tl_f(xs: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: []
    case x <> t: t

def tl_p(xs: List<&2, V.Point>) -> List<&2, V.Point>:
  match xs:
    case []: []
    case x <> t: t

def spans_go(n: Nat, +ks: List<&2, F64>, +ps: List<&2, V.Point>, +ws: List<&2, F64>) -> List<&2, R.Cv>:
  match n:
    case 0n: []
    case 1n+m:
      +kw = take_f(6n, ks)
      +rest = spans_go(m, tl_f(ks), tl_p(ps), tl_f(ws))
      Bool.pick(List<&2, R.Cv>, F64.is_lt(X.fn_(kw, 2n), X.fn_(kw, 3n)), span_cv(kw, take_p(4n, ps), take_f(4n, ws)) <> rest, rest)

def nb_valid(+ks: List<&2, F64>, +ps: List<&2, V.Point>, +ws: List<&2, F64>) -> Bool:
  Nat.is_eq(G3.nok_c(ks, ps, ws, Nat.add(List.length(&2, F64, ks), 1n)), 3n)

def nb_spans(n: G.Nurb) -> List<&2, R.Cv>:
  G.Nb{+ks, +ps, +ws} = n
  +nc = List.length(&2, V.Point, ps)
  Bool.pick(List<&2, R.Cv>, nb_valid(ks, ps, ws), spans_go(Nat.sub(nc, 3n), tl_f(ks), ps, ws), [])
