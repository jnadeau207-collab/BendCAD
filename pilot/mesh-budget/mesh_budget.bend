import Base

type Desc is Data:
  Desc{
    packet_byte_length: U64,
    vertex_count: U64,
    triangle_count: U64,
    face_count: U64,
    edge_count: U64,
    edge_vertex_count: U64,
    brep_vertex_count: U64,
  }

type Totals is Data:
  Totals{
    packet_bytes: U64,
    triangles: U64,
    vertices: U64,
    faces: U64,
    edges: U64,
    edge_vertices: U64,
    brep_vertices: U64,
    body_count: U64,
    gpu_bytes: U64,
  }

type BudgetField is Data:
  F_bodyCount{}
  F_totalPacketBytes{}
  F_totalTriangles{}
  F_totalVertices{}
  F_totalFaces{}
  F_totalEdges{}
  F_totalEdgeVertices{}
  F_totalBrepVertices{}
  F_gpuBytes{}

type AdmitResult is Data:
  AdmitOk{totals: Totals}
  AdmitErr{field: BudgetField}

def BudgetField.show(f: BudgetField) -> String:
  match f:
    case F_bodyCount{}:
      "bodyCount"
    case F_totalPacketBytes{}:
      "totalPacketBytes"
    case F_totalTriangles{}:
      "totalTriangles"
    case F_totalVertices{}:
      "totalVertices"
    case F_totalFaces{}:
      "totalFaces"
    case F_totalEdges{}:
      "totalEdges"
    case F_totalEdgeVertices{}:
      "totalEdgeVertices"
    case F_totalBrepVertices{}:
      "totalBrepVertices"
    case F_gpuBytes{}:
      "gpuBytes"

def max_packet_bytes() -> U64:
  50331648u64

def per_packet_triangle_count() -> U64:
  500000u64

def per_packet_vertex_count() -> U64:
  300000u64

def per_packet_face_count() -> U64:
  50000u64

def per_packet_edge_count() -> U64:
  100000u64

def per_packet_edge_vertex_count() -> U64:
  2000000u64

def per_packet_brep_vertex_count() -> U64:
  300000u64

def eval_total_packet_bytes() -> U64:
  268435456u64

def eval_total_triangles() -> U64:
  1000000u64

def eval_total_vertices() -> U64:
  600000u64

def eval_total_faces() -> U64:
  200000u64

def eval_total_edges() -> U64:
  400000u64

def eval_total_edge_vertices() -> U64:
  8000000u64

def eval_total_brep_vertices() -> U64:
  600000u64

def eval_body_count() -> U64:
  1000u64

def eval_gpu_bytes() -> U64:
  503316480u64

def gpu_bytes_for(v: U64, t: U64) -> U64:
  ((v * 28u64 : U64) + (t * 12u64 : U64) : U64)

def zero_totals() -> Totals:
  Totals{0u64, 0u64, 0u64, 0u64, 0u64, 0u64, 0u64, 0u64, 0u64}

def zero_desc() -> Desc:
  Desc{0u64, 0u64, 0u64, 0u64, 0u64, 0u64, 0u64}

def pick_fail(over: Bool, field: BudgetField, ok: AdmitResult) -> AdmitResult:
  match over:
    case True{}:
      AdmitErr{field}
    case False{}:
      ok

def build_next(
  npb: U64, ntr: U64, nve: U64, nfa: U64, ned: U64, nev: U64, nbv: U64, nbc: U64, ngb: U64
) -> Totals:
  Totals{npb, ntr, nve, nfa, ned, nev, nbv, nbc, ngb}

