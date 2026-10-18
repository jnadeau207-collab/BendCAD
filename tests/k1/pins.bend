import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c06/build.bend as BD
import ../../src/c06/model.bend as M
import ../../src/c07/mem.bend as Mm
import ../../src/k1/sf.bend as S
import ../../src/k1/ss.bend as SS
import ../../src/k1/fb.bend as FB
import ../../src/k1/vi.bend as VI
import ../../src/k1/gb.bend as GB

def cone(+z: F64, +dz: F64, +k: F64) -> S.SF:
  S.sf_of(G.GV_co{G.Co{V.Pt{0.0f64, 0.0f64, z}, V.Dr{0.0f64, 0.0f64, dz}, k}})

def zplane(+z: F64) -> S.SF:
  S.sf_of(G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, z}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}}})

def xplane(+x: F64) -> S.SF:
  S.sf_of(G.GV_pl{G.Pl{V.Pt{x, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}}})

def gv_r(g: G.GVal) -> F64:
  match g:
    case G.GV_cc{w}: G.cc_r(w)
    case _: F64.neg(1.0f64)

def circ_r(+c: SS.IC) -> F64:
  gv_r(SS.ic_curve(c))

def opposed_cones_meet_mid__got() -> F64:
  SS.kk_x(cone(0.0f64, 1.0f64, 1.0f64), cone(4.0f64, F64.neg(1.0f64), 1.0f64))

def opposed_cones_meet_mid__want() -> F64:
  2.0f64

def cone_circle_radius__got() -> F64:
  circ_r(SS.k_circ(cone(0.0f64, 1.0f64, 0.5f64), 4.0f64))

def cone_circle_radius__want() -> F64:
  2.0f64

def coaxial_cyl_cone_radius__got() -> F64:
  circ_r(SS.ck_go(S.sf_of(G.GV_cy{G.Cy{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 2.0f64}}), cone(0.0f64, 1.0f64, 0.5f64)))

def coaxial_cyl_cone_radius__want() -> F64:
  2.0f64

def plane_cone_perpendicular__got() -> U64:
  SS.pk_code(zplane(5.0f64), cone(0.0f64, 1.0f64, 0.5f64))

def plane_cone_perpendicular__want() -> U64:
  1u64

def plane_cone_open_refused__got() -> U64:
  SS.pk_code(xplane(3.0f64), cone(0.0f64, 1.0f64, 0.5f64))

def plane_cone_open_refused__want() -> U64:
  5u64

def plane_behind_apex__got() -> U64:
  SS.pk_code(zplane(F64.neg(1.0f64)), cone(0.0f64, 1.0f64, 0.5f64))

def plane_behind_apex__want() -> U64:
  4u64

def boxes_apart__got() -> Bool:
  FB.bb_dis(FB.BB{0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64}, FB.BB{2.0f64, 3.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64})

def boxes_apart__want() -> Bool:
  True{}

def boxes_touch__got() -> Bool:
  FB.bb_dis(FB.BB{0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64}, FB.BB{1.0f64, 3.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64})

def boxes_touch__want() -> Bool:
  False{}

def cone_band_area_term__got() -> F64:
  VI.cone_seg(1.0f64, V.V2{0.0f64, 1.0f64}, V.V2{2.0f64, 2.0f64})

def cone_band_area_term__want() -> F64:
  F64.neg(2.3333333333333335f64)

def split_piece_name__got() -> String:
  BD.fn_name(BD.Fn{1u64, 0n, 16u64, 0n, 0n})

def split_piece_name__want() -> String:
  "n1.c0.top.p1"

def split_piece_base__got() -> String:
  BD.fn_base(BD.Fn{1u64, 0n, 16u64, 0n, 0n})

def split_piece_base__want() -> String:
  "n1.c0.top"

def exact_face_path_membership__got() -> Bool:
  Mm.uv_has(Mm.uv_of(False{}, G.GV_cy{G.Cy{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 2.0f64}}, [], 0.0f64))

def exact_face_path_membership__want() -> Bool:
  False{}

def tolerant_cylinder_param_membership__got() -> Bool:
  Mm.uv_has(Mm.uv_of(True{}, G.GV_cy{G.Cy{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, 2.0f64}}, [], 0.001f64))

def tolerant_cylinder_param_membership__want() -> Bool:
  True{}

