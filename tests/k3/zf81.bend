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
import ../../src/c07/isect.bend as Y
import ../../src/c07/ss.bend as SS7
import ../../src/c07/emb.bend as EM

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

def kr_s(+r: K1.KR) -> String:
  "k1 ok=" ++ Bool.pick(String, K1.kr_ok(r), "1", "0") ++ " why=" ++ U64.show(K1.kr_why(r)) ++ " nf=" ++ Nat.show(K1.kr_nf(r))

def pt_s(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

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

def uses_bad(us: List<&2, Nat>, +i: Nat, +b: FB.KB) -> String:
  match us:
    case []: ""
    case +u <> +t:
      +ed = FB.edge_at(b, i)
      Bool.pick(String, Nat.is_eq(u, 2n), "", "edge " ++ Nat.show(i) ++ " uses=" ++ Nat.show(u) ++ " " ++ ek_s(Ty.ed_kind(ed)) ++ " " ++ pt_s(FB.vpt(b, Ty.ed_v0(ed))) ++ "-" ++ pt_s(FB.vpt(b, Ty.ed_v1(ed))) ++ "
") ++
        uses_bad(t, Nat.add(i, 1n), b)

def v2s(+q: V.Vec2) -> String:
  "(" ++ F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q)) ++ ")"

def ces_s(hs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> String:
  match hs:
    case []: ""
    case +h <> +t:
      +ce = Ty.tres_ce(Ty.ix_ce(x, h))
      +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(ce)))
      +fwd = Ty.ce_fwd(ce)
      "      ce e=" ++ Nat.show(Ty.he_idx(Ty.ce_edge(ce))) ++ " " ++ ek_s(Ty.ed_kind(ed)) ++ " fwd=" ++ Bool.pick(String, fwd, "1", "0") ++ " v " ++ Nat.show(Ty.hv_idx(C4.o_v_start(ed, fwd))) ++ "->" ++
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


def placed(+cs: List<&2, M.CE>, +id: U64) -> Ty.Brep:
  +b = M.nr_body(M.ce_r(M.ce_find(cs, id)))
  +pl = M.bd_pl(b)
  B8.xf_brep(M.pl_m(pl), M.pl_tx(pl), M.pl_ty(pl), M.pl_tz(pl), M.bd_brep(b))

def kr_uses(+r: K1.KR) -> String:
  +b = FB.kb_of(K1.kr_brep(r))
  +ne = FB.kb_ne(b)
  uses_bad(K1.tb_take(ne, K1.k1use_go(Ty.brep_ces(FB.kb_br(b)), ne, B.tb_of(Nat, K1.zeros(ne, []), 0n)), 0n), 0n, b)

def faces_s(n: Nat, +i: Nat, +b: FB.KB) -> String:
  match n:
    case 0n: ""
    case 1n+(+m):
      +f = FB.kb_f(b, i)
      "face " ++ Nat.show(i) ++ " " ++ sk_s(Ty.fa_surf(f)) ++ " " ++ fls(Ty.fa_loops(f), b, FB.kb_x(b)) ++ "
" ++ faces_s(m, Nat.add(i, 1n), b)

def bx_s(+bx: List<&2, I.I>) -> String:
  "[" ++ F64.show(I.i_lo(X.vn(bx, 0n))) ++ "," ++ F64.show(I.i_hi(X.vn(bx, 0n))) ++ "]x[" ++ F64.show(I.i_lo(X.vn(bx, 1n))) ++ "," ++ F64.show(I.i_hi(X.vn(bx, 1n))) ++ "]x[" ++
    F64.show(I.i_lo(X.vn(bx, 2n))) ++ "," ++ F64.show(I.i_hi(X.vn(bx, 2n))) ++ "]"

def fd_pos(fs: List<&2, SO.Fd>, +i: Nat) -> String:
  match fs:
    case []: "?"
    case +f <> +t:
      match i:
        case 0n: "fi=" ++ Nat.show(SO.fd_fi(f)) ++ " " ++ bx_s(SO.fd_bx(f)) ++ " g=" ++ sk_s(SO.fd_g(f))
        case 1n+(+j): fd_pos(t, j)


