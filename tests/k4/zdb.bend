import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c03/types.bend as G
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as SX
import ../../src/k1/sf.bend as S
import ../../src/k1/fb.bend as FB
import ../../src/k1/px.bend as PX
import ../../src/k1/co.bend as CO
import ../../src/k1/gw.bend as W
import ../../src/k1/gb.bend as GB
import ../../src/k1/ss.bend as SS
import ../../src/k1/ef.bend as EF

law read_go:
  for m: File & Result<&1, &1, (U32 & String), String>
  IO(String)


type Cx is Data:
  Cx{ ba: FB.KB, bb: FB.KB, ma: List<&2, Nat>, mb: List<&2, Nat>, hs: List<&2, PX.HX>, chs: List<&2, PX.CH>, cps: List<&2, CO.CP>, g: PX.GV }

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
    case M.NR_ok{+b, fx}: M.bd_brep(b)
    case M.NR_err{k, d}: Ty.brep_empty()


def v2s(+q: V.Vec2) -> String:
  "(" ++ F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q)) ++ ")"


def lastv(xs: List<&2, V.Vec2>, +d: V.Vec2) -> V.Vec2:
  match xs:
    case []: d
    case +h <> t: lastv(t, h)


def firstv(xs: List<&2, V.Vec2>) -> V.Vec2:
  match xs:
    case []: V.V2{0.0f64, 0.0f64}
    case +h <> t: h


def pcs_s(ps: List<&2, W.PC>) -> String:
  match ps:
    case []: ""
    case +p <> t:
      +pl = W.pc_poly(p)
      "\n  [" ++ Nat.show(W.pc_va(p)) ++ "->" ++ Nat.show(W.pc_vb(p)) ++ (Bool.pick(String, W.pc_bnd(p), " B ", " C ")) ++ Nat.show(List.length(&2, V.Vec2, pl)) ++ " " ++ v2s(firstv(pl)) ++ v2s(lastv(pl, firstv(pl))) ++ "]" ++ pcs_s(t)



def face_s(+c: Cx, +side: U64, +fi: Nat) -> String:
  Cx{+ba, +bb, +ma, +mb, +hs, +chs, +cps, +g} = c
  +b = Bool.pick(FB.KB, U64.is_eq(side, 0u64), ba, bb)
  +o = Bool.pick(FB.KB, U64.is_eq(side, 0u64), bb, ba)
  +m = Bool.pick(List<&2, Nat>, U64.is_eq(side, 0u64), ma, mb)
  +mo = Bool.pick(List<&2, Nat>, U64.is_eq(side, 0u64), mb, ma)
  +pcs = GB.face_pcs(b, fi, side, m, hs, chs, cps, o, mo, g)
  +cs = W.face_cycles(FB.face_sf(b, fi), pcs)
  +rs = W.regions(FB.face_sf(b, fi), W.cs_cys(cs))
  +bad = Bool.or(Bool.not(Bool.and(W.cs_ok(cs), W.rs_ok(rs))), Bool.and(U64.is_eq(side, 1u64), Nat.is_le(32n, fi)))
  Bool.pick(String, bad, "side " ++ U64.show(side) ++ " face " ++ Nat.show(fi) ++ " kind " ++ U64.show(S.sf_kind(FB.face_sf(b, fi))) ++ " cs " ++ (Bool.pick(String, W.cs_ok(cs), "y", "n")) ++ " rs " ++ (Bool.pick(String, W.rs_ok(rs), "y", "n")) ++ pcs_s(pcs) ++ "\n", "")


def faces_s(n: Nat, +c: Cx, +side: U64, +i: Nat) -> String:
  match n:
    case 0n: ""
    case 1n+(+k): face_s(c, side, i) ++ faces_s(k, c, side, Nat.add(i, 1n))


def L_ic0(cs: List<&2, SS.IC>) -> SS.IC:
  match cs:
    case []: SS.none_ic()
    case +h <> t: h


def ssx(+a: G.GVal, +b: G.GVal) -> String:
  +r = SS.ssi(a, b)
  "ssi n=" ++ Nat.show(List.length(&2, SS.IC, SS.ics_ics(r))) ++ " why=" ++ U64.show(SS.ics_why(r)) ++ " kinds=" ++ U64.show(S.sf_kind(S.sf_of(a))) ++ "," ++ U64.show(S.sf_kind(S.sf_of(b))) ++ "
