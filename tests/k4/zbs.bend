import Base
import ../../src/c01/types.bend as V
import ../../src/c03/bsp.bend as Q
import ../../src/k1/sf.bend as S

def circ_go(n: Nat, +k: Nat, +m: Nat) -> List<&2, V.Point>:
  match n:
    case 0n: []
    case 1n+(+j):
      +t = F64.mul(1.5f64, F64.div(Q.nf(k), Q.nf(m)))
      V.Pt{S.fcos(t), S.fsin(t), F64.mul(0.1f64, Q.nf(k))} <> circ_go(j, Nat.add(k, 1n), m)

def err_go(ps: List<&2, V.Point>, us: List<&2, F64>, +c: Q.Bs, +acc: F64) -> F64:
  match ps:
    case []: acc
    case +p <> pt:
      match us:
        case []: acc
        case +u <> ut: err_go(pt, ut, c, F64.max(acc, Q.pdist(p, Q.h_pt(Q.bs_at(c, u)))))

def bz_at(+b: List<&2, Q.H4>, +t: F64) -> Q.H4:
  +s = F64.sub(1.0f64, t)
  Q.h_add(Q.h_add(Q.h_scale(F64.mul(F64.mul(s, s), s), Q.hnth(b, 0n)), Q.h_scale(F64.mul(3.0f64, F64.mul(F64.mul(s, s), t)), Q.hnth(b, 1n))),
    Q.h_add(Q.h_scale(F64.mul(3.0f64, F64.mul(s, F64.mul(t, t))), Q.hnth(b, 2n)), Q.h_scale(F64.mul(F64.mul(t, t), t), Q.hnth(b, 3n))))

def bez_err(ix: List<&2, Nat>, bs: List<&2, List<&2, Q.H4>>, +c: Q.Bs, +acc: F64) -> F64:
  match ix:
    case []: acc
    case +i <> it:
      match bs:
        case []: acc
        case +b <> bt:
          +ks = Q.bs_ks(c)
          +a = Q.fnth(ks, i)
          +e = Q.fnth(ks, Nat.add(i, 1n))
          +um = F64.add(a, F64.mul(0.3f64, F64.sub(e, a)))
          bez_err(it, bt, c, F64.max(acc, Q.pdist(Q.h_pt(bz_at(b, 0.3f64)), Q.h_pt(Q.bs_at(c, um)))))

def main() -> IO(Unit):
  +ps = circ_go(11n, 0n, 10n)
  +us = Q.params(ps)
  +c = Q.interp(us, Q.pts_hs(ps))
  IO.print("interp-err " ++ F64.show(err_go(ps, us, c, 0.0f64)) ++ " spans " ++ Nat.show(List.length(&2, Nat, Q.spans(c)))
    ++ " bez-err " ++ F64.show(bez_err(Q.spans(c), Q.bezs(c), c, 0.0f64)) ++ " mid " ++ F64.show(Q.pdist(Q.h_pt(Q.bs_at(c, 0.5f64)), V.Pt{0.0f64, 0.0f64, 0.5f64})))
