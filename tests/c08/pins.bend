import Base

import ../../src/c00/types.bend as T

import ../../src/c01/types.bend as V

import ../../src/c03/types.bend as G

import ../../src/c04/types.bend as Ty

import ../../src/c06/iv.bend as I

import ../../src/c06/build.bend as BD

import ../../src/c06/model.bend as M

import ../../src/c06/sx.bend as S

import ../../src/c07/xs.bend as XS

import ../../src/c07/sol.bend as SO

import ../../src/c07/emb.bend as EM

import ../../src/c08/bool.bend as B8

import ../../src/base/ex.bend as E

import ../../src/base/par.bend as P

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

def flat_bp() -> G.BezP:
  G.Bp{fq(0.0f64, 0.0f64, 0.0f64), fq(1.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(3.0f64, 0.0f64, 0.0f64),
    fq(0.0f64, 1.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64), fq(2.0f64, 1.0f64, 0.0f64), fq(3.0f64, 1.0f64, 0.0f64),
    fq(0.0f64, 2.0f64, 0.0f64), fq(1.0f64, 2.0f64, 0.0f64), fq(2.0f64, 2.0f64, 0.0f64), fq(3.0f64, 2.0f64, 0.0f64),
    fq(0.0f64, 3.0f64, 0.0f64), fq(1.0f64, 3.0f64, 0.0f64), fq(2.0f64, 3.0f64, 0.0f64), fq(3.0f64, 3.0f64, 0.0f64)}

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

def flat_line() -> G.GVal:
  G.GV_ln{G.Ln{fq(1.0f64, 1.0f64, F64.neg(1.0f64)), V.Dr{0.0f64, 0.0f64, 1.0f64}}}

def egd() -> EM.Eg:
  EM.Eg{[], G.Dom{0.0f64, 1.0f64}, 0n, 0n, [], [], EM.cv0(), [], 1u64, 0n}

def bp_z_sign(m: Maybe<&2, XS.E3>) -> P.Sgn:
  match m:
    case None{}: P.Sz{}
    case Some{n}: E.ex_sign(XS.e3_z(n))

def d2_degen_net() -> List<&2, V.Point>:
  [fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64)]

def face_del() -> B8.Del:
  B8.Del{BD.Fn{1u64, 0n, 0u64, 0n, 0n}, 0u64}

def tag_union_is_14__got() -> U64:
  B8.tag_union()

def tag_union_is_14__want() -> U64:
  14u64

def tag_diff_is_15__got() -> U64:
  B8.tag_diff()

def tag_diff_is_15__want() -> U64:
  15u64

def tag_inter_is_16__got() -> U64:
  B8.tag_inter()

def tag_inter_is_16__want() -> U64:
  16u64

def fc_codes__got() -> U64:
  B8.fc_out()

def fc_codes__want() -> U64:
  0u64

def fc_in_is_1__got() -> U64:
  B8.fc_in()

def fc_in_is_1__want() -> U64:
  1u64

def fc_same_is_2__got() -> U64:
  B8.fc_same()

def fc_same_is_2__want() -> U64:
  2u64

def fc_opp_is_3__got() -> U64:
  B8.fc_opp()

def fc_opp_is_3__want() -> U64:
  3u64

def fc_unc_is_4__got() -> U64:
  B8.fc_unc()

def fc_unc_is_4__want() -> U64:
  4u64

def agg_in_is_1__got() -> U64:
  B8.agg_in()

def agg_in_is_1__want() -> U64:
  1u64

def agg_out_is_2__got() -> U64:
  B8.agg_out()

def agg_out_is_2__want() -> U64:
  2u64

def dec_sep_is_0__got() -> U64:
  B8.dec_sep()

def dec_sep_is_0__want() -> U64:
  0u64

def dec_ainb_is_1__got() -> U64:
  B8.dec_ainb()

def dec_ainb_is_1__want() -> U64:
  1u64

def dec_bina_is_2__got() -> U64:
  B8.dec_bina()

def dec_bina_is_2__want() -> U64:
  2u64

def fk_invalid_is_0__got() -> U64:
  B8.fk_invalid()

def fk_invalid_is_0__want() -> U64:
  0u64

def fk_uncertain_is_1__got() -> U64:
  B8.fk_uncertain()

def fk_uncertain_is_1__want() -> U64:
  1u64

def fk_unsupported_is_2__got() -> U64:
  B8.fk_unsupported()

def fk_unsupported_is_2__want() -> U64:
  2u64

def role_created_is_4__got() -> U64:
  B8.role_created()

def role_created_is_4__want() -> U64:
  4u64

def op_name_union__got() -> String:
  B8.op_name(14u64)

def op_name_union__want() -> String:
  "union"

def op_name_diff__got() -> String:
  B8.op_name(15u64)

def op_name_diff__want() -> String:
  "difference"

def op_name_inter__got() -> String:
  B8.op_name(16u64)

def op_name_inter__want() -> String:
  "intersection"

def op_name_other_is_inter__got() -> String:
  B8.op_name(99u64)

def op_name_other_is_inter__want() -> String:
  "intersection"

def is_bool_op_union__got() -> Bool:
  B8.is_bool_op(14u64)

def is_bool_op_union__want() -> Bool:
  True{}

def is_bool_op_diff__got() -> Bool:
  B8.is_bool_op(15u64)

def is_bool_op_diff__want() -> Bool:
  True{}

def is_bool_op_inter__got() -> Bool:
  B8.is_bool_op(16u64)

def is_bool_op_inter__want() -> Bool:
  True{}

def is_bool_op_other__got() -> Bool:
  B8.is_bool_op(13u64)

def is_bool_op_other__want() -> Bool:
  False{}

def op_carry_nm_a__got() -> String:
  B8.op_carry_nm(1u64)

def op_carry_nm_a__want() -> String:
  "carry-A"

def op_carry_nm_b__got() -> String:
  B8.op_carry_nm(2u64)

def op_carry_nm_b__want() -> String:
  "carry-B"

def op_carry_nm_other_is_b__got() -> String:
  B8.op_carry_nm(7u64)

def op_carry_nm_other_is_b__want() -> String:
  "carry-B"

def keep_union_out__got() -> U64:
  B8.keep_frag(14u64, 0u64)

def keep_union_out__want() -> U64:
  1u64

def keep_union_in__got() -> U64:
  B8.keep_frag(14u64, 1u64)

def keep_union_in__want() -> U64:
  0u64

def keep_union_same__got() -> U64:
  B8.keep_frag(14u64, 2u64)

def keep_union_same__want() -> U64:
  1u64

def keep_union_opp__got() -> U64:
  B8.keep_frag(14u64, 3u64)

def keep_union_opp__want() -> U64:
  0u64

def keep_union_unc__got() -> U64:
  B8.keep_frag(14u64, 4u64)

def keep_union_unc__want() -> U64:
  2u64

def keep_diff_out__got() -> U64:
  B8.keep_frag(15u64, 0u64)

def keep_diff_out__want() -> U64:
  1u64

def keep_diff_in__got() -> U64:
  B8.keep_frag(15u64, 1u64)

def keep_diff_in__want() -> U64:
  0u64

def keep_diff_same__got() -> U64:
  B8.keep_frag(15u64, 2u64)

def keep_diff_same__want() -> U64:
  0u64

def keep_diff_opp__got() -> U64:
  B8.keep_frag(15u64, 3u64)

def keep_diff_opp__want() -> U64:
  1u64

def keep_diff_unc__got() -> U64:
  B8.keep_frag(15u64, 4u64)

def keep_diff_unc__want() -> U64:
  2u64

def keep_inter_out__got() -> U64:
  B8.keep_frag(16u64, 0u64)

def keep_inter_out__want() -> U64:
  0u64

def keep_inter_in__got() -> U64:
  B8.keep_frag(16u64, 1u64)

def keep_inter_in__want() -> U64:
  1u64

def keep_inter_same__got() -> U64:
  B8.keep_frag(16u64, 2u64)

def keep_inter_same__want() -> U64:
  1u64

def keep_inter_opp__got() -> U64:
  B8.keep_frag(16u64, 3u64)

def keep_inter_opp__want() -> U64:
  0u64

def keep_inter_unc__got() -> U64:
  B8.keep_frag(16u64, 4u64)

def keep_inter_unc__want() -> U64:
  2u64

def keep_other_op_is_inter__got() -> U64:
  B8.keep_frag(99u64, 1u64)

def keep_other_op_is_inter__want() -> U64:
  1u64

def agg_of_mixed__got() -> U64:
  B8.agg_of(True{}, True{}, False{})

def agg_of_mixed__want() -> U64:
  3u64

def agg_of_in__got() -> U64:
  B8.agg_of(True{}, False{}, True{})

def agg_of_in__want() -> U64:
  1u64

def agg_of_out__got() -> U64:
  B8.agg_of(False{}, True{}, True{})

def agg_of_out__want() -> U64:
  2u64

def agg_of_boundary__got() -> U64:
  B8.agg_of(False{}, False{}, True{})

def agg_of_boundary__want() -> U64:
  0u64

def agg_of_unsampled__got() -> U64:
  B8.agg_of(False{}, False{}, False{})

def agg_of_unsampled__want() -> U64:
  0u64

def agg_ok_in__got() -> Bool:
  B8.agg_ok(1u64)

def agg_ok_in__want() -> Bool:
  True{}

def agg_ok_out__got() -> Bool:
  B8.agg_ok(2u64)

def agg_ok_out__want() -> Bool:
  True{}

def agg_ok_boundary__got() -> Bool:
  B8.agg_ok(0u64)

def agg_ok_boundary__want() -> Bool:
  False{}

def agg_ok_mixed__got() -> Bool:
  B8.agg_ok(3u64)

def agg_ok_mixed__want() -> Bool:
  False{}

def agg_code_in__got() -> U64:
  B8.agg_code(1u64)

def agg_code_in__want() -> U64:
  1u64

def agg_code_out__got() -> U64:
  B8.agg_code(2u64)

def agg_code_out__want() -> U64:
  0u64

def agg_code_other_is_out__got() -> U64:
  B8.agg_code(0u64)

def agg_code_other_is_out__want() -> U64:
  0u64

def dec_aggA_ainb__got() -> U64:
  B8.dec_aggA(1u64)

def dec_aggA_ainb__want() -> U64:
  1u64

def dec_aggA_other_is_out__got() -> U64:
  B8.dec_aggA(2u64)

def dec_aggA_other_is_out__want() -> U64:
  2u64

def dec_aggB_bina__got() -> U64:
  B8.dec_aggB(2u64)

def dec_aggB_bina__want() -> U64:
  1u64

def dec_aggB_other_is_out__got() -> U64:
  B8.dec_aggB(1u64)

def dec_aggB_other_is_out__want() -> U64:
  2u64

def decide_sep__got() -> U64:
  B8.decide(2u64, 2u64)

def decide_sep__want() -> U64:
  0u64

def decide_ainb__got() -> U64:
  B8.decide(1u64, 2u64)

def decide_ainb__want() -> U64:
  1u64

def decide_bina__got() -> U64:
  B8.decide(2u64, 1u64)

def decide_bina__want() -> U64:
  2u64

def decide_both_in_fails__got() -> U64:
  B8.decide(1u64, 1u64)

def decide_both_in_fails__want() -> U64:
  3u64

def decide_boundary_fails__got() -> U64:
  B8.decide(2u64, 0u64)

def decide_boundary_fails__want() -> U64:
  3u64

def outcome_union_sep__got() -> U64:
  B8.outcome(14u64, 0u64)

def outcome_union_sep__want() -> U64:
  2u64

def outcome_union_ainb__got() -> U64:
  B8.outcome(14u64, 1u64)

def outcome_union_ainb__want() -> U64:
  1u64

def outcome_union_bina__got() -> U64:
  B8.outcome(14u64, 2u64)

def outcome_union_bina__want() -> U64:
  0u64

def outcome_union_bad__got() -> U64:
  B8.outcome(14u64, 3u64)

def outcome_union_bad__want() -> U64:
  5u64

def outcome_diff_sep__got() -> U64:
  B8.outcome(15u64, 0u64)

def outcome_diff_sep__want() -> U64:
  0u64

def outcome_diff_ainb__got() -> U64:
  B8.outcome(15u64, 1u64)

def outcome_diff_ainb__want() -> U64:
  3u64

def outcome_diff_bina__got() -> U64:
  B8.outcome(15u64, 2u64)

def outcome_diff_bina__want() -> U64:
  4u64

def outcome_diff_bad__got() -> U64:
  B8.outcome(15u64, 3u64)

def outcome_diff_bad__want() -> U64:
  5u64

def outcome_inter_sep__got() -> U64:
  B8.outcome(16u64, 0u64)

def outcome_inter_sep__want() -> U64:
  3u64

def outcome_inter_ainb__got() -> U64:
  B8.outcome(16u64, 1u64)

def outcome_inter_ainb__want() -> U64:
  0u64

def outcome_inter_bina__got() -> U64:
  B8.outcome(16u64, 2u64)

def outcome_inter_bina__want() -> U64:
  1u64

def outcome_inter_bad__got() -> U64:
  B8.outcome(16u64, 3u64)

