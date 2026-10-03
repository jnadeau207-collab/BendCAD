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


law sok_is_ok:
  for v: Y.SVal
  {Y.sres_ok(Y.Sok{v}) == True{} : Bool}

def sok_is_ok(v):
  {==}


law sres_diag_ok:
  for v: Y.SVal
  {Y.sres_diag(Y.Sok{v}) == Y.diag_null() : Y.Diag}

def sres_diag_ok(v):
  {==}


law matfx_show_remove:
  {Y.matfx_show(Y.M_remove{}) == "remove" : String}

def matfx_show_remove():
  {==}


law intent_fx_rt:
  for m: Y.MatFx
  for fc: Nat
  for fm: Nat
  for sh: Nat
  for ho: Nat
  {Y.intent_fx(Y.mk_intent(m, fc, fm, sh, ho)) == Y.mk_fx(m, fc, fm, sh, ho) : Y.Effect}

def intent_fx_rt(m, fc, fm, sh, ho):
  {==}


law dm_valid_nan:
  {Y.dm_valid(Y.mk_dm(F64.nan(), 0.0f64, 1.0f64)) == False{} : Bool}

def dm_valid_nan():
  {==}


law prof_show_pin:
  {Y.prof_show(Y.mk_prof(sq_loop(), [])) == "loop=4 holes=0" : String}

def prof_show_pin():
  {==}

# NOTE: hole_show/body_show/ms_show render through the native F64.show,
# which the proof checker leaves symbolic, so no {==} pin can state
# their output. Their structural content is covered by ok_box_counts,
# ok_fx_of_body, and the dim/interval pins instead.


law op_tag_tor:
  {Y.op_tag(Y.O_tor{1u64, 2u64}) == 5u64 : U64}

def op_tag_tor():
  {==}


law op_show_torus:
  {Y.op_show(Y.O_tor{1u64, 2u64}) == "torus" : String}

def op_show_torus():
  {==}


law ok_iv_neg:
  {O.iv_neg(Y.Iv{1.0f64, 2.0f64}) == Y.Iv{F64.neg(2.0f64), F64.neg(1.0f64)} : Y.Iv}

def ok_iv_neg():
  {==}


law ok_next_up_zero:
  {O.f64_next_up(0.0f64) == F64{1u64} : F64}

def ok_next_up_zero():
  {==}


law neg_prof_clockwise:
  {O.prof_code(cw_loop(), [], 1000n) == 5u64 : U64}

def neg_prof_clockwise():
  {==}


law neg_prof_nest_ab:
  {O.prof_code(outer_loop(), [hole_a(), hole_b()], 100000n) == 12u64 : U64}

def neg_prof_nest_ab():
  {==}


law ok_sh_ccw:
  {O.sh_sign(sq_loop(), 100n) == 1u64 : U64}

def ok_sh_ccw():
  {==}


law pick_nz_zero:
  for b: U64
  {O.pick_nz(0u64, b) == b : U64}

def pick_nz_zero(b):
  {==}


law neg_prof_go_short:
  {Y.sres_show(O.prof_go(1u64, "profile")) == "invalid-input" : String}

def neg_prof_go_short():
  {==}


law neg_prof_go_outside:
  {Y.sres_show(O.prof_go(9u64, "profile")) == "invalid-input" : String}

def neg_prof_go_outside():
  {==}


law neg_prof_go_fuel:
  {Y.sres_show(O.prof_go(17u64, "profile")) == "resource-exhausted" : String}

def neg_prof_go_fuel():
  {==}


law neg_prof_go_unknown:
  {Y.sres_show(O.prof_go(99u64, "profile")) == "invalid-input" : String}

def neg_prof_go_unknown():
  {==}


law neg_rev_pinch:
  {O.rev_ax(rev_tri(), 100000n) == 15u64 : U64}

def neg_rev_pinch():
  {==}


law neg_hole_breakout:
  {O.hole_clr_loop(1.5f64, 0.5f64, 1.0f64, sq_loop(), 100n) == 19u64 : U64}

def neg_hole_breakout():
  {==}


