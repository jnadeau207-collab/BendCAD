import Base
import ../../src/c14/asm.bend as AS
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c06/build.bend as BD
import ../../src/c05/sqr.bend as Q
import ../../src/c05/solve.bend as SL
import ../../src/base/par.bend as P
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c01/types.bend as V

def pinst(+n: String, +nd: U64, +x: F64, +y: F64, +z: F64, +q: U64) -> AS.Inst:
  AS.Inst{n, nd, x, y, z, q}

def pmate(+id: U64, +k: U64, +a: String, +b: String, +p: List<&2, F64>) -> AS.Mate:
  AS.Mate{id, k, a, b, p}

def pasm(+il: List<&2, AS.Inst>, +ml: List<&2, AS.Mate>) -> AS.Asm:
  AS.Asm{il, ml}

def sa(+s: String) -> S.Sx:
  S.Sx_a{s}

def sl(+xs: List<&2, S.Sx>) -> S.Sx:
  S.Sx_l{xs}

def pt0() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def dz0() -> V.Dir:
  V.Dr{0.0f64, 0.0f64, 1.0f64}

def bs(+b: Bool) -> String:
  match b:
    case True{}: "1"
    case False{}: "0"

def ar_why(+r: AS.AR) -> String:
  match r:
    case AS.AR_ok{+a}: "ok"
    case AS.AR_err{+why, +fix}: why

def ar_counts(+r: AS.AR) -> String:
  match r:
    case AS.AR_ok{+a}: Nat.show(List.length(&2, AS.Inst, AS.asm_insts(a))) ++ "/" ++ Nat.show(List.length(&2, AS.Mate, AS.asm_mates(a)))
    case AS.AR_err{+why, +fix}: "err:" ++ why

def er_tag(+r: AS.ER) -> String:
  match r:
    case AS.ER_inst{+i}: "inst"
    case AS.ER_mate{+m}: "mate:" ++ U64.show(AS.mate_kind(m))
    case AS.ER_err{+why, +fix}: why

def as_ok(+s: AS.AS) -> Bool:
  match s:
    case AS.AS_ok{+xs, +dof, +red, +res}: True{}
    case AS.AS_conf{+ids, +res}: False{}

def as_dof(+s: AS.AS) -> Nat:
  match s:
    case AS.AS_ok{+xs, +dof, +red, +res}: dof
    case AS.AS_conf{+ids, +res}: 999n

def as_red(+s: AS.AS) -> String:
  match s:
    case AS.AS_ok{+xs, +dof, +red, +res}: AS.ids_show(red)
    case AS.AS_conf{+ids, +res}: "conf"

def as_viol(+s: AS.AS) -> String:
  match s:
    case AS.AS_ok{+xs, +dof, +red, +res}: "ok"
    case AS.AS_conf{+ids, +res}: AS.ids_show(ids)

def as_res(+s: AS.AS) -> F64:
  match s:
    case AS.AS_ok{+xs, +dof, +red, +res}: res
    case AS.AS_conf{+ids, +res}: res

def as_x(+s: AS.AS, +i: Nat) -> F64:
  match s:
    case AS.AS_ok{+xs, +dof, +red, +res}: M.f_nth(xs, i)
    case AS.AS_conf{+ids, +res}: 999.0f64

def dr_nth(+ds: List<&2, SL.Dr>, +i: Nat) -> SL.Dr:
  match ds:
    case []: SL.Dr{0u64, 0.0f64, []}
    case d <> t:
      match i:
        case 0n: d
        case 1n+j: dr_nth(t, j)

def sv_head_c(+xs: List<&2, Q.Sv>) -> Nat:
  match xs:
    case []: 999n
    case s <> t: U32.to_nat(Q.sv_c(s))

def sv_head_v(+xs: List<&2, Q.Sv>) -> F64:
  match xs:
    case []: 999.0f64
    case s <> t: Q.sv_v(s)

def empty_nr() -> M.NR:
  M.NR_ok{M.Bd{[], Ty.brep_empty(), [], M.pl_id(), [], M.xb_id()}, M.Fx{M.M_create{}, 0n, 0n, 0n, 0n}}

def empty_part() -> M.Part:
  M.Pt{[], []}

def rq1() -> AS.RQ:
  AS.RQ{1u64, "", []}

def bp0() -> G.BezP:
  G.Bp{pt0(), pt0(), pt0(), pt0(), pt0(), pt0(), pt0(), pt0(), pt0(), pt0(), pt0(), pt0(), pt0(), pt0(), pt0(), pt0()}

def plsurf() -> G.GVal:
  G.GV_pl{G.Pl{pt0(), dz0(), dz0()}}

def ia0() -> AS.Inst:
  pinst("a", 1u64, 0.0f64, 0.0f64, 0.0f64, 0u64)

def ib0() -> AS.Inst:
  pinst("b", 2u64, 0.0f64, 0.0f64, 0.0f64, 0u64)

def iab() -> List<&2, AS.Inst>:
  [ia0(), ib0()]

def acc_inst__got() -> String:
  +i = pinst("a", 1u64, 2.0f64, 3.0f64, 4.0f64, 5u64)
  AS.inst_name(i) ++ "," ++ U64.show(AS.inst_node(i)) ++ "," ++ S.f_show(AS.inst_tx(i)) ++ "," ++ S.f_show(AS.inst_ty(i)) ++ "," ++ S.f_show(AS.inst_tz(i)) ++ "," ++ U64.show(AS.inst_q(i))

def acc_inst__want() -> String:
  "a,1,2,3,4,5"

def acc_mate__got() -> String:
  +m = pmate(7u64, 2u64, "a", "b", [1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64])
  U64.show(AS.mate_id(m)) ++ "," ++ U64.show(AS.mate_kind(m)) ++ "," ++ AS.mate_a(m) ++ "," ++ AS.mate_b(m) ++ "," ++ Nat.show(List.length(&2, F64, AS.mate_p(m)))

def acc_mate__want() -> String:
  "7,2,a,b,6"

def acc_asm__got() -> String:
  +a = pasm([ia0(), ib0()], [pmate(1u64, 1u64, "", "a", [])])
  Nat.show(List.length(&2, AS.Inst, AS.asm_insts(a))) ++ "/" ++ Nat.show(List.length(&2, AS.Mate, AS.asm_mates(a)))

def acc_asm__want() -> String:
  "2/1"

