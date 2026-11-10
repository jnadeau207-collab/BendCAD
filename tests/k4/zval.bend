import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c03/types.bend as G3
import ../../src/c06/model.bend as M
import ../../src/c08/bool.bend as B8
import ../../src/c06/sx.bend as SX
import ../../src/k1/sf.bend as S
import ../../src/k1/fb.bend as FB
import ../../src/k1/px.bend as PX
import ../../src/k1/co.bend as CO
import ../../src/k1/ls.bend as L
import ../../src/k1/gb.bend as GB
import ../../src/k1/asm.bend as K1
import ../../src/c07/emb.bend as EM
import ../../src/c07/sol.bend as SO
import ../../src/c06/iv.bend as IV
import ../../src/c07/mem.bend as Mm
import ../../src/c07/xs.bend as XS
import ../../src/base/par.bend as BP
import ../../src/k1/ef.bend as EF

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

def brep_of(r: M.NR) -> Ty.Brep:
  match r:
    case M.NR_ok{+b, fx}: B8.bake_of(M.bool_in(b))
    case M.NR_err{k, d}: Ty.brep_empty()

def p3s(+q: V.Point) -> String:
  F64.show(S.px(q)) ++ " " ++ F64.show(S.py(q)) ++ " " ++ F64.show(S.pz(q))

def samp(n: Nat, +c: G3.GVal, +lo: F64, +hi: F64, +k: F64) -> String:
  match n:
    case 0n: ""
    case 1n+m:
      +t = F64.add(lo, F64.mul(F64.sub(hi, lo), F64.div(k, 32.0f64)))
      "ep " ++ p3s(EF.ev(c, t)) ++ "
" ++ samp(m, c, lo, hi, F64.add(k, 1.0f64))

def gk(+g: G3.GVal) -> String:
  match g:
    case G3.GV_ln{w}: "ln"
    case G3.GV_cc{w}: "cc"
    case G3.GV_rq{w}: "rq"
    case G3.GV_bz{w}: "bz"
    case G3.GV_pl{w}: "pl"
    case G3.GV_cy{w}: "cy"
    case G3.GV_bp{w}: "bp"
    case _: "other"

def bps(+g: G3.GVal) -> String:
  match g:
    case G3.GV_bp{w}:
      G3.Bp{a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3, d0, d1, d2, d3} = w
      "cp " ++ p3s(a0) ++ " " ++ p3s(a1) ++ " " ++ p3s(a2) ++ " " ++ p3s(a3) ++ " " ++ p3s(b0) ++ " " ++ p3s(b1) ++ " " ++ p3s(b2) ++ " " ++ p3s(b3) ++ " " ++
        p3s(c0) ++ " " ++ p3s(c1) ++ " " ++ p3s(c2) ++ " " ++ p3s(c3) ++ " " ++ p3s(d0) ++ " " ++ p3s(d1) ++ " " ++ p3s(d2) ++ " " ++ p3s(d3) ++ "
"
    case G3.GV_cy{w}:
      G3.Cy{o, a, r} = w
      "cyl " ++ p3s(o) ++ " r " ++ F64.show(r) ++ "
"
    case _: ""

def nats(xs: List<&2, Nat>) -> String:
  match xs:
    case []: ""
    case +h <> +t: Nat.show(h) ++ " " ++ nats(t)

def fdesc(fs: List<&2, Nat>, +b: FB.KB) -> String:
  match fs:
    case []: ""
    case +h <> +t: "face " ++ Nat.show(h) ++ " " ++ gk(FB.face_surf(b, h)) ++ " nes " ++ Nat.show(List.length(&2, Nat, PX.face_es(b, h))) ++ "
" ++ bps(FB.face_surf(b, h)) ++ fdesc(t, b)

def ivs(xs: List<&2, IV.I>) -> String:
  match xs:
    case []: ""
    case +h <> +t: "[" ++ F64.show(IV.i_lo(h)) ++ "," ++ F64.show(F64.sub(F64.mul(2.0f64, IV.imid(h)), IV.i_lo(h))) ++ "] " ++ ivs(t)

def fgn(fs: List<&2, EM.Fg>, +i: Nat) -> String:
  match fs:
    case []: "fg missing"
    case +h <> +t:
      match i:
        case 0n: "fg box " ++ ivs(SO.fd_bx(EM.fg_fd(h))) ++ " so " ++ Nat.show(EM.fg_so(h)) ++ "
