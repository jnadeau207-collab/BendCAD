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


law serr_is_err:
  for k: T.FailKind
  for dg: Y.Diag
  {Y.sres_ok(Y.Serr{k, dg}) == False{} : Bool}

def serr_is_err(k, dg):
  {==}


law sres_diag_err:
  for k: T.FailKind
  for dg: Y.Diag
  {Y.sres_diag(Y.Serr{k, dg}) == dg : Y.Diag}

def sres_diag_err(k, dg):
  {==}


law matfx_show_same:
  {Y.matfx_show(Y.M_same{}) == "same" : String}

def matfx_show_same():
  {==}


law intent_check_same:
  {Y.intent_check(Y.mk_intent(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n)) == True{} : Bool}

def intent_check_same():
  {==}


law dm_pos_ok:
  {Y.dm_valid_pos(Y.mk_dm(1.0f64, 0.5f64, 2.0f64)) == True{} : Bool}

def dm_pos_ok():
  {==}


law nm_show_pin:
  {Y.nm_show(Y.mk_nm(7u64, 1u64, 11n)) == "n7.r1#11" : String}

def nm_show_pin():
  {==}


law op_tag_extrude:
  {Y.op_tag(Y.O_extrude{Y.mk_prof(sq_loop(), []), 1u64}) == 6u64 : U64}

def op_tag_extrude():
  {==}


law op_show_xform:
  {Y.op_show(Y.O_xform{7u64, id_rigid()}) == "xform" : String}

def op_show_xform():
  {==}


law ok_iv_sq_pos:
  {Y.sok_iv_of(O.iv_sq(Y.Iv{2.0f64, 3.0f64}))
    == Y.Iv{F64{4616189618054758399u64}, F64{4621256167635550209u64}} : Y.Iv}

def ok_iv_sq_pos():
  {==}


law ok_next_down_zero:
  {O.f64_next_down(0.0f64) == F64{9223372036854775809u64} : F64}

def ok_next_down_zero():
  {==}


law neg_prof_spike:
  {O.prof_code(spike_loop(), [], 1000n) == 8u64 : U64}

def neg_prof_spike():
  {==}


law neg_prof_nest_ba:
  {O.prof_code(outer_loop(), [hole_b(), hole_a()], 100000n) == 12u64 : U64}

def neg_prof_nest_ba():
  {==}


law neg_sh_cw:
  {O.sh_sign(cw_loop(), 100n) == 2u64 : U64}

def neg_sh_cw():
  {==}


law pick_nz_nz:
  for b: U64
  {O.pick_nz(5u64, b) == 5u64 : U64}

def pick_nz_nz(b):
  {==}


law neg_prof_go_nonfinite:
  {Y.sres_show(O.prof_go(2u64, "profile")) == "invalid-input" : String}

def neg_prof_go_nonfinite():
  {==}


law neg_prof_go_looptouch:
  {Y.sres_show(O.prof_go(10u64, "profile")) == "invalid-input" : String}

def neg_prof_go_looptouch():
  {==}


law neg_prof_go_large:
  {Y.sres_show(O.prof_go(18u64, "profile")) == "resource-exhausted" : String}

def neg_prof_go_large():
  {==}


law diag_prof_go_winding:
  {Y.diag_show(Y.sres_diag(O.prof_go(5u64, "profile")))
    == "profile loop @ profile [winding] fix: reverse the loop (outer CCW, holes CW)" : String}

def diag_prof_go_winding():
  {==}


law neg_rev_below:
  {O.rev_ax(rev_below(), 100000n) == 14u64 : U64}

def neg_rev_below():
  {==}


law neg_hole_tangent:
  {O.hole_clr_loop(2.0f64, 0.5f64, 1.0f64, sq_loop(), 100n) == 19u64 : U64}

def neg_hole_tangent():
  {==}


law ok_rect_disj:
  {O.rect_disj(0.0f64, 0.0f64, 1.0f64, 1.0f64, 5.0f64, 5.0f64, 1.0f64, 1.0f64)
    == True{} : Bool}

def ok_rect_disj():
  {==}


