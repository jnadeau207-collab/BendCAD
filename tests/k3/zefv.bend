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
import ../../src/c07/emb.bend as EM
import ../../src/c07/mem.bend as Mm
import ../../src/c07/xs.bend as XS
import ../../src/c07/rb.bend as R
import ../../src/c07/eng.bend as N
import ../../src/base/ex.bend as E

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

def b_s(+b: Bool) -> String:
  Bool.pick(String, b, "1", "0")

def bx_s(+bx: List<&2, I.I>) -> String:
  "[" ++ F64.show(I.i_lo(X.vn(bx, 0n))) ++ "," ++ F64.show(I.i_hi(X.vn(bx, 0n))) ++ "]x[" ++ F64.show(I.i_lo(X.vn(bx, 1n))) ++ "," ++ F64.show(I.i_hi(X.vn(bx, 1n))) ++ "]x[" ++
    F64.show(I.i_lo(X.vn(bx, 2n))) ++ "," ++ F64.show(I.i_hi(X.vn(bx, 2n))) ++ "]"

def iv_s(+x: I.I) -> String:
  "[" ++ F64.show(I.i_lo(x)) ++ "," ++ F64.show(I.i_hi(x)) ++ "]"

def placed(+cs: List<&2, M.CE>, +id: U64) -> Ty.Brep:
  +b = M.nr_body(M.ce_r(M.ce_find(cs, id)))
  +pl = M.bd_pl(b)
  B8.xf_brep(M.pl_m(pl), M.pl_tx(pl), M.pl_ty(pl), M.pl_tz(pl), M.bd_brep(b))

def fis_s(fs: List<&2, SO.Fi>) -> String:
  match fs:
    case []: ""
    case +f <> +t:
      SO.Fi{+c, +a, +b} = f
      " fi " ++ c ++ " " ++ Nat.show(a) ++ " " ++ Nat.show(b) ++ "
" ++ fis_s(t)

def tor_dbg(u: Mm.Uv, +q: List<&2, I.I>) -> String:
  match u:
    case Mm.Uv_to{+sf, +ur, +vr, +segs, +s3, +tol}:
      +w = Mm.tor_jit(Mm.tor_w(sf, ur, vr, Mm.q_mid(q)))
      " tor d=" ++ F64.show(Mm.s3_scan(s3, Mm.q_mid(q), F64.div(1.0f64, 0.0f64))) ++ " tol=" ++ F64.show(F64.add(F64.add(tol, Mm.q_rad(q)), Mm.tor_jd(sf))) ++ " n=" ++ Nat.show(Mm.np_scan(segs, V.v2_x(w), V.v2_y(w), 0n)) ++ " w=(" ++ F64.show(V.v2_x(w)) ++ "," ++ F64.show(V.v2_y(w)) ++ ") nseg=" ++ Nat.show(List.length(&2, Mm.Sg, segs)) ++ " ns3=" ++ Nat.show(List.length(&2, Mm.S3, s3))
    case _: " uv-other"

def hit_s(h: XS.Hit, +c: R.Cv, +lo: F64, +hi: F64, +mode: U64, +fd: SO.Fd, +sv: List<&2, List<&2, I.I>>, +tol: F64, +ofds: List<&2, SO.Fd>) -> String:
  match h:
    case XS.H_pt{+s, t, +p, k}:
      +m = Mm.member(SO.fd_fc(fd), p, SO.fd_im(fd))
      "  H_pt s=" ++ iv_s(s) ++ " p=" ++ bx_s(p) ++ " near=" ++ b_s(EM.near_any(sv, p, tol)) ++ " member=" ++ U64.show(m) ++ " mode=" ++ U64.show(mode) ++
        tor_dbg(Mm.fc_uv(SO.fd_fc(fd)), p) ++ " thin_end=" ++ b_s(EM.ef_thin_end(s, lo, hi)) ++ " far=" ++ b_s(EM.ef_far(fd, p)) ++ " tan=" ++ U64.show(EM.ef_tan(ofds, SO.bbox(ofds, []), c, s, lo, hi)) ++ "
"
    case XS.H_un{+s, t, +p}:
      +q = EM.hb_or(X.vfin(p), p, c)
      "  H_un s=" ++ iv_s(s) ++ " p=" ++ bx_s(q) ++ " near=" ++ b_s(EM.near_any(sv, q, tol)) ++ " member=" ++ U64.show(Mm.member(SO.fd_fc(fd), q, SO.fd_im(fd))) ++ " mode=" ++ U64.show(mode) ++ "
"
    case XS.H_ov{+s, t}: "  H_ov s=" ++ iv_s(s) ++ " member=" ++ U64.show(Mm.member(SO.fd_fc(fd), EM.ov_pt(c, s, lo, hi), SO.fd_im(fd))) ++ " mode=" ++ U64.show(mode) ++ "
"
    case XS.H_no{+w}: "  H_no " ++ w ++ "
"

