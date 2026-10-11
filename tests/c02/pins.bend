import Base

import ../../src/c00/types.bend as T

import ../../src/c01/types.bend as V

import ../../src/c02/types.bend as P

import ../../src/c02/ops.bend as O

def n25() -> F64:
  F64{4719772409484279808u64}

def n25p1() -> F64:
  F64{4719772409618497536u64}

def n25p2() -> F64:
  F64{4719772409752715264u64}

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

def o2_ccw__got() -> Bool:
  String.eq(P.pres_sign_show(O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64})), "pos")

def o2_ccw__want() -> Bool:
  True{}

def o2_cw__got() -> Bool:
  String.eq(P.pres_sign_show(O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}, V.V2{1.0f64, 0.0f64})), "neg")

def o2_cw__want() -> Bool:
  True{}

def o2_coll_zero__got() -> Bool:
  String.eq(P.pres_sign_show(O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, 2.0f64}, V.V2{5.0f64, 5.0f64})), "zero")

def o2_coll_zero__want() -> Bool:
  True{}

def o2_rep_zero__got() -> Bool:
  String.eq(P.pres_sign_show(O.orient2d(V.V2{0.1f64, 0.2f64}, V.V2{0.1f64, 0.2f64}, V.V2{3.5f64, 4.5f64})), "zero")

def o2_rep_zero__want() -> Bool:
  True{}

def o2_near_neg__got() -> Bool:
  String.eq(P.pres_sign_show(O.orient2d(V.V2{n25(), n25p1()}, V.V2{n25p1(), n25p2()}, V.V2{0.0f64, 0.0f64})), "neg")

def o2_near_neg__want() -> Bool:
  True{}

def o2_near_exact__got() -> Bool:
  String.eq(P.pres_sign_show(O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, w251()}, V.V2{4.0f64, 4.0f64})), "neg")

def o2_near_exact__want() -> Bool:
  True{}

def o2_nan_inv__got() -> Bool:
  String.eq(P.pres_show(O.orient2d(V.V2{F64.nan(), 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64})), "invalid-input")

def o2_nan_inv__want() -> Bool:
  True{}

def o2_big150__got() -> Bool:
  String.eq(P.pres_sign_show(O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{big150(), 0.0f64}, V.V2{0.0f64, big150()})), "pos")

def o2_big150__want() -> Bool:
  True{}

def o2_ovf_unc__got() -> Bool:
  String.eq(P.pres_show(O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{F64{9218868437227405311u64}, 0.0f64}, V.V2{0.0f64, F64{9218868437227405311u64}})), "numerical-uncertainty")

def o2_ovf_unc__want() -> Bool:
  True{}

def o2_tiny_exact__got() -> Bool:
  String.eq(P.pres_sign_show(O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{tiny500(), 0.0f64}, V.V2{0.0f64, tiny500()})), "pos")

def o2_tiny_exact__want() -> Bool:
  True{}

def o2_flip__got() -> P.Sign:
  P.pres_sign(O.orient2d(V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}))

def o2_flip__want() -> P.Sign:
  P.sign_neg(P.pres_sign(O.orient2d(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64})))

def o3_neg__got() -> Bool:
  String.eq(P.pres_sign_show(O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64})), "neg")

def o3_neg__want() -> Bool:
  True{}

def o3_pos__got() -> Bool:
  String.eq(P.pres_sign_show(O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64})), "pos")

def o3_pos__want() -> Bool:
  True{}

def o3_coplanar_zero__got() -> Bool:
  String.eq(P.pres_sign_show(O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{1.0f64, 1.0f64, 0.0f64})), "zero")

def o3_coplanar_zero__want() -> Bool:
  True{}

def o3_near_exact__got() -> Bool:
  String.eq(P.pres_sign_show(O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{4.0f64, 0.0f64, 4.0f64}, V.Pt{0.0f64, 4.0f64, 0.0f64}, V.Pt{2.0f64, 2.0f64, w251()})), "neg")

def o3_near_exact__want() -> Bool:
  True{}

def o3_ovf_unc__got() -> Bool:
  String.eq(P.pres_show(O.orient3d(V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, V.Pt{0.0f64, F64{9218868437227405311u64}, 0.0f64}, V.Pt{0.0f64, 0.0f64, F64{9218868437227405311u64}})), "numerical-uncertainty")

def o3_ovf_unc__want() -> Bool:
  True{}

