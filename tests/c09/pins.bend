import Base

import ../../src/c00/types.bend as T

import ../../src/c05/solve.bend as SV

import ../../src/c06/xp.bend as X

import ../../src/c06/model.bend as M

import ../../src/c06/sx.bend as S

import ../../src/c06/zone.bend as Z

import ../../src/c09/feat.bend as F9

def ps_xs(r: S.PS) -> List<&2, S.Sx>:
  S.PS{ok, xs} = r
  xs

def op1(+src: String) -> M.Op:
  S.op_of(S.sx_nth(ps_xs(S.parse(src)), 0n), [])

def w_of(o: M.Op) -> List<&2, U64>:
  M.op_w(o, X.env_of([]))

def eq_u(a: List<&2, U64>, +b: List<&2, U64>) -> Bool:
  match a:
    case []:
      match b:
        case []: True{}
        case h <> t: False{}
    case h <> t:
      match b:
        case []: False{}
        case x <> y: Bool.and(U64.is_eq(h, x), eq_u(t, y))

def same_op(+src: String) -> Bool:
  +o = op1(src)
  eq_u(w_of(o), w_of(op1(S.sx_show(S.op_sx(o, [])))))

def tag_head(ws: List<&2, U64>) -> U64:
  match ws:
    case []: 0u64
    case h <> t: h

def tag_of(+src: String) -> U64:
  tag_head(w_of(op1(src)))

def unk_name(o: M.Op) -> String:
  match o:
    case M.O_unk{name}: name
    case _: ""

def sw_g(o: M.Op) -> U64:
  match o:
    case M.O_sw_line{z, rs, g, gd, tw}: g
    case M.O_sw_arc{deg, rs, g, gd, tw}: g
    case _: 9u64

def sw_gd(o: M.Op) -> U64:
  match o:
    case M.O_sw_line{z, rs, g, gd, tw}: gd
    case M.O_sw_arc{deg, rs, g, gd, tw}: gd
    case _: 9u64

def rg() -> String:
  "(region (path 0 0 (line 1 0) (line 1 1) (line 0 1)))"

def eqb(+a: F64, +b: F64) -> Bool:
  U64.is_eq(F64.bits(a), F64.bits(b))

def fillet_closed() -> F64:
  F64.add(896.0f64, F64.div(F64.mul(76.0f64, F9.pi()), 3.0f64))

def tol0() -> T.Tol:
  T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64)

def frees(n: Nat) -> List<&2, Bool>:
  match n:
    case 0n: []
    case 1n+k: True{} <> frees(k)

def sd_rep(s: SV.SD) -> SV.RRep:
  SV.SD{sol, rep} = s
  rep

def tri() -> SV.SD:
  SV.rigid_report([0.0f64, 0.0f64, 3.0f64, 0.0f64, 0.0f64, 4.0f64], frees(6n),
    [SV.K_dist{1u64, SV.Pt{0n, 1n}, SV.Pt{2n, 3n}, 3.0f64},
     SV.K_dist{2u64, SV.Pt{0n, 1n}, SV.Pt{4n, 5n}, 4.0f64},
     SV.K_dist{3u64, SV.Pt{2n, 3n}, SV.Pt{4n, 5n}, 5.0f64}], tol0(), 32n)

def path3() -> SV.SD:
  SV.rigid_report([0.0f64, 0.0f64, 1.0f64, 0.0f64, 2.0f64, 0.0f64, 3.0f64, 0.0f64], frees(8n),
    [SV.K_dist{1u64, SV.Pt{0n, 1n}, SV.Pt{2n, 3n}, 1.0f64},
     SV.K_dist{2u64, SV.Pt{2n, 3n}, SV.Pt{4n, 5n}, 1.0f64},
     SV.K_dist{3u64, SV.Pt{4n, 5n}, SV.Pt{6n, 7n}, 1.0f64}], tol0(), 32n)

