import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c06/iv.bend as I
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c07/sol.bend as SO
import ../../src/c07/xs.bend as Q
import ../../src/c07/ss.bend as SS
import ../../src/c07/isect.bend as Y
import ../../src/base/par.bend as B
import ../../src/c11/qcert.bend as QC
import ../../src/c11/qaccel.bend as QA
import ../../src/c11/qdist.bend as QD
import ../../src/c11/qmass.bend as QM
import ../../src/c11/qsect.bend as QN
import ../../src/c11/qinterf.bend as QI

def lo_ok(+v: F64, +hi: F64, +flo: F64) -> Bool:
  Bool.and(F64.is_le(v, hi), F64.is_lt(flo, v))

def on_is_none(m: Maybe<&2, QN.ON>) -> Bool:
  match m:
    case None{}: True{}
    case Some{w}: False{}

def on_none(+a: F64, +b: F64, +c: F64, +d: F64) -> Bool:
  on_is_none(QN.plane_on(a, b, c, d))

def gvpl() -> G.GVal:
  G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}}}

def a9() -> List<&2, I.I>:
  [I.ipt(1.0f64), I.ipt(2.0f64), I.ipt(3.0f64), I.ipt(4.0f64), I.ipt(5.0f64), I.ipt(6.0f64),
    I.ipt(7.0f64), I.ipt(8.0f64), I.ipt(9.0f64)]

def i9() -> List<&2, I.I>:
  [I.ipt(1.0f64), I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(1.0f64), I.ipt(0.0f64),
    I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(1.0f64)]

def mm_ok(+xs: List<&2, I.I>, +i: Nat, +v: F64) -> Bool:
  +x = M.i_nth(xs, i)
  Bool.and(F64.is_le(I.i_lo(x), v),
    Bool.and(F64.is_le(v, I.i_hi(x)), F64.is_lt(F64.abs(F64.sub(I.imid(x), v)), 0.000001f64)))

def cen_w() -> List<&2, I.I>:
  [I.ipt(100.0f64), I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(200.0f64), I.ipt(0.0f64),
    I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(300.0f64)]

def iv_ok(+x: I.I, +v: F64) -> Bool:
  Bool.and(F64.is_le(I.i_lo(x), v),
    Bool.and(F64.is_le(v, I.i_hi(x)), F64.is_lt(F64.abs(F64.sub(I.imid(x), v)), 0.000001f64)))

def st_certified__got() -> U64:
  QC.st_certified()

def st_certified__want() -> U64:
  1u64

def st_estimated__got() -> U64:
  QC.st_estimated()

def st_estimated__want() -> U64:
  2u64

def st_assumed__got() -> U64:
  QC.st_assumed()

def st_assumed__want() -> U64:
  3u64

def st_show_cert__got() -> String:
  QC.st_show(1u64)

def st_show_cert__want() -> String:
  "certified"

def st_show_est__got() -> String:
  QC.st_show(2u64)

def st_show_est__want() -> String:
  "estimated"

def st_show_assumed__got() -> String:
  QC.st_show(3u64)

def st_show_assumed__want() -> String:
  "assumed"

def st_show_proven__got() -> String:
  QC.st_show(0u64)

def st_show_proven__want() -> String:
  "proven"

def bv_show__got() -> String:
  QC.bv_show(QC.bv_mk(1.0f64, 2.0f64, 1u64))

def bv_show__want() -> String:
  "[1, 2] certified"

def bv_lo__got() -> U64:
  F64.bits(QC.bv_lo(QC.bv_mk(1.5f64, F64.neg(2.5f64), 2u64)))

def bv_lo__want() -> U64:
  4609434218613702656u64

def bv_st__got() -> U64:
  QC.bv_st(QC.bv_mk(1.5f64, F64.neg(2.5f64), 2u64))

def bv_st__want() -> U64:
  2u64

def depth_max__got() -> Nat:
  QC.depth_max()

def depth_max__want() -> Nat:
  6n

def depth_dflt__got() -> Nat:
  QC.depth_dflt()

def depth_dflt__want() -> Nat:
  4n

def depth_ok_6__got() -> Bool:
  QC.depth_ok(6n)

def depth_ok_6__want() -> Bool:
  True{}

def depth_ok_7__got() -> Bool:
  QC.depth_ok(7n)

def depth_ok_7__want() -> Bool:
  False{}

def qfail__got() -> String:
  QC.qfail("invalid-input", "mass", "depth needs 0..6", "mass NODE [DEPTH]")

def qfail__want() -> String:
  "error invalid-input | mass | why: depth needs 0..6 | fix: mass NODE [DEPTH]"

def inc_s_0__got() -> String:
  QC.inc_s(0n)

def inc_s_0__want() -> String:
  ""

