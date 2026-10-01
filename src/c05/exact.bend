import Base
import ../base/par.bend as P
import ../base/ex.bend as E

def orient2(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64,
    +cy: F64) -> E.Ex:
  E.ex_sub(E.ex_mul(E.ex_dif(bx, ax), E.ex_dif(cy, ay)),
    E.ex_mul(E.ex_dif(by, ay), E.ex_dif(cx, ax)))

def err_a() -> F64:
  F64{4375247037990436868u64}

def tiny_sum() -> F64:
  F64{553942754166571008u64}

def sgn_of(+x: F64) -> P.Sgn:
  P.sgn_pick(F64.is_lt(x, 0.0f64), F64.is_lt(0.0f64, x))

def ex_negl_if(e: E.Ex, n: Bool) -> E.Ex:
  match n:
    case True{}: E.ex_neg(e)
    case False{}: e

def dd_exact(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64, +g: F64,
    +h: F64, +pl: Bool) -> P.Sgn:
  +l = E.ex_mul(E.ex_dif(a, b), E.ex_dif(c, d))
  +r = E.ex_mul(E.ex_dif(e, f), E.ex_dif(g, h))
  E.ex_sign(E.ex_add(l, ex_negl_if(r, Bool.not(pl))))

def dd_go(sure: Bool, +det: F64, +a: F64, +b: F64, +c: F64, +d: F64, +e: F64,
    +f: F64, +g: F64, +h: F64, +pl: Bool) -> P.Sgn:
  match sure:
    case True{}: sgn_of(det)
    case False{}: dd_exact(a, b, c, d, e, f, g, h, pl)

def sel_f(c: Bool, +x: F64, +y: F64) -> F64:
  match c:
    case True{}: x
    case False{}: y

def dd_sign(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64, +g: F64,
    +h: F64, +pl: Bool) -> P.Sgn:
  +l = ((a - b : F64) * (c - d : F64) : F64)
  +r = ((e - f : F64) * (g - h : F64) : F64)
  +dt = sel_f(pl, (l + r : F64), (l - r : F64))
  +sum = (F64.abs(l) + F64.abs(r) : F64)
  +sure = Bool.and(Bool.and(E.fin(dt), E.fin(sum)),
    Bool.and(F64.is_le(tiny_sum(), sum), F64.is_lt((2.0f64 * (err_a() * sum : F64) : F64), F64.abs(dt))))
  dd_go(sure, dt, a, b, c, d, e, f, g, h, pl)

def orient2s(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64) -> P.Sgn:
  dd_sign(bx, ax, cy, ay, by, ay, cx, ax, False{})
