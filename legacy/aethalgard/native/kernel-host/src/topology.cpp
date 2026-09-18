#include "topology.hpp"

#include <cmath>
#include <cstddef>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

#include <BRepGProp.hxx>
#include <BRep_Tool.hxx>
#include <GProp_GProps.hxx>
#include <TopExp.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Vertex.hxx>
#include <gp_Pnt.hxx>

#include "cancel.hpp"
#include "geometry_measures.hpp"
#include "topology_index_maps.hpp"

namespace aeth {
namespace {

nlohmann::json AxisJson(const Axis& axis) {
  if (!axis)
    return nullptr;
  return {(*axis)[0], (*axis)[1], (*axis)[2]};
}

nlohmann::json RadiusJson(const std::optional<double>& radius) {
  if (!radius)
    return nullptr;
  return *radius;
}

Axis EdgeAxis(const TopoDS_Edge& edge) {
  if (BRep_Tool::Degenerated(edge))
    return std::nullopt;
  return CurveAxis(edge);
}

std::optional<double> EdgeRadius(const TopoDS_Edge& edge) {
  if (BRep_Tool::Degenerated(edge))
    return std::nullopt;
  return CurveRadius(edge);
}

void Connect(std::vector<std::vector<std::string>>& adjacency, const std::size_t left,
             const std::string& leftToken, const std::size_t right, const std::string& rightToken) {
  adjacency.at(left).push_back(rightToken);
  adjacency.at(right).push_back(leftToken);
}

nlohmann::json Point(const gp_Pnt& point) { return {point.X(), point.Y(), point.Z()}; }

} // namespace

std::string TopologyEntityToken(const std::uint32_t evaluationEpoch,
                                const std::uint32_t bodyOrdinal, const char kind, const int index) {
  return "te:" + std::to_string(evaluationEpoch) + ":" + std::to_string(bodyOrdinal) + ":" + kind +
         ":" + std::to_string(index);
}

nlohmann::json DescribeTopologySelection(const EvaluatedBody& body, const std::string& kind,
                                         const std::size_t entityIndex,
                                         const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();

  TopologyShapeMap faces;
  TopologyShapeMap edges;
  TopologyShapeMap vertices;
  BuildTopologyIndexMaps(body.shape, faces, edges, vertices);

  if (kind == "face") {
    if (entityIndex >= static_cast<std::size_t>(faces.Extent()))
      throw std::invalid_argument("topologySelection face entityIndex is outside the body");
    return DescribeTopologyEvidence(kind, faces(static_cast<int>(entityIndex) + 1));
  }
  if (kind == "edge") {
    if (entityIndex >= static_cast<std::size_t>(edges.Extent()))
      throw std::invalid_argument("topologySelection edge entityIndex is outside the body");
    return DescribeTopologyEvidence(kind, edges(static_cast<int>(entityIndex) + 1));
  }
  if (kind == "vertex") {
    if (entityIndex >= static_cast<std::size_t>(vertices.Extent()))
      throw std::invalid_argument("topologySelection vertex entityIndex is outside the body");
    return DescribeTopologyEvidence(kind, vertices(static_cast<int>(entityIndex) + 1));
  }
  throw std::invalid_argument("topologySelection kind must be face, edge, or vertex");
}

nlohmann::json DescribeTopologyEvidence(const std::string& kind, const TopoDS_Shape& shape) {
  if (kind == "face") {
    const TopoDS_Face face = TopoDS::Face(shape);
    GProp_GProps properties;
    BRepGProp::SurfaceProperties(face, properties);
    return {
        {"kind", "face"},
        {"geometryClass", SurfaceClass(face)},
        {"measure", std::abs(properties.Mass())},
        {"centroid", Point(properties.CentreOfMass())},
        {"axis", AxisJson(SurfaceAxis(face))},
        {"radius", RadiusJson(SurfaceRadius(face))},
    };
  }
  if (kind == "edge") {
    const TopoDS_Edge edge = TopoDS::Edge(shape);
    GProp_GProps properties;
    BRepGProp::LinearProperties(edge, properties);
    return {
        {"kind", "edge"},
        {"geometryClass", CurveClass(edge)},
        {"measure", std::abs(properties.Mass())},
        {"centroid", Point(properties.CentreOfMass())},
        {"axis", AxisJson(EdgeAxis(edge))},
        {"radius", RadiusJson(EdgeRadius(edge))},
    };
  }
  if (kind == "vertex") {
    const TopoDS_Vertex vertex = TopoDS::Vertex(shape);
    return {
        {"kind", "vertex"}, {"geometryClass", "point"},
        {"measure", 0.0},   {"centroid", Point(BRep_Tool::Pnt(vertex))},
        {"axis", nullptr},  {"radius", nullptr},
    };
  }
  throw std::invalid_argument("topology evidence kind must be face, edge, or vertex");
}

nlohmann::json DescribeTopology(const EvaluatedBody& body, const std::uint32_t evaluationEpoch,
                                const std::uint32_t bodyOrdinal,
                                const std::atomic_bool& cancelled) {
  return DescribeTopology(body, evaluationEpoch, bodyOrdinal, cancelled,
                          [&body](const TopoDS_Shape&) { return body.operationId; });
}

nlohmann::json DescribeTopology(const EvaluatedBody& body, const std::uint32_t evaluationEpoch,
                                const std::uint32_t bodyOrdinal, const std::atomic_bool& cancelled,
                                const ProvenanceResolver& provenance) {
  TopologyShapeMap faces;
  TopologyShapeMap edges;
  TopologyShapeMap vertices;
  BuildTopologyIndexMaps(body.shape, faces, edges, vertices);
  const std::size_t faceCount = static_cast<std::size_t>(faces.Extent());
  const std::size_t edgeCount = static_cast<std::size_t>(edges.Extent());
  const std::size_t vertexCount = static_cast<std::size_t>(vertices.Extent());
  std::vector<std::vector<std::string>> adjacency(faceCount + edgeCount + vertexCount);

  for (int faceIndex = 1; faceIndex <= faces.Extent(); ++faceIndex) {
    if (cancelled.load(std::memory_order_relaxed))
      throw Cancelled();
    TopologyShapeMap incidentEdges;
    TopExp::MapShapes(faces(faceIndex), TopAbs_EDGE, incidentEdges);
    for (int localIndex = 1; localIndex <= incidentEdges.Extent(); ++localIndex) {
      const int edgeIndex = edges.FindIndex(incidentEdges(localIndex));
      if (edgeIndex <= 0)
        throw std::runtime_error("face incidence references an unmapped edge");
      Connect(adjacency, static_cast<std::size_t>(faceIndex - 1),
              TopologyEntityToken(evaluationEpoch, bodyOrdinal, 'f', faceIndex - 1),
              faceCount + static_cast<std::size_t>(edgeIndex - 1),
              TopologyEntityToken(evaluationEpoch, bodyOrdinal, 'e', edgeIndex - 1));
    }
  }
  for (int edgeIndex = 1; edgeIndex <= edges.Extent(); ++edgeIndex) {
    if (cancelled.load(std::memory_order_relaxed))
      throw Cancelled();
    TopologyShapeMap incidentVertices;
    TopExp::MapShapes(edges(edgeIndex), TopAbs_VERTEX, incidentVertices);
    for (int localIndex = 1; localIndex <= incidentVertices.Extent(); ++localIndex) {
      const int vertexIndex = vertices.FindIndex(incidentVertices(localIndex));
      if (vertexIndex <= 0)
        throw std::runtime_error("edge incidence references an unmapped vertex");
      Connect(adjacency, faceCount + static_cast<std::size_t>(edgeIndex - 1),
              TopologyEntityToken(evaluationEpoch, bodyOrdinal, 'e', edgeIndex - 1),
              faceCount + edgeCount + static_cast<std::size_t>(vertexIndex - 1),
              TopologyEntityToken(evaluationEpoch, bodyOrdinal, 'v', vertexIndex - 1));
    }
  }

  nlohmann::json entities = nlohmann::json::array();
  for (int faceIndex = 1; faceIndex <= faces.Extent(); ++faceIndex) {
    if (cancelled.load(std::memory_order_relaxed))
      throw Cancelled();
    const TopoDS_Face face = TopoDS::Face(faces(faceIndex));
    GProp_GProps properties;
    BRepGProp::SurfaceProperties(face, properties);
    entities.push_back({
        {"token", TopologyEntityToken(evaluationEpoch, bodyOrdinal, 'f', faceIndex - 1)},
        {"kind", "face"},
        {"geometryClass", SurfaceClass(face)},
        {"measure", std::abs(properties.Mass())},
        {"centroid", Point(properties.CentreOfMass())},
        {"orientation", Orientation(face.Orientation())},
        {"adjacentTokens", adjacency.at(static_cast<std::size_t>(faceIndex - 1))},
        {"provenanceOperationId", provenance(face)},
        {"axis", AxisJson(SurfaceAxis(face))},
        {"radius", RadiusJson(SurfaceRadius(face))},
    });
  }
  for (int edgeIndex = 1; edgeIndex <= edges.Extent(); ++edgeIndex) {
    if (cancelled.load(std::memory_order_relaxed))
      throw Cancelled();
    const TopoDS_Edge edge = TopoDS::Edge(edges(edgeIndex));
    GProp_GProps properties;
    BRepGProp::LinearProperties(edge, properties);
    entities.push_back({
        {"token", TopologyEntityToken(evaluationEpoch, bodyOrdinal, 'e', edgeIndex - 1)},
        {"kind", "edge"},
        {"geometryClass", CurveClass(edge)},
        {"measure", std::abs(properties.Mass())},
        {"centroid", Point(properties.CentreOfMass())},
        {"orientation", Orientation(edge.Orientation())},
        {"adjacentTokens", adjacency.at(faceCount + static_cast<std::size_t>(edgeIndex - 1))},
        {"provenanceOperationId", provenance(edge)},
        {"axis", AxisJson(EdgeAxis(edge))},
        {"radius", RadiusJson(EdgeRadius(edge))},
    });
  }
  for (int vertexIndex = 1; vertexIndex <= vertices.Extent(); ++vertexIndex) {
    if (cancelled.load(std::memory_order_relaxed))
      throw Cancelled();
    const TopoDS_Vertex vertex = TopoDS::Vertex(vertices(vertexIndex));
    entities.push_back({
        {"token", TopologyEntityToken(evaluationEpoch, bodyOrdinal, 'v', vertexIndex - 1)},
        {"kind", "vertex"},
        {"geometryClass", "point"},
        {"measure", 0.0},
        {"centroid", Point(BRep_Tool::Pnt(vertex))},
        {"orientation", Orientation(vertex.Orientation())},
        {"adjacentTokens",
         adjacency.at(faceCount + edgeCount + static_cast<std::size_t>(vertexIndex - 1))},
        {"provenanceOperationId", provenance(vertex)},
        {"axis", nullptr},
        {"radius", nullptr},
    });
  }
  return {
      {"snapshotId", "ts:" + std::to_string(evaluationEpoch) + ":" + body.bodyId},
      {"evaluationEpoch", evaluationEpoch},
      {"entities", std::move(entities)},
  };
}

} // namespace aeth
