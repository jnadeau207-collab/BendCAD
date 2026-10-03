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


law serr_exhausted_show:
  for w: String
  for l: String
  for y: String
  for f: String
  {Y.sres_show(Y.serr_exhausted(w, l, y, f)) == "resource-exhausted" : String}

def serr_exhausted_show(w, l, y, f):
  {==}


law matfx_show_create:
  {Y.matfx_show(Y.M_create{}) == "create" : String}

def matfx_show_create():
  {==}


law fx_eq_diff:
  {Y.fx_eq(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n), Y.mk_fx(Y.M_create{}, 5n, 0n, 1n, 0n)) == False{} : Bool}

def fx_eq_diff():
  {==}


law dm_valid_ok:
  {Y.dm_valid(Y.mk_dm(1.0f64, 0.5f64, 2.0f64)) == True{} : Bool}

def dm_valid_ok():
  {==}


law iv_of_dm_pin:
  {Y.iv_of_dm(Y.mk_dm(1.0f64, 0.5f64, 2.0f64)) == Y.Iv{0.5f64, 2.0f64} : Y.Iv}

def iv_of_dm_pin():
  {==}


law op_tag_sph:
  {Y.op_tag(Y.O_sph{1u64}) == 3u64 : U64}

def op_tag_sph():
  {==}


law op_tag_xform:
  {Y.op_tag(Y.O_xform{7u64, id_rigid()}) == 11u64 : U64}

def op_tag_xform():
  {==}


law ok_iv_div:
  {Y.sok_iv_of(O.iv_div(Y.Iv{6.0f64, 6.0f64}, Y.Iv{2.0f64, 2.0f64}))
    == Y.Iv{F64{4613937818241073151u64}, F64{4613937818241073153u64}} : Y.Iv}

def ok_iv_div():
  {==}


law neg_iv_gate_flip:
  {Y.sres_show(O.iv_gate(2.0f64, 1.0f64)) == "numerical-uncertainty" : String}

def neg_iv_gate_flip():
  {==}


law ok_prof_square:
  {O.prof_code(sq_loop(), [], 1000n) == 0u64 : U64}

def ok_prof_square():
  {==}


law neg_prof_dup:
  {O.prof_code([V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
    V.V2{0.0f64, 1.0f64}], [], 1000n) == 3u64 : U64}

def neg_prof_dup():
  {==}


law neg_prof_too_large:
  {O.prof_code(dup_pts(65n), [], 1000000n) == 18u64 : U64}

def neg_prof_too_large():
  {==}


law ok_pip_corner:
  {O.pip(0.0f64, 0.0f64, sq_loop(), 1000n) == 2u64 : U64}

def ok_pip_corner():
  {==}


law dist_code_dup:
  {O.dist_code([V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}], 100n)
    == 3u64 : U64}

def dist_code_dup():
  {==}

# --- H. Code mapper: every validation code becomes a diagnosis. ---


law neg_prof_go_touch:
  {Y.sres_show(O.prof_go(7u64, "profile")) == "invalid-input" : String}

def neg_prof_go_touch():
  {==}


law neg_prof_go_pinch:
  {Y.sres_show(O.prof_go(15u64, "revolve")) == "invalid-input" : String}

def neg_prof_go_pinch():
  {==}


law neg_prof_go_foot:
  {Y.sres_show(O.prof_go(23u64, "profile")) == "invalid-input" : String}

def neg_prof_go_foot():
  {==}


law neg_prof_valid_bow:
  {Y.sres_show(O.prof_valid(Y.mk_prof(bow_loop(), []), 1000n)) == "invalid-input" : String}

def neg_prof_valid_bow():
  {==}

# --- I. Revolve axis discipline. ---


law ok_rev_prof:
  {Y.sres_show(O.prof_valid_rev(Y.mk_prof(rev_sq(), []), 100000n)) == "ok" : String}

def ok_rev_prof():
  {==}


law ok_hole_boss:
  {O.hole_boss1(10.0f64, 10.0f64, 1.0f64, Y.mk_boss(0.0f64, 0.0f64, 4.0f64, 4.0f64,
    0.0f64, 1.0f64)) == 0u64 : U64}