def inc_s_3__got() -> String:
  QC.inc_s(3n)

def inc_s_3__want() -> String:
  " incomplete-cells=3"

def mass_dn_none__got() -> Nat:
  QM.mass_dn(None{})

def mass_dn_none__want() -> Nat:
  99n

def mass_dn_some__got() -> Nat:
  QM.mass_dn(Some{4u64})

def mass_dn_some__want() -> Nat:
  4n

def mass_depth_dflt__got() -> Nat:
  QM.mass_depth("")

def mass_depth_dflt__want() -> Nat:
  4n

def mass_depth_4__got() -> Nat:
  QM.mass_depth("4")

def mass_depth_4__want() -> Nat:
  4n

def mass_depth_garbage__got() -> Nat:
  QM.mass_depth("xyz")

def mass_depth_garbage__want() -> Nat:
  99n

def mass_depth_7__got() -> Nat:
  QM.mass_depth("7")

def mass_depth_7__want() -> Nat:
  7n

def mass_depth_0__got() -> Nat:
  QM.mass_depth("0")

def mass_depth_0__want() -> Nat:
  0n

def corner_0__got() -> V.Point:
  QA.ab_corner(QA.ab_mk(0.0f64, 10.0f64, 0.0f64, 20.0f64, 0.0f64, 30.0f64), 0n)

def corner_0__want() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def corner_3__got() -> V.Point:
  QA.ab_corner(QA.ab_mk(0.0f64, 10.0f64, 0.0f64, 20.0f64, 0.0f64, 30.0f64), 3n)

def corner_3__want() -> V.Point:
  V.Pt{10.0f64, 20.0f64, 0.0f64}

def corner_7__got() -> V.Point:
  QA.ab_corner(QA.ab_mk(0.0f64, 10.0f64, 0.0f64, 20.0f64, 0.0f64, 30.0f64), 7n)

def corner_7__want() -> V.Point:
  V.Pt{10.0f64, 20.0f64, 30.0f64}

def ab_q_zero__got() -> U64:
  QA.ab_q(5.0f64, 0.0f64, 0.0f64)

def ab_q_zero__want() -> U64:
  0u64

def ab_key__got() -> U64:
  QA.ab_key(QA.ab_mk(0.0f64, 10.0f64, 0.0f64, 10.0f64, 0.0f64, 10.0f64),
    QA.ab_mk(0.0f64, 10.0f64, 0.0f64, 10.0f64, 0.0f64, 10.0f64))

def ab_key__want() -> U64:
  537395712u64

def ab_cx__got() -> U64:
  F64.bits(QA.ab_cx(QA.ab_mk(0.0f64, 10.0f64, 0.0f64, 10.0f64, 0.0f64, 10.0f64)))

def ab_cx__want() -> U64:
  4617315517961601024u64

def hull_x0__got() -> U64:
  F64.bits(QA.ab_x0(QA.ab_hull(QA.ab_mk(0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64),
    QA.ab_mk(2.0f64, 3.0f64, 2.0f64, 3.0f64, 2.0f64, 3.0f64))))

def hull_x0__want() -> U64:
  0u64

def hull_x1__got() -> U64:
  F64.bits(QA.ab_x1(QA.ab_hull(QA.ab_mk(0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64),
    QA.ab_mk(2.0f64, 3.0f64, 2.0f64, 3.0f64, 2.0f64, 3.0f64))))

def hull_x1__want() -> U64:
  4613937818241073152u64

def disjoint_far__got() -> Bool:
  QA.ab_disjoint(QA.ab_mk(0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64),
    QA.ab_mk(2.0f64, 3.0f64, 2.0f64, 3.0f64, 2.0f64, 3.0f64))

def disjoint_far__want() -> Bool:
  True{}

def disjoint_touch__got() -> Bool:
  QA.ab_disjoint(QA.ab_mk(0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64),
    QA.ab_mk(1.0f64, 2.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64))

def disjoint_touch__want() -> Bool:
  False{}

def disjoint_ov__got() -> Bool:
  QA.ab_disjoint(QA.ab_mk(0.0f64, 2.0f64, 0.0f64, 2.0f64, 0.0f64, 2.0f64),
    QA.ab_mk(1.0f64, 3.0f64, 1.0f64, 3.0f64, 1.0f64, 3.0f64))

def disjoint_ov__want() -> Bool:
  False{}

def overlap_far__got() -> Bool:
  QA.ab_overlap(QA.ab_mk(0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64),
    QA.ab_mk(2.0f64, 3.0f64, 2.0f64, 3.0f64, 2.0f64, 3.0f64))

def overlap_far__want() -> Bool:
  False{}

