# C06 first solid-building path: types for intent-checked solid ops,
# toleranced params, certified intervals, profiles, op graphs, lineage.
# Data + total predicates + shows + one result type. Builders: ops.bend.
# Graph evaluator: eval.bend. Contract: docs/c06-contract.md.
# Failure arms reuse C00 FailKind; every C06 failure also carries a
# Diag (what/where/why/fix, MASTER_PLAN §14 property 2).

import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty

# --- Diagnosis: what failed, where (lineage name), why (machine code),
# and the smallest known fix. Every Serr carries one. ---
type Diag is Data:
  Dg{ what: String, loc: String, why: String, fix: String }

def mk_diag(what: String, loc: String, why: String,
    fix: String) -> Diag:
  Dg{what, loc, why, fix}

def diag_show(d: Diag) -> String:
  Dg{+what, +loc, +why, +fix} = d
  what ++ " @ " ++ loc ++ " [" ++ why ++ "] fix: " ++ fix

def diag_null() -> Diag:
  Dg{"ok", "-", "-", "-"}

# --- Material effect class (MASTER_PLAN §14 property 4: checked intent).
# M_create builds a solid from nothing; M_add/M_remove change material;
# M_same preserves it (transforms, rebuilds). ---
type MatFx is Data:
  M_create{}
  M_add{}
  M_remove{}
  M_same{}

def matfx_tag(m: MatFx) -> U64:
  match m:
    case M_create{}: 0u64
    case M_add{}: 1u64
    case M_remove{}: 2u64
    case M_same{}: 3u64

def matfx_show(m: MatFx) -> String:
  match m:
    case M_create{}: "create"
    case M_add{}: "add"
    case M_remove{}: "remove"
    case M_same{}: "same"

def matfx_eq(a: MatFx, b: MatFx) -> Bool:
  U64.is_eq(matfx_tag(a), matfx_tag(b))

# --- Effect: measured outcome. fc/fm = faces created/modified,
# shells = shells in the published brep, holes = through-hole count. ---
type Effect is Data:
  Fx{ mat: MatFx, fc: Nat, fm: Nat, shells: Nat, holes: Nat }

def mk_fx(mat: MatFx, fc: Nat, fm: Nat, shells: Nat,
    holes: Nat) -> Effect:
  Fx{mat, fc, fm, shells, holes}

def fx_show(e: Effect) -> String:
  Fx{+mat, +fc, +fm, +shells, +holes} = e
  matfx_show(mat) ++ " fc=" ++ Nat.show(fc) ++ " fm=" ++
    Nat.show(fm) ++ " sh=" ++ Nat.show(shells) ++ " holes=" ++
    Nat.show(holes)

def fx_eq(a: Effect, b: Effect) -> Bool:
  Fx{+ma, +fa, +na, +sa, +ha} = a
  Fx{+mb, +fb, +nb, +sb, +hb} = b
  Bool.and(matfx_eq(ma, mb),
    Bool.and(Nat.is_eq(fa, fb),
      Bool.and(Nat.is_eq(na, nb),
        Bool.and(Nat.is_eq(sa, sb), Nat.is_eq(ha, hb)))))

# --- Intent: declared BEFORE the build; intent_check compares the
# measured effect against it. Any mismatch is a publish refusal. ---
type Intent is Data:
  In{ mat: MatFx, fc: Nat, fm: Nat, shells: Nat, holes: Nat }

def mk_intent(mat: MatFx, fc: Nat, fm: Nat, shells: Nat,
    holes: Nat) -> Intent:
  In{mat, fc, fm, shells, holes}

def intent_fx(i: Intent) -> Effect:
  In{+mat, +fc, +fm, +shells, +holes} = i
  Fx{mat, fc, fm, shells, holes}

def intent_mat(i: Intent) -> MatFx:
  In{+mat, +fc, +fm, +shells, +holes} = i
  mat

def intent_fc(i: Intent) -> Nat:
  In{+mat, +fc, +fm, +shells, +holes} = i
  fc

def intent_fm(i: Intent) -> Nat:
  In{+mat, +fc, +fm, +shells, +holes} = i
  fm

def intent_shells(i: Intent) -> Nat:
  In{+mat, +fc, +fm, +shells, +holes} = i
  shells

def intent_holes(i: Intent) -> Nat:
  In{+mat, +fc, +fm, +shells, +holes} = i
  holes

