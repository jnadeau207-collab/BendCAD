import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c06/iv.bend as I
import ../../src/c06/model.bend as M
import ../../src/c07/sol.bend as SO
import ../../src/c07/xs.bend as Q
import ../../src/c07/ss.bend as SS
import ../../src/c07/isect.bend as Y
import ../../src/c11/qcert.bend as QC
import ../../src/c11/qaccel.bend as QA
import ../../src/c11/qdist.bend as QD
import ../../src/c11/qmass.bend as QM
import ../../src/c11/qsect.bend as QN
import ../../src/c11/qinterf.bend as QI

law ab_mk_x0:
  for +x0: F64
  for +x1: F64
  for +y0: F64
  for +y1: F64
  for +z0: F64
  for +z1: F64
  {QA.ab_x0(QA.ab_mk(x0, x1, y0, y1, z0, z1)) == x0 : F64}

law ab_mk_x1:
  for +x0: F64
  for +x1: F64
  for +y0: F64
  for +y1: F64
  for +z0: F64
  for +z1: F64
  {QA.ab_x1(QA.ab_mk(x0, x1, y0, y1, z0, z1)) == x1 : F64}

law ab_mk_y0:
  for +x0: F64
  for +x1: F64
  for +y0: F64
  for +y1: F64
  for +z0: F64
  for +z1: F64
  {QA.ab_y0(QA.ab_mk(x0, x1, y0, y1, z0, z1)) == y0 : F64}

law ab_mk_y1:
  for +x0: F64
  for +x1: F64
  for +y0: F64
  for +y1: F64
  for +z0: F64
  for +z1: F64
  {QA.ab_y1(QA.ab_mk(x0, x1, y0, y1, z0, z1)) == y1 : F64}

law ab_mk_z0:
  for +x0: F64
  for +x1: F64
  for +y0: F64
  for +y1: F64
  for +z0: F64
  for +z1: F64
  {QA.ab_z0(QA.ab_mk(x0, x1, y0, y1, z0, z1)) == z0 : F64}

law ab_mk_z1:
  for +x0: F64
  for +x1: F64
  for +y0: F64
  for +y1: F64
  for +z0: F64
  for +z1: F64
  {QA.ab_z1(QA.ab_mk(x0, x1, y0, y1, z0, z1)) == z1 : F64}

law ab_of3_x0:
  for +x: I.I
  for +y: I.I
  for +z: I.I
  {QA.ab_x0(QA.ab_of3(x, y, z)) == I.i_lo(x) : F64}

law ab_of3_x1:
  for +x: I.I
  for +y: I.I
  for +z: I.I
  {QA.ab_x1(QA.ab_of3(x, y, z)) == I.i_hi(x) : F64}

law hull_x0:
  for +a: QA.Ab
  for +b: QA.Ab
  {QA.ab_x0(QA.ab_hull(a, b)) == F64.min(QA.ab_x0(a), QA.ab_x0(b)) : F64}

law hull_x1:
  for +a: QA.Ab
  for +b: QA.Ab
  {QA.ab_x1(QA.ab_hull(a, b)) == F64.max(QA.ab_x1(a), QA.ab_x1(b)) : F64}

law overlap_dual:
  for +a: QA.Ab
  for +b: QA.Ab
  {QA.ab_overlap(a, b) == Bool.not(QA.ab_disjoint(a, b)) : Bool}

law bvh_nd_box:
  for +a: QA.Bvh
  for +b: QA.Bvh
  {QA.bvh_box(QA.bvh_nd(a, b)) == QA.ab_hull(QA.bvh_box(a), QA.bvh_box(b)) : QA.Ab}

law bvh_lf_box:
  for +bx: QA.Ab
  for +ids: List<&2, Nat>
  {QA.bvh_box(QA.Bh_lf{bx, ids}) == bx : QA.Ab}

law bv_mk_lo:
  for +lo: F64
  for +hi: F64
  for +st: U64
  {QC.bv_lo(QC.bv_mk(lo, hi, st)) == lo : F64}