def overlap_ov__got() -> Bool:
  QA.ab_overlap(QA.ab_mk(0.0f64, 2.0f64, 0.0f64, 2.0f64, 0.0f64, 2.0f64),
    QA.ab_mk(1.0f64, 3.0f64, 1.0f64, 3.0f64, 1.0f64, 3.0f64))

def overlap_ov__want() -> Bool:
  True{}

def zero_x0__got() -> U64:
  F64.bits(QA.ab_x0(QA.ab_zero()))

def zero_x0__want() -> U64:
  0u64

def of_iv_x0__got() -> U64:
  F64.bits(QA.ab_x0(QA.ab_of_iv([I.I{1.0f64, 2.0f64}, I.I{3.0f64, 4.0f64}, I.I{5.0f64, 6.0f64}])))

def of_iv_x0__want() -> U64:
  4607182418800017408u64

def ab_lo_inside__got() -> U64:
  F64.bits(QA.ab_lo(V.Pt{5.0f64, 5.0f64, 5.0f64},
    QA.ab_mk(0.0f64, 10.0f64, 0.0f64, 10.0f64, 0.0f64, 10.0f64)))

def ab_lo_inside__want() -> U64:
  0u64

def ab_lo_axis__got() -> Bool:
  lo_ok(QA.ab_lo(V.Pt{15.0f64, 5.0f64, 5.0f64},
    QA.ab_mk(0.0f64, 10.0f64, 0.0f64, 10.0f64, 0.0f64, 10.0f64)), 5.0f64, 4.999999f64)

def ab_lo_axis__want() -> Bool:
  True{}

def ab_lo_345__got() -> Bool:
  lo_ok(QA.ab_lo(V.Pt{13.0f64, 14.0f64, 5.0f64},
    QA.ab_mk(0.0f64, 10.0f64, 0.0f64, 10.0f64, 0.0f64, 10.0f64)), 5.0f64, 4.999999f64)

def ab_lo_345__want() -> Bool:
  True{}

def ab_ab_lo_axis__got() -> Bool:
  lo_ok(QA.ab_ab_lo(QA.ab_mk(0.0f64, 10.0f64, 0.0f64, 10.0f64, 0.0f64, 10.0f64),
    QA.ab_mk(15.0f64, 25.0f64, 0.0f64, 10.0f64, 0.0f64, 10.0f64)), 5.0f64, 4.999999f64)

def ab_ab_lo_axis__want() -> Bool:
  True{}

def n_sort__got() -> List<&2, Nat>:
  QA.n_sort([3n, 1n, 2n])

def n_sort__want() -> List<&2, Nat>:
  [1n, 2n, 3n]

def n_dedup__got() -> List<&2, Nat>:
  QA.n_dedup([3n, 1n, 2n, 1n])

def n_dedup__want() -> List<&2, Nat>:
  [3n, 2n, 1n]

def n_mem_hit__got() -> Bool:
  QA.n_mem(2n, [1n, 2n])

def n_mem_hit__want() -> Bool:
  True{}

def n_mem_miss__got() -> Bool:
  QA.n_mem(5n, [1n, 2n])

def n_mem_miss__want() -> Bool:
  False{}

def n_share_hit__got() -> Bool:
  QA.n_share([1n, 9n], [9n, 8n])

def n_share_hit__want() -> Bool:
  True{}

def n_share_miss__got() -> Bool:
  QA.n_share([1n], [2n])

def n_share_miss__want() -> Bool:
  False{}

def ak_ids__got() -> List<&2, Nat>:
  QA.ak_ids([QA.Ak{5u64, 0n}, QA.Ak{3u64, 1n}])

def ak_ids__want() -> List<&2, Nat>:
  [0n, 1n]

def ak_even__got() -> List<&2, Nat>:
  QA.ak_ids(QA.ak_even([QA.Ak{0u64, 0n}, QA.Ak{0u64, 1n}, QA.Ak{0u64, 2n}]))

def ak_even__want() -> List<&2, Nat>:
  [0n, 2n]

def ak_odd__got() -> List<&2, Nat>:
  QA.ak_ids(QA.ak_odd([QA.Ak{0u64, 0n}, QA.Ak{0u64, 1n}, QA.Ak{0u64, 2n}]))

def ak_odd__want() -> List<&2, Nat>:
  [1n]

def abs_hull_nil__got() -> QA.Ab:
  QA.abs_hull([])

def abs_hull_nil__want() -> QA.Ab:
  QA.ab_zero()

def bvh_box_nil__got() -> QA.Ab:
  QA.bvh_box(QA.bvh_build([]))

def bvh_box_nil__want() -> QA.Ab:
  QA.ab_zero()