fg vs " ++ nats(EM.fg_vs(h))
        case 1n+m: fgn(t, m)

def evs(e: Ty.Edge) -> String:
  Ty.Ed{gn, ev0, ev1, ek} = e
  " v0 " ++ Nat.show(EM.hv_i(ev0)) ++ " v1 " ++ Nat.show(EM.hv_i(ev1))

def vat(vs: List<&2, Ty.Vertex>, +i: Nat) -> V.Point:
  match vs:
    case []: S.pt(0.0f64, 0.0f64, 0.0f64)
    case +h <> +t:
      match i:
        case 0n: Ty.vx_p(h)
        case 1n+m: vat(t, m)

def near(ids: List<&2, Nat>, +vs: List<&2, Ty.Vertex>, +p: V.Point, +bi: Nat, +bd: F64) -> String:
  match ids:
    case []: "nearest " ++ Nat.show(bi) ++ " d " ++ F64.show(bd) ++ " at " ++ p3s(vat(vs, bi))
    case +h <> +t:
      +d = S.dist(vat(vs, h), p)
      +c = F64.is_lt(d, bd)
      near(t, vs, p, Bool.pick(Nat, c, h, bi), Bool.pick(F64, c, d, bd))

def ev1(e: Ty.Edge) -> Nat:
  Ty.Ed{gn, v0, v1, ek} = e
  EM.hv_i(v1)

def fgv(fs: List<&2, EM.Fg>, +i: Nat) -> List<&2, Nat>:
  match fs:
    case []: []
    case +h <> +t:
      match i:
        case 0n: EM.fg_vs(h)
        case 1n+m: fgv(t, m)

def sgs(gs: List<&2, Mm.Sg>) -> String:
  match gs:
    case []: ""
    case +g <> +t:
      Mm.Sg{t0, h0, t1, h1} = g
      "sg " ++ F64.show(t0) ++ " " ++ F64.show(h0) ++ " " ++ F64.show(t1) ++ " " ++ F64.show(h1) ++ "
" ++ sgs(t)

def uvs(u: Mm.Uv) -> String:
  match u:
    case Mm.Uv_cy{sf, r, segs, tol}: "uvcy r " ++ F64.show(r) ++ " tol " ++ F64.show(tol) ++ "
" ++ sgs(segs)
    case _: "uv other
"

def fgm(fs: List<&2, EM.Fg>, +i: Nat, +p: V.Point) -> String:
  match fs:
    case []: "fg missing"
    case +h <> +t:
      match i:
        case 0n:
          +fd = EM.fg_fd(h)
          +q = {[IV.ipt(S.px(p)), IV.ipt(S.py(p)), IV.ipt(S.pz(p))] : List<&2, IV.I>}
          "member " ++ U64.show(Mm.member(SO.fd_fc(fd), q, SO.fd_im(fd))) ++ "
" ++ uvs(Mm.fc_uv(SO.fd_fc(fd)))
        case 1n+m: fgm(t, m, p)

def egn(es: List<&2, EM.Eg>, +i: Nat) -> String:
  match es:
    case []: "eg missing"
    case +h <> +t:
      match i:
        case 0n: "eg " ++ gk(EM.eg_g(h)) ++ " a " ++ Nat.show(EM.eg_a(h)) ++ " b " ++ Nat.show(EM.eg_b(h)) ++ " so " ++ Nat.show(EM.eg_so(h)) ++ " pa " ++ ivs(EM.eg_pa(h)) ++ " pb " ++ ivs(EM.eg_pb(h))
        case 1n+m: egn(t, m)

def i2(+x: IV.I) -> String:
  "[" ++ F64.show(IV.i_lo(x)) ++ "," ++ F64.show(F64.sub(F64.mul(2.0f64, IV.imid(x)), IV.i_lo(x))) ++ "]"

def hss(hs: List<&2, XS.Hit>) -> String:
  match hs:
    case []: ""
    case +h <> +t:
      match h:
        case XS.H_pt{s, u, p, k}: "hit pt s " ++ i2(s) ++ " p " ++ ivs(p) ++ "
" ++ hss(t)
        case XS.H_ov{s, u}: "hit ov s " ++ i2(s) ++ "
" ++ hss(t)
        case XS.H_un{s, u, p}: "hit un s " ++ i2(s) ++ " p " ++ ivs(p) ++ "
" ++ hss(t)
        case XS.H_no{w}: "hit no " ++ w ++ "
