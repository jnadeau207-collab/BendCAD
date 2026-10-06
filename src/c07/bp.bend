import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c06/iv.bend as I
import ./ivx.bend as X
import ./rb.bend as R

type Bq is Data:
  Bq{ x: List<&2, List<&2, I.I>>, y: List<&2, List<&2, I.I>>, z: List<&2, List<&2, I.I>> }

def pl4(+a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> List<&2, V.Point>:
  [a, b, c, d]

def bq_rows(+r0: List<&2, V.Point>, +r1: List<&2, V.Point>, +r2: List<&2, V.Point>, +r3: List<&2, V.Point>) -> Bq:
  Bq{[R.pts_x(r0), R.pts_x(r1), R.pts_x(r2), R.pts_x(r3)], [R.pts_y(r0), R.pts_y(r1), R.pts_y(r2), R.pts_y(r3)],
    [R.pts_z(r0), R.pts_z(r1), R.pts_z(r2), R.pts_z(r3)]}

def bq_of(b: G.BezP) -> Bq:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32, +p33} = b
  bq_rows(pl4(p00, p01, p02, p03), pl4(p10, p11, p12, p13), pl4(p20, p21, p22, p23), pl4(p30, p31, p32, p33))

def heads(rs: List<&2, List<&2, I.I>>) -> List<&2, I.I>:
  match rs:
    case []: []
    case r <> t:
      match r:
        case []: heads(t)
        case x <> u: x <> heads(t)

def tails(rs: List<&2, List<&2, I.I>>) -> List<&2, List<&2, I.I>>:
  match rs:
    case []: []
    case r <> t:
      match r:
        case []: tails(t)
        case x <> u: u <> tails(t)

def transp(n: Nat, +rs: List<&2, List<&2, I.I>>) -> List<&2, List<&2, I.I>>:
  match n:
    case 0n: []
    case 1n+m: heads(rs) <> transp(m, tails(rs))

def rows_rs(rs: List<&2, List<&2, I.I>>, +t: I.I) -> List<&2, List<&2, I.I>>:
  match rs:
    case []: []
    case r <> u: R.rs(r, t) <> rows_rs(u, t)

def rows_hodo(rs: List<&2, List<&2, I.I>>) -> List<&2, List<&2, I.I>>:
  match rs:
    case []: []
    case r <> u: R.hodo(r) <> rows_hodo(u)

def hull2(rs: List<&2, List<&2, I.I>>) -> I.I:
  match rs:
    case []: I.I{F64.div(1.0f64, 0.0f64), F64.neg(F64.div(1.0f64, 0.0f64))}
    case r <> u: I.ihull(R.hull(r), hull2(u))

def sub_rs(+rs: List<&2, List<&2, I.I>>, +u: I.I, +v: I.I) -> List<&2, List<&2, I.I>>:
  rows_rs(transp(4n, rows_rs(rs, u)), v)

def c_box(+rs: List<&2, List<&2, I.I>>, +u: I.I, +v: I.I) -> I.I:
  hull2(sub_rs(rs, u, v))

def c_du(+rs: List<&2, List<&2, I.I>>, +u: I.I, +v: I.I) -> I.I:
  hull2(rows_rs(transp(3n, rows_rs(rows_hodo(rs), u)), v))

def c_dv(+rs: List<&2, List<&2, I.I>>, +u: I.I, +v: I.I) -> I.I:
  hull2(rows_rs(rows_hodo(transp(4n, rows_rs(rs, u))), v))

def bq_box(q: Bq, +u: I.I, +v: I.I) -> List<&2, I.I>:
  Bq{x, y, z} = q
  [c_box(x, u, v), c_box(y, u, v), c_box(z, u, v)]

def bq_du(q: Bq, +u: I.I, +v: I.I) -> List<&2, I.I>:
  Bq{x, y, z} = q
  [c_du(x, u, v), c_du(y, u, v), c_du(z, u, v)]

def bq_dv(q: Bq, +u: I.I, +v: I.I) -> List<&2, I.I>:
  Bq{x, y, z} = q
  [c_dv(x, u, v), c_dv(y, u, v), c_dv(z, u, v)]
