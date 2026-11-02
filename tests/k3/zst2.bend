import Base
import ../../src/c06/sx.bend as S
import ../../src/c06/model.bend as M
import ../../src/c08/bool.bend as B8
import ../../src/k1/gb.bend as GB
import ../../src/k1/asm.bend as K1
import ../../src/k1/vi.bend as VI
import ../../src/c04/types.bend as Ty
import ../../src/k1/fb.bend as FB
import ../../src/k1/px.bend as PX
import ../../src/k1/co.bend as CO
import ../../src/c06/build.bend as BD
import ../../src/c07/ivx.bend as X
import ../../src/c07/sol.bend as SO
import ../../src/c06/iv.bend as I

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

def placed(+cs: List<&2, M.CE>, +id: U64) -> Ty.Brep:
  +b = M.nr_body(M.ce_r(M.ce_find(cs, id)))
  +pl = M.bd_pl(b)
  B8.xf_brep(M.pl_m(pl), M.pl_tx(pl), M.pl_ty(pl), M.pl_tz(pl), M.bd_brep(b))

def nf(+b: Ty.Brep) -> String:
  Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(b)))

def kr_s(+r: K1.KR) -> String:
  Bool.pick(String, K1.kr_ok(r), "ok", "refused " ++ U64.show(K1.kr_why(r))) ++ " faces " ++ nf(K1.kr_brep(r))

def vr_s(+v: B8.VR) -> String:
  Bool.pick(String, B8.VR_ok(v), "ok", B8.vcode(v))

def vol_s(+r: VI.VR) -> String:
  Bool.pick(String, VI.vr_ok(r), "ok", "fail")

def stamp(+tag: String, +t0: Nat, +t1: Nat, +s: String) -> IO(Unit):
  IO.print(tag ++ " " ++ Nat.show(Nat.sub(t1, t0)) ++ " " ++ s)

def fd_sum(fs: List<&2, SO.Fd>, +acc: F64) -> F64:
  match fs:
    case []: acc
    case +f <> t: fd_sum(t, F64.add(acc, I.i_lo(X.vn(SO.fd_bx(f), 0n))))

def kf_n(+xs: List<&2, SO.KF>) -> String:
  Nat.show(List.length(&2, SO.KF, xs))

def s7(+bc: Ty.Brep) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("genus " ++ Nat.show(B8.genus_of(bc)) ++ " vol " ++ vol_s(VI.brep_vol(bc)))
    t1 : Nat <- IO.now()
    stamp("genus+vol", t0, t1, "")

def s6(+bc: Ty.Brep, +fdc: List<&2, SO.Fd>, +ra: Ty.Brep, +fda: List<&2, SO.Fd>, +rb: Ty.Brep, +fdb: List<&2, SO.Fd>) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("fns " ++ Nat.show(List.length(&2, BD.Fn, B8.k1_fns_f(bc, fdc, ra, fda, [], rb, fdb, [], 1201u64))))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("k1_fns_f", t0, t1, "")
    s7(bc)

def s5(+bc: Ty.Brep, +fdc: List<&2, SO.Fd>, +tg: List<&2, U64>, +ra: Ty.Brep, +fda: List<&2, SO.Fd>, +rb: Ty.Brep, +fdb: List<&2, SO.Fd>) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("vcore_t " ++ vr_s(B8.vcore_t(bc, fdc, tg)))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("vcore_t", t0, t1, "")
    s6(bc, fdc, ra, fda, rb, fdb)

def tg_sum(xs: List<&2, U64>, +acc: U64) -> U64:
  match xs:
    case []: acc
    case +x <> t: tg_sum(t, U64.add(acc, x))

def s4(+bc: Ty.Brep, +fdc: List<&2, SO.Fd>, +ra: Ty.Brep, +fda: List<&2, SO.Fd>, +rb: Ty.Brep, +fdb: List<&2, SO.Fd>) -> IO(Unit):
  +tg = SO.tags_of(bc, SO.pool_kf(SO.kfs_of(ra, fda)), SO.pool_kf([]))
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("tags " ++ Nat.show(List.length(&2, U64, tg)) ++ " old " ++ U64.show(tg_sum(tg, 0u64)))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("tags", t0, t1, "")
    s5(bc, fdc, tg, ra, fda, rb, fdb)

def s3(+bc: Ty.Brep, +fk: List<&2, SO.KF>, +ra: Ty.Brep, +fda: List<&2, SO.Fd>, +rb: Ty.Brep, +fdb: List<&2, SO.Fd>) -> IO(Unit):
  +fdc = SO.fds_re(bc, SO.pool_kf(List.append(&2, SO.KF, fk, List.append(&2, SO.KF, SO.kfs_of(ra, fda), SO.kfs_of(rb, fdb)))))
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("fdc " ++ F64.show(fd_sum(fdc, 0.0f64)) ++ " kr_fk " ++ kf_n(fk))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("fdc_pooled", t0, t1, "")
    s4(bc, fdc, ra, fda, rb, fdb)

