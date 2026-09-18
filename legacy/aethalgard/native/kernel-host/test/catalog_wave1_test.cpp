// Native integration tests for the catalog wave-1 executors — datum_plane,
// datum_axis, shell (docs/design/2026-07-19-native-catalog-wave1.md §5; plan
// 01-geometry-core/02 §2.3/§2.5/§3, plan 04 `shell`). They drive the REAL
// EvaluateOperations path both bare and registry-threaded and pin:
//
//   1. the closed-hollow shell's ANALYTIC volumes and topology in both
//      directions (inward keeps the outer size; outward's grown skin carries
//      the Arc-join edge/corner rounding in its closed form), its element
//      naming, and its registry harvest (6 `wall` records, target tokens
//      still live, totality);
//   2. the Wave 2.4 thickness feasibility payload (a tested lower bound the
//      op actually succeeds at);
//   3. the openFaces contract, now COMPLETE (CAP-013): resolution, every
//      resolve-time validation (persisted-form guard, off-body faces,
//      all-faces-removed, empty-ok -> closed hollow), AND the ByJoin execution
//      that turns a resolved set into an open container — one solid bounded by
//      ONE shell, against the closed hollow's two;
//   4. every datum mode's frame derivation (anchor + direction, §2.5
//      canonicalization where mandated, sense preservation where not) and the
//      E_DATUM_INVALID_REFERENCE taxonomy in `details`;
//   5. the synthetic entity records (`t:<opId>/plane/0`, `t:<opId>/axis/0`),
//      the evaluator RESOLVING them body-less (CAP-014), and registry
//      replay determinism across independent evaluations.
#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstddef>
#include <cstdio>
#include <initializer_list>
#include <stdexcept>
#include <string>
#include <vector>

#include <BRepAdaptor_Curve.hxx>
#include <BRepAdaptor_Surface.hxx>
#include <GeomAbs_CurveType.hxx>
#include <GeomAbs_SurfaceType.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <gp_Dir.hxx>
#include <gp_Lin.hxx>
#include <gp_Pln.hxx>
#include <gp_Pnt.hxx>
#include <nlohmann/json.hpp>

#include "element_names.hpp"
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

void checkNear(const double actual, const double expected, const double tolerance,
               const std::string& label) {
  if (std::abs(actual - expected) <= tolerance) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s (expected %.6f, got %.6f)\n", label.c_str(), expected, actual);
    g_failures += 1;
  }
}

void checkDirNear(const gp_Dir& actual, const double x, const double y, const double z,
                  const std::string& label) {
  const bool near = std::abs(actual.X() - x) <= 1e-9 && std::abs(actual.Y() - y) <= 1e-9 &&
                    std::abs(actual.Z() - z) <= 1e-9;
  if (near) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s (expected (%.6f, %.6f, %.6f), got (%.6f, %.6f, %.6f))\n", label.c_str(),
                x, y, z, actual.X(), actual.Y(), actual.Z());
    g_failures += 1;
  }
}

const std::string kBoxOp = "aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa";
const std::string kOtherBoxOp = "abababab-2222-4a22-8a22-abababababab";
const std::string kHoleOp = "bbbbbbbb-3333-4b33-8b33-bbbbbbbbbbbb";
const std::string kShellOp = "cccccccc-4444-4c44-8c44-cccccccccccc";
const std::string kDatumPlaneOp = "dddddddd-5555-4d55-8d55-dddddddddddd";
const std::string kDatumAxisOp = "eeeeeeee-6666-4e66-8e66-eeeeeeeeeeee";

// --- Operation builders ------------------------------------------------------

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

// A through-all hole drilled downward from the top face at (x, y, top).
nlohmann::json HoleOperation(const std::string& id, const std::string& target, const double x,
                             const double y, const double top, const double radius) {
  return {
      {"id", id},
      {"type", "hole"},
      {"outputBodyId", "00000000-0000-4000-8000-00000000000c"},
      {"parameters",
       {{"targetOperationId", target},
        {"size", {{"kind", "radius"}, {"radius", radius}}},
        {"throughAll", true},
        {"placement",
         {{"origin", {x, y, top}},
          {"zDirection", {0.0, 0.0, -1.0}},
          {"xDirection", {1.0, 0.0, 0.0}}}}}},
  };
}

nlohmann::json ShellOperation(const std::string& id, const std::string& target,
                              const double thickness, const std::string& direction) {
  nlohmann::json parameters = {{"targetOperationId", target}, {"thickness", thickness}};
  if (!direction.empty())
    parameters["direction"] = direction;
  return {
      {"id", id},
      {"type", "shell"},
      {"outputBodyId", "00000000-0000-4000-8000-00000000000d"},
      {"parameters", std::move(parameters)},
  };
}

nlohmann::json DatumPlaneOperation(const std::string& id, nlohmann::json parameters) {
  return {{"id", id}, {"type", "datum_plane"}, {"parameters", std::move(parameters)}};
}

nlohmann::json DatumAxisOperation(const std::string& id, nlohmann::json parameters) {
  return {{"id", id}, {"type", "datum_axis"}, {"parameters", std::move(parameters)}};
}

// --- AST builders (the wire form the parser emits; §3 mirror) ----------------

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

nlohmann::json ArgDirAxis(const int sign, const std::string& axis) {
  return {{"arg", "direction"}, {"value", {{"form", "axis"}, {"sign", sign}, {"axis", axis}}}};
}

nlohmann::json Filter(const std::string& name, std::initializer_list<nlohmann::json> args = {}) {
  return {{"name", name}, {"args", AsArray(args)}};
}

nlohmann::json SrcOp(const std::string& id) { return {{"source", "op"}, {"opId", id}}; }

nlohmann::json SrcToken(const std::string& token) {
  return {{"source", "token"}, {"token", token}};
}

nlohmann::json Query(const std::string& kind, std::initializer_list<nlohmann::json> scope,
                     std::initializer_list<nlohmann::json> filters = {}) {
  return {{"kind", kind}, {"scope", AsArray(scope)}, {"filters", AsArray(filters)}};
}

// The kernel-wire ref slot (operationRefWireSchema).
nlohmann::json AstRef(const nlohmann::json& ast, const std::string& arity = "one",
                      const std::string& onEmpty = "error") {
  return {
      {"ast", ast}, {"arity", arity}, {"anchors", nlohmann::json::array()}, {"onEmpty", onEmpty}};
}

// --- Harness -----------------------------------------------------------------

struct RegistryRun final {
  aeth::NamingRegistry registry;
  std::vector<aeth::EvaluatedBody> bodies;
  std::atomic_bool cancelled{false};
};

void EvaluateInto(RegistryRun& run, const nlohmann::json& program) {
  run.bodies = aeth::EvaluateOperations(program, run.cancelled, nullptr, &run.registry);
}