def acc_in_name__got() -> String:
  AS.in_name(AS.IN{ia0(), empty_nr()})

def acc_in_name__want() -> String:
  "a"

def acc_in_ok__got() -> Bool:
  M.nr_ok(AS.in_nr(AS.IN{ia0(), empty_nr()}))

def acc_in_ok__want() -> Bool:
  True{}

def cat3__got() -> String:
  AS.cat(["a", "b", "c"])

def cat3__want() -> String:
  "a b c "

def cat0__got() -> String:
  AS.cat([])

def cat0__want() -> String:
  ""

def sdrop_head__got() -> String:
  S.arg_at(AS.sdrop(["a", "b", "c"], 2n), 0n)

def sdrop_head__want() -> String:
  "c"

def sdrop_len__got() -> Nat:
  List.length(&2, String, AS.sdrop(["a", "b", "c"], 5n))

def sdrop_len__want() -> Nat:
  0n

def sdec_num__got() -> F64:
  AS.sdec("2.5")

def sdec_num__want() -> F64:
  2.5f64

def sdec_neg__got() -> F64:
  AS.sdec("-3")

def sdec_neg__want() -> F64:
  F64.neg(3.0f64)

def sdec_tenth__got() -> F64:
  AS.sdec("0.1")

def sdec_tenth__want() -> F64:
  0.1f64

def sdec_bad__got() -> F64:
  AS.sdec("bogus")

def sdec_bad__want() -> F64:
  F64.nan()

def fnum_dec__got() -> F64:
  AS.fnum(sa("1.5"))

def fnum_dec__want() -> F64:
  1.5f64

def isu64_yes__got() -> Bool:
  AS.is_u64(sa("12"))

def isu64_yes__want() -> Bool:
  True{}

def isu64_no__got() -> Bool:
  AS.is_u64(sa("x"))

def isu64_no__want() -> Bool:
  False{}

def uval12__got() -> U64:
  AS.uval(sa("12"))

def uval12__want() -> U64:
  12u64

def uval_bad__got() -> U64:
  AS.uval(sa("zz"))

def uval_bad__want() -> U64:
  0u64

def p6_len__got() -> Nat:
  List.length(&2, F64, AS.p6(1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64))

def p6_len__want() -> Nat:
  6n

def p7_len__got() -> Nat:
  List.length(&2, F64, AS.p7(1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64, 7.0f64))

def p7_len__want() -> Nat:
  7n

def p9_len__got() -> Nat:
  List.length(&2, F64, AS.p9(1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64, 7.0f64, 8.0f64, 9.0f64))

def p9_len__want() -> Nat:
  9n

def fins_yes__got() -> Bool:
  AS.fins([1.0f64, 2.0f64])

def fins_yes__want() -> Bool:
  True{}

def fins_no__got() -> Bool:
  AS.fins([1.0f64, F64.nan()])

def fins_no__want() -> Bool:
  False{}

def fins_empty__got() -> Bool:
  AS.fins([])

def fins_empty__want() -> Bool:
  True{}

def nzn_zero__got() -> Bool:
  AS.nzn(0.0f64, 0.0f64, 0.0f64)

def nzn_zero__want() -> Bool:
  False{}

def nzn_nz__got() -> Bool:
  AS.nzn(0.0f64, 0.0f64, 1.0f64)

def nzn_nz__want() -> Bool:
  True{}

def entry_kinds__got() -> String:
  U64.show(AS.entry_kind("inst")) ++ "," ++ U64.show(AS.entry_kind("fix")) ++ "," ++ U64.show(AS.entry_kind("coinc")) ++ "," ++ U64.show(AS.entry_kind("plane")) ++ "," ++ U64.show(AS.entry_kind("axis")) ++ "," ++ U64.show(AS.entry_kind("bogus"))

def entry_kinds__want() -> String:
  "1,2,2,2,2,0"

def sx_inst_ok__got() -> String:
  er_tag(AS.inst_of(sl([sa("inst"), sa("a"), sa("1"), sa("0"), sa("0"), sa("0"), sa("0")])))

def sx_inst_ok__want() -> String:
  "inst"

def sx_inst_bad__got() -> String:
  er_tag(AS.inst_of(sl([sa("inst"), sa("a")])))

def sx_inst_bad__want() -> String:
  "bad-instance"

def sx_fix_ok__got() -> String:
  er_tag(AS.mate_of(sl([sa("fix"), sa("1"), sa("a")])))

def sx_fix_ok__want() -> String:
  "mate:1"

def sx_coinc_ok__got() -> String:
  er_tag(AS.mate_of(sl([sa("coinc"), sa("1"), sa("a"), sa("0"), sa("0"), sa("0"), sa("b"), sa("1"), sa("1"), sa("1")])))

def sx_coinc_ok__want() -> String:
  "mate:2"

def sx_plane_ok__got() -> String:
  er_tag(AS.mate_of(sl([sa("plane"), sa("1"), sa("a"), sa("0"), sa("0"), sa("0"), sa("0"), sa("0"), sa("1"), sa("5")])))

def sx_plane_ok__want() -> String:
  "mate:3"

def sx_axis_ok__got() -> String:
  er_tag(AS.mate_of(sl([sa("axis"), sa("1"), sa("a"), sa("0"), sa("0"), sa("0"), sa("1"), sa("2"), sa("3"), sa("0"), sa("0"), sa("1")])))

def sx_axis_ok__want() -> String:
  "mate:4"

def sx_mate_unknown__got() -> String:
  er_tag(AS.mate_of(sl([sa("spin"), sa("1"), sa("a")])))

def sx_mate_unknown__want() -> String:
  "unknown-mate"

def idx_vals__got() -> String:
  +il = iab()
  bs(AS.inst_has(il, "a")) ++ "," ++ bs(AS.inst_has(il, "z")) ++ "," ++ AS.inst_name(AS.inst_at(il, "b")) ++ "," ++ AS.inst_name(AS.inst_at(il, "z")) ++ "," ++ Nat.show(AS.inst_idx(il, "a", 0n)) ++ "," ++ Nat.show(AS.inst_idx(il, "b", 0n)) ++ "," ++ Nat.show(AS.inst_idx(il, "z", 0n))

def idx_vals__want() -> String:
  "1,0,b,,0,1,2"

def join_empty__got() -> String:
  ar_why(AS.asm_join([], AS.MR_ok{[]}))

