import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c02/types.bend as P
import ../../src/c02/ops.bend as O
import ./LAWS.bend as Laws

def Laws.tri_winding_invariant(s1, s2, s3, o):
  match s1 s2 s3 o:
    case P.Sg_neg{} P.Sg_neg{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_neg{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_neg{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_neg{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_neg{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_neg{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_zero{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_zero{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_zero{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_zero{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_zero{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_zero{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_pos{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_pos{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_pos{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_pos{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_pos{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_pos{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_neg{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_neg{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_neg{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_neg{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_neg{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_neg{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_zero{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_zero{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_zero{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_zero{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_zero{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_zero{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_pos{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_pos{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_pos{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_pos{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_pos{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_pos{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_neg{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_neg{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_neg{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_neg{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_neg{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_neg{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_zero{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_zero{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_zero{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_zero{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_zero{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_zero{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_pos{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_pos{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_pos{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_pos{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_pos{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_pos{} P.Sg_pos{} False{}:
      {==}

def Laws.tri_relabel_invariant(s1, s2, s3, o):
  match s1 s2 s3 o:
    case P.Sg_neg{} P.Sg_neg{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_neg{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_neg{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_neg{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_neg{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_neg{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_zero{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_zero{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_zero{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_zero{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_zero{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_zero{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_pos{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_pos{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_pos{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_pos{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_neg{} P.Sg_pos{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_neg{} P.Sg_pos{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_neg{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_neg{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_neg{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_neg{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_neg{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_neg{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_zero{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_zero{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_zero{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_zero{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_zero{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_zero{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_pos{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_pos{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_pos{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_pos{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_zero{} P.Sg_pos{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_zero{} P.Sg_pos{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_neg{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_neg{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_neg{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_neg{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_neg{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_neg{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_zero{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_zero{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_zero{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_zero{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_zero{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_zero{} P.Sg_pos{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_pos{} P.Sg_neg{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_pos{} P.Sg_neg{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_pos{} P.Sg_zero{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_pos{} P.Sg_zero{} False{}:
      {==}
    case P.Sg_pos{} P.Sg_pos{} P.Sg_pos{} True{}:
      {==}
    case P.Sg_pos{} P.Sg_pos{} P.Sg_pos{} False{}:
      {==}

def Laws.tri_mixed_is_outside(s3, o):
  match s3 o:
    case P.Sg_neg{} True{}:
      {==}
    case P.Sg_neg{} False{}:
      {==}
    case P.Sg_zero{} True{}:
      {==}
    case P.Sg_zero{} False{}:
      {==}
    case P.Sg_pos{} True{}:
      {==}
    case P.Sg_pos{} False{}:
      {==}

def Laws.seg_proper_np_pn(ax, ay, bx, by, cx, cy, dx, dy):
  {==}

def Laws.seg_proper_np_np(ax, ay, bx, by, cx, cy, dx, dy):
  {==}

def Laws.seg_proper_pn_pn(ax, ay, bx, by, cx, cy, dx, dy):
  {==}

def Laws.seg_proper_pn_np(ax, ay, bx, by, cx, cy, dx, dy):
  {==}

def Laws.sign_neg_inv(s):
  match s:
    case P.Sg_neg{}:
      {==}
    case P.Sg_zero{}:
      {==}
    case P.Sg_pos{}:
      {==}

def Laws.sign_neg_swaps(s):
  match s:
    case P.Sg_neg{}:
      {==}
    case P.Sg_zero{}:
      {==}
    case P.Sg_pos{}:
      {==}

def Laws.pok_ok(s):
  {==}

def Laws.perr_show(k):
  {==}

def Laws.perr_sign_zero(k):
  {==}

def Laws.xok_ok(x):
  {==}

def Laws.xerr_rel_dis(k):
  {==}

def Laws.tok_ok(c):
  {==}

def Laws.terr_cls_out(k):
  {==}
