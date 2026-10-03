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


law serr_unsupported_show:
  for w: String
  for l: String
  for y: String
  for f: String
  {Y.sres_show(Y.serr_unsupported(w, l, y, f)) == "unsupported-op" : String}

def serr_unsupported_show(w, l, y, f):
  {==}


law diag_show_pin:
  {Y.diag_show(Y.mk_diag("box", "n7", "non-positive dim", "pass strictly positive dims"))
    == "box @ n7 [non-positive dim] fix: pass strictly positive dims" : String}

def diag_show_pin():
  {==}


law fx_eq_same:
  {Y.fx_eq(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n), Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n)) == True{} : Bool}

def fx_eq_same():
  {==}


law intent_proj_holes:
  for m: Y.MatFx
  for fc: Nat
  for fm: Nat
  for sh: Nat
  for ho: Nat
  {Y.intent_holes(Y.mk_intent(m, fc, fm, sh, ho)) == ho : Nat}

def intent_proj_holes(m, fc, fm, sh, ho):
  {==}


law iv_valid_nan:
  {Y.iv_valid(Y.Iv{F64.nan(), 1.0f64}) == False{} : Bool}

def iv_valid_nan():
  {==}


law op_tag_cyl:
  {Y.op_tag(Y.O_cyl{1u64, 2u64}) == 2u64 : U64}

def op_tag_cyl():
  {==}


law op_tag_pad:
  {Y.op_tag(Y.O_pad{7u64, 0.0f64, 0.0f64, 1u64, 2u64, 3u64}) == 10u64 : U64}

def op_tag_pad():
  {==}


law ok_iv_mul:
  {Y.sok_iv_of(O.iv_mul(Y.Iv{2.0f64, 2.0f64}, Y.Iv{3.0f64, 3.0f64}))
    == Y.Iv{F64{4618441417868443647u64}, F64{4618441417868443649u64}} : Y.Iv}

def ok_iv_mul():
  {==}


law neg_iv_sqrt:
  {Y.sres_show(O.iv_sqrt(Y.Iv{F64.neg(1.0f64), 9.0f64})) == "invalid-input" : String}

def neg_iv_sqrt():
  {==}


law iv_pt_point:
  for x: F64
  {O.iv_pt(x) == Y.Iv{x, x} : Y.Iv}

def iv_pt_point(x):
  {==}

# --- E. Profile validator codes (contract §2). ---


law neg_prof_nonfinite:
  {O.prof_code([V.V2{F64.nan(), 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}], [],
    1000n) == 2u64 : U64}

def neg_prof_nonfinite():
  {==}


law neg_prof_fuel:
  {O.prof_code(sq_loop(), [], 0n) == 17u64 : U64}

def neg_prof_fuel():
  {==}


law ok_pip_edge:
  {O.pip(0.5f64, 0.0f64, sq_loop(), 1000n) == 2u64 : U64}

def ok_pip_edge():
  {==}


law dist_code_ok:
  {O.dist_code(sq_loop(), 100n) == 0u64 : U64}

def dist_code_ok():
  {==}


law neg_prof_go_xing:
  {Y.sres_show(O.prof_go(6u64, "profile")) == "invalid-input" : String}

def neg_prof_go_xing():
  {==}


law neg_prof_go_axcross:
  {Y.sres_show(O.prof_go(14u64, "revolve")) == "invalid-input" : String}

def neg_prof_go_axcross():
  {==}


law neg_prof_go_padover:
  {Y.sres_show(O.prof_go(22u64, "profile")) == "invalid-input" : String}

def neg_prof_go_padover():
  {==}


law ok_prof_valid:
  {Y.sres_show(O.prof_valid(Y.mk_prof(sq_loop(), []), 1000n)) == "ok" : String}

def ok_prof_valid():
  {==}


law ok_rev_hole:
  {O.rev_hole_go([rev_hole_ok()], 100n) == 0u64 : U64}

def ok_rev_hole():
  {==}


