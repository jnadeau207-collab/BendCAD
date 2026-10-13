import Base
import ../../src/c04/types.bend as Ty
import ../../src/c12/blob.bend as BL
import ../../src/c12/stepw.bend as SW
import ../../src/c12/stepr.bend as SR
import ../../src/c12/mesh.bend as MO

def pt1(+nm: String) -> List<&2, SR.SPt>:
  SR.SPt{nm, []} <> []

def cx2(+a: String, +b: String) -> List<&2, SR.SPt>:
  SR.SPt{a, []} <> SR.SPt{b, []} <> []

law ar_units_mm:
  for u: String
  {BL.ar_units_ok(u) == String.eq(u, "mm") : Bool}

law ar_ver_refused:
  for s: List<&2, String>
  {BL.ar_secs_v(False{}, s) == BL.apr_fail("archive-bad-version") : BL.APR}

law ar_units_refused:
  for s: List<&2, String>
  {BL.ar_secs_u(False{}, s) == BL.apr_fail("archive-units-not-supported") : BL.APR}

law ar_count_refused:
  for sp: BL.SP
  {BL.ar_parse_t2(False{}, sp) == BL.apr_fail("archive-sections-count") : BL.APR}

law ar_overflow_refused:
  for sp: BL.SP
  {BL.ar_parse_t(False{}, sp) == BL.apr_fail("archive-sections-overflow") : BL.APR}

law ar_large_refused:
  for s: String
  {BL.ar_parse_t0(False{}, s) == BL.apr_fail("archive-too-large") : BL.APR}

law ar_envelope_refused:
  for u: String
  for l: String
  for b: Ty.Brep
  {BL.ar_mk_t(False{}, u, l, b) == BL.es_fail("archive-bad-envelope") : BL.ES}

law ar_mk_ok_shape:
  for u: String
  for l: String
  for b: Ty.Brep
  {BL.ar_mk_t(True{}, u, l, b) == BL.es_app(BL.es_ok("BCAD1|" ++ u ++ "|" ++ l ++ "|"), BL.brep_s(b), "") : BL.ES}

law kind_cartesian_point:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("CARTESIAN_POINT")}) == 1u64 : U64}

law kind_direction:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("DIRECTION")}) == 2u64 : U64}

law kind_line:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("LINE")}) == 4u64 : U64}

law kind_circle:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("CIRCLE")}) == 5u64 : U64}

law kind_plane:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("PLANE")}) == 10u64 : U64}

law kind_sphere:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("SPHERICAL_SURFACE")}) == 11u64 : U64}

law kind_cylinder:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("CYLINDRICAL_SURFACE")}) == 12u64 : U64}

law kind_torus:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("TOROIDAL_SURFACE")}) == 13u64 : U64}

law kind_cone:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("CONICAL_SURFACE")}) == 27u64 : U64}

law kind_vertex_point:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("VERTEX_POINT")}) == 15u64 : U64}

law kind_edge_curve:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("EDGE_CURVE")}) == 16u64 : U64}

law kind_advface:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("ADVANCED_FACE")}) == 20u64 : U64}

law kind_shell:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("CLOSED_SHELL")}) == 21u64 : U64}

law kind_solid:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("MANIFOLD_SOLID_BREP")}) == 22u64 : U64}

law kind_si_unit:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("SI_UNIT")}) == 29u64 : U64}

law kind_unknown_zero:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("NOPE_NOT_AN_ENTITY")}) == 0u64 : U64}

law kind_voids:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("BREP_WITH_VOIDS")}) == 30u64 : U64}

law kind_assembly:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, pt1("MAPPED_ITEM")}) == 31u64 : U64}

law kind_rational:
  for id: U64
  {SR.sr_kind_of(SR.SE{id, cx2("B_SPLINE_CURVE", "RATIONAL_B_SPLINE_CURVE")}) == 7u64 : U64}

law has_nm_nil:
  for s: String
  {SR.sr_has_nm([], s) == False{} : Bool}

law sw_wrap_count:
  for r: SW.ER2
  for np: Nat
  {SW.ws_nent(SW.sw_wrap_t(True{}, r, np)) == Nat.add(SW.er2_n(r), 19n) : Nat}

