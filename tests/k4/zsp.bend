import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c03/types.bend as G
import ../../src/c06/model.bend as M
import ../../src/c08/bool.bend as B8
import ../../src/c06/sx.bend as SX
import ../../src/k1/sf.bend as S
import ../../src/k1/fb.bend as FB
import ../../src/k1/px.bend as PX
import ../../src/k1/co.bend as CO
import ../../src/k1/gw.bend as W
import ../../src/k1/ls.bend as L
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
    case M.NR_ok{+b, fx}: B8.bake_of(M.bool_in(b))
    case M.NR_err{k, d}: Ty.brep_empty()

def hit1(+h: PX.HX, +ps: List<&2, V.Point>, +cl: List<&2, V.Point>) -> String:
  +sd = PX.near_sd(cl, PX.hx_p(h), L.nth_p(ps, 0n), 0n, 0n, F64.div(1.0f64, 0.0f64))
  +i = PX.nb2_i(sd)
  +sl = S.dist(L.nth_p(ps, i), L.nth_p(cl, i))
  " hit d=" ++ F64.show(PX.nb2_d(sd)) ++ " sl=" ++ F64.show(sl) ++ " on=" ++ Bool.pick(String, F64.is_le(PX.nb2_d(sd), F64.add(F64.mul(0.25f64, sl), 1.0e-9f64)), "y", "n")

def hits_s(hs: List<&2, PX.HX>, +ps: List<&2, V.Point>, +cl: List<&2, V.Point>) -> String:
  match hs:
    case []: ""
    case +h <> t: hit1(h, ps, cl) ++ hits_s(t, ps, cl)

def p3s(+p: V.Point) -> String:
  "(" ++ F64.show(S.px(p)) ++ "," ++ F64.show(S.py(p)) ++ "," ++ F64.show(S.pz(p)) ++ ")"

def runs_s(rs: List<&2, List<&2, PX.PP>>, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat) -> String:
  match rs:
    case []: ""
    case +h <> t: "
     run n=" ++ Nat.show(List.length(&2, PX.PP, h)) ++ " side=" ++ U64.show(PX.run_side(ba, fa, bb, fb, PX.mid_pp(h))) ++ " mid=" ++ p3s(PX.mid_pp(h)) ++ runs_s(t, ba, fa, bb, fb)

def ic_r(+c: SS.IC, +hs: List<&2, PX.HX>, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat) -> String:
  +xs = PX.ins_brk_c(hs, SS.ic_closed(c), PX.pv_xs(PX.reg_pts(SS.ic_pts(c), PX.GV{[], 0n}, [])))
  runs_s(PX.poly_split_o(xs, [], []), ba, fa, bb, fb)

def ic_s(cs: List<&2, SS.IC>, +hs: List<&2, PX.HX>, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat) -> String:
  match cs:
    case []: ""
    case +c <> t:
      +ps = SS.ic_pts(c)
      +cl = List.append(&2, V.Point, PX.L_tail(ps), [L.nth_p(ps, 0n)])
      "
   ic kind " ++ U64.show(SS.ic_kind(c)) ++ " n " ++ Nat.show(List.length(&2, V.Point, ps)) ++ " closed " ++ Bool.pick(String, SS.ic_closed(c), "y", "n") ++ " hits " ++ Nat.show(List.length(&2, PX.HX, hs)) ++ hits_s(hs, ps, cl) ++ ic_r(c, hs, ba, fa, bb, fb) ++ ic_s(t, hs, ba, fa, bb, fb)

def pj_s(js: List<&2, PX.PJ>, +ba: FB.KB, +bb: FB.KB) -> String:
  match js:
    case []: ""
    case +j <> t:
      PX.PJ{+fa, +fb, +x, +ph} = j
      Bool.pick(String, Bool.and(Bool.or(Nat.is_eq(fb, 2n), Nat.is_eq(fb, 3n)), S.is_bp(FB.face_sf(ba, fa))), "
JOB " ++ Nat.show(fa) ++ "/" ++ Nat.show(fb) ++ ic_s(SS.ics_ics(x), ph, ba, fa, bb, fb), "") ++ pj_s(t, ba, bb)

def kinds2(js: List<&2, PX.PJ>, +ba: FB.KB, +bb: FB.KB) -> String:
  match js:
    case []: ""
    case +j <> t:
      PX.PJ{+fa, +fb, +x, ph} = j
      Bool.pick(String, U64.is_eq(SS.ics_why(x), 0u64), "", " [" ++ Nat.show(fa) ++ "k" ++ U64.show(S.sf_kind(FB.face_sf(ba, fa))) ++ "/" ++ Nat.show(fb) ++ "k" ++ U64.show(S.sf_kind(FB.face_sf(bb, fb))) ++ " why" ++ U64.show(SS.ics_why(x)) ++ "]") ++ kinds2(t, ba, bb)

def run(+src: String, +na: U64, +nb: U64) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_for(p, [na, nb], [])
  +ra = brep_of(M.ce_r(M.ce_find(cs, na)))
  +rb = brep_of(M.ce_r(M.ce_find(cs, nb)))
  +ba = FB.kb_of(ra)
  +bb = FB.kb_of(rb)
  +va = PX.add_vs(Ty.brep_vs(ra), PX.GV{[], 0n}, [])
  +vb = PX.add_vs(Ty.brep_vs(rb), PX.vm_g(va), [])
  +hs = PX.all_hits(ba, bb, PX.vm_g(vb))
  +c = {PX.PC{PX.faces_bb(L.nat_range(FB.nfaces(bb)), bb), PX.faces_wd(L.nat_range(FB.nfaces(bb)), bb), PX.faces_rho(L.nat_range(FB.nfaces(bb)), bb), PX.hs_hs(hs), ba, bb} : PX.PC}
  +js = List.concat(&2, PX.PJ, B.pmap_g(~Nat, ~PX.PC, ~List<&2, PX.PJ>, ~PX.pj_job, 1, c, L.nat_range(FB.nfaces(ba))))
  "faces " ++ Nat.show(FB.nfaces(ba)) ++ " " ++ Nat.show(FB.nfaces(bb)) ++ " hs_ok " ++ (Bool.pick(String, PX.hs_ok(hs), "y", "n")) ++ " why " ++ U64.show(PX.hs_why(hs)) ++ " jobs " ++ Nat.show(List.length(&2, PX.PJ, js)) ++ kinds2(js, ba, bb) ++ pj_s(js, ba, bb)

def num(+s: String) -> U64:
  SX.u64_of(SX.Sx_a{s})

def to2(xs: List<&1, String>) -> List<&2, String>:
  match xs:
    case []: []
    case h <> t: h <> to2(t)

def go2(+src: String, +args: List<&2, String>) -> IO(Unit):
  IO.print(run(src, num(SX.arg_at(args, 2n)), num(SX.arg_at(args, 3n))))

def go(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(SX.arg_at(args, 1n))
    go2(src, args)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(to2(args))
