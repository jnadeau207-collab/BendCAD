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
import ../../src/k1/ls.bend as L
import ../../src/c07/xs.bend as XS
import ../../src/c07/mem.bend as Mm
import ../../src/c06/iv.bend as IV
import ../../src/c03/types.bend as G
import ../../src/k1/fb.bend as FB
import ../../src/c06/prof.bend as F
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

def tool_rg() -> F.Region:
  M.path_rg(M.xk(0.0f64), M.xk(5.0f64), [F.S_line{M.xk(1.0f64), M.xk(5.0f64)}, F.S_line{M.xk(4.0f64), M.xk(11.0f64)}, F.S_line{M.xk(0.0f64), M.xk(11.0f64)}])

def p3s(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

def gks(g: G.GVal) -> String:
  match g:
    case G.GV_ln{w}: "ln"
    case G.GV_cc{w}:
      G.Cc{+o, e1, e2, +r} = w
      "cc o=" ++ p3s(o) ++ " r=" ++ F64.show(r)
    case G.GV_rq{w}: "rq"
    case G.GV_bz{w}: "bz"
    case _: "other"

def eks(+k: Ty.EdgeKind) -> String:
  match k:
    case Ty.EK_curve{c, d}: gks(c) ++ " dom=[" ++ F64.show(G.dom_lo(d)) ++ "," ++ F64.show(G.dom_hi(d)) ++ "]"
    case Ty.EK_degenerate{}: "degen"

def edump(es: List<&2, Ty.Edge>, +b: Ty.Brep, +i: Nat) -> String:
  match es:
    case []: ""
    case +e <> +t: "
 e" ++ Nat.show(i) ++ " " ++ eks(Ty.ed_kind(e)) ++ " " ++ p3s(FB.vpt(b, Ty.ed_v0(e))) ++ "->" ++ p3s(FB.vpt(b, Ty.ed_v1(e))) ++ edump(t, b, Nat.add(i, 1n))

def fdord(fs: List<&2, SO.Fd>, +i: Nat) -> String:
  match fs:
    case []: ""
    case +f <> +t: " " ++ Nat.show(i) ++ ":f" ++ Nat.show(SO.fd_fi(f)) ++ "k" ++ U64.show(KU.surfkind(SO.fd_g(f))) ++ fdord(t, Nat.add(i, 1n))

def ivs(xs: List<&2, I.I>) -> String:
  match xs:
    case []: ""
    case +x <> +t: "[" ++ F64.show(I.i_lo(x)) ++ "," ++ F64.show(I.i_hi(x)) ++ "]" ++ ivs(t)

def hshow(hs: List<&2, XS.Hit>, +fd: SO.Fd) -> String:
  match hs:
    case []: ""
    case +h <> +t:
      match h:
        case XS.H_pt{s, tt, +p, c}: "
  pt " ++ ivs(p) ++ " m=" ++ U64.show(Mm.member(SO.fd_fc(fd), p, SO.fd_im(fd))) ++ hshow(t, fd)
        case XS.H_un{s, tt, +p}: "
  un " ++ ivs(p) ++ " m=" ++ U64.show(Mm.member(SO.fd_fc(fd), p, SO.fd_im(fd))) ++ hshow(t, fd)
        case XS.H_ov{s, tt}: "
  ov s=" ++ ivs([s]) ++ hshow(t, fd)
        case XS.H_no{w}: "
  no " ++ w ++ hshow(t, fd)

def nthfd(fs: List<&2, SO.Fd>, +i: Nat) -> SO.Fd:
  match fs:
    case []: SO.fd_dflt()
    case +f <> +t:
      match i:
        case 0n: f
        case 1n+j: nthfd(t, j)

def ekc(+k: Ty.EdgeKind) -> G.GVal:
  match k:
    case Ty.EK_curve{c, d}: c
    case Ty.EK_degenerate{}: Ty.surf_zero()

def ekd(+k: Ty.EdgeKind) -> G.Dom:
  match k:
    case Ty.EK_curve{c, d}: d
    case Ty.EK_degenerate{}: G.Dom{0.0f64, 1.0f64}

def hitdbg(+b: Ty.Brep) -> String:
  +e = L.nth_e(Ty.brep_es(b), 12n)
  +fd = nthfd(SO.fds_of(b), 1n)
  "
hits:" ++ hshow(XS.inter_cs(ekc(Ty.ed_kind(e)), ekd(Ty.ed_kind(e)), SO.fd_g(fd), 40n), fd)

def main() -> String:
  +e = X.env_mk([])
  +b1 = B8.bake_of(M.bool_in(P.box10(e, 1u64)))
  +tl = B8.bake_of(M.bool_in(P.moved(P.unnr(M.op_rev([tool_rg()], e, 2u64)), 5.0f64, 5.0f64, 0.0f64, e, 3u64)))
  +bo = B8.bake_of(M.bool_in(P.moved(P.zcyl(1.5f64, F64.neg(5.0f64), 15.0f64, e, 4u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)))
  +d = GB.gbrun(B8.tag_diff(), b1, tl)
  "cone diff " ++ kshow(d) ++ "
cone union " ++ kshow(GB.gbrun(B8.tag_union(), b1, tl)) ++ "
cone inter " ++ kshow(GB.gbrun(B8.tag_inter(), b1, tl)) ++
  "
cs+bore " ++ kshow(GB.gbrun(B8.tag_diff(), K1.kr_brep(d), bo)) ++ hitdbg(K1.kr_brep(GB.gbrun(B8.tag_diff(), K1.kr_brep(d), bo))) ++ "
"
