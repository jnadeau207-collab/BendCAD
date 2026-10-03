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


law serr_uncertain_show:
  for w: String
  for l: String
  for y: String
  for f: String
  {Y.sres_show(Y.serr_uncertain(w, l, y, f)) == "numerical-uncertainty" : String}

def serr_uncertain_show(w, l, y, f):
  {==}


law sok_brep_wrong_arm:
  for u: U64
  {Y.sok_brep_of(Y.sok_u(u)) == Ty.brep_empty() : Ty.Brep}

def sok_brep_wrong_arm(u):
  {==}


law fx_show_pin:
  {Y.fx_show(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n)) == "create fc=6 fm=0 sh=1 holes=0" : String}

def fx_show_pin():
  {==}


law intent_proj_fc:
  for m: Y.MatFx
  for fc: Nat
  for fm: Nat
  for sh: Nat
  for ho: Nat
  {Y.intent_fc(Y.mk_intent(m, fc, fm, sh, ho)) == fc : Nat}

def intent_proj_fc(m, fc, fm, sh, ho):
  {==}


law iv_valid_flip:
  {Y.iv_valid(Y.Iv{2.0f64, 1.0f64}) == False{} : Bool}

def iv_valid_flip():
  {==}


law op_tag_box:
  {Y.op_tag(Y.O_box{1u64, 2u64, 3u64}) == 1u64 : U64}

def op_tag_box():
  {==}


law op_tag_pocket:
  {Y.op_tag(Y.O_pocket{7u64, 0.0f64, 0.0f64, 1.0f64, 1.0f64, 2u64}) == 9u64 : U64}

def op_tag_pocket():
  {==}


law ok_iv_sub:
  {Y.sok_iv_of(O.iv_sub(Y.Iv{5.0f64, 5.0f64}, Y.Iv{2.0f64, 2.0f64}))
    == Y.Iv{F64{4613937818241073151u64}, F64{4613937818241073153u64}} : Y.Iv}

def ok_iv_sub():
  {==}


law ok_iv_sqrt:
  {Y.sok_iv_of(O.iv_sqrt(Y.Iv{4.0f64, 9.0f64}))
    == Y.Iv{F64{4611686018427387903u64}, F64{4613937818241073153u64}} : Y.Iv}

def ok_iv_sqrt():
  {==}


law ok_pi_iv:
  {O.pi_iv() == Y.Iv{F64{4614256656552045847u64}, F64{4614256656552045849u64}} : Y.Iv}

def ok_pi_iv():
  {==}


law neg_prof_short:
  {O.prof_code([V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}], [], 1000n) == 1u64 : U64}

def neg_prof_short():
  {==}


law neg_prof_hole_out:
  {O.prof_code(outer_loop(), [hole_f()], 100000n) == 9u64 : U64}

def neg_prof_hole_out():
  {==}


law ok_pip_out:
  {O.pip(2.0f64, 2.0f64, sq_loop(), 1000n) == 0u64 : U64}

def ok_pip_out():
  {==}


law fin_code_bad:
  {O.fin_code([V.V2{F64.nan(), 0.0f64}], 100n) == 2u64 : U64}

def fin_code_bad():
  {==}


law neg_prof_go_winding:
  {Y.sres_show(O.prof_go(5u64, "profile")) == "invalid-input" : String}

def neg_prof_go_winding():
  {==}


law neg_prof_go_uncertain:
  {Y.sres_show(O.prof_go(13u64, "profile")) == "numerical-uncertainty" : String}

def neg_prof_go_uncertain():
  {==}


law neg_prof_go_boss:
  {Y.sres_show(O.prof_go(21u64, "profile")) == "invalid-input" : String}

def neg_prof_go_boss():
  {==}


law diag_prof_go_blind:
  {Y.diag_show(Y.sres_diag(O.prof_go(24u64, "profile")))
    == "pocket @ profile [blind-pocket] fix: use depth >= thickness (through) or wait for C08" : String}

def diag_prof_go_blind():
  {==}


law neg_rev_hole_axis:
  {O.rev_hole_go([rev_hole_ax()], 100n) == 16u64 : U64}

def neg_rev_hole_axis():
  {==}


