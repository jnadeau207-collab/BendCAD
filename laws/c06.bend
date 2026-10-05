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

def box_it() -> Y.Intent:
  Y.mk_intent(Y.M_create{}, 6n, 0n, 1n, 0n)

def part1() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
      Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
      Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [])], 7u64, box_it())

def part_baddim() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [])], 7u64, box_it())

def part_badroot() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
      Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
      Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [])], 99u64, box_it())

def cyl_ps() -> List<&2, Y.Param>:
  [Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
    Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64))]

def part_cyl() -> Y.Part:
  Y.mk_part(cyl_ps(),
    [Y.mk_node(7u64, Y.O_cyl{1u64, 2u64}, [])], 7u64, box_it())

def part_ff1() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 9u64, 9u64}, []), Y.mk_node(8u64, Y.O_cyl{1u64, 1u64}, [])], 8u64, box_it())

def part_ff2() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
      Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
      Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, []), Y.mk_node(8u64, Y.O_cyl{1u64, 1u64}, [])], 8u64, box_it())

def pchg0() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 1u64, 1u64}, [])], 7u64, box_it())

def pchg() -> Y.Part:
  Y.mk_part([Y.mk_param(1u64, Y.mk_dm(9.0f64, 0.5f64, 20.0f64))],
    [Y.mk_node(7u64, Y.O_box{1u64, 1u64, 1u64}, [])], 7u64, box_it())

def unit_box() -> Ty.Brep:
  O.box_core(0.0f64, 0.0f64, 0.0f64, 1.0f64, 2.0f64, 3.0f64)

def id_rigid() -> V.Rigid:
  V.Rg{V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64},
    0.0f64, 0.0f64, 0.0f64}

def org() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def axis_z() -> V.Dir:
  V.Dr{0.0f64, 0.0f64, 1.0f64}

law sok_is_ok:
  for v: Y.SVal
  {Y.sres_ok(Y.Sok{v}) == True{} : Bool}

def sok_is_ok(v):
  {==}

law serr_is_err:
  for k: T.FailKind
  for dg: Y.Diag
  {Y.sres_ok(Y.Serr{k, dg}) == False{} : Bool}

def serr_is_err(k, dg):
  {==}

law sres_show_ok:
  for v: Y.SVal
  {Y.sres_show(Y.Sok{v}) == "ok" : String}

def sres_show_ok(v):
  {==}

law serr_invalid_show:
  for w: String
  for l: String
  for y: String
  for f: String
  {Y.sres_show(Y.serr_invalid(w, l, y, f)) == "invalid-input" : String}

def serr_invalid_show(w, l, y, f):
  {==}

law serr_uncertain_show:
  for w: String
  for l: String
  for y: String
  for f: String
  {Y.sres_show(Y.serr_uncertain(w, l, y, f)) == "numerical-uncertainty" : String}

def serr_uncertain_show(w, l, y, f):
  {==}

law serr_unsupported_show:
  for w: String
  for l: String
  for y: String
  for f: String
  {Y.sres_show(Y.serr_unsupported(w, l, y, f)) == "unsupported-op" : String}

def serr_unsupported_show(w, l, y, f):
  {==}

law serr_exhausted_show:
  for w: String
  for l: String
  for y: String
  for f: String
  {Y.sres_show(Y.serr_exhausted(w, l, y, f)) == "resource-exhausted" : String}

def serr_exhausted_show(w, l, y, f):
  {==}

law sres_kind_of:
  for k: T.FailKind
  for dg: Y.Diag
  {Y.sres_kind(Y.Serr{k, dg}) == k : T.FailKind}

def sres_kind_of(k, dg):
  {==}

law sres_diag_ok:
  for v: Y.SVal
  {Y.sres_diag(Y.Sok{v}) == Y.diag_null() : Y.Diag}

def sres_diag_ok(v):
  {==}

law sres_diag_err:
  for k: T.FailKind
  for dg: Y.Diag
  {Y.sres_diag(Y.Serr{k, dg}) == dg : Y.Diag}

def sres_diag_err(k, dg):
  {==}

law sok_u_rt:
  for u: U64
  {Y.sok_u_of(Y.sok_u(u)) == u : U64}

def sok_u_rt(u):
  {==}

law sok_u_wrong_arm:
  for s: String
  {Y.sok_u_of(Y.sok_s(s)) == 0u64 : U64}

def sok_u_wrong_arm(s):
  {==}

law sok_brep_wrong_arm:
  for u: U64
  {Y.sok_brep_of(Y.sok_u(u)) == Ty.brep_empty() : Ty.Brep}

def sok_brep_wrong_arm(u):
  {==}

law diag_show_pin:
  {Y.diag_show(Y.mk_diag("box", "n7", "non-positive dim", "pass strictly positive dims"))
    == "box @ n7 [non-positive dim] fix: pass strictly positive dims" : String}

def diag_show_pin():
  {==}

law matfx_show_create:
  {Y.matfx_show(Y.M_create{}) == "create" : String}

def matfx_show_create():
  {==}

law matfx_show_add:
  {Y.matfx_show(Y.M_add{}) == "add" : String}

def matfx_show_add():
  {==}

law matfx_show_remove:
  {Y.matfx_show(Y.M_remove{}) == "remove" : String}

def matfx_show_remove():
  {==}

law matfx_show_same:
  {Y.matfx_show(Y.M_same{}) == "same" : String}

def matfx_show_same():
  {==}

law matfx_eq_same:
  {Y.matfx_eq(Y.M_create{}, Y.M_create{}) == True{} : Bool}

def matfx_eq_same():
  {==}

law matfx_eq_diff:
  {Y.matfx_eq(Y.M_create{}, Y.M_add{}) == False{} : Bool}

def matfx_eq_diff():
  {==}

law fx_show_pin:
  {Y.fx_show(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n)) == "create fc=6 fm=0 sh=1 holes=0" : String}

def fx_show_pin():
  {==}

law fx_eq_same:
  {Y.fx_eq(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n), Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n)) == True{} : Bool}

def fx_eq_same():
  {==}

law fx_eq_diff:
  {Y.fx_eq(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n), Y.mk_fx(Y.M_create{}, 5n, 0n, 1n, 0n)) == False{} : Bool}

def fx_eq_diff():
  {==}

law intent_show_pin:
  {Y.intent_show(Y.mk_intent(Y.M_add{}, 1n, 2n, 1n, 3n)) == "add fc=1 fm=2 sh=1 holes=3" : String}

def intent_show_pin():
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

law intent_check_same:
  {Y.intent_check(Y.mk_intent(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n)) == True{} : Bool}

def intent_check_same():
  {==}

law intent_check_diff:
  {Y.intent_check(Y.mk_intent(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 1n)) == False{} : Bool}

def intent_check_diff():
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

law intent_proj_fc:
  for m: Y.MatFx
  for fc: Nat
  for fm: Nat
  for sh: Nat
  for ho: Nat
  {Y.intent_fc(Y.mk_intent(m, fc, fm, sh, ho)) == fc : Nat}

def intent_proj_fc(m, fc, fm, sh, ho):
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

law dm_valid_ok:
  {Y.dm_valid(Y.mk_dm(1.0f64, 0.5f64, 2.0f64)) == True{} : Bool}

def dm_valid_ok():
  {==}

law dm_valid_zone:
  {Y.dm_valid(Y.mk_dm(1.0f64, 2.0f64, 3.0f64)) == False{} : Bool}

def dm_valid_zone():
  {==}

law dm_valid_nan:
  {Y.dm_valid(Y.mk_dm(F64.nan(), 0.0f64, 1.0f64)) == False{} : Bool}

def dm_valid_nan():
  {==}

law dm_pos_ok:
  {Y.dm_valid_pos(Y.mk_dm(1.0f64, 0.5f64, 2.0f64)) == True{} : Bool}

def dm_pos_ok():
  {==}

law dm_pos_lo:
  {Y.dm_valid_pos(Y.mk_dm(0.0f64, F64.neg(1.0f64), 1.0f64)) == False{} : Bool}

def dm_pos_lo():
  {==}

law iv_valid_ok:
  {Y.iv_valid(Y.Iv{1.0f64, 2.0f64}) == True{} : Bool}

def iv_valid_ok():
  {==}

law iv_valid_flip:
  {Y.iv_valid(Y.Iv{2.0f64, 1.0f64}) == False{} : Bool}

def iv_valid_flip():
  {==}

law iv_valid_nan:
  {Y.iv_valid(Y.Iv{F64.nan(), 1.0f64}) == False{} : Bool}

def iv_valid_nan():
  {==}

law iv_of_dm_pin:
  {Y.iv_of_dm(Y.mk_dm(1.0f64, 0.5f64, 2.0f64)) == Y.Iv{0.5f64, 2.0f64} : Y.Iv}

def iv_of_dm_pin():
  {==}

law iv_nom_pin:
  {Y.iv_nom(Y.mk_dm(1.0f64, 0.5f64, 2.0f64)) == Y.Iv{1.0f64, 1.0f64} : Y.Iv}

def iv_nom_pin():
  {==}

law prof_show_pin:
  {Y.prof_show(Y.mk_prof(sq_loop(), [])) == "loop=4 holes=0" : String}

def prof_show_pin():
  {==}

law nm_show_pin:
  {Y.nm_show(Y.mk_nm(7u64, 1u64, 11n)) == "n7.r1#11" : String}

def nm_show_pin():
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

law op_tag_box:
  {Y.op_tag(Y.O_box{1u64, 2u64, 3u64}) == 1u64 : U64}

def op_tag_box():
  {==}

law op_tag_cyl:
  {Y.op_tag(Y.O_cyl{1u64, 2u64}) == 2u64 : U64}

def op_tag_cyl():
  {==}

law op_tag_sph:
  {Y.op_tag(Y.O_sph{1u64}) == 3u64 : U64}

def op_tag_sph():
  {==}

law op_tag_cone:
  {Y.op_tag(Y.O_cone{1u64, 2u64}) == 4u64 : U64}

def op_tag_cone():
  {==}

law op_tag_tor:
  {Y.op_tag(Y.O_tor{1u64, 2u64}) == 5u64 : U64}

def op_tag_tor():
  {==}

law op_tag_extrude:
  {Y.op_tag(Y.O_extrude{Y.mk_prof(sq_loop(), []), 1u64}) == 6u64 : U64}

def op_tag_extrude():
  {==}

law op_tag_revolve:
  {Y.op_tag(Y.O_revolve{Y.mk_prof(sq_loop(), [])}) == 7u64 : U64}

def op_tag_revolve():
  {==}

law op_tag_holes:
  {Y.op_tag(Y.O_holes{7u64, []}) == 8u64 : U64}

def op_tag_holes():
  {==}

law op_tag_pocket:
  {Y.op_tag(Y.O_pocket{7u64, 0.0f64, 0.0f64, 1.0f64, 1.0f64, 2u64}) == 9u64 : U64}

def op_tag_pocket():
  {==}

law op_tag_pad:
  {Y.op_tag(Y.O_pad{7u64, 0.0f64, 0.0f64, 1u64, 2u64, 3u64}) == 10u64 : U64}

def op_tag_pad():
  {==}

law op_tag_xform:
  {Y.op_tag(Y.O_xform{7u64, id_rigid()}) == 11u64 : U64}

