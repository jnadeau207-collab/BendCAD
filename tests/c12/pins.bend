import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c12/blob.bend as BL
import ../../src/c12/stepw.bend as SW
import ../../src/c12/stepr.bend as SR
import ../../src/c12/mesh.bend as MO

def pinbrep() -> Ty.Brep:
  Ty.Br{[Ty.Vx{0u64, V.Pt{1.5f64, 0.0f64, 0.0f64}}], [], [], [], [], [], [], Ty.Cp{[], []}, 0u64}

def pinarc() -> String:
  BL.es_s(BL.ar_mk("mm", "pin", pinbrep()))

def pin_drop(+n: Nat, s: String) -> String:
  match n:
    case 0n: s
    case 1n+j:
      match s:
        case SNil{}: s
        case SCon{h, t}: pin_drop(j, t)

def pin_nth(xs: List<&2, U32>, +i: Nat, +d: U32) -> U32:
  match xs:
    case []: d
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: pin_nth(t, j, d)

def pin_bshow_go(xs: List<&2, U32>, +acc: List<&2, String>) -> List<&2, String>:
  match xs:
    case []: List.reverse(&2, String, acc)
    case h <> t: pin_bshow_go(t, Nat.show(U32.to_nat(h)) <> acc)

def pin_bshow(+xs: List<&2, U32>) -> String:
  BL.jn(pin_bshow_go(xs, []), ",")

def pin_tri_obj() -> String:
  "v 0 0 0\nv 1 0 0\nv 0 1 0\nf 1 2 3\n"

