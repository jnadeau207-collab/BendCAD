#include "datum_feature.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include <BRepAdaptor_Curve.hxx>
#include <BRepAdaptor_Surface.hxx>
#include <BRepBuilderAPI_MakeEdge.hxx>
#include <BRepBuilderAPI_MakeFace.hxx>
#include <BRep_Tool.hxx>
#include <GeomAbs_CurveType.hxx>
#include <GeomAbs_SurfaceType.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Vertex.hxx>
#include <gp_Ax1.hxx>
#include <gp_Dir.hxx>
#include <gp_Lin.hxx>
#include <gp_Pln.hxx>
#include <gp_Pnt.hxx>
#include <gp_Trsf.hxx>
#include <gp_Vec.hxx>

#include "body_pool.hpp"
#include "cancel.hpp"
#include "geometry_measures.hpp"
#include "naming_registry.hpp"
#include "ref_slot.hpp"

namespace aeth {
namespace {

// Bounded analytic proxy half-extent for the minted backing shapes (design
// note §2.3, recorded divergence from plan 02's infinite gp_Pln/gp_Lin
// backing: an unbounded TopoDS face/edge poisons every GProp the naming
// substrate computes). Epoch-local presentation only; nothing hashes it.
constexpr double kDatumBackingHalfExtentMm = 1.0e5;

// Plan 02 §2.2: signed datum scalars check |v| <= 1e7 (E_PRIM_DIM_TOO_LARGE
// is doc-model's pre-kernel code; the kernel is a trust boundary and
// re-checks the bound).
constexpr double kMaxDatumMagnitudeMm = 1.0e7;

// Plan 02 kernel-mapping tolerances: axis-on-plane and parallel-normal
// checks use 0.1 degrees; axis-to-plane distance uses 1e-3 mm; two-points
// coincidence uses 1e-6 mm.
constexpr double kSinTenthDegree = 0.0017453283658983088;
constexpr double kCosTenthDegree = 0.9999984769132877;
constexpr double kAxisOnPlaneDistanceMm = 1.0e-3;
constexpr double kCoincidentPointsMm = 1.0e-6;
constexpr double kDegreesToRadians = 0.017453292519943295;
constexpr double kRadiansToDegrees = 57.29577951308232;

void CheckCancellation(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
}

/// E_DATUM_INVALID_REFERENCE (plan 02 §3 failure tables): an attributed
/// INVALID_REQUEST whose `details` carry the fine datum code plus the plan's
/// per-mode diagnostic fields.
[[noreturn]] void FailDatumReference(const std::string& operationId, nlohmann::json details,
                                     const std::string& message) {
  details["datumCode"] = "E_DATUM_INVALID_REFERENCE";
  throw OperationFailure(operationId, "INVALID_REQUEST", message, std::move(details));
}

double FiniteBoundedScalar(const nlohmann::json& parameters, const char* key,
                           const std::string& opLabel) {
  const double value = parameters.at(key).get<double>();
  if (!std::isfinite(value) || std::abs(value) > kMaxDatumMagnitudeMm) {
    throw std::invalid_argument(opLabel + " " + key + " must be finite with |value| <= 1e7 mm");
  }
  return value;
}

/// §2.5 direction canonicalization: flip so the first component with
/// |component| > 1e-9 (checked x, y, z) is positive. Deterministic rotation
/// signs for axes whose parametric sense is arbitrary.
gp_Dir CanonicalizedDir(const gp_Dir& direction) {
  const Axis canonical = Canonicalize(direction);
  if (!canonical.has_value())
    throw std::runtime_error("datum executor could not canonicalize a unit direction");
  return {(*canonical)[0], (*canonical)[1], (*canonical)[2]};
}

gp_Pnt ProjectOntoPlane(const gp_Pln& plane, const gp_Pnt& point) {
  const gp_Dir& normal = plane.Axis().Direction();
  const gp_Vec offset(plane.Location(), point);
  const double signedDistance = offset.Dot(gp_Vec(normal));
  return point.Translated(-signedDistance * gp_Vec(normal));
}

gp_Pnt ProjectOntoLine(const gp_Lin& line, const gp_Pnt& point) {
  const gp_Vec toPoint(line.Location(), point);
  const double along = toPoint.Dot(gp_Vec(line.Direction()));
  return line.Location().Translated(along * gp_Vec(line.Direction()));
}

/// A planar reference face resolved into its plane and OUTWARD normal
/// (plan 05 §5.2 — orientation-corrected, the directed material side).
struct PlanarReference final {
  gp_Pln plane;
  gp_Dir outwardNormal;
};

PlanarReference RequirePlanarFace(const std::string& operationId, const std::string& mode,
                                  const char* slotName, const QueryEntity& entity) {
  const TopoDS_Face face = TopoDS::Face(entity.shape);
  const BRepAdaptor_Surface surface(face, true);
  if (surface.GetType() != GeomAbs_Plane) {
    FailDatumReference(operationId,
                       {{"mode", mode},
                        {"slot", slotName},
                        {"expected", "planar face"},
                        {"actualSurface", SurfaceClass(face)},
                        {"suggestedFix", "pick a flat face or add a datum plane"}},
                       "datum reference " + std::string(slotName) +
                           " resolved to a non-planar face; the selected face cannot define "
                           "this datum");
  }
  const Axis outward = PlanarOutwardNormal(face, surface);
  if (!outward.has_value())
    throw std::runtime_error("datum executor could not derive a planar face's outward normal");
  const gp_Dir normal((*outward)[0], (*outward)[1], (*outward)[2]);
  // Re-anchor the plane on the surface location with the OUTWARD normal so
  // every downstream projection/rotation uses the directed material side, not
  // the surface's arbitrary parametric sense.
  return {gp_Pln(surface.Plane().Location(), normal), normal};
}

/// Resolves one required slot to exactly one entity of `expectedKind` through
/// the shared strict path (design note §2.1).
QueryEntity ResolveSingle(const std::string& operationId, const std::string& opLabel,
                          const char* slotName, const char expectedKind,
                          const nlohmann::json& parameters,
                          const std::vector<EvaluatedBody>& bodies, const NamingRegistry& registry,
                          const std::atomic_bool& cancelled) {
  const RefResolution resolution = ResolveRefSlotStrict(
      operationId, opLabel, slotName, parameters.at(slotName), bodies, registry, cancelled);
  return SingleResolvedEntity(opLabel, slotName, expectedKind, resolution);
}

/// The derived datum frame every mode reduces to (plan 02 kernel mapping
/// step 2): a deterministic anchor point plus a unit direction (the plane
/// normal / the axis direction).
struct DatumFrame final {
  gp_Pnt anchor;
  gp_Dir direction;
};

DatumFrame DerivePlaneFrame(const std::string& operationId, const nlohmann::json& parameters,
                            const std::vector<EvaluatedBody>& bodies,
                            const NamingRegistry& registry, const std::atomic_bool& cancelled) {
  const std::string mode = parameters.at("mode").get<std::string>();
  const gp_Pnt worldOrigin(0.0, 0.0, 0.0);

  if (mode == "offset") {
    const double offset = FiniteBoundedScalar(parameters, "offset", "datum_plane");
    const QueryEntity baseEntity = ResolveSingle(operationId, "datum_plane", "base", 'f',
                                                 parameters, bodies, registry, cancelled);
    const PlanarReference base = RequirePlanarFace(operationId, mode, "base", baseEntity);
    const gp_Pnt anchor =
        ProjectOntoPlane(base.plane, worldOrigin).Translated(offset * gp_Vec(base.outwardNormal));
    return {anchor, base.outwardNormal};
  }

  if (mode == "angled") {
    const double angle = FiniteBoundedScalar(parameters, "angle", "datum_plane");
    const QueryEntity baseEntity = ResolveSingle(operationId, "datum_plane", "base", 'f',
                                                 parameters, bodies, registry, cancelled);
    const PlanarReference base = RequirePlanarFace(operationId, mode, "base", baseEntity);
    const QueryEntity axisEntity = ResolveSingle(operationId, "datum_plane", "axis", 'e',
                                                 parameters, bodies, registry, cancelled);
    const TopoDS_Edge axisEdge = TopoDS::Edge(axisEntity.shape);
    const BRepAdaptor_Curve curve(axisEdge);
    if (curve.GetType() != GeomAbs_Line) {
      FailDatumReference(operationId,
                         {{"mode", mode},
                          {"slot", "axis"},
                          {"expected", "linear edge"},
                          {"actualCurve", CurveClass(axisEdge)},
                          {"suggestedFix", "pick a straight edge or a datum axis"}},
                         "datum_plane axis resolved to a non-linear edge; the rotation axis "
                         "must be a straight line");
    }
    const gp_Lin axisLine = curve.Line();
    const gp_Dir axisDirection = CanonicalizedDir(axisLine.Direction());
    // Axis must LIE ON the base plane: direction perpendicular to the normal
    // within 0.1 degrees AND line-to-plane distance within 1e-3 mm.
    const double alignment = std::abs(gp_Vec(axisDirection).Dot(gp_Vec(base.outwardNormal)));
    if (alignment > kSinTenthDegree) {
      FailDatumReference(
          operationId,
          {{"mode", mode},
           {"slot", "axis"},
           {"expected", "axis on the base plane"},
           {"angleOffDeg", std::asin(std::min(alignment, 1.0)) * kRadiansToDegrees},
           {"suggestedFix", "pick an edge lying on the base plane"}},
          "datum_plane axis is not parallel to the base plane; the rotation axis must lie "
          "on it");
    }
    const double distance = std::abs(
        gp_Vec(base.plane.Location(), axisLine.Location()).Dot(gp_Vec(base.outwardNormal)));
    if (distance > kAxisOnPlaneDistanceMm) {
      FailDatumReference(operationId,
                         {{"mode", mode},
                          {"slot", "axis"},
                          {"expected", "axis on the base plane"},
                          {"distanceMm", distance},
                          {"suggestedFix", "pick an edge lying on the base plane"}},
                         "datum_plane axis does not lie on the base plane");
    }
    const gp_Pnt anchor = ProjectOntoLine(axisLine, worldOrigin);
    gp_Trsf rotation;
    rotation.SetRotation(gp_Ax1(anchor, axisDirection), angle * kDegreesToRadians);
    return {anchor, base.outwardNormal.Transformed(rotation)};
  }

  if (mode == "midplane") {
    const QueryEntity aEntity = ResolveSingle(operationId, "datum_plane", "a", 'f', parameters,
                                              bodies, registry, cancelled);
    const PlanarReference a = RequirePlanarFace(operationId, mode, "a", aEntity);
    const QueryEntity bEntity = ResolveSingle(operationId, "datum_plane", "b", 'f', parameters,
                                              bodies, registry, cancelled);
    const PlanarReference b = RequirePlanarFace(operationId, mode, "b", bEntity);
    // Parallel within 0.1 degrees, sign-insensitive (opposite outward normals
    // of two walls are the common case).
    const double alignment = std::abs(gp_Vec(a.outwardNormal).Dot(gp_Vec(b.outwardNormal)));
    if (alignment < kCosTenthDegree) {
      FailDatumReference(
          operationId,
          {{"mode", mode},
           {"slot", "b"},
           {"expected", "face parallel to a"},
           {"angleOffDeg", std::acos(std::clamp(alignment, -1.0, 1.0)) * kRadiansToDegrees},
           {"suggestedFix", "pick two parallel planar faces"}},
          "datum_plane midplane faces are not parallel");
    }
    const gp_Pnt onA = ProjectOntoPlane(a.plane, worldOrigin);
    const gp_Pnt onB = ProjectOntoPlane(b.plane, worldOrigin);
    const gp_Pnt anchor(0.5 * (onA.X() + onB.X()), 0.5 * (onA.Y() + onB.Y()),
                        0.5 * (onA.Z() + onB.Z()));
    return {anchor, CanonicalizedDir(a.outwardNormal)};
  }

  throw std::invalid_argument("unsupported datum_plane mode: " + mode);
}

DatumFrame DeriveAxisFrame(const std::string& operationId, const nlohmann::json& parameters,
                           const std::vector<EvaluatedBody>& bodies, const NamingRegistry& registry,
                           const std::atomic_bool& cancelled) {
  const std::string mode = parameters.at("mode").get<std::string>();
  const gp_Pnt worldOrigin(0.0, 0.0, 0.0);

  if (mode == "twoPoints") {
    const QueryEntity aEntity =
        ResolveSingle(operationId, "datum_axis", "a", 'v', parameters, bodies, registry, cancelled);
    const QueryEntity bEntity =
        ResolveSingle(operationId, "datum_axis", "b", 'v', parameters, bodies, registry, cancelled);
    const gp_Pnt pa = BRep_Tool::Pnt(TopoDS::Vertex(aEntity.shape));
    const gp_Pnt pb = BRep_Tool::Pnt(TopoDS::Vertex(bEntity.shape));
    const gp_Vec span(pa, pb);
    if (span.Magnitude() < kCoincidentPointsMm) {
      FailDatumReference(operationId,
                         {{"mode", mode},
                          {"slot", "b"},
                          {"reason", "coincident-points"},
                          {"distanceMm", span.Magnitude()},
                          {"suggestedFix", "pick two distinct points"}},
                         "datum_axis two-point references are coincident; they cannot define "
                         "an axis");
    }
    // User intent fixes the sense a -> b: deliberately NO §2.5 flip.
    return {pa, gp_Dir(span)};
  }

  if (mode == "faceNormal") {
    const nlohmann::json& position = parameters.at("position");
    if (!position.is_array() || position.size() != 3)
      throw std::invalid_argument("datum_axis position must be a 3-component point");
    const gp_Pnt point(position.at(0).get<double>(), position.at(1).get<double>(),
                       position.at(2).get<double>());
    for (const double component : {point.X(), point.Y(), point.Z()}) {
      if (!std::isfinite(component) || std::abs(component) > kMaxDatumMagnitudeMm)
        throw std::invalid_argument(
            "datum_axis position components must be finite with |value| <= 1e7 mm");
    }
    const QueryEntity faceEntity = ResolveSingle(operationId, "datum_axis", "face", 'f', parameters,
                                                 bodies, registry, cancelled);
    const TopoDS_Face face = TopoDS::Face(faceEntity.shape);
    const BRepAdaptor_Surface surface(face, true);
    if (surface.GetType() != GeomAbs_Plane) {
      FailDatumReference(operationId,
                         {{"mode", mode},
                          {"slot", "face"},
                          {"reason", "not-planar"},
                          {"actualSurface", SurfaceClass(face)},
                          {"suggestedFix", "pick a flat face"}},
                         "datum_axis face-normal reference is not planar");
    }
    const Axis outward = PlanarOutwardNormal(face, surface);
    if (!outward.has_value())
      throw std::runtime_error("datum executor could not derive a planar face's outward normal");
    const gp_Dir normal((*outward)[0], (*outward)[1], (*outward)[2]);
    // Outward normal, no flip; anchor is the projection of `position` onto
    // the face plane (any distance is legal — the axis is infinite).
    return {ProjectOntoPlane(gp_Pln(surface.Plane().Location(), normal), point), normal};
  }

  if (mode == "cylinderAxis") {
    const QueryEntity faceEntity = ResolveSingle(operationId, "datum_axis", "face", 'f', parameters,
                                                 bodies, registry, cancelled);
    const TopoDS_Face face = TopoDS::Face(faceEntity.shape);
    const BRepAdaptor_Surface surface(face, true);
    gp_Ax1 axis;
    switch (surface.GetType()) {
    case GeomAbs_Cylinder:
      axis = surface.Cylinder().Axis();
      break;
    case GeomAbs_Cone:
      axis = surface.Cone().Axis();
      break;
    case GeomAbs_Torus:
      axis = surface.Torus().Axis();
      break;
    default:
      FailDatumReference(operationId,
                         {{"mode", mode},
                          {"slot", "face"},
                          {"reason", "not-rotational"},
                          {"actualSurface", SurfaceClass(face)},
                          {"suggestedFix", "pick a cylindrical, conical, or toroidal face"}},
                         "datum_axis cylinder-axis reference has no rotation axis");
    }
    const gp_Dir direction = CanonicalizedDir(axis.Direction());
    const gp_Lin line(axis.Location(), direction);
    return {ProjectOntoLine(line, worldOrigin), direction};
  }

  throw std::invalid_argument("unsupported datum_axis mode: " + mode);
}

} // namespace

void EvaluateDatumPlane(const nlohmann::json& operation, BodyPool& pool, NamingRegistry* registry,
                        const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  const std::string operationId = operation.at("id").get<std::string>();
  if (registry == nullptr) {
    // Design note §1: every datum mode carries a required ref and the minted
    // synthetic entity lives in the registry, so the registry-less
    // evaluate_document path (replay cache included) refuses fail-closed —
    // the fillet-v2 registry-guard precedent, attributed by ExecuteOperation.
    throw std::invalid_argument(
        "unsupported operation: datum_plane requires the naming registry; evaluate with a "
        "registry-threaded replay state");
  }
  const std::vector<EvaluatedBody> bodies = pool.PeekVisibleBodies();
  const DatumFrame frame =
      DerivePlaneFrame(operationId, operation.at("parameters"), bodies, *registry, cancelled);
  CheckCancellation(cancelled);
  // Bounded analytic backing proxy centered on the anchor (design note §2.3):
  // the gp_Pln's own UV origin is the anchor, so the patch centroid IS the
  // anchor and the record's geometry key needs no measured mass.
  BRepBuilderAPI_MakeFace backing(gp_Pln(frame.anchor, frame.direction), -kDatumBackingHalfExtentMm,
                                  kDatumBackingHalfExtentMm, -kDatumBackingHalfExtentMm,
                                  kDatumBackingHalfExtentMm);
  if (!backing.IsDone())
    throw std::runtime_error("datum plane backing face construction failed");
  registry->RegisterDatumEntity(operationId, "plane", backing.Face(), frame.anchor, cancelled);
}

void EvaluateDatumAxis(const nlohmann::json& operation, BodyPool& pool, NamingRegistry* registry,
                       const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  const std::string operationId = operation.at("id").get<std::string>();
  if (registry == nullptr) {
    throw std::invalid_argument(
        "unsupported operation: datum_axis requires the naming registry; evaluate with a "
        "registry-threaded replay state");
  }
  const std::vector<EvaluatedBody> bodies = pool.PeekVisibleBodies();
  const DatumFrame frame =
      DeriveAxisFrame(operationId, operation.at("parameters"), bodies, *registry, cancelled);
  CheckCancellation(cancelled);
  // Bounded segment proxy centered on the anchor (parameter range symmetric
  // about 0 on gp_Lin(anchor, direction), so the centroid IS the anchor).
  BRepBuilderAPI_MakeEdge backing(gp_Lin(frame.anchor, frame.direction), -kDatumBackingHalfExtentMm,
                                  kDatumBackingHalfExtentMm);
  if (!backing.IsDone())
    throw std::runtime_error("datum axis backing edge construction failed");
  registry->RegisterDatumEntity(operationId, "axis", backing.Edge(), frame.anchor, cancelled);
}

} // namespace aeth
