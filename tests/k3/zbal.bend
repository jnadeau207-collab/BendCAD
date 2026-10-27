import Base
import ../../src/k1/sf.bend as KS
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c08/bool.bend as B8
import ../../src/k3/mach.bend as K
import ../../src/c04/types.bend as Ty
import ../../src/c07/sol.bend as SO
import ../../src/c07/emb.bend as EM
import ../../src/c01/types.bend as V
import ../../src/k1/fb.bend as FB

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

def placed(+b: M.Body) -> Ty.Brep:
  +p = M.bd_pl(b)
  B8.xf_brep(M.pl_m(p), M.pl_tx(p), M.pl_ty(p), M.pl_tz(p), M.bd_brep(b))

def cd(+c: U64) -> String:
  U64.show(c)

def one_d(+pc: K.PC, +tb: K.TB, +t: K.TL, +p: V.Point, +n: V.Dir, +d: V.Dir) -> String:
  +cc = KS.padd(p, F64.add(K.tl_r(t), 0.008f64), n)
  +b = K.pc_b(pc)
  +fs = K.pc_fs(pc)
  +pp = K.pc_pp(pc)
  " ball=" ++ cd(K.clr(b, fs, K.place(K.tb_ball(tb), d, cc), cc, pp)) ++ " flute=" ++ cd(K.clr(b, fs, K.place(K.tb_cut(tb), d, cc), KS.padd(cc, F64.mul(0.5f64, K.tl_fl(t)), d), pp)) ++
    " holder=" ++ cd(K.clr(b, fs, K.place(K.tb_hold(tb), d, KS.padd(cc, K.tl_fl(t), d)), KS.padd(KS.padd(cc, K.tl_fl(t), d), F64.mul(0.5f64, K.tl_hl(t)), d), pp))

def dirs_s(ds: List<&2, V.Dir>, +pc: K.PC, +tb: K.TB, +t: K.TL, +p: V.Point, +n: V.Dir) -> String:
  match ds:
    case []: ""
    case +d <> +r: " |" ++ one_d(pc, tb, t, p, n, d) ++ dirs_s(r, pc, tb, t, p, n)

def sps(xs: List<&2, K.SP>, +pc: K.PC, +tb: K.TB, +t: K.TL) -> String:
  match xs:
    case []: ""
    case +x <> +r:
      K.SP{+p, +n} = x
      K.pt_s(p) ++ dirs_s(K.dirs_of(True{}, n), pc, tb, t, p, n) ++ "
" ++ sps(r, pc, tb, t)

def fis_s(xs: List<&2, SO.Fi>) -> String:
  match xs:
    case []: ""
    case +x <> +r:
      SO.Fi{+c, +a, +b} = x
      " [" ++ c ++ " " ++ Nat.show(a) ++ " " ++ Nat.show(b) ++ "]" ++ fis_s(r)

def cross_s(+pc: K.PC, +tb: K.TB, +t: K.TL, +p: V.Point, +n: V.Dir) -> String:
  +cc = KS.padd(p, F64.add(K.tl_r(t), 0.008f64), n)
  +bc = B8.brep_append(K.pc_b(pc), K.place(K.tb_ball(tb), n, cc))
  "nfaces_part=" ++ Nat.show(List.length(&2, SO.Fd, K.pc_fs(pc))) ++ fis_s(EM.emb_cross(bc, SO.fds_of(bc)))

def one_sp(xs: List<&2, K.SP>, +pc: K.PC, +tb: K.TB, +t: K.TL) -> String:
  match xs:
    case []: ""
    case +x <> +r:
      K.SP{+p, +n} = x
      K.pt_s(p) ++ " " ++ cross_s(pc, tb, t, p, n) ++ "
" ++ one_sp(r, pc, tb, t)

def run(+src: String, +na: Nat) -> String:
  +cs = M.ev_part(S.part_of(S.ps_xs(S.parse(src))), [])
  +b = placed(M.nr_body(M.ce_r(M.ce_find(cs, 1u64))))
  +t = {K.TL{0.8f64, 20.0f64, 5.0f64, 40.0f64} : K.TL}
  +k = FB.kb_of(b)
  +pc = {K.PC{b, k, SO.fds_of(b), K.first_pt(Ty.brep_vs(b))} : K.PC}
  one_sp(K.samples(k, 9n, 2n), pc, K.tool_bs(t), t)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/tmp/zp.bcd")
    IO.print(run(src, List.length(&1, String, args)))
