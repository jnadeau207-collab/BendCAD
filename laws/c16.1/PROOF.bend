import Base
import ../../src/c06/model.bend as M
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

def Laws.bend_base_refused(base, b, e, nd):
  {==}

def Laws.bend_fin_refused(n, deg, it, b, e, nd):
  {==}

def Laws.bend_angle_refused(n, it, b, e, nd):
  {==}

def Laws.bend_edge_refused(it, b, e, nd):
  {==}

def Laws.hem_len_refused(it, b, e, nd):
  {==}

def Laws.flat_kzone_refused(sc, e, id):
  {==}