/// One captured refusal, whichever typed channel it arrived on.
struct Refusal final {
  std::string kind; // "operation" | "selector" | "reference-missing" | "none" | "other"
  std::string code;
  std::string selectorCode;
  std::string operationId;
  std::string message;
  nlohmann::json details;
};

Refusal RunExpectingRefusal(const nlohmann::json& program, const bool withRegistry) {
  std::atomic_bool cancelled{false};
  try {
    if (withRegistry) {
      aeth::NamingRegistry registry;
      aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
    } else {
      aeth::EvaluateOperations(program, cancelled);
    }
    return {"none", "", "", "", "", {}};
  } catch (const aeth::SelectorFailure& error) {
    return {"selector",          error.Code(), error.SelectorCode(),
            error.OperationId(), error.what(), error.Details()};
  } catch (const aeth::OperationFailure& error) {
    return {"operation", error.Code(), "", error.OperationId(), error.what(), error.Details()};
  } catch (const aeth::ReferenceMissing& error) {
    return {"reference-missing", "", "", error.OperationId(), error.what(), {}};
  } catch (const std::exception& error) {
    return {"other", "", "", "", error.what(), {}};
  }
}

bool Contains(const std::string& haystack, const std::string& needle) {
  return haystack.find(needle) != std::string::npos;
}

std::string Prefix8(const std::string& operationId) {
  std::string prefix;
  for (const char character : operationId) {
    if (character == '-')
      continue;
    prefix.push_back(character);
    if (prefix.size() == 8)
      break;
  }
  return prefix;
}

// --- Shell: closed hollow ----------------------------------------------------

void ShellClosedHollowInward() {
  std::printf("shell closed hollow (inward) matches the analytic volume:\n");
  const nlohmann::json program = nlohmann::json::array(
      {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 60, 40, 20),
       ShellOperation(kShellOp, kBoxOp, 1.6, "")});
  std::atomic_bool cancelled{false};
  const std::vector<aeth::EvaluatedBody> bodies = aeth::EvaluateOperations(program, cancelled);
  check(bodies.size() == 1 && bodies.front().operationId == kShellOp,
        "the shell consumes its target and is the single visible body");
  if (bodies.size() != 1)
    return;
  const aeth::ShapeProbes& probes = bodies.front().probes;
  check(probes.valid, "the hollow solid is valid");
  // Outer 60x40x20 minus the 56.8x36.8x16.8 cavity (walls 1.6 on every side).
  checkNear(probes.volume, 48000.0 - 56.8 * 36.8 * 16.8, 1e-3,
            "volume equals outer minus cavity (12883.968 mm^3)");
  check(probes.solidCount == 1 && probes.shellCount == 2,
        "one solid bounded by two shells (outer skin + cavity)");
  check(probes.faceCount == 12, "6 outer + 6 cavity faces");
  checkNear(probes.bounds[0], -30.0, 1e-6, "inward keeps xmin");
  checkNear(probes.bounds[2], 0.0, 1e-6, "inward keeps zmin");
  checkNear(probes.bounds[5], 20.0, 1e-6, "inward keeps zmax (outer size unchanged)");
}

void ShellClosedHollowOutward() {
  std::printf("shell closed hollow (outward) grows the body and keeps the cavity:\n");
  const nlohmann::json program = nlohmann::json::array(
      {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 60, 40, 20),
       ShellOperation(kShellOp, kBoxOp, 1.6, "outward")});
  std::atomic_bool cancelled{false};
  const std::vector<aeth::EvaluatedBody> bodies = aeth::EvaluateOperations(program, cancelled);
  check(bodies.size() == 1, "outward shell produces one body");
  if (bodies.size() != 1)
    return;
  const aeth::ShapeProbes& probes = bodies.front().probes;
  check(probes.valid && probes.solidCount == 1 && probes.shellCount == 2,
        "one valid solid bounded by two shells");
  // The +1.6 offset of a convex box under the Arc join rounds edges and
  // corners: V = t*A + (pi t^2 / 4) * sum(edgeLengths) + (4/3) pi t^3 over
  // the original box (A = 8800 mm^2, edges 480 mm).
  const double t = 1.6;
  const double analytic = t * 8800.0 + (3.14159265358979323846 * t * t / 4.0) * 480.0 +
                          (4.0 / 3.0) * 3.14159265358979323846 * t * t * t;
  checkNear(probes.volume, analytic, 0.5, "volume equals the grown-skin analytic shell volume");
  checkNear(probes.bounds[2], -1.6, 1e-6, "outward grows zmin");
  checkNear(probes.bounds[5], 21.6, 1e-6, "outward grows zmax");
}

void ShellNamesEveryEntity() {
  std::printf("shell records element names for every result entity (bare book):\n");
  const nlohmann::json program = nlohmann::json::array(
      {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 60, 40, 20),
       ShellOperation(kShellOp, kBoxOp, 1.6, "inward")});
  std::atomic_bool cancelled{false};
  aeth::ElementNameBook book;
  const std::vector<aeth::EvaluatedBody> bodies =
      aeth::EvaluateOperations(program, cancelled, &book);
  check(bodies.size() == 1, "the hollow body evaluated under element naming");
  if (bodies.size() != 1)
    return;
  // Coverage is total by contract; count the roots. The outer skin keeps
  // box-rooted names; the cavity's names root at the shell op (its synthetic
  // offset solid is AddPrimitive-rooted there, the hole-cylinder pattern).
  const nlohmann::json projected = aeth::ProjectElementNames(book, bodies.front().shape, 1, 0);
  std::size_t boxRootedFaces = 0;
  std::size_t shellRootedFaces = 0;
  std::size_t faceEntries = 0;
  for (const nlohmann::json& entry : projected) {
    const std::string token = entry.at("token").get<std::string>();
    const std::string name = entry.at("name").get<std::string>();
    // TopologyEntityToken format: te:<epoch>:<body>:<kind>:<index>.
    if (!Contains(token, ":f:"))
      continue;
    faceEntries += 1;
    if (name.starts_with("n1:" + Prefix8(kBoxOp)))
      boxRootedFaces += 1;
    if (name.starts_with("n1:" + Prefix8(kShellOp)))
      shellRootedFaces += 1;
  }
  check(faceEntries == 12, "all 12 faces project element names");
  check(boxRootedFaces == 6, "the 6 outer faces keep their box-rooted lineage");
  check(shellRootedFaces == 6, "the 6 cavity faces root at the shell operation");
}

