import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c04/ops.bend as C4
import ../../src/c06/types.bend as Y
import ../../src/c06/ops.bend as O
import ./box.bend as BX

def ub() -> Ty.Brep:
  O.box_core(0.0f64, 0.0f64, 0.0f64, 1.0f64, 2.0f64, 3.0f64)

def t_stage_go_0() -> U64:
  Bool.pick(U64, BX.kind_is(O.stage_go(0u64), 0u64), 0u64, 1u64)

def t_stage_go_incid() -> U64:
  Bool.pick(U64, BX.kind_is(O.stage_go(2u64), 0u64), 0u64, 1u64)

def t_stage_go_embed() -> U64:
  Bool.pick(U64, BX.kind_is(O.stage_go(7u64), 1u64), 0u64, 1u64)

def t_stage_go_unknown() -> U64:
  Bool.pick(U64, BX.kind_is(O.stage_go(99u64), 0u64), 0u64, 1u64)

def t_stage_ex_fuel() -> U64:
  Bool.pick(U64, BX.kind_is(O.stage_ex(102u64), 3u64), 0u64, 1u64)

def t_att_go_first() -> U64:
  Bool.pick(U64, BX.kind_is(O.att_go(1u64), 0u64), 0u64, 1u64)

def t_att_go_last() -> U64:
  Bool.pick(U64, BX.kind_is(O.att_go(21u64), 0u64), 0u64, 1u64)

def t_att_go_fuel() -> U64:
  Bool.pick(U64, BX.kind_is(O.att_go(100u64), 3u64), 0u64, 1u64)

def t_att_go_unknown() -> U64:
  Bool.pick(U64, BX.kind_is(O.att_go(99u64), 0u64), 0u64, 1u64)

def t_att3_ok() -> U64:
  Bool.pick(U64, U64.is_eq(O.att3(3n, 3n, 3n, 1u64), 0u64),
    0u64, 1u64)

def t_att3_first() -> U64:
  Bool.pick(U64, U64.is_eq(O.att3(2n, 3n, 3n, 1u64), 1u64),
    0u64, 1u64)

def t_stc_undecided() -> U64:
  Bool.pick(U64, U64.is_eq(O.stc(0n, 5u64), 105u64), 0u64, 1u64)

def t_bulk_c_pass() -> U64:
  Bool.pick(U64, BX.is_sok(O.bulk_c(Ty.Tok{Ty.T_brep{ub()}},
    ub(), 10000n)), 0u64, 1u64)

def t_bulk_c_terr() -> U64:
  Bool.pick(U64, BX.kind_is(O.bulk_c(Ty.Terr{T.F_invalid{}},
    ub(), 10000n), 0u64), 0u64, 1u64)

def t_bulk_a_ok() -> U64:
  Bool.pick(U64, BX.is_sok(O.bulk_a(Ty.tok_brep(ub()),
    Ty.brep_vs(ub()), Ty.brep_es(ub()), Ty.brep_ces(ub()),
    Ty.brep_lps(ub()), Ty.brep_fas(ub()), Ty.brep_shs(ub()),
    Ty.brep_sos(ub()), 58u64, 10000n)), 0u64, 1u64)

def t_bulk_a_att() -> U64:
  Bool.pick(U64, BX.kind_is(O.bulk_a(Ty.Terr{T.F_invalid{}},
    [], [], [], [], [], [], [], 58u64, 100n), 0u64), 0u64,
    1u64)

def t_att_tag_box() -> U64:
  Bool.pick(U64, U64.is_eq(O.att_tag(Ty.brep_vs(ub()),
    Ty.brep_es(ub()), Ty.brep_ces(ub()), Ty.brep_lps(ub()),
    Ty.brep_fas(ub()), Ty.brep_shs(ub()), Ty.brep_sos(ub()),
    58u64, 10000n), 0u64), 0u64, 1u64)

def t_diag_fuel() -> U64:
  Bool.pick(U64, BX.kind_is(O.diag_brep(ub(), 0n), 3u64), 0u64,
    1u64)

def t_diag_valid() -> U64:
  Bool.pick(U64, BX.kind_is(O.diag_brep(ub(), 10000n), 0u64),
    0u64, 1u64)

def cyl() -> G.GVal:
  G.GV_cy{G.Cy{V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Dr{0.0f64, 0.0f64, 1.0f64}, 1.0f64}}

def t_trim_cyl() -> U64:
  Bool.pick(U64, U64.is_eq(Y.sok_u_of(O.trim_quad(cyl(),
    0.0f64, 0.0f64)), 0u64), 0u64, 1u64)

def t_trim_t() -> U64:
  Bool.pick(U64, BX.kind_is(O.trim_quad(cyl(), 2.0f64,
    0.0f64), 0u64), 0u64, 1u64)

def t_trim_other() -> U64:
  Bool.pick(U64, BX.kind_is(O.trim_quad(G.GV_f{1.0f64},
    0.0f64, 0.0f64), 0u64), 0u64, 1u64)

def t_trim_over() -> U64:
  Bool.pick(U64, BX.kind_is(O.trim_quad(G.GV_cy{G.Cy{
    V.Pt{0.0f64, 0.0f64, 1.0e308f64},
    V.Dr{0.0f64, 0.0f64, 1.0f64}, 1.0f64}}, 0.0f64,
    1.0e308f64), 1u64), 0u64, 1u64)

