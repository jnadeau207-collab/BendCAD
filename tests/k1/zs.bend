import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c06/model.bend as M
import ../../src/c06/xp.bend as X
import ../../src/c06/iv.bend as I
import ../../src/c06/prof.bend as F
import ../../src/c08/bool.bend as B8
import ../../src/k1/asm.bend as K1
import ../../src/k1/gb.bend as GB
import ../../src/k1/px.bend as PX
import ../../src/k1/gw.bend as W
import ../../src/k1/co.bend as CO
import ../../src/k1/ls.bend as L
import ../../src/k1/vi.bend as VI
import ../../src/k1/fb.bend as FB
import ../../src/k1/sf.bend as S
import ../../src/k1/ef.bend as EF
import ../../src/c07/sol.bend as SO
import ../../src/c03/types.bend as G

def unnr(+r: M.NR) -> M.Body:
  match r:
    case M.NR_ok{+b, fx}: b
    case M.NR_err{k, d}: M.Bd{[], Ty.Br{[], [], [], [], [], [], [], Ty.Cp{[], []}, 0u64}, [], M.pl_id(), [], M.xb_id()}

def boxp(+x: F64, +y: F64, +z: F64, +e: X.Env, +nd: U64) -> M.Body:
  unnr(M.op_prism([M.rect_rg(M.xk(x), M.xk(y))], M.xk(0.0f64), M.xk(z), e, nd))

def moved(+b: M.Body, +x: F64, +y: F64, +z: F64, +e: X.Env, +nd: U64) -> M.Body:
  unnr(M.op_move(b, M.xk(x), M.xk(y), M.xk(z), 0u64, e, nd))

def gk(g: G.GVal) -> String:
  match g:
    case G.GV_pl{w}: "pl"
    case G.GV_cy{w}: "cy"
    case G.GV_bp{w}: "bp"
    case G.GV_co{w}: "co"
    case G.GV_sp{w}: "sp"
    case _: "?"


def fkinds(fs: List<&2, Ty.Face>, +i: Nat) -> String:
  match fs:
    case []: ""
    case +h <> +t: " f" ++ Nat.show(i) ++ "=" ++ gk(Ty.fa_surf(h)) ++ fkinds(t, Nat.add(i, 1n))

def vshow(+r: K1.KR) -> String:
  +b = K1.kr_brep(r)
  +vc = B8.vcore(b)
  +v = VI.brep_vol(b)
  Bool.pick(String, K1.kr_ok(r), "ok", "FAIL" ++ U64.show(K1.kr_why(r))) ++ " nv" ++ Nat.show(K1.kr_nv(r)) ++ " nf" ++ Nat.show(K1.kr_nf(r)) ++ " " ++ Bool.pick(String, B8.VR_ok(vc), "valid", B8.vcode(vc)) ++ fkinds(Ty.brep_fas(b), 0n) ++ " vol=[" ++ F64.show(I.i_lo(VI.vr_vol(v))) ++ "," ++ F64.show(I.i_hi(VI.vr_vol(v))) ++ "]"

def zcyl(+r: F64, +z0: F64, +z1: F64, +e: X.Env, +nd: U64) -> M.Body:
  unnr(M.op_prism([F.Rg{F.L_circ{M.xk(10.0f64), M.xk(10.0f64), M.xk(r)}, []}], M.xk(z0), M.xk(z1), e, nd))

def ccyl(+r: F64, +z0: F64, +z1: F64, +e: X.Env, +nd: U64) -> M.Body:
  unnr(M.op_prism([F.Rg{F.L_circ{M.xk(0.0f64), M.xk(0.0f64), M.xk(r)}, []}], M.xk(z0), M.xk(z1), e, nd))

