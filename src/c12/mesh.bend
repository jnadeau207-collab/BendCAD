import Base
import ../base/num.bend as N
import ../base/par.bend as B
import ../c01/types.bend as V
import ./blob.bend as BL

type MO_P is Data:
  MO_P{ ok: Bool, p: V.Point }

type MO_F is Data:
  MO_F{ ok: Bool, a: Nat, b: Nat, c: Nat }

type MO_G is Data:
  MO_G{ ok: Bool, vs: List<&2, V.Point>, ts: List<&2, MO_F>, why: String }

type MO_R is Data:
  MO_R{ ok: Bool, s: String, nv: Nat, nt: Nat, why: String }

type MO_B is Data:
  MO_B{ ok: Bool, xs: List<&2, U32>, nv: Nat, nt: Nat, why: String }

type MO_LS is Data:
  MO_LS{ cur: List<&2, Char>, acc: List<&2, String> }

type MO_BY is Data:
  MO_BY{ xs: List<&2, U32>, n: U32 }

def mo_mkstr_go(cs: List<&2, Char>, +acc: String) -> String:
  match cs:
    case []: acc
    case h <> t: mo_mkstr_go(t, SCon{h, acc})

def mo_mkstr(+cs: List<&2, Char>) -> String:
  mo_mkstr_go(cs, "")

def mo_lines_nx3(+cr: Bool, h: Char, +cur: List<&2, Char>, +acc: List<&2, String>) -> MO_LS:
  match cr:
    case True{}: MO_LS{cur, acc}
    case False{}: MO_LS{h <> cur, acc}

def mo_lines_nx2(+nl: Bool, +cr: Bool, h: Char, +cur: List<&2, Char>, +acc: List<&2, String>) ->
    MO_LS:
  match nl:
    case True{}: MO_LS{[], mo_mkstr(cur) <> acc}
    case False{}: mo_lines_nx3(cr, h, cur, acc)

def mo_lines_nx(+c: U32, h: Char, +st: MO_LS) -> MO_LS:
  match st:
    case MO_LS{+cur, +acc}: mo_lines_nx2(U32.is_eq(c, 10), U32.is_eq(c, 13), h, cur, acc)

def mo_lines_end(+st: MO_LS) -> List<&2, String>:
  match st:
    case MO_LS{+cur, +acc}: List.reverse(&2, String, mo_mkstr(cur) <> acc)

def mo_lines_go(s: String, +st: MO_LS) -> List<&2, String>:
  match s:
    case SNil{}: mo_lines_end(st)
    case SCon{+h, t}: mo_lines_go(t, mo_lines_nx(N.chr_code(h), h, st))

def mo_lines(+s: String) -> List<&2, String>:
  mo_lines_go(s, MO_LS{[], []})

def mo_p_ok(+r: MO_P) -> Bool:
  MO_P{ok, p} = r
  ok

def mo_p_v(+r: MO_P) -> V.Point:
  MO_P{ok, p} = r
  p

def mo_f_ok(+r: MO_F) -> Bool:
  MO_F{ok, a, b, c} = r
  ok

def mo_f_a(+r: MO_F) -> Nat:
  MO_F{ok, a, b, c} = r
  a

def mo_f_b(+r: MO_F) -> Nat:
  MO_F{ok, a, b, c} = r
  b

def mo_f_c(+r: MO_F) -> Nat:
  MO_F{ok, a, b, c} = r
  c

def mo_head2(+c0: U32, +c1: U32) -> U64:
  Bool.pick(U64, Bool.and(U32.is_eq(c0, 118), U32.is_eq(c1, 32)), 1u64,
    Bool.pick(U64, Bool.and(U32.is_eq(c0, 102), U32.is_eq(c1, 32)), 2u64, 0u64))

def mo_head(+s: String) -> U64:
  match s:
    case SNil{}: 0u64
    case SCon{h, t}:
      match t:
        case SNil{}: 0u64
        case SCon{h2, r}: mo_head2(N.chr_code(h), N.chr_code(h2))

def mo_v3(mx: Maybe<&2, F64>, my: Maybe<&2, F64>, mz: Maybe<&2, F64>) -> MO_P:
  match mx:
    case None{}: MO_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case Some{x}:
      match my:
        case None{}: MO_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
        case Some{y}:
          match mz:
            case None{}: MO_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
            case Some{z}: MO_P{True{}, V.Pt{x, y, z}}

