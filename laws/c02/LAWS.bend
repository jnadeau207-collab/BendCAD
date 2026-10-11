import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c02/types.bend as P
import ../../src/c02/ops.bend as O

law tri_winding_invariant:
  for +s1: P.Sign
  for +s2: P.Sign
  for +s3: P.Sign
  for +o: Bool
  {O.tri_signs(P.sign_neg(s1), P.sign_neg(s2), P.sign_neg(s3), Bool.not(o)) == O.tri_signs(s1, s2, s3, o) : P.Tres}

law tri_relabel_invariant:
  for +s1: P.Sign
  for +s2: P.Sign
  for +s3: P.Sign
  for +o: Bool
  {O.tri_signs(s2, s3, s1, o) == O.tri_signs(s1, s2, s3, o) : P.Tres}

law tri_mixed_is_outside:
  for +s3: P.Sign
  for +o: Bool
  {O.tri_signs(P.Sg_neg{}, P.Sg_pos{}, s3, o) == P.tok(P.T_out{}) : P.Tres}

law seg_proper_np_pn:
  for ax: F64
  for ay: F64
  for bx: F64
  for by: F64
  for cx: F64
  for cy: F64
  for dx: F64
  for dy: F64
  {O.seg_signs(P.Sg_neg{}, P.Sg_pos{}, P.Sg_pos{}, P.Sg_neg{}, ax, ay, bx, by, cx, cy, dx, dy) == P.xok(P.X_proper{}) : P.Xres}

law seg_proper_np_np:
  for ax: F64
  for ay: F64
  for bx: F64
  for by: F64
  for cx: F64
  for cy: F64
  for dx: F64
  for dy: F64
  {O.seg_signs(P.Sg_neg{}, P.Sg_pos{}, P.Sg_neg{}, P.Sg_pos{}, ax, ay, bx, by, cx, cy, dx, dy) == P.xok(P.X_proper{}) : P.Xres}

law seg_proper_pn_pn:
  for ax: F64
  for ay: F64
  for bx: F64
  for by: F64
  for cx: F64
  for cy: F64
  for dx: F64
  for dy: F64
  {O.seg_signs(P.Sg_pos{}, P.Sg_neg{}, P.Sg_pos{}, P.Sg_neg{}, ax, ay, bx, by, cx, cy, dx, dy) == P.xok(P.X_proper{}) : P.Xres}

law seg_proper_pn_np:
  for ax: F64
  for ay: F64
  for bx: F64
  for by: F64
  for cx: F64
  for cy: F64
  for dx: F64
  for dy: F64
  {O.seg_signs(P.Sg_pos{}, P.Sg_neg{}, P.Sg_neg{}, P.Sg_pos{}, ax, ay, bx, by, cx, cy, dx, dy) == P.xok(P.X_proper{}) : P.Xres}

law sign_neg_inv:
  for s: P.Sign
  {P.sign_neg(P.sign_neg(s)) == s : P.Sign}

law sign_neg_swaps:
  for +s: P.Sign
  {P.sign_is_pos(P.sign_neg(s)) == P.sign_is_neg(s) : Bool}

law pok_ok:
  for s: P.Sign
  {P.pres_ok(P.pok(s)) == True{} : Bool}

law perr_show:
  for k: T.FailKind
  {P.pres_show(P.perr(k)) == T.FailKind.show(k) : String}

law perr_sign_zero:
  for k: T.FailKind
  {P.pres_sign(P.perr(k)) == P.Sg_zero{} : P.Sign}

law xok_ok:
  for x: P.Xrel
  {P.xres_ok(P.xok(x)) == True{} : Bool}

law xerr_rel_dis:
  for k: T.FailKind
  {P.xres_rel(P.xerr(k)) == P.X_disjoint{} : P.Xrel}

law tok_ok:
  for c: P.Tcls
  {P.tres_ok(P.tok(c)) == True{} : Bool}

law terr_cls_out:
  for k: T.FailKind
  {P.tres_cls(P.terr(k)) == P.T_out{} : P.Tcls}
