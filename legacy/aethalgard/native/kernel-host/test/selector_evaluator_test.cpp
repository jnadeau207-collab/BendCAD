// Native integration tests for the AQL selector evaluator (integration tranche
// N4; plan 05 §3.2, §4.1, §5, §6.4). These drive the REAL evaluation path —
// EvaluateOperations with a registry, exactly as the server's `query` handler
// threads it — then evaluate serialized ASTs against that replay state. They
// pin:
//
//  1. the set-refinement pipeline and per-stage cardinalities (§4.1/§8.1);
//  2. a representative filter from EVERY §3.2 catalog family, over a
//     box / box+hole / fillet program;
//  3. dihedral convex/concave classification (§5.3);
//  4. canonical ordering determinism (§6.4);
//  5. the ResolvedEntity JSON projection (§2);
//  6. the fail-closed deferral of sketch/tag/world sources and body/region
//     head kinds — the cardinal no-silent-misreference rule.
#include <array>
#include <atomic>
#include <cmath>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

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

void checkEqual(const std::size_t actual, const std::size_t expected, const std::string& label) {
  if (actual == expected) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s (expected %zu, got %zu)\n", label.c_str(), expected, actual);
    g_failures += 1;
  }
}

const std::string kBoxOp = "aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa";
const std::string kHoleOp = "bbbbbbbb-2222-4b22-8b22-bbbbbbbbbbbb";
const std::string kFilletOp = "eeeeeeee-5555-4e55-8e55-eeeeeeeeeeee";
const std::string kCylinderOp = "10000000-0000-4000-8000-000000000001";
const std::string kSphereOp = "10000000-0000-4000-8000-000000000002";
const std::string kConeOp = "10000000-0000-4000-8000-000000000003";
const std::string kTorusOp = "10000000-0000-4000-8000-000000000004";
const std::string kWedgeOp = "10000000-0000-4000-8000-000000000005";
const std::string kExtrudeProfileOp = "20000000-0000-4000-8000-000000000001";
const std::string kExtrudeOp = "20000000-0000-4000-8000-000000000002";
const std::string kRevolveProfileOp = "30000000-0000-4000-8000-000000000001";
const std::string kRevolveOp = "30000000-0000-4000-8000-000000000002";
const std::string kLoftProfileStartOp = "40000000-0000-4000-8000-000000000001";
const std::string kLoftProfileEndOp = "40000000-0000-4000-8000-000000000002";
const std::string kLoftOp = "40000000-0000-4000-8000-000000000003";
const std::string kSweepProfileOp = "50000000-0000-4000-8000-000000000001";
const std::string kSweepOp = "50000000-0000-4000-8000-000000000002";

nlohmann::json Placement(const nlohmann::json& origin = {0.0, 0.0, 0.0},
                         const nlohmann::json& zDirection = {0.0, 0.0, 1.0},
                         const nlohmann::json& xDirection = {1.0, 0.0, 0.0}) {
  return {{"origin", origin}, {"zDirection", zDirection}, {"xDirection", xDirection}};
}

nlohmann::json BodyBirth(const std::string& id, const std::string& type,
                         nlohmann::json parameters) {
  return {
      {"id", id},
      {"type", type},
      {"outputBodyId", "90000000-0000-4000-8000-000000000001"},
      {"parameters", std::move(parameters)},
  };
}

nlohmann::json ProfileBirth(const std::string& id, nlohmann::json shape,
                            const nlohmann::json& origin,
                            const nlohmann::json& zDirection = {0.0, 0.0, 1.0},
                            const nlohmann::json& xDirection = {1.0, 0.0, 0.0}) {
  return {
      {"id", id},
      {"type", "create_profile"},
      {"outputProfileId", "91000000-0000-4000-8000-000000000001"},
      {"parameters",
       {{"shape", std::move(shape)}, {"placement", Placement(origin, zDirection, xDirection)}}},
  };
}

nlohmann::json CylinderProgram() {
  return nlohmann::json::array(
      {BodyBirth(kCylinderOp, "create_cylinder",
                 {{"radius", 7.0},
                  {"height", 23.0},
                  {"placement", Placement({3.0, -4.0, 5.0}, {0.0, 1.0, 0.0})}})});
}

nlohmann::json SphereProgram() {
  return nlohmann::json::array(
      {BodyBirth(kSphereOp, "create_sphere",
                 {{"radius", 11.0}, {"placement", Placement({3.0, -4.0, 5.0}, {0.0, 1.0, 0.0})}})});
}

nlohmann::json ConeProgram() {
  return nlohmann::json::array(
      {BodyBirth(kConeOp, "create_cone",
                 {{"radiusBottom", 9.0},
                  {"radiusTop", 0.0},
                  {"height", 19.0},
                  {"placement", Placement({3.0, -4.0, 5.0}, {0.0, 1.0, 0.0})}})});
}

nlohmann::json TorusProgram() {
  return nlohmann::json::array(
      {BodyBirth(kTorusOp, "create_torus",
                 {{"majorRadius", 20.0},
                  {"minorRadius", 4.0},
                  {"placement", Placement({3.0, -4.0, 5.0}, {0.0, 1.0, 0.0})}})});
}

