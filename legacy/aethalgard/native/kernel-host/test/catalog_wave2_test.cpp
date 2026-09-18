// Native integration tests for the catalog wave-2 executors — mirror,
// pattern_linear, pattern_circular (plan 01-geometry-core/04 `mirror`,
// `pattern-linear`, `pattern-circular`; docs/design/2026-07-19-native-catalog-
// wave1.md line 285, designed in the shell mold). They drive the REAL
// EvaluateOperations path (bare book + registry-threaded) and pin:
//
//   1. mirror merge:false — a NEW body from the reflected copy while the source
//      stays live; the copy's bbox/volume reflect correctly and the registry
//      mints `mirrored*` records;
//   2. mirror merge:true — the copy fused into the (consumed) source as one
//      connected solid; the source's faces survive `modified`, the copy's
//      re-mint `mirrored`;
//   3. the resolve-time refusals: E_MIRROR_PLANE_INVALID (curved plane),
//      E_SEL_EMPTY / E_SEL_AMBIGUOUS from the slot, the persisted-form and
//      registry-less guards;
//   4. pattern_linear — a touching-instance bar (combined extent + volume) and
//      a subtract of instanced tools from a target;
//   5. pattern_circular — a ring of instances around a resolved axis edge (one
//      connected solid, symmetric extent), plus E_PATTERN_AXIS_INVALID;
//   6. registry replay determinism across independent evaluations.
#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstddef>
#include <cstdio>
#include <initializer_list>
#include <stdexcept>
#include <string>
#include <vector>

#include <nlohmann/json.hpp>

#include "element_names.hpp"
#include "geometry.hpp"
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

const std::string kBoxOp = "aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa";
const std::string kSeedOp = "abababab-2222-4a22-8a22-abababababab";
const std::string kTargetOp = "acacacac-7777-4a77-8a77-acacacacacac";
const std::string kHoleOp = "bbbbbbbb-3333-4b33-8b33-bbbbbbbbbbbb";
const std::string kMirrorOp = "cccccccc-4444-4c44-8c44-cccccccccccc";
const std::string kPatternOp = "dddddddd-5555-4d55-8d55-dddddddddddd";

// --- Operation builders ------------------------------------------------------

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

// --- AST builders (the wire form the parser emits) ---------------------------

nlohmann::json AsArray(std::initializer_list<nlohmann::json> items) {
  nlohmann::json array = nlohmann::json::array();
  for (const nlohmann::json& item : items)
    array.push_back(item);
  return array;
}

nlohmann::json ArgIdent(const std::string& value) { return {{"arg", "ident"}, {"value", value}}; }

