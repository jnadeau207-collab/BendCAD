import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c04/ops.bend as O
import ../../src/c06/model.bend as M
import ../../src/c08/bool.bend as B8
import ../../src/c06/sx.bend as SX
import ../../src/k1/sf.bend as S
import ../../src/k1/gb.bend as GB
import ../../src/k1/asm.bend as K1
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

def brep_of(r: M.NR) -> Ty.Brep:
  match r:
    case M.NR_ok{+b, fx}: B8.bake_of(M.bool_in(b))
    case M.NR_err{k, d}: Ty.brep_empty()

def yn(+b: Bool) -> String:
  Bool.pick(String, b, "y", "n")

def p3(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

def vpt(+x: Ty.Ix, +h: Ty.HVertex) -> V.Point:
  Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, h)))

def bn(+b: Bool) -> Nat:
  Bool.pick(Nat, b, 1n, 0n)

def cx_p(+r: G.GRes, +p: V.Point, +sf: G.GVal) -> Nat:
  Nat.add(Nat.mul(100n, bn(O.pt_eq(G.gres_p(r), p))), Nat.add(Nat.mul(10n, bn(O.p_near(G.gres_p(r), p))), bn(O.s_on(sf, p))))

def cx_a(+h: Ty.HCoedge, +x: Ty.Ix, +sf: G.GVal) -> Nat:
  +ce = Ty.tres_ce(Ty.ix_ce(x, h))
  +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(ce)))
  +ts = O.trim_o_start(Ty.ce_trim(ce), Ty.ce_fwd(ce))
  cx_p(O.surf_at(sf, V.v2_x(ts), V.v2_y(ts)), vpt(x, O.o_v_start(ed, Ty.ce_fwd(ce))), sf)

def cx_b(+h: Ty.HCoedge, +x: Ty.Ix, +sf: G.GVal) -> Nat:
  +ce = Ty.tres_ce(Ty.ix_ce(x, h))
  +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(ce)))
  +te = O.trim_o_end(Ty.ce_trim(ce), Ty.ce_fwd(ce))
  cx_p(O.surf_at(sf, V.v2_x(te), V.v2_y(te)), vpt(x, O.o_v_end(ed, Ty.ce_fwd(ce))), sf)

def cx_d(+h: Ty.HCoedge, +x: Ty.Ix, +sf: G.GVal) -> String:
  +ce = Ty.tres_ce(Ty.ix_ce(x, h))
  +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(ce)))
  +te = O.trim_o_end(Ty.ce_trim(ce), Ty.ce_fwd(ce))
  " uv=" ++ F64.show(V.v2_x(te)) ++ "," ++ F64.show(V.v2_y(te)) ++ " ev=" ++ p3(G.gres_p(O.surf_at(sf, V.v2_x(te), V.v2_y(te))))

def ce_s(+h: Ty.HCoedge, +x: Ty.Ix, +sf: G.GVal) -> String:
  +ce = Ty.tres_ce(Ty.ix_ce(x, h))
  +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(ce)))
  +p0 = vpt(x, Ty.ed_v0(ed))
  +p1 = vpt(x, Ty.ed_v1(ed))
  "
    e" ++ Nat.show(Ty.he_idx(Ty.ce_edge(ce))) ++ " tag" ++ U64.show(Ty.ekind_tag(Ty.ed_kind(ed))) ++ " ends_on=" ++ yn(O.edge_ends_on_curve(Ty.ed_kind(ed), p0, p1, 1000n)) ++
    " on_s=" ++ yn(EF.on_g(sf, p0)) ++ yn(EF.on_g(sf, p1)) ++ " " ++ p3(p0) ++ p3(p1) ++ " c=" ++ Nat.show(cx_a(h, x, sf)) ++ "/" ++ Nat.show(cx_b(h, x, sf)) ++ cx_d(h, x, sf)

def ces_s(xs: List<&2, Ty.HCoedge>, +x: Ty.Ix, +sf: G.GVal) -> String:
  match xs:
    case []: ""
    case +h <> t: ce_s(h, x, sf) ++ ces_s(t, x, sf)

def lps_s(ls: List<&2, Ty.HLoop>, +x: Ty.Ix, +sf: G.GVal) -> String:
  match ls:
    case []: ""
    case +h <> t:
      +hcs = Ty.lp_ces(Ty.tres_lp(Ty.ix_lp(x, h)))
      "\n  loop ok=" ++ yn(O.loop_one_ok(hcs, x)) ++ ces_s(hcs, x, sf) ++ lps_s(t, x, sf)

def lps_all(ls: List<&2, Ty.HLoop>, +x: Ty.Ix) -> Bool:
  match ls:
    case []: True{}
    case +h <> t: Bool.and(O.loop_one_ok(Ty.lp_ces(Ty.tres_lp(Ty.ix_lp(x, h))), x), lps_all(t, x))

