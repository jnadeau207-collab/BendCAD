// Native tests for the replay engine (Wave 2.1 slice 1b-wire + slice 2). They
// drive DocumentEvaluator directly and pin the two contracts the cache rests on:
//
//   1. THE DIFFERENTIAL GATE (the non-negotiable safety invariant): a WARM
//      evaluation — one that restores a cached operation prefix and re-executes
//      only the changed tail — is byte-identical to a COLD evaluation of the
//      same program. "Byte-identical" here means the observable output: the same
//      unconsumed bodies in the same order, the same probes (bit-for-bit), and
//      the same projected element names. Verified for a trailing edit, a middle
//      edit, with and without element naming.
//   2. THE REUSE METRIC: a warm evaluation actually re-executes only the tail —
//      a single trailing-parameter edit re-executes exactly one operation, a
//      re-evaluation of an unchanged program executes zero, and a middle edit
//      re-executes exactly the suffix from the change.
//
// Plus: with reuse OFF the evaluator is byte-identical to plain
// EvaluateOperations (the fail-closed default the server ships).
#include <array>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <exception>
#include <string>
#include <vector>

#include <nlohmann/json.hpp>

#include "element_names.hpp"
#include "geometry.hpp"
#include "tessellate.hpp"

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

const std::string kDocumentId = "dddddddd-0000-4d00-8d00-dddddddddddd";
const std::string kKernelGeomVersion = "occt-test+aeth.1";

// UUID-shaped, hex-only op ids (element naming parses the first 8 hex chars), all
// distinct in the last two characters.
std::string IndexedId(const int index) {
  static constexpr char kHex[] = "0123456789abcdef";
  std::string id = "aaaaaaaa-0000-4000-8000-0000000000";
  id.push_back(kHex[(index >> 4) & 0xF]);
  id.push_back(kHex[index & 0xF]);
  return id;
}