void ShellRegistryHarvest() {
  std::printf("shell harvests wall records and keeps target tokens live (registry):\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array(
                        {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 60, 40, 20),
                         ShellOperation(kShellOp, kBoxOp, 1.6, "inward")}));
  check(run.bodies.size() == 1, "the hollow body evaluated under the registry");
  std::size_t wallRecords = 0;
  std::size_t liveBoxFaceRecords = 0;
  for (std::size_t index = 0; index < run.registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = run.registry.RecordAt(index);
    if (record.minter == kShellOp && record.role == "wall" && record.kind == 'f' && record.live)
      wallRecords += 1;
    if (record.minter == kBoxOp && record.kind == 'f' && record.live)
      liveBoxFaceRecords += 1;
  }
  check(wallRecords == 6, "the cavity mints 6 live wall records under the shell op");
  check(liveBoxFaceRecords == 6, "the target's 6 face records stay live (outer skin survives)");
  const aeth::NamingRecord* wallZero = run.registry.FindByToken("t:" + kShellOp + "/wall/0");
  check(wallZero != nullptr && wallZero->live, "t:<shellOp>/wall/0 resolves to a live record");
}

void ShellFeasibilityBound() {
  std::printf("an infeasible shell thickness reports a TESTED feasibility bound:\n");
  const nlohmann::json box =
      BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 60, 40, 20);
  const Refusal refusal = RunExpectingRefusal(
      nlohmann::json::array({box, ShellOperation(kShellOp, kBoxOp, 15.0, "inward")}), false);
  check(refusal.kind == "operation" && refusal.code == "GEOMETRY_FAILED",
        "t=15 on a 20 mm body fails GEOMETRY_FAILED");
  check(refusal.operationId == kShellOp, "the failure is attributed to the shell operation");
  if (!refusal.details.contains("feasibilityProbe")) {
    check(false, "the failure carries a feasibilityProbe payload");
    return;
  }
  const nlohmann::json& probe = refusal.details.at("feasibilityProbe");
  check(probe.at("parameter").get<std::string>() == "thickness",
        "the probe names the thickness parameter");
  // The payload is EXACTLY the wire schema's strict thickness variant
  // (geometryFeasibilityDetailsSchema): the request/bound pair plus the probe.
  check(refusal.details.at("requestedThickness").get<double>() == 15.0,
        "the payload echoes the requested thickness");
  checkNear(refusal.details.at("maxFeasibleThickness").get<double>(),
            probe.at("maxFeasible").get<double>(), 0.0,
            "maxFeasibleThickness matches the probe bound");
  const double maxFeasible = probe.at("maxFeasible").get<double>();
  check(maxFeasible > 0.0 && maxFeasible < 10.0,
        "the tested bound lies below the 10 mm half-height");
  // The bound is a TESTED success: re-running at it must hollow cleanly.
  std::atomic_bool cancelled{false};
  const std::vector<aeth::EvaluatedBody> bodies = aeth::EvaluateOperations(
      nlohmann::json::array({box, ShellOperation(kShellOp, kBoxOp, maxFeasible, "inward")}),
      cancelled);
  check(bodies.size() == 1 && bodies.front().probes.shellCount == 2,
        "re-running at the reported bound produces the hollow");
}

void ShellDirectionFailsClosed() {
  std::printf("an unknown shell direction fails closed:\n");
  const Refusal refusal = RunExpectingRefusal(
      nlohmann::json::array(
          {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 60, 40, 20),
           ShellOperation(kShellOp, kBoxOp, 1.6, "sideways")}),
      false);
  check(refusal.kind == "operation" && refusal.code == "INVALID_REQUEST" &&
            refusal.operationId == kShellOp,
        "direction 'sideways' -> attributed INVALID_REQUEST");
}

// --- Shell: openFaces staging ------------------------------------------------

nlohmann::json ShellWithOpenFaces(const nlohmann::json& openFaces, const double thickness = 1.6) {
  nlohmann::json shell = ShellOperation(kShellOp, kBoxOp, thickness, "inward");
  shell["parameters"]["openFaces"] = openFaces;
  return shell;
}

