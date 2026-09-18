// Native integration tests for the Electrical/routing domain's one v1
// primitive, wire_route (native-kernel electrical wave 1; the
// geometry-contracts schema layer landed independently against the same wire
// field names, packages/geometry-contracts/src/operations.ts). Drives the
// REAL EvaluateOperations/ExecuteOperation dispatch path throughout (never a
// hand-seeded pool bypassing the dispatch switch this file also proves is
// wired), with startVertex/endVertex resolved through the SAME
// ResolveRefSlotStrict + SingleResolvedEntity vertex-kinded ('v') path
// datum_axis's own twoPoints mode already proves end to end
// (catalog_wave1_test.cpp's DatumAxisTwoPoints).
//
// Every numeric assertion is independently hand-derived in a comment beside
// it (this repo's own standard, set by sheet_metal_test.cpp and repeated by
// surfacing_test.cpp) — never copied from what electrical_routing_feature.cpp
// itself computes:
//
//   1. A straight point-to-point run (no waypoints) is, geometrically, a
//      plain cylinder: GeomAPI_Interpolate's natural (zero-second-derivative)
//      cubic through EXACTLY 2 points has no freedom to bend, so the result
//      is the straight segment between them. This is a genuinely independent
//      check of the general-purpose spline+sweep machinery against the
//      closed-form formula pi*r^2*length, using a box fixture whose diagonal
//      distance is the exact integer 17 (a 12x9x8 box corner-to-corner:
//      sqrt(12^2+9^2+8^2) = sqrt(289) = 17).
//   2. A route with a real waypoint bend: the volume is checked against
//      pi*r^2*L two ways — a RIGOROUS lower bound (arc length always exceeds
//      chord length for a genuinely bent path, and Weyl's tube formula says
//      volume == pi*r^2*(true arc length) EXACTLY whenever the tube does not
//      self-overlap — this file derives and states that formula below, not
//      just a hand-wave) and a reasoned +/-15% band around the polyline
//      (chord-length) estimate of pi*r^2*L for the actual OCCT-measured
//      volume, generous enough to cover a natural spline's real overshoot
//      around one gentle bump without being so loose it would pass a
//      badly-wrong sweep.
//   3./4. A deliberately sharp 3-point corner refuses
//      E_WIRE_ROUTE_BEND_TOO_TIGHT against a large MBR ask, while the exact
//      same corner shape at 1/100th the scale of a generous MBR succeeds —
//      proving the check is neither always-refusing nor a no-op.
//   5. Coincident startVertex/endVertex with no waypoints refuses
//      E_WIRE_ROUTE_DEGENERATE.
//   6. Naming: element naming stays non-throwing and mints via
//      AddDerivedPrimitive; a registry-less evaluation refuses
//      UNSUPPORTED_OPERATION (the edge_flange/datum precedent); and a
//      DIRECT, standalone empirical test of NamingRegistry::HarvestOperation
//      against a wire_route-shaped construction with NO consumed operand
//      (mirroring wire_route's own real architecture) confirms — rather than
//      merely asserting — that it cannot attribute a result, the concrete
//      finding electrical_routing_feature.hpp's own NAMING paragraph cites.
#include <atomic>
#include <cmath>
#include <cstdio>
#include <string>
#include <vector>

#include <BRepBuilderAPI_MakeEdge.hxx>
#include <BRepBuilderAPI_MakeWire.hxx>
#include <BRepOffsetAPI_MakePipeShell.hxx>
#include <BRepTools_History.hxx>
#include <NCollection_List.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp_Explorer.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Wire.hxx>
#include <gp_Ax2.hxx>
#include <gp_Circ.hxx>
#include <gp_Dir.hxx>
#include <gp_Pnt.hxx>
#include <nlohmann/json.hpp>

#include "electrical_routing_feature.hpp"
#include "element_names.hpp"
#include "geometry.hpp"
#include "local_operation_history.hpp"
#include "naming_registry.hpp"

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

void checkNear(const double actual, const double expected, const double tolerance,
               const std::string& label) {
  if (std::abs(actual - expected) <= tolerance) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s (expected %.6f, got %.6f)\n", label.c_str(), expected, actual);
    g_failures += 1;
  }
}

