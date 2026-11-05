import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as SX
import ../../src/c06/tess.bend as TS
import ../../src/c10/mesh.bend as M10
import ../../src/k1/sf.bend as S
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

def ud(n: Nat, xs: List<&2, U64>, ys: List<&2, U64>, +acc: List<&2, U64>) -> List<&2, U64>:
  match n:
    case 0n: acc
    case 1n+(+m):
      match xs:
        case []: acc
        case +x <> +xt:
          match ys:
            case []: ud(m, xt, [], x <> acc)
            case +y <> +yt:
              +eq = U64.is_eq(x, y)
              +lt = U64.is_lt(x, y)
              ud(m, Bool.pick(List<&2, U64>, Bool.or(eq, lt), xt, x <> xt), Bool.pick(List<&2, U64>, lt, y <> yt, yt),
                Bool.pick(List<&2, U64>, Bool.and(Bool.not(eq), lt), x <> acc, acc))

def ud_c(c: U64, n: Nat, +x: U64, +xt: List<&2, U64>, +y: U64, +yt: List<&2, U64>, +acc: List<&2, U64>) -> List<&2, U64>:
  match c:
    case 0u64: ud(n, xt, yt, acc)
    case 1u64: ud(n, xt, y <> yt, x <> acc)
    case _: ud(n, x <> xt, yt, acc)

def sk(+xs: List<&2, U64>) -> List<&2, U64>:
  TS.so_u(B.msort(~U64, ~TS.u_cmp, xs))

def kshow(n: Nat, xs: List<&2, U64>) -> String:
  match n:
    case 0n: ""
    case 1n+(+m):
      match xs:
        case []: ""
        case +x <> t: " (" ++ U64.show(U64.div(x, 4294967296u64)) ++ "," ++ U64.show(U64.mod(x, 4294967296u64)) ++ ")" ++ kshow(m, t)

def unm_s(+ts: List<&2, TS.Tri>) -> String:
  +es = TS.dir_es(ts, [], [])
  +f = sk(TS.es_hd(es))
  +b = sk(TS.es_tl(es))
  +u = ud(Nat.mul(2n, Nat.add(List.length(&2, U64, f), List.length(&2, U64, b))), f, b, [])
  Nat.show(List.length(&2, U64, u)) ++ kshow(12n, u)

def tg_s(+r: TS.TGO) -> String:
  TS.TGO{+ts, +ps, +ok} = r
  " ok=" ++ Bool.pick(String, ok, "y", "n") ++ " tris=" ++ Nat.show(List.length(&2, TS.Tri, ts)) ++ " new=" ++ Nat.show(List.length(&2, V.Point, ps)) ++ " closed=" ++ Bool.pick(String, TS.closed(ts), "y", "n") ++ " unm=" ++ unm_s(ts)

def fs_s(fs: List<&2, Ty.Face>, +x: TS.Ctx, +tb: B.Tb<&2, V.Point>, +i: Nat, +gb: Nat) -> String:
  match fs:
    case []: ""
    case +f <> t:
      +u = TS.use_gen(f, x)
      +r = TS.face_tg(u, f, x, tb, 0n, gb, 0.01f64)
      "\nF" ++ Nat.show(i) ++ " k" ++ U64.show(S.sf_kind(S.sf_of(Ty.fa_surf(f)))) ++ " gen=" ++ Bool.pick(String, u, "y", "n") ++ tg_s(r) ++
        fs_s(t, x, tb, Nat.add(i, 1n), Nat.add(gb, TS.gt_np(r)))

def run_b(r: M.NR) -> String:
  match r:
    case M.NR_err{k, d}: "node failed"
    case M.NR_ok{+b, fx}:
      +br = M.bd_brep(b)
      +q = M10.q_preset(1u64)
      +ps = TS.all_pts(br, q)
      +all = List.append(&2, V.Point, ps, TS.bp_ps_of(Ty.brep_fas(br)))
      +tb = B.tb_of(V.Point, all, TS.pz())
      +x = TS.ctx_of(br, q)
      +gt = TS.faces_tg(Ty.brep_fas(br), x, tb, List.length(&2, V.Point, ps), List.length(&2, V.Point, all), M10.q_chord(q))
      "faces " ++ Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(br))) ++ tg_s(gt) ++ fs_s(Ty.brep_fas(br), x, tb, 0n, List.length(&2, V.Point, all))

def run(+src: String) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_part(p, [])
  +r = M.ce_r(M.ce_find(cs, 1930u64))
  run_b(r)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/home/jesse/g5/imp_t.bcd")
    IO.print(run(src))
