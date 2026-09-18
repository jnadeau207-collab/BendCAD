// CAP-034: the LOCAL FACE OFFSET evaluator, driven through the REAL
// EvaluateOperations path with a registry threaded exactly as a document
// evaluation does.
//
// `LocalFaceOffsetHistoryFixtures` (naming_registry_test.cpp) pins the PIPELINE
// in isolation — prism, boolean, unify — against hand-built shapes. This gate
// pins the OPERATION: that a `face`-scoped offset reaches that pipeline through
// the executor, mints the doc-04 roles, refuses the cases doc-04 says it must,
// and leaves v1 bit-for-bit. The two are deliberately not the same test: a
// green pipeline with an unreachable evaluator is exactly the reachability gap
// this project measures.
#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdio>
#include <string>
#include <vector>

#include <nlohmann/json.hpp>

#include "geometry.hpp"
#include "naming_registry.hpp"

namespace {

int g_failures = 0;

void check(const bool condition, const std::string& label) {
  std::printf("  %s %s\n", condition ? "ok  " : "FAIL", label.c_str());
  if (!condition)
    g_failures += 1;
}

void checkNear(const double actual, const double expected, const double tolerance,
               const std::string& label) {
  const bool ok = std::abs(actual - expected) <= tolerance;
  if (ok) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s (expected %.4f, got %.4f)\n", label.c_str(), expected, actual);
    g_failures += 1;
  }
}

const char* kBoxOp = "00000000-0000-4000-8000-000000000001";
const char* kOffsetOp = "00000000-0000-4000-8000-000000000002";
const char* kOtherBoxOp = "00000000-0000-4000-8000-000000000003";

nlohmann::json BoxOperation(const char* id, const double w, const double d, const double h,
                            const double x = 0.0, const double z = 0.0) {
  return {{"id", id},
          {"type", "create_box"},
          {"outputBodyId", std::string("00000000-0000-4000-8000-0000000000b") + id[35]},
          {"parameters",
           {{"width", w},
            {"depth", d},
            {"height", h},
            {"placement",
             {{"origin", {x, 0.0, z}},
              {"zDirection", {0.0, 0.0, 1.0}},
              {"xDirection", {1.0, 0.0, 0.0}}}}}}};
}

// --- AST builders (the wire form the parser emits) ---------------------------

nlohmann::json AsArray(std::initializer_list<nlohmann::json> items) {
  nlohmann::json array = nlohmann::json::array();
  for (const nlohmann::json& item : items)
    array.push_back(item);
  return array;
}

nlohmann::json ArgAxis(const std::string& axis) { return {{"arg", "axis"}, {"value", axis}}; }

nlohmann::json ArgDirAxis(const int sign, const std::string& axis) {
  return {{"arg", "direction"}, {"value", {{"form", "axis"}, {"sign", sign}, {"axis", axis}}}};
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

/// The +Z top face of a box, the ADR-014 fixture's target.
nlohmann::json TopFaceOf(const char* opId) {
  return Query("faces", {SrcOp(opId)}, {Filter("normal", {ArgDirAxis(1, "z")})});
}

/// A face-scoped offset whose `face` slot carries the WIRE AST form, exactly as
/// `operationRefWireSchema` ships it.
nlohmann::json OffsetOperation(const double distance, const nlohmann::json& faceRef,
                               const char* target = kBoxOp) {
  return {
      {"id", kOffsetOp},
      {"type", "offset"},
      {"schemaVersion", 2},
      {"outputBodyId", "00000000-0000-4000-8000-0000000000b2"},
      {"parameters", {{"targetOperationId", target}, {"distance", distance}, {"face", faceRef}}}};
}

struct Run final {
  std::vector<aeth::EvaluatedBody> bodies;
  aeth::NamingRegistry registry;
};

std::vector<aeth::EvaluatedBody> Evaluate(const nlohmann::json& program,
                                          aeth::NamingRegistry& registry) {
  std::atomic_bool cancelled{false};
  return aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
}

struct Failure final {
  std::string kind;
  std::string code;
  std::string message;
  bool hasProbe{};
};

Failure EvaluateExpectingFailure(const nlohmann::json& program) {
  std::atomic_bool cancelled{false};
  aeth::NamingRegistry registry;
  try {
    aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
  } catch (const aeth::OperationFailure& error) {
    std::string code;
    if (error.Details().contains("code"))
      code = error.Details().at("code").get<std::string>();
    return {"operation", code, error.what(), error.Details().contains("feasibilityProbe")};
  } catch (const aeth::SelectorFailure& error) {
    return {"selector", error.SelectorCode(), error.what()};
  } catch (const std::exception& error) {
    return {"other", "", error.what()};
  }
  return {"none", "", ""};
}

std::size_t CountRole(const aeth::NamingRegistry& registry, const std::string& role,
                      const char kind) {
  std::size_t count = 0;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (record.live && record.minter == kOffsetOp && record.role == role && record.kind == kind)
      count += 1;
  }
  return count;
}

