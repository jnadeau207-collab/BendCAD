// Native integration tests for the sheet-metal wave — base_flange,
// edge_flange, unfold (native/kernel-host only; the geometry-contracts
// schema/registry layer is landed independently against the same wire field
// names). They drive the REAL EvaluateOperations path (registry-threaded, so
// edge_flange's `edge` ref slot resolves) and pin, per the assignment's own
// "analytically known geometry" discipline (the same discipline the
// simulation solver's "uniaxial bar stress exact at sigma=F/A" fixture uses):
//
//   1. base_flange from a rectangular profile: exact volume (area*thickness)
//      and exact bounding box.
//   2. edge_flange at 90 degrees on a rectangular base_flange: the flange
//      face is measurably perpendicular to the base face, the bend region is
//      a cylindrical face PAIR of exactly the requested inside/outside
//      radius, and the flange panel's flat length (measured from its own
//      tangent line, per the wire contract) is exactly flangeLengthMm.
//   3. unfold of that exact 2-body part: the flat body's total extent along
//      the unfold direction equals the hand-computed
//      (baseTangentLength + BA + flangeLengthMm), where BA is the bend
//      allowance formula and baseTangentLength is the base panel's own
//      profile width minus its outer fillet's tangent setback — both
//      independently re-derived in this file, not copied from production
//      code, so the test cannot pass by construction.
//   4. Typed refusals: edge_flange on a non-boundary edge (a cone's circular
//      rim, closed — degenerate endpoints) -> E_EDGE_FLANGE_NOT_PLANAR_
//      BOUNDARY; unfold on a body with no bends -> E_UNFOLD_NO_BENDS.
#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstdio>
#include <initializer_list>
#include <optional>
#include <string>
#include <vector>

#include <BRepGProp.hxx>
#include <BRep_Tool.hxx>
#include <GProp_GProps.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp_Explorer.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Vertex.hxx>
#include <gp_Pnt.hxx>
#include <nlohmann/json.hpp>

#include "element_names.hpp"
#include "geometry.hpp"
#include "geometry_measures.hpp"
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
constexpr double kDegreesToRadians = kPi / 180.0;

// --- Operation builders ------------------------------------------------------

nlohmann::json Placement(const std::array<double, 3>& origin,
                         const std::array<double, 3>& zDirection = {0.0, 0.0, 1.0},
                         const std::array<double, 3>& xDirection = {1.0, 0.0, 0.0}) {
  return {{"origin", origin}, {"zDirection", zDirection}, {"xDirection", xDirection}};
}

nlohmann::json RectangleProfileOperation(const std::string& id, const double width,
                                         const double depth, const std::array<double, 3>& origin) {
  return {
      {"id", id},
      {"type", "create_profile"},
      {"outputProfileId", "91000000-0000-4000-8000-000000000001"},
      {"parameters",
       {{"shape", {{"kind", "rectangle"}, {"width", width}, {"depth", depth}}},
        {"placement", Placement(origin)}}},
  };
}

nlohmann::json BaseFlangeOperation(const std::string& id, const std::string& bodyId,
                                   const std::string& profileId, const double thicknessMm,
                                   const std::string& direction = "normal") {
  return {
      {"id", id},
      {"type", "base_flange"},
      {"outputBodyId", bodyId},
      {"parameters",
       {{"profileOperationId", profileId}, {"thicknessMm", thicknessMm}, {"direction", direction}}},
  };
}

nlohmann::json ConeOperation(const std::string& id, const std::string& bodyId,
                             const double radiusBottom, const double height,
                             const std::array<double, 3>& origin) {
  return {
      {"id", id},
      {"type", "create_cone"},
      {"outputBodyId", bodyId},
      {"parameters",
       {{"radiusBottom", radiusBottom},
        {"radiusTop", 0.0},
        {"height", height},
        {"placement", Placement(origin)}}},
  };
}

// --- AST builders (the wire form the parser emits — catalog_wave2_test.cpp's
// own shape, reused so the edge_flange `edge` slot is built the identical way
// fillet-v2/mirror/pattern refs already are). --------------------------------

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

