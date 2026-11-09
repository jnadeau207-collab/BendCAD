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
  "(" ++ F64.show(S.px(q)) ++ "," ++ F64.show(S.py(q)) ++ "," ++ F64.show(S.pz(q)) ++ ")"

def gk(+g: G3.GVal) -> String:
  match g:
    case G3.GV_ln{w}: "ln"
    case G3.GV_cc{w}: "cc"
    case G3.GV_rq{w}: "rq"
    case G3.GV_bz{w}: "bz"
    case _: "other"

def onl(gs: List<&2, G3.GVal>, +p: V.Point) -> String:
  match gs:
    case []: ""
    case +h <> +t: Bool.pick(String, EF.on_g(h, p), "1", "0") ++ onl(t, p)

def hs_s(hs: List<&2, EF.EH>, +ka: List<&2, Ty.EdgeKind>, +lob: F64, +hib: F64, +gs: List<&2, G3.GVal>) -> String:
  match hs:
    case []: ""
    case +h <> +t:
      +p = EF.eh_p(h)
      +tb = EF.eh_t(h)
      +ta = CO.ta_of(ka, p)
      +kk = CO.ek1(ka)
      "   hit tb " ++ F64.show(tb) ++ " ta " ++ F64.show(ta) ++ " ok " ++ Bool.pick(String, EF.eh_ok(h), "y", "n") ++ " inb " ++
        Bool.pick(String, CO.strict_in(tb, lob, hib), "y", "n") ++ " ina " ++ Bool.pick(String, CO.strict_in(ta, EF.ek_lo(kk), EF.ek_hi(kk)), "y", "n") ++
        " dist " ++ F64.show(S.dist(EF.ev(EF.ek_curve(kk), ta), p)) ++ " on " ++ onl(gs, p) ++ " p " ++ p3s(p) ++ "
" ++ hs_s(t, ka, lob, hib, gs)

def ep_s(es: List<&2, CO.EP>, +ba: FB.KB, +bb: FB.KB) -> String:
  match es:
    case []: ""
    case +e <> +t:
      +ea = CO.ep_ea(e)
      +eb = CO.ep_eb(e)
      +ka = {[Ty.ed_kind(FB.edge_at(ba, ea))] : List<&2, Ty.EdgeKind>}
      +kb = {[Ty.ed_kind(FB.edge_at(bb, eb))] : List<&2, Ty.EdgeKind>}
      +ex = CO.extr_of(ka, CO.ep_n(e))
      +gs = List.append(&2, G3.GVal, CO.surfs(FB.edge_faces(ba, ea), ba), CO.surfs(FB.edge_faces(bb, eb), bb))
      +ok = Bool.not(Nat.is_eq(List.length(&2, G3.GVal, ex), 0n))
      +on = Bool.and(ok, Bool.or(PX.in_plane(CO.ek1(kb), S.sf_of(CO.g1(ex))), PX.on_cyl(CO.ek1(kb), S.sf_of(CO.g1(ex)))))
      +r = EF.edge_hits(CO.ek1(kb), S.sf_of(CO.g1(ex)), gs)
      +hs = Bool.pick(List<&2, EF.EH>, Bool.and(ok, Bool.not(on)), EF.ehs_hs(r), [])
      "ep " ++ Nat.show(ea) ++ " " ++ gk(EF.ek_curve(CO.ek1(ka))) ++ " x " ++ Nat.show(eb) ++ " " ++ gk(EF.ek_curve(CO.ek1(kb))) ++
        " ex " ++ Bool.pick(String, ok, "y", "n") ++ " on " ++ Bool.pick(String, on, "y", "n") ++ " nh " ++ Nat.show(List.length(&2, EF.EH, hs)) ++ "
" ++ hs_s(hs, ka, EF.ek_lo(CO.ek1(kb)), EF.ek_hi(CO.ek1(kb)), gs) ++ ep_s(t, ba, bb)

def run(+src: String, +na: U64, +nb: U64) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_for(p, [na, nb], [])
  +ra = brep_of(M.ce_r(M.ce_find(cs, na)))
  +rb = brep_of(M.ce_r(M.ce_find(cs, nb)))
  +ba = FB.kb_of(ra)
  +bb = FB.kb_of(rb)
  +cps = CO.coin_pairs(ba, bb)
  +cx = CO.crossings(cps, ba, bb, PX.GV{[], 0n})
  "ncp " ++ Nat.show(List.length(&2, CO.CP, cps)) ++ " cx ok " ++ Bool.pick(String, CO.cx_ok(cx), "y", "n") ++ "
" ++ ep_s(CO.edge_pairs(cps, ba, bb, []), ba, bb)

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