def outcome_inter_bad__want() -> U64:
  5u64

def empty_union_both_empty__got() -> U64:
  B8.empty_outcome(14u64, True{}, True{}, False{})

def empty_union_both_empty__want() -> U64:
  3u64

def empty_union_a_empty__got() -> U64:
  B8.empty_outcome(14u64, True{}, False{}, False{})

def empty_union_a_empty__want() -> U64:
  1u64

def empty_union_b_empty__got() -> U64:
  B8.empty_outcome(14u64, False{}, True{}, False{})

def empty_union_b_empty__want() -> U64:
  0u64

def empty_union_full__got() -> U64:
  B8.empty_outcome(14u64, False{}, False{}, False{})

def empty_union_full__want() -> U64:
  10u64

def empty_union_identical__got() -> U64:
  B8.empty_outcome(14u64, False{}, False{}, True{})

def empty_union_identical__want() -> U64:
  0u64

def empty_union_a_empty_identical__got() -> U64:
  B8.empty_outcome(14u64, True{}, False{}, True{})

def empty_union_a_empty_identical__want() -> U64:
  0u64

def empty_union_b_empty_identical__got() -> U64:
  B8.empty_outcome(14u64, False{}, True{}, True{})

def empty_union_b_empty_identical__want() -> U64:
  0u64

def empty_diff_both_empty__got() -> U64:
  B8.empty_outcome(15u64, True{}, True{}, False{})

def empty_diff_both_empty__want() -> U64:
  3u64

def empty_diff_a_empty__got() -> U64:
  B8.empty_outcome(15u64, True{}, False{}, False{})

def empty_diff_a_empty__want() -> U64:
  3u64

def empty_diff_b_empty__got() -> U64:
  B8.empty_outcome(15u64, False{}, True{}, False{})

def empty_diff_b_empty__want() -> U64:
  0u64

def empty_diff_full__got() -> U64:
  B8.empty_outcome(15u64, False{}, False{}, False{})

def empty_diff_full__want() -> U64:
  10u64

def empty_diff_identical__got() -> U64:
  B8.empty_outcome(15u64, False{}, False{}, True{})

def empty_diff_identical__want() -> U64:
  3u64

def empty_diff_a_empty_identical__got() -> U64:
  B8.empty_outcome(15u64, True{}, False{}, True{})

def empty_diff_a_empty_identical__want() -> U64:
  3u64

def empty_diff_b_empty_identical__got() -> U64:
  B8.empty_outcome(15u64, False{}, True{}, True{})

def empty_diff_b_empty_identical__want() -> U64:
  3u64

def empty_inter_both_empty__got() -> U64:
  B8.empty_outcome(16u64, True{}, True{}, False{})

def empty_inter_both_empty__want() -> U64:
  3u64

def empty_inter_a_empty__got() -> U64:
  B8.empty_outcome(16u64, True{}, False{}, False{})

def empty_inter_a_empty__want() -> U64:
  3u64

def empty_inter_b_empty__got() -> U64:
  B8.empty_outcome(16u64, False{}, True{}, False{})

def empty_inter_b_empty__want() -> U64:
  3u64

def empty_inter_full__got() -> U64:
  B8.empty_outcome(16u64, False{}, False{}, False{})

def empty_inter_full__want() -> U64:
  10u64

def empty_inter_identical__got() -> U64:
  B8.empty_outcome(16u64, False{}, False{}, True{})

def empty_inter_identical__want() -> U64:
  0u64

def empty_inter_a_empty_identical__got() -> U64:
  B8.empty_outcome(16u64, True{}, False{}, True{})

def empty_inter_a_empty_identical__want() -> U64:
  0u64

def empty_inter_b_empty_identical__got() -> U64:
  B8.empty_outcome(16u64, False{}, True{}, True{})

def empty_inter_b_empty_identical__want() -> U64:
  0u64

def mat_union_append_grows__got() -> U64:
  B8.bool_mat(14u64, 2u64, I.I{1.0f64, 1.0f64}, I.I{2.0f64, 2.0f64}, 0u64)

def mat_union_append_grows__want() -> U64:
  1u64

def mat_union_append_flat_is_unknown__got() -> U64:
  B8.bool_mat(14u64, 2u64, I.I{0.0f64, 0.0f64}, I.I{2.0f64, 2.0f64}, 0u64)

def mat_union_append_flat_is_unknown__want() -> U64:
  4u64

def mat_diff_cavity_shrinks__got() -> U64:
  B8.bool_mat(15u64, 4u64, I.I{8.0f64, 8.0f64}, I.I{1.0f64, 1.0f64}, 1u64)

def mat_diff_cavity_shrinks__want() -> U64:
  2u64

def mat_diff_cavity_flat_tool_is_unknown__got() -> U64:
  B8.bool_mat(15u64, 4u64, I.I{8.0f64, 8.0f64}, I.I{0.0f64, 0.0f64}, 1u64)

def mat_diff_cavity_flat_tool_is_unknown__want() -> U64:
  4u64

def mat_diff_cavity_reads_tool_side__got() -> U64:
  B8.bool_mat(15u64, 4u64, I.I{0.0f64, 0.0f64}, I.I{1.0f64, 1.0f64}, 0u64)

def mat_diff_cavity_reads_tool_side__want() -> U64:
  4u64

def mat_carry_a_is_same__got() -> U64:
  B8.bool_mat(14u64, 0u64, I.I{1.0f64, 1.0f64}, I.I{1.0f64, 1.0f64}, 0u64)

def mat_carry_a_is_same__want() -> U64:
  3u64

def mat_carry_b_is_same__got() -> U64:
  B8.bool_mat(16u64, 1u64, I.I{1.0f64, 1.0f64}, I.I{1.0f64, 1.0f64}, 0u64)

def mat_carry_b_is_same__want() -> U64:
  3u64

def mat_empty_is_same__got() -> U64:
  B8.bool_mat(16u64, 3u64, I.I{1.0f64, 1.0f64}, I.I{1.0f64, 1.0f64}, 0u64)

def mat_empty_is_same__want() -> U64:
  3u64

def mat_inter_append_is_unknown__got() -> U64:
  B8.bool_mat(16u64, 2u64, I.I{1.0f64, 1.0f64}, I.I{1.0f64, 1.0f64}, 0u64)

def mat_inter_append_is_unknown__want() -> U64:
  4u64

def mat_union_cavity_is_unknown__got() -> U64:
  B8.bool_mat(14u64, 4u64, I.I{1.0f64, 1.0f64}, I.I{1.0f64, 1.0f64}, 0u64)

def mat_union_cavity_is_unknown__want() -> U64:
  4u64

def pos_vol_strict__got() -> Bool:
  B8.pos_vol(I.I{1.0f64, 2.0f64})

def pos_vol_strict__want() -> Bool:
  True{}

def pos_vol_touching_zero__got() -> Bool:
  B8.pos_vol(I.I{0.0f64, 0.0f64})

def pos_vol_touching_zero__want() -> Bool:
  False{}

def pos_vol_straddling_zero__got() -> Bool:
  B8.pos_vol(I.I{F64.neg(1.0f64), 1.0f64})

def pos_vol_straddling_zero__want() -> Bool:
  False{}

def contact_edge_edge__got() -> Bool:
  B8.is_contact("contact-edge-edge")

def contact_edge_edge__want() -> Bool:
  True{}

def contact_edge_face__got() -> Bool:
  B8.is_contact("contact-edge-face")

def contact_edge_face__want() -> Bool:
  True{}

def contact_face_face__got() -> Bool:
  B8.is_contact("contact-face-face")

def contact_face_face__want() -> Bool:
  True{}

def contact_fail_closed__got() -> Bool:
  B8.is_contact("edge-crossing")

def contact_fail_closed__want() -> Bool:
  False{}

def unc_edge_crossing__got() -> Bool:
  B8.is_uncertain_code("edge-crossing-uncertain")

def unc_edge_crossing__want() -> Bool:
  True{}

def unc_edge_face__got() -> Bool:
  B8.is_uncertain_code("edge-face-uncertain")

def unc_edge_face__want() -> Bool:
  True{}

def unc_face_face__got() -> Bool:
  B8.is_uncertain_code("face-face-uncertain")

def unc_face_face__want() -> Bool:
  True{}

def unc_face_overlap__got() -> Bool:
  B8.is_uncertain_code("face-overlap-uncertain")

def unc_face_overlap__want() -> Bool:
  True{}

def unc_orientation__got() -> Bool:
  B8.is_uncertain_code("orientation-uncertain")

def unc_orientation__want() -> Bool:
  True{}

def unc_nesting__got() -> Bool:
  B8.is_uncertain_code("nesting-uncertain")

def unc_nesting__want() -> Bool:
  True{}

def unc_fail_closed__got() -> Bool:
  B8.is_uncertain_code("edge-crossing")

def unc_fail_closed__want() -> Bool:
  False{}

def unsup_edge__got() -> Bool:
  B8.is_unsupported_code("edge-check-unsupported")

def unsup_edge__want() -> Bool:
  True{}

def unsup_face__got() -> Bool:
  B8.is_unsupported_code("face-check-unsupported")

def unsup_face__want() -> Bool:
  True{}

def unsup_edge_face__got() -> Bool:
  B8.is_unsupported_code("edge-face-unsupported")

def unsup_edge_face__want() -> Bool:
  True{}

def unsup_fail_closed__got() -> Bool:
  B8.is_unsupported_code("face-overlap")

def unsup_fail_closed__want() -> Bool:
  False{}

def stage_incidence__got() -> String:
  B8.stage_why(2u64)

def stage_incidence__want() -> String:
  "incidence"

def stage_edge_use__got() -> String:
  B8.stage_why(3u64)

def stage_edge_use__want() -> String:
  "edge-use"

def stage_loop__got() -> String:
  B8.stage_why(4u64)

def stage_loop__want() -> String:
  "loop-closure-or-trim"

def stage_face_kind__got() -> String:
  B8.stage_why(5u64)

def stage_face_kind__want() -> String:
  "face-kind"

def stage_ownership__got() -> String:
  B8.stage_why(6u64)

def stage_ownership__want() -> String:
  "ownership"

def stage_embedding__got() -> String:
  B8.stage_why(7u64)

def stage_embedding__want() -> String:
  "embedding"

def stage_vertex_link__got() -> String:
  B8.stage_why(8u64)

def stage_vertex_link__want() -> String:
  "vertex-link"

def stage_shell__got() -> String:
  B8.stage_why(9u64)

def stage_shell__want() -> String:
  "shell-connectivity"

def stage_coin__got() -> String:
  B8.stage_why(10u64)

def stage_coin__want() -> String:
  "coincident-vertices"

def stage_crossing__got() -> String:
  B8.stage_why(11u64)

def stage_crossing__want() -> String:
  "segment-crossing"

def stage_orientation__got() -> String:
  B8.stage_why(12u64)

def stage_orientation__want() -> String:
  "orientation"

def stage_unknown__got() -> String:
  B8.stage_why(99u64)

def stage_unknown__want() -> String:
  "stage-unknown"

def admit_open_a_first__got() -> U64:
  B8.admit_code(True{}, True{}, 1u64, 1u64, 1u64, 1u64, True{}, True{})

def admit_open_a_first__want() -> U64:
  1u64

def admit_open_b__got() -> U64:
  B8.admit_code(False{}, True{}, 0u64, 0u64, 0u64, 0u64, True{}, True{})

def admit_open_b__want() -> U64:
  2u64

def admit_face_a__got() -> U64:
  B8.admit_code(False{}, False{}, 1u64, 0u64, 0u64, 0u64, True{}, True{})

def admit_face_a__want() -> U64:
  3u64

def admit_face_b__got() -> U64:
  B8.admit_code(False{}, False{}, 0u64, 2u64, 0u64, 0u64, True{}, True{})

def admit_face_b__want() -> U64:
  4u64

def admit_edge_a__got() -> U64:
  B8.admit_code(False{}, False{}, 0u64, 0u64, 1u64, 0u64, True{}, True{})

def admit_edge_a__want() -> U64:
  5u64

def admit_edge_b__got() -> U64:
  B8.admit_code(False{}, False{}, 0u64, 0u64, 0u64, 1u64, True{}, True{})

def admit_edge_b__want() -> U64:
  6u64

def admit_clean__got() -> U64:
  B8.admit_code(False{}, False{}, 0u64, 0u64, 0u64, 0u64, True{}, True{})

def admit_clean__want() -> U64:
  0u64

def shell_open_is_open__got() -> Bool:
  B8.shell_open(Ty.SK_open{})

def shell_open_is_open__want() -> Bool:
  True{}

def shell_open_outer__got() -> Bool:
  B8.shell_open(Ty.SK_outer{})

def shell_open_outer__want() -> Bool:
  False{}

def shell_open_inner__got() -> Bool:
  B8.shell_open(Ty.SK_inner{})

def shell_open_inner__want() -> Bool:
  False{}

def admit_shs_empty__got() -> Bool:
  B8.admit_shs([])

def admit_shs_empty__want() -> Bool:
  False{}

def admit_shs_closed__got() -> Bool:
  B8.admit_shs([Ty.Sh{0u64, [], Ty.SK_outer{}}])

