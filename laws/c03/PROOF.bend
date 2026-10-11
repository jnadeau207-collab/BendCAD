import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c03/ops.bend as O
import ./LAWS.bend as Laws

def lo_fin(+p0: V.Point, +a: V.Point, +d: V.Point, +f: V.Point, ok: Bool) -> {Laws.first_or(O.bez3_split_lo_fin(p0, a, d, f, ok), p0) == p0 : V.Point} & {Laws.last_or(O.bez3_split_lo_fin(p0, a, d, f, ok), f) == f : V.Point}:
  match ok:
    case True{}: ({==}, {==})
    case False{}: ({==}, {==})

def lo_go(+p0: V.Point, +a: V.Point, +d: V.Point, +f: V.Point, fin: Bool, inside: Bool) -> {Laws.first_or(O.bez3_split_lo_go(p0, a, d, f, fin, inside), p0) == p0 : V.Point} & {Laws.last_or(O.bez3_split_lo_go(p0, a, d, f, fin, inside), f) == f : V.Point}:
  match fin inside:
    case False{} _: ({==}, {==})
    case True{} False{}: ({==}, {==})
    case True{} True{}: lo_fin(p0, a, d, f, Bool.and(V.pt_fin(a), Bool.and(V.pt_fin(d), V.pt_fin(f))))

def hi_fin(+f: V.Point, +e: V.Point, +c: V.Point, +p3: V.Point, ok: Bool) -> {Laws.first_or(O.bez3_split_hi_fin(f, e, c, p3, ok), f) == f : V.Point} & {Laws.last_or(O.bez3_split_hi_fin(f, e, c, p3, ok), p3) == p3 : V.Point}:
  match ok:
    case True{}: ({==}, {==})
    case False{}: ({==}, {==})

def hi_go(+f: V.Point, +e: V.Point, +c: V.Point, +p3: V.Point, fin: Bool, inside: Bool) -> {Laws.first_or(O.bez3_split_hi_go(f, e, c, p3, fin, inside), f) == f : V.Point} & {Laws.last_or(O.bez3_split_hi_go(f, e, c, p3, fin, inside), p3) == p3 : V.Point}:
  match fin inside:
    case False{} _: ({==}, {==})
    case True{} False{}: ({==}, {==})
    case True{} True{}: hi_fin(f, e, c, p3, Bool.and(V.pt_fin(f), Bool.and(V.pt_fin(e), V.pt_fin(c))))

def lo_split(+p0: V.Point, +p1: V.Point, +p2: V.Point, +p3: V.Point, +t: F64) -> {Laws.first_or(O.bez3_split_lo(G.Bz{p0, p1, p2, p3}, t), p0) == p0 : V.Point} & {Laws.last_or(O.bez3_split_lo(G.Bz{p0, p1, p2, p3}, t), Laws.dc_mid(G.Bz{p0, p1, p2, p3}, t)) == Laws.dc_mid(G.Bz{p0, p1, p2, p3}, t) : V.Point}:
  +s = F64.sub(1.0f64, t)
  +a = O.plerp_raw(p0, p1, s, t)
  +bb = O.plerp_raw(p1, p2, s, t)
  +c = O.plerp_raw(p2, p3, s, t)
  lo_go(p0, a, O.plerp_raw(a, bb, s, t), O.plerp_raw(O.plerp_raw(a, bb, s, t), O.plerp_raw(bb, c, s, t), s, t), G.bz_fin(G.Bz{p0, p1, p2, p3}), Bool.and(F64.is_lt(0.0f64, t), F64.is_lt(t, 1.0f64)))

def hi_split(+p0: V.Point, +p1: V.Point, +p2: V.Point, +p3: V.Point, +t: F64) -> {Laws.first_or(O.bez3_split_hi(G.Bz{p0, p1, p2, p3}, t), Laws.dc_mid(G.Bz{p0, p1, p2, p3}, t)) == Laws.dc_mid(G.Bz{p0, p1, p2, p3}, t) : V.Point} & {Laws.last_or(O.bez3_split_hi(G.Bz{p0, p1, p2, p3}, t), p3) == p3 : V.Point}:
  +s = F64.sub(1.0f64, t)
  +a = O.plerp_raw(p0, p1, s, t)
  +bb = O.plerp_raw(p1, p2, s, t)
  +c = O.plerp_raw(p2, p3, s, t)
  +e = O.plerp_raw(bb, c, s, t)
  hi_go(O.plerp_raw(O.plerp_raw(a, bb, s, t), e, s, t), e, c, p3, G.bz_fin(G.Bz{p0, p1, p2, p3}), Bool.and(F64.is_lt(0.0f64, t), F64.is_lt(t, 1.0f64)))

