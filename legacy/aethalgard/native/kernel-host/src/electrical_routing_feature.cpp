#include "electrical_routing_feature.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <limits>
#include <string>
#include <vector>

#include <BRepBuilderAPI_MakeEdge.hxx>
#include <BRepBuilderAPI_MakeWire.hxx>
#include <BRepBuilderAPI_TransitionMode.hxx>
#include <BRepCheck_Analyzer.hxx>
#include <BRepLib.hxx>
#include <BRepOffsetAPI_MakePipeShell.hxx>
#include <BRep_Tool.hxx>
#include <GeomAPI_Interpolate.hxx>
#include <GeomLProp_CLProps.hxx>
#include <Geom_BSplineCurve.hxx>
#include <Geom_Curve.hxx>
#include <NCollection_HArray1.hxx>
#include <Precision.hxx>
#include <Standard_Failure.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Solid.hxx>
#include <TopoDS_Vertex.hxx>
#include <TopoDS_Wire.hxx>
#include <gp_Ax2.hxx>
#include <gp_Circ.hxx>
#include <gp_Dir.hxx>
#include <gp_Pnt.hxx>
#include <gp_Vec.hxx>

#include "body_pool.hpp"
#include "cancel.hpp"
#include "naming_registry.hpp"
#include "ref_slot.hpp"
#include "selector_evaluator.hpp"

