import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c06/model.bend as M
import ../../src/c06/xp.bend as X
import ../../src/c06/iv.bend as I
import ../../src/c08/bool.bend as B8
import ../../src/k1/surg.bend as K1
import ../../src/k1/gb.bend as GB
import ../../src/c07/sol.bend as SO
import ../../src/c07/mem.bend as Mm
import ../../src/c07/rb.bend as R
import ../../src/c07/im.bend as MI
import ../../src/c07/ivx.bend as XV
import ./probe.bend as P
import ../../src/k1/ls.bend as L
import ../../src/c07/xs.bend as XS
import ../../src/c03/types.bend as G3
import ../../src/k1/vi.bend as VI
import ../../src/c07/isect.bend as Y
import ../../src/c07/ss.bend as SS
import ../../src/c07/emb.bend as EM
import ../../src/c03/types.bend as G
import ../../src/k1/curve.bend as KU

def port(+r: F64, +x: F64, +y: F64, +z: F64, +e: X.Env) -> Ty.Brep:
  +c6 = P.moved(P.zcyl(r, F64.neg(5.0f64), 15.0f64, e, 6u64), 5.0f64, 5.0f64, 0.0f64, e, 6u64)
  +c7 = P.unnr(M.op_rot(c6, 1u64, M.xk(90.0f64), e, 7u64))
  B8.bake_of(M.bool_in(P.moved(c7, x, y, z, e, 8u64)))

def bs(+b: Bool) -> String:
  Bool.pick(String, b, "T", "F")

def cnu(+c: Mm.Cn) -> Bool:
  Mm.Cn{n, u} = c
  u

def tryd(+f: Mm.Fc, +q: List<&2, I.I>, +nf: MI.Im, +i: Nat, +tau: F64, +rev: Bool) -> String:
  Mm.Fc{s, +same, +es, uv} = f
  +e = Mm.er_at(es, i)
  +c = Mm.er_c(e)
  +rp = R.cv_box(c, I.ipt(tau))
  +lp = Mm.legs_of(s, q, rp, rev, nf)
  +nrm = Mm.neg_if(same, MI.im_grad(nf, rp))
  +tl = Mm.neg_if(Mm.er_fwd(e), R.cv_der(c, I.ipt(tau)))
  +cn = Mm.total(Mm.lp_ls(lp), es, i, tau, Mm.Cn{0n, False{}})
  +ar = Mm.arrive(Mm.lp_d(lp), nrm, tl)
  "\n   e" ++ Nat.show(i) ++ " t" ++ F64.show(tau) ++ " rev" ++ bs(rev) ++ " rp=(" ++ F64.show(I.imid(XV.vn(rp, 0n))) ++ "," ++ F64.show(I.imid(XV.vn(rp, 1n))) ++ "," ++ F64.show(I.imid(XV.vn(rp, 2n))) ++ ") ok" ++ bs(Mm.lp_ok(lp)) ++ " n" ++ Nat.show(Mm.cn_n(cn)) ++ " u" ++ bs(cnu(cn)) ++ " arr" ++ U64.show(ar) ++ " res" ++ U64.show(Mm.finish(cn, ar))

def tries(+n: Nat, +f: Mm.Fc, +q: List<&2, I.I>, +nf: MI.Im, +j: Nat) -> String:
  match n:
    case 0n: ""
    case 1n+m: tryd(f, q, nf, Nat.div(j, 6n), Mm.tau_of(Nat.div(j, 2n)), Nat.is_eq(Nat.mod(j, 2n), 1n)) ++ tries(m, f, q, nf, Nat.add(j, 1n))

def fdump(fs: List<&2, SO.Fd>, +q: List<&2, I.I>, +i: Nat) -> String:
  match fs:
    case []: ""
    case +f <> +t:
      +nr = SO.near_face(f, q, 0.000001f64)
      +ne = List.length(&2, Mm.Er, Mm.fc_es(SO.fd_fc(f)))
      Bool.pick(String, nr, "\nface " ++ Nat.show(i) ++ " nes=" ++ Nat.show(ne) ++ " member=" ++ U64.show(Mm.member(SO.fd_fc(f), q, SO.fd_im(f))) ++ tries(Nat.min(0n, Nat.mul(6n, ne)), SO.fd_fc(f), q, SO.fd_im(f), 0n), "") ++ fdump(t, q, Nat.add(i, 1n))

def cls(+fds: List<&2, SO.Fd>, +x: F64, +y: F64, +z: F64) -> String:
  " " ++ U64.show(SO.classify(fds, V.Pt{x, y, z}))

def vshow(+b: Ty.Brep) -> String:
  +vc = B8.vcore(b)
  Bool.pick(String, B8.VR_ok(vc), "valid", B8.vcode(vc))

