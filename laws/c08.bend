# C08 laws — Layer A semantic laws (regularized selection tables,
# tie-breaks, intent comparison, empty/compound semantics, lineage
# well-formedness) on micro-stores, plus fast Layer B verdict laws over
# the packet's pure functions. Full-evaluation laws live in
# laws/c08_build.bend. Binding: docs/c08-laws.md (L1-L20).
import Base
import ../src/c00/types.bend as T
import ../src/c01/types.bend as V
import ../src/c03/types.bend as G
import ../src/c04/types.bend as Ty
import ../src/c06/iv.bend as I
import ../src/c06/build.bend as BD
import ../src/c06/model.bend as M
import ../src/c06/sx.bend as S
import ../src/c07/xs.bend as XS
import ../src/c07/sol.bend as SO
import ../src/c07/emb.bend as EM
import ../src/c08/bool.bend as B8
import ../src/base/ex.bend as E
import ../src/base/par.bend as P

def pt0() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def ptx() -> V.Point:
  V.Pt{1.0f64, 0.0f64, 0.0f64}

def pty() -> V.Point:
  V.Pt{0.0f64, 1.0f64, 0.0f64}

def dx() -> V.Dir:
  V.Dr{1.0f64, 0.0f64, 0.0f64}

def dy() -> V.Dir:
  V.Dr{0.0f64, 1.0f64, 0.0f64}

def dom01() -> G.Dom:
  G.Dom{0.0f64, 1.0f64}

def m3id() -> V.Mat3:
  V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64}

def mval() -> M.Ms:
  M.Ms{I.I{1.0f64, 2.0f64}, I.I{3.0f64, 4.0f64}, 5.0f64, 6.0f64, 7.0f64, 8.0f64, 9.0f64, 10.0f64,
    11n, 12n, 13n, 14n, 15n, 16.0f64}

def bd0() -> M.Body:
  M.Bd{[], Ty.brep_empty(), [], M.pl_id(), [], M.xb_id()}

def in0() -> B8.In:
  B8.In{Ty.brep_empty(), [], [], m3id(), 0.0f64, 0.0f64, 0.0f64, [], I.I{1.0f64, 1.0f64},
    I.I{2.0f64, 2.0f64}, B8.bx_zero(), 0.5f64, False{}, True{}}

def fq(+x: F64, +y: F64, +z: F64) -> V.Point:
  V.Pt{x, y, z}