def mo_v4(+w: Bool, +fs: List<&2, String>) -> MO_P:
  match w:
    case False{}: MO_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case True{}: mo_v3(N.num(BL.fld(fs, 1n)), N.num(BL.fld(fs, 2n)), N.num(BL.fld(fs, 3n)))

def mo_v(+line: String) -> MO_P:
  +fs = BL.s_split(line, 32)
  mo_v4(Nat.is_eq(List.length(&2, String, fs), 4n), fs)

def mo_f3p(+w: Bool, +x: U64, +y: U64, +z: U64) -> MO_F:
  match w:
    case False{}: MO_F{False{}, 0n, 0n, 0n}
    case True{}: MO_F{True{}, Nat.sub(U64.to_nat(x), 1n), Nat.sub(U64.to_nat(y), 1n),
      Nat.sub(U64.to_nat(z), 1n)}

def mo_f3(mx: Maybe<&2, U64>, my: Maybe<&2, U64>, mz: Maybe<&2, U64>) -> MO_F:
  match mx:
    case None{}: MO_F{False{}, 0n, 0n, 0n}
    case Some{+x}:
      match my:
        case None{}: MO_F{False{}, 0n, 0n, 0n}
        case Some{+y}:
          match mz:
            case None{}: MO_F{False{}, 0n, 0n, 0n}
            case Some{+z}: mo_f3p(Bool.and(U64.is_le(1u64, x), Bool.and(U64.is_le(1u64, y),
              U64.is_le(1u64, z))), x, y, z)

def mo_f4(+w: Bool, +fs: List<&2, String>) -> MO_F:
  match w:
    case False{}: MO_F{False{}, 0n, 0n, 0n}
    case True{}: mo_f3(U64.read(BL.fld(fs, 1n)), U64.read(BL.fld(fs, 2n)), U64.read(BL.fld(fs, 3n)))

def mo_f(+line: String) -> MO_F:
  +fs = BL.s_split(line, 32)
  mo_f4(Nat.is_eq(List.length(&2, String, fs), 4n), fs)

def mo_nx_vt(+w: Bool, +r: MO_P, +ok: Bool, +vs: List<&2, V.Point>, +ts: List<&2, MO_F>,
    +why: String) -> MO_G:
  match w:
    case False{}: MO_G{False{}, vs, ts, "mesh-bad-vertex"}
    case True{}: MO_G{ok, mo_p_v(r) <> vs, ts, why}

def mo_nx_ft(+w: Bool, +r: MO_F, +ok: Bool, +vs: List<&2, V.Point>, +ts: List<&2, MO_F>,
    +why: String) -> MO_G:
  match w:
    case False{}: MO_G{False{}, vs, ts, "mesh-bad-face"}
    case True{}: MO_G{ok, vs, r <> ts, why}

def mo_nx_k(+k: U64, +h: String, +ok: Bool, +vs: List<&2, V.Point>, +ts: List<&2, MO_F>,
    +why: String) -> MO_G:
  match k:
    case 1u64:
      +r = mo_v(h)
      mo_nx_vt(mo_p_ok(r), r, ok, vs, ts, why)
    case 2u64:
      +r = mo_f(h)
      mo_nx_ft(mo_f_ok(r), r, ok, vs, ts, why)
    case _: MO_G{ok, vs, ts, why}

def mo_nx(+k: U64, +h: String, +st: MO_G) -> MO_G:
  match st:
    case MO_G{+ok, +vs, +ts, +why}: mo_nx_k(k, h, ok, vs, ts, why)

def mo_go(ls: List<&2, String>, +st: MO_G) -> MO_G:
  match ls:
    case []: st
    case +h <> t: mo_go(t, mo_nx(mo_head(h), h, st))

def mo_parse(+obj: String) -> MO_G:
  mo_go(mo_lines(obj), MO_G{True{}, [], [], ""})

def mo_max3(+a: Nat, +b: Nat, +c: Nat) -> Nat:
  Nat.max(a, Nat.max(b, c))

def mo_max_go(ts: List<&2, MO_F>, +m: Nat) -> Nat:
  match ts:
    case []: m
    case +h <> t: mo_max_go(t, mo_max3(mo_f_a(h), mo_f_b(h), mo_f_c(h)))