def join_empty__want() -> String:
  "assembly-needs-instance"

def join_ok__got() -> String:
  ar_counts(AS.asm_join([ia0()], AS.MR_ok{[]}))

def join_ok__want() -> String:
  "1/0"

def join_merr__got() -> String:
  ar_why(AS.asm_join([ia0()], AS.MR_err{"w", "f"}))

def join_merr__want() -> String:
  "w"

def ir_ok__got() -> String:
  ar_counts(AS.asm_ir(AS.IR_ok{[ia0()]}, []))

def ir_ok__want() -> String:
  "1/0"

def ir_err__got() -> String:
  ar_why(AS.asm_ir(AS.IR_err{"w", "f"}, []))

def ir_err__want() -> String:
  "w"

def ps_no__got() -> String:
  ar_why(AS.asm_ps(S.PS{False{}, []}))

def ps_no__want() -> String:
  "assembly-parse-failed"

def ps_yes_empty__got() -> String:
  ar_why(AS.asm_ps(S.PS{True{}, []}))

def ps_yes_empty__want() -> String:
  "assembly-parse-failed"

def ps_yes_asm__got() -> String:
  ar_why(AS.asm_ps(S.PS{True{}, [sl([sa("assembly")])]}))

def ps_yes_asm__want() -> String:
  "assembly-needs-instance"

def ps_empty__got() -> String:
  ar_why(AS.asm_parse(""))

def ps_empty__want() -> String:
  "assembly-parse-failed"

def ps_bare__got() -> String:
  ar_why(AS.asm_parse("(assembly)"))

def ps_bare__want() -> String:
  "assembly-needs-instance"

def ps_two__got() -> String:
  ar_why(AS.asm_parse("(assembly (inst a 1 0 0 0 0)) (assembly (inst b 2 0 0 0 0))"))

def ps_two__want() -> String:
  "assembly-parse-failed"

def ps_nohead__got() -> String:
  ar_why(AS.asm_parse("(fix 1 a)"))

def ps_nohead__want() -> String:
  "assembly-parse-failed"

def ps_ok1__got() -> String:
  ar_counts(AS.asm_parse("(assembly (inst a 1 0 0 0 0))"))

def ps_ok1__want() -> String:
  "1/0"

def ps_ok2__got() -> String:
  ar_counts(AS.asm_parse("(assembly (inst a 1 0 0 0 0) (inst b 2 1 2 3 1) (fix 7 a) (fix 8 b))"))

def ps_ok2__want() -> String:
  "2/2"

def ps_dup__got() -> String:
  ar_why(AS.asm_parse("(assembly (inst a 1 0 0 0 0) (inst a 2 0 0 0 0))"))

def ps_dup__want() -> String:
  "duplicate-instance"

def ps_badinst_q__got() -> String:
  ar_why(AS.asm_parse("(assembly (inst a 1 0 0 0 9))"))

def ps_badinst_q__want() -> String:
  "bad-instance"

def ps_badinst_len__got() -> String:
  ar_why(AS.asm_parse("(assembly (inst a 1 0 0 0))"))

def ps_badinst_len__want() -> String:
  "bad-instance"

def ps_unknown_entry__got() -> String:
  ar_why(AS.asm_parse("(assembly (inst a 1 0 0 0 0) (bogus 1 2))"))

def ps_unknown_entry__want() -> String:
  "unknown-assembly-entry"

def ps_unknown_mate__got() -> String:
  ar_why(AS.asm_parse("(assembly (inst a 1 0 0 0 0) (frobnicate 1 a))"))

def ps_unknown_mate__want() -> String:
  "unknown-assembly-entry"

def ps_badmate__got() -> String:
  ar_why(AS.asm_parse("(assembly (inst a 1 0 0 0 0) (fix 1))"))

def ps_badmate__want() -> String:
  "bad-mate"

def ps_unknown_inst__got() -> String:
  ar_why(AS.asm_parse("(assembly (inst a 1 0 0 0 0) (fix 1 b))"))

def ps_unknown_inst__want() -> String:
  "unknown-instance"

def ps_coinc_self__got() -> String:
  ar_why(AS.asm_parse("(assembly (inst a 1 0 0 0 0) (coinc 1 a 0 0 0 a 1 1 1))"))

def ps_coinc_self__want() -> String:
  "bad-mate"

def ps_plane_zeron__got() -> String:
  ar_why(AS.asm_parse("(assembly (inst a 1 0 0 0 0) (plane 1 a 0 0 0 0 0 0 5))"))

def ps_plane_zeron__want() -> String:
  "bad-mate"

def ps_axis_zerod__got() -> String:
  ar_why(AS.asm_parse("(assembly (inst a 1 0 0 0 0) (axis 1 a 0 0 0 1 2 3 0 0 0))"))

def ps_axis_zerod__want() -> String:
  "bad-mate"

def ps_coinc_ok__got() -> String:
  ar_counts(AS.asm_parse("(assembly (inst a 1 0 0 0 0) (inst b 2 0 0 0 0) (coinc 3 a 1 2 3 b 4 5 6))"))

def ps_coinc_ok__want() -> String:
  "2/1"

def ps_plane_ok__got() -> String:
  ar_counts(AS.asm_parse("(assembly (inst a 1 0 0 0 0) (plane 3 a 1 2 3 0 0 1 9))"))

def ps_plane_ok__want() -> String:
  "1/1"

def ps_axis_ok__got() -> String:
  ar_counts(AS.asm_parse("(assembly (inst a 1 0 0 0 0) (axis 4 a 1 2 3 0 0 0 0 0 1))"))

def ps_axis_ok__want() -> String:
  "1/1"

def col_layout__got() -> String:
  Nat.show(U32.to_nat(AS.col_of(0n, 0n))) ++ "," ++ Nat.show(U32.to_nat(AS.col_of(0n, 1n))) ++ "," ++ Nat.show(U32.to_nat(AS.col_of(0n, 2n))) ++ "," ++ Nat.show(U32.to_nat(AS.col_of(1n, 0n))) ++ "," ++ Nat.show(U32.to_nat(AS.col_of(2n, 1n)))

def col_layout__want() -> String:
  "0,1,2,3,7"

def node_off_id__got() -> F64:
  AS.node_off([], 99u64, 0u64, 1.0f64, 2.0f64, 3.0f64, 1n)