def s2b(+kr: K1.KR, +t0: Nat, +ra: Ty.Brep, +fda: List<&2, SO.Fd>, +rb: Ty.Brep, +fdb: List<&2, SO.Fd>) -> IO(Unit):
  do IO<Unit>:
    u : Unit <- IO.print("k1 " ++ kr_s(kr))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("finish_p", t0, t1, "")
    s3(B8.restamp(K1.kr_brep(kr)), K1.kr_fk(kr), ra, fda, rb, fdb)

def g7(+ra: Ty.Brep, +m: GB.EM, +ok: Bool, +why: U64, +rb: Ty.Brep, +fda: List<&2, SO.Fd>, +fdb: List<&2, SO.Fd>) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    s2b(GB.finish_p(Bool.pick(GB.EM, ok, m, GB.EM{GB.em_st(m), False{}, why}), ra,
      SO.pool_kf(List.append(&2, SO.KF, SO.kfs_of(ra, fda), SO.kfs_of(rb, fdb)))), t0, ra, fda, rb, fdb)

def g6b(+ra: Ty.Brep, +m: GB.EM, +ok: Bool, +why: U64, +t0: Nat, +rb: Ty.Brep, +fda: List<&2, SO.Fd>, +fdb: List<&2, SO.Fd>) -> IO(Unit):
  do IO<Unit>:
    u : Unit <- IO.print("emit ok " ++ Bool.pick(String, GB.em_ok(m), "1", "0") ++ " nf " ++ Nat.show(K1.as_nf(GB.em_st(m))))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("run_emit_f", t0, t1, "")
    g7(ra, m, ok, why, rb, fda, fdb)

def g6c(+ra: Ty.Brep, +ba: FB.KB, +bb: FB.KB, +va: PX.VM, +vb: PX.VM, +hs3: List<&2, PX.HX>, +cr: PX.CR, +cps: List<&2, CO.CP>, +ok: Bool, +why: U64, +fda: List<&2, SO.Fd>, +fdb: List<&2, SO.Fd>) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    g6b(ra, GB.run_emit_f(B8.tag_union(), ba, bb, PX.vm_mp(va), PX.vm_mp(vb), hs3, PX.cr_chs(cr), PX.cr_g(cr), cps, fda, fdb), ok, why, t0, FB.kb_br(bb), fda, fdb)

def g6(+ra: Ty.Brep, +ba: FB.KB, +bb: FB.KB, +va: PX.VM, +vb: PX.VM, +hs3: List<&2, PX.HX>, +cr: PX.CR, +cps: List<&2, CO.CP>, +ok: Bool, +why: U64) -> IO(Unit):
  +fda = SO.fds_of(ra)
  +fdb = SO.fds_of(FB.kb_br(bb))
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("operand fds " ++ F64.show(F64.add(fd_sum(fda, 0.0f64), fd_sum(fdb, 0.0f64))))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("operand_fds_unpooled", t0, t1, "")
    g6c(ra, ba, bb, va, vb, hs3, cr, cps, ok, why, fda, fdb)

def g5d(+ra: Ty.Brep, +ba: FB.KB, +bb: FB.KB, +va: PX.VM, +vb: PX.VM, +cps: List<&2, CO.CP>, +hs2: List<&2, PX.HX>, +cr: PX.CR, +ok: Bool, +why: U64) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("chain_hits " ++ Nat.show(List.length(&2, PX.HX, PX.chain_hits(PX.cr_chs(cr), ba, bb, PX.cr_g(cr), hs2))))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("chain_hits", t0, t1, "")
    g6(ra, ba, bb, va, vb, PX.chain_hits(PX.cr_chs(cr), ba, bb, PX.cr_g(cr), hs2), cr, cps, ok, why)

def g5c(+ra: Ty.Brep, +ba: FB.KB, +bb: FB.KB, +va: PX.VM, +vb: PX.VM, +hs: PX.HS, +cps: List<&2, CO.CP>, +cx: CO.CX, +hs2: List<&2, PX.HX>) -> IO(Unit):
  +cr = PX.all_chains(hs2, ba, bb, CO.cx_g(cx))
  +ok = Bool.and(Bool.and(PX.hs_ok(hs), CO.cx_ok(cx)), PX.cr_ok(cr))
  +why = Bool.pick(U64, PX.hs_ok(hs), Bool.pick(U64, CO.cx_ok(cx), PX.cr_why(cr), 97u64), PX.hs_why(hs))
  g5d(ra, ba, bb, va, vb, cps, hs2, cr, ok, why)