law bv_mk_hi:
  for +lo: F64
  for +hi: F64
  for +st: U64
  {QC.bv_hi(QC.bv_mk(lo, hi, st)) == hi : F64}

law bv_mk_st:
  for +lo: F64
  for +hi: F64
  for +st: U64
  {QC.bv_st(QC.bv_mk(lo, hi, st)) == st : U64}

law mass_s_err:
  for +k: T.FailKind
  for +dg: M.Dg
  for +d: Nat
  {QM.mass_s(M.NR_err{k, dg}, d) == "error: node failed; nothing measured" : String}

law dist_s_err:
  for +k: T.FailKind
  for +dg: M.Dg
  for +x: F64
  for +y: F64
  for +z: F64
  {QD.dist_s(M.NR_err{k, dg}, x, y, z) == "error: node failed; nothing measured" : String}

law extrema_s_err:
  for +k: T.FailKind
  for +dg: M.Dg
  {QD.extrema_s(M.NR_err{k, dg}) == "error: node failed; nothing measured" : String}

law clear_s_err_a:
  for +k: T.FailKind
  for +dg: M.Dg
  for +rb: M.NR
  {QD.clear_s(M.NR_err{k, dg}, rb) == "error: node failed; nothing measured" : String}

law wall_s_err:
  for +k: T.FailKind
  for +dg: M.Dg
  {QD.wall_s(M.NR_err{k, dg}) == "error: node failed; nothing measured" : String}

law sect_s_err:
  for +k: T.FailKind
  for +dg: M.Dg
  for +a: F64
  for +b: F64
  for +c: F64
  for +d: F64
  {QN.sect_s(M.NR_err{k, dg}, a, b, c, d) == "error: node failed; nothing sectioned" : String}

law rel_s_err_a:
  for +k: T.FailKind
  for +dg: M.Dg
  for +rb: M.NR
  {QI.rel_s(M.NR_err{k, dg}, rb) == "error: node failed; nothing compared" : String}

law classify_s_err:
  for +k: T.FailKind
  for +dg: M.Dg
  for +x: F64
  for +y: F64
  for +z: F64
  {QI.classify_s(M.NR_err{k, dg}, x, y, z) == "error: node failed; nothing classified" : String}

law mass_dep_false:
  for +b: M.Body
  for +d: Nat
  {QM.mass_dep(False{}, b, d) == QC.qfail("invalid-input", "mass", "depth needs 0..6", "mass NODE [DEPTH]") : String}

law dist_fin_false:
  for +b: M.Body
  for +x: F64
  for +y: F64
  for +z: F64
  {QD.dist_fin(False{}, b, x, y, z) == "error invalid-input | dist | why: the point needs three finite numbers | fix: dist NODE X Y Z" : String}

law classify_bd_false:
  for +b: M.Body
  for +x: F64
  for +y: F64
  for +z: F64
  {QI.classify_bd(False{}, b, x, y, z) == "error invalid-input | classify | why: the point needs three finite numbers | fix: classify NODE X Y Z" : String}

law rel_pair_go_dis:
  for +a: M.Body
  for +b: M.Body
  for +wa: QA.Ab
  for +wb: QA.Ab
  {QI.rel_pair_go(True{}, a, b, wa, wb) == "relation disjoint status=certified" : String}

law rel_interf_go_dis:
  for +a: M.Body
  for +b: M.Body
  for +wa: QA.Ab
  for +wb: QA.Ab
  {QI.rel_interf_go(True{}, a, b, wa, wb) == False{} : Bool}

law wit_go_dis:
  for +a: M.Body
  for +b: M.Body
  for +wa: QA.Ab
  for +wb: QA.Ab
  {QI.wit_go(False{}, a, b, wa, wb) == False{} : Bool}

law wit_line_true:
  for +fb: String
  {QI.wit_line(True{}, fb) == "relation interference status=certified witness=subdiv" : String}

