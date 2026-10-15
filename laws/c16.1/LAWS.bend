import Base
import ../../src/c06/xp.bend as X
import ../../src/c16/sheet.bend as SH

def sg_a(+s: SH.Sg) -> Nat:
  match s:
    case SH.Sg_ln{+a, +b}: a
    case SH.Sg_ar{+a, +cx, +cy, +r, +b, +ccw}: a

def sg_b(+s: SH.Sg) -> Nat:
  match s:
    case SH.Sg_ln{+a, +b}: b
    case SH.Sg_ar{+a, +cx, +cy, +r, +b, +ccw}: b

def below(ss: List<&2, SH.Sg>, +n: Nat) -> Bool:
  match ss:
    case []: True{}
    case +s <> t: Bool.and(Bool.and(Nat.is_lt(sg_a(s), n), Nat.is_lt(sg_b(s), n)), below(t, n))

def linked(ss: List<&2, SH.Sg>, +at: Nat) -> Bool:
  match ss:
    case []: True{}
    case +s <> t: Bool.and(Nat.is_eq(sg_a(s), at), linked(t, sg_b(s)))

def idx_closed(+p: SH.PR) -> Bool:
  SH.PR{+pts, +segs} = p
  match segs:
    case []: False{}
    case +s <> t:
      Bool.and(Nat.is_eq(sg_a(s), 0n),
        Bool.and(linked(t, sg_b(s)), below(segs, List.length(&2, SH.P2, pts))))

law sh_loop_closed:
  for p: SH.PK
  for l: X.Xp
  for t: X.Xp
  for r: X.Xp
  for lh: X.Xp
  for mx: X.Xp
  for my: X.Xp
  {Bool.and(idx_closed(SH.sh_prof(p, l, t, r, lh)),
    idx_closed(SH.rot180(SH.sh_prof(p, l, t, r, lh), mx, my))) == True{} : Bool}

law sh_rot_len:
  for ps: List<&2, SH.P2>
  for mx: X.Xp
  for my: X.Xp
  {List.length(&2, SH.P2, SH.pts_rot(ps, mx, my)) == List.length(&2, SH.P2, ps) : Nat}

law flat_rows_len:
  for bs: List<&2, SH.BN>
  for th: F64
  for klo: F64
  for khi: F64
  for i: Nat
  {List.length(&2, SH.FR, SH.rows_go(bs, th, klo, khi, i)) == List.length(&2, SH.BN, bs) : Nat}

law flat_rows_nil:
  for t: F64
  for klo: F64
  for khi: F64
  {SH.flat_rows([], t, klo, khi) == [] : List<&2, SH.FR>}

law flat_legs_flat:
  for l: X.Xp
  for w: X.Xp
  for t: X.Xp
  {SH.flat_legs(SH.SC_ok{l, w, t, []}) == [l] : List<&2, X.Xp>}

law base_go_false:
  for nf: Nat
  {SH.base_go(False{}, nf) == SH.GR_no{"bend-base-not-admitted", "bend flat or single-bent sheet, hem once at most"} : SH.GR}

law fin_go_false:
  for l: F64
  for w: F64
  for t: F64
  for r: F64
  for lh: F64
  {SH.fin_go(False{}, l, w, t, r, lh) == SH.GR_no{"degenerate-feature", "give finite positive lengths for the blank, radius and hem"} : SH.GR}

law ang_go_false:
  for d: U64
  {SH.ang_go(False{}, d) == SH.GR_no{"bend-angle-not-certified", "bend 90 or 180 degrees"} : SH.GR}

law edge_go_false:
  for n: U64
  {SH.edge_go(False{}, n) == SH.GR_no{"bend-edge-not-admitted", "bend or hem edge 0, 1, 2 or 3 on an unworked end"} : SH.GR}

law rt_go_false:
  for r: F64
  for t: F64
  {SH.rt_go(False{}, r, t) == SH.GR_no{"bend-radius-too-tight", "keep inner radius over the certified R/T bound"} : SH.GR}

law size_go_false:
  for l: F64
  for ro: F64
  {SH.size_go(False{}, l, ro) == SH.GR_no{"bend-consumes-face", "keep the blank longer than twice outer radius"} : SH.GR}

law len_go_false:
  for lh: F64
  for leg: F64
  {SH.len_go(False{}, lh, leg) == SH.GR_no{"hem-consumes-face", "keep the hem shorter than its leg"} : SH.GR}

law k_go_false:
  for klo: F64
  for khi: F64
  {SH.k_go(False{}, klo, khi) == SH.GR_no{"bad-k-zone", "give a K-factor zone with 0 < KLO <= KHI < 1"} : SH.GR}

law gram_bad_base:
  for nf: Nat
  {SH.gram_go(False{}, True{}, nf) == SH.GR_no{"bend-base-not-admitted", "bend flat or single-bent sheet, hem once at most"} : SH.GR}

law gram_bad_edge:
  for nf: Nat
  {SH.gram_go(False{}, False{}, nf) == SH.GR_no{"bend-edge-not-admitted", "bend opposite ends alike, hem the bent end once"} : SH.GR}