nlohmann::json ArgDirAxis(const int sign, const std::string& axis) {
  return {{"arg", "direction"}, {"value", {{"form", "axis"}, {"sign", sign}, {"axis", axis}}}};
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

nlohmann::json MirrorOperation(const std::string& id, const std::string& source,
                               const nlohmann::json& planeRef, const bool merge) {
  return {
      {"id", id},
      {"type", "mirror"},
      {"outputBodyId", "00000000-0000-4000-8000-0000000000a1"},
      {"parameters", {{"sourceOperationId", source}, {"plane", planeRef}, {"merge", merge}}},
  };
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

struct Refusal final {
  std::string kind;
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

std::size_t CountRecords(const aeth::NamingRegistry& registry, const std::string& minter,
                         const std::string& role, const char kind, const bool liveOnly) {
  std::size_t total = 0;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (record.minter == minter && record.role == role && record.kind == kind &&
        (!liveOnly || record.live))
      total += 1;
  }
  return total;
}

const aeth::EvaluatedBody* BodyOf(const std::vector<aeth::EvaluatedBody>& bodies,
                                  const std::string& operationId) {
  for (const aeth::EvaluatedBody& body : bodies) {
    if (body.operationId == operationId)
      return &body;
  }
  return nullptr;
}

// --- Mirror ------------------------------------------------------------------

void MirrorMergeFalseNewBody() {
  std::printf("mirror merge:false produces a new reflected body, source stays live:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array(
                        {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 20, 16, 12),
                         MirrorOperation(kMirrorOp, kBoxOp,
                                         AstRef(Query("faces", {SrcOp(kBoxOp)},
                                                      {Filter("normal", {ArgDirAxis(1, "x")})})),
                                         false)}));
  check(run.bodies.size() == 2, "the source stays live -> two visible bodies");
  const aeth::EvaluatedBody* mirror = BodyOf(run.bodies, kMirrorOp);
  const aeth::EvaluatedBody* box = BodyOf(run.bodies, kBoxOp);
  check(box != nullptr, "the source box is still a visible body");
  check(mirror != nullptr, "the mirror copy is a visible body");
  if (mirror == nullptr)
    return;
  const aeth::ShapeProbes& probes = mirror->probes;
  check(probes.valid && probes.solidCount == 1, "the reflected copy is one valid solid");
  checkNear(probes.volume, 20.0 * 16.0 * 12.0, 1e-6, "the copy keeps the source volume (3840)");
  // Source spans x in [-10,10]; the +x face is x=10. The reflection lands the
  // copy at x in [10,30].
  checkNear(probes.bounds[0], 10.0, 1e-6, "the copy's xmin sits at the mirror plane (x=10)");
  checkNear(probes.bounds[3], 30.0, 1e-6, "the copy's xmax is the reflected far side (x=30)");
  checkNear(probes.bounds[1], -8.0, 1e-6, "the copy keeps ymin");
  checkNear(probes.bounds[5], 12.0, 1e-6, "the copy keeps zmax");
  check(CountRecords(run.registry, kMirrorOp, "mirrored", 'f', true) == 6,
        "the copy mints 6 live `mirrored` face records under the mirror op");
  check(CountRecords(run.registry, kBoxOp, "top", 'f', true) +
                CountRecords(run.registry, kBoxOp, "bottom", 'f', true) +
                CountRecords(run.registry, kBoxOp, "side", 'f', true) ==
            6,
        "the source's own 6 face records stay live (it was not consumed)");
}

/// CAP-014: mirror across a DATUM PLANE. This is the capability's whole point —
/// before datum entities resolved, nothing downstream could reference a datum,
/// so `datum_plane` was an operation that executed and could never be used.
///
/// The number is the assertion, and it is what distinguishes a datum mirror
/// from a face mirror: the datum sits 5 mm OFF the +x face, so the copy lands
/// 10 mm further out than the face-mirrored copy of `MirrorMergeFalseNewBody`.
/// A datum silently falling back to its base face would land the copy at x=10
/// and pass every check except this one.
void MirrorAcrossDatumPlane() {
  std::printf("mirror consumes a DATUM PLANE (CAP-014):\n");
  const std::string kDatumOp = "dddddddd-5555-4d55-8d55-dddddddddddd";
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array(
                        {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 20, 16, 12),
                         // A datum plane 5 mm outboard of the box's +x face (which is x=10).
                         {{"id", kDatumOp},
                          {"type", "datum_plane"},
                          {"parameters",
                           {{"mode", "offset"},
                            {"offset", 5.0},
                            {"base", AstRef(Query("faces", {SrcOp(kBoxOp)},
                                                  {Filter("normal", {ArgDirAxis(1, "x")})}))}}}},
                         MirrorOperation(kMirrorOp, kBoxOp,
                                         AstRef(Query("faces", {SrcOp(kDatumOp)})), false)}));

  check(run.bodies.size() == 2, "the datum produces no body; source + copy are the two");
  const aeth::EvaluatedBody* mirror = BodyOf(run.bodies, kMirrorOp);
  check(mirror != nullptr, "the mirror across the datum produced a body");
  if (mirror == nullptr)
    return;
  const aeth::ShapeProbes& probes = mirror->probes;
  check(probes.valid && probes.solidCount == 1, "the datum-reflected copy is one valid solid");
  checkNear(probes.volume, 20.0 * 16.0 * 12.0, 1e-6, "the copy keeps the source volume (3840)");
  // Source spans x in [-10,10]; the datum is at x=15. Reflecting [-10,10]
  // through x=15 gives [20,40] — NOT the [10,30] a face mirror would give.
  checkNear(probes.bounds[0], 20.0, 1e-6, "xmin = 20: reflected through the DATUM, not the face");
  checkNear(probes.bounds[3], 40.0, 1e-6, "xmax = 40");
  check(CountRecords(run.registry, kMirrorOp, "mirrored", 'f', true) == 6,
        "the datum-mirrored copy mints its 6 live `mirrored` face records");
}

