import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c03/ops.bend as GO
import ../../src/c04/types.bend as Ty
import ../../src/c04/ops.bend as B4
import ../../src/c06/model.bend as M
import ../../src/c06/prof.bend as F
import ../../src/c06/xp.bend as X
import ../../src/c08/bool.bend as B8
import ../../src/k1/surg.bend as K1
import ../../src/k1/clip.bend as QC
import ../../src/c06/iv.bend as I
import ../../src/k1/core.bend as KC
import ../../src/k1/curve.bend as KU
import ../../src/k1/ring.bend as RX
import ../../src/c06/sx.bend as S
import ../../src/c07/sol.bend as SO
import ../../src/c07/ivx.bend as XX
import ../../src/c07/im.bend as MI
import ../../src/c07/mem.bend as MM
import ../../src/c07/xs.bend as XS
import ../../src/c07/rb.bend as RB
import ../../src/c07/eng.bend as NE

def unnr(+r: M.NR) -> M.Body:
  match r:
    case M.NR_ok{+b, fx}: b
    case M.NR_err{k, d}:
      M.Bd{[], Ty.Br{[], [], [], [], [], [], [], Ty.Cp{[], []}, 0u64}, [], M.pl_id(), [], M.xb_id()}

def box10(+e: X.Env, +nd: U64) -> M.Body:
  unnr(M.op_prism([M.rect_rg(M.xk(10.0f64), M.xk(10.0f64))], M.xk(0.0f64), M.xk(10.0f64), e, nd))

def moved(+b: M.Body, +x: F64, +y: F64, +z: F64, +e: X.Env, +nd: U64) -> M.Body:
  unnr(M.op_move(b, M.xk(x), M.xk(y), M.xk(z), 0u64, e, nd))

def osum(+o: B8.Out) -> String:
  Bool.pick(String, B8.Out_ok(o), "ok proof=" ++ B8.Out_proof(o),
    "fail kind=" ++ U64.show(B8.Out_kind(o)) ++ " what=" ++ B8.Out_what(o) ++ " why=" ++ B8.Out_why(o))

def ksum(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +kr = K1.k1run(op, ba, bb)
  Bool.pick(String, K1.kr_ok(kr),
    "k1ok V" ++ Nat.show(K1.kr_nv(kr)) ++ " E" ++ Nat.show(K1.kr_ne(kr)) ++ " F" ++ Nat.show(K1.kr_nf(kr)) ++ " S" ++ Nat.show(K1.kr_nc(kr)),
    "k1no why=" ++ U64.show(K1.kr_why(kr)))

def vsum(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +kr = K1.k1run(op, ba, bb)
  Bool.pick(String, K1.kr_ok(kr),
    "k1ok V" ++ Nat.show(K1.kr_nv(kr)) ++ " E" ++ Nat.show(K1.kr_ne(kr)) ++ " F" ++ Nat.show(K1.kr_nf(kr)) ++ " S" ++ Nat.show(K1.kr_nc(kr)) ++
      " st" ++ U64.show(M.stage_of(K1.kr_brep(kr), M.fuel_of(K1.kr_brep(kr)))),
    "k1no why=" ++ U64.show(K1.kr_why(kr)))

def both(+op: U64, +a: B8.In, +b: B8.In, +nd: U64, +an: U64, +bn: U64) -> String:
  osum(B8.run(op, a, b, nd, an, bn, False{})) ++ " || " ++ ksum(op, B8.bake_of(a), B8.bake_of(b))

def cross_boxes() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  both(B8.tag_union(), M.bool_in(b1), M.bool_in(b3), 4u64, 1u64, 3u64)

def cross_straddle() -> String:
  +e = X.env_mk([])
  +b1 = unnr(M.op_prism([M.rect_rg(M.xk(20.0f64), M.xk(20.0f64))], M.xk(0.0f64), M.xk(20.0f64), e, 1u64))
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(4.0f64), M.xk(4.0f64))], M.xk(0.0f64), M.xk(4.0f64), e, 2u64)), 18.0f64, 8.0f64, 8.0f64, e, 3u64)
  both(B8.tag_diff(), M.bool_in(b1), M.bool_in(b3), 4u64, 1u64, 3u64)

def cross_pierce() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(2.0f64), M.xk(2.0f64))], M.xk(0.0f64), M.xk(20.0f64), e, 2u64)), 4.0f64, 4.0f64, F64.neg(5.0f64), e, 3u64)
  both(B8.tag_union(), M.bool_in(b1), M.bool_in(b3), 4u64, 1u64, 3u64)

def cross_sphere() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b2 = unnr(M.op_rev([M.sph_rg(M.xk(6.0f64))], e, 2u64))
  both(B8.tag_union(), M.bool_in(b1), M.bool_in(b2), 3u64, 1u64, 2u64)

def contact_ident() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b2 = box10(e, 2u64)
  both(B8.tag_union(), M.bool_in(b1), M.bool_in(b2), 3u64, 1u64, 2u64)

def overlap_xyz() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 2.0f64, 2.0f64, e, 3u64)
  both(B8.tag_union(), M.bool_in(b1), M.bool_in(b3), 4u64, 1u64, 3u64)

def disjoint20() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 20.0f64, 0.0f64, 0.0f64, e, 3u64)
  both(B8.tag_union(), M.bool_in(b1), M.bool_in(b3), 4u64, 1u64, 3u64)

def ka_boxes() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  K1.dbg_ka(B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def faces_a() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_side(B8.tag_union(), ba, bb, 0u64)

def faces_b() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_side(B8.tag_union(), ba, bb, 1u64)

def cuts_b01() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_cuts(ba, bb, 1u64, 0n) ++ " " ++ K1.dbg_cuts(ba, bb, 1u64, 1n)

def faces_str() -> String:
  +e = X.env_mk([])
  +b1 = unnr(M.op_prism([M.rect_rg(M.xk(20.0f64), M.xk(20.0f64))], M.xk(0.0f64), M.xk(20.0f64), e, 1u64))
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(4.0f64), M.xk(4.0f64))], M.xk(0.0f64), M.xk(4.0f64), e, 2u64)), 18.0f64, 8.0f64, 8.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  "A:" ++ K1.dbg_side(B8.tag_diff(), ba, bb, 0u64) ++ " B:" ++ K1.dbg_side(B8.tag_diff(), ba, bb, 1u64)

def faces_pie() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(2.0f64), M.xk(2.0f64))], M.xk(0.0f64), M.xk(20.0f64), e, 2u64)), 4.0f64, 4.0f64, F64.neg(5.0f64), e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  "A:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 0u64) ++ " B:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 1u64)

def faces_ov() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 2.0f64, 2.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  "A:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 0u64) ++ " B:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 1u64)

def frags_b0() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_frags(B8.tag_union(), ba, bb, 1u64, 0n)

def rect_o() -> List<&2, QC.QG>:
  [QC.qg_ln(5.0f64, 0.0f64, 15.0f64, 0.0f64, QC.lab_orig(), 0n),
    QC.qg_ln(15.0f64, 0.0f64, 15.0f64, 10.0f64, QC.lab_orig(), 0n),
    QC.qg_ln(15.0f64, 10.0f64, 5.0f64, 10.0f64, QC.lab_orig(), 0n),
    QC.qg_ln(5.0f64, 10.0f64, 5.0f64, 0.0f64, QC.lab_orig(), 0n)]

def dump_outs(os: List<&2, List<&2, QC.QG>>, +acc: String) -> String:
  match os:
    case []: acc
    case +h <> +t: dump_outs(t, acc ++ " [" ++ K1.dbg_qg_go(h, "") ++ " ]")

def k_straddle() -> String:
  +e = X.env_mk([])
  +b1 = unnr(M.op_prism([M.rect_rg(M.xk(20.0f64), M.xk(20.0f64))], M.xk(0.0f64), M.xk(20.0f64), e, 1u64))
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(4.0f64), M.xk(4.0f64))], M.xk(0.0f64), M.xk(4.0f64), e, 2u64)), 18.0f64, 8.0f64, 8.0f64, e, 3u64)
  ksum(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_pierce() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(2.0f64), M.xk(2.0f64))], M.xk(0.0f64), M.xk(20.0f64), e, 2u64)), 4.0f64, 4.0f64, F64.neg(5.0f64), e, 3u64)
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_overlap() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 2.0f64, 2.0f64, e, 3u64)
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def zcyl(+r: F64, +z0: F64, +z1: F64, +e: X.Env, +nd: U64) -> M.Body:
  unnr(M.op_prism([M.circ_rg(M.xk(r))], M.xk(z0), M.xk(z1), e, nd))

def k_bore() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  ksum(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_port() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_coin() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 0.0f64, 0.0f64, 5.0f64, e, 3u64)
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def use_boxes() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_use(B8.tag_union(), ba, bb)

def grps_boxes() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_grps(B8.tag_union(), ba, bb)

def grps_disj() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 20.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_grps(B8.tag_union(), ba, bb)

def str_brep(+e: X.Env, +which: U64) -> Ty.Brep:
  +b1 = unnr(M.op_prism([M.rect_rg(M.xk(20.0f64), M.xk(20.0f64))], M.xk(0.0f64), M.xk(20.0f64), e, 1u64))
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(4.0f64), M.xk(4.0f64))], M.xk(0.0f64), M.xk(4.0f64), e, 2u64)), 18.0f64, 8.0f64, 8.0f64, e, 3u64)
  Bool.pick(Ty.Brep, U64.is_eq(which, 0u64), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def cuts_str() -> String:
  +e = X.env_mk([])
  +ba = str_brep(e, 0u64)
  +bb = str_brep(e, 1u64)
  K1.dbg_cuts(ba, bb, 0u64, 2n) ++ " " ++ K1.dbg_cuts(ba, bb, 0u64, 3n) ++ " " ++
    K1.dbg_cuts(ba, bb, 0u64, 5n)

def frags_str() -> String:
  +e = X.env_mk([])
  +ba = str_brep(e, 0u64)
  +bb = str_brep(e, 1u64)
  K1.dbg_frags(B8.tag_diff(), ba, bb, 0u64, 2n)

def faces_bore() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  "A:" ++ K1.dbg_side(B8.tag_diff(), ba, bb, 0u64) ++ " B:" ++ K1.dbg_side(B8.tag_diff(), ba, bb, 1u64)

def faces_port() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  "A:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 0u64) ++ " B:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 1u64)

def keep_port() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  "f0:" ++ K1.dbg_keep(B8.tag_union(), ba, bb, 1u64, 0n) ++ " f1:" ++
    K1.dbg_keep(B8.tag_union(), ba, bb, 1u64, 1n) ++ " pip:" ++
    K1.dbg_pip(B8.tag_union(), ba, bb, 1u64, 0n)

def faces_coin() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 0.0f64, 0.0f64, 5.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  "A:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 0u64) ++ " B:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 1u64)

def use_port() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_use(B8.tag_union(), ba, bb)

def use_bore() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_use(B8.tag_diff(), ba, bb)

def cuts_bore() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_cuts(ba, bb, 0u64, 0n) ++ " " ++ K1.dbg_cuts(ba, bb, 0u64, 1n) ++ " " ++
    K1.dbg_cuts(ba, bb, 1u64, 2n) ++ " " ++ K1.dbg_cyl(ba, bb, 1u64, 2n) ++ " " ++
    K1.dbg_rim(ba, bb, 1u64, 0n) ++ " " ++ K1.dbg_rim(ba, bb, 1u64, 2n)

