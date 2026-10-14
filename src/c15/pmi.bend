import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../base/par.bend as B
import ../c06/model.bend as M
import ../c06/sx.bend as S
import ../c06/build.bend as BD
import ../c06/iv.bend as I
import ../c11/qdist.bend as QD
import ../c11/qinterf.bend as QI
import ../c11/qaccel.bend as QA
import ../c12/stepw.bend as SW
import ../c12/blob.bend as BL

type Datum is Data:
  Datum{ name: String, sel: String }
type Dim is Data:
  Dim{ name: String, nom: F64, lo: F64, hi: F64 }
type Tol is Data:
  Tol{ name: String, kind: U64, t: F64, sel: String, drf: List<&2, String> }
type State is Data:
  State{ name: String, grow: F64 }
type Stack is Data:
  Stack{ name: String, dims: List<&2, String> }
type Nodes is Data:
  Nodes{ a: U64, b: U64, pair: Bool, seen: Bool }
type PMI is Data:
  PMI{ nodes: Nodes, datums: List<&2, Datum>, dims: List<&2, Dim>, tols: List<&2, Tol>,
    states: List<&2, State>, stacks: List<&2, Stack>, ers: List<&2, ER> }
type ER is Data:
  ER_dt{ d: Datum }
  ER_dm{ d: Dim }
  ER_tol{ t: Tol }
  ER_st{ s: State }
  ER_sk{ s: Stack }
  ER_err{ why: String, fix: String }
type PR is Data:
  PR_ok{ p: PMI }
  PR_err{ why: String, fix: String }
type DU is Data:
  DU{ dup: Bool, xs: List<&2, String> }
type RV is Data:
  RV_ok{ line: String }
  RV_bad{ why: String, fix: String }
type FB is Data:
  FB_ok{}
  FB_bad{ why: String, fix: String }
type FR is Data:
  FR_ok{ s: String, n: Nat }
  FR_err{ why: String, fix: String }
  FR_line{ l: String }
type SR is Data:
  SR{ st: State, nom: F64, lo: F64, hi: F64 }
type CI is Data:
  CI{ hit: Bool, lo: F64, hi: F64, na: Nat, nb: Nat }
type BT is Data:
  BT{ fns: List<&2, BD.Fn>, fas: List<&2, Ty.Face>, vs: B.Tb<&2, Ty.Vertex>,
    es: B.Tb<&2, Ty.Edge>, ces: B.Tb<&2, Ty.Coedge>, lps: B.Tb<&2, Ty.Loop> }
type MP is Data:
  MP_yes{ p: G.Plane3 }
  MP_no{}
type OE is Data:
  OE_ok{ lo: F64, hi: F64 }
  OE_bad{ why: String, fix: String }
type DI is Data:
  DI{ nm: String, id: Nat }
type EM is Data:
  EM{ ok: Bool, why: String, s: String, next: Nat, n: Nat, dm: List<&2, DI> }
type ND is Data:
  ND_ok{ n: Nodes }
  ND_err{ why: String, fix: String }
type PT is Data:
  PT{ dts: List<&2, Datum>, dms: List<&2, Dim>, tls: List<&2, Tol>, sts: List<&2, State>,
    sks: List<&2, Stack> }
type TG is Data:
  TG{ kind: U64, nm: String }
type WN is Data:
  WN{ ok: Bool, x: I.I, y: I.I, z: I.I }
def m_nodes(+m: PMI) -> Nodes:
  PMI{+nd, +dts, +dms, +tls, +sts, +sks, +ers} = m
  nd
def nd_a(+n: Nodes) -> U64:
  Nodes{+a, +b, +pair, +seen} = n
  a
def nd_b(+n: Nodes) -> U64:
  Nodes{+a, +b, +pair, +seen} = n
  b
def nd_pair(+n: Nodes) -> Bool:
  Nodes{+a, +b, +pair, +seen} = n
  pair
def nd_seen(+n: Nodes) -> Bool:
  Nodes{+a, +b, +pair, +seen} = n
  seen
def cat(xs: List<&2, String>) -> String:
  match xs:
    case []: ""
    case x <> t: x ++ " " ++ cat(t)
def sdrop(xs: List<&2, String>, +i: Nat) -> List<&2, String>:
  match xs:
    case []: []
    case x <> +t:
      match i:
        case 0n: x <> t
        case 1n+j: sdrop(t, j)
def fnum_m(m: Maybe<&2, F64>) -> F64:
  match m:
    case None{}: F64.nan()
    case Some{v}: v
def fnum(+x: S.Sx) -> F64:
  fnum_m(S.dec(S.sx_s(x)))
def is_u64_m(m: Maybe<&2, U64>) -> Bool:
  match m:
    case None{}: False{}
    case Some{v}: True{}
def is_u64(+x: S.Sx) -> Bool:
  is_u64_m(U64.read(S.sx_s(x)))
def uval_m(m: Maybe<&2, U64>) -> U64:
  match m:
    case None{}: 0u64
    case Some{v}: v
def uval(+x: S.Sx) -> U64:
  uval_m(U64.read(S.sx_s(x)))
def pfn_s(+f: BD.Fn) -> String:
  BD.Fn{+nd, +k, +role, +i, +j} = f
  Bool.pick(String, U64.is_eq(role, 4u64),
    "n" ++ U64.show(nd) ++ ".cav." ++ Nat.show(k) ++ "." ++ Nat.show(i) ++ "." ++ Nat.show(j),
    "n" ++ U64.show(nd) ++ ".c" ++ Nat.show(k) ++ Bool.pick(String, U64.is_eq(role, 0u64), ".top",
      Bool.pick(String, U64.is_eq(role, 1u64), ".bottom", ".wall." ++ Nat.show(i) ++ "." ++ Nat.show(j))))
def psurf(s: G.GVal) -> U64:
  match s:
    case G.GV_pl{w}: 0u64
    case G.GV_cy{w}: 1u64
    case G.GV_bp{w}: 2u64
    case G.GV_sp{w}: 3u64
    case G.GV_co{w}: 4u64
    case G.GV_to{w}: 5u64
    case _: 6u64
def psurf_s(+k: U64) -> String:
  match k:
    case 0u64: "plane"
    case 1u64: "cylinder"
    case 2u64: "planar-patch"
    case 3u64: "sphere"
    case 4u64: "cone"
    case 5u64: "torus"
    case _: "other"
def sel_mem_go(+eq: Bool, +rec: Bool) -> Bool:
  match eq:
    case True{}: True{}
    case False{}: rec
def sel_mem(fs: List<&2, BD.Fn>, +s: String) -> Bool:
  match fs:
    case []: False{}
    case f <> t: sel_mem_go(String.eq(pfn_s(f), s), sel_mem(t, s))
def sel_idx_go(+eq: Bool, +rec: Nat, +i: Nat) -> Nat:
  match eq:
    case True{}: i
    case False{}: rec
def sel_idx_at(fs: List<&2, BD.Fn>, +s: String, +i: Nat) -> Nat:
  match fs:
    case []: i
    case f <> t: sel_idx_go(String.eq(pfn_s(f), s), sel_idx_at(t, s, Nat.add(i, 1n)), i)
def sel_idx(fs: List<&2, BD.Fn>, +s: String) -> Nat:
  sel_idx_at(fs, s, 0n)
def fa_at(fas: List<&2, Ty.Face>, +i: Nat) -> Ty.Face:
  match fas:
    case []: QD.fa_dflt()
    case f <> t:
      match i:
        case 0n: f
        case 1n+j: fa_at(t, j)
def sel_kind(+bt: BT, +s: String) -> U64:
  BT{+fns, +fas, +vs, +es, +ces, +lps} = bt
  Bool.pick(U64, sel_mem(fns, s), psurf(Ty.fa_surf(fa_at(fas, sel_idx(fns, s)))), 7u64)
def bt_of(+b: M.Body) -> BT:
  +br = M.bd_brep(b)
  +vs = Ty.brep_vs(br)
  +es = Ty.brep_es(br)
  +ces = Ty.brep_ces(br)
  +lps = Ty.brep_lps(br)
  BT{M.bd_fns(b), Ty.brep_fas(br), B.tb_of(Ty.Vertex, vs, QD.vx_dflt()),
    B.tb_of(Ty.Edge, es, QD.ed_dflt()), B.tb_of(Ty.Coedge, ces, QD.ce_dflt()),
    B.tb_of(Ty.Loop, lps, QD.lp_dflt())}
def pm_dim(ps: List<&2, M.Param>, +nm: String) -> Maybe<&2, M.Dim>:
  match ps:
    case []: None{}
    case p <> t:
      M.Pm{+id, +n, +d} = p
      Bool.pick(Maybe<&2, M.Dim>, String.eq(n, nm), Some{d}, pm_dim(t, nm))
def dim_par_m(m: Maybe<&2, M.Dim>, +nm: String, +pnm: String) -> ER:
  match m:
    case None{}: ER_err{"unknown-param " ++ pnm, "name a parameter from the design (show)"}
    case Some{d}:
      M.Dm{+nom, +lo, +hi} = d
      ER_dm{Dim{nm, nom, lo, hi}}
def dim_exp(+ok: Bool, +nm: String, +nom: F64, +lo: F64, +hi: F64) -> ER:
  match ok:
    case False{}: ER_err{"bad-dim",
      "write (dim NAME PARAM) or (dim NAME NOM LO HI) with finite numbers LO <= NOM <= HI"}
    case True{}: ER_dm{Dim{nm, nom, lo, hi}}
def pm_dim_of(+p: M.Part, +nm: String) -> Maybe<&2, M.Dim>:
  M.Pt{+ps, +ns} = p
  pm_dim(ps, nm)
def kind_of(+k: String) -> U64:
  Bool.pick(U64, String.eq(k, "flatness"), 1u64,
    Bool.pick(U64, String.eq(k, "perpendicularity"), 2u64,
      Bool.pick(U64, String.eq(k, "parallelism"), 3u64, 0u64)))