# Exactly-flat bicubic patch: bilinear z=0 grid (D2 admits it).
def flat_bp() -> G.BezP:
  G.Bp{fq(0.0f64, 0.0f64, 0.0f64), fq(1.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(3.0f64, 0.0f64, 0.0f64),
    fq(0.0f64, 1.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64), fq(2.0f64, 1.0f64, 0.0f64), fq(3.0f64, 1.0f64, 0.0f64),
    fq(0.0f64, 2.0f64, 0.0f64), fq(1.0f64, 2.0f64, 0.0f64), fq(2.0f64, 2.0f64, 0.0f64), fq(3.0f64, 2.0f64, 0.0f64),
    fq(0.0f64, 3.0f64, 0.0f64), fq(1.0f64, 3.0f64, 0.0f64), fq(2.0f64, 3.0f64, 0.0f64), fq(3.0f64, 3.0f64, 0.0f64)}

# Genuinely curved bicubic patch: one lifted corner (D2 still refuses it).
def curved_bp() -> G.BezP:
  G.Bp{fq(0.0f64, 0.0f64, 0.0f64), fq(1.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(3.0f64, 0.0f64, 0.0f64),
    fq(0.0f64, 1.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64), fq(2.0f64, 1.0f64, 0.0f64), fq(3.0f64, 1.0f64, 0.0f64),
    fq(0.0f64, 2.0f64, 0.0f64), fq(1.0f64, 2.0f64, 0.0f64), fq(2.0f64, 2.0f64, 0.0f64), fq(3.0f64, 2.0f64, 0.0f64),
    fq(0.0f64, 3.0f64, 0.0f64), fq(1.0f64, 3.0f64, 0.0f64), fq(2.0f64, 3.0f64, 0.0f64), fq(3.0f64, 3.0f64, 1.0f64)}

def ps_xs(r: S.PS) -> List<&2, S.Sx>:
  S.PS{ok, xs} = r
  xs

def only_op(ns: List<&2, M.Node>) -> M.Op:
  match ns:
    case []: M.O_unk{"empty"}
    case n <> t:
      M.Nd{id, op, it} = n
      op

def src_op_go(p: M.Part) -> M.Op:
  M.Pt{ps, ns} = p
  only_op(ns)

def src_op(+src: String) -> M.Op:
  src_op_go(S.part_of(ps_xs(S.parse(src))))

# --- Tags and codes (Layer A vocabulary) ---
law tag_union_is_14:
  {B8.tag_union() == 14u64 : U64}

def tag_union_is_14():
  {==}

law tag_diff_is_15:
  {B8.tag_diff() == 15u64 : U64}

def tag_diff_is_15():
  {==}

law tag_inter_is_16:
  {B8.tag_inter() == 16u64 : U64}

def tag_inter_is_16():
  {==}

law fc_codes:
  {B8.fc_out() == 0u64 : U64}

def fc_codes():
  {==}

law fc_in_is_1:
  {B8.fc_in() == 1u64 : U64}

def fc_in_is_1():
  {==}

law fc_same_is_2:
  {B8.fc_same() == 2u64 : U64}

def fc_same_is_2():
  {==}

law fc_opp_is_3:
  {B8.fc_opp() == 3u64 : U64}

def fc_opp_is_3():
  {==}

law fc_unc_is_4:
  {B8.fc_unc() == 4u64 : U64}

def fc_unc_is_4():
  {==}

law agg_in_is_1:
  {B8.agg_in() == 1u64 : U64}

def agg_in_is_1():
  {==}

law agg_out_is_2:
  {B8.agg_out() == 2u64 : U64}

def agg_out_is_2():
  {==}

law dec_sep_is_0:
  {B8.dec_sep() == 0u64 : U64}

def dec_sep_is_0():
  {==}

law dec_ainb_is_1:
  {B8.dec_ainb() == 1u64 : U64}

def dec_ainb_is_1():
  {==}

law dec_bina_is_2:
  {B8.dec_bina() == 2u64 : U64}

def dec_bina_is_2():
  {==}

law fk_invalid_is_0:
  {B8.fk_invalid() == 0u64 : U64}

def fk_invalid_is_0():
  {==}

law fk_uncertain_is_1:
  {B8.fk_uncertain() == 1u64 : U64}

def fk_uncertain_is_1():
  {==}

law fk_unsupported_is_2:
  {B8.fk_unsupported() == 2u64 : U64}

def fk_unsupported_is_2():
  {==}

law role_created_is_4:
  {B8.role_created() == 4u64 : U64}

def role_created_is_4():
  {==}

law op_name_union:
  {B8.op_name(14u64) == "union" : String}

def op_name_union():
  {==}

law op_name_diff:
  {B8.op_name(15u64) == "difference" : String}

def op_name_diff():
  {==}

law op_name_inter:
  {B8.op_name(16u64) == "intersection" : String}

def op_name_inter():
  {==}

law op_name_other_is_inter:
  {B8.op_name(99u64) == "intersection" : String}

def op_name_other_is_inter():
  {==}

law is_bool_op_union:
  {B8.is_bool_op(14u64) == True{} : Bool}

def is_bool_op_union():
  {==}

law is_bool_op_diff:
  {B8.is_bool_op(15u64) == True{} : Bool}

def is_bool_op_diff():
  {==}

law is_bool_op_inter:
  {B8.is_bool_op(16u64) == True{} : Bool}

def is_bool_op_inter():
  {==}

law is_bool_op_other:
  {B8.is_bool_op(13u64) == False{} : Bool}

def is_bool_op_other():
  {==}

law op_carry_nm_a:
  {B8.op_carry_nm(1u64) == "carry-A" : String}

def op_carry_nm_a():
  {==}

law op_carry_nm_b:
  {B8.op_carry_nm(2u64) == "carry-B" : String}

def op_carry_nm_b():
  {==}

law op_carry_nm_other_is_b:
  {B8.op_carry_nm(7u64) == "carry-B" : String}

def op_carry_nm_other_is_b():
  {==}

# --- Regularized selection tables (L1, L8): 0 drop, 1 keep, 2 fail ---
law keep_union_out:
  {B8.keep_frag(14u64, 0u64) == 1u64 : U64}

def keep_union_out():
  {==}

law keep_union_in:
  {B8.keep_frag(14u64, 1u64) == 0u64 : U64}

def keep_union_in():
  {==}

law keep_union_same:
  {B8.keep_frag(14u64, 2u64) == 1u64 : U64}

def keep_union_same():
  {==}

law keep_union_opp:
  {B8.keep_frag(14u64, 3u64) == 0u64 : U64}

def keep_union_opp():
  {==}

law keep_union_unc:
  {B8.keep_frag(14u64, 4u64) == 2u64 : U64}

def keep_union_unc():
  {==}

law keep_diff_out:
  {B8.keep_frag(15u64, 0u64) == 1u64 : U64}

def keep_diff_out():
  {==}

law keep_diff_in:
  {B8.keep_frag(15u64, 1u64) == 0u64 : U64}

def keep_diff_in():
  {==}

law keep_diff_same:
  {B8.keep_frag(15u64, 2u64) == 0u64 : U64}

def keep_diff_same():
  {==}

law keep_diff_opp:
  {B8.keep_frag(15u64, 3u64) == 1u64 : U64}

def keep_diff_opp():
  {==}

law keep_diff_unc:
  {B8.keep_frag(15u64, 4u64) == 2u64 : U64}

def keep_diff_unc():
  {==}

law keep_inter_out:
  {B8.keep_frag(16u64, 0u64) == 0u64 : U64}

def keep_inter_out():
  {==}

law keep_inter_in:
  {B8.keep_frag(16u64, 1u64) == 1u64 : U64}

def keep_inter_in():
  {==}

law keep_inter_same:
  {B8.keep_frag(16u64, 2u64) == 1u64 : U64}

def keep_inter_same():
  {==}

law keep_inter_opp:
  {B8.keep_frag(16u64, 3u64) == 0u64 : U64}

def keep_inter_opp():
  {==}

law keep_inter_unc:
  {B8.keep_frag(16u64, 4u64) == 2u64 : U64}

def keep_inter_unc():
  {==}

law keep_other_op_is_inter:
  {B8.keep_frag(99u64, 1u64) == 1u64 : U64}

def keep_other_op_is_inter():
  {==}

# --- Aggregates and pair decisions ---
law agg_of_mixed:
  {B8.agg_of(True{}, True{}, False{}) == 3u64 : U64}

def agg_of_mixed():
  {==}

law agg_of_in:
  {B8.agg_of(True{}, False{}, True{}) == 1u64 : U64}

def agg_of_in():
  {==}

law agg_of_out:
  {B8.agg_of(False{}, True{}, True{}) == 2u64 : U64}

def agg_of_out():
  {==}

law agg_of_boundary:
  {B8.agg_of(False{}, False{}, True{}) == 0u64 : U64}

def agg_of_boundary():
  {==}

law agg_of_unsampled:
  {B8.agg_of(False{}, False{}, False{}) == 0u64 : U64}

def agg_of_unsampled():
  {==}

law agg_ok_in:
  {B8.agg_ok(1u64) == True{} : Bool}

def agg_ok_in():
  {==}

law agg_ok_out:
  {B8.agg_ok(2u64) == True{} : Bool}

def agg_ok_out():
  {==}

law agg_ok_boundary:
  {B8.agg_ok(0u64) == False{} : Bool}

def agg_ok_boundary():
  {==}

law agg_ok_mixed:
  {B8.agg_ok(3u64) == False{} : Bool}

def agg_ok_mixed():
  {==}

law agg_code_in:
  {B8.agg_code(1u64) == 1u64 : U64}

def agg_code_in():
  {==}

law agg_code_out:
  {B8.agg_code(2u64) == 0u64 : U64}

def agg_code_out():
  {==}

law agg_code_other_is_out:
  {B8.agg_code(0u64) == 0u64 : U64}

def agg_code_other_is_out():
  {==}

law dec_aggA_ainb:
  {B8.dec_aggA(1u64) == 1u64 : U64}

def dec_aggA_ainb():
  {==}

law dec_aggA_other_is_out:
  {B8.dec_aggA(2u64) == 2u64 : U64}

def dec_aggA_other_is_out():
  {==}

law dec_aggB_bina:
  {B8.dec_aggB(2u64) == 1u64 : U64}

def dec_aggB_bina():
  {==}

law dec_aggB_other_is_out:
  {B8.dec_aggB(1u64) == 2u64 : U64}

def dec_aggB_other_is_out():
  {==}

law decide_sep:
  {B8.decide(2u64, 2u64) == 0u64 : U64}

def decide_sep():
  {==}

law decide_ainb:
  {B8.decide(1u64, 2u64) == 1u64 : U64}

def decide_ainb():
  {==}

law decide_bina:
  {B8.decide(2u64, 1u64) == 2u64 : U64}

def decide_bina():
  {==}

law decide_both_in_fails:
  {B8.decide(1u64, 1u64) == 3u64 : U64}

def decide_both_in_fails():
  {==}

law decide_boundary_fails:
  {B8.decide(2u64, 0u64) == 3u64 : U64}

def decide_boundary_fails():
  {==}

# --- Outcome table: 0 carry-A, 1 carry-B, 2 append, 3 empty, 4 cavity, 5 fail ---
law outcome_union_sep:
  {B8.outcome(14u64, 0u64) == 2u64 : U64}

def outcome_union_sep():
  {==}

law outcome_union_ainb:
  {B8.outcome(14u64, 1u64) == 1u64 : U64}

def outcome_union_ainb():
  {==}

law outcome_union_bina:
  {B8.outcome(14u64, 2u64) == 0u64 : U64}

def outcome_union_bina():
  {==}

law outcome_union_bad:
  {B8.outcome(14u64, 3u64) == 5u64 : U64}

def outcome_union_bad():
  {==}

law outcome_diff_sep:
  {B8.outcome(15u64, 0u64) == 0u64 : U64}

def outcome_diff_sep():
  {==}

law outcome_diff_ainb:
  {B8.outcome(15u64, 1u64) == 3u64 : U64}

def outcome_diff_ainb():
  {==}

law outcome_diff_bina:
  {B8.outcome(15u64, 2u64) == 4u64 : U64}

def outcome_diff_bina():
  {==}

law outcome_diff_bad:
  {B8.outcome(15u64, 3u64) == 5u64 : U64}

def outcome_diff_bad():
  {==}

law outcome_inter_sep:
  {B8.outcome(16u64, 0u64) == 3u64 : U64}

def outcome_inter_sep():
  {==}

law outcome_inter_ainb:
  {B8.outcome(16u64, 1u64) == 0u64 : U64}

def outcome_inter_ainb():
  {==}

law outcome_inter_bina:
  {B8.outcome(16u64, 2u64) == 1u64 : U64}

def outcome_inter_bina():
  {==}

law outcome_inter_bad:
  {B8.outcome(16u64, 3u64) == 5u64 : U64}

def outcome_inter_bad():
  {==}

# --- Empty-compound algebra + identical operands (L7): 10 continues ---
law empty_union_both_empty:
  {B8.empty_outcome(14u64, True{}, True{}, False{}) == 3u64 : U64}

def empty_union_both_empty():
  {==}

law empty_union_a_empty:
  {B8.empty_outcome(14u64, True{}, False{}, False{}) == 1u64 : U64}

def empty_union_a_empty():
  {==}

law empty_union_b_empty:
  {B8.empty_outcome(14u64, False{}, True{}, False{}) == 0u64 : U64}

def empty_union_b_empty():
  {==}

law empty_union_full:
  {B8.empty_outcome(14u64, False{}, False{}, False{}) == 10u64 : U64}

def empty_union_full():
  {==}

law empty_union_identical:
  {B8.empty_outcome(14u64, False{}, False{}, True{}) == 0u64 : U64}

def empty_union_identical():
  {==}

law empty_union_a_empty_identical:
  {B8.empty_outcome(14u64, True{}, False{}, True{}) == 0u64 : U64}

def empty_union_a_empty_identical():
  {==}

law empty_union_b_empty_identical:
  {B8.empty_outcome(14u64, False{}, True{}, True{}) == 0u64 : U64}

def empty_union_b_empty_identical():
  {==}

law empty_diff_both_empty:
  {B8.empty_outcome(15u64, True{}, True{}, False{}) == 3u64 : U64}

def empty_diff_both_empty():
  {==}

law empty_diff_a_empty:
  {B8.empty_outcome(15u64, True{}, False{}, False{}) == 3u64 : U64}

def empty_diff_a_empty():
  {==}

law empty_diff_b_empty:
  {B8.empty_outcome(15u64, False{}, True{}, False{}) == 0u64 : U64}

def empty_diff_b_empty():
  {==}

law empty_diff_full:
  {B8.empty_outcome(15u64, False{}, False{}, False{}) == 10u64 : U64}

def empty_diff_full():
  {==}

law empty_diff_identical:
  {B8.empty_outcome(15u64, False{}, False{}, True{}) == 3u64 : U64}

def empty_diff_identical():
  {==}

law empty_diff_a_empty_identical:
  {B8.empty_outcome(15u64, True{}, False{}, True{}) == 3u64 : U64}

def empty_diff_a_empty_identical():
  {==}

law empty_diff_b_empty_identical:
  {B8.empty_outcome(15u64, False{}, True{}, True{}) == 3u64 : U64}

def empty_diff_b_empty_identical():
  {==}

law empty_inter_both_empty:
  {B8.empty_outcome(16u64, True{}, True{}, False{}) == 3u64 : U64}

def empty_inter_both_empty():
  {==}

law empty_inter_a_empty:
  {B8.empty_outcome(16u64, True{}, False{}, False{}) == 3u64 : U64}

def empty_inter_a_empty():
  {==}

law empty_inter_b_empty:
  {B8.empty_outcome(16u64, False{}, True{}, False{}) == 3u64 : U64}

def empty_inter_b_empty():
  {==}

law empty_inter_full:
  {B8.empty_outcome(16u64, False{}, False{}, False{}) == 10u64 : U64}

def empty_inter_full():
  {==}

law empty_inter_identical:
  {B8.empty_outcome(16u64, False{}, False{}, True{}) == 0u64 : U64}

def empty_inter_identical():
  {==}

law empty_inter_a_empty_identical:
  {B8.empty_outcome(16u64, True{}, False{}, True{}) == 0u64 : U64}

def empty_inter_a_empty_identical():
  {==}

law empty_inter_b_empty_identical:
  {B8.empty_outcome(16u64, False{}, True{}, True{}) == 0u64 : U64}

def empty_inter_b_empty_identical():
  {==}

# --- Intent material (L13): 1 add, 2 remove, 3 same, 4 unknown ---
law mat_union_append_grows:
  {B8.bool_mat(14u64, 2u64, I.I{1.0f64, 1.0f64}, I.I{2.0f64, 2.0f64}, 0u64) == 1u64 : U64}

def mat_union_append_grows():
  {==}

law mat_union_append_flat_is_unknown:
  {B8.bool_mat(14u64, 2u64, I.I{0.0f64, 0.0f64}, I.I{2.0f64, 2.0f64}, 0u64) == 4u64 : U64}

def mat_union_append_flat_is_unknown():
  {==}

law mat_diff_cavity_shrinks:
  {B8.bool_mat(15u64, 4u64, I.I{8.0f64, 8.0f64}, I.I{1.0f64, 1.0f64}, 1u64) == 2u64 : U64}

def mat_diff_cavity_shrinks():
  {==}

law mat_diff_cavity_flat_tool_is_unknown:
  {B8.bool_mat(15u64, 4u64, I.I{8.0f64, 8.0f64}, I.I{0.0f64, 0.0f64}, 1u64) == 4u64 : U64}

def mat_diff_cavity_flat_tool_is_unknown():
  {==}

law mat_diff_cavity_reads_tool_side:
  {B8.bool_mat(15u64, 4u64, I.I{0.0f64, 0.0f64}, I.I{1.0f64, 1.0f64}, 0u64) == 4u64 : U64}

def mat_diff_cavity_reads_tool_side():
  {==}

law mat_carry_a_is_same:
  {B8.bool_mat(14u64, 0u64, I.I{1.0f64, 1.0f64}, I.I{1.0f64, 1.0f64}, 0u64) == 3u64 : U64}

def mat_carry_a_is_same():
  {==}

law mat_carry_b_is_same:
  {B8.bool_mat(16u64, 1u64, I.I{1.0f64, 1.0f64}, I.I{1.0f64, 1.0f64}, 0u64) == 3u64 : U64}

def mat_carry_b_is_same():
  {==}

law mat_empty_is_same:
  {B8.bool_mat(16u64, 3u64, I.I{1.0f64, 1.0f64}, I.I{1.0f64, 1.0f64}, 0u64) == 3u64 : U64}

def mat_empty_is_same():
  {==}

law mat_inter_append_is_unknown:
  {B8.bool_mat(16u64, 2u64, I.I{1.0f64, 1.0f64}, I.I{1.0f64, 1.0f64}, 0u64) == 4u64 : U64}

def mat_inter_append_is_unknown():
  {==}

law mat_union_cavity_is_unknown:
  {B8.bool_mat(14u64, 4u64, I.I{1.0f64, 1.0f64}, I.I{1.0f64, 1.0f64}, 0u64) == 4u64 : U64}

def mat_union_cavity_is_unknown():
  {==}

law pos_vol_strict:
  {B8.pos_vol(I.I{1.0f64, 2.0f64}) == True{} : Bool}

def pos_vol_strict():
  {==}

law pos_vol_touching_zero:
  {B8.pos_vol(I.I{0.0f64, 0.0f64}) == False{} : Bool}

def pos_vol_touching_zero():
  {==}

law pos_vol_straddling_zero:
  {B8.pos_vol(I.I{F64.neg(1.0f64), 1.0f64}) == False{} : Bool}

def pos_vol_straddling_zero():
  {==}

# --- Contact partition (L9): contact is information, all else fails ---
law contact_edge_edge:
  {B8.is_contact("contact-edge-edge") == True{} : Bool}

def contact_edge_edge():
  {==}

law contact_edge_face:
  {B8.is_contact("contact-edge-face") == True{} : Bool}

def contact_edge_face():
  {==}

law contact_face_face:
  {B8.is_contact("contact-face-face") == True{} : Bool}

def contact_face_face():
  {==}

law contact_fail_closed:
  {B8.is_contact("edge-crossing") == False{} : Bool}

def contact_fail_closed():
  {==}

law unc_edge_crossing:
  {B8.is_uncertain_code("edge-crossing-uncertain") == True{} : Bool}

def unc_edge_crossing():
  {==}

law unc_edge_face:
  {B8.is_uncertain_code("edge-face-uncertain") == True{} : Bool}

def unc_edge_face():
  {==}

law unc_face_face:
  {B8.is_uncertain_code("face-face-uncertain") == True{} : Bool}

def unc_face_face():
  {==}

law unc_face_overlap:
  {B8.is_uncertain_code("face-overlap-uncertain") == True{} : Bool}

def unc_face_overlap():
  {==}

law unc_orientation:
  {B8.is_uncertain_code("orientation-uncertain") == True{} : Bool}

def unc_orientation():
  {==}

law unc_nesting:
  {B8.is_uncertain_code("nesting-uncertain") == True{} : Bool}

def unc_nesting():
  {==}

law unc_fail_closed:
  {B8.is_uncertain_code("edge-crossing") == False{} : Bool}

def unc_fail_closed():
  {==}

law unsup_edge:
  {B8.is_unsupported_code("edge-check-unsupported") == True{} : Bool}

def unsup_edge():
  {==}

law unsup_face:
  {B8.is_unsupported_code("face-check-unsupported") == True{} : Bool}

def unsup_face():
  {==}

law unsup_edge_face:
  {B8.is_unsupported_code("edge-face-unsupported") == True{} : Bool}

def unsup_edge_face():
  {==}

law unsup_fail_closed:
  {B8.is_unsupported_code("face-overlap") == False{} : Bool}

def unsup_fail_closed():
  {==}

# --- Stage names ---
law stage_incidence:
  {B8.stage_why(2u64) == "incidence" : String}

def stage_incidence():
  {==}

law stage_edge_use:
  {B8.stage_why(3u64) == "edge-use" : String}

def stage_edge_use():
  {==}

law stage_loop:
  {B8.stage_why(4u64) == "loop-closure-or-trim" : String}

def stage_loop():
  {==}

law stage_face_kind:
  {B8.stage_why(5u64) == "face-kind" : String}

def stage_face_kind():
  {==}

law stage_ownership:
  {B8.stage_why(6u64) == "ownership" : String}

def stage_ownership():
  {==}

law stage_embedding:
  {B8.stage_why(7u64) == "embedding" : String}

def stage_embedding():
  {==}

law stage_vertex_link:
  {B8.stage_why(8u64) == "vertex-link" : String}

def stage_vertex_link():
  {==}

law stage_shell:
  {B8.stage_why(9u64) == "shell-connectivity" : String}

def stage_shell():
  {==}

law stage_coin:
  {B8.stage_why(10u64) == "coincident-vertices" : String}

def stage_coin():
  {==}

law stage_crossing:
  {B8.stage_why(11u64) == "segment-crossing" : String}

def stage_crossing():
  {==}

law stage_orientation:
  {B8.stage_why(12u64) == "orientation" : String}

def stage_orientation():
  {==}

law stage_unknown:
  {B8.stage_why(99u64) == "stage-unknown" : String}

def stage_unknown():
  {==}

# --- Admit domain (L5): first-match-wins in stage order ---
law admit_open_a_first:
  {B8.admit_code(True{}, True{}, 1u64, 1u64, 1u64, 1u64, True{}, True{}) == 1u64 : U64}

def admit_open_a_first():
  {==}

law admit_open_b:
  {B8.admit_code(False{}, True{}, 0u64, 0u64, 0u64, 0u64, True{}, True{}) == 2u64 : U64}

def admit_open_b():
  {==}

law admit_face_a:
  {B8.admit_code(False{}, False{}, 1u64, 0u64, 0u64, 0u64, True{}, True{}) == 3u64 : U64}

def admit_face_a():
  {==}

law admit_face_b:
  {B8.admit_code(False{}, False{}, 0u64, 2u64, 0u64, 0u64, True{}, True{}) == 4u64 : U64}

def admit_face_b():
  {==}

law admit_edge_a:
  {B8.admit_code(False{}, False{}, 0u64, 0u64, 1u64, 0u64, True{}, True{}) == 5u64 : U64}

def admit_edge_a():
  {==}

law admit_edge_b:
  {B8.admit_code(False{}, False{}, 0u64, 0u64, 0u64, 1u64, True{}, True{}) == 6u64 : U64}

def admit_edge_b():
  {==}

law admit_clean:
  {B8.admit_code(False{}, False{}, 0u64, 0u64, 0u64, 0u64, True{}, True{}) == 0u64 : U64}

def admit_clean():
  {==}

law shell_open_is_open:
  {B8.shell_open(Ty.SK_open{}) == True{} : Bool}

def shell_open_is_open():
  {==}

law shell_open_outer:
  {B8.shell_open(Ty.SK_outer{}) == False{} : Bool}

def shell_open_outer():
  {==}

law shell_open_inner:
  {B8.shell_open(Ty.SK_inner{}) == False{} : Bool}

def shell_open_inner():
  {==}

law admit_shs_empty:
  {B8.admit_shs([]) == False{} : Bool}

def admit_shs_empty():
  {==}

law admit_shs_closed:
  {B8.admit_shs([Ty.Sh{0u64, [], Ty.SK_outer{}}]) == False{} : Bool}

def admit_shs_closed():
  {==}

law admit_shs_open:
  {B8.admit_shs([Ty.Sh{0u64, [], Ty.SK_open{}}]) == True{} : Bool}

def admit_shs_open():
  {==}

law admit_shs_mixed:
  {B8.admit_shs([Ty.Sh{0u64, [], Ty.SK_outer{}}, Ty.Sh{0u64, [], Ty.SK_open{}}]) == True{} : Bool}

def admit_shs_mixed():
  {==}

law edge_code_degenerate:
  {B8.edge_code(Ty.EK_degenerate{}) == 0u64 : U64}

def edge_code_degenerate():
  {==}

law edge_code_line:
  {B8.edge_code(Ty.EK_curve{G.GV_ln{G.Ln{pt0(), dx()}}, dom01()}) == 0u64 : U64}

def edge_code_line():
  {==}

law edge_code_cubic:
  {B8.edge_code(Ty.EK_curve{G.GV_bz{G.Bz{pt0(), ptx(), pty(), pt0()}}, dom01()}) == 0u64 : U64}

def edge_code_cubic():
  {==}

law edge_code_circle:
  {B8.edge_code(Ty.EK_curve{G.GV_cc{G.Cc{pt0(), dx(), dy(), 1.0f64}}, dom01()}) == 0u64 : U64}

def edge_code_circle():
  {==}

law edge_code_rational:
  {B8.edge_code(Ty.EK_curve{G.GV_rq{G.Rq{pt0(), ptx(), pty(), 1.0f64, 1.0f64, 1.0f64}}, dom01()}) == 0u64 : U64}

def edge_code_rational():
  {==}

law edge_code_other:
  {B8.edge_code(Ty.EK_curve{G.GV_f{0.0f64}, dom01()}) == 1u64 : U64}

def edge_code_other():
  {==}

law edge_code_plane:
  {B8.edge_code(Ty.EK_curve{G.GV_pl{G.Pl{pt0(), dx(), dy()}}, dom01()}) == 1u64 : U64}

def edge_code_plane():
  {==}

law admit_eds_empty:
  {B8.admit_eds([]) == 0u64 : U64}

def admit_eds_empty():
  {==}

law admit_eds_line:
  {B8.admit_eds([Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{1n, 0u64}, Ty.EK_curve{G.GV_ln{G.Ln{pt0(), dx()}}, dom01()}}]) == 0u64 : U64}

def admit_eds_line():
  {==}

law admit_eds_bad:
  {B8.admit_eds([Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{1n, 0u64}, Ty.EK_curve{G.GV_f{0.0f64}, dom01()}}]) == 1u64 : U64}

