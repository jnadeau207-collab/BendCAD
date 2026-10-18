import Base
import ../../src/c03/types.bend as G
import ../../src/c06/build.bend as BD
import ../../src/c07/mem.bend as Mm
import ../../src/c08/bool.bend as B8
import ../../src/k1/fb.bend as FB

law box_disjoint_symmetric:
  for a: FB.BB
  for b: FB.BB
  {FB.bb_dis(a, b) == FB.bb_dis(b, a) : Bool}

law exact_faces_keep_path_membership:
  for g: G.GVal
  for es: List<&2, Mm.Er>
  for slv: F64
  {Mm.uv_has(Mm.uv_of(False{}, g, es, slv)) == False{} : Bool}

law lineage_one_name_per_face:
  for xs: List<&2, B8.LK>
  for all: List<&2, B8.LK>
  for seen: List<&2, B8.LK>
  {List.length(&2, BD.Fn, B8.lk_fns(xs, all, seen)) == List.length(&2, B8.LK, xs) : Nat}
