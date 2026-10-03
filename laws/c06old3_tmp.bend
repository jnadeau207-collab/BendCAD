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


law serr_invalid_show:
  for w: String
  for l: String
  for y: String
  for f: String
  {Y.sres_show(Y.serr_invalid(w, l, y, f)) == "invalid-input" : String}

def serr_invalid_show(w, l, y, f):
  {==}


law sok_u_wrong_arm:
  for s: String
  {Y.sok_u_of(Y.sok_s(s)) == 0u64 : U64}

def sok_u_wrong_arm(s):
  {==}


law matfx_eq_diff:
  {Y.matfx_eq(Y.M_create{}, Y.M_add{}) == False{} : Bool}

def matfx_eq_diff():
  {==}


law intent_proj_mat:
  for m: Y.MatFx
  for fc: Nat
  for fm: Nat
  for sh: Nat
  for ho: Nat
  {Y.intent_mat(Y.mk_intent(m, fc, fm, sh, ho)) == m : Y.MatFx}

def intent_proj_mat(m, fc, fm, sh, ho):
  {==}


law iv_valid_ok:
  {Y.iv_valid(Y.Iv{1.0f64, 2.0f64}) == True{} : Bool}

def iv_valid_ok():
  {==}


law body_kind_proj:
  for b: Ty.Brep
  for k: U64
  for p: Y.Prof
  for z0: F64
  for z1: F64
  for bo: List<&2, Y.Boss>
  for nh: Nat
  for rh: List<&2, Y.HoleSpec>
  for dm: List<&2, F64>
  {Y.body_kind(Y.mk_body(b, k, p, z0, z1, bo, nh, rh, dm)) == k : U64}

def body_kind_proj(b, k, p, z0, z1, bo, nh, rh, dm):
  {==}

# --- C. Op algebra tags and shows (contract §5). ---


law op_tag_holes:
  {Y.op_tag(Y.O_holes{7u64, []}) == 8u64 : U64}

def op_tag_holes():
  {==}


law ok_iv_add:
  {Y.sok_iv_of(O.iv_add(Y.Iv{1.0f64, 1.0f64}, Y.Iv{2.0f64, 2.0f64}))
    == Y.Iv{F64{4613937818241073151u64}, F64{4613937818241073153u64}} : Y.Iv}

def ok_iv_add():
  {==}


law ok_iv_sq_straddle:
  {Y.sok_iv_of(O.iv_sq(Y.Iv{F64.neg(1.0f64), 2.0f64}))
    == Y.Iv{0.0f64, F64{4616189618054758401u64}} : Y.Iv}

def ok_iv_sq_straddle():
  {==}


law ok_next_down_one:
  {O.f64_next_down(1.0f64) == F64{4607182418800017407u64} : F64}

def ok_next_down_one():
  {==}


law neg_prof_cross:
  {O.prof_code(cross_loop(), [], 100000n) == 6u64 : U64}

def neg_prof_cross():
  {==}


law neg_prof_holes_cross:
  {O.prof_code(outer_loop(), [hole_a(), hole_d()], 100000n) == 11u64 : U64}

def neg_prof_holes_cross():
  {==}


law ok_pip_in:
  {O.pip(0.5f64, 0.5f64, sq_loop(), 1000n) == 1u64 : U64}

def ok_pip_in():
  {==}


law fin_code_ok:
  {O.fin_code(sq_loop(), 100n) == 0u64 : U64}

def fin_code_ok():
  {==}


law neg_prof_go_area:
  {Y.sres_show(O.prof_go(4u64, "profile")) == "invalid-input" : String}

def neg_prof_go_area():
  {==}


law neg_prof_go_nest:
  {Y.sres_show(O.prof_go(12u64, "profile")) == "invalid-input" : String}

def neg_prof_go_nest():
  {==}


law neg_prof_go_merge:
  {Y.sres_show(O.prof_go(20u64, "profile")) == "invalid-input" : String}

def neg_prof_go_merge():
  {==}


law diag_prof_go_fuel:
  {Y.diag_show(Y.sres_diag(O.prof_go(17u64, "profile")))
    == "fuel @ profile [fuel-out] fix: raise the fuel cap" : String}

def diag_prof_go_fuel():
  {==}


law neg_rev_last:
  {O.rev_ax(rev_last(), 100000n) == 15u64 : U64}

def neg_rev_last():
  {==}


