import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c06/types.bend as Y
import ../../src/c06/ops.bend as O

def is_sok(r: Y.SRes) -> Bool:
  match r:
    case Y.Sok{v}: True{}
    case Y.Serr{k, dg}: False{}

def kind_is(r: Y.SRes, want: U64) -> Bool:
  match r:
    case Y.Sok{v}: False{}
    case Y.Serr{k, dg}:
      match k:
        case T.F_invalid{}: U64.is_eq(want, 0u64)
        case T.F_uncertain{}: U64.is_eq(want, 1u64)
        case T.F_unsupported{}: U64.is_eq(want, 2u64)
        case T.F_exhausted{}: U64.is_eq(want, 3u64)
        case _: False{}

def brep_vef(r: Y.SRes, nv: Nat, ne: Nat, nf: Nat) -> Bool:
  match r:
    case Y.Serr{k, dg}: False{}
    case Y.Sok{v}:
      match v:
        case Y.SV_brep{+b}:
          Bool.and(Nat.is_eq(List.length(&2, Ty.Vertex,
              Ty.brep_vs(b)), nv),
            Bool.and(Nat.is_eq(List.length(&2, Ty.Edge,
                Ty.brep_es(b)), ne),
              Nat.is_eq(List.length(&2, Ty.Face,
                Ty.brep_fas(b)), nf)))
        case _: False{}

def t_box_ok() -> U64:
  Bool.pick(U64, brep_vef(O.box_checked(0.0f64, 0.0f64,
    0.0f64, 1.0f64, 2.0f64, 3.0f64, 10000n), 8n, 12n, 6n),
    0u64, 1u64)

def t_box_frac() -> U64:
  Bool.pick(U64, brep_vef(O.box_checked(0.1f64, 0.2f64,
    0.3f64, 0.4f64, 0.5f64, 0.6f64, 10000n), 8n, 12n, 6n),
    0u64, 1u64)

def t_box_zero() -> U64:
  Bool.pick(U64, kind_is(O.box_checked(0.0f64, 0.0f64,
    0.0f64, 0.0f64, 2.0f64, 3.0f64, 10000n), 0u64), 0u64,
    1u64)

def t_box_nan() -> U64:
  Bool.pick(U64, kind_is(O.box_checked(0.0f64, 0.0f64,
    0.0f64, 1.0f64, 2.0f64, F64.nan(), 10000n), 0u64), 0u64,
    1u64)

def t_box_over() -> U64:
  Bool.pick(U64, kind_is(O.box_checked(1.0e308f64, 0.0f64,
    0.0f64, 1.0e308f64, 1.0f64, 1.0f64, 10000n), 1u64), 0u64,
    1u64)

def sq_loop() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 0.0f64},
    V.V2{1.0f64, 1.0f64}, V.V2{0.0f64, 1.0f64}]

def sqcw_loop() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64},
    V.V2{1.0f64, 1.0f64}, V.V2{1.0f64, 0.0f64}]

def bow_loop() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 1.0f64},
    V.V2{1.0f64, 0.0f64}, V.V2{0.0f64, 1.0f64}]

def t_prof_sq() -> U64:
  Bool.pick(U64, U64.is_eq(O.prof_code(sq_loop(), [], 1000n),
    0u64), 0u64, 1u64)

def t_prof_bow() -> U64:
  Bool.pick(U64, U64.is_eq(O.prof_code(bow_loop(), [], 1000n),
    4u64), 0u64, 1u64)

def t_prof_cw() -> U64:
  Bool.pick(U64, U64.is_eq(O.prof_code(sqcw_loop(), [], 1000n),
    5u64), 0u64, 1u64)

def t_pip_in() -> U64:
  Bool.pick(U64, U64.is_eq(O.pip(0.5f64, 0.5f64, sq_loop(),
    1000n), 1u64), 0u64, 1u64)

def t_pip_out() -> U64:
  Bool.pick(U64, U64.is_eq(O.pip(2.0f64, 2.0f64, sq_loop(),
    1000n), 0u64), 0u64, 1u64)

def t_pip_edge() -> U64:
  Bool.pick(U64, U64.is_eq(O.pip(0.5f64, 0.0f64, sq_loop(),
    1000n), 2u64), 0u64, 1u64)

def outer10() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{10.0f64, 0.0f64},
    V.V2{10.0f64, 10.0f64}, V.V2{0.0f64, 10.0f64}]

def holeA() -> List<&2, V.Vec2>:
  [V.V2{1.0f64, 1.0f64}, V.V2{1.0f64, 9.0f64},
    V.V2{9.0f64, 9.0f64}, V.V2{9.0f64, 1.0f64}]

def holeB() -> List<&2, V.Vec2>:
  [V.V2{2.0f64, 2.0f64}, V.V2{2.0f64, 3.0f64},
    V.V2{3.0f64, 3.0f64}, V.V2{3.0f64, 2.0f64}]

def holeC() -> List<&2, V.Vec2>:
  [V.V2{4.0f64, 4.0f64}, V.V2{4.0f64, 5.0f64},
    V.V2{5.0f64, 5.0f64}, V.V2{5.0f64, 4.0f64}]

def t_prof_nest_ab() -> U64:
  Bool.pick(U64, U64.is_eq(O.prof_code(outer10(),
    [holeA(), holeB()], 100000n), 12u64), 0u64, 1u64)

def t_prof_nest_ba() -> U64:
  Bool.pick(U64, U64.is_eq(O.prof_code(outer10(),
    [holeB(), holeA()], 100000n), 12u64), 0u64, 1u64)

