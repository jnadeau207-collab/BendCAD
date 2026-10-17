import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c03/ops.bend as GO
import ../../src/c04/types.bend as Ty
import ../../src/c04/ops.bend as Op
import ../../src/base/par.bend as B
import ./LAWS.bend as Laws

def Laws.tok_ok(v):
  match v:
    case Ty.T_f{w}: {==}
    case Ty.T_n{w}: {==}
    case Ty.T_b{w}: {==}
    case Ty.T_vx{w}: {==}
    case Ty.T_ed{w}: {==}
    case Ty.T_ce{w}: {==}
    case Ty.T_lp{w}: {==}
    case Ty.T_fa{w}: {==}
    case Ty.T_sh{w}: {==}
    case Ty.T_so{w}: {==}
    case Ty.T_cp{w}: {==}
    case Ty.T_brep{w}: {==}
    case Ty.T_hv{w}: {==}
    case Ty.T_he{w}: {==}
    case Ty.T_hc{w}: {==}
    case Ty.T_hlp{w}: {==}
    case Ty.T_hfa{w}: {==}
    case Ty.T_hsh{w}: {==}
    case Ty.T_hso{w}: {==}

def Laws.tok_kind_doc(v):
  match v:
    case Ty.T_f{w}: {==}
    case Ty.T_n{w}: {==}
    case Ty.T_b{w}: {==}
    case Ty.T_vx{w}: {==}
    case Ty.T_ed{w}: {==}
    case Ty.T_ce{w}: {==}
    case Ty.T_lp{w}: {==}
    case Ty.T_fa{w}: {==}
    case Ty.T_sh{w}: {==}
    case Ty.T_so{w}: {==}
    case Ty.T_cp{w}: {==}
    case Ty.T_brep{w}: {==}
    case Ty.T_hv{w}: {==}
    case Ty.T_he{w}: {==}
    case Ty.T_hc{w}: {==}
    case Ty.T_hlp{w}: {==}
    case Ty.T_hfa{w}: {==}
    case Ty.T_hsh{w}: {==}
    case Ty.T_hso{w}: {==}

def Laws.tok_show_ok(v):
  match v:
    case Ty.T_f{w}: {==}
    case Ty.T_n{w}: {==}
    case Ty.T_b{w}: {==}
    case Ty.T_vx{w}: {==}
    case Ty.T_ed{w}: {==}
    case Ty.T_ce{w}: {==}
    case Ty.T_lp{w}: {==}
    case Ty.T_fa{w}: {==}
    case Ty.T_sh{w}: {==}
    case Ty.T_so{w}: {==}
    case Ty.T_cp{w}: {==}
    case Ty.T_brep{w}: {==}
    case Ty.T_hv{w}: {==}
    case Ty.T_he{w}: {==}
    case Ty.T_hc{w}: {==}
    case Ty.T_hlp{w}: {==}
    case Ty.T_hfa{w}: {==}
    case Ty.T_hsh{w}: {==}
    case Ty.T_hso{w}: {==}