def bvh_has_hit__got() -> Bool:
  QA.bvh_has(QA.bvh_build([QA.ab_mk(0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64)]),
    QA.ab_mk(0.5f64, 0.6f64, 0.5f64, 0.6f64, 0.5f64, 0.6f64),
    B.tb_of(QA.Ab, [QA.ab_mk(0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64)], QA.ab_zero()))

def bvh_has_hit__want() -> Bool:
  True{}

def bvh_has_miss__got() -> Bool:
  QA.bvh_has(QA.bvh_build([QA.ab_mk(0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64)]),
    QA.ab_mk(5.0f64, 6.0f64, 5.0f64, 6.0f64, 5.0f64, 6.0f64),
    B.tb_of(QA.Ab, [QA.ab_mk(0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64)], QA.ab_zero()))

def bvh_has_miss__want() -> Bool:
  False{}

def fd_allok_nil__got() -> Bool:
  QA.fd_allok([])

def fd_allok_nil__want() -> Bool:
  True{}

def split_lo__got() -> U64:
  F64.bits(I.i_lo(M.i_nth(QM.split(I.I{0.0f64, 10.0f64}), 0n)))

def split_lo__want() -> U64:
  0u64

def split_hi__got() -> U64:
  F64.bits(I.i_hi(M.i_nth(QM.split(I.I{0.0f64, 10.0f64}), 1n)))

def split_hi__want() -> U64:
  4621819117588971520u64

def split_mid_up__got() -> Bool:
  F64.is_lt(5.0f64, I.i_hi(M.i_nth(QM.split(I.I{0.0f64, 10.0f64}), 0n)))

def split_mid_up__want() -> Bool:
  True{}

def split_mid_dn__got() -> Bool:
  F64.is_lt(I.i_lo(M.i_nth(QM.split(I.I{0.0f64, 10.0f64}), 1n)), 5.0f64)

def split_mid_dn__want() -> Bool:
  True{}

def mc_zero_k__got() -> U64:
  QM.mc_k(QM.mc_zero())

def mc_zero_k__want() -> U64:
  0u64

def mc_zero_v__got() -> I.I:
  QM.mc_v(QM.mc_zero())

def mc_zero_v__want() -> I.I:
  I.I{0.0f64, 0.0f64}

def sub1__got() -> List<&2, List<&2, I.I>>:
  QM.sub1(I.I{0.0f64, 1.0f64}, I.I{2.0f64, 3.0f64}, [I.I{4.0f64, 5.0f64}])

def sub1__want() -> List<&2, List<&2, I.I>>:
  [[I.I{0.0f64, 1.0f64}, I.I{2.0f64, 3.0f64}, I.I{4.0f64, 5.0f64}]]

def sub3_len__got() -> Nat:
  List.length(&2, List<&2, I.I>,
    QM.sub3([I.I{0.0f64, 2.0f64}, I.I{0.0f64, 2.0f64}, I.I{2.0f64, 4.0f64}]))

def sub3_len__want() -> Nat:
  8n

def sub_go_len__got() -> Nat:
  List.length(&2, List<&2, I.I>,
    QM.sub_go(1n, [[I.I{0.0f64, 2.0f64}, I.I{0.0f64, 2.0f64}, I.I{0.0f64, 2.0f64}]]))

def sub_go_len__want() -> Nat:
  8n

def ex_c__got() -> U64:
  F64.bits(QD.ex_c(V.Pt{1.0f64, 2.0f64, 3.0f64}, 1n))

def ex_c__want() -> U64:
  4611686018427387904u64

def ex_wit__got() -> V.Point:
  QD.ex_wit([V.Pt{1.0f64, 2.0f64, 3.0f64}, V.Pt{4.0f64, 0.0f64, 5.0f64}], 0n, True{},
    V.Pt{0.0f64, 0.0f64, 0.0f64})

def ex_wit__want() -> V.Point:
  V.Pt{4.0f64, 0.0f64, 5.0f64}

def near_best__got() -> U64:
  F64.bits(QD.near_best(V.Pt{0.0f64, 0.0f64, 0.0f64},
    [V.Pt{3.0f64, 4.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 10.0f64}], V.dbl_max()))

def near_best__want() -> U64:
  4617315517961601024u64

def near_at__got() -> V.Point:
  QD.near_at(V.Pt{0.0f64, 0.0f64, 0.0f64},
    [V.Pt{3.0f64, 4.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 10.0f64}], 5.0f64)

def near_at__want() -> V.Point:
  V.Pt{3.0f64, 4.0f64, 0.0f64}

def pts_min__got() -> U64:
  F64.bits(QD.pts_min([V.Pt{3.0f64, 4.0f64, 0.0f64}], [V.Pt{0.0f64, 0.0f64, 0.0f64}], V.dbl_max()))

def pts_min__want() -> U64:
  4617315517961601024u64

