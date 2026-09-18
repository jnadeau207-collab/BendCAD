#pragma once

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <mutex>
#include <string>
#include <thread>

namespace aeth {

// The evaluation loop calls this around each operation so a per-op wall-clock
// cap can be enforced without threading a deadline through every geometry op. A
// null pointer disables timing (tests, non-document paths).
class OperationDeadline {
public:
  virtual ~OperationDeadline() = default;
  virtual void BeginOperation(const std::string& operationId) = 0;
  virtual void EndOperation() = 0;
};

// RAII: begins timing an operation and ends it when the scope exits — normally
// OR by exception — so a thrown Cancelled/failure can never leave a deadline
// armed past the operation it belonged to. A null deadline is a no-op.
class ScopedOperation final {
public:
  ScopedOperation(OperationDeadline* deadline, const std::string& operationId)
      : deadline_(deadline) {
    if (deadline_ != nullptr)
      deadline_->BeginOperation(operationId);
  }
  ~ScopedOperation() {
    if (deadline_ != nullptr)
      deadline_->EndOperation();
  }
  ScopedOperation(const ScopedOperation&) = delete;
  ScopedOperation& operator=(const ScopedOperation&) = delete;

private:
  OperationDeadline* deadline_;
};

// The outcome of a request's per-op timing, read at the request boundary to map
// a thrown Cancelled to the right wire error: `tripped` distinguishes a per-op
// TIMEOUT (with the offending op id + its budget) from a plain user `cancel`.
struct OperationTimeout final {
  bool tripped = false;
  std::string operationId;
  std::chrono::milliseconds budget{0};
};

// A background watchdog that bounds each operation's wall-clock time (plan 06
// §7). When the current operation outlives its budget, it records the trip (op
// id + budget) under its lock and THEN trips the shared cancel flag the ops
// already poll, so the op's cooperative `CancellationProgress::UserBreak` check
// unwinds it — no per-op signature change. Reading `Result()` at the boundary
// locks the same mutex, so it happens-after the trip that set the flag the op
// observed: a user cancel (watchdog never tripped) reads `tripped == false`. An
// op that never polls is not interrupted by the flag; that stuck case is the
// request queue's kill/restart job (§10). The thread runs for the object's
// lifetime; construct one per process.
class OperationWatchdog final : public OperationDeadline {
public:
  explicit OperationWatchdog(std::atomic_bool& cancelled);
  ~OperationWatchdog() override;
  OperationWatchdog(const OperationWatchdog&) = delete;
  OperationWatchdog& operator=(const OperationWatchdog&) = delete;

  // Start a request: clear any prior trip and set the per-op cap. A zero (or
  // negative) budget disables timing for the request.
  void BeginRequest(std::chrono::milliseconds opTimeout);

  void BeginOperation(const std::string& operationId) override;
  void EndOperation() override;

  // A user `cancel` arrived: claim the request's cause as a cancellation (if no
  // cause is set yet) and DISARM the deadline so the watchdog can never trip
  // afterwards. This is the first-cause arbiter — whichever of {this, a deadline
  // expiry} takes the lock first with no cause set wins — so a cancel that
  // precedes a not-yet-polled op is never re-reported as a TIMEOUT (finding 1).
  // The caller sets the shared cancel flag AFTER this returns.
  void Cancel();

  // Whether a per-op timeout tripped this request, and on which op. False after
  // a user Cancel(), even if the op ran past its deadline.
  OperationTimeout Result() const;

private:
  // Which cause claimed the request first — the arbiter behind Result(). Both a
  // deadline expiry and Cancel() set it under `mutex_` only from `None`, so the
  // first to the lock decides, and neither can override the other.
  enum class Cause { None, UserCancel, Timeout };

  void Run();

  std::atomic_bool& cancelled_;
  mutable std::mutex mutex_;
  std::condition_variable cv_;
  std::chrono::milliseconds timeout_{0};
  std::chrono::steady_clock::time_point deadline_{};
  std::string operationId_;
  OperationTimeout tripped_;
  Cause cause_ = Cause::None;
  // Bumped on every arm/disarm so the watchdog's timed wait can tell "still the
  // same operation" from "a new op began at a coincidentally equal deadline".
  std::uint64_t generation_ = 0;
  bool armed_ = false;
  bool stop_ = false;
  std::thread thread_;
};

} // namespace aeth