/// ADR-014 §2's measured table, now asserted through the EXECUTOR rather than a
/// hand-built pipeline. 90x64x36, the +Z top face, +-5 mm.
void OutwardAndInwardMatchTheAdrTable() {
  std::printf("the ruled pipeline, through the real executor (ADR-014 table):\n");
  struct Case final {
    double distance;
    double volume;
    const char* label;
  };
  for (const Case& testCase : {Case{5.0, 236160.0, "+5 outward (90x64x41)"},
                               Case{-5.0, 178560.0, "-5 inward (90x64x31)"}}) {
    aeth::NamingRegistry registry;
    const nlohmann::json program =
        nlohmann::json::array({BoxOperation(kBoxOp, 90.0, 64.0, 36.0),
                               OffsetOperation(testCase.distance, AstRef(TopFaceOf(kBoxOp)))});
    const std::vector<aeth::EvaluatedBody> bodies = Evaluate(program, registry);
    if (bodies.size() != 1) {
      check(false, std::string(testCase.label) + ": produced exactly one visible body");
      continue;
    }
    const aeth::ShapeProbes& probes = bodies.front().probes;
    checkNear(probes.volume, testCase.volume, 1e-6, std::string(testCase.label) + ": volume");
    check(probes.faceCount == 6,
          std::string(testCase.label) + ": SIX faces — re-trimmed, not split (unify ran)");
    check(probes.solidCount == 1 && probes.shellCount == 1 && probes.valid,
          std::string(testCase.label) + ": one valid closed solid");
    // doc-04 role table: the moved face is `offset`, everything else `modified`.
    check(CountRole(registry, "offset", 'f') == 1,
          std::string(testCase.label) + ": exactly ONE `offset` face record");
    // Neighbours reach the result by EITHER route, and which route depends on
    // the direction: the outward fuse EXTENDS all five, so all five re-mint as
    // `modified`; the inward cut shortens four and leaves the bottom face
    // untouched, so that one survives by identity keeping its original record.
    // Asserting a fixed `modified` count would therefore be asserting the
    // route, not the outcome — the exact mistake ADR-014 §4 warns about.
    // Neighbours reach the result by EITHER route, and the route depends on
    // direction: the outward fuse EXTENDS all five, so all five re-mint as
    // `modified`; the inward cut shortens four and leaves the bottom face
    // untouched, so that one survives by IDENTITY and keeps its original
    // box-minted record. Asserting a fixed `modified` count would assert the
    // route rather than the outcome — the mistake ADR-014 §4 warns about, which
    // this test made once already.
    check(CountRole(registry, "offset", 'f') + CountRole(registry, "modified", 'f') <=
              static_cast<std::size_t>(probes.faceCount),
          std::string(testCase.label) + ": re-minted faces never exceed the result's face count");
  }
}