def rectd() -> SV.SD:
  SV.rigid_report([0.0f64, 0.0f64, 3.0f64, 0.0f64, 3.0f64, 4.0f64, 0.0f64, 4.0f64], frees(8n),
    [SV.K_dist{1u64, SV.Pt{0n, 1n}, SV.Pt{2n, 3n}, 3.0f64},
     SV.K_dist{2u64, SV.Pt{2n, 3n}, SV.Pt{4n, 5n}, 4.0f64},
     SV.K_dist{3u64, SV.Pt{4n, 5n}, SV.Pt{6n, 7n}, 3.0f64},
     SV.K_dist{4u64, SV.Pt{6n, 7n}, SV.Pt{0n, 1n}, 4.0f64},
     SV.K_dist{5u64, SV.Pt{0n, 1n}, SV.Pt{4n, 5n}, 5.0f64}], tol0(), 32n)

def tancc() -> SV.SD:
  SV.rigid_report([0.0f64, 0.0f64, 5.0f64, 0.0f64, 1.0f64, 1.0f64], frees(6n),
    [SV.K_tan_cc{1u64, SV.Pt{0n, 1n}, 4n, SV.Pt{2n, 3n}, 5n}], tol0(), 32n)

def dragp() -> SV.SD:
  SV.solve_drag([0.0f64, 0.0f64, 1.0f64, 0.0f64, 4.0f64, 0.0f64, 5.0f64, 0.0f64], frees(8n),
    [SV.K_dist{1u64, SV.Pt{0n, 1n}, SV.Pt{2n, 3n}, 1.0f64},
     SV.K_dist{2u64, SV.Pt{4n, 5n}, SV.Pt{6n, 7n}, 1.0f64}], tol0(), 16n, [0n])

