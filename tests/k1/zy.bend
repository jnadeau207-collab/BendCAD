import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c06/model.bend as M
import ../../src/c06/xp.bend as X
import ../../src/c08/bool.bend as B8
import ../../src/k1/sf.bend as S
import ../../src/k1/fb.bend as FB
import ../../src/k1/px.bend as PX
import ../../src/k1/gw.bend as W
import ../../src/k1/gb.bend as GB
import ../../src/k1/co.bend as CO
import ../../src/k1/surg.bend as K1
import ./probe.bend as P
import ../../src/c06/prof.bend as F
import ../../src/c07/sol.bend as SO
import ../../src/c06/iv.bend as I

def cyshow(cs: List<&2, W.CY>) -> String:
  match cs:
    case []: ""
    case +h <> +t: " [w" ++ F64.show(W.cy_wind(h)) ++ " a" ++ F64.show(W.cy_area(h)) ++ " n" ++ Nat.show(List.length(&2, W.HE, W.cy_hes(h))) ++ "]" ++ cyshow(t)

def pcshow(ps: List<&2, W.PC>) -> String:
  match ps:
    case []: ""
    case +h <> +t: " (" ++ Nat.show(W.pc_va(h)) ++ ">" ++ Nat.show(W.pc_vb(h)) ++ Bool.pick(String, W.pc_bnd(h), "b", "c") ++ " np" ++ Nat.show(List.length(&2, V.Vec2, W.pc_poly(h))) ++ " ne" ++ Nat.show(List.length(&2, W.ER, W.pc_ers(h))) ++ ")" ++ pcshow(t)

def chshow(cs: List<&2, PX.CH>) -> String:
  match cs:
    case []: ""
    case +h <> +t: " {fa" ++ Nat.show(PX.ch_fa(h)) ++ " fb" ++ Nat.show(PX.ch_fb(h)) ++ " segs" ++ Nat.show(List.length(&2, PX.SEG, PX.ch_segs(h))) ++ " pts" ++ Nat.show(List.length(&2, V.Point, PX.ch_pts(h))) ++ Bool.pick(String, PX.ch_closed(h), " C", " O") ++ " dv" ++ F64.show(PX.ch_dv(h)) ++ "}" ++ chshow(t)

def faces(fs: List<&2, Nat>, +b: Ty.Brep, +sd: U64, +vm: List<&2, Nat>, +hs: List<&2, PX.HX>, +chs: List<&2, PX.CH>, +cps: List<&2, CO.CP>, +ob: Ty.Brep, +vmo: List<&2, Nat>, +gv: PX.GV) -> String:
  match fs:
    case []: ""
    case +h <> +t:
      +s = S.sf_of(FB.face_surf(b, h))
      +pcs = GB.face_pcs(b, h, sd, vm, hs, chs, cps, ob, vmo, gv)
      +cs = W.face_cycles(s, pcs)
      +rs = W.regions(s, W.cs_cys(cs))
      "\nside" ++ U64.show(sd) ++ " F" ++ Nat.show(h) ++ " k" ++ U64.show(S.sf_kind(s)) ++ pcshow(pcs) ++
        "\n   cyc ok=" ++ Bool.pick(String, W.cs_ok(cs), "T", "F") ++ cyshow(W.cs_cys(cs)) ++ " regions ok=" ++ Bool.pick(String, W.rs_ok(rs), "T", "F") ++
        " n=" ++ Nat.show(List.length(&2, W.RG, W.rs_rgs(rs))) ++ faces(t, b, sd, vm, hs, chs, cps, ob, vmo, gv)

def port(+r: F64, +x: F64, +y: F64, +z: F64, +e: X.Env) -> Ty.Brep:
  +c6 = P.moved(P.zcyl(r, F64.neg(5.0f64), 15.0f64, e, 6u64), 5.0f64, 5.0f64, 0.0f64, e, 6u64)
  +c7 = P.unnr(M.op_rot(c6, 1u64, M.xk(90.0f64), e, 7u64))
  B8.bake_of(M.bool_in(P.moved(c7, x, y, z, e, 8u64)))

