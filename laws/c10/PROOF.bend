import Base
import ../../src/c03/types.bend as G
import ../../src/c06/model.bend as M
import ../../src/c06/tess.bend as TS
import ../../src/c10/mesh.bend as M10
import ./LAWS.bend as Laws

def add_zero(n: Nat) -> {Nat.add(n, 0n) == n : Nat}:
  match n:
    case 0n: {==}
    case 1n+m:
      %add_zero(m) : {1n+Nat.add(m, 0n) == 1n+_ : Nat}
      {==}

def add_succ(a: Nat, +b: Nat) -> {Nat.add(a, 1n+b) == 1n+Nat.add(a, b) : Nat}:
  match a:
    case 0n: {==}
    case 1n+p:
      %add_succ(p, b) : {1n+Nat.add(p, 1n+b) == 1n+_ : Nat}
      {==}

def add_one_assoc(b: Nat, +m: Nat) -> {Nat.add(Nat.add(b, 1n), m) == Nat.add(b, 1n+m) : Nat}:
  match b:
    case 0n: {==}
    case 1n+p:
      %add_one_assoc(p, m) : {1n+Nat.add(Nat.add(p, 1n), m) == 1n+_ : Nat}
      {==}

def lt_add_succ(b: Nat, +m: Nat) -> {Nat.is_lt(b, Nat.add(b, 1n+m)) == True{} : Bool}:
  match b:
    case 0n: {==}
    case 1n+p:
      %lt_add_succ(p, m) : {Nat.is_lt(p, Nat.add(p, 1n+m)) == _ : Bool}
      {==}

def Laws.q_mk_chord(c, a, m, p):
  {==}

def Laws.q_mk_angle(c, a, m, p):
  {==}

def Laws.q_mk_max(c, a, m, p):
  {==}

def Laws.q_mk_prof(c, a, m, p):
  {==}

def Laws.tres_ok_true(o, nv, nt, est, ch, an, ns):
  {==}

def Laws.tres_fail_false(w):
  {==}

def Laws.prism_over_budget_refuses(b, q, e):
  {==}

def Laws.prism_refusal_keeps_estimate(b, q, e):
  {==}

def Laws.lathe_over_budget_refuses(b, q, e):
  {==}

def Laws.lathe_refusal_keeps_estimate(b, q, e):
  {==}

def Laws.strip_tri_count(bs, ts, b0, t0):
  match bs:
    case []: {==}
    case b <> bt:
      match ts:
        case []: {==}
        case t <> tt:
          %Laws.strip_tri_count(bt, tt, b0, t0) : {1n+(1n+List.length(&2, TS.Tri, TS.strip_go(bt, tt, b0, t0))) == 1n+(1n+_) : Nat}
          {==}

def Laws.strip_estimate_exact(n):
  match n:
    case 0n: {==}
    case 1n+m:
      %Laws.strip_estimate_exact(m) : {1n+Nat.add(m, 1n+Nat.add(m, 0n)) == 1n+(1n+_) : Nat}
      %add_succ(m, Nat.add(m, 0n)) : {1n+Nat.add(m, 1n+Nat.add(m, 0n)) == 1n+_ : Nat}
      {==}

def Laws.ring_seq_len(n, b):
  match n:
    case 0n: {==}
    case 1n+m:
      %Laws.ring_seq_len(m, Nat.add(b, 1n)) : {1n+List.length(&2, Nat, TS.n_seq(m, Nat.add(b, 1n))) == 1n+_ : Nat}
      {==}

def Laws.ring_rep_len(n, b):
  match n:
    case 0n: {==}
    case 1n+m:
      %Laws.ring_rep_len(m, b) : {1n+List.length(&2, Nat, TS.n_rep(m, b)) == 1n+_ : Nat}
      {==}

def Laws.ring_seq_in_range(n, b):
  match n:
    case 0n: {==}
    case 1n+m:
      %Equal.sym(Bool, Nat.is_lt(b, Nat.add(b, 1n+m)), True{}, lt_add_succ(b, m)) : {Bool.and(_, Laws.all_lt(TS.n_seq(m, Nat.add(b, 1n)), Nat.add(b, 1n+m))) == True{} : Bool}
      %add_one_assoc(b, m) : {Laws.all_lt(TS.n_seq(m, Nat.add(b, 1n)), _) == True{} : Bool}
      %Laws.ring_seq_in_range(m, Nat.add(b, 1n)) : {Laws.all_lt(TS.n_seq(m, Nat.add(b, 1n)), Nat.add(Nat.add(b, 1n), m)) == _ : Bool}
      {==}

def Laws.segs_min_line(l, d):
  {==}

def Laws.segs_min_rq(w, d):
  {==}

def Laws.segs_min_bz(w, d):
  {==}