def pin_head_vx(xs: List<&2, Ty.Vertex>) -> Ty.Vertex:
  match xs:
    case []: Ty.Vx{0u64, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case h <> t: h

def ar_mk_text__got() -> String:
  pinarc()

def ar_mk_text__want() -> String:
  "BCAD2|mm|pin|B1|1,0,0,0,0,0,0|1.5,0,0|||||||0;0"

def ar_mk_ok__got() -> Bool:
  BL.es_ok_of(BL.ar_mk("mm", "pin", pinbrep()))

def ar_mk_ok__want() -> Bool:
  True{}

def ar_rt_ok__got() -> Bool:
  BL.apr_ok(BL.ar_parse(pinarc()))

def ar_rt_ok__want() -> Bool:
  True{}

def ar_rt_units__got() -> String:
  BL.apr_units(BL.ar_parse(pinarc()))

def ar_rt_units__want() -> String:
  "mm"

def ar_rt_lineage__got() -> String:
  BL.apr_lineage(BL.ar_parse(pinarc()))

def ar_rt_lineage__want() -> String:
  "pin"

def ar_stamp__got() -> U64:
  Ty.brep_stamp(BL.apr_b(BL.ar_parse(pinarc())))

def ar_stamp__want() -> U64:
  1u64

def ar_rt_vx__got() -> F64:
  V.pt_x(Ty.vx_p(pin_head_vx(Ty.brep_vs(BL.apr_b(BL.ar_parse(pinarc()))))))

def ar_rt_vx__want() -> F64:
  1.5f64

def ar_badver__got() -> String:
  BL.apr_why(BL.ar_parse("BCAD0" ++ pin_drop(5n, pinarc())))

def ar_badver__want() -> String:
  "archive-bad-version"

def ar_badunits__got() -> String:
  BL.apr_why(BL.ar_parse("BCAD2|inch|pin|" ++ pin_drop(13n, pinarc())))

def ar_badunits__want() -> String:
  "archive-units-not-supported"

def ar_badenvelope__got() -> String:
  BL.es_why(BL.ar_mk("mm", "a|b", pinbrep()))

def ar_badenvelope__want() -> String:
  "archive-bad-envelope"

def sw_head_text__got() -> String:
  SW.sw_head()

def sw_head_text__want() -> String:
  "ISO-10303-21;\nHEADER;\nFILE_DESCRIPTION(('BendCAD export'),'2;1');\nFILE_NAME('bendcad.step','',('BendCAD'),('BendCAD'),'BendCAD','BendCAD','');\nFILE_SCHEMA(('AUTOMOTIVE_DESIGN'));\nENDSEC;\nDATA;\n"

def sw_units5_text__got() -> String:
  SW.sw_units(5n)

def sw_units5_text__want() -> String:
  "#5 = ( LENGTH_UNIT() NAMED_UNIT(*) SI_UNIT(.MILLI.,.METRE.) );\n#6 = ( NAMED_UNIT(*) PLANE_ANGLE_UNIT() SI_UNIT($,.RADIAN.) );\n#7 = ( NAMED_UNIT(*) SI_UNIT($,.STERADIAN.) SOLID_ANGLE_UNIT() );\n"

def sw_foot_text__got() -> String:
  SW.sw_foot()

def sw_foot_text__want() -> String:
  "ENDSEC;\nEND-ISO-10303-21;\n"

def sw_env_sids_pair__got() -> String:
  SW.sw_env_sids([7n, 9n])

def sw_env_sids_pair__want() -> String:
  ",#7,#9"

def sw_env_sids_nil__got() -> String:
  SW.sw_env_sids([])

def sw_env_sids_nil__want() -> String:
  ""

def sw_sids_range__got() -> String:
  SW.sw_env_sids(SW.sw_sids(7n, 3n))

def sw_sids_range__want() -> String:
  ",#7,#8,#9"

def sw_env_text__got() -> String:
  SW.sw_env(139n, 142n, [138n])

def sw_env_text__want() -> String:
  "#142=APPLICATION_CONTEXT('core data for automotive mechanical design processes');\n#143=APPLICATION_PROTOCOL_DEFINITION('international standard','automotive_design',2000,#142);\n#144=PRODUCT_CONTEXT('',#142,'mechanical');\n#145=PRODUCT_DEFINITION_CONTEXT('part definition',#142,'design');\n#146=PRODUCT('BENDCAD','BENDCAD','',(#144));\n#147=PRODUCT_DEFINITION_FORMATION('','',#146);\n#148=PRODUCT_DEFINITION('design','',#147,#145);\n#149=PRODUCT_DEFINITION_SHAPE('','',#148);\n#150=CARTESIAN_POINT('',(0.0,0.0,0.0));\n#151=DIRECTION('',(0.0,0.0,1.0));\n#152=DIRECTION('',(1.0,0.0,0.0));\n#153=AXIS2_PLACEMENT_3D('',#150,#151,#152);\n#154=ADVANCED_BREP_SHAPE_REPRESENTATION('',(#153,#138),#155);\n#155=( GEOMETRIC_REPRESENTATION_CONTEXT(3) GLOBAL_UNCERTAINTY_ASSIGNED_CONTEXT((#157)) GLOBAL_UNIT_ASSIGNED_CONTEXT((#139,#140,#141)) REPRESENTATION_CONTEXT('','') );\n#156=SHAPE_DEFINITION_REPRESENTATION(#149,#154);\n#157=UNCERTAINTY_MEASURE_WITH_UNIT(LENGTH_MEASURE(0.0000001),#139,'distance_accuracy_value','confusion accuracy');\n#158=PRODUCT_RELATED_PRODUCT_CATEGORY('part',$,(#146));\n"

def sec_extract__got() -> String:
  BL.jn(SR.sr_sec_go(["ISO-10303-21;", "HEADER;", "FILE_DESCRIPTION(('x'),'1');", "ENDSEC;",
    "DATA;", "#1 = CARTESIAN_POINT('',(0.,0.,0.));", "ENDSEC;", "END-ISO-10303-21;"], False{}, []),
    ";")

def sec_extract__want() -> String:
  "#1 = CARTESIAN_POINT('',(0.,0.,0.));"

def se_si_mm() -> SR.SE:
  SR.SE{1u64, SR.SPt{"LENGTH_UNIT", []} <> SR.SPt{"NAMED_UNIT", []} <>
    SR.SPt{"SI_UNIT", SR.SA_en{"MILLI"} <> SR.SA_en{"METRE"} <> []} <> []}

def se_si_m() -> SR.SE:
  SR.SE{2u64, SR.SPt{"LENGTH_UNIT", []} <> SR.SPt{"NAMED_UNIT", []} <>
    SR.SPt{"SI_UNIT", SR.SA_mt{} <> SR.SA_en{"METRE"} <> []} <> []}

def kind_si__got() -> U64:
  SR.sr_kind_of(se_si_mm())

def kind_si__want() -> U64:
  29u64

def kind_unk__got() -> U64:
  SR.sr_kind_of(SR.SE{3u64, SR.SPt{"PRODUCT", []} <> []})

def kind_unk__want() -> U64:
  0u64

def units_mm__got() -> Bool:
  SR.sr_units([se_si_mm()])

def units_mm__want() -> Bool:
  True{}

def units_m__got() -> Bool:
  SR.sr_units([se_si_m()])

def units_m__want() -> Bool:
  False{}

def range4__got() -> String:
  BL.jn(SR.sr_nstrs(SR.sr_range(4n)), ",")

def range4__want() -> String:
  "0,1,2,3"

def freediff__got() -> String:
  BL.jn(SR.sr_nstrs(SR.sr_freediff([0n, 1n, 2n, 3n, 4n], [1n, 3n])), ",")

def freediff__want() -> String:
  "0,2,4"

def stl_tri__got() -> String:
  MO.mo_r_s(MO.mo_stl(pin_tri_obj()))

def stl_tri__want() -> String:
  "solid bendcad\n facet normal 0 0 1\n  outer loop\n   vertex 0 0 0\n   vertex 1 0 0\n   vertex 0 1 0\n  endloop\n endfacet\nendsolid bendcad\n"

def stl_nv__got() -> Nat:
  MO.mo_r_nv(MO.mo_stl(pin_tri_obj()))

def stl_nv__want() -> Nat:
  3n

def stl_nt__got() -> Nat:
  MO.mo_r_nt(MO.mo_stl(pin_tri_obj()))

def stl_nt__want() -> Nat:
  1n

def xml_tri__got() -> String:
  MO.mo_xml_of([V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{1.0f64, 0.0f64, 0.0f64},
    V.Pt{0.0f64, 1.0f64, 0.0f64}], [MO.MO_F{True{}, 0n, 1n, 2n}])

def xml_tri__want() -> String:
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<model unit=\"millimeter\" xml:lang=\"en-US\" xmlns=\"http://schemas.microsoft.com/3dmanufacturing/core/2015/02\">\n <resources>\n  <object id=\"1\" type=\"model\">\n   <mesh>\n    <vertices>\n    <vertex x=\"0\" y=\"0\" z=\"0\" />\n    <vertex x=\"1\" y=\"0\" z=\"0\" />\n    <vertex x=\"0\" y=\"1\" z=\"0\" />\n    </vertices>\n    <triangles>\n    <triangle v1=\"0\" v2=\"1\" v3=\"2\" />\n    </triangles>\n   </mesh>\n  </object>\n </resources>\n <build>\n  <item objectid=\"1\" />\n </build>\n</model>\n"

def crc_std__got() -> U32:
  MO.mo_crc(MO.mo_by_xs(MO.mo_bytes("123456789")))

def crc_std__want() -> U32:
  3421780262

def le16__got() -> String:
  pin_bshow(MO.mo_le16(4660))

def le16__want() -> String:
  "52,18"

def le32__got() -> String:
  pin_bshow(MO.mo_le32(305419896))

def le32__want() -> String:
  "120,86,52,18"

def zip_sig__got() -> String:
  +xs = MO.mo_b_xs(MO.mo_threemf(pin_tri_obj()))
  pin_bshow([pin_nth(xs, 0n, 0), pin_nth(xs, 1n, 0), pin_nth(xs, 2n, 0), pin_nth(xs, 3n, 0)])

def zip_sig__want() -> String:
  "80,75,3,4"

def zip_len__got() -> Nat:
  List.length(&2, U32, MO.mo_b_xs(MO.mo_threemf(pin_tri_obj())))

def zip_len__want() -> Nat:
  1424n