nlohmann::json WedgeProgram() {
  return nlohmann::json::array(
      {BodyBirth(kWedgeOp, "create_wedge",
                 {{"width", 32.0},
                  {"depth", 17.0},
                  {"height", 13.0},
                  {"topWidth", 0.0},
                  {"placement", Placement({3.0, -4.0, 5.0}, {0.0, 1.0, 0.0})}})});
}

nlohmann::json ExtrudeProgram() {
  return nlohmann::json::array(
      {ProfileBirth(
           kExtrudeProfileOp,
           {{"kind", "roundedRectangle"}, {"width", 18.0}, {"depth", 12.0}, {"cornerRadius", 2.0}},
           {2.0, 3.0, 4.0}, {0.0, 1.0, 0.0}),
       BodyBirth(kExtrudeOp, "extrude",
                 {{"profileOperationId", kExtrudeProfileOp},
                  {"distance", 21.0},
                  {"direction", "normal"}})});
}

nlohmann::json RevolveProgram() {
  return nlohmann::json::array(
      {ProfileBirth(kRevolveProfileOp, {{"kind", "rectangle"}, {"width", 20.0}, {"depth", 10.0}},
                    {0.0, 0.0, 0.0}),
       BodyBirth(kRevolveOp, "revolve",
                 {{"profileOperationId", kRevolveProfileOp},
                  {"axisOrigin", {30.0, 0.0, 0.0}},
                  {"axisDirection", {0.0, 1.0, 0.0}},
                  {"angleDegrees", 180.0}})});
}

nlohmann::json LoftProgram() {
  return nlohmann::json::array(
      {ProfileBirth(kLoftProfileStartOp, {{"kind", "rectangle"}, {"width", 18.0}, {"depth", 12.0}},
                    {0.0, 0.0, 0.0}),
       ProfileBirth(kLoftProfileEndOp, {{"kind", "rectangle"}, {"width", 10.0}, {"depth", 7.0}},
                    {3.0, 2.0, 24.0}),
       BodyBirth(
           kLoftOp, "loft",
           {{"profileOperationIds", {kLoftProfileStartOp, kLoftProfileEndOp}}, {"ruled", false}})});
}

nlohmann::json SweepProgram() {
  return nlohmann::json::array(
      {ProfileBirth(kSweepProfileOp, {{"kind", "rectangle"}, {"width", 4.0}, {"depth", 3.0}},
                    {0.0, 0.0, 0.0}),
       BodyBirth(kSweepOp, "sweep",
                 {{"profileOperationId", kSweepProfileOp},
                  {"path", {{0.0, 0.0, 0.0}, {0.0, 0.0, 20.0}, {12.0, 0.0, 32.0}}}})});
}

nlohmann::json TiltedSweepProgram() {
  constexpr double kSinFiveDegrees = 0.08715574274765817;
  constexpr double kCosFiveDegrees = 0.9961946980917455;
  return nlohmann::json::array(
      {ProfileBirth(kSweepProfileOp, {{"kind", "rectangle"}, {"width", 4.0}, {"depth", 3.0}},
                    {0.0, 0.0, 0.0}, {kSinFiveDegrees, 0.0, kCosFiveDegrees},
                    {kCosFiveDegrees, 0.0, -kSinFiveDegrees}),
       BodyBirth(kSweepOp, "sweep",
                 {{"profileOperationId", kSweepProfileOp},
                  {"path", {{0.0, 0.0, 0.0}, {0.0, 0.0, 20.0}, {12.0, 0.0, 32.0}}}})});
}

nlohmann::json RotatedBoxProgram() {
  return nlohmann::json::array(
      {BodyBirth(kBoxOp, "create_box",
                 {{"width", 40.0},
                  {"depth", 30.0},
                  {"height", 20.0},
                  {"placement", Placement({3.0, -4.0, 5.0}, {0.0, 1.0, 0.0})}})});
}

nlohmann::json BoxOperation(const std::string& id, const double width, const double depth,
                            const double height, const std::array<double, 3>& origin) {
  return {
      {"id", id},
      {"type", "create_box"},
      {"outputBodyId", "00000000-0000-4000-8000-00000000000b"},
      {"parameters",
       {{"width", width},
        {"depth", depth},
        {"height", height},
        {"placement",
         {{"origin", {origin[0], origin[1], origin[2]}},
          {"zDirection", {0.0, 0.0, 1.0}},
          {"xDirection", {1.0, 0.0, 0.0}}}}}},
  };
}

// 40 (x) x 30 (y) x 20 (z) box at the origin: top/bottom area 1200, the two
// x-normal sides 30x20=600, the two y-normal sides 40x20=800.
nlohmann::json BoxProgram() {
  return nlohmann::json::array({BoxOperation(kBoxOp, 40, 30, 20, {0, 0, 0})});
}

nlohmann::json BoxHoleProgram(const double radius) {
  return nlohmann::json::array({
      BoxOperation(kBoxOp, 80, 50, 15, {0, 0, 0}),
      {
          {"id", kHoleOp},
          {"type", "hole"},
          {"outputBodyId", "00000000-0000-4000-8000-00000000000c"},
          {"parameters",
           {{"targetOperationId", kBoxOp},
            {"placement",
             {{"origin", {15.0, 0.0, 15.0}},
              {"zDirection", {0.0, 0.0, -1.0}},
              {"xDirection", {1.0, 0.0, 0.0}}}},
            {"size", {{"kind", "radius"}, {"radius", radius}}},
            {"depth", 10.0},
            {"throughAll", false}}},
      },
  });
}