law ok_hole_pair:
  {O.hole_hh(0.0f64, 0.0f64, 1.0f64, 5.0f64, 0.0f64, 1.0f64) == 0u64 : U64}

def ok_hole_pair():
  {==}


law ok_box_frac:
  {box318(O.box_checked(0.1f64, 0.2f64, 0.3f64, 0.4f64, 0.5f64, 0.6f64, 10000n))
    == True{} : Bool}

def ok_box_frac():
  {==}


law ok_box_negcorner:
  {box318(O.box_checked(F64.neg(5.0f64), F64.neg(5.0f64), F64.neg(5.0f64), 1.0f64,
    2.0f64, 3.0f64, 10000n)) == True{} : Bool}

def ok_box_negcorner():
  {==}


law ok_box_gen_so:
  {Ty.so_gen(nth_so(Ty.brep_sos(unit_box()), 0n)) == 58u64 : U64}

def ok_box_gen_so():
  {==}


law neg_stage_use:
  {Y.sres_show(O.stage_go(3u64)) == "invalid-input" : String}

def neg_stage_use():
  {==}


law neg_stage_xing:
  {Y.sres_show(O.stage_go(11u64)) == "invalid-input" : String}

def neg_stage_xing():
  {==}


law neg_att_last:
  {Y.sres_show(O.att_go(21u64)) == "invalid-input" : String}

def neg_att_last():
  {==}


law neg_stc_fail:
  {O.stc(2n, 5u64) == 5u64 : U64}

def neg_stc_fail():
  {==}


law node_hash_cyl:
  for r: U64
  for h: U64
  for ps: List<&2, Y.Param>
  {EV.node_hash(Y.O_cyl{r, h}, ps) == 2u64 : U64}

def node_hash_cyl(r, h, ps):
  {==}


law node_hash_pad:
  for b: U64
  for x: F64
  for y: F64
  for w: U64
  for h: U64
  for d: U64
  for ps: List<&2, Y.Param>
  {EV.node_hash(Y.O_pad{b, x, y, w, h, d}, ps) == 10u64 : U64}

def node_hash_pad(b, x, y, w, h, d, ps):
  {==}


law cc_has_empty:
  for id: U64
  for h: U64
  {EV.cc_has([], id, h) == False{} : Bool}

def cc_has_empty(id, h):
  {==}


law ok_fx_of_body:
  {EV.fx_of_body(Y.mk_body(unit_box(), 0u64, Y.mk_prof(sq_loop(), []), 0.0f64, 3.0f64,
    [], 0n, [], [])) == Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n) : Y.Effect}

def ok_fx_of_body():
  {==}


law neg_eval_first_wins:
  {Y.sres_show(ev_last2(EV.ev_part(part_ff1(), Y.cache_empty(), 10000n)))
    == "invalid-input" : String}

def neg_eval_first_wins():
  {==}


law neg_evop_extrude:
  {Y.sres_show(EV.ev_op(Y.O_extrude{Y.mk_prof(sq_loop(), []), 1u64}, [], 10n))
    == "unsupported-op" : String}

def neg_evop_extrude():
  {==}


law neg_gate_mat:
  {Y.sres_show(EV.gate_publish(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_intent(Y.M_add{}, 6n, 0n, 1n, 0n))) == "invalid-input" : String}

def neg_gate_mat():
  {==}


law ok_circ_ny_zero:
  {SX.circ_ny(0.0f64) == 0.0f64 : F64}

def ok_circ_ny_zero():
  {==}


law ok_qframe_x:
  {SX.qframe(V.Dr{1.0f64, 0.0f64, 0.0f64})
    == SX.QFr{V.Dr{0.0f64, 1.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}} : SX.QFr}

def ok_qframe_x():
  {==}


law neg_surf_cone_h:
  {SX.surf_cone(G.Co{org(), axis_z(), 1.0f64}, 0.0f64, F64.neg(2.0f64))
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_cone_h():
  {==}


law ok_is_quad_cyl:
  {SX.surf_is_quad(G.GV_cy{G.Cy{org(), axis_z(), 1.0f64}}) == True{} : Bool}

def ok_is_quad_cyl():
  {==}


law neg_ring_tor_p_spin:
  {SX.ring_tor_p(G.To{org(), axis_z(), 1.0f64, 5.0f64}, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_tor_p_spin():
  {==}