def op_tag_xform():
  {==}

law op_show_box:
  {Y.op_show(Y.O_box{1u64, 2u64, 3u64}) == "box" : String}

def op_show_box():
  {==}

law op_show_torus:
  {Y.op_show(Y.O_tor{1u64, 2u64}) == "torus" : String}

def op_show_torus():
  {==}

law op_show_xform:
  {Y.op_show(Y.O_xform{7u64, id_rigid()}) == "xform" : String}

def op_show_xform():
  {==}

law node_show_pin:
  {Y.node_show(Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [])) == "n7:box" : String}

def node_show_pin():
  {==}

law ok_iv_add:
  {Y.sok_iv_of(O.iv_add(Y.Iv{1.0f64, 1.0f64}, Y.Iv{2.0f64, 2.0f64}))
    == Y.Iv{F64{4613937818241073151u64}, F64{4613937818241073153u64}} : Y.Iv}

def ok_iv_add():
  {==}

law ok_iv_sub:
  {Y.sok_iv_of(O.iv_sub(Y.Iv{5.0f64, 5.0f64}, Y.Iv{2.0f64, 2.0f64}))
    == Y.Iv{F64{4613937818241073151u64}, F64{4613937818241073153u64}} : Y.Iv}

def ok_iv_sub():
  {==}

law ok_iv_mul:
  {Y.sok_iv_of(O.iv_mul(Y.Iv{2.0f64, 2.0f64}, Y.Iv{3.0f64, 3.0f64}))
    == Y.Iv{F64{4618441417868443647u64}, F64{4618441417868443649u64}} : Y.Iv}

def ok_iv_mul():
  {==}

law ok_iv_div:
  {Y.sok_iv_of(O.iv_div(Y.Iv{6.0f64, 6.0f64}, Y.Iv{2.0f64, 2.0f64}))
    == Y.Iv{F64{4613937818241073151u64}, F64{4613937818241073153u64}} : Y.Iv}

def ok_iv_div():
  {==}

law neg_iv_div_zero:
  {Y.sres_show(O.iv_div(Y.Iv{6.0f64, 6.0f64}, Y.Iv{F64.neg(1.0f64), 1.0f64}))
    == "numerical-uncertainty" : String}

def neg_iv_div_zero():
  {==}

law ok_iv_neg:
  {O.iv_neg(Y.Iv{1.0f64, 2.0f64}) == Y.Iv{F64.neg(2.0f64), F64.neg(1.0f64)} : Y.Iv}

def ok_iv_neg():
  {==}

law ok_iv_sq_pos:
  {Y.sok_iv_of(O.iv_sq(Y.Iv{2.0f64, 3.0f64}))
    == Y.Iv{F64{4616189618054758399u64}, F64{4621256167635550209u64}} : Y.Iv}

def ok_iv_sq_pos():
  {==}

law ok_iv_sq_neg:
  {Y.sok_iv_of(O.iv_sq(Y.Iv{F64.neg(3.0f64), F64.neg(2.0f64)}))
    == Y.Iv{F64{4616189618054758399u64}, F64{4621256167635550209u64}} : Y.Iv}

def ok_iv_sq_neg():
  {==}

law ok_iv_sq_straddle:
  {Y.sok_iv_of(O.iv_sq(Y.Iv{F64.neg(1.0f64), 2.0f64}))
    == Y.Iv{0.0f64, F64{4616189618054758401u64}} : Y.Iv}

def ok_iv_sq_straddle():
  {==}

law ok_iv_sqrt:
  {Y.sok_iv_of(O.iv_sqrt(Y.Iv{4.0f64, 9.0f64}))
    == Y.Iv{F64{4611686018427387903u64}, F64{4613937818241073153u64}} : Y.Iv}

def ok_iv_sqrt():
  {==}

law neg_iv_sqrt:
  {Y.sres_show(O.iv_sqrt(Y.Iv{F64.neg(1.0f64), 9.0f64})) == "invalid-input" : String}

def neg_iv_sqrt():
  {==}

law neg_iv_gate_flip:
  {Y.sres_show(O.iv_gate(2.0f64, 1.0f64)) == "numerical-uncertainty" : String}

def neg_iv_gate_flip():
  {==}

law neg_iv_gate_nan:
  {Y.sres_show(O.iv_gate(F64.nan(), 1.0f64)) == "numerical-uncertainty" : String}

def neg_iv_gate_nan():
  {==}

law ok_next_up_zero:
  {O.f64_next_up(0.0f64) == F64{1u64} : F64}

def ok_next_up_zero():
  {==}

law ok_next_down_zero:
  {O.f64_next_down(0.0f64) == F64{9223372036854775809u64} : F64}

def ok_next_down_zero():
  {==}

law ok_next_up_one:
  {O.f64_next_up(1.0f64) == F64{4607182418800017409u64} : F64}

def ok_next_up_one():
  {==}

law ok_next_down_one:
  {O.f64_next_down(1.0f64) == F64{4607182418800017407u64} : F64}

def ok_next_down_one():
  {==}

law ok_pi_iv:
  {O.pi_iv() == Y.Iv{F64{4614256656552045847u64}, F64{4614256656552045849u64}} : Y.Iv}

def ok_pi_iv():
  {==}

law iv_pt_point:
  for x: F64
  {O.iv_pt(x) == Y.Iv{x, x} : Y.Iv}

def iv_pt_point(x):
  {==}

law ok_prof_square:
  {O.prof_code(sq_loop(), [], 1000n) == 0u64 : U64}

def ok_prof_square():
  {==}

law neg_prof_bowtie:
  {O.prof_code(bow_loop(), [], 1000n) == 4u64 : U64}

def neg_prof_bowtie():
  {==}

law neg_prof_clockwise:
  {O.prof_code(cw_loop(), [], 1000n) == 5u64 : U64}

def neg_prof_clockwise():
  {==}

law neg_prof_spike:
  {O.prof_code(spike_loop(), [], 1000n) == 8u64 : U64}

def neg_prof_spike():
  {==}

law neg_prof_touch:
  {O.prof_code(touch_loop(), [], 100000n) == 7u64 : U64}

def neg_prof_touch():
  {==}

law neg_prof_cross:
  {O.prof_code(cross_loop(), [], 100000n) == 6u64 : U64}

def neg_prof_cross():
  {==}

law neg_prof_short:
  {O.prof_code([V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}], [], 1000n) == 1u64 : U64}

def neg_prof_short():
  {==}

law neg_prof_nonfinite:
  {O.prof_code([V.V2{F64.nan(), 0.0f64}, V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}], [],
    1000n) == 2u64 : U64}

def neg_prof_nonfinite():
  {==}

law neg_prof_dup:
  {O.prof_code([V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
    V.V2{0.0f64, 1.0f64}], [], 1000n) == 3u64 : U64}

def neg_prof_dup():
  {==}

law neg_prof_looptouch:
  {O.prof_code(outer_loop(), [hole_t()], 100000n) == 10u64 : U64}

def neg_prof_looptouch():
  {==}

law neg_prof_nest_ab:
  {O.prof_code(outer_loop(), [hole_a(), hole_b()], 100000n) == 12u64 : U64}

def neg_prof_nest_ab():
  {==}

law neg_prof_nest_ba:
  {O.prof_code(outer_loop(), [hole_b(), hole_a()], 100000n) == 12u64 : U64}

def neg_prof_nest_ba():
  {==}

law ok_prof_holes:
  {O.prof_code(outer_loop(), [hole_b(), hole_c()], 100000n) == 0u64 : U64}

def ok_prof_holes():
  {==}

law neg_prof_holes_cross:
  {O.prof_code(outer_loop(), [hole_a(), hole_d()], 100000n) == 11u64 : U64}

def neg_prof_holes_cross():
  {==}

law neg_prof_hole_out:
  {O.prof_code(outer_loop(), [hole_f()], 100000n) == 9u64 : U64}

def neg_prof_hole_out():
  {==}

law neg_prof_fuel:
  {O.prof_code(sq_loop(), [], 0n) == 17u64 : U64}

def neg_prof_fuel():
  {==}

law neg_prof_too_large:
  {O.prof_code(dup_pts(65n), [], 1000000n) == 18u64 : U64}

def neg_prof_too_large():
  {==}

law neg_prof_hole_short:
  {O.prof_code(outer_loop(), [[V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 1.0f64}]], 100000n)
    == 1u64 : U64}

def neg_prof_hole_short():
  {==}

law ok_sh_ccw:
  {O.sh_sign(sq_loop(), 100n) == 1u64 : U64}

def ok_sh_ccw():
  {==}

law neg_sh_cw:
  {O.sh_sign(cw_loop(), 100n) == 2u64 : U64}

def neg_sh_cw():
  {==}

law neg_sh_zero:
  {O.sh_sign(bow_loop(), 100n) == 0u64 : U64}

def neg_sh_zero():
  {==}

law ok_pip_in:
  {O.pip(0.5f64, 0.5f64, sq_loop(), 1000n) == 1u64 : U64}

def ok_pip_in():
  {==}

law ok_pip_out:
  {O.pip(2.0f64, 2.0f64, sq_loop(), 1000n) == 0u64 : U64}

def ok_pip_out():
  {==}

law ok_pip_edge:
  {O.pip(0.5f64, 0.0f64, sq_loop(), 1000n) == 2u64 : U64}

def ok_pip_edge():
  {==}

law ok_pip_corner:
  {O.pip(0.0f64, 0.0f64, sq_loop(), 1000n) == 2u64 : U64}

def ok_pip_corner():
  {==}

law pip_empty:
  for px: F64
  for py: F64
  for fuel: Nat
  {O.pip(px, py, [], fuel) == 0u64 : U64}

def pip_empty(px, py, fuel):
  {==}

law pick_nz_zero:
  for b: U64
  {O.pick_nz(0u64, b) == b : U64}

def pick_nz_zero(b):
  {==}

law pick_nz_nz:
  for b: U64
  {O.pick_nz(5u64, b) == 5u64 : U64}

def pick_nz_nz(b):
  {==}

law fold_codes_empty:
  for fuel: Nat
  {O.fold_codes([], fuel) == 0u64 : U64}

def fold_codes_empty(fuel):
  {==}

law fin_code_ok:
  {O.fin_code(sq_loop(), 100n) == 0u64 : U64}

def fin_code_ok():
  {==}

law fin_code_bad:
  {O.fin_code([V.V2{F64.nan(), 0.0f64}], 100n) == 2u64 : U64}

def fin_code_bad():
  {==}

law dist_code_ok:
  {O.dist_code(sq_loop(), 100n) == 0u64 : U64}

def dist_code_ok():
  {==}

law dist_code_dup:
  {O.dist_code([V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64}], 100n)
    == 3u64 : U64}

def dist_code_dup():
  {==}

law ok_prof_go_zero:
  {Y.sok_u_of(O.prof_go(0u64, "profile")) == 0u64 : U64}

def ok_prof_go_zero():
  {==}

law neg_prof_go_short:
  {Y.sres_show(O.prof_go(1u64, "profile")) == "invalid-input" : String}

def neg_prof_go_short():
  {==}

