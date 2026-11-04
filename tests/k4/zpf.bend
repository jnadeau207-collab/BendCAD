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
import ../../src/k1/vi.bend as VI
import ../../src/c07/sol.bend as SO
import ../../src/c07/emb.bend as EM
import ../../src/base/par.bend as B
import ../../src/c04/ops.bend as O
import ../../src/c07/ivx.bend as X
import ../../src/c07/isect.bend as Y
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

def kinds(ps: List<&2, EM.Pr>, +k: U64) -> List<&2, EM.Pr>:
  match ps:
    case []: []
    case +p <> t:
      EM.Pr{+kk, +a, +b} = p
      +rest = kinds(t, k)
      Bool.pick(List<&2, EM.Pr>, U64.is_eq(kk, k), p <> rest, rest)

def fis(xs: List<&2, SO.Fi>) -> String:
  match xs:
    case []: ""
    case +h <> t:
      SO.Fi{+c, +a, +b} = h
      " " ++ c ++ ":" ++ Nat.show(a) ++ "/" ++ Nat.show(b) ++ fis(t)

def runm(mode: Nat, +cx: EM.Cx, +prs: List<&2, EM.Pr>) -> String:
  match mode:
    case 0n: ""
    case 1n: ""
    case 2n: " ee" ++ fis(EM.run_prs(cx, kinds(prs, 0u64)))
    case 3n: " ef" ++ fis(EM.run_prs(cx, kinds(prs, 1u64)))
    case _: " ff" ++ fis(EM.run_prs(cx, kinds(prs, 2u64)))

def val(+b: Ty.Brep, +ra: Ty.Brep, +rb: Ty.Brep, +kr: K1.KR, +mode: Nat) -> String:
  +fs = SO.fds_re(b, SO.pool_kf(List.append(&2, SO.KF, K1.kr_fk(kr), List.append(&2, SO.KF, SO.kfs_of(ra, SO.fds_of(ra)), SO.kfs_of(rb, SO.fds_of(rb))))))
  +tg = SO.tags_or(SO.rtags_of(b, SO.vpool(ra, []), SO.vpool(rb, [])), SO.ltags(b, ra, rb))
  +et = SO.etags_of(b, SO.epool(ra, []), SO.epool(rb, []))
  +x = Ty.ix_of(b)
  +egs = EM.egs_go(Ty.brep_es(b), Ty.ix_tv(x))
  +fgs = EM.shs_fg(Ty.brep_shs(b), x, fs, Ty.shmap_of(b), 0n)
  +tgt = B.tb_of(U64, tg, 0u64)
  +prs = EM.keep_new(EM.sweep(EM.its_of(egs, fgs)), tgt, B.tb_of(U64, et, 0u64), EM.em_of(egs, fgs, tgt))
  +cx = EM.mk_cx(egs, fgs, EM.tol_of(SO.bbox(fs, [])), List.length(&2, Ty.Solid, Ty.brep_sos(b)))
  "pairs ee=" ++ Nat.show(List.length(&2, EM.Pr, kinds(prs, 0u64))) ++ " ef=" ++ Nat.show(List.length(&2, EM.Pr, kinds(prs, 1u64))) ++ " ff=" ++ Nat.show(List.length(&2, EM.Pr, kinds(prs, 2u64))) ++ " edges=" ++ Nat.show(List.length(&2, EM.Eg, egs)) ++
    runm(mode, cx, prs)

def st2(mode: Nat, +ba: FB.KB, +bb: FB.KB, +g: PX.GV) -> String:
  match mode:
    case 0n: "kb"
    case 1n: "kb"
    case 2n:
      +hs = PX.all_hits(ba, bb, g)
      "hits " ++ Nat.show(List.length(&2, PX.HX, PX.hs_hs(hs)))
    case 3n:
      +hs = PX.all_hits(ba, bb, g)
      +cps = CO.coin_pairs(ba, bb)
      +cr = PX.all_chains(PX.hs_hs(hs), ba, bb, PX.hs_g(hs))
      "chains " ++ Nat.show(List.length(&2, PX.CH, PX.cr_chs(cr))) ++ " cps " ++ Nat.show(List.length(&2, CO.CP, cps))
    case _:
      +hs = PX.all_hits(ba, bb, g)
      +cr = PX.all_chains(PX.hs_hs(hs), ba, bb, PX.hs_g(hs))
      +hs3 = PX.chain_hits(PX.cr_chs(cr), ba, bb, PX.cr_g(cr), PX.hs_hs(hs))
      "chits " ++ Nat.show(List.length(&2, PX.HX, hs3))

