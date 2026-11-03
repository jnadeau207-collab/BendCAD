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
  +w = patch(pt(17.481206797315725f64, F64.neg(0.6614343221130666f64), 0.0f64), pt(19.953023595902206f64, F64.neg(0.5583826288453821f64), 0.0f64),
    pt(17.72653638073339f64, 2.0201011158620887f64, 30.0f64), pt(20.014038631398385f64, 2.9623491673125684f64, 30.0f64))
  +a = pt(19.963192768484895f64, 0.028406003847609718f64, 5.0f64)
  +b = pt(20.271563057535815f64, 0.059132141038742904f64, 5.0f64)
  +d = {V.Dr{F64.sub(V.pt_x(b), V.pt_x(a)), F64.sub(V.pt_y(b), V.pt_y(a)), 0.0f64} : V.Dir}
  IO.print(hs(Y.inter_cs_w(G.GV_ln{G.Ln{a, d}}, G.Dom{0.0f64, 1.0f64}, G.GV_bp{w}, 40n)))