nlohmann::json FilletProgram() {
  return nlohmann::json::array({
      BoxOperation(kBoxOp, 40, 30, 20, {0, 0, 0}),
      {
          {"id", kFilletOp},
          {"type", "fillet"},
          {"outputBodyId", "00000000-0000-4000-8000-00000000000e"},
          {"parameters", {{"targetOperationId", kBoxOp}, {"radius", 3.0}}},
      },
  });
}

// True when `dir` (a 3-element JSON array) has its first component whose
// absolute value exceeds 1e-9 positive -- the Canonicalize() convention
// (geometry_measures.cpp) an undirected axis/dir must follow.
bool IsCanonicalAxisDirection(const nlohmann::json& dir) {
  for (const nlohmann::json& component : dir) {
    const double value = component.get<double>();
    if (std::abs(value) > 1e-9)
      return value > 0.0;
  }
  return true;
}

// --- AST builders (the wire form the parser emits; §3 mirror) --------------

nlohmann::json ArgNumber(const double value) { return {{"arg", "number"}, {"value", value}}; }
nlohmann::json ArgIdent(const std::string& value) { return {{"arg", "ident"}, {"value", value}}; }
nlohmann::json ArgAxis(const std::string& value) { return {{"arg", "axis"}, {"value", value}}; }
nlohmann::json ArgDirAxis(const int sign, const std::string& axis) {
  return {{"arg", "direction"}, {"value", {{"form", "axis"}, {"sign", sign}, {"axis", axis}}}};
}
nlohmann::json ArgPoint(const double x, const double y, const double z) {
  return {{"arg", "point"}, {"value", {x, y, z}}};
}
nlohmann::json ArgQuery(const nlohmann::json& query) {
  return {{"arg", "query"}, {"value", query}};
}

// nlohmann interprets a single-element brace list of an object as that object,
// not a one-element array, so scope/args/filters are built by pushing into an
// explicit array — this keeps `{SrcOp(id)}` a scope of one source, never the
// source object itself.
nlohmann::json AsArray(std::initializer_list<nlohmann::json> items) {
  nlohmann::json array = nlohmann::json::array();
  for (const nlohmann::json& item : items)
    array.push_back(item);
  return array;
}

nlohmann::json Filter(const std::string& name, std::initializer_list<nlohmann::json> args = {}) {
  return {{"name", name}, {"args", AsArray(args)}};
}
nlohmann::json SrcOp(const std::string& id) { return {{"source", "op"}, {"opId", id}}; }
nlohmann::json SrcBody(const std::string& id) { return {{"source", "body"}, {"opId", id}}; }
nlohmann::json SrcToken(const std::string& t) { return {{"source", "token"}, {"token", t}}; }

nlohmann::json Query(const std::string& kind, std::initializer_list<nlohmann::json> scope,
                     std::initializer_list<nlohmann::json> filters = {}) {
  return {{"kind", kind}, {"scope", AsArray(scope)}, {"filters", AsArray(filters)}};
}

aeth::QueryOutcome Run(const nlohmann::json& program, const nlohmann::json& ast) {
  aeth::NamingRegistry registry;
  std::atomic_bool cancelled{false};
  const std::vector<aeth::EvaluatedBody> bodies =
      aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
  return aeth::EvaluateQuery(ast, bodies, registry, cancelled);
}

std::size_t Count(const nlohmann::json& program, const nlohmann::json& ast) {
  return Run(program, ast).entities.size();
}

bool ThrowsUnsupported(const nlohmann::json& program, const nlohmann::json& ast) {
  try {
    Run(program, ast);
    return false;
  } catch (const std::invalid_argument& error) {
    return std::string(error.what()).starts_with("unsupported operation");
  } catch (...) {
    return false;
  }
}

// --- Tests -----------------------------------------------------------------

void ScopeAndPipeline() {
  std::printf("scope expansion and the refinement pipeline:\n");
  const nlohmann::json box = BoxProgram();
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)})), 6, "faces(op(box)) -> 6 faces");
  checkEqual(Count(box, Query("edges", {SrcOp(kBoxOp)})), 12, "edges(op(box)) -> 12 edges");
  checkEqual(Count(box, Query("vertices", {SrcOp(kBoxOp)})), 8, "vertices(op(box)) -> 8 vertices");
  checkEqual(Count(box, Query("faces", {SrcBody(kBoxOp)})), 6, "faces(body(box)) -> 6 faces");

  // Stage cardinalities: |S0| plus one per filter (§8.1).
  const aeth::QueryOutcome staged =
      Run(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("planar"), Filter("max", {ArgAxis("z")})}));
  checkEqual(staged.stageCardinalities.size(), 3, "three stages recorded (S0 + 2 filters)");
  check(staged.stageCardinalities.size() == 3 && staged.stageCardinalities[0] == 6 &&
            staged.stageCardinalities[1] == 6 && staged.stageCardinalities[2] == 1,
        "stage cardinalities are 6 -> 6 -> 1");
}

