// Native unit tests for the BodyPool snapshot/restore seam (Wave 2.1 replay
// engine, slice 1). The replay cache's fail-closed correctness gate demands
// that resuming evaluation from a snapshotted operation prefix be
// byte-identical to a cold full replay. Before any reuse is trusted, this
// suite pins the seam itself — the value semantics the whole cache rests on:
//
//   1. snapshot -> mutate -> restore reproduces the exact visible-body set
//      (order, ids, and OCCT TShape identity) that existed at snapshot time;
//   2. restore rebuilds the consume/available bookkeeping, so an id that was
//      consumable at the snapshot resolves again and an id already consumed
//      before the snapshot still refuses (consumed is consumed);
//   3. a snapshot is an INDEPENDENT value — later mutation of the live pool
//      never disturbs it, and one snapshot may seed many restores;
//   4. TShape identity survives the copy: an edge explored from a restored
//      body IsSame the same edge explored from the pre-snapshot body, which is
//      what tranche-N5 ref resolution keys on;
//   5. the differential dry run for slice 2: restore(prefix) + replay(tail)
//      lands on the SAME visible set as one continuous evaluation of the whole
//      program. Feeding identical tail inputs isolates the seam, so any
//      divergence here would be a seam defect, not geometry.
//
// The seam is a value copy of handle-shared OCCT shapes, so these link only
// body_pool.hpp (header-only) and OCCT — no kernel-host process, no
// EvaluateOperations, no protocol.
#include <cstdio>
#include <exception>
#include <string>
#include <vector>

#include <BRepPrimAPI_MakeBox.hxx>
#include <TopExp_Explorer.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Shape.hxx>

#include "body_pool.hpp"
#include "geometry.hpp"

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

// Distinct UUID-shaped operation ids (the seam never parses them; it only keys
// the available-by-id map on the string, so any distinct strings suffice).
const std::string kOpA = "aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa";
const std::string kOpB = "bbbbbbbb-2222-4b22-8b22-bbbbbbbbbbbb";
const std::string kOpC = "cccccccc-3333-4c33-8c33-cccccccccccc";
const std::string kOpD = "dddddddd-4444-4d44-8d44-dddddddddddd";
const std::string kConsumer = "eeeeeeee-5555-4e55-8e55-eeeeeeeeeeee";

// A body-producing operation's result with a real OCCT solid, so identity
// checks exercise genuine TShape handles (never a null or shared default).
aeth::EvaluatedBody MakeBoxBody(const std::string& operationId, const double sx, const double sy,
                                const double sz) {
  aeth::EvaluatedBody body;
  body.bodyId = "body-" + operationId;
  body.operationId = operationId;
  body.shape = BRepPrimAPI_MakeBox(sx, sy, sz).Shape();
  body.probes = aeth::ShapeProbes{};
  return body;
}

// Two visible-body vectors denote the same pool state iff they match in count,
// order, identity strings, AND OCCT TShape identity — the last is the property
// the cache actually depends on (a restored body must BE the original shape,
// not merely an equal one).
bool SameVisible(const std::vector<aeth::EvaluatedBody>& actual,
                 const std::vector<aeth::EvaluatedBody>& expected) {
  if (actual.size() != expected.size())
    return false;
  for (std::size_t index = 0; index < actual.size(); ++index) {
    if (actual[index].bodyId != expected[index].bodyId)
      return false;
    if (actual[index].operationId != expected[index].operationId)
      return false;
    if (!actual[index].shape.IsSame(expected[index].shape))
      return false;
  }
  return true;
}

// The first edge of a shape in TopExp explore order — a stable representative
// sub-shape whose TShape must be preserved by a snapshot copy.
TopoDS_Edge FirstEdge(const TopoDS_Shape& shape) {
  TopExp_Explorer explorer(shape, TopAbs_EDGE);
  return TopoDS::Edge(explorer.Current());
}