def sphere_operand_admitted__got() -> Bool:
  GB.fas_sup([Ty.Fa{0u64, G.GV_sp{G.Sp{V.Pt{0.0f64, 0.0f64, 0.0f64}, 1.0f64}}, [], True{}, 0.0f64, 0.0f64}], True{})

def sphere_operand_admitted__want() -> Bool:
  True{}

def pt3(+x: F64, +y: F64, +z: F64) -> V.Point:
  V.Pt{x, y, z}

def curved_patch_refused__got() -> Bool:
  GB.fas_sup([Ty.Fa{0u64, G.GV_bp{G.Bp{pt3(0.0f64, 0.0f64, 0.0f64), pt3(0.0f64, 1.0f64, 0.0f64), pt3(0.0f64, 2.0f64, 0.0f64), pt3(0.0f64, 3.0f64, 0.0f64),
    pt3(1.0f64, 0.0f64, 0.0f64), pt3(1.0f64, 1.0f64, 1.0f64), pt3(1.0f64, 2.0f64, 1.0f64), pt3(1.0f64, 3.0f64, 0.0f64),
    pt3(2.0f64, 0.0f64, 0.0f64), pt3(2.0f64, 1.0f64, 1.0f64), pt3(2.0f64, 2.0f64, 1.0f64), pt3(2.0f64, 3.0f64, 0.0f64),
    pt3(3.0f64, 0.0f64, 0.0f64), pt3(3.0f64, 1.0f64, 0.0f64), pt3(3.0f64, 2.0f64, 0.0f64), pt3(3.0f64, 3.0f64, 0.0f64)}}, [], True{}, 0.0f64, 0.0f64}], True{})

def curved_patch_refused__want() -> Bool:
  False{}

def sph(+z: F64, +r: F64) -> S.SF:
  S.sf_of(G.GV_sp{G.Sp{V.Pt{0.0f64, 0.0f64, z}, r}})

def zcyl(+r: F64) -> S.SF:
  S.sf_of(G.GV_cy{G.Cy{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, r}})

def tor(+bigr: F64, +r: F64) -> S.SF:
  S.sf_of(G.GV_to{G.To{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, bigr, r}})

def ics_n(+c: SS.ICS) -> Nat:
  List.length(&2, SS.IC, SS.ics_ics(c))

def L_ic(xs: List<&2, SS.IC>, +i: Nat) -> SS.IC:
  match xs:
    case []: SS.none_ic()
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: L_ic(t, j)


def ics_r(+c: SS.ICS, +i: Nat) -> F64:
  circ_r(L_ic(SS.ics_ics(c), i))

def plane_sphere_circle_radius__got() -> F64:
  circ_r(SS.ps_go(zplane(3.0f64), sph(0.0f64, 5.0f64)))

def plane_sphere_circle_radius__want() -> F64:
  4.0f64

def ball_on_shaft_one_tangent_circle__got() -> Nat:
  ics_n(SS.cs_go(zcyl(3.0f64), sph(10.0f64, 3.0f64), []))

def ball_on_shaft_one_tangent_circle__want() -> Nat:
  1n

def torus_plane_two_circles__got() -> Nat:
  ics_n(SS.tp_go(zplane(0.6f64), tor(5.0f64, 1.0f64)))

def torus_plane_two_circles__want() -> Nat:
  2n

def torus_plane_outer_radius__got() -> F64:
  ics_r(SS.tp_go(zplane(0.0f64), tor(5.0f64, 1.0f64)), 0n)

def torus_plane_outer_radius__want() -> F64:
  6.0f64

def torus_tangent_plane_circle__got() -> F64:
  ics_r(SS.tp_go(zplane(1.0f64), tor(5.0f64, 1.0f64)), 0n)

def torus_tangent_plane_circle__want() -> F64:
  5.0f64

def torus_tangent_cylinder_circle__got() -> Nat:
  ics_n(SS.tcy_go(zcyl(4.0f64), tor(5.0f64, 1.0f64)))

def torus_tangent_cylinder_circle__want() -> Nat:
  1n

def reversed_face_frame_y__got() -> F64:
  V.dr_y(M.fr_w(M.frame_of(Ty.Fa{0u64, G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}}}, [], False{}, 0.0f64, 0.0f64})))

def reversed_face_frame_y__want() -> F64:
  F64.neg(1.0f64)
