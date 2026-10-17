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
import ../../src/k1/curve.bend as KU
import ../../src/c07/sol.bend as SO
import ../../src/c01/types.bend as V

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

def boxp(+x: F64, +y: F64, +z: F64, +e: X.Env, +nd: U64) -> M.Body:
  P.unnr(M.op_prism([M.rect_rg(M.xk(x), M.xk(y))], M.xk(0.0f64), M.xk(z), e, nd))

def ga() -> List<&2, Nat>:
  [0n, 2n, 4n]

def gb2() -> List<&2, Nat>:
  [1n, 3n, 5n]

def gall() -> List<&2, Nat>:
  [0n, 1n, 2n, 3n, 4n, 5n]

def g01() -> List<&2, Nat>:
  [0n, 1n]

def smp(+b: Ty.Brep, +f: Nat) -> V.Point:
  +fa = KU.nth_fa0(Ty.brep_fas(b), f)
  +hl = P.f0h(Ty.fa_loops(fa))
  +lp = KU.nth_lp0(Ty.brep_lps(b), Ty.hlp_idx(hl))
  +hc = P.first_hce(Ty.lp_ces(lp))
  +ce = KU.nth_ce0(Ty.brep_ces(b), Ty.hc_idx(hc))
  +ed = KU.nth_ed0(Ty.brep_es(b), Ty.he_idx(Ty.ce_edge(ce)))
  Ty.vx_p(KU.nth_vx0(Ty.brep_vs(b), Ty.hv_idx(Ty.ed_v0(ed))))

def pshow(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

def cl(+fs: List<&2, SO.Fd>, +inc: List<&2, Nat>, +p: V.Point) -> String:
  +of = K1.comp_fds(fs, inc)
  U64.show(SO.classify_in(of, SO.bbox(of, []), p))

def fsmp(fs: List<&2, Nat>, +b: Ty.Brep, +fds: List<&2, SO.Fd>) -> String:
  match fs:
    case []: ""
    case +h <> +t:
      +p = smp(b, h)
      "
f" ++ Nat.show(h) ++ " " ++ pshow(p) ++ " vsA=" ++ cl(fds, ga(), p) ++ " vsB=" ++ cl(fds, gb2(), p) ++ fsmp(t, b, fds)

def main() -> String:
  +e = X.env_mk([])
  +b1 = B8.bake_of(M.bool_in(P.box10(e, 1u64)))
  +b3 = B8.bake_of(M.bool_in(P.moved(P.zcyl(1.5f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 2u64)))
  +a3 = K1.kr_brep(GB.gbrun(B8.tag_diff(), b1, b3))
  +r = K1.kr_brep(GB.gbrun(B8.tag_inter(), a3, port(1.0f64, 0.0f64, 0.0f64, 10.0f64, e)))
  +fds = SO.fds_of(r)
  "xinter" ++ fsmp(g01(), r, fds) ++ "
mid8 " ++ cl(fds, ga(), V.Pt{8.0f64, 5.0f64, 5.0f64}) ++ " " ++ cl(fds, gb2(), V.Pt{8.0f64, 5.0f64, 5.0f64}) ++ "
"