def admit_shs_closed__want() -> Bool:
  False{}

def admit_shs_open__got() -> Bool:
  B8.admit_shs([Ty.Sh{0u64, [], Ty.SK_open{}}])

def admit_shs_open__want() -> Bool:
  True{}

def admit_shs_mixed__got() -> Bool:
  B8.admit_shs([Ty.Sh{0u64, [], Ty.SK_outer{}}, Ty.Sh{0u64, [], Ty.SK_open{}}])

def admit_shs_mixed__want() -> Bool:
  True{}

def edge_code_degenerate__got() -> U64:
  B8.edge_code(Ty.EK_degenerate{})

def edge_code_degenerate__want() -> U64:
  0u64

def edge_code_line__got() -> U64:
  B8.edge_code(Ty.EK_curve{G.GV_ln{G.Ln{pt0(), dx()}}, dom01()})

def edge_code_line__want() -> U64:
  0u64

def edge_code_cubic__got() -> U64:
  B8.edge_code(Ty.EK_curve{G.GV_bz{G.Bz{pt0(), ptx(), pty(), pt0()}}, dom01()})

def edge_code_cubic__want() -> U64:
  0u64

def edge_code_circle__got() -> U64:
  B8.edge_code(Ty.EK_curve{G.GV_cc{G.Cc{pt0(), dx(), dy(), 1.0f64}}, dom01()})

def edge_code_circle__want() -> U64:
  0u64

def edge_code_rational__got() -> U64:
  B8.edge_code(Ty.EK_curve{G.GV_rq{G.Rq{pt0(), ptx(), pty(), 1.0f64, 1.0f64, 1.0f64}}, dom01()})

def edge_code_rational__want() -> U64:
  0u64

def edge_code_other__got() -> U64:
  B8.edge_code(Ty.EK_curve{G.GV_f{0.0f64}, dom01()})

def edge_code_other__want() -> U64:
  1u64

def edge_code_plane__got() -> U64:
  B8.edge_code(Ty.EK_curve{G.GV_pl{G.Pl{pt0(), dx(), dy()}}, dom01()})

def edge_code_plane__want() -> U64:
  1u64

def admit_eds_empty__got() -> U64:
  B8.admit_eds([])

def admit_eds_empty__want() -> U64:
  0u64

def admit_eds_line__got() -> U64:
  B8.admit_eds([Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{1n, 0u64}, Ty.EK_curve{G.GV_ln{G.Ln{pt0(), dx()}}, dom01()}}])

def admit_eds_line__want() -> U64:
  0u64

def admit_eds_bad__got() -> U64:
  B8.admit_eds([Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{1n, 0u64}, Ty.EK_curve{G.GV_f{0.0f64}, dom01()}}])

def admit_eds_bad__want() -> U64:
  1u64

def admit_eds_at_empty__got() -> Nat:
  B8.admit_eds_at([], 0n)

def admit_eds_at_empty__want() -> Nat:
  0n

def admit_eds_at_second__got() -> Nat:
  B8.admit_eds_at([Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{1n, 0u64}, Ty.EK_degenerate{}}, Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{1n, 0u64}, Ty.EK_curve{G.GV_f{0.0f64}, dom01()}}], 0n)

def admit_eds_at_second__want() -> Nat:
  1n

def surf_why_bezier__got() -> String:
  B8.surf_why(1u64)

def surf_why_bezier__want() -> String:
  "bezier-patch-operand"

def surf_why_nurbs__got() -> String:
  B8.surf_why(2u64)

def surf_why_nurbs__want() -> String:
  "nurbs-operand"

def surf_why_other__got() -> String:
  B8.surf_why(3u64)

def surf_why_other__want() -> String:
  "face-kind-not-supported"

def surf_why_zero__got() -> String:
  B8.surf_why(0u64)

def surf_why_zero__want() -> String:
  "face-kind-not-supported"

def surf_admit_nb_nurbs__got() -> U64:
  B8.surf_admit_nb(G.GV_nb{G.Nb{[], [], []}})

def surf_admit_nb_nurbs__want() -> U64:
  2u64

def surf_admit_nb_other__got() -> U64:
  B8.surf_admit_nb(G.GV_f{0.0f64})

def surf_admit_nb_other__want() -> U64:
  3u64

def surf_admit_go_none__got() -> U64:
  B8.surf_admit_go(None{}, G.GV_nb{G.Nb{[], [], []}})

def surf_admit_go_none__want() -> U64:
  2u64

def surf_admit_plane__got() -> U64:
  B8.surf_admit(G.GV_pl{G.Pl{pt0(), dx(), dy()}})

def surf_admit_plane__want() -> U64:
  0u64

def admit_fas_empty__got() -> U64:
  B8.admit_fas([], 0n)

def admit_fas_empty__want() -> U64:
  0u64

def admit_fas_plane__got() -> U64:
  B8.admit_fas([Ty.Fa{0u64, G.GV_pl{G.Pl{pt0(), dx(), dy()}}, [], True{}}], 0n)

def admit_fas_plane__want() -> U64:
  0u64

def admit_fas_nurbs__got() -> U64:
  B8.admit_fas([Ty.Fa{0u64, G.GV_nb{G.Nb{[], [], []}}, [], True{}}], 0n)

def admit_fas_nurbs__want() -> U64:
  2u64

def admit_fas_at_second__got() -> Nat:
  B8.admit_fas_at([Ty.Fa{0u64, G.GV_pl{G.Pl{pt0(), dx(), dy()}}, [], True{}}, Ty.Fa{0u64, G.GV_nb{G.Nb{[], [], []}}, [], True{}}], 0n)

def admit_fas_at_second__want() -> Nat:
  1n

def d2_flat_patch_admitted__got() -> U64:
  B8.surf_admit(G.GV_bp{flat_bp()})

def d2_flat_patch_admitted__want() -> U64:
  0u64

def d2_curved_patch_refused__got() -> U64:
  B8.surf_admit(G.GV_bp{curved_bp()})

def d2_curved_patch_refused__want() -> U64:
  1u64

def d2_bp_kind_is_bezier__got() -> U64:
  B8.surf_admit_nb(G.GV_bp{curved_bp()})

def d2_bp_kind_is_bezier__want() -> U64:
  1u64

def flat_bp_line_on_plane__got() -> Bool:
  XS.ez(XS.ex_horner(XS.comp_go(XS.gv_xc(flat_line()), XS.gv_xs(G.GV_bp{flat_bp()})), 1.0f64))

def flat_bp_line_on_plane__want() -> Bool:
  True{}

def curved_bp_xs_none__got() -> Bool:
  XS.gv_xs_is(G.GV_bp{curved_bp()})

def curved_bp_xs_none__want() -> Bool:
  False{}

def fn_nd_reads__got() -> U64:
  B8.fn_nd(BD.Fn{9u64, 1n, 4u64, 2n, 3n})

def fn_nd_reads__want() -> U64:
  9u64

def fn_k_reads__got() -> Nat:
  B8.fn_k(BD.Fn{9u64, 1n, 4u64, 2n, 3n})

def fn_k_reads__want() -> Nat:
  1n

def fn_role_reads__got() -> U64:
  B8.fn_role(BD.Fn{9u64, 1n, 4u64, 2n, 3n})

def fn_role_reads__want() -> U64:
  4u64

def fn_i_reads__got() -> Nat:
  B8.fn_i(BD.Fn{9u64, 1n, 4u64, 2n, 3n})

def fn_i_reads__want() -> Nat:
  2n

def fn_j_reads__got() -> Nat:
  B8.fn_j(BD.Fn{9u64, 1n, 4u64, 2n, 3n})

def fn_j_reads__want() -> Nat:
  3n

def fn_created_words__got() -> BD.Fn:
  B8.fn_created(9u64, 1n, 2n, 1u64)

def fn_created_words__want() -> BD.Fn:
  BD.Fn{9u64, 1n, 4u64, 2n, 1n}

def fn_created_here_counts__got() -> Nat:
  B8.fn_created_here([BD.Fn{9u64, 0n, 4u64, 0n, 0n}, BD.Fn{9u64, 1n, 2u64, 0n, 0n}, BD.Fn{7u64, 0n, 4u64, 0n, 0n}], 9u64)

def fn_created_here_counts__want() -> Nat:
  1n

def fn_created_here_empty__got() -> Nat:
  B8.fn_created_here([], 9u64)

def fn_created_here_empty__want() -> Nat:
  0n

def fn_created_n_counts_role__got() -> Nat:
  B8.fn_created_n([BD.Fn{9u64, 0n, 4u64, 0n, 0n}, BD.Fn{9u64, 1n, 2u64, 0n, 0n}, BD.Fn{7u64, 0n, 4u64, 0n, 0n}])

def fn_created_n_counts_role__want() -> Nat:
  2n

def fn_full_eq_hit__got() -> Bool:
  B8.fn_full_eq(BD.Fn{9u64, 1n, 4u64, 2n, 3n}, 9u64, 1n, 4u64, 2n, 3n)

def fn_full_eq_hit__want() -> Bool:
  True{}

def fn_full_eq_miss__got() -> Bool:
  B8.fn_full_eq(BD.Fn{9u64, 1n, 4u64, 2n, 3n}, 9u64, 1n, 4u64, 2n, 4n)

def fn_full_eq_miss__want() -> Bool:
  False{}

def fn_pre_eq_hit__got() -> Bool:
  B8.fn_pre_eq(BD.Fn{9u64, 1n, 4u64, 2n, 3n}, 9u64, 1n, 4u64)

def fn_pre_eq_hit__want() -> Bool:
  True{}

def fn_pre_eq_miss__got() -> Bool:
  B8.fn_pre_eq(BD.Fn{9u64, 1n, 4u64, 2n, 3n}, 9u64, 2n, 4u64)

def fn_pre_eq_miss__want() -> Bool:
  False{}

def resolve_unique__got() -> B8.Rs:
  B8.resolve([BD.Fn{4u64, 0n, 4u64, 0n, 0n}], 4u64, 0n, 4u64, 0n, 0n, True{})

def resolve_unique__want() -> B8.Rs:
  B8.R_one{0n}

def resolve_second__got() -> B8.Rs:
  B8.resolve([BD.Fn{4u64, 1n, 4u64, 0n, 0n}, BD.Fn{4u64, 0n, 4u64, 0n, 0n}], 4u64, 0n, 4u64, 0n, 0n, True{})

def resolve_second__want() -> B8.Rs:
  B8.R_one{1n}

def resolve_missing__got() -> B8.Rs:
  B8.resolve([BD.Fn{4u64, 0n, 4u64, 0n, 0n}], 4u64, 0n, 4u64, 0n, 1n, True{})

def resolve_missing__want() -> B8.Rs:
  B8.R_miss{1n}

def resolve_empty_missing__got() -> B8.Rs:
  B8.resolve([], 4u64, 0n, 4u64, 0n, 0n, True{})

def resolve_empty_missing__want() -> B8.Rs:
  B8.R_miss{0n}

def resolve_ambiguous__got() -> B8.Rs:
  B8.resolve([BD.Fn{4u64, 0n, 4u64, 0n, 0n}, BD.Fn{4u64, 0n, 4u64, 0n, 0n}], 4u64, 0n, 4u64, 0n, 0n, True{})

def resolve_ambiguous__want() -> B8.Rs:
  B8.R_amb{[0n, 1n]}

def res_show_ambiguous__got() -> String:
  B8.res_show(B8.R_amb{[0n, 1n]}, [BD.Fn{4u64, 0n, 4u64, 0n, 0n}, BD.Fn{4u64, 0n, 4u64, 0n, 0n}])

def res_show_ambiguous__want() -> String:
  "ambiguous (2 faces match) n4.cav.0.0.0 n4.cav.0.0.0"

def resolve_set__got() -> B8.Rs:
  B8.resolve([BD.Fn{4u64, 1n, 4u64, 0n, 0n}, BD.Fn{4u64, 0n, 4u64, 0n, 0n}, BD.Fn{4u64, 0n, 4u64, 1n, 0n}], 4u64, 0n, 4u64, 0n, 0n, False{})

def resolve_set__want() -> B8.Rs:
  B8.R_set{[1n, 2n]}

def resolve_set_missing__got() -> B8.Rs:
  B8.resolve([BD.Fn{4u64, 1n, 4u64, 0n, 0n}], 4u64, 0n, 4u64, 0n, 0n, False{})

def resolve_set_missing__want() -> B8.Rs:
  B8.R_miss{1n}

def ag_agg_both__got() -> U64:
  B8.ag_agg(3u64)

def ag_agg_both__want() -> U64:
  3u64

def ag_agg_in__got() -> U64:
  B8.ag_agg(1u64)

def ag_agg_in__want() -> U64:
  1u64

def ag_agg_out__got() -> U64:
  B8.ag_agg(2u64)

def ag_agg_out__want() -> U64:
  2u64

def ag_agg_none__got() -> U64:
  B8.ag_agg(0u64)

def ag_agg_none__want() -> U64:
  0u64

def ag_agg_boundary_only__got() -> U64:
  B8.ag_agg(4u64)

def ag_agg_boundary_only__want() -> U64:
  0u64