def fkeep(c: Bool, +x: Ty.Ix, +h: Ty.HFace, +sh: Nat, +rest: List<&2, SO.Fd>) -> List<&2, SO.Fd>:
  match c:
    case True{}: SO.fd_x(x, h, sh) <> rest
    case False{}: rest

def fsel(js: List<&2, SO.FJ>, +x: Ty.Ix, +bp: Bool) -> List<&2, SO.Fd>:
  match js:
    case []: []
    case +j <> t:
      SO.FJ{+h, +sh} = j
      +k = S.sf_kind(S.sf_of(Ty.fa_surf(Ty.tres_fa(Ty.ix_fa(x, h)))))
      +isb = U64.is_eq(k, S.k_bp())
      fkeep(Bool.not(Bool.xor(isb, bp)), x, h, sh, fsel(t, x, bp))

def stage(mode: Nat, +ra: Ty.Brep, +rb: Ty.Brep) -> String:
  match mode:
    case 9n:
      +kr = GB.gbrun(14u64, ra, rb)
      val(K1.kr_brep(kr), ra, rb, kr, 1n)
    case 10n:
      +kr = GB.gbrun(14u64, ra, rb)
      val(K1.kr_brep(kr), ra, rb, kr, 2n)
    case 11n:
      +kr = GB.gbrun(14u64, ra, rb)
      val(K1.kr_brep(kr), ra, rb, kr, 3n)
    case 12n:
      +kr = GB.gbrun(14u64, ra, rb)
      val(K1.kr_brep(kr), ra, rb, kr, 4n)
    case 7n:
      +kr = GB.gbrun(14u64, ra, rb)
      +b = K1.kr_brep(kr)
      "bp-fds " ++ Nat.show(List.length(&2, SO.Fd, fsel(SO.fj_shs(Ty.brep_shs(b), 0n), Ty.ix_of(b), True{})))
    case 8n:
      +kr = GB.gbrun(14u64, ra, rb)
      +b = K1.kr_brep(kr)
      "an-fds " ++ Nat.show(List.length(&2, SO.Fd, fsel(SO.fj_shs(Ty.brep_shs(b), 0n), Ty.ix_of(b), False{})))
    case 6n:
      +kr = GB.gbrun(14u64, ra, rb)
      "k1+fds " ++ Nat.show(List.length(&2, SO.Fd, SO.fds_of(K1.kr_brep(kr))))
    case 5n:
      +kr = GB.gbrun(14u64, ra, rb)
      "k1 " ++ Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(K1.kr_brep(kr))))
    case 4n:
      +ba = FB.kb_of(ra)
      +bb = FB.kb_of(rb)
      +va = PX.add_vs(Ty.brep_vs(ra), PX.GV{[], 0n}, [])
      +vb = PX.add_vs(Ty.brep_vs(rb), PX.vm_g(va), [])
      +hs = PX.all_hits(ba, bb, PX.vm_g(vb))
      +cr = PX.all_chains(PX.hs_hs(hs), ba, bb, PX.hs_g(hs))
      +hs3 = PX.chain_hits(PX.cr_chs(cr), ba, bb, PX.cr_g(cr), PX.hs_hs(hs))
      +em = GB.emit_if(True{}, 0u64, 14u64, ba, bb, va, vb, hs3, cr, [], SO.fds_of(ra), SO.fds_of(rb))
      "emit " ++ Bool.pick(String, GB.em_ok(em), "ok", "bad")
    case _:
      +va = PX.add_vs(Ty.brep_vs(ra), PX.GV{[], 0n}, [])
      +vb = PX.add_vs(Ty.brep_vs(rb), PX.vm_g(va), [])
      st2(mode, FB.kb_of(ra), FB.kb_of(rb), PX.vm_g(vb))

def run(+src: String, +mode: Nat) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_part(p, [])
  stage(mode, brep_of(M.ce_r(M.ce_find(cs, 1901u64))), brep_of(M.ce_r(M.ce_find(cs, 2u64))))

