#include "mate_frame.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <optional>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include <BRepAdaptor_Curve.hxx>
#include <BRepAdaptor_Surface.hxx>
#include <BRepGProp.hxx>
#include <BRep_Tool.hxx>
#include <GProp_GProps.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Vertex.hxx>
#include <gp_Circ.hxx>
#include <gp_Cone.hxx>
#include <gp_Cylinder.hxx>
#include <gp_Dir.hxx>
#include <gp_Lin.hxx>
#include <gp_Pnt.hxx>
#include <gp_Sphere.hxx>

#include "cancel.hpp"
#include "geometry_measures.hpp"
#include "ref_resolution.hpp"
#include "selector_evaluator.hpp"
#include "topology.hpp"

namespace aeth {
namespace {

std::array<double, 3> PointArray(const gp_Pnt& point) { return {point.X(), point.Y(), point.Z()}; }

const char* KindName(const char kind) {
  return kind == 'f' ? "face" : kind == 'e' ? "edge" : "vertex";
}

/// SurfaceClass/CurveClass, dispatched by the query-result entity kind so
/// ResolveMateFrame has one call that answers "what analytic class did this
/// entity resolve to" regardless of whether it is a face, edge, or vertex.
/// Vertices carry no OCCT surface/curve type, so they are always "point".
std::string ClassifyByKind(const char kind, const TopoDS_Shape& shape) {
  if (kind == 'f')
    return SurfaceClass(TopoDS::Face(shape));
  if (kind == 'e')
    return CurveClass(TopoDS::Edge(shape));
  return "point";
}

struct GeometryRule final {
  char requiredKind;
  std::vector<std::string> requiredClasses;
};

// C++ twin of packages/geometry-contracts/src/assembly-endpoint.ts's
// assemblyEndpointGeometryRules and fixtures/assemblies/mate-frame-geometry-classes.json
// — keep all three identical.
const std::unordered_map<std::string, GeometryRule>& GeometryRules() {
  static const std::unordered_map<std::string, GeometryRule> kRules = {
      {"point", {'v', {"point"}}},
      {"line", {'e', {"line"}}},
      {"axis", {'e', {"line"}}},
      {"circle", {'e', {"circle"}}},
      {"plane", {'f', {"plane"}}},
      {"cylinder", {'f', {"cylinder"}}},
      {"cone", {'f', {"cone"}}},
      {"sphere", {'f', {"sphere"}}},
      // coordinate_frame carries no requiredKind/requiredClasses (TS's
      // selectorKind/analyticClasses both undefined): no kernel operation
      // produces a resolvable datum coordinate frame, so it always fails
      // Invalidated regardless of what the selector resolved to.
      {"coordinate_frame", {'\0', {}}},
  };
  return kRules;
}

std::optional<GeometryRule> LookUpRule(const std::string& expectedGeometry) {
  const auto& rules = GeometryRules();
  const auto found = rules.find(expectedGeometry);
  if (found == rules.end())
    throw std::invalid_argument("mate_frame: unknown expectedGeometry \"" + expectedGeometry +
                                "\"");
  if (found->second.requiredClasses.empty())
    return std::nullopt;
  return found->second;
}

/// Deterministic in-plane secondary for any unit `primary` (plan 07 §5): try
/// X, Y, Z in that fixed order and keep the one with the SMALLEST
/// |dot(primary, candidate)| seen so far (strict improvement only, so a tie
/// keeps the earlier candidate) — at least one of X/Y/Z has |dot| <= 1/sqrt(3)
/// < 1, so `raw` below is never near-zero and the result is always defined.
std::array<double, 3> CanonicalSecondary(const std::array<double, 3>& primary) {
  static constexpr std::array<std::array<double, 3>, 3> kCandidates = {{
      {1.0, 0.0, 0.0},
      {0.0, 1.0, 0.0},
      {0.0, 0.0, 1.0},
  }};
  std::size_t bestIndex = 0;
  double bestAbsDot = std::numeric_limits<double>::infinity();
  double bestDot = 0.0;
  for (std::size_t index = 0; index < kCandidates.size(); ++index) {
    const std::array<double, 3>& candidate = kCandidates[index];
    const double dot =
        primary[0] * candidate[0] + primary[1] * candidate[1] + primary[2] * candidate[2];
    const double absDot = std::abs(dot);
    if (absDot < bestAbsDot) {
      bestAbsDot = absDot;
      bestDot = dot;
      bestIndex = index;
    }
  }
  const std::array<double, 3>& chosen = kCandidates[bestIndex];
  const std::array<double, 3> raw = {
      chosen[0] - bestDot * primary[0],
      chosen[1] - bestDot * primary[1],
      chosen[2] - bestDot * primary[2],
  };
  const double norm = std::sqrt(raw[0] * raw[0] + raw[1] * raw[1] + raw[2] * raw[2]);
  return {raw[0] / norm, raw[1] / norm, raw[2] / norm};
}

MateFrame SphereFrame(const TopoDS_Face& face) {
  const BRepAdaptor_Surface surface(face, true);
  const gp_Sphere sphere = surface.Sphere();
  MateFrame frame;
  frame.origin = PointArray(sphere.Location());
  frame.radius = sphere.Radius();
  frame.primary = {1.0, 0.0, 0.0};
  frame.secondary = {0.0, 1.0, 0.0};
  frame.geometry = MateFrameGeometry::Sphere;
  frame.orientationClass = "isotropic";
  return frame;
}

MateFrame ConeFrame(const TopoDS_Face& face) {
  const BRepAdaptor_Surface surface(face, true);
  const gp_Cone cone = surface.Cone();
  MateFrame frame;
  frame.origin = PointArray(cone.Apex());
  frame.primary = Canonicalize(cone.Axis().Direction()).value();
  frame.secondary = CanonicalSecondary(frame.primary);
  frame.radius = ConicalFaceReferenceRadius(face);
  frame.halfAngleRad = cone.SemiAngle();
  frame.geometry = MateFrameGeometry::Cone;
  frame.orientationClass = "undirected-axis";
  return frame;
}

MateFrame CylinderFrame(const TopoDS_Face& face) {
  const BRepAdaptor_Surface surface(face, true);
  MateFrame frame;
  frame.origin = PointArray(surface.Cylinder().Axis().Location());
  frame.primary = SurfaceAxis(face).value();
  frame.secondary = CanonicalSecondary(frame.primary);
  frame.radius = CylindricalFaceRadius(face);
  frame.geometry = MateFrameGeometry::Cylinder;
  frame.orientationClass = "undirected-axis";
  return frame;
}

MateFrame PlaneFrame(const TopoDS_Face& face) {
  const BRepAdaptor_Surface surface(face, true);
  GProp_GProps properties;
  BRepGProp::SurfaceProperties(face, properties);
  MateFrame frame;
  frame.origin = PointArray(properties.CentreOfMass());
  frame.primary = PlanarOutwardNormal(face, surface).value();
  frame.secondary = CanonicalSecondary(frame.primary);
  frame.geometry = MateFrameGeometry::Plane;
  frame.orientationClass = "directed";
  return frame;
}

MateFrame CircleEdgeFrame(const TopoDS_Edge& edge) {
  const BRepAdaptor_Curve curve(edge);
  const gp_Circ circle = curve.Circle();
  MateFrame frame;
  frame.origin = PointArray(circle.Location());
  frame.primary = CurveAxis(edge).value();
  frame.secondary = CanonicalSecondary(frame.primary);
  frame.radius = CircleEdgeRadius(edge);
  frame.geometry = MateFrameGeometry::Axis;
  frame.orientationClass = "undirected-axis";
  return frame;
}

MateFrame LineEdgeFrame(const TopoDS_Edge& edge) {
  const BRepAdaptor_Curve curve(edge);
  MateFrame frame;
  frame.origin = PointArray(curve.Value((curve.FirstParameter() + curve.LastParameter()) / 2.0));
  frame.primary = CurveAxis(edge).value();
  frame.secondary = CanonicalSecondary(frame.primary);
  frame.geometry = MateFrameGeometry::Axis;
  frame.orientationClass = "undirected-axis";
  return frame;
}

MateFrame VertexFrame(const TopoDS_Vertex& vertex) {
  MateFrame frame;
  frame.origin = PointArray(BRep_Tool::Pnt(vertex));
  frame.primary = {1.0, 0.0, 0.0};
  frame.secondary = {0.0, 1.0, 0.0};
  frame.geometry = MateFrameGeometry::Point;
  frame.orientationClass = "isotropic";
  return frame;
}

MateFrame ExtractFrame(const char kind, const std::string& geometryClass,
                       const TopoDS_Shape& shape) {
  if (kind == 'f') {
    const TopoDS_Face face = TopoDS::Face(shape);
    if (geometryClass == "plane")
      return PlaneFrame(face);
    if (geometryClass == "cylinder")
      return CylinderFrame(face);
    if (geometryClass == "cone")
      return ConeFrame(face);
    if (geometryClass == "sphere")
      return SphereFrame(face);
    throw std::invalid_argument("mate_frame: unsupported face geometry class \"" + geometryClass +
                                "\"");
  }
  if (kind == 'e') {
    const TopoDS_Edge edge = TopoDS::Edge(shape);
    if (geometryClass == "line")
      return LineEdgeFrame(edge);
    if (geometryClass == "circle")
      return CircleEdgeFrame(edge);
    throw std::invalid_argument("mate_frame: unsupported edge geometry class \"" + geometryClass +
                                "\"");
  }
  if (kind == 'v')
    return VertexFrame(TopoDS::Vertex(shape));
  throw std::invalid_argument("mate_frame: unsupported entity kind");
}

nlohmann::json Vec3Json(const std::array<double, 3>& v) { return {v[0], v[1], v[2]}; }

const char* GeometryName(const MateFrameGeometry geometry) {
  switch (geometry) {
  case MateFrameGeometry::Point:
    return "point";
  case MateFrameGeometry::Axis:
    return "axis";
  case MateFrameGeometry::Plane:
    return "plane";
  case MateFrameGeometry::Cylinder:
    return "cylinder";
  case MateFrameGeometry::Cone:
    return "cone";
  case MateFrameGeometry::Sphere:
    return "sphere";
  }
  throw std::runtime_error("mate_frame: unreachable MateFrameGeometry value");
}

/// mateFrameSchema's exact shape (@aeth/geometry-contracts assembly-mate-frame.ts):
/// radius/halfAngleRad are OMITTED entirely when absent, never emitted as
/// null — the schema's `.optional()` (no `.nullable()`) only accepts the key
/// being missing.
nlohmann::json MateFrameToJson(const MateFrame& frame) {
  nlohmann::json json = {
      {"origin", Vec3Json(frame.origin)},           {"primary", Vec3Json(frame.primary)},
      {"secondary", Vec3Json(frame.secondary)},     {"geometry", GeometryName(frame.geometry)},
      {"orientationClass", frame.orientationClass}, {"sourceEvidence", frame.sourceEvidence},
  };
  if (frame.radius.has_value())
    json["radius"] = *frame.radius;
  if (frame.halfAngleRad.has_value())
    json["halfAngleRad"] = *frame.halfAngleRad;
  return json;
}

} // namespace

MateFrameResolution ResolveMateFrame(const nlohmann::json& endpointRefSlot,
                                     const std::string& expectedGeometry,
                                     const std::vector<EvaluatedBody>& bodies,
                                     const NamingRegistry& registry,
                                     const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();

  // An endpoint selector is never multi-valued: force arity to "one"
  // regardless of what the input JSON's own "arity" field says (defense in
  // depth against an adversarial or stale frame — the kernel is a trust
  // boundary, per ref_slot.hpp's identical rationale for its slots).
  nlohmann::json forcedRefSlot = endpointRefSlot;
  forcedRefSlot["arity"] = "one";

  const RefResolution ref = ResolveRef(forcedRefSlot, bodies, registry, cancelled);

  MateFrameResolution resolution;
  switch (ref.status) {
  case RefStatus::Empty:
    resolution.status = MateFrameStatus::Missing;
    resolution.message =
        ref.message.empty() ? "endpoint selector resolved to no entities" : ref.message;
    return resolution;

  case RefStatus::Ambiguous:
    resolution.status = MateFrameStatus::Ambiguous;
    resolution.candidates = ref.candidates;
    resolution.message = ref.message;
    return resolution;

  case RefStatus::Resolved: {
    if (ref.entities.size() != 1) {
      // Structurally impossible for a forced arity="one" resolution — kept
      // as an explicit named refusal instead of indexing undefined behavior.
      resolution.status = MateFrameStatus::Invalidated;
      resolution.message = "kernel invariant violated: a forced arity=\"one\" endpoint reference "
                           "resolved to " +
                           std::to_string(ref.entities.size()) + " entities";
      return resolution;
    }
    const QueryEntity& entity = ref.entities.front();
    const std::optional<GeometryRule> rule = LookUpRule(expectedGeometry);
    if (!rule.has_value()) {
      resolution.status = MateFrameStatus::Invalidated;
      resolution.message = "coordinate_frame endpoints are not resolvable: no kernel operation "
                           "currently produces a datum coordinate frame";
      return resolution;
    }
    const char actualKind = entity.kind;
    if (actualKind != rule->requiredKind) {
      resolution.status = MateFrameStatus::Invalidated;
      resolution.message = std::string("endpoint resolved to a ") + KindName(actualKind) +
                           " but expectedGeometry requires a " + KindName(rule->requiredKind);
      return resolution;
    }
    const std::string actualClass = ClassifyByKind(actualKind, entity.shape);
    if (std::find(rule->requiredClasses.begin(), rule->requiredClasses.end(), actualClass) ==
        rule->requiredClasses.end()) {
      resolution.status = MateFrameStatus::Invalidated;
      resolution.message = "endpoint resolved to geometry class \"" + actualClass +
                           "\" which does not satisfy expectedGeometry \"" + expectedGeometry +
                           "\"";
      return resolution;
    }
    MateFrame frame = ExtractFrame(actualKind, actualClass, entity.shape);
    frame.sourceEvidence = DescribeTopologyEvidence(KindName(actualKind), entity.shape);
    resolution.status = MateFrameStatus::Resolved;
    resolution.frame = std::move(frame);
    return resolution;
  }
  }
  throw std::runtime_error("mate_frame: unreachable RefStatus value");
}

nlohmann::json MateFrameResolutionToJson(const MateFrameResolution& resolution) {
  switch (resolution.status) {
  case MateFrameStatus::Resolved:
    return {
        {"status", "resolved"},
        {"frame", MateFrameToJson(resolution.frame.value())},
    };
  case MateFrameStatus::Missing:
    return {
        {"status", "missing"},
        {"message", resolution.message},
    };
  case MateFrameStatus::Ambiguous: {
    nlohmann::json candidates = nlohmann::json::array();
    for (const QueryEntity& candidate : resolution.candidates)
      candidates.push_back(ResolvedEntityToJson(candidate));
    return {
        {"status", "ambiguous"},
        {"candidates", std::move(candidates)},
        {"message", resolution.message},
    };
  }
  case MateFrameStatus::Invalidated:
    return {
        {"status", "invalidated"},
        {"message", resolution.message},
    };
  }
  throw std::runtime_error("mate_frame: unreachable MateFrameStatus value");
}

std::vector<MateFrameResolution>
ResolveMateFrames(const std::vector<MateFrameEndpointRequest>& endpoints,
                  const std::vector<EvaluatedBody>& bodies, const NamingRegistry& registry,
                  const std::atomic_bool& cancelled) {
  std::vector<MateFrameResolution> resolutions;
  resolutions.reserve(endpoints.size());
  for (const MateFrameEndpointRequest& endpoint : endpoints) {
    resolutions.push_back(
        ResolveMateFrame(endpoint.refSlot, endpoint.expectedGeometry, bodies, registry, cancelled));
  }
  return resolutions;
}

} // namespace aeth