def mo_max(ts: List<&2, MO_F>) -> Nat:
  mo_max_go(ts, 0n)

def mo_fin_v3(+hix: Bool, +vs: List<&2, V.Point>, +ts: List<&2, MO_F>) -> MO_G:
  match hix:
    case False{}: MO_G{False{}, vs, ts, "mesh-index-out-of-range"}
    case True{}: MO_G{True{}, vs, ts, ""}

def mo_fin_v2(+hnt: Bool, +hix: Bool, +vs: List<&2, V.Point>, +ts: List<&2, MO_F>) -> MO_G:
  match hnt:
    case False{}: MO_G{False{}, vs, ts, "mesh-empty"}
    case True{}: mo_fin_v3(hix, vs, ts)

def mo_fin_v(+hnv: Bool, +hnt: Bool, +hix: Bool, +vs: List<&2, V.Point>, +ts: List<&2, MO_F>) ->
    MO_G:
  match hnv:
    case False{}: MO_G{False{}, vs, ts, "mesh-empty"}
    case True{}: mo_fin_v2(hnt, hix, vs, ts)

def mo_fin_t(+ok: Bool, +vs: List<&2, V.Point>, +ts: List<&2, MO_F>, +why: String) -> MO_G:
  match ok:
    case False{}: MO_G{False{}, vs, ts, why}
    case True{}: mo_fin_v(Nat.is_lt(0n, List.length(&2, V.Point, vs)),
      Nat.is_lt(0n, List.length(&2, MO_F, ts)),
      Nat.is_lt(mo_max(ts), List.length(&2, V.Point, vs)), vs, ts)

def mo_fin(+g: MO_G) -> MO_G:
  match g:
    case MO_G{+ok, +vs, +ts, +why}: mo_fin_t(ok, List.reverse(&2, V.Point, vs),
      List.reverse(&2, MO_F, ts), why)

def mo_mesh(+obj: String) -> MO_G:
  mo_fin(mo_parse(obj))

def mo_g_ok(+r: MO_G) -> Bool:
  MO_G{ok, vs, ts, why} = r
  ok

def mo_g_vs(+r: MO_G) -> List<&2, V.Point>:
  MO_G{ok, vs, ts, why} = r
  vs

def mo_g_ts(+r: MO_G) -> List<&2, MO_F>:
  MO_G{ok, vs, ts, why} = r
  ts

def mo_g_why(+r: MO_G) -> String:
  MO_G{ok, vs, ts, why} = r
  why

def mo_f3s(+p: V.Point) -> String:
  N.f_show(V.pt_x(p)) ++ " " ++ N.f_show(V.pt_y(p)) ++ " " ++ N.f_show(V.pt_z(p))

def mo_nr_l(+w: Bool, +nx: F64, +ny: F64, +nz: F64, +len: F64) -> V.Point:
  match w:
    case True{}: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case False{}: V.Pt{F64.div(nx, len), F64.div(ny, len), F64.div(nz, len)}

def mo_nr(+a: V.Point, +b: V.Point, +c: V.Point) -> V.Point:
  +ux = F64.sub(V.pt_x(b), V.pt_x(a))
  +uy = F64.sub(V.pt_y(b), V.pt_y(a))
  +uz = F64.sub(V.pt_z(b), V.pt_z(a))
  +vx = F64.sub(V.pt_x(c), V.pt_x(a))
  +vy = F64.sub(V.pt_y(c), V.pt_y(a))
  +vz = F64.sub(V.pt_z(c), V.pt_z(a))
  +nx = F64.sub(F64.mul(uy, vz), F64.mul(uz, vy))
  +ny = F64.sub(F64.mul(uz, vx), F64.mul(ux, vz))
  +nz = F64.sub(F64.mul(ux, vy), F64.mul(uy, vx))
  +len = F64.sqrt(F64.add(F64.mul(nx, nx), F64.add(F64.mul(ny, ny), F64.mul(nz, nz))))
  mo_nr_l(F64.is_eq(len, 0.0f64), nx, ny, nz, len)