law wit_line_false:
  for +fb: String
  {QI.wit_line(False{}, fb) == fb : String}

law wit_batches_true:
  for +bs: List<&2, List<&2, I.I>>
  for +bss: List<&2, List<&2, List<&2, I.I>>>
  for +fa: List<&2, SO.Fd>
  for +ba: List<&2, I.I>
  for +pa: M.Pl
  for +fb: List<&2, SO.Fd>
  for +bb: List<&2, I.I>
  for +pb: M.Pl
  {QI.wit_batches(bs <> bss, True{}, fa, ba, pa, fb, bb, pb) == True{} : Bool}

law rel_vb_ainb:
  for +bina: Bool
  {QI.rel_vb(False{}, False{}, True{}, bina, 1n, 0n, 0n, QI.Ag{0n, 5n, 0n}) == "relation inside a-in-b status=certified" : String}

law rel_vb_bina:
  for +ainb: Bool
  {QI.rel_vb(False{}, False{}, ainb, True{}, 0n, 5n, 0n, QI.Ag{1n, 0n, 0n}) == "relation inside b-in-a status=certified" : String}

law dist_in_inside:
  for +k: U64
  for +c: V.Point
  for +fs: List<&2, SO.Fd>
  for +ps: List<&2, V.Point>
  for +cert: Bool
  {QD.dist_in(True{}, k, c, fs, ps, cert) == "distance 0 status=certified state=inside" : String}

law dist_bd_boundary:
  for +unc: Bool
  for +c: V.Point
  for +fs: List<&2, SO.Fd>
  for +ps: List<&2, V.Point>
  for +cert: Bool
  {QD.dist_bd(True{}, unc, c, fs, ps, cert) == "distance 0 status=certified state=boundary" : String}

law wall_rep_empty:
  for +x: QD.Wx
  for +cert: Bool
  {QD.wall_rep([], x, cert) == "min-wall none status=certified reason=all-faces-adjacent" : String}

law wall_body_noface:
  for +b: M.Body
  {QD.wall_body(False{}, b) == "min-wall none status=certified reason=no-faces" : String}

law cav_pair_line_dis:
  for +c: Nat
  for +d: Nat
  {QI.cav_pair_line(0u64, True{}, c, d) == "cavities " ++ Nat.show(c) ++ " " ++ Nat.show(d) ++ " disjoint status=certified\n" : String}

law cav_line_out:
  for +nov: Bool
  for +c: Nat
  for +o: Nat
  {QI.cav_line(0u64, nov, c, o) == "cavity " ++ Nat.show(c) ++ " outside " ++ Nat.show(o) ++ " status=certified" : String}

law mass_rep_incomplete:
  for +b: M.Body
  for +ms: M.Ms
  for +inn: QM.Mc
  for +unc: QM.Mc
  for +nin: Nat
  for +nout: Nat
  for +nunc: Nat
  for +d: Nat
  for +m0: F64
  for +m1: F64
  {QM.mass_rep(True{}, b, ms, inn, unc, nin, nout, nunc, d, m0, m1) == QM.mass_line(ms, m0, m1, nin, nout, nunc, d) ++ "\ncentroid incomplete status=incomplete" ++ QC.inc_s(nunc) : String}

law sect_miss_nu:
  for +at: Nat
  {QN.sg_nu(QN.sect_miss(at)) == 1n : Nat}

law sect_miss_ok:
  for +at: Nat
  {QN.sg_ok(QN.sect_miss(at)) == False{} : Bool}

law cnt_nil:
  for +k: U64
  {QN.cnt([], k) == 0n : Nat}

law cnt_cons:
  for +h: Y.Hx
  for +t: List<&2, Y.Hx>
  for +k: U64
  {QN.cnt(h <> t, k) == Nat.add(Bool.pick(Nat, U64.is_eq(QN.hx_k(h), k), 1n, 0n), QN.cnt(t, k)) : Nat}

