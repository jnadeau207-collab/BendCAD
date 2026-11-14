import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c07/sol.bend as SO
import ../../src/c07/emb.bend as EM
import ../../src/c08/bool.bend as B8
import ../../src/c04/types.bend as Ty
import ../../src/c11/qclear.bend as QL
import ../../src/c11/qdist.bend as QD
import ../../src/c11/qinterf.bend as QI
import ../../src/c07/im.bend as Im
import ../../src/c06/iv.bend as I
import ../../src/c07/ivx.bend as X
import ../../src/c01/types.bend as V
import ../../src/c07/mem.bend as Mm
import ../../src/c07/rb.bend as R
import ../../src/base/par.bend as BP

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

def body_of(cs: List<&2, M.CE>, +id: U64) -> M.Body:
  M.nr_body(M.ce_r(M.ce_find(cs, id)))

def kind(s: Im.Im) -> String:
  match s:
    case Im.M_pl{o, n}: "pl"
    case Im.M_sp{c, r}: "sp"
    case Im.M_cy{o, a, r}: "cy"
    case Im.M_co{o, a, k}: "co"
    case Im.M_to{o, a, b, r}: "to"
    case Im.M_no{}: "no"

def en_s(e: QL.En) -> String:
  match e:
    case QL.En_f{+f}: "f" ++ kind(SO.fd_im(f)) ++ Nat.show(SO.fd_fi(f))
    case QL.En_e{c, +s}: "e" ++ kind(s)
    case QL.En_v{}: "v"

def iv_s(+x: I.I) -> String:
  "[" ++ F64.show(I.i_lo(x)) ++ "," ++ F64.show(I.i_hi(x)) ++ "]"

def bx_s(+b: List<&2, I.I>) -> String:
  iv_s(X.vn(b, 0n)) ++ " " ++ iv_s(X.vn(b, 1n)) ++ " " ++ iv_s(X.vn(b, 2n))

def tag(+x: QL.Cb) -> String:
  QL.Cb{+a, +b, ra, rb} = x
  en_s(QL.cl_e(a)) ++ ":" ++ en_s(QL.cl_e(b))

type Ag is Data:
  Ag{ s: String, n: Nat, lo: F64, w: F64 }

def ag_put(xs: List<&2, Ag>, +t: String, +k: F64, +w: F64) -> List<&2, Ag>:
  match xs:
    case []: [Ag{t, 1n, k, w}]
    case Ag{+s, +n, +lo, +ww} <> +r:
      Bool.pick(List<&2, Ag>, String.eq(s, t), Ag{s, Nat.add(n, 1n), F64.min(lo, k), F64.min(ww, w)} <> r, Ag{s, n, lo, ww} <> ag_put(r, t, k, w))

def ag_heap(hs: List<&2, QL.Ph>, +acc: List<&2, Ag>) -> List<&2, Ag>:
  match hs:
    case []: acc
    case +h <> +t:
      match h:
        case QL.Ph_e{}: ag_heap(t, acc)
        case QL.Ph_n{+k, q, +w, +x, +cs}: ag_heap(t, ag_heap(cs, ag_put(acc, tag(x), k, w)))

def ag_s(xs: List<&2, Ag>) -> String:
  match xs:
    case []: ""
    case Ag{+s, +n, +lo, +w} <> +t: "AG " ++ Nat.show(n) ++ " " ++ s ++ " lo " ++ F64.show(lo) ++ " minw " ++ F64.show(w) ++ "
" ++ ag_s(t)

def tops(n: Nat, h: QL.Ph) -> String:
  match n:
    case 0n: ""
    case 1n+m:
      match h:
        case QL.Ph_e{}: ""
        case QL.Ph_n{+k, q, +w, +x, +cs}:
          QL.Cb{+a, +b, ra, rb} = x
          "lb " ++ F64.show(k) ++ " w " ++ F64.show(w) ++ " " ++ tag(x) ++ " lbk " ++ F64.show(QL.lbk(False{}, x)) ++ " wit " ++ F64.show(QL.wit(False{}, x, V.dbl_max())) ++ "
   A " ++ bx_s(QL.cl_bx(a)) ++ "
   B " ++ bx_s(QL.cl_bx(b)) ++ "