def fds_s(fs: List<&2, SO.Fd>, +i: Nat) -> String:
  match fs:
    case []: ""
    case +f <> +t: "pos " ++ Nat.show(i) ++ " fi=" ++ Nat.show(SO.fd_fi(f)) ++ " " ++ bx_s(SO.fd_bx(f)) ++ " g=" ++ sk_s(SO.fd_g(f)) ++ "\n" ++ fds_s(t, Nat.add(i, 1n))


def es_bad(es: List<&2, Ty.Edge>, +x: Ty.Ix, +fuel: Nat, +i: Nat) -> String:
  match es:
    case []: ""
    case +h <> +t: Bool.pick(String, C4.es_embed_ok([h], x, fuel), "", "embed-bad edge " ++ Nat.show(i) ++ " " ++ ek_s(Ty.ed_kind(h)) ++ "\n") ++ es_bad(t, x, fuel, Nat.add(i, 1n))


def b_s(+b: Bool) -> String:
  Bool.pick(String, b, "1", "0")

def cq_one(+x: Ty.Ix, +hv: Ty.HVertex, +he: Ty.HVertex, +sf: G.GVal, +tol: F64) -> String:
  " s0=" ++ b_s(C4.vx_surf_tol(x, hv, sf, tol)) ++ " s1=" ++ b_s(C4.vx_surf_tol(x, he, sf, tol))

def cq_vv(+hv: Ty.HVertex, +he: Ty.HVertex, +x: Ty.Ix, +sf: G.GVal, +tol: F64) -> String:
  " v" ++ Nat.show(Ty.hv_idx(hv)) ++ "->v" ++ Nat.show(Ty.hv_idx(he)) ++ cq_one(x, hv, he, sf, tol) ++ " p0=" ++ pt_s(Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, hv))))

def cq_ed(+ed: Ty.Edge, +fw: Bool, +x: Ty.Ix, +sf: G.GVal, +tol: F64) -> String:
  " fwd=" ++ b_s(fw) ++ cq_vv(C4.o_v_start(ed, fw), C4.o_v_end(ed, fw), x, sf, tol)

def cq_c(+ce: Ty.Coedge, +x: Ty.Ix, +sf: G.GVal, +tol: F64) -> String:
  "   ce e=" ++ Nat.show(Ty.he_idx(Ty.ce_edge(ce))) ++ cq_ed(Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(ce))), Ty.ce_fwd(ce), x, sf, tol)

def cq_ce(+h: Ty.HCoedge, +x: Ty.Ix, +sf: G.GVal, +tol: F64) -> String:
  cq_c(Ty.tres_ce(Ty.ix_ce(x, h)), x, sf, tol) ++ " one=" ++ b_s(C4.hcs_face_ok([h], x, sf, False{}, True{}, tol))

def cq_s(xs: List<&2, Ty.HCoedge>, +x: Ty.Ix, +sf: G.GVal, +tol: F64) -> String:
  match xs:
    case []: ""
    case +h <> +t: cq_ce(h, x, sf, tol) ++ "
" ++ cq_s(t, x, sf, tol)

def lc_s(ls: List<&2, Ty.HLoop>, +x: Ty.Ix, +sf: G.GVal, +tol: F64) -> String:
  match ls:
    case []: ""
    case +l <> +t: "  loop ok=" ++ b_s(C4.hls_face_ok([l], x, sf, False{}, True{}, tol)) ++ "\n" ++ cq_s(Ty.lp_ces(Ty.tres_lp(Ty.ix_lp(x, l))), x, sf, tol) ++ lc_s(t, x, sf, tol)

def fa_bad(fs: List<&2, Ty.Face>, +x: Ty.Ix, +i: Nat) -> String:
  match fs:
    case []: ""
    case +h <> +t: Bool.pick(String, C4.fas_coinc_ok([h], x), "", "coinc-bad face " ++ Nat.show(i) ++ " " ++ sk_s(Ty.fa_surf(h)) ++ " slv=" ++ F64.show(Ty.fa_slv(h)) ++ "\n" ++ lc_s(Ty.fa_loops(h), x, Ty.fa_surf(h), Ty.fa_slv(h))) ++ fa_bad(t, x, Nat.add(i, 1n))

