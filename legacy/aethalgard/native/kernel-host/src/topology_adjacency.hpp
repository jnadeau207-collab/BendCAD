#pragma once

// Shared free-edge / incident-face topology helpers (mold/tooling wave).
//
// Before this file, `IncidentFacesOf` (sheet_metal_feature.cpp, anonymous
// namespace) and `FreeEdgesOf` (surfacing_feature.cpp, anonymous namespace)
// each independently reimplemented `TopExp::MapShapesAndAncestors` for the
// same manifold-adjacency queries. The mold/tooling domain needs BOTH
// simultaneously (parting-line/shut-off face-and-edge walks), which is the
// moment a shared header stops being optional — this file is that header,
// and sheet_metal_feature.cpp/surfacing_feature.cpp were backfilled to call
// it instead of keeping their own copies, so there is exactly one
// implementation of each helper rather than a third (or fourth) copy-paste.
// Header-only `inline` functions, the exact `topology_index_maps.hpp`
// precedent: keeping shared topology plumbing header-only avoids a new
// link-time dependency for every translation unit (including native tests)
// that only needs the query, not a whole feature file.
//
// `GroupEdgesIntoLoops` is new: `surfacing_feature.cpp`'s own
// `OrderIntoSingleLoop` (boundary_surface) assumes/requires its input is
// exactly ONE closed loop. Shut-off surfaces must cap MULTIPLE independent
// hole loops on one body (one per through-hole), so this helper generalizes
// that walk from "exactly one loop, or refuse" to "partition into however
// many disjoint simple closed loops the edge set actually contains, or
// refuse if any connected component of shared vertices is not itself a
// simple closed loop" — the same "fail closed on a topology defect" contract
// `OrderIntoSingleLoop` already applies, just evaluated per connected
// component instead of once globally.

#include <cstddef>
#include <vector>

#include <BRep_Tool.hxx>
#include <NCollection_IndexedDataMap.hxx>
#include <NCollection_List.hxx>
#include <Standard_Failure.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shape.hxx>
#include <TopoDS_Vertex.hxx>