void ShellOpenFacesExecutes() {
  std::printf("shell openFaces: resolution, validation AND execution (CAP-013):\n");
  const nlohmann::json box =
      BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 60, 40, 20);

  // CAP-013 FLIPPED THIS PIN. A resolved open-face set used to refuse
  // UNSUPPORTED_OPERATION naming the unverified ByJoin history. That history is
  // now MEASURED deterministic, and the harvest below attributes the result
  // under the registry's totality rule, so the set EXECUTES into an open
  // container. The pin's expiry is the intended signal (PROTOCOL §5).
  {
    const nlohmann::json program = nlohmann::json::array(
        {box, ShellWithOpenFaces(
                  AstRef(Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})}),
                         "any", "empty-ok"))});
    std::atomic_bool cancelled{false};
    aeth::NamingRegistry registry;
    const std::vector<aeth::EvaluatedBody> bodies =
        aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
    check(bodies.size() == 1 && bodies.front().operationId == kShellOp,
          "an open-face set EXECUTES into a single visible body");
    if (bodies.size() == 1) {
      const aeth::ShapeProbes& probes = bodies.front().probes;
      check(probes.valid, "the open container is a valid solid");
      // A 60x40x20 box hollowed 1.6 with the TOP left open is the closed
      // hollow PLUS the material the missing top wall would have occupied:
      // 48000 - 56.8*36.8*18.4 (the cavity now runs to the top face).
      checkNear(probes.volume, 48000.0 - 56.8 * 36.8 * 18.4, 1e-3,
                "volume equals outer minus the open-topped cavity");
      // The defining difference from a closed hollow: ONE shell, not two. An
      // open container's cavity is continuous with the outside, so the outer
      // skin and the cavity are a single connected boundary.
      check(probes.solidCount == 1 && probes.shellCount == 1,
            "an open container is ONE solid bounded by ONE shell (not two)");
      checkNear(probes.bounds[5], 20.0, 1e-6, "the outer size is unchanged");
    }
  }

  // Work-order item 6: an infeasible OPEN container reports the same TESTED
  // bound a closed one does. Without the ByJoin probe this refusal would carry
  // `probeSkipped` — the same failure, silently less useful.
  //
  // MEASURED while writing this: the open container is MORE permissive than the
  // closed hollow, and the first version of this check was wrong because of it.
  // 15 mm walls collapse a closed 60x40x20 hollow (six walls collide), but with
  // the TOP left open the same 15 mm builds a valid thick-walled tray — there is
  // no top wall to collide with. The collapse threshold is the 40 mm DEPTH, so
  // the refusal needs t >= 20. That is a real difference in the two paths'
  // feasible ranges, which is exactly why this path needs its OWN probe rather
  // than inheriting the closed hollow's number.
  {
    const nlohmann::json thick =
        BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 60, 40, 20);
    const Refusal infeasible = RunExpectingRefusal(
        nlohmann::json::array(
            {thick, ShellWithOpenFaces(
                        AstRef(Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})}),
                               "any", "empty-ok"),
                        25.0)}),
        true);
    check(infeasible.kind == "operation" && infeasible.code == "GEOMETRY_FAILED",
          "an infeasible open container fails GEOMETRY_FAILED");
    const nlohmann::json probe = infeasible.details.value("feasibilityProbe", nlohmann::json());
    check(probe.value("parameter", std::string()) == "thickness" &&
              probe.value("bound", std::string()) == "tested-lower-bound",
          "the open-container refusal carries the SAME tested thickness bound as the closed one");
    check(!infeasible.details.contains("probeSkipped"),
          "the open path does not silently downgrade to probeSkipped");
  }

  // ALL faces resolved -> E_SHELL_ALL_FACES_REMOVED (doc 04 rule 3).
  const Refusal allFaces = RunExpectingRefusal(
      nlohmann::json::array(
          {box, ShellWithOpenFaces(AstRef(Query("faces", {SrcOp(kBoxOp)}), "any", "empty-ok"))}),
      true);
  check(allFaces.kind == "operation" && allFaces.code == "INVALID_REQUEST" &&
            allFaces.details.value("shellCode", "") == "E_SHELL_ALL_FACES_REMOVED",
        "resolving every target face -> E_SHELL_ALL_FACES_REMOVED");
  check(allFaces.details.value("faceCount", 0) == 6, "the refusal reports the face count");

  // A face on a DIFFERENT body -> open-face-not-on-body (doc 04 rule 2).
  const nlohmann::json otherBox =
      BoxOperation(kOtherBoxOp, "00000000-0000-4000-8000-00000000000e", 10, 10, 10);
  const Refusal offBody = RunExpectingRefusal(
      nlohmann::json::array({box, otherBox,
                             ShellWithOpenFaces(AstRef(Query("faces", {SrcOp(kOtherBoxOp)},
                                                             {Filter("role", {ArgIdent("top")})}),
                                                       "any", "empty-ok"))}),
      true);
  check(offBody.kind == "operation" && offBody.code == "INVALID_REQUEST" &&
            offBody.details.value("reason", "") == "open-face-not-on-body",
        "an off-body open face -> E_SHELL_FAILED / open-face-not-on-body");

  // Persisted-form slot -> the F1 transport guard.
  const Refusal persisted = RunExpectingRefusal(
      nlohmann::json::array(
          {box, ShellWithOpenFaces({{"query", "faces(op(x)).role(top)"}, {"arity", "any"}})}),
      true);
  check(persisted.kind == "operation" && persisted.code == "INVALID_REQUEST" &&
            Contains(persisted.message, "persisted query form"),
        "a persisted-form openFaces slot -> INVALID_REQUEST (transport guard)");

  // Without a registry the slot cannot resolve at all.
  const Refusal noRegistry = RunExpectingRefusal(
      nlohmann::json::array(
          {box, ShellWithOpenFaces(
                    AstRef(Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})}),
                           "any", "empty-ok"))}),
      false);
  check(noRegistry.kind == "operation" && noRegistry.code == "UNSUPPORTED_OPERATION" &&
            Contains(noRegistry.message, "naming registry"),
        "openFaces without a registry -> UNSUPPORTED_OPERATION naming the registry");

  // An EMPTY empty-ok resolution IS the closed hollow.
  RegistryRun run;
  EvaluateInto(run,
               nlohmann::json::array({box, ShellWithOpenFaces(AstRef(Query("faces", {SrcOp(kBoxOp)},
                                                                           {Filter("cylindrical")}),
                                                                     "any", "empty-ok"))}));
  check(run.bodies.size() == 1 && run.bodies.front().probes.shellCount == 2,
        "an empty empty-ok openFaces resolution executes the closed hollow");
}

// --- Datum plane -------------------------------------------------------------

const aeth::NamingRecord* DatumRecord(const aeth::NamingRegistry& registry,
                                      const std::string& operationId, const char* role) {
  return registry.FindByToken("t:" + operationId + "/" + role + "/0");
}

void DatumPlaneOffsetMode() {
  std::printf("datum_plane offset derives anchor + normal from the base face:\n");
  RegistryRun run;
  EvaluateInto(
      run,
      nlohmann::json::array(
          {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
           DatumPlaneOperation(kDatumPlaneOp,
                               {{"mode", "offset"},
                                {"offset", 5.0},
                                {"base", AstRef(Query("faces", {SrcOp(kBoxOp)},
                                                      {Filter("role", {ArgIdent("top")})}))}})}));
  check(run.bodies.size() == 1 && run.bodies.front().operationId == kBoxOp,
        "the datum produces NO body (the box stays the only visible body)");
  const aeth::NamingRecord* record = DatumRecord(run.registry, kDatumPlaneOp, "plane");
  check(record != nullptr && record->live && record->kind == 'f' && record->role == "plane",
        "t:<opId>/plane/0 is a live face-kinded record");
  if (record == nullptr)
    return;
  const BRepAdaptor_Surface surface(TopoDS::Face(record->shape), true);
  check(surface.GetType() == GeomAbs_Plane, "the backing shape is a planar face");
  const gp_Pln plane = surface.Plane();
  checkNear(plane.Location().X(), 0.0, 1e-9, "anchor x = projected world origin");
  checkNear(plane.Location().Y(), 0.0, 1e-9, "anchor y = projected world origin");
  checkNear(plane.Location().Z(), 25.0, 1e-9, "anchor z = top + 5 mm offset");
  checkDirNear(plane.Axis().Direction(), 0.0, 0.0, 1.0, "the plane normal is the base outward +z");
}

void DatumPlaneOffsetSideFace() {
  std::printf("datum_plane offset works off a side face with a negative offset:\n");
  RegistryRun run;
  EvaluateInto(run,
               nlohmann::json::array(
                   {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
                    DatumPlaneOperation(
                        kDatumPlaneOp,
                        {{"mode", "offset"},
                         {"offset", -3.0},
                         {"base", AstRef(Query("faces", {SrcOp(kBoxOp)},
                                               {Filter("normal", {ArgDirAxis(1, "x")})}))}})}));
  const aeth::NamingRecord* record = DatumRecord(run.registry, kDatumPlaneOp, "plane");
  check(record != nullptr, "the side-face datum minted its record");
  if (record == nullptr)
    return;
  const gp_Pln plane = BRepAdaptor_Surface(TopoDS::Face(record->shape), true).Plane();
  // Base plane x = 20 (outward +x); anchor = (20,0,0) - 3 * (+x) = (17,0,0).
  checkNear(plane.Location().X(), 17.0, 1e-9, "anchor moved 3 mm INTO the material");
  checkDirNear(plane.Axis().Direction(), 1.0, 0.0, 0.0, "the normal stays the outward +x");
}

