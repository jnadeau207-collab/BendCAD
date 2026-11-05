import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/k1/ss.bend as SS

def main() -> IO(Unit):
  IO.print(U64.show(SS.ics_why(SS.ssi(G.GV_to{G.To{V.Pt{0.0f64, 0.0f64, 1.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 24.0f64, 2.0f64}}, G.GV_to{G.To{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 25.0f64, 2.0f64}}))))
