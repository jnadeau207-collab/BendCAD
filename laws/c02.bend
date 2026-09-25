# C02 laws: every claim closed by the proof beneath it. Unbounded claims
# live as explicit P-laws in docs/c02-contract.md; this file proves the
# structural properties generally plus one instance per pipeline arm.
# Pins: exact truth from an independent python Fraction oracle; F64 bit
# patterns from python struct; filter-vs-exact paths predicted by the
# same oracle (see the receipt).

import Base
import ../src/c00/types.bend as T
import ../src/c01/types.bend as V
import ../src/c02/types.bend as P
import ../src/c02/ops.bend as O

# --- Bit-exact fixtures (python struct; see receipt) ---
def n25() -> F64:
  F64{4719772409484279808u64}

def n25p1() -> F64:
  F64{4719772409618497536u64}

def n25p2() -> F64:
  F64{4719772409752715264u64}

def lim26() -> F64:
  F64{4724276009111650304u64}

def lim26p1() -> F64:
  F64{4724276009178759168u64}

def w251() -> F64:
  F64{4611686018427387905u64}

def q148() -> F64:
  F64{4607182418800017424u64}

def q147() -> F64:
  F64{4607182418800017440u64}

def big150() -> F64:
  F64{6850974717710472879u64}

def tiny500() -> F64:
  F64{2355382605114769408u64}

# --- Structural: general over every sign/kind/relation/class ---
law pok_ok:
  for s: P.Sign
  {P.pres_ok(P.pok(s)) == True{} : Bool}

def pok_ok(s):
  match s:
    case P.Sg_neg{}: {==}
    case P.Sg_zero{}: {==}
    case P.Sg_pos{}: {==}

law perr_show:
  for k: T.FailKind
  {P.pres_show(P.perr(k)) == T.FailKind.show(k) : String}