void DatumPlaneAngledMode() {
  std::printf("datum_plane angled rotates the base normal about an on-plane axis:\n");
  RegistryRun run;
  EvaluateInto(
      run, nlohmann::json::array(
               {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
                DatumPlaneOperation(
                    kDatumPlaneOp,
                    {{"mode", "angled"},
                     {"angle", 45.0},
                     {"base",
                      AstRef(Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})}))},
                     {"axis", AstRef(Query("edges", {SrcOp(kBoxOp)},
                                           {Filter("at", {ArgPoint(0.0, -15.0, 20.0)})}))}})}));
  const aeth::NamingRecord* record = DatumRecord(run.registry, kDatumPlaneOp, "plane");
  check(record != nullptr, "the angled datum minted its record");
  if (record == nullptr)
    return;
  const gp_Pln plane = BRepAdaptor_Surface(TopoDS::Face(record->shape), true).Plane();
  // Axis: the top edge along +x at y=-15, z=20 (canonicalized +x). Right-hand
  // rotation of +z about +x by 45 degrees -> (0, -sin45, cos45).
  const double half = std::sqrt(0.5);
  checkDirNear(plane.Axis().Direction(), 0.0, -half, half,
               "+z rotated 45 degrees about the canonicalized +x axis");
  checkNear(plane.Location().X(), 0.0, 1e-9, "anchor x = axis point closest to the origin");
  checkNear(plane.Location().Y(), -15.0, 1e-9, "anchor y on the axis line");
  checkNear(plane.Location().Z(), 20.0, 1e-9, "anchor z on the axis line");
}

void DatumPlaneAngledOffPlaneAxis() {
  std::printf("datum_plane angled refuses an axis off the base plane:\n");
  const Refusal refusal = RunExpectingRefusal(
      nlohmann::json::array(
          {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
           DatumPlaneOperation(
               kDatumPlaneOp,
               {{"mode", "angled"},
                {"angle", 45.0},
                {"base",
                 AstRef(Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})}))},
                {"axis", AstRef(Query("edges", {SrcOp(kBoxOp)},
                                      {Filter("at", {ArgPoint(0.0, -15.0, 0.0)})}))}})}),
      true);
  check(refusal.kind == "operation" && refusal.code == "INVALID_REQUEST" &&
            refusal.details.value("datumCode", "") == "E_DATUM_INVALID_REFERENCE",
        "a bottom edge under a top base -> E_DATUM_INVALID_REFERENCE");
  checkNear(refusal.details.value("distanceMm", 0.0), 20.0, 1e-6,
            "the refusal reports the 20 mm axis-to-plane distance");
  check(refusal.operationId == kDatumPlaneOp, "the refusal is attributed to the datum op");
}

void DatumPlaneMidplaneMode() {
  std::printf("datum_plane midplane bisects two parallel faces:\n");
  RegistryRun run;
  EvaluateInto(
      run,
      nlohmann::json::array(
          {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
           DatumPlaneOperation(
               kDatumPlaneOp,
               {{"mode", "midplane"},
                {"a", AstRef(Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})}))},
                {"b", AstRef(Query("faces", {SrcOp(kBoxOp)},
                                   {Filter("role", {ArgIdent("bottom")})}))}})}));
  const aeth::NamingRecord* record = DatumRecord(run.registry, kDatumPlaneOp, "plane");
  check(record != nullptr, "the midplane datum minted its record");
  if (record == nullptr)
    return;
  const gp_Pln plane = BRepAdaptor_Surface(TopoDS::Face(record->shape), true).Plane();
  checkNear(plane.Location().Z(), 10.0, 1e-9, "the midplane sits at z = 10");
  // a's outward normal is +z; §2.5 canonicalization keeps it +z.
  checkDirNear(plane.Axis().Direction(), 0.0, 0.0, 1.0, "normal = a's outward normal, canonical");
}

void DatumPlaneMidplaneNotParallel() {
  std::printf("datum_plane midplane refuses non-parallel faces:\n");
  const Refusal refusal = RunExpectingRefusal(
      nlohmann::json::array(
          {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
           DatumPlaneOperation(
               kDatumPlaneOp,
               {{"mode", "midplane"},
                {"a", AstRef(Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("top")})}))},
                {"b", AstRef(Query("faces", {SrcOp(kBoxOp)},
                                   {Filter("normal", {ArgDirAxis(1, "x")})}))}})}),
      true);
  check(refusal.kind == "operation" &&
            refusal.details.value("datumCode", "") == "E_DATUM_INVALID_REFERENCE",
        "perpendicular faces -> E_DATUM_INVALID_REFERENCE");
  checkNear(refusal.details.value("angleOffDeg", 0.0), 90.0, 1e-6,
            "the refusal reports the 90 degree misalignment");
}

void DatumPlaneNonPlanarBase() {
  std::printf("datum_plane refuses a non-planar base face:\n");
  const Refusal refusal = RunExpectingRefusal(
      nlohmann::json::array(
          {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
           HoleOperation(kHoleOp, kBoxOp, 0.0, 0.0, 20.0, 5.0),
           DatumPlaneOperation(kDatumPlaneOp, {{"mode", "offset"},
                                               {"offset", 5.0},
                                               {"base", AstRef(Query("faces", {SrcOp(kHoleOp)},
                                                                     {Filter("cylindrical")}))}})}),
      true);
  check(refusal.kind == "operation" && refusal.code == "INVALID_REQUEST" &&
            refusal.details.value("datumCode", "") == "E_DATUM_INVALID_REFERENCE",
        "a cylindrical bore wall as base -> E_DATUM_INVALID_REFERENCE");
  check(refusal.details.value("actualSurface", "") == "cylinder",
        "the refusal reports the actual surface class");
}

void DatumPlaneSelectorRefusals() {
  std::printf("datum_plane surfaces E_SEL_EMPTY / E_SEL_AMBIGUOUS from its slot:\n");
  const nlohmann::json box =
      BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20);
  const Refusal empty = RunExpectingRefusal(
      nlohmann::json::array(
          {box, DatumPlaneOperation(
                    kDatumPlaneOp,
                    {{"mode", "offset"},
                     {"offset", 5.0},
                     {"base", AstRef(Query("faces", {SrcOp(kBoxOp)}, {Filter("cylindrical")}))}})}),
      true);
  check(empty.kind == "selector" && empty.selectorCode == "E_SEL_EMPTY" &&
            empty.operationId == kDatumPlaneOp,
        "an empty base match -> E_SEL_EMPTY attributed to the datum");
  const Refusal ambiguous = RunExpectingRefusal(
      nlohmann::json::array(
          {box,
           DatumPlaneOperation(kDatumPlaneOp,
                               {{"mode", "offset"},
                                {"offset", 5.0},
                                {"base", AstRef(Query("faces", {SrcOp(kBoxOp)},
                                                      {Filter("role", {ArgIdent("side")})}))}})}),
      true);
  check(ambiguous.kind == "selector" && ambiguous.selectorCode == "E_SEL_AMBIGUOUS",
        "four side faces on a `one` slot -> E_SEL_AMBIGUOUS, never a guess");
}

