import Base
import ../../src/c03/types.bend as G
import ../../src/c06/model.bend as M
import ../../src/c06/tess.bend as TS
import ../../src/c10/mesh.bend as M10

def nmin(a: Nat, b: Nat) -> Nat:
  match a:
    case 0n: 0n
    case 1n+x:
      match b:
        case 0n: 0n
        case 1n+y: 1n+nmin(x, y)

def two(n: Nat) -> Nat:
  match n:
    case 0n: 0n
    case 1n+m: 1n+(1n+two(m))

def all_lt(xs: List<&2, Nat>, +lim: Nat) -> Bool:
  match xs:
    case []: True{}
    case x <> t: Bool.and(Nat.is_lt(x, lim), all_lt(t, lim))

law q_mk_chord:
  for +c: F64
  for +a: F64
  for +m: Nat
  for +p: U64
  {M10.q_chord(M10.q_mk(c, a, m, p)) == c : F64}

law q_mk_angle:
  for +c: F64
  for +a: F64
  for +m: Nat
  for +p: U64
  {M10.q_angle(M10.q_mk(c, a, m, p)) == a : F64}

law q_mk_max:
  for +c: F64
  for +a: F64
  for +m: Nat
  for +p: U64
  {M10.q_max(M10.q_mk(c, a, m, p)) == m : Nat}

law q_mk_prof:
  for +c: F64
  for +a: F64
  for +m: Nat
  for +p: U64
  {M10.q_prof(M10.q_mk(c, a, m, p)) == p : U64}

law tres_ok_true:
  for +o: String
  for +nv: Nat
  for +nt: Nat
  for +est: Nat
  for +ch: F64
  for +an: F64
  for +ns: Nat
  {M10.tres_ok_of(M10.tres_ok(o, nv, nt, est, ch, an, ns)) == True{} : Bool}

law tres_fail_false:
  for +w: String
  {M10.tres_ok_of(M10.tres_fail(w)) == False{} : Bool}

law prism_over_budget_refuses:
  for +b: M.Body
  for +q: M10.Q
  for +e: Nat
  {M10.tres_ok_of(TS.pri_go(False{}, b, q, e)) == False{} : Bool}

law prism_refusal_keeps_estimate:
  for +b: M.Body
  for +q: M10.Q
  for +e: Nat
  {M10.tres_est(TS.pri_go(False{}, b, q, e)) == e : Nat}

law lathe_over_budget_refuses:
  for +b: M.Body
  for +q: M10.Q
  for +e: Nat
  {M10.tres_ok_of(TS.rev_go(False{}, b, q, e)) == False{} : Bool}

law lathe_refusal_keeps_estimate:
  for +b: M.Body
  for +q: M10.Q
  for +e: Nat
  {M10.tres_est(TS.rev_go(False{}, b, q, e)) == e : Nat}

law strip_tri_count:
  for +bs: List<&2, Nat>
  for +ts: List<&2, Nat>
  for +b0: Nat
  for +t0: Nat
  {List.length(&2, TS.Tri, TS.strip_go(bs, ts, b0, t0)) == two(nmin(List.length(&2, Nat, bs), List.length(&2, Nat, ts))) : Nat}

law strip_estimate_exact:
  for +n: Nat
  {M10.tri_est_strip(n) == two(n) : Nat}

law ring_seq_len:
  for +n: Nat
  for +b: Nat
  {List.length(&2, Nat, TS.n_seq(n, b)) == n : Nat}

law ring_rep_len:
  for +n: Nat
  for +b: Nat
  {List.length(&2, Nat, TS.n_rep(n, b)) == n : Nat}

law ring_seq_in_range:
  for +n: Nat
  for +b: Nat
  {all_lt(TS.n_seq(n, b), Nat.add(b, n)) == True{} : Bool}

law segs_min_line:
  for +l: G.Line3
  for +d: G.Dom
  {M10.segs_min(G.GV_ln{l}, d) == 1n : Nat}

law segs_min_rq:
  for +w: G.RQBez
  for +d: G.Dom
  {M10.segs_min(G.GV_rq{w}, d) == 1n : Nat}

law segs_min_bz:
  for +w: G.Bez3
  for +d: G.Dom
  {M10.segs_min(G.GV_bz{w}, d) == 1n : Nat}
