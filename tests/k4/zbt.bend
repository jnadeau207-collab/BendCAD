import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c04/ops.bend as O
import ../../src/c06/model.bend as M
import ../../src/c08/bool.bend as B8
import ../../src/c06/sx.bend as SX
import ../../src/k1/sf.bend as S
import ../../src/k1/gb.bend as GB
import ../../src/k1/asm.bend as K1
import ../../src/k1/ef.bend as EF
import ../../src/k1/ss.bend as SS
import ../../src/c03/ops.bend as GOP

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

def yn(+b: Bool) -> String:
  Bool.pick(String, b, "y", "n")

def g0(gs: List<&2, G.GVal>) -> G.GVal:
  match gs:
    case []: G.GV_f{0.0f64}
    case +h <> t: h

def g1(gs: List<&2, G.GVal>) -> G.GVal:
  match gs:
    case []: G.GV_f{0.0f64}
    case h <> t: g0(t)

def sbo(+gs: List<&2, G.GVal>) -> S.SF:
  S.sf_of(g0(gs))

def soo(+gs: List<&2, G.GVal>) -> S.SF:
  S.sf_of(g1(gs))

def sd_p(+q: V.Vec2, +gs: List<&2, G.GVal>) -> V.Point:
  +p1 = SS.fr_pt(sbo(gs), V.v2_x(q), V.v2_y(q), V.V2{0.0f64, 1.0f64})
  S.newton2(10n, sbo(gs), soo(gs), p1, S.dunit(SS.fr_tan(sbo(gs), soo(gs), p1)), p1)

def bad1(ps: List<&2, V.Point>, +gs: List<&2, G.GVal>) -> String:
  match ps:
    case []: ""
    case +p <> t:
      Bool.pick(String, EF.ct_ok(EF.cert_gs(gs, p)), bad1(t, gs),
        " BAD on_bp=" ++ yn(EF.on_g(g0(gs), p)) ++ " on_tor=" ++ yn(EF.on_g(g1(gs), p)) ++ " h13=" ++ yn(GOP.q_on_h(g1(gs), p, 1.0e-13f64)) ++ " h12=" ++ yn(GOP.q_on_h(g1(gs), p, 1.0e-12f64)) ++ " h10=" ++ yn(GOP.q_on_h(g1(gs), p, 1.0e-10f64)) ++ " h8=" ++ yn(GOP.q_on_h(g1(gs), p, 1.0e-8f64)) ++ " p=" ++ F64.show(S.px(p)) ++ "," ++ F64.show(S.py(p)) ++ "," ++ F64.show(S.pz(p)) ++ " uv=" ++ F64.show(V.v2_x(S.bp_uv(S.gbp([g0(gs)]), p))) ++ "," ++ F64.show(V.v2_y(S.bp_uv(S.gbp([g0(gs)]), p))))

def sd_c(+tr: SS.TR, +gs: List<&2, G.GVal>) -> String:
  " ok=" ++ yn(SS.tr_ok(tr)) ++ " cl=" ++ yn(SS.tr_closed(tr)) ++ " n=" ++ Nat.show(List.length(&2, V.Point, SS.tr_pts(tr))) ++
    " cert=" ++ yn(SS.pl_ok(SS.fr_cert(SS.tr_pts(tr), sbo(gs), soo(gs), gs, SS.bx_all(), [], True{}))) ++ bad1(SS.tr_pts(tr), gs)

def sd_t(+p: V.Point, +h: F64, +gs: List<&2, G.GVal>) -> String:
  "
  seed f=" ++ F64.show(S.sf_f(soo(gs), p)) ++ sd_c(SS.fr_seed(sbo(gs), soo(gs), h, p, SS.bx_all()), gs)

def sds(qs: List<&2, V.Vec2>, +h: F64, +gs: List<&2, G.GVal>, +k: Nat) -> String:
  match qs:
    case []: ""
    case +q <> t: Bool.pick(String, Nat.is_eq(k, 0n), "", sd_t(sd_p(q, gs), h, gs) ++ sds(t, h, gs, Nat.sub(k, 1n)))

def pr_x(+gs: List<&2, G.GVal>, +i: Nat, +j: Nat) -> String:
  +h = SS.fr_h(sbo(gs), soo(gs))
  +qs = SS.fr_seeds(sbo(gs), soo(gs), V.V2{0.0f64, 1.0f64})
  "
PAIR " ++ Nat.show(i) ++ "/" ++ Nat.show(j) ++ " why " ++ U64.show(SS.ics_why(SS.ssi(g0(gs), g1(gs)))) ++ " h " ++ F64.show(h) ++ " seeds " ++ Nat.show(List.length(&2, V.Vec2, qs)) ++ sds(qs, h, gs, 8n)

def pr_go(go: Bool, +gs: List<&2, G.GVal>, +i: Nat, +j: Nat) -> String:
  match go:
    case True{}: pr_x(gs, i, j)
    case False{}: ""

def pr1(+gs: List<&2, G.GVal>, +i: Nat, +j: Nat) -> String:
  pr_go(Bool.and(S.is_bp(sbo(gs)), S.is_tor(soo(gs))), gs, i, j)

def prb(fb: List<&2, Ty.Face>, +fa: Ty.Face, +i: Nat, +j: Nat) -> String:
  match fb:
    case []: ""
    case +f <> t: pr1([Ty.fa_surf(fa), Ty.fa_surf(f)], i, j) ++ prb(t, fa, i, Nat.add(j, 1n))

def pra(fa: List<&2, Ty.Face>, +fb: List<&2, Ty.Face>, +i: Nat) -> String:
  match fa:
    case []: ""
    case +f <> t: prb(fb, f, i, 0n) ++ pra(t, fb, Nat.add(i, 1n))

def kinds(fs: List<&2, Ty.Face>) -> String:
  match fs:
    case []: ""
    case +f <> t: " k" ++ U64.show(S.sf_kind(S.sf_of(Ty.fa_surf(f)))) ++ kinds(t)

def run(+src: String, +a: U64, +b: U64) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_for(p, [a, b], [])
  +fa = Ty.brep_fas(brep_of(M.ce_r(M.ce_find(cs, a))))
  +fb = Ty.brep_fas(brep_of(M.ce_r(M.ce_find(cs, b))))
  "A " ++ Nat.show(List.length(&2, Ty.Face, fa)) ++ " B " ++ Nat.show(List.length(&2, Ty.Face, fb)) ++ kinds(fb) ++ pra(fa, fb, 0n)

def num(+s: String) -> U64:
  SX.u64_of(SX.Sx_a{s})

def to2(xs: List<&1, String>) -> List<&2, String>:
  match xs:
    case []: []
    case h <> t: h <> to2(t)

def go(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(SX.arg_at(args, 1n))
    IO.print(run(src, num(SX.arg_at(args, 2n)), num(SX.arg_at(args, 3n))))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(to2(args))
