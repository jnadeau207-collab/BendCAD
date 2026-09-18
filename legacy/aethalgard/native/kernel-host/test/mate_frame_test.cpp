// Native integration tests for MateFrame extraction (ASM-005; plan 07 §5
// "Mate-reference resolution"; docs/context/assembly-program.json ASM-005:
// "kernel resolve_mate_frames, exact analytic frame extraction, mutation
// fixtures"). These drive the REAL EvaluateOperations path, registry-
// threaded exactly as server.cpp's Query() does, then the real
// aeth::ResolveMateFrame (mate_frame.hpp/.cpp) against real bodies/registry
// pairs. This file is BOTH the extraction-rule unit surface (every MateFrame
// geometry class plus the resolved/missing/ambiguous/invalidated taxonomy)
// and the ASM-005 mutation-fixtures deliverable: the qualified-edit
// tournament (resize / fillet / hole / pattern-count / import-replacement /
// operation-reorder).
//
// mate_frame.hpp/.cpp landed in this same delivery pass (a concurrent file in
// ASM-005's own ownedPaths, authored independently of this test). This file
// was written directly against that real header/implementation — the
// MateFrameGeometry enum, MateFrameResolution's std::array<double,3> fields,
// the exact CanonicalSecondary construction, and the exact refusal message
// text below are all read verbatim from mate_frame.cpp, not guessed. Not yet
// compiled or run in this turn (no OCCT toolchain invocation happened here) —
// mirrors ref_resolution_test.cpp's own COMPILE-UNVERIFIED precedent for this
// codebase. Two predictions in the qualified-edit tournament (B and C below)
// depend on naming_registry.cpp's Role tables rather than on mate_frame.cpp
// itself; both are read directly from naming_registry.cpp (RoleForModified /
// RoleForGenerated for OperationClass::Fillet and OperationClass::Hole) and
// are marked PREDICTION at their use site — reconcile those specifically if
// this suite's first real run disagrees.
#include <array>
#include <atomic>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <initializer_list>
#include <iterator>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepPrimAPI_MakeCylinder.hxx>
#include <Precision.hxx>
#include <TopoDS_Shape.hxx>
#include <TopoDS_Solid.hxx>
#include <nlohmann/json.hpp>

#include "geometry.hpp"
#include "mate_frame.hpp"
#include "naming_registry.hpp"
#include "sha256.hpp"

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
    std::printf("  FAIL %s (expected %.9f, got %.9f)\n", label.c_str(), expected, actual);
    g_failures += 1;
  }
}

void checkVec(const std::array<double, 3>& actual, const double x, const double y, const double z,
              const double tolerance, const std::string& label) {
  const bool near = std::abs(actual[0] - x) <= tolerance && std::abs(actual[1] - y) <= tolerance &&
                    std::abs(actual[2] - z) <= tolerance;
  if (near) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s (expected (%.9f, %.9f, %.9f), got (%.9f, %.9f, %.9f))\n", label.c_str(),
                x, y, z, actual[0], actual[1], actual[2]);
    g_failures += 1;
  }
}

void checkVecEqual(const std::array<double, 3>& a, const std::array<double, 3>& b,
                   const double tolerance, const std::string& label) {
  checkVec(a, b[0], b[1], b[2], tolerance, label);
}

std::string StatusName(const aeth::MateFrameStatus status) {
  switch (status) {
  case aeth::MateFrameStatus::Resolved:
    return "Resolved";
  case aeth::MateFrameStatus::Missing:
    return "Missing";
  case aeth::MateFrameStatus::Ambiguous:
    return "Ambiguous";
  case aeth::MateFrameStatus::Invalidated:
    return "Invalidated";
  }
  return "?";
}

void checkStatus(const aeth::MateFrameStatus actual, const aeth::MateFrameStatus expected,
                 const std::string& label) {
  if (actual == expected) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s (expected %s, got %s)\n", label.c_str(), StatusName(expected).c_str(),
                StatusName(actual).c_str());
    g_failures += 1;
  }
}

std::string GeometryName(const aeth::MateFrameGeometry geometry) {
  switch (geometry) {
  case aeth::MateFrameGeometry::Point:
    return "Point";
  case aeth::MateFrameGeometry::Axis:
    return "Axis";
  case aeth::MateFrameGeometry::Plane:
    return "Plane";
  case aeth::MateFrameGeometry::Cylinder:
    return "Cylinder";
  case aeth::MateFrameGeometry::Cone:
    return "Cone";
  case aeth::MateFrameGeometry::Sphere:
    return "Sphere";
  }
  return "?";
}

void checkGeometry(const aeth::MateFrameGeometry actual, const aeth::MateFrameGeometry expected,
                   const std::string& label) {
  if (actual == expected) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s (expected %s, got %s)\n", label.c_str(), GeometryName(expected).c_str(),
                GeometryName(actual).c_str());
    g_failures += 1;
  }
}

bool Contains(const std::string& haystack, const std::string& needle) {
  return haystack.find(needle) != std::string::npos;
}

// The repo's standard native geometric-identity tolerance (tolerance_budget_
// test.cpp: Precision::Confusion() == 1e-7 mm on the pinned OCCT — the same
// constant every other native gate's exact-analytic assertion is measured
// against). Used for every position/direction/radius assertion below.
const double kEps = Precision::Confusion();

constexpr double kPi = 3.14159265358979323846;

// --- Operation ids (reused across independent test functions — none of
// these programs share state, matching catalog_wave1_test.cpp's own
// convention) --------------------------------------------------------------

const std::string kBoxOp = "aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa";
const std::string kCylOp = "bbbbbbbb-2222-4b22-8b22-bbbbbbbbbbbb";
const std::string kConeOp = "cccccccc-3333-4c33-8c33-cccccccccccc";
const std::string kSphereOp = "dddddddd-4444-4d44-8d44-dddddddddddd";
const std::string kDatumPlaneOp = "eeeeeeee-5555-4e55-8e55-eeeeeeeeeeee";
const std::string kDatumAxisOp = "ffffffff-6666-4f66-8f66-ffffffffffff";
const std::string kSeedOp = "11111111-7777-4a77-8a77-111111111111";
const std::string kPatternOp = "22222222-8888-4b88-8b88-222222222222";
const std::string kHoleOp = "33333333-9999-4c99-8c99-333333333333";
const std::string kFilletOp = "44444444-aaaa-4daa-8daa-444444444444";
const std::string kImportOp = "55555555-bbbb-4ebb-8bbb-555555555555";
const std::string kBoxAOp = "66666666-cccc-4fcc-8ccc-666666666666";
const std::string kBoxBOp = "77777777-dddd-4add-8ddd-777777777777";

// --- Operation builders (mirrors the exact literal JSON shapes already used
// in catalog_wave1_test.cpp / catalog_wave2_test.cpp / hole_entry_test.cpp /
// ref_resolution_test.cpp / step_import_test.cpp) --------------------------

