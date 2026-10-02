# C06 op-graph eval pins: fresh build, cache reuse, bad dim id,
# bad root, unsupported op, publish gate, lineage names.
# selfcheck fails=N.

import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c06/types.bend as Y
import ../../src/c06/eval.bend as EV
import ./box.bend as BX

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

def total() -> U64:
  U64.add(t_eval_fresh(), U64.add(t_eval_reuse(),
    U64.add(t_eval_baddim(), U64.add(t_eval_badroot(),
      U64.add(t_eval_cyl(), U64.add(t_gate_ok(),
        U64.add(t_gate_mis(), t_names())))))))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("selfcheck fails=" ++ U64.show(total()))