void MirrorMergeTrueFuses() {
  std::printf("mirror merge:true fuses the copy into the consumed source:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array(
                        {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 20, 16, 12),
                         MirrorOperation(kMirrorOp, kBoxOp,
                                         AstRef(Query("faces", {SrcOp(kBoxOp)},
                                                      {Filter("normal", {ArgDirAxis(1, "x")})})),
                                         true)}));
  check(run.bodies.size() == 1 && run.bodies.front().operationId == kMirrorOp,
        "the merge consumes the source -> one visible mirror body");
  if (run.bodies.size() != 1)
    return;
  const aeth::ShapeProbes& probes = run.bodies.front().probes;
  check(probes.valid && probes.solidCount == 1, "the merged mirror is one valid solid");
  // Two 3840 boxes meeting at x=10 -> a bar x in [-10,30], no overlap.
  checkNear(probes.volume, 2.0 * 20.0 * 16.0 * 12.0, 1e-6, "the merged volume is 2x the source");
  checkNear(probes.bounds[0], -10.0, 1e-6, "the bar keeps the source xmin (-10)");
  checkNear(probes.bounds[3], 30.0, 1e-6, "the bar extends to the reflected xmax (30)");
  check(CountRecords(run.registry, kMirrorOp, "mirrored", 'f', true) >= 1,
        "the copy contributes `mirrored` face records");
  check(CountRecords(run.registry, kMirrorOp, "modified", 'f', true) >= 1,
        "the source's surviving faces carry `modified` records");
}

void MirrorPlaneInvalid() {
  std::printf("mirror across a curved face -> E_MIRROR_PLANE_INVALID:\n");
  const Refusal refusal = RunExpectingRefusal(
      nlohmann::json::array(
          {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20),
           HoleOperation(kHoleOp, kBoxOp, 0.0, 0.0, 20.0, 5.0),
           MirrorOperation(kMirrorOp, kHoleOp,
                           AstRef(Query("faces", {SrcOp(kHoleOp)}, {Filter("cylindrical")})),
                           false)}),
      true);
  check(refusal.kind == "operation" && refusal.code == "INVALID_REQUEST" &&
            refusal.details.value("mirrorCode", "") == "E_MIRROR_PLANE_INVALID" &&
            refusal.operationId == kMirrorOp,
        "a cylindrical bore wall as the mirror plane -> E_MIRROR_PLANE_INVALID");
}

