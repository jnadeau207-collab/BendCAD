# C08 build laws — one law per full boolean evaluation (parse →
# boolean → C04 + C07 validation → measures → lineage), C06/C07
# `_build` precedent. Each law runs one design; check one-per-process
# in parallel. Full-evaluation outcomes for contact, cavity and
# crossing cases live in tests/c08/e2e.py, which asserts them at
# runtime (entity indices in crossing diagnoses are geometry-derived).
import Base
import ../src/c00/types.bend as T
import ../src/c01/types.bend as V
import ../src/c03/types.bend as G
import ../src/c04/types.bend as Ty
import ../src/c06/xp.bend as X
import ../src/c06/prof.bend as F
import ../src/c06/iv.bend as I
import ../src/c06/model.bend as M
import ../src/c06/sx.bend as S
import ../src/c06/zone.bend as Z

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

law ev_union_disjoint:
  {String.eq(last_s(base2() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))"), "ok material=add faces_created=0 faces_modified=0 solids=2 through_holes=0") == True{} : Bool}

def ev_union_disjoint():
  {==}

law ev_diff_disjoint:
  {String.eq(last_s(base2() ++ " (node 4 (difference 1 3) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0") == True{} : Bool}

def ev_diff_disjoint():
  {==}

law ev_inter_disjoint:
  {String.eq(last_s(base2() ++ " (node 4 (intersection 1 3) (intent same 0 0 0 0))"), "ok material=same faces_created=0 faces_modified=0 solids=0 through_holes=0") == True{} : Bool}

def ev_inter_disjoint():
  {==}

law ev_union_identical:
  {String.eq(last_s(base1() ++ " (node 2 (union 1 1) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0") == True{} : Bool}

def ev_union_identical():
  {==}

law ev_diff_identical:
  {String.eq(last_s(base1() ++ " (node 2 (difference 1 1) (intent same 0 0 0 0))"), "ok material=same faces_created=0 faces_modified=0 solids=0 through_holes=0") == True{} : Bool}

def ev_diff_identical():
  {==}

law ev_inter_identical:
  {String.eq(last_s(base1() ++ " (node 2 (intersection 1 1) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0") == True{} : Bool}

def ev_inter_identical():
  {==}

law ev_union_contained:
  {String.eq(last_s(base_contain() ++ " (node 4 (union 1 3) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0") == True{} : Bool}

def ev_union_contained():
  {==}

law ev_inter_contained:
  {String.eq(last_s(base_contain() ++ " (node 4 (intersection 1 3) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0") == True{} : Bool}

def ev_inter_contained():
  {==}

law ev_union_empty_left:
  {String.eq(last_s(with_empty() ++ " (node 5 (union 4 1) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0") == True{} : Bool}

def ev_union_empty_left():
  {==}

law ev_diff_empty_left:
  {String.eq(last_s(with_empty() ++ " (node 5 (difference 4 1) (intent same 0 0 0 0))"), "ok material=same faces_created=0 faces_modified=0 solids=0 through_holes=0") == True{} : Bool}

def ev_diff_empty_left():
  {==}

law ev_feature_on_empty:
  {String.eq(last_s(with_empty() ++ " (node 5 (pad 4 (face 4 0 top) 5 (region (circle 5 5 2))) (intent add 2 1 1 0))"), "err invalid-input feature-on-empty-compound") == True{} : Bool}

def ev_feature_on_empty():
  {==}

law ev_feature_on_boolean:
  {String.eq(last_s(base2() ++ " (node 4 (union 1 3) (intent add 0 0 2 0)) (node 5 (pad 4 (face 4 0 top) 5 (region (circle 5 5 2))) (intent add 2 1 2 0))"), "err invalid-input feature-on-boolean-result") == True{} : Bool}

def ev_feature_on_boolean():
  {==}

law ev_intent_mismatch:
  {String.eq(last_s(base2() ++ " (node 4 (union 1 3) (intent create 6 0 1 0))"), "err invalid-input declared material=create faces_created=6 faces_modified=0 solids=1 through_holes=0 but measured material=add faces_created=0 faces_modified=0 solids=2 through_holes=0") == True{} : Bool}

def ev_intent_mismatch():
  {==}

law ev_zone_bool:
  {Z.zone(part(base2() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))"), 4u64) == Z.Z_err{"topology-not-certified-over-zone"} : Z.ZR}

def ev_zone_bool():
  {==}

law ev_vol_union:
  {vol_has(base2() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))", 2000.0f64) == True{} : Bool}

def ev_vol_union():
  {==}

law ev_vol_inter_empty:
  {vol_has(base2() ++ " (node 4 (intersection 1 3) (intent same 0 0 0 0))", 0.0f64) == True{} : Bool}

def ev_vol_inter_empty():
  {==}

# --- F16: cavity, contact, refusal and admit coverage ---
def base_touch() -> String:
  "(node 1 (box 10 10 10) (intent create 6 0 1 0)) (node 2 (box 10 10 10) (intent create 6 0 1 0)) (node 3 (move 2 10 0 0 0) (intent same 0 0 1 0))"

law ev_diff_contained:
  {String.eq(last_s(base_contain() ++ " (node 4 (difference 1 3) (intent remove 6 0 1 0))"), "ok material=remove faces_created=6 faces_modified=0 solids=1 through_holes=0") == True{} : Bool}

def ev_diff_contained():
  {==}

law ev_vol_cavity:
  {vol_has(base_contain() ++ " (node 4 (difference 1 3) (intent remove 6 0 1 0))", 7936.0f64) == True{} : Bool}

def ev_vol_cavity():
  {==}

law ev_union_contact_face:
  {String.eq(last_s(base_touch() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))"), "ok material=add faces_created=0 faces_modified=0 solids=2 through_holes=0") == True{} : Bool}

def ev_union_contact_face():
  {==}

law ev_vol_contact:
  {vol_has(base_touch() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))", 2000.0f64) == True{} : Bool}

def ev_vol_contact():
  {==}

law ev_diff_ainb_empty:
  {String.eq(last_s(base_contain() ++ " (node 4 (difference 3 1) (intent same 0 0 0 0))"), "ok material=same faces_created=0 faces_modified=0 solids=0 through_holes=0") == True{} : Bool}

def ev_diff_ainb_empty():
  {==}

def base_multi() -> String:
  "(node 1 (box 40 40 40) (intent create 6 0 1 0)) (node 2 (move 1 0 0 -20 0) (intent same 0 0 1 0)) (node 3 (prism 0 10 (region (path 1 1 (line 5 1) (line 5 5) (line 1 5))) (region (path 100 100 (line 105 100) (line 105 105) (line 100 105)))) (intent create 12 0 2 0))"

law ev_mixed_solids_refused:
  {String.eq(last_s(base_multi() ++ " (node 4 (difference 2 3) (intent remove 0 0 1 0))"), "err unsupported-op mixed-solid-relations: one operand has solids both inside and outside the other") == True{} : Bool}

def ev_mixed_solids_refused():
  {==}

def nb_brep() -> Ty.Brep:
  Ty.Br{[], [], [], [], [Ty.Fa{1u64, G.GV_nb{G.Nb{[], [], []}}, [], True{}}],
    [Ty.Sh{1u64, [], Ty.SK_outer{}}], [Ty.So{1u64, Ty.HS{0n, 1u64}, []}], Ty.Cp{[Ty.HSo{0n, 1u64}], []}, 0u64}

def nb_body() -> M.Body:
  M.Bd{[], nb_brep(), [], M.pl_id(), [], M.xb_id()}

law ev_nurbs_refused:
  {r_s(M.bool_run(M.O_union{1u64, 2u64}, nb_body(), nb_body(), 3u64)) == "err unsupported-op nurbs-operand: face outside the admitted domain" : String}

def ev_nurbs_refused():
  {==}

def open_brep() -> Ty.Brep:
  Ty.Br{[], [], [], [], [Ty.Fa{1u64, G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}}}, [], True{}}],
    [Ty.Sh{1u64, [], Ty.SK_open{}}], [Ty.So{1u64, Ty.HS{0n, 1u64}, []}], Ty.Cp{[Ty.HSo{0n, 1u64}], []}, 0u64}

def open_body() -> M.Body:
  M.Bd{[], open_brep(), [], M.pl_id(), [], M.xb_id()}

law ev_open_shell_refused:
  {r_s(M.bool_run(M.O_union{1u64, 2u64}, open_body(), open_body(), 3u64)) == "err unsupported-op open-shell-operand: booleans are closed-solid operators" : String}

def ev_open_shell_refused():
  {==}

law ev_move_preserves_origin:
  {M.xb_bo(M.bd_xb(last_body(base2() ++ " (node 4 (union 1 3) (intent add 0 0 2 0)) (node 5 (move 4 100 0 0 0) (intent same 0 0 2 0))"))) == True{} : Bool}

def ev_move_preserves_origin():
  {==}

law ev_move_plain_stays_plain:
  {M.xb_bo(M.bd_xb(last_body(base1() ++ " (node 2 (move 1 5 0 0 0) (intent same 0 0 1 0))"))) == False{} : Bool}

def ev_move_plain_stays_plain():
  {==}

# --- F5/F18: piercing refusal, tangent publishing, curved oracles ---
def base_pierce() -> String:
  "(node 1 (box 10 10 10) (intent create 6 0 1 0)) (node 2 (box 2 2 20) (intent create 6 0 1 0)) (node 3 (move 2 4 4 -5 0) (intent same 0 0 1 0))"

law ev_pierce_rod_refused:
  {String.eq(last_s(base_pierce() ++ " (node 4 (union 1 3) (intent add 0 0 1 0))"), "err unsupported-op boundaries-cross-or-overlap: edge-face-penetration 20 0 between nodes 1 and 3") == True{} : Bool}

def ev_pierce_rod_refused():
  {==}

law ev_pierce_rod_diff_refused:
  {String.eq(last_s(base_pierce() ++ " (node 4 (difference 1 3) (intent remove 0 0 1 0))"), "err unsupported-op boundaries-cross-or-overlap: edge-face-penetration 20 0 between nodes 1 and 3") == True{} : Bool}

def ev_pierce_rod_diff_refused():
  {==}

def base_tangent() -> String:
  "(node 1 (box 10 10 10) (intent create 6 0 1 0)) (node 2 (sphere 5) (intent create 2 0 1 0)) (node 3 (move 2 5 5 15 0) (intent same 0 0 1 0))"

law ev_tangent_sphere_plane:
  {String.eq(last_s(base_tangent() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))"), "ok material=add faces_created=0 faces_modified=0 solids=2 through_holes=0") == True{} : Bool}

def ev_tangent_sphere_plane():
  {==}

law ev_vol_tangent:
  {vol_has(base_tangent() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))", 1523.5987755982987f64) == True{} : Bool}

def ev_vol_tangent():
  {==}

law ev_tangent_inter_empty:
  {String.eq(last_s(base_tangent() ++ " (node 4 (intersection 1 3) (intent same 0 0 0 0))"), "ok material=same faces_created=0 faces_modified=0 solids=0 through_holes=0") == True{} : Bool}

def ev_tangent_inter_empty():
  {==}

def base_kiss() -> String:
  "(node 1 (sphere 5) (intent create 2 0 1 0)) (node 2 (sphere 5) (intent create 2 0 1 0)) (node 3 (move 2 10 0 0 0) (intent same 0 0 1 0))"

law ev_kissing_spheres:
  {String.eq(last_s(base_kiss() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))"), "ok material=add faces_created=0 faces_modified=0 solids=2 through_holes=0") == True{} : Bool}

def ev_kissing_spheres():
  {==}

law ev_vol_kissing:
  {vol_has(base_kiss() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))", 1047.1975511965977f64) == True{} : Bool}

def ev_vol_kissing():
  {==}

def base_sphcav() -> String:
  "(node 1 (box 20 20 20) (intent create 6 0 1 0)) (node 2 (sphere 4) (intent create 2 0 1 0)) (node 3 (move 2 10 10 10 0) (intent same 0 0 1 0))"

law ev_sphere_cavity:
  {String.eq(last_s(base_sphcav() ++ " (node 4 (difference 1 3) (intent remove 2 0 1 0))"), "ok material=remove faces_created=2 faces_modified=0 solids=1 through_holes=0") == True{} : Bool}

def ev_sphere_cavity():
  {==}

law ev_vol_sphere_cavity:
  {vol_has(base_sphcav() ++ " (node 4 (difference 1 3) (intent remove 2 0 1 0))", 7731.917426893671f64) == True{} : Bool}

def ev_vol_sphere_cavity():
  {==}

law ev_sphere_inter:
  {String.eq(last_s(base_sphcav() ++ " (node 4 (intersection 1 3) (intent same 0 0 1 0))"), "ok material=same faces_created=0 faces_modified=0 solids=1 through_holes=0") == True{} : Bool}

def ev_sphere_inter():
  {==}

law ev_vol_sphere_inter:
  {vol_has(base_sphcav() ++ " (node 4 (intersection 1 3) (intent same 0 0 1 0))", 268.082573106329f64) == True{} : Bool}

def ev_vol_sphere_inter():
  {==}

def base_cylsph() -> String:
  "(node 1 (cylinder 2 10) (intent create 3 0 1 0)) (node 2 (sphere 3) (intent create 2 0 1 0)) (node 3 (move 2 50 0 0 0) (intent same 0 0 1 0))"

law ev_disjoint_cyl_sphere:
  {String.eq(last_s(base_cylsph() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))"), "ok material=add faces_created=0 faces_modified=0 solids=2 through_holes=0") == True{} : Bool}

def ev_disjoint_cyl_sphere():
  {==}

law ev_vol_cyl_sphere:
  {vol_has(base_cylsph() ++ " (node 4 (union 1 3) (intent add 0 0 2 0))", 238.76104167282426f64) == True{} : Bool}

def ev_vol_cyl_sphere():
  {==}

def base_rot45() -> String:
  "(node 1 (box 10 10 10) (intent create 6 0 1 0)) (node 2 (box 10 10 10) (intent create 6 0 1 0)) (node 3 (rotate 2 z 45) (intent same 0 0 1 0)) (node 4 (move 3 40 0 0 0) (intent same 0 0 1 0))"

law ev_rot45_refused:
  {String.eq(last_s(base_rot45() ++ " (node 5 (union 1 4) (intent add 0 0 2 0))"), "err unsupported-op interval-placement: operand placement is not certified exact") == True{} : Bool}

def ev_rot45_refused():
  {==}