"


def hxs_s(hs: List<&2, PX.HX>) -> String:
  match hs:
    case []: ""
    case +h <> t: " v" ++ Nat.show(PX.hx_v(h)) ++ hxs_s(t)


def chs_s(cs: List<&2, PX.CH>) -> String:
  match cs:
    case []: ""
    case +h <> t:
      PX.CH{+fa, +fb, ss, +ps, cl, dv} = h
      " ch(" ++ Nat.show(fa) ++ "," ++ Nat.show(fb) ++ " n=" ++ Nat.show(List.length(&2, V.Point, ps)) ++ ")" ++ chs_s(t)


def pair_s(+ba: FB.KB, +fa: Nat, +bb: FB.KB, +fb: Nat, +hs: List<&2, PX.HX>, +g: PX.GV) -> String:
  +ph = PX.pair_hits(hs, PX.face_es(ba, fa), fa, PX.face_es(bb, fb), fb)
  +x = SS.ssi(FB.face_surf(ba, fa), FB.face_surf(bb, fb))
  +r = PX.pj_apply(x, ph, ba, fa, bb, fb, PX.CR{[], g, True{}, 0u64})
  "pair " ++ Nat.show(fa) ++ "/" ++ Nat.show(fb) ++ " hits" ++ hxs_s(ph) ++ " curves " ++ Nat.show(List.length(&2, SS.IC, SS.ics_ics(x))) ++ " kind " ++ U64.show(SS.ic_kind(L_ic0(SS.ics_ics(x)))) ++ " closed " ++ (Bool.pick(String, SS.ic_closed(L_ic0(SS.ics_ics(x))), "y", "n")) ++ " npts " ++ Nat.show(List.length(&2, V.Point, SS.ic_pts(L_ic0(SS.ics_ics(x))))) ++ " chains" ++ chs_s(PX.cr_chs(r)) ++ "
"


def ns_s(xs: List<&2, Nat>) -> String:
  match xs:
    case []: ""
    case +h <> t: " " ++ Nat.show(h) ++ ns_s(t)