def k_fig8() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_cbore() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  ksum(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_cbu() -> String:
  +e = X.env_mk([])
  +b1 = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 1u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +b3 = moved(zcyl(1.5f64, F64.neg(5.0f64), 8.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_sph() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = unnr(M.op_rev([M.sph_rg(M.xk(6.0f64))], e, 2u64))
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def faces_fig8() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  "A:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 0u64) ++ " B:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 1u64)

def use_cbu() -> String:
  +e = X.env_mk([])
  +b1 = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 1u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +b3 = moved(zcyl(1.5f64, F64.neg(5.0f64), 8.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_use(B8.tag_union(), ba, bb)

def faces_sph() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = unnr(M.op_rev([M.sph_rg(M.xk(6.0f64))], e, 2u64))
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  "A:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 0u64) ++ " B:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 1u64)

def topo_cbu() -> String:
  +e = X.env_mk([])
  +b1 = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 1u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +b3 = moved(zcyl(1.5f64, F64.neg(5.0f64), 8.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_topo(B8.tag_union(), ba, bb)

def faces_cbu() -> String:
  +e = X.env_mk([])
  +b1 = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 1u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +b3 = moved(zcyl(1.5f64, F64.neg(5.0f64), 8.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  "A:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 0u64) ++ " B:" ++ K1.dbg_side(B8.tag_union(), ba, bb, 1u64)

def cuts_cbu() -> String:
  +e = X.env_mk([])
  +b1 = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 1u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +b3 = moved(zcyl(1.5f64, F64.neg(5.0f64), 8.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_cuts(ba, bb, 0u64, 1n) ++ " " ++ K1.dbg_cuts(ba, bb, 0u64, 2n) ++ " " ++
    K1.dbg_cuts(ba, bb, 1u64, 2n) ++ " " ++ K1.dbg_rls(B8.tag_union(), ba, bb, 0u64, 1n)

def cuts_fig8() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_cuts(ba, bb, 0u64, 0n) ++ " " ++ K1.dbg_cuts(ba, bb, 0u64, 2n) ++ " " ++
    K1.dbg_cuts(ba, bb, 1u64, 2n) ++ " " ++ K1.dbg_rls(B8.tag_union(), ba, bb, 0u64, 1n)

def ka_sph() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = unnr(M.op_rev([M.sph_rg(M.xk(6.0f64))], e, 2u64))
  K1.dbg_ka(B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def cuts_coin() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 0.0f64, 0.0f64, 5.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_cuts(ba, bb, 0u64, 2n) ++ " " ++ K1.dbg_cuts(ba, bb, 1u64, 2n) ++ " " ++
    K1.dbg_cyl(ba, bb, 0u64, 2n) ++ " " ++ K1.dbg_cyl(ba, bb, 1u64, 2n)

def comps_disj() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 20.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_comps(B8.tag_union(), ba, bb)

def use_straddle() -> String:
  +e = X.env_mk([])
  +b1 = unnr(M.op_prism([M.rect_rg(M.xk(20.0f64), M.xk(20.0f64))], M.xk(0.0f64), M.xk(20.0f64), e, 1u64))
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(4.0f64), M.xk(4.0f64))], M.xk(0.0f64), M.xk(4.0f64), e, 2u64)), 18.0f64, 8.0f64, 8.0f64, e, 3u64)
  K1.dbg_use(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def use_pierce() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(2.0f64), M.xk(2.0f64))], M.xk(0.0f64), M.xk(20.0f64), e, 2u64)), 4.0f64, 4.0f64, F64.neg(5.0f64), e, 3u64)
  K1.dbg_use(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def use_fig8() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  K1.dbg_use(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def capfrags() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  +u = B8.tag_union()
  K1.dbg_rls(u, ba, bb, 0u64, 0n) ++ " || " ++ K1.dbg_rls(u, ba, bb, 0u64, 1n) ++ " || " ++
    K1.dbg_rls(u, ba, bb, 1u64, 0n) ++ " || " ++ K1.dbg_rls(u, ba, bb, 1u64, 1n)

def edgefig8() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  K1.dbg_edges(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def run_ident() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b2 = box10(e, 2u64)
  osum(B8.run(B8.tag_union(), M.bool_in(b1), M.bool_in(b2), 3u64, 1u64, 2u64, False{}))

def i_overlap() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 2.0f64, 2.0f64, e, 3u64)
  ksum(B8.tag_inter(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def i_fig8() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  ksum(B8.tag_inter(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def i_port() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  ksum(B8.tag_inter(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def i_bore() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  ksum(B8.tag_inter(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def plasr(cs: List<&2, M.CE>, +d: M.NR) -> M.NR:
  match cs:
    case []: d
    case c <> t:
      M.CE{id, key, r} = c
      plasr(t, r)

def plas_show(+r: M.NR) -> String:
  match r:
    case M.NR_ok{b, fx}: "ok " ++ M.fx_show(fx)
    case M.NR_err{k, d}:
      M.Dg{w, l, y, f} = d
      "err " ++ y

def pfeatsrc() -> String:
  "(node 1 (box 10 10 10) (intent create 6 0 1 0)) (node 2 (box 10 10 10) (intent create 6 0 1 0)) (node 3 (move 2 20 0 0 0) (intent same 0 0 1 0)) (node 4 (union 1 3) (intent add 0 0 2 0)) (node 5 (pad 4 (face 4 0 top) 5 (region (circle 5 5 2))) (intent add 2 1 2 0))"

def pfeat2src() -> String:
  "(node 1 (box 10 10 10) (intent create 6 0 1 0)) (node 2 (box 10 10 10) (intent create 6 0 1 0)) (node 3 (move 2 5 0 0 0) (intent same 0 0 1 0)) (node 4 (union 1 3) (intent add 0 0 1 0)) (node 5 (pad 4 (face 4 0 top) 5 (region (circle 5 5 2))) (intent add 2 1 1 0))"

def pfeat2() -> String:
  plas_show(plasr(M.ev_part(S.part_of(S.ps_xs(S.parse(pfeat2src()))), []), M.bad("-", "-", "empty", "-")))

def pfeat() -> String:
  plas_show(plasr(M.ev_part(S.part_of(S.ps_xs(S.parse(pfeatsrc()))), []), M.bad("-", "-", "empty", "-")))

def fragtest() -> String:
  "pm=" ++ U64.show(KC.kfrag(14u64, 0u64, 3u64, 1u64, 0u64)) ++ " mp=" ++
    U64.show(KC.kfrag(14u64, 0u64, 3u64, 0u64, 1u64)) ++ " unc=" ++
    U64.show(KC.kfrag(14u64, 0u64, 2u64, 2u64, 2u64))

def k_ident() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +kr = K1.k1run(B8.tag_union(), ba, ba)
  +v = B8.vcore(K1.kr_brep(kr))
  Bool.pick(String, K1.kr_ok(kr),
    "k1ok V" ++ Nat.show(K1.kr_nv(kr)) ++ " E" ++ Nat.show(K1.kr_ne(kr)) ++ " F" ++
      Nat.show(K1.kr_nf(kr)) ++ " S" ++ Nat.show(K1.kr_nc(kr)) ++ " vc" ++
      Bool.pick(String, B8.VR_ok(v), "ok", "NO"),
    "k1no why=" ++ U64.show(K1.kr_why(kr)))

def two_sq() -> List<&2, F.Region>:
  [F.Rg{F.L_path{M.xk(1.0f64), M.xk(1.0f64), [F.S_line{M.xk(5.0f64), M.xk(1.0f64)}, F.S_line{M.xk(5.0f64), M.xk(5.0f64)}, F.S_line{M.xk(1.0f64), M.xk(5.0f64)}]}, []},
   F.Rg{F.L_path{M.xk(100.0f64), M.xk(100.0f64), [F.S_line{M.xk(105.0f64), M.xk(100.0f64)}, F.S_line{M.xk(105.0f64), M.xk(105.0f64)}, F.S_line{M.xk(100.0f64), M.xk(105.0f64)}]}, []}]

def k_mixreg() -> String:
  +e = X.env_mk([])
  +b1 = unnr(M.op_prism([M.rect_rg(M.xk(40.0f64), M.xk(40.0f64))], M.xk(0.0f64), M.xk(40.0f64), e, 1u64))
  +b2 = moved(unnr(M.op_prism(two_sq(), M.xk(0.0f64), M.xk(10.0f64), e, 2u64)), 0.0f64, 0.0f64, 5.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b2))
  +kr = K1.k1run(B8.tag_diff(), ba, bb)
  +v = B8.vcore(K1.kr_brep(kr))
  Bool.pick(String, K1.kr_ok(kr),
    "k1ok F" ++ Nat.show(K1.kr_nf(kr)) ++ " S" ++ Nat.show(K1.kr_nc(kr)) ++ " vc" ++
      Bool.pick(String, B8.VR_ok(v), "ok", "NO"),
    "k1no why=" ++ U64.show(K1.kr_why(kr)))

def volfig8() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +m = K1.k1tight(K1.kr_brep(kr))
  Bool.pick(String, K1.kr_ok(kr),
    "vol [" ++ F64.show(I.i_lo(K1.k1m_vol(m))) ++ "," ++ F64.show(I.i_hi(K1.k1m_vol(m))) ++
      "] ar [" ++ F64.show(I.i_lo(K1.k1m_ar(m))) ++ "," ++ F64.show(I.i_hi(K1.k1m_ar(m))) ++
      "] ok" ++ Bool.pick(String, K1.k1m_ok(m), "T", "F"),
    "k1no why=" ++ U64.show(K1.kr_why(kr)))

def featpad() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b2 = box10(e, 2u64)
  +b3 = moved(b2, 20.0f64, 0.0f64, 0.0f64, e, 3u64)
  +o4 = B8.run(B8.tag_union(), M.bool_in(b1), M.bool_in(b3), 4u64, 1u64, 3u64, False{})
  +rg = M.path_rg(M.xk(1.0f64), M.xk(1.0f64),
    [F.S_line{M.xk(3.0f64), M.xk(1.0f64)}, F.S_line{M.xk(3.0f64), M.xk(3.0f64)},
      F.S_line{M.xk(1.0f64), M.xk(3.0f64)}])
  +tool = unnr(M.op_prism([rg], M.xk(10.0f64), M.xk(12.0f64), e, 5u64))
  +o5 = B8.Out_brep(o4)
  ksum(B8.tag_union(), o5, B8.bake_of(M.bool_in(tool)))

def topo_boxes() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  K1.dbg_topo(B8.tag_union(), ba, bb)

def topo_str() -> String:
  +e = X.env_mk([])
  +ba = str_brep(e, 0u64)
  +bb = str_brep(e, 1u64)
  K1.dbg_topo(B8.tag_diff(), ba, bb)

def clip_v10() -> String:
  +r = K1.clip_loops([rect_o()], K1.CUT{True{}, 10.0f64, 0n, False{}}, QC.QC{0.000000001f64, []})
  "n=" ++ Nat.show(List.length(&2, List<&2, QC.QG>, K1.qla_ls(r))) ++ dump_outs(K1.qla_ls(r), "")

def clip_st2() -> String:
  +s1 = K1.clip_loops([rect_o()], K1.CUT{True{}, 0.0f64, 0n, False{}}, QC.QC{0.000000001f64, []})
  +s2 = K1.clip_loops(K1.qla_ls(s1), K1.CUT{False{}, 10.0f64, 1n, False{}}, K1.qla_qc(s1))
  "n=" ++ Nat.show(List.length(&2, List<&2, QC.QG>, K1.qla_ls(s2))) ++ dump_outs(K1.qla_ls(s2), "")

def clip_st3() -> String:
  +s1 = K1.clip_loops([rect_o()], K1.CUT{True{}, 0.0f64, 0n, False{}}, QC.QC{0.000000001f64, []})
  +s2 = K1.clip_loops(K1.qla_ls(s1), K1.CUT{False{}, 10.0f64, 1n, False{}}, K1.qla_qc(s1))
  +s3 = K1.clip_loops(K1.qla_ls(s2), K1.CUT{True{}, 10.0f64, 2n, False{}}, K1.qla_qc(s2))
  "n=" ++ Nat.show(List.length(&2, List<&2, QC.QG>, K1.qla_ls(s3))) ++ dump_outs(K1.qla_ls(s3), "")

def clip_st4() -> String:
  +s1 = K1.clip_loops([rect_o()], K1.CUT{True{}, 0.0f64, 0n, False{}}, QC.QC{0.000000001f64, []})
  +s2 = K1.clip_loops(K1.qla_ls(s1), K1.CUT{False{}, 10.0f64, 1n, False{}}, K1.qla_qc(s1))
  +s3 = K1.clip_loops(K1.qla_ls(s2), K1.CUT{True{}, 10.0f64, 2n, False{}}, K1.qla_qc(s2))
  +s4 = K1.clip_loops(K1.qla_ls(s3), K1.CUT{False{}, 0.0f64, 3n, False{}}, K1.qla_qc(s3))
  "n=" ++ Nat.show(List.length(&2, List<&2, QC.QG>, K1.qla_ls(s4))) ++ dump_outs(K1.qla_ls(s4), "")

def msum(+m: K1.K1M) -> String:
  Bool.pick(String, K1.k1m_ok(m),
    "tv[" ++ F64.show(I.i_lo(K1.k1m_vol(m))) ++ "," ++ F64.show(I.i_hi(K1.k1m_vol(m))) ++
      "]ta[" ++ F64.show(I.i_lo(K1.k1m_ar(m))) ++ "," ++ F64.show(I.i_hi(K1.k1m_ar(m))) ++ "]",
    "tno")

def tight_boxes() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  Bool.pick(String, K1.kr_ok(kr), msum(K1.k1tight(K1.kr_brep(kr))), "k1no")

def tight_str() -> String:
  +e = X.env_mk([])
  +ba = str_brep(e, 0u64)
  +bb = str_brep(e, 1u64)
  +kr = K1.k1run(B8.tag_diff(), ba, bb)
  Bool.pick(String, K1.kr_ok(kr), msum(K1.k1tight(K1.kr_brep(kr))), "k1no")

def circtool(+e: X.Env, +nd: U64) -> M.Body:
  moved(unnr(M.op_prism([M.circ_rg(M.xk(1.0f64))], M.xk(10.0f64), M.xk(13.0f64), e, nd)),
    2.0f64, 5.0f64, 0.0f64, e, nd)

def coltool(+e: X.Env, +nd: U64) -> M.Body:
  moved(unnr(M.op_prism([M.circ_rg(M.xk(1.0f64))], M.xk(0.0f64), M.xk(13.0f64), e, nd)),
    2.0f64, 5.0f64, 0.0f64, e, nd)

def skshow_go(fs: List<&2, Ty.Face>, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      skshow_go(t, acc ++ U64.show(KU.surfkind(Ty.fa_surf(h))) ++ ",")

def k_nubtight() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = circtool(e, 5u64)
  +kr2 = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))
  Bool.pick(String, K1.kr_ok(kr2),
    msum(K1.k1tight(K1.kr_brep(kr2))) ++ " sk:" ++ skshow_go(Ty.brep_fas(K1.kr_brep(kr2)), ""),
    "k1no why=" ++ U64.show(K1.kr_why(kr2)))

def cens_e_go(es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, +acc: String) -> String:
  match es:
    case []: acc
    case +h <> +t:
      +tag = K1.gv_tag(Ty.ekind_curve(Ty.ed_kind(h)))
      +v0 = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v0(h))))
      +v1 = Ty.vx_p(KU.nth_vx0(vs, Ty.hv_idx(Ty.ed_v1(h))))
      +dx = F64.sub(V.pt_x(v1), V.pt_x(v0))
      +dy = F64.sub(V.pt_y(v1), V.pt_y(v0))
      +dz = F64.sub(V.pt_z(v1), V.pt_z(v0))
      +ch = F64.sqrt(F64.add(F64.mul(dx, dx), F64.add(F64.mul(dy, dy), F64.mul(dz, dz))))
      cens_e_go(t, vs, acc ++ " e" ++ U64.show(tag) ++ "c" ++ F64.show(ch))

def cens_f_go(fs: List<&2, Ty.Face>, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      cens_f_go(t, acc ++ U64.show(KU.surfkind(Ty.fa_surf(h))) ++ ",")

def census(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +kr = K1.k1run(op, ba, bb)
  Bool.pick(String, K1.kr_ok(kr),
    "F[" ++ cens_f_go(Ty.brep_fas(K1.kr_brep(kr)), "") ++ "]E[" ++
      cens_e_go(Ty.brep_es(K1.kr_brep(kr)), Ty.brep_vs(K1.kr_brep(kr)), "") ++ "]",
    "k1no")

def samedump_go(fs: List<&2, Ty.Face>, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      samedump_go(t, acc ++ U64.show(KU.surfkind(Ty.fa_surf(h))) ++
        Bool.pick(String, Ty.fa_same(h), "T", "F") ++ " ")

def sameconv_go(fs: List<&2, Ty.Face>, +b: Ty.Brep, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      +w = K1.gv_pl_of(Ty.fa_surf(h))
      +n = KU.crx(G.pl_u(w), G.pl_v(w))
      +ax = KC.sk_axis(KU.surfkind(Ty.fa_surf(h)))
      sameconv_go(t, b, acc ++ " sk" ++ U64.show(KU.surfkind(Ty.fa_surf(h))) ++
        Bool.pick(String, Ty.fa_same(h), "T", "F") ++ "n(" ++ F64.show(V.dr_x(n)) ++ "," ++
        F64.show(V.dr_y(n)) ++ "," ++ F64.show(V.dr_z(n)) ++ ")c" ++
        F64.show(KU.plancon(w, ax)))

def k_sameconv() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +ba = B8.bake_of(M.bool_in(b1))
  sameconv_go(Ty.brep_fas(ba), ba, "")

def k_tubekind() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +bore = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(bore)))
  +b = K1.kr_brep(kr)
  +w = KU.nth_fa0(Ty.brep_fas(b), 6n)
  "sk=" ++ U64.show(KU.surfkind(Ty.fa_surf(w))) ++ " nloops=" ++
    Nat.show(List.length(&2, Ty.HLoop, Ty.fa_loops(w)))

def k_sames() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +bore = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(bore)))
  +kr2 = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(bore)))
  "borewall: " ++ samedump_go(Ty.brep_fas(K1.kr_brep(kr)), "") ++ "portwall: " ++
    samedump_go(Ty.brep_fas(K1.kr_brep(kr2)), "")

def k_census() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +bore = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +cbore = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  "bore:" ++ census(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(bore))) ++
    " cbore:" ++ census(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(cbore)))

def k_copdbg() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +fa = KU.nth_fa0(Ty.brep_fas(ba), 0n)
  +fr = K1.fr_of(Ty.fa_surf(fa), KU.surfkind(Ty.fa_surf(fa)))
  +lq = K1.face_qg(ba, 0n, fr, False{})
  +o = K1.lq_outer(lq)
  +ks = KU.analist(ba, ba, SO.fds_of(ba), SO.fds_of(ba))
  +fc = K1.face_cuts(ks, 0n, 0u64, K1.fr_ax(fr), False{}, 0n)
  "full=" ++ Bool.pick(String, K1.cop_full(o, o), "T", "F") ++
    " cross=" ++ Bool.pick(String, K1.cop_cross(o, o), "T", "F") ++
    " vin=" ++ Bool.pick(String, K1.cop_verts_in(o, o), "T", "F") ++
    " cop=" ++ Bool.pick(String, K1.fc_cop(fc), "T", "F") ++
    " ncuts=" ++ Nat.show(List.length(&2, K1.CUT, K1.fc_cuts(fc))) ++
    " nrings=" ++ Nat.show(List.length(&2, K1.RG, K1.fc_rings(fc))) ++
    " hit=" ++ Nat.show(List.length(&2, K1.CUT, K1.cuts_hit(K1.fc_cuts(fc), K1.qg_bbox(o)))) ++
    " nseg=" ++ U64.show(QC.seg_seg_n(0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 0.0f64, 10.0f64, 0.0f64))

def k_colsk() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +tool = coltool(e, 5u64)
  +kr2 = K1.k1run(B8.tag_union(), K1.kr_brep(kr), B8.bake_of(M.bool_in(tool)))
  Bool.pick(String, K1.kr_ok(kr2),
    "sk:" ++ skshow_go(Ty.brep_fas(K1.kr_brep(kr2)), ""),
    "k1no why=" ++ U64.show(K1.kr_why(kr2)))

def tsum(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +kr = K1.k1run(op, ba, bb)
  Bool.pick(String, K1.kr_ok(kr), msum(K1.k1tight(K1.kr_brep(kr))), "k1no")

def tfacedump_go(fs: List<&2, Ty.Face>, +b: Ty.Brep, +at: Nat, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      +sk = KU.surfkind(Ty.fa_surf(h))
      +m = Bool.pick(K1.K1M, Bool.and(U64.is_le(1u64, sk), U64.is_le(sk, 3u64)),
        K1.k1fa_plane(h, Ty.brep_lps(b), Ty.brep_ces(b), Ty.brep_es(b), Ty.brep_vs(b)),
        Bool.pick(K1.K1M, Bool.and(U64.is_le(4u64, sk), U64.is_le(sk, 6u64)),
          K1.k1fa_wall(h, Ty.brep_lps(b), Ty.brep_ces(b), Ty.brep_es(b), Ty.brep_vs(b)),
          K1.K1M{I.ipt(0.0f64), I.ipt(0.0f64), False{}}))
      tfacedump_go(t, b, Nat.add(at, 1n), acc ++ " f" ++ Nat.show(at) ++ "sk" ++
        U64.show(sk) ++ Bool.pick(String, K1.k1m_ok(m), "ok", "NO"))

def gatedump_go(cs: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, +fa: U64, +acc: String) -> String:
  match cs:
    case []: acc
    case +h <> +t:
      +ce = KU.nth_ce0(ces, Ty.hc_idx(h))
      +ed = KU.nth_ed0(es, Ty.he_idx(Ty.ce_edge(ce)))
      +f = Ty.ce_fwd(ce)
      +tag = K1.gv_tag(Ty.ekind_curve(Ty.ed_kind(ed)))
      +ia = Bool.pick(Nat, f, Ty.hv_idx(Ty.ed_v0(ed)), Ty.hv_idx(Ty.ed_v1(ed)))
      +ib = Bool.pick(Nat, f, Ty.hv_idx(Ty.ed_v1(ed)), Ty.hv_idx(Ty.ed_v0(ed)))
      +pa = Ty.vx_p(KU.nth_vx0(vs, ia))
      +pb = Ty.vx_p(KU.nth_vx0(vs, ib))
      +cc = K1.gv_cc_of(Ty.ekind_curve(Ty.ed_kind(ed)))
      +c3 = G.cc_c(cc)
      +r = G.cc_r(cc)
      +a = K1.k1drop(pa, fa)
      +b = K1.k1drop(pb, fa)
      +c = K1.k1drop(c3, fa)
      +m = K1.k1trim_mid(Ty.ce_trim(ce))
      +bits = Bool.pick(String, U64.is_eq(tag, 0u64), "ln",
        Bool.pick(String, K1.k1trim_ok(Ty.ce_trim(ce)), "T", "t") ++
        Bool.pick(String, K1.k1onc(a, c, r), "A", "a") ++
        Bool.pick(String, K1.k1onc(b, c, r), "B", "b") ++
        Bool.pick(String, K1.k1onc(m, c, r), "M", "m"))
      gatedump_go(t, ces, es, vs, fa, acc ++ " t" ++ U64.show(tag) ++ bits)

def f0h(+hs: List<&2, Ty.HLoop>) -> Ty.HLoop:
  match hs:
    case []: Ty.HL{0n, 0u64}
    case +h <> +t: h

def k_gatedump() -> String:
  +e = X.env_mk([])
  +f1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +f3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(f1)), B8.bake_of(M.bool_in(f3)))
  +b = K1.kr_brep(kr)
  +f0 = KU.nth_fa0(Ty.brep_fas(b), 0n)
  +lp = KU.nth_lp0(Ty.brep_lps(b), Ty.hlp_idx(f0h(Ty.fa_loops(f0))))
  gatedump_go(Ty.lp_ces(lp), Ty.brep_ces(b), Ty.brep_es(b), Ty.brep_vs(b), 2u64, "")

def k_tfig8() -> String:
  +e = X.env_mk([])
  +f1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +f3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(f1)), B8.bake_of(M.bool_in(f3)))
  Bool.pick(String, K1.kr_ok(kr), tfacedump_go(Ty.brep_fas(K1.kr_brep(kr)), K1.kr_brep(kr), 0n, ""),
    "k1no")

