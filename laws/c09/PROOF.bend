import Base
import ../../src/c04/types.bend as Ty
import ../../src/c06/build.bend as BD
import ../../src/c09/feat.bend as F9
import ./LAWS.bend as Laws

def Laws.frustum_closed_solid(fr):
  match fr:
    case F9.FR{x0, y0, x1, y1, u0, v0, u1, v1, z, nd}:
      {==}

def Laws.fillet_closed_solid(fm):
  match fm:
    case F9.FM{x, y, z, r, nd}:
      {==}

def Laws.cone_closed_solid(c):
  match c:
    case F9.CN{e, x, y, h, r0, r1, za, ax, ay, az, k, nd, surf}:
      {==}
