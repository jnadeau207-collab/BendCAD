# Pilot entry point: replays the oracle vectors (oracle.ts, generated from the
# ORIGINAL mesh-budget.ts) against the Bend port and prints the same line
# protocol. Byte-identical stdout across lanes + `diff` against oracle.out is
# the verification gate; the trailing `selfcheck fails=N` line folds every
# internal expectation (accept values, reject fields, boundary, atomicity).

import Base
import ./mesh_budget.bend as MB

def admit2_go(r: MB.AdmitResult, d: MB.Desc) -> MB.AdmitResult:
  match r:
    case MB.AdmitErr{fd}:
      MB.AdmitErr{fd}
    case MB.AdmitOk{t}:
      MB.admit(t, d)

def admit_twice(+b: MB.Desc) -> MB.AdmitResult:
  admit2_go(MB.admit(MB.zero_totals(), b), b)

def print_accept_checked(+tag: String, r: MB.AdmitResult, +want: MB.Totals, f: U64) -> IO(U64):
  match r:
    case MB.AdmitOk{+t}:
      do IO<U64>:
        IO.print(tag ++ " " ++ MB.show_totals(t))
        return (f + Bool.to_u64(Bool.not(MB.totals_equal(t, want))) : U64)
    case MB.AdmitErr{fd}:
      do IO<U64>:
        IO.print(tag ++ " UNEXPECTED-REJECT " ++ MB.BudgetField.show(fd))
        return (f + 1u64 : U64)

def print_reject_checked(r: MB.AdmitResult, +want: String, f: U64) -> IO(U64):
  match r:
    case MB.AdmitErr{+fd}:
      do IO<U64>:
        IO.print("reject " ++ MB.BudgetField.show(fd))
        return (f + Bool.to_u64(Bool.not(String.eq(MB.BudgetField.show(fd), want))) : U64)
    case MB.AdmitOk{t}:
      do IO<U64>:
        IO.print("reject UNEXPECTED-ACCEPT " ++ MB.show_totals(t))
        return (f + 1u64 : U64)

def print_boundary_checked(r: MB.AdmitResult, +want: MB.Totals, f: U64) -> IO(U64):
  match r:
    case MB.AdmitOk{+t}:
      do IO<U64>:
        IO.print("accept-boundary " ++ MB.show_boundary(t))
        return (f + Bool.to_u64(Bool.not(MB.totals_equal(t, want))) : U64)
    case MB.AdmitErr{fd}:
      do IO<U64>:
        IO.print("accept-boundary UNEXPECTED-REJECT " ++ MB.BudgetField.show(fd))
        return (f + 1u64 : U64)

def atomicity_go(r: MB.AdmitResult, +t: MB.Totals, f: U64) -> IO(U64):
  match r:
    case MB.AdmitErr{fd}:
      do IO<U64>:
        IO.print("atomicity " ++ MB.atomicity_word(MB.totals_equal(t, MB.atom_seed())))
        return (f + Bool.to_u64(Bool.not(MB.totals_equal(t, MB.atom_seed()))) : U64)
    case MB.AdmitOk{t2}:
      do IO<U64>:
        IO.print("atomicity VIOLATED")
        return (f + 1u64 : U64)

