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

def kind_s(+g: G.GVal) -> String:
  U64.show(KS.sf_kind(KS.sf_of(g)))

def pair_s(+ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat) -> String:
  +x = SS.ssi_b(FB.face_surf(ba, fa), FB.face_surf(bb, fb), PX.pj_box(FB.face_bb(ba, fa), FB.face_bb(bb, fb)))
  "pair " ++ Nat.show(fa) ++ " " ++ Nat.show(fb) ++ " kinds " ++ kind_s(FB.face_surf(ba, fa)) ++ "/" ++ kind_s(FB.face_surf(bb, fb)) ++
    " ics " ++ Nat.show(List.length(&2, SS.IC, SS.ics_ics(x))) ++ " why " ++ U64.show(SS.ics_why(x)) ++ "
"

def row(n: Nat, +ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat) -> String:
  match n:
    case 0n: ""
    case 1n+m: pair_s(ba, fa, bb, fb) ++ row(m, ba, fa, bb, Nat.add(fb, 1n))

def rows(n: Nat, +ba: FB.KB, +fa: Nat, +bb: FB.KB) -> String:
  match n:
    case 0n: ""
    case 1n+m: row(FB.nfaces(bb), ba, fa, bb, 0n) ++ rows(m, ba, Nat.add(fa, 1n), bb)

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +ia = S.u64_of(S.Sx_a{S.arg_at(args, 2n)})
  +ib = S.u64_of(S.Sx_a{S.arg_at(args, 3n)})
  +cs = M.ev_for(p, [ia, ib], [])
  +ba = FB.kb_of(placed(cs, ia))
  +bb = FB.kb_of(placed(cs, ib))
  IO.print(rows(FB.nfaces(ba), ba, 0n, bb))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
