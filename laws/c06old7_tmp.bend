# C06 laws: intent-checked solid builders over C00-C05.
# Contract: docs/c06-contract.md. Convention: laws/c05.bend
# (ground pins ok_/neg_ plus quantified definitional laws).

import Base
import ../src/c00/types.bend as T
import ../src/c01/types.bend as V
import ../src/c03/types.bend as G
import ../src/c04/types.bend as Ty
import ../src/c06/types.bend as Y
import ../src/c06/ops.bend as O
import ../src/c06/eval.bend as EV
import ../src/c06/surfx.bend as SX

def sq_loop() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{1.0f64, 1.0f64}, V.V2{0.0f64, 1.0f64}]

def bow_loop() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 1.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}]

def cw_loop() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}, V.V2{1.0f64, 1.0f64}, V.V2{1.0f64, 0.0f64}]

def spike_loop() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{1.0f64, 1.0f64}]

def touch_loop() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{3.0f64, 0.0f64}, V.V2{3.0f64, 3.0f64}, V.V2{2.0f64, 3.0f64},
    V.V2{2.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{1.0f64, 3.0f64}, V.V2{0.0f64, 3.0f64}]

def cross_loop() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, 0.0f64}, V.V2{2.0f64, 2.0f64}, V.V2{3.0f64, 2.0f64},
    V.V2{3.0f64, 1.0f64}, V.V2{0.0f64, 1.0f64}]

def outer_loop() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{10.0f64, 0.0f64}, V.V2{10.0f64, 10.0f64}, V.V2{0.0f64, 10.0f64}]

def hole_a() -> List<&2, V.Vec2>:
  [V.V2{1.0f64, 1.0f64}, V.V2{1.0f64, 9.0f64}, V.V2{9.0f64, 9.0f64}, V.V2{9.0f64, 1.0f64}]

def hole_b() -> List<&2, V.Vec2>:
  [V.V2{2.0f64, 2.0f64}, V.V2{2.0f64, 3.0f64}, V.V2{3.0f64, 3.0f64}, V.V2{3.0f64, 2.0f64}]

def hole_c() -> List<&2, V.Vec2>:
  [V.V2{4.0f64, 4.0f64}, V.V2{4.0f64, 5.0f64}, V.V2{5.0f64, 5.0f64}, V.V2{5.0f64, 4.0f64}]

def hole_d() -> List<&2, V.Vec2>:
  [V.V2{0.5f64, 0.5f64}, V.V2{0.5f64, 2.0f64}, V.V2{5.0f64, 2.0f64}, V.V2{5.0f64, 0.5f64}]

def hole_f() -> List<&2, V.Vec2>:
  [V.V2{20.0f64, 20.0f64}, V.V2{20.0f64, 21.0f64}, V.V2{21.0f64, 21.0f64}, V.V2{21.0f64, 20.0f64}]

def hole_t() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 2.0f64}, V.V2{2.0f64, 2.0f64}, V.V2{2.0f64, 0.0f64}]

def rev_sq() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, 0.0f64}, V.V2{2.0f64, 1.0f64}, V.V2{0.0f64, 1.0f64}]

def rev_tri() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 1.0f64}, V.V2{0.0f64, 2.0f64}]

def rev_below() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, F64.neg(1.0f64)}, V.V2{2.0f64, F64.neg(1.0f64)},
    V.V2{2.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64}]

def rev_mid() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 2.0f64}, V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 1.0f64}, V.V2{0.0f64, 3.0f64}]

def rev_last() -> List<&2, V.Vec2>:
  [V.V2{1.0f64, 1.0f64}, V.V2{0.0f64, 1.0f64}, V.V2{0.0f64, 0.0f64}]

def rev_hole_ax() -> List<&2, V.Vec2>:
  [V.V2{1.0f64, 0.0f64}, V.V2{2.0f64, 1.0f64}, V.V2{3.0f64, 0.0f64}]

def rev_hole_ok() -> List<&2, V.Vec2>:
  [V.V2{1.0f64, 1.0f64}, V.V2{2.0f64, 1.0f64}, V.V2{1.0f64, 2.0f64}]

def dup_pts(n: Nat) -> List<&2, V.Vec2>:
  match n:
    case 0n: []
    case 1n+m: V.V2{0.0f64, 0.0f64} <> dup_pts(m)

