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

def nf(+b: Ty.Brep) -> String:
  Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(b)))

def kr_s(+r: K1.KR) -> String:
  Bool.pick(String, K1.kr_ok(r), "ok", "refused " ++ U64.show(K1.kr_why(r))) ++ " faces " ++ nf(K1.kr_brep(r))

def vr_s(+v: B8.VR) -> String:
  Bool.pick(String, B8.VR_ok(v), "ok", B8.vcode(v))

def vol_s(+r: VI.VR) -> String:
  Bool.pick(String, VI.vr_ok(r), "ok", "fail")

def stamp(+tag: String, +t0: Nat, +t1: Nat, +s: String) -> IO(Unit):
  IO.print(tag ++ " " ++ Nat.show(Nat.sub(t1, t0)) ++ " " ++ s)

def rep(n: Nat, +b: Ty.Brep, +acc: Nat) -> Nat:
  match n:
    case 0n: acc
    case 1n+m: rep(m, b, Nat.add(acc, List.length(&2, SO.Fd, SO.fds_of(b))))

def isum(xs: List<&2, I.I>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> t: isum(t, F64.add(acc, F64.add(I.i_lo(x), I.i_hi(x))))

def ea_n(f: Ty.Face, +x: Ty.Ix) -> F64:
  Ty.Fa{g, s, ls, same, slv, sla} = f
  isum(SO.eb_go(SO.ea_es(SO.lps_go(ls, x, SO.Ea{[], True{}})), []), 0.0f64)

def fb_n(f: Ty.Face, +x: Ty.Ix) -> F64:
  isum(SO.fd_bx(SO.fd_of(f, x, 0n, 0n)), 0.0f64)

def one(e: Bool, f: Ty.Face, +x: Ty.Ix) -> F64:
  match e:
    case True{}: ea_n(f, x)
    case False{}: fb_n(f, x)

def eh(hs: List<&2, Ty.HFace>, +x: Ty.Ix, +k: Nat, +acc: F64) -> F64:
  match hs:
    case []: acc
    case +h <> t: eh(t, x, k, F64.add(acc, one(Nat.is_eq(k, 0n), Ty.tres_fa(Ty.ix_fa(x, h)), x)))

def esh(ss: List<&2, Ty.Shell>, +x: Ty.Ix, +k: Nat, +acc: F64) -> F64:
  match ss:
    case []: acc
    case s <> t:
      Ty.Sh{g, hs, kk} = s
      esh(t, x, k, eh(hs, x, k, acc))

def part(n: Nat, +b: Ty.Brep, +k: Nat, +acc: F64) -> F64:
  match n:
    case 0n: acc
    case 1n+m: part(m, b, k, esh(Ty.brep_shs(b), Ty.ix_of(b), k, acc))

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +id = S.u64_of(S.Sx_a{S.arg_at(args, 2n)})
  +b = placed(M.ev_for(p, [id], []), id)
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("faces " ++ nf(b))
    t1 : Nat <- IO.now()
    v : Unit <- IO.print("eval_ms " ++ Nat.show(Nat.sub(t1, t0)))
    t1b : Nat <- IO.now()
    w : Unit <- IO.print("fds x5 " ++ Nat.show(rep(5n, b, 0n)))
    t2 : Nat <- IO.now()
    x : Unit <- IO.print("fds_ms " ++ Nat.show(Nat.sub(t2, t1b)))
    t3 : Nat <- IO.now()
    y : Unit <- IO.print("edges x5 " ++ F64.show(part(5n, b, 0n, 0.0f64)))
    t4 : Nat <- IO.now()
    z : Unit <- IO.print("edges_ms " ++ Nat.show(Nat.sub(t4, t3)))
    t5 : Nat <- IO.now()
    q : Unit <- IO.print("fbox x5 " ++ F64.show(part(5n, b, 1n, 0.0f64)))
    t6 : Nat <- IO.now()
    IO.print("fbox_ms " ++ Nat.show(Nat.sub(t6, t5)))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