nlohmann::json BoxOp(const std::string& id, const double width, const double depth,
                     const double height, const std::array<double, 3>& origin) {
  return {
      {"id", id},
      {"type", "create_box"},
      {"schemaVersion", 1},
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

nlohmann::json TranslateOp(const std::string& id, const std::string& targetId,
                           const std::array<double, 3>& offset) {
  return {
      {"id", id},
      {"type", "transform"},
      {"schemaVersion", 1},
      {"outputBodyId", "00000000-0000-4000-8000-00000000000f"},
      {"parameters",
       {{"targetOperationId", targetId},
        {"transform", {{"kind", "translate"}, {"offset", {offset[0], offset[1], offset[2]}}}}}},
  };
}

nlohmann::json HoleOp(const std::string& id, const std::string& targetId, const double radius) {
  return {
      {"id", id},
      {"type", "hole"},
      {"schemaVersion", 1},
      {"outputBodyId", "00000000-0000-4000-8000-00000000000c"},
      {"parameters",
       {{"targetOperationId", targetId},
        {"placement",
         {{"origin", {15.0, 0.0, 15.0}},
          {"zDirection", {0.0, 0.0, -1.0}},
          {"xDirection", {1.0, 0.0, 0.0}}}},
        {"size", {{"kind", "radius"}, {"radius", radius}}},
        {"depth", 10.0},
        {"throughAll", false}}},
  };
}

nlohmann::json FilletOp(const std::string& id, const std::string& targetId, const double radius) {
  return {
      {"id", id},
      {"type", "fillet"},
      {"schemaVersion", 1},
      {"outputBodyId", "00000000-0000-4000-8000-00000000000e"},
      {"parameters", {{"targetOperationId", targetId}, {"radius", radius}}},
  };
}

nlohmann::json ChamferOp(const std::string& id, const std::string& targetId,
                         const double distance) {
  return {
      {"id", id},
      {"type", "chamfer"},
      {"schemaVersion", 1},
      {"outputBodyId", "00000000-0000-4000-8000-00000000000d"},
      {"parameters", {{"targetOperationId", targetId}, {"distance", distance}}},
  };
}

nlohmann::json OffsetOp(const std::string& id, const std::string& targetId, const double distance) {
  return {
      {"id", id},
      {"type", "offset"},
      {"schemaVersion", 1},
      {"outputBodyId", "00000000-0000-4000-8000-00000000000a"},
      {"parameters", {{"targetOperationId", targetId}, {"distance", distance}}},
  };
}

// box + `transformCount` translate transforms, each consuming the previous body,
// so editing the last transform's offset leaves the whole prefix unchanged.
nlohmann::json TransformChain(const int transformCount, const double lastOffsetX) {
  nlohmann::json operations = nlohmann::json::array();
  operations.push_back(BoxOp(IndexedId(0), 40, 30, 20, {0, 0, 0}));
  for (int index = 1; index <= transformCount; ++index) {
    const double offsetX = index == transformCount ? lastOffsetX : static_cast<double>(index);
    operations.push_back(TranslateOp(IndexedId(index), IndexedId(index - 1),
                                     {offsetX, static_cast<double>(index), 0.0}));
  }
  return operations;
}

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

// Observable equality: same bodies in the same order (id + bit-for-bit probes)
// and, when naming is on, the same projected element-name array per body. This
// is exactly the wire output evaluate_document surfaces.
bool SameOutput(const aeth::DocumentEvaluator::Result& warm,
                const aeth::DocumentEvaluator::Result& cold) {
  if (warm.bodies.size() != cold.bodies.size())
    return false;
  const std::uint32_t epoch = 7;
  for (std::size_t index = 0; index < warm.bodies.size(); ++index) {
    const aeth::EvaluatedBody& warmBody = warm.bodies[index];
    const aeth::EvaluatedBody& coldBody = cold.bodies[index];
    if (warmBody.bodyId != coldBody.bodyId || warmBody.operationId != coldBody.operationId)
      return false;
    if (!ProbesEqual(warmBody.probes, coldBody.probes))
      return false;
    if (warm.elementNames.has_value() != cold.elementNames.has_value())
      return false;
    if (warm.elementNames.has_value()) {
      const nlohmann::json warmNames = aeth::ProjectElementNames(
          *warm.elementNames, warmBody.shape, epoch, static_cast<std::uint32_t>(index));
      const nlohmann::json coldNames = aeth::ProjectElementNames(
          *cold.elementNames, coldBody.shape, epoch, static_cast<std::uint32_t>(index));
      if (warmNames != coldNames)
        return false;
    }
  }
  return true;
}

aeth::DocumentEvaluator::Result EvaluateCold(const nlohmann::json& operations,
                                             const bool includeElementNames) {
  std::atomic_bool cancelled{false};
  aeth::DocumentEvaluator evaluator;
  return evaluator.Evaluate(operations, kDocumentId, kKernelGeomVersion, includeElementNames,
                            /*reuseEnabled=*/false, cancelled);
}

// (0) reuse OFF is byte-identical to plain EvaluateOperations.
void ColdMatchesPlainEvaluate() {
  std::printf("reuse-off cold path matches plain EvaluateOperations:\n");
  std::atomic_bool cancelled{false};
  const nlohmann::json program = nlohmann::json::array({BoxOp(IndexedId(0), 80, 50, 15, {0, 0, 0}),
                                                        HoleOp(IndexedId(1), IndexedId(0), 8),
                                                        FilletOp(IndexedId(2), IndexedId(1), 1.5)});
  const std::vector<aeth::EvaluatedBody> plain =
      aeth::EvaluateOperations(program, cancelled, nullptr, nullptr);
  const aeth::DocumentEvaluator::Result cold = EvaluateCold(program, false);
  checkEqual(cold.bodies.size(), plain.size(), "same body count");
  bool same = cold.bodies.size() == plain.size();
  for (std::size_t index = 0; index < cold.bodies.size() && same; ++index) {
    same = cold.bodies[index].bodyId == plain[index].bodyId &&
           cold.bodies[index].operationId == plain[index].operationId &&
           ProbesEqual(cold.bodies[index].probes, plain[index].probes);
  }
  check(same, "cold DocumentEvaluator bodies == EvaluateOperations bodies (ids + probes)");
  checkEqual(cold.executedOperationCount, 3, "reuse-off executes every operation");
}

// (1) full hit: re-evaluating an unchanged program restores everything.
void FullHitExecutesNothing() {
  std::printf("full cache hit executes nothing:\n");
  std::atomic_bool cancelled{false};
  aeth::DocumentEvaluator evaluator;
  const nlohmann::json program = TransformChain(5, 100.0);
  const aeth::DocumentEvaluator::Result first = evaluator.Evaluate(
      program, kDocumentId, kKernelGeomVersion, false, /*reuseEnabled=*/true, cancelled);
  checkEqual(first.executedOperationCount, 6, "first evaluation (cold-fill) executes all 6 ops");
  const aeth::DocumentEvaluator::Result second = evaluator.Evaluate(
      program, kDocumentId, kKernelGeomVersion, false, /*reuseEnabled=*/true, cancelled);
  checkEqual(second.executedOperationCount, 0, "re-evaluating the same program executes 0 ops");
  check(SameOutput(second, EvaluateCold(program, false)), "full-hit output == cold output");
}

// (2) trailing edit: warm re-executes exactly the last op, byte-identical to cold.
void TrailingEditReusesPrefix(const bool includeElementNames) {
  std::printf("trailing edit re-executes only the tail%s:\n",
              includeElementNames ? " (with element names)" : "");
  std::atomic_bool cancelled{false};
  aeth::DocumentEvaluator evaluator;

  nlohmann::json original;
  nlohmann::json edited;
  if (includeElementNames) {
    // box -> hole -> fillet; edit the fillet radius (the last op).
    original = nlohmann::json::array({BoxOp(IndexedId(0), 80, 50, 15, {0, 0, 0}),
                                      HoleOp(IndexedId(1), IndexedId(0), 8),
                                      FilletOp(IndexedId(2), IndexedId(1), 1.5)});
    edited = nlohmann::json::array({BoxOp(IndexedId(0), 80, 50, 15, {0, 0, 0}),
                                    HoleOp(IndexedId(1), IndexedId(0), 8),
                                    FilletOp(IndexedId(2), IndexedId(1), 2.0)});
  } else {
    original = TransformChain(5, 100.0);
    edited = TransformChain(5, 250.0);
  }

  // Warm the cache with the original, then evaluate the edited program warm.
  evaluator.Evaluate(original, kDocumentId, kKernelGeomVersion, includeElementNames, true,
                     cancelled);
  const aeth::DocumentEvaluator::Result warm = evaluator.Evaluate(
      edited, kDocumentId, kKernelGeomVersion, includeElementNames, true, cancelled);

  checkEqual(warm.executedOperationCount, 1, "warm eval re-executes exactly the edited last op");
  check(SameOutput(warm, EvaluateCold(edited, includeElementNames)),
        "warm output is byte-identical to a cold evaluation (the differential gate)");
}

// (3) middle edit: warm reuses the prefix before the change and re-executes the suffix.
void MiddleEditReusesPrefix() {
  std::printf("middle edit re-executes only the suffix:\n");
  std::atomic_bool cancelled{false};
  aeth::DocumentEvaluator evaluator;

  // box + 5 transforms; change transform #3's offset (op index 3 of 6).
  nlohmann::json original = TransformChain(5, 100.0);
  nlohmann::json edited = TransformChain(5, 100.0);
  edited[3]["parameters"]["transform"]["offset"][0] = 999.0;

  evaluator.Evaluate(original, kDocumentId, kKernelGeomVersion, false, true, cancelled);
  const aeth::DocumentEvaluator::Result warm =
      evaluator.Evaluate(edited, kDocumentId, kKernelGeomVersion, false, true, cancelled);

  // ops[0..2] (box, T1, T2) reused; ops[3..5] (T3-edited, T4, T5) re-executed.
  checkEqual(warm.executedOperationCount, 3,
             "warm eval re-executes the 3-op suffix from the change");
  check(SameOutput(warm, EvaluateCold(edited, false)),
        "middle-edit warm output is byte-identical to cold");
}

// (4) the design's acceptance at scale: a large document with one trailing edit.
void LargeDocumentTrailingEdit() {
  std::printf("large document, one trailing edit:\n");
  std::atomic_bool cancelled{false};
  aeth::DocumentEvaluator evaluator;
  const nlohmann::json original = TransformChain(24, 1.0); // box + 24 transforms = 25 ops
  nlohmann::json edited = TransformChain(24, 500.0);

  evaluator.Evaluate(original, kDocumentId, kKernelGeomVersion, false, true, cancelled);
  const aeth::DocumentEvaluator::Result warm =
      evaluator.Evaluate(edited, kDocumentId, kKernelGeomVersion, false, true, cancelled);

  checkEqual(warm.executedOperationCount, 1,
             "a 25-op document with one trailing edit re-executes exactly one op");
  check(SameOutput(warm, EvaluateCold(edited, false)), "large-document warm output == cold");
}

// (5) Wave 2.1 slice 4 + Wave 2.2: presentation quality is not part of the
// B-rep replay key. Re-evaluating an unchanged document restores the cached
// shape without executing an operation, and that same shape can then be
// tessellated at a different viewport tier.
void LodChangeRetessellatesWithoutReexecution() {
  std::printf("LOD change reuses B-rep and retessellates:\n");
  std::atomic_bool cancelled{false};
  aeth::DocumentEvaluator evaluator;
  const nlohmann::json program = TransformChain(5, 100.0);

  const aeth::DocumentEvaluator::Result first =
      evaluator.Evaluate(program, kDocumentId, kKernelGeomVersion, false, true, cancelled);
  const aeth::DocumentEvaluator::Result reused =
      evaluator.Evaluate(program, kDocumentId, kKernelGeomVersion, false, true, cancelled);

  checkEqual(first.executedOperationCount, 6, "cold-fill executes all operations");
  checkEqual(reused.executedOperationCount, 0,
             "LOD-only re-evaluation executes zero geometry operations");
  checkEqual(reused.bodies.size(), 1, "reused document exposes one final body");
  if (reused.bodies.size() != 1)
    return;

  const aeth::TessellationPacket tier0 =
      aeth::TessellateShape(reused.bodies[0].shape, 1, cancelled, 0);
  const aeth::TessellationPacket tier2 =
      aeth::TessellateShape(reused.bodies[0].shape, 2, cancelled, 2);
  check(tier0.descriptor.at("lodTier") == 0, "first packet reports LOD 0");
  check(tier2.descriptor.at("lodTier") == 2, "second packet reports LOD 2");
  check(tier2.descriptor.at("deflectionMm").get<double>() <
            tier0.descriptor.at("deflectionMm").get<double>(),
        "LOD 2 retessellates the cached shape at a finer deflection");
  check(tier0.bytes != tier2.bytes, "LOD switch emits a distinct mesh packet");
  check(SameOutput(reused, EvaluateCold(program, false)),
        "LOD switch leaves the cached B-rep result byte-identical to cold");
}

// (6) the memory governor (slice 3a): a budget smaller than the working set
// forces byte-bounded eviction, the live total stays within budget (or a single
// over-budget survivor remains), and — the safety property — output after
// eviction is still byte-identical to a cold evaluation.
void ByteBudgetGovernorEvicts() {
  std::printf("byte-budget governor evicts and stays correct:\n");
  const std::size_t budget = 200 * 1024; // 200 KB, well under a 9-op working set
  std::atomic_bool cancelled{false};
  aeth::DocumentEvaluator evaluator(budget);
  const nlohmann::json program = TransformChain(8, 1.0); // box + 8 transforms = 9 ops

  evaluator.Evaluate(program, kDocumentId, kKernelGeomVersion, false, true, cancelled);
  const aeth::DocumentEvaluator::CacheStats stats = evaluator.Stats();
  check(stats.evictions > 0, "governor evicted at least one snapshot under a tight budget");
  check(stats.entries >= 1, "governor retains at least one snapshot");
  check(stats.entries == 1 || stats.bytes <= budget,
        "live bytes within budget (or a single over-budget survivor)");
  checkEqual(stats.budgetBytes, budget, "stats reports the configured budget");
  checkEqual(stats.misses, 1, "the cold-fill evaluation counted as one miss");

  // The differential gate must survive eviction: a warm re-eval whose prefixes
  // may have aged out recomputes them and is byte-identical to a cold eval.
  const aeth::DocumentEvaluator::Result warm =
      evaluator.Evaluate(program, kDocumentId, kKernelGeomVersion, false, true, cancelled);
  check(SameOutput(warm, EvaluateCold(program, false)),
        "output after eviction is byte-identical to cold (differential gate holds)");
}

// (7) stats counters track reuse under the default (non-evicting) budget: one
// cold miss that stores a snapshot per op, then a full hit that stores nothing.
void StatsCountersTrackReuse() {
  std::printf("stats counters track hits, misses, and stored snapshots:\n");
  std::atomic_bool cancelled{false};
  aeth::DocumentEvaluator evaluator; // default 512 MB budget — no eviction here
  const nlohmann::json program = TransformChain(5, 100.0); // 6 ops

  evaluator.Evaluate(program, kDocumentId, kKernelGeomVersion, false, true, cancelled);
  evaluator.Evaluate(program, kDocumentId, kKernelGeomVersion, false, true, cancelled);
  const aeth::DocumentEvaluator::CacheStats stats = evaluator.Stats();
  checkEqual(stats.misses, 1, "one cold evaluation counted as a miss");
  checkEqual(stats.hits, 1, "one warm re-evaluation counted as a hit");
  checkEqual(stats.snapshotsStored, 6, "cold-fill stored one snapshot per op (6)");
  checkEqual(stats.entries, 6, "all six prefix snapshots live under the default budget");
  checkEqual(stats.evictions, 0, "no eviction under the default budget");
  check(stats.budgetBytes == aeth::DocumentEvaluator::kDefaultCacheBudgetBytes,
        "default budget is 512 MB");
  check(stats.bytes > 0, "live byte total is nonzero while entries are present");
}

// (8) Wave 2.4: every advertised feasibility value is a candidate the
// kernel actually built and validated. The replay assertion is the critical
// honesty gate: a diagnostic may be conservative, but it may never be fiction.
void FeasibilityBoundsReplaySuccessfully() {
  std::printf("bounded feasibility diagnostics replay successfully:\n");
  std::atomic_bool cancelled{false};
  const std::string boxId = IndexedId(0);
  const nlohmann::json box = BoxOp(boxId, 10.0, 10.0, 10.0, {0, 0, 0});

  const auto checkOperation = [&](nlohmann::json operation, const char* parameter,
                                  const char* detailKey) {
    const std::string operationId = operation.at("id").get<std::string>();
    const double requested = operation.at("parameters").at(parameter).get<double>();
    double bound = 0.0;
    bool failedAsExpected = false;
    try {
      (void)aeth::EvaluateOperations(nlohmann::json::array({box, operation}), cancelled);
    } catch (const aeth::OperationFailure& error) {
      failedAsExpected = true;
      check(error.Code() == "GEOMETRY_FAILED",
            operation.at("type").get<std::string>() + " keeps GEOMETRY_FAILED");
      check(error.OperationId() == operationId,
            operation.at("type").get<std::string>() + " error is attributed");
      const nlohmann::json& details = error.Details();
      check(details.contains(detailKey),
            operation.at("type").get<std::string>() + " carries a tested bound");
      if (details.contains(detailKey))
        bound = details.at(detailKey).get<double>();
      check(std::abs(bound) > 0.0, operation.at("type").get<std::string>() + " bound is non-zero");
      check(std::signbit(bound) == std::signbit(requested),
            operation.at("type").get<std::string>() + " bound preserves direction");
      check(std::abs(bound) < std::abs(requested),
            operation.at("type").get<std::string>() + " bound is below failed request");

      const nlohmann::json probe = details.value("feasibilityProbe", nlohmann::json::object());
      check(probe.value("parameter", std::string()) == parameter,
            operation.at("type").get<std::string>() + " identifies the repaired parameter");
      check(probe.value("requested", 0.0) == requested,
            operation.at("type").get<std::string>() + " preserves the requested value");
      check(probe.value("maxFeasible", 0.0) == bound,
            operation.at("type").get<std::string>() + " aliases one bound exactly");
      check(probe.value("bound", std::string()) == "tested-lower-bound",
            operation.at("type").get<std::string>() + " labels the bound conservatively");
      const std::size_t attempts = probe.value("attempts", std::size_t{0});
      check(attempts > 0 && attempts <= 16,
            operation.at("type").get<std::string>() + " reports bounded work");
    }
    check(failedAsExpected, operation.at("type").get<std::string>() + " oversized request fails");

    if (std::abs(bound) > 0.0) {
      operation["parameters"][parameter] = bound;
      try {
        const std::vector<aeth::EvaluatedBody> bodies =
            aeth::EvaluateOperations(nlohmann::json::array({box, operation}), cancelled);
        checkEqual(bodies.size(), 1,
                   operation.at("type").get<std::string>() + " reported bound replays");
      } catch (const std::exception& error) {
        std::printf("  FAIL %s reported bound did not replay: %s\n",
                    operation.at("type").get<std::string>().c_str(), error.what());
        g_failures += 1;
      }
    }
  };

  checkOperation(FilletOp(IndexedId(1), boxId, 100.0), "radius", "maxFeasibleRadius");
  checkOperation(ChamferOp(IndexedId(2), boxId, 100.0), "distance", "maxFeasibleDistance");
  checkOperation(OffsetOp(IndexedId(3), boxId, -100.0), "distance", "maxFeasibleDistance");

  // Syntactically invalid parameters are not geometry feasibility questions:
  // they retain INVALID_REQUEST and must not claim a repair bound.
  bool rejectedInvalid = false;
  try {
    const nlohmann::json invalid = nlohmann::json::array({box, FilletOp(IndexedId(4), boxId, 0.0)});
    (void)aeth::EvaluateOperations(invalid, cancelled);
  } catch (const aeth::OperationFailure& error) {
    rejectedInvalid = true;
    check(error.Code() == "INVALID_REQUEST", "invalid radius remains INVALID_REQUEST");
    check(error.Details().is_null() || error.Details().empty(),
          "invalid radius carries no feasibility claim");
  }
  check(rejectedInvalid, "invalid radius is rejected");
}

} // namespace

int main() {
  try {
    ColdMatchesPlainEvaluate();
    FullHitExecutesNothing();
    TrailingEditReusesPrefix(false);
    TrailingEditReusesPrefix(true);
    MiddleEditReusesPrefix();
    LargeDocumentTrailingEdit();
    LodChangeRetessellatesWithoutReexecution();
    ByteBudgetGovernorEvicts();
    StatsCountersTrackReuse();
    FeasibilityBoundsReplaySuccessfully();
  } catch (const std::exception& error) {
    std::printf("FATAL: uncaught exception: %s\n", error.what());
    return 1;
  }
  if (g_failures == 0) {
    std::printf("\nALL REPLAY CACHE TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d REPLAY CACHE CHECK(S) FAILED\n", g_failures);
  return 1;
}
