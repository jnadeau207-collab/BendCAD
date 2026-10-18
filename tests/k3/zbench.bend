import Base
import ../../src/base/par.bend as B

def gen(n: Nat, +x: F64) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+m: x <> gen(m, F64.add(x, 0.5f64))

def gath(k: Nat, +tb: B.Tb<&2, F64>, +n: U32, +s: U32, +acc: F64) -> F64:
  match k:
    case 0n: acc
    case 1n+(+m):
      +j = U32.mod(U32.add(U32.mul(s, 31), U32.mul(U32.from_nat(m), 977)), n)
      gath(m, tb, n, s, F64.add(acc, F64.mul(1.0000001f64, B.tb_get(F64, tb, j))))

def rows(i: Nat, +tb: B.Tb<&2, F64>, +n: U32, +acc: F64) -> F64:
  match i:
    case 0n: acc
    case 1n+(+m): rows(m, tb, n, gath(81n, tb, n, U32.from_nat(m), acc))

def main() -> String:
  +n = {100000n : Nat}
  +tb = B.tb_of(F64, gen(n, 0.0f64), 0.0f64)
  F64.show(rows(n, tb, U32.from_nat(n), 0.0f64))