def admit_eds_bad():
  {==}

law admit_eds_at_empty:
  {B8.admit_eds_at([], 0n) == 0n : Nat}

def admit_eds_at_empty():
  {==}

law admit_eds_at_second:
  {B8.admit_eds_at([Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{1n, 0u64}, Ty.EK_degenerate{}},
    Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{1n, 0u64}, Ty.EK_curve{G.GV_f{0.0f64}, dom01()}}], 0n) == 1n : Nat}

def admit_eds_at_second():
  {==}

law surf_why_bezier:
  {B8.surf_why(1u64) == "bezier-patch-operand" : String}

def surf_why_bezier():
  {==}

law surf_why_nurbs:
  {B8.surf_why(2u64) == "nurbs-operand" : String}

def surf_why_nurbs():
  {==}

law surf_why_other:
  {B8.surf_why(3u64) == "face-kind-not-supported" : String}

def surf_why_other():
  {==}

law surf_why_zero:
  {B8.surf_why(0u64) == "face-kind-not-supported" : String}

def surf_why_zero():
  {==}

law surf_admit_nb_nurbs:
  {B8.surf_admit_nb(G.GV_nb{G.Nb{[], [], []}}) == 2u64 : U64}

def surf_admit_nb_nurbs():
  {==}

law surf_admit_nb_other:
  {B8.surf_admit_nb(G.GV_f{0.0f64}) == 3u64 : U64}

def surf_admit_nb_other():
  {==}

law surf_admit_go_none:
  {B8.surf_admit_go(None{}, G.GV_nb{G.Nb{[], [], []}}) == 2u64 : U64}

def surf_admit_go_none():
  {==}

law surf_admit_plane:
  {B8.surf_admit(G.GV_pl{G.Pl{pt0(), dx(), dy()}}) == 0u64 : U64}

def surf_admit_plane():
  {==}

law admit_fas_empty:
  {B8.admit_fas([], 0n) == 0u64 : U64}

def admit_fas_empty():
  {==}

law admit_fas_plane:
  {B8.admit_fas([Ty.Fa{0u64, G.GV_pl{G.Pl{pt0(), dx(), dy()}}, [], True{}}], 0n) == 0u64 : U64}

def admit_fas_plane():
  {==}

law admit_fas_nurbs:
  {B8.admit_fas([Ty.Fa{0u64, G.GV_nb{G.Nb{[], [], []}}, [], True{}}], 0n) == 2u64 : U64}

def admit_fas_nurbs():
  {==}

law admit_fas_at_second:
  {B8.admit_fas_at([Ty.Fa{0u64, G.GV_pl{G.Pl{pt0(), dx(), dy()}}, [], True{}},
    Ty.Fa{0u64, G.GV_nb{G.Nb{[], [], []}}, [], True{}}], 0n) == 1n : Nat}

def admit_fas_at_second():
  {==}

# --- D2 (L18): flat bicubic walls reduce exactly; curved still refuse ---
law d2_flat_patch_admitted:
  {B8.surf_admit(G.GV_bp{flat_bp()}) == 0u64 : U64}

def d2_flat_patch_admitted():
  {==}

law d2_curved_patch_refused:
  {B8.surf_admit(G.GV_bp{curved_bp()}) == 1u64 : U64}

def d2_curved_patch_refused():
  {==}

law d2_bp_kind_is_bezier:
  {B8.surf_admit_nb(G.GV_bp{curved_bp()}) == 1u64 : U64}

def d2_bp_kind_is_bezier():
  {==}

def flat_line() -> G.GVal:
  G.GV_ln{G.Ln{fq(1.0f64, 1.0f64, F64.neg(1.0f64)), V.Dr{0.0f64, 0.0f64, 1.0f64}}}

law flat_bp_line_on_plane:
  {XS.ez(XS.ex_horner(XS.comp_go(XS.gv_xc(flat_line()), XS.gv_xs(G.GV_bp{flat_bp()})), 1.0f64)) == True{} : Bool}

def flat_bp_line_on_plane():
  {==}

law curved_bp_xs_none:
  {XS.gv_xs_is(G.GV_bp{curved_bp()}) == False{} : Bool}

def curved_bp_xs_none():
  {==}

# --- Lineage and selectors (L11, L12) ---
law fn_nd_reads:
  {B8.fn_nd(BD.Fn{9u64, 1n, 4u64, 2n, 3n}) == 9u64 : U64}

def fn_nd_reads():
  {==}

law fn_k_reads:
  {B8.fn_k(BD.Fn{9u64, 1n, 4u64, 2n, 3n}) == 1n : Nat}

def fn_k_reads():
  {==}

law fn_role_reads:
  {B8.fn_role(BD.Fn{9u64, 1n, 4u64, 2n, 3n}) == 4u64 : U64}

def fn_role_reads():
  {==}

law fn_i_reads:
  {B8.fn_i(BD.Fn{9u64, 1n, 4u64, 2n, 3n}) == 2n : Nat}

def fn_i_reads():
  {==}

law fn_j_reads:
  {B8.fn_j(BD.Fn{9u64, 1n, 4u64, 2n, 3n}) == 3n : Nat}

def fn_j_reads():
  {==}

law fn_created_words:
  {B8.fn_created(9u64, 1n, 2n, 1u64) == BD.Fn{9u64, 1n, 4u64, 2n, 1n} : BD.Fn}

def fn_created_words():
  {==}

law fn_created_here_counts:
  {B8.fn_created_here([BD.Fn{9u64, 0n, 4u64, 0n, 0n}, BD.Fn{9u64, 1n, 2u64, 0n, 0n}, BD.Fn{7u64, 0n, 4u64, 0n, 0n}], 9u64) == 1n : Nat}

def fn_created_here_counts():
  {==}

law fn_created_here_empty:
  {B8.fn_created_here([], 9u64) == 0n : Nat}

def fn_created_here_empty():
  {==}

law fn_created_n_counts_role:
  {B8.fn_created_n([BD.Fn{9u64, 0n, 4u64, 0n, 0n}, BD.Fn{9u64, 1n, 2u64, 0n, 0n}, BD.Fn{7u64, 0n, 4u64, 0n, 0n}]) == 2n : Nat}

def fn_created_n_counts_role():
  {==}

law fn_full_eq_hit:
  {B8.fn_full_eq(BD.Fn{9u64, 1n, 4u64, 2n, 3n}, 9u64, 1n, 4u64, 2n, 3n) == True{} : Bool}

def fn_full_eq_hit():
  {==}

law fn_full_eq_miss:
  {B8.fn_full_eq(BD.Fn{9u64, 1n, 4u64, 2n, 3n}, 9u64, 1n, 4u64, 2n, 4n) == False{} : Bool}

def fn_full_eq_miss():
  {==}

law fn_pre_eq_hit:
  {B8.fn_pre_eq(BD.Fn{9u64, 1n, 4u64, 2n, 3n}, 9u64, 1n, 4u64) == True{} : Bool}

def fn_pre_eq_hit():
  {==}

law fn_pre_eq_miss:
  {B8.fn_pre_eq(BD.Fn{9u64, 1n, 4u64, 2n, 3n}, 9u64, 2n, 4u64) == False{} : Bool}

def fn_pre_eq_miss():
  {==}

law resolve_unique:
  {B8.resolve([BD.Fn{4u64, 0n, 4u64, 0n, 0n}], 4u64, 0n, 4u64, 0n, 0n, True{}) == B8.R_one{0n} : B8.Rs}

def resolve_unique():
  {==}

law resolve_second:
  {B8.resolve([BD.Fn{4u64, 1n, 4u64, 0n, 0n}, BD.Fn{4u64, 0n, 4u64, 0n, 0n}], 4u64, 0n, 4u64, 0n, 0n, True{}) == B8.R_one{1n} : B8.Rs}

def resolve_second():
  {==}

law resolve_missing:
  {B8.resolve([BD.Fn{4u64, 0n, 4u64, 0n, 0n}], 4u64, 0n, 4u64, 0n, 1n, True{}) == B8.R_miss{1n} : B8.Rs}

def resolve_missing():
  {==}

law resolve_empty_missing:
  {B8.resolve([], 4u64, 0n, 4u64, 0n, 0n, True{}) == B8.R_miss{0n} : B8.Rs}

def resolve_empty_missing():
  {==}

law resolve_ambiguous:
  {B8.resolve([BD.Fn{4u64, 0n, 4u64, 0n, 0n}, BD.Fn{4u64, 0n, 4u64, 0n, 0n}], 4u64, 0n, 4u64, 0n, 0n, True{}) == B8.R_amb{[0n, 1n]} : B8.Rs}

def resolve_ambiguous():
  {==}

