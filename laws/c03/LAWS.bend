import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c03/ops.bend as O

def dc_mid(+b: G.Bez3, +t: F64) -> V.Point:
  G.Bz{+p0, +p1, +p2, +p3} = b
  +s = F64.sub(1.0f64, t)
  +a = O.plerp_raw(p0, p1, s, t)
  +bb = O.plerp_raw(p1, p2, s, t)
  +c = O.plerp_raw(p2, p3, s, t)
  O.plerp_raw(O.plerp_raw(a, bb, s, t), O.plerp_raw(bb, c, s, t), s, t)

def bz_p0(b: G.Bez3) -> V.Point:
  G.Bz{p0, p1, p2, p3} = b
  p0

def bz_p3(b: G.Bez3) -> V.Point:
  G.Bz{p0, p1, p2, p3} = b
  p3

def first_or(r: G.GRes, +q: V.Point) -> V.Point:
  match r:
    case G.Gok{v}:
      match v:
        case G.GV_bz{w}:
          G.Bz{p0, p1, p2, p3} = w
          p0
        case _: q
    case G.Gerr{kind}: q

def last_or(r: G.GRes, +q: V.Point) -> V.Point:
  match r:
    case G.Gok{v}:
      match v:
        case G.GV_bz{w}:
          G.Bz{p0, p1, p2, p3} = w
          p3
        case _: q
    case G.Gerr{kind}: q

def lo_or(r: G.GRes, +q: F64) -> F64:
  match r:
    case G.Gok{v}:
      match v:
        case G.GV_dom{w}:
          G.Dom{lo, hi} = w
          lo
        case _: q
    case G.Gerr{kind}: q

def hi_or(r: G.GRes, +q: F64) -> F64:
  match r:
    case G.Gok{v}:
      match v:
        case G.GV_dom{w}:
          G.Dom{lo, hi} = w
          hi
        case _: q
    case G.Gerr{kind}: q

def d_lo(d: G.Dom) -> F64:
  G.Dom{lo, hi} = d
  lo

def d_hi(d: G.Dom) -> F64:
  G.Dom{lo, hi} = d
  hi

law bez_split_lo:
  for +b: G.Bez3
  for +t: F64
  {first_or(O.bez3_split_lo(b, t), bz_p0(b)) == bz_p0(b) : V.Point} & {last_or(O.bez3_split_lo(b, t), dc_mid(b, t)) == dc_mid(b, t) : V.Point}

law bez_split_hi:
  for +b: G.Bez3
  for +t: F64
  {first_or(O.bez3_split_hi(b, t), dc_mid(b, t)) == dc_mid(b, t) : V.Point} & {last_or(O.bez3_split_hi(b, t), bz_p3(b)) == bz_p3(b) : V.Point}

law dom_split_lo:
  for +d: G.Dom
  for +t: F64
  {lo_or(O.dom_split_lo(d, t), d_lo(d)) == d_lo(d) : F64} & {hi_or(O.dom_split_lo(d, t), t) == t : F64}

law dom_split_hi:
  for +d: G.Dom
  for +t: F64
  {lo_or(O.dom_split_hi(d, t), t) == t : F64} & {hi_or(O.dom_split_hi(d, t), d_hi(d)) == d_hi(d) : F64}

law gok_ok:
  for v: G.GVal
  {G.gres_ok(G.Gok{v}) == True{} : Bool}

law gok_kind_doc:
  for v: G.GVal
  {G.gres_kind(G.Gok{v}) == T.F_invalid{} : T.FailKind}

law gerr_show:
  for k: T.FailKind
  {G.gres_show(G.gerr(k)) == T.FailKind.show(k) : String}

law gerr_kind:
  for k: T.FailKind
  {G.gres_kind(G.gerr(k)) == k : T.FailKind}

law gerr_p_zero:
  for k: T.FailKind
  {G.gres_p(G.gerr(k)) == V.Pt{0.0f64, 0.0f64, 0.0f64} : V.Point}

law gerr_dom_zero:
  for k: T.FailKind
  {G.gres_dom(G.gerr(k)) == G.Dom{0.0f64, 0.0f64} : G.Dom}
