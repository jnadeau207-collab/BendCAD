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

def pt_s(+p: V.Point) -> String:
  F64.show(V.pt_x(p)) ++ " " ++ F64.show(V.pt_y(p)) ++ " " ++ F64.show(V.pt_z(p))

def fv_s(fs: List<&2, Nat>, +b: FB.KB, +c: V.Point) -> String:
  match fs:
    case []: ""
    case +h <> +t:
      +a = VI.face_va(b, h, c)
      "face " ++ Nat.show(h) ++ " kind " ++ U64.show(KS.sf_kind(KS.sf_of(FB.face_surf(b, h)))) ++ " vol " ++ F64.show(VI.va_vol(a)) ++ " slv " ++ F64.show(VI.va_slv(a)) ++ " ar " ++ F64.show(VI.va_ar(a)) ++ "
" ++ fv_s(t, b, c)

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +ia = S.u64_of(S.Sx_a{S.arg_at(args, 2n)})
  +cs = M.ev_for(p, [ia], [])
  +b = FB.kb_of(placed(cs, ia))
  +c = VI.center_of(b)
  IO.print("center " ++ pt_s(c) ++ "
faces " ++ Nat.show(FB.nfaces(b)) ++ "
" ++ fv_s(L.nat_range(FB.nfaces(b)), b, c) ++ "end")

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