nlohmann::json AstRef(const nlohmann::json& ast, const std::string& arity = "one",
                      const std::string& onEmpty = "error") {
  return {
      {"ast", ast}, {"arity", arity}, {"anchors", nlohmann::json::array()}, {"onEmpty", onEmpty}};
}

struct EdgeFlangeParams final {
  std::string targetOperationId;
  nlohmann::json edgeRef;
  double flangeLengthMm{};
  double bendAngleDeg{};
  double bendRadiusMm{};
  double thicknessMm{};
  double kFactor{0.44};
  std::string reliefType{"rectangular"};
  double reliefDepthMm{3.0};
};

nlohmann::json EdgeFlangeOperation(const std::string& id, const std::string& bodyId,
                                   const EdgeFlangeParams& p) {
  return {
      {"id", id},
      {"type", "edge_flange"},
      {"outputBodyId", bodyId},
      {"parameters",
       {{"targetOperationId", p.targetOperationId},
        {"edge", p.edgeRef},
        {"flangeLengthMm", p.flangeLengthMm},
        {"bendAngleDeg", p.bendAngleDeg},
        {"bendRadiusMm", p.bendRadiusMm},
        {"thicknessMm", p.thicknessMm},
        {"kFactor", p.kFactor},
        {"reliefType", p.reliefType},
        {"reliefDepthMm", p.reliefDepthMm}}},
  };
}

nlohmann::json UnfoldOperation(const std::string& id, const std::string& foldedBodyId,
                               const std::string& flatBodyId,
                               const std::string& targetOperationId) {
  return {
      {"id", id},
      {"type", "unfold"},
      {"outputBodyId", foldedBodyId},
      {"outputBodyIds", {foldedBodyId, flatBodyId}},
      {"parameters", {{"targetOperationId", targetOperationId}}},
  };
}

// --- Harness (the catalog_wave2_test.cpp shape) ------------------------------

struct RegistryRun final {
  aeth::NamingRegistry registry;
  std::vector<aeth::EvaluatedBody> bodies;
  std::atomic_bool cancelled{false};
};

void EvaluateInto(RegistryRun& run, const nlohmann::json& program) {
  run.bodies = aeth::EvaluateOperations(program, run.cancelled, nullptr, &run.registry);
}

struct Refusal final {
  std::string kind;
  std::string code;
  std::string operationId;
  std::string message;
  nlohmann::json details;
};