def kind_s(+k: U64) -> String:
  match k:
    case 1u64: "flatness"
    case 2u64: "perpendicularity"
    case 3u64: "parallelism"
    case _: "unknown-kind"
def sx_strs(xs: List<&2, S.Sx>) -> List<&2, String>:
  match xs:
    case []: []
    case h <> t: S.sx_s(h) <> sx_strs(t)
def tol_gate_t(+code: U64, +nm: String, +k: String, +t: F64, +sel: String, +mo: String,
    +rest: List<&2, S.Sx>) -> ER:
  match code:
    case 0u64: ER_tol{Tol{nm, kind_of(k), t, sel, sx_strs(rest)}}
    case 2u64: ER_err{"unsupported-modifier " ++ mo, "the only modifier is rfs"}
    case _: ER_err{"bad-tol", "write (tol NAME KIND T SEL rfs DATUM...) with flatness, perpendicularity or parallelism, finite T >= 0 and rfs"}
def st_go(+ok: Bool, +nm: String, +g: F64) -> ER:
  match ok:
    case False{}: ER_err{"bad-state", "write (state NAME GROW) with finite GROW > 0"}
    case True{}: ER_st{State{nm, g}}
def dims_ok(xs: List<&2, String>) -> Bool:
  match xs:
    case []: True{}
    case h <> t: Bool.and(Bool.not(String.eq(h, "")), dims_ok(t))
def nd_of(+x: S.Sx) -> ND:
  +xs = S.sx_xs(x)
  +n = List.length(&2, S.Sx, xs)
  +h = S.sx_s(S.sx_nth(xs, 0n))
  Bool.pick(ND, String.eq(h, "node"),
    Bool.pick(ND, Bool.and(Nat.is_eq(n, 2n), is_u64(S.sx_nth(xs, 1n))),
      ND_ok{Nodes{uval(S.sx_nth(xs, 1n)), 0u64, False{}, True{}}},
      ND_err{"pmi-needs-node", "give one (node N) entry"}),
    Bool.pick(ND, Bool.and(Nat.is_eq(n, 3n),
        Bool.and(is_u64(S.sx_nth(xs, 1n)), is_u64(S.sx_nth(xs, 2n)))),
      ND_ok{Nodes{uval(S.sx_nth(xs, 1n)), uval(S.sx_nth(xs, 2n)), True{}, True{}}},
      ND_err{"pmi-needs-node", "give one (nodes A B) entry"}))
def ek_of(+h: String) -> U64:
  Bool.pick(U64, String.eq(h, "datum"), 1u64, Bool.pick(U64, String.eq(h, "dim"), 2u64,
    Bool.pick(U64, String.eq(h, "tol"), 3u64, Bool.pick(U64, String.eq(h, "state"), 4u64,
      Bool.pick(U64, String.eq(h, "stack"), 5u64, 0u64)))))
def dup_go(+seen: Bool, +nm: String, +xs: List<&2, String>) -> DU:
  match seen:
    case True{}: DU{True{}, xs}
    case False{}: DU{False{}, nm <> xs}
def dup_hit(d: DU) -> Bool:
  DU{+dup, +xs} = d
  dup
def part_dt(+d: Datum, +pt: PT) -> PT:
  PT{+dts, +dms, +tls, +sts, +sks} = pt
  PT{d <> dts, dms, tls, sts, sks}
def part_dm(+d: Dim, +pt: PT) -> PT:
  PT{+dts, +dms, +tls, +sts, +sks} = pt
  PT{dts, d <> dms, tls, sts, sks}
def part_tol(+t: Tol, +pt: PT) -> PT:
  PT{+dts, +dms, +tls, +sts, +sks} = pt
  PT{dts, dms, t <> tls, sts, sks}
def part_st(+st: State, +pt: PT) -> PT:
  PT{+dts, +dms, +tls, +sts, +sks} = pt
  PT{dts, dms, tls, st <> sts, sks}
def part_sk(+st: Stack, +pt: PT) -> PT:
  PT{+dts, +dms, +tls, +sts, +sks} = pt
  PT{dts, dms, tls, sts, st <> sks}
def part_one(+e: ER, +pt: PT) -> PT:
  match e:
    case ER_dt{+d}: part_dt(d, pt)
    case ER_dm{+d}: part_dm(d, pt)
    case ER_tol{+t}: part_tol(t, pt)
    case ER_st{+s}: part_st(s, pt)
    case ER_sk{+s}: part_sk(s, pt)
    case ER_err{+why, +fix}: pt
def part_go(es: List<&2, ER>, +pt: PT) -> PT:
  match es:
    case []: pt
    case h <> t: part_go(t, part_one(h, pt))
def er_tag(+h: ER, +rec: List<&2, TG>) -> List<&2, TG>:
  match h:
    case ER_dt{+d}:
      Datum{+name, +sel} = d
      TG{1u64, name} <> rec
    case ER_dm{+d}:
      Dim{+name, +nom, +lo, +hi} = d
      TG{2u64, name} <> rec
    case ER_tol{+tl}:
      Tol{+name, +kind, +t, +sel, +drf} = tl
      TG{3u64, name} <> rec
    case ER_st{+st}:
      State{+name, +grow} = st
      TG{4u64, name} <> rec
    case ER_sk{+sk}:
      Stack{+name, +dims} = sk
      TG{5u64, name} <> rec
    case ER_err{+why, +fix}: rec
def er_tags(es: List<&2, ER>, +acc: List<&2, TG>) -> List<&2, TG>:
  match es:
    case []: acc
    case h <> t: er_tag(h, er_tags(t, acc))
def tag_mem_go(+h: TG, +rec: Bool, +k: U64, +nm: String) -> Bool:
  TG{+kind, +n} = h
  Bool.or(Bool.and(U64.is_eq(kind, k), String.eq(n, nm)), rec)
def tag_mem(ts: List<&2, TG>, +k: U64, +nm: String) -> Bool:
  match ts:
    case []: False{}
    case h <> t: tag_mem_go(h, tag_mem(t, k, nm), k, nm)
def sc_dup2(+hit: Bool, +why: String, +fix: String, +rec: PR) -> PR:
  match hit:
    case True{}: PR_err{why, fix}
    case False{}: rec
def sc_dup_nd2(+seen: Bool, +rec: PR) -> PR:
  match seen:
    case True{}: PR_err{"duplicate-node", "give one (node N) or (nodes A B) entry"}
    case False{}: rec
def sc_ndh2(+ndh: ND, +rec: PR, +nd: Nodes) -> PR:
  match ndh:
    case ND_err{+why, +fix}: PR_err{why, fix}
    case ND_ok{+n}: sc_dup_nd2(nd_seen(nd), rec)
def sc_er2(+e: ER, +rec: PR, +ers: List<&2, ER>) -> PR:
  match e:
    case ER_err{+why, +fix}: PR_err{why, fix}
    case ER_dt{+d}:
      Datum{+name, +sel} = d
      sc_dup2(dup_hit(dup_go(tag_mem(er_tags(ers, []), 1u64, name), name, [])),
        "duplicate-datum", "datum names are distinct", rec)
    case ER_dm{+d}:
      Dim{+name, +nom, +lo, +hi} = d
      sc_dup2(dup_hit(dup_go(tag_mem(er_tags(ers, []), 2u64, name), name, [])),
        "duplicate-dim", "dim names are distinct", rec)
    case ER_tol{+tl}:
      Tol{+name, +kind, +t, +sel, +drf} = tl
      sc_dup2(dup_hit(dup_go(tag_mem(er_tags(ers, []), 3u64, name), name, [])),
        "duplicate-tol", "tol names are distinct", rec)
    case ER_st{+st}:
      State{+name, +grow} = st
      sc_dup2(dup_hit(dup_go(tag_mem(er_tags(ers, []), 4u64, name), name, [])),
        "duplicate-state", "state names are distinct", rec)
    case ER_sk{+sk}:
      Stack{+name, +dims} = sk
      sc_dup2(dup_hit(dup_go(tag_mem(er_tags(ers, []), 5u64, name), name, [])),
        "duplicate-stack", "stack names are distinct", rec)
def sc_wrap(+isn: Bool, +e: ER, +ndh: ND, +rec: PR, +nd: Nodes, +ers: List<&2, ER>) -> PR:
  match isn:
    case True{}: sc_ndh2(ndh, rec, nd)
    case False{}: sc_er2(e, rec, ers)
def sc_ndh(+ndh: ND, +nd: Nodes) -> Nodes:
  match ndh:
    case ND_err{+why, +fix}: nd
    case ND_ok{+n}: n
def sc_nd_nacc(+isn: Bool, +ndh: ND, +nd: Nodes) -> Nodes:
  match isn:
    case True{}: sc_ndh(ndh, nd)
    case False{}: nd
def sc_ers_nacc(+isn: Bool, +e: ER, +ers: List<&2, ER>) -> List<&2, ER>:
  match isn:
    case True{}: ers
    case False{}:
      match e:
        case ER_err{+why, +fix}: ers
        case _: e <> ers
def is_nd(+x: S.Sx) -> Bool:
  match x:
    case S.Sx_a{s}: False{}
    case S.Sx_l{xs}:
      +h = S.sx_s(S.sx_nth(xs, 0n))
      Bool.or(String.eq(h, "node"), String.eq(h, "nodes"))
def pt_rev(+pt: PT) -> PT:
  PT{+dts, +dms, +tls, +sts, +sks} = pt
  PT{List.reverse(&2, Datum, dts), List.reverse(&2, Dim, dms), List.reverse(&2, Tol, tls),
    List.reverse(&2, State, sts), List.reverse(&2, Stack, sks)}
def scan_fin(+pt: PT, +ers: List<&2, ER>, +nd: Nodes) -> PR:
  PT{+dts, +dms, +tls, +sts, +sks} = pt
  PR_ok{PMI{nd, dts, dms, tls, sts, sks, ers}}