def p3(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"


def hall(hs: List<&2, PX.HX>) -> String:
  match hs:
    case []: ""
    case +h <> t:
      PX.HX{+sd, +e, +tt, +p, +v, +fo} = h
      "
  v" ++ Nat.show(v) ++ " side" ++ U64.show(sd) ++ " e" ++ Nat.show(e) ++ " fo" ++ Nat.show(fo) ++ " t" ++ F64.show(tt) ++ " " ++ p3(p) ++ hall(t)


def ehs_s(hs: List<&2, EF.EH>) -> String:
  match hs:
    case []: ""
    case +h <> t: " t=" ++ F64.show(EF.eh_t(h)) ++ p3(EF.eh_p(h)) ++ ehs_s(t)


def ej_inp(+j: PX.EJ) -> Bool:
  PX.EJ{ee, ff, +inp, r} = j
  inp


def ej_r(+j: PX.EJ) -> EF.EHS:
  PX.EJ{ee, ff, inp, +r} = j
  r


def ej_s(+ba: FB.KB, +bb: FB.KB, +e: Nat, +fo: Nat) -> String:
  +inp = ej_inp(PX.ej_one(bb, ba, e, fo))
  +r = ej_r(PX.ej_one(bb, ba, e, fo))
  +ed = FB.edge_at(bb, e)
  "edge " ++ Nat.show(e) ++ " vs face " ++ Nat.show(fo) ++ " inp " ++ (Bool.pick(String, inp, "y", "n")) ++ " far " ++ (Bool.pick(String, PX.far_f(S.sf_of(FB.face_surf(ba, fo)), PX.edge_box(bb, e)), "y", "n")) ++ " raw" ++ ehs_s(EF.ehs_hs(r)) ++ " v0" ++ p3(FB.vpt(bb, Ty.ed_v0(ed))) ++ " v1" ++ p3(FB.vpt(bb, Ty.ed_v1(ed))) ++ "
"


def L_eh0(hs: List<&2, EF.EH>) -> EF.EH:
  match hs:
    case []: EF.EH{0.0f64, V.Pt{0.0f64, 0.0f64, 0.0f64}, False{}}
    case +h <> t: h


def keep_s(+ba: FB.KB, +bb: FB.KB, +e: Nat, +fo: Nat) -> String:
  +r = ej_r(PX.ej_one(bb, ba, e, fo))
  +k = Ty.ed_kind(FB.edge_at(bb, e))
  +st = PX.eh_keep(EF.ehs_hs(r), 1u64, e, fo, ba, bb, EF.ek_lo(k), EF.ek_hi(k), PX.HS{[], PX.GV{[], 0n}, True{}, 0u64})
  +p = EF.eh_p(L_eh0(EF.ehs_hs(r)))
  "keep e" ++ Nat.show(e) ++ " fo" ++ Nat.show(fo) ++ " n=" ++ Nat.show(List.length(&2, PX.HX, PX.hs_hs(st))) ++ " pif " ++ (Bool.pick(String, FB.pt_in_face(ba, fo, p), "y", "n")) ++ " bn " ++ (Bool.pick(String, FB.bnd_near(ba, fo, p), "y", "n")) ++ " uv " ++ v2s(FB.uv_raw(FB.face_sf(ba, fo), p)) ++ "
"


def run(+src: String) -> String:
  +p = SX.part_of(SX.ps_xs(SX.parse(src)))
  +cs = M.ev_part(p, [])
  +ra = brep_of(M.ce_r(M.ce_find(cs, 1901u64)))
  +rb = brep_of(M.ce_r(M.ce_find(cs, 2u64)))
  +ba = FB.kb_of(ra)
  +bb = FB.kb_of(rb)
  +va = PX.add_vs(Ty.brep_vs(ra), PX.GV{[], 0n}, [])
  +vb = PX.add_vs(Ty.brep_vs(rb), PX.vm_g(va), [])
  +hs = PX.all_hits(ba, bb, PX.vm_g(vb))
  +cps = CO.coin_pairs(ba, bb)
  +hs2 = PX.hs_hs(hs)
  +cr = PX.all_chains(hs2, ba, bb, PX.hs_g(hs))
  +hs3 = PX.chain_hits(PX.cr_chs(cr), ba, bb, PX.cr_g(cr), hs2)
  +c = {Cx{ba, bb, PX.vm_mp(va), PX.vm_mp(vb), hs3, PX.cr_chs(cr), cps, PX.cr_g(cr)} : Cx}
  "hits " ++ Nat.show(List.length(&2, PX.HX, hs2)) ++ " hs_ok " ++ (Bool.pick(String, PX.hs_ok(hs), "y", "n")) ++ " cr_ok " ++ (Bool.pick(String, PX.cr_ok(cr), "y", "n")) ++ " chains " ++ Nat.show(List.length(&2, PX.CH, PX.cr_chs(cr))) ++ "\n" ++
    keep_s(ba, bb, 32n, 7n) ++ keep_s(ba, bb, 34n, 7n) ++ keep_s(ba, bb, 32n, 6n) ++ ej_s(ba, bb, 34n, 7n) ++ ej_s(ba, bb, 6n, 7n) ++ ej_s(ba, bb, 32n, 6n) ++ "face33 edges " ++ ns_s(PX.face_es(bb, 33n)) ++ "
all hits:" ++ hall(hs2) ++ "
" ++ pair_s(ba, 7n, bb, 33n, hs2, PX.hs_g(hs)) ++
    faces_s(FB.kb_nf(ba), c, 0u64, 0n) ++ faces_s(FB.kb_nf(bb), c, 1u64, 0n) ++ ssx(FB.face_surf(bb, 32n), FB.face_surf(ba, 2n)) ++ ssx(FB.face_surf(bb, 33n), FB.face_surf(ba, 2n)) ++ ssx(FB.face_surf(bb, 32n), FB.face_surf(ba, 7n)) ++ ssx(FB.face_surf(bb, 33n), FB.face_surf(ba, 7n))


def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    src : String <- read_file("/home/jesse/g5/dbg.bcd")
    IO.print(run(src))
