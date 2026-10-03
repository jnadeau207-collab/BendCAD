# C06 laws: intent-checked solid builders over C00-C05.
# Contract: docs/c06-contract.md. Convention: laws/c05.bend
# (ground pins ok_/neg_ plus quantified definitional laws).

import Base
import ../src/c00/types.bend as T
import ../src/c01/types.bend as V
import ../src/c03/types.bend as G
import ../src/c04/types.bend as Ty
import ../src/c06/types.bend as Y
import ../src/c06/ops.bend as O
import ../src/c06/eval.bend as EV
import ../src/c06/surfx.bend as SX

def unit_box() -> Ty.Brep:
  O.box_core(0.0f64, 0.0f64, 0.0f64, 1.0f64, 2.0f64, 3.0f64)

def id_rigid() -> V.Rigid:
  V.Rg{V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64},
    0.0f64, 0.0f64, 0.0f64}

def org() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def axis_z() -> V.Dir:
  V.Dr{0.0f64, 0.0f64, 1.0f64}


# --- Q. Staged-diagnosis runtime paths (extends L). ---

law ok_att_tag_box:
  {O.att_tag(Ty.brep_vs(unit_box()), Ty.brep_es(unit_box()),
    Ty.brep_ces(unit_box()), Ty.brep_lps(unit_box()),
    Ty.brep_fas(unit_box()), Ty.brep_shs(unit_box()),
    Ty.brep_sos(unit_box()), 58u64, 10000n) == 0u64 : U64}

def ok_att_tag_box():
  {==}

law neg_diag_fuel:
  {Y.sres_show(O.diag_brep(unit_box(), 0n)) == "resource-exhausted" : String}

def neg_diag_fuel():
  {==}

law diag_diag_fuel:
  {Y.diag_show(Y.sres_diag(O.diag_brep(unit_box(), 0n)))
    == "incidence @ bulk [fuel-out] fix: raise the fuel cap" : String}

def diag_diag_fuel():
  {==}

law diag_diag_valid:
  {Y.diag_show(Y.sres_diag(O.diag_brep(unit_box(), 10000n)))
    == "stages @ bulk [internal-stage] fix: internal: report this" : String}

def diag_diag_valid():
  {==}

law diag_stage_zero:
  {Y.diag_show(Y.sres_diag(O.stage_go(0u64)))
    == "stages @ bulk [internal-stage] fix: internal: report this" : String}

def diag_stage_zero():
  {==}