law neg_prof_go_nonfinite:
  {Y.sres_show(O.prof_go(2u64, "profile")) == "invalid-input" : String}

def neg_prof_go_nonfinite():
  {==}

law neg_prof_go_dup:
  {Y.sres_show(O.prof_go(3u64, "profile")) == "invalid-input" : String}

def neg_prof_go_dup():
  {==}

law neg_prof_go_area:
  {Y.sres_show(O.prof_go(4u64, "profile")) == "invalid-input" : String}

def neg_prof_go_area():
  {==}

law neg_prof_go_winding:
  {Y.sres_show(O.prof_go(5u64, "profile")) == "invalid-input" : String}

def neg_prof_go_winding():
  {==}

law neg_prof_go_xing:
  {Y.sres_show(O.prof_go(6u64, "profile")) == "invalid-input" : String}

def neg_prof_go_xing():
  {==}

law neg_prof_go_touch:
  {Y.sres_show(O.prof_go(7u64, "profile")) == "invalid-input" : String}

def neg_prof_go_touch():
  {==}

law neg_prof_go_spike:
  {Y.sres_show(O.prof_go(8u64, "profile")) == "invalid-input" : String}

def neg_prof_go_spike():
  {==}

law neg_prof_go_outside:
  {Y.sres_show(O.prof_go(9u64, "profile")) == "invalid-input" : String}

def neg_prof_go_outside():
  {==}

law neg_prof_go_looptouch:
  {Y.sres_show(O.prof_go(10u64, "profile")) == "invalid-input" : String}

def neg_prof_go_looptouch():
  {==}

law neg_prof_go_loopxing:
  {Y.sres_show(O.prof_go(11u64, "profile")) == "invalid-input" : String}

def neg_prof_go_loopxing():
  {==}

law neg_prof_go_nest:
  {Y.sres_show(O.prof_go(12u64, "profile")) == "invalid-input" : String}

def neg_prof_go_nest():
  {==}

law neg_prof_go_uncertain:
  {Y.sres_show(O.prof_go(13u64, "profile")) == "numerical-uncertainty" : String}

def neg_prof_go_uncertain():
  {==}

law neg_prof_go_axcross:
  {Y.sres_show(O.prof_go(14u64, "revolve")) == "invalid-input" : String}

def neg_prof_go_axcross():
  {==}

law neg_prof_go_pinch:
  {Y.sres_show(O.prof_go(15u64, "revolve")) == "invalid-input" : String}

def neg_prof_go_pinch():
  {==}

law neg_prof_go_hoax:
  {Y.sres_show(O.prof_go(16u64, "revolve")) == "invalid-input" : String}

def neg_prof_go_hoax():
  {==}

law neg_prof_go_fuel:
  {Y.sres_show(O.prof_go(17u64, "profile")) == "resource-exhausted" : String}

def neg_prof_go_fuel():
  {==}

law neg_prof_go_large:
  {Y.sres_show(O.prof_go(18u64, "profile")) == "resource-exhausted" : String}

def neg_prof_go_large():
  {==}

law neg_prof_go_breakout:
  {Y.sres_show(O.prof_go(19u64, "profile")) == "invalid-input" : String}

def neg_prof_go_breakout():
  {==}

law neg_prof_go_merge:
  {Y.sres_show(O.prof_go(20u64, "profile")) == "invalid-input" : String}

def neg_prof_go_merge():
  {==}

law neg_prof_go_boss:
  {Y.sres_show(O.prof_go(21u64, "profile")) == "invalid-input" : String}

def neg_prof_go_boss():
  {==}

law neg_prof_go_padover:
  {Y.sres_show(O.prof_go(22u64, "profile")) == "invalid-input" : String}

def neg_prof_go_padover():
  {==}

law neg_prof_go_foot:
  {Y.sres_show(O.prof_go(23u64, "profile")) == "invalid-input" : String}

def neg_prof_go_foot():
  {==}

law neg_prof_go_blind:
  {Y.sres_show(O.prof_go(24u64, "profile")) == "unsupported-op" : String}

def neg_prof_go_blind():
  {==}

law neg_prof_go_unknown:
  {Y.sres_show(O.prof_go(99u64, "profile")) == "invalid-input" : String}

def neg_prof_go_unknown():
  {==}

law diag_prof_go_winding:
  {Y.diag_show(Y.sres_diag(O.prof_go(5u64, "profile")))
    == "profile loop @ profile [winding] fix: reverse the loop (outer CCW, holes CW)" : String}

def diag_prof_go_winding():
  {==}

law diag_prof_go_uncertain:
  {Y.diag_show(Y.sres_diag(O.prof_go(13u64, "profile")))
    == "predicate @ profile [predicate-uncertain] fix: perturb coordinates slightly" : String}

def diag_prof_go_uncertain():
  {==}

law diag_prof_go_fuel:
  {Y.diag_show(Y.sres_diag(O.prof_go(17u64, "profile")))
    == "fuel @ profile [fuel-out] fix: raise the fuel cap" : String}

def diag_prof_go_fuel():
  {==}

law diag_prof_go_blind:
  {Y.diag_show(Y.sres_diag(O.prof_go(24u64, "profile")))
    == "pocket @ profile [blind-pocket] fix: use depth >= thickness (through) or wait for C08" : String}

def diag_prof_go_blind():
  {==}

law ok_prof_valid:
  {Y.sres_show(O.prof_valid(Y.mk_prof(sq_loop(), []), 1000n)) == "ok" : String}

def ok_prof_valid():
  {==}

law neg_prof_valid_bow:
  {Y.sres_show(O.prof_valid(Y.mk_prof(bow_loop(), []), 1000n)) == "invalid-input" : String}

def neg_prof_valid_bow():
  {==}

law ok_rev_ax:
  {O.rev_ax(rev_sq(), 100000n) == 0u64 : U64}

def ok_rev_ax():
  {==}

law neg_rev_pinch:
  {O.rev_ax(rev_tri(), 100000n) == 15u64 : U64}

def neg_rev_pinch():
  {==}

law neg_rev_below:
  {O.rev_ax(rev_below(), 100000n) == 14u64 : U64}

def neg_rev_below():
  {==}

law neg_rev_mid:
  {O.rev_ax(rev_mid(), 100000n) == 15u64 : U64}

def neg_rev_mid():
  {==}

law neg_rev_last:
  {O.rev_ax(rev_last(), 100000n) == 15u64 : U64}

def neg_rev_last():
  {==}

law neg_rev_hole_axis:
  {O.rev_hole_go([rev_hole_ax()], 100n) == 16u64 : U64}

def neg_rev_hole_axis():
  {==}

law ok_rev_hole:
  {O.rev_hole_go([rev_hole_ok()], 100n) == 0u64 : U64}

def ok_rev_hole():
  {==}

law ok_rev_prof:
  {Y.sres_show(O.prof_valid_rev(Y.mk_prof(rev_sq(), []), 100000n)) == "ok" : String}

def ok_rev_prof():
  {==}

law neg_rev_prof_cross:
  {Y.sres_show(O.prof_valid_rev(Y.mk_prof(rev_below(), []), 100000n))
    == "invalid-input" : String}

def neg_rev_prof_cross():
  {==}

law neg_hole_breakout:
  {O.hole_clr_loop(1.5f64, 0.5f64, 1.0f64, sq_loop(), 100n) == 19u64 : U64}

def neg_hole_breakout():
  {==}

law neg_hole_tangent:
  {O.hole_clr_loop(2.0f64, 0.5f64, 1.0f64, sq_loop(), 100n) == 19u64 : U64}

def neg_hole_tangent():
  {==}

law ok_hole_clear:
  {O.hole_clr_loop(5.0f64, 5.0f64, 1.0f64, sq_loop(), 100n) == 0u64 : U64}

def ok_hole_clear():
  {==}

law neg_hole_merge:
  {O.hole_hh(0.0f64, 0.0f64, 2.0f64, 1.0f64, 0.0f64, 2.0f64) == 20u64 : U64}

def neg_hole_merge():
  {==}

law ok_hole_pair:
  {O.hole_hh(0.0f64, 0.0f64, 1.0f64, 5.0f64, 0.0f64, 1.0f64) == 0u64 : U64}

def ok_hole_pair():
  {==}

law neg_hole_boss:
  {O.hole_boss1(0.0f64, 0.0f64, 1.0f64, Y.mk_boss(0.0f64, 0.0f64, 4.0f64, 4.0f64, 0.0f64,
    1.0f64)) == 21u64 : U64}

def neg_hole_boss():
  {==}

law ok_hole_boss:
  {O.hole_boss1(10.0f64, 10.0f64, 1.0f64, Y.mk_boss(0.0f64, 0.0f64, 4.0f64, 4.0f64,
    0.0f64, 1.0f64)) == 0u64 : U64}

def ok_hole_boss():
  {==}

law neg_hole_rect:
  {O.hole_rect(0.0f64, 0.0f64, 5.0f64, F64.neg(1.0f64), F64.neg(1.0f64), 1.0f64, 1.0f64)
    == 21u64 : U64}

def neg_hole_rect():
  {==}

law ok_hole_rect:
  {O.hole_rect(10.0f64, 10.0f64, 1.0f64, 0.0f64, 0.0f64, 4.0f64, 4.0f64) == 0u64 : U64}

def ok_hole_rect():
  {==}

law ok_rect_disj:
  {O.rect_disj(0.0f64, 0.0f64, 1.0f64, 1.0f64, 5.0f64, 5.0f64, 1.0f64, 1.0f64)
    == True{} : Bool}

def ok_rect_disj():
  {==}

law neg_rect_disj:
  {O.rect_disj(0.0f64, 0.0f64, 2.0f64, 2.0f64, 1.0f64, 1.0f64, 2.0f64, 2.0f64)
    == False{} : Bool}

def neg_rect_disj():
  {==}

law ok_box:
  {box318(O.box_checked(0.0f64, 0.0f64, 0.0f64, 1.0f64, 2.0f64, 3.0f64, 10000n))
    == True{} : Bool}

def ok_box():
  {==}

law ok_box_frac:
  {box318(O.box_checked(0.1f64, 0.2f64, 0.3f64, 0.4f64, 0.5f64, 0.6f64, 10000n))
    == True{} : Bool}

def ok_box_frac():
  {==}

law neg_box_zero:
  {Y.sres_show(O.box_checked(0.0f64, 0.0f64, 0.0f64, 0.0f64, 2.0f64, 3.0f64, 10000n))
    == "invalid-input" : String}

def neg_box_zero():
  {==}

law neg_box_negdim:
  {Y.sres_show(O.box_checked(0.0f64, 0.0f64, 0.0f64, F64.neg(1.0f64), 2.0f64, 3.0f64,
    10000n)) == "invalid-input" : String}

def neg_box_negdim():
  {==}

law neg_box_nan:
  {Y.sres_show(O.box_checked(0.0f64, 0.0f64, 0.0f64, 1.0f64, 2.0f64, F64.nan(), 10000n))
    == "invalid-input" : String}

def neg_box_nan():
  {==}

law neg_box_over:
  {Y.sres_show(O.box_checked(1.0e308f64, 0.0f64, 0.0f64, 1.0e308f64, 1.0f64, 1.0f64,
    10000n)) == "numerical-uncertainty" : String}

