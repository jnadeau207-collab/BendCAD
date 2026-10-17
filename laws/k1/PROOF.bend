import Base
import ../../src/k1/core.bend as K
import ../../src/c08/bool.bend as B
import ./LAWS.bend as Laws

def Laws.pp_table(r):
  match r:
    case Laws.R_dis{}:
      {==}
    case Laws.R_tra{}:
      {==}
    case Laws.R_par{}:
      {==}
    case Laws.R_cop{}:
      {==}
    case Laws.R_coa{}:
      {==}
    case Laws.R_tan{}:
      {==}
    case Laws.R_cyl{}:
      {==}
    case Laws.R_cpar{}:
      {==}

def Laws.pc_table(r, p):
  match r p:
    case Laws.R_dis{} Laws.P_par{}:
      {==}
    case Laws.R_dis{} Laws.P_perp{}:
      {==}
    case Laws.R_dis{} Laws.P_ang{}:
      {==}
    case Laws.R_tra{} Laws.P_par{}:
      {==}
    case Laws.R_tra{} Laws.P_perp{}:
      {==}
    case Laws.R_tra{} Laws.P_ang{}:
      {==}
    case Laws.R_par{} Laws.P_par{}:
      {==}
    case Laws.R_par{} Laws.P_perp{}:
      {==}
    case Laws.R_par{} Laws.P_ang{}:
      {==}
    case Laws.R_cop{} Laws.P_par{}:
      {==}
    case Laws.R_cop{} Laws.P_perp{}:
      {==}
    case Laws.R_cop{} Laws.P_ang{}:
      {==}
    case Laws.R_coa{} Laws.P_par{}:
      {==}
    case Laws.R_coa{} Laws.P_perp{}:
      {==}
    case Laws.R_coa{} Laws.P_ang{}:
      {==}
    case Laws.R_tan{} Laws.P_par{}:
      {==}
    case Laws.R_tan{} Laws.P_perp{}:
      {==}
    case Laws.R_tan{} Laws.P_ang{}:
      {==}
    case Laws.R_cyl{} Laws.P_par{}:
      {==}
    case Laws.R_cyl{} Laws.P_perp{}:
      {==}
    case Laws.R_cyl{} Laws.P_ang{}:
      {==}
    case Laws.R_cpar{} Laws.P_par{}:
      {==}
    case Laws.R_cpar{} Laws.P_perp{}:
      {==}
    case Laws.R_cpar{} Laws.P_ang{}:
      {==}

def Laws.pq_table(r, c, p):
  match r c p:
    case Laws.R_dis{} True{} Laws.P_par{}:
      {==}
    case Laws.R_dis{} True{} Laws.P_perp{}:
      {==}
    case Laws.R_dis{} True{} Laws.P_ang{}:
      {==}
    case Laws.R_dis{} False{} Laws.P_par{}:
      {==}
    case Laws.R_dis{} False{} Laws.P_perp{}:
      {==}
    case Laws.R_dis{} False{} Laws.P_ang{}:
      {==}
    case Laws.R_tra{} True{} Laws.P_par{}:
      {==}
    case Laws.R_tra{} True{} Laws.P_perp{}:
      {==}
    case Laws.R_tra{} True{} Laws.P_ang{}:
      {==}
    case Laws.R_tra{} False{} Laws.P_par{}:
      {==}
    case Laws.R_tra{} False{} Laws.P_perp{}:
      {==}
    case Laws.R_tra{} False{} Laws.P_ang{}:
      {==}
    case Laws.R_par{} True{} Laws.P_par{}:
      {==}
    case Laws.R_par{} True{} Laws.P_perp{}:
      {==}
    case Laws.R_par{} True{} Laws.P_ang{}:
      {==}
    case Laws.R_par{} False{} Laws.P_par{}:
      {==}
    case Laws.R_par{} False{} Laws.P_perp{}:
      {==}
    case Laws.R_par{} False{} Laws.P_ang{}:
      {==}
    case Laws.R_cop{} True{} Laws.P_par{}:
      {==}
    case Laws.R_cop{} True{} Laws.P_perp{}:
      {==}
    case Laws.R_cop{} True{} Laws.P_ang{}:
      {==}
    case Laws.R_cop{} False{} Laws.P_par{}:
      {==}
    case Laws.R_cop{} False{} Laws.P_perp{}:
      {==}
    case Laws.R_cop{} False{} Laws.P_ang{}:
      {==}
    case Laws.R_coa{} True{} Laws.P_par{}:
      {==}
    case Laws.R_coa{} True{} Laws.P_perp{}:
      {==}
    case Laws.R_coa{} True{} Laws.P_ang{}:
      {==}
    case Laws.R_coa{} False{} Laws.P_par{}:
      {==}
    case Laws.R_coa{} False{} Laws.P_perp{}:
      {==}
    case Laws.R_coa{} False{} Laws.P_ang{}:
      {==}
    case Laws.R_tan{} True{} Laws.P_par{}:
      {==}
    case Laws.R_tan{} True{} Laws.P_perp{}:
      {==}
    case Laws.R_tan{} True{} Laws.P_ang{}:
      {==}
    case Laws.R_tan{} False{} Laws.P_par{}:
      {==}
    case Laws.R_tan{} False{} Laws.P_perp{}:
      {==}
    case Laws.R_tan{} False{} Laws.P_ang{}:
      {==}
    case Laws.R_cyl{} True{} Laws.P_par{}:
      {==}
    case Laws.R_cyl{} True{} Laws.P_perp{}:
      {==}
    case Laws.R_cyl{} True{} Laws.P_ang{}:
      {==}
    case Laws.R_cyl{} False{} Laws.P_par{}:
      {==}
    case Laws.R_cyl{} False{} Laws.P_perp{}:
      {==}
    case Laws.R_cyl{} False{} Laws.P_ang{}:
      {==}
    case Laws.R_cpar{} True{} Laws.P_par{}:
      {==}
    case Laws.R_cpar{} True{} Laws.P_perp{}:
      {==}
    case Laws.R_cpar{} True{} Laws.P_ang{}:
      {==}
    case Laws.R_cpar{} False{} Laws.P_par{}:
      {==}
    case Laws.R_cpar{} False{} Laws.P_perp{}:
      {==}
    case Laws.R_cpar{} False{} Laws.P_ang{}:
      {==}