def fs_s(+f: EM.Fs) -> String:
  EM.Fs{+xs} = f
  fis(xs)

def pr_s(+p: EM.Pr) -> String:
  EM.Pr{+k, +a, +b} = p
  Nat.show(a) ++ "/" ++ Nat.show(b)

def loop_go(ps: List<&2, EM.Pr>, +cx: EM.Cx) -> IO(Unit):
  match ps:
    case []: IO.print("done")
    case +p <> t:
      do IO<Unit>:
        u : Unit <- IO.print("PAIR " ++ pr_s(p) ++ fs_s(EM.chk(cx, p)))
        loop_go(t, cx)

def L_tk(n: Nat, xs: List<&2, EM.Pr>) -> List<&2, EM.Pr>:
  match n:
    case 0n: []
    case 1n+(+m):
      match xs:
        case []: []
        case +h <> t: h <> L_tk(m, t)

def L_dr(n: Nat, xs: List<&2, EM.Pr>) -> List<&2, EM.Pr>:
  match n:
    case 0n: xs
    case 1n+(+m):
      match xs:
        case []: []
        case +h <> t: L_dr(m, t)

def prs_s(ps: List<&2, EM.Pr>) -> String:
  match ps:
    case []: ""
    case +p <> t: " " ++ pr_s(p) ++ prs_s(t)

def ivs(+a: I.I) -> String:
  "[" ++ F64.show(I.i_lo(a)) ++ "," ++ F64.show(I.i_hi(a)) ++ "]"

def bxs(xs: List<&2, I.I>) -> String:
  match xs:
    case []: ""
    case +h <> t: ivs(h) ++ bxs(t)