def intent_show(i: Intent) -> String:
  fx_show(intent_fx(i))

def intent_check(i: Intent, e: Effect) -> Bool:
  fx_eq(intent_fx(i), e)

# --- Toleranced dimension: nominal plus zone (MASTER_PLAN §14.6 seed).
# The zone is the certified envelope; evaluation over the zone is
# interval-certified (ops.bend). ---
type Dim is Data:
  Dm{ nom: F64, lo: F64, hi: F64 }

def mk_dm(nom: F64, lo: F64, hi: F64) -> Dim:
  Dm{nom, lo, hi}

def dm_valid(d: Dim) -> Bool:
  Dm{+nom, +lo, +hi} = d
  Bool.and(T.is_finite(nom),
    Bool.and(T.is_finite(lo),
      Bool.and(T.is_finite(hi),
        Bool.and(F64.is_le(lo, nom), F64.is_le(nom, hi)))))

def dm_valid_pos(d: Dim) -> Bool:
  Dm{+nom, +lo, +hi} = d
  Bool.and(dm_valid(d), F64.is_lt(0.0f64, lo))

def dm_show(d: Dim) -> String:
  Dm{+nom, +lo, +hi} = d
  F64.show(nom) ++ " [" ++ F64.show(lo) ++ "," ++
    F64.show(hi) ++ "]"

# --- Certified interval: lo <= hi, both finite. Arithmetic (ops.bend)
# rounds outward, so the interval encloses the true real result. ---
type Iv is Data:
  Iv{ lo: F64, hi: F64 }

def mk_iv(lo: F64, hi: F64) -> Iv:
  Iv{lo, hi}

def iv_valid(v: Iv) -> Bool:
  Iv{+lo, +hi} = v
  Bool.and(T.is_finite(lo),
    Bool.and(T.is_finite(hi), F64.is_le(lo, hi)))

def iv_show(v: Iv) -> String:
  Iv{+lo, +hi} = v
  "[" ++ F64.show(lo) ++ "," ++ F64.show(hi) ++ "]"

def iv_of_dm(d: Dim) -> Iv:
  Dm{+nom, +lo, +hi} = d
  Iv{lo, hi}

def iv_nom(d: Dim) -> Iv:
  Dm{+nom, +lo, +hi} = d
  Iv{nom, nom}

# --- Profile: straight-edge outer loop + straight-edge hole loops in
# sketch (x, y). Loops close implicitly (last connects to first).
# Curved (arc) profile edges are NOT admitted here: they need C07
# intersections for validation (contract §12). ---
type Prof is Data:
  Pf{ loop: List<&2, V.Vec2>, holes: List<&2, List<&2, V.Vec2>> }

def mk_prof(loop: List<&2, V.Vec2>,
    holes: List<&2, List<&2, V.Vec2>>) -> Prof:
  Pf{loop, holes}

def prof_show(p: Prof) -> String:
  Pf{+loop, +holes} = p
  "loop=" ++ Nat.show(List.length(&2, V.Vec2, loop)) ++
    " holes=" ++ Nat.show(List.length(&2, List<&2, V.Vec2>, holes))

# --- Round hole spec (rectangular pockets reuse profile hole loops). ---
type HoleSpec is Data:
  Hs{ x: F64, y: F64, r: F64 }

def mk_hole(x: F64, y: F64, r: F64) -> HoleSpec:
  Hs{x, y, r}

def hole_show(h: HoleSpec) -> String:
  Hs{+x, +y, +r} = h
  "hole(" ++ F64.show(x) ++ "," ++ F64.show(y) ++ "," ++
    F64.show(r) ++ ")"

# --- Boss record: pad footprint retained for hole-vs-boss checks. ---
type Boss is Data:
  Bo{ x: F64, y: F64, w: F64, d: F64, z0: F64, z1: F64 }

def mk_boss(x: F64, y: F64, w: F64, d: F64, z0: F64,
    z1: F64) -> Boss:
  Bo{x, y, w, d, z0, z1}

# --- Body: a built brep plus its recipe. kind tags: 0 = z-prism
# (caps perpendicular to z, surgery allowed), 1 = closed primitive,
# 2 = pad compound (base prism + bosses; base surgery allowed),
# 3 = transformed (no further surgery; xform last), 5 = forest
# compound (one solid per region; no surgery). rh retains round
# holes for rebuilds; dims retains primitive dims for measures. ---
type Body is Data:
  Bd{ brep: Ty.Brep, kind: U64, prof: Prof, z0: F64, z1: F64,
    boss: List<&2, Boss>, nhole: Nat, rh: List<&2, HoleSpec>,
    dims: List<&2, F64> }