def dt_find(ds: List<&2, Datum>, +nm: String) -> Maybe<&2, Datum>:
  match ds:
    case []: None{}
    case h <> t:
      Datum{+name, +sel} = h
      Bool.pick(Maybe<&2, Datum>, String.eq(name, nm), Some{h}, dt_find(t, nm))
def dm_find(ds: List<&2, Dim>, +nm: String) -> Maybe<&2, Dim>:
  match ds:
    case []: None{}
    case h <> t:
      Dim{+name, +nom, +lo, +hi} = h
      Bool.pick(Maybe<&2, Dim>, String.eq(name, nm), Some{h}, dm_find(t, nm))
def gplane(s: G.GVal) -> MP:
  match s:
    case G.GV_pl{w}: MP_yes{w}
    case _: MP_no{}
def face_plane(+bt: BT, +i: Nat) -> MP:
  BT{+fns, +fas, +vs, +es, +ces, +lps} = bt
  gplane(Ty.fa_surf(fa_at(fas, i)))
def ce_pts(+bt: BT, +i: Nat) -> List<&2, V.Point>:
  BT{+fns, +fas, +vs, +es, +ces, +lps} = bt
  +ce = B.tb_get(Ty.Coedge, ces, U32.from_nat(i))
  +e = B.tb_get(Ty.Edge, es, U32.from_nat(Ty.he_idx(Ty.ce_edge(ce))))
  +v0 = B.tb_get(Ty.Vertex, vs, U32.from_nat(Ty.hv_idx(Ty.ed_v0(e))))
  +v1 = B.tb_get(Ty.Vertex, vs, U32.from_nat(Ty.hv_idx(Ty.ed_v1(e))))
  [Ty.vx_p(v0), Ty.vx_p(v1)]
