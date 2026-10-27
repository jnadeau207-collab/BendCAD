import Base
import ../../src/c01/types.bend as V
import ../../src/k3/fem.bend as F
import ../../src/k3/mesh.bend as K
import ./LAWS.bend as Laws

def prb_go(t: Bool, +a: Nat, +b: Nat, +c: Nat, +d: Nat, +e: Nat, +f: Nat, +acc: List<&2, K.T4>) -> {List.length(&2, K.T4, Bool.pick(List<&2, K.T4>, t, K.T4{a, b, c, f} <> K.T4{a, b, f, e} <> K.T4{a, e, f, d} <> acc, K.T4{a, b, c, e} <> K.T4{a, e, c, f} <> K.T4{a, e, f, d} <> acc)) == 1n+(1n+(1n+List.length(&2, K.T4, acc))) : Nat}:
  match t:
    case True{}: {==}
    case False{}: {==}

def prb3(+a: Nat, +b: Nat, +c: Nat, +d: Nat, +e: Nat, +f: Nat, +acc: List<&2, K.T4>) -> {List.length(&2, K.T4, K.pr_b(a, b, c, d, e, f, acc)) == 1n+(1n+(1n+List.length(&2, K.T4, acc))) : Nat}:
  prb_go(Nat.is_lt(Nat.min(b, f), Nat.min(c, e)), a, b, c, d, e, f, acc)

def pra_go(t: Bool, +a: Nat, +b: Nat, +c: Nat, +d: Nat, +e: Nat, +f: Nat, +acc: List<&2, K.T4>) -> {List.length(&2, K.T4, Bool.pick(List<&2, K.T4>, t, K.pr_b(d, e, f, a, b, c, acc), K.pr_b(a, b, c, d, e, f, acc))) == 1n+(1n+(1n+List.length(&2, K.T4, acc))) : Nat}:
  match t:
    case True{}: prb3(d, e, f, a, b, c, acc)
    case False{}: prb3(a, b, c, d, e, f, acc)

def pra3(+a: Nat, +b: Nat, +c: Nat, +d: Nat, +e: Nat, +f: Nat, +acc: List<&2, K.T4>) -> {List.length(&2, K.T4, K.pr_a(a, b, c, d, e, f, acc)) == 1n+(1n+(1n+List.length(&2, K.T4, acc))) : Nat}:
  pra_go(Nat.is_lt(d, a), a, b, c, d, e, f, acc)

def prism_go(t: Bool, u: Bool, +a: Nat, +b: Nat, +c: Nat, +d: Nat, +e: Nat, +f: Nat, +acc: List<&2, K.T4>) -> {List.length(&2, K.T4, Bool.pick(List<&2, K.T4>, t, K.pr_a(a, b, c, d, e, f, acc), Bool.pick(List<&2, K.T4>, u, K.pr_a(b, c, a, e, f, d, acc), K.pr_a(c, a, b, f, d, e, acc)))) == 1n+(1n+(1n+List.length(&2, K.T4, acc))) : Nat}:
  match t:
    case True{}: pra3(a, b, c, d, e, f, acc)
    case False{}:
      match u:
        case True{}: pra3(b, c, a, e, f, d, acc)
        case False{}: pra3(c, a, b, f, d, e, acc)

def pyr_go(t: Bool, +q0: Nat, +q1: Nat, +q2: Nat, +q3: Nat, +p: Nat, +acc: List<&2, K.T4>) -> {List.length(&2, K.T4, Bool.pick(List<&2, K.T4>, t, K.T4{q0, q1, q2, p} <> K.T4{q0, q2, q3, p} <> acc, K.T4{q1, q2, q3, p} <> K.T4{q1, q3, q0, p} <> acc)) == 1n+(1n+List.length(&2, K.T4, acc)) : Nat}:
  match t:
    case True{}: {==}
    case False{}: {==}

def Laws.transpose_keeps_rows(n, cs):
  match n:
    case 0n: {==}
    case 1n+m:
      %Laws.transpose_keeps_rows(m, F.tls(cs)) : {1n+List.length(&2, List<&2, V.Dir>, F.tcol(m, F.tls(cs))) == 1n+_ : Nat}
      {==}

def Laws.transpose_keeps_rows_f64(n, cs):
  match n:
    case 0n: {==}
    case 1n+m:
      %Laws.transpose_keeps_rows_f64(m, F.tlf(cs)) : {1n+List.length(&2, List<&2, F64>, F.tcolf(m, F.tlf(cs))) == 1n+_ : Nat}
      {==}

def Laws.pyramid_splits_into_two(q0, q1, q2, q3, p, acc):
  pyr_go(Bool.or(Nat.is_eq(K.mn4(q0, q1, q2, q3), q0), Nat.is_eq(K.mn4(q0, q1, q2, q3), q2)), q0, q1, q2, q3, p, acc)

def Laws.prism_splits_into_three(a, b, c, d, e, f, acc):
  prism_go(Bool.or(Nat.is_eq(K.mn6n(a, b, c, d, e, f), a), Nat.is_eq(K.mn6n(a, b, c, d, e, f), d)),
    Bool.or(Nat.is_eq(K.mn6n(a, b, c, d, e, f), b), Nat.is_eq(K.mn6n(a, b, c, d, e, f), e)), a, b, c, d, e, f, acc)

def Laws.revert_keeps_unflagged(ms, ls, i):
  match ms:
    case []: {==}
    case m <> r:
      %Laws.revert_keeps_unflagged(r, K.p_tl(ls), Nat.add(i, 1n)) : {m <> K.revert(r, K.p_tl(ls), [], Nat.add(i, 1n)) == m <> _ : List<&2, V.Point>}
      {==}

def Laws.revert_keeps_length(ms, ls, bad, i):
  match ms:
    case []: {==}
    case m <> r:
      %Laws.revert_keeps_length(r, K.p_tl(ls), Bool.pick(List<&2, Nat>, Bool.and(Bool.not(K.n_nil(bad)), Nat.is_eq(K.n_hd(bad), i)), K.n_tl(bad), bad), Nat.add(i, 1n)) : {1n+List.length(&2, V.Point, K.revert(r, K.p_tl(ls), Bool.pick(List<&2, Nat>, Bool.and(Bool.not(K.n_nil(bad)), Nat.is_eq(K.n_hd(bad), i)), K.n_tl(bad), bad), Nat.add(i, 1n))) == 1n+_ : Nat}
      {==}

def Laws.snap_keeps_length(ps, vs, i):
  match ps:
    case []: {==}
    case p <> r:
      %Laws.snap_keeps_length(r, Bool.pick(List<&2, K.VT>, Bool.and(Bool.not(K.vt_nil(vs)), Nat.is_eq(K.vt_v(K.vt_hd(vs)), i)), K.vt_tl(vs), vs), Nat.add(i, 1n)) : {1n+List.length(&2, V.Point, K.place(r, Bool.pick(List<&2, K.VT>, Bool.and(Bool.not(K.vt_nil(vs)), Nat.is_eq(K.vt_v(K.vt_hd(vs)), i)), K.vt_tl(vs), vs), Nat.add(i, 1n))) == 1n+_ : Nat}
      {==}
