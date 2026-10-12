import Base

import ../../src/c01/types.bend as V

import ../../src/c03/types.bend as G

import ../../src/c10/mesh.bend as M10

def chord_bits(+p: U64) -> U64:
  F64.bits(M10.q_chord(M10.q_preset(p)))

def angle_bits(+p: U64) -> U64:
  F64.bits(M10.q_angle(M10.q_preset(p)))

def preset_chord_0__got() -> U64:
  chord_bits(0u64)

def preset_chord_0__want() -> U64:
  4611686018427387904u64

def preset_angle_0__got() -> U64:
  angle_bits(0u64)

def preset_angle_0__want() -> U64:
  4600877379321698714u64

def preset_chord_1__got() -> U64:
  chord_bits(1u64)

def preset_chord_1__want() -> U64:
  4607182418800017408u64

def preset_angle_1__got() -> U64:
  angle_bits(1u64)

def preset_angle_1__want() -> U64:
  4596373779694328218u64

def preset_chord_2__got() -> U64:
  chord_bits(2u64)

def preset_chord_2__want() -> U64:
  4598175219545276416u64

def preset_angle_2__got() -> U64:
  angle_bits(2u64)

def preset_angle_2__want() -> U64:
  4587366580439587226u64

def preset_chord_3__got() -> U64:
  chord_bits(3u64)

def preset_chord_3__want() -> U64:
  4587366580439587226u64

def preset_angle_3__got() -> U64:
  angle_bits(3u64)

def preset_angle_3__want() -> U64:
  4576918229304087675u64

def preset_max_0__got() -> Nat:
  M10.q_max(M10.q_preset(0u64))

def preset_max_0__want() -> Nat:
  10000000n

def preset_max_1__got() -> Nat:
  M10.q_max(M10.q_preset(1u64))

def preset_max_1__want() -> Nat:
  10000000n

def preset_max_2__got() -> Nat:
  M10.q_max(M10.q_preset(2u64))

def preset_max_2__want() -> Nat:
  10000000n

def preset_max_3__got() -> Nat:
  M10.q_max(M10.q_preset(3u64))

def preset_max_3__want() -> Nat:
  10000000n

def preset_prof_0__got() -> U64:
  M10.q_prof(M10.q_preset(0u64))

def preset_prof_0__want() -> U64:
  0u64

def preset_prof_1__got() -> U64:
  M10.q_prof(M10.q_preset(1u64))

def preset_prof_1__want() -> U64:
  0u64

def preset_prof_2__got() -> U64:
  M10.q_prof(M10.q_preset(2u64))

def preset_prof_2__want() -> U64:
  0u64

def preset_prof_3__got() -> U64:
  M10.q_prof(M10.q_preset(3u64))

def preset_prof_3__want() -> U64:
  1u64

def preset_ok_0__got() -> Bool:
  M10.q_ok(M10.q_preset(0u64))

def preset_ok_0__want() -> Bool:
  True{}

def preset_ok_1__got() -> Bool:
  M10.q_ok(M10.q_preset(1u64))

def preset_ok_1__want() -> Bool:
  True{}

def preset_ok_2__got() -> Bool:
  M10.q_ok(M10.q_preset(2u64))

def preset_ok_2__want() -> Bool:
  True{}

def preset_ok_3__got() -> Bool:
  M10.q_ok(M10.q_preset(3u64))

def preset_ok_3__want() -> Bool:
  True{}

def preset_prof_ok_0__got() -> Bool:
  M10.q_prof_ok(M10.q_preset(0u64))

def preset_prof_ok_0__want() -> Bool:
  True{}

def preset_prof_ok_1__got() -> Bool:
  M10.q_prof_ok(M10.q_preset(1u64))

def preset_prof_ok_1__want() -> Bool:
  True{}

def preset_prof_ok_2__got() -> Bool:
  M10.q_prof_ok(M10.q_preset(2u64))

def preset_prof_ok_2__want() -> Bool:
  True{}

def preset_prof_ok_3__got() -> Bool:
  M10.q_prof_ok(M10.q_preset(3u64))

def preset_prof_ok_3__want() -> Bool:
  True{}

def preset_max_tag__got() -> U64:
  M10.q_preset_max()

def preset_max_tag__want() -> U64:
  3u64

def budget_under__got() -> Bool:
  M10.budget_ok(5n, 10n)

def budget_under__want() -> Bool:
  True{}

def budget_equal__got() -> Bool:
  M10.budget_ok(10n, 10n)

def budget_equal__want() -> Bool:
  True{}

def budget_over__got() -> Bool:
  M10.budget_ok(11n, 10n)

def budget_over__want() -> Bool:
  False{}

def tri_strip__got() -> Nat:
  M10.tri_est_strip(7n)

def tri_strip__want() -> Nat:
  14n

def tri_fan__got() -> Nat:
  M10.tri_est_fan(7n)

def tri_fan__want() -> Nat:
  7n

def tri_add__got() -> Nat:
  M10.tri_est_add(3n, 4n)

def tri_add__want() -> Nat:
  7n

def segs_len_10_1__got() -> Nat:
  M10.segs_len(10.0f64, 1.0f64)

def segs_len_10_1__want() -> Nat:
  11n

def segs_ang_pi_02__got() -> Nat:
  M10.segs_ang(3.141592653589793f64, 0.2f64)

def segs_ang_pi_02__want() -> Nat:
  16n

def unit_circle() -> G.Circle3:
  G.Cc{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}, 5.0f64}

def segs_min_cc_full__got() -> Nat:
  M10.segs_min(G.GV_cc{unit_circle()}, G.Dom{F64.neg(1.0f64), 1.0f64})

def segs_min_cc_full__want() -> Nat:
  3n

def segs_min_cc_part__got() -> Nat:
  M10.segs_min(G.GV_cc{unit_circle()}, G.Dom{0.0f64, 1.0f64})

def segs_min_cc_part__want() -> Nat:
  1n

def cc_span_full__got() -> U64:
  F64.bits(M10.cc_span(G.Dom{F64.neg(1.0f64), 1.0f64}))

def cc_span_full__want() -> U64:
  4618760256179416344u64

def cc_span_part__got() -> U64:
  F64.bits(M10.cc_span(G.Dom{0.0f64, 1.0f64}))

def cc_span_part__want() -> U64:
  4616189618054758400u64

def segs_edge_ln10__got() -> Nat:
  M10.segs_edge(G.GV_ln{G.Ln{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}}},
    G.Dom{0.0f64, 10.0f64}, M10.q_preset(1u64))

def segs_edge_ln10__want() -> Nat:
  11n

def segs_edge_cc_full__got() -> Nat:
  M10.segs_edge(G.GV_cc{unit_circle()}, G.Dom{F64.neg(1.0f64), 1.0f64}, M10.q_preset(1u64))

def segs_edge_cc_full__want() -> Nat:
  32n

def two_pi_bits__got() -> U64:
  F64.bits(M10.two_pi())

def two_pi_bits__want() -> U64:
  4618760256179416344u64

def q_display_tag__got() -> U64:
  M10.q_display()

def q_display_tag__want() -> U64:
  0u64

def q_manufacturing_tag__got() -> U64:
  M10.q_manufacturing()

def q_manufacturing_tag__want() -> U64:
  1u64