def g5b(+ra: Ty.Brep, +ba: FB.KB, +bb: FB.KB, +va: PX.VM, +vb: PX.VM, +hs: PX.HS, +cps: List<&2, CO.CP>, +cx: CO.CX, +hs2: List<&2, PX.HX>) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("chains " ++ Nat.show(List.length(&2, PX.CH, PX.cr_chs(PX.all_chains(hs2, ba, bb, CO.cx_g(cx))))))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("all_chains", t0, t1, "")
    g5c(ra, ba, bb, va, vb, hs, cps, cx, hs2)

def g5(+ra: Ty.Brep, +ba: FB.KB, +bb: FB.KB, +va: PX.VM, +vb: PX.VM, +hs: PX.HS, +cps: List<&2, CO.CP>, +cx: CO.CX, +hs2: List<&2, PX.HX>) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("hits2 " ++ Nat.show(List.length(&2, PX.HX, hs2)))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("hits2", t0, t1, "")
    g5b(ra, ba, bb, va, vb, hs, cps, cx, hs2)

def g4b(+ra: Ty.Brep, +ba: FB.KB, +bb: FB.KB, +va: PX.VM, +vb: PX.VM, +hs: PX.HS, +cps: List<&2, CO.CP>) -> IO(Unit):
  +cx0 = CO.crossings(cps, ba, bb, PX.hs_g(hs))
  +tj = CO.tjunctions(cps, ba, bb, CO.cx_g(cx0))
  +cx = {CO.CX{List.append(&2, PX.HX, CO.cx_hs(cx0), CO.cx_hs(tj)), CO.cx_g(tj), Bool.and(CO.cx_ok(cx0), CO.cx_ok(tj))} : CO.CX}
  g5(ra, ba, bb, va, vb, hs, cps, cx, List.append(&2, PX.HX, PX.hs_hs(hs), CO.cx_hs(cx)))

def g4(+ra: Ty.Brep, +ba: FB.KB, +bb: FB.KB, +va: PX.VM, +vb: PX.VM, +hs: PX.HS, +cps: List<&2, CO.CP>) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("crossings " ++ Nat.show(List.length(&2, PX.HX, CO.cx_hs(CO.crossings(cps, ba, bb, PX.hs_g(hs))))))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("crossings+tj", t0, t1, "")
    g4b(ra, ba, bb, va, vb, hs, cps)

def g3(+ra: Ty.Brep, +ba: FB.KB, +bb: FB.KB, +va: PX.VM, +vb: PX.VM, +hs: PX.HS) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("coin_pairs " ++ Nat.show(List.length(&2, CO.CP, CO.coin_pairs(ba, bb))))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("coin_pairs", t0, t1, "")
    g4(ra, ba, bb, va, vb, hs, CO.coin_pairs(ba, bb))

def g2(+ra: Ty.Brep, +ba: FB.KB, +bb: FB.KB, +va: PX.VM, +vb: PX.VM) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("hits " ++ Nat.show(List.length(&2, PX.HX, PX.hs_hs(PX.all_hits(ba, bb, PX.vm_g(vb))))))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("all_hits", t0, t1, "")
    g3(ra, ba, bb, va, vb, PX.all_hits(ba, bb, PX.vm_g(vb)))

def s2(+ra: Ty.Brep, +rb: Ty.Brep) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("kb faces " ++ Nat.show(FB.nfaces(FB.kb_of(ra))) ++ " " ++ Nat.show(FB.nfaces(FB.kb_of(rb))))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("kb_of", t0, t1, "")
    g2(ra, FB.kb_of(ra), FB.kb_of(rb), PX.add_vs(Ty.brep_vs(ra), PX.GV{[], 0n}, []), PX.add_vs(Ty.brep_vs(rb), PX.vm_g(PX.add_vs(Ty.brep_vs(ra), PX.GV{[], 0n}, [])), []))

def s1b(+ba: Ty.Brep, +bb: Ty.Brep, +t0: Nat) -> IO(Unit):
  do IO<Unit>:
    u : Unit <- IO.print("operand faces " ++ nf(ba) ++ " " ++ nf(bb))
    t1 : Nat <- IO.now()
    v : Unit <- stamp("eval", t0, t1, "")
    s2(ba, bb)

def s1(+p: M.Part, +a: U64, +b: U64, +t0: Nat) -> IO(Unit):
  +cs = M.ev_for(p, [a, b], [])
  s1b(placed(cs, a), placed(cs, b), t0)

def stages(+p: M.Part, +a: U64, +b: U64) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    s1(p, a, b, t0)

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  stages(S.part_of(S.ps_xs(S.parse(src))), S.u64_of(S.Sx_a{S.arg_at(args, 2n)}), S.u64_of(S.Sx_a{S.arg_at(args, 3n)}))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