nlohmann::json BoxOperation(const std::string& id, const std::string& bodyId, const double width,
                            const double depth, const double height,
                            const std::array<double, 3>& origin = {0.0, 0.0, 0.0}) {
  return {
      {"id", id},
      {"type", "create_box"},
      {"outputBodyId", bodyId},
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

nlohmann::json CylinderOperation(const std::string& id, const std::string& bodyId,
                                 const double radius, const double height) {
  return {
      {"id", id},
      {"type", "create_cylinder"},
      {"outputBodyId", bodyId},
      {"parameters",
       {{"radius", radius},
        {"height", height},
        {"placement",
         {{"origin", {0.0, 0.0, 0.0}},
          {"zDirection", {0.0, 0.0, 1.0}},
          {"xDirection", {1.0, 0.0, 0.0}}}}}},
  };
}

nlohmann::json ConeOperation(const std::string& id, const std::string& bodyId,
                             const double radiusBottom, const double radiusTop,
                             const double height) {
  return {
      {"id", id},
      {"type", "create_cone"},
      {"outputBodyId", bodyId},
      {"parameters",
       {{"radiusBottom", radiusBottom},
        {"radiusTop", radiusTop},
        {"height", height},
        {"placement",
         {{"origin", {0.0, 0.0, 0.0}},
          {"zDirection", {0.0, 0.0, 1.0}},
          {"xDirection", {1.0, 0.0, 0.0}}}}}},
  };
}

nlohmann::json SphereOperation(const std::string& id, const std::string& bodyId,
                               const double radius, const std::array<double, 3>& origin) {
  return {
      {"id", id},
      {"type", "create_sphere"},
      {"outputBodyId", bodyId},
      {"parameters",
       {{"radius", radius},
        {"placement",
         {{"origin", {origin[0], origin[1], origin[2]}},
          {"zDirection", {0.0, 0.0, 1.0}},
          {"xDirection", {1.0, 0.0, 0.0}}}}}},
  };
}

nlohmann::json DatumPlaneOperation(const std::string& id, nlohmann::json parameters) {
  return {{"id", id}, {"type", "datum_plane"}, {"parameters", std::move(parameters)}};
}

nlohmann::json DatumAxisOperation(const std::string& id, nlohmann::json parameters) {
  return {{"id", id}, {"type", "datum_axis"}, {"parameters", std::move(parameters)}};
}

nlohmann::json HoleOperation(const std::string& id, const std::string& target, const double x,
                             const double y, const double z, const double dirZ, const double radius,
                             const bool throughAll, const double depth) {
  nlohmann::json parameters = {
      {"targetOperationId", target},
      {"size", {{"kind", "radius"}, {"radius", radius}}},
      {"throughAll", throughAll},
      {"placement",
       {{"origin", {x, y, z}}, {"zDirection", {0.0, 0.0, dirZ}}, {"xDirection", {1.0, 0.0, 0.0}}}},
  };
  if (!throughAll)
    parameters["depth"] = depth;
  return {{"id", id},
          {"type", "hole"},
          {"outputBodyId", "00000000-0000-4000-8000-0000000000he"},
          {"parameters", std::move(parameters)}};
}

nlohmann::json FilletOperation(const std::string& id, const std::string& target,
                               const nlohmann::json& edgesRef, const double radius) {
  return {
      {"id", id},
      {"type", "fillet"},
      {"schemaVersion", 2},
      {"outputBodyId", "00000000-0000-4000-8000-0000000000fe"},
      {"parameters", {{"targetOperationId", target}, {"radius", radius}, {"edges", edgesRef}}},
  };
}

nlohmann::json PatternLinearOperation(const std::string& id, const std::string& seed,
                                      const int count, const double spacing,
                                      const nlohmann::json& direction) {
  return {
      {"id", id},
      {"type", "pattern_linear"},
      {"outputBodyId", "00000000-0000-4000-8000-0000000000pe"},
      {"parameters",
       {{"seedOperationId", seed},
        {"count", count},
        {"spacing", spacing},
        {"direction", direction},
        {"op", "fuseInstances"}}},
  };
}

// --- STEP import fixture plumbing (mirrors step_import_test.cpp exactly:
// export a real solid, read the retained bytes back, hash them) -----------

std::string ToUtf8(const std::filesystem::path& path) {
  const std::u8string u8 = path.u8string();
  return std::string(reinterpret_cast<const char*>(u8.data()), u8.size());
}

std::string ReadAll(const std::filesystem::path& path) {
  std::ifstream input(path, std::ios::binary);
  if (!input)
    throw std::runtime_error("could not read STEP file for the import-replacement fixture");
  return std::string((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
}

std::string Sha256Of(const std::string& text) {
  aeth::Sha256 hasher;
  hasher.Update(reinterpret_cast<const unsigned char*>(text.data()), text.size());
  return hasher.HexDigest();
}

struct ImportSource final {
  std::string bytes;
  std::string sha256;
};

ImportSource ExportFixtureSource(const TopoDS_Shape& shape, const std::filesystem::path& path) {
  aeth::EvaluatedBody body;
  body.bodyId = "fixture-body";
  body.operationId = "fixture-op";
  body.shape = shape;
  body.probes = aeth::ProbeShape(body.shape);
  std::atomic_bool cancelled{false};
  aeth::ExportStep({body}, ToUtf8(path), cancelled);
  const std::string bytes = ReadAll(path);
  return {bytes, Sha256Of(bytes)};
}

nlohmann::json ImportOperation(const std::string& id, const ImportSource& source) {
  return {
      {"id", id},
      {"type", "import_step"},
      {"schemaVersion", 1},
      {"name", "mate-frame import-replacement fixture"},
      {"outputBodyId", "00000000-0000-4000-8000-0000000000ie"},
      {"parameters", {{"source", source.bytes}, {"sourceSha256", source.sha256}}},
  };
}

// --- AST builders (the wire form the parser emits; mirrors the §3 shape
// every other native suite in this directory already builds) --------------

nlohmann::json AsArray(std::initializer_list<nlohmann::json> items) {
  nlohmann::json array = nlohmann::json::array();
  for (const nlohmann::json& item : items)
    array.push_back(item);
  return array;
}

nlohmann::json ArgIdent(const std::string& value) { return {{"arg", "ident"}, {"value", value}}; }

nlohmann::json ArgPoint(const double x, const double y, const double z) {
  return {{"arg", "point"}, {"value", {x, y, z}}};
}

nlohmann::json ArgAxis(const std::string& axis) { return {{"arg", "axis"}, {"value", axis}}; }

nlohmann::json ArgNumber(const double value) { return {{"arg", "number"}, {"value", value}}; }

nlohmann::json Filter(const std::string& name, std::initializer_list<nlohmann::json> args = {}) {
  return {{"name", name}, {"args", AsArray(args)}};
}

nlohmann::json SrcOp(const std::string& id) { return {{"source", "op"}, {"opId", id}}; }

nlohmann::json Query(const std::string& kind, std::initializer_list<nlohmann::json> scope,
                     std::initializer_list<nlohmann::json> filters = {}) {
  return {{"kind", kind}, {"scope", AsArray(scope)}, {"filters", AsArray(filters)}};
}

// The kernel-wire ref slot (operationRefWireSchema) — ResolveMateFrame's
// `endpointRefSlot` parameter takes this exact shape (mate_frame.hpp: "the
// SAME shape ResolveRef's refSlot.at('ast') already expects... wrapped
// exactly like a refSlot"). `arity` is forced to "one" internally regardless
// of what is passed here, so its value here is documentation, not a live
// lever. `fillet`'s own `edges` parameter uses this same wrapper for an
// unrelated purpose (a kernel document operation's ref slot, not a
// mate-frame endpoint) in TournamentB below.
nlohmann::json AstRef(const nlohmann::json& ast, const std::string& arity = "one") {
  return {
      {"ast", ast}, {"arity", arity}, {"anchors", nlohmann::json::array()}, {"onEmpty", "error"}};
}

// --- Harness ----------------------------------------------------------------

struct RegistryRun final {
  aeth::NamingRegistry registry;
  std::vector<aeth::EvaluatedBody> bodies;
  std::atomic_bool cancelled{false};
};

void EvaluateInto(RegistryRun& run, const nlohmann::json& program) {
  run.bodies = aeth::EvaluateOperations(program, run.cancelled, nullptr, &run.registry, nullptr);
}

aeth::MateFrameResolution Resolve(const RegistryRun& run, const nlohmann::json& ast,
                                  const std::string& expectedGeometry) {
  return aeth::ResolveMateFrame(AstRef(ast), expectedGeometry, run.bodies, run.registry,
                                run.cancelled);
}

// =============================================================================
// REQUIRED COVERAGE 1-14
// =============================================================================

void Row01_PlanarFace() {
  std::printf("row 1: planar face -> Resolved Plane, directed, no radius/halfAngle:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array({BoxOperation(
                        kBoxOp, "00000000-0000-4000-8000-000000000001", 40, 30, 20)}));
  const aeth::MateFrameResolution result =
      Resolve(run, Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})}), "plane");
  checkStatus(result.status, aeth::MateFrameStatus::Resolved, "status is Resolved");
  if (result.status != aeth::MateFrameStatus::Resolved || !result.frame.has_value())
    return;
  const aeth::MateFrame& frame = *result.frame;
  checkGeometry(frame.geometry, aeth::MateFrameGeometry::Plane, "geometry class is Plane");
  check(frame.orientationClass == "directed", "orientationClass is 'directed' for a planar frame");
  check(!frame.radius.has_value(), "radius is absent for a plane frame");
  check(!frame.halfAngleRad.has_value(), "halfAngleRad is absent for a plane frame");
  checkVec(frame.origin, 0.0, 0.0, 20.0, kEps, "origin is the top face's centroid (0,0,20)");
  checkVec(frame.primary, 0.0, 0.0, 1.0, kEps, "primary is the outward normal (+z)");
  // CanonicalSecondary(0,0,1) (mate_frame.cpp): X=(1,0,0) has |dot|=0, the
  // smallest possible and the FIRST candidate tried, so it wins outright;
  // Gram-Schmidt against a primary already orthogonal to it is a no-op.
  checkVec(frame.secondary, 1.0, 0.0, 0.0, kEps,
           "secondary is CanonicalSecondary(0,0,1) = (1,0,0) exactly");
}

