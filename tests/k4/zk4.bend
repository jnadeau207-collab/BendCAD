import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c06/build.bend as BD
import ../../src/c03/bsp.bend as Q
import ../../src/c16/skin.bend as SK
import ../../src/k1/sf.bend as S
import ../../src/k1/fb.bend as FB
import ../../src/k1/px.bend as PX
import ../../src/k1/co.bend as CO
import ../../src/k1/gw.bend as W
import ../../src/k1/gb.bend as GB
import ../../src/k1/ss.bend as SS

def fr_z(+z: F64) -> SK.Fr:
  SK.Fr{V.Pt{0.0f64, 0.0f64, z}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}, 1.0f64}

def circ_go(n: Nat, +k: Nat, +m: Nat, +r: F64) -> List<&2, V.Vec2>:
  match n:
    case 0n: []
    case 1n+(+j):
      +t = F64.mul(S.two_pi(), F64.div(Q.nf(k), Q.nf(m)))
      V.V2{F64.mul(r, S.fcos(t)), F64.mul(r, S.fsin(t))} <> circ_go(j, Nat.add(k, 1n), m, r)

def csec(+z: F64) -> SK.Sc:
  SK.Sc{([circ_go(37n, 0n, 36n, 10.0f64)]), fr_z(z)}

def sq() -> List<&2, List<&2, V.Vec2>>:
  +a = {V.V2{F64.neg(15.0f64), F64.neg(15.0f64)} : V.Vec2}
  +b = {V.V2{15.0f64, F64.neg(15.0f64)} : V.Vec2}
  +c = {V.V2{15.0f64, 15.0f64} : V.Vec2}
  +d = {V.V2{F64.neg(15.0f64), 15.0f64} : V.Vec2}
  [[a, b], [b, c], [c, d], [d, a]]

def ssec(+z: F64) -> SK.Sc:
  SK.Sc{(sq()), fr_z(z)}

def bt_b(bt: BD.Bt) -> Ty.Brep:
  BD.Bt{+b, fns} = bt
  b

def brep(+cs: List<&2, SK.Sc>) -> Ty.Brep:
  bt_b(SK.skr_bt(SK.sk_run(cs, 1u64)))

def v2s(+q: V.Vec2) -> String:
  "(" ++ F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q)) ++ ")"

def lastv(xs: List<&2, V.Vec2>, +d: V.Vec2) -> V.Vec2:
  match xs:
    case []: d
    case +h <> t: lastv(t, h)

def firstv(xs: List<&2, V.Vec2>) -> V.Vec2:
  match xs:
    case []: V.V2{0.0f64, 0.0f64}
    case +h <> t: h

def pcs_s(ps: List<&2, W.PC>) -> String:
  match ps:
    case []: ""
    case +p <> t:
      +pl = W.pc_poly(p)
      " [" ++ Nat.show(W.pc_va(p)) ++ "->" ++ Nat.show(W.pc_vb(p)) ++ (Bool.pick(String, W.pc_bnd(p), " B ", " C ")) ++ Nat.show(List.length(&2, V.Vec2, pl)) ++ " " ++ v2s(firstv(pl)) ++ v2s(lastv(pl, firstv(pl))) ++ "]" ++ pcs_s(t)

def hxs(hs: List<&2, PX.HX>, +w: S.SF) -> String:
  match hs:
    case []: ""
    case +h <> t:
      +q = S.sf_uv(w, PX.hx_p(h))
      " h" ++ Nat.show(PX.hx_v(h)) ++ v2s(q) ++ hxs(t, w)

def ptl(ps: List<&2, V.Point>, +w: S.SF) -> String:
  match ps:
    case []: ""
    case +p <> t: v2s(S.sf_uv(w, p)) ++ ptl(t, w)

def icl(cs: List<&2, SS.IC>, +w: S.SF) -> String:
  match cs:
    case []: ""
    case +c <> t: " IC closed=" ++ (Bool.pick(String, SS.ic_closed(c), "y", "n")) ++ ptl(SS.ic_pts(c), w) ++ icl(t, w)

def dbg(+ba: FB.KB, +bb: FB.KB, +hs: List<&2, PX.HX>) -> String:
  +w = FB.face_sf(ba, 0n)
  +ph = PX.pair_hits(hs, PX.face_es(ba, 0n), 0n, PX.face_es(bb, 5n), 5n)
  +ic = SS.ssi(FB.face_surf(ba, 0n), FB.face_surf(bb, 5n))
  "pair hits:" ++ hxs(ph, w) ++ "
" ++ icl(SS.ics_ics(ic), w)

def main() -> IO(Unit):
  +ra = brep([csec(0.0f64), csec(20.0f64)])
  +rb = brep([ssec(F64.neg(5.0f64)), ssec(5.0f64)])
  +ba = FB.kb_of(ra)
  +bb = FB.kb_of(rb)
  +va = PX.add_vs(Ty.brep_vs(ra), PX.GV{[], 0n}, [])
  +vb = PX.add_vs(Ty.brep_vs(rb), PX.vm_g(va), [])
  +hs = PX.all_hits(ba, bb, PX.vm_g(vb))
  +cps = CO.coin_pairs(ba, bb)
  +hs2 = PX.hs_hs(hs)
  +cr = PX.all_chains(hs2, ba, bb, PX.hs_g(hs))
  +hs3 = PX.chain_hits(PX.cr_chs(cr), ba, bb, PX.cr_g(cr), hs2)
  +dg = dbg(ba, bb, hs2)
  +pcs = GB.face_pcs(ba, 0n, 0u64, PX.vm_mp(va), hs3, PX.cr_chs(cr), cps, bb, PX.vm_mp(vb), PX.cr_g(cr))
  +cs = W.face_cycles(FB.face_sf(ba, 0n), pcs)
  IO.print("hits " ++ Nat.show(List.length(&2, PX.HX, hs2)) ++ " hs_ok " ++ (Bool.pick(String, PX.hs_ok(hs), "y", "n")) ++ " cr_ok " ++ (Bool.pick(String, PX.cr_ok(cr), "y", "n")) ++ " why " ++ U64.show(PX.cr_why(cr)) ++ " chains " ++ Nat.show(List.length(&2, PX.CH, PX.cr_chs(cr))) ++ " cyc_ok " ++ (Bool.pick(String, W.cs_ok(cs), "y", "n")) ++ "\n" ++ pcs_s(pcs) ++ dg)