void RoleAndCreation() {
  std::printf("role and creation filters:\n");
  const nlohmann::json box = BoxProgram();
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})})), 1,
             "faces(op(box)).role(top) -> 1");
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("bottom")})})), 1,
             "faces(op(box)).role(bottom) -> 1");
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("side")})})), 4,
             "faces(op(box)).role(side) -> 4");
  checkEqual(
      Count(box, Query("edges", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("bottom-edge")})})), 4,
      "edges(op(box)).role(bottom-edge) -> 4");
  checkEqual(Count(box, Query("edges", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top-edge")})})),
             4, "edges(op(box)).role(top-edge) -> 4");
  checkEqual(
      Count(box, Query("edges", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("vertical-edge")})})), 4,
      "edges(op(box)).role(vertical-edge) -> 4");
  checkEqual(Count(box, Query("vertices", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("vertex")})})),
             8, "vertices(op(box)).role(vertex) -> 8");
  // A fresh box birth is entirely generated, nothing modified.
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("created")})), 6,
             "faces(op(box)).created() -> 6");
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("modified")})), 0,
             "faces(op(box)).modified() -> 0 on a fresh birth");
}

void GeometricClass() {
  std::printf("geometric-class filters:\n");
  const nlohmann::json box = BoxProgram();
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("planar")})), 6,
             "faces(op(box)).planar() -> 6");
  checkEqual(Count(box, Query("edges", {SrcOp(kBoxOp)}, {Filter("line")})), 12,
             "edges(op(box)).line() -> 12");

  const nlohmann::json hole = BoxHoleProgram(4);
  // The blind hole's wall role holds the curved bore wall plus the flat floor;
  // cylindrical() keeps only the bore wall.
  const std::size_t cylWalls =
      Count(hole, Query("faces", {SrcOp(kHoleOp)}, {Filter("cylindrical")}));
  check(cylWalls >= 1, "faces(op(hole)).cylindrical() finds the bore wall");
  check(Count(hole, Query("edges", {SrcOp(kHoleOp)}, {Filter("circle")})) >= 1,
        "edges(op(hole)).circle() finds at least one circular edge");
}

void Directional() {
  std::printf("directional filters:\n");
  const nlohmann::json box = BoxProgram();
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("normal", {ArgDirAxis(1, "z")})})),
             1, "faces(op(box)).normal(+z) -> 1 (top)");
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("normal", {ArgDirAxis(-1, "z")})})),
             1, "faces(op(box)).normal(-z) -> 1 (bottom)");
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("normal", {ArgDirAxis(1, "x")})})),
             1, "faces(op(box)).normal(+x) -> 1 side");
  checkEqual(
      Count(box, Query("edges", {SrcOp(kBoxOp)}, {Filter("parallel", {ArgDirAxis(1, "z")})})), 4,
      "edges(op(box)).parallel(+z) -> 4 vertical edges");
  // Perpendicular to +z keeps the 8 edges lying in the top/bottom planes.
  checkEqual(
      Count(box, Query("edges", {SrcOp(kBoxOp)}, {Filter("perpendicular", {ArgDirAxis(1, "z")})})),
      8, "edges(op(box)).perpendicular(+z) -> 8 horizontal edges");
}

void Positional() {
  std::printf("positional filters:\n");
  const nlohmann::json box = BoxProgram();
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("max", {ArgAxis("z")})})), 1,
             "faces(op(box)).max(z) -> 1 (top)");
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("min", {ArgAxis("z")})})), 1,
             "faces(op(box)).min(z) -> 1 (bottom)");
  // A single corner: the min along each of the three axes in turn.
  checkEqual(Count(box, Query("vertices", {SrcOp(kBoxOp)},
                              {Filter("min", {ArgAxis("x")}), Filter("min", {ArgAxis("y")}),
                               Filter("min", {ArgAxis("z")})})),
             1, "vertices(op(box)).min(x).min(y).min(z) -> 1 corner");
  // create_box places the box CENTERED on its placement origin in x/y and
  // resting on it in z, so a 40x30x20 box at the origin spans x[-20,20],
  // y[-15,15], z[0,20]; the top face centre is [0,0,20].
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("at", {ArgPoint(0, 0, 20)})})), 1,
             "faces(op(box)).at([0,0,20]) -> 1 (top centre)");
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)},
                              {Filter("within", {ArgPoint(-21, -16, -1), ArgPoint(21, 16, 21)})})),
             6, "faces(op(box)).within(box+eps) -> all 6");
  // onGround: the bottom face lies in z=0 with a -z outward normal.
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("onGround")})), 1,
             "faces(op(box)).onGround() -> 1 (bottom)");
}

void SizeAndMeasure() {
  std::printf("size and measure filters:\n");
  const nlohmann::json box = BoxProgram();
  // Two faces share the largest area (1200); largest(2) keeps both.
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("largest", {ArgNumber(2)})})), 2,
             "faces(op(box)).largest(2) -> 2 (top+bottom, area 1200)");
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("largest")})), 1,
             "faces(op(box)).largest() -> 1");
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)},
                              {Filter("area", {ArgNumber(1000), ArgNumber(-1)})})),
             2, "faces(op(box)).area(1000,-1) -> 2 (the 1200 faces)");
  checkEqual(Count(box, Query("edges", {SrcOp(kBoxOp)},
                              {Filter("parallel", {ArgDirAxis(1, "z")}),
                               Filter("length", {ArgNumber(19), ArgNumber(21)})})),
             4, "the four vertical edges have length ~20");

  const nlohmann::json hole = BoxHoleProgram(4);
  check(Count(hole, Query("faces", {SrcOp(kHoleOp)},
                          {Filter("cylindrical"), Filter("radius", {ArgNumber(4)})})) >= 1,
        "faces(op(hole)).cylindrical().radius(4) finds the r=4 bore wall");
}