void Row02_CylindricalFace() {
  std::printf("row 2: cylindrical face -> Resolved Cylinder, undirected-axis, radius set:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array({CylinderOperation(
                        kCylOp, "00000000-0000-4000-8000-000000000002", 8.0, 30.0)}));
  const aeth::MateFrameResolution result =
      Resolve(run, Query("faces", {SrcOp(kCylOp)}, {Filter("cylindrical")}), "cylinder");
  checkStatus(result.status, aeth::MateFrameStatus::Resolved, "status is Resolved");
  if (result.status != aeth::MateFrameStatus::Resolved || !result.frame.has_value())
    return;
  const aeth::MateFrame& frame = *result.frame;
  checkGeometry(frame.geometry, aeth::MateFrameGeometry::Cylinder, "geometry class is Cylinder");
  check(frame.orientationClass == "undirected-axis",
        "orientationClass is 'undirected-axis' for a cylinder frame");
  check(frame.radius.has_value(), "radius is present for a cylinder frame");
  if (frame.radius.has_value())
    checkNear(*frame.radius, 8.0, kEps, "radius matches the constructed cylinder (8 mm)");
  check(!frame.halfAngleRad.has_value(), "halfAngleRad is absent for a cylinder frame");
  // CylinderFrame's origin is surface.Cylinder().Axis().Location() — the
  // construction frame passed to BRepPrimAPI_MakeCylinder, which this
  // fixture places at the world origin.
  checkVec(frame.origin, 0.0, 0.0, 0.0, kEps,
           "origin is the cylinder's own construction frame (0,0,0)");
  checkVec(
      frame.primary, 0.0, 0.0, 1.0, kEps,
      "primary is the sign-canonicalized axis direction (+z, geometry_measures.hpp Canonicalize)");
  checkVec(frame.secondary, 1.0, 0.0, 0.0, kEps,
           "secondary is CanonicalSecondary(0,0,1) = (1,0,0)");
}

void Row03_ConicalFace() {
  std::printf("row 3: conical face -> Resolved Cone, radius AND halfAngleRad both set:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array({ConeOperation(
                        kConeOp, "00000000-0000-4000-8000-000000000003", 10.0, 4.0, 20.0)}));
  const aeth::MateFrameResolution result =
      Resolve(run, Query("faces", {SrcOp(kConeOp)}, {Filter("conical")}), "cone");
  checkStatus(result.status, aeth::MateFrameStatus::Resolved, "status is Resolved");
  if (result.status != aeth::MateFrameStatus::Resolved || !result.frame.has_value())
    return;
  const aeth::MateFrame& frame = *result.frame;
  checkGeometry(frame.geometry, aeth::MateFrameGeometry::Cone, "geometry class is Cone");
  check(
      frame.orientationClass == "undirected-axis",
      "orientationClass is 'undirected-axis' for a cone frame (same axis convention as cylinder)");
  check(frame.radius.has_value(), "radius is set for a cone frame");
  check(frame.halfAngleRad.has_value(), "halfAngleRad is set for a cone frame");
  if (frame.radius.has_value()) {
    check(*frame.radius > 0.0 && *frame.radius <= 10.0 + kEps,
          "the reference radius lies within the frustum's [radiusTop, radiusBottom] envelope");
    // PREDICTION: ConicalFaceReferenceRadius == gp_Cone::RefRadius, defined at
    // the cone's own Ax3 location — BRepPrimAPI_MakeCone(axes, R1, R2, H)
    // positions that Ax3 at `axes` itself (z=0, radiusBottom=10 here). If
    // OCCT's internal convention differs, only this ONE bonus check fails —
    // the presence + envelope checks above already satisfy row 3's literal
    // requirement independently.
    checkNear(*frame.radius, 10.0, kEps,
              "(bonus) reference radius equals radiusBottom at the construction frame's z=0 plane");
  }
  if (frame.halfAngleRad.has_value()) {
    // The MAGNITUDE of a cone's semi-angle is atan(|R1-R2|/height) regardless
    // of gp_Cone::SemiAngle's sign convention (negative for a converging
    // cone) — the task's own requirement is presence, not an exact signed
    // value.
    checkNear(std::abs(*frame.halfAngleRad), std::atan(6.0 / 20.0), 1.0e-6,
              "halfAngleRad magnitude matches atan(|radiusBottom-radiusTop|/height)");
    check(std::abs(*frame.halfAngleRad) > 0.0 && std::abs(*frame.halfAngleRad) < kPi / 2.0,
          "halfAngleRad lies in the open (0, pi/2) range every valid cone satisfies");
  }
  checkVec(frame.secondary, 1.0, 0.0, 0.0, kEps,
           "secondary is CanonicalSecondary(0,0,1) = (1,0,0)");
}

