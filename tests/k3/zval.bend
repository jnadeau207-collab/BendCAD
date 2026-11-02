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
import ../../src/c07/emb.bend as EMB
import ../../src/c04/ops.bend as B4
import ../../src/c00/types.bend as T0
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

def v_tail3(+b: Ty.Brep, +fds: List<&2, SO.Fd>) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("solid_fi " ++ Nat.show(List.length(&2, SO.Fi, SO.solid_fi(b, fds))))
    t1 : Nat <- IO.now()
    tm("solid_fi", t0, t1)

def v_tail2(+b: Ty.Brep, +fds: List<&2, SO.Fd>) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("emb_fi " ++ Nat.show(List.length(&2, SO.Fi, EMB.emb_fi(b, fds))))
    t1 : Nat <- IO.now()
    v : Unit <- tm("emb_fi", t0, t1)
    v_tail3(b, fds)

def v_tail(+b: Ty.Brep) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("coin " ++ Bool.pick(String, B8.CR_ok(B8.coin_contact(b)), "ok", "bad"))
    t1 : Nat <- IO.now()
    v : Unit <- tm("coin_contact", t0, t1)
    t2 : Nat <- IO.now()
    w : Unit <- IO.print("fds " ++ Nat.show(List.length(&2, SO.Fd, SO.fds_of(b))))
    t3 : Nat <- IO.now()
    x : Unit <- tm("fds_of", t2, t3)
    v_tail2(b, SO.fds_of(b))

def v_9(+b: Ty.Brep, +f: Nat) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("orient " ++ Bool.pick(String, Ty.okd_ok(B4.brep_orient_c(b, f)), "ok", "bad"))
    t1 : Nat <- IO.now()
    v : Unit <- tm("c04_orient", t0, t1)
    v_tail(b)

def v_8(+b: Ty.Brep, +f: Nat) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("xing " ++ Bool.pick(String, Ty.okd_ok(B4.brep_xing_c(b, f)), "ok", "bad"))
    t1 : Nat <- IO.now()
    v : Unit <- tm("c04_xing", t0, t1)
    v_9(b, f)

def v_7(+b: Ty.Brep, +f: Nat) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("conn " ++ Bool.pick(String, Ty.okd_ok(B4.brep_conn_c(b, f)), "ok", "bad"))
    t1 : Nat <- IO.now()
    v : Unit <- tm("c04_conn", t0, t1)
    v_8(b, f)

def v_6(+b: Ty.Brep, +f: Nat) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("link " ++ Bool.pick(String, Ty.okd_ok(B4.brep_link_c(b, Ty.P_manifold_solid{}, f)), "ok", "bad"))
    t1 : Nat <- IO.now()
    v : Unit <- tm("c04_link", t0, t1)
    v_7(b, f)

def v_5(+b: Ty.Brep, +f: Nat) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("embed " ++ Bool.pick(String, Ty.okd_ok(B4.brep_embed_c(b, f)), "ok", "bad"))
    t1 : Nat <- IO.now()
    v : Unit <- tm("c04_embed", t0, t1)
    v_6(b, f)

def v_4(+b: Ty.Brep, +f: Nat) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("prof " ++ Bool.pick(String, Ty.okd_ok(B4.brep_prof_c(b, Ty.P_manifold_solid{}, f)), "ok", "bad"))
    t1 : Nat <- IO.now()
    v : Unit <- tm("c04_prof", t0, t1)
    v_5(b, f)

def v_3(+b: Ty.Brep, +f: Nat) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("facekind " ++ Bool.pick(String, Ty.okd_ok(B4.brep_facekind_c(b, f)), "ok", "bad"))
    t1 : Nat <- IO.now()
    v : Unit <- tm("c04_facekind", t0, t1)
    v_4(b, f)

def v_2(+b: Ty.Brep, +f: Nat) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("loop " ++ Bool.pick(String, Ty.okd_ok(B4.brep_loop_c(b, f)), "ok", "bad"))
    t1 : Nat <- IO.now()
    v : Unit <- tm("c04_loop", t0, t1)
    v_3(b, f)

def v_1(+b: Ty.Brep, +f: Nat) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("use " ++ Bool.pick(String, Ty.okd_ok(B4.brep_use_c(b, Ty.P_manifold_solid{}, f)), "ok", "bad"))
    t1 : Nat <- IO.now()
    v : Unit <- tm("c04_use", t0, t1)
    v_2(b, f)

def v_0(+b: Ty.Brep, +f: Nat) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("incid " ++ Bool.pick(String, Ty.okd_ok(B4.brep_incid_c(b, f)), "ok", "bad"))
    t1 : Nat <- IO.now()
    v : Unit <- tm("c04_incid", t0, t1)
    v_1(b, f)

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +id = S.u64_of(S.Sx_a{S.arg_at(args, 2n)})
  +b = placed(M.ev_for(p, [id], []), id)
  do IO<Unit>:
    u : Unit <- IO.print("faces " ++ nf(b))
    v_0(b, B8.fuel_of(b))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