void MirrorSelectorRefusals() {
  std::printf("mirror surfaces E_SEL_EMPTY / E_SEL_AMBIGUOUS and the guards:\n");
  const nlohmann::json box =
      BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20);
  const Refusal empty = RunExpectingRefusal(
      nlohmann::json::array(
          {box, MirrorOperation(kMirrorOp, kBoxOp,
                                AstRef(Query("faces", {SrcOp(kBoxOp)}, {Filter("cylindrical")})),
                                false)}),
      true);
  check(empty.kind == "selector" && empty.selectorCode == "E_SEL_EMPTY" &&
            empty.operationId == kMirrorOp,
        "an empty plane match -> E_SEL_EMPTY attributed to the mirror");
  const Refusal ambiguous = RunExpectingRefusal(
      nlohmann::json::array(
          {box, MirrorOperation(
                    kMirrorOp, kBoxOp,
                    AstRef(Query("faces", {SrcOp(kBoxOp)}, {Filter("role", {ArgIdent("side")})})),
                    false)}),
      true);
  check(ambiguous.kind == "selector" && ambiguous.selectorCode == "E_SEL_AMBIGUOUS",
        "four side faces on a `one` plane slot -> E_SEL_AMBIGUOUS, never a guess");
  const Refusal persisted = RunExpectingRefusal(
      nlohmann::json::array(
          {box, MirrorOperation(
                    kMirrorOp, kBoxOp,
                    {{"query", "faces(op(x)).normal(+x)"}, {"arity", "one"}, {"onEmpty", "error"}},
                    false)}),
      true);
  check(persisted.kind == "operation" && persisted.code == "INVALID_REQUEST" &&
            Contains(persisted.message, "persisted query form"),
        "a persisted-form plane slot -> INVALID_REQUEST (transport guard)");
  const Refusal noRegistry = RunExpectingRefusal(
      nlohmann::json::array(
          {box, MirrorOperation(kMirrorOp, kBoxOp,
                                AstRef(Query("faces", {SrcOp(kBoxOp)},
                                             {Filter("normal", {ArgDirAxis(1, "x")})})),
                                false)}),
      false);
  check(noRegistry.kind == "operation" && noRegistry.code == "UNSUPPORTED_OPERATION" &&
            Contains(noRegistry.message, "mirror"),
        "mirror without a registry -> attributed UNSUPPORTED_OPERATION naming the registry");
}

// --- pattern_linear ----------------------------------------------------------

nlohmann::json PatternLinear(const std::string& id, const std::string& seed, const int count,
                             const double spacing, const nlohmann::json& direction,
                             const std::string& op = "fuseInstances",
                             const std::string& target = "") {
  nlohmann::json parameters = {{"seedOperationId", seed},
                               {"count", count},
                               {"spacing", spacing},
                               {"direction", direction},
                               {"op", op}};
  if (!target.empty())
    parameters["targetOperationId"] = target;
  return {{"id", id},
          {"type", "pattern_linear"},
          {"outputBodyId", "00000000-0000-4000-8000-0000000000b1"},
          {"parameters", std::move(parameters)}};
}

void PatternLinearBar() {
  std::printf("pattern_linear fuses a row of touching instances into one bar:\n");
  RegistryRun run;
  EvaluateInto(run, nlohmann::json::array(
                        {BoxOperation(kSeedOp, "00000000-0000-4000-8000-0000000000c1", 10, 10, 10),
                         PatternLinear(kPatternOp, kSeedOp, 4, 10.0, {1.0, 0.0, 0.0})}));
  check(run.bodies.size() == 1 && run.bodies.front().operationId == kPatternOp,
        "the seed is consumed -> one visible pattern body");
  if (run.bodies.size() != 1)
    return;
  const aeth::ShapeProbes& probes = run.bodies.front().probes;
  check(probes.valid && probes.solidCount == 1, "the four touching instances fuse to one solid");
  // Seed x in [-5,5]; four copies at x-offsets 0,10,20,30 -> bar x in [-5,35].
  checkNear(probes.volume, 4.0 * 10.0 * 10.0 * 10.0, 1e-6,
            "the combined volume is 4x the seed (touching, no overlap)");
  checkNear(probes.bounds[0], -5.0, 1e-6, "the bar starts at the seed xmin (-5)");
  checkNear(probes.bounds[3], 35.0, 1e-6, "the bar ends at the fourth instance (x=35)");
  check(CountRecords(run.registry, kPatternOp, "instance-face", 'f', true) >= 4,
        "the instances mint `instance-face` records");
}

