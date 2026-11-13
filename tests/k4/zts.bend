import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
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

def unm_s(+ts: List<&2, TS.Tri>) -> String:
  +es = TS.dir_es(ts, [], [])
  +f = sk(TS.es_hd(es))
  +b = sk(TS.es_tl(es))
  +u = ud(Nat.mul(2n, Nat.add(List.length(&2, U64, f), List.length(&2, U64, b))), f, b, [])
  Nat.show(List.length(&2, U64, u)) ++ kshow(12n, u)

def tg_s(+r: TS.TGO) -> String:
  TS.TGO{+ts, +ps, +ok, st} = r
  " ok=" ++ Bool.pick(String, ok, "y", "n") ++ " tris=" ++ Nat.show(List.length(&2, TS.Tri, ts)) ++ " new=" ++ Nat.show(List.length(&2, V.Point, ps)) ++ " closed=" ++ Bool.pick(String, TS.closed(ts), "y", "n") ++ " unm=" ++ unm_s(ts)

def vx_s(+w: TS.VX) -> String:
  TS.VX{+u, +v, +p} = w
  " (" ++ F64.show(u) ++ "," ++ F64.show(v) ++ ")"

def worst(ts: List<&2, TS.Tri>, +k: U64, +sf: S.SF, +vt: B.Tb<&2, TS.VX>, +bm: F64, +bs: String) -> String:
  match ts:
    case []: " worst=" ++ F64.show(bm) ++ bs
    case +t <> r:
      TS.Tri{+a, +b, +c} = t
      +va = B.tb_get(TS.VX, vt, U32.from_nat(a))
      +vb = B.tb_get(TS.VX, vt, U32.from_nat(b))
      +vc = B.tb_get(TS.VX, vt, U32.from_nat(c))
      +x = TS.ct_tri(k, sf, va, vb, vc)
      +hi = F64.is_lt(bm, x)
      worst(r, k, sf, vt, F64.max(bm, x), Bool.pick(String, hi, vx_s(va) ++ vx_s(vb) ++ vx_s(vc), bs))

def dx_s(f: Ty.Face, +x: TS.Ctx, +tol: TS.TL) -> String:
  Ty.Fa{g, +s, +ls, +same, slv, sla} = f
  +rs = TS.rings(ls, x)
  +sf = TS.sph_pick(S.sf_of(s), rs)
  +g0 = TS.gs_of(sf, rs)
  +wss = TS.rings_ws(rs, g0, 0.0f64, True{}, 1.0f64)
  +qs = TS.wss_q(wss, 0n)
  +d = TS.dx_try(qs, TS.rings_n(rs), g0, sf, tol, 0n)
  +vt = B.tb_of(TS.VX, List.append(&2, TS.VX, TS.wss_v(wss, rs), TS.dr_vs(d)), TS.vx0())
  " st=" ++ Bool.pick(String, TS.gs_isst(g0), "y", "n") ++ " dx_ok=" ++ Bool.pick(String, TS.dr_ok(d), "y", "n") ++ " dx_tris=" ++ Nat.show(List.length(&2, TS.Tri, TS.dr_ts(d))) ++
    " dx_new=" ++ Nat.show(List.length(&2, TS.VX, TS.dr_vs(d))) ++ worst(TS.dr_ts(d), S.sf_kind(sf), sf, vt, 0.0f64, "")

def fs_s(fs: List<&2, Ty.Face>, +x: TS.Ctx, +tb: B.Tb<&2, V.Point>, +i: Nat, +gb: Nat, +ch: F64, +an: F64) -> String:
  match fs:
    case []: ""
    case +f <> t:
      +u = TS.use_gen(f, x)
      +tol = {TS.TL{ch, S.fcos(an)} : TS.TL}
      +r = TS.face_tg(u, f, x, tb, 0n, gb, tol)
      "\nF" ++ Nat.show(i) ++ " k" ++ U64.show(S.sf_kind(S.sf_of(Ty.fa_surf(f)))) ++ " gen=" ++ Bool.pick(String, u, "y", "n") ++ " k=" ++ U64.show(S.sf_kind(S.sf_of(Ty.fa_surf(f)))) ++ dx_s(f, x, tol) ++
        fs_s(t, x, tb, Nat.add(i, 1n), Nat.add(gb, TS.gt_np(r)), ch, an)

def run_b(r: M.NR, +ch: F64, +an: F64) -> String:
  match r:
    case M.NR_err{k, d}: "node failed"
    case M.NR_ok{+b, fx}:
      +br = M.bd_brep(b)
      +q = M10.q_mk(ch, an, 10000000n, 1u64)
      +ps = TS.all_pts(br, q)
      +all = List.append(&2, V.Point, ps, TS.bp_ps_of(Ty.brep_fas(br)))
      +tb = B.tb_of(V.Point, all, TS.pz())
      +x = TS.ctx_of(br, q)
      +gt = TS.faces_tg(Ty.brep_fas(br), x, tb, List.length(&2, V.Point, ps), List.length(&2, V.Point, all), TS.TL{M10.q_chord(q), S.fcos(M10.q_angle(q))})
      "faces " ++ Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(br))) ++ fs_s(Ty.brep_fas(br), x, tb, 0n, List.length(&2, V.Point, all), ch, an)

def run(+src: String, +n: U64, +ch: F64, +an: F64) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_for(p, [n], [])
  run_b(M.ce_r(M.ce_find(cs, n)), ch, an)

def to2(xs: List<&1, String>) -> List<&2, String>:
  match xs:
    case []: []
    case h <> t: h <> to2(t)

def mf(m: Maybe<&2, F64>) -> F64:
  match m:
    case None{}: 1.0f64
    case Some{v}: v

def go(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(SX.arg_at(args, 1n))
    IO.print(run(src, SX.u64_of(SX.Sx_a{SX.arg_at(args, 2n)}), mf(SX.dec(SX.arg_at(args, 3n))), mf(SX.dec(SX.arg_at(args, 4n)))))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(to2(args))