def mo_facet(+a: V.Point, +b: V.Point, +c: V.Point) -> String:
  " facet normal " ++ mo_f3s(mo_nr(a, b, c)) ++ "\n  outer loop\n   vertex " ++ mo_f3s(a) ++
    "\n   vertex " ++ mo_f3s(b) ++ "\n   vertex " ++ mo_f3s(c) ++ "\n  endloop\n endfacet\n"

def mo_ux(+i: Nat) -> U32:
  U32.from_nat(i)

def mo_stl_go(ts: List<&2, MO_F>, +tb: B.Tb<&2, V.Point>, +acc: List<&2, String>) ->
    List<&2, String>:
  match ts:
    case []: List.reverse(&2, String, acc)
    case +h <> t: mo_stl_go(t, tb, mo_facet(B.tb_get(V.Point, tb, mo_ux(mo_f_a(h))),
      B.tb_get(V.Point, tb, mo_ux(mo_f_b(h))), B.tb_get(V.Point, tb, mo_ux(mo_f_c(h)))) <> acc)

def mo_stl_of(+vs: List<&2, V.Point>, +ts: List<&2, MO_F>) -> String:
  "solid bendcad\n" ++ BL.jn(mo_stl_go(ts, B.tb_of(V.Point, vs, V.Pt{0.0f64, 0.0f64, 0.0f64}),
    []), "") ++ "endsolid bendcad\n"

def mo_stl_t(+w: Bool, +g: MO_G) -> MO_R:
  match w:
    case False{}: MO_R{False{}, "", 0n, 0n, mo_g_why(g)}
    case True{}: MO_R{True{}, mo_stl_of(mo_g_vs(g), mo_g_ts(g)),
      List.length(&2, V.Point, mo_g_vs(g)), List.length(&2, MO_F, mo_g_ts(g)), ""}

def mo_stl(+obj: String) -> MO_R:
  +g = mo_mesh(obj)
  mo_stl_t(mo_g_ok(g), g)

def mo_xml_v(+p: V.Point) -> String:
  "    <vertex x=\"" ++ N.f_show(V.pt_x(p)) ++ "\" y=\"" ++ N.f_show(V.pt_y(p)) ++ "\" z=\"" ++
    N.f_show(V.pt_z(p)) ++ "\" />\n"

def mo_xml_vs_go(ps: List<&2, V.Point>, +acc: List<&2, String>) -> List<&2, String>:
  match ps:
    case []: List.reverse(&2, String, acc)
    case h <> t: mo_xml_vs_go(t, mo_xml_v(h) <> acc)

def mo_xml_t(+f: MO_F) -> String:
  "    <triangle v1=\"" ++ Nat.show(mo_f_a(f)) ++ "\" v2=\"" ++ Nat.show(mo_f_b(f)) ++
    "\" v3=\"" ++ Nat.show(mo_f_c(f)) ++ "\" />\n"

def mo_xml_ts_go(ts: List<&2, MO_F>, +acc: List<&2, String>) -> List<&2, String>:
  match ts:
    case []: List.reverse(&2, String, acc)
    case h <> t: mo_xml_ts_go(t, mo_xml_t(h) <> acc)

def mo_xml_hd() -> String:
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<model unit=\"millimeter\" xml:lang=\"en-US\" xmlns=\"http://schemas.microsoft.com/3dmanufacturing/core/2015/02\">\n <resources>\n  <object id=\"1\" type=\"model\">\n   <mesh>\n    <vertices>\n"

def mo_xml_mid() -> String:
  "    </vertices>\n    <triangles>\n"

def mo_xml_ft() -> String:
  "    </triangles>\n   </mesh>\n  </object>\n </resources>\n <build>\n  <item objectid=\"1\" />\n </build>\n</model>\n"

def mo_xml_of(+vs: List<&2, V.Point>, +ts: List<&2, MO_F>) -> String:
  mo_xml_hd() ++ BL.jn(mo_xml_vs_go(vs, []), "") ++ mo_xml_mid() ++
    BL.jn(mo_xml_ts_go(ts, []), "") ++ mo_xml_ft()

def mo_by_xs(+r: MO_BY) -> List<&2, U32>:
  MO_BY{xs, n} = r
  xs

def mo_by_n(+r: MO_BY) -> U32:
  MO_BY{xs, n} = r
  n

