import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c06/model.bend as M
import ../../src/c08/bool.bend as B8
import ../../src/c06/sx.bend as SX
import ../../src/k1/sf.bend as S
import ../../src/k1/fb.bend as FB
import ../../src/k1/px.bend as PX
import ../../src/k1/co.bend as CO
import ../../src/k1/gw.bend as W
import ../../src/k1/gb.bend as GB
import ../../src/k1/ls.bend as L

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

def v2s(+q: V.Vec2) -> String:
  "(" ++ F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q)) ++ ")"

def last2(ps: List<&2, V.Vec2>, +d: V.Vec2) -> V.Vec2:
  match ps:
    case []: d
    case +h <> +t: last2(t, h)

def first2(ps: List<&2, V.Vec2>) -> V.Vec2:
  match ps:
    case []: V.V2{0.0f64, 0.0f64}
    case +h <> +t: h

def deg(pcs: List<&2, W.PC>, +v: Nat) -> Nat:
  match pcs:
    case []: 0n
    case +h <> +t: Nat.add(Nat.add(Bool.pick(Nat, Nat.is_eq(W.pc_va(h), v), 1n, 0n), Bool.pick(Nat, Nat.is_eq(W.pc_vb(h), v), 1n, 0n)), deg(t, v))

def pcs_s(ps: List<&2, W.PC>, +all: List<&2, W.PC>, +i: Nat) -> String:
  match ps:
    case []: ""
    case +h <> +t:
      +pl = W.pc_poly(h)
      "pc " ++ Nat.show(i) ++ " va " ++ Nat.show(W.pc_va(h)) ++ "/" ++ Nat.show(deg(all, W.pc_va(h))) ++ " vb " ++ Nat.show(W.pc_vb(h)) ++ "/" ++
        Nat.show(deg(all, W.pc_vb(h))) ++ " bnd " ++ Bool.pick(String, W.pc_bnd(h), "y", "n") ++ " n " ++ Nat.show(List.length(&2, V.Vec2, pl)) ++
        " " ++ v2s(first2(pl)) ++ " -> " ++ v2s(last2(pl, first2(pl))) ++ "
" ++ pcs_s(t, all, Nat.add(i, 1n))

def cys_s(cs: List<&2, W.CY>) -> String:
  match cs:
    case []: ""
    case +h <> +t: "cy hes " ++ Nat.show(List.length(&2, W.HE, W.cy_hes(h))) ++ " wind " ++ F64.show(W.cy_wind(h)) ++ " area " ++ F64.show(W.cy_area(h)) ++ "
" ++ cys_s(t)

def run(+src: String, +na: U64, +nb: U64, +sd: U64, +fi: Nat) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_for(p, [na, nb], [])
  +ra = brep_of(M.ce_r(M.ce_find(cs, na)))
  +rb = brep_of(M.ce_r(M.ce_find(cs, nb)))
  +ba = FB.kb_of(ra)
  +bb = FB.kb_of(rb)
  +va = PX.add_vs(Ty.brep_vs(ra), PX.GV{[], 0n}, [])
  +vb = PX.add_vs(Ty.brep_vs(rb), PX.vm_g(va), [])
  +hs = PX.all_hits(ba, bb, PX.vm_g(vb))
  +cps = CO.coin_pairs(ba, bb)
  +cx0 = CO.crossings(cps, ba, bb, PX.hs_g(hs))
  +tj = CO.tjunctions(cps, ba, bb, CO.cx_g(cx0))
  +hs2 = List.append(&2, PX.HX, PX.hs_hs(hs), List.append(&2, PX.HX, CO.cx_hs(cx0), CO.cx_hs(tj)))
  +cr = PX.all_chains(hs2, ba, bb, CO.cx_g(tj))
  +hs3 = PX.chain_hits(PX.cr_chs(cr), ba, bb, PX.cr_g(cr), hs2)
  +m0 = GB.arc_mids(L.nat_range(FB.nedges(ba)), 0u64, ba, hs3, PX.cr_g(cr), [])
  +m1 = GB.arc_mids(L.nat_range(FB.nedges(bb)), 1u64, bb, hs3, PX.hxg_g(m0), PX.hxg_hs(m0))
  +hs4 = List.append(&2, PX.HX, hs3, PX.hxg_hs(m1))
  +b = Bool.pick(FB.KB, U64.is_eq(sd, 0u64), ba, bb)
  +ob = Bool.pick(FB.KB, U64.is_eq(sd, 0u64), bb, ba)
  +vm = Bool.pick(List<&2, Nat>, U64.is_eq(sd, 0u64), PX.vm_mp(va), PX.vm_mp(vb))
  +vmo = Bool.pick(List<&2, Nat>, U64.is_eq(sd, 0u64), PX.vm_mp(vb), PX.vm_mp(va))
  +pcs = GB.face_pcs(b, fi, sd, vm, hs4, PX.cr_chs(cr), cps, ob, vmo, PX.hxg_g(m1))
  +fc = W.face_cycles(FB.face_sf(b, fi), pcs)
  "hits ok " ++ Bool.pick(String, PX.hs_ok(hs), "y", "n") ++ " chains ok " ++ Bool.pick(String, PX.cr_ok(cr), "y", "n") ++ " why " ++ U64.show(PX.cr_why(cr)) ++
    " nchains " ++ Nat.show(List.length(&2, PX.CH, PX.cr_chs(cr))) ++ " face " ++ Nat.show(fi) ++ " kind " ++ U64.show(S.sf_kind(FB.face_sf(b, fi))) ++
    " npcs " ++ Nat.show(List.length(&2, W.PC, pcs)) ++ " cycles ok " ++ Bool.pick(String, W.cs_ok(fc), "y", "n") ++ "
" ++ pcs_s(pcs, pcs, 0n) ++ cys_s(W.cs_cys(fc))

def num(+s: String) -> U64:
  SX.u64_of(SX.Sx_a{s})

def to2(xs: List<&1, String>) -> List<&2, String>:
  match xs:
    case []: []
    case h <> t: h <> to2(t)

def go2(+src: String, +args: List<&2, String>) -> IO(Unit):
  IO.print(run(src, num(SX.arg_at(args, 2n)), num(SX.arg_at(args, 3n)), num(SX.arg_at(args, 4n)), U64.to_nat(num(SX.arg_at(args, 5n)))))

def go(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(SX.arg_at(args, 1n))
    go2(src, args)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(to2(args))