def k_tvols() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +bore = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +cbore = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +port = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +f1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +f3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +u1 = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 1u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +u3 = moved(zcyl(1.5f64, F64.neg(5.0f64), 8.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  "bore:" ++ tsum(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(bore))) ++
    " cbore:" ++ tsum(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(cbore))) ++
    " port:" ++ tsum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(port))) ++
    " fig8:" ++ tsum(B8.tag_union(), B8.bake_of(M.bool_in(f1)), B8.bake_of(M.bool_in(f3))) ++
    " cbu:" ++ tsum(B8.tag_union(), B8.bake_of(M.bool_in(u1)), B8.bake_of(M.bool_in(u3)))

def colfce_go(ls: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>, +acc: String) -> String:
  match ls:
    case []: acc
    case +h <> +t:
      colfce_go(t, lps, acc ++ Nat.show(List.length(&2, Ty.HCoedge,
        Ty.lp_ces(KU.nth_lp0(lps, Ty.hlp_idx(h))))) ++ ".")

def colfaces_go(fs: List<&2, Ty.Face>, +b: Ty.Brep, +at: Nat, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      +sk = KU.surfkind(Ty.fa_surf(h))
      +w = K1.gv_pl_of(Ty.fa_surf(h))
      +wc = K1.gv_cy_of(Ty.fa_surf(h))
      +ax = U64.sub(sk, 1u64)
      +cst = Bool.pick(F64, Bool.and(U64.is_le(1u64, sk), U64.is_le(sk, 3u64)), KU.plancon(w, ax),
        G.cy_r(wc))
      colfaces_go(t, b, Nat.add(at, 1n), acc ++ " f" ++ Nat.show(at) ++ "sk" ++ U64.show(sk) ++
        "c" ++ F64.show(cst) ++ "lp" ++ Nat.show(List.length(&2, Ty.HLoop, Ty.fa_loops(h))) ++
        "ce" ++ colfce_go(Ty.fa_loops(h), Ty.brep_lps(b), ""))

def colfaces2_go(+ba: Ty.Brep) -> String:
  +e = X.env_mk([])
  +tool = coltool(e, 5u64)
  +kr2 = K1.k1run(B8.tag_union(), ba, B8.bake_of(M.bool_in(tool)))
  colfaces_go(Ty.brep_fas(K1.kr_brep(kr2)), K1.kr_brep(kr2), 0n, "")

def k_colfaces() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  colfaces_go(Ty.brep_fas(K1.kr_brep(kr)), K1.kr_brep(kr), 0n, "base:") ++ " |res: " ++
    colfaces2_go(K1.kr_brep(kr))

def k_cross() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +bore = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(bore)))
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +port = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +kr2 = K1.k1run(B8.tag_diff(), K1.kr_brep(kr), B8.bake_of(M.bool_in(port)))
  Bool.pick(String, K1.kr_ok(kr2),
    "k1ok V" ++ Nat.show(K1.kr_nv(kr2)) ++ " E" ++ Nat.show(K1.kr_ne(kr2)) ++ " F" ++
      Nat.show(K1.kr_nf(kr2)) ++ " S" ++ Nat.show(K1.kr_nc(kr2)),
    "k1no why=" ++ U64.show(K1.kr_why(kr2)) ++ " st1=" ++
      Bool.pick(String, K1.kr_ok(kr), "ok", "no" ++ U64.show(K1.kr_why(kr))))

def k_cbore2() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +shank = moved(zcyl(1.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(shank)))
  +head = moved(zcyl(2.0f64, 6.0f64, 14.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  +kr2 = K1.k1run(B8.tag_diff(), K1.kr_brep(kr), B8.bake_of(M.bool_in(head)))
  Bool.pick(String, K1.kr_ok(kr2),
    "k1ok V" ++ Nat.show(K1.kr_nv(kr2)) ++ " E" ++ Nat.show(K1.kr_ne(kr2)) ++ " F" ++
      Nat.show(K1.kr_nf(kr2)) ++ " S" ++ Nat.show(K1.kr_nc(kr2)),
    "k1no why=" ++ U64.show(K1.kr_why(kr2)) ++ " st1=" ++
      Bool.pick(String, K1.kr_ok(kr), "ok", "no" ++ U64.show(K1.kr_why(kr))))

def k_fig8port() -> String:
  +e = X.env_mk([])
  +f1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +f3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(f1)), B8.bake_of(M.bool_in(f3)))
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +port = moved(cx, 0.0f64, 4.0f64, 5.0f64, e, 3u64)
  +kr2 = K1.k1run(B8.tag_union(), K1.kr_brep(kr), B8.bake_of(M.bool_in(port)))
  Bool.pick(String, K1.kr_ok(kr2),
    "k1ok V" ++ Nat.show(K1.kr_nv(kr2)) ++ " E" ++ Nat.show(K1.kr_ne(kr2)) ++ " F" ++
      Nat.show(K1.kr_nf(kr2)) ++ " S" ++ Nat.show(K1.kr_nc(kr2)),
    "k1no why=" ++ U64.show(K1.kr_why(kr2)) ++ " st1=" ++
      Bool.pick(String, K1.kr_ok(kr), "ok", "no" ++ U64.show(K1.kr_why(kr))))

def k_dbgcross() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +bore = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(bore)))
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +port = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +bb = B8.bake_of(M.bool_in(port))
  "s0:" ++ K1.dbg_side(B8.tag_diff(), K1.kr_brep(kr), bb, 0u64) ++
    " s1:" ++ K1.dbg_side(B8.tag_diff(), K1.kr_brep(kr), bb, 1u64)

def k_dbgfig8port() -> String:
  +e = X.env_mk([])
  +f1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +f3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(f1)), B8.bake_of(M.bool_in(f3)))
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +port = moved(cx, 0.0f64, 4.0f64, 5.0f64, e, 3u64)
  +bb = B8.bake_of(M.bool_in(port))
  "s0:" ++ K1.dbg_side(B8.tag_union(), K1.kr_brep(kr), bb, 0u64) ++
    " s1:" ++ K1.dbg_side(B8.tag_union(), K1.kr_brep(kr), bb, 1u64)

def k_dbgx() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +bore = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(bore)))
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +port = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +bb = B8.bake_of(M.bool_in(port))
  "ka:" ++ K1.dbg_ka(K1.kr_brep(kr), bb) ++ " rls06:" ++
    K1.dbg_rls(B8.tag_diff(), K1.kr_brep(kr), bb, 0u64, 6n) ++ " rls12:" ++
    K1.dbg_rls(B8.tag_diff(), K1.kr_brep(kr), bb, 1u64, 2n)

def dbg_ucount(cs: List<&2, Ty.Coedge>, +at: Nat, +n: Nat, +t: Bool, +f: Bool) -> String:
  match cs:
    case []: Nat.show(n) ++ Bool.pick(String, t, "T", "t") ++ Bool.pick(String, f, "F", "f")
    case +h <> +tt:
      +hit = Nat.is_eq(Ty.he_idx(Ty.ce_edge(h)), at)
      dbg_ucount(tt, at, Nat.add(n, Bool.pick(Nat, hit, 1n, 0n)),
        Bool.or(t, Bool.and(hit, Ty.ce_fwd(h))), Bool.or(f, Bool.and(hit, Bool.not(Ty.ce_fwd(h)))))