def Laws.cc_table(r):
  match r:
    case Laws.R_dis{}:
      {==}
    case Laws.R_tra{}:
      {==}
    case Laws.R_par{}:
      {==}
    case Laws.R_cop{}:
      {==}
    case Laws.R_coa{}:
      {==}
    case Laws.R_tan{}:
      {==}
    case Laws.R_cyl{}:
      {==}
    case Laws.R_cpar{}:
      {==}

def Laws.gen_table(r):
  match r:
    case Laws.R_dis{}:
      {==}
    case Laws.R_tra{}:
      {==}
    case Laws.R_par{}:
      {==}
    case Laws.R_cop{}:
      {==}
    case Laws.R_coa{}:
      {==}
    case Laws.R_tan{}:
      {==}
    case Laws.R_cyl{}:
      {==}
    case Laws.R_cpar{}:
      {==}

def Laws.keep_matches_c08(o, c):
  match o c:
    case Laws.O_union{} Laws.F_out{}:
      {==}
    case Laws.O_union{} Laws.F_in{}:
      {==}
    case Laws.O_union{} Laws.F_same{}:
      {==}
    case Laws.O_union{} Laws.F_opp{}:
      {==}
    case Laws.O_union{} Laws.F_unc{}:
      {==}
    case Laws.O_union{} Laws.F_coin{}:
      {==}
    case Laws.O_diff{} Laws.F_out{}:
      {==}
    case Laws.O_diff{} Laws.F_in{}:
      {==}
    case Laws.O_diff{} Laws.F_same{}:
      {==}
    case Laws.O_diff{} Laws.F_opp{}:
      {==}
    case Laws.O_diff{} Laws.F_unc{}:
      {==}
    case Laws.O_diff{} Laws.F_coin{}:
      {==}
    case Laws.O_inter{} Laws.F_out{}:
      {==}
    case Laws.O_inter{} Laws.F_in{}:
      {==}
    case Laws.O_inter{} Laws.F_same{}:
      {==}
    case Laws.O_inter{} Laws.F_opp{}:
      {==}
    case Laws.O_inter{} Laws.F_unc{}:
      {==}
    case Laws.O_inter{} Laws.F_coin{}:
      {==}