def lp_pts_go(hs: List<&2, Ty.HCoedge>, +bt: BT, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match hs:
    case []: acc
    case h <> t:
      Ty.HC{+idx, +gen} = h
      lp_pts_go(t, bt, List.append(&2, V.Point, ce_pts(bt, idx), acc))
def lp_pts(+bt: BT, +h: Ty.HLoop) -> List<&2, V.Point>:
  BT{+fns, +fas, +vs, +es, +ces, +lps} = bt
  +lp = B.tb_get(Ty.Loop, lps, U32.from_nat(Ty.hlp_idx(h)))
  lp_pts_go(Ty.lp_ces(lp), bt, [])
def face_pts_go(ls: List<&2, Ty.HLoop>, +bt: BT, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match ls:
    case []: acc
    case h <> t: face_pts_go(t, bt, List.append(&2, V.Point, lp_pts(bt, h), acc))
def face_pts(+bt: BT, +i: Nat) -> List<&2, V.Point>:
  BT{+fns, +fas, +vs, +es, +ces, +lps} = bt
  face_pts_go(Ty.fa_loops(fa_at(fas, i)), bt, [])
def mm_go(ps: List<&2, V.Point>, +ax: F64, +bx: F64, +ay: F64, +by: F64, +az: F64,
    +bz: F64) -> List<&2, F64>:
  match ps:
    case []: [ax, bx, ay, by, az, bz]
    case +p <> t:
      mm_go(t, F64.min(ax, V.pt_x(p)), F64.max(bx, V.pt_x(p)), F64.min(ay, V.pt_y(p)),
        F64.max(by, V.pt_y(p)), F64.min(az, V.pt_z(p)), F64.max(bz, V.pt_z(p)))
def mm_ext(+m: List<&2, F64>) -> I.I:
  +ax = M.f_nth(m, 0n)
  +bx = M.f_nth(m, 1n)
  +ay = M.f_nth(m, 2n)
  +by = M.f_nth(m, 3n)
  +az = M.f_nth(m, 4n)
  +bz = M.f_nth(m, 5n)
  I.isqrt(I.iadd(I.isq(I.isub(I.ipt(bx), I.ipt(ax))),
    I.iadd(I.isq(I.isub(I.ipt(by), I.ipt(ay))), I.isq(I.isub(I.ipt(bz), I.ipt(az))))))
def face_ext_go(ps: List<&2, V.Point>) -> OE:
  match ps:
    case []: OE_bad{"tol-degenerate-face", "the toleranced face has no vertices"}
    case +p <> t:
      +e = mm_ext(mm_go(p <> t, V.pt_x(p), V.pt_x(p), V.pt_y(p), V.pt_y(p),
        V.pt_z(p), V.pt_z(p)))
      OE_ok{I.i_lo(e), I.i_hi(e)}
def face_ext(+bt: BT, +i: Nat) -> OE:
  face_ext_go(face_pts(bt, i))
def iabs(+a: I.I) -> I.I:
  +l = I.i_lo(a)
  +h = I.i_hi(a)
  Bool.pick(I.I, F64.is_le(0.0f64, l), a,
    Bool.pick(I.I, F64.is_le(h, 0.0f64), I.I{F64.neg(h), F64.neg(l)},
      I.I{0.0f64, F64.max(F64.abs(l), F64.abs(h))}))
def irot(+m: V.Mat3, +x: I.I, +y: I.I, +z: I.I) -> List<&2, I.I>:
  V.M3{+a0, +a1, +a2, +a3, +a4, +a5, +a6, +a7, +a8} = m
  [I.iadd(I.imul(I.ipt(a0), x), I.iadd(I.imul(I.ipt(a1), y), I.imul(I.ipt(a2), z))),
    I.iadd(I.imul(I.ipt(a3), x), I.iadd(I.imul(I.ipt(a4), y), I.imul(I.ipt(a5), z))),
    I.iadd(I.imul(I.ipt(a6), x), I.iadd(I.imul(I.ipt(a7), y), I.imul(I.ipt(a8), z)))]
def wnorm_go(+ok: Bool, +pl: M.Pl, +cx: I.I, +cy: I.I, +cz: I.I, +n2: I.I) -> WN:
  match ok:
    case False{}: WN{False{}, I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(0.0f64)}
    case True{}:
      +n = I.isqrt(n2)
      +w = irot(M.pl_m(pl), I.idiv(cx, n), I.idiv(cy, n), I.idiv(cz, n))
      WN{True{}, M.i_nth(w, 0n), M.i_nth(w, 1n), M.i_nth(w, 2n)}
def wnorm(+pl: M.Pl, +p: G.Plane3) -> WN:
  +u = G.pl_u(p)
  +v = G.pl_v(p)
  +cx = I.isub(I.imul(I.ipt(V.dr_y(u)), I.ipt(V.dr_z(v))), I.imul(I.ipt(V.dr_z(u)), I.ipt(V.dr_y(v))))
  +cy = I.isub(I.imul(I.ipt(V.dr_z(u)), I.ipt(V.dr_x(v))), I.imul(I.ipt(V.dr_x(u)), I.ipt(V.dr_z(v))))
  +cz = I.isub(I.imul(I.ipt(V.dr_x(u)), I.ipt(V.dr_y(v))), I.imul(I.ipt(V.dr_y(u)), I.ipt(V.dr_x(v))))
  +n2 = I.iadd(I.isq(cx), I.iadd(I.isq(cy), I.isq(cz)))
  wnorm_go(F64.is_lt(0.0f64, I.i_lo(n2)), pl, cx, cy, cz, n2)
def orient_dev(+kind: U64, +dot: I.I) -> I.I:
  Bool.pick(I.I, U64.is_eq(kind, 2u64), iabs(dot),
    I.isqrt(I.isub(I.ipt(1.0f64), I.imul(dot, dot))))
def orient_ext(+e: OE, +kind: U64, +dot: I.I) -> OE:
  match e:
    case OE_bad{+why, +fix}: OE_bad{why, fix}
    case OE_ok{+lo, +hi}:
      +a = I.imul(I.I{lo, hi}, orient_dev(kind, dot))
      OE_ok{I.i_lo(a), I.i_hi(a)}
def orient_go(+wi: WN, +wj: WN, +e: OE, +kind: U64) -> OE:
  WN{+oki, +xi, +yi, +zi} = wi
  WN{+okj, +xj, +yj, +zj} = wj
  Bool.pick(OE, Bool.and(oki, okj), orient_ext(e, kind,
      I.iadd(I.imul(xi, xj), I.iadd(I.imul(yi, yj), I.imul(zi, zj)))),
    OE_bad{"tol-degenerate-face", "a toleranced plane has a zero normal"})
def orient_pj(+mj: MP, +bt: BT, +pl: M.Pl, +i: Nat, +pa: G.Plane3, +kind: U64) -> OE:
  match mj:
    case MP_no{}: OE_bad{"tol-datum-not-plane", "orientation datums bind plane faces"}
    case MP_yes{+pb}:
      orient_go(wnorm(pl, pa), wnorm(pl, pb), face_ext(bt, i), kind)
def orient_pi(+mi: MP, +bt: BT, +pl: M.Pl, +i: Nat, +j: Nat, +kind: U64) -> OE:
  match mi:
    case MP_no{}: OE_bad{"tol-face-not-plane", "flatness, perpendicularity and parallelism apply to plane faces"}
    case MP_yes{+pa}: orient_pj(face_plane(bt, j), bt, pl, i, pa, kind)
def orient_all(+bt: BT, +pl: M.Pl, +i: Nat, +j: Nat, +kind: U64) -> OE:
  orient_pi(face_plane(bt, i), bt, pl, i, j, kind)
def voe(+lo: F64, +hi: F64, +t: F64) -> U64:
  Bool.pick(U64, F64.is_le(hi, t), 0u64,
    Bool.pick(U64, F64.is_lt(t, lo), 1u64, 2u64))
def voe_s(+v: U64) -> String:
  match v:
    case 0u64: "conforms"
    case 1u64: "violates"
    case _: "uncertain"
def voe_c(+v: U64) -> String:
  Bool.pick(String, U64.is_eq(v, 2u64), "estimated", "certified")
def drf_head(ds: List<&2, String>) -> String:
  match ds:
    case []: ""
    case h <> t: h
def sel_mem_of(+bt: BT, +s: String) -> Bool:
  BT{+fns, +fas, +vs, +es, +ces, +lps} = bt
  sel_mem(fns, s)
def tol_oe(+e: OE, +u: Tol, +dnm: String) -> RV:
  match e:
    case OE_bad{+why, +fix}: RV_bad{why, fix}
    case OE_ok{+lo, +hi}:
      Tol{+name, +kind, +t, +sel, +drf} = u
      +v = voe(lo, hi, t)
      RV_ok{"tol " ++ name ++ " " ++ kind_s(kind) ++ " " ++ voe_s(v) ++ " actual [" ++
        S.f_show(lo) ++ ", " ++ S.f_show(hi) ++ "] " ++ voe_c(v) ++ " datum " ++ dnm ++ "\n"}
def tol_orient_d(+d: Datum, +u: Tol, +bt: BT, +pl: M.Pl, +ts: String, +kind: U64) -> RV:
  Datum{+name, +sel} = d
  BT{+fns, +fas, +vs, +es, +ces, +lps} = bt
  tol_oe(orient_all(bt, pl, sel_idx(fns, ts), sel_idx(fns, sel), kind), u, name)
def tol_orient(+u: Tol, +bt: BT, +pl: M.Pl, +d: Datum) -> RV:
  Tol{+name, +kind, +t, +sel, +drf} = u
  tol_orient_d(d, u, bt, pl, sel, kind)
def tol_datum_sel(+ok: Bool, +u: Tol, +bt: BT, +pl: M.Pl, +d: Datum) -> RV:
  match ok:
    case False{}:
      Datum{+name, +sel} = d
      RV_bad{"unknown-selector " ++ sel, "select a face from the faces verb"}
    case True{}: tol_orient(u, bt, pl, d)
def tol_datum(+m: Maybe<&2, Datum>, +u: Tol, +bt: BT, +pl: M.Pl, +dnm: String) -> RV:
  match m:
    case None{}: RV_bad{"unknown-datum " ++ dnm, "name a datum from the pmi set"}
    case Some{+d}:
      Datum{+name, +sel} = d
      tol_datum_sel(sel_mem_of(bt, sel), u, bt, pl, d)
def tol_flat_go(+ispl: Bool, +u: Tol) -> RV:
  match ispl:
    case False{}: RV_bad{"tol-face-not-plane", "flatness, perpendicularity and parallelism apply to plane faces"}
    case True{}:
      Tol{+name, +kind, +t, +sel, +drf} = u
      RV_ok{"tol " ++ name ++ " flatness conforms actual 0 certified\n"}
def tol_flat(+u: Tol, +bt: BT) -> RV:
  Tol{+name, +kind, +t, +sel, +drf} = u
  Bool.pick(RV, Nat.is_eq(List.length(&2, String, drf), 0n),
    tol_flat_go(U64.is_eq(sel_kind(bt, sel), 0u64), u),
    RV_bad{"tol-kind-takes-no-datum", "flatness takes no datum references"})
def tol_drf_n(+one: Bool, +u: Tol, +dts: List<&2, Datum>, +bt: BT, +pl: M.Pl) -> RV:
  match one:
    case False{}: RV_bad{"tol-needs-one-datum", "orientation takes exactly one datum"}
    case True{}:
      Tol{+name, +kind, +t, +sel, +drf} = u
      tol_datum(dt_find(dts, drf_head(drf)), u, bt, pl, drf_head(drf))
def tol_drf(+u: Tol, +dts: List<&2, Datum>, +bt: BT, +pl: M.Pl) -> RV:
  Tol{+name, +kind, +t, +sel, +drf} = u
  Bool.pick(RV, U64.is_eq(kind, 1u64), tol_flat(u, bt),
    tol_drf_n(Nat.is_eq(List.length(&2, String, drf), 1n), u, dts, bt, pl))
def tol_sel(+ok: Bool, +u: Tol, +dts: List<&2, Datum>, +bt: BT, +pl: M.Pl) -> RV:
  match ok:
    case False{}:
      Tol{+name, +kind, +t, +sel, +drf} = u
      RV_bad{"unknown-selector " ++ sel, "select a face from the faces verb"}
    case True{}: tol_drf(u, dts, bt, pl)
def tol_res(+u: Tol, +dts: List<&2, Datum>, +bt: BT, +pl: M.Pl) -> RV:
  Tol{+name, +kind, +t, +sel, +drf} = u
  tol_sel(sel_mem_of(bt, sel), u, dts, bt, pl)
def sk_bad_m(+m: Maybe<&2, Dim>, +h: String, +rec: Maybe<&2, String>) -> Maybe<&2, String>:
  match m:
    case None{}: Some{h}
    case Some{d}: rec
def sk_bad(ds: List<&2, String>, +dms: List<&2, Dim>) -> Maybe<&2, String>:
  match ds:
    case []: None{}
    case +h <> t: sk_bad_m(dm_find(dms, h), h, sk_bad(t, dms))
def sk_res(+m: Maybe<&2, String>, +s: Stack) -> RV:
  match m:
    case Some{+nm}: RV_bad{"unknown-dim " ++ nm, "name a dim from the pmi set"}
    case None{}:
      Stack{+name, +dims} = s
      RV_ok{"stack " ++ name ++ " dims " ++ Nat.show(List.length(&2, String, dims)) ++ "\n"}
def Stack_dims(+s: Stack) -> List<&2, String>:
  Stack{+name, +dims} = s
  dims
def res_dt(+ok: Bool, +d: Datum, +bt: BT) -> RV:
  match ok:
    case False{}:
      Datum{+name, +sel} = d
      RV_bad{"unknown-selector " ++ sel, "select a face from the faces verb"}
    case True{}:
      Datum{+name, +sel} = d
      RV_ok{"datum " ++ name ++ " ok " ++ sel ++ " " ++ psurf_s(sel_kind(bt, sel)) ++ "\n"}
def res_one(+e: ER, +dts: List<&2, Datum>, +dms: List<&2, Dim>, +bt: BT, +pl: M.Pl) -> RV:
  match e:
    case ER_dt{+d}:
      Datum{+name, +sel} = d
      res_dt(sel_mem_of(bt, sel), d, bt)
    case ER_dm{+d}:
      Dim{+name, +nom, +lo, +hi} = d
      RV_ok{"dim " ++ name ++ " nominal " ++ S.f_show(nom) ++ " zone [" ++ S.f_show(lo) ++
        ", " ++ S.f_show(hi) ++ "]\n"}
    case ER_tol{+t}: tol_res(t, dts, bt, pl)
    case ER_st{+s}:
      State{+name, +grow} = s
      RV_ok{"state " ++ name ++ " grow " ++ S.f_show(grow) ++ "\n"}
    case ER_sk{+s}: sk_res(sk_bad(Stack_dims(s), dms), s)
    case ER_err{+why, +fix}: RV_bad{why, fix}
def res_all(es: List<&2, ER>, +dts: List<&2, Datum>, +dms: List<&2, Dim>, +bt: BT,
    +pl: M.Pl) -> List<&2, RV>:
  match es:
    case []: []
    case h <> t: res_one(h, dts, dms, bt, pl) <> res_all(t, dts, dms, bt, pl)
def fb_head(+r: RV, +rec: FB) -> FB:
  match r:
    case RV_bad{+why, +fix}: FB_bad{why, fix}
    case RV_ok{+line}: rec
def fb(rs: List<&2, RV>) -> FB:
  match rs:
    case []: FB_ok{}
    case h <> t: fb_head(h, fb(t))
def join_one(+h: RV, +rec: String) -> String:
  match h:
    case RV_ok{+line}: line ++ rec
    case RV_bad{+why, +fix}: rec
def join_go(rs: List<&2, RV>) -> String:
  match rs:
    case []: ""
    case h <> t: join_one(h, join_go(t))
def check_fb(+f: FB, +rvs: List<&2, RV>, +hdr: String) -> String:
  match f:
    case FB_bad{+why, +fix}: "error invalid-input | pmi check | why: " ++ why ++ " | fix: " ++ fix
    case FB_ok{}: hdr ++ join_go(rvs) ++ "pmi ok " ++ Nat.show(List.length(&2, RV, rvs)) ++ " items\n"
def check_rep(+rvs: List<&2, RV>, +hdr: String) -> String:
  check_fb(fb(rvs), rvs, hdr)
def states_or_dflt(ss: List<&2, State>) -> List<&2, State>:
  match ss:
    case []: [State{"nominal", 1.0f64}]
    case h <> t: h <> t
def sk_dims_go(+m: Maybe<&2, Dim>, +rec: List<&2, Dim>) -> List<&2, Dim>:
  match m:
    case None{}: rec
    case Some{+d}: d <> rec
def sk_dims(ds: List<&2, String>, +dms: List<&2, Dim>) -> List<&2, Dim>:
  match ds:
    case []: []
    case h <> t: sk_dims_go(dm_find(dms, h), sk_dims(t, dms))
def stk_sum(ds: List<&2, Dim>, +n: F64, +e: I.I) -> SR:
  match ds:
    case []: SR{State{"", 1.0f64}, n, I.i_lo(e), I.i_hi(e)}
    case h <> t:
      Dim{+name, +nom, +lo, +hi} = h
      stk_sum(t, F64.add(n, nom), I.iadd(e, I.I{lo, hi}))
def stk_dim(ds: List<&2, String>, +dms: List<&2, Dim>, +n: F64, +e: I.I) -> SR:
  stk_sum(sk_dims(ds, dms), n, e)
def stk_row(+b: SR, +s: State) -> SR:
  SR{+st, +nom, +lo, +hi} = b
  State{+name, +grow} = s
  +e = I.iscale(I.I{lo, hi}, grow)
  SR{s, F64.mul(nom, grow), I.i_lo(e), I.i_hi(e)}
def stk_rows(+b: SR, ts: List<&2, State>) -> List<&2, SR>:
  match ts:
    case []: []
    case h <> t: stk_row(b, h) <> stk_rows(b, t)
def sr_rep(+r: SR) -> String:
  SR{+st, +nom, +lo, +hi} = r
  State{+name, +grow} = st
  "state " ++ name ++ " grow " ++ S.f_show(grow) ++ " [" ++ S.f_show(lo) ++ ", " ++
    S.f_show(hi) ++ "]\n"
def srs_rep(rs: List<&2, SR>) -> String:
  match rs:
    case []: ""
    case h <> t: sr_rep(h) ++ srs_rep(t)
def stk_rep_b(+b: SR, +name: String, +ts: List<&2, State>) -> String:
  SR{+st, +nom, +lo, +hi} = b
  "stack " ++ name ++ " nominal " ++ S.f_show(nom) ++ " envelope [" ++ S.f_show(lo) ++
    ", " ++ S.f_show(hi) ++ "] certified\n" ++ srs_rep(stk_rows(b, ts))
def stk_rep(+s: Stack, +dms: List<&2, Dim>, +ts: List<&2, State>) -> String:
  Stack{+name, +dims} = s
  stk_rep_b(stk_dim(dims, dms, 0.0f64, I.I{0.0f64, 0.0f64}), name, ts)
def stks_rep(ss: List<&2, Stack>, +dms: List<&2, Dim>, +ts: List<&2, State>) -> String:
  match ss:
    case []: ""
    case h <> t: stk_rep(h, dms, ts) ++ stks_rep(t, dms, ts)
def clr_iv(+a: M.Body, +b: M.Body) -> CI:
  +sa = QI.sms_of(a)
  +sb = QI.sms_of(b)
  CI{QI.rel_interf(a, b), QA.ab_ab_lo(QI.wbox(a), QI.wbox(b)),
    QD.pts_min(sa, sb, V.dbl_max()), List.length(&2, V.Point, sa),
    List.length(&2, V.Point, sb)}
def clr_hit(+hit: Bool, +lo: F64, +hi: F64, +na: Nat, +nb: Nat, +s: State) -> String:
  match hit:
    case True{}:
      State{+name, +grow} = s
      "state " ++ name ++ " grow " ++ S.f_show(grow) ++ " clearance 0 status=certified state=interference\n"
    case False{}:
      State{+name, +grow} = s
      +e = I.iscale(I.I{lo, hi}, grow)
      "state " ++ name ++ " grow " ++ S.f_show(grow) ++ " clearance [" ++
        S.f_show(I.i_lo(e)) ++ ", " ++ S.f_show(I.i_hi(e)) ++ "] estimated lo=certified samples=" ++
        Nat.show(na) ++ "x" ++ Nat.show(nb) ++ "\n"
def clr_st(+c: CI, +s: State) -> String:
  CI{+hit, +lo, +hi, +na, +nb} = c
  clr_hit(hit, lo, hi, na, nb, s)
def clr_rows(+c: CI, ts: List<&2, State>) -> List<&2, String>:
  match ts:
    case []: []
    case h <> t: clr_st(c, h) <> clr_rows(c, t)
def str_join(rs: List<&2, String>) -> String:
  match rs:
    case []: ""
    case h <> t: h ++ str_join(t)
def pwidth(+ps: List<&2, M.Param>, +acc: F64) -> F64:
  match ps:
    case []: acc
    case p <> t:
      M.Pm{+id, +n, +d} = p
      M.Dm{+nom, +lo, +hi} = d
      pwidth(t, F64.add(acc, F64.sub(hi, lo)))
def pmi_w(+p: M.Part) -> F64:
  M.Pt{+ps, +ns} = p
  pwidth(ps, 0.0f64)
def env_rep_s(+a: String, +b: String, +c: String) -> String:
  "envelope clearance [" ++ a ++ ", " ++ b ++ "] estimated widen=" ++ c ++ "\n"
def env_rep(+lo: F64, +hi: F64, +w: F64) -> String:
  env_rep_s(S.f_show(F64.sub(lo, w)), S.f_show(F64.add(hi, w)), S.f_show(w))
def chs_go(s: String, +acc: List<&2, Char>) -> List<&2, Char>:
  match s:
    case SNil{}: List.reverse(&2, Char, acc)
    case SCon{h, t}: chs_go(t, h <> acc)
def chs_of(+s: String) -> List<&2, Char>:
  chs_go(s, [])
def ch_at(xs: List<&2, Char>, +i: Nat) -> U32:
  match xs:
    case []: U32.from_nat(0n)
    case h <> t:
      match i:
        case 0n: S.chr_code(h)
        case 1n+j: ch_at(t, j)
def rw_ix(+rs: List<&2, Char>, +ps: List<&2, Char>, +k: Nat, +i: Nat, +lr: Nat) -> Bool:
  match k:
    case 0n: True{}
    case 1n+j:
      Bool.pick(Bool, Nat.is_lt(i, lr),
        Bool.and(U32.is_eq(ch_at(rs, i), ch_at(ps, i)), rw_ix(rs, ps, j, Nat.add(i, 1n), lr)),
        False{})
def rw_pre(+r: String, +pre: String) -> Bool:
  rw_ix(chs_of(r), chs_of(pre), List.length(&2, Char, chs_of(pre)), 0n,
    List.length(&2, Char, chs_of(r)))
def rw_of(+r: String) -> String:
  Bool.pick(String, rw_pre(r, "relation disjoint"), "disjoint",
    Bool.pick(String, rw_pre(r, "relation inside"), "inside",
      Bool.pick(String, rw_pre(r, "relation interference"), "interference",
        Bool.pick(String, rw_pre(r, "relation uncertain"), "uncertain", "unknown"))))
def env_rel(+w: F64, +rel: String) -> String:
  "envelope relation " ++ rw_of(rel) ++ " status=estimated widen=" ++ S.f_show(w) ++ "\n"
def nd_go(+has: Bool, +ok: Bool, +id: U64, +hdr: String, +tail: String) -> String:
  match has:
    case False{}: hdr ++ "unknown-node " ++ U64.show(id) ++
      " | fix: name a node from the design (eval)"
    case True{}: Bool.pick(String, ok, "",
      "error: node " ++ U64.show(id) ++ tail)
def nd_line(+cs: List<&2, M.CE>, +id: U64, +hdr: String, +tail: String) -> String:
  nd_go(M.ce_has(cs, id), M.nr_ok(M.ce_r(M.ce_find(cs, id))), id, hdr, tail)
def nd_body(+cs: List<&2, M.CE>, +id: U64) -> M.Body:
  M.nr_body(M.ce_r(M.ce_find(cs, id)))
def q_check_e_go(+c: Bool, +e: String, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>, +id: U64) -> String:
  match c:
    case False{}: e
    case True{}:
      PMI{+nd, +dts, +dms, +tls, +sts, +sks, +ers} = m
      +b = nd_body(cs, id)
      +bt = bt_of(b)
      check_rep(res_all(ers, dts, dms, bt, M.bd_pl(b)),
        "pmi node " ++ U64.show(id) ++ " items " ++ Nat.show(List.length(&2, ER, ers)) ++ "\n")
def q_check_e(+e: String, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>, +id: U64) -> String:
  q_check_e_go(String.eq(e, ""), e, m, p, cs, id)
def q_check_pr(+pair: Bool, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>) -> String:
  match pair:
    case True{}: "error invalid-input | pmi check | why: pmi-needs-node | fix: give one (node N) entry"
    case False{}: q_check_e(nd_line(cs, nd_a(m_nodes(m)), "error invalid-input | pmi check | why: ",
      "; nothing evaluated"), m, p, cs, nd_a(m_nodes(m)))
def q_check_nd(+seen: Bool, +pair: Bool, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>) -> String:
  match seen:
    case False{}: "error invalid-input | pmi check | why: pmi-needs-node | fix: give one (node N) entry"
    case True{}: q_check_pr(pair, m, p, cs)
def q_check(+p: M.Part, +pr: PR) -> String:
  match pr:
    case PR_err{+why, +fix}: "error invalid-input | pmi check | why: " ++ why ++ " | fix: " ++ fix
    case PR_ok{+m}: q_check_nd(nd_seen(m_nodes(m)), nd_pair(m_nodes(m)), m, p, M.ev_part(p, []))
def stk_rep_all(+id: U64, +ss: List<&2, Stack>, +dms: List<&2, Dim>, +ts: List<&2, State>) -> String:
  "pmi node " ++ U64.show(id) ++ " stacks " ++ Nat.show(List.length(&2, Stack, ss)) ++
    " states " ++ Nat.show(List.length(&2, State, ts)) ++ "\n" ++ stks_rep(ss, dms, ts)
def stk_fb(+f: FB, +m: PMI) -> String:
  match f:
    case FB_bad{+why, +fix}: "error invalid-input | pmi stack | why: " ++ why ++ " | fix: " ++ fix
    case FB_ok{}:
      PMI{+nd, +dts, +dms, +tls, +sts, +sks, +ers} = m
      stk_rep_all(nd_a(m_nodes(m)), sks, dms, states_or_dflt(sts))
def q_stack_e_go(+c: Bool, +e: String, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>, +id: U64) -> String:
  match c:
    case False{}: e
    case True{}:
      PMI{+nd, +dts, +dms, +tls, +sts, +sks, +ers} = m
      +b = nd_body(cs, id)
      stk_fb(fb(res_all(ers, dts, dms, bt_of(b), M.bd_pl(b))), m)
def q_stack_e(+e: String, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>, +id: U64) -> String:
  q_stack_e_go(String.eq(e, ""), e, m, p, cs, id)
def q_stack_pr(+pair: Bool, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>) -> String:
  match pair:
    case True{}: "error invalid-input | pmi stack | why: pmi-needs-node | fix: give one (node N) entry"
    case False{}: q_stack_e(nd_line(cs, nd_a(m_nodes(m)), "error invalid-input | pmi stack | why: ",
      "; nothing evaluated"), m, p, cs, nd_a(m_nodes(m)))
def q_stack_nd(+seen: Bool, +pair: Bool, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>) -> String:
  match seen:
    case False{}: "error invalid-input | pmi stack | why: pmi-needs-node | fix: give one (node N) entry"
    case True{}: q_stack_pr(pair, m, p, cs)
def q_stack(+p: M.Part, +pr: PR) -> String:
  match pr:
    case PR_err{+why, +fix}: "error invalid-input | pmi stack | why: " ++ why ++ " | fix: " ++ fix
    case PR_ok{+m}: q_stack_nd(nd_seen(m_nodes(m)), nd_pair(m_nodes(m)), m, p, M.ev_part(p, []))
def rel_st(+s: State, +rel: String) -> String:
  State{+name, +grow} = s
  "state " ++ name ++ " grow " ++ S.f_show(grow) ++ " relation " ++ rel ++ "\n"
def rel_rows(ts: List<&2, State>, +rel: String) -> List<&2, String>:
  match ts:
    case []: []
    case h <> t: rel_st(h, rel) <> rel_rows(t, rel)
def zip_go(rs: List<&2, String>, +cs: List<&2, String>) -> String:
  match rs:
    case []: ""
    case h <> t:
      match cs:
        case []: h
        case +ch <> ct: h ++ ch ++ zip_go(t, ct)
def rels_rep(+ts: List<&2, State>, +rel: String, +c: CI) -> String:
  zip_go(rel_rows(ts, rel), clr_rows(c, ts))
def tol_rep(+c: CI, +rel: String, +rels: String, +ts: List<&2, State>, +p: M.Part, +ida: U64,
    +idb: U64) -> String:
  CI{+hit, +lo, +hi, +na, +nb} = c
  "toler nodes " ++ U64.show(ida) ++ " " ++ U64.show(idb) ++ " states " ++
    Nat.show(List.length(&2, State, ts)) ++ "\nnominal relation:\n" ++ rels ++
    "\n" ++ rels_rep(ts, rel, c) ++ env_rep(lo, hi, pmi_w(p)) ++ env_rel(pmi_w(p), rel)
def tol_fb(+f: FB, +m: PMI, +p: M.Part, +a: M.Body, +b: M.Body, +ra: M.NR, +rb: M.NR,
    +ida: U64, +idb: U64) -> String:
  match f:
    case FB_bad{+why, +fix}: "error invalid-input | pmi toler | why: " ++ why ++ " | fix: " ++ fix
    case FB_ok{}:
      PMI{+nd, +dts, +dms, +tls, +sts, +sks, +ers} = m
      tol_rep(clr_iv(a, b), QI.rel_pair(a, b), QI.rel_s(ra, rb), states_or_dflt(sts), p, ida, idb)
def tol_nds_go(+e: Bool, +ea: String, +eb: String) -> String:
  match e:
    case False{}: ea
    case True{}: eb
def tol_nds(+ea: String, +eb: String) -> String:
  tol_nds_go(String.eq(ea, ""), ea, eb)
def q_toler_e_go(+c: Bool, +e: String, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>, +ida: U64,
    +idb: U64) -> String:
  match c:
    case False{}: e
    case True{}:
      PMI{+nd, +dts, +dms, +tls, +sts, +sks, +ers} = m
      +ba = nd_body(cs, ida)
      tol_fb(fb(res_all(ers, dts, dms, bt_of(ba), M.bd_pl(ba))), m, p, ba, nd_body(cs, idb),
        M.ce_r(M.ce_find(cs, ida)), M.ce_r(M.ce_find(cs, idb)), ida, idb)
def q_toler_e(+e: String, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>, +ida: U64,
    +idb: U64) -> String:
  q_toler_e_go(String.eq(e, ""), e, m, p, cs, ida, idb)
def q_toler_pr(+pair: Bool, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>) -> String:
  match pair:
    case False{}: "error invalid-input | pmi toler | why: pmi-needs-node | fix: give one (nodes A B) entry"
    case True{}: q_toler_e(tol_nds(nd_line(cs, nd_a(m_nodes(m)), "error invalid-input | pmi toler | why: ",
        "; nothing compared"), nd_line(cs, nd_b(m_nodes(m)), "error invalid-input | pmi toler | why: ",
        "; nothing compared")), m, p, cs, nd_a(m_nodes(m)), nd_b(m_nodes(m)))
def q_toler_nd(+seen: Bool, +pair: Bool, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>) -> String:
  match seen:
    case False{}: "error invalid-input | pmi toler | why: pmi-needs-node | fix: give one (nodes A B) entry"
    case True{}: q_toler_pr(pair, m, p, cs)
def q_toler(+p: M.Part, +pr: PR) -> String:
  match pr:
    case PR_err{+why, +fix}: "error invalid-input | pmi toler | why: " ++ why ++ " | fix: " ++ fix
    case PR_ok{+m}: q_toler_nd(nd_seen(m_nodes(m)), nd_pair(m_nodes(m)), m, p, M.ev_part(p, []))
def pmi_file_ws_go(+ok: Bool, +w: SW.WS, +n: Nat) -> FR:
  match ok:
    case False{}: FR_err{SW.ws_why(w), "export a node inside the STEP profile"}
    case True{}: FR_ok{SW.ws_s(w), n}
def pmi_file_ws(+w: SW.WS, +n: Nat) -> FR:
  pmi_file_ws_go(SW.ws_ok(w), w, n)
def pmi_file_ok(+ok: Bool, +em: EM, +r: SW.ER2) -> FR:
  match ok:
    case False{}:
      EM{+o, +why, +s, +next, +n, +dm} = em
      FR_err{why, "use exactly representable numbers in dims and tols"}
    case True{}:
      EM{+o, +w, +s, +next, +n, +dm} = em
      pmi_file_ws(SW.sw_wrap42(r, 1n, s, n), n)
def pmi_file_em(+em: EM, +r: SW.ER2) -> FR:
  EM{+ok, +why, +s, +next, +n, +dm} = em
  pmi_file_ok(ok, em, r)
def verb_code(+v: String) -> U64:
  Bool.pick(U64, String.eq(v, "check"), 1u64, Bool.pick(U64, String.eq(v, "stack"), 2u64,
    Bool.pick(U64, String.eq(v, "toler"), 3u64, Bool.pick(U64, String.eq(v, "step42"), 4u64, 0u64))))
def nm_go(s: String) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{h, t}:
      +c = S.chr_code(h)
      Bool.or(Bool.or(U32.is_eq(c, 39), U32.is_eq(c, 92)), nm_go(t))
def nm_bad(+s: String) -> Bool:
  nm_go(s)
def datum_of(+x: S.Sx) -> ER:
  +xs = S.sx_xs(x)
  +nm = S.sx_s(S.sx_nth(xs, 1n))
  +sel = S.sx_s(S.sx_nth(xs, 2n))
  +ok = Bool.and(Nat.is_eq(List.length(&2, S.Sx, xs), 3n),
    Bool.and(Bool.not(String.eq(nm, "")), Bool.and(Bool.not(String.eq(sel, "")), Bool.not(nm_bad(nm)))))
  Bool.pick(ER, ok, ER_dt{Datum{nm, sel}},
    ER_err{"bad-datum", "write (datum NAME SEL) with a face selector from the faces verb"})
def dim_exp_ok(+nm: String, +xs: List<&2, S.Sx>) -> Bool:
  +nom = fnum(S.sx_nth(xs, 2n))
  +lo = fnum(S.sx_nth(xs, 3n))
  +hi = fnum(S.sx_nth(xs, 4n))
  Bool.and(Bool.and(Bool.not(String.eq(nm, "")), Bool.not(nm_bad(nm))), Bool.and(T.is_finite(nom),
    Bool.and(T.is_finite(lo), Bool.and(T.is_finite(hi),
      Bool.and(F64.is_le(lo, nom), F64.is_le(nom, hi))))))
def dim_of(+x: S.Sx, +p: M.Part) -> ER:
  +xs = S.sx_xs(x)
  +n = List.length(&2, S.Sx, xs)
  +nm = S.sx_s(S.sx_nth(xs, 1n))
  +pnm = S.sx_s(S.sx_nth(xs, 2n))
  Bool.pick(ER, Nat.is_eq(n, 3n),
    Bool.pick(ER, Bool.or(String.eq(nm, ""), nm_bad(nm)), dim_exp(False{}, nm, 0.0f64, 0.0f64, 0.0f64),
      dim_par_m(pm_dim_of(p, pnm), nm, pnm)),
    Bool.pick(ER, Nat.is_eq(n, 5n),
      dim_exp(dim_exp_ok(nm, xs), nm, fnum(S.sx_nth(xs, 2n)), fnum(S.sx_nth(xs, 3n)),
        fnum(S.sx_nth(xs, 4n))),
      dim_exp(False{}, nm, 0.0f64, 0.0f64, 0.0f64)))
def tol_t_ok(+nm: String, +t: F64, +sel: String, +mo: String) -> U64:
  Bool.pick(U64, Bool.or(String.eq(nm, ""), nm_bad(nm)), 1u64,
    Bool.pick(U64, Bool.not(Bool.and(T.is_finite(t), F64.is_le(0.0f64, t))), 1u64,
      Bool.pick(U64, String.eq(sel, ""), 1u64,
        Bool.pick(U64, Bool.not(String.eq(mo, "rfs")), 2u64, 0u64))))
def tol_gate_k(+badk: Bool, +nm: String, +k: String, +t: F64, +sel: String, +mo: String,
    +rest: List<&2, S.Sx>) -> ER:
  match badk:
    case True{}: ER_err{"unsupported-tol-kind " ++ k,
      "toleranced kinds are flatness, perpendicularity and parallelism"}
    case False{}: tol_gate_t(tol_t_ok(nm, t, sel, mo), nm, k, t, sel, mo, rest)
def tol_gate(+arity: Bool, +badk: Bool, +nm: String, +k: String, +t: F64, +sel: String,
    +mo: String, +rest: List<&2, S.Sx>) -> ER:
  match arity:
    case False{}: ER_err{"bad-tol", "write (tol NAME KIND T SEL rfs DATUM...) with flatness, perpendicularity or parallelism, finite T >= 0 and rfs"}
    case True{}: tol_gate_k(badk, nm, k, t, sel, mo, rest)
def tol_of(+x: S.Sx) -> ER:
  +xs = S.sx_xs(x)
  +n = List.length(&2, S.Sx, xs)
  +nm = S.sx_s(S.sx_nth(xs, 1n))
  +k = S.sx_s(S.sx_nth(xs, 2n))
  +t = fnum(S.sx_nth(xs, 3n))
  +sel = S.sx_s(S.sx_nth(xs, 4n))
  +mo = S.sx_s(S.sx_nth(xs, 5n))
  tol_gate(Nat.is_lt(5n, n), U64.is_eq(kind_of(k), 0u64), nm, k, t, sel, mo, S.sx_drop(xs, 6n))
def st_of(+x: S.Sx) -> ER:
  +xs = S.sx_xs(x)
  +nm = S.sx_s(S.sx_nth(xs, 1n))
  +g = fnum(S.sx_nth(xs, 2n))
  st_go(Bool.and(Nat.is_eq(List.length(&2, S.Sx, xs), 3n),
    Bool.and(Bool.and(Bool.not(String.eq(nm, "")), Bool.not(nm_bad(nm))), Bool.and(T.is_finite(g), F64.is_lt(0.0f64, g)))), nm, g)
def sk_of(+x: S.Sx) -> ER:
  +xs = S.sx_xs(x)
  +nm = S.sx_s(S.sx_nth(xs, 1n))
  +ds = sx_strs(S.sx_drop(xs, 2n))
  Bool.pick(ER, Bool.and(Nat.is_lt(1n, List.length(&2, S.Sx, xs)),
      Bool.and(Bool.and(Bool.not(String.eq(nm, "")), Bool.not(nm_bad(nm))),
        Bool.and(Nat.is_lt(0n, List.length(&2, String, ds)), dims_ok(ds)))),
    ER_sk{Stack{nm, ds}},
    ER_err{"stack-needs-dim", "write (stack NAME DIM...) with a name and one or more dim names"})
def entry_arm(+code: U64, +x: S.Sx, +p: M.Part) -> ER:
  match code:
    case 1u64: datum_of(x)
    case 2u64: dim_of(x, p)
    case 3u64: tol_of(x)
    case 4u64: st_of(x)
    case 5u64: sk_of(x)
    case _: ER_err{"unknown-pmi-entry", "entries are (node N), (nodes A B), (datum ...), (dim ...), (tol ...), (state ...) or (stack ...)"}
def entry_list(+x: S.Sx, +p: M.Part) -> ER:
  entry_arm(ek_of(S.sx_s(S.sx_nth(S.sx_xs(x), 0n))), x, p)
def entry_of(+x: S.Sx, +p: M.Part) -> ER:
  match x:
    case S.Sx_a{s}: ER_err{"unknown-pmi-entry", "entries are (node N), (nodes A B), (datum ...), (dim ...), (tol ...), (state ...) or (stack ...)"}
    case S.Sx_l{xs}: entry_list(x, p)
def scan_go(es: List<&2, S.Sx>, +p: M.Part, +nd: Nodes, +ers: List<&2, ER>) -> PR:
  match es:
    case []: scan_fin(pt_rev(part_go(List.reverse(&2, ER, ers), PT{[], [], [], [], []})),
      List.reverse(&2, ER, ers), nd)
    case +h <> t:
      sc_wrap(is_nd(h), entry_of(h, p), nd_of(h),
        scan_go(t, p, sc_nd_nacc(is_nd(h), nd_of(h), nd), sc_ers_nacc(is_nd(h), entry_of(h, p), ers)),
        nd, ers)
def pmi_head_go(+ispmi: Bool, +x: S.Sx, +p: M.Part) -> PR:
  match ispmi:
    case False{}: PR_err{"pmi-parse-failed", "write one (pmi ...) form"}
    case True{}: scan_go(S.sx_drop(S.sx_xs(x), 1n), p, Nodes{0u64, 0u64, False{}, False{}}, [])
def pmi_one_go(+ok: Bool, +x: S.Sx, +p: M.Part) -> PR:
  match ok:
    case False{}: PR_err{"pmi-parse-failed", "write one (pmi ...) form"}
    case True{}: pmi_head_go(S.head_is(x, "pmi"), x, p)
def pmi_ps_go(+ok: Bool, +xs: List<&2, S.Sx>, +p: M.Part) -> PR:
  match ok:
    case False{}: PR_err{"pmi-parse-failed", "write one (pmi ...) form"}
    case True{}:
      pmi_one_go(Nat.is_eq(List.length(&2, S.Sx, xs), 1n), S.sx_nth(xs, 0n), p)
def pmi_ps(+r: S.PS, +p: M.Part) -> PR:
  S.PS{+ok, +xs} = r
  pmi_ps_go(ok, xs, p)
def pmi_parse(+s: String, +p: M.Part) -> PR:
  pmi_ps(S.parse(s), p)
def pmi_verb(+code: U64, +p: M.Part, +xs: List<&2, String>) -> String:
  match code:
    case 1u64: q_check(p, pmi_parse(cat(sdrop(xs, 1n)), p))
    case 2u64: q_stack(p, pmi_parse(cat(sdrop(xs, 1n)), p))
    case 3u64: q_toler(p, pmi_parse(cat(sdrop(xs, 1n)), p))
    case 4u64: "error invalid-input | pmi | why: step42 needs an output path | fix: pmi step42 OUT (pmi ...)"
    case _: "error invalid-input | pmi | why: unknown verb | fix: pmi check|stack|toler|step42 ..."
def pmi_go(+p: M.Part, +xs: List<&2, String>) -> String:
  pmi_verb(verb_code(S.arg_at(xs, 0n)), p, xs)
def esc_add(+c: U32, h: Char, +acc: String) -> String:
  Bool.pick(String, U32.is_eq(c, 39), acc ++ "''", acc ++ SCon{h, ""})
def esc_go(s: String, +acc: String) -> String:
  match s:
    case SNil{}: acc
    case SCon{+h, t}: esc_go(t, esc_add(S.chr_code(h), h, acc))
def st_esc(+s: String) -> String:
  esc_go(s, "")
def dt_id(ds: List<&2, DI>, +s: String) -> Nat:
  match ds:
    case []: 0n
    case h <> t:
      DI{+nm, +id} = h
      Bool.pick(Nat, String.eq(nm, s), id, dt_id(t, s))
def em_bad(+em: EM, +why: String) -> EM:
  EM{+ok, +w, +s, +next, +n, +dm} = em
  EM{False{}, why, s, next, n, dm}
def em_dt_go(+ok: Bool, +d: Datum, +em: EM, +pds: Nat) -> EM:
  match ok:
    case False{}: em
    case True{}:
      Datum{+name, +sel} = d
      EM{+o, +w, +s, +next, +n, +dm} = em
      +b1 = Nat.add(next, 1n)
      +b2 = Nat.add(next, 2n)
      EM{True{}, "", s ++ SW.sw_ent(next, "(DATUM('" ++ st_esc(name) ++ "')SHAPE_ASPECT('',''," ++
          SW.sw_ref(pds) ++ ",.F.))") ++ SW.sw_ent(b1, "(DATUM_FEATURE()SHAPE_ASPECT('df-" ++
          st_esc(name) ++ "','" ++ sel ++ "'," ++ SW.sw_ref(pds) ++ ",.T.))") ++
        SW.sw_ent(b2, "SHAPE_ASPECT_RELATIONSHIP('',''," ++ SW.sw_ref(b1) ++ "," ++
          SW.sw_ref(next) ++ ")"), Nat.add(next, 3n), Nat.add(n, 3n), DI{name, next} <> dm}
def em_dt(+d: Datum, +em: EM, +pds: Nat) -> EM:
  Datum{+name, +sel} = d
  EM{+ok, +why, +s, +next, +n, +dm} = em
  em_dt_go(ok, d, em, pds)
def em_mi(+tag: String, +ns: BL.NS, +u0: Nat) -> String:
  "(MEASURE_REPRESENTATION_ITEM()MEASURE_WITH_UNIT(LENGTH_MEASURE(" ++ BL.ns_s(ns) ++ ")," ++
    SW.sw_ref(u0) ++ ")REPRESENTATION_ITEM('" ++ tag ++ "'))"
def em_sdr(+tag: String, +mi: Nat, +ctx: Nat) -> String:
  "(REPRESENTATION('" ++ tag ++ "',(" ++ SW.sw_ref(mi) ++ ")," ++ SW.sw_ref(ctx) ++
    ")SHAPE_DIMENSION_REPRESENTATION()SHAPE_REPRESENTATION())"
def em_dm_ok(+ok: Bool, +n0: BL.NS, +n1: BL.NS, +n2: BL.NS, +d: Dim, +em: EM, +u0: Nat,
    +pds: Nat, +ctx: Nat) -> EM:
  match ok:
    case False{}: em_bad(em, SW.sw_why_pick3(BL.ns_ok(n0), BL.ns_ok(n1), n0, n1, n2))
    case True{}:
      Dim{+name, +nom, +lo, +hi} = d
      EM{+o, +w, +s, +next, +n, +dm} = em
      +b = next
      EM{True{}, "", s ++ SW.sw_ent(b, "SHAPE_ASPECT('size','" ++ st_esc(name) ++ "'," ++
          SW.sw_ref(pds) ++ ",.T.)") ++
        SW.sw_ent(Nat.add(b, 1n), "DIMENSIONAL_SIZE(" ++ SW.sw_ref(b) ++ ",'" ++
          st_esc(name) ++ "')") ++
        SW.sw_ent(Nat.add(b, 2n), em_mi("nominal", n0, u0)) ++
        SW.sw_ent(Nat.add(b, 3n), em_sdr(st_esc(name) ++ "-nom", Nat.add(b, 2n), ctx)) ++
        SW.sw_ent(Nat.add(b, 4n), em_mi("lower", n1, u0)) ++
        SW.sw_ent(Nat.add(b, 5n), em_sdr(st_esc(name) ++ "-lo", Nat.add(b, 4n), ctx)) ++
        SW.sw_ent(Nat.add(b, 6n), em_mi("upper", n2, u0)) ++
        SW.sw_ent(Nat.add(b, 7n), em_sdr(st_esc(name) ++ "-hi", Nat.add(b, 6n), ctx)) ++
        SW.sw_ent(Nat.add(b, 8n), "(DIMENSIONAL_CHARACTERISTIC_REPRESENTATION(" ++
          SW.sw_ref(Nat.add(b, 1n)) ++ "," ++ SW.sw_ref(Nat.add(b, 3n)) ++
          ")INDEPENDENT_LIMITS_OF_LINEAR_DIMENSIONAL_SIZE_CHARACTERISTIC_REPRESENTATION((" ++
          SW.sw_ref(Nat.add(b, 5n)) ++ "," ++ SW.sw_ref(Nat.add(b, 7n)) ++ ")))"),
        Nat.add(b, 9n), Nat.add(n, 9n), dm}
def em_ok_of(+em: EM, +n0: BL.NS, +n1: BL.NS, +n2: BL.NS) -> Bool:
  EM{+ok, +why, +s, +next, +n, +dm} = em
  Bool.and(ok, Bool.and(BL.ns_ok(n0), Bool.and(BL.ns_ok(n1), BL.ns_ok(n2))))
def em_dm_go(+n0: BL.NS, +n1: BL.NS, +n2: BL.NS, +d: Dim, +em: EM, +u0: Nat, +pds: Nat,
    +ctx: Nat) -> EM:
  em_dm_ok(em_ok_of(em, n0, n1, n2), n0, n1, n2, d, em, u0, pds, ctx)
def em_dm(+d: Dim, +em: EM, +u0: Nat, +pds: Nat, +ctx: Nat) -> EM:
  Dim{+name, +nom, +lo, +hi} = d
  em_dm_go(SW.sw_f(nom), SW.sw_f(lo), SW.sw_f(hi), d, em, u0, pds, ctx)
def em_mag(+ns: BL.NS, +u0: Nat) -> String:
  "(LENGTH_MEASURE_WITH_UNIT()MEASURE_WITH_UNIT(LENGTH_MEASURE(" ++ BL.ns_s(ns) ++ ")," ++
    SW.sw_ref(u0) ++ "))"
def em_ok1(+em: EM, +ns: BL.NS) -> Bool:
  EM{+ok, +why, +s, +next, +n, +dm} = em
  Bool.and(ok, BL.ns_ok(ns))
def dt_id_of(+em: EM, +drf: List<&2, String>) -> Nat:
  EM{+ok, +why, +s, +next, +n, +dm} = em
  dt_id(dm, drf_head(drf))
def em_flat(+name: String, +sel: String, +ns: BL.NS, +em: EM, +u0: Nat, +pds: Nat) -> EM:
  EM{+o, +w, +s, +next, +n, +dm} = em
  +b = next
  EM{True{}, "", s ++ SW.sw_ent(b, "SHAPE_ASPECT('tol-face','" ++ sel ++ "'," ++
      SW.sw_ref(pds) ++ ",.T.)") ++ SW.sw_ent(Nat.add(b, 1n), em_mag(ns, u0)) ++
    SW.sw_ent(Nat.add(b, 2n), "FLATNESS_TOLERANCE('" ++ st_esc(name) ++ "','flatness'," ++
      SW.sw_ref(Nat.add(b, 1n)) ++ "," ++ SW.sw_ref(b) ++ ")"),
    Nat.add(b, 3n), Nat.add(n, 3n), dm}
def ori_ent(+kind: U64) -> String:
  Bool.pick(String, U64.is_eq(kind, 2u64), "PERPENDICULARITY_TOLERANCE", "PARALLELISM_TOLERANCE")
def em_ori(+name: String, +kind: U64, +sel: String, +ns: BL.NS, +em: EM, +u0: Nat, +pds: Nat,
    +did: Nat) -> EM:
  EM{+o, +w, +s, +next, +n, +dm} = em
  +b = next
  EM{True{}, "", s ++ SW.sw_ent(b, "SHAPE_ASPECT('tol-face','" ++ sel ++ "'," ++
      SW.sw_ref(pds) ++ ",.T.)") ++ SW.sw_ent(Nat.add(b, 1n), em_mag(ns, u0)) ++
    SW.sw_ent(Nat.add(b, 2n), "DATUM_REFERENCE(1," ++ SW.sw_ref(did) ++ ")") ++
    SW.sw_ent(Nat.add(b, 3n), "(GEOMETRIC_TOLERANCE('" ++ st_esc(name) ++ "','" ++
      kind_s(kind) ++ "'," ++ SW.sw_ref(Nat.add(b, 1n)) ++ "," ++ SW.sw_ref(b) ++
      ")GEOMETRIC_TOLERANCE_WITH_DATUM_REFERENCE((" ++ SW.sw_ref(Nat.add(b, 2n)) ++ "))" ++
      ori_ent(kind) ++ "())"), Nat.add(b, 4n), Nat.add(n, 4n), dm}
def em_tol_ok(+ok: Bool, +ns: BL.NS, +u: Tol, +em: EM, +u0: Nat, +pds: Nat) -> EM:
  match ok:
    case False{}: em_bad(em, SW.sw_why1(ns))
    case True{}:
      Tol{+name, +kind, +t, +sel, +drf} = u
      Bool.pick(EM, U64.is_eq(kind, 1u64), em_flat(name, sel, ns, em, u0, pds),
        em_ori(name, kind, sel, ns, em, u0, pds, dt_id_of(em, drf)))
def em_tol_go(+ns: BL.NS, +u: Tol, +em: EM, +u0: Nat, +pds: Nat) -> EM:
  em_tol_ok(em_ok1(em, ns), ns, u, em, u0, pds)
def em_tol(+u: Tol, +em: EM, +u0: Nat, +pds: Nat) -> EM:
  Tol{+name, +kind, +t, +sel, +drf} = u
  em_tol_go(SW.sw_f(t), u, em, u0, pds)
def emit_one(+e: ER, +em: EM, +u0: Nat, +pds: Nat, +ctx: Nat) -> EM:
  match e:
    case ER_dt{+d}: em_dt(d, em, pds)
    case ER_dm{+d}: em_dm(d, em, u0, pds, ctx)
    case ER_tol{+t}: em_tol(t, em, u0, pds)
    case ER_st{+s}: em
    case ER_sk{+s}: em
    case ER_err{+why, +fix}: em
def emit_go(es: List<&2, ER>, +em: EM, +u0: Nat, +pds: Nat, +ctx: Nat) -> EM:
  match es:
    case []: em
    case h <> t: emit_go(t, emit_one(h, em, u0, pds, ctx), u0, pds, ctx)
def pmi_emit(es: List<&2, ER>, +base: Nat, +u0: Nat, +pds: Nat, +ctx: Nat) -> EM:
  match es:
    case []: EM{True{}, "", "", base, 0n, []}
    case h <> t: emit_go(t, emit_one(h, EM{True{}, "", "", base, 0n, []}, u0, pds, ctx), u0, pds, ctx)
def pmi_file_fb(+f: FB, +m: PMI, +b: M.Body) -> FR:
  match f:
    case FB_bad{+why, +fix}: FR_err{why, fix}
    case FB_ok{}:
      PMI{+nd, +dts, +dms, +tls, +sts, +sks, +ers} = m
      +r = SW.sw_stage(M.bd_brep(b), M.bd_pl(b), 1n)
      +e = SW.er2_n(r)
      pmi_file_em(pmi_emit(ers, Nat.add(e, 20n), e, Nat.add(e, 10n), Nat.add(e, 16n)), r)
def q_file_e_go(+c: Bool, +e: String, +m: PMI, +cs: List<&2, M.CE>, +id: U64) -> FR:
  match c:
    case False{}: FR_line{e}
    case True{}:
      PMI{+nd, +dts, +dms, +tls, +sts, +sks, +ers} = m
      +b = nd_body(cs, id)
      pmi_file_fb(fb(res_all(ers, dts, dms, bt_of(b), M.bd_pl(b))), m, b)
def q_file_e(+e: String, +m: PMI, +cs: List<&2, M.CE>, +id: U64) -> FR:
  q_file_e_go(String.eq(e, ""), e, m, cs, id)
def q_file_pr(+pair: Bool, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>) -> FR:
  match pair:
    case True{}: FR_err{"pmi-needs-node", "give one (node N) entry"}
    case False{}: q_file_e(nd_line(cs, nd_a(m_nodes(m)), "error invalid-input | pmi step42 | why: ",
      "; nothing exported"), m, cs, nd_a(m_nodes(m)))
def q_file_nd(+seen: Bool, +pair: Bool, +m: PMI, +p: M.Part, +cs: List<&2, M.CE>) -> FR:
  match seen:
    case False{}: FR_err{"pmi-needs-node", "give one (node N) entry"}
    case True{}: q_file_pr(pair, m, p, cs)
def q_file(+p: M.Part, +pr: PR) -> FR:
  match pr:
    case PR_err{+why, +fix}: FR_err{why, fix}
    case PR_ok{+m}: q_file_nd(nd_seen(m_nodes(m)), nd_pair(m_nodes(m)), m, p, M.ev_part(p, []))
def pmi_file_out_go(+e: Bool, +out: String, +p: M.Part, +xs: List<&2, String>) -> FR:
  match e:
    case True{}: FR_err{"step42-needs-output", "pmi step42 OUT (pmi ...)"}
    case False{}: q_file(p, pmi_parse(cat(sdrop(xs, 2n)), p))
def pmi_file_out(+out: String, +p: M.Part, +xs: List<&2, String>) -> FR:
  pmi_file_out_go(String.eq(out, ""), out, p, xs)
def pmi_file(+p: M.Part, +xs: List<&2, String>) -> FR:
  pmi_file_out(S.arg_at(xs, 1n), p, xs)