def hex_rg() -> F.Region:
  M.path_rg(M.xk(2.3094010767585034f64), M.xk(0.0f64), [F.S_line{M.xk(1.154700538379252f64), M.xk(2.0f64)}, F.S_line{M.xk(F64.neg(1.1547005383792512f64)), M.xk(2.0000000000000004f64)}, F.S_line{M.xk(F64.neg(2.3094010767585034f64)), M.xk(2.828200636599752e-16f64)}, F.S_line{M.xk(F64.neg(1.1547005383792528f64)), M.xk(F64.neg(2.0f64))}, F.S_line{M.xk(1.154700538379252f64), M.xk(F64.neg(2.0f64))}])

def ord(fs: List<&2, SO.Fd>, +i: Nat) -> String:
  match fs:
    case []: ""
    case +f <> +t: " " ++ Nat.show(i) ++ ":f" ++ Nat.show(SO.fd_fi(f)) ++ gk(SO.fd_g(f)) ++ ord(t, Nat.add(i, 1n))

def nrshow(r: M.NR) -> String:
  match r:
    case M.NR_ok{+b, fx}: vshow(K1.KR{True{}, 0u64, M.bd_brep(b), 0n, 0n, 0n, 0n})
    case M.NR_err{k, d}:
      M.Dg{w, l, y, f} = d
      "ERR " ++ w ++ " " ++ y

def id3() -> V.Mat3:
  V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64}

def sph(+r: F64, +x: F64, +y: F64, +z: F64, +e: X.Env, +nd: U64) -> Ty.Brep:
  B8.xf_brep(id3(), x, y, z, M.bd_brep(unnr(M.op_rev([M.sph_rg(M.xk(r))], e, nd))))

def run3(+tag: String, +ba: Ty.Brep, +bb: Ty.Brep) -> String:
  tag ++ " union " ++ vshow(GB.gbrun(14u64, ba, bb)) ++ "
" ++ tag ++ " diff " ++ vshow(GB.gbrun(15u64, ba, bb)) ++ "
" ++ tag ++ " inter " ++ vshow(GB.gbrun(16u64, ba, bb)) ++ "
"

def pshow(+p: V.Point) -> String:
  "(" ++ F64.show(S.px(p)) ++ "," ++ F64.show(S.py(p)) ++ "," ++ F64.show(S.pz(p)) ++ ")"

def uses(cs: List<&2, Ty.Coedge>, +i: Nat, +f: Nat, +b: Nat) -> String:
  match cs:
    case []: Nat.show(f) ++ "/" ++ Nat.show(b)
    case +h <> +t:
      +m = Nat.is_eq(Ty.he_idx(Ty.ce_edge(h)), i)
      uses(t, i, Bool.pick(Nat, Bool.and(m, Ty.ce_fwd(h)), Nat.add(f, 1n), f), Bool.pick(Nat, Bool.and(m, Bool.not(Ty.ce_fwd(h))), Nat.add(b, 1n), b))