law res_show_ambiguous:
  {B8.res_show(B8.R_amb{[0n, 1n]}, [BD.Fn{4u64, 0n, 4u64, 0n, 0n}, BD.Fn{4u64, 0n, 4u64, 0n, 0n}])
    == "ambiguous (2 faces match) n4.cav.0.0.0 n4.cav.0.0.0" : String}

def res_show_ambiguous():
  {==}

law resolve_set:
  {B8.resolve([BD.Fn{4u64, 1n, 4u64, 0n, 0n}, BD.Fn{4u64, 0n, 4u64, 0n, 0n}, BD.Fn{4u64, 0n, 4u64, 1n, 0n}], 4u64, 0n, 4u64, 0n, 0n, False{}) == B8.R_set{[1n, 2n]} : B8.Rs}

def resolve_set():
  {==}

law resolve_set_missing:
  {B8.resolve([BD.Fn{4u64, 1n, 4u64, 0n, 0n}], 4u64, 0n, 4u64, 0n, 0n, False{}) == B8.R_miss{1n} : B8.Rs}

def resolve_set_missing():
  {==}

# --- Masks, relations, helpers ---
law ag_agg_both:
  {B8.ag_agg(3u64) == 3u64 : U64}

def ag_agg_both():
  {==}

law ag_agg_in:
  {B8.ag_agg(1u64) == 1u64 : U64}

def ag_agg_in():
  {==}

law ag_agg_out:
  {B8.ag_agg(2u64) == 2u64 : U64}

def ag_agg_out():
  {==}

law ag_agg_none:
  {B8.ag_agg(0u64) == 0u64 : U64}

def ag_agg_none():
  {==}

law ag_agg_boundary_only:
  {B8.ag_agg(4u64) == 0u64 : U64}

def ag_agg_boundary_only():
  {==}

law ag_agg_in_boundary:
  {B8.ag_agg(5u64) == 1u64 : U64}

def ag_agg_in_boundary():
  {==}

law ag_agg_out_boundary:
  {B8.ag_agg(6u64) == 2u64 : U64}

def ag_agg_out_boundary():
  {==}

law rel_list_empty:
  {B8.rel_list([]) == [] : List<&2, U64>}

def rel_list_empty():
  {==}

law rel_list_maps:
  {B8.rel_list([1u64, 2u64, 3u64]) == [1u64, 2u64, 3u64] : List<&2, U64>}

def rel_list_maps():
  {==}

law rel_class_empty:
  {B8.rel_class([], 0n, 0n, 0n) == 6u64 : U64}

def rel_class_empty():
  {==}

law rel_class_all_in:
  {B8.rel_class([1u64, 1u64], 0n, 0n, 0n) == 1u64 : U64}

def rel_class_all_in():
  {==}

law rel_class_all_out:
  {B8.rel_class([2u64, 2u64], 0n, 0n, 0n) == 2u64 : U64}

def rel_class_all_out():
  {==}

law rel_class_mixed:
  {B8.rel_class([1u64, 2u64], 0n, 0n, 0n) == 5u64 : U64}

def rel_class_mixed():
  {==}

law rel_class_bad:
  {B8.rel_class([0u64], 0n, 0n, 0n) == 6u64 : U64}

def rel_class_bad():
  {==}

law rel_class_agg_mixed:
  {B8.rel_class([3u64], 0n, 0n, 0n) == 6u64 : U64}

def rel_class_agg_mixed():
  {==}

law n_has_hit:
  {B8.n_has([1n, 2n], 2n) == True{} : Bool}

def n_has_hit():
  {==}

law n_has_miss:
  {B8.n_has([1n, 2n], 3n) == False{} : Bool}

def n_has_miss():
  {==}

law n_has_empty:
  {B8.n_has([], 5n) == False{} : Bool}

def n_has_empty():
  {==}

law rel_has_hit:
  {B8.rel_has([1u64, 3u64], 3u64) == True{} : Bool}

def rel_has_hit():
  {==}

law rel_has_miss:
  {B8.rel_has([1u64, 2u64], 3u64) == False{} : Bool}

def rel_has_miss():
  {==}

law rel_why_mixed_is_crossing:
  {B8.rel_why([3u64], [2u64]) == "boundaries-cross-or-overlap: one solid samples strictly inside and outside the other" : String}

def rel_why_mixed_is_crossing():
  {==}

law rel_why_contact:
  {B8.rel_why([1u64], [2u64]) == "contact-not-certified" : String}

def rel_why_contact():
  {==}

law nth_nat_hit:
  {B8.nth_nat([7n, 8n], 1n) == 8n : Nat}

def nth_nat_hit():
  {==}

law nth_nat_miss:
  {B8.nth_nat([], 3n) == 0n : Nat}

def nth_nat_miss():
  {==}

law br_counts_empty:
  {B8.br_counts(Ty.brep_empty()) == [0n, 0n, 0n, 0n, 0n, 0n] : List<&2, Nat>}

def br_counts_empty():
  {==}

law nsolids_empty:
  {B8.nsolids(Ty.brep_empty()) == 0n : Nat}

def nsolids_empty():
  {==}

law genus_empty:
  {B8.genus_of(Ty.brep_empty()) == 0n : Nat}

def genus_empty():
  {==}

law sh_ids_go:
  {B8.sh_ids_go([Ty.HS{4n, 0u64}, Ty.HS{9n, 0u64}]) == [4n, 9n] : List<&2, Nat>}

def sh_ids_go():
  {==}

law sh_ids_go_empty:
  {B8.sh_ids_go([]) == [] : List<&2, Nat>}

def sh_ids_go_empty():
  {==}

# --- Boxes and baking ---
law bx_zero_is_origin:
  {B8.bx_zero() == B8.BX{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64} : B8.BX}

def bx_zero_is_origin():
  {==}

law bx_hull_grows:
  {B8.bx_hull(B8.BX{0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64}, B8.BX{2.0f64, 3.0f64, 2.0f64, 3.0f64, 2.0f64, 3.0f64}) == B8.BX{0.0f64, 3.0f64, 0.0f64, 3.0f64, 0.0f64, 3.0f64} : B8.BX}

def bx_hull_grows():
  {==}

law bx_disjoint_far:
  {B8.bx_disjoint(B8.BX{0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64}, B8.BX{2.0f64, 3.0f64, 2.0f64, 3.0f64, 2.0f64, 3.0f64}) == True{} : Bool}

def bx_disjoint_far():
  {==}

law bx_disjoint_overlap:
  {B8.bx_disjoint(B8.BX{0.0f64, 2.0f64, 0.0f64, 2.0f64, 0.0f64, 2.0f64}, B8.BX{1.0f64, 3.0f64, 1.0f64, 3.0f64, 1.0f64, 3.0f64}) == False{} : Bool}

def bx_disjoint_overlap():
  {==}

law bx_disjoint_touching_is_not_disjoint:
  {B8.bx_disjoint(B8.BX{0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64}, B8.BX{1.0f64, 2.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64}) == False{} : Bool}

def bx_disjoint_touching_is_not_disjoint():
  {==}

law bx_diag_sums:
  {B8.bx_diag(B8.BX{0.0f64, 1.0f64, 0.0f64, 2.0f64, 0.0f64, 3.0f64}) == 6.0f64 : F64}

def bx_diag_sums():
  {==}

law bx_x0_reads:
  {B8.BX_x0(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64}) == 1.0f64 : F64}

def bx_x0_reads():
  {==}

law bx_x1_reads:
  {B8.BX_x1(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64}) == 2.0f64 : F64}

def bx_x1_reads():
  {==}

law bx_y0_reads:
  {B8.BX_y0(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64}) == 3.0f64 : F64}

def bx_y0_reads():
  {==}

law bx_y1_reads:
  {B8.BX_y1(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64}) == 4.0f64 : F64}

def bx_y1_reads():
  {==}

law bx_z0_reads:
  {B8.BX_z0(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64}) == 5.0f64 : F64}

def bx_z0_reads():
  {==}

law bx_z1_reads:
  {B8.BX_z1(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64}) == 6.0f64 : F64}

def bx_z1_reads():
  {==}

law xf_pt_identity:
  {B8.xf_pt(m3id(), 0.0f64, 0.0f64, 0.0f64, V.Pt{1.0f64, 2.0f64, 3.0f64}) == V.Pt{1.0f64, 2.0f64, 3.0f64} : V.Point}

def xf_pt_identity():
  {==}

law xf_pt_translate_origin:
  {B8.xf_pt(m3id(), 1.0f64, 2.0f64, 3.0f64, pt0()) == V.Pt{1.0f64, 2.0f64, 3.0f64} : V.Point}

def xf_pt_translate_origin():
  {==}

law xf_dr_identity:
  {B8.xf_dr(m3id(), dx()) == dx() : V.Dir}

def xf_dr_identity():
  {==}

# --- Validation records (Layer B wiring) ---
law vr_fail_not_ok:
  {B8.VR_ok(B8.vr_fail(7u64, "edge-use", 1n, 2n)) == False{} : Bool}

def vr_fail_not_ok():
  {==}

law vr_fail_stage:
  {B8.VR_stage(B8.vr_fail(7u64, "edge-use", 1n, 2n)) == 7u64 : U64}

def vr_fail_stage():
  {==}

law vr_fail_code:
  {B8.VR_code(B8.vr_fail(7u64, "edge-use", 1n, 2n)) == "edge-use" : String}

def vr_fail_code():
  {==}

law vr_fail_a:
  {B8.VR_a(B8.vr_fail(7u64, "edge-use", 1n, 2n)) == 1n : Nat}

def vr_fail_a():
  {==}

law vr_fail_b:
  {B8.VR_b(B8.vr_fail(7u64, "edge-use", 1n, 2n)) == 2n : Nat}

def vr_fail_b():
  {==}

law vr_fail_nc_zero:
  {B8.VR_nc(B8.vr_fail(7u64, "edge-use", 1n, 2n)) == 0n : Nat}

def vr_fail_nc_zero():
  {==}

law vr_ok_true:
  {B8.VR_ok(B8.VR{True{}, 0u64, 5n, "", 0n, 0n}) == True{} : Bool}

def vr_ok_true():
  {==}

law vr_nc_reads:
  {B8.VR_nc(B8.VR{True{}, 0u64, 5n, "", 0n, 0n}) == 5n : Nat}

def vr_nc_reads():
  {==}

law vcode_stage:
  {B8.vcode(B8.VR{True{}, 12u64, 0n, "", 0n, 0n}) == "c04-orientation" : String}

def vcode_stage():
  {==}

law vcode_finding:
  {B8.vcode(B8.VR{True{}, 0u64, 0n, "edge-crossing", 3n, 7n}) == "edge-crossing 3 7" : String}

def vcode_finding():
  {==}

law cr_reads:
  {B8.CR_ok(B8.CR{True{}, 3n, 1n, 2n}) == True{} : Bool}

def cr_reads():
  {==}

law cr_nc_reads:
  {B8.CR_nc(B8.CR{True{}, 3n, 1n, 2n}) == 3n : Nat}

def cr_nc_reads():
  {==}

law cr_a_reads:
  {B8.CR_a(B8.CR{True{}, 3n, 1n, 2n}) == 1n : Nat}

def cr_a_reads():
  {==}

law cr_b_reads:
  {B8.CR_b(B8.CR{True{}, 3n, 1n, 2n}) == 2n : Nat}

def cr_b_reads():
  {==}

law cv_ok_reads:
  {B8.CV_ok(B8.CV{True{}, Ty.brep_empty(), []}) == True{} : Bool}

def cv_ok_reads():
  {==}

law cv_brep_reads:
  {B8.CV_brep(B8.CV{True{}, Ty.brep_empty(), []}) == Ty.brep_empty() : Ty.Brep}

def cv_brep_reads():
  {==}

law cv_fns_reads:
  {B8.CV_fns(B8.CV{True{}, Ty.brep_empty(), []}) == [] : List<&2, BD.Fn>}

def cv_fns_reads():
  {==}

law ag_unc_reads:
  {B8.AG_unc(B8.AG{True{}, False{}, 0n, []}) == False{} : Bool}

def ag_unc_reads():
  {==}

law ag_masks_reads:
  {B8.AG_masks(B8.AG{True{}, False{}, 0n, []}) == [] : List<&2, U64>}

def ag_masks_reads():
  {==}

law out_empty_ok:
  {B8.Out_ok(B8.out_empty(9u64, "", [])) == True{} : Bool}

def out_empty_ok():
  {==}

law out_empty_kind:
  {B8.Out_kind(B8.out_empty(9u64, "", [])) == 0u64 : U64}

def out_empty_kind():
  {==}

law out_empty_carry:
  {B8.Out_carry(B8.out_empty(9u64, "", [])) == 0u64 : U64}

def out_empty_carry():
  {==}

law out_empty_mat:
  {B8.Out_mat(B8.out_empty(9u64, "", [])) == 3u64 : U64}

def out_empty_mat():
  {==}

law out_empty_solids:
  {B8.Out_sh(B8.out_empty(9u64, "", [])) == 0n : Nat}