constexpr double kPi = 3.14159265358979323846;

// --- Operation / AST builders (the wire form the parser emits; §3 mirror —
// the SAME shape catalog_wave1_test.cpp's own builders produce, reproduced
// locally per this codebase's per-test-file convention). -------------------

nlohmann::json BoxOperation(const std::string& id, const std::string& bodyId, const double width,
                            const double depth, const double height) {
  return {
      {"id", id},
      {"type", "create_box"},
      {"outputBodyId", bodyId},
      {"parameters",
       {{"width", width},
        {"depth", depth},
        {"height", height},
        {"placement",
         {{"origin", {0.0, 0.0, 0.0}},
          {"zDirection", {0.0, 0.0, 1.0}},
          {"xDirection", {1.0, 0.0, 0.0}}}}}},
  };
}

nlohmann::json AsArray(std::initializer_list<nlohmann::json> items) {
  nlohmann::json array = nlohmann::json::array();
  for (const nlohmann::json& item : items)
    array.push_back(item);
  return array;
}

nlohmann::json ArgPoint(const double x, const double y, const double z) {
  return {{"arg", "point"}, {"value", {x, y, z}}};
}

nlohmann::json Filter(const std::string& name, std::initializer_list<nlohmann::json> args = {}) {
  return {{"name", name}, {"args", AsArray(args)}};
}

nlohmann::json SrcOp(const std::string& id) { return {{"source", "op"}, {"opId", id}}; }

nlohmann::json Query(const std::string& kind, std::initializer_list<nlohmann::json> scope,
                     std::initializer_list<nlohmann::json> filters = {}) {
  return {{"kind", kind}, {"scope", AsArray(scope)}, {"filters", AsArray(filters)}};
}

// The kernel-wire ref slot (operationRefWireSchema) — matches
// wireRouteOperationSchemaWith's own vertexRef shape
// (packages/geometry-contracts/src/operations.ts).
nlohmann::json AstRef(const nlohmann::json& ast, const std::string& arity = "one",
                      const std::string& onEmpty = "error") {
  return {
      {"ast", ast}, {"arity", arity}, {"anchors", nlohmann::json::array()}, {"onEmpty", onEmpty}};
}

// A vertex ref slot picking the box corner AT the given point exactly — the
// datum_axis twoPoints precedent (catalog_wave1_test.cpp's own
// DatumAxisTwoPoints/DatumAxisCoincidentPoints).
nlohmann::json VertexRefAt(const std::string& boxOperationId, const double x, const double y,
                           const double z) {
  return AstRef(Query("vertices", {SrcOp(boxOperationId)}, {Filter("at", {ArgPoint(x, y, z)})}));
}

nlohmann::json WireRouteOperation(const std::string& id, const std::string& bodyId,
                                  const nlohmann::json& startVertex,
                                  const nlohmann::json& endVertex, const nlohmann::json& waypoints,
                                  const double diameterMm, const double minimumBendRadiusMm) {
  return {
      {"id", id},
      {"type", "wire_route"},
      {"outputBodyId", bodyId},
      {"parameters",
       {{"startVertex", startVertex},
        {"endVertex", endVertex},
        {"waypoints", waypoints},
        {"diameterMm", diameterMm},
        {"minimumBendRadiusMm", minimumBendRadiusMm},
        {"wireType", "wire"}}},
  };
}

// --- Harness (the surfacing_test.cpp / catalog_wave1_test.cpp shape). ------

struct RegistryRun final {
  aeth::NamingRegistry registry;
  std::vector<aeth::EvaluatedBody> bodies;
  std::atomic_bool cancelled{false};
};

/// Runs a full JSON program through the REAL EvaluateOperations dispatch,
/// registry-threaded — the only way startVertex/endVertex can resolve at
/// all, and the same call this file's dispatch-wiring claim rests on.
void EvaluateInto(RegistryRun& run, const nlohmann::json& program) {
  run.bodies = aeth::EvaluateOperations(program, run.cancelled, nullptr, &run.registry);
}

const aeth::EvaluatedBody& FindBody(const std::vector<aeth::EvaluatedBody>& bodies,
                                    const std::string& bodyId) {
  for (const aeth::EvaluatedBody& body : bodies) {
    if (body.bodyId == bodyId)
      return body;
  }
  throw std::runtime_error("test fixture: body not found: " + bodyId);
}

