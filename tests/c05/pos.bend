import Base
import ../../src/c05/arrange.bend as A
import ../../src/c05/solve.bend as S
import ./check.bend as C

def hole() -> List<&2, A.Seg>:
  C.cat(C.sq(1u64, 0.0f64, 0.0f64, 10.0f64, 10.0f64), C.sq(11u64, 2.0f64, 2.0f64, 8.0f64, 8.0f64))

def cross() -> List<&2, A.Seg>:
  C.cat(C.sq(1u64, 0.0f64, 0.0f64, 4.0f64, 4.0f64), C.sq(11u64, 2.0f64, 2.0f64, 6.0f64, 6.0f64))

def unit() -> List<&2, A.Seg>:
  C.sq(1u64, 0.0f64, 0.0f64, 4.0f64, 4.0f64)

def star() -> List<&2, A.Seg>:
  C.cat([A.Seg{21u64, 0.0f64, 0.0f64, 4.0f64, 4.0f64}, A.Seg{22u64, 0.0f64, 4.0f64, 4.0f64, 0.0f64},
    A.Seg{23u64, 2.0f64, 0.0f64, 2.0f64, 4.0f64}], unit())

def arr_cases() -> List<&2, C.Case>:
  [C.Case{"pos-arr-square", C.arr(unit(), 100n), "v=4 e=4 c=1 R { e1.0[1] e1.1[2] e2.1[3] e3.1[4] } D"},
   C.Case{"pos-arr-hole", C.arr(hole(), 100n), "v=8 e=8 c=2 R { e1.0[1] e1.1[2] e2.1[3] e3.1[4] | e11.0[14] e13.1[13] e12.1[12] e11.1[11] } { e11.0[11] e11.1[12] e12.1[13] e13.1[14] } D"},
   C.Case{"pos-arr-nest", C.arr(C.cat(hole(), C.sq(21u64, 4.0f64, 4.0f64, 6.0f64, 6.0f64)), 100n), "v=12 e=12 c=3 R { e1.0[1] e1.1[2] e2.1[3] e3.1[4] | e11.0[14] e13.1[13] e12.1[12] e11.1[11] } { e11.0[11] e11.1[12] e12.1[13] e13.1[14] | e21.0[24] e23.1[23] e22.1[22] e21.1[21] } { e21.0[21] e21.1[22] e22.1[23] e23.1[24] } D"},
   C.Case{"pos-arr-cross", C.arr(cross(), 100n), "v=10 e=12 c=1 R { e1.0[1] e1.1[2] x2.11[11] e11.0[14] x3.14[3] e3.1[4] } { e11.0[11] x2.11[2] e2.1[3] x3.14[14] } { x3.14[3] e2.1[2] x2.11[11] e11.1[12] e12.1[13] e13.1[14] } D"},
   C.Case{"pos-arr-perm", C.arr(C.rev(cross(), []), 100n), C.arr(cross(), 100n)},
   C.Case{"pos-arr-antenna", C.arr(C.cat([A.Seg{9u64, 2.0f64, 0.0f64, 2.0f64, 1.0f64}], unit()), 100n), "v=6 e=6 c=1 R { e1.0[1] e9.0[1] e1.1[2] e2.1[3] e3.1[4] } D e9.0-e9.1"},
   C.Case{"pos-arr-bridge", C.arr(C.cat([A.Seg{9u64, 4.0f64, 2.0f64, 6.0f64, 2.0f64}],
     C.cat(unit(), C.sq(11u64, 6.0f64, 0.0f64, 8.0f64, 4.0f64))), 100n), "v=10 e=11 c=1 R { e1.0[1] e1.1[2] e9.0[2] e2.1[3] e3.1[4] } { e11.0[11] e11.1[12] e12.1[13] e13.1[14] e9.1[14] } D e9.0-e9.1"},
   C.Case{"pos-arr-overlap", C.arr(C.cat([A.Seg{9u64, 1.0f64, 0.0f64, 3.0f64, 0.0f64}], unit()), 100n), "v=6 e=6 c=1 R { e1.0[1] e9.0[1,9] e9.1[1] e1.1[2] e2.1[3] e3.1[4] } D"},
   C.Case{"pos-arr-islands", C.arr(C.cat(C.sq(1u64, 0.0f64, 0.0f64, 2.0f64, 2.0f64),
     C.sq(11u64, 5.0f64, 0.0f64, 7.0f64, 2.0f64)), 100n), "v=8 e=8 c=2 R { e1.0[1] e1.1[2] e2.1[3] e3.1[4] } { e11.0[11] e11.1[12] e12.1[13] e13.1[14] } D"},
   C.Case{"pos-arr-star", C.arr(star(), 100n), "v=7 e=12 c=1 R { e1.0[1] e23.0[23] x21.22[21] } { e1.0[21] x21.22[22] e3.1[4] } { e3.1[22] x21.22[23] e23.1[3] } { e23.0[1] e1.1[22] x21.22[23] } { x21.22[22] e1.1[2] e2.1[21] } { x21.22[21] e2.1[3] e23.1[23] } D"},
   C.Case{"pos-arr-tenth", C.arr([A.Seg{1u64, 0.1f64, 0.1f64, 0.3f64, 0.3f64},
     A.Seg{2u64, 0.1f64, 0.3f64, 0.3f64, 0.1f64}, A.Seg{3u64, 0.1f64, 0.1f64, 0.3f64, 0.1f64}], 100n), "v=5 e=5 c=1 R { e1.0[3] e2.1[2] x1.2[1] } D e2.0-x1.2 x1.2-e1.1"},
   C.Case{"pos-arr-region-keys", A.ares_keys(A.arrange(C.cat(hole(), C.sq(21u64, 4.0f64, 4.0f64, 6.0f64, 6.0f64)), 100n)),
     "keys [1,2,3,4,11,12,13,14] [11,12,13,14,21,22,23,24] [21,22,23,24]"},
   C.Case{"pos-arr-empty", C.arr([], 0n), "v=0 e=0 c=0 R D"}]

