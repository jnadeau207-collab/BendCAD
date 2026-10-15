import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c03/ops.bend as GO
import ../../src/c04/types.bend as Ty
import ../../src/c04/ops.bend as B4
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c06/xp.bend as X
import ../../src/c06/prof.bend as F
import ../../src/c06/build.bend as BD
import ../../src/c06/revolve.bend as RV
import ../../src/c06/iv.bend as I
import ../../src/c09/feat.bend as F9
import ../../src/c16/surf.bend as SU

def e_at(es: List<&2, Ty.Edge>, +i: Nat) -> Ty.Edge:
  match es:
    case []: Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{0n, 0u64}, Ty.EK_degenerate{}}
    case e <> t:
      match i:
        case 0n: e
        case 1n+j: e_at(t, j)
def ev0(e: Ty.Edge) -> Nat:
  Ty.Ed{g, a, b, k} = e
  Ty.HV{i, ag} = a
  i
def ev1(e: Ty.Edge) -> Nat:
  Ty.Ed{g, a, b, k} = e
  Ty.HV{i, bg} = b
  i
def u_start(+es: List<&2, Ty.Edge>, u: BD.Use) -> Nat:
  BD.Us{+e, fwd, ta, tb} = u
  Bool.pick(Nat, fwd, ev0(e_at(es, e)), ev1(e_at(es, e)))
def u_end(+es: List<&2, Ty.Edge>, u: BD.Use) -> Nat:
  BD.Us{+e, fwd, ta, tb} = u
  Bool.pick(Nat, fwd, ev1(e_at(es, e)), ev0(e_at(es, e)))
def chain(+es: List<&2, Ty.Edge>, us: List<&2, BD.Use>, +at: Nat, +home: Nat) -> Bool:
  match us:
    case []: Nat.is_eq(at, home)
    case +u <> t: Bool.and(Nat.is_eq(u_start(es, u), at), chain(es, t, u_end(es, u), home))
def loop_closed(+es: List<&2, Ty.Edge>, us: List<&2, BD.Use>) -> Bool:
  match us:
    case []: False{}
    case +u <> t: chain(es, t, u_end(es, u), u_start(es, u))
def loops_closed(+es: List<&2, Ty.Edge>, ls: List<&2, List<&2, BD.Use>>) -> Bool:
  match ls:
    case []: True{}
    case l <> t: Bool.and(loop_closed(es, l), loops_closed(es, t))
def faces_closed(+es: List<&2, Ty.Edge>, fs: List<&2, BD.FS>) -> Bool:
  match fs:
    case []: True{}
    case f <> t:
      BD.FS{sol, surf, same, lps, nm} = f
      Bool.and(loops_closed(es, lps), faces_closed(es, t))
def flat(ls: List<&2, List<&2, BD.Use>>) -> List<&2, BD.Use>:
  match ls:
    case []: []
    case l <> t: List.append(&2, BD.Use, l, flat(t))
def beq(a: Bool, b: Bool) -> Bool:
  match a:
    case True{}: b
    case False{}: Bool.not(b)
def uses(fs: List<&2, BD.FS>) -> List<&2, BD.Use>:
  match fs:
    case []: []
    case f <> t:
      BD.FS{sol, surf, same, lps, nm} = f
      List.append(&2, BD.Use, flat(lps), uses(t))
def hits(us: List<&2, BD.Use>, +e: Nat, +d: Bool) -> Nat:
  match us:
    case []: 0n
    case u <> t:
      BD.Us{e2, fwd, ta, tb} = u
      Nat.add(Bool.pick(Nat, Bool.and(Nat.is_eq(e2, e), beq(fwd, d)), 1n, 0n), hits(t, e, d))
def is_bnd(bs: List<&2, Nat>, +e: Nat) -> Bool:
  match bs:
    case []: False{}
    case +b <> t: Bool.or(Nat.is_eq(b, e), is_bnd(t, e))
def bndge(n: Nat, +us: List<&2, BD.Use>, +bs: List<&2, Nat>) -> Bool:
  match n:
    case 0n: True{}
    case 1n+(+k):
      Bool.and(Bool.pick(Bool, is_bnd(bs, k),
        Nat.is_eq(Nat.add(hits(us, k, True{}), hits(us, k, False{})), 1n),
        Bool.and(Nat.is_eq(hits(us, k, True{}), 1n), Nat.is_eq(hits(us, k, False{}), 1n))),
        bndge(k, us, bs))
def ends_below(es: List<&2, Ty.Edge>, +nv: Nat) -> Bool:
  match es:
    case []: True{}
    case +e <> t: Bool.and(Bool.and(Nat.is_lt(ev0(e), nv), Nat.is_lt(ev1(e), nv)), ends_below(t, nv))
def open_shell(+vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>, +fs: List<&2, BD.FS>,
    +bs: List<&2, Nat>, +chi: Nat) -> Bool:
  +nv = List.length(&2, Ty.Vertex, vs)
  +ne = List.length(&2, Ty.Edge, es)
  +nf = List.length(&2, BD.FS, fs)
  Bool.and(Bool.and(faces_closed(es, fs), bndge(ne, uses(fs), bs)),
    Bool.and(ends_below(es, nv), Nat.is_eq(Nat.add(nv, nf), Nat.add(ne, chi))))

def xk(+v: F64) -> X.Xp:
  X.X_k{v}
def env0() -> X.Env:
  X.env_of([])
def fb(+b: Bool) -> String:
  match b:
    case True{}: "1"
    case False{}: "0"
def fbits(+v: F64) -> String:
  U64.show(F64.bits(v))