def pv_s(+pb: N.Pb, +a: F64, +b: F64) -> String:
  " P[" ++ F64.show(a) ++ "," ++ F64.show(b) ++ "]=" ++ iv_s(X.vn(N.pb_f(pb, [I.I{a, b}]), 0n))

def un_dbg(+g: G.GVal, +d: G.Dom, +sf: G.GVal, +s: I.I) -> String:
  +es = XS.comp_go(XS.gv_xc(g), XS.gv_xs(sf))
  +lo = XS.dlo(d)
  +hi = XS.dhi(d)
  +pb = XS.mk_h(XS.bern(es, lo, hi), es, lo, hi)
  +m = F64.mul(0.5f64, F64.add(I.i_lo(s), I.i_hi(s)))
  +w = F64.sub(I.i_hi(s), I.i_lo(s))
  "   deg=" ++ Nat.show(List.length(&2, E.Ex, es)) ++ pv_s(pb, I.i_lo(s), m) ++ pv_s(pb, m, I.i_hi(s)) ++ pv_s(pb, F64.sub(I.i_lo(s), w), I.i_lo(s)) ++ " Pend=" ++ iv_s(X.vn(N.pb_f(pb, [I.ipt(hi)]), 0n)) ++ "
"

def hits_s(hs: List<&2, XS.Hit>, +c: R.Cv, +lo: F64, +hi: F64, +mode: U64, +fd: SO.Fd, +sv: List<&2, List<&2, I.I>>, +tol: F64, +ofds: List<&2, SO.Fd>) -> String:
  match hs:
    case []: ""
    case +h <> +t: hit_s(h, c, lo, hi, mode, fd, sv, tol, ofds) ++ hits_s(t, c, lo, hi, mode, fd, sv, tol, ofds)

def vd_go(vs: List<&2, Nat>, +tv: B.Tb<&2, Ty.Vertex>, +p: V.Point) -> String:
  match vs:
    case []: ""
    case +i <> +t:
      +q = Ty.vx_p(B.tb_get(Ty.Vertex, tv, U32.from_nat(i)))
      +dx = F64.sub(V.pt_x(q), V.pt_x(p))
      +dy = F64.sub(V.pt_y(q), V.pt_y(p))
      +dz = F64.sub(V.pt_z(q), V.pt_z(p))
      +d = F64.sqrt(F64.add(F64.mul(dx, dx), F64.add(F64.mul(dy, dy), F64.mul(dz, dz))))
      Bool.pick(String, F64.is_lt(d, 1.0e-3f64), " v" ++ Nat.show(i) ++ "@" ++ F64.show(d), "") ++ vd_go(t, tv, p)

def eg_ab(+x: EM.Eg) -> String:
  EM.Eg{g, d, +a0, +a1, pa0, pa1, c, bx, u, so} = x
  "a0=v" ++ Nat.show(a0) ++ " a1=v" ++ Nat.show(a1)

def vpt(+tv: B.Tb<&2, Ty.Vertex>, +i: Nat) -> V.Point:
  Ty.vx_p(B.tb_get(Ty.Vertex, tv, U32.from_nat(i)))

def eg_a1(+x: EM.Eg) -> Nat:
  EM.Eg{g, d, a0, +a1, pa0, pa1, c, bx, u, so} = x
  a1

def eg_a0(+x: EM.Eg) -> Nat:
  EM.Eg{g, d, +a0, a1, pa0, pa1, c, bx, u, so} = x
  a0

def vinfo(+cx: EM.Cx, +tv: B.Tb<&2, Ty.Vertex>, +nv: Nat, +ia: Nat, +jb: Nat) -> String:
  EM.Cx{+te, +tf, tef, tol, ns, sfs, sbx} = cx
  +x = B.tb_get(EM.Eg, te, U32.from_nat(ia))
  +f = B.tb_get(EM.Fg, tf, U32.from_nat(jb))
  " " ++ eg_ab(x) ++ " face-vs-near-a0:" ++ vd_go(EM.fg_vs(f), tv, vpt(tv, eg_a0(x))) ++ " face-vs-near-a1:" ++ vd_go(EM.fg_vs(f), tv, vpt(tv, eg_a1(x))) ++ " all-vs-near-a1:" ++ vd_go(L.nat_range(nv), tv, vpt(tv, eg_a1(x))) ++ "
"

def un_one(h: XS.Hit, +g: G.GVal, +d: G.Dom, +sf: G.GVal) -> String:
  match h:
    case XS.H_un{+s, t, p}: un_dbg(g, d, sf, s)
    case _: ""

def un_all(hs: List<&2, XS.Hit>, +g: G.GVal, +d: G.Dom, +sf: G.GVal) -> String:
  match hs:
    case []: ""
    case +h <> +t: un_one(h, g, d, sf) ++ un_all(t, g, d, sf)

