# C04 boundary-representation topology types: vertices, edges, oriented
# edge uses (coedges), loops, faces, shells, solids, cavities, compounds.
# Data + total predicates + validated constructors + one result type.
# Validators: ops.bend. Contract: docs/c04-contract.md.
# Failure arms reuse C00 FailKind (T.FailKind); no new taxonomy.
#
# BN-7 identity: every entity lives in an explicit Brep list; a handle
# is the structural (index, generation) pair, never an address or a bare
# ordinal. Each slot records the stamp issued at push time; resolve
# compares it and reports a mismatch as invalid-input (stale handle).
# Slot gens start at 1 (stamp 0 is the empty model); mk_* values carry
# gen 0 meaning UNISSUED — push re-stamps, the incoming gen is ignored.
#
# BN-8 fuel: every recursive list walk takes Nat fuel and fails closed
# with resource-exhausted when fuel runs out. The snoc appends below are
# structural in the list (bounded by length) and take no fuel, by the
# C03 dropk precedent. Head lookups (at idx 0) consume no fuel.
#
# BN-9 batches: no batch op yet. A batch is SPECIFIED as the left fold
# of the corresponding single push over its input list, failing closed
# on the first step that returns Terr; no batch runs until a later
# milestone implements that fold.
#
# Split with ops.bend (mirrors C03 mk_plane vs plane_checked): mk_*
# gates value-level shape only (finite points, valid geometry arms,
# nonempty member lists, degenerate edges pinched to one vertex).
# Incidence, handle liveness, loop closure, edge-use pairing, trimming
# consistency and geometric embedding are brep_checked in ops.bend
# under an explicit Profile (manifold-solid vs open-shell).

import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G

# --- Generational handles: structural (index, generation) pairs into
# the Brep lists. Well-formed as data for any pair; liveness is
# resolve's verdict, never the type. ---
type HVertex is Data:
  HV{ idx: Nat, gen: U64 }

type HEdge is Data:
  HE{ idx: Nat, gen: U64 }

type HCoedge is Data:
  HC{ idx: Nat, gen: U64 }

type HLoop is Data:
  HL{ idx: Nat, gen: U64 }

type HFace is Data:
  HF{ idx: Nat, gen: U64 }

type HShell is Data:
  HS{ idx: Nat, gen: U64 }

type HSolid is Data:
  HSo{ idx: Nat, gen: U64 }

# --- Validation profiles, explicitly named (MASTER_PLAN C04). Open
# surfaces are valid ONLY under P_open_shell; the admitted solid
# profile is P_manifold_solid. ops.bend threads the profile. ---
type Profile is Data:
  P_manifold_solid{}
  P_open_shell{}

# --- Edge geometry: either a curve arm over a parameter domain, or an
# explicit degenerate marker for singular poles (apex squeezed to one
# vertex). Pole-ness is content, never inferred. ---
type EdgeKind is Data:
  EK_curve{ curve: G.GVal, dom: G.Dom }
  EK_degenerate{}

# Outer boundary vs hole; every face carries >= 1 loop, exactly one
# outer under P_manifold_solid (checked in ops.bend).
type LoopKind is Data:
  LK_outer{}
  LK_inner{}

# Outer boundary vs cavity wall vs open sheet. A cavity IS a shell of
# kind SK_inner referenced from Solid.cavities; SK_open is admitted
# only under P_open_shell.
type ShellKind is Data:
  SK_outer{}
  SK_inner{}
  SK_open{}

# --- Vertex: a finite point. gen is the issued stamp (0 = unissued). ---
type Vertex is Data:
  Vx{ gen: U64, p: V.Point }

# --- Edge: the UNDERLYING geometry + endpoints, unoriented. Coedges
# carry orientation (fwd). A closed edge has v0 == v1 with EK_curve;
# a pole has v0 == v1 with EK_degenerate (enforced by edge_valid). ---
type Edge is Data:
  Ed{ gen: U64, v0: HVertex, v1: HVertex, kind: EdgeKind }

# --- Coedge: one ORIENTED use of an edge, with its trimming curve in
# the owning face's parameter space (TSeg/TBez arm). A seam edge
# occurs twice on one face as two coedges (fwd True/False); mating
# across faces is ops-level. ---
type Coedge is Data:
  Ce{ gen: U64, edge: HEdge, fwd: Bool, trim: G.GVal }

# --- Loop: an ordered coedge cycle; closure is geometric (ops.bend),
# not the list shape. Nonempty at value level. ---
type Loop is Data:
  Lp{ gen: U64, ces: List<&2, HCoedge>, kind: LoopKind }

# --- Face: a surface arm + trimming loops. same aligns the face
# normal with the surface normal (True) or flips it (False). ---
type Face is Data:
  Fa{ gen: U64, surf: G.GVal, loops: List<&2, HLoop>, same: Bool }

# --- Shell: a face set with one boundary role (outer/inner/open).
# Closedness is ops-level. ---
type Shell is Data:
  Sh{ gen: U64, faces: List<&2, HFace>, kind: ShellKind }

# --- Solid: one outer shell + zero or more cavity (inner) shells. ---
type Solid is Data:
  So{ gen: U64, outer: HShell, cavities: List<&2, HShell> }

# --- Compound: the root grouping — solids plus open sheets that are
# not part of any solid. Stored as Brep.top. ---
type Compound is Data:
  Cp{ solids: List<&2, HSolid>, shells: List<&2, HShell> }

# --- Brep: the explicit stores + root + issue stamp. stamp exceeds
# every issued slot gen (empty = 0); each push stamps stamp+1. ---
type Brep is Data:
  Br{ vs: List<&2, Vertex>, es: List<&2, Edge>,
    ces: List<&2, Coedge>, lps: List<&2, Loop>,
    fas: List<&2, Face>, shs: List<&2, Shell>,
    sos: List<&2, Solid>, top: Compound, stamp: U64 }

# --- One value union, one result type: every fallible C04 op returns
# TRes carrying either a value or a C00 FailKind. ---
type TVal is Data:
  T_f{ v: F64 }
  T_n{ v: Nat }
  T_b{ v: Bool }
  T_vx{ v: Vertex }
  T_ed{ v: Edge }
  T_ce{ v: Coedge }
  T_lp{ v: Loop }
  T_fa{ v: Face }
  T_sh{ v: Shell }
  T_so{ v: Solid }
  T_cp{ v: Compound }
  T_brep{ v: Brep }
  T_hv{ v: HVertex }
  T_he{ v: HEdge }
  T_hc{ v: HCoedge }
  T_hlp{ v: HLoop }
  T_hfa{ v: HFace }
  T_hsh{ v: HShell }
  T_hso{ v: HSolid }

type TRes is Data:
  Tok{ v: TVal }
  Terr{ kind: T.FailKind }

def tok_f(v: F64) -> TRes:
  Tok{T_f{v}}

def tok_n(v: Nat) -> TRes:
  Tok{T_n{v}}

def tok_b(v: Bool) -> TRes:
  Tok{T_b{v}}

def tok_vx(v: Vertex) -> TRes:
  Tok{T_vx{v}}

def tok_ed(v: Edge) -> TRes:
  Tok{T_ed{v}}

def tok_ce(v: Coedge) -> TRes:
  Tok{T_ce{v}}

def tok_lp(v: Loop) -> TRes:
  Tok{T_lp{v}}

def tok_fa(v: Face) -> TRes:
  Tok{T_fa{v}}

def tok_sh(v: Shell) -> TRes:
  Tok{T_sh{v}}

def tok_so(v: Solid) -> TRes:
  Tok{T_so{v}}

def tok_cp(v: Compound) -> TRes:
  Tok{T_cp{v}}

def tok_brep(v: Brep) -> TRes:
  Tok{T_brep{v}}

def tok_hv(v: HVertex) -> TRes:
  Tok{T_hv{v}}

def tok_he(v: HEdge) -> TRes:
  Tok{T_he{v}}

def tok_hc(v: HCoedge) -> TRes:
  Tok{T_hc{v}}

def tok_hlp(v: HLoop) -> TRes:
  Tok{T_hlp{v}}

def tok_hfa(v: HFace) -> TRes:
  Tok{T_hfa{v}}

def tok_hsh(v: HShell) -> TRes:
  Tok{T_hsh{v}}

def tok_hso(v: HSolid) -> TRes:
  Tok{T_hso{v}}

def terr(k: T.FailKind) -> TRes:
  Terr{k}

def tres_ok(r: TRes) -> Bool:
  match r:
    case Tok{v}: True{}
    case Terr{kind}: False{}

def tres_show(r: TRes) -> String:
  match r:
    case Tok{v}: "ok"
    case Terr{kind}: T.FailKind.show(kind)