/// The totality rule, and the identity-survival route in particular. The inward
/// case's faces are ALL identity survivors (the cut splits nothing and unify has
/// nothing to merge), so a Modified-only attribution check would report six
/// orphans here. Every live face record must carry a tabled role.
void EveryFaceIsAttributed() {
  std::printf("attribution is total, by either route (ADR-014 §4):\n");
  for (const double distance : {5.0, -5.0}) {
    aeth::NamingRegistry registry;
    const nlohmann::json program =
        nlohmann::json::array({BoxOperation(kBoxOp, 90.0, 64.0, 36.0),
                               OffsetOperation(distance, AstRef(TopFaceOf(kBoxOp)))});
    const std::vector<aeth::EvaluatedBody> bodies = Evaluate(program, registry);
    // TOTALITY IS ENFORCED BY THE HARVEST ITSELF, not re-derived here: if any
    // result entity could be attributed by NEITHER route, HarvestOperation
    // throws ("cannot attribute a result entity ... refusing to mint an
    // untrusted identity") and the evaluation above would never have returned.
    // Reaching this line with a body in hand IS the no-orphans proof — and it
    // is a proof that was earned, since this path failed exactly that way until
    // the swept prism was registered as a synthetic tool.
    check(bodies.size() == 1, std::string(distance > 0 ? "outward" : "inward") +
                                  ": the harvest attributed every entity (no orphans)");
    check(CountRole(registry, "offset", 'f') == 1,
          std::string(distance > 0 ? "outward" : "inward") + ": the moved face is unique");
    // No role outside doc-04's two-row table may appear.
    bool tabled = true;
    for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
      const aeth::NamingRecord& record = registry.RecordAt(index);
      if (!record.live || record.minter != kOffsetOp || record.kind != 'f')
        continue;
      if (record.role != "offset" && record.role != "modified")
        tabled = false;
    }
    check(tabled, std::string(distance > 0 ? "outward" : "inward") +
                      ": no face role outside doc-04's {offset, modified}");
  }
}

/// doc-04's typed refusals. Each is a support-or-refuse decision — the ruling
/// excludes a plausible-looking approximation as a third outcome.
void RefusalsAreTypedAndNamed() {
  std::printf("typed refusals (doc-04 error table):\n");

  // Curved target: a cylinder's lateral face is not planar.
  const nlohmann::json curved =
      nlohmann::json::array({{{"id", kBoxOp},
                              {"type", "create_sphere"},
                              {"outputBodyId", "00000000-0000-4000-8000-0000000000b9"},
                              {"parameters",
                               {{"radius", 20.0},
                                {"placement",
                                 {{"origin", {0.0, 0.0, 0.0}},
                                  {"zDirection", {0.0, 0.0, 1.0}},
                                  {"xDirection", {1.0, 0.0, 0.0}}}}}}},
                             OffsetOperation(3.0, AstRef(Query("faces", {SrcOp(kBoxOp)})))});
  const Failure curvedFailure = EvaluateExpectingFailure(curved);
  check(curvedFailure.code == "E_OFFSET_UNSUPPORTED_SURFACE",
        "a curved target refuses E_OFFSET_UNSUPPORTED_SURFACE rather than approximating");

  // A distance that consumes the body entirely: 36 mm tall, moved -50 mm.
  const nlohmann::json collapsed = nlohmann::json::array(
      {BoxOperation(kBoxOp, 90.0, 64.0, 36.0), OffsetOperation(-50.0, AstRef(TopFaceOf(kBoxOp)))});
  // The collapse refusal carries the bounded-feasibility payload and therefore
  // NO `code` key: the wire schema CLOSES `details` whenever `feasibilityProbe`
  // is present, so one extra key makes the response unparseable and the user
  // sees "Kernel control stream is corrupt" instead of an actionable bound.
  // Asserted so the omission cannot be "helpfully" restored later.
  const Failure collapseFailure = EvaluateExpectingFailure(collapsed);
  check(collapseFailure.kind == "operation" && collapseFailure.hasProbe,
        "an over-large inward distance refuses WITH the bounded-feasibility probe");
  check(collapseFailure.code.empty(),
        "the probe-bearing refusal carries no extra details key (the wire schema is strict)");

  // Cross-body: resolve a face on a DIFFERENT body than the offset target.
  const nlohmann::json crossBody = nlohmann::json::array(
      {BoxOperation(kBoxOp, 90.0, 64.0, 36.0), BoxOperation(kOtherBoxOp, 20.0, 20.0, 20.0, 200.0),
       OffsetOperation(5.0, AstRef(TopFaceOf(kOtherBoxOp)))});
  const Failure crossFailure = EvaluateExpectingFailure(crossBody);
  check(crossFailure.code == "E_OFFSET_FACE_NOT_ON_BODY",
        "a face on another body refuses E_OFFSET_FACE_NOT_ON_BODY");

  // An empty match must refuse, never round to a guess.
  const nlohmann::json empty = nlohmann::json::array(
      {BoxOperation(kBoxOp, 90.0, 64.0, 36.0),
       OffsetOperation(5.0, AstRef(Query("faces", {SrcOp(kBoxOp)},
                                         {Filter("normal", {ArgDirAxis(1, "z")}),
                                          Filter("normal", {ArgDirAxis(1, "x")})})))});
  const Failure emptyFailure = EvaluateExpectingFailure(empty);
  check(emptyFailure.kind == "selector" && emptyFailure.code == "E_SEL_EMPTY",
        "an empty face match refuses E_SEL_EMPTY");

  // Ambiguity must refuse too: `one` arity over all six faces.
  const nlohmann::json ambiguous =
      nlohmann::json::array({BoxOperation(kBoxOp, 90.0, 64.0, 36.0),
                             OffsetOperation(5.0, AstRef(Query("faces", {SrcOp(kBoxOp)})))});
  const Failure ambiguousFailure = EvaluateExpectingFailure(ambiguous);
  check(ambiguousFailure.kind == "selector" && ambiguousFailure.code == "E_SEL_AMBIGUOUS",
        "an ambiguous face match refuses E_SEL_AMBIGUOUS");
}