namespace aeth {
namespace {

void CheckCancellation(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
}

/// Finishes a wire_route SOLID body: geometry.cpp's own `FinishSolidBody`
/// (OrientClosedSolid, then probe-and-require-valid) reproduced locally for
/// the same cross-translation-unit reason surfacing_feature.cpp's own
/// `FinishSurfaceBody`/`FinishThickenedSolidBody` document — geometry.cpp's
/// original lives in that file's own anonymous namespace. `wire_route` only
/// ever produces a solid (the swept pipe), never an open body, so this is
/// named and shaped identically to the geometry.cpp original rather than
/// needing surfacing's two-way split.
EvaluatedBody FinishSolidBody(const nlohmann::json& operation, TopoDS_Solid solid,
                              const char* label) {
  BRepLib::OrientClosedSolid(solid);
  EvaluatedBody body;
  body.bodyId = operation.at("outputBodyId").get<std::string>();
  body.operationId = operation.at("id").get<std::string>();
  body.shape = solid;
  body.probes = ProbeShape(body.shape);
  if (!body.probes.valid)
    throw std::runtime_error(std::string("OCCT produced an invalid ") + label);
  return body;
}

// Point-coincidence tolerance for the degenerate-sequence check below —
// matches datum_feature.cpp's own kCoincidentPointsMm (the datum_axis
// twoPoints precedent): 1e-6 mm is this codebase's standing "these are the
// same point" scale (mirror/sweep's own profile-anchor coincidence checks
// use the identical value). Deliberately an order of magnitude LARGER than
// kInterpolationTolerance below, so this typed pre-check always fires first
// for any sequence that would also trip GeomAPI_Interpolate's own
// constructor precondition ("Standard_ConstructionError if the distance
// between two consecutive points ... is less than or equal to Tolerance",
// its own header) — this file's own typed refusal always wins over a raw
// OCCT exception, never the reverse.
constexpr double kCoincidentPointTolerance = 1.0e-6;
constexpr double kInterpolationTolerance = 1.0e-7;

/// The ordered point sequence `[startPoint, waypoints..., endPoint]`.
/// Refuses `E_WIRE_ROUTE_DEGENERATE` if any two CONSECUTIVE points coincide
/// within `kCoincidentPointTolerance`. This SUBSUMES "fewer than 2 distinct
/// points result" without a separate cardinality scan: the only way the
/// whole sequence can collapse to under 2 distinct values is for EVERY
/// point in it to equal that one value, in which case every consecutive
/// pair — in particular the first — is already coincident and caught here.
/// There is no arrangement where the sequence has fewer than 2 distinct
/// values yet no two adjacent entries coincide, so a whole-sequence
/// cardinality check would be dead code layered on top of this one, not a
/// materially stronger one.
std::vector<gp_Pnt> ResolvedRoutePoints(const nlohmann::json& parameters,
                                        const std::string& operationId, const gp_Pnt& startPoint,
                                        const gp_Pnt& endPoint) {
  const nlohmann::json waypoints = parameters.value("waypoints", nlohmann::json::array());
  if (!waypoints.is_array())
    throw std::invalid_argument("wire_route waypoints must be an array of points");

  std::vector<gp_Pnt> points;
  points.reserve(waypoints.size() + 2);
  points.push_back(startPoint);
  for (const nlohmann::json& waypoint : waypoints) {
    if (!waypoint.is_array() || waypoint.size() != 3)
      throw std::invalid_argument("wire_route waypoints entries must be [x, y, z] points");
    points.emplace_back(waypoint.at(0).get<double>(), waypoint.at(1).get<double>(),
                        waypoint.at(2).get<double>());
  }
  points.push_back(endPoint);

  for (std::size_t index = 1; index < points.size(); ++index) {
    const double distance = points[index - 1].Distance(points[index]);
    if (distance <= kCoincidentPointTolerance) {
      throw OperationFailure(
          operationId, "INVALID_REQUEST",
          "wire_route's routed points must be pairwise distinct where consecutive; two "
          "consecutive points in the start/waypoints/end sequence coincide",
          {{"routeCode", "E_WIRE_ROUTE_DEGENERATE"},
           {"pointIndex", static_cast<int>(index)},
           {"distanceMm", distance}});
    }
  }
  return points;
}

} // namespace

EvaluatedBody EvaluateWireRoute(const nlohmann::json& operation, BodyPool& pool,
                                ElementNameBook* elementNames, NamingRegistry* registry,
                                const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();

  const double diameter = parameters.at("diameterMm").get<double>();
  const double minimumBendRadius = parameters.at("minimumBendRadiusMm").get<double>();
  const std::string wireType = parameters.value("wireType", "wire");
  if (!(std::isfinite(diameter) && diameter > 0.0))
    throw std::invalid_argument("wire_route diameterMm must be positive");
  if (!(std::isfinite(minimumBendRadius) && minimumBendRadius > 0.0))
    throw std::invalid_argument("wire_route minimumBendRadiusMm must be positive");
  if (wireType != "wire" && wireType != "cable")
    throw std::invalid_argument("unsupported wire_route wireType: " + wireType);
  // netName is a plain descriptive label (SolidWorks "Net" concept, v1
  // cosmetic-only per the schema doc comment) with no geometric consequence
  // at all — deliberately never read here.

  if (registry == nullptr) {
    // The edge_flange/datum registry-guard precedent: startVertex/endVertex
    // need the registry to resolve, so the registry-less path refuses
    // fail-closed rather than guess.
    throw std::invalid_argument(
        "unsupported operation: wire_route requires the naming registry to resolve its "
        "`startVertex`/`endVertex` references; evaluate with the registry enabled");
  }

  // Resolve both terminal vertices against the peeked (pre-mutation) pool
  // state — the fillet-v2/N5 discipline every other ref-resolving executor
  // in this codebase follows. Neither resolved body is consumed below (the
  // wire_route contract: both stay live, see this file's header comment),
  // but resolving from the peeked snapshot keeps this call shape identical
  // to every other ref-resolving executor regardless.
  const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
  const RefResolution startResolution =
      ResolveRefSlotStrict(operationId, "wire_route", "startVertex", parameters.at("startVertex"),
                           peeked, *registry, cancelled);
  const QueryEntity startEntity =
      SingleResolvedEntity("wire_route", "startVertex", 'v', startResolution);
  const RefResolution endResolution =
      ResolveRefSlotStrict(operationId, "wire_route", "endVertex", parameters.at("endVertex"),
                           peeked, *registry, cancelled);
  const QueryEntity endEntity = SingleResolvedEntity("wire_route", "endVertex", 'v', endResolution);
  const gp_Pnt startPoint = BRep_Tool::Pnt(TopoDS::Vertex(startEntity.shape));
  const gp_Pnt endPoint = BRep_Tool::Pnt(TopoDS::Vertex(endEntity.shape));

  const std::vector<gp_Pnt> routePoints =
      ResolvedRoutePoints(parameters, operationId, startPoint, endPoint);

  const auto refuse = [&](const char* message, const char* routeCode) -> void {
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message, {{"routeCode", routeCode}});
  };