void DatumPlaneTransportAndRegistryGuards() {
  std::printf("datum_plane refuses persisted-form refs and registry-less evaluation:\n");
  const nlohmann::json box =
      BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20);
  const nlohmann::json persistedForm = nlohmann::json::array(
      {box, DatumPlaneOperation(kDatumPlaneOp, {{"mode", "offset"},
                                                {"offset", 5.0},
                                                {"base", {{"query", "faces(op(x)).role(top)"}}}})});
  const Refusal persisted = RunExpectingRefusal(persistedForm, true);
  check(persisted.kind == "operation" && persisted.code == "INVALID_REQUEST" &&
            Contains(persisted.message, "persisted query form"),
        "a persisted-form base slot -> INVALID_REQUEST (transport guard)");
  const Refusal noRegistry = RunExpectingRefusal(persistedForm, false);
  check(noRegistry.kind == "operation" && noRegistry.code == "UNSUPPORTED_OPERATION" &&
            noRegistry.operationId == kDatumPlaneOp && Contains(noRegistry.message, "datum_plane"),
        "registry-less evaluation -> attributed UNSUPPORTED_OPERATION naming datum_plane");
}

// --- Datum axis --------------------------------------------------------------

void DatumAxisTwoPoints() {
  std::printf("datum_axis twoPoints preserves the a->b sense:\n");
  RegistryRun run;
  EvaluateInto(run,
               nlohmann::json::array(
                   {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
                    DatumAxisOperation(
                        kDatumAxisOp,
                        {{"mode", "twoPoints"},
                         {"a", AstRef(Query("vertices", {SrcOp(kBoxOp)},
                                            {Filter("at", {ArgPoint(-20.0, -15.0, 20.0)})}))},
                         {"b", AstRef(Query("vertices", {SrcOp(kBoxOp)},
                                            {Filter("at", {ArgPoint(-20.0, -15.0, 0.0)})}))}})}));
  const aeth::NamingRecord* record = DatumRecord(run.registry, kDatumAxisOp, "axis");
  check(record != nullptr && record->live && record->kind == 'e' && record->role == "axis",
        "t:<opId>/axis/0 is a live edge-kinded record");
  if (record == nullptr)
    return;
  const BRepAdaptor_Curve curve(TopoDS::Edge(record->shape));
  check(curve.GetType() == GeomAbs_Line, "the backing shape is a linear edge");
  const gp_Lin line = curve.Line();
  // a is the TOP vertex, b the BOTTOM one: the sense is a->b = -z, and the
  // §2.5 canonicalization flip is deliberately NOT applied (user intent).
  checkDirNear(line.Direction(), 0.0, 0.0, -1.0, "direction a->b (-z) is preserved, no flip");
  checkNear(line.Location().X(), -20.0, 1e-9, "anchor = pa (x)");
  checkNear(line.Location().Z(), 20.0, 1e-9, "anchor = pa (z)");
}

void DatumAxisCoincidentPoints() {
  std::printf("datum_axis twoPoints refuses coincident points:\n");
  const nlohmann::json sameVertex =
      AstRef(Query("vertices", {SrcOp(kBoxOp)}, {Filter("at", {ArgPoint(-20.0, -15.0, 0.0)})}));
  const Refusal refusal = RunExpectingRefusal(
      nlohmann::json::array(
          {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
           DatumAxisOperation(kDatumAxisOp,
                              {{"mode", "twoPoints"}, {"a", sameVertex}, {"b", sameVertex}})}),
      true);
  check(refusal.kind == "operation" &&
            refusal.details.value("datumCode", "") == "E_DATUM_INVALID_REFERENCE" &&
            refusal.details.value("reason", "") == "coincident-points",
        "the same vertex twice -> E_DATUM_INVALID_REFERENCE / coincident-points");
}

void DatumAxisFaceNormal() {
  std::printf("datum_axis faceNormal projects the position onto the face plane:\n");
  RegistryRun run;
  EvaluateInto(
      run,
      nlohmann::json::array(
          {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
           DatumAxisOperation(kDatumAxisOp,
                              {{"mode", "faceNormal"},
                               {"position", {5.0, 7.0, 99.0}},
                               {"face", AstRef(Query("faces", {SrcOp(kBoxOp)},
                                                     {Filter("role", {ArgIdent("top")})}))}})}));
  const aeth::NamingRecord* record = DatumRecord(run.registry, kDatumAxisOp, "axis");
  check(record != nullptr, "the face-normal datum minted its record");
  if (record == nullptr)
    return;
  const gp_Lin line = BRepAdaptor_Curve(TopoDS::Edge(record->shape)).Line();
  checkDirNear(line.Direction(), 0.0, 0.0, 1.0, "direction = the face's outward normal");
  checkNear(line.Location().X(), 5.0, 1e-9, "anchor x = position x");
  checkNear(line.Location().Y(), 7.0, 1e-9, "anchor y = position y");
  checkNear(line.Location().Z(), 20.0, 1e-9, "anchor z projected onto the face plane");
}

void DatumAxisFaceNormalNonPlanar() {
  std::printf("datum_axis faceNormal refuses a non-planar face:\n");
  const Refusal refusal = RunExpectingRefusal(
      nlohmann::json::array(
          {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
           HoleOperation(kHoleOp, kBoxOp, 0.0, 0.0, 20.0, 5.0),
           DatumAxisOperation(kDatumAxisOp, {{"mode", "faceNormal"},
                                             {"position", {0.0, 0.0, 0.0}},
                                             {"face", AstRef(Query("faces", {SrcOp(kHoleOp)},
                                                                   {Filter("cylindrical")}))}})}),
      true);
  check(refusal.kind == "operation" && refusal.details.value("reason", "") == "not-planar",
        "the bore wall under faceNormal -> E_DATUM_INVALID_REFERENCE / not-planar");
}

void DatumAxisCylinderAxis() {
  std::printf("datum_axis cylinderAxis takes the bore's canonicalized rotation axis:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array(
                        {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
                         HoleOperation(kHoleOp, kBoxOp, 6.0, -3.0, 20.0, 4.0),
                         DatumAxisOperation(kDatumAxisOp,
                                            {{"mode", "cylinderAxis"},
                                             {"face", AstRef(Query("faces", {SrcOp(kHoleOp)},
                                                                   {Filter("cylindrical")}))}})}));
  const aeth::NamingRecord* record = DatumRecord(run.registry, kDatumAxisOp, "axis");
  check(record != nullptr, "the cylinder-axis datum minted its record");
  if (record == nullptr)
    return;
  const gp_Lin line = BRepAdaptor_Curve(TopoDS::Edge(record->shape)).Line();
  // The hole was drilled along -z; §2.5 canonicalization flips the reported
  // axis to +z. The anchor is the axis point closest to the world origin.
  checkDirNear(line.Direction(), 0.0, 0.0, 1.0, "the bore axis canonicalizes to +z");
  checkNear(line.Location().X(), 6.0, 1e-9, "anchor x = bore centre x");
  checkNear(line.Location().Y(), -3.0, 1e-9, "anchor y = bore centre y");
  checkNear(line.Location().Z(), 0.0, 1e-9, "anchor z = closest point to the origin");
}