def out_empty_solids():
  {==}

law out_empty_holes:
  {B8.Out_ho(B8.out_empty(9u64, "", [])) == 0n : Nat}

def out_empty_holes():
  {==}

law out_empty_vol:
  {B8.Out_vol(B8.out_empty(9u64, "", [])) == I.I{0.0f64, 0.0f64} : I.I}

def out_empty_vol():
  {==}

law out_empty_bb:
  {B8.Out_bb(B8.out_empty(9u64, "", [])) == B8.bx_zero() : B8.BX}

def out_empty_bb():
  {==}

law out_empty_cells:
  {B8.Out_cells(B8.out_empty(9u64, "", [])) == [] : List<&2, BD.Cl>}

def out_empty_cells():
  {==}

law out_empty_has_measures:
  {B8.Out_hasm(B8.out_empty(9u64, "", [])) == True{} : Bool}

def out_empty_has_measures():
  {==}

law out_fail_not_ok:
  {B8.Out_ok(B8.out_fail(1u64, "w", "l", "y", "f")) == False{} : Bool}

def out_fail_not_ok():
  {==}

law out_fail_kind:
  {B8.Out_kind(B8.out_fail(1u64, "w", "l", "y", "f")) == 1u64 : U64}

def out_fail_kind():
  {==}

law out_fail_what:
  {B8.Out_what(B8.out_fail(1u64, "w", "l", "y", "f")) == "w" : String}

def out_fail_what():
  {==}

law out_fail_why:
  {B8.Out_why(B8.out_fail(1u64, "w", "l", "y", "f")) == "y" : String}

def out_fail_why():
  {==}

law out_fail_fix:
  {B8.Out_fix(B8.out_fail(1u64, "w", "l", "y", "f")) == "f" : String}

def out_fail_fix():
  {==}

law out_fail_mat_unknown:
  {B8.Out_mat(B8.out_fail(1u64, "w", "l", "y", "f")) == 4u64 : U64}

def out_fail_mat_unknown():
  {==}

law out_carry_side:
  {B8.Out_carry(B8.out_carry_direct(in0(), 2u64, "", [])) == 2u64 : U64}

def out_carry_side():
  {==}

law out_carry_mat:
  {B8.Out_mat(B8.out_carry_direct(in0(), 2u64, "", [])) == 3u64 : U64}

def out_carry_mat():
  {==}

law out_carry_vol:
  {B8.Out_vol(B8.out_carry_direct(in0(), 2u64, "", [])) == I.I{1.0f64, 1.0f64} : I.I}

def out_carry_vol():
  {==}

law out_carry_brep:
  {B8.Out_brep(B8.out_carry_direct(in0(), 2u64, "", [])) == Ty.brep_empty() : Ty.Brep}

def out_carry_brep():
  {==}

law out_carry_lin:
  {B8.Out_lin(B8.out_carry_direct(in0(), 2u64, "", [])) == 0.5f64 : F64}

def out_carry_lin():
  {==}

law out_carry_solids:
  {B8.Out_sh(B8.out_carry_direct(in0(), 2u64, "", [])) == 0n : Nat}

def out_carry_solids():
  {==}

law out_carry_holes:
  {B8.Out_ho(B8.out_carry_direct(in0(), 2u64, "", [])) == 0n : Nat}

def out_carry_holes():
  {==}

law in_brep_reads:
  {B8.in_brep(in0()) == Ty.brep_empty() : Ty.Brep}

def in_brep_reads():
  {==}

law in_bo_reads:
  {B8.in_bo(in0()) == False{} : Bool}

def in_bo_reads():
  {==}

# --- Cavity transplant helpers (flip keeps C04 orientation) ---
law ce_flip_negates:
  {B8.ce_flip(Ty.Ce{0u64, Ty.HE{1n, 0u64}, True{}, G.GV_f{0.0f64}}) == Ty.Ce{0u64, Ty.HE{1n, 0u64}, False{}, G.GV_f{0.0f64}} : Ty.Coedge}

def ce_flip_negates():
  {==}

law ce_flip_twice_is_identity:
  {B8.ce_flip(B8.ce_flip(Ty.Ce{0u64, Ty.HE{1n, 0u64}, True{}, G.GV_f{0.0f64}})) == Ty.Ce{0u64, Ty.HE{1n, 0u64}, True{}, G.GV_f{0.0f64}} : Ty.Coedge}

def ce_flip_twice_is_identity():
  {==}

law cav_flip_fas_empty:
  {B8.cav_flip_fas([], 5n, 0n) == [] : List<&2, Ty.Face>}

def cav_flip_fas_empty():
  {==}

law cav_flip_fas_tool_flips:
  {B8.cav_flip_fas([Ty.Fa{0u64, G.GV_f{0.0f64}, [], True{}}], 0n, 0n) == [Ty.Fa{0u64, G.GV_f{0.0f64}, [], False{}}] : List<&2, Ty.Face>}

def cav_flip_fas_tool_flips():
  {==}

law cav_flip_fas_minuend_keeps:
  {B8.cav_flip_fas([Ty.Fa{0u64, G.GV_f{0.0f64}, [], False{}}], 1n, 0n) == [Ty.Fa{0u64, G.GV_f{0.0f64}, [], False{}}] : List<&2, Ty.Face>}

def cav_flip_fas_minuend_keeps():
  {==}

law cav_flip_ces_empty:
  {B8.cav_flip_ces([], [], 0n) == [] : List<&2, Ty.Coedge>}

def cav_flip_ces_empty():
  {==}

law cav_flip_ces_marked_flips:
  {B8.cav_flip_ces([Ty.Ce{0u64, Ty.HE{0n, 0u64}, True{}, G.GV_f{0.0f64}}], [0n], 0n) == [Ty.Ce{0u64, Ty.HE{0n, 0u64}, False{}, G.GV_f{0.0f64}}] : List<&2, Ty.Coedge>}

def cav_flip_ces_marked_flips():
  {==}

law cav_flip_ces_unmarked_keeps:
  {B8.cav_flip_ces([Ty.Ce{0u64, Ty.HE{0n, 0u64}, True{}, G.GV_f{0.0f64}}], [1n], 0n) == [Ty.Ce{0u64, Ty.HE{0n, 0u64}, True{}, G.GV_f{0.0f64}}] : List<&2, Ty.Coedge>}

def cav_flip_ces_unmarked_keeps():
  {==}

law cav_flip_lps_empty:
  {B8.cav_flip_lps([], [], 0n) == [] : List<&2, Ty.Loop>}

def cav_flip_lps_empty():
  {==}

law cav_flip_lps_reverses:
  {B8.cav_flip_lps([Ty.Lp{0u64, [Ty.HC{0n, 0u64}, Ty.HC{1n, 0u64}], Ty.LK_outer{}}], [0n], 0n) == [Ty.Lp{0u64, [Ty.HC{1n, 0u64}, Ty.HC{0n, 0u64}], Ty.LK_outer{}}] : List<&2, Ty.Loop>}

def cav_flip_lps_reverses():
  {==}

law cav_flip_lps_unmarked_keeps:
  {B8.cav_flip_lps([Ty.Lp{0u64, [Ty.HC{0n, 0u64}, Ty.HC{1n, 0u64}], Ty.LK_outer{}}], [5n], 0n) == [Ty.Lp{0u64, [Ty.HC{0n, 0u64}, Ty.HC{1n, 0u64}], Ty.LK_outer{}}] : List<&2, Ty.Loop>}

def cav_flip_lps_unmarked_keeps():
  {==}

law cav_floops_empty:
  {B8.cav_floops([], 0n, 0n) == [] : List<&2, Nat>}

def cav_floops_empty():
  {==}

law cav_floops_collects_tool:
  {B8.cav_floops([Ty.Fa{0u64, G.GV_f{0.0f64}, [Ty.HL{2n, 0u64}], True{}}], 0n, 0n) == [2n] : List<&2, Nat>}

def cav_floops_collects_tool():
  {==}

law cav_floops_skips_minuend:
  {B8.cav_floops([Ty.Fa{0u64, G.GV_f{0.0f64}, [Ty.HL{2n, 0u64}], True{}}], 1n, 0n) == [] : List<&2, Nat>}

def cav_floops_skips_minuend():
  {==}

law cav_fces_empty:
  {B8.cav_fces([], [], 0n) == [] : List<&2, Nat>}

def cav_fces_empty():
  {==}

law cav_fces_collects_marked:
  {B8.cav_fces([Ty.Lp{0u64, [Ty.HC{4n, 0u64}], Ty.LK_outer{}}], [0n], 0n) == [4n] : List<&2, Nat>}

def cav_fces_collects_marked():
  {==}

law hl_ids_go_acc:
  {B8.hl_ids_go([], [7n]) == [7n] : List<&2, Nat>}

def hl_ids_go_acc():
  {==}

law hl_ids_go_one:
  {B8.hl_ids_go([Ty.HL{3n, 0u64}], []) == [3n] : List<&2, Nat>}

def hl_ids_go_one():
  {==}

law hc_ids_go_empty:
  {B8.hc_ids_go([], []) == [] : List<&2, Nat>}

def hc_ids_go_empty():
  {==}

law hc_ids_go_one:
  {B8.hc_ids_go([Ty.HC{5n, 0u64}], []) == [5n] : List<&2, Nat>}

def hc_ids_go_one():
  {==}

law cav_kind_tool_outer_is_inner:
  {B8.cav_kind_shs([Ty.Sh{0u64, [], Ty.SK_outer{}}], [0n], 0n, 0n) == [Ty.Sh{0u64, [], Ty.SK_inner{}}] : List<&2, Ty.Shell>}

def cav_kind_tool_outer_is_inner():
  {==}

law cav_kind_tool_cavity_is_outer:
  {B8.cav_kind_shs([Ty.Sh{0u64, [], Ty.SK_inner{}}], [7n], 0n, 0n) == [Ty.Sh{0u64, [], Ty.SK_outer{}}] : List<&2, Ty.Shell>}

def cav_kind_tool_cavity_is_outer():
  {==}

law cav_kind_minuend_keeps:
  {B8.cav_kind_shs([Ty.Sh{0u64, [], Ty.SK_inner{}}], [], 1n, 0n) == [Ty.Sh{0u64, [], Ty.SK_inner{}}] : List<&2, Ty.Shell>}

def cav_kind_minuend_keeps():
  {==}

law cav_topsos_two:
  {B8.cav_topsos(2n, 5n) == [Ty.HSo{5n, 0u64}, Ty.HSo{6n, 0u64}] : List<&2, Ty.HSolid>}

def cav_topsos_two():
  {==}

law cav_topsos_zero:
  {B8.cav_topsos(0n, 5n) == [] : List<&2, Ty.HSolid>}

def cav_topsos_zero():
  {==}

law cav_islands_one:
  {B8.cav_islands([1n], 10n) == [Ty.So{0u64, Ty.HS{11n, 0u64}, []}] : List<&2, Ty.Solid>}

def cav_islands_one():
  {==}

law cav_islands_empty:
  {B8.cav_islands([], 10n) == [] : List<&2, Ty.Solid>}

def cav_islands_empty():
  {==}

law cav_add_cav_hit:
  {B8.cav_add_cav([Ty.So{0u64, Ty.HS{0n, 0u64}, []}], 0n, 7n, 0n) == [Ty.So{0u64, Ty.HS{0n, 0u64}, [Ty.HS{7n, 0u64}]}] : List<&2, Ty.Solid>}

def cav_add_cav_hit():
  {==}

law cav_add_cav_miss:
  {B8.cav_add_cav([Ty.So{0u64, Ty.HS{0n, 0u64}, []}], 1n, 7n, 0n) == [Ty.So{0u64, Ty.HS{0n, 0u64}, []}] : List<&2, Ty.Solid>}

def cav_add_cav_miss():
  {==}

law cav_outs_collects:
  {B8.cav_outs(Ty.brep_empty(), [Ty.So{0u64, Ty.HS{3n, 0u64}, []}]) == [3n] : List<&2, Nat>}

def cav_outs_collects():
  {==}

law cav_cavs_collects:
  {B8.cav_cavs(Ty.brep_empty(), [Ty.So{0u64, Ty.HS{3n, 0u64}, [Ty.HS{4n, 0u64}]}]) == [4n] : List<&2, Nat>}

def cav_cavs_collects():
  {==}

# --- Contact-aware embedding (L18 for the emb surgery) ---
# Degenerate-edge witness for ee_hit's context args (mirrors eg_k's
# EK_degenerate case); H_pt/H_ov/H_no verdicts ignore these args.
def egd() -> EM.Eg:
  EM.Eg{[], G.Dom{0.0f64, 1.0f64}, 0n, 0n, [], [], EM.cv0(), [], 1u64, 0n}

law emb_ee_overlap_cross_is_contact:
  {EM.ee_hit(XS.H_ov{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}}, [], [], 0.0f64, 3n, 7n, True{}, egd(), egd(), [], [], [], []) == [SO.Fi{"contact-edge-edge", 3n, 7n}] : List<&2, SO.Fi>}

def emb_ee_overlap_cross_is_contact():
  {==}