def dbg_uses_go(es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>, +at: Nat, +acc: String) -> String:
  match es:
    case []: acc
    case +h <> +t:
      dbg_uses_go(t, ces, Nat.add(at, 1n), acc ++ " e" ++ Nat.show(at) ++ "(" ++
        Nat.show(Ty.hv_idx(Ty.ed_v0(h))) ++ "," ++ Nat.show(Ty.hv_idx(Ty.ed_v1(h))) ++ ",k" ++
        U64.show(Ty.ekind_tag(Ty.ed_kind(h))) ++ ")=" ++ dbg_ucount(ces, at, 0n, False{}, False{}))

def dbg_lpces_go(cs: List<&2, Ty.HCoedge>, +acc: String) -> String:
  match cs:
    case []: acc
    case +h <> +t: dbg_lpces_go(t, acc ++ Nat.show(Ty.hc_idx(h)) ++ ".")

def dbg_lps_go2(ls: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>, +acc: String) -> String:
  match ls:
    case []: acc
    case +h <> +t:
      dbg_lps_go2(t, lps, acc ++ "[" ++ Nat.show(Ty.hlp_idx(h)) ++ ":" ++
        dbg_lpces_go(Ty.lp_ces(KU.nth_lp0(lps, Ty.hlp_idx(h))), "") ++ "]")

def dbg_faces_go2(fs: List<&2, Ty.Face>, +b: Ty.Brep, +at: Nat, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      dbg_faces_go2(t, b, Nat.add(at, 1n), acc ++ " f" ++ Nat.show(at) ++ "sk" ++
        U64.show(KU.surfkind(Ty.fa_surf(h))) ++ dbg_lps_go2(Ty.fa_loops(h), Ty.brep_lps(b), ""))

def dbg_ces_go(cs: List<&2, Ty.Coedge>, +at: Nat, +acc: String) -> String:
  match cs:
    case []: acc
    case +h <> +t:
      dbg_ces_go(t, Nat.add(at, 1n), acc ++ " c" ++ Nat.show(at) ++ "->e" ++
        Nat.show(Ty.he_idx(Ty.ce_edge(h))) ++ Bool.pick(String, Ty.ce_fwd(h), "T", "F"))

def dbg_vs_go(vs: List<&2, Ty.Vertex>, +at: Nat, +acc: String) -> String:
  match vs:
    case []: acc
    case +h <> +t:
      +p = Ty.vx_p(h)
      dbg_vs_go(t, Nat.add(at, 1n), acc ++ " v" ++ Nat.show(at) ++ "(" ++
        F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")")

def dbg_ekind_go(es: List<&2, Ty.Edge>, +at: Nat, +acc: String) -> String:
  match es:
    case []: acc
    case +h <> +t:
      dbg_ekind_go(t, Nat.add(at, 1n), acc ++ " e" ++ Nat.show(at) ++ "g" ++
        U64.show(K1.gv_tag(Ty.ekind_curve(Ty.ed_kind(h)))))

def k_dbgcbore2() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +shank = moved(zcyl(1.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(shank)))
  +head = moved(zcyl(2.0f64, 6.0f64, 14.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  +kr2 = K1.k1run(B8.tag_diff(), K1.kr_brep(kr), B8.bake_of(M.bool_in(head)))
  +b = K1.kr_brep(kr2)
  "ces:" ++ dbg_ces_go(Ty.brep_ces(b), 0n, "") ++ " vs:" ++ dbg_vs_go(Ty.brep_vs(b), 0n, "") ++
    " ek:" ++ dbg_ekind_go(Ty.brep_es(b), 0n, "")

def k_dbgcbore() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +shank = moved(zcyl(1.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(shank)))
  +head = moved(zcyl(2.0f64, 6.0f64, 14.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  +kr2 = K1.k1run(B8.tag_diff(), K1.kr_brep(kr), B8.bake_of(M.bool_in(head)))
  +b = K1.kr_brep(kr2)
  "ok=" ++ Bool.pick(String, K1.kr_ok(kr2), "y", "n" ++ U64.show(K1.kr_why(kr2))) ++ " uses:" ++
    dbg_uses_go(Ty.brep_es(b), Ty.brep_ces(b), 0n, "") ++ " loops:" ++
    dbg_faces_go2(Ty.brep_fas(b), b, 0n, "")

def k_valid() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +bore = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +shank = moved(zcyl(1.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +head = moved(zcyl(2.0f64, 6.0f64, 14.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +port = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +f1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +f3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +krb = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(bore)))
  +krs = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(shank)))
  "bore:" ++ vsum(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(bore))) ++
    " cbore2:" ++ vsum(B8.tag_diff(), K1.kr_brep(krs), B8.bake_of(M.bool_in(head))) ++
    " port:" ++ vsum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(port))) ++
    " fig8:" ++ vsum(B8.tag_union(), B8.bake_of(M.bool_in(f1)), B8.bake_of(M.bool_in(f3))) ++
    " boreX:" ++ vsum(B8.tag_diff(), K1.kr_brep(krb), B8.bake_of(M.bool_in(port)))

def k_dbgfp() -> String:
  +e = X.env_mk([])
  +f1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +f3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(f1)), B8.bake_of(M.bool_in(f3)))
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +port = moved(cx, 0.0f64, 4.0f64, 5.0f64, e, 3u64)
  +ba = K1.kr_brep(kr)
  +bb = B8.bake_of(M.bool_in(port))
  "C4:" ++ K1.dbg_cyl(ba, bb, 0u64, 4n) ++ " F4:" ++
    K1.dbg_frags(B8.tag_union(), ba, bb, 0u64, 4n) ++ " R4:" ++
    K1.dbg_rls(B8.tag_union(), ba, bb, 0u64, 4n)

def k_colpad() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +tool = coltool(e, 5u64)
  +kr2 = K1.k1run(B8.tag_union(), K1.kr_brep(kr), B8.bake_of(M.bool_in(tool)))
  Bool.pick(String, K1.kr_ok(kr2),
    "k1ok V" ++ Nat.show(K1.kr_nv(kr2)) ++ " E" ++ Nat.show(K1.kr_ne(kr2)) ++ " F" ++
      Nat.show(K1.kr_nf(kr2)) ++ " S" ++ Nat.show(K1.kr_nc(kr2)) ++ " " ++ msum(K1.k1tight(K1.kr_brep(kr2))),
    "k1no why=" ++ U64.show(K1.kr_why(kr2)))

def k_padcirc() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +tool = circtool(e, 5u64)
  ksum(B8.tag_union(), K1.kr_brep(kr), B8.bake_of(M.bool_in(tool)))

def k_padcirc_fresh() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = circtool(e, 5u64)
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))

def edgepadcirc() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = circtool(e, 5u64)
  K1.dbg_edges(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))

def vpadcirc() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +tool = circtool(e, 5u64)
  +kr2 = K1.k1run(B8.tag_union(), K1.kr_brep(kr), B8.bake_of(M.bool_in(tool)))
  +v = B8.vcore(K1.kr_brep(kr2))
  Bool.pick(String, B8.VR_ok(v), "vok", "vno " ++ B8.vcode(v))

def cedump_go(cs: List<&2, Ty.Coedge>, +at: Nat, +acc: String) -> String:
  match cs:
    case []: acc
    case +h <> +t:
      cedump_go(t, Nat.add(at, 1n), acc ++ " c" ++ Nat.show(at) ++ ">e" ++
        Nat.show(Ty.he_idx(Ty.ce_edge(h))) ++ Bool.pick(String, Ty.ce_fwd(h), "F", "B"))

def fwpadcirc() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = circtool(e, 5u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))
  cedump_go(Ty.brep_ces(K1.kr_brep(kr)), 0n, "")

def vfig8() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +v = B8.vcore(K1.kr_brep(kr))
  Bool.pick(String, B8.VR_ok(v), "vok", "vno " ++ B8.vcode(v))

def vrep(+kr: K1.KR) -> String:
  +v = B8.vcore(K1.kr_brep(kr))
  Bool.pick(String, B8.VR_ok(v), "vok", "vno " ++ B8.vcode(v))

def v_cross() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  vrep(K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3))))

def v_bore() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  vrep(K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3))))

def v_port() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  vrep(K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3))))

def v_cbore() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  vrep(K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3))))

def v_cbu() -> String:
  +e = X.env_mk([])
  +b1 = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 1u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +b3 = moved(zcyl(1.5f64, F64.neg(5.0f64), 8.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  vrep(K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3))))

def finfo_go(fs: List<&2, Ty.Face>, +at: Nat, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      finfo_go(t, Nat.add(at, 1n), acc ++ " f" ++ Nat.show(at) ++ "sk" ++
        U64.show(KU.surfkind(Ty.fa_surf(h))) ++ Bool.pick(String, Ty.fa_same(h), "T", "F"))

def winfo_pad() -> String:
  +e = X.env_mk([])
  +tool = circtool(e, 5u64)
  finfo_go(Ty.brep_fas(B8.bake_of(M.bool_in(tool))), 0n, "")

def winfo_bore() -> String:
  +e = X.env_mk([])
  +b3 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  finfo_go(Ty.brep_fas(B8.bake_of(M.bool_in(b3))), 0n, "")

def tight_bore() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  Bool.pick(String, K1.kr_ok(kr), msum(K1.k1tight(K1.kr_brep(kr))), "k1no")

def tight_cbore() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  Bool.pick(String, K1.kr_ok(kr), msum(K1.k1tight(K1.kr_brep(kr))), "k1no")

def v_rectpock() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(4.0f64), M.xk(4.0f64))], M.xk(0.0f64), M.xk(4.0f64), e, 2u64)), 3.0f64, 3.0f64, F64.neg(2.0f64), e, 3u64)
  vrep(K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3))))

def v_botboss() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = moved(unnr(M.op_prism([M.circ_rg(M.xk(1.0f64))], M.xk(F64.neg(3.0f64)), M.xk(0.0f64), e, 5u64)), 2.0f64, 5.0f64, 0.0f64, e, 5u64)
  vrep(K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool))))

def v_rectthru() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(4.0f64), M.xk(4.0f64))], M.xk(0.0f64), M.xk(20.0f64), e, 2u64)), 3.0f64, 3.0f64, F64.neg(5.0f64), e, 3u64)
  vrep(K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3))))

def v_recttop() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(4.0f64), M.xk(4.0f64))], M.xk(0.0f64), M.xk(4.0f64), e, 2u64)), 3.0f64, 3.0f64, 8.0f64, e, 3u64)
  vrep(K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3))))

def fwbotboss() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = moved(unnr(M.op_prism([M.circ_rg(M.xk(1.0f64))], M.xk(F64.neg(3.0f64)), M.xk(0.0f64), e, 5u64)), 2.0f64, 5.0f64, 0.0f64, e, 5u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))
  cedump_go(Ty.brep_ces(K1.kr_brep(kr)), 0n, "")

def lkshow(+k: Ty.LoopKind) -> String:
  match k:
    case Ty.LK_outer{}: "O"
    case Ty.LK_inner{}: "I"

def facedump_ces(hs: List<&2, Ty.HCoedge>, +cs: List<&2, Ty.Coedge>, +acc: String) -> String:
  match hs:
    case []: acc
    case +h <> +t:
      +ce = KU.nth_ce0(cs, Ty.hc_idx(h))
      facedump_ces(t, cs, acc ++ "e" ++ Nat.show(Ty.he_idx(Ty.ce_edge(ce))) ++
        Bool.pick(String, Ty.ce_fwd(ce), "F", "B"))

def facedump_lps(hs: List<&2, Ty.HLoop>, +b: Ty.Brep, +acc: String) -> String:
  match hs:
    case []: acc
    case +h <> +t:
      +lp = KU.nth_lp0(Ty.brep_lps(b), Ty.hlp_idx(h))
      facedump_lps(t, b, acc ++ "[" ++ lkshow(Ty.lp_kind(lp)) ++
        facedump_ces(Ty.lp_ces(lp), Ty.brep_ces(b), "") ++ "]")

def facedump_go(fs: List<&2, Ty.Face>, +b: Ty.Brep, +at: Nat, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      facedump_go(t, b, Nat.add(at, 1n), acc ++ " f" ++ Nat.show(at) ++ "sk" ++
        U64.show(KU.surfkind(Ty.fa_surf(h))) ++ Bool.pick(String, Ty.fa_same(h), "T", "F") ++
        facedump_lps(Ty.fa_loops(h), b, ""))

def fpadcirc() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = circtool(e, 5u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))
  facedump_go(Ty.brep_fas(K1.kr_brep(kr)), K1.kr_brep(kr), 0n, "")

def fbotboss() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = moved(unnr(M.op_prism([M.circ_rg(M.xk(1.0f64))], M.xk(F64.neg(3.0f64)), M.xk(0.0f64), e, 5u64)), 2.0f64, 5.0f64, 0.0f64, e, 5u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))
  facedump_go(Ty.brep_fas(K1.kr_brep(kr)), K1.kr_brep(kr), 0n, "")

def ordbg_dir(gs: List<&2, V.Dir>, +fs: List<&2, SO.Fd>, +bb: List<&2, I.I>, +ip: SO.Ip, +at: Nat, +acc: String) -> String:
  match gs:
    case []: acc
    case +g <> +t:
      SO.Ip{+i, +q, +nv} = ip
      +d = SO.dr_of(SO.off_dir(nv, g))
      +ok = XX.ipos(XX.vdot(MI.d3(d), nv))
      +r = SO.or_shot(ok, fs, bb, SO.pt_of(q), d, i)
      ordbg_dir(t, fs, bb, ip, Nat.add(at, 1n), acc ++ " g" ++ Nat.show(at) ++
        Bool.pick(String, ok, "T", "F") ++ "n" ++ Nat.show(SO.rc_n(r)) ++ "s" ++ U64.show(SO.rc_st(r)))

def ordbg_ip(+m: Maybe<&2, SO.Ip>, +fds: List<&2, SO.Fd>, +bb: List<&2, I.I>) -> String:
  match m:
    case None{}: "noip"
    case Some{+ip}:
      SO.Ip{+i, +q, +nv} = ip
      "ip" ++ Nat.show(i) ++ " q" ++ F64.show(I.imid(XX.vn(q, 0n))) ++ "," ++
        F64.show(I.imid(XX.vn(q, 1n))) ++ "," ++ F64.show(I.imid(XX.vn(q, 2n))) ++ " nv" ++
        F64.show(I.imid(XX.vn(nv, 0n))) ++ "," ++ F64.show(I.imid(XX.vn(nv, 1n))) ++ "," ++
        F64.show(I.imid(XX.vn(nv, 2n))) ++ ordbg_dir(SO.dirs(), fds, bb, ip, 0n, "")

