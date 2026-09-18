// CAP-140 native Sweep-v2 qualification.
//
// This intentionally exercises the document evaluator and naming registry, not
// BRepOffsetAPI in isolation. The core acceptance case is a committed sketch
// path containing a LINE, a tangent ARC, and a SPLINE. Those curves produce no
// presentation body; Sweep reaches them only through the stable sketch-edge
// tokens minted by the registry. A successful solid therefore proves both the
// hidden-sketch identity seam and the associative evaluator seam.
#include <atomic>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>

#include <BRepAdaptor_Curve.hxx>
#include <BRepBndLib.hxx>
#include <BRepGProp.hxx>
#include <Bnd_Box.hxx>
#include <GProp_GProps.hxx>
#include <GeomAbs_CurveType.hxx>
#include <TopoDS.hxx>
#include <nlohmann/json.hpp>

#include "geometry.hpp"
#include "naming_registry.hpp"

namespace {

int g_failures = 0;

void check(const bool condition, const std::string& label) {
  if (condition) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s\n", label.c_str());
    ++g_failures;
  }
}

void checkClose(const double actual, const double expected, const double tolerance,
                const std::string& label) {
  if (std::abs(actual - expected) <= tolerance) {
    std::printf("  ok   %s (%.9f)\n", label.c_str(), actual);
  } else {
    std::printf("  FAIL %s: expected %.9f, got %.9f\n", label.c_str(), expected, actual);
    ++g_failures;
  }
}

nlohmann::json Metadata() {
  return {{"createdAt", "2026-08-09T00:00:00.000Z"}, {"createdBy", {{"kind", "user"}}}};
}

nlohmann::json WorldPlaneRef(const std::string& world) {
  return {{"ast",
           {{"kind", "faces"},
            {"scope", nlohmann::json::array({{{"source", "world"}, {"world", world}}})},
            {"filters", nlohmann::json::array()}}},
          {"arity", "one"},
          {"anchors", nlohmann::json::array()},
          {"onEmpty", "error"}};
}

std::uint64_t StableSemanticOrdinal(const std::string& value) {
  std::uint64_t hash = UINT64_C(14695981039346656037);
  for (const unsigned char byte : value) {
    hash ^= static_cast<std::uint64_t>(byte);
    hash *= UINT64_C(1099511628211);
  }
  return hash;
}

std::string SketchEdgeToken(const std::string& sketchId, const std::string& semanticId) {
  return "t:" + sketchId + "/sketch-edge/" + std::to_string(StableSemanticOrdinal(semanticId));
}

nlohmann::json TokenEdgeRef(const std::string& token) {
  return {{"ast",
           {{"kind", "edges"},
            {"scope", nlohmann::json::array({{{"source", "token"}, {"token", token}}})},
            {"filters", nlohmann::json::array()}}},
          {"arity", "one"},
          {"anchors", nlohmann::json::array({{{"token", token}, {"kind", "edge"}}})},
          {"onEmpty", "error"}};
}

nlohmann::json BoxTopEdgeRef(const std::string& boxId, const std::string& yExtreme) {
  const nlohmann::json roleArg = {{"arg", "ident"}, {"value", "top-edge"}};
  const nlohmann::json directionArg = {{"arg", "direction"},
                                       {"value", {{"form", "axis"}, {"sign", 1}, {"axis", "x"}}}};
  const nlohmann::json yArg = {{"arg", "axis"}, {"value", "y"}};
  return {{"ast",
           {{"kind", "edges"},
            {"scope", nlohmann::json::array({{{"source", "op"}, {"opId", boxId}}})},
            {"filters", nlohmann::json::array({{{"name", "role"}, {"args", {roleArg}}},
                                               {{"name", "parallel"}, {"args", {directionArg}}},
                                               {{"name", yExtreme}, {"args", {yArg}}}})}}},
          {"arity", "one"},
          {"anchors", nlohmann::json::array()},
          {"onEmpty", "error"}};
}

nlohmann::json BoxRightTopEdgeRef(const std::string& boxId) {
  const nlohmann::json roleArg = {{"arg", "ident"}, {"value", "top-edge"}};
  const nlohmann::json directionArg = {{"arg", "direction"},
                                       {"value", {{"form", "axis"}, {"sign", 1}, {"axis", "y"}}}};
  const nlohmann::json xArg = {{"arg", "axis"}, {"value", "x"}};
  return {{"ast",
           {{"kind", "edges"},
            {"scope", nlohmann::json::array({{{"source", "op"}, {"opId", boxId}}})},
            {"filters", nlohmann::json::array({{{"name", "role"}, {"args", {roleArg}}},
                                               {{"name", "parallel"}, {"args", {directionArg}}},
                                               {{"name", "max"}, {"args", {xArg}}}})}}},
          {"arity", "one"},
          {"anchors", nlohmann::json::array()},
          {"onEmpty", "error"}};
}