def kshow2(ks: List<&2, Bool>) -> String:
  match ks:
    case []: ""
    case +h <> +t: Bool.pick(String, h, "K", "d") ++ kshow2(t)

def spshow(rs: List<&2, W.RG>, +s: S.SF) -> String:
  match rs:
    case []: ""
    case +h <> +t:
      +sp = W.sample_pt(s, h)
      " [" ++ Bool.pick(String, W.sp_ok(sp), "", "NOSP") ++ F64.show(V.v2_x(W.sp_q(sp))) ++ "," ++ F64.show(V.v2_y(W.sp_q(sp))) ++ " band" ++ Bool.pick(String, W.rg_band(h), "T", "F") ++ " ncy" ++ Nat.show(List.length(&2, W.CY, W.rg_cys(h))) ++ "]" ++ spshow(t, s)

def fr_go(fs: List<&2, Nat>, +b: Ty.Brep, +sd: U64, +vm: List<&2, Nat>, +hs: List<&2, PX.HX>, +chs: List<&2, PX.CH>, +cps: List<&2, CO.CP>, +ob: Ty.Brep, +vmo: List<&2, Nat>, +gv: PX.GV, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>) -> String:
  match fs:
    case []: ""
    case +h <> +t:
      +fr = GB.face_run(b, h, sd, vm, hs, chs, fdo, bbo, 15u64, cps, ob, vmo, gv)
      "
side" ++ U64.show(sd) ++ " F" ++ Nat.show(h) ++ " keep=" ++ kshow2(GB.fr_keep(fr)) ++ spshow(GB.fr_rgs(fr), S.sf_of(FB.face_surf(b, h))) ++ fr_go(t, b, sd, vm, hs, chs, cps, ob, vmo, gv, fdo, bbo)

def tool_rg() -> F.Region:
  M.path_rg(M.xk(0.0f64), M.xk(5.0f64), [F.S_line{M.xk(1.0f64), M.xk(5.0f64)}, F.S_line{M.xk(4.0f64), M.xk(11.0f64)}, F.S_line{M.xk(0.0f64), M.xk(11.0f64)}])

def main() -> String:
  +e = X.env_mk([])
  +b1 = B8.bake_of(M.bool_in(P.box10(e, 1u64)))
  +tl = B8.bake_of(M.bool_in(P.moved(P.unnr(M.op_rev([tool_rg()], e, 2u64)), 5.0f64, 5.0f64, 0.0f64, e, 3u64)))
  +bb = B8.bake_of(M.bool_in(P.moved(P.zcyl(1.5f64, F64.neg(5.0f64), 15.0f64, e, 4u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)))
  +ba = K1.kr_brep(GB.gbrun(B8.tag_diff(), b1, tl))
  +va = PX.add_vs(Ty.brep_vs(ba), PX.GV{[], 0n}, [])
  +vb = PX.add_vs(Ty.brep_vs(bb), PX.vm_g(va), [])
  +hs = PX.all_hits(ba, bb, PX.vm_g(vb))
  +cps = CO.coin_pairs(ba, bb)
  +cr = PX.all_chains(PX.hs_hs(hs), ba, bb, PX.hs_g(hs))
  "hits ok=" ++ Bool.pick(String, PX.hs_ok(hs), "T", "F") ++ " n=" ++ Nat.show(List.length(&2, PX.HX, PX.hs_hs(hs))) ++ " chains ok=" ++ Bool.pick(String, PX.cr_ok(cr), "T", "F") ++ chshow(PX.cr_chs(cr)) ++
  faces(W.L_rng(FB.nfaces(ba)), ba, 0u64, PX.vm_mp(va), PX.hs_hs(hs), PX.cr_chs(cr), cps, bb, PX.vm_mp(vb), PX.cr_g(cr)) ++
  faces(W.L_rng(FB.nfaces(bb)), bb, 1u64, PX.vm_mp(vb), PX.hs_hs(hs), PX.cr_chs(cr), cps, ba, PX.vm_mp(va), PX.cr_g(cr)) ++ "
"
