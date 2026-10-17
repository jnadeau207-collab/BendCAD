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
import ./LAWS.bend as Laws

def Laws.inst_mk_name(nm, nd, tx, ty, tz, q):
  {==}

def Laws.inst_mk_node(nm, nd, tx, ty, tz, q):
  {==}

def Laws.inst_mk_tx(nm, nd, tx, ty, tz, q):
  {==}

def Laws.inst_mk_ty(nm, nd, tx, ty, tz, q):
  {==}

def Laws.inst_mk_tz(nm, nd, tx, ty, tz, q):
  {==}

def Laws.inst_mk_q(nm, nd, tx, ty, tz, q):
  {==}

def Laws.mate_mk_id(id, kind, a, b, p):
  {==}

def Laws.mate_mk_kind(id, kind, a, b, p):
  {==}

def Laws.mate_mk_a(id, kind, a, b, p):
  {==}

def Laws.mate_mk_b(id, kind, a, b, p):
  {==}

def Laws.mate_mk_p(id, kind, a, b, p):
  {==}

def Laws.asm_mk_insts(il, ml):
  {==}

def Laws.asm_mk_mates(il, ml):
  {==}

def Laws.in_mk_name(i, r):
  {==}

def Laws.in_mk_nr(i, r):
  {==}

def Laws.cat_cons(x, t):
  {==}

def Laws.sdrop_nil(i):
  {==}

def Laws.sdrop_zero(x, t):
  {==}

def Laws.sdrop_cons(x, t, j):
  {==}

def Laws.fnum_some(v):
  {==}

def Laws.isu64_some(v):
  {==}

def Laws.uval_some(v):
  {==}

def Laws.p6_len(a, b, c, d, e, f):
  {==}

def Laws.p7_len(a, b, c, d, e, f, g):
  {==}

def Laws.p9_len(a, b, c, d, e, f, g, h, i):
  {==}

def Laws.fins_cons(x, t):
  {==}

def Laws.inst_has_nil(nm):
  {==}

def Laws.inst_has_cons(i, t, nm):
  {==}

def Laws.inst_at_cons(i, t, nm):
  {==}

def Laws.inst_idx_nil(nm, k):
  {==}

def Laws.inst_idx_cons(i, t, nm, k):
  {==}

def Laws.insts_dup_yes(rec):
  {==}

def Laws.insts_dup_no(rec):
  {==}

def Laws.insts_inst_ok(i, rec, acc):
  {==}

def Laws.insts_inst_mate(m, rec, acc):
  {==}

def Laws.insts_inst_err(why, fix, rec, acc):
  {==}

def Laws.insts_wrap_inst(r, rec, acc):
  {==}

def Laws.insts_wrap_mate(r, rec, acc):
  {==}

def Laws.insts_wrap_unknown(r, rec, acc):
  {==}

def Laws.insts_nacc_ok(i, acc):
  {==}

def Laws.insts_nacc_mate(m, acc):
  {==}

def Laws.insts_nacc_err(why, fix, acc):
  {==}

def Laws.insts_nacc_inst(r, acc):
  {==}

def Laws.insts_nacc_other(r, acc):
  {==}

def Laws.insts_go_nil(acc):
  {==}

def Laws.insts_go_cons(x, t, acc):
  {==}

def Laws.mates_ref_yes(rec):
  {==}

def Laws.mates_ref_no(rec):
  {==}

def Laws.mates_mate_ok(m, rec, il):
  {==}

def Laws.mates_mate_inst(i, rec, il):
  {==}

def Laws.mates_mate_err(why, fix, rec, il):
  {==}

def Laws.mates_wrap_inst(r, rec, il):
  {==}

def Laws.mates_wrap_mate(r, rec, il):
  {==}

def Laws.mates_wrap_unknown(r, rec, il):
  {==}

def Laws.mates_nacc_ok(m, il, acc):
  {==}

def Laws.mates_nacc_inst(i, il, acc):
  {==}

def Laws.mates_nacc_err(why, fix, il, acc):
  {==}

def Laws.mates_nacc_mate(r, il, acc):
  {==}

def Laws.mates_nacc_other(r, il, acc):
  {==}

def Laws.mates_go_nil(il, acc):
  {==}

def Laws.mates_go_cons(x, t, il, acc):
  {==}

def Laws.asm_join_ml_ok(l, il):
  {==}

def Laws.asm_join_ml_err(why, fix, il):
  {==}

def Laws.asm_join_empty(r, il):
  {==}

def Laws.asm_join_some(r, il):
  {==}

def Laws.asm_ir_ok(l, xs):
  {==}

def Laws.asm_ir_err(why, fix, xs):
  {==}

def Laws.asm_head_no(x):
  {==}

def Laws.asm_head_yes(x):
  {==}

def Laws.asm_ps_no(xs):
  {==}

def Laws.asm_ps_yes(xs):
  {==}

def Laws.col_of_layout(k, i):
  {==}

def Laws.rows_fix_len(id, k, i):
  {==}

def Laws.rows_coinc_len(m, il, cs):
  {==}

def Laws.rows_plane_len(m, il, cs):
  {==}

def Laws.rows_axis_len(m, il, cs):
  {==}

def Laws.mate_rows_fix(m, il, cs):
  {==}

def Laws.mate_rows_coinc(m, il, cs):
  {==}

