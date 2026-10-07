import Base
import ../src/c00/types.bend as T
import ../src/c01/types.bend as V
import ../src/c03/types.bend as G
import ../src/c06/surfx.bend as SX
import ../src/c06/xp.bend as X
import ../src/c06/prof.bend as F
import ../src/c06/iv.bend as I
import ../src/c06/model.bend as M
import ../src/c06/sx.bend as S
import ../src/c06/ear.bend as EA
import ../src/c06/zone.bend as Z

def org() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def axis_z() -> V.Dir:
  V.Dr{0.0f64, 0.0f64, 1.0f64}

def trim_wide() -> G.GVal:
  G.GV_cy{G.Cy{org(), V.Dr{0.0f64, 0.0f64, 10.0f64}, 1.0f64}}

def ps_xs(r: S.PS) -> List<&2, S.Sx>:
  S.PS{ok, xs} = r
  xs

def part(+src: String) -> M.Part:
  S.part_of(ps_xs(S.parse(src)))

def ev(+src: String) -> List<&2, M.CE>:
  M.ev_part(part(src), [])

def r_s(r: M.NR) -> String:
  match r:
    case M.NR_ok{b, fx}: "ok " ++ M.fx_show(fx)
    case M.NR_err{k, d}:
      M.Dg{w, l, y, f} = d
      "err " ++ T.FailKind.show(k) ++ " " ++ y

def last_r(cs: List<&2, M.CE>, +d: M.NR) -> M.NR:
  match cs:
    case []: d
    case c <> t:
      M.CE{id, key, r} = c
      last_r(t, r)

def last_s(+src: String) -> String:
  r_s(last_r(ev(src), M.bad("-", "-", "empty", "-")))

def k(+v: F64) -> X.Xp:
  X.X_k{v}

def env1() -> X.Env:
  X.env_of([X.PV{1u64, 100.0f64}])

def ck_code(c: F.CK) -> U64:
  match c:
    case F.CK_ok{ls, ps}: 0u64
    case F.CK_err{e}: F.er_code(e)

def ck_pars(c: F.CK) -> List<&2, Nat>:
  match c:
    case F.CK_ok{ls, ps}: ps
    case F.CK_err{e}: []

def pchk(+src: String) -> F.CK:
  F.prof_check(S.rgs_of(S.sx_xs(S.sx_nth(ps_xs(S.parse(src)), 0n)), []), X.env_of([]))

def rr() -> String:
  "(path 5 0 (line 95 0) (arc 95 5 5 100 5 ccw) (line 100 55) (arc 95 55 5 95 60 ccw) (line 5 60) (arc 5 55 5 0 55 ccw) (line 0 5) (arc 5 5 5 5 0 ccw))"

def slot() -> String:
  "(path 50 25 (line 70 25) (arc 70 30 5 70 35 ccw) (line 50 35) (arc 50 30 5 50 25 ccw))"

def pr_one(r: F.PR) -> F64:
  match r:
    case F.PR_ok{ps}: F.pc_bx(F.pc_hd(ps))
    case F.PR_err{c}: 0.0f64

def it_any() -> M.It:
  M.It{M.M_create{}, M.C_any{}, M.C_any{}, M.C_any{}, M.C_any{}}

def zpart(+lo: F64, +hi: F64, o: M.Op) -> M.Part:
  M.Pt{[M.Pm{1u64, "X", M.Dm{10.0f64, lo, hi}}, M.Pm{2u64, "Y", M.Dm{4.0f64, 4.0f64, 4.0f64}}], [M.Nd{1u64, o, it_any()}, M.Nd{2u64, M.O_move{1u64, X.X_k{1.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}, 4u64}, it_any()}]}

def z_has(r: Z.ZR, +a: F64, +b: F64) -> Bool:
  match r:
    case Z.Z_ok{+v, ar}: Bool.and(Bool.and(F64.is_le(I.i_lo(v), a), F64.is_le(b, I.i_hi(v))), F64.is_lt(F64.sub(I.i_hi(v), I.i_lo(v)), F64.add(F64.sub(b, a), 0.000001f64)))
    case Z.Z_err{w}: False{}

