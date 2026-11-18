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
import ../../src/c07/sol.bend as SO
import ../../src/c06/iv.bend as I
import ../../src/c06/build.bend as BD
import ../../src/k1/ss.bend as SS
import ../../src/k1/sf.bend as KS
import ../../src/c03/types.bend as G
import ../../src/c01/types.bend as V
import ../../src/k1/ef.bend as EF
import ../../src/k1/ls.bend as L

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

def gk(c: G.GVal) -> String:
  match c:
    case G.GV_ln{w}: "ln"
    case G.GV_cc{w}: "cc"
    case G.GV_bz{w}: "bz"
    case _: "g"

def pt_s(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

def line_s(+side: U64, +e: Nat, +fo: Nat, +k: Ty.EdgeKind, +nt: F64, +q: V.Point, +ob: FB.KB) -> String:
  "side " ++ U64.show(side) ++ " edge " ++ Nat.show(e) ++ " " ++ gk(EF.ek_curve(k)) ++ " [" ++ F64.show(EF.ek_lo(k)) ++ "," ++ F64.show(EF.ek_hi(k)) ++ "] face " ++ Nat.show(fo) ++
    " kind " ++ U64.show(KS.sf_kind(KS.sf_of(FB.face_surf(ob, fo)))) ++ " nt " ++ F64.show(nt) ++ " q " ++ pt_s(q) ++ "
"

def nr_s(inp: Bool, +e: Nat, +fo: Nat, +r: EF.EHS, +side: U64, +b: FB.KB, +ob: FB.KB) -> String:
  match inp:
    case True{}: ""
    case False{}:
      +k = Ty.ed_kind(FB.edge_at(b, e))
      +nt = EF.ehs_nt(r)
      +q = EF.ev(EF.ek_curve(k), nt)
      +bad = PX.near_bad(PX.near_on(EF.ehs_near(r), ob, fo, q), k, nt, ob)
      Bool.pick(String, bad, line_s(side, e, fo, k, nt, q, ob), "")

def ej_s(+j: PX.EJ, +side: U64, +b: FB.KB, +ob: FB.KB) -> String:
  PX.EJ{+e, +fo, +inp, +r} = j
  nr_s(inp, e, fo, r, side, b, ob)

def eps_s(ps: List<&2, PX.EP>, +side: U64, +b: FB.KB, +ob: FB.KB) -> String:
  match ps:
    case []: ""
    case +p <> +t:
      PX.EP{+e, +fo} = p
      ej_s(PX.ej_one(b, ob, e, fo), side, b, ob) ++ eps_s(t, side, b, ob)

def side_s(+side: U64, +b: FB.KB, +ob: FB.KB) -> String:
  eps_s(PX.ep_all(L.nat_range(FB.nedges(b)), b, PX.fbs_of(FB.nfaces(ob), ob, [])), side, b, ob)

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +ia = S.u64_of(S.Sx_a{S.arg_at(args, 2n)})
  +ib = S.u64_of(S.Sx_a{S.arg_at(args, 3n)})
  +cs = M.ev_for(p, [ia, ib], [])
  +ba = FB.kb_of(placed(cs, ia))
  +bb = FB.kb_of(placed(cs, ib))
  IO.print("edges " ++ Nat.show(FB.nedges(ba)) ++ " " ++ Nat.show(FB.nedges(bb)) ++ "
" ++ side_s(0u64, ba, bb) ++ side_s(1u64, bb, ba) ++ "end")

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