def pair2(x: EM.Eg, +f: EM.Fg, +fd: SO.Fd, +fe: List<&2, Nat>, +cross: Bool, +ofds: List<&2, SO.Fd>, +tf: B.Tb<&2, EM.Fg>, +tol: F64, +ia: Nat, +jb: Nat) -> String:
  EM.Eg{+g, +d, +a0, +a1, +pa0, +pa1, +c, +bx, +u, +so} = x
  +xe = {EM.Eg{g, d, a0, a1, pa0, pa1, c, bx, u, so} : EM.Eg}
  +sv = EM.sh_pt(EM.has(EM.fg_vs(f), a0), pa0, EM.sh_pt(EM.has(EM.fg_vs(f), a1), pa1, []))
  "pair e" ++ Nat.show(ia) ++ " f" ++ Nat.show(jb) ++ " own=" ++ b_s(EM.has(EM.fg_es(f), ia)) ++ " cross=" ++ b_s(cross) ++ " sep=" ++ b_s(EM.sep_e(xe, fd, tol)) ++ " ctan=" ++ b_s(EM.circ_tan(xe, fd, EM.fg_vs(f), tol)) ++
    " co=" ++ b_s(EM.any_co(fe, tf, SO.fd_g(fd))) ++ " tol=" ++ F64.show(tol) ++ " dom=[" ++ F64.show(XS.dlo(d)) ++ "," ++ F64.show(XS.dhi(d)) ++ "] ebx=" ++ bx_s(bx) ++ " pa0=" ++ bx_s(pa0) ++ " pa1=" ++ bx_s(pa1) ++ "
" ++
    " fbx=" ++ bx_s(SO.fd_bx(fd)) ++ "
" ++
    hits_s(SO.hits_any(SO.g1(g), d, SO.fd_g(fd), SO.fd_im(fd)), c, XS.dlo(d), XS.dhi(d), EM.ef_mode(ofds, pa0, pa1, cross), fd, sv, tol, ofds) ++
    un_all(SO.hits_any(SO.g1(g), d, SO.fd_g(fd), SO.fd_im(fd)), SO.g1(g), d, SO.fd_g(fd)) ++
    " result=" ++ fis_s(EM.ef(xe, f, fe, tf, ia, jb, tol, cross, ofds))

def pair_s(+cx: EM.Cx, +ia: Nat, +jb: Nat) -> String:
  EM.Cx{+te, +tf, +tef, +tol, ns, +sfs, sbx} = cx
  +x = B.tb_get(EM.Eg, te, U32.from_nat(ia))
  +f = B.tb_get(EM.Fg, tf, U32.from_nat(jb))
  +fd = EM.fg_fd(f)
  +fe = B.tb_get(List<&2, Nat>, tef, U32.from_nat(ia))
  +cross = Bool.not(Nat.is_eq(EM.eg_so(x), EM.fg_so(f)))
  +ofds = B.tb_get(List<&2, SO.Fd>, sfs, U32.from_nat(EM.fg_so(f)))
  pair2(x, f, fd, fe, cross, ofds, tf, tol, ia, jb)

def run(+src: String, +op: String, +nb: U64, +ia: Nat, +jb: Nat) -> String:
  +cs = M.ev_part(S.part_of(S.ps_xs(S.parse(src))), [])
  +ba = placed(cs, 1u64)
  +bb = placed(cs, nb)
  +tg = Bool.pick(U64, String.eq(op, "i"), B8.tag_inter(), Bool.pick(U64, String.eq(op, "d"), B8.tag_diff(), B8.tag_union()))
  +kr = GB.gbrun(tg, ba, bb)
  +bc = B8.restamp(K1.kr_brep(kr))
  +fds = SO.fds_of(bc)
  +xx = Ty.ix_of(bc)
  +egs = EM.egs_go(Ty.brep_es(bc), Ty.ix_tv(xx))
  +fgs = EM.shs_fg(Ty.brep_shs(bc), xx, fds, Ty.shmap_of(bc), 0n)
  +cx = EM.mk_cx(egs, fgs, EM.tol_of(SO.bbox(fds, [])), List.length(&2, Ty.Solid, Ty.brep_sos(bc)))
  "k1 ok=" ++ b_s(K1.kr_ok(kr)) ++ " why=" ++ U64.show(K1.kr_why(kr)) ++ "
emb:
" ++ fis_s(EM.emb_fi(bc, fds)) ++ pair_s(cx, ia, jb) ++ vinfo(cx, Ty.ix_tv(xx), List.length(&2, Ty.Vertex, Ty.brep_vs(bc)), ia, jb)

law go2:
  for a: String
  for o: String
  for n: String
  for i: String
  for j: String
  IO(String)

def go2(a, o, n, i, j):
  do IO<String>:
    src : String <- read_file(a)
    return run(src, o, S.u64_of(S.Sx_a{n}), U64.to_nat(S.u64_of(S.Sx_a{i})), U64.to_nat(S.u64_of(S.Sx_a{j})))

def go(+xs: List<&2, String>) -> IO(String):
  go2(S.arg_at(xs, 1n), S.arg_at(xs, 2n), S.arg_at(xs, 3n), S.arg_at(xs, 4n), S.arg_at(xs, 5n))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    r : String <- go(S.args_l(args))
    IO.print(r)
