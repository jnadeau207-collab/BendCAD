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
import ../../src/k1/ef.bend as EF
import ../../src/k1/ss.bend as SS
import ../../src/k1/ls.bend as L
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

def placed(+cs: List<&2, M.CE>, +id: U64) -> Ty.Brep:
  +b = M.nr_body(M.ce_r(M.ce_find(cs, id)))
  +pl = M.bd_pl(b)
  B8.xf_brep(M.pl_m(pl), M.pl_tx(pl), M.pl_ty(pl), M.pl_tz(pl), M.bd_brep(b))

def nf(+b: Ty.Brep) -> String:
  Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(b)))

def tm(+tag: String, +t0: Nat, +t1: Nat) -> IO(Unit):
  IO.print(tag ++ " " ++ Nat.show(Nat.sub(t1, t0)))

def ej_n(js: List<&2, PX.EJ>, +n: Nat) -> Nat:
  match js:
    case []: n
    case +j <> +t:
      PX.EJ{e, fo, inp, +r} = j
      ej_n(t, Nat.add(n, Nat.add(1n, List.length(&2, EF.EH, EF.ehs_hs(r)))))

def pj_n(js: List<&2, PX.PJ>, +n: Nat) -> Nat:
  match js:
    case []: n
    case +j <> +t:
      PX.PJ{fa, fb, +x, ph} = j
      pj_n(t, Nat.add(n, Nat.add(1n, List.length(&2, SS.IC, SS.ics_ics(x)))))

def c3(+ba: FB.KB, +bb: FB.KB, +hs: List<&2, PX.HX>, +g: PX.GV) -> IO(Unit):
  +c = {PX.PC{PX.faces_bb(L.nat_range(FB.nfaces(bb)), bb), PX.faces_wd(L.nat_range(FB.nfaces(bb)), bb), PX.faces_rho(L.nat_range(FB.nfaces(bb)), bb), hs, ba, bb} : PX.PC}
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("pj " ++ Nat.show(pj_n(List.concat(&2, PX.PJ, B.pmap_g(~Nat, ~PX.PC, ~List<&2, PX.PJ>, ~PX.pj_job, 1, c, L.nat_range(FB.nfaces(ba)))), 0n)))
    t1 : Nat <- IO.now()
    v : Unit <- tm("chain_pairs_parallel", t0, t1)
    t2 : Nat <- IO.now()
    w : Unit <- IO.print("chains " ++ Nat.show(List.length(&2, PX.CH, PX.cr_chs(PX.pj_fold(List.concat(&2, PX.PJ, B.pmap_g(~Nat, ~PX.PC, ~List<&2, PX.PJ>, ~PX.pj_job, 1, c, L.nat_range(FB.nfaces(ba)))), ba, bb, PX.CR{[], g, True{}, 0u64})))))
    t3 : Nat <- IO.now()
    tm("chain_pairs+fold", t2, t3)

def c2(+ba: FB.KB, +bb: FB.KB, +g: PX.GV) -> IO(Unit):
  +ps = PX.ep_all(L.nat_range(FB.nedges(ba)), ba, PX.fbs_of(FB.nfaces(bb), bb, []))
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("pairs " ++ Nat.show(List.length(&2, PX.EP, ps)))
    t1 : Nat <- IO.now()
    v : Unit <- tm("edge_pairs", t0, t1)
    t2 : Nat <- IO.now()
    w : Unit <- IO.print("ej " ++ Nat.show(ej_n(B.pmap_g(~PX.EP, ~PX.EX, ~PX.EJ, ~PX.ej_job, 1, PX.EX{ba, bb}, ps), 0n)))
    t3 : Nat <- IO.now()
    x : Unit <- tm("edge_hits_parallel", t2, t3)
    t4 : Nat <- IO.now()
    y : Unit <- IO.print("s0 " ++ Nat.show(List.length(&2, PX.HX, PX.hs_hs(PX.ef_edges(L.nat_range(FB.nedges(ba)), 0u64, ba, bb, PX.HS{[], g, True{}, 0u64})))))
    t5 : Nat <- IO.now()
    z : Unit <- tm("s0_edges_a", t4, t5)
    t6 : Nat <- IO.now()
    y2 : Unit <- IO.print("s1 " ++ Nat.show(List.length(&2, PX.HX, PX.hs_hs(PX.ef_edges(L.nat_range(FB.nedges(bb)), 1u64, bb, ba, PX.HS{[], g, True{}, 0u64})))))
    t7 : Nat <- IO.now()
    z2 : Unit <- tm("s1_edges_b", t6, t7)
    t8 : Nat <- IO.now()
    y3 : Unit <- IO.print("s2 " ++ Nat.show(List.length(&2, PX.HX, PX.hs_hs(PX.ve_verts(L.nat_range(FB.kb_nv(bb)), 0u64, ba, bb, PX.HS{[], g, True{}, 0u64})))))
    t9 : Nat <- IO.now()
    z3 : Unit <- tm("s2_verts_b", t8, t9)
    t10 : Nat <- IO.now()
    y4 : Unit <- IO.print("s3 " ++ Nat.show(List.length(&2, PX.HX, PX.hs_hs(PX.ve_verts(L.nat_range(FB.kb_nv(ba)), 1u64, bb, ba, PX.HS{[], g, True{}, 0u64})))))
    t11 : Nat <- IO.now()
    z4 : Unit <- tm("s3_verts_a", t10, t11)
    c3(ba, bb, PX.hs_hs(PX.all_hits(ba, bb, g)), PX.hs_g(PX.all_hits(ba, bb, g)))

def c1(+ra: Ty.Brep, +rb: Ty.Brep) -> IO(Unit):
  +ba = FB.kb_of(ra)
  +bb = FB.kb_of(rb)
  +va = PX.add_vs(Ty.brep_vs(ra), PX.GV{[], 0n}, [])
  +vb = PX.add_vs(Ty.brep_vs(rb), PX.vm_g(va), [])
  do IO<Unit>:
    u : Unit <- IO.print("operands " ++ nf(ra) ++ " " ++ nf(rb))
    c2(ba, bb, PX.vm_g(vb))

def s1(+p: M.Part, +a: U64, +b: U64) -> IO(Unit):
  +cs = M.ev_for(p, [a, b], [])
  c1(placed(cs, a), placed(cs, b))

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  s1(S.part_of(S.ps_xs(S.parse(src))), S.u64_of(S.Sx_a{S.arg_at(args, 2n)}), S.u64_of(S.Sx_a{S.arg_at(args, 3n)}))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
