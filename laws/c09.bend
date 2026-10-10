import Base
import ../src/c00/types.bend as T
import ../src/c05/solve.bend as SV
import ../src/c06/xp.bend as X
import ../src/c06/model.bend as M
import ../src/c06/sx.bend as S
import ../src/c06/zone.bend as Z
import ../src/c09/feat.bend as F9

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

law zone_ops_loaded:
  {Z.zones_ok([]) == True{} : Bool}

def zone_ops_loaded():
  {==}

law tag_sweep_line:
  {tag_of("(sweep (line 5) " ++ rg() ++ ")") == 17u64 : U64}

def tag_sweep_line():
  {==}

law tag_sweep_arc:
  {tag_of("(sweep (arc 90) " ++ rg() ++ ")") == 18u64 : U64}

def tag_sweep_arc():
  {==}

law tag_loft:
  {tag_of("(loft 5 " ++ rg() ++ " " ++ rg() ++ ")") == 19u64 : U64}

def tag_loft():
  {==}

law tag_chamfer:
  {tag_of("(chamfer 1 1)") == 20u64 : U64}

def tag_chamfer():
  {==}

law tag_fillet:
  {tag_of("(fillet 1 2)") == 21u64 : U64}

def tag_fillet():
  {==}

law tag_fillet_edge:
  {tag_of("(fillet 1 (edge 0) 1 2)") == 22u64 : U64}

def tag_fillet_edge():
  {==}

law tag_draft:
  {tag_of("(draft 1 1)") == 23u64 : U64}

def tag_draft():
  {==}

law tag_offset:
  {tag_of("(offset 1 1)") == 24u64 : U64}

def tag_offset():
  {==}

law tag_shell:
  {tag_of("(shell 1 1)") == 25u64 : U64}

def tag_shell():
  {==}

law tag_thicken:
  {tag_of("(thicken 1 1)") == 26u64 : U64}

def tag_thicken():
  {==}

law tag_pattern_linear:
  {tag_of("(pattern 1 (linear 2 20 1 0 1 0))") == 27u64 : U64}

def tag_pattern_linear():
  {==}

law tag_pattern_circular:
  {tag_of("(pattern 1 (circular 4 20))") == 28u64 : U64}

def tag_pattern_circular():
  {==}

law tag_holes_linear:
  {tag_of("(pattern-holes 1 (face 1 0 top) (linear 2 2 4 4 2 2) (hole 0.5) through)") == 29u64 : U64}

def tag_holes_linear():
  {==}

law tag_holes_circular:
  {tag_of("(pattern-holes 1 (face 1 0 top) (circular 4 2 5 5) (hole 0.5) 2)") == 30u64 : U64}

def tag_holes_circular():
  {==}

law fillet_is_admitted:
  {M.op_name(op1("(fillet 1 2)")) == "fillet" : String}

def fillet_is_admitted():
  {==}

law fillet_arity_unknown:
  {unk_name(op1("(fillet 1 2 3)")) == "fillet" : String}

def fillet_arity_unknown():
  {==}

law loft_g2_unknown:
  {unk_name(op1("(loft 5 " ++ rg() ++ " " ++ rg() ++ " (continuity g2))")) == "loft" : String}

def loft_g2_unknown():
  {==}

law guide_line_code:
  {sw_g(op1("(sweep (line 4) " ++ rg() ++ " (guide (line 9)))")) == 1u64 : U64}

def guide_line_code():
  {==}

law guide_line_drops_distance:
  {sw_gd(op1("(sweep (line 4) " ++ rg() ++ " (guide (line 9)))")) == 0u64 : U64}

def guide_line_drops_distance():
  {==}

law rt_fillet:
  {same_op("(fillet 1 2)") == True{} : Bool}

def rt_fillet():
  {==}

law rt_sweep:
  {same_op("(sweep (arc 90) " ++ rg() ++ " (guide (arc 90)) (twist 1))") == True{} : Bool}

def rt_sweep():
  {==}

law rt_shell_open:
  {same_op("(shell 1 1 open)") == True{} : Bool}

def rt_shell_open():
  {==}

law why_angle_refuses:
  {F9.why_sw_ang(45u64) == "sweep-angle-not-certified" : String}

def why_angle_refuses():
  {==}

law why_angle_admits:
  {F9.why_sw_ang(90u64) == "" : String}

def why_angle_admits():
  {==}

law why_guide_foreign:
  {F9.why_guide(0u64, 2u64, 90u64, 0u64) == "guide-not-admitted" : String}

def why_guide_foreign():
  {==}

law why_twist_refuses:
  {F9.why_twist(1u64) == "twist-not-admitted" : String}

def why_twist_refuses():
  {==}

law why_g1_refuses:
  {F9.why_loft_g1(1u64) == "continuity-not-met" : String}

def why_g1_refuses():
  {==}

law vol_chamfer_box_980:
  {eqb(F9.vol_chamfer_box(10.0f64, 10.0f64, 10.0f64, 1.0f64), 980.0f64) == True{} : Bool}

def vol_chamfer_box_980():
  {==}