def nth_vx(xs: List<&2, Ty.Vertex>, i: Nat) -> Ty.Vertex:
  match xs:
    case Nil{}: Ty.Vx{0u64, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_vx(t, j)

def nth_ed(xs: List<&2, Ty.Edge>, i: Nat) -> Ty.Edge:
  match xs:
    case Nil{}: Ty.Ed{0u64, Ty.mk_hv(0n, 0u64), Ty.mk_hv(0n, 0u64), Ty.EK_degenerate{}}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_ed(t, j)

def nth_ce(xs: List<&2, Ty.Coedge>, i: Nat) -> Ty.Coedge:
  match xs:
    case Nil{}: Ty.Ce{0u64, Ty.mk_he(0n, 0u64), True{}, G.GV_f{0.0f64}}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_ce(t, j)

def nth_lp(xs: List<&2, Ty.Loop>, i: Nat) -> Ty.Loop:
  match xs:
    case Nil{}: Ty.Lp{0u64, [], Ty.LK_outer{}}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_lp(t, j)

def nth_fa(xs: List<&2, Ty.Face>, i: Nat) -> Ty.Face:
  match xs:
    case Nil{}: Ty.Fa{0u64, G.GV_f{0.0f64}, [], True{}}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_fa(t, j)

def nth_sh(xs: List<&2, Ty.Shell>, i: Nat) -> Ty.Shell:
  match xs:
    case Nil{}: Ty.Sh{0u64, [], Ty.SK_outer{}}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_sh(t, j)

def nth_so(xs: List<&2, Ty.Solid>, i: Nat) -> Ty.Solid:
  match xs:
    case Nil{}: Ty.So{0u64, Ty.mk_hsh(0n, 0u64), []}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_so(t, j)

def nm_nth(xs: List<&2, Y.Nm>, i: Nat) -> Y.Nm:
  match xs:
    case Nil{}: Y.mk_nm(0u64, 9u64, 0n)
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nm_nth(t, j)

def ev_last2(er: EV.EvRes) -> Y.SRes:
  match er:
    case EV.EV{cc, last}: last

def ev_cc2(er: EV.EvRes) -> Y.Cache:
  match er:
    case EV.EV{cc, last}: cc

def ev_body(er: EV.EvRes) -> Y.Body:
  match er:
    case EV.EV{cc, last}: Y.sok_body_of(last)

def bd_z0(b: Y.Body) -> F64:
  match b:
    case Y.Bd{brep, kind, prof, z0, z1, boss, nhole, rh, dims}: z0

def bd_z1(b: Y.Body) -> F64:
  match b:
    case Y.Bd{brep, kind, prof, z0, z1, boss, nhole, rh, dims}: z1

def bd_dims(b: Y.Body) -> List<&2, F64>:
  match b:
    case Y.Bd{brep, kind, prof, z0, z1, boss, nhole, rh, dims}: dims

def dims_are_9(xs: List<&2, F64>) -> Bool:
  match xs:
    case a <> b <> c <> Nil{}:
      Bool.and(F64.is_eq(a, 9.0f64), Bool.and(F64.is_eq(b, 9.0f64), F64.is_eq(c, 9.0f64)))
    case _: False{}

def stale_dims_ok(er: EV.EvRes) -> Bool:
  dims_are_9(bd_dims(ev_body(er)))

def box318(r: Y.SRes) -> Bool:
  match r:
    case Y.Serr{k, dg}: False{}
    case Y.Sok{v}:
      match v:
        case Y.SV_brep{+b}:
          Bool.and(Nat.is_eq(List.length(&2, Ty.Vertex, Ty.brep_vs(b)), 8n),
            Bool.and(Nat.is_eq(List.length(&2, Ty.Edge, Ty.brep_es(b)), 12n),
              Nat.is_eq(List.length(&2, Ty.Face, Ty.brep_fas(b)), 6n)))
        case _: False{}

def boxcounts7(+b: Ty.Brep) -> Bool:
  Bool.and(Nat.is_eq(List.length(&2, Ty.Vertex, Ty.brep_vs(b)), 8n),
    Bool.and(Nat.is_eq(List.length(&2, Ty.Edge, Ty.brep_es(b)), 12n),
      Bool.and(Nat.is_eq(List.length(&2, Ty.Coedge, Ty.brep_ces(b)), 24n),
        Bool.and(Nat.is_eq(List.length(&2, Ty.Loop, Ty.brep_lps(b)), 6n),
          Bool.and(Nat.is_eq(List.length(&2, Ty.Face, Ty.brep_fas(b)), 6n),
            Bool.and(Nat.is_eq(List.length(&2, Ty.Shell, Ty.brep_shs(b)), 1n),
              Nat.is_eq(List.length(&2, Ty.Solid, Ty.brep_sos(b)), 1n)))))))

def root318(er: EV.EvRes) -> Bool:
  match er:
    case EV.EV{cc, last}:
      match last:
        case Y.Serr{k, dg}: False{}
        case Y.Sok{v}:
          match v:
            case Y.SV_body{+b}:
              +bb = Y.body_brep(b)
              Bool.and(Nat.is_eq(List.length(&2, Ty.Vertex, Ty.brep_vs(bb)), 8n),
                Bool.and(Nat.is_eq(List.length(&2, Ty.Edge, Ty.brep_es(bb)), 12n),
                  Nat.is_eq(List.length(&2, Ty.Face, Ty.brep_fas(bb)), 6n)))
            case _: False{}

def part1() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
      Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
      Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [])], 7u64)

