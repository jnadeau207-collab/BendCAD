#include "geometry.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <limits>
#include <list>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <sstream>
#include <stdexcept>
#include <string>
#include <system_error>
#include <thread>
#include <unordered_map>

#ifdef _WIN32
#include <windows.h>
#else
#include <fcntl.h>
#include <unistd.h>
#endif

#include <BRepAdaptor_CompCurve.hxx>
#include <BRepAdaptor_Curve.hxx>
#include <BRepAdaptor_Surface.hxx>
#include <BRepAlgoAPI_BooleanOperation.hxx>
#include <BRepAlgoAPI_Common.hxx>
#include <BRepAlgoAPI_Cut.hxx>
#include <BRepAlgoAPI_Fuse.hxx>
#include <BRepBndLib.hxx>
#include <BRepBuilderAPI_Copy.hxx>
#include <BRepBuilderAPI_MakeEdge.hxx>
#include <BRepBuilderAPI_MakeFace.hxx>
#include <BRepBuilderAPI_MakePolygon.hxx>
#include <BRepBuilderAPI_MakeSolid.hxx>
#include <BRepBuilderAPI_MakeWire.hxx>
#include <BRepBuilderAPI_Sewing.hxx>
#include <BRepBuilderAPI_Transform.hxx>
#include <BRepBuilderAPI_TransitionMode.hxx>
#include <BRepCheck_Analyzer.hxx>
#include <BRepExtrema_DistShapeShape.hxx>
#include <BRepFilletAPI_MakeChamfer.hxx>
#include <BRepFilletAPI_MakeFillet.hxx>
#include <BRepGProp.hxx>
#include <BRepLib.hxx>
#include <BRepOffsetAPI_DraftAngle.hxx>
#include <BRepOffsetAPI_MakeDraft.hxx>
#include <BRepOffsetAPI_MakeOffset.hxx>
#include <BRepOffsetAPI_MakeOffsetShape.hxx>
#include <BRepOffsetAPI_MakePipeShell.hxx>
#include <BRepOffsetAPI_MakeThickSolid.hxx>
#include <BRepOffsetAPI_ThruSections.hxx>
#include <BRepOffset_Mode.hxx>
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepPrimAPI_MakeCone.hxx>
#include <BRepPrimAPI_MakeCylinder.hxx>
#include <BRepPrimAPI_MakePrism.hxx>
#include <BRepPrimAPI_MakeRevol.hxx>
#include <BRepPrimAPI_MakeSphere.hxx>
#include <BRepPrimAPI_MakeTorus.hxx>
#include <BRepPrimAPI_MakeWedge.hxx>
#include <BRepTools.hxx>
#include <BRepTools_History.hxx>
#include <BRepTools_WireExplorer.hxx>
#include <BRep_Builder.hxx>
#include <BRep_Tool.hxx>
#include <Bnd_Box.hxx>
#include <GProp_GProps.hxx>
#include <GeomAPI_Interpolate.hxx>
#include <GeomAbs_JoinType.hxx>
#include <Geom_BSplineCurve.hxx>
#include <IFSelect_ReturnStatus.hxx>
#include <NCollection_DataMap.hxx>
#include <NCollection_HArray1.hxx>
#include <NCollection_IndexedMap.hxx>
#include <NCollection_List.hxx>
#include <NCollection_Sequence.hxx>
#include <Precision.hxx>
#include <STEPCAFControl_Reader.hxx>
#include <STEPCAFControl_Writer.hxx>
#include <STEPControl_Reader.hxx>
#include <STEPControl_StepModelType.hxx>
#include <STEPControl_Writer.hxx>
#include <ShapeFix_Solid.hxx>
#include <ShapeUpgrade_UnifySameDomain.hxx>
#include <Standard_Failure.hxx>
#include <TDF_Label.hxx>
#include <TDataStd_Name.hxx>
#include <TDocStd_Document.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopAbs_State.hxx>
#include <TopExp.hxx>
#include <TopExp_Explorer.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Compound.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shell.hxx>
#include <TopoDS_Solid.hxx>
#include <TopoDS_Vertex.hxx>
#include <TopoDS_Wire.hxx>
#include <XCAFApp_Application.hxx>
#include <XCAFDoc_DocumentTool.hxx>
#include <XCAFDoc_ShapeTool.hxx>
#include <gp_Ax1.hxx>
#include <gp_Ax2.hxx>
#include <gp_Ax3.hxx>
#include <gp_Circ.hxx>
#include <gp_Dir.hxx>
#include <gp_Elips.hxx>
#include <gp_Lin.hxx>
#include <gp_Pln.hxx>
#include <gp_Pnt.hxx>
#include <gp_Trsf.hxx>
#include <gp_Vec.hxx>

#include "body_pool.hpp"
#include "bounded_feasibility.hpp"
#include "build_manifest.hpp"
#include "cancel.hpp"
#include "datum_feature.hpp"
#include "electrical_routing_feature.hpp"
#include "element_names.hpp"
#include "hole_entry.hpp"
#include "local_operation_history.hpp"
#include "mold_tooling_feature.hpp"
#include "naming_registry.hpp"
#include "operation_hash.hpp"
#include "ref_resolution.hpp"
#include "ref_slot.hpp"
#include "selector_evaluator.hpp"
#include "sha256.hpp"
#include "sheet_metal_feature.hpp"
#include "shell_feature.hpp"
#include "step_atomic_write.hpp"
#include "surfacing_feature.hpp"

namespace aeth {
namespace {

gp_Vec JsonVector(const nlohmann::json& value) {
  if (!value.is_array() || value.size() != 3)
    throw std::invalid_argument("expected vector3");
  return {value.at(0).get<double>(), value.at(1).get<double>(), value.at(2).get<double>()};
}

int Count(const TopoDS_Shape& shape, const TopAbs_ShapeEnum kind) {
  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> map;
  TopExp::MapShapes(shape, kind, map);
  return map.Extent();
}

void CheckCancellation(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
}

std::filesystem::path Utf8Path(const std::string& value) {
#ifdef _WIN32
  const auto* first = reinterpret_cast<const char8_t*>(value.data());
  return std::filesystem::path(std::u8string(first, value.size()));
#else
  return std::filesystem::path(value);
#endif
}

// Parses and orthonormalizes an operation placement into a right-handed OCCT
// frame anchored at the placement origin. Every primitive uses the base-center
// convention: the origin is the center of the shape's base profile (bottom
// face for extrusion-like primitives, geometric center for the sphere).
gp_Ax2 PlacementFrame(const nlohmann::json& placement) {
  const gp_Vec origin = JsonVector(placement.at("origin"));
  gp_Vec zDirection = JsonVector(placement.at("zDirection"));
  gp_Vec xDirection = JsonVector(placement.at("xDirection"));
  if (zDirection.Magnitude() < 1e-9 || xDirection.Magnitude() < 1e-9) {
    throw std::invalid_argument("placement directions must be non-zero");
  }
  zDirection.Normalize();
  xDirection -= zDirection * xDirection.Dot(zDirection);
  if (xDirection.Magnitude() < 1e-9) {
    throw std::invalid_argument("placement directions must not be parallel");
  }
  xDirection.Normalize();
  return {gp_Pnt(origin.X(), origin.Y(), origin.Z()), gp_Dir(zDirection), gp_Dir(xDirection)};
}

EvaluatedBody FinishBodyShape(const nlohmann::json& operation, TopoDS_Shape shape,
                              const char* primitiveName) {
  if (shape.IsNull() || Count(shape, TopAbs_SOLID) == 0)
    throw std::runtime_error(std::string("OCCT produced no solid ") + primitiveName);
  if (shape.ShapeType() == TopAbs_SOLID)
    BRepLib::OrientClosedSolid(TopoDS::Solid(shape));
  EvaluatedBody body;
  body.bodyId = operation.at("outputBodyId").get<std::string>();
  body.operationId = operation.at("id").get<std::string>();
  body.shape = std::move(shape);
  body.probes = ProbeShape(body.shape);
  if (!body.probes.valid)
    throw std::runtime_error(std::string("OCCT produced an invalid ") + primitiveName);
  return body;
}

EvaluatedBody FinishSolidBody(const nlohmann::json& operation, TopoDS_Solid solid,
                              const char* primitiveName) {
  return FinishBodyShape(operation, solid, primitiveName);
}

/**
 * Finishes a SHEET body. `FinishBodyShape` demands at least one solid, which is
 * correct for every solid feature and wrong for a surface result: a surface
 * loft encloses no volume by definition, so requiring one would refuse exactly
 * the geometry the author asked for.
 */
EvaluatedBody FinishSheetBody(const nlohmann::json& operation, TopoDS_Shape shape,
                              const char* primitiveName) {
  if (shape.IsNull())
    throw std::runtime_error(std::string("OCCT produced no ") + primitiveName + " surface");
  EvaluatedBody body;
  body.bodyId = operation.at("outputBodyId").get<std::string>();
  body.operationId = operation.at("id").get<std::string>();
  body.shape = std::move(shape);
  body.probes = ProbeShape(body.shape);
  return body;
}

EvaluatedBody EvaluateBox(const nlohmann::json& operation, const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const double width = parameters.at("width").get<double>();
  const double depth = parameters.at("depth").get<double>();
  const double height = parameters.at("height").get<double>();
  if (!(width > 0.0 && depth > 0.0 && height > 0.0)) {
    throw std::invalid_argument("box dimensions must be positive");
  }

  const gp_Ax2 base = PlacementFrame(parameters.at("placement"));
  const gp_Vec xDirection(base.XDirection());
  const gp_Vec yDirection(base.YDirection());
  const gp_Pnt corner =
      base.Location().Translated((-0.5 * width) * xDirection + (-0.5 * depth) * yDirection);
  const gp_Ax2 frame(corner, base.Direction(), base.XDirection());
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepPrimAPI_MakeBox maker;
  maker.Init(frame, width, depth, height);
  maker.Build(progress->Start());
  CheckCancellation(cancelled);
  return FinishSolidBody(operation, maker.Solid(), "box");
}

EvaluatedBody EvaluateCylinder(const nlohmann::json& operation, const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const double radius = parameters.at("radius").get<double>();
  const double height = parameters.at("height").get<double>();
  if (!(radius > 0.0 && height > 0.0)) {
    throw std::invalid_argument("cylinder dimensions must be positive");
  }

  // Base-center convention: the placement origin is the center of the base
  // circle and the cylinder extrudes along the placement z direction.
  const gp_Ax2 frame = PlacementFrame(parameters.at("placement"));
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepPrimAPI_MakeCylinder maker(frame, radius, height);
  maker.Build(progress->Start());
  CheckCancellation(cancelled);
  return FinishSolidBody(operation, maker.Solid(), "cylinder");
}

EvaluatedBody EvaluateSphere(const nlohmann::json& operation, const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const double radius = parameters.at("radius").get<double>();
  if (!(radius > 0.0)) {
    throw std::invalid_argument("sphere radius must be positive");
  }

  // The sphere is centered at the placement origin. The full frame still
  // participates so the seam and pole parameterization replay
  // deterministically under a rotated placement.
  const gp_Ax2 frame = PlacementFrame(parameters.at("placement"));
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepPrimAPI_MakeSphere maker(frame, radius);
  maker.Build(progress->Start());
  CheckCancellation(cancelled);
  return FinishSolidBody(operation, maker.Solid(), "sphere");
}

EvaluatedBody EvaluateCone(const nlohmann::json& operation, const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const double radiusBottom = parameters.at("radiusBottom").get<double>();
  const double radiusTop = parameters.at("radiusTop").get<double>();
  const double height = parameters.at("height").get<double>();
  if (!(radiusBottom > 0.0 && radiusTop >= 0.0 && height > 0.0)) {
    throw std::invalid_argument("cone dimensions must be positive (top radius may be zero)");
  }
  const double equalRadiusTolerance = 1.0e-9 * std::max(1.0, std::abs(radiusBottom));
  if (std::abs(radiusTop - radiusBottom) <= equalRadiusTolerance) {
    throw OperationFailure(
        operation.at("id").get<std::string>(), "INVALID_REQUEST",
        "The top and bottom are the same size — use a cylinder for that.",
        {{"primitiveCode", "E_PRIM_CONE_EQUAL_RADII"},
         {"radius1", radiusBottom},
         {"radius2", radiusTop},
         {"suggestedFix",
          {{"op", "primitive-cylinder"}, {"radius", radiusBottom}, {"height", height}}}});
  }

  // Base-center convention: the placement origin is the center of the bottom
  // circle and the cone rises along the placement z direction.
  const gp_Ax2 frame = PlacementFrame(parameters.at("placement"));
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepPrimAPI_MakeCone maker(frame, radiusBottom, radiusTop, height);
  maker.Build(progress->Start());
  CheckCancellation(cancelled);
  return FinishSolidBody(operation, maker.Solid(), "cone");
}

EvaluatedBody EvaluateTorus(const nlohmann::json& operation, const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const double majorRadius = parameters.at("majorRadius").get<double>();
  const double minorRadius = parameters.at("minorRadius").get<double>();
  if (!(majorRadius > 0.0 && minorRadius > 0.0 && minorRadius < majorRadius)) {
    throw std::invalid_argument("torus minor radius must be positive and below the major radius");
  }

  // The ring is centered on the placement origin; its axis is the placement z
  // direction (like the cylinder's).
  const gp_Ax2 frame = PlacementFrame(parameters.at("placement"));
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepPrimAPI_MakeTorus maker(frame, majorRadius, minorRadius);
  maker.Build(progress->Start());
  CheckCancellation(cancelled);
  return FinishSolidBody(operation, maker.Solid(), "torus");
}

EvaluatedBody EvaluateWedge(const nlohmann::json& operation, const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const double width = parameters.at("width").get<double>();
  const double depth = parameters.at("depth").get<double>();
  const double height = parameters.at("height").get<double>();
  const double topWidth = parameters.at("topWidth").get<double>();
  if (!(width > 0.0 && depth > 0.0 && height > 0.0 && topWidth >= 0.0 && topWidth <= width)) {
    throw std::invalid_argument("wedge dimensions must be positive with 0 <= topWidth <= width");
  }

  // The near corner sits at the placement origin; the top face (at height) is
  // narrowed in x to topWidth, sloping one face.
  const gp_Ax2 frame = PlacementFrame(parameters.at("placement"));
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepPrimAPI_MakeWedge maker(frame, width, depth, height, topWidth);
  maker.Build(progress->Start());
  CheckCancellation(cancelled);
  return FinishSolidBody(operation, maker.Solid(), "wedge");
}

// A profile evaluated for the current request only. Profiles are epoch-local
// kernel state: they produce no body packet, no probes entry, and never
// outlive the evaluation that built them (ADR-003 epoch-local identity).
struct EvaluatedProfile final {
  // `face` remains the primary face for legacy consumers that need one outer
  // wire (loft/sweep). `shape` is the authoritative profile payload and may be
  // a compound of coplanar faces when a sketch contains disjoint material
  // regions or nested islands. Extrude/revolve consume the shape directly.
  TopoDS_Face face;
  TopoDS_Shape shape;
  std::vector<TopoDS_Face> faces;
  // The associative plane frame that produced this profile. A downstream
  // feature may consume a semantic axis/path instead of inventing a world
  // frame in the renderer, so this stays with the evaluated profile.
  gp_Ax2 frame;
  gp_Dir normal;
  // The profile plane's origin (placement location). Sweep enforces that its
  // section sits at the spine's first point, so it needs the section's anchor.
  gp_Pnt origin;
  // Durable region identity, parallel to `faces` (same index correspondence).
  // Empty when the profile did not come from a multi-region sketch (e.g. a
  // legacy create_profile or a single-face source) — existing positional
  // EvaluatedProfile{...} call sites that predate this field correctly leave
  // it default-empty rather than needing to change. Each key is derived from
  // the sorted, deduplicated set of sketch entity ids that bound that region
  // (outer loop plus any attached holes) — never a positional/array index —
  // so a consumer that asks for a specific region by key fails closed
  // (ReferenceMissing) rather than silently reattaching to a different
  // region when the sketch's region order changes.
  std::vector<std::string> regionIds;
};

// A point on the profile plane expressed through the placement frame:
// origin + u * xDirection + v * yDirection.
gp_Pnt PlanePoint(const gp_Ax2& frame, const double u, const double v) {
  return frame.Location().Translated(u * gp_Vec(frame.XDirection()) +
                                     v * gp_Vec(frame.YDirection()));
}

TopoDS_Wire RectangleWire(const gp_Ax2& frame, const double width, const double depth) {
  const double w = 0.5 * width;
  const double d = 0.5 * depth;
  // Counter-clockwise as seen from the +normal side, so the face material
  // lies inside the contour and the prism extrudes a positive solid.
  BRepBuilderAPI_MakePolygon polygon(PlanePoint(frame, -w, -d), PlanePoint(frame, w, -d),
                                     PlanePoint(frame, w, d), PlanePoint(frame, -w, d),
                                     /*Close=*/true);
  if (!polygon.IsDone())
    throw std::runtime_error("rectangle profile wire construction failed");
  return polygon.Wire();
}

TopoDS_Wire CircleWire(const gp_Ax2& frame, const double radius) {
  BRepBuilderAPI_MakeEdge edge(gp_Circ(frame, radius));
  if (!edge.IsDone())
    throw std::runtime_error("circle profile edge construction failed");
  BRepBuilderAPI_MakeWire wire(edge.Edge());
  if (!wire.IsDone())
    throw std::runtime_error("circle profile wire construction failed");
  return wire.Wire();
}

// Four straight segments joined by four quarter-circle arcs, ordered
// counter-clockwise. Each corner circle is parameterized around the profile
// normal, so BRepBuilderAPI_MakeEdge(circle, from, to) trims the arc in the
// counter-clockwise direction that matches the contour.
TopoDS_Wire RoundedRectangleWire(const gp_Ax2& frame, const double width, const double depth,
                                 const double cornerRadius) {
  const double w = 0.5 * width;
  const double d = 0.5 * depth;
  const double r = cornerRadius;
  const auto cornerCircle = [&frame, r](const double u, const double v) {
    return gp_Circ(gp_Ax2(PlanePoint(frame, u, v), frame.Direction(), frame.XDirection()), r);
  };

  BRepBuilderAPI_MakeWire wire;
  const auto addSegment = [&wire](const gp_Pnt& from, const gp_Pnt& to) {
    BRepBuilderAPI_MakeEdge edge(from, to);
    if (!edge.IsDone())
      throw std::runtime_error("rounded rectangle segment construction failed");
    wire.Add(edge.Edge());
  };
  const auto addArc = [&wire](const gp_Circ& circle, const gp_Pnt& from, const gp_Pnt& to) {
    BRepBuilderAPI_MakeEdge edge(circle, from, to);
    if (!edge.IsDone())
      throw std::runtime_error("rounded rectangle arc construction failed");
    wire.Add(edge.Edge());
  };

  addSegment(PlanePoint(frame, -w + r, -d), PlanePoint(frame, w - r, -d));
  addArc(cornerCircle(w - r, -d + r), PlanePoint(frame, w - r, -d), PlanePoint(frame, w, -d + r));
  addSegment(PlanePoint(frame, w, -d + r), PlanePoint(frame, w, d - r));
  addArc(cornerCircle(w - r, d - r), PlanePoint(frame, w, d - r), PlanePoint(frame, w - r, d));
  addSegment(PlanePoint(frame, w - r, d), PlanePoint(frame, -w + r, d));
  addArc(cornerCircle(-w + r, d - r), PlanePoint(frame, -w + r, d), PlanePoint(frame, -w, d - r));
  addSegment(PlanePoint(frame, -w, d - r), PlanePoint(frame, -w, -d + r));
  addArc(cornerCircle(-w + r, -d + r), PlanePoint(frame, -w, -d + r),
         PlanePoint(frame, -w + r, -d));

  if (!wire.IsDone())
    throw std::runtime_error("rounded rectangle profile wire construction failed");
  return wire.Wire();
}

// A stadium: a straight run along x capped by a semicircle (radius width/2) at
// each short end, traced counter-clockwise from the +normal side.
TopoDS_Wire SlotWire(const gp_Ax2& frame, const double length, const double width) {
  const double r = 0.5 * width;       // cap radius
  const double sx = 0.5 * length - r; // half-length of the straight run (> 0 since length > width)
  const auto capCircle = [&frame, r](const double u, const double v) {
    return gp_Circ(gp_Ax2(PlanePoint(frame, u, v), frame.Direction(), frame.XDirection()), r);
  };
  BRepBuilderAPI_MakeWire wire;
  const auto addSegment = [&wire](const gp_Pnt& from, const gp_Pnt& to) {
    BRepBuilderAPI_MakeEdge edge(from, to);
    if (!edge.IsDone())
      throw std::runtime_error("slot segment construction failed");
    wire.Add(edge.Edge());
  };
  const auto addArc = [&wire](const gp_Circ& circle, const gp_Pnt& from, const gp_Pnt& to) {
    BRepBuilderAPI_MakeEdge edge(circle, from, to);
    if (!edge.IsDone())
      throw std::runtime_error("slot arc construction failed");
    wire.Add(edge.Edge());
  };
  addSegment(PlanePoint(frame, -sx, -r), PlanePoint(frame, sx, -r));
  addArc(capCircle(sx, 0.0), PlanePoint(frame, sx, -r), PlanePoint(frame, sx, r));
  addSegment(PlanePoint(frame, sx, r), PlanePoint(frame, -sx, r));
  addArc(capCircle(-sx, 0.0), PlanePoint(frame, -sx, r), PlanePoint(frame, -sx, -r));
  if (!wire.IsDone())
    throw std::runtime_error("slot profile wire construction failed");
  return wire.Wire();
}

// A regular polygon: `sides` vertices evenly spaced on a circle of `radius`,
// the first on the placement +x axis, ordered counter-clockwise.
TopoDS_Wire PolygonWire(const gp_Ax2& frame, const int sides, const double radius) {
  const double twoPi = 6.283185307179586;
  BRepBuilderAPI_MakePolygon polygon;
  for (int vertex = 0; vertex < sides; ++vertex) {
    const double angle = twoPi * static_cast<double>(vertex) / static_cast<double>(sides);
    polygon.Add(PlanePoint(frame, radius * std::cos(angle), radius * std::sin(angle)));
  }
  polygon.Close();
  if (!polygon.IsDone())
    throw std::runtime_error("polygon profile wire construction failed");
  return polygon.Wire();
}

// An ellipse centered on the placement origin, semi-axes radiusX along x and
// radiusY along y. gp_Elips requires major >= minor, so the ellipse frame's x
// axis is oriented along whichever placement axis is the larger radius.
TopoDS_Wire EllipseWire(const gp_Ax2& frame, const double radiusX, const double radiusY) {
  gp_Ax2 ellipseFrame = frame;
  double major = radiusX;
  double minor = radiusY;
  if (radiusY > radiusX) {
    ellipseFrame = gp_Ax2(frame.Location(), frame.Direction(), frame.YDirection());
    major = radiusY;
    minor = radiusX;
  }
  BRepBuilderAPI_MakeEdge edge(gp_Elips(ellipseFrame, major, minor));
  if (!edge.IsDone())
    throw std::runtime_error("ellipse profile edge construction failed");
  BRepBuilderAPI_MakeWire wire(edge.Edge());
  if (!wire.IsDone())
    throw std::runtime_error("ellipse profile wire construction failed");
  return wire.Wire();
}

EvaluatedProfile EvaluateProfile(const nlohmann::json& operation,
                                 const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const gp_Ax2 frame = PlacementFrame(parameters.at("placement"));
  const auto& shape = parameters.at("shape");
  const std::string kind = shape.at("kind").get<std::string>();
  CheckCancellation(cancelled);

  TopoDS_Wire wire;
  if (kind == "rectangle") {
    const double width = shape.at("width").get<double>();
    const double depth = shape.at("depth").get<double>();
    if (!(width > 0.0 && depth > 0.0))
      throw std::invalid_argument("rectangle profile dimensions must be positive");
    wire = RectangleWire(frame, width, depth);
  } else if (kind == "circle") {
    const double radius = shape.at("radius").get<double>();
    if (!(radius > 0.0))
      throw std::invalid_argument("circle profile radius must be positive");
    wire = CircleWire(frame, radius);
  } else if (kind == "roundedRectangle") {
    const double width = shape.at("width").get<double>();
    const double depth = shape.at("depth").get<double>();
    const double cornerRadius = shape.at("cornerRadius").get<double>();
    if (!(width > 0.0 && depth > 0.0))
      throw std::invalid_argument("rounded rectangle profile dimensions must be positive");
    if (!(cornerRadius > 0.0 && 2.0 * cornerRadius < std::min(width, depth))) {
      throw std::invalid_argument(
          "rounded rectangle cornerRadius must be strictly below min(width, depth) / 2");
    }
    wire = RoundedRectangleWire(frame, width, depth, cornerRadius);
  } else if (kind == "slot") {
    const double length = shape.at("length").get<double>();
    const double width = shape.at("width").get<double>();
    if (!(width > 0.0 && length > width))
      throw std::invalid_argument("slot length must be greater than its positive width");
    wire = SlotWire(frame, length, width);
  } else if (kind == "polygon") {
    const int sides = shape.at("sides").get<int>();
    const double radius = shape.at("circumradius").get<double>();
    if (!(sides >= 3 && radius > 0.0))
      throw std::invalid_argument("polygon needs at least three sides and a positive circumradius");
    wire = PolygonWire(frame, sides, radius);
  } else if (kind == "ellipse") {
    const double radiusX = shape.at("radiusX").get<double>();
    const double radiusY = shape.at("radiusY").get<double>();
    if (!(radiusX > 0.0 && radiusY > 0.0))
      throw std::invalid_argument("ellipse profile radii must be positive");
    wire = EllipseWire(frame, radiusX, radiusY);
  } else {
    throw std::invalid_argument("unsupported profile shape: " + kind);
  }

  // Wire closure is a hard validity requirement for a face-producing
  // profile: an open contour would extrude to a shell, not a solid.
  TopoDS_Vertex first;
  TopoDS_Vertex last;
  TopExp::Vertices(wire, first, last);
  if (first.IsNull() || last.IsNull() || !first.IsSame(last))
    throw std::runtime_error("profile wire is not closed");

  CheckCancellation(cancelled);
  BRepBuilderAPI_MakeFace faceMaker(gp_Pln(gp_Ax3(frame)), wire, /*Inside=*/true);
  if (!faceMaker.IsDone())
    throw std::runtime_error("profile face construction failed");
  const TopoDS_Face face = faceMaker.Face();
  if (!BRepCheck_Analyzer(face, false).IsValid())
    throw std::runtime_error("OCCT produced an invalid profile face");
  return {face, face, {face}, frame, frame.Direction(), frame.Location()};
}

// ---------------------------------------------------------------------------
// The sketch region (CAP-038): a solved constraint sketch becomes a profile.
//
// A `sketch` produces no body, but a closed region of its boundary entities is
// a planar face — the same EvaluatedProfile create_profile produces. Inserting
// it into the profile map under the SKETCH's own operation id is what makes
// extrude, revolve, sweep and loft consume a sketch with no change to any of
// them: every one of them resolves its profile by operation id through that one
// map.
// ---------------------------------------------------------------------------

// Plan 02's degeneracy floor, mirrored from `sketch.ts`. A gap at or above it
// is an OPEN contour and is refused; below it there is no gap at all. Nothing
// here closes a contour by widening this — ADR-015 §2 forbids exactly that.
constexpr double kSketchMinSize = 1e-6;
constexpr double kSketchPi = 3.141592653589793238462643383279502884;
constexpr double kSketchDegreesToRadians = 0.017453292519943295;

// The sketch-plane basis rule (plan 02, normative), rule 1: the fixed bases for
// the three world planes. Written as the table it is, because the u/v/w triple
// is what sketch portability rests on and a derivation would obscure it.
bool WorldPlaneAxes(const std::string& world, gp_Ax2& into) {
  if (world == "xy") {
    into = gp_Ax2(gp_Pnt(0, 0, 0), gp_Dir(0, 0, 1), gp_Dir(1, 0, 0));
    return true;
  }
  if (world == "xz") {
    into = gp_Ax2(gp_Pnt(0, 0, 0), gp_Dir(0, -1, 0), gp_Dir(1, 0, 0));
    return true;
  }
  if (world == "yz") {
    into = gp_Ax2(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0), gp_Dir(0, 1, 0));
    return true;
  }
  return false;
}

// The sketch-plane basis rule, rules 2 and 4: u is world +x projected onto the
// plane (world +y when the normal is within 0.999 of +x), and the frame origin
// is the orthogonal projection of the WORLD origin onto the plane.
//
// Rule 4 is why this is not `faceSketchFrame` from the renderer: that one
// deliberately departs to the face centroid, because a `create_profile` shape is
// CENTRED on its placement. A sketch's entities carry their own (u, v), so the
// plan's rule applies unmodified and both sides must agree on it exactly or the
// contour lands somewhere the person did not draw it.
gp_Ax2 PlanarFaceSketchAxes(const gp_Pln& plane) {
  const gp_Dir normal = plane.Axis().Direction();
  const gp_Dir seed =
      std::abs(normal.Dot(gp_Dir(1, 0, 0))) <= 0.999 ? gp_Dir(1, 0, 0) : gp_Dir(0, 1, 0);
  const gp_Vec projected = gp_Vec(seed) - gp_Vec(normal) * normal.Dot(seed);
  const gp_Dir u(projected);
  // The world origin projected onto the plane: O − ((O − L)·n) n.
  const gp_Pnt worldOrigin(0, 0, 0);
  const double signedDistance = gp_Vec(plane.Location(), worldOrigin).Dot(gp_Vec(normal));
  const gp_Pnt frameOrigin = worldOrigin.Translated(gp_Vec(normal) * -signedDistance);
  return gp_Ax2(frameOrigin, normal, u);
}

// Resolves a sketch's `plane` ref slot to its (u, v, w) frame.
//
// A world plane is NOT topology — no body owns a face for it — so it is read
// from the ref's own AST source rather than routed through the selector
// evaluator, whose `world` source is deferred precisely because synthesizing an
// entity with no body and no lineage name would be the wrong answer. Everything
// else is a real face and resolves exactly as the mirror plane does.
gp_Ax2 SketchPlaneAxes(const nlohmann::json& operation, const std::vector<EvaluatedBody>& bodies,
                       NamingRegistry* registry, const std::atomic_bool& cancelled) {
  const std::string operationId = operation.at("id").get<std::string>();
  const nlohmann::json& slot = operation.at("parameters").at("plane");
  if (slot.contains("ast")) {
    const nlohmann::json& ast = slot.at("ast");
    const auto scope = ast.find("scope");
    // A single world source and nothing else: `faces(world(xy))`. A world
    // source mixed with body sources, or narrowed by filters, is a query over
    // topology and belongs to the evaluator, which refuses it today.
    if (scope != ast.end() && scope->is_array() && scope->size() == 1 &&
        scope->front().is_object() && scope->front().value("source", std::string()) == "world") {
      const std::string world = scope->front().value("world", std::string());
      gp_Ax2 axes;
      if (WorldPlaneAxes(world, axes))
        return axes;
      throw OperationFailure(operationId, "INVALID_REQUEST",
                             "A sketch needs a plane; world(" + world +
                                 ") names an axis or a point, not one.");
    }
  }

  if (registry == nullptr)
    throw std::invalid_argument(
        "unsupported operation: a sketch on a model face requires the naming registry; evaluate "
        "with a registry-threaded replay state");
  const RefResolution resolution =
      ResolveRefSlotStrict(operationId, "sketch", "plane", slot, bodies, *registry, cancelled);
  const QueryEntity planeEntity = SingleResolvedEntity("sketch", "plane", 'f', resolution);
  const BRepAdaptor_Surface surface(TopoDS::Face(planeEntity.shape), true);
  if (surface.GetType() != GeomAbs_Plane) {
    throw OperationFailure(operationId, "INVALID_REQUEST",
                           "A sketch needs a flat face — the one it is drawn on is curved.");
  }
  return PlanarFaceSketchAxes(surface.Plane());
}

// One boundary entity's solved parameter vector, or its authored values.
//
// The vector order is the solver seam's canonical per-kind order
// (`sketch_solver.hpp`), and the TS twin of this lookup lives in
// `sketch.ts` (`solvedValues`). A vector of the wrong length is IGNORED rather
// than partially applied — half a solution describes a shape that is neither
// what was drawn nor what was solved.
const nlohmann::json* SolvedSketchValues(const nlohmann::json& parameters, const std::string& eid,
                                         const std::size_t expected) {
  const auto solution = parameters.find("solution");
  if (solution == parameters.end() || !solution->is_object())
    return nullptr;
  const auto entities = solution->find("entities");
  if (entities == solution->end() || !entities->is_array())
    return nullptr;
  for (const auto& entry : *entities) {
    if (!entry.is_object() || entry.value("eid", std::string()) != eid)
      continue;
    const auto values = entry.find("values");
    if (values == entry.end() || !values->is_array() || values->size() != expected)
      return nullptr;
    return &(*values);
  }
  return nullptr;
}

struct SketchRegionPoint final {
  double u{};
  double v{};
};

double SketchGap(const SketchRegionPoint& a, const SketchRegionPoint& b) {
  return std::hypot(b.u - a.u, b.v - a.v);
}

void RegisterSketchConstructionEdges(const nlohmann::json& operation,
                                     const std::vector<EvaluatedBody>& bodies,
                                     NamingRegistry* registry, const std::atomic_bool& cancelled) {
  if (registry == nullptr)
    return;
  const nlohmann::json& parameters = operation.at("parameters");
  const gp_Ax2 frame = SketchPlaneAxes(operation, bodies, registry, cancelled);
  std::vector<std::pair<std::string, TopoDS_Shape>> edges;
  for (const nlohmann::json& entity : parameters.at("entities")) {
    if (!entity.is_object() || !entity.value("construction", false) ||
        entity.value("kind", std::string()) != "line")
      continue;
    const std::string eid = entity.at("eid").get<std::string>();
    const nlohmann::json* solved = SolvedSketchValues(parameters, eid, 4);
    const auto point = [&](const std::size_t offset, const char* key) {
      if (solved != nullptr)
        return PlanePoint(frame, (*solved)[offset].get<double>(),
                          (*solved)[offset + 1].get<double>());
      return PlanePoint(frame, entity.at(key).at(0).get<double>(),
                        entity.at(key).at(1).get<double>());
    };
    BRepBuilderAPI_MakeEdge maker(point(0, "p1"), point(2, "p2"));
    if (!maker.IsDone() || BRepAdaptor_Curve(maker.Edge()).FirstParameter() ==
                               BRepAdaptor_Curve(maker.Edge()).LastParameter())
      throw OperationFailure(operation.at("id").get<std::string>(), "INVALID_REQUEST",
                             "A construction axis line has zero length.",
                             {{"code", "E_SKETCH_CONSTRUCTION_EDGE_DEGENERATE"}, {"eid", eid}});
    edges.emplace_back(eid, maker.Edge());
  }
  registry->RegisterSketchEdges(operation.at("id").get<std::string>(), "construction-edge",
                                "construction", edges, cancelled);
}

// One boundary curve, resolved to plane coordinates. `circle` carries no
// endpoints because it closes on itself.
struct SketchRegionSegment final {
  enum class Kind { Line, Arc, Circle, Ellipse, Spline };
  Kind kind{Kind::Line};
  std::string eid;
  SketchRegionPoint start;
  SketchRegionPoint end;
  SketchRegionPoint center;
  double radius{};
  double radiusX{};
  double radiusY{};
  double rotation{};
  double startAngle{};
  double endAngle{};
  bool ccw{true};
  std::vector<SketchRegionPoint> points;
  bool closed{false};
  bool construction{false};
};

struct SketchRegionLoop final {
  std::vector<SketchRegionSegment> segments;
  std::vector<SketchRegionPoint> samples;
  double signedArea{};
  int depth{};
  bool hole{false};
};

SketchRegionPoint ArcEndpoint(const SketchRegionPoint& center, const double radius,
                              const double degrees) {
  const double radians = degrees * kSketchDegreesToRadians;
  return {center.u + radius * std::cos(radians), center.v + radius * std::sin(radians)};
}

SketchRegionPoint SegmentStart(const SketchRegionSegment& segment) {
  if (segment.kind == SketchRegionSegment::Kind::Circle) {
    return {segment.center.u + segment.radius, segment.center.v};
  }
  if (segment.kind == SketchRegionSegment::Kind::Ellipse) {
    const double radians = segment.rotation * kSketchDegreesToRadians;
    return {segment.center.u + segment.radiusX * std::cos(radians),
            segment.center.v + segment.radiusX * std::sin(radians)};
  }
  if (segment.kind == SketchRegionSegment::Kind::Spline && !segment.points.empty()) {
    return segment.points.front();
  }
  return segment.start;
}

SketchRegionPoint SegmentEnd(const SketchRegionSegment& segment) {
  if (segment.kind == SketchRegionSegment::Kind::Circle ||
      segment.kind == SketchRegionSegment::Kind::Ellipse) {
    return SegmentStart(segment);
  }
  if (segment.kind == SketchRegionSegment::Kind::Spline && !segment.points.empty()) {
    return segment.closed ? segment.points.front() : segment.points.back();
  }
  return segment.end;
}

SketchRegionSegment ReverseSegment(const SketchRegionSegment& segment) {
  SketchRegionSegment reversed = segment;
  if (segment.kind == SketchRegionSegment::Kind::Line ||
      segment.kind == SketchRegionSegment::Kind::Arc) {
    reversed.start = segment.end;
    reversed.end = segment.start;
    std::swap(reversed.startAngle, reversed.endAngle);
    reversed.ccw = !segment.ccw;
  } else if (segment.kind == SketchRegionSegment::Kind::Spline) {
    std::reverse(reversed.points.begin(), reversed.points.end());
  }
  return reversed;
}

std::vector<SketchRegionPoint> SampleRegionSegment(const SketchRegionSegment& segment) {
  std::vector<SketchRegionPoint> points;
  if (segment.kind == SketchRegionSegment::Kind::Line) {
    return {segment.start, segment.end};
  }
  if (segment.kind == SketchRegionSegment::Kind::Spline) {
    if (segment.points.size() < 3)
      throw std::runtime_error("sketch spline region has fewer than three points");
    occ::handle<NCollection_HArray1<gp_Pnt>> controlPoints =
        new NCollection_HArray1<gp_Pnt>(1, static_cast<int>(segment.points.size()));
    for (std::size_t index = 0; index < segment.points.size(); ++index) {
      controlPoints->SetValue(static_cast<int>(index) + 1,
                              gp_Pnt(segment.points[index].u, segment.points[index].v, 0.0));
    }
    GeomAPI_Interpolate interpolate(controlPoints, segment.closed, 1.0e-7);
    try {
      interpolate.Perform();
    } catch (const Standard_Failure&) {
      throw std::runtime_error("sketch spline sampling interpolation failed");
    }
    if (!interpolate.IsDone())
      throw std::runtime_error("sketch spline sampling interpolation failed");
    const occ::handle<Geom_BSplineCurve> curve = interpolate.Curve();
    const int samples = std::max(32, curve->NbKnots() * 24);
    points.reserve(static_cast<std::size_t>(samples) + 1);
    for (int index = 0; index <= samples; ++index) {
      const double parameter =
          curve->FirstParameter() +
          (curve->LastParameter() - curve->FirstParameter()) * static_cast<double>(index) / samples;
      const gp_Pnt point = curve->Value(parameter);
      points.push_back({point.X(), point.Y()});
    }
    return points;
  }
  if (segment.kind == SketchRegionSegment::Kind::Circle ||
      segment.kind == SketchRegionSegment::Kind::Ellipse) {
    constexpr int samples = 96;
    for (int index = 0; index <= samples; ++index) {
      const double angle = 2.0 * kSketchPi * static_cast<double>(index) / samples;
      if (segment.kind == SketchRegionSegment::Kind::Circle) {
        points.push_back({segment.center.u + segment.radius * std::cos(angle),
                          segment.center.v + segment.radius * std::sin(angle)});
      } else {
        const double radians = segment.rotation * kSketchDegreesToRadians;
        const double c = std::cos(radians);
        const double s = std::sin(radians);
        const double u = segment.radiusX * std::cos(angle);
        const double v = segment.radiusY * std::sin(angle);
        points.push_back({segment.center.u + u * c - v * s, segment.center.v + u * s + v * c});
      }
    }
    return points;
  }
  const double start = segment.startAngle * kSketchDegreesToRadians;
  const double end = segment.endAngle * kSketchDegreesToRadians;
  const double full = 2.0 * kSketchPi;
  auto normalize = [full](double value) {
    const double normalized = std::fmod(value, full);
    return normalized < 0.0 ? normalized + full : normalized;
  };
  const double sweep = segment.ccw ? normalize(end - start) : -normalize(start - end);
  const int count = std::max(8, static_cast<int>(std::ceil(std::abs(sweep) / (kSketchPi / 24.0))));
  for (int index = 0; index <= count; ++index) {
    const double angle = start + sweep * static_cast<double>(index) / count;
    points.push_back({segment.center.u + segment.radius * std::cos(angle),
                      segment.center.v + segment.radius * std::sin(angle)});
  }
  return points;
}

double RegionPolygonArea(const std::vector<SketchRegionPoint>& points) {
  double area = 0.0;
  if (points.size() < 3)
    return 0.0;
  for (std::size_t index = 0; index < points.size(); ++index) {
    const auto& a = points[index];
    const auto& b = points[(index + 1) % points.size()];
    area += a.u * b.v - b.u * a.v;
  }
  return area / 2.0;
}

bool RegionPointInPolygon(const SketchRegionPoint& point,
                          const std::vector<SketchRegionPoint>& polygon) {
  bool inside = false;
  if (polygon.size() < 3)
    return false;
  for (std::size_t index = 0, previous = polygon.size() - 1; index < polygon.size();
       previous = index++) {
    const auto& current = polygon[index];
    const auto& prior = polygon[previous];
    if ((current.v > point.v) != (prior.v > point.v)) {
      const double x =
          (prior.u - current.u) * (point.v - current.v) / (prior.v - current.v) + current.u;
      if (point.u < x)
        inside = !inside;
    }
  }
  return inside;
}

bool RegionEdgesCross(const SketchRegionPoint& a1, const SketchRegionPoint& a2,
                      const SketchRegionPoint& b1, const SketchRegionPoint& b2) {
  const auto cross = [](const SketchRegionPoint& a, const SketchRegionPoint& b,
                        const SketchRegionPoint& c) {
    return (b.u - a.u) * (c.v - a.v) - (b.v - a.v) * (c.u - a.u);
  };
  const double c1 = cross(a1, a2, b1);
  const double c2 = cross(a1, a2, b2);
  const double c3 = cross(b1, b2, a1);
  const double c4 = cross(b1, b2, a2);
  const auto closeEnough = [](const SketchRegionPoint& a, const SketchRegionPoint& b) {
    return SketchGap(a, b) < kSketchMinSize;
  };
  if (closeEnough(a1, b1) || closeEnough(a1, b2) || closeEnough(a2, b1) || closeEnough(a2, b2))
    return false;
  return ((c1 > 0.0) != (c2 > 0.0)) && ((c3 > 0.0) != (c4 > 0.0));
}

// Deterministic planar arrangement for sketch boundaries. The first authored
// segment seeds a loop, but every subsequent segment is chosen by its solved
// endpoint, so independently ordered loops, holes, and compound entities all
// use one semantic lowerer.
std::vector<SketchRegionLoop>
SketchClosedRegions(const nlohmann::json& parameters, const gp_Ax2& frame,
                    const std::vector<EvaluatedBody>& bodies, NamingRegistry* registry,
                    const std::string& operationId, const std::atomic_bool& cancelled,
                    std::string& refusal, std::vector<SketchRegionSegment>* outSegments = nullptr) {
  refusal.clear();
  std::vector<SketchRegionSegment> segments;
  const auto& entities = parameters.at("entities");
  const auto pointFromJson = [](const nlohmann::json& value) -> SketchRegionPoint {
    return {value.at(0).get<double>(), value.at(1).get<double>()};
  };
  const auto solvedPoint = [&](const nlohmann::json& entity, const std::string& eid,
                               const std::size_t expected, const std::size_t offset,
                               const char* key) -> SketchRegionPoint {
    const nlohmann::json* solved = SolvedSketchValues(parameters, eid, expected);
    if (solved != nullptr)
      return {(*solved)[offset].get<double>(), (*solved)[offset + 1].get<double>()};
    return pointFromJson(entity.at(key));
  };
  const auto addLine = [&](const std::string& eid, const SketchRegionPoint& a,
                           const SketchRegionPoint& b) {
    SketchRegionSegment line;
    line.kind = SketchRegionSegment::Kind::Line;
    line.eid = eid;
    line.start = a;
    line.end = b;
    segments.push_back(std::move(line));
  };
  for (const auto& entity : entities) {
    if (!entity.is_object() || entity.value("construction", false))
      continue;
    const std::string kind = entity.value("kind", std::string());
    const std::string eid = entity.value("eid", std::string());
    if (kind == "point") {
      refusal = "a point cannot bound a region";
      return {};
    }
    if (kind == "line") {
      addLine(eid, solvedPoint(entity, eid, 4, 0, "p1"), solvedPoint(entity, eid, 4, 2, "p2"));
      continue;
    }
    if (kind == "polyline") {
      const auto* solved = SolvedSketchValues(parameters, eid, entity.at("points").size() * 2);
      std::vector<SketchRegionPoint> points;
      for (std::size_t index = 0; index < entity.at("points").size(); ++index) {
        points.push_back(solved != nullptr
                             ? SketchRegionPoint{(*solved)[index * 2].get<double>(),
                                                 (*solved)[index * 2 + 1].get<double>()}
                             : pointFromJson(entity.at("points")[index]));
      }
      for (std::size_t index = 0; index + 1 < points.size(); ++index)
        addLine(eid + ":" + std::to_string(index), points[index], points[index + 1]);
      if (entity.value("closed", false) && points.size() > 1)
        addLine(eid + ":close", points.back(), points.front());
      continue;
    }
    if (kind == "rectangle") {
      const nlohmann::json* solved = SolvedSketchValues(parameters, eid, 5);
      const SketchRegionPoint position =
          solved != nullptr
              ? SketchRegionPoint{(*solved)[0].get<double>(), (*solved)[1].get<double>()}
              : pointFromJson(entity.at("position"));
      const double width =
          solved != nullptr ? (*solved)[2].get<double>() : entity.at("width").get<double>();
      const double height =
          solved != nullptr ? (*solved)[3].get<double>() : entity.at("height").get<double>();
      const double rotation =
          solved != nullptr ? (*solved)[4].get<double>() : entity.value("rotation", 0.0);
      const bool centered = entity.value("mode", std::string("corner")) == "center";
      const double minU = centered ? -width / 2.0 : 0.0;
      const double minV = centered ? -height / 2.0 : 0.0;
      const double radians = rotation * kSketchDegreesToRadians;
      const double c = std::cos(radians);
      const double s = std::sin(radians);
      std::vector<SketchRegionPoint> points;
      const std::array<SketchRegionPoint, 4> locals = {
          SketchRegionPoint{minU, minV},
          SketchRegionPoint{minU + width, minV},
          SketchRegionPoint{minU + width, minV + height},
          SketchRegionPoint{minU, minV + height},
      };
      for (const SketchRegionPoint& local : locals) {
        points.push_back(
            {position.u + local.u * c - local.v * s, position.v + local.u * s + local.v * c});
      }
      for (std::size_t index = 0; index < points.size(); ++index)
        addLine(eid + ":" + std::to_string(index), points[index],
                points[(index + 1) % points.size()]);
      continue;
    }
    if (kind == "circle") {
      const nlohmann::json* solved = SolvedSketchValues(parameters, eid, 3);
      SketchRegionSegment circle;
      circle.kind = SketchRegionSegment::Kind::Circle;
      circle.eid = eid;
      circle.center = solved != nullptr ? SketchRegionPoint{(*solved)[0].get<double>(),
                                                            (*solved)[1].get<double>()}
                                        : pointFromJson(entity.at("center"));
      circle.radius =
          solved != nullptr ? (*solved)[2].get<double>() : entity.at("radius").get<double>();
      segments.push_back(std::move(circle));
      continue;
    }
    if (kind == "arc-center") {
      const nlohmann::json* solved = SolvedSketchValues(parameters, eid, 5);
      SketchRegionSegment arc;
      arc.kind = SketchRegionSegment::Kind::Arc;
      arc.eid = eid;
      arc.center = solved != nullptr
                       ? SketchRegionPoint{(*solved)[0].get<double>(), (*solved)[1].get<double>()}
                       : pointFromJson(entity.at("center"));
      arc.radius =
          solved != nullptr ? (*solved)[2].get<double>() : entity.at("radius").get<double>();
      arc.startAngle =
          solved != nullptr ? (*solved)[3].get<double>() : entity.at("startAngle").get<double>();
      arc.endAngle =
          solved != nullptr ? (*solved)[4].get<double>() : entity.at("endAngle").get<double>();
      arc.ccw = entity.value("ccw", true);
      arc.start = ArcEndpoint(arc.center, arc.radius, arc.startAngle);
      arc.end = ArcEndpoint(arc.center, arc.radius, arc.endAngle);
      segments.push_back(std::move(arc));
      continue;
    }
    if (kind == "arc-three-point") {
      const nlohmann::json* solved = SolvedSketchValues(parameters, eid, 6);
      const auto pointAt = [&](std::size_t offset, const char* key) {
        return solved != nullptr ? SketchRegionPoint{(*solved)[offset].get<double>(),
                                                     (*solved)[offset + 1].get<double>()}
                                 : pointFromJson(entity.at(key));
      };
      const SketchRegionPoint p1 = pointAt(0, "p1");
      const SketchRegionPoint p2 = pointAt(2, "p2");
      const SketchRegionPoint p3 = pointAt(4, "p3");
      const double area = (p1.u - p2.u) * (p2.v - p3.v) - (p2.u - p3.u) * (p1.v - p2.v);
      if (std::abs(area) < 1e-12) {
        refusal = "a three-point arc has collinear points";
        return {};
      }
      const double twice = 2.0 * area;
      const double p1s = p1.u * p1.u + p1.v * p1.v;
      const double p2s = p2.u * p2.u + p2.v * p2.v;
      const double p3s = p3.u * p3.u + p3.v * p3.v;
      SketchRegionSegment arc;
      arc.kind = SketchRegionSegment::Kind::Arc;
      arc.eid = eid;
      arc.center = {(p1s * (p2.v - p3.v) + p2s * (p3.v - p1.v) + p3s * (p1.v - p2.v)) / twice,
                    (p1s * (p3.u - p2.u) + p2s * (p1.u - p3.u) + p3s * (p2.u - p1.u)) / twice};
      arc.radius = SketchGap(arc.center, p1);
      arc.start = p1;
      arc.end = p3;
      arc.startAngle =
          std::atan2(p1.v - arc.center.v, p1.u - arc.center.u) / kSketchDegreesToRadians;
      arc.endAngle = std::atan2(p3.v - arc.center.v, p3.u - arc.center.u) / kSketchDegreesToRadians;
      arc.ccw = (p2.u - p1.u) * (p3.v - p2.v) - (p2.v - p1.v) * (p3.u - p2.u) > 0.0;
      segments.push_back(std::move(arc));
      continue;
    }
    if (kind == "ellipse") {
      const nlohmann::json* solved = SolvedSketchValues(parameters, eid, 5);
      SketchRegionSegment ellipse;
      ellipse.kind = SketchRegionSegment::Kind::Ellipse;
      ellipse.eid = eid;
      ellipse.center = solved != nullptr ? SketchRegionPoint{(*solved)[0].get<double>(),
                                                             (*solved)[1].get<double>()}
                                         : pointFromJson(entity.at("center"));
      ellipse.radiusX =
          solved != nullptr ? (*solved)[2].get<double>() : entity.at("radiusX").get<double>();
      ellipse.radiusY =
          solved != nullptr ? (*solved)[3].get<double>() : entity.at("radiusY").get<double>();
      ellipse.rotation =
          solved != nullptr ? (*solved)[4].get<double>() : entity.value("rotation", 0.0);
      segments.push_back(std::move(ellipse));
      continue;
    }
    if (kind == "polygon") {
      const nlohmann::json* solved = SolvedSketchValues(parameters, eid, 5);
      const SketchRegionPoint center =
          solved != nullptr
              ? SketchRegionPoint{(*solved)[0].get<double>(), (*solved)[1].get<double>()}
              : pointFromJson(entity.at("center"));
      const int sides = solved != nullptr
                            ? static_cast<int>(std::llround((*solved)[2].get<double>()))
                            : entity.at("sides").get<int>();
      const double radius =
          solved != nullptr ? (*solved)[3].get<double>() : entity.at("circumradius").get<double>();
      const double rotation =
          solved != nullptr ? (*solved)[4].get<double>() : entity.value("rotation", 0.0);
      for (int index = 0; index < sides; ++index) {
        const double a = (rotation + 360.0 * index / sides) * kSketchDegreesToRadians;
        const double b = (rotation + 360.0 * (index + 1) / sides) * kSketchDegreesToRadians;
        addLine(eid + ":" + std::to_string(index),
                {center.u + radius * std::cos(a), center.v + radius * std::sin(a)},
                {center.u + radius * std::cos(b), center.v + radius * std::sin(b)});
      }
      continue;
    }
    if (kind == "slot") {
      const nlohmann::json* solved = SolvedSketchValues(parameters, eid, 5);
      const SketchRegionPoint p1 = solved != nullptr ? SketchRegionPoint{(*solved)[0].get<double>(),
                                                                         (*solved)[1].get<double>()}
                                                     : pointFromJson(entity.at("p1"));
      const SketchRegionPoint p2 = solved != nullptr ? SketchRegionPoint{(*solved)[2].get<double>(),
                                                                         (*solved)[3].get<double>()}
                                                     : pointFromJson(entity.at("p2"));
      const double width =
          solved != nullptr ? (*solved)[4].get<double>() : entity.at("width").get<double>();
      const double length = SketchGap(p1, p2);
      if (length < kSketchMinSize) {
        refusal = "a slot needs a centreline with length";
        return {};
      }
      const double radius = width / 2.0;
      const double nx = -(p2.v - p1.v) / length * radius;
      const double ny = (p2.u - p1.u) / length * radius;
      const SketchRegionPoint p1b{p1.u - nx, p1.v - ny};
      const SketchRegionPoint p2b{p2.u - nx, p2.v - ny};
      const SketchRegionPoint p2t{p2.u + nx, p2.v + ny};
      const SketchRegionPoint p1t{p1.u + nx, p1.v + ny};
      addLine(eid + ":lower", p1b, p2b);
      SketchRegionSegment endArc;
      endArc.kind = SketchRegionSegment::Kind::Arc;
      endArc.eid = eid + ":end-cap";
      endArc.center = p2;
      endArc.radius = radius;
      const double normalAngle = std::atan2(ny, nx) / kSketchDegreesToRadians;
      endArc.startAngle = normalAngle - 180.0;
      endArc.endAngle = normalAngle;
      endArc.ccw = true;
      endArc.start = p2b;
      endArc.end = p2t;
      segments.push_back(std::move(endArc));
      addLine(eid + ":upper", p2t, p1t);
      SketchRegionSegment startArc;
      startArc.kind = SketchRegionSegment::Kind::Arc;
      startArc.eid = eid + ":start-cap";
      startArc.center = p1;
      startArc.radius = radius;
      startArc.startAngle = normalAngle;
      startArc.endAngle = normalAngle + 180.0;
      startArc.ccw = true;
      startArc.start = p1t;
      startArc.end = p1b;
      segments.push_back(std::move(startArc));
      continue;
    }
    if (kind == "spline") {
      const nlohmann::json* solved =
          SolvedSketchValues(parameters, eid, entity.at("points").size() * 2);
      SketchRegionSegment spline;
      spline.kind = SketchRegionSegment::Kind::Spline;
      spline.eid = eid;
      spline.closed = entity.value("closed", false);
      for (std::size_t index = 0; index < entity.at("points").size(); ++index) {
        spline.points.push_back(solved != nullptr
                                    ? SketchRegionPoint{(*solved)[index * 2].get<double>(),
                                                        (*solved)[index * 2 + 1].get<double>()}
                                    : pointFromJson(entity.at("points")[index]));
      }
      segments.push_back(std::move(spline));
      continue;
    }
    refusal = "a " + kind + " cannot bound a region";
    return {};
  }

  // Projected geometry is associative: the sketch stores only the source
  // operation-level reference, and this lowerer resolves that reference on
  // every replay. No sampled coordinates are persisted in the document.
  const auto projected = parameters.find("projected");
  if (projected != parameters.end() && projected->is_array() && !projected->empty()) {
    if (registry == nullptr) {
      throw OperationFailure(operationId, "INVALID_REQUEST",
                             "projected sketch geometry requires the naming registry");
    }
    const auto planePoint = [&](const gp_Pnt& point) -> SketchRegionPoint {
      const gp_Vec delta(frame.Location(), point);
      return {delta.Dot(gp_Vec(frame.XDirection())), delta.Dot(gp_Vec(frame.YDirection()))};
    };
    const auto addProjectedSpline = [&](const std::string& eid, const BRepAdaptor_Curve& curve) {
      SketchRegionSegment spline;
      spline.kind = SketchRegionSegment::Kind::Spline;
      spline.eid = eid;
      spline.closed = curve.IsClosed();
      const double first = curve.FirstParameter();
      const double last = curve.LastParameter();
      constexpr int sampleCount = 48;
      for (int index = 0; index < sampleCount; ++index) {
        const double parameter = first + (last - first) * index / sampleCount;
        spline.points.push_back(planePoint(curve.Value(parameter)));
      }
      if (!spline.closed)
        spline.points.push_back(planePoint(curve.Value(last)));
      spline.construction = false;
      segments.push_back(std::move(spline));
    };
    for (const auto& projection : *projected) {
      CheckCancellation(cancelled);
      const std::string eid = projection.at("eid").get<std::string>();
      const std::string mode = projection.value("mode", "project");
      if (mode != "project") {
        throw OperationFailure(
            operationId, "UNSUPPORTED_OPERATION",
            "sketch projected geometry mode '" + mode +
                "' is not implemented by the native region lowerer; use 'project'");
      }
      const RefResolution resolution =
          ResolveRefSlotStrict(operationId, "sketch", "projected", projection.at("source"), bodies,
                               *registry, cancelled);
      const QueryEntity& source = SingleResolvedEntity("sketch", "projected", 'e', resolution);
      const BRepAdaptor_Curve curve(TopoDS::Edge(source.shape));
      if (curve.GetType() == GeomAbs_Line) {
        SketchRegionSegment line;
        line.kind = SketchRegionSegment::Kind::Line;
        line.eid = eid;
        line.start = planePoint(curve.Value(curve.FirstParameter()));
        line.end = planePoint(curve.Value(curve.LastParameter()));
        line.construction = projection.value("construction", true);
        if (!line.construction)
          segments.push_back(std::move(line));
        continue;
      }
      if (curve.GetType() == GeomAbs_Circle && curve.IsClosed()) {
        const gp_Circ circle = curve.Circle();
        SketchRegionSegment projectedCircle;
        projectedCircle.kind = SketchRegionSegment::Kind::Circle;
        projectedCircle.eid = eid;
        projectedCircle.center = planePoint(circle.Location());
        projectedCircle.radius = circle.Radius();
        projectedCircle.construction = projection.value("construction", true);
        if (!projectedCircle.construction)
          segments.push_back(std::move(projectedCircle));
        continue;
      }
      if (curve.GetType() == GeomAbs_Circle) {
        const gp_Circ circle = curve.Circle();
        const SketchRegionPoint center = planePoint(circle.Location());
        const SketchRegionPoint start = planePoint(curve.Value(curve.FirstParameter()));
        const SketchRegionPoint end = planePoint(curve.Value(curve.LastParameter()));
        SketchRegionSegment arc;
        arc.kind = SketchRegionSegment::Kind::Arc;
        arc.eid = eid;
        arc.center = center;
        arc.radius = circle.Radius();
        arc.start = start;
        arc.end = end;
        arc.startAngle =
            std::atan2(start.v - center.v, start.u - center.u) / kSketchDegreesToRadians;
        arc.endAngle = std::atan2(end.v - center.v, end.u - center.u) / kSketchDegreesToRadians;
        arc.ccw = circle.Axis().Direction().Dot(frame.Direction()) >= 0.0;
        arc.construction = projection.value("construction", true);
        if (!arc.construction)
          segments.push_back(std::move(arc));
        continue;
      }
      if (curve.GetType() == GeomAbs_Ellipse && curve.IsClosed()) {
        const gp_Elips ellipse = curve.Ellipse();
        const SketchRegionPoint center = planePoint(ellipse.Location());
        const gp_Dir majorDirection = ellipse.XAxis().Direction();
        const gp_Vec major(majorDirection);
        const double rotation = std::atan2(major.Dot(gp_Vec(frame.YDirection())),
                                           major.Dot(gp_Vec(frame.XDirection()))) /
                                kSketchDegreesToRadians;
        SketchRegionSegment projectedEllipse;
        projectedEllipse.kind = SketchRegionSegment::Kind::Ellipse;
        projectedEllipse.eid = eid;
        projectedEllipse.center = center;
        projectedEllipse.radiusX = ellipse.MajorRadius();
        projectedEllipse.radiusY = ellipse.MinorRadius();
        projectedEllipse.rotation = rotation;
        projectedEllipse.construction = projection.value("construction", true);
        if (!projectedEllipse.construction)
          segments.push_back(std::move(projectedEllipse));
        continue;
      }
      if (!projection.value("construction", true))
        addProjectedSpline(eid, curve);
    }
  }

  if (outSegments != nullptr)
    *outSegments = segments;
  if (segments.empty())
    return {};
  std::vector<SketchRegionSegment> pending = segments;
  std::vector<SketchRegionLoop> rawLoops;
  while (!pending.empty()) {
    SketchRegionSegment first = pending.front();
    pending.erase(pending.begin());
    const bool closed = first.kind == SketchRegionSegment::Kind::Circle ||
                        first.kind == SketchRegionSegment::Kind::Ellipse ||
                        (first.kind == SketchRegionSegment::Kind::Spline && first.closed);
    if (closed) {
      rawLoops.push_back({{std::move(first)}, {}, 0.0, 0, false});
      continue;
    }
    SketchRegionLoop loop;
    loop.segments.push_back(std::move(first));
    const SketchRegionPoint start = SegmentStart(loop.segments.front());
    SketchRegionPoint end = SegmentEnd(loop.segments.front());
    while (SketchGap(end, start) >= kSketchMinSize) {
      std::vector<std::size_t> matches;
      std::vector<bool> reverse;
      for (std::size_t index = 0; index < pending.size(); ++index) {
        if (pending[index].kind == SketchRegionSegment::Kind::Circle ||
            pending[index].kind == SketchRegionSegment::Kind::Ellipse ||
            (pending[index].kind == SketchRegionSegment::Kind::Spline && pending[index].closed))
          continue;
        const bool atStart = SketchGap(end, SegmentStart(pending[index])) < kSketchMinSize;
        const bool atEnd = SketchGap(end, SegmentEnd(pending[index])) < kSketchMinSize;
        if (atStart || atEnd) {
          matches.push_back(index);
          reverse.push_back(!atStart);
        }
      }
      if (matches.empty()) {
        std::ostringstream message;
        message << "this contour is open: " << loop.segments.back().eid << " ends "
                << SketchGap(end, start) << " mm from where " << loop.segments.front().eid
                << " starts";
        refusal = message.str();
        return {};
      }
      if (matches.size() > 1) {
        refusal = "the sketch boundary is ambiguous where multiple curves meet";
        return {};
      }
      const std::size_t index = matches.front();
      SketchRegionSegment next = std::move(pending[index]);
      pending.erase(pending.begin() + static_cast<std::ptrdiff_t>(index));
      if (reverse.front())
        next = ReverseSegment(next);
      end = SegmentEnd(next);
      loop.segments.push_back(std::move(next));
      if (loop.segments.size() > segments.size()) {
        refusal = "the sketch boundary could not be arranged into a closed loop";
        return {};
      }
    }
    rawLoops.push_back(std::move(loop));
  }

  std::vector<std::vector<SketchRegionPoint>> samples;
  samples.reserve(rawLoops.size());
  std::vector<double> areas;
  for (std::size_t index = 0; index < rawLoops.size(); ++index) {
    const auto& loop = rawLoops[index];
    std::vector<SketchRegionPoint> sample;
    for (const auto& segment : loop.segments) {
      const auto segmentSamples = SampleRegionSegment(segment);
      for (const auto& point : segmentSamples) {
        if (sample.empty() || SketchGap(sample.back(), point) >= kSketchMinSize)
          sample.push_back(point);
      }
    }
    if (sample.size() > 1 && SketchGap(sample.front(), sample.back()) < kSketchMinSize)
      sample.pop_back();
    const double area = RegionPolygonArea(sample);
    if (sample.size() < 3 || std::abs(area) < kSketchMinSize * kSketchMinSize) {
      refusal = "a sketch boundary has zero area";
      return {};
    }
    for (std::size_t i = 0; i < sample.size(); ++i) {
      for (std::size_t j = i + 1; j < sample.size(); ++j) {
        if (j == i + 1 || (i == 0 && j == sample.size() - 1))
          continue;
        if (RegionEdgesCross(sample[i], sample[(i + 1) % sample.size()], sample[j],
                             sample[(j + 1) % sample.size()])) {
          refusal = "a sketch boundary self-intersects";
          return {};
        }
      }
    }
    rawLoops[index].samples = sample;
    samples.push_back(std::move(sample));
    areas.push_back(area);
  }
  for (std::size_t index = 0; index < rawLoops.size(); ++index) {
    const auto& sample = samples[index];
    SketchRegionPoint probe{};
    for (const auto& point : sample) {
      probe.u += point.u / sample.size();
      probe.v += point.v / sample.size();
    }
    int depth = 0;
    for (std::size_t other = 0; other < rawLoops.size(); ++other) {
      if (other == index || std::abs(areas[other]) <= std::abs(areas[index]))
        continue;
      if (RegionPointInPolygon(probe, samples[other]))
        ++depth;
    }
    rawLoops[index].depth = depth;
    rawLoops[index].hole = depth % 2 == 1;
    if ((areas[index] >= 0.0) == rawLoops[index].hole) {
      std::reverse(rawLoops[index].segments.begin(), rawLoops[index].segments.end());
      for (auto& segment : rawLoops[index].segments)
        segment = ReverseSegment(segment);
      rawLoops[index].signedArea = -areas[index];
    } else {
      rawLoops[index].signedArea = areas[index];
    }
  }
  return rawLoops;
}

// Builds the region's wire on the sketch plane.
//
// Every edge is built from the solved endpoints directly, so consecutive edges
// share exact coordinates and nothing is fitted: the wire's tolerance stays at
// OCCT's linear default rather than absorbing a gap (the §6a budget).
TopoDS_Wire SketchRegionWire(const gp_Ax2& frame,
                             const std::vector<SketchRegionSegment>& segments) {
  if (segments.size() == 1 && segments.front().kind == SketchRegionSegment::Kind::Circle) {
    const SketchRegionSegment& circle = segments.front();
    const gp_Ax2 circleFrame(PlanePoint(frame, circle.center.u, circle.center.v), frame.Direction(),
                             frame.XDirection());
    return CircleWire(circleFrame, circle.radius);
  }
  if (segments.size() == 1 && segments.front().kind == SketchRegionSegment::Kind::Ellipse) {
    const SketchRegionSegment& ellipse = segments.front();
    const double radians = ellipse.rotation * kSketchDegreesToRadians;
    const gp_Vec majorDirection = gp_Vec(frame.XDirection()) * std::cos(radians) +
                                  gp_Vec(frame.YDirection()) * std::sin(radians);
    const gp_Ax2 ellipseFrame(PlanePoint(frame, ellipse.center.u, ellipse.center.v),
                              frame.Direction(), gp_Dir(majorDirection));
    double major = ellipse.radiusX;
    double minor = ellipse.radiusY;
    gp_Ax2 actualFrame = ellipseFrame;
    if (minor > major) {
      std::swap(major, minor);
      actualFrame =
          gp_Ax2(ellipseFrame.Location(), ellipseFrame.Direction(), ellipseFrame.YDirection());
    }
    BRepBuilderAPI_MakeEdge edge(gp_Elips(actualFrame, major, minor));
    if (!edge.IsDone())
      throw std::runtime_error("sketch ellipse construction failed");
    BRepBuilderAPI_MakeWire wire(edge.Edge());
    if (!wire.IsDone())
      throw std::runtime_error("sketch ellipse wire construction failed");
    return wire.Wire();
  }

  BRepBuilderAPI_MakeWire wire;
  for (const SketchRegionSegment& segment : segments) {
    const gp_Pnt from = PlanePoint(frame, segment.start.u, segment.start.v);
    const gp_Pnt to = PlanePoint(frame, segment.end.u, segment.end.v);
    if (segment.kind == SketchRegionSegment::Kind::Line) {
      BRepBuilderAPI_MakeEdge edge(from, to);
      if (!edge.IsDone())
        throw std::runtime_error("sketch region segment construction failed");
      wire.Add(edge.Edge());
      continue;
    }
    if (segment.kind == SketchRegionSegment::Kind::Spline) {
      if (segment.points.size() < 3)
        throw std::runtime_error("sketch spline region has fewer than three points");
      occ::handle<NCollection_HArray1<gp_Pnt>> points =
          new NCollection_HArray1<gp_Pnt>(1, static_cast<int>(segment.points.size()));
      for (std::size_t index = 0; index < segment.points.size(); ++index)
        points->SetValue(static_cast<int>(index) + 1,
                         PlanePoint(frame, segment.points[index].u, segment.points[index].v));
      GeomAPI_Interpolate interpolate(points, segment.closed, 1.0e-7);
      try {
        interpolate.Perform();
      } catch (const Standard_Failure&) {
        throw std::runtime_error("sketch spline interpolation failed");
      }
      if (!interpolate.IsDone())
        throw std::runtime_error("sketch spline interpolation failed");
      BRepBuilderAPI_MakeEdge edge(interpolate.Curve());
      if (!edge.IsDone())
        throw std::runtime_error("sketch spline construction failed");
      wire.Add(edge.Edge());
      continue;
    }
    // The arc's own circle, parameterized about the sketch normal so that
    // MakeEdge(circle, from, to) trims counter-clockwise — the direction the
    // entity's start/end angles are measured in.
    gp_Dir arcNormal = frame.Direction();
    if (!segment.ccw)
      arcNormal.Reverse();
    const gp_Circ circle(gp_Ax2(PlanePoint(frame, segment.center.u, segment.center.v), arcNormal,
                                frame.XDirection()),
                         segment.radius);
    BRepBuilderAPI_MakeEdge edge(circle, from, to);
    if (!edge.IsDone())
      throw std::runtime_error("sketch region arc construction failed");
    wire.Add(edge.Edge());
  }
  if (!wire.IsDone())
    throw std::runtime_error("sketch region wire construction failed");
  return wire.Wire();
}

void RegisterSketchBoundaryEdges(const nlohmann::json& operation,
                                 const std::vector<EvaluatedBody>& bodies, NamingRegistry* registry,
                                 const std::atomic_bool& cancelled) {
  if (registry == nullptr)
    return;
  const gp_Ax2 frame = SketchPlaneAxes(operation, bodies, registry, cancelled);
  std::string refusal;
  std::vector<SketchRegionSegment> segments;
  (void)SketchClosedRegions(operation.at("parameters"), frame, bodies, registry,
                            operation.at("id").get<std::string>(), cancelled, refusal, &segments);
  if (segments.empty())
    return;

  std::vector<std::pair<std::string, TopoDS_Shape>> edges;
  edges.reserve(segments.size());
  for (const SketchRegionSegment& segment : segments) {
    CheckCancellation(cancelled);
    const TopoDS_Wire wire = SketchRegionWire(frame, {segment});
    TopExp_Explorer explorer(wire, TopAbs_EDGE);
    if (!explorer.More())
      throw std::runtime_error("sketch boundary segment produced no selectable edge");
    const TopoDS_Edge edge = TopoDS::Edge(explorer.Current());
    explorer.Next();
    if (explorer.More())
      throw std::runtime_error("one sketch boundary segment produced multiple selectable edges");
    edges.emplace_back(segment.eid, edge);
  }
  registry->RegisterSketchEdges(operation.at("id").get<std::string>(), "sketch-edge", "entity",
                                edges, cancelled);
}

// The sketch's region as a profile, or `std::nullopt` when the sketch encloses
// none.
//
// NEVER REFUSES. A sketch that encloses no region is legal — plan 02 says a
// sketch used only as a path or a guide is a real thing, and a single line is
// real geometry that simply bounds nothing. Failing the document over it would
// be the kernel inventing a rule about what a person is allowed to draw, and it
// broke a shipped contract the moment it was written: CAP-037's determinism
// gate stores a one-line sketch, and that document must evaluate.
//
// The refusal a person needs — "this contour is open: A ends 5 mm from where B
// starts" — is raised where they can act on it, in `sketchClosedRegion` on the
// authoring side, while they are drawing. A consumer that names a sketch which
// produced no profile still fails, as REFERENCE_MISSING naming the consumer.
// A sketch that encloses nothing but draws ONE connected open path, plus the
// plane frame it was drawn on. Only Thin Extrude consumes this: a wall can
// follow a path, but nothing else here can turn a path into a solid.
//
// This is deliberately a SEPARATE evaluation from EvaluateSketchRegion rather
// than an extra return mode of it. Every existing consumer of an
// EvaluatedProfile assumes it carries real faces, so handing them a face-less
// profile crashed the sketch-region suite outright. Keeping open paths in
// their own map means no consumer sees one unless it asked.
struct EvaluatedOpenPath final {
  TopoDS_Wire wire;
  gp_Ax2 frame;
  gp_Dir normal;
  gp_Pnt origin;
};

// Turns one authoritative open sketch path into an asymmetric planar band.
// The authored path stays the zero line: sideOne grows to its left and
// sideTwo to its right in the sketch frame.  Revolve uses this directly, so
// unequal walls remain one typed/history feature instead of a surface plus a
// later thicken operation.
TopoDS_Face MakeOpenPathBand(const std::string& operationId, const EvaluatedOpenPath& path,
                             const double sideOne, const double sideTwo) {
  if (sideOne < 0.0 || sideTwo < 0.0 || sideOne + sideTwo <= 0.0)
    throw OperationFailure(operationId, "INVALID_REQUEST",
                           "Thin Revolve needs a positive wall on at least one side.",
                           {{"code", "E_REVOLVE_THIN_INVALID"}});
  if (Count(path.wire, TopAbs_EDGE) == 1) {
    TopExp_Explorer explorer(path.wire, TopAbs_EDGE);
    const TopoDS_Edge edge = TopoDS::Edge(explorer.Current());
    const BRepAdaptor_Curve curve(edge);
    if (curve.GetType() == GeomAbs_Line) {
      TopoDS_Vertex first, last;
      TopExp::Vertices(path.wire, first, last);
      if (!first.IsNull() && !last.IsNull()) {
        const gp_Pnt p0 = BRep_Tool::Pnt(first);
        const gp_Pnt p1 = BRep_Tool::Pnt(last);
        gp_Vec tangent(p0, p1);
        if (tangent.Magnitude() > 1e-9) {
          tangent.Normalize();
          gp_Vec lateral = gp_Vec(path.normal).Crossed(tangent);
          lateral.Normalize();
          const gp_Pnt a0 = p0.Translated(-sideOne * lateral);
          const gp_Pnt a1 = p1.Translated(-sideOne * lateral);
          const gp_Pnt b1 = p1.Translated(sideTwo * lateral);
          const gp_Pnt b0 = p0.Translated(sideTwo * lateral);
          BRepBuilderAPI_MakePolygon polygon(a0, a1, b1, b0, /*Close=*/true);
          BRepBuilderAPI_MakeFace face(gp_Pln(gp_Ax3(path.frame)), polygon.Wire(), true);
          if (polygon.IsDone() && face.IsDone() && BRepCheck_Analyzer(face.Face(), true).IsValid())
            return face.Face();
        }
      }
    }
  }
  const auto offsetPath = [&](const double distance) -> TopoDS_Wire {
    if (std::abs(distance) < 1e-12)
      return path.wire;
    BRepOffsetAPI_MakeOffset maker;
    maker.Init(GeomAbs_Arc, /*IsOpenResult=*/true);
    maker.AddWire(path.wire);
    maker.Perform(distance);
    if (!maker.IsDone() || maker.Shape().IsNull())
      throw OperationFailure(operationId, "THIN_FAILED",
                             "Thin Revolve could not offset the open profile.",
                             {{"code", "E_REVOLVE_THIN_OFFSET_FAILED"}});
    TopExp_Explorer wires(maker.Shape(), TopAbs_WIRE);
    if (!wires.More())
      throw OperationFailure(operationId, "THIN_FAILED",
                             "Thin Revolve produced no usable offset path.",
                             {{"code", "E_REVOLVE_THIN_OFFSET_FAILED"}});
    return TopoDS::Wire(wires.Current());
  };
  const TopoDS_Wire first = offsetPath(-sideOne);
  const TopoDS_Wire second = offsetPath(sideTwo);
  TopoDS_Vertex a0, a1, b0, b1;
  TopExp::Vertices(first, a0, a1);
  TopExp::Vertices(second, b0, b1);
  if (a0.IsNull() || a1.IsNull() || b0.IsNull() || b1.IsNull())
    throw OperationFailure(operationId, "THIN_FAILED",
                           "Thin Revolve could not find both profile ends.",
                           {{"code", "E_REVOLVE_THIN_OPEN_FAILED"}});
  const auto orderedEdges = [](const TopoDS_Wire& wire) {
    std::vector<TopoDS_Edge> edges;
    for (BRepTools_WireExplorer explorer(wire); explorer.More(); explorer.Next())
      edges.push_back(TopoDS::Edge(explorer.Current()));
    return edges;
  };
  const std::vector<TopoDS_Edge> edgesA = orderedEdges(first);
  const std::vector<TopoDS_Edge> edgesB = orderedEdges(second);
  if (edgesA.empty() || edgesB.empty())
    throw OperationFailure(operationId, "THIN_FAILED", "Thin Revolve profile is empty.",
                           {{"code", "E_REVOLVE_THIN_OPEN_FAILED"}});
  const gp_Pnt endA = BRep_Tool::Pnt(a1);
  const bool forwardB = endA.Distance(BRep_Tool::Pnt(b0)) <= endA.Distance(BRep_Tool::Pnt(b1));
  const TopoDS_Vertex entryB = forwardB ? b0 : b1;
  const TopoDS_Vertex exitB = forwardB ? b1 : b0;
  BRepBuilderAPI_MakeWire band;
  for (const TopoDS_Edge& edge : edgesA)
    band.Add(edge);
  band.Add(BRepBuilderAPI_MakeEdge(a1, entryB).Edge());
  if (forwardB) {
    for (const TopoDS_Edge& edge : edgesB)
      band.Add(edge);
  } else {
    for (auto it = edgesB.rbegin(); it != edgesB.rend(); ++it)
      band.Add(*it);
  }
  band.Add(BRepBuilderAPI_MakeEdge(exitB, a0).Edge());
  if (!band.IsDone())
    throw OperationFailure(operationId, "THIN_FAILED",
                           "Thin Revolve offsets do not close into a band.",
                           {{"code", "E_REVOLVE_THIN_OPEN_FAILED"}});
  BRepBuilderAPI_MakeFace face(gp_Pln(gp_Ax3(path.frame)), band.Wire(), /*Inside=*/true);
  if (!face.IsDone() || !BRepCheck_Analyzer(face.Face(), true).IsValid())
    throw OperationFailure(
        operationId, "THIN_FAILED",
        "Thin Revolve self-intersects; reduce the wall or open the profile bend.",
        {{"code", "E_REVOLVE_THIN_SELF_INTERSECT"}});
  return face.Face();
}

std::optional<EvaluatedOpenPath> EvaluateSketchOpenPath(const nlohmann::json& operation,
                                                        const std::vector<EvaluatedBody>& bodies,
                                                        NamingRegistry* registry,
                                                        const std::atomic_bool& cancelled) {
  const nlohmann::json& parameters = operation.at("parameters");
  CheckCancellation(cancelled);
  const gp_Ax2 frame = SketchPlaneAxes(operation, bodies, registry, cancelled);
  std::string refusal;
  std::vector<SketchRegionSegment> segments;
  const std::vector<SketchRegionLoop> loops =
      SketchClosedRegions(parameters, frame, bodies, registry,
                          operation.at("id").get<std::string>(), cancelled, refusal, &segments);
  // A sketch that encloses material is a region, not a path.
  if (!loops.empty() || segments.empty())
    return std::nullopt;
  // A closed primitive encloses area on its own; the region path already
  // rejected this sketch for some other reason, so do not reinterpret it.
  for (const SketchRegionSegment& segment : segments) {
    if (segment.kind == SketchRegionSegment::Kind::Circle ||
        segment.kind == SketchRegionSegment::Kind::Ellipse ||
        (segment.kind == SketchRegionSegment::Kind::Spline && segment.closed))
      return std::nullopt;
  }

  // Chain the segments end-to-end. Walk forward from the seed's tail, then
  // backward from its head, so a path authored from the middle outward still
  // resolves to one ordered run.
  std::vector<SketchRegionSegment> pending = segments;
  std::vector<SketchRegionSegment> ordered;
  ordered.push_back(pending.front());
  pending.erase(pending.begin());
  const auto extend = [&](const bool forward) {
    bool grew = true;
    while (grew && !pending.empty()) {
      grew = false;
      const SketchRegionPoint anchor =
          forward ? SegmentEnd(ordered.back()) : SegmentStart(ordered.front());
      for (std::size_t index = 0; index < pending.size(); ++index) {
        const bool atStart = SketchGap(anchor, SegmentStart(pending[index])) < kSketchMinSize;
        const bool atEnd = SketchGap(anchor, SegmentEnd(pending[index])) < kSketchMinSize;
        if (!atStart && !atEnd)
          continue;
        SketchRegionSegment next = pending[index];
        pending.erase(pending.begin() + static_cast<std::ptrdiff_t>(index));
        // Orient the segment so the chain reads head-to-tail in one direction.
        if (forward ? atEnd : atStart)
          next = ReverseSegment(next);
        if (forward)
          ordered.push_back(std::move(next));
        else
          ordered.insert(ordered.begin(), std::move(next));
        grew = true;
        break;
      }
    }
  };
  extend(true);
  extend(false);
  // Leftovers mean the sketch draws more than one path. Refuse to guess which
  // one a wall should follow.
  if (!pending.empty())
    return std::nullopt;
  // A chain whose ends meet is a closed contour the region path should have
  // taken; treating it as a path here would produce a wall with a seam.
  if (SketchGap(SegmentStart(ordered.front()), SegmentEnd(ordered.back())) < kSketchMinSize)
    return std::nullopt;

  CheckCancellation(cancelled);
  const TopoDS_Wire wire = SketchRegionWire(frame, ordered);
  if (wire.IsNull())
    return std::nullopt;
  return EvaluatedOpenPath{wire, frame, frame.Direction(), frame.Location()};
}

std::optional<EvaluatedProfile> EvaluateSketchRegion(const nlohmann::json& operation,
                                                     const std::vector<EvaluatedBody>& bodies,
                                                     NamingRegistry* registry,
                                                     const std::atomic_bool& cancelled) {
  const nlohmann::json& parameters = operation.at("parameters");
  CheckCancellation(cancelled);
  const gp_Ax2 frame = SketchPlaneAxes(operation, bodies, registry, cancelled);
  std::string refusal;
  const std::vector<SketchRegionLoop> loops =
      SketchClosedRegions(parameters, frame, bodies, registry,
                          operation.at("id").get<std::string>(), cancelled, refusal);
  if (loops.empty())
    return std::nullopt;

  CheckCancellation(cancelled);
  // Every even-depth loop is material. Build one planar face for each such
  // loop and attach only its immediate odd-depth children as holes. Keeping
  // the faces separate is important: a disconnected region is valid sketch
  // material and must extrude into a compound of solids rather than being
  // silently discarded or forced through the largest contour.
  // Durable region key: the sorted, deduplicated source entity ids bounding
  // this loop (outer loop plus any attached holes). Two loops built from the
  // same entities always produce the same key; a loop whose bounding
  // entities change produces a different key rather than silently keeping
  // the old one (see EvaluatedProfile::regionIds doc comment).
  std::vector<TopoDS_Face> faces;
  std::vector<std::string> regionIds;
  for (std::size_t outerIndex = 0; outerIndex < loops.size(); ++outerIndex) {
    if (loops[outerIndex].depth % 2 != 0)
      continue;
    const TopoDS_Wire wire = SketchRegionWire(frame, loops[outerIndex].segments);
    TopoDS_Vertex first;
    TopoDS_Vertex last;
    TopExp::Vertices(wire, first, last);
    if (first.IsNull() || last.IsNull() || !first.IsSame(last))
      throw std::runtime_error("sketch region wire is not closed");

    CheckCancellation(cancelled);
    BRepBuilderAPI_MakeFace faceMaker(gp_Pln(gp_Ax3(frame)), wire, /*Inside=*/true);
    if (!faceMaker.IsDone())
      throw std::runtime_error("sketch region face construction failed");
    std::vector<const SketchRegionLoop*> contributingLoops{&loops[outerIndex]};
    for (std::size_t holeIndex = 0; holeIndex < loops.size(); ++holeIndex) {
      if (loops[holeIndex].depth != loops[outerIndex].depth + 1 ||
          loops[holeIndex].samples.empty() || loops[outerIndex].samples.empty())
        continue;
      SketchRegionPoint probe{};
      for (const SketchRegionPoint& point : loops[holeIndex].samples) {
        probe.u += point.u / loops[holeIndex].samples.size();
        probe.v += point.v / loops[holeIndex].samples.size();
      }
      if (RegionPointInPolygon(probe, loops[outerIndex].samples)) {
        faceMaker.Add(SketchRegionWire(frame, loops[holeIndex].segments));
        contributingLoops.push_back(&loops[holeIndex]);
      }
    }
    const TopoDS_Face face = faceMaker.Face();
    if (!BRepCheck_Analyzer(face, true).IsValid())
      throw std::runtime_error("OCCT produced an invalid sketch region face");
    faces.push_back(face);
    std::string key = "region:";
    {
      std::vector<std::string> eids;
      for (const SketchRegionLoop* loop : contributingLoops) {
        for (const SketchRegionSegment& seg : loop->segments) {
          if (!seg.eid.empty())
            eids.push_back(seg.eid);
        }
      }
      std::sort(eids.begin(), eids.end());
      eids.erase(std::unique(eids.begin(), eids.end()), eids.end());
      for (std::size_t i = 0; i < eids.size(); ++i) {
        if (i > 0)
          key += "+";
        key += eids[i];
      }
    }
    regionIds.push_back(std::move(key));
  }
  if (faces.empty())
    throw std::runtime_error("sketch region has no outer boundary");

  TopoDS_Shape profileShape = faces.front();
  if (faces.size() > 1) {
    TopoDS_Compound compound;
    BRep_Builder builder;
    builder.MakeCompound(compound);
    for (const TopoDS_Face& face : faces)
      builder.Add(compound, face);
    profileShape = compound;
  }
  GProp_GProps surfaceProperties;
  BRepGProp::SurfaceProperties(profileShape, surfaceProperties);
  const gp_Pnt origin =
      surfaceProperties.Mass() > 0.0 ? surfaceProperties.CentreOfMass() : frame.Location();
  EvaluatedProfile result{faces.front(), profileShape, faces, frame, frame.Direction(), origin};
  result.regionIds = std::move(regionIds);
  return result;
}

// Derive a revolve axis from the evaluated profile frame, not from a renderer
// snapshot. The shape is transformed into the profile's local Ax3 first, so
// the bounds are correct for a model face with any world orientation and for
// curved edges whose extrema are not world-axis aligned.
gp_Ax1 ProfileRelativeAxis(const EvaluatedProfile& profile, const std::string& axisName) {
  const gp_Ax3 source(profile.frame);
  gp_Trsf toLocal;
  // The one-argument form maps the absolute world system into `source`'s
  // coordinates. The two-system form would map coordinates that are already
  // expressed in `source`, which is not the shape's representation here.
  toLocal.SetTransformation(source);
  BRepBuilderAPI_Transform transform(profile.shape, toLocal, /*Copy=*/true);
  if (!transform.IsDone() || transform.Shape().IsNull())
    throw Standard_Failure("could not derive a profile-relative revolve axis");

  Bnd_Box bounds;
  BRepBndLib::AddOptimal(transform.Shape(), bounds, true, false);
  if (bounds.IsVoid())
    throw Standard_Failure("profile-relative revolve axis has no profile bounds");
  double minX = 0.0;
  double minY = 0.0;
  double minZ = 0.0;
  double maxX = 0.0;
  double maxY = 0.0;
  double maxZ = 0.0;
  bounds.Get(minX, minY, minZ, maxX, maxY, maxZ);
  const double centerX = 0.5 * (minX + maxX);
  const double centerY = 0.5 * (minY + maxY);
  // OCCT rejects an axis whose line is exactly coincident with a profile edge
  // as a degenerate revolution. The semantic label remains the profile edge,
  // while this microscopic outward clearance keeps the generated solid valid
  // and is below the document modeling tolerance budget.
  constexpr double kAxisClearance = 1.0e-6;

  if (axisName == "left")
    return gp_Ax1(PlanePoint(profile.frame, minX - kAxisClearance, centerY),
                  profile.frame.YDirection());
  if (axisName == "right")
    return gp_Ax1(PlanePoint(profile.frame, maxX + kAxisClearance, centerY),
                  profile.frame.YDirection());
  if (axisName == "bottom")
    return gp_Ax1(PlanePoint(profile.frame, centerX, minY - kAxisClearance),
                  profile.frame.XDirection());
  if (axisName == "top")
    return gp_Ax1(PlanePoint(profile.frame, centerX, maxY + kAxisClearance),
                  profile.frame.XDirection());
  throw std::invalid_argument("unknown profile-relative revolve axis: " + axisName);
}

// BodyPool — the evaluation-epoch pool of solid bodies, with the tranche-2.1
// snapshot/restore seam — lives in body_pool.hpp so the replay-cache slices
// (and the seam's differential test) can reuse it without pulling in this
// whole translation unit. Included at the top of the file.

// Proves a cutting tool would actually remove material from the target before
// a subtractive boolean (cut / hole) is allowed to "succeed". OCCT's cut of a
// non-overlapping tool returns the target unchanged as one valid solid, so the
// solid-count contract alone cannot tell a real cut from a no-op. The shared
// volume is computed as a first-class intersection SHAPE — never as the
// difference of two large volumes, which cancels catastrophically for a small
// tool against a large body — so an empty solid intersection is a reliable
// no-op signal regardless of model scale.
bool ToolRemovesMaterial(const TopoDS_Shape& target, const TopoDS_Shape& tool,
                         const std::atomic_bool& cancelled) {
  BRepAlgoAPI_Common overlap;
  NCollection_List<TopoDS_Shape> objects;
  objects.Append(target);
  NCollection_List<TopoDS_Shape> tools;
  tools.Append(tool);
  overlap.SetArguments(objects);
  overlap.SetTools(tools);
  overlap.SetRunParallel(false);
  overlap.SetToFillHistory(false);
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    overlap.Build(progress->Start());
  }
  CheckCancellation(cancelled);
  if (overlap.HasErrors())
    throw Standard_Failure("subtractive-boolean intersection preflight failed");
  return Count(overlap.Shape(), TopAbs_SOLID) > 0;
}

EvaluatedBody EvaluateBooleanCombine(const nlohmann::json& operation, BodyPool& pool,
                                     ElementNameBook* elementNames, NamingRegistry* registry,
                                     const std::atomic_bool& cancelled) {
  const std::string operationId = operation.at("id").get<std::string>();
  const auto& parameters = operation.at("parameters");
  const std::string kind = parameters.at("kind").get<std::string>();

  std::unique_ptr<BRepAlgoAPI_BooleanOperation> algorithm;
  if (kind == "union") {
    algorithm = std::make_unique<BRepAlgoAPI_Fuse>();
  } else if (kind == "cut") {
    algorithm = std::make_unique<BRepAlgoAPI_Cut>();
  } else if (kind == "intersect") {
    algorithm = std::make_unique<BRepAlgoAPI_Common>();
  } else {
    throw std::invalid_argument("unsupported boolean kind: " + kind);
  }

  // Consume the target before resolving the tool, so target == tool fails as
  // an already-consumed reference (defense in depth below the schema's
  // distinctness rule).
  const std::string description = "boolean " + kind;
  const TopoDS_Shape target = pool.Consume(operationId, description, "target",
                                           parameters.at("targetOperationId").get<std::string>());
  const TopoDS_Shape tool = pool.Consume(operationId, description, "tool",
                                         parameters.at("toolOperationId").get<std::string>());

  // No-op contract (fail closed), decided explicitly per the audit: a cut
  // whose tool does not overlap the target removes nothing and would return
  // the target unchanged as one valid solid — a committed feature with no
  // geometric effect. The whole boolean family is fail-closed (union of
  // non-touching bodies rejected as disjoint, intersect of non-overlapping
  // rejected as empty), so a cut that removes no material is rejected too.
  // Union and intersect keep their material contracts through the empty /
  // disjoint checks below, so only the subtractive kind needs this preflight.
  if (kind == "cut" && !ToolRemovesMaterial(target, tool, cancelled)) {
    throw Standard_Failure(
        "boolean cut removed no material: the tool does not overlap the target body");
  }

  NCollection_List<TopoDS_Shape> objects;
  objects.Append(target);
  NCollection_List<TopoDS_Shape> tools;
  tools.Append(tool);
  algorithm->SetArguments(objects);
  algorithm->SetTools(tools);
  // Determinism over speed: replay integrity (MASTER_PLAN §5 gate 3) demands
  // that re-evaluating the same document reproduces the same result.
  algorithm->SetRunParallel(false);
  // History is retained exactly when the caller is recording element names
  // (tranche N0); a plain evaluation keeps the history-free fast path.
  algorithm->SetToFillHistory(elementNames != nullptr);
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    algorithm->Build(progress->Start());
  }
  CheckCancellation(cancelled);
  if (algorithm->HasErrors())
    throw Standard_Failure(("boolean " + kind + " failed").c_str());
  const TopoDS_Shape result = algorithm->Shape();
  if (result.IsNull())
    throw Standard_Failure(("boolean " + kind + " produced no result shape").c_str());

  // Empty-result contract (fail closed): a boolean that leaves no solid
  // material — a cut whose tool consumes the entire target, an intersect of
  // non-overlapping bodies — fails the request instead of fabricating an
  // empty body. On the pinned OCCT the algorithm reports no error for these
  // cases and returns an empty compound, so the material check is ours.
  const int solidCount = Count(result, TopAbs_SOLID);
  if (solidCount == 0) {
    if (kind == "cut") {
      throw Standard_Failure(
          "boolean cut produced an empty result: the tool consumed the entire target body");
    }
    if (kind == "intersect") {
      throw Standard_Failure(
          "boolean intersect produced an empty result: the target and tool bodies do not overlap");
    }
    throw Standard_Failure("boolean union produced an empty result");
  }
  // Disjoint-result contract (fail closed): one operation output is one
  // connected solid in v1. A union of non-touching bodies or a cut that
  // severs its target into islands produces several solids; splitting into
  // multiple bodies is the future split operation's contract, not a silent
  // boolean side effect.
  if (solidCount > 1) {
    throw Standard_Failure(("boolean " + kind + " produced " + std::to_string(solidCount) +
                            " disjoint solids; a boolean output must be a single connected solid")
                               .c_str());
  }
  const TopExp_Explorer solids(result, TopAbs_SOLID);
  EvaluatedBody body = FinishSolidBody(operation, TopoDS::Solid(solids.Current()),
                                       ("boolean " + kind + " result").c_str());
  if (elementNames != nullptr) {
    // History() returns a reference-counted handle that safely outlives the
    // non-copyable algorithm object — the same lifetime contract the
    // mutation-oracle path relies on. Inputs are the EXACT pool shapes the
    // algorithm consumed (never copies: BRepTools_History keys on shape
    // identity), and the named result is the extracted solid the topology
    // snapshot enumerates.
    const occ::handle<BRepTools_History> history = algorithm->History();
    if (history.IsNull())
      throw Standard_Failure(("boolean " + kind + " did not record algorithm history").c_str());
    elementNames->ApplyOperation(operationId, {target, tool}, body.shape, *history, cancelled);
    if (registry != nullptr) {
      // Tranche N3: the registry harvest consumes the SAME retained history
      // and the same exact input shapes the naming pass just used — one
      // history-retention path, one naming pass, then the §6.3 record
      // harvest on top of both.
      registry->HarvestOperation(operationId, NamingRegistry::OperationClass::Boolean,
                                 {{target, false}, {tool, true}}, body.shape, *history, cancelled);
    }
  }
  return body;
}

// POSITIONAL hole (Tranche B item 4, first pass): synthesizes a cylindrical
// tool from `size`/`depth`/`placement` and cuts it from the target body. The
// target is consumed exactly like a boolean cut's target (ADR-003
// operation-level reference; same REFERENCE_MISSING taxonomy). No face/edge
// selector exists yet — `placement.origin` is a raw world coordinate, never a
// topology reference — so this stays out of scope the moment a caller needs
// anything beyond a coordinate and an axis.
EvaluatedBody EvaluateHole(const nlohmann::json& operation, BodyPool& pool,
                           ElementNameBook* elementNames, NamingRegistry* registry,
                           const std::atomic_bool& cancelled) {
  const std::string operationId = operation.at("id").get<std::string>();
  const auto& parameters = operation.at("parameters");

  const auto& size = parameters.at("size");
  const std::string sizeKind = size.at("kind").get<std::string>();
  double radius;
  if (sizeKind == "radius") {
    radius = size.at("radius").get<double>();
  } else if (sizeKind == "diameter") {
    radius = size.at("diameter").get<double>() / 2.0;
  } else {
    throw std::invalid_argument("unsupported hole size kind: " + sizeKind);
  }
  if (!(radius > 0.0))
    throw std::invalid_argument("hole radius must be positive");

  const bool throughAll = parameters.at("throughAll").get<bool>();
  const gp_Ax2 frame = PlacementFrame(parameters.at("placement"));

  // Consumes the target exactly like a boolean cut's target: an operation-
  // level reference to an earlier, still-unconsumed body-producing operation.
  const TopoDS_Shape target = pool.Consume(operationId, "hole", "target",
                                           parameters.at("targetOperationId").get<std::string>());

  // Entry-point contract (fail closed): the placement origin IS the point where
  // drilling begins — a point ON the target's boundary — and the drilling
  // direction points INTO the material (blind depth is measured from that entry
  // point). Merely proving that the overshot tool intersects the target is too
  // weak: an origin above the surface, inside the solid, or on the surface but
  // drilling outward could each still intersect and silently cut the wrong
  // depth or nothing at the claimed entry point. The classification is scale-
  // independent (local ray/surface crossings, local entry-face tolerance) and
  // lives in its own translation unit so it can be unit-tested against
  // adversarial bodies; see hole_entry.cpp.
  ClassifyHoleEntry(target, frame);

  // Blind holes cut exactly `depth` along the drilling axis from the
  // placement origin. Through-all holes carry no user-given depth: the
  // kernel derives one from the target's own bounding-box diagonal, which
  // upper-bounds the distance from any point in (or on) the box to any of
  // its faces along any direction, so the synthesized tool is guaranteed to
  // fully pierce the target regardless of where the origin sits on it.
  double depth;
  if (throughAll) {
    Bnd_Box box;
    BRepBndLib::AddOptimal(target, box, true, false);
    double xmin;
    double ymin;
    double zmin;
    double xmax;
    double ymax;
    double zmax;
    box.Get(xmin, ymin, zmin, xmax, ymax, zmax);
    const double diagonal = gp_Vec(xmax - xmin, ymax - ymin, zmax - zmin).Magnitude();
    depth = 2.0 * diagonal + 1.0;
  } else {
    depth = parameters.at("depth").get<double>();
    if (!(depth > 0.0))
      throw std::invalid_argument("hole depth must be positive");
  }

  // Overshoot the entry side so the tool's own base cap sits safely outside
  // the target instead of coincident with its entry surface — a coplanar-
  // face boolean is a known-harder OCCT case this v1 does not attempt (see
  // the boolean_combine execution notes). The tool's LATERAL surface, not an
  // end cap, is what crosses the target's entry face; that is an ordinary,
  // well-conditioned intersection — exactly how the through-cut fixture
  // avoids the same case on both ends by overshooting there too.
  const double overshoot = std::max(0.25 * depth, 1.0);
  const gp_Vec direction(frame.Direction());
  const gp_Pnt toolBase = frame.Location().Translated((-overshoot) * direction);
  const gp_Ax2 toolFrame(toolBase, frame.Direction(), frame.XDirection());
  const occ::handle<CancellationProgress> toolProgress = MakeCancellationProgress(cancelled);
  BRepPrimAPI_MakeCylinder toolMaker(toolFrame, radius, depth + overshoot);
  toolMaker.Build(toolProgress->Start());
  CheckCancellation(cancelled);
  if (!toolMaker.IsDone())
    throw std::runtime_error("hole tool cylinder construction failed");

  // The entry-point contract above already guarantees the origin is on the
  // surface with material along the drilling axis, so a positive-depth tool
  // necessarily removes material — no separate intersection preflight is needed
  // here (unlike the general boolean cut, whose tool is an arbitrary body).
  BRepAlgoAPI_Cut cut;
  NCollection_List<TopoDS_Shape> objects;
  objects.Append(target);
  NCollection_List<TopoDS_Shape> tools;
  tools.Append(toolMaker.Shape());
  cut.SetArguments(objects);
  cut.SetTools(tools);
  // Determinism over speed, matching every other document-evaluation
  // boolean (MASTER_PLAN §5 gate 3).
  cut.SetRunParallel(false);
  // History is retained exactly when the caller is recording element names
  // (tranche N0), matching boolean_combine.
  cut.SetToFillHistory(elementNames != nullptr);
  {
    const occ::handle<CancellationProgress> cutProgress = MakeCancellationProgress(cancelled);
    cut.Build(cutProgress->Start());
  }
  CheckCancellation(cancelled);
  if (cut.HasErrors())
    throw Standard_Failure("hole cut failed");
  const TopoDS_Shape result = cut.Shape();
  if (result.IsNull())
    throw Standard_Failure("hole cut produced no result shape");

  // Same fail-closed empty/disjoint contract as boolean_combine: a hole that
  // swallows its entire target, or one that severs the target into islands,
  // fails the request instead of fabricating a body no downstream consumer
  // has a meaning for.
  const int solidCount = Count(result, TopAbs_SOLID);
  if (solidCount == 0) {
    throw Standard_Failure(
        "hole cut produced an empty result: the hole consumed the entire target body");
  }
  if (solidCount > 1) {
    throw Standard_Failure(("hole cut produced " + std::to_string(solidCount) +
                            " disjoint solids; a hole must not sever its target body")
                               .c_str());
  }
  const TopExp_Explorer solids(result, TopAbs_SOLID);
  EvaluatedBody body = FinishSolidBody(operation, TopoDS::Solid(solids.Current()), "hole result");
  if (elementNames != nullptr) {
    const occ::handle<BRepTools_History> history = cut.History();
    if (history.IsNull())
      throw Standard_Failure("hole cut did not record algorithm history");
    // The synthesized tool cylinder has no document identity of its own (it
    // never appears as a body), so its sub-shapes root at the hole operation
    // — mirroring the mutation fixtures' cutting tools: the bore wall's name
    // then reads as an image minted by the hole.
    elementNames->AddPrimitive(operationId, toolMaker.Shape());
    elementNames->ApplyOperation(operationId, {target, toolMaker.Shape()}, body.shape, *history,
                                 cancelled);
    if (registry != nullptr) {
      // Tranche N3: register the synthetic tool's sub-shapes (so the cut's
      // provenance terminates at real tokens), then harvest the cut through
      // the SAME retained history the naming pass consumed. Tool sub-shapes
      // that do not survive into the result die in the harvest's sweep.
      registry->HarvestSyntheticTool(operationId, toolMaker.Shape(), cancelled);
      registry->HarvestOperation(operationId, NamingRegistry::OperationClass::Hole,
                                 {{target, false, false}, {toolMaker.Shape(), true, true}},
                                 body.shape, *history, cancelled);
    }
  }
  return body;
}

EvaluatedBody EvaluateExtrude(const nlohmann::json& operation,
                              const std::map<std::string, EvaluatedProfile>& profiles,
                              const std::map<std::string, EvaluatedOpenPath>& openPaths,
                              BodyPool& pool, ElementNameBook* elementNames,
                              NamingRegistry* registry, const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const auto finishBirth = [&](TopoDS_Shape shape, const gp_Pnt& start, const gp_Pnt& end,
                               const gp_Dir& normal) {
    EvaluatedBody body = FinishBodyShape(operation, std::move(shape), "extrusion");
    if (elementNames != nullptr) {
      elementNames->AddPrimitive(body.operationId, body.shape);
      if (registry != nullptr) {
        registry->HarvestBirth(body.operationId, body.shape,
                               {NamingRegistry::BirthClass::Extrude,
                                NamingRegistry::BirthBoundary{start, normal, true},
                                NamingRegistry::BirthBoundary{end, normal, true}},
                               cancelled);
      }
    }
    return body;
  };
  // v2 detection: if extent field exists, it's v2; otherwise v1
  if (!parameters.contains("extent")) {
    // --- v1 legacy path ---
    const std::string profileOperationId = parameters.at("profileOperationId").get<std::string>();
    const double distance = parameters.at("distance").get<double>();
    const std::string direction = parameters.value("direction", "normal");
    if (!(distance > 0.0))
      throw std::invalid_argument("extrude distance must be positive");
    if (direction != "normal" && direction != "reverse")
      throw std::invalid_argument("unsupported extrude direction: " + direction);
    const double sign = direction == "reverse" ? -1.0 : 1.0;
    const auto profile = profiles.find(profileOperationId);
    if (profile == profiles.end()) {
      throw ReferenceMissing(operation.at("id").get<std::string>(),
                             "extrude references operation " + profileOperationId +
                                 ", which is not an evaluated profile operation earlier in the "
                                 "document");
    }
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    BRepPrimAPI_MakePrism maker(profile->second.shape,
                                sign * distance * gp_Vec(profile->second.normal),
                                /*Copy=*/true);
    maker.Build(progress->Start());
    CheckCancellation(cancelled);
    if (!maker.IsDone())
      throw std::runtime_error("extrude prism construction failed");
    const TopoDS_Shape result = maker.Shape();
    return finishBirth(
        result, profile->second.origin,
        profile->second.origin.Translated(sign * distance * gp_Vec(profile->second.normal)),
        profile->second.normal);
  }
  // --- v2 professional path ---
  const double taperDeg = parameters.value("taperAngleDeg", 0.0);
  if (std::abs(taperDeg) > 89.0)
    throw std::invalid_argument("taperAngleDeg must be within [-89, 89]");
  const bool hasThin = parameters.contains("thin") && !parameters.at("thin").is_null();
  if (hasThin) {
    const auto& thin = parameters.at("thin");
    const double th = thin.at("thicknessMm").get<double>();
    if (!(th > 0.0 && th <= 1e6))
      throw std::invalid_argument("thin thicknessMm must be positive");
  }
  const std::string direction = parameters.value("direction", "normal");
  if (direction != "normal" && direction != "reverse")
    throw std::invalid_argument("unsupported extrude direction: " + direction);
  const double dirSign = direction == "reverse" ? -1.0 : 1.0;

  // profile source — a sketch/profile operation, an open sketch path, or a
  // solid face
  TopoDS_Shape baseShape;
  gp_Vec normalVec;
  gp_Pnt origin;
  // True once the thin wall has been expressed as the profile itself (the
  // open-path band), so the solid-hollowing step below must not run again.
  bool thinAppliedAsBand = false;
  if (parameters.contains("faceProfile") && !parameters.at("faceProfile").is_null()) {
    if (registry == nullptr)
      throw std::invalid_argument("faceProfile extrude requires naming registry");
    const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
    const RefResolution res =
        ResolveRefSlotStrict(operation.at("id").get<std::string>(), "extrude", "faceProfile",
                             parameters.at("faceProfile"), peeked, *registry, cancelled);
    const QueryEntity& entity = SingleResolvedEntity("extrude", "faceProfile", 'f', res);
    TopoDS_Face face = TopoDS::Face(entity.shape);
    BRepAdaptor_Surface surf(face, true);
    if (surf.GetType() != GeomAbs_Plane)
      throw OperationFailure(operation.at("id").get<std::string>(), "INVALID_REQUEST",
                             "faceProfile must be a planar face",
                             {{"code", "E_EXTRUDE_FACE_NOT_PLANAR"}});
    gp_Pln pln = surf.Plane();
    baseShape = face;
    gp_Dir faceNormal = pln.Axis().Direction();
    if (face.Orientation() == TopAbs_REVERSED)
      faceNormal.Reverse();
    normalVec = gp_Vec(faceNormal);
    origin = pln.Location();
  } else if (parameters.contains("profileOperationId") &&
             !parameters.at("profileOperationId").is_null()) {
    std::string profileOperationId = parameters.at("profileOperationId").get<std::string>();
    const auto profileIt = profiles.find(profileOperationId);
    if (profileIt == profiles.end()) {
      // Not a region — it may still be an open path, which Thin Extrude can
      // follow as a wall.
      const auto pathIt = openPaths.find(profileOperationId);
      if (pathIt != openPaths.end()) {
        const EvaluatedOpenPath& path = pathIt->second;
        normalVec = path.normal;
        origin = path.origin;
        if (!hasThin)
          throw OperationFailure(
              operation.at("id").get<std::string>(), "INVALID_REQUEST",
              "this sketch draws an open path, which encloses no area; only Thin Extrude can "
              "turn a path into a wall — close the profile or set a thin wall thickness",
              {{"code", "E_EXTRUDE_OPEN_PROFILE_REQUIRES_THIN"}});
        const auto& thin = parameters.at("thin");
        const double wallThickness = thin.at("thicknessMm").get<double>();
        const std::string wallPosition = thin.value("position", "midPlane");
        // Build the wall as a planar BAND on the sketch plane, then let the
        // ordinary prism/extent/boolean machinery below consume it like any
        // other profile face. Thickening the swept shell in 3D instead would
        // also inflate the free top and bottom edges, making a 10mm-tall wall
        // measure 15.66mm — right-looking, wrong geometry.
        //
        // The band's two long edges are in-plane offsets of the authored path;
        // its two short edges are straight caps between the offset endpoints,
        // which is what keeps the wall's ends flat rather than rounded.
        // Side 1 and Side 2 both run from the path to an offset, differing
        // only in which side that offset is on; Center straddles the path.
        // Keeping the authored path as the FIRST edge for both one-sided
        // cases makes them exact mirrors of each other.
        const double edgeA = wallPosition == "midPlane" ? -wallThickness / 2.0 : 0.0;
        const double edgeB = wallPosition == "midPlane"  ? wallThickness / 2.0
                             : wallPosition == "twoSide" ? -wallThickness
                                                         : wallThickness;
        const auto offsetPath = [&](const double distance) -> TopoDS_Wire {
          if (std::abs(distance) < 1e-12)
            return path.wire;
          BRepOffsetAPI_MakeOffset mk;
          // IsOpenResult=true keeps the result a one-sided open wire; the
          // default closes it into a loop around the path, which would make
          // the wall's ends round instead of flat.
          mk.Init(GeomAbs_Arc, /*IsOpenResult=*/true);
          mk.AddWire(path.wire);
          mk.Perform(distance);
          if (!mk.IsDone() || mk.Shape().IsNull())
            throw OperationFailure(operation.at("id").get<std::string>(), "THIN_FAILED",
                                   "thin wall could not offset the open path",
                                   {{"code", "E_EXTRUDE_THIN_OPEN_OFFSET_FAILED"}});
          TopExp_Explorer wireExplorer(mk.Shape(), TopAbs_WIRE);
          if (!wireExplorer.More())
            throw OperationFailure(operation.at("id").get<std::string>(), "THIN_FAILED",
                                   "thin wall offset produced no usable path",
                                   {{"code", "E_EXTRUDE_THIN_OPEN_OFFSET_FAILED"}});
          return TopoDS::Wire(wireExplorer.Current());
        };
        const TopoDS_Wire wallEdgeA = offsetPath(edgeA);
        const TopoDS_Wire wallEdgeB = offsetPath(edgeB);
        TopoDS_Vertex a0, a1, b0, b1;
        TopExp::Vertices(wallEdgeA, a0, a1);
        TopExp::Vertices(wallEdgeB, b0, b1);
        if (a0.IsNull() || a1.IsNull() || b0.IsNull() || b1.IsNull())
          throw OperationFailure(operation.at("id").get<std::string>(), "THIN_FAILED",
                                 "thin wall could not find the ends of the open path",
                                 {{"code", "E_EXTRUDE_THIN_OPEN_FAILED"}});
        // Build the band contour edge by edge in an explicit order. Handing
        // BRepBuilderAPI_MakeWire two open wires and two caps lets it choose
        // its own traversal for the second wire, which crossed the caps into
        // a bowtie: the twoSide band came out enclosing the whole 40x30
        // rectangle (area 1200) instead of a ~136 wall, and only surfaced as
        // an invalid face afterwards.
        const auto orderedEdges = [](const TopoDS_Wire& wire) {
          std::vector<TopoDS_Edge> edges;
          for (BRepTools_WireExplorer explorer(wire); explorer.More(); explorer.Next())
            edges.push_back(TopoDS::Edge(explorer.Current()));
          return edges;
        };
        const std::vector<TopoDS_Edge> edgesA = orderedEdges(wallEdgeA);
        const std::vector<TopoDS_Edge> edgesB = orderedEdges(wallEdgeB);
        if (edgesA.empty() || edgesB.empty())
          throw OperationFailure(operation.at("id").get<std::string>(), "THIN_FAILED",
                                 "thin wall edges are empty",
                                 {{"code", "E_EXTRUDE_THIN_OPEN_FAILED"}});
        // Walk the second edge in whichever direction starts nearest the end
        // of the first, so the two caps join corresponding ends and never
        // cross.
        const gp_Pnt endOfA = BRep_Tool::Pnt(a1);
        const bool traverseBForward =
            endOfA.Distance(BRep_Tool::Pnt(b0)) <= endOfA.Distance(BRep_Tool::Pnt(b1));
        const TopoDS_Vertex bEntry = traverseBForward ? b0 : b1;
        const TopoDS_Vertex bExit = traverseBForward ? b1 : b0;
        BRepBuilderAPI_MakeWire band;
        for (const TopoDS_Edge& edge : edgesA)
          band.Add(edge);
        band.Add(BRepBuilderAPI_MakeEdge(a1, bEntry).Edge());
        if (traverseBForward) {
          for (const TopoDS_Edge& edge : edgesB)
            band.Add(edge);
        } else {
          for (auto it = edgesB.rbegin(); it != edgesB.rend(); ++it)
            band.Add(*it);
        }
        band.Add(BRepBuilderAPI_MakeEdge(bExit, a0).Edge());
        if (!band.IsDone())
          throw OperationFailure(operation.at("id").get<std::string>(), "THIN_FAILED",
                                 "thin wall edges do not close into a band",
                                 {{"code", "E_EXTRUDE_THIN_OPEN_FAILED"}});
        BRepBuilderAPI_MakeFace bandFace(gp_Pln(gp_Ax3(path.frame)), band.Wire(),
                                         /*Inside=*/true);
        if (!bandFace.IsDone())
          throw OperationFailure(operation.at("id").get<std::string>(), "THIN_FAILED",
                                 "thin wall band is not a valid planar face",
                                 {{"code", "E_EXTRUDE_THIN_OPEN_FAILED"}});
        const TopoDS_Face wallProfile = bandFace.Face();
        // A path that turns tighter than the wall thickness folds the band
        // over itself. OCCT is the authority on whether that happened.
        // A path that turns tighter than the wall thickness folds the band
        // over itself. OCCT is the authority on whether that happened.
        if (!BRepCheck_Analyzer(wallProfile, true).IsValid())
          throw OperationFailure(
              operation.at("id").get<std::string>(), "THIN_FAILED",
              "thin wall self-intersects: the path turns tighter than the wall thickness",
              {{"code", "E_EXTRUDE_THIN_OPEN_SELF_INTERSECT"}});
        baseShape = wallProfile;
        thinAppliedAsBand = true;
      } else {
        throw ReferenceMissing(
            operation.at("id").get<std::string>(),
            "extrude references operation " + profileOperationId +
                ", which is not an evaluated profile operation earlier in the document");
      }
    } else {
      const EvaluatedProfile& prof = profileIt->second;
      normalVec = prof.normal;
      origin = prof.frame.Location();
      if (parameters.contains("sketchRegionIds") && !parameters.at("sketchRegionIds").is_null()) {
        // Select a durable subset of the sketch's regions instead of the whole
        // compound. Every requested id must resolve against the profile's
        // current regionIds (parallel to prof.faces) — an id that does not
        // match, including because the sketch no longer has a region built
        // from that entity set, fails closed rather than silently extruding a
        // different region or the whole sketch.
        std::vector<std::string> requested;
        for (const auto& idJson : parameters.at("sketchRegionIds")) {
          requested.push_back(idJson.get<std::string>());
        }
        std::vector<TopoDS_Face> selected;
        for (const std::string& want : requested) {
          bool found = false;
          for (std::size_t i = 0; i < prof.regionIds.size(); ++i) {
            if (prof.regionIds[i] == want) {
              selected.push_back(prof.faces[i]);
              found = true;
              break;
            }
          }
          if (!found) {
            throw ReferenceMissing(
                operation.at("id").get<std::string>(),
                "extrude sketchRegionIds references region '" + want +
                    "', which is not a current region of sketch " + profileOperationId +
                    " (it may have been removed or its bounding entities changed)");
          }
        }
        if (selected.empty())
          throw std::invalid_argument("extrude sketchRegionIds must not be empty");
        if (selected.size() == 1) {
          baseShape = selected.front();
        } else {
          TopoDS_Compound compound;
          BRep_Builder builder;
          builder.MakeCompound(compound);
          for (const TopoDS_Face& face : selected)
            builder.Add(compound, face);
          baseShape = compound;
        }
      } else {
        baseShape = prof.shape;
      }
    }
  } else {
    throw std::invalid_argument("extrude v2 requires profileOperationId or faceProfile");
  }

  // start offset
  double startOffset = 0.0;
  if (parameters.contains("start") && parameters.at("start").contains("mode")) {
    const auto& start = parameters.at("start");
    const std::string sm = start.at("mode").get<std::string>();
    if (sm == "offset") {
      startOffset = start.at("offsetMm").get<double>();
    } else if (sm == "profilePlane") {
      startOffset = 0.0;
    } else if (sm == "object") {
      // Start from a durable planar reference. The distance to travel is
      // derived from where that face actually is now, so an upstream move of
      // the referenced face moves the extrusion's start with it. Resolution
      // is strict: a missing or ambiguous reference refuses rather than
      // silently starting at the profile plane.
      if (!parameters.contains("startObject") || parameters.at("startObject").is_null())
        throw std::invalid_argument("extrude start object requires startObject reference");
      if (registry == nullptr)
        throw std::invalid_argument("extrude start object requires naming registry");
      const std::vector<EvaluatedBody> peekedStart = pool.PeekVisibleBodies();
      const RefResolution resStart =
          ResolveRefSlotStrict(operation.at("id").get<std::string>(), "extrude", "startObject",
                               parameters.at("startObject"), peekedStart, *registry, cancelled);
      const QueryEntity& entityStart =
          SingleResolvedEntity("extrude", "startObject", 'f', resStart);
      TopoDS_Face startFace = TopoDS::Face(entityStart.shape);
      BRepAdaptor_Surface surfStart(startFace, true);
      if (surfStart.GetType() != GeomAbs_Plane)
        throw OperationFailure(operation.at("id").get<std::string>(), "INVALID_REQUEST",
                               "start object must be a planar face",
                               {{"code", "E_EXTRUDE_START_OBJECT_NOT_PLANAR"}});
      gp_Pln planeStart = surfStart.Plane();
      const gp_Vec planeNormalStart(planeStart.Axis().Direction());
      const double dotStart = planeNormalStart.Dot(normalVec);
      if (std::abs(std::abs(dotStart) - 1.0) > 1e-6)
        throw OperationFailure(operation.at("id").get<std::string>(), "INVALID_REQUEST",
                               "start object face must be parallel to the profile plane",
                               {{"code", "E_EXTRUDE_START_OBJECT_NOT_PARALLEL"}});
      // Signed distance from the profile plane to the resolved face, measured
      // along the profile normal, plus any authored extra offset.
      const gp_Vec toStart(origin, planeStart.Location());
      startOffset = toStart.Dot(normalVec) + start.value("offsetMm", 0.0);
    } else {
      throw std::invalid_argument("unsupported extrude start mode: " + sm);
    }
  }
  if (std::abs(startOffset) > 1e-9) {
    gp_Trsf trsf;
    trsf.SetTranslation(startOffset * normalVec);
    BRepBuilderAPI_Transform mover(baseShape, trsf, true);
    baseShape = mover.Shape();
    origin.Translate(startOffset * normalVec);
  }

  // extent
  const auto& extent = parameters.at("extent");
  const std::string mode = extent.at("mode").get<std::string>();
  double fwd = 0.0, bwd = 0.0;
  bool isThroughAll = false;
  bool isToFace = false;
  double toFaceOffset = 0.0;
  if (mode == "distance") {
    fwd = extent.at("distanceMm").get<double>();
  } else if (mode == "symmetric") {
    double d = extent.at("distanceMm").get<double>();
    fwd = d;
    bwd = d;
  } else if (mode == "twoSided") {
    fwd = extent.at("distanceForwardMm").get<double>();
    bwd = extent.at("distanceBackwardMm").get<double>();
  } else if (mode == "throughAll") {
    // Through-all is body-aware: travel exactly far enough to clear every
    // visible body along the extrusion direction, measured from the (already
    // start-offset) profile origin against real geometry. The previous 1e6
    // sentinel was independent of the scene — it produced the same absurd
    // prism whether the target was 1mm or 1km away, and any "correct" result
    // was incidental.
    isThroughAll = true;
    const gp_Vec throughDir = dirSign * normalVec;
    double furthest = -std::numeric_limits<double>::infinity();
    for (const EvaluatedBody& visible : pool.PeekVisibleBodies()) {
      Bnd_Box box;
      BRepBndLib::Add(visible.shape, box, /*useTriangulation=*/false);
      if (box.IsVoid())
        continue;
      double bxMin, byMin, bzMin, bxMax, byMax, bzMax;
      box.Get(bxMin, byMin, bzMin, bxMax, byMax, bzMax);
      // Project all eight corners; the box is axis-aligned but the extrusion
      // direction is arbitrary, so the furthest corner is not predictable.
      for (int corner = 0; corner < 8; ++corner) {
        const gp_Pnt point((corner & 1) ? bxMax : bxMin, (corner & 2) ? byMax : byMin,
                           (corner & 4) ? bzMax : bzMin);
        furthest = std::max(furthest, gp_Vec(origin, point).Dot(throughDir));
      }
    }
    if (!std::isfinite(furthest) || furthest <= 1e-9) {
      // Nothing lies ahead to pass through. Inventing a length here would be
      // a guess presented as geometry, so refuse with attribution instead.
      throw OperationFailure(
          operation.at("id").get<std::string>(), "INVALID_REQUEST",
          "through-all found no visible geometry ahead of the profile to pass through",
          {{"code", "E_EXTRUDE_THROUGHALL_NO_TARGET"}});
    }
    // Clear the far side rather than ending exactly coplanar with the last
    // face, which would leave a zero-thickness cut that booleans treat as
    // tangent contact.
    fwd = furthest + std::max(1.0, furthest * 1e-3);
  } else if (mode == "toFace") {
    isToFace = true;
    toFaceOffset = extent.value("offsetMm", 0.0);
    if (!parameters.contains("toFace"))
      throw std::invalid_argument("toFace extrude requires toFace reference");
    if (registry == nullptr)
      throw std::invalid_argument("toFace extrude requires naming registry");
    const std::vector<EvaluatedBody> peeked2 = pool.PeekVisibleBodies();
    const RefResolution res2 =
        ResolveRefSlotStrict(operation.at("id").get<std::string>(), "extrude", "toFace",
                             parameters.at("toFace"), peeked2, *registry, cancelled);
    const QueryEntity& entity2 = SingleResolvedEntity("extrude", "toFace", 'f', res2);
    TopoDS_Face targetFace = TopoDS::Face(entity2.shape);
    BRepAdaptor_Surface surf2(targetFace, true);
    if (surf2.GetType() != GeomAbs_Plane)
      throw OperationFailure(operation.at("id").get<std::string>(), "INVALID_REQUEST",
                             "toFace target must be a planar face",
                             {{"code", "E_EXTRUDE_TOFACE_NOT_PLANAR"}});
    gp_Pln plane2 = surf2.Plane();
    gp_Vec planeNormal2 = plane2.Axis().Direction();
    double dot2 = planeNormal2.Dot(gp_Vec(normalVec));
    if (std::abs(std::abs(dot2) - 1.0) > 1e-6)
      throw OperationFailure(operation.at("id").get<std::string>(), "INVALID_REQUEST",
                             "toFace target face must be parallel to profile plane",
                             {{"code", "E_EXTRUDE_TOFACE_NOT_PARALLEL"}});
    gp_Vec toTarget2 = gp_Vec(origin, plane2.Location());
    double signedDist2 = toTarget2.Dot(gp_Vec(normalVec));
    double distAlongDir2 = signedDist2 * dirSign;
    fwd = distAlongDir2 + toFaceOffset;
    if (fwd < 1e-9)
      throw OperationFailure(
          operation.at("id").get<std::string>(), "INVALID_REQUEST",
          "toFace distance is non-positive — target is behind profile or too close",
          {{"code", "E_EXTRUDE_TOFACE_BEHIND"}});
  } else {
    throw std::invalid_argument("unsupported extrude extent mode: " + mode);
  }
  if (!(fwd >= 0.0) || !(bwd >= 0.0))
    throw std::invalid_argument("extrude distances must be non-negative");
  if (fwd < 1e-9 && bwd < 1e-9)
    throw std::invalid_argument("extrude requires non-zero distance");

  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);

  auto makePrism = [&](const TopoDS_Shape& base, double h, gp_Vec dir) -> TopoDS_Shape {
    if (h < 1e-9)
      return TopoDS_Shape();
    BRepPrimAPI_MakePrism maker(base, h * dir, /*Copy=*/true);
    maker.Build(progress->Start());
    CheckCancellation(cancelled);
    if (!maker.IsDone())
      throw std::runtime_error("extrude prism construction failed");
    return maker.Shape();
  };

  TopoDS_Shape result;
  // Real per-face draft via BRepOffsetAPI_DraftAngle — replaces the
  // uniform-scale loft provisional. Side faces are drafted about the
  // profile plane (neutral plane at origin) with the authored angle.
  // Fail-closed on unsupported topology or OCCT refusal; never silently
  // falls back to an untapered prism.
  auto makeTapered = [&](const TopoDS_Shape& base, double h, gp_Vec dir,
                         double taper) -> TopoDS_Shape {
    if (std::abs(taper) < 1e-9) {
      return makePrism(base, h, dir);
    }
    // Build the straight prism first, then draft its side faces.
    TopoDS_Shape prism = makePrism(base, h, dir);
    if (prism.IsNull()) {
      throw OperationFailure(operation.at("id").get<std::string>(), "GEOMETRY_FAILED",
                             "taper prism build failed", {{"code", "E_EXTRUDE_TAPER_FAILED"}});
    }
    try {
      // DraftAngle sign: positive removes matter, negative adds. Extrude taper
      // positive is defined as outward splay (adds matter, larger top), so
      // invert sign relative to DraftAngle's convention.
      const double angleRad = -taper * 0.017453292519943295;
      // Neutral plane is the profile plane at the start origin; prism
      // origin is already offset by startOffset, and dir already includes
      // dirSign. For bwd leg, origin is the same neutral plane but dir
      // points opposite — draft still measured from that plane.
      gp_Dir draftDir(dir.X(), dir.Y(), dir.Z());
      gp_Pln neutralPlane(origin, draftDir);
      BRepOffsetAPI_DraftAngle draft(prism);
      // Identify side faces: those whose normal is ~perpendicular to draftDir.
      // Caps have normals parallel to draftDir (dot ~ ±1).
      int sideFaces = 0;
      for (TopExp_Explorer ex(prism, TopAbs_FACE); ex.More(); ex.Next()) {
        TopoDS_Face face = TopoDS::Face(ex.Current());
        BRepAdaptor_Surface adapt(face, true);
        GeomAbs_SurfaceType st = adapt.GetType();
        // Only planar/cylindrical/conical faces can be drafted per OCCT docs.
        // Skip other types — they will cause AddDone() failure and we
        // fail closed rather than silently leaving them undrafted.
        if (st != GeomAbs_Plane && st != GeomAbs_Cylinder && st != GeomAbs_Cone) {
          continue;
        }
        // Compute face normal via plane or surface normal at a point.
        gp_Dir faceNormal;
        if (st == GeomAbs_Plane) {
          gp_Pln pln = adapt.Plane();
          faceNormal = pln.Axis().Direction();
          if (face.Orientation() == TopAbs_REVERSED)
            faceNormal.Reverse();
        } else {
          // For cylinder/cone, approximate normal via surface normal at mid param.
          // Use adapt normals at (0,0) — sufficient to distinguish side vs cap.
          gp_Pnt p;
          gp_Vec dU, dV;
          adapt.D1(0, 0, p, dU, dV);
          gp_Vec n = dU.Crossed(dV);
          if (n.Magnitude() < 1e-12)
            continue;
          faceNormal = gp_Dir(n);
          if (face.Orientation() == TopAbs_REVERSED)
            faceNormal.Reverse();
        }
        double dot = std::abs(faceNormal.Dot(draftDir));
        // Caps: dot ~1 (normal parallel to extrusion). Sides: dot ~0.
        if (dot > 0.5) {
          continue; // cap face — do not draft
        }
        draft.Add(face, draftDir, angleRad, neutralPlane);
        if (!draft.AddDone()) {
          throw OperationFailure(operation.at("id").get<std::string>(), "GEOMETRY_FAILED",
                                 "taper draft failed on side face",
                                 {{"code", "E_EXTRUDE_TAPER_FAILED"}});
        }
        sideFaces++;
      }
      if (sideFaces == 0) {
        throw OperationFailure(operation.at("id").get<std::string>(), "GEOMETRY_FAILED",
                               "taper found no draftable side faces",
                               {{"code", "E_EXTRUDE_TAPER_FAILED"}});
      }
      draft.Build(progress->Start());
      CheckCancellation(cancelled);
      if (!draft.IsDone() || draft.Shape().IsNull()) {
        throw OperationFailure(operation.at("id").get<std::string>(), "GEOMETRY_FAILED",
                               "taper draft build failed", {{"code", "E_EXTRUDE_TAPER_FAILED"}});
      }
      TopoDS_Shape drafted = draft.Shape();
      // Validate: drafted shape must be a single solid and pass BRepCheck.
      if (Count(drafted, TopAbs_SOLID) != 1) {
        throw OperationFailure(operation.at("id").get<std::string>(), "GEOMETRY_FAILED",
                               "taper draft produced non-singular solid",
                               {{"code", "E_EXTRUDE_TAPER_FAILED"}});
      }
      if (!BRepCheck_Analyzer(drafted, false).IsValid()) {
        throw OperationFailure(operation.at("id").get<std::string>(), "GEOMETRY_FAILED",
                               "taper draft produced invalid solid (self-intersection)",
                               {{"code", "E_EXTRUDE_TAPER_FAILED"}});
      }
      return drafted;
    } catch (const Cancelled&) {
      throw;
    } catch (const OperationFailure&) {
      throw;
    } catch (const Standard_Failure& error) {
      throw OperationFailure(operation.at("id").get<std::string>(), "GEOMETRY_FAILED",
                             std::string("taper draft failed: ") + error.what(),
                             {{"code", "E_EXTRUDE_TAPER_FAILED"}});
    } catch (const std::exception& error) {
      throw OperationFailure(operation.at("id").get<std::string>(), "GEOMETRY_FAILED",
                             std::string("taper draft failed: ") + error.what(),
                             {{"code", "E_EXTRUDE_TAPER_FAILED"}});
    } catch (...) {
      throw OperationFailure(operation.at("id").get<std::string>(), "GEOMETRY_FAILED",
                             "taper draft failed", {{"code", "E_EXTRUDE_TAPER_FAILED"}});
    }
  };

  if (std::abs(taperDeg) > 1e-9 && (isThroughAll || isToFace)) {
    throw OperationFailure(operation.at("id").get<std::string>(), "INVALID_REQUEST",
                           "taper with through-all or to-face extent is not yet supported",
                           {{"code", "E_EXTRUDE_TAPER_EXTENT_UNSUPPORTED"}});
  }

  // Build main prism(s)
  TopoDS_Shape fwdShape, bwdShape;
  if (fwd > 1e-9) {
    gp_Vec fwdDir = dirSign * gp_Vec(normalVec);
    fwdShape = makeTapered(baseShape, fwd, fwdDir, taperDeg);
  }
  if (bwd > 1e-9) {
    gp_Vec bwdDir = -dirSign * gp_Vec(normalVec);
    bwdShape = makeTapered(baseShape, bwd, bwdDir, taperDeg);
  }
  if (!fwdShape.IsNull() && !bwdShape.IsNull()) {
    BRepAlgoAPI_Fuse fuse(fwdShape, bwdShape);
    fuse.Build(progress->Start());
    CheckCancellation(cancelled);
    if (!fuse.IsDone())
      throw std::runtime_error("extrude two-sided fuse failed");
    result = fuse.Shape();
  } else if (!fwdShape.IsNull()) {
    result = fwdShape;
  } else if (!bwdShape.IsNull()) {
    result = bwdShape;
  } else {
    throw std::runtime_error("extrude produced no geometry");
  }

  // thin: hollow solid to create wall of thickness t.
  // All three positions are implemented via offset+cut provisional;
  // fail-closed on any hollow failure per SUPERIORITY_LAW. The intended
  // manufacturable path is BRepOffsetAPI_MakeThickSolid; current path is
  // measured and refuses self-intersection with attribution.
  // An open-path wall already IS its thin profile (the band), so hollowing it
  // again would carve a void out of the wall itself.
  if (hasThin && !thinAppliedAsBand) {
    const auto& thin = parameters.at("thin");
    double th = thin.at("thicknessMm").get<double>();
    std::string pos = thin.value("position", "midPlane");
    if (pos == "midPlane" || pos == "twoSide" || pos == "oneSide") {
      bool hollowed = false;
      TopoDS_Shape hollowResult;
      try {
        BRepOffsetAPI_MakeOffsetShape offset;
        // oneSide material is on one side of the profile: use full thickness
        // inward offset (same as twoSide). midPlane is centered (half thickness).
        double off = (pos == "midPlane") ? -th / 2.0 : -th;
        offset.PerformByJoin(result, off, 1e-6, BRepOffset_Skin, false, false, GeomAbs_Arc, true,
                             progress->Start());
        if (!offset.IsDone() || offset.Shape().IsNull())
          throw OperationFailure(operation.at("id").get<std::string>(), "THIN_FAILED",
                                 "thin offset failed", {{"code", "E_EXTRUDE_THIN_OFFSET_FAILED"}});
        TopoDS_Shape inner = offset.Shape();
        BRepAlgoAPI_Cut cut(result, inner);
        cut.Build(progress->Start());
        CheckCancellation(cancelled);
        if (!cut.IsDone() || cut.Shape().IsNull())
          throw OperationFailure(operation.at("id").get<std::string>(), "THIN_FAILED",
                                 "thin cut failed", {{"code", "E_EXTRUDE_THIN_CUT_FAILED"}});
        GProp_GProps propsOuter, propsCut;
        BRepGProp::VolumeProperties(result, propsOuter);
        BRepGProp::VolumeProperties(cut.Shape(), propsCut);
        if (!(propsCut.Mass() < propsOuter.Mass() * 0.98 && propsCut.Mass() > 1e-9))
          throw OperationFailure(operation.at("id").get<std::string>(), "THIN_FAILED",
                                 "thin hollow produced no volume reduction",
                                 {{"code", "E_EXTRUDE_THIN_NO_REDUCTION"}});
        hollowResult = cut.Shape();
        hollowed = true;
      } catch (const OperationFailure&) {
        throw;
      } catch (const std::exception& e) {
        throw OperationFailure(operation.at("id").get<std::string>(), "THIN_FAILED",
                               std::string("thin hollow failed: ") + e.what(),
                               {{"code", "E_EXTRUDE_THIN_FAILED"}});
      } catch (...) {
        throw OperationFailure(operation.at("id").get<std::string>(), "THIN_FAILED",
                               "thin hollow failed", {{"code", "E_EXTRUDE_THIN_FAILED"}});
      }
      if (!hollowed)
        throw OperationFailure(operation.at("id").get<std::string>(), "THIN_FAILED",
                               "thin hollow produced no result",
                               {{"code", "E_EXTRUDE_THIN_FAILED"}});
      result = hollowResult;
    } else {
      throw OperationFailure(operation.at("id").get<std::string>(), "INVALID_REQUEST",
                             "unsupported thin position", {{"code", "E_EXTRUDE_THIN_FAILED"}});
    }
  }

  // boolean handling — explicit target, never first overlapping
  if (parameters.contains("boolean")) {
    const auto& boolean = parameters.at("boolean");
    const std::string bMode = boolean.at("mode").get<std::string>();
    if (bMode != "newBody") {
      if (!boolean.contains("targetOperationId"))
        throw std::invalid_argument(
            "extrude boolean targetOperationId is required for join/cut/intersect");
      const std::string targetId = boolean.at("targetOperationId").get<std::string>();
      const std::string operationId = operation.at("id").get<std::string>();
      const TopoDS_Shape targetShape =
          pool.Consume(operationId, "extrude " + bMode, "target", targetId);
      const TopoDS_Shape toolShape = result;

      if (bMode == "cut" && !ToolRemovesMaterial(targetShape, toolShape, cancelled)) {
        throw Standard_Failure(
            "extrude cut removed no material: the extruded tool does not overlap the target body");
      }

      std::unique_ptr<BRepAlgoAPI_BooleanOperation> algorithm;
      if (bMode == "join") {
        algorithm = std::make_unique<BRepAlgoAPI_Fuse>();
      } else if (bMode == "cut") {
        algorithm = std::make_unique<BRepAlgoAPI_Cut>();
      } else if (bMode == "intersect") {
        algorithm = std::make_unique<BRepAlgoAPI_Common>();
      } else {
        throw std::invalid_argument("unsupported extrude boolean mode: " + bMode);
      }

      NCollection_List<TopoDS_Shape> objects;
      objects.Append(targetShape);
      NCollection_List<TopoDS_Shape> tools;
      tools.Append(toolShape);
      algorithm->SetArguments(objects);
      algorithm->SetTools(tools);
      algorithm->SetRunParallel(false);
      algorithm->SetToFillHistory(elementNames != nullptr);
      algorithm->Build(progress->Start());
      CheckCancellation(cancelled);
      if (algorithm->HasErrors())
        throw Standard_Failure(("extrude " + bMode + " boolean failed").c_str());

      const TopoDS_Shape booleanResult = algorithm->Shape();
      if (booleanResult.IsNull())
        throw Standard_Failure(("extrude " + bMode + " produced no result shape").c_str());
      const int solidCount = Count(booleanResult, TopAbs_SOLID);
      if (solidCount == 0) {
        throw Standard_Failure(("extrude " + bMode + " produced an empty result").c_str());
      }
      if (solidCount > 1) {
        throw Standard_Failure(("extrude " + bMode + " produced " + std::to_string(solidCount) +
                                " disjoint solids; an extrude boolean must produce one connected "
                                "solid")
                                   .c_str());
      }

      const TopExp_Explorer solids(booleanResult, TopAbs_SOLID);
      EvaluatedBody body = FinishSolidBody(operation, TopoDS::Solid(solids.Current()),
                                           ("extrude " + bMode + " result").c_str());
      if (elementNames != nullptr) {
        const occ::handle<BRepTools_History> history = algorithm->History();
        if (history.IsNull())
          throw Standard_Failure(
              ("extrude " + bMode + " did not record algorithm history").c_str());

        // The extrusion is a synthetic boolean operand. Profile-based tools
        // are fresh, while face-profile tools may share topology with their
        // source body; AddDerivedPrimitive handles both cases without
        // re-registering an already named source face.
        elementNames->AddDerivedPrimitive(operationId, toolShape);
        elementNames->ApplyOperation(operationId, {targetShape, toolShape}, body.shape, *history,
                                     cancelled);
        if (registry != nullptr) {
          registry->HarvestSyntheticTool(operationId, toolShape, cancelled);
          registry->HarvestOperation(operationId, NamingRegistry::OperationClass::Boolean,
                                     {{targetShape, false, false}, {toolShape, true, true}},
                                     body.shape, *history, cancelled);
        }
      }
      return body;
    }
  }

  const gp_Dir resolvedNormal(normalVec);
  return finishBirth(result, origin.Translated(-dirSign * bwd * normalVec),
                     origin.Translated(dirSign * fwd * normalVec), resolvedNormal);
}

// Sheet-metal wave, `base_flange`: creates the FIRST sheet-metal body from a
// planar profile. Under the OCCT call this makes, it is BYTE-IDENTICAL to a
// thin `extrude` — offset the profile's boundary by `thicknessMm` along the
// profile-plane normal and cap both ends, exactly the
// `BRepPrimAPI_MakePrism` sweep `EvaluateExtrude` above already performs.
// The difference is entirely in the TypeScript operation-type name and the
// downstream sheet-metal-aware operations (`edge_flange`, `unfold`) that
// treat this body's history as a sheet's base panel; this executor mirrors
// `EvaluateExtrude` field-for-field on purpose, right down to sharing its
// `(operation, profiles, cancelled)` signature (not a `pool`/registry-taking
// signature like `fillet`/`shell`) — `base_flange` is a root BIRTH, consuming
// no target body, so it is dispatched through `ExecuteOperation`'s
// `produceRoot` path exactly like `extrude`/`revolve`/`loft`/`sweep`, and its
// naming travels through `HarvestBirth`/`BirthClass::Extrude` (see
// `NamingBirthSpec` below) rather than `NamingRegistry::OperationClass`.
//
// `direction` is real from the start (unlike `extrude`, whose own `direction`
// field is currently a literal-only `"normal"` placeholder): a base panel is
// exactly as likely to need building away from its profile's normal as
// toward it (which side of a sketch a person happened to draw), so
// `"reverse"` prisms along the negated profile normal. This costs nothing —
// the sign is a single multiplier on the sweep vector — and is honest about
// being a real two-valued field rather than a single-literal enum reserved
// for the future the way extrude's is.
EvaluatedBody EvaluateBaseFlange(const nlohmann::json& operation,
                                 const std::map<std::string, EvaluatedProfile>& profiles,
                                 const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const std::string profileOperationId = parameters.at("profileOperationId").get<std::string>();
  const double thickness = parameters.at("thicknessMm").get<double>();
  const std::string direction = parameters.value("direction", "normal");
  if (!(std::isfinite(thickness) && thickness > 0.0))
    throw std::invalid_argument("base_flange thicknessMm must be positive");
  if (direction != "normal" && direction != "reverse")
    throw std::invalid_argument("unsupported base_flange direction: " + direction);
  const double sign = direction == "reverse" ? -1.0 : 1.0;

  const auto profile = profiles.find(profileOperationId);
  if (profile == profiles.end()) {
    // Operation-level reference failure (ADR-003), identical to extrude's.
    throw ReferenceMissing(operation.at("id").get<std::string>(),
                           "base_flange references operation " + profileOperationId +
                               ", which is not an evaluated profile operation earlier in the "
                               "document");
  }

  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  // Copy the base face so each base_flange owns its geometry even when
  // several sheet-metal bodies (or an extrude) consume the same profile
  // within one evaluation — the same discipline EvaluateExtrude applies.
  BRepPrimAPI_MakePrism maker(profile->second.shape,
                              sign * thickness * gp_Vec(profile->second.normal),
                              /*Copy=*/true);
  maker.Build(progress->Start());
  CheckCancellation(cancelled);
  if (!maker.IsDone())
    throw std::runtime_error("base_flange prism construction failed");
  const TopoDS_Shape result = maker.Shape();
  return FinishBodyShape(operation, result, "base flange");
}

EvaluatedBody EvaluateRevolveV1(const nlohmann::json& operation,
                                const std::map<std::string, EvaluatedProfile>& profiles,
                                const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const std::string profileOperationId = parameters.at("profileOperationId").get<std::string>();
  const double angleDegrees = parameters.at("angleDegrees").get<double>();
  if (!(angleDegrees > 0.0 && angleDegrees <= 360.0))
    throw std::invalid_argument("revolve angle must be within (0, 360] degrees");

  const auto profile = profiles.find(profileOperationId);
  if (profile == profiles.end()) {
    // Operation-level reference failure (ADR-003), identical to extrude: the
    // id names no operation, a non-profile operation, or a profile later in
    // the document — all the same contract violation to the kernel.
    throw ReferenceMissing(operation.at("id").get<std::string>(),
                           "revolve references operation " + profileOperationId +
                               ", which is not an evaluated profile operation earlier in the "
                               "document");
  }

  gp_Ax1 axis;
  if (parameters.contains("profileAxis")) {
    axis = ProfileRelativeAxis(profile->second, parameters.at("profileAxis").get<std::string>());
  } else {
    const gp_Vec axisOrigin = JsonVector(parameters.at("axisOrigin"));
    const gp_Vec axisDirection = JsonVector(parameters.at("axisDirection"));
    if (axisDirection.Magnitude() < 1e-9)
      throw std::invalid_argument("revolve axis direction must be non-zero");
    axis = gp_Ax1(gp_Pnt(axisOrigin.X(), axisOrigin.Y(), axisOrigin.Z()), gp_Dir(axisDirection));
  }
  // Degrees are the document unit; OCCT sweeps in radians. A full 360 request
  // goes through the no-angle constructor so the seam closes exactly rather
  // than at a 2*pi trim.
  constexpr double kDegreesToRadians = 0.017453292519943295;
  const bool fullRevolve = angleDegrees >= 360.0 - 1e-9;

  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  // Copy the base face so each revolve owns its geometry even when several
  // features consume the same profile within one evaluation.
  TopoDS_Shape result;
  if (fullRevolve) {
    BRepPrimAPI_MakeRevol maker(profile->second.shape, axis, /*Copy=*/true);
    maker.Build(progress->Start());
    CheckCancellation(cancelled);
    if (!maker.IsDone())
      throw Standard_Failure("revolve construction failed");
    result = maker.Shape();
  } else {
    BRepPrimAPI_MakeRevol maker(profile->second.shape, axis, angleDegrees * kDegreesToRadians,
                                /*Copy=*/true);
    maker.Build(progress->Start());
    CheckCancellation(cancelled);
    if (!maker.IsDone())
      throw Standard_Failure("revolve construction failed");
    result = maker.Shape();
  }

  if (result.IsNull() || Count(result, TopAbs_SOLID) == 0)
    throw Standard_Failure("revolve did not produce a solid body");
  // An axis that crosses the profile revolves material through itself; refuse
  // the self-intersecting result as a geometry failure (fail closed) rather
  // than emit an invalid body. FinishSolidBody re-checks validity as a
  // last-resort backstop.
  if (!BRepCheck_Analyzer(result, false).IsValid())
    throw Standard_Failure(
        "revolve produced an invalid solid; the axis must lie clear of the profile");
  return FinishBodyShape(operation, result, "revolution");
}

std::optional<std::string> UnfilteredWorldAxis(const nlohmann::json& ref) {
  if (!ref.contains("ast"))
    return std::nullopt;
  const nlohmann::json& ast = ref.at("ast");
  const auto scope = ast.find("scope");
  const auto filters = ast.find("filters");
  if (ast.value("kind", std::string()) != "edges" || scope == ast.end() || !scope->is_array() ||
      scope->size() != 1 || filters == ast.end() || !filters->is_array() || !filters->empty() ||
      !scope->front().is_object() || scope->front().value("source", std::string()) != "world")
    return std::nullopt;
  return scope->front().value("world", std::string());
}

gp_Ax1 CanonicalAxis(const gp_Ax1& authored) {
  gp_Dir direction = authored.Direction();
  const double eps = 1e-12;
  if (direction.X() < -eps || (std::abs(direction.X()) <= eps && direction.Y() < -eps) ||
      (std::abs(direction.X()) <= eps && std::abs(direction.Y()) <= eps && direction.Z() < 0.0))
    direction.Reverse();
  const gp_Vec d(direction);
  const gp_Vec p(authored.Location().X(), authored.Location().Y(), authored.Location().Z());
  const gp_Vec closest = p - d * p.Dot(d);
  return gp_Ax1(gp_Pnt(closest.X(), closest.Y(), closest.Z()), direction);
}

bool SameInfiniteAxis(const gp_Ax1& left, const gp_Ax1& right) {
  const gp_Ax1 a = CanonicalAxis(left);
  const gp_Ax1 b = CanonicalAxis(right);
  return std::abs(gp_Vec(a.Direction()).Dot(gp_Vec(b.Direction()))) >= 1.0 - 1e-10 &&
         a.Location().Distance(b.Location()) <= 1e-7;
}

[[noreturn]] void ThrowRevolveAxisAmbiguous(const std::string& operationId, const char* slotName) {
  throw SelectorFailure(operationId, "REFERENCE_AMBIGUOUS", "E_SEL_AMBIGUOUS",
                        std::string("revolve ") + slotName +
                            ": ambiguous candidates do not describe one infinite axis",
                        {{"selectorCode", "E_SEL_AMBIGUOUS"}});
}

gp_Ax1 ResolveRevolveAxis(const nlohmann::json& operation, const nlohmann::json& parameters,
                          const std::vector<EvaluatedBody>& bodies, NamingRegistry* registry,
                          const std::atomic_bool& cancelled) {
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string kind = parameters.at("axisSource").at("kind").get<std::string>();
  if (kind == "edge") {
    const nlohmann::json& ref = parameters.at("axisEdge");
    if (const std::optional<std::string> world = UnfilteredWorldAxis(ref); world.has_value()) {
      if (*world == "x")
        return gp_Ax1(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0));
      if (*world == "y")
        return gp_Ax1(gp_Pnt(0, 0, 0), gp_Dir(0, 1, 0));
      if (*world == "z")
        return gp_Ax1(gp_Pnt(0, 0, 0), gp_Dir(0, 0, 1));
      throw OperationFailure(operationId, "INVALID_REQUEST",
                             "Revolve axis must be world x, y, or z.",
                             {{"code", "E_REVOLVE_AXIS_WORLD_INVALID"}});
    }
    if (registry == nullptr)
      throw std::invalid_argument(
          "unsupported operation: Revolve axis requires the naming registry");
    nlohmann::json plural = ref;
    plural["arity"] = "any";
    const RefResolution resolution = ResolveRefSlotStrict(operationId, "revolve", "axisEdge",
                                                          plural, bodies, *registry, cancelled);
    std::optional<gp_Ax1> resolvedAxis;
    for (const QueryEntity& entity : resolution.entities) {
      if (entity.kind != 'e')
        throw OperationFailure(operationId, "REFERENCE_WRONG_KIND",
                               "Revolve axis reference resolved a non-edge.",
                               {{"code", "E_REVOLVE_AXIS_NOT_EDGE"}});
      const BRepAdaptor_Curve curve(TopoDS::Edge(entity.shape));
      if (curve.GetType() != GeomAbs_Line)
        throw OperationFailure(operationId, "REFERENCE_WRONG_KIND",
                               "Revolve needs a straight edge, construction line, datum axis, or "
                               "world axis.",
                               {{"code", "E_REVOLVE_AXIS_NOT_LINEAR"}});
      const gp_Ax1 candidate = CanonicalAxis(curve.Line().Position());
      if (resolvedAxis.has_value() && !SameInfiniteAxis(*resolvedAxis, candidate))
        ThrowRevolveAxisAmbiguous(operationId, "axisEdge");
      resolvedAxis = candidate;
    }
    if (!resolvedAxis.has_value())
      throw ReferenceMissing(operationId, "Revolve axisEdge reference resolved no entities.");
    return *resolvedAxis;
  }
  if (kind == "rotationalFace") {
    if (registry == nullptr)
      throw std::invalid_argument(
          "unsupported operation: Revolve face axis requires the naming registry");
    nlohmann::json plural = parameters.at("axisFace");
    plural["arity"] = "any";
    const RefResolution resolution = ResolveRefSlotStrict(operationId, "revolve", "axisFace",
                                                          plural, bodies, *registry, cancelled);
    std::optional<gp_Ax1> resolvedAxis;
    for (const QueryEntity& entity : resolution.entities) {
      if (entity.kind != 'f')
        throw OperationFailure(operationId, "REFERENCE_WRONG_KIND",
                               "Revolve axis-face reference resolved a non-face.",
                               {{"code", "E_REVOLVE_AXIS_NOT_FACE"}});
      const BRepAdaptor_Surface surface(TopoDS::Face(entity.shape), true);
      std::optional<gp_Ax1> candidate;
      if (surface.GetType() == GeomAbs_Cylinder)
        candidate = surface.Cylinder().Axis();
      else if (surface.GetType() == GeomAbs_Cone)
        candidate = surface.Cone().Axis();
      else if (surface.GetType() == GeomAbs_Torus)
        candidate = surface.Torus().Axis();
      else
        throw OperationFailure(operationId, "REFERENCE_WRONG_KIND",
                               "The picked face has no exact rotational axis; pick a cylinder, "
                               "cone, or torus face.",
                               {{"code", "E_REVOLVE_FACE_NOT_ROTATIONAL"}});
      const gp_Ax1 canonical = CanonicalAxis(*candidate);
      if (resolvedAxis.has_value() && !SameInfiniteAxis(*resolvedAxis, canonical))
        ThrowRevolveAxisAmbiguous(operationId, "axisFace");
      resolvedAxis = canonical;
    }
    if (!resolvedAxis.has_value())
      throw ReferenceMissing(operationId, "Revolve axisFace reference resolved no entities.");
    return *resolvedAxis;
  }
  throw OperationFailure(operationId, "INVALID_REQUEST", "Unsupported Revolve axis source.",
                         {{"code", "E_REVOLVE_AXIS_SOURCE_INVALID"}});
}

EvaluatedBody EvaluateRevolveV2(const nlohmann::json& operation,
                                const std::map<std::string, EvaluatedProfile>& profiles,
                                const std::map<std::string, EvaluatedOpenPath>& openPaths,
                                BodyPool& pool, ElementNameBook* elementNames,
                                NamingRegistry* registry, const std::atomic_bool& cancelled) {
  const nlohmann::json& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const bool hasThin = parameters.contains("thin") && !parameters.at("thin").is_null();
  const std::vector<EvaluatedBody> visible = pool.PeekVisibleBodies();

  TopoDS_Shape baseShape;
  gp_Ax2 profileFrame;
  if (parameters.contains("faceProfile") && !parameters.at("faceProfile").is_null()) {
    if (hasThin)
      throw OperationFailure(operationId, "INVALID_REQUEST",
                             "Thin Revolve follows an open sketch path, not a solid face.",
                             {{"code", "E_REVOLVE_THIN_FACE_UNSUPPORTED"}});
    if (registry == nullptr)
      throw std::invalid_argument("face-profile Revolve requires the naming registry");
    const RefResolution resolution =
        ResolveRefSlotStrict(operationId, "revolve", "faceProfile", parameters.at("faceProfile"),
                             visible, *registry, cancelled);
    const QueryEntity& entity = SingleResolvedEntity("revolve", "faceProfile", 'f', resolution);
    const TopoDS_Face face = TopoDS::Face(entity.shape);
    const BRepAdaptor_Surface surface(face, true);
    if (surface.GetType() != GeomAbs_Plane)
      throw OperationFailure(operationId, "REFERENCE_WRONG_KIND",
                             "Revolve profile must be a flat face.",
                             {{"code", "E_REVOLVE_FACE_NOT_PLANAR"}});
    baseShape = face;
    profileFrame = PlanarFaceSketchAxes(surface.Plane());
  } else {
    const std::string profileId = parameters.at("profileOperationId").get<std::string>();
    const auto found = profiles.find(profileId);
    if (found != profiles.end()) {
      if (hasThin)
        throw OperationFailure(operationId, "INVALID_REQUEST",
                               "Thin Revolve needs an open sketch path; remove Thin or open the "
                               "profile.",
                               {{"code", "E_REVOLVE_THIN_PROFILE_CLOSED"}});
      profileFrame = found->second.frame;
      if (parameters.contains("sketchRegionIds") && !parameters.at("sketchRegionIds").is_null()) {
        TopoDS_Compound compound;
        BRep_Builder builder;
        builder.MakeCompound(compound);
        for (const nlohmann::json& requestedJson : parameters.at("sketchRegionIds")) {
          const std::string requested = requestedJson.get<std::string>();
          const auto match =
              std::find(found->second.regionIds.begin(), found->second.regionIds.end(), requested);
          if (match == found->second.regionIds.end())
            throw ReferenceMissing(operationId,
                                   "Revolve sketch region " + requested + " no longer exists.");
          builder.Add(compound, found->second.faces.at(static_cast<std::size_t>(
                                    match - found->second.regionIds.begin())));
        }
        baseShape = compound;
      } else {
        baseShape = found->second.shape;
      }
    } else {
      const auto open = openPaths.find(profileId);
      if (open == openPaths.end())
        throw ReferenceMissing(operationId,
                               "Revolve profile operation " + profileId + " is missing.");
      if (!hasThin)
        throw OperationFailure(operationId, "INVALID_REQUEST",
                               "This sketch is open; enable Thin Revolve or close the profile.",
                               {{"code", "E_REVOLVE_OPEN_PROFILE_REQUIRES_THIN"}});
      const nlohmann::json& thin = parameters.at("thin");
      baseShape = MakeOpenPathBand(operationId, open->second, thin.at("sideOneMm").get<double>(),
                                   thin.at("sideTwoMm").get<double>());
      profileFrame = open->second.frame;
    }
  }

  GProp_GProps baseSurfaceProperties;
  BRepGProp::SurfaceProperties(baseShape, baseSurfaceProperties);
  if (!(baseSurfaceProperties.Mass() > 1e-12))
    throw OperationFailure(operationId, "INVALID_REQUEST",
                           "Revolve profile has no measurable planar area.",
                           {{"code", "E_REVOLVE_PROFILE_DEGENERATE"}});
  // A partial Revolve's start/end cap planes can be the same infinite plane
  // (most obviously at 180 degrees). The profile-frame origin often lies on
  // the axis and therefore rotates to itself, which gave naming two identical
  // boundary anchors and forced a false ambiguity. The authoritative profile
  // centroid rotates to the actual cap sector and remains distinguishable.
  const gp_Pnt profileBoundaryAnchor = baseSurfaceProperties.CentreOfMass();

  gp_Ax1 axis = ResolveRevolveAxis(operation, parameters, visible, registry, cancelled);
  const gp_Pln profilePlane(profileFrame.Location(), profileFrame.Direction());
  gp_Vec axisDirection(axis.Direction());
  gp_Pnt axisOrigin = axis.Location();
  if (parameters.value("projectAxisToProfilePlane", false)) {
    const gp_Vec n(profileFrame.Direction());
    const gp_Vec projectedDirection = axisDirection - n * axisDirection.Dot(n);
    if (projectedDirection.Magnitude() < 1e-9)
      throw OperationFailure(operationId, "INVALID_REQUEST",
                             "This axis projects to a point on the profile plane.",
                             {{"code", "E_REVOLVE_AXIS_PROJECTION_DEGENERATE"}});
    const double signedDistance =
        gp_Vec(profileFrame.Location(), axisOrigin).Dot(gp_Vec(profileFrame.Direction()));
    axisOrigin = axisOrigin.Translated(-signedDistance * gp_Vec(profileFrame.Direction()));
    axis = CanonicalAxis(gp_Ax1(axisOrigin, gp_Dir(projectedDirection)));
  } else {
    if (std::abs(axisDirection.Dot(gp_Vec(profileFrame.Direction()))) > 1e-8 ||
        profilePlane.Distance(axisOrigin) > 1e-7)
      throw OperationFailure(operationId, "INVALID_REQUEST",
                             "Revolve axis is not in the profile plane; choose Project axis or "
                             "pick a coplanar axis.",
                             {{"code", "E_REVOLVE_AXIS_NOT_COPLANAR"}});
  }

  const nlohmann::json& extent = parameters.at("extent");
  const std::string mode = extent.at("mode").get<std::string>();
  double forward = 360.0;
  double backward = 0.0;
  if (mode == "oneSide") {
    forward = extent.at("angleDegrees").get<double>();
  } else if (mode == "symmetric") {
    forward = extent.at("angleDegrees").get<double>() / 2.0;
    backward = forward;
  } else if (mode == "twoSided") {
    forward = extent.at("forwardAngleDegrees").get<double>();
    backward = extent.at("backwardAngleDegrees").get<double>();
  } else if (mode != "full") {
    throw OperationFailure(operationId, "INVALID_REQUEST", "Unsupported Revolve extent.",
                           {{"code", "E_REVOLVE_EXTENT_INVALID"}});
  }
  const double total = forward + backward;
  if (!(total > 0.0 && total <= 360.0 + 1e-9))
    throw OperationFailure(operationId, "INVALID_REQUEST", "Revolve angle is out of range.",
                           {{"code", "E_REVOLVE_ANGLE_INVALID"}});
  const double directionSign = parameters.value("direction", "forward") == "reverse" ? -1.0 : 1.0;
  gp_Ax1 sweepAxis = axis;
  if (directionSign < 0.0)
    sweepAxis.Reverse();
  constexpr double kDegreesToRadians = 0.017453292519943295;
  TopoDS_Shape sweepBase = baseShape;
  if (backward > 1e-12) {
    gp_Trsf startRotation;
    startRotation.SetRotation(sweepAxis, -backward * kDegreesToRadians);
    BRepBuilderAPI_Transform transformed(baseShape, startRotation, /*Copy=*/true);
    if (!transformed.IsDone())
      throw OperationFailure(operationId, "GEOMETRY_FAILED",
                             "Revolve could not position the two-sided start.",
                             {{"code", "E_REVOLVE_START_ROTATION_FAILED"}});
    sweepBase = transformed.Shape();
  }
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  TopoDS_Shape toolShape;
  try {
    if (mode == "full") {
      BRepPrimAPI_MakeRevol maker(sweepBase, sweepAxis, /*Copy=*/true);
      maker.Build(progress->Start());
      if (!maker.IsDone())
        throw Standard_Failure("full revolve construction failed");
      toolShape = maker.Shape();
    } else {
      BRepPrimAPI_MakeRevol maker(sweepBase, sweepAxis, total * kDegreesToRadians,
                                  /*Copy=*/true);
      maker.Build(progress->Start());
      if (!maker.IsDone())
        throw Standard_Failure("partial revolve construction failed");
      toolShape = maker.Shape();
    }
    CheckCancellation(cancelled);
  } catch (const OperationFailure&) {
    throw;
  } catch (const Standard_Failure& error) {
    throw OperationFailure(operationId, "GEOMETRY_FAILED",
                           std::string("Revolve could not build this profile: ") + error.what(),
                           {{"code", "E_REVOLVE_GEOMETRY_FAILED"}});
  }
  if (toolShape.IsNull() || Count(toolShape, TopAbs_SOLID) == 0 ||
      !BRepCheck_Analyzer(toolShape, false).IsValid())
    throw OperationFailure(operationId, "SELF_INTERSECTION",
                           "Revolve self-intersects or crosses its axis. Move the axis or trim "
                           "the profile.",
                           {{"code", "E_REVOLVE_SELF_INTERSECTION"}});

  const nlohmann::json& boolean = parameters.at("boolean");
  const std::string booleanMode = boolean.at("mode").get<std::string>();
  if (booleanMode != "newBody") {
    const std::string targetId = boolean.at("targetOperationId").get<std::string>();
    const TopoDS_Shape target =
        pool.Consume(operationId, "revolve " + booleanMode, "target", targetId);
    if (booleanMode == "cut" && !ToolRemovesMaterial(target, toolShape, cancelled))
      throw OperationFailure(operationId, "NO_CONTACT",
                             "Revolve Cut does not touch the selected target.",
                             {{"code", "E_REVOLVE_CUT_NO_CONTACT"}});
    std::unique_ptr<BRepAlgoAPI_BooleanOperation> algorithm;
    if (booleanMode == "join")
      algorithm = std::make_unique<BRepAlgoAPI_Fuse>();
    else if (booleanMode == "cut")
      algorithm = std::make_unique<BRepAlgoAPI_Cut>();
    else if (booleanMode == "intersect")
      algorithm = std::make_unique<BRepAlgoAPI_Common>();
    else
      throw OperationFailure(operationId, "INVALID_REQUEST", "Unsupported Revolve operation.",
                             {{"code", "E_REVOLVE_BOOLEAN_INVALID"}});
    NCollection_List<TopoDS_Shape> objects;
    objects.Append(target);
    NCollection_List<TopoDS_Shape> tools;
    tools.Append(toolShape);
    algorithm->SetArguments(objects);
    algorithm->SetTools(tools);
    algorithm->SetRunParallel(false);
    algorithm->SetToFillHistory(elementNames != nullptr);
    algorithm->Build(progress->Start());
    CheckCancellation(cancelled);
    if (algorithm->HasErrors() || algorithm->Shape().IsNull() ||
        Count(algorithm->Shape(), TopAbs_SOLID) != 1)
      throw OperationFailure(operationId, "GEOMETRY_FAILED",
                             "Revolve operation must produce one connected solid.",
                             {{"code", "E_REVOLVE_BOOLEAN_FAILED"}});
    TopExp_Explorer solids(algorithm->Shape(), TopAbs_SOLID);
    EvaluatedBody body =
        FinishSolidBody(operation, TopoDS::Solid(solids.Current()), "revolve boolean result");
    if (elementNames != nullptr) {
      const occ::handle<BRepTools_History> history = algorithm->History();
      if (history.IsNull())
        throw OperationFailure(operationId, "GEOMETRY_FAILED",
                               "Revolve operation produced no topology history.",
                               {{"code", "E_REVOLVE_HISTORY_MISSING"}});
      elementNames->AddDerivedPrimitive(operationId, toolShape);
      elementNames->ApplyOperation(operationId, {target, toolShape}, body.shape, *history,
                                   cancelled);
      if (registry != nullptr) {
        registry->HarvestSyntheticTool(operationId, toolShape, cancelled);
        registry->HarvestOperation(operationId, NamingRegistry::OperationClass::Boolean,
                                   {{target, false, false}, {toolShape, true, true}}, body.shape,
                                   *history, cancelled);
      }
    }
    return body;
  }

  EvaluatedBody body = FinishBodyShape(operation, toolShape, "revolution");
  if (elementNames != nullptr) {
    elementNames->AddPrimitive(operationId, body.shape);
    if (registry != nullptr) {
      if (mode == "full") {
        registry->HarvestBirth(operationId, body.shape,
                               {NamingRegistry::BirthClass::Revolve, std::nullopt, std::nullopt},
                               cancelled);
      } else {
        gp_Trsf startRotation;
        startRotation.SetRotation(sweepAxis, -backward * kDegreesToRadians);
        gp_Trsf endRotation;
        endRotation.SetRotation(sweepAxis, forward * kDegreesToRadians);
        registry->HarvestBirth(operationId, body.shape,
                               {NamingRegistry::BirthClass::Revolve,
                                NamingRegistry::BirthBoundary{
                                    profileBoundaryAnchor.Transformed(startRotation),
                                    profileFrame.Direction().Transformed(startRotation), true},
                                NamingRegistry::BirthBoundary{
                                    profileBoundaryAnchor.Transformed(endRotation),
                                    profileFrame.Direction().Transformed(endRotation), true}},
                               cancelled);
      }
    }
  }
  return body;
}

EvaluatedBody EvaluateLoft(const nlohmann::json& operation,
                           const std::map<std::string, EvaluatedProfile>& profiles,
                           const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const auto& profileIds = parameters.at("profileOperationIds");
  const bool ruled = parameters.at("ruled").get<bool>();
  if (!profileIds.is_array() || profileIds.size() < 2)
    throw std::invalid_argument("loft requires at least two section profiles");

  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  // isSolid caps the first and last sections so the result is a closed solid,
  // not an open shell. Sections are threaded in document-reference order.
  BRepOffsetAPI_ThruSections maker(/*isSolid=*/true, /*ruled=*/ruled);
  const EvaluatedProfile* firstProfile = nullptr;
  for (const auto& idValue : profileIds) {
    CheckCancellation(cancelled);
    const std::string profileOperationId = idValue.get<std::string>();
    const auto profile = profiles.find(profileOperationId);
    if (profile == profiles.end()) {
      // Operation-level reference failure (ADR-003), identical to extrude:
      // missing, non-profile, or forward reference are one contract violation.
      throw ReferenceMissing(operation.at("id").get<std::string>(),
                             "loft references operation " + profileOperationId +
                                 ", which is not an evaluated profile operation earlier in the "
                                 "document");
    }
    if (firstProfile == nullptr) {
      firstProfile = &profile->second;
    } else {
      const gp_Dir firstNormal = firstProfile->frame.Direction();
      const gp_Dir sectionNormal = profile->second.frame.Direction();
      const double parallel = std::abs(firstNormal.Dot(sectionNormal));
      const double signedSeparation =
          gp_Vec(firstProfile->frame.Location(), profile->second.frame.Location())
              .Dot(gp_Vec(firstNormal));
      if (parallel > 1.0 - 1.0e-9 && std::abs(signedSeparation) < 1.0e-3) {
        throw OperationFailure(
            operation.at("id").get<std::string>(), "GEOMETRY_FAILED",
            "loft sections lie on the same plane; the result would have zero volume");
      }
    }
    const TopoDS_Wire outer = BRepTools::OuterWire(profile->second.face);
    if (outer.IsNull())
      throw Standard_Failure("loft section profile has no boundary wire");
    // Copy the section wire so this loft owns its geometry even when several
    // features consume the same profile within one evaluation — the same
    // ownership discipline extrude and revolve apply with Copy=true.
    const TopoDS_Wire wire = TopoDS::Wire(BRepBuilderAPI_Copy(outer).Shape());
    maker.AddWire(wire);
  }

  maker.Build(progress->Start());
  CheckCancellation(cancelled);
  if (!maker.IsDone())
    throw Standard_Failure("loft through-sections construction failed");
  const TopoDS_Shape result = maker.Shape();
  if (result.IsNull() || result.ShapeType() != TopAbs_SOLID)
    throw Standard_Failure("loft did not produce a single solid body");
  // Incompatible or self-intersecting sections can yield an invalid solid;
  // refuse it as a geometry failure rather than emit invalid geometry.
  if (!BRepCheck_Analyzer(result, false).IsValid())
    throw Standard_Failure(
        "loft produced an invalid solid; the section profiles must be compatible and disjoint");
  return FinishSolidBody(operation, TopoDS::Solid(result), "loft");
}

// ── Loft v2 — professional multi-section authoring (issue #141) ─────────────
//
// v1 threads profile operations in order with a single `ruled` flag. v2 adds
// ordered sections that may be profiles, model faces, closed edge loops or
// point tips; deterministic seam mapping; continuity; closed form; a surface
// result; and rail/centerline control.
//
// Seam mapping is explicit because OCCT pairs section wires by their topology
// enumeration: a rebuild that renumbers a section would otherwise twist the
// solid silently. `seamDirection` and `explicit` both resolve to a target
// POINT per section, and each wire is rotated to start at the vertex nearest
// that point, so the correspondence survives renumbering.
//
// Rails and the centerline are honoured by inserting fitted intermediate
// sections between the authored ones: at each sample the bracketing section is
// copied and moved by the similarity (translation, rotation about the section
// normal, uniform scale) that least-squares maps its anchor points onto the
// guide points at that parameter. One rail or a centerline therefore yields a
// translation; several rails additionally rotate and scale the section. This
// is an approximation of a Gordon surface, not a Gordon surface — it is
// deterministic and measurable, and the packet records the limitation.
namespace {

constexpr int kLoftRailSamplesPerSpan = 8;
constexpr double kLoftSeamTolerance = 1.0e-9;
/** How near a rail/centerline must pass to each section to control it. */
constexpr double kLoftGuideAttachToleranceMm = 1.0e-3;

struct LoftSection {
  TopoDS_Wire wire;
  TopoDS_Vertex vertex;
  bool isPoint = false;
  gp_Pnt origin;
  gp_Dir normal{0.0, 0.0, 1.0};
};

/** Centroid + Newell normal of a closed wire, independent of edge order. */
gp_Ax2 LoftWireFrame(const TopoDS_Wire& wire) {
  std::vector<gp_Pnt> points;
  for (BRepTools_WireExplorer explorer(wire); explorer.More(); explorer.Next())
    points.push_back(BRep_Tool::Pnt(explorer.CurrentVertex()));
  if (points.size() < 3)
    throw std::invalid_argument("loft section wire has fewer than three vertices");
  gp_XYZ centroid(0.0, 0.0, 0.0);
  for (const gp_Pnt& point : points)
    centroid += point.XYZ();
  centroid /= static_cast<double>(points.size());
  gp_XYZ normal(0.0, 0.0, 0.0);
  for (std::size_t index = 0; index < points.size(); ++index) {
    const gp_XYZ& current = points[index].XYZ();
    const gp_XYZ& next = points[(index + 1) % points.size()].XYZ();
    normal += gp_XYZ((current.Y() - next.Y()) * (current.Z() + next.Z()),
                     (current.Z() - next.Z()) * (current.X() + next.X()),
                     (current.X() - next.X()) * (current.Y() + next.Y()));
  }
  if (normal.Modulus() <= 1.0e-12)
    throw std::invalid_argument("loft section wire is degenerate and has no plane");
  return gp_Ax2(gp_Pnt(centroid), gp_Dir(normal));
}

/** Rebuilds `wire` so it starts at the vertex nearest `target`. */
TopoDS_Wire RotateWireToSeam(const TopoDS_Wire& wire, const gp_Pnt& target) {
  std::vector<TopoDS_Edge> edges;
  std::vector<gp_Pnt> starts;
  for (BRepTools_WireExplorer explorer(wire); explorer.More(); explorer.Next()) {
    edges.push_back(explorer.Current());
    starts.push_back(BRep_Tool::Pnt(explorer.CurrentVertex()));
  }
  if (edges.size() < 2)
    return wire;
  std::size_t best = 0;
  double bestDistance = starts[0].Distance(target);
  for (std::size_t index = 1; index < starts.size(); ++index) {
    const double distance = starts[index].Distance(target);
    if (distance + kLoftSeamTolerance < bestDistance) {
      bestDistance = distance;
      best = index;
    }
  }
  if (best == 0)
    return wire;
  BRepBuilderAPI_MakeWire rebuilt;
  for (std::size_t offset = 0; offset < edges.size(); ++offset)
    rebuilt.Add(edges[(best + offset) % edges.size()]);
  if (!rebuilt.IsDone())
    throw Standard_Failure("loft could not re-seam a section wire");
  return rebuilt.Wire();
}

/** The wire vertex closest to `target` — the point a guide attaches to. */
gp_Pnt NearestWireVertex(const TopoDS_Wire& wire, const gp_Pnt& target) {
  gp_Pnt best;
  double bestDistance = -1.0;
  for (BRepTools_WireExplorer explorer(wire); explorer.More(); explorer.Next()) {
    const gp_Pnt point = BRep_Tool::Pnt(explorer.CurrentVertex());
    const double distance = point.Distance(target);
    if (bestDistance < 0.0 || distance < bestDistance) {
      bestDistance = distance;
      best = point;
    }
  }
  if (bestDistance < 0.0)
    throw std::invalid_argument("loft guide has no section vertex to attach to");
  return best;
}

GeomAbs_Shape LoftContinuity(const std::string& continuity) {
  if (continuity == "g0")
    return GeomAbs_C0;
  if (continuity == "g1")
    return GeomAbs_G1;
  if (continuity == "g2")
    return GeomAbs_G2;
  throw std::invalid_argument("unsupported loft continuity: " + continuity);
}

/** Evenly-spaced points along a guide wire, parameter 0..1 by arc length. */
std::vector<gp_Pnt> SampleGuide(const TopoDS_Wire& guide, int samples) {
  BRepAdaptor_CompCurve curve(guide);
  const double first = curve.FirstParameter();
  const double last = curve.LastParameter();
  std::vector<gp_Pnt> points;
  points.reserve(static_cast<std::size_t>(samples) + 1);
  for (int index = 0; index <= samples; ++index) {
    const double fraction = static_cast<double>(index) / static_cast<double>(samples);
    points.push_back(curve.Value(first + (last - first) * fraction));
  }
  return points;
}

/**
 * Least-squares similarity taking `from` onto `to` within the plane whose
 * normal is `normal`. One pair is a translation; more pairs add a rotation
 * about the normal and a uniform scale (2-D Procrustes in that plane).
 */
gp_Trsf LoftGuideFit(const std::vector<gp_Pnt>& from, const std::vector<gp_Pnt>& to,
                     const gp_Dir& normal) {
  if (from.size() != to.size() || from.empty())
    throw std::invalid_argument("loft guide fit needs matching anchor and target points");
  gp_XYZ fromCentre(0.0, 0.0, 0.0);
  gp_XYZ toCentre(0.0, 0.0, 0.0);
  for (std::size_t index = 0; index < from.size(); ++index) {
    fromCentre += from[index].XYZ();
    toCentre += to[index].XYZ();
  }
  fromCentre /= static_cast<double>(from.size());
  toCentre /= static_cast<double>(to.size());
  gp_Trsf translation;
  translation.SetTranslation(gp_Vec(gp_Pnt(fromCentre), gp_Pnt(toCentre)));
  if (from.size() < 2)
    return translation;

  const gp_Ax2 plane(gp_Pnt(fromCentre), normal);
  const gp_Dir xDir = plane.XDirection();
  const gp_Dir yDir = plane.YDirection();
  double sinSum = 0.0;
  double cosSum = 0.0;
  double fromNorm = 0.0;
  double dotSum = 0.0;
  for (std::size_t index = 0; index < from.size(); ++index) {
    const gp_Vec a(gp_Pnt(fromCentre), from[index]);
    const gp_Vec b(gp_Pnt(toCentre), to[index]);
    const double ax = a.Dot(gp_Vec(xDir));
    const double ay = a.Dot(gp_Vec(yDir));
    const double bx = b.Dot(gp_Vec(xDir));
    const double by = b.Dot(gp_Vec(yDir));
    sinSum += ax * by - ay * bx;
    cosSum += ax * bx + ay * by;
    fromNorm += ax * ax + ay * ay;
    dotSum += std::sqrt(bx * bx + by * by) * std::sqrt(ax * ax + ay * ay);
  }
  gp_Trsf result = translation;
  if (std::abs(sinSum) > 1.0e-12 || std::abs(cosSum) > 1.0e-12) {
    gp_Trsf rotation;
    rotation.SetRotation(gp_Ax1(gp_Pnt(toCentre), normal), std::atan2(sinSum, cosSum));
    result = rotation * result;
  }
  if (fromNorm > 1.0e-12 && dotSum > 1.0e-12) {
    const double scale = dotSum / fromNorm;
    if (scale > 1.0e-6 && std::abs(scale - 1.0) > 1.0e-9) {
      gp_Trsf scaling;
      scaling.SetScale(gp_Pnt(toCentre), scale);
      result = scaling * result;
    }
  }
  return result;
}

} // namespace
EvaluatedBody EvaluateLoftV2(const nlohmann::json& operation,
                             const std::map<std::string, EvaluatedProfile>& profiles,
                             const BodyPool& pool, NamingRegistry* registry,
                             const std::atomic_bool& cancelled) {
  const std::string operationId = operation.at("id").get<std::string>();
  const auto& parameters = operation.at("parameters");
  const auto& sectionsJson = parameters.at("sections");
  if (!sectionsJson.is_array() || sectionsJson.size() < 2)
    throw std::invalid_argument("loft requires at least two sections");
  if (parameters.value("closed", false) && sectionsJson.size() < 3)
    throw std::invalid_argument(
        "a closed loft needs at least three sections; two would fold back on themselves");
  const bool ruled = parameters.value("ruled", false);
  const bool closed = parameters.value("closed", false);
  const bool solid = parameters.value("result", std::string("solid")) == "solid";
  const GeomAbs_Shape continuity =
      LoftContinuity(parameters.value("continuity", std::string("g2")));
  const nlohmann::json mapping = parameters.value("mapping", nlohmann::json{{"mode", "default"}});
  const std::string mappingMode = mapping.value("mode", std::string("default"));
  const std::vector<EvaluatedBody> visible = pool.PeekVisibleBodies();
  const nlohmann::json rails = parameters.value("rails", nlohmann::json::array());
  const bool hasCenterline =
      parameters.contains("centerline") && !parameters.at("centerline").is_null();
  const bool needsRegistry =
      !rails.empty() || hasCenterline ||
      std::any_of(sectionsJson.begin(), sectionsJson.end(), [](const nlohmann::json& section) {
        return section.value("kind", std::string("profile")) != "profile";
      });
  if (needsRegistry && registry == nullptr)
    throw std::invalid_argument(
        "loft sections, rails or centerline reference model topology; evaluate with selector "
        "resolution enabled");

  std::vector<LoftSection> sections;
  sections.reserve(sectionsJson.size());
  for (std::size_t index = 0; index < sectionsJson.size(); ++index) {
    CheckCancellation(cancelled);
    const nlohmann::json& sectionJson = sectionsJson.at(index);
    const std::string slot = "sections[" + std::to_string(index) + "]";
    const std::string kind = sectionJson.value("kind", std::string("profile"));
    LoftSection section;
    if (kind == "profile") {
      const std::string profileOperationId = sectionJson.at("operationId").get<std::string>();
      const auto profile = profiles.find(profileOperationId);
      if (profile == profiles.end())
        throw ReferenceMissing(operationId, "loft " + slot + ": references operation " +
                                                profileOperationId +
                                                ", which is not an evaluated profile operation "
                                                "earlier in the document");
      const TopoDS_Wire outer = BRepTools::OuterWire(profile->second.face);
      if (outer.IsNull())
        throw Standard_Failure("loft section profile has no boundary wire");
      section.wire = TopoDS::Wire(BRepBuilderAPI_Copy(outer).Shape());
      section.origin = profile->second.frame.Location();
      section.normal = profile->second.frame.Direction();
    } else if (kind == "point") {
      const RefResolution resolution = ResolveRefSlotStrict(
          operationId, "loft", slot.c_str(), sectionJson.at("ref"), visible, *registry, cancelled);
      const QueryEntity& entity = SingleResolvedEntity("loft", slot.c_str(), 'v', resolution);
      section.vertex = TopoDS::Vertex(entity.shape);
      section.isPoint = true;
      section.origin = BRep_Tool::Pnt(section.vertex);
    } else if (kind == "face" || kind == "edgeLoop") {
      const char expected = kind == "face" ? 'f' : 'e';
      const RefResolution resolution = ResolveRefSlotStrict(
          operationId, "loft", slot.c_str(), sectionJson.at("ref"), visible, *registry, cancelled);
      const QueryEntity& entity = SingleResolvedEntity("loft", slot.c_str(), expected, resolution);
      TopoDS_Wire wire;
      if (kind == "face") {
        const TopoDS_Wire outer = BRepTools::OuterWire(TopoDS::Face(entity.shape));
        if (outer.IsNull())
          throw Standard_Failure("loft section face has no outer wire");
        wire = TopoDS::Wire(BRepBuilderAPI_Copy(outer).Shape());
      } else {
        BRepBuilderAPI_MakeWire builder(TopoDS::Edge(entity.shape));
        if (!builder.IsDone())
          throw Standard_Failure("loft edge-loop section is not a usable loop");
        wire = builder.Wire();
        if (!wire.Closed())
          throw OperationFailure(operationId, "INVALID_REQUEST",
                                 "loft " + slot + ": an edge-loop section must be a closed loop",
                                 {{"code", "E_LOFT_SECTION_NOT_CLOSED"}});
      }
      section.wire = wire;
      const gp_Ax2 frame = LoftWireFrame(wire);
      section.origin = frame.Location();
      section.normal = frame.Direction();
    } else {
      throw std::invalid_argument("unsupported loft section kind: " + kind);
    }
    if (!section.isPoint && sectionJson.value("flip", false))
      section.wire = TopoDS::Wire(section.wire.Reversed());
    sections.push_back(section);
  }

  // Deterministic seam correspondence, so a renumbered section cannot twist
  // the solid on rebuild.
  if (mappingMode != "default") {
    for (std::size_t index = 0; index < sections.size(); ++index) {
      LoftSection& section = sections[index];
      if (section.isPoint)
        continue;
      gp_Pnt target;
      if (mappingMode == "seamDirection") {
        const auto& direction = mapping.at("direction");
        const gp_Vec offset(direction.at(0).get<double>(), direction.at(1).get<double>(),
                            direction.at(2).get<double>());
        if (offset.Magnitude() <= 1.0e-12)
          throw std::invalid_argument("loft seam direction must not be the zero vector");
        target = section.origin.Translated(gp_Vec(gp_Dir(offset)) * 1.0e6);
      } else {
        const std::string slot = "sections[" + std::to_string(index) + "].seamVertexRef";
        const RefResolution resolution = ResolveRefSlotStrict(
            operationId, "loft", slot.c_str(), sectionsJson.at(index).at("seamVertexRef"), visible,
            *registry, cancelled);
        const QueryEntity& entity = SingleResolvedEntity("loft", slot.c_str(), 'v', resolution);
        target = BRep_Tool::Pnt(TopoDS::Vertex(entity.shape));
      }
      section.wire = RotateWireToSeam(section.wire, target);
    }
  }

  std::vector<TopoDS_Wire> guides;
  const auto addGuide = [&](const nlohmann::json& ref, const std::string& slot) {
    const RefResolution resolution =
        ResolveRefSlotStrict(operationId, "loft", slot.c_str(), ref, visible, *registry, cancelled);
    const QueryEntity& entity = SingleResolvedEntity("loft", slot.c_str(), 'e', resolution);
    BRepBuilderAPI_MakeWire builder(TopoDS::Edge(entity.shape));
    if (!builder.IsDone())
      throw Standard_Failure("loft guide edge is not a usable curve");
    guides.push_back(builder.Wire());
  };
  for (std::size_t index = 0; index < rails.size(); ++index)
    addGuide(rails.at(index), "rails[" + std::to_string(index) + "]");
  if (hasCenterline)
    addGuide(parameters.at("centerline"), "centerline");

  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepOffsetAPI_ThruSections maker(/*isSolid=*/solid,
                                   /*ruled=*/ruled || continuity == GeomAbs_C0);
  // G0 means position continuity only: the honest geometry for that is a
  // faceted, straight transition between sections, which is exactly what
  // `ruled` builds. G1/G2 keep the smooth interpolated surface. OCCT's own
  // continuity setter is consulted only while APPROXIMATING, so setting it
  // alone would have made g0/g1/g2 a stored flag that changed nothing —
  // and forcing the approximation on instead broke multi-section lofts.
  maker.SetContinuity(continuity);
  // An explicit seam mapping is a user decision. OCCT's compatibility pass
  // re-seams and re-parameterises the wires itself, which silently discarded
  // that decision — so authored mapping turns it off and uses the wires as
  // given (the sections must then share an edge count, which is what a
  // deterministic correspondence means in the first place).
  if (mappingMode != "default")
    maker.CheckCompatibility(false);

  const std::size_t spans = sections.size() - 1;
  std::vector<std::vector<gp_Pnt>> guideSamples;
  for (const TopoDS_Wire& guide : guides) {
    std::vector<gp_Pnt> samples =
        SampleGuide(guide, static_cast<int>(spans) * kLoftRailSamplesPerSpan);
    // A guide edge carries OCCT's arbitrary internal direction, not the
    // author's. Sampled backwards, the fitted intermediate sections march AWAY
    // from the loft and fold it into a self-intersecting solid that
    // BRepCheck_Analyzer still accepts. Orient every guide so its start is the
    // end nearest the FIRST section, exactly as the associative sweep path
    // normalizes its first edge.
    if (!samples.empty() && samples.front().Distance(sections.front().origin) >
                                samples.back().Distance(sections.front().origin))
      std::reverse(samples.begin(), samples.end());
    guideSamples.push_back(std::move(samples));
  }

  // A guide that does not pass through the authored sections cannot control
  // them: attaching a section to a distant rail introduces a step at the first
  // sample, and the smooth surface then overshoots the sections' own extent.
  // Fusion requires a rail to intersect every section; so do we, and we say
  // which rail and which section rather than emitting bent geometry.
  for (std::size_t guideIndex = 0; guideIndex < guideSamples.size(); ++guideIndex) {
    const std::string slot = guideIndex < rails.size() ? "rails[" + std::to_string(guideIndex) + "]"
                                                       : std::string("centerline");
    for (std::size_t sectionIndex = 0; sectionIndex < sections.size(); ++sectionIndex) {
      const LoftSection& section = sections[sectionIndex];
      if (section.isPoint)
        continue;
      double nearest = -1.0;
      for (const gp_Pnt& sample : guideSamples[guideIndex]) {
        const double distance = NearestWireVertex(section.wire, sample).Distance(sample);
        if (nearest < 0.0 || distance < nearest)
          nearest = distance;
      }
      if (nearest > kLoftGuideAttachToleranceMm)
        throw OperationFailure(operationId, "INVALID_REQUEST",
                               "loft " + slot +
                                   ": the guide must pass through every section, but it misses " +
                                   "sections[" + std::to_string(sectionIndex) + "] by " +
                                   std::to_string(nearest) + " mm",
                               {{"code", "E_LOFT_GUIDE_MISSES_SECTION"}});
    }
  }

  const auto addSection = [&](const LoftSection& section) {
    if (section.isPoint)
      maker.AddVertex(section.vertex);
    else
      maker.AddWire(section.wire);
  };

  for (std::size_t index = 0; index < sections.size(); ++index) {
    CheckCancellation(cancelled);
    addSection(sections[index]);
    if (guides.empty() || index + 1 >= sections.size() || sections[index].isPoint)
      continue;
    const LoftSection& base = sections[index];
    for (int step = 1; step < kLoftRailSamplesPerSpan; ++step) {
      const std::size_t anchorIndex = index * static_cast<std::size_t>(kLoftRailSamplesPerSpan);
      const std::size_t sampleIndex = anchorIndex + static_cast<std::size_t>(step);
      std::vector<gp_Pnt> anchors;
      std::vector<gp_Pnt> targets;
      for (const std::vector<gp_Pnt>& samples : guideSamples) {
        // Attach the section to the guide: the anchor is the section's own
        // nearest vertex, not the guide point. Using the guide point made the
        // fit a pure copy of the guide's delta, which pinned every
        // intermediate section at the first section's position and forced a
        // violent kink the smooth surface then overshot.
        anchors.push_back(NearestWireVertex(base.wire, samples[anchorIndex]));
        targets.push_back(samples[sampleIndex]);
      }
      const gp_Trsf fit = LoftGuideFit(anchors, targets, base.normal);
      BRepBuilderAPI_Transform moved(base.wire, fit, /*Copy=*/true);
      if (!moved.IsDone())
        throw Standard_Failure("loft could not place a guided intermediate section");
      maker.AddWire(TopoDS::Wire(moved.Shape()));
    }
  }
  if (closed)
    addSection(sections.front());

  maker.Build(progress->Start());
  CheckCancellation(cancelled);
  if (!maker.IsDone())
    throw OperationFailure(operationId, "GEOMETRY_FAILED",
                           "loft through-sections construction failed; the sections may be "
                           "incompatible, self-intersecting, or twisted by their seam mapping",
                           {{"code", "E_LOFT_BUILD_FAILED"}});
  const TopoDS_Shape result = maker.Shape();
  if (result.IsNull())
    throw Standard_Failure("loft produced no shape");
  if (!solid)
    return FinishSheetBody(operation, result, "loft");
  if (result.ShapeType() != TopAbs_SOLID)
    throw Standard_Failure("loft did not produce a single solid body");
  if (!BRepCheck_Analyzer(result, false).IsValid())
    throw Standard_Failure(
        "loft produced an invalid solid; the section profiles must be compatible and disjoint");
  return FinishSolidBody(operation, TopoDS::Solid(result), "loft");
}

std::vector<TopoDS_Edge> ResolveAssociativeSweepPath(const nlohmann::json& operation,
                                                     const BodyPool& pool, NamingRegistry* registry,
                                                     const std::atomic_bool& cancelled,
                                                     const gp_Pnt* profileAnchor = nullptr) {
  const std::string operationId = operation.at("id").get<std::string>();
  const auto& path = operation.at("parameters").at("path");
  if (registry == nullptr)
    throw std::invalid_argument("associative sweep path requires the naming registry; evaluate "
                                "with selector resolution enabled");
  if (!path.is_array() || path.empty())
    throw std::invalid_argument("associative sweep path must contain at least one edge reference");

  const std::vector<EvaluatedBody> visible = pool.PeekVisibleBodies();
  std::vector<TopoDS_Edge> edges;
  edges.reserve(path.size());
  for (std::size_t index = 0; index < path.size(); ++index) {
    const std::string slotName = "path[" + std::to_string(index) + "]";
    const RefResolution resolution = ResolveRefSlotStrict(
        operationId, "sweep", slotName.c_str(), path.at(index), visible, *registry, cancelled);
    const QueryEntity& entity = SingleResolvedEntity("sweep", slotName.c_str(), 'e', resolution);
    edges.push_back(TopoDS::Edge(entity.shape));
  }

  // The document stores the authored order. Normalize only each edge's local
  // orientation so the chain is connected; never sort by geometry, since
  // sorting would destroy the user's associative path intent.
  const auto orientedVertices = [](const TopoDS_Edge& edge, TopoDS_Vertex& first,
                                   TopoDS_Vertex& last) {
    TopExp::Vertices(edge, first, last, /*CumOri=*/true);
    if (first.IsNull() || last.IsNull())
      throw std::invalid_argument("associative sweep path contains an edge without endpoints");
  };
  constexpr double kSweepPathJoinTolerance = 1.0e-6;
  if (edges.size() > 1) {
    TopoDS_Vertex firstStart;
    TopoDS_Vertex firstEnd;
    TopoDS_Vertex secondStart;
    TopoDS_Vertex secondEnd;
    orientedVertices(edges[0], firstStart, firstEnd);
    orientedVertices(edges[1], secondStart, secondEnd);
    const gp_Pnt pFirstStart = BRep_Tool::Pnt(firstStart);
    const gp_Pnt pFirstEnd = BRep_Tool::Pnt(firstEnd);
    const gp_Pnt pSecondStart = BRep_Tool::Pnt(secondStart);
    const gp_Pnt pSecondEnd = BRep_Tool::Pnt(secondEnd);
    const bool endStart = pFirstEnd.Distance(pSecondStart) <= kSweepPathJoinTolerance;
    const bool endEnd = pFirstEnd.Distance(pSecondEnd) <= kSweepPathJoinTolerance;
    const bool startStart = pFirstStart.Distance(pSecondStart) <= kSweepPathJoinTolerance;
    const bool startEnd = pFirstStart.Distance(pSecondEnd) <= kSweepPathJoinTolerance;
    const int sharedEndpointCount = static_cast<int>(endStart) + static_cast<int>(endEnd) +
                                    static_cast<int>(startStart) + static_cast<int>(startEnd);
    if (sharedEndpointCount != 1)
      throw std::invalid_argument(
          "associative sweep adjacent path edges must share exactly one endpoint");
    if (startStart || startEnd)
      edges[0] = TopoDS::Edge(edges[0].Reversed());
    if (endEnd || startEnd)
      edges[1] = TopoDS::Edge(edges[1].Reversed());

    for (std::size_t index = 2; index < edges.size(); ++index) {
      TopoDS_Vertex previousFirst;
      TopoDS_Vertex previousLast;
      TopoDS_Vertex currentFirst;
      TopoDS_Vertex currentLast;
      orientedVertices(edges[index - 1], previousFirst, previousLast);
      orientedVertices(edges[index], currentFirst, currentLast);
      const gp_Pnt previousEnd = BRep_Tool::Pnt(previousLast);
      const gp_Pnt currentStart = BRep_Tool::Pnt(currentFirst);
      const gp_Pnt currentEnd = BRep_Tool::Pnt(currentLast);
      if (previousEnd.Distance(currentStart) <= kSweepPathJoinTolerance)
        continue;
      if (previousEnd.Distance(currentEnd) <= kSweepPathJoinTolerance) {
        edges[index] = TopoDS::Edge(edges[index].Reversed());
        continue;
      }
      throw std::invalid_argument(
          "associative sweep path references must form one connected ordered tangent chain");
    }
  }

  // A topological edge selected from a model body has no user-authored
  // direction: OCCT may return either orientation for the same durable
  // selector. For a single such edge, choose the endpoint nearest the authored
  // profile origin as the semantic start before applying the user's explicit
  // Reverse toggle.
  // Sketch-edge tokens do preserve their authored direction, so leave those
  // alone; pathDirection remains meaningful for that case.
  const auto hasAuthoredTokenDirection = [&path]() {
    if (path.size() != 1 || !path.front().contains("ast"))
      return false;
    const auto& scope = path.front().at("ast").value("scope", nlohmann::json::array());
    return scope.is_array() && scope.size() == 1 &&
           scope.front().value("source", std::string{}) == "token";
  };
  if (edges.size() == 1 && profileAnchor != nullptr && !hasAuthoredTokenDirection()) {
    TopoDS_Vertex first;
    TopoDS_Vertex last;
    orientedVertices(edges.front(), first, last);
    const double firstDistance = profileAnchor->Distance(BRep_Tool::Pnt(first));
    const double lastDistance = profileAnchor->Distance(BRep_Tool::Pnt(last));
    if (lastDistance + kSweepPathJoinTolerance < firstDistance)
      edges.front() = TopoDS::Edge(edges.front().Reversed());
  }

  if (operation.at("parameters").value("pathDirection", "forward") == "reverse") {
    std::reverse(edges.begin(), edges.end());
    for (TopoDS_Edge& edge : edges)
      edge = TopoDS::Edge(edge.Reversed());
  }
  return edges;
}

gp_Dir AssociativeSweepEdgeTangent(const TopoDS_Edge& edge, const bool atStart) {
  TopoDS_Vertex orientedStart;
  TopoDS_Vertex orientedEnd;
  TopExp::Vertices(edge, orientedStart, orientedEnd, /*CumOri=*/true);
  if (orientedStart.IsNull() || orientedEnd.IsNull())
    throw std::invalid_argument("associative sweep tangent needs path endpoints");

  const BRepAdaptor_Curve curve(edge);
  const double firstParameter = curve.FirstParameter();
  const double lastParameter = curve.LastParameter();
  const gp_Pnt curveFirst = curve.Value(firstParameter);
  const gp_Pnt curveLast = curve.Value(lastParameter);
  const gp_Pnt startPoint = BRep_Tool::Pnt(orientedStart);
  const bool increasing = startPoint.Distance(curveFirst) <= startPoint.Distance(curveLast);
  const double parameter = atStart ? (increasing ? firstParameter : lastParameter)
                                   : (increasing ? lastParameter : firstParameter);
  gp_Pnt point;
  gp_Vec tangent;
  curve.D1(parameter, point, tangent);
  if (!increasing)
    tangent.Reverse();
  if (tangent.Magnitude() <= 1.0e-9)
    throw std::invalid_argument("associative sweep path tangent is degenerate");
  return gp_Dir(tangent);
}

std::vector<TopoDS_Edge> LimitAssociativeSweepPath(const std::vector<TopoDS_Edge>& edges,
                                                   const nlohmann::json& extent) {
  if (extent.value("mode", "full") != "distance")
    return edges;
  const double requested = extent.at("distanceMm").get<double>();
  if (!(requested > 0.0))
    throw std::invalid_argument("associative sweep distance extent must be positive");

  std::vector<TopoDS_Edge> limited;
  limited.reserve(edges.size());
  double remaining = requested;
  for (const TopoDS_Edge& edge : edges) {
    TopoDS_Vertex first;
    TopoDS_Vertex last;
    TopExp::Vertices(edge, first, last, /*CumOri=*/true);
    if (first.IsNull() || last.IsNull())
      throw std::invalid_argument(
          "associative sweep extent path contains an edge without endpoints");
    const gp_Pnt start = BRep_Tool::Pnt(first);
    const gp_Pnt finish = BRep_Tool::Pnt(last);
    GProp_GProps lengthProperties;
    BRepGProp::LinearProperties(edge, lengthProperties);
    const double length = std::abs(lengthProperties.Mass());
    if (!(length > 1.0e-9))
      throw std::invalid_argument("associative sweep extent path contains a zero-length edge");
    if (remaining >= length - 1.0e-9) {
      limited.push_back(edge);
      remaining -= length;
      continue;
    }

    const BRepAdaptor_Curve curve(edge);
    if (curve.GetType() != GeomAbs_Line)
      throw std::invalid_argument(
          "associative sweep distance extent can trim only straight path edges");
    const gp_Vec direction(start, finish);
    const gp_Pnt trimmed = start.Translated((remaining / length) * direction);
    BRepBuilderAPI_MakeEdge segment(start, trimmed);
    if (!segment.IsDone())
      throw Standard_Failure("associative sweep distance extent could not trim its final edge");
    limited.push_back(segment.Edge());
    remaining = 0.0;
    break;
  }
  if (remaining > 1.0e-6)
    throw std::invalid_argument(
        "associative sweep distance extent exceeds the authored path length");
  return limited;
}

std::vector<TopoDS_Edge> LimitAssociativeSweepPathToReference(const nlohmann::json& operation,
                                                              const std::vector<TopoDS_Edge>& edges,
                                                              const BodyPool& pool,
                                                              NamingRegistry* registry,
                                                              const std::atomic_bool& cancelled) {
  if (registry == nullptr)
    throw std::invalid_argument(
        "associative sweep toReference extent requires the naming registry");
  const std::string operationId = operation.at("id").get<std::string>();
  const nlohmann::json& endRef = operation.at("parameters").at("extent").at("end");
  const std::vector<EvaluatedBody> visible = pool.PeekVisibleBodies();
  const RefResolution resolution = ResolveRefSlotStrict(operationId, "sweep", "extent.end", endRef,
                                                        visible, *registry, cancelled);
  const QueryEntity& entity = SingleResolvedEntity("sweep", "extent.end", 'f', resolution);
  const TopoDS_Face endFace = TopoDS::Face(entity.shape);
  const BRepAdaptor_Surface surface(endFace, true);
  if (surface.GetType() != GeomAbs_Plane)
    throw std::invalid_argument("associative sweep toReference extent requires a planar end face");
  const gp_Pln plane = surface.Plane();
  const gp_Vec normal(plane.Axis().Direction());
  const gp_Pnt origin = plane.Location();

  std::vector<TopoDS_Edge> limited;
  limited.reserve(edges.size());
  for (const TopoDS_Edge& edge : edges) {
    TopoDS_Vertex first;
    TopoDS_Vertex last;
    TopExp::Vertices(edge, first, last, /*CumOri=*/true);
    if (first.IsNull() || last.IsNull())
      throw std::invalid_argument(
          "associative sweep extent path contains an edge without endpoints");
    const gp_Pnt start = BRep_Tool::Pnt(first);
    const gp_Pnt finish = BRep_Tool::Pnt(last);
    const double startDistance = gp_Vec(origin, start).Dot(normal);
    const double endDistance = gp_Vec(origin, finish).Dot(normal);
    if (std::abs(endDistance) <= 1.0e-6) {
      limited.push_back(edge);
      return limited;
    }
    if (startDistance * endDistance > 0.0) {
      limited.push_back(edge);
      continue;
    }
    const BRepAdaptor_Curve curve(edge);
    if (curve.GetType() != GeomAbs_Line)
      throw std::invalid_argument(
          "associative sweep toReference extent can trim only straight path edges");
    const double denominator = startDistance - endDistance;
    if (std::abs(denominator) <= 1.0e-12)
      throw std::invalid_argument("associative sweep end reference is parallel to its path");
    const double fraction = startDistance / denominator;
    if (!(fraction > 0.0 && fraction < 1.0))
      throw std::invalid_argument("associative sweep path does not reach its end reference");
    const gp_Pnt trimmed = start.Translated(fraction * gp_Vec(start, finish));
    BRepBuilderAPI_MakeEdge segment(start, trimmed);
    if (!segment.IsDone())
      throw Standard_Failure("associative sweep could not trim to its end reference");
    limited.push_back(segment.Edge());
    return limited;
  }
  throw std::invalid_argument("associative sweep path does not intersect its end reference");
}

EvaluatedBody EvaluateSweepV2(const nlohmann::json& operation,
                              const std::map<std::string, EvaluatedProfile>& profiles,
                              const BodyPool& pool, NamingRegistry* registry,
                              const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  if (parameters.contains("guideRail") && parameters.contains("guideSurface"))
    throw std::invalid_argument(
        "associative sweep accepts either guideRail or guideSurface, not both");
  const auto& extent = parameters.at("extent");

  TopoDS_Face profileFace;
  gp_Ax2 profileFrame;
  if (parameters.contains("faceProfile") && !parameters.at("faceProfile").is_null()) {
    if (registry == nullptr)
      throw std::invalid_argument("associative sweep faceProfile requires the naming registry");
    const std::vector<EvaluatedBody> visible = pool.PeekVisibleBodies();
    const RefResolution resolution =
        ResolveRefSlotStrict(operationId, "sweep", "faceProfile", parameters.at("faceProfile"),
                             visible, *registry, cancelled);
    const QueryEntity& entity = SingleResolvedEntity("sweep", "faceProfile", 'f', resolution);
    profileFace = TopoDS::Face(entity.shape);
    const BRepAdaptor_Surface surface(profileFace, true);
    if (surface.GetType() != GeomAbs_Plane)
      throw OperationFailure(operationId, "REFERENCE_WRONG_KIND",
                             "associative sweep faceProfile must be planar",
                             {{"code", "E_SWEEP_FACE_NOT_PLANAR"}});
    profileFrame = PlanarFaceSketchAxes(surface.Plane());
  } else {
    const std::string profileOperationId = parameters.at("profileOperationId").get<std::string>();
    const auto profile = profiles.find(profileOperationId);
    if (profile == profiles.end())
      throw ReferenceMissing(
          operationId, "sweep references operation " + profileOperationId +
                           ", which is not an evaluated profile operation earlier in the document");
    if (parameters.contains("sketchRegionIds") && !parameters.at("sketchRegionIds").is_null()) {
      const auto& requested = parameters.at("sketchRegionIds");
      if (!requested.is_array() || requested.size() != 1)
        throw std::invalid_argument(
            "associative sweep currently requires exactly one selected sketch region");
      const std::string regionId = requested.front().get<std::string>();
      const auto region =
          std::find(profile->second.regionIds.begin(), profile->second.regionIds.end(), regionId);
      if (region == profile->second.regionIds.end())
        throw ReferenceMissing(operationId,
                               "sweep sketch region " + regionId + " no longer exists");
      profileFace = profile->second.faces.at(
          static_cast<std::size_t>(std::distance(profile->second.regionIds.begin(), region)));
    } else {
      profileFace = profile->second.face;
    }
    profileFrame = profile->second.frame;
  }

  const gp_Pln profilePlane = gp_Pln(gp_Ax3(profileFrame));
  const gp_Pnt profileAnchor = profileFrame.Location();
  std::vector<TopoDS_Edge> edges =
      ResolveAssociativeSweepPath(operation, pool, registry, cancelled, &profileAnchor);
  edges = LimitAssociativeSweepPath(edges, extent);
  if (extent.value("mode", "full") == "toReference")
    edges = LimitAssociativeSweepPathToReference(operation, edges, pool, registry, cancelled);
  const double taperAngle = parameters.value("taperAngleDeg", 0.0);
  const double twistAngle = parameters.value("twistAngleDegrees", 0.0);
  if ((std::abs(taperAngle) > 1.0e-9 || std::abs(twistAngle) > 1.0e-9) && edges.size() != 1 &&
      parameters.value("orientation", "natural") != "fixed")
    throw std::invalid_argument(
        "associative sweep taper/twist over multiple edges requires fixed orientation");
  if (edges.empty())
    throw std::invalid_argument("associative sweep path resolved no edges");
  BRepBuilderAPI_MakeWire spineMaker;
  for (const TopoDS_Edge& edge : edges)
    spineMaker.Add(edge);
  if (!spineMaker.IsDone())
    throw Standard_Failure("associative sweep spine wire construction failed");
  TopoDS_Wire spine = spineMaker.Wire();
  // MakeWire may canonicalize a single model edge back to its underlying
  // topological orientation. Reassert the resolved semantic direction on the
  // finished wire so PipeShell and durable boundary naming agree.
  TopoDS_Vertex expectedStart;
  TopoDS_Vertex expectedEnd;
  TopExp::Vertices(edges.front(), expectedStart, expectedEnd, /*CumOri=*/true);
  if (edges.size() == 1) {
    BRepTools_WireExplorer explorer(spine);
    if (explorer.More()) {
      TopoDS_Vertex wireStart;
      TopoDS_Vertex wireEnd;
      TopExp::Vertices(explorer.Current(), wireStart, wireEnd, /*CumOri=*/true);
      if (!expectedStart.IsNull() && !wireStart.IsNull() && !wireEnd.IsNull() &&
          BRep_Tool::Pnt(expectedStart).Distance(BRep_Tool::Pnt(wireEnd)) <
              BRep_Tool::Pnt(expectedStart).Distance(BRep_Tool::Pnt(wireStart)))
        spine.Reverse();
    }
  }

  TopoDS_Vertex firstVertex;
  TopoDS_Vertex firstEdgeEnd;
  TopExp::Vertices(edges.front(), firstVertex, firstEdgeEnd, /*CumOri=*/true);
  if (firstVertex.IsNull())
    throw std::invalid_argument("associative sweep path has no start vertex");
  if (profilePlane.Distance(BRep_Tool::Pnt(firstVertex)) > 1.0e-6)
    throw OperationFailure(operationId, "INVALID_REQUEST",
                           "associative sweep path start must lie on the profile plane",
                           {{"code", "E_SWEEP_PATH_START_OFF_PROFILE_PLANE"}});

  TopoDS_Shape sectionShape = BRepBuilderAPI_Copy(BRepTools::OuterWire(profileFace)).Shape();
  const bool naturalOrientation = parameters.value("orientation", "natural") == "natural";
  if (naturalOrientation) {
    // Normalize the authored profile plane onto the path-normal plane before
    // handing it to either PipeShell or the explicit taper/twist branches.
    // PipeShell's WithCorrection is ambiguous when a face-hosted profile plane
    // contains the spine: it may transport the section away from the selected
    // model edge even though the resolved edge direction is correct.
    const gp_Pnt start = BRep_Tool::Pnt(firstVertex);
    const gp_Dir from = profileFrame.Direction();
    const gp_Dir to = AssociativeSweepEdgeTangent(edges.front(), true);
    const double dot = std::clamp(gp_Vec(from).Dot(gp_Vec(to)), -1.0, 1.0);
    if (dot < 1.0 - 1.0e-10) {
      gp_Vec axis = gp_Vec(from).Crossed(gp_Vec(to));
      if (axis.Magnitude() <= 1.0e-9) {
        axis = std::abs(from.X()) < 0.8 ? gp_Vec(from).Crossed(gp_Vec(1.0, 0.0, 0.0))
                                        : gp_Vec(from).Crossed(gp_Vec(0.0, 1.0, 0.0));
      }
      gp_Trsf correction;
      correction.SetRotation(gp_Ax1(start, gp_Dir(axis)), std::acos(dot));
      sectionShape = BRepBuilderAPI_Transform(sectionShape, correction, true).Shape();
    }
  }
  const double startRotation = parameters.value("startRotationDegrees", 0.0);
  if (std::abs(startRotation) > 1.0e-9) {
    const gp_Pnt start = BRep_Tool::Pnt(firstVertex);
    const gp_Dir tangent = AssociativeSweepEdgeTangent(edges.front(), true);
    gp_Trsf rotation;
    constexpr double kSweepDegreesToRadians = 0.017453292519943295;
    rotation.SetRotation(gp_Ax1(start, tangent), startRotation * kSweepDegreesToRadians);
    sectionShape = BRepBuilderAPI_Transform(sectionShape, rotation, true).Shape();
  }
  const TopoDS_Wire section = TopoDS::Wire(sectionShape);
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);

  if (edges.size() == 1 && (std::abs(taperAngle) > 1.0e-9 || std::abs(twistAngle) > 1.0e-9)) {
    const BRepAdaptor_Curve pathCurve(edges.front());
    if (pathCurve.GetType() != GeomAbs_Line)
      throw std::invalid_argument(
          "associative sweep taper/twist controls require a straight path edge");
    TopoDS_Vertex first;
    TopoDS_Vertex last;
    TopExp::Vertices(edges.front(), first, last, /*CumOri=*/true);
    if (first.IsNull() || last.IsNull())
      throw std::invalid_argument("associative sweep controls need path endpoints");
    const gp_Pnt start = BRep_Tool::Pnt(first);
    const gp_Pnt end = BRep_Tool::Pnt(last);
    const gp_Vec pathVector(start, end);
    const double pathLength = pathVector.Magnitude();
    if (!(pathLength > 1.0e-9))
      throw std::invalid_argument("associative sweep controls need a non-zero path");

    TopoDS_Shape endShape = section;
    const double scale = 1.0 + std::tan(taperAngle * 0.017453292519943295) * pathLength;
    if (!(scale > 1.0e-6))
      throw std::invalid_argument("associative sweep taper collapses the end section");
    if (std::abs(scale - 1.0) > 1.0e-9) {
      gp_Trsf taper;
      taper.SetScale(start, scale);
      endShape = BRepBuilderAPI_Transform(endShape, taper, true).Shape();
    }
    if (std::abs(twistAngle) > 1.0e-9) {
      gp_Trsf twist;
      twist.SetRotation(gp_Ax1(start, gp_Dir(pathVector)), twistAngle * 0.017453292519943295);
      endShape = BRepBuilderAPI_Transform(endShape, twist, true).Shape();
    }
    gp_Trsf translation;
    translation.SetTranslation(pathVector);
    endShape = BRepBuilderAPI_Transform(endShape, translation, true).Shape();

    BRepOffsetAPI_ThruSections controlled(/*isSolid=*/true, /*ruled=*/false);
    controlled.AddWire(section);
    controlled.AddWire(TopoDS::Wire(endShape));
    controlled.Build(progress->Start());
    CheckCancellation(cancelled);
    if (!controlled.IsDone() || controlled.Shape().IsNull() ||
        controlled.Shape().ShapeType() != TopAbs_SOLID ||
        Count(controlled.Shape(), TopAbs_SOLID) != 1)
      throw Standard_Failure("associative sweep taper/twist loft failed");
    if (!BRepCheck_Analyzer(controlled.Shape(), false).IsValid())
      throw Standard_Failure("associative sweep taper/twist produced an invalid solid");
    return FinishSolidBody(operation, TopoDS::Solid(controlled.Shape()),
                           "associative sweep taper/twist");
  }

  if (edges.size() > 1 && (std::abs(taperAngle) > 1.0e-9 || std::abs(twistAngle) > 1.0e-9)) {
    for (const TopoDS_Edge& edge : edges) {
      if (BRepAdaptor_Curve(edge).GetType() != GeomAbs_Line)
        throw std::invalid_argument(
            "associative sweep multi-edge taper/twist currently requires straight path edges");
    }
    std::vector<gp_Pnt> pathVertices;
    pathVertices.reserve(edges.size() + 1);
    for (const TopoDS_Edge& edge : edges) {
      TopoDS_Vertex first;
      TopoDS_Vertex last;
      TopExp::Vertices(edge, first, last, /*CumOri=*/true);
      if (first.IsNull() || last.IsNull())
        throw std::invalid_argument("associative sweep controls need path vertices");
      if (pathVertices.empty())
        pathVertices.push_back(BRep_Tool::Pnt(first));
      const gp_Pnt endpoint = BRep_Tool::Pnt(last);
      if (pathVertices.back().Distance(endpoint) <= 1.0e-9)
        throw std::invalid_argument("associative sweep controls contain a zero-length segment");
      pathVertices.push_back(endpoint);
    }
    if (pathVertices.size() < 3)
      throw std::logic_error("associative sweep multi-edge control path lost its vertices");

    const gp_Vec firstTangent(pathVertices[0], pathVertices[1]);
    const gp_Dir firstDirection(firstTangent);
    const auto tangentAt = [&pathVertices](const std::size_t index) {
      if (index == 0)
        return gp_Dir(gp_Vec(pathVertices[0], pathVertices[1]));
      if (index + 1 == pathVertices.size())
        return gp_Dir(gp_Vec(pathVertices[index - 1], pathVertices[index]));
      const gp_Vec incoming(pathVertices[index - 1], pathVertices[index]);
      const gp_Vec outgoing(pathVertices[index], pathVertices[index + 1]);
      gp_Vec blended = gp_Vec(gp_Dir(incoming)) + gp_Vec(gp_Dir(outgoing));
      if (blended.Magnitude() <= 1.0e-9)
        blended = outgoing;
      return gp_Dir(blended);
    };
    const auto frameRotation = [](const gp_Dir& from, const gp_Dir& to, const gp_Pnt& origin) {
      const double dot = std::clamp(gp_Vec(from).Dot(gp_Vec(to)), -1.0, 1.0);
      if (dot >= 1.0 - 1.0e-10)
        return gp_Trsf{};
      gp_Vec axis = gp_Vec(from).Crossed(gp_Vec(to));
      if (axis.Magnitude() <= 1.0e-9) {
        axis = std::abs(from.X()) < 0.8 ? gp_Vec(from).Crossed(gp_Vec(1.0, 0.0, 0.0))
                                        : gp_Vec(from).Crossed(gp_Vec(0.0, 1.0, 0.0));
      }
      gp_Trsf rotation;
      rotation.SetRotation(gp_Ax1(origin, gp_Dir(axis)), std::acos(dot));
      return rotation;
    };
    double totalLength = 0.0;
    for (std::size_t index = 1; index < pathVertices.size(); ++index)
      totalLength += pathVertices[index - 1].Distance(pathVertices[index]);
    double traveled = 0.0;
    BRepOffsetAPI_ThruSections controlled(/*isSolid=*/true, /*ruled=*/false);
    for (std::size_t index = 0; index < pathVertices.size(); ++index) {
      if (index > 0)
        traveled += pathVertices[index - 1].Distance(pathVertices[index]);
      const double scale = 1.0 + std::tan(taperAngle * 0.017453292519943295) * traveled;
      if (!(scale > 1.0e-6))
        throw std::invalid_argument("associative sweep taper collapses an intermediate section");
      TopoDS_Shape sectionAtVertex = section;
      if (index > 0 && std::abs(scale - 1.0) > 1.0e-9) {
        gp_Trsf taper;
        taper.SetScale(pathVertices[0], scale);
        sectionAtVertex = BRepBuilderAPI_Transform(sectionAtVertex, taper, true).Shape();
      }
      const gp_Dir localTangent = tangentAt(index);
      if (naturalOrientation && index > 0) {
        const gp_Trsf frame = frameRotation(firstDirection, localTangent, pathVertices[0]);
        sectionAtVertex = BRepBuilderAPI_Transform(sectionAtVertex, frame, true).Shape();
      }
      if (index > 0) {
        gp_Trsf translation;
        translation.SetTranslation(gp_Vec(pathVertices.front(), pathVertices[index]));
        sectionAtVertex = BRepBuilderAPI_Transform(sectionAtVertex, translation, true).Shape();
      }
      if (index > 0 && std::abs(twistAngle) > 1.0e-9) {
        gp_Trsf twist;
        twist.SetRotation(
            gp_Ax1(pathVertices[index], naturalOrientation ? localTangent : firstDirection),
            twistAngle * traveled / totalLength * 0.017453292519943295);
        sectionAtVertex = BRepBuilderAPI_Transform(sectionAtVertex, twist, true).Shape();
      }
      controlled.AddWire(TopoDS::Wire(sectionAtVertex));
    }
    controlled.Build(progress->Start());
    CheckCancellation(cancelled);
    if (!controlled.IsDone() || controlled.Shape().IsNull() ||
        controlled.Shape().ShapeType() != TopAbs_SOLID ||
        Count(controlled.Shape(), TopAbs_SOLID) != 1)
      throw Standard_Failure("associative sweep multi-edge taper/twist loft failed");
    if (!BRepCheck_Analyzer(controlled.Shape(), false).IsValid())
      throw Standard_Failure("associative sweep multi-edge taper/twist is invalid");
    return FinishSolidBody(operation, TopoDS::Solid(controlled.Shape()),
                           "associative sweep multi-edge taper/twist");
  }

  BRepOffsetAPI_MakePipeShell pipe(spine);
  if (parameters.contains("guideRail") && !parameters.at("guideRail").is_null()) {
    if (registry == nullptr)
      throw std::invalid_argument("associative sweep guideRail requires the naming registry");
    const std::vector<EvaluatedBody> visible = pool.PeekVisibleBodies();
    const RefResolution resolution =
        ResolveRefSlotStrict(operationId, "sweep", "guideRail", parameters.at("guideRail"), visible,
                             *registry, cancelled);
    const QueryEntity& entity = SingleResolvedEntity("sweep", "guideRail", 'e', resolution);
    // OCCT's auxiliary-spine mode controls the section's roll while the
    // authored path remains the actual sweep spine. Straight path/guide pairs
    // use normal-plane correspondence: unlike normalized distance, it supports
    // a section located inside (rather than at an endpoint of) the model edge.
    // General curves retain normalized-distance mapping because a broken
    // upstream guide can make plane-intersection mode enter an unbounded search.
    TopoDS_Edge guideEdge = TopoDS::Edge(entity.shape);
    TopoDS_Vertex pathStart;
    TopoDS_Vertex pathFirstEnd;
    TopExp::Vertices(edges.front(), pathStart, pathFirstEnd, /*CumOri=*/true);
    TopoDS_Vertex pathLastStart;
    TopoDS_Vertex pathEnd;
    TopExp::Vertices(edges.back(), pathLastStart, pathEnd, /*CumOri=*/true);
    TopoDS_Vertex guideStart;
    TopoDS_Vertex guideEnd;
    TopExp::Vertices(guideEdge, guideStart, guideEnd, /*CumOri=*/true);
    if (pathStart.IsNull() || pathEnd.IsNull() || guideStart.IsNull() || guideEnd.IsNull())
      throw std::invalid_argument("associative sweep guideRail requires bounded path endpoints");
    const double alignedDistance = BRep_Tool::Pnt(pathStart).Distance(BRep_Tool::Pnt(guideStart)) +
                                   BRep_Tool::Pnt(pathEnd).Distance(BRep_Tool::Pnt(guideEnd));
    const double reversedDistance = BRep_Tool::Pnt(pathStart).Distance(BRep_Tool::Pnt(guideEnd)) +
                                    BRep_Tool::Pnt(pathEnd).Distance(BRep_Tool::Pnt(guideStart));
    if (reversedDistance < alignedDistance)
      guideEdge = TopoDS::Edge(guideEdge.Reversed());
    BRepBuilderAPI_MakeWire guideMaker;
    guideMaker.Add(guideEdge);
    if (!guideMaker.IsDone())
      throw std::invalid_argument("associative sweep guideRail could not form an auxiliary wire");
    const bool straightPair = edges.size() == 1 &&
                              BRepAdaptor_Curve(edges.front()).GetType() == GeomAbs_Line &&
                              BRepAdaptor_Curve(guideEdge).GetType() == GeomAbs_Line;
    constexpr double kSweepGuideEndpointTolerance = 1.0e-6;
    const bool profileAtPathEndpoint =
        profileAnchor.Distance(BRep_Tool::Pnt(pathStart)) <= kSweepGuideEndpointTolerance ||
        profileAnchor.Distance(BRep_Tool::Pnt(pathEnd)) <= kSweepGuideEndpointTolerance;
    const bool usePlaneCorrespondence = straightPair && !profileAtPathEndpoint;
    pipe.SetMode(guideMaker.Wire(),
                 /*CurvilinearEquivalence=*/!usePlaneCorrespondence);
  }
  if (parameters.contains("guideSurface") && !parameters.at("guideSurface").is_null()) {
    if (registry == nullptr)
      throw std::invalid_argument("associative sweep guideSurface requires the naming registry");
    const std::vector<EvaluatedBody> visible = pool.PeekVisibleBodies();
    const RefResolution resolution =
        ResolveRefSlotStrict(operationId, "sweep", "guideSurface", parameters.at("guideSurface"),
                             visible, *registry, cancelled);
    const QueryEntity& entity = SingleResolvedEntity("sweep", "guideSurface", 'f', resolution);
    if (!pipe.SetMode(entity.shape))
      throw std::invalid_argument(
          "associative sweep guideSurface does not support every authored path edge");
  }
  pipe.SetTransitionMode(BRepBuilderAPI_RightCorner);
  const bool natural = parameters.value("orientation", "natural") == "natural";
  if (!natural) {
    if ((parameters.contains("guideRail") && !parameters.at("guideRail").is_null()) ||
        (parameters.contains("guideSurface") && !parameters.at("guideSurface").is_null()))
      throw std::invalid_argument(
          "associative sweep fixed orientation cannot be combined with a guide rail or surface");
    pipe.SetMode(profileFrame);
  }
  pipe.Add(section, /*WithContact=*/false, /*WithCorrection=*/natural);
  pipe.Build(progress->Start());
  CheckCancellation(cancelled);
  if (!pipe.IsDone() || !pipe.MakeSolid())
    throw Standard_Failure("associative sweep could not produce a capped solid");
  const TopoDS_Shape result = pipe.Shape();
  if (result.IsNull() || result.ShapeType() != TopAbs_SOLID)
    throw Standard_Failure("associative sweep did not produce a single solid body");
  if (!BRepCheck_Analyzer(result, false).IsValid())
    throw Standard_Failure("associative sweep produced an invalid solid");
  return FinishSolidBody(operation, TopoDS::Solid(result), "associative sweep");
}

EvaluatedBody EvaluateLoftBoolean(const nlohmann::json& operation,
                                  const std::map<std::string, EvaluatedProfile>& profiles,
                                  BodyPool& pool, ElementNameBook* elementNames,
                                  NamingRegistry* registry, const std::atomic_bool& cancelled) {
  (void)elementNames;
  const auto& boolean = operation.at("parameters").at("boolean");
  const std::string mode = boolean.at("mode").get<std::string>();
  if (mode == "newBody")
    return EvaluateLoftV2(operation, profiles, pool, registry, cancelled);
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetId = boolean.at("targetOperationId").get<std::string>();

  // Evaluate the loft as an independent tool first; only the boolean mode is
  // replaced in this ephemeral copy so the tool cannot consume its own target.
  nlohmann::json toolOperation = operation;
  toolOperation["parameters"]["boolean"] = {{"mode", "newBody"}};
  const EvaluatedBody tool = EvaluateLoftV2(toolOperation, profiles, pool, registry, cancelled);
  const TopoDS_Shape target = pool.Consume(operationId, "loft " + mode, "target", targetId);
  if (mode == "cut" && !ToolRemovesMaterial(target, tool.shape, cancelled))
    throw Standard_Failure(
        "loft cut removed no material: the lofted tool does not overlap the target body");

  std::unique_ptr<BRepAlgoAPI_BooleanOperation> algorithm;
  if (mode == "join")
    algorithm = std::make_unique<BRepAlgoAPI_Fuse>();
  else if (mode == "cut")
    algorithm = std::make_unique<BRepAlgoAPI_Cut>();
  else if (mode == "intersect")
    algorithm = std::make_unique<BRepAlgoAPI_Common>();
  else
    throw std::invalid_argument("unsupported loft boolean mode: " + mode);

  NCollection_List<TopoDS_Shape> objects;
  objects.Append(target);
  NCollection_List<TopoDS_Shape> tools;
  tools.Append(tool.shape);
  algorithm->SetArguments(objects);
  algorithm->SetTools(tools);
  algorithm->SetRunParallel(false);
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  algorithm->Build(progress->Start());
  CheckCancellation(cancelled);
  if (!algorithm->IsDone())
    throw OperationFailure(operationId, "GEOMETRY_FAILED",
                           "loft " + mode + " failed against its target body",
                           {{"code", "E_LOFT_BOOLEAN_FAILED"}});
  const TopoDS_Shape shape = algorithm->Shape();
  if (shape.IsNull())
    throw Standard_Failure("loft boolean produced no shape");
  return FinishBodyShape(operation, shape, "loft");
}

EvaluatedBody
EvaluateAssociativeSweepBoolean(const nlohmann::json& operation,
                                const std::map<std::string, EvaluatedProfile>& profiles,
                                BodyPool& pool, ElementNameBook* elementNames,
                                NamingRegistry* registry, const std::atomic_bool& cancelled) {
  const auto& boolean = operation.at("parameters").at("boolean");
  const std::string mode = boolean.at("mode").get<std::string>();
  if (mode == "newBody")
    return EvaluateSweepV2(operation, profiles, pool, registry, cancelled);
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetId = boolean.at("targetOperationId").get<std::string>();

  // Evaluate the sweep as an independent tool first. The authored operation
  // remains the single source of identity; only the boolean mode is replaced
  // in this ephemeral evaluator copy so the tool geometry cannot consume its
  // target before the explicit boolean below does so.
  nlohmann::json toolOperation = operation;
  toolOperation["parameters"]["boolean"] = {{"mode", "newBody"}};
  const EvaluatedBody tool = EvaluateSweepV2(toolOperation, profiles, pool, registry, cancelled);
  const TopoDS_Shape target = pool.Consume(operationId, "sweep " + mode, "target", targetId);
  if (mode == "cut" && !ToolRemovesMaterial(target, tool.shape, cancelled))
    throw Standard_Failure(
        "sweep cut removed no material: the swept tool does not overlap the target body");

  std::unique_ptr<BRepAlgoAPI_BooleanOperation> algorithm;
  if (mode == "join")
    algorithm = std::make_unique<BRepAlgoAPI_Fuse>();
  else if (mode == "cut")
    algorithm = std::make_unique<BRepAlgoAPI_Cut>();
  else if (mode == "intersect")
    algorithm = std::make_unique<BRepAlgoAPI_Common>();
  else
    throw std::invalid_argument("unsupported associative sweep boolean mode: " + mode);

  NCollection_List<TopoDS_Shape> objects;
  objects.Append(target);
  NCollection_List<TopoDS_Shape> tools;
  tools.Append(tool.shape);
  algorithm->SetArguments(objects);
  algorithm->SetTools(tools);
  algorithm->SetRunParallel(false);
  algorithm->SetToFillHistory(elementNames != nullptr);
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  algorithm->Build(progress->Start());
  CheckCancellation(cancelled);
  if (algorithm->HasErrors())
    throw Standard_Failure(("sweep " + mode + " boolean failed").c_str());
  const TopoDS_Shape result = algorithm->Shape();
  if (result.IsNull() || Count(result, TopAbs_SOLID) != 1)
    throw Standard_Failure(("sweep " + mode + " boolean must produce one solid").c_str());

  const TopExp_Explorer solids(result, TopAbs_SOLID);
  EvaluatedBody body =
      FinishSolidBody(operation, TopoDS::Solid(solids.Current()), "associative sweep boolean");
  if (elementNames != nullptr) {
    const occ::handle<BRepTools_History> history = algorithm->History();
    if (history.IsNull())
      throw Standard_Failure(("sweep " + mode + " boolean did not record history").c_str());
    elementNames->AddDerivedPrimitive(operationId, tool.shape);
    elementNames->ApplyOperation(operationId, {target, tool.shape}, body.shape, *history,
                                 cancelled);
    if (registry != nullptr) {
      registry->HarvestSyntheticTool(operationId, tool.shape, cancelled);
      registry->HarvestOperation(operationId, NamingRegistry::OperationClass::Boolean,
                                 {{target, false, false}, {tool.shape, true, true}}, body.shape,
                                 *history, cancelled);
    }
  }
  return body;
}

EvaluatedBody EvaluateSweep(const nlohmann::json& operation,
                            const std::map<std::string, EvaluatedProfile>& profiles,
                            const BodyPool& pool, NamingRegistry* registry,
                            const std::atomic_bool& cancelled) {
  if (operation.value("schemaVersion", 1) >= 2)
    return EvaluateSweepV2(operation, profiles, pool, registry, cancelled);
  const auto& parameters = operation.at("parameters");
  const std::string profileOperationId = parameters.at("profileOperationId").get<std::string>();

  const auto profile = profiles.find(profileOperationId);
  if (profile == profiles.end()) {
    // Operation-level reference failure (ADR-003), identical to extrude.
    throw ReferenceMissing(operation.at("id").get<std::string>(),
                           "sweep references operation " + profileOperationId +
                               ", which is not an evaluated profile operation earlier in the "
                               "document");
  }

  std::vector<gp_Pnt> pathPoints;
  if (parameters.contains("profilePath")) {
    const auto& profilePath = parameters.at("profilePath");
    if (profilePath.at("kind").get<std::string>() != "normal")
      throw std::invalid_argument("unsupported profile-relative sweep path");
    const double lengthMm = profilePath.at("lengthMm").get<double>();
    if (!(lengthMm > 0.0))
      throw std::invalid_argument("profile-relative sweep path length must be positive");
    pathPoints.push_back(profile->second.origin);
    pathPoints.push_back(
        profile->second.origin.Translated(lengthMm * gp_Vec(profile->second.normal)));
  } else {
    const auto& literalPath = parameters.at("path");
    if (!literalPath.is_array())
      throw std::invalid_argument("sweep path needs an array of points");
    pathPoints.reserve(literalPath.size());
    for (const auto& pointValue : literalPath) {
      const gp_Vec point = JsonVector(pointValue);
      pathPoints.emplace_back(point.X(), point.Y(), point.Z());
    }
  }
  if (pathPoints.size() < 2)
    throw std::invalid_argument("sweep path needs at least two points");

  // Section/spine contract (enforced, not silently transported): the profile
  // section must sit at the spine's first point. OCCT's MakePipeShell will
  // happily sweep a section offset from the spine start and return a valid but
  // semantically surprising solid; requiring coincidence keeps the swept body
  // deterministic and predictable. Profile relocation onto the path start is a
  // future feature, not an implicit side effect of sweep.
  const gp_Pnt firstPathPoint = pathPoints.front();
  if (profile->second.origin.Distance(firstPathPoint) > 1.0e-6) {
    throw std::invalid_argument(
        "sweep section must sit at the spine's first point: the profile placement origin does "
        "not coincide with the first path point");
  }

  // Build the spine as an open polyline wire from consecutive path points.
  BRepBuilderAPI_MakeWire spineMaker;
  gp_Pnt previous;
  bool havePrevious = false;
  for (const gp_Pnt& current : pathPoints) {
    if (havePrevious) {
      BRepBuilderAPI_MakeEdge edge(previous, current);
      if (!edge.IsDone())
        throw std::invalid_argument("sweep path has a zero-length or invalid segment");
      spineMaker.Add(edge.Edge());
    }
    previous = current;
    havePrevious = true;
  }
  if (!spineMaker.IsDone())
    throw Standard_Failure("sweep spine wire construction failed");
  const TopoDS_Wire spine = spineMaker.Wire();

  // Copy the section wire so this sweep owns its geometry even when several
  // features consume the same profile within one evaluation (as extrude does).
  const TopoDS_Wire section =
      TopoDS::Wire(BRepBuilderAPI_Copy(BRepTools::OuterWire(profile->second.face)).Shape());
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepOffsetAPI_MakePipeShell pipe(spine);
  // Miter polyline corners rather than let the default transition self-intersect.
  pipe.SetTransitionMode(BRepBuilderAPI_RightCorner);
  // `WithCorrection=true` rotates a coincident but tilted input section onto
  // the spine's normal plane. This implements the wire contract (the section
  // is kept perpendicular to the spine) and makes the resulting caps agree
  // with the naming boundaries derived from the path tangents.
  pipe.Add(section, /*WithContact=*/false, /*WithCorrection=*/true);
  pipe.Build(progress->Start());
  CheckCancellation(cancelled);
  if (!pipe.IsDone())
    throw Standard_Failure("sweep pipe construction failed");
  if (!pipe.MakeSolid())
    throw Standard_Failure("sweep could not cap the swept shell into a solid");
  const TopoDS_Shape result = pipe.Shape();
  if (result.IsNull() || result.ShapeType() != TopAbs_SOLID)
    throw Standard_Failure("sweep did not produce a single solid body");
  // A path too tightly curved for the section self-intersects; refuse it as a
  // geometry failure rather than emit an invalid body.
  if (!BRepCheck_Analyzer(result, false).IsValid())
    throw Standard_Failure(
        "sweep produced an invalid solid; the path may be too tightly curved for the section");
  return FinishSolidBody(operation, TopoDS::Solid(result), "sweep");
}

NamingRegistry::BirthSpec NamingBirthSpec(const nlohmann::json& operation,
                                          const std::map<std::string, EvaluatedProfile>& profiles,
                                          const BodyPool& pool, NamingRegistry* registry,
                                          const std::atomic_bool& cancelled) {
  using BirthBoundary = NamingRegistry::BirthBoundary;
  using BirthClass = NamingRegistry::BirthClass;
  const std::string type = operation.at("type").get<std::string>();
  const nlohmann::json& parameters = operation.at("parameters");
  if (type == "sweep" && operation.value("schemaVersion", 1) >= 2) {
    gp_Pnt profileAnchor;
    if (parameters.contains("faceProfile") && !parameters.at("faceProfile").is_null()) {
      if (registry == nullptr)
        throw std::invalid_argument(
            "associative sweep faceProfile naming requires the naming registry");
      const std::vector<EvaluatedBody> visible = pool.PeekVisibleBodies();
      const RefResolution resolution =
          ResolveRefSlotStrict(operation.at("id").get<std::string>(), "sweep", "faceProfile",
                               parameters.at("faceProfile"), visible, *registry, cancelled);
      const QueryEntity& entity = SingleResolvedEntity("sweep", "faceProfile", 'f', resolution);
      const BRepAdaptor_Surface surface(TopoDS::Face(entity.shape), true);
      if (surface.GetType() != GeomAbs_Plane)
        throw std::invalid_argument("associative sweep faceProfile naming requires a plane");
      GProp_GProps profileProperties;
      BRepGProp::SurfaceProperties(TopoDS::Face(entity.shape), profileProperties);
      profileAnchor = profileProperties.CentreOfMass();
    } else {
      const std::string profileOperationId = parameters.at("profileOperationId").get<std::string>();
      const auto profile = profiles.find(profileOperationId);
      if (profile == profiles.end())
        throw ReferenceMissing(operation.at("id").get<std::string>(),
                               "sweep naming lost its evaluated profile operation");
      profileAnchor = profile->second.frame.Location();
    }
    std::vector<TopoDS_Edge> edges = LimitAssociativeSweepPath(
        ResolveAssociativeSweepPath(operation, pool, registry, cancelled, &profileAnchor),
        operation.at("parameters").at("extent"));
    if (operation.at("parameters").at("extent").value("mode", "full") == "toReference")
      edges = LimitAssociativeSweepPathToReference(operation, edges, pool, registry, cancelled);
    if (edges.empty())
      throw std::invalid_argument("associative sweep naming requires a non-empty path");
    // Take the chain's ENDS with orientation. TopExp_Explorer walks an edge's
    // vertices in raw topology order, which ignores the direction
    // ResolveAssociativeSweepPath already normalized — on a two-edge chain it
    // returned the SHARED corner from both ends, so the path looked
    // zero-length and the birth boundary landed on the wrong face.
    TopoDS_Vertex firstVertex;
    TopoDS_Vertex firstTrailing;
    TopExp::Vertices(edges.front(), firstVertex, firstTrailing, /*CumOri=*/true);
    TopoDS_Vertex lastLeading;
    TopoDS_Vertex lastVertex;
    TopExp::Vertices(edges.back(), lastLeading, lastVertex, /*CumOri=*/true);
    if (firstVertex.IsNull() || lastVertex.IsNull())
      throw std::invalid_argument("associative sweep naming requires path endpoints");
    const gp_Pnt start = BRep_Tool::Pnt(firstVertex);
    const gp_Pnt end = BRep_Tool::Pnt(lastVertex);
    if (start.Distance(end) <= 1.0e-9)
      throw std::invalid_argument("associative sweep path must have distinct endpoints");
    const gp_Dir startNormal = AssociativeSweepEdgeTangent(edges.front(), true);
    const gp_Dir endNormal = AssociativeSweepEdgeTangent(edges.back(), false);
    return {BirthClass::Sweep, BirthBoundary{start, startNormal, true},
            BirthBoundary{end, endNormal, true}};
  }
  const auto placementBounds = [&parameters](const BirthClass operationClass, const double height,
                                             const bool endFaceExpected = true) {
    const gp_Ax2 frame = PlacementFrame(parameters.at("placement"));
    const gp_Pnt start = frame.Location();
    const gp_Pnt end = start.Translated(height * gp_Vec(frame.Direction()));
    return NamingRegistry::BirthSpec{
        operationClass,
        BirthBoundary{start, frame.Direction(), true},
        BirthBoundary{end, frame.Direction(), endFaceExpected},
    };
  };
  const auto requireProfile =
      [&profiles](const std::string& operationId) -> const EvaluatedProfile& {
    const auto found = profiles.find(operationId);
    if (found == profiles.end())
      throw std::runtime_error(
          "naming registry lost a profile already resolved by the body birth executor");
    return found->second;
  };

  if (type == "create_cylinder") {
    return placementBounds(BirthClass::Cylinder, parameters.at("height").get<double>());
  }
  if (type == "create_sphere")
    return {BirthClass::Sphere, std::nullopt, std::nullopt};
  if (type == "create_cone") {
    const double radiusTop = parameters.at("radiusTop").get<double>();
    return placementBounds(BirthClass::Cone, parameters.at("height").get<double>(),
                           radiusTop > 0.0);
  }
  if (type == "create_torus")
    return {BirthClass::Torus, std::nullopt, std::nullopt};
  if (type == "create_wedge") {
    const double topWidth = parameters.at("topWidth").get<double>();
    return placementBounds(BirthClass::Wedge, parameters.at("height").get<double>(),
                           topWidth > 0.0);
  }
  if (type == "base_flange") {
    // Byte-identical topology to extrude (see EvaluateBaseFlange's own
    // comment) — two profile-shaped caps plus N swept side walls — so it
    // reuses BirthClass::Extrude's role table rather than a new class.
    // FaceOnBoundary/EdgeOnBoundary only test parallelism to `boundary.normal`
    // (via abs(dot)) plus anchor position, so passing `profile.normal`
    // unsigned for BOTH ends is correct for either sweep direction — the same
    // shape extrude's own two boundaries already use.
    const EvaluatedProfile& profile =
        requireProfile(parameters.at("profileOperationId").get<std::string>());
    const double thickness = parameters.at("thicknessMm").get<double>();
    const std::string direction = parameters.value("direction", "normal");
    const double sign = direction == "reverse" ? -1.0 : 1.0;
    return {
        BirthClass::Extrude,
        BirthBoundary{profile.origin, profile.normal, true},
        BirthBoundary{profile.origin.Translated(sign * thickness * gp_Vec(profile.normal)),
                      profile.normal, true},
    };
  }
  if (type == "revolve") {
    const EvaluatedProfile& profile =
        requireProfile(parameters.at("profileOperationId").get<std::string>());
    const double angleDegrees = parameters.at("angleDegrees").get<double>();
    if (angleDegrees >= 360.0 - 1.0e-9)
      return {BirthClass::Revolve, std::nullopt, std::nullopt};
    const gp_Ax1 axis =
        parameters.contains("profileAxis")
            ? ProfileRelativeAxis(profile, parameters.at("profileAxis").get<std::string>())
            : gp_Ax1(
                  [&]() {
                    const gp_Vec origin = JsonVector(parameters.at("axisOrigin"));
                    return gp_Pnt(origin.X(), origin.Y(), origin.Z());
                  }(),
                  gp_Dir(JsonVector(parameters.at("axisDirection"))));
    constexpr double kDegreesToRadians = 0.017453292519943295;
    gp_Trsf rotation;
    rotation.SetRotation(axis, angleDegrees * kDegreesToRadians);
    return {
        BirthClass::Revolve,
        BirthBoundary{profile.origin, profile.normal, true},
        BirthBoundary{profile.origin.Transformed(rotation), profile.normal.Transformed(rotation),
                      true},
    };
  }
  if (type == "loft") {
    if (operation.value("schemaVersion", 1) < 2) {
      const nlohmann::json& profileIds = parameters.at("profileOperationIds");
      const EvaluatedProfile& first = requireProfile(profileIds.front().get<std::string>());
      const EvaluatedProfile& last = requireProfile(profileIds.back().get<std::string>());
      return {
          BirthClass::Loft,
          BirthBoundary{first.origin, first.normal, true},
          BirthBoundary{last.origin, last.normal, true},
      };
    }
    // v2: a boundary section may be a profile, a model face, an edge loop or a
    // point tip, so resolve it the same way the evaluator does. A closed or
    // surface loft has no caps at all and must declare that rather than making
    // the cap-count invariant demand faces that cannot exist.
    const nlohmann::json& sections = parameters.at("sections");
    const bool capped = parameters.value("result", std::string("solid")) == "solid" &&
                        !parameters.value("closed", false);
    const std::vector<EvaluatedBody> visible = pool.PeekVisibleBodies();
    const auto boundary = [&](const std::size_t index) {
      const nlohmann::json& section = sections.at(index);
      const std::string kind = section.value("kind", std::string("profile"));
      const std::string slot = "sections[" + std::to_string(index) + "]";
      if (kind == "profile") {
        const EvaluatedProfile& profile =
            requireProfile(section.at("operationId").get<std::string>());
        return BirthBoundary{profile.origin, profile.normal, capped};
      }
      if (registry == nullptr)
        throw std::invalid_argument("loft naming requires selector resolution for a ref section");
      const char expected = kind == "point" ? 'v' : (kind == "face" ? 'f' : 'e');
      const RefResolution resolution =
          ResolveRefSlotStrict(operation.at("id").get<std::string>(), "loft", slot.c_str(),
                               section.at("ref"), visible, *registry, cancelled);
      const QueryEntity& entity = SingleResolvedEntity("loft", slot.c_str(), expected, resolution);
      if (kind == "point") {
        // A tip contributes no cap face regardless of the result mode.
        return BirthBoundary{BRep_Tool::Pnt(TopoDS::Vertex(entity.shape)), gp_Dir(0.0, 0.0, 1.0),
                             false};
      }
      TopoDS_Wire wire;
      if (kind == "face")
        wire = BRepTools::OuterWire(TopoDS::Face(entity.shape));
      else
        wire = BRepBuilderAPI_MakeWire(TopoDS::Edge(entity.shape)).Wire();
      const gp_Ax2 frame = LoftWireFrame(wire);
      return BirthBoundary{frame.Location(), frame.Direction(), capped};
    };
    return {BirthClass::Loft, boundary(0), boundary(sections.size() - 1)};
  }
  if (type == "sweep") {
    gp_Pnt start;
    gp_Pnt next;
    gp_Pnt previous;
    gp_Pnt end;
    if (parameters.contains("profilePath")) {
      const EvaluatedProfile& profile =
          requireProfile(parameters.at("profileOperationId").get<std::string>());
      const double lengthMm = parameters.at("profilePath").at("lengthMm").get<double>();
      start = profile.origin;
      next = profile.origin.Translated(lengthMm * gp_Vec(profile.normal));
      previous = start;
      end = next;
    } else {
      const nlohmann::json& path = parameters.at("path");
      const gp_Vec startVector = JsonVector(path.front());
      const gp_Vec nextVector = JsonVector(path.at(1));
      const gp_Vec previousVector = JsonVector(path.at(path.size() - 2));
      const gp_Vec endVector = JsonVector(path.back());
      start = gp_Pnt(startVector.X(), startVector.Y(), startVector.Z());
      next = gp_Pnt(nextVector.X(), nextVector.Y(), nextVector.Z());
      previous = gp_Pnt(previousVector.X(), previousVector.Y(), previousVector.Z());
      end = gp_Pnt(endVector.X(), endVector.Y(), endVector.Z());
    }
    return {
        BirthClass::Sweep,
        BirthBoundary{start, gp_Dir(gp_Vec(start, next)), true},
        BirthBoundary{end, gp_Dir(gp_Vec(previous, end)), true},
    };
  }
  throw std::runtime_error("naming registry requested a birth spec for non-birth operation " +
                           type);
}

EvaluatedBody EvaluateTransform(const nlohmann::json& operation, BodyPool& pool,
                                ElementNameBook* elementNames, NamingRegistry* registry,
                                const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId = parameters.at("targetOperationId").get<std::string>();
  const auto& transform = parameters.at("transform");
  const std::string kind = transform.at("kind").get<std::string>();

  gp_Trsf trsf;
  constexpr double kDegreesToRadians = 0.017453292519943295;
  if (kind == "translate") {
    trsf.SetTranslation(JsonVector(transform.at("offset")));
  } else if (kind == "rotate") {
    const gp_Vec axisOrigin = JsonVector(transform.at("axisOrigin"));
    const gp_Vec axisDirection = JsonVector(transform.at("axisDirection"));
    if (axisDirection.Magnitude() < 1e-9)
      throw std::invalid_argument("transform rotate axis direction must be non-zero");
    const double angleDegrees = transform.at("angleDegrees").get<double>();
    trsf.SetRotation(
        gp_Ax1(gp_Pnt(axisOrigin.X(), axisOrigin.Y(), axisOrigin.Z()), gp_Dir(axisDirection)),
        angleDegrees * kDegreesToRadians);
  } else if (kind == "scale") {
    const double factor = transform.at("factor").get<double>();
    if (!(factor > 0.0))
      throw std::invalid_argument("transform scale factor must be positive");
    trsf.SetScale(gp_Pnt(0.0, 0.0, 0.0), factor);
  } else if (kind == "mirror") {
    const gp_Vec planeOrigin = JsonVector(transform.at("planeOrigin"));
    const gp_Vec planeNormal = JsonVector(transform.at("planeNormal"));
    if (planeNormal.Magnitude() < 1e-9)
      throw std::invalid_argument("transform mirror plane normal must be non-zero");
    // A gp_Ax2's XY plane (perpendicular to its main direction) is the mirror
    // plane, so the plane normal is the Ax2's direction.
    trsf.SetMirror(
        gp_Ax2(gp_Pnt(planeOrigin.X(), planeOrigin.Y(), planeOrigin.Z()), gp_Dir(planeNormal)));
  } else {
    throw std::invalid_argument("unsupported transform kind: " + kind);
  }

  // Transform CONSUMES its target (translate/rotate/scale/mirror replaces it
  // in place), the same taxonomy as boolean_combine and hole.
  const TopoDS_Shape target = pool.Consume(operationId, "transform", "target", targetOperationId);
  CheckCancellation(cancelled);
  BRepBuilderAPI_Transform maker(target, trsf, /*Copy=*/true);
  if (!maker.IsDone())
    throw Standard_Failure("transform construction failed");
  const TopoDS_Shape result = maker.Shape();
  if (result.IsNull() || result.ShapeType() != TopAbs_SOLID)
    throw Standard_Failure("transform did not produce a single solid body");
  EvaluatedBody body = FinishSolidBody(operation, TopoDS::Solid(result), "transform result");
  if (elementNames != nullptr) {
    // BRepBuilderAPI_Transform's standard history surface is exact for this
    // use: with Copy=true every input sub-shape has exactly one Modified
    // image (BRepTools_Modifier), nothing is deleted, and nothing is
    // generated — so every entity's name gains one plain M step, which the
    // survivor-matching normalization erases (identity survives a move).
    NCollection_List<TopoDS_Shape> arguments;
    arguments.Append(target);
    const occ::handle<BRepTools_History> history = new BRepTools_History(arguments, maker);
    elementNames->ApplyOperation(operationId, {target}, body.shape, *history, cancelled);
    if (registry != nullptr) {
      // Tranche N3: transform needs no op-specific role table — every entity
      // is the 1:1 Modified continuation of its source (reserved `modified`
      // role), so each record aliases forward and anything else in the
      // history is rejected as incoherent.
      registry->HarvestOperation(operationId, NamingRegistry::OperationClass::Transform,
                                 {{target, false}}, body.shape, *history, cancelled);
    }
  }
  return body;
}

/// The founder's ruled LOCAL FACE OFFSET (ADR-014, plan-04 `### offset`): a
/// topological re-trim and stitching cycle, composed from three verified
/// history-carrying primitives. Nothing here translates a trim — the prism's
/// side walls lie EXACTLY in the neighbour planes, so the boolean RE-TRIMS the
/// neighbours against the moved surface and they keep their own surfaces.
EvaluatedBody EvaluateLocalFaceOffset(const nlohmann::json& operation, BodyPool& pool,
                                      const TopoDS_Face& targetFace, const double distance,
                                      ElementNameBook* elementNames, NamingRegistry* registry,
                                      const std::atomic_bool& cancelled) {
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId =
      operation.at("parameters").at("targetOperationId").get<std::string>();

  // doc-04 E_OFFSET_UNSUPPORTED_SURFACE: curved targets are UNSPECIFIED, so
  // they refuse rather than approximate. Approximating here would be exactly
  // the plausible-looking-wrong-answer class the ruling excludes.
  BRepAdaptor_Surface surface(targetFace, true);
  if (surface.GetType() != GeomAbs_Plane)
    throw OperationFailure(operationId, "GEOMETRY_FAILED",
                           "offsetting a curved face is not supported yet",
                           {{"code", "E_OFFSET_UNSUPPORTED_SURFACE"}});

  gp_Dir normal = surface.Plane().Axis().Direction();
  if (targetFace.Orientation() == TopAbs_REVERSED)
    normal.Reverse();

  const TopoDS_Shape target = pool.Consume(operationId, "offset", "target", targetOperationId);
  const bool outward = distance > 0.0;

  const auto buildAt = [&](const double signedDistance, TopoDS_Shape& out,
                           occ::handle<BRepTools_History>& outHistory,
                           TopoDS_Shape& outPrism) -> bool {
    const TopoDS_Shape prism =
        BRepPrimAPI_MakePrism(targetFace, gp_Vec(normal.XYZ() * signedDistance)).Shape();
    if (prism.IsNull())
      return false;
    outPrism = prism;
    NCollection_List<TopoDS_Shape> objects;
    objects.Append(target);
    NCollection_List<TopoDS_Shape> tools;
    tools.Append(prism);

    TopoDS_Shape combined;
    occ::handle<BRepTools_History> booleanHistory;
    if (signedDistance > 0.0) {
      BRepAlgoAPI_Fuse fuse;
      fuse.SetArguments(objects);
      fuse.SetTools(tools);
      // Determinism mandate: document evaluation never runs OCCT in parallel.
      fuse.SetRunParallel(false);
      fuse.SetToFillHistory(true);
      fuse.Build();
      if (!fuse.IsDone())
        return false;
      combined = fuse.Shape();
      booleanHistory = fuse.History();
    } else {
      BRepAlgoAPI_Cut cut;
      cut.SetArguments(objects);
      cut.SetTools(tools);
      cut.SetRunParallel(false);
      cut.SetToFillHistory(true);
      cut.Build();
      if (!cut.IsDone())
        return false;
      combined = cut.Shape();
      booleanHistory = cut.History();
    }
    if (combined.IsNull() || booleanHistory.IsNull())
      return false;

    // Step 3 — the ruling's third clause, not a cosmetic simplification.
    // Without it the outward case leaves each neighbour SPLIT into original
    // plus extension (same plane, redundant seam): 10 faces where 6 is right.
    ShapeUpgrade_UnifySameDomain unify(combined, true, true, false);
    unify.Build();
    const TopoDS_Shape unified = unify.Shape();
    if (unified.IsNull())
      return false;

    // The COMPOSED history of steps 2 and 3. Unify is permitted on this path,
    // and ONLY here, because it exposes its own BRepTools_History and therefore
    // composes rather than erases (ADR-014 §3); boolean_combine's no-unify
    // convention is unchanged.
    occ::handle<BRepTools_History> merged = new BRepTools_History;
    merged->Merge(booleanHistory);
    if (!unify.History().IsNull())
      merged->Merge(unify.History());

    // MEASURED: the merge emits SELF-images — `Modified(x)` containing `x` —
    // for entities a stage left untouched. That is an identity survivor wearing
    // a Modified badge, and the registry rightly rejects it as an incoherent
    // history ("identity-survives yet claims Modified images"). Rebuild the
    // composed history keeping only images that are genuinely different
    // shapes, so identity survival stays the clean route ADR-014 §4 requires.
    occ::handle<BRepTools_History> composed = new BRepTools_History;
    NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> sources;
    for (const TopAbs_ShapeEnum kind : {TopAbs_FACE, TopAbs_EDGE, TopAbs_VERTEX}) {
      TopExp::MapShapes(target, kind, sources);
      TopExp::MapShapes(prism, kind, sources);
    }
    for (int index = 1; index <= sources.Extent(); ++index) {
      const TopoDS_Shape& source = sources(index);
      for (const TopoDS_Shape& image : merged->Modified(source)) {
        if (!image.IsSame(source))
          composed->AddModified(source, image);
      }
      for (const TopoDS_Shape& image : merged->Generated(source)) {
        if (!image.IsSame(source))
          composed->AddGenerated(source, image);
      }
      if (merged->IsRemoved(source))
        composed->Remove(source);
    }

    out = unified;
    outHistory = composed;
    return true;
  };

  // The boolean returns the result WRAPPED (typically a compound around the
  // solid), exactly as MakeFillet/MakeChamfer do — so acceptance tests the
  // contained solid, never the wrapper's own ShapeType.
  const auto isAcceptable = [](const TopoDS_Shape& candidate) {
    if (candidate.IsNull() || Count(candidate, TopAbs_SOLID) != 1)
      return false;
    const ShapeProbes probes = ProbeShape(candidate);
    // Result validation is an invariant, not a courtesy (plan-04): one solid,
    // one closed shell, analyzer-clean — or a typed refusal. No third outcome.
    return probes.valid && probes.solidCount == 1 && probes.shellCount == 1;
  };

  TopoDS_Shape result;
  TopoDS_Shape prism;
  occ::handle<BRepTools_History> history;
  bool built = false;
  try {
    built = buildAt(distance, result, history, prism);
  } catch (const Standard_Failure&) {
    CheckCancellation(cancelled);
    built = false;
  }
  CheckCancellation(cancelled);

  if (!built || !isAcceptable(result)) {
    // §1.4 bounded probe: report a TESTED lower bound. Nothing clamps to it —
    // shrinking the distance would be the app making a design decision the
    // person did not make.
    const double sign = outward ? 1.0 : -1.0;
    const auto bound = ProbeMaxFeasible(std::abs(distance), [&](const double magnitude) {
      CheckCancellation(cancelled);
      try {
        TopoDS_Shape trial;
        TopoDS_Shape trialPrism;
        occ::handle<BRepTools_History> trialHistory;
        return buildAt(sign * magnitude, trial, trialHistory, trialPrism) && isAcceptable(trial);
      } catch (const Standard_Failure&) {
        CheckCancellation(cancelled);
        return false;
      }
    });
    if (bound.has_value()) {
      const double signedBound = sign * bound->maxFeasible;
      // The measured bound rides in `details`, never interpolated into the
      // message: CAP-006 found the kernel had already measured the bound and
      // was dropping it on the way out, so the presentation layer formats
      // `maxFeasibleDistance` and the kernel stays language-free.
      // NO `code` key here, and its absence is a CONTRACT requirement rather
      // than an oversight: when `details.feasibilityProbe` is present the wire
      // schema validates the WHOLE details object against the strict
      // bounded-feasibility shape (`kernelErrorSchema`'s superRefine). One
      // extra key makes the response fail to parse, and the user sees "Kernel
      // control stream is corrupt" — a transport error for what is actually a
      // well-formed refusal. Other GEOMETRY_FAILED details stay additive; only
      // the probe-bearing payload is closed. The packaged gate caught this,
      // because in-process these details never cross the wire.
      throw OperationFailure(operationId, "GEOMETRY_FAILED",
                             "moving this face that far collapses or self-intersects the body",
                             {{"requestedDistance", distance},
                              {"maxFeasibleDistance", signedBound},
                              {"feasibilityProbe",
                               {{"parameter", "distance"},
                                {"requested", distance},
                                {"maxFeasible", signedBound},
                                {"bound", "tested-lower-bound"},
                                {"attempts", bound->attempts}}}});
    }
    throw OperationFailure(operationId, "GEOMETRY_FAILED",
                           "the face offset failed and no feasible distance was found",
                           {{"code", "E_OFFSET_FAILED"}});
  }

  TopExp_Explorer solidExplorer(result, TopAbs_SOLID);
  EvaluatedBody body =
      FinishSolidBody(operation, TopoDS::Solid(solidExplorer.Current()), "offset result");
  if (elementNames != nullptr) {
    // The prism is SWEPT FROM the target's own face, so it shares that face and
    // its boundary with the target and those names must survive; only the swept
    // walls and the moved face are new. AddPrimitive would (correctly) refuse
    // the re-registration, so this path uses the derived-tool variant.
    elementNames->AddDerivedPrimitive(operationId, prism);
    elementNames->ApplyOperation(operationId, {target, prism}, body.shape, *history, cancelled);
  }
  if (registry != nullptr) {
    // The swept prism is a SYNTHETIC tool with no document identity of its own
    // — it is derived from the target face and the distance, never a body — so
    // it roots at this operation exactly as the hole's cylinder does. Without
    // registering it, the faces the boolean generates from its side walls have
    // no ancestor token and the totality rule refuses the whole request.
    registry->HarvestSyntheticTool(operationId, prism, cancelled);
    registry->HarvestOperation(operationId, NamingRegistry::OperationClass::Offset,
                               {{target, false, false}, {prism, true, true}}, body.shape, *history,
                               cancelled);
  }
  return body;
}

EvaluatedBody EvaluateOffset(const nlohmann::json& operation, BodyPool& pool,
                             ElementNameBook* elementNames, NamingRegistry* registry,
                             const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId = parameters.at("targetOperationId").get<std::string>();
  const double distance = parameters.at("distance").get<double>();
  if (!(std::abs(distance) > 1e-9))
    throw std::invalid_argument("offset distance must be non-zero");

  // Face-scoped LOCAL offset (schemaVersion 2) — the founder's ruled semantics
  // (ADR-014, plan-04 `### offset`). Resolve the `face` ref against the replay
  // state BEFORE consuming the target, the fillet-v2/chamfer mold, so the
  // query's op(...)/body(...) sources see exactly the bodies this op sees.
  // An absent `face` slot keeps the v1 whole-body path bit-for-bit.
  if (parameters.contains("face")) {
    if (registry == nullptr)
      throw std::invalid_argument(
          "unsupported operation: a face-scoped offset requires the naming registry; evaluate "
          "with the registry enabled");
    const nlohmann::json& faceSlot = parameters.at("face");
    if (!faceSlot.contains("ast"))
      throw std::invalid_argument(
          "offset face reference reached the kernel unparsed (persisted query form); the "
          "transport must ship the wire AST (operationRefWireSchema)");
    const std::vector<EvaluatedBody> peekedBodies = pool.PeekVisibleBodies();
    const RefResolution resolution = ResolveRef(faceSlot, peekedBodies, *registry, cancelled);
    if (resolution.status == RefStatus::Empty)
      throw SelectorFailure(
          operationId, "REFERENCE_MISSING", "E_SEL_EMPTY", resolution.message,
          {{"selectorCode", "E_SEL_EMPTY"}, {"stageCardinalities", resolution.stageCardinalities}});
    if (resolution.status == RefStatus::Ambiguous) {
      nlohmann::json candidates = nlohmann::json::array();
      for (const QueryEntity& candidate : resolution.candidates)
        candidates.push_back(ResolvedEntityToJson(candidate));
      throw SelectorFailure(operationId, "REFERENCE_AMBIGUOUS", "E_SEL_AMBIGUOUS",
                            resolution.message,
                            {{"selectorCode", "E_SEL_AMBIGUOUS"}, {"candidates", candidates}});
    }
    if (resolution.entities.size() != 1)
      throw std::invalid_argument("offset face reference must resolve to exactly one face");
    const QueryEntity& entity = resolution.entities.front();
    if (entity.kind != 'f')
      throw std::invalid_argument(
          "offset face reference resolved a non-face entity; the slot is face-kinded");
    // doc-04 validation 3: the cross-body guard. A face on another visible body
    // would sweep and fuse into a plausible-looking wrong answer.
    for (const EvaluatedBody& peeked : peekedBodies) {
      if (peeked.operationId == targetOperationId && entity.bodyId != peeked.bodyId)
        throw OperationFailure(operationId, "GEOMETRY_FAILED",
                               "the offset face reference resolved a face outside the target body",
                               {{"code", "E_OFFSET_FACE_NOT_ON_BODY"}});
    }
    return EvaluateLocalFaceOffset(operation, pool, TopoDS::Face(entity.shape), distance,
                                   elementNames, registry, cancelled);
  }

  // Fail closed under element naming (tranche N0): BRepOffsetAPI_MakeOffsetShape's
  // IsDeleted/Modified/Generated surface is unverified against the pinned
  // OCCT, and unverified history must never mint names — a wrong-but-
  // deterministic lineage is exactly the silent-misreference shape the
  // tournament exists to exclude. This guard is scoped to the v1 WHOLE-BODY
  // path only: the v2 local-face path above runs a different, fixture-pinned
  // pipeline whose history IS verified (ADR-014 §2).
  if (elementNames != nullptr) {
    throw std::invalid_argument(
        "unsupported operation: offset cannot record element names yet; evaluate without "
        "includeElementNames");
  }

  // Offset CONSUMES its target (the grown/inset body replaces it in place),
  // the same taxonomy as boolean_combine and hole.
  const TopoDS_Shape target = pool.Consume(operationId, "offset", "target", targetOperationId);

  const auto failWithBound = [&](const std::string& message) {
    const double sign = distance < 0.0 ? -1.0 : 1.0;
    const auto bound = ProbeMaxFeasible(std::abs(distance), [&](const double magnitude) {
      CheckCancellation(cancelled);
      try {
        const occ::handle<CancellationProgress> trialProgress = MakeCancellationProgress(cancelled);
        BRepOffsetAPI_MakeOffsetShape trial;
        trial.PerformByJoin(target, sign * magnitude, 1.0e-6, BRepOffset_Skin, false, false,
                            GeomAbs_Arc, false, trialProgress->Start());
        CheckCancellation(cancelled);
        if (!trial.IsDone())
          return false;
        const TopoDS_Shape trialResult = trial.Shape();
        return !trialResult.IsNull() && trialResult.ShapeType() == TopAbs_SOLID &&
               BRepCheck_Analyzer(trialResult, false).IsValid();
      } catch (const Standard_Failure&) {
        CheckCancellation(cancelled);
        return false;
      }
    });

    nlohmann::json details;
    if (bound.has_value()) {
      const double signedBound = sign * bound->maxFeasible;
      details = {{"requestedDistance", distance},
                 {"maxFeasibleDistance", signedBound},
                 {"feasibilityProbe",
                  {{"parameter", "distance"},
                   {"requested", distance},
                   {"maxFeasible", signedBound},
                   {"bound", "tested-lower-bound"},
                   {"attempts", bound->attempts}}}};
    }
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message, std::move(details));
  };

  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepOffsetAPI_MakeOffsetShape maker;
  try {
    maker.PerformByJoin(target, distance, 1.0e-6, BRepOffset_Skin, false, false, GeomAbs_Arc, false,
                        progress->Start());
  } catch (const Standard_Failure& error) {
    CheckCancellation(cancelled);
    failWithBound(error.what());
  }
  CheckCancellation(cancelled);
  if (!maker.IsDone())
    failWithBound(
        "offset construction failed; the distance may collapse or self-intersect the body");
  const TopoDS_Shape result = maker.Shape();
  if (result.IsNull() || result.ShapeType() != TopAbs_SOLID)
    failWithBound("offset did not produce a single solid body");
  // A negative offset deeper than the body's own thickness collapses it; refuse
  // the degenerate result rather than emit an invalid body.
  if (!BRepCheck_Analyzer(result, false).IsValid())
    failWithBound("offset produced an invalid solid; the inset likely collapsed the body");
  return FinishSolidBody(operation, TopoDS::Solid(result), "offset result");
}

EvaluatedBody EvaluateFillet(const nlohmann::json& operation, BodyPool& pool,
                             ElementNameBook* elementNames, NamingRegistry* registry,
                             const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId = parameters.at("targetOperationId").get<std::string>();
  const double radius = parameters.at("radius").get<double>();
  if (!(radius > 0.0))
    throw std::invalid_argument("fillet radius must be positive");

  // Edge-scoped fillet (schemaVersion 2): resolve the `edges` ref against the
  // replay state BEFORE consuming the target, so the query's op(...)/body(...)
  // sources see exactly the bodies this op sees. Absent `edges` keeps the v1
  // all-edges behavior. Resolution is a TYPED gate (plan 05 §8): an empty or
  // ambiguous match REFUSES the op rather than rounding a guessed edge — the
  // cardinal no-silent-misreference rule made representable.
  std::vector<TopoDS_Edge> selectedEdges;
  const bool edgeScoped = parameters.contains("edges");
  if (edgeScoped) {
    if (registry == nullptr)
      throw std::invalid_argument(
          "unsupported operation: an edge-scoped fillet requires the naming registry; evaluate "
          "with the registry enabled");
    // Pre-N6 transport seam (F1): evaluate_document can hand this kernel a v2
    // fillet whose `edges` slot is still the PERSISTED form ({query:"<string>"},
    // no `ast` key) because the N6 transport transform that lowers the query
    // string to the wire AST does not exist yet. Refuse it here with an
    // ATTRIBUTED std::invalid_argument (the per-op catch chain in
    // EvaluateOperations wraps a non-"unsupported operation" invalid_argument
    // into OperationFailure(operationId, "INVALID_REQUEST", ...)); without this
    // guard ResolveRef's `refSlot.at("ast")` throws a bare, unattributed
    // nlohmann::json::out_of_range that escapes the catch chain.
    const nlohmann::json& edgesSlot = parameters.at("edges");
    if (!edgesSlot.contains("ast"))
      throw std::invalid_argument(
          "fillet edges reference reached the kernel unparsed (persisted query form); the "
          "transport must ship the wire AST (operationRefWireSchema)");
    // Capture the replay-state snapshot before resolving so the cross-body
    // guard (F4) can reuse it — resolution peeks the same visible bodies.
    const std::vector<EvaluatedBody> peekedBodies = pool.PeekVisibleBodies();
    const RefResolution resolution = ResolveRef(edgesSlot, peekedBodies, *registry, cancelled);
    if (resolution.status == RefStatus::Empty)
      throw SelectorFailure(
          operationId, "REFERENCE_MISSING", "E_SEL_EMPTY", resolution.message,
          {{"selectorCode", "E_SEL_EMPTY"}, {"stageCardinalities", resolution.stageCardinalities}});
    if (resolution.status == RefStatus::Ambiguous) {
      nlohmann::json candidates = nlohmann::json::array();
      for (const QueryEntity& candidate : resolution.candidates)
        candidates.push_back(ResolvedEntityToJson(candidate));
      throw SelectorFailure(operationId, "REFERENCE_AMBIGUOUS", "E_SEL_AMBIGUOUS",
                            resolution.message,
                            {{"selectorCode", "E_SEL_AMBIGUOUS"}, {"candidates", candidates}});
    }
    // Target-body constraint (F4): every resolved edge must live on the body
    // this fillet targets. A cross-body edge is a live sub-shape of some OTHER
    // visible body, so maker.Add would accept it and the miss would only surface
    // later as a confusing GEOMETRY_FAILED from maker.Build. Locate the target
    // in the peeked snapshot; if it is not visible here (a bad targetOperationId)
    // skip the comparison and let the later pool.Consume raise the canonical
    // ReferenceMissing rather than duplicating that check.
    const std::string* targetBodyId = nullptr;
    for (const EvaluatedBody& peeked : peekedBodies) {
      if (peeked.operationId == targetOperationId) {
        targetBodyId = &peeked.bodyId;
        break;
      }
    }
    for (const QueryEntity& entity : resolution.entities) {
      if (entity.kind != 'e')
        throw std::invalid_argument(
            "fillet edges reference resolved a non-edge entity; the slot is edge-kinded");
      if (targetBodyId != nullptr && entity.bodyId != *targetBodyId)
        throw std::invalid_argument(
            "fillet edges reference resolved an edge outside the fillet target body");
      selectedEdges.push_back(TopoDS::Edge(entity.shape));
    }
    if (selectedEdges.empty())
      throw std::invalid_argument("fillet edges reference resolved to no edges to round");
  }

  // Fillet CONSUMES its target, the same taxonomy as boolean_combine and hole.
  const TopoDS_Shape target = pool.Consume(operationId, "fillet", "target", targetOperationId);
  if (!edgeScoped) {
    // v1 rounds every unique edge by the same radius (no edge selection).
    NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> edges;
    TopExp::MapShapes(target, TopAbs_EDGE, edges);
    if (edges.Extent() == 0)
      throw std::invalid_argument("fillet target has no edges to round");
    selectedEdges.reserve(static_cast<std::size_t>(edges.Extent()));
    for (int index = 1; index <= edges.Extent(); ++index)
      selectedEdges.push_back(TopoDS::Edge(edges(index)));
  }

  const auto isFeasibleRadius = [&](const double candidate) {
    CheckCancellation(cancelled);
    try {
      const occ::handle<CancellationProgress> trialProgress = MakeCancellationProgress(cancelled);
      BRepFilletAPI_MakeFillet trial(target);
      for (const TopoDS_Edge& edge : selectedEdges)
        trial.Add(candidate, edge);
      trial.Build(trialProgress->Start());
      CheckCancellation(cancelled);
      if (!trial.IsDone())
        return false;
      const TopoDS_Shape trialResult = trial.Shape();
      if (trialResult.IsNull() || Count(trialResult, TopAbs_SOLID) != 1)
        return false;
      TopExp_Explorer solidExplorer(trialResult, TopAbs_SOLID);
      return BRepCheck_Analyzer(TopoDS::Solid(solidExplorer.Current()), false).IsValid();
    } catch (const Standard_Failure&) {
      CheckCancellation(cancelled);
      return false;
    }
  };

  const auto failWithBound = [&](const std::string& message) {
    const auto bound = ProbeMaxFeasible(radius, isFeasibleRadius);
    nlohmann::json details;
    if (bound.has_value()) {
      details = {{"requestedRadius", radius},
                 {"maxFeasibleRadius", bound->maxFeasible},
                 {"feasibilityProbe",
                  {{"parameter", "radius"},
                   {"requested", radius},
                   {"maxFeasible", bound->maxFeasible},
                   {"bound", "tested-lower-bound"},
                   {"attempts", bound->attempts}}}};
    }
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message, std::move(details));
  };

  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepFilletAPI_MakeFillet maker(target);
  // Edge-scoped v2 and all-edge v1 now share the exact retained list used by
  // the feasibility probe, so the diagnostic can never test a different op.
  for (const TopoDS_Edge& edge : selectedEdges)
    maker.Add(radius, edge);
  try {
    maker.Build(progress->Start());
  } catch (const Standard_Failure& error) {
    CheckCancellation(cancelled);
    failWithBound(error.what());
  }
  CheckCancellation(cancelled);
  if (!maker.IsDone())
    failWithBound("fillet construction failed; the radius may be too large for an edge");
  const TopoDS_Shape result = maker.Shape();
  // MakeFillet returns the modified shape wrapped (typically a compound around
  // the solid); extract the single solid it should contain.
  if (result.IsNull() || Count(result, TopAbs_SOLID) != 1)
    failWithBound("fillet did not produce a single solid body");
  TopExp_Explorer solidExplorer(result, TopAbs_SOLID);
  const TopoDS_Solid solid = TopoDS::Solid(solidExplorer.Current());
  if (!BRepCheck_Analyzer(solid, false).IsValid())
    failWithBound(
        "fillet produced an invalid solid; the radius likely exceeds an edge's neighborhood");
  EvaluatedBody body = FinishSolidBody(operation, solid, "fillet result");
  if (elementNames != nullptr) {
    // MakeFillet exposes no History() handle; materialize one through
    // BRepTools_History's template constructor with the IsDeleted correction
    // documented on LocalOperationHistorySource. The fillet history is
    // face-only for Modified(), so the book's lower-bound reconstruction is
    // what names the blend boundary edges and vertices — exactly the gap the
    // element-map scheme exists to fill.
    NCollection_List<TopoDS_Shape> arguments;
    arguments.Append(target);
    LocalOperationHistorySource historySource(maker, body.shape);
    const occ::handle<BRepTools_History> history = new BRepTools_History(arguments, historySource);
    elementNames->ApplyOperation(operationId, {target}, body.shape, *history, cancelled);
    if (registry != nullptr) {
      // Tranche N3: blend faces harvest under `fillet` from the same
      // materialized local-operation history; the face-only Modified surface
      // leaves blend boundary edges/vertices to the reserved `generated`
      // role (their lineage is the book's L-reconstruction).
      registry->HarvestOperation(operationId, NamingRegistry::OperationClass::Fillet,
                                 {{target, false}}, body.shape, *history, cancelled);
    }
  }
  return body;
}

EvaluatedBody EvaluateChamfer(const nlohmann::json& operation, BodyPool& pool,
                              ElementNameBook* elementNames, NamingRegistry* registry,
                              const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId = parameters.at("targetOperationId").get<std::string>();
  const double distance = parameters.at("distance").get<double>();
  if (!(distance > 0.0))
    throw std::invalid_argument("chamfer distance must be positive");

  // Edge-scoped chamfer (schemaVersion 2), the fillet-v2 path verbatim: resolve
  // the `edges` ref against the replay state BEFORE consuming the target, so
  // the query's op(...)/body(...) sources see exactly the bodies this op sees.
  // Absent `edges` keeps the v1 all-edges behavior. Resolution is a TYPED gate
  // (plan 05 §8): empty or ambiguous REFUSES rather than bevelling a guess.
  std::vector<TopoDS_Edge> selectedEdges;
  const bool edgeScoped = parameters.contains("edges");
  if (edgeScoped) {
    if (registry == nullptr)
      throw std::invalid_argument(
          "unsupported operation: an edge-scoped chamfer requires the naming registry; evaluate "
          "with the registry enabled");
    // Persisted-form trust boundary: the wire must carry the parsed AST, never
    // the raw query string (see the fillet twin for why a bare out_of_range
    // would escape the attribution chain).
    const nlohmann::json& edgesSlot = parameters.at("edges");
    if (!edgesSlot.contains("ast"))
      throw std::invalid_argument(
          "chamfer edges reference reached the kernel unparsed (persisted query form); the "
          "transport must ship the wire AST (operationRefWireSchema)");
    const std::vector<EvaluatedBody> peekedBodies = pool.PeekVisibleBodies();
    const RefResolution resolution = ResolveRef(edgesSlot, peekedBodies, *registry, cancelled);
    if (resolution.status == RefStatus::Empty)
      throw SelectorFailure(
          operationId, "REFERENCE_MISSING", "E_SEL_EMPTY", resolution.message,
          {{"selectorCode", "E_SEL_EMPTY"}, {"stageCardinalities", resolution.stageCardinalities}});
    if (resolution.status == RefStatus::Ambiguous) {
      nlohmann::json candidates = nlohmann::json::array();
      for (const QueryEntity& candidate : resolution.candidates)
        candidates.push_back(ResolvedEntityToJson(candidate));
      throw SelectorFailure(operationId, "REFERENCE_AMBIGUOUS", "E_SEL_AMBIGUOUS",
                            resolution.message,
                            {{"selectorCode", "E_SEL_AMBIGUOUS"}, {"candidates", candidates}});
    }
    // Target-body constraint: a cross-body edge is a live sub-shape of some
    // OTHER visible body, so maker.Add would accept it and the miss would only
    // surface later as a confusing GEOMETRY_FAILED (doc-04 E_CHAMFER_MULTI_BODY).
    const std::string* targetBodyId = nullptr;
    for (const EvaluatedBody& peeked : peekedBodies) {
      if (peeked.operationId == targetOperationId) {
        targetBodyId = &peeked.bodyId;
        break;
      }
    }
    for (const QueryEntity& entity : resolution.entities) {
      if (entity.kind != 'e')
        throw std::invalid_argument(
            "chamfer edges reference resolved a non-edge entity; the slot is edge-kinded");
      if (targetBodyId != nullptr && entity.bodyId != *targetBodyId)
        throw std::invalid_argument(
            "chamfer edges reference resolved an edge outside the chamfer target body");
      selectedEdges.push_back(TopoDS::Edge(entity.shape));
    }
    if (selectedEdges.empty())
      throw std::invalid_argument("chamfer edges reference resolved to no edges to bevel");
  }

  const TopoDS_Shape target = pool.Consume(operationId, "chamfer", "target", targetOperationId);
  if (!edgeScoped) {
    // v1 bevels every unique edge by the same symmetric distance. The
    // two-argument Add applies a symmetric chamfer, so no reference face is
    // needed.
    NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> edges;
    TopExp::MapShapes(target, TopAbs_EDGE, edges);
    if (edges.Extent() == 0)
      throw std::invalid_argument("chamfer target has no edges to bevel");
    selectedEdges.reserve(static_cast<std::size_t>(edges.Extent()));
    for (int index = 1; index <= edges.Extent(); ++index)
      selectedEdges.push_back(TopoDS::Edge(edges(index)));
  }

  const auto isFeasibleDistance = [&](const double candidate) {
    CheckCancellation(cancelled);
    try {
      const occ::handle<CancellationProgress> trialProgress = MakeCancellationProgress(cancelled);
      BRepFilletAPI_MakeChamfer trial(target);
      for (const TopoDS_Edge& edge : selectedEdges)
        trial.Add(candidate, edge);
      trial.Build(trialProgress->Start());
      CheckCancellation(cancelled);
      if (!trial.IsDone())
        return false;
      const TopoDS_Shape trialResult = trial.Shape();
      if (trialResult.IsNull() || Count(trialResult, TopAbs_SOLID) != 1)
        return false;
      TopExp_Explorer solidExplorer(trialResult, TopAbs_SOLID);
      return BRepCheck_Analyzer(TopoDS::Solid(solidExplorer.Current()), false).IsValid();
    } catch (const Standard_Failure&) {
      CheckCancellation(cancelled);
      return false;
    }
  };

  const auto failWithBound = [&](const std::string& message) {
    const auto bound = ProbeMaxFeasible(distance, isFeasibleDistance);
    nlohmann::json details;
    if (bound.has_value()) {
      details = {{"requestedDistance", distance},
                 {"maxFeasibleDistance", bound->maxFeasible},
                 {"feasibilityProbe",
                  {{"parameter", "distance"},
                   {"requested", distance},
                   {"maxFeasible", bound->maxFeasible},
                   {"bound", "tested-lower-bound"},
                   {"attempts", bound->attempts}}}};
    }
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message, std::move(details));
  };

  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepFilletAPI_MakeChamfer maker(target);
  // Edge-scoped v2 and all-edge v1 share the exact retained list the
  // feasibility probe used, so the diagnostic can never test a different op.
  for (const TopoDS_Edge& edge : selectedEdges)
    maker.Add(distance, edge);
  try {
    maker.Build(progress->Start());
  } catch (const Standard_Failure& error) {
    CheckCancellation(cancelled);
    failWithBound(error.what());
  }
  CheckCancellation(cancelled);
  if (!maker.IsDone())
    failWithBound("chamfer construction failed; the distance may be too large for an edge");
  const TopoDS_Shape result = maker.Shape();
  // MakeChamfer returns the modified shape wrapped (typically a compound around
  // the solid); extract the single solid it should contain.
  if (result.IsNull() || Count(result, TopAbs_SOLID) != 1)
    failWithBound("chamfer did not produce a single solid body");
  TopExp_Explorer solidExplorer(result, TopAbs_SOLID);
  const TopoDS_Solid solid = TopoDS::Solid(solidExplorer.Current());
  if (!BRepCheck_Analyzer(solid, false).IsValid())
    failWithBound(
        "chamfer produced an invalid solid; the distance likely exceeds an edge's neighborhood");
  EvaluatedBody body = FinishSolidBody(operation, solid, "chamfer result");
  if (elementNames != nullptr) {
    // Same history materialization as fillet: MakeChamfer's IsDeleted has the
    // identical face-only result map in the pinned source, so the
    // LocalOperationHistorySource correction covers both local operations.
    NCollection_List<TopoDS_Shape> arguments;
    arguments.Append(target);
    LocalOperationHistorySource historySource(maker, body.shape);
    const occ::handle<BRepTools_History> history = new BRepTools_History(arguments, historySource);
    elementNames->ApplyOperation(operationId, {target}, body.shape, *history, cancelled);
    if (registry != nullptr) {
      // CAP-012: bevel faces harvest under the doc-04 `chamfer` table from the
      // same materialized local-operation history. Like fillet, the face-only
      // Modified surface leaves bevel boundary edges/vertices to the reserved
      // `generated` role rather than guessing them into `chamfer-edge`.
      registry->HarvestOperation(operationId, NamingRegistry::OperationClass::Chamfer,
                                 {{target, false}}, body.shape, *history, cancelled);
    }
  }
  return body;
}

// ---------------------------------------------------------------------------
// import_mesh: ingest a checked aeth-mesh-v1 triangle surface as a solid body
// (defect D-023; MASTER_PLAN §1.4 Tranche E). Unlike import_step (exact B-rep
// read from Part-21), the retained source is the CHECKED, guaranteed-manifold
// surface the TS interchange pipeline produced (packages/interchange
// mesh-import.ts): the operation carries the aeth-mesh-v1 payload base64-encoded,
// so the kernel rebuilds the same solid deterministically WITHOUT the TS repair
// pipeline (which is not linked into the native host). The stored mesh is welded,
// closed, and outward-oriented by construction (08 §6.3.1), so sewing its
// triangles yields closed shell(s) that make a valid solid — one body per §568
// (a multi-lump mesh becomes one body that is a compound of solids, exactly as
// import_step accepts a multi-solid compound).
// ---------------------------------------------------------------------------

// Standard base64 decode (RFC 4648). Any non-alphabet byte other than the '='
// padding fails closed — a corrupted source can never silently decode to
// truncated geometry (Gate 9, file integrity).
std::vector<unsigned char> DecodeBase64(const std::string& text) {
  static constexpr int kInvalid = -1;
  const auto value = [](char c) -> int {
    if (c >= 'A' && c <= 'Z')
      return c - 'A';
    if (c >= 'a' && c <= 'z')
      return c - 'a' + 26;
    if (c >= '0' && c <= '9')
      return c - '0' + 52;
    if (c == '+')
      return 62;
    if (c == '/')
      return 63;
    return kInvalid;
  };
  std::vector<unsigned char> out;
  out.reserve(text.size() / 4 * 3);
  int accumulator = 0;
  int bitCount = 0;
  std::size_t paddingSeen = 0;
  for (const char c : text) {
    if (c == '=') {
      paddingSeen += 1;
      continue;
    }
    const int decoded = value(c);
    if (decoded == kInvalid)
      throw Standard_Failure("import_mesh source is not valid base64");
    if (paddingSeen != 0)
      throw Standard_Failure("import_mesh source has base64 data after its padding");
    accumulator = (accumulator << 6) | decoded;
    bitCount += 6;
    if (bitCount >= 8) {
      bitCount -= 8;
      out.push_back(static_cast<unsigned char>((accumulator >> bitCount) & 0xff));
    }
  }
  return out;
}

// The decoded aeth-mesh-v1 surface: f32 mm positions (xyz per vertex) and u32
// triangle indices, exactly the buffers encodeAethMeshV1 serialized.
struct AethMesh final {
  std::vector<float> positions;
  std::vector<std::uint32_t> indices;
  std::uint32_t vertexCount{};
  std::uint32_t triangleCount{};
};

std::uint32_t ReadU32LE(const unsigned char* p) {
  return static_cast<std::uint32_t>(p[0]) | (static_cast<std::uint32_t>(p[1]) << 8) |
         (static_cast<std::uint32_t>(p[2]) << 16) | (static_cast<std::uint32_t>(p[3]) << 24);
}

float ReadF32LE(const unsigned char* p) {
  const std::uint32_t bits = ReadU32LE(p);
  float out = 0.0F;
  std::memcpy(&out, &bits, sizeof(out));
  return out;
}

// Decodes and fully validates an aeth-mesh-v1 payload (08 §6.3.2 layout,
// mirroring decodeAethMeshV1 in mesh-import.ts): "AETHMESH" magic, u32 version=1,
// u32 flags=0, u32 vertexCount, u32 triCount, f32*3n positions (mm), u32*3t
// indices, every integer/float little-endian. Fail-closed on wrong magic/version,
// any reserved flag bit, zero counts, a length that violates the count arithmetic
// (checked before any large read), an out-of-range index, or a non-finite
// position — the stored mesh is loaded verbatim, so nothing unproven may pass.
AethMesh DecodeAethMeshV1(const std::vector<unsigned char>& bytes) {
  static constexpr std::size_t kHeaderBytes = 24;
  static const char kMagic[8] = {'A', 'E', 'T', 'H', 'M', 'E', 'S', 'H'};
  if (bytes.size() < kHeaderBytes)
    throw Standard_Failure("import_mesh payload is shorter than the aeth-mesh-v1 header");
  for (std::size_t index = 0; index < 8; ++index) {
    if (bytes[index] != static_cast<unsigned char>(kMagic[index]))
      throw Standard_Failure("import_mesh payload does not begin with the aeth-mesh-v1 magic");
  }
  if (ReadU32LE(&bytes[8]) != 1U)
    throw Standard_Failure("import_mesh payload declares an unsupported aeth-mesh version");
  if (ReadU32LE(&bytes[12]) != 0U)
    throw Standard_Failure("import_mesh payload sets reserved aeth-mesh flag bits");
  const std::uint32_t vertexCount = ReadU32LE(&bytes[16]);
  const std::uint32_t triangleCount = ReadU32LE(&bytes[20]);
  if (vertexCount < 1U || triangleCount < 1U)
    throw Standard_Failure("import_mesh payload needs at least one vertex and one triangle");
  // Count arithmetic in 64-bit BEFORE allocating, so hostile counts cannot force
  // a large read: header + 12 bytes/vertex + 12 bytes/triangle.
  const std::uint64_t expected = static_cast<std::uint64_t>(kHeaderBytes) +
                                 static_cast<std::uint64_t>(vertexCount) * 12ULL +
                                 static_cast<std::uint64_t>(triangleCount) * 12ULL;
  if (static_cast<std::uint64_t>(bytes.size()) != expected)
    throw Standard_Failure("import_mesh payload length does not match its vertex/triangle counts");
  AethMesh mesh;
  mesh.vertexCount = vertexCount;
  mesh.triangleCount = triangleCount;
  mesh.positions.resize(static_cast<std::size_t>(vertexCount) * 3);
  for (std::size_t index = 0; index < mesh.positions.size(); ++index) {
    const float component = ReadF32LE(&bytes[kHeaderBytes + index * 4]);
    if (!std::isfinite(component))
      throw Standard_Failure("import_mesh payload has a non-finite position");
    mesh.positions[index] = component;
  }
  const std::size_t indexBase = kHeaderBytes + static_cast<std::size_t>(vertexCount) * 12;
  mesh.indices.resize(static_cast<std::size_t>(triangleCount) * 3);
  for (std::size_t index = 0; index < mesh.indices.size(); ++index) {
    const std::uint32_t value = ReadU32LE(&bytes[indexBase + index * 4]);
    if (value >= vertexCount)
      throw Standard_Failure("import_mesh payload has a triangle index outside the vertex array");
    mesh.indices[index] = value;
  }
  return mesh;
}

// Sews the checked triangle surface into solid material. Every triangle becomes
// a planar face; sewing merges the shared (bit-identical, welded) corners into
// closed shell(s); each shell makes one solid, oriented outward. One shell ⇒ a
// solid; several disconnected lumps ⇒ a compound of solids (still one body).
TopoDS_Shape BuildSolidFromAethMesh(const AethMesh& mesh, const std::atomic_bool& cancelled) {
  const auto point = [&mesh](std::uint32_t vertex) -> gp_Pnt {
    return {static_cast<double>(mesh.positions[vertex * 3]),
            static_cast<double>(mesh.positions[vertex * 3 + 1]),
            static_cast<double>(mesh.positions[vertex * 3 + 2])};
  };
  // Sewing tolerance at the kernel linear tolerance (01 §3, 1e-4 mm): shared
  // corners are already bit-identical f32 after the TS weld+compact, so this only
  // guards f32 spacing, never fuses distinct vertices.
  BRepBuilderAPI_Sewing sewing(1.0e-4, true, true, true, false);
  for (std::uint32_t triangle = 0; triangle < mesh.triangleCount; ++triangle) {
    if ((triangle & 0x3ffU) == 0U)
      CheckCancellation(cancelled);
    const std::uint32_t a = mesh.indices[triangle * 3];
    const std::uint32_t b = mesh.indices[triangle * 3 + 1];
    const std::uint32_t c = mesh.indices[triangle * 3 + 2];
    BRepBuilderAPI_MakePolygon polygon(point(a), point(b), point(c), true);
    if (!polygon.IsDone())
      throw Standard_Failure("import_mesh could not build a triangle wire");
    BRepBuilderAPI_MakeFace face(polygon.Wire(), true);
    if (!face.IsDone())
      throw Standard_Failure("import_mesh could not build a triangle face");
    sewing.Add(face.Face());
  }
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  sewing.Perform(progress->Start());
  CheckCancellation(cancelled);
  const TopoDS_Shape sewn = sewing.SewedShape();
  if (sewn.IsNull())
    throw Standard_Failure("import_mesh sewing produced no shape");

  BRep_Builder builder;
  TopoDS_Compound compound;
  builder.MakeCompound(compound);
  int solidCount = 0;
  TopoDS_Solid lastSolid;
  for (TopExp_Explorer shells(sewn, TopAbs_SHELL); shells.More(); shells.Next()) {
    CheckCancellation(cancelled);
    const TopoDS_Shell shell = TopoDS::Shell(shells.Current());
    BRepBuilderAPI_MakeSolid solidMaker(shell);
    if (!solidMaker.IsDone())
      throw Standard_Failure("import_mesh could not build a solid from a sewn shell");
    TopoDS_Solid solid = solidMaker.Solid();
    BRepLib::OrientClosedSolid(solid);
    TopoDS_Shape material = solid;
    if (!BRepCheck_Analyzer(material, false).IsValid()) {
      // A last-resort repair for the sewn shell's tolerances/orientation; a mesh
      // that still will not form a valid solid is refused, never emitted invalid.
      ShapeFix_Solid fixer;
      const TopoDS_Solid fixed = fixer.SolidFromShell(shell);
      if (!fixed.IsNull() && BRepCheck_Analyzer(fixed, false).IsValid()) {
        material = fixed;
      } else {
        throw Standard_Failure("import_mesh did not form a valid solid from the ingested surface");
      }
    }
    builder.Add(compound, material);
    lastSolid = TopoDS::Solid(material);
    solidCount += 1;
  }
  if (solidCount == 0)
    throw Standard_Failure("import_mesh surface did not sew into any closed shell");
  return solidCount == 1 ? TopoDS_Shape(lastSolid) : TopoDS_Shape(compound);
}

// Ingests a checked aeth-mesh-v1 surface as a solid body (defect D-023). A
// body-birth like import_step and the primitives: fail closed under element
// naming (an import has no per-feature lineage), re-verify the content hash of
// the retained source before building (a source corrupted in transport can never
// silently yield different geometry), then rebuild the solid from the exact bytes.
EvaluatedBody EvaluateImportMesh(const nlohmann::json& operation,
                                 const std::atomic_bool& cancelled) {
  const nlohmann::json& parameters = operation.at("parameters");
  const std::string source = parameters.at("source").get<std::string>();
  const std::string expectedSha = parameters.at("sourceSha256").get<std::string>();
  Sha256 hasher;
  hasher.Update(reinterpret_cast<const unsigned char*>(source.data()), source.size());
  if (hasher.HexDigest() != expectedSha)
    throw std::invalid_argument("import_mesh source does not match its recorded sourceSha256");

  const TopoDS_Shape shape = ImportMeshShapeFromString(source, cancelled);
  if (shape.IsNull())
    throw Standard_Failure("import_mesh produced a null shape");
  EvaluatedBody body;
  body.bodyId = operation.at("outputBodyId").get<std::string>();
  body.operationId = operation.at("id").get<std::string>();
  body.shape = shape;
  body.probes = ProbeShape(shape);
  if (!body.probes.valid || body.probes.solidCount < 1)
    throw Standard_Failure("import_mesh did not yield a valid solid body");
  return body;
}

// Ingests a preserved STEP (ISO-10303-21) B-rep as a solid body (defect D-019;
// MASTER_PLAN §1.4 Tranche E). A body-birth like the primitives, but its
// geometry is not synthesized from numeric parameters — it is read back from
// the exact Part-21 bytes the operation retains (§2.1), so deterministic replay
// rests on the kernel's proven property that identical STEP bytes read back to
// identical topology (the step-reimport oracle in mutation.cpp).
EvaluatedBody EvaluateImportStep(const nlohmann::json& operation,
                                 const std::atomic_bool& cancelled) {
  const nlohmann::json& parameters = operation.at("parameters");
  const std::string source = parameters.at("source").get<std::string>();
  const std::string expectedSha = parameters.at("sourceSha256").get<std::string>();
  // Gate 9 (file integrity): re-derive the content hash and refuse a source
  // that does not match its recorded anchor, so a source corrupted in transport
  // can never silently yield geometry the document never promised.
  Sha256 hasher;
  hasher.Update(reinterpret_cast<const unsigned char*>(source.data()), source.size());
  if (hasher.HexDigest() != expectedSha)
    throw std::invalid_argument("import_step source does not match its recorded sourceSha256");

  const TopoDS_Shape shape = ImportStepShapeFromString(source, cancelled);
  if (shape.IsNull())
    throw Standard_Failure("import_step produced a null shape");
  EvaluatedBody body;
  body.bodyId = operation.at("outputBodyId").get<std::string>();
  body.operationId = operation.at("id").get<std::string>();
  body.shape = shape;
  body.probes = ProbeShape(shape);
  // A STEP import must yield real, valid solid material — never a wireframe,
  // dangling sketch, or empty compound — matching FinishSolidBody's validity
  // contract for the primitive births.
  if (!body.probes.valid || body.probes.solidCount < 1)
    throw Standard_Failure("import_step did not yield a valid solid body");
  return body;
}

// The canonical ordering key for a born solid (ADR-013 decision 1, ruled in
// docs/design/2026-07-28-multi-output-birth-residuals.md).
//
// The order decides which solid is index 0, and index 0 is what every persisted
// reference and every element name is scoped to. It must therefore be a
// property of the SHAPES, never of the reader: OCCT transfer order is stable
// only for a fixed OCCT build, so an upgrade that reordered roots would
// silently remap every body in every multi-solid document and every reference
// would resolve to different geometry with no error anywhere.
struct BirthOrderKey final {
  double volume{};
  double comX{};
  double comY{};
  double comZ{};
  double diagonal{};

  // volume DESC, then centre of mass ascending, then bbox diagonal DESC.
  bool operator<(const BirthOrderKey& other) const {
    if (volume != other.volume)
      return volume > other.volume;
    if (comX != other.comX)
      return comX < other.comX;
    if (comY != other.comY)
      return comY < other.comY;
    if (comZ != other.comZ)
      return comZ < other.comZ;
    return diagonal > other.diagonal;
  }

  bool operator==(const BirthOrderKey& other) const {
    return volume == other.volume && comX == other.comX && comY == other.comY &&
           comZ == other.comZ && diagonal == other.diagonal;
  }
};

BirthOrderKey MakeBirthOrderKey(const ShapeProbes& probes) {
  BirthOrderKey key;
  key.volume = probes.volume;
  key.comX = probes.centerOfMass[0];
  key.comY = probes.centerOfMass[1];
  key.comZ = probes.centerOfMass[2];
  const double dx = probes.bounds[3] - probes.bounds[0];
  const double dy = probes.bounds[4] - probes.bounds[1];
  const double dz = probes.bounds[5] - probes.bounds[2];
  key.diagonal = std::sqrt(dx * dx + dy * dy + dz * dz);
  return key;
}

// Expand one `import_step` into the ordered set of bodies it declares
// (ADR-013). A single-solid import returns exactly one body carrying the
// operation's scalar `outputBodyId` and index 0 — byte-identical to the
// behaviour before fan-out existed.
std::vector<EvaluatedBody> EvaluateImportStepBodies(const nlohmann::json& operation,
                                                    const std::atomic_bool& cancelled) {
  EvaluatedBody whole = EvaluateImportStep(operation, cancelled);
  const std::string operationId = whole.operationId;

  std::vector<std::string> declared;
  if (operation.contains("outputBodyIds")) {
    for (const auto& id : operation.at("outputBodyIds"))
      declared.push_back(id.get<std::string>());
  }

  // Nothing declared: the document says this import is a single body, so it is
  // one body regardless of how many solids the file happens to hold. Splitting
  // it here would hand back bodies the document never declared and cannot
  // reference.
  if (declared.size() <= 1) {
    std::vector<EvaluatedBody> single;
    single.push_back(std::move(whole));
    return single;
  }

  std::vector<std::pair<BirthOrderKey, TopoDS_Shape>> solids;
  for (TopExp_Explorer explorer(whole.shape, TopAbs_SOLID); explorer.More(); explorer.Next()) {
    const TopoDS_Shape solid = explorer.Current();
    solids.emplace_back(MakeBirthOrderKey(ProbeShape(solid)), solid);
  }

  // A declared-vs-produced mismatch is a hard failure, never a silent
  // truncation or a fabricated body: the document promises N referenceable
  // bodies and anything else makes every reference above the produced count
  // dangle (ADR-013 decision 3).
  if (solids.size() != declared.size()) {
    throw Standard_Failure(("import_step declared " + std::to_string(declared.size()) +
                            " bodies but the source yielded " + std::to_string(solids.size()))
                               .c_str());
  }

  std::sort(solids.begin(), solids.end(),
            [](const auto& left, const auto& right) { return left.first < right.first; });

  // Two solids can only tie on volume, centre of mass AND bbox diagonal if they
  // occupy the same place — which disjoint solids cannot. A tie is therefore
  // evidence of a malformed import, and choosing arbitrarily between
  // indistinguishable bodies is how a reference starts pointing at the wrong
  // one. Fail closed instead.
  for (std::size_t index = 1; index < solids.size(); ++index) {
    if (solids[index].first == solids[index - 1].first)
      throw Standard_Failure(
          "import_step cannot order its solids: two are geometrically identical and "
          "coincident, so no stable body index exists");
  }

  std::vector<EvaluatedBody> bodies;
  bodies.reserve(solids.size());
  for (std::size_t index = 0; index < solids.size(); ++index) {
    EvaluatedBody body;
    body.bodyId = declared[index];
    body.operationId = operationId;
    body.outputIndex = static_cast<int>(index);
    body.shape = solids[index].second;
    body.probes = ProbeShape(body.shape);
    if (!body.probes.valid || body.probes.solidCount < 1)
      throw Standard_Failure("import_step yielded a constituent that is not a valid solid");
    bodies.push_back(std::move(body));
  }
  return bodies;
}

// ============================================================================
// Catalog wave 2 executors — mirror / pattern_linear / pattern_circular
// (docs/design/2026-07-19-native-catalog-wave1.md line 285 — "a later wave",
// designed in the shell mold; plan 01-geometry-core/04 `mirror`,
// `pattern-linear`, `pattern-circular`). Each resolves its topology ref through
// the registry-guarded strict slot path (fillet-v2 / shell precedent), consumes
// its operands from the BodyPool (ADR-003), and harvests element names +
// registry records through the SAME retained OCCT history. NO unify/simplify
// stage runs (the landed boolean_combine convention): the naming substrate
// keeps every result entity attributable to ONE source, so v1 patterns/mirrors
// are the shapes whose fuse leaves images 1:1 (a §6.3 merged-image split is the
// `instance-face-split` tranche's contract — see the report).
// ============================================================================

using ShapeToShapeMap = NCollection_DataMap<TopoDS_Shape, TopoDS_Shape, TopTools_ShapeMapHasher>;

// Reverse of a copy operation's 1:1 modify map: image sub-shape -> source
// sub-shape, built from BRepBuilderAPI_Transform::ModifiedShape so a fresh-body
// harvest can record the source's token as an ancestor (correspondence).
ShapeToShapeMap CopyToSourceMap(BRepBuilderAPI_Transform& maker, const TopoDS_Shape& source) {
  ShapeToShapeMap map;
  for (const TopAbs_ShapeEnum kind : {TopAbs_FACE, TopAbs_EDGE, TopAbs_VERTEX}) {
    NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> shapes;
    TopExp::MapShapes(source, kind, shapes);
    for (int index = 1; index <= shapes.Extent(); ++index) {
      const TopoDS_Shape& sub = shapes(index);
      const TopoDS_Shape image = maker.ModifiedShape(sub);
      if (!image.IsNull() && !map.IsBound(image))
        map.Bind(image, sub);
    }
  }
  return map;
}

EvaluatedBody EvaluateMirror(const nlohmann::json& operation, BodyPool& pool,
                             ElementNameBook* elementNames, NamingRegistry* registry,
                             const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string sourceOperationId = parameters.at("sourceOperationId").get<std::string>();
  const bool merge = parameters.value("merge", false);

  // The mirror `plane` is normally a face-kinded topology ref resolved on-kernel —
  // the registry is required exactly as fillet-v2's `edges` / shell's
  // `openFaces`. World planes are the one deliberate exception: they are
  // document-level reference geometry, not topology owned by a body, so route
  // them through the same explicit world-plane table used by sketch planes
  // instead of asking the selector evaluator to synthesize a fake face.
  if (registry == nullptr)
    throw std::invalid_argument(
        "unsupported operation: mirror requires the naming registry; evaluate with a "
        "registry-threaded replay state");
  const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
  const nlohmann::json& planeRef = parameters.at("plane");
  std::optional<gp_Pln> worldPlane;
  if (planeRef.contains("ast")) {
    const nlohmann::json& ast = planeRef.at("ast");
    const auto scope = ast.find("scope");
    const auto filters = ast.find("filters");
    if (scope != ast.end() && scope->is_array() && scope->size() == 1 && filters != ast.end() &&
        filters->is_array() && filters->empty() && scope->front().is_object() &&
        scope->front().value("source", std::string()) == "world") {
      gp_Ax2 axes;
      if (!WorldPlaneAxes(scope->front().value("world", std::string()), axes))
        throw OperationFailure(operationId, "INVALID_REQUEST",
                               "The mirror plane names an unknown world plane.",
                               {{"mirrorCode", "E_MIRROR_PLANE_INVALID"}});
      worldPlane = gp_Pln(axes.Location(), axes.Direction());
    }
  }

  const gp_Pln plane = worldPlane.has_value() ? *worldPlane : [&]() {
    const RefResolution resolution = ResolveRefSlotStrict(operationId, "mirror", "plane", planeRef,
                                                          peeked, *registry, cancelled);
    const QueryEntity planeEntity = SingleResolvedEntity("mirror", "plane", 'f', resolution);
    const BRepAdaptor_Surface surface(TopoDS::Face(planeEntity.shape), true);
    if (surface.GetType() != GeomAbs_Plane) {
      throw OperationFailure(operationId, "INVALID_REQUEST",
                             "The mirror needs a flat face or plane — the one picked is "
                             "curved.",
                             {{"mirrorCode", "E_MIRROR_PLANE_INVALID"}});
    }
    return surface.Plane();
  }();
  gp_Trsf mirrorTrsf;
  mirrorTrsf.SetMirror(gp_Ax2(plane.Location(), plane.Axis().Direction()));

  // Obtain the source shape. merge:false is a READ (source stays live, doc 04 —
  // the first non-consuming body reference in the catalog); merge:true CONSUMES
  // the source exactly like transform.
  TopoDS_Shape source;
  if (merge) {
    source = pool.Consume(operationId, "mirror", "source", sourceOperationId);
  } else {
    const EvaluatedBody* found = nullptr;
    for (const EvaluatedBody& body : peeked) {
      if (body.operationId == sourceOperationId) {
        found = &body;
        break;
      }
    }
    if (found == nullptr)
      throw ReferenceMissing(operationId,
                             "mirror source references operation " + sourceOperationId +
                                 ", which is not an unconsumed body-producing operation earlier in "
                                 "the document");
    source = found->shape;
  }
  CheckCancellation(cancelled);

  BRepBuilderAPI_Transform mirrorMaker(source, mirrorTrsf, /*Copy=*/true);
  if (!mirrorMaker.IsDone())
    throw Standard_Failure("mirror reflection failed");
  const TopoDS_Shape mirroredRaw = mirrorMaker.Shape();
  if (mirroredRaw.IsNull() || mirroredRaw.ShapeType() != TopAbs_SOLID)
    throw Standard_Failure("mirror did not produce a single solid body");
  // Mandatory orientation repair (doc 04 kernel mapping step 3): a reflection
  // flips orientation, leaving the solid inside-out.
  TopoDS_Solid mirrored = TopoDS::Solid(mirroredRaw);
  BRepLib::OrientClosedSolid(mirrored);

  if (!merge) {
    // A NEW independent body from the reflected copy (the source stays live).
    EvaluatedBody body = FinishSolidBody(operation, mirrored, "mirror result");
    if (elementNames != nullptr) {
      // The copy is a fresh body: root every sub-shape at the mirror op, then
      // (under a registry) mint `mirrored*` records with the reflected source
      // token as an ancestor (correspondence via provenance, not ordinal).
      elementNames->AddPrimitive(operationId, body.shape);
      if (registry != nullptr) {
        const ShapeToShapeMap copyToSource = CopyToSourceMap(mirrorMaker, source);
        registry->HarvestCopiedBody(operationId, body.shape, "mirrored", "mirrored-edge",
                                    "mirrored-vertex", copyToSource, cancelled);
      }
    }
    return body;
  }

  // merge:true — fuse the reflected copy into the source (doc 04 kernel mapping
  // step 4): one internal boolean, no unify (the boolean_combine convention).
  BRepAlgoAPI_Fuse fuse;
  NCollection_List<TopoDS_Shape> objects;
  objects.Append(source);
  NCollection_List<TopoDS_Shape> tools;
  tools.Append(mirrored);
  fuse.SetArguments(objects);
  fuse.SetTools(tools);
  fuse.SetRunParallel(false);
  fuse.SetToFillHistory(elementNames != nullptr);
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    fuse.Build(progress->Start());
  }
  CheckCancellation(cancelled);
  if (fuse.HasErrors())
    throw Standard_Failure("mirror merge fuse failed");
  const TopoDS_Shape fused = fuse.Shape();
  if (fused.IsNull())
    throw Standard_Failure("mirror merge produced no result shape");
  const int solidCount = Count(fused, TopAbs_SOLID);
  if (solidCount != 1)
    throw Standard_Failure(("mirror merge produced " + std::to_string(solidCount) +
                            " disjoint solids; a merged mirror must be a single connected solid")
                               .c_str());
  const TopExp_Explorer solids(fused, TopAbs_SOLID);
  EvaluatedBody body = FinishSolidBody(operation, TopoDS::Solid(solids.Current()), "mirror result");
  if (elementNames != nullptr) {
    // The reflected copy is a SYNTHETIC operand (the hole/shell tool route):
    // AddPrimitive-rooted at the mirror op, then named + harvested through the
    // fuse's real history. Its survivors re-mint `mirrored*`, the source's
    // untouched faces identity-survive `modified`, join curves are `seam`.
    const occ::handle<BRepTools_History> history = fuse.History();
    if (history.IsNull())
      throw Standard_Failure("mirror merge did not record algorithm history");
    elementNames->AddPrimitive(operationId, mirrored);
    elementNames->ApplyOperation(operationId, {source, mirrored}, body.shape, *history, cancelled);
    if (registry != nullptr) {
      registry->HarvestSyntheticTool(operationId, mirrored, cancelled);
      registry->HarvestOperation(operationId, NamingRegistry::OperationClass::Mirror,
                                 {{source, false, false}, {mirrored, true, true}}, body.shape,
                                 *history, cancelled);
    }
  }
  return body;
}

// The shared pattern core: instances the seed under a supplied per-instance
// transform list, combines them in ONE n-ary boolean per `op`, and harvests
// names/records. `transforms` is in canonical instance order (instanceIndex),
// so the instance compound's AddPrimitive ordinals are prefix-stable in that
// order — the ADR-006-compatible expression of doc 04's `m·P + k`.
EvaluatedBody EvaluatePatternCore(const nlohmann::json& operation, BodyPool& pool,
                                  ElementNameBook* elementNames, NamingRegistry* registry,
                                  const std::vector<gp_Trsf>& transforms,
                                  const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string seedOperationId = parameters.at("seedOperationId").get<std::string>();
  const std::string combine = parameters.value("op", std::string("fuseInstances"));
  const bool consumeSeed = parameters.value("consumeSeed", true);
  const bool hasTarget = combine == "union" || combine == "subtract";
  if (combine != "fuseInstances" && combine != "union" && combine != "subtract")
    throw std::invalid_argument("unsupported pattern op: " + combine);
  if (transforms.empty())
    throw std::invalid_argument("pattern requires at least one instance");

  // Read the seed BEFORE consuming so the instance transforms see it, then
  // consume the operands (target for union/subtract; seed unless kept).
  const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
  const EvaluatedBody* seedBody = nullptr;
  for (const EvaluatedBody& body : peeked) {
    if (body.operationId == seedOperationId) {
      seedBody = &body;
      break;
    }
  }
  if (seedBody == nullptr)
    throw ReferenceMissing(operationId,
                           "pattern seed references operation " + seedOperationId +
                               ", which is not an unconsumed body-producing operation earlier in "
                               "the document");
  const TopoDS_Shape seed = seedBody->shape;

  TopoDS_Shape target;
  if (hasTarget) {
    target = pool.Consume(operationId, "pattern", "target",
                          parameters.at("targetOperationId").get<std::string>());
  }
  if (consumeSeed)
    pool.Consume(operationId, "pattern", "seed", seedOperationId);

  // Instance the seed. Instance 0 is the identity transform, still copied
  // (doc 04 kernel mapping step 1).
  BRep_Builder builder;
  TopoDS_Compound instanceCompound;
  builder.MakeCompound(instanceCompound);
  std::vector<TopoDS_Shape> instances;
  instances.reserve(transforms.size());
  for (const gp_Trsf& trsf : transforms) {
    CheckCancellation(cancelled);
    BRepBuilderAPI_Transform maker(seed, trsf, /*Copy=*/true);
    if (!maker.IsDone())
      throw Standard_Failure("pattern instance transform failed");
    const TopoDS_Shape instance = maker.Shape();
    if (instance.IsNull() || instance.ShapeType() != TopAbs_SOLID)
      throw Standard_Failure("pattern instance did not produce a solid");
    instances.push_back(instance);
    builder.Add(instanceCompound, instance);
  }

  const bool naming = elementNames != nullptr;
  const bool loneInstance = !hasTarget && instances.size() == 1;

  const auto failMerge = [&](const std::string& message) -> void {
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message,
                           {{"patternCode", "E_PATTERN_MERGE_FAILED"}});
  };

  TopoDS_Shape resultShape;
  occ::handle<BRepTools_History> history;
  std::vector<TopoDS_Shape> namingInputs;

  if (loneInstance) {
    // W_PATTERN_COUNT_ONE degenerate: a single copy of the seed, no boolean.
    resultShape = instances.front();
  } else {
    std::unique_ptr<BRepAlgoAPI_BooleanOperation> algorithm;
    NCollection_List<TopoDS_Shape> objects;
    NCollection_List<TopoDS_Shape> tools;
    if (!hasTarget) {
      // fuseInstances: fuse instance 0 with instances 1..n-1.
      algorithm = std::make_unique<BRepAlgoAPI_Fuse>();
      objects.Append(instances.front());
      for (std::size_t index = 1; index < instances.size(); ++index)
        tools.Append(instances[index]);
      for (const TopoDS_Shape& instance : instances)
        namingInputs.push_back(instance);
    } else {
      // union/subtract: all instances against the target in one n-ary boolean.
      if (combine == "union")
        algorithm = std::make_unique<BRepAlgoAPI_Fuse>();
      else
        algorithm = std::make_unique<BRepAlgoAPI_Cut>();
      objects.Append(target);
      for (const TopoDS_Shape& instance : instances)
        tools.Append(instance);
      namingInputs.push_back(target);
      for (const TopoDS_Shape& instance : instances)
        namingInputs.push_back(instance);
    }
    algorithm->SetArguments(objects);
    algorithm->SetTools(tools);
    // Determinism over speed (replay integrity), no unify (per the header note).
    algorithm->SetRunParallel(false);
    algorithm->SetFuzzyValue(1.0e-5);
    algorithm->SetNonDestructive(true);
    algorithm->SetToFillHistory(naming);
    {
      const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
      algorithm->Build(progress->Start());
    }
    CheckCancellation(cancelled);
    if (algorithm->HasErrors())
      failMerge("the pattern instances could not be merged");
    resultShape = algorithm->Shape();
    if (resultShape.IsNull())
      failMerge("the pattern boolean produced no result shape");
    if (naming) {
      history = algorithm->History();
      if (history.IsNull())
        throw Standard_Failure("pattern boolean did not record algorithm history");
    }
  }

  // Boolean patterns with an explicit target retain the one-connected-solid
  // contract. A normal fuseInstances pattern is different: disjoint instances
  // are the normal result of a spacing pattern and must remain one semantic
  // operation body containing all of its solids.
  const int solidCount = Count(resultShape, TopAbs_SOLID);
  if (solidCount == 0)
    failMerge("the pattern produced an empty result (the boolean removed all material)");
  if (solidCount > 1 && hasTarget)
    failMerge("the pattern produced " + std::to_string(solidCount) +
              " disjoint solids; a pattern output must be a single connected solid in v1");
  EvaluatedBody body = FinishBodyShape(operation, resultShape, "pattern result");

  if (naming) {
    if (loneInstance) {
      // The lone copy is a fresh body (like mirror merge:false), instance roles.
      elementNames->AddPrimitive(operationId, body.shape);
      if (registry != nullptr) {
        const ShapeToShapeMap empty;
        registry->HarvestCopiedBody(operationId, body.shape, "instance-face", "instance-edge",
                                    "instance-vertex", empty, cancelled);
      }
    } else {
      // The instance set is a SYNTHETIC operand compound (the hole/shell tool
      // route): AddPrimitive-rooted with prefix-stable per-instance ordinals,
      // then named + harvested through the real boolean history.
      elementNames->AddPrimitive(operationId, instanceCompound);
      elementNames->ApplyOperation(operationId, namingInputs, body.shape, *history, cancelled);
      if (registry != nullptr) {
        registry->HarvestSyntheticTool(operationId, instanceCompound, cancelled);
        std::vector<NamingRegistry::Input> inputs;
        if (hasTarget)
          inputs.push_back({target, false, false});
        for (const TopoDS_Shape& instance : instances)
          inputs.push_back({instance, true, true});
        // A consumed seed is inert to the boolean (the instances are copies), so
        // it is fed in only to retire its now-stale records (§6.3 step 13).
        if (consumeSeed)
          inputs.push_back({seed, false, false});
        registry->HarvestOperation(operationId, NamingRegistry::OperationClass::Pattern, inputs,
                                   body.shape, *history, cancelled);
      }
    }
  }
  return body;
}

// Normalizes a wire direction vector at the kernel trust boundary (the schema
// leaves normalization to the kernel).
gp_Dir PatternDirection(const nlohmann::json& value, const char* label) {
  const gp_Vec vector = JsonVector(value);
  if (vector.Magnitude() < 1e-9)
    throw std::invalid_argument(std::string("pattern ") + label + " must be non-zero");
  return gp_Dir(vector);
}

EvaluatedBody EvaluatePatternLinear(const nlohmann::json& operation, BodyPool& pool,
                                    ElementNameBook* elementNames, NamingRegistry* registry,
                                    const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const int count = parameters.at("count").get<int>();
  const int count2 = parameters.value("count2", 1);
  const double spacing = parameters.at("spacing").get<double>();
  if (count < 1 || count2 < 1)
    throw std::invalid_argument("pattern counts must be at least 1");
  if (static_cast<long long>(count) * count2 > 1024)
    throw std::invalid_argument("pattern instance count exceeds the 1024 budget");
  const gp_Dir direction = PatternDirection(parameters.at("direction"), "direction");

  gp_Dir direction2(1.0, 0.0, 0.0);
  double spacing2 = 0.0;
  if (count2 > 1) {
    if (!parameters.contains("spacing2") || !parameters.contains("direction2"))
      throw std::invalid_argument("a 2D pattern requires spacing2 and direction2");
    spacing2 = parameters.at("spacing2").get<double>();
    direction2 = PatternDirection(parameters.at("direction2"), "direction2");
    // Doc 04 rule 2 (sign-insensitive): the two axes must differ by >= 1 degree.
    constexpr double kCosOneDegree = 0.9998476951563913;
    if (std::abs(direction.Dot(direction2)) > kCosOneDegree)
      throw OperationFailure(operation.at("id").get<std::string>(), "INVALID_REQUEST",
                             "The two pattern directions point the same way — pick directions at "
                             "an angle to each other.",
                             {{"patternCode", "E_PATTERN_DEGENERATE_AXES"}});
  }

  // instanceIndex = j*count + i (first direction varies fastest), instance 0 the
  // unmoved copy (doc 04). Emit transforms in that canonical order.
  std::vector<gp_Trsf> transforms;
  transforms.reserve(static_cast<std::size_t>(count) * static_cast<std::size_t>(count2));
  for (int j = 0; j < count2; ++j) {
    for (int i = 0; i < count; ++i) {
      const gp_Vec offset = gp_Vec(direction) * (i * spacing) + gp_Vec(direction2) * (j * spacing2);
      gp_Trsf trsf;
      trsf.SetTranslation(offset);
      transforms.push_back(trsf);
    }
  }
  return EvaluatePatternCore(operation, pool, elementNames, registry, transforms, cancelled);
}

EvaluatedBody EvaluatePatternCircular(const nlohmann::json& operation, BodyPool& pool,
                                      ElementNameBook* elementNames, NamingRegistry* registry,
                                      const std::atomic_bool& cancelled) {
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const int count = parameters.at("count").get<int>();
  if (count < 2)
    throw std::invalid_argument("pattern_circular count must be at least 2");
  if (count > 1024)
    throw std::invalid_argument("pattern instance count exceeds the 1024 budget");
  const double totalAngle = parameters.value("totalAngle", 360.0);
  if (!(totalAngle > 0.0 && totalAngle <= 360.0))
    throw std::invalid_argument("pattern_circular totalAngle must lie in (0, 360]");
  const bool rotateInstances = parameters.value("rotateInstances", true);

  // The `axis` is an edge-kinded topology ref resolved on-kernel — the registry
  // is required (fillet-v2 / shell precedent).
  if (registry == nullptr)
    throw std::invalid_argument(
        "unsupported operation: pattern_circular requires the naming registry; evaluate with a "
        "registry-threaded replay state");
  const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
  const RefResolution resolution = ResolveRefSlotStrict(
      operationId, "pattern_circular", "axis", parameters.at("axis"), peeked, *registry, cancelled);
  const QueryEntity axisEntity = SingleResolvedEntity("pattern_circular", "axis", 'e', resolution);
  const TopoDS_Edge axisEdge = TopoDS::Edge(axisEntity.shape);
  const BRepAdaptor_Curve axisCurve(axisEdge);
  if (axisCurve.GetType() != GeomAbs_Line) {
    // Doc 04 rule 3: resolve-time E_PATTERN_AXIS_INVALID (fine code in details).
    throw OperationFailure(
        operationId, "INVALID_REQUEST",
        "The pattern needs a straight edge or axis to revolve around — the one picked is curved.",
        {{"patternCode", "E_PATTERN_AXIS_INVALID"}});
  }
  const gp_Ax1 axis = axisCurve.Line().Position();

  // Fencepost (doc 04, normative): full circle divides by count (no doubled
  // instance at 0 = 360); an open arc divides by count-1 (both endpoints).
  const bool fullCircle = totalAngle >= 360.0 - 1e-9;
  const double denominator =
      fullCircle ? static_cast<double>(count) : static_cast<double>(count - 1);
  constexpr double kDegreesToRadians = 0.017453292519943295;

  // rotateInstances:false is the translate-only orbit: the seed's volume
  // centroid orbits the axis, the instance is the seed translated by (c_k - c).
  gp_Pnt seedCentroid(0.0, 0.0, 0.0);
  if (!rotateInstances) {
    const EvaluatedBody* seedBody = nullptr;
    const std::string seedOperationId = parameters.at("seedOperationId").get<std::string>();
    for (const EvaluatedBody& body : peeked) {
      if (body.operationId == seedOperationId) {
        seedBody = &body;
        break;
      }
    }
    if (seedBody == nullptr)
      throw ReferenceMissing(operationId,
                             "pattern seed references operation " + seedOperationId +
                                 ", which is not an unconsumed body-producing operation earlier in "
                                 "the document");
    GProp_GProps properties;
    BRepGProp::VolumeProperties(seedBody->shape, properties);
    seedCentroid = properties.CentreOfMass();
  }

  std::vector<gp_Trsf> transforms;
  transforms.reserve(static_cast<std::size_t>(count));
  for (int k = 0; k < count; ++k) {
    const double angle = (k * totalAngle / denominator) * kDegreesToRadians;
    gp_Trsf trsf;
    if (rotateInstances) {
      trsf.SetRotation(axis, angle);
    } else {
      gp_Pnt orbited = seedCentroid;
      orbited.Rotate(axis, angle);
      trsf.SetTranslation(gp_Vec(seedCentroid, orbited));
    }
    transforms.push_back(trsf);
  }
  return EvaluatePatternCore(operation, pool, elementNames, registry, transforms, cancelled);
}

// Executes ONE operation into the running epoch state (the pool of bodies, the
// profile map, and — when naming is on — the element-name book / naming
// registry). This is exactly the per-op dispatch EvaluateOperations used to
// inline; extracting it lets the replay cache (DocumentEvaluator) drive the same
// path for a restored-prefix tail. Birth operations root every sub-shape at the
// producing op (tranche N0) and, under a registry, harvest per-epoch records
// (N3). The H4 attribution envelope re-throws unattributed geometry/argument
// failures as an OperationFailure carrying this op's id.
// `allOperations` is the full document operations array this `operation`
// belongs to — threaded through starting with the mold/tooling wave, whose
// `mold_parting_surface`/`mold_tooling_split` executors need to read a
// SIBLING operation's own authored parameter value (`mold_parting_line`'s
// `pullDirection`), not merely its evaluated body/geometry, something no
// earlier operation in this codebase needed (see
// mold_tooling_feature.hpp's own header comment on `EvaluateMoldPartingSurface`
// for the full account). Both of `ExecuteOperation`'s own call sites already
// have the complete array in scope under this exact name, so this is a
// minimal, local addition — every OTHER dispatch branch below simply
// ignores the parameter.
void ExecuteOperation(const nlohmann::json& operation, const nlohmann::json& allOperations,
                      BodyPool& pool, std::map<std::string, EvaluatedProfile>& profiles,
                      std::map<std::string, EvaluatedOpenPath>& openPaths, ElementNameBook* book,
                      NamingRegistry* namingRegistry, const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  const std::string type = operation.at("type").get<std::string>();
  const std::string operationId = operation.at("id").get<std::string>();
  const auto produceRoot = [&pool, &profiles, book, namingRegistry,
                            &cancelled](const nlohmann::json& op, const std::string& opType,
                                        EvaluatedBody body) {
    if (book != nullptr) {
      book->AddPrimitive(body.operationId, body.shape);
    }
    if (namingRegistry != nullptr) {
      if (opType == "create_box") {
        namingRegistry->HarvestBoxBirth(
            body.operationId, body.shape,
            PlacementFrame(op.at("parameters").at("placement")).Direction(), cancelled);
      } else if (opType == "import_step" || opType == "import_mesh") {
        // An import has no authored construction frame, so it takes the flat
        // per-kind import role table (CAP-011) rather than a semantic one: a
        // role like `top` or `wall` over read-back topology would be a GUESS,
        // which is exactly what the zero-silent-misreference law forbids.
        //
        // Enumeration is per-(operation, output body): a multi-solid import's
        // second solid must not mint the same tokens as its first, or a
        // reference to one would resolve to the other (ADR-013 decision 2).
        namingRegistry->HarvestImportedBody(body.operationId, body.outputIndex, body.shape,
                                            cancelled);
      } else {
        namingRegistry->HarvestBirth(body.operationId, body.shape,
                                     NamingBirthSpec(op, profiles, pool, namingRegistry, cancelled),
                                     cancelled);
      }
    }
    pool.Produce(std::move(body));
  };
  try {
    if (type == "create_box") {
      produceRoot(operation, type, EvaluateBox(operation, cancelled));
    } else if (type == "create_cylinder") {
      produceRoot(operation, type, EvaluateCylinder(operation, cancelled));
    } else if (type == "create_sphere") {
      produceRoot(operation, type, EvaluateSphere(operation, cancelled));
    } else if (type == "create_cone") {
      produceRoot(operation, type, EvaluateCone(operation, cancelled));
    } else if (type == "create_torus") {
      produceRoot(operation, type, EvaluateTorus(operation, cancelled));
    } else if (type == "create_wedge") {
      produceRoot(operation, type, EvaluateWedge(operation, cancelled));
    } else if (type == "sketch") {
      // A sketch produces NO body. It produces a PROFILE when its boundary
      // entities close a region (CAP-038) — under its own operation id, in the
      // same map `create_profile` writes to, which is what lets extrude,
      // revolve, sweep and loft consume it without knowing it is a sketch. A
      // sketch that encloses nothing is a guide and adds nothing; a sketch
      // whose boundary does not CLOSE refuses by name rather than quietly
      // becoming a missing reference at whatever consumes it.
      //
      // The other work a sketch requires on evaluation — re-solving the stored
      // system and asserting it reproduces the stored solution byte-for-byte
      // (the ADR-016 determinism contract) — happens at the request boundary in
      // server.cpp, BEFORE any geometry runs. It lives there because the
      // solver's engine is a 13k-LOC vendored library and geometry.cpp is
      // compiled into twelve targets that have no business linking it. A
      // divergent document therefore fails before producing a single body.
      const std::vector<EvaluatedBody> sketchBodies = pool.PeekVisibleBodies();
      RegisterSketchConstructionEdges(operation, sketchBodies, namingRegistry, cancelled);
      RegisterSketchBoundaryEdges(operation, sketchBodies, namingRegistry, cancelled);
      std::optional<EvaluatedProfile> region =
          EvaluateSketchRegion(operation, sketchBodies, namingRegistry, cancelled);
      if (region.has_value()) {
        profiles.insert_or_assign(operation.at("id").get<std::string>(), std::move(*region));
      } else {
        // No enclosed region. A single connected open path is still useful —
        // Thin Extrude can run a wall along it. It goes in its own map so no
        // consumer that requires real faces can ever be handed one.
        std::optional<EvaluatedOpenPath> path =
            EvaluateSketchOpenPath(operation, sketchBodies, namingRegistry, cancelled);
        if (path.has_value())
          openPaths.insert_or_assign(operation.at("id").get<std::string>(), std::move(*path));
      }
    } else if (type == "create_profile") {
      profiles.insert_or_assign(operation.at("id").get<std::string>(),
                                EvaluateProfile(operation, cancelled));
    } else if (type == "extrude") {
      // Extrude owns its naming because v2 resolves face-profile and to-face
      // construction planes inside the evaluator, and boolean modes retain
      // their OCCT mutation history there. Reconstructing either after return
      // loses information and misclassifies a target-consuming result as a
      // root birth.
      pool.Produce(
          EvaluateExtrude(operation, profiles, openPaths, pool, book, namingRegistry, cancelled));
    } else if (type == "base_flange") {
      // Sheet-metal wave: the first sheet-metal body, a root birth from a
      // profile exactly like extrude (see EvaluateBaseFlange's own comment).
      produceRoot(operation, type, EvaluateBaseFlange(operation, profiles, cancelled));
    } else if (type == "revolve") {
      if (operation.value("schemaVersion", 1) >= 2) {
        pool.Produce(EvaluateRevolveV2(operation, profiles, openPaths, pool, book, namingRegistry,
                                       cancelled));
      } else {
        produceRoot(operation, type, EvaluateRevolveV1(operation, profiles, cancelled));
      }
    } else if (type == "loft") {
      if (operation.value("schemaVersion", 1) >= 2) {
        if (operation.at("parameters")
                .value("boolean", nlohmann::json{{"mode", "newBody"}})
                .value("mode", "newBody") != "newBody") {
          pool.Produce(
              EvaluateLoftBoolean(operation, profiles, pool, book, namingRegistry, cancelled));
        } else {
          produceRoot(operation, type,
                      EvaluateLoftV2(operation, profiles, pool, namingRegistry, cancelled));
        }
      } else {
        produceRoot(operation, type, EvaluateLoft(operation, profiles, cancelled));
      }
    } else if (type == "sweep") {
      if (operation.value("schemaVersion", 1) >= 2 &&
          operation.at("parameters").at("boolean").value("mode", "newBody") != "newBody") {
        pool.Produce(EvaluateAssociativeSweepBoolean(operation, profiles, pool, book,
                                                     namingRegistry, cancelled));
      } else {
        produceRoot(operation, type,
                    EvaluateSweep(operation, profiles, pool, namingRegistry, cancelled));
      }
    } else if (type == "boolean_combine") {
      pool.Produce(EvaluateBooleanCombine(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "hole") {
      pool.Produce(EvaluateHole(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "transform") {
      pool.Produce(EvaluateTransform(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "offset") {
      pool.Produce(EvaluateOffset(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "fillet") {
      pool.Produce(EvaluateFillet(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "chamfer") {
      pool.Produce(EvaluateChamfer(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "datum_plane") {
      // Catalog wave 1 (docs/design/2026-07-19-native-catalog-wave1.md):
      // datum ops produce NO body and no profile — their sole product is the
      // synthetic registry entity. Without a registry they refuse fail-closed
      // inside the executor (the fillet-v2 registry-guard precedent), so the
      // replay-cache path never reaches state it cannot snapshot.
      EvaluateDatumPlane(operation, pool, namingRegistry, cancelled);
    } else if (type == "datum_axis") {
      EvaluateDatumAxis(operation, pool, namingRegistry, cancelled);
    } else if (type == "shell") {
      pool.Produce(EvaluateShell(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "mirror") {
      // Catalog wave 2 (plan 04 `mirror`): merge:false produces a NEW body from
      // the reflected copy while the source stays live; merge:true fuses the
      // copy into the (consumed) source. Its `plane` ref requires the registry.
      pool.Produce(EvaluateMirror(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "pattern_linear") {
      // Catalog wave 2 (plan 04 `pattern-linear`): a 1D/2D grid of instances
      // combined in one n-ary boolean. No ref slot, so it rides the bare-book
      // path too (registry only when another op in the document forces one).
      pool.Produce(EvaluatePatternLinear(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "pattern_circular") {
      // Catalog wave 2 (plan 04 `pattern-circular`): instances around the
      // resolved axis edge. Its `axis` ref requires the registry.
      pool.Produce(EvaluatePatternCircular(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "import_step") {
      // A root body-birth from retained STEP bytes, named through the SAME
      // produceRoot path as the primitives (CAP-011). Its identity rests on the
      // proven property that identical Part-21 bytes read back to identical
      // topology (the step-reimport oracle in mutation.cpp), so the birth
      // ordinals a deterministic reader assigns agree across replays.
      // A multi-solid import fans out to the ordered body set the operation
      // declared (ADR-013); a single-solid one yields exactly one body, as it
      // always did.
      for (EvaluatedBody& born : EvaluateImportStepBodies(operation, cancelled)) {
        produceRoot(operation, type, std::move(born));
      }
    } else if (type == "import_mesh") {
      // Same, from the retained checked aeth-mesh-v1 surface: the payload is
      // sha256-verified before the rebuild, so the sewn topology — and with it
      // the birth ordinals — is a deterministic function of the retained bytes.
      produceRoot(operation, type, EvaluateImportMesh(operation, cancelled));
    } else if (type == "edge_flange") {
      // Sheet-metal wave: grows a new flat panel + bend from a picked edge of
      // an existing sheet-metal body. CONSUMES its target, the same taxonomy
      // as fillet/shell/chamfer.
      pool.Produce(EvaluateEdgeFlange(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "unfold") {
      // Sheet-metal wave: CONSUMES the folded body, births TWO bodies from one
      // operation (ADR-013's multi-output-birth mechanism, the same one
      // import_step's fan-out uses) — the folded pass-through (outputIndex 0,
      // `outputBodyId`) and the flat pattern (outputIndex 1,
      // `outputBodyIds[1]`). Produced flat-THEN-folded (reverse of birth-index
      // order) so BodyPool's last-write-wins operationId->index map resolves a
      // plain downstream `targetOperationId: <this op>` to the FOLDED body —
      // matching the documented intent that "further features keep building
      // on the 3D form." This is a deliberate ordering choice within
      // BodyPool's existing single-index-per-operation-id contract, not a
      // BodyPool change: the flat body remains fully visible (unconsumed) in
      // the final result either way, and only a plain-operationId Consume of
      // an operation with more than one born body is sensitive to it (a body-
      // id-scoped reference is unaffected, since Consume only ever takes an
      // operationId in this codebase today).
      std::vector<EvaluatedBody> born =
          EvaluateUnfoldBodies(operation, pool, book, namingRegistry, cancelled);
      if (born.size() != 2)
        throw std::runtime_error("unfold must produce exactly two born bodies (folded, flat)");
      pool.Produce(std::move(born[1]));
      pool.Produce(std::move(born[0]));
    } else if (type == "boundary_surface") {
      // Surfacing wave: fills a target body's entire open boundary into one
      // new face. Reads (never consumes) its target, the mirror/datum_plane
      // non-consuming taxonomy.
      pool.Produce(EvaluateBoundarySurface(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "surface_offset") {
      // Surfacing wave: offsets an existing OPEN surface body along its
      // normal. CONSUMES its target, the boolean_combine/hole/offset taxonomy.
      pool.Produce(EvaluateSurfaceOffset(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "stitch") {
      // Surfacing wave: sews exactly two bodies together within a tolerance.
      // CONSUMES both, the boolean_combine taxonomy.
      pool.Produce(EvaluateStitch(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "thicken") {
      // Surfacing wave: extrudes an open surface into a solid along its own
      // normal. CONSUMES its target, the fillet/shell taxonomy.
      pool.Produce(EvaluateThicken(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "wire_route") {
      // Electrical wave 1: routes a physical wire/cable as a thin solid pipe
      // through startVertex -> waypoints -> endVertex, subject to a minimum
      // bend radius measured against the built curve's own curvature. Reads
      // (never consumes) the two referenced vertex-owning bodies, the
      // mirror/datum/boundary_surface non-consuming taxonomy.
      pool.Produce(EvaluateWireRoute(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "mold_parting_line") {
      // Mold/tooling wave: finds the sign-changing edge loop separating
      // positive- from negative-draft faces along pullDirection and mints
      // it as a new WIRE body. Reads (never consumes) its target, the
      // mirror/datum/boundary_surface/wire_route non-consuming taxonomy.
      pool.Produce(EvaluateMoldPartingLine(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "mold_shutoff_surface") {
      // Mold/tooling wave: caps every free-boundary loop of the target
      // EXCEPT the referenced parting line's own loop into one new surface
      // body. Reads (never consumes) both references.
      pool.Produce(EvaluateMoldShutoffSurface(operation, pool, book, namingRegistry, cancelled));
    } else if (type == "mold_parting_surface") {
      // Mold/tooling wave: sweeps the parting-line wire along ITS OWN
      // authored pullDirection (read back from that sibling operation's own
      // JSON — see EvaluateMoldPartingSurface's own comment for why this op
      // alone needs the full operations array) into one new shell. Reads
      // (never consumes) its references.
      pool.Produce(EvaluateMoldPartingSurface(operation, allOperations, pool, book, namingRegistry,
                                              cancelled));
    } else if (type == "mold_tooling_split") {
      // Mold/tooling wave: cuts a tooling block with the (optionally
      // shut-off-capped) part, then splits the remainder with the parting
      // surface plus any insert tools — births 2..N solid bodies from one
      // operation (a THIRD multi-output-birth shape: always-present AND
      // variable-length; see EvaluateMoldToolingSplit's own comment).
      // Produced insert-then-cavity-then-core (reverse array order) so
      // BodyPool's last-write-wins operationId->index map resolves a plain
      // downstream `targetOperationId: <this op>` reference to CORE —
      // matching outputBodyId's own documented identity (outputBodyId ==
      // outputBodyIds[0] == core), the exact `unfold` precedent (flat-THEN-
      // folded) applied to this operation's own first-array-position
      // instead of unfold's fixed pair.
      std::vector<EvaluatedBody> born =
          EvaluateMoldToolingSplit(operation, allOperations, pool, book, namingRegistry, cancelled);
      if (born.size() < 2) {
        throw std::runtime_error(
            "mold_tooling_split must produce at least two born bodies (core, cavity)");
      }
      for (std::size_t index = born.size(); index-- > 1;)
        pool.Produce(std::move(born[index]));
      pool.Produce(std::move(born[0]));
    } else {
      throw std::invalid_argument("unsupported operation: " + type);
    }
  } catch (const Cancelled&) {
    throw;
  } catch (const ReferenceMissing&) {
    throw;
  } catch (const SelectorFailure&) {
    // Already carries this op's id, the wire code, and the §8.1 details payload —
    // pass through so the server maps it with attribution intact.
    throw;
  } catch (const OperationFailure&) {
    throw;
  } catch (const Standard_Failure& error) {
    throw OperationFailure(operationId, "GEOMETRY_FAILED", error.what());
  } catch (const std::invalid_argument& error) {
    const std::string message = error.what();
    throw OperationFailure(operationId,
                           message.starts_with("unsupported operation") ? "UNSUPPORTED_OPERATION"
                                                                        : "INVALID_REQUEST",
                           message);
  } catch (const std::runtime_error& error) {
    // Registry/lineage invariant failures happen inside this operation's
    // production envelope. Preserve their internal taxonomy while always
    // attributing the failure to the operation that triggered it.
    throw OperationFailure(operationId, "INTERNAL_ERROR", error.what());
  }
}

// A ref slot is the canonical operationRefSchema/WireSchema shape (a resolution
// policy `arity` + `onEmpty` plus a selector — the persisted `query` string or
// the lowered wire `ast`). This mirrors operation_hash.cpp's IsRefSlot / the TS
// `isRefSlot` twin; the check is by shape so it catches every selector-bearing
// slot regardless of the parameter name that carries it.
bool JsonIsRefSlot(const nlohmann::json& value) {
  return value.is_object() && value.contains("arity") && value.contains("onEmpty") &&
         (value.contains("ast") || value.contains("query"));
}

// True if `value` is, or transitively contains, a ref slot. Documents are small
// and the recursion is bounded by their JSON depth.
bool ContainsRefSlot(const nlohmann::json& value) {
  if (JsonIsRefSlot(value))
    return true;
  if (value.is_object()) {
    for (const auto& entry : value.items())
      if (ContainsRefSlot(entry.value()))
        return true;
  } else if (value.is_array()) {
    for (const nlohmann::json& element : value)
      if (ContainsRefSlot(element))
        return true;
  }
  return false;
}

// Whether this document must evaluate under an epoch-local NamingRegistry: true
// iff any operation carries a selector ref slot (fillet `edges`, shell
// `openFaces`, a datum reference). Only these operations resolve a selector
// on-kernel (N4/N5), and only resolution needs the registry — so a document of
// plain primitives/booleans/offset/imports keeps evaluating on the byte-
// identical bare-book path, leaving the offset/import naming-fail-closed guards
// and the differential-replay corpus untouched (N6 slice C).
bool DocumentRequiresNamingRegistry(const nlohmann::json& operations) {
  if (!operations.is_array())
    return false;
  for (const nlohmann::json& operation : operations) {
    if (!operation.is_object())
      continue;
    const auto parameters = operation.find("parameters");
    if (parameters != operation.end() && ContainsRefSlot(*parameters))
      return true;
  }
  return false;
}

// The resumable epoch state a replay-cache entry captures: the body pool, the
// profile map, and — when a name channel is engaged — the owned name book. All
// three components carry a value snapshot seam (tranche 2.1), so the bundle's
// snapshot is their composition; restoring it reproduces the exact state after
// the snapshotted operation prefix.
//
// The name channel is at most ONE of two, never both:
//   - `book` alone: the tranche-N0 bare-book path, engaged for
//     `includeElementNames` on a document with NO selector ref. Byte-identical
//     to the pre-registry evaluator — the differential-replay corpus and the
//     offset/import naming-fail-closed paths ride this branch unchanged.
//   - `registry` (which OWNS its book): engaged ONLY for a document carrying a
//     selector ref slot, so ExecuteOperation can resolve it on-kernel (N6 slice
//     C). The registry's book doubles as the name book, so element naming still
//     works alongside selector resolution.
//
// The snapshot captures ONLY the live book, never the registry's records: a
// restored prefix deliberately carries no registry state (a later "registry in
// the snapshot" tranche owns that), so DocumentEvaluator::Evaluate hands the
// re-executed tail a null registry and a tail selector op fails closed.
struct EvaluationState final {
  BodyPool pool;
  std::map<std::string, EvaluatedProfile> profiles;
  std::map<std::string, EvaluatedOpenPath> openPaths;
  std::optional<ElementNameBook> book;
  std::optional<NamingRegistry> registry;

  ElementNameBook* NamingBook() {
    if (registry.has_value())
      return &registry->Book();
    return book.has_value() ? &*book : nullptr;
  }
  NamingRegistry* Registry() { return registry.has_value() ? &*registry : nullptr; }

  struct Snapshot final {
    BodyPool::Snapshot pool;
    std::map<std::string, EvaluatedProfile> profiles;
    std::map<std::string, EvaluatedOpenPath> openPaths;
    std::optional<ElementNameBook::Snapshot> book;
  };

  Snapshot TakeSnapshot() const {
    const ElementNameBook* const liveBook =
        registry.has_value() ? &registry->Book() : (book.has_value() ? &*book : nullptr);
    return Snapshot{pool.TakeSnapshot(), profiles, openPaths,
                    liveBook != nullptr
                        ? std::optional<ElementNameBook::Snapshot>(liveBook->TakeSnapshot())
                        : std::nullopt};
  }

  void RestoreFrom(const Snapshot& snapshot) {
    pool.RestoreFrom(snapshot.pool);
    profiles = snapshot.profiles;
    openPaths = snapshot.openPaths;
    // Restore only the live book, never registry records (see above). Whichever
    // channel is engaged owns the restored book; a registry keeps its records
    // empty so the re-executed tail cannot resolve a selector against a restored
    // prefix name.
    if (snapshot.book.has_value()) {
      if (registry.has_value())
        registry->Book().RestoreFrom(*snapshot.book);
      else {
        if (!book.has_value())
          book.emplace();
        book->RestoreFrom(*snapshot.book);
      }
    } else if (!registry.has_value()) {
      book.reset();
    }
  }
};

// Approximate retained bytes of a cached snapshot for the byte-bounded governor
// (Wave 2.1 slice 3a; plan 06 §9 `cacheRamMb`). Plan §8.4 estimates a shape's
// bytes from a BinTools serialization; that is neither linked here nor free —
// serializing on every Put would tax the exact interactive edit loop this cache
// exists to speed up (§8.4 is written for the L2 DISK tier, where the bytes are
// being written anyway). The L1 RAM estimator instead reuses data already
// computed during evaluation: each body's `probes` carry per-kind sub-shape
// counts, so a body's geometry weight costs ZERO extra OCCT traversal.
//
// The constants below are conservative calibration knobs (a measured memory
// suite refines them, §8.4). The estimate deliberately OVER-counts shared OCCT
// geometry — one TShape referenced by several snapshots is billed to each — so
// the governor evicts sooner than true RSS would demand, never later. That is
// fail-safe for a memory bound. `kEntryOverhead` also caps entry count: an
// empty-prefix snapshot still costs it, so the byte budget alone bounds how many
// entries the map can hold (no separate entry cap needed).
constexpr std::size_t kEntryOverhead = 512;     // map/vector headers per snapshot
constexpr std::size_t kBodyOverhead = 128;      // EvaluatedBody + ShapeProbes
constexpr std::size_t kBytesPerSubShape = 1024; // OCCT per-sub-shape in-memory weight
constexpr std::size_t kMapNodeOverhead = 48;    // per std::map / DataMap node
constexpr std::size_t kProfileEntryBytes = 512; // EvaluatedProfile (face handle + dirs)
constexpr std::size_t kAvgNameBytes = 64;       // average lineage-name string length

std::size_t EstimateSnapshotBytes(const EvaluationState::Snapshot& snapshot) {
  std::size_t bytes = kEntryOverhead;
  for (const EvaluatedBody& body : snapshot.pool.bodies) {
    // Non-negative by construction (Count() over topology); consumed bodies are
    // retained in the snapshot and so are billed — they occupy memory too.
    const std::size_t subShapes = static_cast<std::size_t>(body.probes.solidCount) +
                                  static_cast<std::size_t>(body.probes.shellCount) +
                                  static_cast<std::size_t>(body.probes.faceCount) +
                                  static_cast<std::size_t>(body.probes.edgeCount) +
                                  static_cast<std::size_t>(body.probes.vertexCount);
    bytes += kBodyOverhead + body.bodyId.size() + body.operationId.size() +
             subShapes * kBytesPerSubShape;
  }
  for (const auto& entry : snapshot.pool.availableByOperationId)
    bytes += kMapNodeOverhead + entry.first.size();
  for (const auto& entry : snapshot.profiles)
    bytes += kMapNodeOverhead + entry.first.size() + kProfileEntryBytes;
  if (snapshot.book.has_value())
    bytes += static_cast<std::size_t>(snapshot.book->names.Extent()) *
             (kMapNodeOverhead + kAvgNameBytes);
  return bytes;
}

} // namespace

ShapeProbes ProbeShape(const TopoDS_Shape& shape) {
  if (shape.IsNull())
    throw std::invalid_argument("cannot probe a null shape");
  ShapeProbes result;
  result.valid = BRepCheck_Analyzer(shape, false).IsValid();
  result.solidCount = Count(shape, TopAbs_SOLID);
  result.shellCount = Count(shape, TopAbs_SHELL);
  result.faceCount = Count(shape, TopAbs_FACE);
  result.edgeCount = Count(shape, TopAbs_EDGE);
  result.vertexCount = Count(shape, TopAbs_VERTEX);

  GProp_GProps surfaceProperties;
  BRepGProp::SurfaceProperties(shape, surfaceProperties);
  result.surfaceArea = std::abs(surfaceProperties.Mass());

  // Surfacing domain: a shape with no TopAbs_SOLID sub-shape (an open shell
  // or a bare face — the Surfacing domain's whole product) has no
  // well-defined enclosed volume. BRepGProp::VolumeProperties still RUNS on
  // such a shape without complaint (the divergence-theorem sum over whatever
  // faces exist — OCCT does not refuse an open shape), but MEASURED
  // (surfacing_test.cpp) against a simple open rectangular patch, the number
  // it returns is neither 0 nor any obviously-flagged sentinel: it is a
  // numerically-well-defined but PHYSICALLY MEANINGLESS artifact of an
  // implicitly-assumed closing surface. Reporting that artifact under the
  // `volume` field would silently mislead a consumer (a UI panel showing a
  // bogus "Volume: 4.1 mm3" for a surface body). `solidCount` above is
  // already the reliable, ALREADY-CORRECT open-vs-solid discriminator (a
  // bare TopExp::MapShapes census, shape-kind-agnostic, unaffected by this
  // change) — so `volume` is forced to the unambiguous 0.0 here, and
  // `centerOfMass` switches to the SURFACE (area-weighted) centroid, which
  // unlike the volume integral IS well-defined for an open shape and is what
  // a "center of this body" consumer actually wants. A shape mixing solids
  // with open shells (not producible by any operation today) still takes the
  // volume path below, since it does have a genuine enclosed volume from its
  // solid member(s) — exactly the existing, unchanged behavior for every
  // solid body this function already served before the Surfacing domain.
  gp_Pnt center;
  if (result.solidCount > 0) {
    GProp_GProps volumeProperties;
    BRepGProp::VolumeProperties(shape, volumeProperties);
    result.volume = std::abs(volumeProperties.Mass());
    center = volumeProperties.CentreOfMass();
  } else {
    result.volume = 0.0;
    center = surfaceProperties.CentreOfMass();
  }
  result.centerOfMass[0] = center.X();
  result.centerOfMass[1] = center.Y();
  result.centerOfMass[2] = center.Z();

  Bnd_Box box;
  BRepBndLib::AddOptimal(shape, box, true, false);
  box.Get(result.bounds[0], result.bounds[1], result.bounds[2], result.bounds[3], result.bounds[4],
          result.bounds[5]);
  return result;
}

std::vector<EvaluatedBody> EvaluateOperations(const nlohmann::json& operations,
                                              const std::atomic_bool& cancelled,
                                              ElementNameBook* elementNames,
                                              NamingRegistry* namingRegistry,
                                              OperationDeadline* deadline) {
  if (!operations.is_array())
    throw std::invalid_argument("operations must be an array");
  // Tranche N3: a registry brings its OWN book, so the naming passes and the
  // record harvest read one shared lineage state. Passing both a bare book
  // and a registry would fork the recording path — refuse it outright.
  if (namingRegistry != nullptr && elementNames != nullptr) {
    throw std::runtime_error(
        "evaluate: pass either an element-name book or a naming registry, never both");
  }
  ElementNameBook* const book = namingRegistry != nullptr ? &namingRegistry->Book() : elementNames;
  // Evaluation contract: operations evaluate strictly in document order, and
  // the returned vector contains only body-producing operations that remain
  // UNCONSUMED at the end of the request. Profiles evaluate to planar faces
  // held here for this request only; a dangling profile is valid and
  // produces nothing. A boolean consumes its target and tool bodies, and a
  // hole consumes its target body (its tool is synthesized from parameters,
  // not a document operation), which then leave the returned vector entirely
  // (and with it probes, mesh emission, and STEP export). Consumers may only
  // reference producer operations that evaluated EARLIER in the same request
  // and are still unconsumed; anything else is REFERENCE_MISSING attributed
  // to the consuming operation. Each op is dispatched by ExecuteOperation (the
  // same per-op path the replay cache drives for a restored-prefix tail).
  BodyPool pool;
  std::map<std::string, EvaluatedProfile> profiles;
  std::map<std::string, EvaluatedOpenPath> openPaths;
  for (const auto& operation : operations) {
    const auto metadata = operation.find("metadata");
    if (metadata != operation.end() && metadata->is_object() &&
        metadata->value("suppressed", false)) {
      // Suppression is an authored feature state, not a renderer visibility
      // flag. Omit the feature from replay so its downstream references fail
      // closed and re-enable is a deterministic ordinary re-evaluation.
      continue;
    }
    // Per-op wall-clock cap (Wave 2.1 slice 3b): the guard arms the watchdog for
    // this op and disarms on scope exit even if ExecuteOperation throws. A null
    // deadline is a no-op.
    const ScopedOperation opScope(deadline, operation.value("id", std::string()));
    ExecuteOperation(operation, operations, pool, profiles, openPaths, book, namingRegistry,
                     cancelled);
  }
  return pool.TakeVisibleBodies();
}

// In-process byte-bounded LRU of evaluation-state snapshots keyed by the
// cumulative operation hash (hex). The governor (Wave 2.1 slice 3a; plan 06 §9)
// evicts least-recently-used snapshots until the live total is within
// `budgetBytes_`, replacing the earlier fixed 512-ENTRY cap. Recency is a
// most-recent-front list so a hot document's prefixes survive eviction.
//
// Concurrency: a `stats` frame is read and handled on the reader thread while a
// worker may be mid-evaluate, so — unlike the rest of the evaluator, which runs
// single-threaded under the server's busy_ guard — the cache map/list/counters
// are guarded by `mutex_`. The snapshot pointer Get() returns is borrowed under
// the single-worker contract: only the worker mutates the map, and it copies out
// (RestoreFrom) before its next Put, so the borrow stays valid without holding
// the lock across the restore; concurrent stats only read.
struct DocumentEvaluator::Impl final {
  explicit Impl(std::size_t budgetBytes) : budgetBytes_(budgetBytes) {}

  struct Entry final {
    EvaluationState::Snapshot snapshot;
    std::size_t bytes;
  };

  const EvaluationState::Snapshot* Get(const std::string& key) {
    std::scoped_lock lock(mutex_);
    const auto found = entries_.find(key);
    if (found == entries_.end())
      return nullptr;
    Touch(key);
    return &found->second.snapshot;
  }

  void Put(const std::string& key, EvaluationState::Snapshot snapshot) {
    // Estimate outside the lock — it touches only the passed-in value.
    const std::size_t bytes = EstimateSnapshotBytes(snapshot);
    std::scoped_lock lock(mutex_);
    const auto found = entries_.find(key);
    if (found != entries_.end()) {
      totalBytes_ -= found->second.bytes;
      found->second.snapshot = std::move(snapshot);
      found->second.bytes = bytes;
      totalBytes_ += bytes;
      Touch(key);
      EvictToBudget();
      return;
    }
    entries_.emplace(key, Entry{std::move(snapshot), bytes});
    recency_.push_front(key);
    position_.emplace(key, recency_.begin());
    totalBytes_ += bytes;
    snapshotsStored_ += 1;
    EvictToBudget();
  }

  void RecordPrefixOutcome(bool hit) {
    std::scoped_lock lock(mutex_);
    if (hit)
      hits_ += 1;
    else
      misses_ += 1;
  }

  CacheStats StatsSnapshot() const {
    std::scoped_lock lock(mutex_);
    CacheStats stats;
    stats.entries = entries_.size();
    stats.bytes = totalBytes_;
    stats.budgetBytes = budgetBytes_;
    stats.hits = hits_;
    stats.misses = misses_;
    stats.evictions = evictions_;
    stats.snapshotsStored = snapshotsStored_;
    return stats;
  }

private:
  void Touch(const std::string& key) {
    const auto entry = position_.find(key);
    recency_.erase(entry->second);
    recency_.push_front(key);
    entry->second = recency_.begin();
  }

  // Evict the least-recently-used entries until within budget. Never evicts the
  // last remaining entry: a single snapshot larger than the whole budget is
  // kept (evicting it frees nothing the governor can act on and it is the one a
  // just-restored prefix would need). The just-inserted key sits at the recency
  // FRONT, so tail eviction never reclaims it while any older entry exists.
  void EvictToBudget() {
    while (totalBytes_ > budgetBytes_ && entries_.size() > 1)
      EvictLeastRecent();
  }

  void EvictLeastRecent() {
    const std::string leastRecent = recency_.back();
    recency_.pop_back();
    position_.erase(leastRecent);
    const auto found = entries_.find(leastRecent);
    totalBytes_ -= found->second.bytes;
    entries_.erase(found);
    evictions_ += 1;
  }

  mutable std::mutex mutex_;
  std::unordered_map<std::string, Entry> entries_;
  std::list<std::string> recency_;
  std::unordered_map<std::string, std::list<std::string>::iterator> position_;
  const std::size_t budgetBytes_;
  std::size_t totalBytes_ = 0;
  std::uint64_t hits_ = 0;
  std::uint64_t misses_ = 0;
  std::uint64_t evictions_ = 0;
  std::uint64_t snapshotsStored_ = 0;
};

DocumentEvaluator::DocumentEvaluator(std::size_t cacheBudgetBytes)
    : impl_(std::make_unique<Impl>(cacheBudgetBytes)) {}
DocumentEvaluator::~DocumentEvaluator() = default;

DocumentEvaluator::CacheStats DocumentEvaluator::Stats() const { return impl_->StatsSnapshot(); }

DocumentEvaluator::Result DocumentEvaluator::Evaluate(const nlohmann::json& operations,
                                                      const std::string& documentId,
                                                      const std::string& kernelGeomVersion,
                                                      bool includeElementNames, bool reuseEnabled,
                                                      const std::atomic_bool& cancelled,
                                                      OperationDeadline* deadline) {
  if (!operations.is_array())
    throw std::invalid_argument("operations must be an array");

  EvaluationState state;
  // A document carrying a selector ref slot (fillet `edges`, shell `openFaces`,
  // a datum reference) resolves it on-kernel through an epoch-local naming
  // registry (N4/N5), so engage one for the WHOLE cold evaluation: a fresh
  // registry harvests every op's names as they execute and the selector
  // resolves (N6 slice C). The registry owns its book, so it serves element
  // naming too. A document WITHOUT a selector rides the byte-identical bare-book
  // path — only `includeElementNames` engages a book — leaving offset/import
  // naming-fail-closed and the differential-replay corpus exactly as before.
  if (DocumentRequiresNamingRegistry(operations))
    state.registry.emplace();
  else if (includeElementNames)
    state.book.emplace();

  const std::size_t operationCount = operations.size();
  std::size_t startIndex = 0;
  // prefixHashes[i] = the cumulative hash of the state AFTER operations[0..i-1]
  // (length operationCount + 1). Only computed when reuse is on.
  std::vector<std::string> prefixHashes;

  if (reuseEnabled) {
    prefixHashes = CumulativeOperationHashes(documentId, kernelGeomVersion, operations);
    // Longest cached prefix: the largest i in [1, operationCount] whose
    // after-i-ops hash is live. Restore that state and execute from op i.
    for (std::size_t prefix = operationCount; prefix >= 1; --prefix) {
      const EvaluationState::Snapshot* cached = impl_->Get(prefixHashes[prefix]);
      if (cached != nullptr) {
        state.RestoreFrom(*cached);
        startIndex = prefix;
        break;
      }
    }
    // Per-evaluation prefix outcome for `stats` (§7): a restored prefix is a
    // hit, a cold evaluation (startIndex == 0) a miss.
    impl_->RecordPrefixOutcome(startIndex > 0);
  }

  // The registry is threaded ONLY into a fresh full evaluation (startIndex == 0).
  // A restored prefix (startIndex > 0) carries no registry records — the snapshot
  // deliberately omits them — so re-executing the tail against the registry would
  // fail-closed INTERNAL_ERROR the moment an ordinary mutating op harvested
  // against an absent prefix record. Handing the tail a null registry instead
  // reproduces the exact bare-book reuse path for non-selector ops, and a tail
  // SELECTOR op fails closed with a typed refusal ("an edge-scoped fillet
  // requires the naming registry") rather than resolving against a half-populated
  // registry — making reuse-on selector resolution actually work is a later
  // "registry in the snapshot" tranche. Reuse is OFF by default, so the shipped
  // cold path always threads the registry and the selector resolves.
  NamingRegistry* const tailRegistry = startIndex == 0 ? state.Registry() : nullptr;
  for (std::size_t index = startIndex; index < operationCount; ++index) {
    const auto metadata = operations[index].find("metadata");
    if (metadata != operations[index].end() && metadata->is_object() &&
        metadata->value("suppressed", false)) {
      if (reuseEnabled)
        impl_->Put(prefixHashes[index + 1], state.TakeSnapshot());
      continue;
    }
    // Per-op wall-clock cap (slice 3b): only the re-executed tail is timed; the
    // restored prefix ran in an earlier request. The guard disarms on scope exit
    // even when the op throws (a timeout unwinds through here). Null = no-op.
    const ScopedOperation opScope(deadline, operations[index].value("id", std::string()));
    ExecuteOperation(operations[index], operations, state.pool, state.profiles, state.openPaths,
                     state.NamingBook(), tailRegistry, cancelled);
    if (reuseEnabled)
      impl_->Put(prefixHashes[index + 1], state.TakeSnapshot());
  }

  Result result;
  result.bodies = state.pool.PeekVisibleBodies();
  result.executedOperationCount = operationCount - startIndex;
  if (includeElementNames) {
    // Names come from whichever channel was engaged; a selector document
    // (registry engaged) still surfaces them from the registry's own book.
    if (state.registry.has_value())
      result.elementNames = std::move(state.registry->Book());
    else
      result.elementNames = std::move(state.book);
  }
  return result;
}

nlohmann::json ProbesToJson(const ShapeProbes& probes) {
  return {
      {"valid", probes.valid},
      {"volumeMm3", probes.volume},
      {"surfaceAreaMm2", probes.surfaceArea},
      {"centerOfMassMm", {probes.centerOfMass[0], probes.centerOfMass[1], probes.centerOfMass[2]}},
      {"boundingBoxMm",
       {probes.bounds[0], probes.bounds[1], probes.bounds[2], probes.bounds[3], probes.bounds[4],
        probes.bounds[5]}},
      {"solidCount", probes.solidCount},
      {"shellCount", probes.shellCount},
      {"faceCount", probes.faceCount},
      {"edgeCount", probes.edgeCount},
      {"vertexCount", probes.vertexCount},
  };
}

std::string CollisionShapeCacheKey(const std::string& revisionHash, const std::string& bodyId) {
  return revisionHash + ":" + bodyId;
}

TopoDS_Shape CombineBodies(const std::vector<EvaluatedBody>& bodies) {
  if (bodies.empty())
    throw std::invalid_argument("document contains no exportable bodies");
  if (bodies.size() == 1)
    return bodies.front().shape;
  BRep_Builder builder;
  TopoDS_Compound compound;
  builder.MakeCompound(compound);
  for (const auto& body : bodies)
    builder.Add(compound, body.shape);
  return compound;
}

std::uintmax_t ExportStep(const std::vector<EvaluatedBody>& bodies, const std::string& path,
                          const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  STEPControl_Writer writer;
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  if (writer.Transfer(CombineBodies(bodies), STEPControl_AsIs, true, progress->Start()) !=
      IFSelect_RetDone) {
    throw std::runtime_error("STEP transfer failed");
  }
  CheckCancellation(cancelled);

  // Crash-safe publish (finding 11): never write in place over a valid file. We
  // write to a same-directory temp, flush + fsync it, reopen-verify it re-parses
  // as a STEP, then atomically rename it over the destination. On ANY failure the
  // temp is removed and the destination — if one existed — is left byte-for-byte
  // untouched, so a failed or interrupted write can never destroy a prior export.
  const std::filesystem::path outputPath = Utf8Path(path);
  const std::filesystem::path tempPath = aeth::NextStepTempPath(outputPath);
  try {
    std::ofstream output(tempPath, std::ios::binary | std::ios::trunc);
    if (!output)
      throw std::runtime_error("STEP output could not be opened");
    if (writer.WriteStream(output) != IFSelect_RetDone)
      throw std::runtime_error("STEP write failed");
    output.flush();
    if (!output)
      throw std::runtime_error("STEP output could not be flushed");
    output.close();

    aeth::FsyncFile(tempPath);
    CheckCancellation(cancelled);
    // Reopen-verify: recover the temp path as the UTF-8 string InspectStep
    // consumes (the exact inverse of Utf8Path), then re-parse it. InspectStep
    // throws if the bytes on disk are not a readable STEP with transferable
    // roots, so a corrupt write can never be renamed over a valid destination.
    const std::u8string tempUtf8 = tempPath.u8string();
    const std::string tempPathString(reinterpret_cast<const char*>(tempUtf8.data()),
                                     tempUtf8.size());
    InspectStep(tempPathString, cancelled);

    const std::uintmax_t bytesWritten = std::filesystem::file_size(tempPath);
    aeth::RenameOverTarget(tempPath, outputPath);
    return bytesWritten;
  } catch (...) {
    aeth::RemoveTempBestEffort(tempPath);
    throw;
  }
}

namespace {

Handle(TDocStd_Document) NewXdeDocument() {
  Handle(TDocStd_Document) document;
  Handle(XCAFApp_Application) application = XCAFApp_Application::GetApplication();
  application->NewDocument("MDTV-XCAF", document);
  return document;
}

void AddXdeBody(const Handle(XCAFDoc_ShapeTool) & shapeTool, const EvaluatedBody& body) {
  const TDF_Label label = shapeTool->AddShape(body.shape, false);
  TDataStd_Name::Set(label, TCollection_ExtendedString(body.bodyId.c_str()));
}

void CountXdeLabel(const Handle(XCAFDoc_ShapeTool) & shapeTool, const TDF_Label& label,
                   int& definitionCount, int& occurrenceCount, int& namedCount) {
  ++definitionCount;
  Handle(TDataStd_Name) name;
  if (label.FindAttribute(TDataStd_Name::GetID(), name) && !name->Get().IsEmpty())
    ++namedCount;
  if (!shapeTool->IsAssembly(label))
    return;
  NCollection_Sequence<TDF_Label> components;
  shapeTool->GetComponents(label, components);
  occurrenceCount += components.Length();
  for (int index = 1; index <= components.Length(); ++index)
    CountXdeLabel(shapeTool, components.Value(index), definitionCount, occurrenceCount, namedCount);
}

} // namespace

std::uintmax_t ExportStepXde(const std::vector<EvaluatedBody>& bodies, const std::string& path,
                             const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  if (bodies.empty())
    throw std::invalid_argument("document contains no exportable bodies");
  Handle(TDocStd_Document) document = NewXdeDocument();
  Handle(XCAFDoc_ShapeTool) shapeTool = XCAFDoc_DocumentTool::ShapeTool(document->Main());
  for (const EvaluatedBody& body : bodies) {
    CheckCancellation(cancelled);
    AddXdeBody(shapeTool, body);
  }
  STEPCAFControl_Writer writer;
  writer.SetColorMode(true);
  writer.SetNameMode(true);
  if (!writer.Transfer(document, STEPControl_AsIs))
    throw std::runtime_error("STEP/XDE transfer failed");
  const std::filesystem::path outputPath = Utf8Path(path);
  const std::filesystem::path tempPath = aeth::NextStepTempPath(outputPath);
  try {
    const std::u8string tempUtf8 = tempPath.u8string();
    const std::string tempPathString(reinterpret_cast<const char*>(tempUtf8.data()),
                                     tempUtf8.size());
    if (writer.Write(tempPathString.c_str()) != IFSelect_RetDone)
      throw std::runtime_error("STEP/XDE write failed");
    CheckCancellation(cancelled);
    const std::uintmax_t bytesWritten = std::filesystem::file_size(tempPath);
    aeth::FsyncFile(tempPath);
    aeth::RenameOverTarget(tempPath, outputPath);
    return bytesWritten;
  } catch (...) {
    aeth::RemoveTempBestEffort(tempPath);
    throw;
  }
}

nlohmann::json ExactInterference(const std::vector<EvaluatedBody>& bodies,
                                 const nlohmann::json& request, const std::string& kernelBuildId,
                                 const std::string& geometryBuildId,
                                 const std::atomic_bool& cancelled) {
  const double tolerance = request.value("toleranceMm", 1.0e-7);
  if (!std::isfinite(tolerance) || tolerance < 0.0)
    throw std::invalid_argument("interference_exact toleranceMm must be finite and nonnegative");
  if (!request.contains("pairs") || !request.at("pairs").is_array())
    throw std::invalid_argument("interference_exact pairs must be an array");
  std::unordered_map<std::string, const EvaluatedBody*> byBody;
  for (const EvaluatedBody& body : bodies)
    byBody.emplace(body.bodyId, &body);

  nlohmann::json findings = nlohmann::json::array();
  bool hasFinding = false;
  for (const auto& pair : request.at("pairs")) {
    CheckCancellation(cancelled);
    const auto& a = pair.at("a");
    const auto& b = pair.at("b");
    const EvaluatedBody* bodyA = byBody.at(a.at("bodyId").get<std::string>());
    const EvaluatedBody* bodyB = byBody.at(b.at("bodyId").get<std::string>());
    BRepAlgoAPI_Common common(bodyA->shape, bodyB->shape);
    common.Build();
    if (!common.IsDone())
      throw std::runtime_error("exact interference common failed");
    GProp_GProps commonProperties;
    BRepGProp::VolumeProperties(common.Shape(), commonProperties);
    const double overlapVolume = commonProperties.Mass();
    BRepExtrema_DistShapeShape distance(bodyA->shape, bodyB->shape);
    distance.Perform();
    if (!distance.IsDone())
      throw std::runtime_error("exact interference distance failed");
    const double distanceMm = distance.Value();
    const bool penetrating = overlapVolume > tolerance;
    const bool touching = !penetrating && distanceMm <= tolerance;
    if (!penetrating && !touching)
      continue;

    gp_Pnt pointA(0.0, 0.0, 0.0);
    gp_Pnt pointB(0.0, 0.0, 0.0);
    if (distance.NbSolution() > 0) {
      pointA = distance.PointOnShape1(1);
      pointB = distance.PointOnShape2(1);
    }
    gp_Vec normal(pointA, pointB);
    if (normal.Magnitude() > Precision::Confusion())
      normal.Normalize();
    const double signedDistance =
        penetrating ? -std::cbrt(std::max(overlapVolume, tolerance)) : distanceMm;
    const nlohmann::json pairOutput = {
        {"a",
         {{"occurrencePath", a.at("occurrencePath")},
          {"definitionId", a.at("definitionId")},
          {"definitionRevisionHash", a.at("definitionRevisionHash")}}},
        {"b",
         {{"occurrencePath", b.at("occurrencePath")},
          {"definitionId", b.at("definitionId")},
          {"definitionRevisionHash", b.at("definitionRevisionHash")}}},
    };
    findings.push_back({{"pair", pairOutput},
                        {"relation", penetrating ? "penetrating" : "touching"},
                        {"signedDistanceMm", signedDistance},
                        {"overlapVolumeMm3", penetrating ? overlapVolume : 0.0},
                        {"witness",
                         {{"pointA", {pointA.X(), pointA.Y(), pointA.Z()}},
                          {"pointB", {pointB.X(), pointB.Y(), pointB.Z()}},
                          {"normal", {normal.X(), normal.Y(), normal.Z()}}}},
                        {"exactConfirmation",
                         {{"kind", "occt-brep-confirmation"},
                          {"method", "common"},
                          {"kernelBuildId", kernelBuildId},
                          {"definitionRevisionHashA", a.at("definitionRevisionHash")},
                          {"definitionRevisionHashB", b.at("definitionRevisionHash")}}}});
    hasFinding = true;
  }
  const std::string pairSetDigest = aeth::Sha256Hex8(request.at("pairs").dump());
  const std::string inputRevisionDigest =
      request.value("inputRevisionDigest", aeth::Sha256Hex8(request.at("operations").dump()));
  const std::string resultDigest = aeth::Sha256Hex8(findings.dump());
  const nlohmann::json confirmation = {{"kind", "occt-brep-report-confirmation"},
                                       {"method", "common"},
                                       {"kernelBuildId", kernelBuildId}};
  return {{"type", "interference_exact_result"},
          {"report",
           {{"query", "exact-interference"},
            {"accuracy", "exact-brep"},
            {"exactConfirmation", confirmation},
            {"status", "complete"},
            {"conclusion", hasFinding ? "findings" : "clear"},
            {"toleranceMm", tolerance},
            {"totalPairCount", request.at("pairs").size()},
            {"evaluatedPairCount", request.at("pairs").size()},
            {"findings", findings}}},
          {"evidence",
           {{"kind", "native-occt-execution"},
            {"executionId", request.at("requestId")},
            {"kernelBuildId", kernelBuildId},
            {"occtVersion", AETH_OCCT_TAG},
            {"occtCommit", AETH_OCCT_COMMIT},
            {"geometryBuildId", geometryBuildId},
            {"inputRevisionDigest", inputRevisionDigest},
            {"pairSetDigest", pairSetDigest},
            {"toleranceMm", tolerance},
            {"fuzzyToleranceMm", 0.0},
            {"inputValidation", "passed"},
            {"resultDigest", resultDigest}}}};
}

nlohmann::json InspectStepXde(const std::string& path, const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  Handle(TDocStd_Document) document = NewXdeDocument();
  STEPCAFControl_Reader reader;
  reader.SetColorMode(true);
  reader.SetNameMode(true);
  if (reader.ReadFile(path.c_str()) != IFSelect_RetDone)
    throw std::runtime_error("STEP/XDE read failed");
  CheckCancellation(cancelled);
  if (!reader.Transfer(document))
    throw std::runtime_error("STEP/XDE transfer failed");
  Handle(XCAFDoc_ShapeTool) shapeTool = XCAFDoc_DocumentTool::ShapeTool(document->Main());
  NCollection_Sequence<TDF_Label> roots;
  shapeTool->GetFreeShapes(roots);
  int definitionCount = 0;
  int occurrenceCount = 0;
  int namedCount = 0;
  for (int index = 1; index <= roots.Length(); ++index)
    CountXdeLabel(shapeTool, roots.Value(index), definitionCount, occurrenceCount, namedCount);
  return {{"type", "step_xde_inspection"},      {"representation", "xde"},
          {"rootCount", roots.Length()},        {"definitionCount", definitionCount},
          {"occurrenceCount", occurrenceCount}, {"namedEntityCount", namedCount}};
}

TopoDS_Shape ImportStepShape(const std::string& path, const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  // Opening a freshly-written file can transiently fail under external
  // contention (antivirus/indexer holds, loaded CI runners); the content is
  // already durable, so a bounded retry on the OPEN only is honest. Read and
  // parse failures below stay single-shot.
  std::ifstream input;
  for (int attempt = 0;; ++attempt) {
    input.open(Utf8Path(path), std::ios::binary);
    if (input)
      break;
    if (attempt >= 2)
      throw std::runtime_error("STEP input could not be opened");
    CheckCancellation(cancelled);
    std::this_thread::sleep_for(std::chrono::milliseconds(50 * (attempt + 1)));
    input.clear();
  }
  STEPControl_Reader reader;
  if (reader.ReadStream("aethalgard.step", input) != IFSelect_RetDone)
    throw std::runtime_error("STEP read failed");
  CheckCancellation(cancelled);
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  if (reader.TransferRoots(progress->Start()) == 0)
    throw std::runtime_error("STEP contains no transferable roots");
  return reader.OneShape();
}

ShapeProbes InspectStep(const std::string& path, const std::atomic_bool& cancelled) {
  return ProbeShape(ImportStepShape(path, cancelled));
}

TopoDS_Shape ImportStepShapeFromString(const std::string& source,
                                       const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  // The document retains the original Part-21 bytes (§2.1); read them straight
  // from memory rather than staging a temp file, so an import replays without
  // any dependence on the source file still existing on disk.
  std::istringstream input(source, std::ios::binary);
  STEPControl_Reader reader;
  if (reader.ReadStream("aethalgard-inline.step", input) != IFSelect_RetDone)
    throw Standard_Failure("import_step could not parse the retained STEP source");
  CheckCancellation(cancelled);
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  if (reader.TransferRoots(progress->Start()) == 0)
    throw Standard_Failure("import_step STEP source has no transferable roots");
  return reader.OneShape();
}

TopoDS_Shape ImportMeshShapeFromString(const std::string& source,
                                       const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  // The document retains the CHECKED aeth-mesh-v1 payload base64-encoded (§2.1);
  // decode it straight from memory and rebuild the solid, so an import replays
  // without any dependence on the original mesh file still existing on disk.
  const std::vector<unsigned char> payload = DecodeBase64(source);
  const AethMesh mesh = DecodeAethMeshV1(payload);
  return BuildSolidFromAethMesh(mesh, cancelled);
}

} // namespace aeth