def z_why(r: Z.ZR) -> String:
  match r:
    case Z.Z_ok{v, a}: "ok"
    case Z.Z_err{w}: w

def sc_has(l: List<&2, I.I>, +i: Nat, +v: F64, +w: F64) -> Bool:
  +a = M.i_nth(l, i)
  Bool.and(Bool.and(F64.is_le(I.i_lo(a), v), F64.is_le(v, I.i_hi(a))), F64.is_lt(F64.sub(I.i_hi(a), I.i_lo(a)), w))

def sc_unit(+l: List<&2, I.I>) -> Bool:
  +n = I.iadd(I.isq(M.i_nth(l, 0n)), I.isq(M.i_nth(l, 1n)))
  Bool.and(F64.is_le(I.i_lo(n), 1.0f64), F64.is_le(1.0f64, I.i_hi(n)))

law ok_circ_nx_zero:
  {SX.circ_nx(0.0f64) == 1.0f64 : F64}

def ok_circ_nx_zero():
  {==}

law ok_circ_ny_zero:
  {SX.circ_ny(0.0f64) == 0.0f64 : F64}

def ok_circ_ny_zero():
  {==}

law ok_circ_nx_one:
  {SX.circ_nx(1.0f64) == F64.neg(1.0f64) : F64}

def ok_circ_nx_one():
  {==}

law ok_circ_ny_one:
  {SX.circ_ny(1.0f64) == 0.0f64 : F64}

def ok_circ_ny_one():
  {==}

law ok_t_in11:
  {SX.t_in11(0.0f64) == True{} : Bool}

def ok_t_in11():
  {==}

law neg_t_in11:
  {SX.t_in11(2.0f64) == False{} : Bool}

def neg_t_in11():
  {==}

law ok_qf_wi_x:
  {SX.qf_wi(1.0f64, 0.0f64, 0.0f64) == 1u64 : U64}

def ok_qf_wi_x():
  {==}

law ok_qf_wi_z:
  {SX.qf_wi(0.0f64, 0.0f64, 5.0f64) == 0u64 : U64}

def ok_qf_wi_z():
  {==}

law ok_norm3:
  {SX.norm3(3.0f64, 4.0f64, 0.0f64) == 5.0f64 : F64}

def ok_norm3():
  {==}

law ok_qframe_x:
  {SX.qframe(V.Dr{1.0f64, 0.0f64, 0.0f64})
    == SX.QFr{V.Dr{0.0f64, 1.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}} : SX.QFr}

def ok_qframe_x():
  {==}

law ok_qframe_y:
  {SX.qframe(V.Dr{0.0f64, 1.0f64, 0.0f64})
    == SX.QFr{V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}} : SX.QFr}

def ok_qframe_y():
  {==}

law ok_qframe_z:
  {SX.qframe(V.Dr{0.0f64, 0.0f64, 1.0f64})
    == SX.QFr{V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}} : SX.QFr}

def ok_qframe_z():
  {==}

law ok_spine:
  {SX.spine_c(1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 1.0f64, 10.0f64)
    == V.Pt{1.0f64, 2.0f64, 13.0f64} : V.Point}

def ok_spine():
  {==}