struct Refusal final {
  std::string kind; // "operation" | "selector" | "reference-missing" | "none" | "other"
  std::string code;
  std::string operationId;
  std::string message;
  nlohmann::json details;
};

/// Runs a full JSON program through the REAL dispatch, catching every typed
/// refusal this codebase throws — the surfacing_test.cpp shape.
Refusal RunProgramExpectingRefusal(const nlohmann::json& program, const bool withRegistry) {
  std::atomic_bool cancelled{false};
  try {
    if (withRegistry) {
      aeth::NamingRegistry registry;
      aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
    } else {
      aeth::EvaluateOperations(program, cancelled, nullptr, nullptr);
    }
    return {"none", "", "", "", {}};
  } catch (const aeth::SelectorFailure& error) {
    return {"selector", error.Code(), error.OperationId(), error.what(), error.Details()};
  } catch (const aeth::OperationFailure& error) {
    return {"operation", error.Code(), error.OperationId(), error.what(), error.Details()};
  } catch (const aeth::ReferenceMissing& error) {
    return {"reference-missing", "", error.OperationId(), error.what(), {}};
  } catch (const std::exception& error) {
    return {"other", "", "", error.what(), {}};
  }
}

// --- 1. A straight point-to-point run IS a plain cylinder. -----------------

void WireRouteStraightRunMatchesCylinderVolume() {
  std::printf("wire_route with no waypoints between two box corners is EXACTLY a cylinder: volume "
              "== pi*r^2*length against the closed-form formula:\n");
  // Box 12 x 9 x 8, corner-anchored at the origin per PlacementFrame's own
  // base-center convention (verified against geometry.cpp's EvaluateBox):
  // corner_min = (-width/2, -depth/2, 0) = (-6, -4.5, 0);
  // corner_max = ( width/2,  depth/2, height) = (6, 4.5, 8).
  // Hand-derived diagonal distance: sqrt(12^2 + 9^2 + 8^2)
  //   = sqrt(144 + 81 + 64) = sqrt(289) = 17 EXACTLY.
  constexpr double kWidth = 12.0, kDepth = 9.0, kHeight = 8.0;
  constexpr double kExpectedLength = 17.0;
  constexpr double kDiameter = 2.0; // radius 1.
  const std::string boxOp = "e0000000-0000-4000-8000-000000000001";
  const std::string routeOp = "e0000000-0000-4000-8000-0000000000f1";
  const std::string routeBody = "e0000000-0000-4000-8000-0000000000f2";

  RegistryRun run;
  EvaluateInto(
      run,
      nlohmann::json::array(
          {BoxOperation(boxOp, "e0000000-0000-4000-8000-00000000000b", kWidth, kDepth, kHeight),
           WireRouteOperation(routeOp, routeBody, VertexRefAt(boxOp, -6.0, -4.5, 0.0),
                              VertexRefAt(boxOp, 6.0, 4.5, kHeight), nlohmann::json::array(),
                              kDiameter, /*minimumBendRadiusMm=*/0.5)}));

  const aeth::EvaluatedBody& result = FindBody(run.bodies, routeBody);
  check(result.probes.valid && result.probes.solidCount == 1, "the straight route is one valid "
                                                              "solid");
  check(result.probes.faceCount == 3, "a straight route has exactly 3 faces (2 flat caps + 1 "
                                      "cylindrical lateral face), the same topology as a plain "
                                      "cylinder primitive");
  const double radius = kDiameter / 2.0;
  const double expectedVolume = kPi * radius * radius * kExpectedLength;
  checkNear(result.probes.volume, expectedVolume, expectedVolume * 1e-6,
            "straight route volume == pi*r^2*length exactly (pi*1^2*17)");
  // The box itself is also still live and unconsumed (wire_route reads, never
  // consumes, its endpoint bodies — the wire contract's own stated rule).
  bool boxStillLive = false;
  for (const aeth::EvaluatedBody& body : run.bodies) {
    if (body.operationId == boxOp)
      boxStillLive = true;
  }
  check(boxStillLive, "the box startVertex/endVertex were read from stays live and unconsumed");
}