law neg_hole_merge:
  {O.hole_hh(0.0f64, 0.0f64, 2.0f64, 1.0f64, 0.0f64, 2.0f64) == 20u64 : U64}

def neg_hole_merge():
  {==}


law ok_box:
  {box318(O.box_checked(0.0f64, 0.0f64, 0.0f64, 1.0f64, 2.0f64, 3.0f64, 10000n))
    == True{} : Bool}

def ok_box():
  {==}


law ok_box_adversarial:
  {box318(O.box_checked(97398.60767117864f64, F64.neg(971916.5996719621f64), 0.0f64,
    1.0f64, 2.0f64, 3.0f64, 10000n)) == True{} : Bool}

def ok_box_adversarial():
  {==}


law ok_box_gen_sh:
  {Ty.sh_gen(nth_sh(Ty.brep_shs(unit_box()), 0n)) == 57u64 : U64}

def ok_box_gen_sh():
  {==}


law neg_stage_incid:
  {Y.sres_show(O.stage_go(2u64)) == "invalid-input" : String}

def neg_stage_incid():
  {==}


law neg_stage_coin:
  {Y.sres_show(O.stage_go(10u64)) == "invalid-input" : String}

def neg_stage_coin():
  {==}


law neg_att_first:
  {Y.sres_show(O.att_go(1u64)) == "invalid-input" : String}

def neg_att_first():
  {==}


law ok_stc_pass:
  {O.stc(3n, 5u64) == 0u64 : U64}

def ok_stc_pass():
  {==}


law ok_node_hash_box:
  {EV.node_hash(Y.O_box{1u64, 2u64, 3u64},
    [Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
      Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
      Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))]) == 7153670588617593504u64 : U64}

def ok_node_hash_box():
  {==}


law node_hash_pocket:
  for b: U64
  for x: F64
  for y: F64
  for w: F64
  for h: F64
  for d: U64
  for ps: List<&2, Y.Param>
  {EV.node_hash(Y.O_pocket{b, x, y, w, h, d}, ps) == 9u64 : U64}

def node_hash_pocket(b, x, y, w, h, d, ps):
  {==}


law ok_ev_wrap_kind:
  {Y.body_kind(Y.sok_body_of(EV.ev_wrap(Y.sok_brep(Ty.brep_empty()), 1.0f64, 2.0f64,
    3.0f64))) == 0u64 : U64}

def ok_ev_wrap_kind():
  {==}


law sres_body_no:
  for k: T.FailKind
  for dg: Y.Diag
  {EV.sres_body(Y.Serr{k, dg}) == EV.dummy_body() : Y.Body}

def sres_body_no(k, dg):
  {==}


law neg_eval_empty:
  {Y.sres_show(ev_last2(EV.ev_part(Y.mk_part([], [], 99u64), Y.cache_empty(), 10000n)))
    == "invalid-input" : String}

def neg_eval_empty():
  {==}


law neg_evop_tor:
  {Y.sres_show(EV.ev_op(Y.O_tor{1u64, 2u64}, [], 10n)) == "unsupported-op" : String}

def neg_evop_tor():
  {==}


law neg_gate_fc:
  {Y.sres_show(EV.gate_publish(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_intent(Y.M_create{}, 5n, 0n, 1n, 0n))) == "invalid-input" : String}

def neg_gate_fc():
  {==}


law ok_circ_nx_zero:
  {SX.circ_nx(0.0f64) == 1.0f64 : F64}

def ok_circ_nx_zero():
  {==}


law ok_norm3:
  {SX.norm3(3.0f64, 4.0f64, 0.0f64) == 5.0f64 : F64}

def ok_norm3():
  {==}


law ok_surf_cone:
  {SX.surf_cone(G.Co{org(), axis_z(), 1.0f64}, 0.0f64, 2.0f64)
    == G.Gok{G.GV_p{V.Pt{2.0f64, 0.0f64, 2.0f64}}} : G.GRes}

def ok_surf_cone():
  {==}


law neg_surf_at_other:
  {SX.surf_at(G.GV_f{1.0f64}, 0.0f64, 0.0f64) == G.gerr(T.F_unsupported{}) : G.GRes}

def neg_surf_at_other():
  {==}


law ok_ring_tor_p:
  {SX.ring_tor_p(G.To{org(), axis_z(), 5.0f64, 1.0f64}, 0.0f64)
    == G.Gok{G.GV_cc{G.Cc{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 1.0f64, 0.0f64}, 6.0f64}}} : G.GRes}

def ok_ring_tor_p():
  {==}