def neg_box_over():
  {==}

law neg_box_fin_first:
  {Y.sres_show(O.box_checked(F64.nan(), 0.0f64, 0.0f64, 1.0e308f64, 1.0f64, 1.0f64,
    10000n)) == "invalid-input" : String}

def neg_box_fin_first():
  {==}

law neg_box_pos_first:
  {Y.sres_show(O.box_checked(1.0e308f64, 0.0f64, 0.0f64, 1.0e308f64, 0.0f64, 1.0f64,
    10000n)) == "invalid-input" : String}

def neg_box_pos_first():
  {==}

law ok_box_adversarial:
  {box318(O.box_checked(97398.60767117864f64, F64.neg(971916.5996719621f64), 0.0f64,
    1.0f64, 2.0f64, 3.0f64, 10000n)) == True{} : Bool}

def ok_box_adversarial():
  {==}

law ok_box_negcorner:
  {box318(O.box_checked(F64.neg(5.0f64), F64.neg(5.0f64), F64.neg(5.0f64), 1.0f64,
    2.0f64, 3.0f64, 10000n)) == True{} : Bool}

def ok_box_negcorner():
  {==}

law ok_box_counts:
  {boxcounts7(unit_box()) == True{} : Bool}

def ok_box_counts():
  {==}

law ok_box_gen_vx:
  {Ty.vx_gen(nth_vx(Ty.brep_vs(unit_box()), 0n)) == 1u64 : U64}

def ok_box_gen_vx():
  {==}

law ok_box_gen_ed:
  {Ty.ed_gen(nth_ed(Ty.brep_es(unit_box()), 0n)) == 9u64 : U64}

def ok_box_gen_ed():
  {==}

law ok_box_gen_ce:
  {Ty.ce_gen(nth_ce(Ty.brep_ces(unit_box()), 0n)) == 21u64 : U64}

def ok_box_gen_ce():
  {==}

law ok_box_gen_lp:
  {Ty.lp_gen(nth_lp(Ty.brep_lps(unit_box()), 0n)) == 45u64 : U64}

def ok_box_gen_lp():
  {==}

law ok_box_gen_fa:
  {Ty.fa_gen(nth_fa(Ty.brep_fas(unit_box()), 0n)) == 51u64 : U64}

def ok_box_gen_fa():
  {==}

law ok_box_gen_sh:
  {Ty.sh_gen(nth_sh(Ty.brep_shs(unit_box()), 0n)) == 57u64 : U64}

def ok_box_gen_sh():
  {==}

law ok_box_gen_so:
  {Ty.so_gen(nth_so(Ty.brep_sos(unit_box()), 0n)) == 58u64 : U64}

def ok_box_gen_so():
  {==}

law neg_box_fin:
  {O.box_fin(F64.nan(), 0.0f64, 0.0f64, 1.0f64, 2.0f64, 3.0f64) == False{} : Bool}

def neg_box_fin():
  {==}

law ok_box_pos:
  {O.box_pos(1.0f64, 2.0f64, 3.0f64) == True{} : Bool}

def ok_box_pos():
  {==}

law neg_box_pos_zero:
  {O.box_pos(0.0f64, 2.0f64, 3.0f64) == False{} : Bool}

def neg_box_pos_zero():
  {==}

law neg_box_pos_neg:
  {O.box_pos(F64.neg(1.0f64), 2.0f64, 3.0f64) == False{} : Bool}

def neg_box_pos_neg():
  {==}

law neg_box_sum:
  {O.box_sum_fin(1.0e308f64, 0.0f64, 0.0f64, 1.0e308f64, 1.0f64, 1.0f64)
    == False{} : Bool}

def neg_box_sum():
  {==}

law neg_stage_zero:
  {Y.sres_show(O.stage_go(0u64)) == "invalid-input" : String}

def neg_stage_zero():
  {==}

law neg_stage_incid:
  {Y.sres_show(O.stage_go(2u64)) == "invalid-input" : String}

def neg_stage_incid():
  {==}

law neg_stage_use:
  {Y.sres_show(O.stage_go(3u64)) == "invalid-input" : String}

def neg_stage_use():
  {==}

law neg_stage_loop:
  {Y.sres_show(O.stage_go(4u64)) == "invalid-input" : String}

def neg_stage_loop():
  {==}

law neg_stage_facekind:
  {Y.sres_show(O.stage_go(5u64)) == "invalid-input" : String}

def neg_stage_facekind():
  {==}

law neg_stage_owner:
  {Y.sres_show(O.stage_go(6u64)) == "invalid-input" : String}

def neg_stage_owner():
  {==}

law neg_stage_embed:
  {Y.sres_show(O.stage_go(7u64)) == "numerical-uncertainty" : String}

def neg_stage_embed():
  {==}

law neg_stage_link:
  {Y.sres_show(O.stage_go(8u64)) == "invalid-input" : String}

def neg_stage_link():
  {==}

law neg_stage_conn:
  {Y.sres_show(O.stage_go(9u64)) == "invalid-input" : String}

def neg_stage_conn():
  {==}

law neg_stage_coin:
  {Y.sres_show(O.stage_go(10u64)) == "invalid-input" : String}

def neg_stage_coin():
  {==}

law neg_stage_xing:
  {Y.sres_show(O.stage_go(11u64)) == "invalid-input" : String}

def neg_stage_xing():
  {==}

law neg_stage_orient:
  {Y.sres_show(O.stage_go(12u64)) == "invalid-input" : String}

def neg_stage_orient():
  {==}

law neg_stage_unknown:
  {Y.sres_show(O.stage_go(99u64)) == "invalid-input" : String}

def neg_stage_unknown():
  {==}

law neg_stage_fuel_lo:
  {Y.sres_show(O.stage_ex(102u64)) == "resource-exhausted" : String}

def neg_stage_fuel_lo():
  {==}

law neg_stage_fuel_hi:
  {Y.sres_show(O.stage_ex(112u64)) == "resource-exhausted" : String}

def neg_stage_fuel_hi():
  {==}

law neg_stage_ex_unknown:
  {Y.sres_show(O.stage_ex(99u64)) == "invalid-input" : String}

def neg_stage_ex_unknown():
  {==}

law neg_att_zero:
  {Y.sres_show(O.att_go(0u64)) == "invalid-input" : String}

def neg_att_zero():
  {==}

law neg_att_first:
  {Y.sres_show(O.att_go(1u64)) == "invalid-input" : String}

def neg_att_first():
  {==}

law neg_att_last:
  {Y.sres_show(O.att_go(21u64)) == "invalid-input" : String}

def neg_att_last():
  {==}

law neg_att_fuel:
  {Y.sres_show(O.att_go(100u64)) == "resource-exhausted" : String}

def neg_att_fuel():
  {==}

law neg_att_unknown:
  {Y.sres_show(O.att_go(99u64)) == "invalid-input" : String}

def neg_att_unknown():
  {==}

law ok_att3_all:
  {O.att3(3n, 3n, 3n, 1u64) == 0u64 : U64}

def ok_att3_all():
  {==}

law neg_att3_all_c:
  {O.att3(2n, 3n, 3n, 1u64) == 1u64 : U64}

def neg_att3_all_c():
  {==}

law neg_att3_gen:
  {O.att3(3n, 2n, 3n, 1u64) == 2u64 : U64}

def neg_att3_gen():
  {==}

law neg_att3_nodup:
  {O.att3(3n, 3n, 2n, 1u64) == 3u64 : U64}

def neg_att3_nodup():
  {==}

law ok_stc_pass:
  {O.stc(3n, 5u64) == 0u64 : U64}

def ok_stc_pass():
  {==}

law neg_stc_fail:
  {O.stc(2n, 5u64) == 5u64 : U64}

def neg_stc_fail():
  {==}

law neg_stc_undecided:
  {O.stc(0n, 5u64) == 105u64 : U64}

def neg_stc_undecided():
  {==}

law bulk_c_passthrough:
  for b: Ty.Brep
  for fuel: Nat
  {O.bulk_c(Ty.Tok{Ty.T_brep{b}}, b, fuel) == Y.sok_brep(b) : Y.SRes}

def bulk_c_passthrough(b, fuel):
  {==}

law neg_bulk_c_terr:
  {Y.sres_show(O.bulk_c(Ty.Terr{T.F_invalid{}}, unit_box(), 10000n))
    == "invalid-input" : String}

def neg_bulk_c_terr():
  {==}

law ok_bulk_a:
  {Y.sres_show(O.bulk_a(Ty.tok_brep(unit_box()), Ty.brep_vs(unit_box()),
    Ty.brep_es(unit_box()), Ty.brep_ces(unit_box()), Ty.brep_lps(unit_box()),
    Ty.brep_fas(unit_box()), Ty.brep_shs(unit_box()), Ty.brep_sos(unit_box()), 58u64,
    10000n)) == "ok" : String}

def ok_bulk_a():
  {==}

law neg_bulk_a_att:
  {Y.sres_show(O.bulk_a(Ty.Terr{T.F_invalid{}}, [], [], [], [], [], [], [], 58u64, 100n))
    == "invalid-input" : String}

def neg_bulk_a_att():
  {==}

law neg_diag_valid_box:
  {Y.sres_show(O.diag_brep(unit_box(), 10000n)) == "invalid-input" : String}

def neg_diag_valid_box():
  {==}

def hash_ps() -> List<&2, Y.Param>:
  [Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
    Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
    Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64)),
    Y.mk_param(4u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64))]

law ok_node_hash_box:
  {EV.node_hash(Y.O_box{1u64, 2u64, 3u64},
    [Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
      Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
      Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))], [])
    == 1606728812698307254u64 : U64}

def ok_node_hash_box():
  {==}

law node_hash_zone:
  {U64.is_eq(EV.node_hash(Y.O_box{1u64, 2u64, 3u64},
      [Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
        Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
        Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))], []),
      EV.node_hash(Y.O_box{1u64, 2u64, 3u64},
        [Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 9.0f64)),
          Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
          Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))], []))
    == False{} : Bool}

def node_hash_zone():
  {==}

law node_hash_dim_id:
  {U64.is_eq(EV.node_hash(Y.O_box{1u64, 2u64, 3u64}, hash_ps(), []),
      EV.node_hash(Y.O_box{4u64, 2u64, 3u64}, hash_ps(), []))
    == False{} : Bool}

def node_hash_dim_id():
  {==}

law node_hash_ins:
  {U64.is_eq(EV.node_hash(Y.O_box{1u64, 2u64, 3u64}, hash_ps(), []),
      EV.node_hash(Y.O_box{1u64, 2u64, 3u64}, hash_ps(), [9u64]))
    == False{} : Bool}

def node_hash_ins():
  {==}

law node_hash_cyl:
  {U64.is_eq(EV.node_hash(Y.O_cyl{1u64, 2u64}, [], []), 2u64)
    == False{} : Bool}

def node_hash_cyl():
  {==}

law node_hash_sph:
  {U64.is_eq(EV.node_hash(Y.O_sph{1u64}, [], []), 3u64) == False{} : Bool}

def node_hash_sph():
  {==}

law node_hash_cone:
  {U64.is_eq(EV.node_hash(Y.O_cone{1u64, 2u64}, [], []), 4u64)
    == False{} : Bool}