void Row04_SphericalFace() {
  std::printf("row 4: spherical face -> Resolved Sphere, origin = the true center:\n");
  const std::array<double, 3> center = {12.0, -5.0, 3.0};
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array({SphereOperation(
                        kSphereOp, "00000000-0000-4000-8000-000000000004", 6.0, center)}));
  const aeth::MateFrameResolution result =
      Resolve(run, Query("faces", {SrcOp(kSphereOp)}, {Filter("spherical")}), "sphere");
  checkStatus(result.status, aeth::MateFrameStatus::Resolved, "status is Resolved");
  if (result.status != aeth::MateFrameStatus::Resolved || !result.frame.has_value())
    return;
  const aeth::MateFrame& frame = *result.frame;
  checkGeometry(frame.geometry, aeth::MateFrameGeometry::Sphere, "geometry class is Sphere");
  check(frame.orientationClass == "isotropic",
        "orientationClass is 'isotropic' for a sphere frame (no natural orientation)");
  check(frame.radius.has_value(), "radius is present for a sphere frame");
  if (frame.radius.has_value())
    checkNear(*frame.radius, 6.0, kEps, "radius matches the constructed sphere (6 mm)");
  check(!frame.halfAngleRad.has_value(), "halfAngleRad is absent for a sphere frame");
  // Hand-computed: BRepPrimAPI_MakeSphere(frame, radius) centers the sphere
  // exactly at the placement origin — the fixture's own known parameter.
  checkVec(frame.origin, center[0], center[1], center[2], kEps,
           "origin equals the sphere's true center (12, -5, 3)");
  // SphereFrame (mate_frame.cpp) hardcodes the isotropic fallback exactly
  // like VertexFrame does — the same fixed world axes.
  checkVec(frame.primary, 1.0, 0.0, 0.0, kEps, "primary is the fixed isotropic fallback (1,0,0)");
  checkVec(frame.secondary, 0.0, 1.0, 0.0, kEps,
           "secondary is the fixed isotropic fallback (0,1,0)");
}

void Row05_CircularEdge() {
  std::printf("row 5: circular edge -> Resolved Axis, radius set, origin = the circle's center:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array({CylinderOperation(
                        kCylOp, "00000000-0000-4000-8000-000000000005", 8.0, 30.0)}));
  // Two circular rim edges exist (top z=30, bottom z=0); max(z) picks the top
  // one uniquely (BRepGProp::LinearProperties centroid of a full circle IS
  // its geometric center, by symmetry — the same primitive the "min"/"max"
  // filter itself is built on).
  const aeth::MateFrameResolution result = Resolve(
      run, Query("edges", {SrcOp(kCylOp)}, {Filter("circle"), Filter("max", {ArgAxis("z")})}),
      "circle");
  checkStatus(result.status, aeth::MateFrameStatus::Resolved, "status is Resolved");
  if (result.status != aeth::MateFrameStatus::Resolved || !result.frame.has_value())
    return;
  const aeth::MateFrame& frame = *result.frame;
  checkGeometry(frame.geometry, aeth::MateFrameGeometry::Axis,
                "geometry class is Axis (circle collapses to the Axis frame)");
  check(frame.orientationClass == "undirected-axis",
        "orientationClass is 'undirected-axis' for a circular-edge frame");
  check(frame.radius.has_value(), "radius is present for a circular-edge frame");
  if (frame.radius.has_value())
    checkNear(*frame.radius, 8.0, kEps, "radius matches the cylinder's rim (8 mm)");
  check(!frame.halfAngleRad.has_value(), "halfAngleRad is absent for a circular-edge frame");
  checkVec(frame.origin, 0.0, 0.0, 30.0, kEps, "origin equals the top rim's center (0,0,30)");
  checkVec(frame.primary, 0.0, 0.0, 1.0, kEps, "primary is the sign-canonicalized rim axis (+z)");
  checkVec(frame.secondary, 1.0, 0.0, 0.0, kEps,
           "secondary is CanonicalSecondary(0,0,1) = (1,0,0)");
}

void Row06_LinearEdge() {
  std::printf(
      "row 6: linear edge -> Resolved Axis, no radius, origin = the parametric midpoint:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array({BoxOperation(
                        kBoxOp, "00000000-0000-4000-8000-000000000006", 40, 30, 20)}));
  // The vertical edge at the (-20,-15) corner, z in [0,20]; hand-computed
  // midpoint (-20,-15,10). LineEdgeFrame's origin is the CURVE-PARAMETER
  // midpoint, which for a straight edge equals the geometric midpoint.
  const aeth::MateFrameResolution result =
      Resolve(run,
              Query("edges", {SrcOp(kBoxOp)},
                    {Filter("line"), Filter("at", {ArgPoint(-20.0, -15.0, 10.0)})}),
              "line");
  checkStatus(result.status, aeth::MateFrameStatus::Resolved, "status is Resolved");
  if (result.status != aeth::MateFrameStatus::Resolved || !result.frame.has_value())
    return;
  const aeth::MateFrame& frame = *result.frame;
  checkGeometry(frame.geometry, aeth::MateFrameGeometry::Axis,
                "geometry class is Axis (line collapses to the Axis frame)");
  check(frame.orientationClass == "undirected-axis",
        "orientationClass is 'undirected-axis' for a linear-edge frame");
  check(!frame.radius.has_value(), "radius is absent for a linear-edge frame");
  check(!frame.halfAngleRad.has_value(), "halfAngleRad is absent for a linear-edge frame");
  checkVec(frame.origin, -20.0, -15.0, 10.0, kEps,
           "origin equals the edge's true parametric midpoint (-20,-15,10)");
  checkVec(frame.primary, 0.0, 0.0, 1.0, kEps,
           "primary is the sign-canonicalized edge direction (+z)");
  checkVec(frame.secondary, 1.0, 0.0, 0.0, kEps,
           "secondary is CanonicalSecondary(0,0,1) = (1,0,0)");
}