// --- 2. A route with a real waypoint bend. ----------------------------------

void WireRouteCurvedPathVolumeNearLengthTimesArea() {
  std::printf("wire_route with one waypoint bend produces a single valid solid whose volume is "
              "close to (a real curve, not required to exactly equal) length-along-curve * "
              "cross-section-area:\n");
  // Box 40 x 30 x 20 (catalog_wave1_test.cpp's own box, corners re-derived
  // the same way): corner_min = (-20,-15,0), and (20,15,0) is another
  // bottom-face corner. Hand-derived chord distance between them:
  // sqrt(40^2 + 30^2) = sqrt(1600+900) = sqrt(2500) = 50 EXACTLY.
  // The waypoint (0,0,25) bumps well above the segment joining them, a
  // genuinely non-planar-with-the-endpoints... actually a real bend in 3D:
  // both legs have hand-derived length sqrt(20^2+15^2+25^2) = sqrt(1250)
  // = 25*sqrt(2) ~= 35.35533906, so the 2-leg POLYLINE (chord) length is
  // 2*25*sqrt(2) = 50*sqrt(2) ~= 70.71067812 — a rigorous LOWER bound on the
  // true spline arc length (a straight chord is never longer than the curve
  // connecting its own endpoints).
  constexpr double kWidth = 40.0, kDepth = 30.0, kHeight = 20.0;
  constexpr double kDiameter = 1.0; // radius 0.5 -- tiny relative to the
                                    // path's tens-of-mm scale, so the tube
                                    // cannot self-overlap anywhere on this
                                    // gentle a bend (Weyl's tube-formula
                                    // precondition, see below).
  constexpr double kMinimumBendRadius = 3.0;
  const std::string boxOp = "e0000000-0000-4000-8000-000000000002";
  const std::string routeOp = "e0000000-0000-4000-8000-0000000000f3";
  const std::string routeBody = "e0000000-0000-4000-8000-0000000000f4";

  RegistryRun run;
  EvaluateInto(
      run,
      nlohmann::json::array(
          {BoxOperation(boxOp, "e0000000-0000-4000-8000-00000000000c", kWidth, kDepth, kHeight),
           WireRouteOperation(routeOp, routeBody, VertexRefAt(boxOp, -20.0, -15.0, 0.0),
                              VertexRefAt(boxOp, 20.0, 15.0, 0.0),
                              nlohmann::json::array({{0.0, 0.0, 25.0}}), kDiameter,
                              kMinimumBendRadius)}));

  const aeth::EvaluatedBody& result = FindBody(run.bodies, routeBody);
  check(result.probes.valid && result.probes.solidCount == 1, "the curved route is one single "
                                                              "valid solid");

  const double radius = kDiameter / 2.0;
  const double polylineLength = 2.0 * std::sqrt(20.0 * 20.0 + 15.0 * 15.0 + 25.0 * 25.0);
  const double polylineVolume = kPi * radius * radius * polylineLength;
  // RIGOROUS lower bound, not a fudge: for a tube of constant circular
  // cross-section radius r swept perpendicular to a smooth space curve of
  // arc length L with no self-overlap, the enclosed volume is EXACTLY
  // pi*r^2*L (Weyl's tube formula — derivable directly from the sweep's own
  // Jacobian: parametrize the tube by arc length s, cross-section radius
  // rho in [0,r], and angle theta; the volume element reduces to
  // rho*(1 - rho*kappa(s)*cos(theta)) drho dtheta ds, and integrating theta
  // over its full 2*pi period kills the cos(theta) curvature term
  // completely regardless of kappa(s) — leaving exactly pi*r^2 per unit
  // arc length, hence pi*r^2*L overall). True arc length is always >=
  // chord (polyline) length for any curve joining the same ordered points
  // (each straight chord is the SHORTEST path between its own endpoints),
  // so volume > polylineVolume is a proven inequality here, not a
  // heuristic — PROVIDED the tube does not self-overlap, guaranteed by this
  // fixture's tiny 0.5mm radius against a path whose own scale is tens of
  // mm (confirmed operationally too: the operation did not refuse
  // E_WIRE_ROUTE_BEND_TOO_TIGHT above, so every SAMPLED radius of curvature
  // already exceeded kMinimumBendRadius (3mm), itself six times this
  // fixture's own tube radius).
  check(result.probes.volume > polylineVolume,
        "curved route volume EXCEEDS pi*r^2*(chord length) -- a rigorous lower bound (Weyl's tube "
        "formula + arc length >= chord length), not a heuristic");
  // Upper band: a natural cubic spline's overshoot around ONE gentle bump
  // (bump height comparable to, not wildly exceeding, the leg lengths) is a
  // modest double-digit percentage of the chord length, not an
  // order-of-magnitude effect -- 15% is generous headroom for that
  // overshoot while still being a meaningful check (it would catch the
  // sweep being badly wrong, e.g. at half or double the right volume).
  checkNear(result.probes.volume, polylineVolume, polylineVolume * 0.15,
            "curved route volume is within a reasoned +/-15% band of pi*r^2*(chord length), "
            "consistent with a modest smooth-spline overshoot around one gentle bump");
}

