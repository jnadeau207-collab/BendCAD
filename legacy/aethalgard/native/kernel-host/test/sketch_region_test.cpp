// Native gate for the sketch REGION (CAP-038): a solved constraint sketch
// becomes a profile, and every existing profile consumer eats it unchanged.
//
// The assertions are ANALYTIC. A region gate that checked "a body came out"
// would pass on a contour built in the wrong plane, in the wrong order, or with
// an arc replaced by its chord — every one of which produces a perfectly valid
// solid of the wrong shape. So each case predicts a volume in closed form and
// compares, and the face-plane case additionally pins WHERE the solid landed,
// because the sketch-plane basis rule (plan 02, normative) is exactly the part
// two independent implementations can disagree about while both look right.
//
// What this pins:
//   1. a four-line contour on world(xy) extrudes to width x depth x height;
//   2. the criterion's four-line/two-arc contour extrudes to its closed-form
//      area x height — the arcs are real arcs, not chords;
//   3. a single circle is a closed loop and extrudes to pi r^2 h;
//   4. the SOLVED coordinates win: a contour left open by its placed values
//      and closed by its solution builds the solved shape;
//   5. an open contour is LEGAL and produces no region — the sketch never fails
//      a document over what it does not enclose;
//   6. a guide-only sketch produces no profile — and the extrude that names
//      either of them fails as a missing reference rather than building
//      nothing silently;
//   7. a sketch on a picked planar FACE lands on that face, at the frame the
//      basis rule's rules 2 and 4 derive (not the face centroid);
//   8. world(xz)'s normal is -y, the normative table's row, so a sketch on it
//      extrudes in that direction and nowhere else.
#include <array>
#include <atomic>
#include <cmath>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <vector>

#include <BRepAdaptor_Curve.hxx>
#include <BRepBndLib.hxx>
#include <BRepGProp.hxx>
#include <Bnd_Box.hxx>
#include <GProp_GProps.hxx>
#include <GeomAbs_CurveType.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp_Explorer.hxx>
#include <TopoDS.hxx>
#include <nlohmann/json.hpp>

#include "geometry.hpp"
#include "naming_registry.hpp"
#include "selector_evaluator.hpp"

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

void checkClose(const double actual, const double expected, const double tolerance,
                const std::string& label) {
  const bool ok = std::abs(actual - expected) <= tolerance;
  if (ok) {
    std::printf("  ok   %s (%.9f)\n", label.c_str(), actual);
  } else {
    std::printf("  FAIL %s: expected %.9f, got %.9f\n", label.c_str(), expected, actual);
    g_failures += 1;
  }
}

// --- Document builders -------------------------------------------------------

std::string Eid(const char letter) { return std::string("ent_") + letter + std::string(25, '0'); }

nlohmann::json Metadata() {
  return {{"createdAt", "2026-07-28T00:00:00.000Z"}, {"createdBy", {{"kind", "user"}}}};
}

nlohmann::json Line(const char letter, const double x1, const double y1, const double x2,
                    const double y2) {
  return {{"eid", Eid(letter)},
          {"kind", "line"},
          {"p1", {x1, y1}},
          {"p2", {x2, y2}},
          {"construction", false}};
}

nlohmann::json Arc(const char letter, const double cx, const double cy, const double radius,
                   const double startAngle, const double endAngle) {
  return {{"eid", Eid(letter)}, {"kind", "arc-center"},     {"center", {cx, cy}},
          {"radius", radius},   {"startAngle", startAngle}, {"endAngle", endAngle},
          {"ccw", true},        {"construction", false}};
}

nlohmann::json Circle(const char letter, const double cx, const double cy, const double radius) {
  return {{"eid", Eid(letter)},
          {"kind", "circle"},
          {"center", {cx, cy}},
          {"radius", radius},
          {"construction", false}};
}

nlohmann::json Spline(const char letter, const std::vector<std::array<double, 2>>& points,
                      const bool closed) {
  nlohmann::json values = nlohmann::json::array();
  for (const auto& point : points)
    values.push_back({point[0], point[1]});
  return {{"eid", Eid(letter)},
          {"kind", "spline"},
          {"points", values},
          {"closed", closed},
          {"construction", false}};
}

nlohmann::json SrcOp(const std::string& id) { return {{"source", "op"}, {"opId", id}}; }

nlohmann::json Filter(const std::string& name,
                      const nlohmann::json& args = nlohmann::json::array()) {
  return {{"name", name}, {"args", args}};
}