def ag_agg_in_boundary__got() -> U64:
  B8.ag_agg(5u64)

def ag_agg_in_boundary__want() -> U64:
  1u64

def ag_agg_out_boundary__got() -> U64:
  B8.ag_agg(6u64)

def ag_agg_out_boundary__want() -> U64:
  2u64

def rel_list_empty__got() -> List<&2, U64>:
  B8.rel_list([])

def rel_list_empty__want() -> List<&2, U64>:
  []

def rel_list_maps__got() -> List<&2, U64>:
  B8.rel_list([1u64, 2u64, 3u64])

def rel_list_maps__want() -> List<&2, U64>:
  [1u64, 2u64, 3u64]

def rel_class_empty__got() -> U64:
  B8.rel_class([], 0n, 0n, 0n)

def rel_class_empty__want() -> U64:
  6u64

def rel_class_all_in__got() -> U64:
  B8.rel_class([1u64, 1u64], 0n, 0n, 0n)

def rel_class_all_in__want() -> U64:
  1u64

def rel_class_all_out__got() -> U64:
  B8.rel_class([2u64, 2u64], 0n, 0n, 0n)

def rel_class_all_out__want() -> U64:
  2u64

def rel_class_mixed__got() -> U64:
  B8.rel_class([1u64, 2u64], 0n, 0n, 0n)

def rel_class_mixed__want() -> U64:
  5u64

def rel_class_bad__got() -> U64:
  B8.rel_class([0u64], 0n, 0n, 0n)

def rel_class_bad__want() -> U64:
  6u64

def rel_class_agg_mixed__got() -> U64:
  B8.rel_class([3u64], 0n, 0n, 0n)

def rel_class_agg_mixed__want() -> U64:
  6u64

def n_has_hit__got() -> Bool:
  B8.n_has([1n, 2n], 2n)

def n_has_hit__want() -> Bool:
  True{}

def n_has_miss__got() -> Bool:
  B8.n_has([1n, 2n], 3n)

def n_has_miss__want() -> Bool:
  False{}

def n_has_empty__got() -> Bool:
  B8.n_has([], 5n)

def n_has_empty__want() -> Bool:
  False{}

def rel_has_hit__got() -> Bool:
  B8.rel_has([1u64, 3u64], 3u64)

def rel_has_hit__want() -> Bool:
  True{}

def rel_has_miss__got() -> Bool:
  B8.rel_has([1u64, 2u64], 3u64)

def rel_has_miss__want() -> Bool:
  False{}

def rel_why_mixed_is_crossing__got() -> String:
  B8.rel_why([3u64], [2u64])

def rel_why_mixed_is_crossing__want() -> String:
  "boundaries-cross-or-overlap: one solid samples strictly inside and outside the other"

def rel_why_contact__got() -> String:
  B8.rel_why([1u64], [2u64])

def rel_why_contact__want() -> String:
  "contact-not-certified"

def nth_nat_hit__got() -> Nat:
  B8.nth_nat([7n, 8n], 1n)

def nth_nat_hit__want() -> Nat:
  8n

def nth_nat_miss__got() -> Nat:
  B8.nth_nat([], 3n)

def nth_nat_miss__want() -> Nat:
  0n

def br_counts_empty__got() -> List<&2, Nat>:
  B8.br_counts(Ty.brep_empty())

def br_counts_empty__want() -> List<&2, Nat>:
  [0n, 0n, 0n, 0n, 0n, 0n]

def nsolids_empty__got() -> Nat:
  B8.nsolids(Ty.brep_empty())

def nsolids_empty__want() -> Nat:
  0n

def genus_empty__got() -> Nat:
  B8.genus_of(Ty.brep_empty())

def genus_empty__want() -> Nat:
  0n

def sh_ids_go__got() -> List<&2, Nat>:
  B8.sh_ids_go([Ty.HS{4n, 0u64}, Ty.HS{9n, 0u64}])

def sh_ids_go__want() -> List<&2, Nat>:
  [4n, 9n]

def sh_ids_go_empty__got() -> List<&2, Nat>:
  B8.sh_ids_go([])

def sh_ids_go_empty__want() -> List<&2, Nat>:
  []

def bx_zero_is_origin__got() -> B8.BX:
  B8.bx_zero()

def bx_zero_is_origin__want() -> B8.BX:
  B8.BX{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}

def bx_hull_grows__got() -> B8.BX:
  B8.bx_hull(B8.BX{0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64}, B8.BX{2.0f64, 3.0f64, 2.0f64, 3.0f64, 2.0f64, 3.0f64})

def bx_hull_grows__want() -> B8.BX:
  B8.BX{0.0f64, 3.0f64, 0.0f64, 3.0f64, 0.0f64, 3.0f64}

def bx_disjoint_far__got() -> Bool:
  B8.bx_disjoint(B8.BX{0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64}, B8.BX{2.0f64, 3.0f64, 2.0f64, 3.0f64, 2.0f64, 3.0f64})

def bx_disjoint_far__want() -> Bool:
  True{}

def bx_disjoint_overlap__got() -> Bool:
  B8.bx_disjoint(B8.BX{0.0f64, 2.0f64, 0.0f64, 2.0f64, 0.0f64, 2.0f64}, B8.BX{1.0f64, 3.0f64, 1.0f64, 3.0f64, 1.0f64, 3.0f64})

def bx_disjoint_overlap__want() -> Bool:
  False{}

def bx_disjoint_touching_is_not_disjoint__got() -> Bool:
  B8.bx_disjoint(B8.BX{0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64}, B8.BX{1.0f64, 2.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64})

def bx_disjoint_touching_is_not_disjoint__want() -> Bool:
  False{}

def bx_diag_sums__got() -> F64:
  B8.bx_diag(B8.BX{0.0f64, 1.0f64, 0.0f64, 2.0f64, 0.0f64, 3.0f64})

def bx_diag_sums__want() -> F64:
  6.0f64

def bx_x0_reads__got() -> F64:
  B8.BX_x0(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64})

def bx_x0_reads__want() -> F64:
  1.0f64

def bx_x1_reads__got() -> F64:
  B8.BX_x1(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64})

def bx_x1_reads__want() -> F64:
  2.0f64

def bx_y0_reads__got() -> F64:
  B8.BX_y0(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64})

def bx_y0_reads__want() -> F64:
  3.0f64

def bx_y1_reads__got() -> F64:
  B8.BX_y1(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64})

def bx_y1_reads__want() -> F64:
  4.0f64

def bx_z0_reads__got() -> F64:
  B8.BX_z0(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64})

def bx_z0_reads__want() -> F64:
  5.0f64

def bx_z1_reads__got() -> F64:
  B8.BX_z1(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64})

def bx_z1_reads__want() -> F64:
  6.0f64

def xf_pt_identity__got() -> V.Point:
  B8.xf_pt(m3id(), 0.0f64, 0.0f64, 0.0f64, V.Pt{1.0f64, 2.0f64, 3.0f64})

def xf_pt_identity__want() -> V.Point:
  V.Pt{1.0f64, 2.0f64, 3.0f64}

def xf_pt_translate_origin__got() -> V.Point:
  B8.xf_pt(m3id(), 1.0f64, 2.0f64, 3.0f64, pt0())

def xf_pt_translate_origin__want() -> V.Point:
  V.Pt{1.0f64, 2.0f64, 3.0f64}

def xf_dr_identity__got() -> V.Dir:
  B8.xf_dr(m3id(), dx())

def xf_dr_identity__want() -> V.Dir:
  dx()

def vr_fail_not_ok__got() -> Bool:
  B8.VR_ok(B8.vr_fail(7u64, "edge-use", 1n, 2n))

def vr_fail_not_ok__want() -> Bool:
  False{}

def vr_fail_stage__got() -> U64:
  B8.VR_stage(B8.vr_fail(7u64, "edge-use", 1n, 2n))

def vr_fail_stage__want() -> U64:
  7u64

def vr_fail_code__got() -> String:
  B8.VR_code(B8.vr_fail(7u64, "edge-use", 1n, 2n))

def vr_fail_code__want() -> String:
  "edge-use"

def vr_fail_a__got() -> Nat:
  B8.VR_a(B8.vr_fail(7u64, "edge-use", 1n, 2n))

def vr_fail_a__want() -> Nat:
  1n

def vr_fail_b__got() -> Nat:
  B8.VR_b(B8.vr_fail(7u64, "edge-use", 1n, 2n))

def vr_fail_b__want() -> Nat:
  2n

def vr_fail_nc_zero__got() -> Nat:
  B8.VR_nc(B8.vr_fail(7u64, "edge-use", 1n, 2n))

def vr_fail_nc_zero__want() -> Nat:
  0n

def vr_ok_true__got() -> Bool:
  B8.VR_ok(B8.VR{True{}, 0u64, 5n, "", 0n, 0n})

def vr_ok_true__want() -> Bool:
  True{}

def vr_nc_reads__got() -> Nat:
  B8.VR_nc(B8.VR{True{}, 0u64, 5n, "", 0n, 0n})

def vr_nc_reads__want() -> Nat:
  5n

def vcode_stage__got() -> String:
  B8.vcode(B8.VR{True{}, 12u64, 0n, "", 0n, 0n})

def vcode_stage__want() -> String:
  "c04-orientation"

def vcode_finding__got() -> String:
  B8.vcode(B8.VR{True{}, 0u64, 0n, "edge-crossing", 3n, 7n})

def vcode_finding__want() -> String:
  "edge-crossing 3 7"

def cr_reads__got() -> Bool:
  B8.CR_ok(B8.CR{True{}, 3n, 1n, 2n})

def cr_reads__want() -> Bool:
  True{}

def cr_nc_reads__got() -> Nat:
  B8.CR_nc(B8.CR{True{}, 3n, 1n, 2n})

def cr_nc_reads__want() -> Nat:
  3n

def cr_a_reads__got() -> Nat:
  B8.CR_a(B8.CR{True{}, 3n, 1n, 2n})

def cr_a_reads__want() -> Nat:
  1n

def cr_b_reads__got() -> Nat:
  B8.CR_b(B8.CR{True{}, 3n, 1n, 2n})

def cr_b_reads__want() -> Nat:
  2n

def cv_ok_reads__got() -> Bool:
  B8.CV_ok(B8.CV{True{}, Ty.brep_empty(), []})

def cv_ok_reads__want() -> Bool:
  True{}

def cv_brep_reads__got() -> Ty.Brep:
  B8.CV_brep(B8.CV{True{}, Ty.brep_empty(), []})

def cv_brep_reads__want() -> Ty.Brep:
  Ty.brep_empty()

def cv_fns_reads__got() -> List<&2, BD.Fn>:
  B8.CV_fns(B8.CV{True{}, Ty.brep_empty(), []})

def cv_fns_reads__want() -> List<&2, BD.Fn>:
  []

def ag_unc_reads__got() -> Bool:
  B8.AG_unc(B8.AG{True{}, False{}, 0n, []})

def ag_unc_reads__want() -> Bool:
  False{}

def ag_masks_reads__got() -> List<&2, U64>:
  B8.AG_masks(B8.AG{True{}, False{}, 0n, []})

def ag_masks_reads__want() -> List<&2, U64>:
  []

def out_empty_ok__got() -> Bool:
  B8.Out_ok(B8.out_empty(9u64, "", []))

def out_empty_ok__want() -> Bool:
  True{}

def out_empty_kind__got() -> U64:
  B8.Out_kind(B8.out_empty(9u64, "", []))

def out_empty_kind__want() -> U64:
  0u64

def out_empty_carry__got() -> U64:
  B8.Out_carry(B8.out_empty(9u64, "", []))

def out_empty_carry__want() -> U64:
  0u64

def out_empty_mat__got() -> U64:
  B8.Out_mat(B8.out_empty(9u64, "", []))

def out_empty_mat__want() -> U64:
  3u64

def out_empty_solids__got() -> Nat:
  B8.Out_sh(B8.out_empty(9u64, "", []))

def out_empty_solids__want() -> Nat:
  0n

def out_empty_holes__got() -> Nat:
  B8.Out_ho(B8.out_empty(9u64, "", []))

def out_empty_holes__want() -> Nat:
  0n

def out_empty_vol__got() -> I.I:
  B8.Out_vol(B8.out_empty(9u64, "", []))

def out_empty_vol__want() -> I.I:
  I.I{0.0f64, 0.0f64}

def out_empty_bb__got() -> B8.BX:
  B8.Out_bb(B8.out_empty(9u64, "", []))

def out_empty_bb__want() -> B8.BX:
  B8.bx_zero()

def out_empty_cells__got() -> List<&2, BD.Cl>:
  B8.Out_cells(B8.out_empty(9u64, "", []))

def out_empty_cells__want() -> List<&2, BD.Cl>:
  []

def out_empty_has_measures__got() -> Bool:
  B8.Out_hasm(B8.out_empty(9u64, "", []))

def out_empty_has_measures__want() -> Bool:
  True{}

def out_fail_not_ok__got() -> Bool:
  B8.Out_ok(B8.out_fail(1u64, "w", "l", "y", "f"))

def out_fail_not_ok__want() -> Bool:
  False{}

