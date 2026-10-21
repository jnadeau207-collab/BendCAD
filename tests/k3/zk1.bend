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

def body_of(cs: List<&2, M.CE>, +id: U64) -> M.Body:
  M.nr_body(M.ce_r(M.ce_find(cs, id)))

def kr_s(+r: K1.KR) -> String:
  "k1 ok=" ++ Bool.pick(String, K1.kr_ok(r), "1", "0") ++ " why=" ++ U64.show(K1.kr_why(r)) ++ " nf=" ++ Nat.show(K1.kr_nf(r))

def rg_dbg(rs: List<&2, W.RG>, +s: SF.SF, +fdo: List<&2, SO.Fd>, +bbo: List<&2, I.I>, +sd: U64, +pcp: List<&2, CO.CP>, +ob: Ty.Brep) -> String:
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

def faces_dbg(fs: List<&2, Nat>, +b: Ty.Brep, +sd: U64, +vmap: List<&2, Nat>, +hs: List<&2, PX.HX>, +chs: List<&2, PX.CH>, +fdo: List<&2, SO.Fd>,
    +bbo: List<&2, I.I>, +cps: List<&2, CO.CP>, +ob: Ty.Brep, +vmo: List<&2, Nat>, +gv: PX.GV) -> String:
  match fs:
    case []: ""
    case +fi <> +t:
      +s = FB.face_sf(b, fi)
      +pcs = GB.face_pcs(b, fi, sd, vmap, hs, chs, cps, ob, vmo, gv)
      +cs = W.face_cycles(s, pcs)
      +rs = W.regions(s, W.cs_cys(cs))
      "side " ++ U64.show(sd) ++ " face " ++ Nat.show(fi) ++ " cs_ok=" ++ Bool.pick(String, W.cs_ok(cs), "1", "0") ++ " rs_ok=" ++ Bool.pick(String, W.rs_ok(rs), "1", "0") ++
        " nrg=" ++ Nat.show(List.length(&2, W.RG, W.rs_rgs(rs))) ++ "
" ++ rg_dbg(W.rs_rgs(rs), s, fdo, bbo, sd, CO.partner_of(cps, sd, fi), ob) ++
        faces_dbg(t, b, sd, vmap, hs, chs, fdo, bbo, cps, ob, vmo, gv)