void Topological() {
  std::printf("topological filters (dihedral classification):\n");
  const nlohmann::json box = BoxProgram();
  const std::size_t convex = Count(box, Query("edges", {SrcOp(kBoxOp)}, {Filter("convex")}));
  const std::size_t concave = Count(box, Query("edges", {SrcOp(kBoxOp)}, {Filter("concave")}));
  const std::size_t smooth = Count(box, Query("edges", {SrcOp(kBoxOp)}, {Filter("smooth")}));
  checkEqual(convex, 12, "edges(op(box)).convex() -> 12 (external corners)");
  checkEqual(concave, 0, "edges(op(box)).concave() -> 0 on a convex box");
  checkEqual(smooth, 0, "edges(op(box)).smooth() -> 0 on a box");

  // The blind hole cuts internal concave edges (wall meeting floor / opening).
  const nlohmann::json hole = BoxHoleProgram(4);
  check(Count(hole, Query("edges", {SrcOp(kHoleOp)}, {Filter("concave")})) >= 1,
        "faces(op(hole)) introduces at least one concave edge");

  // adjacentTo / on / boundaryOf over the box top face.
  const nlohmann::json topFace =
      Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})});
  checkEqual(
      Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("adjacentTo", {ArgQuery(topFace)})})), 4,
      "faces adjacent to the top -> 4 sides");
  checkEqual(Count(box, Query("edges", {SrcOp(kBoxOp)}, {Filter("on", {ArgQuery(topFace)})})), 4,
             "edges on the top face -> its 4 loop edges");
  checkEqual(
      Count(box, Query("edges", {SrcOp(kBoxOp)}, {Filter("boundaryOf", {ArgQuery(topFace)})})), 4,
      "boundaryOf(top) -> 4 edges");
}

void SetAndOrder() {
  std::printf("set and order filters + canonical determinism:\n");
  const nlohmann::json box = BoxProgram();
  const nlohmann::json bottom =
      Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("bottom")})});
  checkEqual(
      Count(box, Query("faces", {SrcOp(kBoxOp)},
                       {Filter("role", {ArgIdent("top")}), Filter("union", {ArgQuery(bottom)})})),
      2, "role(top).union(role(bottom)) -> 2");
  const nlohmann::json sides =
      Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("side")})});
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("not", {ArgQuery(sides)})})), 2,
             "faces(op(box)).not(role(side)) -> 2 (top+bottom)");
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("first", {ArgNumber(3)})})), 3,
             "faces(op(box)).first(3) -> 3");
  checkEqual(Count(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("nth", {ArgNumber(0)})})), 1,
             "faces(op(box)).nth(0) -> 1");

  // Canonical order is byte-stable across independent evaluations (§6.4).
  const nlohmann::json ast = Query("edges", {SrcOp(kBoxOp)});
  const aeth::QueryOutcome first = Run(box, ast);
  const aeth::QueryOutcome second = Run(box, ast);
  bool sameOrder = first.entities.size() == second.entities.size();
  for (std::size_t i = 0; sameOrder && i < first.entities.size(); ++i)
    sameOrder = first.entities[i].token == second.entities[i].token;
  check(sameOrder, "edge ordering is byte-identical across two evaluations");
}

void TokenSourceAndJson() {
  std::printf("token source and the ResolvedEntity projection:\n");
  const nlohmann::json box = BoxProgram();
  const aeth::QueryOutcome top =
      Run(box, Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})}));
  check(top.entities.size() == 1, "resolved exactly one top face");
  if (top.entities.size() == 1) {
    const std::string token = top.entities.front().token;
    // Re-select the same face by its exact token.
    checkEqual(Count(box, Query("faces", {SrcToken(token)})), 1, "token(<top>) re-selects 1 face");
    const nlohmann::json json = aeth::ResolvedEntityToJson(top.entities.front());
    check(json.at("kind") == "face", "projection: kind is face");
    check(json.at("surface") == "plane", "projection: top face surface is plane");
    check(json.contains("normal"), "projection: planar face carries a normal");
    check(json.at("centroid").is_array() && json.at("centroid").size() == 3,
          "projection: centroid is a 3-tuple");
  }
  // An unknown token resolves to the empty set, never a crash or a guess.
  checkEqual(Count(box, Query("faces", {SrcToken("t:" + kBoxOp + "/top/99")})), 0,
             "token(<unknown>) -> 0");

  // A cylinder wall projects its surface class, radius, and axis.
  const nlohmann::json hole = BoxHoleProgram(4);
  const aeth::QueryOutcome walls =
      Run(hole, Query("faces", {SrcOp(kHoleOp)}, {Filter("cylindrical")}));
  if (!walls.entities.empty()) {
    const nlohmann::json json = aeth::ResolvedEntityToJson(walls.entities.front());
    check(json.at("surface") == "cylinder", "projection: bore wall surface is cylinder");
    check(json.contains("radius"), "projection: cylinder wall carries a radius");
    check(json.contains("axis"), "projection: cylinder wall carries an axis");
    // This axis feeds the desktop selection recorder's matchesEvidence, which
    // compares it against the evaluate_document topology harvest's axis
    // (geometry_measures.cpp Canonicalize) byte-for-byte. Both MUST agree on
    // the sign convention: the raw OCCT direction is never guaranteed to have
    // its dominant component positive, so this pins that ResolvedEntityToJson
    // canonicalizes (via SurfaceAxis/CurveAxis) rather than emitting the raw
    // surface.Cylinder().Axis().Direction(), which regressed silently once
    // before (no test caught a raw-vs-canonical cross-path sign mismatch).
    if (json.contains("axis")) {
      check(IsCanonicalAxisDirection(json.at("axis").at("dir")),
            "projection: cylinder wall axis direction is sign-canonicalized");
    }
  }

  // A straight box edge is a LINE; before the cross-path axis fix, the query
  // projection never emitted an axis for GeomAbs_Line (or GeomAbs_Ellipse) at
  // all, unconditionally failing the desktop recorder's evidence match for
  // every straight or elliptical edge. Any one box edge exercises this.
  const aeth::QueryOutcome boxEdges = Run(box, Query("edges", {SrcOp(kBoxOp)}));
  check(!boxEdges.entities.empty(), "box has edges to project");
  if (!boxEdges.entities.empty()) {
    const nlohmann::json json = aeth::ResolvedEntityToJson(boxEdges.entities.front());
    check(json.at("curve") == "line", "projection: box edge curve is line");
    check(json.contains("axis"), "projection: straight box edge now carries an axis");
    if (json.contains("axis")) {
      check(IsCanonicalAxisDirection(json.at("axis").at("dir")),
            "projection: box edge axis direction is sign-canonicalized");
    }
  }
}