def node_hash_cone():
  {==}

law node_hash_tor:
  {U64.is_eq(EV.node_hash(Y.O_tor{1u64, 2u64}, [], []), 5u64)
    == False{} : Bool}

def node_hash_tor():
  {==}

law node_hash_extrude:
  {U64.is_eq(EV.node_hash(Y.O_extrude{Y.mk_prof(sq_loop(), []), 1u64},
      [], []), 6u64) == False{} : Bool}

def node_hash_extrude():
  {==}

law node_hash_revolve:
  {U64.is_eq(EV.node_hash(Y.O_revolve{Y.mk_prof(sq_loop(), [])}, [], []),
      7u64) == False{} : Bool}

def node_hash_revolve():
  {==}

law node_hash_holes:
  {U64.is_eq(EV.node_hash(Y.O_holes{7u64, []}, [], []), 8u64)
    == False{} : Bool}

def node_hash_holes():
  {==}

law node_hash_pocket:
  {U64.is_eq(EV.node_hash(Y.O_pocket{7u64, 0.0f64, 0.0f64, 1.0f64, 1.0f64,
      2u64}, [], []), 9u64) == False{} : Bool}

def node_hash_pocket():
  {==}

law node_hash_pad:
  {U64.is_eq(EV.node_hash(Y.O_pad{7u64, 0.0f64, 0.0f64, 1u64, 2u64, 3u64},
      [], []), 10u64) == False{} : Bool}

def node_hash_pad():
  {==}

def sres_why(r: Y.SRes) -> String:
  match r:
    case Y.Sok{v}: ""
    case Y.Serr{k, dg}:
      Y.Dg{+what, +loc, +why, +fix} = dg
      why

def zone_wide() -> Y.Dim:
  Y.mk_dm(2.0f64, 1.0f64, 3.0f64)

def zone_pt() -> Y.Dim:
  Y.mk_dm(2.0f64, 2.0f64, 2.0f64)

law zone_not_nominal:
  {Bool.and(String.eq(Y.sres_show(O.ms_zone(zone_wide(), zone_pt(),
      zone_pt())), "ok"),
    Bool.and(String.eq(Y.sres_show(O.ms_nom_vol(zone_wide(), zone_pt(),
        zone_pt())), "ok"),
      F64.is_lt(Y.iv_lo(Y.sok_iv_of(O.ms_zone(zone_wide(), zone_pt(),
          zone_pt()))),
        Y.iv_lo(Y.sok_iv_of(O.ms_nom_vol(zone_wide(), zone_pt(),
          zone_pt()))))))
    == True{} : Bool}

def zone_not_nominal():
  {==}

law neg_ev_box_zone:
  {Bool.and(String.eq(sres_why(EV.ev_box(1u64, 2u64, 3u64,
      [Y.mk_param(1u64, Y.mk_dm(1.0f64, 5.0f64, 9.0f64)),
        Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
        Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))],
      10000n)), "zone"),
    String.eq(sres_why(EV.ev_box(9u64, 2u64, 3u64, hash_ps(),
      10000n)), "unknown dim id"))
    == True{} : Bool}

def neg_ev_box_zone():
  {==}

law node_hash_xform:
  {U64.is_eq(EV.node_hash(Y.O_xform{7u64, id_rigid()}, [], []), 11u64)
    == False{} : Bool}

def node_hash_xform():
  {==}

law ok_fnv_step:
  {EV.fnv_step(1u64, 2u64) == 1099511628213u64 : U64}

def ok_fnv_step():
  {==}

law ok_pm_hit:
  {EV.px_hit(EV.px_of([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64))]), 1u64)
    == True{} : Bool}

def ok_pm_hit():
  {==}

law neg_pm_hit:
  {EV.px_hit(EV.px_of([Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64))]), 9u64)
    == False{} : Bool}

def neg_pm_hit():
  {==}

law ok_pm_nom:
  {EV.px_nom(EV.px_of([Y.mk_param(5u64, Y.mk_dm(7.0f64, 6.0f64, 8.0f64))]), 5u64)
    == 7.0f64 : F64}

def ok_pm_nom():
  {==}

law neg_ev_wrap_other:
  {Y.sres_show(EV.ev_wrap(Y.sok_u(5u64), 1.0f64, 2.0f64, 3.0f64))
    == "unsupported-op" : String}

def neg_ev_wrap_other():
  {==}

law ok_ev_wrap_kind:
  {Y.body_kind(Y.sok_body_of(EV.ev_wrap(Y.sok_brep(Ty.brep_empty()), 1.0f64, 2.0f64,
    3.0f64))) == 0u64 : U64}

def ok_ev_wrap_kind():
  {==}

law cc_covers_empty:
  for items: List<&2, Y.Built>
  {EV.cc_covers(items, []) == True{} : Bool}

def cc_covers_empty(items):
  {==}

law ok_cc_find_hit:
  {EV.cc_find([EV.bt_dummy()], 0u64)
    == EV.CO{True{}, EV.bt_dummy()} : EV.CcOut}

def ok_cc_find_hit():
  {==}

law neg_cc_find_miss:
  {EV.cc_find([EV.bt_dummy()], 9u64)
    == EV.CO{False{}, EV.bt_dummy()} : EV.CcOut}

def neg_cc_find_miss():
  {==}

law sres_is_body_yes:
  for b: Y.Body
  {EV.sres_is_body(Y.sok_body(b)) == True{} : Bool}

def sres_is_body_yes(b):
  {==}

law sres_is_body_no:
  for k: T.FailKind
  for dg: Y.Diag
  {EV.sres_is_body(Y.Serr{k, dg}) == False{} : Bool}

def sres_is_body_no(k, dg):
  {==}

law sres_body_yes:
  for b: Y.Body
  {EV.sres_body(Y.sok_body(b)) == b : Y.Body}

def sres_body_yes(b):
  {==}

law sres_body_no:
  for k: T.FailKind
  for dg: Y.Diag
  {EV.sres_body(Y.Serr{k, dg}) == EV.dummy_body() : Y.Body}

def sres_body_no(k, dg):
  {==}

law ok_fx_of_body:
  {EV.fx_of_body(Y.mk_body(unit_box(), 0u64, Y.mk_prof(sq_loop(), []), 0.0f64, 3.0f64,
    [], 0n, [], [])) == Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n) : Y.Effect}

def ok_fx_of_body():
  {==}

law ok_eval_fresh:
  {root318(EV.ev_part(part1(), Y.cache_empty(), 10000n)) == True{} : Bool}

def ok_eval_fresh():
  {==}

law ok_eval_reuse:
  {root318(EV.ev_part(part1(), ev_cc2(EV.ev_part(part1(), Y.cache_empty(), 10000n)),
    10000n)) == True{} : Bool}

def ok_eval_reuse():
  {==}

law ok_eval_stale_rebuild:
  {stale_dims_ok(EV.ev_part(pchg(), ev_cc2(EV.ev_part(pchg0(), Y.cache_empty(), 10000n)),
    10000n)) == True{} : Bool}

def ok_eval_stale_rebuild():
  {==}

law neg_eval_baddim:
  {Y.sres_show(ev_last2(EV.ev_part(part_baddim(), Y.cache_empty(), 10000n)))
    == "invalid-input" : String}

def neg_eval_baddim():
  {==}

law neg_eval_badroot:
  {Y.sres_show(ev_last2(EV.ev_part(part_badroot(), Y.cache_empty(), 10000n)))
    == "invalid-input" : String}

def neg_eval_badroot():
  {==}

law neg_eval_cyl:
  {Y.sres_show(ev_last2(EV.ev_part(part_cyl(), Y.cache_empty(), 10000n)))
    == "unsupported-op" : String}

def neg_eval_cyl():
  {==}

law neg_eval_empty:
  {Y.sres_show(ev_last2(EV.ev_part(Y.mk_part([], [], 99u64, box_it()), Y.cache_empty(), 10000n)))
    == "invalid-input" : String}

def neg_eval_empty():
  {==}

law neg_eval_first_wins:
  {Y.sres_show(ev_last2(EV.ev_part(part_ff1(), Y.cache_empty(), 10000n)))
    == "invalid-input" : String}

def neg_eval_first_wins():
  {==}

law neg_eval_second_fails:
  {Y.sres_show(ev_last2(EV.ev_part(part_ff2(), Y.cache_empty(), 10000n)))
    == "unsupported-op" : String}

def neg_eval_second_fails():
  {==}

law ok_eval_origin_z0:
  {bd_z0(ev_body(EV.ev_part(part1(), Y.cache_empty(), 10000n))) == 0.0f64 : F64}

def ok_eval_origin_z0():
  {==}

law ok_eval_origin_z1:
  {bd_z1(ev_body(EV.ev_part(part1(), Y.cache_empty(), 10000n))) == 3.0f64 : F64}

def ok_eval_origin_z1():
  {==}

law neg_evop_cyl:
  {Y.sres_show(EV.ev_op(Y.O_cyl{1u64, 2u64}, [], 10n)) == "unsupported-op" : String}

def neg_evop_cyl():
  {==}

law neg_evop_sph:
  {Y.sres_show(EV.ev_op(Y.O_sph{1u64}, [], 10n)) == "unsupported-op" : String}

def neg_evop_sph():
  {==}

law neg_evop_cone:
  {Y.sres_show(EV.ev_op(Y.O_cone{1u64, 2u64}, [], 10n)) == "unsupported-op" : String}

def neg_evop_cone():
  {==}

law neg_evop_tor:
  {Y.sres_show(EV.ev_op(Y.O_tor{1u64, 2u64}, [], 10n)) == "unsupported-op" : String}

def neg_evop_tor():
  {==}

law neg_evop_extrude:
  {Y.sres_show(EV.ev_op(Y.O_extrude{Y.mk_prof(sq_loop(), []), 1u64}, [], 10n))
    == "unsupported-op" : String}

def neg_evop_extrude():
  {==}

law neg_evop_revolve:
  {Y.sres_show(EV.ev_op(Y.O_revolve{Y.mk_prof(sq_loop(), [])}, [], 10n))
    == "unsupported-op" : String}

def neg_evop_revolve():
  {==}

law neg_evop_holes:
  {Y.sres_show(EV.ev_op(Y.O_holes{7u64, []}, [], 10n)) == "unsupported-op" : String}

def neg_evop_holes():
  {==}

law neg_evop_pocket:
  {Y.sres_show(EV.ev_op(Y.O_pocket{7u64, 0.0f64, 0.0f64, 1.0f64, 1.0f64, 2u64}, [], 10n))
    == "unsupported-op" : String}

def neg_evop_pocket():
  {==}

law neg_evop_pad:
  {Y.sres_show(EV.ev_op(Y.O_pad{7u64, 0.0f64, 0.0f64, 1u64, 2u64, 3u64}, [], 10n))
    == "unsupported-op" : String}

def neg_evop_pad():
  {==}

law neg_evop_xform:
  {Y.sres_show(EV.ev_op(Y.O_xform{7u64, id_rigid()}, [], 10n)) == "unsupported-op" : String}

def neg_evop_xform():
  {==}

law ok_gate:
  {EV.gate_publish(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_intent(Y.M_create{}, 6n, 0n, 1n, 0n))
    == Y.sok_fx(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n)) : Y.SRes}