const std::string kProfileId = "aaaaaaaa-0000-4000-8000-000000000140";
const std::string kPathSketchId = "aaaaaaaa-0000-4000-8000-000000000141";
const std::string kGuideSketchId = "aaaaaaaa-0000-4000-8000-000000000144";
const std::string kSweepId = "aaaaaaaa-0000-4000-8000-000000000142";
const std::string kSweepBodyId = "b0000000-0000-4000-8000-000000000140";
const std::string kLineEid = "path_line_00000000000000000000001";
const std::string kArcEid = "path_arc_000000000000000000000002";
const std::string kSplineEid = "path_spline_00000000000000000001";
const std::string kGuideEid = "path_guide_000000000000000000001";
const std::string kTargetId = "aaaaaaaa-0000-4000-8000-000000000143";

nlohmann::json Profile() {
  return {{"id", kProfileId},
          {"type", "create_profile"},
          {"schemaVersion", 1},
          {"name", "Sweep section"},
          {"outputProfileId", "c0000000-0000-4000-8000-000000000140"},
          {"parameters",
           {{"shape", {{"kind", "rectangle"}, {"width", 4.0}, {"depth", 2.0}}},
            {"placement",
             {{"origin", {0.0, 0.0, 0.0}},
              {"zDirection", {1.0, 0.0, 0.0}},
              {"xDirection", {0.0, 1.0, 0.0}}}}}},
          {"metadata", Metadata()}};
}

nlohmann::json PathSketch() {
  // Deliberately author the first line backwards. The ordered path is still
  // line -> arc -> spline, so the evaluator must orient the FIRST PAIR from
  // their unique shared endpoint instead of assuming edge 1 already points
  // toward edge 2. The normalized path then starts at the profile plane x=0.
  const nlohmann::json line = {{"eid", kLineEid},
                               {"kind", "line"},
                               {"p1", {20.0, 0.0}},
                               {"p2", {0.0, 0.0}},
                               {"construction", false}};
  const nlohmann::json arc = {{"eid", kArcEid}, {"kind", "arc-center"}, {"center", {20.0, 10.0}},
                              {"radius", 10.0}, {"startAngle", -90.0},  {"endAngle", 0.0},
                              {"ccw", true},    {"construction", false}};
  const nlohmann::json spline = {
      {"eid", kSplineEid},
      {"kind", "spline"},
      {"points", nlohmann::json::array({{30.0, 10.0}, {30.0, 16.0}, {36.0, 22.0}})},
      {"closed", false},
      {"construction", false}};
  return {{"id", kPathSketchId},
          {"type", "sketch"},
          {"schemaVersion", 1},
          {"name", "Sweep path"},
          {"parameters",
           {{"plane", WorldPlaneRef("xy")},
            {"entities", nlohmann::json::array({line, arc, spline})},
            {"constraints", nlohmann::json::array()}}},
          {"metadata", Metadata()}};
}

nlohmann::json GuideSketch() {
  // A parallel guide in a distinct XZ sketch defines world +Z as the section
  // normal along the X-aligned spine. That is intentionally different from the
  // unguided natural frame and avoids conflating guide orientation with scale
  // or contact behavior.
  const nlohmann::json guide = {{"eid", kGuideEid},
                                {"kind", "line"},
                                {"p1", {0.0, 3.0}},
                                {"p2", {20.0, 3.0}},
                                {"construction", false}};
  return {{"id", kGuideSketchId},
          {"type", "sketch"},
          {"schemaVersion", 1},
          {"name", "Sweep guide"},
          {"parameters",
           {{"plane", WorldPlaneRef("xz")},
            {"entities", nlohmann::json::array({guide})},
            {"constraints", nlohmann::json::array()}}},
          {"metadata", Metadata()}};
}