law ok_surf_cyl:
  {SX.surf_cyl(G.Cy{org(), axis_z(), 1.0f64}, 0.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{1.0f64, 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_cyl():
  {==}

law neg_surf_cyl_t:
  {SX.surf_cyl(G.Cy{org(), axis_z(), 1.0f64}, 2.0f64, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_cyl_t():
  {==}

law neg_surf_cyl_r:
  {SX.surf_cyl(G.Cy{org(), axis_z(), 0.0f64}, 0.0f64, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_cyl_r():
  {==}

law ok_surf_cone:
  {SX.surf_cone(G.Co{org(), axis_z(), 1.0f64}, 0.0f64, 2.0f64)
    == G.Gok{G.GV_p{V.Pt{2.0f64, 0.0f64, 2.0f64}}} : G.GRes}

def ok_surf_cone():
  {==}

law neg_surf_cone_h:
  {SX.surf_cone(G.Co{org(), axis_z(), 1.0f64}, 0.0f64, F64.neg(2.0f64))
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_cone_h():
  {==}

law ok_surf_tor:
  {SX.surf_tor(G.To{org(), axis_z(), 5.0f64, 1.0f64}, 0.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{6.0f64, 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_tor():
  {==}

law neg_surf_tor_spindle:
  {SX.surf_tor(G.To{org(), axis_z(), 1.0f64, 5.0f64}, 0.0f64, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_tor_spindle():
  {==}

law ok_surf_sph_east:
  {SX.surf_sph(G.Sp{org(), 2.0f64}, 1.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{2.0f64, 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_sph_east():
  {==}

law ok_surf_sph_west:
  {SX.surf_sph(G.Sp{org(), 2.0f64}, F64.neg(1.0f64), 0.0f64)
    == G.Gok{G.GV_p{V.Pt{F64.neg(2.0f64), 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_sph_west():
  {==}

law ok_surf_sph_pole:
  {SX.surf_sph(G.Sp{org(), 2.0f64}, 0.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{0.0f64, 0.0f64, 2.0f64}}} : G.GRes}

def ok_surf_sph_pole():
  {==}

law ok_surf_at_sph:
  {SX.surf_at(G.GV_sp{G.Sp{org(), 2.0f64}}, 1.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{2.0f64, 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_at_sph():
  {==}

law neg_surf_at_other:
  {SX.surf_at(G.GV_f{1.0f64}, 0.0f64, 0.0f64) == G.gerr(T.F_unsupported{}) : G.GRes}

def neg_surf_at_other():
  {==}

law ok_is_quad_cyl:
  {SX.surf_is_quad(G.GV_cy{G.Cy{org(), axis_z(), 1.0f64}}) == True{} : Bool}

def ok_is_quad_cyl():
  {==}

law ok_is_quad_sph:
  {SX.surf_is_quad(G.GV_sp{G.Sp{org(), 2.0f64}}) == True{} : Bool}

def ok_is_quad_sph():
  {==}

law neg_is_quad_f:
  {SX.surf_is_quad(G.GV_f{1.0f64}) == False{} : Bool}

def neg_is_quad_f():
  {==}

law ok_ring_cyl:
  {SX.ring_cyl(G.Cy{org(), axis_z(), 2.0f64}, 3.0f64)
    == G.Gok{G.GV_cc{G.Cc{V.Pt{0.0f64, 0.0f64, 3.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 1.0f64, 0.0f64}, 2.0f64}}} : G.GRes}

def ok_ring_cyl():
  {==}

law neg_ring_cyl_r:
  {SX.ring_cyl(G.Cy{org(), axis_z(), 0.0f64}, 3.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_cyl_r():
  {==}

law ok_ring_cone:
  {SX.ring_cone(G.Co{org(), axis_z(), 1.0f64}, 2.0f64)
    == G.Gok{G.GV_cc{G.Cc{V.Pt{0.0f64, 0.0f64, 2.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 1.0f64, 0.0f64}, 2.0f64}}} : G.GRes}

def ok_ring_cone():
  {==}

law neg_ring_cone_h:
  {SX.ring_cone(G.Co{org(), axis_z(), 1.0f64}, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_cone_h():
  {==}

law ok_ring_tor_p:
  {SX.ring_tor_p(G.To{org(), axis_z(), 5.0f64, 1.0f64}, 0.0f64)
    == G.Gok{G.GV_cc{G.Cc{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 1.0f64, 0.0f64}, 6.0f64}}} : G.GRes}

def ok_ring_tor_p():
  {==}

law neg_ring_tor_p_spin:
  {SX.ring_tor_p(G.To{org(), axis_z(), 1.0f64, 5.0f64}, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_tor_p_spin():
  {==}

law ok_ring_tor_m:
  {SX.ring_tor_m(G.To{org(), axis_z(), 5.0f64, 1.0f64}, 0.0f64)
    == G.Gok{G.GV_cc{G.Cc{V.Pt{5.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 1.0f64}, 1.0f64}}} : G.GRes}

def ok_ring_tor_m():
  {==}

law neg_ring_tor_m_t:
  {SX.ring_tor_m(G.To{org(), axis_z(), 5.0f64, 1.0f64}, 2.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_tor_m_t():
  {==}

law ok_kind_tag_cyl:
  {SX.surf_kind_tag(G.GV_cy{G.Cy{org(), axis_z(), 1.0f64}}) == 2u64 : U64}

def ok_kind_tag_cyl():
  {==}

law ok_kind_tag_sph:
  {SX.surf_kind_tag(G.GV_sp{G.Sp{org(), 2.0f64}}) == 5u64 : U64}

def ok_kind_tag_sph():
  {==}

law neg_kind_tag_f:
  {SX.surf_kind_tag(G.GV_f{1.0f64}) == 99u64 : U64}

def neg_kind_tag_f():
  {==}

law ok_kind_show_cyl:
  {SX.surf_kind_show(G.GV_cy{G.Cy{org(), axis_z(), 1.0f64}}) == "cyl" : String}

def ok_kind_show_cyl():
  {==}

law ok_kind_show_sph:
  {SX.surf_kind_show(G.GV_sp{G.Sp{org(), 2.0f64}}) == "sphere" : String}

def ok_kind_show_sph():
  {==}

law neg_kind_show_f:
  {SX.surf_kind_show(G.GV_f{1.0f64}) == "other" : String}

def neg_kind_show_f():
  {==}

law ok_qframe_nx:
  {SX.qframe(V.Dr{F64.neg(1.0f64), 0.0f64, 0.0f64})
    == SX.QFr{V.Dr{0.0f64, 1.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, F64.neg(1.0f64)}} : SX.QFr}

def ok_qframe_nx():
  {==}

law ok_qframe_ny:
  {SX.qframe(V.Dr{0.0f64, F64.neg(1.0f64), 0.0f64})
    == SX.QFr{V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{F64.neg(1.0f64), 0.0f64, 0.0f64}} : SX.QFr}

def ok_qframe_ny():
  {==}

law ok_qframe_nz:
  {SX.qframe(V.Dr{0.0f64, 0.0f64, F64.neg(1.0f64)})
    == SX.QFr{V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, F64.neg(1.0f64), 0.0f64}} : SX.QFr}

def ok_qframe_nz():
  {==}

law neg_surf_at_axis:
  {SX.surf_at(trim_wide(), 0.0f64, 0.0f64) == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_at_axis():
  {==}

law neg_ring_cyl_axis:
  {SX.ring_cyl(G.Cy{org(), V.Dr{0.0f64, 0.0f64, 2.0f64}, 1.0f64}, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_cyl_axis():
  {==}

law xp_eval:
  {X.xp_ev(X.X_div{X.X_sub{X.X_p{1u64}, k(10.0f64)}, k(2.0f64)}, env1()) == 45.0f64 : F64}

def xp_eval():
  {==}

law xp_missing:
  {X.xp_miss(X.X_add{X.X_p{1u64}, X.X_p{7u64}}, env1()) == 8u64 : U64}

def xp_missing():
  {==}

law arc_ccw_split:
  {pr_one(F.arc_ccw(70.0f64, 30.0f64, 5.0f64, 70.0f64, 25.0f64, 70.0f64, 35.0f64)) == 75.0f64 : F64}

def arc_ccw_split():
  {==}

law arc_cw_split:
  {pr_one(F.arc_dir(False{}, 70.0f64, 30.0f64, 5.0f64, 70.0f64, 35.0f64, 70.0f64, 25.0f64)) == 75.0f64 : F64}

def arc_cw_split():
  {==}

law prof_plate_ok:
  {ck_pars(pchk("((region " ++ rr() ++ " (circle 20 30 4) " ++ slot() ++ "))")) == [0n, 1n, 1n] : List<&2, Nat>}

def prof_plate_ok():
  {==}

law prof_bowtie:
  {ck_code(pchk("((region (path 0 0 (line 10 10) (line 10 0) (line 0 10))))")) == 9u64 : U64}

def prof_bowtie():
  {==}

law prof_arc_off:
  {ck_code(pchk("((region (path 0 0 (line 10 0) (arc 10 5 5 10 10.1 ccw))))")) == 5u64 : U64}

def prof_arc_off():
  {==}

law prof_hole_out:
  {ck_code(pchk("((region " ++ rr() ++ " (circle 500 30 4)))")) == 12u64 : U64}

def prof_hole_out():
  {==}

law prof_hole_nest:
  {ck_code(pchk("((region " ++ rr() ++ " (circle 30 30 10) (circle 30 30 4)))")) == 13u64 : U64}

def prof_hole_nest():
  {==}

law prof_region_overlap:
  {ck_code(pchk("((region " ++ rr() ++ ") (region (circle 30 30 4)))")) == 14u64 : U64}

def prof_region_overlap():
  {==}

law prof_island:
  {ck_pars(pchk("((region " ++ rr() ++ " (circle 30 30 10)) (region (circle 30 30 4)))")) == [0n, 1n, 2n] : List<&2, Nat>}

def prof_island():
  {==}

law prof_zero_seg:
  {ck_code(pchk("((region (path 0 0 (line 0 0) (line 10 0) (line 10 10))))")) == 2u64 : U64}

def prof_zero_seg():
  {==}

law prof_neg_radius:
  {ck_code(pchk("((region (path 0 0 (line 10 0) (arc 10 5 -5 10 10 ccw))))")) == 3u64 : U64}

def prof_neg_radius():
  {==}

law prof_spike:
  {ck_code(pchk("((region (path 0 0 (line 20 0) (line 10 0) (line 10 10))))")) == 10u64 : U64}

def prof_spike():
  {==}

law prof_unknown_param:
  {ck_code(pchk("((region (path 0 0 (line Q 0) (line 10 10))))")) == 17u64 : U64}

def prof_unknown_param():
  {==}

law prof_cw_normalized:
  {ck_code(pchk("((region (path 0 0 (line 0 10) (line 10 10) (line 10 0))))")) == 0u64 : U64}

def prof_cw_normalized():
  {==}

law ev_bad_input_node:
  {String.eq(last_s("(node 2 (holes 1 (face 1 0 top) through (hole 50 30 3)) (intent remove any any 1 any))"),
    "err invalid-input input-node-missing-or-failed") == True{} : Bool}

def ev_bad_input_node():
  {==}

law ev_axis_cross:
  {String.eq(last_s("(node 1 (revolve (region (path -5 0 (line 10 0) (line 10 10) (line -5 10)))) (intent create any any 1 any))"),
    "err invalid-input profile-crosses-revolve-axis") == True{} : Bool}

def ev_axis_cross():
  {==}

law ev_axis_pinch:
  {String.eq(last_s("(node 1 (revolve (region (path 0 5 (line 10 0) (line 20 5) (line 10 10)))) (intent create any any 1 any))"),
    "err invalid-input axis-pinch") == True{} : Bool}

def ev_axis_pinch():
  {==}

law zone_box:
  {z_has(Z.zone(zpart(9.0f64, 11.0f64, M.O_box{X.X_p{1u64}, X.X_k{2.0f64}, X.X_k{3.0f64}}), 2u64), 54.0f64, 66.0f64) == True{} : Bool}

def zone_box():
  {==}

law zone_torus_overlap:
  {z_why(Z.zone(zpart(9.0f64, 11.0f64, M.O_tor{X.X_k{10.5f64}, X.X_p{1u64}}), 1u64)) == "dimension-not-certified-positive-over-zone" : String}

def zone_torus_overlap():
  {==}

law zone_box_nonpositive:
  {z_why(Z.zone(zpart(F64.neg(1.0f64), 11.0f64, M.O_box{X.X_p{1u64}, X.X_k{2.0f64}, X.X_k{3.0f64}}), 1u64)) == "dimension-not-certified-positive-over-zone" : String}

def zone_box_nonpositive():
  {==}

law zone_unordered:
  {z_why(Z.zone(zpart(11.0f64, 12.0f64, M.O_box{X.X_p{1u64}, X.X_k{2.0f64}, X.X_k{3.0f64}}), 1u64)) == "zone-not-ordered" : String}

def zone_unordered():
  {==}

law zone_prism_not_certified:
  {z_why(Z.zone(zpart(9.0f64, 11.0f64, M.O_prism{[], X.X_k{0.0f64}, X.X_p{1u64}}), 1u64)) == "topology-not-certified-over-zone" : String}

def zone_prism_not_certified():
  {==}

law sin_cos_30:
  {sc_has(I.sin_cos_deg(30.0f64), 1n, 0.5f64, 0.00000000000001f64) == True{} : Bool}

def sin_cos_30():
  {==}

law sin_cos_neg_150_unit:
  {Bool.and(sc_has(I.sin_cos_deg(F64.neg(150.0f64)), 1n, F64.neg(0.5f64), 0.00000000000001f64), sc_unit(I.sin_cos_deg(F64.neg(150.0f64)))) == True{} : Bool}

def sin_cos_neg_150_unit():
  {==}

law sin_cos_270_exact:
  {Bool.and(sc_has(I.sin_cos_deg(270.0f64), 0n, 0.0f64, 0.0000000000000000001f64), sc_has(I.sin_cos_deg(270.0f64), 1n, F64.neg(1.0f64), 0.0000000000000000001f64)) == True{} : Bool}

def sin_cos_270_exact():
  {==}

law rot_quarter_exact:
  {M.pl_exact(M.pl_rot(M.pl_id(), 2u64, I.sin_cos_deg(90.0f64))) == True{} : Bool}

def rot_quarter_exact():
  {==}

law rot_general_inexact:
  {M.pl_exact(M.pl_rot(M.pl_id(), 0u64, I.sin_cos_deg(30.0f64))) == False{} : Bool}

def rot_general_inexact():
  {==}

law unknown_op:
  {M.op_name(S.op_of(S.sx_nth(ps_xs(S.parse("(fillet 1 2)")), 0n), [])) == "unknown" : String}

def unknown_op():
  {==}

def forge(cs: List<&2, M.CE>) -> List<&2, M.CE>:
  match cs:
    case []: []
    case +c <> t: [M.CE{M.ce_id(c), M.ce_key(c), M.nr_err(T.F_invalid{}, "forged", "-", "forged", "-")}]

def unk_src() -> String:
  "(bendcad 1) (node 1 (frobnicate 1) (intent create any 0 1 0))"

law ev_dup_param:
  {r_s(M.ce_r(M.ce_find(ev("(bendcad 1) (param 1 W 1 1 1) (param 1 H 2 2 2) (node 1 (box W H 1) (intent create 6 0 1 0))"), 0u64))) == "err invalid-input duplicate-node-or-parameter-id" : String}

def ev_dup_param():
  {==}

law cache_hit_republishes:
  {r_s(M.ce_r(M.ce_find(M.ev_part(part(unk_src()), forge(ev(unk_src()))), 1u64))) == "err invalid-input forged" : String}

def cache_hit_republishes():
  {==}

law cache_miss_rebuilds:
  {r_s(M.ce_r(M.ce_find(M.ev_part(part(unk_src()), []), 1u64))) == "err invalid-input unknown-op" : String}

def cache_miss_rebuilds():
  {==}