void DatumAxisNotRotational() {
  std::printf("datum_axis cylinderAxis refuses a planar face:\n");
  const Refusal refusal = RunExpectingRefusal(
      nlohmann::json::array(
          {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
           DatumAxisOperation(kDatumAxisOp,
                              {{"mode", "cylinderAxis"},
                               {"face", AstRef(Query("faces", {SrcOp(kBoxOp)},
                                                     {Filter("role", {ArgIdent("top")})}))}})}),
      true);
  check(refusal.kind == "operation" && refusal.details.value("reason", "") == "not-rotational",
        "a planar face under cylinderAxis -> E_DATUM_INVALID_REFERENCE / not-rotational");
}

// --- Cross-cutting -----------------------------------------------------------

/// CAP-014 REPLACES the wave-1 deferral this function used to pin. A datum
/// plane now RESOLVES under a `faces` head and a datum axis under `edges`,
/// because nothing downstream could reference a datum while they refused.
///
/// The resolved entity is deliberately BODY-LESS: a datum has no visible body
/// by construction. That is legal inside ref-slot resolution and illegal on the
/// `query` wire, where `resolvedEntitySchema` requires `bodyId` — the seam the
/// packet names, enforced in server.cpp and pinned by the wire test below.
void EvaluatorResolvesDatumEntities() {
  std::printf("the selector evaluator resolves datum entities (CAP-014):\n");
  RegistryRun run;
  EvaluateInto(
      run,
      nlohmann::json::array(
          {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
           DatumPlaneOperation(kDatumPlaneOp,
                               {{"mode", "offset"},
                                {"offset", 5.0},
                                {"base", AstRef(Query("faces", {SrcOp(kBoxOp)},
                                                      {Filter("role", {ArgIdent("top")})}))}}),
           DatumAxisOperation(kDatumAxisOp,
                              {{"mode", "faceNormal"},
                               {"position", {5.0, 7.0, 99.0}},
                               {"face", AstRef(Query("faces", {SrcOp(kBoxOp)},
                                                     {Filter("role", {ArgIdent("top")})}))}})}));

  const aeth::QueryOutcome plane = aeth::EvaluateQuery(Query("faces", {SrcOp(kDatumPlaneOp)}),
                                                       run.bodies, run.registry, run.cancelled);
  check(plane.entities.size() == 1 && plane.entities.front().kind == 'f',
        "faces(op(<datumPlane>)) resolves exactly ONE face entity");
  check(plane.entities.size() == 1 && plane.entities.front().bodyId.empty(),
        "the datum plane entity is BODY-LESS by construction");
  check(plane.entities.size() == 1 &&
            plane.entities.front().token == "t:" + kDatumPlaneOp + "/plane/0",
        "it carries the datum's own synthetic token");

  const aeth::QueryOutcome axis = aeth::EvaluateQuery(Query("edges", {SrcOp(kDatumAxisOp)}),
                                                      run.bodies, run.registry, run.cancelled);
  check(axis.entities.size() == 1 && axis.entities.front().kind == 'e',
        "edges(op(<datumAxis>)) resolves exactly ONE edge entity");

  // The TOKEN source is what a RECORDED datum reference re-resolves through on
  // replay, so a saved datum-mirror reopening depends on this arm specifically.
  const aeth::QueryOutcome byToken =
      aeth::EvaluateQuery(Query("faces", {SrcToken("t:" + kDatumPlaneOp + "/plane/0")}), run.bodies,
                          run.registry, run.cancelled);
  check(byToken.entities.size() == 1,
        "the same datum plane resolves through the TOKEN source (replay path)");
}

// Bit-for-bit probe equality — the replay-cache differential comparator
// (replay_cache_test.cpp ProbesEqual), duplicated here so the shell extension
// of the warm==cold contract needs no cross-test linkage.
bool ProbesEqual(const aeth::ShapeProbes& a, const aeth::ShapeProbes& b) {
  if (a.valid != b.valid || a.volume != b.volume || a.surfaceArea != b.surfaceArea)
    return false;
  for (int axis = 0; axis < 3; ++axis) {
    if (a.centerOfMass[axis] != b.centerOfMass[axis])
      return false;
  }
  for (int bound = 0; bound < 6; ++bound) {
    if (a.bounds[bound] != b.bounds[bound])
      return false;
  }
  return a.solidCount == b.solidCount && a.shellCount == b.shellCount &&
         a.faceCount == b.faceCount && a.edgeCount == b.edgeCount && a.vertexCount == b.vertexCount;
}

/// Sorted multiset of every element NAME on a body — the durable naming
/// channel, independent of the epoch-local positional token pairing.
std::vector<std::string> SortedNames(const aeth::ElementNameBook& book, const TopoDS_Shape& shape) {
  std::vector<std::string> names;
  for (const nlohmann::json& entry : aeth::ProjectElementNames(book, shape, 7, 0))
    names.push_back(entry.at("name").get<std::string>());
  std::sort(names.begin(), names.end());
  return names;
}