nlohmann::json Sweep(const nlohmann::json& path, const nlohmann::json& extent,
                     const std::string& orientation = "natural",
                     const std::string& pathDirection = "forward") {
  return {{"id", kSweepId},
          {"type", "sweep"},
          {"schemaVersion", 2},
          {"name", "Associative Sweep"},
          {"outputBodyId", kSweepBodyId},
          {"parameters",
           {{"profileOperationId", kProfileId},
            {"path", path},
            {"orientation", orientation},
            {"extent", extent},
            {"pathDirection", pathDirection},
            {"startRotationDegrees", 0.0},
            {"taperAngleDeg", 0.0},
            {"twistAngleDegrees", 0.0},
            {"boolean", {{"mode", "newBody"}}}}},
          {"metadata", Metadata()}};
}

nlohmann::json FullPathRefs() {
  return nlohmann::json::array({TokenEdgeRef(SketchEdgeToken(kPathSketchId, kLineEid)),
                                TokenEdgeRef(SketchEdgeToken(kPathSketchId, kArcEid)),
                                TokenEdgeRef(SketchEdgeToken(kPathSketchId, kSplineEid))});
}

nlohmann::json Program(const nlohmann::json& sweep) {
  return nlohmann::json::array({Profile(), PathSketch(), GuideSketch(), sweep});
}

nlohmann::json TargetBox() {
  return {{"id", kTargetId},
          {"type", "create_box"},
          {"schemaVersion", 1},
          {"name", "Sweep target"},
          {"outputBodyId", "b0000000-0000-4000-8000-000000000143"},
          {"parameters",
           {{"width", 40.0},
            {"depth", 12.0},
            {"height", 12.0},
            {"placement",
             {{"origin", {0.0, 0.0, -6.0}},
              {"zDirection", {0.0, 0.0, 1.0}},
              {"xDirection", {1.0, 0.0, 0.0}}}}}},
          {"metadata", Metadata()}};
}

struct Run final {
  std::vector<aeth::EvaluatedBody> bodies;
  std::string failure;
};

Run Evaluate(const nlohmann::json& program, aeth::NamingRegistry& registry) {
  std::atomic_bool cancelled{false};
  Run run;
  try {
    run.bodies = aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
  } catch (const std::exception& error) {
    run.failure = error.what();
  }
  return run;
}

double Volume(const TopoDS_Shape& shape) {
  GProp_GProps properties;
  BRepGProp::VolumeProperties(shape, properties);
  return std::abs(properties.Mass());
}

std::vector<double> BoundingDimensions(const TopoDS_Shape& shape) {
  Bnd_Box box;
  BRepBndLib::AddOptimal(shape, box, false, false);
  double xmin = 0.0;
  double ymin = 0.0;
  double zmin = 0.0;
  double xmax = 0.0;
  double ymax = 0.0;
  double zmax = 0.0;
  box.Get(xmin, ymin, zmin, xmax, ymax, zmax);
  return {xmax - xmin, ymax - ymin, zmax - zmin};
}

double TokenEdgeLength(const aeth::NamingRegistry& registry, const std::string& token) {
  const aeth::NamingRecord* record = registry.FindByToken(token);
  if (record == nullptr)
    return -1.0;
  GProp_GProps properties;
  BRepGProp::LinearProperties(record->shape, properties);
  return std::abs(properties.Mass());
}

void TestLineArcSplinePath() {
  std::printf("\n[1] backwards-first line + arc + spline path\n");
  aeth::NamingRegistry registry;
  const Run run = Evaluate(Program(Sweep(FullPathRefs(), {{"mode", "full"}})), registry);
  check(run.failure.empty(), "document evaluates after first-edge normalization: " + run.failure);
  if (!run.failure.empty())
    return;
  check(run.bodies.size() == 1, "Sweep produces exactly one visible body");
  if (run.bodies.empty())
    return;

  const std::string lineToken = SketchEdgeToken(kPathSketchId, kLineEid);
  const std::string arcToken = SketchEdgeToken(kPathSketchId, kArcEid);
  const std::string splineToken = SketchEdgeToken(kPathSketchId, kSplineEid);
  const aeth::NamingRecord* lineRecord = registry.FindByToken(lineToken);
  const aeth::NamingRecord* arcRecord = registry.FindByToken(arcToken);
  const aeth::NamingRecord* splineRecord = registry.FindByToken(splineToken);
  check(lineRecord != nullptr, "line sketch edge has its stable token");
  check(arcRecord != nullptr, "arc sketch edge has its stable token");
  check(splineRecord != nullptr, "spline sketch edge has its stable token");
  if (lineRecord == nullptr || arcRecord == nullptr || splineRecord == nullptr)
    return;

  check(BRepAdaptor_Curve(TopoDS::Edge(lineRecord->shape)).GetType() == GeomAbs_Line,
        "line token resolves to a real line edge");
  check(BRepAdaptor_Curve(TopoDS::Edge(arcRecord->shape)).GetType() == GeomAbs_Circle,
        "arc token resolves to a real circular edge, not its chord");
  check(BRepAdaptor_Curve(TopoDS::Edge(splineRecord->shape)).GetType() == GeomAbs_BSplineCurve,
        "spline token resolves to a real B-spline edge");

  const double pathLength = TokenEdgeLength(registry, lineToken) +
                            TokenEdgeLength(registry, arcToken) +
                            TokenEdgeLength(registry, splineToken);
  check(pathLength > 40.0, "registry path has substantial curved length");
  // The B-spline segment introduces genuine OCCT pipe/volume numerical noise
  // beyond the 1e-6 straight-edge precision; 1e-2 absolute on ~404 keeps the
  // exact-length contract (area * exact path length) while allowing solver
  // noise.
  checkClose(Volume(run.bodies.front().shape), 8.0 * pathLength, 1.0e-2,
             "swept volume follows the exact line+arc+spline path length");
}

