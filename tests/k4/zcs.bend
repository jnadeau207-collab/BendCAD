import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c06/iv.bend as I
import ../../src/c07/isect.bend as Y

def pt(+x: F64, +y: F64, +z: F64) -> V.Point:
  V.Pt{x, y, z}

def lerp(+a: V.Point, +b: V.Point, +t: F64) -> V.Point:
  V.Pt{F64.add(V.pt_x(a), F64.mul(t, F64.sub(V.pt_x(b), V.pt_x(a)))), F64.add(V.pt_y(a), F64.mul(t, F64.sub(V.pt_y(b), V.pt_y(a)))),
    F64.add(V.pt_z(a), F64.mul(t, F64.sub(V.pt_z(b), V.pt_z(a))))}

def bil(+a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point, +u: F64, +v: F64) -> V.Point:
  lerp(lerp(a, b, u), lerp(c, d, u), v)

def patch(+a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> G.BezP:
  +t = F64.div(1.0f64, 3.0f64)
  +s = F64.div(2.0f64, 3.0f64)
  G.Bp{bil(a, b, c, d, 0.0f64, 0.0f64), bil(a, b, c, d, t, 0.0f64), bil(a, b, c, d, s, 0.0f64), bil(a, b, c, d, 1.0f64, 0.0f64),
    bil(a, b, c, d, 0.0f64, t), bil(a, b, c, d, t, t), bil(a, b, c, d, s, t), bil(a, b, c, d, 1.0f64, t),
    bil(a, b, c, d, 0.0f64, s), bil(a, b, c, d, t, s), bil(a, b, c, d, s, s), bil(a, b, c, d, 1.0f64, s),
    bil(a, b, c, d, 0.0f64, 1.0f64), bil(a, b, c, d, t, 1.0f64), bil(a, b, c, d, s, 1.0f64), bil(a, b, c, d, 1.0f64, 1.0f64)}

def ivs(+a: I.I) -> String:
  "[" ++ F64.show(I.i_lo(a)) ++ "," ++ F64.show(I.i_hi(a)) ++ "]"

def hs(xs: List<&2, Y.Hx>) -> String:
  match xs:
    case []: "end"
    case h <> t:
      match h:
        case Y.Hx_uv{+s, +u, +v, p, k}: "uv s" ++ ivs(s) ++ " u" ++ ivs(u) ++ " v" ++ ivs(v) ++ "; " ++ hs(t)
        case Y.Hx_un3{+s, +u, +v}: "un s" ++ ivs(s) ++ " u" ++ ivs(u) ++ " v" ++ ivs(v) ++ "; " ++ hs(t)
        case Y.Hx_c{w}: "c; " ++ hs(t)

def main() -> IO(Unit):
  +w = patch(pt(5.275453858797004f64, F64.neg(1.1595507912509375f64), 0.0f64), pt(7.739173681963697f64, F64.neg(1.1026089184818497f64), 0.0f64),
    pt(6.4272462794388385f64, F64.neg(2.6225886239085754f64), 30.0f64), pt(8.72291034946683f64, F64.neg(1.72643895921997f64), 30.0f64))
  +a = pt(7.903129793214218f64, F64.neg(1.2065805919382029f64), 5.0f64)
  +b = pt(8.206668595587383f64, F64.neg(1.1755843017865066f64), 5.0f64)
  +d = {V.Dr{F64.sub(V.pt_x(b), V.pt_x(a)), F64.sub(V.pt_y(b), V.pt_y(a)), 0.0f64} : V.Dir}
  IO.print(hs(Y.inter_cs_w(G.GV_ln{G.Ln{a, d}}, G.Dom{0.0f64, 1.0f64}, G.GV_bp{w}, 120n)))