def eb_of_degen__got() -> QA.Ab:
  QD.eb_of(Ty.EK_degenerate{}, V.Pt{1.0f64, 2.0f64, 3.0f64}, V.Pt{4.0f64, 5.0f64, 6.0f64})

def eb_of_degen__want() -> QA.Ab:
  QA.ab_mk(1.0f64, 1.0f64, 2.0f64, 2.0f64, 3.0f64, 3.0f64)

def fb_one_dflt__got() -> QA.Ab:
  QD.fb_one(SO.fd_dflt(), QA.ab_zero())

def fb_one_dflt__want() -> QA.Ab:
  QA.ab_zero()

def cls_k_interior__got() -> String:
  QN.cls_k(0u64)

def cls_k_interior__want() -> String:
  "interior"

def cls_k_seam__got() -> String:
  QN.cls_k(16u64)

def cls_k_seam__want() -> String:
  "seam"

def cls_k_astart__got() -> String:
  QN.cls_k(1u64)

def cls_k_astart__want() -> String:
  "a-start "

def cls_s_tangent__got() -> String:
  QN.cls_s(32u64)

def cls_s_tangent__want() -> String:
  "tangent interior"

def hit_k_ov__got() -> U64:
  QN.hit_k(Q.H_ov{I.I{0.0f64, 1.0f64}, I.I{0.0f64, 1.0f64}})

def hit_k_ov__want() -> U64:
  1u64

def hit_k_no__got() -> U64:
  QN.hit_k(Q.H_no{"w"})

def hit_k_no__want() -> U64:
  3u64

def hit_k_pt__got() -> U64:
  QN.hit_k(Q.H_pt{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, [], 0u64})

def hit_k_pt__want() -> U64:
  0u64

def hit_k_un__got() -> U64:
  QN.hit_k(Q.H_un{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, []})

def hit_k_un__want() -> U64:
  2u64

def hx_k_un3__got() -> U64:
  QN.hx_k(Y.Hx_un3{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}})

def hx_k_un3__want() -> U64:
  2u64

def hx_k_uv__got() -> U64:
  QN.hx_k(Y.Hx_uv{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, [], 0u64})

def hx_k_uv__want() -> U64:
  0u64

def hx_k_c__got() -> U64:
  QN.hx_k(Y.Hx_c{Q.H_ov{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}}})

def hx_k_c__want() -> U64:
  1u64

def hit_s_ov__got() -> String:
  QN.hit_s(Q.H_ov{I.I{1.0f64, 2.0f64}, I.I{3.0f64, 4.0f64}})

def hit_s_ov__want() -> String:
  "overlap s=[1, 2] t=[3, 4]"

def si__got() -> String:
  QN.si(I.I{1.0f64, 2.0f64})

def si__want() -> String:
  "[1, 2]"

def sp2_nil__got() -> String:
  QN.sp2([])

def sp2_nil__want() -> String:
  "-"

def sp2_pair__got() -> String:
  QN.sp2([I.I{1.0f64, 2.0f64}, I.I{3.0f64, 4.0f64}])

def sp2_pair__want() -> String:
  "([1, 2], [3, 4])"

def report_nil__got() -> String:
  QN.report([])

def report_nil__want() -> String:
  "summary points=0 overlaps=0 unresolved=0"

def cnt_nil__got() -> Nat:
  QN.cnt([], 5u64)

def cnt_nil__want() -> Nat:
  0n

def cnt_hit__got() -> Nat:
  QN.cnt([Y.Hx_un3{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}}], 2u64)

def cnt_hit__want() -> Nat:
  1n

def cnt_miss__got() -> Nat:
  QN.cnt([Y.Hx_un3{I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}}], 0u64)

def cnt_miss__want() -> Nat:
  0n

def coord_x__got() -> String:
  QN.coord_name(0u64, 0n)

def coord_x__want() -> String:
  "x"

def coord_z__got() -> String:
  QN.coord_name(0u64, 2n)

def coord_z__want() -> String:
  "z"

def coord_v2__got() -> String:
  QN.coord_name(3u64, 3n)

def coord_v2__want() -> String:
  "v2"

def coord_u__got() -> String:
  QN.coord_name(1u64, 0n)

def coord_u__want() -> String:
  "u"

def sg_add_nc__got() -> Nat:
  QN.sg_nc(QN.sg_add(QN.sg_empty(), "l", 2n, 3n, 4n, True{}))

def sg_add_nc__want() -> Nat:
  2n

def sg_add_nu__got() -> Nat:
  QN.sg_nu(QN.sg_add(QN.sg_empty(), "l", 2n, 3n, 4n, True{}))

def sg_add_nu__want() -> Nat:
  3n