def out_fail_kind__got() -> U64:
  B8.Out_kind(B8.out_fail(1u64, "w", "l", "y", "f"))

def out_fail_kind__want() -> U64:
  1u64

def out_fail_what__got() -> String:
  B8.Out_what(B8.out_fail(1u64, "w", "l", "y", "f"))

def out_fail_what__want() -> String:
  "w"

def out_fail_why__got() -> String:
  B8.Out_why(B8.out_fail(1u64, "w", "l", "y", "f"))

def out_fail_why__want() -> String:
  "y"

def out_fail_fix__got() -> String:
  B8.Out_fix(B8.out_fail(1u64, "w", "l", "y", "f"))

def out_fail_fix__want() -> String:
  "f"

def out_fail_mat_unknown__got() -> U64:
  B8.Out_mat(B8.out_fail(1u64, "w", "l", "y", "f"))

def out_fail_mat_unknown__want() -> U64:
  4u64

def out_carry_side__got() -> U64:
  B8.Out_carry(B8.out_carry_direct(in0(), 2u64, "", []))

def out_carry_side__want() -> U64:
  2u64

def out_carry_mat__got() -> U64:
  B8.Out_mat(B8.out_carry_direct(in0(), 2u64, "", []))

def out_carry_mat__want() -> U64:
  3u64

def out_carry_vol__got() -> I.I:
  B8.Out_vol(B8.out_carry_direct(in0(), 2u64, "", []))

def out_carry_vol__want() -> I.I:
  I.I{1.0f64, 1.0f64}

def out_carry_brep__got() -> Ty.Brep:
  B8.Out_brep(B8.out_carry_direct(in0(), 2u64, "", []))

def out_carry_brep__want() -> Ty.Brep:
  Ty.brep_empty()

def out_carry_lin__got() -> F64:
  B8.Out_lin(B8.out_carry_direct(in0(), 2u64, "", []))

def out_carry_lin__want() -> F64:
  0.5f64

def out_carry_solids__got() -> Nat:
  B8.Out_sh(B8.out_carry_direct(in0(), 2u64, "", []))

def out_carry_solids__want() -> Nat:
  0n

def out_carry_holes__got() -> Nat:
  B8.Out_ho(B8.out_carry_direct(in0(), 2u64, "", []))

def out_carry_holes__want() -> Nat:
  0n

def in_brep_reads__got() -> Ty.Brep:
  B8.in_brep(in0())

def in_brep_reads__want() -> Ty.Brep:
  Ty.brep_empty()

def in_bo_reads__got() -> Bool:
  B8.in_bo(in0())

def in_bo_reads__want() -> Bool:
  False{}

def ce_flip_negates__got() -> Ty.Coedge:
  B8.ce_flip(Ty.Ce{0u64, Ty.HE{1n, 0u64}, True{}, G.GV_f{0.0f64}})

def ce_flip_negates__want() -> Ty.Coedge:
  Ty.Ce{0u64, Ty.HE{1n, 0u64}, False{}, G.GV_f{0.0f64}}

def ce_flip_twice_is_identity__got() -> Ty.Coedge:
  B8.ce_flip(B8.ce_flip(Ty.Ce{0u64, Ty.HE{1n, 0u64}, True{}, G.GV_f{0.0f64}}))

def ce_flip_twice_is_identity__want() -> Ty.Coedge:
  Ty.Ce{0u64, Ty.HE{1n, 0u64}, True{}, G.GV_f{0.0f64}}

def cav_flip_fas_empty__got() -> List<&2, Ty.Face>:
  B8.cav_flip_fas([], 5n, 0n)

def cav_flip_fas_empty__want() -> List<&2, Ty.Face>:
  []

def cav_flip_fas_tool_flips__got() -> List<&2, Ty.Face>:
  B8.cav_flip_fas([Ty.Fa{0u64, G.GV_f{0.0f64}, [], True{}}], 0n, 0n)

def cav_flip_fas_tool_flips__want() -> List<&2, Ty.Face>:
  [Ty.Fa{0u64, G.GV_f{0.0f64}, [], False{}}]

def cav_flip_fas_minuend_keeps__got() -> List<&2, Ty.Face>:
  B8.cav_flip_fas([Ty.Fa{0u64, G.GV_f{0.0f64}, [], False{}}], 1n, 0n)

def cav_flip_fas_minuend_keeps__want() -> List<&2, Ty.Face>:
  [Ty.Fa{0u64, G.GV_f{0.0f64}, [], False{}}]

def cav_flip_ces_empty__got() -> List<&2, Ty.Coedge>:
  B8.cav_flip_ces([], [], 0n)

def cav_flip_ces_empty__want() -> List<&2, Ty.Coedge>:
  []

def cav_flip_ces_marked_flips__got() -> List<&2, Ty.Coedge>:
  B8.cav_flip_ces([Ty.Ce{0u64, Ty.HE{0n, 0u64}, True{}, G.GV_f{0.0f64}}], [0n], 0n)

def cav_flip_ces_marked_flips__want() -> List<&2, Ty.Coedge>:
  [Ty.Ce{0u64, Ty.HE{0n, 0u64}, False{}, G.GV_f{0.0f64}}]

def cav_flip_ces_unmarked_keeps__got() -> List<&2, Ty.Coedge>:
  B8.cav_flip_ces([Ty.Ce{0u64, Ty.HE{0n, 0u64}, True{}, G.GV_f{0.0f64}}], [1n], 0n)

def cav_flip_ces_unmarked_keeps__want() -> List<&2, Ty.Coedge>:
  [Ty.Ce{0u64, Ty.HE{0n, 0u64}, True{}, G.GV_f{0.0f64}}]

def cav_flip_lps_empty__got() -> List<&2, Ty.Loop>:
  B8.cav_flip_lps([], [], 0n)

def cav_flip_lps_empty__want() -> List<&2, Ty.Loop>:
  []

def cav_flip_lps_reverses__got() -> List<&2, Ty.Loop>:
  B8.cav_flip_lps([Ty.Lp{0u64, [Ty.HC{0n, 0u64}, Ty.HC{1n, 0u64}], Ty.LK_outer{}}], [0n], 0n)

def cav_flip_lps_reverses__want() -> List<&2, Ty.Loop>:
  [Ty.Lp{0u64, [Ty.HC{1n, 0u64}, Ty.HC{0n, 0u64}], Ty.LK_outer{}}]

def cav_flip_lps_unmarked_keeps__got() -> List<&2, Ty.Loop>:
  B8.cav_flip_lps([Ty.Lp{0u64, [Ty.HC{0n, 0u64}, Ty.HC{1n, 0u64}], Ty.LK_outer{}}], [5n], 0n)

def cav_flip_lps_unmarked_keeps__want() -> List<&2, Ty.Loop>:
  [Ty.Lp{0u64, [Ty.HC{0n, 0u64}, Ty.HC{1n, 0u64}], Ty.LK_outer{}}]

def cav_floops_empty__got() -> List<&2, Nat>:
  B8.cav_floops([], 0n, 0n)

def cav_floops_empty__want() -> List<&2, Nat>:
  []

def cav_floops_collects_tool__got() -> List<&2, Nat>:
  B8.cav_floops([Ty.Fa{0u64, G.GV_f{0.0f64}, [Ty.HL{2n, 0u64}], True{}}], 0n, 0n)

def cav_floops_collects_tool__want() -> List<&2, Nat>:
  [2n]

def cav_floops_skips_minuend__got() -> List<&2, Nat>:
  B8.cav_floops([Ty.Fa{0u64, G.GV_f{0.0f64}, [Ty.HL{2n, 0u64}], True{}}], 1n, 0n)

def cav_floops_skips_minuend__want() -> List<&2, Nat>:
  []

def cav_fces_empty__got() -> List<&2, Nat>:
  B8.cav_fces([], [], 0n)

def cav_fces_empty__want() -> List<&2, Nat>:
  []

def cav_fces_collects_marked__got() -> List<&2, Nat>:
  B8.cav_fces([Ty.Lp{0u64, [Ty.HC{4n, 0u64}], Ty.LK_outer{}}], [0n], 0n)

def cav_fces_collects_marked__want() -> List<&2, Nat>:
  [4n]

def hl_ids_go_acc__got() -> List<&2, Nat>:
  B8.hl_ids_go([], [7n])

def hl_ids_go_acc__want() -> List<&2, Nat>:
  [7n]

def hl_ids_go_one__got() -> List<&2, Nat>:
  B8.hl_ids_go([Ty.HL{3n, 0u64}], [])

def hl_ids_go_one__want() -> List<&2, Nat>:
  [3n]

def hc_ids_go_empty__got() -> List<&2, Nat>:
  B8.hc_ids_go([], [])

def hc_ids_go_empty__want() -> List<&2, Nat>:
  []

def hc_ids_go_one__got() -> List<&2, Nat>:
  B8.hc_ids_go([Ty.HC{5n, 0u64}], [])

def hc_ids_go_one__want() -> List<&2, Nat>:
  [5n]

def cav_kind_tool_outer_is_inner__got() -> List<&2, Ty.Shell>:
  B8.cav_kind_shs([Ty.Sh{0u64, [], Ty.SK_outer{}}], [0n], 0n, 0n)

def cav_kind_tool_outer_is_inner__want() -> List<&2, Ty.Shell>:
  [Ty.Sh{0u64, [], Ty.SK_inner{}}]

def cav_kind_tool_cavity_is_outer__got() -> List<&2, Ty.Shell>:
  B8.cav_kind_shs([Ty.Sh{0u64, [], Ty.SK_inner{}}], [7n], 0n, 0n)

def cav_kind_tool_cavity_is_outer__want() -> List<&2, Ty.Shell>:
  [Ty.Sh{0u64, [], Ty.SK_outer{}}]

def cav_kind_minuend_keeps__got() -> List<&2, Ty.Shell>:
  B8.cav_kind_shs([Ty.Sh{0u64, [], Ty.SK_inner{}}], [], 1n, 0n)

def cav_kind_minuend_keeps__want() -> List<&2, Ty.Shell>:
  [Ty.Sh{0u64, [], Ty.SK_inner{}}]

def cav_topsos_two__got() -> List<&2, Ty.HSolid>:
  B8.cav_topsos(2n, 5n)

def cav_topsos_two__want() -> List<&2, Ty.HSolid>:
  [Ty.HSo{5n, 0u64}, Ty.HSo{6n, 0u64}]

def cav_topsos_zero__got() -> List<&2, Ty.HSolid>:
  B8.cav_topsos(0n, 5n)

def cav_topsos_zero__want() -> List<&2, Ty.HSolid>:
  []

def cav_islands_one__got() -> List<&2, Ty.Solid>:
  B8.cav_islands([1n], 10n)

def cav_islands_one__want() -> List<&2, Ty.Solid>:
  [Ty.So{0u64, Ty.HS{11n, 0u64}, []}]

def cav_islands_empty__got() -> List<&2, Ty.Solid>:
  B8.cav_islands([], 10n)

def cav_islands_empty__want() -> List<&2, Ty.Solid>:
  []

def cav_add_cav_hit__got() -> List<&2, Ty.Solid>:
  B8.cav_add_cav([Ty.So{0u64, Ty.HS{0n, 0u64}, []}], 0n, 7n, 0n)

def cav_add_cav_hit__want() -> List<&2, Ty.Solid>:
  [Ty.So{0u64, Ty.HS{0n, 0u64}, [Ty.HS{7n, 0u64}]}]

def cav_add_cav_miss__got() -> List<&2, Ty.Solid>:
  B8.cav_add_cav([Ty.So{0u64, Ty.HS{0n, 0u64}, []}], 1n, 7n, 0n)

def cav_add_cav_miss__want() -> List<&2, Ty.Solid>:
  [Ty.So{0u64, Ty.HS{0n, 0u64}, []}]

def cav_outs_collects__got() -> List<&2, Nat>:
  B8.cav_outs(Ty.brep_empty(), [Ty.So{0u64, Ty.HS{3n, 0u64}, []}])

def cav_outs_collects__want() -> List<&2, Nat>:
  [3n]

def cav_cavs_collects__got() -> List<&2, Nat>:
  B8.cav_cavs(Ty.brep_empty(), [Ty.So{0u64, Ty.HS{3n, 0u64}, [Ty.HS{4n, 0u64}]}])

def cav_cavs_collects__want() -> List<&2, Nat>:
  [4n]

def emb_ee_overlap_cross_is_contact__got() -> List<&2, SO.Fi>:
  EM.ee_hit(XS.H_ov{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}}, [], [], 0.0f64, 3n, 7n, True{}, egd(), egd(), [], [], [], [])

def emb_ee_overlap_cross_is_contact__want() -> List<&2, SO.Fi>:
  [SO.Fi{"contact-edge-edge", 3n, 7n}]

def emb_ee_overlap_same_is_fail__got() -> List<&2, SO.Fi>:
  EM.ee_hit(XS.H_ov{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}}, [], [], 0.0f64, 3n, 7n, False{}, egd(), egd(), [], [], [], [])

def emb_ee_overlap_same_is_fail__want() -> List<&2, SO.Fi>:
  [SO.Fi{"edge-overlap", 3n, 7n}]