def ordbg_one(+b: Ty.Brep) -> String:
  +fds = SO.fds_of(b)
  +bb = SO.bbox(fds, [])
  ordbg_ip(SO.ip_find(fds, None{}, 0n, 0n), fds, bb)

def orpad() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = circtool(e, 5u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))
  ordbg_one(K1.kr_brep(kr))

def orbot() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = moved(unnr(M.op_prism([M.circ_rg(M.xk(1.0f64))], M.xk(F64.neg(3.0f64)), M.xk(0.0f64), e, 5u64)), 2.0f64, 5.0f64, 0.0f64, e, 5u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))
  ordbg_one(K1.kr_brep(kr))

def mbr_fd(fs: List<&2, SO.Fd>, +q: List<&2, I.I>, +at: Nat, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      SO.Fd{+fc, +g, +bx, +ok, +sh, +fi} = h
      mbr_fd(t, q, Nat.add(at, 1n), acc ++ " f" ++ Nat.show(at) ++ "(fi" ++ Nat.show(fi) ++
        Bool.pick(String, ok, "T", "F") ++ ")=" ++ U64.show(MM.member(fc, q, SO.fd_im(h))))

def mbr_one(+b: Ty.Brep, +qx: F64, +qy: F64, +qz: F64) -> String:
  +fds = SO.fds_of(b)
  mbr_fd(fds, [I.ipt(qx), I.ipt(qy), I.ipt(qz)], 0n, "")

def mbrpad() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = circtool(e, 5u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))
  "k1:" ++ mbr_one(K1.kr_brep(kr), 3.0f64, 5.0f64, 13.1875f64) ++ " orig:" ++
    mbr_one(B8.bake_of(M.bool_in(tool)), 3.0f64, 5.0f64, 13.1875f64)

def mbrcen() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = circtool(e, 5u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))
  "k1c:" ++ mbr_one(K1.kr_brep(kr), 2.0f64, 5.0f64, 13.0f64) ++ " k1o:" ++
    mbr_one(K1.kr_brep(kr), 5.0f64, 5.0f64, 13.0f64)

def mbrhole() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = circtool(e, 5u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))
  "hole-in:" ++ mbr_one(K1.kr_brep(kr), 2.0f64, 5.0f64, 10.0f64)

def origcap() -> String:
  +e = X.env_mk([])
  +tool = circtool(e, 5u64)
  +b = B8.bake_of(M.bool_in(tool))
  facedump_go(Ty.brep_fas(b), b, 0n, "")

def ts_show(+t: G.GVal) -> String:
  match t:
    case G.GV_ts{+w}:
      G.Ts{+a, +b} = w
      V.V2{+ax, +ay} = a
      V.V2{+bx, +by} = b
      "(" ++ F64.show(ax) ++ "," ++ F64.show(ay) ++ ")-(" ++ F64.show(bx) ++ "," ++ F64.show(by) ++ ")"
    case _: "non-ts"

def first_hlp(hs: List<&2, Ty.HLoop>) -> Ty.HLoop:
  match hs:
    case h <> _: h
    case []: Ty.hlp_null()

def first_hce(hs: List<&2, Ty.HCoedge>) -> Ty.HCoedge:
  match hs:
    case h <> _: h
    case []: K1.hc(0n)

def origtrim() -> String:
  +e = X.env_mk([])
  +tool = circtool(e, 5u64)
  +b = B8.bake_of(M.bool_in(tool))
  +f1 = KU.nth_fa0(Ty.brep_fas(b), 1n)
  +lp = KU.nth_lp0(Ty.brep_lps(b), Ty.hlp_idx(first_hlp(Ty.fa_loops(f1))))
  +ce = KU.nth_ce0(Ty.brep_ces(b), Ty.hc_idx(first_hce(Ty.lp_ces(lp))))
  ts_show(Ty.ce_trim(ce)) ++ Bool.pick(String, Ty.ce_fwd(ce), "F", "B")

def mbrorig() -> String:
  +e = X.env_mk([])
  +tool = circtool(e, 5u64)
  "cen:" ++ mbr_one(B8.bake_of(M.bool_in(tool)), 2.0f64, 5.0f64, 13.0f64) ++ " out:" ++
    mbr_one(B8.bake_of(M.bool_in(tool)), 5.0f64, 5.0f64, 13.0f64)

def mbroff() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = circtool(e, 5u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))
  "k1:" ++ mbr_one(K1.kr_brep(kr), 2.5f64, 5.0f64, 13.0f64) ++ " orig:" ++
    mbr_one(B8.bake_of(M.bool_in(tool)), 2.5f64, 5.0f64, 13.0f64)

def riminfo() -> String:
  +e = X.env_mk([])
  +tool = circtool(e, 5u64)
  +b = B8.bake_of(M.bool_in(tool))
  +rlo = K1.wall_rim(b, 2n, True{})
  +rhi = K1.wall_rim(b, 2n, False{})
  "rlo z=" ++ F64.show(V.pt_z(G.cc_c(K1.rim_cc(rlo)))) ++ " ok" ++
    Bool.pick(String, K1.rim_ok(rlo), "T", "F") ++ " rhi z=" ++
    F64.show(V.pt_z(G.cc_c(K1.rim_cc(rhi)))) ++ " ok" ++ Bool.pick(String, K1.rim_ok(rhi), "T", "F")

def fwfig8() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  cedump_go(Ty.brep_ces(K1.kr_brep(kr)), 0n, "")

def ffig8() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  facedump_go(Ty.brep_fas(K1.kr_brep(kr)), K1.kr_brep(kr), 0n, "")

def vbr(+b: Ty.Brep) -> String:
  +v = B8.vcore(b)
  Bool.pick(String, B8.VR_ok(v), "vok", "vno " ++ B8.vcode(v))

def vorig() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = circtool(e, 5u64)
  vbr(B8.bake_of(M.bool_in(b1))) ++ " " ++ vbr(B8.bake_of(M.bool_in(tool)))

def mbrf5() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  mbr_one(K1.kr_brep(kr), F64.neg(2.1213203435596424f64), 2.1213203435596424f64, 5.0f64)

def sho_go(xs: List<&2, V.Point>, +px: F64, +py: F64, +fx: F64, +fy: F64, +acc: F64) -> F64:
  match xs:
    case []: F64.add(acc, F64.sub(F64.mul(px, fy), F64.mul(fx, py)))
    case +h <> +t:
      sho_go(t, V.pt_x(h), V.pt_y(h), fx, fy, F64.add(acc, F64.sub(F64.mul(px, V.pt_y(h)), F64.mul(V.pt_x(h), py))))

def shoelace(xs: List<&2, V.Point>) -> F64:
  match xs:
    case []: 0.0f64
    case +h <> +t: sho_go(t, V.pt_x(h), V.pt_y(h), V.pt_x(h), V.pt_y(h), 0.0f64)