def Laws.bez_split_lo(b, t):
  match b:
    case G.Bz{+p0, +p1, +p2, +p3}:
      lo_split(p0, p1, p2, p3, t)

def Laws.bez_split_hi(b, t):
  match b:
    case G.Bz{+p0, +p1, +p2, +p3}:
      hi_split(p0, p1, p2, p3, t)

def dlo(+lo: F64, +hi: F64, +t: F64, fin: Bool, inside: Bool) -> {Laws.lo_or(O.dom_split_go(lo, hi, t, fin, inside), lo) == lo : F64} & {Laws.hi_or(O.dom_split_go(lo, hi, t, fin, inside), t) == t : F64}:
  match fin inside:
    case False{} _: ({==}, {==})
    case True{} False{}: ({==}, {==})
    case True{} True{}: ({==}, {==})

def dhi(+lo: F64, +hi: F64, +t: F64, fin: Bool, inside: Bool) -> {Laws.lo_or(O.dom_split_hi_go(lo, hi, t, fin, inside), t) == t : F64} & {Laws.hi_or(O.dom_split_hi_go(lo, hi, t, fin, inside), hi) == hi : F64}:
  match fin inside:
    case False{} _: ({==}, {==})
    case True{} False{}: ({==}, {==})
    case True{} True{}: ({==}, {==})

def Laws.dom_split_lo(d, t):
  match d:
    case G.Dom{+lo, +hi}:
      dlo(lo, hi, t, G.dom_valid(G.Dom{lo, hi}), Bool.and(F64.is_lt(lo, t), F64.is_lt(t, hi)))

def Laws.dom_split_hi(d, t):
  match d:
    case G.Dom{+lo, +hi}:
      dhi(lo, hi, t, G.dom_valid(G.Dom{lo, hi}), Bool.and(F64.is_lt(lo, t), F64.is_lt(t, hi)))

def Laws.gok_ok(v):
  match v:
    case G.GV_f{w}: {==}
    case G.GV_p{w}: {==}
    case G.GV_d{w}: {==}
    case G.GV_v2{w}: {==}
    case G.GV_dom{w}: {==}
    case G.GV_ln{w}: {==}
    case G.GV_pl{w}: {==}
    case G.GV_cc{w}: {==}
    case G.GV_bz{w}: {==}
    case G.GV_rq{w}: {==}
    case G.GV_bp{w}: {==}
    case G.GV_sp{w}: {==}
    case G.GV_cy{w}: {==}
    case G.GV_co{w}: {==}
    case G.GV_to{w}: {==}
    case G.GV_bb{w}: {==}
    case G.GV_nb{w}: {==}
    case G.GV_ts{w}: {==}
    case G.GV_tb{w}: {==}

def Laws.gok_kind_doc(v):
  match v:
    case G.GV_f{w}: {==}
    case G.GV_p{w}: {==}
    case G.GV_d{w}: {==}
    case G.GV_v2{w}: {==}
    case G.GV_dom{w}: {==}
    case G.GV_ln{w}: {==}
    case G.GV_pl{w}: {==}
    case G.GV_cc{w}: {==}
    case G.GV_bz{w}: {==}
    case G.GV_rq{w}: {==}
    case G.GV_bp{w}: {==}
    case G.GV_sp{w}: {==}
    case G.GV_cy{w}: {==}
    case G.GV_co{w}: {==}
    case G.GV_to{w}: {==}
    case G.GV_bb{w}: {==}
    case G.GV_nb{w}: {==}
    case G.GV_ts{w}: {==}
    case G.GV_tb{w}: {==}

def Laws.gerr_show(k):
  {==}

def Laws.gerr_kind(k):
  {==}

def Laws.gerr_p_zero(k):
  {==}

def Laws.gerr_dom_zero(k):
  {==}
