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


# --- S. Box measure. ---

def ms123() -> Y.SRes:
  O.ms_box(1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64, unit_box())

def ms_vol123() -> Y.Iv:
  Y.ms_vol(Y.sok_ms_of(ms123()))

def ms_area123() -> Y.Iv:
  Y.ms_area(Y.sok_ms_of(ms123()))

law ok_ms_box_show:
  {Y.sres_show(ms123()) == "ok" : String}

def ok_ms_box_show():
  {==}

law ok_ms_box_vol:
  {ms_vol123()
    == Y.Iv{F64{4618441417868443646u64}, F64{4618441417868443651u64}} : Y.Iv}

def ok_ms_box_vol():
  {==}

law ok_ms_box_area:
  {ms_area123()
    == Y.Iv{F64{4626885667169763325u64}, F64{4626885667169763332u64}} : Y.Iv}

def ok_ms_box_area():
  {==}

law ok_ms_box_blo:
  {Y.ms_blo(Y.sok_ms_of(ms123()))
    == V.Pt{0.0f64, 0.0f64, 0.0f64} : V.Point}

def ok_ms_box_blo():
  {==}

law ok_ms_box_bhi:
  {Y.ms_bhi(Y.sok_ms_of(ms123()))
    == V.Pt{1.0f64, 2.0f64, 3.0f64} : V.Point}

def ok_ms_box_bhi():
  {==}

law ok_ms_box_nv:
  {Y.ms_nv(Y.sok_ms_of(ms123())) == 8n : Nat}

def ok_ms_box_nv():
  {==}

law ok_ms_box_ne:
  {Y.ms_ne(Y.sok_ms_of(ms123())) == 12n : Nat}

def ok_ms_box_ne():
  {==}

law ok_ms_box_nf:
  {Y.ms_nf(Y.sok_ms_of(ms123())) == 6n : Nat}

def ok_ms_box_nf():
  {==}
