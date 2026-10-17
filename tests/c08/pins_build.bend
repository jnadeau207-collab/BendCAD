import Base

import ../../src/c00/types.bend as T

import ../../src/c01/types.bend as V

import ../../src/c03/types.bend as G

import ../../src/c04/types.bend as Ty

import ../../src/c06/xp.bend as X

import ../../src/c06/prof.bend as F

import ../../src/c06/iv.bend as I

import ../../src/c06/model.bend as M

import ../../src/c06/sx.bend as S

import ../../src/c06/zone.bend as Z

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

def last_body(+src: String) -> M.Body:
  M.nr_body(last_r(ev(src), M.bad("-", "-", "empty", "-")))

def vol_has(+src: String, +v: F64) -> Bool:
  +m = M.body_ms(last_body(src))
  +i = M.ms_vol(m)
  Bool.and(F64.is_le(I.i_lo(i), v), F64.is_le(v, I.i_hi(i)))

def base2() -> String:
  "(node 1 (box 10 10 10) (intent create 6 0 1 0)) (node 2 (box 10 10 10) (intent create 6 0 1 0)) (node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))"

def base1() -> String:
  "(node 1 (box 10 10 10) (intent create 6 0 1 0))"

def base_contain() -> String:
  "(node 1 (box 20 20 20) (intent create 6 0 1 0)) (node 2 (box 4 4 4) (intent create 6 0 1 0)) (node 3 (move 2 8 8 8 0) (intent same 0 0 1 0))"

def with_empty() -> String:
  base2() ++ " (node 4 (intersection 1 3) (intent same 0 0 0 0))"

def base_touch() -> String:
  "(node 1 (box 10 10 10) (intent create 6 0 1 0)) (node 2 (box 10 10 10) (intent create 6 0 1 0)) (node 3 (move 2 10 0 0 0) (intent same 0 0 1 0))"

def base_multi() -> String:
  "(node 1 (box 40 40 40) (intent create 6 0 1 0)) (node 2 (move 1 0 0 -20 0) (intent same 0 0 1 0)) (node 3 (prism 0 10 (region (path 1 1 (line 5 1) (line 5 5) (line 1 5))) (region (path 100 100 (line 105 100) (line 105 105) (line 100 105)))) (intent create 12 0 2 0))"

def nb_brep() -> Ty.Brep:
  Ty.Br{[], [], [], [], [Ty.Fa{1u64, G.GV_nb{G.Nb{[], [], []}}, [], True{}, 0.0f64, 0.0f64}],
    [Ty.Sh{1u64, [], Ty.SK_outer{}}], [Ty.So{1u64, Ty.HS{0n, 1u64}, []}], Ty.Cp{[Ty.HSo{0n, 1u64}], []}, 0u64}

def nb_body() -> M.Body:
  M.Bd{[], nb_brep(), [], M.pl_id(), [], M.xb_id()}

def open_brep() -> Ty.Brep:
  Ty.Br{[], [], [], [], [Ty.Fa{1u64, G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}}}, [], True{}, 0.0f64, 0.0f64}],
    [Ty.Sh{1u64, [], Ty.SK_open{}}], [Ty.So{1u64, Ty.HS{0n, 1u64}, []}], Ty.Cp{[Ty.HSo{0n, 1u64}], []}, 0u64}

def open_body() -> M.Body:
  M.Bd{[], open_brep(), [], M.pl_id(), [], M.xb_id()}

def base_pierce() -> String:
  "(node 1 (box 10 10 10) (intent create 6 0 1 0)) (node 2 (box 2 2 20) (intent create 6 0 1 0)) (node 3 (move 2 4 4 -5 0) (intent same 0 0 1 0))"

def base_cross() -> String:
  "(node 1 (box 10 10 10) (intent create 6 0 1 0)) (node 2 (box 10 10 10) (intent create 6 0 1 0)) (node 3 (move 2 5 0 0 0) (intent same 0 0 1 0))"