void PatternLinearSubtract() {
  std::printf("pattern_linear subtract carves a row of instanced tools from a target:\n");
  RegistryRun run;
  // A plate to drill, and a small cylinder seed to array as through tools.
  const nlohmann::json plate =
      BoxOperation(kTargetOp, "00000000-0000-4000-8000-0000000000d1", 60, 20, 6);
  const nlohmann::json seed = {{"id", kSeedOp},
                               {"type", "create_cylinder"},
                               {"outputBodyId", "00000000-0000-4000-8000-0000000000c2"},
                               {"parameters",
                                {{"radius", 2.0},
                                 {"height", 20.0},
                                 {"placement",
                                  {{"origin", {-20.0, 0.0, -6.0}},
                                   {"zDirection", {0.0, 0.0, 1.0}},
                                   {"xDirection", {1.0, 0.0, 0.0}}}}}}};
  EvaluateInto(run, nlohmann::json::array({plate, seed,
                                           PatternLinear(kPatternOp, kSeedOp, 3, 20.0,
                                                         {1.0, 0.0, 0.0}, "subtract", kTargetOp)}));
  check(run.bodies.size() == 1 && run.bodies.front().operationId == kPatternOp,
        "the target and seed are consumed -> one drilled body");
  if (run.bodies.size() != 1)
    return;
  const aeth::ShapeProbes& probes = run.bodies.front().probes;
  check(probes.valid && probes.solidCount == 1, "the drilled plate is one valid solid");
  // Plate 60*20*6 = 7200 minus three r=2 through holes of height 6.
  const double holeVolume = 3.0 * 3.14159265358979323846 * 2.0 * 2.0 * 6.0;
  checkNear(probes.volume, 7200.0 - holeVolume, 1e-2,
            "the volume is the plate minus three cylindrical bores");
  check(CountRecords(run.registry, kTargetOp, "top", 'f', true) >= 1 ||
            CountRecords(run.registry, kTargetOp, "bottom", 'f', true) >= 1,
        "the target's own faces survive as live records");
}

// --- pattern_circular --------------------------------------------------------

nlohmann::json PatternCircular(const std::string& id, const std::string& seed, const int count,
                               const double totalAngle, const nlohmann::json& axisRef,
                               const bool rotateInstances = true,
                               const std::string& op = "fuseInstances",
                               const std::string& target = "") {
  nlohmann::json parameters = {{"seedOperationId", seed},
                               {"count", count},
                               {"totalAngle", totalAngle},
                               {"axis", axisRef},
                               {"rotateInstances", rotateInstances},
                               {"op", op}};
  if (!target.empty())
    parameters["targetOperationId"] = target;
  return {{"id", id},
          {"type", "pattern_circular"},
          {"outputBodyId", "00000000-0000-4000-8000-0000000000e1"},
          {"parameters", std::move(parameters)}};
}

void PatternCircularRing() {
  std::printf("pattern_circular arrays overlapping spheres into one connected ring:\n");
  RegistryRun run;
  // A box straddling the z-axis provides a real vertical edge (its (0,0)
  // corner) to serve as the axis; a sphere is then rung around it. The box is
  // base-centered at (2,2,-20) so it spans x,y in [0,4] and its (0,0) vertical
  // edge lies exactly on the z-axis.
  const nlohmann::json axisBox =
      BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 4, 4, 40, {2.0, 2.0, -20.0});
  const nlohmann::json seed =
      SphereOperation(kSeedOp, "00000000-0000-4000-8000-0000000000c3", 6.0, {12.0, 0.0, 0.0});
  EvaluateInto(
      run,
      nlohmann::json::array(
          {axisBox, seed,
           PatternCircular(kPatternOp, kSeedOp, 8, 360.0,
                           AstRef(Query("edges", {SrcOp(kBoxOp)},
                                        {Filter("line"), Filter("at", {ArgPoint(0.0, 0.0, 0.0)})}),
                                  "one"))}));
  check(run.bodies.size() == 2, "the axis box stays live; the ring replaces the seed");
  const aeth::EvaluatedBody* ring = BodyOf(run.bodies, kPatternOp);
  check(ring != nullptr, "the pattern ring is a visible body");
  if (ring == nullptr)
    return;
  const aeth::ShapeProbes& probes = ring->probes;
  check(probes.valid && probes.solidCount == 1, "the eight overlapping spheres fuse to one solid");
  // Spheres at radius 12, sphere radius 6 -> ring extent radius 18 in x/y.
  checkNear(probes.bounds[0], -18.0, 1e-3, "the ring xmin is -(ringR + sphereR)");
  checkNear(probes.bounds[3], 18.0, 1e-3, "the ring xmax is +(ringR + sphereR)");
  checkNear(probes.bounds[2], -6.0, 1e-3, "the ring zmin is the sphere radius below the plane");
  checkNear(probes.bounds[5], 6.0, 1e-3, "the ring zmax is the sphere radius above the plane");
  check(CountRecords(run.registry, kPatternOp, "instance-face", 'f', true) >= 8,
        "each sphere instance contributes an `instance-face` record");
}