law emb_ee_overlap_same_is_fail:
  {EM.ee_hit(XS.H_ov{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}}, [], [], 0.0f64, 3n, 7n, False{}, egd(), egd(), [], [], [], []) == [SO.Fi{"edge-overlap", 3n, 7n}] : List<&2, SO.Fi>}

def emb_ee_overlap_same_is_fail():
  {==}

law emb_ee_crossing_cross_still_fails:
  {EM.ee_hit(XS.H_pt{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, [I.I{0.0f64, 0.0f64}], 0u64}, [], [], 0.0f64, 3n, 7n, True{}, egd(), egd(), [], [], [], []) == [SO.Fi{"edge-crossing", 3n, 7n}] : List<&2, SO.Fi>}

def emb_ee_crossing_cross_still_fails():
  {==}

law emb_ee_uncertain_cross_still_fails:
  {EM.ee_hit(XS.H_un{I.I{0.0f64, 1.0f64}, I.I{0.0f64, 1.0f64}, [I.I{0.0f64, 0.0f64}]}, [], [], 0.0f64, 3n, 7n, True{}, egd(), egd(), [], [], [], []) == [SO.Fi{"edge-crossing-uncertain", 3n, 7n}] : List<&2, SO.Fi>}

def emb_ee_uncertain_cross_still_fails():
  {==}

law emb_ee_unsupported_cross_still_fails:
  {EM.ee_hit(XS.H_no{"why"}, [], [], 0.0f64, 3n, 7n, True{}, egd(), egd(), [], [], [], []) == [SO.Fi{"edge-check-unsupported", 3n, 7n}] : List<&2, SO.Fi>}

def emb_ee_unsupported_cross_still_fails():
  {==}

law emb_ee_cross_endpoint_is_contact:
  {EM.ee_hit(XS.H_pt{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, [I.I{0.0f64, 0.0f64}], 0u64}, [], [[I.I{0.0f64, 0.0f64}]], 0.0f64, 3n, 7n, True{}, egd(), egd(), [], [], [], []) == [SO.Fi{"contact-edge-edge", 3n, 7n}] : List<&2, SO.Fi>}

def emb_ee_cross_endpoint_is_contact():
  {==}

law emb_ee_cross_interior_still_fails:
  {EM.ee_hit(XS.H_pt{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, [I.I{5.0f64, 5.0f64}], 0u64}, [], [[I.I{0.0f64, 0.0f64}]], 0.0f64, 3n, 7n, True{}, egd(), egd(), [], [], [], []) == [SO.Fi{"edge-crossing", 3n, 7n}] : List<&2, SO.Fi>}

def emb_ee_cross_interior_still_fails():
  {==}

law emb_ee_same_endpoint_excluded:
  {EM.ee_hit(XS.H_pt{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, [I.I{0.0f64, 0.0f64}], 0u64}, [[I.I{0.0f64, 0.0f64}]], [], 0.0f64, 3n, 7n, False{}, egd(), egd(), [], [], [], []) == [] : List<&2, SO.Fi>}

def emb_ee_same_endpoint_excluded():
  {==}

# --- Model bridge (Layer B wiring for the packet's model changes) ---
law model_bool_tag_union:
  {M.bool_tag(M.O_union{3u64, 5u64}) == 14u64 : U64}

def model_bool_tag_union():
  {==}

law model_bool_tag_diff:
  {M.bool_tag(M.O_difference{3u64, 5u64}) == 15u64 : U64}

def model_bool_tag_diff():
  {==}

law model_bool_tag_inter:
  {M.bool_tag(M.O_intersection{3u64, 5u64}) == 16u64 : U64}

def model_bool_tag_inter():
  {==}

law model_bool_tag_other:
  {M.bool_tag(M.O_unk{"x"}) == 0u64 : U64}

def model_bool_tag_other():
  {==}

law model_op_base_bool:
  {M.op_base(M.O_union{3u64, 5u64}) == 3u64 : U64}

def model_op_base_bool():
  {==}

law model_op_base2_bool:
  {M.op_base2(M.O_union{3u64, 5u64}) == 5u64 : U64}

def model_op_base2_bool():
  {==}

law model_op_base2_other:
  {M.op_base2(M.O_unk{"x"}) == 0u64 : U64}

def model_op_base2_other():
  {==}

law model_op_has_b2_bool:
  {M.op_has_b2(M.O_difference{3u64, 5u64}) == True{} : Bool}

def model_op_has_b2_bool():
  {==}

law model_op_has_b2_other:
  {M.op_has_b2(M.O_unk{"x"}) == False{} : Bool}

def model_op_has_b2_other():
  {==}

law model_op_is_bool:
  {M.op_is_bool(M.O_intersection{3u64, 5u64}) == True{} : Bool}

def model_op_is_bool():
  {==}

law model_op_is_bool_other:
  {M.op_is_bool(M.O_unk{"x"}) == False{} : Bool}

def model_op_is_bool_other():
  {==}

law model_op_name_union:
  {M.op_name(M.O_union{3u64, 5u64}) == "union" : String}

def model_op_name_union():
  {==}

law model_op_name_diff:
  {M.op_name(M.O_difference{3u64, 5u64}) == "difference" : String}

def model_op_name_diff():
  {==}

law model_op_name_inter:
  {M.op_name(M.O_intersection{3u64, 5u64}) == "intersection" : String}

def model_op_name_inter():
  {==}

law model_bool_mat_add:
  {M.bool_mat(1u64) == M.M_add{} : M.Mat}

def model_bool_mat_add():
  {==}

law model_bool_mat_remove:
  {M.bool_mat(2u64) == M.M_remove{} : M.Mat}

def model_bool_mat_remove():
  {==}

law model_bool_mat_same:
  {M.bool_mat(3u64) == M.M_same{} : M.Mat}

def model_bool_mat_same():
  {==}

law model_bool_mat_unknown:
  {M.bool_mat(4u64) == M.M_unknown{} : M.Mat}

def model_bool_mat_unknown():
  {==}

law model_bool_mat_other_unknown:
  {M.bool_mat(0u64) == M.M_unknown{} : M.Mat}

def model_bool_mat_other_unknown():
  {==}

law model_bool_kind_invalid:
  {M.bool_kind(0u64) == T.F_invalid{} : T.FailKind}

def model_bool_kind_invalid():
  {==}

law model_bool_kind_uncertain:
  {M.bool_kind(1u64) == T.F_uncertain{} : T.FailKind}

def model_bool_kind_uncertain():
  {==}

law model_bool_kind_unsupported:
  {M.bool_kind(2u64) == T.F_unsupported{} : T.FailKind}

def model_bool_kind_unsupported():
  {==}

law model_xb_id:
  {M.xb_id() == M.Xb{[], 0n, False{}, "", []} : M.Xb}

def model_xb_id():
  {==}

law model_xb_mx:
  {M.xb_mx(M.Xb{[mval()], 1n, True{}, "", []}) == [mval()] : List<&2, M.Ms>}

def model_xb_mx():
  {==}

law model_xb_nc:
  {M.xb_nc(M.Xb{[mval()], 1n, True{}, "", []}) == 1n : Nat}

def model_xb_nc():
  {==}

law model_xb_bo:
  {M.xb_bo(M.Xb{[mval()], 1n, True{}, "", []}) == True{} : Bool}

def model_xb_bo():
  {==}

law model_body_mx_stored:
  {M.body_mx(bd0(), [mval()]) == M.Ms{I.I{1.0f64, 2.0f64}, I.I{3.0f64, 4.0f64}, I.dn(5.0f64),
    I.up(6.0f64), I.dn(7.0f64), I.up(8.0f64), I.dn(9.0f64), I.up(10.0f64), 11n, 12n, 13n, 14n, 15n,
    16.0f64} : M.Ms}

def model_body_mx_stored():
  {==}

law model_body_mx_vol_passthrough:
  {M.ms_vol(M.body_mx(bd0(), [mval()])) == I.I{1.0f64, 2.0f64} : I.I}

def model_body_mx_vol_passthrough():
  {==}

law model_body_mx_moved:
  {M.body_mx(M.Bd{[], Ty.brep_empty(), [], M.pl_move(M.pl_id(), 0u64, 10.0f64, 0.0f64, 0.0f64), [],
    M.xb_id()}, [mval()]) == M.Ms{I.I{1.0f64, 2.0f64}, I.I{3.0f64, 4.0f64}, I.dn(15.0f64),
    I.up(16.0f64), I.dn(7.0f64), I.up(8.0f64), I.dn(9.0f64), I.up(10.0f64), 11n, 12n, 13n, 14n, 15n,
    16.0f64} : M.Ms}

def model_body_mx_moved():
  {==}

law model_ms_vol:
  {M.ms_vol(mval()) == I.I{1.0f64, 2.0f64} : I.I}

def model_ms_vol():
  {==}

law model_ms_area:
  {M.ms_area(mval()) == I.I{3.0f64, 4.0f64} : I.I}

def model_ms_area():
  {==}

law model_ms_x0:
  {M.ms_x0(mval()) == 5.0f64 : F64}

def model_ms_x0():
  {==}

law model_ms_x1:
  {M.ms_x1(mval()) == 6.0f64 : F64}

def model_ms_x1():
  {==}

law model_ms_y0:
  {M.ms_y0(mval()) == 7.0f64 : F64}

def model_ms_y0():
  {==}

law model_ms_y1:
  {M.ms_y1(mval()) == 8.0f64 : F64}

def model_ms_y1():
  {==}

law model_ms_z0:
  {M.ms_z0(mval()) == 9.0f64 : F64}

def model_ms_z0():
  {==}

law model_ms_z1:
  {M.ms_z1(mval()) == 10.0f64 : F64}

def model_ms_z1():
  {==}

law model_ms_lin:
  {M.ms_lin(mval()) == 16.0f64 : F64}

def model_ms_lin():
  {==}

law model_ms_ns:
  {M.ms_ns(mval()) == 14n : Nat}

def model_ms_ns():
  {==}

law model_ms_genus:
  {M.ms_genus(mval()) == 15n : Nat}

def model_ms_genus():
  {==}

law model_pl_m:
  {M.pl_m(M.Pl{m3id(), 1.0f64, 2.0f64, 3.0f64, [], []}) == m3id() : V.Mat3}

def model_pl_m():
  {==}

law model_pl_tx:
  {M.pl_tx(M.Pl{m3id(), 1.0f64, 2.0f64, 3.0f64, [], []}) == 1.0f64 : F64}

def model_pl_tx():
  {==}

law model_pl_ty:
  {M.pl_ty(M.Pl{m3id(), 1.0f64, 2.0f64, 3.0f64, [], []}) == 2.0f64 : F64}

def model_pl_ty():
  {==}

law model_pl_tz:
  {M.pl_tz(M.Pl{m3id(), 1.0f64, 2.0f64, 3.0f64, [], []}) == 3.0f64 : F64}

def model_pl_tz():
  {==}

# --- Design syntax (print + parse roundtrip arms) ---
law sx_print_union:
  {S.sx_show(S.op_sx(M.O_union{1u64, 2u64}, [])) == "(union 1 2)" : String}

def sx_print_union():
  {==}

law sx_print_diff:
  {S.sx_show(S.op_sx(M.O_difference{1u64, 2u64}, [])) == "(difference 1 2)" : String}

def sx_print_diff():
  {==}

law sx_print_inter:
  {S.sx_show(S.op_sx(M.O_intersection{1u64, 2u64}, [])) == "(intersection 1 2)" : String}

def sx_print_inter():
  {==}

law sx_parse_union:
  {src_op("(node 4 (union 1 2) (intent same 0 0 1 0))") == M.O_union{1u64, 2u64} : M.Op}

def sx_parse_union():
  {==}

law sx_parse_diff:
  {src_op("(node 4 (difference 1 2) (intent same 0 0 1 0))") == M.O_difference{1u64, 2u64} : M.Op}

def sx_parse_diff():
  {==}

law sx_parse_inter:
  {src_op("(node 4 (intersection 1 2) (intent same 0 0 1 0))") == M.O_intersection{1u64, 2u64} : M.Op}

def sx_parse_inter():
  {==}

# --- Adversarial-fix pins (F3 broad-phase boxes) ---
law wbox_empty_is_zero:
  {B8.wbox_of(Ty.brep_empty()) == B8.bx_zero() : B8.BX}

def wbox_empty_is_zero():
  {==}

law bake_eps_covers_lin:
  {F64.is_le(0.5f64, B8.bake_eps(B8.BX{0.0f64, 10.0f64, 0.0f64, 10.0f64, 0.0f64, 10.0f64}, 0.5f64)) == True{} : Bool}

def bake_eps_covers_lin():
  {==}

law bx_widen_contains:
  {Bool.and(F64.is_le(B8.BX_x0(B8.bx_widen(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64}, 0.25f64)), 1.0f64), F64.is_le(2.0f64, B8.BX_x1(B8.bx_widen(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64}, 0.25f64)))) == True{} : Bool}

def bx_widen_contains():
  {==}