def edbg(es: List<&2, Ty.Edge>, +i: Nat, +cs: List<&2, Ty.Coedge>, +gv: PX.GV) -> String:
  match es:
    case []: ""
    case +h <> +t:
      +k = Ty.ed_kind(h)
      +u = uses(cs, i, 0n, 0n)
      +bad = Bool.not(String.eq(u, "1/1"))
      Bool.pick(String, bad, " E" ++ Nat.show(i) ++ " v" ++ Nat.show(Ty.hv_idx(Ty.ed_v0(h))) ++ pshow(PX.gv_pt(gv, Ty.hv_idx(Ty.ed_v0(h)))) ++ "-v" ++ Nat.show(Ty.hv_idx(Ty.ed_v1(h))) ++ pshow(PX.gv_pt(gv, Ty.hv_idx(Ty.ed_v1(h)))) ++ " tag" ++ U64.show(VI.ek_tag(k)) ++ " mid" ++ pshow(EF.ev(EF.ek_curve(k), F64.mul(0.5f64, F64.add(EF.ek_lo(k), EF.ek_hi(k))))) ++ " use " ++ u ++ "
", "") ++ edbg(t, Nat.add(i, 1n), cs, gv)

def hxdbg(hs: List<&2, PX.HX>) -> String:
  match hs:
    case []: ""
    case +h <> +t: " hx s" ++ U64.show(PX.hx_side(h)) ++ " e" ++ Nat.show(PX.hx_e(h)) ++ " t" ++ F64.show(PX.hx_t(h)) ++ " v" ++ Nat.show(PX.hx_v(h)) ++ " fo" ++ Nat.show(PX.hx_fo(h)) ++ pshow(PX.hx_p(h)) ++ "
" ++ hxdbg(t)

def chdbg(cs: List<&2, PX.CH>) -> String:
  match cs:
    case []: ""
    case +h <> +t: " ch fa" ++ Nat.show(PX.ch_fa(h)) ++ " fb" ++ Nat.show(PX.ch_fb(h)) ++ " nseg" ++ Nat.show(List.length(&2, PX.SEG, PX.ch_segs(h))) ++ " closed" ++ Bool.pick(String, PX.ch_closed(h), "1", "0") ++ "
" ++ chdbg(t)

def v2s(+q: V.Vec2) -> String:
  "(" ++ F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q)) ++ ")"

def pcdbg(ps: List<&2, W.PC>) -> String:
  match ps:
    case []: ""
    case +h <> +t:
      +pl = W.pc_poly(h)
      "   pc v" ++ Nat.show(W.pc_va(h)) ++ "->v" ++ Nat.show(W.pc_vb(h)) ++ " n" ++ Nat.show(List.length(&2, V.Vec2, pl)) ++ " " ++ v2s(L.nth_v2(pl, 0n)) ++ "..." ++ v2s(L.last_v2(pl, V.V2{0.0f64, 0.0f64})) ++ " bnd" ++ Bool.pick(String, W.pc_bnd(h), "1", "0") ++ "
" ++ pcdbg(t)

def fpdbg(fs: List<&2, Nat>, +b: Ty.Brep, +sd: U64, +vm: List<&2, Nat>, +hs: List<&2, PX.HX>, +chs: List<&2, PX.CH>, +cps: List<&2, CO.CP>, +ob: Ty.Brep, +vmo: List<&2, Nat>, +g: PX.GV) -> String:
  match fs:
    case []: ""
    case +h <> +t: "  face s" ++ U64.show(sd) ++ " f" ++ Nat.show(h) ++ "
" ++ pcdbg(GB.face_pcs(b, h, sd, vm, hs, chs, cps, ob, vmo, g)) ++ fpdbg(t, b, sd, vm, hs, chs, cps, ob, vmo, g)