def node_off_id__want() -> F64:
  2.0f64

def node_off_rot__got() -> F64:
  AS.node_off([], 99u64, 1u64, 1.0f64, 2.0f64, 3.0f64, 0n)

def node_off_rot__want() -> F64:
  F64.neg(2.0f64)

def sv_put_zero__got() -> Nat:
  List.length(&2, Q.Sv, AS.sv_put(0.0f64, AS.col_of(0n, 0n), []))

def sv_put_zero__want() -> Nat:
  0n

def sv_put_one__got() -> Nat:
  List.length(&2, Q.Sv, AS.sv_put(1.0f64, AS.col_of(0n, 0n), []))

def sv_put_one__want() -> Nat:
  1n

def rows_fix_len__got() -> Nat:
  List.length(&2, SL.Dr, AS.rows_fix(7u64, 2n, pinst("a", 1u64, 1.0f64, 2.0f64, 3.0f64, 0u64)))

def rows_fix_len__want() -> Nat:
  3n

def rows_fix_r0__got() -> F64:
  SL.dr_r(dr_nth(AS.rows_fix(7u64, 2n, pinst("a", 1u64, 1.0f64, 2.0f64, 3.0f64, 0u64)), 0n))

def rows_fix_r0__want() -> F64:
  F64.neg(1.0f64)

def rows_fix_c1__got() -> Nat:
  sv_head_c(SL.dr_v(dr_nth(AS.rows_fix(7u64, 2n, pinst("a", 1u64, 1.0f64, 2.0f64, 3.0f64, 0u64)), 1n)))

def rows_fix_c1__want() -> Nat:
  7n

def rows_fix_v2__got() -> F64:
  sv_head_v(SL.dr_v(dr_nth(AS.rows_fix(7u64, 2n, pinst("a", 1u64, 1.0f64, 2.0f64, 3.0f64, 0u64)), 2n)))

def rows_fix_v2__want() -> F64:
  1.0f64

def coinc_xs_neg__got() -> F64:
  sv_head_v(AS.coinc_xs(0n, 1n, 2n))

def coinc_xs_neg__want() -> F64:
  F64.neg(1.0f64)

def coinc_xs_pos__got() -> F64:
  sv_head_v(AS.coinc_xs(1n, 0n, 2n))

def coinc_xs_pos__want() -> F64:
  1.0f64

def coinc_xs_col__got() -> Nat:
  sv_head_c(AS.coinc_xs(1n, 0n, 2n))

def coinc_xs_col__want() -> Nat:
  2n

def coinc_c0__got() -> F64:
  AS.coinc_c([], ia0(), ib0(), [1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64], 0n)

def coinc_c0__want() -> F64:
  F64.neg(3.0f64)

def rows_coinc_len__got() -> Nat:
  List.length(&2, SL.Dr, AS.rows_coinc(pmate(5u64, 2u64, "a", "b", [1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64]), [ia0(), ib0()], []))

def rows_coinc_len__want() -> Nat:
  3n

def rows_coinc_r1__got() -> F64:
  SL.dr_r(dr_nth(AS.rows_coinc(pmate(5u64, 2u64, "a", "b", [1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64]), [ia0(), ib0()], []), 1n))

def rows_coinc_r1__want() -> F64:
  3.0f64

def rows_plane_len__got() -> Nat:
  List.length(&2, SL.Dr, AS.rows_plane(pmate(3u64, 3u64, "", "a", [1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 1.0f64, 9.0f64]), [ia0()], []))

def rows_plane_len__want() -> Nat:
  1n

def rows_plane_r__got() -> F64:
  SL.dr_r(dr_nth(AS.rows_plane(pmate(3u64, 3u64, "", "a", [1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 1.0f64, 9.0f64]), [ia0()], []), 0n))

def rows_plane_r__want() -> F64:
  F64.neg(6.0f64)

def rows_plane_nv__got() -> Nat:
  List.length(&2, Q.Sv, SL.dr_v(dr_nth(AS.rows_plane(pmate(3u64, 3u64, "", "a", [1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 1.0f64, 9.0f64]), [ia0()], []), 0n)))

def rows_plane_nv__want() -> Nat:
  1n

def axpick_vals__got() -> String:
  U64.show(AS.ax_pick(1.0f64, 0.0f64, 0.0f64)) ++ "," ++ U64.show(AS.ax_pick(1.0f64, 1.0f64, 0.0f64)) ++ "," ++ U64.show(AS.ax_pick(0.0f64, 0.0f64, 1.0f64))

def axpick_vals__want() -> String:
  "1,2,0"

def axe1_head__got() -> String:
  +u = AS.ax_e1(0.0f64, 0.0f64, 1.0f64, 0u64)
  S.f_show(M.f_nth(u, 0n)) ++ "," ++ S.f_show(M.f_nth(u, 1n))

def axe1_head__want() -> String:
  "0,1"

def axe1_negzero__got() -> Bool:
  U64.is_eq(F64.bits(M.f_nth(AS.ax_e1(0.0f64, 0.0f64, 1.0f64, 0u64), 2n)), F64.bits(F64.neg(0.0f64)))

def axe1_negzero__want() -> Bool:
  True{}

def vnorm345__got() -> F64:
  AS.vnorm3(3.0f64, 4.0f64, 0.0f64)

def vnorm345__want() -> F64:
  5.0f64

def rows_axis_len__got() -> Nat:
  List.length(&2, SL.Dr, AS.rows_axis(pmate(4u64, 4u64, "", "a", [1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64]), [ia0()], []))

def rows_axis_len__want() -> Nat:
  2n

def rows_axis_r0__got() -> F64:
  SL.dr_r(dr_nth(AS.rows_axis(pmate(4u64, 4u64, "", "a", [1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64]), [ia0()], []), 0n))

def rows_axis_r0__want() -> F64:
  2.0f64

def rows_axis_r1__got() -> F64:
  SL.dr_r(dr_nth(AS.rows_axis(pmate(4u64, 4u64, "", "a", [1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64]), [ia0()], []), 1n))

def rows_axis_r1__want() -> F64:
  F64.neg(1.0f64)