def capvs_ces(hs: List<&2, Ty.HCoedge>, +b: Ty.Brep, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match hs:
    case []: List.reverse(&2, V.Point, acc)
    case +h <> +t:
      +ce = KU.nth_ce0(Ty.brep_ces(b), Ty.hc_idx(h))
      +ed = KU.nth_ed0(Ty.brep_es(b), Ty.he_idx(Ty.ce_edge(ce)))
      +hv = Bool.pick(Ty.HVertex, Ty.ce_fwd(ce), Ty.ed_v0(ed), Ty.ed_v1(ed))
      capvs_ces(t, b, Ty.vx_p(KU.nth_vx0(Ty.brep_vs(b), Ty.hv_idx(hv))) <> acc)

def capfact(+b: Ty.Brep, +fi: Nat) -> String:
  +fa = KU.nth_fa0(Ty.brep_fas(b), fi)
  +hl = first_hlp(Ty.fa_loops(fa))
  +lp = KU.nth_lp0(Ty.brep_lps(b), Ty.hlp_idx(hl))
  +vs = capvs_ces(Ty.lp_ces(lp), b, [])
  Nat.show(fi) ++ ":" ++ F64.show(shoelace(vs)) ++ " "

def capfacts() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +b = K1.kr_brep(kr)
  capfact(b, 0n) ++ capfact(b, 1n) ++ capfact(b, 2n) ++ capfact(b, 6n) ++ capfact(b, 7n)

def mbrlens() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  "toplens:" ++ mbr_one(K1.kr_brep(kr), 2.5f64, 0.5f64, 10.0f64) ++ " botlens:" ++
    mbr_one(K1.kr_brep(kr), 2.5f64, 0.5f64, 0.0f64) ++ " topl:" ++
    mbr_one(K1.kr_brep(kr), F64.neg(2.0f64), 0.0f64, 10.0f64) ++ " topr:" ++
    mbr_one(K1.kr_brep(kr), 6.0f64, 0.0f64, 10.0f64)

def mbrbore() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  "topann:" ++ mbr_one(K1.kr_brep(kr), 1.0f64, 1.0f64, 10.0f64) ++ " wallin:" ++
    mbr_one(K1.kr_brep(kr), 7.0f64, 5.0f64, 5.0f64)

def gendump_go(cs: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>, +at: Nat, +acc: String) -> String:
  match cs:
    case []: acc
    case +h <> +t:
      +ei = Ty.he_idx(Ty.ce_edge(h))
      +eg = Ty.he_gen(Ty.ce_edge(h))
      +hg = Ty.ed_gen(KU.nth_ed0(es, ei))
      gendump_go(t, es, Nat.add(at, 1n), Bool.pick(String, U64.is_eq(eg, hg), acc,
        acc ++ " c" ++ Nat.show(at) ++ " e" ++ Nat.show(ei) ++ " hg" ++ U64.show(eg) ++ " eg" ++ U64.show(hg)))

def gendump() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +b = K1.kr_brep(kr)
  "genbad:" ++ gendump_go(Ty.brep_ces(b), Ty.brep_es(b), 0n, "")

def hitshow(hs: List<&2, XS.Hit>, +acc: String) -> String:
  match hs:
    case []: acc
    case +h <> +t:
      match h:
        case XS.H_pt{+s, +tt, +p, +cls}: hitshow(t, acc ++ " pt[" ++ F64.show(I.i_lo(s)) ++ "," ++ F64.show(I.i_hi(s)) ++ "]")
        case XS.H_ov{+s, +tt}: hitshow(t, acc ++ " ov[" ++ F64.show(I.i_lo(s)) ++ "," ++ F64.show(I.i_hi(s)) ++ "]")
        case XS.H_un{+s, +tt, +p}: hitshow(t, acc ++ " un[" ++ F64.show(I.i_lo(s)) ++ "," ++ F64.show(I.i_hi(s)) ++ "]")
        case XS.H_no{+why}: hitshow(t, acc ++ " no:" ++ why)

def ics14() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +b = K1.kr_brep(kr)
  +ed = KU.nth_ed0(Ty.brep_es(b), 1n)
  +fa = KU.nth_fa0(Ty.brep_fas(b), 4n)
  hitshow(XS.inter_cs(Ty.ekind_curve(Ty.ed_kind(ed)), Ty.ekind_dom(Ty.ed_kind(ed)), Ty.fa_surf(fa), 40n), "")

def mbre1() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  "e1start:" ++ mbr_one(K1.kr_brep(kr), 3.0f64, 0.0f64, 10.0f64) ++ " e1mid:" ++
    mbr_one(K1.kr_brep(kr), 2.419f64, 1.772f64, 10.0f64) ++ " e1end:" ++
    mbr_one(K1.kr_brep(kr), 2.0f64, 2.23606797749979f64, 10.0f64)

def mbrrimz() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  "up:" ++ mbr_one(K1.kr_brep(kr), 3.0f64, 0.0f64, 10.0000001f64) ++ " dn:" ++
    mbr_one(K1.kr_brep(kr), 3.0f64, 0.0f64, 9.9999999f64)

def mmtry(+fc: MM.Fc, +q: List<&2, I.I>, +nf: MI.Im, +j: Nat, +acc: String) -> String:
  match j:
    case 0n: acc
    case 1n+m:
      +jj = Nat.sub(24n, j)
      +r = MM.try_r(fc, q, nf, Nat.div(jj, 6n), MM.tau_of(Nat.div(jj, 2n)), Nat.is_eq(Nat.mod(jj, 2n), 1n))
      mmtry(fc, q, nf, m, acc ++ U64.show(r))

def mmdiag_at(fs: List<&2, SO.Fd>, +at: Nat) -> String:
  match fs:
    case []: "nofd"
    case +h <> +t:
      match at:
        case 0n:
          "qz10:" ++ mmtry(SO.fd_fc(h), [I.ipt(3.0f64), I.ipt(0.0f64), I.ipt(10.0f64)], SO.fd_im(h), 24n, "") ++
            " qup:" ++ mmtry(SO.fd_fc(h), [I.ipt(3.0f64), I.ipt(0.0f64), I.ipt(10.0000001f64)], SO.fd_im(h), 24n, "")
        case 1n+j: mmdiag_at(t, j)

def mmdiag() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  mmdiag_at(SO.fds_of(K1.kr_brep(kr)), 4n)

def mmone(+fc: MM.Fc, +q: List<&2, I.I>, +nf: MI.Im, +i: Nat, +tau: F64, +rev: Bool) -> String:
  +e = MM.er_at(MM.fc_es(fc), i)
  +c = MM.er_c(e)
  +rp = RB.cv_box(c, I.ipt(tau))
  +lp = MM.legs_of(MM.fc_s(fc), q, rp, rev, nf)
  +ok = MM.lp_ok(lp)
  +tt = MM.total(MM.lp_ls(lp), MM.fc_es(fc), i, tau, MM.Cn{0n, False{}})
  +nrm = MM.neg_if(MM.fc_same(fc), MI.im_grad(nf, rp))
  +tl = MM.neg_if(MM.er_fwd(e), RB.cv_der(c, I.ipt(tau)))
  +arr = MM.arrive(MM.lp_d(lp), nrm, tl)
  Bool.pick(String, ok, "n" ++ Nat.show(MM.cn_n(tt)), "nok") ++ "a" ++ U64.show(arr) ++ "t" ++ U64.show(MM.try_r(fc, q, nf, i, tau, rev))

def mmroots_rs(rs: List<&2, NE.Res>, +acc: String) -> String:
  match rs:
    case []: acc
    case +r <> +t:
      match r:
        case NE.R_pt{+x}: mmroots_rs(t, acc ++ "p")
        case NE.R_un{+x}: mmroots_rs(t, acc ++ "U")
        case _: mmroots_rs(t, acc ++ "?")


def mmroots_es(es: List<&2, MM.Er>, +l: MM.Lg, +ei: Nat, +acc: String) -> String:
  match es:
    case []: acc
    case +e <> +t:
      +c = MM.er_c(e)
      +fl = MM.flat(c, MM.lg_cut(l))
      +rs = NE.solve_ew(40n, 4096u64, NE.P_ci{c, MM.lg_cut(l)}, [I.I{0.0f64, 1.0f64}])
      mmroots_es(t, l, Nat.add(ei, 1n), acc ++ " e" ++ Nat.show(ei) ++ Bool.pick(String, fl, "F", "") ++ mmroots_rs(rs, ""))


def mmroots_ls(ls: List<&2, MM.Lg>, +es: List<&2, MM.Er>, +rp: List<&2, I.I>, +li: Nat, +acc: String) -> String:
  match ls:
    case []: acc
    case +l <> +t:
      mmroots_ls(t, es, rp, Nat.add(li, 1n), acc ++ " L" ++ Nat.show(li) ++ mmroots_es(es, l, 0n, ""))


def mmroots(+fc: MM.Fc, +q: List<&2, I.I>, +nf: MI.Im) -> String:
  +es = MM.fc_es(fc)
  +e0 = MM.er_at(es, 0n)
  +rp = RB.cv_box(MM.er_c(e0), I.ipt(0.5f64))
  +lp = MM.legs_of(MM.fc_s(fc), q, rp, True{}, nf)
  mmroots_ls(MM.lp_ls(lp), es, rp, 0n, "")

def mmcut_show(+c: MI.Im) -> String:
  match c:
    case MI.M_pl{+o, +n}: "pl" ++ F64.show(I.imid(XX.vn(o, 2n)))
    case _: "other"


def mmcut_ls(ls: List<&2, MM.Lg>, +acc: String) -> String:
  match ls:
    case []: acc
    case +l <> +t:
      mmcut_ls(t, acc ++ " cut:" ++ mmcut_show(MM.lg_cut(l)))


def mmes(es: List<&2, MM.Er>, +i: Nat, +acc: String) -> String:
  match es:
    case []: acc
    case +e <> +t:
      +m = RB.cv_box(MM.er_c(e), I.ipt(0.5f64))
      mmes(t, Nat.add(i, 1n), acc ++ " e" ++ Nat.show(i) ++ "(" ++ F64.show(I.imid(XX.vn(m, 0n))) ++ "," ++ F64.show(I.imid(XX.vn(m, 1n))) ++ "," ++ F64.show(I.imid(XX.vn(m, 2n))) ++ ")")


def mmcut(+fc: MM.Fc, +q: List<&2, I.I>, +nf: MI.Im) -> String:
  +es = MM.fc_es(fc)
  +e0 = MM.er_at(es, 0n)
  +rp = RB.cv_box(MM.er_c(e0), I.ipt(0.5f64))
  +lp = MM.legs_of(MM.fc_s(fc), q, rp, True{}, nf)
  "rpz" ++ F64.show(I.imid(XX.vn(rp, 2n))) ++ mmcut_ls(MM.lp_ls(lp), "") ++ mmes(es, 0n, "")

def mmcmp_at(fs: List<&2, SO.Fd>, +at: Nat) -> String:
  match fs:
    case []: "nofd"
    case +h <> +t:
      match at:
        case 0n:
          "z10:" ++ mmone(SO.fd_fc(h), [I.ipt(3.0f64), I.ipt(0.0f64), I.ipt(10.0f64)], SO.fd_im(h), 0n, 0.5f64, True{}) ++
            " up:" ++ mmone(SO.fd_fc(h), [I.ipt(3.0f64), I.ipt(0.0f64), I.ipt(10.0000001f64)], SO.fd_im(h), 0n, 0.5f64, True{})
        case 1n+j: mmcmp_at(t, j)

def mmcmp() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  mmcmp_at(SO.fds_of(K1.kr_brep(kr)), 4n)



def mmrd_at(fs: List<&2, SO.Fd>, +at: Nat) -> String:
  match fs:
    case []: "nofd"
    case +h <> +t:
      match at:
        case 0n:
          "z10:" ++ mmroots(SO.fd_fc(h), [I.ipt(3.0f64), I.ipt(0.0f64), I.ipt(10.0f64)], SO.fd_im(h)) ++
            " up:" ++ mmroots(SO.fd_fc(h), [I.ipt(3.0f64), I.ipt(0.0f64), I.ipt(10.0000001f64)], SO.fd_im(h))
        case 1n+j: mmrd_at(t, j)

def mmrd() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  mmrd_at(SO.fds_of(K1.kr_brep(kr)), 4n)


def mmcd_at(fs: List<&2, SO.Fd>, +at: Nat) -> String:
  match fs:
    case []: "nofd"
    case +h <> +t:
      match at:
        case 0n:
          "z10:" ++ mmcut(SO.fd_fc(h), [I.ipt(3.0f64), I.ipt(0.0f64), I.ipt(10.0f64)], SO.fd_im(h)) ++
            " up:" ++ mmcut(SO.fd_fc(h), [I.ipt(3.0f64), I.ipt(0.0f64), I.ipt(10.0000001f64)], SO.fd_im(h))
        case 1n+j: mmcd_at(t, j)

def mmcd() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  mmcd_at(SO.fds_of(K1.kr_brep(kr)), 4n)


def mmvd_pt(xs: List<&2, I.I>, ys: List<&2, I.I>, zs: List<&2, I.I>, ws: List<&2, I.I>, +o: List<&2, I.I>, +n: List<&2, I.I>, +acc: String) -> String:
  match xs:
    case []: acc
    case x <> xt:
      match ys:
        case []: acc
        case y <> yt:
          match zs:
            case []: acc
            case z <> zt:
              match ws:
                case []: acc
                case +w <> wt:
                  +f = XX.vdot(n, XX.vsub([x, y, z], MM.vs(w, o)))
                  mmvd_pt(xt, yt, zt, wt, o, n, acc ++ " [" ++ F64.show(I.i_lo(f)) ++ "," ++ F64.show(I.i_hi(f)) ++ "]")

def mmvd_rb(r: RB.Rb, +o: List<&2, I.I>, +n: List<&2, I.I>) -> String:
  RB.Rb{x, y, z, w} = r
  mmvd_pt(x, y, z, w, o, n, "")

def mmvd_cut(+c: MI.Im, +cv: RB.Cv) -> String:
  match c:
    case MI.M_pl{+o, +n}: mmvd_rb(RB.cv_rb(cv), o, n)
    case _: "nonpl"

def mmvd_es(es: List<&2, MM.Er>, +l: MM.Lg, +ei: Nat, +acc: String) -> String:
  match es:
    case []: acc
    case +e <> +t:
      mmvd_es(t, l, Nat.add(ei, 1n), acc ++ " e" ++ Nat.show(ei) ++ mmvd_cut(MM.lg_cut(l), MM.er_c(e)))

def mmvd_ls(ls: List<&2, MM.Lg>, +es: List<&2, MM.Er>, +acc: String) -> String:
  match ls:
    case []: acc
    case +l <> +t:
      mmvd_ls(t, es, acc ++ mmvd_es(es, l, 0n, ""))

def mmvd_at(fs: List<&2, SO.Fd>, +at: Nat) -> String:
  match fs:
    case []: "nofd"
    case +h <> +t:
      match at:
        case 0n:
          +fc = SO.fd_fc(h)
          +q: List<&2, I.I> = [I.ipt(3.0f64), I.ipt(0.0f64), I.ipt(10.0f64)]
          +es = MM.fc_es(fc)
          +rp = RB.cv_box(MM.er_c(MM.er_at(es, 0n)), I.ipt(0.5f64))
          +lp = MM.legs_of(MM.fc_s(fc), q, rp, True{}, SO.fd_im(h))
          mmvd_ls(MM.lp_ls(lp), es, "")
        case 1n+j: mmvd_at(t, j)

def mmvd() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  mmvd_at(SO.fds_of(K1.kr_brep(kr)), 4n)


def mmcn_u(+c: MM.Cn) -> String:
  match c:
    case MM.Cn{+n, +u}: Bool.pick(String, u, "U", "u")

def mmcn_show(+c: MM.Cn) -> String:
  "n" ++ Nat.show(MM.cn_n(c)) ++ mmcn_u(c)

def mmcn_es(es: List<&2, MM.Er>, +l: MM.Lg, +q: List<&2, I.I>, +rp: List<&2, I.I>, +ei: Nat, +acc: String) -> String:
  match es:
    case []: acc
    case +e <> +t:
      +c = MM.edge_cn(MM.flat(MM.er_c(e), MM.lg_cut(l)), MM.er_c(e), l, Nat.is_eq(ei, 0n), 0.5f64, MM.Cn{0n, False{}})
      mmcn_es(t, l, q, rp, Nat.add(ei, 1n), acc ++ " e" ++ Nat.show(ei) ++ mmcn_show(c))


def mmcn_ls(ls: List<&2, MM.Lg>, +es: List<&2, MM.Er>, +q: List<&2, I.I>, +rp: List<&2, I.I>, +li: Nat, +acc: String) -> String:
  match ls:
    case []: acc
    case +l <> +t:
      mmcn_ls(t, es, q, rp, Nat.add(li, 1n), acc ++ " L" ++ Nat.show(li) ++ mmcn_es(es, l, q, rp, 0n, ""))


def mmcn_at(fs: List<&2, SO.Fd>, +at: Nat) -> String:
  match fs:
    case []: "nofd"
    case +h <> +t:
      match at:
        case 0n:
          +fc = SO.fd_fc(h)
          +q: List<&2, I.I> = [I.ipt(3.0f64), I.ipt(0.0f64), I.ipt(10.0f64)]
          +es = MM.fc_es(fc)
          +rp = RB.cv_box(MM.er_c(MM.er_at(es, 0n)), I.ipt(0.5f64))
          +lp = MM.legs_of(MM.fc_s(fc), q, rp, True{}, SO.fd_im(h))
          mmcn_ls(MM.lp_ls(lp), es, q, rp, 0n, "")
        case 1n+j: mmcn_at(t, j)

def mmcn() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  mmcn_at(SO.fds_of(K1.kr_brep(kr)), 4n)

def vportop() -> String:
  +e = X.env_mk([])
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +v = B8.vcore(B8.bake_of(M.bool_in(b3)))
  Bool.pick(String, B8.VR_ok(v), "vok", "vno " ++ B8.vcode(v))

def vportemb() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +b = K1.kr_brep(kr)
  +x = Ty.ix_of(b)
  +fu = Nat.add(Nat.mul(4n, Nat.add(List.length(&2, Ty.Coedge, Ty.brep_ces(b)), List.length(&2, Ty.Vertex, Ty.brep_vs(b)))), 64n)
  Bool.pick(String, B4.es_embed_ok(Ty.brep_es(b), x, fu), "es", "NOES") ++
    Bool.pick(String, B4.ces_trim_ok(Ty.brep_ces(b)), "ces", "NOCES") ++
    Bool.pick(String, B4.fas_surf_ok(Ty.brep_fas(b)), "fas", "NOFAS") ++
    Bool.pick(String, B4.fas_coinc_ok(Ty.brep_fas(b), x), "coinc", "NOCOINC")

def portcf_go(fs: List<&2, Ty.Face>, +x: Ty.Ix, +at: Nat, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      +sf = Ty.fa_surf(h)
      +ok = B4.hls_face_ok(Ty.fa_loops(h), x, sf, B4.surf_coinc(sf), B4.surf_quad(sf))
      portcf_go(t, x, Nat.add(at, 1n), Bool.pick(String, ok, acc, acc ++ " f" ++ Nat.show(at)))

def portcoinc() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +b = K1.kr_brep(kr)
  "bad:" ++ portcf_go(Ty.brep_fas(b), Ty.ix_of(b), 0n, "")

def portfinfo() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +b = K1.kr_brep(kr)
  finfo_go(Ty.brep_fas(b), 0n, "") ++ " | " ++ facedump_go(Ty.brep_fas(b), b, 0n, "")

def portrim_go(fs: List<&2, Ty.Face>, +b: Ty.Brep, +want: Nat, +at: Nat) -> String:
  match fs:
    case []: "none"
    case +h <> +t:
      +hl = first_hlp(Ty.fa_loops(h))
      +lp = KU.nth_lp0(Ty.brep_lps(b), Ty.hlp_idx(hl))
      +hc = first_hce(Ty.lp_ces(lp))
      +ce = KU.nth_ce0(Ty.brep_ces(b), Ty.hc_idx(hc))
      +ed = KU.nth_ed0(Ty.brep_es(b), Ty.he_idx(Ty.ce_edge(ce)))
      +v0 = Ty.vx_p(KU.nth_vx0(Ty.brep_vs(b), Ty.hv_idx(Ty.ed_v0(ed))))
      +ts = B4.trim_o_start(Ty.ce_trim(ce), Ty.ce_fwd(ce))
      +rs = B4.surf_at(Ty.fa_surf(h), V.v2_x(ts), V.v2_y(ts))
      +here = "ts(" ++ F64.show(V.v2_x(ts)) ++ "," ++ F64.show(V.v2_y(ts)) ++ ")v0(" ++
        F64.show(V.pt_x(v0)) ++ "," ++ F64.show(V.pt_y(v0)) ++ "," ++ F64.show(V.pt_z(v0)) ++
        ")sat(" ++ F64.show(V.pt_x(G.gres_p(rs))) ++ "," ++ F64.show(V.pt_y(G.gres_p(rs))) ++
        "," ++ F64.show(V.pt_z(G.gres_p(rs))) ++ ")"
      Bool.pick(String, Nat.is_eq(at, want), here, portrim_go(t, b, want, Nat.add(at, 1n)))

def portrim() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  "k1:" ++ portrim_go(Ty.brep_fas(K1.kr_brep(kr)), K1.kr_brep(kr), 6n, 0n)

def portqg_show(ps: List<&2, QC.QG>, +acc: String) -> String:
  match ps:
    case []: acc
    case +h <> +t:
      portqg_show(t, acc ++ Bool.pick(String, QC.qg_is_ln(h), "L", Bool.pick(String, QC.qg_closed(h), "C", "A")))


def portqg_go(fs: List<&2, Ty.Face>, +b: Ty.Brep, +at: Nat, +acc: String) -> String:
  match fs:
    case []: acc
    case +h <> +t:
      +fr = K1.fr_of(Ty.fa_surf(h), KU.surfkind(Ty.fa_surf(h)))
      +lq = K1.face_qg(b, at, fr, False{})
      portqg_go(t, b, Nat.add(at, 1n), acc ++ " f" ++ Nat.show(at) ++ Bool.pick(String, K1.lq_ok(lq), "ok[", "NO[") ++ portqg_show(K1.lq_outer(lq), "") ++ "]")

def portqg() -> String:
  +e = X.env_mk([])
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +bb = B8.bake_of(M.bool_in(b3))
  portqg_go(Ty.brep_fas(bb), bb, 0n, "")


def portka() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  K1.dbg_ka(B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def u64show_go(xs: List<&2, U64>, +acc: String) -> String:
  match xs:
    case []: acc
    case +h <> +t: u64show_go(t, acc ++ U64.show(h) ++ ",")

def nsshow_go(xs: List<&2, M.NS>, +acc: String) -> String:
  match xs:
    case []: acc
    case +h <> +t:
      nsshow_go(t, acc ++ " [" ++ u64show_go(M.ns_k(h), "") ++ "." ++ Nat.show(M.ns_lp(h)) ++
        "." ++ Nat.show(M.ns_ce(h)) ++ "]")

def paddbg() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +o4 = B8.run(B8.tag_union(), M.bool_in(b1), M.bool_in(b3), 4u64, 1u64, 3u64, False{})
  +n4 = M.bool_carry(o4, b1, b3)
  +tool = coltool(e, 5u64)
  +o5 = B8.run(B8.tag_union(), M.bool_in(n4), M.bool_in(tool), 5u64, 0u64, 0u64, False{})
  +n5 = M.bool_carry(o5, n4, tool)
  +rn = M.body_ns(n5)
  +bn = M.body_ns(n4)
  +d = M.diff_go(Nat.add(List.length(&2, M.NS, rn), List.length(&2, M.NS, bn)), rn, bn, 0n, 0n)
  "o5ok=" ++ Bool.pick(String, B8.Out_ok(o5), "T", "F") ++ " v4=[" ++ F64.show(I.i_lo(M.ms_vol(M.body_ms(n4)))) ++
    "," ++ F64.show(I.i_hi(M.ms_vol(M.body_ms(n4)))) ++ "] v5=[" ++
    F64.show(I.i_lo(M.ms_vol(M.body_ms(n5)))) ++ "," ++ F64.show(I.i_hi(M.ms_vol(M.body_ms(n5)))) ++
    "] f4=" ++ Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(M.bd_brep(n4)))) ++
    " f5=" ++ Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(M.bd_brep(n5)))) ++
    " n4=" ++ Nat.show(List.length(&2, M.NS, bn)) ++ " n5=" ++ Nat.show(List.length(&2, M.NS, rn)) ++
    " fc=" ++ Nat.show(M.nth_n(d, 0n)) ++ " fm=" ++ Nat.show(M.nth_n(d, 1n)) ++
    " base:" ++ nsshow_go(bn, "") ++ " res:" ++ nsshow_go(rn, "")