// --- 3. A deliberately tight bend refuses; the same shape at a scale the
// MBR respects succeeds. ------------------------------------------------

void WireRouteBendTooTightRefusal() {
  std::printf("wire_route with a deliberately sharp 3mm right-angle corner against a 100mm MBR "
              "ask refuses E_WIRE_ROUTE_BEND_TOO_TIGHT:\n");
  // Box 20x20x20; start = bottom corner (-10,-10,0), end = the corner
  // directly above it, (-10,-10,20). Two waypoints, (-7,-10,0) then
  // (-7,-7,0), sit right next to the start: (-10,-10,0)->(-7,-10,0) is a
  // 3mm leg along +x, and (-7,-10,0)->(-7,-7,0) a 3mm leg along +y -- a
  // sharp, genuine 90-degree corner AT (-7,-10,0) with 3mm legs. A natural
  // interpolating spline through a genuine corner concentrates curvature
  // there at a radius on the order of the leg lengths themselves
  // (single-digit mm) -- overwhelmingly tighter than a 100mm MBR ask, so
  // this does not depend on hand-deriving the EXACT curvature value, only
  // on the corner being sharp relative to a deliberately huge MBR. (The
  // final long diagonal leg up to `end` is deliberately irrelevant here --
  // it is gentle by comparison and is not where the violation comes from.)
  const std::string boxOp = "e0000000-0000-4000-8000-000000000003";
  const std::string routeOp = "e0000000-0000-4000-8000-0000000000f5";
  const nlohmann::json program = nlohmann::json::array(
      {BoxOperation(boxOp, "e0000000-0000-4000-8000-00000000000d", 20.0, 20.0, 20.0),
       WireRouteOperation(
           routeOp, "e0000000-0000-4000-8000-0000000000f6", VertexRefAt(boxOp, -10.0, -10.0, 0.0),
           VertexRefAt(boxOp, -10.0, -10.0, 20.0),
           nlohmann::json::array({{-7.0, -10.0, 0.0}, {-7.0, -7.0, 0.0}}), 1.0, 100.0)});
  const Refusal refusal = RunProgramExpectingRefusal(program, /*withRegistry=*/true);
  check(refusal.kind == "operation" && refusal.code == "GEOMETRY_FAILED" &&
            refusal.details.value("routeCode", "") == "E_WIRE_ROUTE_BEND_TOO_TIGHT",
        "a sharp corner against a 100mm MBR ask -> E_WIRE_ROUTE_BEND_TOO_TIGHT, never a crash "
        "(through full ExecuteOperation dispatch)");
  if (refusal.kind == "operation") {
    const double tightest = refusal.details.value("tightestRadiusMm", -1.0);
    check(tightest >= 0.0 && tightest < 100.0,
          "the failure detail carries a tightest radius that is itself < minimumBendRadiusMm, the "
          "self-consistency the refusal condition requires");
  }
}

