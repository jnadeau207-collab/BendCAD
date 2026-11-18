import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c06/iv.bend as I
import ../../src/k1/gb.bend as GB
import ../../src/c07/ivx.bend as X
import ../../src/c04/ops.bend as C4
import ../../src/c03/types.bend as G
import ../../src/k1/px.bend as PX
import ../../src/k1/ef.bend as EF
import ../../src/k1/co.bend as CO
import ../../src/k1/gw.bend as W
import ../../src/k1/fb.bend as FB
import ../../src/k1/sf.bend as SF
import ../../src/k1/ls.bend as L
import ../../src/c07/sol.bend as SO
import ../../src/c04/types.bend as Ty
import ../../src/c01/types.bend as V
import ../../src/k1/asm.bend as K1
import ../../src/c08/bool.bend as B8
import ../../src/base/par.bend as B

law read_go:
  for m: File & Result<&1, &1, (U32 & String), String>
  IO(String)

def read_go(m):
  (f, r) = m
  do IO<String>:
    data : String <- IO.pass(String, r)
    x : Unit <- File.close(f)
    return data

law size_go:
  for m: File & Result<&1, &1, (U32 & String), U32>
  IO(String)

def size_go(m):
  (f, r) = m
  do IO<String>:
    n : U32 <- IO.pass(U32, r)
    d : File & Result<&1, &1, (U32 & String), String> <- File.read(f, U32.add(n, 1))
    read_go(d)

law read_file:
  for path: String
  IO(String)

def read_file(path):
  do IO<String>:
    f : File <- IO.try(File, File.open(path, "r"))
    m : File & Result<&1, &1, (U32 & String), U32> <- File.size(f)
    size_go(m)

def rg_dbg(rs: List<&2, W.RG>, +s: SF.SF, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>, +sd: U64, +pcp: List<&2, CO.CP>, +ob: FB.KB) -> String:
  match rs:
    case []: ""
    case +h <> +t:
      +sp = W.sample_pt(s, h)
      +p = SF.sf_at(s, V.v2_x(W.sp_q(sp)), V.v2_y(W.sp_q(sp)))
      +oc = CO.on_code(pcp, sd, ob, p)
      +c = Bool.pick(U64, U64.is_eq(oc, 0u64), SO.classify_in(fdo, bbo, p), oc)
      "    rg sp_ok=" ++ Bool.pick(String, W.sp_ok(sp), "1", "0") ++ " p=(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++
        ") oc=" ++ U64.show(oc) ++ " c=" ++ U64.show(c) ++ "
" ++ rg_dbg(t, s, fdo, bbo, sd, pcp, ob)

def v2_s(+q: V.Vec2) -> String:
  "(" ++ F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q)) ++ ")"

def first_v2(ps: List<&2, V.Vec2>, +d: V.Vec2) -> V.Vec2:
  match ps:
    case []: d
    case +h <> +t: h

def last_v2(ps: List<&2, V.Vec2>, +d: V.Vec2) -> V.Vec2:
  match ps:
    case []: d
    case +h <> +t: last_v2(t, h)

def pc_s(pcs: List<&2, W.PC>) -> String:
  match pcs:
    case []: ""
    case +p <> +t:
      W.PC{+va, +vb, +poly, +bnd, ers, dv} = p
      +z = {V.V2{0.0f64, 0.0f64} : V.Vec2}
      "      pc " ++ Nat.show(va) ++ "->" ++ Nat.show(vb) ++ Bool.pick(String, bnd, " bnd", " cut") ++ " n=" ++ Nat.show(List.length(&2, V.Vec2, poly)) ++
        " a=" ++ v2_s(first_v2(poly, z)) ++ " b=" ++ v2_s(last_v2(poly, z)) ++ "
" ++ pc_s(t)

def faces_dbg(fs: List<&2, Nat>, +b: FB.KB, +sd: U64, +vmap: List<&2, Nat>, +hs: List<&2, PX.HX>, +chs: List<&2, PX.CH>, +fdo: List<&2, SO.Fd>,
    +bbo: List<&2, I.I>, +cps: List<&2, CO.CP>, +ob: FB.KB, +vmo: List<&2, Nat>, +gv: PX.GV) -> String:
  match fs:
    case []: ""
    case +fi <> +t:
      +s = FB.face_sf(b, fi)
      +pcs = GB.face_pcs(b, fi, sd, vmap, hs, chs, cps, ob, vmo, gv)
      +cs = W.face_cycles(s, pcs)
      +rs = W.regions(s, W.cs_cys(cs))
      "side " ++ U64.show(sd) ++ " face " ++ Nat.show(fi) ++ " cs_ok=" ++ Bool.pick(String, W.cs_ok(cs), "1", "0") ++ " rs_ok=" ++ Bool.pick(String, W.rs_ok(rs), "1", "0") ++
        " nrg=" ++ Nat.show(List.length(&2, W.RG, W.rs_rgs(rs))) ++ "