def fa_s(+h: Ty.Face, +x: Ty.Ix, +i: Nat) -> String:
  +sf = Ty.fa_surf(h)
  +ok = O.hls_face_ok(Ty.fa_loops(h), x, sf, O.surf_coinc(sf), O.surf_quad(sf), Ty.fa_slv(h))
  +lok = lps_all(Ty.fa_loops(h), x)
  Bool.pick(String, Bool.and(ok, lok), "", "\nFACE " ++ Nat.show(i) ++ " kind " ++ U64.show(S.sf_kind(S.sf_of(sf))) ++ " coinc_ok=" ++ yn(ok) ++ " loops_ok=" ++ yn(lok) ++ " slv=" ++ F64.show(Ty.fa_slv(h)) ++ lps_s(Ty.fa_loops(h), x, sf))

def fas_s(fs: List<&2, Ty.Face>, +x: Ty.Ix, +i: Nat) -> String:
  match fs:
    case []: ""
    case +h <> t: fa_s(h, x, i) ++ fas_s(t, x, Nat.add(i, 1n))

def ek_s(+k: Ty.EdgeKind) -> String:
  " ck=" ++ U64.show(EF.cv_kind(EF.ek_curve(k))) ++ " dom=" ++ F64.show(EF.ek_lo(k)) ++ "," ++ F64.show(EF.ek_hi(k)) ++ " c0=" ++ p3(EF.ev(EF.ek_curve(k), EF.ek_lo(k))) ++ " c1=" ++ p3(EF.ev(EF.ek_curve(k), EF.ek_hi(k)))

def ed_bad(es: List<&2, Ty.Edge>, +x: Ty.Ix, +i: Nat) -> String:
  match es:
    case []: ""
    case +h <> t:
      +p0 = vpt(x, Ty.ed_v0(h))
      +p1 = vpt(x, Ty.ed_v1(h))
      +ok = O.edge_ends_on_curve(Ty.ed_kind(h), p0, p1, 1000n)
      Bool.pick(String, ok, "", "\nEDGE " ++ Nat.show(i) ++ " " ++ p3(p0) ++ p3(p1) ++ ek_s(Ty.ed_kind(h))) ++ ed_bad(t, x, Nat.add(i, 1n))

def rep(+b: Ty.Brep) -> String:
  +x = Ty.ix_of(b)
  "faces " ++ Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(b))) ++ " trim_ok " ++ yn(O.ces_trim_ok(Ty.brep_ces(b))) ++ " surf_ok " ++ yn(O.fas_surf_ok(Ty.brep_fas(b))) ++
    ed_bad(Ty.brep_es(b), x, 0n) ++ fas_s(Ty.brep_fas(b), x, 0n)

def run_app(+src: String, +a: U64, +b: U64) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_for(p, [a, b], [])
  "append
" ++ rep(B8.brep_append(brep_of(M.ce_r(M.ce_find(cs, a))), brep_of(M.ce_r(M.ce_find(cs, b)))))

def run(+src: String, +a: U64, +b: U64, +op: U64) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_for(p, [a, b], [])
  +kr = GB.gbrun(op, brep_of(M.ce_r(M.ce_find(cs, a))), brep_of(M.ce_r(M.ce_find(cs, b))))
  "A faces " ++ Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(brep_of(M.ce_r(M.ce_find(cs, a)))))) ++ " B faces " ++ Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(brep_of(M.ce_r(M.ce_find(cs, b)))))) ++ " k1 ok " ++ yn(K1.kr_ok(kr)) ++ " why " ++ U64.show(K1.kr_why(kr)) ++ "\n" ++ rep(K1.kr_brep(kr))

def arg1(xs: List<&1, String>, +i: Nat) -> String:
  match xs:
    case []: ""
    case +h <> t:
      match i:
        case 0n: h
        case 1n+(+j): arg1(t, j)

def num(+s: String) -> U64:
  SX.u64_of(SX.Sx_a{s})

def to2(xs: List<&1, String>) -> List<&2, String>:
  match xs:
    case []: []
    case h <> t: h <> to2(t)

def go3(app: Bool, +src: String, +a: String, +b: String, +op: String) -> String:
  match app:
    case True{}: run_app(src, num(a), num(b))
    case False{}: run(src, num(a), num(b), num(op))

def go2(+src: String, +a: String, +b: String, +op: String) -> IO(Unit):
  IO.print(go3(String.eq(op, "0"), src, a, b, op))

def go(+args: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(SX.arg_at(args, 1n))
    go2(src, SX.arg_at(args, 2n), SX.arg_at(args, 3n), SX.arg_at(args, 4n))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(to2(args))
