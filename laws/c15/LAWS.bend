import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c12/blob.bend as BL
import ../../src/c15/pmi.bend as PM

law sel_mem_nil:
  for s: String
  {PM.sel_mem([], s) == False{} : Bool}

law sel_mem_hit:
  for r: Bool
  {PM.sel_mem_go(True{}, r) == True{} : Bool}

law sel_idx_hit:
  for r: Nat
  for i: Nat
  {PM.sel_idx_go(True{}, r, i) == i : Nat}

law res_all_len:
  for es: List<&2, PM.ER>
  for dts: List<&2, PM.Datum>
  for dms: List<&2, PM.Dim>
  for bt: PM.BT
  for pl: M.Pl
  {List.length(&2, PM.RV, PM.res_all(es, dts, dms, bt, pl)) == List.length(&2, PM.ER, es) : Nat}

law stk_rows_len:
  for b: PM.SR
  for ts: List<&2, PM.State>
  {List.length(&2, PM.SR, PM.stk_rows(b, ts)) == List.length(&2, PM.State, ts) : Nat}

law clr_rows_len:
  for c: PM.CI
  for ts: List<&2, PM.State>
  {List.length(&2, String, PM.clr_rows(c, ts)) == List.length(&2, PM.State, ts) : Nat}

law states_nonempty:
  for s: PM.State
  for t: List<&2, PM.State>
  {PM.states_or_dflt(s <> t) == s <> t : List<&2, PM.State>}

law fb_bad:
  for w: String
  for f: String
  for t: List<&2, PM.RV>
  {PM.fb(PM.RV_bad{w, f} <> t) == PM.FB_bad{w, f} : PM.FB}

law check_fb_bad:
  for w: String
  for f: String
  for rvs: List<&2, PM.RV>
  for hdr: String
  {PM.check_fb(PM.FB_bad{w, f}, rvs, hdr) == "error invalid-input | pmi check | why: " ++ w ++ " | fix: " ++ f : String}

law file_fb_bad:
  for w: String
  for f: String
  for m: PM.PMI
  for b: M.Body
  {PM.pmi_file_fb(PM.FB_bad{w, f}, m, b) == PM.FR_err{w, f} : PM.FR}

law check_empty_ok:
  for hdr: String
  {PM.check_rep([], hdr) == hdr ++ "pmi ok 0 items\n" : String}

law st_go_false:
  for nm: String
  for g: F64
  {PM.st_go(False{}, nm, g) == PM.ER_err{"bad-state", "write (state NAME GROW) with finite GROW > 0"} : PM.ER}

law emit_nil:
  for b: Nat
  for u0: Nat
  for pds: Nat
  for ctx: Nat
  {PM.pmi_emit([], b, u0, pds, ctx) == PM.EM{True{}, "", "", b, 0n, []} : PM.EM}

law em_dt_halt:
  for d: PM.Datum
  for em: PM.EM
  for pds: Nat
  {PM.em_dt_go(False{}, d, em, pds) == em : PM.EM}

law em_ok_false:
  for w: String
  for s: String
  for n: Nat
  for nn: Nat
  for dm: List<&2, PM.DI>
  for n0: BL.NS
  for n1: BL.NS
  for n2: BL.NS
  {PM.em_ok_of(PM.EM{False{}, w, s, n, nn, dm}, n0, n1, n2) == False{} : Bool}

law entry_atom:
  for s: String
  for p: M.Part
  {PM.entry_of(S.Sx_a{s}, p) == PM.ER_err{"unknown-pmi-entry", "entries are (node N), (nodes A B), (datum ...), (dim ...), (tol ...), (state ...) or (stack ...)"} : PM.ER}

law ps_go_false:
  for xs: List<&2, S.Sx>
  for p: M.Part
  {PM.pmi_ps_go(False{}, xs, p) == PM.PR_err{"pmi-parse-failed", "write one (pmi ...) form"} : PM.PR}

law one_go_false:
  for x: S.Sx
  for p: M.Part
  {PM.pmi_one_go(False{}, x, p) == PM.PR_err{"pmi-parse-failed", "write one (pmi ...) form"} : PM.PR}

law head_go_false:
  for x: S.Sx
  for p: M.Part
  {PM.pmi_head_go(False{}, x, p) == PM.PR_err{"pmi-parse-failed", "write one (pmi ...) form"} : PM.PR}

law dup_go_true:
  for nm: String
  for xs: List<&2, String>
  {PM.dup_go(True{}, nm, xs) == PM.DU{True{}, xs} : PM.DU}