def perr_show(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law perr_sign_zero:
  for k: T.FailKind
  {P.pres_sign(P.perr(k)) == P.Sg_zero{} : P.Sign}

def perr_sign_zero(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law sign_neg_inv:
  for s: P.Sign
  {P.sign_neg(P.sign_neg(s)) == s : P.Sign}

def sign_neg_inv(s):
  match s:
    case P.Sg_neg{}: {==}
    case P.Sg_zero{}: {==}
    case P.Sg_pos{}: {==}

law xok_ok:
  for x: P.Xrel
  {P.xres_ok(P.xok(x)) == True{} : Bool}

def xok_ok(x):
  match x:
    case P.X_disjoint{}: {==}
    case P.X_touch{}: {==}
    case P.X_proper{}: {==}
    case P.X_overlap{}: {==}

law xerr_rel_dis:
  for k: T.FailKind
  {P.xres_rel(P.xerr(k)) == P.X_disjoint{} : P.Xrel}

def xerr_rel_dis(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

law tok_ok:
  for c: P.Tcls
  {P.tres_ok(P.tok(c)) == True{} : Bool}

def tok_ok(c):
  match c:
    case P.T_in{}: {==}
    case P.T_bound{}: {==}
    case P.T_out{}: {==}

law terr_cls_out:
  for k: T.FailKind
  {P.tres_cls(P.terr(k)) == P.T_out{} : P.Tcls}

def terr_cls_out(k):
  match k:
    case T.F_invalid{}: {==}
    case T.F_unsupported{}: {==}
    case T.F_uncertain{}: {==}
    case T.F_nonconverged{}: {==}
    case T.F_cancelled{}: {==}
    case T.F_exhausted{}: {==}

# --- Small-integer domain: roundtrip detection, limits, signs ---
law sint_int:
  {Bool.and(P.si_ok(P.sint_of(5.0f64, P.lim_o2())),
    U64.is_eq(P.si_mag(P.sint_of(5.0f64, P.lim_o2())), 5u64))
    == True{} : Bool}

def sint_int():
  {==}

law sint_half:
  {P.si_ok(P.sint_of(0.5f64, P.lim_o2())) == False{} : Bool}

def sint_half():
  {==}

law sint_lim:
  {P.si_ok(P.sint_of(lim26(), P.lim_o2())) == True{} : Bool}

def sint_lim():
  {==}

law sint_big:
  {P.si_ok(P.sint_of(lim26p1(), P.lim_o2())) == False{} : Bool}

def sint_big():
  {==}

law sint_neg:
  {Bool.and(P.si_neg(P.sint_of(F64.neg(3.0f64), P.lim_o2())),
    U64.is_eq(P.si_mag(P.sint_of(F64.neg(3.0f64), P.lim_o2())), 3u64))
    == True{} : Bool}

def sint_neg():
  {==}

# --- orient2d: filter pins, rep zero, exact zero, exact win, uncertain ---
law o2_ccw:
  {String.eq(P.pres_sign_show(O.orient2d(V.V2{0.0f64, 0.0f64},
    V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64})), "pos")
    == True{} : Bool}

def o2_ccw():
  {==}

law o2_cw:
  {String.eq(P.pres_sign_show(O.orient2d(V.V2{0.0f64, 0.0f64},
    V.V2{0.0f64, 1.0f64}, V.V2{1.0f64, 0.0f64})), "neg")
    == True{} : Bool}

def o2_cw():
  {==}

law o2_coll_zero:
  {String.eq(P.pres_sign_show(O.orient2d(V.V2{0.0f64, 0.0f64},
    V.V2{2.0f64, 2.0f64}, V.V2{5.0f64, 5.0f64})), "zero")
    == True{} : Bool}

def o2_coll_zero():
  {==}

law o2_rep_zero:
  {String.eq(P.pres_sign_show(O.orient2d(V.V2{0.1f64, 0.2f64},
    V.V2{0.1f64, 0.2f64}, V.V2{3.5f64, 4.5f64})), "zero")
    == True{} : Bool}

def o2_rep_zero():
  {==}

law o2_near_neg:
  {String.eq(P.pres_sign_show(O.orient2d(V.V2{n25(), n25p1()},
    V.V2{n25p1(), n25p2()}, V.V2{0.0f64, 0.0f64})), "neg")
    == True{} : Bool}

def o2_near_neg():
  {==}

law o2_unc:
  {String.eq(P.pres_show(O.orient2d(V.V2{0.0f64, 0.0f64},
    V.V2{2.0f64, w251()}, V.V2{4.0f64, 4.0f64})),
    "numerical-uncertainty") == True{} : Bool}

def o2_unc():
  {==}

law o2_nan_inv:
  {String.eq(P.pres_show(O.orient2d(V.V2{F64.nan(), 0.0f64},
    V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64})), "invalid-input")
    == True{} : Bool}

def o2_nan_inv():
  {==}

law o2_big150:
  {String.eq(P.pres_sign_show(O.orient2d(V.V2{0.0f64, 0.0f64},
    V.V2{big150(), 0.0f64}, V.V2{0.0f64, big150()})), "pos")
    == True{} : Bool}

def o2_big150():
  {==}

law o2_ovf_unc:
  {String.eq(P.pres_show(O.orient2d(V.V2{0.0f64, 0.0f64},
    V.V2{F64{9218868437227405311u64}, 0.0f64},
    V.V2{0.0f64, F64{9218868437227405311u64}})),
    "numerical-uncertainty") == True{} : Bool}

def o2_ovf_unc():
  {==}

law o2_tiny_unc:
  {String.eq(P.pres_show(O.orient2d(V.V2{0.0f64, 0.0f64},
    V.V2{tiny500(), 0.0f64}, V.V2{0.0f64, tiny500()})),
    "numerical-uncertainty") == True{} : Bool}

def o2_tiny_unc():
  {==}

law o2_flip:
  {P.pres_sign(O.orient2d(V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64},
    V.V2{0.0f64, 1.0f64}))
    == P.sign_neg(P.pres_sign(O.orient2d(V.V2{0.0f64, 0.0f64},
      V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}))) : P.Sign}

def o2_flip():
  {==}

# --- orient3d: shortcut pins, coplanar zero, uncertain ---
law o3_neg:
  {String.eq(P.pres_sign_show(O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
    V.Pt{0.0f64, 0.0f64, 1.0f64})), "neg") == True{} : Bool}

