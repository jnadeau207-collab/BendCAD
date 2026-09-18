#pragma once

#include <NCollection_IndexedMap.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS_Shape.hxx>

namespace aeth {

using TopologyShapeMap = NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher>;

/**
 * Builds the three dense, 1-based OCCT indexed maps that define every
 * epoch-local topology row in AEMB and topology snapshots. Keeping this helper
 * header-only lets the tessellation native test compare the binary rows against
 * the exact authority topology.cpp uses without introducing another link-time
 * dependency. Outputs are cleared first so reuse can never append stale rows.
 */
inline void BuildTopologyIndexMaps(const TopoDS_Shape& shape, TopologyShapeMap& faces,
                                   TopologyShapeMap& edges, TopologyShapeMap& vertices) {
  faces.Clear();
  edges.Clear();
  vertices.Clear();
  TopExp::MapShapes(shape, TopAbs_FACE, faces);
  TopExp::MapShapes(shape, TopAbs_EDGE, edges);
  TopExp::MapShapes(shape, TopAbs_VERTEX, vertices);
}

} // namespace aeth
