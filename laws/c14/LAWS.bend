import Base
import ../../src/c00/types.bend as T
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/base/par.bend as P
import ../../src/c05/sqr.bend as Q
import ../../src/c05/solve.bend as SL
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c06/build.bend as BD
import ../../src/c11/qdist.bend as QD
import ../../src/c11/qinterf.bend as QI
import ../../src/c14/asm.bend as AS

law inst_mk_name:
  for nm: String
  for nd: U64
  for tx: F64
  for ty: F64
  for tz: F64
  for q: U64
  {AS.inst_name(AS.Inst{nm, nd, tx, ty, tz, q}) == nm : String}

law inst_mk_node:
  for nm: String
  for nd: U64
  for tx: F64
  for ty: F64
  for tz: F64
  for q: U64
  {AS.inst_node(AS.Inst{nm, nd, tx, ty, tz, q}) == nd : U64}

law inst_mk_tx:
  for nm: String
  for nd: U64
  for tx: F64
  for ty: F64
  for tz: F64
  for q: U64
  {AS.inst_tx(AS.Inst{nm, nd, tx, ty, tz, q}) == tx : F64}

law inst_mk_ty:
  for nm: String
  for nd: U64
  for tx: F64
  for ty: F64
  for tz: F64
  for q: U64
  {AS.inst_ty(AS.Inst{nm, nd, tx, ty, tz, q}) == ty : F64}

law inst_mk_tz:
  for nm: String
  for nd: U64
  for tx: F64
  for ty: F64
  for tz: F64
  for q: U64
  {AS.inst_tz(AS.Inst{nm, nd, tx, ty, tz, q}) == tz : F64}

law inst_mk_q:
  for nm: String
  for nd: U64
  for tx: F64
  for ty: F64
  for tz: F64
  for q: U64
  {AS.inst_q(AS.Inst{nm, nd, tx, ty, tz, q}) == q : U64}

law mate_mk_id:
  for id: U64
  for kind: U64
  for a: String
  for b: String
  for p: List<&2, F64>
  {AS.mate_id(AS.Mate{id, kind, a, b, p}) == id : U64}

law mate_mk_kind:
  for id: U64
  for kind: U64
  for a: String
  for b: String
  for p: List<&2, F64>
  {AS.mate_kind(AS.Mate{id, kind, a, b, p}) == kind : U64}

law mate_mk_a:
  for id: U64
  for kind: U64
  for a: String
  for b: String
  for p: List<&2, F64>
  {AS.mate_a(AS.Mate{id, kind, a, b, p}) == a : String}

law mate_mk_b:
  for id: U64
  for kind: U64
  for a: String
  for b: String
  for p: List<&2, F64>
  {AS.mate_b(AS.Mate{id, kind, a, b, p}) == b : String}

law mate_mk_p:
  for id: U64
  for kind: U64
  for a: String
  for b: String
  for p: List<&2, F64>
  {AS.mate_p(AS.Mate{id, kind, a, b, p}) == p : List<&2, F64>}

law asm_mk_insts:
  for il: List<&2, AS.Inst>
  for ml: List<&2, AS.Mate>
  {AS.asm_insts(AS.Asm{il, ml}) == il : List<&2, AS.Inst>}

law asm_mk_mates:
  for il: List<&2, AS.Inst>
  for ml: List<&2, AS.Mate>
  {AS.asm_mates(AS.Asm{il, ml}) == ml : List<&2, AS.Mate>}

law in_mk_name:
  for i: AS.Inst
  for r: M.NR
  {AS.in_name(AS.IN{i, r}) == AS.inst_name(i) : String}

law in_mk_nr:
  for i: AS.Inst
  for r: M.NR
  {AS.in_nr(AS.IN{i, r}) == r : M.NR}

law cat_cons:
  for x: String
  for t: List<&2, String>
  {AS.cat(x <> t) == x ++ " " ++ AS.cat(t) : String}

law sdrop_nil:
  for i: Nat
  {AS.sdrop([], i) == [] : List<&2, String>}

law sdrop_zero:
  for x: String
  for t: List<&2, String>
  {AS.sdrop(x <> t, 0n) == x <> t : List<&2, String>}

law sdrop_cons:
  for x: String
  for t: List<&2, String>
  for j: Nat
  {AS.sdrop(x <> t, Nat.add(1n, j)) == AS.sdrop(t, j) : List<&2, String>}

law fnum_some:
  for v: F64
  {AS.fnum_m(Some{v}) == v : F64}

law isu64_some:
  for v: U64
  {AS.is_u64_m(Some{v}) == True{} : Bool}

law uval_some:
  for v: U64
  {AS.uval_m(Some{v}) == v : U64}

law p6_len:
  for a: F64
  for b: F64
  for c: F64
  for d: F64
  for e: F64
  for f: F64
  {List.length(&2, F64, AS.p6(a, b, c, d, e, f)) == 6n : Nat}

law p7_len:
  for a: F64
  for b: F64
  for c: F64
  for d: F64
  for e: F64
  for f: F64
  for g: F64
  {List.length(&2, F64, AS.p7(a, b, c, d, e, f, g)) == 7n : Nat}

law p9_len:
  for a: F64
  for b: F64
  for c: F64
  for d: F64
  for e: F64
  for f: F64
  for g: F64
  for h: F64
  for i: F64
  {List.length(&2, F64, AS.p9(a, b, c, d, e, f, g, h, i)) == 9n : Nat}