void FailsClosed() {
  std::printf("deferred surfaces fail closed:\n");
  const nlohmann::json box = BoxProgram();
  check(ThrowsUnsupported(box, Query("bodies", {SrcOp(kBoxOp)})),
        "bodies(...) head kind is UNSUPPORTED_OPERATION");
  check(ThrowsUnsupported(box, Query("regions", {{{"source", "sketch"}, {"opId", kBoxOp}}})),
        "regions(sketch(...)) is UNSUPPORTED_OPERATION");
  check(ThrowsUnsupported(box, Query("faces", {{{"source", "tag"}, {"tag", "gridfinity"}}})),
        "faces(tag(...)) source is UNSUPPORTED_OPERATION");
  check(ThrowsUnsupported(box, Query("faces", {{{"source", "world"}, {"world", "xy"}}})),
        "faces(world(...)) source is UNSUPPORTED_OPERATION");
}

void FilletSmoke() {
  std::printf("fillet program: modified faces and blend edges resolve:\n");
  const nlohmann::json fillet = FilletProgram();
  // The six box faces are re-trimmed (Modified) through the fillet.
  checkEqual(Count(fillet, Query("faces", {SrcOp(kFilletOp)}, {Filter("modified")})), 6,
             "faces(op(fillet)).modified() -> 6 re-trimmed box faces");
  // Cylindrical blend faces exist along the filleted edges.
  check(Count(fillet, Query("faces", {SrcOp(kFilletOp)}, {Filter("cylindrical")})) >= 1,
        "fillet introduces cylindrical blend faces");
}

struct RoleExpectation final {
  std::string kind;
  std::string role;
  std::size_t count{};
};

struct BirthQueryCase final {
  std::string label;
  std::string operationId;
  nlohmann::json program;
  std::vector<RoleExpectation> roles;
};

void MutateBirthProgram(nlohmann::json& program) {
  for (nlohmann::json& operation : program) {
    const std::string id = operation.at("id").get<std::string>();
    nlohmann::json& parameters = operation.at("parameters");
    if (id == kBoxOp) {
      parameters["width"] = 44.0;
      parameters["depth"] = 34.0;
      parameters["height"] = 22.0;
    } else if (id == kCylinderOp) {
      parameters["radius"] = 8.5;
      parameters["height"] = 29.0;
    } else if (id == kSphereOp) {
      parameters["radius"] = 14.0;
    } else if (id == kConeOp) {
      parameters["radiusBottom"] = 12.0;
      parameters["height"] = 25.0;
    } else if (id == kTorusOp) {
      parameters["majorRadius"] = 24.0;
      parameters["minorRadius"] = 5.0;
    } else if (id == kWedgeOp) {
      parameters["width"] = 38.0;
      parameters["depth"] = 21.0;
      parameters["height"] = 16.0;
    } else if (id == kExtrudeOp) {
      parameters["distance"] = 27.0;
    } else if (id == kRevolveOp) {
      parameters["axisOrigin"] = {35.0, 0.0, 0.0};
    } else if (id == kLoftProfileEndOp) {
      parameters["shape"]["width"] = 12.0;
      parameters["shape"]["depth"] = 8.0;
      parameters["placement"]["origin"] = {4.0, 1.0, 28.0};
    } else if (id == kSweepOp) {
      parameters["path"] = {{0.0, 0.0, 0.0}, {0.0, 0.0, 24.0}, {15.0, 0.0, 38.0}};
    }
  }
}