def mk_body(brep: Ty.Brep, kind: U64, prof: Prof, z0: F64,
    z1: F64, boss: List<&2, Boss>, nhole: Nat,
    rh: List<&2, HoleSpec>, dims: List<&2, F64>) -> Body:
  Bd{brep, kind, prof, z0, z1, boss, nhole, rh, dims}

def body_brep(b: Body) -> Ty.Brep:
  Bd{+brep, +kind, +prof, +z0, +z1, +boss, +nhole, +rh,
    +dims} = b
  brep

def body_kind(b: Body) -> U64:
  Bd{+brep, +kind, +prof, +z0, +z1, +boss, +nhole, +rh,
    +dims} = b
  kind

def body_show(b: Body) -> String:
  Bd{+brep, +kind, +prof, +z0, +z1, +boss, +nhole, +rh,
    +dims} = b
  "kind=" ++ U64.show(kind) ++ " z=[" ++ F64.show(z0) ++
    "," ++ F64.show(z1) ++ "] holes=" ++ Nat.show(nhole) ++
    " boss=" ++ Nat.show(List.length(&2, Boss, boss)) ++
    " V=" ++ Nat.show(List.length(&2, Ty.Vertex, Ty.brep_vs(brep))) ++
    " E=" ++ Nat.show(List.length(&2, Ty.Edge, Ty.brep_es(brep))) ++
    " F=" ++ Nat.show(List.length(&2, Ty.Face, Ty.brep_fas(brep)))

# --- Measure: certified volume/area intervals + exact bbox corners +
# entity counts. Labeled certified only over the interval arithmetic
# and the stated pi enclosure (contract §7); sampling is separate. ---
type Measure is Data:
  Ms{ vol: Iv, area: Iv, blo: V.Point, bhi: V.Point, nv: Nat,
    ne: Nat, nf: Nat }

def mk_ms(vol: Iv, area: Iv, blo: V.Point, bhi: V.Point,
    nv: Nat, ne: Nat, nf: Nat) -> Measure:
  Ms{vol, area, blo, bhi, nv, ne, nf}

def ms_show(m: Measure) -> String:
  Ms{+vol, +area, +blo, +bhi, +nv, +ne, +nf} = m
  "vol=" ++ iv_show(vol) ++ " area=" ++ iv_show(area) ++
    " n=" ++ Nat.show(nv) ++ "/" ++ Nat.show(ne) ++ "/" ++
    Nat.show(nf)

def ms_vol(m: Measure) -> Iv:
  Ms{+vol, +area, +blo, +bhi, +nv, +ne, +nf} = m
  vol

def ms_area(m: Measure) -> Iv:
  Ms{+vol, +area, +blo, +bhi, +nv, +ne, +nf} = m
  area

def ms_blo(m: Measure) -> V.Point:
  Ms{+vol, +area, +blo, +bhi, +nv, +ne, +nf} = m
  blo

def ms_bhi(m: Measure) -> V.Point:
  Ms{+vol, +area, +blo, +bhi, +nv, +ne, +nf} = m
  bhi

def ms_nv(m: Measure) -> Nat:
  Ms{+vol, +area, +blo, +bhi, +nv, +ne, +nf} = m
  nv

def ms_ne(m: Measure) -> Nat:
  Ms{+vol, +area, +blo, +bhi, +nv, +ne, +nf} = m
  ne

def ms_nf(m: Measure) -> Nat:
  Ms{+vol, +area, +blo, +bhi, +nv, +ne, +nf} = m
  nf

# --- Op algebra. Param-carrying ops name Dim ids; structural ops name
# input node ids. Profiles are inline content (part of the hash). ---
type Op is Data:
  O_box{ w: U64, h: U64, d: U64 }
  O_cyl{ r: U64, h: U64 }
  O_sph{ r: U64 }
  O_cone{ r: U64, h: U64 }
  O_tor{ bigR: U64, r: U64 }
  O_extrude{ prof: Prof, depth: U64 }
  O_revolve{ prof: Prof }
  O_holes{ base: U64, hs: List<&2, HoleSpec> }
  O_pocket{ base: U64, x: F64, y: F64, w: F64, h: F64,
    depth: U64 }
  O_pad{ base: U64, x: F64, y: F64, w: U64, h: U64,
    d: U64 }
  O_xform{ base: U64, xf: V.Rigid }