def sg_add_ok__got() -> Bool:
  QN.sg_ok(QN.sg_add(QN.sg_empty(), "l", 2n, 3n, 4n, True{}))

def sg_add_ok__want() -> Bool:
  True{}

def sg_cat_nc__got() -> Nat:
  QN.sg_nc(QN.sg_cat(QN.sg_add(QN.sg_empty(), "a", 1n, 0n, 0n, True{}),
    QN.sg_add(QN.sg_empty(), "b", 2n, 0n, 0n, True{})))

def sg_cat_nc__want() -> Nat:
  3n

def sg_cat_s__got() -> String:
  QN.sg_s(QN.sg_cat(QN.sg_add(QN.sg_empty(), "a", 1n, 0n, 0n, True{}),
    QN.sg_add(QN.sg_empty(), "b", 2n, 0n, 0n, True{})))

def sg_cat_s__want() -> String:
  "ab"

def sg_cat_ok__got() -> Bool:
  QN.sg_ok(QN.sg_cat(QN.sg_add(QN.sg_empty(), "a", 1n, 0n, 0n, True{}),
    QN.sg_add(QN.sg_empty(), "b", 0n, 0n, 0n, False{})))

def sg_cat_ok__want() -> Bool:
  False{}

def ss_nbr__got() -> Nat:
  QN.ss_nbr(SS.Ss{True{}, [SS.Br{True{}, [], []}], [[I.I{0.0f64, 0.0f64}]]})

def ss_nbr__want() -> Nat:
  1n

def ss_nun__got() -> Nat:
  QN.ss_nun(SS.Ss{True{}, [SS.Br{True{}, [], []}], [[I.I{0.0f64, 0.0f64}]]})

def ss_nun__want() -> Nat:
  1n

def ss_ok__got() -> Bool:
  QN.ss_ok(SS.Ss{True{}, [SS.Br{True{}, [], []}], [[I.I{0.0f64, 0.0f64}]]})

def ss_ok__want() -> Bool:
  True{}

def sect_miss__got() -> String:
  QN.sg_s(QN.sect_miss(2n))

def sect_miss__want() -> String:
  "face 2:\nunresolved no-descriptor\n"

def sr_coin__got() -> String:
  QN.sr_go(True{}, SS.Ss{True{}, [], []}, 0u64, gvpl(), gvpl())

def sr_coin__want() -> String:
  "overlap surfaces coincide\nsummary curves=0 unresolved=0 coincident=1"

def br_s__got() -> String:
  QN.br_s(SS.Br{True{}, [], []}, 0u64, gvpl(), gvpl())

def br_s__want() -> String:
  "curve closed samples=0\n"

def uns_s_nil__got() -> String:
  QN.uns_s([])

def uns_s_nil__want() -> String:
  ""

def eps_s_nil__got() -> String:
  QN.eps_s([], 0u64)

def eps_s_nil__want() -> String:
  ""

def drop2__got() -> List<&2, I.I>:
  QN.drop2([I.I{1.0f64, 1.0f64}, I.I{2.0f64, 2.0f64}, I.I{3.0f64, 3.0f64}])

def drop2__want() -> List<&2, I.I>:
  [I.I{3.0f64, 3.0f64}]

def par_a__got() -> List<&2, I.I>:
  QN.par_a(1u64, gvpl(), [I.I{1.0f64, 2.0f64}], [I.I{3.0f64, 4.0f64}])

def par_a__want() -> List<&2, I.I>:
  [I.I{1.0f64, 2.0f64}]

def plane_on_some__got() -> Maybe<&2, QN.ON>:
  QN.plane_on(0.0f64, 0.0f64, 1.0f64, 5.0f64)

def plane_on_some__want() -> Maybe<&2, QN.ON>:
  Some{QN.ON{V.Pt{0.0f64, 0.0f64, 5.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}}}

def plane_on_degen__got() -> Bool:
  on_none(0.0f64, 0.0f64, 0.0f64, 5.0f64)

def plane_on_degen__want() -> Bool:
  True{}

def plane_on_ok__got() -> Bool:
  on_none(0.0f64, 0.0f64, 1.0f64, 5.0f64)

def plane_on_ok__want() -> Bool:
  False{}

def hint_of__got() -> V.Dir:
  QN.hint_of(1.0f64, 0.0f64, 0.0f64)

def hint_of__want() -> V.Dir:
  V.Dr{0.0f64, 1.0f64, 0.0f64}

def fin4_ok__got() -> Bool:
  QN.fin4(1.0f64, 2.0f64, 3.0f64, 4.0f64)

def fin4_ok__want() -> Bool:
  True{}

def fin4_nan__got() -> Bool:
  QN.fin4(F64.nan(), 0.0f64, 0.0f64, 0.0f64)