def Laws.frag_strict(o, s, c):
  match o s c:
    case Laws.O_union{} Laws.S_a{} Laws.St_in{}:
      {==}
    case Laws.O_union{} Laws.S_a{} Laws.St_out{}:
      {==}
    case Laws.O_union{} Laws.S_b{} Laws.St_in{}:
      {==}
    case Laws.O_union{} Laws.S_b{} Laws.St_out{}:
      {==}
    case Laws.O_diff{} Laws.S_a{} Laws.St_in{}:
      {==}
    case Laws.O_diff{} Laws.S_a{} Laws.St_out{}:
      {==}
    case Laws.O_diff{} Laws.S_b{} Laws.St_in{}:
      {==}
    case Laws.O_diff{} Laws.S_b{} Laws.St_out{}:
      {==}
    case Laws.O_inter{} Laws.S_a{} Laws.St_in{}:
      {==}
    case Laws.O_inter{} Laws.S_a{} Laws.St_out{}:
      {==}
    case Laws.O_inter{} Laws.S_b{} Laws.St_in{}:
      {==}
    case Laws.O_inter{} Laws.S_b{} Laws.St_out{}:
      {==}

def Laws.frag_coin_pm(o, s):
  match o s:
    case Laws.O_union{} Laws.S_a{}:
      {==}
    case Laws.O_union{} Laws.S_b{}:
      {==}
    case Laws.O_diff{} Laws.S_a{}:
      {==}
    case Laws.O_diff{} Laws.S_b{}:
      {==}
    case Laws.O_inter{} Laws.S_a{}:
      {==}
    case Laws.O_inter{} Laws.S_b{}:
      {==}

def Laws.frag_coin_mp(o, s):
  match o s:
    case Laws.O_union{} Laws.S_a{}:
      {==}
    case Laws.O_union{} Laws.S_b{}:
      {==}
    case Laws.O_diff{} Laws.S_a{}:
      {==}
    case Laws.O_diff{} Laws.S_b{}:
      {==}
    case Laws.O_inter{} Laws.S_a{}:
      {==}
    case Laws.O_inter{} Laws.S_b{}:
      {==}

def Laws.frag_uncertain(o, s):
  match o s:
    case Laws.O_union{} Laws.S_a{}:
      {==}
    case Laws.O_union{} Laws.S_b{}:
      {==}
    case Laws.O_diff{} Laws.S_a{}:
      {==}
    case Laws.O_diff{} Laws.S_b{}:
      {==}
    case Laws.O_inter{} Laws.S_a{}:
      {==}
    case Laws.O_inter{} Laws.S_b{}:
      {==}

def Laws.frag_graze(o, s, c):
  match o s c:
    case Laws.O_union{} Laws.S_a{} Laws.St_in{}:
      {==}
    case Laws.O_union{} Laws.S_a{} Laws.St_out{}:
      {==}
    case Laws.O_union{} Laws.S_b{} Laws.St_in{}:
      {==}
    case Laws.O_union{} Laws.S_b{} Laws.St_out{}:
      {==}
    case Laws.O_diff{} Laws.S_a{} Laws.St_in{}:
      {==}
    case Laws.O_diff{} Laws.S_a{} Laws.St_out{}:
      {==}
    case Laws.O_diff{} Laws.S_b{} Laws.St_in{}:
      {==}
    case Laws.O_diff{} Laws.S_b{} Laws.St_out{}:
      {==}
    case Laws.O_inter{} Laws.S_a{} Laws.St_in{}:
      {==}
    case Laws.O_inter{} Laws.S_a{} Laws.St_out{}:
      {==}
    case Laws.O_inter{} Laws.S_b{} Laws.St_in{}:
      {==}
    case Laws.O_inter{} Laws.S_b{} Laws.St_out{}:
      {==}

def Laws.flip_diff_tool(o, s):
  match o s:
    case Laws.O_union{} Laws.S_a{}:
      {==}
    case Laws.O_union{} Laws.S_b{}:
      {==}
    case Laws.O_diff{} Laws.S_a{}:
      {==}
    case Laws.O_diff{} Laws.S_b{}:
      {==}
    case Laws.O_inter{} Laws.S_a{}:
      {==}
    case Laws.O_inter{} Laws.S_b{}:
      {==}

def Laws.band_fw_lo(flip, same, pos):
  match flip same pos:
    case False{} False{} False{}:
      {==}
    case False{} False{} True{}:
      {==}
    case False{} True{} False{}:
      {==}
    case False{} True{} True{}:
      {==}
    case True{} False{} False{}:
      {==}
    case True{} False{} True{}:
      {==}
    case True{} True{} False{}:
      {==}
    case True{} True{} True{}:
      {==}

