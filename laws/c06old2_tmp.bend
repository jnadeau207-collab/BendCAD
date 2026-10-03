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


law sres_show_ok:
  for v: Y.SVal
  {Y.sres_show(Y.Sok{v}) == "ok" : String}

def sres_show_ok(v):
  {==}


law sok_u_rt:
  for u: U64
  {Y.sok_u_of(Y.sok_u(u)) == u : U64}

def sok_u_rt(u):
  {==}


law matfx_eq_same:
  {Y.matfx_eq(Y.M_create{}, Y.M_create{}) == True{} : Bool}

def matfx_eq_same():
  {==}


law intent_check_diff:
  {Y.intent_check(Y.mk_intent(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 1n)) == False{} : Bool}

def intent_check_diff():
  {==}


law dm_pos_lo:
  {Y.dm_valid_pos(Y.mk_dm(0.0f64, F64.neg(1.0f64), 1.0f64)) == False{} : Bool}

def dm_pos_lo():
  {==}


law body_brep_proj:
  for b: Ty.Brep
  for k: U64
  for p: Y.Prof
  for z0: F64
  for z1: F64
  for bo: List<&2, Y.Boss>
  for nh: Nat
  for rh: List<&2, Y.HoleSpec>
  for dm: List<&2, F64>
  {Y.body_brep(Y.mk_body(b, k, p, z0, z1, bo, nh, rh, dm)) == b : Ty.Brep}

def body_brep_proj(b, k, p, z0, z1, bo, nh, rh, dm):
  {==}


law op_tag_revolve:
  {Y.op_tag(Y.O_revolve{Y.mk_prof(sq_loop(), [])}) == 7u64 : U64}

def op_tag_revolve():
  {==}


law node_show_pin:
  {Y.node_show(Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [])) == "n7:box" : String}

def node_show_pin():
  {==}

# --- D. Certified interval arithmetic (outward rounding). ---


law ok_iv_sq_neg:
  {Y.sok_iv_of(O.iv_sq(Y.Iv{F64.neg(3.0f64), F64.neg(2.0f64)}))
    == Y.Iv{F64{4616189618054758399u64}, F64{4621256167635550209u64}} : Y.Iv}

def ok_iv_sq_neg():
  {==}


law ok_next_up_one:
  {O.f64_next_up(1.0f64) == F64{4607182418800017409u64} : F64}

def ok_next_up_one():
  {==}


law neg_prof_touch:
  {O.prof_code(touch_loop(), [], 100000n) == 7u64 : U64}

def neg_prof_touch():
  {==}


law ok_prof_holes:
  {O.prof_code(outer_loop(), [hole_b(), hole_c()], 100000n) == 0u64 : U64}

def ok_prof_holes():
  {==}


law neg_sh_zero:
  {O.sh_sign(bow_loop(), 100n) == 0u64 : U64}

def neg_sh_zero():
  {==}

# --- F. Point-in-polygon (contract §2: exact, tangent is on-edge). ---


law fold_codes_empty:
  for fuel: Nat
  {O.fold_codes([], fuel) == 0u64 : U64}

def fold_codes_empty(fuel):
  {==}


law neg_prof_go_dup:
  {Y.sres_show(O.prof_go(3u64, "profile")) == "invalid-input" : String}

def neg_prof_go_dup():
  {==}


law neg_prof_go_loopxing:
  {Y.sres_show(O.prof_go(11u64, "profile")) == "invalid-input" : String}

def neg_prof_go_loopxing():
  {==}


law neg_prof_go_breakout:
  {Y.sres_show(O.prof_go(19u64, "profile")) == "invalid-input" : String}

def neg_prof_go_breakout():
  {==}


law diag_prof_go_uncertain:
  {Y.diag_show(Y.sres_diag(O.prof_go(13u64, "profile")))
    == "predicate @ profile [predicate-uncertain] fix: perturb coordinates slightly" : String}

def diag_prof_go_uncertain():
  {==}


law neg_rev_mid:
  {O.rev_ax(rev_mid(), 100000n) == 15u64 : U64}

def neg_rev_mid():
  {==}