def atomicity_checked(f: U64) -> IO(U64):
  +t0 = MB.atom_seed()
  atomicity_go(MB.admit(t0, MB.zero_desc()), t0, f)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("const maxPacketBytes=" ++ U64.show(MB.max_packet_bytes()))
    IO.print("const perPacket triangleCount=" ++ U64.show(MB.per_packet_triangle_count())
      ++ " vertexCount=" ++ U64.show(MB.per_packet_vertex_count())
      ++ " faceCount=" ++ U64.show(MB.per_packet_face_count())
      ++ " edgeCount=" ++ U64.show(MB.per_packet_edge_count())
      ++ " edgeVertexCount=" ++ U64.show(MB.per_packet_edge_vertex_count())
      ++ " brepVertexCount=" ++ U64.show(MB.per_packet_brep_vertex_count()))
    IO.print("const eval totalPacketBytes=" ++ U64.show(MB.eval_total_packet_bytes())
      ++ " totalTriangles=" ++ U64.show(MB.eval_total_triangles())
      ++ " totalVertices=" ++ U64.show(MB.eval_total_vertices())
      ++ " totalFaces=" ++ U64.show(MB.eval_total_faces())
      ++ " totalEdges=" ++ U64.show(MB.eval_total_edges())
      ++ " totalEdgeVertices=" ++ U64.show(MB.eval_total_edge_vertices())
      ++ " totalBrepVertices=" ++ U64.show(MB.eval_total_brep_vertices())
      ++ " bodyCount=" ++ U64.show(MB.eval_body_count())
      ++ " gpuBytes=" ++ U64.show(MB.eval_gpu_bytes()))
    f1 : U64 <- print_accept_checked("accept-single",
      MB.admit(MB.zero_totals(), MB.Desc{4096u64, 100u64, 200u64, 6u64, 12u64, 24u64, 8u64}),
      MB.Totals{4096u64, 200u64, 100u64, 6u64, 12u64, 24u64, 8u64, 1u64, 5200u64}, 0u64)
    f2 : U64 <- print_accept_checked("accept-double",
      admit_twice(MB.Desc{1000u64, 10u64, 20u64, 0u64, 0u64, 0u64, 0u64}),
      MB.Totals{2000u64, 40u64, 20u64, 0u64, 0u64, 0u64, 0u64, 2u64, 1040u64}, f1)
    f3 : U64 <- print_reject_checked(
      MB.admit(MB.zero_totals(), MB.Desc{268435457u64, 0u64, 0u64, 0u64, 0u64, 0u64, 0u64}),
      "totalPacketBytes", f2)
    f4 : U64 <- print_reject_checked(
      MB.admit(MB.zero_totals(), MB.Desc{0u64, 0u64, 1000001u64, 0u64, 0u64, 0u64, 0u64}),
      "totalTriangles", f3)
    f5 : U64 <- print_reject_checked(
      MB.admit(MB.zero_totals(), MB.Desc{0u64, 600001u64, 0u64, 0u64, 0u64, 0u64, 0u64}),
      "totalVertices", f4)
    f6 : U64 <- print_reject_checked(
      MB.admit(MB.zero_totals(), MB.Desc{0u64, 0u64, 0u64, 200001u64, 0u64, 0u64, 0u64}),
      "totalFaces", f5)
    f7 : U64 <- print_reject_checked(
      MB.admit(MB.zero_totals(), MB.Desc{0u64, 0u64, 0u64, 0u64, 400001u64, 0u64, 0u64}),
      "totalEdges", f6)
    f8 : U64 <- print_reject_checked(
      MB.admit(MB.zero_totals(), MB.Desc{0u64, 0u64, 0u64, 0u64, 0u64, 8000001u64, 0u64}),
      "totalEdgeVertices", f7)
    f9 : U64 <- print_reject_checked(
      MB.admit(MB.zero_totals(), MB.Desc{0u64, 0u64, 0u64, 0u64, 0u64, 0u64, 600001u64}),
      "totalBrepVertices", f8)
    f10 : U64 <- print_reject_checked(MB.admit(MB.atom_seed(), MB.zero_desc()), "bodyCount", f9)
    f11 : U64 <- print_reject_checked(
      MB.admit(MB.Totals{0u64, 0u64, 0u64, 0u64, 0u64, 0u64, 0u64, 0u64, 503316480u64},
        MB.Desc{0u64, 1u64, 0u64, 0u64, 0u64, 0u64, 0u64}),
      "gpuBytes", f10)
    f12 : U64 <- print_boundary_checked(
      MB.admit(MB.zero_totals(), MB.Desc{0u64, 0u64, 1000000u64, 0u64, 0u64, 0u64, 0u64}),
      MB.Totals{0u64, 1000000u64, 0u64, 0u64, 0u64, 0u64, 0u64, 1u64, 12000000u64}, f11)
    f13 : U64 <- atomicity_checked(f12)
    IO.print("selfcheck fails=" ++ U64.show(f13))