def t_trim_axis() -> U64:
  Bool.pick(U64, BX.kind_is(O.trim_quad(G.GV_cy{G.Cy{
    V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Dr{0.0f64, 0.0f64, 2.0f64}, 1.0f64}}, 0.0f64,
    0.0f64), 0u64), 0u64, 1u64)

def t_ms_ok() -> U64:
  Bool.pick(U64, BX.is_sok(O.ms_box(1.0f64, 2.0f64, 3.0f64,
    0.0f64, 0.0f64, 0.0f64, ub())), 0u64, 1u64)

def ms_vol_bits(v: Y.Iv) -> Bool:
  Y.Iv{+lo, +hi} = v
  Bool.and(U64.is_eq(F64.bits(lo), 4618441417868443646u64),
    U64.is_eq(F64.bits(hi), 4618441417868443651u64))

def t_ms_vol() -> U64:
  Bool.pick(U64, ms_vol_bits(Y.ms_vol(Y.sok_ms_of(O.ms_box(
    1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64,
    ub())))), 0u64, 1u64)

def ms_area_bits(v: Y.Iv) -> Bool:
  Y.Iv{+lo, +hi} = v
  Bool.and(U64.is_eq(F64.bits(lo), 4626885667169763325u64),
    U64.is_eq(F64.bits(hi), 4626885667169763332u64))

def t_ms_area() -> U64:
  Bool.pick(U64, ms_area_bits(Y.ms_area(Y.sok_ms_of(O.ms_box(
    1.0f64, 2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64,
    ub())))), 0u64, 1u64)

def ms_counts_ok(+m: Y.Measure) -> Bool:
  Bool.and(Nat.is_eq(Y.ms_nv(m), 8n),
    Bool.and(Nat.is_eq(Y.ms_ne(m), 12n),
      Nat.is_eq(Y.ms_nf(m), 6n)))

def t_ms_counts() -> U64:
  Bool.pick(U64, ms_counts_ok(Y.sok_ms_of(O.ms_box(1.0f64,
    2.0f64, 3.0f64, 0.0f64, 0.0f64, 0.0f64, ub()))), 0u64,
    1u64)

def t_ms_zero() -> U64:
  Bool.pick(U64, BX.kind_is(O.ms_box(0.0f64, 2.0f64, 3.0f64,
    0.0f64, 0.0f64, 0.0f64, ub()), 0u64), 0u64, 1u64)

def t_ms_over() -> U64:
  Bool.pick(U64, BX.kind_is(O.ms_box(1.0e308f64, 1.0e308f64,
    1.0f64, 0.0f64, 0.0f64, 0.0f64, ub()), 1u64), 0u64, 1u64)

def t_ms_corner() -> U64:
  Bool.pick(U64, BX.kind_is(O.ms_box(1.0e308f64, 0.1f64, 0.1f64,
    1.0e308f64, 0.0f64, 0.0f64, ub()), 1u64), 0u64, 1u64)

def t_incid_low() -> U64:
  Bool.pick(U64, Nat.is_eq(C4.brep_incid_c(ub(), 0n), 0n), 0u64, 1u64)

def t_incid_box() -> U64:
  Bool.pick(U64, Nat.is_eq(C4.brep_incid_c(ub(), 10000n), 3n),
    0u64, 1u64)

def t_orient_low() -> U64:
  Bool.pick(U64, Nat.is_eq(C4.brep_orient_c(ub(), 0n), 0n), 0u64, 1u64)

def t_orient_box() -> U64:
  Bool.pick(U64, Nat.is_eq(C4.brep_orient_c(ub(), 10000n), 3n),
    0u64, 1u64)

def total() -> U64:
  U64.add(t_stage_go_0(), U64.add(t_stage_go_incid(),
    U64.add(t_stage_go_embed(), U64.add(t_stage_go_unknown(),
      U64.add(t_stage_ex_fuel(), U64.add(t_att_go_first(),
        U64.add(t_att_go_last(), U64.add(t_att_go_fuel(),
          U64.add(t_att_go_unknown(), U64.add(t_att3_ok(),
            U64.add(t_att3_first(), U64.add(t_stc_undecided(),
              U64.add(t_bulk_c_pass(), U64.add(t_bulk_c_terr(),
                U64.add(t_bulk_a_ok(), U64.add(t_bulk_a_att(),
                  U64.add(t_att_tag_box(), U64.add(t_diag_fuel(),
                    U64.add(t_diag_valid(), U64.add(t_trim_cyl(),
                      U64.add(t_trim_t(), U64.add(t_trim_other(),
                        U64.add(t_trim_over(), U64.add(t_trim_axis(), U64.add(t_ms_ok(),
                          U64.add(t_ms_vol(), U64.add(t_ms_area(),
                            U64.add(t_ms_counts(),
                              U64.add(t_ms_zero(),
                                U64.add(t_ms_over(),
                                  U64.add(t_ms_corner(),
                                    U64.add(t_incid_low(),
                                      U64.add(t_incid_box(),
                                        U64.add(t_orient_low(),
                                          t_orient_box()))))))))))))))))))))))))))))))))))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("selfcheck fails=" ++ U64.show(total()))