def fk_s(fs: List<&2, EM.Fg>, +i: Nat) -> String:
  match fs:
    case []: ""
    case +f <> t: Bool.pick(String, Bool.or(Nat.is_eq(i, 41n), Bool.or(Nat.is_eq(i, 34n), Nat.is_eq(i, 39n))), "
 F" ++ Nat.show(i) ++ "=" ++ U64.show(S.sf_kind(S.sf_of(SO.fd_g(EM.fg_fd(f))))) ++ " nes=" ++ Nat.show(List.length(&2, Nat, EM.fg_es(f))) ++ " box " ++ bxs(SO.fd_bx(EM.fg_fd(f))), "") ++ fk_s(t, Nat.add(i, 1n))

def fg_at(fs: List<&2, EM.Fg>, +i: Nat) -> List<&2, EM.Fg>:
  match fs:
    case []: []
    case +f <> t:
      match i:
        case 0n: [f]
        case 1n+(+j): fg_at(t, j)

def ss_s(+ss: CS.Ss, +k: U64) -> String:
  CS.Ss{+ok, +bs, +un} = ss
  "SSI k=" ++ U64.show(k) ++ " ok=" ++ (Bool.pick(String, ok, "y", "n")) ++ " brs=" ++ Nat.show(List.length(&2, CS.Br, bs)) ++ " un=" ++ Nat.show(List.length(&2, List<&2, I.I>, un))

def sr_s(+r: Y.Sr) -> String:
  Y.Sr{+ss, +k, +co} = r
  ss_s(ss, k)

def ssi2(xs: List<&2, EM.Fg>, ys: List<&2, EM.Fg>) -> String:
  match xs:
    case []: "?"
    case +x <> u:
      match ys:
        case []: "?"
        case +y <> v:
          +fa = EM.fg_fd(x)
          +fb = EM.fg_fd(y)
          sr_s(Y.inter_ss(SO.fd_g(fa), SO.fd_g(fb), X.vmeet(SO.fd_bx(fa), SO.fd_bx(fb))))

def ssi_s(+fgs: List<&2, EM.Fg>, +sel: Nat) -> String:
  Bool.pick(String, Nat.is_eq(sel, 99n), ssi2(fg_at(fgs, 34n), fg_at(fgs, 39n)), "")

def ffloop(+b: Ty.Brep, +ra: Ty.Brep, +rb: Ty.Brep, +kr: K1.KR, +sel: Nat) -> IO(Unit):
  +fs = SO.fds_re(b, SO.pool_kf(List.append(&2, SO.KF, K1.kr_fk(kr), List.append(&2, SO.KF, SO.kfs_of(ra, SO.fds_of(ra)), SO.kfs_of(rb, SO.fds_of(rb))))))
  +tg = SO.tags_or(SO.rtags_of(b, SO.vpool(ra, []), SO.vpool(rb, [])), SO.ltags(b, ra, rb))
  +et = SO.etags_of(b, SO.epool(ra, []), SO.epool(rb, []))
  +x = Ty.ix_of(b)
  +egs = EM.egs_go(Ty.brep_es(b), Ty.ix_tv(x))
  +fgs = EM.shs_fg(Ty.brep_shs(b), x, fs, Ty.shmap_of(b), 0n)
  +tgt = B.tb_of(U64, tg, 0u64)
  +prs = EM.keep_new(EM.sweep(EM.its_of(egs, fgs)), tgt, B.tb_of(U64, et, 0u64), EM.em_of(egs, fgs, tgt))
  +cx = EM.mk_cx(egs, fgs, EM.tol_of(SO.bbox(fs, [])), List.length(&2, Ty.Solid, Ty.brep_sos(b)))
  IO.print(ssi_s(fgs, sel) ++ fk_s(fgs, 0n) ++ fis(EM.run_prs(cx, L_tk(16n, L_dr(Nat.mul(16n, sel), kinds(prs, 2u64))))) ++ " sel " ++ Nat.show(sel) ++ prs_s(L_tk(16n, L_dr(Nat.mul(16n, sel), kinds(prs, 2u64)))))

def stg(mode: Nat, +ra: Ty.Brep, +rb: Ty.Brep) -> String:
  match mode:
    case 1n:
      +kr = GB.gbrun_f(False{}, 14u64, ra, rb, SO.fds_of(ra), SO.fds_of(rb))
      "k1 " ++ Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(K1.kr_brep(kr))))
    case 2n:
      +kr = GB.gbrun_f(False{}, 14u64, ra, rb, SO.fds_of(ra), SO.fds_of(rb))
      +b = K1.kr_brep(kr)
      +fs = SO.fds_re(b, SO.pool_kf(List.append(&2, SO.KF, K1.kr_fk(kr), List.append(&2, SO.KF, SO.kfs_of(ra, SO.fds_of(ra)), SO.kfs_of(rb, SO.fds_of(rb))))))
      "solid" ++ fis(SO.solid_fi(b, fs))
    case 3n:
      +kr = GB.gbrun_f(False{}, 14u64, ra, rb, SO.fds_of(ra), SO.fds_of(rb))
      +b = K1.kr_brep(kr)
      +fs = SO.fds_re(b, SO.pool_kf(List.append(&2, SO.KF, K1.kr_fk(kr), List.append(&2, SO.KF, SO.kfs_of(ra, SO.fds_of(ra)), SO.kfs_of(rb, SO.fds_of(rb))))))
      +tg = SO.tags_or(SO.rtags_of(b, SO.vpool(ra, []), SO.vpool(rb, [])), SO.ltags(b, ra, rb))
      +et = SO.etags_of(b, SO.epool(ra, []), SO.epool(rb, []))
      "emb" ++ fis(EM.emb_fi_t(b, fs, tg, et))
    case _:
      +kr = GB.gbrun_f(False{}, 14u64, ra, rb, SO.fds_of(ra), SO.fds_of(rb))
      +tm = VI.brep_vol(K1.kr_brep(kr))
      "vol " ++ Bool.pick(String, VI.vr_ok(tm), "ok", "no")

def stmain(+src: String, +sel: Nat) -> IO(Unit):
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_part(p, [])
  IO.print(stg(sel, brep_of(M.ce_r(M.ce_find(cs, 1901u64))), brep_of(M.ce_r(M.ce_find(cs, 2u64)))))

def ffmain(+src: String, +sel: Nat) -> IO(Unit):
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_part(p, [])
  +ra = brep_of(M.ce_r(M.ce_find(cs, 1901u64)))
  +rb = brep_of(M.ce_r(M.ce_find(cs, 2u64)))
  +kr = GB.gbrun(14u64, ra, rb)
  ffloop(K1.kr_brep(kr), ra, rb, kr, sel)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/home/jesse/g5/dbg.bcd")
    ffmain(src, Nat.sub(List.length(&1, String, args), 2n))