def t_prof_holes_ok() -> U64:
  Bool.pick(U64, U64.is_eq(O.prof_code(outer10(),
    [holeB(), holeC()], 100000n), 0u64), 0u64, 1u64)

def revsq() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{2.0f64, 0.0f64},
    V.V2{2.0f64, 1.0f64}, V.V2{0.0f64, 1.0f64}]

def revtri() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 0.0f64}, V.V2{1.0f64, 1.0f64},
    V.V2{0.0f64, 2.0f64}]

def revbelow() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, F64.neg(1.0f64)}, V.V2{2.0f64, F64.neg(1.0f64)},
    V.V2{2.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64}]

def t_revax_ok() -> U64:
  Bool.pick(U64, U64.is_eq(O.rev_ax(revsq(), 100000n),
    0u64), 0u64, 1u64)

def t_revax_pinch() -> U64:
  Bool.pick(U64, U64.is_eq(O.rev_ax(revtri(), 100000n),
    15u64), 0u64, 1u64)

def t_revax_neg() -> U64:
  Bool.pick(U64, U64.is_eq(O.rev_ax(revbelow(), 100000n),
    14u64), 0u64, 1u64)

def t_revprof_ok() -> U64:
  Bool.pick(U64, is_sok(O.prof_valid_rev(Y.mk_prof(revsq(),
    []), 100000n)), 0u64, 1u64)

def revmid() -> List<&2, V.Vec2>:
  [V.V2{0.0f64, 2.0f64}, V.V2{0.0f64, 0.0f64},
    V.V2{1.0f64, 1.0f64}, V.V2{0.0f64, 3.0f64}]

def revlast() -> List<&2, V.Vec2>:
  [V.V2{1.0f64, 1.0f64}, V.V2{0.0f64, 1.0f64},
    V.V2{0.0f64, 0.0f64}]

def t_revax_mid() -> U64:
  Bool.pick(U64, U64.is_eq(O.rev_ax(revmid(), 100000n),
    15u64), 0u64, 1u64)

def t_revax_last() -> U64:
  Bool.pick(U64, U64.is_eq(O.rev_ax(revlast(), 100000n),
    15u64), 0u64, 1u64)

def holeD() -> List<&2, V.Vec2>:
  [V.V2{0.5f64, 0.5f64}, V.V2{0.5f64, 2.0f64},
    V.V2{5.0f64, 2.0f64}, V.V2{5.0f64, 0.5f64}]

def holeF() -> List<&2, V.Vec2>:
  [V.V2{20.0f64, 20.0f64}, V.V2{20.0f64, 21.0f64},
    V.V2{21.0f64, 21.0f64}, V.V2{21.0f64, 20.0f64}]

def t_prof_holes_cross() -> U64:
  Bool.pick(U64, U64.is_eq(O.prof_code(outer10(),
    [holeA(), holeD()], 100000n), 11u64), 0u64, 1u64)

def t_prof_hole_out() -> U64:
  Bool.pick(U64, U64.is_eq(O.prof_code(outer10(), [holeF()],
    100000n), 9u64), 0u64, 1u64)

def t_box_adv() -> U64:
  Bool.pick(U64, brep_vef(O.box_checked(97398.60767117864f64,
    F64.neg(971916.5996719621f64), 0.0f64, 1.0f64, 2.0f64,
    3.0f64, 10000n), 8n, 12n, 6n), 0u64, 1u64)

def t_box_negcorner() -> U64:
  Bool.pick(U64, brep_vef(O.box_checked(F64.neg(5.0f64),
    F64.neg(5.0f64), F64.neg(5.0f64), 1.0f64, 2.0f64, 3.0f64,
    10000n), 8n, 12n, 6n), 0u64, 1u64)

def t_box_fin_first() -> U64:
  Bool.pick(U64, kind_is(O.box_checked(F64.nan(), 0.0f64,
    0.0f64, 1.0e308f64, 1.0f64, 1.0f64, 10000n), 0u64), 0u64,
    1u64)

def t_box_pos_first() -> U64:
  Bool.pick(U64, kind_is(O.box_checked(1.0e308f64, 0.0f64,
    0.0f64, 1.0e308f64, 0.0f64, 1.0f64, 10000n), 0u64), 0u64,
    1u64)

def total() -> U64:
  U64.add(t_box_ok(), U64.add(t_box_frac(),
    U64.add(t_box_zero(), U64.add(t_box_nan(),
      U64.add(t_box_over(), U64.add(t_box_adv(),
        U64.add(t_box_negcorner(), U64.add(t_box_fin_first(),
          U64.add(t_box_pos_first(), U64.add(t_prof_sq(),
        U64.add(t_prof_bow(), U64.add(t_prof_cw(),
          U64.add(t_pip_in(), U64.add(t_pip_out(),
            U64.add(t_pip_edge(), U64.add(t_prof_nest_ab(),
              U64.add(t_prof_nest_ba(),
                U64.add(t_prof_holes_ok(),
                  U64.add(t_revax_ok(),
                    U64.add(t_revax_pinch(),
                      U64.add(t_revax_neg(),
                        U64.add(t_revprof_ok(),
                          U64.add(t_revax_mid(),
                            U64.add(t_revax_last(),
                              U64.add(t_prof_holes_cross(),
                                t_prof_hole_out())))))))))))))))))))))))))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("selfcheck fails=" ++ U64.show(total()))