def ok_gate():
  {==}

law neg_gate_fc:
  {Y.sres_show(EV.gate_publish(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_intent(Y.M_create{}, 5n, 0n, 1n, 0n))) == "invalid-input" : String}

def neg_gate_fc():
  {==}

law neg_gate_mat:
  {Y.sres_show(EV.gate_publish(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_intent(Y.M_add{}, 6n, 0n, 1n, 0n))) == "invalid-input" : String}

def neg_gate_mat():
  {==}

law neg_gate_fm:
  {Y.sres_show(EV.gate_publish(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_intent(Y.M_create{}, 6n, 1n, 1n, 0n))) == "invalid-input" : String}

def neg_gate_fm():
  {==}

law neg_gate_shells:
  {Y.sres_show(EV.gate_publish(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_intent(Y.M_create{}, 6n, 0n, 2n, 0n))) == "invalid-input" : String}

def neg_gate_shells():
  {==}

law neg_gate_holes:
  {Y.sres_show(EV.gate_publish(Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n),
    Y.mk_intent(Y.M_create{}, 6n, 0n, 1n, 1n))) == "invalid-input" : String}

def neg_gate_holes():
  {==}

law ok_box_names_len:
  {Nat.is_eq(List.length(&2, Y.Nm, EV.box_names(7u64)), 26n) == True{} : Bool}

def ok_box_names_len():
  {==}

law ok_box_names_first:
  {Y.nm_show(nm_nth(EV.box_names(7u64), 0n)) == "n7.r0#0" : String}

def ok_box_names_first():
  {==}

law ok_box_names_last:
  {Y.nm_show(nm_nth(EV.box_names(7u64), 25n)) == "n7.r2#7" : String}

def ok_box_names_last():
  {==}

law ok_circ_nx_zero:
  {SX.circ_nx(0.0f64) == 1.0f64 : F64}

def ok_circ_nx_zero():
  {==}

law ok_circ_ny_zero:
  {SX.circ_ny(0.0f64) == 0.0f64 : F64}

def ok_circ_ny_zero():
  {==}

law ok_circ_nx_one:
  {SX.circ_nx(1.0f64) == F64.neg(1.0f64) : F64}

def ok_circ_nx_one():
  {==}

law ok_circ_ny_one:
  {SX.circ_ny(1.0f64) == 0.0f64 : F64}

def ok_circ_ny_one():
  {==}

law ok_t_in11:
  {SX.t_in11(0.0f64) == True{} : Bool}

def ok_t_in11():
  {==}

law neg_t_in11:
  {SX.t_in11(2.0f64) == False{} : Bool}

def neg_t_in11():
  {==}

law ok_qf_wi_x:
  {SX.qf_wi(1.0f64, 0.0f64, 0.0f64) == 1u64 : U64}

def ok_qf_wi_x():
  {==}

law ok_qf_wi_z:
  {SX.qf_wi(0.0f64, 0.0f64, 5.0f64) == 0u64 : U64}

def ok_qf_wi_z():
  {==}

law ok_norm3:
  {SX.norm3(3.0f64, 4.0f64, 0.0f64) == 5.0f64 : F64}

def ok_norm3():
  {==}

law ok_qframe_x:
  {SX.qframe(V.Dr{1.0f64, 0.0f64, 0.0f64})
    == SX.QFr{V.Dr{0.0f64, 1.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}} : SX.QFr}

def ok_qframe_x():
  {==}

law ok_qframe_y:
  {SX.qframe(V.Dr{0.0f64, 1.0f64, 0.0f64})
    == SX.QFr{V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}} : SX.QFr}

def ok_qframe_y():
  {==}

law ok_qframe_z:
  {SX.qframe(V.Dr{0.0f64, 0.0f64, 1.0f64})
    == SX.QFr{V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}} : SX.QFr}

def ok_qframe_z():
  {==}

law ok_spine:
  {SX.spine_c(1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 1.0f64, 10.0f64)
    == V.Pt{1.0f64, 2.0f64, 13.0f64} : V.Point}

def ok_spine():
  {==}

