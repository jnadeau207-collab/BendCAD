import Base
import ../../src/c00/types.bend as T
import ../../src/c05/arrange.bend as A
import ../../src/c05/solve.bend as S
import ./check.bend as C

def nan() -> F64:
  (0.0f64 / 0.0f64 : F64)

def inf() -> F64:
  (1.0f64 / 0.0f64 : F64)

def tiny() -> F64:
  F64{2220274616293654528u64}

def huge() -> F64:
  F64{7309342195222315008u64}

def ex(+s: F64) -> List<&2, A.Seg>:
  [A.Seg{1u64, 0.0f64, 0.0f64, s, s}, A.Seg{2u64, 0.0f64, s, s, 0.0f64}]

def inv() -> String:
  "err invalid-input"

def arr_cases() -> List<&2, C.Case>:
  [C.Case{"neg-arr-degenerate", C.arr([A.Seg{1u64, 1.0f64, 1.0f64, 1.0f64, 1.0f64}], 100n), inv()},
   C.Case{"neg-arr-nan", C.arr([A.Seg{1u64, nan(), 0.0f64, 1.0f64, 1.0f64}], 100n), inv()},
   C.Case{"neg-arr-inf", C.arr([A.Seg{1u64, 0.0f64, 0.0f64, inf(), 1.0f64}], 100n), inv()},
   C.Case{"neg-arr-dup-id", C.arr([A.Seg{1u64, 0.0f64, 0.0f64, 1.0f64, 1.0f64},
     A.Seg{1u64, 0.0f64, 1.0f64, 1.0f64, 0.0f64}], 100n), inv()},
   C.Case{"neg-arr-fuel", C.arr(C.sq(1u64, 0.0f64, 0.0f64, 4.0f64, 4.0f64), 3n), "err resource-exhausted"},
   C.Case{"neg-arr-underflow", C.arr(ex(tiny()), 100n), "err numerical-uncertainty"},
   C.Case{"neg-arr-overflow", C.arr(ex(huge()), 100n), "err numerical-uncertainty"}]

def lp() -> List<&2, F64>:
  C.line_ps()

def lf() -> List<&2, Bool>:
  C.line_fr()

def anti() -> List<&2, F64>:
  [0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 5.0f64, F64.neg(10.0f64), 5.0f64]

def p01() -> S.Pt:
  C.pt(0n, 1n)

def p23() -> S.Pt:
  C.pt(2n, 3n)

