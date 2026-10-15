import Base
import ../../src/c00/types.bend as T
import ../../src/c06/cli.bend as C
import ../../src/c06/model.bend as M
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

law bend_base_refused:
  for base: U64
  for b: M.Body
  for e: X.Env
  for nd: U64
  {M.op_sheet(SH.FT_bend{0u64, X.X_k{2.0f64}, 90u64}, base, b, e, nd, []) == M.NR_err{T.F_invalid{}, M.Dg{"bend", "node " ++ U64.show(nd), "bend-base-not-admitted", "bend flat or single-bent sheet, hem once at most"}} : M.NR}

law bend_fin_refused:
  for n: U64
  for deg: U64
  for it: M.It
  for b: M.Body
  for e: X.Env
  for nd: U64
  {M.op_sheet(SH.FT_bend{n, X.X_k{2.0f64}, deg}, 1u64, b, e, nd, [M.Nd{1u64, M.O_flat{X.X_k{120.0f64}, X.X_k{80.0f64}, X.X_k{0.0f64}}, it}]) == M.NR_err{T.F_invalid{}, M.Dg{"bend", "node " ++ U64.show(nd), "degenerate-feature", "give finite positive lengths for the blank, radius and hem"}} : M.NR}

law bend_angle_refused:
  for n: U64
  for it: M.It
  for b: M.Body
  for e: X.Env
  for nd: U64
  {M.op_sheet(SH.FT_bend{n, X.X_k{2.0f64}, 45u64}, 1u64, b, e, nd, [M.Nd{1u64, M.O_flat{X.X_k{120.0f64}, X.X_k{80.0f64}, X.X_k{2.0f64}}, it}]) == M.NR_err{T.F_unsupported{}, M.Dg{"bend", "node " ++ U64.show(nd), "bend-angle-not-certified", "bend 90 or 180 degrees"}} : M.NR}

law bend_edge_refused:
  for it: M.It
  for b: M.Body
  for e: X.Env
  for nd: U64
  {M.op_sheet(SH.FT_bend{4u64, X.X_k{1.0f64}, 90u64}, 1u64, b, e, nd, [M.Nd{1u64, M.O_flat{X.X_k{120.0f64}, X.X_k{80.0f64}, X.X_k{2.0f64}}, it}]) == M.NR_err{T.F_unsupported{}, M.Dg{"bend", "node " ++ U64.show(nd), "bend-edge-not-admitted", "bend or hem edge 0, 1, 2 or 3 on an unworked end"}} : M.NR}

law hem_len_refused:
  for it: M.It
  for b: M.Body
  for e: X.Env
  for nd: U64
  {M.op_sheet(SH.FT_hem{0u64, X.X_k{120.0f64}}, 1u64, b, e, nd, [M.Nd{1u64, M.O_flat{X.X_k{100.0f64}, X.X_k{80.0f64}, X.X_k{2.0f64}}, it}]) == M.NR_err{T.F_invalid{}, M.Dg{"hem", "node " ++ U64.show(nd), "hem-consumes-face", "keep the hem shorter than its leg"}} : M.NR}

law flat_kzone_refused:
  for sc: SH.SC
  for e: X.Env
  for id: U64
  {C.flat_sc(True{}, sc, e, id, 0.7f64, 0.3f64) == "error invalid-input | flat | why: " ++ "bad-k-zone" ++ " | fix: " ++ "give a K-factor zone with 0 < KLO <= KHI < 1" : String}