law fins_cons:
  for x: F64
  for t: List<&2, F64>
  {AS.fins(x <> t) == Bool.and(T.is_finite(x), AS.fins(t)) : Bool}

law inst_has_nil:
  for nm: String
  {AS.inst_has([], nm) == False{} : Bool}

law inst_has_cons:
  for i: AS.Inst
  for t: List<&2, AS.Inst>
  for nm: String
  {AS.inst_has(i <> t, nm) == Bool.or(String.eq(AS.inst_name(i), nm), AS.inst_has(t, nm)) : Bool}

law inst_at_cons:
  for i: AS.Inst
  for t: List<&2, AS.Inst>
  for nm: String
  {AS.inst_at(i <> t, nm) == Bool.pick(AS.Inst, String.eq(AS.inst_name(i), nm), i, AS.inst_at(t, nm)) : AS.Inst}

law inst_idx_nil:
  for nm: String
  for k: Nat
  {AS.inst_idx([], nm, k) == k : Nat}

law inst_idx_cons:
  for i: AS.Inst
  for t: List<&2, AS.Inst>
  for nm: String
  for k: Nat
  {AS.inst_idx(i <> t, nm, k) == Bool.pick(Nat, String.eq(AS.inst_name(i), nm), k, AS.inst_idx(t, nm, Nat.add(k, 1n))) : Nat}

law insts_dup_yes:
  for rec: AS.IR
  {AS.insts_wrap_dup(True{}, rec) == AS.IR_err{"duplicate-instance", "give every instance a different name"} : AS.IR}

law insts_dup_no:
  for rec: AS.IR
  {AS.insts_wrap_dup(False{}, rec) == rec : AS.IR}

law insts_inst_ok:
  for i: AS.Inst
  for rec: AS.IR
  for acc: List<&2, AS.Inst>
  {AS.insts_wrap_inst(AS.ER_inst{i}, rec, acc) == AS.insts_wrap_dup(AS.inst_has(acc, AS.inst_name(i)), rec) : AS.IR}

law insts_inst_mate:
  for m: AS.Mate
  for rec: AS.IR
  for acc: List<&2, AS.Inst>
  {AS.insts_wrap_inst(AS.ER_mate{m}, rec, acc) == AS.IR_err{"bad-instance", "write (inst NAME NODE TX TY TZ Q)"} : AS.IR}

law insts_inst_err:
  for why: String
  for fix: String
  for rec: AS.IR
  for acc: List<&2, AS.Inst>
  {AS.insts_wrap_inst(AS.ER_err{why, fix}, rec, acc) == AS.IR_err{why, fix} : AS.IR}

law insts_wrap_inst:
  for r: AS.ER
  for rec: AS.IR
  for acc: List<&2, AS.Inst>
  {AS.insts_wrap(1u64, r, rec, acc) == AS.insts_wrap_inst(r, rec, acc) : AS.IR}

law insts_wrap_mate:
  for r: AS.ER
  for rec: AS.IR
  for acc: List<&2, AS.Inst>
  {AS.insts_wrap(2u64, r, rec, acc) == rec : AS.IR}

law insts_wrap_unknown:
  for r: AS.ER
  for rec: AS.IR
  for acc: List<&2, AS.Inst>
  {AS.insts_wrap(0u64, r, rec, acc) == AS.IR_err{"unknown-assembly-entry", "use (inst ...) or a mate (fix, coinc, plane, axis)"} : AS.IR}

law insts_nacc_ok:
  for i: AS.Inst
  for acc: List<&2, AS.Inst>
  {AS.insts_nacc_i(AS.ER_inst{i}, acc) == Bool.pick(List<&2, AS.Inst>, AS.inst_has(acc, AS.inst_name(i)), acc, i <> acc) : List<&2, AS.Inst>}

law insts_nacc_mate:
  for m: AS.Mate
  for acc: List<&2, AS.Inst>
  {AS.insts_nacc_i(AS.ER_mate{m}, acc) == acc : List<&2, AS.Inst>}

law insts_nacc_err:
  for why: String
  for fix: String
  for acc: List<&2, AS.Inst>
  {AS.insts_nacc_i(AS.ER_err{why, fix}, acc) == acc : List<&2, AS.Inst>}

law insts_nacc_inst:
  for r: AS.ER
  for acc: List<&2, AS.Inst>
  {AS.insts_nacc(1u64, r, acc) == AS.insts_nacc_i(r, acc) : List<&2, AS.Inst>}

law insts_nacc_other:
  for r: AS.ER
  for acc: List<&2, AS.Inst>
  {AS.insts_nacc(0u64, r, acc) == acc : List<&2, AS.Inst>}

law insts_go_nil:
  for acc: List<&2, AS.Inst>
  {AS.insts_go([], acc) == AS.IR_ok{List.reverse(&2, AS.Inst, acc)} : AS.IR}

law insts_go_cons:
  for x: S.Sx
  for t: List<&2, S.Sx>
  for acc: List<&2, AS.Inst>
  {AS.insts_go(x <> t, acc) == AS.insts_wrap(AS.entry_kind(S.sx_s(S.sx_nth(S.sx_xs(x), 0n))), AS.inst_of(x), AS.insts_go(t, AS.insts_nacc(AS.entry_kind(S.sx_s(S.sx_nth(S.sx_xs(x), 0n))), AS.inst_of(x), acc)), acc) : AS.IR}

law mates_ref_yes:
  for rec: AS.MR
  {AS.mates_wrap_ref(True{}, rec) == rec : AS.MR}

