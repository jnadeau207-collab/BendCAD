import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c06/build.bend as BD
import ../../src/c06/model.bend as M
import ../../src/c06/xp.bend as X
import ../../src/c16/blade.bend as BA
import ./LAWS.bend as Laws

def Laws.naca_loop_closed(q):
  match q:
    case BA.Q17{}:
      {==}
    case BA.Q33{}:
      {==}
    case BA.Q65{}:
      {==}

def Laws.blade_n_closed(w):
  match w:
    case Laws.S2{}:
      {==}
    case Laws.S3{}:
      {==}

def Laws.blade_m_closed(q):
  match q:
    case Laws.S8{}:
      {==}
    case Laws.S16{}:
      {==}

def Laws.ring_segs_len(m, left, j):
  match left:
    case 0n:
      {==}
    case 1n+k:
      %Laws.ring_segs_len(m, k, Nat.add(j, 1n)) : {List.length(&2, BA.Sg, BA.ring_seg(m, j) <> BA.ring_segs_go(m, k, Nat.add(j, 1n))) == Nat.add(1n, _) : Nat}
      {==}

def Laws.walls_len(n, m, left, w):
  match left:
    case 0n:
      {==}
    case 1n+k:
      %Laws.walls_len(n, m, k, Nat.add(w, 1n)) : {List.length(&2, List<&2, BA.Ub>, BA.wall_loop(n, m, Nat.div(w, m), Nat.mod(w, m)) <> BA.walls_flat_go(n, m, k, Nat.add(w, 1n))) == Nat.add(1n, _) : Nat}
      {==}

def Laws.blade_rows_len(ses, m, i):
  match ses:
    case []:
      {==}
    case +h <> t:
      %Laws.blade_rows_len(t, m, Nat.add(i, 1n)) : {List.length(&2, BA.BR, BA.sec_row(i, h, m) <> BA.blade_rows_go(t, m, Nat.add(i, 1n))) == Nat.add(1n, _) : Nat}
      {==}

def Laws.blade_rows_nil(m, i):
  {==}

def Laws.blade_sections_refused(s0, s1, s2, s3, s4, s5, s6, s7, s8, z, tw, tp, e, nd, ns):
  {==}

def Laws.blade_twist_refused(s0, s1, z, tp, e, nd, ns):
  {==}

def Laws.blade_taper_refused(s0, s1, z, e, nd, ns):
  {==}

def Laws.naca_digits_refused(p, t, c, n, e, nd):
  {==}

def Laws.naca_points_refused(e, nd):
  {==}

def Laws.blade_span_refused(s0, s1, e, nd, ns):
  {==}

def Laws.blade_ruled_refused(x0, y0, z0, it0, x1, y1, z1, it1, e, nd):
  {==}

def Laws.blade_needs_blade_refused(x, y, z, it, e):
  {==}