void Row07_Vertex() {
  std::printf("row 7: vertex -> Resolved Point, exact coords, primary/secondary = world x/y:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array({BoxOperation(
                        kBoxOp, "00000000-0000-4000-8000-000000000007", 40, 30, 20)}));
  const aeth::MateFrameResolution result = Resolve(
      run, Query("vertices", {SrcOp(kBoxOp)}, {Filter("at", {ArgPoint(-20.0, -15.0, 0.0)})}),
      "point");
  checkStatus(result.status, aeth::MateFrameStatus::Resolved, "status is Resolved");
  if (result.status != aeth::MateFrameStatus::Resolved || !result.frame.has_value())
    return;
  const aeth::MateFrame& frame = *result.frame;
  checkGeometry(frame.geometry, aeth::MateFrameGeometry::Point, "geometry class is Point");
  check(frame.orientationClass == "isotropic",
        "orientationClass is 'isotropic' for a point frame (no natural orientation)");
  check(!frame.radius.has_value(), "radius is absent for a point frame");
  check(!frame.halfAngleRad.has_value(), "halfAngleRad is absent for a point frame");
  checkVec(frame.origin, -20.0, -15.0, 0.0, kEps, "origin equals the vertex's exact coordinates");
  checkVec(frame.primary, 1.0, 0.0, 0.0, kEps, "primary is the fixed world x axis (1,0,0)");
  checkVec(frame.secondary, 0.0, 1.0, 0.0, kEps, "secondary is the fixed world y axis (0,1,0)");
}

void Row08_DatumPlane() {
  std::printf("row 8: datum plane -> Resolved through the IDENTICAL Plane path as row 1:\n");
  RegistryRun run;
  EvaluateInto(
      run,
      nlohmann::json::array(
          {BoxOperation(kBoxOp, "00000000-0000-4000-8000-000000000008", 40, 30, 20),
           DatumPlaneOperation(kDatumPlaneOp,
                               {{"mode", "offset"},
                                {"offset", 5.0},
                                {"base", AstRef(Query("faces", {SrcOp(kBoxOp)},
                                                      {Filter("role", {ArgIdent("top")})}))}})}));
  const aeth::MateFrameResolution result =
      Resolve(run, Query("faces", {SrcOp(kDatumPlaneOp)}), "plane");
  checkStatus(result.status, aeth::MateFrameStatus::Resolved, "status is Resolved");
  if (result.status != aeth::MateFrameStatus::Resolved || !result.frame.has_value())
    return;
  const aeth::MateFrame& frame = *result.frame;
  checkGeometry(frame.geometry, aeth::MateFrameGeometry::Plane,
                "geometry class is Plane (no datum special-casing)");
  check(frame.orientationClass == "directed",
        "orientationClass is 'directed', identical to row 1's planar-face frame");
  check(!frame.radius.has_value(), "radius is absent, identical to row 1");
  check(!frame.halfAngleRad.has_value(), "halfAngleRad is absent, identical to row 1");
  checkVec(frame.origin, 0.0, 0.0, 25.0, kEps, "origin = top + 5mm offset (0,0,25)");
  checkVec(frame.primary, 0.0, 0.0, 1.0, kEps, "primary is the base plane's outward normal (+z)");
  checkVec(frame.secondary, 1.0, 0.0, 0.0, kEps,
           "secondary is CanonicalSecondary(0,0,1) = (1,0,0)");
}

void Row09_DatumAxis() {
  std::printf("row 9: datum axis -> Resolved through the IDENTICAL Axis path as row 6:\n");
  RegistryRun run;
  // twoPoints a=top vertex, b=bottom vertex: the datum's OWN raw stored
  // direction is a->b = (0,0,-1), sense preserved (catalog_wave1_test.cpp's
  // own DatumAxisTwoPoints pins this — the datum layer does NOT canonicalize
  // it). The point of this row is that mate-frame extraction runs its OWN
  // CurveAxis()/Canonicalize() over whatever edge it resolves (mate_frame.cpp
  // LineEdgeFrame), so the reported primary below is expected to flip to
  // (0,0,1) regardless — proving "identical path" rather than a
  // special-cased pass-through of the datum's own sense.
  EvaluateInto(run,
               nlohmann::json::array(
                   {BoxOperation(kBoxOp, "00000000-0000-4000-8000-000000000009", 40, 30, 20),
                    DatumAxisOperation(
                        kDatumAxisOp,
                        {{"mode", "twoPoints"},
                         {"a", AstRef(Query("vertices", {SrcOp(kBoxOp)},
                                            {Filter("at", {ArgPoint(-20.0, -15.0, 20.0)})}))},
                         {"b", AstRef(Query("vertices", {SrcOp(kBoxOp)},
                                            {Filter("at", {ArgPoint(-20.0, -15.0, 0.0)})}))}})}));
  const nlohmann::json ast = Query("edges", {SrcOp(kDatumAxisOp)});
  for (const std::string& expectedGeometry : {std::string("axis"), std::string("line")}) {
    const aeth::MateFrameResolution result = Resolve(run, ast, expectedGeometry);
    checkStatus(result.status, aeth::MateFrameStatus::Resolved,
                "status is Resolved for expectedGeometry '" + expectedGeometry + "'");
    if (result.status != aeth::MateFrameStatus::Resolved || !result.frame.has_value())
      continue;
    const aeth::MateFrame& frame = *result.frame;
    checkGeometry(frame.geometry, aeth::MateFrameGeometry::Axis,
                  "geometry class is Axis for expectedGeometry '" + expectedGeometry + "'");
    check(frame.orientationClass == "undirected-axis",
          "orientationClass is 'undirected-axis', identical to row 6's linear-edge frame");
    check(!frame.radius.has_value(), "radius is absent, identical to row 6");
    checkVec(frame.primary, 0.0, 0.0, 1.0, kEps,
             "primary is CANONICALIZED to +z even though the datum's own raw sense was -z");
    checkVec(frame.secondary, 1.0, 0.0, 0.0, kEps,
             "secondary is CanonicalSecondary(0,0,1) = (1,0,0)");
  }
}

void Row10_Missing() {
  std::printf("row 10: a filter band no face satisfies -> Missing:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array({BoxOperation(
                        kBoxOp, "00000000-0000-4000-8000-000000000010", 40, 30, 20)}));
  const aeth::MateFrameResolution result = Resolve(
      run,
      Query("faces", {SrcOp(kBoxOp)}, {Filter("area", {ArgNumber(999999.0), ArgNumber(-1.0)})}),
      "plane");
  checkStatus(result.status, aeth::MateFrameStatus::Missing,
              "an area band no face reaches -> Missing");
  check(!result.message.empty(), "a Missing outcome carries a non-empty message");
  check(Contains(result.message, "no entities"),
        "the message is ResolveRef's own empty-match text (ResolveMateFrame passes ref.message "
        "through verbatim)");
}

