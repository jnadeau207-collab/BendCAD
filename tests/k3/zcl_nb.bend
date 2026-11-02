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

def iv_s(+x: I.I) -> String:
  "[" ++ F64.show(I.i_lo(x)) ++ "," ++ F64.show(I.i_hi(x)) ++ "]"

def bx_s(+b: List<&2, I.I>) -> String:
  iv_s(X.vn(b, 0n)) ++ " " ++ iv_s(X.vn(b, 1n)) ++ " " ++ iv_s(X.vn(b, 2n))

def cb_s(+x: QL.Cb) -> String:
  QL.Cb{+a, +b, +fs, +fl, ra, rb} = x
  +fa = QL.f0(fs)
  +fb = QL.f1(fs)
  kind(SO.fd_im(fa)) ++ Nat.show(SO.fd_fi(fa)) ++ " vs " ++ kind(SO.fd_im(fb)) ++ Nat.show(SO.fd_fi(fb)) ++
    " boxgap " ++ F64.show(QL.box_gap(a, b)) ++ " mer " ++ F64.show(QL.mer(SO.fd_im(fa), SO.fd_im(fb), a, b)) ++
    " m2 " ++ F64.show(QL.mer2(SO.fd_im(fa), SO.fd_im(fb), a, b, ra, rb)) ++ " sd " ++ F64.show(QL.sdist(SO.fd_im(fb), a)) ++ "/" ++ F64.show(QL.sdist(SO.fd_im(fa), b)) ++ " fl " ++ F64.show(fl) ++
    "
   A " ++ bx_s(a) ++ "
   B " ++ bx_s(b)

def is_some(m: Maybe<&2, List<&2, I.I>>) -> Bool:
  match m:
    case None{}: False{}
    case Some{v}: True{}

def ft_s(+f: QL.Ft) -> String:
  match f:
    case QL.Ft_no{}: "no"
    case QL.Ft_r{+p, +h, +e}: "rect " ++ iv_s(p) ++ " " ++ iv_s(h) ++ " e " ++ F64.show(e)
    case QL.Ft_a{+x, +e}:
      QL.Ar{+cr, +ch, +r, +a, +b, +sg} = x
      "arc c " ++ F64.show(cr) ++ "," ++ F64.show(ch) ++ " r " ++ F64.show(r) ++ " s " ++ F64.show(sg) ++ " e " ++ F64.show(e)

def ew_s(es: List<&2, Mm.Er>, +o: List<&2, I.I>, +a: List<&2, I.I>) -> String:
  match es:
    case []: ""
    case +e <> +t:
      +c = Mm.er_c(e)
      " [" ++ iv_s(QL.alg_rho(o, a, c)) ++ " " ++ iv_s(QL.ax_h(o, a, R.cv_hbox(c))) ++ "]" ++ ew_s(t, o, a)

def ac_s(+st: QL.Ac) -> String:
  QL.Ac{+ok, +n, +a, +b} = st
  "ac ok " ++ Bool.pick(String, ok, "1", "0") ++ " n " ++ Nat.show(n)

def dbg_t(s: Im.Im, +f: SO.Fd) -> String:
  match s:
    case Im.M_to{+o, +a, +bigr, +r}:
      +cr = I.imid(bigr)
      +ch = I.imid(QL.ax_h(o, a, o))
      +z = {QL.U2{1.0f64, 0.0f64} : QL.U2}
      "  edges" ++ ew_s(Mm.fc_es(SO.fd_fc(f)), o, a) ++ "
  " ++ ac_s(QL.ac_go(Mm.fc_es(SO.fd_fc(f)), o, a, cr, ch, QL.wtol(cr, ch, I.imid(r)), QL.Ac{True{}, 0n, z, z})) ++
        " interior " ++ Bool.pick(String, is_some(SO.interior(f)), "yes", "no") ++ "
  ft " ++ ft_s(QL.ft_of(Im.M_to{o, a, bigr, r}, o, a, f, QL.rr_all()))
    case _: ""

def tops(n: Nat, h: QL.Ph) -> String:
  match n:
    case 0n: ""
    case 1n+m:
      match h:
        case QL.Ph_e{}: ""
        case QL.Ph_n{+k, q, +w, +x, +cs}: "lb " ++ F64.show(k) ++ " w " ++ F64.show(w) ++ " " ++ cb_s(x) ++ "
" ++ tops(m, QL.pairs(cs))

def dbg_all(xs: List<&2, QL.Cb>) -> String:
  match xs:
    case []: ""
    case +x <> +t:
      QL.Cb{+a, +b, +fs, +fl, ra, rb} = x
      +fa = QL.f0(fs)
      +fb = QL.f1(fs)
      Bool.pick(String, Bool.and(Nat.is_eq(SO.fd_fi(fa), 290n), Nat.is_eq(SO.fd_fi(fb), 15n)),
        "pair 290/15 rr " ++ iv_s(QL.rr_pair(SO.fd_im(fa), SO.fd_im(fb), fa)) ++ "
" ++ dbg_t(SO.fd_im(fb), fb) ++ "
", "") ++ dbg_all(t)

def run_h(fuel: Nat, h: QL.Ph, +hi: F64, +eps: F64) -> QL.Ph:
  match fuel:
    case 0n: h
    case 1n+f:
      match h:
        case QL.Ph_e{}: QL.Ph_e{}
        case QL.Ph_n{k, q, bw, +x, +cs}:
          run_h(f, QL.push_all(QL.kids(x, F64.mul(0.5f64, hi)), QL.pairs(cs), False{}, hi, eps), hi, eps)

def go2(+a: M.Body, +b: M.Body, +fuel: Nat) -> String:
  +hi = QD.pts_min(QI.sms_of(a), QI.sms_of(b), V.dbl_max())
  +cs = QL.cross(QL.world_fds(a), QL.world_fds(b), [])
  +h0 = QL.root_all(cs, QL.Ph_e{}, False{}, hi, 0.001f64)

  "hi " ++ F64.show(hi) ++ " pairs " ++ Nat.show(List.length(&2, QL.Cb, cs)) ++ "
roots
" ++ tops(6n, h0) ++
    "dbg
" ++ dbg_all(cs) ++ "after " ++ Nat.show(fuel) ++ "
" ++ tops(6n, run_h(fuel, h0, hi, 0.001f64))

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +ia = S.u64_of(S.Sx_a{S.arg_at(args, 2n)})
  +ib = S.u64_of(S.Sx_a{S.arg_at(args, 3n)})
  +cs = M.ev_for(p, [ia, ib], [])
  IO.print(go2(body_of(cs, ia), body_of(cs, ib), U64.to_nat(S.u64_of(S.Sx_a{S.arg_at(args, 4n)}))))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
