// CAP-139 Revolve topology tournament. Every professional mode is executed
// against real OCCT geometry and durable selectors; no bbox-derived axis is
// admitted on the v2 path.

#include <atomic>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <string>
#include <utility>
#include <vector>

#include <BRepGProp.hxx>
#include <GProp_GProps.hxx>
#include <nlohmann/json.hpp>

#include "geometry.hpp"
#include "naming_registry.hpp"

namespace {
int failures = 0;
// The superiority gate consumes counts, not a log scrape. Every check is
// recorded so `tools/superiority` can prove zero failures AND prove the case
// count did not shrink, which is how SUPERIORITY_LAW section 3 defines a
// tournament regression.
std::vector<std::pair<std::string, bool>> cases;
void check(bool value, const std::string& label) {
  cases.emplace_back(label, value);
  if (value)
    printf("  ok   %s\n", label.c_str());
  else {
    printf("  FAIL %s\n", label.c_str());
    ++failures;
  }
}
void close(double actual, double expected, double tolerance, const std::string& label) {
  check(std::abs(actual - expected) <= tolerance, label + " (" + std::to_string(actual) + ")");
}
std::string Id(char suffix) { return std::string("aaaaaaaa-0000-4000-8000-00000000000") + suffix; }
std::uint64_t StableOrdinal(const std::string& value) {
  std::uint64_t hash = 14695981039346656037ull;
  for (const unsigned char byte : value) {
    hash ^= byte;
    hash *= 1099511628211ull;
  }
  return hash;
}
nlohmann::json Metadata(bool suppressed = false) {
  nlohmann::json metadata = {{"createdAt", "2026-08-08T00:00:00.000Z"},
                             {"createdBy", {{"kind", "user"}}}};
  if (suppressed)
    metadata["suppressed"] = true;
  return metadata;
}
nlohmann::json Ref(const std::string& kind, nlohmann::json source,
                   nlohmann::json filters = nlohmann::json::array()) {
  return {{"ast",
           {{"kind", kind},
            {"scope", nlohmann::json::array({std::move(source)})},
            {"filters", std::move(filters)}}},
          {"arity", "one"},
          {"anchors", nlohmann::json::array()},
          {"onEmpty", "error"}};
}
nlohmann::json World(const std::string& kind, const std::string& name) {
  return Ref(kind, {{"source", "world"}, {"world", name}});
}
nlohmann::json RoleRef(const std::string& kind, const std::string& operationId,
                       const std::string& role) {
  return Ref(kind, {{"source", "op"}, {"opId", operationId}},
             nlohmann::json::array(
                 {{{"name", "role"},
                   {"args", nlohmann::json::array({{{"arg", "ident"}, {"value", role}}})}}}));
}
nlohmann::json TokenRef(const std::string& kind, const std::string& token) {
  return Ref(kind, {{"source", "token"}, {"token", token}});
}
nlohmann::json Line(char suffix, double u0, double v0, double u1, double v1,
                    bool construction = false) {
  return {{"eid", std::string("ent_") + suffix + std::string(25, '0')},
          {"kind", "line"},
          {"p1", {u0, v0}},
          {"p2", {u1, v1}},
          {"construction", construction}};
}
nlohmann::json Sketch(const std::string& id, std::vector<nlohmann::json> entities) {
  nlohmann::json list = nlohmann::json::array();
  for (nlohmann::json& entity : entities)
    list.push_back(std::move(entity));
  return {{"id", id},
          {"type", "sketch"},
          {"schemaVersion", 1},
          {"name", "Shaft profile"},
          {"parameters",
           {{"plane", World("faces", "xz")},
            {"entities", std::move(list)},
            {"constraints", nlohmann::json::array()}}},
          {"metadata", Metadata()}};
}
std::vector<nlohmann::json> ShaftProfile(bool constructionAxis = false) {
  std::vector<nlohmann::json> result = {Line('a', 10, 0, 20, 0), Line('b', 20, 0, 20, 30),
                                        Line('c', 20, 30, 10, 30), Line('d', 10, 30, 10, 0)};
  if (constructionAxis)
    result.push_back(Line('z', 0, -5, 0, 35, true));
  return result;
}
std::vector<nlohmann::json> CoreProfile() {
  return {Line('a', 0, 0, 10, 0), Line('b', 10, 0, 10, 30), Line('c', 10, 30, 0, 30),
          Line('d', 0, 30, 0, 0)};
}
nlohmann::json Box(const std::string& id, double width, double depth, double height,
                   double originX = 0, double originY = 0, double originZ = 0) {
  return {{"id", id},
          {"type", "create_box"},
          {"schemaVersion", 1},
          {"name", "Target"},
          {"outputBodyId", "b" + id.substr(1)},
          {"parameters",
           {{"width", width},
            {"depth", depth},
            {"height", height},
            {"placement",
             {{"origin", {originX, originY, originZ}},
              {"zDirection", {0, 0, 1}},
              {"xDirection", {1, 0, 0}}}}}},
          {"metadata", Metadata()}};
}
nlohmann::json RotationalPrimitive(const std::string& id, const std::string& type) {
  nlohmann::json parameters = {
      {"placement",
       {{"origin", {0, 0, -5}}, {"zDirection", {0, 0, 1}}, {"xDirection", {1, 0, 0}}}}};
  if (type == "create_cone") {
    parameters["radiusBottom"] = 5;
    parameters["radiusTop"] = 2;
    parameters["height"] = 40;
  } else {
    parameters["majorRadius"] = 8;
    parameters["minorRadius"] = 2;
  }
  return {{"id", id},
          {"type", type},
          {"schemaVersion", 1},
          {"name", "Rotational axis host"},
          {"outputBodyId", "b" + id.substr(1)},
          {"parameters", std::move(parameters)},
          {"metadata", Metadata()}};
}
nlohmann::json Cylinder(const std::string& id) {
  return {{"id", id},
          {"type", "create_cylinder"},
          {"schemaVersion", 1},
          {"name", "Axis host"},
          {"outputBodyId", "b" + id.substr(1)},
          {"parameters",
           {{"radius", 3},
            {"height", 40},
            {"placement",
             {{"origin", {0, 0, -5}}, {"zDirection", {0, 0, 1}}, {"xDirection", {1, 0, 0}}}}}},
          {"metadata", Metadata()}};
}
nlohmann::json DatumAxis(const std::string& id, const std::string& cylinderId) {
  return {
      {"id", id},
      {"type", "datum_axis"},
      {"schemaVersion", 1},
      {"name", "Shaft axis"},
      {"parameters", {{"mode", "cylinderAxis"}, {"face", RoleRef("faces", cylinderId, "wall")}}},
      {"metadata", Metadata()}};
}
nlohmann::json Revolve(const std::string& id, const std::string& profileId,
                       nlohmann::json axisSource, nlohmann::json axisRef, nlohmann::json extent,
                       nlohmann::json boolean = {{"mode", "newBody"}},
                       nlohmann::json thin = nullptr, const std::string& direction = "forward",
                       bool suppressed = false) {
  nlohmann::json parameters = {{"profileOperationId", profileId},
                               {"axisSource", axisSource},
                               {"extent", std::move(extent)},
                               {"direction", direction},
                               {"boolean", std::move(boolean)}};
  if (axisSource.at("kind") == "edge")
    parameters["axisEdge"] = std::move(axisRef);
  else
    parameters["axisFace"] = std::move(axisRef);
  if (!thin.is_null())
    parameters["thin"] = std::move(thin);
  return {{"id", id},
          {"type", "revolve"},
          {"schemaVersion", 2},
          {"name", "Revolve 1"},
          {"outputBodyId", "b" + id.substr(1)},
          {"parameters", std::move(parameters)},
          {"metadata", Metadata(suppressed)}};
}
nlohmann::json RevolveFace(const std::string& id, nlohmann::json faceRef, nlohmann::json axisRef) {
  return {{"id", id},
          {"type", "revolve"},
          {"schemaVersion", 2},
          {"name", "Face revolve"},
          {"outputBodyId", "b" + id.substr(1)},
          {"parameters",
           {{"faceProfile", std::move(faceRef)},
            {"axisSource", {{"kind", "edge"}}},
            {"axisEdge", std::move(axisRef)},
            {"extent", {{"mode", "oneSide"}, {"angleDegrees", 90}}},
            {"direction", "forward"},
            {"boolean", {{"mode", "newBody"}}}}},
          {"metadata", Metadata()}};
}
nlohmann::json Mirror(const std::string& id, const std::string& seed,
                      nlohmann::json plane = World("faces", "xy")) {
  return {
      {"id", id},
      {"type", "mirror"},
      {"outputBodyId", "b" + id.substr(1)},
      {"parameters", {{"sourceOperationId", seed}, {"plane", std::move(plane)}, {"merge", false}}},
      {"metadata", Metadata()}};
}
nlohmann::json PatternLinear(const std::string& id, const std::string& seed) {
  return {{"id", id},
          {"type", "pattern_linear"},
          {"outputBodyId", "b" + id.substr(1)},
          {"parameters",
           {{"seedOperationId", seed},
            {"count", 3},
            {"spacing", 60},
            {"direction", {1, 0, 0}},
            {"op", "fuseInstances"}}},
          {"metadata", Metadata()}};
}
struct Run {
  std::vector<aeth::EvaluatedBody> bodies;
  std::string failure;
};
Run Evaluate(const nlohmann::json& program) {
  std::atomic_bool cancelled{false};
  aeth::NamingRegistry registry;
  try {
    return {aeth::EvaluateOperations(program, cancelled, nullptr, &registry), ""};
  } catch (const std::exception& error) {
    return {{}, error.what()};
  }
}
double Volume(const aeth::EvaluatedBody& body) {
  GProp_GProps properties;
  BRepGProp::VolumeProperties(body.shape, properties);
  return properties.Mass();
}

void TestExtentsAndWorldAxis() {
  printf("\n[world axis + angular extent suite]\n");
  const std::string sketch = Id('1');
  const double fullVolume = 9000.0 * std::acos(-1.0);
  const std::vector<std::pair<nlohmann::json, double>> extents = {
      {{{"mode", "full"}}, 1.0},
      {{{"mode", "oneSide"}, {"angleDegrees", 75}}, 75.0 / 360.0},
      {{{"mode", "symmetric"}, {"angleDegrees", 120}}, 120.0 / 360.0},
      {{{"mode", "twoSided"}, {"forwardAngleDegrees", 30}, {"backwardAngleDegrees", 210}},
       240.0 / 360.0}};
  char suffix = '2';
  for (const auto& [extent, fraction] : extents) {
    const Run run = Evaluate(nlohmann::json::array(
        {Sketch(sketch, ShaftProfile()),
         Revolve(Id(suffix++), sketch, {{"kind", "edge"}}, World("edges", "z"), extent)}));
    check(run.failure.empty(), "extent evaluates: " + run.failure);
    if (run.failure.empty() && !run.bodies.empty())
      close(Volume(run.bodies.back()), fullVolume * fraction, 1e-4,
            "extent volume measures exact included angle");
  }
  const Run reverse = Evaluate(
      nlohmann::json::array({Sketch(sketch, ShaftProfile()),
                             Revolve(Id('f'), sketch, {{"kind", "edge"}}, World("edges", "z"),
                                     {{"mode", "oneSide"}, {"angleDegrees", 75}},
                                     {{"mode", "newBody"}}, nullptr, "reverse")}));
  check(reverse.failure.empty(), "reverse direction evaluates: " + reverse.failure);
  if (reverse.failure.empty())
    close(Volume(reverse.bodies.back()), fullVolume * (75.0 / 360.0), 1e-4,
          "reverse preserves the exact included-angle volume");
}

void TestAssociativeAxes() {
  printf("\n[construction, model-edge, rotational-face, and datum axes]\n");
  const std::string sketch = Id('1');
  const Run construction = Evaluate(nlohmann::json::array(
      {Sketch(sketch, ShaftProfile(true)),
       Revolve(Id('2'), sketch, {{"kind", "edge"}}, RoleRef("edges", sketch, "construction-edge"),
               {{"mode", "full"}})}));
  check(construction.failure.empty(), "construction-line axis evaluates: " + construction.failure);

  const std::string selectedEid = std::string("ent_z") + std::string(25, '0');
  nlohmann::json selectedConstruction = TokenRef(
      "edges", "t:" + sketch + "/construction-edge/" + std::to_string(StableOrdinal(selectedEid)));
  selectedConstruction["anchors"] =
      nlohmann::json::array({{{"token", "t:" + sketch + "/construction-edge/" +
                                            std::to_string(StableOrdinal(selectedEid))},
                              {"kind", "edge"},
                              {"curve", "line"}}});
  const nlohmann::json stableRevolve =
      Revolve(Id('e'), sketch, {{"kind", "edge"}}, selectedConstruction, {{"mode", "full"}});
  const Run oneConstruction =
      Evaluate(nlohmann::json::array({Sketch(sketch, ShaftProfile(true)), stableRevolve}));
  std::vector<nlohmann::json> twoAxes = ShaftProfile(true);
  twoAxes.push_back(Line('y', 5, -5, 5, 35, true));
  const Run addedEarlierConstruction =
      Evaluate(nlohmann::json::array({Sketch(sketch, twoAxes), stableRevolve}));
  check(oneConstruction.failure.empty() && addedEarlierConstruction.failure.empty(),
        "eid-derived construction token survives another line being inserted: " +
            addedEarlierConstruction.failure);
  if (oneConstruction.failure.empty() && addedEarlierConstruction.failure.empty())
    close(Volume(addedEarlierConstruction.bodies.back()), Volume(oneConstruction.bodies.back()),
          1e-6, "construction reference stays on the selected eid, never the new ordinal");

  std::vector<nlohmann::json> reversedAxis = ShaftProfile();
  reversedAxis.push_back(Line('z', 0, 35, 0, -5, true));
  const Run reversedConstruction =
      Evaluate(nlohmann::json::array({Sketch(sketch, reversedAxis), stableRevolve}));
  check(reversedConstruction.failure.empty(),
        "construction endpoint reversal preserves the selected semantic axis: " +
            reversedConstruction.failure);
  if (oneConstruction.failure.empty() && reversedConstruction.failure.empty())
    close(Volume(reversedConstruction.bodies.back()), Volume(oneConstruction.bodies.back()), 1e-6,
          "axis endpoint order cannot reverse the separately stored direction");

  const std::string box = Id('3');
  nlohmann::json edgeRevolve =
      Revolve(Id('4'), sketch, {{"kind", "edge"}},
              TokenRef("edges", "t:" + box + "/vertical-edge/0"), {{"mode", "full"}});
  edgeRevolve["parameters"]["projectAxisToProfilePlane"] = true;
  const Run edge = Evaluate(
      nlohmann::json::array({Box(box, 8, 8, 40), Sketch(sketch, ShaftProfile()), edgeRevolve}));
  check(edge.failure.empty(), "arbitrary named model edge evaluates: " + edge.failure);

  const std::string cylinder = Id('5');
  const Run face = Evaluate(
      nlohmann::json::array({Cylinder(cylinder), Sketch(sketch, ShaftProfile()),
                             Revolve(Id('6'), sketch, {{"kind", "rotationalFace"}},
                                     RoleRef("faces", cylinder, "wall"), {{"mode", "full"}})}));
  check(face.failure.empty(), "exact cylindrical-face axis evaluates: " + face.failure);
  nlohmann::json grownCylinder = Cylinder(cylinder);
  grownCylinder["parameters"]["height"] = 80;
  const Run trimmedFace = Evaluate(
      nlohmann::json::array({grownCylinder, Sketch(sketch, ShaftProfile()),
                             Revolve(Id('6'), sketch, {{"kind", "rotationalFace"}},
                                     RoleRef("faces", cylinder, "wall"), {{"mode", "full"}})}));
  check(face.failure.empty() && trimmedFace.failure.empty(),
        "analytic-face trim/height change preserves its support axis: " + trimmedFace.failure);
  if (face.failure.empty() && trimmedFace.failure.empty())
    close(Volume(trimmedFace.bodies.back()), Volume(face.bodies.back()), 1e-6,
          "rotational-face trim cannot change the infinite-axis result");

  for (const std::string primitive : {"create_cone", "create_torus"}) {
    const std::string host = primitive == "create_cone" ? Id('9') : Id('0');
    const Run analyticFace = Evaluate(
        nlohmann::json::array({RotationalPrimitive(host, primitive), Sketch(sketch, ShaftProfile()),
                               Revolve(primitive == "create_cone" ? Id('a') : Id('b'), sketch,
                                       {{"kind", "rotationalFace"}}, RoleRef("faces", host, "wall"),
                                       {{"mode", "full"}})}));
    check(analyticFace.failure.empty(),
          primitive + " exact face axis evaluates: " + analyticFace.failure);
  }

  const std::string datum = Id('7');
  const Run datumRun = Evaluate(nlohmann::json::array(
      {Cylinder(cylinder), DatumAxis(datum, cylinder), Sketch(sketch, ShaftProfile()),
       Revolve(Id('8'), sketch, {{"kind", "edge"}}, RoleRef("edges", datum, "axis"),
               {{"mode", "full"}})}));
  check(datumRun.failure.empty(), "datum-axis reference evaluates: " + datumRun.failure);

  nlohmann::json associated =
      Revolve(Id('c'), sketch, {{"kind", "edge"}},
              TokenRef("edges", "t:" + box + "/vertical-edge/0"), {{"mode", "full"}});
  associated["parameters"]["projectAxisToProfilePlane"] = true;
  const Run before = Evaluate(
      nlohmann::json::array({Box(box, 8, 8, 40), Sketch(sketch, ShaftProfile()), associated}));
  const Run after = Evaluate(
      nlohmann::json::array({Box(box, 8, 8, 40, 2), Sketch(sketch, ShaftProfile()), associated}));
  check(before.failure.empty() && after.failure.empty(),
        "named edge survives an upstream host move");
  if (before.failure.empty() && after.failure.empty())
    check(std::abs(Volume(before.bodies.back()) - Volume(after.bodies.back())) > 1.0,
          "rebuild follows the moved associative axis instead of cached geometry");
}

void TestProfilesAndDownstreamConsumers() {
  printf("\n[model-face profile, region selection, mirror, and pattern]\n");
  const std::string faceHost = Id('1');
  const Run modelFace = Evaluate(
      nlohmann::json::array({Box(faceHost, 20, 12, 8),
                             RevolveFace(Id('2'), RoleRef("faces", faceHost, "bottom"),
                                         TokenRef("edges", "t:" + faceHost + "/bottom-edge/0"))}));
  check(modelFace.failure.empty(), "planar model-face profile evaluates: " + modelFace.failure);

  const std::string sketch = Id('3');
  std::vector<nlohmann::json> islands = ShaftProfile();
  islands.push_back(Line('e', 24, 0, 28, 0));
  islands.push_back(Line('f', 28, 0, 28, 30));
  islands.push_back(Line('g', 28, 30, 24, 30));
  islands.push_back(Line('h', 24, 30, 24, 0));
  const Run allRegions = Evaluate(nlohmann::json::array(
      {Sketch(sketch, islands),
       Revolve(Id('4'), sketch, {{"kind", "edge"}}, World("edges", "z"), {{"mode", "full"}})}));
  check(allRegions.failure.empty(),
        "multiple disjoint sketch regions evaluate: " + allRegions.failure);
  if (allRegions.failure.empty())
    check(allRegions.bodies.back().probes.solidCount == 2,
          "all selected islands remain two exact solids in one semantic result");

  const std::string revolve = Id('5');
  const Run mirror = Evaluate(
      nlohmann::json::array({Sketch(sketch, ShaftProfile()),
                             Revolve(revolve, sketch, {{"kind", "edge"}}, World("edges", "z"),
                                     {{"mode", "oneSide"}, {"angleDegrees", 120}}),
                             Mirror(Id('6'), revolve)}));
  check(mirror.failure.empty() && mirror.bodies.size() == 2,
        "Revolve remains a valid downstream mirror seed: " + mirror.failure);

  const Run startCapRole = Evaluate(
      nlohmann::json::array({Sketch(sketch, ShaftProfile()),
                             Revolve(revolve, sketch, {{"kind", "edge"}}, World("edges", "z"),
                                     {{"mode", "oneSide"}, {"angleDegrees", 75}}),
                             Mirror(Id('8'), revolve, RoleRef("faces", revolve, "cap-start"))}));
  check(startCapRole.failure.empty(),
        "partial Revolve publishes a usable cap-start semantic role: " + startCapRole.failure);
  const Run endCapRole = Evaluate(
      nlohmann::json::array({Sketch(sketch, ShaftProfile()),
                             Revolve(revolve, sketch, {{"kind", "edge"}}, World("edges", "z"),
                                     {{"mode", "oneSide"}, {"angleDegrees", 75}}),
                             Mirror(Id('9'), revolve, RoleRef("faces", revolve, "cap-end"))}));
  check(endCapRole.failure.empty(),
        "partial Revolve publishes a usable cap-end semantic role: " + endCapRole.failure);

  const Run pattern = Evaluate(nlohmann::json::array(
      {Sketch(sketch, ShaftProfile()),
       Revolve(revolve, sketch, {{"kind", "edge"}}, World("edges", "z"), {{"mode", "full"}}),
       PatternLinear(Id('7'), revolve)}));
  check(pattern.failure.empty() && pattern.bodies.size() == 1,
        "Revolve remains a valid downstream pattern seed: " + pattern.failure);
  if (pattern.failure.empty())
    close(Volume(pattern.bodies.back()), 3.0 * 9000.0 * std::acos(-1.0), 1e-3,
          "pattern preserves all three revolved instance volumes");
}

void TestReferenceRefusalsAndColdReplay() {
  printf("\n[reference refusal attribution + 20 cold deterministic replays]\n");
  const std::string sketch = Id('1');
  std::vector<nlohmann::json> ambiguousProfile = ShaftProfile(true);
  ambiguousProfile.push_back(Line('y', -3, -5, -3, 35, true));
  const Run ambiguous = Evaluate(nlohmann::json::array(
      {Sketch(sketch, ambiguousProfile),
       Revolve(Id('2'), sketch, {{"kind", "edge"}}, RoleRef("edges", sketch, "construction-edge"),
               {{"mode", "full"}})}));
  check(ambiguous.failure.find("ambiguous") != std::string::npos ||
            ambiguous.failure.find("multiple") != std::string::npos ||
            ambiguous.failure.find("several") != std::string::npos ||
            ambiguous.failure.find("2 entities") != std::string::npos ||
            ambiguous.failure.find("arity") != std::string::npos,
        "plural construction axes refuse as ambiguous instead of choosing first: " +
            ambiguous.failure);

  std::vector<nlohmann::json> coaxialProfile = ShaftProfile();
  coaxialProfile.push_back(Line('y', 0, -5, 0, 15, true));
  coaxialProfile.push_back(Line('z', 0, 15, 0, 35, true));
  const Run coaxial = Evaluate(nlohmann::json::array(
      {Sketch(sketch, coaxialProfile),
       Revolve(Id('a'), sketch, {{"kind", "edge"}}, RoleRef("edges", sketch, "construction-edge"),
               {{"mode", "full"}})}));
  check(coaxial.failure.empty(),
        "plural coaxial successors collapse to one infinite axis: " + coaxial.failure);
  if (coaxial.failure.empty())
    close(Volume(coaxial.bodies.back()), 9000.0 * std::acos(-1.0), 1e-4,
          "coaxial successor collapse preserves exact geometry");

  const std::string box = Id('3');
  const Run wrongKind = Evaluate(
      nlohmann::json::array({Box(box, 8, 8, 40), Sketch(sketch, ShaftProfile()),
                             Revolve(Id('4'), sketch, {{"kind", "rotationalFace"}},
                                     RoleRef("faces", box, "bottom"), {{"mode", "full"}})}));
  check(wrongKind.failure.find("rotational") != std::string::npos,
        "planar face axis refuses with an attributed wrong-kind message");

  const Run lost = Evaluate(
      nlohmann::json::array({Sketch(sketch, ShaftProfile()),
                             Revolve(Id('5'), sketch, {{"kind", "edge"}},
                                     RoleRef("edges", Id('9'), "axis"), {{"mode", "full"}})}));
  check(!lost.failure.empty(), "lost associative axis refuses with no stale result");

  bool deterministic = true;
  double firstVolume = 0.0;
  for (int replay = 0; replay < 20; ++replay) {
    const Run run = Evaluate(nlohmann::json::array(
        {Sketch(sketch, ShaftProfile(true)),
         Revolve(
             Id('6'), sketch, {{"kind", "edge"}}, RoleRef("edges", sketch, "construction-edge"),
             {{"mode", "twoSided"}, {"forwardAngleDegrees", 30}, {"backwardAngleDegrees", 210}})}));
    if (!run.failure.empty() || run.bodies.empty()) {
      deterministic = false;
      continue;
    }
    const double volume = Volume(run.bodies.back());
    if (replay == 0)
      firstVolume = volume;
    else if (std::abs(volume - firstVolume) > 1e-9)
      deterministic = false;
  }
  check(deterministic, "20 fresh registries replay to the same exact volume");
}

void TestThinBooleanFailureAndSuppression() {
  printf("\n[unequal Thin, explicit booleans, refusal, suppression]\n");
  const std::string openSketch = Id('1');
  const Run thin = Evaluate(nlohmann::json::array(
      {Sketch(openSketch, {Line('a', 12, 0, 12, 30)}),
       Revolve(Id('2'), openSketch, {{"kind", "edge"}}, World("edges", "z"),
               {{"mode", "oneSide"}, {"angleDegrees", 270}}, {{"mode", "newBody"}},
               {{"sideOneMm", 2}, {"sideTwoMm", 5}})}));
  check(thin.failure.empty(), "270-degree unequal-wall Thin evaluates: " + thin.failure);
  if (thin.failure.empty()) {
    const double expected = std::acos(-1.0) * (14.0 * 14.0 - 7.0 * 7.0) * 30.0 * 0.75;
    close(Volume(thin.bodies.back()), expected, 1e-4,
          "unequal Thin matches its analytic annular-sector oracle");
    check(thin.bodies.back().probes.valid && thin.bodies.back().probes.solidCount == 1,
          "Thin produces one valid watertight solid");
  }

  const Run flippedThin = Evaluate(nlohmann::json::array(
      {Sketch(openSketch, {Line('a', 12, 0, 12, 30)}),
       Revolve(Id('c'), openSketch, {{"kind", "edge"}}, World("edges", "z"),
               {{"mode", "oneSide"}, {"angleDegrees", 270}}, {{"mode", "newBody"}},
               {{"sideOneMm", 5}, {"sideTwoMm", 2}})}));
  check(flippedThin.failure.empty(), "flipped unequal-wall Thin evaluates: " + flippedThin.failure);
  if (flippedThin.failure.empty()) {
    const double expected = std::acos(-1.0) * (17.0 * 17.0 - 10.0 * 10.0) * 30.0 * 0.75;
    close(Volume(flippedThin.bodies.back()), expected, 1e-4,
          "flipping unequal walls moves material to the opposite side");
  }

  const Run multiSegmentThin = Evaluate(nlohmann::json::array(
      {Sketch(Id('d'), {Line('a', 12, 0, 12, 15), Line('b', 12, 15, 16, 15)}),
       Revolve(Id('e'), Id('d'), {{"kind", "edge"}}, World("edges", "z"),
               {{"mode", "oneSide"}, {"angleDegrees", 180}}, {{"mode", "newBody"}},
               {{"sideOneMm", 1}, {"sideTwoMm", 1}})}));
  check(multiSegmentThin.failure.empty() && !multiSegmentThin.bodies.empty() &&
            multiSegmentThin.bodies.back().probes.valid,
        "connected multi-segment Thin path produces one valid solid: " + multiSegmentThin.failure);

  const std::string target = Id('3');
  const std::string profile = Id('4');
  char booleanSuffix = '5';
  for (const std::string mode : {"join", "cut", "intersect"}) {
    const Run run = Evaluate(nlohmann::json::array(
        {Box(target, 50, 50, 30), Sketch(profile, mode == "cut" ? CoreProfile() : ShaftProfile()),
         Revolve(Id(booleanSuffix++), profile, {{"kind", "edge"}}, World("edges", "z"),
                 {{"mode", "full"}}, {{"mode", mode}, {"targetOperationId", target}})}));
    check(run.failure.empty(), "explicit " + mode + " evaluates: " + run.failure);
    if (run.failure.empty())
      check(run.bodies.size() == 1, mode + " consumes only its exact target");
  }

  const Run wrongAxis = Evaluate(nlohmann::json::array(
      {Sketch(profile, ShaftProfile()),
       Revolve(Id('9'), profile, {{"kind", "edge"}}, World("edges", "y"), {{"mode", "full"}})}));
  check(!wrongAxis.failure.empty(), "non-coplanar or crossing axis fails closed");

  const Run suppressed = Evaluate(nlohmann::json::array(
      {Sketch(profile, ShaftProfile()),
       Revolve(Id('8'), profile, {{"kind", "edge"}}, World("edges", "z"), {{"mode", "full"}},
               {{"mode", "newBody"}}, nullptr, "forward", true)}));
  check(suppressed.failure.empty() && suppressed.bodies.empty(),
        "suppressed Revolve replays without geometry and without failure");
}
} // namespace

int main() {
  printf("[revolve-topology] CAP-139 superiority tournament\n");
  TestExtentsAndWorldAxis();
  TestAssociativeAxes();
  TestProfilesAndDownstreamConsumers();
  TestReferenceRefusalsAndColdReplay();
  TestThinBooleanFailureAndSuppression();
  printf("\n[revolve-topology] failures: %d\n", failures);
  printf("[revolve-topology] cases: %d\n", static_cast<int>(cases.size()));
  if (const char* const path = std::getenv("AETH_REVOLVE_TOURNAMENT_JSON")) {
    nlohmann::json record;
    record["suite"] = "revolve-topology";
    record["total"] = static_cast<int>(cases.size());
    record["failures"] = failures;
    nlohmann::json entries = nlohmann::json::array();
    for (const auto& entry : cases)
      entries.push_back({{"label", entry.first}, {"ok", entry.second}});
    record["cases"] = entries;
    std::ofstream output(path, std::ios::binary | std::ios::trunc);
    if (output)
      output << record.dump(2);
    else
      printf("[revolve-topology] could not write %s\n", path);
  }
  return failures == 0 ? 0 : 1;
}