law vol_chamfer_cyl:
  {eqb(F9.vol_chamfer_cyl(5.0f64, 10.0f64, 1.0f64), F64.div(F64.mul(722.0f64, F9.pi()), 3.0f64)) == True{} : Bool}

def vol_chamfer_cyl():
  {==}

law vol_fillet_box_closed:
  {eqb(F9.vol_fillet_box(10.0f64, 10.0f64, 10.0f64, 1.0f64), fillet_closed()) == True{} : Bool}

def vol_fillet_box_closed():
  {==}

law vol_fillet_box_not_cube:
  {eqb(F9.vol_fillet_box(10.0f64, 10.0f64, 10.0f64, 1.0f64), 1000.0f64) == False{} : Bool}

def vol_fillet_box_not_cube():
  {==}

law vol_fillet_cyl:
  {eqb(F9.vol_fillet_cyl(5.0f64, 10.0f64, 1.0f64), F64.add(F64.mul(232.0f64, F9.pi()), F64.mul(4.0f64, F64.mul(F9.pi(), F9.pi())))) == True{} : Bool}

def vol_fillet_cyl():
  {==}

law vol_fillet_edge_equal:
  {eqb(F9.vol_fillet_edge(10.0f64, 10.0f64, 10.0f64, 1.0f64, 1.0f64), F64.add(990.0f64, F64.mul(2.5f64, F9.pi()))) == True{} : Bool}

def vol_fillet_edge_equal():
  {==}

law vol_fillet_edge_cone:
  {eqb(F9.vol_fillet_edge(10.0f64, 10.0f64, 10.0f64, 1.0f64, 2.0f64), F64.add(F64.sub(1000.0f64, F64.div(70.0f64, 3.0f64)), F64.div(F64.mul(70.0f64, F9.pi()), 12.0f64))) == True{} : Bool}

def vol_fillet_edge_cone():
  {==}

law vol_draft_380:
  {eqb(F9.vol_draft(10.0f64, 8.0f64, 6.0f64, 1.0f64), 380.0f64) == True{} : Bool}

def vol_draft_380():
  {==}

law vol_offset_box:
  {eqb(F9.vol_offset_box(10.0f64, 10.0f64, 10.0f64, 1.0f64), 1728.0f64) == True{} : Bool}

def vol_offset_box():
  {==}

law vol_offset_cyl:
  {eqb(F9.vol_offset_cyl(5.0f64, 10.0f64, 1.0f64), F64.mul(432.0f64, F9.pi())) == True{} : Bool}

def vol_offset_cyl():
  {==}

law vol_shell_box:
  {eqb(F9.vol_shell_box(10.0f64, 10.0f64, 10.0f64, 1.0f64), 488.0f64) == True{} : Bool}

def vol_shell_box():
  {==}

law vol_shell_open:
  {eqb(F9.vol_shell_open(10.0f64, 10.0f64, 10.0f64, 1.0f64), 424.0f64) == True{} : Bool}

def vol_shell_open():
  {==}

law vol_shell_cyl:
  {eqb(F9.vol_shell_cyl(5.0f64, 10.0f64, 1.0f64), F64.mul(122.0f64, F9.pi())) == True{} : Bool}

def vol_shell_cyl():
  {==}

law vol_loft_squares:
  {eqb(F9.vol_frust(5.0f64, F64.sub(0.0f64, 5.0f64), F64.sub(0.0f64, 5.0f64), 5.0f64, 5.0f64, F64.sub(0.0f64, 3.0f64), F64.sub(0.0f64, 3.0f64), 3.0f64, 3.0f64), F64.div(980.0f64, 3.0f64)) == True{} : Bool}

def vol_loft_squares():
  {==}

law vol_loft_prismatoid:
  {eqb(F9.vol_frust(6.0f64, 0.0f64, 0.0f64, 10.0f64, 8.0f64, 2.0f64, 2.0f64, 8.0f64, 6.0f64), 296.0f64) == True{} : Bool}

def vol_loft_prismatoid():
  {==}

law thicken_matches_offset:
  {eqb(F9.vol_offset_box(10.0f64, 8.0f64, 6.0f64, 1.0f64), F64.mul(F64.mul(12.0f64, 10.0f64), 8.0f64)) == True{} : Bool}

def thicken_matches_offset():
  {==}

law sw_quarter:
  {eqb(F9.sw_k(90u64), 0.25f64) == True{} : Bool}

def sw_quarter():
  {==}

law rigid_path:
  {SV.rr_n(sd_rep(path3())) == 3n : Nat}

def rigid_path():
  {==}

law rigid_triangle:
  {SV.rr_n(sd_rep(tri())) == 1n : Nat}

def rigid_triangle():
  {==}

law rigid_rectangle:
  {SV.rr_n(sd_rep(rectd())) == 1n : Nat}

def rigid_rectangle():
  {==}

law rigid_tangent_whole:
  {SV.rr_why(sd_rep(tancc())) == "kind-not-decomposed" : String}

def rigid_tangent_whole():
  {==}

law rigid_drag_clean:
  {drag_clean() == True{} : Bool}

def rigid_drag_clean():
  {==}