void TestDistanceExtentOnStraightPrefix() {
  std::printf("\n[2] distance extent trims from normalized authored start\n");
  aeth::NamingRegistry registry;
  const Run run = Evaluate(
      Program(Sweep(FullPathRefs(), {{"mode", "distance"}, {"distanceMm", 15.0}})), registry);
  check(run.failure.empty(), "distance-limited document evaluates: " + run.failure);
  if (!run.failure.empty() || run.bodies.empty())
    return;
  checkClose(Volume(run.bodies.front().shape), 8.0 * 15.0, 1.0e-6,
             "distance extent uses the first 15 mm from the normalized path start");
}

void TestFixedTrihedronStraightPath() {
  std::printf("\n[3] fixed trihedron honors explicit single-edge reverse\n");
  const nlohmann::json linePath =
      nlohmann::json::array({TokenEdgeRef(SketchEdgeToken(kPathSketchId, kLineEid))});
  aeth::NamingRegistry registry;
  // The underlying line is authored 20 -> 0, so reverse is required to begin
  // at the profile plane and proves single-edge pathDirection is semantic.
  const Run run =
      Evaluate(Program(Sweep(linePath, {{"mode", "full"}}, "fixed", "reverse")), registry);
  check(run.failure.empty(), "fixed-orientation reversed document evaluates: " + run.failure);
  if (!run.failure.empty() || run.bodies.empty())
    return;
  checkClose(Volume(run.bodies.front().shape), 8.0 * 20.0, 1.0e-6,
             "fixed trihedron preserves the reversed straight-section volume");
}

void TestGuideRailChangesGeometry() {
  std::printf("\n[4] guide rail has a measurable geometric effect\n");
  const nlohmann::json linePath =
      nlohmann::json::array({TokenEdgeRef(SketchEdgeToken(kPathSketchId, kLineEid))});
  nlohmann::json unGuided = Sweep(linePath, {{"mode", "full"}}, "natural", "reverse");
  nlohmann::json guided = unGuided;
  guided["parameters"]["guideRail"] = TokenEdgeRef(SketchEdgeToken(kGuideSketchId, kGuideEid));
  aeth::NamingRegistry unGuidedRegistry;
  aeth::NamingRegistry guidedRegistry;
  const Run baseline = Evaluate(Program(unGuided), unGuidedRegistry);
  const Run controlled = Evaluate(Program(guided), guidedRegistry);
  check(baseline.failure.empty(), "unguided benchmark evaluates: " + baseline.failure);
  check(controlled.failure.empty(), "guide-rail benchmark evaluates: " + controlled.failure);
  if (!baseline.failure.empty() || !controlled.failure.empty() || baseline.bodies.empty() ||
      controlled.bodies.empty())
    return;
  const std::vector<double> baselineBounds = BoundingDimensions(baseline.bodies.front().shape);
  const std::vector<double> controlledBounds = BoundingDimensions(controlled.bodies.front().shape);
  const double envelopeDelta = std::abs(controlledBounds[0] - baselineBounds[0]) +
                               std::abs(controlledBounds[1] - baselineBounds[1]) +
                               std::abs(controlledBounds[2] - baselineBounds[2]);
  check(envelopeDelta > 1.0e-3,
        "guide rail changes the measured bounding envelope rather than validating as a no-op");
}