def op_tag(o: Op) -> U64:
  match o:
    case O_box{w, h, d}: 1u64
    case O_cyl{r, h}: 2u64
    case O_sph{r}: 3u64
    case O_cone{r, h}: 4u64
    case O_tor{bigR, r}: 5u64
    case O_extrude{prof, depth}: 6u64
    case O_revolve{prof}: 7u64
    case O_holes{base, hs}: 8u64
    case O_pocket{base, x, y, w, h, depth}: 9u64
    case O_pad{base, x, y, w, h, d}: 10u64
    case O_xform{base, xf}: 11u64

def op_show(o: Op) -> String:
  match o:
    case O_box{w, h, d}: "box"
    case O_cyl{r, h}: "cyl"
    case O_sph{r}: "sph"
    case O_cone{r, h}: "cone"
    case O_tor{bigR, r}: "torus"
    case O_extrude{prof, depth}: "extrude"
    case O_revolve{prof}: "revolve"
    case O_holes{base, hs}: "holes"
    case O_pocket{base, x, y, w, h, depth}: "pocket"
    case O_pad{base, x, y, w, h, d}: "pad"
    case O_xform{base, xf}: "xform"

# --- Param + Node + Part: the content-addressed op graph (§14.5).
# Node ids are content hashes (eval.bend); the graph, not the program
# text, is canonical. ---
type Param is Data:
  Pm{ id: U64, dim: Dim }

def mk_param(id: U64, dim: Dim) -> Param:
  Pm{id, dim}

type Node is Data:
  Nd{ id: U64, op: Op, ins: List<&2, U64> }

def mk_node(id: U64, op: Op, ins: List<&2, U64>) -> Node:
  Nd{id, op, ins}

def node_show(n: Node) -> String:
  Nd{+id, +op, +ins} = n
  "n" ++ U64.show(id) ++ ":" ++ op_show(op)

type Part is Data:
  Pt{ params: List<&2, Param>, nodes: List<&2, Node>,
    root: U64 }

def mk_part(params: List<&2, Param>, nodes: List<&2, Node>,
    root: U64) -> Part:
  Pt{params, nodes, root}

def part_empty() -> Part:
  Pt{[], [], 0u64}

# --- Evaluated node value (memo entry): node id + build hash +
# body + measured effect. Rebuild reuses the entry iff the build
# hash is unchanged (eval.bend). ---
type Built is Data:
  Bt{ id: U64, hash: U64, body: Body, fx: Effect }

def mk_built(id: U64, hash: U64, body: Body,
    fx: Effect) -> Built:
  Bt{id, hash, body, fx}

type Cache is Data:
  Cc{ items: List<&2, Built> }

def cache_empty() -> Cache:
  Cc{[]}

# --- Lineage name (§14.3): creator node + role + ordinal. Roles:
# 0 face, 1 edge, 2 vertex, 3 solid, 4 hole wall, 5 boss, 6 cap. ---
type Nm is Data:
  Nm{ node: U64, role: U64, idx: Nat }

def mk_nm(node: U64, role: U64, idx: Nat) -> Nm:
  Nm{node, role, idx}

def nm_show(n: Nm) -> String:
  Nm{+node, +role, +idx} = n
  "n" ++ U64.show(node) ++ ".r" ++ U64.show(role) ++ "#" ++
    Nat.show(idx)

# --- One value union, one result type: every fallible C06 op returns
# SRes carrying either a value or a FailKind plus a Diag. ---
type SVal is Data:
  SV_brep{ v: Ty.Brep }
  SV_body{ v: Body }
  SV_fx{ v: Effect }
  SV_ms{ v: Measure }
  SV_part{ v: Part }
  SV_iv{ v: Iv }
  SV_u{ v: U64 }
  SV_s{ v: String }

type SRes is Data:
  Sok{ v: SVal }
  Serr{ kind: T.FailKind, diag: Diag }

def sok_brep(v: Ty.Brep) -> SRes:
  Sok{SV_brep{v}}

def sok_body(v: Body) -> SRes:
  Sok{SV_body{v}}

def sok_fx(v: Effect) -> SRes:
  Sok{SV_fx{v}}

def sok_ms(v: Measure) -> SRes:
  Sok{SV_ms{v}}

