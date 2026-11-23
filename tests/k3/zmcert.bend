import Base
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c07/sol.bend as SO
import ../../src/c07/xs.bend as XS
import ../../src/c07/ivx.bend as X
import ../../src/c07/mem.bend as Mm
import ../../src/c07/im.bend as MI
import ../../src/c06/iv.bend as I
import ../../src/c03/types.bend as G
import ../../src/c01/types.bend as V
import ../../src/k3/mesh.bend as K

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

def iv_s(+x: I.I) -> String:
  "[" ++ F64.show(I.i_lo(x)) ++ "," ++ F64.show(I.i_hi(x)) ++ "]"

def ivs_s(xs: List<&2, I.I>) -> String:
  match xs:
    case []: ""
    case +x <> t: iv_s(x) ++ ivs_s(t)

def hit_d(h: XS.Hit, +fc: Mm.Fc, +im: MI.Im, +fi: Nat) -> String:
  match h:
    case XS.H_pt{+s, t, +pb, c}:
      +m = Mm.member(fc, pb, im)
      Bool.pick(String, U64.is_lt(m, 2u64), "", " f" ++ Nat.show(fi) ++ " member=" ++ U64.show(m) ++ " s=" ++ iv_s(s) ++ " p=" ++ ivs_s(pb))
    case XS.H_ov{+s, t}: " f" ++ Nat.show(fi) ++ " overlap s=" ++ iv_s(s)
    case XS.H_un{+s, t, +pb}: " f" ++ Nat.show(fi) ++ " uncertain s=" ++ iv_s(s) ++ " p=" ++ ivs_s(pb)
    case XS.H_no{+why}: " f" ++ Nat.show(fi) ++ " none " ++ why

def hits_d(hs: List<&2, XS.Hit>, +fc: Mm.Fc, +im: MI.Im, +fi: Nat) -> String:
  match hs:
    case []: ""
    case +h <> t: hit_d(h, fc, im, fi) ++ hits_d(t, fc, im, fi)

def face_d(+f: SO.Fd, +p: V.Point, +len: F64, +sb: List<&2, I.I>, +fi: Nat) -> String:
  Bool.pick(String, X.vdisj(SO.fd_bx(f), sb), "",
    hits_d(XS.inter_cs(G.GV_ln{G.Ln{p, K.xdir()}}, G.Dom{0.0f64, len}, SO.fd_g(f), 40n), SO.fd_fc(f), SO.fd_im(f), fi))

def faces_d(fs: List<&2, SO.Fd>, +p: V.Point, +len: F64, +sb: List<&2, I.I>, +fi: Nat) -> String:
  match fs:
    case []: ""
    case +f <> t: face_d(f, p, len, sb, fi) ++ faces_d(t, p, len, sb, Nat.add(fi, 1n))

def pt_s(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ " " ++ F64.show(V.pt_y(p)) ++ " " ++ F64.show(V.pt_z(p)) ++ ")"

def lines_d(ls: List<&2, K.LN>, +fs: List<&2, SO.Fd>, +left: Nat, +nbad: Nat, +n: Nat) -> String:
  match ls:
    case []: "lines=" ++ Nat.show(n) ++ " bad=" ++ Nat.show(nbad) ++ "\n"
    case +l <> t:
      K.LN{+p, +nn, +h} = l
      +len = F64.mul(h, K.nat_f(nn))
      +d = faces_d(fs, p, len, SO.seg_box(p, K.xdir(), len), 0n)
      +bad = Bool.not(String.eq(d, ""))
      +show = Bool.and(bad, Nat.is_lt(0n, left))
      Bool.pick(String, show, "line " ++ pt_s(p) ++ d ++ "\n", "") ++
        lines_d(t, fs, Bool.pick(Nat, show, Nat.sub(left, 1n), left), Bool.pick(Nat, bad, Nat.add(nbad, 1n), nbad), Nat.add(n, 1n))

def run_gr(+fs: List<&2, SO.Fd>, +gr: K.GR, +h: F64) -> String:
  K.GR{+ox, +oy, +oz, gh, +nx, +ny, +nz} = gr
  +hh = F64.mul(0.5f64, h)
  "faces=" ++ Nat.show(List.length(&2, SO.Fd, fs)) ++ " grid " ++ Nat.show(nx) ++ "x" ++ Nat.show(ny) ++ "x" ++ Nat.show(nz) ++ "\nA " ++
    lines_d(K.ln_k(nz, ox, oy, oz, h, nx, ny, []), fs, 25n, 0n, 0n) ++ "B " ++
    lines_d(K.ln_k(Nat.sub(nz, 1n), F64.add(ox, hh), F64.add(oy, hh), F64.add(oz, hh), h, Nat.sub(nx, 1n), Nat.sub(ny, 1n), []), fs, 25n, 0n, 0n)

def run_fs(+fs: List<&2, SO.Fd>, +h: F64) -> String:
  run_gr(fs, K.grid_of(SO.bbox(fs, []), h), h)

def run(+src: String) -> String:
  +cs = M.ev_part(S.part_of(S.ps_xs(S.parse(src))), [])
  run_fs(SO.fds_of(M.bd_brep(M.nr_body(M.ce_r(M.ce_find(cs, 2702u64))))), 0.65f64)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file(S.arg_at(S.args_l(args), 1n))
    IO.print(run(src))