def base_straddle() -> String:
  "(node 1 (box 20 20 20) (intent create 6 0 1 0)) (node 2 (box 4 4 4) (intent create 6 0 1 0)) (node 3 (move 2 18 8 8 0) (intent same 0 0 1 0))"

def base_tangent() -> String:
  "(node 1 (box 10 10 10) (intent create 6 0 1 0)) (node 2 (sphere 5) (intent create 2 0 1 0)) (node 3 (move 2 5 5 15 0) (intent same 0 0 1 0))"

def base_kiss() -> String:
  "(node 1 (sphere 5) (intent create 2 0 1 0)) (node 2 (sphere 5) (intent create 2 0 1 0)) (node 3 (move 2 10 0 0 0) (intent same 0 0 1 0))"

def base_sphcav() -> String:
  "(node 1 (box 20 20 20) (intent create 6 0 1 0)) (node 2 (sphere 4) (intent create 2 0 1 0)) (node 3 (move 2 10 10 10 0) (intent same 0 0 1 0))"

def base_cylsph() -> String:
  "(node 1 (cylinder 2 10) (intent create 3 0 1 0)) (node 2 (sphere 3) (intent create 2 0 1 0)) (node 3 (move 2 50 0 0 0) (intent same 0 0 1 0))"

def base_rot45() -> String:
  "(node 1 (box 10 10 10) (intent create 6 0 1 0)) (node 2 (box 10 10 10) (intent create 6 0 1 0)) (node 3 (rotate 2 z 45) (intent same 0 0 1 0)) (node 4 (move 3 40 0 0 0) (intent same 0 0 1 0))"

def ev_union_disjoint__got() -> Bool:
  String.eq(last_s(base2() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))"), "ok material=add faces_created=0 faces_modified=0 solids=2 through_holes=0")

def ev_union_disjoint__want() -> Bool:
  True{}