def Laws.band_fw_hi(flip, same, pos):
  match flip same pos:
    case False{} False{} False{}:
      {==}
    case False{} False{} True{}:
      {==}
    case False{} True{} False{}:
      {==}
    case False{} True{} True{}:
      {==}
    case True{} False{} False{}:
      {==}
    case True{} False{} True{}:
      {==}
    case True{} True{} False{}:
      {==}
    case True{} True{} True{}:
      {==}

def Laws.dec_curve_roundtrip(a, b, c):
  match a b c:
    case False{} False{} Laws.C_none{}:
      {==}
    case False{} False{} Laws.C_line{}:
      {==}
    case False{} False{} Laws.C_circle{}:
      {==}
    case False{} False{} Laws.C_segs{}:
      {==}
    case False{} False{} Laws.C_ring{}:
      {==}
    case False{} True{} Laws.C_none{}:
      {==}
    case False{} True{} Laws.C_line{}:
      {==}
    case False{} True{} Laws.C_circle{}:
      {==}
    case False{} True{} Laws.C_segs{}:
      {==}
    case False{} True{} Laws.C_ring{}:
      {==}
    case True{} False{} Laws.C_none{}:
      {==}
    case True{} False{} Laws.C_line{}:
      {==}
    case True{} False{} Laws.C_circle{}:
      {==}
    case True{} False{} Laws.C_segs{}:
      {==}
    case True{} False{} Laws.C_ring{}:
      {==}
    case True{} True{} Laws.C_none{}:
      {==}
    case True{} True{} Laws.C_line{}:
      {==}
    case True{} True{} Laws.C_circle{}:
      {==}
    case True{} True{} Laws.C_segs{}:
      {==}
    case True{} True{} Laws.C_ring{}:
      {==}

def Laws.dec_splitA_roundtrip(a, b, c):
  match a b c:
    case False{} False{} Laws.C_none{}:
      {==}
    case False{} False{} Laws.C_line{}:
      {==}
    case False{} False{} Laws.C_circle{}:
      {==}
    case False{} False{} Laws.C_segs{}:
      {==}
    case False{} False{} Laws.C_ring{}:
      {==}
    case False{} True{} Laws.C_none{}:
      {==}
    case False{} True{} Laws.C_line{}:
      {==}
    case False{} True{} Laws.C_circle{}:
      {==}
    case False{} True{} Laws.C_segs{}:
      {==}
    case False{} True{} Laws.C_ring{}:
      {==}
    case True{} False{} Laws.C_none{}:
      {==}
    case True{} False{} Laws.C_line{}:
      {==}
    case True{} False{} Laws.C_circle{}:
      {==}
    case True{} False{} Laws.C_segs{}:
      {==}
    case True{} False{} Laws.C_ring{}:
      {==}
    case True{} True{} Laws.C_none{}:
      {==}
    case True{} True{} Laws.C_line{}:
      {==}
    case True{} True{} Laws.C_circle{}:
      {==}
    case True{} True{} Laws.C_segs{}:
      {==}
    case True{} True{} Laws.C_ring{}:
      {==}

def Laws.dec_splitB_roundtrip(a, b, c):
  match a b c:
    case False{} False{} Laws.C_none{}:
      {==}
    case False{} False{} Laws.C_line{}:
      {==}
    case False{} False{} Laws.C_circle{}:
      {==}
    case False{} False{} Laws.C_segs{}:
      {==}
    case False{} False{} Laws.C_ring{}:
      {==}
    case False{} True{} Laws.C_none{}:
      {==}
    case False{} True{} Laws.C_line{}:
      {==}
    case False{} True{} Laws.C_circle{}:
      {==}
    case False{} True{} Laws.C_segs{}:
      {==}
    case False{} True{} Laws.C_ring{}:
      {==}
    case True{} False{} Laws.C_none{}:
      {==}
    case True{} False{} Laws.C_line{}:
      {==}
    case True{} False{} Laws.C_circle{}:
      {==}
    case True{} False{} Laws.C_segs{}:
      {==}
    case True{} False{} Laws.C_ring{}:
      {==}
    case True{} True{} Laws.C_none{}:
      {==}
    case True{} True{} Laws.C_line{}:
      {==}
    case True{} True{} Laws.C_circle{}:
      {==}
    case True{} True{} Laws.C_segs{}:
      {==}
    case True{} True{} Laws.C_ring{}:
      {==}