" ++ tops(m, QL.pairs(cs))

type St is Data:
  St{ h: QL.Ph, hi: F64, left: Nat }

def run_h(fuel: Nat, stop: Bool, h: QL.Ph, +w: Bool, +hi: F64) -> St:
  match fuel:
    case 0n: St{h, hi, 0n}
    case 1n+(+f):
      match stop:
        case True{}: St{h, hi, Nat.add(f, 1n)}
        case False{}:
          match h:
            case QL.Ph_e{}: St{QL.Ph_e{}, hi, Nat.add(f, 1n)}
            case QL.Ph_n{+k, q, +bw, +x, +cs}:
              +leaf = F64.is_le(bw, QL.eps_of(hi, 0.0f64))
              +hw = F64.min(hi, QL.wit_if(Bool.or(leaf, Nat.is_eq(Nat.mod(f, 8n), 0n)), w, x, hi))
              +eps = QL.eps_of(hw, 0.0f64)
              +h2 = QL.step(leaf, k, x, cs, w, hw, eps)
              run_h(f, QL.stop_of(h2, hw, eps), h2, w, hw)

def rep_st(+st: St, +h0: QL.Ph, +hi: F64, +fuel: Nat) -> String:
  St{+h, +hw, +left} = st
  "hi " ++ F64.show(hi) ++ "
ROOTS
" ++ ag_s(ag_heap([h0], [])) ++ "AFTER fuel " ++ Nat.show(fuel) ++ " left " ++ Nat.show(left) ++ " hi " ++ F64.show(hw) ++ " minlb " ++ F64.show(QL.ph_min(h, hw)) ++ "
" ++ ag_s(ag_heap([h], [])) ++ "TOP
" ++ tops(5n, h)

def go_c(+a: M.Body, +b: M.Body, +fuel: Nat) -> String:
  +hi = QD.pts_min(QI.sms_of(a), QI.sms_of(b), V.dbl_max())
  +ea = QL.ents(a)
  +eb = QL.ents(b)
  +h0 = QL.root_a(QL.cull(QL.el_cs(ea), QL.el_bb(eb), hi), QL.cull(QL.el_cs(eb), QL.el_bb(ea), hi), QL.Ph_e{}, hi, QL.eps_of(hi, 0.0f64))
  +h1 = F64.min(hi, QL.wit_ph([h0], False{}, hi))
  rep_st(run_h(fuel, QL.stop_of(h0, h1, QL.eps_of(h1, 0.0f64)), h0, False{}, h1), h0, h1, fuel)

def go_w(+b: M.Body, +fuel: Nat) -> String:
  +fs = SO.fds_of(M.bd_brep(b))
  +cap = QL.diag(SO.bbox(fs, []))
  +h0 = QL.wroot_a(QL.en_fs(fs), QL.Ph_e{}, cap, QL.eps_of(cap, 0.0f64))
  +h1 = F64.min(cap, QL.wit_ph([h0], True{}, cap))
  rep_st(run_h(fuel, QL.stop_of(h0, h1, QL.eps_of(h1, 0.0f64)), h0, True{}, h1), h0, h1, fuel)

def pick(mode: U64, +a: M.Body, +b: M.Body, +fuel: Nat) -> String:
  match mode:
    case 0u64: go_c(a, b, fuel)
    case _: go_w(a, fuel)

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +ia = S.u64_of(S.Sx_a{S.arg_at(args, 3n)})
  +ib = S.u64_of(S.Sx_a{S.arg_at(args, 4n)})
  +cs = M.ev_for(p, [ia, ib], [])
  IO.print(pick(S.u64_of(S.Sx_a{S.arg_at(args, 2n)}), body_of(cs, ia), body_of(cs, ib), U64.to_nat(S.u64_of(S.Sx_a{S.arg_at(args, 5n)}))))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
