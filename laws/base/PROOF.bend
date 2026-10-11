import Base
import ../../src/base/par.bend as P
import ../../src/base/ex.bend as E
import ../lib/Ex.bend as LE
import ./LAWS.bend as Laws

def Laws.split_rejoins(A, xs, k, z):
  match xs z:
    case [] True{}:
      {==}
    case [] False{}:
      {==}
    case h <> t True{}:
      {==}
    case +h <> t False{}:
      %Laws.split_rejoins(A, t, (k - 1 : U32), U32.is_eq(k, 1)) : {h <> List.append(&2, A, P.take_u(A, t, (k - 1 : U32), U32.is_eq(k, 1)), P.drop_u(A, t, (k - 1 : U32), U32.is_eq(k, 1))) == h <> _ : List<&2, A>}
      {==}

def seq_app(~A: Data, ~C: Data, ~B: Data, ~f: C -> A -> B, +c: C, +xs: List<&2, A>, +ys: List<&2, A>) -> {List.append(&2, B, P.pmc_seq(~A, ~C, ~B, ~f, c, xs), P.pmc_seq(~A, ~C, ~B, ~f, c, ys)) == P.pmc_seq(~A, ~C, ~B, ~f, c, List.append(&2, A, xs, ys)) : List<&2, B>}:
  match xs:
    case []:
      {==}
    case +h <> t:
      %seq_app(~A, ~C, ~B, ~f, c, t, ys) : {f(c, h) <> List.append(&2, B, P.pmc_seq(~A, ~C, ~B, ~f, c, t), P.pmc_seq(~A, ~C, ~B, ~f, c, ys)) == f(c, h) <> _ : List<&2, B>}
      {==}

def pmc_eq(~A: Data, ~C: Data, ~B: Data, ~f: C -> A -> B, d: Nat, small: Bool, +g: U32, +n: U32, +c: C, +xs: List<&2, A>) -> {P.pmc(~A, ~C, ~B, ~f, d, small, g, n, c, xs) == P.pmc_seq(~A, ~C, ~B, ~f, c, xs) : List<&2, B>}:
  match d:
    case 0n:
      {==}
    case 1n+(+e):
      match small:
        case True{}:
          {==}
        case False{}:
          %Laws.split_rejoins(A, xs, U32.shr(n), U32.is_eq(U32.shr(n), 0)) : {P.pmc(~A, ~C, ~B, ~f, 1n+e, False{}, g, n, c, xs) == P.pmc_seq(~A, ~C, ~B, ~f, c, _) : List<&2, B>}
          %seq_app(~A, ~C, ~B, ~f, c, P.take_u(A, xs, U32.shr(n), U32.is_eq(U32.shr(n), 0)), P.drop_u(A, xs, U32.shr(n), U32.is_eq(U32.shr(n), 0))) : {P.pmc(~A, ~C, ~B, ~f, 1n+e, False{}, g, n, c, xs) == _ : List<&2, B>}
          %pmc_eq(~A, ~C, ~B, ~f, e, U32.is_lt(U32.shr(n), g), g, U32.shr(n), c, P.take_u(A, xs, U32.shr(n), U32.is_eq(U32.shr(n), 0))) : {P.pmc(~A, ~C, ~B, ~f, 1n+e, False{}, g, n, c, xs) == List.append(&2, B, _, P.pmc_seq(~A, ~C, ~B, ~f, c, P.drop_u(A, xs, U32.shr(n), U32.is_eq(U32.shr(n), 0)))) : List<&2, B>}
          %pmc_eq(~A, ~C, ~B, ~f, e, U32.is_lt(U32.sub(n, U32.shr(n)), g), g, U32.sub(n, U32.shr(n)), c, P.drop_u(A, xs, U32.shr(n), U32.is_eq(U32.shr(n), 0))) : {P.pmc(~A, ~C, ~B, ~f, 1n+e, False{}, g, n, c, xs) == List.append(&2, B, P.pmc(~A, ~C, ~B, ~f, e, U32.is_lt(U32.shr(n), g), g, U32.shr(n), c, P.take_u(A, xs, U32.shr(n), U32.is_eq(U32.shr(n), 0))), _) : List<&2, B>}
          {==}