def o3_neg():
  {==}

law o3_pos:
  {String.eq(P.pres_sign_show(O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{1.0f64, 0.0f64, 0.0f64},
    V.Pt{0.0f64, 0.0f64, 1.0f64})), "pos") == True{} : Bool}

def o3_pos():
  {==}

law o3_coplanar_zero:
  {String.eq(P.pres_sign_show(O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
    V.Pt{1.0f64, 1.0f64, 0.0f64})), "zero") == True{} : Bool}

def o3_coplanar_zero():
  {==}

law o3_unc:
  {String.eq(P.pres_show(O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Pt{4.0f64, 0.0f64, 4.0f64}, V.Pt{0.0f64, 4.0f64, 0.0f64},
    V.Pt{2.0f64, 2.0f64, w251()})), "numerical-uncertainty")
    == True{} : Bool}

def o3_unc():
  {==}

law o3_nan_inv:
  {String.eq(P.pres_show(O.orient3d(V.Pt{F64.nan(), 0.0f64, 0.0f64},
    V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
    V.Pt{0.0f64, 0.0f64, 1.0f64})), "invalid-input") == True{} : Bool}

def o3_nan_inv():
  {==}

# --- incircle: inside/outside/on/uncertain/invalid ---
law ic_in:
  {String.eq(P.pres_sign_show(O.incircle(V.V2{0.0f64, 0.0f64},
    V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64},
    V.V2{0.25f64, 0.25f64})), "pos") == True{} : Bool}

def ic_in():
  {==}

law ic_out:
  {String.eq(P.pres_sign_show(O.incircle(V.V2{0.0f64, 0.0f64},
    V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64},
    V.V2{2.0f64, 2.0f64})), "neg") == True{} : Bool}

def ic_out():
  {==}

law ic_on_zero:
  {String.eq(P.pres_sign_show(O.incircle(V.V2{0.0f64, 0.0f64},
    V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64},
    V.V2{1.0f64, 1.0f64})), "zero") == True{} : Bool}

def ic_on_zero():
  {==}

law ic_unc:
  {String.eq(P.pres_show(O.incircle(V.V2{0.0f64, 0.0f64},
    V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64},
    V.V2{q148(), 1.0f64})), "numerical-uncertainty") == True{} : Bool}

def ic_unc():
  {==}

law ic_inf_inv:
  {String.eq(P.pres_show(O.incircle(V.V2{0.0f64, 0.0f64},
    V.V2{1.0f64, F64{9218868437227405312u64}}, V.V2{0.0f64, 1.0f64},
    V.V2{0.25f64, 0.25f64})), "invalid-input") == True{} : Bool}

def ic_inf_inv():
  {==}