def mate_rows_lens__got() -> String:
  +il = iab()
  Nat.show(List.length(&2, SL.Dr, AS.mate_rows(pmate(1u64, 1u64, "", "a", []), il, []))) ++ "," ++ Nat.show(List.length(&2, SL.Dr, AS.mate_rows(pmate(2u64, 2u64, "a", "b", [1.0f64, 2.0f64, 3.0f64, 4.0f64, 5.0f64, 6.0f64]), il, []))) ++ "," ++ Nat.show(List.length(&2, SL.Dr, AS.mate_rows(pmate(3u64, 3u64, "", "b", [1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 1.0f64, 9.0f64]), il, []))) ++ "," ++ Nat.show(List.length(&2, SL.Dr, AS.mate_rows(pmate(4u64, 4u64, "", "b", [1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64]), il, []))) ++ "," ++ Nat.show(List.length(&2, SL.Dr, AS.mate_rows(pmate(9u64, 99u64, "", "b", [1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64]), il, [])))

def mate_rows_lens__want() -> String:
  "3,3,1,2,2"

def asm_rows_len__got() -> Nat:
  List.length(&2, SL.Dr, AS.asm_rows([pmate(1u64, 1u64, "", "a", []), pmate(2u64, 1u64, "", "a", [])], [ia0()], []))

def asm_rows_len__want() -> Nat:
  6n

def asm_rows_nil__got() -> Nat:
  List.length(&2, SL.Dr, AS.asm_rows([], [ia0()], []))

def asm_rows_nil__want() -> Nat:
  0n

def decl_len__got() -> Nat:
  List.length(&2, F64, AS.decl_ts([pinst("a", 1u64, 1.0f64, 2.0f64, 3.0f64, 0u64), pinst("b", 2u64, 4.0f64, 5.0f64, 6.0f64, 0u64)]))

def decl_len__want() -> Nat:
  6n

def decl_nth__got() -> F64:
  M.f_nth(AS.decl_ts([pinst("a", 1u64, 1.0f64, 2.0f64, 3.0f64, 0u64), pinst("b", 2u64, 4.0f64, 5.0f64, 6.0f64, 0u64)]), 3n)

def decl_nth__want() -> F64:
  4.0f64

def nd_pm_inverse__got() -> U32:
  P.tb_get(U32, AS.nd_pm(Q.ND{[2, 0, 1], Q.NL{3}}, 3), 0)

def nd_pm_inverse__want() -> U32:
  1

def ev_xs0__got() -> F64:
  AS.ev_xs([], [1.0f64])

def ev_xs0__want() -> F64:
  0.0f64

def ev_xs1__got() -> F64:
  AS.ev_xs([Q.Sv{AS.col_of(0n, 0n), 2.0f64}], [3.0f64, 4.0f64])

def ev_xs1__want() -> F64:
  6.0f64

def row_res1__got() -> F64:
  AS.row_res(SL.Dr{1u64, 1.0f64, []}, [])

def row_res1__want() -> F64:
  1.0f64

def maxres_nil__got() -> F64:
  AS.maxres_go([], [], 5.0f64)

def maxres_nil__want() -> F64:
  5.0f64

def maxres_cons__got() -> F64:
  AS.maxres_go([SL.Dr{1u64, 1.0f64, []}], [], 0.0f64)

def maxres_cons__want() -> F64:
  1.0f64

def rowbad_yes__got() -> Bool:
  AS.row_bad(SL.Dr{7u64, 1.0f64, []}, [])

def rowbad_yes__want() -> Bool:
  True{}

def rowbad_no__got() -> Bool:
  AS.row_bad(SL.Dr{8u64, 0.0f64, []}, [])

def rowbad_no__want() -> Bool:
  False{}

def rowbad_tiny__got() -> Bool:
  AS.row_bad(SL.Dr{9u64, 0.000000000001f64, []}, [])

def rowbad_tiny__want() -> Bool:
  False{}

def uadd_vals__got() -> String:
  AS.ids_show(AS.u_add([7u64], 3u64)) ++ ";" ++ AS.ids_show(AS.u_add([7u64], 7u64)) ++ ";" ++ bs(AS.u_has([7u64], 7u64)) ++ bs(AS.u_has([7u64], 8u64)) ++ ";" ++ AS.ids_show(AS.viol_go([SL.Dr{7u64, 1.0f64, []}, SL.Dr{8u64, 0.0f64, []}, SL.Dr{7u64, 2.0f64, []}], [], [])) ++ ";" ++ AS.ids_show(AS.viol_go([], [], []))

def uadd_vals__want() -> String:
  "[3,7];[7];10;[7];[]"

def redup_nil__got() -> String:
  AS.ids_show(AS.redup([], P.tb_of(U64, [7u64], 0u64), [5u64]))

def redup_nil__want() -> String:
  "[5]"

def redup_one__got() -> String:
  AS.ids_show(AS.redup([AS.col_of(0n, 0n)], P.tb_of(U64, [7u64], 0u64), []))

def redup_one__want() -> String:
  "[7]"

def ndt_val__got() -> Nat:
  U32.to_nat(Q.nt_n(AS.nd_t(Q.ND{[], Q.NL{AS.col_of(0n, 2n)}})))

def ndt_val__want() -> Nat:
  2n

def verdict_ok__got() -> Bool:
  as_ok(AS.asm_verdict(0n, [], [1.0f64], 0.0f64, []))

def verdict_ok__want() -> Bool:
  True{}

def verdict_conf__got() -> String:
  as_viol(AS.asm_verdict(0n, [], [], 0.0f64, [7u64]))

def verdict_conf__want() -> String:
  "[7]"

def verdict_conf_res__got() -> F64:
  as_res(AS.asm_verdict(0n, [], [], 1.5f64, [7u64]))

def verdict_conf_res__want() -> F64:
  1.5f64

def solve_free_dof__got() -> Nat:
  as_dof(AS.asm_solve(pasm([pinst("a", 1u64, 1.0f64, 2.0f64, 3.0f64, 0u64)], []), []))

def solve_free_dof__want() -> Nat:
  3n

def solve_free_x__got() -> String:
  +s = AS.asm_solve(pasm([pinst("a", 1u64, 1.0f64, 2.0f64, 3.0f64, 0u64)], []), [])
  S.f_show(as_x(s, 0n)) ++ "," ++ S.f_show(as_x(s, 1n)) ++ "," ++ S.f_show(as_x(s, 2n)) ++ "," ++ S.f_show(as_res(s)) ++ "," ++ bs(as_ok(s)) ++ "," ++ as_red(s)

