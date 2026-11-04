import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c03/types.bend as G
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as SX
import ../../src/k1/sf.bend as S
import ../../src/k1/fb.bend as FB
import ../../src/k1/px.bend as PX
import ../../src/k1/co.bend as CO
import ../../src/k1/gw.bend as W
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
    case M.NR_ok{+b, fx}: M.bd_brep(b)
    case M.NR_err{k, d}: Ty.brep_empty()

def ivs(+a: I.I) -> String:
  "[" ++ F64.show(I.i_lo(a)) ++ "," ++ F64.show(I.i_hi(a)) ++ "]"

def bxs(xs: List<&2, I.I>) -> String:
  match xs:
    case []: ""
    case +h <> t: ivs(h) ++ bxs(t)

def fis(xs: List<&2, SO.Fi>) -> String:
  match xs:
    case []: ""
    case +h <> t:
      SO.Fi{+c, +a, +b} = h
      " " ++ c ++ ":" ++ Nat.show(a) ++ "/" ++ Nat.show(b) ++ fis(t)

def fd_at(fs: List<&2, SO.Fd>, +i: Nat) -> List<&2, SO.Fd>:
  match fs:
    case []: []
    case +f <> t:
      match i:
        case 0n: [f]
        case 1n+(+j): fd_at(t, j)

def uns(us: List<&2, List<&2, I.I>>, +n: Nat) -> String:
  match us:
    case []: ""
    case +h <> t:
      match n:
        case 0n: ""
        case 1n+(+k): "
   un " ++ bxs(h) ++ uns(t, k)

def ss_s(+ss: CS.Ss, +k: U64) -> String:
  CS.Ss{+ok, +bs, +un} = ss
  "SSI k=" ++ U64.show(k) ++ " ok=" ++ (Bool.pick(String, ok, "y", "n")) ++ " brs=" ++ Nat.show(List.length(&2, CS.Br, bs)) ++ " un=" ++ Nat.show(List.length(&2, List<&2, I.I>, un)) ++ uns(un, 4n)

def sr_s(+r: Y.Sr) -> String:
  Y.Sr{+ss, +k, +co} = r
  ss_s(ss, k)

def pr2(xs: List<&2, SO.Fd>, ys: List<&2, SO.Fd>) -> String:
  match xs:
    case []: "?"
    case +fa <> u:
      match ys:
        case []: "?"
        case +fb <> v:
          "A kind " ++ U64.show(S.sf_kind(S.sf_of(SO.fd_g(fa)))) ++ " box " ++ bxs(SO.fd_bx(fa)) ++ "
B kind " ++ U64.show(S.sf_kind(S.sf_of(SO.fd_g(fb)))) ++ " box " ++ bxs(SO.fd_bx(fb)) ++ "
" ++
            sr_s(Y.inter_ss(SO.fd_g(fa), SO.fd_g(fb), EM.pad_ss(X.vmeet(SO.fd_bx(fa), SO.fd_bx(fb)))))

def run(+src: String) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_part(p, [])
  +ra = brep_of(M.ce_r(M.ce_find(cs, 1001u64)))
  +rb = brep_of(M.ce_r(M.ce_find(cs, 1100u64)))
  +kr = GB.gbrun_f(False{}, 14u64, ra, rb, SO.fds_of(ra), SO.fds_of(rb))
  +b = K1.kr_brep(kr)
  +fs = SO.fds_re(b, SO.pool_kf(List.append(&2, SO.KF, K1.kr_fk(kr), List.append(&2, SO.KF, SO.kfs_of(ra, SO.fds_of(ra)), SO.kfs_of(rb, SO.fds_of(rb))))))
  +tg = SO.tags_or(SO.rtags_of(b, SO.vpool(ra, []), SO.vpool(rb, [])), SO.ltags(b, ra, rb))
  +et = SO.etags_of(b, SO.epool(ra, []), SO.epool(rb, []))
  "V" ++ Nat.show(List.length(&2, Ty.Vertex, Ty.brep_vs(b))) ++ " E" ++ Nat.show(List.length(&2, Ty.Edge, Ty.brep_es(b))) ++ " F" ++ Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(b))) ++ " emb" ++ fis(EM.emb_fi_t(b, fs, tg, et)) ++ "
" ++ pr2(fd_at(fs, 30n), fd_at(fs, 45n))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/mnt/c/dev/BendCAD-k3/tests/speed/hub2.bcd")
    IO.print(run(src))