# Total kind projector. There is no ok-valued FailKind, so Tok yields
# F_invalid BY DOCUMENTED CONVENTION (mirrors C01 cres_kind); gate on
# tres_ok or tres_show before reading the kind.
def tres_kind(r: TRes) -> T.FailKind:
  match r:
    case Tok{v}: T.F_invalid{}
    case Terr{kind}: kind

# --- Handle constructors: total, any pair well-formed as data. ---
def mk_hv(idx: Nat, gen: U64) -> HVertex:
  HV{idx, gen}

def mk_he(idx: Nat, gen: U64) -> HEdge:
  HE{idx, gen}

def mk_hc(idx: Nat, gen: U64) -> HCoedge:
  HC{idx, gen}

def mk_hlp(idx: Nat, gen: U64) -> HLoop:
  HL{idx, gen}

def mk_hfa(idx: Nat, gen: U64) -> HFace:
  HF{idx, gen}

def mk_hsh(idx: Nat, gen: U64) -> HShell:
  HS{idx, gen}

def mk_hso(idx: Nat, gen: U64) -> HSolid:
  HSo{idx, gen}

# --- Null handles: the documented projector defaults. A null carries
# no liveness claim; resolve treats it like any other pair. ---
def hv_null() -> HVertex:
  HV{0n, 0u64}

def he_null() -> HEdge:
  HE{0n, 0u64}

def hc_null() -> HCoedge:
  HC{0n, 0u64}

def hlp_null() -> HLoop:
  HL{0n, 0u64}

def hfa_null() -> HFace:
  HF{0n, 0u64}

def hsh_null() -> HShell:
  HS{0n, 0u64}

def hso_null() -> HSolid:
  HSo{0n, 0u64}

def brep_empty() -> Brep:
  Br{Nil{}, Nil{}, Nil{}, Nil{}, Nil{}, Nil{}, Nil{},
    Cp{Nil{}, Nil{}}, 0u64}

# --- Zero geometry arms for projector defaults (never validated). ---
def curve_zero() -> G.GVal:
  G.GV_ln{G.Ln{V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Dr{0.0f64, 0.0f64, 0.0f64}}}

def surf_zero() -> G.GVal:
  G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Dr{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64}}}

def trim_zero() -> G.GVal:
  G.GV_ts{G.Ts{V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64}}}

# Total projectors; documented zeroes unless the arm matches.
# Entity defaults: gen 0 (unissued), null handles, empty member lists,
# zero geometry arms, same=True, shell kind SK_open BY CONVENTION —
# gate on tres_ok; no default kind is meaningful.
def tres_f(r: TRes) -> F64:
  match r:
    case Tok{v}:
      match v:
        case T_f{w}: w
        case _: 0.0f64
    case Terr{kind}: 0.0f64

def tres_n(r: TRes) -> Nat:
  match r:
    case Tok{v}:
      match v:
        case T_n{w}: w
        case _: 0n
    case Terr{kind}: 0n

def tres_b(r: TRes) -> Bool:
  match r:
    case Tok{v}:
      match v:
        case T_b{w}: w
        case _: False{}
    case Terr{kind}: False{}