def sok_part(v: Part) -> SRes:
  Sok{SV_part{v}}

def sok_iv(v: Iv) -> SRes:
  Sok{SV_iv{v}}

def sok_u(v: U64) -> SRes:
  Sok{SV_u{v}}

def sok_s(v: String) -> SRes:
  Sok{SV_s{v}}

def serr(kind: T.FailKind, diag: Diag) -> SRes:
  Serr{kind, diag}

def serr_invalid(what: String, loc: String, why: String,
    fix: String) -> SRes:
  Serr{T.F_invalid{}, Dg{what, loc, why, fix}}

def serr_uncertain(what: String, loc: String, why: String,
    fix: String) -> SRes:
  Serr{T.F_uncertain{}, Dg{what, loc, why, fix}}

def serr_unsupported(what: String, loc: String, why: String,
    fix: String) -> SRes:
  Serr{T.F_unsupported{}, Dg{what, loc, why, fix}}

def serr_exhausted(what: String, loc: String, why: String,
    fix: String) -> SRes:
  Serr{T.F_exhausted{}, Dg{what, loc, why, fix}}

def sres_ok(r: SRes) -> Bool:
  match r:
    case Sok{v}: True{}
    case Serr{kind, diag}: False{}

def sres_show(r: SRes) -> String:
  match r:
    case Sok{v}: "ok"
    case Serr{kind, diag}: T.FailKind.show(kind)

def sres_diag(r: SRes) -> Diag:
  match r:
    case Sok{v}: diag_null()
    case Serr{kind, diag}: diag

def sres_kind(r: SRes) -> T.FailKind:
  match r:
    case Sok{v}: T.F_invalid{}
    case Serr{kind, diag}: kind

# Total projectors with documented defaults (mirror C04 tres_*:
# gate on sres_ok/sres_show first). Defaults carry no claim.
def sok_def_body() -> Body:
  Bd{Ty.brep_empty(), 3u64, Pf{[], []}, 0.0f64, 0.0f64, [],
    0n, [], []}

def sok_brep_of(r: SRes) -> Ty.Brep:
  match r:
    case Sok{v}:
      match v:
        case SV_brep{w}: w
        case _: Ty.brep_empty()
    case Serr{kind, diag}: Ty.brep_empty()

def sok_body_of(r: SRes) -> Body:
  match r:
    case Sok{v}:
      match v:
        case SV_body{w}: w
        case _: sok_def_body()
    case Serr{kind, diag}: sok_def_body()

def sok_fx_of(r: SRes) -> Effect:
  match r:
    case Sok{v}:
      match v:
        case SV_fx{w}: w
        case _: Fx{M_same{}, 0n, 0n, 0n, 0n}
    case Serr{kind, diag}: Fx{M_same{}, 0n, 0n, 0n, 0n}

def sok_ms_of(r: SRes) -> Measure:
  match r:
    case Sok{v}:
      match v:
        case SV_ms{w}: w
        case _:
          Ms{Iv{0.0f64, 0.0f64}, Iv{0.0f64, 0.0f64},
            V.Pt{0.0f64, 0.0f64, 0.0f64},
            V.Pt{0.0f64, 0.0f64, 0.0f64}, 0n, 0n, 0n}
    case Serr{kind, diag}:
      Ms{Iv{0.0f64, 0.0f64}, Iv{0.0f64, 0.0f64},
        V.Pt{0.0f64, 0.0f64, 0.0f64},
        V.Pt{0.0f64, 0.0f64, 0.0f64}, 0n, 0n, 0n}

def sok_part_of(r: SRes) -> Part:
  match r:
    case Sok{v}:
      match v:
        case SV_part{w}: w
        case _: part_empty()
    case Serr{kind, diag}: part_empty()

def sok_iv_of(r: SRes) -> Iv:
  match r:
    case Sok{v}:
      match v:
        case SV_iv{w}: w
        case _: Iv{0.0f64, 0.0f64}
    case Serr{kind, diag}: Iv{0.0f64, 0.0f64}

def sok_u_of(r: SRes) -> U64:
  match r:
    case Sok{v}:
      match v:
        case SV_u{w}: w
        case _: 0u64
    case Serr{kind, diag}: 0u64

def sok_s_of(r: SRes) -> String:
  match r:
    case Sok{v}:
      match v:
        case SV_s{w}: w
        case _: ""
    case Serr{kind, diag}: ""