  // --- Build a smooth interpolated curve through the routed points. -------
  // GeomAPI_Interpolate's real constructor (verified against the vendored
  // header, not assumed): a Handle(NCollection_HArray1<gp_Pnt>), a periodic
  // flag, and a tolerance — NOT the initially-hypothesized
  // TColgp_Array1OfPnt shape, which this pinned OCCT deprecates in favor of
  // NCollection_HArray1<gp_Pnt> directly (its own header says so explicitly:
  // "deprecated since OCCT 8.0.0... use NCollection_HArray1<gp_Pnt>
  // directly"). Non-periodic (a route is an open path, never a closed
  // loop) with no Load() tangent constraints, so the whole curve is
  // uniformly C2 (its own header: "C2 Continuity if tangency is not
  // requested at the point") — load-bearing for the sampling density
  // reasoning below (no special "also sample at every knot" step is needed
  // on top of dense uniform sampling, because there is no continuity drop
  // AT a knot to catch separately).
  occ::handle<NCollection_HArray1<gp_Pnt>> pointArray =
      new NCollection_HArray1<gp_Pnt>(1, static_cast<int>(routePoints.size()));
  for (std::size_t index = 0; index < routePoints.size(); ++index)
    pointArray->SetValue(static_cast<int>(index) + 1, routePoints[index]);
  GeomAPI_Interpolate interpolate(pointArray, /*PeriodicFlag=*/false, kInterpolationTolerance);
  try {
    interpolate.Perform();
  } catch (const Standard_Failure&) {
    CheckCancellation(cancelled);
    refuse("wire_route could not fit a smooth curve through the routed points",
           "E_WIRE_ROUTE_SELF_INTERSECTS");
  }
  CheckCancellation(cancelled);
  if (!interpolate.IsDone()) {
    refuse("wire_route could not fit a smooth curve through the routed points",
           "E_WIRE_ROUTE_SELF_INTERSECTS");
  }
  const occ::handle<Geom_BSplineCurve> curve = interpolate.Curve();

  // --- Sample curvature across the curve's FULL parameter range and
  // enforce minimumBendRadiusMm BEFORE paying for the (more expensive) sweep
  // below. -------------------------------------------------------------
  //
  // Sampling density is PER-SPAN, not a flat overall count: a cubic
  // B-spline's curvature is a bounded-degree rational function WITHIN one
  // knot span, so resolution needs to track the curve's own knot structure
  // (spans = NbKnots() - 1) to stay roughly constant regardless of how many
  // waypoints the caller supplied (up to 64, so up to roughly 65 spans for
  // this non-periodic natural interpolation, which knots at essentially one
  // parameter per input point) — sampling a flat small count overall would
  // silently under-sample a many-waypoint route, catching only its
  // grosser bends and missing a genuinely tight LOCAL one between two
  // closely-spaced waypoints. 50 samples/span is comfortably dense for a
  // single cubic segment's own bounded-complexity curvature profile
  // (GeomLProp_CLProps evaluation is a cheap closed-form polynomial
  // evaluation from already-computed derivatives, so even the maximum
  // ~65-span, ~3251-sample case costs nothing measurable — this is not a
  // tradeoff against performance, just against picking a number at all).
  const double firstParameter = curve->FirstParameter();
  const double lastParameter = curve->LastParameter();
  constexpr int kSamplesPerSpan = 50;
  const int spans = std::max(1, curve->NbKnots() - 1);
  const int sampleCount = spans * kSamplesPerSpan + 1;

  GeomLProp_CLProps properties(curve, firstParameter, 2, Precision::Confusion());
  if (!properties.IsTangentDefined()) {
    refuse("wire_route's routed curve has no defined tangent at its start point",
           "E_WIRE_ROUTE_SELF_INTERSECTS");
  }
  gp_Dir startTangent;
  properties.Tangent(startTangent);

  double tightestRadius = std::numeric_limits<double>::infinity();
  for (int sample = 0; sample < sampleCount; ++sample) {
    CheckCancellation(cancelled);
    const double t = firstParameter + (lastParameter - firstParameter) *
                                          (static_cast<double>(sample) / (sampleCount - 1));
    properties.SetParameter(t);
    double radius = std::numeric_limits<double>::infinity();
    if (properties.IsTangentDefined()) {
      // GeomLProp_CLProps::Curvature() (LProp_CurveUtils::ComputeCurvature,
      // verified by reading its implementation): |D1 x D2| / |D1|^3, an
      // always-NONNEGATIVE 3-space curvature magnitude, EXPLICITLY zeroed
      // out (not merely small) whenever D2 is null or collinear with D1
      // within the Resolution passed to the constructor above
      // (Precision::Confusion()) — so curvature == 0.0 is OCCT's own
      // explicit "this is straight within tolerance" answer, an EXPLICIT
      // infinite-radius case, never a live division by a value that merely
      // happens to be small. A nonzero curvature (including the
      // LProp_CurveUtils::Curvature RealLast() sentinel it returns for a
      // higher-order/cusp parametrization, where the first derivative
      // itself vanishes) divides cleanly into a finite, correctly-tiny
      // radius that reads as a genuine tight-bend violation below.
      const double curvature = properties.Curvature();
      if (curvature > 0.0)
        radius = 1.0 / curvature;
    } else {
      // No defined tangent anywhere up to third order at this sample (a
      // truly stationary point in the curve's own parametrization) is,
      // physically, at least as tight a kink as any finite curvature —
      // treat it as the tightest possible bend rather than silently
      // skipping the sample.
      radius = 0.0;
    }
    tightestRadius = std::min(tightestRadius, radius);
  }

