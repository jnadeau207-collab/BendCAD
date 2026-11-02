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

def vr_s(+v: B8.VR) -> String:
  Bool.pick(String, B8.VR_ok(v), "ok", B8.vcode(v))

def ok_s(+cs: List<&2, M.CE>, +id: U64) -> String:
  +r = M.ce_r(M.ce_find(cs, id))
  Bool.pick(String, M.nr_ok(r), "ok faces " ++ nf(M.bd_brep(M.nr_body(r))), "err")

def br_of(+cs: List<&2, M.CE>, +id: U64) -> Ty.Brep:
  M.bd_brep(M.nr_body(M.ce_r(M.ce_find(cs, id))))

def hd(+xs: List<&2, U64>) -> U64:
  match xs:
    case []: 0u64
    case +h <> +t: h

def walk(ids: List<&2, U64>, +p: M.Part, +cs: List<&2, M.CE>, +t0: Nat) -> IO(Unit):
  match ids:
    case []: IO.pure(Unit, Unit{})
    case +id <> +t:
      do IO<Unit>:
        u : Unit <- IO.print("node " ++ U64.show(id) ++ " " ++ ok_s(cs, id))
        t1 : Nat <- IO.now()
        v : Unit <- IO.print("  eval_ms " ++ Nat.show(Nat.sub(t1, t0)))
        t3 : Nat <- IO.now()
        walk(t, p, List.append(&2, M.CE, M.ev_for(p, [hd(t)], cs), cs), t3)

def ids_of(+p: M.Part) -> List<&2, U64>:
  M.Pt{+ps, +ns, +ms, +ts} = p
  M.nd_ids(ns)

def go(+src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +ids = ids_of(p)
  do IO<Unit>:
    t0 : Nat <- IO.now()
    walk(ids, p, M.ev_for(p, [hd(ids)], []), t0)

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