def sol_cases() -> List<&2, C.Case>:
  [C.Case{"pos-sol-line", C.sol(C.line_ps(), C.line_fr(),
     [S.K_horiz{1u64, C.pt(0n, 1n), C.pt(2n, 3n)}, S.K_dist{2u64, C.pt(0n, 1n), C.pt(2n, 3n), 20.0f64}], 100n), "ok dof=0 red=[] ps= 0 0 20 1.0524505733705337e-24"},
   C.Case{"pos-sol-determinism", C.sol(C.line_ps(), C.line_fr(),
     [S.K_horiz{1u64, C.pt(0n, 1n), C.pt(2n, 3n)}, S.K_dist{2u64, C.pt(0n, 1n), C.pt(2n, 3n), 20.0f64}], 100n),
     C.sol(C.line_ps(), C.line_fr(),
     [S.K_horiz{1u64, C.pt(0n, 1n), C.pt(2n, 3n)}, S.K_dist{2u64, C.pt(0n, 1n), C.pt(2n, 3n), 20.0f64}], 100n)},
   C.Case{"pos-sol-under", C.sol(C.line_ps(), C.line_fr(), [S.K_horiz{1u64, C.pt(0n, 1n), C.pt(2n, 3n)}], 100n), "ok dof=1 red=[] ps= 0 0 8.284655149237857 1.937627004915847e-20"},
   C.Case{"pos-sol-redundant", C.sol(C.line_ps(), C.line_fr(),
     [S.K_dist{1u64, C.pt(0n, 1n), C.pt(2n, 3n), 10.0f64}, S.K_dist{2u64, C.pt(0n, 1n), C.pt(2n, 3n), 10.0f64}], 100n), "ok dof=1 red=[2] ps= 0 0 9.191450300180579 3.939192985791676"},
   C.Case{"pos-sol-parallel", C.sol(C.two_ps(), C.two_fr(),
     [S.K_par{1u64, C.pt(0n, 1n), C.pt(2n, 3n), C.pt(4n, 5n), C.pt(6n, 7n)}], 100n), "ok dof=1 red=[] ps= 0 0 10 0 0 5 9.99843969468711 5"},
   C.Case{"pos-sol-perp", C.sol(C.two_ps(), C.two_fr(),
     [S.K_perp{1u64, C.pt(0n, 1n), C.pt(2n, 3n), C.pt(4n, 5n), C.pt(6n, 7n)}], 100n), "ok dof=1 red=[] ps= 0 0 10 0 0 5 3.918780960152284e-20 24.987511708789736"},
   C.Case{"pos-sol-perp-grounded", C.sol([0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 5.0f64, 0.0f64, 9.0f64], C.ff(8n),
     [S.K_perp{1u64, C.pt(0n, 1n), C.pt(2n, 3n), C.pt(4n, 5n), C.pt(6n, 7n)}], 100n), "ok dof=0 red=[1] ps= 0 0 10 0 0 5 0 9"},
   C.Case{"pos-sol-angle30", C.sol([0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 0.0f64, 8.0f64, 9.0f64], C.two_fr(),
     [S.K_angle{1u64, C.pt(0n, 1n), C.pt(2n, 3n), C.pt(4n, 5n), C.pt(6n, 7n), 0.8660254037844387f64, 0.5f64},
      S.K_dist{2u64, C.pt(4n, 5n), C.pt(6n, 7n), 10.0f64}], 100n), "ok dof=0 red=[] ps= 0 0 10 0 0 0 8.660254037844386 4.999999999999999"},
   C.Case{"pos-sol-tan-lc", C.sol([0.0f64, 0.0f64, 10.0f64, 0.0f64, 4.0f64, 7.0f64, 3.0f64],
     [False{}, False{}, False{}, False{}, False{}, True{}, False{}],
     [S.K_tan_lc{1u64, C.pt(0n, 1n), C.pt(2n, 3n), C.pt(4n, 5n), 6n}], 100n), "ok dof=0 red=[] ps= 0 0 10 0 4 3 3"},
   C.Case{"pos-sol-tan-lc-below", C.sol([0.0f64, 0.0f64, 10.0f64, 0.0f64, 4.0f64, F64.neg(7.0f64), 3.0f64],
     [False{}, False{}, False{}, False{}, False{}, True{}, False{}],
     [S.K_tan_lc{1u64, C.pt(0n, 1n), C.pt(2n, 3n), C.pt(4n, 5n), 6n}], 100n), "ok dof=0 red=[] ps= 0 0 10 0 4 -3 3"},
   C.Case{"pos-sol-tan-cc-ext", C.sol([0.0f64, 0.0f64, 2.0f64, 9.0f64, 0.0f64, 3.0f64],
     [False{}, False{}, False{}, True{}, False{}, False{}],
     [S.K_tan_cc{1u64, C.pt(0n, 1n), 2n, C.pt(3n, 4n), 5n}], 100n), "ok dof=0 red=[] ps= 0 0 2 5 0 3"},
   C.Case{"pos-sol-tan-cc-int", C.sol([0.0f64, 0.0f64, 10.0f64, 3.0f64, 0.0f64, 4.0f64],
     [False{}, False{}, False{}, True{}, False{}, False{}],
     [S.K_tan_cc{1u64, C.pt(0n, 1n), 2n, C.pt(3n, 4n), 5n}], 100n), "ok dof=0 red=[] ps= 0 0 10 6 0 4"},
   C.Case{"pos-sol-arc", C.sol([0.0f64, 0.0f64, 5.0f64, 5.0f64, 1.0f64, 1.0f64, 4.0f64],
     [False{}, False{}, True{}, False{}, False{}, True{}, True{}],
     [S.K_on_circ{1u64, C.pt(3n, 4n), C.pt(0n, 1n), 2n}, S.K_on_circ{2u64, C.pt(5n, 6n), C.pt(0n, 1n), 2n},
      S.K_dist{3u64, C.pt(3n, 4n), C.pt(5n, 6n), 6.0f64}], 100n), "ok dof=0 red=[] ps= 0 0 5.0990195135927845 5 1 0.5869756248574631 5.065121875712685"},
   C.Case{"pos-sol-rect", C.sol([0.0f64, 0.0f64, 9.0f64, 1.0f64, 8.0f64, 5.0f64, 1.0f64, 4.0f64],
     List.append(&2, Bool, C.ff(2n), C.tt(6n)),
     [S.K_horiz{1u64, C.pt(0n, 1n), C.pt(2n, 3n)}, S.K_vert{2u64, C.pt(2n, 3n), C.pt(4n, 5n)},
      S.K_horiz{3u64, C.pt(4n, 5n), C.pt(6n, 7n)}, S.K_vert{4u64, C.pt(6n, 7n), C.pt(0n, 1n)},
      S.K_dist{5u64, C.pt(0n, 1n), C.pt(2n, 3n), 12.0f64}, S.K_dist{6u64, C.pt(2n, 3n), C.pt(4n, 5n), 5.0f64}], 100n), "ok dof=0 red=[] ps= 0 0 12 -6.133289621267596e-21 12 5 1.1141955500275019e-36 5"},
   C.Case{"pos-sol-rect-extra", C.sol([0.0f64, 0.0f64, 9.0f64, 1.0f64, 8.0f64, 5.0f64, 1.0f64, 4.0f64],
     List.append(&2, Bool, C.ff(2n), C.tt(6n)),
     [S.K_horiz{1u64, C.pt(0n, 1n), C.pt(2n, 3n)}, S.K_vert{2u64, C.pt(2n, 3n), C.pt(4n, 5n)},
      S.K_horiz{3u64, C.pt(4n, 5n), C.pt(6n, 7n)}, S.K_vert{4u64, C.pt(6n, 7n), C.pt(0n, 1n)},
      S.K_dist{5u64, C.pt(0n, 1n), C.pt(2n, 3n), 12.0f64}, S.K_dist{6u64, C.pt(2n, 3n), C.pt(4n, 5n), 5.0f64},
      S.K_par{7u64, C.pt(0n, 1n), C.pt(2n, 3n), C.pt(6n, 7n), C.pt(4n, 5n)}], 100n), "ok dof=0 red=[7] ps= 0 0 12 -4.067434864563482e-21 12 5 1.2321353924670854e-36 5"},
   C.Case{"pos-sol-on-line", C.sol([0.0f64, 0.0f64, 10.0f64, 5.0f64, 3.0f64, 4.0f64], List.append(&2, Bool, C.ff(4n), C.tt(2n)),
     [S.K_on_line{1u64, C.pt(4n, 5n), C.pt(0n, 1n), C.pt(2n, 3n)}], 100n), "ok dof=1 red=[] ps= 0 0 10 5 4.000000000000001 2.0000000000000004"},
   C.Case{"pos-sol-midpoint", C.sol([0.0f64, 0.0f64, 10.0f64, 4.0f64, 1.0f64, 1.0f64], List.append(&2, Bool, C.ff(4n), C.tt(2n)),
     [S.K_midpoint{1u64, C.pt(4n, 5n), C.pt(0n, 1n), C.pt(2n, 3n)}], 100n), "ok dof=0 red=[] ps= 0 0 10 4 5 2"},
   C.Case{"pos-sol-equal", C.sol([0.0f64, 0.0f64, 3.0f64, 4.0f64, 1.0f64, 7.0f64, 2.0f64, 9.0f64], List.append(&2, Bool, C.ff(6n), C.tt(2n)),
     [S.K_equal{1u64, C.pt(0n, 1n), C.pt(2n, 3n), C.pt(4n, 5n), C.pt(6n, 7n)}], 100n), "ok dof=1 red=[] ps= 0 0 3 4 1 7 3.2360679774997902 11.472135954999578"},
   C.Case{"pos-sol-hdist-vdist", C.sol([0.0f64, 0.0f64, 3.0f64, 4.0f64], C.line_fr(),
     [S.K_hdist{1u64, C.pt(0n, 1n), C.pt(2n, 3n), F64.neg(2.5f64)}, S.K_vdist{2u64, C.pt(0n, 1n), C.pt(2n, 3n), 6.0f64}], 100n), "ok dof=0 red=[] ps= 0 0 -2.5 6"},
   C.Case{"pos-sol-collinear-redundant", C.sol([0.0f64, 0.0f64, 10.0f64, 0.0f64, 4.0f64, 1.0f64], List.append(&2, Bool, C.ff(4n), C.tt(2n)),
     [S.K_on_line{1u64, C.pt(4n, 5n), C.pt(0n, 1n), C.pt(2n, 3n)}, S.K_horiz{2u64, C.pt(0n, 1n), C.pt(4n, 5n)}], 100n), "ok dof=1 red=[2] ps= 0 0 10 0 4.2493903932506845 9.942460778806745e-21"},
   C.Case{"pos-sol-equal-radii", C.sol([0.0f64, 0.0f64, 2.0f64, 9.0f64, 0.0f64, 3.0f64],
     [False{}, False{}, False{}, False{}, False{}, True{}],
     [S.K_same{1u64, 2n, 5n}], 100n), "ok dof=0 red=[] ps= 0 0 2 9 0 2"},
   C.Case{"pos-sol-par-antiparallel", C.sol([0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 5.0f64, F64.neg(10.0f64), 5.0f64], C.ff(8n),
     [S.K_par{1u64, C.pt(0n, 1n), C.pt(2n, 3n), C.pt(4n, 5n), C.pt(6n, 7n)}], 10n), "ok dof=0 red=[1] ps= 0 0 10 0 0 5 -10 5"},
   C.Case{"pos-sol-angle-from-far", C.sol([0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 0.0f64, F64.neg(9.4f64), F64.neg(3.4f64)], C.two_fr(),
     [S.K_angle{1u64, C.pt(0n, 1n), C.pt(2n, 3n), C.pt(4n, 5n), C.pt(6n, 7n), 0.8660254037844387f64, 0.5f64},
      S.K_dist{2u64, C.pt(4n, 5n), C.pt(6n, 7n), 10.0f64}], 100n), "ok dof=0 red=[] ps= 0 0 10 0 0 0 8.660254037844386 4.999999999999999"},
   C.Case{"pos-sol-signed-zero", C.sol([F64.neg(0.0f64), 1.0f64], [False{}, True{}],
     [S.K_fix{1u64, 1n, 2.0f64}], 100n), "ok dof=0 red=[] ps= 0 2"},
   C.Case{"pos-sol-zero-pivot", C.sol([5.1787109375f64, 1.302734375f64, 10.19921875f64, 1.28515625f64, 1.8203125f64, 1.01953125f64, 1.5400390625f64, F64.neg(3.0869140625f64)], [False{}, False{}, True{}, True{}, True{}, True{}, True{}, True{}], [S.K_hdist{3u64, S.Pt{6n, 7n}, S.Pt{0n, 1n}, 3.6572265625f64}, S.K_perp{6u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, S.Pt{0n, 1n}, S.Pt{2n, 3n}}, S.K_dist{11u64, S.Pt{4n, 5n}, S.Pt{2n, 3n}, 8.720686658469603f64}, S.K_dist{12u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 4.318359375f64}, S.K_vert{25u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}}, S.K_dist{27u64, S.Pt{4n, 5n}, S.Pt{6n, 7n}, 4.318359375f64}], 200n), "ok dof=1 red=[27] ps= 5.1787109375 1.302734375 10.240353556745635 1.302734375 1.521484375 1.1247007073527582 1.521484375 -3.193658667647242"},
   C.Case{"pos-sol-clusters-merge", C.sol([0.0f64, 0.0f64, 7.0f64, 3.0f64, 20.0f64, 0.0f64, 24.0f64, 2.0f64],
     [False{}, False{}, True{}, True{}, False{}, False{}, True{}, True{}],
     [S.K_dist{10u64, C.pt(4n, 5n), C.pt(6n, 7n), 5.0f64}, S.K_dist{11u64, C.pt(0n, 1n), C.pt(2n, 3n), 10.0f64},
      S.K_dist{12u64, C.pt(4n, 5n), C.pt(6n, 7n), 5.0f64}, S.K_dist{13u64, C.pt(0n, 1n), C.pt(2n, 3n), 10.0f64}], 100n), "ok dof=2 red=[12,13] ps= 0 0 9.191450300180579 3.939192985791676 20 0 24.47213595499958 2.2360679774997885"},
   C.Case{"pos-sol-conflict-localized", C.sol([0.0f64, 0.0f64, 7.0f64, 3.0f64, 20.0f64, 0.0f64, 24.0f64, 2.0f64],
     [False{}, False{}, True{}, True{}, False{}, False{}, True{}, True{}],
     [S.K_dist{20u64, C.pt(0n, 1n), C.pt(2n, 3n), 10.0f64}, S.K_dist{21u64, C.pt(4n, 5n), C.pt(6n, 7n), 5.0f64},
      S.K_dist{22u64, C.pt(4n, 5n), C.pt(6n, 7n), 6.0f64}], 100n), "conflict [21,22]"},
   C.Case{"pos-sol-nothing", C.sol([1.0f64, 2.0f64], [True{}, True{}], [], 100n), "ok dof=2 red=[] ps= 1 2"}]

def main() -> IO(Unit):
  C.finish(List.append(&2, C.Case, arr_cases(), sol_cases()))
