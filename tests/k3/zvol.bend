import Base
import ../../src/k1/ef.bend as EF
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

def placed(+cs: List<&2, M.CE>, +id: U64) -> Ty.Brep:
  +b = M.nr_body(M.ce_r(M.ce_find(cs, id)))
  +pl = M.bd_pl(b)
  B8.xf_brep(M.pl_m(pl), M.pl_tx(pl), M.pl_ty(pl), M.pl_tz(pl), M.bd_brep(b))

def pt_s(+p: V.Point) -> String:
  F64.show(V.pt_x(p)) ++ " " ++ F64.show(V.pt_y(p)) ++ " " ++ F64.show(V.pt_z(p))

def fv_s(fs: List<&2, Nat>, +b: FB.KB, +c: V.Point) -> String:
  match fs:
    case []: ""
    case +h <> +t:
      +a = VI.face_va(b, h, c)
      "face " ++ Nat.show(h) ++ " kind " ++ U64.show(KS.sf_kind(KS.sf_of(FB.face_surf(b, h)))) ++ " vol " ++ F64.show(VI.va_vol(a)) ++ " slv " ++ F64.show(VI.va_slv(a)) ++ " ar " ++ F64.show(VI.va_ar(a)) ++ "
" ++ fv_s(t, b, c)

def gk2(c: G.GVal) -> String:
  match c:
    case G.GV_ln{w}: "line"
    case G.GV_cc{w}: "circle"
    case G.GV_bz{w}: "bezier"
    case G.GV_rq{w}: "rquad"
    case _: "other"

def ek_of(+b: FB.KB, +e: Nat) -> Ty.EdgeKind:
  Ty.ed_kind(FB.edge_at(b, e))

def uv_s(+gs: List<&2, G.GVal>, +p: V.Point) -> String:
  +q = KS.bp_uv(KS.gbp(gs), p)
  F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q))

def contrib_s(+gs: List<&2, G.GVal>, +b: FB.KB, +e: Nat, +fw: Bool, +c: V.Point) -> String:
  +r = VI.bw_ce(EF.ek_is_curve(ek_of(b, e)), 96n, KS.gbp(gs), c, ek_of(b, e), fw)
  " dvol " ++ F64.show(F64.div(V.v2_x(r), 3.0f64)) ++ " dar " ++ F64.show(V.v2_y(r))

def ends_s(+gs: List<&2, G.GVal>, +b: FB.KB, +e: Nat) -> String:
  " uv0 " ++ uv_s(gs, EF.ev(EF.ek_curve(ek_of(b, e)), EF.ek_lo(ek_of(b, e)))) ++ " uv1 " ++ uv_s(gs, EF.ev(EF.ek_curve(ek_of(b, e)), EF.ek_hi(ek_of(b, e))))

def kind_s2(+b: FB.KB, +e: Nat) -> String:
  gk2(EF.ek_curve(ek_of(b, e))) ++ " [" ++ F64.show(EF.ek_lo(ek_of(b, e))) ++ "," ++ F64.show(EF.ek_hi(ek_of(b, e))) ++ "]"

def samp_s(n: Nat, +gs: List<&2, G.GVal>, +b: FB.KB, +e: Nat, +k: F64) -> String:
  match n:
    case 0n: ""
    case 1n+m:
      +lo = EF.ek_lo(ek_of(b, e))
      +hi = EF.ek_hi(ek_of(b, e))
      +t = F64.add(lo, F64.mul(F64.div(k, 8.0f64), F64.sub(hi, lo)))
      +p = EF.ev(EF.ek_curve(ek_of(b, e)), t)
      +q = KS.bp_uv(KS.gbp(gs), p)
      "   t " ++ F64.show(t) ++ " uv " ++ F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q)) ++ " res " ++ F64.show(KS.dist(KS.bp_at(KS.gbp(gs), V.v2_x(q), V.v2_y(q)), p)) ++ "
" ++ samp_s(m, gs, b, e, F64.add(k, 1.0f64))