def sol_cases() -> List<&2, C.Case>:
  [C.Case{"neg-sol-bad-index", C.sol(lp(), lf(), [S.K_fix{1u64, 4n, 0.0f64}], 100n), inv()},
   C.Case{"neg-sol-self-coinc", C.sol(lp(), lf(), [S.K_coinc{1u64, p23(), p23()}], 100n), inv()},
   C.Case{"neg-sol-self-horiz", C.sol(lp(), lf(), [S.K_horiz{1u64, p01(), p01()}], 100n), inv()},
   C.Case{"neg-sol-dist-zero", C.sol(lp(), lf(), [S.K_dist{1u64, p01(), p23(), 0.0f64}], 100n), inv()},
   C.Case{"neg-sol-dist-neg", C.sol(lp(), lf(), [S.K_dist{1u64, p01(), p23(), F64.neg(3.0f64)}], 100n), inv()},
   C.Case{"neg-sol-dist-nan", C.sol(lp(), lf(), [S.K_dist{1u64, p01(), p23(), nan()}], 100n), inv()},
   C.Case{"neg-sol-radius-zero", C.sol(lp(), lf(), [S.K_radius{1u64, 2n, 0.0f64}], 100n), inv()},
   C.Case{"neg-sol-angle-nonunit", C.sol(C.two_ps(), C.two_fr(),
     [S.K_angle{1u64, p01(), p23(), C.pt(4n, 5n), C.pt(6n, 7n), 1.0f64, 1.0f64}], 100n), inv()},
   C.Case{"neg-sol-par-self", C.sol(lp(), lf(), [S.K_par{1u64, p01(), p23(), p01(), p23()}], 100n), inv()},
   C.Case{"neg-sol-par-self-rev", C.sol(lp(), lf(), [S.K_par{1u64, p01(), p23(), p23(), p01()}], 100n), inv()},
   C.Case{"neg-sol-dup-id", C.sol(lp(), lf(), [S.K_horiz{1u64, p01(), p23()}, S.K_vert{1u64, p01(), p23()}], 100n), inv()},
   C.Case{"neg-sol-free-len", C.sol(lp(), [True{}], [S.K_horiz{1u64, p01(), p23()}], 100n), inv()},
   C.Case{"neg-sol-nan-param", C.sol([0.0f64, nan(), 1.0f64, 1.0f64], lf(), [S.K_horiz{1u64, p01(), p23()}], 100n), inv()},
   C.Case{"neg-sol-tol-zero", C.sol_t(lp(), lf(), [S.K_horiz{1u64, p01(), p23()}],
     T.mk_tol(0.0f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64), 100n), inv()},
   C.Case{"neg-sol-zero-line", C.sol([0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 1.0f64], C.tt(6n),
     [S.K_par{1u64, p01(), p23(), p01(), C.pt(4n, 5n)}], 100n), inv()},
   C.Case{"neg-sol-tan-cc-same", C.sol([0.0f64, 0.0f64, 1.0f64, 2.0f64], C.tt(4n),
     [S.K_tan_cc{1u64, p01(), 2n, p01(), 3n}], 100n), inv()},
   C.Case{"neg-sol-oncirc-center", C.sol([0.0f64, 0.0f64, 1.0f64], C.tt(3n),
     [S.K_on_circ{1u64, p01(), p01(), 2n}], 100n), inv()},
   C.Case{"neg-sol-same-self", C.sol(lp(), lf(), [S.K_same{1u64, 2n, 2n}], 100n), inv()},
   C.Case{"neg-sol-grounded-contra", C.sol(lp(), C.ff(4n), [S.K_dist{5u64, p01(), p23(), 20.0f64}], 100n), "conflict [5]"},
   C.Case{"neg-sol-hv-axes", C.sol(lp(), lf(), [S.K_horiz{1u64, p01(), p23()}, S.K_vert{2u64, p01(), p23()},
     S.K_dist{3u64, p01(), p23(), 10.0f64}], 200n), "conflict [1,2]"},
   C.Case{"neg-sol-dist-5-6", C.sol(lp(), lf(), [S.K_dist{1u64, p01(), p23(), 5.0f64},
     S.K_dist{2u64, p01(), p23(), 6.0f64}], 200n), "conflict [1,2]"},
   C.Case{"neg-sol-triangle", C.sol([0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.5f64, 1.0f64], List.append(&2, Bool, C.ff(2n), C.tt(4n)),
     [S.K_dist{1u64, p01(), p23(), 1.0f64}, S.K_dist{2u64, p23(), C.pt(4n, 5n), 1.0f64},
      S.K_dist{3u64, p01(), C.pt(4n, 5n), 5.0f64}], 300n), "conflict [1,2,3]"},
   C.Case{"neg-sol-perp-grounded", C.sol(C.two_ps(), C.ff(8n),
     [S.K_perp{1u64, p01(), p23(), C.pt(4n, 5n), C.pt(6n, 7n)}], 100n), "conflict [1]"},
   C.Case{"neg-sol-hv-collapse", C.sol(lp(), lf(), [S.K_horiz{1u64, p01(), p23()}, S.K_vert{2u64, p01(), p23()}], 200n),
     "conflict [1,2]"},
   C.Case{"neg-sol-angle-flipped", C.sol(anti(), C.ff(8n),
     [S.K_angle{1u64, p01(), p23(), C.pt(4n, 5n), C.pt(6n, 7n), 1.0f64, 0.0f64}], 10n), "conflict [1]"},
   C.Case{"neg-sol-angle90-flipped", C.sol([0.0f64, 0.0f64, 10.0f64, 0.0f64, 0.0f64, 5.0f64, 0.0f64, F64.neg(5.0f64)], C.ff(8n),
     [S.K_angle{1u64, p01(), p23(), C.pt(4n, 5n), C.pt(6n, 7n), 0.0f64, 1.0f64}], 10n), "conflict [1]"},
   C.Case{"neg-sol-radius-start", C.sol([0.0f64, 0.0f64, 3.0f64, 0.0f64, F64.neg(1.0f64)], C.tt(5n),
     [S.K_on_circ{1u64, C.pt(2n, 3n), p01(), 4n}], 100n), inv()},
   C.Case{"neg-sol-radius-cross", C.sol([0.0f64, 0.0f64, 10.0f64, 0.0f64, 4.0f64, 3.0f64, 3.0f64],
     [False{}, False{}, False{}, False{}, False{}, True{}, True{}],
     [S.K_tan_lc{1u64, p01(), p23(), C.pt(4n, 5n), 6n}, S.K_vdist{2u64, p01(), C.pt(4n, 5n), F64.neg(2.0f64)}], 100n), "err nonconvergence"},
   C.Case{"neg-sol-coinc-collapse", C.sol(lp(), lf(), [S.K_coinc{1u64, p01(), p23()}, S.K_horiz{2u64, p01(), p23()}], 100n), "err nonconvergence"},
   C.Case{"neg-sol-fuel-1", C.sol(lp(), lf(), [S.K_horiz{1u64, p01(), p23()},
     S.K_dist{2u64, p01(), p23(), 20.0f64}], 1n), "err nonconvergence"},
   C.Case{"neg-sol-fuel-0", C.sol(lp(), lf(), [S.K_horiz{1u64, p01(), p23()},
     S.K_dist{2u64, p01(), p23(), 20.0f64}], 0n), "err nonconvergence"}]

def main() -> IO(Unit):
  C.finish(List.append(&2, C.Case, arr_cases(), sol_cases()))
