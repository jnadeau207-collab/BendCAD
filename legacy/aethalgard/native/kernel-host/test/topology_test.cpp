// Native unit tests for the AEMB topology evidence builder (topology.hpp/.cpp).
// DescribeTopologyEvidence was extracted out of DescribeTopologySelection so a
// caller already holding a resolved TopoDS_Shape (mate_frame.cpp) can get
// {geometryClass, centroid, axis, radius} evidence without a dense
// body/entityIndex pair. This drives a real create_box and create_cylinder
// program through EvaluateOperations to get genuine planar/cylindrical faces
// and linear/circular edges, then pins:
//
//   1-5. the evidence shape (geometryClass, axis, radius) for a planar face, a
//        cylindrical face, a linear edge, a circular edge, and a vertex;
//   6. an unknown kind string throws std::invalid_argument;
//   7. THE REGRESSION PIN: for every face/edge/vertex of both bodies,
//      DescribeTopologySelection(body, kind, index, cancelled) is nlohmann::
//      json-equal to DescribeTopologyEvidence(kind, <the same shape read
//      through the body's own TopologyShapeMap>) — the refactor changed
//      nothing observable;
//   8. an out-of-range entityIndex still throws std::invalid_argument.
#include <atomic>
#include <cmath>
#include <cstddef>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <vector>

#include <BRepAdaptor_Curve.hxx>
#include <BRepAdaptor_Surface.hxx>
#include <BRep_Tool.hxx>
#include <GeomAbs_CurveType.hxx>
#include <GeomAbs_SurfaceType.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shape.hxx>
#include <TopoDS_Vertex.hxx>
#include <gp_Pln.hxx>
#include <gp_Pnt.hxx>
#include <nlohmann/json.hpp>

#include "geometry.hpp"
#include "topology.hpp"
#include "topology_index_maps.hpp"

namespace {

int g_failures = 0;

void check(const bool condition, const std::string& label) {
  if (condition) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s\n", label.c_str());
    g_failures += 1;
  }
}

const std::string kBoxOp = "aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa";
const std::string kCylinderOp = "bbbbbbbb-2222-4b22-8b22-bbbbbbbbbbbb";

nlohmann::json BoxOperation(const std::string& id, const std::string& bodyId) {
  return {
      {"id", id},
      {"type", "create_box"},
      {"outputBodyId", bodyId},
      {"parameters",
       {{"width", 40.0},
        {"depth", 30.0},
        {"height", 20.0},
        {"placement",
         {{"origin", {0.0, 0.0, 0.0}},
          {"zDirection", {0.0, 0.0, 1.0}},
          {"xDirection", {1.0, 0.0, 0.0}}}}}},
  };
}

nlohmann::json CylinderOperation(const std::string& id, const std::string& bodyId) {
  return {
      {"id", id},
      {"type", "create_cylinder"},
      {"outputBodyId", bodyId},
      {"parameters",
       {{"radius", 10.0},
        {"height", 25.0},
        {"placement",
         {{"origin", {200.0, 0.0, 0.0}},
          {"zDirection", {0.0, 0.0, 1.0}},
          {"xDirection", {1.0, 0.0, 0.0}}}}}},
  };
}

nlohmann::json Program() {
  return nlohmann::json::array({
      BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b"),
      CylinderOperation(kCylinderOp, "00000000-0000-4000-8000-00000000000c"),
  });
}

struct Fixture final {
  aeth::EvaluatedBody box;
  aeth::EvaluatedBody cylinder;
};

Fixture BuildFixture() {
  std::atomic_bool cancelled{false};
  std::vector<aeth::EvaluatedBody> bodies = aeth::EvaluateOperations(Program(), cancelled);
  if (bodies.size() != 2 || bodies[0].operationId != kBoxOp ||
      bodies[1].operationId != kCylinderOp) {
    throw std::runtime_error("fixture: expected the box and the cylinder as two unconsumed bodies");
  }
  return {std::move(bodies[0]), std::move(bodies[1])};
}