" ++ hss(t)

def fgh(fs: List<&2, EM.Fg>, +j: Nat, +e: EM.Eg) -> String:
  match fs:
    case []: "fg missing"
    case +h <> +t:
      match j:
        case 0n:
          +fd = EM.fg_fd(h)
          hss(SO.hits_any(EM.eg_g(e), EM.eg_d(e), SO.fd_g(fd), SO.fd_im(fd)))
        case 1n+m: fgh(t, m, e)

def egh(es: List<&2, EM.Eg>, +i: Nat, fs: List<&2, EM.Fg>, +j: Nat) -> String:
  match es:
    case []: "eg missing"
    case +h <> +t:
      match i:
        case 0n: fgh(fs, j, h)
        case 1n+m: egh(t, m, fs, j)

def fi1s(h: SO.Fi) -> String:
  SO.Fi{c, a, b} = h
  "fi " ++ c ++ " " ++ Nat.show(a) ++ " " ++ Nat.show(b) ++ "
"

def fis(xs: List<&2, SO.Fi>, +n: Nat) -> String:
  match xs:
    case []: ""
    case +h <> +t:
      match n:
        case 0n: "..."
        case 1n+m: fi1s(h) ++ fis(t, m)

def b2(+x: Bool) -> String:
  Bool.pick(String, x, "y", "n")

def hmem(hs: List<&2, XS.Hit>, +fd: SO.Fd) -> String:
  match hs:
    case []: ""
    case +h <> +t:
      match h:
        case XS.H_pt{s, u, p, k}: "hpt s " ++ i2(s) ++ " mem " ++ U64.show(Mm.member(SO.fd_fc(fd), p, SO.fd_im(fd))) ++ " p " ++ ivs(p) ++ "
" ++ hmem(t, fd)
        case _: "hother
" ++ hmem(t, fd)

def cxd(c: EM.Cx, +a: Nat, +b: Nat) -> String:
  EM.Cx{te, +tf, tef, +tol, ns, sfs} = c
  +x = BP.tb_get(EM.Eg, te, U32.from_nat(a))
  +f = BP.tb_get(EM.Fg, tf, U32.from_nat(b))
  +fe = BP.tb_get(List<&2, Nat>, tef, U32.from_nat(a))
  +fd = EM.fg_fd(f)
  +cross = Bool.not(Nat.is_eq(EM.eg_so(x), EM.fg_so(f)))
  "cx tol " ++ F64.show(tol) ++ " eso " ++ Nat.show(EM.eg_so(x)) ++ " fso " ++ Nat.show(EM.fg_so(f)) ++ " own " ++ b2(EM.has(EM.fg_es(f), a)) ++
    " sep " ++ b2(EM.sep_e(x, fd, tol)) ++ " ctan " ++ b2(EM.circ_tan(x, fd, EM.fg_vs(f), tol)) ++ " far " ++ b2(EM.e_far(False{}, x, fd, tol)) ++
    " co " ++ b2(EM.any_co(fe, tf, SO.fd_g(fd))) ++ " fe " ++ nats(fe) ++ "
" ++ hmem(SO.hits_any(EM.eg_g(x), EM.eg_d(x), SO.fd_g(fd), SO.fd_im(fd)), fd) ++ fis(EM.ef(x, f, fe, tf, a, b, tol, cross, BP.tb_get(List<&2, SO.Fd>, sfs, U32.from_nat(EM.fg_so(f)))), 5n)

def run(+src: String, +na: U64, +nb: U64, +ei: Nat, +fi: Nat) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_for(p, [na, nb], [])
  +ra = brep_of(M.ce_r(M.ce_find(cs, na)))
  +rb = brep_of(M.ce_r(M.ce_find(cs, nb)))
  +kr = GB.gbrun(14u64, ra, rb)
  +bc = B8.restamp(K1.kr_brep(kr))
  +b = FB.kb_of(bc)
  +k = Ty.ed_kind(FB.edge_at(b, ei))
  +fdc = SO.fds_re(bc, SO.pool_kf(List.append(&2, SO.KF, K1.kr_fk(kr), List.append(&2, SO.KF, SO.kfs_of(ra, SO.fds_of(ra)), SO.kfs_of(rb, SO.fds_of(rb))))))
  +cxx = EM.mk_cx(EM.egs_go(Ty.brep_es(bc), Ty.ix_tv(Ty.ix_of(bc))), EM.shs_fg(Ty.brep_shs(bc), Ty.ix_of(bc), fdc, Ty.shmap_of(bc), 0n), EM.tol_of(SO.bbox(fdc, [])), List.length(&2, Ty.Solid, Ty.brep_sos(bc)))
  cxd(cxx, ei, fi) ++ fis(EM.emb_fi_t(bc, fdc, SO.tags_or(SO.rtags_of(bc, SO.vpool(ra, []), SO.vpool(rb, [])), SO.ltags(bc, ra, rb)), SO.etags_of(bc, SO.epool(ra, []), SO.epool(rb, []))), 40n) ++ "ok " ++ Bool.pick(String, K1.kr_ok(kr), "y", "n") ++ " ne " ++ Nat.show(FB.nedges(b)) ++ " nf " ++ Nat.show(FB.nfaces(b)) ++ "