def sa(+s: String) -> S.Sx:
  S.Sx_a{s}
def sl(+xs: List<&2, S.Sx>) -> S.Sx:
  S.Sx_l{xs}
def opnm(o: M.Op) -> String:
  M.op_name(o)
def parsed(+x: S.Sx) -> String:
  opnm(S.op_of(x, []))
def shown(+x: S.Sx) -> String:
  S.sx_show(S.op_sx(S.op_of(x, []), []))
def gr_s(+g: SU.GR) -> String:
  match g:
    case SU.GR_ok{}: "ok"
    case SU.GR_no{+why, +fix}: "no:" ++ why ++ " | " ++ fix
def p3(+x: F64, +y: F64, +z: F64) -> V.Point:
  V.Pt{x, y, z}
def rect_pp() -> SU.PP:
  SU.PP{p3(0.0f64, 0.0f64, 0.0f64), p3(4.0f64, 0.0f64, 0.0f64), p3(6.0f64, 0.0f64, 0.0f64),
    p3(10.0f64, 0.0f64, 0.0f64), p3(0.0f64, 2.0f64, 0.0f64), p3(4.0f64, 2.0f64, 0.0f64),
    p3(6.0f64, 2.0f64, 0.0f64), p3(10.0f64, 2.0f64, 0.0f64), p3(0.0f64, 3.0f64, 0.0f64),
    p3(4.0f64, 3.0f64, 0.0f64), p3(6.0f64, 3.0f64, 0.0f64), p3(10.0f64, 3.0f64, 0.0f64),
    p3(0.0f64, 5.0f64, 0.0f64), p3(4.0f64, 5.0f64, 0.0f64), p3(6.0f64, 5.0f64, 0.0f64),
    p3(10.0f64, 5.0f64, 0.0f64)}
def cowl_pp() -> SU.PP:
  SU.PP{p3(0.0f64, 0.0f64, 0.0f64), p3(4.0f64, 0.0f64, 0.0f64), p3(6.0f64, 0.0f64, 0.0f64),
    p3(10.0f64, 0.0f64, 0.0f64), p3(0.0f64, 2.0f64, 0.0f64), p3(4.0f64, 2.0f64, 0.288f64),
    p3(6.0f64, 2.0f64, 0.288f64), p3(10.0f64, 2.0f64, 0.0f64), p3(0.0f64, 3.0f64, 0.0f64),
    p3(4.0f64, 3.0f64, 0.288f64), p3(6.0f64, 3.0f64, 0.288f64), p3(10.0f64, 3.0f64, 0.0f64),
    p3(0.0f64, 5.0f64, 0.0f64), p3(4.0f64, 5.0f64, 0.0f64), p3(6.0f64, 5.0f64, 0.0f64),
    p3(10.0f64, 5.0f64, 0.0f64)}
def curve_pp() -> SU.PP:
  SU.PP{p3(0.0f64, 0.0f64, 0.0f64), p3(3.0f64, 1.0f64, 0.0f64), p3(7.0f64, F64.neg(1.0f64), 0.0f64),
    p3(10.0f64, 0.0f64, 0.0f64), p3(0.0f64, 2.0f64, 0.0f64), p3(3.0f64, 2.0f64, 0.0f64),
    p3(7.0f64, 2.0f64, 0.0f64), p3(10.0f64, 2.0f64, 0.0f64), p3(0.0f64, 3.0f64, 0.0f64),
    p3(3.0f64, 3.0f64, 0.0f64), p3(7.0f64, 3.0f64, 0.0f64), p3(10.0f64, 3.0f64, 0.0f64),
    p3(0.0f64, 5.0f64, 0.0f64), p3(3.0f64, 5.0f64, 0.0f64), p3(7.0f64, 5.0f64, 0.0f64),
    p3(10.0f64, 5.0f64, 0.0f64)}
def rowsame_pp() -> SU.PP:
  SU.PP{p3(0.0f64, 0.0f64, 0.0f64), p3(4.0f64, 0.0f64, 0.0f64), p3(6.0f64, 0.0f64, 0.0f64),
    p3(10.0f64, 0.0f64, 0.0f64), p3(0.0f64, 0.0f64, 0.0f64), p3(4.0f64, 0.0f64, 0.0f64),
    p3(6.0f64, 0.0f64, 0.0f64), p3(10.0f64, 0.0f64, 0.0f64), p3(0.0f64, 3.0f64, 0.0f64),
    p3(4.0f64, 3.0f64, 0.0f64), p3(6.0f64, 3.0f64, 0.0f64), p3(10.0f64, 3.0f64, 0.0f64),
    p3(0.0f64, 5.0f64, 0.0f64), p3(4.0f64, 5.0f64, 0.0f64), p3(6.0f64, 5.0f64, 0.0f64),
    p3(10.0f64, 5.0f64, 0.0f64)}
def colsame_pp() -> SU.PP:
  SU.PP{p3(0.0f64, 0.0f64, 0.0f64), p3(0.0f64, 0.0f64, 0.0f64), p3(6.0f64, 0.0f64, 0.0f64),
    p3(10.0f64, 0.0f64, 0.0f64), p3(0.0f64, 2.0f64, 0.0f64), p3(0.0f64, 2.0f64, 0.0f64),
    p3(6.0f64, 2.0f64, 0.0f64), p3(10.0f64, 2.0f64, 0.0f64), p3(0.0f64, 3.0f64, 0.0f64),
    p3(0.0f64, 3.0f64, 0.0f64), p3(6.0f64, 3.0f64, 0.0f64), p3(10.0f64, 3.0f64, 0.0f64),
    p3(0.0f64, 5.0f64, 0.0f64), p3(0.0f64, 5.0f64, 0.0f64), p3(6.0f64, 5.0f64, 0.0f64),
    p3(10.0f64, 5.0f64, 0.0f64)}