law ok_hole_rect:
  {O.hole_rect(10.0f64, 10.0f64, 1.0f64, 0.0f64, 0.0f64, 4.0f64, 4.0f64) == 0u64 : U64}

def ok_hole_rect():
  {==}


law neg_box_over:
  {Y.sres_show(O.box_checked(1.0e308f64, 0.0f64, 0.0f64, 1.0e308f64, 1.0f64, 1.0f64,
    10000n)) == "numerical-uncertainty" : String}

def neg_box_over():
  {==}


law ok_box_gen_ce:
  {Ty.ce_gen(nth_ce(Ty.brep_ces(unit_box()), 0n)) == 21u64 : U64}

def ok_box_gen_ce():
  {==}


law neg_box_pos_neg:
  {O.box_pos(F64.neg(1.0f64), 2.0f64, 3.0f64) == False{} : Bool}

def neg_box_pos_neg():
  {==}


law neg_stage_embed:
  {Y.sres_show(O.stage_go(7u64)) == "numerical-uncertainty" : String}

def neg_stage_embed():
  {==}


law neg_stage_fuel_hi:
  {Y.sres_show(O.stage_ex(112u64)) == "resource-exhausted" : String}

def neg_stage_fuel_hi():
  {==}


law neg_att3_all_c:
  {O.att3(2n, 3n, 3n, 1u64) == 1u64 : U64}

def neg_att3_all_c():
  {==}


law ok_bulk_a:
  {Y.sres_show(O.bulk_a(Ty.tok_brep(unit_box()), Ty.brep_vs(unit_box()),
    Ty.brep_es(unit_box()), Ty.brep_ces(unit_box()), Ty.brep_lps(unit_box()),
    Ty.brep_fas(unit_box()), Ty.brep_shs(unit_box()), Ty.brep_sos(unit_box()), 58u64,
    10000n)) == "ok" : String}

def ok_bulk_a():
  {==}


law node_hash_extrude:
  for p: Y.Prof
  for d: U64
  for ps: List<&2, Y.Param>
  {EV.node_hash(Y.O_extrude{p, d}, ps) == 6u64 : U64}

def node_hash_extrude(p, d, ps):
  {==}


law neg_pm_hit:
  {EV.pm_hit_go([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64))], 9u64)
    == False{} : Bool}

def neg_pm_hit():
  {==}


law sres_is_body_yes:
  for b: Y.Body
  {EV.sres_is_body(Y.sok_body(b)) == True{} : Bool}

def sres_is_body_yes(b):
  {==}


law neg_eval_baddim:
  {Y.sres_show(ev_last2(EV.ev_part(part_baddim(), Y.cache_empty(), 10000n)))
    == "invalid-input" : String}

def neg_eval_baddim():
  {==}


law neg_evop_cyl:
  {Y.sres_show(EV.ev_op(Y.O_cyl{1u64, 2u64}, [], 10n)) == "unsupported-op" : String}

def neg_evop_cyl():
  {==}


law neg_evop_pad:
  {Y.sres_show(EV.ev_op(Y.O_pad{7u64, 0.0f64, 0.0f64, 1u64, 2u64, 3u64}, [], 10n))
    == "unsupported-op" : String}

def neg_evop_pad():
  {==}


law ok_box_names_len:
  {Nat.is_eq(List.length(&2, Y.Nm, EV.box_names(7u64)), 26n) == True{} : Bool}

def ok_box_names_len():
  {==}


law neg_t_in11:
  {SX.t_in11(2.0f64) == False{} : Bool}

def neg_t_in11():
  {==}


law ok_surf_cyl:
  {SX.surf_cyl(G.Cy{org(), axis_z(), 1.0f64}, 0.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{1.0f64, 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_cyl():
  {==}


law ok_surf_sph_west:
  {SX.surf_sph(G.Sp{org(), 2.0f64}, F64.neg(1.0f64), 0.0f64)
    == G.Gok{G.GV_p{V.Pt{F64.neg(2.0f64), 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_sph_west():
  {==}


law neg_ring_cyl_r:
  {SX.ring_cyl(G.Cy{org(), axis_z(), 0.0f64}, 3.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_cyl_r():
  {==}