def part_baddim() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [])], 7u64)

def part_badroot() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
      Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
      Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [])], 99u64)

def part_cyl() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
      Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64))],
    [Y.mk_node(7u64, Y.O_cyl{1u64, 2u64}, [])], 7u64)

def part_ff1() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 9u64, 9u64}, []), Y.mk_node(8u64, Y.O_cyl{1u64, 1u64}, [])], 8u64)

def part_ff2() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
      Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
      Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, []), Y.mk_node(8u64, Y.O_cyl{1u64, 1u64}, [])], 8u64)

def pchg0() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 1u64, 1u64}, [])], 7u64)

def pchg() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(9.0f64, 0.5f64, 20.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 1u64, 1u64}, [])], 7u64)

def unit_box() -> Ty.Brep:
  O.box_core(0.0f64, 0.0f64, 0.0f64, 1.0f64, 2.0f64, 3.0f64)

def id_rigid() -> V.Rigid:
  V.Rg{V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64},
    0.0f64, 0.0f64, 0.0f64}

def org() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def axis_z() -> V.Dir:
  V.Dr{0.0f64, 0.0f64, 1.0f64}

# --- A. Result protocol (contract §1). ---


law sres_kind_of:
  for k: T.FailKind
  for dg: Y.Diag
  {Y.sres_kind(Y.Serr{k, dg}) == k : T.FailKind}

def sres_kind_of(k, dg):
  {==}


law matfx_show_add:
  {Y.matfx_show(Y.M_add{}) == "add" : String}

def matfx_show_add():
  {==}


law intent_show_pin:
  {Y.intent_show(Y.mk_intent(Y.M_add{}, 1n, 2n, 1n, 3n)) == "add fc=1 fm=2 sh=1 holes=3" : String}

def intent_show_pin():
  {==}

# --- B. Intent, toleranced dims, certified intervals (types). ---


law dm_valid_zone:
  {Y.dm_valid(Y.mk_dm(1.0f64, 2.0f64, 3.0f64)) == False{} : Bool}

def dm_valid_zone():
  {==}


law iv_nom_pin:
  {Y.iv_nom(Y.mk_dm(1.0f64, 0.5f64, 2.0f64)) == Y.Iv{1.0f64, 1.0f64} : Y.Iv}

def iv_nom_pin():
  {==}


law op_tag_cone:
  {Y.op_tag(Y.O_cone{1u64, 2u64}) == 4u64 : U64}

def op_tag_cone():
  {==}


law op_show_box:
  {Y.op_show(Y.O_box{1u64, 2u64, 3u64}) == "box" : String}

def op_show_box():
  {==}


law neg_iv_div_zero:
  {Y.sres_show(O.iv_div(Y.Iv{6.0f64, 6.0f64}, Y.Iv{F64.neg(1.0f64), 1.0f64}))
    == "numerical-uncertainty" : String}

def neg_iv_div_zero():
  {==}


law neg_iv_gate_nan:
  {Y.sres_show(O.iv_gate(F64.nan(), 1.0f64)) == "numerical-uncertainty" : String}

def neg_iv_gate_nan():
  {==}


law neg_prof_bowtie:
  {O.prof_code(bow_loop(), [], 1000n) == 4u64 : U64}

def neg_prof_bowtie():
  {==}


law neg_prof_looptouch:
  {O.prof_code(outer_loop(), [hole_t()], 100000n) == 10u64 : U64}

def neg_prof_looptouch():
  {==}


law neg_prof_hole_short:
  {O.prof_code(outer_loop(), [[V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 1.0f64}]], 100000n)
    == 1u64 : U64}

def neg_prof_hole_short():
  {==}


law pip_empty:
  for px: F64
  for py: F64
  for fuel: Nat
  {O.pip(px, py, [], fuel) == 0u64 : U64}

def pip_empty(px, py, fuel):
  {==}

# --- G. Small validator helpers. ---


law ok_prof_go_zero:
  {Y.sok_u_of(O.prof_go(0u64, "profile")) == 0u64 : U64}

def ok_prof_go_zero():
  {==}


law neg_prof_go_spike:
  {Y.sres_show(O.prof_go(8u64, "profile")) == "invalid-input" : String}

def neg_prof_go_spike():
  {==}


law neg_prof_go_hoax:
  {Y.sres_show(O.prof_go(16u64, "revolve")) == "invalid-input" : String}

def neg_prof_go_hoax():
  {==}


law neg_prof_go_blind:
  {Y.sres_show(O.prof_go(24u64, "profile")) == "unsupported-op" : String}