def ev_diff_disjoint__got() -> Bool:
  String.eq(last_s(base2() ++ " (node 4 (difference 1 3) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_diff_disjoint__want() -> Bool:
  True{}

def ev_inter_disjoint__got() -> Bool:
  String.eq(last_s(base2() ++ " (node 4 (intersection 1 3) (intent same 0 0 0 0))"), "ok material=same faces_created=0 faces_modified=0 solids=0 through_holes=0")

def ev_inter_disjoint__want() -> Bool:
  True{}

def ev_union_identical__got() -> Bool:
  String.eq(last_s(base1() ++ " (node 2 (union 1 1) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_union_identical__want() -> Bool:
  True{}

def ev_diff_identical__got() -> Bool:
  String.eq(last_s(base1() ++ " (node 2 (difference 1 1) (intent same 0 0 0 0))"), "ok material=same faces_created=0 faces_modified=0 solids=0 through_holes=0")

def ev_diff_identical__want() -> Bool:
  True{}

def ev_inter_identical__got() -> Bool:
  String.eq(last_s(base1() ++ " (node 2 (intersection 1 1) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_inter_identical__want() -> Bool:
  True{}

def ev_union_contained__got() -> Bool:
  String.eq(last_s(base_contain() ++ " (node 4 (union 1 3) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_union_contained__want() -> Bool:
  True{}

def ev_inter_contained__got() -> Bool:
  String.eq(last_s(base_contain() ++ " (node 4 (intersection 1 3) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_inter_contained__want() -> Bool:
  True{}

def ev_union_empty_left__got() -> Bool:
  String.eq(last_s(with_empty() ++ " (node 5 (union 4 1) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_union_empty_left__want() -> Bool:
  True{}

def ev_diff_empty_left__got() -> Bool:
  String.eq(last_s(with_empty() ++ " (node 5 (difference 4 1) (intent same 0 0 0 0))"), "ok material=same faces_created=0 faces_modified=0 solids=0 through_holes=0")

def ev_diff_empty_left__want() -> Bool:
  True{}

def ev_feature_on_empty__got() -> Bool:
  String.eq(last_s(with_empty() ++ " (node 5 (pad 4 (face 4 0 top) 5 (region (circle 5 5 2))) (intent add 2 1 1 0))"), "err invalid-input feature-on-empty-compound")

def ev_feature_on_empty__want() -> Bool:
  True{}

def ev_feature_on_compound__got() -> Bool:
  String.eq(last_s(base2() ++ " (node 4 (union 1 3) (intent add 0 0 2 0)) (node 5 (pad 4 (face 4 0 top) 5 (region (circle 5 5 2))) (intent add 2 1 2 0))"), "err invalid-input feature-on-compound")

def ev_feature_on_compound__want() -> Bool:
  True{}

def ev_feature_pad_ok__got() -> Bool:
  String.eq(last_s(base_cross() ++ " (node 4 (union 1 3) (intent add 0 0 1 0)) (node 5 (pad 4 (face 4 0 top) 3 (region (circle 2 5 1))) (intent add 3 0 1 0))"), "ok material=add faces_created=3 faces_modified=0 solids=1 through_holes=0")

def ev_feature_pad_ok__want() -> Bool:
  True{}

def ev_vol_feature_pad__got() -> Bool:
  vol_has(base_cross() ++ " (node 4 (union 1 3) (intent add 0 0 1 0)) (node 5 (pad 4 (face 4 0 top) 3 (region (circle 2 5 1))) (intent add 3 0 1 0))", 1509.4247779607695f64)

def ev_vol_feature_pad__want() -> Bool:
  True{}

def ev_intent_mismatch__got() -> Bool:
  String.eq(last_s(base2() ++ " (node 4 (union 1 3) (intent create 6 0 1 0))"), "err invalid-input declared material=create faces_created=6 faces_modified=0 solids=1 through_holes=0 but measured material=add faces_created=0 faces_modified=0 solids=2 through_holes=0")

def ev_intent_mismatch__want() -> Bool:
  True{}

def ev_zone_bool__got() -> Z.ZR:
  Z.zone(part(base2() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))"), 4u64)

def ev_zone_bool__want() -> Z.ZR:
  Z.Z_err{"topology-not-certified-over-zone"}

def ev_vol_union__got() -> Bool:
  vol_has(base2() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))", 2000.0f64)

def ev_vol_union__want() -> Bool:
  True{}

def ev_vol_inter_empty__got() -> Bool:
  vol_has(base2() ++ " (node 4 (intersection 1 3) (intent same 0 0 0 0))", 0.0f64)

def ev_vol_inter_empty__want() -> Bool:
  True{}

def ev_diff_contained__got() -> Bool:
  String.eq(last_s(base_contain() ++ " (node 4 (difference 1 3) (intent remove 6 0 1 0))"), "ok material=remove faces_created=6 faces_modified=0 solids=1 through_holes=0")

def ev_diff_contained__want() -> Bool:
  True{}

def ev_vol_cavity__got() -> Bool:
  vol_has(base_contain() ++ " (node 4 (difference 1 3) (intent remove 6 0 1 0))", 7936.0f64)

def ev_vol_cavity__want() -> Bool:
  True{}

def ev_union_contact_face__got() -> Bool:
  String.eq(last_s(base_touch() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))"), "ok material=add faces_created=0 faces_modified=0 solids=2 through_holes=0")

def ev_union_contact_face__want() -> Bool:
  True{}

def ev_vol_contact__got() -> Bool:
  vol_has(base_touch() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))", 2000.0f64)

def ev_vol_contact__want() -> Bool:
  True{}

def ev_diff_ainb_empty__got() -> Bool:
  String.eq(last_s(base_contain() ++ " (node 4 (difference 3 1) (intent same 0 0 0 0))"), "ok material=same faces_created=0 faces_modified=0 solids=0 through_holes=0")

def ev_diff_ainb_empty__want() -> Bool:
  True{}

def ev_mixed_solids_refused__got() -> Bool:
  String.eq(last_s(base_multi() ++ " (node 4 (difference 2 3) (intent remove 0 0 1 0))"), "err unsupported-op mixed-solid-relations: one operand has solids both inside and outside the other")

def ev_mixed_solids_refused__want() -> Bool:
  True{}

def ev_nurbs_refused__got() -> String:
  r_s(M.bool_run(M.O_union{1u64, 2u64}, nb_body(), nb_body(), 3u64))

def ev_nurbs_refused__want() -> String:
  "err unsupported-op nurbs-operand: face outside the admitted domain"

def ev_open_shell_refused__got() -> String:
  r_s(M.bool_run(M.O_union{1u64, 2u64}, open_body(), open_body(), 3u64))

def ev_open_shell_refused__want() -> String:
  "err unsupported-op open-shell-operand: booleans are closed-solid operators"

def ev_move_preserves_origin__got() -> Bool:
  M.xb_bo(M.bd_xb(last_body(base2() ++ " (node 4 (union 1 3) (intent add 0 0 2 0)) (node 5 (move 4 100 0 0 0) (intent same 0 0 2 0))")))

def ev_move_preserves_origin__want() -> Bool:
  True{}

def ev_move_plain_stays_plain__got() -> Bool:
  M.xb_bo(M.bd_xb(last_body(base1() ++ " (node 2 (move 1 5 0 0 0) (intent same 0 0 1 0))")))

def ev_move_plain_stays_plain__want() -> Bool:
  False{}

def ev_pierce_rod__got() -> Bool:
  String.eq(last_s(base_pierce() ++ " (node 4 (union 1 3) (intent add 0 0 1 0))"), "ok material=add faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_pierce_rod__want() -> Bool:
  True{}

def ev_vol_pierce_rod__got() -> Bool:
  vol_has(base_pierce() ++ " (node 4 (union 1 3) (intent add 0 0 1 0))", 1040.0f64)

def ev_vol_pierce_rod__want() -> Bool:
  True{}

def ev_pierce_rod_diff__got() -> Bool:
  String.eq(last_s(base_pierce() ++ " (node 4 (difference 1 3) (intent remove 0 0 1 0))"), "ok material=remove faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_pierce_rod_diff__want() -> Bool:
  True{}

def ev_vol_pierce_rod_diff__got() -> Bool:
  vol_has(base_pierce() ++ " (node 4 (difference 1 3) (intent remove 0 0 1 0))", 960.0f64)

def ev_vol_pierce_rod_diff__want() -> Bool:
  True{}

def ev_pierce_rod_inter__got() -> Bool:
  String.eq(last_s(base_pierce() ++ " (node 4 (intersection 1 3) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_pierce_rod_inter__want() -> Bool:
  True{}

def ev_vol_pierce_rod_inter__got() -> Bool:
  vol_has(base_pierce() ++ " (node 4 (intersection 1 3) (intent same 0 0 1 0))", 40.0f64)

def ev_vol_pierce_rod_inter__want() -> Bool:
  True{}

def ev_cross_union__got() -> Bool:
  String.eq(last_s(base_cross() ++ " (node 4 (union 1 3) (intent add 0 0 1 0))"), "ok material=add faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_cross_union__want() -> Bool:
  True{}

def ev_vol_cross_union__got() -> Bool:
  vol_has(base_cross() ++ " (node 4 (union 1 3) (intent add 0 0 1 0))", 1500.0f64)

def ev_vol_cross_union__want() -> Bool:
  True{}

def ev_cross_diff__got() -> Bool:
  String.eq(last_s(base_cross() ++ " (node 4 (difference 1 3) (intent remove 0 0 1 0))"), "ok material=remove faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_cross_diff__want() -> Bool:
  True{}

def ev_vol_cross_diff__got() -> Bool:
  vol_has(base_cross() ++ " (node 4 (difference 1 3) (intent remove 0 0 1 0))", 500.0f64)

def ev_vol_cross_diff__want() -> Bool:
  True{}

def ev_cross_inter__got() -> Bool:
  String.eq(last_s(base_cross() ++ " (node 4 (intersection 1 3) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_cross_inter__want() -> Bool:
  True{}

def ev_vol_cross_inter__got() -> Bool:
  vol_has(base_cross() ++ " (node 4 (intersection 1 3) (intent same 0 0 1 0))", 500.0f64)

def ev_vol_cross_inter__want() -> Bool:
  True{}

def ev_straddle__got() -> Bool:
  String.eq(last_s(base_straddle() ++ " (node 4 (difference 1 3) (intent remove 0 0 1 0))"), "ok material=remove faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_straddle__want() -> Bool:
  True{}

def ev_vol_straddle__got() -> Bool:
  vol_has(base_straddle() ++ " (node 4 (difference 1 3) (intent remove 0 0 1 0))", 7968.0f64)

def ev_vol_straddle__want() -> Bool:
  True{}

def ev_tangent_sphere_plane__got() -> Bool:
  String.eq(last_s(base_tangent() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))"), "ok material=add faces_created=0 faces_modified=0 solids=2 through_holes=0")

def ev_tangent_sphere_plane__want() -> Bool:
  True{}

def ev_vol_tangent__got() -> Bool:
  vol_has(base_tangent() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))", 1523.5987755982987f64)

def ev_vol_tangent__want() -> Bool:
  True{}

def ev_tangent_inter_empty__got() -> Bool:
  String.eq(last_s(base_tangent() ++ " (node 4 (intersection 1 3) (intent same 0 0 0 0))"), "ok material=same faces_created=0 faces_modified=0 solids=0 through_holes=0")

def ev_tangent_inter_empty__want() -> Bool:
  True{}

def ev_kissing_spheres__got() -> Bool:
  String.eq(last_s(base_kiss() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))"), "ok material=add faces_created=0 faces_modified=0 solids=2 through_holes=0")

def ev_kissing_spheres__want() -> Bool:
  True{}

def ev_vol_kissing__got() -> Bool:
  vol_has(base_kiss() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))", 1047.1975511965977f64)

def ev_vol_kissing__want() -> Bool:
  True{}

def ev_sphere_cavity__got() -> Bool:
  String.eq(last_s(base_sphcav() ++ " (node 4 (difference 1 3) (intent remove 2 0 1 0))"), "ok material=remove faces_created=2 faces_modified=0 solids=1 through_holes=0")

def ev_sphere_cavity__want() -> Bool:
  True{}

def ev_vol_sphere_cavity__got() -> Bool:
  vol_has(base_sphcav() ++ " (node 4 (difference 1 3) (intent remove 2 0 1 0))", 7731.917426893671f64)

def ev_vol_sphere_cavity__want() -> Bool:
  True{}

def ev_sphere_inter__got() -> Bool:
  String.eq(last_s(base_sphcav() ++ " (node 4 (intersection 1 3) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0")

def ev_sphere_inter__want() -> Bool:
  True{}

def ev_vol_sphere_inter__got() -> Bool:
  vol_has(base_sphcav() ++ " (node 4 (intersection 1 3) (intent same 0 0 1 0))", 268.082573106329f64)

def ev_vol_sphere_inter__want() -> Bool:
  True{}

def ev_disjoint_cyl_sphere__got() -> Bool:
  String.eq(last_s(base_cylsph() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))"), "ok material=add faces_created=0 faces_modified=0 solids=2 through_holes=0")

def ev_disjoint_cyl_sphere__want() -> Bool:
  True{}

def ev_vol_cyl_sphere__got() -> Bool:
  vol_has(base_cylsph() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))", 238.76104167282426f64)

def ev_vol_cyl_sphere__want() -> Bool:
  True{}

def ev_rot45_refused__got() -> Bool:
  String.eq(last_s(base_rot45() ++ " (node 5 (union 1 4) (intent add 0 0 2 0))"), "err unsupported-op interval-placement: operand placement is not certified exact")

def ev_rot45_refused__want() -> Bool:
  True{}