law ok_surf_cyl:
  {SX.surf_cyl(G.Cy{org(), axis_z(), 1.0f64}, 0.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{1.0f64, 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_cyl():
  {==}

law neg_surf_cyl_t:
  {SX.surf_cyl(G.Cy{org(), axis_z(), 1.0f64}, 2.0f64, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_cyl_t():
  {==}

law neg_surf_cyl_r:
  {SX.surf_cyl(G.Cy{org(), axis_z(), 0.0f64}, 0.0f64, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_cyl_r():
  {==}

law ok_surf_cone:
  {SX.surf_cone(G.Co{org(), axis_z(), 1.0f64}, 0.0f64, 2.0f64)
    == G.Gok{G.GV_p{V.Pt{2.0f64, 0.0f64, 2.0f64}}} : G.GRes}

def ok_surf_cone():
  {==}

law neg_surf_cone_h:
  {SX.surf_cone(G.Co{org(), axis_z(), 1.0f64}, 0.0f64, F64.neg(2.0f64))
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_cone_h():
  {==}

law ok_surf_tor:
  {SX.surf_tor(G.To{org(), axis_z(), 5.0f64, 1.0f64}, 0.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{6.0f64, 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_tor():
  {==}

law neg_surf_tor_spindle:
  {SX.surf_tor(G.To{org(), axis_z(), 1.0f64, 5.0f64}, 0.0f64, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_tor_spindle():
  {==}

law ok_surf_sph_east:
  {SX.surf_sph(G.Sp{org(), 2.0f64}, 1.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{2.0f64, 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_sph_east():
  {==}

law ok_surf_sph_west:
  {SX.surf_sph(G.Sp{org(), 2.0f64}, F64.neg(1.0f64), 0.0f64)
    == G.Gok{G.GV_p{V.Pt{F64.neg(2.0f64), 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_sph_west():
  {==}

law ok_surf_sph_pole:
  {SX.surf_sph(G.Sp{org(), 2.0f64}, 0.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{0.0f64, 0.0f64, 2.0f64}}} : G.GRes}

def ok_surf_sph_pole():
  {==}

law ok_surf_at_sph:
  {SX.surf_at(G.GV_sp{G.Sp{org(), 2.0f64}}, 1.0f64, 0.0f64)
    == G.Gok{G.GV_p{V.Pt{2.0f64, 0.0f64, 0.0f64}}} : G.GRes}

def ok_surf_at_sph():
  {==}

law neg_surf_at_other:
  {SX.surf_at(G.GV_f{1.0f64}, 0.0f64, 0.0f64) == G.gerr(T.F_unsupported{}) : G.GRes}

def neg_surf_at_other():
  {==}

law ok_is_quad_cyl:
  {SX.surf_is_quad(G.GV_cy{G.Cy{org(), axis_z(), 1.0f64}}) == True{} : Bool}

def ok_is_quad_cyl():
  {==}

law ok_is_quad_sph:
  {SX.surf_is_quad(G.GV_sp{G.Sp{org(), 2.0f64}}) == True{} : Bool}

def ok_is_quad_sph():
  {==}

law neg_is_quad_f:
  {SX.surf_is_quad(G.GV_f{1.0f64}) == False{} : Bool}

def neg_is_quad_f():
  {==}

law ok_ring_cyl:
  {SX.ring_cyl(G.Cy{org(), axis_z(), 2.0f64}, 3.0f64)
    == G.Gok{G.GV_cc{G.Cc{V.Pt{0.0f64, 0.0f64, 3.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 1.0f64, 0.0f64}, 2.0f64}}} : G.GRes}

def ok_ring_cyl():
  {==}

law neg_ring_cyl_r:
  {SX.ring_cyl(G.Cy{org(), axis_z(), 0.0f64}, 3.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_cyl_r():
  {==}

law ok_ring_cone:
  {SX.ring_cone(G.Co{org(), axis_z(), 1.0f64}, 2.0f64)
    == G.Gok{G.GV_cc{G.Cc{V.Pt{0.0f64, 0.0f64, 2.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 1.0f64, 0.0f64}, 2.0f64}}} : G.GRes}

def ok_ring_cone():
  {==}

law neg_ring_cone_h:
  {SX.ring_cone(G.Co{org(), axis_z(), 1.0f64}, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_cone_h():
  {==}

law ok_ring_tor_p:
  {SX.ring_tor_p(G.To{org(), axis_z(), 5.0f64, 1.0f64}, 0.0f64)
    == G.Gok{G.GV_cc{G.Cc{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 1.0f64, 0.0f64}, 6.0f64}}} : G.GRes}

def ok_ring_tor_p():
  {==}

law neg_ring_tor_p_spin:
  {SX.ring_tor_p(G.To{org(), axis_z(), 1.0f64, 5.0f64}, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_tor_p_spin():
  {==}

law ok_ring_tor_m:
  {SX.ring_tor_m(G.To{org(), axis_z(), 5.0f64, 1.0f64}, 0.0f64)
    == G.Gok{G.GV_cc{G.Cc{V.Pt{5.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 1.0f64}, 1.0f64}}} : G.GRes}

def ok_ring_tor_m():
  {==}

law neg_ring_tor_m_t:
  {SX.ring_tor_m(G.To{org(), axis_z(), 5.0f64, 1.0f64}, 2.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_tor_m_t():
  {==}

law intent_proj_fm:
  for m: Y.MatFx
  for fc: Nat
  for fm: Nat
  for sh: Nat
  for ho: Nat
  {Y.intent_fm(Y.mk_intent(m, fc, fm, sh, ho)) == fm : Nat}

def intent_proj_fm(m, fc, fm, sh, ho):
  {==}

law intent_proj_shells:
  for m: Y.MatFx
  for fc: Nat
  for fm: Nat
  for sh: Nat
  for ho: Nat
  {Y.intent_shells(Y.mk_intent(m, fc, fm, sh, ho)) == sh : Nat}

def intent_proj_shells(m, fc, fm, sh, ho):
  {==}

law matfx_tag_create:
  {Y.matfx_tag(Y.M_create{}) == 0u64 : U64}

def matfx_tag_create():
  {==}

law matfx_tag_add:
  {Y.matfx_tag(Y.M_add{}) == 1u64 : U64}

def matfx_tag_add():
  {==}

law matfx_tag_remove:
  {Y.matfx_tag(Y.M_remove{}) == 2u64 : U64}

def matfx_tag_remove():
  {==}

law matfx_tag_same:
  {Y.matfx_tag(Y.M_same{}) == 3u64 : U64}

def matfx_tag_same():
  {==}

law sok_iv_rt:
  for v: Y.Iv
  {Y.sok_iv_of(Y.sok_iv(v)) == v : Y.Iv}

def sok_iv_rt(v):
  {==}

law sok_s_rt:
  for s: String
  {Y.sok_s_of(Y.sok_s(s)) == s : String}

def sok_s_rt(s):
  {==}

law sok_fx_rt:
  for e: Y.Effect
  {Y.sok_fx_of(Y.sok_fx(e)) == e : Y.Effect}

def sok_fx_rt(e):
  {==}

law sok_body_rt:
  for b: Y.Body
  {Y.sok_body_of(Y.sok_body(b)) == b : Y.Body}

def sok_body_rt(b):
  {==}

law sok_part_rt:
  for p: Y.Part
  {Y.sok_part_of(Y.sok_part(p)) == p : Y.Part}

def sok_part_rt(p):
  {==}

law sok_ms_rt:
  for m: Y.Measure
  {Y.sok_ms_of(Y.sok_ms(m)) == m : Y.Measure}

def sok_ms_rt(m):
  {==}

law sok_iv_wrong_arm:
  for u: U64
  {Y.sok_iv_of(Y.sok_u(u)) == Y.Iv{0.0f64, 0.0f64} : Y.Iv}

def sok_iv_wrong_arm(u):
  {==}

law sok_s_wrong_arm:
  for u: U64
  {Y.sok_s_of(Y.sok_u(u)) == "" : String}

def sok_s_wrong_arm(u):
  {==}

law sok_fx_wrong_arm:
  {Y.sok_fx_of(Y.sok_u(5u64)) == Y.mk_fx(Y.M_same{}, 0n, 0n, 0n, 0n) : Y.Effect}

def sok_fx_wrong_arm():
  {==}

law sok_ms_wrong_arm:
  {Y.sok_ms_of(Y.sok_u(5u64))
    == Y.mk_ms(Y.Iv{0.0f64, 0.0f64}, Y.Iv{0.0f64, 0.0f64},
      V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64},
      0n, 0n, 0n) : Y.Measure}

def sok_ms_wrong_arm():
  {==}

law sok_part_wrong_arm:
  {Y.sok_part_of(Y.sok_u(5u64)) == Y.part_empty() : Y.Part}

def sok_part_wrong_arm():
  {==}

law sok_body_wrong_arm:
  {Y.sok_body_of(Y.sok_u(5u64)) == Y.sok_def_body() : Y.Body}

def sok_body_wrong_arm():
  {==}

law serr_kind_keep:
  for k: T.FailKind
  {Y.sres_kind(Y.serr(k, Y.diag_null())) == k : T.FailKind}

def serr_kind_keep(k):
  {==}

law ms_vol_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_vol(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == v : Y.Iv}

def ms_vol_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ms_area_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_area(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == a : Y.Iv}

def ms_area_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ms_blo_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_blo(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == lo : V.Point}

def ms_blo_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ms_bhi_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_bhi(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == hi : V.Point}

def ms_bhi_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ms_nv_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_nv(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == nv : Nat}

def ms_nv_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ms_ne_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_ne(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == ne : Nat}

def ms_ne_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ms_nf_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_nf(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == nf : Nat}

def ms_nf_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ok_kind_tag_cyl:
  {SX.surf_kind_tag(G.GV_cy{G.Cy{org(), axis_z(), 1.0f64}}) == 2u64 : U64}

def ok_kind_tag_cyl():
  {==}

law ok_kind_tag_sph:
  {SX.surf_kind_tag(G.GV_sp{G.Sp{org(), 2.0f64}}) == 5u64 : U64}

def ok_kind_tag_sph():
  {==}

law neg_kind_tag_f:
  {SX.surf_kind_tag(G.GV_f{1.0f64}) == 99u64 : U64}

def neg_kind_tag_f():
  {==}

law ok_kind_show_cyl:
  {SX.surf_kind_show(G.GV_cy{G.Cy{org(), axis_z(), 1.0f64}}) == "cyl" : String}

def ok_kind_show_cyl():
  {==}

law ok_kind_show_sph:
  {SX.surf_kind_show(G.GV_sp{G.Sp{org(), 2.0f64}}) == "sphere" : String}

def ok_kind_show_sph():
  {==}

law neg_kind_show_f:
  {SX.surf_kind_show(G.GV_f{1.0f64}) == "other" : String}

def neg_kind_show_f():
  {==}

law ok_att_tag_box:
  {O.att_tag(Ty.brep_vs(unit_box()), Ty.brep_es(unit_box()),
    Ty.brep_ces(unit_box()), Ty.brep_lps(unit_box()),
    Ty.brep_fas(unit_box()), Ty.brep_shs(unit_box()),
    Ty.brep_sos(unit_box()), 58u64, 10000n) == 0u64 : U64}

def ok_att_tag_box():
  {==}

law neg_diag_fuel:
  {Y.sres_show(O.diag_brep(unit_box(), 0n)) == "resource-exhausted" : String}

def neg_diag_fuel():
  {==}

law diag_diag_fuel:
  {Y.diag_show(Y.sres_diag(O.diag_brep(unit_box(), 0n)))
    == "incidence @ bulk [fuel-out] fix: raise the fuel cap" : String}

def diag_diag_fuel():
  {==}

law diag_diag_valid:
  {Y.diag_show(Y.sres_diag(O.diag_brep(unit_box(), 10000n)))
    == "stages @ bulk [internal-stage] fix: internal: report this" : String}

def diag_diag_valid():
  {==}

law diag_stage_zero:
  {Y.diag_show(Y.sres_diag(O.stage_go(0u64)))
    == "stages @ bulk [internal-stage] fix: internal: report this" : String}

def diag_stage_zero():
  {==}

def trim_cyl() -> G.GVal:
  G.GV_cy{G.Cy{org(), axis_z(), 1.0f64}}

def trim_cone() -> G.GVal:
  G.GV_co{G.Co{org(), axis_z(), 1.0f64}}

def trim_tor() -> G.GVal:
  G.GV_to{G.To{org(), axis_z(), 5.0f64, 1.0f64}}

def trim_sph() -> G.GVal:
  G.GV_sp{G.Sp{org(), 2.0f64}}

def trim_wide() -> G.GVal:
  G.GV_cy{G.Cy{org(), V.Dr{0.0f64, 0.0f64, 10.0f64}, 1.0f64}}

law ok_trim_quad_cyl:
  {Y.sok_u_of(O.trim_quad(trim_cyl(), 0.0f64, 0.0f64)) == 0u64 : U64}

def ok_trim_quad_cyl():
  {==}

law ok_trim_quad_cone:
  {Y.sok_u_of(O.trim_quad(trim_cone(), 0.0f64, 2.0f64)) == 0u64 : U64}

def ok_trim_quad_cone():
  {==}

law ok_trim_quad_tor:
  {Y.sok_u_of(O.trim_quad(trim_tor(), 0.0f64, 0.0f64)) == 0u64 : U64}

def ok_trim_quad_tor():
  {==}

law ok_trim_quad_sph:
  {Y.sok_u_of(O.trim_quad(trim_sph(), 1.0f64, 0.0f64)) == 0u64 : U64}

def ok_trim_quad_sph():
  {==}

law neg_trim_quad_t:
  {Y.sres_show(O.trim_quad(trim_cyl(), 2.0f64, 0.0f64))
    == "invalid-input" : String}

def neg_trim_quad_t():
  {==}

law neg_trim_quad_r:
  {Y.sres_show(O.trim_quad(G.GV_cy{G.Cy{org(), axis_z(), 0.0f64}}, 0.0f64,
    0.0f64)) == "invalid-input" : String}

def neg_trim_quad_r():
  {==}

law neg_trim_quad_spindle:
  {Y.sres_show(O.trim_quad(G.GV_to{G.To{org(), axis_z(), 1.0f64, 5.0f64}},
    0.0f64, 0.0f64)) == "invalid-input" : String}

def neg_trim_quad_spindle():
  {==}

law neg_trim_quad_cone_h:
  {Y.sres_show(O.trim_quad(trim_cone(), 0.0f64, F64.neg(2.0f64)))
    == "invalid-input" : String}

def neg_trim_quad_cone_h():
  {==}

law neg_trim_quad_other:
  {Y.sres_show(O.trim_quad(G.GV_f{1.0f64}, 0.0f64, 0.0f64))
    == "invalid-input" : String}

def neg_trim_quad_other():
  {==}

law diag_trim_quad_other:
  {Y.diag_show(Y.sres_diag(O.trim_quad(G.GV_f{1.0f64}, 0.0f64, 0.0f64)))
    == "surface @ trim_quad [not-quad] fix: route plane/bezier trims through the C04 stages" : String}

def diag_trim_quad_other():
  {==}

law neg_trim_quad_huge:
  {Y.sres_show(O.trim_quad(trim_cyl(), 0.0f64, F64{9218868437227405312u64}))
    == "invalid-input" : String}

def neg_trim_quad_huge():
  {==}

def trim_far() -> G.GVal:
  G.GV_cy{G.Cy{V.Pt{0.0f64, 0.0f64, 1.0e308f64}, axis_z(), 1.0f64}}

law neg_trim_quad_over:
  {Y.sres_show(O.trim_quad(trim_far(), 0.0f64, 1.0e308f64))
    == "numerical-uncertainty" : String}

def neg_trim_quad_over():
  {==}

law neg_trim_quad_map_ex:
  {Y.sres_show(O.trim_quad_map(G.gerr(T.F_exhausted{})))
    == "resource-exhausted" : String}

def neg_trim_quad_map_ex():
  {==}

law neg_trim_quad_map_nc:
  {Y.sres_show(O.trim_quad_map(G.gerr(T.F_nonconverged{})))
    == "nonconvergence" : String}

def neg_trim_quad_map_nc():
  {==}

law ok_trim_quad_fin:
  {Y.sok_u_of(O.trim_quad_fin(True{}, True{}, True{})) == 0u64 : U64}

def ok_trim_quad_fin():
  {==}

law neg_trim_quad_fin_x:
  {Y.sres_show(O.trim_quad_fin(False{}, True{}, True{}))
    == "numerical-uncertainty" : String}

def neg_trim_quad_fin_x():
  {==}

law neg_trim_quad_pt_huge:
  {Y.sres_show(O.trim_quad_pt(V.Pt{F64{9218868437227405312u64}, 0.0f64,
    0.0f64})) == "numerical-uncertainty" : String}

def neg_trim_quad_pt_huge():
  {==}

def ms123() -> Y.SRes:
  O.ms_box(1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64, unit_box())

def ms_vol123() -> Y.Iv:
  Y.ms_vol(Y.sok_ms_of(ms123()))

def ms_area123() -> Y.Iv:
  Y.ms_area(Y.sok_ms_of(ms123()))

law ok_ms_box_show:
  {Y.sres_show(ms123()) == "ok" : String}

def ok_ms_box_show():
  {==}

law ok_ms_box_vol:
  {ms_vol123()
    == Y.Iv{F64{4618441417868443646u64}, F64{4618441417868443651u64}} : Y.Iv}

def ok_ms_box_vol():
  {==}

law ok_ms_box_area:
  {ms_area123()
    == Y.Iv{F64{4626885667169763325u64}, F64{4626885667169763332u64}} : Y.Iv}

def ok_ms_box_area():
  {==}

law ok_ms_box_blo:
  {Y.ms_blo(Y.sok_ms_of(ms123()))
    == V.Pt{0.0f64, 0.0f64, 0.0f64} : V.Point}

def ok_ms_box_blo():
  {==}

law ok_ms_box_bhi:
  {Y.ms_bhi(Y.sok_ms_of(ms123()))
    == V.Pt{1.0f64, 2.0f64, 3.0f64} : V.Point}

def ok_ms_box_bhi():
  {==}

law ok_ms_box_nv:
  {Y.ms_nv(Y.sok_ms_of(ms123())) == 8n : Nat}

def ok_ms_box_nv():
  {==}

law ok_ms_box_ne:
  {Y.ms_ne(Y.sok_ms_of(ms123())) == 12n : Nat}

def ok_ms_box_ne():
  {==}

law ok_ms_box_nf:
  {Y.ms_nf(Y.sok_ms_of(ms123())) == 6n : Nat}

def ok_ms_box_nf():
  {==}

law neg_ms_box_zero:
  {Y.sres_show(O.ms_box(0.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64,
    unit_box())) == "invalid-input" : String}

def neg_ms_box_zero():
  {==}

law neg_ms_box_nan:
  {Y.sres_show(O.ms_box(F64.nan(), 2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64,
    unit_box())) == "invalid-input" : String}

def neg_ms_box_nan():
  {==}

law neg_ms_box_over:
  {Y.sres_show(O.ms_box(1.0e308f64, 1.0e308f64, 1.0f64, 0.0f64, 0.0f64,
    0.0f64, unit_box())) == "numerical-uncertainty" : String}

def neg_ms_box_over():
  {==}

law neg_ms_box_corner:
  {Y.diag_show(Y.sres_diag(O.ms_box(1.0e308f64, 0.1f64, 0.1f64,
      1.0e308f64, 0.0f64, 0.0f64, unit_box())))
    == "far corner @ ms_box [corner+dim overflows F64] fix: shrink the box or move it toward origin" : String}

def neg_ms_box_corner():
  {==}

law ok_ms_bin_add:
  {Y.sok_iv_of(O.ms_bin_iv(0u64, Y.Iv{1.0f64, 1.0f64}, Y.Iv{2.0f64, 2.0f64}))
    == Y.Iv{F64{4613937818241073151u64}, F64{4613937818241073153u64}} : Y.Iv}

def ok_ms_bin_add():
  {==}

law ok_ms_bin_mul:
  {Y.sok_iv_of(O.ms_bin_iv(1u64, Y.Iv{2.0f64, 2.0f64}, Y.Iv{3.0f64, 3.0f64}))
    == Y.Iv{F64{4618441417868443647u64}, F64{4618441417868443649u64}} : Y.Iv}

def ok_ms_bin_mul():
  {==}

law neg_ms_bin_first_wins:
  {Y.sres_show(O.ms_bin2(0u64, Y.serr_invalid("a", "t", "w", "f"),
    Y.sok_iv(Y.Iv{1.0f64, 1.0f64}))) == "invalid-input" : String}

def neg_ms_bin_first_wins():
  {==}

law neg_ms_bin_second:
  {Y.sres_show(O.ms_bin2(0u64, Y.sok_iv(Y.Iv{1.0f64, 1.0f64}),
    Y.serr_uncertain("b", "t", "w", "f"))) == "numerical-uncertainty" : String}

def neg_ms_bin_second():
  {==}

def box_ps() -> List<&2, Y.Param>:
  [Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
    Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
    Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))]

def part_ins() -> Y.Part:
  Y.mk_part(box_ps(),
    [Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [9u64])], 7u64,
    box_it())

def part_mis() -> Y.Part:
  Y.mk_part(box_ps(),
    [Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [])], 7u64,
    Y.mk_intent(Y.M_create{}, 5n, 0n, 1n, 0n))

def ins_poison() -> Y.Cache:
  Y.Cc{[Y.mk_built(7u64, EV.node_key(Y.O_box{1u64, 2u64, 3u64},
      box_ps(), []), EV.dummy_body(),
    Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n))]}

def cyl_poison() -> Y.Cache:
  Y.Cc{[Y.mk_built(7u64, EV.node_key(Y.O_cyl{1u64, 2u64}, cyl_ps(),
      []), EV.dummy_body(),
    Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n))]}

law ok_cache_ins_miss:
  {root318(EV.ev_part(part_ins(), ins_poison(), 10000n)) == True{} : Bool}

def ok_cache_ins_miss():
  {==}

law ok_cache_cyl_covers:
  {EV.cc_covers(EV.cc_items(cyl_poison()),
      EV.ev_keys([Y.mk_node(7u64, Y.O_cyl{1u64, 2u64}, [])], cyl_ps()))
    == True{} : Bool}

def ok_cache_cyl_covers():
  {==}

law neg_cache_cyl:
  {Y.sres_show(ev_last2(EV.ev_part(part_cyl(), cyl_poison(), 10000n)))
    == "unsupported-op" : String}

def neg_cache_cyl():
  {==}

law neg_cache_ins_covers:
  {EV.cc_covers(EV.cc_items(ins_poison()),
      EV.ev_keys([Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [9u64])],
        box_ps())) == False{} : Bool}

def neg_cache_ins_covers():
  {==}

law neg_ev_intent:
  {Y.sres_show(ev_last2(EV.ev_part(part_mis(), Y.cache_empty(), 10000n)))
    == "invalid-input" : String}

def neg_ev_intent():
  {==}

law neg_ev_intent_hit:
  {Y.sres_show(ev_last2(EV.ev_part(part_mis(),
      ev_cc2(EV.ev_part(part1(), Y.cache_empty(), 10000n)), 10000n)))
    == "invalid-input" : String}

def neg_ev_intent_hit():
  {==}

law ok_hole_clr_exact:
  {O.hole_clr_pt(F64{4877398396442247170u64}, 1.0f64, 255.0f64, 0.0f64,
    255.0f64, 2.0f64, F64{4877398396442247169u64}) == 0u64 : U64}

def ok_hole_clr_exact():
  {==}

law ok_hole_hh_exact:
  {O.hole_hh(F64{4877398396442247170u64}, 0.0f64, 0.5f64, 255.0f64, 0.0f64,
    F64{4877398396442247169u64}) == 0u64 : U64}

def ok_hole_hh_exact():
  {==}

law ok_hole_rect_exact:
  {O.hole_rect(F64{4877398396442247170u64}, 0.0f64,
    F64{4877398396442247169u64}, 0.0f64, F64.neg(1.0f64), 255.0f64,
    1.0f64) == 0u64 : U64}

def ok_hole_rect_exact():
  {==}

law ok_qframe_nx:
  {SX.qframe(V.Dr{F64.neg(1.0f64), 0.0f64, 0.0f64})
    == SX.QFr{V.Dr{0.0f64, 1.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, F64.neg(1.0f64)}} : SX.QFr}

def ok_qframe_nx():
  {==}

law ok_qframe_ny:
  {SX.qframe(V.Dr{0.0f64, F64.neg(1.0f64), 0.0f64})
    == SX.QFr{V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Dr{F64.neg(1.0f64), 0.0f64, 0.0f64}} : SX.QFr}

def ok_qframe_ny():
  {==}

law ok_qframe_nz:
  {SX.qframe(V.Dr{0.0f64, 0.0f64, F64.neg(1.0f64)})
    == SX.QFr{V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, F64.neg(1.0f64), 0.0f64}} : SX.QFr}

def ok_qframe_nz():
  {==}

law neg_trim_quad_axis:
  {Y.sres_show(O.trim_quad(trim_wide(), 0.0f64, 0.0f64))
    == "invalid-input" : String}

def neg_trim_quad_axis():
  {==}

law neg_surf_at_axis:
  {SX.surf_at(trim_wide(), 0.0f64, 0.0f64) == G.gerr(T.F_invalid{}) : G.GRes}

def neg_surf_at_axis():
  {==}

law neg_ring_cyl_axis:
  {SX.ring_cyl(G.Cy{org(), V.Dr{0.0f64, 0.0f64, 2.0f64}, 1.0f64}, 0.0f64)
    == G.gerr(T.F_invalid{}) : G.GRes}

def neg_ring_cyl_axis():
  {==}

def coll_ps_a() -> List<&2, Y.Param>:
  [Y.mk_param(1u64, Y.mk_dm(10.0f64, 9.0f64, 11.0f64)),
    Y.mk_param(2u64, Y.mk_dm(10.0f64, 9.0f64, 11.0f64)),
    Y.mk_param(3u64, Y.mk_dm(10.0f64, 9.0f64, 11.0f64))]

def coll_ps_b() -> List<&2, Y.Param>:
  [Y.mk_param(1u64, Y.mk_dm(10.0f64, 9.0f64, F64{4622382067542392833u64})),
    Y.mk_param(2u64, Y.mk_dm(F64{4621818018077343309u64}, 9.0f64, 11.0f64)),
    Y.mk_param(3u64, Y.mk_dm(10.0f64, 9.0f64, 11.0f64))]

def coll_part(ps: List<&2, Y.Param>) -> Y.Part:
  Y.mk_part(ps, [Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [])], 7u64,
    box_it())

def bits_of(xs: List<&2, F64>) -> List<&2, U64>:
  match xs:
    case []: []
    case h <> t: F64.bits(h) <> bits_of(t)

def coll_dims(er: EV.EvRes) -> List<&2, U64>:
  match er:
    case EV.EV{cc, last}:
      match last:
        case Y.Serr{k, dg}: []
        case Y.Sok{v}:
          match v:
            case Y.SV_body{b}:
              Y.Bd{brep, kind, prof, z0, z1, boss, nhole, rh, dims} = b
              bits_of(dims)
            case _: []

law coll_hash_equal:
  {EV.node_hash(Y.O_box{1u64, 2u64, 3u64}, coll_ps_a(), [])
    == EV.node_hash(Y.O_box{1u64, 2u64, 3u64}, coll_ps_b(), []) : U64}

def coll_hash_equal():
  {==}

law ok_cache_collision_rebuilds:
  {coll_dims(EV.ev_part(coll_part(coll_ps_b()),
      ev_cc2(EV.ev_part(coll_part(coll_ps_a()), Y.cache_empty(), 100000n)),
      100000n))
    == [4621819117588971520u64, 4621818018077343309u64, 4621819117588971520u64]
      : List<&2, U64>}

def ok_cache_collision_rebuilds():
  {==}

law neg_ev_dup_node:
  {Y.sres_show(ev_last2(EV.ev_part(Y.mk_part(box_ps(),
      [Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, []),
        Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [])], 7u64, box_it()),
      Y.cache_empty(), 10000n)))
    == "invalid-input" : String}

def neg_ev_dup_node():
  {==}

law neg_ev_dup_param:
  {Y.sres_show(ev_last2(EV.ev_part(Y.mk_part(
      [Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 2.0f64)),
        Y.mk_param(1u64, Y.mk_dm(5.0f64, 4.0f64, 6.0f64)),
        Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
        Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))],
      [Y.mk_node(7u64, Y.O_box{1u64, 2u64, 3u64}, [])], 7u64, box_it()),
      Y.cache_empty(), 10000n)))
    == "invalid-input" : String}

def neg_ev_dup_param():
  {==}

law node_hash_pocket_coords:
  {U64.is_eq(EV.node_hash(Y.O_pocket{7u64, 0.0f64, 0.0f64, 1.0f64, 1.0f64, 1u64}, [], []),
    EV.node_hash(Y.O_pocket{7u64, 0.5f64, 0.0f64, 1.0f64, 1.0f64, 1u64}, [], []))
    == False{} : Bool}

def node_hash_pocket_coords():
  {==}
