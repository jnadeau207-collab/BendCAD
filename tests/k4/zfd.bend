import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c03/types.bend as G
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as SX
import ../../src/c06/tess.bend as TS
import ../../src/c10/mesh.bend as M10
import ../../src/k1/sf.bend as S
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

def ud(n: Nat, xs: List<&2, U64>, ys: List<&2, U64>, +acc: List<&2, U64>) -> List<&2, U64>:
  match n:
    case 0n: acc
    case 1n+(+m):
      match xs:
        case []: acc
        case +x <> +xt:
          match ys:
            case []: ud(m, xt, [], x <> acc)
            case +y <> +yt:
              +eq = U64.is_eq(x, y)
              +lt = U64.is_lt(x, y)
              ud(m, Bool.pick(List<&2, U64>, Bool.or(eq, lt), xt, x <> xt), Bool.pick(List<&2, U64>, lt, y <> yt, yt),
                Bool.pick(List<&2, U64>, Bool.and(Bool.not(eq), lt), x <> acc, acc))

def ud_c(c: U64, n: Nat, +x: U64, +xt: List<&2, U64>, +y: U64, +yt: List<&2, U64>, +acc: List<&2, U64>) -> List<&2, U64>:
  match c:
    case 0u64: ud(n, xt, yt, acc)
    case 1u64: ud(n, xt, y <> yt, x <> acc)
    case _: ud(n, x <> xt, yt, acc)

def sk(+xs: List<&2, U64>) -> List<&2, U64>:
  TS.so_u(B.msort(~U64, ~TS.u_cmp, xs))

def kshow(n: Nat, xs: List<&2, U64>) -> String:
  match n:
    case 0n: ""
    case 1n+(+m):
      match xs:
        case []: ""
        case +x <> t: " (" ++ U64.show(U64.div(x, 4294967296u64)) ++ "," ++ U64.show(U64.mod(x, 4294967296u64)) ++ ")" ++ kshow(m, t)

def hd_id(r: List<&2, TS.TP>, +d: Nat) -> Nat:
  match r:
    case []: d
    case +h <> t: TS.tp_id(h)

def seg_go(r: List<&2, TS.TP>, +first: Nat, +acc: List<&2, U64>) -> List<&2, U64>:
  match r:
    case []: acc
    case +h <> +t: seg_go(t, first, TS.ek(TS.tp_id(h), hd_id(t, first)) <> acc)

def segs(rs: List<&2, List<&2, TS.TP>>, +acc: List<&2, U64>) -> List<&2, U64>:
  match rs:
    case []: acc
    case +r <> t: segs(t, seg_go(r, hd_id(r, 0n), acc))

def rk(xs: List<&2, U64>) -> List<&2, U64>:
  match xs:
    case []: []
    case +x <> t: U64.add(U64.mul(U64.mod(x, 4294967296u64), 4294967296u64), U64.div(x, 4294967296u64)) <> rk(t)

def miss(+ss: List<&2, U64>, +es: List<&2, U64>) -> List<&2, U64>:
  +a = sk(ss)
  +b = sk(es)
  ud(Nat.mul(2n, Nat.add(List.length(&2, U64, a), List.length(&2, U64, b))), a, b, [])

def p_s(+tb: B.Tb<&2, V.Point>, +i: U64) -> String:
  +p = B.tb_get(V.Point, tb, U64.to_u32(i))
  "(" ++ F64.show(V.pt_x(p)) ++ " " ++ F64.show(V.pt_y(p)) ++ " " ++ F64.show(V.pt_z(p)) ++ ")"

def mshow(n: Nat, xs: List<&2, U64>, +tb: B.Tb<&2, V.Point>, +nb: U64) -> String:
  match n:
    case 0n: ""
    case 1n+(+m):
      match xs:
        case []: ""
        case +x <> t:
          +a = U64.div(x, 4294967296u64)
          +b = U64.mod(x, 4294967296u64)
          " [" ++ U64.show(a) ++ Bool.pick(String, U64.is_lt(a, nb), p_s(tb, a), "") ++ "->" ++ U64.show(b) ++ Bool.pick(String, U64.is_lt(b, nb), p_s(tb, b), "") ++ "]" ++ mshow(m, t, tb, nb)

def rsz(rs: List<&2, List<&2, TS.TP>>) -> String:
  match rs:
    case []: ""
    case r <> t: " " ++ Nat.show(List.length(&2, TS.TP, r)) ++ rsz(t)

def b_s(+b: Bool) -> String:
  Bool.pick(String, b, "y", "n")

def c_s(+c: V.Dir) -> String:
  "(" ++ F64.show(V.dr_x(c)) ++ " " ++ F64.show(V.dr_y(c)) ++ " " ++ F64.show(V.dr_z(c)) ++ ")"

def ms_s(+mf: List<&2, U64>, +mb: List<&2, U64>, +tb: B.Tb<&2, V.Point>, +nb: Nat) -> String:
  +f = mshow(6n, mf, tb, U64.from_nat(nb))
  +g = mshow(6n, mb, tb, U64.from_nat(nb))
  " missF=" ++ Nat.show(List.length(&2, U64, mf)) ++ " missB=" ++ Nat.show(List.length(&2, U64, mb)) ++ " F:" ++ f ++ " B:" ++ g

def fd_t(+r: TS.TGO, +rs: List<&2, List<&2, TS.TP>>, +tb: B.Tb<&2, V.Point>, +nb: Nat) -> String:
  TS.TGO{+ts, +ps, +ok, st} = r
  +es = TS.dir_es(ts, [], [])
  +sg = segs(rs, [])
  +h = " tris=" ++ Nat.show(List.length(&2, TS.Tri, ts)) ++ " segs=" ++ Nat.show(List.length(&2, U64, sg))
  h ++ (ms_s(miss(sg, TS.es_hd(es)), miss(rk(sg), TS.es_hd(es)), tb, nb))