law mates_ref_no:
  for rec: AS.MR
  {AS.mates_wrap_ref(False{}, rec) == AS.MR_err{"unknown-instance", "name an instance from the assembly"} : AS.MR}

law mates_mate_ok:
  for m: AS.Mate
  for rec: AS.MR
  for il: List<&2, AS.Inst>
  {AS.mates_wrap_mate(AS.ER_mate{m}, rec, il) == AS.mates_wrap_ref(AS.mate_ref_ok(m, il), rec) : AS.MR}

law mates_mate_inst:
  for i: AS.Inst
  for rec: AS.MR
  for il: List<&2, AS.Inst>
  {AS.mates_wrap_mate(AS.ER_inst{i}, rec, il) == AS.MR_err{"bad-mate", "use fix, coinc, plane or axis"} : AS.MR}

law mates_mate_err:
  for why: String
  for fix: String
  for rec: AS.MR
  for il: List<&2, AS.Inst>
  {AS.mates_wrap_mate(AS.ER_err{why, fix}, rec, il) == AS.MR_err{why, fix} : AS.MR}

law mates_wrap_inst:
  for r: AS.ER
  for rec: AS.MR
  for il: List<&2, AS.Inst>
  {AS.mates_wrap(1u64, r, rec, il) == rec : AS.MR}

law mates_wrap_mate:
  for r: AS.ER
  for rec: AS.MR
  for il: List<&2, AS.Inst>
  {AS.mates_wrap(2u64, r, rec, il) == AS.mates_wrap_mate(r, rec, il) : AS.MR}

law mates_wrap_unknown:
  for r: AS.ER
  for rec: AS.MR
  for il: List<&2, AS.Inst>
  {AS.mates_wrap(0u64, r, rec, il) == AS.MR_err{"unknown-assembly-entry", "use (inst ...) or a mate (fix, coinc, plane, axis)"} : AS.MR}

law mates_nacc_ok:
  for m: AS.Mate
  for il: List<&2, AS.Inst>
  for acc: List<&2, AS.Mate>
  {AS.mates_nacc_m(AS.ER_mate{m}, il, acc) == Bool.pick(List<&2, AS.Mate>, AS.mate_ref_ok(m, il), m <> acc, acc) : List<&2, AS.Mate>}

law mates_nacc_inst:
  for i: AS.Inst
  for il: List<&2, AS.Inst>
  for acc: List<&2, AS.Mate>
  {AS.mates_nacc_m(AS.ER_inst{i}, il, acc) == acc : List<&2, AS.Mate>}

law mates_nacc_err:
  for why: String
  for fix: String
  for il: List<&2, AS.Inst>
  for acc: List<&2, AS.Mate>
  {AS.mates_nacc_m(AS.ER_err{why, fix}, il, acc) == acc : List<&2, AS.Mate>}

law mates_nacc_mate:
  for r: AS.ER
  for il: List<&2, AS.Inst>
  for acc: List<&2, AS.Mate>
  {AS.mates_nacc(2u64, r, il, acc) == AS.mates_nacc_m(r, il, acc) : List<&2, AS.Mate>}

law mates_nacc_other:
  for r: AS.ER
  for il: List<&2, AS.Inst>
  for acc: List<&2, AS.Mate>
  {AS.mates_nacc(0u64, r, il, acc) == acc : List<&2, AS.Mate>}

law mates_go_nil:
  for il: List<&2, AS.Inst>
  for acc: List<&2, AS.Mate>
  {AS.mates_go([], il, acc) == AS.MR_ok{List.reverse(&2, AS.Mate, acc)} : AS.MR}

law mates_go_cons:
  for x: S.Sx
  for t: List<&2, S.Sx>
  for il: List<&2, AS.Inst>
  for acc: List<&2, AS.Mate>
  {AS.mates_go(x <> t, il, acc) == AS.mates_wrap(AS.entry_kind(S.sx_s(S.sx_nth(S.sx_xs(x), 0n))), AS.mate_of(x), AS.mates_go(t, il, AS.mates_nacc(AS.entry_kind(S.sx_s(S.sx_nth(S.sx_xs(x), 0n))), AS.mate_of(x), il, acc)), il) : AS.MR}

law asm_join_ml_ok:
  for l: List<&2, AS.Mate>
  for il: List<&2, AS.Inst>
  {AS.asm_join_ml(AS.MR_ok{l}, il) == AS.AR_ok{AS.Asm{il, l}} : AS.AR}

law asm_join_ml_err:
  for why: String
  for fix: String
  for il: List<&2, AS.Inst>
  {AS.asm_join_ml(AS.MR_err{why, fix}, il) == AS.AR_err{why, fix} : AS.AR}

law asm_join_empty:
  for r: AS.MR
  for il: List<&2, AS.Inst>
  {AS.asm_join_e(True{}, r, il) == AS.AR_err{"assembly-needs-instance", "add (inst NAME NODE TX TY TZ Q)"} : AS.AR}

law asm_join_some:
  for r: AS.MR
  for il: List<&2, AS.Inst>
  {AS.asm_join_e(False{}, r, il) == AS.asm_join_ml(r, il) : AS.AR}

law asm_ir_ok:
  for l: List<&2, AS.Inst>
  for xs: List<&2, S.Sx>
  {AS.asm_ir(AS.IR_ok{l}, xs) == AS.asm_join(l, AS.mates_go(xs, l, [])) : AS.AR}