def admit(t: Totals, d: Desc) -> AdmitResult:
  Totals{pb, tr, ve, fa, ed, ev, bv, bc, gb} = t
  Desc{dp, +dv, +dt, df, de, dev, dbv} = d
  +nbc = (bc + 1u64 : U64)
  +npb = (pb + dp : U64)
  +ntr = (tr + dt : U64)
  +nve = (ve + dv : U64)
  +nfa = (fa + df : U64)
  +ned = (ed + de : U64)
  +nev = (ev + dev : U64)
  +nbv = (bv + dbv : U64)
  +ngb = (gb + gpu_bytes_for(dv, dt) : U64)
  +next = build_next(npb, ntr, nve, nfa, ned, nev, nbv, nbc, ngb)
  r9 = pick_fail((ngb > eval_gpu_bytes() : U64), F_gpuBytes{}, AdmitOk{next})
  r8 = pick_fail((nbv > eval_total_brep_vertices() : U64), F_totalBrepVertices{}, r9)
  r7 = pick_fail((nev > eval_total_edge_vertices() : U64), F_totalEdgeVertices{}, r8)
  r6 = pick_fail((ned > eval_total_edges() : U64), F_totalEdges{}, r7)
  r5 = pick_fail((nfa > eval_total_faces() : U64), F_totalFaces{}, r6)
  r4 = pick_fail((nve > eval_total_vertices() : U64), F_totalVertices{}, r5)
  r3 = pick_fail((ntr > eval_total_triangles() : U64), F_totalTriangles{}, r4)
  r2 = pick_fail((npb > eval_total_packet_bytes() : U64), F_totalPacketBytes{}, r3)
  pick_fail((nbc > eval_body_count() : U64), F_bodyCount{}, r2)

def totals_equal(a: Totals, b: Totals) -> Bool:
  Totals{+pa, +ta, +va, +fa, +ea, +eva, +bva, +bca, +gba} = a
  Totals{+pb, +tb, +vb, +fb, +eb, +evb, +bvb, +bcb, +gbb} = b
  Bool.and(U64.is_eq(pa, pb),
    Bool.and(U64.is_eq(ta, tb),
      Bool.and(U64.is_eq(va, vb),
        Bool.and(U64.is_eq(fa, fb),
          Bool.and(U64.is_eq(ea, eb),
            Bool.and(U64.is_eq(eva, evb),
              Bool.and(U64.is_eq(bva, bvb),
                Bool.and(U64.is_eq(bca, bcb), U64.is_eq(gba, gbb)))))))))

def show_totals(t: Totals) -> String:
  Totals{pb, tr, ve, fa, ed, ev, bv, bc, gb} = t
  "packetBytes=" ++ U64.show(pb) ++ " triangles=" ++ U64.show(tr)
    ++ " vertices=" ++ U64.show(ve) ++ " faces=" ++ U64.show(fa)
    ++ " edges=" ++ U64.show(ed) ++ " edgeVertices=" ++ U64.show(ev)
    ++ " brepVertices=" ++ U64.show(bv) ++ " bodyCount=" ++ U64.show(bc)
    ++ " gpuBytes=" ++ U64.show(gb)

def show_boundary(t: Totals) -> String:
  Totals{pb, tr, ve, fa, ed, ev, bv, bc, gb} = t
  "triangles=" ++ U64.show(tr) ++ " bodyCount=" ++ U64.show(bc)

def atom_seed() -> Totals:
  Totals{0u64, 0u64, 0u64, 0u64, 0u64, 0u64, 0u64, 1000u64, 0u64}

def atomicity_word(ok: Bool) -> String:
  match ok:
    case True{}:
      "ok"
    case False{}:
      "VIOLATED"

law gpu_bytes_zero:
  {gpu_bytes_for(0u64, 0u64) == 0u64 : U64}

def gpu_bytes_zero():
  {==}

law gpu_bytes_unit:
  {gpu_bytes_for(1u64, 1u64) == 40u64 : U64}

def gpu_bytes_unit():
  {==}

law gpu_bytes_oracle_case:
  {gpu_bytes_for(100u64, 200u64) == 5200u64 : U64}

def gpu_bytes_oracle_case():
  {==}

law zero_totals_is_zero:
  {zero_totals() == Totals{0u64, 0u64, 0u64, 0u64, 0u64, 0u64, 0u64, 0u64, 0u64} : Totals}

def zero_totals_is_zero():
  {==}
