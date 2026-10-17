import Base
import ../../src/c04/types.bend as Ty
import ../../src/c06/model.bend as M
import ../../src/c06/xp.bend as X
import ../../src/c06/iv.bend as I
import ../../src/c08/bool.bend as B8
import ../../src/k1/surg.bend as K1
import ../../src/k1/gb.bend as GB
import ../../src/k1/vi.bend as VI
import ./probe.bend as P

def kshow(+r: K1.KR) -> String:
  +v = VI.brep_vol(K1.kr_brep(r))
  +vc = B8.vcore(K1.kr_brep(r))
  "ok=" ++ Bool.pick(String, K1.kr_ok(r), "T", "F") ++ " why=" ++ U64.show(K1.kr_why(r)) ++ " valid=" ++ Bool.pick(String, B8.VR_ok(vc), "T", B8.vcode(vc)) ++ " F" ++ Nat.show(K1.kr_nf(r)) ++ " S" ++ Nat.show(K1.kr_nc(r)) ++
    " vok=" ++ Bool.pick(String, VI.vr_ok(v), "T", "F") ++ " vol=[" ++ F64.show(I.i_lo(VI.vr_vol(v))) ++ "," ++ F64.show(I.i_hi(VI.vr_vol(v))) ++ "] area=[" ++
    F64.show(I.i_lo(VI.vr_ar(v))) ++ "," ++ F64.show(I.i_hi(VI.vr_ar(v))) ++ "]"

def port(+r: F64, +x: F64, +y: F64, +z: F64, +e: X.Env) -> Ty.Brep:
  +c6 = P.moved(P.zcyl(r, F64.neg(5.0f64), 15.0f64, e, 6u64), 5.0f64, 5.0f64, 0.0f64, e, 6u64)
  +c7 = P.unnr(M.op_rot(c6, 1u64, M.xk(90.0f64), e, 7u64))
  B8.bake_of(M.bool_in(P.moved(c7, x, y, z, e, 8u64)))

def main() -> String:
  +e = X.env_mk([])
  +b1 = B8.bake_of(M.bool_in(P.box10(e, 1u64)))
  +b2 = B8.bake_of(M.bool_in(P.moved(P.zcyl(1.5f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 2u64)))
  +b3 = B8.bake_of(M.bool_in(P.moved(P.zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 2u64)))
  +a = K1.kr_brep(GB.gbrun(B8.tag_diff(), b1, b2))
  +a3 = K1.kr_brep(GB.gbrun(B8.tag_diff(), b1, b3))
  +c1 = B8.bake_of(M.bool_in(P.zcyl(3.0f64, 0.0f64, 10.0f64, e, 11u64)))
  +c2 = B8.bake_of(M.bool_in(P.moved(P.zcyl(3.0f64, 0.0f64, 10.0f64, e, 12u64), 4.0f64, 0.0f64, 0.0f64, e, 13u64)))
  "cross diff " ++ kshow(GB.gbrun(B8.tag_diff(), a, port(1.0f64, 0.0f64, 0.0f64, 10.0f64, e))) ++
  "
fig8 union " ++ kshow(GB.gbrun(B8.tag_union(), c1, c2)) ++
  "
boreq diff " ++ kshow(GB.gbrun(B8.tag_diff(), a3, port(2.0f64, 0.0f64, 0.0f64, 10.0f64, e))) ++ "
"