law asm_ir_err:
  for why: String
  for fix: String
  for xs: List<&2, S.Sx>
  {AS.asm_ir(AS.IR_err{why, fix}, xs) == AS.AR_err{why, fix} : AS.AR}

law asm_head_no:
  for x: S.Sx
  {AS.asm_head_go(False{}, x) == AS.AR_err{"assembly-parse-failed", "write one (assembly ...) form"} : AS.AR}

law asm_head_yes:
  for x: S.Sx
  {AS.asm_head_go(True{}, x) == AS.asm_ir(AS.insts_go(S.sx_drop(S.sx_xs(x), 1n), []), S.sx_drop(S.sx_xs(x), 1n)) : AS.AR}

law asm_ps_no:
  for xs: List<&2, S.Sx>
  {AS.asm_ps(S.PS{False{}, xs}) == AS.AR_err{"assembly-parse-failed", "write one (assembly ...) form"} : AS.AR}

law asm_ps_yes:
  for xs: List<&2, S.Sx>
  {AS.asm_ps(S.PS{True{}, xs}) == AS.asm_one(xs) : AS.AR}

law col_of_layout:
  for k: Nat
  for i: Nat
  {AS.col_of(k, i) == U32.from_nat(Nat.add(Nat.mul(k, 3n), i)) : U32}

law rows_fix_len:
  for id: U64
  for k: Nat
  for i: AS.Inst
  {List.length(&2, SL.Dr, AS.rows_fix(id, k, i)) == 3n : Nat}

law rows_coinc_len:
  for m: AS.Mate
  for il: List<&2, AS.Inst>
  for cs: List<&2, M.CE>
  {List.length(&2, SL.Dr, AS.rows_coinc(m, il, cs)) == 3n : Nat}

law rows_plane_len:
  for m: AS.Mate
  for il: List<&2, AS.Inst>
  for cs: List<&2, M.CE>
  {List.length(&2, SL.Dr, AS.rows_plane(m, il, cs)) == 1n : Nat}

law rows_axis_len:
  for m: AS.Mate
  for il: List<&2, AS.Inst>
  for cs: List<&2, M.CE>
  {List.length(&2, SL.Dr, AS.rows_axis(m, il, cs)) == 2n : Nat}

law mate_rows_fix:
  for m: AS.Mate
  for il: List<&2, AS.Inst>
  for cs: List<&2, M.CE>
  {AS.mate_rows_go(1u64, m, il, cs) == AS.rows_fix(AS.mate_id(m), AS.inst_idx(il, AS.mate_b(m), 0n), AS.inst_at(il, AS.mate_b(m))) : List<&2, SL.Dr>}

law mate_rows_coinc:
  for m: AS.Mate
  for il: List<&2, AS.Inst>
  for cs: List<&2, M.CE>
  {AS.mate_rows_go(2u64, m, il, cs) == AS.rows_coinc(m, il, cs) : List<&2, SL.Dr>}

law mate_rows_plane:
  for m: AS.Mate
  for il: List<&2, AS.Inst>
  for cs: List<&2, M.CE>
  {AS.mate_rows_go(3u64, m, il, cs) == AS.rows_plane(m, il, cs) : List<&2, SL.Dr>}

law mate_rows_axis_len:
  for m: AS.Mate
  for il: List<&2, AS.Inst>
  for cs: List<&2, M.CE>
  {List.length(&2, SL.Dr, AS.mate_rows_go(4u64, m, il, cs)) == 2n : Nat}

law asm_rows_nil:
  for il: List<&2, AS.Inst>
  for cs: List<&2, M.CE>
  {AS.asm_rows([], il, cs) == [] : List<&2, SL.Dr>}

law asm_rows_cons:
  for m: AS.Mate
  for t: List<&2, AS.Mate>
  for il: List<&2, AS.Inst>
  for cs: List<&2, M.CE>
  {AS.asm_rows(m <> t, il, cs) == List.append(&2, SL.Dr, AS.mate_rows(m, il, cs), AS.asm_rows(t, il, cs)) : List<&2, SL.Dr>}

law decl_ts_cons:
  for i: AS.Inst
  for t: List<&2, AS.Inst>
  {AS.decl_ts(i <> t) == AS.inst_tx(i) <> AS.inst_ty(i) <> AS.inst_tz(i) <> AS.decl_ts(t) : List<&2, F64>}

law maxres_nil:
  for sol: List<&2, F64>
  for m: F64
  {AS.maxres_go([], sol, m) == m : F64}

law maxres_cons:
  for d: SL.Dr
  for t: List<&2, SL.Dr>
  for sol: List<&2, F64>
  for m: F64
  {AS.maxres_go(d <> t, sol, m) == AS.maxres_go(t, sol, F64.max(m, AS.row_res(d, sol))) : F64}

law u_has_nil:
  for v: U64
  {AS.u_has([], v) == False{} : Bool}

law u_has_cons:
  for x: U64
  for t: List<&2, U64>
  for v: U64
  {AS.u_has(x <> t, v) == Bool.or(U64.is_eq(x, v), AS.u_has(t, v)) : Bool}

law viol_nil:
  for sol: List<&2, F64>
  for acc: List<&2, U64>
  {AS.viol_go([], sol, acc) == List.reverse(&2, U64, acc) : List<&2, U64>}

law viol_cons:
  for d: SL.Dr
  for t: List<&2, SL.Dr>
  for sol: List<&2, F64>
  for acc: List<&2, U64>
  {AS.viol_go(d <> t, sol, acc) == AS.viol_go(t, sol, Bool.pick(List<&2, U64>, AS.row_bad(d, sol), AS.u_add(acc, SL.dr_id(d)), acc)) : List<&2, U64>}