def neg_prof_go_blind():
  {==}


law ok_rev_ax:
  {O.rev_ax(rev_sq(), 100000n) == 0u64 : U64}

def ok_rev_ax():
  {==}


law neg_rev_prof_cross:
  {Y.sres_show(O.prof_valid_rev(Y.mk_prof(rev_below(), []), 100000n))
    == "invalid-input" : String}

def neg_rev_prof_cross():
  {==}

# --- J. Hole clearance and footprints. ---


law neg_hole_rect:
  {O.hole_rect(0.0f64, 0.0f64, 5.0f64, F64.neg(1.0f64), F64.neg(1.0f64), 1.0f64, 1.0f64)
    == 21u64 : U64}

def neg_hole_rect():
  {==}


law neg_box_nan:
  {Y.sres_show(O.box_checked(0.0f64, 0.0f64, 0.0f64, 1.0f64, 2.0f64, F64.nan(), 10000n))
    == "invalid-input" : String}

def neg_box_nan():
  {==}


law ok_box_gen_ed:
  {Ty.ed_gen(nth_ed(Ty.brep_es(unit_box()), 0n)) == 9u64 : U64}

def ok_box_gen_ed():
  {==}


law neg_box_pos_zero:
  {O.box_pos(0.0f64, 2.0f64, 3.0f64) == False{} : Bool}

def neg_box_pos_zero():
  {==}


law neg_stage_owner:
  {Y.sres_show(O.stage_go(6u64)) == "invalid-input" : String}

def neg_stage_owner():
  {==}


law neg_stage_fuel_lo:
  {Y.sres_show(O.stage_ex(102u64)) == "resource-exhausted" : String}

def neg_stage_fuel_lo():
  {==}


law ok_att3_all:
  {O.att3(3n, 3n, 3n, 1u64) == 0u64 : U64}

def ok_att3_all():
  {==}


law neg_bulk_c_terr:
  {Y.sres_show(O.bulk_c(Ty.Terr{T.F_invalid{}}, unit_box(), 10000n))
    == "resource-exhausted" : String}

def neg_bulk_c_terr():
  {==}


law node_hash_tor:
  for a: U64
  for r: U64
  for ps: List<&2, Y.Param>
  {EV.node_hash(Y.O_tor{a, r}, ps) == 5u64 : U64}

def node_hash_tor(a, r, ps):
  {==}


law ok_pm_hit:
  {EV.pm_hit_go([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64))], 1u64)
    == True{} : Bool}

def ok_pm_hit():
  {==}


law neg_cc_find_miss:
  {EV.cc_find_id0([EV.bt_dummy()], [], 9u64)
    == EV.CO{False{}, EV.bt_dummy(), [EV.bt_dummy()]} : EV.CcOut}

def neg_cc_find_miss():
  {==}


law ok_eval_stale_rebuild:
  {stale_dims_ok(EV.ev_part(pchg(), ev_cc2(EV.ev_part(pchg0(), Y.cache_empty(), 10000n)),
    10000n)) == True{} : Bool}

def ok_eval_stale_rebuild():
  {==}


law ok_eval_origin_z1:
  {bd_z1(ev_body(EV.ev_part(part1(), Y.cache_empty(), 10000n))) == 3.0f64 : F64}

def ok_eval_origin_z1():
  {==}

# Pending builders fail closed (contract §7: no stub returns success).


law neg_evop_pocket:
  {Y.sres_show(EV.ev_op(Y.O_pocket{7u64, 0.0f64, 0.0f64, 1.0f64, 1.0f64, 2u64}, [], 10n))
    == "unsupported-op" : String}

def neg_evop_pocket():
  {==}


law neg_gate_holes:
  {Y.sres_show(EV.gate_publish(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_intent(Y.M_create{}, 6n, 0n, 1n, 1n))) == "invalid-input" : String}

def neg_gate_holes():
  {==}


law ok_t_in11:
  {SX.t_in11(0.0f64) == True{} : Bool}

def ok_t_in11():
  {==}


law ok_spine:
  {SX.spine_c(1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 1.0f64, 10.0f64)
    == V.Pt{1.0f64, 2.0f64, 13.0f64} : V.Point}

def ok_spine():
  {==}


law ok_surf_sph_east:
  {SX.surf_sph(G.Sp{org(), 2.0f64}, 1.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{2.0f64, 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_sph_east():
  {==}


law ok_ring_cyl:
  {SX.ring_cyl(G.Cy{org(), axis_z(), 2.0f64}, 3.0f64)
    == G.Gok{G.GV_cc{G.Cc{V.Pt{0.0f64, 0.0f64, 3.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 1.0f64, 0.0f64}, 2.0f64}}} : G.GRes}

def ok_ring_cyl():
  {==}