law neg_hole_boss:
  {O.hole_boss1(0.0f64, 0.0f64, 1.0f64, Y.mk_boss(0.0f64, 0.0f64, 4.0f64, 4.0f64, 0.0f64,
    1.0f64)) == 21u64 : U64}

def neg_hole_boss():
  {==}


law neg_box_zero:
  {Y.sres_show(O.box_checked(0.0f64, 0.0f64, 0.0f64, 0.0f64, 2.0f64, 3.0f64, 10000n))
    == "invalid-input" : String}

def neg_box_zero():
  {==}


law ok_box_counts:
  {boxcounts7(unit_box()) == True{} : Bool}

def ok_box_counts():
  {==}


law neg_box_fin:
  {O.box_fin(F64.nan(), 0.0f64, 0.0f64, 1.0f64, 2.0f64, 3.0f64) == False{} : Bool}

def neg_box_fin():
  {==}


law neg_stage_loop:
  {Y.sres_show(O.stage_go(4u64)) == "invalid-input" : String}

def neg_stage_loop():
  {==}


law neg_stage_orient:
  {Y.sres_show(O.stage_go(12u64)) == "invalid-input" : String}

def neg_stage_orient():
  {==}


law neg_att_fuel:
  {Y.sres_show(O.att_go(100u64)) == "resource-exhausted" : String}

def neg_att_fuel():
  {==}


law neg_stc_undecided:
  {O.stc(0n, 5u64) == 105u64 : U64}

def neg_stc_undecided():
  {==}


law node_hash_sph:
  for r: U64
  for ps: List<&2, Y.Param>
  {EV.node_hash(Y.O_sph{r}, ps) == 3u64 : U64}

def node_hash_sph(r, ps):
  {==}


law node_hash_xform:
  for b: U64
  for xf: V.Rigid
  for ps: List<&2, Y.Param>
  {EV.node_hash(Y.O_xform{b, xf}, ps) == 11u64 : U64}

def node_hash_xform(b, xf, ps):
  {==}


law cc_covers_empty:
  for items: List<&2, Y.Built>
  {EV.cc_covers(items, []) == True{} : Bool}

def cc_covers_empty(items):
  {==}


law ok_eval_fresh:
  {root318(EV.ev_part(part1(), Y.cache_empty(), 10000n)) == True{} : Bool}

def ok_eval_fresh():
  {==}


law neg_eval_second_fails:
  {Y.sres_show(ev_last2(EV.ev_part(part_ff2(), Y.cache_empty(), 10000n)))
    == "unsupported-op" : String}

def neg_eval_second_fails():
  {==}


law neg_evop_revolve:
  {Y.sres_show(EV.ev_op(Y.O_revolve{Y.mk_prof(sq_loop(), [])}, [], 10n))
    == "unsupported-op" : String}

def neg_evop_revolve():
  {==}


law neg_gate_fm:
  {Y.sres_show(EV.gate_publish(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_intent(Y.M_create{}, 6n, 1n, 1n, 0n))) == "invalid-input" : String}

def neg_gate_fm():
  {==}


law ok_circ_nx_one:
  {SX.circ_nx(1.0f64) == F64.neg(1.0f64) : F64}

def ok_circ_nx_one():
  {==}


law ok_qframe_y:
  {SX.qframe(V.Dr{0.0f64, 1.0f64, 0.0f64})
    == SX.QFr{V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}} : SX.QFr}

def ok_qframe_y():
  {==}


law ok_surf_tor:
  {SX.surf_tor(G.To{org(), axis_z(), 5.0f64, 1.0f64}, 0.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{6.0f64, 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_tor():
  {==}


law ok_is_quad_sph:
  {SX.surf_is_quad(G.GV_sp{G.Sp{org(), 2.0f64}}) == True{} : Bool}

def ok_is_quad_sph():
  {==}


law ok_ring_tor_m:
  {SX.ring_tor_m(G.To{org(), axis_z(), 5.0f64, 1.0f64}, 0.0f64)
    == G.Gok{G.GV_cc{G.Cc{V.Pt{5.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 1.0f64}, 1.0f64}}} : G.GRes}

def ok_ring_tor_m():
  {==}