void WireRouteGentleBendSucceeds() {
  std::printf("wire_route with the SAME corner shape scaled up to a gentle, large-radius bend "
              "against a modest MBR ask correctly SUCCEEDS (the check is not trivially "
              "always-refusing):\n");
  // The same right-angle corner topology as the refusal test above (box
  // corner start, two waypoints forming a 90-degree corner, box corner
  // end), with the corner's own legs widened from 3mm to 100mm (on a
  // 200x200x200 box) against a modest 5mm MBR ask -- a corner this broad
  // has a radius of curvature on the order of its own leg lengths
  // (~100mm), comfortably above 5mm.
  const std::string boxOp = "e0000000-0000-4000-8000-000000000004";
  const std::string routeOp = "e0000000-0000-4000-8000-0000000000f7";
  const std::string routeBody = "e0000000-0000-4000-8000-0000000000f8";
  RegistryRun run;
  EvaluateInto(
      run, nlohmann::json::array(
               {BoxOperation(boxOp, "e0000000-0000-4000-8000-00000000000e", 200.0, 200.0, 200.0),
                WireRouteOperation(routeOp, routeBody, VertexRefAt(boxOp, -100.0, -100.0, 0.0),
                                   VertexRefAt(boxOp, -100.0, -100.0, 200.0),
                                   nlohmann::json::array({{0.0, -100.0, 0.0}, {0.0, 0.0, 0.0}}),
                                   2.0, 5.0)}));
  const aeth::EvaluatedBody& result = FindBody(run.bodies, routeBody);
  check(result.probes.valid && result.probes.solidCount == 1,
        "the gentle-scale corner respects a 5mm MBR ask and succeeds as one valid solid");
}

// --- 4. Degenerate coincident endpoints refuse. -----------------------------

void WireRouteDegenerateCoincidentEndpointsRefusal() {
  std::printf("wire_route with startVertex == endVertex and no waypoints refuses "
              "E_WIRE_ROUTE_DEGENERATE:\n");
  const std::string boxOp = "e0000000-0000-4000-8000-000000000005";
  const std::string routeOp = "e0000000-0000-4000-8000-0000000000f9";
  const nlohmann::json sameVertex = VertexRefAt(boxOp, -5.0, -5.0, 0.0);
  const nlohmann::json program = nlohmann::json::array(
      {BoxOperation(boxOp, "e0000000-0000-4000-8000-00000000000f", 10.0, 10.0, 10.0),
       WireRouteOperation(routeOp, "e0000000-0000-4000-8000-0000000000fa", sameVertex, sameVertex,
                          nlohmann::json::array(), 1.0, 5.0)});
  const Refusal refusal = RunProgramExpectingRefusal(program, /*withRegistry=*/true);
  check(refusal.kind == "operation" && refusal.code == "INVALID_REQUEST" &&
            refusal.details.value("routeCode", "") == "E_WIRE_ROUTE_DEGENERATE",
        "startVertex == endVertex with no waypoints -> E_WIRE_ROUTE_DEGENERATE, never a crash "
        "(through full ExecuteOperation dispatch)");
}

void WireRouteConsecutiveWaypointCoincidenceRefusal() {
  std::printf("wire_route with a waypoint coincident with its immediate neighbor also refuses "
              "E_WIRE_ROUTE_DEGENERATE (not just the whole-sequence coincident-endpoints case):\n");
  const std::string boxOp = "e0000000-0000-4000-8000-000000000006";
  const std::string routeOp = "e0000000-0000-4000-8000-0000000000fb";
  const nlohmann::json program = nlohmann::json::array(
      {BoxOperation(boxOp, "e0000000-0000-4000-8000-000000000010", 10.0, 10.0, 10.0),
       WireRouteOperation(routeOp, "e0000000-0000-4000-8000-0000000000fc",
                          VertexRefAt(boxOp, -5.0, -5.0, 0.0), VertexRefAt(boxOp, 5.0, 5.0, 10.0),
                          // The second waypoint exactly repeats the first -- a consecutive
                          // coincidence in the MIDDLE of the sequence, not at the ends.
                          nlohmann::json::array({{0.0, 0.0, 5.0}, {0.0, 0.0, 5.0}}), 1.0, 5.0)});
  const Refusal refusal = RunProgramExpectingRefusal(program, /*withRegistry=*/true);
  check(refusal.kind == "operation" && refusal.code == "INVALID_REQUEST" &&
            refusal.details.value("routeCode", "") == "E_WIRE_ROUTE_DEGENERATE",
        "two consecutive coincident waypoints -> E_WIRE_ROUTE_DEGENERATE");
}