law hx_k_un3:
  for +s: I.I
  for +u: I.I
  for +v: I.I
  {QN.hx_k(Y.Hx_un3{s, u, v}) == 2u64 : U64}

law hx_k_uv:
  for +s: I.I
  for +u: I.I
  for +v: I.I
  for +p: List<&2, I.I>
  for +cls: U64
  {QN.hx_k(Y.Hx_uv{s, u, v, p, cls}) == 0u64 : U64}

law hit_k_ov:
  for +s: I.I
  for +t: I.I
  {QN.hit_k(Q.H_ov{s, t}) == 1u64 : U64}

law sg_add_nc:
  for +a: QN.Sg
  for +line: String
  for +c: Nat
  for +u: Nat
  for +k: Nat
  for +ok: Bool
  {QN.sg_nc(QN.sg_add(a, line, c, u, k, ok)) == Nat.add(QN.sg_nc(a), c) : Nat}

law sg_add_ok:
  for +a: QN.Sg
  for +line: String
  for +c: Nat
  for +u: Nat
  for +k: Nat
  for +ok: Bool
  {QN.sg_ok(QN.sg_add(a, line, c, u, k, ok)) == Bool.and(QN.sg_ok(a), ok) : Bool}

law sg_cat_nc:
  for +a: QN.Sg
  for +b: QN.Sg
  {QN.sg_nc(QN.sg_cat(a, b)) == Nat.add(QN.sg_nc(a), QN.sg_nc(b)) : Nat}

law sg_cat_ok:
  for +a: QN.Sg
  for +b: QN.Sg
  {QN.sg_ok(QN.sg_cat(a, b)) == Bool.and(QN.sg_ok(a), QN.sg_ok(b)) : Bool}

law ss_nbr_len:
  for +ok: Bool
  for +brs: List<&2, SS.Br>
  for +un: List<&2, List<&2, I.I>>
  {QN.ss_nbr(SS.Ss{ok, brs, un}) == List.length(&2, SS.Br, brs) : Nat}

law ss_nun_len:
  for +ok: Bool
  for +brs: List<&2, SS.Br>
  for +un: List<&2, List<&2, I.I>>
  {QN.ss_nun(SS.Ss{ok, brs, un}) == List.length(&2, List<&2, I.I>, un) : Nat}

law ak_ids_len:
  for +xs: List<&2, QA.Ak>
  {List.length(&2, Nat, QA.ak_ids(xs)) == List.length(&2, QA.Ak, xs) : Nat}

law n_mem_nil:
  for +x: Nat
  {QA.n_mem(x, []) == False{} : Bool}

law n_share_nil:
  for +ys: List<&2, Nat>
  {QA.n_share([], ys) == False{} : Bool}

law sub_go_zero:
  for +cs: List<&2, List<&2, I.I>>
  {QM.sub_go(0n, cs) == cs : List<&2, List<&2, I.I>>}

law sub1_nil:
  for +x: I.I
  for +y: I.I
  {QM.sub1(x, y, []) == [] : List<&2, List<&2, I.I>>}

law fb_at_nil:
  for +i: Nat
  for +bb: QA.Ab
  {QD.fb_at([], i, bb) == bb : QA.Ab}

law sect_find_nil:
  for +at: Nat
  {QN.sect_find([], at) == None{} : Maybe<&2, SO.Fd>}

law mass_dn_some:
  for +v: U64
  {QM.mass_dn(Some{v}) == U64.to_nat(v) : Nat}

law sect_with_none:
  for +b: M.Body
  for +mapped: Bool
  {QN.sect_with(None{}, b, mapped) == QC.qfail("invalid-input", "section", "the plane needs four finite numbers with a nonzero normal", "section NODE A B C D") : String}

law sect_at_none:
  for +pl: G.GVal
  for +f: Ty.Face
  for +at: Nat
  {QN.sect_at(None{}, pl, f, at) == QN.sect_miss(at) : QN.Sg}