law redup_nil:
  for it: P.Tb<&2, U64>
  for acc: List<&2, U64>
  {AS.redup([], it, acc) == List.reverse(&2, U64, acc) : List<&2, U64>}

law redup_cons:
  for j: U32
  for t: List<&2, U32>
  for it: P.Tb<&2, U64>
  for acc: List<&2, U64>
  {AS.redup(j <> t, it, acc) == AS.redup(t, it, AS.u_add(acc, P.tb_get(U64, it, j))) : List<&2, U64>}

law verdict_ok:
  for dof: Nat
  for red: List<&2, U64>
  for sol: List<&2, F64>
  for res: F64
  {AS.asm_verdict(dof, red, sol, res, []) == AS.AS_ok{sol, dof, red, res} : AS.AS}

law verdict_conf:
  for dof: Nat
  for red: List<&2, U64>
  for sol: List<&2, F64>
  for res: F64
  for id: U64
  for ids: List<&2, U64>
  {AS.asm_verdict(dof, red, sol, res, id <> ids) == AS.AS_conf{id <> ids, res} : AS.AS}

law ids_tail_cons:
  for h: U64
  for t: List<&2, U64>
  {AS.ids_tail(h <> t) == "," ++ U64.show(h) ++ AS.ids_tail(t) : String}

law ids_show_cons:
  for h: U64
  for t: List<&2, U64>
  {AS.ids_show(h <> t) == "[" ++ U64.show(h) ++ AS.ids_tail(t) ++ "]" : String}

law mate_ids_cons:
  for m: AS.Mate
  for t: List<&2, AS.Mate>
  {AS.mate_ids(m <> t) == AS.mate_id(m) <> AS.mate_ids(t) : List<&2, U64>}

law lin_nil:
  for first: Bool
  {AS.lin_go([], first) == "" : String}

law lin_cons:
  for i: AS.Inst
  for t: List<&2, AS.Inst>
  for first: Bool
  {AS.lin_go(i <> t, first) == Bool.pick(String, first, "", ",") ++ AS.inst_name(i) ++ "=n" ++ U64.show(AS.inst_node(i)) ++ AS.lin_go(t, False{}) : String}

law insts_rep_nil:
  for xs: List<&2, F64>
  for k: Nat
  {AS.insts_rep([], xs, k) == "" : String}

law insts_rep_cons:
  for i: AS.Inst
  for t: List<&2, AS.Inst>
  for xs: List<&2, F64>
  for k: Nat
  {AS.insts_rep(i <> t, xs, k) == AS.inst_line(i, M.f_nth(xs, Nat.mul(k, 3n)), M.f_nth(xs, Nat.add(Nat.mul(k, 3n), 1n)), M.f_nth(xs, Nat.add(Nat.mul(k, 3n), 2n))) ++ AS.insts_rep(t, xs, Nat.add(k, 1n)) : String}

law solve_rep_solved:
  for il: List<&2, AS.Inst>
  for ml: List<&2, AS.Mate>
  for xs: List<&2, F64>
  for red: List<&2, U64>
  for res: F64
  {AS.solve_rep(AS.Asm{il, ml}, xs, 0n, red, res) == "asm " ++ "solved" ++ " ninst " ++ Nat.show(List.length(&2, AS.Inst, il)) ++ " nmates " ++ Nat.show(List.length(&2, AS.Mate, ml)) ++ " dof " ++ Nat.show(0n) ++ " max-residual " ++ S.f_show(res) ++ "\n" ++ AS.insts_rep(il, xs, 0n) ++ "redundant " ++ AS.ids_show(red) ++ "\n" ++ AS.lineage(il, ml) : String}

law solve_rep_under:
  for il: List<&2, AS.Inst>
  for ml: List<&2, AS.Mate>
  for xs: List<&2, F64>
  for j: Nat
  for red: List<&2, U64>
  for res: F64
  {AS.solve_rep(AS.Asm{il, ml}, xs, Nat.add(1n, j), red, res) == "asm " ++ "underconstrained" ++ " ninst " ++ Nat.show(List.length(&2, AS.Inst, il)) ++ " nmates " ++ Nat.show(List.length(&2, AS.Mate, ml)) ++ " dof " ++ Nat.show(Nat.add(1n, j)) ++ " max-residual " ++ S.f_show(res) ++ "\n" ++ AS.insts_rep(il, xs, 0n) ++ "redundant " ++ AS.ids_show(red) ++ "\n" ++ AS.lineage(il, ml) : String}

law placed_nr_err:
  for k: T.FailKind
  for d: M.Dg
  for q: U64
  for x: F64
  for y: F64
  for z: F64
  {AS.placed_nr(M.NR_err{k, d}, q, x, y, z) == M.NR_err{k, d} : M.NR}

law placed_nr_ok:
  for b: M.Body
  for fx: M.Fx
  for q: U64
  for x: F64
  for y: F64
  for z: F64
  {AS.placed_nr(M.NR_ok{b, fx}, q, x, y, z) == M.NR_ok{M.Bd{M.bd_cells(b), M.bd_brep(b), M.bd_fns(b), M.pl_move(M.bd_pl(b), q, x, y, z), M.bd_rv(b), M.bd_xb(b)}, fx} : M.NR}

law place_all_nil:
  for xs: List<&2, F64>
  for cs: List<&2, M.CE>
  for k: Nat
  {AS.place_all([], xs, cs, k) == [] : List<&2, AS.IN>}