def f_at(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: 0.0f64
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: f_at(t, j)

def drag_clean() -> Bool:
  +ps = SV.sd_ps(dragp())
  Bool.and(Bool.and(eqb(f_at(ps, 4n), 4.0f64), eqb(f_at(ps, 5n), 0.0f64)),
    Bool.and(eqb(f_at(ps, 6n), 5.0f64), eqb(f_at(ps, 7n), 0.0f64)))

def zone_ops_loaded__got() -> Bool:
  Z.zones_ok([])

def zone_ops_loaded__want() -> Bool:
  True{}

def tag_sweep_line__got() -> U64:
  tag_of("(sweep (line 5) " ++ rg() ++ ")")

def tag_sweep_line__want() -> U64:
  17u64

def tag_sweep_arc__got() -> U64:
  tag_of("(sweep (arc 90) " ++ rg() ++ ")")

def tag_sweep_arc__want() -> U64:
  18u64

def tag_loft__got() -> U64:
  tag_of("(loft 5 " ++ rg() ++ " " ++ rg() ++ ")")

def tag_loft__want() -> U64:
  19u64

def tag_chamfer__got() -> U64:
  tag_of("(chamfer 1 1)")

def tag_chamfer__want() -> U64:
  20u64

def tag_fillet__got() -> U64:
  tag_of("(fillet 1 2)")

def tag_fillet__want() -> U64:
  21u64

def tag_fillet_edge__got() -> U64:
  tag_of("(fillet 1 (edge 0) 1 2)")

def tag_fillet_edge__want() -> U64:
  22u64

def tag_draft__got() -> U64:
  tag_of("(draft 1 1)")

def tag_draft__want() -> U64:
  23u64

def tag_offset__got() -> U64:
  tag_of("(offset 1 1)")

def tag_offset__want() -> U64:
  24u64

def tag_shell__got() -> U64:
  tag_of("(shell 1 1)")

def tag_shell__want() -> U64:
  25u64

def tag_thicken__got() -> U64:
  tag_of("(thicken 1 1)")

def tag_thicken__want() -> U64:
  26u64

def tag_pattern_linear__got() -> U64:
  tag_of("(pattern 1 (linear 2 20 1 0 1 0))")

def tag_pattern_linear__want() -> U64:
  27u64

def tag_pattern_circular__got() -> U64:
  tag_of("(pattern 1 (circular 4 20))")

def tag_pattern_circular__want() -> U64:
  28u64

def tag_holes_linear__got() -> U64:
  tag_of("(pattern-holes 1 (face 1 0 top) (linear 2 2 4 4 2 2) (hole 0.5) through)")

def tag_holes_linear__want() -> U64:
  29u64

def tag_holes_circular__got() -> U64:
  tag_of("(pattern-holes 1 (face 1 0 top) (circular 4 2 5 5) (hole 0.5) 2)")

def tag_holes_circular__want() -> U64:
  30u64

def fillet_is_admitted__got() -> String:
  M.op_name(op1("(fillet 1 2)"))

def fillet_is_admitted__want() -> String:
  "fillet"

def fillet_arity_unknown__got() -> String:
  unk_name(op1("(fillet 1 2 3)"))

def fillet_arity_unknown__want() -> String:
  "fillet"

def loft_g2_unknown__got() -> String:
  unk_name(op1("(loft 5 " ++ rg() ++ " " ++ rg() ++ " (continuity g2))"))

def loft_g2_unknown__want() -> String:
  "loft"

def guide_line_code__got() -> U64:
  sw_g(op1("(sweep (line 4) " ++ rg() ++ " (guide (line 9)))"))

def guide_line_code__want() -> U64:
  1u64

def guide_line_drops_distance__got() -> U64:
  sw_gd(op1("(sweep (line 4) " ++ rg() ++ " (guide (line 9)))"))

def guide_line_drops_distance__want() -> U64:
  0u64

def rt_fillet__got() -> Bool:
  same_op("(fillet 1 2)")

def rt_fillet__want() -> Bool:
  True{}

def rt_sweep__got() -> Bool:
  same_op("(sweep (arc 90) " ++ rg() ++ " (guide (arc 90)) (twist 1))")

def rt_sweep__want() -> Bool:
  True{}

def rt_shell_open__got() -> Bool:
  same_op("(shell 1 1 open)")

def rt_shell_open__want() -> Bool:
  True{}

def why_angle_refuses__got() -> String:
  F9.why_sw_ang(45u64)

def why_angle_refuses__want() -> String:
  "sweep-angle-not-certified"

def why_angle_admits__got() -> String:
  F9.why_sw_ang(90u64)

def why_angle_admits__want() -> String:
  ""

def why_guide_foreign__got() -> String:
  F9.why_guide(0u64, 2u64, 90u64, 0u64)

def why_guide_foreign__want() -> String:
  "guide-not-admitted"

def why_twist_refuses__got() -> String:
  F9.why_twist(1u64)

def why_twist_refuses__want() -> String:
  "twist-not-admitted"

def why_g1_refuses__got() -> String:
  F9.why_loft_g1(1u64)

def why_g1_refuses__want() -> String:
  "continuity-not-met"

def vol_chamfer_box_980__got() -> Bool:
  eqb(F9.vol_chamfer_box(10.0f64, 10.0f64, 10.0f64, 1.0f64), 980.0f64)

def vol_chamfer_box_980__want() -> Bool:
  True{}

def vol_chamfer_cyl__got() -> Bool:
  eqb(F9.vol_chamfer_cyl(5.0f64, 10.0f64, 1.0f64), F64.div(F64.mul(722.0f64, F9.pi()), 3.0f64))

def vol_chamfer_cyl__want() -> Bool:
  True{}

def vol_fillet_box_closed__got() -> Bool:
  eqb(F9.vol_fillet_box(10.0f64, 10.0f64, 10.0f64, 1.0f64), fillet_closed())

def vol_fillet_box_closed__want() -> Bool:
  True{}

def vol_fillet_box_not_cube__got() -> Bool:
  eqb(F9.vol_fillet_box(10.0f64, 10.0f64, 10.0f64, 1.0f64), 1000.0f64)

def vol_fillet_box_not_cube__want() -> Bool:
  False{}

def vol_fillet_cyl__got() -> Bool:
  eqb(F9.vol_fillet_cyl(5.0f64, 10.0f64, 1.0f64), F64.add(F64.mul(232.0f64, F9.pi()), F64.mul(4.0f64, F64.mul(F9.pi(), F9.pi()))))

def vol_fillet_cyl__want() -> Bool:
  True{}

def vol_fillet_edge_equal__got() -> Bool:
  eqb(F9.vol_fillet_edge(10.0f64, 10.0f64, 10.0f64, 1.0f64, 1.0f64), F64.add(990.0f64, F64.mul(2.5f64, F9.pi())))

def vol_fillet_edge_equal__want() -> Bool:
  True{}

def vol_fillet_edge_cone__got() -> Bool:
  eqb(F9.vol_fillet_edge(10.0f64, 10.0f64, 10.0f64, 1.0f64, 2.0f64), F64.add(F64.sub(1000.0f64, F64.div(70.0f64, 3.0f64)), F64.div(F64.mul(70.0f64, F9.pi()), 12.0f64)))

def vol_fillet_edge_cone__want() -> Bool:
  True{}

def vol_draft_380__got() -> Bool:
  eqb(F9.vol_draft(10.0f64, 8.0f64, 6.0f64, 1.0f64), 380.0f64)

def vol_draft_380__want() -> Bool:
  True{}

def vol_offset_box__got() -> Bool:
  eqb(F9.vol_offset_box(10.0f64, 10.0f64, 10.0f64, 1.0f64), 1728.0f64)

def vol_offset_box__want() -> Bool:
  True{}

def vol_offset_cyl__got() -> Bool:
  eqb(F9.vol_offset_cyl(5.0f64, 10.0f64, 1.0f64), F64.mul(432.0f64, F9.pi()))

def vol_offset_cyl__want() -> Bool:
  True{}

def vol_shell_box__got() -> Bool:
  eqb(F9.vol_shell_box(10.0f64, 10.0f64, 10.0f64, 1.0f64), 488.0f64)

def vol_shell_box__want() -> Bool:
  True{}

def vol_shell_open__got() -> Bool:
  eqb(F9.vol_shell_open(10.0f64, 10.0f64, 10.0f64, 1.0f64), 424.0f64)

def vol_shell_open__want() -> Bool:
  True{}

def vol_shell_cyl__got() -> Bool:
  eqb(F9.vol_shell_cyl(5.0f64, 10.0f64, 1.0f64), F64.mul(122.0f64, F9.pi()))

def vol_shell_cyl__want() -> Bool:
  True{}

def vol_loft_squares__got() -> Bool:
  eqb(F9.vol_frust(5.0f64, F64.sub(0.0f64, 5.0f64), F64.sub(0.0f64, 5.0f64), 5.0f64, 5.0f64, F64.sub(0.0f64, 3.0f64), F64.sub(0.0f64, 3.0f64), 3.0f64, 3.0f64), F64.div(980.0f64, 3.0f64))

def vol_loft_squares__want() -> Bool:
  True{}

def vol_loft_prismatoid__got() -> Bool:
  eqb(F9.vol_frust(6.0f64, 0.0f64, 0.0f64, 10.0f64, 8.0f64, 2.0f64, 2.0f64, 8.0f64, 6.0f64), 296.0f64)

def vol_loft_prismatoid__want() -> Bool:
  True{}

def thicken_matches_offset__got() -> Bool:
  eqb(F9.vol_offset_box(10.0f64, 8.0f64, 6.0f64, 1.0f64), F64.mul(F64.mul(12.0f64, 10.0f64), 8.0f64))

def thicken_matches_offset__want() -> Bool:
  True{}

def sw_quarter__got() -> Bool:
  eqb(F9.sw_k(90u64), 0.25f64)

def sw_quarter__want() -> Bool:
  True{}

def rigid_path__got() -> Nat:
  SV.rr_n(sd_rep(path3()))

def rigid_path__want() -> Nat:
  3n

def rigid_triangle__got() -> Nat:
  SV.rr_n(sd_rep(tri()))

def rigid_triangle__want() -> Nat:
  1n

def rigid_rectangle__got() -> Nat:
  SV.rr_n(sd_rep(rectd()))

def rigid_rectangle__want() -> Nat:
  1n

def rigid_tangent_whole__got() -> String:
  SV.rr_why(sd_rep(tancc()))

def rigid_tangent_whole__want() -> String:
  "kind-not-decomposed"

def rigid_drag_clean__got() -> Bool:
  drag_clean()

def rigid_drag_clean__want() -> Bool:
  True{}
