# C01 test support: reporters over CRes. Imported by neg.bend/pos.bend.

import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c01/ops.bend as O

def verdict(ok: Bool) -> String:
  match ok:
    case True{}: "PASS"
    case False{}: "FAIL"

def bump(f: U64, ok: Bool) -> U64:
  (f + Bool.to_u64(Bool.not(ok)) : U64)

# Cerr of the wanted kind (structured failure, no value published).
def err_as(+r: V.CRes, want: String) -> Bool:
  String.eq(V.cres_show(r), want)

def report_err(tag: String, +r: V.CRes, +want: String, f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(err_as(r, want))
      ++ " [" ++ V.cres_show(r) ++ "]")
    return bump(f, err_as(r, want))

# Cok F64 pinned to exact bits.
def f_as(+r: V.CRes, want: U64) -> Bool:
  Bool.and(String.eq(V.cres_show(r), "ok"),
    U64.is_eq(F64.bits(V.cres_f(r)), want))

def report_f(tag: String, +r: V.CRes, +want: U64, f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(f_as(r, want))
      ++ " [" ++ V.cres_show(r) ++ "]")
    return bump(f, f_as(r, want))

# Cok Vec3 pinned to exact component bits.
def v3_as(+r: V.CRes, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  +v = V.cres_v3(r)
  Bool.and(String.eq(V.cres_show(r), "ok"),
    Bool.and(U64.is_eq(F64.bits(V.v3_x(v)), wx),
      Bool.and(U64.is_eq(F64.bits(V.v3_y(v)), wy),
        U64.is_eq(F64.bits(V.v3_z(v)), wz))))

def report_v3(tag: String, +r: V.CRes, +wx: U64, +wy: U64, +wz: U64,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(v3_as(r, wx, wy, wz))
      ++ " [" ++ V.cres_show(r) ++ "]")
    return bump(f, v3_as(r, wx, wy, wz))

# Cok Vec2 pinned to exact component bits.
def v2_as(+r: V.CRes, +wx: U64, +wy: U64) -> Bool:
  +v = V.cres_v2(r)
  Bool.and(String.eq(V.cres_show(r), "ok"),
    Bool.and(U64.is_eq(F64.bits(V.v2_x(v)), wx),
      U64.is_eq(F64.bits(V.v2_y(v)), wy)))

def report_v2(tag: String, +r: V.CRes, +wx: U64, +wy: U64,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(v2_as(r, wx, wy))
      ++ " [" ++ V.cres_show(r) ++ "]")
    return bump(f, v2_as(r, wx, wy))

# Cok Point pinned to exact component bits.
def p_as(+r: V.CRes, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  +p = V.cres_p(r)
  Bool.and(String.eq(V.cres_show(r), "ok"),
    Bool.and(U64.is_eq(F64.bits(V.pt_x(p)), wx),
      Bool.and(U64.is_eq(F64.bits(V.pt_y(p)), wy),
        U64.is_eq(F64.bits(V.pt_z(p)), wz))))

def report_p(tag: String, +r: V.CRes, +wx: U64, +wy: U64, +wz: U64,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(p_as(r, wx, wy, wz))
      ++ " [" ++ V.cres_show(r) ++ "]")
    return bump(f, p_as(r, wx, wy, wz))

# Cok Dir pinned to exact component bits.
def d_as(+r: V.CRes, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  +d = V.cres_d(r)
  Bool.and(String.eq(V.cres_show(r), "ok"),
    Bool.and(U64.is_eq(F64.bits(V.dr_x(d)), wx),
      Bool.and(U64.is_eq(F64.bits(V.dr_y(d)), wy),
        U64.is_eq(F64.bits(V.dr_z(d)), wz))))

def report_d(tag: String, +r: V.CRes, +wx: U64, +wy: U64, +wz: U64,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(d_as(r, wx, wy, wz))
      ++ " [" ++ V.cres_show(r) ++ "]")
    return bump(f, d_as(r, wx, wy, wz))

def report_pure(tag: String, +ok: Bool, f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(ok))
    return bump(f, ok)

# Cok Mat3 pinned to exact component bits.
def m_as(+r: V.CRes, +w0: U64, +w1: U64, +w2: U64, +w3: U64, +w4: U64,
    +w5: U64, +w6: U64, +w7: U64, +w8: U64) -> Bool:
  +m = V.cres_m(r)
  Bool.and(String.eq(V.cres_show(r), "ok"),
    Bool.and(U64.is_eq(F64.bits(V.m_a(m)), w0),
      Bool.and(U64.is_eq(F64.bits(V.m_b(m)), w1),
        Bool.and(U64.is_eq(F64.bits(V.m_c(m)), w2),
          Bool.and(U64.is_eq(F64.bits(V.m_d(m)), w3),
            Bool.and(U64.is_eq(F64.bits(V.m_e(m)), w4),
              Bool.and(U64.is_eq(F64.bits(V.m_f(m)), w5),
                Bool.and(U64.is_eq(F64.bits(V.m_g(m)), w6),
                  Bool.and(U64.is_eq(F64.bits(V.m_h(m)), w7),
                    U64.is_eq(F64.bits(V.m_i(m)), w8))))))))))

def report_m(tag: String, +r: V.CRes, +w0: U64, +w1: U64, +w2: U64,
    +w3: U64, +w4: U64, +w5: U64, +w6: U64, +w7: U64, +w8: U64,
    f: U64) -> IO(U64):
  do IO<U64>:
    IO.print(tag ++ " " ++ verdict(m_as(r, w0, w1, w2, w3, w4, w5, w6,
      w7, w8)) ++ " [" ++ V.cres_show(r) ++ "]")
    return bump(f, m_as(r, w0, w1, w2, w3, w4, w5, w6, w7, w8))

# --- Shared fixtures ---
def v340() -> V.Vec3:
  V.V3{3.0f64, 4.0f64, 0.0f64}

def v000() -> V.Vec3:
  V.V3{0.0f64, 0.0f64, 0.0f64}

def pt123() -> V.Point:
  V.Pt{1.0f64, 2.0f64, 3.0f64}

def rz90() -> V.Rigid:
  V.Rg{V.M3{0.0f64, F64.neg(1.0f64), 0.0f64, 1.0f64, 0.0f64, 0.0f64,
    0.0f64, 0.0f64, 1.0f64}, 5.0f64, 6.0f64, 7.0f64}

def fr_ident() -> V.Frame:
  O.fr_of_rigid(O.rg_ident())
