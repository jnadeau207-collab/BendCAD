import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c12/blob.bend as BL
import ../../src/c15/pmi.bend as PM
import ./LAWS.bend as Laws

def Laws.sel_mem_nil(s):
  {==}

def Laws.sel_mem_hit(r):
  {==}

def Laws.sel_idx_hit(r, i):
  {==}

def Laws.res_all_len(es, dts, dms, bt, pl):
  match es:
    case []:
      {==}
    case +h <> t:
      %Laws.res_all_len(t, dts, dms, bt, pl) : {List.length(&2, PM.RV, PM.res_one(h, dts, dms, bt, pl) <> PM.res_all(t, dts, dms, bt, pl)) == Nat.add(1n, _) : Nat}
      {==}

def Laws.stk_rows_len(b, ts):
  match ts:
    case []:
      {==}
    case +h <> t:
      %Laws.stk_rows_len(b, t) : {List.length(&2, PM.SR, PM.stk_row(b, h) <> PM.stk_rows(b, t)) == Nat.add(1n, _) : Nat}
      {==}

def Laws.clr_rows_len(c, ts):
  match ts:
    case []:
      {==}
    case +h <> t:
      %Laws.clr_rows_len(c, t) : {List.length(&2, String, PM.clr_st(c, h) <> PM.clr_rows(c, t)) == Nat.add(1n, _) : Nat}
      {==}

def Laws.states_nonempty(s, t):
  {==}

def Laws.fb_bad(w, f, t):
  {==}

def Laws.check_fb_bad(w, f, rvs, hdr):
  {==}

def Laws.file_fb_bad(w, f, m, b):
  {==}

def Laws.check_empty_ok(hdr):
  {==}

def Laws.st_go_false(nm, g):
  {==}

def Laws.emit_nil(b, u0, pds, ctx):
  {==}

def Laws.em_dt_halt(d, em, pds):
  {==}

def Laws.em_ok_false(w, s, n, nn, dm, n0, n1, n2):
  {==}

def Laws.entry_atom(s, p):
  {==}

def Laws.ps_go_false(xs, p):
  {==}

def Laws.one_go_false(x, p):
  {==}

def Laws.head_go_false(x, p):
  {==}

def Laws.dup_go_true(nm, xs):
  {==}