nlohmann::json AstRef(const nlohmann::json& ast, const std::string& arity = "one") {
  return {
      {"ast", ast}, {"arity", arity}, {"anchors", nlohmann::json::array()}, {"onEmpty", "error"}};
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

nlohmann::json BoxFaceRef(const std::string& role) {
  return AstRef(
      {{"kind", "faces"},
       {"scope", nlohmann::json::array({SrcOp("aaaaaaaa-0000-4000-8000-000000000003")})},
       {"filters", nlohmann::json::array({Filter(
                       "role", nlohmann::json::array({{{"arg", "ident"}, {"value", role}}}))})}});
}

nlohmann::json BoxTopEdgeRef() {
  return AstRef(
      {{"kind", "edges"},
       {"scope", nlohmann::json::array({SrcOp("aaaaaaaa-0000-4000-8000-000000000003")})},
       {"filters",
        nlohmann::json::array(
            {Filter("role", nlohmann::json::array({{{"arg", "ident"}, {"value", "top-edge"}}})),
             Filter("largest")})}});
}

nlohmann::json Sketch(const std::string& id, const nlohmann::json& plane,
                      const std::vector<nlohmann::json>& entities,
                      const nlohmann::json& solution = nlohmann::json(),
                      const nlohmann::json& projected = nlohmann::json()) {
  nlohmann::json list = nlohmann::json::array();
  for (const nlohmann::json& entity : entities)
    list.push_back(entity);
  nlohmann::json parameters = {
      {"plane", plane}, {"entities", list}, {"constraints", nlohmann::json::array()}};
  if (!solution.is_null())
    parameters["solution"] = solution;
  if (!projected.is_null())
    parameters["projected"] = projected;
  return {{"id", id},
          {"type", "sketch"},
          {"schemaVersion", 1},
          {"name", "Sketch 1"},
          {"parameters", std::move(parameters)},
          {"metadata", Metadata()}};
}

nlohmann::json Extrude(const std::string& id, const std::string& profileId, const double distance) {
  return {{"id", id},
          {"type", "extrude"},
          {"schemaVersion", 1},
          {"name", "Extrude 1"},
          {"outputBodyId", "b0000000-0000-4000-8000-000000000001"},
          {"parameters",
           {{"profileOperationId", profileId}, {"distance", distance}, {"direction", "normal"}}},
          {"metadata", Metadata()}};
}

nlohmann::json RevolveRelative(const std::string& id, const std::string& profileId,
                               const std::string& axis) {
  return {{"id", id},
          {"type", "revolve"},
          {"schemaVersion", 1},
          {"name", "Revolve 1"},
          {"outputBodyId", "b0000000-0000-4000-8000-000000000003"},
          {"parameters",
           {{"profileOperationId", profileId}, {"profileAxis", axis}, {"angleDegrees", 360.0}}},
          {"metadata", Metadata()}};
}

nlohmann::json SweepNormal(const std::string& id, const std::string& profileId,
                           const double length) {
  return {{"id", id},
          {"type", "sweep"},
          {"schemaVersion", 1},
          {"name", "Sweep 1"},
          {"outputBodyId", "b0000000-0000-4000-8000-000000000004"},
          {"parameters",
           {{"profileOperationId", profileId},
            {"profilePath", {{"kind", "normal"}, {"lengthMm", length}}}}},
          {"metadata", Metadata()}};
}

nlohmann::json Loft(const std::string& id, const std::vector<std::string>& profileIds) {
  return {{"id", id},
          {"type", "loft"},
          {"schemaVersion", 1},
          {"name", "Loft 1"},
          {"outputBodyId", "b0000000-0000-4000-8000-000000000005"},
          {"parameters", {{"profileOperationIds", profileIds}, {"ruled", false}}},
          {"metadata", Metadata()}};
}

nlohmann::json Box(const std::string& id, const double width, const double depth,
                   const double height) {
  return {{"id", id},
          {"type", "create_box"},
          {"schemaVersion", 1},
          {"name", "Box 1"},
          {"outputBodyId", "b0000000-0000-4000-8000-000000000002"},
          {"parameters",
           {{"width", width},
            {"depth", depth},
            {"height", height},
            {"placement",
             {{"origin", {0.0, 0.0, 0.0}},
              {"zDirection", {0.0, 0.0, 1.0}},
              {"xDirection", {1.0, 0.0, 0.0}}}}}},
          {"metadata", Metadata()}};
}

nlohmann::json Program(const std::vector<nlohmann::json>& operations) {
  nlohmann::json list = nlohmann::json::array();
  for (const nlohmann::json& operation : operations)
    list.push_back(operation);
  return list;
}

// --- Harness -----------------------------------------------------------------

struct Run final {
  std::vector<aeth::EvaluatedBody> bodies;
  std::string failureKind; // "none" | "operation" | "reference-missing" | "other"
  std::string message;
};

Run Evaluate(const nlohmann::json& program) {
  std::atomic_bool cancelled{false};
  aeth::NamingRegistry registry;
  Run run;
  try {
    run.bodies = aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
    run.failureKind = "none";
  } catch (const aeth::OperationFailure& error) {
    run.failureKind = "operation";
    run.message = error.what();
  } catch (const aeth::ReferenceMissing& error) {
    run.failureKind = "reference-missing";
    run.message = error.what();
  } catch (const std::exception& error) {
    run.failureKind = "other";
    run.message = error.what();
  }
  return run;
}

double Volume(const aeth::EvaluatedBody& body) {
  GProp_GProps properties;
  BRepGProp::VolumeProperties(body.shape, properties);
  return properties.Mass();
}

Bnd_Box Bounds(const aeth::EvaluatedBody& body) {
  Bnd_Box box;
  BRepBndLib::Add(body.shape, box);
  return box;
}

const std::string kSketchId = "aaaaaaaa-0000-4000-8000-000000000001";
const std::string kExtrudeId = "aaaaaaaa-0000-4000-8000-000000000002";
const std::string kBoxId = "aaaaaaaa-0000-4000-8000-000000000003";

// The four sides of a 40 x 30 rectangle, authored end-to-start in order.
std::vector<nlohmann::json> RectangleEntities() {
  return {Line('A', 0, 0, 40, 0), Line('B', 40, 0, 40, 30), Line('C', 40, 30, 0, 30),
          Line('D', 0, 30, 0, 0)};
}

void TestRectangleOnGround() {
  std::printf("\n[1] a four-line contour on world(xy)\n");
  const Run run = Evaluate(Program({Sketch(kSketchId, WorldPlaneRef("xy"), RectangleEntities()),
                                    Extrude(kExtrudeId, kSketchId, 10.0)}));
  check(run.failureKind == "none", "the document evaluates: " + run.message);
  if (run.failureKind != "none")
    return;
  check(run.bodies.size() == 1, "one body — the sketch itself produces none");
  if (run.bodies.empty())
    return;
  // 40 x 30 x 10, exactly. A contour walked out of order would still close and
  // still extrude; it would not have this volume.
  checkClose(Volume(run.bodies.front()), 12000.0, 1e-9, "volume is width x depth x height");
  const Bnd_Box bounds = Bounds(run.bodies.front());
  double xMin = 0;
  double yMin = 0;
  double zMin = 0;
  double xMax = 0;
  double yMax = 0;
  double zMax = 0;
  bounds.Get(xMin, yMin, zMin, xMax, yMax, zMax);
  checkClose(zMin, 0.0, 1e-6, "it starts on the ground plane");
  checkClose(zMax, 10.0, 1e-6, "and extrudes along +z");
}

void TestCriterionContour() {
  std::printf("\n[2] the criterion's four lines and two arcs\n");
  // A 40 x 30 rectangle with its two right corners rounded at r = 10.
  const Run run = Evaluate(Program(
      {Sketch(kSketchId, WorldPlaneRef("xy"),
              {Line('A', 0, 0, 30, 0), Arc('B', 30, 10, 10, -90, 0), Line('C', 40, 10, 40, 20),
               Arc('D', 30, 20, 10, 0, 90), Line('E', 30, 30, 0, 30), Line('F', 0, 30, 0, 0)}),
       Extrude(kExtrudeId, kSketchId, 10.0)}));
  check(run.failureKind == "none", "the document evaluates: " + run.message);
  if (run.bodies.empty())
    return;
  // area = 40*30 - 2*(r^2 - pi r^2 / 4) with r = 10; times height 10.
  const double corner = 100.0 - (3.14159265358979323846 * 100.0 / 4.0);
  const double expected = (1200.0 - 2.0 * corner) * 10.0;
  // A chord in place of either arc would lose 2 * (r^2/2) * h = 1000 mm^3 —
  // three orders of magnitude above this tolerance.
  checkClose(Volume(run.bodies.front()), expected, 1e-6, "volume matches the closed-form area");
}

void TestSingleCircle() {
  std::printf("\n[3] a single circle is a closed loop on its own\n");
  const Run run = Evaluate(Program({Sketch(kSketchId, WorldPlaneRef("xy"), {Circle('A', 5, 5, 10)}),
                                    Extrude(kExtrudeId, kSketchId, 10.0)}));
  check(run.failureKind == "none", "the document evaluates: " + run.message);
  if (run.bodies.empty())
    return;
  checkClose(Volume(run.bodies.front()), 3.14159265358979323846 * 100.0 * 10.0, 1e-6,
             "volume is pi r^2 h");
}

void TestSolvedValuesWin() {
  std::printf("\n[4] the SOLVED coordinates are the ones built\n");
  // Placed: the last side stops 5 mm short, so the contour is open. Solved: it
  // closes, and the region is the closed one.
  const nlohmann::json solution = {
      {"entities", nlohmann::json::array({{{"eid", Eid('D')}, {"values", {0, 30, 0, 0}}}})},
      {"degreesOfFreedom", 0}};
  const std::vector<nlohmann::json> openLast = {Line('A', 0, 0, 40, 0), Line('B', 40, 0, 40, 30),
                                                Line('C', 40, 30, 0, 30), Line('D', 0, 30, 0, 5)};

  const Run refused = Evaluate(Program(
      {Sketch(kSketchId, WorldPlaneRef("xy"), openLast), Extrude(kExtrudeId, kSketchId, 10.0)}));
  check(refused.failureKind == "reference-missing",
        "the PLACED contour is open, so it encloses nothing to extrude");

  const Run run = Evaluate(Program({Sketch(kSketchId, WorldPlaneRef("xy"), openLast, solution),
                                    Extrude(kExtrudeId, kSketchId, 10.0)}));
  check(run.failureKind == "none", "the SOLVED contour closes: " + run.message);
  if (run.bodies.empty())
    return;
  checkClose(Volume(run.bodies.front()), 12000.0, 1e-9, "and builds the solved rectangle");
}

void TestOpenContourEnclosesNothing() {
  std::printf("\n[5] an open contour is legal and encloses nothing\n");
  const std::vector<nlohmann::json> open = {Line('A', 0, 0, 40, 0), Line('B', 40, 0, 40, 30),
                                            Line('C', 40, 30, 0, 30), Line('D', 0, 30, 0, 5)};
  // On its own it is a perfectly good sketch. Failing the document over what a
  // person has not closed YET would be the kernel inventing a rule about what
  // they are allowed to draw — and CAP-037's determinism gate stores a
  // ONE-LINE sketch whose document must evaluate.
  const Run alone = Evaluate(Program({Sketch(kSketchId, WorldPlaneRef("xy"), open)}));
  check(alone.failureKind == "none", "an open contour is legal on its own: " + alone.message);
  check(alone.bodies.empty(), "and produces nothing");

  const Run oneLine =
      Evaluate(Program({Sketch(kSketchId, WorldPlaneRef("xy"), {Line('A', 0, 0, 40, 0)})}));
  check(oneLine.failureKind == "none", "a one-line sketch evaluates: " + oneLine.message);

  // CONSUMING one is what fails, and it fails naming the consumer.
  const Run consumed = Evaluate(Program(
      {Sketch(kSketchId, WorldPlaneRef("xy"), open), Extrude(kExtrudeId, kSketchId, 10.0)}));
  check(consumed.failureKind == "reference-missing",
        "an extrude that names it fails as a MISSING REFERENCE: " + consumed.message);
}

void TestGuideOnlySketch() {
  std::printf("\n[6] a guide-only sketch produces no profile\n");
  nlohmann::json guide = Line('A', 0, 0, 40, 0);
  guide["construction"] = true;
  const nlohmann::json onlyGuide = Program({Sketch(kSketchId, WorldPlaneRef("xy"), {guide})});
  const Run quiet = Evaluate(onlyGuide);
  check(quiet.failureKind == "none", "on its own it is LEGAL and silent: " + quiet.message);
  check(quiet.bodies.empty(), "and produces nothing");

  const Run consumed = Evaluate(Program(
      {Sketch(kSketchId, WorldPlaneRef("xy"), {guide}), Extrude(kExtrudeId, kSketchId, 10.0)}));
  check(consumed.failureKind == "reference-missing",
        "an extrude that names it fails as a MISSING REFERENCE: " + consumed.message);
}

void TestSplineRegion() {
  std::printf("\n[7] a closed spline remains a BSpline boundary\n");
  const std::vector<std::array<double, 2>> points = {
      {0.0, 0.0}, {40.0, 0.0}, {40.0, 30.0}, {0.0, 30.0}};
  const Run run =
      Evaluate(Program({Sketch(kSketchId, WorldPlaneRef("xy"), {Spline('S', points, true)}),
                        Extrude(kExtrudeId, kSketchId, 5.0)}));
  check(run.failureKind == "none", "the spline document evaluates: " + run.message);
  if (run.bodies.empty())
    return;
  bool hasBspline = false;
  for (TopExp_Explorer explorer(run.bodies.front().shape, TopAbs_EDGE); explorer.More();
       explorer.Next()) {
    const BRepAdaptor_Curve curve(TopoDS::Edge(explorer.Current()));
    if (curve.GetType() == GeomAbs_BSplineCurve) {
      hasBspline = true;
      break;
    }
  }
  check(hasBspline, "the solid retains a genuine BSpline edge, not a control polygon");
}

void TestFacePlane() {
  std::printf("\n[8] a sketch on a picked planar face\n");
  // The box's top face at z = 20. The sketch plane's origin is the world
  // origin projected onto it — (0, 0, 20) — NOT the face centroid (30, 30, 20),
  // which is the departure `create_profile` makes and a sketch must not.
  nlohmann::json planeRef = {
      {"ast",
       {{"kind", "faces"},
        {"scope", nlohmann::json::array({{{"source", "op"}, {"opId", kBoxId}}})},
        {"filters",
         nlohmann::json::array(
             {{{"name", "role"},
               {"args", nlohmann::json::array({{{"arg", "ident"}, {"value", "top"}}})}}})}}},
      {"arity", "one"},
      {"anchors", nlohmann::json::array()},
      {"onEmpty", "error"}};
  const Run run =
      Evaluate(Program({Box(kBoxId, 60, 60, 20), Sketch(kSketchId, planeRef, RectangleEntities()),
                        Extrude(kExtrudeId, kSketchId, 5.0)}));
  check(run.failureKind == "none", "the document evaluates: " + run.message);
  if (run.bodies.size() < 2)
    return;
  const aeth::EvaluatedBody& prism = run.bodies.back();
  checkClose(Volume(prism), 40.0 * 30.0 * 5.0, 1e-9, "the region extrudes to its own volume");
  Bnd_Box bounds = Bounds(prism);
  double xMin = 0;
  double yMin = 0;
  double zMin = 0;
  double xMax = 0;
  double yMax = 0;
  double zMax = 0;
  bounds.Get(xMin, yMin, zMin, xMax, yMax, zMax);
  // Rule 4 of the basis rule, measured: the frame origin is on the face, at the
  // world origin's projection. A centroid origin would put xMin at 30.
  checkClose(zMin, 20.0, 1e-6, "it sits ON the picked face");
  checkClose(zMax, 25.0, 1e-6, "and rises along the face normal");
  checkClose(xMin, 0.0, 1e-6, "the frame origin is the world origin projected, not the centroid");
  checkClose(yMin, 0.0, 1e-6, "in v as well as u");
}

void TestWorldXzTable() {
  std::printf("\n[9] world(xz)'s normal is -y, per the normative table\n");
  const Run run = Evaluate(Program({Sketch(kSketchId, WorldPlaneRef("xz"), RectangleEntities()),
                                    Extrude(kExtrudeId, kSketchId, 10.0)}));
  check(run.failureKind == "none", "the document evaluates: " + run.message);
  if (run.bodies.empty())
    return;
  Bnd_Box bounds = Bounds(run.bodies.front());
  double xMin = 0;
  double yMin = 0;
  double zMin = 0;
  double xMax = 0;
  double yMax = 0;
  double zMax = 0;
  bounds.Get(xMin, yMin, zMin, xMax, yMax, zMax);
  checkClose(yMin, -10.0, 1e-6, "it extrudes along -y");
  checkClose(yMax, 0.0, 1e-6, "starting at the plane");
  // u = +x, v = +z: the 40 mm side runs along x and the 30 mm side along z.
  checkClose(xMax - xMin, 40.0, 1e-6, "u is +x");
  checkClose(zMax - zMin, 30.0, 1e-6, "v is +z");
}

void TestProjectedGeometryResolves() {
  std::printf("\n[10] projected sketch geometry resolves its driving edge\n");
  const nlohmann::json projected = nlohmann::json::array({{{"eid", Eid('P')},
                                                           {"source", BoxTopEdgeRef()},
                                                           {"mode", "project"},
                                                           {"construction", true}}});
  const Run run = Evaluate(Program({
      Box(kBoxId, 60, 60, 20),
      Sketch(kSketchId, BoxFaceRef("top"), {}, nlohmann::json(), projected),
  }));
  check(run.failureKind == "none", "the projection resolves: " + run.message);
  check(run.bodies.size() == 1, "construction projection does not create a body");
}

void TestUnsupportedProjectedModeRefuses() {
  std::printf("\n[11] unsupported projected modes fail explicitly\n");
  const nlohmann::json projected = nlohmann::json::array({{{"eid", Eid('Q')},
                                                           {"source", BoxTopEdgeRef()},
                                                           {"mode", "include"},
                                                           {"construction", true}}});
  const Run run = Evaluate(Program({
      Box(kBoxId, 60, 60, 20),
      Sketch(kSketchId, BoxFaceRef("top"), {}, nlohmann::json(), projected),
  }));
  check(run.failureKind == "operation", "unsupported projected mode is rejected");
  check(run.message.find("mode 'include'") != std::string::npos,
        "the refusal names the unsupported mode");
}

void TestModelFaceDownstreamConsumers() {
  std::printf("\n[12] model-face sketches feed Revolve, Sweep, and Loft\n");
  const Run revolve = Evaluate(Program({
      Box(kBoxId, 60, 60, 20),
      Sketch("aaaaaaaa-0000-4000-8000-000000000011", BoxFaceRef("top"), RectangleEntities()),
      RevolveRelative("aaaaaaaa-0000-4000-8000-000000000012",
                      "aaaaaaaa-0000-4000-8000-000000000011", "right"),
  }));
  check(revolve.failureKind == "none", "model-face Revolve evaluates: " + revolve.message);
  check(revolve.bodies.size() == 2, "model-face Revolve keeps the host and result bodies");
  if (revolve.bodies.size() == 2)
    check(Volume(revolve.bodies.back()) > 0.0, "model-face Revolve has positive volume");

  const Run sweep = Evaluate(Program({
      Box(kBoxId, 60, 60, 20),
      Sketch("aaaaaaaa-0000-4000-8000-000000000021", BoxFaceRef("top"), RectangleEntities()),
      SweepNormal("aaaaaaaa-0000-4000-8000-000000000022", "aaaaaaaa-0000-4000-8000-000000000021",
                  40.0),
  }));
  check(sweep.failureKind == "none", "model-face Sweep evaluates: " + sweep.message);
  check(sweep.bodies.size() == 2, "model-face Sweep keeps the host and result bodies");
  if (sweep.bodies.size() == 2)
    check(Volume(sweep.bodies.back()) > 0.0, "model-face Sweep has positive volume");

  const Run loft = Evaluate(Program({
      Box(kBoxId, 60, 60, 20),
      Sketch("aaaaaaaa-0000-4000-8000-000000000031", BoxFaceRef("bottom"), RectangleEntities()),
      Sketch("aaaaaaaa-0000-4000-8000-000000000032", BoxFaceRef("top"), RectangleEntities()),
      Loft("aaaaaaaa-0000-4000-8000-000000000033",
           {"aaaaaaaa-0000-4000-8000-000000000031", "aaaaaaaa-0000-4000-8000-000000000032"}),
  }));
  check(loft.failureKind == "none", "model-face Loft evaluates: " + loft.message);
  check(loft.bodies.size() == 2, "model-face Loft keeps the host and result bodies");
  if (loft.bodies.size() == 2)
    check(Volume(loft.bodies.back()) > 0.0, "model-face Loft has positive volume");
}

} // namespace

int main() {
  std::printf("sketch region (CAP-038)\n");
  TestRectangleOnGround();
  TestCriterionContour();
  TestSingleCircle();
  TestSolvedValuesWin();
  TestOpenContourEnclosesNothing();
  TestGuideOnlySketch();
  TestSplineRegion();
  TestFacePlane();
  TestWorldXzTable();
  TestProjectedGeometryResolves();
  TestUnsupportedProjectedModeRefuses();
  TestModelFaceDownstreamConsumers();
  if (g_failures == 0) {
    std::printf("\nALL SKETCH REGION TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d SKETCH REGION CHECK(S) FAILED\n", g_failures);
  return 1;
}