def tres_vx(r: TRes) -> Vertex:
  match r:
    case Tok{v}:
      match v:
        case T_vx{w}: w
        case _: Vx{0u64, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case Terr{kind}: Vx{0u64, V.Pt{0.0f64, 0.0f64, 0.0f64}}

def tres_ed(r: TRes) -> Edge:
  match r:
    case Tok{v}:
      match v:
        case T_ed{w}: w
        case _: Ed{0u64, hv_null(), hv_null(), EK_degenerate{}}
    case Terr{kind}: Ed{0u64, hv_null(), hv_null(), EK_degenerate{}}

def tres_ce(r: TRes) -> Coedge:
  match r:
    case Tok{v}:
      match v:
        case T_ce{w}: w
        case _: Ce{0u64, he_null(), False{}, trim_zero()}
    case Terr{kind}: Ce{0u64, he_null(), False{}, trim_zero()}

def tres_lp(r: TRes) -> Loop:
  match r:
    case Tok{v}:
      match v:
        case T_lp{w}: w
        case _: Lp{0u64, Nil{}, LK_outer{}}
    case Terr{kind}: Lp{0u64, Nil{}, LK_outer{}}

def tres_fa(r: TRes) -> Face:
  match r:
    case Tok{v}:
      match v:
        case T_fa{w}: w
        case _: Fa{0u64, surf_zero(), Nil{}, True{}}
    case Terr{kind}: Fa{0u64, surf_zero(), Nil{}, True{}}

def tres_sh(r: TRes) -> Shell:
  match r:
    case Tok{v}:
      match v:
        case T_sh{w}: w
        case _: Sh{0u64, Nil{}, SK_open{}}
    case Terr{kind}: Sh{0u64, Nil{}, SK_open{}}

def tres_so(r: TRes) -> Solid:
  match r:
    case Tok{v}:
      match v:
        case T_so{w}: w
        case _: So{0u64, hsh_null(), Nil{}}
    case Terr{kind}: So{0u64, hsh_null(), Nil{}}

def tres_cp(r: TRes) -> Compound:
  match r:
    case Tok{v}:
      match v:
        case T_cp{w}: w
        case _: Cp{Nil{}, Nil{}}
    case Terr{kind}: Cp{Nil{}, Nil{}}

def tres_brep(r: TRes) -> Brep:
  match r:
    case Tok{v}:
      match v:
        case T_brep{w}: w
        case _: brep_empty()
    case Terr{kind}: brep_empty()

def tres_hv(r: TRes) -> HVertex:
  match r:
    case Tok{v}:
      match v:
        case T_hv{w}: w
        case _: hv_null()
    case Terr{kind}: hv_null()

def tres_he(r: TRes) -> HEdge:
  match r:
    case Tok{v}:
      match v:
        case T_he{w}: w
        case _: he_null()
    case Terr{kind}: he_null()

def tres_hc(r: TRes) -> HCoedge:
  match r:
    case Tok{v}:
      match v:
        case T_hc{w}: w
        case _: hc_null()
    case Terr{kind}: hc_null()

def tres_hlp(r: TRes) -> HLoop:
  match r:
    case Tok{v}:
      match v:
        case T_hlp{w}: w
        case _: hlp_null()
    case Terr{kind}: hlp_null()

def tres_hfa(r: TRes) -> HFace:
  match r:
    case Tok{v}:
      match v:
        case T_hfa{w}: w
        case _: hfa_null()
    case Terr{kind}: hfa_null()

def tres_hsh(r: TRes) -> HShell:
  match r:
    case Tok{v}:
      match v:
        case T_hsh{w}: w
        case _: hsh_null()
    case Terr{kind}: hsh_null()

def tres_hso(r: TRes) -> HSolid:
  match r:
    case Tok{v}:
      match v:
        case T_hso{w}: w
        case _: hso_null()
    case Terr{kind}: hso_null()

# --- Raw accessors (total; no validation, no failure). ---
def hv_idx(h: HVertex) -> Nat:
  HV{idx, gen} = h
  idx

def hv_gen(h: HVertex) -> U64:
  HV{idx, gen} = h
  gen

def he_idx(h: HEdge) -> Nat:
  HE{idx, gen} = h
  idx

def he_gen(h: HEdge) -> U64:
  HE{idx, gen} = h
  gen

def hc_idx(h: HCoedge) -> Nat:
  HC{idx, gen} = h
  idx

def hc_gen(h: HCoedge) -> U64:
  HC{idx, gen} = h
  gen

def hlp_idx(h: HLoop) -> Nat:
  HL{idx, gen} = h
  idx

def hlp_gen(h: HLoop) -> U64:
  HL{idx, gen} = h
  gen

def hfa_idx(h: HFace) -> Nat:
  HF{idx, gen} = h
  idx

def hfa_gen(h: HFace) -> U64:
  HF{idx, gen} = h
  gen

def hsh_idx(h: HShell) -> Nat:
  HS{idx, gen} = h
  idx

def hsh_gen(h: HShell) -> U64:
  HS{idx, gen} = h
  gen

def hso_idx(h: HSolid) -> Nat:
  HSo{idx, gen} = h
  idx

def hso_gen(h: HSolid) -> U64:
  HSo{idx, gen} = h
  gen

def vx_gen(v: Vertex) -> U64:
  Vx{gen, p} = v
  gen

def vx_p(v: Vertex) -> V.Point:
  Vx{gen, p} = v
  p

def ed_gen(e: Edge) -> U64:
  Ed{gen, v0, v1, kind} = e
  gen

def ed_v0(e: Edge) -> HVertex:
  Ed{gen, v0, v1, kind} = e
  v0

def ed_v1(e: Edge) -> HVertex:
  Ed{gen, v0, v1, kind} = e
  v1

def ed_kind(e: Edge) -> EdgeKind:
  Ed{gen, v0, v1, kind} = e
  kind

# Union-kind accessors; documented defaults on the other arm.
def ekind_is_curve(k: EdgeKind) -> Bool:
  match k:
    case EK_curve{curve, dom}: True{}
    case EK_degenerate{}: False{}

def ekind_curve(k: EdgeKind) -> G.GVal:
  match k:
    case EK_curve{curve, dom}: curve
    case EK_degenerate{}: curve_zero()

def ekind_dom(k: EdgeKind) -> G.Dom:
  match k:
    case EK_curve{curve, dom}: dom
    case EK_degenerate{}: G.Dom{0.0f64, 0.0f64}

def ce_gen(c: Coedge) -> U64:
  Ce{gen, edge, fwd, trim} = c
  gen

def ce_edge(c: Coedge) -> HEdge:
  Ce{gen, edge, fwd, trim} = c
  edge

def ce_fwd(c: Coedge) -> Bool:
  Ce{gen, edge, fwd, trim} = c
  fwd

def ce_trim(c: Coedge) -> G.GVal:
  Ce{gen, edge, fwd, trim} = c
  trim

def lp_gen(l: Loop) -> U64:
  Lp{gen, ces, kind} = l
  gen

def lp_ces(l: Loop) -> List<&2, HCoedge>:
  Lp{gen, ces, kind} = l
  ces

def lp_kind(l: Loop) -> LoopKind:
  Lp{gen, ces, kind} = l
  kind

def fa_gen(f: Face) -> U64:
  Fa{gen, surf, loops, same} = f
  gen

def fa_surf(f: Face) -> G.GVal:
  Fa{gen, surf, loops, same} = f
  surf

def fa_loops(f: Face) -> List<&2, HLoop>:
  Fa{gen, surf, loops, same} = f
  loops

def fa_same(f: Face) -> Bool:
  Fa{gen, surf, loops, same} = f
  same

def sh_gen(s: Shell) -> U64:
  Sh{gen, faces, kind} = s
  gen

def sh_faces(s: Shell) -> List<&2, HFace>:
  Sh{gen, faces, kind} = s
  faces

def sh_kind(s: Shell) -> ShellKind:
  Sh{gen, faces, kind} = s
  kind

def so_gen(s: Solid) -> U64:
  So{gen, outer, cavities} = s
  gen

def so_outer(s: Solid) -> HShell:
  So{gen, outer, cavities} = s
  outer

def so_cavities(s: Solid) -> List<&2, HShell>:
  So{gen, outer, cavities} = s
  cavities

def cp_solids(c: Compound) -> List<&2, HSolid>:
  Cp{solids, shells} = c
  solids

def cp_shells(c: Compound) -> List<&2, HShell>:
  Cp{solids, shells} = c
  shells

def brep_vs(b: Brep) -> List<&2, Vertex>:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  vs

def brep_es(b: Brep) -> List<&2, Edge>:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  es

def brep_ces(b: Brep) -> List<&2, Coedge>:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  ces

def brep_lps(b: Brep) -> List<&2, Loop>:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  lps

def brep_fas(b: Brep) -> List<&2, Face>:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  fas

def brep_shs(b: Brep) -> List<&2, Shell>:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  shs

def brep_sos(b: Brep) -> List<&2, Solid>:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  sos

def brep_top(b: Brep) -> Compound:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  top

def brep_stamp(b: Brep) -> U64:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  stamp

# --- Structural handle equality: index AND generation. ---
def hv_eq(a: HVertex, b: HVertex) -> Bool:
  HV{ai, ag} = a
  HV{bi, bg} = b
  Bool.and(Nat.is_eq(ai, bi), U64.is_eq(ag, bg))

def he_eq(a: HEdge, b: HEdge) -> Bool:
  HE{ai, ag} = a
  HE{bi, bg} = b
  Bool.and(Nat.is_eq(ai, bi), U64.is_eq(ag, bg))

def hc_eq(a: HCoedge, b: HCoedge) -> Bool:
  HC{ai, ag} = a
  HC{bi, bg} = b
  Bool.and(Nat.is_eq(ai, bi), U64.is_eq(ag, bg))

def hlp_eq(a: HLoop, b: HLoop) -> Bool:
  HL{ai, ag} = a
  HL{bi, bg} = b
  Bool.and(Nat.is_eq(ai, bi), U64.is_eq(ag, bg))

def hfa_eq(a: HFace, b: HFace) -> Bool:
  HF{ai, ag} = a
  HF{bi, bg} = b
  Bool.and(Nat.is_eq(ai, bi), U64.is_eq(ag, bg))

def hsh_eq(a: HShell, b: HShell) -> Bool:
  HS{ai, ag} = a
  HS{bi, bg} = b
  Bool.and(Nat.is_eq(ai, bi), U64.is_eq(ag, bg))

def hso_eq(a: HSolid, b: HSolid) -> Bool:
  HSo{ai, ag} = a
  HSo{bi, bg} = b
  Bool.and(Nat.is_eq(ai, bi), U64.is_eq(ag, bg))

# --- Geometry-arm classifiers over C03 values. Edges take curve arms
# (Nurb here is a cubic curve), faces take surface arms, coedges take
# trim arms. Anything else is invalid-input at the constructor. ---
def gval_is_curve(c: G.GVal) -> Bool:
  match c:
    case G.GV_ln{v}: True{}
    case G.GV_cc{v}: True{}
    case G.GV_bz{v}: True{}
    case G.GV_rq{v}: True{}
    case G.GV_nb{v}: True{}
    case _: False{}

def gval_is_surf(s: G.GVal) -> Bool:
  match s:
    case G.GV_pl{v}: True{}
    case G.GV_cy{v}: True{}
    case G.GV_co{v}: True{}
    case G.GV_sp{v}: True{}
    case G.GV_to{v}: True{}
    case G.GV_bp{v}: True{}
    case _: False{}

def gval_is_trim(t: G.GVal) -> Bool:
  match t:
    case G.GV_ts{v}: True{}
    case G.GV_tb{v}: True{}
    case _: False{}

# --- Member-list emptiness: total, no walk (shape only). ---
def hce_nonempty(xs: List<&2, HCoedge>) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t: True{}

def hlp_nonempty(xs: List<&2, HLoop>) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t: True{}

def hfa_nonempty(xs: List<&2, HFace>) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t: True{}

def hsh_nonempty(xs: List<&2, HShell>) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t: True{}

def hso_nonempty(xs: List<&2, HSolid>) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t: True{}

# --- Value-level validity: finiteness + shape (the ONE centralized
# layer; constructors AND pushes consume these). Incidence, liveness,
# closure and embedding are ops.bend's brep_checked. ---
def vx_valid(v: Vertex) -> Bool:
  Vx{gen, p} = v
  V.pt_fin(p)

# Curve edges need a curve arm over a strict domain; endpoints are
# unconstrained (v0 == v1 is the honest closed edge). Degenerate
# edges must pinch to one vertex (the pole apex).
def edge_valid(e: Edge) -> Bool:
  Ed{gen, v0, v1, kind} = e
  match kind:
    case EK_curve{curve, dom}:
      Bool.and(gval_is_curve(curve), G.dom_valid(dom))
    case EK_degenerate{}: hv_eq(v0, v1)

def edge_is_closed(e: Edge) -> Bool:
  Ed{gen, v0, v1, kind} = e
  hv_eq(v0, v1)

def edge_is_degenerate(e: Edge) -> Bool:
  Ed{gen, v0, v1, kind} = e
  match kind:
    case EK_curve{curve, dom}: False{}
    case EK_degenerate{}: True{}

def ce_valid(c: Coedge) -> Bool:
  Ce{gen, edge, fwd, trim} = c
  gval_is_trim(trim)

def lp_valid(l: Loop) -> Bool:
  Lp{gen, ces, kind} = l
  hce_nonempty(ces)

def fa_valid(f: Face) -> Bool:
  Fa{gen, surf, loops, same} = f
  Bool.and(gval_is_surf(surf), hlp_nonempty(loops))

def sh_valid(s: Shell) -> Bool:
  Sh{gen, faces, kind} = s
  hfa_nonempty(faces)

# Every Solid value is well-formed: the outer handle and cavity
# membership are store-level (brep_checked), not value shape.
def so_valid(s: Solid) -> Bool:
  So{gen, outer, cavities} = s
  True{}

def so_has_cav(s: Solid) -> Bool:
  So{gen, outer, cavities} = s
  hsh_nonempty(cavities)

def cp_has_solids(c: Compound) -> Bool:
  Cp{solids, shells} = c
  hso_nonempty(solids)

def cp_has_shells(c: Compound) -> Bool:
  Cp{solids, shells} = c
  hsh_nonempty(shells)

# --- Kind/profile tags: content identity words (mirrors C00 op_tag). ---
def ekind_tag(k: EdgeKind) -> U64:
  match k:
    case EK_curve{curve, dom}: 0u64
    case EK_degenerate{}: 1u64

def lkind_tag(k: LoopKind) -> U64:
  match k:
    case LK_outer{}: 0u64
    case LK_inner{}: 1u64

def skind_tag(k: ShellKind) -> U64:
  match k:
    case SK_outer{}: 0u64
    case SK_inner{}: 1u64
    case SK_open{}: 2u64

def profile_tag(p: Profile) -> U64:
  match p:
    case P_manifold_solid{}: 0u64
    case P_open_shell{}: 1u64

def profile_show(p: Profile) -> String:
  match p:
    case P_manifold_solid{}: "manifold-solid"
    case P_open_shell{}: "open-shell"

# --- Validated constructors: malformed input fails as invalid-input.
# All mk_* values carry gen 0 (unissued); push re-stamps. ---
def mk_vx_go(p: V.Point, ok: Bool) -> TRes:
  match ok:
    case True{}: tok_vx(Vx{0u64, p})
    case False{}: terr(T.F_invalid{})

def mk_vx(+p: V.Point) -> TRes:
  mk_vx_go(p, V.pt_fin(p))

def mk_edge_curve_go(v0: HVertex, v1: HVertex, curve: G.GVal,
    dom: G.Dom, ok: Bool) -> TRes:
  match ok:
    case True{}: tok_ed(Ed{0u64, v0, v1, EK_curve{curve, dom}})
    case False{}: terr(T.F_invalid{})

def mk_edge_curve(v0: HVertex, v1: HVertex, +curve: G.GVal,
    +dom: G.Dom) -> TRes:
  mk_edge_curve_go(v0, v1, curve, dom,
    Bool.and(gval_is_curve(curve), G.dom_valid(dom)))

def mk_edge_degen_go(v0: HVertex, v1: HVertex, ok: Bool) -> TRes:
  match ok:
    case True{}: tok_ed(Ed{0u64, v0, v1, EK_degenerate{}})
    case False{}: terr(T.F_invalid{})

def mk_edge_degen(+v0: HVertex, +v1: HVertex) -> TRes:
  mk_edge_degen_go(v0, v1, hv_eq(v0, v1))

def mk_coedge_go(edge: HEdge, fwd: Bool, trim: G.GVal,
    ok: Bool) -> TRes:
  match ok:
    case True{}: tok_ce(Ce{0u64, edge, fwd, trim})
    case False{}: terr(T.F_invalid{})

def mk_coedge(edge: HEdge, fwd: Bool, +trim: G.GVal) -> TRes:
  mk_coedge_go(edge, fwd, trim, gval_is_trim(trim))

def mk_loop_go(ces: List<&2, HCoedge>, kind: LoopKind,
    ok: Bool) -> TRes:
  match ok:
    case True{}: tok_lp(Lp{0u64, ces, kind})
    case False{}: terr(T.F_invalid{})

def mk_loop(+ces: List<&2, HCoedge>, kind: LoopKind) -> TRes:
  mk_loop_go(ces, kind, hce_nonempty(ces))

def mk_face_go(surf: G.GVal, loops: List<&2, HLoop>, same: Bool,
    ok: Bool) -> TRes:
  match ok:
    case True{}: tok_fa(Fa{0u64, surf, loops, same})
    case False{}: terr(T.F_invalid{})

def mk_face(+surf: G.GVal, +loops: List<&2, HLoop>,
    same: Bool) -> TRes:
  mk_face_go(surf, loops, same,
    Bool.and(gval_is_surf(surf), hlp_nonempty(loops)))

def mk_shell_go(faces: List<&2, HFace>, kind: ShellKind,
    ok: Bool) -> TRes:
  match ok:
    case True{}: tok_sh(Sh{0u64, faces, kind})
    case False{}: terr(T.F_invalid{})

def mk_shell(+faces: List<&2, HFace>, kind: ShellKind) -> TRes:
  mk_shell_go(faces, kind, hfa_nonempty(faces))

# Total: every Solid/Compound value is well-formed (so_valid).
def mk_solid(outer: HShell,
    cavities: List<&2, HShell>) -> TRes:
  tok_so(So{0u64, outer, cavities})

def mk_compound(solids: List<&2, HSolid>,
    shells: List<&2, HShell>) -> TRes:
  tok_cp(Cp{solids, shells})

# --- Walk codes pack ok + 2*done as one Nat (mirrors C03 code_pack;
# ok is meaningful only when done; callers check done first). ---
def okd_pack(ok: Bool, done: Bool) -> Nat:
  Nat.add(Bool.pick(Nat, ok, 1n, 0n), Bool.pick(Nat, done, 2n, 0n))

def okd_ok(c: Nat) -> Bool:
  Nat.is_eq(Nat.mod(c, 2n), 1n)

def okd_done(c: Nat) -> Bool:
  Nat.is_le(2n, c)

def okd_all(+a: Nat, +b: Nat) -> Nat:
  okd_pack(Bool.and(okd_ok(a), okd_ok(b)),
    Bool.and(okd_done(a), okd_done(b)))

# --- Vertex-orbit carrier (stage H internal): fuel-out and genuine
# close are distinguishable only via the closed flag; steps counts
# non-degenerate visits before close. ---
type VOrbit is Data:
  VO{ steps: Nat, closed: Bool }

def vo_steps(o: VOrbit) -> Nat:
  VO{s, c} = o
  s

def vo_closed(o: VOrbit) -> Bool:
  VO{s, c} = o
  c

# --- Slot validation walks: every recursive walk is structural in
# its list AND fuel-capped; fuel exhaustion surfaces as
# resource-exhausted, never a guess. ---
def vs_all_c(vs: List<&2, Vertex>, fuel: Nat) -> Nat:
  match vs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = vs_all_c(t, f)
          okd_pack(Bool.and(vx_valid(h), okd_ok(rest)),
            okd_done(rest))

def es_all_c(es: List<&2, Edge>, fuel: Nat) -> Nat:
  match es:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = es_all_c(t, f)
          okd_pack(Bool.and(edge_valid(h), okd_ok(rest)),
            okd_done(rest))

def ces_all_c(ces: List<&2, Coedge>, fuel: Nat) -> Nat:
  match ces:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = ces_all_c(t, f)
          okd_pack(Bool.and(ce_valid(h), okd_ok(rest)),
            okd_done(rest))

def lps_all_c(lps: List<&2, Loop>, fuel: Nat) -> Nat:
  match lps:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = lps_all_c(t, f)
          okd_pack(Bool.and(lp_valid(h), okd_ok(rest)),
            okd_done(rest))

def fas_all_c(fas: List<&2, Face>, fuel: Nat) -> Nat:
  match fas:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = fas_all_c(t, f)
          okd_pack(Bool.and(fa_valid(h), okd_ok(rest)),
            okd_done(rest))

def shs_all_c(shs: List<&2, Shell>, fuel: Nat) -> Nat:
  match shs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = shs_all_c(t, f)
          okd_pack(Bool.and(sh_valid(h), okd_ok(rest)),
            okd_done(rest))

def sos_all_c(sos: List<&2, Solid>, fuel: Nat) -> Nat:
  match sos:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = sos_all_c(t, f)
          okd_pack(Bool.and(so_valid(h), okd_ok(rest)),
            okd_done(rest))

# --- Slot generation checks (D1/D2): every slot gen nonzero (D2) and
# <= stamp (D1). Fuel 1 per slot; each walk gets the full mk_brep cap. ---
def vs_gen_c(vs: List<&2, Vertex>, +stamp: U64, fuel: Nat) -> Nat:
  match vs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = vs_gen_c(t, stamp, f)
          +hg = vx_gen(h)
          okd_pack(Bool.and(Bool.and(U64.is_ne(hg, 0u64),
            U64.is_le(hg, stamp)), okd_ok(rest)), okd_done(rest))

def es_gen_c(es: List<&2, Edge>, +stamp: U64, fuel: Nat) -> Nat:
  match es:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = es_gen_c(t, stamp, f)
          +hg = ed_gen(h)
          okd_pack(Bool.and(Bool.and(U64.is_ne(hg, 0u64),
            U64.is_le(hg, stamp)), okd_ok(rest)), okd_done(rest))

def ces_gen_c(ces: List<&2, Coedge>, +stamp: U64, fuel: Nat) -> Nat:
  match ces:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = ces_gen_c(t, stamp, f)
          +hg = ce_gen(h)
          okd_pack(Bool.and(Bool.and(U64.is_ne(hg, 0u64),
            U64.is_le(hg, stamp)), okd_ok(rest)), okd_done(rest))

def lps_gen_c(lps: List<&2, Loop>, +stamp: U64, fuel: Nat) -> Nat:
  match lps:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = lps_gen_c(t, stamp, f)
          +hg = lp_gen(h)
          okd_pack(Bool.and(Bool.and(U64.is_ne(hg, 0u64),
            U64.is_le(hg, stamp)), okd_ok(rest)), okd_done(rest))

def fas_gen_c(fas: List<&2, Face>, +stamp: U64, fuel: Nat) -> Nat:
  match fas:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = fas_gen_c(t, stamp, f)
          +hg = fa_gen(h)
          okd_pack(Bool.and(Bool.and(U64.is_ne(hg, 0u64),
            U64.is_le(hg, stamp)), okd_ok(rest)), okd_done(rest))

def shs_gen_c(shs: List<&2, Shell>, +stamp: U64, fuel: Nat) -> Nat:
  match shs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = shs_gen_c(t, stamp, f)
          +hg = sh_gen(h)
          okd_pack(Bool.and(Bool.and(U64.is_ne(hg, 0u64),
            U64.is_le(hg, stamp)), okd_ok(rest)), okd_done(rest))

def sos_gen_c(sos: List<&2, Solid>, +stamp: U64, fuel: Nat) -> Nat:
  match sos:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = sos_gen_c(t, stamp, f)
          +hg = so_gen(h)
          okd_pack(Bool.and(Bool.and(U64.is_ne(hg, 0u64),
            U64.is_le(hg, stamp)), okd_ok(rest)), okd_done(rest))

# --- Slot uniqueness checks (D3): no duplicate gen within a store.
# free_of scans the tail for g (ok = absent); nodup combines head-vs-tail
# with the recursive tail check. Each scan gets the full remaining fuel,
# so fuel >= store length still suffices (same bound as validity). ---
def vs_free_of(xs: List<&2, Vertex>, +g: U64, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = vs_free_of(t, g, f)
          +hg = vx_gen(h)
          okd_pack(Bool.and(U64.is_ne(hg, g), okd_ok(rest)),
            okd_done(rest))

def vs_nodup_c(xs: List<&2, Vertex>, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> +t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +ff = f
          +hg = vx_gen(h)
          okd_all(vs_free_of(t, hg, ff), vs_nodup_c(t, ff))

def es_free_of(xs: List<&2, Edge>, +g: U64, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = es_free_of(t, g, f)
          +hg = ed_gen(h)
          okd_pack(Bool.and(U64.is_ne(hg, g), okd_ok(rest)),
            okd_done(rest))

def es_nodup_c(xs: List<&2, Edge>, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> +t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +ff = f
          +hg = ed_gen(h)
          okd_all(es_free_of(t, hg, ff), es_nodup_c(t, ff))

def ces_free_of(xs: List<&2, Coedge>, +g: U64, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = ces_free_of(t, g, f)
          +hg = ce_gen(h)
          okd_pack(Bool.and(U64.is_ne(hg, g), okd_ok(rest)),
            okd_done(rest))

def ces_nodup_c(xs: List<&2, Coedge>, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> +t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +ff = f
          +hg = ce_gen(h)
          okd_all(ces_free_of(t, hg, ff), ces_nodup_c(t, ff))

def lps_free_of(xs: List<&2, Loop>, +g: U64, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = lps_free_of(t, g, f)
          +hg = lp_gen(h)
          okd_pack(Bool.and(U64.is_ne(hg, g), okd_ok(rest)),
            okd_done(rest))

def lps_nodup_c(xs: List<&2, Loop>, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> +t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +ff = f
          +hg = lp_gen(h)
          okd_all(lps_free_of(t, hg, ff), lps_nodup_c(t, ff))

def fas_free_of(xs: List<&2, Face>, +g: U64, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = fas_free_of(t, g, f)
          +hg = fa_gen(h)
          okd_pack(Bool.and(U64.is_ne(hg, g), okd_ok(rest)),
            okd_done(rest))

def fas_nodup_c(xs: List<&2, Face>, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> +t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +ff = f
          +hg = fa_gen(h)
          okd_all(fas_free_of(t, hg, ff), fas_nodup_c(t, ff))

def shs_free_of(xs: List<&2, Shell>, +g: U64, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = shs_free_of(t, g, f)
          +hg = sh_gen(h)
          okd_pack(Bool.and(U64.is_ne(hg, g), okd_ok(rest)),
            okd_done(rest))

def shs_nodup_c(xs: List<&2, Shell>, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> +t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +ff = f
          +hg = sh_gen(h)
          okd_all(shs_free_of(t, hg, ff), shs_nodup_c(t, ff))

def sos_free_of(xs: List<&2, Solid>, +g: U64, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = sos_free_of(t, g, f)
          +hg = so_gen(h)
          okd_pack(Bool.and(U64.is_ne(hg, g), okd_ok(rest)),
            okd_done(rest))

def sos_nodup_c(xs: List<&2, Solid>, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> +t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +ff = f
          +hg = so_gen(h)
          okd_all(sos_free_of(t, hg, ff), sos_nodup_c(t, ff))

# Validated Brep assembly: every slot value-checked, gen-checked
# (nonzero, <= stamp), and uniqueness-checked under one shared fuel
# cap per walk (full cap each, not divided). Handle liveness of member
# lists and top is brep_checked in ops.bend, not here.
def mk_brep_pick2(vs: List<&2, Vertex>, es: List<&2, Edge>,
    ces: List<&2, Coedge>, lps: List<&2, Loop>,
    fas: List<&2, Face>, shs: List<&2, Shell>,
    sos: List<&2, Solid>, top: Compound, stamp: U64,
    ok: Bool) -> TRes:
  match ok:
    case True{}:
      tok_brep(Br{vs, es, ces, lps, fas, shs, sos, top, stamp})
    case False{}: terr(T.F_invalid{})

def mk_brep_pick(vs: List<&2, Vertex>, es: List<&2, Edge>,
    ces: List<&2, Coedge>, lps: List<&2, Loop>,
    fas: List<&2, Face>, shs: List<&2, Shell>,
    sos: List<&2, Solid>, top: Compound, stamp: U64,
    done: Bool, ok: Bool) -> TRes:
  match done:
    case False{}: terr(T.F_exhausted{})
    case True{}:
      mk_brep_pick2(vs, es, ces, lps, fas, shs, sos, top,
        stamp, ok)

def mk_brep_go(vs: List<&2, Vertex>, es: List<&2, Edge>,
    ces: List<&2, Coedge>, lps: List<&2, Loop>,
    fas: List<&2, Face>, shs: List<&2, Shell>,
    sos: List<&2, Solid>, top: Compound, stamp: U64,
    +code: Nat) -> TRes:
  mk_brep_pick(vs, es, ces, lps, fas, shs, sos, top, stamp,
    okd_done(code), okd_ok(code))

def mk_brep(+vs: List<&2, Vertex>, +es: List<&2, Edge>,
    +ces: List<&2, Coedge>, +lps: List<&2, Loop>,
    +fas: List<&2, Face>, +shs: List<&2, Shell>,
    +sos: List<&2, Solid>, top: Compound, +stamp: U64,
    +fuel: Nat) -> TRes:
  mk_brep_go(vs, es, ces, lps, fas, shs, sos, top, stamp,
    okd_all(vs_all_c(vs, fuel),
      okd_all(vs_gen_c(vs, stamp, fuel),
        okd_all(vs_nodup_c(vs, fuel),
          okd_all(es_all_c(es, fuel),
            okd_all(es_gen_c(es, stamp, fuel),
              okd_all(es_nodup_c(es, fuel),
                okd_all(ces_all_c(ces, fuel),
                  okd_all(ces_gen_c(ces, stamp, fuel),
                    okd_all(ces_nodup_c(ces, fuel),
                      okd_all(lps_all_c(lps, fuel),
                        okd_all(lps_gen_c(lps, stamp, fuel),
                          okd_all(lps_nodup_c(lps, fuel),
                            okd_all(fas_all_c(fas, fuel),
                              okd_all(fas_gen_c(fas, stamp, fuel),
                                okd_all(fas_nodup_c(fas, fuel),
                                  okd_all(shs_all_c(shs, fuel),
                                    okd_all(shs_gen_c(shs, stamp, fuel),
                                      okd_all(shs_nodup_c(shs, fuel),
                                        okd_all(sos_all_c(sos, fuel),
                                          okd_all(sos_gen_c(sos, stamp, fuel),
                                            sos_nodup_c(sos, fuel))))))))))))))))))))))

# --- Generational store ops, per entity: structural snoc append,
# fuel-bounded len/at/resolve/handle_of, issued-handle preview, and
# validating push (stamps stamp+1, bumps stamp). resolve reports a
# generation mismatch as invalid-input (stale handle); out-of-range
# is invalid-input; fuel-out is resource-exhausted. issued+push is
# the issue protocol: the issued handle names the pushed slot iff no
# push intervenes. ---

def vx_snoc(xs: List<&2, Vertex>, v: Vertex) -> List<&2, Vertex>:
  match xs:
    case Nil{}: v <> Nil{}
    case h <> t: h <> vx_snoc(t, v)

def vx_len_go(xs: List<&2, Vertex>, fuel: Nat, acc: Nat) -> TRes:
  match xs:
    case Nil{}: tok_n(acc)
    case h <> t:
      match fuel:
        case 0n: terr(T.F_exhausted{})
        case 1n+f: vx_len_go(t, f, Nat.add(acc, 1n))

def vx_len(xs: List<&2, Vertex>, fuel: Nat) -> TRes:
  vx_len_go(xs, fuel, 0n)

def vx_at(xs: List<&2, Vertex>, idx: Nat, fuel: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match idx:
        case 0n: tok_vx(h)
        case 1n+m:
          match fuel:
            case 0n: terr(T.F_exhausted{})
            case 1n+f: vx_at(t, m, f)

def vx_resolve_pick(w: Vertex, live: Bool) -> TRes:
  match live:
    case True{}: tok_vx(w)
    case False{}: terr(T.F_invalid{})

def vx_resolve_go(r: TRes, gen: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_vx{w}:
          Vx{+g, p} = w
          vx_resolve_pick(Vx{g, p}, U64.is_eq(g, gen))
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def vx_resolve(xs: List<&2, Vertex>, h: HVertex,
    fuel: Nat) -> TRes:
  HV{idx, gen} = h
  vx_resolve_go(vx_at(xs, idx, fuel), gen)

def vx_handle_of_go(xs: List<&2, Vertex>, +gen: U64, fuel: Nat,
    +idx: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match fuel:
        case 0n:
          Bool.pick(TRes, U64.is_eq(vx_gen(h), gen),
            tok_hv(HV{idx, gen}), terr(T.F_exhausted{}))
        case 1n+f:
          Bool.pick(TRes, U64.is_eq(vx_gen(h), gen),
            tok_hv(HV{idx, gen}),
            vx_handle_of_go(t, gen, f, Nat.add(idx, 1n)))

def vx_handle_of(xs: List<&2, Vertex>, gen: U64,
    fuel: Nat) -> TRes:
  vx_handle_of_go(xs, gen, fuel, 0n)

def vx_issued_go(r: TRes, stamp: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_n{n}: tok_hv(HV{n, U64.add(stamp, 1u64)})
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def vx_issued(b: Brep, fuel: Nat) -> TRes:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  vx_issued_go(vx_len(vs, fuel), stamp)

def vx_push_pick(vs: List<&2, Vertex>, es: List<&2, Edge>,
    ces: List<&2, Coedge>, lps: List<&2, Loop>,
    fas: List<&2, Face>, shs: List<&2, Shell>,
    sos: List<&2, Solid>, top: Compound, +g: U64,
    p: V.Point, ok: Bool) -> TRes:
  match ok:
    case False{}: terr(T.F_invalid{})
    case True{}:
      tok_brep(Br{vx_snoc(vs, Vx{g, p}), es, ces, lps, fas,
        shs, sos, top, g})

def vx_push_go(b: Brep, p: V.Point, ok: Bool) -> TRes:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  vx_push_pick(vs, es, ces, lps, fas, shs, sos, top,
    U64.add(stamp, 1u64), p, ok)

def vx_push(b: Brep, +p: V.Point) -> TRes:
  vx_push_go(b, p, V.pt_fin(p))

def ed_snoc(xs: List<&2, Edge>, v: Edge) -> List<&2, Edge>:
  match xs:
    case Nil{}: v <> Nil{}
    case h <> t: h <> ed_snoc(t, v)

def ed_len_go(xs: List<&2, Edge>, fuel: Nat, acc: Nat) -> TRes:
  match xs:
    case Nil{}: tok_n(acc)
    case h <> t:
      match fuel:
        case 0n: terr(T.F_exhausted{})
        case 1n+f: ed_len_go(t, f, Nat.add(acc, 1n))

def ed_len(xs: List<&2, Edge>, fuel: Nat) -> TRes:
  ed_len_go(xs, fuel, 0n)

def ed_at(xs: List<&2, Edge>, idx: Nat, fuel: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match idx:
        case 0n: tok_ed(h)
        case 1n+m:
          match fuel:
            case 0n: terr(T.F_exhausted{})
            case 1n+f: ed_at(t, m, f)

def ed_resolve_pick(w: Edge, live: Bool) -> TRes:
  match live:
    case True{}: tok_ed(w)
    case False{}: terr(T.F_invalid{})

def ed_resolve_go(r: TRes, gen: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_ed{w}:
          Ed{+g, v0, v1, kind} = w
          ed_resolve_pick(Ed{g, v0, v1, kind},
            U64.is_eq(g, gen))
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def ed_resolve(xs: List<&2, Edge>, h: HEdge,
    fuel: Nat) -> TRes:
  HE{idx, gen} = h
  ed_resolve_go(ed_at(xs, idx, fuel), gen)

def ed_handle_of_go(xs: List<&2, Edge>, +gen: U64, fuel: Nat,
    +idx: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match fuel:
        case 0n:
          Bool.pick(TRes, U64.is_eq(ed_gen(h), gen),
            tok_he(HE{idx, gen}), terr(T.F_exhausted{}))
        case 1n+f:
          Bool.pick(TRes, U64.is_eq(ed_gen(h), gen),
            tok_he(HE{idx, gen}),
            ed_handle_of_go(t, gen, f, Nat.add(idx, 1n)))

def ed_handle_of(xs: List<&2, Edge>, gen: U64,
    fuel: Nat) -> TRes:
  ed_handle_of_go(xs, gen, fuel, 0n)

def ed_issued_go(r: TRes, stamp: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_n{n}: tok_he(HE{n, U64.add(stamp, 1u64)})
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def ed_issued(b: Brep, fuel: Nat) -> TRes:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  ed_issued_go(ed_len(es, fuel), stamp)

def ed_push_pick(vs: List<&2, Vertex>, es: List<&2, Edge>,
    ces: List<&2, Coedge>, lps: List<&2, Loop>,
    fas: List<&2, Face>, shs: List<&2, Shell>,
    sos: List<&2, Solid>, top: Compound, +g: U64,
    v0: HVertex, v1: HVertex, kind: EdgeKind,
    ok: Bool) -> TRes:
  match ok:
    case False{}: terr(T.F_invalid{})
    case True{}:
      tok_brep(Br{vs, ed_snoc(es, Ed{g, v0, v1, kind}), ces,
        lps, fas, shs, sos, top, g})

def ed_push_go(b: Brep, v0: HVertex, v1: HVertex,
    kind: EdgeKind, ok: Bool) -> TRes:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  ed_push_pick(vs, es, ces, lps, fas, shs, sos, top,
    U64.add(stamp, 1u64), v0, v1, kind, ok)

def ed_push(b: Brep, +v0: HVertex, +v1: HVertex,
    +kind: EdgeKind) -> TRes:
  ed_push_go(b, v0, v1, kind,
    edge_valid(Ed{0u64, v0, v1, kind}))

def ce_snoc(xs: List<&2, Coedge>, v: Coedge) -> List<&2, Coedge>:
  match xs:
    case Nil{}: v <> Nil{}
    case h <> t: h <> ce_snoc(t, v)

def ce_len_go(xs: List<&2, Coedge>, fuel: Nat, acc: Nat) -> TRes:
  match xs:
    case Nil{}: tok_n(acc)
    case h <> t:
      match fuel:
        case 0n: terr(T.F_exhausted{})
        case 1n+f: ce_len_go(t, f, Nat.add(acc, 1n))

def ce_len(xs: List<&2, Coedge>, fuel: Nat) -> TRes:
  ce_len_go(xs, fuel, 0n)

def ce_at(xs: List<&2, Coedge>, idx: Nat, fuel: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match idx:
        case 0n: tok_ce(h)
        case 1n+m:
          match fuel:
            case 0n: terr(T.F_exhausted{})
            case 1n+f: ce_at(t, m, f)

def ce_resolve_pick(w: Coedge, live: Bool) -> TRes:
  match live:
    case True{}: tok_ce(w)
    case False{}: terr(T.F_invalid{})

def ce_resolve_go(r: TRes, gen: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_ce{w}:
          Ce{+g, edge, fwd, trim} = w
          ce_resolve_pick(Ce{g, edge, fwd, trim},
            U64.is_eq(g, gen))
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def ce_resolve(xs: List<&2, Coedge>, h: HCoedge,
    fuel: Nat) -> TRes:
  HC{idx, gen} = h
  ce_resolve_go(ce_at(xs, idx, fuel), gen)

def ce_handle_of_go(xs: List<&2, Coedge>, +gen: U64, fuel: Nat,
    +idx: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match fuel:
        case 0n:
          Bool.pick(TRes, U64.is_eq(ce_gen(h), gen),
            tok_hc(HC{idx, gen}), terr(T.F_exhausted{}))
        case 1n+f:
          Bool.pick(TRes, U64.is_eq(ce_gen(h), gen),
            tok_hc(HC{idx, gen}),
            ce_handle_of_go(t, gen, f, Nat.add(idx, 1n)))

def ce_handle_of(xs: List<&2, Coedge>, gen: U64,
    fuel: Nat) -> TRes:
  ce_handle_of_go(xs, gen, fuel, 0n)

def ce_issued_go(r: TRes, stamp: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_n{n}: tok_hc(HC{n, U64.add(stamp, 1u64)})
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def ce_issued(b: Brep, fuel: Nat) -> TRes:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  ce_issued_go(ce_len(ces, fuel), stamp)

def ce_push_pick(vs: List<&2, Vertex>, es: List<&2, Edge>,
    ces: List<&2, Coedge>, lps: List<&2, Loop>,
    fas: List<&2, Face>, shs: List<&2, Shell>,
    sos: List<&2, Solid>, top: Compound, +g: U64,
    edge: HEdge, fwd: Bool, trim: G.GVal,
    ok: Bool) -> TRes:
  match ok:
    case False{}: terr(T.F_invalid{})
    case True{}:
      tok_brep(Br{vs, es, ce_snoc(ces, Ce{g, edge, fwd, trim}),
        lps, fas, shs, sos, top, g})

def ce_push_go(b: Brep, edge: HEdge, fwd: Bool,
    trim: G.GVal, ok: Bool) -> TRes:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  ce_push_pick(vs, es, ces, lps, fas, shs, sos, top,
    U64.add(stamp, 1u64), edge, fwd, trim, ok)

def ce_push(b: Brep, +edge: HEdge, +fwd: Bool,
    +trim: G.GVal) -> TRes:
  ce_push_go(b, edge, fwd, trim,
    ce_valid(Ce{0u64, edge, fwd, trim}))

def lp_snoc(xs: List<&2, Loop>, v: Loop) -> List<&2, Loop>:
  match xs:
    case Nil{}: v <> Nil{}
    case h <> t: h <> lp_snoc(t, v)

def lp_len_go(xs: List<&2, Loop>, fuel: Nat, acc: Nat) -> TRes:
  match xs:
    case Nil{}: tok_n(acc)
    case h <> t:
      match fuel:
        case 0n: terr(T.F_exhausted{})
        case 1n+f: lp_len_go(t, f, Nat.add(acc, 1n))

def lp_len(xs: List<&2, Loop>, fuel: Nat) -> TRes:
  lp_len_go(xs, fuel, 0n)

def lp_at(xs: List<&2, Loop>, idx: Nat, fuel: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match idx:
        case 0n: tok_lp(h)
        case 1n+m:
          match fuel:
            case 0n: terr(T.F_exhausted{})
            case 1n+f: lp_at(t, m, f)

def lp_resolve_pick(w: Loop, live: Bool) -> TRes:
  match live:
    case True{}: tok_lp(w)
    case False{}: terr(T.F_invalid{})

def lp_resolve_go(r: TRes, gen: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_lp{w}:
          Lp{+g, ces, kind} = w
          lp_resolve_pick(Lp{g, ces, kind}, U64.is_eq(g, gen))
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def lp_resolve(xs: List<&2, Loop>, h: HLoop,
    fuel: Nat) -> TRes:
  HL{idx, gen} = h
  lp_resolve_go(lp_at(xs, idx, fuel), gen)

def lp_handle_of_go(xs: List<&2, Loop>, +gen: U64, fuel: Nat,
    +idx: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match fuel:
        case 0n:
          Bool.pick(TRes, U64.is_eq(lp_gen(h), gen),
            tok_hlp(HL{idx, gen}), terr(T.F_exhausted{}))
        case 1n+f:
          Bool.pick(TRes, U64.is_eq(lp_gen(h), gen),
            tok_hlp(HL{idx, gen}),
            lp_handle_of_go(t, gen, f, Nat.add(idx, 1n)))

def lp_handle_of(xs: List<&2, Loop>, gen: U64,
    fuel: Nat) -> TRes:
  lp_handle_of_go(xs, gen, fuel, 0n)

def lp_issued_go(r: TRes, stamp: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_n{n}: tok_hlp(HL{n, U64.add(stamp, 1u64)})
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def lp_issued(b: Brep, fuel: Nat) -> TRes:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  lp_issued_go(lp_len(lps, fuel), stamp)

def lp_push_pick(vs: List<&2, Vertex>, es: List<&2, Edge>,
    ces0: List<&2, Coedge>, lps: List<&2, Loop>,
    fas: List<&2, Face>, shs: List<&2, Shell>,
    sos: List<&2, Solid>, top: Compound, +g: U64,
    ces: List<&2, HCoedge>, kind: LoopKind,
    ok: Bool) -> TRes:
  match ok:
    case False{}: terr(T.F_invalid{})
    case True{}:
      tok_brep(Br{vs, es, ces0,
        lp_snoc(lps, Lp{g, ces, kind}), fas, shs, sos,
        top, g})

def lp_push_go(b: Brep, ces: List<&2, HCoedge>,
    kind: LoopKind, ok: Bool) -> TRes:
  Br{vs, es, ces0, lps, fas, shs, sos, top, stamp} = b
  lp_push_pick(vs, es, ces0, lps, fas, shs, sos, top,
    U64.add(stamp, 1u64), ces, kind, ok)

def lp_push(b: Brep, +ces: List<&2, HCoedge>,
    +kind: LoopKind) -> TRes:
  lp_push_go(b, ces, kind, lp_valid(Lp{0u64, ces, kind}))

def fa_snoc(xs: List<&2, Face>, v: Face) -> List<&2, Face>:
  match xs:
    case Nil{}: v <> Nil{}
    case h <> t: h <> fa_snoc(t, v)

def fa_len_go(xs: List<&2, Face>, fuel: Nat, acc: Nat) -> TRes:
  match xs:
    case Nil{}: tok_n(acc)
    case h <> t:
      match fuel:
        case 0n: terr(T.F_exhausted{})
        case 1n+f: fa_len_go(t, f, Nat.add(acc, 1n))

def fa_len(xs: List<&2, Face>, fuel: Nat) -> TRes:
  fa_len_go(xs, fuel, 0n)

def fa_at(xs: List<&2, Face>, idx: Nat, fuel: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match idx:
        case 0n: tok_fa(h)
        case 1n+m:
          match fuel:
            case 0n: terr(T.F_exhausted{})
            case 1n+f: fa_at(t, m, f)

def fa_resolve_pick(w: Face, live: Bool) -> TRes:
  match live:
    case True{}: tok_fa(w)
    case False{}: terr(T.F_invalid{})

def fa_resolve_go(r: TRes, gen: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_fa{w}:
          Fa{+g, surf, loops, same} = w
          fa_resolve_pick(Fa{g, surf, loops, same},
            U64.is_eq(g, gen))
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def fa_resolve(xs: List<&2, Face>, h: HFace,
    fuel: Nat) -> TRes:
  HF{idx, gen} = h
  fa_resolve_go(fa_at(xs, idx, fuel), gen)

def fa_handle_of_go(xs: List<&2, Face>, +gen: U64, fuel: Nat,
    +idx: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match fuel:
        case 0n:
          Bool.pick(TRes, U64.is_eq(fa_gen(h), gen),
            tok_hfa(HF{idx, gen}), terr(T.F_exhausted{}))
        case 1n+f:
          Bool.pick(TRes, U64.is_eq(fa_gen(h), gen),
            tok_hfa(HF{idx, gen}),
            fa_handle_of_go(t, gen, f, Nat.add(idx, 1n)))

def fa_handle_of(xs: List<&2, Face>, gen: U64,
    fuel: Nat) -> TRes:
  fa_handle_of_go(xs, gen, fuel, 0n)

def fa_issued_go(r: TRes, stamp: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_n{n}: tok_hfa(HF{n, U64.add(stamp, 1u64)})
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def fa_issued(b: Brep, fuel: Nat) -> TRes:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  fa_issued_go(fa_len(fas, fuel), stamp)

def fa_push_pick(vs: List<&2, Vertex>, es: List<&2, Edge>,
    ces: List<&2, Coedge>, lps: List<&2, Loop>,
    fas: List<&2, Face>, shs: List<&2, Shell>,
    sos: List<&2, Solid>, top: Compound, +g: U64,
    surf: G.GVal, loops: List<&2, HLoop>, same: Bool,
    ok: Bool) -> TRes:
  match ok:
    case False{}: terr(T.F_invalid{})
    case True{}:
      tok_brep(Br{vs, es, ces, lps,
        fa_snoc(fas, Fa{g, surf, loops, same}), shs, sos,
        top, g})

def fa_push_go(b: Brep, surf: G.GVal,
    loops: List<&2, HLoop>, same: Bool, ok: Bool) -> TRes:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  fa_push_pick(vs, es, ces, lps, fas, shs, sos, top,
    U64.add(stamp, 1u64), surf, loops, same, ok)

def fa_push(b: Brep, +surf: G.GVal, +loops: List<&2, HLoop>,
    +same: Bool) -> TRes:
  fa_push_go(b, surf, loops, same,
    fa_valid(Fa{0u64, surf, loops, same}))

def sh_snoc(xs: List<&2, Shell>, v: Shell) -> List<&2, Shell>:
  match xs:
    case Nil{}: v <> Nil{}
    case h <> t: h <> sh_snoc(t, v)

def sh_len_go(xs: List<&2, Shell>, fuel: Nat, acc: Nat) -> TRes:
  match xs:
    case Nil{}: tok_n(acc)
    case h <> t:
      match fuel:
        case 0n: terr(T.F_exhausted{})
        case 1n+f: sh_len_go(t, f, Nat.add(acc, 1n))

def sh_len(xs: List<&2, Shell>, fuel: Nat) -> TRes:
  sh_len_go(xs, fuel, 0n)

def sh_at(xs: List<&2, Shell>, idx: Nat, fuel: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match idx:
        case 0n: tok_sh(h)
        case 1n+m:
          match fuel:
            case 0n: terr(T.F_exhausted{})
            case 1n+f: sh_at(t, m, f)

def sh_resolve_pick(w: Shell, live: Bool) -> TRes:
  match live:
    case True{}: tok_sh(w)
    case False{}: terr(T.F_invalid{})

def sh_resolve_go(r: TRes, gen: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_sh{w}:
          Sh{+g, faces, kind} = w
          sh_resolve_pick(Sh{g, faces, kind}, U64.is_eq(g, gen))
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def sh_resolve(xs: List<&2, Shell>, h: HShell,
    fuel: Nat) -> TRes:
  HS{idx, gen} = h
  sh_resolve_go(sh_at(xs, idx, fuel), gen)

def sh_handle_of_go(xs: List<&2, Shell>, +gen: U64, fuel: Nat,
    +idx: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match fuel:
        case 0n:
          Bool.pick(TRes, U64.is_eq(sh_gen(h), gen),
            tok_hsh(HS{idx, gen}), terr(T.F_exhausted{}))
        case 1n+f:
          Bool.pick(TRes, U64.is_eq(sh_gen(h), gen),
            tok_hsh(HS{idx, gen}),
            sh_handle_of_go(t, gen, f, Nat.add(idx, 1n)))

def sh_handle_of(xs: List<&2, Shell>, gen: U64,
    fuel: Nat) -> TRes:
  sh_handle_of_go(xs, gen, fuel, 0n)

def sh_issued_go(r: TRes, stamp: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_n{n}: tok_hsh(HS{n, U64.add(stamp, 1u64)})
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def sh_issued(b: Brep, fuel: Nat) -> TRes:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  sh_issued_go(sh_len(shs, fuel), stamp)

def sh_push_pick(vs: List<&2, Vertex>, es: List<&2, Edge>,
    ces: List<&2, Coedge>, lps: List<&2, Loop>,
    fas: List<&2, Face>, shs: List<&2, Shell>,
    sos: List<&2, Solid>, top: Compound, +g: U64,
    faces: List<&2, HFace>, kind: ShellKind,
    ok: Bool) -> TRes:
  match ok:
    case False{}: terr(T.F_invalid{})
    case True{}:
      tok_brep(Br{vs, es, ces, lps, fas,
        sh_snoc(shs, Sh{g, faces, kind}), sos, top, g})

def sh_push_go(b: Brep, faces: List<&2, HFace>,
    kind: ShellKind, ok: Bool) -> TRes:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  sh_push_pick(vs, es, ces, lps, fas, shs, sos, top,
    U64.add(stamp, 1u64), faces, kind, ok)

def sh_push(b: Brep, +faces: List<&2, HFace>,
    +kind: ShellKind) -> TRes:
  sh_push_go(b, faces, kind, sh_valid(Sh{0u64, faces, kind}))

def so_snoc(xs: List<&2, Solid>, v: Solid) -> List<&2, Solid>:
  match xs:
    case Nil{}: v <> Nil{}
    case h <> t: h <> so_snoc(t, v)

def so_len_go(xs: List<&2, Solid>, fuel: Nat, acc: Nat) -> TRes:
  match xs:
    case Nil{}: tok_n(acc)
    case h <> t:
      match fuel:
        case 0n: terr(T.F_exhausted{})
        case 1n+f: so_len_go(t, f, Nat.add(acc, 1n))

def so_len(xs: List<&2, Solid>, fuel: Nat) -> TRes:
  so_len_go(xs, fuel, 0n)

def so_at(xs: List<&2, Solid>, idx: Nat, fuel: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match idx:
        case 0n: tok_so(h)
        case 1n+m:
          match fuel:
            case 0n: terr(T.F_exhausted{})
            case 1n+f: so_at(t, m, f)

def so_resolve_pick(w: Solid, live: Bool) -> TRes:
  match live:
    case True{}: tok_so(w)
    case False{}: terr(T.F_invalid{})

def so_resolve_go(r: TRes, gen: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_so{w}:
          So{+g, outer, cavities} = w
          so_resolve_pick(So{g, outer, cavities},
            U64.is_eq(g, gen))
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def so_resolve(xs: List<&2, Solid>, h: HSolid,
    fuel: Nat) -> TRes:
  HSo{idx, gen} = h
  so_resolve_go(so_at(xs, idx, fuel), gen)

def so_handle_of_go(xs: List<&2, Solid>, +gen: U64, fuel: Nat,
    +idx: Nat) -> TRes:
  match xs:
    case Nil{}: terr(T.F_invalid{})
    case h <> t:
      match fuel:
        case 0n:
          Bool.pick(TRes, U64.is_eq(so_gen(h), gen),
            tok_hso(HSo{idx, gen}), terr(T.F_exhausted{}))
        case 1n+f:
          Bool.pick(TRes, U64.is_eq(so_gen(h), gen),
            tok_hso(HSo{idx, gen}),
            so_handle_of_go(t, gen, f, Nat.add(idx, 1n)))

def so_handle_of(xs: List<&2, Solid>, gen: U64,
    fuel: Nat) -> TRes:
  so_handle_of_go(xs, gen, fuel, 0n)

def so_issued_go(r: TRes, stamp: U64) -> TRes:
  match r:
    case Tok{v}:
      match v:
        case T_n{n}: tok_hso(HSo{n, U64.add(stamp, 1u64)})
        case _: terr(T.F_invalid{})
    case Terr{kind}: Terr{kind}

def so_issued(b: Brep, fuel: Nat) -> TRes:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  so_issued_go(so_len(sos, fuel), stamp)

def so_push_pick(vs: List<&2, Vertex>, es: List<&2, Edge>,
    ces: List<&2, Coedge>, lps: List<&2, Loop>,
    fas: List<&2, Face>, shs: List<&2, Shell>,
    sos: List<&2, Solid>, top: Compound, +g: U64,
    outer: HShell, cavities: List<&2, HShell>,
    ok: Bool) -> TRes:
  match ok:
    case False{}: terr(T.F_invalid{})
    case True{}:
      tok_brep(Br{vs, es, ces, lps, fas, shs,
        so_snoc(sos, So{g, outer, cavities}), top, g})

def so_push_go(b: Brep, outer: HShell,
    cavities: List<&2, HShell>, ok: Bool) -> TRes:
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp} = b
  so_push_pick(vs, es, ces, lps, fas, shs, sos, top,
    U64.add(stamp, 1u64), outer, cavities, ok)

def so_push(b: Brep, +outer: HShell,
    +cavities: List<&2, HShell>) -> TRes:
  so_push_go(b, outer, cavities,
    so_valid(So{0u64, outer, cavities}))

# --- Root replacement: total, structural. Liveness of the new top
# is brep_checked in ops.bend, not here. ---
def brep_set_top(b: Brep, top: Compound) -> Brep:
  Br{vs, es, ces, lps, fas, shs, sos, old, stamp} = b
  Br{vs, es, ces, lps, fas, shs, sos, top, stamp}