void TestTaperTwistAndUpstreamRebuild() {
  std::printf("\n[5] taper/twist and upstream path edits are semantic\n");
  const auto straightRef = TokenEdgeRef(SketchEdgeToken(kPathSketchId, kLineEid));
  nlohmann::json controlled =
      Sweep(nlohmann::json::array({straightRef}), {{"mode", "full"}}, "fixed", "reverse");
  controlled["parameters"]["taperAngleDeg"] = 1.0;
  controlled["parameters"]["twistAngleDegrees"] = 30.0;
  aeth::NamingRegistry controlledRegistry;
  const Run changed = Evaluate(Program(controlled), controlledRegistry);
  check(changed.failure.empty(), "taper/twist benchmark evaluates: " + changed.failure);
  if (!changed.failure.empty() || changed.bodies.empty())
    return;
  check(std::abs(Volume(changed.bodies.front().shape) - 160.0) > 1.0,
        "taper/twist controls measurably change the straight-path solid");

  nlohmann::json editedPath = PathSketch();
  editedPath["parameters"]["entities"][0]["p1"][0] = 30.0;
  nlohmann::json editedProgram = nlohmann::json::array(
      {Profile(), editedPath,
       Sweep(nlohmann::json::array({straightRef}), {{"mode", "full"}}, "fixed", "reverse")});
  aeth::NamingRegistry editedRegistry;
  const Run rebuilt = Evaluate(editedProgram, editedRegistry);
  check(rebuilt.failure.empty(), "upstream-edited path rebuilds: " + rebuilt.failure);
  if (!rebuilt.failure.empty() || rebuilt.bodies.empty())
    return;
  checkClose(Volume(rebuilt.bodies.front().shape), 8.0 * 30.0, 1.0e-6,
             "upstream line edit changes the same associative Sweep result");
}

void TestBrokenReferenceAndBooleanModes() {
  std::printf("\n[6] broken reference refusal plus Join/Cut result modes\n");
  nlohmann::json missing =
      Sweep(nlohmann::json::array({TokenEdgeRef("t:missing/sketch-edge/1")}), {{"mode", "full"}});
  aeth::NamingRegistry missingRegistry;
  const Run refused = Evaluate(Program(missing), missingRegistry);
  check(!refused.failure.empty(), "missing path token refuses instead of substituting a path");
  check(refused.failure.find("path") != std::string::npos ||
            refused.failure.find("resolve") != std::string::npos,
        "broken-path refusal is attributed to the path slot: " + refused.failure);

  const auto linePath =
      nlohmann::json::array({TokenEdgeRef(SketchEdgeToken(kPathSketchId, kLineEid))});
  for (const std::string mode : {std::string("join"), std::string("cut")}) {
    nlohmann::json operation = Sweep(linePath, {{"mode", "full"}}, "fixed", "reverse");
    operation["parameters"]["boolean"] = {{"mode", mode}, {"targetOperationId", kTargetId}};
    const nlohmann::json program =
        nlohmann::json::array({TargetBox(), Profile(), PathSketch(), operation});
    aeth::NamingRegistry registry;
    const Run result = Evaluate(program, registry);
    check(result.failure.empty(), "Sweep " + mode + " evaluates: " + result.failure);
    check(result.bodies.size() == 1, "Sweep " + mode + " leaves one explicit result body");
  }
}