def ch_s(+sf: S.SF, +rs: List<&2, List<&2, TS.TP>>, +same: Bool, +m: V.Dir) -> String:
  +c = S.dunit(m)
  +ga = TS.st_of(sf, c)
  +gb = TS.st_of(sf, S.dscale(F64.neg(1.0f64), c))
  +a = " |m|=" ++ F64.show(S.dlen(m)) ++ " c=" ++ c_s(c)
  +o = " oka=" ++ b_s(TS.st_ok(ga, rs, same)) ++ " okb=" ++ b_s(TS.st_ok(gb, rs, same))
  +w = " aA=" ++ F64.show(TS.st_area(rs, ga, 0.0f64)) ++ " aB=" ++ F64.show(TS.st_area(rs, gb, 0.0f64))
  a ++ o ++ w

def fd_s(f: Ty.Face, +x: TS.Ctx, +tb: B.Tb<&2, V.Point>, +gb: Nat, +nb: Nat) -> String:
  Ty.Fa{g, +s, +ls, +same, slv, sla} = f
  +sf = S.sf_of(s)
  +rs = TS.rings(ls, x)
  +hd = " k" ++ U64.show(S.sf_kind(sf)) ++ " same=" ++ b_s(same) ++ " rings" ++ rsz(rs)
  +cs = ch_s(sf, rs, same, TS.rs_nw(rs, V.Dr{0.0f64, 0.0f64, 0.0f64}))
  +tt = fd_t(TS.face_tg(True{}, f, x, tb, 0n, gb, TS.TL{0.01f64, S.fcos(M10.q_angle(M10.q_preset(1u64)))}), rs, tb, nb)
  hd ++ cs ++ tt

def fds(fs: List<&2, Ty.Face>, +x: TS.Ctx, +tb: B.Tb<&2, V.Point>, +i: Nat, +nb: Nat) -> String:
  match fs:
    case []: ""
    case +f <> t:
      +u = TS.use_gen(f, x)
      Bool.pick(String, u, "\nF" ++ Nat.show(i) ++ fd_s(f, x, tb, nb, nb), "\nF" ++ Nat.show(i) ++ " not gen") ++ fds(t, x, tb, Nat.add(i, 1n), nb)

def dst(+a: V.Point, +b: V.Point) -> F64:
  +dx = F64.sub(V.pt_x(a), V.pt_x(b))
  +dy = F64.sub(V.pt_y(a), V.pt_y(b))
  +dz = F64.sub(V.pt_z(a), V.pt_z(b))
  F64.sqrt(F64.add(F64.mul(dx, dx), F64.add(F64.mul(dy, dy), F64.mul(dz, dz))))

def pp_s(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ " " ++ F64.show(V.pt_y(p)) ++ " " ++ F64.show(V.pt_z(p)) ++ ")"

def ek_s(+i: Nat, k: Ty.EdgeKind, +a: V.Point, +b: V.Point) -> String:
  match k:
    case Ty.EK_degenerate{}: ""
    case Ty.EK_curve{+c, +d}:
      G.Dom{+lo, +hi} = d
      +pa = TS.ev_at(c, lo)
      +pb = TS.ev_at(c, hi)
      +e = F64.max(dst(pa, a), dst(pb, b))
      +h = "
E" ++ Nat.show(i) ++ " lo=" ++ F64.show(lo) ++ " hi=" ++ F64.show(hi) ++ " err=" ++ F64.show(e)
      Bool.pick(String, F64.is_lt(1.0e-6f64, e), h ++ " v0=" ++ pp_s(a) ++ " ev(lo)=" ++ pp_s(pa) ++ " v1=" ++ pp_s(b) ++ " ev(hi)=" ++ pp_s(pb), "")

def eds(es: List<&2, Ty.Edge>, +vt: B.Tb<&2, V.Point>, +i: Nat) -> String:
  match es:
    case []: ""
    case e <> t:
      Ty.Ed{g, v0, v1, k} = e
      ek_s(i, k, B.tb_get(V.Point, vt, TS.ux(TS.hv_i(v0))), B.tb_get(V.Point, vt, TS.ux(TS.hv_i(v1)))) ++ eds(t, vt, Nat.add(i, 1n))

def run_b(r: M.NR) -> String:
  match r:
    case M.NR_err{k, d}: "node failed"
    case M.NR_ok{+b, fx}:
      +br = M.bd_brep(b)
      +q = M10.q_preset(1u64)
      +ps = TS.all_pts(br, q)
      +all = List.append(&2, V.Point, ps, TS.bp_ps_of(Ty.brep_fas(br)))
      +tb = B.tb_of(V.Point, all, TS.pz())
      +x = TS.ctx_of(br, q)
      "edges " ++ Nat.show(List.length(&2, Ty.Edge, Ty.brep_es(br))) ++ eds(Ty.brep_es(br), B.tb_of(V.Point, TS.vx_pts(Ty.brep_vs(br)), TS.pz()), 0n) ++ "
faces " ++ Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(br))) ++ fds(Ty.brep_fas(br), x, tb, 0n, List.length(&2, V.Point, all))

def run(+src: String, +n: U64) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_for(p, [n], [])
  run_b(M.ce_r(M.ce_find(cs, n)))

def to2(xs: List<&1, String>) -> List<&2, String>:
  match xs:
    case []: []
    case h <> t: h <> to2(t)

def go(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(SX.arg_at(args, 1n))
    IO.print(run(src, SX.u64_of(SX.Sx_a{SX.arg_at(args, 2n)})))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(to2(args))