/// Result of a hard case: either a valid solid with its measured volume, or a
/// typed refusal. There is deliberately no third outcome to represent.
struct HardCase final {
  bool succeeded{};
  double volume{};
  int faces{};
  bool valid{};
  std::string kind;
  std::string code;
  std::string message;
};

HardCase RunHardCase(const nlohmann::json& program) {
  std::atomic_bool cancelled{false};
  aeth::NamingRegistry registry;
  try {
    const std::vector<aeth::EvaluatedBody> bodies =
        aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
    if (bodies.empty())
      return {false, 0.0, 0, false, "none", "", "no body"};
    const aeth::ShapeProbes& probes = bodies.back().probes;
    return {true, probes.volume, probes.faceCount, probes.valid, "", "", ""};
  } catch (const aeth::OperationFailure& error) {
    std::string code;
    if (error.Details().contains("code"))
      code = error.Details().at("code").get<std::string>();
    return {false, 0.0, 0, false, "operation", code, error.what()};
  } catch (const aeth::SelectorFailure& error) {
    return {false, 0.0, 0, false, "selector", error.SelectorCode(), error.what()};
  } catch (const std::exception& error) {
    return {false, 0.0, 0, false, "other", "", error.what()};
  }
}

/// The result is REPORTED, then asserted only on the invariant that holds
/// either way. Acceptance criterion 5 asks for each hard case to be tested
/// EITHER way — a loud typed refusal is world-class, approximating is
/// disqualifying — so what must never happen is a third outcome: a "successful"
/// result that is not a single valid solid, a crash, or an untyped throw.
void CheckHardCase(const std::string& label, const HardCase& outcome) {
  if (outcome.succeeded) {
    std::printf("  %-26s SUPPORTED  vol=%.2f faces=%d valid=%d\n", label.c_str(), outcome.volume,
                outcome.faces, outcome.valid ? 1 : 0);
    check(outcome.valid && outcome.faces > 0,
          label + ": when it succeeds, the result is a VALID solid");
  } else {
    std::printf("  %-26s REFUSED    kind=%s code=%s msg=%s\n", label.c_str(), outcome.kind.c_str(),
                outcome.code.empty() ? "(probe-bearing)" : outcome.code.c_str(),
                outcome.message.c_str());
    check(outcome.kind == "operation" || outcome.kind == "selector",
          label + ": when it refuses, the refusal is TYPED (never a bare throw)");
    check(!outcome.message.empty(), label + ": the refusal carries a message");
  }
}