def mo_bytes_go(s: String, +acc: List<&2, U32>, +n: U32) -> MO_BY:
  match s:
    case SNil{}: MO_BY{List.reverse(&2, U32, acc), n}
    case SCon{h, t}: mo_bytes_go(t, N.chr_code(h) <> acc, U32.add(n, 1))

def mo_bytes(+s: String) -> MO_BY:
  mo_bytes_go(s, [], 0)

def mo_crc_bit(+k: Nat, +crc: U32) -> U32:
  match k:
    case 0n: crc
    case 1n+j: mo_crc_bit(j, U32.xor(U32.shr(crc), U32.and(Bool.pick(U32,
      U32.is_eq(U32.and(crc, 1), 1), 4294967295, 0), 3988292384)))

def mo_crc_go(xs: List<&2, U32>, +crc: U32) -> U32:
  match xs:
    case []: U32.xor(crc, 4294967295)
    case +h <> t: mo_crc_go(t, mo_crc_bit(8n, U32.xor(crc, h)))

def mo_crc(+xs: List<&2, U32>) -> U32:
  mo_crc_go(xs, 4294967295)

def mo_l2(+a: U32, +b: U32) -> List<&2, U32>:
  a <> b <> []

def mo_l4(+a: U32, +b: U32, +c: U32, +d: U32) -> List<&2, U32>:
  a <> b <> c <> d <> []

def mo_shr8(+u: U32) -> U32:
  U32.shr(U32.shr(U32.shr(U32.shr(U32.shr(U32.shr(U32.shr(U32.shr(u))))))))

def mo_le16(+u: U32) -> List<&2, U32>:
  mo_l2(U32.and(u, 255), U32.and(mo_shr8(u), 255))

def mo_le32(+u: U32) -> List<&2, U32>:
  mo_l4(U32.and(u, 255), U32.and(mo_shr8(u), 255), U32.and(mo_shr8(mo_shr8(u)), 255),
    U32.and(mo_shr8(mo_shr8(mo_shr8(u))), 255))

def mo_len(+xs: List<&2, U32>) -> U32:
  U32.from_nat(List.length(&2, U32, xs))

def mo_ct() -> String:
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">\n <Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\" />\n <Default Extension=\"model\" ContentType=\"application/vnd.ms-package.3dmanufacturing-3dmodel+xml\" />\n</Types>\n"

def mo_rels() -> String:
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">\n <Relationship Target=\"/3D/3dmodel.model\" Id=\"rel0\" Type=\"http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel\" />\n</Relationships>\n"

def mo_nm_ct() -> String:
  "[Content_Types].xml"

def mo_nm_rels() -> String:
  "_rels/.rels"

def mo_nm_model() -> String:
  "3D/3dmodel.model"

def mo_app(+a: List<&2, U32>, +b: List<&2, U32>) -> List<&2, U32>:
  List.append(&2, U32, a, b)

def mo_lh(+nm: List<&2, U32>, +nn: U32, +crc: U32, +sz: U32) -> List<&2, U32>:
  mo_app(mo_l4(80, 75, 3, 4), mo_app(mo_le16(20), mo_app(mo_le16(0), mo_app(mo_le16(0),
    mo_app(mo_le16(0), mo_app(mo_le16(33), mo_app(mo_le32(crc), mo_app(mo_le32(sz),
      mo_app(mo_le32(sz), mo_app(mo_le16(nn), mo_app(mo_le16(0), nm)))))))))))

def mo_ch(+nm: List<&2, U32>, +nn: U32, +crc: U32, +sz: U32, +off: U32) -> List<&2, U32>:
  mo_app(mo_l4(80, 75, 1, 2), mo_app(mo_le16(20), mo_app(mo_le16(20), mo_app(mo_le16(0),
    mo_app(mo_le16(0), mo_app(mo_le16(0), mo_app(mo_le16(33), mo_app(mo_le32(crc),
      mo_app(mo_le32(sz), mo_app(mo_le32(sz), mo_app(mo_le16(nn), mo_app(mo_le16(0),
        mo_app(mo_le16(0), mo_app(mo_le16(0), mo_app(mo_le16(0), mo_app(mo_le32(0),
          mo_app(mo_le32(off), nm)))))))))))))))))