def sc_seq(+tp: P.Tb<&2, U32>, ps: List<&2, U32>) -> {P.pmc_seq(~U32, ~P.Tb<&2, U32>, ~U32, ~P.sc_step, tp, ps) == Laws.smap(tp, ps) : List<&2, U32>}:
  match ps:
    case []:
      {==}
    case +p <> t:
      %sc_seq(tp, t) : {P.tb_get(U32, tp, p) <> P.pmc_seq(~U32, ~P.Tb<&2, U32>, ~U32, ~P.sc_step, tp, t) == P.tb_get(U32, tp, p) <> _ : List<&2, U32>}
      {==}

def Laws.pmap_shortcut_is_map(tp, ps):
  %sc_seq(tp, ps) : {P.pmap(~U32, ~P.Tb<&2, U32>, ~U32, ~P.sc_step, tp, ps) == _ : List<&2, U32>}
  pmc_eq(~U32, ~P.Tb<&2, U32>, ~U32, ~P.sc_step, 40n, U32.is_lt(P.ulen(U32, ps), 128), 128, P.ulen(U32, ps), tp, ps)

def hk_seq(+tp: P.Tb<&2, U32>, es: List<&2, P.Ed>) -> {P.pmc_seq(~P.Ed, ~P.Tb<&2, U32>, ~P.HK, ~P.hk_of, tp, es) == Laws.hmap(tp, es) : List<&2, P.HK>}:
  match es:
    case []:
      {==}
    case +e <> t:
      %hk_seq(tp, t) : {P.hk_of(tp, e) <> P.pmc_seq(~P.Ed, ~P.Tb<&2, U32>, ~P.HK, ~P.hk_of, tp, t) == P.hk_of(tp, e) <> _ : List<&2, P.HK>}
      {==}

def Laws.pmap_hooks_is_map(tp, es):
  %hk_seq(tp, es) : {P.pmap(~P.Ed, ~P.Tb<&2, U32>, ~P.HK, ~P.hk_of, tp, es) == _ : List<&2, P.HK>}
  pmc_eq(~P.Ed, ~P.Tb<&2, U32>, ~P.HK, ~P.hk_of, 40n, U32.is_lt(P.ulen(P.Ed, es), 128), 128, P.ulen(P.Ed, es), tp, es)

def tr_rw(-A: Data, +t: P.Tr<&2, A>, +n: U32, +i: U32, +x: A, z: Bool) -> {P.tr_go(A, P.tr_set(A, t, n, i, x, z), n, i, z) == x : A}:
  match t z:
    case P.TL{v} True{}:
      {==}
    case P.TL{v} False{}:
      {==}
    case P.TN{l, r} True{}:
      tr_rw(A, l, U32.shr(n), i, x, U32.is_lt(i, U32.shr(U32.shr(n))))
    case P.TN{l, r} False{}:
      tr_rw(A, r, U32.shr(n), U32.sub(i, U32.shr(n)), x, U32.is_lt(U32.sub(i, U32.shr(n)), U32.shr(U32.shr(n))))

def Laws.table_read_after_write(A, tb, i, x):
  match tb:
    case P.Tb{+n, t}:
      tr_rw(A, t, n, i, x, U32.is_lt(i, U32.shr(n)))

def Laws.hooks_kept_are_valid(xs):
  match xs:
    case []:
      {==}
    case h <> t:
      match h:
        case P.HK{ok, hi, lo}:
          match ok:
            case True{}:
              Laws.hooks_kept_are_valid(t)
            case False{}:
              Laws.hooks_kept_are_valid(t)

def Laws.ex_neg_involution(e):
  LE.ex_neg_inv(e)

def Laws.ex_uncertain_dominates(cs):
  {==}

def Laws.ex_neg_keeps_ok(ok, cs):
  {==}

def Laws.ex_add_taints(a, cs):
  {==}

def Laws.ex_mul_taints(a, cs):
  {==}

def Laws.sgn_neg_invol(s):
  match s:
    case P.Sn{}: {==}
    case P.Sz{}: {==}
    case P.Sp{}: {==}
    case P.Su{}: {==}

def Laws.sgn_is_refl(s):
  match s:
    case P.Sn{}: {==}
    case P.Sz{}: {==}
    case P.Sp{}: {==}
    case P.Su{}: {==}

def Laws.sgn_neg_of_neg(b):
  match b:
    case True{}: {==}
    case False{}: {==}