law sw_wrap_refused:
  for r: SW.ER2
  for np: Nat
  {SW.sw_wrap_t(False{}, r, np) == SW.WS{False{}, "", SW.er2_why(r), 0n, 0n} : SW.WS}

law sw_units_head:
  for n: Nat
  {SW.sw_units(n) == "#" ++ Nat.show(n) ++ " = ( LENGTH_UNIT() NAMED_UNIT(*) SI_UNIT(.MILLI.,.METRE.) );\n" ++ "#" ++ Nat.show(Nat.add(n, 1n)) ++ " = ( NAMED_UNIT(*) PLANE_ANGLE_UNIT() SI_UNIT($,.RADIAN.) );\n" ++ "#" ++ Nat.show(Nat.add(n, 2n)) ++ " = ( NAMED_UNIT(*) SI_UNIT($,.STERADIAN.) SOLID_ANGLE_UNIT() );\n" : String}

law parse_cap_refused:
  for js: List<&2, String>
  {SR.sr_parse_cap(False{}, js) == BL.pr_fail("step-too-many-entities") : BL.PR}

law parse_en_refused:
  for es: List<&2, SR.SE>
  {SR.sr_parse_en(False{}, es) == BL.pr_fail("step-entity-parse-failed") : BL.PR}

law parse_so_refused:
  for es: List<&2, SR.SE>
  {SR.sr_parse_so(False{}, es) == BL.pr_fail("step-sort-failed") : BL.PR}

law parse_du_refused:
  for es: List<&2, SR.SE>
  {SR.sr_parse_du(False{}, es) == BL.pr_fail("step-duplicate-id") : BL.PR}

law parse_un_refused:
  for es: List<&2, SR.SE>
  for st: SR.ST
  {SR.sr_parse_un(False{}, es, st) == BL.pr_fail("step-units-not-supported") : BL.PR}

law parse_op_refused:
  for es: List<&2, SR.SE>
  for st: SR.ST
  {SR.sr_parse_op(False{}, es, st) == BL.pr_fail("step-open-shell-not-in-profile") : BL.PR}

law parse_vd_refused:
  for es: List<&2, SR.SE>
  for st: SR.ST
  {SR.sr_parse_vd(False{}, es, st) == BL.pr_fail("step-voids-not-in-profile") : BL.PR}

law parse_as_refused:
  for es: List<&2, SR.SE>
  for st: SR.ST
  {SR.sr_parse_as(False{}, es, st) == BL.pr_fail("step-assembly-not-in-profile") : BL.PR}

law parse_v_refused:
  for es: List<&2, SR.SE>
  for st: SR.ST
  for vr: SR.SR_VW
  {SR.sr_parse_v(False{}, es, st, vr) == BL.pr_fail("step-bad-vertex-point #" ++ U64.show(SR.sr_vw_bad(vr))) : BL.PR}

law parse_o_refused:
  for es: List<&2, SR.SE>
  for st: SR.ST
  for vr: SR.SR_VW
  for er: SR.SR_EW
  for cr: SR.SR_CW
  for lr: SR.SR_LW
  for fr: SR.SR_FW
  for sw: SR.SR_SW
  for ow: SR.SR_OW
  {SR.sr_parse_o(False{}, es, st, vr, er, cr, lr, fr, sw, ow) == BL.pr_fail("step-bad-solid #" ++ U64.show(SR.sr_ow_bad(ow))) : BL.PR}

law parse_s_refused:
  for es: List<&2, SR.SE>
  for st: SR.ST
  for vr: SR.SR_VW
  for er: SR.SR_EW
  for cr: SR.SR_CW
  for lr: SR.SR_LW
  for fr: SR.SR_FW
  for sw: SR.SR_SW
  {SR.sr_parse_s(False{}, es, st, vr, er, cr, lr, fr, sw) == BL.pr_fail("step-bad-shell #" ++ U64.show(SR.sr_sw_bad(sw))) : BL.PR}

law parse_nso_refused:
  for vr: SR.SR_VW
  for er: SR.SR_EW
  for cr: SR.SR_CW
  for lr: SR.SR_LW
  for fr: SR.SR_FW
  for sw: SR.SR_SW
  for ow: SR.SR_OW
  {SR.sr_parse_nso(False{}, vr, er, cr, lr, fr, sw, ow) == BL.pr_fail("step-no-solid") : BL.PR}