def solve_free_x__want() -> String:
  "1,2,3,0,1,[]"

def solve_fix_dof__got() -> Nat:
  as_dof(AS.asm_solve(pasm([pinst("a", 1u64, 1.0f64, 2.0f64, 3.0f64, 0u64)], [pmate(1u64, 1u64, "", "a", [])]), []))

def solve_fix_dof__want() -> Nat:
  0n

def solve_fix_x__got() -> String:
  +s = AS.asm_solve(pasm([pinst("a", 1u64, 1.0f64, 2.0f64, 3.0f64, 0u64)], [pmate(1u64, 1u64, "", "a", [])]), [])
  S.f_show(as_x(s, 0n)) ++ "," ++ S.f_show(as_x(s, 1n)) ++ "," ++ S.f_show(as_x(s, 2n))

def solve_fix_x__want() -> String:
  "1,2,3"

def solve_fix_clean__got() -> String:
  +s = AS.asm_solve(pasm([pinst("a", 1u64, 1.0f64, 2.0f64, 3.0f64, 0u64)], [pmate(1u64, 1u64, "", "a", [])]), [])
  S.f_show(as_res(s)) ++ "," ++ as_red(s) ++ "," ++ as_viol(s) ++ "," ++ bs(as_ok(s))

def solve_fix_clean__want() -> String:
  "0,[],ok,1"

def solve_2fix__got() -> String:
  +s = AS.asm_solve(pasm([pinst("a", 1u64, 1.0f64, 2.0f64, 3.0f64, 0u64)], [pmate(1u64, 1u64, "", "a", []), pmate(2u64, 1u64, "", "a", [])]), [])
  Nat.show(as_dof(s)) ++ "," ++ as_red(s) ++ "," ++ as_viol(s) ++ "," ++ bs(as_ok(s))

def solve_2fix__want() -> String:
  "0,[2],ok,1"

def solve_conflict__got() -> String:
  +s = AS.asm_solve(pasm([ia0()], [pmate(1u64, 3u64, "", "a", [0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64]), pmate(2u64, 3u64, "", "a", [0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 10.0f64])]), [])
  bs(as_ok(s)) ++ "," ++ as_viol(s) ++ "," ++ bs(F64.is_lt(4.0f64, as_res(s))) ++ bs(F64.is_lt(as_res(s), 6.0f64))

def solve_conflict__want() -> String:
  "0,[1,2],11"

def solve_coinc_free__got() -> String:
  +s = AS.asm_solve(pasm([ia0(), ib0()], [pmate(5u64, 2u64, "a", "b", [0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64])]), [])
  bs(as_ok(s)) ++ "," ++ Nat.show(as_dof(s)) ++ "," ++ as_viol(s)

def solve_coinc_free__want() -> String:
  "1,3,ok"

def ids_vals__got() -> String:
  AS.ids_show([]) ++ ";" ++ AS.ids_show([7u64]) ++ ";" ++ AS.ids_show([1u64, 2u64]) ++ ";" ++ AS.ids_tail([2u64, 3u64])

def ids_vals__want() -> String:
  "[];[7];[1,2];,2,3"

def mate_ids_show__got() -> String:
  AS.ids_show(AS.mate_ids([pmate(1u64, 1u64, "", "a", []), pmate(2u64, 1u64, "", "a", [])]))

def mate_ids_show__want() -> String:
  "[1,2]"

def lin_vals__got() -> String:
  AS.lin_go([ia0(), ib0()], True{}) ++ ";" ++ AS.lin_go([], True{})

def lin_vals__want() -> String:
  "a=n1,b=n2;"

def lineage_full__got() -> String:
  AS.lineage([ia0(), ib0()], [pmate(1u64, 1u64, "", "a", []), pmate(2u64, 1u64, "", "b", [])])

def lineage_full__want() -> String:
  "lineage asm(a=n1,b=n2) mates[1,2]\n"

def inst_line_full__got() -> String:
  AS.inst_line(ia0(), 1.0f64, 2.0f64, 3.0f64)

def inst_line_full__want() -> String:
  "inst a node 1 t=1 2 3 q=0\n"

def insts_rep_vals__got() -> String:
  AS.insts_rep([], [1.0f64], 0n) ++ ";" ++ AS.insts_rep([ia0()], [1.0f64, 2.0f64, 3.0f64], 0n)

def insts_rep_vals__want() -> String:
  ";inst a node 1 t=1 2 3 q=0\n"

def solve_rep_solved_full__got() -> String:
  AS.solve_rep(pasm([ia0()], []), [1.0f64, 2.0f64, 3.0f64], 0n, [], 0.0f64)

def solve_rep_solved_full__want() -> String:
  "asm solved ninst 1 nmates 0 dof 0 max-residual 0\ninst a node 1 t=1 2 3 q=0\nredundant []\nlineage asm(a=n1) mates[]\n"

def solve_rep_under_full__got() -> String:
  AS.solve_rep(pasm([ia0()], [pmate(9u64, 3u64, "", "a", [])]), [1.0f64, 2.0f64, 3.0f64], 3n, [4u64], 0.0f64)

def solve_rep_under_full__want() -> String:
  "asm underconstrained ninst 1 nmates 1 dof 3 max-residual 0\ninst a node 1 t=1 2 3 q=0\nredundant [4]\nlineage asm(a=n1) mates[9]\n"

def conf_rep_full__got() -> String:
  AS.conf_rep(pasm([ia0()], [pmate(7u64, 3u64, "", "a", [])]), [7u64], 1.5f64)

def conf_rep_full__want() -> String:
  "asm conflict ninst 1 nmates 1 viol [7] max-residual 1.5 | fix: loosen or correct the violating mates"

def explode_rep_full__got() -> String:
  AS.explode_rep(pasm([ia0(), ib0()], []), [0.0f64, 0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64], [0.0f64, 0.0f64, 1.0f64, 5.0f64])

def explode_rep_full__want() -> String:
  "asm exploded ninst 2 dir=0 0 1 gap=5\ninst a node 1 t=0 0 0 q=0\ninst b node 2 t=10 0 5 q=0\n"

def explode_go_nil__got() -> String:
  AS.explode_go([], [0.0f64], 0n, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 5.0f64)

def explode_go_nil__want() -> String:
  ""