law ok_hole_clear:
  {O.hole_clr_loop(5.0f64, 5.0f64, 1.0f64, sq_loop(), 100n) == 0u64 : U64}

def ok_hole_clear():
  {==}


law neg_rect_disj:
  {O.rect_disj(0.0f64, 0.0f64, 2.0f64, 2.0f64, 1.0f64, 1.0f64, 2.0f64, 2.0f64)
    == False{} : Bool}

def neg_rect_disj():
  {==}

# --- K. Box builder (contract §3). ---


law neg_box_pos_first:
  {Y.sres_show(O.box_checked(1.0e308f64, 0.0f64, 0.0f64, 1.0e308f64, 0.0f64, 1.0f64,
    10000n)) == "invalid-input" : String}

def neg_box_pos_first():
  {==}


law ok_box_gen_fa:
  {Ty.fa_gen(nth_fa(Ty.brep_fas(unit_box()), 0n)) == 51u64 : U64}

def ok_box_gen_fa():
  {==}


law neg_stage_zero:
  {Y.sres_show(O.stage_go(0u64)) == "resource-exhausted" : String}

def neg_stage_zero():
  {==}


law neg_stage_conn:
  {Y.sres_show(O.stage_go(9u64)) == "invalid-input" : String}

def neg_stage_conn():
  {==}


law neg_att_zero:
  {Y.sres_show(O.att_go(0u64)) == "invalid-input" : String}

def neg_att_zero():
  {==}


law neg_att3_nodup:
  {O.att3(3n, 3n, 2n, 1u64) == 3u64 : U64}

def neg_att3_nodup():
  {==}


law neg_diag_valid_box:
  {Y.sres_show(O.diag_brep(unit_box(), 10000n)) == "resource-exhausted" : String}

def neg_diag_valid_box():
  {==}

# --- M. Op-graph eval (contract §5). ---


law node_hash_holes:
  for b: U64
  for hs: List<&2, Y.HoleSpec>
  for ps: List<&2, Y.Param>
  {EV.node_hash(Y.O_holes{b, hs}, ps) == 8u64 : U64}

def node_hash_holes(b, hs, ps):
  {==}


law neg_ev_wrap_other:
  {Y.sres_show(EV.ev_wrap(Y.sok_u(5u64), 1.0f64, 2.0f64, 3.0f64))
    == "unsupported-op" : String}

def neg_ev_wrap_other():
  {==}


law sres_body_yes:
  for b: Y.Body
  {EV.sres_body(Y.sok_body(b)) == b : Y.Body}

def sres_body_yes(b):
  {==}


law neg_eval_cyl:
  {Y.sres_show(ev_last2(EV.ev_part(part_cyl(), Y.cache_empty(), 10000n)))
    == "unsupported-op" : String}

def neg_eval_cyl():
  {==}


law neg_evop_cone:
  {Y.sres_show(EV.ev_op(Y.O_cone{1u64, 2u64}, [], 10n)) == "unsupported-op" : String}

def neg_evop_cone():
  {==}


law ok_gate:
  {EV.gate_publish(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_intent(Y.M_create{}, 6n, 0n, 1n, 0n))
    == Y.sok_fx(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n)) : Y.SRes}

def ok_gate():
  {==}


law ok_box_names_last:
  {Y.nm_show(nm_nth(EV.box_names(7u64), 25n)) == "n7.r2#7" : String}

def ok_box_names_last():
  {==}

# --- O. Quadric frames and evaluators (surfx). ---


law ok_qf_wi_z:
  {SX.qf_wi(0.0f64, 0.0f64, 5.0f64) == 0u64 : U64}

def ok_qf_wi_z():
  {==}


law neg_surf_cyl_r:
  {SX.surf_cyl(G.Cy{org(), axis_z(), 0.0f64}, 0.0f64, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_cyl_r():
  {==}


law ok_surf_at_sph:
  {SX.surf_at(G.GV_sp{G.Sp{org(), 2.0f64}}, 1.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{2.0f64, 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_at_sph():
  {==}


law neg_ring_cone_h:
  {SX.ring_cone(G.Co{org(), axis_z(), 1.0f64}, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_cone_h():
  {==}