law iv_bx_reads:
  {B8.iv_bx([I.I{1.0f64, 2.0f64}, I.I{3.0f64, 4.0f64}, I.I{5.0f64, 6.0f64}]) == B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64} : B8.BX}

def iv_bx_reads():
  {==}

law bx_mag_reads:
  {B8.bx_mag(B8.BX{F64.neg(3.0f64), 2.0f64, 0.0f64, 1.0f64, F64.neg(1.0f64), 1.0f64}) == 3.0f64 : F64}

def bx_mag_reads():
  {==}

# --- Adversarial-fix pins (F4 interval placement) ---
law admit_interval_a:
  {B8.admit_code(False{}, False{}, 0u64, 0u64, 0u64, 0u64, False{}, True{}) == 7u64 : U64}

def admit_interval_a():
  {==}

law admit_interval_b:
  {B8.admit_code(False{}, False{}, 0u64, 0u64, 0u64, 0u64, True{}, False{}) == 8u64 : U64}

def admit_interval_b():
  {==}

law admit_open_beats_interval:
  {B8.admit_code(True{}, False{}, 0u64, 0u64, 0u64, 0u64, False{}, False{}) == 1u64 : U64}

def admit_open_beats_interval():
  {==}

law admit_edge_beats_interval:
  {B8.admit_code(False{}, False{}, 0u64, 0u64, 0u64, 1u64, False{}, True{}) == 6u64 : U64}

def admit_edge_beats_interval():
  {==}

# --- Adversarial-fix pins (F5 piercing discriminator) ---
law ef_bad_same_ignores_mode:
  {EM.ef_bad(False{}, 1u64, "edge-face-penetration") == "edge-face-penetration" : String}

def ef_bad_same_ignores_mode():
  {==}

law ef_bad_cross_contact:
  {EM.ef_bad(True{}, 0u64, "edge-face-penetration") == "contact-edge-face" : String}

def ef_bad_cross_contact():
  {==}

law ef_bad_cross_pierce:
  {EM.ef_bad(True{}, 1u64, "edge-face-penetration") == "edge-face-penetration" : String}

def ef_bad_cross_pierce():
  {==}

law ef_bad_cross_uncertain:
  {EM.ef_bad(True{}, 2u64, "edge-face-overlap") == "edge-face-uncertain" : String}

def ef_bad_cross_uncertain():
  {==}

law ef_mode_go_inside:
  {EM.ef_mode_go(1u64, 0u64) == 1u64 : U64}

def ef_mode_go_inside():
  {==}

law ef_mode_go_outside:
  {EM.ef_mode_go(0u64, 3u64) == 0u64 : U64}

def ef_mode_go_outside():
  {==}

law ef_mode_go_uncertain:
  {EM.ef_mode_go(2u64, 0u64) == 2u64 : U64}

def ef_mode_go_uncertain():
  {==}

law ef_mode_go_inside_beats_uncertain:
  {EM.ef_mode_go(2u64, 1u64) == 1u64 : U64}

def ef_mode_go_inside_beats_uncertain():
  {==}

law ef_mode_same_is_contact:
  {EM.ef_mode([], [], [], False{}) == 0u64 : U64}

def ef_mode_same_is_contact():
  {==}

law m_code_x_outside_is_empty:
  {EM.m_code_x(0u64, "contact-edge-face", 3n, 7n) == [] : List<&2, SO.Fi>}

def m_code_x_outside_is_empty():
  {==}

law m_code_x_inside_is_contact:
  {EM.m_code_x(1u64, "contact-edge-face", 3n, 7n) == [SO.Fi{"contact-edge-face", 3n, 7n}] : List<&2, SO.Fi>}

def m_code_x_inside_is_contact():
  {==}

law m_code_x_boundary_is_contact:
  {EM.m_code_x(2u64, "contact-edge-face", 3n, 7n) == [SO.Fi{"contact-edge-face", 3n, 7n}] : List<&2, SO.Fi>}

def m_code_x_boundary_is_contact():
  {==}

law ef_ov_cross_lenient:
  {EM.ef_ov(2u64, "contact-edge-face", "edge-face-overlap", True{}, 3n, 7n) == [SO.Fi{"contact-edge-face", 3n, 7n}] : List<&2, SO.Fi>}

def ef_ov_cross_lenient():
  {==}

law ef_ov_same_strict:
  {EM.ef_ov(2u64, "contact-edge-face", "edge-face-overlap", False{}, 3n, 7n) == [SO.Fi{"edge-face-uncertain", 3n, 7n}] : List<&2, SO.Fi>}

def ef_ov_same_strict():
  {==}

# --- Adversarial-fix pins (F5c trim-boundary verdict) ---
law ef_bad2_contact:
  {EM.ef_bad2(0u64) == "contact-edge-face" : String}

def ef_bad2_contact():
  {==}

law ef_bad2_pierce:
  {EM.ef_bad2(1u64) == "edge-face-penetration" : String}

def ef_bad2_pierce():
  {==}

law ef_bad2_uncertain:
  {EM.ef_bad2(2u64) == "edge-face-uncertain" : String}

def ef_bad2_uncertain():
  {==}

law ef_bad2_boundary_mode_is_contact:
  {EM.ef_bad2(3u64) == "contact-edge-face" : String}

def ef_bad2_boundary_mode_is_contact():
  {==}

# --- Adversarial-fix pins (F5/F18 tangent-vs-piercing test) ---
law ef_clamp_mid:
  {EM.ef_clamp(0.5f64, 0.0f64, 1.0f64) == 0.5f64 : F64}

def ef_clamp_mid():
  {==}

law ef_clamp_lo:
  {EM.ef_clamp(F64.neg(1.0f64), 0.0f64, 1.0f64) == 0.0f64 : F64}

def ef_clamp_lo():
  {==}

law ef_clamp_hi:
  {EM.ef_clamp(2.0f64, 0.0f64, 1.0f64) == 1.0f64 : F64}

def ef_clamp_hi():
  {==}

law ef_tan_code_contact:
  {EM.ef_tan_code(0u64) == "contact-edge-face" : String}

def ef_tan_code_contact():
  {==}

law ef_tan_code_pierce:
  {EM.ef_tan_code(1u64) == "edge-face-penetration" : String}

def ef_tan_code_pierce():
  {==}

law ef_tan_code_uncertain:
  {EM.ef_tan_code(2u64) == "edge-face-uncertain" : String}

def ef_tan_code_uncertain():
  {==}

# --- Adversarial-fix pins (F5/F18 exact sphere tangency + adjacency) ---
law ff_iv_overlap_hit:
  {EM.ff_iv_overlap(I.I{1.0f64, 2.0f64}, I.I{1.5f64, 3.0f64}) == True{} : Bool}

def ff_iv_overlap_hit():
  {==}

law ff_iv_overlap_miss_lo:
  {EM.ff_iv_overlap(I.I{1.0f64, 2.0f64}, I.I{3.0f64, 4.0f64}) == False{} : Bool}

def ff_iv_overlap_miss_lo():
  {==}

law ff_iv_overlap_miss_hi:
  {EM.ff_iv_overlap(I.I{3.0f64, 4.0f64}, I.I{1.0f64, 2.0f64}) == False{} : Bool}

def ff_iv_overlap_miss_hi():
  {==}

law ff_iv_overlap_touch:
  {EM.ff_iv_overlap(I.I{1.0f64, 2.0f64}, I.I{2.0f64, 3.0f64}) == True{} : Bool}

def ff_iv_overlap_touch():
  {==}

law es_share_hit:
  {EM.es_share([1n, 2n, 3n], [5n, 2n]) == True{} : Bool}

def es_share_hit():
  {==}

law es_share_miss:
  {EM.es_share([1n, 2n, 3n], [5n, 6n]) == False{} : Bool}

def es_share_miss():
  {==}

law es_share_empty:
  {EM.es_share([], [5n]) == False{} : Bool}

def es_share_empty():
  {==}

# --- Adversarial-fix pins (F18 interior samples) ---
law sm_mid_pt_none:
  {B8.sm_mid_pt(None{}, 3n) == [] : List<&2, B8.SM>}

def sm_mid_pt_none():
  {==}

law sm_mid_pt_some:
  {B8.sm_mid_pt(Some{[I.ipt(1.0f64), I.ipt(2.0f64), I.ipt(4.0f64)]}, 3n)
    == [B8.SM{V.Pt{1.0f64, 2.0f64, 4.0f64}, 3n}] : List<&2, B8.SM>}

def sm_mid_pt_some():
  {==}

law sm_int_fd_empty:
  {B8.sm_int_fd([], 3n) == [] : List<&2, B8.SM>}

def sm_int_fd_empty():
  {==}

# --- Adversarial-fix pins (F7 fallback-plane orientation) ---
def bp_z_sign(m: Maybe<&2, XS.E3>) -> P.Sgn:
  match m:
    case None{}: P.Sz{}
    case Some{n}: E.ex_sign(XS.e3_z(n))

def d2_degen_net() -> List<&2, V.Point>:
  [fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64)]

law d2_primary_sign:
  {E.ex_sign(XS.e3_z(XS.bp_nrm(fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 1.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64)))) == P.Sn{} : P.Sgn}

def d2_primary_sign():
  {==}

law d2_fallback3_sign:
  {E.ex_sign(XS.e3_z(XS.bp_nrm(fq(0.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64)))) == P.Sn{} : P.Sgn}

def d2_fallback3_sign():
  {==}

law d2_old4_order_flipped:
  {E.ex_sign(XS.e3_z(XS.bp_nrm(fq(0.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64)))) == P.Sp{} : P.Sgn}

def d2_old4_order_flipped():
  {==}

law d2_old_order_flipped:
  {E.ex_sign(XS.e3_z(XS.bp_nrm(fq(0.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64)))) == P.Sp{} : P.Sgn}

def d2_old_order_flipped():
  {==}

law d2_pick_degenerate_net:
  {bp_z_sign(XS.bp_pick(fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64), d2_degen_net())) == P.Sn{} : P.Sgn}

def d2_pick_degenerate_net():
  {==}

# --- Adversarial-fix pins (F9 unknown-code partition) ---
law transverse_edge_crossing:
  {B8.is_transverse_code("edge-crossing") == True{} : Bool}

def transverse_edge_crossing():
  {==}

law transverse_nesting:
  {B8.is_transverse_code("cavities-nested") == True{} : Bool}

def transverse_nesting():
  {==}

law transverse_unknown_false:
  {B8.is_transverse_code("future-code") == False{} : Bool}

def transverse_unknown_false():
  {==}

law partition_unknown_is_none:
  {Bool.and(Bool.not(B8.is_contact("future-code")), Bool.and(Bool.not(B8.is_uncertain_code("future-code")), Bool.not(B8.is_unsupported_code("future-code")))) == True{} : Bool}

def partition_unknown_is_none():
  {==}

law intersect_unknown_is_uncertain:
  {B8.Out_kind(B8.intersect_fail(9u64, 1u64, 2u64, B8.VR{False{}, 0u64, 0n, "future-code", 3n, 7n})) == 1u64 : U64}

def intersect_unknown_is_uncertain():
  {==}

law intersect_unknown_why:
  {B8.Out_why(B8.intersect_fail(9u64, 1u64, 2u64, B8.VR{False{}, 0u64, 0n, "future-code", 3n, 7n})) == "unknown-finding: future-code 3 7 between nodes 1 and 2" : String}

def intersect_unknown_why():
  {==}

law intersect_transverse_still_crosses:
  {B8.Out_why(B8.intersect_fail(9u64, 1u64, 2u64, B8.VR{False{}, 0u64, 0n, "edge-crossing", 3n, 7n})) == "boundaries-cross-or-overlap: edge-crossing 3 7 between nodes 1 and 2" : String}

def intersect_transverse_still_crosses():
  {==}

# --- Adversarial-fix pins (F10 stored-box rounding) ---
law append_out_rebox:
  {B8.Out_bb(B8.append_out(14u64, in0(), in0(), Ty.brep_empty(), 9u64, 0n, B8.BX{0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64}, B8.BX{2.0f64, 3.0f64, 2.0f64, 3.0f64, 2.0f64, 3.0f64}, "")) == B8.BX{0.0f64, 3.0f64, 0.0f64, 3.0f64, 0.0f64, 3.0f64} : B8.BX}

def append_out_rebox():
  {==}

law append_out_no_del:
  {B8.Out_del(B8.append_out(14u64, in0(), in0(), Ty.brep_empty(), 9u64, 0n, B8.bx_zero(), B8.bx_zero(), "")) == [] : List<&2, B8.Del>}

def append_out_no_del():
  {==}

law append_out_proof:
  {B8.Out_proof(B8.append_out(14u64, in0(), in0(), Ty.brep_empty(), 9u64, 0n, B8.bx_zero(), B8.bx_zero(), "p")) == "p" : String}

def append_out_proof():
  {==}

# --- Adversarial-fix pins (F11 bake arm parity: every admitted arm moves) ---
law xf_moves_ln:
  {B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_ln{G.Ln{pt0(), dx()}}) == G.GV_ln{G.Ln{fq(1.0f64, 0.0f64, 0.0f64), dx()}} : G.GVal}