void Row11_Ambiguous() {
  std::printf("row 11: >1 candidates with no anchor -> Ambiguous, capped at 5:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array({BoxOperation(
                        kBoxOp, "00000000-0000-4000-8000-000000000011", 40, 30, 20)}));
  // All 6 box faces, unfiltered: a "one"-arity resolution with no anchor (the
  // mate-frame endpoint's own AstRef always carries an empty anchors array)
  // is ambiguous by construction — ResolveRef's own no-anchor Ambiguous
  // branch, whose TopCandidates caps at 5 (ref_resolution.cpp kMaxCandidates).
  const aeth::MateFrameResolution result = Resolve(run, Query("faces", {SrcOp(kBoxOp)}), "plane");
  checkStatus(result.status, aeth::MateFrameStatus::Ambiguous,
              "6 candidates, no anchor -> Ambiguous");
  check(!result.candidates.empty(), "candidates is non-empty");
  check(result.candidates.size() == 5,
        "candidates is capped at exactly 5 (6 real matches, capped)");
  check(!result.message.empty(), "an Ambiguous outcome carries a non-empty message");
  check(Contains(result.message, "no anchor"),
        "the message is ResolveRef's own no-anchor Ambiguous text");
}

void Row12_InvalidatedGeometryClassMismatch() {
  std::printf("row 12: expectedGeometry 'plane' but a real cylindrical face -> Invalidated:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array({CylinderOperation(
                        kCylOp, "00000000-0000-4000-8000-000000000012", 8.0, 30.0)}));
  const aeth::MateFrameResolution result =
      Resolve(run, Query("faces", {SrcOp(kCylOp)}, {Filter("cylindrical")}), "plane");
  checkStatus(result.status, aeth::MateFrameStatus::Invalidated,
              "kind matches 'face' but geometryClass mismatches -> Invalidated");
  check(!result.message.empty(), "an Invalidated outcome carries a non-empty message");
  check(Contains(result.message, "cylinder") && Contains(result.message, "plane"),
        "the message names both the actual class and the mismatched expectedGeometry");
}

void Row13_InvalidatedKindMismatch() {
  std::printf("row 13: expectedGeometry 'axis' (edges) but a vertex resolves -> Invalidated:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array({BoxOperation(
                        kBoxOp, "00000000-0000-4000-8000-000000000013", 40, 30, 20)}));
  const aeth::MateFrameResolution result = Resolve(
      run, Query("vertices", {SrcOp(kBoxOp)}, {Filter("at", {ArgPoint(-20.0, -15.0, 0.0)})}),
      "axis");
  checkStatus(result.status, aeth::MateFrameStatus::Invalidated,
              "kind mismatch ('e' required, 'v' actual) -> Invalidated");
  check(!result.message.empty(), "an Invalidated outcome carries a non-empty message");
  check(Contains(result.message, "vertex") && Contains(result.message, "edge"),
        "the message names both the actual kind and the required kind");
}

void Row14_CoordinateFrameAlwaysInvalidated() {
  std::printf("row 14: expectedGeometry 'coordinate_frame' -> Invalidated unconditionally:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array({BoxOperation(
                        kBoxOp, "00000000-0000-4000-8000-000000000014", 40, 30, 20)}));
  // An otherwise-perfectly-valid, uniquely-resolvable planar-face selector —
  // mate_frame.cpp's ruling is that "coordinate_frame" is invalidated
  // UNCONDITIONALLY (LookUpRule returns nullopt before the resolved entity's
  // kind/class is even inspected), independent of what the selector itself
  // would have resolved.
  const aeth::MateFrameResolution result =
      Resolve(run, Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})}),
              "coordinate_frame");
  checkStatus(result.status, aeth::MateFrameStatus::Invalidated,
              "coordinate_frame -> Invalidated unconditionally");
  // The exact ruled message, read verbatim from mate_frame.cpp's own
  // coordinate_frame branch.
  check(result.message == "coordinate_frame endpoints are not resolvable: no kernel operation "
                          "currently produces a datum coordinate frame",
        "the message is the exact ruled coordinate_frame refusal text");
}

// =============================================================================
// QUALIFIED-EDIT TOURNAMENT (section 17: resize / fillet-chamfer / hole /
// pattern-count / import-replacement / operation-reorder)
// =============================================================================

void TournamentA_Resize() {
  std::printf("tournament A: RESIZE -- untouched face survives with an updated centroid:\n");
  const nlohmann::json ast = Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})});

  RegistryRun before;
  EvaluateInto(before, nlohmann::json::array({BoxOperation(
                           kBoxOp, "00000000-0000-4000-8000-0000000000a1", 40, 30, 20)}));
  const aeth::MateFrameResolution beforeResult = Resolve(before, ast, "plane");
  checkStatus(beforeResult.status, aeth::MateFrameStatus::Resolved, "before: resolved");
  if (beforeResult.status == aeth::MateFrameStatus::Resolved && beforeResult.frame.has_value())
    checkVec(beforeResult.frame->origin, 0.0, 0.0, 20.0, kEps,
             "before: origin at the original height");

  RegistryRun after;
  EvaluateInto(after, nlohmann::json::array({BoxOperation(
                          kBoxOp, "00000000-0000-4000-8000-0000000000a1", 40, 30, 35)}));
  const aeth::MateFrameResolution afterResult = Resolve(after, ast, "plane");
  checkStatus(afterResult.status, aeth::MateFrameStatus::Resolved,
              "after: the SAME selector (lineage-stable op(id)) is still Resolved");
  if (afterResult.status != aeth::MateFrameStatus::Resolved || !afterResult.frame.has_value())
    return;
  checkVec(afterResult.frame->origin, 0.0, 0.0, 35.0, kEps,
           "after: origin follows the resized height (updated centroid)");
  check(afterResult.frame->orientationClass == "directed", "after: orientationClass unchanged");
  checkVec(afterResult.frame->primary, 0.0, 0.0, 1.0, kEps, "after: primary unchanged (+z)");
}