void ShellReplayCacheDifferential() {
  std::printf("the replay cache covers shell (Wave 2.1 gate, per-evaluator warm==seed):\n");
  const nlohmann::json box =
      BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 60, 40, 20);
  const nlohmann::json program =
      nlohmann::json::array({box, ShellOperation(kShellOp, kBoxOp, 1.6, "inward")});
  std::atomic_bool cancelled{false};

  // The cache's user-facing contract: re-evaluating the UNCHANGED document
  // warm reproduces what the same document produced when this evaluator ran
  // it cold — bit-for-bit probes and an identical element-name projection.
  aeth::DocumentEvaluator warmEvaluator;
  const aeth::DocumentEvaluator::Result seeded = warmEvaluator.Evaluate(
      program, "catalog-wave1-doc", "test-geom", /*includeElementNames=*/true,
      /*reuseEnabled=*/true, cancelled);
  check(seeded.executedOperationCount == 2, "the seeding evaluation executes both operations");
  const aeth::DocumentEvaluator::Result warm = warmEvaluator.Evaluate(
      program, "catalog-wave1-doc", "test-geom", true, /*reuseEnabled=*/true, cancelled);
  check(warm.executedOperationCount == 0, "an unchanged re-eval restores the full prefix");
  check(warm.bodies.size() == 1 && seeded.bodies.size() == 1 &&
            warm.bodies.front().bodyId == seeded.bodies.front().bodyId &&
            ProbesEqual(warm.bodies.front().probes, seeded.bodies.front().probes),
        "warm probes are bit-identical to the seeding evaluation");
  check(warm.elementNames.has_value() && seeded.elementNames.has_value() &&
            aeth::ProjectElementNames(*warm.elementNames, warm.bodies.front().shape, 7, 0) ==
                aeth::ProjectElementNames(*seeded.elementNames, seeded.bodies.front().shape, 7, 0),
        "warm element names project identically to the seeding evaluation");

  // Cross-evaluator determinism holds at the wire-quantization grain: an
  // independent cold evaluation reproduces identity, counts, volume, area,
  // and the durable NAME SET exactly. FINDING (recorded in the design note):
  // the offset stage iterates pointer-hashed NCollection maps inside
  // BRepOffset, so bounds/centroid wobble at ulp level ACROSS evaluations —
  // the landed `offset` op shares this property and the bitwise differential
  // corpus has never covered it; token pairing is epoch-local positional
  // (ADR-003) and legitimately follows each instance's enumeration order.
  aeth::DocumentEvaluator coldEvaluator;
  const aeth::DocumentEvaluator::Result cold = coldEvaluator.Evaluate(
      program, "catalog-wave1-doc", "test-geom", true, /*reuseEnabled=*/false, cancelled);
  check(cold.bodies.size() == 1 && cold.bodies.front().bodyId == warm.bodies.front().bodyId &&
            cold.bodies.front().operationId == warm.bodies.front().operationId,
        "an independent cold evaluation reproduces the body identity");
  const aeth::ShapeProbes& coldProbes = cold.bodies.front().probes;
  const aeth::ShapeProbes& warmProbes = warm.bodies.front().probes;
  check(coldProbes.solidCount == warmProbes.solidCount &&
            coldProbes.shellCount == warmProbes.shellCount &&
            coldProbes.faceCount == warmProbes.faceCount &&
            coldProbes.edgeCount == warmProbes.edgeCount &&
            coldProbes.vertexCount == warmProbes.vertexCount,
        "cold topology counts match warm exactly");
  checkNear(coldProbes.volume, warmProbes.volume, 1e-9, "cold volume matches warm");
  checkNear(coldProbes.surfaceArea, warmProbes.surfaceArea, 1e-9, "cold area matches warm");
  bool boundsClose = true;
  for (int bound = 0; bound < 6; ++bound)
    boundsClose =
        boundsClose && std::abs(coldProbes.bounds[bound] - warmProbes.bounds[bound]) <= 1e-6;
  check(boundsClose, "cold bounds match warm within 1e-6 mm");
  check(cold.elementNames.has_value() &&
            SortedNames(*cold.elementNames, cold.bodies.front().shape) ==
                SortedNames(*warm.elementNames, warm.bodies.front().shape),
        "the durable element-name SET is identical across independent evaluations");

  // A thickness edit re-executes ONLY the shell tail on the restored box.
  const nlohmann::json edited =
      nlohmann::json::array({box, ShellOperation(kShellOp, kBoxOp, 2.0, "inward")});
  const aeth::DocumentEvaluator::Result tail = warmEvaluator.Evaluate(
      edited, "catalog-wave1-doc", "test-geom", true, /*reuseEnabled=*/true, cancelled);
  check(tail.executedOperationCount == 1, "a thickness edit re-executes only the shell tail");
  checkNear(tail.bodies.front().probes.volume, 48000.0 - 56.0 * 36.0 * 16.0, 1e-3,
            "the tail re-execution produces the edited hollow's analytic volume");
}

void RegistryReplayDeterminism() {
  std::printf("independent registry evaluations mint identical record streams:\n");
  const nlohmann::json program = nlohmann::json::array(
      {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 60, 40, 20),
       DatumPlaneOperation(kDatumPlaneOp,
                           {{"mode", "offset"},
                            {"offset", 5.0},
                            {"base", AstRef(Query("faces", {SrcOp(kBoxOp)},
                                                  {Filter("role", {ArgIdent("top")})}))}}),
       DatumAxisOperation(kDatumAxisOp,
                          {{"mode", "twoPoints"},
                           {"a", AstRef(Query("vertices", {SrcOp(kBoxOp)},
                                              {Filter("at", {ArgPoint(-30.0, -20.0, 0.0)})}))},
                           {"b", AstRef(Query("vertices", {SrcOp(kBoxOp)},
                                              {Filter("at", {ArgPoint(30.0, 20.0, 20.0)})}))}}),
       ShellOperation(kShellOp, kBoxOp, 1.6, "inward")});
  RegistryRun first;
  EvaluateInto(first, program);
  RegistryRun second;
  EvaluateInto(second, program);
  check(first.registry.RecordCount() == second.registry.RecordCount(),
        "both evaluations mint the same record count");
  bool identical = first.registry.RecordCount() == second.registry.RecordCount();
  for (std::size_t index = 0; identical && index < first.registry.RecordCount(); ++index) {
    const aeth::NamingRecord& a = first.registry.RecordAt(index);
    const aeth::NamingRecord& b = second.registry.RecordAt(index);
    identical = a.token == b.token && a.minter == b.minter && a.role == b.role &&
                a.kind == b.kind && a.lineageName == b.lineageName &&
                a.normalizedLineageName == b.normalizedLineageName && a.live == b.live &&
                a.nameCollision == b.nameCollision && a.orderTie == b.orderTie &&
                a.ancestors == b.ancestors;
  }
  check(identical, "record streams are field-for-field identical (replay determinism)");
}

} // namespace

int main() {
  try {
    ShellClosedHollowInward();
    ShellClosedHollowOutward();
    ShellNamesEveryEntity();
    ShellRegistryHarvest();
    ShellFeasibilityBound();
    ShellDirectionFailsClosed();
    ShellOpenFacesExecutes();
    DatumPlaneOffsetMode();
    DatumPlaneOffsetSideFace();
    DatumPlaneAngledMode();
    DatumPlaneAngledOffPlaneAxis();
    DatumPlaneMidplaneMode();
    DatumPlaneMidplaneNotParallel();
    DatumPlaneNonPlanarBase();
    DatumPlaneSelectorRefusals();
    DatumPlaneTransportAndRegistryGuards();
    DatumAxisTwoPoints();
    DatumAxisCoincidentPoints();
    DatumAxisFaceNormal();
    DatumAxisFaceNormalNonPlanar();
    DatumAxisCylinderAxis();
    DatumAxisNotRotational();
    EvaluatorResolvesDatumEntities();
    ShellReplayCacheDifferential();
    RegistryReplayDeterminism();
  } catch (const std::exception& error) {
    std::printf("FATAL: uncaught exception: %s\n", error.what());
    return 1;
  }
  if (g_failures == 0) {
    std::printf("\nALL CATALOG WAVE 1 TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d CATALOG WAVE 1 CHECK(S) FAILED\n", g_failures);
  return 1;
}