def emb_ee_crossing_cross_still_fails__got() -> List<&2, SO.Fi>:
  EM.ee_hit(XS.H_pt{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, [I.I{0.0f64, 0.0f64}], 0u64}, [], [], 0.0f64, 3n, 7n, True{}, egd(), egd(), [], [], [], [])

def emb_ee_crossing_cross_still_fails__want() -> List<&2, SO.Fi>:
  [SO.Fi{"edge-crossing", 3n, 7n}]

def emb_ee_uncertain_cross_still_fails__got() -> List<&2, SO.Fi>:
  EM.ee_hit(XS.H_un{I.I{0.0f64, 1.0f64}, I.I{0.0f64, 1.0f64}, [I.I{0.0f64, 0.0f64}]}, [], [], 0.0f64, 3n, 7n, True{}, egd(), egd(), [], [], [], [])

def emb_ee_uncertain_cross_still_fails__want() -> List<&2, SO.Fi>:
  [SO.Fi{"edge-crossing-uncertain", 3n, 7n}]

def emb_ee_unsupported_cross_still_fails__got() -> List<&2, SO.Fi>:
  EM.ee_hit(XS.H_no{"why"}, [], [], 0.0f64, 3n, 7n, True{}, egd(), egd(), [], [], [], [])

def emb_ee_unsupported_cross_still_fails__want() -> List<&2, SO.Fi>:
  [SO.Fi{"edge-check-unsupported", 3n, 7n}]

def emb_ee_cross_endpoint_is_contact__got() -> List<&2, SO.Fi>:
  EM.ee_hit(XS.H_pt{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, [I.I{0.0f64, 0.0f64}], 0u64}, [], [[I.I{0.0f64, 0.0f64}]], 0.0f64, 3n, 7n, True{}, egd(), egd(), [], [], [], [])

def emb_ee_cross_endpoint_is_contact__want() -> List<&2, SO.Fi>:
  [SO.Fi{"contact-edge-edge", 3n, 7n}]

def emb_ee_cross_interior_still_fails__got() -> List<&2, SO.Fi>:
  EM.ee_hit(XS.H_pt{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, [I.I{5.0f64, 5.0f64}], 0u64}, [], [[I.I{0.0f64, 0.0f64}]], 0.0f64, 3n, 7n, True{}, egd(), egd(), [], [], [], [])

def emb_ee_cross_interior_still_fails__want() -> List<&2, SO.Fi>:
  [SO.Fi{"edge-crossing", 3n, 7n}]

def emb_ee_same_endpoint_excluded__got() -> List<&2, SO.Fi>:
  EM.ee_hit(XS.H_pt{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, [I.I{0.0f64, 0.0f64}], 0u64}, [[I.I{0.0f64, 0.0f64}]], [], 0.0f64, 3n, 7n, False{}, egd(), egd(), [], [], [], [])

def emb_ee_same_endpoint_excluded__want() -> List<&2, SO.Fi>:
  []

def model_bool_tag_union__got() -> U64:
  M.bool_tag(M.O_union{3u64, 5u64})

def model_bool_tag_union__want() -> U64:
  14u64

def model_bool_tag_diff__got() -> U64:
  M.bool_tag(M.O_difference{3u64, 5u64})

def model_bool_tag_diff__want() -> U64:
  15u64

def model_bool_tag_inter__got() -> U64:
  M.bool_tag(M.O_intersection{3u64, 5u64})

def model_bool_tag_inter__want() -> U64:
  16u64

def model_bool_tag_other__got() -> U64:
  M.bool_tag(M.O_unk{"x"})

def model_bool_tag_other__want() -> U64:
  0u64

def model_op_base_bool__got() -> U64:
  M.op_base(M.O_union{3u64, 5u64})

def model_op_base_bool__want() -> U64:
  3u64

def model_op_base2_bool__got() -> U64:
  M.op_base2(M.O_union{3u64, 5u64})

def model_op_base2_bool__want() -> U64:
  5u64

def model_op_base2_other__got() -> U64:
  M.op_base2(M.O_unk{"x"})

def model_op_base2_other__want() -> U64:
  0u64

def model_op_has_b2_bool__got() -> Bool:
  M.op_has_b2(M.O_difference{3u64, 5u64})

def model_op_has_b2_bool__want() -> Bool:
  True{}

def model_op_has_b2_other__got() -> Bool:
  M.op_has_b2(M.O_unk{"x"})

def model_op_has_b2_other__want() -> Bool:
  False{}

def model_op_is_bool__got() -> Bool:
  M.op_is_bool(M.O_intersection{3u64, 5u64})

def model_op_is_bool__want() -> Bool:
  True{}

def model_op_is_bool_other__got() -> Bool:
  M.op_is_bool(M.O_unk{"x"})

def model_op_is_bool_other__want() -> Bool:
  False{}

def model_op_name_union__got() -> String:
  M.op_name(M.O_union{3u64, 5u64})

def model_op_name_union__want() -> String:
  "union"

def model_op_name_diff__got() -> String:
  M.op_name(M.O_difference{3u64, 5u64})

def model_op_name_diff__want() -> String:
  "difference"

def model_op_name_inter__got() -> String:
  M.op_name(M.O_intersection{3u64, 5u64})

def model_op_name_inter__want() -> String:
  "intersection"

def model_bool_mat_add__got() -> M.Mat:
  M.bool_mat(1u64)

def model_bool_mat_add__want() -> M.Mat:
  M.M_add{}

def model_bool_mat_remove__got() -> M.Mat:
  M.bool_mat(2u64)

def model_bool_mat_remove__want() -> M.Mat:
  M.M_remove{}

def model_bool_mat_same__got() -> M.Mat:
  M.bool_mat(3u64)

def model_bool_mat_same__want() -> M.Mat:
  M.M_same{}

def model_bool_mat_unknown__got() -> M.Mat:
  M.bool_mat(4u64)

def model_bool_mat_unknown__want() -> M.Mat:
  M.M_unknown{}

def model_bool_mat_other_unknown__got() -> M.Mat:
  M.bool_mat(0u64)

def model_bool_mat_other_unknown__want() -> M.Mat:
  M.M_unknown{}

def model_bool_kind_invalid__got() -> T.FailKind:
  M.bool_kind(0u64)

def model_bool_kind_invalid__want() -> T.FailKind:
  T.F_invalid{}

def model_bool_kind_uncertain__got() -> T.FailKind:
  M.bool_kind(1u64)

def model_bool_kind_uncertain__want() -> T.FailKind:
  T.F_uncertain{}

def model_bool_kind_unsupported__got() -> T.FailKind:
  M.bool_kind(2u64)

def model_bool_kind_unsupported__want() -> T.FailKind:
  T.F_unsupported{}

def model_xb_id__got() -> M.Xb:
  M.xb_id()

def model_xb_id__want() -> M.Xb:
  M.Xb{[], 0n, False{}, "", []}

def model_xb_mx__got() -> List<&2, M.Ms>:
  M.xb_mx(M.Xb{[mval()], 1n, True{}, "", []})

def model_xb_mx__want() -> List<&2, M.Ms>:
  [mval()]

def model_xb_nc__got() -> Nat:
  M.xb_nc(M.Xb{[mval()], 1n, True{}, "", []})

def model_xb_nc__want() -> Nat:
  1n

def model_xb_bo__got() -> Bool:
  M.xb_bo(M.Xb{[mval()], 1n, True{}, "", []})

def model_xb_bo__want() -> Bool:
  True{}

def model_body_mx_stored__got() -> M.Ms:
  M.body_mx(bd0(), [mval()])

def model_body_mx_stored__want() -> M.Ms:
  M.Ms{I.I{1.0f64, 2.0f64}, I.I{3.0f64, 4.0f64}, I.dn(5.0f64), I.up(6.0f64), I.dn(7.0f64), I.up(8.0f64), I.dn(9.0f64), I.up(10.0f64), 11n, 12n, 13n, 14n, 15n, 16.0f64}

def model_body_mx_vol_passthrough__got() -> I.I:
  M.ms_vol(M.body_mx(bd0(), [mval()]))

def model_body_mx_vol_passthrough__want() -> I.I:
  I.I{1.0f64, 2.0f64}

def model_body_mx_moved__got() -> M.Ms:
  M.body_mx(M.Bd{[], Ty.brep_empty(), [], M.pl_move(M.pl_id(), 0u64, 10.0f64, 0.0f64, 0.0f64), [], M.xb_id()}, [mval()])

def model_body_mx_moved__want() -> M.Ms:
  M.Ms{I.I{1.0f64, 2.0f64}, I.I{3.0f64, 4.0f64}, I.dn(15.0f64), I.up(16.0f64), I.dn(7.0f64), I.up(8.0f64), I.dn(9.0f64), I.up(10.0f64), 11n, 12n, 13n, 14n, 15n, 16.0f64}

def model_ms_vol__got() -> I.I:
  M.ms_vol(mval())

def model_ms_vol__want() -> I.I:
  I.I{1.0f64, 2.0f64}

def model_ms_area__got() -> I.I:
  M.ms_area(mval())

def model_ms_area__want() -> I.I:
  I.I{3.0f64, 4.0f64}

def model_ms_x0__got() -> F64:
  M.ms_x0(mval())

def model_ms_x0__want() -> F64:
  5.0f64

def model_ms_x1__got() -> F64:
  M.ms_x1(mval())

def model_ms_x1__want() -> F64:
  6.0f64

def model_ms_y0__got() -> F64:
  M.ms_y0(mval())

def model_ms_y0__want() -> F64:
  7.0f64

def model_ms_y1__got() -> F64:
  M.ms_y1(mval())

def model_ms_y1__want() -> F64:
  8.0f64

def model_ms_z0__got() -> F64:
  M.ms_z0(mval())

def model_ms_z0__want() -> F64:
  9.0f64

def model_ms_z1__got() -> F64:
  M.ms_z1(mval())

def model_ms_z1__want() -> F64:
  10.0f64

def model_ms_lin__got() -> F64:
  M.ms_lin(mval())

def model_ms_lin__want() -> F64:
  16.0f64

def model_ms_ns__got() -> Nat:
  M.ms_ns(mval())

def model_ms_ns__want() -> Nat:
  14n

def model_ms_genus__got() -> Nat:
  M.ms_genus(mval())

def model_ms_genus__want() -> Nat:
  15n

def model_pl_m__got() -> V.Mat3:
  M.pl_m(M.Pl{m3id(), 1.0f64, 2.0f64, 3.0f64, [], []})

def model_pl_m__want() -> V.Mat3:
  m3id()

def model_pl_tx__got() -> F64:
  M.pl_tx(M.Pl{m3id(), 1.0f64, 2.0f64, 3.0f64, [], []})

def model_pl_tx__want() -> F64:
  1.0f64

def model_pl_ty__got() -> F64:
  M.pl_ty(M.Pl{m3id(), 1.0f64, 2.0f64, 3.0f64, [], []})

def model_pl_ty__want() -> F64:
  2.0f64

def model_pl_tz__got() -> F64:
  M.pl_tz(M.Pl{m3id(), 1.0f64, 2.0f64, 3.0f64, [], []})

def model_pl_tz__want() -> F64:
  3.0f64

def sx_print_union__got() -> String:
  S.sx_show(S.op_sx(M.O_union{1u64, 2u64}, []))

def sx_print_union__want() -> String:
  "(union 1 2)"

def sx_print_diff__got() -> String:
  S.sx_show(S.op_sx(M.O_difference{1u64, 2u64}, []))

def sx_print_diff__want() -> String:
  "(difference 1 2)"

def sx_print_inter__got() -> String:
  S.sx_show(S.op_sx(M.O_intersection{1u64, 2u64}, []))

def sx_print_inter__want() -> String:
  "(intersection 1 2)"

def sx_parse_union__got() -> M.Op:
  src_op("(node 4 (union 1 2) (intent same 0 0 1 0))")

def sx_parse_union__want() -> M.Op:
  M.O_union{1u64, 2u64}

def sx_parse_diff__got() -> M.Op:
  src_op("(node 4 (difference 1 2) (intent same 0 0 1 0))")

def sx_parse_diff__want() -> M.Op:
  M.O_difference{1u64, 2u64}

def sx_parse_inter__got() -> M.Op:
  src_op("(node 4 (intersection 1 2) (intent same 0 0 1 0))")

def sx_parse_inter__want() -> M.Op:
  M.O_intersection{1u64, 2u64}

def wbox_empty_is_zero__got() -> B8.BX:
  B8.wbox_of(Ty.brep_empty())

def wbox_empty_is_zero__want() -> B8.BX:
  B8.bx_zero()

def bake_eps_covers_lin__got() -> Bool:
  F64.is_le(0.5f64, B8.bake_eps(B8.BX{0.0f64, 10.0f64, 0.0f64, 10.0f64, 0.0f64, 10.0f64}, 0.5f64))

def bake_eps_covers_lin__want() -> Bool:
  True{}

def bx_widen_contains__got() -> Bool:
  Bool.and(F64.is_le(B8.BX_x0(B8.bx_widen(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64}, 0.25f64)), 1.0f64), F64.is_le(2.0f64, B8.BX_x1(B8.bx_widen(B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64}, 0.25f64))))