def cornsame_pp() -> SU.PP:
  SU.PP{p3(0.0f64, 0.0f64, 0.0f64), p3(4.0f64, 0.0f64, 0.0f64), p3(6.0f64, 0.0f64, 0.0f64),
    p3(10.0f64, 0.0f64, 0.0f64), p3(0.0f64, 2.0f64, 0.0f64), p3(4.0f64, 2.0f64, 0.0f64),
    p3(6.0f64, 2.0f64, 0.0f64), p3(10.0f64, 2.0f64, 0.0f64), p3(0.0f64, 3.0f64, 0.0f64),
    p3(4.0f64, 3.0f64, 0.0f64), p3(6.0f64, 3.0f64, 0.0f64), p3(10.0f64, 3.0f64, 0.0f64),
    p3(0.0f64, 5.0f64, 0.0f64), p3(4.0f64, 5.0f64, 0.0f64), p3(6.0f64, 5.0f64, 0.0f64),
    p3(0.0f64, 0.0f64, 0.0f64)}
def nan_pp() -> SU.PP:
  SU.PP{p3(0.0f64, 0.0f64, 0.0f64), p3(4.0f64, 0.0f64, 0.0f64), p3(6.0f64, 0.0f64, 0.0f64),
    p3(10.0f64, 0.0f64, 0.0f64), p3(0.0f64, 2.0f64, 0.0f64), p3(F64{9218868437227405312u64}, 2.0f64, 0.0f64),
    p3(6.0f64, 2.0f64, 0.0f64), p3(10.0f64, 2.0f64, 0.0f64), p3(0.0f64, 3.0f64, 0.0f64),
    p3(4.0f64, 3.0f64, 0.0f64), p3(6.0f64, 3.0f64, 0.0f64), p3(10.0f64, 3.0f64, 0.0f64),
    p3(0.0f64, 5.0f64, 0.0f64), p3(4.0f64, 5.0f64, 0.0f64), p3(6.0f64, 5.0f64, 0.0f64),
    p3(10.0f64, 5.0f64, 0.0f64)}
def box_lo() -> SU.LO:
  SU.LO{8.0f64, 0.0f64, 0.0f64, 10.0f64, 5.0f64, 0.0f64, 0.0f64, 10.0f64, 5.0f64}
def taper_lo() -> SU.LO:
  SU.LO{8.0f64, 0.0f64, 0.0f64, 10.0f64, 5.0f64, 1.0f64, 1.0f64, 9.0f64, 4.0f64}
def sec_sw() -> SU.SWO:
  SU.SWO{90u64, 2.0f64, 6.0f64, 0.0f64, 4.0f64}