law neg_box_fin_first:
  {Y.sres_show(O.box_checked(F64.nan(), 0.0f64, 0.0f64, 1.0e308f64, 1.0f64, 1.0f64,
    10000n)) == "invalid-input" : String}

def neg_box_fin_first():
  {==}


law ok_box_gen_lp:
  {Ty.lp_gen(nth_lp(Ty.brep_lps(unit_box()), 0n)) == 45u64 : U64}

def ok_box_gen_lp():
  {==}


law neg_box_sum:
  {O.box_sum_fin(1.0e308f64, 0.0f64, 0.0f64, 1.0e308f64, 1.0f64, 1.0f64)
    == False{} : Bool}

def neg_box_sum():
  {==}

# --- L. Staged diagnosis (contract §4). ---


law neg_stage_link:
  {Y.sres_show(O.stage_go(8u64)) == "invalid-input" : String}

def neg_stage_link():
  {==}


law neg_stage_ex_unknown:
  {Y.sres_show(O.stage_ex(99u64)) == "invalid-input" : String}

def neg_stage_ex_unknown():
  {==}


law neg_att3_gen:
  {O.att3(3n, 2n, 3n, 1u64) == 2u64 : U64}

def neg_att3_gen():
  {==}


law neg_bulk_a_att:
  {Y.sres_show(O.bulk_a(Ty.Terr{T.F_invalid{}}, [], [], [], [], [], [], [], 58u64, 100n))
    == "invalid-input" : String}

def neg_bulk_a_att():
  {==}


law node_hash_revolve:
  for p: Y.Prof
  for ps: List<&2, Y.Param>
  {EV.node_hash(Y.O_revolve{p}, ps) == 7u64 : U64}

def node_hash_revolve(p, ps):
  {==}


law ok_pm_nom:
  {EV.pm_nom_go([Y.mk_param(5u64, Y.mk_dm(7.0f64, 6.0f64, 8.0f64))], 5u64)
    == 7.0f64 : F64}

def ok_pm_nom():
  {==}


law sres_is_body_no:
  for k: T.FailKind
  for dg: Y.Diag
  {EV.sres_is_body(Y.Serr{k, dg}) == False{} : Bool}

def sres_is_body_no(k, dg):
  {==}


law neg_eval_badroot:
  {Y.sres_show(ev_last2(EV.ev_part(part_badroot(), Y.cache_empty(), 10000n)))
    == "invalid-input" : String}

def neg_eval_badroot():
  {==}


law neg_evop_sph:
  {Y.sres_show(EV.ev_op(Y.O_sph{1u64}, [], 10n)) == "unsupported-op" : String}

def neg_evop_sph():
  {==}


law neg_evop_xform:
  {Y.sres_show(EV.ev_op(Y.O_xform{7u64, id_rigid()}, [], 10n)) == "unsupported-op" : String}

def neg_evop_xform():
  {==}

# --- N. Publish gate and lineage names (contract §5). ---


law ok_box_names_first:
  {Y.nm_show(nm_nth(EV.box_names(7u64), 0n)) == "n7.r0#0" : String}

def ok_box_names_first():
  {==}


law ok_qf_wi_x:
  {SX.qf_wi(1.0f64, 0.0f64, 0.0f64) == 1u64 : U64}

def ok_qf_wi_x():
  {==}


law neg_surf_cyl_t:
  {SX.surf_cyl(G.Cy{org(), axis_z(), 1.0f64}, 2.0f64, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_cyl_t():
  {==}


law ok_surf_sph_pole:
  {SX.surf_sph(G.Sp{org(), 2.0f64}, 0.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{0.0f64, 0.0f64, 2.0f64}}} : G.GRes}

def ok_surf_sph_pole():
  {==}


law ok_ring_cone:
  {SX.ring_cone(G.Co{org(), axis_z(), 1.0f64}, 2.0f64)
    == G.Gok{G.GV_cc{G.Cc{V.Pt{0.0f64, 0.0f64, 2.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 1.0f64, 0.0f64}, 2.0f64}}} : G.GRes}

def ok_ring_cone():
  {==}

