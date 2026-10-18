import Base
import ../../src/c03/types.bend as G
import ../../src/c06/build.bend as BD
import ../../src/c07/mem.bend as Mm
import ../../src/c08/bool.bend as B8
import ../../src/k1/fb.bend as FB
import ./LAWS.bend as Laws

def or6(p1: Bool, p2: Bool, p3: Bool, p4: Bool, p5: Bool, p6: Bool) -> {Bool.or(p1, Bool.or(p2, Bool.or(p3, Bool.or(p4, Bool.or(p5, p6))))) == Bool.or(p2, Bool.or(p1, Bool.or(p4, Bool.or(p3, Bool.or(p6, p5))))) : Bool}:
  match p1 p2 p3 p4 p5 p6:
    case False{} False{} False{} False{} False{} False{}:
      {==}
    case False{} False{} False{} False{} False{} True{}:
      {==}
    case False{} False{} False{} False{} True{} False{}:
      {==}
    case False{} False{} False{} False{} True{} True{}:
      {==}
    case False{} False{} False{} True{} False{} False{}:
      {==}
    case False{} False{} False{} True{} False{} True{}:
      {==}
    case False{} False{} False{} True{} True{} False{}:
      {==}
    case False{} False{} False{} True{} True{} True{}:
      {==}
    case False{} False{} True{} False{} False{} False{}:
      {==}
    case False{} False{} True{} False{} False{} True{}:
      {==}
    case False{} False{} True{} False{} True{} False{}:
      {==}
    case False{} False{} True{} False{} True{} True{}:
      {==}
    case False{} False{} True{} True{} False{} False{}:
      {==}
    case False{} False{} True{} True{} False{} True{}:
      {==}
    case False{} False{} True{} True{} True{} False{}:
      {==}
    case False{} False{} True{} True{} True{} True{}:
      {==}
    case False{} True{} False{} False{} False{} False{}:
      {==}
    case False{} True{} False{} False{} False{} True{}:
      {==}
    case False{} True{} False{} False{} True{} False{}:
      {==}
    case False{} True{} False{} False{} True{} True{}:
      {==}
    case False{} True{} False{} True{} False{} False{}:
      {==}
    case False{} True{} False{} True{} False{} True{}:
      {==}
    case False{} True{} False{} True{} True{} False{}:
      {==}
    case False{} True{} False{} True{} True{} True{}:
      {==}
    case False{} True{} True{} False{} False{} False{}:
      {==}
    case False{} True{} True{} False{} False{} True{}:
      {==}
    case False{} True{} True{} False{} True{} False{}:
      {==}
    case False{} True{} True{} False{} True{} True{}:
      {==}
    case False{} True{} True{} True{} False{} False{}:
      {==}
    case False{} True{} True{} True{} False{} True{}:
      {==}
    case False{} True{} True{} True{} True{} False{}:
      {==}
    case False{} True{} True{} True{} True{} True{}:
      {==}
    case True{} False{} False{} False{} False{} False{}:
      {==}
    case True{} False{} False{} False{} False{} True{}:
      {==}
    case True{} False{} False{} False{} True{} False{}:
      {==}
    case True{} False{} False{} False{} True{} True{}:
      {==}
    case True{} False{} False{} True{} False{} False{}:
      {==}
    case True{} False{} False{} True{} False{} True{}:
      {==}
    case True{} False{} False{} True{} True{} False{}:
      {==}
    case True{} False{} False{} True{} True{} True{}:
      {==}
    case True{} False{} True{} False{} False{} False{}:
      {==}
    case True{} False{} True{} False{} False{} True{}:
      {==}
    case True{} False{} True{} False{} True{} False{}:
      {==}
    case True{} False{} True{} False{} True{} True{}:
      {==}
    case True{} False{} True{} True{} False{} False{}:
      {==}
    case True{} False{} True{} True{} False{} True{}:
      {==}
    case True{} False{} True{} True{} True{} False{}:
      {==}
    case True{} False{} True{} True{} True{} True{}:
      {==}
    case True{} True{} False{} False{} False{} False{}:
      {==}
    case True{} True{} False{} False{} False{} True{}:
      {==}
    case True{} True{} False{} False{} True{} False{}:
      {==}
    case True{} True{} False{} False{} True{} True{}:
      {==}
    case True{} True{} False{} True{} False{} False{}:
      {==}
    case True{} True{} False{} True{} False{} True{}:
      {==}
    case True{} True{} False{} True{} True{} False{}:
      {==}
    case True{} True{} False{} True{} True{} True{}:
      {==}
    case True{} True{} True{} False{} False{} False{}:
      {==}
    case True{} True{} True{} False{} False{} True{}:
      {==}
    case True{} True{} True{} False{} True{} False{}:
      {==}
    case True{} True{} True{} False{} True{} True{}:
      {==}
    case True{} True{} True{} True{} False{} False{}:
      {==}
    case True{} True{} True{} True{} False{} True{}:
      {==}
    case True{} True{} True{} True{} True{} False{}:
      {==}
    case True{} True{} True{} True{} True{} True{}:
      {==}

def Laws.box_disjoint_symmetric(a, b):
  match a b:
    case FB.BB{ax0, ax1, ay0, ay1, az0, az1} FB.BB{bx0, bx1, by0, by1, bz0, bz1}:
      or6(F64.is_lt(ax1, bx0), F64.is_lt(bx1, ax0), F64.is_lt(ay1, by0), F64.is_lt(by1, ay0), F64.is_lt(az1, bz0), F64.is_lt(bz1, az0))

def Laws.exact_faces_keep_path_membership(g, es, slv):
  {==}

def lin_go(xs: List<&2, B8.LK>, all: List<&2, B8.LK>, seen: List<&2, B8.LK>) -> {List.length(&2, BD.Fn, B8.lk_fns(xs, all, seen)) == List.length(&2, B8.LK, xs) : Nat}:
  match xs:
    case []: {==}
    case h <> t:
      %lin_go(t, all, h <> seen) : {1n+List.length(&2, BD.Fn, B8.lk_fns(t, all, h <> seen)) == 1n+_ : Nat}
      {==}

def Laws.lineage_one_name_per_face(xs, all, seen):
  lin_go(xs, all, seen)