TopoDS_Face RequireFace(const aeth::TopologyShapeMap& faces, const GeomAbs_SurfaceType type) {
  for (int index = 1; index <= faces.Extent(); ++index) {
    const TopoDS_Face face = TopoDS::Face(faces(index));
    if (BRepAdaptor_Surface(face, true).GetType() == type)
      return face;
  }
  throw std::runtime_error("fixture: no face of the requested surface type");
}

TopoDS_Edge RequireEdge(const aeth::TopologyShapeMap& edges, const GeomAbs_CurveType type) {
  for (int index = 1; index <= edges.Extent(); ++index) {
    const TopoDS_Edge edge = TopoDS::Edge(edges(index));
    if (BRep_Tool::Degenerated(edge))
      continue;
    if (BRepAdaptor_Curve(edge).GetType() == type)
      return edge;
  }
  throw std::runtime_error("fixture: no edge of the requested curve type");
}

// The box top face, picked by its flat bounding box at z == level (the same
// selector hole_entry_test.cpp / catalog_wave1_test.cpp use), so the evidence
// centroid/axis below can be checked against known analytic values instead of
// merely "some planar face, whichever OCCT enumerates first".
TopoDS_Face FaceAtZ(const TopoDS_Shape& shape, const double level) {
  for (int index = 1;; ++index) {
    aeth::TopologyShapeMap faces;
    aeth::TopologyShapeMap edges;
    aeth::TopologyShapeMap vertices;
    aeth::BuildTopologyIndexMaps(shape, faces, edges, vertices);
    if (index > faces.Extent())
      break;
    const TopoDS_Face face = TopoDS::Face(faces(index));
    BRepAdaptor_Surface surface(face, true);
    if (surface.GetType() != GeomAbs_Plane ||
        std::abs(surface.Plane().Location().Z() - level) > 1e-9)
      continue;
    return face;
  }
  throw std::runtime_error("fixture: no box face at the requested z level");
}

void FaceEvidencePlanar(const Fixture& fixture) {
  std::printf("DescribeTopologyEvidence(face, planar):\n");
  const TopoDS_Face top = FaceAtZ(fixture.box.shape, 20.0);
  const nlohmann::json evidence = aeth::DescribeTopologyEvidence("face", top);
  check(evidence.at("geometryClass").get<std::string>() == "plane", "geometryClass is 'plane'");
  // The box centers X/Y on the placement origin but starts Z at it (a 40x30x20
  // box at origin (0,0,0) spans X:[-20,20] Y:[-15,15] Z:[0,20]), so the top
  // face's centroid is the analytically exact (0, 0, 20).
  const nlohmann::json& centroid = evidence.at("centroid");
  check(centroid.is_array() && centroid.size() == 3 && std::abs(centroid[0].get<double>()) < 1e-6 &&
            std::abs(centroid[1].get<double>()) < 1e-6 &&
            std::abs(centroid[2].get<double>() - 20.0) < 1e-6,
        "centroid is the correct (0, 0, 20)");
  const nlohmann::json& axis = evidence.at("axis");
  check(!axis.is_null() && axis.is_array() && axis.size() == 3 &&
            std::abs(axis[0].get<double>()) < 1e-9 && std::abs(axis[1].get<double>()) < 1e-9 &&
            std::abs(axis[2].get<double>() - 1.0) < 1e-9,
        "axis (the outward normal) is non-null and equals +z");
  check(evidence.at("radius").is_null(), "radius is null");
}

void FaceEvidenceCylindrical(const Fixture& fixture) {
  std::printf("DescribeTopologyEvidence(face, cylindrical):\n");
  aeth::TopologyShapeMap faces;
  aeth::TopologyShapeMap edges;
  aeth::TopologyShapeMap vertices;
  aeth::BuildTopologyIndexMaps(fixture.cylinder.shape, faces, edges, vertices);
  const TopoDS_Face cylindrical = RequireFace(faces, GeomAbs_Cylinder);
  const nlohmann::json evidence = aeth::DescribeTopologyEvidence("face", cylindrical);
  check(evidence.at("geometryClass").get<std::string>() == "cylinder",
        "geometryClass is 'cylinder'");
  check(!evidence.at("axis").is_null(), "axis is non-null");
  const nlohmann::json& radius = evidence.at("radius");
  check(!radius.is_null() && std::abs(radius.get<double>() - 10.0) < 1e-9,
        "radius is non-null and equals the cylinder's 10 mm radius");
}