law fail_edge_vertex:
  for bad: U64
  for st: SR.ST
  {SR.sr_fail_edge(1u64, bad, st) == BL.pr_fail("step-edge-bad-vertex #" ++ U64.show(bad)) : BL.PR}

law fail_face_bounds:
  for bad: U64
  for st: SR.ST
  {SR.sr_fail_face(1u64, bad, st) == BL.pr_fail("step-face-bad-bounds #" ++ U64.show(bad)) : BL.PR}

law fail_loop_dup:
  for bad: U64
  {SR.sr_fail_loop(7u64, bad) == BL.pr_fail("step-bound-in-two-faces #" ++ U64.show(bad)) : BL.PR}

law fail_ce_trim:
  for bad: U64
  {SR.sr_fail_ce(9u64, bad) == BL.pr_fail("step-coedge-trim-failed #" ++ U64.show(bad)) : BL.PR}

law fail_curve_spline:
  for cid: U64
  {SR.sr_fail_curve(7u64, cid) == BL.pr_fail("step-spline-not-bezier-form #" ++ U64.show(cid)) : BL.PR}

law fail_surf_cone:
  for sid: U64
  {SR.sr_fail_surf(27u64, sid) == BL.pr_fail("step-conical-surface-not-in-profile") : BL.PR}

law sec_go_nil:
  for ind: Bool
  for acc: List<&2, String>
  {SR.sr_sec_go([], ind, acc) == List.reverse(&2, String, acc) : List<&2, String>}

law sec_data_enter:
  for t: List<&2, String>
  for acc: List<&2, String>
  {SR.sr_sec_go("DATA;" <> t, False{}, acc) == SR.sr_sec_go(t, True{}, acc) : List<&2, String>}

law sec_end_stop:
  for t: List<&2, String>
  for acc: List<&2, String>
  {SR.sr_sec_go("ENDSEC;" <> t, True{}, acc) == List.reverse(&2, String, acc) : List<&2, String>}

law mo_head_v:
  for r: String
  {MO.mo_head("v " ++ r) == 1u64 : U64}

law mo_head_f:
  for r: String
  {MO.mo_head("f " ++ r) == 2u64 : U64}

law mo_head_short:
  for c: Char
  {MO.mo_head(SCon{c, SNil{}}) == 0u64 : U64}

law mo_crc_bit_zero:
  for crc: U32
  {MO.mo_crc_bit(0n, crc) == crc : U32}

law mo_crc_go_nil:
  for crc: U32
  {MO.mo_crc_go([], crc) == U32.xor(crc, 4294967295) : U32}

law mo_l2_len:
  for a: U32
  for b: U32
  {List.length(&2, U32, MO.mo_l2(a, b)) == 2n : Nat}

law mo_bytes_nil:
  for acc: List<&2, U32>
  for n: U32
  {MO.mo_bytes_go(SNil{}, acc, n) == MO.MO_BY{List.reverse(&2, U32, acc), n} : MO.MO_BY}

law ar_drop3:
  for a: String
  for b: String
  for c: String
  for rest: List<&2, String>
  {BL.ar_drop3(a <> b <> c <> rest) == rest : List<&2, String>}

law sr_range_one:
  for acc: List<&2, Nat>
  {SR.sr_range_go(1n, acc) == 0n <> acc : List<&2, Nat>}

law sr_tp2_len:
  for a: String
  for b: String
  {List.length(&2, String, SR.sr_tp2(a, b)) == 2n : Nat}

law mkstr_unreverses:
  for a: Char
  for b: Char
  {SR.sr_mkstr(a <> b <> []) == SCon{b, SCon{a, ""}} : String}

law br_mk_stamp:
  for vs: List<&2, Ty.Vertex>
  for es: List<&2, Ty.Edge>
  for ces: List<&2, Ty.Coedge>
  for lps: List<&2, Ty.Loop>
  for fas: List<&2, Ty.Face>
  for shs: List<&2, Ty.Shell>
  for sos: List<&2, Ty.Solid>
  for top: Ty.Compound
  {Ty.brep_stamp(BL.br_mk(vs, es, ces, lps, fas, shs, sos, top)) == BL.br_stamp(vs, es, ces, lps, fas, shs, sos) : U64}