law place_all_cons:
  for i: AS.Inst
  for t: List<&2, AS.Inst>
  for xs: List<&2, F64>
  for cs: List<&2, M.CE>
  for k: Nat
  {AS.place_all(i <> t, xs, cs, k) == AS.IN{i, AS.inst_nr(cs, i, M.f_nth(xs, Nat.mul(k, 3n)), M.f_nth(xs, Nat.add(Nat.mul(k, 3n), 1n)), M.f_nth(xs, Nat.add(Nat.mul(k, 3n), 2n)))} <> AS.place_all(t, xs, cs, Nat.add(k, 1n)) : List<&2, AS.IN>}

law pairs_inner_nil:
  for x: AS.IN
  for cl: Bool
  {AS.pairs_inner(x, [], cl) == "" : String}

law pairs_inner_clear:
  for x: AS.IN
  for y: AS.IN
  for t: List<&2, AS.IN>
  {AS.pairs_inner(x, y <> t, True{}) == "pair " ++ AS.in_name(x) ++ " " ++ AS.in_name(y) ++ "\n" ++ QD.clear_s(AS.in_nr(x), AS.in_nr(y)) ++ "\n" ++ AS.pairs_inner(x, t, True{}) : String}

law pairs_inner_rel:
  for x: AS.IN
  for y: AS.IN
  for t: List<&2, AS.IN>
  {AS.pairs_inner(x, y <> t, False{}) == "pair " ++ AS.in_name(x) ++ " " ++ AS.in_name(y) ++ "\n" ++ QI.rel_s(AS.in_nr(x), AS.in_nr(y)) ++ "\n" ++ AS.pairs_inner(x, t, False{}) : String}

law pairs_go_nil:
  for cl: Bool
  {AS.pairs_go([], cl) == "" : String}

law pairs_go_cons:
  for x: AS.IN
  for t: List<&2, AS.IN>
  for cl: Bool
  {AS.pairs_go(x <> t, cl) == AS.pairs_inner(x, t, cl) ++ AS.pairs_go(t, cl) : String}

law explode_go_nil:
  for xs: List<&2, F64>
  for k: Nat
  for o: F64
  for dx: F64
  for dy: F64
  for dz: F64
  for gap: F64
  {AS.explode_go([], xs, k, o, dx, dy, dz, gap) == "" : String}

law explode_go_cons:
  for i: AS.Inst
  for t: List<&2, AS.Inst>
  for xs: List<&2, F64>
  for k: Nat
  for o: F64
  for dx: F64
  for dy: F64
  for dz: F64
  for gap: F64
  {AS.explode_go(i <> t, xs, k, o, dx, dy, dz, gap) == AS.inst_line(i, F64.add(M.f_nth(xs, Nat.mul(k, 3n)), F64.mul(o, dx)), F64.add(M.f_nth(xs, Nat.add(Nat.mul(k, 3n), 1n)), F64.mul(o, dy)), F64.add(M.f_nth(xs, Nat.add(Nat.mul(k, 3n), 2n)), F64.mul(o, dz))) ++ AS.explode_go(t, xs, Nat.add(k, 1n), F64.add(o, gap), dx, dy, dz, gap) : String}

law afn_cav:
  for nd: U64
  for k: Nat
  for i: Nat
  for j: Nat
  for pre: String
  {AS.afn_s(BD.Fn{nd, k, 4u64, i, j}, pre) == pre ++ "n" ++ U64.show(nd) ++ ".cav." ++ Nat.show(k) ++ "." ++ Nat.show(i) ++ "." ++ Nat.show(j) : String}

law afn_top:
  for nd: U64
  for k: Nat
  for i: Nat
  for j: Nat
  for pre: String
  {AS.afn_s(BD.Fn{nd, k, 0u64, i, j}, pre) == pre ++ "n" ++ U64.show(nd) ++ ".c" ++ Nat.show(k) ++ ".top" : String}

law afn_bottom:
  for nd: U64
  for k: Nat
  for i: Nat
  for j: Nat
  for pre: String
  {AS.afn_s(BD.Fn{nd, k, 1u64, i, j}, pre) == pre ++ "n" ++ U64.show(nd) ++ ".c" ++ Nat.show(k) ++ ".bottom" : String}

law afn_wall:
  for nd: U64
  for k: Nat
  for i: Nat
  for j: Nat
  for pre: String
  {AS.afn_s(BD.Fn{nd, k, 2u64, i, j}, pre) == pre ++ "n" ++ U64.show(nd) ++ ".c" ++ Nat.show(k) ++ ".wall." ++ Nat.show(i) ++ "." ++ Nat.show(j) : String}

law asurf_plane:
  for w: G.Plane3
  {AS.asurf_s(G.GV_pl{w}) == "plane" : String}

law asurf_cyl:
  for w: G.Cyl
  {AS.asurf_s(G.GV_cy{w}) == "cylinder" : String}

law asurf_patch:
  for w: G.BezP
  {AS.asurf_s(G.GV_bp{w}) == "planar-patch" : String}

law asurf_sphere:
  for w: G.Sphere
  {AS.asurf_s(G.GV_sp{w}) == "sphere" : String}

law asurf_cone:
  for w: G.Cone
  {AS.asurf_s(G.GV_co{w}) == "cone" : String}

law asurf_torus:
  for w: G.Torus
  {AS.asurf_s(G.GV_to{w}) == "torus" : String}