def slvs(fs: List<&2, Ty.Face>, +i: Nat) -> String:
  match fs:
    case []: ""
    case +f <> +t: " f" ++ Nat.show(i) ++ "=" ++ F64.show(Ty.fa_slv(f)) ++ slvs(t, Nat.add(i, 1n))

def fdord(fs: List<&2, SO.Fd>, +i: Nat) -> String:
  match fs:
    case []: ""
    case +f <> +t: " " ++ Nat.show(i) ++ ":f" ++ Nat.show(SO.fd_fi(f)) ++ "k" ++ U64.show(KU.surfkind(SO.fd_g(f))) ++ fdord(t, Nat.add(i, 1n))

def p3s(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

def d3s(+p: V.Dir) -> String:
  "(" ++ F64.show(V.dr_x(p)) ++ "," ++ F64.show(V.dr_y(p)) ++ "," ++ F64.show(V.dr_z(p)) ++ ")"

def cys(g: G.GVal) -> String:
  match g:
    case G.GV_cy{w}:
      G.Cy{+o, +a, +r} = w
      "cy o=" ++ p3s(o) ++ " a=" ++ d3s(a) ++ " r=" ++ F64.show(r)
    case _: "notcy"

def facecy(fs: List<&2, Ty.Face>, +i: Nat) -> String:
  match fs:
    case []: ""
    case +f <> +t: Bool.pick(String, Bool.or(Nat.is_eq(i, 7n), Nat.is_eq(i, 9n)), "
 f" ++ Nat.show(i) ++ " " ++ cys(Ty.fa_surf(f)), "") ++ facecy(t, Nat.add(i, 1n))

def ivs(xs: List<&2, I.I>) -> String:
  match xs:
    case []: ""
    case +x <> +t: "[" ++ F64.show(I.i_lo(x)) ++ "," ++ F64.show(I.i_hi(x)) ++ "]" ++ ivs(t)

def uns(us: List<&2, List<&2, I.I>>) -> String:
  match us:
    case []: ""
    case +u <> +t: "
   un " ++ ivs(u) ++ uns(t)

def brs(xs: List<&2, SS.Br>) -> String:
  match xs:
    case []: ""
    case +b <> +t:
      SS.Br{closed, pts, ends} = b
      " br(closed=" ++ bs(closed) ++ " n=" ++ Nat.show(List.length(&2, List<&2, I.I>, pts)) ++ ")" ++ brs(t)

def ssdump(+r: Y.Sr) -> String:
  Y.Sr{ss, k, co} = r
  SS.Ss{ok, bb, un} = ss
  "k=" ++ U64.show(k) ++ " ok=" ++ bs(ok) ++ brs(bb) ++ uns(un)

def nthf(fs: List<&2, SO.Fd>, +i: Nat) -> SO.Fd:
  match fs:
    case []: SO.fd_dflt()
    case +f <> +t:
      match i:
        case 0n: f
        case 1n+j: nthf(t, j)

def vshow2(+r: K1.KR) -> String:
  +b = K1.kr_brep(r)
  +vc = B8.vcore(b)
  +v = VI.brep_vol(b)
  Bool.pick(String, K1.kr_ok(r), "ok", "FAIL" ++ U64.show(K1.kr_why(r))) ++ " " ++ Bool.pick(String, B8.VR_ok(vc), "valid", B8.vcode(vc)) ++ " vol=[" ++ F64.show(I.i_lo(VI.vr_vol(v))) ++ "," ++ F64.show(I.i_hi(VI.vr_vol(v))) ++ "]"

def ipshow(m: Maybe<&2, SO.Ip>) -> String:
  match m:
    case None{}: "ip=None"
    case Some{ip}:
      SO.Ip{+fi, +q, nv} = ip
      "ip face#" ++ Nat.show(fi) ++ " q=" ++ ivs(q)

def dshow(ds: List<&2, V.Dir>, +fs: List<&2, SO.Fd>, +bb: List<&2, I.I>, +m: Maybe<&2, SO.Ip>) -> String:
  match ds:
    case []: ""
    case +g <> +t:
      match m:
        case None{}: ""
        case Some{ip}:
          SO.Ip{+fi, +q, +nv} = ip
          +d = SO.dr_of(SO.off_dir(nv, g))
          +r = SO.shoot(fs, bb, SO.pt_of(q), d, fi, 9.313225746154785e-10f64)
          " [st" ++ U64.show(SO.rc_st(r)) ++ " n" ++ Nat.show(SO.rc_n(r)) ++ "]" ++ dshow(t, fs, bb, Some{SO.Ip{fi, q, nv}})

def ordbg(+b: Ty.Brep) -> String:
  +fs = SO.fds_of(b)
  +bb = SO.bbox(fs, [])
  +m = SO.ip_find(fs, None{}, 0n, 0n)
  ipshow(m) ++ dshow(SO.dirs(), fs, bb, SO.ip_find(fs, None{}, 0n, 0n))

def fdoks(fs: List<&2, SO.Fd>, +i: Nat) -> String:
  match fs:
    case []: ""
    case +f <> +t: " " ++ Nat.show(i) ++ ":f" ++ Nat.show(SO.fd_fi(f)) ++ Bool.pick(String, SO.fd_ok(f), "ok", "BAD") ++ "uv" ++ Bool.pick(String, Mm.uv_has(Mm.fc_uv(SO.fd_fc(f))), "Y", "N") ++ fdoks(t, Nat.add(i, 1n))

def hsh(hs: List<&2, XS.Hit>, +fd: SO.Fd) -> String:
  match hs:
    case []: ""
    case +h <> +t:
      match h:
        case XS.H_pt{sp, tt, +p, c}: " pt(s=" ++ F64.show(I.i_lo(sp)) ++ ")m" ++ U64.show(Mm.member(SO.fd_fc(fd), p, SO.fd_im(fd))) ++ hsh(t, fd)
        case XS.H_un{sp, tt, +p}: " un(s=" ++ F64.show(I.i_lo(sp)) ++ ")m" ++ U64.show(Mm.member(SO.fd_fc(fd), p, SO.fd_im(fd))) ++ hsh(t, fd)
        case XS.H_ov{sp, tt}: " ov" ++ hsh(t, fd)
        case XS.H_no{w}: " no:" ++ w ++ hsh(t, fd)

def rayf(fs: List<&2, SO.Fd>, +p: V.Point, +d: V.Dir, +i: Nat) -> String:
  match fs:
    case []: ""
    case +f <> +t: "
  F" ++ Nat.show(i) ++ ":" ++ hsh(XS.inter_cs(G3.GV_ln{G3.Ln{p, d}}, G3.Dom{0.0f64, 40.0f64}, SO.fd_g(f), 40n), f) ++ rayf(t, p, d, Nat.add(i, 1n))

def raydbg_m(m: Maybe<&2, SO.Ip>, +fs: List<&2, SO.Fd>) -> String:
  match m:
    case None{}: "none"
    case Some{ip}:
      SO.Ip{+fi, +q, +nv} = ip
      rayf(fs, SO.pt_of(q), SO.dr_of(SO.off_dir(nv, V.Dr{0.5773502691896258f64, 0.6123724356957945f64, 0.5400617248673217f64})), 0n)

def raydbg(+b: Ty.Brep) -> String:
  +fs = SO.fds_of(b)
  raydbg_m(SO.ip_find(fs, None{}, 0n, 0n), fs)

def slvf(fs: List<&2, Nat>, +b: Ty.Brep, +c: V.Point) -> String:
  match fs:
    case []: ""
    case +h <> +t:
      +v = VI.face_va(b, h, c)
      " f" ++ Nat.show(h) ++ "k" ++ U64.show(KU.surfkind(Ty.fa_surf(L.nth_f(Ty.brep_fas(b), h)))) ++ "=" ++ F64.show(VI.va_slv(v)) ++ slvf(t, b, c)

def slvb(+r: K1.KR) -> String:
  +b = K1.kr_brep(r)
  slvf(L.nat_range(List.length(&2, Ty.Face, Ty.brep_fas(b))), b, VI.center_of(b))

def main() -> String:
  +e = X.env_mk([])
  +b1 = B8.bake_of(M.bool_in(P.box10(e, 1u64)))
  +b4 = B8.bake_of(M.bool_in(P.moved(P.zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 2u64)))
  +a4 = K1.kr_brep(GB.gbrun(B8.tag_diff(), b1, b4))
  +c1 = B8.bake_of(M.bool_in(P.zcyl(3.0f64, 0.0f64, 10.0f64, e, 11u64)))
  +c2 = B8.bake_of(M.bool_in(P.moved(P.zcyl(3.0f64, 0.0f64, 10.0f64, e, 12u64), 4.0f64, 0.0f64, 0.0f64, e, 13u64)))
  +f8 = K1.kr_brep(GB.gbrun(B8.tag_union(), c1, c2))
  +cz = P.zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = P.unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +pt = B8.bake_of(M.bool_in(P.moved(cx, 0.0f64, 4.0f64, 5.0f64, e, 3u64)))
  +rq = GB.gbrun(B8.tag_diff(), a4, port(2.0f64, 0.0f64, 0.0f64, 10.0f64, e))
  +ru = GB.gbrun(B8.tag_union(), f8, pt)
  "boreq " ++ vshow2(rq) ++ "
" ++ slvb(rq) ++ "
fp union " ++ vshow2(ru) ++ "
" ++ slvb(ru) ++ "
"