void EdgeEvidenceLinear(const Fixture& fixture) {
  std::printf("DescribeTopologyEvidence(edge, line):\n");
  aeth::TopologyShapeMap faces;
  aeth::TopologyShapeMap edges;
  aeth::TopologyShapeMap vertices;
  aeth::BuildTopologyIndexMaps(fixture.box.shape, faces, edges, vertices);
  const TopoDS_Edge linear = RequireEdge(edges, GeomAbs_Line);
  const nlohmann::json evidence = aeth::DescribeTopologyEvidence("edge", linear);
  check(evidence.at("geometryClass").get<std::string>() == "line", "geometryClass is 'line'");
  check(!evidence.at("axis").is_null(), "axis is non-null");
  check(evidence.at("radius").is_null(), "radius is null");
}

void EdgeEvidenceCircular(const Fixture& fixture) {
  std::printf("DescribeTopologyEvidence(edge, circle) from the cylinder's cap:\n");
  aeth::TopologyShapeMap faces;
  aeth::TopologyShapeMap edges;
  aeth::TopologyShapeMap vertices;
  aeth::BuildTopologyIndexMaps(fixture.cylinder.shape, faces, edges, vertices);
  const TopoDS_Edge circular = RequireEdge(edges, GeomAbs_Circle);
  const nlohmann::json evidence = aeth::DescribeTopologyEvidence("edge", circular);
  check(evidence.at("geometryClass").get<std::string>() == "circle", "geometryClass is 'circle'");
  check(!evidence.at("axis").is_null(), "axis is non-null");
  const nlohmann::json& radius = evidence.at("radius");
  check(!radius.is_null() && std::abs(radius.get<double>() - 10.0) < 1e-9,
        "radius is non-null and equals the cylinder's 10 mm rim radius");
}

void VertexEvidence(const Fixture& fixture) {
  std::printf("DescribeTopologyEvidence(vertex, point):\n");
  aeth::TopologyShapeMap faces;
  aeth::TopologyShapeMap edges;
  aeth::TopologyShapeMap vertices;
  aeth::BuildTopologyIndexMaps(fixture.box.shape, faces, edges, vertices);
  const nlohmann::json evidence = aeth::DescribeTopologyEvidence("vertex", vertices(1));
  check(evidence.at("geometryClass").get<std::string>() == "point", "geometryClass is 'point'");
  check(evidence.at("measure").get<double>() == 0.0, "measure is exactly 0.0");
  check(evidence.at("axis").is_null(), "axis is null");
  check(evidence.at("radius").is_null(), "radius is null");
}

void UnknownKindThrows(const Fixture& fixture) {
  std::printf("DescribeTopologyEvidence refuses an unknown kind:\n");
  bool threw = false;
  try {
    static_cast<void>(aeth::DescribeTopologyEvidence("solid", fixture.box.shape));
  } catch (const std::invalid_argument&) {
    threw = true;
  }
  check(threw, "kind 'solid' throws std::invalid_argument");
}