void PatternCircularAxisInvalid() {
  std::printf("pattern_circular around a curved edge -> E_PATTERN_AXIS_INVALID:\n");
  const nlohmann::json box =
      BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 40, 30, 20);
  const nlohmann::json seed =
      SphereOperation(kSeedOp, "00000000-0000-4000-8000-0000000000c3", 5.0, {30.0, 0.0, 0.0});
  const nlohmann::json hole = HoleOperation(kHoleOp, kBoxOp, 0.0, 0.0, 20.0, 5.0);
  const Refusal refusal = RunExpectingRefusal(
      nlohmann::json::array(
          {box, hole, seed,
           PatternCircular(
               kPatternOp, kSeedOp, 6, 360.0,
               // A circular bore edge is not linear (largest() pins
               // one of the two identical rim circles deterministically).
               AstRef(Query("edges", {SrcOp(kHoleOp)}, {Filter("circle"), Filter("largest")}),
                      "one"))}),
      true);
  check(refusal.kind == "operation" && refusal.code == "INVALID_REQUEST" &&
            refusal.details.value("patternCode", "") == "E_PATTERN_AXIS_INVALID",
        "a circular bore edge as the pattern axis -> E_PATTERN_AXIS_INVALID");
}

// --- Determinism -------------------------------------------------------------

void RegistryReplayDeterminism() {
  std::printf("independent registry evaluations mint identical record streams:\n");
  const nlohmann::json program = nlohmann::json::array(
      {BoxOperation(kBoxOp, "00000000-0000-4000-8000-00000000000b", 20, 16, 12),
       MirrorOperation(
           kMirrorOp, kBoxOp,
           AstRef(Query("faces", {SrcOp(kBoxOp)}, {Filter("normal", {ArgDirAxis(1, "x")})})),
           true)});
  RegistryRun first;
  EvaluateInto(first, program);
  RegistryRun second;
  EvaluateInto(second, program);
  bool identical = first.registry.RecordCount() == second.registry.RecordCount();
  check(identical, "both evaluations mint the same record count");
  for (std::size_t index = 0; identical && index < first.registry.RecordCount(); ++index) {
    const aeth::NamingRecord& a = first.registry.RecordAt(index);
    const aeth::NamingRecord& b = second.registry.RecordAt(index);
    identical = a.token == b.token && a.minter == b.minter && a.role == b.role &&
                a.kind == b.kind && a.lineageName == b.lineageName &&
                a.normalizedLineageName == b.normalizedLineageName && a.live == b.live &&
                a.ancestors == b.ancestors;
  }
  check(identical, "record streams are field-for-field identical (replay determinism)");
}

} // namespace

int main() {
  try {
    MirrorMergeFalseNewBody();
    MirrorAcrossDatumPlane();
    MirrorMergeTrueFuses();
    MirrorPlaneInvalid();
    MirrorSelectorRefusals();
    PatternLinearBar();
    PatternLinearSubtract();
    PatternCircularRing();
    PatternCircularAxisInvalid();
    RegistryReplayDeterminism();
  } catch (const std::exception& error) {
    std::printf("FATAL: uncaught exception: %s\n", error.what());
    return 1;
  }
  if (g_failures == 0) {
    std::printf("\nALL CATALOG WAVE 2 TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d CATALOG WAVE 2 CHECK(S) FAILED\n", g_failures);
  return 1;
}