def bx_widen_contains__want() -> Bool:
  True{}

def iv_bx_reads__got() -> B8.BX:
  B8.iv_bx([I.I{1.0f64, 2.0f64}, I.I{3.0f64, 4.0f64}, I.I{5.0f64, 6.0f64}])

def iv_bx_reads__want() -> B8.BX:
  B8.BX{1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64}

def bx_mag_reads__got() -> F64:
  B8.bx_mag(B8.BX{F64.neg(3.0f64), 2.0f64, 0.0f64, 1.0f64, F64.neg(1.0f64), 1.0f64})

def bx_mag_reads__want() -> F64:
  3.0f64

def admit_interval_a__got() -> U64:
  B8.admit_code(False{}, False{}, 0u64, 0u64, 0u64, 0u64, False{}, True{})

def admit_interval_a__want() -> U64:
  7u64

def admit_interval_b__got() -> U64:
  B8.admit_code(False{}, False{}, 0u64, 0u64, 0u64, 0u64, True{}, False{})

def admit_interval_b__want() -> U64:
  8u64

def admit_open_beats_interval__got() -> U64:
  B8.admit_code(True{}, False{}, 0u64, 0u64, 0u64, 0u64, False{}, False{})

def admit_open_beats_interval__want() -> U64:
  1u64

def admit_edge_beats_interval__got() -> U64:
  B8.admit_code(False{}, False{}, 0u64, 0u64, 0u64, 1u64, False{}, True{})

def admit_edge_beats_interval__want() -> U64:
  6u64

def ef_bad_same_ignores_mode__got() -> String:
  EM.ef_bad(False{}, 1u64, "edge-face-penetration")

def ef_bad_same_ignores_mode__want() -> String:
  "edge-face-penetration"

def ef_bad_cross_contact__got() -> String:
  EM.ef_bad(True{}, 0u64, "edge-face-penetration")

def ef_bad_cross_contact__want() -> String:
  "contact-edge-face"

def ef_bad_cross_pierce__got() -> String:
  EM.ef_bad(True{}, 1u64, "edge-face-penetration")

def ef_bad_cross_pierce__want() -> String:
  "edge-face-penetration"

def ef_bad_cross_uncertain__got() -> String:
  EM.ef_bad(True{}, 2u64, "edge-face-overlap")

def ef_bad_cross_uncertain__want() -> String:
  "edge-face-uncertain"

def ef_mode_go_inside__got() -> U64:
  EM.ef_mode_go(1u64, 0u64)

def ef_mode_go_inside__want() -> U64:
  1u64

def ef_mode_go_outside__got() -> U64:
  EM.ef_mode_go(0u64, 3u64)

def ef_mode_go_outside__want() -> U64:
  0u64

def ef_mode_go_uncertain__got() -> U64:
  EM.ef_mode_go(2u64, 0u64)

def ef_mode_go_uncertain__want() -> U64:
  2u64

def ef_mode_go_inside_beats_uncertain__got() -> U64:
  EM.ef_mode_go(2u64, 1u64)

def ef_mode_go_inside_beats_uncertain__want() -> U64:
  1u64

def ef_mode_same_is_contact__got() -> U64:
  EM.ef_mode([], [], [], False{})

def ef_mode_same_is_contact__want() -> U64:
  0u64

def m_code_x_outside_is_empty__got() -> List<&2, SO.Fi>:
  EM.m_code_x(0u64, "contact-edge-face", 3n, 7n)

def m_code_x_outside_is_empty__want() -> List<&2, SO.Fi>:
  []

def m_code_x_inside_is_contact__got() -> List<&2, SO.Fi>:
  EM.m_code_x(1u64, "contact-edge-face", 3n, 7n)

def m_code_x_inside_is_contact__want() -> List<&2, SO.Fi>:
  [SO.Fi{"contact-edge-face", 3n, 7n}]

def m_code_x_boundary_is_contact__got() -> List<&2, SO.Fi>:
  EM.m_code_x(2u64, "contact-edge-face", 3n, 7n)

def m_code_x_boundary_is_contact__want() -> List<&2, SO.Fi>:
  [SO.Fi{"contact-edge-face", 3n, 7n}]

def ef_ov_cross_lenient__got() -> List<&2, SO.Fi>:
  EM.ef_ov(2u64, "contact-edge-face", "edge-face-overlap", True{}, 3n, 7n)

def ef_ov_cross_lenient__want() -> List<&2, SO.Fi>:
  [SO.Fi{"contact-edge-face", 3n, 7n}]

def ef_ov_same_strict__got() -> List<&2, SO.Fi>:
  EM.ef_ov(2u64, "contact-edge-face", "edge-face-overlap", False{}, 3n, 7n)

def ef_ov_same_strict__want() -> List<&2, SO.Fi>:
  [SO.Fi{"edge-face-uncertain", 3n, 7n}]

def ef_bad2_contact__got() -> String:
  EM.ef_bad2(0u64)

def ef_bad2_contact__want() -> String:
  "contact-edge-face"

def ef_bad2_pierce__got() -> String:
  EM.ef_bad2(1u64)

def ef_bad2_pierce__want() -> String:
  "edge-face-penetration"

def ef_bad2_uncertain__got() -> String:
  EM.ef_bad2(2u64)

def ef_bad2_uncertain__want() -> String:
  "edge-face-uncertain"

def ef_bad2_boundary_mode_is_contact__got() -> String:
  EM.ef_bad2(3u64)

def ef_bad2_boundary_mode_is_contact__want() -> String:
  "contact-edge-face"

def ef_clamp_mid__got() -> F64:
  EM.ef_clamp(0.5f64, 0.0f64, 1.0f64)

def ef_clamp_mid__want() -> F64:
  0.5f64

def ef_clamp_lo__got() -> F64:
  EM.ef_clamp(F64.neg(1.0f64), 0.0f64, 1.0f64)

def ef_clamp_lo__want() -> F64:
  0.0f64

def ef_clamp_hi__got() -> F64:
  EM.ef_clamp(2.0f64, 0.0f64, 1.0f64)

def ef_clamp_hi__want() -> F64:
  1.0f64

def ef_tan_code_contact__got() -> String:
  EM.ef_tan_code(0u64)

def ef_tan_code_contact__want() -> String:
  "contact-edge-face"

def ef_tan_code_pierce__got() -> String:
  EM.ef_tan_code(1u64)

def ef_tan_code_pierce__want() -> String:
  "edge-face-penetration"

def ef_tan_code_uncertain__got() -> String:
  EM.ef_tan_code(2u64)

def ef_tan_code_uncertain__want() -> String:
  "edge-face-uncertain"

def ff_iv_overlap_hit__got() -> Bool:
  EM.ff_iv_overlap(I.I{1.0f64, 2.0f64}, I.I{1.5f64, 3.0f64})

def ff_iv_overlap_hit__want() -> Bool:
  True{}

def ff_iv_overlap_miss_lo__got() -> Bool:
  EM.ff_iv_overlap(I.I{1.0f64, 2.0f64}, I.I{3.0f64, 4.0f64})

def ff_iv_overlap_miss_lo__want() -> Bool:
  False{}

def ff_iv_overlap_miss_hi__got() -> Bool:
  EM.ff_iv_overlap(I.I{3.0f64, 4.0f64}, I.I{1.0f64, 2.0f64})

def ff_iv_overlap_miss_hi__want() -> Bool:
  False{}

def ff_iv_overlap_touch__got() -> Bool:
  EM.ff_iv_overlap(I.I{1.0f64, 2.0f64}, I.I{2.0f64, 3.0f64})

def ff_iv_overlap_touch__want() -> Bool:
  True{}

def es_share_hit__got() -> Bool:
  EM.es_share([1n, 2n, 3n], [5n, 2n])

def es_share_hit__want() -> Bool:
  True{}

def es_share_miss__got() -> Bool:
  EM.es_share([1n, 2n, 3n], [5n, 6n])

def es_share_miss__want() -> Bool:
  False{}

def es_share_empty__got() -> Bool:
  EM.es_share([], [5n])

def es_share_empty__want() -> Bool:
  False{}

def sm_mid_pt_none__got() -> List<&2, B8.SM>:
  B8.sm_mid_pt(None{}, 3n)

def sm_mid_pt_none__want() -> List<&2, B8.SM>:
  []

def sm_mid_pt_some__got() -> List<&2, B8.SM>:
  B8.sm_mid_pt(Some{[I.ipt(1.0f64), I.ipt(2.0f64), I.ipt(4.0f64)]}, 3n)

def sm_mid_pt_some__want() -> List<&2, B8.SM>:
  [B8.SM{V.Pt{1.0f64, 2.0f64, 4.0f64}, 3n}]

def sm_int_fd_empty__got() -> List<&2, B8.SM>:
  B8.sm_int_fd([], 3n)

def sm_int_fd_empty__want() -> List<&2, B8.SM>:
  []

def d2_primary_sign__got() -> P.Sgn:
  E.ex_sign(XS.e3_z(XS.bp_nrm(fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 1.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64))))

def d2_primary_sign__want() -> P.Sgn:
  P.Sn{}

def d2_fallback3_sign__got() -> P.Sgn:
  E.ex_sign(XS.e3_z(XS.bp_nrm(fq(0.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64))))

def d2_fallback3_sign__want() -> P.Sgn:
  P.Sn{}

def d2_old4_order_flipped__got() -> P.Sgn:
  E.ex_sign(XS.e3_z(XS.bp_nrm(fq(0.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64))))

def d2_old4_order_flipped__want() -> P.Sgn:
  P.Sp{}

def d2_old_order_flipped__got() -> P.Sgn:
  E.ex_sign(XS.e3_z(XS.bp_nrm(fq(0.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64))))

def d2_old_order_flipped__want() -> P.Sgn:
  P.Sp{}

def d2_pick_degenerate_net__got() -> P.Sgn:
  bp_z_sign(XS.bp_pick(fq(0.0f64, 0.0f64, 0.0f64), fq(0.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64), d2_degen_net()))

def d2_pick_degenerate_net__want() -> P.Sgn:
  P.Sn{}

def transverse_edge_crossing__got() -> Bool:
  B8.is_transverse_code("edge-crossing")

def transverse_edge_crossing__want() -> Bool:
  True{}

def transverse_nesting__got() -> Bool:
  B8.is_transverse_code("cavities-nested")

def transverse_nesting__want() -> Bool:
  True{}

def transverse_unknown_false__got() -> Bool:
  B8.is_transverse_code("future-code")

def transverse_unknown_false__want() -> Bool:
  False{}

def partition_unknown_is_none__got() -> Bool:
  Bool.and(Bool.not(B8.is_contact("future-code")), Bool.and(Bool.not(B8.is_uncertain_code("future-code")), Bool.not(B8.is_unsupported_code("future-code"))))

def partition_unknown_is_none__want() -> Bool:
  True{}

def intersect_unknown_is_uncertain__got() -> U64:
  B8.Out_kind(B8.intersect_fail(9u64, 1u64, 2u64, B8.VR{False{}, 0u64, 0n, "future-code", 3n, 7n}))

def intersect_unknown_is_uncertain__want() -> U64:
  1u64

def intersect_unknown_why__got() -> String:
  B8.Out_why(B8.intersect_fail(9u64, 1u64, 2u64, B8.VR{False{}, 0u64, 0n, "future-code", 3n, 7n}))

def intersect_unknown_why__want() -> String:
  "unknown-finding: future-code 3 7 between nodes 1 and 2"

def intersect_transverse_still_crosses__got() -> String:
  B8.Out_why(B8.intersect_fail(9u64, 1u64, 2u64, B8.VR{False{}, 0u64, 0n, "edge-crossing", 3n, 7n}))

def intersect_transverse_still_crosses__want() -> String:
  "boundaries-cross-or-overlap: edge-crossing 3 7 between nodes 1 and 2"

def append_out_rebox__got() -> B8.BX:
  B8.Out_bb(B8.append_out(14u64, in0(), in0(), Ty.brep_empty(), 9u64, 0n, B8.BX{0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64}, B8.BX{2.0f64, 3.0f64, 2.0f64, 3.0f64, 2.0f64, 3.0f64}, ""))

def append_out_rebox__want() -> B8.BX:
  B8.BX{0.0f64, 3.0f64, 0.0f64, 3.0f64, 0.0f64, 3.0f64}

def append_out_no_del__got() -> List<&2, B8.Del>:
  B8.Out_del(B8.append_out(14u64, in0(), in0(), Ty.brep_empty(), 9u64, 0n, B8.bx_zero(), B8.bx_zero(), ""))

def append_out_no_del__want() -> List<&2, B8.Del>:
  []

def append_out_proof__got() -> String:
  B8.Out_proof(B8.append_out(14u64, in0(), in0(), Ty.brep_empty(), 9u64, 0n, B8.bx_zero(), B8.bx_zero(), "p"))

def append_out_proof__want() -> String:
  "p"

def xf_moves_ln__got() -> G.GVal:
  B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_ln{G.Ln{pt0(), dx()}})

