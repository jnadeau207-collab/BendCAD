import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c01/ops.bend as O
import ../lib/F64.bend as L
import ./LAWS.bend as Laws

def Laws.neg_involution(x):
  L.neg_inv(x)

def Laws.v3_neg_involution(v):
  match v:
    case V.V3{+x, +y, +z}:
      %L.neg_inv(x) : {V.v3_neg(V.v3_neg(V.V3{x, y, z})) == V.V3{_, y, z} : V.Vec3}
      %L.neg_inv(y) : {V.v3_neg(V.v3_neg(V.V3{x, y, z})) == V.V3{F64.neg(F64.neg(x)), _, z} : V.Vec3}
      %L.neg_inv(z) : {V.v3_neg(V.v3_neg(V.V3{x, y, z})) == V.V3{F64.neg(F64.neg(x)), F64.neg(F64.neg(y)), _} : V.Vec3}
      {==}

def Laws.v2_neg_involution(v):
  match v:
    case V.V2{+x, +y}:
      %L.neg_inv(x) : {V.v2_neg(V.v2_neg(V.V2{x, y})) == V.V2{_, y} : V.Vec2}
      %L.neg_inv(y) : {V.v2_neg(V.v2_neg(V.V2{x, y})) == V.V2{F64.neg(F64.neg(x)), _} : V.Vec2}
      {==}

def Laws.trans_involution(m):
  match m:
    case V.M3{a, b, c, d, e, f, g, h, i}:
      {==}

def Laws.frame_rigid_frame(fr):
  match fr:
    case V.Fr{ox, oy, oz, xx, xy, xz, yx, yy, yz, zx, zy, zz}:
      {==}

def Laws.rigid_frame_rigid(r):
  match r:
    case V.Rg{m, tx, ty, tz}:
      match m:
        case V.M3{a, b, c, d, e, f, g, h, i}:
          {==}

def Laws.cres_ok_ok(v):
  {==}

def Laws.cres_show_err(k):
  {==}

def Laws.cerr_zero_f(k):
  {==}

def Laws.cerr_zero_v3(k):
  {==}
