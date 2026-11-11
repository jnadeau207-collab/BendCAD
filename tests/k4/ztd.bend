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

def q_s(qs: List<&2, TS.QP>) -> String:
  match qs:
    case []: ""
    case +q <> t:
      TS.QP{+i, +u, +v} = q
      " " ++ Nat.show(i) ++ ":" ++ F64.show(u) ++ "," ++ F64.show(v) ++ q_s(t)

def qs_s(qs: List<&2, List<&2, TS.QP>>) -> String:
  match qs:
    case []: ""
    case +r <> t: "\n  ring" ++ q_s(r) ++ qs_s(t)

def tp_s(r: List<&2, TS.TP>) -> String:
  match r:
    case []: ""
    case +h <> t:
      TS.TP{+i, +p} = h
      " " ++ Nat.show(i) ++ "@" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ tp_s(t)

def tps_s(rs: List<&2, List<&2, TS.TP>>) -> String:
  match rs:
    case []: ""
    case +r <> t: "\n  pts" ++ tp_s(r) ++ tps_s(t)

def tg_s(+r: TS.TGO) -> String:
  TS.TGO{+ts, +ps, +ok} = r
  " ok=" ++ Bool.pick(String, ok, "y", "n") ++ " tris=" ++ Nat.show(List.length(&2, TS.Tri, ts)) ++ " new=" ++ Nat.show(List.length(&2, V.Point, ps))

def face_s(f: Ty.Face, +x: TS.Ctx, +tol: TS.TL) -> String:
  Ty.Fa{g, +s, +ls, +same, slv, sla} = f
  +rs = TS.rings(ls, x)
  +sf = TS.sph_pick(S.sf_of(s), rs)
  +g0 = TS.gs_of(sf, rs)
  +ws = TS.rings_ws(rs, g0, 0.0f64, True{}, 1.0f64)
  +r = TS.gen_face(f, x, 0n, tol)
  "same=" ++ Bool.pick(String, same, "y", "n") ++ " band=" ++ Bool.pick(String, TS.band_of(g0, rs), "y", "n") ++ tg_s(r) ++ tps_s(rs) ++ qs_s(TS.wss_q(ws, 0n))

def vx_s(+i: Nat, +w: TS.VX) -> String:
  TS.VX{+u, +v, +p} = w
  "\nV " ++ Nat.show(i) ++ " " ++ F64.show(u) ++ " " ++ F64.show(v) ++ " " ++ F64.show(V.pt_x(p)) ++ " " ++ F64.show(V.pt_y(p)) ++ " " ++ F64.show(V.pt_z(p))

def vt_s(n: Nat, +vt: B.Tb<&2, TS.VX>, +i: Nat) -> String:
  match n:
    case 0n: ""
    case 1n+(+m):
      vx_s(i, B.tb_get(TS.VX, vt, U32.from_nat(i))) ++ vt_s(m, vt, Nat.add(i, 1n))

def tr_s(ts: List<&2, TS.Tri>) -> String:
  match ts:
    case []: ""
    case +t <> r:
      TS.Tri{+a, +b, +c} = t
      "\nT " ++ Nat.show(a) ++ " " ++ Nat.show(b) ++ " " ++ Nat.show(c) ++ tr_s(r)

def rf_dump(+r: TS.RF) -> String:
  TS.RF{+ts, +vt, +nv} = r
  "\nNV " ++ Nat.show(nv) ++ vt_s(nv, vt, 0n) ++ tr_s(ts)

def core_dump(+rs: List<&2, List<&2, TS.TP>>, +g: TS.GS, +qs: List<&2, List<&2, TS.QP>>, +vxs: List<&2, TS.VX>, +tol: TS.TL, +rounds: Nat) -> String:
  +t0 = TS.clip_rings(TS.ql_hd(qs), TS.ql_tl(qs))
  +nb = TS.rings_n(rs)
  +cap = Nat.add(Nat.mul(6n, nb), 8192n)
  +vt = B.tb_of(TS.VX, List.append(&2, TS.VX, vxs, TS.rep_vx(cap)), TS.vx0())
  +nx = B.tb_of(Nat, TS.g_nx(rs, 0n), 0n)
  "\nNB " ++ Nat.show(nb) ++ " T0 " ++ Nat.show(List.length(&2, TS.Tri, t0)) ++ rf_dump(TS.ref_go(rounds, False{}, TS.RF{t0, vt, nb}, g, nx, nb, Nat.add(nb, cap), tol))

def dump_s(f: Ty.Face, +x: TS.Ctx, +tol: TS.TL, +rounds: Nat) -> String:
  Ty.Fa{g, +s, +ls, +same, slv, sla} = f
  +rs = TS.rings(ls, x)
  +sf = TS.sph_pick(S.sf_of(s), rs)
  +g0 = TS.gs_of(sf, rs)
  +wss = TS.rings_ws(rs, g0, 0.0f64, True{}, 1.0f64)
  core_dump(rs, g0, TS.wss_q(wss, 0n), TS.wss_v(wss, rs), tol, rounds)

def drop_f(fs: List<&2, Ty.Face>, +i: Nat) -> List<&2, Ty.Face>:
  match fs:
    case []: []
    case +f <> +t:
      match i:
        case 0n: f <> t
        case 1n+(+j): drop_f(t, j)

def pick_s(fs: List<&2, Ty.Face>, +x: TS.Ctx, +tol: TS.TL, +fi: Nat) -> String:
  match fs:
    case []: "no face"
    case +f <> t: "face " ++ Nat.show(fi) ++ " " ++ face_s(f, x, tol) ++ dump_s(f, x, tol, 48n)

def run_b(r: M.NR, +fi: Nat) -> String:
  match r:
    case M.NR_err{k, d}: "node failed"
    case M.NR_ok{+b, fx}:
      +br = M.bd_brep(b)
      +q = M10.q_preset(2u64)
      +x = TS.ctx_of(br, q)
      pick_s(drop_f(Ty.brep_fas(br), fi), x, TS.TL{M10.q_chord(q), S.fcos(M10.q_angle(q))}, fi)

def run(+src: String, +n: U64, +fi: Nat) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_for(p, [n], [])
  run_b(M.ce_r(M.ce_find(cs, n)), fi)

def to2(xs: List<&1, String>) -> List<&2, String>:
  match xs:
    case []: []
    case h <> t: h <> to2(t)

def go(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(SX.arg_at(args, 1n))
    IO.print(run(src, SX.u64_of(SX.Sx_a{SX.arg_at(args, 2n)}), U64.to_nat(SX.u64_of(SX.Sx_a{SX.arg_at(args, 3n)}))))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(to2(args))