def gdbg(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +va = PX.add_vs(Ty.brep_vs(ba), PX.GV{[], 0n}, [])
  +vb = PX.add_vs(Ty.brep_vs(bb), PX.vm_g(va), [])
  +hs = PX.all_hits(ba, bb, PX.vm_g(vb))
  +cps = CO.coin_pairs(ba, bb)
  +cx0 = CO.crossings(cps, ba, bb, PX.hs_g(hs))
  +tj = CO.tjunctions(cps, ba, bb, CO.cx_g(cx0))
  +cx = {CO.CX{List.append(&2, PX.HX, CO.cx_hs(cx0), CO.cx_hs(tj)), CO.cx_g(tj), Bool.and(CO.cx_ok(cx0), CO.cx_ok(tj))} : CO.CX}
  +hs2 = List.append(&2, PX.HX, PX.hs_hs(hs), CO.cx_hs(cx))
  +cr = PX.all_chains(hs2, ba, bb, CO.cx_g(cx))
  +m = GB.run_emit(op, ba, bb, PX.vm_mp(va), PX.vm_mp(vb), PX.chain_hits(PX.cr_chs(cr), ba, bb, PX.cr_g(cr), hs2), PX.cr_chs(cr), PX.cr_g(cr), cps)
  +st = GB.em_st(m)
  +h3 = PX.chain_hits(PX.cr_chs(cr), ba, bb, PX.cr_g(cr), hs2)
  fpdbg(L.nat_range(FB.nfaces(ba)), ba, 0u64, PX.vm_mp(va), h3, PX.cr_chs(cr), cps, bb, PX.vm_mp(vb), PX.cr_g(cr)) ++ fpdbg(L.nat_range(FB.nfaces(bb)), bb, 1u64, PX.vm_mp(vb), h3, PX.cr_chs(cr), cps, ba, PX.vm_mp(va), PX.cr_g(cr)) ++ chdbg(PX.cr_chs(cr)) ++ "hits=" ++ Nat.show(List.length(&2, PX.HX, hs2)) ++ " chains=" ++ Nat.show(List.length(&2, PX.CH, PX.cr_chs(cr))) ++ " emok=" ++ Bool.pick(String, GB.em_ok(m), "1", "0") ++ " why=" ++ U64.show(GB.em_why(m)) ++ "
" ++ edbg(List.reverse(&2, Ty.Edge, K1.as_es(st)), 0n, K1.as_ces(st), PX.cr_g(cr))

def bdump(es: List<&2, Nat>, +b: Ty.Brep) -> String:
  match es:
    case []: ""
    case +i <> +t:
      +h = FB.edge_at(b, i)
      +k = Ty.ed_kind(h)
      " e" ++ Nat.show(i) ++ " " ++ pshow(FB.vpt(b, Ty.ed_v0(h))) ++ "-" ++ pshow(FB.vpt(b, Ty.ed_v1(h))) ++ " tag" ++ U64.show(VI.ek_tag(k)) ++ " lo" ++ F64.show(EF.ek_lo(k)) ++ " hi" ++ F64.show(EF.ek_hi(k)) ++ " mid" ++ pshow(EF.ev(EF.ek_curve(k), F64.mul(0.5f64, F64.add(EF.ek_lo(k), EF.ek_hi(k))))) ++ " faces" ++ Nat.show(List.length(&2, Nat, FB.edge_faces(b, i))) ++ "
" ++ bdump(t, b)

def main() -> String:
  +e = X.env_mk([])
  +bx = M.bd_brep(boxp(10.0f64, 10.0f64, 10.0f64, e, 1u64))
  +s1 = sph(4.0f64, 5.0f64, 5.0f64, 9.0f64, e, 2u64)
  +s2 = sph(5.0f64, 0.0f64, 0.0f64, 0.0f64, e, 3u64)
  +cy = M.bd_brep(unnr(M.op_prism([F.Rg{F.L_circ{M.xk(1.5f64), M.xk(0.5f64), M.xk(2.0f64)}, []}], M.xk(F64.neg(8.0f64)), M.xk(8.0f64), e, 4u64)))
  +s3 = sph(3.0f64, 0.0f64, 0.0f64, 4.5f64, e, 5u64)
  +s4 = sph(3.0f64, 0.0f64, 0.3f64, 4.5f64, e, 6u64)
  +sh = M.bd_brep(unnr(M.op_prism([F.Rg{F.L_circ{M.xk(0.0f64), M.xk(0.0f64), M.xk(3.0f64)}, []}], M.xk(0.0f64), M.xk(10.0f64), e, 7u64)))
  bdump(L.nat_range(FB.nedges(sh)), sh) ++ gdbg(14u64, sh, sph(3.0f64, 0.0f64, 0.0f64, 10.0f64, e, 8u64)) ++ run3("ball", sh, sph(3.0f64, 0.0f64, 0.0f64, 10.0f64, e, 8u64)) ++ run3("corner", bx, sph(6.0f64, 0.0f64, 0.0f64, 0.0f64, e, 9u64)) ++ run3("ss", s2, s3) ++ run3("ssy", s2, s4) ++ run3("dimple", bx, s1) ++ run3("bore", s2, cy)