void TournamentB_FilletAdjacentEdge() {
  std::printf("tournament B: FILLET -- untouched cap survives; the filleted edge does not:\n");
  const nlohmann::json topAst =
      Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})});
  // The bottom-front edge (y=-15, z=0), bordering only the BOTTOM face and one
  // SIDE face — deliberately not an edge bordering the top face, so the top
  // cap's own "top" record is never touched by this operation's Modified
  // harvest (naming_registry.cpp: RoleForModified only reclassifies a face
  // the op actually shares boundary with; an untouched face's original
  // record simply is never revisited — the exact behavior
  // catalog_wave1_test.cpp's ShellRegistryHarvest proves for an analogous
  // untouched-survivor case).
  const nlohmann::json edgeAst =
      Query("edges", {SrcOp(kBoxOp)}, {Filter("line"), Filter("at", {ArgPoint(0.0, -15.0, 0.0)})});

  const nlohmann::json box =
      BoxOperation(kBoxOp, "00000000-0000-4000-8000-0000000000b1", 40, 30, 20);
  RegistryRun before;
  EvaluateInto(before, nlohmann::json::array({box}));
  const aeth::MateFrameResolution beforeTop = Resolve(before, topAst, "plane");
  const aeth::MateFrameResolution beforeEdge = Resolve(before, edgeAst, "line");
  checkStatus(beforeTop.status, aeth::MateFrameStatus::Resolved, "before: top cap resolved");
  checkStatus(beforeEdge.status, aeth::MateFrameStatus::Resolved,
              "before: the target edge resolved");
  if (beforeEdge.status == aeth::MateFrameStatus::Resolved && beforeEdge.frame.has_value())
    checkVec(beforeEdge.frame->origin, 0.0, -15.0, 0.0, kEps,
             "before: edge origin is its midpoint");

  RegistryRun after;
  EvaluateInto(after,
               nlohmann::json::array(
                   {box, FilletOperation(kFilletOp, kBoxOp, AstRef(edgeAst, "one-or-more"), 2.0)}));

  const aeth::MateFrameResolution afterTop = Resolve(after, topAst, "plane");
  checkStatus(afterTop.status, aeth::MateFrameStatus::Resolved,
              "after: the UNTOUCHED top cap is still Resolved as Plane");
  if (afterTop.status == aeth::MateFrameStatus::Resolved && afterTop.frame.has_value())
    checkVec(afterTop.frame->origin, 0.0, 0.0, 20.0, kEps, "after: top cap centroid unchanged");

  // PREDICTION: the original sharp edge at (0,-15,0) is CONSUMED by the
  // fillet — replaced by a cylindrical blend plus two new tangent edges
  // offset by the 2mm radius; neither sits at the original point.
  // `edges(op(kBoxOp))` scope (selector_evaluator.cpp ExpandSource's "op"
  // branch) is minter-based, not body-based, and only includes LIVE
  // kBoxOp-minted edge records — the consumed edge's own record is excluded
  // from that scope outright, so this specific query is expected to resolve
  // empty -> Missing (the task explicitly allows Missing OR Invalidated
  // here; Missing is the outcome a QUERY-shaped, position-based selector
  // mechanically produces, independent of whatever alias bookkeeping the
  // registry does underneath for a token-shaped reference).
  const aeth::MateFrameResolution afterEdge = Resolve(after, edgeAst, "line");
  checkStatus(afterEdge.status, aeth::MateFrameStatus::Missing,
              "after: the filleted edge's own selector no longer finds it (Missing)");
}

void TournamentC_Hole() {
  std::printf("tournament C: HOLE -- untouched cap survives; the bore's own wall face resolves:\n");
  const nlohmann::json box =
      BoxOperation(kBoxOp, "00000000-0000-4000-8000-0000000000c1", 40, 30, 20);
  const nlohmann::json bottomAst =
      Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("bottom")})});

  RegistryRun before;
  EvaluateInto(before, nlohmann::json::array({box}));
  const aeth::MateFrameResolution beforeBottom = Resolve(before, bottomAst, "plane");
  checkStatus(beforeBottom.status, aeth::MateFrameStatus::Resolved, "before: bottom cap resolved");

  // A BLIND hole (depth 8 of 20) entering the TOP face: the bottom cap sits
  // entirely outside the blind hole's reach (genuinely untouched), while the
  // top face is genuinely re-trimmed with a new inner boundary.
  // naming_registry.cpp: RoleForModified(Hole, tool=false, 'f') == "modified"
  // for exactly that re-trimmed survivor (so a role("top") query would no
  // longer answer after this edit — not exercised here, only "bottom" is);
  // RoleForGenerated(Hole, tool=true, 'f') == "wall" for the bore's own
  // newly-generated cylindrical face — the "real wall-role re-mint" this row
  // names. The wall face is MINTED by the hole op, not the box op, so its
  // selector scopes through op(kHoleOp), not op(kBoxOp) (ExpandSource's "op"
  // branch is minter-based — see TournamentB's comment on the same
  // mechanism).
  const nlohmann::json hole = HoleOperation(kHoleOp, kBoxOp, 0.0, 0.0, 20.0, -1.0, 3.0, false, 8.0);
  RegistryRun after;
  EvaluateInto(after, nlohmann::json::array({box, hole}));

  const aeth::MateFrameResolution afterBottom = Resolve(after, bottomAst, "plane");
  checkStatus(afterBottom.status, aeth::MateFrameStatus::Resolved,
              "after: the UNTOUCHED bottom cap is still Resolved as Plane");
  if (afterBottom.status == aeth::MateFrameStatus::Resolved && afterBottom.frame.has_value())
    checkVec(afterBottom.frame->origin, 0.0, 0.0, 0.0, kEps,
             "after: bottom cap centroid unchanged");

  // PREDICTION (see comment above).
  const nlohmann::json wallAst =
      Query("faces", {SrcOp(kHoleOp)}, {Filter("role", {ArgIdent("wall")}), Filter("cylindrical")});
  const aeth::MateFrameResolution afterWall = Resolve(after, wallAst, "cylinder");
  checkStatus(afterWall.status, aeth::MateFrameStatus::Resolved,
              "after: the hole's own wall-role bore face resolves as Cylinder");
  if (afterWall.status == aeth::MateFrameStatus::Resolved && afterWall.frame.has_value())
    checkNear(afterWall.frame->radius.value_or(-1.0), 3.0, kEps,
              "after: wall radius matches the drilled bore (3 mm)");
}

void TournamentD_PatternCount() {
  std::printf("tournament D: PATTERN COUNT -- lower ordinals survive growth, die on shrink:\n");
  const nlohmann::json seed =
      // The live v1 pattern contract requires one connected solid.  A 12 mm
      // seed with 10 mm spacing keeps the three/five-instance chains fused
      // while preserving the ordinal-2 probe at x=20; the previous 4 mm seed
      // made this fixture ask the kernel to emit three disjoint solids.
      BoxOperation(kSeedOp, "00000000-0000-4000-8000-0000000000d1", 12, 4, 4);
  // Instance ordinal 2 (0-indexed, third copy): spacing 10 along +x, so its
  // top-face centroid is hand-computable at x = 2*10 = 20.
  const nlohmann::json ordinal2TopAst = Query(
      "faces", {SrcOp(kPatternOp)}, {Filter("planar"), Filter("at", {ArgPoint(20.0, 0.0, 4.0)})});

  RegistryRun before;
  EvaluateInto(before,
               nlohmann::json::array(
                   {seed, PatternLinearOperation(kPatternOp, kSeedOp, 3, 10.0, {1.0, 0.0, 0.0})}));
  const aeth::MateFrameResolution beforeResult = Resolve(before, ordinal2TopAst, "plane");
  checkStatus(beforeResult.status, aeth::MateFrameStatus::Resolved,
              "before (count=3): ordinal 2 resolved");

  RegistryRun increased;
  EvaluateInto(increased,
               nlohmann::json::array(
                   {seed, PatternLinearOperation(kPatternOp, kSeedOp, 5, 10.0, {1.0, 0.0, 0.0})}));
  const aeth::MateFrameResolution increasedResult = Resolve(increased, ordinal2TopAst, "plane");
  checkStatus(increasedResult.status, aeth::MateFrameStatus::Resolved,
              "increasing count to 5: ordinal 2 stays Resolved (its position is unchanged)");
  if (increasedResult.status == aeth::MateFrameStatus::Resolved &&
      increasedResult.frame.has_value())
    checkVec(increasedResult.frame->origin, 20.0, 0.0, 4.0, kEps,
             "increasing count: ordinal 2's centroid is UNCHANGED (20,0,4)");

  RegistryRun decreased;
  EvaluateInto(decreased,
               nlohmann::json::array(
                   {seed, PatternLinearOperation(kPatternOp, kSeedOp, 2, 10.0, {1.0, 0.0, 0.0})}));
  const aeth::MateFrameResolution decreasedResult = Resolve(decreased, ordinal2TopAst, "plane");
  checkStatus(decreasedResult.status, aeth::MateFrameStatus::Missing,
              "decreasing count to 2: ordinal 2 no longer exists -> Missing");
}