def xf_moves_ln():
  {==}

law xf_moves_pl:
  {B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_pl{G.Pl{pt0(), dx(), dy()}}) == G.GV_pl{G.Pl{fq(1.0f64, 0.0f64, 0.0f64), dx(), dy()}} : G.GVal}

def xf_moves_pl():
  {==}

law xf_moves_cc:
  {B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_cc{G.Cc{pt0(), dx(), dy(), 2.0f64}}) == G.GV_cc{G.Cc{fq(1.0f64, 0.0f64, 0.0f64), dx(), dy(), 2.0f64}} : G.GVal}

def xf_moves_cc():
  {==}

law xf_moves_bz:
  {B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_bz{G.Bz{pt0(), ptx(), pty(), pt0()}}) == G.GV_bz{G.Bz{fq(1.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64), fq(1.0f64, 0.0f64, 0.0f64)}} : G.GVal}

def xf_moves_bz():
  {==}

law xf_moves_rq:
  {B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_rq{G.Rq{pt0(), ptx(), pty(), 1.0f64, 1.0f64, 1.0f64}}) == G.GV_rq{G.Rq{fq(1.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64), 1.0f64, 1.0f64, 1.0f64}} : G.GVal}

def xf_moves_rq():
  {==}

law xf_moves_sp:
  {B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_sp{G.Sp{pt0(), 2.0f64}}) == G.GV_sp{G.Sp{fq(1.0f64, 0.0f64, 0.0f64), 2.0f64}} : G.GVal}

def xf_moves_sp():
  {==}

law xf_moves_cy:
  {B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_cy{G.Cy{pt0(), dx(), 2.0f64}}) == G.GV_cy{G.Cy{fq(1.0f64, 0.0f64, 0.0f64), dx(), 2.0f64}} : G.GVal}

def xf_moves_cy():
  {==}

law xf_moves_co:
  {B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_co{G.Co{pt0(), dx(), 2.0f64}}) == G.GV_co{G.Co{fq(1.0f64, 0.0f64, 0.0f64), dx(), 2.0f64}} : G.GVal}

def xf_moves_co():
  {==}

law xf_moves_to:
  {B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_to{G.To{pt0(), dx(), 3.0f64, 2.0f64}}) == G.GV_to{G.To{fq(1.0f64, 0.0f64, 0.0f64), dx(), 3.0f64, 2.0f64}} : G.GVal}

def xf_moves_to():
  {==}

law xf_moves_bb:
  {B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_bb{G.Bb{pt0(), ptx()}}) == G.GV_bb{G.Bb{fq(1.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64)}} : G.GVal}

def xf_moves_bb():
  {==}

law xf_moves_nb:
  {B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_nb{G.Nb{[], [pt0()], []}}) == G.GV_nb{G.Nb{[], [fq(1.0f64, 0.0f64, 0.0f64)], []}} : G.GVal}

def xf_moves_nb():
  {==}

law xf_moves_bp:
  {B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_bp{flat_bp()}) == G.GV_bp{G.Bp{fq(1.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(3.0f64, 0.0f64, 0.0f64), fq(4.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64), fq(2.0f64, 1.0f64, 0.0f64), fq(3.0f64, 1.0f64, 0.0f64), fq(4.0f64, 1.0f64, 0.0f64), fq(1.0f64, 2.0f64, 0.0f64), fq(2.0f64, 2.0f64, 0.0f64), fq(3.0f64, 2.0f64, 0.0f64), fq(4.0f64, 2.0f64, 0.0f64), fq(1.0f64, 3.0f64, 0.0f64), fq(2.0f64, 3.0f64, 0.0f64), fq(3.0f64, 3.0f64, 0.0f64), fq(4.0f64, 3.0f64, 0.0f64)}} : G.GVal}

def xf_moves_bp():
  {==}

# --- Adversarial-fix pins (F12 deleted lineage) ---
law del_classified_empty:
  {B8.del_classified([]) == [] : List<&2, B8.Del>}

def del_classified_empty():
  {==}

law del_classified_one:
  {B8.del_classified([BD.Fn{1u64, 0n, 0u64, 0n, 0n}]) == [B8.Del{BD.Fn{1u64, 0n, 0u64, 0n, 0n}, 0u64}] : List<&2, B8.Del>}

def del_classified_one():
  {==}

def face_del() -> B8.Del:
  B8.Del{BD.Fn{1u64, 0n, 0u64, 0n, 0n}, 0u64}

law same_carry_not_classified:
  {B8.carry_dels(True{}, [face_del()]) == [] : List<&2, B8.Del>}

def same_carry_not_classified():
  {==}

law same_diff_lists_once:
  {B8.empty_dels(True{}, [face_del()], [face_del()]) == [face_del()] : List<&2, B8.Del>}

def same_diff_lists_once():
  {==}

law other_carry_classified:
  {B8.carry_dels(False{}, [face_del()]) == [face_del()] : List<&2, B8.Del>}

def other_carry_classified():
  {==}

law other_empty_lists_both:
  {B8.empty_dels(False{}, [face_del()], [face_del()]) == [face_del(), face_del()] : List<&2, B8.Del>}

def other_empty_lists_both():
  {==}

law del_why_words:
  {Bool.and(String.eq(B8.del_why_s(0u64), "classified-away"), Bool.and(String.eq(B8.del_why_s(1u64), "regularized-away"), String.eq(B8.del_why_s(2u64), "merged"))) == True{} : Bool}

def del_why_words():
  {==}

law del_show_created:
  {B8.del_show(B8.Del{BD.Fn{4u64, 0n, 4u64, 0n, 0n}, 0u64}) == "n4.cav.0.0.0 classified-away" : String}

def del_show_created():
  {==}

law out_del_empty_default:
  {B8.Out_del(B8.out_empty(9u64, "", [])) == [] : List<&2, B8.Del>}

def out_del_empty_default():
  {==}

law out_del_fail_default:
  {B8.Out_del(B8.out_fail(1u64, "w", "l", "y", "f")) == [] : List<&2, B8.Del>}

def out_del_fail_default():
  {==}

law out_proof_plumbing:
  {B8.Out_proof(B8.out_empty(9u64, "p", [])) == "p" : String}

def out_proof_plumbing():
  {==}

# --- Adversarial-fix pins (F13 lineage rendering) ---
law fn_show_created_role:
  {B8.fn_show(BD.Fn{4u64, 2n, 4u64, 3n, 1n}) == "n4.cav.2.3.1" : String}

def fn_show_created_role():
  {==}

# --- Adversarial-fix pins (F15 disjoint proof) ---
# The proof string renders boxes via F64.show, which the checker does not
# evaluate, so no closed law can pin its content: `disjoint.proof` in
# tests/c08/e2e.py asserts `disjoint-boxes` presence at runtime, and
# `out_proof_plumbing` above pins the Out plumbing.
law disjoint_proof_empty_default:
  {B8.Out_proof(B8.out_fail(1u64, "w", "l", "y", "f")) == "" : String}

def disjoint_proof_empty_default():
  {==}

# --- Adversarial-fix pins (F23 boolean-origin flag) ---
law model_xb_pr_default:
  {M.xb_pr(M.Xb{[mval()], 1n, True{}, "p", []}) == "p" : String}

def model_xb_pr_default():
  {==}

law model_xb_dl_default:
  {M.xb_dl(M.Xb{[mval()], 1n, True{}, "", []}) == [] : List<&2, B8.Del>}

def model_xb_dl_default():
  {==}

law model_bool_body_origin:
  {M.xb_bo(M.bd_xb(M.bool_body(B8.out_empty(9u64, "", [])))) == True{} : Bool}

def model_bool_body_origin():
  {==}

law model_ck_go_origin:
  {M.bd_xb(M.nr_body(M.ck_go(True{}, Ty.brep_empty(), [], [], M.pl_id(), "", []))) == M.xb_id() : M.Xb}

def model_ck_go_origin():
  {==}

law model_carry_keeps_plain:
  {M.xb_bo(M.bd_xb(M.bool_carry(B8.out_carry_direct(in0(), 1u64, "", []), bd0(),
    M.bool_body(B8.out_empty(9u64, "", []))))) == False{} : Bool}

def model_carry_keeps_plain():
  {==}

law model_carry_keeps_assembled:
  {M.xb_bo(M.bd_xb(M.bool_carry(B8.out_carry_direct(in0(), 2u64, "", []), bd0(),
    M.bool_body(B8.out_empty(9u64, "", []))))) == True{} : Bool}

def model_carry_keeps_assembled():
  {==}

law model_bool_body_proof:
  {M.xb_pr(M.bd_xb(M.bool_body(B8.out_empty(9u64, "p", [])))) == "p" : String}

def model_bool_body_proof():
  {==}

# --- Adversarial-fix pins (F24 total sampling) ---
law lp_v0_empty_is_none:
  {B8.lp_v0(Ty.brep_empty(), []) == None{} : Maybe<&2, V.Point>}

def lp_v0_empty_is_none():
  {==}

law fa_v0_empty_is_none:
  {B8.fa_v0(Ty.brep_empty(), []) == None{} : Maybe<&2, V.Point>}

def fa_v0_empty_is_none():
  {==}

law face_pts_skips_loopless:
  {B8.face_pts(Ty.brep_empty(), [Ty.HF{0n, 0u64}]) == [] : List<&2, V.Point>}

def face_pts_skips_loopless():
  {==}

# --- New-accessor reads ---
law in_lin_reads:
  {B8.in_lin(in0()) == 0.5f64 : F64}

def in_lin_reads():
  {==}

law in_px_reads:
  {B8.in_px(in0()) == True{} : Bool}

def in_px_reads():
  {==}

law in_fns_reads:
  {B8.in_fns(in0()) == [] : List<&2, BD.Fn>}

def in_fns_reads():
  {==}

# --- Adversarial-fix pins (seam-vertex sampling soundness) ---
# Loop-first-vertex sampling strands solids whose sampled vertices
# share a small patch (tangent-cylinder L9 violation, 1e-6-overlap
# silent carry). Every admitted edge also contributes its parametric
# midpoint. Computed midpoints widen by interval rounding, so the
# Some-arm laws pin arity (exactly one sample per admitted edge
# curve), not coordinates; coordinates are pinned on hand-built
# boxes, and spanning is pinned by the E2E tangent/micro-overlap
# journeys.
law mid_pt_exact:
  {B8.mid_pt([I.ipt(0.0f64), I.ipt(2.0f64), I.ipt(4.0f64)]) == V.Pt{0.0f64, 2.0f64, 4.0f64} : V.Point}

def mid_pt_exact():
  {==}

law cv_mid_none:
  {B8.cv_mid(None{}) == None{} : Maybe<&2, V.Point>}

def cv_mid_none():
  {==}

law ed_mid_degenerate_none:
  {B8.ed_mid(Ty.EK_degenerate{}) == None{} : Maybe<&2, V.Point>}

def ed_mid_degenerate_none():
  {==}

law ed_mid_uncurved_none:
  {B8.ed_mid(Ty.EK_curve{G.GV_f{0.0f64}, dom01()}) == None{} : Maybe<&2, V.Point>}

def ed_mid_uncurved_none():
  {==}

law ed_mid_line_one:
  {List.length(&2, V.Point, B8.mid_cons(B8.ed_mid(Ty.EK_curve{G.GV_ln{G.Ln{pt0(), dx()}}, dom01()}), [])) == 1n : Nat}

def ed_mid_line_one():
  {==}

law ed_mid_cubic_one:
  {List.length(&2, V.Point, B8.mid_cons(B8.ed_mid(Ty.EK_curve{G.GV_bz{G.Bz{pt0(), ptx(), pty(), pt0()}}, dom01()}), [])) == 1n : Nat}

def ed_mid_cubic_one():
  {==}

law ed_mid_circle_one:
  {List.length(&2, V.Point, B8.mid_cons(B8.ed_mid(Ty.EK_curve{G.GV_cc{G.Cc{pt0(), dx(), dy(), 1.0f64}}, dom01()}), [])) == 1n : Nat}

def ed_mid_circle_one():
  {==}

law ed_mid_rational_one:
  {List.length(&2, V.Point, B8.mid_cons(B8.ed_mid(Ty.EK_curve{G.GV_rq{G.Rq{pt0(), ptx(), pty(), 1.0f64, 1.0f64, 1.0f64}}, dom01()}), [])) == 1n : Nat}

def ed_mid_rational_one():
  {==}

law mid_cons_none:
  {B8.mid_cons(None{}, [pt0()]) == [pt0()] : List<&2, V.Point>}

def mid_cons_none():
  {==}

law mid_cons_some:
  {B8.mid_cons(Some{ptx()}, [pt0()]) == [ptx(), pt0()] : List<&2, V.Point>}

def mid_cons_some():
  {==}

law lp_mids_empty:
  {B8.lp_mids(Ty.brep_empty(), []) == [] : List<&2, V.Point>}

def lp_mids_empty():
  {==}

law fa_mids_empty:
  {B8.fa_mids(Ty.brep_empty(), []) == [] : List<&2, V.Point>}

def fa_mids_empty():
  {==}