def rqbits(+pa: V.Point, +pb: V.Point, +rq: G.RQBez, +tm: G.GVal, +fa: U64, +f: Bool) -> String:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = rq
  +w1ok = Bool.and(F64.is_eq(w0, 1.0f64), F64.is_eq(w2, 1.0f64))
  +eok = Bool.pick(Bool, f, Bool.and(K1.k1pteq(p0, pa), K1.k1pteq(p2, pb)),
    Bool.and(K1.k1pteq(p0, pb), K1.k1pteq(p2, pa)))
  +tok = K1.k1trim_ok(tm)
  +a = K1.k1drop(pa, fa)
  +b = K1.k1drop(pb, fa)
  +c2 = K1.k1drop(p1, fa)
  +den = F64.add(2.0f64, F64.mul(2.0f64, w1))
  +mmx = F64.div(F64.add(V.v2_x(a), F64.add(F64.mul(F64.mul(2.0f64, w1), V.v2_x(c2)), V.v2_x(b))), den)
  +mmy = F64.div(F64.add(V.v2_y(a), F64.add(F64.mul(F64.mul(2.0f64, w1), V.v2_y(c2)), V.v2_y(b))), den)
  +midx = F64.mul(0.5f64, F64.add(V.v2_x(a), V.v2_x(b)))
  +midy = F64.mul(0.5f64, F64.add(V.v2_y(a), V.v2_y(b)))
  +h = F64.mul(0.5f64, K1.k1d2(a, b))
  +sdx = F64.sub(mmx, midx)
  +sdy = F64.sub(mmy, midy)
  +s = F64.sqrt(F64.add(F64.mul(sdx, sdx), F64.mul(sdy, sdy)))
  +axp = K1.k1axc(pa, fa)
  +axb = F64.is_le(F64.abs(F64.sub(K1.k1axc(pb, fa), axp)), K1.k1tol(axp))
  +axq = F64.is_le(F64.abs(F64.sub(K1.k1axc(p1, fa), axp)), K1.k1tol(axp))
  +r = F64.div(F64.add(F64.mul(h, h), F64.mul(s, s)), F64.add(s, s))
  +ie = F64.sub(F64.add(F64.mul(F64.div(h, r), F64.div(h, r)), F64.mul(w1, w1)), 1.0f64)
  +idok = F64.is_le(F64.abs(ie), 1.0e-14f64)
  +sok = F64.is_le(F64.mul(5.0e-10f64, F64.add(h, s)), s)
  +rw = I.iwiden(K1.k1w(r), F64.mul(r, 1.0e-14f64))
  +adm = K1.kasin_adm(I.idiv(K1.k1w(h), rw))
  +dot = F64.add(F64.mul(F64.sub(V.v2_x(c2), midx), sdx), F64.mul(F64.sub(V.v2_y(c2), midy), sdy))
  +major = F64.is_lt(h, s)
  +agree = Bool.pick(Bool, major, F64.is_lt(dot, 0.0f64), F64.is_lt(0.0f64, dot))
  Bool.pick(String, w1ok, "W", "w") ++ Bool.pick(String, eok, "E", "e") ++
    Bool.pick(String, tok, "T", "t") ++ Bool.pick(String, axb, "X", "x") ++
    Bool.pick(String, axq, "Q", "q") ++ Bool.pick(String, idok, "I", "i") ++
    Bool.pick(String, sok, "S", "s") ++ Bool.pick(String, adm, "D", "d") ++
    Bool.pick(String, agree, "G", "g") ++ Bool.pick(String, major, "M", "m") ++
    " w1=" ++ F64.show(w1) ++ " h=" ++ F64.show(h) ++ " s=" ++ F64.show(s) ++
    " r=" ++ F64.show(r) ++ " ie=" ++ F64.show(ie) ++ " dot=" ++ F64.show(dot)

def rqdump_go(cs: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, +fa: U64, +acc: String) -> String:
  match cs:
    case []: acc
    case +h <> +t:
      +ce = KU.nth_ce0(ces, Ty.hc_idx(h))
      +ed = KU.nth_ed0(es, Ty.he_idx(Ty.ce_edge(ce)))
      +f = Ty.ce_fwd(ce)
      +tag = K1.gv_tag(Ty.ekind_curve(Ty.ed_kind(ed)))
      +ia = Bool.pick(Nat, f, Ty.hv_idx(Ty.ed_v0(ed)), Ty.hv_idx(Ty.ed_v1(ed)))
      +ib = Bool.pick(Nat, f, Ty.hv_idx(Ty.ed_v1(ed)), Ty.hv_idx(Ty.ed_v0(ed)))
      +pa = Ty.vx_p(KU.nth_vx0(vs, ia))
      +pb = Ty.vx_p(KU.nth_vx0(vs, ib))
      +rq = K1.gv_rq_of(Ty.ekind_curve(Ty.ed_kind(ed)))
      +cc = K1.gv_cc_of(Ty.ekind_curve(Ty.ed_kind(ed)))
      +c3 = G.cc_c(cc)
      +r3 = G.cc_r(cc)
      +a3 = K1.k1drop(pa, fa)
      +b3 = K1.k1drop(pb, fa)
      +c33 = K1.k1drop(c3, fa)
      +m3 = K1.k1trim_mid(Ty.ce_trim(ce))
      +b3s = Bool.pick(String, K1.k1trim_ok(Ty.ce_trim(ce)), "T", "t") ++
        Bool.pick(String, K1.k1onc(a3, c33, r3), "A", "a") ++
        Bool.pick(String, K1.k1onc(b3, c33, r3), "B", "b") ++
        Bool.pick(String, K1.k1onc(m3, c33, r3), "M", "m")
      +bits = Bool.pick(String, U64.is_eq(tag, 2u64), rqbits(pa, pb, rq, Ty.ce_trim(ce), fa, f),
        Bool.pick(String, U64.is_eq(tag, 3u64), b3s, "ln" ++ F64.show(K1.k1d3(pa, pb))))
      rqdump_go(t, ces, es, vs, fa, acc ++ " t" ++ U64.show(tag) ++ bits)

def k_rqdump() -> String:
  +e = X.env_mk([])
  +f1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +f3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(f1)), B8.bake_of(M.bool_in(f3)))
  +b = K1.kr_brep(kr)
  +f0 = KU.nth_fa0(Ty.brep_fas(b), 0n)
  +lp = KU.nth_lp0(Ty.brep_lps(b), Ty.hlp_idx(f0h(Ty.fa_loops(f0))))
  rqdump_go(Ty.lp_ces(lp), Ty.brep_ces(b), Ty.brep_es(b), Ty.brep_vs(b), 2u64, "")

def wdump_go(ls: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, +fa: U64, +wr: F64, +lo: F64,
    +hi: F64, +so: F64, +cu: F64, +cv: F64, +acc: String) -> String:
  match ls:
    case []: acc
    case +h <> +t:
      +w = K1.k1wloop(h, lps, ces, es, vs, fa, wr, lo, hi, so, cu, cv)
      +cs = Ty.lp_ces(KU.nth_lp0(lps, Ty.hlp_idx(h)))
      wdump_go(t, lps, ces, es, vs, fa, wr, lo, hi, so, cu, cv, acc ++ " lp[na" ++
        Nat.show(K1.k1w_narc(w)) ++ "nl" ++ Nat.show(K1.k1w_nln(w)) ++ "nc" ++
        Nat.show(K1.k1w_ncl(w)) ++ "ne" ++ Nat.show(K1.k1w_nce(w)) ++
        Bool.pick(String, K1.k1w_ok(w), "ok", "NO") ++ " dth[" ++
        F64.show(I.i_lo(K1.k1w_dth(w))) ++ "," ++ F64.show(I.i_hi(K1.k1w_dth(w))) ++
        "]fx[" ++ F64.show(I.i_lo(K1.k1w_fx(w))) ++ "," ++
        F64.show(I.i_hi(K1.k1w_fx(w))) ++ "]" ++ rqdump_go(cs, ces, es, vs, fa, "") ++ "]")

def k_wdump() -> String:
  +e = X.env_mk([])
  +f1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +f3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(f1)), B8.bake_of(M.bool_in(f3)))
  +b = K1.kr_brep(kr)
  +f4 = KU.nth_fa0(Ty.brep_fas(b), 4n)
  +sk = KU.surfkind(Ty.fa_surf(f4))
  +ax = U64.sub(sk, 4u64)
  +rg = K1.k1range_face(Ty.fa_loops(f4), Ty.brep_lps(b), Ty.brep_ces(b), Ty.brep_es(b),
    Ty.brep_vs(b), ax)
  +wr = G.cy_r(K1.gv_cy_of(Ty.fa_surf(f4)))
  +so = Bool.pick(F64, Ty.fa_same(f4), 1.0f64, F64.neg(1.0f64))
  "sk" ++ U64.show(sk) ++ " wr=" ++ F64.show(wr) ++ " lo=" ++ F64.show(K1.k1r_lo(rg)) ++
    " hi=" ++ F64.show(K1.k1r_hi(rg)) ++ " so=" ++ F64.show(so) ++
    wdump_go(Ty.fa_loops(f4), Ty.brep_lps(b), Ty.brep_ces(b), Ty.brep_es(b), Ty.brep_vs(b),
      ax, wr, K1.k1r_lo(rg), K1.k1r_hi(rg), so, 0.0f64, 0.0f64, "")

def k_uf_ces(ces: List<&2, Ty.Coedge>, +ei: Nat, +eg: U64, +n: Nat, +t: Bool, +f: Bool) -> String:
  match ces:
    case []:
      Bool.pick(String, Bool.and(Nat.is_eq(n, 2n), Bool.and(t, f)), "",
        " E" ++ Nat.show(ei) ++ "n" ++ Nat.show(n) ++ Bool.pick(String, t, "t", "") ++
        Bool.pick(String, f, "f", ""))
    case +h <> +tt:
      +hit = Bool.and(Nat.is_eq(Ty.he_idx(Ty.ce_edge(h)), ei),
        U64.is_eq(Ty.he_gen(Ty.ce_edge(h)), eg))
      +fw = Ty.ce_fwd(h)
      k_uf_ces(tt, ei, eg, Bool.pick(Nat, hit, Nat.add(n, 1n), n),
        Bool.or(t, Bool.and(hit, fw)), Bool.or(f, Bool.and(hit, Bool.not(fw))))

def k_uf_id(ces: List<&2, Ty.Coedge>, +ei: Nat, +eg: U64, +n: Nat, +t: Bool, +f: Bool,
    +e: Ty.Edge) -> String:
  match ces:
    case []:
      Bool.pick(String, Bool.and(Nat.is_eq(n, 2n), Bool.and(t, f)), "",
        "k" ++ U64.show(Ty.ekind_tag(Ty.ed_kind(e))) ++ "v" ++ Nat.show(Ty.hv_idx(Ty.ed_v0(e))) ++
        "v" ++ Nat.show(Ty.hv_idx(Ty.ed_v1(e))) ++ " ")
    case +h <> +tt:
      +hit = Bool.and(Nat.is_eq(Ty.he_idx(Ty.ce_edge(h)), ei),
        U64.is_eq(Ty.he_gen(Ty.ce_edge(h)), eg))
      +fw = Ty.ce_fwd(h)
      k_uf_id(tt, ei, eg, Bool.pick(Nat, hit, Nat.add(n, 1n), n),
        Bool.or(t, Bool.and(hit, fw)), Bool.or(f, Bool.and(hit, Bool.not(fw))), e)