  if (tightestRadius < minimumBendRadius) {
    throw OperationFailure(
        operationId, "GEOMETRY_FAILED",
        "wire_route's path bends tighter than minimumBendRadiusMm somewhere along its length",
        {{"routeCode", "E_WIRE_ROUTE_BEND_TOO_TIGHT"},
         {"tightestRadiusMm", tightestRadius},
         {"minimumBendRadiusMm", minimumBendRadius}});
  }

  // --- Sweep a circular profile of diameterMm along the validated curve
  // into a real solid pipe body. ----------------------------------------
  const TopoDS_Edge spineEdge = BRepBuilderAPI_MakeEdge(curve);
  const TopoDS_Wire spine = BRepBuilderAPI_MakeWire(spineEdge).Wire();
  // Perpendicular to the curve's own start tangent BY CONSTRUCTION
  // (gp_Ax2's two-direction-argument constructor picks that plane
  // directly) — unlike EvaluateSweep's own literal-polyline path
  // (geometry.cpp), which must rely on WithCorrection to rotate a section
  // authored independently of the spine onto the right plane, this file
  // builds the profile already exactly where it needs to be.
  const gp_Ax2 profileFrame(startPoint, startTangent);
  const gp_Circ profileCircle(profileFrame, diameter / 2.0);
  const TopoDS_Edge profileEdge = BRepBuilderAPI_MakeEdge(profileCircle);
  const TopoDS_Wire profileWire = BRepBuilderAPI_MakeWire(profileEdge).Wire();

  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepOffsetAPI_MakePipeShell pipe(spine);
  // Matches EvaluateSweep's own call shape (geometry.cpp), this codebase's
  // one other pipe-shell precedent, for mechanical consistency. Unlike
  // EvaluateSweep's polyline spine, this file's spine is ONE smooth,
  // globally-C2 edge with no fractures for a transition mode to treat
  // differently, so this is harmless parity rather than a load-bearing
  // choice here.
  pipe.SetTransitionMode(BRepBuilderAPI_RightCorner);
  // WithCorrection=true is likewise a no-op by construction (the profile
  // plane above is ALREADY exactly perpendicular to the curve's own start
  // tangent) — kept for the same parity reason.
  pipe.Add(profileWire, /*WithContact=*/false, /*WithCorrection=*/true);
  try {
    pipe.Build(progress->Start());
  } catch (const Standard_Failure&) {
    CheckCancellation(cancelled);
    refuse("wire_route sweep construction failed; the path may self-intersect the profile",
           "E_WIRE_ROUTE_SELF_INTERSECTS");
  }
  CheckCancellation(cancelled);
  if (!pipe.IsDone()) {
    refuse("wire_route sweep construction failed; the path may self-intersect the profile",
           "E_WIRE_ROUTE_SELF_INTERSECTS");
  }
  if (!pipe.MakeSolid())
    refuse("wire_route could not cap the swept shell into a solid", "E_WIRE_ROUTE_SELF_INTERSECTS");
  const TopoDS_Shape result = pipe.Shape();
  if (result.IsNull() || result.ShapeType() != TopAbs_SOLID) {
    refuse("wire_route did not produce a single solid body", "E_WIRE_ROUTE_SELF_INTERSECTS");
  }
  // A path too tightly curved for the section (or one that folds back on
  // itself between waypoints) self-intersects; refuse it as a geometry
  // failure rather than emit an invalid body — the same discipline
  // EvaluateSweep's own final check applies (geometry.cpp).
  if (!BRepCheck_Analyzer(result, false).IsValid()) {
    refuse("wire_route produced an invalid solid; the path may be too tightly curved for the "
           "profile",
           "E_WIRE_ROUTE_SELF_INTERSECTS");
  }

  EvaluatedBody body = FinishSolidBody(operation, TopoDS::Solid(result), "wire_route result");

  if (elementNames != nullptr) {
    // Mints fresh: see this file's header comment (and naming_registry.hpp's
    // own OperationClass::WireRoute doc comment) for the measured reason —
    // wire_route consumes no existing body's topology at all, so there is
    // no NamingRegistry::Input for HarvestOperation to attribute
    // Modified/Generated images against. No registry harvest for the same
    // reason; book-level naming above is still total (every sub-shape of
    // the result gets a name, satisfying includeElementNames's coverage
    // contract).
    elementNames->AddDerivedPrimitive(operationId, body.shape);
  }
  return body;
}

} // namespace aeth