// --- 5. Naming. --------------------------------------------------------------

void WireRouteNamingMintsFreshWithoutThrowing() {
  std::printf("wire_route with element naming active mints its result fresh (AddDerivedPrimitive) "
              "without throwing:\n");
  const std::string boxOp = "e0000000-0000-4000-8000-000000000007";
  const std::string routeOp = "e0000000-0000-4000-8000-0000000000fd";
  const std::string routeBody = "e0000000-0000-4000-8000-0000000000fe";
  RegistryRun run; // EvaluateInto always threads a registry (and therefore a
                   // book) — this test's whole point is that the call
                   // completes without throwing despite naming being active.
  bool threw = false;
  try {
    EvaluateInto(run,
                 nlohmann::json::array(
                     {BoxOperation(boxOp, "e0000000-0000-4000-8000-000000000011", 10.0, 10.0, 10.0),
                      WireRouteOperation(routeOp, routeBody, VertexRefAt(boxOp, -5.0, -5.0, 0.0),
                                         VertexRefAt(boxOp, 5.0, 5.0, 10.0),
                                         nlohmann::json::array(), 1.0, 0.5)}));
  } catch (const std::exception& error) {
    std::printf("  FAIL naming-enabled call threw: %s\n", error.what());
    threw = true;
    g_failures += 1;
  }
  check(!threw, "naming-enabled wire_route does not throw");
  if (threw)
    return;
  // The naming system names faces/edges/vertices only (NamingRecord's own
  // `kind` field is 'f'/'e'/'v', never a solid/shell wrapper — the
  // ThickenNamingNormalDoesNotThrow precedent in surfacing_test.cpp checks
  // the identical thing the identical way for its own solid result), so
  // total coverage means every FACE of the routed pipe is named, not the
  // solid itself.
  const aeth::EvaluatedBody& result = FindBody(run.bodies, routeBody);
  bool everyFaceNamed = true;
  for (TopExp_Explorer explorer(result.shape, TopAbs_FACE); explorer.More(); explorer.Next()) {
    try {
      (void)run.registry.Book().NameOf(explorer.Current());
    } catch (const std::exception&) {
      everyFaceNamed = false;
      break;
    }
  }
  check(everyFaceNamed, "every face of the routed pipe solid has a book lineage name (total "
                        "coverage, AddDerivedPrimitive)");
}

void WireRouteRegistryLessRefusal() {
  std::printf("wire_route with no naming registry threaded refuses UNSUPPORTED_OPERATION (the "
              "edge_flange/datum registry-guard precedent, since startVertex/endVertex cannot "
              "resolve without one):\n");
  const std::string boxOp = "e0000000-0000-4000-8000-000000000008";
  const std::string routeOp = "e0000000-0000-4000-8000-0000000000ff";
  const nlohmann::json program = nlohmann::json::array(
      {BoxOperation(boxOp, "e0000000-0000-4000-8000-000000000012", 10.0, 10.0, 10.0),
       WireRouteOperation(routeOp, "e0000000-0000-4000-8000-000000000100",
                          VertexRefAt(boxOp, -5.0, -5.0, 0.0), VertexRefAt(boxOp, 5.0, 5.0, 10.0),
                          nlohmann::json::array(), 1.0, 0.5)});
  const Refusal refusal = RunProgramExpectingRefusal(program, /*withRegistry=*/false);
  check(refusal.kind == "operation" && refusal.code == "UNSUPPORTED_OPERATION",
        "registry-less evaluation -> attributed UNSUPPORTED_OPERATION, never a crash");
}