def o3_nan_inv__got() -> Bool:
  String.eq(P.pres_show(O.orient3d(V.Pt{F64.nan(), 0.0f64, 0.0f64}, V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64})), "invalid-input")

def o3_nan_inv__want() -> Bool:
  True{}

def ic_in__got() -> Bool:
  String.eq(P.pres_sign_show(O.incircle(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}, V.V2{0.25f64, 0.25f64})), "pos")

def ic_in__want() -> Bool:
  True{}

def ic_out__got() -> Bool:
  String.eq(P.pres_sign_show(O.incircle(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}, V.V2{2.0f64, 2.0f64})), "neg")

def ic_out__want() -> Bool:
  True{}

def ic_on_zero__got() -> Bool:
  String.eq(P.pres_sign_show(O.incircle(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}, V.V2{1.0f64, 1.0f64})), "zero")

def ic_on_zero__want() -> Bool:
  True{}

def ic_near_exact__got() -> Bool:
  String.eq(P.pres_sign_show(O.incircle(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}, V.V2{q148(), 1.0f64})), "neg")

def ic_near_exact__want() -> Bool:
  True{}

def ic_ovf_unc__got() -> Bool:
  String.eq(P.pres_show(O.incircle(V.V2{0.0f64, 0.0f64}, V.V2{F64{9218868437227405311u64}, 0.0f64}, V.V2{0.0f64, F64{9218868437227405311u64}}, V.V2{1.0f64, 1.0f64})), "numerical-uncertainty")

def ic_ovf_unc__want() -> Bool:
  True{}

def ic_inf_inv__got() -> Bool:
  String.eq(P.pres_show(O.incircle(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, F64{9218868437227405312u64}}, V.V2{0.0f64, 1.0f64}, V.V2{0.25f64, 0.25f64})), "invalid-input")

def ic_inf_inv__want() -> Bool:
  True{}

def is_in__got() -> Bool:
  String.eq(P.pres_sign_show(O.insphere( V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.5f64, 0.5f64, 0.5f64})), "pos")

def is_in__want() -> Bool:
  True{}

def is_out__got() -> Bool:
  String.eq(P.pres_sign_show(O.insphere( V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{2.0f64, 2.0f64, 2.0f64})), "neg")

def is_out__want() -> Bool:
  True{}

def is_on_zero__got() -> Bool:
  String.eq(P.pres_sign_show(O.insphere( V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{1.0f64, 1.0f64, 1.0f64})), "zero")

def is_on_zero__want() -> Bool:
  True{}

def is_near_exact__got() -> Bool:
  String.eq(P.pres_sign_show(O.insphere( V.Pt{1.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{q147(), 1.0f64, 1.0f64})), "neg")

def is_near_exact__want() -> Bool:
  True{}

def is_cofactor_signs__got() -> Bool:
  String.eq(P.pres_sign_show(O.insphere( V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{F64.neg(1.0f64), F64.neg(1.0f64), F64.neg(1.0f64)}, V.Pt{F64.neg(1.0f64), F64.neg(1.0f64), 0.0f64}, V.Pt{0.0f64, F64.neg(1.0f64), 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64})), P.pres_sign_show(O.is_exact(0.0f64, 1.0f64, 0.0f64, F64.neg(1.0f64), F64.neg(1.0f64), F64.neg(1.0f64), F64.neg(1.0f64), F64.neg(1.0f64), 0.0f64, 0.0f64, F64.neg(1.0f64), 0.0f64, 0.0f64, 0.0f64, 0.0f64)))

def is_cofactor_signs__want() -> Bool:
  True{}

def is_cofactor_signs_pos__got() -> Bool:
  String.eq(P.pres_sign_show(O.insphere( V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{F64.neg(1.0f64), F64.neg(1.0f64), F64.neg(1.0f64)}, V.Pt{F64.neg(1.0f64), F64.neg(1.0f64), 0.0f64}, V.Pt{0.0f64, F64.neg(1.0f64), 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64})), "pos")

def is_cofactor_signs_pos__want() -> Bool:
  True{}

def is_ovf_unc__got() -> Bool:
  String.eq(P.pres_show(O.insphere( V.Pt{F64{9218868437227405311u64}, 0.0f64, 0.0f64}, V.Pt{0.0f64, F64{9218868437227405311u64}, 0.0f64}, V.Pt{0.0f64, 0.0f64, F64{9218868437227405311u64}}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{1.0f64, 1.0f64, 1.0f64})), "numerical-uncertainty")

def is_ovf_unc__want() -> Bool:
  True{}

def is_nan_inv__got() -> Bool:
  String.eq(P.pres_show(O.insphere( V.Pt{F64.nan(), 0.0f64, 0.0f64}, V.Pt{0.0f64, 1.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 1.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.5f64, 0.5f64, 0.5f64})), "invalid-input")

def is_nan_inv__want() -> Bool:
  True{}

def seg_proper__got() -> Bool:
  String.eq(P.xres_rel_show(O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, 2.0f64}, V.V2{0.0f64, 2.0f64}, V.V2{2.0f64, 0.0f64})), "proper")