def Laws.terr_not_ok(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_kind(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_show(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_f_zero(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_n_zero(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_b_false(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_vx_zero(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_ed_dflt(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_ce_dflt(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_lp_dflt(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_fa_dflt(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_sh_dflt(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_so_dflt(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_cp_empty(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_brep_empty(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_hv_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_he_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_hc_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_hlp_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_hfa_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_hsh_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.terr_hso_null(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

def Laws.mk_hv_idx(i, g):
  {==}

def Laws.mk_hv_gen(i, g):
  {==}

def Laws.mk_he_idx(i, g):
  {==}

def Laws.mk_he_gen(i, g):
  {==}

def Laws.mk_hc_idx(i, g):
  {==}

def Laws.mk_hc_gen(i, g):
  {==}

def Laws.mk_hlp_idx(i, g):
  {==}

def Laws.mk_hlp_gen(i, g):
  {==}

def Laws.mk_hfa_idx(i, g):
  {==}

def Laws.mk_hfa_gen(i, g):
  {==}

def Laws.mk_hsh_idx(i, g):
  {==}

def Laws.mk_hsh_gen(i, g):
  {==}

def Laws.mk_hso_idx(i, g):
  {==}

def Laws.mk_hso_gen(i, g):
  {==}

def Laws.l1_use_solid_spec(c, t, f):
  {==}

def Laws.l1_use_open_spec(c, t, f):
  {==}

def Laws.l1_use_solid_non2(c, t, f):
  match c:
    case 0n: {==}
    case 1n+0n: {==}
    case 1n+(1n+0n): {==}
    case 1n+(1n+(1n+g)): {==}

def Laws.l1_use_solid_pair(t, f):
  match t:
    case True{}:
      match f:
        case True{}: {==}
        case False{}: {==}
    case False{}:
      match f:
        case True{}: {==}
        case False{}: {==}

def Laws.l1_use_open_1(t, f):
  {==}

def Laws.l1_use_open_non12(c, t, f):
  match c:
    case 0n: {==}
    case 1n+0n: {==}
    case 1n+(1n+0n): {==}
    case 1n+(1n+(1n+g)): {==}

def Laws.l1_use_open_pair(t, f):
  match t:
    case True{}:
      match f:
        case True{}: {==}
        case False{}: {==}
    case False{}:
      match f:
        case True{}: {==}
        case False{}: {==}

def Laws.l1_use_go_nil(i, keys, prof):
  {==}

def Laws.l1_es_use_nil(ces, prof):
  {==}

def Laws.l1_seam_use(f):
  match f:
    case True{}: {==}
    case False{}: {==}

def Laws.l1_outer_rule(g, su, ls, sa, slv, sla, x):
  {==}

def Laws.l1_ov_start(a, b, f):
  match f:
    case True{}: {==}
    case False{}: {==}

def Laws.l1_ov_end(a, b, f):
  match f:
    case True{}: {==}
    case False{}: {==}

def Laws.l1_ov_swap(a, b, f):
  match f:
    case True{}: {==}
    case False{}: {==}

def Laws.l1_closed_start(a, f):
  match f:
    case True{}: {==}
    case False{}: {==}

def Laws.l1_closed_end(a, f):
  match f:
    case True{}: {==}
    case False{}: {==}

def Laws.l1_trim_ts_start(a, b):
  {==}

def Laws.l1_trim_ts_end(a, b):
  {==}

def Laws.l1_trim_tb_start(b0, b1, b2, b3):
  {==}

def Laws.l1_trim_tb_end(b0, b1, b2, b3):
  {==}

def Laws.l1_trim_o_start(t, f):
  match f:
    case True{}: {==}
    case False{}: {==}

def Laws.l1_trim_o_end(t, f):
  match f:
    case True{}: {==}
    case False{}: {==}

def Laws.l1_trim_swap(t, f):
  match f:
    case True{}: {==}
    case False{}: {==}

def Laws.l1_closure(x, pv, fv, pt, ft):
  {==}

def Laws.l1_nodup_nil(fuel):
  match fuel:
    case 0n: {==}
    case 1n+f: {==}

def Laws.l1_nodup_single(h):
  {==}

def Laws.l1_seam_run_nil(pk, pf, run):
  {==}

def Laws.l1_seam_go_nil(x):
  {==}

def Laws.l1_seam_accept(f):
  match f:
    case True{}: {==}
    case False{}: {==}

def Laws.l1_pole_nil(hcs, x):
  {==}

def Laws.l1_last_nil(d):
  {==}

def Laws.l1_link_open(b, fuel):
  {==}

def Laws.l1_cov_nil(i, cls):
  {==}

def Laws.l1_start_nil(x, i):
  {==}

def Laws.l1_have_nil(x, p, acc):
  {==}

def Laws.l1_share_nil(x):
  {==}

def Laws.l1_hls_nil(x, p, acc):
  {==}

def Laws.l1_hlps_nil(x, p):
  {==}

def Laws.l1_conn_nil(x):
  {==}

def Laws.l1_conn_rule(ok, ps):
  {==}

def Laws.l1_line_ln(w):
  {==}

def Laws.l1_line_cc(w):
  {==}

def Laws.l1_line_bz(w):
  {==}

def Laws.l1_line_rq(w):
  {==}

def Laws.l1_line_nb(w):
  {==}

def Laws.l1_line_pl(w):
  {==}

def Laws.l1_ekind_curve(c, d):
  {==}

def Laws.l1_edge_line(g, v0, v1, k):
  {==}

def Laws.l1_lines_nil(x):
  {==}

def Laws.l1_lines_cons(h, t, x):
  {==}

def Laws.l1_plane_pos(w):
  {==}

def Laws.l1_plane_cy(w):
  {==}

def Laws.l1_plane_co(w):
  {==}

def Laws.l1_plane_sp(w):
  {==}

def Laws.l1_plane_to(w):
  {==}

def Laws.l1_plane_bp(w):
  {==}

def Laws.l1_varying_nofail(s, hcs, x, same, kind):
  match s:
    case G.GV_f{w}: {==}
    case G.GV_p{w}: {==}
    case G.GV_d{w}: {==}
    case G.GV_v2{w}: {==}
    case G.GV_dom{w}: {==}
    case G.GV_ln{w}: {==}
    case G.GV_pl{w}: {==}
    case G.GV_cc{w}: {==}
    case G.GV_bz{w}: {==}
    case G.GV_rq{w}: {==}
    case G.GV_bp{w}: {==}
    case G.GV_sp{w}: {==}
    case G.GV_cy{w}: {==}
    case G.GV_co{w}: {==}
    case G.GV_to{w}: {==}
    case G.GV_bb{w}: {==}
    case G.GV_nb{w}: {==}
    case G.GV_ts{w}: {==}
    case G.GV_tb{w}: {==}

def Laws.l1_plnorm_unsupported(s):
  match s:
    case G.GV_f{w}: {==}
    case G.GV_p{w}: {==}
    case G.GV_d{w}: {==}
    case G.GV_v2{w}: {==}
    case G.GV_dom{w}: {==}
    case G.GV_ln{w}: {==}
    case G.GV_pl{w}: {==}
    case G.GV_cc{w}: {==}
    case G.GV_bz{w}: {==}
    case G.GV_rq{w}: {==}
    case G.GV_bp{w}: {==}
    case G.GV_sp{w}: {==}
    case G.GV_cy{w}: {==}
    case G.GV_co{w}: {==}
    case G.GV_to{w}: {==}
    case G.GV_bb{w}: {==}
    case G.GV_nb{w}: {==}
    case G.GV_ts{w}: {==}
    case G.GV_tb{w}: {==}

def Laws.l1_orient_c_spec(hcs, x, surf, same, kind):
  {==}

def Laws.l1_oct_hls_nil(x, surf, same, o):
  {==}

def Laws.l1_oct_skip(bad, cert, skip):
  {==}

def Laws.l1_oct_fas_nil(x, o):
  {==}

def Laws.l1_oct_bad(bad, cert, skip):
  {==}

def Laws.l1_cnt_false(n):
  {==}

def pick_acc(v: Bool, +b: Ty.Brep) -> {Laws.accepted_or(Bool.pick(Ty.TRes, v, Ty.tok_brep(b), Ty.terr(T.F_invalid{})), b) == b : Ty.Brep}:
  match v:
    case True{}: {==}
    case False{}: {==}

def after_acc(+ra: Ty.TRes, +b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> {Laws.accepted_or(Op.ck_after_a(Ty.tres_ok(ra), ra, b, prof, fuel), b) == b : Ty.Brep}:
  match ra:
    case Ty.Tok{v}: pick_acc(Op.verdict(b, prof, fuel), b)
    case Ty.Terr{k}: {==}

def go_acc(done: Bool, +b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> {Laws.accepted_or(Op.brep_checked_go(done, b, prof, fuel), b) == b : Ty.Brep}:
  match done:
    case False{}: {==}
    case True{}: after_acc(Ty.mk_brep(Ty.brep_vs(b), Ty.brep_es(b), Ty.brep_ces(b), Ty.brep_lps(b), Ty.brep_fas(b), Ty.brep_shs(b), Ty.brep_sos(b), Ty.brep_top(b), Ty.brep_stamp(b), fuel), b, prof, fuel)

def Laws.checked_returns_input(b, prof, fuel):
  go_acc(Op.ck_done(b, fuel), b, prof, fuel)
