#pragma once

#include <cstddef>
#include <map>
#include <string>
#include <utility>
#include <vector>

#include <TopoDS_Shape.hxx>

#include "geometry.hpp"

namespace aeth {

// The evaluation-epoch pool of solid bodies produced so far, keyed by the
// producing operation's document id. Booleans CONSUME pool entries: a
// consumed body leaves the visible result entirely (no bodies entry, no
// probes, no mesh packet) and can never be referenced again within the same
// request — consumed is consumed; there is no DAG reuse of a body a boolean
// has already eaten. Like profiles, the pool is epoch-local kernel state
// (ADR-003) and nothing about it survives the request that built it.
//
// Tranche 2.1 (replay engine): the pool grew a snapshot/restore seam so a
// re-evaluation can resume from the longest unchanged operation prefix instead
// of replaying the whole document. Slice 1 lands the seam and proves it
// round-trips; the cumulative-hash cache that drives reuse arrives in a later
// slice. Snapshots are value copies — the design's fail-closed correctness
// gate demands a warm resume be byte-identical to a cold replay, and OCCT
// shapes are handle/shared so the copy is of handles, not geometry.
class BodyPool final {
public:
  void Produce(EvaluatedBody body) {
    availableByOperationId_.insert_or_assign(body.operationId, bodies_.size());
    consumed_.push_back(false);
    bodies_.push_back(std::move(body));
  }

  // Resolves an operation-level body reference for a consuming operation
  // (boolean_combine, hole) and consumes it. Missing id, non-body id (profile
  // or unknown), forward reference, and already-consumed id are deliberately
  // the same failure: to the kernel all four are "no consumable body by that
  // id yet" — the same taxonomy as extrude's profile resolution. The thrown
  // ReferenceMissing carries the CONSUMING operation's id. `description`
  // names the consuming operation for the message (e.g. "boolean cut" or
  // "hole"); it carries no other behavior.
  const TopoDS_Shape& Consume(const std::string& consumingOperationId,
                              const std::string& description, const char* role,
                              const std::string& referenceId) {
    const auto found = availableByOperationId_.find(referenceId);
    if (found == availableByOperationId_.end()) {
      throw ReferenceMissing(consumingOperationId,
                             description + " " + role + " references operation " + referenceId +
                                 ", which is not an unconsumed body-producing operation earlier "
                                 "in the document");
    }
    const std::size_t bodyIndex = found->second;
    availableByOperationId_.erase(found);
    consumed_[bodyIndex] = true;
    return bodies_[bodyIndex].shape;
  }

  // A non-destructive snapshot of the unconsumed bodies in document order — the
  // replay state a consuming op's ref slots resolve against BEFORE the op
  // consumes its own target (tranche N5). EvaluatedBody holds a TopoDS_Shape
  // handle, so the copies share TShape identity with what Consume() later
  // hands back: an edge resolved from this snapshot IS a valid spine sub-shape
  // of the consumed target.
  std::vector<EvaluatedBody> PeekVisibleBodies() const {
    std::vector<EvaluatedBody> visible;
    visible.reserve(bodies_.size());
    for (std::size_t bodyIndex = 0; bodyIndex < bodies_.size(); ++bodyIndex) {
      if (!consumed_[bodyIndex])
        visible.push_back(bodies_[bodyIndex]);
    }
    return visible;
  }

  // The unconsumed bodies, preserving document order among the survivors.
  std::vector<EvaluatedBody> TakeVisibleBodies() {
    std::vector<EvaluatedBody> visible;
    visible.reserve(bodies_.size());
    for (std::size_t bodyIndex = 0; bodyIndex < bodies_.size(); ++bodyIndex) {
      if (!consumed_[bodyIndex])
        visible.push_back(std::move(bodies_[bodyIndex]));
    }
    return visible;
  }

  // A resumable, immutable value capturing the FULL pool state after some
  // operation — every produced body (consumed or not), the consumed bitmap,
  // and the id->index resolution map. The consumed bodies are retained, not
  // pruned: `availableByOperationId` maps an id to an index into `bodies`, so
  // dropping a consumed body would shift indices and invalidate the map. A
  // memory governor may compact later (slice 3); the seam stays correct by
  // keeping the three containers index-aligned exactly as the live pool does.
  //
  // Copying an EvaluatedBody copies its TopoDS_Shape HANDLE, so a snapshot
  // shares TShape identity with the pool it came from (an edge resolved from a
  // restored body IsSame the same edge in the original — what ref resolution
  // keys on). The snapshot is an independent value: mutating the live pool
  // after TakeSnapshot never disturbs it, and one snapshot may be restored any
  // number of times (a prefix can seed several tail replays).
  struct Snapshot final {
    std::vector<EvaluatedBody> bodies;
    std::vector<bool> consumed;
    std::map<std::string, std::size_t> availableByOperationId;
  };

  Snapshot TakeSnapshot() const { return Snapshot{bodies_, consumed_, availableByOperationId_}; }

  // Replaces the live pool state with the snapshot's. Copies (does not move)
  // out of the snapshot so it stays reusable for a subsequent restore.
  void RestoreFrom(const Snapshot& snapshot) {
    bodies_ = snapshot.bodies;
    consumed_ = snapshot.consumed;
    availableByOperationId_ = snapshot.availableByOperationId;
  }

private:
  std::vector<EvaluatedBody> bodies_;
  std::vector<bool> consumed_;
  std::map<std::string, std::size_t> availableByOperationId_;
};

} // namespace aeth
