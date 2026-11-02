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
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
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


type KA is Data:
  KA{ ok: Bool, ks: List<&2, U64> }

type KF is Data:
  KF{ k: List<&2, U64>, f: SO.Fd }

def kf(+x: F64, +acc: List<&2, U64>) -> List<&2, U64>:
  F64.bits(x) <> acc

def kpt(+p: V.Point, +acc: List<&2, U64>) -> List<&2, U64>:
  V.Pt{+x, +y, +z} = p
  kf(x, kf(y, kf(z, acc)))

def kdr(+d: V.Dir, +acc: List<&2, U64>) -> List<&2, U64>:
  V.Dr{+x, +y, +z} = d
  kf(x, kf(y, kf(z, acc)))

def kgv(+g: G.GVal, +ok: Bool, +acc: List<&2, U64>) -> KA:
  match g:
    case G.GV_ln{+v}:
      G.Ln{+p, +d} = v
      KA{ok, 1u64 <> kpt(p, kdr(d, acc))}
    case G.GV_pl{+v}:
      G.Pl{+o, +u, +w} = v
      KA{ok, 2u64 <> kpt(o, kdr(u, kdr(w, acc)))}
    case G.GV_cc{+v}:
      G.Cc{+c, +u, +w, +r} = v
      KA{ok, 3u64 <> kpt(c, kdr(u, kdr(w, kf(r, acc))))}
    case G.GV_bz{+v}:
      G.Bz{+p0, +p1, +p2, +p3} = v
      KA{ok, 4u64 <> kpt(p0, kpt(p1, kpt(p2, kpt(p3, acc))))}
    case G.GV_rq{+v}:
      G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = v
      KA{ok, 5u64 <> kpt(p0, kpt(p1, kpt(p2, kf(w0, kf(w1, kf(w2, acc))))))}
    case G.GV_sp{+v}:
      G.Sp{+c, +r} = v
      KA{ok, 7u64 <> kpt(c, kf(r, acc))}
    case G.GV_cy{+v}:
      G.Cy{+o, +d, +r} = v
      KA{ok, 8u64 <> kpt(o, kdr(d, kf(r, acc)))}
    case G.GV_co{+v}:
      G.Co{+o, +d, +k} = v
      KA{ok, 9u64 <> kpt(o, kdr(d, kf(k, acc)))}
    case G.GV_to{+v}:
      G.To{+o, +d, +rr, +r} = v
      KA{ok, 10u64 <> kpt(o, kdr(d, kf(rr, kf(r, acc))))}
    case _: KA{False{}, acc}

def kbool(+b: Bool, +acc: List<&2, U64>) -> List<&2, U64>:
  Bool.pick(U64, b, 1u64, 0u64) <> acc

def kek(k: Ty.EdgeKind, +fwd: Bool, +a: KA) -> KA:
  match k:
    case Ty.EK_curve{+c, +d}:
      G.Dom{+lo, +hi} = d
      KA{+ok, +acc} = a
      kgv(c, ok, 11u64 <> kbool(fwd, kf(lo, kf(hi, acc))))
    case Ty.EK_degenerate{}:
      KA{+ok, +acc} = a
      KA{ok, 12u64 <> kbool(fwd, acc)}

def ked(e: Ty.Edge, +fwd: Bool, +a: KA) -> KA:
  Ty.Ed{g, v0, v1, k} = e
  kek(k, fwd, a)

def kce(ce: Ty.Coedge, +x: Ty.Ix, +a: KA) -> KA:
  Ty.Ce{g, eh, +fwd, tr} = ce
  ked(Ty.tres_ed(Ty.ix_ed(x, eh)), fwd, a)

def kces(hs: List<&2, Ty.HCoedge>, +x: Ty.Ix, +a: KA) -> KA:
  match hs:
    case []: a
    case h <> t: kces(t, x, kce(Ty.tres_ce(Ty.ix_ce(x, h)), x, a))

def ksep(+a: KA) -> KA:
  KA{+ok, +acc} = a
  KA{ok, 13u64 <> acc}

def klp(l: Ty.Loop, +x: Ty.Ix, +a: KA) -> KA:
  Ty.Lp{g, cs, k} = l
  ksep(kces(cs, x, a))