def Laws.mate_rows_plane(m, il, cs):
  {==}

def Laws.mate_rows_axis_len(m, il, cs):
  {==}

def Laws.asm_rows_nil(il, cs):
  {==}

def Laws.asm_rows_cons(m, t, il, cs):
  {==}

def Laws.decl_ts_cons(i, t):
  {==}

def Laws.maxres_nil(sol, m):
  {==}

def Laws.maxres_cons(d, t, sol, m):
  {==}

def Laws.u_has_nil(v):
  {==}

def Laws.u_has_cons(x, t, v):
  {==}

def Laws.viol_nil(sol, acc):
  {==}

def Laws.viol_cons(d, t, sol, acc):
  {==}

def Laws.redup_nil(it, acc):
  {==}

def Laws.redup_cons(j, t, it, acc):
  {==}

def Laws.verdict_ok(dof, red, sol, res):
  {==}

def Laws.verdict_conf(dof, red, sol, res, id, ids):
  {==}

def Laws.ids_tail_cons(h, t):
  {==}

def Laws.ids_show_cons(h, t):
  {==}

def Laws.mate_ids_cons(m, t):
  {==}

def Laws.lin_nil(first):
  {==}

def Laws.lin_cons(i, t, first):
  {==}

def Laws.insts_rep_nil(xs, k):
  {==}

def Laws.insts_rep_cons(i, t, xs, k):
  {==}

def Laws.solve_rep_solved(il, ml, xs, red, res):
  {==}

def Laws.solve_rep_under(il, ml, xs, j, red, res):
  {==}

def Laws.placed_nr_err(k, d, q, x, y, z):
  {==}

def Laws.placed_nr_ok(b, fx, q, x, y, z):
  {==}

def Laws.place_all_nil(xs, cs, k):
  {==}

def Laws.place_all_cons(i, t, xs, cs, k):
  {==}

def Laws.pairs_inner_nil(x, cl):
  {==}

def Laws.pairs_inner_clear(x, y, t):
  {==}

def Laws.pairs_inner_rel(x, y, t):
  {==}

def Laws.pairs_go_nil(cl):
  {==}

def Laws.pairs_go_cons(x, t, cl):
  {==}

def Laws.explode_go_nil(xs, k, o, dx, dy, dz, gap):
  {==}

def Laws.explode_go_cons(i, t, xs, k, o, dx, dy, dz, gap):
  {==}

def Laws.afn_cav(nd, k, i, j, pre):
  {==}

def Laws.afn_top(nd, k, i, j, pre):
  {==}

def Laws.afn_bottom(nd, k, i, j, pre):
  {==}

def Laws.afn_wall(nd, k, i, j, pre):
  {==}

def Laws.asurf_plane(w):
  {==}

def Laws.asurf_cyl(w):
  {==}

def Laws.asurf_patch(w):
  {==}

def Laws.asurf_sphere(w):
  {==}

def Laws.asurf_cone(w):
  {==}

def Laws.asurf_torus(w):
  {==}

def Laws.asurf_other(v):
  {==}

def Laws.afaces_nil(fas, pre):
  {==}

def Laws.afaces_cons(f, t, g, s, ls, same, slv, sla, u, pre):
  {==}

def Laws.faces_has_unknown(a, xs, cs, nm):
  {==}

def Laws.faces_has_known(a, xs, cs, nm):
  {==}

def Laws.ok_solve(a, xs, dof, red, res, cs, nm, d):
  {==}

def Laws.ok_interf(a, xs, dof, red, res, cs, nm, d):
  {==}

def Laws.ok_clear(a, xs, dof, red, res, cs, nm, d):
  {==}

def Laws.ok_explode(a, xs, dof, red, res, cs, nm, d):
  {==}

def Laws.ok_faces(a, xs, dof, red, res, cs, nm, d):
  {==}

def Laws.ok_default(a, xs, dof, red, res, cs, nm, d):
  {==}

def Laws.asm_out_conf(a, ids, res, cs, rq):
  {==}

def Laws.asm_out_ok(a, xs, dof, red, res, cs, rq):
  {==}

def Laws.nodes_ce_unknown(ok, i, rec):
  {==}

def Laws.nodes_ce_failed(i, rec):
  {==}

def Laws.nodes_ce_ok(i, rec):
  {==}

def Laws.nodes_err_nil(ml, cs):
  {==}

def Laws.nodes_err_cons(i, t, ml, cs):
  {==}

def Laws.asm_q_parse_err(p, why, fix, rq):
  {==}

def Laws.asm_q_ok(p, il, ml, rq):
  {==}

def Laws.explode_go_no(p, xs, dx, dy, dz, gap):
  {==}

def Laws.explode_go_yes(p, xs, dx, dy, dz, gap):
  {==}

def Laws.faces_go_needy(p, xs, nm):
  {==}

def Laws.faces_go_yes(p, xs, nm):
  {==}

def Laws.asm_verb_solve(p, xs):
  {==}

def Laws.asm_verb_interf(p, xs):
  {==}

def Laws.asm_verb_clear(p, xs):
  {==}

def Laws.asm_verb_explode(p, xs):
  {==}

def Laws.asm_verb_faces(p, xs):
  {==}

def Laws.asm_verb_unknown(p, xs):
  {==}