def fin4_nan__want() -> Bool:
  False{}

def pl_ident__got() -> Bool:
  QN.pl_ident(M.pl_id())

def pl_ident__want() -> Bool:
  True{}

def cls_outside__got() -> String:
  QI.cls_s(0u64)

def cls_outside__want() -> String:
  "outside"

def cls_inside__got() -> String:
  QI.cls_s(1u64)

def cls_inside__want() -> String:
  "inside"

def cls_boundary__got() -> String:
  QI.cls_s(3u64)

def cls_boundary__want() -> String:
  "boundary"

def cls_uncertain__got() -> String:
  QI.cls_s(2u64)

def cls_uncertain__want() -> String:
  "uncertain | why: every ray met a tangency, an edge or an unsupported face | fix: move the point off the boundary"

def fin3_ok__got() -> Bool:
  QI.fin3(1.0f64, 2.0f64, 3.0f64)

def fin3_ok__want() -> Bool:
  True{}

def fin3_nan__got() -> Bool:
  QI.fin3(F64.nan(), 0.0f64, 0.0f64)

def fin3_nan__want() -> Bool:
  False{}

def ag_nin__got() -> Nat:
  QI.ag_nin(QI.ag_add(QI.ag_zero(), 1u64))

def ag_nin__want() -> Nat:
  1n

def ag_counts__got() -> String:
  QI.ag_counts(1n, 2n, 3n, 4n, 5n, 6n)

def ag_counts__want() -> String:
  "a:in=1 out=2 uncertain=3 b:in=4 out=5 uncertain=6"

def box_in_box_hit__got() -> Bool:
  QI.box_in_box(QA.ab_mk(1.0f64, 2.0f64, 1.0f64, 2.0f64, 1.0f64, 2.0f64),
    QA.ab_mk(0.0f64, 3.0f64, 0.0f64, 3.0f64, 0.0f64, 3.0f64))

def box_in_box_hit__want() -> Bool:
  True{}

def box_in_box_miss__got() -> Bool:
  QI.box_in_box(QA.ab_mk(0.0f64, 3.0f64, 0.0f64, 3.0f64, 0.0f64, 3.0f64),
    QA.ab_mk(1.0f64, 2.0f64, 1.0f64, 2.0f64, 1.0f64, 2.0f64))

def box_in_box_miss__want() -> Bool:
  False{}

def fi_real__got() -> List<&2, SO.Fi>:
  QI.fi_real([SO.Fi{"contact-edge-face", 1n, 2n}, SO.Fi{"gap", 3n, 4n}])

def fi_real__want() -> List<&2, SO.Fi>:
  [SO.Fi{"gap", 3n, 4n}]

def cav_line_inside__got() -> String:
  QI.cav_line(1u64, True{}, 2n, 0n)

def cav_line_inside__want() -> String:
  "cavity 2 inside 0 status=certified"

def cav_line_outside__got() -> String:
  QI.cav_line(0u64, False{}, 2n, 0n)

def cav_line_outside__want() -> String:
  "cavity 2 outside 0 status=certified"

def cav_line_nest__got() -> String:
  QI.cav_line(2u64, True{}, 2n, 0n)

def cav_line_nest__want() -> String:
  "cavity 2 nesting-uncertain 0 status=estimated"

def cav_pair_disj__got() -> String:
  QI.cav_pair_line(0u64, True{}, 1n, 2n)

def cav_pair_disj__want() -> String:
  "cavities 1 2 disjoint status=certified\n"

def cav_pair_nest__got() -> String:
  QI.cav_pair_line(1u64, False{}, 1n, 2n)

def cav_pair_nest__want() -> String:
  "cavities 1 2 nested status=certified\n"

def cav_pair_unc__got() -> String:
  QI.cav_pair_line(0u64, False{}, 1n, 2n)

def cav_pair_unc__want() -> String:
  "cavities 1 2 uncertain status=estimated\n"

def rel_vb_interf__got() -> String:
  QI.rel_vb(False{}, True{}, False{}, False{}, 1n, 2n, 0n, QI.Ag{0n, 3n, 0n})

def rel_vb_interf__want() -> String:
  "relation interference status=certified a:in=1 out=2 uncertain=0 b:in=0 out=3 uncertain=0"

def rel_vb_unc__got() -> String:
  QI.rel_vb(False{}, True{}, False{}, False{}, 0n, 2n, 1n, QI.Ag{0n, 3n, 0n})

def rel_vb_unc__want() -> String:
  "relation uncertain status=estimated a:in=0 out=2 uncertain=1 b:in=0 out=3 uncertain=0 boxes-overlap=1"

