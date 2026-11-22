import Base
import ../../src/k1/sf.bend as KS
import ../../src/c07/emb.bend as EMB
import ../../src/c07/isect.bend as Y
import ../../src/c07/ss.bend as CSS
import ../../src/c07/xs.bend as CXS
import ../../src/c07/mem.bend as Mm
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

def body_of_unused(cs: List<&2, M.CE>, +id: U64) -> M.Body:
  M.nr_body(M.ce_r(M.ce_find(cs, id)))

def kr_s(+r: K1.KR) -> String:
  "k1 ok=" ++ Bool.pick(String, K1.kr_ok(r), "1", "0") ++ " why=" ++ U64.show(K1.kr_why(r)) ++ " nf=" ++ Nat.show(K1.kr_nf(r))

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
" ++ rg_dbg(W.rs_rgs(rs), s, fdo, bbo, sd, CO.partner_of(cps, sd, fi), ob) ++
        faces_dbg(t, b, sd, vmap, hs, chs, fdo, bbo, cps, ob, vmo, gv)

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
" ++
    faces_dbg(L.nat_range(FB.nfaces(ba)), ba, 0u64, PX.vm_mp(va), hs3, PX.cr_chs(cr), fdb, SO.bbox(fdb, []), cps, bb, PX.vm_mp(vb), gv) ++
    faces_dbg(L.nat_range(FB.nfaces(bb)), bb, 1u64, PX.vm_mp(vb), hs3, PX.cr_chs(cr), fda, SO.bbox(fda, []), cps, ba, PX.vm_mp(va), gv)

