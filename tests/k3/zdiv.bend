import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c01/types.bend as V
import ../../src/k1/fb.bend as FB
import ../../src/k1/ls.bend as L
import ../../src/k1/vi.bend as VI
import ../../src/k3/div.bend as D
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

def body_of(cs: List<&2, M.CE>, +id: U64) -> M.Body:
  M.nr_body(M.ce_r(M.ce_find(cs, id)))

def pt_s(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

def sk_s(+g: G.GVal) -> String:
  match g:
    case G.GV_pl{w}: "plane"
    case G.GV_cy{w}: "cylinder"
    case G.GV_to{w}:
      G.To{+o, +a, +bigr, +r} = w
      "torus o=" ++ pt_s(o) ++ " R=" ++ F64.show(bigr) ++ " r=" ++ F64.show(r)
    case G.GV_sp{w}: "sphere"
    case G.GV_co{w}: "cone"
    case _: "other"

def mv_s(+m: D.MV) -> String:
  D.MV{+v, x, y, z, xx, yy, zz, xy, yz, zx} = m
  F64.show(v)

def face_s(fs: List<&2, Nat>, +b: Ty.Brep, +c: V.Point) -> String:
  match fs:
    case []: ""
    case +f <> +t:
      +p = D.face_mp(b, f, c)
      +a = VI.face_va(b, f, c)
      "face " ++ Nat.show(f) ++ " " ++ sk_s(FB.face_surf(b, f)) ++ " same=" ++ Bool.pick(String, FB.face_same(b, f), "1", "0") ++ " m=" ++ mv_s(D.mp_m(p)) ++ " e=" ++ mv_s(D.mp_e(p)) ++
        " va.vol=" ++ F64.show(VI.va_vol(a)) ++ " slv=" ++ F64.show(VI.va_slv(a)) ++ " ok=" ++ Bool.pick(String, VI.va_ok(a), "1", "0") ++ "
" ++ face_s(t, b, c)

def mr_s(+r: D.MR) -> String:
  D.MR{+c2, +m, +e, +slv, +rad, ar, sla} = r
  +v = M.i_nth(D.mv_iv(m, e, slv, rad), 0n)
  "slv=" ++ F64.show(slv) ++ " rad=" ++ F64.show(rad) ++ " v=[" ++ F64.show(I.i_lo(v)) ++ "," ++ F64.show(I.i_hi(v)) ++ "]
"

def run(+src: String) -> String:
  +cs = M.ev_part(S.part_of(S.ps_xs(S.parse(src))), [])
  +b = M.bd_brep(body_of(cs, 3u64))
  +c = VI.center_of(b)
  +w = M.ms_vol(M.body_ms(body_of(cs, 3u64)))
  "center " ++ pt_s(c) ++ " body=[" ++ F64.show(I.i_lo(w)) ++ "," ++ F64.show(I.i_hi(w)) ++ "]
" ++ mr_s(D.brep_mom(b))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/tmp/zp.bcd")
    IO.print(run(src))