namespace aeth {

/// Every face of `body` sharing `edge` (ADR-003 epoch-local topology; the
/// same `TopExp::MapShapesAndAncestors` call `ComputeDihedralRange`
/// (geometry_measures.cpp) itself makes). Relocated verbatim from
/// sheet_metal_feature.cpp's own former anonymous-namespace copy.
inline std::vector<TopoDS_Face> IncidentFacesOf(const TopoDS_Shape& body, const TopoDS_Edge& edge) {
  NCollection_IndexedDataMap<TopoDS_Shape, NCollection_List<TopoDS_Shape>, TopTools_ShapeMapHasher>
      edgeToFaces;
  TopExp::MapShapesAndAncestors(body, TopAbs_EDGE, TopAbs_FACE, edgeToFaces);
  std::vector<TopoDS_Face> faces;
  const int index = edgeToFaces.FindIndex(edge);
  if (index == 0)
    return faces;
  for (const TopoDS_Shape& face : edgeToFaces.FindFromKey(edge))
    faces.push_back(TopoDS::Face(face));
  return faces;
}

/// Every edge of `shape` incident to EXACTLY one face — the standard
/// manifold free-boundary definition. Relocated from surfacing_feature.cpp's
/// own former anonymous-namespace copy, with ONE behavior addition on top of
/// a verbatim port: DEGENERATE edges (`BRep_Tool::Degenerated`, the
/// zero-length/no-3D-curve bookkeeping edges OCCT mints at a revolve's pole
/// or axis-touching seam — the exact idiom geometry_measures.cpp/
/// naming_registry.cpp/tessellate.cpp/topology.cpp already special-case
/// throughout this codebase) are EXCLUDED from the result, never counted as
/// a genuine open boundary. MEASURED, not a defensive guess: a revolved cone
/// whose profile touches its own axis (this domain's own bicone test
/// fixture, mold_tooling_test.cpp) leaves exactly one such degenerate edge
/// with a single incident face — feeding it into
/// `BRepOffsetAPI_MakeFilling::Add` (the mold_shutoff_surface/
/// boundary_surface capping primitive) does not throw a catchable
/// `Standard_Failure` at all; it SEGFAULTS several frames deep inside
/// `GeomPlate_BuildPlateSurface::Disc2dContour` on this pinned OCCT build —
/// a hardware trap no try/catch can intercept, caught only by never handing
/// this primitive a degenerate edge in the first place. Excluding it here,
/// at the shared boundary-discovery helper, is strictly safe for
/// `boundary_surface`'s own existing behavior too (its own fixtures — a box
/// with faces removed — contain no degenerate edges, so this is a no-op for
/// every case that helper's own tests already cover) while closing a real
/// crash for any shape (this domain's own bicone included) that does.
inline std::vector<TopoDS_Edge> FreeEdgesOf(const TopoDS_Shape& shape) {
  NCollection_IndexedDataMap<TopoDS_Shape, NCollection_List<TopoDS_Shape>, TopTools_ShapeMapHasher>
      edgeToFaces;
  TopExp::MapShapesAndAncestors(shape, TopAbs_EDGE, TopAbs_FACE, edgeToFaces);
  std::vector<TopoDS_Edge> freeEdges;
  for (int index = 1; index <= edgeToFaces.Extent(); ++index) {
    if (edgeToFaces(index).Extent() != 1)
      continue;
    const TopoDS_Edge edge = TopoDS::Edge(edgeToFaces.FindKey(index));
    if (BRep_Tool::Degenerated(edge))
      continue;
    freeEdges.push_back(edge);
  }
  return freeEdges;
}

/// Groups `edges` into distinct closed loops by shared vertices, each loop
/// returned in WALKED (traversal) order — surfacing_feature.cpp's own
/// `OrderIntoSingleLoop`, generalized from "exactly one loop" to "however
/// many disjoint simple closed loops the edge set contains". A degenerate
/// single edge whose own two endpoints are the SAME vertex (a full circular
/// free edge — the common case for a drilled through-hole's rim) is a valid
/// one-edge loop.
///
/// Throws `Standard_Failure` if any vertex touched by `edges` has degree
/// other than exactly two (a non-manifold junction: three or more of
/// `edges` meeting at one point, or a dangling endpoint touched by only
/// one), or if a connected component's walk cannot consume every one of its
/// own edges and return to its own start vertex. Both are real topology
/// defects this codebase already refuses rather than silently mis-groups —
/// see `OrderIntoSingleLoop`'s identical single-loop contract.
inline std::vector<std::vector<TopoDS_Edge>>
GroupEdgesIntoLoops(const std::vector<TopoDS_Edge>& edges) {
  NCollection_IndexedDataMap<TopoDS_Shape, std::vector<std::size_t>, TopTools_ShapeMapHasher>
      vertexToEdges;
  std::vector<TopoDS_Vertex> firstVertex(edges.size());
  std::vector<TopoDS_Vertex> secondVertex(edges.size());
  for (std::size_t index = 0; index < edges.size(); ++index) {
    TopoDS_Vertex v1;
    TopoDS_Vertex v2;
    TopExp::Vertices(edges[index], v1, v2);
    if (v1.IsNull() || v2.IsNull())
      throw Standard_Failure("GroupEdgesIntoLoops: an edge has no endpoints");
    firstVertex[index] = v1;
    secondVertex[index] = v2;
    for (const TopoDS_Vertex& vertex : {v1, v2}) {
      const int existing = vertexToEdges.FindIndex(vertex);
      if (existing == 0)
        vertexToEdges.Add(vertex, std::vector<std::size_t>{index});
      else
        vertexToEdges.ChangeFromIndex(existing).push_back(index);
    }
  }
  for (int index = 1; index <= vertexToEdges.Extent(); ++index) {
    if (vertexToEdges(index).size() != 2) {
      throw Standard_Failure(
          "GroupEdgesIntoLoops: a vertex is touched by other than exactly two edges, so the edge "
          "set is not a union of simple closed loops");
    }
  }

  std::vector<bool> visited(edges.size(), false);
  std::vector<std::vector<TopoDS_Edge>> loops;
  for (std::size_t seed = 0; seed < edges.size(); ++seed) {
    if (visited[seed])
      continue;
    // Walk this connected component starting at `seed` — OrderIntoSingleLoop's
    // own walk, stopped at THIS component's own closure rather than assuming
    // it spans every edge passed in.
    std::vector<TopoDS_Edge> loop;
    const TopoDS_Vertex startVertex = firstVertex[seed];
    TopoDS_Vertex currentVertex = secondVertex[seed];
    loop.push_back(edges[seed]);
    visited[seed] = true;
    while (!currentVertex.IsSame(startVertex)) {
      const int atCurrent = vertexToEdges.FindIndex(currentVertex);
      bool advanced = false;
      for (const std::size_t candidateIndex : vertexToEdges(atCurrent)) {
        if (visited[candidateIndex])
          continue;
        currentVertex = firstVertex[candidateIndex].IsSame(currentVertex)
                            ? secondVertex[candidateIndex]
                            : firstVertex[candidateIndex];
        loop.push_back(edges[candidateIndex]);
        visited[candidateIndex] = true;
        advanced = true;
        break;
      }
      if (!advanced) {
        throw Standard_Failure(
            "GroupEdgesIntoLoops: a connected component does not close into a simple loop");
      }
    }
    loops.push_back(std::move(loop));
  }
  return loops;
}

} // namespace aeth
