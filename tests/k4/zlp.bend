import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c03/types.bend as G
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as SX
import ../../src/k1/sf.bend as S
import ../../src/k1/fb.bend as FB
import ../../src/k1/px.bend as PX
import ../../src/k1/co.bend as CO
import ../../src/k1/gw.bend as W
import ../../src/k1/gb.bend as GB
import ../../src/k1/asm.bend as K1
import ../../src/c04/ops.bend as O
import ../../src/c07/sol.bend as SO
import ../../src/c07/ivx.bend as X
import ../../src/c07/isect.bend as Y
import ../../src/c07/emb.bend as EM
import ../../src/c07/ss.bend as CS
import ../../src/c06/iv.bend as I
import ../../src/k1/ss.bend as SS
import ../../src/k1/ef.bend as EF

law read_go:
  for m: File & Result<&1, &1, (U32 & String), String>
  IO(String)











type Cx is Data:
  Cx{ ba: FB.KB, bb: FB.KB, ma: List<&2, Nat>, mb: List<&2, Nat>, hs: List<&2, PX.HX>, chs: List<&2, PX.CH>, cps: List<&2, CO.CP>, g: PX.GV }









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









def brep_of(r: M.NR) -> Ty.Brep:
  match r:
    case M.NR_ok{+b, fx}: M.bd_brep(b)
    case M.NR_err{k, d}: Ty.brep_empty()









def v2s(+q: V.Vec2) -> String:
  "(" ++ F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q)) ++ ")"









def yn(+b: Bool) -> String:
  Bool.pick(String, b, "y", "n")









def ces_s(xs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> String:
  match xs:
    case []: ""
    case +h <> t:
      +ce = Ty.tres_ce(Ty.ix_ce(x, h))
      +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(ce)))
      +fw = Ty.ce_fwd(ce)
      +tr = Ty.ce_trim(ce)
      "
    e" ++ Nat.show(Ty.he_idx(Ty.ce_edge(ce))) ++ " tag" ++ U64.show(Ty.ekind_tag(Ty.ed_kind(ed))) ++ " v" ++ Nat.show(Ty.hv_idx(O.o_v_start(ed, fw))) ++ "->v" ++ Nat.show(Ty.hv_idx(O.o_v_end(ed, fw))) ++ " " ++ v2s(O.trim_o_start(tr, fw)) ++ v2s(O.trim_o_end(tr, fw)) ++ ces_s(t, x)









def lp_s(+hcs: List<&2, Ty.HCoedge>, +x: Ty.Ix, +fi: Nat, +k: U64) -> String:
  +ok = O.loop_one_ok(hcs, x)
  +d = O.hks_distinct(O.hcs_keys(hcs, []))
  +sm = O.loop_seam_ok(hcs, x)
  +pl = O.loop_pole_ok(hcs, x)
  Bool.pick(String, ok, "", "face " ++ Nat.show(fi) ++ " kind " ++ U64.show(k) ++ " distinct " ++ yn(d) ++ " seam " ++ yn(sm) ++ " pole " ++ yn(pl) ++ ces_s(hcs, x) ++ "
")









def hls_s(ls: List<&2, Ty.HLoop>, +x: Ty.Ix, +fi: Nat, +k: U64) -> String:
  match ls:
    case []: ""
    case +h <> t: lp_s(Ty.lp_ces(Ty.tres_lp(Ty.ix_lp(x, h))), x, fi, k) ++ hls_s(t, x, fi, k)









def fas_s(fs: List<&2, Ty.Face>, +x: Ty.Ix, +i: Nat) -> String:
  match fs:
    case []: ""
    case +h <> t: hls_s(Ty.fa_loops(h), x, i, S.sf_kind(S.sf_of(Ty.fa_surf(h)))) ++ fas_s(t, x, Nat.add(i, 1n))









def p3(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"











def c_lo(+k: Ty.EdgeKind) -> V.Point:
  G.gres_p(O.curve_at(Ty.ekind_curve(k), G.dom_lo(Ty.ekind_dom(k)), 1000n))







def c_hi(+k: Ty.EdgeKind) -> V.Point:
  G.gres_p(O.curve_at(Ty.ekind_curve(k), G.dom_hi(Ty.ekind_dom(k)), 1000n))







def ed_line(+q0: V.Point, +q1: V.Point, +p0: V.Point, +p1: V.Point, +i: Nat) -> String:
  "edge " ++ Nat.show(i) ++ " v" ++ p3(p0) ++ p3(p1) ++ " c" ++ p3(q0) ++ p3(q1) ++ "
"







def ed_ok(+k: Ty.EdgeKind, +p0: V.Point, +p1: V.Point) -> Bool:
  Bool.and(O.edge_ends_on_curve(k, p0, p1, 1000n), Bool.or(Bool.not(Ty.ekind_is_curve(k)), O.curve_fin_ok(Ty.ekind_curve(k), 1000n)))









def ed_s(+k: Ty.EdgeKind, +p0: V.Point, +p1: V.Point, +i: Nat) -> String:
  Bool.pick(String, ed_ok(k, p0, p1), "", ed_line(c_lo(k), c_hi(k), p0, p1, i))









def eds(es: List<&2, Ty.Edge>, +x: Ty.Ix, +i: Nat) -> String:
  match es:
    case []: ""
    case +h <> t:
      Bool.pick(String, Nat.is_eq(i, 380n), "EDGE380 tag" ++ U64.show(Ty.ekind_tag(Ty.ed_kind(h))) ++ ed_line(c_lo(Ty.ed_kind(h)), c_hi(Ty.ed_kind(h)), Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, Ty.ed_v0(h)))), Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, Ty.ed_v1(h)))), i), "") ++ ed_s(Ty.ed_kind(h), Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, Ty.ed_v0(h)))), Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, Ty.ed_v1(h)))), i) ++ eds(t, x, Nat.add(i, 1n))