# --- insphere: inside/outside/on/uncertain/invalid ---
law is_in:
  {String.eq(P.pres_sign_show(O.insphere(
    V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
    V.Pt{0.0f64, 0.0f64, 1.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Pt{0.5f64, 0.5f64, 0.5f64})), "pos") == True{} : Bool}

def is_in():
  {==}

law is_out:
  {String.eq(P.pres_sign_show(O.insphere(
    V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
    V.Pt{0.0f64, 0.0f64, 1.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Pt{2.0f64, 2.0f64, 2.0f64})), "neg") == True{} : Bool}

def is_out():
  {==}

law is_on_zero:
  {String.eq(P.pres_sign_show(O.insphere(
    V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
    V.Pt{0.0f64, 0.0f64, 1.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Pt{1.0f64, 1.0f64, 1.0f64})), "zero") == True{} : Bool}

def is_on_zero():
  {==}

law is_unc:
  {String.eq(P.pres_show(O.insphere(
    V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
    V.Pt{0.0f64, 0.0f64, 1.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Pt{q147(), 1.0f64, 1.0f64})), "numerical-uncertainty")
    == True{} : Bool}

def is_unc():
  {==}

law is_nan_inv:
  {String.eq(P.pres_show(O.insphere(
    V.Pt{F64.nan(), 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64},
    V.Pt{0.0f64, 0.0f64, 1.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Pt{0.5f64, 0.5f64, 0.5f64})), "invalid-input") == True{} : Bool}

def is_nan_inv():
  {==}

# --- seg_seg: all four relations, point cases, propagation ---
law seg_proper:
  {String.eq(P.xres_rel_show(O.seg_seg(V.V2{0.0f64, 0.0f64},
    V.V2{2.0f64, 2.0f64}, V.V2{0.0f64, 2.0f64},
    V.V2{2.0f64, 0.0f64})), "proper") == True{} : Bool}

def seg_proper():
  {==}

law seg_touch:
  {String.eq(P.xres_rel_show(O.seg_seg(V.V2{0.0f64, 0.0f64},
    V.V2{1.0f64, 1.0f64}, V.V2{1.0f64, 1.0f64},
    V.V2{2.0f64, 0.0f64})), "touch") == True{} : Bool}

def seg_touch():
  {==}

law seg_disjoint:
  {String.eq(P.xres_rel_show(O.seg_seg(V.V2{0.0f64, 0.0f64},
    V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64},
    V.V2{1.0f64, 1.0f64})), "disjoint") == True{} : Bool}

def seg_disjoint():
  {==}

law seg_overlap:
  {String.eq(P.xres_rel_show(O.seg_seg(V.V2{0.0f64, 0.0f64},
    V.V2{2.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
    V.V2{3.0f64, 0.0f64})), "overlap") == True{} : Bool}

def seg_overlap():
  {==}

law seg_ctouch:
  {String.eq(P.xres_rel_show(O.seg_seg(V.V2{0.0f64, 0.0f64},
    V.V2{1.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
    V.V2{2.0f64, 0.0f64})), "touch") == True{} : Bool}

def seg_ctouch():
  {==}

law seg_point_on:
  {String.eq(P.xres_rel_show(O.seg_seg(V.V2{1.0f64, 1.0f64},
    V.V2{1.0f64, 1.0f64}, V.V2{0.0f64, 0.0f64},
    V.V2{2.0f64, 2.0f64})), "touch") == True{} : Bool}

def seg_point_on():
  {==}

law seg_unc:
  {String.eq(P.xres_show(O.seg_seg(V.V2{0.0f64, 0.0f64},
    V.V2{2.0f64, w251()}, V.V2{4.0f64, 4.0f64},
    V.V2{5.0f64, 6.0f64})), "numerical-uncertainty") == True{} : Bool}

def seg_unc():
  {==}

# --- tri_class: inside/outside/boundary/degenerate ---
law tri_in:
  {String.eq(P.tres_cls_show(O.tri_class(V.V2{1.0f64, 1.0f64},
    V.V2{0.0f64, 0.0f64}, V.V2{4.0f64, 0.0f64},
    V.V2{0.0f64, 4.0f64})), "inside") == True{} : Bool}

def tri_in():
  {==}

law tri_out:
  {String.eq(P.tres_cls_show(O.tri_class(V.V2{5.0f64, 5.0f64},
    V.V2{0.0f64, 0.0f64}, V.V2{4.0f64, 0.0f64},
    V.V2{0.0f64, 4.0f64})), "outside") == True{} : Bool}

def tri_out():
  {==}

law tri_bound:
  {String.eq(P.tres_cls_show(O.tri_class(V.V2{2.0f64, 0.0f64},
    V.V2{0.0f64, 0.0f64}, V.V2{4.0f64, 0.0f64},
    V.V2{0.0f64, 4.0f64})), "boundary") == True{} : Bool}

def tri_bound():
  {==}

law tri_degen_inv:
  {String.eq(P.tres_show(O.tri_class(V.V2{0.0f64, 0.0f64},
    V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 1.0f64},
    V.V2{2.0f64, 2.0f64})), "invalid-input") == True{} : Bool}

def tri_degen_inv():
  {==}

law tri_nan_inv:
  {String.eq(P.tres_show(O.tri_class(V.V2{F64.nan(), 0.0f64},
    V.V2{0.0f64, 0.0f64}, V.V2{4.0f64, 0.0f64},
    V.V2{0.0f64, 4.0f64})), "invalid-input") == True{} : Bool}

def tri_nan_inv():
  {==}
