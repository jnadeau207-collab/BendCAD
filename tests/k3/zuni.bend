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

def tm(+tag: String, +t0: Nat, +t1: Nat) -> IO(Unit):
  IO.print(tag ++ " " ++ Nat.show(Nat.sub(t1, t0)))

def u8(+bc: Ty.Brep) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("genus " ++ Nat.show(B8.genus_of(bc)) ++ " vol " ++ vol_s(VI.brep_vol(bc)))
    t1 : Nat <- IO.now()
    tm("genus+vol", t0, t1)

def u7(+bc: Ty.Brep, +fdc: List<&2, SO.Fd>, +ra: Ty.Brep, +fda: List<&2, SO.Fd>, +rb: Ty.Brep, +fdb: List<&2, SO.Fd>) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("fns " ++ Nat.show(List.length(&2, BD.Fn, B8.k1_fns_f(bc, fdc, ra, fda, [], rb, fdb, [], 1201u64))))
    t1 : Nat <- IO.now()
    v : Unit <- tm("k1_fns_f", t0, t1)
    u8(bc)

def u6(+bc: Ty.Brep, +fdc: List<&2, SO.Fd>, +ra: Ty.Brep, +fda: List<&2, SO.Fd>, +rb: Ty.Brep, +fdb: List<&2, SO.Fd>) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("vcore " ++ vr_s(B8.vcore_f(bc, fdc)))
    t1 : Nat <- IO.now()
    v : Unit <- tm("vcore_f", t0, t1)
    u7(bc, fdc, ra, fda, rb, fdb)

def u5(+bc: Ty.Brep, +ra: Ty.Brep, +fda: List<&2, SO.Fd>, +rb: Ty.Brep, +fdb: List<&2, SO.Fd>) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("fdc " ++ Nat.show(List.length(&2, SO.Fd, SO.fds_of(bc))))
    t1 : Nat <- IO.now()
    v : Unit <- tm("fds_of(result)", t0, t1)
    u6(bc, SO.fds_of(bc), ra, fda, rb, fdb)

def u4(+kr: K1.KR, +ra: Ty.Brep, +fda: List<&2, SO.Fd>, +rb: Ty.Brep, +fdb: List<&2, SO.Fd>, +t0: Nat) -> IO(Unit):
  do IO<Unit>:
    u : Unit <- IO.print("k1 " ++ kr_s(kr))
    t1 : Nat <- IO.now()
    v : Unit <- tm("gbrun_f", t0, t1)
    u5(B8.restamp(K1.kr_brep(kr)), ra, fda, rb, fdb)

def u3(+ra: Ty.Brep, +fda: List<&2, SO.Fd>, +rb: Ty.Brep, +fdb: List<&2, SO.Fd>) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("fda " ++ Nat.show(List.length(&2, SO.Fd, fda)) ++ " fdb " ++ Nat.show(List.length(&2, SO.Fd, fdb)))
    t1 : Nat <- IO.now()
    v : Unit <- tm("fds_of(operands)", t0, t1)
    t2 : Nat <- IO.now()
    u4(GB.gbrun_f(True{}, B8.tag_union(), ra, rb, fda, fdb), ra, fda, rb, fdb, t2)

def u2(+p: M.Part, +c: U64, +old: List<&2, M.CE>, +ra: Ty.Brep, +rb: Ty.Brep) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("node " ++ U64.show(c) ++ " faces " ++ nf(placed(M.ev_for(p, [c], old), c)))
    t1 : Nat <- IO.now()
    v : Unit <- tm("node_eval_cached_operands", t0, t1)
    u3(ra, SO.fds_of(ra), rb, SO.fds_of(rb))

def u1(+p: M.Part, +a: U64, +b: U64, +c: U64, +cs: List<&2, M.CE>, +t0: Nat) -> IO(Unit):
  do IO<Unit>:
    u : Unit <- IO.print("operands " ++ nf(placed(cs, a)) ++ " " ++ nf(placed(cs, b)))
    t1 : Nat <- IO.now()
    v : Unit <- tm("operands_eval", t0, t1)
    u2(p, c, cs, placed(cs, a), placed(cs, b))

def s1(+p: M.Part, +a: U64, +b: U64, +c: U64) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u1(p, a, b, c, M.ev_for(p, [a, b], []), t0)

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  s1(S.part_of(S.ps_xs(S.parse(src))), S.u64_of(S.Sx_a{S.arg_at(args, 2n)}), S.u64_of(S.Sx_a{S.arg_at(args, 3n)}), S.u64_of(S.Sx_a{S.arg_at(args, 4n)}))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