def emb_s(+bc: Ty.Brep) -> String:
  +x = Ty.ix_of(bc)
  "trim_ok=" ++ Bool.pick(String, C4.ces_trim_ok(Ty.brep_ces(bc)), "1", "0") ++ " surf_ok=" ++ Bool.pick(String, C4.fas_surf_ok(Ty.brep_fas(bc)), "1", "0") ++ "\n" ++
    es_bad(Ty.brep_es(bc), x, B8.fuel_of(bc), 0n) ++ fa_bad(Ty.brep_fas(bc), x, 0n)

def fd_at(fs: List<&2, SO.Fd>, +i: Nat) -> SO.Fd:
  match fs:
    case []: SO.fd_dflt()
    case +f <> +t:
      match i:
        case 0n: f
        case 1n+(+k): fd_at(t, k)

def br_s(bs: List<&2, SS7.Br>) -> String:
  match bs:
    case []: ""
    case +b <> +t:
      SS7.Br{+cl, +ps, +es} = b
      " br closed=" ++ Bool.pick(String, cl, "1", "0") ++ " pts=" ++ Nat.show(List.length(&2, List<&2, I.I>, ps)) ++ " ends=" ++ Nat.show(List.length(&2, SS7.Ep, es)) ++ "
" ++ br_s(t)

def un_s(us: List<&2, List<&2, I.I>>) -> String:
  match us:
    case []: ""
    case +u <> +t: " un " ++ bx_s(u) ++ "
" ++ un_s(t)

def sr_s(+r: Y.Sr) -> String:
  Y.Sr{+ss, +k, +co} = r
  SS7.Ss{+ok, +brs, +un} = ss
  " ss ok=" ++ Bool.pick(String, ok, "1", "0") ++ " kind=" ++ U64.show(k) ++ " coin=" ++ Bool.pick(String, co, "1", "0") ++ " nbr=" ++ Nat.show(List.length(&2, SS7.Br, brs)) ++ " nun=" ++ Nat.show(List.length(&2, List<&2, I.I>, un)) ++ "
" ++ br_s(brs) ++ un_s(un)

def fd_s(+f: SO.Fd) -> String:
  "fi=" ++ Nat.show(SO.fd_fi(f)) ++ " " ++ bx_s(SO.fd_bx(f)) ++ " g=" ++ sk_s(SO.fd_g(f))

def pair_s(+fs: List<&2, SO.Fd>, +ia: Nat, +ib: Nat) -> String:
  +fa = fd_at(fs, ia)
  +fb = fd_at(fs, ib)
  "pair " ++ Nat.show(ia) ++ " " ++ Nat.show(ib) ++ "
 a " ++ fd_s(fa) ++ "
 b " ++ fd_s(fb) ++ "
" ++
    sr_s(Y.inter_ss(SO.fd_g(fa), SO.fd_g(fb), EM.pad_ss(X.vmeet(SO.fd_bx(fa), SO.fd_bx(fb)))))

def run(+src: String, +op: String) -> String:
  +cs = M.ev_part(S.part_of(S.ps_xs(S.parse(src))), [])
  +ba = placed(cs, 1u64)
  +bb = placed(cs, 12u64)
  +tg = Bool.pick(U64, String.eq(op, "i"), B8.tag_inter(), Bool.pick(U64, String.eq(op, "d"), B8.tag_diff(), B8.tag_union()))
  +kr = GB.gbrun(tg, ba, bb)
  +bc = B8.restamp(K1.kr_brep(kr))
  +fs = SO.fds_of(bc)
  kr_s(kr) ++ "
vcode " ++ B8.vcode(B8.vcore(bc)) ++ "
" ++ fds_s(fs, 0n) ++
    Bool.pick(String, String.eq(op, "i"), pair_s(fs, 3n, 7n), Bool.pick(String, String.eq(op, "d"), pair_s(fs, 3n, 10n), pair_s(fs, 6n, 15n)))

law go2:
  for a: String
  for o: String
  IO(String)

def go2(a, o):
  do IO<String>:
    src : String <- read_file(a)
    return run(src, o)

def go(+xs: List<&2, String>) -> IO(String):
  go2(S.arg_at(xs, 1n), S.arg_at(xs, 2n))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    r : String <- go(S.args_l(args))
    IO.print(r)
