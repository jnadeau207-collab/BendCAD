import Base
import ../../src/c04/types.bend as Ty
import ../../src/c06/build.bend as BD
import ../../src/c06/model.bend as M
import ../../src/c06/revolve.bend as RV
import ../../src/c06/xp.bend as X
import ../../src/c09/feat.bend as F9
import ../../src/c16/surf.bend as SU
import ./LAWS.bend as Laws

def Laws.loft_open_shell(fr):
  match fr:
    case F9.FR{x0, y0, x1, y1, u0, v0, u1, v1, z, nd}:
      {==}

def Laws.swo_open_shell(s, q, nd):
  match s:
    case SU.SWO{deg, r0, r1, z0, z1}:
      match q:
        case SU.Q1{}:
          {==}
        case SU.Q2{}:
          {==}
        case SU.Q3{}:
          {==}

def Laws.patch_open_shell(p, nd):
  match p:
    case SU.PP{p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23, p30, p31, p32, p33}:
      {==}

def Laws.thicken_slab_closed(p, t, nd):
  match p:
    case SU.PP{p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23, p30, p31, p32, p33}:
      {==}

def Laws.thicken_duct_closed(d, nd):
  match d:
    case SU.DD{ox0, oy0, ox1, oy1, ou0, ov0, ou1, ov1, ix0, iy0, ix1, iy1, iu0, iv0, iu1, iv1, z}:
      {==}

def Laws.thicken_sec_closed(d, q, nd):
  match d:
    case SU.SD{r0o, r1o, z0o, z1o, r0i, r1i, z0i, z1i}:
      match q:
        case SU.Q1{}:
          {==}
        case SU.Q2{}:
          {==}
        case SU.Q3{}:
          {==}

def Laws.surf_rows_len(bs, i):
  match bs:
    case []:
      {==}
    case +h <> t:
      %Laws.surf_rows_len(t, Nat.add(i, 1n)) : {List.length(&2, SU.BR, SU.bnd_row(i, h) <> SU.bnd_rows(t, Nat.add(i, 1n))) == Nat.add(1n, _) : Nat}
      {==}

def Laws.surf_rows_nil(i):
  {==}

def Laws.sweep_angle_refused(rs, g, gd, tw, e, nd):
  {==}

def Laws.patch_degenerate_refused(e, nd):
  {==}

def Laws.surf_needs_open_refused(x, y, z, it, e):
  {==}

def Laws.thicken_needs_open_refused(x, y, z, it, b, e, nd):
  {==}

def Laws.thicken_thickness_refused(ps, it, b, e, nd):
  {==}
