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
import ../../src/k1/ss.bend as SS
import ../../src/k1/sf.bend as KS
import ../../src/c03/types.bend as G
import ../../src/c01/types.bend as V
import ../../src/k1/ef.bend as EF

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

type ZS is Data:
  ZS{ s: String, seen: List<&2, V.Point> }

def b_s(b: Bool) -> String:
  match b:
    case True{}: "1"
    case False{}: "0"

def uv_s(+s: KS.SF, +p: V.Point) -> String:
  match s:
    case KS.SF_bp{gw}:
      +q = KS.bp_uv(KS.gbp(gw), p)
      F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q))
    case _: "-"

def p_s(+s1: KS.SF, +s2: KS.SF, +p: V.Point) -> String:
  "uv1 " ++ uv_s(s1, p) ++ " uv2 " ++ uv_s(s2, p) ++ " f1 " ++ F64.show(KS.sf_f(s1, p)) ++ " f2 " ++ F64.show(KS.sf_f(s2, p)) ++ " tok " ++ b_s(SS.fr_tok(s1, s2, p))

def bad_go(ps: List<&2, V.Point>, +s1: KS.SF, +s2: KS.SF, +gs: List<&2, G.GVal>, +bx: SS.BX, +n: Nat, +need_n: Nat, +got: Bool, +first: String) -> String:
  match ps:
    case []: "need " ++ Nat.show(need_n) ++ " bad " ++ Nat.show(n) ++ " first[" ++ first ++ "]"
    case +h <> +t:
      +need = Bool.and(Bool.and(SS.fr_in(s1, h), SS.fr_in(s2, h)), SS.bx_in(bx, h))
      +ok = EF.ct_ok(EF.cert_gs(gs, h))
      +b = Bool.and(need, Bool.not(ok))
      bad_go(t, s1, s2, gs, bx, Bool.pick(Nat, b, Nat.add(n, 1n), n), Bool.pick(Nat, need, Nat.add(need_n, 1n), need_n), Bool.or(got, b), Bool.pick(String, Bool.and(b, Bool.not(got)), p_s(s1, s2, h), first))

def last_p(ps: List<&2, V.Point>, +d: V.Point) -> V.Point:
  match ps:
    case []: d
    case +h <> +t: last_p(t, h)

def tr_s(+ps: List<&2, V.Point>, +cl: Bool, +ok: Bool, +p: V.Point, +s1: KS.SF, +s2: KS.SF, +gs: List<&2, G.GVal>, +bx: SS.BX) -> String:
  +a = " n " ++ Nat.show(List.length(&2, V.Point, ps)) ++ " closed " ++ b_s(cl) ++ " ok " ++ b_s(ok)
  +b = bad_go(ps, s1, s2, gs, bx, 0n, 0n, False{}, "")
  +c = p_s(s1, s2, last_p(List.reverse(&2, V.Point, ps), p))
  +d = p_s(s1, s2, last_p(ps, p))
  a ++ " " ++ b ++ "
   start " ++ c ++ "
   end " ++ d ++ "
"

def hd_s(+q: V.Vec2, +on: Bool) -> String:
  "seed " ++ F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q)) ++ " on " ++ b_s(on)

def one_s(skip: Bool, +q: V.Vec2, +on: Bool, +p: V.Point, +s1: KS.SF, +s2: KS.SF, +h: F64, +gs: List<&2, G.GVal>, +bx: SS.BX, +acc: String, +seen: List<&2, V.Point>) -> ZS:
  match skip:
    case True{}: ZS{acc ++ hd_s(q, on) ++ " skip
", seen}
    case False{}:
      +tr = SS.fr_seed(s1, s2, h, p, SS.bx_all())
      +ps = SS.tr_pts(tr)
      ZS{acc ++ hd_s(q, on) ++ tr_s(ps, SS.tr_closed(tr), SS.tr_ok(tr), p, s1, s2, gs, bx), List.append(&2, V.Point, ps, seen)}

def seeds_s(qs: List<&2, V.Vec2>, +sb: KS.SF, +s1: KS.SF, +s2: KS.SF, +h: F64, +gs: List<&2, G.GVal>, +bx: SS.BX, +z: ZS) -> String:
  match qs:
    case []:
      ZS{+acc, seen} = z
      acc
    case +q <> +t:
      ZS{+acc, +seen} = z
      +p1 = SS.fr_pt(sb, V.v2_x(q), V.v2_y(q), V.V2{0.0f64, 1.0f64})
      +tn = KS.dunit(SS.fr_tan(s1, s2, p1))
      +p = KS.newton2(10n, s1, s2, p1, tn, p1)
      +on = F64.is_lt(F64.max(F64.abs(KS.sf_f(s1, p)), F64.abs(KS.sf_f(s2, p))), F64.mul(1.0e-6f64, h))
      +skip = Bool.or(Bool.not(on), SS.fr_near(seen, p, F64.mul(1.5f64, h)))
      seeds_s(t, sb, s1, s2, h, gs, bx, one_s(skip, q, on, p, s1, s2, h, gs, bx, acc, seen))

def pair_x(+gs: List<&2, G.GVal>, +bx: SS.BX) -> String:
  +x = SS.ssi_b(EF.g_at(gs, 0n), EF.g_at(gs, 1n), bx)
  " ics " ++ Nat.show(List.length(&2, SS.IC, SS.ics_ics(x))) ++ " why " ++ U64.show(SS.ics_why(x)) ++ "
"

def pair_t(+s1: KS.SF, +s2: KS.SF, +gs: List<&2, G.GVal>, +bx: SS.BX) -> String:
  +b1 = KS.is_bp(s1)
  +sb = Bool.pick(KS.SF, b1, s1, s2)
  +so = Bool.pick(KS.SF, b1, s2, s1)
  +h = SS.fr_h(s1, s2)
  +qs = SS.fr_seeds(sb, so, V.V2{0.0f64, 1.0f64})
  " h " ++ F64.show(h) ++ " seeds " ++ Nat.show(List.length(&2, V.Vec2, qs)) ++ pair_x(gs, bx) ++ seeds_s(qs, sb, s1, s2, h, gs, bx, ZS{"", []})

def pair_g(+gs: List<&2, G.GVal>, +bx: SS.BX) -> String:
  pair_t(KS.sf_of(EF.g_at(gs, 0n)), KS.sf_of(EF.g_at(gs, 1n)), gs, bx)

def pair_s(+ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat) -> String:
  "pair " ++ Nat.show(fa) ++ " " ++ Nat.show(fb) ++ pair_g({[FB.face_surf(ba, fa), FB.face_surf(bb, fb)] : List<&2, G.GVal>}, PX.pj_box(FB.face_bb(ba, fa), FB.face_bb(bb, fb)))

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +ia = S.u64_of(S.Sx_a{S.arg_at(args, 2n)})
  +ib = S.u64_of(S.Sx_a{S.arg_at(args, 3n)})
  +fa = U64.to_nat(S.u64_of(S.Sx_a{S.arg_at(args, 4n)}))
  +fb = U64.to_nat(S.u64_of(S.Sx_a{S.arg_at(args, 5n)}))
  +cs = M.ev_for(p, [ia, ib], [])
  +ba = FB.kb_of(placed(cs, ia))
  +bb = FB.kb_of(placed(cs, ib))
  IO.print(pair_s(ba, fa, bb, fb))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