Refusal RunExpectingRefusal(const nlohmann::json& program) {
  std::atomic_bool cancelled{false};
  try {
    aeth::NamingRegistry registry;
    aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
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

const aeth::EvaluatedBody* BodyOf(const std::vector<aeth::EvaluatedBody>& bodies,
                                  const std::string& operationId, const int outputIndex = 0) {
  for (const aeth::EvaluatedBody& body : bodies) {
    if (body.operationId == operationId && body.outputIndex == outputIndex)
      return &body;
  }
  return nullptr;
}

// --- Direct-topology geometry helpers (independent of this file's own
// production code paths — these just walk the returned TopoDS_Shape). -------

struct FaceSample final {
  TopoDS_Face face;
  std::string surfaceClass;
  double area{};
  aeth::Axis axis; // outward normal (plane) or cylinder axis (cylinder)
  std::optional<double> radius;
};

double FaceArea(const TopoDS_Face& face) {
  GProp_GProps properties;
  BRepGProp::SurfaceProperties(face, properties);
  return std::abs(properties.Mass());
}

std::vector<FaceSample> SampleFaces(const TopoDS_Shape& shape) {
  std::vector<FaceSample> faces;
  for (TopExp_Explorer explorer(shape, TopAbs_FACE); explorer.More(); explorer.Next()) {
    const TopoDS_Face face = TopoDS::Face(explorer.Current());
    FaceSample sample;
    sample.face = face;
    sample.surfaceClass = aeth::SurfaceClass(face);
    sample.area = FaceArea(face);
    sample.axis = aeth::SurfaceAxis(face);
    sample.radius = aeth::SurfaceRadius(face);
    faces.push_back(sample);
  }
  return faces;
}

bool SharesEdgeWith(const TopoDS_Face& a, const TopoDS_Face& b) {
  for (TopExp_Explorer edgesA(a, TopAbs_EDGE); edgesA.More(); edgesA.Next()) {
    for (TopExp_Explorer edgesB(b, TopAbs_EDGE); edgesB.More(); edgesB.Next()) {
      if (edgesA.Current().IsSame(edgesB.Current()))
        return true;
    }
  }
  return false;
}

// [minX, maxX, minY, maxY, minZ, maxZ] over a face's vertices — exact for a
// face whose boundary is straight lines and circular arcs sampled at their
// endpoints only where the extremum genuinely falls at a vertex, which is the
// case here: every face measured below is planar with straight boundary
// edges except at one tangent-line end, and that end is exactly the boundary
// this test is NOT measuring across (see each call site).
std::array<double, 6> VertexBounds(const TopoDS_Face& face) {
  std::array<double, 6> bounds{1e18, -1e18, 1e18, -1e18, 1e18, -1e18};
  for (TopExp_Explorer explorer(face, TopAbs_VERTEX); explorer.More(); explorer.Next()) {
    const gp_Pnt point = BRep_Tool::Pnt(TopoDS::Vertex(explorer.Current()));
    bounds[0] = std::min(bounds[0], point.X());
    bounds[1] = std::max(bounds[1], point.X());
    bounds[2] = std::min(bounds[2], point.Y());
    bounds[3] = std::max(bounds[3], point.Y());
    bounds[4] = std::min(bounds[4], point.Z());
    bounds[5] = std::max(bounds[5], point.Z());
  }
  return bounds;
}

// --- Shared fixture ids --------------------------------------------------

const std::string kProfileOp = "10000000-0000-4000-8000-000000000001";
const std::string kBaseFlangeOp = "20000000-0000-4000-8000-000000000002";
const std::string kEdgeFlangeOp = "30000000-0000-4000-8000-000000000003";
const std::string kUnfoldOp = "40000000-0000-4000-8000-000000000004";
const std::string kBaseFlangeBody = "20000000-0000-4000-8000-0000000000b1";
const std::string kEdgeFlangeBody = "30000000-0000-4000-8000-0000000000b1";
const std::string kFoldedBody = "40000000-0000-4000-8000-0000000000f0";
const std::string kFlatBody = "40000000-0000-4000-8000-0000000000f1";

constexpr double kBaseWidth = 40.0; // x extent [-20, 20]; edge_flange grows off the +x edge.
constexpr double kBaseDepth = 30.0; // y extent [-15, 15]; this is the bend-line length.
constexpr double kThickness = 2.0;
constexpr double kFlangeLength = 15.0;
constexpr double kBendAngleDeg = 90.0;
constexpr double kBendRadius = 1.0;
constexpr double kKFactor = 0.44;

nlohmann::json BuildTwoBodyProgram() {
  const nlohmann::json profile =
      RectangleProfileOperation(kProfileOp, kBaseWidth, kBaseDepth, {0.0, 0.0, 0.0});
  const nlohmann::json baseFlange =
      BaseFlangeOperation(kBaseFlangeOp, kBaseFlangeBody, kProfileOp, kThickness);
  // The edge on the TOP cap (z = thickness) running along y, at x = +width/2
  // — the midpoint (width/2, 0, thickness) lies on that edge and no other.
  EdgeFlangeParams params;
  params.targetOperationId = kBaseFlangeOp;
  params.edgeRef =
      AstRef(Query("edges", {SrcOp(kBaseFlangeOp)},
                   {Filter("line"), Filter("at", {ArgPoint(kBaseWidth / 2.0, 0.0, kThickness)})}));
  params.flangeLengthMm = kFlangeLength;
  params.bendAngleDeg = kBendAngleDeg;
  params.bendRadiusMm = kBendRadius;
  params.thicknessMm = kThickness;
  params.kFactor = kKFactor;
  const nlohmann::json edgeFlange = EdgeFlangeOperation(kEdgeFlangeOp, kEdgeFlangeBody, params);
  return nlohmann::json::array({profile, baseFlange, edgeFlange});
}

// --- 1. base_flange -----------------------------------------------------

void BaseFlangeVolumeAndBounds() {
  std::printf("base_flange produces the exact prism volume and bounding box:\n");
  RegistryRun run;
  EvaluateInto(run,
               nlohmann::json::array(
                   {RectangleProfileOperation(kProfileOp, kBaseWidth, kBaseDepth, {0.0, 0.0, 0.0}),
                    BaseFlangeOperation(kBaseFlangeOp, kBaseFlangeBody, kProfileOp, kThickness)}));
  const aeth::EvaluatedBody* body = BodyOf(run.bodies, kBaseFlangeOp);
  check(body != nullptr, "base_flange produced a visible body");
  if (body == nullptr)
    return;
  const aeth::ShapeProbes& probes = body->probes;
  check(probes.valid && probes.solidCount == 1, "the result is one valid solid");
  checkNear(probes.volume, kBaseWidth * kBaseDepth * kThickness, 1e-6,
            "volume == width * depth * thicknessMm (2400)");
  checkNear(probes.bounds[0], -kBaseWidth / 2.0, 1e-9, "xmin");
  checkNear(probes.bounds[3], kBaseWidth / 2.0, 1e-9, "xmax");
  checkNear(probes.bounds[1], -kBaseDepth / 2.0, 1e-9, "ymin");
  checkNear(probes.bounds[4], kBaseDepth / 2.0, 1e-9, "ymax");
  checkNear(probes.bounds[2], 0.0, 1e-9, "zmin (direction: normal starts at the profile plane)");
  checkNear(probes.bounds[5], kThickness, 1e-9, "zmax == thicknessMm");

  std::printf("base_flange direction: \"reverse\" sweeps the other way:\n");
  RegistryRun reversed;
  EvaluateInto(reversed,
               nlohmann::json::array(
                   {RectangleProfileOperation(kProfileOp, kBaseWidth, kBaseDepth, {0.0, 0.0, 0.0}),
                    BaseFlangeOperation(kBaseFlangeOp, kBaseFlangeBody, kProfileOp, kThickness,
                                        "reverse")}));
  const aeth::EvaluatedBody* reversedBody = BodyOf(reversed.bodies, kBaseFlangeOp);
  check(reversedBody != nullptr, "the reversed base_flange produced a visible body");
  if (reversedBody == nullptr)
    return;
  checkNear(reversedBody->probes.bounds[2], -kThickness, 1e-9, "zmin == -thicknessMm");
  checkNear(reversedBody->probes.bounds[5], 0.0, 1e-9, "zmax (swept toward -normal)");
}

// --- 2. edge_flange -------------------------------------------------------

void EdgeFlangeNinetyDegreeBend() {
  std::printf("edge_flange at 90 degrees: perpendicularity, bend radius, flat length:\n");
  RegistryRun run;
  EvaluateInto(run, BuildTwoBodyProgram());
  const aeth::EvaluatedBody* body = BodyOf(run.bodies, kEdgeFlangeOp);
  check(body != nullptr, "edge_flange produced a visible body");
  if (body == nullptr)
    return;
  check(body->probes.valid && body->probes.solidCount == 1, "the result is one valid solid");

  const std::vector<FaceSample> faces = SampleFaces(body->shape);

  std::vector<FaceSample> cylinders;
  for (const FaceSample& sample : faces) {
    if (sample.surfaceClass == "cylinder")
      cylinders.push_back(sample);
  }
  check(cylinders.size() == 2, "the bend region is exactly two cylindrical faces (inner + outer)");
  if (cylinders.size() == 2) {
    const double r0 = cylinders[0].radius.value_or(-1.0);
    const double r1 = cylinders[1].radius.value_or(-1.0);
    const double innerRadius = std::min(r0, r1);
    const double outerRadius = std::max(r0, r1);
    checkNear(innerRadius, kBendRadius, 1e-6, "inner bend radius == bendRadiusMm (1.0)");
    checkNear(outerRadius, kBendRadius + kThickness, 1e-6,
              "outer bend radius == bendRadiusMm + thicknessMm (3.0)");
  }

  // The base's own top cap: largest-area planar face with outward normal +Z.
  const FaceSample* baseTop = nullptr;
  for (const FaceSample& sample : faces) {
    if (sample.surfaceClass != "plane" || !sample.axis.has_value())
      continue;
    if ((*sample.axis)[2] < 0.99)
      continue;
    if (baseTop == nullptr || sample.area > baseTop->area)
      baseTop = &sample;
  }
  check(baseTop != nullptr, "the base panel's own top face survives, normal +Z");

  // The OUTER cylindrical face (the larger radius one) is tangent to the
  // flange's own OUTWARD face — find the largest Z-perpendicular planar face
  // that shares an edge with it.
  const FaceSample* outerCylinder = nullptr;
  for (const FaceSample& sample : cylinders) {
    if (outerCylinder == nullptr ||
        sample.radius.value_or(0.0) > outerCylinder->radius.value_or(0.0))
      outerCylinder = &sample;
  }
  const FaceSample* flangeFace = nullptr;
  if (outerCylinder != nullptr) {
    for (const FaceSample& sample : faces) {
      if (sample.surfaceClass != "plane" || !sample.axis.has_value())
        continue;
      if (std::abs((*sample.axis)[2]) > 0.01)
        continue; // Not perpendicular to Z -> not the standing flange face.
      if (!SharesEdgeWith(sample.face, outerCylinder->face))
        continue;
      if (flangeFace == nullptr || sample.area > flangeFace->area)
        flangeFace = &sample;
    }
  }
  check(flangeFace != nullptr, "the flange's own outward face was found (Z-perpendicular, tangent "
                               "to the outer bend cylinder)");

  if (baseTop != nullptr && flangeFace != nullptr) {
    const double dot = (*baseTop->axis)[0] * (*flangeFace->axis)[0] +
                       (*baseTop->axis)[1] * (*flangeFace->axis)[1] +
                       (*baseTop->axis)[2] * (*flangeFace->axis)[2];
    checkNear(dot, 0.0, 1e-6, "the flange face is measurably perpendicular to the base face");

    // At exactly a 90-degree bend the flange face is a vertical plane, so its
    // OWN flat length (tangent line to far end) is exactly its Z extent —
    // required to equal flangeLengthMm on the nose (the wire contract's own
    // "measured from the tangent line" ground truth).
    const std::array<double, 6> bounds = VertexBounds(flangeFace->face);
    checkNear(bounds[5] - bounds[4], kFlangeLength, 1e-3,
              "the flange panel's flat length (Z extent) == flangeLengthMm (15)");
  }
}

// --- 3. unfold -------------------------------------------------------------

void UnfoldFlatPatternLength() {
  std::printf("unfold reconstructs the analytically predicted flat-pattern length:\n");
  nlohmann::json program = BuildTwoBodyProgram();
  program.push_back(UnfoldOperation(kUnfoldOp, kFoldedBody, kFlatBody, kEdgeFlangeOp));
  RegistryRun run;
  EvaluateInto(run, program);

  const aeth::EvaluatedBody* folded = BodyOf(run.bodies, kUnfoldOp, 0);
  const aeth::EvaluatedBody* flat = BodyOf(run.bodies, kUnfoldOp, 1);
  check(folded != nullptr, "unfold's folded pass-through body is visible");
  check(flat != nullptr, "unfold's flat-pattern body is visible");
  if (folded == nullptr || flat == nullptr)
    return;
  check(folded->probes.valid && folded->probes.solidCount == 1,
        "the folded body is one valid solid");
  check(flat->probes.valid && flat->probes.solidCount == 1, "the flat body is one valid solid");

  // The folded body's own volume, independently re-derived here (not copied
  // from sheet_metal_feature.cpp) from first principles — NOT simply
  // base-plus-flat-flange material, because edge_flange's sharp-corner-then-
  // fillet construction does not exactly conserve that naive sum: rounding
  // the two creases changes the cross-sectional area by a real, calculable
  // amount. Both the pentagon (edge_flange's own new-material cross-section)
  // and the fillet corrections are re-derived independently below, by hand,
  // from the SAME pentagon vertex construction edge_flange's own header
  // comment documents (this file's job is to catch a wrong construction, so
  // it cannot just trust that construction's own code).
  //
  // The pentagon (in the {outwardInPlane, N} cross-section plane, one
  // thickness-by-extendedLength rectangle plus one right triangle of legs
  // thickness and thickness*sin(theta) — verified by decomposing the
  // pentagon hinge/farOuter/farInner/wedgeInner/innerHinge construction by
  // hand) has area extendedLength*t + 0.5*t^2*sin(theta), swept over the
  // picked edge's own length (kBaseDepth).
  //
  // Filleting then perturbs that sharp-corner volume by two independent
  // corrections, each derived from the standard "circular fillet at a
  // corner of interior angle alpha" area formula, r^2*(cot(alpha/2) -
  // (pi-alpha)/2) (the textbook square-corner case, r^2*(1 - pi/4), is this
  // formula at alpha = pi/2):
  //   - The OUTER crease (radius bendRadiusMm + thicknessMm) sits where the
  //     base's own top face meets the flange's outward face. Hand-tracing
  //     the fused solid's boundary around that edge (both the base's
  //     contribution and the pentagon's own, as two adjoining wedges) gives
  //     an interior (material) angle of (pi + theta) for ANY bend angle
  //     theta — always reflex (over pi), so this fillet ADDS a lobe of
  //     material rather than cutting one off. Its notch (exterior) angle is
  //     (pi - theta), and cot((pi-theta)/2) simplifies via the standard
  //     complementary-angle identity to tan(theta/2).
  //   - The INNER crease (radius bendRadiusMm) sits where the base's own
  //     bottom face meets the wedge infill's diagonal face. The same
  //     hand-tracing gives interior angle (pi - theta/2) for any theta —
  //     always convex (under pi), so this fillet REMOVES a sliver, and
  //     cot(alpha/2) simplifies to tan(theta/4).
  // Both were checked by hand against this fixture's own theta = 90 degrees
  // (interior angles 270 and 135 degrees respectively, confirmed by direct
  // quadrant/ray tracing of the pentagon-plus-base topology) before being
  // generalized to the formulas below.
  const double angleRadForVolume = kBendAngleDeg * kDegreesToRadians;
  const double tangentSetbackForVolume =
      (kBendRadius + kThickness) * std::tan(0.5 * angleRadForVolume);
  const double extendedLengthForVolume = kFlangeLength + tangentSetbackForVolume;
  const double pentagonArea = extendedLengthForVolume * kThickness +
                              0.5 * kThickness * kThickness * std::sin(angleRadForVolume);
  const double newMaterialVolume = pentagonArea * kBaseDepth;
  const double outerRadiusForVolume = kBendRadius + kThickness;
  const double addedOuterArea = outerRadiusForVolume * outerRadiusForVolume *
                                (std::tan(0.5 * angleRadForVolume) - 0.5 * angleRadForVolume);
  const double removedInnerArea =
      kBendRadius * kBendRadius * (std::tan(0.25 * angleRadForVolume) - 0.25 * angleRadForVolume);
  const double filletVolumeCorrection = (addedOuterArea - removedInnerArea) * kBaseDepth;
  const double expectedFoldedVolume =
      kBaseWidth * kBaseDepth * kThickness + newMaterialVolume + filletVolumeCorrection;
  checkNear(folded->probes.volume, expectedFoldedVolume, 1e-2,
            "the folded pass-through's volume matches the hand-derived sharp-pentagon-plus-fillet-"
            "correction total exactly (not the naive flat-material sum, which ignores the fillets' "
            "own real area correction)");

  // Ground truth, independently re-derived here (not copied from
  // sheet_metal_feature.cpp): BA from the stated formula, and the base
  // panel's own remaining length after its outer fillet (radius
  // bendRadiusMm + thicknessMm) trims it back from the original profile edge
  // by the standard tangent-length-of-an-inscribed-fillet formula,
  // r * tan(theta/2).
  const double angleRad = kBendAngleDeg * kDegreesToRadians;
  const double bendAllowance = angleRad * (kBendRadius + kKFactor * kThickness);
  const double outerSetback = (kBendRadius + kThickness) * std::tan(0.5 * angleRad);
  const double baseTangentLength = kBaseWidth / 2.0 - outerSetback;
  const double expectedTotalLength = baseTangentLength + bendAllowance + kFlangeLength;

  const double actualXExtent = flat->probes.bounds[3] - flat->probes.bounds[0];
  checkNear(actualXExtent, kBaseWidth / 2.0 + expectedTotalLength, 5e-3,
            "flat pattern X extent == (base's far edge to hinge) + baseTangentLength' worth of "
            "panel + BA + flangeLengthMm, i.e. baseLength' + BA + flangeLengthMm past the seed's "
            "own far edge");
  checkNear(flat->probes.bounds[4] - flat->probes.bounds[1], kBaseDepth, 1e-3,
            "flat pattern Y extent is unchanged (the bend-line length)");
  checkNear(flat->probes.bounds[5] - flat->probes.bounds[2], kThickness, 1e-3,
            "flat pattern Z extent is exactly one sheet thickness (genuinely flat)");
}

// --- 4. Refusals -------------------------------------------------------------

void EdgeFlangeNonPlanarBoundaryRefusal() {
  std::printf("edge_flange on a non-boundary (closed, degenerate) edge -> "
              "E_EDGE_FLANGE_NOT_PLANAR_BOUNDARY:\n");
  const std::string coneOp = "50000000-0000-4000-8000-000000000005";
  const std::string coneBody = "50000000-0000-4000-8000-0000000000b1";
  EdgeFlangeParams params;
  params.targetOperationId = coneOp;
  // A simple cone's ONE circular rim edge (radiusTop == 0, so there is no
  // second cap to disambiguate against) — closed, so its two endpoints
  // coincide: neither "exactly two distinct incident faces one of which is
  // the larger of a planar pair" reasoning nor a non-degenerate chord applies.
  params.edgeRef = AstRef(Query("edges", {SrcOp(coneOp)}, {Filter("circle")}));
  params.flangeLengthMm = 10.0;
  params.bendAngleDeg = 90.0;
  params.bendRadiusMm = 1.0;
  params.thicknessMm = 2.0;
  const Refusal refusal = RunExpectingRefusal(
      nlohmann::json::array({ConeOperation(coneOp, coneBody, 20.0, 30.0, {200.0, 200.0, 0.0}),
                             EdgeFlangeOperation(kEdgeFlangeOp, kEdgeFlangeBody, params)}));
  check(refusal.kind == "operation" && refusal.code == "GEOMETRY_FAILED" &&
            refusal.details.value("bendCode", "") == "E_EDGE_FLANGE_NOT_PLANAR_BOUNDARY" &&
            refusal.operationId == kEdgeFlangeOp,
        "a cone's closed rim edge -> E_EDGE_FLANGE_NOT_PLANAR_BOUNDARY, never a crash");
}

void UnfoldNoBendsRefusal() {
  std::printf("unfold on an already-flat body (no bends) -> E_UNFOLD_NO_BENDS:\n");
  const Refusal refusal = RunExpectingRefusal(nlohmann::json::array(
      {RectangleProfileOperation(kProfileOp, kBaseWidth, kBaseDepth, {0.0, 0.0, 0.0}),
       BaseFlangeOperation(kBaseFlangeOp, kBaseFlangeBody, kProfileOp, kThickness),
       UnfoldOperation(kUnfoldOp, kFoldedBody, kFlatBody, kBaseFlangeOp)}));
  check(refusal.kind == "operation" && refusal.code == "GEOMETRY_FAILED" &&
            refusal.details.value("bendCode", "") == "E_UNFOLD_NO_BENDS" &&
            refusal.operationId == kUnfoldOp,
        "a bend-free base_flange body -> E_UNFOLD_NO_BENDS, never a crash");
}

} // namespace

int main() {
  try {
    BaseFlangeVolumeAndBounds();
    EdgeFlangeNinetyDegreeBend();
    UnfoldFlatPatternLength();
    EdgeFlangeNonPlanarBoundaryRefusal();
    UnfoldNoBendsRefusal();
  } catch (const std::exception& error) {
    std::printf("FATAL: uncaught exception: %s\n", error.what());
    return 1;
  }
  if (g_failures == 0) {
    std::printf("\nALL SHEET METAL TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d SHEET METAL CHECK(S) FAILED\n", g_failures);
  return 1;
}