def step_s(n: Nat, +gs: List<&2, G.GVal>, +c: V.Point, +b: FB.KB, +e: Nat, +k: F64, +q: V.Vec2) -> String:
  match n:
    case 0n: ""
    case 1n+m:
      +lo = EF.ek_lo(ek_of(b, e))
      +hi = EF.ek_hi(ek_of(b, e))
      +t = F64.add(lo, F64.mul(k, F64.div(F64.sub(hi, lo), 48.0f64)))
      +q1 = KS.bp_uv(KS.gbp(gs), EF.ev(EF.ek_curve(ek_of(b, e)), t))
      +g1 = VI.bg_at(KS.gbp(gs), c, q1)
      Bool.pick(String, F64.is_lt(1.0e-9f64, F64.abs(F64.sub(V.v2_y(q1), V.v2_y(q)))), "   step t " ++ F64.show(t) ++ " q " ++ F64.show(V.v2_x(q1)) ++ "," ++ F64.show(V.v2_y(q1)) ++ " dv " ++ F64.show(F64.sub(V.v2_y(q1), V.v2_y(q))) ++ " p " ++ pt_s(EF.ev(EF.ek_curve(ek_of(b, e)), t)) ++ " G " ++ F64.show(V.v2_x(g1)) ++ "," ++ F64.show(V.v2_y(g1)) ++ "
", "") ++ step_s(m, gs, c, b, e, F64.add(k, 1.0f64), q1)

def bwn_s(ns: List<&2, Nat>, +gs: List<&2, G.GVal>, +b: FB.KB, +e: Nat, +fw: Bool, +c: V.Point) -> String:
  match ns:
    case []: "
"
    case +n <> +t:
      +r = VI.bw_k(n, KS.gbp(gs), c, ek_of(b, e), fw)
      " n" ++ Nat.show(n) ++ "=" ++ F64.show(V.v2_y(r)) ++ bwn_s(t, gs, b, e, fw, c)

def ce_rows(cs: List<&2, FB.CE>, +b: FB.KB, +gs: List<&2, G.GVal>, +c: V.Point) -> String:
  match cs:
    case []: ""
    case +h <> +t:
      +e = FB.ce_e(h)
      +fw = FB.ce_fw(h)
      "  e " ++ Nat.show(e) ++ " fw " ++ Bool.pick(String, fw, "1", "0") ++ " " ++ kind_s2(b, e) ++ ends_s(gs, b, e) ++ contrib_s(gs, b, e, fw, c) ++ "
" ++ bwn_s([1n, 2n, 4n, 8n, 16n, 32n, 48n, 64n, 96n], gs, b, e, fw, c) ++ step_s(49n, gs, c, b, e, 0.0f64, KS.bp_uv(KS.gbp(gs), EF.ev(EF.ek_curve(ek_of(b, e)), EF.ek_lo(ek_of(b, e))))) ++ ce_rows(t, b, gs, c)

def lp_rows(ls: List<&2, List<&2, FB.CE>>, +b: FB.KB, +gs: List<&2, G.GVal>, +c: V.Point) -> String:
  match ls:
    case []: ""
    case +h <> +t: " loop
" ++ ce_rows(h, b, gs, c) ++ lp_rows(t, b, gs, c)

def face_rows(+s: KS.SF, +b: FB.KB, +fi: Nat, +c: V.Point) -> String:
  match s:
    case KS.SF_bp{+gw}: lp_rows(FB.face_ce(b, fi), b, gw, c)
    case _: " not a patch
"

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +ia = S.u64_of(S.Sx_a{S.arg_at(args, 2n)})
  +cs = M.ev_for(p, [ia], [])
  +b = FB.kb_of(placed(cs, ia))
  +c = VI.center_of(b)
  +fx = U64.to_nat(S.u64_of(S.Sx_a{S.arg_at(args, 3n)}))
  IO.print("center " ++ pt_s(c) ++ "
faces " ++ Nat.show(FB.nfaces(b)) ++ "
" ++ fv_s(L.nat_range(FB.nfaces(b)), b, c) ++ "detail face " ++ Nat.show(fx) ++ "
" ++ face_rows(KS.sf_of(FB.face_surf(b, fx)), b, fx, c) ++ "end")

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