void TournamentE_ImportReplacement() {
  std::printf("tournament E: IMPORT REPLACEMENT -- the flat imported-face role has no anchor:\n");
  const std::filesystem::path scratch =
      std::filesystem::temp_directory_path() / "aeth-mate-frame-test-import";
  std::error_code ec;
  std::filesystem::remove_all(scratch, ec);
  std::filesystem::create_directories(scratch, ec);

  BRepPrimAPI_MakeBox boxMaker(20.0, 15.0, 10.0);
  const ImportSource boxSource = ExportFixtureSource(boxMaker.Solid(), scratch / "box.step");
  BRepPrimAPI_MakeCylinder cylinderMaker(6.0, 12.0);
  const ImportSource cylinderSource =
      ExportFixtureSource(cylinderMaker.Solid(), scratch / "cylinder.step");

  const nlohmann::json ast = Query("faces", {SrcOp(kImportOp)},
                                   {Filter("role", {ArgIdent("imported-face")}), Filter("planar")});

  // A box import: 6 planar faces under the flat "imported-face" role, no
  // authored construction frame to distinguish any one of them (CAP-011's
  // documented honest limit) -> a "one"-arity, no-anchor resolution is
  // Ambiguous by construction (see row 11's identical mechanism).
  RegistryRun before;
  EvaluateInto(before, nlohmann::json::array({ImportOperation(kImportOp, boxSource)}));
  const aeth::MateFrameResolution beforeResult = Resolve(before, ast, "plane");
  checkStatus(beforeResult.status, aeth::MateFrameStatus::Ambiguous,
              "before (box import, 6 planar imported-faces): Ambiguous, no anchor");
  check(!beforeResult.candidates.empty(), "before: candidates non-empty");

  // The SAME op id, source swapped to a structurally different fixture (a
  // cylinder: 2 planar caps + 1 cylindrical wall). The imported-face role is
  // still flat and still carries no anchor, so this remains Ambiguous — the
  // honest limit holds regardless of which structure is behind the import,
  // proving it is a structural property of import_step, not a fluke of one
  // fixture's exact face count.
  RegistryRun after;
  EvaluateInto(after, nlohmann::json::array({ImportOperation(kImportOp, cylinderSource)}));
  const aeth::MateFrameResolution afterResult = Resolve(after, ast, "plane");
  checkStatus(afterResult.status, aeth::MateFrameStatus::Ambiguous,
              "after (cylinder import, 2 planar imported-faces): still Ambiguous, no anchor");
  check(!afterResult.candidates.empty(), "after: candidates non-empty");
}

void TournamentF_OperationReorder() {
  std::printf("tournament F: REORDER -- unrelated ops, byte-identical resolution either order:\n");
  const nlohmann::json boxA =
      BoxOperation(kBoxAOp, "00000000-0000-4000-8000-0000000000f1", 10, 10, 10, {0.0, 0.0, 0.0});
  const nlohmann::json boxB =
      BoxOperation(kBoxBOp, "00000000-0000-4000-8000-0000000000f2", 6, 6, 6, {50.0, 0.0, 0.0});
  const nlohmann::json ast = Query("faces", {SrcOp(kBoxAOp)}, {Filter("role", {ArgIdent("top")})});

  RegistryRun before;
  EvaluateInto(before, nlohmann::json::array({boxA, boxB}));
  const aeth::MateFrameResolution beforeResult = Resolve(before, ast, "plane");

  RegistryRun after;
  EvaluateInto(after, nlohmann::json::array({boxB, boxA}));
  const aeth::MateFrameResolution afterResult = Resolve(after, ast, "plane");

  checkStatus(beforeResult.status, aeth::MateFrameStatus::Resolved, "original order: resolved");
  checkStatus(afterResult.status, aeth::MateFrameStatus::Resolved, "reordered: resolved");
  if (beforeResult.status != aeth::MateFrameStatus::Resolved ||
      afterResult.status != aeth::MateFrameStatus::Resolved || !beforeResult.frame.has_value() ||
      !afterResult.frame.has_value())
    return;
  checkGeometry(beforeResult.frame->geometry, afterResult.frame->geometry,
                "geometry class is identical regardless of unrelated-operation order");
  check(beforeResult.frame->orientationClass == afterResult.frame->orientationClass,
        "orientationClass is identical regardless of order");
  checkVecEqual(beforeResult.frame->origin, afterResult.frame->origin, kEps,
                "origin is identical regardless of order");
  checkVecEqual(beforeResult.frame->primary, afterResult.frame->primary, kEps,
                "primary is identical regardless of order");
  checkVecEqual(beforeResult.frame->secondary, afterResult.frame->secondary, kEps,
                "secondary is identical regardless of order");
  checkVec(beforeResult.frame->origin, 0.0, 0.0, 10.0, kEps,
           "origin is boxA's own top-face centroid (0,0,10), unaffected by boxB's presence/order");
}

} // namespace

int main() {
  try {
    Row01_PlanarFace();
    Row02_CylindricalFace();
    Row03_ConicalFace();
    Row04_SphericalFace();
    Row05_CircularEdge();
    Row06_LinearEdge();
    Row07_Vertex();
    Row08_DatumPlane();
    Row09_DatumAxis();
    Row10_Missing();
    Row11_Ambiguous();
    Row12_InvalidatedGeometryClassMismatch();
    Row13_InvalidatedKindMismatch();
    Row14_CoordinateFrameAlwaysInvalidated();
    TournamentA_Resize();
    TournamentB_FilletAdjacentEdge();
    TournamentC_Hole();
    TournamentD_PatternCount();
    TournamentE_ImportReplacement();
    TournamentF_OperationReorder();
  } catch (const std::exception& error) {
    std::printf("FATAL: uncaught exception: %s\n", error.what());
    return 1;
  }
  if (g_failures == 0) {
    std::printf("\nALL MATE FRAME TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d MATE FRAME CHECK(S) FAILED\n", g_failures);
  return 1;
}
