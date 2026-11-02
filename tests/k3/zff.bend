import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c07/sol.bend as SO
import ../../src/c07/emb.bend as EM
import ../../src/c08/bool.bend as B8
import ../../src/c04/types.bend as Ty
import ../../src/c07/isect.bend as Y
import ../../src/c07/ss.bend as SS
import ../../src/c07/ivx.bend as X
import ../../src/c06/iv.bend as I
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

def tm(+tag: String, +t0: Nat, +t1: Nat) -> IO(Unit):
  IO.print(tag ++ " " ++ Nat.show(Nat.sub(t1, t0)))

def ivs_sum(xs: List<&2, I.I>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> t: ivs_sum(t, F64.add(acc, F64.add(I.i_lo(x), I.i_hi(x))))

def pts_sum(xs: List<&2, List<&2, I.I>>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> t: pts_sum(t, ivs_sum(x, acc))

def brs_sum(xs: List<&2, SS.Br>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +b <> t:
      SS.Br{c, pts, e} = b
      brs_sum(t, pts_sum(pts, F64.add(acc, 1.0f64)))

def sr_sum(r: Y.Sr) -> F64:
  Y.Sr{ss, k, co} = r
  SS.Ss{ok, brs, un} = ss
  pts_sum(un, brs_sum(brs, U64.to_f64(k)))

type FR is Data:
  FR{ v: F64 }

def ss_job_x(+c: EM.Cx, +p: EM.Pr) -> FR:
  EM.Cx{+te, +tf, +tef, +tol, +ns, +sfs} = c
  EM.Pr{+k, +a, +b} = p
  +x = B.tb_get(EM.Fg, tf, U32.from_nat(a))
  +y = B.tb_get(EM.Fg, tf, U32.from_nat(b))
  +fa = EM.fg_fd(x)
  +fb = EM.fg_fd(y)
  FR{sr_sum(Y.inter_ss(SO.fd_g(fa), SO.fd_g(fb), EM.pad(X.vmeet(SO.fd_bx(fa), SO.fd_bx(fb)))))}

def ss_job(c: EM.Cx, p: EM.Pr) -> FR:
  ss_job_x(c, p)

def fr_v(x: FR) -> F64:
  FR{v} = x
  v

def fr_sum(xs: List<&2, FR>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> t:
      FR{v} = x
      fr_sum(t, F64.add(acc, v))

def code_job_x(+c: EM.Cx, +p: EM.Pr) -> FR:
  EM.Cx{+te, +tf, +tef, +tol, +ns, +sfs} = c
  EM.Pr{+k, +a, +b} = p
  +x = B.tb_get(EM.Fg, tf, U32.from_nat(a))
  +y = B.tb_get(EM.Fg, tf, U32.from_nat(b))
  +fa = EM.fg_fd(x)
  +fb = EM.fg_fd(y)
  +cd = EM.ff_code(Y.flat_pl(SO.fd_g(fa)), Y.flat_pl(SO.fd_g(fb)))
  +sh = EM.es_share(EM.fg_es(x), EM.fg_es(y))
  FR{F64.add(U64.to_f64(cd), Bool.pick(F64, sh, 10.0f64, 0.0f64))}

def code_job(c: EM.Cx, p: EM.Pr) -> FR:
  code_job_x(c, p)

def only(ps: List<&2, EM.Pr>, +k: U64) -> List<&2, EM.Pr>:
  match ps:
    case []: []
    case +p <> +t:
      EM.Pr{+pk, +a, +b} = p
      +rest = only(t, k)
      Bool.pick(List<&2, EM.Pr>, U64.is_eq(pk, k), p <> rest, rest)

def cls_of(xs: List<&2, FR>, ps: List<&2, EM.Pr>, +want: F64) -> List<&2, EM.Pr>:
  match xs ps:
    case +x <> xt +p <> pt:
      +rest = cls_of(xt, pt, want)
      Bool.pick(List<&2, EM.Pr>, F64.is_eq(fr_v(x), want), p <> rest, rest)
    case _ _: []

def cls_t(+cx: EM.Cx, +cs: List<&2, FR>, +ps: List<&2, EM.Pr>, +w: F64) -> IO(Unit):
  +qs = cls_of(cs, ps, w)
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("class " ++ F64.show(w) ++ " pairs " ++ Nat.show(List.length(&2, EM.Pr, qs)) ++ " fi " ++ Nat.show(List.length(&2, SO.Fi, EM.run_prs(cx, qs))))
    t1 : Nat <- IO.now()
    v : Unit <- tm("full", t0, t1)
    t2 : Nat <- IO.now()
    w2 : Unit <- IO.print("ss sum " ++ F64.show(fr_sum(B.pmap_g(~EM.Pr, ~EM.Cx, ~FR, ~ss_job, 2, cx, qs), 0.0f64)))
    t3 : Nat <- IO.now()
    tm("inter_ss", t2, t3)

def k4(+cx: EM.Cx, +ps: List<&2, EM.Pr>, +cs: List<&2, FR>) -> IO(Unit):
  do IO<Unit>:
    a : Unit <- cls_t(cx, cs, ps, 0.0f64)
    b : Unit <- cls_t(cx, cs, ps, 10.0f64)
    c : Unit <- cls_t(cx, cs, ps, 1.0f64)
    d : Unit <- cls_t(cx, cs, ps, 11.0f64)
    e : Unit <- cls_t(cx, cs, ps, 2.0f64)
    f : Unit <- cls_t(cx, cs, ps, 12.0f64)
    g : Unit <- cls_t(cx, cs, ps, 3.0f64)
    h : Unit <- cls_t(cx, cs, ps, 13.0f64)
    i : Unit <- cls_t(cx, cs, ps, 4.0f64)
    cls_t(cx, cs, ps, 14.0f64)

def k3(+cx: EM.Cx, +ps: List<&2, EM.Pr>) -> IO(Unit):
  k4(cx, ps, B.pmap_g(~EM.Pr, ~EM.Cx, ~FR, ~code_job, 2, cx, ps))

def k2(+b: Ty.Brep, +fds: List<&2, SO.Fd>) -> IO(Unit):
  +x = Ty.ix_of(b)
  +egs = EM.egs_go(Ty.brep_es(b), Ty.ix_tv(x))
  +fgs = EM.shs_fg(Ty.brep_shs(b), x, fds, Ty.shmap_of(b), 0n)
  +cx = EM.mk_cx(egs, fgs, EM.tol_of(SO.bbox(fds, [])), List.length(&2, Ty.Solid, Ty.brep_sos(b)))
  k3(cx, only(EM.sweep(EM.its_of(egs, fgs)), 2u64))

def k1(+b: Ty.Brep) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    u : Unit <- IO.print("fds " ++ Nat.show(List.length(&2, SO.Fd, SO.fds_of(b))))
    t1 : Nat <- IO.now()
    v : Unit <- tm("fds_of", t0, t1)
    k2(b, SO.fds_of(b))

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  +p = S.part_of(S.ps_xs(S.parse(src)))
  +id = S.u64_of(S.Sx_a{S.arg_at(args, 2n)})
  k1(placed(M.ev_for(p, [id], []), id))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
