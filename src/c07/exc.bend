import Base
import ../base/ex.bend as E

type He is Data:
  He{ e: E.Ex, err: F64 }

def rev_go(xs: List<&2, F64>, acc: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: acc
    case x <> t: rev_go(t, x <> acc)

def p1(xs: List<&2, F64>, +q: F64, +acc: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: q <> acc
    case x <> t:
      +r = E.two_sum(q, x)
      +lo = E.tw_lo(r)
      +hi = E.tw_hi(r)
      +z = F64.is_eq(lo, 0.0f64)
      p1(t, Bool.pick(F64, z, hi, lo), Bool.pick(List<&2, F64>, z, acc, hi <> acc))

def p2(xs: List<&2, F64>, +q: F64) -> List<&2, F64>:
  match xs:
    case []: E.keep(q, [])
    case g <> t:
      +r = E.two_sum(g, q)
      E.keep(E.tw_lo(r), p2(t, E.tw_hi(r)))

def pass1(xs: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: []
    case x <> t: p1(t, x, [])

def pass2(xs: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: []
    case x <> t: p2(t, x)

def compress(e: E.Ex) -> E.Ex:
  E.Ex{ok, cs} = e
  E.Ex{ok, pass2(pass1(rev_go(cs, [])))}

def lastc(xs: List<&2, F64>, +d: F64) -> F64:
  match xs:
    case []: d
    case x <> t: lastc(t, x)

def tr_go(xs: List<&2, F64>, +cut: F64, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> t: tr_go(t, cut, Bool.pick(F64, F64.is_lt(F64.abs(x), cut), E.f64_next_up(F64.add(acc, F64.abs(x))), acc))

def keep_big(xs: List<&2, F64>, +cut: F64) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> t:
      +r = keep_big(t, cut)
      Bool.pick(List<&2, F64>, F64.is_lt(F64.abs(x), cut), r, x <> r)

def trunc_go(c: E.Ex, +err: F64) -> He:
  E.Ex{ok, +cs} = c
  +cut = F64.mul(F64.abs(lastc(cs, 0.0f64)), 6.223015277861142e-61f64)
  He{E.Ex{ok, keep_big(cs, cut)}, E.f64_next_up(F64.add(err, tr_go(cs, cut, 0.0f64)))}

def trunc(+e: E.Ex, +err: F64) -> He:
  trunc_go(compress(e), err)

def he_step(+c: E.Ex, h: He, +t: F64) -> He:
  He{e, err} = h
  trunc(E.ex_add(c, E.ex_scale(e, t)), E.f64_next_up(F64.mul(err, F64.abs(t))))

def he_ok(h: He) -> Bool:
  He{e, err} = h
  E.ex_ok(e)