def fco(fs: List<&2, Ty.Face>, +x: Ty.Ix, +i: Nat) -> String:
  match fs:
    case []: ""
    case +h <> t:
      +sf = Ty.fa_surf(h)
      +ok = O.hls_face_ok(Ty.fa_loops(h), x, sf, O.surf_coinc(sf), O.surf_quad(sf), Ty.fa_slv(h))
      Bool.pick(String, ok, "", "face " ++ Nat.show(i) ++ " kind " ++ U64.show(S.sf_kind(S.sf_of(sf))) ++ " coinc=" ++ yn(O.surf_coinc(sf)) ++ " quad=" ++ yn(O.surf_quad(sf)) ++ " slv=" ++ F64.show(Ty.fa_slv(h)) ++ "
") ++ fco(t, x, Nat.add(i, 1n))









def fe_s(hcs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> String:
  match hcs:
    case []: ""
    case +h <> t: " e" ++ Nat.show(Ty.he_idx(Ty.ce_edge(Ty.tres_ce(Ty.ix_ce(x, h))))) ++ p3(Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, Ty.ed_v0(Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(Ty.tres_ce(Ty.ix_ce(x, h)))))))))) ++ fe_s(t, x)






def fl_s(ls: List<&2, Ty.HLoop>, +x: Ty.Ix) -> String:
  match ls:
    case []: ""
    case +h <> t: " |" ++ fe_s(Ty.lp_ces(Ty.tres_lp(Ty.ix_lp(x, h))), x) ++ fl_s(t, x)