def stagev(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> String:
  fb(Ty.okd_ok(B4.brep_incid_c(b, fuel))) ++ fb(Ty.okd_ok(B4.brep_use_c(b, prof, fuel))) ++
    fb(Ty.okd_ok(B4.brep_loop_c(b, fuel))) ++ fb(Ty.okd_ok(B4.brep_facekind_c(b, fuel))) ++
    fb(Ty.okd_ok(B4.brep_prof_c(b, prof, fuel))) ++ fb(Ty.okd_ok(B4.brep_embed_c(b, fuel))) ++
    fb(Ty.okd_ok(B4.brep_link_c(b, prof, fuel))) ++ fb(Ty.okd_ok(B4.brep_conn_c(b, fuel))) ++
    fb(Ty.okd_ok(B4.brep_coin_c(b, fuel))) ++ fb(Ty.okd_ok(B4.brep_xing_c(b, fuel))) ++
    fb(Ty.okd_ok(B4.brep_orient_c(b, fuel)))
def tok_open(+bt: BD.Bt) -> String:
  BD.Bt{+b, +fns} = bt
  fb(Ty.tres_ok(B4.brep_checked(b, Ty.P_open_shell{}, M.fuel_of(b))))
def tok_man(+bt: BD.Bt) -> String:
  BD.Bt{+b, +fns} = bt
  fb(Ty.tres_ok(B4.brep_checked(b, Ty.P_manifold_solid{}, M.fuel_of(b))))
def stv_open(+bt: BD.Bt) -> String:
  BD.Bt{+b, +fns} = bt
  stagev(b, Ty.P_open_shell{}, M.fuel_of(b))
def stv_man(+bt: BD.Bt) -> String:
  BD.Bt{+b, +fns} = bt
  stagev(b, Ty.P_manifold_solid{}, M.fuel_of(b))
def nats(xs: List<&2, Nat>) -> String:
  match xs:
    case []: ""
    case +h <> t: Nat.show(h) ++ "," ++ nats(t)
def lf_lit() -> F9.LF:
  F9.LF{"", 2u64, 0.0f64, 0.0f64, 10.0f64, 5.0f64, 1.0f64, 1.0f64, 9.0f64, 4.0f64}
def fr_lit() -> F9.FR:
  F9.FR{0.0f64, 0.0f64, 10.0f64, 5.0f64, 0.0f64, 0.0f64, 10.0f64, 5.0f64, 8.0f64, 1u64}
def pcs_rect() -> List<&2, F.Pc>:
  [F.P_ln{2.0f64, 0.0f64, 6.0f64, 0.0f64}, F.P_ln{6.0f64, 0.0f64, 6.0f64, 4.0f64},
    F.P_ln{6.0f64, 4.0f64, 2.0f64, 4.0f64}, F.P_ln{2.0f64, 4.0f64, 2.0f64, 0.0f64}]
def pcs_rot() -> List<&2, F.Pc>:
  [F.P_ln{6.0f64, 0.0f64, 6.0f64, 4.0f64}, F.P_ln{6.0f64, 4.0f64, 2.0f64, 4.0f64},
    F.P_ln{2.0f64, 4.0f64, 2.0f64, 0.0f64}, F.P_ln{2.0f64, 0.0f64, 6.0f64, 0.0f64}]
def pcs_slant() -> List<&2, F.Pc>:
  [F.P_ln{2.0f64, 0.0f64, 6.0f64, 0.0f64}, F.P_ln{6.0f64, 0.0f64, 5.0f64, 4.0f64},
    F.P_ln{5.0f64, 4.0f64, 2.0f64, 4.0f64}, F.P_ln{2.0f64, 4.0f64, 2.0f64, 0.0f64}]
def pcs_tri() -> List<&2, F.Pc>:
  [F.P_ln{2.0f64, 0.0f64, 6.0f64, 0.0f64}, F.P_ln{6.0f64, 0.0f64, 2.0f64, 4.0f64},
    F.P_ln{2.0f64, 4.0f64, 2.0f64, 0.0f64}]
def rt_s(+r: SU.RT) -> String:
  SU.RT{+r0, +r1, +z0, +z1, +ok} = r
  fbits(r0) ++ "/" ++ fbits(r1) ++ "/" ++ fbits(z0) ++ "/" ++ fbits(z1) ++ "/" ++ fb(ok)
def lo_s(+l: SU.LO) -> String:
  SU.LO{+z, +x0, +y0, +x1, +y1, +u0, +v0, +u1, +v1} = l
  fbits(z) ++ "/" ++ fbits(x0) ++ "/" ++ fbits(y0) ++ "/" ++ fbits(x1) ++ "/" ++ fbits(y1) ++ "/" ++
    fbits(u0) ++ "/" ++ fbits(v0) ++ "/" ++ fbits(u1) ++ "/" ++ fbits(v1)
def iv_s(+a: I.I) -> String:
  fbits(I.i_lo(a)) ++ "/" ++ fbits(I.i_hi(a))
def be_s(+b: SU.BE) -> String:
  SU.BE{+eid, +lo, +hi, +cert} = b
  Nat.show(eid) ++ ":" ++ fbits(lo) ++ "/" ++ fbits(hi) ++ "/" ++ fb(cert)
def bes_s(bs: List<&2, SU.BE>) -> String:
  match bs:
    case []: ""
    case +b <> t: be_s(b) ++ ";" ++ bes_s(t)
def uline(+x: String, +y: String) -> S.Sx:
  sl([sa("line"), sa(x), sa(y)])
def upath() -> S.Sx:
  sl([sa("path"), sa("0"), sa("0"), uline("10", "0"), uline("10", "5"), uline("0", "5")])
def ureg() -> S.Sx:
  sl([sa("region"), upath()])
def upath_top() -> S.Sx:
  sl([sa("path"), sa("1"), sa("1"), uline("9", "1"), uline("9", "4"), uline("1", "4")])
def ureg_top() -> S.Sx:
  sl([sa("region"), upath_top()])
def upath_sec() -> S.Sx:
  sl([sa("path"), sa("2"), sa("0"), uline("6", "0"), uline("6", "4"), uline("2", "4")])
def ureg_sec() -> S.Sx:
  sl([sa("region"), upath_sec()])
def upt(+x: String, +y: String, +z: String) -> S.Sx:
  sl([sa("pt"), sa(x), sa(y), sa(z)])
def patch_sx() -> S.Sx:
  sl([sa("patch"), upt("0", "0", "0"), upt("4", "0", "0"), upt("6", "0", "0"), upt("10", "0", "0"),
    upt("0", "2", "0"), upt("4", "2", "0"), upt("6", "2", "0"), upt("10", "2", "0"),
    upt("0", "3", "0"), upt("4", "3", "0"), upt("6", "3", "0"), upt("10", "3", "0"),
    upt("0", "5", "0"), upt("4", "5", "0"), upt("6", "5", "0"), upt("10", "5", "0")])
def rect_xps() -> List<&2, X.Xp>:
  [xk(0.0f64), xk(0.0f64), xk(0.0f64), xk(4.0f64), xk(0.0f64), xk(0.0f64), xk(6.0f64), xk(0.0f64),
    xk(0.0f64), xk(10.0f64), xk(0.0f64), xk(0.0f64), xk(0.0f64), xk(2.0f64), xk(0.0f64), xk(4.0f64),
    xk(2.0f64), xk(0.0f64), xk(6.0f64), xk(2.0f64), xk(0.0f64), xk(10.0f64), xk(2.0f64), xk(0.0f64),
    xk(0.0f64), xk(3.0f64), xk(0.0f64), xk(4.0f64), xk(3.0f64), xk(0.0f64), xk(6.0f64), xk(3.0f64),
    xk(0.0f64), xk(10.0f64), xk(3.0f64), xk(0.0f64), xk(0.0f64), xk(5.0f64), xk(0.0f64), xk(4.0f64),
    xk(5.0f64), xk(0.0f64), xk(6.0f64), xk(5.0f64), xk(0.0f64), xk(10.0f64), xk(5.0f64), xk(0.0f64)]
def hull_in(+lo: F64, +hi: F64, +v: F64) -> Bool:
  Bool.and(F64.is_le(lo, v), F64.is_le(v, hi))
def wlo(+v: F64) -> F64:
  Bool.pick(F64, F64.is_eq(v, 0.0f64), F64.neg(F64{64u64}), F64{U64.sub(F64.bits(v), 64u64)})
def whi(+v: F64) -> F64:
  F64{U64.add(F64.bits(v), 64u64)}
def hull_pt(+p: V.Point) -> Bool:
  V.Pt{+x, +y, +z} = p
  Bool.and(hull_in(wlo(0.0f64), whi(10.0f64), x),
    Bool.and(hull_in(wlo(0.0f64), whi(5.0f64), y), hull_in(wlo(0.0f64), whi(0.288f64), z)))
def hull9(+b: G.BezP, +u: F64, +v: F64) -> Bool:
  hull_pt(G.gres_p(GO.bezp_eval(b, u, v)))
def hull_all() -> Bool:
  +b = SU.patch_bp(cowl_pp())
  Bool.and(hull9(b, 0.25f64, 0.25f64),
    Bool.and(hull9(b, 0.5f64, 0.25f64),
      Bool.and(hull9(b, 0.75f64, 0.25f64),
        Bool.and(hull9(b, 0.25f64, 0.5f64),
          Bool.and(hull9(b, 0.5f64, 0.5f64),
            Bool.and(hull9(b, 0.75f64, 0.5f64),
              Bool.and(hull9(b, 0.25f64, 0.75f64),
                Bool.and(hull9(b, 0.5f64, 0.75f64), hull9(b, 0.75f64, 0.75f64)))))))))
def uhd(xs: List<&2, U64>) -> U64:
  match xs:
    case []: 999u64
    case h <> t: h
def ureg_ev() -> F.Region:
  F.Rg{F.L_path{xk(0.0f64), xk(0.0f64),
    [F.S_line{xk(10.0f64), xk(0.0f64)}, F.S_line{xk(10.0f64), xk(5.0f64)}, F.S_line{xk(0.0f64), xk(5.0f64)}]}, []}
def ureg_top_ev() -> F.Region:
  F.Rg{F.L_path{xk(1.0f64), xk(1.0f64),
    [F.S_line{xk(9.0f64), xk(1.0f64)}, F.S_line{xk(9.0f64), xk(4.0f64)}, F.S_line{xk(1.0f64), xk(4.0f64)}]}, []}
def be_nth(bs: List<&2, SU.BE>, +i: Nat) -> SU.BE:
  match bs:
    case []: SU.BE{999n, 0.0f64, 0.0f64, False{}}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: be_nth(t, j)
def br_s(+r: SU.BR) -> String:
  SU.BR{+i, +eid, +lo, +hi, +cert} = r
  Nat.show(i) ++ "/" ++ Nat.show(eid) ++ "/" ++ fb(cert)
def br_nth(rs: List<&2, SU.BR>, +i: Nat) -> SU.BR:
  match rs:
    case []: SU.BR{999n, 999n, 0.0f64, 0.0f64, False{}}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: br_nth(t, j)
def g_lo_no__got() -> String:
  gr_s(SU.lo_go(False{}))
def g_lo_no__want() -> String:
  "no:loft-open-not-planar | loft-open axis-aligned rect pairs with planar walls"
def g_sa_no__got() -> String:
  gr_s(SU.sa_go(False{}, 45u64))
def g_sa_no__want() -> String:
  "no:sweep-angle-not-certified | sweep-open 90, 180 or 270 degrees"
def g_sp_no__got() -> String:
  gr_s(SU.sp_go(False{}))
def g_sp_no__want() -> String:
  "no:sweep-profile-not-admitted | sweep-open one axis-aligned rect profile off the axis"
def g_pa_no__got() -> String:
  gr_s(SU.pa_go(False{}))
def g_pa_no__want() -> String:
  "no:patch-degenerate | give 16 finite control points with distinct rows, columns and corners"
def g_tc_no__got() -> String:
  gr_s(SU.tc_go(False{}))
def g_tc_no__want() -> String:
  "no:thicken-curvature-not-certified | thicken rect patches, rect ducts and rect sectors only"
def g_ts_no__got() -> String:
  gr_s(SU.ts_go(False{}))
def g_ts_no__want() -> String:
  "no:thicken-consumes-shell | keep wall thickness below the shell minimum"
def g_su_no__got() -> String:
  gr_s(SU.su_go(False{}))
def g_su_no__want() -> String:
  "no:surf-needs-open-shell | run surf on a loft-open, sweep-open or patch node"
def g_th_no__got() -> String:
  gr_s(SU.th_go(False{}))
def g_th_no__want() -> String:
  "no:thicken-needs-open-shell | thicken-open an open-shell node"
def g_dg_no__got() -> String:
  gr_s(SU.dg_go(False{}, 0.0f64))
def g_dg_no__want() -> String:
  "no:degenerate-feature | give finite positive wall thickness"
def g_all_ok__got() -> String:
  gr_s(SU.lo_go(True{})) ++ "/" ++ gr_s(SU.sa_go(True{}, 90u64)) ++ "/" ++ gr_s(SU.sp_go(True{})) ++ "/" ++
    gr_s(SU.pa_go(True{})) ++ "/" ++ gr_s(SU.tc_go(True{})) ++ "/" ++ gr_s(SU.ts_go(True{})) ++ "/" ++
    gr_s(SU.su_go(True{})) ++ "/" ++ gr_s(SU.th_go(True{})) ++ "/" ++ gr_s(SU.dg_go(True{}, 1.0f64))
def g_all_ok__want() -> String:
  "ok/ok/ok/ok/ok/ok/ok/ok/ok"
def pa_rect__got() -> String:
  fb(SU.pa_ok(rect_pp()))
def pa_rect__want() -> String:
  "1"
def pa_rows__got() -> String:
  fb(SU.pa_ok(rowsame_pp()))
def pa_rows__want() -> String:
  "0"
def pa_cols__got() -> String:
  fb(SU.pa_ok(colsame_pp()))
def pa_cols__want() -> String:
  "0"
def pa_corn__got() -> String:
  fb(SU.pa_ok(cornsame_pp()))
def pa_corn__want() -> String:
  "0"
def pa_nan__got() -> String:
  fb(SU.pa_ok(nan_pp()))
def pa_nan__want() -> String:
  "0"
def pa_cowl__got() -> String:
  fb(SU.pa_ok(cowl_pp()))
def pa_cowl__want() -> String:
  "1"
def pa_curve__got() -> String:
  fb(SU.pa_ok(curve_pp()))
def pa_curve__want() -> String:
  "1"
def slab_rect__got() -> String:
  fb(SU.rect_slab_ok(rect_pp()))
def slab_rect__want() -> String:
  "1"
def slab_cowl__got() -> String:
  fb(SU.rect_slab_ok(cowl_pp()))
def slab_cowl__want() -> String:
  "0"
def slab_curve__got() -> String:
  fb(SU.rect_slab_ok(curve_pp()))
def slab_curve__want() -> String:
  "0"
def deg_ok__got() -> String:
  fb(SU.swo_deg_ok(90u64)) ++ fb(SU.swo_deg_ok(180u64)) ++ fb(SU.swo_deg_ok(270u64)) ++
    fb(SU.swo_deg_ok(45u64)) ++ fb(SU.swo_deg_ok(360u64)) ++ fb(SU.swo_deg_ok(0u64))
def deg_ok__want() -> String:
  "111000"
def qd_maps__got() -> String:
  Nat.show(SU.qd_n(SU.Q1{})) ++ "/" ++ Nat.show(SU.qd_n(SU.Q2{})) ++ "/" ++ Nat.show(SU.qd_n(SU.Q3{})) ++
    "/" ++ U64.show(SU.qd_deg(SU.Q1{})) ++ "/" ++ U64.show(SU.qd_deg(SU.Q2{})) ++ "/" ++
    U64.show(SU.qd_deg(SU.Q3{})) ++ "/" ++ Nat.show(SU.qd_n(SU.qd_of(90u64))) ++ "/" ++
    Nat.show(SU.qd_n(SU.qd_of(180u64))) ++ "/" ++ Nat.show(SU.qd_n(SU.qd_of(270u64)))
def qd_maps__want() -> String:
  "1/2/3/90/180/270/1/2/3"
def duct_inner__got() -> String:
  fb(SU.duct_inner_ok(SU.duct_dims(box_lo(), 2.0f64))) ++ fb(SU.duct_inner_ok(SU.duct_dims(box_lo(), 6.0f64)))
def duct_inner__want() -> String:
  "10"
def sec_t__got() -> String:
  fb(SU.sec_t_ok(sec_sw(), 1.0f64)) ++ fb(SU.sec_t_ok(sec_sw(), 5.0f64)) ++ fb(SU.sec_t_ok(sec_sw(), 4.0f64))
def sec_t__want() -> String:
  "100"
def rt_canon__got() -> String:
  rt_s(SU.sw_rect_of(pcs_rect()))
def rt_canon__want() -> String:
  "4611686018427387904/4618441417868443648/0/4616189618054758400/1"
def rt_rot__got() -> String:
  rt_s(SU.sw_rect_of(pcs_rot()))
def rt_rot__want() -> String:
  "4611686018427387904/4618441417868443648/0/4616189618054758400/1"
def rt_slant__got() -> String:
  fb(SU.rt_ok(SU.sw_rect_of(pcs_slant())))
def rt_slant__want() -> String:
  "0"
def rt_tri__got() -> String:
  fb(SU.rt_ok(SU.sw_rect_of(pcs_tri())))
def rt_tri__want() -> String:
  "0"
def lo_of_lf__got() -> String:
  lo_s(SU.lo_of_lf(lf_lit(), 8.0f64))
def lo_of_lf__want() -> String:
  "4620693217682128896/0/0/4621819117588971520/4617315517961601024/4607182418800017408/4607182418800017408/4621256167635550208/4616189618054758400"
def os_loft__got() -> String:
  fb(open_shell(F9.fr_vs(8n, 0n, fr_lit()), F9.fr_es(12n, 0n, fr_lit()), SU.loft_wall_fs(fr_lit()),
    SU.loft_bnd_ids(), 0n))
def os_loft__want() -> String:
  "1"
def os_swo__got() -> String:
  fb(open_shell(RV.sec_vs(SU.swo_pcs(sec_sw()), 4n, 2n), RV.sec_es(SU.swo_pcs(sec_sw()), 4n, 1n),
    RV.sides_all(1n, SU.swo_pcs(sec_sw()), 4n, 0n, 1n, 1u64, 0n), SU.swo_bnd_ids(SU.Q1{}), 0n))
def os_swo__want() -> String:
  "1"
def os_patch__got() -> String:
  fb(open_shell(SU.patch_vs(rect_pp()), SU.patch_es(rect_pp()), SU.patch_fs(rect_pp(), 1u64),
    SU.patch_bnd_ids(), 1n))
def os_patch__want() -> String:
  "1"
def os_slab__got() -> String:
  fb(open_shell(SU.slab_vs(rect_pp(), 2.0f64), SU.slab_es(rect_pp(), 2.0f64),
    SU.slab_fs(rect_pp(), 2.0f64, 1u64), [], 2n))
def os_slab__want() -> String:
  "1"
def os_duct__got() -> String:
  fb(open_shell(SU.duct_vs(SU.duct_dims(box_lo(), 2.0f64)), SU.duct_es(SU.duct_dims(box_lo(), 2.0f64)),
    SU.duct_fs(SU.duct_dims(box_lo(), 2.0f64), 1u64), [], 0n))
def os_duct__want() -> String:
  "1"
def os_sec__got() -> String:
  fb(open_shell(SU.sec_vs(SU.sec_dims(sec_sw(), 1.0f64), 1n), SU.sec_es(SU.sec_dims(sec_sw(), 1.0f64), 1n),
    SU.sec_fs(SU.sec_dims(sec_sw(), 1.0f64), 1n, 1u64), [], 0n))
def os_sec__want() -> String:
  "1"
def hits_loft__got() -> String:
  +us = uses(SU.loft_wall_fs(fr_lit()))
  Nat.show(hits(us, 0n, True{})) ++ "/" ++ Nat.show(hits(us, 0n, False{})) ++ "/" ++
    Nat.show(hits(us, 8n, True{})) ++ "/" ++ Nat.show(hits(us, 8n, False{}))
def hits_loft__want() -> String:
  "1/0/1/1"
def counts_sec__got() -> String:
  +ps = SU.swo_pcs(sec_sw())
  Nat.show(List.length(&2, Ty.Vertex, RV.sec_vs(ps, 4n, 3n))) ++ "/" ++
    Nat.show(List.length(&2, Ty.Edge, RV.sec_es(ps, 4n, 2n))) ++ "/" ++
    Nat.show(List.length(&2, BD.FS, RV.sides_all(2n, ps, 4n, 0n, 2n, 1u64, 0n)))
def counts_sec__want() -> String:
  "12/20/8"
def area_loft__got() -> String:
  iv_s(SU.loft_area_I(box_lo()))
def area_loft__want() -> String:
  "4642648265865560050/4642648265865560078"
def area_swo__got() -> String:
  iv_s(SU.swo_area_I(sec_sw()))
def area_swo__want() -> String:
  "4636774654688898321/4636774654688898337"
def area_patch__got() -> String:
  fbits(SU.patch_area_est(rect_pp()))
def area_patch__want() -> String:
  "4632233691727265792"
def vol_slab__got() -> String:
  fbits(SU.slab_vol(rect_pp(), 2.0f64))
def vol_slab__want() -> String:
  "4636737291354636288"
def vol_duct__got() -> String:
  fbits(SU.duct_vol(SU.duct_dims(box_lo(), 2.0f64)))
def vol_duct__want() -> String:
  "4647151865492930560"
def vol_sec__got() -> String:
  fbits(SU.sec_vol(sec_sw(), 1.0f64))
def vol_sec__want() -> String:
  "4636774654688898328"
def op_tags__got() -> String:
  +e = env0()
  U64.show(uhd(M.op_w(M.O_loft_open{xk(8.0f64), ureg_ev(), ureg_top_ev(), 0u64, 0u64}, e))) ++ "/" ++
    U64.show(uhd(M.op_w(M.O_sw_open{90u64, [ureg_ev()], 0u64, 0u64, 0u64}, e))) ++ "/" ++
    U64.show(uhd(M.op_w(M.O_patch{rect_xps()}, e))) ++ "/" ++
    U64.show(uhd(M.op_w(M.O_thicken_open{3u64, xk(1.0f64)}, e)))
def op_tags__want() -> String:
  "35/36/37/38"
def op_names__got() -> String:
  opnm(M.O_loft_open{xk(8.0f64), ureg_ev(), ureg_top_ev(), 0u64, 0u64}) ++ "/" ++
    opnm(M.O_sw_open{90u64, [ureg_ev()], 0u64, 0u64, 0u64}) ++ "/" ++ opnm(M.O_patch{rect_xps()}) ++ "/" ++
    opnm(M.O_thicken_open{3u64, xk(1.0f64)})
def op_names__want() -> String:
  "loft-open/sweep-open/patch/thicken-open"
def op_base__got() -> String:
  U64.show(M.op_base(M.O_thicken_open{3u64, xk(1.0f64)})) ++ "/" ++
    fb(M.op_has_base(M.O_thicken_open{3u64, xk(1.0f64)})) ++ "/" ++ fb(M.op_has_base(M.O_patch{rect_xps()}))
def op_base__want() -> String:
  "3/1/0"
def th_base__got() -> String:
  fb(M.th_base_ok(M.O_patch{rect_xps()})) ++ "/" ++
    fb(M.th_base_ok(M.O_box{xk(1.0f64), xk(1.0f64), xk(1.0f64)}))
def th_base__want() -> String:
  "1/0"
def parse_loft__got() -> String:
  parsed(sl([sa("loft-open"), sa("8"), ureg(), ureg_top()]))
def parse_loft__want() -> String:
  "loft-open"
def parse_swo__got() -> String:
  parsed(sl([sa("sweep-open"), sl([sa("arc"), sa("90")]), ureg_sec()]))
def parse_swo__want() -> String:
  "sweep-open"
def parse_patch__got() -> String:
  parsed(patch_sx())
def parse_patch__want() -> String:
  "patch"
def parse_tko__got() -> String:
  parsed(sl([sa("thicken-open"), sa("2"), sa("1.5")]))
def parse_tko__want() -> String:
  "thicken-open"
def parse_bad__got() -> String:
  parsed(sl([sa("patch"), sa("1")])) ++ "/" ++
    parsed(sl([sa("sweep-open"), sl([sa("line"), sa("5")]), ureg_sec()]))
def parse_bad__want() -> String:
  "unknown/unknown"
def show_patch__got() -> String:
  shown(patch_sx())
def show_patch__want() -> String:
  "(patch (pt 0 0 0) (pt 4 0 0) (pt 6 0 0) (pt 10 0 0) (pt 0 2 0) (pt 4 2 0) (pt 6 2 0) (pt 10 2 0) (pt 0 3 0) (pt 4 3 0) (pt 6 3 0) (pt 10 3 0) (pt 0 5 0) (pt 4 5 0) (pt 6 5 0) (pt 10 5 0))"
def show_loft__got() -> String:
  shown(sl([sa("loft-open"), sa("8"), ureg(), ureg_top()]))
def show_loft__want() -> String:
  "(loft-open 8 (region (path 0 0 (line 10 0) (line 10 5) (line 0 5))) (region (path 1 1 (line 9 1) (line 9 4) (line 1 4))))"
def tok_loft__got() -> String:
  tok_open(SU.loft_open_bt(box_lo(), 1u64))
def tok_loft__want() -> String:
  "1"
def stv_loft__got() -> String:
  stv_open(SU.loft_open_bt(box_lo(), 1u64))
def stv_loft__want() -> String:
  "11111111111"
def tok_swo__got() -> String:
  tok_open(SU.swo_open_bt(sec_sw(), SU.Q1{}, 1u64))
def tok_swo__want() -> String:
  "1"
def stv_swo__got() -> String:
  stv_open(SU.swo_open_bt(sec_sw(), SU.Q1{}, 1u64))
def stv_swo__want() -> String:
  "11111111111"
def tok_patch__got() -> String:
  tok_open(SU.patch_open_bt(rect_pp(), 1u64))
def tok_patch__want() -> String:
  "1"
def stv_patch__got() -> String:
  stv_open(SU.patch_open_bt(rect_pp(), 1u64))
def stv_patch__want() -> String:
  "11111111111"
def tok_slab__got() -> String:
  tok_man(SU.slab_bt(rect_pp(), 2.0f64, 1u64))
def tok_slab__want() -> String:
  "1"
def stv_slab__got() -> String:
  stv_man(SU.slab_bt(rect_pp(), 2.0f64, 1u64))
def stv_slab__want() -> String:
  "11111111111"
def tok_duct__got() -> String:
  tok_man(SU.duct_bt(SU.duct_dims(box_lo(), 2.0f64), 1u64))
def tok_duct__want() -> String:
  "1"
def stv_duct__got() -> String:
  stv_man(SU.duct_bt(SU.duct_dims(box_lo(), 2.0f64), 1u64))
def stv_duct__want() -> String:
  "11111111111"
def tok_sec__got() -> String:
  tok_man(SU.sec_bt(SU.sec_dims(sec_sw(), 1.0f64), 1n, 1u64))
def tok_sec__want() -> String:
  "1"
def stv_sec__got() -> String:
  stv_man(SU.sec_bt(SU.sec_dims(sec_sw(), 1.0f64), 1n, 1u64))
def stv_sec__want() -> String:
  "11111111111"
def bnd_ids__got() -> String:
  nats(SU.loft_bnd_ids()) ++ "|" ++ nats(SU.swo_bnd_ids(SU.Q1{})) ++ "|" ++ nats(SU.swo_bnd_ids(SU.Q2{})) ++
    "|" ++ nats(SU.patch_bnd_ids())
def bnd_ids__want() -> String:
  "0,1,2,3,4,5,6,7,|4,5,6,7,8,9,10,11,|8,9,10,11,16,17,18,19,|0,1,2,3,"
def bnd_counts__got() -> String:
  Nat.show(List.length(&2, SU.BE, SU.loft_bnd(box_lo()))) ++ "/" ++
    Nat.show(List.length(&2, SU.BR, SU.surf_rows(SU.loft_bnd(box_lo())))) ++ "/" ++
    Nat.show(List.length(&2, SU.BE, SU.swo_bnd(sec_sw(), SU.Q1{}))) ++ "/" ++
    Nat.show(List.length(&2, SU.BR, SU.surf_rows(SU.swo_bnd(sec_sw(), SU.Q1{})))) ++ "/" ++
    Nat.show(List.length(&2, SU.BE, SU.patch_bnd(rect_pp()))) ++ "/" ++
    Nat.show(List.length(&2, SU.BR, SU.surf_rows(SU.patch_bnd(rect_pp()))))
def bnd_counts__want() -> String:
  "8/8/8/8/4/4"
def be_loft0__got() -> String:
  be_s(be_nth(SU.loft_bnd(box_lo()), 0n))
def be_loft0__want() -> String:
  "0:4621819117588971519/4621819117588971521/1"
def rows_first__got() -> String:
  br_s(br_nth(SU.surf_rows(SU.loft_bnd(box_lo())), 0n))
def rows_first__want() -> String:
  "0/0/1"
def rep_patch__got() -> String:
  SU.surf_rep(2u64, SU.SO_pt{rect_xps()}, env0())
def rep_patch__want() -> String:
  "surf node 2 kind patch faces 1 boundary 4\nedge n2.e0 len [10, 10] estimated\nedge n2.e1 len [5, 5] estimated\nedge n2.e2 len [10, 10] estimated\nedge n2.e3 len [5, 5] estimated\narea [50, 50] estimated\nblen [30, 30] estimated\nbbox 0 10 0 5 0 0\n"
def hull__got() -> String:
  fb(hull_all())
def hull__want() -> String:
  "1"