void TestModelFaceSketchAlongModelEdge() {
  std::printf("\n[7] model-face sketch along a durable model edge\n");
  const std::string boxId = "aaaaaaaa-0000-4000-8000-000000000147";
  const std::string profileId = "aaaaaaaa-0000-4000-8000-000000000148";
  const std::string sweepId = "aaaaaaaa-0000-4000-8000-000000000149";
  const nlohmann::json box = {{"id", boxId},
                              {"type", "create_box"},
                              {"schemaVersion", 1},
                              {"name", "Rail box"},
                              {"outputBodyId", "b0000000-0000-4000-8000-000000000147"},
                              {"parameters",
                               {{"width", 90.0},
                                {"depth", 10.0},
                                {"height", 36.0},
                                {"placement",
                                 {{"origin", {-45.0, -5.0, 0.0}},
                                  {"zDirection", {0.0, 0.0, 1.0}},
                                  {"xDirection", {1.0, 0.0, 0.0}}}}}},
                              {"metadata", Metadata()}};
  const nlohmann::json profile = {
      {"id", profileId},
      {"type", "create_profile"},
      {"schemaVersion", 1},
      {"name", "Face sketch"},
      {"outputProfileId", "c0000000-0000-4000-8000-000000000147"},
      {"parameters",
       {{"shape", {{"kind", "rectangle"}, {"width", 10.0}, {"depth", 10.0}}},
        {"placement",
         {{"origin", {-45.0, -5.0, 36.0}},
          {"zDirection", {0.0, 0.0, 1.0}},
          {"xDirection", {1.0, 0.0, 0.0}}}}}},
      {"metadata", Metadata()}};
  const nlohmann::json sweep = {{"id", sweepId},
                                {"type", "sweep"},
                                {"schemaVersion", 2},
                                {"name", "Face sketch model-edge Sweep"},
                                {"outputBodyId", "b0000000-0000-4000-8000-000000000149"},
                                {"parameters",
                                 {{"profileOperationId", profileId},
                                  {"path", nlohmann::json::array({BoxTopEdgeRef(boxId, "min")})},
                                  {"orientation", "natural"},
                                  {"extent", {{"mode", "full"}}},
                                  {"pathDirection", "forward"},
                                  {"startRotationDegrees", 0.0},
                                  {"taperAngleDeg", 0.0},
                                  {"twistAngleDegrees", 0.0},
                                  {"boolean", {{"mode", "newBody"}}}}},
                                {"metadata", Metadata()}};
  aeth::NamingRegistry registry;
  const Run run = Evaluate(nlohmann::json::array({box, profile, sweep}), registry);
  check(run.failure.empty(), "model-face sketch/model-edge Sweep evaluates: " + run.failure);
  check(run.bodies.size() == 2, "model-face sketch Sweep keeps box plus one new body");

  nlohmann::json guidedSweep = sweep;
  guidedSweep["id"] = "b0000000-0000-4000-8000-000000000150";
  guidedSweep["outputBodyId"] = "b0000000-0000-4000-8000-000000000151";
  guidedSweep["parameters"]["guideRail"] = BoxTopEdgeRef(boxId, "max");
  aeth::NamingRegistry guidedRegistry;
  const Run guided = Evaluate(nlohmann::json::array({box, profile, guidedSweep}), guidedRegistry);
  check(guided.failure.empty(),
        "opposite model edge is direction-normalized as a guide rail: " + guided.failure);
  check(guided.bodies.size() == 2, "guided model-face sketch Sweep keeps box plus one new body");

  nlohmann::json chainedSweep = sweep;
  chainedSweep["id"] = "b0000000-0000-4000-8000-000000000152";
  chainedSweep["outputBodyId"] = "b0000000-0000-4000-8000-000000000153";
  const std::string chainProfileId = "b0000000-0000-4000-8000-000000000154";
  nlohmann::json chainProfile = profile;
  chainProfile["id"] = chainProfileId;
  chainProfile["outputProfileId"] = "b0000000-0000-4000-8000-000000000155";
  chainProfile["parameters"]["shape"] = {{"kind", "rectangle"}, {"width", 2.0}, {"depth", 2.0}};
  chainProfile["parameters"]["placement"] = {{"origin", {-90.0, -10.0, 36.0}},
                                             {"zDirection", {1.0, 0.0, 0.0}},
                                             {"xDirection", {0.0, 1.0, 0.0}}};
  chainedSweep["parameters"]["profileOperationId"] = chainProfileId;
  chainedSweep["parameters"]["path"] =
      nlohmann::json::array({BoxTopEdgeRef(boxId, "min"), BoxRightTopEdgeRef(boxId)});
  aeth::NamingRegistry chainedRegistry;
  const Run chained =
      Evaluate(nlohmann::json::array({box, chainProfile, chainedSweep}), chainedRegistry);
  check(chained.failure.empty(),
        "two adjacent durable model edges evaluate as one ordered chain: " + chained.failure);
  check(chained.bodies.size() == 2, "two-edge model chain keeps box plus one Sweep body");
}

} // namespace

int main() {
  std::printf("CAP-140 associative Sweep native corpus\n");
  TestLineArcSplinePath();
  TestDistanceExtentOnStraightPrefix();
  TestFixedTrihedronStraightPath();
  TestGuideRailChangesGeometry();
  TestTaperTwistAndUpstreamRebuild();
  TestBrokenReferenceAndBooleanModes();
  TestModelFaceSketchAlongModelEdge();
  if (g_failures == 0) {
    std::printf("\nPASS: associative Sweep corpus is green\n");
    return 0;
  }
  std::printf("\nFAIL: %d associative Sweep assertion(s) failed\n", g_failures);
  return 1;
}