def afn_vals__got() -> String:
  AS.afn_s(BD.Fn{3u64, 1n, 4u64, 2n, 5n}, "a.") ++ ";" ++ AS.afn_s(BD.Fn{3u64, 1n, 0u64, 2n, 5n}, "a.") ++ ";" ++ AS.afn_s(BD.Fn{3u64, 1n, 1u64, 2n, 5n}, "a.") ++ ";" ++ AS.afn_s(BD.Fn{3u64, 1n, 2u64, 2n, 5n}, "a.")

def afn_vals__want() -> String:
  "a.n3.cav.1.2.5;a.n3.c1.top;a.n3.c1.bottom;a.n3.c1.wall.2.5"

def asurf_vals__got() -> String:
  AS.asurf_s(G.GV_pl{G.Pl{pt0(), dz0(), dz0()}}) ++ "," ++ AS.asurf_s(G.GV_cy{G.Cy{pt0(), dz0(), 1.0f64}}) ++ "," ++ AS.asurf_s(G.GV_bp{bp0()}) ++ "," ++ AS.asurf_s(G.GV_sp{G.Sp{pt0(), 1.0f64}}) ++ "," ++ AS.asurf_s(G.GV_co{G.Co{pt0(), dz0(), 1.0f64}}) ++ "," ++ AS.asurf_s(G.GV_to{G.To{pt0(), dz0(), 2.0f64, 1.0f64}}) ++ "," ++ AS.asurf_s(G.GV_f{1.0f64})

def asurf_vals__want() -> String:
  "plane,cylinder,planar-patch,sphere,cone,torus,other"

def afaces_vals__got() -> String:
  AS.afaces_go([], [], "a.") ++ ";" ++ AS.afaces_go([BD.Fn{3u64, 1n, 0u64, 0n, 0n}], [Ty.Fa{0u64, plsurf(), [], True{}}], "a.")

def afaces_vals__want() -> String:
  ";a.n3.c1.top plane loops=0\n"

def faces_unknown__got() -> String:
  AS.faces_rep(pasm([ia0()], []), [0.0f64, 0.0f64, 0.0f64], [], "b")

def faces_unknown__want() -> String:
  "error invalid-input | asm faces | why: unknown-instance b | fix: name an instance from the assembly"

def faces_empty__got() -> String:
  AS.faces_rep(pasm([ia0()], []), [0.0f64, 0.0f64, 0.0f64], [], "a")

def faces_empty__want() -> String:
  ""

def ok_solve_full__got() -> String:
  AS.ok_out(pasm([ia0()], []), [1.0f64, 2.0f64, 3.0f64], 0n, [], 0.0f64, [], AS.RQ{1u64, "", []})

def ok_solve_full__want() -> String:
  "asm solved ninst 1 nmates 0 dof 0 max-residual 0\ninst a node 1 t=1 2 3 q=0\nredundant []\nlineage asm(a=n1) mates[]\n"

def ok_explode_full__got() -> String:
  AS.ok_out(pasm([ia0()], []), [1.0f64, 2.0f64, 3.0f64], 0n, [], 0.0f64, [], AS.RQ{4u64, "", [0.0f64, 0.0f64, 1.0f64, 5.0f64]})

def ok_explode_full__want() -> String:
  "asm exploded ninst 1 dir=0 0 1 gap=5\ninst a node 1 t=1 2 3 q=0\n"

def ok_faces_def__got() -> String:
  AS.ok_out(pasm([ia0()], []), [0.0f64, 0.0f64, 0.0f64], 0n, [], 0.0f64, [], AS.RQ{9u64, "b", []})

def ok_faces_def__want() -> String:
  "error invalid-input | asm faces | why: unknown-instance b | fix: name an instance from the assembly"

def ok_faces5__got() -> String:
  AS.ok_out(pasm([ia0()], []), [0.0f64, 0.0f64, 0.0f64], 0n, [], 0.0f64, [], AS.RQ{5u64, "a", []})

def ok_faces5__want() -> String:
  ""

def out_conf_full__got() -> String:
  AS.asm_out(pasm([ia0()], [pmate(7u64, 3u64, "", "a", [])]), AS.AS_conf{[7u64], 1.5f64}, [], rq1())

def out_conf_full__want() -> String:
  "asm conflict ninst 1 nmates 1 viol [7] max-residual 1.5 | fix: loosen or correct the violating mates"

def out_ok_full__got() -> String:
  AS.asm_out(pasm([ia0()], []), AS.AS_ok{[1.0f64, 2.0f64, 3.0f64], 0n, [], 0.0f64}, [], rq1())

def out_ok_full__want() -> String:
  "asm solved ninst 1 nmates 0 dof 0 max-residual 0\ninst a node 1 t=1 2 3 q=0\nredundant []\nlineage asm(a=n1) mates[]\n"

def nodes_vals__got() -> String:
  AS.nodes_ce(False{}, True{}, ia0(), "rec") ++ ";" ++ AS.nodes_ce(True{}, False{}, pinst("a", 5u64, 0.0f64, 0.0f64, 0.0f64, 0u64), "rec") ++ ";" ++ AS.nodes_ce(True{}, True{}, ia0(), "REC") ++ ";" ++ AS.nodes_err([], [], [])

def nodes_vals__want() -> String:
  "error invalid-input | asm | why: unknown-node a | fix: name a node from the design (eval);error: node 5; nothing assembled;REC;"

def nodes_err_fail__got() -> String:
  AS.nodes_err([ia0()], [], [M.CE{1u64, [], M.bad("w", "l", "y", "f")}])

def nodes_err_fail__want() -> String:
  "error: node 1; nothing assembled"

def nodes_err_ok__got() -> String:
  AS.nodes_err([ia0()], [], [M.CE{1u64, [], empty_nr()}])

def nodes_err_ok__want() -> String:
  ""

def q_parse_err__got() -> String:
  AS.asm_q_go(empty_part(), AS.AR_err{"w", "f"}, rq1())

def q_parse_err__want() -> String:
  "error invalid-input | asm | why: w | fix: f"

def q_unknown_node__got() -> String:
  AS.asm_q_go(empty_part(), AS.AR_ok{pasm([ia0()], [])}, rq1())

def q_unknown_node__want() -> String:
  "error invalid-input | asm | why: unknown-node a | fix: name a node from the design (eval)"