// (1) snapshot -> mutate -> restore reproduces the snapshot-time visible set.
void RoundTripReproducesVisibleBodies() {
  std::printf("RoundTripReproducesVisibleBodies\n");
  aeth::BodyPool pool;
  pool.Produce(MakeBoxBody(kOpA, 10, 10, 10));
  pool.Produce(MakeBoxBody(kOpB, 20, 20, 20));
  pool.Produce(MakeBoxBody(kOpC, 30, 30, 30));
  const std::vector<aeth::EvaluatedBody> atSnapshot = pool.PeekVisibleBodies();
  const aeth::BodyPool::Snapshot snapshot = pool.TakeSnapshot();

  // Mutate the live pool well past the snapshot: consume one, add another.
  pool.Consume(kConsumer, "boolean cut", "target", kOpB);
  pool.Produce(MakeBoxBody(kOpD, 40, 40, 40));
  check(!SameVisible(pool.PeekVisibleBodies(), atSnapshot),
        "the mutated pool differs from the snapshot state (sanity: the test mutated something)");

  pool.RestoreFrom(snapshot);
  checkEqual(pool.PeekVisibleBodies().size(), 3,
             "restore brings back exactly the 3 snapshot bodies");
  check(SameVisible(pool.PeekVisibleBodies(), atSnapshot),
        "restored visible set matches the snapshot state (order, ids, TShape identity)");
}

// (2) restore rebuilds the consume/available bookkeeping.
void RestoreRebuildsConsumeMap() {
  std::printf("RestoreRebuildsConsumeMap\n");
  aeth::BodyPool pool;
  pool.Produce(MakeBoxBody(kOpA, 10, 10, 10));
  pool.Produce(MakeBoxBody(kOpB, 20, 20, 20));
  pool.Produce(MakeBoxBody(kOpC, 30, 30, 30));
  // Consume B BEFORE snapshotting: B must stay consumed across the round trip.
  pool.Consume(kConsumer, "boolean cut", "target", kOpB);
  const aeth::BodyPool::Snapshot snapshot = pool.TakeSnapshot();

  // Drain the pool completely, then restore.
  pool.Consume(kConsumer, "boolean cut", "target", kOpA);
  pool.Consume(kConsumer, "boolean cut", "tool", kOpC);
  checkEqual(pool.PeekVisibleBodies().size(), 0, "sanity: pool fully drained before restore");
  pool.RestoreFrom(snapshot);

  checkEqual(pool.PeekVisibleBodies().size(), 2,
             "restore brings back the 2 unconsumed bodies (A, C)");

  // An id consumable at the snapshot (A) resolves again and hands back a real
  // shape; the id consumed before the snapshot (B) still refuses.
  bool aResolved = false;
  try {
    const TopoDS_Shape& shape = pool.Consume(kConsumer, "boolean cut", "target", kOpA);
    aResolved = !shape.IsNull();
  } catch (const aeth::ReferenceMissing&) {
    aResolved = false;
  }
  check(aResolved, "an id available at snapshot time Consume-s again after restore");

  bool bRefused = false;
  try {
    pool.Consume(kConsumer, "boolean cut", "tool", kOpB);
  } catch (const aeth::ReferenceMissing&) {
    bRefused = true;
  }
  check(bRefused,
        "an id consumed BEFORE the snapshot still refuses after restore (consumed is consumed)");
}

// (3a) later mutation of the live pool never disturbs the snapshot value, and
// (3b) one snapshot may be restored any number of times.
void SnapshotIsIndependentAndReusable() {
  std::printf("SnapshotIsIndependentAndReusable\n");
  aeth::BodyPool pool;
  pool.Produce(MakeBoxBody(kOpA, 10, 10, 10));
  pool.Produce(MakeBoxBody(kOpB, 20, 20, 20));
  const std::vector<aeth::EvaluatedBody> atSnapshot = pool.PeekVisibleBodies();
  const aeth::BodyPool::Snapshot snapshot = pool.TakeSnapshot();

  // Heavy mutation AFTER taking the snapshot: consume both, add a third.
  pool.Consume(kConsumer, "boolean cut", "target", kOpA);
  pool.Consume(kConsumer, "boolean cut", "tool", kOpB);
  pool.Produce(MakeBoxBody(kOpC, 30, 30, 30));

  // First restore: the snapshot was not disturbed by the mutation above.
  pool.RestoreFrom(snapshot);
  check(SameVisible(pool.PeekVisibleBodies(), atSnapshot),
        "snapshot is unaffected by mutation performed after it was taken");

  // Mutate again, then restore the SAME snapshot a second time: identical.
  pool.Produce(MakeBoxBody(kOpD, 40, 40, 40));
  pool.RestoreFrom(snapshot);
  check(SameVisible(pool.PeekVisibleBodies(), atSnapshot),
        "the same snapshot restores identically a second time (a prefix can seed many tails)");
}

