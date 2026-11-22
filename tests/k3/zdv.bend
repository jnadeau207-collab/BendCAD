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

def pt3(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

def seg_a(+s: PX.SEG) -> V.Point:
  PX.bz_at(PX.seg_k(s), 0.0f64)

def seg_b(+s: PX.SEG) -> V.Point:
  PX.bz_at(PX.seg_k(s), 1.0f64)

def seg_d(+s: PX.SEG, +s1: SF.SF, +s2: SF.SF) -> F64:
  PX.seg_dev(s1, s2, PX.seg_k(s))

def worst(ss: List<&2, PX.SEG>, +s1: SF.SF, +s2: SF.SF, +bd: F64, +ba: V.Point, +bb: V.Point) -> String:
  match ss:
    case []: " worst " ++ F64.show(bd) ++ " from " ++ pt3(ba) ++ " to " ++ pt3(bb) ++ " len " ++ F64.show(SF.dist(ba, bb))
    case +h <> +t:
      +d = seg_d(h, s1, s2)
      +b = F64.is_lt(bd, d)
      worst(t, s1, s2, Bool.pick(F64, b, d, bd), Bool.pick(V.Point, b, seg_a(h), ba), Bool.pick(V.Point, b, seg_b(h), bb))

def chs_dv(cs: List<&2, PX.CH>, +ba: FB.KB, +bb: FB.KB) -> String:
  match cs:
    case []: ""
    case +c <> +t:
      PX.CH{+fa, +fb, +ss, ps, cl, +dv} = c
      +s1 = SF.sf_of(FB.face_surf(ba, fa))
      +s2 = SF.sf_of(FB.face_surf(bb, fb))
      Bool.pick(String, F64.is_lt(1.0e-3f64, dv), "ch " ++ Nat.show(fa) ++ " " ++ Nat.show(fb) ++ " kinds " ++ U64.show(SF.sf_kind(s1)) ++ "/" ++ U64.show(SF.sf_kind(s2)) ++ " dv " ++ F64.show(dv) ++ " segs " ++ Nat.show(List.length(&2, PX.SEG, ss)) ++ worst(ss, s1, s2, 0.0f64, SF.pt(0.0f64, 0.0f64, 0.0f64), SF.pt(0.0f64, 0.0f64, 0.0f64)) ++ "
", "") ++ chs_dv(t, ba, bb)

def dvs(+ba: FB.KB, +bb: FB.KB) -> String:
  +va = PX.add_vs(Ty.brep_vs(FB.kb_br(ba)), PX.GV{[], 0n}, [])
  +vb = PX.add_vs(Ty.brep_vs(FB.kb_br(bb)), PX.vm_g(va), [])
  +hs = PX.all_hits(ba, bb, PX.vm_g(vb))
  +cps = CO.coin_pairs(ba, bb)
  +cx0 = CO.crossings(cps, ba, bb, PX.hs_g(hs))
  +tj = CO.tjunctions(cps, ba, bb, CO.cx_g(cx0))
  +hs2 = List.append(&2, PX.HX, PX.hs_hs(hs), List.append(&2, PX.HX, CO.cx_hs(cx0), CO.cx_hs(tj)))
  +cr = PX.all_chains(hs2, ba, bb, CO.cx_g(tj))
  "chains " ++ Nat.show(List.length(&2, PX.CH, PX.cr_chs(cr))) ++ "
" ++ chs_dv(PX.cr_chs(cr), ba, bb) ++ "end"

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +ia = S.u64_of(S.Sx_a{S.arg_at(args, 2n)})
  +ib = S.u64_of(S.Sx_a{S.arg_at(args, 3n)})
  +cs = M.ev_for(p, [ia, ib], [])
  IO.print(dvs(FB.kb_of(placed(cs, ia)), FB.kb_of(placed(cs, ib))))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