// The refactor's actual proof obligation: DescribeTopologySelection resolves
// the same 1-based OCCT indexed map topology.cpp has always used, so reading
// entity `index` through that SAME map and asking DescribeTopologyEvidence for
// it directly must produce a byte-identical JSON value.
void SelectionMatchesEvidenceEverywhere(const aeth::EvaluatedBody& body, const std::string& label) {
  std::printf("%s: DescribeTopologySelection == DescribeTopologyEvidence at every index:\n",
              label.c_str());
  const std::atomic_bool cancelled{false};
  aeth::TopologyShapeMap faces;
  aeth::TopologyShapeMap edges;
  aeth::TopologyShapeMap vertices;
  aeth::BuildTopologyIndexMaps(body.shape, faces, edges, vertices);

  bool facesMatch = true;
  for (int index = 1; index <= faces.Extent(); ++index) {
    const std::size_t entityIndex = static_cast<std::size_t>(index - 1);
    const nlohmann::json viaSelection =
        aeth::DescribeTopologySelection(body, "face", entityIndex, cancelled);
    const nlohmann::json viaEvidence = aeth::DescribeTopologyEvidence("face", faces(index));
    facesMatch = facesMatch && viaSelection == viaEvidence;
  }
  check(facesMatch && faces.Extent() > 0, "every face index agrees");

  bool edgesMatch = true;
  for (int index = 1; index <= edges.Extent(); ++index) {
    const std::size_t entityIndex = static_cast<std::size_t>(index - 1);
    const nlohmann::json viaSelection =
        aeth::DescribeTopologySelection(body, "edge", entityIndex, cancelled);
    const nlohmann::json viaEvidence = aeth::DescribeTopologyEvidence("edge", edges(index));
    edgesMatch = edgesMatch && viaSelection == viaEvidence;
  }
  check(edgesMatch && edges.Extent() > 0, "every edge index agrees");

  bool verticesMatch = true;
  for (int index = 1; index <= vertices.Extent(); ++index) {
    const nlohmann::json viaSelection = aeth::DescribeTopologySelection(
        body, "vertex", static_cast<std::size_t>(index - 1), cancelled);
    const nlohmann::json viaEvidence = aeth::DescribeTopologyEvidence("vertex", vertices(index));
    verticesMatch = verticesMatch && viaSelection == viaEvidence;
  }
  check(verticesMatch && vertices.Extent() > 0, "every vertex index agrees");
}

void SelectionOutOfRangeThrows(const aeth::EvaluatedBody& body, const std::string& label) {
  std::printf("%s: DescribeTopologySelection refuses an out-of-range entityIndex:\n",
              label.c_str());
  const std::atomic_bool cancelled{false};
  aeth::TopologyShapeMap faces;
  aeth::TopologyShapeMap edges;
  aeth::TopologyShapeMap vertices;
  aeth::BuildTopologyIndexMaps(body.shape, faces, edges, vertices);

  const auto expectThrows = [&](const std::string& kind, const std::size_t index,
                                const std::string& kindLabel) {
    bool threw = false;
    try {
      static_cast<void>(aeth::DescribeTopologySelection(body, kind, index, cancelled));
    } catch (const std::invalid_argument&) {
      threw = true;
    }
    check(threw, "an out-of-range " + kindLabel + " entityIndex throws std::invalid_argument");
  };
  expectThrows("face", static_cast<std::size_t>(faces.Extent()), "face");
  expectThrows("edge", static_cast<std::size_t>(edges.Extent()), "edge");
  expectThrows("vertex", static_cast<std::size_t>(vertices.Extent()), "vertex");
}

} // namespace

int main() {
  try {
    const Fixture fixture = BuildFixture();
    FaceEvidencePlanar(fixture);
    FaceEvidenceCylindrical(fixture);
    EdgeEvidenceLinear(fixture);
    EdgeEvidenceCircular(fixture);
    VertexEvidence(fixture);
    UnknownKindThrows(fixture);
    SelectionMatchesEvidenceEverywhere(fixture.box, "box");
    SelectionMatchesEvidenceEverywhere(fixture.cylinder, "cylinder");
    SelectionOutOfRangeThrows(fixture.box, "box");
    SelectionOutOfRangeThrows(fixture.cylinder, "cylinder");
  } catch (const std::exception& error) {
    std::printf("FATAL: unhandled exception: %s\n", error.what());
    return 1;
  }
  if (g_failures > 0) {
    std::printf("%d failure(s)\n", g_failures);
    return 1;
  }
  std::printf("all topology evidence tests passed\n");
  return 0;
}