def ok_hole_boss():
  {==}


law neg_box_negdim:
  {Y.sres_show(O.box_checked(0.0f64, 0.0f64, 0.0f64, F64.neg(1.0f64), 2.0f64, 3.0f64,
    10000n)) == "invalid-input" : String}

def neg_box_negdim():
  {==}


law ok_box_gen_vx:
  {Ty.vx_gen(nth_vx(Ty.brep_vs(unit_box()), 0n)) == 1u64 : U64}

def ok_box_gen_vx():
  {==}


law ok_box_pos:
  {O.box_pos(1.0f64, 2.0f64, 3.0f64) == True{} : Bool}

def ok_box_pos():
  {==}


law neg_stage_facekind:
  {Y.sres_show(O.stage_go(5u64)) == "invalid-input" : String}

def neg_stage_facekind():
  {==}


law neg_stage_unknown:
  {Y.sres_show(O.stage_go(99u64)) == "invalid-input" : String}

def neg_stage_unknown():
  {==}


law neg_att_unknown:
  {Y.sres_show(O.att_go(99u64)) == "invalid-input" : String}

def neg_att_unknown():
  {==}


law bulk_c_passthrough:
  for b: Ty.Brep
  for fuel: Nat
  {O.bulk_c(Ty.Tok{Ty.T_brep{b}}, b, fuel) == Y.sok_brep(b) : Y.SRes}

def bulk_c_passthrough(b, fuel):
  {==}


law node_hash_cone:
  for r: U64
  for h: U64
  for ps: List<&2, Y.Param>
  {EV.node_hash(Y.O_cone{r, h}, ps) == 4u64 : U64}

def node_hash_cone(r, h, ps):
  {==}


law ok_fnv_step:
  {EV.fnv_step(1u64, 2u64) == 1099511628213u64 : U64}

def ok_fnv_step():
  {==}


law ok_cc_find_hit:
  {EV.cc_find_id0([EV.bt_dummy()], [], 0u64)
    == EV.CO{True{}, EV.bt_dummy(), []} : EV.CcOut}

def ok_cc_find_hit():
  {==}


law ok_eval_reuse:
  {root318(EV.ev_part(part1(), ev_cc2(EV.ev_part(part1(), Y.cache_empty(), 10000n)),
    10000n)) == True{} : Bool}

def ok_eval_reuse():
  {==}


law ok_eval_origin_z0:
  {bd_z0(ev_body(EV.ev_part(part1(), Y.cache_empty(), 10000n))) == 0.0f64 : F64}

def ok_eval_origin_z0():
  {==}


law neg_evop_holes:
  {Y.sres_show(EV.ev_op(Y.O_holes{7u64, []}, [], 10n)) == "unsupported-op" : String}

def neg_evop_holes():
  {==}


law neg_gate_shells:
  {Y.sres_show(EV.gate_publish(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_intent(Y.M_create{}, 6n, 0n, 2n, 0n))) == "invalid-input" : String}

def neg_gate_shells():
  {==}


law ok_circ_ny_one:
  {SX.circ_ny(1.0f64) == 0.0f64 : F64}

def ok_circ_ny_one():
  {==}


law ok_qframe_z:
  {SX.qframe(V.Dr{0.0f64, 0.0f64, 1.0f64})
    == SX.QFr{V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}} : SX.QFr}

def ok_qframe_z():
  {==}


law neg_surf_tor_spindle:
  {SX.surf_tor(G.To{org(), axis_z(), 1.0f64, 5.0f64}, 0.0f64, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_tor_spindle():
  {==}


law neg_is_quad_f:
  {SX.surf_is_quad(G.GV_f{1.0f64}) == False{} : Bool}

def neg_is_quad_f():
  {==}


law neg_ring_tor_m_t:
  {SX.ring_tor_m(G.To{org(), axis_z(), 5.0f64, 1.0f64}, 2.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_tor_m_t():
  {==}