def mo_eocd(+cdsz: U32, +cdoff: U32) -> List<&2, U32>:
  mo_app(mo_l4(80, 75, 5, 6), mo_app(mo_le16(0), mo_app(mo_le16(0), mo_app(mo_le16(3),
    mo_app(mo_le16(3), mo_app(mo_le32(cdsz), mo_app(mo_le32(cdoff), mo_le16(0))))))))

def mo_zip_of(+m1: MO_BY, +m2: MO_BY, +m3: MO_BY, +f1: MO_BY, +f2: MO_BY, +f3: MO_BY) ->
    List<&2, U32>:
  +h1 = mo_lh(mo_by_xs(m1), mo_by_n(m1), mo_crc(mo_by_xs(f1)), mo_by_n(f1))
  +o2 = U32.add(mo_len(h1), mo_by_n(f1))
  +h2 = mo_lh(mo_by_xs(m2), mo_by_n(m2), mo_crc(mo_by_xs(f2)), mo_by_n(f2))
  +o3 = U32.add(o2, U32.add(mo_len(h2), mo_by_n(f2)))
  +h3 = mo_lh(mo_by_xs(m3), mo_by_n(m3), mo_crc(mo_by_xs(f3)), mo_by_n(f3))
  +cdo = U32.add(o3, U32.add(mo_len(h3), mo_by_n(f3)))
  +c1 = mo_ch(mo_by_xs(m1), mo_by_n(m1), mo_crc(mo_by_xs(f1)), mo_by_n(f1), 0)
  +c2 = mo_ch(mo_by_xs(m2), mo_by_n(m2), mo_crc(mo_by_xs(f2)), mo_by_n(f2), o2)
  +c3 = mo_ch(mo_by_xs(m3), mo_by_n(m3), mo_crc(mo_by_xs(f3)), mo_by_n(f3), o3)
  +cdsz = U32.add(U32.add(mo_len(c1), mo_len(c2)), mo_len(c3))
  mo_app(h1, mo_app(mo_by_xs(f1), mo_app(h2, mo_app(mo_by_xs(f2), mo_app(h3,
    mo_app(mo_by_xs(f3), mo_app(c1, mo_app(c2, mo_app(c3, mo_eocd(cdsz, cdo))))))))))

def mo_r_ok(+r: MO_R) -> Bool:
  MO_R{ok, s, nv, nt, why} = r
  ok

def mo_r_s(+r: MO_R) -> String:
  MO_R{ok, s, nv, nt, why} = r
  s

def mo_r_nv(+r: MO_R) -> Nat:
  MO_R{ok, s, nv, nt, why} = r
  nv

def mo_r_nt(+r: MO_R) -> Nat:
  MO_R{ok, s, nv, nt, why} = r
  nt

def mo_r_why(+r: MO_R) -> String:
  MO_R{ok, s, nv, nt, why} = r
  why

def mo_b_ok(+r: MO_B) -> Bool:
  MO_B{ok, xs, nv, nt, why} = r
  ok

def mo_b_xs(+r: MO_B) -> List<&2, U32>:
  MO_B{ok, xs, nv, nt, why} = r
  xs

def mo_b_nv(+r: MO_B) -> Nat:
  MO_B{ok, xs, nv, nt, why} = r
  nv

def mo_b_nt(+r: MO_B) -> Nat:
  MO_B{ok, xs, nv, nt, why} = r
  nt

def mo_b_why(+r: MO_B) -> String:
  MO_B{ok, xs, nv, nt, why} = r
  why

def mo_threemf_t(+w: Bool, +g: MO_G) -> MO_B:
  match w:
    case False{}: MO_B{False{}, [], 0n, 0n, mo_g_why(g)}
    case True{}:
      +vs = mo_g_vs(g)
      +ts = mo_g_ts(g)
      MO_B{True{}, mo_zip_of(mo_bytes(mo_nm_ct()), mo_bytes(mo_nm_rels()), mo_bytes(mo_nm_model()),
        mo_bytes(mo_ct()), mo_bytes(mo_rels()), mo_bytes(mo_xml_of(vs, ts))),
        List.length(&2, V.Point, vs), List.length(&2, MO_F, ts), ""}

def mo_threemf(+obj: String) -> MO_B:
  +g = mo_mesh(obj)
  mo_threemf_t(mo_g_ok(g), g)
