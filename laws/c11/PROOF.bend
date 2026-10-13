import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c06/iv.bend as I
import ../../src/c06/model.bend as M
import ../../src/c07/sol.bend as SO
import ../../src/c07/xs.bend as Q
import ../../src/c07/ss.bend as SS
import ../../src/c07/isect.bend as Y
import ../../src/c11/qcert.bend as QC
import ../../src/c11/qaccel.bend as QA
import ../../src/c11/qdist.bend as QD
import ../../src/c11/qmass.bend as QM
import ../../src/c11/qsect.bend as QN
import ../../src/c11/qinterf.bend as QI
import ./LAWS.bend as Laws

def Laws.ab_mk_x0(x0, x1, y0, y1, z0, z1):
  {==}

def Laws.ab_mk_x1(x0, x1, y0, y1, z0, z1):
  {==}

def Laws.ab_mk_y0(x0, x1, y0, y1, z0, z1):
  {==}

def Laws.ab_mk_y1(x0, x1, y0, y1, z0, z1):
  {==}

def Laws.ab_mk_z0(x0, x1, y0, y1, z0, z1):
  {==}

def Laws.ab_mk_z1(x0, x1, y0, y1, z0, z1):
  {==}

def Laws.ab_of3_x0(x, y, z):
  {==}

def Laws.ab_of3_x1(x, y, z):
  {==}

def Laws.hull_x0(a, b):
  {==}

def Laws.hull_x1(a, b):
  {==}

def Laws.overlap_dual(a, b):
  {==}

def Laws.bvh_nd_box(a, b):
  {==}

def Laws.bvh_lf_box(bx, ids):
  {==}

def Laws.bv_mk_lo(lo, hi, st):
  {==}

def Laws.bv_mk_hi(lo, hi, st):
  {==}

def Laws.bv_mk_st(lo, hi, st):
  {==}

def Laws.mass_s_err(k, dg, d):
  {==}

def Laws.dist_s_err(k, dg, x, y, z):
  {==}

def Laws.extrema_s_err(k, dg):
  {==}

def Laws.clear_s_err_a(k, dg, rb):
  {==}

def Laws.wall_s_err(k, dg):
  {==}

def Laws.sect_s_err(k, dg, a, b, c, d):
  {==}

def Laws.rel_s_err_a(k, dg, rb):
  {==}

def Laws.classify_s_err(k, dg, x, y, z):
  {==}

def Laws.mass_dep_false(b, d):
  {==}

def Laws.dist_fin_false(b, x, y, z):
  {==}

def Laws.classify_bd_false(b, x, y, z):
  {==}

def Laws.rel_pair_go_dis(a, b, wa, wb):
  {==}

def Laws.rel_interf_go_dis(a, b, wa, wb):
  {==}

def Laws.wit_go_dis(a, b, wa, wb):
  {==}

def Laws.wit_line_true(fb):
  {==}

def Laws.wit_line_false(fb):
  {==}

def Laws.wit_batches_true(bs, bss, fa, ba, pa, fb, bb, pb):
  {==}

def Laws.rel_vb_ainb(bina):
  {==}

def Laws.rel_vb_bina(ainb):
  {==}

def Laws.dist_in_inside(k, c, fs, ps, cert):
  {==}

def Laws.dist_bd_boundary(unc, c, fs, ps, cert):
  {==}

def Laws.wall_rep_empty(x, cert):
  {==}

def Laws.wall_body_noface(b):
  {==}

def Laws.cav_pair_line_dis(c, d):
  {==}

def Laws.cav_line_out(nov, c, o):
  {==}

def Laws.mass_rep_incomplete(b, ms, inn, unc, nin, nout, nunc, d, m0, m1):
  {==}

def Laws.sect_miss_nu(at):
  {==}

def Laws.sect_miss_ok(at):
  {==}

def Laws.cnt_nil(k):
  {==}

def Laws.cnt_cons(h, t, k):
  {==}

def Laws.hx_k_un3(s, u, v):
  {==}

def Laws.hx_k_uv(s, u, v, p, cls):
  {==}

def Laws.hit_k_ov(s, t):
  {==}

def Laws.sg_add_nc(a, line, c, u, k, ok):
  {==}

def Laws.sg_add_ok(a, line, c, u, k, ok):
  {==}

def Laws.sg_cat_nc(a, b):
  {==}

def Laws.sg_cat_ok(a, b):
  {==}

def Laws.ss_nbr_len(ok, brs, un):
  {==}

def Laws.ss_nun_len(ok, brs, un):
  {==}

def Laws.ak_ids_len(xs):
  match xs:
    case []: {==}
    case QA.Ak{k, id} <> t:
      %Laws.ak_ids_len(t) : {1n+List.length(&2, Nat, QA.ak_ids(t)) == 1n+_ : Nat}
      {==}

def Laws.n_mem_nil(x):
  {==}

def Laws.n_share_nil(ys):
  {==}

def Laws.sub_go_zero(cs):
  {==}

def Laws.sub1_nil(x, y):
  {==}

def Laws.fb_at_nil(i, bb):
  {==}

def Laws.sect_find_nil(at):
  {==}

def Laws.mass_dn_some(v):
  {==}

def Laws.sect_with_none(b, mapped):
  {==}

def Laws.sect_at_none(pl, f, at):
  {==}
