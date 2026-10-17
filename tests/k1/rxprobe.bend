import Base
import ../../src/c01/types.bend as V
import ../../src/k1/ring.bend as R

def ax() -> R.RC:
  R.RC{0u64, V.Pt{0.0f64, 0.0f64, 0.0f64}, 1.0f64}

def bx() -> R.RC:
  R.RC{2u64, V.Pt{0.0f64, 0.0f64, 0.0f64}, 1.0f64}

def bmiss() -> R.RC:
  R.RC{2u64, V.Pt{0.0f64, 5.0f64, 0.0f64}, 1.0f64}

def slv0(+rs: List<&2, R.RING>) -> String:
  match rs:
    case []: "none"
    case +h <> +t: F64.show(R.ring_slv(h)) ++ "," ++ F64.show(R.ring_sla(h))

def main() -> String:
  R.rx_dbg(ax(), bx(), 1u64, [], True{}) ++ "\n" ++
  R.rx_dbg(ax(), bx(), 1u64, [], False{}) ++ "\n" ++
  R.rx_dbg(ax(), bmiss(), 1u64, [], True{}) ++ "\n" ++
  slv0(R.rxr_ra(R.rx_rings(ax(), bx(), 1u64, []))) ++ "\n"