/// Acceptance criterion 5 — the four hard cases the freeze review found
/// unpinned. Each is exercised for real and its outcome recorded; "refuses or
/// works" is not a status this project accepts UNTESTED, because an untested
/// refusal path is indistinguishable from a crash nobody has hit yet.
void HardCasesAreTestedEitherWay() {
  std::printf("hard cases, each tested either way (criterion 5):\n");

  // 1. BLEND-ADJACENT — offset a face that touches a fillet. The blend must
  //    either re-limit correctly or the operation must refuse; silently
  //    dropping or corrupting the blend is the disqualifying outcome.
  {
    const char* kFilletOp = "00000000-0000-4000-8000-00000000000f";
    const nlohmann::json program =
        nlohmann::json::array({BoxOperation(kBoxOp, 90.0, 64.0, 36.0),
                               {{"id", kFilletOp},
                                {"type", "fillet"},
                                {"outputBodyId", "00000000-0000-4000-8000-0000000000c1"},
                                {"parameters", {{"targetOperationId", kBoxOp}, {"radius", 6.0}}}},
                               OffsetOperation(5.0, AstRef(TopFaceOf(kFilletOp)), kFilletOp)});
    CheckHardCase("blend-adjacent", RunHardCase(program));
  }

  // 2. NEIGHBOUR CONSUMPTION — a real STEP, whose lower tread is pushed up
  //    until it goes flush with the upper one. That is a topology CHANGE (the
  //    riser face disappears and two faces merge), not a resize.
  //
  //    The first draft of this case cut a notch out of the BOTTOM and then
  //    selected `normal(+z)`, which matched nothing and refused E_SEL_EMPTY —
  //    a failure of the TEST's selector, not a refusal by the product. Recorded
  //    because "the hard case refused" would have been a false pass.
  {
    const char* kToolOp = "00000000-0000-4000-8000-00000000000c";
    const char* kCutOp = "00000000-0000-4000-8000-00000000000d";
    // Notch the TOP-RIGHT corner away: the body now has two +Z faces, the
    // original top at z=36 and the notch floor at z=24.
    const nlohmann::json program = nlohmann::json::array(
        // create_box CENTRES its placement in X and Y (the hole gate's entry
        // point at x=-45 on a 90-wide box is the witness), so the target spans
        // x -45..45 and this tool must sit at x=30 to notch the right-hand end.
        // The first draft placed it at x=60, exactly TANGENT at x=45, and the
        // cut refused "the tool does not overlap the target body" — a refusal
        // from the CUT, not from the offset under test.
        {BoxOperation(kBoxOp, 90.0, 64.0, 36.0),
         BoxOperation(kToolOp, 30.0, 70.0, 12.0, 30.0, 24.0),
         {{"id", kCutOp},
          {"type", "boolean_combine"},
          {"outputBodyId", "00000000-0000-4000-8000-0000000000c2"},
          {"parameters",
           {{"kind", "cut"}, {"targetOperationId", kBoxOp}, {"toolOperationId", kToolOp}}}},
         // The LOWER of the two +Z faces — the notch floor — raised the full
         // 12 mm step height, which lands it exactly flush with the top face.
         OffsetOperation(
             12.0,
             AstRef(Query("faces", {SrcOp(kCutOp)},
                          {Filter("normal", {ArgDirAxis(1, "z")}), Filter("min", {ArgAxis("z")})})),
             kCutOp)});
    const HardCase consumed = RunHardCase(program);
    CheckHardCase("neighbour consumption", consumed);
    // This one has an EXACT expected answer, so it is asserted rather than left
    // at "valid": raising the notch floor the full 12 mm step height restores
    // the plain 90x64x36 box. The riser face is CONSUMED and the two now-
    // coplanar faces MERGE — SIX faces, not eight, and exactly the original
    // volume. That is the topology change succeeding, not an approximation of
    // it, and a wrong answer here would still have been a "valid solid".
    check(consumed.succeeded && std::abs(consumed.volume - 207360.0) < 1e-6,
          "neighbour consumption: the step is gone — exactly the 207,360 mm3 box");
    check(consumed.succeeded && consumed.faces == 6,
          "neighbour consumption: SIX faces — the riser and its coplanar mate merged");
  }

  // 3. TANGENT CHAIN — the filleted box's top face is G1-continuous with the
  //    blend that meets it, so moving it drags a tangency rather than a crease.
  {
    const char* kFilletOp = "00000000-0000-4000-8000-00000000000f";
    const nlohmann::json program =
        nlohmann::json::array({BoxOperation(kBoxOp, 90.0, 64.0, 36.0),
                               {{"id", kFilletOp},
                                {"type", "fillet"},
                                {"outputBodyId", "00000000-0000-4000-8000-0000000000c3"},
                                {"parameters", {{"targetOperationId", kBoxOp}, {"radius", 12.0}}}},
                               // Inward, so the moved face runs INTO the tangent blend region.
                               OffsetOperation(-8.0, AstRef(TopFaceOf(kFilletOp)), kFilletOp)});
    CheckHardCase("tangent chain", RunHardCase(program));
  }

  // 4. SELF-INTERSECTING OFFSET SURFACE — concave geometry with an inward move
  //    larger than the local radius. The classic case where a naive offset
  //    produces a self-intersecting sheet.
  {
    const char* kToolOp = "00000000-0000-4000-8000-00000000000c";
    const char* kCutOp = "00000000-0000-4000-8000-00000000000d";
    const char* kFilletOp = "00000000-0000-4000-8000-00000000000f";
    const nlohmann::json program = nlohmann::json::array(
        {BoxOperation(kBoxOp, 90.0, 64.0, 36.0),
         BoxOperation(kToolOp, 30.0, 70.0, 18.0, 30.0),
         {{"id", kCutOp},
          {"type", "boolean_combine"},
          {"outputBodyId", "00000000-0000-4000-8000-0000000000c4"},
          {"parameters",
           {{"kind", "cut"}, {"targetOperationId", kBoxOp}, {"toolOperationId", kToolOp}}}},
         {{"id", kFilletOp},
          {"type", "fillet"},
          {"outputBodyId", "00000000-0000-4000-8000-0000000000c5"},
          {"parameters", {{"targetOperationId", kCutOp}, {"radius", 4.0}}}},
         OffsetOperation(-30.0, AstRef(TopFaceOf(kFilletOp)), kFilletOp)});
    CheckHardCase("self-intersecting", RunHardCase(program));
  }
}

