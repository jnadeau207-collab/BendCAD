import Base
import ../c00/types.bend as T
import ../c06/iv.bend as I
import ../c06/sx.bend as S

type Bv is Data:
  Bv{ lo: F64, hi: F64, st: U64 }

def st_certified() -> U64:
  1u64

def st_estimated() -> U64:
  2u64

def st_assumed() -> U64:
  3u64

def st_show(+s: U64) -> String:
  match s:
    case 0u64: "proven"
    case 1u64: "certified"
    case 2u64: "estimated"
    case _: "assumed"

def bv_mk(+lo: F64, +hi: F64, +st: U64) -> Bv:
  Bv{lo, hi, st}

def bv_lo(+b: Bv) -> F64:
  Bv{lo, hi, st} = b
  lo

def bv_hi(+b: Bv) -> F64:
  Bv{lo, hi, st} = b
  hi

def bv_st(+b: Bv) -> U64:
  Bv{lo, hi, st} = b
  st

def bv_show(+b: Bv) -> String:
  "[" ++ S.f_show(bv_lo(b)) ++ ", " ++ S.f_show(bv_hi(b)) ++ "] " ++ st_show(bv_st(b))

def inc_s(+n: Nat) -> String:
  Bool.pick(String, Nat.is_eq(n, 0n), "", " incomplete-cells=" ++ Nat.show(n))

def qfail(+kind: String, +what: String, +why: String, +fix: String) -> String:
  "error " ++ kind ++ " | " ++ what ++ " | why: " ++ why ++ " | fix: " ++ fix

def depth_max() -> Nat:
  6n

def depth_dflt() -> Nat:
  4n

def depth_ok(+d: Nat) -> Bool:
  Nat.is_le(d, depth_max())