def rel_vb_disj_box__got() -> String:
  QI.rel_vb(True{}, True{}, False{}, False{}, 0n, 0n, 9n, QI.Ag{0n, 0n, 9n})

def rel_vb_disj_box__want() -> String:
  "relation disjoint status=certified"

def rel_vb_disj_samp__got() -> String:
  QI.rel_vb(False{}, False{}, False{}, False{}, 0n, 2n, 0n, QI.Ag{0n, 3n, 0n})

def rel_vb_disj_samp__want() -> String:
  "relation disjoint status=certified"

def mmul_id_0__got() -> Bool:
  mm_ok(QM.mmul(a9(), i9()), 0n, 1.0f64)

def mmul_id_0__want() -> Bool:
  True{}

def mmul_id_8__got() -> Bool:
  mm_ok(QM.mmul(a9(), i9()), 8n, 9.0f64)

def mmul_id_8__want() -> Bool:
  True{}

def mmul_id_5__got() -> Bool:
  mm_ok(QM.mmul(a9(), i9()), 5n, 6.0f64)

def mmul_id_5__want() -> Bool:
  True{}

def mmult_t_1__got() -> Bool:
  mm_ok(QM.mmult(i9(), a9()), 1n, 4.0f64)

def mmult_t_1__want() -> Bool:
  True{}

def mmult_t_6__got() -> Bool:
  mm_ok(QM.mmult(i9(), a9()), 6n, 3.0f64)

def mmult_t_6__want() -> Bool:
  True{}

def mmul_sq_0__got() -> Bool:
  mm_ok(QM.mmul(a9(), a9()), 0n, 30.0f64)

def mmul_sq_0__want() -> Bool:
  True{}

def mmul_sq_4__got() -> Bool:
  mm_ok(QM.mmul(a9(), a9()), 4n, 81.0f64)

def mmul_sq_4__want() -> Bool:
  True{}

def sh9_xx__got() -> Bool:
  iv_ok(M.i_nth(QM.sh9(cen_w(), I.ipt(10.0f64), [I.ipt(1.0f64), I.ipt(2.0f64), I.ipt(3.0f64)]),
    0n), F64.neg(30.0f64))

def sh9_xx__want() -> Bool:
  True{}

def sh9_yy__got() -> Bool:
  iv_ok(M.i_nth(QM.sh9(cen_w(), I.ipt(10.0f64), [I.ipt(1.0f64), I.ipt(2.0f64), I.ipt(3.0f64)]),
    4n), 100.0f64)

def sh9_yy__want() -> Bool:
  True{}

def sh9_xy__got() -> Bool:
  iv_ok(M.i_nth(QM.sh9(cen_w(), I.ipt(10.0f64), [I.ipt(1.0f64), I.ipt(2.0f64), I.ipt(3.0f64)]),
    1n), 20.0f64)

def sh9_xy__want() -> Bool:
  True{}

def pk6_3__got() -> Bool:
  iv_ok(M.i_nth(QM.pk6([I.ipt(0.0f64), I.ipt(1.0f64), I.ipt(2.0f64), I.ipt(3.0f64), I.ipt(4.0f64),
    I.ipt(5.0f64), I.ipt(6.0f64), I.ipt(7.0f64), I.ipt(8.0f64)]), 3n), 1.0f64)

def pk6_3__want() -> Bool:
  True{}

def dec_nan_none__got() -> Bool:
  S.is_some(S.dec("nan"))

def dec_nan_none__want() -> Bool:
  False{}

def dec_abc_none__got() -> Bool:
  S.is_some(S.dec("abc"))

def dec_abc_none__want() -> Bool:
  False{}

def dec_empty_none__got() -> Bool:
  S.is_some(S.dec(""))

def dec_empty_none__want() -> Bool:
  False{}

def dec_5_some__got() -> Bool:
  S.is_some(S.dec("5"))

def dec_5_some__want() -> Bool:
  True{}

def wit_line_t__got() -> String:
  QI.wit_line(True{}, "relation uncertain status=estimated")

def wit_line_t__want() -> String:
  "relation interference status=certified witness=subdiv"

def wit_line_f__got() -> String:
  QI.wit_line(False{}, "relation uncertain status=estimated")

def wit_line_f__want() -> String:
  "relation uncertain status=estimated"

def wov_bx__got() -> List<&2, I.I>:
  QI.wov_bx(QA.Ab{0.0f64, 10.0f64, 0.0f64, 10.0f64, 0.0f64, 10.0f64},
    QA.Ab{5.0f64, 15.0f64, 0.0f64, 10.0f64, 0.0f64, 10.0f64})

def wov_bx__want() -> List<&2, I.I>:
  [I.I{5.0f64, 10.0f64}, I.I{0.0f64, 10.0f64}, I.I{0.0f64, 10.0f64}]