/// Empirical investigation (electrical_routing_feature.hpp's own NAMING
/// paragraph): does NamingRegistry::HarvestOperation actually succeed or
/// fail when given a wire_route-shaped construction — a real
/// BRepBuilderAPI_MakeShape history (BRepOffsetAPI_MakePipeShell, exactly
/// the class EvaluateWireRoute itself uses) but with ZERO consumed operands,
/// matching wire_route's own real architecture (its spine/profile are built
/// from resolved point coordinates, never from an existing sub-shape)? This
/// does not call EvaluateWireRoute itself — it drives NamingRegistry
/// directly against a hand-built pipe, because the question under test is
/// the REGISTRY's own contract on an empty-Input harvest, not this file's
/// geometry (already covered by the tests above).
void WireRouteHarvestOperationEmptyInputInvestigation() {
  std::printf("empirical investigation: HarvestOperation on a wire_route-shaped construction (a "
              "real BRepOffsetAPI_MakePipeShell history) with NO consumed operand cannot "
              "attribute a result -- testing this directly rather than assuming it:\n");
  const gp_Pnt p1(0.0, 0.0, 0.0);
  const gp_Pnt p2(10.0, 0.0, 0.0);
  const TopoDS_Edge spineEdge = BRepBuilderAPI_MakeEdge(p1, p2);
  const TopoDS_Wire spine = BRepBuilderAPI_MakeWire(spineEdge).Wire();
  const gp_Ax2 profileFrame(p1, gp_Dir(1.0, 0.0, 0.0));
  const gp_Circ profileCircle(profileFrame, 1.0);
  const TopoDS_Edge profileEdge = BRepBuilderAPI_MakeEdge(profileCircle);
  const TopoDS_Wire profileWire = BRepBuilderAPI_MakeWire(profileEdge).Wire();

  BRepOffsetAPI_MakePipeShell pipe(spine);
  pipe.Add(profileWire, /*WithContact=*/false, /*WithCorrection=*/true);
  pipe.Build();
  if (!pipe.IsDone() || !pipe.MakeSolid()) {
    check(false, "test fixture: the investigation's own pipe construction failed");
    return;
  }
  const TopoDS_Shape pipeShape = pipe.Shape();

  // EMPTY arguments list: wire_route's own real situation (no consumed
  // operand at all), unlike every real HarvestOperation call site in this
  // codebase (fillet/hole/boolean/etc.), which always passes at least the
  // consumed target.
  const NCollection_List<TopoDS_Shape> noArguments;
  aeth::LocalOperationHistorySource historySource(pipe, pipeShape);
  const occ::handle<BRepTools_History> history = new BRepTools_History(noArguments, historySource);

  aeth::NamingRegistry registry;
  std::atomic_bool cancelled{false};
  const std::string operationId = "e0000000-0000-4000-8000-000000000101";

  bool threw = false;
  std::string observedMessage;
  try {
    // The book's own naming pass must run first (every real HarvestOperation
    // call site in this codebase pairs the two calls this way — see e.g.
    // EvaluateFillet in geometry.cpp) — empty inputs here too, mirroring
    // wire_route's own real call shape exactly.
    registry.Book().ApplyOperation(operationId, {}, pipeShape, *history, cancelled);
    registry.HarvestOperation(operationId, aeth::NamingRegistry::OperationClass::WireRoute, {},
                              pipeShape, *history, cancelled);
  } catch (const std::exception& error) {
    threw = true;
    observedMessage = error.what();
  }
  check(threw,
        "HarvestOperation (or the book's own ApplyOperation naming pass that must precede it) "
        "REFUSES when there is no consumed operand to attribute history from -- confirming "
        "electrical_routing_feature.cpp's AddDerivedPrimitive design choice by direct "
        "measurement, not architecture-only reasoning");
  std::printf("  (observed: %s)\n", observedMessage.c_str());
}

} // namespace

int main() {
  try {
    WireRouteStraightRunMatchesCylinderVolume();
    WireRouteCurvedPathVolumeNearLengthTimesArea();
    WireRouteBendTooTightRefusal();
    WireRouteGentleBendSucceeds();
    WireRouteDegenerateCoincidentEndpointsRefusal();
    WireRouteConsecutiveWaypointCoincidenceRefusal();
    WireRouteNamingMintsFreshWithoutThrowing();
    WireRouteRegistryLessRefusal();
    WireRouteHarvestOperationEmptyInputInvestigation();
  } catch (const std::exception& error) {
    std::printf("FATAL: uncaught exception: %s\n", error.what());
    return 1;
  }
  if (g_failures == 0) {
    std::printf("\nALL ELECTRICAL ROUTING TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d ELECTRICAL ROUTING CHECK(S) FAILED\n", g_failures);
  return 1;
}