def fsel(fs: List<&2, Ty.Face>, +x: Ty.Ix, +i: Nat) -> String:
  match fs:
    case []: ""
    case +h <> t:
      +w = Bool.or(Nat.is_eq(i, 38n), Nat.is_eq(i, 40n))
      Bool.pick(String, w, "F" ++ Nat.show(i) ++ " kind " ++ U64.show(S.sf_kind(S.sf_of(Ty.fa_surf(h)))) ++ fl_s(Ty.fa_loops(h), x) ++ "
", "") ++ fsel(t, x, Nat.add(i, 1n))






def hf_fas(hs: List<&2, Ty.HFace>, +x: Ty.Ix) -> List<&2, Ty.Face>:
  match hs:
    case []: []
    case +h <> t: Ty.tres_fa(Ty.ix_fa(x, h)) <> hf_fas(t, x)





def sh_fas(ss: List<&2, Ty.Shell>, +x: Ty.Ix) -> List<&2, Ty.Face>:
  match ss:
    case []: []
    case +s <> t:
      Ty.Sh{g, +fs, k} = s
      List.append(&2, Ty.Face, hf_fas(fs, x), sh_fas(t, x))





def drop_fd(xs: List<&2, SO.Fd>, +i: Nat) -> List<&2, SO.Fd>:
  match xs:
    case []: []
    case +h <> t:
      match i:
        case 0n: h <> t
        case 1n+(+j): drop_fd(t, j)




def ivs(+a: I.I) -> String:
  "[" ++ F64.show(I.i_lo(a)) ++ "," ++ F64.show(I.i_hi(a)) ++ "]"




def bxs(xs: List<&2, I.I>) -> String:
  match xs:
    case []: ""
    case +h <> t: ivs(h) ++ bxs(t)




def uns(us: List<&2, List<&2, I.I>>, +n: Nat) -> String:
  match us:
    case []: ""
    case +h <> t:
      match n:
        case 0n: " ..."
        case 1n+(+k): "
  un " ++ bxs(h) ++ uns(t, k)




def L_b0(xs: List<&2, List<&2, I.I>>) -> List<&2, I.I>:
  match xs:
    case []: []
    case +h <> t: h




def brs(bs: List<&2, CS.Br>) -> String:
  match bs:
    case []: ""
    case +h <> t:
      CS.Br{+cl, +pts, es} = h
      "
  br closed=" ++ yn(cl) ++ " n=" ++ Nat.show(List.length(&2, List<&2, I.I>, pts)) ++ " first " ++ bxs(L_b0(pts)) ++ brs(t)




def sr_s(+r: Y.Sr) -> String:
  Y.Sr{+ss, +k, +co} = r
  CS.Ss{+ok, +bs, +un} = ss
  "SSI k=" ++ U64.show(k) ++ " co=" ++ yn(co) ++ " ok=" ++ yn(ok) ++ " brs=" ++ Nat.show(List.length(&2, CS.Br, bs)) ++ " un=" ++ Nat.show(List.length(&2, List<&2, I.I>, un)) ++ brs(bs) ++ uns(un, 6n) ++ "
"




def pair_go(xs: List<&2, SO.Fd>, ys: List<&2, SO.Fd>) -> String:
  match xs:
    case []: "no fa"
    case +fa <> t:
      match ys:
        case []: "no fb"
        case +fb <> u:
          "boxA " ++ bxs(SO.fd_bx(fa)) ++ "
boxB " ++ bxs(SO.fd_bx(fb)) ++ "
" ++ sr_s(Y.inter_ss(SO.fd_g(fa), SO.fd_g(fb), X.vmeet(SO.fd_bx(fa), SO.fd_bx(fb))))




def fis(xs: List<&2, SO.Fi>) -> String:
  match xs:
    case []: ""
    case +h <> t:
      SO.Fi{+c, +a, +b} = h
      " " ++ c ++ ":" ++ Nat.show(a) ++ "/" ++ Nat.show(b) ++ fis(t)


def allfi(+b: Ty.Brep, +fs: List<&2, SO.Fd>, +ra: Ty.Brep, +rb: Ty.Brep) -> String:
  +tg = SO.tags_or(SO.rtags_of(b, SO.vpool(ra, []), SO.vpool(rb, [])), SO.ltags(b, ra, rb))
  +et = SO.etags_of(b, SO.epool(ra, []), SO.epool(rb, []))
  "FINDINGS" ++ fis(EM.emb_fi_t(b, fs, tg, et)) ++ "
"


def pair9(+b: Ty.Brep, +kr: K1.KR, +ra: Ty.Brep, +rb: Ty.Brep) -> String:
  +fs = SO.fds_re(b, SO.pool_kf(List.append(&2, SO.KF, K1.kr_fk(kr), List.append(&2, SO.KF, SO.kfs_of(ra, SO.fds_of(ra)), SO.kfs_of(rb, SO.fds_of(rb))))))
  allfi(b, fs, ra, rb) ++ pair_go(drop_fd(fs, 9n), drop_fd(fs, 39n))




def emb_s(+b: Ty.Brep) -> String:
  fsel(sh_fas(Ty.brep_shs(b), Ty.ix_of(b)), Ty.ix_of(b), 0n) ++ eds(Ty.brep_es(b), Ty.ix_of(b), 0n) ++ fco(Ty.brep_fas(b), Ty.ix_of(b), 0n) ++ "ces_trim " ++ yn(O.ces_trim_ok(Ty.brep_ces(b))) ++ " surf " ++ yn(O.fas_surf_ok(Ty.brep_fas(b)))








def run(+src: String) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_part(p, [])
  +ra = brep_of(M.ce_r(M.ce_find(cs, 1901u64)))
  +rb = brep_of(M.ce_r(M.ce_find(cs, 2u64)))
  +kr = GB.gbrun(14u64, ra, rb)
  +b = K1.kr_brep(kr)
  "k1 ok " ++ yn(K1.kr_ok(kr)) ++ " why " ++ U64.show(K1.kr_why(kr)) ++ " faces " ++ Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(b))) ++ "
" ++ pair9(b, kr, ra, rb) ++ fas_s(Ty.brep_fas(b), Ty.ix_of(b), 0n) ++ emb_s(b)









def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/home/jesse/g5/dbg.bcd")
    IO.print(run(src))
