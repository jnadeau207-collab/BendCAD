import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty

def nth_v(xs: List<&2, Ty.Vertex>, +i: Nat) -> Ty.Vertex:
  match xs:
    case []: Ty.Vx{0u64, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_v(t, j)

def nth_e(xs: List<&2, Ty.Edge>, +i: Nat) -> Ty.Edge:
  match xs:
    case []: Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{0n, 0u64}, Ty.EK_degenerate{}}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_e(t, j)

def nth_c(xs: List<&2, Ty.Coedge>, +i: Nat) -> Ty.Coedge:
  match xs:
    case []: Ty.Ce{0u64, Ty.HE{0n, 0u64}, True{}, G.GV_f{0.0f64}}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_c(t, j)

def nth_l(xs: List<&2, Ty.Loop>, +i: Nat) -> Ty.Loop:
  match xs:
    case []: Ty.Lp{0u64, [], Ty.LK_outer{}}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_l(t, j)

def nth_f(xs: List<&2, Ty.Face>, +i: Nat) -> Ty.Face:
  match xs:
    case []: Ty.Fa{0u64, G.GV_f{0.0f64}, [], True{}, 0.0f64, 0.0f64}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_f(t, j)

def nth_p(xs: List<&2, V.Point>, +i: Nat) -> V.Point:
  match xs:
    case []: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_p(t, j)

def nth_f64(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: 0.0f64
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_f64(t, j)

def nth_n(xs: List<&2, Nat>, +i: Nat) -> Nat:
  match xs:
    case []: 0n
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_n(t, j)

def nth_v2(xs: List<&2, V.Vec2>, +i: Nat) -> V.Vec2:
  match xs:
    case []: V.V2{0.0f64, 0.0f64}
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nth_v2(t, j)

def mem_n(xs: List<&2, Nat>, +x: Nat) -> Bool:
  match xs:
    case []: False{}
    case +h <> +t: Bool.or(Nat.is_eq(h, x), mem_n(t, x))

def last_p(xs: List<&2, V.Point>, +d: V.Point) -> V.Point:
  match xs:
    case []: d
    case +h <> +t: last_p(t, h)

def last_v2(xs: List<&2, V.Vec2>, +d: V.Vec2) -> V.Vec2:
  match xs:
    case []: d
    case +h <> +t: last_v2(t, h)

def range_go(n: Nat, +i: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: i <> range_go(m, Nat.add(i, 1n))

def nat_range(+n: Nat) -> List<&2, Nat>:
  range_go(n, 0n)

def f64_of(+n: Nat) -> F64:
  U64.to_f64(U64.from_nat(n))