edge " ++ gk(EF.ek_curve(k)) ++ " lo " ++ F64.show(EF.ek_lo(k)) ++ " hi " ++ F64.show(EF.ek_hi(k)) ++ " faces " ++ nats(FB.edge_faces(b, ei)) ++ evs(FB.edge_at(b, ei)) ++ "
" ++ samp(33n, EF.ek_curve(k), EF.ek_lo(k), EF.ek_hi(k), 0.0f64) ++ fdesc(FB.edge_faces(b, ei), b) ++ fdesc([fi], b) ++ "v1 at " ++ p3s(vat(Ty.brep_vs(bc), ev1(FB.edge_at(b, ei)))) ++ "
" ++ near(fgv(EM.shs_fg(Ty.brep_shs(bc), Ty.ix_of(bc), SO.fds_re(bc, SO.pool_kf(List.append(&2, SO.KF, K1.kr_fk(kr), List.append(&2, SO.KF, SO.kfs_of(ra, SO.fds_of(ra)), SO.kfs_of(rb, SO.fds_of(rb)))))), Ty.shmap_of(bc), 0n), fi), Ty.brep_vs(bc), vat(Ty.brep_vs(bc), ev1(FB.edge_at(b, ei))), 0n, 1.0e9f64) ++ "
" ++ fgn(EM.shs_fg(Ty.brep_shs(bc), Ty.ix_of(bc), SO.fds_re(bc, SO.pool_kf(List.append(&2, SO.KF, K1.kr_fk(kr), List.append(&2, SO.KF, SO.kfs_of(ra, SO.fds_of(ra)), SO.kfs_of(rb, SO.fds_of(rb)))))), Ty.shmap_of(bc), 0n), fi) ++ "
" ++ egn(EM.egs_go(Ty.brep_es(bc), Ty.ix_tv(Ty.ix_of(bc))), ei) ++ "
" ++ egh(EM.egs_go(Ty.brep_es(bc), Ty.ix_tv(Ty.ix_of(bc))), ei, EM.shs_fg(Ty.brep_shs(bc), Ty.ix_of(bc), SO.fds_re(bc, SO.pool_kf(List.append(&2, SO.KF, K1.kr_fk(kr), List.append(&2, SO.KF, SO.kfs_of(ra, SO.fds_of(ra)), SO.kfs_of(rb, SO.fds_of(rb)))))), Ty.shmap_of(bc), 0n), fi) ++ fgm(EM.shs_fg(Ty.brep_shs(bc), Ty.ix_of(bc), SO.fds_re(bc, SO.pool_kf(List.append(&2, SO.KF, K1.kr_fk(kr), List.append(&2, SO.KF, SO.kfs_of(ra, SO.fds_of(ra)), SO.kfs_of(rb, SO.fds_of(rb)))))), Ty.shmap_of(bc), 0n), fi, vat(Ty.brep_vs(bc), ev1(FB.edge_at(b, ei)))) ++ "
"

def num(+s: String) -> U64:
  SX.u64_of(SX.Sx_a{s})

def to2(xs: List<&1, String>) -> List<&2, String>:
  match xs:
    case []: []
    case h <> t: h <> to2(t)

def go2(+src: String, +args: List<&2, String>) -> IO(Unit):
  IO.print(run(src, num(SX.arg_at(args, 2n)), num(SX.arg_at(args, 3n)), U64.to_nat(num(SX.arg_at(args, 4n))), U64.to_nat(num(SX.arg_at(args, 5n)))))

def go(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(SX.arg_at(args, 1n))
    go2(src, args)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(to2(args))
