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



law neg_ms_box_zero:
  {Y.sres_show(O.ms_box(0.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64,
    unit_box())) == "invalid-input" : String}

def neg_ms_box_zero():
  {==}

law neg_ms_box_nan:
  {Y.sres_show(O.ms_box(F64.nan(), 2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64,
    unit_box())) == "invalid-input" : String}

def neg_ms_box_nan():
  {==}

law neg_ms_box_over:
  {Y.sres_show(O.ms_box(1.0e308f64, 1.0e308f64, 1.0f64, 0.0f64, 0.0f64,
    0.0f64, unit_box())) == "numerical-uncertainty" : String}

def neg_ms_box_over():
  {==}

law ok_ms_bin_add:
  {Y.sok_iv_of(O.ms_bin_iv(0u64, Y.Iv{1.0f64, 1.0f64}, Y.Iv{2.0f64, 2.0f64}))
    == Y.Iv{F64{4613937818241073151u64}, F64{4613937818241073153u64}} : Y.Iv}

def ok_ms_bin_add():
  {==}

law ok_ms_bin_mul:
  {Y.sok_iv_of(O.ms_bin_iv(1u64, Y.Iv{2.0f64, 2.0f64}, Y.Iv{3.0f64, 3.0f64}))
    == Y.Iv{F64{4618441417868443647u64}, F64{4618441417868443649u64}} : Y.Iv}

def ok_ms_bin_mul():
  {==}

law neg_ms_bin_first_wins:
  {Y.sres_show(O.ms_bin2(0u64, Y.serr_invalid("a", "t", "w", "f"),
    Y.sok_iv(Y.Iv{1.0f64, 1.0f64}))) == "invalid-input" : String}

def neg_ms_bin_first_wins():
  {==}

law neg_ms_bin_second:
  {Y.sres_show(O.ms_bin2(0u64, Y.sok_iv(Y.Iv{1.0f64, 1.0f64}),
    Y.serr_uncertain("b", "t", "w", "f"))) == "numerical-uncertainty" : String}

def neg_ms_bin_second():
  {==}