def klps(hs: List<&2, Ty.HLoop>, +x: Ty.Ix, +a: KA) -> KA:
  match hs:
    case []: a
    case h <> t: klps(t, x, klp(Ty.tres_lp(Ty.ix_lp(x, h)), x, a))

def fkey(f: Ty.Face, +x: Ty.Ix) -> KA:
  Ty.Fa{g, +s, ls, +same, +slv, sla} = f
  klps(ls, x, kgv(s, True{}, kbool(same, kf(slv, []))))

def fk_hs(hs: List<&2, Ty.HFace>, +x: Ty.Ix) -> List<&2, KA>:
  match hs:
    case []: []
    case +h <> t: fkey(Ty.tres_fa(Ty.ix_fa(x, h)), x) <> fk_hs(t, x)

def fk_shs(ss: List<&2, Ty.Shell>, +x: Ty.Ix) -> List<&2, KA>:
  match ss:
    case []: []
    case s <> t:
      Ty.Sh{g, hs, k} = s
      List.append(&2, KA, fk_hs(hs, x), fk_shs(t, x))

def fkeys(+b: Ty.Brep) -> List<&2, KA>:
  fk_shs(Ty.brep_shs(b), Ty.ix_of(b))

def klt(a: List<&2, U64>, b: List<&2, U64>) -> Bool:
  match a:
    case []:
      match b:
        case []: False{}
        case +y <> yt: True{}
    case +x <> xt:
      match b:
        case []: False{}
        case +y <> yt: Bool.or(U64.is_lt(x, y), Bool.and(U64.is_eq(x, y), klt(xt, yt)))

def keq(a: List<&2, U64>, b: List<&2, U64>) -> Bool:
  match a:
    case []:
      match b:
        case []: True{}
        case +y <> yt: False{}
    case +x <> xt:
      match b:
        case []: False{}
        case +y <> yt: Bool.and(U64.is_eq(x, y), keq(xt, yt))


def ka_one(+a: KA, +rest: List<&2, List<&2, U64>>) -> List<&2, List<&2, U64>>:
  KA{+ok, +ks} = a
  Bool.pick(List<&2, List<&2, U64>>, ok, ks <> rest, rest)

def ka_ok(xs: List<&2, KA>) -> List<&2, List<&2, U64>>:
  match xs:
    case []: []
    case +k <> t: ka_one(k, ka_ok(t))

def kas(+b: Ty.Brep) -> List<&2, List<&2, U64>>:
  ka_ok(fkeys(b))

def mem_k(xs: List<&2, List<&2, U64>>, +k: List<&2, U64>) -> Bool:
  match xs:
    case []: False{}
    case +h <> t: Bool.or(keq(h, k), mem_k(t, k))

def cnt(ks: List<&2, List<&2, U64>>, +pool: List<&2, List<&2, U64>>, +n: Nat) -> Nat:
  match ks:
    case []: n
    case +k <> t: cnt(t, pool, Nat.add(n, Bool.pick(Nat, mem_k(pool, k), 1n, 0n)))

def go2(+bc: Ty.Brep, +ra: Ty.Brep, +rb: Ty.Brep) -> IO(Unit):
  IO.print("result keys " ++ Nat.show(List.length(&2, List<&2, U64>, kas(bc))) ++ " hits_in_a " ++ Nat.show(cnt(kas(bc), kas(ra), 0n)) ++ " hits_in_b " ++ Nat.show(cnt(kas(bc), kas(rb), 0n)) ++ " a_faces " ++ nf(ra))

def s1(+p: M.Part, +a: U64, +b: U64, +c: U64) -> IO(Unit):
  +cs = M.ev_for(p, [c], [])
  go2(placed(cs, c), placed(cs, a), placed(cs, b))

def go(+args: List<&2, String>, +src: String) -> IO(Unit):
  s1(S.part_of(S.ps_xs(S.parse(src))), S.u64_of(S.Sx_a{S.arg_at(args, 2n)}), S.u64_of(S.Sx_a{S.arg_at(args, 3n)}), S.u64_of(S.Sx_a{S.arg_at(args, 4n)}))

def run(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(S.arg_at(args, 1n))
    go(args, src)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    run(S.args_l(args))