def ex_ok_vals__got() -> String:
  bs(AS.ex_ok(0.0f64, 0.0f64, 1.0f64, 5.0f64)) ++ bs(AS.ex_ok(0.0f64, 0.0f64, 0.0f64, 5.0f64)) ++ bs(AS.ex_ok(0.0f64, 0.0f64, 1.0f64, F64.nan()))

def ex_ok_vals__want() -> String:
  "100"

def explode_go_no__got() -> String:
  AS.asm_explode_go(False{}, empty_part(), [], 0.0f64, 0.0f64, 0.0f64, 0.0f64)

def explode_go_no__want() -> String:
  "error invalid-input | asm explode | why: need DX DY DZ GAP finite with a nonzero direction | fix: asm explode DX DY DZ GAP (assembly ...)"

def explode_go_yes__got() -> String:
  AS.asm_explode_go(True{}, empty_part(), ["explode", "0", "0", "1", "5", "(assembly (inst a 1 0 0 0 0))"], 0.0f64, 0.0f64, 1.0f64, 5.0f64)

def explode_go_yes__want() -> String:
  "error invalid-input | asm | why: unknown-node a | fix: name a node from the design (eval)"

def explode_v_full__got() -> String:
  AS.asm_explode_v(empty_part(), ["explode", "0", "0", "1", "5", "(assembly (inst a 1 0 0 0 0))"])

def explode_v_full__want() -> String:
  "error invalid-input | asm | why: unknown-node a | fix: name a node from the design (eval)"

def explode_v_bad__got() -> String:
  AS.asm_explode_v(empty_part(), ["explode", "0", "0", "0", "5", "(assembly (inst a 1 0 0 0 0))"])

def explode_v_bad__want() -> String:
  "error invalid-input | asm explode | why: need DX DY DZ GAP finite with a nonzero direction | fix: asm explode DX DY DZ GAP (assembly ...)"

def faces_go_needy__got() -> String:
  AS.asm_faces_go(True{}, empty_part(), [], "")

def faces_go_needy__want() -> String:
  "error invalid-input | asm faces | why: need an instance name | fix: asm faces INST (assembly ...)"

def faces_go_yes__got() -> String:
  AS.asm_faces_go(False{}, empty_part(), ["faces", "b", "(assembly (inst a 1 0 0 0 0))"], "b")

def faces_go_yes__want() -> String:
  "error invalid-input | asm | why: unknown-node a | fix: name a node from the design (eval)"

def faces_v_full__got() -> String:
  AS.asm_faces_v(empty_part(), ["faces", "b", "(assembly (inst a 1 0 0 0 0))"])

def faces_v_full__want() -> String:
  "error invalid-input | asm | why: unknown-node a | fix: name a node from the design (eval)"

def faces_v_needy__got() -> String:
  AS.asm_faces_v(empty_part(), ["faces"])

def faces_v_needy__want() -> String:
  "error invalid-input | asm faces | why: need an instance name | fix: asm faces INST (assembly ...)"

def verb_codes__got() -> String:
  U64.show(AS.verb_code("solve")) ++ "," ++ U64.show(AS.verb_code("interf")) ++ "," ++ U64.show(AS.verb_code("clear")) ++ "," ++ U64.show(AS.verb_code("explode")) ++ "," ++ U64.show(AS.verb_code("faces")) ++ "," ++ U64.show(AS.verb_code("bogus"))

def verb_codes__want() -> String:
  "1,2,3,4,5,0"

def verb_solve_empty__got() -> String:
  AS.asm_verb(1u64, empty_part(), ["solve"])

def verb_solve_empty__want() -> String:
  "error invalid-input | asm | why: assembly-parse-failed | fix: write one (assembly ...) form"

def verb_unknown__got() -> String:
  AS.asm_verb(99u64, empty_part(), ["bogus"])

def verb_unknown__want() -> String:
  "error invalid-input | asm | why: unknown verb | fix: asm solve|interf|clear|explode|faces ..."

def go_bogus__got() -> String:
  AS.asm_go(empty_part(), ["bogus"])

def go_bogus__want() -> String:
  "error invalid-input | asm | why: unknown verb | fix: asm solve|interf|clear|explode|faces ..."

def go_solve_empty__got() -> String:
  AS.asm_go(empty_part(), ["solve"])

def go_solve_empty__want() -> String:
  "error invalid-input | asm | why: assembly-parse-failed | fix: write one (assembly ...) form"

def go_interf_parse__got() -> String:
  AS.asm_go(empty_part(), ["interf", "(assembly (inst a 1 0 0 0))"])

def go_interf_parse__want() -> String:
  "error invalid-input | asm | why: bad-instance | fix: write (inst NAME NODE TX TY TZ Q) with finite numbers and a turn code 0-5"

def pairs_nil__got() -> String:
  AS.pairs_go([], False{}) ++ ";" ++ AS.pairs_inner(AS.IN{ia0(), empty_nr()}, [], True{})

def pairs_nil__want() -> String:
  ";"

def place_lens__got() -> String:
  Nat.show(List.length(&2, AS.IN, AS.place_all([], [1.0f64], [], 0n))) ++ "," ++ Nat.show(List.length(&2, AS.IN, AS.place_all([ia0()], [1.0f64, 2.0f64, 3.0f64], [], 0n)))

def place_lens__want() -> String:
  "0,1"

def inst_nr_err__got() -> Bool:
  M.nr_ok(AS.inst_nr([], ia0(), 1.0f64, 2.0f64, 3.0f64))

def inst_nr_err__want() -> Bool:
  False{}

def placed_vals__got() -> String:
  bs(M.nr_ok(AS.placed_nr(M.bad("w", "l", "y", "f"), 0u64, 1.0f64, 2.0f64, 3.0f64))) ++ "," ++ S.f_show(M.pl_tx(M.bd_pl(M.nr_body(AS.placed_nr(empty_nr(), 0u64, 1.0f64, 2.0f64, 3.0f64)))))

def placed_vals__want() -> String:
  "0,1"

def mate_ref_vals__got() -> String:
  +il = iab()
  bs(AS.mate_ref_ok(pmate(1u64, 1u64, "", "a", []), il)) ++ "," ++ bs(AS.mate_ref_ok(pmate(1u64, 1u64, "", "z", []), il)) ++ "," ++ bs(AS.mate_ref_ok(pmate(2u64, 2u64, "a", "b", []), il))

def mate_ref_vals__want() -> String:
  "1,0,1"
