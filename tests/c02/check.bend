# C02 test support: reporters over PRes/Xres/Tres + shared fixtures.
# Imported by neg.bend/pos.bend; no main here.

import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c02/types.bend as P
import ../../src/c02/ops.bend as O

def verdict(ok: Bool) -> String:
  match ok:
    case True{}: "PASS"
    case False{}: "FAIL"

def bump(f: U64, ok: Bool) -> U64:
  (f + Bool.to_u64(Bool.not(ok)) : U64)

# Perr of the wanted kind (structured failure, no sign published).
def perr_as(+r: P.PRes, want: String) -> Bool:
  String.eq(P.pres_show(r), want)

def report_perr(tag: String, +r: P.PRes, +want: String,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(perr_as(r, want))
      ++ " [" ++ P.pres_show(r) ++ "]")
    return bump(f, perr_as(r, want))

# Pok with the wanted sign.
def ps_as(+r: P.PRes, want: String) -> Bool:
  Bool.and(String.eq(P.pres_show(r), "ok"),
    String.eq(P.pres_sign_show(r), want))

def report_ps(tag: String, +r: P.PRes, +want: String,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(ps_as(r, want))
      ++ " [" ++ P.pres_show(r) ++ ":" ++ P.pres_sign_show(r) ++ "]")
    return bump(f, ps_as(r, want))

# Xok with the wanted relation.
def xr_as(+r: P.Xres, want: String) -> Bool:
  Bool.and(String.eq(P.xres_show(r), "ok"),
    String.eq(P.xres_rel_show(r), want))

def report_xr(tag: String, +r: P.Xres, +want: String,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(xr_as(r, want))
      ++ " [" ++ P.xres_show(r) ++ ":" ++ P.xres_rel_show(r) ++ "]")
    return bump(f, xr_as(r, want))

def xerr_as(+r: P.Xres, want: String) -> Bool:
  String.eq(P.xres_show(r), want)

def report_xerr(tag: String, +r: P.Xres, +want: String,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(xerr_as(r, want))
      ++ " [" ++ P.xres_show(r) ++ "]")
    return bump(f, xerr_as(r, want))

# Tok with the wanted class.
def tc_as(+r: P.Tres, want: String) -> Bool:
  Bool.and(String.eq(P.tres_show(r), "ok"),
    String.eq(P.tres_cls_show(r), want))

def report_tc(tag: String, +r: P.Tres, +want: String,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(tc_as(r, want))
      ++ " [" ++ P.tres_show(r) ++ ":" ++ P.tres_cls_show(r) ++ "]")
    return bump(f, tc_as(r, want))

def terr_as(+r: P.Tres, want: String) -> Bool:
  String.eq(P.tres_show(r), want)

def report_terr(tag: String, +r: P.Tres, +want: String,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(terr_as(r, want))
      ++ " [" ++ P.tres_show(r) ++ "]")
    return bump(f, terr_as(r, want))

def report_pure(tag: String, +ok: Bool, f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(ok))
    return bump(f, ok)

# --- Shared fixtures (bit-exact; python struct, see receipt) ---
def n25() -> F64:
  F64{4719772409484279808u64}

def n25p1() -> F64:
  F64{4719772409618497536u64}

def n25p2() -> F64:
  F64{4719772409752715264u64}

def w251() -> F64:
  F64{4611686018427387905u64}

def q148() -> F64:
  F64{4607182418800017424u64}

def q147() -> F64:
  F64{4607182418800017440u64}

def big150() -> F64:
  F64{6850974717710472879u64}

def tiny500() -> F64:
  F64{2355382605114769408u64}

def p2e60() -> F64:
  F64{4877398396442247168u64}

def lim26() -> F64:
  F64{4724276009111650304u64}

def lim26p1() -> F64:
  F64{4724276009178759168u64}

def ccw_tri_a() -> V.Vec2:
  V.V2{0.0f64, 0.0f64}

def ccw_tri_b() -> V.Vec2:
  V.V2{4.0f64, 0.0f64}

def ccw_tri_c() -> V.Vec2:
  V.V2{0.0f64, 4.0f64}