law asurf_other:
  for v: F64
  {AS.asurf_s(G.GV_f{v}) == "other" : String}

law afaces_nil:
  for fas: List<&2, Ty.Face>
  for pre: String
  {AS.afaces_go([], fas, pre) == "" : String}

law afaces_cons:
  for f: BD.Fn
  for t: List<&2, BD.Fn>
  for g: U64
  for s: G.GVal
  for ls: List<&2, Ty.HLoop>
  for same: Bool
  for u: List<&2, Ty.Face>
  for pre: String
  {AS.afaces_go(f <> t, Ty.Fa{g, s, ls, same} <> u, pre) == AS.afn_s(f, pre) ++ " " ++ AS.asurf_s(s) ++ " loops=" ++ Nat.show(List.length(&2, Ty.HLoop, ls)) ++ "\n" ++ AS.afaces_go(t, u, pre) : String}

law faces_has_unknown:
  for a: AS.Asm
  for xs: List<&2, F64>
  for cs: List<&2, M.CE>
  for nm: String
  {AS.faces_has(False{}, a, xs, cs, nm) == "error invalid-input | asm faces | why: unknown-instance " ++ nm ++ " | fix: name an instance from the assembly" : String}

law faces_has_known:
  for a: AS.Asm
  for xs: List<&2, F64>
  for cs: List<&2, M.CE>
  for nm: String
  {AS.faces_has(True{}, a, xs, cs, nm) == AS.afaces_go(M.bd_fns(M.nr_body(AS.inst_nr(cs, AS.inst_at(AS.asm_insts(a), nm), M.f_nth(xs, Nat.mul(AS.inst_idx(AS.asm_insts(a), nm, 0n), 3n)), M.f_nth(xs, Nat.add(Nat.mul(AS.inst_idx(AS.asm_insts(a), nm, 0n), 3n), 1n)), M.f_nth(xs, Nat.add(Nat.mul(AS.inst_idx(AS.asm_insts(a), nm, 0n), 3n), 2n))))), Ty.brep_fas(M.bd_brep(M.nr_body(AS.inst_nr(cs, AS.inst_at(AS.asm_insts(a), nm), M.f_nth(xs, Nat.mul(AS.inst_idx(AS.asm_insts(a), nm, 0n), 3n)), M.f_nth(xs, Nat.add(Nat.mul(AS.inst_idx(AS.asm_insts(a), nm, 0n), 3n), 1n)), M.f_nth(xs, Nat.add(Nat.mul(AS.inst_idx(AS.asm_insts(a), nm, 0n), 3n), 2n)))))), nm ++ ".") : String}

law ok_solve:
  for a: AS.Asm
  for xs: List<&2, F64>
  for dof: Nat
  for red: List<&2, U64>
  for res: F64
  for cs: List<&2, M.CE>
  for nm: String
  for d: List<&2, F64>
  {AS.ok_out(a, xs, dof, red, res, cs, AS.RQ{1u64, nm, d}) == AS.solve_rep(a, xs, dof, red, res) : String}

law ok_interf:
  for a: AS.Asm
  for xs: List<&2, F64>
  for dof: Nat
  for red: List<&2, U64>
  for res: F64
  for cs: List<&2, M.CE>
  for nm: String
  for d: List<&2, F64>
  {AS.ok_out(a, xs, dof, red, res, cs, AS.RQ{2u64, nm, d}) == AS.pairs_rep(a, xs, cs, False{}) : String}

law ok_clear:
  for a: AS.Asm
  for xs: List<&2, F64>
  for dof: Nat
  for red: List<&2, U64>
  for res: F64
  for cs: List<&2, M.CE>
  for nm: String
  for d: List<&2, F64>
  {AS.ok_out(a, xs, dof, red, res, cs, AS.RQ{3u64, nm, d}) == AS.pairs_rep(a, xs, cs, True{}) : String}

law ok_explode:
  for a: AS.Asm
  for xs: List<&2, F64>
  for dof: Nat
  for red: List<&2, U64>
  for res: F64
  for cs: List<&2, M.CE>
  for nm: String
  for d: List<&2, F64>
  {AS.ok_out(a, xs, dof, red, res, cs, AS.RQ{4u64, nm, d}) == AS.explode_rep(a, xs, d) : String}

law ok_faces:
  for a: AS.Asm
  for xs: List<&2, F64>
  for dof: Nat
  for red: List<&2, U64>
  for res: F64
  for cs: List<&2, M.CE>
  for nm: String
  for d: List<&2, F64>
  {AS.ok_out(a, xs, dof, red, res, cs, AS.RQ{5u64, nm, d}) == AS.faces_rep(a, xs, cs, nm) : String}

law ok_default:
  for a: AS.Asm
  for xs: List<&2, F64>
  for dof: Nat
  for red: List<&2, U64>
  for res: F64
  for cs: List<&2, M.CE>
  for nm: String
  for d: List<&2, F64>
  {AS.ok_out(a, xs, dof, red, res, cs, AS.RQ{0u64, nm, d}) == AS.faces_rep(a, xs, cs, nm) : String}

law asm_out_conf:
  for a: AS.Asm
  for ids: List<&2, U64>
  for res: F64
  for cs: List<&2, M.CE>
  for rq: AS.RQ
  {AS.asm_out(a, AS.AS_conf{ids, res}, cs, rq) == AS.conf_rep(a, ids, res) : String}

