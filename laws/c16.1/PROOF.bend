import Base
import ../../src/c06/xp.bend as X
import ../../src/c16/sheet.bend as SH
import ./LAWS.bend as Laws

def Laws.sh_loop_closed(p, l, t, r, lh, mx, my):
  match p:
    case SH.K0{}: {==}
    case SH.K1{}: {==}
    case SH.K2{}: {==}
    case SH.K3{}: {==}
    case SH.K4{}: {==}
    case SH.K5{}: {==}
    case SH.K6{}: {==}
    case SH.K7{}: {==}
    case SH.K8{}: {==}
    case SH.K9{}: {==}
    case SH.K10{}: {==}
    case SH.K11{}: {==}

def Laws.sh_rot_len(ps, mx, my):
  match ps:
    case []:
      {==}
    case +h <> t:
      %Laws.sh_rot_len(t, mx, my) : {List.length(&2, SH.P2, SH.pts_rot_go(h, mx, my) <> SH.pts_rot(t, mx, my)) == Nat.add(1n, _) : Nat}
      {==}

def Laws.flat_rows_len(bs, th, klo, khi, i):
  match bs:
    case []:
      {==}
    case +h <> t:
      %Laws.flat_rows_len(t, th, klo, khi, Nat.add(i, 1n)) : {List.length(&2, SH.FR, SH.flat_row(i, h, th, klo, khi) <> SH.rows_go(t, th, klo, khi, Nat.add(i, 1n))) == Nat.add(1n, _) : Nat}
      {==}

def Laws.flat_rows_nil(t, klo, khi):
  {==}

def Laws.flat_legs_flat(l, w, t):
  {==}

def Laws.base_go_false(nf):
  {==}

def Laws.fin_go_false(l, w, t, r, lh):
  {==}

def Laws.ang_go_false(d):
  {==}

def Laws.edge_go_false(n):
  {==}

def Laws.rt_go_false(r, t):
  {==}

def Laws.size_go_false(l, ro):
  {==}

def Laws.len_go_false(lh, leg):
  {==}

def Laws.k_go_false(klo, khi):
  {==}

def Laws.gram_bad_base(nf):
  {==}

def Laws.gram_bad_edge(nf):
  {==}