void BodyBirthRegistryAndQueryMatrix() {
  std::printf("all body births: registry totality, semantic roles, and hostile queries:\n");
  const std::vector<BirthQueryCase> cases{
      {"rotated box",
       kBoxOp,
       RotatedBoxProgram(),
       {{"faces", "bottom", 1},
        {"faces", "top", 1},
        {"faces", "side", 4},
        {"edges", "bottom-edge", 4},
        {"edges", "top-edge", 4},
        {"edges", "vertical-edge", 4},
        {"vertices", "vertex", 8}}},
      {"rotated cylinder",
       kCylinderOp,
       CylinderProgram(),
       {{"faces", "bottom", 1},
        {"faces", "top", 1},
        {"faces", "wall", 1},
        {"edges", "seam", 1},
        {"edges", "bottom-edge", 1},
        {"edges", "top-edge", 1}}},
      {"rotated sphere",
       kSphereOp,
       SphereProgram(),
       {{"faces", "wall", 1}, {"edges", "seam", 1}, {"edges", "pole-edge", 2}}},
      {"rotated pointed cone",
       kConeOp,
       ConeProgram(),
       {{"faces", "bottom", 1},
        {"faces", "top", 0},
        {"faces", "wall", 1},
        {"vertices", "apex-vertex", 1}}},
      {"rotated torus", kTorusOp, TorusProgram(), {{"faces", "wall", 1}, {"edges", "seam", 2}}},
      {"rotated knife-edge wedge",
       kWedgeOp,
       WedgeProgram(),
       {{"faces", "bottom", 1}, {"faces", "top", 0}, {"edges", "top-edge", 3}}},
      {"rotated rounded-rectangle extrude",
       kExtrudeOp,
       ExtrudeProgram(),
       {{"faces", "cap-start", 1}, {"faces", "cap-end", 1}, {"edges", "side-edge", 24}}},
      {"180-degree partial revolve",
       kRevolveOp,
       RevolveProgram(),
       {{"faces", "cap-start", 1}, {"faces", "cap-end", 1}}},
      {"offset non-ruled loft",
       kLoftOp,
       LoftProgram(),
       {{"faces", "cap-start", 1}, {"faces", "cap-end", 1}}},
      {"mitered polyline sweep",
       kSweepOp,
       SweepProgram(),
       {{"faces", "cap-start", 1}, {"faces", "cap-end", 1}}},
      {"tilted profile corrected onto straight sweep",
       kSweepOp,
       TiltedSweepProgram(),
       {{"faces", "cap-start", 1}, {"faces", "cap-end", 1}}},
  };

  for (const BirthQueryCase& testCase : cases) {
    aeth::NamingRegistry registry;
    std::atomic_bool cancelled{false};
    const std::vector<aeth::EvaluatedBody> bodies =
        aeth::EvaluateOperations(testCase.program, cancelled, nullptr, &registry);
    checkEqual(bodies.size(), 1, testCase.label + ": produces one visible body");
    if (bodies.size() != 1)
      continue;

    const aeth::EvaluatedBody& body = bodies.front();
    const std::array<std::pair<std::string, std::size_t>, 3> kinds{
        std::pair{"faces", static_cast<std::size_t>(body.probes.faceCount)},
        std::pair{"edges", static_cast<std::size_t>(body.probes.edgeCount)},
        std::pair{"vertices", static_cast<std::size_t>(body.probes.vertexCount)},
    };
    std::size_t topologyCount = 0;
    bool everyProjectionFinite = true;
    bool everyTokenReselectsExactly = true;
    std::vector<std::vector<std::string>> firstReplayTokens;
    for (const auto& [kind, expectedCount] : kinds) {
      const aeth::QueryOutcome outcome = aeth::EvaluateQuery(
          Query(kind, {SrcOp(testCase.operationId)}), bodies, registry, cancelled);
      checkEqual(outcome.entities.size(), expectedCount,
                 testCase.label + ": " + kind + " query covers the B-rep census");
      topologyCount += expectedCount;
      std::vector<std::string> tokens;
      for (const aeth::QueryEntity& entity : outcome.entities) {
        tokens.push_back(entity.token);
        const nlohmann::json projected = aeth::ResolvedEntityToJson(entity);
        const nlohmann::json& centroid = projected.at("centroid");
        if (!centroid.is_array() || centroid.size() != 3)
          everyProjectionFinite = false;
        for (const nlohmann::json& coordinate : centroid) {
          if (!coordinate.is_number() || !std::isfinite(coordinate.get<double>()))
            everyProjectionFinite = false;
        }
        const aeth::QueryOutcome reselected =
            aeth::EvaluateQuery(Query(kind, {SrcToken(entity.token)}), bodies, registry, cancelled);
        if (reselected.entities.size() != 1 ||
            !reselected.entities.front().shape.IsSame(entity.shape)) {
          everyTokenReselectsExactly = false;
        }
      }
      firstReplayTokens.push_back(std::move(tokens));
    }
    check(everyProjectionFinite,
          testCase.label + ": every entity projects finite geometry (including zero-length edges)");
    check(everyTokenReselectsExactly,
          testCase.label + ": every minted token re-selects exactly its own entity");
    checkEqual(registry.RecordCount(), topologyCount,
               testCase.label + ": registry has exactly one birth record per B-rep entity");

    bool allLiveAndSemantic = true;
    for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
      const aeth::NamingRecord& record = registry.RecordAt(index);
      if (!record.live || record.minter != testCase.operationId || record.role == "generated" ||
          record.nameCollision || record.orderTie) {
        allLiveAndSemantic = false;
      }
    }
    check(allLiveAndSemantic,
          testCase.label + ": all records are live, semantic, and free of hidden ordering ties");

    for (const RoleExpectation& expectation : testCase.roles) {
      const std::size_t actual =
          aeth::EvaluateQuery(Query(expectation.kind, {SrcOp(testCase.operationId)},
                                    {Filter("role", {ArgIdent(expectation.role)})}),
                              bodies, registry, cancelled)
              .entities.size();
      checkEqual(actual, expectation.count,
                 testCase.label + ": role(" + expectation.role + ") cardinality");
    }
    for (const auto& [kind, unused] : kinds) {
      (void)unused;
      checkEqual(aeth::EvaluateQuery(Query(kind, {SrcOp(testCase.operationId)},
                                           {Filter("role", {ArgIdent("generated")})}),
                                     bodies, registry, cancelled)
                     .entities.size(),
                 0, testCase.label + ": no reserved generated-role fallback for " + kind);
    }

    aeth::NamingRegistry secondRegistry;
    const std::vector<aeth::EvaluatedBody> secondBodies =
        aeth::EvaluateOperations(testCase.program, cancelled, nullptr, &secondRegistry);
    bool replayOrderStable = secondBodies.size() == 1;
    for (std::size_t kindIndex = 0; replayOrderStable && kindIndex < kinds.size(); ++kindIndex) {
      const aeth::QueryOutcome second =
          aeth::EvaluateQuery(Query(kinds[kindIndex].first, {SrcOp(testCase.operationId)}),
                              secondBodies, secondRegistry, cancelled);
      if (second.entities.size() != firstReplayTokens[kindIndex].size()) {
        replayOrderStable = false;
        break;
      }
      for (std::size_t entityIndex = 0; entityIndex < second.entities.size(); ++entityIndex) {
        if (second.entities[entityIndex].token != firstReplayTokens[kindIndex][entityIndex]) {
          replayOrderStable = false;
          break;
        }
      }
    }
    check(replayOrderStable,
          testCase.label + ": independent replay preserves every query token and order");

    nlohmann::json mutatedProgram = testCase.program;
    MutateBirthProgram(mutatedProgram);
    aeth::NamingRegistry mutatedRegistry;
    const std::vector<aeth::EvaluatedBody> mutatedBodies =
        aeth::EvaluateOperations(mutatedProgram, cancelled, nullptr, &mutatedRegistry);
    bool mutationStable = mutatedBodies.size() == 1;
    for (std::size_t kindIndex = 0; mutationStable && kindIndex < kinds.size(); ++kindIndex) {
      const aeth::QueryOutcome mutated =
          aeth::EvaluateQuery(Query(kinds[kindIndex].first, {SrcOp(testCase.operationId)}),
                              mutatedBodies, mutatedRegistry, cancelled);
      if (mutated.entities.size() != firstReplayTokens[kindIndex].size()) {
        mutationStable = false;
        break;
      }
      for (std::size_t entityIndex = 0; entityIndex < mutated.entities.size(); ++entityIndex) {
        if (mutated.entities[entityIndex].token != firstReplayTokens[kindIndex][entityIndex]) {
          mutationStable = false;
          break;
        }
      }
    }
    for (const RoleExpectation& expectation : testCase.roles) {
      if (!mutationStable)
        break;
      mutationStable = aeth::EvaluateQuery(Query(expectation.kind, {SrcOp(testCase.operationId)},
                                                 {Filter("role", {ArgIdent(expectation.role)})}),
                                           mutatedBodies, mutatedRegistry, cancelled)
                           .entities.size() == expectation.count;
    }
    check(mutationStable,
          testCase.label + ": shape-preserving parameter edit keeps tokens and role semantics");
  }
}