def dbg(+ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +va = PX.add_vs(Ty.brep_vs(ba), PX.GV{[], 0n}, [])
  +vb = PX.add_vs(Ty.brep_vs(bb), PX.vm_g(va), [])
  +hs = PX.all_hits(ba, bb, PX.vm_g(vb))
  +cps = CO.coin_pairs(ba, bb)
  +cx0 = CO.crossings(cps, ba, bb, PX.hs_g(hs))
  +tj = CO.tjunctions(cps, ba, bb, CO.cx_g(cx0))
  +cx = {CO.CX{List.append(&2, PX.HX, CO.cx_hs(cx0), CO.cx_hs(tj)), CO.cx_g(tj), Bool.and(CO.cx_ok(cx0), CO.cx_ok(tj))} : CO.CX}
  +hs2 = List.append(&2, PX.HX, PX.hs_hs(hs), CO.cx_hs(cx))
  +cr = PX.all_chains(hs2, ba, bb, CO.cx_g(cx))
  +hs3 = PX.chain_hits(PX.cr_chs(cr), ba, bb, PX.cr_g(cr), hs2)
  +fda = SO.fds_of(ba)
  +fdb = SO.fds_of(bb)
  +gv = PX.cr_g(cr)
  "hs_ok=" ++ Bool.pick(String, PX.hs_ok(hs), "1", "0") ++ " hs_why=" ++ U64.show(PX.hs_why(hs)) ++ " cr_why=" ++ U64.show(PX.cr_why(cr)) ++ " cx_ok=" ++ Bool.pick(String, CO.cx_ok(cx), "1", "0") ++ " cr_ok=" ++ Bool.pick(String, PX.cr_ok(cr), "1", "0") ++ "
" ++
    faces_dbg(L.nat_range(FB.nfaces(ba)), ba, 0u64, PX.vm_mp(va), hs3, PX.cr_chs(cr), fdb, SO.bbox(fdb, []), cps, bb, PX.vm_mp(vb), gv) ++
    faces_dbg(L.nat_range(FB.nfaces(bb)), bb, 1u64, PX.vm_mp(vb), hs3, PX.cr_chs(cr), fda, SO.bbox(fda, []), cps, ba, PX.vm_mp(va), gv)

def pt_s(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

def near_fo(fs: List<&2, Nat>, +side: U64, +e: Nat, +b: Ty.Brep, +ob: Ty.Brep) -> String:
  match fs:
    case []: ""
    case +fo <> +t:
      +k = Ty.ed_kind(FB.edge_at(b, e))
      +g = FB.face_surf(ob, fo)
      +inp = PX.in_plane(k, SF.sf_of(g))
      +r = EF.edge_hits(k, SF.sf_of(g), g <> PX.surfs_of(FB.edge_faces(b, e), b))
      +ed = FB.edge_at(b, e)
      +line = Bool.pick(String, Bool.and(Bool.not(inp), EF.ehs_near(r)),
        "near side=" ++ U64.show(side) ++ " edge=" ++ Nat.show(e) ++ " " ++ pt_s(FB.vpt(b, Ty.ed_v0(ed))) ++ "-" ++ pt_s(FB.vpt(b, Ty.ed_v1(ed))) ++
          " face=" ++ Nat.show(fo) ++ " at " ++ pt_s(EF.ev(EF.ek_curve(k), EF.ehs_nt(r))) ++ " vtx=" ++ Bool.pick(String, PX.near_at_vertex(k, EF.ehs_nt(r), ob), "1", "0") ++ "
", "")
      line ++ near_fo(t, side, e, b, ob)

def near_es(es: List<&2, Nat>, +side: U64, +b: Ty.Brep, +ob: Ty.Brep) -> String:
  match es:
    case []: ""
    case +e <> +t: near_fo(L.nat_range(FB.nfaces(ob)), side, e, b, ob) ++ near_es(t, side, b, ob)

def hd2(+s: String) -> String:
  s

def ek_s(+k: Ty.EdgeKind) -> String:
  match k:
    case Ty.EK_curve{+c, +d}:
      match c:
        case G.GV_ln{w}: "line"
        case G.GV_cc{w}: "circle"
        case G.GV_rq{w}: "rq"
        case G.GV_bz{w}: "bz"
        case G.GV_nb{w}: "nurbs"
        case _: "other"
    case Ty.EK_degenerate{}: "degenerate"

def uses_bad(us: List<&2, Nat>, +i: Nat, +b: Ty.Brep) -> String:
  match us:
    case []: ""
    case +u <> +t:
      +ed = FB.edge_at(b, i)
      Bool.pick(String, Nat.is_eq(u, 2n), "", "edge " ++ Nat.show(i) ++ " uses=" ++ Nat.show(u) ++ " " ++ ek_s(Ty.ed_kind(ed)) ++ " " ++ pt_s(FB.vpt(b, Ty.ed_v0(ed))) ++ "-" ++ pt_s(FB.vpt(b, Ty.ed_v1(ed))) ++ "
") ++
        uses_bad(t, Nat.add(i, 1n), b)

def kr_uses(+r: K1.KR) -> String:
  +b = K1.kr_brep(r)
  uses_bad(K1.k1use_go(Ty.brep_ces(b), K1.zeros(List.length(&2, Ty.Edge, Ty.brep_es(b)), [])), 0n, b)

def v2s(+q: V.Vec2) -> String:
  "(" ++ F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q)) ++ ")"

def ces_s(hs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> String:
  match hs:
    case []: ""
    case +h <> +t:
      +ce = Ty.tres_ce(Ty.ix_ce(x, h))
      +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(ce)))
      +fwd = Ty.ce_fwd(ce)
      "      ce e=" ++ Nat.show(Ty.he_idx(Ty.ce_edge(ce))) ++ " fwd=" ++ Bool.pick(String, fwd, "1", "0") ++ " v " ++ Nat.show(Ty.hv_idx(C4.o_v_start(ed, fwd))) ++ "->" ++
        Nat.show(Ty.hv_idx(C4.o_v_end(ed, fwd))) ++ " t " ++ v2s(C4.trim_o_start(Ty.ce_trim(ce), fwd)) ++ "->" ++ v2s(C4.trim_o_end(Ty.ce_trim(ce), fwd)) ++ "
" ++ ces_s(t, x)

def lps_bad(ls: List<&2, Ty.Loop>, +i: Nat, +x: Ty.Ix) -> String:
  match ls:
    case []: ""
    case +l <> +t:
      +hs = Ty.lp_ces(l)
      +ok = C4.loop_one_ok(hs, x)
      Bool.pick(String, ok, "", "loop " ++ Nat.show(i) ++ " seam=" ++ Bool.pick(String, C4.loop_seam_ok(hs, x), "1", "0") ++ " pole=" ++
        Bool.pick(String, C4.loop_pole_ok(hs, x), "1", "0") ++ "
" ++ ces_s(hs, x)) ++ lps_bad(t, Nat.add(i, 1n), x)

def sk_s(+g: G.GVal) -> String:
  match g:
    case G.GV_pl{w}: "plane"
    case G.GV_cy{w}: "cylinder"
    case G.GV_to{w}:
      G.To{+o, +a, +bigr, +r} = w
      "torus o=" ++ pt_s(o) ++ " R=" ++ F64.show(bigr) ++ " r=" ++ F64.show(r)
    case G.GV_sp{w}: "sphere"
    case G.GV_co{w}: "cone"
    case _: "other"

def bx_s(+bx: List<&2, I.I>) -> String:
  "[" ++ F64.show(I.i_lo(X.vn(bx, 0n))) ++ "," ++ F64.show(I.i_hi(X.vn(bx, 0n))) ++ "]x[" ++ F64.show(I.i_lo(X.vn(bx, 1n))) ++ "," ++ F64.show(I.i_hi(X.vn(bx, 1n))) ++ "]x[" ++
    F64.show(I.i_lo(X.vn(bx, 2n))) ++ "," ++ F64.show(I.i_hi(X.vn(bx, 2n))) ++ "]"

def g_s(gs: List<&2, G.GVal>) -> String:
  match gs:
    case []: "-"
    case +g <> +t: sk_s(g)

def fd_at(fs: List<&2, SO.Fd>, +i: Nat) -> String:
  match fs:
    case []: "?"
    case +f <> +t: Bool.pick(String, Nat.is_eq(SO.fd_fi(f), i), bx_s(SO.fd_bx(f)) ++ " g=" ++ sk_s(SO.fd_g(f)), fd_at(t, i))

def fd_pos(fs: List<&2, SO.Fd>, +i: Nat) -> String:
  match fs:
    case []: "?"
    case +f <> +t:
      match i:
        case 0n: "fi=" ++ Nat.show(SO.fd_fi(f)) ++ " " ++ bx_s(SO.fd_bx(f)) ++ " g=" ++ sk_s(SO.fd_g(f))
        case 1n+(+j): fd_pos(t, j)

def fi_pos(fs: List<&2, SO.Fd>, +i: Nat) -> Nat:
  match fs:
    case []: 0n
    case +f <> +t:
      match i:
        case 0n: SO.fd_fi(f)
        case 1n+(+j): fi_pos(t, j)

def fa_info(+b: Ty.Brep, +fi: Nat) -> String:
  +f = L.nth_f(Ty.brep_fas(b), fi)
  "face " ++ Nat.show(fi) ++ " " ++ sk_s(Ty.fa_surf(f)) ++ " loops=" ++ Nat.show(List.length(&2, Ty.HLoop, Ty.fa_loops(f))) ++ " c07(by fi)=" ++ fd_at(SO.fds_of(b), fi) ++ "
   c07(by pos)=" ++ fd_pos(SO.fds_of(b), fi) ++ "
"

def poly_s(ps: List<&2, V.Vec2>) -> String:
  match ps:
    case []: ""
    case +q <> +t: v2s(q) ++ " " ++ poly_s(t)

def polys_s(ls: List<&2, List<&2, V.Vec2>>) -> String:
  match ls:
    case []: ""
    case +h <> +t: "  poly: " ++ poly_s(h) ++ "
" ++ polys_s(t)

def find_tor(fs: List<&2, Nat>, +b: Ty.Brep) -> Nat:
  match fs:
    case []: 999n
    case +f <> +t:
      +g = Ty.fa_surf(L.nth_f(Ty.brep_fas(b), f))
      Bool.pick(Nat, String.eq(sk_s(g), "torus o=(0,0,2) R=38 r=2"), f, find_tor(t, b))

def mid_pt() -> V.Point:
  V.Pt{F64.mul(38.0f64, 0.7193398003386512f64), F64.mul(38.0f64, 0.6946583704589973f64), 0.0f64}

def pif_s(+b: Ty.Brep, +fi: Nat, +p: V.Point) -> String:
  +s = FB.face_sf(b, fi)
  "face " ++ Nat.show(fi) ++ " uv(p)=" ++ v2s(FB.uv_raw(s, p)) ++ " in=" ++ Bool.pick(String, FB.pt_in_face(b, fi, p), "1", "0") ++ " bnd=" ++
    Bool.pick(String, FB.bnd_near(b, fi, p), "1", "0") ++ " north=" ++ Bool.pick(String, FB.north(b, fi, s), "1", "0") ++ "
" ++ polys_s(FB.face_polys(b, fi))

def fes(hs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> String:
  match hs:
    case []: ""
    case +h <> +t:
      +ce = Ty.tres_ce(Ty.ix_ce(x, h))
      +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(ce)))
      Nat.show(Ty.he_idx(Ty.ce_edge(ce))) ++ "(v" ++ Nat.show(Ty.hv_idx(Ty.ed_v0(ed))) ++ "-v" ++ Nat.show(Ty.hv_idx(Ty.ed_v1(ed))) ++ ") " ++ fes(t, x)

def fls(ls: List<&2, Ty.HLoop>, +b: Ty.Brep, +x: Ty.Ix) -> String:
  match ls:
    case []: ""
    case +l <> +t: "[" ++ fes(Ty.lp_ces(Ty.tres_lp(Ty.ix_lp(x, l))), x) ++ "] " ++ fls(t, b, x)

def face_es(+b: Ty.Brep, +fi: Nat) -> String:
  +f = L.nth_f(Ty.brep_fas(b), fi)
  +x = Ty.ix_of(b)
  "face " ++ Nat.show(fi) ++ " edges: " ++ fls(Ty.fa_loops(f), b, x) ++ "
"

def run(+src: String) -> String:
  +cs = M.ev_part(S.part_of(S.ps_xs(S.parse(src))), [])
  +ba = M.bd_brep(body_of(cs, 2u64))
  +bb = M.bd_brep(body_of(cs, 3u64))
  +kr = GB.gbrun(B8.tag_union(), ba, bb)
  +bc = B8.restamp(K1.kr_brep(kr))
  +fs = SO.fds_of(bc)
  +ed = FB.edge_at(bc, 62n)
  kr_s(kr) ++ "
edge 62 " ++ ek_s(Ty.ed_kind(ed)) ++ " v" ++ Nat.show(Ty.hv_idx(Ty.ed_v0(ed))) ++ " " ++ pt_s(FB.vpt(bc, Ty.ed_v0(ed))) ++ " - v" ++ Nat.show(Ty.hv_idx(Ty.ed_v1(ed))) ++ " " ++ pt_s(FB.vpt(bc, Ty.ed_v1(ed))) ++ "
pos9 " ++ fd_pos(fs, 9n) ++ "
pos11 " ++ fd_pos(fs, 11n) ++ "
" ++ face_es(bc, fi_pos(fs, 9n)) ++ face_es(bc, fi_pos(fs, 11n)) ++ B8.vcode(B8.vcore(bc)) ++ "
"

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/tmp/zp.bcd")
    IO.print(run(src))