def k_uf_es(es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>, +ei: Nat, +acc: String) -> String:
  match es:
    case []: acc
    case +h <> +t:
      k_uf_es(t, ces, Nat.add(ei, 1n), acc ++ k_uf_ces(ces, ei, Ty.ed_gen(h), 0n, False{}, False{}) ++
        k_uf_id(ces, ei, Ty.ed_gen(h), 0n, False{}, False{}, h))

def k_usefail() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +bore = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(bore)))
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +port = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +kr2 = K1.k1run(B8.tag_diff(), K1.kr_brep(kr), B8.bake_of(M.bool_in(port)))
  +b = K1.kr_brep(kr2)
  "E" ++ Nat.show(List.length(&2, Ty.Edge, Ty.brep_es(b))) ++ "C" ++
    Nat.show(List.length(&2, Ty.Coedge, Ty.brep_ces(b))) ++
    k_uf_es(Ty.brep_es(b), Ty.brep_ces(b), 0n, "")

def k_topo_ce(cs: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>) -> String:
  match cs:
    case []: ""
    case +h <> +t:
      +ce = KU.nth_ce0(ces, Ty.hc_idx(h))
      " " ++ Nat.show(Ty.he_idx(Ty.ce_edge(ce))) ++ Bool.pick(String, Ty.ce_fwd(ce), "+", "-") ++
        k_topo_ce(t, ces)

def k_topo_lp(ls: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>) -> String:
  match ls:
    case []: ""
    case +h <> +t:
      " L" ++ Nat.show(Ty.hlp_idx(h)) ++ "(" ++
        Nat.show(List.length(&2, Ty.HCoedge, Ty.lp_ces(KU.nth_lp0(lps, Ty.hlp_idx(h))))) ++ ")" ++
        k_topo_ce(Ty.lp_ces(KU.nth_lp0(lps, Ty.hlp_idx(h))), ces) ++ k_topo_lp(t, lps, ces)

def k_topo_fa(fs: List<&2, Ty.Face>, +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +fi: Nat) -> String:
  match fs:
    case []: ""
    case +h <> +t:
      "\nF" ++ Nat.show(fi) ++ k_topo_lp(Ty.fa_loops(h), lps, ces) ++ k_topo_fa(t, lps, ces, Nat.add(fi, 1n))

def k_topo() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +bore = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(bore)))
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +port = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  +kr2 = K1.k1run(B8.tag_diff(), K1.kr_brep(kr), B8.bake_of(M.bool_in(port)))
  +b = K1.kr_brep(kr2)
  k_topo_fa(Ty.brep_fas(b), Ty.brep_lps(b), Ty.brep_ces(b), 0n)

def k_cg_show(xs: List<&2, I.I>) -> String:
  match xs:
    case []: ""
    case +h <> +t:
      "[" ++ F64.show(I.i_lo(h)) ++ "," ++ F64.show(I.i_hi(h)) ++ "]" ++ k_cg_show(t)

def k_cg_bb(+b: Ty.Brep) -> String:
  +bb = SO.bbox(SO.fds_of(b), [])
  k_cg_show(bb)

def k_corpusgeo() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +n2 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 2u64)
  +kr5 = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(n2)))
  +n6 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 6u64)
  +n7 = unnr(M.op_rot(n6, 1u64, M.xk(90.0f64), e, 7u64))
  +n8 = moved(n7, 0.0f64, 5.0f64, 5.0f64, e, 8u64)
  +b5 = K1.kr_brep(kr5)
  +b8 = B8.bake_of(M.bool_in(n8))
  "n5ok=" ++ Bool.pick(String, K1.kr_ok(kr5), "1", "0") ++ " bb5=" ++ k_cg_bb(b5) ++
    " bb8=" ++ k_cg_bb(b8) ++
    " d9=" ++ vsum(B8.tag_diff(), b5, b8) ++ " i10=" ++ vsum(B8.tag_inter(), b5, b8) ++
    " u11=" ++ vsum(B8.tag_union(), b5, b8)

def k_cg2() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +n2 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 2u64)
  +kr5 = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(n2)))
  +n6 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 6u64)
  +n7 = unnr(M.op_rot(n6, 1u64, M.xk(90.0f64), e, 7u64))
  +n8 = moved(n7, 0.0f64, 1.0f64, 10.0f64, e, 8u64)
  +b5 = K1.kr_brep(kr5)
  +b8 = B8.bake_of(M.bool_in(n8))
  +u2 = moved(zcyl(1.5f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 2u64)
  +ur5 = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(u2)))
  +u6 = moved(zcyl(1.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 6u64)
  +u7 = unnr(M.op_rot(u6, 1u64, M.xk(90.0f64), e, 7u64))
  +u8 = moved(u7, 0.0f64, 0.0f64, 10.0f64, e, 8u64)
  +ub5 = K1.kr_brep(ur5)
  +ub8 = B8.bake_of(M.bool_in(u8))
  "eqbb8=" ++ k_cg_bb(b8) ++ " eqd9=" ++ vsum(B8.tag_diff(), b5, b8) ++
    " eqi10=" ++ vsum(B8.tag_inter(), b5, b8) ++ " equ11=" ++ vsum(B8.tag_union(), b5, b8) ++
    " unbb8=" ++ k_cg_bb(ub8) ++ " und9=" ++ vsum(B8.tag_diff(), ub5, ub8) ++
    " uni10=" ++ vsum(B8.tag_inter(), ub5, ub8) ++ " unu11=" ++ vsum(B8.tag_union(), ub5, ub8)

def k_ufx(+op: U64) -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +n2 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 2u64)
  +kr5 = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(n2)))
  +n6 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 6u64)
  +n7 = unnr(M.op_rot(n6, 1u64, M.xk(90.0f64), e, 7u64))
  +n8 = moved(n7, 0.0f64, 1.0f64, 10.0f64, e, 8u64)
  +kr = K1.k1run(op, K1.kr_brep(kr5), B8.bake_of(M.bool_in(n8)))
  +b = K1.kr_brep(kr)
  "why=" ++ U64.show(K1.kr_why(kr)) ++ " E" ++
    Nat.show(List.length(&2, Ty.Edge, Ty.brep_es(b))) ++ "C" ++
    Nat.show(List.length(&2, Ty.Coedge, Ty.brep_ces(b))) ++
    k_uf_es(Ty.brep_es(b), Ty.brep_ces(b), 0n, "")

def k_topx(+op: U64) -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +n2 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 2u64)
  +kr5 = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(n2)))
  +n6 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 6u64)
  +n7 = unnr(M.op_rot(n6, 1u64, M.xk(90.0f64), e, 7u64))
  +n8 = moved(n7, 0.0f64, 1.0f64, 10.0f64, e, 8u64)
  +kr = K1.k1run(op, K1.kr_brep(kr5), B8.bake_of(M.bool_in(n8)))
  +b = K1.kr_brep(kr)
  "why=" ++ U64.show(K1.kr_why(kr)) ++ " F" ++
    Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(b))) ++ " L" ++
    Nat.show(List.length(&2, Ty.Loop, Ty.brep_lps(b))) ++
    k_topo_fa(Ty.brep_fas(b), Ty.brep_lps(b), Ty.brep_ces(b), 0n)

def k_topxu(+which: U64) -> String:
  k_topx(Bool.pick(U64, U64.is_eq(which, 0u64), B8.tag_union(), B8.tag_inter()))

def k_topu() -> String:
  k_topx(B8.tag_union())

def k_topi() -> String:
  k_topx(B8.tag_inter())

def k_topd() -> String:
  k_topx(B8.tag_diff())

def k_ufu() -> String:
  k_ufx(B8.tag_union())

def k_ufi() -> String:
  k_ufx(B8.tag_inter())

def k_ufd() -> String:
  k_topx(B8.tag_diff())

def k_sen_pt(+p: V.Point) -> String:
  F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p))

def k_sen_vs(+vs: List<&2, V.Point>, +n: Nat) -> String:
  match vs:
    case []: ""
    case +h <> +t:
      match n:
        case 0n: ""
        case 1n+m: " " ++ k_sen_pt(h) ++ k_sen_vs(t, m)

def k_sen_q(+vs: List<&2, V.Point>, +fr: K1.FR, +sm0: Bool) -> String:
  match vs:
    case []: " empty"
    case +h <> +t:
      +ax = K1.fr_ax(fr)
      +n = List.length(&2, V.Point, vs)
      +iz = K1.isl_zmi_go(t, ax, 1n, 0n, K1.pcomp(h, ax))
      +ps = K1.isl_nth(vs, iz, h)
      +pn = K1.isl_nth(vs, Nat.mod(Nat.add(iz, 1n), n), h)
      +pp = K1.isl_nth(vs, Nat.mod(Nat.add(iz, Nat.sub(n, 1n)), n), h)
      +tan = GO.pp_sub_raw(pn, pp)
      +rad = K1.isl_rad(ps, K1.fr_o(fr), K1.dir_ax(ax))
      +nr = Bool.pick(V.Dir, sm0, rad, GO.dd_scale_raw(F64.neg(1.0f64), rad))
      +q = GO.dd_dot_raw(GO.dd_cross_raw(tan, nr), K1.dir_ax(ax))
      " iz" ++ Nat.show(iz) ++ " ps" ++ k_sen_pt(ps) ++ " tn" ++
        F64.show(V.dr_x(tan)) ++ "," ++ F64.show(V.dr_y(tan)) ++ "," ++
        F64.show(V.dr_z(tan)) ++ " nr" ++ F64.show(V.dr_x(nr)) ++ "," ++
        F64.show(V.dr_y(nr)) ++ "," ++ F64.show(V.dr_z(nr)) ++ " q" ++ F64.show(q)

def k_sen_rs(+rs: List<&2, RX.RING>, +fr: K1.FR, +sm0: Bool, +tag: String) -> String:
  match rs:
    case []: ""
    case +h <> +t:
      +vs = RX.ring_vs(h)
      +zr = RX.rx_zrange(vs, K1.fr_ax(fr))
      tag ++ " n" ++ Nat.show(List.length(&2, V.Point, vs)) ++
        " z[" ++ F64.show(V.v2_x(zr)) ++ "," ++ F64.show(V.v2_y(zr)) ++ "]" ++
        " cd" ++ Nat.show(K1.isl_sense(vs, fr, sm0, False{})) ++ k_sen_q(vs, fr, sm0) ++
        k_sen_vs(vs, 3n) ++ "\n" ++ k_sen_rs(t, fr, sm0, tag)

def k_sen_one(+cv: KU.KCv, +fa: Nat, +fb: Nat, +b5: Ty.Brep, +b8: Ty.Brep,
    +op: U64) -> String:
  +f0 = KU.nth_fa0(Ty.brep_fas(b5), fa)
  +f1 = KU.nth_fa0(Ty.brep_fas(b8), fb)
  +s0 = Ty.fa_surf(f0)
  +s1 = Ty.fa_surf(f1)
  +fr0 = K1.fr_of(s0, KU.surfkind(s0))
  +fr1 = K1.fr_of(s1, KU.surfkind(s1))
  +sm0 = KC.band_sm(KC.kflip(op, 0u64), Ty.fa_same(f0))
  +sm1 = KC.band_sm(KC.kflip(op, 1u64), Ty.fa_same(f1))
  k_sen_rs(KU.kcv_rings(cv, 0u64), fr0, sm0,
    "A fa" ++ Nat.show(fa) ++ " sm" ++ Bool.pick(String, sm0, "1", "0")) ++
    k_sen_rs(KU.kcv_rings(cv, 1u64), fr1, sm1,
      "B fb" ++ Nat.show(fb) ++ " sm" ++ Bool.pick(String, sm1, "1", "0"))

def k_sen_ks(+ks: List<&2, KU.KA>, +b5: Ty.Brep, +b8: Ty.Brep, +op: U64) -> String:
  match ks:
    case []: ""
    case +h <> +t:
      +cv = KU.ka_cv(h)
      +fa = KU.ka_fa(h)
      +fb = KU.ka_fb(h)
      +rest = k_sen_ks(t, b5, b8, op)
      Bool.pick(String, U64.is_eq(KU.kcv_kind(cv), KC.ck_ring()),
        k_sen_one(cv, fa, fb, b5, b8, op) ++ rest, rest)

def k_sense() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +n2 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 2u64)
  +kr5 = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(n2)))
  +n6 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 6u64)
  +n7 = unnr(M.op_rot(n6, 1u64, M.xk(90.0f64), e, 7u64))
  +n8 = moved(n7, 0.0f64, 1.0f64, 10.0f64, e, 8u64)
  +b5 = K1.kr_brep(kr5)
  +b8 = B8.bake_of(M.bool_in(n8))
  k_sen_ks(KU.analist(b5, b8, SO.fds_of(b5), SO.fds_of(b8)), b5, b8, B8.tag_diff())

def k_sense_u() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +u2 = moved(zcyl(1.5f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 2u64)
  +ur5 = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(u2)))
  +u6 = moved(zcyl(1.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 6u64)
  +u7 = unnr(M.op_rot(u6, 1u64, M.xk(90.0f64), e, 7u64))
  +u8 = moved(u7, 0.0f64, 0.0f64, 10.0f64, e, 8u64)
  +ub5 = K1.kr_brep(ur5)
  +ub8 = B8.bake_of(M.bool_in(u8))
  k_sen_ks(KU.analist(ub5, ub8, SO.fds_of(ub5), SO.fds_of(ub8)), ub5, ub8, B8.tag_diff())

def k_ufu_u() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +u2 = moved(zcyl(1.5f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 2u64)
  +ur5 = K1.k1run(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(u2)))
  +u6 = moved(zcyl(1.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 6u64)
  +u7 = unnr(M.op_rot(u6, 1u64, M.xk(90.0f64), e, 7u64))
  +u8 = moved(u7, 0.0f64, 0.0f64, 10.0f64, e, 8u64)
  +kr = K1.k1run(B8.tag_diff(), K1.kr_brep(ur5), B8.bake_of(M.bool_in(u8)))
  +b = K1.kr_brep(kr)
  "why=" ++ U64.show(K1.kr_why(kr)) ++ " E" ++
    Nat.show(List.length(&2, Ty.Edge, Ty.brep_es(b))) ++ "C" ++
    Nat.show(List.length(&2, Ty.Coedge, Ty.brep_ces(b))) ++
    k_uf_es(Ty.brep_es(b), Ty.brep_ces(b), 0n, "")
