import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c01/ops.bend as O

law neg_involution:
  for +x: F64
  {F64.neg(F64.neg(x)) == x : F64}

law v3_neg_involution:
  for +v: V.Vec3
  {V.v3_neg(V.v3_neg(v)) == v : V.Vec3}

law v2_neg_involution:
  for +v: V.Vec2
  {V.v2_neg(V.v2_neg(v)) == v : V.Vec2}

law trans_involution:
  for +m: V.Mat3
  {V.m3_trans(V.m3_trans(m)) == m : V.Mat3}

law frame_rigid_frame:
  for +fr: V.Frame
  {O.fr_of_rigid(O.rg_of_frame(fr)) == fr : V.Frame}

law rigid_frame_rigid:
  for +r: V.Rigid
  {O.rg_of_frame(O.fr_of_rigid(r)) == r : V.Rigid}

law cres_ok_ok:
  for v: V.CVal
  {V.cres_ok(V.Cok{v}) == True{} : Bool}

law cres_show_err:
  for k: T.FailKind
  {V.cres_show(V.Cerr{k}) == T.FailKind.show(k) : String}

law cerr_zero_f:
  for k: T.FailKind
  {F64.bits(V.cres_f(V.Cerr{k})) == 0u64 : U64}

law cerr_zero_v3:
  for k: T.FailKind
  {V.cres_v3(V.Cerr{k}) == V.V3{0.0f64, 0.0f64, 0.0f64} : V.Vec3}
