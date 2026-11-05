import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c04/ops.bend as O
import ../../src/c06/model.bend as M
import ../../src/c08/bool.bend as B8
import ../../src/c06/sx.bend as SX
import ../../src/k1/sf.bend as S
import ../../src/k1/gb.bend as GB
import ../../src/k1/asm.bend as K1
import ../../src/k1/ef.bend as EF
import ../../src/k1/ss.bend as SS
import ../../src/k1/fb.bend as FB
import ../../src/c03/ops.bend as GOP

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

def yn(+b: Bool) -> String:
  Bool.pick(String, b, "y", "n")

def t1(+kb: FB.KB, +i: Nat, +p: V.Point) -> String:
  +s = FB.face_sf(kb, i)
  +q = FB.uv_raw(s, p)
  " f" ++ Nat.show(i) ++ " k" ++ U64.show(S.sf_kind(s)) ++ " in=" ++ yn(FB.pt_in_face(kb, i, p)) ++ " near=" ++ yn(FB.bnd_near(kb, i, p)) ++ " uv=" ++ F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q))

def pts(xs: List<&2, V.Vec2>) -> String:
  match xs:
    case []: ""
    case +h <> t: "(" ++ F64.show(V.v2_x(h)) ++ "," ++ F64.show(V.v2_y(h)) ++ ")" ++ pts(t)

def polys(xs: List<&2, List<&2, V.Vec2>>) -> String:
  match xs:
    case []: ""
    case +h <> t: " [" ++ pts(h) ++ "]" ++ polys(t)

def run(+src: String, +b: U64) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_for(p, [b], [])
  +kb = FB.kb_of(brep_of(M.ce_r(M.ce_find(cs, b))))
  +q = S.pt(22.951912768818055f64, F64.neg(0.35656890856412743f64), 4.367058393093676f64)
  +r = S.pt(22.951912768818055f64, 0.35656890856412743f64, 4.367058393093676f64)
  "neg:" ++ t1(kb, 2n, q) ++ t1(kb, 3n, q) ++ "
pos:" ++ t1(kb, 2n, r) ++ t1(kb, 3n, r) ++ "
poly2" ++ polys(FB.face_polys(kb, 2n)) ++ "
poly3" ++ polys(FB.face_polys(kb, 3n))

def num(+s: String) -> U64:
  SX.u64_of(SX.Sx_a{s})

def to2(xs: List<&1, String>) -> List<&2, String>:
  match xs:
    case []: []
    case h <> t: h <> to2(t)

def go(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(SX.arg_at(args, 1n))
    IO.print(run(src, num(SX.arg_at(args, 2n))))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(to2(args))