def pt_s(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

def near_fo(fs: List<&2, Nat>, +side: U64, +e: Nat, +b: FB.KB, +ob: FB.KB) -> String:
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

def near_es(es: List<&2, Nat>, +side: U64, +b: FB.KB, +ob: FB.KB) -> String:
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

def fa_info(+b: FB.KB, +fi: Nat) -> String:
  +f = FB.kb_f(b, fi)
  "face " ++ Nat.show(fi) ++ " " ++ sk_s(Ty.fa_surf(f)) ++ " loops=" ++ Nat.show(List.length(&2, Ty.HLoop, Ty.fa_loops(f))) ++ " c07(by fi)=" ++ fd_at(SO.fds_of(FB.kb_br(b)), fi) ++ "
   c07(by pos)=" ++ fd_pos(SO.fds_of(FB.kb_br(b)), fi) ++ "
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

def find_tor(fs: List<&2, Nat>, +b: FB.KB) -> Nat:
  match fs:
    case []: 999n
    case +f <> +t:
      +g = Ty.fa_surf(FB.kb_f(b, f))
      Bool.pick(Nat, String.eq(sk_s(g), "torus o=(0,0,2) R=38 r=2"), f, find_tor(t, b))

def mid_pt() -> V.Point:
  V.Pt{F64.mul(38.0f64, 0.7193398003386512f64), F64.mul(38.0f64, 0.6946583704589973f64), 0.0f64}

def pif_s(+b: FB.KB, +fi: Nat, +p: V.Point) -> String:
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

def fls(ls: List<&2, Ty.HLoop>, +b: FB.KB, +x: Ty.Ix) -> String:
  match ls:
    case []: ""
    case +l <> +t: "[" ++ fes(Ty.lp_ces(Ty.tres_lp(Ty.ix_lp(x, l))), x) ++ "] " ++ fls(t, b, x)

def face_es(+b: FB.KB, +fi: Nat) -> String:
  +f = FB.kb_f(b, fi)
  +x = FB.kb_x(b)
  "face " ++ Nat.show(fi) ++ " edges: " ++ fls(Ty.fa_loops(f), b, x) ++ "
"

def placed(+cs: List<&2, M.CE>, +id: U64) -> Ty.Brep:
  +b = M.nr_body(M.ce_r(M.ce_find(cs, id)))
  +pl = M.bd_pl(b)
  B8.xf_brep(M.pl_m(pl), M.pl_tx(pl), M.pl_ty(pl), M.pl_tz(pl), M.bd_brep(b))

def bxs_s(us: List<&2, List<&2, I.I>>, +n: Nat) -> String:
  match us:
    case []: ""
    case +u <> +t:
      match n:
        case 0n: " ..."
        case 1n+(+m): " " ++ bx_s(u) ++ bxs_s(t, m)

def ss_s(+r: Y.Sr) -> String:
  Y.Sr{+ss, +k, +co} = r
  CSS.Ss{+ok, +brs, +un} = ss
  "ss kind " ++ U64.show(k) ++ " coinc " ++ Bool.pick(String, co, "1", "0") ++ " ok " ++ Bool.pick(String, ok, "1", "0") ++ " brs " ++ Nat.show(List.length(&2, CSS.Br, brs)) ++
    " un " ++ Nat.show(List.length(&2, List<&2, I.I>, un)) ++ bxs_s(un, 4n)

def fis_s(fs: List<&2, SO.Fi>) -> String:
  match fs:
    case []: "ff: no findings"
    case +f <> +t:
      SO.Fi{+c, +a, +b} = f
      "ff: " ++ c ++ " " ++ Nat.show(a) ++ " " ++ Nat.show(b)

def gk(c: G.GVal) -> String:
  match c:
    case G.GV_ln{w}: "line"
    case G.GV_cc{w}: "circle"
    case G.GV_bz{w}: "bezier"
    case G.GV_rq{w}: "rquad"
    case _: "other"

def gks(gs: List<&2, G.GVal>) -> String:
  match gs:
    case []: "none"
    case +h <> +t: gk(h)

def hit_one(h: CXS.Hit, +fd: SO.Fd) -> String:
  match h:
    case CXS.H_pt{+s, t, +p, c}: "  pt s " ++ F64.show(I.i_lo(s)) ++ ".." ++ F64.show(I.i_hi(s)) ++ " p " ++ bx_s(p) ++ " member " ++ U64.show(Mm.member(SO.fd_fc(fd), p, SO.fd_im(fd))) ++ "
"
    case CXS.H_un{+s, t, +p}: "  un s " ++ F64.show(I.i_lo(s)) ++ ".." ++ F64.show(I.i_hi(s)) ++ " p " ++ bx_s(p) ++ " member " ++ U64.show(Mm.member(SO.fd_fc(fd), p, SO.fd_im(fd))) ++ "
"
    case CXS.H_ov{+s, t}: "  ov s " ++ F64.show(I.i_lo(s)) ++ ".." ++ F64.show(I.i_hi(s)) ++ "
"
    case CXS.H_no{+w}: "  no " ++ w ++ "
"

def hit_s(hs: List<&2, CXS.Hit>, +fd: SO.Fd) -> String:
  match hs:
    case []: ""
    case +h <> +t:
      hit_one(h, fd) ++ hit_s(t, fd)

def fs_fis(+r: EMB.Fs) -> List<&2, SO.Fi>:
  EMB.Fs{+x} = r
  x

def uv_info(u: Mm.Uv, +q: List<&2, I.I>) -> String:
  match u:
    case Mm.Uv_cy{+sf, +r, +segs, +tol, xs, xtol}:
      +w = KS.sf_uv(sf, Mm.q_mid(q))
      "uv cyl r " ++ F64.show(r) ++ " tol " ++ F64.show(tol) ++ " dist " ++ F64.show(Mm.win_d(Mm.tb1(segs), r, V.v2_x(w), V.v2_y(w), F64.div(tol, r))) ++ " t " ++ F64.show(V.v2_x(w)) ++ " h " ++ F64.show(V.v2_y(w))
    case Mm.Uv_no{}: "uv none"
    case _: "uv other"

def fc_inf(+f: Mm.Fc, +q: List<&2, I.I>) -> String:
  Mm.Fc{s, same, +es, +uv} = f
  "fc edges " ++ Nat.show(List.length(&2, Mm.Er, es)) ++ " " ++ uv_info(uv, q) ++ "
"

def fc_info(+fd: SO.Fd, +q: List<&2, I.I>) -> String:
  fc_inf(SO.fd_fc(fd), q)

def efr(+x: EMB.Eg, +f: EMB.Fg, +te: B.Tb<&2, EMB.Eg>, +tf: B.Tb<&2, EMB.Fg>, +tef: B.Tb<&2, List<&2, Nat>>, +tol: F64,
    +sfs: B.Tb<&2, List<&2, SO.Fd>>, +a: Nat, +b: Nat) -> String:
  EMB.Eg{+g, +d, ea, eb, +pa, +pb, c, bx, +u, so} = x
  +fd = EMB.fg_fd(f)
  +fis = fs_fis(EMB.chk_ef(a, b, te, tf, tef, tol, sfs))
  "edge " ++ gks(g) ++ " dom " ++ F64.show(CXS.dlo(d)) ++ ".." ++ F64.show(CXS.dhi(d)) ++ " u " ++ U64.show(u) ++ " pa " ++ bx_s(pa) ++ " pb " ++ bx_s(pb) ++ "
" ++
    "face " ++ sk_s(SO.fd_g(fd)) ++ " bx " ++ bx_s(SO.fd_bx(fd)) ++ " edge on face " ++ Bool.pick(String, EMB.has(EMB.fg_es(f), a), "1", "0") ++ "
" ++
    hit_s(SO.hits_any(SO.g1(g), d, SO.fd_g(fd), SO.fd_im(fd)), fd) ++ fc_info(fd, pb) ++ fis_s(fis) ++ "
"

def efq(+cx: EMB.Cx, +a: Nat, +b: Nat) -> String:
  EMB.Cx{+te, +tf, +tef, +tol, ns, +sfs} = cx
  efr(B.tb_get(EMB.Eg, te, U32.from_nat(a)), B.tb_get(EMB.Fg, tf, U32.from_nat(b)), te, tf, tef, tol, sfs, a, b)

def efp(+bc: Ty.Brep, +a: Nat, +b: Nat) -> String:
  +x = Ty.ix_of(bc)
  +fds = SO.fds_of(bc)
  +egs = EMB.egs_go(Ty.brep_es(bc), Ty.ix_tv(x))
  +fgs = EMB.shs_fg(Ty.brep_shs(bc), x, fds, Ty.shmap_of(bc), 0n)
  efq(EMB.mk_cx(egs, fgs, EMB.tol_of(SO.bbox(fds, [])), List.length(&2, Ty.Solid, Ty.brep_sos(bc))), a, b)

def zv_out(+head: String, +bc: Ty.Brep, +pa: Nat, +pb: Nat) -> IO(Unit):
  do IO<Unit>:
    u : Unit <- IO.print(head)
    IO.print(efp(bc, pa, pb))

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +ia = S.u64_of(S.Sx_a{S.arg_at(args, 2n)})
  +ib = S.u64_of(S.Sx_a{S.arg_at(args, 3n)})
  +ka = U64.to_nat(S.u64_of(S.Sx_a{S.arg_at(args, 4n)}))
  +kb = U64.to_nat(S.u64_of(S.Sx_a{S.arg_at(args, 5n)}))
  +cs = M.ev_for(p, [ia, ib], [])
  +kr = GB.gbrun(B8.tag_union(), placed(cs, ia), placed(cs, ib))
  +bc = B8.restamp(K1.kr_brep(kr))
  +fs = SO.fds_of(bc)
  +kc = FB.kb_of(bc)
  zv_out(kr_s(kr) ++ "
pos A " ++ fd_pos(fs, ka) ++ "
pos B " ++ fd_pos(fs, kb) ++ "
" ++ face_es(kc, fi_pos(fs, ka)) ++ face_es(kc, fi_pos(fs, kb)), bc, ka, kb)

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