law asm_out_ok:
  for a: AS.Asm
  for xs: List<&2, F64>
  for dof: Nat
  for red: List<&2, U64>
  for res: F64
  for cs: List<&2, M.CE>
  for rq: AS.RQ
  {AS.asm_out(a, AS.AS_ok{xs, dof, red, res}, cs, rq) == AS.ok_out(a, xs, dof, red, res, cs, rq) : String}

law nodes_ce_unknown:
  for ok: Bool
  for i: AS.Inst
  for rec: String
  {AS.nodes_ce(False{}, ok, i, rec) == "error invalid-input | asm | why: unknown-node " ++ AS.inst_name(i) ++ " | fix: name a node from the design (eval)" : String}

law nodes_ce_failed:
  for i: AS.Inst
  for rec: String
  {AS.nodes_ce(True{}, False{}, i, rec) == "error: node " ++ U64.show(AS.inst_node(i)) ++ "; nothing assembled" : String}

law nodes_ce_ok:
  for i: AS.Inst
  for rec: String
  {AS.nodes_ce(True{}, True{}, i, rec) == rec : String}

law nodes_err_nil:
  for ml: List<&2, AS.Mate>
  for cs: List<&2, M.CE>
  {AS.nodes_err([], ml, cs) == "" : String}

law nodes_err_cons:
  for i: AS.Inst
  for t: List<&2, AS.Inst>
  for ml: List<&2, AS.Mate>
  for cs: List<&2, M.CE>
  {AS.nodes_err(i <> t, ml, cs) == AS.nodes_ce(M.ce_has(cs, AS.inst_node(i)), M.nr_ok(M.ce_r(M.ce_find(cs, AS.inst_node(i)))), i, AS.nodes_err(t, ml, cs)) : String}

law asm_q_parse_err:
  for p: M.Part
  for why: String
  for fix: String
  for rq: AS.RQ
  {AS.asm_q_go(p, AS.AR_err{why, fix}, rq) == "error invalid-input | asm | why: " ++ why ++ " | fix: " ++ fix : String}

law asm_q_ok:
  for p: M.Part
  for il: List<&2, AS.Inst>
  for ml: List<&2, AS.Mate>
  for rq: AS.RQ
  {AS.asm_q_go(p, AS.AR_ok{AS.Asm{il, ml}}, rq) == Bool.pick(String, String.eq(AS.nodes_err(il, ml, M.ev_part(p, [])), ""), AS.asm_out(AS.Asm{il, ml}, AS.asm_solve(AS.Asm{il, ml}, M.ev_part(p, [])), M.ev_part(p, []), rq), AS.nodes_err(il, ml, M.ev_part(p, []))) : String}

law explode_go_no:
  for p: M.Part
  for xs: List<&2, String>
  for dx: F64
  for dy: F64
  for dz: F64
  for gap: F64
  {AS.asm_explode_go(False{}, p, xs, dx, dy, dz, gap) == "error invalid-input | asm explode | why: need DX DY DZ GAP finite with a nonzero direction | fix: asm explode DX DY DZ GAP (assembly ...)" : String}

law explode_go_yes:
  for p: M.Part
  for xs: List<&2, String>
  for dx: F64
  for dy: F64
  for dz: F64
  for gap: F64
  {AS.asm_explode_go(True{}, p, xs, dx, dy, dz, gap) == AS.asm_q_go(p, AS.asm_parse(AS.cat(AS.sdrop(xs, 5n))), AS.RQ{4u64, "", [dx, dy, dz, gap]}) : String}

law faces_go_needy:
  for p: M.Part
  for xs: List<&2, String>
  for nm: String
  {AS.asm_faces_go(True{}, p, xs, nm) == "error invalid-input | asm faces | why: need an instance name | fix: asm faces INST (assembly ...)" : String}

law faces_go_yes:
  for p: M.Part
  for xs: List<&2, String>
  for nm: String
  {AS.asm_faces_go(False{}, p, xs, nm) == AS.asm_q_go(p, AS.asm_parse(AS.cat(AS.sdrop(xs, 2n))), AS.RQ{5u64, nm, []}) : String}

law asm_verb_solve:
  for p: M.Part
  for xs: List<&2, String>
  {AS.asm_verb(1u64, p, xs) == AS.asm_q_go(p, AS.asm_parse(AS.cat(AS.sdrop(xs, 1n))), AS.RQ{1u64, "", []}) : String}

law asm_verb_interf:
  for p: M.Part
  for xs: List<&2, String>
  {AS.asm_verb(2u64, p, xs) == AS.asm_q_go(p, AS.asm_parse(AS.cat(AS.sdrop(xs, 1n))), AS.RQ{2u64, "", []}) : String}

law asm_verb_clear:
  for p: M.Part
  for xs: List<&2, String>
  {AS.asm_verb(3u64, p, xs) == AS.asm_q_go(p, AS.asm_parse(AS.cat(AS.sdrop(xs, 1n))), AS.RQ{3u64, "", []}) : String}

law asm_verb_explode:
  for p: M.Part
  for xs: List<&2, String>
  {AS.asm_verb(4u64, p, xs) == AS.asm_explode_v(p, xs) : String}

law asm_verb_faces:
  for p: M.Part
  for xs: List<&2, String>
  {AS.asm_verb(5u64, p, xs) == AS.asm_faces_v(p, xs) : String}

law asm_verb_unknown:
  for p: M.Part
  for xs: List<&2, String>
  {AS.asm_verb(0u64, p, xs) == "error invalid-input | asm | why: unknown verb | fix: asm solve|interf|clear|explode|faces ..." : String}