// (4) TShape identity survives the snapshot copy at the sub-shape level.
void ShapeIdentitySurvivesSnapshot() {
  std::printf("ShapeIdentitySurvivesSnapshot\n");
  aeth::BodyPool pool;
  pool.Produce(MakeBoxBody(kOpA, 10, 10, 10));
  const TopoDS_Edge edgeBefore = FirstEdge(pool.PeekVisibleBodies().at(0).shape);
  const aeth::BodyPool::Snapshot snapshot = pool.TakeSnapshot();

  pool.Consume(kConsumer, "boolean cut", "target", kOpA);
  pool.RestoreFrom(snapshot);

  const TopoDS_Edge edgeAfter = FirstEdge(pool.PeekVisibleBodies().at(0).shape);
  check(edgeAfter.IsSame(edgeBefore),
        "an edge explored from a restored body IsSame the same edge before the snapshot");
}

// (5) the slice-2 differential dry run: restore(prefix) + replay(tail) reaches
// the same visible set as one continuous evaluation of the whole program.
void PrefixRestorePlusTailEqualsContinuous() {
  std::printf("PrefixRestorePlusTailEqualsContinuous\n");
  // Identical operation results feed BOTH paths, so the only variable is HOW
  // the pool reached the final state — continuous production vs restore+tail.
  const aeth::EvaluatedBody a = MakeBoxBody(kOpA, 10, 10, 10);
  const aeth::EvaluatedBody b = MakeBoxBody(kOpB, 20, 20, 20);
  const aeth::EvaluatedBody c = MakeBoxBody(kOpC, 30, 30, 30);
  const aeth::EvaluatedBody d = MakeBoxBody(kOpD, 40, 40, 40);

  // Cold path: produce A, B, C; consume B; produce D. Visible => A, C, D.
  aeth::BodyPool cold;
  cold.Produce(a);
  cold.Produce(b);
  cold.Produce(c);
  cold.Consume(kConsumer, "boolean cut", "target", kOpB);
  cold.Produce(d);
  const std::vector<aeth::EvaluatedBody> coldVisible = cold.TakeVisibleBodies();
  checkEqual(coldVisible.size(), 3, "cold path leaves 3 visible bodies (A, C, D)");

  // Warm path: build the prefix (A, B, C), snapshot it, then on a FRESH pool
  // restore the prefix and replay only the tail (consume B; produce D).
  aeth::BodyPool warmPrefix;
  warmPrefix.Produce(a);
  warmPrefix.Produce(b);
  warmPrefix.Produce(c);
  const aeth::BodyPool::Snapshot prefix = warmPrefix.TakeSnapshot();

  aeth::BodyPool warm;
  warm.RestoreFrom(prefix);
  warm.Consume(kConsumer, "boolean cut", "target", kOpB);
  warm.Produce(d);
  const std::vector<aeth::EvaluatedBody> warmVisible = warm.TakeVisibleBodies();

  check(SameVisible(warmVisible, coldVisible), "restore(prefix) + replay(tail) == continuous "
                                               "evaluation (the seam introduces no divergence)");
}

} // namespace

int main() {
  try {
    RoundTripReproducesVisibleBodies();
    RestoreRebuildsConsumeMap();
    SnapshotIsIndependentAndReusable();
    ShapeIdentitySurvivesSnapshot();
    PrefixRestorePlusTailEqualsContinuous();
  } catch (const std::exception& error) {
    std::printf("FATAL: uncaught exception: %s\n", error.what());
    return 1;
  }
  if (g_failures == 0) {
    std::printf("\nALL BODY POOL SNAPSHOT TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d BODY POOL SNAPSHOT CHECK(S) FAILED\n", g_failures);
  return 1;
}