def xf_moves_ln__want() -> G.GVal:
  G.GV_ln{G.Ln{fq(1.0f64, 0.0f64, 0.0f64), dx()}}

def xf_moves_pl__got() -> G.GVal:
  B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_pl{G.Pl{pt0(), dx(), dy()}})

def xf_moves_pl__want() -> G.GVal:
  G.GV_pl{G.Pl{fq(1.0f64, 0.0f64, 0.0f64), dx(), dy()}}

def xf_moves_cc__got() -> G.GVal:
  B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_cc{G.Cc{pt0(), dx(), dy(), 2.0f64}})

def xf_moves_cc__want() -> G.GVal:
  G.GV_cc{G.Cc{fq(1.0f64, 0.0f64, 0.0f64), dx(), dy(), 2.0f64}}

def xf_moves_bz__got() -> G.GVal:
  B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_bz{G.Bz{pt0(), ptx(), pty(), pt0()}})

def xf_moves_bz__want() -> G.GVal:
  G.GV_bz{G.Bz{fq(1.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64), fq(1.0f64, 0.0f64, 0.0f64)}}

def xf_moves_rq__got() -> G.GVal:
  B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_rq{G.Rq{pt0(), ptx(), pty(), 1.0f64, 1.0f64, 1.0f64}})

def xf_moves_rq__want() -> G.GVal:
  G.GV_rq{G.Rq{fq(1.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64), 1.0f64, 1.0f64, 1.0f64}}

def xf_moves_sp__got() -> G.GVal:
  B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_sp{G.Sp{pt0(), 2.0f64}})

def xf_moves_sp__want() -> G.GVal:
  G.GV_sp{G.Sp{fq(1.0f64, 0.0f64, 0.0f64), 2.0f64}}

def xf_moves_cy__got() -> G.GVal:
  B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_cy{G.Cy{pt0(), dx(), 2.0f64}})

def xf_moves_cy__want() -> G.GVal:
  G.GV_cy{G.Cy{fq(1.0f64, 0.0f64, 0.0f64), dx(), 2.0f64}}

def xf_moves_co__got() -> G.GVal:
  B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_co{G.Co{pt0(), dx(), 2.0f64}})

def xf_moves_co__want() -> G.GVal:
  G.GV_co{G.Co{fq(1.0f64, 0.0f64, 0.0f64), dx(), 2.0f64}}

def xf_moves_to__got() -> G.GVal:
  B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_to{G.To{pt0(), dx(), 3.0f64, 2.0f64}})

def xf_moves_to__want() -> G.GVal:
  G.GV_to{G.To{fq(1.0f64, 0.0f64, 0.0f64), dx(), 3.0f64, 2.0f64}}

def xf_moves_bb__got() -> G.GVal:
  B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_bb{G.Bb{pt0(), ptx()}})

def xf_moves_bb__want() -> G.GVal:
  G.GV_bb{G.Bb{fq(1.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64)}}

def xf_moves_nb__got() -> G.GVal:
  B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_nb{G.Nb{[], [pt0()], []}})

def xf_moves_nb__want() -> G.GVal:
  G.GV_nb{G.Nb{[], [fq(1.0f64, 0.0f64, 0.0f64)], []}}

def xf_moves_bp__got() -> G.GVal:
  B8.xf_gval(m3id(), 1.0f64, 0.0f64, 0.0f64, G.GV_bp{flat_bp()})

def xf_moves_bp__want() -> G.GVal:
  G.GV_bp{G.Bp{fq(1.0f64, 0.0f64, 0.0f64), fq(2.0f64, 0.0f64, 0.0f64), fq(3.0f64, 0.0f64, 0.0f64), fq(4.0f64, 0.0f64, 0.0f64), fq(1.0f64, 1.0f64, 0.0f64), fq(2.0f64, 1.0f64, 0.0f64), fq(3.0f64, 1.0f64, 0.0f64), fq(4.0f64, 1.0f64, 0.0f64), fq(1.0f64, 2.0f64, 0.0f64), fq(2.0f64, 2.0f64, 0.0f64), fq(3.0f64, 2.0f64, 0.0f64), fq(4.0f64, 2.0f64, 0.0f64), fq(1.0f64, 3.0f64, 0.0f64), fq(2.0f64, 3.0f64, 0.0f64), fq(3.0f64, 3.0f64, 0.0f64), fq(4.0f64, 3.0f64, 0.0f64)}}

def del_classified_empty__got() -> List<&2, B8.Del>:
  B8.del_classified([])

def del_classified_empty__want() -> List<&2, B8.Del>:
  []

def del_classified_one__got() -> List<&2, B8.Del>:
  B8.del_classified([BD.Fn{1u64, 0n, 0u64, 0n, 0n}])

def del_classified_one__want() -> List<&2, B8.Del>:
  [B8.Del{BD.Fn{1u64, 0n, 0u64, 0n, 0n}, 0u64}]

def same_carry_not_classified__got() -> List<&2, B8.Del>:
  B8.carry_dels(True{}, [face_del()])

def same_carry_not_classified__want() -> List<&2, B8.Del>:
  []

def same_diff_lists_once__got() -> List<&2, B8.Del>:
  B8.empty_dels(True{}, [face_del()], [face_del()])

def same_diff_lists_once__want() -> List<&2, B8.Del>:
  [face_del()]

def other_carry_classified__got() -> List<&2, B8.Del>:
  B8.carry_dels(False{}, [face_del()])

def other_carry_classified__want() -> List<&2, B8.Del>:
  [face_del()]

def other_empty_lists_both__got() -> List<&2, B8.Del>:
  B8.empty_dels(False{}, [face_del()], [face_del()])

def other_empty_lists_both__want() -> List<&2, B8.Del>:
  [face_del(), face_del()]

def del_why_words__got() -> Bool:
  Bool.and(String.eq(B8.del_why_s(0u64), "classified-away"), Bool.and(String.eq(B8.del_why_s(1u64), "regularized-away"), String.eq(B8.del_why_s(2u64), "merged")))

def del_why_words__want() -> Bool:
  True{}

def del_show_created__got() -> String:
  B8.del_show(B8.Del{BD.Fn{4u64, 0n, 4u64, 0n, 0n}, 0u64})

def del_show_created__want() -> String:
  "n4.cav.0.0.0 classified-away"

def out_del_empty_default__got() -> List<&2, B8.Del>:
  B8.Out_del(B8.out_empty(9u64, "", []))

def out_del_empty_default__want() -> List<&2, B8.Del>:
  []

def out_del_fail_default__got() -> List<&2, B8.Del>:
  B8.Out_del(B8.out_fail(1u64, "w", "l", "y", "f"))

def out_del_fail_default__want() -> List<&2, B8.Del>:
  []

def out_proof_plumbing__got() -> String:
  B8.Out_proof(B8.out_empty(9u64, "p", []))

def out_proof_plumbing__want() -> String:
  "p"

def fn_show_created_role__got() -> String:
  B8.fn_show(BD.Fn{4u64, 2n, 4u64, 3n, 1n})

def fn_show_created_role__want() -> String:
  "n4.cav.2.3.1"

def disjoint_proof_empty_default__got() -> String:
  B8.Out_proof(B8.out_fail(1u64, "w", "l", "y", "f"))

def disjoint_proof_empty_default__want() -> String:
  ""

def model_xb_pr_default__got() -> String:
  M.xb_pr(M.Xb{[mval()], 1n, True{}, "p", []})

def model_xb_pr_default__want() -> String:
  "p"

def model_xb_dl_default__got() -> List<&2, B8.Del>:
  M.xb_dl(M.Xb{[mval()], 1n, True{}, "", []})

def model_xb_dl_default__want() -> List<&2, B8.Del>:
  []

def model_bool_body_origin__got() -> Bool:
  M.xb_bo(M.bd_xb(M.bool_body(B8.out_empty(9u64, "", []))))

def model_bool_body_origin__want() -> Bool:
  True{}

def model_ck_go_origin__got() -> M.Xb:
  M.bd_xb(M.nr_body(M.ck_go(True{}, Ty.brep_empty(), [], [], M.pl_id(), "", [])))

def model_ck_go_origin__want() -> M.Xb:
  M.xb_id()

def model_carry_keeps_plain__got() -> Bool:
  M.xb_bo(M.bd_xb(M.bool_carry(B8.out_carry_direct(in0(), 1u64, "", []), bd0(), M.bool_body(B8.out_empty(9u64, "", [])))))

def model_carry_keeps_plain__want() -> Bool:
  False{}

def model_carry_keeps_assembled__got() -> Bool:
  M.xb_bo(M.bd_xb(M.bool_carry(B8.out_carry_direct(in0(), 2u64, "", []), bd0(), M.bool_body(B8.out_empty(9u64, "", [])))))

def model_carry_keeps_assembled__want() -> Bool:
  True{}

def model_bool_body_proof__got() -> String:
  M.xb_pr(M.bd_xb(M.bool_body(B8.out_empty(9u64, "p", []))))

def model_bool_body_proof__want() -> String:
  "p"

def lp_v0_empty_is_none__got() -> Maybe<&2, V.Point>:
  B8.lp_v0(Ty.brep_empty(), [])

def lp_v0_empty_is_none__want() -> Maybe<&2, V.Point>:
  None{}

def fa_v0_empty_is_none__got() -> Maybe<&2, V.Point>:
  B8.fa_v0(Ty.brep_empty(), [])

def fa_v0_empty_is_none__want() -> Maybe<&2, V.Point>:
  None{}

def face_pts_skips_loopless__got() -> List<&2, V.Point>:
  B8.face_pts(Ty.brep_empty(), [Ty.HF{0n, 0u64}])

def face_pts_skips_loopless__want() -> List<&2, V.Point>:
  []

def in_lin_reads__got() -> F64:
  B8.in_lin(in0())

def in_lin_reads__want() -> F64:
  0.5f64

def in_px_reads__got() -> Bool:
  B8.in_px(in0())

def in_px_reads__want() -> Bool:
  True{}

def in_fns_reads__got() -> List<&2, BD.Fn>:
  B8.in_fns(in0())

def in_fns_reads__want() -> List<&2, BD.Fn>:
  []

def mid_pt_exact__got() -> V.Point:
  B8.mid_pt([I.ipt(0.0f64), I.ipt(2.0f64), I.ipt(4.0f64)])

def mid_pt_exact__want() -> V.Point:
  V.Pt{0.0f64, 2.0f64, 4.0f64}

def cv_mid_none__got() -> Maybe<&2, V.Point>:
  B8.cv_mid(None{})

def cv_mid_none__want() -> Maybe<&2, V.Point>:
  None{}

def ed_mid_degenerate_none__got() -> Maybe<&2, V.Point>:
  B8.ed_mid(Ty.EK_degenerate{})

def ed_mid_degenerate_none__want() -> Maybe<&2, V.Point>:
  None{}

def ed_mid_uncurved_none__got() -> Maybe<&2, V.Point>:
  B8.ed_mid(Ty.EK_curve{G.GV_f{0.0f64}, dom01()})

def ed_mid_uncurved_none__want() -> Maybe<&2, V.Point>:
  None{}

def ed_mid_line_one__got() -> Nat:
  List.length(&2, V.Point, B8.mid_cons(B8.ed_mid(Ty.EK_curve{G.GV_ln{G.Ln{pt0(), dx()}}, dom01()}), []))

def ed_mid_line_one__want() -> Nat:
  1n

def ed_mid_cubic_one__got() -> Nat:
  List.length(&2, V.Point, B8.mid_cons(B8.ed_mid(Ty.EK_curve{G.GV_bz{G.Bz{pt0(), ptx(), pty(), pt0()}}, dom01()}), []))

def ed_mid_cubic_one__want() -> Nat:
  1n

def ed_mid_circle_one__got() -> Nat:
  List.length(&2, V.Point, B8.mid_cons(B8.ed_mid(Ty.EK_curve{G.GV_cc{G.Cc{pt0(), dx(), dy(), 1.0f64}}, dom01()}), []))

def ed_mid_circle_one__want() -> Nat:
  1n

def ed_mid_rational_one__got() -> Nat:
  List.length(&2, V.Point, B8.mid_cons(B8.ed_mid(Ty.EK_curve{G.GV_rq{G.Rq{pt0(), ptx(), pty(), 1.0f64, 1.0f64, 1.0f64}}, dom01()}), []))

def ed_mid_rational_one__want() -> Nat:
  1n

def mid_cons_none__got() -> List<&2, V.Point>:
  B8.mid_cons(None{}, [pt0()])

def mid_cons_none__want() -> List<&2, V.Point>:
  [pt0()]

def mid_cons_some__got() -> List<&2, V.Point>:
  B8.mid_cons(Some{ptx()}, [pt0()])

def mid_cons_some__want() -> List<&2, V.Point>:
  [ptx(), pt0()]

def lp_mids_empty__got() -> List<&2, V.Point>:
  B8.lp_mids(Ty.brep_empty(), [])

def lp_mids_empty__want() -> List<&2, V.Point>:
  []

def fa_mids_empty__got() -> List<&2, V.Point>:
  B8.fa_mids(Ty.brep_empty(), [])

def fa_mids_empty__want() -> List<&2, V.Point>:
  []