/// The absent-slot-is-v1 invariant chamfer established (ADR-014 §1): whole-body
/// offset is superseded as the FUTURE but not removed, and must still evaluate.
void AbsentSlotStaysV1() {
  std::printf("absent `face` slot keeps v1 whole-body offset (ADR-014 §1):\n");
  std::atomic_bool cancelled{false};
  const nlohmann::json program =
      nlohmann::json::array({BoxOperation(kBoxOp, 90.0, 64.0, 36.0),
                             {{"id", kOffsetOp},
                              {"type", "offset"},
                              {"outputBodyId", "00000000-0000-4000-8000-0000000000b4"},
                              {"parameters", {{"targetOperationId", kBoxOp}, {"distance", 2.0}}}}});
  const std::vector<aeth::EvaluatedBody> bodies = aeth::EvaluateOperations(program, cancelled);
  check(bodies.size() == 1 && bodies.front().probes.solidCount == 1,
        "v1 whole-body offset still evaluates with no face slot");
  // Grown on every side: strictly larger than the 207,360 mm3 source box.
  check(bodies.size() == 1 && bodies.front().probes.volume > 207360.0,
        "v1 grows the whole body, not one face");
}

/// Replay determinism: the same document must evaluate to the same geometry on
/// every run, which is what the replay cache and the op-hash rest on.
void ReplayDeterminism() {
  std::printf("replay determinism:\n");
  double first = 0.0;
  bool identical = true;
  for (int run = 0; run < 4; ++run) {
    aeth::NamingRegistry registry;
    const nlohmann::json program = nlohmann::json::array(
        {BoxOperation(kBoxOp, 90.0, 64.0, 36.0), OffsetOperation(5.0, AstRef(TopFaceOf(kBoxOp)))});
    const std::vector<aeth::EvaluatedBody> bodies = Evaluate(program, registry);
    if (bodies.size() != 1) {
      identical = false;
      break;
    }
    if (run == 0)
      first = bodies.front().probes.volume;
    else if (bodies.front().probes.volume != first) // exact, deliberately
      identical = false;
  }
  check(identical, "four independent evaluations agree exactly");
}

} // namespace

int main() {
  try {
    OutwardAndInwardMatchTheAdrTable();
    EveryFaceIsAttributed();
    RefusalsAreTypedAndNamed();
    HardCasesAreTestedEitherWay();
    AbsentSlotStaysV1();
    ReplayDeterminism();
  } catch (const std::exception& error) {
    std::printf("  FAIL threw: %s\n", error.what());
    g_failures += 1;
  }
  if (g_failures == 0) {
    std::printf("local face offset: all checks passed\n");
    return 0;
  }
  std::printf("local face offset: %d FAILED\n", g_failures);
  return 1;
}