def seg_proper__want() -> Bool:
  True{}

def seg_touch__got() -> Bool:
  String.eq(P.xres_rel_show(O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 1.0f64}, V.V2{1.0f64, 1.0f64}, V.V2{2.0f64, 0.0f64})), "touch")

def seg_touch__want() -> Bool:
  True{}

def seg_disjoint__got() -> Bool:
  String.eq(P.xres_rel_show(O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}, V.V2{1.0f64, 1.0f64})), "disjoint")

def seg_disjoint__want() -> Bool:
  True{}

def seg_overlap__got() -> Bool:
  String.eq(P.xres_rel_show(O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{3.0f64, 0.0f64})), "overlap")

def seg_overlap__want() -> Bool:
  True{}

def seg_ctouch__got() -> Bool:
  String.eq(P.xres_rel_show(O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{2.0f64, 0.0f64})), "touch")

def seg_ctouch__want() -> Bool:
  True{}

def seg_point_on__got() -> Bool:
  String.eq(P.xres_rel_show(O.seg_seg(V.V2{1.0f64, 1.0f64}, V.V2{1.0f64, 1.0f64}, V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, 2.0f64})), "touch")

def seg_point_on__want() -> Bool:
  True{}

def seg_near_exact__got() -> Bool:
  String.eq(P.xres_rel_show(O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, w251()}, V.V2{4.0f64, 4.0f64}, V.V2{5.0f64, 6.0f64})), "disjoint")

def seg_near_exact__want() -> Bool:
  True{}

def seg_ovf_unc__got() -> Bool:
  String.eq(P.xres_show(O.seg_seg(V.V2{0.0f64, 0.0f64}, V.V2{F64{9218868437227405311u64}, F64{9218868437227405311u64}}, V.V2{F64{9218868437227405311u64}, 0.0f64}, V.V2{0.0f64, F64{9218868437227405311u64}})), "numerical-uncertainty")

def seg_ovf_unc__want() -> Bool:
  True{}

def tri_in__got() -> Bool:
  String.eq(P.tres_cls_show(O.tri_class(V.V2{1.0f64, 1.0f64}, V.V2{0.0f64, 0.0f64}, V.V2{4.0f64, 0.0f64}, V.V2{0.0f64, 4.0f64})), "inside")

def tri_in__want() -> Bool:
  True{}

def tri_out__got() -> Bool:
  String.eq(P.tres_cls_show(O.tri_class(V.V2{5.0f64, 5.0f64}, V.V2{0.0f64, 0.0f64}, V.V2{4.0f64, 0.0f64}, V.V2{0.0f64, 4.0f64})), "outside")

def tri_out__want() -> Bool:
  True{}

def tri_bound__got() -> Bool:
  String.eq(P.tres_cls_show(O.tri_class(V.V2{2.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64}, V.V2{4.0f64, 0.0f64}, V.V2{0.0f64, 4.0f64})), "boundary")

def tri_bound__want() -> Bool:
  True{}

def tri_degen_inv__got() -> Bool:
  String.eq(P.tres_show(O.tri_class(V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 1.0f64}, V.V2{2.0f64, 2.0f64})), "invalid-input")

def tri_degen_inv__want() -> Bool:
  True{}

def tri_nan_inv__got() -> Bool:
  String.eq(P.tres_show(O.tri_class(V.V2{F64.nan(), 0.0f64}, V.V2{0.0f64, 0.0f64}, V.V2{4.0f64, 0.0f64}, V.V2{0.0f64, 4.0f64})), "invalid-input")

def tri_nan_inv__want() -> Bool:
  True{}
