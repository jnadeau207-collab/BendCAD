import Base
import ../src/c01/types.bend as V
import ../src/c03/types.bend as G
import ../src/c06/iv.bend as I
import ../src/c06/xp.bend as X
import ../src/c06/revolve.bend as RV
import ../src/c07/ivx.bend as IX
import ../src/c07/rb.bend as R
import ../src/c07/im.bend as M
import ../src/c07/xs.bend as S
import ../src/c07/mem.bend as Mm
import ../src/c07/sym.bend as Y
import ../src/c07/zd.bend as D
import ../src/c07/zt.bend as ZT



def pt(+x: F64, +y: F64, +z: F64) -> V.Point:
  V.Pt{x, y, z}

def dr(+x: F64, +y: F64, +z: F64) -> V.Dir:
  V.Dr{x, y, z}

def i0() -> I.I:
  I.ipt(0.0f64)

def i1() -> I.I:
  I.ipt(1.0f64)

def xa() -> X.Xp:
  X.X_p{1u64}

def xb() -> X.Xp:
  X.X_p{2u64}

def xk(+v: F64) -> X.Xp:
  X.X_k{v}

def sq_sum() -> X.Xp:
  X.X_sub{X.X_mul{X.X_add{xa(), xb()}, X.X_add{xa(), xb()}}, X.X_add{X.X_add{X.X_mul{xa(), xa()}, X.X_mul{X.X_mul{xk(2.0f64), xa()}, xb()}}, X.X_mul{xb(), xb()}}}

def bez() -> R.Cv:
  R.cv_bez([pt(0.0f64, 0.0f64, 0.0f64), pt(0.0f64, 0.0f64, 0.0f64), pt(3.0f64, 0.0f64, 9.0f64), pt(3.0f64, 0.0f64, 9.0f64)], 0.0f64, 1.0f64)

def full() -> R.Cv:
  R.cv_circle(pt(0.0f64, 0.0f64, 0.0f64), dr(1.0f64, 0.0f64, 0.0f64), dr(0.0f64, 1.0f64, 0.0f64), 2.0f64, F64.neg(1.0f64), 1.0f64)

def co_az_g(g: G.GVal) -> F64:
  match g:
    case G.GV_co{w}:
      G.Co{o, a, k} = w
      V.dr_z(a)
    case _: F64.nan()

def co_az(s: RV.SS) -> F64:
  RV.SS{ok, g, same, plane} = s
  co_az_g(g)

law ok_grad_unit_first:
  {D.ge(3n, 0n) == [i1(), i0(), i0()] : List<&2, I.I>}

def ok_grad_unit_first():
  {==}

law ok_grad_unit_mid:
  {D.ge(3n, 1n) == [i0(), i1(), i0()] : List<&2, I.I>}

def ok_grad_unit_mid():
  {==}

law ok_sym_binomial:
  {Y.is_zero(sq_sum()) == True{} : Bool}

def ok_sym_binomial():
  {==}

law neg_sym_distinct:
  {Y.is_zero(X.X_sub{xa(), xb()}) == False{} : Bool}

def neg_sym_distinct():
  {==}

law ok_sym_quotient:
  {Y.same(X.X_div{X.X_mul{xa(), xb()}, xb()}, xa()) == True{} : Bool}

def ok_sym_quotient():
  {==}

law ok_arc_identity:
  {ZT.on_circ(xa(), xb(), X.X_sub{xa(), xb()}, xb(), xb()) == True{} : Bool}

def ok_arc_identity():
  {==}

law neg_arc_identity:
  {ZT.on_circ(xk(10.0f64), X.X_add{xa(), xb()}, xk(10.0f64), xa(), xa()) == False{} : Bool}

def neg_arc_identity():
  {==}

law ok_restr_whole_exact:
  {R.cv_rb(bez()) == R.Rb{[I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(3.0f64), I.ipt(3.0f64)], [i0(), i0(), i0(), i0()], [I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(9.0f64), I.ipt(9.0f64)], [i1(), i1(), i1(), i1()]} : R.Rb}

def ok_restr_whole_exact():
  {==}

law neg_full_circle_whole_box:
  {IX.vfin(R.cv_box(full(), I.I{0.0f64, 1.0f64})) == False{} : Bool}

def neg_full_circle_whole_box():
  {==}

law ok_class_mask:
  {S.has_cls([S.H_pt{i0(), i0(), [i0(), i0(), i0()], 33u64}], 1u64) == True{} : Bool}

def ok_class_mask():
  {==}

law ok_cone_axis_below_apex:
  {co_az(RV.ss_cone(RV.CN{True{}, 9.0f64, 0.6666666666666666f64}, 6.0f64, 0.0f64, 0.0f64, 9.0f64)) == F64.neg(1.0f64) : F64}

def ok_cone_axis_below_apex():
  {==}
