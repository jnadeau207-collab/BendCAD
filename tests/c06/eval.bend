import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c06/types.bend as Y
import ../../src/c06/ops.bend as O
import ../../src/c06/eval.bend as EV
import ./box.bend as BX

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

def cyl_ns() -> List<&2, Y.Node>:
  [Y.mk_node(7u64, Y.O_cyl{1u64, 2u64}, [])]

def part_cyl() -> Y.Part:
  Y.mk_part(cyl_ps(), cyl_ns(), 7u64, box_it())

def ev_cc(er: EV.EvRes) -> Y.Cache:
  match er:
    case EV.EV{cc, last}: cc

def ev_last(er: EV.EvRes) -> Y.SRes:
  match er:
    case EV.EV{cc, last}: last

def root_vef(er: EV.EvRes, nv: Nat, ne: Nat, nf: Nat) -> Bool:
  match er:
    case EV.EV{cc, last}:
      match last:
        case Y.Serr{k, dg}: False{}
        case Y.Sok{v}:
          match v:
            case Y.SV_body{+b}:
              +bb = Y.body_brep(b)
              Bool.and(Nat.is_eq(List.length(&2, Ty.Vertex,
                  Ty.brep_vs(bb)), nv),
                Bool.and(Nat.is_eq(List.length(&2, Ty.Edge,
                    Ty.brep_es(bb)), ne),
                  Nat.is_eq(List.length(&2, Ty.Face,
                    Ty.brep_fas(bb)), nf)))
            case _: False{}

def t_eval_fresh() -> U64:
  Bool.pick(U64, root_vef(EV.ev_part(part1(),
    Y.cache_empty(), 10000n), 8n, 12n, 6n), 0u64, 1u64)

def t_eval_reuse() -> U64:
  Bool.pick(U64, root_vef(EV.ev_part(part1(),
    ev_cc(EV.ev_part(part1(), Y.cache_empty(), 10000n)),
    10000n), 8n, 12n, 6n), 0u64, 1u64)

def t_eval_baddim() -> U64:
  Bool.pick(U64, BX.kind_is(ev_last(EV.ev_part(part_baddim(),
    Y.cache_empty(), 10000n)), 0u64), 0u64, 1u64)

def t_eval_badroot() -> U64:
  Bool.pick(U64, BX.kind_is(ev_last(EV.ev_part(part_badroot(),
    Y.cache_empty(), 10000n)), 0u64), 0u64, 1u64)

def t_eval_cyl() -> U64:
  Bool.pick(U64, BX.kind_is(ev_last(EV.ev_part(part_cyl(),
    Y.cache_empty(), 10000n)), 2u64), 0u64, 1u64)

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

def t_cache_cyl() -> U64:
  Bool.pick(U64, Bool.and(EV.cc_covers(EV.cc_items(cyl_poison()),
      EV.ev_keys(cyl_ns(), cyl_ps())),
    BX.kind_is(ev_last(EV.ev_part(part_cyl(), cyl_poison(),
      10000n)), 2u64)), 0u64, 1u64)

def t_cache_ins() -> U64:
  Bool.pick(U64, root_vef(EV.ev_part(part_ins(), ins_poison(),
    10000n), 8n, 12n, 6n), 0u64, 1u64)

def t_intent_bad() -> U64:
  Bool.pick(U64, BX.kind_is(ev_last(EV.ev_part(part_mis(),
    Y.cache_empty(), 10000n)), 0u64), 0u64, 1u64)

def t_intent_hit() -> U64:
  Bool.pick(U64, BX.kind_is(ev_last(EV.ev_part(part_mis(),
    ev_cc(EV.ev_part(part1(), Y.cache_empty(), 10000n)),
    10000n)), 0u64), 0u64, 1u64)

def fx_box() -> Y.Effect:
  Y.mk_fx(Y.M_create{}, 6n, 0n, 1n, 0n)

def t_gate_ok() -> U64:
  Bool.pick(U64, BX.is_sok(EV.gate_publish(fx_box(),
    Y.mk_intent(Y.M_create{}, 6n, 0n, 1n, 0n))), 0u64, 1u64)

def t_gate_mis() -> U64:
  Bool.pick(U64, BX.kind_is(EV.gate_publish(fx_box(),
    Y.mk_intent(Y.M_create{}, 5n, 0n, 1n, 0n)), 0u64), 0u64,
    1u64)

def t_names() -> U64:
  Bool.pick(U64, Nat.is_eq(List.length(&2, Y.Nm,
    EV.box_names(7u64)), 26n), 0u64, 1u64)

def why_is(r: Y.SRes, w: String) -> Bool:
  match r:
    case Y.Sok{v}: False{}
    case Y.Serr{k, dg}:
      Y.Dg{+what, +loc, +why, +fix} = dg
      String.eq(why, w)

def zone_bad_ps() -> List<&2, Y.Param>:
  [Y.mk_param(1u64, Y.mk_dm(1.0f64, 5.0f64, 9.0f64)),
    Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
    Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))]

def wide_ps() -> List<&2, Y.Param>:
  [Y.mk_param(1u64, Y.mk_dm(1.0f64, 0.5f64, 9.0f64)),
    Y.mk_param(2u64, Y.mk_dm(2.0f64, 1.0f64, 3.0f64)),
    Y.mk_param(3u64, Y.mk_dm(3.0f64, 2.0f64, 4.0f64))]

def wide_dm() -> Y.Dim:
  Y.mk_dm(2.0f64, 1.0f64, 3.0f64)

def pt_dm() -> Y.Dim:
  Y.mk_dm(2.0f64, 2.0f64, 2.0f64)

def t_zone_bad() -> U64:
  Bool.pick(U64, why_is(EV.ev_box(1u64, 2u64, 3u64, zone_bad_ps(),
    10000n), "zone"), 0u64, 1u64)

def t_zone_miss() -> U64:
  Bool.pick(U64, why_is(EV.ev_box(9u64, 2u64, 3u64, box_ps(),
    10000n), "unknown dim id"), 0u64, 1u64)

def t_hash_zone() -> U64:
  Bool.pick(U64, Bool.not(U64.is_eq(EV.node_hash(Y.O_box{1u64, 2u64,
      3u64}, box_ps(), []), EV.node_hash(Y.O_box{1u64, 2u64, 3u64},
      wide_ps(), []))), 0u64, 1u64)

def t_zone_vol() -> U64:
  Bool.pick(U64, Bool.and(BX.is_sok(O.ms_zone(wide_dm(), pt_dm(),
      pt_dm())), Bool.and(BX.is_sok(O.ms_nom_vol(wide_dm(), pt_dm(),
      pt_dm())), F64.is_lt(Y.iv_lo(Y.sok_iv_of(O.ms_zone(wide_dm(),
      pt_dm(), pt_dm()))), Y.iv_lo(Y.sok_iv_of(O.ms_nom_vol(wide_dm(),
      pt_dm(), pt_dm())))))), 0u64, 1u64)

def total() -> U64:
  U64.add(t_eval_fresh(), U64.add(t_eval_reuse(),
    U64.add(t_eval_baddim(), U64.add(t_eval_badroot(),
      U64.add(t_eval_cyl(), U64.add(t_cache_cyl(),
        U64.add(t_cache_ins(), U64.add(t_intent_bad(),
          U64.add(t_intent_hit(), U64.add(t_gate_ok(),
            U64.add(t_gate_mis(), U64.add(t_names(),
              U64.add(t_zone_bad(), U64.add(t_zone_miss(),
                U64.add(t_hash_zone(), t_zone_vol())))))))))))))))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("selfcheck fails=" ++ U64.show(total()))