void ConeEqualRadiiContract() {
  std::printf("equal-radius cone contract and taxonomy:\n");
  nlohmann::json program = ConeProgram();
  program.at(0).at("parameters")["radiusTop"] = 9.0;
  std::atomic_bool cancelled{false};
  try {
    (void)aeth::EvaluateOperations(program, cancelled);
    check(false, "equal-radius cone is rejected before OCCT");
  } catch (const aeth::OperationFailure& error) {
    check(error.OperationId() == kConeOp, "equal-radius cone failure is operation-attributed");
    check(error.Code() == "INVALID_REQUEST", "equal-radius cone uses INVALID_REQUEST");
    check(error.Details().value("primitiveCode", "") == "E_PRIM_CONE_EQUAL_RADII",
          "equal-radius cone carries E_PRIM_CONE_EQUAL_RADII");
    check(error.Details().contains("suggestedFix"), "equal-radius cone carries a repair payload");
  }
}

} // namespace

int main() {
  try {
    ScopeAndPipeline();
    RoleAndCreation();
    GeometricClass();
    Directional();
    Positional();
    SizeAndMeasure();
    Topological();
    SetAndOrder();
    TokenSourceAndJson();
    FailsClosed();
    FilletSmoke();
    BodyBirthRegistryAndQueryMatrix();
    ConeEqualRadiiContract();
  } catch (const std::exception& error) {
    std::printf("FATAL: uncaught exception: %s\n", error.what());
    return 1;
  }
  if (g_failures == 0) {
    std::printf("\nALL SELECTOR EVALUATOR TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d SELECTOR EVALUATOR CHECK(S) FAILED\n", g_failures);
  return 1;
}