" ++ Bool.pick(String, W.cs_ok(cs), "", pc_s(pcs)) ++ rg_dbg(W.rs_rgs(rs), s, fdo, bbo, sd, CO.partner_of(cps, sd, fi), ob) ++
        faces_dbg(t, b, sd, vmap, hs, chs, fdo, bbo, cps, ob, vmo, gv)

def segs_s(ss: List<&2, PX.SEG>) -> String:
  match ss:
    case []: ""
    case +h <> +t: " " ++ Nat.show(PX.seg_va(h)) ++ "-" ++ Nat.show(PX.seg_vb(h)) ++ segs_s(t)

def chs_s(cs: List<&2, PX.CH>, +fa: Nat) -> String:
  match cs:
    case []: ""
    case +c <> +t:
      PX.CH{+a, +b, +sg, +ps, +cl, dv} = c
      Bool.pick(String, Nat.is_eq(a, fa), "  ch " ++ Nat.show(a) ++ " " ++ Nat.show(b) ++ " closed " ++ Bool.pick(String, cl, "1", "0") ++ " pts " ++ Nat.show(List.length(&2, V.Point, ps)) ++ " segs" ++ segs_s(sg) ++ "
", "") ++ chs_s(t, fa)

def dbg(+ba: FB.KB, +bb: FB.KB) -> String:
  +va = PX.add_vs(Ty.brep_vs(FB.kb_br(ba)), PX.GV{[], 0n}, [])
  +vb = PX.add_vs(Ty.brep_vs(FB.kb_br(bb)), PX.vm_g(va), [])
  +hs = PX.all_hits(ba, bb, PX.vm_g(vb))
  +cps = CO.coin_pairs(ba, bb)
  +cx0 = CO.crossings(cps, ba, bb, PX.hs_g(hs))
  +tj = CO.tjunctions(cps, ba, bb, CO.cx_g(cx0))
  +cx = {CO.CX{List.append(&2, PX.HX, CO.cx_hs(cx0), CO.cx_hs(tj)), CO.cx_g(tj), Bool.and(CO.cx_ok(cx0), CO.cx_ok(tj))} : CO.CX}
  +hs2 = List.append(&2, PX.HX, PX.hs_hs(hs), CO.cx_hs(cx))
  +cr = PX.all_chains(hs2, ba, bb, CO.cx_g(cx))
  +hs3 = PX.chain_hits(PX.cr_chs(cr), ba, bb, PX.cr_g(cr), hs2)
  +fda = SO.fds_of(FB.kb_br(ba))
  +fdb = SO.fds_of(FB.kb_br(bb))
  +gv = PX.cr_g(cr)
  "hs_ok=" ++ Bool.pick(String, PX.hs_ok(hs), "1", "0") ++ " hs_why=" ++ U64.show(PX.hs_why(hs)) ++ " cr_why=" ++ U64.show(PX.cr_why(cr)) ++ " cx_ok=" ++ Bool.pick(String, CO.cx_ok(cx), "1", "0") ++ " cr_ok=" ++ Bool.pick(String, PX.cr_ok(cr), "1", "0") ++ "
" ++ chs_s(PX.cr_chs(cr), 18n) ++
    faces_dbg(L.nat_range(FB.nfaces(ba)), ba, 0u64, PX.vm_mp(va), hs3, PX.cr_chs(cr), fdb, SO.bbox(fdb, []), cps, bb, PX.vm_mp(vb), gv) ++
    faces_dbg(L.nat_range(FB.nfaces(bb)), bb, 1u64, PX.vm_mp(vb), hs3, PX.cr_chs(cr), fda, SO.bbox(fda, []), cps, ba, PX.vm_mp(va), gv)

def placed(+cs: List<&2, M.CE>, +id: U64) -> Ty.Brep:
  +b = M.nr_body(M.ce_r(M.ce_find(cs, id)))
  +pl = M.bd_pl(b)
  B8.xf_brep(M.pl_m(pl), M.pl_tx(pl), M.pl_ty(pl), M.pl_tz(pl), M.bd_brep(b))

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +ia = S.u64_of(S.Sx_a{S.arg_at(args, 2n)})
  +ib = S.u64_of(S.Sx_a{S.arg_at(args, 3n)})
  +cs = M.ev_for(p, [ia, ib], [])
  IO.print(dbg(FB.kb_of(placed(cs, ia)), FB.kb_of(placed(cs, ib))))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
